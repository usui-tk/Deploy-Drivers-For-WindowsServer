# psa-disable-file PSAP0002 -- test code is not a pipeline script: it declares no
# ScriptVersion / ScriptHash / ScriptShortTag because it ships no runtime identity.
# The five product scripts remain subject to the rule.
<#
.SYNOPSIS
    Cross-script invariants the four deploy scripts must hold together.
.DESCRIPTION
    The four scripts share helpers by byte-identical duplication rather than
    by import (SPEC A.11.5b). Nothing enforces that at runtime, so a fix
    applied to one sister and forgotten on the others is invisible until a
    field run. This case checks the invariants mechanically.

    It also checks the two contract classes that reached production: a call
    site passing a value outside a ValidateSet, and @( ) applied to a
    List[object] - both of which throw on first execution and neither of
    which the static analyzer detects.
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
) | ForEach-Object { Join-Path $RepoRoot $_ }
$pathA = $sisters | Where-Object { $_ -notmatch 'Npu' }
$allScripts = @($sisters) + @(Join-Path $RepoRoot 'Collect-WindowsServerConfigurationEvidence.ps1')

function Get-FunctionText {
    [OutputType([string])]
    param([string]$Path, [string]$Name)
    $t = $null; $e = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseFile((Resolve-Path $Path).Path, [ref]$t, [ref]$e)
    foreach ($fn in $ast.FindAll({ param($n) $n -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true)) {
        if ($fn.Name -eq $Name) { return $fn.Extent.Text }
    }
    return ''
}

function Get-TextHash {
    [OutputType([string])]
    param([string]$Text)
    if ([string]::IsNullOrEmpty($Text)) { return '(absent)' }
    $sha = [System.Security.Cryptography.SHA256]::Create()
    return [System.BitConverter]::ToString($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($Text))).Replace('-', '').Substring(0, 16)
}

Write-TestSection 'Shared helpers are byte-identical across the sisters that carry them'
$fourWay = @('Write-InstallReadinessDigest', 'Get-SystemDeviceHealthCensus',
              'Write-DeviceHealthRegressionReport', 'Get-InfWdfRequirement')
foreach ($name in $fourWay) {
    $hashes = @($sisters | ForEach-Object { Get-TextHash (Get-FunctionText -Path $_ -Name $name) })
    Assert-Equal ('{0}: identical in all four' -f $name) 1 (@($hashes | Sort-Object -Unique)).Count
}
$threeWay = @('Get-EligibleInfRecordList', 'Save-WhqlCoSignPlanJson', 'Get-WhqlCoSignPlanInfo')
foreach ($name in $threeWay) {
    $hashes = @($pathA | ForEach-Object { Get-TextHash (Get-FunctionText -Path $_ -Name $name) })
    Assert-Equal ('{0}: identical in the three Path A sisters' -f $name) 1 (@($hashes | Sort-Object -Unique)).Count
}

Write-TestSection 'ValidateSet call sites pass values the parameter accepts'
# Write-PhaseFooter lives inside a vendored canon region, so its ValidateSet
# cannot be widened here; the call sites are this repository's to get right.
$violations = 0
foreach ($script in $allScripts) {
    $t = $null; $e = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseFile((Resolve-Path $script).Path, [ref]$t, [ref]$e)
    $sets = @{}
    foreach ($fn in $ast.FindAll({ param($n) $n -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true)) {
        $params = if ($fn.Body.ParamBlock) { $fn.Body.ParamBlock.Parameters } else { $fn.Parameters }
        if (-not $params) { continue }
        $i = 0
        $info = @{}
        foreach ($p in $params) {
            foreach ($a in $p.Attributes) {
                if ($a -is [System.Management.Automation.Language.AttributeAst] -and $a.TypeName.Name -match 'ValidateSet') {
                    $info[$i] = @{ Name = $p.Name.VariablePath.UserPath; Set = @($a.PositionalArguments | ForEach-Object { $_.Value }) }
                }
            }
            $i++
        }
        if ($info.Count -gt 0) { $sets[$fn.Name] = $info }
    }
    foreach ($call in $ast.FindAll({ param($n) $n -is [System.Management.Automation.Language.CommandAst] }, $true)) {
        $cmd = $call.GetCommandName()
        if (-not $cmd -or -not $sets.ContainsKey($cmd)) { continue }
        $pos = @(); $named = @{}
        for ($j = 1; $j -lt $call.CommandElements.Count; $j++) {
            $el = $call.CommandElements[$j]
            if ($el -is [System.Management.Automation.Language.CommandParameterAst]) {
                $v = $el.Argument
                if (-not $v -and ($j + 1) -lt $call.CommandElements.Count) { $v = $call.CommandElements[$j + 1]; $j++ }
                if ($v -is [System.Management.Automation.Language.StringConstantExpressionAst]) { $named[$el.ParameterName] = $v.Value }
            } else { $pos += , $el }
        }
        foreach ($k in $sets[$cmd].Keys) {
            $spec = $sets[$cmd][$k]
            $lit = $null
            if ($named.ContainsKey($spec.Name)) { $lit = $named[$spec.Name] }
            elseif ($k -lt $pos.Count -and $pos[$k] -is [System.Management.Automation.Language.StringConstantExpressionAst]) { $lit = $pos[$k].Value }
            if ($lit -and ($spec.Set -notcontains $lit)) {
                $violations++
                Write-Host ('        {0}:{1} {2} -{3} ''{4}''' -f (Split-Path -Leaf $script), $call.Extent.StartLineNumber, $cmd, $spec.Name, $lit) -ForegroundColor DarkRed
            }
        }
    }
}
Assert-Equal 'no ValidateSet call-site violations repo-wide' 0 $violations

Write-TestSection '@( ) is never applied to a List[object]'
# The array-subexpression binder throws ArgumentException for that exact
# element type, even when the list is empty. List[string] and the rest are
# unaffected, which is what makes it easy to reintroduce.
$binderHits = 0
foreach ($script in $allScripts) {
    $t = $null; $e = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseFile((Resolve-Path $script).Path, [ref]$t, [ref]$e)
    $names = New-Object 'System.Collections.Generic.List[string]'
    foreach ($assign in $ast.FindAll({ param($n) $n -is [System.Management.Automation.Language.AssignmentStatementAst] }, $true)) {
        if ($assign.Right.Extent.Text -match 'System\.Collections\.Generic\.List\[\s*object\s*\]') {
            $leaf = ($assign.Left.Extent.Text -replace '^\$', '') -split '[:.]' | Select-Object -Last 1
            if ($leaf -and -not $names.Contains($leaf)) { $names.Add($leaf) }
        }
    }
    foreach ($ht in $ast.FindAll({ param($n) $n -is [System.Management.Automation.Language.HashtableAst] }, $true)) {
        foreach ($pair in $ht.KeyValuePairs) {
            if ($pair.Item2.Extent.Text -match 'System\.Collections\.Generic\.List\[\s*object\s*\]') {
                $leaf = $pair.Item1.Extent.Text.Trim("'", '"')
                if ($leaf -and -not $names.Contains($leaf)) { $names.Add($leaf) }
            }
        }
    }
    foreach ($arr in $ast.FindAll({ param($n) $n -is [System.Management.Automation.Language.ArrayExpressionAst] }, $true)) {
        $inner = $arr.SubExpression.Extent.Text.Trim()
        if ($inner -notmatch '^\$[A-Za-z_][A-Za-z0-9_:]*(\.[A-Za-z_][A-Za-z0-9_]*)*$') { continue }
        $leaf = ($inner -replace '^\$', '') -split '[:.]' | Select-Object -Last 1
        if ($names.Contains($leaf)) {
            $binderHits++
            Write-Host ('        {0}:{1} @({2})' -f (Split-Path -Leaf $script), $arr.Extent.StartLineNumber, $inner) -ForegroundColor DarkRed
        }
    }
}
Assert-Equal 'no @( ) over List[object] repo-wide' 0 $binderHits

Write-TestSection 'Every script parses and declares a version'
foreach ($script in $allScripts) {
    $t = $null; $e = $null
    $null = [System.Management.Automation.Language.Parser]::ParseFile((Resolve-Path $script).Path, [ref]$t, [ref]$e)
    Assert-Equal ('{0} parses cleanly' -f (Split-Path -Leaf $script)) 0 @($e).Count
    $text = Get-Content -LiteralPath $script -Raw
    Assert-True ('{0} declares $Script:ScriptVersion' -f (Split-Path -Leaf $script)) ($text -match '\$Script:ScriptVersion\s*=')
}


Write-TestSection 'Phase guards live inside the phases they guard'
# A guard inserted into the wrong function compiles, passes every static
# gate, and is never reached. That shipped: the degenerate-plan guards for
# P08 and P09 landed in P09 and V03 respectively, so a correctly-detected
# empty plan still failed P08 with a message naming a phase that had run.
$guardMap = @(
    @{ Function = 'Invoke-PrepPhase08_GenerateCatalogs'; Marker = "'P08' 'skipped'" },
    @{ Function = 'Invoke-PrepPhase09_SignCatalogs';     Marker = "'P09' 'skipped'" }
)
# Scope: the sisters that actually CALL Get-EligibleInfRecordList and can
# therefore reach an empty plan. BthPan carries the shared helper for
# byte-identity but drives a single inbox INF, so its trim never runs and a
# guard there would be unreachable code. Membership is derived from the call
# site rather than hard-coded, so a sister that starts calling the helper is
# picked up automatically.
$trimmers = @($pathA | Where-Object {
    (Get-Content -LiteralPath $_ -Raw) -match 'Get-EligibleInfRecordList -Ctx \$Ctx'
})
Assert-True 'at least one sister applies the trim' ($trimmers.Count -gt 0)
foreach ($script in $trimmers) {
    $t = $null; $e = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseFile((Resolve-Path $script).Path, [ref]$t, [ref]$e)
    $lines = Get-Content -LiteralPath $script
    foreach ($g in $guardMap) {
        $fn = $ast.FindAll({ param($n) $n -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true) |
              Where-Object { $_.Name -eq $g.Function } | Select-Object -First 1
        if ($null -eq $fn) {
            Assert-True ('{0}: {1} exists' -f (Split-Path -Leaf $script), $g.Function) $false
            continue
        }
        $body = ($lines[($fn.Extent.StartLineNumber - 1)..($fn.Extent.EndLineNumber - 1)]) -join "`n"
        Assert-True ('{0}: {1} contains its own degenerate guard' -f (Split-Path -Leaf $script), $g.Function) `
            ($body.Contains($g.Marker) -and $body.Contains('$Ctx.DegeneratePlan'))
    }
}

Write-TestSection 'The BthPan pre-flight excludes the auto-generated transcript path'
# All four sisters auto-place the transcript under <WorkRoot>\logs when
# -LogFile is omitted. Only BthPan carries a P01 overlap check, and it did
# not exclude that case, so the default invocation failed on a path the
# operator never chose.
$bthpan = Join-Path $RepoRoot 'Deploy-MSBthPanInboxOnWindowsServer.ps1'
$bthText = Get-Content -LiteralPath $bthpan -Raw
Assert-True 'P01 overlap check excludes auto-generated transcripts' `
    ($bthText -match 'CleanWorkRoot -and \$Script:LogFileActive -and \$LogFile -and -not \$Script:LogFileAutoGenerated')


Write-TestSection 'The WDF version comparator is identical in all five scripts'
# The collector reads the host's framework version and the sisters read what
# each INF asks for. Both answers are meaningless unless they are ordered the
# same way, so the comparator is duplicated deliberately and pinned here.
# Divergence would make one side satisfied by a runtime the other rejects.
$fiveWay = @('ConvertTo-WdfVersionNumber')
foreach ($name in $fiveWay) {
    $hashes = @($allScripts | ForEach-Object { Get-TextHash (Get-FunctionText -Path $_ -Name $name) })
    Assert-Equal ('{0}: identical in all five scripts' -f $name) 1 (@($hashes | Sort-Object -Unique)).Count
}

Write-TestSection 'Every sister carries the WDF requirement columns in P05'
# The four sisters build their inventory rows in different shapes - two of
# them in two stages, two in one - so the columns are checked by reading the
# hashtable keys out of the AST rather than by grepping. A column added to
# one sister and forgotten in another is exactly the drift this catches.
$wdfColumns = @('IsWdfDriver', 'KmdfLibraryVersion', 'UmdfLibraryVersion',
                'CoInstallerVersions', 'WdfSectionCount')
foreach ($script in $sisters) {
    $leaf = Split-Path -Leaf $script
    $tok = $null; $perr = $null
    $sast = [System.Management.Automation.Language.Parser]::ParseFile(
        (Resolve-Path $script).Path, [ref]$tok, [ref]$perr)
    $p05 = @($sast.FindAll({ param($n)
        $n -is [System.Management.Automation.Language.FunctionDefinitionAst] -and
        $n.Name -eq 'Invoke-PrepPhase05_AnalyzeInfs' }, $true))
    Assert-Equal ('{0}: P05 is defined exactly once' -f $leaf) 1 $p05.Count
    $keys = New-Object 'System.Collections.Generic.List[string]'
    foreach ($table in $p05[0].FindAll({ param($n)
        $n -is [System.Management.Automation.Language.HashtableAst] }, $true)) {
        foreach ($pair in $table.KeyValuePairs) { [void]$keys.Add($pair.Item1.Extent.Text) }
    }
    $keyList = $keys.ToArray()
    foreach ($column in $wdfColumns) {
        Assert-True ('{0}: P05 emits {1}' -f $leaf, $column) ($keyList -contains $column)
    }
}
$result = Get-TestResult
Write-Host ''
Write-Host ('{0}: {1} passed, {2} failed' -f (Split-Path -Leaf $PSCommandPath), $result.Passed, $result.Failed) `
    -ForegroundColor $(if ($result.Failed -eq 0) { 'Green' } else { 'Red' })
exit $result.Failed
