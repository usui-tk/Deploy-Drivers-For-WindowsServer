# psa-disable-file PSAP0002 -- test code is not a pipeline script: it declares no
# ScriptVersion / ScriptHash / ScriptShortTag because it ships no runtime identity.
<#
.SYNOPSIS
    Gate G-19: canonical package inventory identity (audit v5 R5-H04 /
    R5-H06 / feedback 5B-4 / W13).
.DESCRIPTION
    1. Presence guard: the five inventory helpers exist in C and G (named
       fail + standard footer early-exit on a pre-W13 tree).
    2. Byte identity of the five helpers across C/G.
    3. Generator pins: every inspected record carries InfSha256 /
       SourceArtifactSha256 / InspectionStatus; the per-INF ParseFailed
       path exists; the canonical JSON write precedes the CSV export; the
       P05 cache hit rehydrates from JSON and Import-Csv is gone from it;
       the required and best-effort rehydration sites go through the
       shared entry.
    4. Runtime: flat projection is property-preserving for both the
       chipset-shaped and graphics-shaped record (historical CSV columns
       survive; exactly InfSha256 / InspectionStatus are added ahead of
       DeviceList); the canonical JSON round-trip preserves nested
       Devices[], typed booleans and WDF evidence, and its flat view
       equals the live projection; a schema mismatch rehydrates to $null;
       a ParseFailed record flows through the projection intact.
    5. Negative control: a record stripped of InfSha256 is named by the
       shape validator.
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
$inventorySisters = @($chipsetPath, $graphicsPath)

$inventoryFunctionNames = @(
    'Get-InfLayerManifestHash',
    'Get-InfWdfEvidence',
    'ConvertTo-InfInventoryFlatView',
    'Restore-PackageInventoryFromJson',
    'Restore-InfInventoryContext'
)

function Get-G19FunctionText {
    param([string]$Path, [string]$Name)
    $tokens = $null; $errors = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseFile((Resolve-Path $Path).Path, [ref]$tokens, [ref]$errors)
    foreach ($fn in $ast.FindAll({ param($node) $node -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true)) {
        if ($fn.Name -eq $Name) { return $fn.Extent.Text }
    }
    return ''
}

function Get-G19TextHash {
    [OutputType([string])]
    param([string]$Text)
    if ([string]::IsNullOrEmpty($Text)) { return '(absent)' }
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try {
        return [System.BitConverter]::ToString($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($Text))).Replace('-', '').Substring(0, 16)
    }
    finally { $sha.Dispose() }
}

function Assert-G19RecordShape {
    # Names the first missing identity property, '' when the shape is sound.
    [OutputType([string])]
    param($Record)
    foreach ($required in @('InfSha256', 'SourceArtifactSha256', 'InspectionStatus', 'Wdf')) {
        if (-not $Record.PSObject.Properties[$required]) { return $required }
    }
    return ''
}

Write-TestSection 'G-19: presence guard (five inventory helpers in C/G)'
$presenceOk = $true
foreach ($path in $inventorySisters) {
    $leaf = Split-Path -Leaf $path
    foreach ($name in $inventoryFunctionNames) {
        $present = (Get-G19FunctionText -Path $path -Name $name) -ne ''
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

Write-TestSection 'G-19: byte identity of the inventory helpers across C/G'
foreach ($name in $inventoryFunctionNames) {
    $hashes = @($inventorySisters | ForEach-Object { Get-G19TextHash (Get-G19FunctionText -Path $_ -Name $name) })
    Assert-Equal ('{0}: identical in C/G' -f $name) 1 (@($hashes | Sort-Object -Unique)).Count
}

Write-TestSection 'G-19: generator and rehydration pins'
foreach ($entry in @(
    @{ Path = $chipsetPath;  Leaf = 'chipset';  BestEffort = 3 },
    @{ Path = $graphicsPath; Leaf = 'graphics'; BestEffort = 0 }
)) {
    $p05Text = Get-G19FunctionText -Path $entry.Path -Name 'Invoke-PrepPhase05_AnalyzeInfs'
    Assert-True ('{0}: records carry InfSha256' -f $entry.Leaf) ($p05Text.Contains('InfSha256            = $infSha'))
    Assert-True ('{0}: records carry SourceArtifactSha256' -f $entry.Leaf) ($p05Text.Contains('SourceArtifactSha256 = [string]$Ctx.ArtifactSha256'))
    Assert-True ('{0}: the ParseFailed path exists' -f $entry.Leaf) ($p05Text.Contains("InspectionStatus     = 'ParseFailed'"))
    Assert-True ('{0}: raw WDF evidence is captured' -f $entry.Leaf) ($p05Text.Contains('Get-InfWdfEvidence'))
    $jsonWriteIndex = $p05Text.IndexOf('package-inventory.json')
    $csvWriteIndex  = $p05Text.IndexOf('Export-Csv')
    Assert-True ('{0}: canonical JSON write precedes the CSV export' -f $entry.Leaf) (($jsonWriteIndex -ge 0) -and ($csvWriteIndex -gt $jsonWriteIndex))
    Assert-True ('{0}: P05 hit rehydrates from the canonical JSON' -f $entry.Leaf) ($p05Text.Contains('Restore-PackageInventoryFromJson'))
    Assert-False ('{0}: Import-Csv is gone from the P05 phase' -f $entry.Leaf) ($p05Text.Contains('Import-Csv'))
    $rawText = Get-Content -Path $entry.Path -Raw
    $requiredSites = ([regex]::Matches($rawText, [regex]::Escape('Restore-InfInventoryContext -Ctx $Ctx -Required'))).Count
    Assert-Equal ('{0}: exactly one required rehydration site' -f $entry.Leaf) 1 $requiredSites
    # EOL-independent count: every call site contains the plain form, and
    # the required site is its strict superstring - the difference is the
    # best-effort population.
    $totalSites = ([regex]::Matches($rawText, [regex]::Escape('Restore-InfInventoryContext -Ctx $Ctx'))).Count
    $bestEffortSites = $totalSites - $requiredSites
    Assert-Equal ('{0}: best-effort rehydration sites' -f $entry.Leaf) $entry.BestEffort $bestEffortSites
}

# Bring the helpers into this session from the chipset copy; the schema
# constant is read from the live script so the round-trip uses the real value.
$Script:InventorySchemaVersion = '1'
. (Get-ScriptFunctionBlock -Path $chipsetPath -Name $inventoryFunctionNames)

Write-TestSection 'G-19: property-preserving flat projection'
$wdfInf = "[Version]`r`nSignature=x`r`n[Drv.Wdf]`r`nKmdfLibraryVersion = 1.15`r`nKmdfLibraryVersion = 1.33`r`n"
$devices = @([pscustomobject]@{ Description = 'Dev A'; HardwareId = 'PCI\VEN_1022' })
$chipsetRecord = [pscustomobject]@{
    Inf = 'a.inf'; FullPath = 'X:\a.inf'; RelativePath = 'W11x64\a.inf'; RelativeDir = 'W11x64'
    SourceVariant = 'W11x64'; VariantSelected = $true; Encoding = 'utf8'; HasMfg = $true
    HasServerDeco = $false; NeedsPatch = $true; Provider = 'AMD'; Class = 'System'
    ClassGuid = '{g}'; DriverVer = '01/01/2026,1.0'; CatalogFile = 'a.cat'; Manufacturer = 'AMD'
    DeviceCount = 1; Devices = $devices; ManufacturerEntries = 1; ModelsSectionsScanned = 1
    ReferencedFilesCount = 2; MissingReferencedFiles = ''; EligibleForCatalog = $true
    IsWdfDriver = $true; KmdfLibraryVersion = '1.33'; UmdfLibraryVersion = ''
    CoInstallerVersions = ''; WdfSectionCount = 1
    SourceArtifactSha256 = 's'; InfSha256 = 'i'; InspectionStatus = 'Inspected'
    InspectionError = $null; Wdf = (Get-InfWdfEvidence -Content $wdfInf)
}
$graphicsRecord = [pscustomobject]@{
    Inf = 'b.inf'; FullPath = 'X:\b.inf'; RelativePath = 'b.inf'; RelativeDir = ''
    SourceVariant = 'root'; VariantSelected = $true; Encoding = 'utf8'; HasMfg = $true
    HasServerDeco = $true; NeedsPatch = $false; Provider = 'AMD'; Class = 'Display'
    ClassGuid = '{g}'; DriverVer = 'd'; CatalogFile = 'b.cat'; Manufacturer = 'AMD'
    DeviceCount = 1; Devices = $devices; ManufacturerEntries = 1; ModelsSectionsScanned = 1
    IsWdfDriver = $false; KmdfLibraryVersion = ''; UmdfLibraryVersion = ''
    CoInstallerVersions = ''; WdfSectionCount = 0
    SourceArtifactSha256 = 's'; InfSha256 = 'j'; InspectionStatus = 'Inspected'
    InspectionError = $null; Wdf = (Get-InfWdfEvidence -Content '')
}
$chipsetFlat  = @(ConvertTo-InfInventoryFlatView -DetailRecords @($chipsetRecord))[0]
$graphicsFlat = @(ConvertTo-InfInventoryFlatView -DetailRecords @($graphicsRecord))[0]
$chipsetColumns  = @($chipsetFlat.PSObject.Properties.Name)
$graphicsColumns = @($graphicsFlat.PSObject.Properties.Name)
Assert-True 'chipset flat keeps its historical phantom-file columns' ($chipsetColumns -contains 'EligibleForCatalog')
Assert-False 'graphics flat does not invent phantom-file columns' ($graphicsColumns -contains 'EligibleForCatalog')
Assert-Equal 'chipset flat tail is InfSha256, InspectionStatus, DeviceList' 'InfSha256|InspectionStatus|DeviceList' (($chipsetColumns[-3..-1]) -join '|')
Assert-Equal 'graphics flat tail is InfSha256, InspectionStatus, DeviceList' 'InfSha256|InspectionStatus|DeviceList' (($graphicsColumns[-3..-1]) -join '|')
Assert-False 'rich-only Devices[] does not leak into the flat view' ($chipsetColumns -contains 'Devices')
Assert-False 'rich-only Wdf evidence does not leak into the flat view' ($chipsetColumns -contains 'Wdf')
Assert-True 'typed booleans survive the projection' ($chipsetFlat.NeedsPatch -is [bool])
Assert-Equal 'DeviceList flattening is unchanged' 'Dev A|PCI\VEN_1022' ([string]$chipsetFlat.DeviceList)

Write-TestSection 'G-19: canonical JSON round-trip'
$tempJson = Join-Path ([System.IO.Path]::GetTempPath()) ('g19-' + [guid]::NewGuid().ToString('N') + '.json')
try {
    $doc = [pscustomobject][ordered]@{
        SchemaVersion        = '1'
        GeneratedAtUtc       = [DateTime]::UtcNow.ToString('o')
        ToolIdentity         = [pscustomobject]@{ ScriptVersion = 'g19-fixture' }
        SourceArtifactSha256 = 's'
        InfManifestSha256    = 'm'
        PreferredVariants    = @('W11x64')
        Records              = @($chipsetRecord)
    }
    $doc | ConvertTo-Json -Depth 8 | Set-Content -Path $tempJson -Encoding UTF8
    $restored = Restore-PackageInventoryFromJson -Path $tempJson
    Assert-True 'round-trip returns a result' ($null -ne $restored)
    Assert-Equal 'round-trip row count' 1 (@($restored.Detail)).Count
    Assert-Equal 'nested Devices[] survives' 1 (@($restored.Detail[0].Devices)).Count
    Assert-Equal 'typed WDF status survives' 'Declared' ([string]$restored.Detail[0].Wdf.KMDF.Status)
    Assert-Equal 'WDF evidence lines survive with line numbers' 2 (@($restored.Detail[0].Wdf.KMDF.Evidence)).Count
    Assert-Equal 'restored flat view equals the live projection' ($chipsetColumns -join '|') (@($restored.Flat[0].PSObject.Properties.Name) -join '|')
    Assert-Equal 'shape validator accepts a sound record' '' (Assert-G19RecordShape -Record $restored.Detail[0])

    $mismatch = Get-Content -Path $tempJson -Raw | ConvertFrom-Json
    $mismatch.SchemaVersion = '99'
    $mismatch | ConvertTo-Json -Depth 8 | Set-Content -Path $tempJson -Encoding UTF8
    Assert-True 'schema mismatch rehydrates to $null (miss, never a guess)' ($null -eq (Restore-PackageInventoryFromJson -Path $tempJson))
}
finally {
    Remove-Item -Path $tempJson -Force -ErrorAction SilentlyContinue
}
Assert-True 'absent file rehydrates to $null' ($null -eq (Restore-PackageInventoryFromJson -Path (Join-Path ([System.IO.Path]::GetTempPath()) 'g19-absent.json')))

Write-TestSection 'G-19: ParseFailed record flows intact'
$parseFailedRecord = [pscustomobject]@{
    Inf = 'bad.inf'; FullPath = 'X:\bad.inf'; RelativePath = 'bad.inf'; RelativeDir = ''
    SourceVariant = 'root'; VariantSelected = $false; Encoding = ''; HasMfg = $false
    HasServerDeco = $false; NeedsPatch = $false; Provider = ''; Class = ''
    ClassGuid = ''; DriverVer = ''; CatalogFile = ''; Manufacturer = ''
    DeviceCount = 0; Devices = @(); ManufacturerEntries = 0; ModelsSectionsScanned = 0
    IsWdfDriver = $false; KmdfLibraryVersion = ''; UmdfLibraryVersion = ''
    CoInstallerVersions = ''; WdfSectionCount = 0
    SourceArtifactSha256 = 's'; InfSha256 = 'k'; InspectionStatus = 'ParseFailed'
    InspectionError = 'fixture read failure'
    Wdf = [pscustomobject]@{
        KMDF = [pscustomobject]@{ Status = 'ParseFailed'; Versions = @(); Evidence = @() }
        UMDF = [pscustomobject]@{ Status = 'ParseFailed'; Versions = @(); Evidence = @() }
    }
}
$parseFailedFlat = @(ConvertTo-InfInventoryFlatView -DetailRecords @($parseFailedRecord))[0]
Assert-Equal 'ParseFailed status survives the projection' 'ParseFailed' ([string]$parseFailedFlat.InspectionStatus)
Assert-Equal 'ParseFailed record passes the shape validator' '' (Assert-G19RecordShape -Record $parseFailedRecord)

Write-TestSection 'G-19: negative control (stripped identity field)'
$strippedRecord = $parseFailedRecord | Select-Object -Property * -ExcludeProperty InfSha256
Assert-Equal 'stripped record is named by the shape validator' 'InfSha256' (Assert-G19RecordShape -Record $strippedRecord)

$result = Get-TestResult
Write-Host ''
Write-Host ('{0}: {1} passed, {2} failed' -f (Split-Path -Leaf $PSCommandPath), $result.Passed, $result.Failed) `
    -ForegroundColor $(if ($result.Failed -eq 0) { 'Green' } else { 'Red' })
exit $result.Failed
