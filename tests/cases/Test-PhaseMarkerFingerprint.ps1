# psa-disable-file PSAP0002 -- test code is not a pipeline script: it declares no
# ScriptVersion / ScriptHash / ScriptShortTag because it ships no runtime identity.
<#
.SYNOPSIS
    Gate G-18: content-addressed phase markers v2 (audit v5 R5-H03 /
    feedback 5B-3 / W13).
.DESCRIPTION
    1. Presence guard: the five marker functions exist in C/G/M (named
       fail + standard footer early-exit when absent, so a pre-W13 tree
       fails loudly instead of dying on extraction).
    2. Byte identity of the five marker functions across C/G/M.
    3. Pure-primitive fixtures for Get-PhaseFingerprintHash: determinism,
       key-order independence, value sensitivity, null coercion,
       non-ASCII stability, typed empty result.
    4. Live marker round-trip in a temp workspace: v2 hit on matching
       fields; miss on mutated fields; legacy-mode semantics preserved;
       a schema-less v1 marker is a MISS under a fingerprinted check;
       -Force forces a miss; a garbage marker parses to $null; a marker
       with a tampered stored fingerprint is a miss (negative control).
    5. Call-site pins: P03/P04/P05 pass fingerprint fields in C/G and M;
       the C/G P03 hit path verifies content by SHA and no longer selects
       by LastWriteTime; the schema constants exist.
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
$graphicsPath = Join-Path $RepoRoot 'Deploy-AMDGraphicsDriverOnWindowsServer.ps1'
$bthpanPath   = Join-Path $RepoRoot 'Deploy-MSBthPanInboxOnWindowsServer.ps1'
$markerSisters = @($chipsetPath, $graphicsPath, $bthpanPath)

$markerFunctionNames = @(
    'Get-PhaseFingerprintHash',
    'Get-PhaseMarkerRecord',
    'Test-PhaseMarker',
    'Set-PhaseMarker',
    'Clear-PhaseMarker'
)

function Get-G18FunctionText {
    param([string]$Path, [string]$Name)
    $tokens = $null; $errors = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseFile((Resolve-Path $Path).Path, [ref]$tokens, [ref]$errors)
    foreach ($fn in $ast.FindAll({ param($node) $node -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true)) {
        if ($fn.Name -eq $Name) { return $fn.Extent.Text }
    }
    return ''
}

function Get-G18TextHash {
    [OutputType([string])]
    param([string]$Text)
    if ([string]::IsNullOrEmpty($Text)) { return '(absent)' }
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try {
        return [System.BitConverter]::ToString($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($Text))).Replace('-', '').Substring(0, 16)
    }
    finally { $sha.Dispose() }
}

Write-TestSection 'G-18: presence guard (five marker functions in C/G/M)'
$presenceOk = $true
foreach ($path in $markerSisters) {
    $leaf = Split-Path -Leaf $path
    foreach ($name in $markerFunctionNames) {
        $present = (Get-G18FunctionText -Path $path -Name $name) -ne ''
        Assert-True ('{0}: {1} is defined' -f $leaf, $name) $present
        if (-not $present) { $presenceOk = $false }
    }
}
if (-not $presenceOk) {
    $result = Get-TestResult
    Write-Host ''
    Write-Host ('{0}: {1} passed, {2} failed' -f (Split-Path -Leaf $PSCommandPath), $result.Passed, $result.Failed) -ForegroundColor Red
    exit $result.Failed
}

Write-TestSection 'G-18: byte identity of the marker functions across C/G/M'
foreach ($name in $markerFunctionNames) {
    $hashes = @($markerSisters | ForEach-Object { Get-G18TextHash (Get-G18FunctionText -Path $_ -Name $name) })
    Assert-Equal ('{0}: identical in C/G/M' -f $name) 1 (@($hashes | Sort-Object -Unique)).Count
}

# Bring the five functions into this session from the chipset copy.
. (Get-ScriptFunctionBlock -Path $chipsetPath -Name $markerFunctionNames)

Write-TestSection 'G-18: pure fingerprint primitive fixtures'
$hashA = Get-PhaseFingerprintHash -Fields @{ b = '2'; a = '1' }
$hashB = Get-PhaseFingerprintHash -Fields @{ a = '1'; b = '2' }
$hashC = Get-PhaseFingerprintHash -Fields @{ a = '1'; b = '3' }
Assert-True 'key order does not change the fingerprint' ($hashA -ceq $hashB)
Assert-True 'a value change changes the fingerprint' ($hashA -cne $hashC)
Assert-Equal 'fingerprint is 64 lowercase hex chars' 64 $hashA.Length
Assert-True 'fingerprint is lowercase' ($hashA -ceq $hashA.ToLowerInvariant())
$hashNull  = Get-PhaseFingerprintHash -Fields @{ a = $null }
$hashEmpty = Get-PhaseFingerprintHash -Fields @{ a = '' }
Assert-True 'null coerces to empty string' ($hashNull -ceq $hashEmpty)
$hashRepeat = Get-PhaseFingerprintHash -Fields @{ path = 'C:\x\y'; sha = 'abc123' }
Assert-True 'deterministic across calls' ($hashRepeat -ceq (Get-PhaseFingerprintHash -Fields @{ sha = 'abc123'; path = 'C:\x\y' }))
$hashUnicode = Get-PhaseFingerprintHash -Fields @{ name = [char]0x65E5 + [char]0x672C }
Assert-Equal 'non-ASCII values hash stably' 64 $hashUnicode.Length
Assert-Equal 'empty field set is still a typed fingerprint' 64 (Get-PhaseFingerprintHash).Length

Write-TestSection 'G-18: live marker round-trip (temp workspace)'
$tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ('g18-' + [guid]::NewGuid().ToString('N'))
$markersDir = Join-Path $tempRoot 'markers'
New-Item -ItemType Directory -Path $markersDir -Force | Out-Null
try {
    $ctx = [pscustomobject]@{
        Paths = [pscustomobject]@{ Markers = $markersDir }
        Force = $false
    }
    $inputFields = @{ ArtifactSha256 = 'abc'; ExtractionSchemaVersion = '1' }
    Set-PhaseMarker -Ctx $ctx -PhaseId 'P04' -Metadata @{ note = 'x' } -InputFields $inputFields -OutputFields @{ InfCount = 3 }
    Assert-True 'v2 hit on matching expected fields' (Test-PhaseMarker -Ctx $ctx -PhaseId 'P04' -ExpectedInputFields $inputFields)
    Assert-False 'v2 miss on a mutated expected field' (Test-PhaseMarker -Ctx $ctx -PhaseId 'P04' -ExpectedInputFields @{ ArtifactSha256 = 'zzz'; ExtractionSchemaVersion = '1' })
    Assert-True 'legacy-mode check (no expected fields) still hits' (Test-PhaseMarker -Ctx $ctx -PhaseId 'P04')

    $record = Get-PhaseMarkerRecord -Ctx $ctx -PhaseId 'P04'
    Assert-Equal 'record round-trip: schemaVersion' '2' ([string]$record.schemaVersion)
    Assert-Equal 'record round-trip: output field survives' 3 ([int]$record.output.fields.InfCount)
    Assert-Equal 'record round-trip: metadata survives under meta' 'x' ([string]$record.meta.note)

    # v1 (schema-less) marker: legacy-mode hit, fingerprinted MISS (plan-fixed).
    '{"phase":"P05","completedAt":"x","meta":{}}' | Set-Content -Path (Join-Path $markersDir '.P05.done') -Encoding UTF8
    Assert-True  'v1 marker still hits a legacy-mode check' (Test-PhaseMarker -Ctx $ctx -PhaseId 'P05')
    Assert-False 'v1 marker is a MISS under a fingerprinted check' (Test-PhaseMarker -Ctx $ctx -PhaseId 'P05' -ExpectedInputFields @{ a = '1' })

    # -Force forces a miss in both modes.
    $ctx.Force = $true
    Assert-False 'Force misses the fingerprinted check' (Test-PhaseMarker -Ctx $ctx -PhaseId 'P04' -ExpectedInputFields $inputFields)
    Assert-False 'Force misses the legacy-mode check' (Test-PhaseMarker -Ctx $ctx -PhaseId 'P04')
    $ctx.Force = $false

    # Garbage marker parses to $null.
    'not json at all' | Set-Content -Path (Join-Path $markersDir '.P06.done') -Encoding UTF8
    Assert-True 'garbage marker record is $null' ($null -eq (Get-PhaseMarkerRecord -Ctx $ctx -PhaseId 'P06'))

    # Negative control: tamper the STORED input fingerprint in place.
    $markerPath = Join-Path $markersDir '.P04.done'
    $tampered = (Get-Content -Path $markerPath -Raw) -replace '"fingerprint":\s*"[0-9a-f]{8}', '"fingerprint": "00000000'
    $tampered | Set-Content -Path $markerPath -Encoding UTF8
    Assert-False 'tampered stored fingerprint is a miss' (Test-PhaseMarker -Ctx $ctx -PhaseId 'P04' -ExpectedInputFields $inputFields)
}
finally {
    Remove-Item -Path $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
}

Write-TestSection 'G-18: call-site pins (fingerprinted phases pass fields)'
foreach ($entry in @(
    @{ Path = $chipsetPath;  Leaf = 'chipset' },
    @{ Path = $graphicsPath; Leaf = 'graphics' }
)) {
    $p03Text = Get-G18FunctionText -Path $entry.Path -Name 'Invoke-PrepPhase03_FetchInstaller'
    $p04Text = Get-G18FunctionText -Path $entry.Path -Name 'Invoke-PrepPhase04_ExtractInstaller'
    $p05Text = Get-G18FunctionText -Path $entry.Path -Name 'Invoke-PrepPhase05_AnalyzeInfs'
    Assert-True ('{0}: P03 writes input fields' -f $entry.Leaf) ($p03Text.Contains('-InputFields'))
    Assert-True ('{0}: P03 hit reads the marker record' -f $entry.Leaf) ($p03Text.Contains("Get-PhaseMarkerRecord -Ctx `$Ctx -PhaseId 'P03'"))
    Assert-True ('{0}: P03 hit verifies content by SHA' -f $entry.Leaf) ($p03Text.Contains('Get-FileHash'))
    Assert-False ('{0}: P03 no longer selects by LastWriteTime' -f $entry.Leaf) ($p03Text.Contains('Sort-Object LastWriteTime'))
    Assert-True ('{0}: P04 checks an expected input fingerprint' -f $entry.Leaf) ($p04Text.Contains('-ExpectedInputFields'))
    Assert-True ('{0}: P04 records the INF-layer manifest' -f $entry.Leaf) ($p04Text.Contains('Get-InfLayerManifestHash'))
    Assert-True ('{0}: P05 checks an expected input fingerprint' -f $entry.Leaf) ($p05Text.Contains('-ExpectedInputFields'))
    Assert-True ('{0}: P05 chains the inventory schema constant' -f $entry.Leaf) ($p05Text.Contains('InventorySchemaVersion'))
    $rawText = Get-Content -Path $entry.Path -Raw
    Assert-True ('{0}: ExtractionSchemaVersion constant exists' -f $entry.Leaf) ($rawText.Contains('$Script:ExtractionSchemaVersion'))
    Assert-True ('{0}: InventorySchemaVersion constant exists' -f $entry.Leaf) ($rawText.Contains('$Script:InventorySchemaVersion'))
}
$bthP03 = Get-G18FunctionText -Path $bthpanPath -Name 'Invoke-PrepPhase03_FetchInstaller'
$bthP04 = Get-G18FunctionText -Path $bthpanPath -Name 'Invoke-PrepPhase04_ExtractInstaller'
$bthP05 = Get-G18FunctionText -Path $bthpanPath -Name 'Invoke-PrepPhase05_AnalyzeInfs'
Assert-True 'bthpan: P03 records the source-set fingerprint' ($bthP03.Contains('SourceSetSha256'))
Assert-True 'bthpan: P03 hit re-verifies the set fingerprint' ($bthP03.Contains('Get-BthPanSourceSetFingerprint'))
Assert-True 'bthpan: P04 chains and records set fingerprints' ($bthP04.Contains('CopiedSetSha256'))
Assert-True 'bthpan: P05 chains the copied-set fingerprint' ($bthP05.Contains('CopiedSetSha256'))

$result = Get-TestResult
Write-Host ''
Write-Host ('{0}: {1} passed, {2} failed' -f (Split-Path -Leaf $PSCommandPath), $result.Passed, $result.Failed) `
    -ForegroundColor $(if ($result.Failed -eq 0) { 'Green' } else { 'Red' })
exit $result.Failed
