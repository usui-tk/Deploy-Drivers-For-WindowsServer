# psa-disable-file PSAP0002 -- test code is not a pipeline script: it declares no
# ScriptVersion / ScriptHash / ScriptShortTag because it ships no runtime identity.
# The five product scripts remain subject to the rule.
<#
.SYNOPSIS
    Run the Deploy-Drivers-For-WindowsServer test suite.

.DESCRIPTION
    Discovers and runs every Test-*.ps1 under tests/cases, reports per-case
    and aggregate results, and exits non-zero when any case fails.

    Runs on Windows PowerShell 5.1 and PowerShell 7.x, on Windows or Linux,
    with no modules to install. Nothing here executes a deploy script or
    touches driver state: cases extract the functions they exercise by AST
    and run them against fixtures.

.PARAMETER Name
    Run only cases whose file name matches this wildcard.

.EXAMPLE
    ./tests/Invoke-TestSuite.ps1

.EXAMPLE
    ./tests/Invoke-TestSuite.ps1 -Name '*Collector*'
#>
[CmdletBinding()]
[OutputType([int])]
param(
    [Parameter()]
    [string]$Name = '*',

    [Parameter()]
    [string]$RepoRoot = (Split-Path -Parent $PSScriptRoot)
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$caseDir = Join-Path $PSScriptRoot 'cases'
$cases = @(Get-ChildItem -LiteralPath $caseDir -Filter 'Test-*.ps1' -File | Sort-Object Name |
           Where-Object { $_.Name -like $Name })

Write-Host ''
Write-Host '================================================================' -ForegroundColor Magenta
Write-Host ' Deploy-Drivers-For-WindowsServer test suite' -ForegroundColor Magenta
Write-Host '================================================================' -ForegroundColor Magenta
Write-Host (' PowerShell : {0} ({1})' -f $PSVersionTable.PSVersion, $PSVersionTable.PSEdition)
Write-Host (' Repo root  : {0}' -f $RepoRoot)
Write-Host (' Cases      : {0}' -f $cases.Count)

if ($cases.Count -eq 0) {
    Write-Host ''
    Write-Host ('No test cases matched ''{0}''.' -f $Name) -ForegroundColor Yellow
    exit 1
}

# The suite total is accumulated by the harness across cases; start clean.
Set-Variable -Name 'DdTestSuiteTally' -Scope Global -Value ([pscustomobject]@{ Passed = 0; Failed = 0 })

$results = New-Object 'System.Collections.Generic.List[object]'
foreach ($case in $cases) {
    Write-Host ''
    Write-Host ('=== {0}' -f $case.Name) -ForegroundColor Magenta
    $exit = 0
    try {
        & $case.FullName -RepoRoot $RepoRoot
        $exit = $LASTEXITCODE
        if ($null -eq $exit) { $exit = 0 }
    }
    catch {
        Write-Host ('  CASE ERRORED: {0}' -f $_.Exception.Message) -ForegroundColor Red
        $exit = 1
    }
    $results.Add([pscustomobject]@{ Name = $case.Name; Failed = [int]$exit }) | Out-Null
}

$resultRows = $results.ToArray()
$failedCases = @($resultRows | Where-Object { $_.Failed -ne 0 })

Write-Host ''
Write-Host '================================================================' -ForegroundColor Magenta
Write-Host ' SUITE SUMMARY' -ForegroundColor Magenta
Write-Host '================================================================' -ForegroundColor Magenta
foreach ($row in $resultRows) {
    $label = if ($row.Failed -eq 0) { 'PASS' } else { ('FAIL ({0})' -f $row.Failed) }
    $colour = if ($row.Failed -eq 0) { 'Green' } else { 'Red' }
    Write-Host ('  {0,-10} {1}' -f $label, $row.Name) -ForegroundColor $colour
}
Write-Host ''
$tally = Get-Variable -Name 'DdTestSuiteTally' -Scope Global -ErrorAction SilentlyContinue
$totalPassed = if ($null -ne $tally) { [int]$tally.Value.Passed } else { 0 }
$totalFailed = if ($null -ne $tally) { [int]$tally.Value.Failed } else { 0 }
$platform = if ($PSVersionTable.ContainsKey('Platform')) { $PSVersionTable.Platform } else { 'Win32NT' }
# Printed so the number that goes into CHANGELOG / SPEC is one that was
# observed, together with the environment it was observed on. The count is
# loop-driven and moves with the content the cases read, so it cannot be
# derived by arithmetic from a previous release's figure.
Write-Host ('  Assertions : {0} passed, {1} failed' -f $totalPassed, $totalFailed)
Write-Host ('  Measured on: PowerShell {0} ({1}) on {2}' -f `
    $PSVersionTable.PSVersion, $PSVersionTable.PSEdition, $platform)

if ($failedCases.Count -eq 0) {
    Write-Host (' ALL {0} CASE(S) PASSED' -f $resultRows.Count) -ForegroundColor Green
    exit 0
}
Write-Host (' {0} of {1} CASE(S) FAILED' -f $failedCases.Count, $resultRows.Count) -ForegroundColor Red
exit $failedCases.Count
