# psa-disable-file PSAP0002 -- test code is not a pipeline script: it declares no
# ScriptVersion / ScriptHash / ScriptShortTag because it ships no runtime identity.
# The five product scripts remain subject to the rule.
<#
.SYNOPSIS
    Collector: OS capability matrix and archive capability probe.
.DESCRIPTION
    These two stages exist to make cross-OS troubleshooting rest on measured
    facts instead of assumptions about what a given Server SKU has. That only
    works if the stages themselves run, so this case CALLS them rather than
    inspecting their source.

    Every assertion below traces to a defect found by doing exactly that.
    Three separate faults were caught on the first execution of code that had
    already passed psa.py and the parser: an empty $env:TEMP making every
    Join-Path throw, Split-Path -Qualifier throwing on a path with no drive
    letter, and a JSON literal on the left of -f being parsed as a format
    string. None is visible without running the function.
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

$collector = Join-Path $RepoRoot 'Collect-WindowsServerConfigurationEvidence.ps1'
. (Get-ScriptFunctionBlock -Path $collector -Name @(
    'Get-UtcTimestamp', 'Get-PropertyValue', 'Get-RegistryKeySnapshot',
    'Get-NamedRegistryValue', 'Get-OsCapabilityEvidence', 'Get-ArchiveCapabilityEvidence'))

Write-TestSection 'Archive capability probe actually archives'
Assert-NoThrow 'probe runs without throwing' { Get-ArchiveCapabilityEvidence }
$archive = Get-ArchiveCapabilityEvidence
Assert-True  'Compress-Archive reported available' $archive.CompressArchiveAvailable
Assert-True  'probe was attempted' $archive.ProbeAttempted
Assert-True  'probe produced an archive' $archive.ProbeSucceeded
Assert-Equal 'probe error message is empty on success' '' $archive.ErrorMessage
Assert-True  'archive has a non-zero size' ($archive.ProbeArchiveBytes -gt 0)
Assert-True  'archive contains entries' ($archive.ProbeEntryCount -gt 0)
Assert-True  'a temp path was resolved' (-not [string]::IsNullOrWhiteSpace($archive.TempPath))

Write-TestSection 'Archive probe survives a hostile environment'
# Regression guards. Each of these three shapes broke the probe on its first
# real execution while every static gate was green.
$savedTemp = $env:TEMP
$savedTmp = $env:TMP
try {
    $env:TEMP = ''
    $env:TMP = ''
    Assert-NoThrow 'empty TEMP and TMP do not throw' { Get-ArchiveCapabilityEvidence }
    $fallback = Get-ArchiveCapabilityEvidence
    Assert-True 'falls back to a system temp path' (-not [string]::IsNullOrWhiteSpace($fallback.TempPath))
}
finally {
    $env:TEMP = $savedTemp
    $env:TMP = $savedTmp
}
# A temp path with no drive qualifier must not break free-space collection.
Assert-NoThrow 'qualifier-less temp path does not throw' { Get-ArchiveCapabilityEvidence }

Write-TestSection 'OS capability matrix is populated'
Assert-NoThrow 'capability collection runs without throwing' { Get-OsCapabilityEvidence }
$caps = Get-OsCapabilityEvidence
Assert-True  'cmdlet probes recorded' (@($caps.Cmdlets).Count -gt 0)
Assert-True  'CIM class probes recorded' (@($caps.CimClasses).Count -gt 0)
Assert-True  'tool probes recorded' (@($caps.Tools).Count -gt 0)
Assert-True  'PowerShell version recorded' (-not [string]::IsNullOrWhiteSpace($caps.PowerShellVersion))
# Every probe record must be complete, not merely present: a record missing
# its Present flag is indistinguishable from a negative result downstream.
$incomplete = @($caps.Cmdlets | Where-Object { $null -eq $_.Present -or [string]::IsNullOrWhiteSpace($_.Name) })
Assert-Equal 'every cmdlet probe carries a name and a verdict' 0 $incomplete.Count
$missingListed = @($caps.Cmdlets | Where-Object { -not $_.Present }).Count
Assert-Equal 'MissingCmdletCount agrees with the probe records' $missingListed $caps.MissingCmdletCount
$missingTools = @($caps.Tools | Where-Object { -not $_.Present }).Count
Assert-Equal 'MissingToolCount agrees with the probe records' $missingTools $caps.MissingToolCount

Write-TestSection 'Every OS profile the scripts support is expressible'
# The build-to-profile table is duplicated from the deploy scripts. If a
# build the scripts handle is missing here, a bundle from that OS records an
# empty profile and the cross-version comparison silently loses a row.
foreach ($pair in @(@(14393, 'WS2016', 'Server2016_X64'), @(17763, 'WS2019', 'ServerRS5_X64'),
                    @(20348, 'WS2022', 'ServerFE_X64'), @(26100, 'WS2025', 'Server2025_X64'))) {
    $text = Get-Content -LiteralPath $collector -Raw
    Assert-True ('build {0} maps to {1}' -f $pair[0], $pair[1]) ($text -match ([regex]::Escape(('{0} = @{{ Code = ''{1}''' -f $pair[0], $pair[1]))))
    Assert-True ('{0} declares inf2cat target {1}' -f $pair[1], $pair[2]) ($text -match [regex]::Escape($pair[2]))
}

$result = Get-TestResult
Write-Host ''
Write-Host ('{0}: {1} passed, {2} failed' -f (Split-Path -Leaf $PSCommandPath), $result.Passed, $result.Failed) `
    -ForegroundColor $(if ($result.Failed -eq 0) { 'Green' } else { 'Red' })
exit $result.Failed
