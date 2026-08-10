# psa-disable-file PSAP0002 -- test code is not a pipeline script: it declares no
# ScriptVersion / ScriptHash / ScriptShortTag because it ships no runtime identity.
# The five product scripts remain subject to the rule.
<#
.SYNOPSIS
    Gate G-17: static extraction shadow port integrity (audit R5-H01 /
    R5-H02 / W12).
.DESCRIPTION
    Pins the wave-W12 shadow port of the research static extractor:
      1. Identity gate: the marker-delimited payload embedded in the
         chipset script is byte-identical to the fragment file (markers
         included), and each side carries the span exactly once.
      2. Structural pins on the span: queue-based traversal (two Enqueue
         sites), MaxDepth bounds at dequeue and re-enqueue, SHA-256
         dedup, the four-status vocabulary, and the decision chain that
         keeps PartialExtraction distinct from ExtractionComplete (zero
         INF is never complete).
      3. Prohibited-capability scan of the span: no download primitives,
         no ServiceBinary logic, no first-match register consumption, no
         compat-scoring vocabulary (all tokens assembled so this file
         never trips its own scan).
      4. Measured C# behavior: the decoder compiles, a garbage probe
         returns a typed non-stream result instead of throwing, and the
         extraction-root escape rejection is present in source.
      5. Measured resolver behavior: File-table long-name resolution,
         suffix-convention fallback, verbatim base names, case-insensitive
         key match.
      6. Measured orchestrator behavior: a run without a usable extractor
         still yields a graph whose container records carry the
         audit-mandated 13 fields verbatim and in order; the schema
         detector names a stripped field (built-in negative); the graph
         writer round-trips through JSON; the MaxDepth ceiling is
         enforced.
      7. Report-only research agreement: the C# here-strings of fragment
         and research toolkit are compared namespace-normalized; a
         divergence is REPORTED, never failed (the research artifact is
         manifest-preserved and is not a build input).
      8. P04 wiring and placement: the shadow call, the manifests graph
         path, the workspace directories, the ShadowFailed vocabulary,
         and the span sitting outside (after) every canon region.
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
$researchPath = Join-Path $RepoRoot 'tools/amd-chipset-driver-research/Invoke-AmdChipsetDriverResearch.ps1'
$fragmentId   = 'amd-static-extraction v1'
$beginMarker  = ('# ===== BEGIN SOURCE-FRAGMENT {0} =====' -f $fragmentId)
$endMarker    = ('# ===== END SOURCE-FRAGMENT {0} =====' -f $fragmentId)

function Get-G17TokenCount {
    param([string]$Text, [string]$Token)
    $count = 0
    $index = 0
    while ($true) {
        $index = $Text.IndexOf($Token, $index, [System.StringComparison]::Ordinal)
        if ($index -lt 0) { break }
        $count++
        $index += $Token.Length
    }
    return $count
}

function Test-G17ContainerRecord {
    param($Record, [string[]]$RequiredFields)
    $names = @($Record.PSObject.Properties.Name)
    $missing = @()
    foreach ($field in $RequiredFields) {
        if ($field -notin $names) { $missing += $field }
    }
    return $missing
}

# Presence guard FIRST so a pre-W12 tree fails by NAME instead of by an
# unhandled read exception (negative-control discipline: silence and
# explosions are not evidence).
Write-TestSection 'G-17: shadow port presence'
$fragmentPresent = Test-Path -LiteralPath $fragmentPath
Assert-True 'fragment file exists' $fragmentPresent
if (-not $fragmentPresent) {
    $result = Get-TestResult
    Write-Host ''
    Write-Host ('{0}: {1} passed, {2} failed' -f (Split-Path -Leaf $PSCommandPath), $result.Passed, $result.Failed) -ForegroundColor Red
    exit $result.Failed
}

# Byte-faithful strings: a single-byte round-trip encoding makes string
# equality equivalent to byte equality.
$byteEncoding  = [System.Text.Encoding]::GetEncoding(28591)
$chipsetText   = $byteEncoding.GetString([System.IO.File]::ReadAllBytes($chipsetPath))
$fragmentText  = $byteEncoding.GetString([System.IO.File]::ReadAllBytes($fragmentPath))
$researchText  = $byteEncoding.GetString([System.IO.File]::ReadAllBytes($researchPath))

$tmpDir = Join-Path ([System.IO.Path]::GetTempPath()) ('g17-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $tmpDir -Force | Out-Null
try {
    Write-TestSection 'G-17: fragment file and identity gate'
    Assert-Equal 'fragment BEGIN marker count' 1 (Get-G17TokenCount -Text $fragmentText -Token $beginMarker)
    Assert-Equal 'fragment END marker count' 1 (Get-G17TokenCount -Text $fragmentText -Token $endMarker)
    Assert-Equal 'chipset BEGIN marker count' 1 (Get-G17TokenCount -Text $chipsetText -Token $beginMarker)
    Assert-Equal 'chipset END marker count' 1 (Get-G17TokenCount -Text $chipsetText -Token $endMarker)

    $fragBegin = $fragmentText.IndexOf($beginMarker, [System.StringComparison]::Ordinal)
    $fragEnd   = $fragmentText.IndexOf($endMarker, [System.StringComparison]::Ordinal)
    $fragSpan  = $fragmentText.Substring($fragBegin, $fragEnd + $endMarker.Length - $fragBegin)
    $chipBegin = $chipsetText.IndexOf($beginMarker, [System.StringComparison]::Ordinal)
    $chipSpan  = $chipsetText.Substring($chipBegin, $fragSpan.Length)
    Assert-True 'embedded span is byte-identical to the fragment span (markers included)' ($chipSpan -ceq $fragSpan)
    $mutatedSpan = $fragSpan.Remove(200, 1).Insert(200, '~')
    Assert-False 'a one-byte mutation is detected by the identity comparison' ($mutatedSpan -ceq $fragSpan)

    Write-TestSection 'G-17: structural pins on the span'
    Assert-Equal 'two queue Enqueue sites (initial + nested re-enqueue)' 2 (Get-G17TokenCount -Text $fragSpan -Token '$queue.Enqueue(')
    Assert-True 'MaxDepth upper bound applied at dequeue' ($fragSpan.Contains('-gt $MaxDepth'))
    Assert-True 'MaxDepth bound applied before re-enqueue' ($fragSpan.Contains('-lt $MaxDepth'))
    Assert-True 'SHA-256 dedup before extraction' ($fragSpan.Contains('$seenHashes.ContainsKey('))
    foreach ($status in @('ExtractionComplete', 'PartialExtraction', 'ExtractedWithErrors', 'ExtractionFailed')) {
        Assert-True ('status vocabulary carries {0}' -f $status) ($fragSpan.Contains("'" + $status + "'"))
    }
    $normalizedSpan = ($fragSpan -replace '\s+', ' ')
    Assert-Pattern 'zero-INF never resolves to ExtractionComplete (decision chain)' `
        "elseif \(\`$infFiles\.Count -gt 0\) \{ 'ExtractionComplete' \} else \{ 'PartialExtraction' \}" $normalizedSpan

    Write-TestSection 'G-17: prohibited capabilities stay out of the span'
    $downloadTokens = @(('Invoke-' + 'WebRequest'), ('Download' + 'File'), ('Start-' + 'BitsTransfer'))
    foreach ($token in $downloadTokens) {
        Assert-Equal ('no download primitive: {0}' -f $token) 0 (Get-G17TokenCount -Text $fragSpan -Token $token)
    }
    Assert-Equal 'no ServiceBinary logic' 0 (Get-G17TokenCount -Text $fragSpan -Token ('Service' + 'Binary'))
    Assert-Equal 'no first-match register consumption' 0 (Get-G17TokenCount -Text $fragSpan -Token ('$mat' + 'ches[0]'))
    Assert-Equal 'no compat-scoring vocabulary' 0 (Get-G17TokenCount -Text $fragSpan.ToLowerInvariant() -Token ('omp' + 'at'))

    Write-TestSection 'G-17: measured C# decoder behavior'
    . $fragmentPath
    Assert-NoThrow 'decoder compiles (Add-Type)' { Initialize-AmdStaticExtractionDecoder }
    $garbagePath = Join-Path $tmpDir 'garbage.bin'
    [System.IO.File]::WriteAllBytes($garbagePath, [byte[]](1..200 | ForEach-Object { [byte]($_ % 251) }))
    $probe = Get-AmdStaticIsSetupStreamProbe -Path $garbagePath
    Assert-False 'garbage input is not classified as ISSetupStream' ([bool]$probe.IsSetupStream)
    Assert-True 'garbage probe returns a typed error instead of throwing' (-not [string]::IsNullOrEmpty([string]$probe.Error))
    Assert-True 'safe-output-path guard is present in source' ($fragSpan.Contains('GetSafeOutputPath'))
    Assert-True 'extraction-root escape rejection is present in source' ($fragSpan.Contains('escapes the extraction root'))

    Write-TestSection 'G-17: measured resolver behavior'
    $rows = @([pscustomobject]@{ File = 'axpbus.inf2'; FileName = 'ax_1|axpbus.inf' })
    $resolved = Resolve-AmdStaticCabEntryName -EntryName 'axpbus.inf2' -FileTableRows $rows
    Assert-Equal 'File-table long-name resolution' 'axpbus.inf' ([string]$resolved.ResolvedName)
    Assert-Equal 'variant index parsed from the suffix' 2 ([int]$resolved.VariantIndex)
    Assert-Equal 'resolution vocabulary: FileTable' 'FileTable' ([string]$resolved.Resolution)
    $fallback = Resolve-AmdStaticCabEntryName -EntryName 'zeta.inf3'
    Assert-Equal 'suffix-convention fallback resolves the base name' 'zeta.inf' ([string]$fallback.ResolvedName)
    Assert-Equal 'resolution vocabulary: SuffixConvention' 'SuffixConvention' ([string]$fallback.Resolution)
    $plain = Resolve-AmdStaticCabEntryName -EntryName 'plain.inf'
    Assert-Equal 'plain entry keeps variant index zero' 0 ([int]$plain.VariantIndex)
    Assert-Equal 'resolution vocabulary: Verbatim' 'Verbatim' ([string]$plain.Resolution)
    $upper = Resolve-AmdStaticCabEntryName -EntryName 'AXPBUS.INF2' -FileTableRows $rows
    Assert-Equal 'File-table key match is case-insensitive' 'FileTable' ([string]$upper.Resolution)

    Write-TestSection 'G-17: measured orchestrator behavior and graph schema'
    $fakeInstaller = Join-Path $tmpDir 'amd_input.exe'
    [System.IO.File]::WriteAllBytes($fakeInstaller, [byte[]](1..300 | ForEach-Object { [byte]($_ % 251) }))
    $shadowRoot = Join-Path $tmpDir 'shadow'
    $graph = Invoke-AmdStaticExtractionShadow -InstallerPath $fakeInstaller -DestinationRoot $shadowRoot `
        -SevenZipPath (Join-Path $tmpDir 'no-such-7z') -MaxDepth 5
    Assert-Equal 'graph status without a usable extractor' 'ExtractedWithErrors' ([string]$graph.Status)
    Assert-Equal 'one container record for the single artifact' 1 (@($graph.Containers).Count)
    $requiredFields = @('SourceArtifactSha256', 'ContainerSha256', 'ParentContainerSha256', 'RelativePath',
        'Depth', 'Extractor', 'Status', 'ExitCode', 'Error', 'OutputRoot',
        'ProducedFiles', 'ProducedContainers', 'ProducedInfs')
    $actualFields = @(@($graph.Containers)[0].PSObject.Properties.Name)
    Assert-Equal 'container record carries the 13 audit fields verbatim, in order' `
        ($requiredFields -join ',') ($actualFields -join ',')
    Assert-Equal 'positive record: schema detector finds nothing missing' 0 `
        (@(Test-G17ContainerRecord -Record @($graph.Containers)[0] -RequiredFields $requiredFields).Count)
    $strippedHash = [ordered]@{}
    foreach ($field in $requiredFields) {
        if ($field -ne 'ProducedInfs') { $strippedHash[$field] = 'x' }
    }
    Assert-Equal 'built-in negative: the stripped field is NAMED' 'ProducedInfs' `
        (@(Test-G17ContainerRecord -Record ([pscustomobject]$strippedHash) -RequiredFields $requiredFields) -join ',')
    Assert-Equal 'graph top-level shape' `
        'SchemaVersion,GeneratedAtUtc,ToolIdentity,MaxDepth,Status,MsiFileTable,Containers,Infs,ParityNote' `
        (@($graph.PSObject.Properties.Name) -join ',')
    Assert-Equal 'graph schema version' '1.0' ([string]$graph.SchemaVersion)
    Assert-True 'MSI File-table status is typed' ([string]$graph.MsiFileTable.Status -in @('Read', 'Failed', 'Unavailable'))
    $graph.ToolIdentity = [pscustomobject]@{ ScriptVersion = 'g17-test'; FragmentId = $fragmentId }
    $graph.ParityNote.CurrentTreeInfCount = 7
    $graphPath = Join-Path $tmpDir 'extraction-graph.json'
    Write-AmdStaticExtractionGraph -Graph $graph -Path $graphPath
    $rehydrated = Get-Content -LiteralPath $graphPath -Raw | ConvertFrom-Json
    Assert-Equal 'JSON round-trip: status' 'ExtractedWithErrors' ([string]$rehydrated.Status)
    Assert-Equal 'JSON round-trip: caller-filled parity note' 7 ([int]$rehydrated.ParityNote.CurrentTreeInfCount)
    Assert-Equal 'JSON round-trip: fragment identity' $fragmentId ([string]$rehydrated.ToolIdentity.FragmentId)
    $ceilingTripped = $false
    try {
        Invoke-AmdStaticExtractionShadow -InstallerPath $fakeInstaller -DestinationRoot $shadowRoot `
            -SevenZipPath 'unused' -MaxDepth 11 | Out-Null
    }
    catch {
        $ceilingTripped = $true
    }
    Assert-True 'MaxDepth ceiling (10) is enforced' $ceilingTripped

    Write-TestSection 'G-17: research decoder agreement (report-only)'
    $sourceOpen = '$source = @' + "'"
    $sourceClose = "'" + '@'
    $fragCsStart = $fragSpan.IndexOf($sourceOpen, [System.StringComparison]::Ordinal)
    $fragCsEnd   = $fragSpan.IndexOf($sourceClose, $fragCsStart, [System.StringComparison]::Ordinal)
    $resCsStart  = $researchText.IndexOf($sourceOpen, [System.StringComparison]::Ordinal)
    $resCsEnd    = $researchText.IndexOf($sourceClose, $resCsStart, [System.StringComparison]::Ordinal)
    Assert-True 'both C# here-strings located' (($fragCsStart -ge 0) -and ($fragCsEnd -gt $fragCsStart) -and
        ($resCsStart -ge 0) -and ($resCsEnd -gt $resCsStart))
    $fragCs = $fragSpan.Substring($fragCsStart, $fragCsEnd - $fragCsStart) -replace 'AmdStaticExtraction', '__NS__'
    $resCs  = $researchText.Substring($resCsStart, $resCsEnd - $resCsStart) -replace 'AmdChipsetResearch', '__NS__'
    if ($fragCs -ceq $resCs) {
        Write-Host '  research decoder agreement (namespace-normalized): MATCH' -ForegroundColor Green
    }
    else {
        Write-Host '  research decoder agreement (namespace-normalized): DIVERGENCE (report-only; the research artifact is manifest-preserved and this is NOT a failure)' -ForegroundColor Yellow
    }

    Write-TestSection 'G-17: P04 wiring and placement'
    Assert-True 'P04 invokes the shadow orchestrator on the fetched installer' `
        ($chipsetText.Contains('Invoke-AmdStaticExtractionShadow -InstallerPath $Ctx.Installer'))
    Assert-True 'graph is written under the manifests workspace' `
        ($chipsetText.Contains("Join-Path `$Ctx.Paths.Manifests 'extraction-graph.json'"))
    Assert-True 'workspace declares Manifests' ($chipsetText.Contains("Manifests = Join-Path `$Ctx.WorkRoot 'manifests'"))
    Assert-True 'workspace declares ShadowExtract' ($chipsetText.Contains("ShadowExtract = Join-Path `$Ctx.WorkRoot 'shadow-extracted'"))
    Assert-True 'ShadowFailed vocabulary is wired at the call site' ($chipsetText.Contains("'ShadowFailed'"))
    $lastCanonClose = $chipsetText.LastIndexOf('# <<< CANONICAL', [System.StringComparison]::Ordinal)
    Assert-True 'span sits after the last canon region (never inside)' ($chipBegin -gt $lastCanonClose)
}
finally {
    Remove-Item -LiteralPath $tmpDir -Recurse -Force -ErrorAction SilentlyContinue
}

$result = Get-TestResult
Write-Host ''
Write-Host ('{0}: {1} passed, {2} failed' -f (Split-Path -Leaf $PSCommandPath), $result.Passed, $result.Failed) `
    -ForegroundColor $(if ($result.Failed -eq 0) { 'Green' } else { 'Red' })
exit $result.Failed
