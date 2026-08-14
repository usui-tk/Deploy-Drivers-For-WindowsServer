#requires -Version 5.1
<#
.SYNOPSIS
    Collects read-only AMD platform hardware identity evidence for NPU research from Windows.

.DESCRIPTION
    This standalone probe is intended for AMD CPU/NPU/GPU platform reverse-engineering research.
    It does NOT install, update, remove, sign, or execute any AMD driver package.

    The script collects:
      - Windows / system / BIOS / CPU identification
      - Processor-class PnP identities and amdppm.sys metadata
      - AMD platform PnP devices, including PCI VEN_1022 and AMD GPU VEN_1002
      - AMD graphics adapter identity and driver metadata
      - Platform firmware PnP devices and non-sensitive firmware properties
      - Device topology (parent/location/bus-reported description where exposed)
      - Installed INF snapshots for relevant platform devices
      - Service driver binary hashes/version/signature metadata where resolvable
      - Likely NPU devices, including known DEV_1502 / DEV_17F0
      - PCI VEN / DEV / SUBSYS / REV identifiers
      - PnP hardware IDs, compatible IDs, device properties
      - Installed driver / INF / provider / signer metadata
      - Relevant SetupAPI.dev.log lines
      - Raw pnputil output for NPU and GPU candidates
      - Read-only AMD XRT/xrt-smi runtime inspection when xrt-smi.exe is present
      - Ryzen AI quicktest.py discovery/hash/private snapshot when present (never executed)
      - AMD quicktest-style PCI REV platform classification for known NPU identities
      - Installed INF model-section correlation for NPU/GPU platform hints
      - Exact-hash correlation against reviewed AMD 376 INF/ipustack/xrt-smi payloads

    Safety:
      - xrt-smi probe is limited to read-only --version / examine commands.
      - The collector never runs xrt-smi validate/configure or quicktest inference.

    Privacy / evidence boundary:
      - Structured probes do NOT intentionally collect serial numbers, user names,
        IP addresses, MAC addresses, Wi-Fi data, or storage identifiers.
      - Evidence is private/runtime/non-commit input. The standard PowerShell
        transcript and raw vendor diagnostics such as xrt-smi JSON may contain
        host identity metadata. These raw files must not be committed directly.

.NOTES
    Project: Deploy-Drivers-For-WindowsServer
    Purpose: AMD platform CPU/NPU/GPU hardware identity survey
    Tool version: 1.2.1
    Compatible with: Windows PowerShell 5.1 and PowerShell 7+
#>

[CmdletBinding()]
param(
    [string]$OutputDirectory = (Get-Location).Path,
    [switch]$KeepDirectory,
    [switch]$SkipXrtSmiProbe,
    [ValidateRange(5,300)][int]$XrtSmiTimeoutSeconds = 45,
    [switch]$SkipQuicktestSnapshot
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

$ToolName = 'AMD Platform Hardware Identity Evidence Collector'
$ToolVersion = '1.2.1'
$script:ReviewedQuicktestSha256 = '185abe30aad44c3ca59df2c07249a550a1d0a1de6aecc7a52c9324362d910c09'
$script:ReviewedQuicktestArchiveSha256 = 'a479e458bd3ae5bc671be89c80d2d250e8a8c7c1268b18ed70498985fc4b0ea5'
$script:ReviewedNpu376ArtifactSha256 = 'aa836cbfcad5d0782c79b58f197aa50624af37e7cb8311c5f94d85b0dc3ccaad'
$script:ReviewedNpu376InfSha256 = 'c2a448340a9e802faa81b7c03fda0009d52cbfe86be5e915134dac39ab9c8008'
$script:ReviewedNpu376IpuStackSha256 = '24f8c7220b86ccb8246845c3dd25f55be4e64b2fac1aab1fbac1e1f8226d4a42'
$script:ReviewedNpu376XrtSmiSha256 = '1f7e88c6a4acc7c743809f7ae34dd09b0a6380b1002f97b3d57d3578ddd2e87a'
$StartTime = Get-Date
$Timestamp = $StartTime.ToString('yyyyMMdd-HHmmss')
$EvidenceName = 'amd-npu-hardware-evidence-{0}' -f $Timestamp
$EvidenceRoot = Join-Path $OutputDirectory $EvidenceName
$ZipPath = Join-Path $OutputDirectory ($EvidenceName + '.zip')

function New-Utf8NoBomEncoding {
    New-Object System.Text.UTF8Encoding($false)
}

function Write-Utf8File {
    param(
        [Parameter(Mandatory=$true)][string]$Path,
        [AllowEmptyString()][string]$Text
    )
    $parent = Split-Path -Parent $Path
    if ($parent -and -not (Test-Path -LiteralPath $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }
    if ($null -eq $Text) { $Text = '' }
    $normalized = $Text -replace "`r`n", "`n" -replace "`r", "`n"
    [System.IO.File]::WriteAllText($Path, $normalized, (New-Utf8NoBomEncoding))
}

function Write-JsonFile {
    param(
        [Parameter(Mandatory=$true)]$Value,
        [Parameter(Mandatory=$true)][string]$Path
    )
    $json = $Value | ConvertTo-Json -Depth 20
    Write-Utf8File -Path $Path -Text ($json + "`n")
}

function Get-Sha256 {
    param([Parameter(Mandatory=$true)][string]$Path)
    $stream = [System.IO.File]::OpenRead($Path)
    try {
        $sha = [System.Security.Cryptography.SHA256]::Create()
        try {
            ([BitConverter]::ToString($sha.ComputeHash($stream))).Replace('-', '').ToLowerInvariant()
        }
        finally {
            $sha.Dispose()
        }
    }
    finally {
        $stream.Dispose()
    }
}


function Get-EvidenceRelativePath {
    param(
        [Parameter(Mandatory=$true)][string]$Root,
        [Parameter(Mandatory=$true)][string]$FullName
    )

    $relative = $FullName.Substring($Root.Length)
    $backslash = [string][char]0x5C
    $slash = [string][char]0x2F

    while ($relative.StartsWith($backslash, [System.StringComparison]::Ordinal) -or
           $relative.StartsWith($slash, [System.StringComparison]::Ordinal)) {
        $relative = $relative.Substring(1)
    }

    return $relative.Replace([char]0x5C, [char]0x2F)
}

function Write-CollectorFailureRecord {
    param(
        [Parameter(Mandatory=$true)][string]$Root,
        [Parameter(Mandatory=$true)]$ErrorRecord
    )

    try {
        $errorDirectory = Join-Path $Root 'errors'
        New-Item -ItemType Directory -Path $errorDirectory -Force -ErrorAction Stop | Out-Null

        $lines = New-Object System.Collections.Generic.List[string]
        $lines.Add(('ToolVersion: {0}' -f $ToolVersion)) | Out-Null
        $lines.Add(('CollectedAtUtc: {0}' -f ((Get-Date).ToUniversalTime().ToString('o')))) | Out-Null
        $lines.Add(('ExceptionType: {0}' -f $ErrorRecord.Exception.GetType().FullName)) | Out-Null
        $lines.Add(('Message: {0}' -f $ErrorRecord.Exception.Message)) | Out-Null
        $lines.Add(('FullyQualifiedErrorId: {0}' -f [string]$ErrorRecord.FullyQualifiedErrorId)) | Out-Null
        if (-not [string]::IsNullOrWhiteSpace([string]$ErrorRecord.ScriptStackTrace)) {
            $lines.Add('') | Out-Null
            $lines.Add('ScriptStackTrace:') | Out-Null
            $lines.Add([string]$ErrorRecord.ScriptStackTrace) | Out-Null
        }
        $lines.Add('') | Out-Null
        $lines.Add('ErrorRecord:') | Out-Null
        $lines.Add(($ErrorRecord | Out-String).TrimEnd()) | Out-Null

        Write-Utf8File -Path (Join-Path $errorDirectory 'collector-error.txt') -Text (($lines.ToArray()) -join "`n")
    }
    catch {
        Write-Host ('[!] Failed to write collector error record: {0}' -f $_.Exception.Message)
    }
}

function Write-CollectorStatusFile {
    param(
        [Parameter(Mandatory=$true)][string]$Root,
        [Parameter(Mandatory=$true)][bool]$Succeeded,
        $ErrorRecord
    )

    try {
        $status = [ordered]@{
            SchemaVersion = '1.0'
            Tool = [ordered]@{
                Name = $ToolName
                Version = $ToolVersion
            }
            CompletedAtUtc = (Get-Date).ToUniversalTime().ToString('o')
            Outcome = if ($Succeeded) { 'Pass' } else { 'Failed' }
            EvidenceArchiveExpected = $true
            Error = if ($null -eq $ErrorRecord) {
                $null
            }
            else {
                [ordered]@{
                    ExceptionType = $ErrorRecord.Exception.GetType().FullName
                    Message = $ErrorRecord.Exception.Message
                    FullyQualifiedErrorId = [string]$ErrorRecord.FullyQualifiedErrorId
                    ScriptStackTrace = [string]$ErrorRecord.ScriptStackTrace
                }
            }
        }
        Write-JsonFile -Value $status -Path (Join-Path $Root 'collector-status.json')
        return $true
    }
    catch {
        Write-Host ('[!] Failed to write collector status: {0}' -f $_.Exception.Message)
        return $false
    }
}

function Write-EvidenceManifestSafely {
    param([Parameter(Mandatory=$true)][string]$Root)

    try {
        $manifestPath = Join-Path $Root 'manifest.json'
        $manifestFiles = @()

        Get-ChildItem -LiteralPath $Root -File -Recurse -ErrorAction Stop |
            Where-Object { $_.FullName -ne $manifestPath } |
            Sort-Object FullName |
            ForEach-Object {
                $relative = Get-EvidenceRelativePath -Root $Root -FullName $_.FullName
                $manifestFiles += [pscustomobject][ordered]@{
                    File = $relative
                    Length = $_.Length
                    Sha256 = Get-Sha256 -Path $_.FullName
                }
            }

        $manifest = [ordered]@{
            ToolVersion = $ToolVersion
            CreatedAtUtc = (Get-Date).ToUniversalTime().ToString('o')
            Files = $manifestFiles
        }
        Write-JsonFile -Value $manifest -Path $manifestPath
        return [pscustomobject][ordered]@{
            Success = $true
            EntryCount = $manifestFiles.Count
            Error = $null
        }
    }
    catch {
        try {
            $errorDirectory = Join-Path $Root 'errors'
            New-Item -ItemType Directory -Path $errorDirectory -Force -ErrorAction SilentlyContinue | Out-Null
            Write-Utf8File -Path (Join-Path $errorDirectory 'manifest-finalization-error.txt') -Text (($_ | Out-String).TrimEnd())
        }
        catch {}
        return [pscustomobject][ordered]@{
            Success = $false
            EntryCount = 0
            Error = $_.Exception.Message
        }
    }
}

function New-PortableEvidenceZipArchive {
    param(
        [Parameter(Mandatory=$true)][string]$Root,
        [Parameter(Mandatory=$true)][string]$Destination
    )

    Add-Type -AssemblyName System.IO.Compression -ErrorAction Stop
    Add-Type -AssemblyName System.IO.Compression.FileSystem -ErrorAction Stop

    if (Test-Path -LiteralPath $Destination) {
        Remove-Item -LiteralPath $Destination -Force -ErrorAction Stop
    }

    $fileStream = $null
    $archive = $null
    try {
        $fileStream = New-Object System.IO.FileStream(
            $Destination,
            [System.IO.FileMode]::CreateNew,
            [System.IO.FileAccess]::ReadWrite,
            [System.IO.FileShare]::None)
        $archive = New-Object System.IO.Compression.ZipArchive(
            $fileStream,
            [System.IO.Compression.ZipArchiveMode]::Create,
            $false)

        $items = @(Get-ChildItem -LiteralPath $Root -File -Recurse -ErrorAction Stop | Sort-Object FullName)
        foreach ($item in $items) {
            $entryName = Get-EvidenceRelativePath -Root $Root -FullName $item.FullName
            $null = [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile(
                $archive,
                $item.FullName,
                $entryName,
                [System.IO.Compression.CompressionLevel]::Optimal)
        }
    }
    finally {
        if ($null -ne $archive) { $archive.Dispose() }
        if ($null -ne $fileStream) { $fileStream.Dispose() }
    }
}

function Compress-EvidenceArchiveSafely {
    param(
        [Parameter(Mandatory=$true)][string]$Root,
        [Parameter(Mandatory=$true)][string]$Destination
    )

    $primaryError = $null
    try {
        New-PortableEvidenceZipArchive -Root $Root -Destination $Destination
        if (-not (Test-Path -LiteralPath $Destination)) {
            throw 'Portable ZIP writer returned without creating the destination ZIP.'
        }
        return [pscustomobject][ordered]@{
            Success = $true
            Sha256 = Get-Sha256 -Path $Destination
            Error = $null
        }
    }
    catch {
        $primaryError = $_.Exception.Message
        try {
            $errorDirectory = Join-Path $Root 'errors'
            New-Item -ItemType Directory -Path $errorDirectory -Force -ErrorAction SilentlyContinue | Out-Null
            Write-Utf8File -Path (Join-Path $errorDirectory 'zip-finalization-error.txt') -Text (($_ | Out-String).TrimEnd())
        }
        catch {}
    }

    # Best-effort fallback. Compress-Archive may use host-native separators in
    # entries, so this is used only when the canonical portable writer fails.
    try {
        if (Test-Path -LiteralPath $Destination) {
            Remove-Item -LiteralPath $Destination -Force -ErrorAction SilentlyContinue
        }
        if (-not (Get-Command Compress-Archive -ErrorAction SilentlyContinue)) {
            throw 'Compress-Archive fallback is not available.'
        }
        Compress-Archive -Path (Join-Path $Root '*') -DestinationPath $Destination -CompressionLevel Optimal -ErrorAction Stop
        if (-not (Test-Path -LiteralPath $Destination)) {
            throw 'Compress-Archive fallback returned without creating the destination ZIP.'
        }
        return [pscustomobject][ordered]@{
            Success = $true
            Sha256 = Get-Sha256 -Path $Destination
            Error = ('Portable ZIP writer failed; Compress-Archive fallback succeeded. Primary error: {0}' -f $primaryError)
        }
    }
    catch {
        return [pscustomobject][ordered]@{
            Success = $false
            Sha256 = $null
            Error = ('Portable ZIP writer failed: {0}; fallback failed: {1}' -f $primaryError, $_.Exception.Message)
        }
    }
}

function Complete-CollectorEvidencePackage {
    param(
        [Parameter(Mandatory=$true)][string]$Root,
        [Parameter(Mandatory=$true)][string]$Destination,
        [Parameter(Mandatory=$true)][bool]$Succeeded,
        $ErrorRecord
    )

    if (-not (Test-Path -LiteralPath $Root)) {
        try {
            New-Item -ItemType Directory -Path $Root -Force -ErrorAction Stop | Out-Null
        }
        catch {
            return [pscustomobject][ordered]@{
                Success = $false
                ManifestSuccess = $false
                ArchiveSuccess = $false
                ArchiveSha256 = $null
                Error = 'Unable to create evidence root: ' + $_.Exception.Message
            }
        }
    }

    $null = Write-CollectorStatusFile -Root $Root -Succeeded $Succeeded -ErrorRecord $ErrorRecord
    if (-not $Succeeded -and $null -ne $ErrorRecord) {
        Write-CollectorFailureRecord -Root $Root -ErrorRecord $ErrorRecord
    }

    $manifestResult = Write-EvidenceManifestSafely -Root $Root
    $archiveResult = Compress-EvidenceArchiveSafely -Root $Root -Destination $Destination

    return [pscustomobject][ordered]@{
        Success = [bool]$archiveResult.Success
        ManifestSuccess = [bool]$manifestResult.Success
        ManifestEntryCount = $manifestResult.EntryCount
        ArchiveSuccess = [bool]$archiveResult.Success
        ArchiveSha256 = $archiveResult.Sha256
        Error = $archiveResult.Error
    }
}


function Get-DriverBinaryEvidence {
    param([Parameter(Mandatory=$true)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        return [pscustomobject][ordered]@{
            Path = $Path
            Present = $false
        }
    }

    try {
        $item = Get-Item -LiteralPath $Path -ErrorAction Stop
        $signatureStatus = $null
        $signerSubject = $null
        $signerIssuer = $null

        if (Get-Command Get-AuthenticodeSignature -ErrorAction SilentlyContinue) {
            try {
                $sig = Get-AuthenticodeSignature -LiteralPath $Path -ErrorAction Stop
                $signatureStatus = [string]$sig.Status
                if ($null -ne $sig.SignerCertificate) {
                    $signerSubject = [string]$sig.SignerCertificate.Subject
                    $signerIssuer = [string]$sig.SignerCertificate.Issuer
                }
            }
            catch {
                $signatureStatus = 'CollectionError: ' + $_.Exception.Message
            }
        }

        return [pscustomobject][ordered]@{
            Path = $Path
            Present = $true
            Length = $item.Length
            Sha256 = Get-Sha256 -Path $Path
            FileVersion = [string]$item.VersionInfo.FileVersion
            ProductVersion = [string]$item.VersionInfo.ProductVersion
            CompanyName = [string]$item.VersionInfo.CompanyName
            ProductName = [string]$item.VersionInfo.ProductName
            SignatureStatus = $signatureStatus
            SignerSubject = $signerSubject
            SignerIssuer = $signerIssuer
        }
    }
    catch {
        return [pscustomobject][ordered]@{
            Path = $Path
            Present = $true
            CollectionError = $_.Exception.Message
        }
    }
}

function Convert-ToIso8601DateTimeOrRaw {
    <#
    .SYNOPSIS
        Safely normalizes CIM/WMI date values without assuming DMTF input.

    .DESCRIPTION
        Windows PowerShell 5.1 and PowerShell 7 can expose CIM datetime
        properties differently. Some providers return System.DateTime, while
        older WMI-style paths may expose a DMTF string. Malformed or provider-
        specific values must not abort evidence collection.
    #>
    param($Value)

    if ($null -eq $Value) { return $null }

    if ($Value -is [System.DateTime]) {
        return ([System.DateTime]$Value).ToString('o', [System.Globalization.CultureInfo]::InvariantCulture)
    }

    if ($Value -is [System.DateTimeOffset]) {
        return ([System.DateTimeOffset]$Value).ToString('o', [System.Globalization.CultureInfo]::InvariantCulture)
    }

    $text = [string]$Value
    if ([string]::IsNullOrWhiteSpace($text)) { return $null }
    $text = $text.Trim()

    # Parse complete DMTF datetime text directly instead of routing it through
    # ManagementDateTimeConverter. DMTF stores the UTC offset as signed minutes
    # (for example +540 for JST), which is different from a normal +09:00 ISO
    # suffix. Casting an already-materialized DateTime to a localized string and
    # passing that text to ToDateTime is the regression fixed in tool 1.0.1.
    if ($text -match '^(\d{14})\.(\d{6})([+-])(\d{3})$') {
        try {
            $base = [System.DateTime]::ParseExact(
                $matches[1],
                'yyyyMMddHHmmss',
                [System.Globalization.CultureInfo]::InvariantCulture,
                [System.Globalization.DateTimeStyles]::None)
            $microseconds = [int]$matches[2]
            $offsetMinutes = [int]$matches[4]
            if ($matches[3] -eq '-') { $offsetMinutes = -$offsetMinutes }
            $base = [System.DateTime]::SpecifyKind($base.AddTicks([long]$microseconds * 10L), [System.DateTimeKind]::Unspecified)
            $dmtfOffset = [System.DateTimeOffset]::new($base, [System.TimeSpan]::FromMinutes($offsetMinutes))
            return $dmtfOffset.ToString('o', [System.Globalization.CultureInfo]::InvariantCulture)
        }
        catch {
            # Fall through to culture-aware parsing and finally raw retention.
        }
    }

    $parsedOffset = [System.DateTimeOffset]::MinValue
    if ([System.DateTimeOffset]::TryParse(
        $text,
        [System.Globalization.CultureInfo]::InvariantCulture,
        [System.Globalization.DateTimeStyles]::AllowWhiteSpaces,
        [ref]$parsedOffset)) {
        return $parsedOffset.ToString('o', [System.Globalization.CultureInfo]::InvariantCulture)
    }

    $parsed = [System.DateTime]::MinValue
    if ([System.DateTime]::TryParse(
        $text,
        [System.Globalization.CultureInfo]::CurrentCulture,
        [System.Globalization.DateTimeStyles]::AllowWhiteSpaces,
        [ref]$parsed)) {
        return $parsed.ToString('o', [System.Globalization.CultureInfo]::InvariantCulture)
    }

    # Preserve evidence rather than terminating the whole run when a provider
    # emits an unexpected date representation.
    return $text
}

function Get-PciIdentity {
    param([AllowNull()][string[]]$Ids)

    $joined = (@($Ids) -join "`n").ToUpperInvariant()
    $result = [ordered]@{
        VendorId = $null
        DeviceId = $null
        SubsystemId = $null
        Revision = $null
    }

    if ($joined -match 'VEN_([0-9A-F]{4})') { $result.VendorId = $matches[1] }
    if ($joined -match 'DEV_([0-9A-F]{4})') { $result.DeviceId = $matches[1] }
    if ($joined -match 'SUBSYS_([0-9A-F]{8})') { $result.SubsystemId = $matches[1] }
    if ($joined -match 'REV_([0-9A-F]{2})') { $result.Revision = $matches[1] }

    [pscustomobject]$result
}

function Convert-PropertyValueToText {
    param($Value)

    if ($null -eq $Value) { return $null }

    if ($Value -is [System.Array]) {
        return (@($Value | ForEach-Object { [string]$_ }) -join '; ')
    }

    return [string]$Value
}

function Test-PnpPropertySensitive {
    param([AllowNull()][string]$KeyName)

    if ([string]::IsNullOrWhiteSpace($KeyName)) { return $false }

    # Preserve hardware/topology/driver evidence, but avoid persistent personal or
    # network identifiers that are not needed for platform correlation.
    return ($KeyName -match '(?i)(SerialNumber|MacAddress|NetworkAddress|BluetoothAddress)')
}

function Get-PnpPropertyValue {
    param(
        [Parameter(Mandatory=$true)]$Properties,
        [Parameter(Mandatory=$true)][string[]]$KeyNames
    )

    foreach ($key in $KeyNames) {
        $match = @($Properties | Where-Object { [string]$_.KeyName -eq $key } | Select-Object -First 1)
        if ($match.Count -gt 0) { return [string]$match[0].Data }
    }
    return $null
}

function Get-PnpPropertySnapshot {
    param([Parameter(Mandatory=$true)][string]$InstanceId)

    $items = @()

    if (-not (Get-Command Get-PnpDeviceProperty -ErrorAction SilentlyContinue)) {
        return $items
    }

    try {
        $props = @(Get-PnpDeviceProperty -InstanceId $InstanceId -ErrorAction Stop)
        foreach ($prop in $props) {
            $keyName = [string]$prop.KeyName
            if (Test-PnpPropertySensitive -KeyName $keyName) { continue }
            $items += [pscustomobject][ordered]@{
                KeyName = $keyName
                Type = [string]$prop.Type
                Data = Convert-PropertyValueToText $prop.Data
            }
        }
    }
    catch {
        $items += [pscustomobject][ordered]@{
            KeyName = '__COLLECTION_ERROR__'
            Type = 'Error'
            Data = $_.Exception.Message
        }
    }

    $items
}

function Get-NpuRevisionEvidence {
    <#
    .SYNOPSIS
        Separates PCI revision, PCIe specification version, and firmware device
        revision evidence instead of treating any revision/version property as
        firmware identity.

    .DESCRIPTION
        Linux amdxdna uses a firmware-reported NPU device revision to refine
        NPU4-family devices. That value is not the same as PCI REV_XX and is not
        the same as DEVPKEY_PciDevice_ExpressSpecVersion. Standard Windows PnP
        properties observed so far do not expose the amdxdna firmware revision.
    #>
    param(
        [Parameter(Mandatory=$true)]$Properties,
        [Parameter(Mandatory=$true)]$PciIdentity
    )

    $pcieSpecProps = @(
        $Properties |
        Where-Object {
            [string]$_.KeyName -eq 'DEVPKEY_PciDevice_ExpressSpecVersion'
        }
    )

    # Only count an explicitly named firmware/NPU/XDNA device-revision property
    # as firmware-device-revision evidence. Generic "version" or "revision"
    # properties are intentionally excluded because they produced the 1.0.2
    # false positive on DEVPKEY_PciDevice_ExpressSpecVersion.
    $firmwareDeviceRevisionProps = @(
        $Properties |
        Where-Object {
            $key = [string]$_.KeyName
            if ([string]::IsNullOrWhiteSpace($key)) { return $false }
            if ($key -eq 'DEVPKEY_PciDevice_ExpressSpecVersion') { return $false }
            if ($key -match '(?i)driver.*version') { return $false }
            return ($key -match '(?i)(firmware.*(?:device.*)?revision|(?:device.*)?revision.*firmware|(?:npu|xdna).*device.*revision|device.*revision.*(?:npu|xdna))')
        }
    )

    $otherRevisionVersionProps = @(
        $Properties |
        Where-Object {
            $key = [string]$_.KeyName
            if ([string]::IsNullOrWhiteSpace($key)) { return $false }
            if ($key -match '(?i)driver.*version') { return $false }
            if ($key -eq 'DEVPKEY_PciDevice_ExpressSpecVersion') { return $false }
            if (@($firmwareDeviceRevisionProps | Where-Object { [string]$_.KeyName -eq $key }).Count -gt 0) { return $false }
            return ($key -match '(?i)revision|version')
        }
    )

    $pcieSpecValue = $null
    if ($pcieSpecProps.Count -gt 0) {
        $pcieSpecValue = [string]$pcieSpecProps[0].Data
    }

    [pscustomobject][ordered]@{
        PciRevisionStatus = if ([string]::IsNullOrWhiteSpace([string]$PciIdentity.Revision)) { 'NotObserved' } else { 'ObservedFromPciHardwareId' }
        PciRevision = [string]$PciIdentity.Revision
        PciExpressSpecificationVersionStatus = if ($pcieSpecProps.Count -gt 0) { 'ObservedFromStandardPnPProperty' } else { 'NotObserved' }
        PciExpressSpecificationVersion = $pcieSpecValue
        PciExpressSpecificationProperties = $pcieSpecProps
        FirmwareDeviceRevisionStatus = if ($firmwareDeviceRevisionProps.Count -gt 0) { 'ExplicitPnPPropertyObserved' } else { 'NotObservedThroughCollectedStandardPnPProperties' }
        FirmwareDeviceRevisionProperties = $firmwareDeviceRevisionProps
        OtherRevisionOrVersionProperties = $otherRevisionVersionProps
        ImportantNote = 'PCI REV_XX, PCI Express specification version, and firmware-reported NPU device revision are different identity layers.'
    }
}

function Get-ObservedCpuIdentity {
    <#
    .SYNOPSIS
        Extracts architectural CPU Family/Model/Stepping separately from WMI
        processor-family classification codes.
    #>
    param(
        [Parameter(Mandatory=$true)]$Processor,
        [AllowNull()]$ProcessorPnpDevices
    )

    $family = $null
    $model = $null
    $stepping = $null
    $source = $null
    $description = [string]$Processor.Description

    if ($description -match '(?i)AMD64\s+Family\s+(\d+)\s+Model\s+(\d+)\s+Stepping\s+(\d+)') {
        $family = [int]$matches[1]
        $model = [int]$matches[2]
        $stepping = [int]$matches[3]
        $source = 'Win32_Processor.Description'
    }

    if ($null -eq $family -and $null -ne $ProcessorPnpDevices) {
        foreach ($device in @($ProcessorPnpDevices)) {
            $ids = @([string]$device.DeviceID) + @($device.HardwareID | ForEach-Object { [string]$_ })
            $joined = $ids -join ';'
            if ($joined -match '(?i)AMD64_Family_(\d+)_Model_(\d+)') {
                $family = [int]$matches[1]
                $model = [int]$matches[2]
                $steppingText = [string]$Processor.Stepping
                if ($steppingText -match '^\d+$') { $stepping = [int]$steppingText }
                $source = 'ProcessorPnPHardwareId'
                break
            }
        }
    }

    [pscustomobject][ordered]@{
        Status = if ($null -eq $family) { 'NotResolved' } else { 'Resolved' }
        Family = $family
        Model = $model
        Stepping = $stepping
        Source = $source
        ImportantNote = 'This architectural CPU identity is distinct from Win32_Processor.Family, which is a WMI processor-family classification code.'
    }
}

function Get-DriverRecord {
    param(
        [Parameter(Mandatory=$true)][string]$DeviceId,
        [AllowNull()]$DriverRecords
    )

    try {
        if ($null -eq $DriverRecords) {
            $records = @(
                Get-CimInstance Win32_PnPSignedDriver -ErrorAction Stop |
                Where-Object { [string]$_.DeviceID -eq $DeviceId }
            )
        }
        else {
            $records = @(
                $DriverRecords |
                Where-Object { [string]$_.DeviceID -eq $DeviceId }
            )
        }

        if ($records.Count -eq 0) { return $null }

        $d = $records[0]
        return [pscustomobject][ordered]@{
            DeviceName = [string]$d.DeviceName
            DriverVersion = [string]$d.DriverVersion
            DriverProviderName = [string]$d.DriverProviderName
            DriverDate = Convert-ToIso8601DateTimeOrRaw -Value $d.DriverDate
            InfName = [string]$d.InfName
            IsSigned = $d.IsSigned
            Signer = [string]$d.Signer
            Manufacturer = [string]$d.Manufacturer
        }
    }
    catch {
        return [pscustomobject][ordered]@{
            CollectionError = $_.Exception.Message
        }
    }
}

function Get-NpuCandidateReason {
    param(
        [Parameter(Mandatory=$true)]$Device,
        $Driver
    )

    $reasons = New-Object System.Collections.Generic.List[string]
    $text = @(
        [string]$Device.Name,
        [string]$Device.Description,
        [string]$Device.Service,
        [string]$Device.PNPClass,
        (@($Device.HardwareID) -join ' '),
        (@($Device.CompatibleID) -join ' ')
    ) -join ' '

    if ($text -match '(?i)\bNPU\b|Neural|XDNA|KIPU|\bIPU\b') {
        $reasons.Add('NameOrPnPMetadataMatchesNpuKeyword') | Out-Null
    }

    $pci = Get-PciIdentity -Ids (@($Device.DeviceID) + @($Device.HardwareID))
    if ($pci.DeviceId -eq '1502') {
        $reasons.Add('KnownAmdNpuDeviceId1502') | Out-Null
    }
    if ($pci.DeviceId -eq '17F0') {
        $reasons.Add('KnownAmdNpuDeviceId17F0') | Out-Null
    }

    if ($null -ne $Driver) {
        if ([string]$Driver.InfName -match '(?i)kipu') {
            $reasons.Add('InstalledInfMatchesKipu') | Out-Null
        }
        if ([string]$Driver.DeviceName -match '(?i)\bNPU\b|Neural|XDNA|KIPU|\bIPU\b') {
            $reasons.Add('InstalledDriverNameMatchesNpuKeyword') | Out-Null
        }
    }

    $reasons.ToArray()
}

function Test-AmdPlatformPnpDevice {
    param([Parameter(Mandatory=$true)]$Device)

    $ids = @([string]$Device.DeviceID) + @($Device.HardwareID | ForEach-Object { [string]$_ }) + @($Device.CompatibleID | ForEach-Object { [string]$_ })
    $joined = ($ids -join ';').ToUpperInvariant()
    if ($joined -match 'PCI\\VEN_(1022|1002)') { return $true }

    $text = @([string]$Device.Name, [string]$Device.Description, [string]$Device.Manufacturer, [string]$Device.Service) -join ' '
    if ($text -match '(?i)\bAMD\b|Advanced Micro Devices|Radeon|Ryzen') { return $true }

    return $false
}

function Get-AmdPlatformDeviceRole {
    param(
        [Parameter(Mandatory=$true)]$Device,
        [Parameter(Mandatory=$true)]$PciIdentity,
        [AllowNull()]$NpuReasons
    )

    if (@($NpuReasons).Count -gt 0) { return 'NPU' }

    $name = @([string]$Device.Name, [string]$Device.Description, [string]$Device.Service) -join ' '
    $class = [string]$Device.PNPClass
    if ($class -eq 'Display' -or $name -match '(?i)Radeon|Display') { return 'GPU' }
    if ($class -match '(?i)MEDIA|AudioEndpoint' -or $name -match '(?i)Audio') { return 'Audio' }
    if ($class -match '(?i)SecurityDevices' -or $name -match '(?i)PSP|Platform Security') { return 'SecurityProcessor' }
    if ($class -match '(?i)USB' -or $name -match '(?i)USB') { return 'USB' }
    if ($name -match '(?i)GPIO|I2C|SMBus|PCI|Chipset|Root Complex|Host Bridge') { return 'ChipsetOrSystem' }
    if ($class -eq 'Processor') { return 'Processor' }
    if ($null -ne $PciIdentity -and [string]$PciIdentity.VendorId -eq '1002') { return 'AmdGpuFunction' }
    return 'OtherAmdPlatformDevice'
}

function Get-DeviceTopologyEvidence {
    param([Parameter(Mandatory=$true)]$Properties)

    [pscustomobject][ordered]@{
        Parent = Get-PnpPropertyValue -Properties $Properties -KeyNames @('DEVPKEY_Device_Parent')
        LocationPaths = Get-PnpPropertyValue -Properties $Properties -KeyNames @('DEVPKEY_Device_LocationPaths')
        LocationInfo = Get-PnpPropertyValue -Properties $Properties -KeyNames @('DEVPKEY_Device_LocationInfo')
        BusReportedDeviceDescription = Get-PnpPropertyValue -Properties $Properties -KeyNames @('DEVPKEY_Device_BusReportedDeviceDesc')
        BusTypeGuid = Get-PnpPropertyValue -Properties $Properties -KeyNames @('DEVPKEY_Device_BusTypeGuid')
        Address = Get-PnpPropertyValue -Properties $Properties -KeyNames @('DEVPKEY_Device_Address')
        UINumber = Get-PnpPropertyValue -Properties $Properties -KeyNames @('DEVPKEY_Device_UINumber')
    }
}

function Resolve-WindowsServiceImagePath {
    param([AllowNull()][string]$ImagePath)

    if ([string]::IsNullOrWhiteSpace($ImagePath)) { return $null }
    $value = [Environment]::ExpandEnvironmentVariables($ImagePath.Trim())
    if ($value.StartsWith('"')) {
        $endQuote = $value.IndexOf('"', 1)
        if ($endQuote -gt 1) { $value = $value.Substring(1, $endQuote - 1) }
    } else {
        $value = ($value -split '\s+')[0]
    }
    $value = $value -replace '^\\\\\?\?\\', ''
    $value = $value -replace '^\\SystemRoot', $env:SystemRoot
    if ($value -match '^(?i)System32\\') { $value = Join-Path $env:SystemRoot $value }
    return $value
}

function Get-ServiceBinaryEvidence {
    param([AllowNull()][string]$ServiceName)

    if ([string]::IsNullOrWhiteSpace($ServiceName)) { return $null }
    $regPath = 'HKLM:\\SYSTEM\\CurrentControlSet\\Services\\{0}' -f $ServiceName
    try {
        if (-not (Test-Path -LiteralPath $regPath)) {
            return [pscustomobject][ordered]@{ ServiceName = $ServiceName; RegistryPresent = $false }
        }
        $svc = Get-ItemProperty -LiteralPath $regPath -ErrorAction Stop
        $resolved = Resolve-WindowsServiceImagePath -ImagePath ([string]$svc.ImagePath)
        [pscustomobject][ordered]@{
            ServiceName = $ServiceName
            RegistryPresent = $true
            Start = $svc.Start
            Type = $svc.Type
            ImagePathRaw = [string]$svc.ImagePath
            ImagePathResolved = $resolved
            Binary = if ([string]::IsNullOrWhiteSpace($resolved)) { $null } else { Get-DriverBinaryEvidence -Path $resolved }
        }
    }
    catch {
        [pscustomobject][ordered]@{ ServiceName = $ServiceName; CollectionError = $_.Exception.Message }
    }
}

function Get-DriverInfEvidence {
    param(
        [AllowNull()][string]$InfName,
        [Parameter(Mandatory=$true)][string]$SnapshotRoot
    )

    if ([string]::IsNullOrWhiteSpace($InfName)) { return $null }
    $safeName = [System.IO.Path]::GetFileName($InfName)
    if ([string]::IsNullOrWhiteSpace($safeName)) { return $null }
    $sourcePath = Join-Path (Join-Path $env:SystemRoot 'INF') $safeName
    if (-not (Test-Path -LiteralPath $sourcePath)) {
        return [pscustomobject][ordered]@{ InfName = $safeName; Present = $false; SourcePath = $sourcePath }
    }
    try {
        if (-not (Test-Path -LiteralPath $SnapshotRoot)) { New-Item -ItemType Directory -Path $SnapshotRoot -Force | Out-Null }
        $destPath = Join-Path $SnapshotRoot $safeName
        Copy-Item -LiteralPath $sourcePath -Destination $destPath -Force
        $item = Get-Item -LiteralPath $sourcePath
        return [pscustomobject][ordered]@{
            InfName = $safeName
            Present = $true
            Length = $item.Length
            Sha256 = Get-Sha256 -Path $sourcePath
            SnapshotFile = ('driver-inf/{0}' -f $safeName)
        }
    }
    catch {
        return [pscustomobject][ordered]@{ InfName = $safeName; Present = $true; CollectionError = $_.Exception.Message }
    }
}

function Get-InstalledInfModelEvidence {
    param(
        [AllowNull()][string]$InfName,
        [AllowNull()][string[]]$HardwareIds
    )

    if ([string]::IsNullOrWhiteSpace($InfName)) { return @() }
    $safeName = [System.IO.Path]::GetFileName($InfName)
    if ([string]::IsNullOrWhiteSpace($safeName)) { return @() }
    $sourcePath = Join-Path (Join-Path $env:SystemRoot 'INF') $safeName
    if (-not (Test-Path -LiteralPath $sourcePath -PathType Leaf)) { return @() }

    $tokens = New-Object System.Collections.Generic.List[string]
    foreach ($hardwareId in @($HardwareIds)) {
        if ([string]::IsNullOrWhiteSpace([string]$hardwareId)) { continue }
        $match = [regex]::Match([string]$hardwareId, '(?i)PCI\\VEN_[0-9A-F]{4}&DEV_[0-9A-F]{4}(?:&SUBSYS_[0-9A-F]{8})?(?:&REV_[0-9A-F]{2})?')
        if ($match.Success) { $tokens.Add($match.Value) | Out-Null }
    }
    $tokens = @($tokens.ToArray() | Sort-Object { $_.Length } -Descending -Unique)
    if ($tokens.Count -eq 0) { return @() }

    $results = New-Object System.Collections.Generic.List[object]
    try {
        $lineNumber = 0
        foreach ($line in [System.IO.File]::ReadAllLines($sourcePath, [System.Text.Encoding]::UTF8)) {
            $lineNumber++
            $trimmed = ([string]$line).Trim()
            if ([string]::IsNullOrWhiteSpace($trimmed) -or $trimmed.StartsWith(';')) { continue }
            $matchedHardwareId = $null
            foreach ($token in $tokens) {
                if ($trimmed.IndexOf($token, [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
                    $matchedHardwareId = $token
                    break
                }
            }
            if ($null -eq $matchedHardwareId) { continue }

            $installSection = $null
            $equalsIndex = $trimmed.IndexOf('=')
            $commaIndex = $trimmed.IndexOf(',')
            if ($equalsIndex -ge 0 -and $commaIndex -gt $equalsIndex) {
                $installSection = $trimmed.Substring($equalsIndex + 1, $commaIndex - $equalsIndex - 1).Trim()
            }
            $results.Add([pscustomobject][ordered]@{
                InfName = $safeName
                LineNumber = $lineNumber
                MatchedHardwareId = $matchedHardwareId
                InstallSection = $installSection
                Line = $trimmed
            }) | Out-Null
        }
    }
    catch {
        return @([pscustomobject][ordered]@{ InfName = $safeName; CollectionError = $_.Exception.Message })
    }
    return @($results.ToArray())
}

function Get-ReviewedPublishedPayloadCorrelation {
    param(
        [AllowNull()]$DriverInfEvidence,
        [AllowNull()]$ServiceBinaryEvidence,
        [AllowNull()]$XrtSmiEvidence
    )

    $infHash = if ($null -ne $DriverInfEvidence -and $DriverInfEvidence.PSObject.Properties['Sha256']) { [string]$DriverInfEvidence.Sha256 } else { $null }
    $binaryHash = $null
    if ($null -ne $ServiceBinaryEvidence -and $ServiceBinaryEvidence.PSObject.Properties['Binary'] -and $null -ne $ServiceBinaryEvidence.Binary -and $ServiceBinaryEvidence.Binary.PSObject.Properties['Sha256']) {
        $binaryHash = [string]$ServiceBinaryEvidence.Binary.Sha256
    }
    $xrtHash = $null
    if ($null -ne $XrtSmiEvidence -and $XrtSmiEvidence.PSObject.Properties['Executable'] -and $null -ne $XrtSmiEvidence.Executable -and $XrtSmiEvidence.Executable.PSObject.Properties['Sha256']) {
        $xrtHash = [string]$XrtSmiEvidence.Executable.Sha256
    }

    $infMatch = (-not [string]::IsNullOrWhiteSpace($infHash)) -and ($infHash -eq $script:ReviewedNpu376InfSha256)
    $driverMatch = (-not [string]::IsNullOrWhiteSpace($binaryHash)) -and ($binaryHash -eq $script:ReviewedNpu376IpuStackSha256)
    $xrtMatch = (-not [string]::IsNullOrWhiteSpace($xrtHash)) -and ($xrtHash -eq $script:ReviewedNpu376XrtSmiSha256)
    return [pscustomobject][ordered]@{
        ReviewedArtifact = 'NPU_RAI_376_WHQL.zip'
        ReviewedArtifactSha256 = $script:ReviewedNpu376ArtifactSha256
        InfExactMatch = $infMatch
        DriverBinaryExactMatch = $driverMatch
        XrtSmiExactMatch = $xrtMatch
        FullObservedStackExactMatch = ($infMatch -and $driverMatch -and $xrtMatch)
        ImportantNote = 'Exact hash correlation is a client runtime evidence fact. It does not by itself prove Windows Server runtime applicability.'
    }
}

function Get-GraphicsAdapterEvidence {
    param([AllowNull()]$Controllers)

    $items = @()
    foreach ($gpu in @($Controllers)) {
        $items += [pscustomobject][ordered]@{
            Name = [string]$gpu.Name
            AdapterCompatibility = [string]$gpu.AdapterCompatibility
            PnpDeviceId = [string]$gpu.PNPDeviceID
            VideoProcessor = [string]$gpu.VideoProcessor
            DriverVersion = [string]$gpu.DriverVersion
            DriverDate = Convert-ToIso8601DateTimeOrRaw -Value $gpu.DriverDate
            InstalledDisplayDrivers = [string]$gpu.InstalledDisplayDrivers
            Status = [string]$gpu.Status
        }
    }
    return $items
}

function ConvertTo-QuotedProcessArgument {
    param([AllowNull()][string]$Value)

    if ($null -eq $Value) { return '""' }
    if ($Value -notmatch '[\s"]') { return $Value }
    # Windows command-line quoting compatible with ProcessStartInfo.Arguments.
    return '"' + ($Value -replace '(\\*)"', '$1$1\\"' -replace '(\\+)$', '$1$1') + '"'
}

function Invoke-ReadOnlyProcessCapture {
    param(
        [Parameter(Mandatory=$true)][string]$FilePath,
        [Parameter(Mandatory=$true)][string[]]$Arguments,
        [ValidateRange(5,300)][int]$TimeoutSeconds = 45,
        [AllowNull()][string]$WorkingDirectory
    )

    $startedAt = Get-Date
    try {
        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = $FilePath
        $psi.UseShellExecute = $false
        $psi.CreateNoWindow = $true
        $psi.RedirectStandardOutput = $true
        $psi.RedirectStandardError = $true
        $psi.Arguments = (@($Arguments | ForEach-Object { ConvertTo-QuotedProcessArgument -Value ([string]$_) }) -join ' ')
        if (-not [string]::IsNullOrWhiteSpace($WorkingDirectory)) {
            $psi.WorkingDirectory = $WorkingDirectory
        }

        $process = New-Object System.Diagnostics.Process
        $process.StartInfo = $psi
        if (-not $process.Start()) {
            throw 'Process.Start() returned false.'
        }
        $stdoutTask = $process.StandardOutput.ReadToEndAsync()
        $stderrTask = $process.StandardError.ReadToEndAsync()
        $completed = $process.WaitForExit($TimeoutSeconds * 1000)
        if (-not $completed) {
            try { $process.Kill() } catch {}
            try { $process.WaitForExit() } catch {}
        }

        $stdout = $stdoutTask.GetAwaiter().GetResult()
        $stderr = $stderrTask.GetAwaiter().GetResult()
        return [pscustomobject][ordered]@{
            Started = $true
            TimedOut = (-not $completed)
            ExitCode = if ($completed) { $process.ExitCode } else { $null }
            StdOut = [string]$stdout
            StdErr = [string]$stderr
            ElapsedMilliseconds = [int][Math]::Round(((Get-Date) - $startedAt).TotalMilliseconds)
            Error = if ($completed) { $null } else { 'Timed out and process was terminated.' }
        }
    }
    catch {
        return [pscustomobject][ordered]@{
            Started = $false
            TimedOut = $false
            ExitCode = $null
            StdOut = ''
            StdErr = ''
            ElapsedMilliseconds = [int][Math]::Round(((Get-Date) - $startedAt).TotalMilliseconds)
            Error = $_.Exception.Message
        }
    }
}

function Find-XrtSmiExecutable {
    $candidates = New-Object System.Collections.Generic.List[object]

    if (-not [string]::IsNullOrWhiteSpace($env:SystemRoot)) {
        $candidates.Add([pscustomobject]@{ Path = (Join-Path $env:SystemRoot 'System32\AMD\xrt-smi.exe'); Source = 'WindowsSystem32AMD' }) | Out-Null
    }

    try {
        $cmd = Get-Command xrt-smi.exe -ErrorAction SilentlyContinue
        if ($null -ne $cmd) {
            $cmdPath = $null
            if ($null -ne $cmd.PSObject.Properties['Source']) { $cmdPath = [string]$cmd.Source }
            if ([string]::IsNullOrWhiteSpace($cmdPath) -and $null -ne $cmd.PSObject.Properties['Path']) { $cmdPath = [string]$cmd.Path }
            if (-not [string]::IsNullOrWhiteSpace($cmdPath)) {
                $candidates.Add([pscustomobject]@{ Path = $cmdPath; Source = 'PATH' }) | Out-Null
            }
        }
    }
    catch {}

    if (-not [string]::IsNullOrWhiteSpace($env:RYZEN_AI_INSTALLATION_PATH)) {
        foreach ($relative in @('xrt-smi.exe','bin\xrt-smi.exe','xrt\bin\xrt-smi.exe')) {
            $candidates.Add([pscustomobject]@{ Path = (Join-Path $env:RYZEN_AI_INSTALLATION_PATH $relative); Source = 'RYZEN_AI_INSTALLATION_PATH' }) | Out-Null
        }
    }

    $seen = @{}
    foreach ($candidate in $candidates) {
        $path = [string]$candidate.Path
        if ([string]::IsNullOrWhiteSpace($path)) { continue }
        $key = $path.ToLowerInvariant()
        if ($seen.ContainsKey($key)) { continue }
        $seen[$key] = $true
        if (Test-Path -LiteralPath $path -PathType Leaf) {
            return [pscustomobject][ordered]@{
                Present = $true
                Path = (Get-Item -LiteralPath $path -ErrorAction Stop).FullName
                Source = [string]$candidate.Source
            }
        }
    }

    return [pscustomobject][ordered]@{
        Present = $false
        Path = $null
        Source = $null
    }
}

function Get-XrtRuntimeDirectoryEvidence {
    param([AllowNull()][string]$XrtSmiPath)

    if ([string]::IsNullOrWhiteSpace($XrtSmiPath) -or -not (Test-Path -LiteralPath $XrtSmiPath)) { return @() }
    $directory = Split-Path -Parent $XrtSmiPath
    if ([string]::IsNullOrWhiteSpace($directory) -or -not (Test-Path -LiteralPath $directory)) { return @() }

    $items = @()
    foreach ($item in @(Get-ChildItem -LiteralPath $directory -File -ErrorAction SilentlyContinue | Sort-Object Name)) {
        if ($item.Extension -notmatch '^(?i)\.(exe|dll|json|txt)$') { continue }
        if ($item.Name -notmatch '^(?i)(xrt|xcl|xaie|xdp|amd|ipu|npu)') { continue }
        $evidence = Get-DriverBinaryEvidence -Path $item.FullName
        $items += [pscustomobject][ordered]@{
            Name = $item.Name
            Length = $item.Length
            Sha256 = if ($null -ne $evidence.PSObject.Properties['Sha256']) { $evidence.Sha256 } else { $null }
            FileVersion = if ($null -ne $evidence.PSObject.Properties['FileVersion']) { $evidence.FileVersion } else { $null }
            ProductVersion = if ($null -ne $evidence.PSObject.Properties['ProductVersion']) { $evidence.ProductVersion } else { $null }
            SignatureStatus = if ($null -ne $evidence.PSObject.Properties['SignatureStatus']) { $evidence.SignatureStatus } else { $null }
            SignerSubject = if ($null -ne $evidence.PSObject.Properties['SignerSubject']) { $evidence.SignerSubject } else { $null }
        }
    }
    return $items
}

function Add-XrtJsonScalarMatches {
    param(
        $Value,
        [string]$Path,
        [Parameter(Mandatory=$true)]$Results
    )

    if ($null -eq $Value) { return }
    if ($Value -is [System.Collections.IDictionary]) {
        foreach ($key in $Value.Keys) {
            $childPath = if ([string]::IsNullOrWhiteSpace($Path)) { [string]$key } else { '{0}.{1}' -f $Path, $key }
            Add-XrtJsonScalarMatches -Value $Value[$key] -Path $childPath -Results $Results
        }
        return
    }
    if ($Value -is [System.Management.Automation.PSCustomObject]) {
        foreach ($prop in $Value.PSObject.Properties) {
            $childPath = if ([string]::IsNullOrWhiteSpace($Path)) { [string]$prop.Name } else { '{0}.{1}' -f $Path, $prop.Name }
            if ([string]$prop.Name -match '(?i)(firmware.*version|driver.*version|xrt.*version|device.*name|^name$|bdf|ready|status|^hash$|build_date)') {
                if ($null -ne $prop.Value -and -not ($prop.Value -is [System.Collections.IEnumerable] -and -not ($prop.Value -is [string]))) {
                    $Results.Add([pscustomobject][ordered]@{ JsonPath = $childPath; Property = [string]$prop.Name; Value = [string]$prop.Value }) | Out-Null
                }
            }
            Add-XrtJsonScalarMatches -Value $prop.Value -Path $childPath -Results $Results
        }
        return
    }
    if ($Value -is [System.Collections.IEnumerable] -and -not ($Value -is [string])) {
        $index = 0
        foreach ($entry in $Value) {
            Add-XrtJsonScalarMatches -Value $entry -Path ('{0}[{1}]' -f $Path, $index) -Results $Results
            $index++
        }
    }
}

function Get-XrtStructuredJsonSummary {
    param($ParsedJson)

    $summary = [ordered]@{
        Parsed = ($null -ne $ParsedJson)
        HostMetadata = [ordered]@{
            OsDistribution = $null
            OsRelease = $null
            SystemModel = $null
            Processor = $null
            HostnamePresentInRawJson = $false
        }
        Xrt = [ordered]@{
            Version = $null
            Branch = $null
            Hash = $null
            BuildDate = $null
        }
        Drivers = @()
        Devices = @()
    }
    if ($null -eq $ParsedJson) { return [pscustomobject]$summary }

    try {
        $hostNode = $ParsedJson.system.host
        if ($null -ne $hostNode) {
            if ($null -ne $hostNode.os) {
                $summary.HostMetadata.OsDistribution = [string]$hostNode.os.distribution
                $summary.HostMetadata.OsRelease = [string]$hostNode.os.release
                $summary.HostMetadata.SystemModel = [string]$hostNode.os.model
                $summary.HostMetadata.Processor = [string]$hostNode.os.processor
                if ($hostNode.os.PSObject.Properties['hostname'] -and -not [string]::IsNullOrWhiteSpace([string]$hostNode.os.hostname)) {
                    $summary.HostMetadata.HostnamePresentInRawJson = $true
                }
            }
            if ($null -ne $hostNode.xrt) {
                $summary.Xrt.Version = [string]$hostNode.xrt.version
                $summary.Xrt.Branch = [string]$hostNode.xrt.branch
                $summary.Xrt.Hash = [string]$hostNode.xrt.hash
                $summary.Xrt.BuildDate = [string]$hostNode.xrt.build_date
                $drivers = New-Object System.Collections.Generic.List[object]
                foreach ($driver in @($hostNode.xrt.drivers)) {
                    $drivers.Add([pscustomobject][ordered]@{
                        Name = [string]$driver.name
                        Version = [string]$driver.version
                    }) | Out-Null
                }
                $summary.Drivers = @($drivers.ToArray())
            }
            $devices = New-Object System.Collections.Generic.List[object]
            foreach ($device in @($hostNode.devices)) {
                $devices.Add([pscustomobject][ordered]@{
                    Name = [string]$device.name
                    DeviceClass = [string]$device.device_class
                    Bdf = [string]$device.bdf
                    FirmwareVersion = [string]$device.firmware_version
                    Ready = [string]$device.is_ready
                    Id = [string]$device.id
                    Instance = [string]$device.instance
                }) | Out-Null
            }
            $summary.Devices = @($devices.ToArray())
        }
    }
    catch {
        $summary['ParseWarning'] = $_.Exception.Message
    }
    return [pscustomobject]$summary
}

function Invoke-XrtSmiEvidenceProbe {
    param(
        [Parameter(Mandatory=$true)][string]$EvidenceRoot,
        [ValidateRange(5,300)][int]$TimeoutSeconds = 45,
        [switch]$SkipProbe
    )

    $discovery = Find-XrtSmiExecutable
    $result = [ordered]@{
        ProbePolicy = 'ReadOnlyOnly: --version and examine; validate/configure are never invoked'
        Skipped = [bool]$SkipProbe
        Present = [bool]$discovery.Present
        DiscoverySource = $discovery.Source
        Executable = $null
        RuntimeDirectoryInventory = @()
        VersionProbe = $null
        ExamineJsonProbe = $null
        ExamineTextProbe = $null
        StructuredJsonSummary = $null
        NormalizedJsonFields = @()
        ReviewedPayloadCorrelation = [pscustomobject][ordered]@{
            ReviewedArtifact = 'NPU_RAI_376_WHQL.zip'
            ReviewedArtifactSha256 = $script:ReviewedNpu376ArtifactSha256
            XrtSmiExactMatch = $false
        }
    }

    if (-not $discovery.Present) { return [pscustomobject]$result }

    $result.Executable = Get-DriverBinaryEvidence -Path ([string]$discovery.Path)
    if ($null -ne $result.Executable -and $result.Executable.PSObject.Properties['Sha256']) { $result.ReviewedPayloadCorrelation.XrtSmiExactMatch = ([string]$result.Executable.Sha256 -eq $script:ReviewedNpu376XrtSmiSha256) }
    $result.RuntimeDirectoryInventory = @(Get-XrtRuntimeDirectoryEvidence -XrtSmiPath ([string]$discovery.Path))
    if ($SkipProbe) { return [pscustomobject]$result }

    $xrtRoot = Join-Path $EvidenceRoot 'xrt'
    New-Item -ItemType Directory -Path $xrtRoot -Force -ErrorAction SilentlyContinue | Out-Null
    $workingDirectory = Split-Path -Parent ([string]$discovery.Path)

    $versionProbe = Invoke-ReadOnlyProcessCapture -FilePath ([string]$discovery.Path) -Arguments @('--version') -TimeoutSeconds $TimeoutSeconds -WorkingDirectory $workingDirectory
    Write-Utf8File -Path (Join-Path $xrtRoot 'xrt-smi-version-stdout.txt') -Text ([string]$versionProbe.StdOut)
    Write-Utf8File -Path (Join-Path $xrtRoot 'xrt-smi-version-stderr.txt') -Text ([string]$versionProbe.StdErr)
    $result.VersionProbe = [pscustomobject][ordered]@{
        Started = $versionProbe.Started
        TimedOut = $versionProbe.TimedOut
        ExitCode = $versionProbe.ExitCode
        ElapsedMilliseconds = $versionProbe.ElapsedMilliseconds
        Error = $versionProbe.Error
        StdOutFile = 'xrt/xrt-smi-version-stdout.txt'
        StdErrFile = 'xrt/xrt-smi-version-stderr.txt'
    }

    $jsonOutput = Join-Path $xrtRoot 'xrt-smi-examine.json'
    if (Test-Path -LiteralPath $jsonOutput) { Remove-Item -LiteralPath $jsonOutput -Force -ErrorAction SilentlyContinue }
    $jsonProbe = Invoke-ReadOnlyProcessCapture -FilePath ([string]$discovery.Path) -Arguments @('examine','-f','JSON','-o',$jsonOutput) -TimeoutSeconds $TimeoutSeconds -WorkingDirectory $workingDirectory
    Write-Utf8File -Path (Join-Path $xrtRoot 'xrt-smi-examine-json-stdout.txt') -Text ([string]$jsonProbe.StdOut)
    Write-Utf8File -Path (Join-Path $xrtRoot 'xrt-smi-examine-json-stderr.txt') -Text ([string]$jsonProbe.StdErr)

    $jsonParseStatus = 'NotProduced'
    $normalized = New-Object System.Collections.Generic.List[object]
    if (Test-Path -LiteralPath $jsonOutput -PathType Leaf) {
        try {
            $rawJson = [System.IO.File]::ReadAllText($jsonOutput, [System.Text.Encoding]::UTF8)
            $parsed = $rawJson | ConvertFrom-Json -ErrorAction Stop
            Add-XrtJsonScalarMatches -Value $parsed -Path '' -Results $normalized
            $result.StructuredJsonSummary = Get-XrtStructuredJsonSummary -ParsedJson $parsed
            $jsonParseStatus = 'Parsed'
        }
        catch {
            $jsonParseStatus = 'ParseError: ' + $_.Exception.Message
        }
    }
    $result.ExamineJsonProbe = [pscustomobject][ordered]@{
        Started = $jsonProbe.Started
        TimedOut = $jsonProbe.TimedOut
        ExitCode = $jsonProbe.ExitCode
        ElapsedMilliseconds = $jsonProbe.ElapsedMilliseconds
        Error = $jsonProbe.Error
        OutputFile = if (Test-Path -LiteralPath $jsonOutput) { 'xrt/xrt-smi-examine.json' } else { $null }
        JsonParseStatus = $jsonParseStatus
        StdOutFile = 'xrt/xrt-smi-examine-json-stdout.txt'
        StdErrFile = 'xrt/xrt-smi-examine-json-stderr.txt'
    }
    $result.NormalizedJsonFields = @($normalized.ToArray())

    # Preserve a human-readable examine result as an independent fallback.
    $textProbe = Invoke-ReadOnlyProcessCapture -FilePath ([string]$discovery.Path) -Arguments @('examine') -TimeoutSeconds $TimeoutSeconds -WorkingDirectory $workingDirectory
    Write-Utf8File -Path (Join-Path $xrtRoot 'xrt-smi-examine.txt') -Text ([string]$textProbe.StdOut)
    Write-Utf8File -Path (Join-Path $xrtRoot 'xrt-smi-examine-stderr.txt') -Text ([string]$textProbe.StdErr)
    $result.ExamineTextProbe = [pscustomobject][ordered]@{
        Started = $textProbe.Started
        TimedOut = $textProbe.TimedOut
        ExitCode = $textProbe.ExitCode
        ElapsedMilliseconds = $textProbe.ElapsedMilliseconds
        Error = $textProbe.Error
        StdOutFile = 'xrt/xrt-smi-examine.txt'
        StdErrFile = 'xrt/xrt-smi-examine-stderr.txt'
    }

    return [pscustomobject]$result
}

function Get-QuicktestStyleNpuClassification {
    param([Parameter(Mandatory=$true)]$PciIdentity)

    $dev = ([string]$PciIdentity.DeviceId).ToUpperInvariant()
    $rev = ([string]$PciIdentity.Revision).ToUpperInvariant()
    $classification = $null
    if ($dev -eq '1502' -and $rev -eq '00') { $classification = 'PHX/HPT' }
    elseif ($dev -eq '17F0' -and @('00','10','11') -contains $rev) { $classification = 'STX' }
    elseif ($dev -eq '17F0' -and $rev -eq '20') { $classification = 'KRK' }

    return [pscustomobject][ordered]@{
        Classification = $classification
        Status = if ([string]::IsNullOrWhiteSpace($classification)) { 'NoReviewedQuicktestMapping' } else { 'MatchedReviewedQuicktestMapping' }
        DeviceId = $dev
        PciRevision = $rev
        ReferenceType = 'RecoveredPrivateRyzenAiQuicktestSource'
        ReferenceQuicktestSha256 = $script:ReviewedQuicktestSha256
        ReferenceArchiveSha256 = $script:ReviewedQuicktestArchiveSha256
        EvidenceNote = 'Mapping recovered from AMD Ryzen AI quicktest.py supplied for research; this is PCI-revision platform classification, not firmware device revision.'
    }
}

function Find-RyzenAiQuicktestEvidence {
    param(
        [Parameter(Mandatory=$true)][string]$EvidenceRoot,
        [switch]$SkipSnapshot
    )

    $candidates = New-Object System.Collections.Generic.List[object]
    if (-not [string]::IsNullOrWhiteSpace($env:RYZEN_AI_INSTALLATION_PATH)) {
        $candidates.Add([pscustomobject]@{ Path = (Join-Path $env:RYZEN_AI_INSTALLATION_PATH 'quicktest\quicktest.py'); Source = 'RYZEN_AI_INSTALLATION_PATH' }) | Out-Null
    }
    if (-not [string]::IsNullOrWhiteSpace($env:ProgramFiles)) {
        $ryzenAiRoot = Join-Path $env:ProgramFiles 'RyzenAI'
        if (Test-Path -LiteralPath $ryzenAiRoot) {
            foreach ($candidate in @(Get-ChildItem -LiteralPath $ryzenAiRoot -Directory -ErrorAction SilentlyContinue | Sort-Object Name -Descending)) {
                $candidates.Add([pscustomobject]@{ Path = (Join-Path $candidate.FullName 'quicktest\quicktest.py'); Source = 'ProgramFilesRyzenAI' }) | Out-Null
            }
        }
    }

    $found = $null
    foreach ($candidate in $candidates) {
        if (Test-Path -LiteralPath ([string]$candidate.Path) -PathType Leaf) { $found = $candidate; break }
    }
    if ($null -eq $found) {
        return [pscustomobject][ordered]@{ Present = $false; Path = $null; Source = $null; Sha256 = $null; SnapshotFile = $null; Executed = $false }
    }

    $item = Get-Item -LiteralPath ([string]$found.Path) -ErrorAction Stop
    $snapshotFile = $null
    if (-not $SkipSnapshot) {
        $destRoot = Join-Path $EvidenceRoot 'ryzen-ai'
        New-Item -ItemType Directory -Path $destRoot -Force -ErrorAction SilentlyContinue | Out-Null
        $dest = Join-Path $destRoot 'quicktest.py'
        Copy-Item -LiteralPath $item.FullName -Destination $dest -Force -ErrorAction Stop
        $snapshotFile = 'ryzen-ai/quicktest.py'
    }

    return [pscustomobject][ordered]@{
        Present = $true
        Path = $item.FullName
        Source = [string]$found.Source
        Length = $item.Length
        Sha256 = Get-Sha256 -Path $item.FullName
        MatchesReviewedQuicktestSource = ((Get-Sha256 -Path $item.FullName) -eq $script:ReviewedQuicktestSha256)
        ReviewedQuicktestSha256 = $script:ReviewedQuicktestSha256
        SnapshotFile = $snapshotFile
        Executed = $false
        SafetyNote = 'quicktest.py is collected as private source evidence only; collector never executes it or its inference workload.'
    }
}

function Invoke-PnpUtilForInstance {
    param([Parameter(Mandatory=$true)][string]$InstanceId)

    $pnputil = Join-Path $env:SystemRoot 'System32\pnputil.exe'
    if (-not (Test-Path -LiteralPath $pnputil)) {
        return 'pnputil.exe not found.'
    }

    try {
        $output = & $pnputil /enum-devices /instanceid $InstanceId /properties 2>&1
        return (@($output | ForEach-Object { [string]$_ }) -join "`n")
    }
    catch {
        return 'pnputil error: ' + $_.Exception.Message
    }
}

$script:CollectorSucceeded = $false
$script:CollectorErrorRecord = $null
$script:TranscriptStarted = $false

try {
    New-Item -ItemType Directory -Path $EvidenceRoot -Force -ErrorAction Stop | Out-Null

    try {
        Start-Transcript -LiteralPath (Join-Path $EvidenceRoot 'console-transcript.txt') -Force -ErrorAction Stop | Out-Null
        $script:TranscriptStarted = $true
    }
    catch {
        Write-Host ('[!] Transcript could not be started; collection will continue: {0}' -f $_.Exception.Message)
    }

Write-Host ''
Write-Host ('=== {0} v{1} ===' -f $ToolName, $ToolVersion)
Write-Host ('Output: {0}' -f $EvidenceRoot)
Write-Host ''
Write-Host '[*] Collecting OS / system / CPU information...'

$os = Get-CimInstance Win32_OperatingSystem
$computer = Get-CimInstance Win32_ComputerSystem
$computerProduct = Get-CimInstance Win32_ComputerSystemProduct
$bios = Get-CimInstance Win32_BIOS
$processors = @(Get-CimInstance Win32_Processor)
$allPnpEntities = @(Get-CimInstance Win32_PnPEntity)
$signedDriverRecords = @(Get-CimInstance Win32_PnPSignedDriver)
$videoControllers = @(Get-CimInstance Win32_VideoController -ErrorAction SilentlyContinue)

$systemInfo = [ordered]@{
    Manufacturer = [string]$computer.Manufacturer
    Model = [string]$computer.Model
    SystemFamily = [string]$computer.SystemFamily
    SystemProductName = [string]$computerProduct.Name
    SystemVersion = [string]$computerProduct.Version
    # Intentionally omit IdentifyingNumber / UUID / serial numbers.
}

$osInfo = [ordered]@{
    Caption = [string]$os.Caption
    Version = [string]$os.Version
    BuildNumber = [string]$os.BuildNumber
    OSArchitecture = [string]$os.OSArchitecture
}

$biosInfo = [ordered]@{
    Manufacturer = [string]$bios.Manufacturer
    SMBIOSBIOSVersion = [string]$bios.SMBIOSBIOSVersion
    Version = [string]$bios.Version
    ReleaseDate = Convert-ToIso8601DateTimeOrRaw -Value $bios.ReleaseDate
}

Write-Host '[*] Collecting processor-class PnP identity and amdppm.sys metadata...'

$processorPnpDevices = @(
    $allPnpEntities |
    Where-Object {
        ([string]$_.PNPClass -eq 'Processor') -or
        ([string]$_.Service -eq 'amdppm') -or
        ([string]$_.DeviceID -match '(?i)^ACPI\\AuthenticAMD')
    } |
    Sort-Object DeviceID
)

$processorPnpIdentities = @()
$processorGroups = @(
    $processorPnpDevices |
    Group-Object -Property {
        @(
            [string]$_.Name,
            [string]$_.Manufacturer,
            [string]$_.Service,
            (@($_.HardwareID | ForEach-Object { [string]$_ }) -join ';'),
            (@($_.CompatibleID | ForEach-Object { [string]$_ }) -join ';')
        ) -join '|'
    }
)

foreach ($group in $processorGroups) {
    $device = $group.Group[0]
    $hardwareIds = @($device.HardwareID | ForEach-Object { [string]$_ })
    $compatibleIds = @($device.CompatibleID | ForEach-Object { [string]$_ })
    $driver = Get-DriverRecord -DeviceId ([string]$device.DeviceID) -DriverRecords $signedDriverRecords

    $processorPnpIdentities += [pscustomobject][ordered]@{
        Name = [string]$device.Name
        Manufacturer = [string]$device.Manufacturer
        Status = [string]$device.Status
        PNPClass = [string]$device.PNPClass
        Service = [string]$device.Service
        ObservedInstanceCount = $group.Count
        RepresentativeDeviceId = [string]$device.DeviceID
        HardwareIds = $hardwareIds
        CompatibleIds = $compatibleIds
        InstalledDriver = $driver
    }
}

$amdPpmPath = Join-Path $env:SystemRoot 'System32\drivers\amdppm.sys'
$amdPpmEvidence = Get-DriverBinaryEvidence -Path $amdPpmPath

$cpuInfo = @()
foreach ($cpu in $processors) {
    $observedCpuIdentity = Get-ObservedCpuIdentity -Processor $cpu -ProcessorPnpDevices $processorPnpDevices
    $cpuInfo += [pscustomobject][ordered]@{
        Name = [string]$cpu.Name
        Manufacturer = [string]$cpu.Manufacturer
        Description = [string]$cpu.Description
        WmiProcessorFamilyCode = $cpu.Family
        WmiRevision = $cpu.Revision
        Family = $cpu.Family
        Revision = $cpu.Revision
        Stepping = [string]$cpu.Stepping
        ObservedCpuIdentity = $observedCpuIdentity
        Architecture = $cpu.Architecture
        AddressWidth = $cpu.AddressWidth
        NumberOfCores = $cpu.NumberOfCores
        NumberOfLogicalProcessors = $cpu.NumberOfLogicalProcessors
    }
}

Write-Host '[*] Enumerating AMD platform PnP devices (PCI VEN_1022/VEN_1002 and AMD-related ACPI/PnP)...'

$amdPlatformPnpDevices = @(
    $allPnpEntities |
    Where-Object { Test-AmdPlatformPnpDevice -Device $_ } |
    Where-Object { [string]$_.PNPClass -ne 'Processor' } |
    Sort-Object DeviceID -Unique
)

$platformFirmwarePnpDevices = @(
    $allPnpEntities |
    Where-Object { [string]$_.PNPClass -eq 'Firmware' } |
    Sort-Object DeviceID -Unique
)

$allDevices = @()
$amdPciDevices = @()
$npuCandidates = @()
$gpuCandidates = @()
$firmwareDevices = @()
$pnpRawSections = New-Object System.Collections.Generic.List[string]
$pnputilSections = New-Object System.Collections.Generic.List[string]
$platformPnpRawSections = New-Object System.Collections.Generic.List[string]
$firmwarePnpRawSections = New-Object System.Collections.Generic.List[string]
$infSnapshotRoot = Join-Path $EvidenceRoot 'driver-inf'
$infEvidenceByName = @{}
$serviceEvidenceByName = @{}

foreach ($device in $amdPlatformPnpDevices) {
    $driver = Get-DriverRecord -DeviceId ([string]$device.DeviceID) -DriverRecords $signedDriverRecords
    $hardwareIds = @($device.HardwareID | ForEach-Object { [string]$_ })
    $compatibleIds = @($device.CompatibleID | ForEach-Object { [string]$_ })
    $pci = Get-PciIdentity -Ids (@([string]$device.DeviceID) + $hardwareIds + $compatibleIds)
    $props = @(Get-PnpPropertySnapshot -InstanceId ([string]$device.DeviceID))
    $revisionEvidence = Get-NpuRevisionEvidence -Properties $props -PciIdentity $pci
    $reasons = @(Get-NpuCandidateReason -Device $device -Driver $driver)
    $role = Get-AmdPlatformDeviceRole -Device $device -PciIdentity $pci -NpuReasons $reasons
    $topology = Get-DeviceTopologyEvidence -Properties $props

    $serviceEvidence = $null
    $serviceName = [string]$device.Service
    if (-not [string]::IsNullOrWhiteSpace($serviceName)) {
        if (-not $serviceEvidenceByName.ContainsKey($serviceName)) {
            $serviceEvidenceByName[$serviceName] = Get-ServiceBinaryEvidence -ServiceName $serviceName
        }
        $serviceEvidence = $serviceEvidenceByName[$serviceName]
    }

    $infEvidence = $null
    if ($null -ne $driver -and -not [string]::IsNullOrWhiteSpace([string]$driver.InfName)) {
        $infKey = ([string]$driver.InfName).ToLowerInvariant()
        if (-not $infEvidenceByName.ContainsKey($infKey)) {
            $infEvidenceByName[$infKey] = Get-DriverInfEvidence -InfName ([string]$driver.InfName) -SnapshotRoot $infSnapshotRoot
        }
        $infEvidence = $infEvidenceByName[$infKey]
    }

    $record = [pscustomobject][ordered]@{
        Role = $role
        Name = [string]$device.Name
        Description = [string]$device.Description
        Status = [string]$device.Status
        PNPClass = [string]$device.PNPClass
        ClassGuid = [string]$device.ClassGuid
        Service = $serviceName
        Manufacturer = [string]$device.Manufacturer
        DeviceId = [string]$device.DeviceID
        HardwareIds = $hardwareIds
        CompatibleIds = $compatibleIds
        PciIdentity = $pci
        Topology = $topology
        InstalledDriver = $driver
        DriverInfEvidence = $infEvidence
        InfModelEvidence = if ($null -ne $driver) { @(Get-InstalledInfModelEvidence -InfName ([string]$driver.InfName) -HardwareIds $hardwareIds) } else { @() }
        ServiceBinaryEvidence = $serviceEvidence
        PnpProperties = $props
        RevisionEvidence = $revisionEvidence
        QuicktestStyleNpuClassification = if ($reasons.Count -gt 0) { Get-QuicktestStyleNpuClassification -PciIdentity $pci } else { $null }
        NpuCandidateReasons = $reasons
    }

    $allDevices += $record
    if (-not [string]::IsNullOrWhiteSpace([string]$pci.VendorId)) { $amdPciDevices += $record }

    $platformPnpRawSections.Add(('===== [{0}] {1} =====' -f $role, $device.DeviceID)) | Out-Null
    foreach ($prop in $props) {
        $platformPnpRawSections.Add(('{0} [{1}] = {2}' -f $prop.KeyName, $prop.Type, $prop.Data)) | Out-Null
    }
    $platformPnpRawSections.Add('') | Out-Null

    if ($reasons.Count -gt 0) {
        $npuCandidates += $record
        $pnpRawSections.Add(('===== {0} =====' -f $device.DeviceID)) | Out-Null
        foreach ($prop in $props) {
            $pnpRawSections.Add(('{0} [{1}] = {2}' -f $prop.KeyName, $prop.Type, $prop.Data)) | Out-Null
        }
        $pnpRawSections.Add('') | Out-Null

        $pnputilSections.Add(('===== [NPU] {0} =====' -f $device.DeviceID)) | Out-Null
        $pnputilSections.Add((Invoke-PnpUtilForInstance -InstanceId ([string]$device.DeviceID))) | Out-Null
        $pnputilSections.Add('') | Out-Null
    }

    if ($role -eq 'GPU') {
        $gpuCandidates += $record
        $pnputilSections.Add(('===== [GPU] {0} =====' -f $device.DeviceID)) | Out-Null
        $pnputilSections.Add((Invoke-PnpUtilForInstance -InstanceId ([string]$device.DeviceID))) | Out-Null
        $pnputilSections.Add('') | Out-Null
    }
}

foreach ($device in $platformFirmwarePnpDevices) {
    $driver = Get-DriverRecord -DeviceId ([string]$device.DeviceID) -DriverRecords $signedDriverRecords
    $hardwareIds = @($device.HardwareID | ForEach-Object { [string]$_ })
    $compatibleIds = @($device.CompatibleID | ForEach-Object { [string]$_ })
    $props = @(Get-PnpPropertySnapshot -InstanceId ([string]$device.DeviceID))
    $topology = Get-DeviceTopologyEvidence -Properties $props

    $firmwareDevices += [pscustomobject][ordered]@{
        Name = [string]$device.Name
        Description = [string]$device.Description
        Status = [string]$device.Status
        Manufacturer = [string]$device.Manufacturer
        DeviceId = [string]$device.DeviceID
        HardwareIds = $hardwareIds
        CompatibleIds = $compatibleIds
        Topology = $topology
        InstalledDriver = $driver
        PnpProperties = $props
    }

    $firmwarePnpRawSections.Add(('===== {0} =====' -f $device.DeviceID)) | Out-Null
    foreach ($prop in $props) {
        $firmwarePnpRawSections.Add(('{0} [{1}] = {2}' -f $prop.KeyName, $prop.Type, $prop.Data)) | Out-Null
    }
    $firmwarePnpRawSections.Add('') | Out-Null
}

$graphicsAdapters = @(Get-GraphicsAdapterEvidence -Controllers $videoControllers)
$driverInfEvidence = @($infEvidenceByName.Values | Sort-Object InfName)
$serviceBinaryEvidence = @($serviceEvidenceByName.Values | Sort-Object ServiceName)
$deviceRoleSummary = @(
    $allDevices | Group-Object Role | Sort-Object Name | ForEach-Object {
        [pscustomobject][ordered]@{ Role = [string]$_.Name; Count = $_.Count }
    }
)

Write-Host ('[+] AMD platform devices : {0}' -f $allDevices.Count)
Write-Host ('[+] AMD PCI devices      : {0}' -f $amdPciDevices.Count)
Write-Host ('[+] GPU candidates       : {0}' -f $gpuCandidates.Count)
Write-Host ('[+] NPU candidates       : {0}' -f $npuCandidates.Count)
Write-Host ('[+] Firmware devices     : {0}' -f $firmwareDevices.Count)

Write-Host '[*] Probing AMD XRT/xrt-smi runtime and Ryzen AI quicktest source evidence...'
$xrtSmiEvidence = Invoke-XrtSmiEvidenceProbe -EvidenceRoot $EvidenceRoot -TimeoutSeconds $XrtSmiTimeoutSeconds -SkipProbe:$SkipXrtSmiProbe
$quicktestEvidence = Find-RyzenAiQuicktestEvidence -EvidenceRoot $EvidenceRoot -SkipSnapshot:$SkipQuicktestSnapshot
$quicktestPlatformClasses = @($npuCandidates | ForEach-Object { if ($null -ne $_.QuicktestStyleNpuClassification -and -not [string]::IsNullOrWhiteSpace([string]$_.QuicktestStyleNpuClassification.Classification)) { [string]$_.QuicktestStyleNpuClassification.Classification } } | Sort-Object -Unique)
$xrtStructured = $xrtSmiEvidence.StructuredJsonSummary
$xrtDevices = if ($null -ne $xrtStructured) { @($xrtStructured.Devices) } else { @() }
$xrtDrivers = if ($null -ne $xrtStructured) { @($xrtStructured.Drivers) } else { @() }
$xrtDeviceNames = @($xrtDevices | ForEach-Object { [string]$_.Name } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Sort-Object -Unique)
$xrtFirmwareVersions = @($xrtDevices | ForEach-Object { [string]$_.FirmwareVersion } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Sort-Object -Unique)
$xrtBdfs = @($xrtDevices | ForEach-Object { [string]$_.Bdf } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Sort-Object -Unique)
$xrtDriverNames = @($xrtDrivers | ForEach-Object { [string]$_.Name } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Sort-Object -Unique)
$xrtDriverVersions = @($xrtDrivers | ForEach-Object { [string]$_.Version } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Sort-Object -Unique)
$gpuInfSections = @($gpuCandidates | ForEach-Object { @($_.InfModelEvidence) | ForEach-Object { if ($_.PSObject.Properties['InstallSection']) { [string]$_.InstallSection } } } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Sort-Object -Unique)
$xrtPnpCorrelation = [pscustomobject][ordered]@{
    Status = if ($quicktestPlatformClasses.Count -gt 0 -and $xrtDeviceNames.Count -gt 0) { 'CrossSourcePlatformEvidenceAvailable' } elseif ($xrtSmiEvidence.Present) { 'XrtPresentCorrelationIncomplete' } else { 'XrtNotObserved' }
    PnpQuicktestPlatformClassifications = $quicktestPlatformClasses
    XrtDevices = $xrtDevices
    XrtDrivers = $xrtDrivers
    XrtReportedDeviceNames = $xrtDeviceNames
    XrtReportedFirmwareVersions = $xrtFirmwareVersions
    XrtReportedBdfs = $xrtBdfs
    XrtReportedDriverNames = $xrtDriverNames
    XrtReportedDriverVersions = $xrtDriverVersions
    GpuInfInstallSectionHints = $gpuInfSections
    Reviewed376XrtSmiExactMatch = [bool]$xrtSmiEvidence.ReviewedPayloadCorrelation.XrtSmiExactMatch
    ImportantNote = 'XRT device names and firmware versions are runtime evidence. XRT driver names are kept separately and are not treated as device names. Firmware version is not equivalent to the firmware-reported NPU device revision used by the 0x117 GET_DEV_REVISION path.'
}
if ($xrtSmiEvidence.Present) {
    Write-Host ('[+] xrt-smi               : present ({0})' -f $xrtSmiEvidence.DiscoverySource)
    if (-not $SkipXrtSmiProbe -and $null -ne $xrtSmiEvidence.ExamineJsonProbe) {
        Write-Host ('[+] xrt-smi JSON examine  : {0}; exit={1}' -f $xrtSmiEvidence.ExamineJsonProbe.JsonParseStatus, $xrtSmiEvidence.ExamineJsonProbe.ExitCode)
    }
} else {
    Write-Host '[*] xrt-smi               : not found; read-only runtime probe skipped'
}
foreach ($candidate in @($npuCandidates)) {
    $candidate | Add-Member -NotePropertyName ReviewedPublishedPayloadCorrelation -NotePropertyValue (Get-ReviewedPublishedPayloadCorrelation -DriverInfEvidence $candidate.DriverInfEvidence -ServiceBinaryEvidence $candidate.ServiceBinaryEvidence -XrtSmiEvidence $xrtSmiEvidence) -Force
}

if ($quicktestEvidence.Present) {
    Write-Host ('[+] Ryzen AI quicktest.py : present; SHA256={0}' -f $quicktestEvidence.Sha256)
} else {
    Write-Host '[*] Ryzen AI quicktest.py : not found (allowed; Ryzen AI Software may be absent/rolled back)'
}

Write-Host '[*] Extracting relevant SetupAPI.dev.log lines...'

$setupApiPath = Join-Path $env:SystemRoot 'INF\setupapi.dev.log'
$setupApiLines = @()
$setupApiPlatformLines = @()

if (Test-Path -LiteralPath $setupApiPath) {
    try {
        $patterns = New-Object System.Collections.Generic.List[string]
        $patterns.Add('VEN_1022&DEV_1502') | Out-Null
        $patterns.Add('VEN_1022&DEV_17F0') | Out-Null
        $patterns.Add('(?i)\bkipudrv(?:\.(?:inf|sys))?\b') | Out-Null
        $patterns.Add('(?i)\bAMD[\s_-]+(?:NPU|IPU)\b') | Out-Null
        $patterns.Add('(?i)\b(?:NPU|IPU)[\s_-]+(?:Compute|Device|Accelerator)\b') | Out-Null

        foreach ($candidate in $npuCandidates) {
            if (-not [string]::IsNullOrWhiteSpace([string]$candidate.PciIdentity.DeviceId)) {
                $patterns.Add(('VEN_1022&DEV_{0}' -f $candidate.PciIdentity.DeviceId)) | Out-Null
            }
        }

        $pattern = (@($patterns | Select-Object -Unique) -join '|')
        $matches = @(
            Select-String -LiteralPath $setupApiPath -Pattern $pattern -ErrorAction Stop |
            Select-Object -Last 500
        )
        foreach ($match in $matches) {
            $setupApiLines += ('{0}: {1}' -f $match.LineNumber, $match.Line)
        }
    }
    catch {
        $setupApiLines = @('SetupAPI collection error: ' + $_.Exception.Message)
    }
}
else {
    $setupApiLines = @('setupapi.dev.log was not found.')
}

# Build a broader AMD platform SetupAPI evidence slice using exact observed
# device IDs and INF names. Use escaped literal tokens to avoid substring false
# positives such as the earlier "input" -> "npu" regression.
if (Test-Path -LiteralPath $setupApiPath) {
    try {
        $platformPatterns = New-Object System.Collections.Generic.List[string]
        foreach ($device in $allDevices) {
            if (-not [string]::IsNullOrWhiteSpace([string]$device.PciIdentity.VendorId) -and -not [string]::IsNullOrWhiteSpace([string]$device.PciIdentity.DeviceId)) {
                $platformPatterns.Add([regex]::Escape(('VEN_{0}&DEV_{1}' -f $device.PciIdentity.VendorId, $device.PciIdentity.DeviceId))) | Out-Null
            }
            if ($null -ne $device.InstalledDriver -and -not [string]::IsNullOrWhiteSpace([string]$device.InstalledDriver.InfName)) {
                $platformPatterns.Add([regex]::Escape([string]$device.InstalledDriver.InfName)) | Out-Null
            }
        }
        if ($platformPatterns.Count -gt 0) {
            $platformPattern = (@($platformPatterns | Select-Object -Unique) -join '|')
            $platformMatches = @(Select-String -LiteralPath $setupApiPath -Pattern $platformPattern -ErrorAction Stop | Select-Object -Last 2000)
            foreach ($match in $platformMatches) {
                $setupApiPlatformLines += ('{0}: {1}' -f $match.LineNumber, $match.Line)
            }
        }
    }
    catch {
        $setupApiPlatformLines = @('SetupAPI platform collection error: ' + $_.Exception.Message)
    }
}

$summary = [ordered]@{
    SchemaVersion = '2.2'
    Tool = [ordered]@{
        Name = $ToolName
        Version = $ToolVersion
    }
    CollectedAtUtc = (Get-Date).ToUniversalTime().ToString('o')
    Privacy = [ordered]@{
        StructuredCollectorComputerNameCollected = $false
        StructuredCollectorUserNameCollected = $false
        SerialNumbersCollected = $false
        NetworkIdentifiersCollected = $false
        CpuProcessorIdCollected = $false
        PnpSerialNumberValuesCollected = $false
        NetworkAddressValuesCollected = $false
        PrivateEvidenceClassification = 'RuntimePrivateNonCommit'
        PowerShellTranscriptMayContainShellIdentityMetadata = $true
        XrtSmiRawOutputMayContainHostName = $true
        XrtSmiRawOutputMayContainSystemModelAndProcessorName = $true
        ImportantNote = 'Structured collector probes avoid user/computer/network identifiers, but vendor/raw diagnostic output and the PowerShell transcript may contain host identity metadata. Collector evidence is private runtime input and must not be committed directly.'
    }
    System = $systemInfo
    OperatingSystem = $osInfo
    Bios = $biosInfo
    Processors = $cpuInfo
    ProcessorPnpIdentities = $processorPnpIdentities
    AmdProcessorPowerManagementDriver = $amdPpmEvidence
    AmdPlatformDevices = $allDevices
    AmdPciDevices = $amdPciDevices
    DeviceRoleSummary = $deviceRoleSummary
    GraphicsAdapters = $graphicsAdapters
    GpuCandidates = $gpuCandidates
    PlatformFirmwareDevices = $firmwareDevices
    XrtSmiEvidence = $xrtSmiEvidence
    RyzenAiQuicktestEvidence = $quicktestEvidence
    XrtPnpCorrelation = $xrtPnpCorrelation
    DriverInfEvidence = $driverInfEvidence
    ServiceBinaryEvidence = $serviceBinaryEvidence
    NpuCandidates = $npuCandidates
    ResearchInterpretation = [ordered]@{
        PrimaryResearchTarget = 'AMD CPU/NPU/GPU platform correlation; Ryzen AI Z2 Extreme is the current positive-control target'
        KnownAmdNpuDeviceIds = @('1502', '17F0')
        AmdPciVendorIdsCollected = @('1022', '1002')
        PlatformDeviceCorrelationStatus = 'CPU/NPU/GPU/AMD-platform-PnP/firmware/INF/service-binary/XRT evidence collected in one run'
        XrtSmiStatus = if (-not $xrtSmiEvidence.Present) { 'NotInstalledOrNotFound' } elseif ($SkipXrtSmiProbe) { 'PresentProbeSkippedByRequest' } elseif ($null -ne $xrtSmiEvidence.ExamineJsonProbe -and $xrtSmiEvidence.ExamineJsonProbe.JsonParseStatus -eq 'Parsed') { 'ReadOnlyJsonExamineParsed' } else { 'PresentReadOnlyProbeIncomplete' }
        QuicktestSourceStatus = if ($quicktestEvidence.Present) { 'PrivateSourceEvidenceObserved' } else { 'NotObserved' }
        XrtPnpCorrelationStatus = $xrtPnpCorrelation.Status
        PciRevisionStatus = if ($npuCandidates.Count -eq 0) {
            'NoNpuCandidateObserved'
        } elseif (@($npuCandidates | Where-Object { $_.RevisionEvidence.PciRevisionStatus -eq 'ObservedFromPciHardwareId' }).Count -eq $npuCandidates.Count) {
            'ObservedForAllNpuCandidates'
        } elseif (@($npuCandidates | Where-Object { $_.RevisionEvidence.PciRevisionStatus -eq 'ObservedFromPciHardwareId' }).Count -gt 0) {
            'ObservedForSomeNpuCandidates'
        } else {
            'NotObserved'
        }
        PciExpressSpecificationVersionStatus = if ($npuCandidates.Count -eq 0) {
            'NoNpuCandidateObserved'
        } elseif (@($npuCandidates | Where-Object { $_.RevisionEvidence.PciExpressSpecificationVersionStatus -eq 'ObservedFromStandardPnPProperty' }).Count -gt 0) {
            'ObservedForOneOrMoreNpuCandidates'
        } else {
            'NotObserved'
        }
        FirmwareDeviceRevisionStatus = if ($npuCandidates.Count -eq 0) {
            'NoNpuCandidateObserved'
        } elseif (@($npuCandidates | Where-Object { $_.RevisionEvidence.FirmwareDeviceRevisionStatus -eq 'ExplicitPnPPropertyObserved' }).Count -gt 0) {
            'ExplicitPnPPropertyObservedForOneOrMoreNpuCandidates'
        } else {
            'NotObservedThroughCollectedStandardPnPProperties'
        }
        ImportantNote = 'PCI REV_XX, PCI Express specification version, and firmware-reported NPU device revision are different identity layers. The collector does not infer firmware device revision from generic revision/version properties.'
    }
}

$processorText = New-Object System.Collections.Generic.List[string]
$processorText.Add(('Processor PnP identity groups: {0}' -f $processorPnpIdentities.Count)) | Out-Null
$processorText.Add('') | Out-Null
foreach ($p in $processorPnpIdentities) {
    $processorText.Add(('Name                  : {0}' -f $p.Name)) | Out-Null
    $processorText.Add(('Service               : {0}' -f $p.Service)) | Out-Null
    $processorText.Add(('Observed instances    : {0}' -f $p.ObservedInstanceCount)) | Out-Null
    $processorText.Add(('Representative ID     : {0}' -f $p.RepresentativeDeviceId)) | Out-Null
    $processorText.Add(('Hardware IDs          : {0}' -f (@($p.HardwareIds) -join '; '))) | Out-Null
    $processorText.Add(('Compatible IDs        : {0}' -f (@($p.CompatibleIds) -join '; '))) | Out-Null
    if ($null -ne $p.InstalledDriver) {
        $processorText.Add(('Installed driver     : {0}; INF={1}; Provider={2}; Signer={3}' -f $p.InstalledDriver.DriverVersion, $p.InstalledDriver.InfName, $p.InstalledDriver.DriverProviderName, $p.InstalledDriver.Signer)) | Out-Null
    }
    $processorText.Add('') | Out-Null
}
$processorText.Add(('amdppm.sys present    : {0}' -f $amdPpmEvidence.Present)) | Out-Null
if ($amdPpmEvidence.Present) {
    $processorText.Add(('amdppm.sys version    : {0}' -f $amdPpmEvidence.FileVersion)) | Out-Null
    $processorText.Add(('amdppm.sys SHA-256    : {0}' -f $amdPpmEvidence.Sha256)) | Out-Null
    $processorText.Add(('amdppm signature      : {0}' -f $amdPpmEvidence.SignatureStatus)) | Out-Null
    $processorText.Add(('amdppm signer         : {0}' -f $amdPpmEvidence.SignerSubject)) | Out-Null
}

$revisionText = New-Object System.Collections.Generic.List[string]
$revisionText.Add(('NPU candidates: {0}' -f $npuCandidates.Count)) | Out-Null
$revisionText.Add('') | Out-Null
if ($npuCandidates.Count -eq 0) {
    $revisionText.Add('No NPU candidate observed; PCI/NPU revision evidence is not applicable for this run.') | Out-Null
}
else {
    foreach ($candidate in $npuCandidates) {
        $r = $candidate.RevisionEvidence
        $revisionText.Add(('Device                       : {0}' -f $candidate.DeviceId)) | Out-Null
        $revisionText.Add(('PCI revision                 : {0} ({1})' -f $r.PciRevision, $r.PciRevisionStatus)) | Out-Null
        $revisionText.Add(('PCIe specification version   : {0} ({1})' -f $r.PciExpressSpecificationVersion, $r.PciExpressSpecificationVersionStatus)) | Out-Null
        $revisionText.Add(('Firmware device revision     : {0}' -f $r.FirmwareDeviceRevisionStatus)) | Out-Null
        foreach ($prop in @($r.FirmwareDeviceRevisionProperties)) {
            $revisionText.Add(('  Explicit firmware property : {0} [{1}] = {2}' -f $prop.KeyName, $prop.Type, $prop.Data)) | Out-Null
        }
        $revisionText.Add('') | Out-Null
    }
}
$revisionText.Add('Important: DEVPKEY_PciDevice_ExpressSpecVersion is PCIe protocol capability metadata, not the firmware-reported NPU device revision used by amdxdna refinement logic.') | Out-Null

$platformText = New-Object System.Collections.Generic.List[string]
$platformText.Add(('AMD platform devices: {0}' -f $allDevices.Count)) | Out-Null
$platformText.Add(('AMD PCI devices     : {0}' -f $amdPciDevices.Count)) | Out-Null
$platformText.Add(('GPU candidates      : {0}' -f $gpuCandidates.Count)) | Out-Null
$platformText.Add(('NPU candidates      : {0}' -f $npuCandidates.Count)) | Out-Null
$platformText.Add('') | Out-Null
foreach ($role in $deviceRoleSummary) {
    $platformText.Add(('Role {0,-24} : {1}' -f $role.Role, $role.Count)) | Out-Null
}
$platformText.Add('') | Out-Null
foreach ($device in $allDevices) {
    $platformText.Add(('[{0}] {1}' -f $device.Role, $device.Name)) | Out-Null
    $platformText.Add(('  Device : {0}' -f $device.DeviceId)) | Out-Null
    if (-not [string]::IsNullOrWhiteSpace([string]$device.PciIdentity.VendorId)) {
        $platformText.Add(('  PCI    : VEN={0}; DEV={1}; SUBSYS={2}; REV={3}' -f $device.PciIdentity.VendorId, $device.PciIdentity.DeviceId, $device.PciIdentity.SubsystemId, $device.PciIdentity.Revision)) | Out-Null
    }
    $platformText.Add(('  Class  : {0}; Service={1}; Status={2}' -f $device.PNPClass, $device.Service, $device.Status)) | Out-Null
    if ($null -ne $device.InstalledDriver) {
        $platformText.Add(('  Driver : {0}; INF={1}; Provider={2}; Signer={3}' -f $device.InstalledDriver.DriverVersion, $device.InstalledDriver.InfName, $device.InstalledDriver.DriverProviderName, $device.InstalledDriver.Signer)) | Out-Null
    }
    if ($null -ne $device.Topology -and -not [string]::IsNullOrWhiteSpace([string]$device.Topology.Parent)) {
        $platformText.Add(('  Parent : {0}' -f $device.Topology.Parent)) | Out-Null
    }
    $platformText.Add('') | Out-Null
}

$graphicsText = New-Object System.Collections.Generic.List[string]
$graphicsText.Add(('Graphics adapters: {0}' -f $graphicsAdapters.Count)) | Out-Null
$graphicsText.Add('') | Out-Null
foreach ($gpu in $graphicsAdapters) {
    $graphicsText.Add(('Name          : {0}' -f $gpu.Name)) | Out-Null
    $graphicsText.Add(('PNP Device ID : {0}' -f $gpu.PnpDeviceId)) | Out-Null
    $graphicsText.Add(('VideoProcessor: {0}' -f $gpu.VideoProcessor)) | Out-Null
    $graphicsText.Add(('DriverVersion : {0}' -f $gpu.DriverVersion)) | Out-Null
    $graphicsText.Add(('DriverDate    : {0}' -f $gpu.DriverDate)) | Out-Null
    $graphicsText.Add('') | Out-Null
}

$firmwareText = New-Object System.Collections.Generic.List[string]
$firmwareText.Add(('Platform firmware devices: {0}' -f $firmwareDevices.Count)) | Out-Null
$firmwareText.Add('') | Out-Null
foreach ($fw in $firmwareDevices) {
    $firmwareText.Add(('Name        : {0}' -f $fw.Name)) | Out-Null
    $firmwareText.Add(('Device ID   : {0}' -f $fw.DeviceId)) | Out-Null
    $firmwareText.Add(('Status      : {0}' -f $fw.Status)) | Out-Null
    if ($null -ne $fw.InstalledDriver) {
        $firmwareText.Add(('Driver      : {0}; INF={1}; Provider={2}' -f $fw.InstalledDriver.DriverVersion, $fw.InstalledDriver.InfName, $fw.InstalledDriver.DriverProviderName)) | Out-Null
    }
    foreach ($prop in @($fw.PnpProperties | Where-Object { [string]$_.KeyName -match '(?i)firmware|version|revision' })) {
        $firmwareText.Add(('Property    : {0} [{1}] = {2}' -f $prop.KeyName, $prop.Type, $prop.Data)) | Out-Null
    }
    $firmwareText.Add('') | Out-Null
}

Write-JsonFile -Value $summary -Path (Join-Path $EvidenceRoot 'amd-npu-hardware-summary.json')
Write-Utf8File -Path (Join-Path $EvidenceRoot 'processor-identity-summary.txt') -Text (($processorText.ToArray()) -join "`n")
Write-Utf8File -Path (Join-Path $EvidenceRoot 'npu-revision-evidence-summary.txt') -Text (($revisionText.ToArray()) -join "`n")
Write-Utf8File -Path (Join-Path $EvidenceRoot 'amd-platform-device-summary.txt') -Text (($platformText.ToArray()) -join "`n")
Write-Utf8File -Path (Join-Path $EvidenceRoot 'graphics-adapter-summary.txt') -Text (($graphicsText.ToArray()) -join "`n")
Write-Utf8File -Path (Join-Path $EvidenceRoot 'platform-firmware-summary.txt') -Text (($firmwareText.ToArray()) -join "`n")
Write-Utf8File -Path (Join-Path $EvidenceRoot 'amd-platform-pnp-properties.txt') -Text (($platformPnpRawSections.ToArray()) -join "`n")
Write-Utf8File -Path (Join-Path $EvidenceRoot 'platform-firmware-pnp-properties.txt') -Text (($firmwarePnpRawSections.ToArray()) -join "`n")
Write-JsonFile -Value @($driverInfEvidence) -Path (Join-Path $EvidenceRoot 'driver-inf-manifest.json')
Write-JsonFile -Value $xrtSmiEvidence -Path (Join-Path $EvidenceRoot 'xrt-smi-evidence.json')
Write-JsonFile -Value $quicktestEvidence -Path (Join-Path $EvidenceRoot 'ryzen-ai-quicktest-evidence.json')
Write-Utf8File -Path (Join-Path $EvidenceRoot 'npu-candidate-pnp-properties.txt') -Text (($pnpRawSections.ToArray()) -join "`n")
Write-Utf8File -Path (Join-Path $EvidenceRoot 'npu-candidate-pnputil.txt') -Text (($pnputilSections.ToArray()) -join "`n")
Write-Utf8File -Path (Join-Path $EvidenceRoot 'setupapi-npu-matches.txt') -Text ($setupApiLines -join "`n")
Write-Utf8File -Path (Join-Path $EvidenceRoot 'setupapi-amd-platform-matches.txt') -Text ($setupApiPlatformLines -join "`n")

$summaryText = New-Object System.Collections.Generic.List[string]
$summaryText.Add(('Tool            : {0} v{1}' -f $ToolName, $ToolVersion)) | Out-Null
$summaryText.Add(('Collected UTC   : {0}' -f $summary.CollectedAtUtc)) | Out-Null
$summaryText.Add(('System          : {0} {1}' -f $systemInfo.Manufacturer, $systemInfo.Model)) | Out-Null
$summaryText.Add(('System product  : {0}' -f $systemInfo.SystemProductName)) | Out-Null
$summaryText.Add(('OS              : {0} / {1} / build {2}' -f $osInfo.Caption, $osInfo.Version, $osInfo.BuildNumber)) | Out-Null
$summaryText.Add(('BIOS            : {0}' -f $biosInfo.SMBIOSBIOSVersion)) | Out-Null
foreach ($cpu in $cpuInfo) {
    $summaryText.Add(('CPU             : {0}' -f $cpu.Name)) | Out-Null
    $summaryText.Add(('WMI family/rev  : FamilyCode={0}; Revision={1}; Stepping={2}' -f $cpu.WmiProcessorFamilyCode, $cpu.WmiRevision, $cpu.Stepping)) | Out-Null
    if ($cpu.ObservedCpuIdentity.Status -eq 'Resolved') {
        $summaryText.Add(('CPU identity    : Family={0}; Model={1}; Stepping={2}; Source={3}' -f $cpu.ObservedCpuIdentity.Family, $cpu.ObservedCpuIdentity.Model, $cpu.ObservedCpuIdentity.Stepping, $cpu.ObservedCpuIdentity.Source)) | Out-Null
    }
}
$summaryText.Add(('Processor PnP IDs: {0}' -f $processorPnpIdentities.Count)) | Out-Null
if ($amdPpmEvidence.Present) {
    $summaryText.Add(('amdppm.sys      : {0}; SHA256={1}' -f $amdPpmEvidence.FileVersion, $amdPpmEvidence.Sha256)) | Out-Null
} else {
    $summaryText.Add('amdppm.sys      : not present') | Out-Null
}
$summaryText.Add(('AMD platform dev: {0}' -f $allDevices.Count)) | Out-Null
$summaryText.Add(('AMD PCI devices : {0}' -f $amdPciDevices.Count)) | Out-Null
$summaryText.Add(('GPU candidates  : {0}' -f $gpuCandidates.Count)) | Out-Null
$summaryText.Add(('NPU candidates  : {0}' -f $npuCandidates.Count)) | Out-Null
$summaryText.Add(('Firmware devices: {0}' -f $firmwareDevices.Count)) | Out-Null
$xrtSmiSummaryStatus = if ($xrtSmiEvidence.Present) { 'present' } else { 'not found' }
$summaryText.Add(('xrt-smi         : {0}' -f $xrtSmiSummaryStatus)) | Out-Null
if ($xrtSmiEvidence.Present -and $null -ne $xrtSmiEvidence.ExamineJsonProbe) {
    $summaryText.Add(('xrt-smi JSON    : {0}; exit={1}' -f $xrtSmiEvidence.ExamineJsonProbe.JsonParseStatus, $xrtSmiEvidence.ExamineJsonProbe.ExitCode)) | Out-Null
    if ($null -ne $xrtSmiEvidence.StructuredJsonSummary) {
        $xs = $xrtSmiEvidence.StructuredJsonSummary
        $summaryText.Add(('  XRT version: {0}; hash={1}; build={2}' -f $xs.Xrt.Version, $xs.Xrt.Hash, $xs.Xrt.BuildDate)) | Out-Null
        foreach ($driver in @($xs.Drivers)) {
            $summaryText.Add(('  XRT driver : {0}; version={1}' -f $driver.Name, $driver.Version)) | Out-Null
        }
        foreach ($device in @($xs.Devices)) {
            $summaryText.Add(('  XRT device : {0}; BDF={1}; firmware={2}; ready={3}' -f $device.Name, $device.Bdf, $device.FirmwareVersion, $device.Ready)) | Out-Null
        }
    }
}
if ($xrtPnpCorrelation.PnpQuicktestPlatformClassifications.Count -gt 0) {
    $summaryText.Add(('PnP quicktest class: {0}' -f (@($xrtPnpCorrelation.PnpQuicktestPlatformClassifications) -join ', '))) | Out-Null
}
if ($xrtPnpCorrelation.XrtReportedDeviceNames.Count -gt 0) {
    $summaryText.Add(('XRT device names : {0}' -f (@($xrtPnpCorrelation.XrtReportedDeviceNames) -join ', '))) | Out-Null
}
if ($xrtPnpCorrelation.XrtReportedFirmwareVersions.Count -gt 0) {
    $summaryText.Add(('XRT firmware ver : {0}' -f (@($xrtPnpCorrelation.XrtReportedFirmwareVersions) -join ', '))) | Out-Null
}
$quicktestSummaryStatus = if ($quicktestEvidence.Present) { 'private source evidence observed; not executed' } else { 'not found' }
$summaryText.Add(('quicktest.py    : {0}' -f $quicktestSummaryStatus)) | Out-Null
$summaryText.Add('') | Out-Null

if ($npuCandidates.Count -eq 0) {
    $summaryText.Add('No NPU candidate was found by the current rules.') | Out-Null
    $summaryText.Add('Please still share the ZIP: all AMD PCI devices are retained in the JSON for unknown/new device-ID analysis.') | Out-Null
}
else {
    for ($i = 0; $i -lt $npuCandidates.Count; $i++) {
        $c = $npuCandidates[$i]
        $summaryText.Add(('NPU candidate #{0}' -f ($i + 1))) | Out-Null
        $summaryText.Add(('  Name       : {0}' -f $c.Name)) | Out-Null
        $summaryText.Add(('  DeviceId   : {0}' -f $c.DeviceId)) | Out-Null
        $summaryText.Add(('  PCI        : VEN={0}; DEV={1}; SUBSYS={2}; REV={3}' -f $c.PciIdentity.VendorId, $c.PciIdentity.DeviceId, $c.PciIdentity.SubsystemId, $c.PciIdentity.Revision)) | Out-Null
        $summaryText.Add(('  Reasons    : {0}' -f (@($c.NpuCandidateReasons) -join ', '))) | Out-Null
        $summaryText.Add(('  PCI REV    : {0} ({1})' -f $c.RevisionEvidence.PciRevision, $c.RevisionEvidence.PciRevisionStatus)) | Out-Null
        $summaryText.Add(('  PCIe spec  : {0} ({1})' -f $c.RevisionEvidence.PciExpressSpecificationVersion, $c.RevisionEvidence.PciExpressSpecificationVersionStatus)) | Out-Null
        $summaryText.Add(('  FW dev rev : {0}' -f $c.RevisionEvidence.FirmwareDeviceRevisionStatus)) | Out-Null
        if ($null -ne $c.QuicktestStyleNpuClassification) {
            $summaryText.Add(('  Quicktest  : {0} ({1})' -f $c.QuicktestStyleNpuClassification.Classification, $c.QuicktestStyleNpuClassification.Status)) | Out-Null
        }
        foreach ($model in @($c.InfModelEvidence)) {
            if ($model.PSObject.Properties['InstallSection'] -and -not [string]::IsNullOrWhiteSpace([string]$model.InstallSection)) {
                $summaryText.Add(('  INF model  : {0}; section={1}; HWID={2}' -f $model.InfName, $model.InstallSection, $model.MatchedHardwareId)) | Out-Null
            }
        }
        if ($c.PSObject.Properties['ReviewedPublishedPayloadCorrelation']) {
            $corr = $c.ReviewedPublishedPayloadCorrelation
            $summaryText.Add(('  376 exact  : INF={0}; ipustack={1}; xrt-smi={2}; full={3}' -f $corr.InfExactMatch, $corr.DriverBinaryExactMatch, $corr.XrtSmiExactMatch, $corr.FullObservedStackExactMatch)) | Out-Null
        }
        if ($null -ne $c.InstalledDriver) {
            $summaryText.Add(('  Driver     : {0}; INF={1}; Provider={2}; Signed={3}; Signer={4}' -f $c.InstalledDriver.DriverVersion, $c.InstalledDriver.InfName, $c.InstalledDriver.DriverProviderName, $c.InstalledDriver.IsSigned, $c.InstalledDriver.Signer)) | Out-Null
        }
        $summaryText.Add('') | Out-Null
    }
}

$summaryText.Add('Important: PCI REV_XX, PCIe specification version, and firmware-reported NPU device revision are separate identity layers. PCIe ExpressSpecVersion must not be used as firmware device revision.') | Out-Null
$summaryText.Add('XRT safety: collector invokes only read-only xrt-smi --version/examine. It never invokes validate/configure and never executes quicktest.py.') | Out-Null
Write-Utf8File -Path (Join-Path $EvidenceRoot 'SUMMARY.txt') -Text (($summaryText.ToArray()) -join "`n")

    $script:CollectorSucceeded = $true
}
catch {
    $script:CollectorErrorRecord = $_
    Write-Host ''
    Write-Host ('[-] Collector failed: {0}' -f $_.Exception.Message)
    Write-CollectorFailureRecord -Root $EvidenceRoot -ErrorRecord $_
}
finally {
    if ($script:TranscriptStarted) {
        try {
            Stop-Transcript | Out-Null
        }
        catch {
            Write-Host ('[!] Transcript could not be stopped cleanly: {0}' -f $_.Exception.Message)
        }
        $script:TranscriptStarted = $false
    }

    Write-Host '[*] Finalizing evidence manifest and ZIP...'
    $finalization = Complete-CollectorEvidencePackage `
        -Root $EvidenceRoot `
        -Destination $ZipPath `
        -Succeeded $script:CollectorSucceeded `
        -ErrorRecord $script:CollectorErrorRecord

    Write-Host ''
    if ($script:CollectorSucceeded) {
        Write-Host '[+] Collection completed.'
    }
    else {
        Write-Host '[!] Collection completed with errors. Partial evidence was preserved.'
    }

    if ($finalization.ArchiveSuccess) {
        Write-Host ('[+] Evidence ZIP : {0}' -f $ZipPath)
        Write-Host ('[+] SHA-256      : {0}' -f $finalization.ArchiveSha256)
        if (-not $finalization.ManifestSuccess) {
            Write-Host '[!] Evidence manifest finalization reported an error; inspect errors/ inside the ZIP.'
        }
        if (-not [string]::IsNullOrWhiteSpace([string]$finalization.Error)) {
            Write-Host ('[!] Archive note : {0}' -f $finalization.Error)
        }
        Write-Host ''
        Write-Host 'Please share the generated ZIP file for analysis.'
    }
    else {
        Write-Host ('[-] Evidence ZIP creation failed: {0}' -f $finalization.Error)
        Write-Host ('[!] Evidence directory was retained: {0}' -f $EvidenceRoot)
    }

    if ($script:CollectorSucceeded -and $finalization.ArchiveSuccess -and -not $KeepDirectory) {
        try {
            Remove-Item -LiteralPath $EvidenceRoot -Recurse -Force -ErrorAction Stop
        }
        catch {
            Write-Host ('[!] Evidence ZIP is valid, but the working directory could not be removed: {0}' -f $_.Exception.Message)
        }
    }
}

if (-not $script:CollectorSucceeded) {
    # Do not rethrow here. The primary requirement of this collector is to
    # preserve partial evidence even when one probe fails. The failure is
    # represented by collector-status.json and errors/collector-error.txt.
    Write-Error -Message ('AMD platform evidence collection failed. Evidence finalization was attempted. {0}' -f $script:CollectorErrorRecord.Exception.Message) -ErrorAction Continue
}
