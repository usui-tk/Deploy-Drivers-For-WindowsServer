# psa-disable-file PSAP0002 -- test code is not a pipeline script: it declares no
# ScriptVersion / ScriptHash / ScriptShortTag because it ships no runtime identity.
# The five product scripts remain subject to the rule.
<#
.SYNOPSIS
    Gate G-22: third-party attribution retention for migrated code
    (audit R5-M07 / W12).
.DESCRIPTION
    The static extractor port carries ISx-informed C# (MIT). This gate
    pins that the attribution travels WITH the code everywhere it lives:
      1. The embedded span in the chipset script names lifenjoiner/ISx
         and points at THIRD-PARTY-NOTICES.md.
      2. The fragment file (source of truth) carries the same in-span
         attribution.
      3. The repository-root THIRD-PARTY-NOTICES.md exists, names the
         upstream, carries the full MIT license text, and cross-references
         the research toolkit's own notices file (which must still exist).
      4. Both README languages reference the root notices file.
      5. Built-in negative: an attribution-stripped copy of the span is
         detected by the same detector this gate uses (self-check).
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

$chipsetPath  = Join-Path $RepoRoot 'Deploy-AMDChipsetDriverOnWindowsServer.ps1'
$fragmentPath = Join-Path $RepoRoot 'tools/source-fragments/AmdStaticExtraction.fragment.ps1'
$noticesPath  = Join-Path $RepoRoot 'THIRD-PARTY-NOTICES.md'
$researchNoticesPath = Join-Path $RepoRoot 'tools/amd-chipset-driver-research/THIRD-PARTY-NOTICES.md'
$beginMarker  = '# ===== BEGIN SOURCE-FRAGMENT amd-static-extraction v1 ====='
$endMarker    = '# ===== END SOURCE-FRAGMENT amd-static-extraction v1 ====='

function Test-G22SpanAttribution {
    param([string]$SpanText)
    return ($SpanText.Contains('lifenjoiner/ISx') -and $SpanText.Contains('THIRD-PARTY-NOTICES.md'))
}

function Get-G22Span {
    param([string]$Text)
    $begin = $Text.IndexOf($beginMarker, [System.StringComparison]::Ordinal)
    $end   = $Text.IndexOf($endMarker, [System.StringComparison]::Ordinal)
    if ($begin -lt 0 -or $end -le $begin) { return $null }
    return $Text.Substring($begin, $end + $endMarker.Length - $begin)
}

# Presence guard FIRST so a pre-W12 tree fails by NAME instead of by an
# unhandled read exception.
Write-TestSection 'G-22: attribution asset presence'
$fragmentPresent = Test-Path -LiteralPath $fragmentPath
$noticesPresent  = Test-Path -LiteralPath $noticesPath
Assert-True 'fragment file exists' $fragmentPresent
Assert-True 'repository-root THIRD-PARTY-NOTICES.md exists' $noticesPresent
if (-not ($fragmentPresent -and $noticesPresent)) {
    $result = Get-TestResult
    Write-Host ''
    Write-Host ('{0}: {1} passed, {2} failed' -f (Split-Path -Leaf $PSCommandPath), $result.Passed, $result.Failed) -ForegroundColor Red
    exit $result.Failed
}

Write-TestSection 'G-22: in-span attribution (both copies)'
$chipsetText  = [System.IO.File]::ReadAllText($chipsetPath)
$fragmentText = [System.IO.File]::ReadAllText($fragmentPath)
$chipSpan = Get-G22Span -Text $chipsetText
$fragSpan = Get-G22Span -Text $fragmentText
Assert-True 'chipset carries the marker span' ($null -ne $chipSpan)
Assert-True 'fragment carries the marker span' ($null -ne $fragSpan)
Assert-True 'embedded span names the upstream and the notices file' (Test-G22SpanAttribution -SpanText $chipSpan)
Assert-True 'fragment span names the upstream and the notices file' (Test-G22SpanAttribution -SpanText $fragSpan)

Write-TestSection 'G-22: repository-root notices file'
$notices = [System.IO.File]::ReadAllText($noticesPath)
Assert-True 'notices name the ISx project' ($notices.Contains('ISx'))
Assert-True 'notices name the upstream author' ($notices.Contains('lifenjoiner'))
Assert-True 'notices carry the MIT license header' ($notices.Contains('MIT License'))
Assert-True 'notices carry the full MIT grant text' ($notices.Contains('Permission is hereby granted, free of charge'))
Assert-True 'notices carry the MIT warranty disclaimer' ($notices.Contains('THE SOFTWARE IS PROVIDED "AS IS"'))
Assert-True 'notices cross-reference the research toolkit notices' `
    ($notices.Contains('tools/amd-chipset-driver-research/THIRD-PARTY-NOTICES.md'))
Assert-True 'research toolkit notices still exist (manifest-preserved)' (Test-Path -LiteralPath $researchNoticesPath)

Write-TestSection 'G-22: README references (both languages)'
$readmeEn = [System.IO.File]::ReadAllText((Join-Path $RepoRoot 'README.md'))
$readmeJa = [System.IO.File]::ReadAllText((Join-Path $RepoRoot 'README.ja.md'))
Assert-True 'README.md references the notices file' ($readmeEn.Contains('THIRD-PARTY-NOTICES.md'))
Assert-True 'README.ja.md references the notices file' ($readmeJa.Contains('THIRD-PARTY-NOTICES.md'))

Write-TestSection 'G-22: built-in negative (attribution-stripped span is detected)'
$strippedLines = @($chipSpan -split "`r`n" | Where-Object {
    -not ($_.Contains('ISx') -or $_.Contains('lifenjoiner') -or $_.Contains('THIRD-PARTY-NOTICES.md'))
})
$strippedSpan = $strippedLines -join "`r`n"
Assert-False 'the detector flags an attribution-stripped copy of the span' (Test-G22SpanAttribution -SpanText $strippedSpan)

$result = Get-TestResult
Write-Host ''
Write-Host ('{0}: {1} passed, {2} failed' -f (Split-Path -Leaf $PSCommandPath), $result.Passed, $result.Failed) `
    -ForegroundColor $(if ($result.Failed -eq 0) { 'Green' } else { 'Red' })
exit $result.Failed
