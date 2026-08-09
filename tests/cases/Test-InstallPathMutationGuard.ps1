# psa-disable-file PSAP0002 -- test code is not a pipeline script: it declares no
# ScriptVersion / ScriptHash / ScriptShortTag because it ships no runtime identity.
# The five product scripts remain subject to the rule.
<#
.SYNOPSIS
    Acceptance gate G-04: the install path never auto-disables Windows Driver
    Policy / Secure Boot / HVCI, and Mode T is an explicit opt-in.
.DESCRIPTION
    Audit ruling (plan G-04; design section 3): a normal install run must not
    weaken the platform to raise its own success rate. This case pins, on the
    AST of every product script:
      1. No command passes a Windows Driver Policy GUID to a removal verb
         (CiTool --remove-policy / Remove-Item / del).
      2. No bcdedit invocation touches nointegritychecks.
      3. No Set-ItemProperty / New-ItemProperty writes the HVCI Enabled value.
      4. (Sisters) every "testsigning on" write site - a bcdedit CommandAst or
         the ProcessStartInfo Arguments assignment - sits under an
         IfStatementAst whose condition references UseTestSigning (Mode T
         explicit opt-in).
    Plus the P1-A decision-table fixtures for the pure function
    Resolve-SupplementalActivationPlan, and four-way byte-identity for the
    two new W3 helpers. Negative controls: mutated /tmp copies (never the
    working tree) fail checks 1 and 4.
#>
[CmdletBinding()]
[OutputType([int])]
param(
    [Parameter()] [string]$RepoRoot = (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
Import-Module (Join-Path (Split-Path -Parent $PSScriptRoot) 'lib/TestHarness.psm1') -Force
Reset-TestState

$sisters = @(
    'Deploy-AMDChipsetDriverOnWindowsServer.ps1',
    'Deploy-AMDGraphicsDriverOnWindowsServer.ps1',
    'Deploy-AMDNpuDriverOnWindowsServer.ps1',
    'Deploy-MSBthPanInboxOnWindowsServer.ps1'
)
$products = $sisters + @('Collect-WindowsServerConfigurationEvidence.ps1')

# WDP GUIDs assembled at run time so this file never matches its own scan.
$wdpGuids = @(
    ('784C4414-79F4-4C32' + '-A6A5-F0FB42A51D0D'),
    ('8F9CB695-5D48-48D6' + '-A329-7202B44607E3')
)
$removalVerbPattern = '(?i)(--remove-policy|Remove-Item|\bdel\b)'

function Get-G04ScriptAst {
    [OutputType([System.Management.Automation.Language.ScriptBlockAst])]
    param([Parameter(Mandatory)] [string]$Path)
    $t = $null; $e = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseFile(
        (Resolve-Path $Path).Path, [ref]$t, [ref]$e)
    if (@($e).Count -gt 0) {
        throw ('{0}: {1} parse error(s)' -f (Split-Path -Leaf $Path), @($e).Count)
    }
    return $ast
}

function Get-G04ViolationList {
    # Pure scanner over one parsed AST. Returns violation strings; an
    # empty list means the script passes G-04. Kept as one function so
    # the negative controls exercise the same code the gate uses.
    [OutputType([object[]])]
    param(
        [Parameter(Mandatory)] $Ast,
        [Parameter(Mandatory)] [string[]]$WdpGuids,
        [Parameter(Mandatory)] [string]$RemovalVerbPattern,
        [Parameter()] [bool]$CheckTestSigningGuard = $false
    )
    $violations = New-Object System.Collections.Generic.List[string]

    $commands = $Ast.FindAll({ param($n) $n -is [System.Management.Automation.Language.CommandAst] }, $true)
    foreach ($cmd in $commands) {
        $text = $cmd.Extent.Text
        foreach ($gid in $WdpGuids) {
            if ($text -match [regex]::Escape($gid) -and [regex]::IsMatch($text, $RemovalVerbPattern)) {
                $violations.Add(('line {0}: WDP GUID passed to a removal verb' -f $cmd.Extent.StartLineNumber)) | Out-Null
            }
        }
        $name = $cmd.GetCommandName()
        if ($name -and $name -match '(?i)^bcdedit(\.exe)?$') {
            if ($text -match '(?i)nointegritychecks') {
                $violations.Add(('line {0}: bcdedit touches nointegritychecks' -f $cmd.Extent.StartLineNumber)) | Out-Null
            }
        }
        if ($name -and $name -match '(?i)^(Set-ItemProperty|New-ItemProperty)$') {
            if ($text -match '(?i)HypervisorEnforcedCodeIntegrity') {
                $violations.Add(('line {0}: HVCI registry value write' -f $cmd.Extent.StartLineNumber)) | Out-Null
            }
        }
    }

    if ($CheckTestSigningGuard) {
        # Write sites: bcdedit CommandAst with "testsigning on", or an
        # assignment whose RHS string is "/set testsigning on" (the
        # ProcessStartInfo form used by three sisters).
        $writeSites = New-Object System.Collections.Generic.List[object]
        foreach ($cmd in $commands) {
            $name = $cmd.GetCommandName()
            if ($name -and $name -match '(?i)^bcdedit(\.exe)?$' -and $cmd.Extent.Text -match '(?i)testsigning\s+on') {
                $writeSites.Add($cmd) | Out-Null
            }
        }
        $assigns = $Ast.FindAll({ param($n) $n -is [System.Management.Automation.Language.AssignmentStatementAst] }, $true)
        foreach ($a in $assigns) {
            # Write form only: the RHS is exactly the '/set testsigning on'
            # string constant (the ProcessStartInfo Arguments assignment).
            # Guidance text that merely mentions the command (multi-line
            # here-arrays, sentences) must not count as a write site.
            if ($a.Right.Extent.Text -match "(?i)^\s*'/set\s+testsigning\s+on'\s*$") {
                $writeSites.Add($a) | Out-Null
            }
        }
        foreach ($site in $writeSites) {
            $guarded = $false
            $node = $site.Parent
            while ($null -ne $node) {
                if ($node -is [System.Management.Automation.Language.IfStatementAst]) {
                    foreach ($clause in $node.Clauses) {
                        if ($clause.Item1.Extent.Text -match 'UseTestSigning') { $guarded = $true; break }
                    }
                }
                if ($guarded) { break }
                $node = $node.Parent
            }
            if (-not $guarded) {
                $violations.Add(('line {0}: testsigning write without a UseTestSigning conditional ancestor' -f $site.Extent.StartLineNumber)) | Out-Null
            }
        }
    }
    return ,$violations.ToArray()
}

Write-TestSection 'G-04: no product script weakens WDP / Secure Boot / HVCI; Mode T writes are guarded'
foreach ($leaf in $products) {
    $ast = Get-G04ScriptAst -Path (Join-Path $RepoRoot $leaf)
    $isSister = ($sisters -contains $leaf)
    $v = Get-G04ViolationList -Ast $ast -WdpGuids $wdpGuids -RemovalVerbPattern $removalVerbPattern -CheckTestSigningGuard $isSister
    Assert-Equal ('{0}: 0 G-04 violation(s)' -f $leaf) 0 (@($v).Count)
    if (@($v).Count -gt 0) { $v | ForEach-Object { Write-Host ('        {0}' -f $_) -ForegroundColor Red } }
}

Write-TestSection 'P1-A: Resolve-SupplementalActivationPlan decision table (fixtures)'
$chipset = Join-Path $RepoRoot 'Deploy-AMDChipsetDriverOnWindowsServer.ps1'
. (Get-ScriptFunctionBlock -Path $chipset -Name @('Resolve-SupplementalActivationPlan'))
$rows = @(
    @{ Build = 14393; Ci = $false; Rp = '';                Hvci = $false; Supported = $false; Method = 'unsupported' },
    @{ Build = 17763; Ci = $false; Rp = '';                Hvci = $false; Supported = $false; Method = 'unsupported' },
    @{ Build = 17763; Ci = $true;  Rp = 'X:\rp.exe';       Hvci = $true;  Supported = $false; Method = 'unsupported' },
    @{ Build = 20348; Ci = $false; Rp = '';                Hvci = $false; Supported = $true;  Method = 'wmi-bridge' },
    @{ Build = 20348; Ci = $false; Rp = 'X:\rp.exe';       Hvci = $false; Supported = $true;  Method = 'refreshpolicy-exe' },
    @{ Build = 20348; Ci = $true;  Rp = '';                Hvci = $false; Supported = $true;  Method = 'citool' },
    @{ Build = 26100; Ci = $true;  Rp = '';                Hvci = $true;  Supported = $true;  Method = 'citool' }
)
foreach ($r in $rows) {
    $plan = Resolve-SupplementalActivationPlan -OsBuild $r.Build -CiToolAvailable $r.Ci -RefreshPolicyExePath $r.Rp -MemoryIntegrityRunning $r.Hvci
    Assert-Equal ('build {0} ci={1} rp={2}: Supported' -f $r.Build, $r.Ci, ($r.Rp -ne '')) $r.Supported $plan.SupplementalSupported
    Assert-Equal ('build {0} ci={1} rp={2}: Method' -f $r.Build, $r.Ci, ($r.Rp -ne '')) $r.Method $plan.Method
    Assert-Equal ('build {0}: MemoryIntegrityNote presence' -f $r.Build) $r.Hvci ($null -ne $plan.MemoryIntegrityNote)
}

Write-TestSection 'W3 helpers are four-way byte-identical'
function Get-FnText {
    param([string]$Path, [string]$Name)
    $ast = Get-G04ScriptAst -Path $Path
    foreach ($fn in $ast.FindAll({ param($n) $n -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true)) {
        if ($fn.Name -eq $Name) { return $fn.Extent.Text }
    }
    return '(absent)'
}
foreach ($name in @('Resolve-SupplementalActivationPlan', 'Test-RefreshPolicyExeAvailable',
                    'Test-WindowsDriverPolicyPresent', 'Show-WindowsDriverPolicyDisclosure')) {
    $texts = @($sisters | ForEach-Object { Get-FnText -Path (Join-Path $RepoRoot $_) -Name $name })
    Assert-Equal ('{0}: identical in all four' -f $name) 1 (@($texts | Sort-Object -Unique)).Count
}

Write-TestSection 'The scanner catches violations (negative controls on mutated /tmp copies)'
$tmpDir = Join-Path ([System.IO.Path]::GetTempPath()) ('g04neg-' + [guid]::NewGuid().ToString('N').Substring(0, 8))
New-Item -ItemType Directory -Path $tmpDir | Out-Null
try {
    $mut1 = Join-Path $tmpDir 'mut-unguarded-testsigning.ps1'
    Set-Content -LiteralPath $mut1 -Value "& bcdedit.exe /set testsigning on`n" -Encoding ASCII
    $v1 = Get-G04ViolationList -Ast (Get-G04ScriptAst -Path $mut1) -WdpGuids $wdpGuids -RemovalVerbPattern $removalVerbPattern -CheckTestSigningGuard $true
    Assert-True 'an unguarded testsigning write is detected' (@($v1).Count -gt 0)

    $mut2 = Join-Path $tmpDir 'mut-wdp-removal.ps1'
    Set-Content -LiteralPath $mut2 -Value ("& CiTool.exe --remove-policy '{0}'`n" -f $wdpGuids[0]) -Encoding ASCII
    $v2 = Get-G04ViolationList -Ast (Get-G04ScriptAst -Path $mut2) -WdpGuids $wdpGuids -RemovalVerbPattern $removalVerbPattern -CheckTestSigningGuard $false
    Assert-True 'a WDP GUID removal is detected' (@($v2).Count -gt 0)

    $mut4 = Join-Path $tmpDir 'mut-unguarded-psi-assignment.ps1'
    Set-Content -LiteralPath $mut4 -Value "`$psi = New-Object System.Diagnostics.ProcessStartInfo`n`$psi.Arguments = '/set testsigning on'`n" -Encoding ASCII
    $v4 = Get-G04ViolationList -Ast (Get-G04ScriptAst -Path $mut4) -WdpGuids $wdpGuids -RemovalVerbPattern $removalVerbPattern -CheckTestSigningGuard $true
    Assert-True 'an unguarded ProcessStartInfo Arguments assignment is detected' (@($v4).Count -gt 0)

    $mut3 = Join-Path $tmpDir 'mut-guarded-testsigning.ps1'
    Set-Content -LiteralPath $mut3 -Value "if (`$Ctx.UseTestSigning) { & bcdedit.exe /set testsigning on }`n" -Encoding ASCII
    $v3 = Get-G04ViolationList -Ast (Get-G04ScriptAst -Path $mut3) -WdpGuids $wdpGuids -RemovalVerbPattern $removalVerbPattern -CheckTestSigningGuard $true
    Assert-Equal 'a properly guarded testsigning write passes' 0 (@($v3).Count)
} finally {
    Remove-Item -LiteralPath $tmpDir -Recurse -Force -ErrorAction SilentlyContinue
}

$result = Get-TestResult
Write-Host ''
Write-Host ('{0}: {1} passed, {2} failed' -f (Split-Path -Leaf $PSCommandPath), $result.Passed, $result.Failed) `
    -ForegroundColor $(if ($result.Failed -eq 0) { 'Green' } else { 'Red' })
exit $result.Failed
