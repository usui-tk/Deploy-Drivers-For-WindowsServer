# psa-disable-file PSAP0002 -- test code is not a pipeline script: it declares no
# ScriptVersion / ScriptHash / ScriptShortTag because it ships no runtime identity.
# The five product scripts remain subject to the rule.
<#
.SYNOPSIS
    Audit P1-E contracts: ProjectPreference wording and the measured-rank
    parser.
.DESCRIPTION
    Ruling H-03: the '[C] > [B] > [A]' ordering is the PROJECT'S preference,
    never an objective PnP ranking, and V06 must not assert WILL_REPLACE.
    This case pins:
      1. The retired wording (category-priority / WILL_REPLACE / the
         'outranks' claim) appears 0 times in Chipset/Graphics, and the
         replacement vocabulary is present.
      2. ConvertFrom-PnputilEnumDevicesDrivers parses the SYNTHETIC fixture
         (assembled from the Microsoft Learn syntax page and public field
         observations; real-host validation is operator-pending): device
         split, candidate split, optional Rank in hex and decimal, empty
         input yields zero devices.
      3. The parser and the report function are byte-identical in the two
         sisters that carry the decision layer.
      4. Negative control: the pre-W5 tree fails the wording contract.
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

$decisionSisters = @(
    'Deploy-AMDChipsetDriverOnWindowsServer.ps1',
    'Deploy-AMDGraphicsDriverOnWindowsServer.ps1'
)

# Retired wording, assembled so this file never matches its own scan.
$retiredCat  = 'category' + '-priority'
$retiredCat2 = 'category' + ' priority'
$retiredWill = 'WILL_' + 'REPLACE'
$retiredRank = 'outranks'

Write-TestSection 'P1-E: retired wording is gone; ProjectPreference vocabulary is present'
foreach ($leaf in $decisionSisters) {
    $text = Get-Content -LiteralPath (Join-Path $RepoRoot $leaf) -Raw
    foreach ($tok in @($retiredCat, $retiredCat2, $retiredWill, $retiredRank)) {
        Assert-Equal ('{0}: retired token #{1} appears 0 time(s)' -f $leaf, ([array]::IndexOf(@($retiredCat,$retiredCat2,$retiredWill,$retiredRank), $tok) + 1)) 0 ([regex]::Matches($text, [regex]::Escape($tok))).Count
    }
    Assert-True ('{0}: ProjectPreference vocabulary present' -f $leaf) ($text.Contains('ProjectPreference'))
    Assert-True ('{0}: PROJECT_PREFERS_INSTALL vocabulary present' -f $leaf) ($text.Contains('PROJECT_PREFERS_INSTALL'))
    Assert-True ('{0}: the not-a-PnP-rank caveat is stated' -f $leaf) ($text.Contains('not a PnP rank') -or $text.Contains('not PnP rank'))
}

Write-TestSection 'P1-E: measured-rank parser against the synthetic fixture'
$chipset = Join-Path $RepoRoot 'Deploy-AMDChipsetDriverOnWindowsServer.ps1'
. (Get-ScriptFunctionBlock -Path $chipset -Name @('ConvertFrom-PnputilEnumDevicesDrivers'))
$fixture = @"
Microsoft PnP Utility

Instance ID:                PCI\VEN_1022&DEV_15E4\3&11583659&0&E3
Device Description:         AMD PSP 11.0 Device
Class Name:                 System
Status:                     Started
Matching Drivers:
    Driver Name:            oem42.inf
    Original Name:          amdpsp.inf
    Provider Name:          Advanced Micro Devices, Inc
    Driver Version:         05/01/2026 5.28.0.0
    Matching Device Id:     PCI\VEN_1022&DEV_15E4
    Rank:                   0x00FF2000
    Driver Name:            machine.inf
    Original Name:          machine.inf
    Provider Name:          Microsoft
    Driver Version:         06/21/2006 10.0.26100.1
    Matching Device Id:     PCI\CC_1080
    Rank:                   16723968

Instance ID:                ACPI\PNP0A08\0
Device Description:         PCI Express Root Complex
Matching Drivers:
    Driver Name:            acpi.inf
    Original Name:          acpi.inf
    Provider Name:          Microsoft
    Driver Version:         06/21/2006 10.0.26100.1
"@
$r = @(ConvertFrom-PnputilEnumDevicesDrivers -Content $fixture)
Assert-Equal 'fixture: 2 devices parsed' 2 $r.Count
Assert-Equal 'fixture: device 1 instance id' 'PCI\VEN_1022&DEV_15E4\3&11583659&0&E3' $r[0].InstanceId
Assert-Equal 'fixture: device 1 description' 'AMD PSP 11.0 Device' $r[0].Description
Assert-Equal 'fixture: device 1 has 2 candidates' 2 (@($r[0].MatchingDrivers)).Count
Assert-Equal 'fixture: hex rank parsed' 16719872 $r[0].MatchingDrivers[0].Rank
Assert-Equal 'fixture: decimal rank parsed' 16723968 $r[0].MatchingDrivers[1].Rank
Assert-Equal 'fixture: candidate original name' 'amdpsp.inf' $r[0].MatchingDrivers[0].OriginalName
Assert-Equal 'fixture: device 2 has 1 candidate' 1 (@($r[1].MatchingDrivers)).Count
Assert-True  'fixture: absent Rank stays null (first-listed = best-ranked fact carries)' ($null -eq $r[1].MatchingDrivers[0].Rank)
Assert-Equal 'empty input yields zero devices' 0 (@(ConvertFrom-PnputilEnumDevicesDrivers -Content '')).Count

Write-TestSection 'P1-E: parser and report are byte-identical across the decision sisters'
function Get-FnTextW5 {
    param([string]$Path, [string]$Name)
    $t = $null; $e = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseFile((Resolve-Path $Path).Path, [ref]$t, [ref]$e)
    if (@($e).Count -gt 0) { throw ('{0}: parse error(s)' -f $Path) }
    foreach ($fn in $ast.FindAll({ param($n) $n -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true)) {
        if ($fn.Name -eq $Name) { return $fn.Extent.Text }
    }
    return '(absent)'
}
foreach ($name in @('ConvertFrom-PnputilEnumDevicesDrivers', 'Show-MeasuredDriverRankReport')) {
    $texts = @($decisionSisters | ForEach-Object { Get-FnTextW5 -Path (Join-Path $RepoRoot $_) -Name $name })
    Assert-Equal ('{0}: identical in both decision sisters' -f $name) 1 (@($texts | Sort-Object -Unique)).Count
}

$result = Get-TestResult
Write-Host ''
Write-Host ('{0}: {1} passed, {2} failed' -f (Split-Path -Leaf $PSCommandPath), $result.Passed, $result.Failed) `
    -ForegroundColor $(if ($result.Failed -eq 0) { 'Green' } else { 'Red' })
exit $result.Failed
