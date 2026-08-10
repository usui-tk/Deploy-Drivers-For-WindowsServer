# psa-disable-file PSAP0002 -- test code is not a pipeline script: it declares no
# ScriptVersion / ScriptHash / ScriptShortTag because it ships no runtime identity.
# The five product scripts remain subject to the rule.
<#
.SYNOPSIS
    Gate G-16 (shadow scope): the static extraction shadow never reaches
    an execution primitive (audit v5 sections 4.1-4.3 / W12).
.DESCRIPTION
    AST walk over the seven shadow functions embedded in the chipset
    script plus the P04 shadow call site:
      1. All seven shadow functions are present exactly once.
      2. Zero invocations of the forbidden set inside their bodies:
         process launch, msiexec, and the two executable extraction
         strategies (ViaLaunch / ViaInstallShield). Forbidden names are
         assembled by concatenation so this file never trips a scan.
      3. The P04 shadow try block exists exactly once, carries a catch
         clause (fail-open), and its body is also free of the forbidden
         set.
      4. Detector self-checks: a synthetic positive (a function invoking
         a process launch) is detected; a variable-based invocation
         (& $SevenZipPath) is NOT misattributed as a named command.
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

$chipsetPath = Join-Path $RepoRoot 'Deploy-AMDChipsetDriverOnWindowsServer.ps1'
$shadowFunctionNames = @(
    'Initialize-AmdStaticExtractionDecoder',
    'Get-AmdStaticIsSetupStreamProbe',
    'Expand-AmdStaticIsSetupStream',
    'Invoke-AmdStaticExtractionShadow',
    'Get-AmdStaticMsiFileTableMap',
    'Resolve-AmdStaticCabEntryName',
    'Write-AmdStaticExtractionGraph'
)
# Assembled so this file never trips its own scan or a repo-wide grep.
$forbiddenNames = @(
    ('Start-' + 'Process'),
    ('msi' + 'exec'),
    ('msi' + 'exec.exe'),
    ('Expand-AmdInstaller' + '_ViaLaunch'),
    ('Expand-AmdInstaller' + '_ViaInstallShield')
)

function Get-G16ForbiddenInvocation {
    param($Ast, [string[]]$Forbidden)
    $hits = @()
    $commands = $Ast.FindAll({ param($node)
        $node -is [System.Management.Automation.Language.CommandAst] }, $true)
    foreach ($command in $commands) {
        $name = $command.GetCommandName()
        if ($null -eq $name) { continue }
        foreach ($bad in $Forbidden) {
            if ([string]::Equals($name, $bad, [System.StringComparison]::OrdinalIgnoreCase)) {
                $hits += $name
            }
        }
    }
    return $hits
}

Write-TestSection 'G-16: shadow function bodies never invoke an execution primitive'
$tokens = $null
$errors = $null
$scriptAst = [System.Management.Automation.Language.Parser]::ParseFile($chipsetPath, [ref]$tokens, [ref]$errors)
Assert-Equal 'chipset parses with zero errors' 0 (@($errors).Count)
$shadowFunctions = @($scriptAst.FindAll({ param($node)
    $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and
    $node.Name -in $shadowFunctionNames }, $true))
Assert-Equal 'all seven shadow functions present exactly once' 7 $shadowFunctions.Count
foreach ($function in $shadowFunctions) {
    $hits = @(Get-G16ForbiddenInvocation -Ast $function -Forbidden $forbiddenNames)
    Assert-Equal ('{0}: zero forbidden invocations' -f $function.Name) 0 $hits.Count
}

Write-TestSection 'G-16: P04 shadow call site'
$p04 = @($scriptAst.FindAll({ param($node)
    $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and
    $node.Name -eq 'Invoke-PrepPhase04_ExtractInstaller' }, $true))
Assert-Equal 'P04 function present' 1 $p04.Count
$shadowTries = @()
if ($p04.Count -eq 1) {
    $shadowTries = @($p04[0].FindAll({ param($node)
        $node -is [System.Management.Automation.Language.TryStatementAst] }, $true) |
        Where-Object { $_.Extent.Text.Contains('Invoke-AmdStaticExtractionShadow') })
}
Assert-Equal 'exactly one shadow try block in P04' 1 $shadowTries.Count
if ($shadowTries.Count -eq 1) {
    Assert-True 'the shadow try block carries a catch clause (fail-open)' ($shadowTries[0].CatchClauses.Count -ge 1)
    $callSiteHits = @(Get-G16ForbiddenInvocation -Ast $shadowTries[0] -Forbidden $forbiddenNames)
    Assert-Equal 'zero forbidden invocations inside the shadow try block' 0 $callSiteHits.Count
}

Write-TestSection 'G-16: detector self-checks'
$positiveSource = 'function Test-Positive { ' + $forbiddenNames[0] + ' -FilePath example.exe }'
$positiveAst = [System.Management.Automation.Language.Parser]::ParseInput($positiveSource, [ref]$tokens, [ref]$errors)
Assert-Equal 'synthetic positive is detected' 1 (@(Get-G16ForbiddenInvocation -Ast $positiveAst -Forbidden $forbiddenNames).Count)
$variableSource = 'function Test-Variable { & $SevenZipPath ''x'' ''-y'' $path }'
$variableAst = [System.Management.Automation.Language.Parser]::ParseInput($variableSource, [ref]$tokens, [ref]$errors)
Assert-Equal 'variable invocation is not misattributed as a named command' 0 (@(Get-G16ForbiddenInvocation -Ast $variableAst -Forbidden $forbiddenNames).Count)

$result = Get-TestResult
Write-Host ''
Write-Host ('{0}: {1} passed, {2} failed' -f (Split-Path -Leaf $PSCommandPath), $result.Passed, $result.Failed) `
    -ForegroundColor $(if ($result.Failed -eq 0) { 'Green' } else { 'Red' })
exit $result.Failed
