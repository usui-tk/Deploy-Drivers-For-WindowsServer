# psa-disable-file PSAP0002 -- test code is not a pipeline script: it declares no
# ScriptVersion / ScriptHash / ScriptShortTag because it ships no runtime identity.
# The five product scripts remain subject to the rule.
<#
.SYNOPSIS
    The WDAC supplemental-policy path must not assume a base policy.
.DESCRIPTION
    Third-party audit finding C-02: all four sisters defaulted the
    SupplementsBasePolicyID to the Windows-shipped GUID
    {A244370E-44C9-4C06-B551-F6016E563076} and deployed a supplemental
    policy against a base policy nobody had verified to exist. A
    supplemental policy supplements a base; assuming the base's identity
    is exactly the class of expectation-as-fact error recorded in SPEC
    D.47.2. This case pins the remediation:

      1. No sister carries the assumed GUID as a code string constant
         (comments may keep it as history; code may not).
      2. The script-scope default variable WdacBasePolicyGuidDefault is
         gone from every script.
      3. All four sisters carry a byte-identical admissibility helper,
         Test-WdacSupplementalPolicyAdmissible.
      4. Every supplemental-policy builder refuses an empty BasePolicyId.
      5. Every authorize-signing phase gates the supplemental path on the
         helper, and the refusal branch actually returns (SPEC D.57: a
         refusal must refuse, not fall through to path selection).
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
$allScripts = @($sisters) + @(Join-Path $RepoRoot 'Collect-WindowsServerConfigurationEvidence.ps1')

function Get-ScriptAst {
    [OutputType([System.Management.Automation.Language.ScriptBlockAst])]
    param([string]$Path)
    $t = $null; $e = $null
    return [System.Management.Automation.Language.Parser]::ParseFile((Resolve-Path $Path).Path, [ref]$t, [ref]$e)
}

function Get-FunctionAst {
    param([System.Management.Automation.Language.ScriptBlockAst]$Ast, [string]$Name)
    foreach ($fn in $Ast.FindAll({ param($n) $n -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true)) {
        if ($fn.Name -eq $Name) { return $fn }
    }
    return $null
}

function Get-TextHash {
    [OutputType([string])]
    param([string]$Text)
    if ([string]::IsNullOrEmpty($Text)) { return '(absent)' }
    $sha = [System.Security.Cryptography.SHA256]::Create()
    return [System.BitConverter]::ToString($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($Text))).Replace('-', '').Substring(0, 16)
}

Write-TestSection 'No sister assumes the Windows-shipped base policy GUID in code'
foreach ($script in $sisters) {
    $ast = Get-ScriptAst -Path $script
    $hits = @($ast.FindAll({ param($n)
        $n -is [System.Management.Automation.Language.StringConstantExpressionAst] -and
        $n.Value -match 'A244370E-44C9-4C06-B551-F6016E563076' }, $true))
    foreach ($h in $hits) {
        Write-Host ('        {0}:{1} {2}' -f (Split-Path -Leaf $script), $h.Extent.StartLineNumber, $h.Extent.Text) -ForegroundColor DarkRed
    }
    Assert-Equal ('{0}: assumed base GUID appears in 0 code string(s)' -f (Split-Path -Leaf $script)) 0 $hits.Count
}

Write-TestSection 'The WdacBasePolicyGuidDefault variable is gone repo-wide'
foreach ($script in $allScripts) {
    $ast = Get-ScriptAst -Path $script
    $vars = @($ast.FindAll({ param($n)
        $n -is [System.Management.Automation.Language.VariableExpressionAst] -and
        $n.VariablePath.UserPath -match 'WdacBasePolicyGuidDefault' }, $true))
    Assert-Equal ('{0}: WdacBasePolicyGuidDefault referenced 0 time(s)' -f (Split-Path -Leaf $script)) 0 $vars.Count
}

Write-TestSection 'All four sisters carry the byte-identical admissibility helper'
$helperTexts = @()
foreach ($script in $sisters) {
    $fn = Get-FunctionAst -Ast (Get-ScriptAst -Path $script) -Name 'Test-WdacSupplementalPolicyAdmissible'
    Assert-True ('{0}: Test-WdacSupplementalPolicyAdmissible exists' -f (Split-Path -Leaf $script)) ($null -ne $fn)
    $helperTexts += if ($fn) { $fn.Extent.Text } else { '' }
}
$uniqueHashes = @($helperTexts | ForEach-Object { Get-TextHash $_ } | Sort-Object -Unique)
Assert-Equal 'helper is byte-identical in all four' 1 $uniqueHashes.Count

Write-TestSection 'Every supplemental-policy builder refuses an empty BasePolicyId'
$builders = @{
    'Deploy-AMDChipsetDriverOnWindowsServer.ps1'  = 'New-AmdDriverWdacSupplementalPolicy'
    'Deploy-AMDGraphicsDriverOnWindowsServer.ps1' = 'New-AmdDriverWdacSupplementalPolicy'
    'Deploy-AMDNpuDriverOnWindowsServer.ps1'      = 'New-WdacSupplementalPolicy'
    'Deploy-MSBthPanInboxOnWindowsServer.ps1'     = 'New-MsBthPanDriverWdacSupplementalPolicy'
}
foreach ($script in $sisters) {
    $leaf = Split-Path -Leaf $script
    $fn = Get-FunctionAst -Ast (Get-ScriptAst -Path $script) -Name $builders[$leaf]
    $text = if ($fn) { $fn.Extent.Text } else { '' }
    $guarded = ($text -match 'IsNullOrWhiteSpace') -and ($text -match '\bthrow\b') -and ($text -match 'BasePolicyId')
    Assert-True ('{0}: builder {1} guards empty BasePolicyId' -f $leaf, $builders[$leaf]) $guarded
}

Write-TestSection 'The authorize-signing phase gates the supplemental path, and the refusal returns'
foreach ($script in $sisters) {
    $leaf = Split-Path -Leaf $script
    $ast = Get-ScriptAst -Path $script
    $builderName = $builders[$leaf]
    $phaseFn = $null
    foreach ($call in $ast.FindAll({ param($n) $n -is [System.Management.Automation.Language.CommandAst] }, $true)) {
        if ($call.GetCommandName() -ne $builderName) { continue }
        $p = $call.Parent
        while ($p -and -not ($p -is [System.Management.Automation.Language.FunctionDefinitionAst])) { $p = $p.Parent }
        if ($p -and $p.Name -ne $builderName) { $phaseFn = $p; break }
    }
    Assert-True ('{0}: phase invoking {1} found' -f $leaf, $builderName) ($null -ne $phaseFn)
    $gates = @()
    if ($phaseFn) {
        $gates = @($phaseFn.FindAll({ param($n)
            $n -is [System.Management.Automation.Language.IfStatementAst] -and
            $n.Clauses[0].Item1.Extent.Text -match 'Test-WdacSupplementalPolicyAdmissible' }, $true))
    }
    Assert-True ('{0}: phase gates on Test-WdacSupplementalPolicyAdmissible' -f $leaf) ($gates.Count -ge 1)
    $refusalReturns = $false
    foreach ($g in $gates) {
        $rets = @($g.Clauses[0].Item2.FindAll({ param($n) $n -is [System.Management.Automation.Language.ReturnStatementAst] }, $true))
        if ($rets.Count -ge 1) { $refusalReturns = $true }
    }
    Assert-True ('{0}: the refusal branch returns' -f $leaf) $refusalReturns
}

$result = Get-TestResult
Write-Host ''
Write-Host ('{0}: {1} passed, {2} failed' -f (Split-Path -Leaf $PSCommandPath), $result.Passed, $result.Failed) `
    -ForegroundColor $(if ($result.Failed -eq 0) { 'Green' } else { 'Red' })
exit $result.Failed
