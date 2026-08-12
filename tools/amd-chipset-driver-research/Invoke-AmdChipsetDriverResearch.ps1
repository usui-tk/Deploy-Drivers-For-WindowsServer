# AMD Chipset Driver Research Toolkit 2.0.0
# INF semantic analysis + AMD selector reverse-engineering / host-analysis development line.
# PowerShell 5.1 and PowerShell 7.x; single-script implementation.
[CmdletBinding()]
param(
    [string[]]$Stages = @('All'),

    [string[]]$ReleaseVersion = @(),

    [string]$SevenZipPath,

    [int]$MaxDepth = 5,

    [string[]]$SitemapUri = @(
        'https://www.amd.com/en.sitemap.xml',
        'https://www.amd.com/sitemap.xml'
    ),

    [string[]]$AdditionalReleaseNotesUrl = @(),

    [string]$EvidenceOutputRoot,

    [string]$EvidenceLabel,

    [string]$PublicOutputRoot,

    [switch]$SkipPublicExport,

    [switch]$SkipEvidenceArchive,

    [switch]$IncludeInstallersInEvidence,

    [switch]$AllowNonAmdHost,

    [switch]$SkipHostAnalysis,

    [string]$ObservedAmdDeviceIdLog,

    [string]$ObservedAmdMsiLog,

    [string]$ObservedAmdReleaseVersion,

    [switch]$Force
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2.0

$script:AmdChipsetResearchToolkitVersion = '2.0.0'
$script:AmdChipsetResearchToolkitRoot = $PSScriptRoot
$script:AmdPublicOutputRoot = if ([string]::IsNullOrWhiteSpace($PublicOutputRoot)) { Join-Path $PSScriptRoot 'public' } else { $PublicOutputRoot }
$script:AmdPublicationResult = $null

$script:AmdChipsetResearchEvidenceSchemaVersion = 'amd-chipset-driver-research-evidence/1.1'
$script:AmdChipsetResearchAnalysisSchemaVersion = 'amd-chipset-driver-release-analysis/2.5'
$script:AmdInfSemanticContractVersion = 'amd-inf-semantic-contract/1.0'
$script:AmdInfIdentifierTaxonomyVersion = 'amd-inf-identifier-taxonomy/1.0'
$script:AmdStageResults = New-Object 'System.Collections.Generic.List[object]'
$script:AmdEvidenceContext = $null
$script:AmdTranscriptStarted = $false
$script:AmdTopLevelFatalError = $null
$script:AmdRunStartTime = Get-Date
$script:AmdCurrentStageStart = $null
$script:AmdCurrentStageName = $null
$script:AmdStageOrdinal = 0
$script:AmdResolvedStageCount = 0

function Get-AmdResearchToolkitRoot {
    [CmdletBinding()]
    param()

    return $script:AmdChipsetResearchToolkitRoot
}

function Get-AmdPublicOutputRoot {
    [CmdletBinding()]
    param()

    return $script:AmdPublicOutputRoot
}

function Get-AmdPrivateEvidenceRoot {
    [CmdletBinding()]
    param()

    return (Join-Path (Join-Path (Get-AmdResearchToolkitRoot) 'private') 'evidence')
}

function New-AmdDirectory {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    if (-not (Test-Path -LiteralPath $Path -PathType Container)) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
    }

    return (Resolve-Path -LiteralPath $Path).Path
}

function Write-AmdUtf8NoBom {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]$Text
    )

    $directory = Split-Path -Parent $Path
    if ($directory) {
        New-AmdDirectory -Path $directory | Out-Null
    }

    $encoding = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($Path, $Text, $encoding)
}

function Read-AmdTextFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    return [System.IO.File]::ReadAllText((Resolve-Path -LiteralPath $Path).Path)
}

function Write-AmdJsonFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [AllowNull()]
        [object]$Value,

        [int]$Depth = 30,

        [switch]$Compress
    )

    $json = $Value | ConvertTo-Json -Depth $Depth -Compress:$Compress
    Write-AmdUtf8NoBom -Path $Path -Text ($json + [Environment]::NewLine)
}

function Read-AmdJsonFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    $raw = Read-AmdTextFile -Path $Path
    return ($raw | ConvertFrom-Json)
}


function Get-AmdCollectionItems {
    [CmdletBinding()]
    param([AllowNull()]$Value)

    if ($null -eq $Value) { return @() }

    # Windows PowerShell 5.1 can serialize selected collection-valued properties as
    # { "value": [...], "Count": n }. Treat that shape as a collection only when
    # consuming generated Raw JSON; the canonical JSON itself remains untouched.
    if ($Value -is [System.Management.Automation.PSCustomObject]) {
        $properties = @($Value.PSObject.Properties)
        $names = @($properties | ForEach-Object { [string]$_.Name })
        if ($properties.Count -eq 2 -and $names -contains 'value' -and $names -contains 'Count') {
            return @($Value.value)
        }
    }

    if ($Value -is [string]) { return @($Value) }
    if ($Value -is [System.Collections.IEnumerable]) { return @($Value) }
    return @($Value)
}

function Test-AmdPowerShell51CollectionWrapperObject {
    [CmdletBinding()]
    param([AllowNull()]$Value)

    if ($null -eq $Value -or -not ($Value -is [System.Management.Automation.PSCustomObject])) { return $false }
    $properties = @($Value.PSObject.Properties)
    if ($properties.Count -ne 2) { return $false }
    $names = @($properties | ForEach-Object { [string]$_.Name })
    if (-not ($names -contains 'value' -and $names -contains 'Count')) { return $false }

    $declaredCount = 0
    try { $declaredCount = [int]$Value.Count }
    catch { return $false }
    if ($declaredCount -lt 0) { return $false }

    # Observed Windows PowerShell 5.1 wrappers always carry an array-like `value`.
    # Requiring an enumerable value avoids rewriting an unrelated domain object that
    # merely happens to expose scalar `value` and `Count` properties.
    if ($null -eq $Value.value -or $Value.value -is [string] -or -not ($Value.value -is [System.Collections.IEnumerable])) {
        return $false
    }
    $actualCount = @($Value.value).Count
    return ($actualCount -eq $declaredCount)
}

function ConvertTo-AmdCanonicalPublicAggregateValue {
    [CmdletBinding()]
    param([AllowNull()]$Value)

    if ($null -eq $Value) { return $null }

    # Windows PowerShell 5.1 can materialize collection-valued properties as
    # { "value": [...], "Count": n }. Public aggregate indexes are derived
    # views, not primary Raw JSON, so unwrap this serialization artifact here.
    # Per-release Raw JSON is never rewritten by this function.
    if (Test-AmdPowerShell51CollectionWrapperObject -Value $Value) {
        $items = New-Object 'System.Collections.Generic.List[object]'
        foreach ($item in @($Value.value)) {
            $items.Add((ConvertTo-AmdCanonicalPublicAggregateValue -Value $item))
        }
        return ,@($items.ToArray())
    }

    if ($Value -is [System.Collections.IDictionary]) {
        $result = [ordered]@{}
        foreach ($key in @($Value.Keys)) {
            $result[$key] = ConvertTo-AmdCanonicalPublicAggregateValue -Value $Value[$key]
        }
        return $result
    }

    if ($Value -is [System.Management.Automation.PSCustomObject]) {
        $result = [ordered]@{}
        foreach ($property in @($Value.PSObject.Properties)) {
            $result[$property.Name] = ConvertTo-AmdCanonicalPublicAggregateValue -Value $property.Value
        }
        return [pscustomobject]$result
    }

    if ($Value -is [string]) { return $Value }
    if ($Value -is [System.Collections.IEnumerable]) {
        $items = New-Object 'System.Collections.Generic.List[object]'
        foreach ($item in @($Value)) {
            $items.Add((ConvertTo-AmdCanonicalPublicAggregateValue -Value $item))
        }
        return ,@($items.ToArray())
    }

    return $Value
}

function Write-AmdCanonicalPublicAggregateJsonFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][string]$Path,
        [Parameter(Mandatory=$true)][AllowNull()][object]$Value,
        [int]$Depth = 30,
        [switch]$Compress
    )

    $canonical = ConvertTo-AmdCanonicalPublicAggregateValue -Value $Value
    Write-AmdJsonFile -Path $Path -Value $canonical -Depth $Depth -Compress:$Compress
}

function Get-AmdPowerShell51CollectionWrapperPaths {
    [CmdletBinding()]
    param([AllowNull()]$Value,[string]$Path='$')

    $results = New-Object 'System.Collections.Generic.List[string]'
    $stack = New-Object System.Collections.Stack
    $stack.Push([pscustomobject]@{ Value=$Value; Path=$Path })
    while ($stack.Count -gt 0) {
        $entry = $stack.Pop()
        $current = $entry.Value
        $currentPath = [string]$entry.Path
        if ($null -eq $current) { continue }
        if (Test-AmdPowerShell51CollectionWrapperObject -Value $current) {
            $results.Add($currentPath)
            continue
        }
        if ($current -is [System.Collections.IDictionary]) {
            foreach ($key in @($current.Keys)) {
                $stack.Push([pscustomobject]@{Value=$current[$key];Path=('{0}.{1}' -f $currentPath,$key)})
            }
            continue
        }
        if ($current -is [System.Management.Automation.PSCustomObject]) {
            foreach ($property in @($current.PSObject.Properties)) {
                $stack.Push([pscustomobject]@{Value=$property.Value;Path=('{0}.{1}' -f $currentPath,$property.Name)})
            }
            continue
        }
        if ($current -is [string]) { continue }
        if ($current -is [System.Collections.IEnumerable]) {
            $index = 0
            foreach ($item in @($current)) {
                $stack.Push([pscustomobject]@{Value=$item;Path=('{0}[{1}]' -f $currentPath,$index)})
                $index++
            }
        }
    }
    return @($results.ToArray())
}

function Test-AmdSelectorStaticAggregateShape {
    [CmdletBinding()]
    param([AllowNull()]$Value)

    $errors = New-Object 'System.Collections.Generic.List[string]'
    if ($null -eq $Value) {
        $errors.Add('selector aggregate is null')
    }
    else {
        if ([string]$Value.SchemaVersion -ne 'amd-chipset-selector-static/1.2') {
            $errors.Add(('unexpected selector aggregate SchemaVersion: {0}' -f [string]$Value.SchemaVersion))
        }
        foreach ($path in @(Get-AmdPowerShell51CollectionWrapperPaths -Value $Value)) {
            $errors.Add(('PowerShell 5.1 collection wrapper remains in selector aggregate at {0}' -f $path))
        }

        $releases = @($Value.Releases)
        foreach ($release in $releases) {
            if ($null -eq $release) { $errors.Add('null release entry in selector aggregate'); continue }
            foreach ($propertyName in @('DevIdRules','Notes')) {
                $property = $release.PSObject.Properties[$propertyName]
                if ($null -ne $property -and $null -ne $property.Value -and ($property.Value -is [System.Management.Automation.PSCustomObject])) {
                    $errors.Add(('{0}.{1} is not an array-compatible value' -f [string]$release.ReleaseVersion,$propertyName))
                }
            }
            $binary = $release.SelectorBinaryEvidence
            if ($null -ne $binary) {
                foreach ($propertyName in @('StringEvidence','UnicodeStringEvidence','Notes')) {
                    $property = $binary.PSObject.Properties[$propertyName]
                    if ($null -ne $property -and $null -ne $property.Value -and ($property.Value -is [System.Management.Automation.PSCustomObject])) {
                        $errors.Add(('{0}.SelectorBinaryEvidence.{1} is not an array-compatible value' -f [string]$release.ReleaseVersion,$propertyName))
                    }
                }
                $contract = $binary.CompiledSelectorContract
                if ($null -ne $contract) {
                    $property = $contract.PSObject.Properties['ReverseEngineeringNotes']
                    if ($null -ne $property -and $null -ne $property.Value -and ($property.Value -is [System.Management.Automation.PSCustomObject])) {
                        $errors.Add(('{0}.SelectorBinaryEvidence.CompiledSelectorContract.ReverseEngineeringNotes is not an array-compatible value' -f [string]$release.ReleaseVersion))
                    }
                }
            }
        }
    }

    return [pscustomobject][ordered]@{
        Status=if($errors.Count -eq 0){'Pass'}else{'Fail'}
        ErrorCount=$errors.Count
        Errors=@($errors.ToArray())
    }
}

function Get-AmdUtcTimestamp {
    [CmdletBinding()]
    param()

    return [DateTime]::UtcNow.ToString('o')
}

# Logging conventions intentionally mirror the repository's primary deployment
# scripts (Format-Elapsed / _LogLine / phase header+footer), while retaining
# tool-specific Amd-prefixed names to avoid collisions when dot-sourced.
function Format-AmdElapsed {
    [CmdletBinding()]
    param([TimeSpan]$Span)

    if ($null -eq $Span) { return '0.00s' }
    if ($Span.TotalSeconds -lt 60) {
        return ('{0:F2}s' -f $Span.TotalSeconds)
    }
    elseif ($Span.TotalMinutes -lt 60) {
        $m = [int][math]::Floor($Span.TotalMinutes)
        $s = $Span.TotalSeconds - ($m * 60)
        return ('{0}m{1:F1}s' -f $m, $s)
    }
    else {
        $h = [int][math]::Floor($Span.TotalHours)
        return ('{0}h{1:D2}m{2:D2}s' -f $h, $Span.Minutes, $Span.Seconds)
    }
}

function Format-AmdByteSize {
    [CmdletBinding()]
    param([long]$Bytes)

    if ($Bytes -lt 1024) { return ('{0} B' -f $Bytes) }
    if ($Bytes -lt 1MB) { return ('{0:F1} KiB' -f ($Bytes / 1KB)) }
    if ($Bytes -lt 1GB) { return ('{0:F1} MiB' -f ($Bytes / 1MB)) }
    return ('{0:F2} GiB' -f ($Bytes / 1GB))
}

function Get-AmdStageElapsedTag {
    [CmdletBinding()]
    param()

    if ($null -eq $script:AmdCurrentStageStart) { return '' }
    return ('[+{0}]' -f (Format-AmdElapsed ((Get-Date) - $script:AmdCurrentStageStart)))
}

function Write-AmdLogLine {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][string]$Marker,
        [Parameter(Mandatory=$true)][AllowEmptyString()][string]$Message,
        [ConsoleColor]$Color = [ConsoleColor]::Gray
    )

    $ts = Get-Date -Format 'HH:mm:ss'
    $tag = Get-AmdStageElapsedTag
    if ($tag) {
        Write-Host ("[{0}] {1,-12} {2} {3}" -f $ts, $tag, $Marker, $Message) -ForegroundColor $Color
    }
    else {
        Write-Host ("[{0}] {1,-12} {2} {3}" -f $ts, '', $Marker, $Message) -ForegroundColor $Color
    }
}

function Write-AmdStep    { param([string]$Message) Write-AmdLogLine -Marker '[*]' -Message $Message -Color Cyan }
function Write-AmdOk      { param([string]$Message) Write-AmdLogLine -Marker '[+]' -Message $Message -Color Green }
function Write-AmdCaution { param([string]$Message) Write-AmdLogLine -Marker '[!]' -Message $Message -Color Yellow }
function Write-AmdFail    { param([string]$Message) Write-AmdLogLine -Marker '[X]' -Message $Message -Color Red }
function Write-AmdSkip    { param([string]$Message) Write-AmdLogLine -Marker '[~]' -Message $Message -Color DarkGray }

function Write-AmdDetail {
    [CmdletBinding()]
    param(
        [AllowEmptyString()][string]$Message,
        [ConsoleColor]$Color = [ConsoleColor]::Gray
    )
    Write-Host ('    {0}' -f $Message) -ForegroundColor $Color
}

function Write-AmdStageHeader {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][string]$Name,
        [int]$Ordinal,
        [int]$Total
    )

    $script:AmdCurrentStageStart = Get-Date
    $script:AmdCurrentStageName = $Name
    $startStr = $script:AmdCurrentStageStart.ToString('HH:mm:ss')
    $line = '=' * 72
    Write-Host ''
    Write-Host $line -ForegroundColor Magenta
    if ($Total -gt 0) {
        Write-Host (' STAGE {0}/{1} - {2,-20} start: {3}' -f $Ordinal, $Total, $Name, $startStr) -ForegroundColor Magenta
    }
    else {
        Write-Host (' STAGE {0,-24} start: {1}' -f $Name, $startStr) -ForegroundColor Magenta
    }
    Write-Host (' toolkit: v{0}' -f $script:AmdChipsetResearchToolkitVersion) -ForegroundColor DarkGray
    Write-Host $line -ForegroundColor Magenta
}

function Write-AmdStageFooter {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][string]$Name,
        [Parameter(Mandatory=$true)][ValidateSet('PASS','FAIL','BLOCKED')][string]$Status,
        [Parameter(Mandatory=$true)][TimeSpan]$Elapsed
    )

    $color = if ($Status -eq 'PASS') { 'Green' } elseif ($Status -eq 'BLOCKED') { 'Yellow' } else { 'Red' }
    Write-Host (' STAGE {0,-20} -> {1,-4}  elapsed: {2}' -f $Name, $Status, (Format-AmdElapsed $Elapsed)) -ForegroundColor $color
    $script:AmdCurrentStageStart = $null
    $script:AmdCurrentStageName = $null
}

function Write-AmdRunTimingSummary {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][object]$Assessment
    )

    $totalElapsed = (Get-Date) - $script:AmdRunStartTime
    Write-Host ''
    Write-Host '========================================================================' -ForegroundColor Magenta
    Write-Host ' RUN TIMING SUMMARY' -ForegroundColor Magenta
    Write-Host '========================================================================' -ForegroundColor Magenta
    Write-Host (' Started at      : {0}' -f $script:AmdRunStartTime.ToString('yyyy-MM-dd HH:mm:ss'))
    Write-Host (' Current/ended   : {0}' -f (Get-Date).ToString('yyyy-MM-dd HH:mm:ss'))
    Write-Host (' Total elapsed   : {0}' -f (Format-AmdElapsed $totalElapsed)) -ForegroundColor Cyan

    if ($script:AmdStageResults.Count -gt 0) {
        Write-Host ''
        Write-Host ' Stage timings:' -ForegroundColor Cyan
        Write-Host ('   {0,-12} {1,-6} {2,12}' -f 'Stage','Status','Elapsed')
        Write-Host ('   {0}' -f ('-' * 34))
        foreach ($t in $script:AmdStageResults) {
            $span = [TimeSpan]::FromMilliseconds([double]$t.DurationMilliseconds)
            $color = if ($t.Status -eq 'PASS') { 'Green' } else { 'Red' }
            Write-Host ('   {0,-12} {1,-6} {2,12}' -f $t.Name, $t.Status, (Format-AmdElapsed $span)) -ForegroundColor $color
        }
    }

    Write-Host ''
    Write-Host (' Assessment      : {0}' -f $Assessment.OverallStatus)
    Write-Host (' Exit code       : {0}' -f $Assessment.ExitCode)
    Write-Host '========================================================================' -ForegroundColor Magenta
}

function ConvertTo-AmdEvidenceSafeFragment {
    [CmdletBinding()]
    param(
        [Parameter()]
        [AllowEmptyString()]
        [string]$Value
    )

    if ([string]::IsNullOrWhiteSpace($Value)) {
        return ''
    }

    $safe = $Value -replace '[^A-Za-z0-9._-]', '-'
    $safe = $safe.Trim('-')
    if ($safe.Length -gt 64) {
        $safe = $safe.Substring(0, 64).Trim('-')
    }
    return $safe
}

function Get-AmdRelativePath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$BasePath,

        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    $baseFull = [System.IO.Path]::GetFullPath($BasePath)
    $pathFull = [System.IO.Path]::GetFullPath($Path)

    if (-not $baseFull.EndsWith([System.IO.Path]::DirectorySeparatorChar.ToString())) {
        $baseFull += [System.IO.Path]::DirectorySeparatorChar
    }

    $baseUri = New-Object System.Uri($baseFull)
    $pathUri = New-Object System.Uri($pathFull)
    $relative = [System.Uri]::UnescapeDataString($baseUri.MakeRelativeUri($pathUri).ToString())
    return ($relative -replace '/', [System.IO.Path]::DirectorySeparatorChar)
}

function ConvertTo-AmdRepositoryRelativePath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]$Path
    )

    # Repository/publication paths are serialized with '/' regardless of the host OS.
    # This keeps manifests and cross-file references byte-stable between Windows and Linux.
    return (($Path -replace '\\', '/').TrimStart('/'))
}

function New-AmdZipFromDirectory {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$SourceDirectory,

        [Parameter(Mandatory = $true)]
        [string]$DestinationZip
    )

    if (Test-Path -LiteralPath $DestinationZip -PathType Leaf) {
        Remove-Item -LiteralPath $DestinationZip -Force -ErrorAction Stop
    }

    $parent = Split-Path -Parent $DestinationZip
    if ($parent) {
        New-AmdDirectory -Path $parent | Out-Null
    }

    # Do not rely on ZipFile.CreateFromDirectory / Compress-Archive here.
    # Windows PowerShell / .NET Framework can persist backslashes in ZIP entry
    # names. The archive remains readable by Windows, but common Linux unzip
    # tools warn and may return a non-zero exit code. Evidence bundles are
    # intentionally cross-platform, so create entries explicitly and normalize
    # every ZIP entry name to the ZIP-standard forward slash separator.
    Add-Type -AssemblyName 'System.IO.Compression' -ErrorAction SilentlyContinue
    Add-Type -AssemblyName 'System.IO.Compression.FileSystem' -ErrorAction SilentlyContinue

    $sourceFull = [System.IO.Path]::GetFullPath($SourceDirectory)
    $fileStream = $null
    $archive = $null

    try {
        $fileStream = [System.IO.File]::Open(
            $DestinationZip,
            [System.IO.FileMode]::CreateNew,
            [System.IO.FileAccess]::ReadWrite,
            [System.IO.FileShare]::None
        )
        $archive = New-Object -TypeName System.IO.Compression.ZipArchive -ArgumentList @(
            $fileStream,
            [System.IO.Compression.ZipArchiveMode]::Create,
            $false
        )

        $files = @(Get-ChildItem -LiteralPath $sourceFull -File -Recurse -Force -ErrorAction Stop)
        foreach ($file in $files) {
            $relative = Get-AmdRelativePath -BasePath $sourceFull -Path $file.FullName
            $entryName = ($relative -replace '\\', '/').TrimStart('/')

            if ([string]::IsNullOrWhiteSpace($entryName)) {
                continue
            }

            $entry = $archive.CreateEntry(
                $entryName,
                [System.IO.Compression.CompressionLevel]::Optimal
            )

            try {
                $entry.LastWriteTime = [DateTimeOffset]$file.LastWriteTime
            }
            catch {
                # Timestamp preservation is best-effort and must not prevent
                # evidence creation on runtimes with narrower ZIP timestamp rules.
            }

            $input = $null
            $output = $null
            try {
                $input = [System.IO.File]::OpenRead($file.FullName)
                $output = $entry.Open()
                $input.CopyTo($output)
            }
            finally {
                if ($null -ne $output) { $output.Dispose() }
                if ($null -ne $input) { $input.Dispose() }
            }
        }
    }
    finally {
        if ($null -ne $archive) { $archive.Dispose() }
        if ($null -ne $fileStream) { $fileStream.Dispose() }
    }

    if (-not (Test-Path -LiteralPath $DestinationZip -PathType Leaf)) {
        throw ('ZIP archive was not created: {0}' -f $DestinationZip)
    }

    return (Get-Item -LiteralPath $DestinationZip)
}

function Test-AmdEvidenceArchiveCapability {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$EvidenceDirectory
    )

    $probeRoot = Join-Path $EvidenceDirectory '_archive-probe'
    $probeZip = Join-Path $EvidenceDirectory '_archive-probe.zip'
    $result = [ordered]@{
        CollectedAtUtc = Get-AmdUtcTimestamp
        ProbeAttempted = $false
        ProbeSucceeded = $false
        ProbeArchiveBytes = 0
        Error = $null
    }

    try {
        $result.ProbeAttempted = $true
        New-AmdDirectory -Path $probeRoot | Out-Null
        Write-AmdUtf8NoBom -Path (Join-Path $probeRoot 'probe.txt') -Text 'AMD research evidence archive probe.'
        $archive = New-AmdZipFromDirectory -SourceDirectory $probeRoot -DestinationZip $probeZip
        $result.ProbeSucceeded = $true
        $result.ProbeArchiveBytes = [int64]$archive.Length
    }
    catch {
        $result.Error = $_.Exception.Message
    }
    finally {
        Remove-Item -LiteralPath $probeRoot -Recurse -Force -ErrorAction SilentlyContinue
        Remove-Item -LiteralPath $probeZip -Force -ErrorAction SilentlyContinue
    }

    return [pscustomobject]$result
}

function Start-AmdResearchEvidenceSession {
    [CmdletBinding()]
    param(
        [string]$OutputRoot,
        [string]$Label,
        [Parameter(Mandatory = $true)]
        [object]$InvocationParameters
    )

    $toolRoot = Get-AmdResearchToolkitRoot
    if ([string]::IsNullOrWhiteSpace($OutputRoot)) {
        $OutputRoot = Join-Path (Get-AmdPrivateEvidenceRoot) 'runs'
    }

    New-AmdDirectory -Path $OutputRoot | Out-Null

    $platform = Get-AmdPlatformInfo
    $stamp = (Get-Date).ToUniversalTime().ToString('yyyyMMdd-HHmmss')
    $platformFragment = ConvertTo-AmdEvidenceSafeFragment -Value ([string]$platform.PlatformFamily)
    $labelFragment = ConvertTo-AmdEvidenceSafeFragment -Value $Label

    $baseName = if ($labelFragment) {
        'AmdChipsetDriverResearchEvidence_{0}_{1}_{2}' -f $stamp, $platformFragment, $labelFragment
    }
    else {
        'AmdChipsetDriverResearchEvidence_{0}_{1}' -f $stamp, $platformFragment
    }

    $evidenceDir = Join-Path $OutputRoot $baseName
    $zipPath = Join-Path $OutputRoot ($baseName + '.zip')
    New-AmdDirectory -Path $evidenceDir | Out-Null
    New-AmdDirectory -Path (Join-Path $evidenceDir 'logs') | Out-Null
    New-AmdDirectory -Path (Join-Path $evidenceDir 'errors') | Out-Null
    New-AmdDirectory -Path (Join-Path $evidenceDir 'snapshot') | Out-Null

    $scriptPath = $MyInvocation.ScriptName
    if ([string]::IsNullOrWhiteSpace($scriptPath)) {
        $scriptPath = $PSCommandPath
    }
    if ([string]::IsNullOrWhiteSpace($scriptPath)) {
        $scriptPath = Join-Path $toolRoot 'Invoke-AmdChipsetDriverResearch.ps1'
    }

    $scriptHash = $null
    try {
        if (Test-Path -LiteralPath $scriptPath -PathType Leaf) {
            $scriptHash = Get-AmdSha256 -Path $scriptPath
        }
    }
    catch {
        $scriptHash = $null
    }

    $context = [pscustomobject][ordered]@{
        SchemaVersion = $script:AmdChipsetResearchEvidenceSchemaVersion
        ToolkitVersion = $script:AmdChipsetResearchToolkitVersion
        RunId = $baseName
        StartedAtUtc = Get-AmdUtcTimestamp
        EvidenceDirectory = $evidenceDir
        ZipPath = $zipPath
        Platform = $platform
        PowerShellVersion = $PSVersionTable.PSVersion.ToString()
        PSEdition = if ($PSVersionTable.PSEdition) { [string]$PSVersionTable.PSEdition } else { 'Desktop' }
        ScriptPath = $scriptPath
        ScriptSha256 = $scriptHash
        InvocationParameters = $InvocationParameters
        ArchiveCapability = $null
        TranscriptPath = Join-Path (Join-Path $evidenceDir 'logs') 'console-transcript.txt'
        TranscriptStarted = $false
    }

    $script:AmdEvidenceContext = $context
    $context.ArchiveCapability = Test-AmdEvidenceArchiveCapability -EvidenceDirectory $evidenceDir

    Write-AmdJsonFile -Path (Join-Path $evidenceDir 'run-context.json') -Value $context
    Write-AmdJsonFile -Path (Join-Path $evidenceDir 'archive-capability.json') -Value $context.ArchiveCapability

    try {
        Start-Transcript -LiteralPath $context.TranscriptPath -Force -ErrorAction Stop | Out-Null
        $script:AmdTranscriptStarted = $true
        $context.TranscriptStarted = $true
    }
    catch {
        $script:AmdTranscriptStarted = $false
        $context.TranscriptStarted = $false
        Write-AmdUtf8NoBom -Path (Join-Path (Join-Path $evidenceDir 'logs') 'transcript-start-error.txt') -Text $_.Exception.ToString()
    }

    # Persist the post-attempt transcript state; the initial context is written before
    # Start-Transcript so transcript startup failures themselves can still be evidenced.
    Write-AmdJsonFile -Path (Join-Path $evidenceDir 'run-context.json') -Value $context

    return $context
}

function Write-AmdStageResultsEvidence {
    [CmdletBinding()]
    param()

    if ($null -eq $script:AmdEvidenceContext) {
        return
    }

    $payload = [pscustomobject][ordered]@{
        SchemaVersion = 'amd-chipset-driver-research-stage-results/1.0'
        ToolkitVersion = $script:AmdChipsetResearchToolkitVersion
        GeneratedAtUtc = Get-AmdUtcTimestamp
        StageCount = $script:AmdStageResults.Count
        Stages = @($script:AmdStageResults.ToArray())
    }

    Write-AmdJsonFile -Path (Join-Path $script:AmdEvidenceContext.EvidenceDirectory 'stage-results.json') -Value $payload
}

function Invoke-AmdTrackedStage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [scriptblock]$Body,

        [AllowNull()]
        [string]$BlockedReason
    )

    $script:AmdStageOrdinal++
    Write-AmdStageHeader -Name $Name -Ordinal $script:AmdStageOrdinal -Total $script:AmdResolvedStageCount

    $started = [DateTime]::UtcNow
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $status = if ([string]::IsNullOrWhiteSpace($BlockedReason)) { 'PASS' } else { 'BLOCKED' }
    $errorText = $null
    $errorFile = $null
    $output = $null

    try {
        if ($status -eq 'BLOCKED') {
            $errorText = $BlockedReason
            Write-AmdCaution ('Stage {0} blocked: {1}' -f $Name,$BlockedReason)
        }
        else {
            $output = & $Body
        }
    }
    catch {
        $status = 'FAIL'
        $errorText = $_.Exception.Message

        if ($null -ne $script:AmdEvidenceContext) {
            $safeName = ConvertTo-AmdEvidenceSafeFragment -Value $Name
            $errorFile = Join-Path (Join-Path $script:AmdEvidenceContext.EvidenceDirectory 'errors') ('stage-{0}.txt' -f $safeName)
            $detail = @(
                ('Stage      : {0}' -f $Name),
                ('OccurredUtc: {0}' -f (Get-AmdUtcTimestamp)),
                ('Exception  : {0}' -f $_.Exception.ToString()),
                ('ScriptStack: {0}' -f $_.ScriptStackTrace)
            ) -join [Environment]::NewLine
            Write-AmdUtf8NoBom -Path $errorFile -Text $detail
        }

        Write-AmdFail ('Stage {0} failed: {1}' -f $Name, $errorText)
    }
    finally {
        $sw.Stop()
        $entry = [pscustomobject][ordered]@{
            Name = $Name
            Status = $status
            StartedAtUtc = $started.ToString('o')
            CompletedAtUtc = Get-AmdUtcTimestamp
            DurationMilliseconds = [int64]$sw.ElapsedMilliseconds
            Error = $errorText
            ErrorEvidencePath = $errorFile
        }
        $script:AmdStageResults.Add($entry)
        Write-AmdStageResultsEvidence
        Write-AmdStageFooter -Name $Name -Status $status -Elapsed $sw.Elapsed
    }

    return [pscustomobject][ordered]@{
        Success = ($status -eq 'PASS')
        Output = $output
        Error = $errorText
    }
}



function Get-AmdStageResultEntry {
    [CmdletBinding()]
    param([Parameter(Mandatory=$true)][string]$Name)

    $matches = @($script:AmdStageResults.ToArray() | Where-Object { $_.Name -eq $Name })
    if ($matches.Count -eq 0) { return $null }
    return $matches[$matches.Count - 1]
}

function Test-AmdStagePassedCurrentRun {
    [CmdletBinding()]
    param([Parameter(Mandatory=$true)][string]$Name)

    $entry = Get-AmdStageResultEntry -Name $Name
    return ($null -ne $entry -and [string]$entry.Status -eq 'PASS')
}

function Get-AmdStageDependencyBlockReason {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][string]$Name,
        [Parameter(Mandatory=$true)][string[]]$ResolvedStages
    )

    $dependencies = @{
        Metadata = @('Discover')
        Acquire = @('Metadata')
        Extract = @('Acquire')
        Inspect = @('Extract')
        Selector = @('Inspect')
        HostMatch = @('HostSurvey','Selector')
        Build = @('Inspect','Selector')
    }

    if (-not $dependencies.ContainsKey($Name)) { return $null }

    foreach ($dependency in @($dependencies[$Name])) {
        if ($ResolvedStages -notcontains $dependency) { continue }
        $entry = Get-AmdStageResultEntry -Name $dependency
        if ($null -eq $entry) { continue }
        if ([string]$entry.Status -ne 'PASS') {
            return ('Blocked because prerequisite stage {0} ended with status {1}.' -f $dependency,[string]$entry.Status)
        }
    }
    return $null
}

function Copy-AmdEvidenceTree {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Source,

        [Parameter(Mandatory = $true)]
        [string]$Destination,

        [string[]]$ExcludeDirectoryNames = @()
    )

    if (-not (Test-Path -LiteralPath $Source -PathType Container)) {
        return
    }

    New-AmdDirectory -Path $Destination | Out-Null

    foreach ($file in @(Get-ChildItem -LiteralPath $Source -File -Recurse -Force -ErrorAction SilentlyContinue)) {
        $relative = Get-AmdRelativePath -BasePath $Source -Path $file.FullName
        $segments = @($relative -split '[\\/]')
        $skip = $false
        foreach ($segment in $segments) {
            if ($ExcludeDirectoryNames -contains $segment) {
                $skip = $true
                break
            }
        }
        if ($skip) {
            continue
        }

        $target = Join-Path $Destination $relative
        $parent = Split-Path -Parent $target
        if ($parent) {
            New-AmdDirectory -Path $parent | Out-Null
        }
        Copy-Item -LiteralPath $file.FullName -Destination $target -Force
    }
}

function Get-AmdMsiDeclarativeEvidenceQuality {
    [CmdletBinding()]
    param([AllowNull()][object]$MsiDeclarativeAnalysis)

    if ($null -eq $MsiDeclarativeAnalysis) {
        return [pscustomobject][ordered]@{
            TableCount = 0
            TotalRowCount = 0
            AllNullRowCount = 0
        }
    }

    $qualityProperty = $MsiDeclarativeAnalysis.PSObject.Properties['Quality']
    if ($null -ne $qualityProperty -and $null -ne $qualityProperty.Value) {
        $quality = $qualityProperty.Value
        $tableCount = 0
        $totalRowCount = 0
        $allNullRowCount = 0
        if ($null -ne $quality.PSObject.Properties['TableCount']) { $tableCount = [int]$quality.TableCount }
        if ($null -ne $quality.PSObject.Properties['TotalRowCount']) { $totalRowCount = [int]$quality.TotalRowCount }
        if ($null -ne $quality.PSObject.Properties['AllNullRowCount']) { $allNullRowCount = [int]$quality.AllNullRowCount }
        return [pscustomobject][ordered]@{
            TableCount = $tableCount
            TotalRowCount = $totalRowCount
            AllNullRowCount = $allNullRowCount
        }
    }

    $tableCount = 0
    $totalRowCount = 0
    $allNullRowCount = 0
    $tablesProperty = $MsiDeclarativeAnalysis.PSObject.Properties['Tables']
    if ($null -ne $tablesProperty -and $null -ne $tablesProperty.Value) {
        foreach ($tableProperty in @($tablesProperty.Value.PSObject.Properties)) {
            $tableCount++
            foreach ($row in @($tableProperty.Value)) {
                $totalRowCount++
                if ($null -eq $row) {
                    $allNullRowCount++
                    continue
                }

                $properties = @($row.PSObject.Properties)
                if ($properties.Count -eq 0) {
                    $allNullRowCount++
                    continue
                }

                $hasValue = $false
                foreach ($property in $properties) {
                    if ($null -ne $property.Value -and -not [string]::IsNullOrEmpty([string]$property.Value)) {
                        $hasValue = $true
                        break
                    }
                }
                if (-not $hasValue) { $allNullRowCount++ }
            }
        }
    }

    return [pscustomobject][ordered]@{
        TableCount = $tableCount
        TotalRowCount = $totalRowCount
        AllNullRowCount = $allNullRowCount
    }
}

function Get-AmdMsiDeclarativeAssessmentFromReleases {
    [CmdletBinding()]
    param([AllowNull()][object[]]$Releases)

    $all = @($Releases)
    $successStatuses = @('Parsed','ParsedReadOnly')
    $parsed = @($all | Where-Object { $_.MsiDeclarativeAnalysis -and [string]$_.MsiDeclarativeAnalysis.Status -in $successStatuses })
    $parseFailed = @($all | Where-Object { $_.MsiDeclarativeAnalysis -and [string]$_.MsiDeclarativeAnalysis.Status -eq 'ParseFailed' })
    $parsedWithErrors = @($all | Where-Object { $_.MsiDeclarativeAnalysis -and [string]$_.MsiDeclarativeAnalysis.Status -eq 'ParsedWithErrors' })
    $notRecovered = @($all | Where-Object { $_.MsiDeclarativeAnalysis -and [string]$_.MsiDeclarativeAnalysis.Status -eq 'MsiNotRecovered' })
    $platformUnavailable = @($all | Where-Object { $_.MsiDeclarativeAnalysis -and [string]$_.MsiDeclarativeAnalysis.Status -eq 'WindowsInstallerComUnavailableOnPlatform' })
    $knownStatuses = @($successStatuses + @('ParseFailed','ParsedWithErrors','MsiNotRecovered','WindowsInstallerComUnavailableOnPlatform'))
    $unknown = @($all | Where-Object { $_.MsiDeclarativeAnalysis -and [string]$_.MsiDeclarativeAnalysis.Status -notin $knownStatuses })
    $missing = @($all | Where-Object { -not $_.MsiDeclarativeAnalysis })

    $qualityIssueReleaseCount = 0
    $allNullRowCount = 0
    foreach ($release in $parsed) {
        $quality = Get-AmdMsiDeclarativeEvidenceQuality -MsiDeclarativeAnalysis $release.MsiDeclarativeAnalysis
        $allNullRowCount += [int]$quality.AllNullRowCount
        if ([int]$quality.AllNullRowCount -gt 0) { $qualityIssueReleaseCount++ }
    }

    $reviewCount = $parseFailed.Count + $parsedWithErrors.Count + $notRecovered.Count + $unknown.Count + $missing.Count + $qualityIssueReleaseCount
    $allPlatformUnavailable = ($all.Count -gt 0 -and $platformUnavailable.Count -eq $all.Count)
    $hasSuccessfulParse = ($parsed.Count -gt 0)
    $status = if ($reviewCount -eq 0 -and ($hasSuccessfulParse -or $allPlatformUnavailable)) { 'PASS' } else { 'REVIEW' }

    $detail = if ($status -eq 'PASS') {
        if ($allPlatformUnavailable) {
            ('MSI declarative analysis is unavailable on this platform for all {0} release(s), as expected.' -f $all.Count)
        }
        else {
            ('MSI declarative analysis parsed {0}/{1} release(s) successfully (platform-unavailable={2}; all-null-rows={3}).' -f $parsed.Count,$all.Count,$platformUnavailable.Count,$allNullRowCount)
        }
    }
    else {
        ('MSI declarative analysis requires review: parsed={0}; parse-failed={1}; parsed-with-errors={2}; not-recovered={3}; platform-unavailable={4}; unknown={5}; missing={6}; quality-issue-releases={7}; all-null-rows={8}' -f $parsed.Count,$parseFailed.Count,$parsedWithErrors.Count,$notRecovered.Count,$platformUnavailable.Count,$unknown.Count,$missing.Count,$qualityIssueReleaseCount,$allNullRowCount)
    }

    return [pscustomobject][ordered]@{
        Name = 'MsiDeclarativeInspection'
        Status = $status
        Detail = $detail
        ParsedCount = $parsed.Count
        ParseFailedCount = $parseFailed.Count
        ParsedWithErrorsCount = $parsedWithErrors.Count
        MsiNotRecoveredCount = $notRecovered.Count
        PlatformUnavailableCount = $platformUnavailable.Count
        UnknownStatusCount = $unknown.Count
        MissingAnalysisCount = $missing.Count
        QualityIssueReleaseCount = $qualityIssueReleaseCount
        AllNullRowCount = $allNullRowCount
    }
}

function Test-AmdMsiDeclarativeAssessmentSelfTest {
    [CmdletBinding()]
    param()

    $passCase = @(
        [pscustomobject]@{ MsiDeclarativeAnalysis=[pscustomobject]@{Status='ParsedReadOnly'} },
        [pscustomobject]@{ MsiDeclarativeAnalysis=[pscustomobject]@{Status='Parsed'} }
    )
    $platformCase = @(
        [pscustomobject]@{ MsiDeclarativeAnalysis=[pscustomobject]@{Status='WindowsInstallerComUnavailableOnPlatform'} },
        [pscustomobject]@{ MsiDeclarativeAnalysis=[pscustomobject]@{Status='WindowsInstallerComUnavailableOnPlatform'} }
    )
    $failureCase = @(
        [pscustomobject]@{ MsiDeclarativeAnalysis=[pscustomobject]@{Status='ParsedReadOnly'} },
        [pscustomobject]@{ MsiDeclarativeAnalysis=[pscustomobject]@{Status='ParseFailed'} }
    )
    $partialCase = @(
        [pscustomobject]@{ MsiDeclarativeAnalysis=[pscustomobject]@{Status='ParsedReadOnly'} },
        [pscustomobject]@{ MsiDeclarativeAnalysis=[pscustomobject]@{Status='ParsedWithErrors'} },
        [pscustomobject]@{ MsiDeclarativeAnalysis=[pscustomobject]@{Status='MsiNotRecovered'} }
    )
    $contaminatedCase = @(
        [pscustomobject]@{ MsiDeclarativeAnalysis=[pscustomobject]@{Status='ParsedReadOnly';Quality=[pscustomobject]@{TableCount=1;TotalRowCount=3;AllNullRowCount=1}} }
    )
    $passResult = Get-AmdMsiDeclarativeAssessmentFromReleases -Releases $passCase
    $platformResult = Get-AmdMsiDeclarativeAssessmentFromReleases -Releases $platformCase
    $failureResult = Get-AmdMsiDeclarativeAssessmentFromReleases -Releases $failureCase
    $partialResult = Get-AmdMsiDeclarativeAssessmentFromReleases -Releases $partialCase
    $contaminatedResult = Get-AmdMsiDeclarativeAssessmentFromReleases -Releases $contaminatedCase
    $ok = (
        $passResult.Status -eq 'PASS' -and $passResult.ParsedCount -eq 2 -and $passResult.AllNullRowCount -eq 0 -and
        $platformResult.Status -eq 'PASS' -and $platformResult.PlatformUnavailableCount -eq 2 -and
        $failureResult.Status -eq 'REVIEW' -and $failureResult.ParseFailedCount -eq 1 -and
        $partialResult.Status -eq 'REVIEW' -and $partialResult.ParsedWithErrorsCount -eq 1 -and $partialResult.MsiNotRecoveredCount -eq 1 -and
        $contaminatedResult.Status -eq 'REVIEW' -and $contaminatedResult.QualityIssueReleaseCount -eq 1 -and $contaminatedResult.AllNullRowCount -eq 1
    )
    return [pscustomobject][ordered]@{
        Status = if ($ok) { 'Pass' } else { 'Fail' }
        PassCaseStatus = $passResult.Status
        PassCaseParsedCount = $passResult.ParsedCount
        PlatformCaseStatus = $platformResult.Status
        FailureCaseStatus = $failureResult.Status
        FailureCaseParseFailedCount = $failureResult.ParseFailedCount
        PartialCaseStatus = $partialResult.Status
        PartialCaseParsedWithErrorsCount = $partialResult.ParsedWithErrorsCount
        PartialCaseNotRecoveredCount = $partialResult.MsiNotRecoveredCount
        ContaminatedCaseStatus = $contaminatedResult.Status
        ContaminatedCaseQualityIssueReleaseCount = $contaminatedResult.QualityIssueReleaseCount
        ContaminatedCaseAllNullRowCount = $contaminatedResult.AllNullRowCount
    }
}

function Restore-AmdRuntimeBaselineFromPublic {
    [CmdletBinding()]
    param()

    $root = Get-AmdResearchToolkitRoot
    $publicInventory = Join-Path (Get-AmdPublicOutputRoot) 'inventory'
    $runtimeInventory = Join-Path $root 'inventory'
    if (-not (Test-Path -LiteralPath $publicInventory -PathType Container)) { return }
    New-AmdDirectory -Path $runtimeInventory | Out-Null

    # Lightweight aggregate files are deterministically generated from canonical public per-release Raw JSON.
    foreach ($name in @('releases.json','release-metadata.json','acquisition.json','extraction.json','embedded-installer-metadata.json','amd-selector-static.json','amd-chipset-driver-inventory.csv','amd-chipset-windows-server-compatibility.csv')) {
        $src = Join-Path $publicInventory $name
        $dst = Join-Path $runtimeInventory $name
        if ((Test-Path -LiteralPath $src -PathType Leaf) -and -not (Test-Path -LiteralPath $dst -PathType Leaf)) {
            Copy-Item -LiteralPath $src -Destination $dst -Force
        }
    }
    $srcReleases = Join-Path $publicInventory 'releases'
    $dstReleases = Join-Path $runtimeInventory 'releases'
    if ((Test-Path -LiteralPath $srcReleases -PathType Container) -and -not (Test-Path -LiteralPath $dstReleases -PathType Container)) {
        Copy-AmdEvidenceTree -Source $srcReleases -Destination $dstReleases
    }

    # The monolithic DriverPackages aggregate is intentionally not a public Git artifact because it can exceed
    # normal GitHub file-size limits. Reconstruct it locally from the canonical per-release Raw JSON when needed.
    $driverPackagesPath = Join-Path $runtimeInventory 'driver-packages.json'
    if (-not (Test-Path -LiteralPath $driverPackagesPath -PathType Leaf) -and (Test-Path -LiteralPath $srcReleases -PathType Container)) {
        $drivers = New-Object 'System.Collections.Generic.List[object]'
        foreach ($file in @(Get-ChildItem -LiteralPath $srcReleases -Filter 'amd-chipset-analysis-*.json' -File -Recurse -Force | Sort-Object FullName)) {
            $doc = Read-AmdJsonFile -Path $file.FullName
            foreach ($driver in @(Get-AmdCollectionItems -Value $doc.DriverPackages)) { $drivers.Add($driver) }
        }
        if ($drivers.Count -gt 0) {
            Write-AmdJsonFile -Path $driverPackagesPath -Value ([pscustomobject][ordered]@{
                SchemaVersion='2.0';ToolkitVersion=$script:AmdChipsetResearchToolkitVersion;GeneratedAtUtc=Get-AmdUtcTimestamp
                Purpose='RuntimeBaselineReconstructedFromPublicPerReleaseRawJson';DriverPackageCount=$drivers.Count;DriverPackages=@($drivers.ToArray())
            }) -Compress
        }
    }
}

function Get-AmdPublicForbiddenPatterns {
    [CmdletBinding()]
    param()

    $patterns = New-Object 'System.Collections.Generic.List[string]'
    foreach ($pattern in @('(?i)/(?:home|mnt/data|tmp|var/tmp)/','(?i)[A-Z]:\\Users\\')) { $patterns.Add($pattern) }
    foreach ($candidate in @((Get-AmdResearchToolkitRoot),(Get-AmdPrivateEvidenceRoot),$HOME,$env:USERPROFILE,$env:TEMP,$env:TMP)) {
        if (-not [string]::IsNullOrWhiteSpace([string]$candidate)) {
            $patterns.Add([regex]::Escape(([string]$candidate).TrimEnd('\','/')))
        }
    }
    return @($patterns.ToArray())
}

function Get-AmdPublicScalarStrings {
    [CmdletBinding()]
    param([AllowNull()]$Value)

    $results = New-Object 'System.Collections.Generic.List[string]'
    $stack = New-Object System.Collections.Stack
    $stack.Push($Value)

    while ($stack.Count -gt 0) {
        $current = $stack.Pop()
        if ($null -eq $current) { continue }
        if ($current -is [string]) {
            $results.Add([string]$current)
            continue
        }
        if ($current -is [System.Collections.IDictionary]) {
            foreach ($key in @($current.Keys)) { $stack.Push($current[$key]) }
            continue
        }
        if ($current -is [System.Management.Automation.PSCustomObject]) {
            foreach ($property in @($current.PSObject.Properties)) { $stack.Push($property.Value) }
            continue
        }
        if ($current -is [System.Collections.IEnumerable]) {
            foreach ($item in @($current)) { $stack.Push($item) }
        }
    }
    return @($results.ToArray())
}

function Test-AmdPublicRepositorySurface {
    [CmdletBinding()]
    param([Parameter(Mandatory=$true)][string]$Root)

    $errors = New-Object 'System.Collections.Generic.List[string]'
    $allowedExtensions = @('.json','.csv','.md','.txt')
    $forbiddenPatterns = @(Get-AmdPublicForbiddenPatterns)
    if (-not (Test-Path -LiteralPath $Root -PathType Container)) {
        $errors.Add(('public root is missing: {0}' -f $Root))
    }

    foreach ($file in @(Get-ChildItem -LiteralPath $Root -File -Recurse -Force -ErrorAction SilentlyContinue)) {
        $relative = ConvertTo-AmdRepositoryRelativePath -Path (Get-AmdRelativePath -BasePath $Root -Path $file.FullName)
        if ($file.Extension -notin $allowedExtensions) {
            $errors.Add(('non-public file type found: {0}' -f $relative))
            continue
        }
        try { $text = Read-AmdTextFile -Path $file.FullName }
        catch { $errors.Add(('unable to read public file: {0}' -f $relative)); continue }

        # JSON must be inspected after parsing. On Windows, JSON serialisation escapes '\\' as '\\\\';
        # scanning the serialised text can therefore miss a real private path even though the decoded
        # scalar contains the exact runtime path. Non-JSON text is inspected directly.
        if ($file.Extension -eq '.json') {
            try {
                $json = Read-AmdJsonFile -Path $file.FullName
                $aggregateRelativePaths = @(
                    'inventory/release-index.json','inventory/releases.json','inventory/release-metadata.json','inventory/acquisition.json',
                    'inventory/extraction.json','inventory/embedded-installer-metadata.json','inventory/amd-selector-static.json'
                )
                if ($relative -in $aggregateRelativePaths) {
                    foreach ($wrapperPath in @(Get-AmdPowerShell51CollectionWrapperPaths -Value $json)) {
                        $errors.Add(('PowerShell 5.1 collection wrapper remains in public aggregate {0} at {1}' -f $relative,$wrapperPath))
                    }
                }
                if ($relative -eq 'inventory/amd-selector-static.json') {
                    $selectorShape = Test-AmdSelectorStaticAggregateShape -Value $json
                    foreach ($selectorShapeError in @($selectorShape.Errors)) {
                        $errors.Add(('selector aggregate shape: {0}' -f $selectorShapeError))
                    }
                }
                foreach ($scalar in @(Get-AmdPublicScalarStrings -Value $json)) {
                    foreach ($pattern in $forbiddenPatterns) {
                        if ($scalar -match $pattern) {
                            $errors.Add(('private/runtime path pattern found in JSON scalar: {0}' -f $relative))
                            break
                        }
                    }
                }
            }
            catch { $errors.Add(('invalid JSON in public file: {0}' -f $relative)) }
        }
        else {
            foreach ($pattern in $forbiddenPatterns) {
                if ($text -match $pattern) { $errors.Add(('private/runtime path pattern found in {0}' -f $relative)); break }
            }
        }

        # Regression guard for Claude F-01. These are vendor tokens, never path placeholders.
        if ($text -match '(?i)external-path/(?:SET[A-Z0-9.]+|info\.xml|DevID\.xml)') {
            $errors.Add(('vendor selector/XML token was path-normalized in {0}' -f $relative))
        }
        if ($file.Extension -eq '.md') {
            $bytes = [System.IO.File]::ReadAllBytes($file.FullName)
            if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) { $errors.Add(('UTF-8 BOM found in public Markdown: {0}' -f $relative)) }
            if ($text.Contains("`r")) { $errors.Add(('CR/CRLF line ending found in public Markdown: {0}' -f $relative)) }
        }
    }

    return [pscustomobject][ordered]@{
        SchemaVersion = 'amd-chipset-publication-validation/1.0'
        ToolkitVersion = $script:AmdChipsetResearchToolkitVersion
        GeneratedAtUtc = Get-AmdUtcTimestamp
        Status = if ($errors.Count -eq 0) { 'Pass' } else { 'Fail' }
        ErrorCount = $errors.Count
        Errors = @($errors.ToArray())
        Policy = 'public/** is the only generated repository-publication surface; JSON privacy validation is performed on decoded scalar values and publication is fail-closed.'
    }
}

function New-AmdPublicDatasetIndexes {
    [CmdletBinding()]
    param([Parameter(Mandatory=$true)][string]$PublicInventoryRoot)

    $releaseRoot = Join-Path $PublicInventoryRoot 'releases'
    $releaseEntries = New-Object 'System.Collections.Generic.List[object]'
    $discoveryEntries = New-Object 'System.Collections.Generic.List[object]'
    $metadataEntries = New-Object 'System.Collections.Generic.List[object]'
    $acquisitionEntries = New-Object 'System.Collections.Generic.List[object]'
    $extractionEntries = New-Object 'System.Collections.Generic.List[object]'
    $embeddedEntries = New-Object 'System.Collections.Generic.List[object]'
    $selectorEntries = New-Object 'System.Collections.Generic.List[object]'

    if (Test-Path -LiteralPath $releaseRoot -PathType Container) {
        foreach ($file in @(Get-ChildItem -LiteralPath $releaseRoot -Filter 'amd-chipset-analysis-*.json' -File -Recurse -Force | Sort-Object FullName)) {
            $doc = Read-AmdJsonFile -Path $file.FullName
            $version = [string]$doc.Release.Version
            $releaseEntries.Add([pscustomobject][ordered]@{
                ReleaseVersion = $version
                AnalysisFile = ConvertTo-AmdRepositoryRelativePath -Path (Get-AmdRelativePath -BasePath $PublicInventoryRoot -Path $file.FullName)
                AnalysisSha256 = Get-AmdSha256 -Path $file.FullName
                DriverPackageCount = @($doc.DriverPackages).Count
                ProductRecordCount = if ($doc.Release.EmbeddedInstallerMetadata) { [int]$doc.Release.EmbeddedInstallerMetadata.ProductCount } else { 0 }
                DevIdRuleCount = if ($doc.Release.AmdSelectorStatic) { [int]$doc.Release.AmdSelectorStatic.DevIdRuleCount } else { 0 }
            })
            if ($doc.Release.Discovery) { $discoveryEntries.Add($doc.Release.Discovery) }
            if ($doc.Release.Metadata) { $metadataEntries.Add($doc.Release.Metadata) }
            if ($doc.Release.Acquisition) { $acquisitionEntries.Add($doc.Release.Acquisition) }
            if ($doc.Release.Extraction) { $extractionEntries.Add($doc.Release.Extraction) }
            if ($doc.Release.EmbeddedInstallerMetadata) { $embeddedEntries.Add($doc.Release.EmbeddedInstallerMetadata) }
            if ($doc.Release.AmdSelectorStatic) { $selectorEntries.Add($doc.Release.AmdSelectorStatic) }
        }
    }

    Write-AmdCanonicalPublicAggregateJsonFile -Path (Join-Path $PublicInventoryRoot 'release-index.json') -Value ([pscustomobject][ordered]@{
        SchemaVersion='amd-chipset-public-release-index/1.0';ToolkitVersion=$script:AmdChipsetResearchToolkitVersion;GeneratedAtUtc=Get-AmdUtcTimestamp
        CanonicalRawData='inventory/releases/**/amd-chipset-analysis-*.json';ReleaseCount=$releaseEntries.Count;Releases=@($releaseEntries.ToArray())
    }) -Compress
    Write-AmdCanonicalPublicAggregateJsonFile -Path (Join-Path $PublicInventoryRoot 'releases.json') -Value ([pscustomobject][ordered]@{
        SchemaVersion='1.0';ToolkitVersion=$script:AmdChipsetResearchToolkitVersion;GeneratedAtUtc=Get-AmdUtcTimestamp
        Completeness='CanonicalPublicDatasetDerivedFromPerReleaseRawJson';ReleaseCount=$discoveryEntries.Count;Releases=@($discoveryEntries.ToArray())
    }) -Compress
    Write-AmdCanonicalPublicAggregateJsonFile -Path (Join-Path $PublicInventoryRoot 'release-metadata.json') -Value ([pscustomobject][ordered]@{
        SchemaVersion='1.0';ToolkitVersion=$script:AmdChipsetResearchToolkitVersion;GeneratedAtUtc=Get-AmdUtcTimestamp;Releases=@($metadataEntries.ToArray())
    }) -Compress
    Write-AmdCanonicalPublicAggregateJsonFile -Path (Join-Path $PublicInventoryRoot 'acquisition.json') -Value ([pscustomobject][ordered]@{
        SchemaVersion='1.0';ToolkitVersion=$script:AmdChipsetResearchToolkitVersion;GeneratedAtUtc=Get-AmdUtcTimestamp;Artifacts=@($acquisitionEntries.ToArray())
    }) -Compress
    Write-AmdCanonicalPublicAggregateJsonFile -Path (Join-Path $PublicInventoryRoot 'extraction.json') -Value ([pscustomobject][ordered]@{
        SchemaVersion='2.0';ToolkitVersion=$script:AmdChipsetResearchToolkitVersion;GeneratedAtUtc=Get-AmdUtcTimestamp
        Purpose='CanonicalPublicExtractionEvidenceDerivedFromPerReleaseRawJson';Releases=@($extractionEntries.ToArray())
    }) -Compress
    Write-AmdCanonicalPublicAggregateJsonFile -Path (Join-Path $PublicInventoryRoot 'embedded-installer-metadata.json') -Value ([pscustomobject][ordered]@{
        SchemaVersion='1.1';ToolkitVersion=$script:AmdChipsetResearchToolkitVersion;GeneratedAtUtc=Get-AmdUtcTimestamp
        Purpose='CanonicalPublicEmbeddedInstallerMetadataDerivedFromPerReleaseRawJson';Releases=@($embeddedEntries.ToArray())
    }) -Compress
    Write-AmdCanonicalPublicAggregateJsonFile -Path (Join-Path $PublicInventoryRoot 'amd-selector-static.json') -Value ([pscustomobject][ordered]@{
        SchemaVersion='amd-chipset-selector-static/1.2';ToolkitVersion=$script:AmdChipsetResearchToolkitVersion;GeneratedAtUtc=Get-AmdUtcTimestamp
        AnalysisBoundary='Generated deterministically from canonical per-release public Raw JSON. No value-level publication normalization is applied.'
        Releases=@($selectorEntries.ToArray())
    }) -Compress
}

function Test-AmdPublicationContractSelfTest {
    [CmdletBinding()]
    param()

    # Keep this self-test independently callable after dot-sourcing function definitions.
    # Normal script execution initializes these script-scope values before any stage runs,
    # but isolated diagnostics and third-party review may intentionally skip that bootstrap.
    $createdToolkitRootVariable = $false
    $createdToolkitVersionVariable = $false
    $toolkitRootVariable = Get-Variable -Name 'AmdChipsetResearchToolkitRoot' -Scope Script -ErrorAction SilentlyContinue
    $toolkitVersionVariable = Get-Variable -Name 'AmdChipsetResearchToolkitVersion' -Scope Script -ErrorAction SilentlyContinue
    if ($null -eq $toolkitRootVariable -or [string]::IsNullOrWhiteSpace([string]$toolkitRootVariable.Value)) {
        $script:AmdChipsetResearchToolkitRoot = Join-Path ([System.IO.Path]::GetTempPath()) 'amd-chipset-public-selftest-toolroot'
        $createdToolkitRootVariable = $true
    }
    if ($null -eq $toolkitVersionVariable -or [string]::IsNullOrWhiteSpace([string]$toolkitVersionVariable.Value)) {
        $script:AmdChipsetResearchToolkitVersion = 'publication-contract-selftest'
        $createdToolkitVersionVariable = $true
    }

    $root = Join-Path ([System.IO.Path]::GetTempPath()) ('amd-chipset-public-selftest-{0}' -f ([guid]::NewGuid().ToString('N')))
    try {
        New-AmdDirectory -Path $root | Out-Null
        Write-AmdJsonFile -Path (Join-Path $root 'safe.json') -Value ([pscustomobject][ordered]@{ Candidate='/SETFILTERUSB'; ManifestPath='/info.xml'; Value='C:\' })
        $safe = Test-AmdPublicRepositorySurface -Root $root

        # This value is deliberately written through JSON so Windows backslashes are escaped in
        # the file. The validator must parse JSON and inspect the decoded scalar, not the raw text.
        $runtimePrivatePath = Join-Path (Get-AmdResearchToolkitRoot) 'work'
        Write-AmdJsonFile -Path (Join-Path $root 'private.json') -Value ([pscustomobject][ordered]@{ RuntimePath=$runtimePrivatePath; WindowsRuntimePath='C:\Users\SensitiveUser\AppData\Local\Temp\amd-private' })
        $blocked = Test-AmdPublicRepositorySurface -Root $root

        $repositoryRelative = ConvertTo-AmdRepositoryRelativePath -Path 'inventory\releases\8.07.16.1035\amd-chipset-analysis-8.07.16.1035.json'
        $repositoryPathContract = ($repositoryRelative -eq 'inventory/releases/8.07.16.1035/amd-chipset-analysis-8.07.16.1035.json' -and $repositoryRelative -like 'inventory/releases/*')

        $wrappedCollection = [pscustomobject][ordered]@{ value=@([pscustomobject]@{ Profile=[pscustomobject]@{ Id='windows-server-2025' } }); Count=1 }
        $unwrappedCollection = @(Get-AmdCollectionItems -Value $wrappedCollection)
        $collectionWrapperContract = ($unwrappedCollection.Count -eq 1 -and $unwrappedCollection[0].Profile.Id -eq 'windows-server-2025')

        $nestedWrappedSelector = [pscustomobject][ordered]@{
            ReleaseVersion='selftest';DevIdRuleCount=1
            DevIdRules=[pscustomobject][ordered]@{value=@([pscustomobject][ordered]@{DeviceIds=[pscustomobject][ordered]@{value=@('DEV_790B');Count=1}});Count=1}
            Notes=[pscustomobject][ordered]@{value=@('note');Count=1}
            SelectorBinaryEvidence=[pscustomobject][ordered]@{
                StringEvidence=[pscustomobject][ordered]@{value=@('/SETFILTERUSB');Count=1}
                UnicodeStringEvidence=[pscustomobject][ordered]@{value=@();Count=0}
                Notes=[pscustomobject][ordered]@{value=@('binary-note');Count=1}
                CompiledSelectorContract=[pscustomobject][ordered]@{ReverseEngineeringNotes=[pscustomobject][ordered]@{value=@('contract-note');Count=1}}
            }
            MsiDeclarativeAnalysis=$null
        }
        $canonicalSelector = ConvertTo-AmdCanonicalPublicAggregateValue -Value $nestedWrappedSelector
        $canonicalAggregate = [pscustomobject][ordered]@{SchemaVersion='amd-chipset-selector-static/1.2';ToolkitVersion='selftest';Releases=@($canonicalSelector)}
        $canonicalShape = Test-AmdSelectorStaticAggregateShape -Value $canonicalAggregate
        $canonicalWrapperPaths = @(Get-AmdPowerShell51CollectionWrapperPaths -Value $canonicalAggregate)
        $scalarDomainObject = [pscustomobject][ordered]@{ value='domain-value'; Count=1 }
        $scalarDomainCanonical = ConvertTo-AmdCanonicalPublicAggregateValue -Value $scalarDomainObject
        $scalarValueCountPreserved = (
            $scalarDomainCanonical -is [System.Management.Automation.PSCustomObject] -and
            [string]$scalarDomainCanonical.value -eq 'domain-value' -and [int]$scalarDomainCanonical.Count -eq 1
        )
        $aggregateCollectionContract = (
            $canonicalShape.Status -eq 'Pass' -and $canonicalWrapperPaths.Count -eq 0 -and
            @($canonicalSelector.DevIdRules).Count -eq 1 -and @($canonicalSelector.DevIdRules[0].DeviceIds).Count -eq 1 -and
            @($canonicalSelector.SelectorBinaryEvidence.StringEvidence).Count -eq 1 -and
            $canonicalSelector.SelectorBinaryEvidence.StringEvidence[0] -eq '/SETFILTERUSB' -and
            $scalarValueCountPreserved
        )

        $ok = ($safe.Status -eq 'Pass' -and $blocked.Status -eq 'Fail' -and @($blocked.Errors).Count -gt 0 -and $repositoryPathContract -and $collectionWrapperContract -and $aggregateCollectionContract)
        return [pscustomobject][ordered]@{
            Status=if($ok){'Pass'}else{'Fail'}
            SafeCase=$safe.Status
            PrivateLeakCase=$blocked.Status
            PrivateLeakErrorCount=@($blocked.Errors).Count
            JsonDecodedScalarValidation=$true
            SelectorTokenPreserved=$true
            RepositoryRelativePath=$repositoryRelative
            RepositoryPathContract=$repositoryPathContract
            PowerShell51CollectionWrapperRehydration=$collectionWrapperContract
            PublicAggregateCollectionCanonicalization=$aggregateCollectionContract
            SelectorAggregateShapeSelfTest=$canonicalShape.Status
            ScalarValueCountDomainObjectPreserved=$scalarValueCountPreserved
        }
    }
    finally {
        Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue
        if ($createdToolkitRootVariable) { Remove-Variable -Name 'AmdChipsetResearchToolkitRoot' -Scope Script -ErrorAction SilentlyContinue }
        if ($createdToolkitVersionVariable) { Remove-Variable -Name 'AmdChipsetResearchToolkitVersion' -Scope Script -ErrorAction SilentlyContinue }
    }
}

function Copy-AmdPublicMarkdownFile {
    [CmdletBinding()]
    param([Parameter(Mandatory=$true)][string]$Source,[Parameter(Mandatory=$true)][string]$Destination)

    $text = Read-AmdTextFile -Path $Source
    $text = $text.Replace("`r`n","`n").Replace("`r","`n")
    Write-AmdUtf8NoBom -Path $Destination -Text $text
}

function Publish-AmdRepositorySurface {
    [CmdletBinding()]
    param([Parameter(Mandatory=$true)][object]$CoreAssessment,[Parameter(Mandatory=$true)][string[]]$ResolvedStages)

    $root = Get-AmdResearchToolkitRoot
    $publicRoot = Get-AmdPublicOutputRoot

    # Never publish if the publication contract itself is not healthy. This check is repeated
    # here rather than trusting a prior Test stage so partial runs remain fail-closed as well.
    $publicationContractSelfTest = Test-AmdPublicationContractSelfTest
    if ([string]$publicationContractSelfTest.Status -ne 'Pass') {
        $validation = [pscustomobject][ordered]@{
            SchemaVersion='amd-chipset-publication-validation/1.0';ToolkitVersion=$script:AmdChipsetResearchToolkitVersion;GeneratedAtUtc=Get-AmdUtcTimestamp
            Status='Fail';ErrorCount=1;Errors=@('PublicationContract self-test failed; existing public baseline was preserved.')
            Policy='public/** publication is blocked when the publication contract self-test is not healthy.'
        }
        if ($script:AmdEvidenceContext) { Write-AmdJsonFile -Path (Join-Path $script:AmdEvidenceContext.EvidenceDirectory 'publication-validation-failed.json') -Value $validation }
        return [pscustomobject][ordered]@{Status='Fail';PublicRoot=$publicRoot;FileCount=0;Validation=$validation;Published=$false}
    }
    $staging = ('{0}.staging-{1}' -f $publicRoot,$PID)
    if (Test-Path -LiteralPath $staging -PathType Container) { Remove-Item -LiteralPath $staging -Recurse -Force }
    New-AmdDirectory -Path $staging | Out-Null

    # Partial runs preserve the previously validated public baseline and overlay only current-run outputs.
    if (Test-Path -LiteralPath $publicRoot -PathType Container) { Copy-AmdEvidenceTree -Source $publicRoot -Destination $staging }
    $pubInv = Join-Path $staging 'inventory'; $pubReports = Join-Path $staging 'reports'
    New-AmdDirectory -Path $pubInv | Out-Null; New-AmdDirectory -Path $pubReports | Out-Null
    $runtimeInventory = Join-Path $root 'inventory'; $runtimeReports = Join-Path $root 'reports'

    # Canonical Raw JSON: Build creates repository-portable per-release records using compact JSON
    # serialization at generation time. Publication copies those canonical files byte-for-byte.
    $runtimeReleases = Join-Path $runtimeInventory 'releases'
    if (Test-Path -LiteralPath $runtimeReleases -PathType Container) {
        Copy-AmdEvidenceTree -Source $runtimeReleases -Destination (Join-Path $pubInv 'releases')
    }
    foreach ($name in @('amd-chipset-driver-inventory.csv','amd-chipset-windows-server-compatibility.csv')) {
        $src = Join-Path $runtimeInventory $name
        if (Test-Path -LiteralPath $src -PathType Leaf) { Copy-Item -LiteralPath $src -Destination (Join-Path $pubInv $name) -Force }
    }
    foreach ($name in @('amd-chipset-driver-history.md','amd-chipset-windows-server-compatibility.md')) {
        $src = Join-Path $runtimeReports $name
        if (Test-Path -LiteralPath $src -PathType Leaf) { Copy-AmdPublicMarkdownFile -Source $src -Destination (Join-Path $pubReports $name) }
    }
    $runtimeReleaseReports = Join-Path $runtimeReports 'releases'
    if (Test-Path -LiteralPath $runtimeReleaseReports -PathType Container) {
        $dstReleaseReports = Join-Path $pubReports 'releases'; New-AmdDirectory -Path $dstReleaseReports | Out-Null
        foreach ($file in @(Get-ChildItem -LiteralPath $runtimeReleaseReports -Filter '*.md' -File -Recurse -Force)) {
            $relative = Get-AmdRelativePath -BasePath $runtimeReleaseReports -Path $file.FullName
            Copy-AmdPublicMarkdownFile -Source $file.FullName -Destination (Join-Path $dstReleaseReports $relative)
        }
    }

    New-AmdPublicDatasetIndexes -PublicInventoryRoot $pubInv

    $runSummary = [pscustomobject][ordered]@{
        SchemaVersion='amd-chipset-public-run-summary/1.0';ToolkitVersion=$script:AmdChipsetResearchToolkitVersion;GeneratedAtUtc=Get-AmdUtcTimestamp
        OverallStatus=$CoreAssessment.OverallStatus;ExitCode=$CoreAssessment.ExitCode;SelectedStages=@($ResolvedStages)
        ScriptSha256=if($script:AmdEvidenceContext){$script:AmdEvidenceContext.ScriptSha256}else{$null}
        PublicationContract=[pscustomobject][ordered]@{
            Classification='PublicRepositoryArtifact';AutoCommitAllowList='public/**';CanonicalRawData='public/inventory/releases/**/amd-chipset-analysis-*.json'
            HandEditingAllowed=$false;PrivateEvidenceLocation='private/evidence/**';RuntimeStaging=@('inventory/**','reports/**','work/**')
        }
    }
    Write-AmdJsonFile -Path (Join-Path $staging 'run-summary.json') -Value $runSummary -Compress
    Write-AmdUtf8NoBom -Path (Join-Path $staging 'run-report.md') -Text ((@(
        '# AMD Chipset Driver Research — Public Run Summary','',
        ('- Toolkit: `{0}`' -f $script:AmdChipsetResearchToolkitVersion),
        ('- Result: **{0}**' -f $CoreAssessment.OverallStatus),
        ('- Exit code: `{0}`' -f $CoreAssessment.ExitCode),
        ('- Stages: `{0}`' -f (@($ResolvedStages)-join ', ')),'',
        'This file and public/** are generated by the toolkit. Do not hand-edit generated JSON/CSV/Markdown.',
        'Host/runtime/debug evidence is retained under private/evidence/** and is not an automated repository-commit target.'
    )) -join "`n")

    $validation = Test-AmdPublicRepositorySurface -Root $staging
    if ([string]$validation.Status -ne 'Pass') {
        if ($script:AmdEvidenceContext) {
            Write-AmdJsonFile -Path (Join-Path $script:AmdEvidenceContext.EvidenceDirectory 'publication-validation-failed.json') -Value $validation
        }
        foreach ($message in @($validation.Errors)) { Write-Warning ('Public repository validation: {0}' -f $message) }
        Remove-Item -LiteralPath $staging -Recurse -Force -ErrorAction SilentlyContinue
        return [pscustomobject][ordered]@{Status='Fail';PublicRoot=$publicRoot;FileCount=0;Validation=$validation;Published=$false}
    }
    Write-AmdJsonFile -Path (Join-Path $staging 'publication-validation.json') -Value $validation -Compress

    $entries = New-Object 'System.Collections.Generic.List[object]'
    foreach ($file in @(Get-ChildItem -LiteralPath $staging -File -Recurse -Force | Sort-Object FullName)) {
        if ($file.Name -eq 'publication-manifest.json') { continue }
        $relative = ConvertTo-AmdRepositoryRelativePath -Path (Get-AmdRelativePath -BasePath $staging -Path $file.FullName)
        $sourceRelative = $null; $sourceSha = $null; $mode='ToolkitGenerated'
        if ($relative -like 'inventory/releases/*') { $sourceRelative=$relative; $mode='ByteCopyFromRuntimeCanonical' }
        elseif ($relative -in @('inventory/amd-chipset-driver-inventory.csv','inventory/amd-chipset-windows-server-compatibility.csv')) { $sourceRelative=$relative; $mode='ByteCopyFromRuntime' }
        elseif ($relative -like 'reports/*') { $sourceRelative=$relative; $mode='MarkdownLfNoBomFromRuntime' }
        if ($sourceRelative) {
            $sourceNativeRelative = $sourceRelative -replace '/', [System.IO.Path]::DirectorySeparatorChar
            $sourcePath = Join-Path $root $sourceNativeRelative
            if (Test-Path -LiteralPath $sourcePath -PathType Leaf) { $sourceSha = Get-AmdSha256 -Path $sourcePath }
        }
        $entries.Add([pscustomobject][ordered]@{
            RelativePath=$relative;SizeBytes=[int64]$file.Length;Sha256=Get-AmdSha256 -Path $file.FullName;Classification='PublicRepositoryArtifact'
            GenerationMode=$mode;SourceRelativePath=$sourceRelative;SourceSha256=$sourceSha;HandEdited=$false
        })
    }
    $manifestedPayloadSizeBytes = [int64]0
    $largestManifestedFileSizeBytes = [int64]0
    $largestManifestedFileRelativePath = $null
    foreach ($entry in @($entries.ToArray())) {
        $manifestedPayloadSizeBytes += [int64]$entry.SizeBytes
        if ([int64]$entry.SizeBytes -gt $largestManifestedFileSizeBytes) {
            $largestManifestedFileSizeBytes = [int64]$entry.SizeBytes
            $largestManifestedFileRelativePath = [string]$entry.RelativePath
        }
    }

    Write-AmdJsonFile -Path (Join-Path $staging 'publication-manifest.json') -Value ([pscustomobject][ordered]@{
        SchemaVersion='amd-chipset-publication-manifest/1.1';ToolkitVersion=$script:AmdChipsetResearchToolkitVersion;GeneratedAtUtc=Get-AmdUtcTimestamp
        PublicRootPolicy='Only public/** is an automated generated-output commit surface.'
        PrivateDataPolicy='private/evidence/**, inventory/**, reports/** and work/** are not automated generated-output commit surfaces.'
        TransformationPolicy=@(
            'Canonical per-release Raw JSON is copied byte-for-byte from runtime inventory/releases after field-scoped portable-path generation and compact serialization at canonical generation time.',
            'Runtime-local installer identities in path-bearing canonical fields are represented as external-artifact/<leaf> when the value is the acquired installer path; the host directory is intentionally discarded before canonical per-release Raw JSON is written.',
            'Extraction/workspace paths in path-bearing canonical fields are represented under work/extracted/<release>/... or evidence/extraction-logs/...; vendor selector/MSI/XML token fields are never path-normalized.',
            'Generated reports are deterministically normalized to UTF-8 no-BOM with LF line endings; selected CSV files are copied byte-for-byte from runtime staging. No report annotation is inserted during publication.',
            'release-index.json, amd-selector-static.json, run-summary.json, run-report.md, publication-validation.json and this manifest are deterministically generated by the toolkit.',
            'Tool-generated aggregate JSON indexes recursively canonicalize the Windows PowerShell 5.1 {value:[...],Count:n} collection-serialization wrapper to plain JSON arrays. Canonical per-release Raw JSON remains byte-unchanged.',
            'Repository-relative paths in public indexes/manifests always use forward slashes; source SHA-256 is recorded for byte-copied and Markdown-normalized runtime artifacts.',
            'Public JSON privacy checks parse JSON and inspect decoded scalar strings so Windows backslash escaping cannot hide runtime paths.',
            'No generated public JSON/CSV/Markdown is intended to be hand-edited.'
        )
        FileCount=$entries.Count;ManifestEntryCount=$entries.Count;PublicFileCountIncludingManifest=($entries.Count+1)
        ManifestedPayloadSizeBytes=$manifestedPayloadSizeBytes;LargestManifestedFileSizeBytes=$largestManifestedFileSizeBytes;LargestManifestedFileRelativePath=$largestManifestedFileRelativePath
        Files=@($entries.ToArray())
    }) -Compress

    if (Test-Path -LiteralPath $publicRoot -PathType Container) { Remove-Item -LiteralPath $publicRoot -Recurse -Force }
    Move-Item -LiteralPath $staging -Destination $publicRoot
    return [pscustomobject][ordered]@{Status='Pass';PublicRoot=$publicRoot;FileCount=$entries.Count+1;Validation=$validation;Published=$true}
}

function Get-AmdRunAssessment {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$ResolvedStages
    )

    $toolRoot = Get-AmdResearchToolkitRoot
    $items = New-Object 'System.Collections.Generic.List[object]'

    $failedStages = @($script:AmdStageResults.ToArray() | Where-Object { $_.Status -in @('FAIL','BLOCKED') })
    $items.Add([pscustomobject]@{
        Name = 'StageExecution'
        Status = if ($failedStages.Count -eq 0) { 'PASS' } else { 'REVIEW' }
        Detail = if ($failedStages.Count -eq 0) {
            ('all {0} selected stage(s) completed without terminating errors' -f $script:AmdStageResults.Count)
        }
        else {
            ('{0} stage(s) failed or were blocked: {1}' -f $failedStages.Count, (@($failedStages | ForEach-Object { '{0}={1}' -f $_.Name,$_.Status }) -join ', '))
        }
    })

    if ($ResolvedStages -contains 'Test') {
        $envPath = Join-Path (Join-Path $toolRoot 'inventory') 'environment.json'
        if (Test-Path -LiteralPath $envPath -PathType Leaf) {
            try {
                $envData = Read-AmdJsonFile -Path $envPath
                $ready = [bool]$envData.Readiness.FullResearchReady
                $items.Add([pscustomobject]@{
                    Name = 'ResearchEnvironment'
                    Status = if ($ready) { 'PASS' } else { 'REVIEW' }
                    Detail = if ($ready) { 'PowerShell runtime and 7-Zip are available' } else { 'full research dependencies are not ready; inspect environment.json' }
                })
            }
            catch {
                $items.Add([pscustomobject]@{ Name = 'ResearchEnvironment'; Status = 'REVIEW'; Detail = $_.Exception.Message })
            }
        }
    }

    if ($ResolvedStages -contains 'Acquire') {
        if (-not (Test-AmdStagePassedCurrentRun -Name 'Acquire')) {
            $items.Add([pscustomobject]@{ Name='Acquisition'; Status='REVIEW'; Detail='not assessed from inventory because Acquire did not PASS in the current run' })
        }
        else {
            $path = Join-Path (Join-Path $toolRoot 'inventory') 'acquisition.json'
            if (Test-Path -LiteralPath $path -PathType Leaf) {
                try {
                    $data = Read-AmdJsonFile -Path $path
                    $failed = @($data.Artifacts | Where-Object { $_.Status -notin @('Downloaded', 'Cached') })
                    $items.Add([pscustomobject]@{
                        Name = 'Acquisition'
                        Status = if ($failed.Count -eq 0) { 'PASS' } else { 'REVIEW' }
                        Detail = if ($failed.Count -eq 0) { ('{0} installer artifact(s) available' -f @($data.Artifacts).Count) } else { ('{0} installer artifact(s) unavailable' -f $failed.Count) }
                    })
                }
                catch {
                    $items.Add([pscustomobject]@{ Name = 'Acquisition'; Status = 'REVIEW'; Detail = $_.Exception.Message })
                }
            }
            else {
                $items.Add([pscustomobject]@{ Name='Acquisition'; Status='REVIEW'; Detail='Acquire passed but acquisition.json is missing' })
            }
        }
    }

    if ($ResolvedStages -contains 'Extract') {
        if (-not (Test-AmdStagePassedCurrentRun -Name 'Extract')) {
            $items.Add([pscustomobject]@{ Name='ExtractionCompleteness'; Status='REVIEW'; Detail='not assessed from inventory because Extract did not PASS in the current run' })
        }
        else {
            $path = Join-Path (Join-Path $toolRoot 'inventory') 'extraction.json'
            if (Test-Path -LiteralPath $path -PathType Leaf) {
                try {
                    $data = Read-AmdJsonFile -Path $path
                    $partial = @($data.Releases | Where-Object { $_.Status -ne 'ExtractionComplete' })
                    $items.Add([pscustomobject]@{
                        Name = 'ExtractionCompleteness'
                        Status = if ($partial.Count -eq 0 -and @($data.Releases).Count -gt 0) { 'PASS' } else { 'REVIEW' }
                        Detail = if ($partial.Count -eq 0 -and @($data.Releases).Count -gt 0) {
                            ('{0} release(s) reached INF-bearing extraction output' -f @($data.Releases).Count)
                        }
                        else {
                            ('{0} release(s) are incomplete/failed or no releases were extracted' -f $partial.Count)
                        }
                    })
                }
                catch {
                    $items.Add([pscustomobject]@{ Name = 'ExtractionCompleteness'; Status = 'REVIEW'; Detail = $_.Exception.Message })
                }
            }
            else {
                $items.Add([pscustomobject]@{ Name='ExtractionCompleteness'; Status='REVIEW'; Detail='Extract passed but extraction.json is missing' })
            }
        }
    }

    if ($ResolvedStages -contains 'Inspect') {
        if (-not (Test-AmdStagePassedCurrentRun -Name 'Inspect')) {
            $items.Add([pscustomobject]@{ Name='InfInspection'; Status='REVIEW'; Detail='not assessed from inventory because Inspect did not PASS in the current run' })
        }
        else {
            $path = Join-Path (Join-Path $toolRoot 'inventory') 'driver-packages.json'
            if (Test-Path -LiteralPath $path -PathType Leaf) {
                try {
                    $data = Read-AmdJsonFile -Path $path
                    $count = @($data.DriverPackages).Count
                    $items.Add([pscustomobject]@{
                        Name = 'InfInspection'
                        Status = if ($count -gt 0) { 'PASS' } else { 'REVIEW' }
                        Detail = ('{0} INF package record(s) produced' -f $count)
                    })
                }
                catch {
                    $items.Add([pscustomobject]@{ Name = 'InfInspection'; Status = 'REVIEW'; Detail = $_.Exception.Message })
                }
            }
            else {
                $items.Add([pscustomobject]@{ Name='InfInspection'; Status='REVIEW'; Detail='Inspect passed but driver-packages.json is missing' })
            }
        }
    }

    if ($ResolvedStages -contains 'Selector') {
        if (-not (Test-AmdStagePassedCurrentRun -Name 'Selector')) {
            $items.Add([pscustomobject]@{ Name='MsiDeclarativeInspection'; Status='REVIEW'; Detail='not assessed from selector inventory because Selector did not PASS in the current run' })
        }
        else {
            $path = Join-Path (Join-Path $toolRoot 'inventory') 'amd-selector-static.json'
            if (Test-Path -LiteralPath $path -PathType Leaf) {
                try {
                    $data = Read-AmdJsonFile -Path $path
                    $items.Add((Get-AmdMsiDeclarativeAssessmentFromReleases -Releases @($data.Releases)))
                }
                catch {
                    $items.Add([pscustomobject]@{ Name='MsiDeclarativeInspection'; Status='REVIEW'; Detail=$_.Exception.Message })
                }
            }
            else {
                $items.Add([pscustomobject]@{ Name='MsiDeclarativeInspection'; Status='REVIEW'; Detail='Selector passed but amd-selector-static.json is missing' })
            }
        }
    }

    if ($null -ne $script:AmdPublicationResult) {
        $pubOk = ([bool]$script:AmdPublicationResult.Published -and [string]$script:AmdPublicationResult.Status -eq 'Pass')
        $items.Add([pscustomobject]@{
            Name='PublicRepositorySurface';Status=if($pubOk){'PASS'}else{'REVIEW'}
            Detail=if($pubOk){('validated public surface published: {0} file(s)' -f [int]$script:AmdPublicationResult.FileCount)}else{'publication validation failed; previous public baseline was preserved'}
        })
    }

    $reviewCount = @($items.ToArray() | Where-Object { $_.Status -eq 'REVIEW' }).Count
    $overall = if ($script:AmdTopLevelFatalError) { 'FatalError' }
        elseif ($reviewCount -gt 0) { 'ReviewRequired' }
        else { 'Pass' }

    return [pscustomobject][ordered]@{
        SchemaVersion = 'amd-chipset-driver-research-assessment/1.0'
        ToolkitVersion = $script:AmdChipsetResearchToolkitVersion
        GeneratedAtUtc = Get-AmdUtcTimestamp
        OverallStatus = $overall
        ExitCode = if ($overall -eq 'Pass') { 0 } elseif ($overall -eq 'FatalError') { 1 } else { 2 }
        Items = @($items.ToArray())
    }
}

function Write-AmdAssessmentConsoleReport {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object]$Assessment,

        [string]$EvidenceDirectory,
        [string]$ZipPath
    )

    Write-Host ''
    Write-Host '================================================================================================================' -ForegroundColor Cyan
    Write-Host ' AMD CHIPSET DRIVER RESEARCH RUN REPORT' -ForegroundColor Cyan
    Write-Host '================================================================================================================' -ForegroundColor Cyan
    foreach ($item in @($Assessment.Items)) {
        $color = if ($item.Status -eq 'PASS') { 'Green' } else { 'Yellow' }
        Write-Host (('[{0}]' -f $item.Status).PadRight(10)) -NoNewline -ForegroundColor $color
        Write-Host ('{0,-28} {1}' -f $item.Name, $item.Detail)
    }
    Write-Host '----------------------------------------------------------------------------------------------------------------' -ForegroundColor DarkGray
    Write-Host ('FINAL RESULT  : {0}' -f $Assessment.OverallStatus)
    Write-Host ('EXIT CODE     : {0}' -f $Assessment.ExitCode)
    Write-Host ('TOTAL ELAPSED : {0}' -f (Format-AmdElapsed ((Get-Date) - $script:AmdRunStartTime))) -ForegroundColor Cyan
    if ($EvidenceDirectory) { Write-Host ('EVIDENCE DIR  : {0}' -f $EvidenceDirectory) }
    if ($ZipPath) { Write-Host ('EVIDENCE ZIP  : {0}' -f $ZipPath) }
    Write-Host '================================================================================================================' -ForegroundColor Cyan
}

function Finalize-AmdResearchEvidenceSession {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$ResolvedStages,

        [switch]$SkipArchive,

        [switch]$IncludeInstallers
    )

    if ($null -eq $script:AmdEvidenceContext) {
        return (Get-AmdRunAssessment -ResolvedStages $ResolvedStages)
    }

    $ctx = $script:AmdEvidenceContext
    Write-AmdStageResultsEvidence

    # Publication is an explicit fail-closed gate. Build the public surface from runtime output,
    # then recompute the final assessment so a publication failure becomes ReviewRequired.
    $coreAssessment = Get-AmdRunAssessment -ResolvedStages $ResolvedStages
    if (-not $script:SkipPublicExport) {
        $script:AmdPublicationResult = Publish-AmdRepositorySurface -CoreAssessment $coreAssessment -ResolvedStages $ResolvedStages
    }
    else { $script:AmdPublicationResult = $null }
    $assessment = Get-AmdRunAssessment -ResolvedStages $ResolvedStages
    Write-AmdJsonFile -Path (Join-Path $ctx.EvidenceDirectory 'assessment.json') -Value $assessment
    $runElapsed = (Get-Date) - $script:AmdRunStartTime

    $summary = [pscustomobject][ordered]@{
        SchemaVersion = $script:AmdChipsetResearchEvidenceSchemaVersion
        ToolkitVersion = $script:AmdChipsetResearchToolkitVersion
        RunId = $ctx.RunId
        StartedAtUtc = $ctx.StartedAtUtc
        CompletedAtUtc = Get-AmdUtcTimestamp
        TotalDurationMilliseconds = [int64]$runElapsed.TotalMilliseconds
        TotalDuration = Format-AmdElapsed $runElapsed
        StageTimings = @($script:AmdStageResults.ToArray())
        OverallStatus = $assessment.OverallStatus
        ExitCode = $assessment.ExitCode
        ScriptSha256 = $ctx.ScriptSha256
        SelectedStages = @($ResolvedStages)
        EvidenceDirectory = $ctx.EvidenceDirectory
        EvidenceZip = if ($SkipArchive) { $null } else { $ctx.ZipPath }
        IncludeInstallersInEvidence = [bool]$IncludeInstallers
        RawWorkDirectoryIncluded = $false
        Notes = @(
            'The work/extracted tree is intentionally excluded from the evidence ZIP to keep review bundles manageable.',
            'Installer binaries are excluded by default; acquisition.json records path, SHA-256 and size.',
            'Use -IncludeInstallersInEvidence only when binary preservation inside the review ZIP is explicitly required.',
            'Generated repository-public output is under public/**; private evidence is not an automated commit surface.'
        )
    }
    Write-AmdJsonFile -Path (Join-Path $ctx.EvidenceDirectory 'run-summary.json') -Value $summary

    $summaryText = @(
        'AMD CHIPSET DRIVER RESEARCH EVIDENCE',
        ('Toolkit version : {0}' -f $script:AmdChipsetResearchToolkitVersion),
        ('Run ID          : {0}' -f $ctx.RunId),
        ('Started UTC     : {0}' -f $ctx.StartedAtUtc),
        ('Completed UTC   : {0}' -f $summary.CompletedAtUtc),
        ('Total elapsed   : {0}' -f $summary.TotalDuration),
        ('Stages          : {0}' -f ($ResolvedStages -join ', ')),
        ('Final result    : {0}' -f $assessment.OverallStatus),
        ('Exit code       : {0}' -f $assessment.ExitCode),
        ('Script SHA-256  : {0}' -f $ctx.ScriptSha256)
    ) -join [Environment]::NewLine
    Write-AmdUtf8NoBom -Path (Join-Path $ctx.EvidenceDirectory 'run-summary.txt') -Text $summaryText

    $snapshot = Join-Path $ctx.EvidenceDirectory 'snapshot'
    $toolSnapshot = Join-Path $snapshot 'tool'
    New-AmdDirectory -Path $toolSnapshot | Out-Null

    foreach ($name in @('Invoke-AmdChipsetDriverResearch.ps1', 'README.md', 'SPEC.md', 'THIRD-PARTY-NOTICES.md')) {
        $src = Join-Path (Get-AmdResearchToolkitRoot) $name
        if (Test-Path -LiteralPath $src -PathType Leaf) {
            Copy-Item -LiteralPath $src -Destination (Join-Path $toolSnapshot $name) -Force
        }
    }

    Copy-AmdEvidenceTree -Source (Join-Path (Get-AmdResearchToolkitRoot) 'inventory') -Destination (Join-Path $snapshot 'inventory')
    Copy-AmdEvidenceTree -Source (Join-Path (Get-AmdResearchToolkitRoot) 'reports') -Destination (Join-Path $snapshot 'reports')
    Copy-AmdEvidenceTree -Source (Join-Path (Get-AmdPrivateEvidenceRoot) 'release-notes') -Destination (Join-Path $snapshot 'release-notes')
    Copy-AmdEvidenceTree -Source (Join-Path (Get-AmdPrivateEvidenceRoot) 'extraction-logs') -Destination (Join-Path $snapshot 'extraction-logs')
    Copy-AmdEvidenceTree -Source (Join-Path (Get-AmdPrivateEvidenceRoot) 'download-diagnostics') -Destination (Join-Path $snapshot 'download-diagnostics')

    if ($IncludeInstallers) {
        Copy-AmdEvidenceTree -Source (Join-Path (Get-AmdPrivateEvidenceRoot) 'installers') -Destination (Join-Path $snapshot 'installers')
    }

    if ($script:AmdPublicationResult -and $script:AmdPublicationResult.Published) {
        $publicManifest = Join-Path (Get-AmdPublicOutputRoot) 'publication-manifest.json'
        if (Test-Path -LiteralPath $publicManifest -PathType Leaf) {
            Write-AmdJsonFile -Path (Join-Path $snapshot 'public-publication-reference.json') -Value ([pscustomobject][ordered]@{
                Classification='PrivateEvidenceReference';PublicManifest='public/publication-manifest.json';PublicManifestSha256=Get-AmdSha256 -Path $publicManifest
                PublicFileCount=[int]$script:AmdPublicationResult.FileCount;Note='The public dataset is not duplicated in private evidence; verify it by manifest SHA-256.'
            })
        }
    }

    $artifactIndex = New-Object 'System.Collections.Generic.List[object]'
    $acquisitionPath = Join-Path (Join-Path (Get-AmdResearchToolkitRoot) 'inventory') 'acquisition.json'
    if (Test-Path -LiteralPath $acquisitionPath -PathType Leaf) {
        try {
            $acq = Read-AmdJsonFile -Path $acquisitionPath
            foreach ($artifact in @($acq.Artifacts)) {
                $artifactIndex.Add([pscustomobject][ordered]@{
                    ReleaseVersion = $artifact.ReleaseVersion
                    Status = $artifact.Status
                    LocalPath = $artifact.LocalPath
                    FileName = $artifact.FileName
                    SizeBytes = $artifact.SizeBytes
                    Sha256 = $artifact.Sha256
                    SourceUrl = $artifact.SourceUrl
                    IncludedInEvidenceZip = [bool]$IncludeInstallers
                })
            }
        }
        catch {
            $artifactIndex.Add([pscustomobject]@{ Error = $_.Exception.Message })
        }
    }

    Write-AmdJsonFile -Path (Join-Path $ctx.EvidenceDirectory 'external-artifacts.json') -Value ([pscustomobject]@{
        GeneratedAtUtc = Get-AmdUtcTimestamp
        Artifacts = @($artifactIndex.ToArray())
    })

    # Print timing while transcript is still active so the review ZIP contains
    # the same operator-facing timing summary that was visible on screen.
    Write-AmdRunTimingSummary -Assessment $assessment

    if ($script:AmdTranscriptStarted) {
        try {
            Stop-Transcript | Out-Null
        }
        catch {
            Write-AmdUtf8NoBom -Path (Join-Path (Join-Path $ctx.EvidenceDirectory 'logs') 'transcript-stop-error.txt') -Text $_.Exception.ToString()
        }
        $script:AmdTranscriptStarted = $false
    }

    $manifestEntries = New-Object 'System.Collections.Generic.List[object]'
    foreach ($file in @(Get-ChildItem -LiteralPath $ctx.EvidenceDirectory -File -Recurse -Force -ErrorAction SilentlyContinue)) {
        if ($file.Name -eq 'evidence-manifest.json') {
            continue
        }
        $manifestEntries.Add([pscustomobject][ordered]@{
            RelativePath = Get-AmdRelativePath -BasePath $ctx.EvidenceDirectory -Path $file.FullName
            SizeBytes = [int64]$file.Length
            Sha256 = try { Get-AmdSha256 -Path $file.FullName } catch { $null }
        })
    }

    Write-AmdJsonFile -Path (Join-Path $ctx.EvidenceDirectory 'evidence-manifest.json') -Value ([pscustomobject][ordered]@{
        SchemaVersion = 'amd-chipset-driver-research-evidence-manifest/1.0'
        GeneratedAtUtc = Get-AmdUtcTimestamp
        FileCount = $manifestEntries.Count
        Files = @($manifestEntries.ToArray())
    })

    if (-not $SkipArchive) {
        try {
            $archive = New-AmdZipFromDirectory -SourceDirectory $ctx.EvidenceDirectory -DestinationZip $ctx.ZipPath
            Write-Host ('Evidence ZIP created: {0} ({1} bytes)' -f $ctx.ZipPath, $archive.Length)
        }
        catch {
            Write-AmdUtf8NoBom -Path (Join-Path $ctx.EvidenceDirectory 'archive-error.txt') -Text $_.Exception.ToString()
            Write-Warning ('Evidence archive could not be created: {0}' -f $_.Exception.Message)
            Write-Warning ('Evidence directory remains available: {0}' -f $ctx.EvidenceDirectory)
        }
    }

    return $assessment
}

function Get-AmdSha256 {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant()
}


function Get-AmdInstallerFileValidation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [int64]$MinimumSizeBytes = 5MB
    )

    $result = [ordered]@{
        Path = $Path
        Present = $false
        SizeBytes = $null
        SizeSane = $false
        HasMzSignature = $false
        HasZipSignature = $false
        ArtifactFormat = 'Unknown'
        LooksLikeHtml = $false
        Valid = $false
        Error = $null
    }

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        $result.Error = 'File does not exist.'
        return [pscustomobject]$result
    }

    try {
        $item = Get-Item -LiteralPath $Path -ErrorAction Stop
        $result.Present = $true
        $result.SizeBytes = [int64]$item.Length
        $result.SizeSane = ($item.Length -ge $MinimumSizeBytes)

        $stream = [System.IO.File]::Open($item.FullName, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::Read)
        try {
            $sig = New-Object byte[] 4
            $read = $stream.Read($sig, 0, 4)
            if ($read -ge 2) {
                $result.HasMzSignature = ($sig[0] -eq 0x4D -and $sig[1] -eq 0x5A)
            }
            if ($read -ge 4) {
                $result.HasZipSignature = (
                    $sig[0] -eq 0x50 -and $sig[1] -eq 0x4B -and
                    (($sig[2] -eq 0x03 -and $sig[3] -eq 0x04) -or
                     ($sig[2] -eq 0x05 -and $sig[3] -eq 0x06) -or
                     ($sig[2] -eq 0x07 -and $sig[3] -eq 0x08))
                )
            }

            if ($result.HasMzSignature) { $result.ArtifactFormat = 'PE' }
            elseif ($result.HasZipSignature) { $result.ArtifactFormat = 'ZIP' }

            $stream.Position = 0
            $probeLength = [int][Math]::Min([int64]4096, $stream.Length)
            $probe = New-Object byte[] $probeLength
            $null = $stream.Read($probe, 0, $probeLength)
            $probeText = [System.Text.Encoding]::ASCII.GetString($probe)
            $result.LooksLikeHtml = ($probeText -match '(?i)<!doctype\s+html|<html|<head|<body')
            if ($result.LooksLikeHtml) { $result.ArtifactFormat = 'HTML' }
        }
        finally {
            $stream.Dispose()
        }

        $recognized = ($result.HasMzSignature -or $result.HasZipSignature)
        $result.Valid = ($result.SizeSane -and $recognized -and -not $result.LooksLikeHtml)
        if (-not $result.Valid) {
            $reasons = New-Object System.Collections.Generic.List[string]
            if (-not $result.SizeSane) { $reasons.Add(('size below {0} bytes' -f $MinimumSizeBytes)) }
            if (-not $recognized) { $reasons.Add('recognized EXE/ZIP signature absent') }
            if ($result.LooksLikeHtml) { $reasons.Add('content looks like HTML') }
            $result.Error = $reasons -join '; '
        }
    }
    catch {
        $result.Error = $_.Exception.Message
    }

    return [pscustomobject]$result
}

function Get-AmdStringSha256 {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]$Text
    )

    $bytes = [System.Text.Encoding]::UTF8.GetBytes($Text)
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try {
        $hash = $sha.ComputeHash($bytes)
        return (($hash | ForEach-Object { $_.ToString('x2') }) -join '')
    }
    finally {
        $sha.Dispose()
    }
}

function Get-AmdVersionFromText {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]$Text
    )

    # AMD occasionally publishes a release-note URL whose path contains an
    # older release version in a parent segment and the actual release version
    # in the leaf segment, for example:
    #   ...6-10-17-152/RN-RYZEN-CHIPSET-7-02-13-148.html
    #
    # Release identity follows the leaf-side/latest version token, so use the
    # final four-part version match rather than the first match.
    $matches = [regex]::Matches(
        $Text,
        '(?<!\d)(\d+)[\.\-_](\d+)[\.\-_](\d+)[\.\-_](\d+)(?!\d)',
        [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
    )

    if ($matches.Count -eq 0) {
        return $null
    }

    $m = $matches[$matches.Count - 1]

    return ('{0}.{1}.{2}.{3}' -f
        [int]$m.Groups[1].Value,
        $m.Groups[2].Value.PadLeft(2, '0'),
        $m.Groups[3].Value.PadLeft(2, '0'),
        $m.Groups[4].Value)
}

function ConvertTo-AmdSafeName {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Value
    )

    $invalid = [System.IO.Path]::GetInvalidFileNameChars()
    $result = $Value

    foreach ($ch in $invalid) {
        $result = $result.Replace([string]$ch, '_')
    }

    $result = $result -replace '[^A-Za-z0-9._-]', '_'
    return $result.Trim('_')
}

function Enable-AmdTls12ForWindowsPowerShell {
    [CmdletBinding()]
    param()

    if ($PSVersionTable.PSVersion.Major -le 5) {
        try {
            [Net.ServicePointManager]::SecurityProtocol =
                [Net.ServicePointManager]::SecurityProtocol -bor
                [Net.SecurityProtocolType]::Tls12
        }
        catch {
            Write-Verbose ('Unable to enable TLS 1.2 explicitly: {0}' -f $_.Exception.Message)
        }
    }
}

function Get-AmdCompactErrorMessage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]$Message,
        [int]$MaximumLength = 600
    )

    $text = ($Message -replace '[\r\n\t]+', ' ').Trim()
    $text = [regex]::Replace($text, '\s{2,}', ' ')
    if ($text.Length -gt $MaximumLength) {
        return ($text.Substring(0, $MaximumLength) + ' ...')
    }
    return $text
}

function ConvertFrom-AmdXmlText {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]$Text,
        [string]$Source = 'response'
    )

    if ([string]::IsNullOrWhiteSpace($Text)) {
        throw ('Empty XML content returned by {0}.' -f $Source)
    }

    $trimmed = $Text.TrimStart()
    if ($trimmed -match '(?is)^<!doctype\s+html\b|^<html\b') {
        throw ('HTML content was returned where XML was expected ({0}).' -f $Source)
    }
    if (-not $trimmed.StartsWith('<')) {
        throw ('Non-XML content was returned where XML was expected ({0}).' -f $Source)
    }

    $doc = New-Object System.Xml.XmlDocument
    try {
        $doc.LoadXml($Text)
        return $doc
    }
    catch {
        $detail = Get-AmdCompactErrorMessage -Message $_.Exception.Message -MaximumLength 300
        throw ('Invalid XML returned by {0}: {1}' -f $Source, $detail)
    }
}

function New-AmdHttpRequest {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Uri,
        [string]$Referer,
        [int]$TimeoutSec = 90,
        [int]$MaximumRedirection = 10
    )

    Enable-AmdTls12ForWindowsPowerShell

    $request = [System.Net.HttpWebRequest]::Create($Uri)
    $request.Method = 'GET'
    $request.UserAgent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0 Safari/537.36'
    $request.Accept = '*/*'
    $request.AllowAutoRedirect = $true
    $request.MaximumAutomaticRedirections = $MaximumRedirection
    $request.Timeout = [Math]::Max(1000, ($TimeoutSec * 1000))
    try { $request.ReadWriteTimeout = [Math]::Max(1000, ($TimeoutSec * 1000)) } catch { }
    $request.Headers['Accept-Language'] = 'en-US,en;q=0.9'
    if ($Referer) { $request.Referer = $Referer }
    return $request
}

function Invoke-AmdWebRequest {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Uri,
        [string]$OutFile,
        [string]$Referer,
        [int]$TimeoutSec = 90,
        [int]$MaximumRedirection = 10
    )

    $request = New-AmdHttpRequest -Uri $Uri -Referer $Referer -TimeoutSec $TimeoutSec -MaximumRedirection $MaximumRedirection
    $response = $null
    try {
        $response = [System.Net.HttpWebResponse]$request.GetResponse()
        $statusCode = [int]$response.StatusCode
        $contentType = [string]$response.ContentType
        $responseUri = if ($response.ResponseUri) { $response.ResponseUri.AbsoluteUri } else { $Uri }
        $stream = $response.GetResponseStream()
        try {
            if ($OutFile) {
                $directory = Split-Path -Parent $OutFile
                if ($directory) { New-AmdDirectory -Path $directory | Out-Null }
                $file = [System.IO.File]::Open($OutFile, [System.IO.FileMode]::Create, [System.IO.FileAccess]::Write, [System.IO.FileShare]::None)
                try { $stream.CopyTo($file) } finally { $file.Dispose() }
                return [pscustomobject]@{ StatusCode=$statusCode; ContentType=$contentType; ResponseUri=$responseUri; Content=$null }
            }

            $memory = New-Object System.IO.MemoryStream
            try {
                $stream.CopyTo($memory)
                $bytes = $memory.ToArray()
            }
            finally {
                $memory.Dispose()
            }

            # HttpWebResponse may report ISO-8859-1 when an HTML server omits an HTTP
            # charset even though the document itself declares UTF-8. Inspect the
            # initial markup first so Windows PowerShell 5.1 does not persist mojibake.
            $encodingName = $null
            $probeCount = [Math]::Min(4096, $bytes.Length)
            if ($probeCount -gt 0) {
                $asciiProbe = [System.Text.Encoding]::ASCII.GetString($bytes, 0, $probeCount)
                $charsetMatch = [regex]::Match($asciiProbe, '(?i)charset\s*=\s*["'']?\s*([A-Za-z0-9._-]+)')
                if ($charsetMatch.Success) { $encodingName = $charsetMatch.Groups[1].Value }
            }
            if (-not $encodingName -and $contentType) {
                $headerCharset = [regex]::Match($contentType, '(?i)charset\s*=\s*["'']?\s*([A-Za-z0-9._-]+)')
                if ($headerCharset.Success) { $encodingName = $headerCharset.Groups[1].Value }
            }
            if (-not $encodingName -and $response.CharacterSet -and $response.CharacterSet -notmatch '(?i)^iso-8859-1$') {
                $encodingName = [string]$response.CharacterSet
            }

            $encoding = [System.Text.Encoding]::UTF8
            if ($encodingName) {
                try { $encoding = [System.Text.Encoding]::GetEncoding($encodingName) } catch { }
            }
            $content = $encoding.GetString($bytes)
            if ($content.Length -gt 0 -and $content[0] -eq [char]0xFEFF) { $content = $content.Substring(1) }
            return [pscustomobject]@{ StatusCode=$statusCode; ContentType=$contentType; ResponseUri=$responseUri; Content=$content }
        }
        finally {
            if ($stream) { $stream.Dispose() }
        }
    }
    catch [System.Net.WebException] {
        if ($file) { $file.Dispose(); $file = $null }
        if ($stream) { $stream.Dispose(); $stream = $null }
        $status = $null
        $reason = $_.Exception.Message
        if ($_.Exception.Response) {
            try {
                $webResponse = [System.Net.HttpWebResponse]$_.Exception.Response
                $status = [int]$webResponse.StatusCode
                $reason = [string]$webResponse.StatusDescription
            }
            catch { }
        }
        if ($OutFile -and (Test-Path -LiteralPath $OutFile -PathType Leaf)) {
            Remove-Item -LiteralPath $OutFile -Force -ErrorAction SilentlyContinue
        }
        if ($status) { throw ('HTTP {0} {1} for {2}' -f $status, $reason, $Uri) }
        throw ('HTTP request failed for {0}: {1}' -f $Uri, (Get-AmdCompactErrorMessage -Message $_.Exception.Message -MaximumLength 300))
    }
    finally {
        if ($response) { $response.Close() }
    }
}

function Invoke-AmdQuietFileDownload {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$Uri,
        [Parameter(Mandatory = $true)][string]$OutFile,
        [string]$Referer,
        [int]$TimeoutSec = 600,
        [int]$MaximumRedirection = 10
    )

    # Expected HTTP misses (404, retired historical URLs, redirects to an
    # error page) are represented as data instead of PowerShell `throw`.
    # Windows PowerShell 5.1's Start-Transcript records caught `throw`
    # statements as "terminating error" lines, which made normal candidate
    # probing look like a script failure to the operator.
    $request = $null
    $response = $null
    $stream = $null
    $file = $null
    try {
        $request = New-AmdHttpRequest -Uri $Uri -Referer $Referer -TimeoutSec $TimeoutSec -MaximumRedirection $MaximumRedirection
        $response = [System.Net.HttpWebResponse]$request.GetResponse()
        $statusCode = [int]$response.StatusCode
        $responseUri = if ($response.ResponseUri) { $response.ResponseUri.AbsoluteUri } else { $Uri }

        $directory = Split-Path -Parent $OutFile
        if ($directory) { New-AmdDirectory -Path $directory | Out-Null }

        $stream = $response.GetResponseStream()
        $file = [System.IO.File]::Open($OutFile, [System.IO.FileMode]::Create, [System.IO.FileAccess]::Write, [System.IO.FileShare]::None)
        $stream.CopyTo($file)

        return [pscustomobject]@{
            Success = $true
            StatusCode = $statusCode
            ResponseUri = $responseUri
            Error = $null
        }
    }
    catch [System.Net.WebException] {
        $status = $null
        $reason = $_.Exception.Message
        $responseUri = $null
        if ($_.Exception.Response) {
            try {
                $webResponse = [System.Net.HttpWebResponse]$_.Exception.Response
                $status = [int]$webResponse.StatusCode
                $reason = [string]$webResponse.StatusDescription
                if ($webResponse.ResponseUri) { $responseUri = $webResponse.ResponseUri.AbsoluteUri }
            }
            catch { }
        }

        if (Test-Path -LiteralPath $OutFile -PathType Leaf) {
            Remove-Item -LiteralPath $OutFile -Force -ErrorAction SilentlyContinue
        }

        $errorText = if ($status) {
            'HTTP {0} {1} for {2}' -f $status, $reason, $Uri
        }
        else {
            'HTTP request failed for {0}: {1}' -f $Uri, (Get-AmdCompactErrorMessage -Message $_.Exception.Message -MaximumLength 300)
        }

        return [pscustomobject]@{
            Success = $false
            StatusCode = $status
            ResponseUri = $responseUri
            Error = $errorText
        }
    }
    catch {
        if ($file) { $file.Dispose(); $file = $null }
        if ($stream) { $stream.Dispose(); $stream = $null }
        if (Test-Path -LiteralPath $OutFile -PathType Leaf) {
            Remove-Item -LiteralPath $OutFile -Force -ErrorAction SilentlyContinue
        }
        return [pscustomobject]@{
            Success = $false
            StatusCode = $null
            ResponseUri = $null
            Error = (Get-AmdCompactErrorMessage -Message $_.Exception.Message -MaximumLength 400)
        }
    }
    finally {
        if ($file) { $file.Dispose() }
        if ($stream) { $stream.Dispose() }
        if ($response) { $response.Close() }
    }
}


function Invoke-AmdQuietTextRequest {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$Uri,
        [string]$Referer,
        [int]$TimeoutSec = 90,
        [int]$MaximumRedirection = 10
    )

    $request = $null
    $response = $null
    $stream = $null
    $memory = $null
    try {
        $request = New-AmdHttpRequest -Uri $Uri -Referer $Referer -TimeoutSec $TimeoutSec -MaximumRedirection $MaximumRedirection
        $response = [System.Net.HttpWebResponse]$request.GetResponse()
        $statusCode = [int]$response.StatusCode
        $contentType = [string]$response.ContentType
        $responseUri = if ($response.ResponseUri) { $response.ResponseUri.AbsoluteUri } else { $Uri }

        $stream = $response.GetResponseStream()
        $memory = New-Object System.IO.MemoryStream
        $stream.CopyTo($memory)
        $bytes = $memory.ToArray()

        $encodingName = $null
        $probeCount = [Math]::Min(4096, $bytes.Length)
        if ($probeCount -gt 0) {
            $asciiProbe = [System.Text.Encoding]::ASCII.GetString($bytes, 0, $probeCount)
            $charsetMatch = [regex]::Match($asciiProbe, '(?i)charset\s*=\s*["'']?\s*([A-Za-z0-9._-]+)')
            if ($charsetMatch.Success) { $encodingName = $charsetMatch.Groups[1].Value }
        }
        if (-not $encodingName -and $contentType) {
            $headerCharset = [regex]::Match($contentType, '(?i)charset\s*=\s*["'']?\s*([A-Za-z0-9._-]+)')
            if ($headerCharset.Success) { $encodingName = $headerCharset.Groups[1].Value }
        }
        if (-not $encodingName -and $response.CharacterSet -and $response.CharacterSet -notmatch '(?i)^iso-8859-1$') {
            $encodingName = [string]$response.CharacterSet
        }

        $encoding = [System.Text.Encoding]::UTF8
        if ($encodingName) {
            try { $encoding = [System.Text.Encoding]::GetEncoding($encodingName) } catch { }
        }
        $content = $encoding.GetString($bytes)
        if ($content.Length -gt 0 -and $content[0] -eq [char]0xFEFF) { $content = $content.Substring(1) }

        return [pscustomobject]@{
            Success = $true
            StatusCode = $statusCode
            ContentType = $contentType
            ResponseUri = $responseUri
            Content = $content
            Error = $null
        }
    }
    catch [System.Net.WebException] {
        $status = $null
        $reason = $_.Exception.Message
        $responseUri = $null
        if ($_.Exception.Response) {
            try {
                $webResponse = [System.Net.HttpWebResponse]$_.Exception.Response
                $status = [int]$webResponse.StatusCode
                $reason = [string]$webResponse.StatusDescription
                if ($webResponse.ResponseUri) { $responseUri = $webResponse.ResponseUri.AbsoluteUri }
            }
            catch { }
        }
        $errorText = if ($status) {
            'HTTP {0} {1} for {2}' -f $status, $reason, $Uri
        }
        else {
            'HTTP request failed for {0}: {1}' -f $Uri, (Get-AmdCompactErrorMessage -Message $_.Exception.Message -MaximumLength 300)
        }
        return [pscustomobject]@{
            Success = $false
            StatusCode = $status
            ContentType = $null
            ResponseUri = $responseUri
            Content = $null
            Error = $errorText
        }
    }
    catch {
        return [pscustomobject]@{
            Success = $false
            StatusCode = $null
            ContentType = $null
            ResponseUri = $null
            Content = $null
            Error = (Get-AmdCompactErrorMessage -Message $_.Exception.Message -MaximumLength 400)
        }
    }
    finally {
        if ($memory) { $memory.Dispose() }
        if ($stream) { $stream.Dispose() }
        if ($response) { $response.Close() }
    }
}


function Resolve-AmdAbsoluteUrl {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$BaseUrl,

        [Parameter(Mandatory = $true)]
        [string]$Candidate
    )

    try {
        $base = New-Object System.Uri($BaseUrl)
        $resolved = New-Object System.Uri($base, $Candidate)
        return $resolved.AbsoluteUri
    }
    catch {
        return $null
    }
}

function Test-AmdAllowedDownloadHost {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Uri
    )

    try {
        $hostName = ([System.Uri]$Uri).DnsSafeHost.ToLowerInvariant()
    }
    catch {
        return $false
    }

    if ($hostName -eq 'amd.com') {
        return $true
    }

    return $hostName.EndsWith('.amd.com')
}

function Get-AmdPlatformInfo {
    [CmdletBinding()]
    param()

    $platformFamily = 'Unknown'

    if ($PSVersionTable.PSEdition -eq 'Desktop') {
        $platformFamily = 'Windows'
    }
    else {
        $isWindowsValue = $false
        $isLinuxValue = $false
        $isMacOSValue = $false

        $v = Get-Variable -Name IsWindows -ErrorAction SilentlyContinue
        if ($v) { $isWindowsValue = [bool]$v.Value }

        $v = Get-Variable -Name IsLinux -ErrorAction SilentlyContinue
        if ($v) { $isLinuxValue = [bool]$v.Value }

        $v = Get-Variable -Name IsMacOS -ErrorAction SilentlyContinue
        if ($v) { $isMacOSValue = [bool]$v.Value }

        if ($isWindowsValue) {
            $platformFamily = 'Windows'
        }
        elseif ($isLinuxValue) {
            $platformFamily = 'Linux'
        }
        elseif ($isMacOSValue) {
            $platformFamily = 'macOS'
        }
        elseif ([System.IO.Path]::DirectorySeparatorChar -eq '/') {
            $platformFamily = 'Unix'
        }
    }

    $osDescription = $null
    try {
        $osDescription = [System.Runtime.InteropServices.RuntimeInformation]::OSDescription
    }
    catch {
        if ($env:OS) { $osDescription = [string]$env:OS }
    }

    $osArchitecture = $null
    $processArchitecture = $null
    try {
        $osArchitecture = [System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture.ToString()
        $processArchitecture = [System.Runtime.InteropServices.RuntimeInformation]::ProcessArchitecture.ToString()
    }
    catch {
        if ($env:PROCESSOR_ARCHITECTURE) {
            $osArchitecture = [string]$env:PROCESSOR_ARCHITECTURE
            $processArchitecture = [string]$env:PROCESSOR_ARCHITECTURE
        }
    }

    return [pscustomobject]@{
        PlatformFamily = $platformFamily
        OSDescription = $osDescription
        OSArchitecture = $osArchitecture
        ProcessArchitecture = $processArchitecture
        DirectorySeparator = [string][System.IO.Path]::DirectorySeparatorChar
        PathSeparator = [string][System.IO.Path]::PathSeparator
    }
}

function Get-AmdCommandPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    $cmd = Get-Command $Name -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $cmd) {
        return $null
    }

    if ($cmd.PSObject.Properties['Source'] -and $cmd.Source) {
        return [string]$cmd.Source
    }

    if ($cmd.PSObject.Properties['Path'] -and $cmd.Path) {
        return [string]$cmd.Path
    }

    return [string]$cmd.Name
}

function Get-AmdLinuxPackageEvidence {
    [CmdletBinding()]
    param()

    $platform = Get-AmdPlatformInfo
    if ($platform.PlatformFamily -ne 'Linux') {
        return $null
    }

    $manager = 'Unknown'
    $installed = New-Object System.Collections.Generic.List[object]
    $queried = @()

    $dpkgQuery = Get-AmdCommandPath -Name 'dpkg-query'
    $rpm = Get-AmdCommandPath -Name 'rpm'
    $apk = Get-AmdCommandPath -Name 'apk'

    if ($dpkgQuery) {
        $manager = 'dpkg'
        $queried = @('7zip', 'p7zip-full', 'p7zip')

        foreach ($packageName in $queried) {
            try {
                $line = @(& $dpkgQuery '-W' '-f=${db:Status-Abbrev}|${Package}|${Version}\n' $packageName 2>$null | ForEach-Object { [string]$_ }) -join ''
                $line = $line.Trim()
                if ($line -match '^ii\s*\|([^|]+)\|(.+)$') {
                    $installed.Add([pscustomobject]@{
                        Name = $Matches[1]
                        Version = $Matches[2]
                        Status = 'Installed'
                    })
                }
            }
            catch {
                # An absent package is an expected negative query result.
            }
        }
    }
    elseif ($rpm) {
        $manager = 'rpm'
        $queried = @('7zip', 'p7zip', 'p7zip-plugins')

        foreach ($packageName in $queried) {
            try {
                $line = @(& $rpm '-q' '--qf' '%{NAME}|%{VERSION}-%{RELEASE}\n' $packageName 2>$null | ForEach-Object { [string]$_ }) -join ''
                $line = $line.Trim()
                if ($LASTEXITCODE -eq 0 -and $line -match '^([^|]+)\|(.+)$') {
                    $installed.Add([pscustomobject]@{
                        Name = $Matches[1]
                        Version = $Matches[2]
                        Status = 'Installed'
                    })
                }
            }
            catch {
            }
        }
    }
    elseif ($apk) {
        $manager = 'apk'
        $queried = @('7zip', 'p7zip')

        foreach ($packageName in $queried) {
            try {
                $lines = @(& $apk 'info' '-e' $packageName 2>$null | ForEach-Object { [string]$_ })
                if ($LASTEXITCODE -eq 0 -and $lines.Count -gt 0) {
                    $version = $null
                    try {
                        $version = (@(& $apk 'info' '-v' $packageName 2>$null | Select-Object -First 1 | ForEach-Object { [string]$_ }) -join '').Trim()
                    }
                    catch {
                    }
                    $installed.Add([pscustomobject]@{
                        Name = $packageName
                        Version = $version
                        Status = 'Installed'
                    })
                }
            }
            catch {
            }
        }
    }

    return [pscustomobject]@{
        PackageManager = $manager
        QueriedPackages = @($queried)
        InstalledPackages = $installed.ToArray()
        InstalledPackageCount = $installed.Count
    }
}

function Get-AmdSevenZipInfo {
    [CmdletBinding()]
    param(
        [string]$ExplicitPath
    )

    $platform = Get-AmdPlatformInfo
    $candidateNames = New-Object System.Collections.Generic.List[string]
    $candidatePaths = New-Object System.Collections.Generic.List[string]

    if ($ExplicitPath) {
        if (-not (Test-Path -LiteralPath $ExplicitPath -PathType Leaf)) {
            throw ('7-Zip path does not exist: {0}' -f $ExplicitPath)
        }

        $candidatePaths.Add((Resolve-Path -LiteralPath $ExplicitPath).Path)
    }
    else {
        if ($platform.PlatformFamily -eq 'Windows') {
            foreach ($name in @('7z.exe', '7zz.exe', '7za.exe')) {
                $candidateNames.Add($name)
            }

            if ($env:ProgramFiles) {
                $candidatePaths.Add((Join-Path $env:ProgramFiles '7-Zip\7z.exe'))
            }

            $programFilesX86 = [Environment]::GetEnvironmentVariable('ProgramFiles(x86)')
            if ($programFilesX86) {
                $candidatePaths.Add((Join-Path $programFilesX86 '7-Zip\7z.exe'))
            }
        }
        else {
            # Prefer the current native 7-Zip for Linux/macOS command (7zz).
            # Legacy p7zip command names remain supported as fallbacks.
            foreach ($name in @('7zz', '7z', '7za')) {
                $candidateNames.Add($name)
            }

            foreach ($path in @(
                '/usr/bin/7zz',
                '/usr/local/bin/7zz',
                '/opt/7zip/7zz',
                '/usr/bin/7z',
                '/usr/local/bin/7z',
                '/usr/bin/7za',
                '/opt/homebrew/bin/7zz',
                '/usr/local/bin/7zz'
            )) {
                $candidatePaths.Add($path)
            }
        }
    }

    $resolvedPath = $null
    $resolvedName = $null

    foreach ($name in $candidateNames) {
        $path = Get-AmdCommandPath -Name $name
        if ($path) {
            $resolvedPath = $path
            $resolvedName = $name
            break
        }
    }

    if (-not $resolvedPath) {
        foreach ($path in $candidatePaths) {
            if (Test-Path -LiteralPath $path -PathType Leaf) {
                $resolvedPath = (Resolve-Path -LiteralPath $path).Path
                $resolvedName = [System.IO.Path]::GetFileName($resolvedPath)
                break
            }
        }
    }

    $versionText = $null
    $implementation = $null
    $probeSucceeded = $false
    $packageEvidence = Get-AmdLinuxPackageEvidence

    if ($resolvedPath) {
        try {
            $probeOutput = @(& $resolvedPath 2>&1 | Select-Object -First 8 | ForEach-Object { [string]$_ })
            $versionText = ($probeOutput -join ' ').Trim()
            $probeSucceeded = $true

            if ($versionText -match '(?i)7-Zip') {
                $implementation = '7-Zip'
            }
            elseif ($resolvedName -match '(?i)^7z(?:a)?(?:\.exe)?$') {
                $implementation = '7-ZipCompatible'
            }
        }
        catch {
            $versionText = ('Version probe failed: {0}' -f $_.Exception.Message)
        }
    }

    $guidance = $null
    if ($resolvedPath -and -not $probeSucceeded) {
        $guidance = ('7-Zip candidate was found but could not be executed: {0}' -f $resolvedPath)
    }
    elseif (-not $resolvedPath) {
        if ($platform.PlatformFamily -eq 'Windows') {
            $guidance = 'Install 7-Zip, add 7z.exe to PATH, or pass -SevenZipPath.'
        }
        elseif ($platform.PlatformFamily -eq 'Linux') {
            $guidance = 'Install the native 7-Zip for Linux (preferred command: 7zz), use a distribution 7zip package, or pass -SevenZipPath. Legacy 7z/7za commands are accepted as fallbacks.'
        }
        else {
            $guidance = 'Install a 7-Zip command-line implementation and expose 7zz/7z/7za on PATH, or pass -SevenZipPath.'
        }
    }

    return [pscustomobject]@{
        Status = if ($resolvedPath -and $probeSucceeded) { 'Available' } elseif ($resolvedPath) { 'ProbeFailed' } else { 'NotFound' }
        Path = $resolvedPath
        CommandName = $resolvedName
        Implementation = $implementation
        VersionProbe = $versionText
        PackageEvidence = $packageEvidence
        PreferredCommand = if ($platform.PlatformFamily -eq 'Windows') { '7z.exe' } else { '7zz' }
        Guidance = $guidance
    }
}

function Get-AmdSevenZipPath {
    [CmdletBinding()]
    param(
        [string]$ExplicitPath
    )

    $info = Get-AmdSevenZipInfo -ExplicitPath $ExplicitPath
    if ($info.Status -ne 'Available') {
        throw ('7-Zip was not found. {0}' -f $info.Guidance)
    }

    return [string]$info.Path
}

function Get-AmdInfDirectiveValue {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string[]]$Lines,

        [Parameter(Mandatory = $true)]
        [string]$Directive
    )

    $escaped = [regex]::Escape($Directive)
    $result = @()

    for ($i = 0; $i -lt $Lines.Count; $i++) {
        $line = $Lines[$i]
        $clean = ($line -split ';', 2)[0].Trim()

        $m = [regex]::Match(
            $clean,
            ('^\s*{0}\s*=\s*(.+?)\s*$' -f $escaped),
            [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
        )

        if ($m.Success) {
            $rawValue = $m.Groups[1].Value.Trim().Trim('"')
            $result += [pscustomobject]@{
                LineNumber = $i + 1
                Directive = $Directive
                RawValue = $rawValue
                RawLine = $line
            }
        }
    }

    return @($result)
}

function Get-AmdInfVersionSectionValue {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string[]]$Lines,

        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    $inVersion = $false
    $escaped = [regex]::Escape($Name)

    foreach ($line in $Lines) {
        $trimmed = $line.Trim()

        if ($trimmed -match '^\s*\[(.+?)\]\s*$') {
            $section = $Matches[1]
            $inVersion = ($section -ieq 'Version')
            continue
        }

        if (-not $inVersion) {
            continue
        }

        $clean = ($line -split ';', 2)[0].Trim()
        $m = [regex]::Match(
            $clean,
            ('^\s*{0}\s*=\s*(.+?)\s*$' -f $escaped),
            [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
        )

        if ($m.Success) {
            return $m.Groups[1].Value.Trim().Trim('"')
        }
    }

    return $null
}

function Get-AmdInfHardwareIds {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string[]]$Lines
    )

    $ids = New-Object System.Collections.Generic.List[string]
    $pattern = '(?i)(?:PCI|ACPI|USB|HID|ROOT|SWD|BTH|I2C|VMBUS)\\[A-Z0-9_&\\\-\.]+'

    foreach ($line in $Lines) {
        $clean = ($line -split ';', 2)[0]

        foreach ($m in [regex]::Matches($clean, $pattern)) {
            $value = $m.Value.Trim().Trim('"', ',')
            if ($value -and -not $ids.Contains($value)) {
                $ids.Add($value)
            }
        }
    }

    return $ids.ToArray()
}



function Remove-AmdInfComment {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]$Line
    )

    $inQuote = $false
    for ($i = 0; $i -lt $Line.Length; $i++) {
        $c = $Line[$i]
        if ($c -eq '"') {
            $inQuote = -not $inQuote
            continue
        }
        if ($c -eq ';' -and -not $inQuote) {
            return $Line.Substring(0, $i)
        }
    }
    return $Line
}

function Read-AmdInfDocument {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    $resolved = (Resolve-Path -LiteralPath $Path).Path
    $bytes = [System.IO.File]::ReadAllBytes($resolved)
    $text = $null
    $encodingName = $null

    if ($bytes.Length -ge 2 -and $bytes[0] -eq 0xFF -and $bytes[1] -eq 0xFE) {
        $text = [System.Text.Encoding]::Unicode.GetString($bytes, 2, $bytes.Length - 2)
        $encodingName = 'UTF-16LE-BOM'
    }
    elseif ($bytes.Length -ge 2 -and $bytes[0] -eq 0xFE -and $bytes[1] -eq 0xFF) {
        $text = [System.Text.Encoding]::BigEndianUnicode.GetString($bytes, 2, $bytes.Length - 2)
        $encodingName = 'UTF-16BE-BOM'
    }
    elseif ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
        $text = [System.Text.Encoding]::UTF8.GetString($bytes, 3, $bytes.Length - 3)
        $encodingName = 'UTF-8-BOM'
    }
    else {
        try {
            $strictUtf8 = New-Object System.Text.UTF8Encoding($false, $true)
            $text = $strictUtf8.GetString($bytes)
            $encodingName = 'UTF-8/ASCII'
        }
        catch {
            try {
                $text = [System.Text.Encoding]::GetEncoding(1252).GetString($bytes)
                $encodingName = 'Windows-1252-fallback'
            }
            catch {
                $text = [System.Text.Encoding]::Default.GetString($bytes)
                $encodingName = 'SystemDefault-fallback'
            }
        }
    }

    $lines = @($text -split "`r?`n")
    return [pscustomobject][ordered]@{
        Path = $resolved
        Encoding = $encodingName
        Text = $text
        Lines = @($lines)
    }
}

function ConvertTo-AmdInfSections {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string[]]$Lines
    )

    $sections = New-Object System.Collections.Generic.List[object]
    $currentName = $null
    $currentStart = 0
    $body = New-Object System.Collections.Generic.List[object]

    for ($i = 0; $i -lt $Lines.Count; $i++) {
        $line = $Lines[$i]
        $trimmed = $line.Trim()
        $m = [regex]::Match($trimmed, '^\[([^\]]+)\]$')
        if ($m.Success) {
            if ($null -ne $currentName) {
                $sections.Add([pscustomobject][ordered]@{
                    Name = $currentName
                    StartLine = $currentStart
                    EndLine = $i
                    Lines = @($body.ToArray())
                })
            }
            $currentName = $m.Groups[1].Value.Trim()
            $currentStart = $i + 1
            $body = New-Object System.Collections.Generic.List[object]
            continue
        }
        if ($null -ne $currentName) {
            $body.Add([pscustomobject][ordered]@{
                LineNumber = $i + 1
                RawLine = $line
            })
        }
    }

    if ($null -ne $currentName) {
        $sections.Add([pscustomobject][ordered]@{
            Name = $currentName
            StartLine = $currentStart
            EndLine = $Lines.Count
            Lines = @($body.ToArray())
        })
    }

    return @($sections.ToArray())
}

function Get-AmdInfSectionByName {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][object[]]$Sections,
        [Parameter(Mandatory = $true)][string]$Name
    )
    return @($Sections | Where-Object { [string]$_.Name -ieq $Name } | Select-Object -First 1)
}

function Get-AmdInfStringTable {
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)][object[]]$Sections)

    $table = @{}
    $orderedSections = @(
        @($Sections | Where-Object { [string]$_.Name -ieq 'Strings' }) +
        @($Sections | Where-Object { [string]$_.Name -ilike 'Strings.*' })
    )
    foreach ($section in $orderedSections) {
        foreach ($entry in @($section.Lines)) {
            $clean = (Remove-AmdInfComment -Line ([string]$entry.RawLine)).Trim()
            if (-not $clean) { continue }
            $m = [regex]::Match($clean, '^\s*([^\s=;]+)\s*=\s*(.*?)\s*$')
            if (-not $m.Success) { continue }
            $key = $m.Groups[1].Value.Trim()
            $value = $m.Groups[2].Value.Trim().Trim('"')
            if ($key -and -not $table.ContainsKey($key)) {
                $table[$key] = $value
            }
        }
    }
    return $table
}

function Resolve-AmdInfStringToken {
    [CmdletBinding()]
    param(
        [AllowNull()][string]$Value,
        [Parameter(Mandatory = $true)][hashtable]$Strings
    )
    if ($null -eq $Value) { return $null }
    $candidate = $Value.Trim().Trim('"')
    $m = [regex]::Match($candidate, '^%([^%]+)%$')
    if ($m.Success) {
        $key = $m.Groups[1].Value
        if ($Strings.ContainsKey($key)) { return [string]$Strings[$key] }
    }
    return $candidate
}

function ConvertTo-AmdInfInteger {
    [CmdletBinding()]
    param([AllowNull()][string]$Value)
    if ([string]::IsNullOrWhiteSpace($Value)) { return $null }
    $v = $Value.Trim()
    try {
        if ($v -match '^(?i)0x[0-9a-f]+$') {
            return [Convert]::ToInt32($v.Substring(2), 16)
        }
        return [int]$v
    }
    catch { return $null }
}

function Split-AmdInfCsv {
    [CmdletBinding()]
    param([AllowEmptyString()][string]$Text)
    $parts=New-Object System.Collections.Generic.List[string]
    if($null -eq $Text){return @()}
    $buffer=New-Object System.Text.StringBuilder;$quoted=$false
    for($i=0;$i -lt $Text.Length;$i++){$ch=$Text[$i];if($ch -eq '"'){$quoted=-not $quoted;[void]$buffer.Append($ch);continue};if($ch -eq ',' -and -not $quoted){$parts.Add($buffer.ToString().Trim());[void]$buffer.Clear();continue};[void]$buffer.Append($ch)}
    $parts.Add($buffer.ToString().Trim());return $parts.ToArray()
}

function ConvertFrom-AmdTargetOsVersionDecoration {
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)][string]$Decoration)

    $raw = $Decoration.Trim()
    $m = [regex]::Match($raw, '^NT(?<arch>x86|amd64|ia64|arm64|arm)?(?<rest>(?:\..*)?)$', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
    if (-not $m.Success) {
        return [pscustomobject][ordered]@{
            Raw = $raw; IsValid = $false; Architecture = $null; OSMajorVersion = $null; OSMinorVersion = $null
            ProductType = $null; ProductTypeName = $null; SuiteMask = $null; BuildNumber = $null
            IsTargetOsVersion = $false; IsPlatformOnly = $false; ParseNotes = @('UnrecognizedDecoration')
        }
    }

    $architecture = $m.Groups['arch'].Value.ToLowerInvariant()
    $rest = $m.Groups['rest'].Value
    $parts = @()
    if ($rest) {
        $payload = $rest.TrimStart('.')
        $parts = @($payload.Split([char]'.'))
    }
    while ($parts.Count -lt 5) { $parts += '' }

    $major = ConvertTo-AmdInfInteger -Value $parts[0]
    $minor = ConvertTo-AmdInfInteger -Value $parts[1]
    $productType = ConvertTo-AmdInfInteger -Value $parts[2]
    $suiteMask = ConvertTo-AmdInfInteger -Value $parts[3]
    $build = ConvertTo-AmdInfInteger -Value $parts[4]
    $notes = New-Object System.Collections.Generic.List[string]
    if ($parts.Count -gt 5) { $notes.Add('ExtraFieldsPresent') }
    if ($null -ne $build -and ($null -eq $major -or $null -eq $minor)) { $notes.Add('BuildWithoutMajorMinor') }
    if ($null -ne $productType -and @([int]1,[int]2,[int]3) -notcontains [int]$productType) { $notes.Add('UnrecognizedProductType') }

    $productName = switch ($productType) {
        1 { 'Workstation' }
        2 { 'DomainController' }
        3 { 'Server' }
        default { $null }
    }

    $hasTargetFields = ($null -ne $major -or $null -ne $minor -or $null -ne $productType -or $null -ne $suiteMask -or $null -ne $build)
    return [pscustomobject][ordered]@{
        Raw = $raw
        IsValid = $true
        Architecture = $architecture
        OSMajorVersion = $major
        OSMinorVersion = $minor
        ProductType = $productType
        ProductTypeName = $productName
        SuiteMask = $suiteMask
        BuildNumber = $build
        IsTargetOsVersion = $hasTargetFields
        IsPlatformOnly = (-not $hasTargetFields)
        ParseNotes = @($notes.ToArray())
    }
}

function Get-AmdInfIdentifierInfo {
    [CmdletBinding()]
    param(
        [AllowNull()]
        [string]$Identifier,

        [AllowNull()]
        [string]$InfClass
    )

    $raw = if ($null -eq $Identifier) { '' } else { $Identifier.Trim() }
    $className = if ($null -eq $InfClass) { '' } else { $InfClass.Trim() }
    $upper = $raw.ToUpperInvariant()

    $kind = 'UnclassifiedIdentifier'
    $display = 'Unclassified identifier'
    $enumerator = $null
    $isPnpHardwareId = $false
    $isSoftwareComponentId = $false
    $notes = New-Object System.Collections.Generic.List[string]

    if (-not $raw) {
        $kind = 'MissingIdentifier'
        $display = 'No device identifier declared'
        $notes.Add('Models entry did not provide a non-empty identifier.')
    }
    elseif ($upper -match '^ROOT\\') {
        $kind = 'RootEnumeratedHardwareId'
        $display = 'Root-enumerated PnP hardware ID'
        $enumerator = 'ROOT'
        $isPnpHardwareId = $true
    }
    elseif ($raw -match '^\{[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}\}\\.+$') {
        $kind = 'DeviceClassSpecificId'
        $display = 'Device-class-specific ID'
        $isPnpHardwareId = $true
        $notes.Add('The INF uses the device-class-specific hardware-ID form rather than a bus-enumerator ID such as PCI\\VEN_....')
    }
    elseif ($upper -match '^\*') {
        $kind = 'GenericHardwareId'
        $display = 'Generic PnP hardware ID'
        $isPnpHardwareId = $true
    }
    elseif ($raw -match '^([^\\]+)\\.+$') {
        $enumerator = $matches[1].ToUpperInvariant()
        $kind = 'EnumeratorHardwareId'
        $display = ('{0}-enumerated PnP hardware ID' -f $enumerator)
        $isPnpHardwareId = $true
    }
    elseif ($className -in @('NetService','NetTrans','NetClient')) {
        $kind = 'NetworkSoftwareComponentId'
        $display = 'Network software component ID'
        $isSoftwareComponentId = $true
        $notes.Add('Network software components use a component ID in the Models-section hw-id field; this is not a PCI/ACPI/USB bus hardware ID.')
    }
    elseif ($className -eq 'Net') {
        $kind = 'NetworkComponentOrSoftwareId'
        $display = 'Network component identifier'
        $isSoftwareComponentId = $true
        $notes.Add('The identifier is declared by a Net-class Models entry but does not use a bus-enumerator form; preserve it as an INF component identifier.')
    }
    else {
        $kind = 'InfModelIdentifier'
        $display = 'INF Models identifier'
        $notes.Add('The value is a valid Models-section identifier from the source INF but its namespace was not classified as a known bus/root/class-specific form.')
    }

    return [pscustomobject][ordered]@{
        Raw = $raw
        Kind = $kind
        DisplayName = $display
        Enumerator = $enumerator
        IsPnpHardwareId = $isPnpHardwareId
        IsSoftwareComponentId = $isSoftwareComponentId
        Notes = @($notes.ToArray())
    }
}

function Get-AmdInfTopology {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][object]$Document
    )

    $sections = @(ConvertTo-AmdInfSections -Lines @($Document.Lines))
    $strings = Get-AmdInfStringTable -Sections $sections
    $infClass = ''
    $versionSection = @($sections | Where-Object { [string]$_.Name -ieq 'Version' } | Select-Object -First 1)
    if ($versionSection.Count -gt 0) {
        foreach ($versionLine in @($versionSection[0].Lines)) {
            $versionClean = (Remove-AmdInfComment -Line ([string]$versionLine.RawLine)).Trim()
            $versionMatch = [regex]::Match($versionClean, '^\s*Class\s*=\s*(.+?)\s*$', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
            if ($versionMatch.Success) {
                $infClass = (Resolve-AmdInfStringToken -Value $versionMatch.Groups[1].Value.Trim().Trim('\"') -Strings $strings)
                break
            }
        }
    }
    $warnings = New-Object System.Collections.Generic.List[string]
    $manufacturerEntries = New-Object System.Collections.Generic.List[object]
    $modelsBaseNames = New-Object System.Collections.Generic.List[string]

    foreach ($manufacturerSection in @($sections | Where-Object { [string]$_.Name -ieq 'Manufacturer' })) {
        foreach ($lineEntry in @($manufacturerSection.Lines)) {
            $rawLine = [string]$lineEntry.RawLine
            $clean = (Remove-AmdInfComment -Line $rawLine).Trim()
            if (-not $clean) { continue }
            $m = [regex]::Match($clean, '^\s*([^=]+?)\s*=\s*(.+?)\s*$')
            if (-not $m.Success) {
                $warnings.Add(('Unparsed Manufacturer line {0}: {1}' -f $lineEntry.LineNumber, $rawLine))
                continue
            }
            $labelRaw = $m.Groups[1].Value.Trim()
            $rhsParts = @(Split-AmdInfCsv -Text $m.Groups[2].Value | ForEach-Object { $_.Trim() })
            if ($rhsParts.Count -lt 1 -or -not $rhsParts[0]) { continue }
            $base = $rhsParts[0]
            if (-not $modelsBaseNames.Contains($base)) { $modelsBaseNames.Add($base) }
            $decorations = New-Object System.Collections.Generic.List[object]
            for ($j = 1; $j -lt $rhsParts.Count; $j++) {
                if (-not $rhsParts[$j]) { continue }
                $decorations.Add((ConvertFrom-AmdTargetOsVersionDecoration -Decoration $rhsParts[$j]))
            }
            $manufacturerEntries.Add([pscustomobject][ordered]@{
                LineNumber = [int]$lineEntry.LineNumber
                RawLine = $rawLine
                ManufacturerRaw = $labelRaw
                ManufacturerName = Resolve-AmdInfStringToken -Value $labelRaw -Strings $strings
                ModelsSectionBase = $base
                Decorations = @($decorations.ToArray())
            })
        }
    }

    $modelSections = New-Object System.Collections.Generic.List[object]
    foreach ($base in $modelsBaseNames.ToArray()) {
        # Only sections reachable from [Manufacturer] are Models sections.
        # Do not wildcard-scan Base.NT* because real AMD INFs can have DDInstall
        # or .Wdf sections that share the manufacturer base prefix (for example
        # AmdMicroPEP.NTamd64.Wdf). Treating those as Models creates bogus devices.
        $allowedSectionNames = New-Object System.Collections.Generic.List[string]
        if (-not $allowedSectionNames.Contains($base)) { $allowedSectionNames.Add($base) }
        foreach ($mfgEntry in @($manufacturerEntries.ToArray() | Where-Object { [string]$_.ModelsSectionBase -ieq $base })) {
            foreach ($dec in @($mfgEntry.Decorations)) {
                $candidateName = $base + '.' + [string]$dec.Raw
                if (-not $allowedSectionNames.Contains($candidateName)) { $allowedSectionNames.Add($candidateName) }
            }
        }
        foreach ($section in $sections) {
            $sectionName = [string]$section.Name
            if (-not (@($allowedSectionNames.ToArray() | Where-Object { $_ -ieq $sectionName }).Count -gt 0)) { continue }
            $decorationRaw = $null
            if ($sectionName.Length -gt $base.Length -and $sectionName.Substring(0, $base.Length) -ieq $base) {
                $decorationRaw = $sectionName.Substring($base.Length + 1)
            }
            $models = New-Object System.Collections.Generic.List[object]
            foreach ($lineEntry in @($section.Lines)) {
                $rawLine = [string]$lineEntry.RawLine
                $clean = (Remove-AmdInfComment -Line $rawLine).Trim()
                if (-not $clean) { continue }
                $m = [regex]::Match($clean, '^\s*(.+?)\s*=\s*(.+?)\s*$')
                if (-not $m.Success) { continue }
                $descriptionRaw = $m.Groups[1].Value.Trim()
                $rhsParts = @(Split-AmdInfCsv -Text $m.Groups[2].Value | ForEach-Object { $_.Trim().Trim('"') })
                if ($rhsParts.Count -lt 2) { continue }
                $installSection = $rhsParts[0]
                $hardwareId = Resolve-AmdInfStringToken -Value $rhsParts[1] -Strings $strings
                $compatible = @()
                if ($rhsParts.Count -gt 2) {
                    $compatible = @($rhsParts[2..($rhsParts.Count - 1)] | ForEach-Object { Resolve-AmdInfStringToken -Value $_ -Strings $strings } | Where-Object { $_ })
                }
                $models.Add([pscustomobject][ordered]@{
                    LineNumber = [int]$lineEntry.LineNumber
                    RawLine = $rawLine
                    DescriptionRaw = $descriptionRaw
                    Description = Resolve-AmdInfStringToken -Value $descriptionRaw -Strings $strings
                    InstallSection = $installSection
                    HardwareId = $hardwareId
                    Identifier = Get-AmdInfIdentifierInfo -Identifier $hardwareId -InfClass $infClass
                    CompatibleIds = @($compatible)
                    CompatibleIdentifiers = @($compatible | ForEach-Object { Get-AmdInfIdentifierInfo -Identifier ([string]$_) -InfClass $infClass })
                })
            }
            $modelSections.Add([pscustomobject][ordered]@{
                SectionName = $sectionName
                ModelsSectionBase = $base
                DecorationRaw = $decorationRaw
                Decoration = if ($decorationRaw) { ConvertFrom-AmdTargetOsVersionDecoration -Decoration $decorationRaw } else { $null }
                StartLine = [int]$section.StartLine
                EndLine = [int]$section.EndLine
                IsEmpty = ($models.Count -eq 0)
                ModelCount = $models.Count
                Models = @($models.ToArray())
            })
        }
    }

    return [pscustomobject][ordered]@{
        SchemaVersion = 'amd-inf-topology/1.1'
        SharedContractVersion = $script:AmdInfSemanticContractVersion
        IdentifierTaxonomyVersion = $script:AmdInfIdentifierTaxonomyVersion
        Encoding = [string]$Document.Encoding
        ManufacturerEntryCount = $manufacturerEntries.Count
        ManufacturerEntries = @($manufacturerEntries.ToArray())
        ModelsSectionCount = $modelSections.Count
        ModelsSections = @($modelSections.ToArray())
        ParseWarnings = @($warnings.ToArray())
    }
}

function Get-AmdWindowsServerProfiles {
    [CmdletBinding()]
    param()
    return @(
        [pscustomobject][ordered]@{ Id='windows-server-2016'; ProfileId='windows-server-2016'; Name='Windows Server 2016'; ShortName='WS2016'; Architecture='amd64'; OSMajorVersion=10; OSMinorVersion=0; BuildNumber=14393; ProductType=3; SuiteMask=$null; DocumentedKMDF='1.19'; ObservedKMDF=$null; DocumentedUMDF='2.19'; ObservedUMDF=$null; WdfConfidence='PublishedReference'; OSMajor=10; OSMinor=0; Build=14393; Kmdf=[pscustomobject]@{Documented='1.19';Observed=$null}; Umdf=[pscustomobject]@{Documented='2.19';Observed=$null} },
        [pscustomobject][ordered]@{ Id='windows-server-2019'; ProfileId='windows-server-2019'; Name='Windows Server 2019'; ShortName='WS2019'; Architecture='amd64'; OSMajorVersion=10; OSMinorVersion=0; BuildNumber=17763; ProductType=3; SuiteMask=$null; DocumentedKMDF='1.27'; ObservedKMDF='1.27'; DocumentedUMDF='2.27'; ObservedUMDF=$null; WdfConfidence='IncludedVersion+Observed'; OSMajor=10; OSMinor=0; Build=17763; Kmdf=[pscustomobject]@{Documented='1.27';Observed='1.27'}; Umdf=[pscustomobject]@{Documented='2.27';Observed=$null} },
        [pscustomobject][ordered]@{ Id='windows-server-2022'; ProfileId='windows-server-2022'; Name='Windows Server 2022'; ShortName='WS2022'; Architecture='amd64'; OSMajorVersion=10; OSMinorVersion=0; BuildNumber=20348; ProductType=3; SuiteMask=$null; DocumentedKMDF='1.33'; ObservedKMDF=$null; DocumentedUMDF='2.33'; ObservedUMDF=$null; WdfConfidence='IncludedVersion'; OSMajor=10; OSMinor=0; Build=20348; Kmdf=[pscustomobject]@{Documented='1.33';Observed=$null}; Umdf=[pscustomobject]@{Documented='2.33';Observed=$null} },
        [pscustomobject][ordered]@{ Id='windows-server-2025'; ProfileId='windows-server-2025'; Name='Windows Server 2025'; ShortName='WS2025'; Architecture='amd64'; OSMajorVersion=10; OSMinorVersion=0; BuildNumber=26100; ProductType=3; SuiteMask=$null; DocumentedKMDF='1.33'; ObservedKMDF='1.35'; DocumentedUMDF='2.33'; ObservedUMDF=$null; WdfConfidence='PublishedReference+ObservedKMDF'; OSMajor=10; OSMinor=0; Build=26100; Kmdf=[pscustomobject]@{Documented='1.33';Observed='1.35'}; Umdf=[pscustomobject]@{Documented='2.33';Observed=$null} }
    )
}

function Get-AmdTargetOsApplicability {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][object]$Decoration,
        [Parameter(Mandatory = $true)][object]$Profile,
        [ValidateSet('AsPublished','ServerProjection')][string]$Mode = 'AsPublished'
    )

    $reasons = New-Object System.Collections.Generic.List[string]
    if (-not $Decoration.IsValid) {
        return [pscustomobject][ordered]@{ Applicability='Indeterminate'; RankScore=[int64]-1; ProjectionApplied=$false; EffectiveProductType=$null; Reasons=@('InvalidDecoration') }
    }

    $projectionApplied = $false
    $effectiveProductType = $Decoration.ProductType
    if ($Mode -eq 'ServerProjection' -and $Decoration.ProductType -eq 1) {
        $effectiveProductType = 3
        $projectionApplied = $true
    }

    if ($Decoration.Architecture -and ([string]$Decoration.Architecture -ine [string]$Profile.Architecture)) {
        $reasons.Add('ArchitectureMismatch')
        return [pscustomobject][ordered]@{ Applicability='NotApplicable'; RankScore=[int64]-1; ProjectionApplied=$projectionApplied; EffectiveProductType=$effectiveProductType; Reasons=@($reasons.ToArray()) }
    }

    if ($null -ne $Decoration.OSMajorVersion) {
        if ([int]$Profile.OSMajorVersion -lt [int]$Decoration.OSMajorVersion) {
            $reasons.Add('OSVersionTooOld')
            return [pscustomobject][ordered]@{ Applicability='NotApplicable'; RankScore=[int64]-1; ProjectionApplied=$projectionApplied; EffectiveProductType=$effectiveProductType; Reasons=@($reasons.ToArray()) }
        }
        if ([int]$Profile.OSMajorVersion -eq [int]$Decoration.OSMajorVersion -and $null -ne $Decoration.OSMinorVersion) {
            if ([int]$Profile.OSMinorVersion -lt [int]$Decoration.OSMinorVersion) {
                $reasons.Add('OSVersionTooOld')
                return [pscustomobject][ordered]@{ Applicability='NotApplicable'; RankScore=[int64]-1; ProjectionApplied=$projectionApplied; EffectiveProductType=$effectiveProductType; Reasons=@($reasons.ToArray()) }
            }
            if ([int]$Profile.OSMinorVersion -eq [int]$Decoration.OSMinorVersion -and $null -ne $Decoration.BuildNumber) {
                if ([int]$Profile.BuildNumber -lt [int]$Decoration.BuildNumber) {
                    $reasons.Add('BuildTooOld')
                    return [pscustomobject][ordered]@{ Applicability='NotApplicable'; RankScore=[int64]-1; ProjectionApplied=$projectionApplied; EffectiveProductType=$effectiveProductType; Reasons=@($reasons.ToArray()) }
                }
            }
        }
    }

    if ($null -ne $effectiveProductType -and [int]$effectiveProductType -ne [int]$Profile.ProductType) {
        $reasons.Add('ProductTypeMismatch')
        return [pscustomobject][ordered]@{ Applicability='NotApplicable'; RankScore=[int64]-1; ProjectionApplied=$projectionApplied; EffectiveProductType=$effectiveProductType; Reasons=@($reasons.ToArray()) }
    }

    if ($null -ne $Decoration.SuiteMask) {
        if ($null -eq $Profile.SuiteMask) {
            $reasons.Add('SuiteMaskUnknown')
            return [pscustomobject][ordered]@{ Applicability='Indeterminate'; RankScore=[int64]-1; ProjectionApplied=$projectionApplied; EffectiveProductType=$effectiveProductType; Reasons=@($reasons.ToArray()) }
        }
        if (([int]$Profile.SuiteMask -band [int]$Decoration.SuiteMask) -ne [int]$Decoration.SuiteMask) {
            $reasons.Add('SuiteMaskMismatch')
            return [pscustomobject][ordered]@{ Applicability='NotApplicable'; RankScore=[int64]-1; ProjectionApplied=$projectionApplied; EffectiveProductType=$effectiveProductType; Reasons=@($reasons.ToArray()) }
        }
    }

    $majorRank = if ($null -ne $Decoration.OSMajorVersion) { [int64]$Decoration.OSMajorVersion } else { [int64]0 }
    $minorRank = if ($null -ne $Decoration.OSMinorVersion) { [int64]$Decoration.OSMinorVersion } else { [int64]0 }
    $buildRank = if ($null -ne $Decoration.BuildNumber) { [int64]$Decoration.BuildNumber } else { [int64]0 }
    $productRank = if ($null -ne $effectiveProductType) { [int64]1 } else { [int64]0 }
    $suiteRank = if ($null -ne $Decoration.SuiteMask) { [int64]1 } else { [int64]0 }
    $archRank = if ($Decoration.Architecture) { [int64]1 } else { [int64]0 }
    $rank = ($majorRank * [int64]1000000000000) + ($minorRank * [int64]10000000000) + ($buildRank * [int64]10000) + ($productRank * 100) + ($suiteRank * 10) + $archRank

    return [pscustomobject][ordered]@{
        Applicability = 'Applicable'
        RankScore = [int64]$rank
        ProjectionApplied = $projectionApplied
        EffectiveProductType = $effectiveProductType
        Reasons = @('TargetOsDecorationMatched')
    }
}

function Select-AmdModelsSectionForProfile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][object]$Topology,
        [Parameter(Mandatory = $true)][object]$ManufacturerEntry,
        [Parameter(Mandatory = $true)][object]$Profile,
        [ValidateSet('AsPublished','ServerProjection')][string]$Mode = 'AsPublished'
    )

    $base = [string]$ManufacturerEntry.ModelsSectionBase
    $candidates = New-Object System.Collections.Generic.List[object]
    $indeterminate = New-Object System.Collections.Generic.List[object]
    $failures = New-Object System.Collections.Generic.List[object]

    foreach ($decoration in @($ManufacturerEntry.Decorations)) {
        $test = Get-AmdTargetOsApplicability -Decoration $decoration -Profile $Profile -Mode $Mode
        $sectionName = $base + '.' + [string]$decoration.Raw
        $section = @($Topology.ModelsSections | Where-Object { [string]$_.SectionName -ieq $sectionName } | Select-Object -First 1)
        $entry = [pscustomobject][ordered]@{
            SectionName = $sectionName
            SourceDecoration = $decoration
            Evaluation = $test
            Section = if ($section.Count -gt 0) { $section[0] } else { $null }
        }
        if ($test.Applicability -eq 'Applicable') { $candidates.Add($entry) }
        elseif ($test.Applicability -eq 'Indeterminate') { $indeterminate.Add($entry) }
        else { $failures.Add($entry) }
    }

    $selected = $null
    if ($candidates.Count -gt 0) {
        $selected = @($candidates.ToArray() | Sort-Object { [int64]$_.Evaluation.RankScore } -Descending | Select-Object -First 1)[0]
    }

    if ($null -ne $selected) {
        $uncertainHigher = @($indeterminate.ToArray() | Where-Object { [int64]$_.Evaluation.RankScore -ge [int64]$selected.Evaluation.RankScore })
        if ($uncertainHigher.Count -gt 0) {
            return [pscustomobject][ordered]@{
                Status='SuiteDependent'; ManufacturerLineNumber=$ManufacturerEntry.LineNumber; ManufacturerName=$ManufacturerEntry.ManufacturerName
                ModelsSectionBase=$base; SelectedSection=$null; ProjectionApplied=$false; Models=@(); CandidateEvaluations=@($candidates.ToArray()+$indeterminate.ToArray()+$failures.ToArray())
            }
        }
        if ($null -eq $selected.Section) {
            return [pscustomobject][ordered]@{
                Status='MissingModelsSection'; ManufacturerLineNumber=$ManufacturerEntry.LineNumber; ManufacturerName=$ManufacturerEntry.ManufacturerName
                ModelsSectionBase=$base; SelectedSection=$selected.SectionName; ProjectionApplied=[bool]$selected.Evaluation.ProjectionApplied; Models=@(); CandidateEvaluations=@($candidates.ToArray()+$indeterminate.ToArray()+$failures.ToArray())
            }
        }
        $status = if ([bool]$selected.Section.IsEmpty) { 'ExplicitlyExcluded' } else { 'Applicable' }
        return [pscustomobject][ordered]@{
            Status=$status; ManufacturerLineNumber=$ManufacturerEntry.LineNumber; ManufacturerName=$ManufacturerEntry.ManufacturerName
            ModelsSectionBase=$base; SelectedSection=$selected.SectionName; ProjectionApplied=[bool]$selected.Evaluation.ProjectionApplied; Models=@($selected.Section.Models); CandidateEvaluations=@($candidates.ToArray()+$indeterminate.ToArray()+$failures.ToArray())
        }
    }

    # Microsoft documents an undecorated Models section as the fallback when no
    # TargetOSVersion section matches. Only use it when the section actually exists.
    $baseSection = @($Topology.ModelsSections | Where-Object { [string]$_.SectionName -ieq $base } | Select-Object -First 1)
    if ($baseSection.Count -gt 0) {
        $status = if ([bool]$baseSection[0].IsEmpty) { 'ExplicitlyExcluded' } else { 'ApplicableFallback' }
        return [pscustomobject][ordered]@{
            Status=$status; ManufacturerLineNumber=$ManufacturerEntry.LineNumber; ManufacturerName=$ManufacturerEntry.ManufacturerName
            ModelsSectionBase=$base; SelectedSection=$base; ProjectionApplied=$false; Models=@($baseSection[0].Models); CandidateEvaluations=@($candidates.ToArray()+$indeterminate.ToArray()+$failures.ToArray())
        }
    }

    if ($indeterminate.Count -gt 0) {
        return [pscustomobject][ordered]@{
            Status='SuiteDependent'; ManufacturerLineNumber=$ManufacturerEntry.LineNumber; ManufacturerName=$ManufacturerEntry.ManufacturerName
            ModelsSectionBase=$base; SelectedSection=$null; ProjectionApplied=$false; Models=@(); CandidateEvaluations=@($indeterminate.ToArray()+$failures.ToArray())
        }
    }

    $allReasonCodes = @($failures.ToArray() | ForEach-Object { @($_.Evaluation.Reasons) } | ForEach-Object { $_ })
    $status = if ($allReasonCodes -contains 'BuildTooOld') { 'NotApplicableByBuild' }
        elseif ($allReasonCodes -contains 'ProductTypeMismatch') { 'NotApplicableByProductType' }
        elseif ($allReasonCodes -contains 'ArchitectureMismatch') { 'NotApplicableByArchitecture' }
        elseif ($allReasonCodes -contains 'OSVersionTooOld') { 'NotApplicableByOsVersion' }
        elseif ($allReasonCodes -contains 'SuiteMaskMismatch') { 'NotApplicableBySuite' }
        else { 'NoMatchingModelsSection' }
    return [pscustomobject][ordered]@{
        Status=$status; ManufacturerLineNumber=$ManufacturerEntry.LineNumber; ManufacturerName=$ManufacturerEntry.ManufacturerName
        ModelsSectionBase=$base; SelectedSection=$null; ProjectionApplied=$false; Models=@(); CandidateEvaluations=@($failures.ToArray())
    }
}

function ConvertTo-AmdComparableVersion {
    [CmdletBinding()]
    param([AllowNull()][string]$Value)
    if ([string]::IsNullOrWhiteSpace($Value)) { return $null }
    try { return [version]$Value.Trim() } catch { return $null }
}

function Get-AmdMaxWdfVersion {
    [CmdletBinding()]
    param([AllowNull()][object]$Framework)
    if ($null -eq $Framework -or $Framework.Status -ne 'Declared') { return $null }
    $parsed = @(@($Framework.Versions) | ForEach-Object { ConvertTo-AmdComparableVersion -Value ([string]$_) } | Where-Object { $null -ne $_ } | Sort-Object -Descending)
    if ($parsed.Count -eq 0) { return $null }
    return $parsed[0]
}

function Get-AmdWdfProfileAssessment {
    [CmdletBinding()]
    param(
        [AllowNull()][object]$Wdf,
        [Parameter(Mandatory = $true)][object]$Profile
    )

    function _AssessFramework {
        param([object]$Framework, [string]$Documented, [string]$Observed, [string]$Name)
        if ($null -eq $Framework -or $Framework.Status -ne 'Declared') {
            return [pscustomobject][ordered]@{ Framework=$Name; Status='NotDeclared'; Required=$null; DocumentedReference=$Documented; ObservedReference=$Observed }
        }
        $required = Get-AmdMaxWdfVersion -Framework $Framework
        if ($null -eq $required) {
            return [pscustomobject][ordered]@{ Framework=$Name; Status='UnparseableRequirement'; Required=(@($Framework.Versions) -join ','); DocumentedReference=$Documented; ObservedReference=$Observed }
        }
        $doc = ConvertTo-AmdComparableVersion -Value $Documented
        $obs = ConvertTo-AmdComparableVersion -Value $Observed
        if ($null -ne $doc -and $required -le $doc) {
            return [pscustomobject][ordered]@{ Framework=$Name; Status='SatisfiedByDocumentedReference'; Required=$required.ToString(); DocumentedReference=$Documented; ObservedReference=$Observed }
        }
        if ($null -ne $obs -and $required -le $obs) {
            return [pscustomobject][ordered]@{ Framework=$Name; Status='SatisfiedByObservedReference'; Required=$required.ToString(); DocumentedReference=$Documented; ObservedReference=$Observed }
        }
        if ($null -ne $obs) {
            return [pscustomobject][ordered]@{ Framework=$Name; Status='ExceedsObservedReference'; Required=$required.ToString(); DocumentedReference=$Documented; ObservedReference=$Observed }
        }
        if ($null -ne $doc) {
            return [pscustomobject][ordered]@{ Framework=$Name; Status='ExceedsDocumentedReference'; Required=$required.ToString(); DocumentedReference=$Documented; ObservedReference=$Observed }
        }
        return [pscustomobject][ordered]@{ Framework=$Name; Status='NoHostReference'; Required=$required.ToString(); DocumentedReference=$Documented; ObservedReference=$Observed }
    }

    $kmdf = _AssessFramework -Framework $(if ($Wdf) { $Wdf.KMDF } else { $null }) -Documented $Profile.DocumentedKMDF -Observed $Profile.ObservedKMDF -Name 'KMDF'
    $umdf = _AssessFramework -Framework $(if ($Wdf) { $Wdf.UMDF } else { $null }) -Documented $Profile.DocumentedUMDF -Observed $Profile.ObservedUMDF -Name 'UMDF'
    $overall = 'NoDeclaredRequirement'
    $statuses = @($kmdf.Status, $umdf.Status)
    if ($statuses -contains 'ExceedsObservedReference' -or $statuses -contains 'ExceedsDocumentedReference') { $overall = 'RequirementReview' }
    elseif ($statuses -contains 'UnparseableRequirement' -or $statuses -contains 'NoHostReference') { $overall = 'Indeterminate' }
    elseif ($statuses -contains 'SatisfiedByObservedReference') { $overall = 'SatisfiedWithObservedReference' }
    elseif ($statuses -contains 'SatisfiedByDocumentedReference') { $overall = 'Satisfied' }
    return [pscustomobject][ordered]@{ Overall=$overall; KMDF=$kmdf; UMDF=$umdf; Scope='InfWideConservative' }
}

function Get-AmdUniqueSelectedDevices {
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)][object[]]$Selections)
    $map = @{}
    foreach ($selection in $Selections) {
        if ($selection.Status -notin @('Applicable','ApplicableFallback')) { continue }
        foreach ($model in @($selection.Models)) {
            $key = ('{0}|{1}|{2}' -f [string]$model.HardwareId, [string]$model.InstallSection, [string]$model.Description).ToUpperInvariant()
            if (-not $map.ContainsKey($key)) {
                $map[$key] = [pscustomobject][ordered]@{
                    ManufacturerName = $selection.ManufacturerName
                    ModelsSection = $selection.SelectedSection
                    Description = $model.Description
                    DescriptionRaw = $model.DescriptionRaw
                    InstallSection = $model.InstallSection
                    HardwareId = $model.HardwareId
                    Identifier = if ($null -ne $model.PSObject.Properties['Identifier']) { $model.Identifier } else { $null }
                    CompatibleIds = @($model.CompatibleIds)
                    ProjectionApplied = [bool]$selection.ProjectionApplied
                }
            }
        }
    }
    return @($map.Values)
}

function Get-AmdServerApplicability {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][object]$Topology,
        [AllowNull()][object]$Wdf
    )

    $profiles = @(Get-AmdWindowsServerProfiles)
    $results = New-Object System.Collections.Generic.List[object]
    foreach ($profile in $profiles) {
        $nativeSelections = New-Object System.Collections.Generic.List[object]
        $projectionSelections = New-Object System.Collections.Generic.List[object]
        foreach ($mfg in @($Topology.ManufacturerEntries)) {
            $nativeSelections.Add((Select-AmdModelsSectionForProfile -Topology $Topology -ManufacturerEntry $mfg -Profile $profile -Mode 'AsPublished'))
            $projectionSelections.Add((Select-AmdModelsSectionForProfile -Topology $Topology -ManufacturerEntry $mfg -Profile $profile -Mode 'ServerProjection'))
        }
        $nativeDevices = @(Get-AmdUniqueSelectedDevices -Selections @($nativeSelections.ToArray()))
        $projectionDevicesAll = @(Get-AmdUniqueSelectedDevices -Selections @($projectionSelections.ToArray()))
        $projectionDevices = @($projectionDevicesAll | Where-Object { $_.ProjectionApplied })

        $nativeStatuses = @($nativeSelections.ToArray() | ForEach-Object { $_.Status })
        $projectionStatuses = @($projectionSelections.ToArray() | ForEach-Object { $_.Status })
        $nativeStatus = if ($nativeDevices.Count -gt 0) { 'NativeApplicable' }
            elseif ($nativeStatuses -contains 'ExplicitlyExcluded') { 'ExplicitlyExcluded' }
            elseif ($nativeStatuses -contains 'SuiteDependent') { 'SuiteDependent' }
            elseif ($nativeStatuses -contains 'NotApplicableByBuild') { 'NotApplicableByBuild' }
            elseif ($nativeStatuses -contains 'NotApplicableByProductType') { 'NotApplicableByProductType' }
            elseif ($nativeStatuses -contains 'NotApplicableByOsVersion') { 'NotApplicableByOsVersion' }
            elseif ($nativeStatuses -contains 'MissingModelsSection') { 'IndeterminateMissingSection' }
            else { 'NoMatchingModel' }
        $projectionStatus = if ($nativeDevices.Count -gt 0) { 'NotRequired' }
            elseif ($projectionDevices.Count -gt 0) { 'ProjectionCandidate' }
            elseif ($projectionStatuses -contains 'SuiteDependent') { 'SuiteDependent' }
            elseif ($projectionStatuses -contains 'ExplicitlyExcluded') { 'ExplicitlyExcluded' }
            else { 'NoProjectionCandidate' }

        $wdfAssessment = Get-AmdWdfProfileAssessment -Wdf $Wdf -Profile $profile
        $staticAssessment = if ($wdfAssessment.Overall -eq 'RequirementReview' -and ($nativeDevices.Count -gt 0 -or $projectionDevices.Count -gt 0)) { 'WdfRequirementReview' }
            elseif ($nativeDevices.Count -gt 0) { 'NativeCandidate' }
            elseif ($projectionDevices.Count -gt 0) { 'ProjectionCandidate' }
            elseif ($nativeStatus -eq 'SuiteDependent' -or $projectionStatus -eq 'SuiteDependent') { 'ReviewRequired' }
            else { 'NotApplicable' }

        $results.Add([pscustomobject][ordered]@{
            Profile = $profile
            AsPublishedStatus = $nativeStatus
            ServerProjectionStatus = $projectionStatus
            StaticAssessment = $staticAssessment
            CanonicalStaticAssessment = $staticAssessment
            AsPublishedSelections = @($nativeSelections.ToArray())
            ServerProjectionSelections = @($projectionSelections.ToArray())
            NativeDevices = @($nativeDevices)
            ProjectionDevices = @($projectionDevices)
            WdfAssessment = $wdfAssessment
            RuntimeCompatibilityProven = $false
        })
    }
    return @($results.ToArray())
}

function Invoke-AmdResearchEnvironmentTest {
    [CmdletBinding()]
    param(
        [string]$SevenZipPath,
        [string]$OutputPath
    )

    $toolRoot = Get-AmdResearchToolkitRoot
    if (-not $OutputPath) {
        $OutputPath = Join-Path $toolRoot 'inventory\environment.json'
    }

    $version = $PSVersionTable.PSVersion
    $engine = if ($PSVersionTable.PSEdition) { [string]$PSVersionTable.PSEdition } else { 'Desktop' }
    $platform = Get-AmdPlatformInfo
    $compiledSelectorSelfTest = Test-AmdCompiledSelectorContractSelfTest
    $architectureSelfTest = Test-AmdHostArchitectureNormalizationSelfTest
    $msiProjectionSelfTest = Test-AmdMsiTableNameProjectionSelfTest
    $msiColumnDiscoverySelfTest = Test-AmdMsiFieldCountIndependentColumnDiscoverySelfTest
    $msiTableRowPipelineIsolationSelfTest = Test-AmdMsiTableRowPipelineIsolationSelfTest
    $msiAssessmentSelfTest = Test-AmdMsiDeclarativeAssessmentSelfTest
    $portableNormalizationSelfTest = Test-AmdPortableAnalysisNormalizationSelfTest
    $publicationContractSelfTest = Test-AmdPublicationContractSelfTest
    $selfTestResults = @(
        $compiledSelectorSelfTest,
        $architectureSelfTest,
        $msiProjectionSelfTest,
        $msiColumnDiscoverySelfTest,
        $msiTableRowPipelineIsolationSelfTest,
        $msiAssessmentSelfTest,
        $portableNormalizationSelfTest,
        $publicationContractSelfTest
    )
    $selfTestsReady = (@($selfTestResults | Where-Object { [string]$_.Status -ne 'Pass' }).Count -eq 0)

    $runtimeSupported = $false
    if ($version.Major -gt 5) {
        $runtimeSupported = $true
    }
    elseif ($version.Major -eq 5 -and $version.Minor -ge 1) {
        $runtimeSupported = $true
    }

    $sevenZipInfo = $null
    try {
        $sevenZipInfo = Get-AmdSevenZipInfo -ExplicitPath $SevenZipPath
    }
    catch {
        $sevenZipInfo = [pscustomobject]@{
            Status = 'InvalidExplicitPath'
            Path = $null
            CommandName = $null
            Implementation = $null
            VersionProbe = $null
            PackageEvidence = Get-AmdLinuxPackageEvidence
            PreferredCommand = if ($platform.PlatformFamily -eq 'Windows') { '7z.exe' } else { '7zz' }
            Guidance = $_.Exception.Message
        }
    }

    $result = [pscustomobject]@{
        SchemaVersion = '1.0'
        ToolkitVersion = $script:AmdChipsetResearchToolkitVersion
        CollectedAtUtc = [DateTime]::UtcNow.ToString('o')
        Platform = $platform
        PowerShell = [pscustomobject]@{
            Version = $version.ToString()
            PSEdition = $engine
            RuntimeSupported = $runtimeSupported
        }
        Dependencies = [pscustomobject]@{
            SevenZip = $sevenZipInfo
        }
        Readiness = [pscustomobject]@{
            MetadataResearchReady = $runtimeSupported
            SelfTestsReady = $selfTestsReady
            FullResearchReady = ($runtimeSupported -and $selfTestsReady -and $sevenZipInfo.Status -eq 'Available')
        }
        SelfTests = [pscustomobject]@{
            CompiledSelectorContract = $compiledSelectorSelfTest
            HostArchitectureNormalization = $architectureSelfTest
            MsiTableNameProjection = $msiProjectionSelfTest
            MsiFieldCountIndependentColumnDiscovery = $msiColumnDiscoverySelfTest
            MsiTableRowPipelineIsolation = $msiTableRowPipelineIsolationSelfTest
            MsiDeclarativeAssessment = $msiAssessmentSelfTest
            PortableAnalysisNormalization = $portableNormalizationSelfTest
            PublicationContract = $publicationContractSelfTest
        }
    }

    Write-AmdJsonFile -Path $OutputPath -Value $result

    [pscustomobject]@{
        ToolkitVersion = $result.ToolkitVersion
        PlatformFamily = $platform.PlatformFamily
        OSDescription = $platform.OSDescription
        OSArchitecture = $platform.OSArchitecture
        PowerShellVersion = $version.ToString()
        PSEdition = $engine
        RuntimeSupported = $runtimeSupported
        MetadataResearchReady = $result.Readiness.MetadataResearchReady
        SevenZipStatus = $sevenZipInfo.Status
        SevenZipPath = $sevenZipInfo.Path
        SevenZipCommand = $sevenZipInfo.CommandName
        LinuxPackageManager = if ($sevenZipInfo.PackageEvidence) { $sevenZipInfo.PackageEvidence.PackageManager } else { $null }
        SevenZipPackageCount = if ($sevenZipInfo.PackageEvidence) { $sevenZipInfo.PackageEvidence.InstalledPackageCount } else { $null }
        SevenZipPreferredCommand = $sevenZipInfo.PreferredCommand
        SelfTestsReady = $result.Readiness.SelfTestsReady
        FullResearchReady = $result.Readiness.FullResearchReady
        CompiledSelectorContractSelfTest = $compiledSelectorSelfTest.Status
        HostArchitectureNormalizationSelfTest = $architectureSelfTest.Status
        MsiTableNameProjectionSelfTest = $msiProjectionSelfTest.Status
        MsiFieldCountIndependentColumnDiscoverySelfTest = $msiColumnDiscoverySelfTest.Status
        MsiTableRowPipelineIsolationSelfTest = $msiTableRowPipelineIsolationSelfTest.Status
        MsiDeclarativeAssessmentSelfTest = $msiAssessmentSelfTest.Status
        PortableAnalysisNormalizationSelfTest = $portableNormalizationSelfTest.Status
        PublicationContractSelfTest = $publicationContractSelfTest.Status
        EnvironmentEvidencePath = $OutputPath
        DependencyGuidance = $sevenZipInfo.Guidance
    }

    if (-not $runtimeSupported) {
        throw ('Unsupported PowerShell runtime: {0}. Windows PowerShell 5.1 or PowerShell 7.x is required.' -f $version)
    }
    if (-not $selfTestsReady) {
        $failedSelfTests = @($result.SelfTests.PSObject.Properties | Where-Object { [string]$_.Value.Status -ne 'Pass' } | ForEach-Object { $_.Name })
        throw ('Toolkit self-test failure(s): {0}. Inspect environment.json before continuing.' -f ($failedSelfTests -join ', '))
    }
}

function Invoke-AmdDiscoverStage {
    [CmdletBinding()]
    param(
        [string]$SeedPath,
        [string]$OutputPath,
        [string[]]$SitemapUri = @(
            'https://www.amd.com/en.sitemap.xml',
            'https://www.amd.com/sitemap.xml'
        ),
        [string[]]$AdditionalReleaseNotesUrl = @()
    )

    $toolRoot = Get-AmdResearchToolkitRoot

    if (-not $SeedPath) {
        $SeedPath = Join-Path $toolRoot 'data\seed-releases.json'
    }

    if (-not $OutputPath) {
        $OutputPath = Join-Path $toolRoot 'inventory\releases.json'
    }

    $records = New-Object System.Collections.Generic.List[object]
    $seenUrl = @{}

    function Add-ReleaseRecord {
        param(
            [string]$Version,
            [string]$Url,
            [string]$Source,
            [string]$Detail
        )

        if (-not $Url) { return }

        $key = $Url.ToLowerInvariant()
        if ($seenUrl.ContainsKey($key)) { return }

        if (-not $Version) {
            $Version = Get-AmdVersionFromText -Text $Url
        }

        $seenUrl[$key] = $true
        $records.Add([pscustomobject]@{
            ReleaseVersion = $Version
            ReleaseNotesUrl = $Url
            DiscoverySource = $Source
            DiscoveryDetail = $Detail
            DiscoveredAtUtc = [DateTime]::UtcNow.ToString('o')
            Status = 'Discovered'
        })
    }

    $seedCount = 0
    if (Test-Path -LiteralPath $SeedPath -PathType Leaf) {
        $seedData = Read-AmdJsonFile -Path $SeedPath
        foreach ($seed in @($seedData.Records)) {
            Add-ReleaseRecord `
                -Version ([string]$seed.ReleaseVersion) `
                -Url ([string]$seed.ReleaseNotesUrl) `
                -Source 'Seed' `
                -Detail ([string]$seed.Reason)
            $seedCount++
        }
    }
    Write-AmdStep ('Loaded {0} seed release record(s).' -f $seedCount)

    foreach ($url in $AdditionalReleaseNotesUrl) {
        Add-ReleaseRecord -Version $null -Url $url -Source 'Operator' -Detail 'Operator-supplied release-note URL.'
    }
    if ($AdditionalReleaseNotesUrl.Count -gt 0) {
        Write-AmdStep ('Added {0} operator-supplied release-note URL(s).' -f $AdditionalReleaseNotesUrl.Count)
    }

    $sitemapErrors = New-Object System.Collections.Generic.List[object]
    $sitemapIndex = 0
    foreach ($sitemap in $SitemapUri) {
        $sitemapIndex++
        $before = $records.Count
        Write-AmdStep ('Sitemap [{0}/{1}] fetch: {2}' -f $sitemapIndex, $SitemapUri.Count, $sitemap)

        $response = Invoke-AmdQuietTextRequest -Uri $sitemap
        if (-not $response.Success) {
            $sitemapErrors.Add([pscustomobject]@{ Uri=$sitemap; Error=$response.Error })
            Write-AmdCaution ('Sitemap [{0}/{1}] unavailable; continuing with seed/other sources: {2}' -f $sitemapIndex, $SitemapUri.Count, $response.Error)
            continue
        }

        $content = [string]$response.Content
        $trimmed = $content.TrimStart()
        if ($trimmed -match '(?is)^<!doctype\s+html\b|^<html\b') {
            $message = 'HTML content was returned where XML was expected.'
            $sitemapErrors.Add([pscustomobject]@{ Uri=$sitemap; Error=$message })
            Write-AmdSkip ('Sitemap [{0}/{1}] returned HTML instead of XML; fallback is expected and no raw page body will be emitted.' -f $sitemapIndex, $SitemapUri.Count)
            continue
        }

        try {
            $xml = ConvertFrom-AmdXmlText -Text $content -Source $sitemap
            $locNodes = @($xml.SelectNodes("//*[local-name()='loc']"))
            foreach ($node in $locNodes) {
                $url = [string]$node.InnerText
                if ($url -notmatch '(?i)/resources/support-articles/release-notes/') { continue }
                if ($url -notmatch '(?i)(RN-RYZEN-CHIPSET|chipset-driver-release-notes)') { continue }

                $version = Get-AmdVersionFromText -Text $url
                if (-not $version) { continue }

                Add-ReleaseRecord `
                    -Version $version `
                    -Url $url `
                    -Source 'AmdSitemap' `
                    -Detail $sitemap
            }
            Write-AmdOk ('Sitemap [{0}/{1}] parsed; +{2} unique release record(s).' -f $sitemapIndex, $SitemapUri.Count, ($records.Count - $before))
        }
        catch {
            $message = Get-AmdCompactErrorMessage -Message $_.Exception.Message -MaximumLength 300
            $sitemapErrors.Add([pscustomobject]@{ Uri=$sitemap; Error=$message })
            Write-AmdCaution ('Sitemap [{0}/{1}] parse skipped: {2}' -f $sitemapIndex, $SitemapUri.Count, $message)
        }
    }

    # Release-note URL is provenance, not identity. AMD can expose aliases or
    # unusual nested URLs for the same release, so normalize to one record per
    # four-part release version. Operator input has highest precedence, then
    # curated seed data, then sitemap discovery. Alternate URLs remain in
    # DiscoveryDiagnostics for auditability.
    $deduplicated = New-Object System.Collections.Generic.List[object]
    $duplicateVersionUrls = New-Object System.Collections.Generic.List[object]

    foreach ($group in @($records | Group-Object -Property ReleaseVersion)) {
        $candidates = @(
            $group.Group |
                Sort-Object `
                    @{ Expression = {
                        switch ([string]$_.DiscoverySource) {
                            'Operator'   { 30 }
                            'Seed'       { 20 }
                            'AmdSitemap' { 10 }
                            default      { 0 }
                        }
                    }; Descending = $true }, `
                    @{ Expression = { [string]$_.ReleaseNotesUrl } }
        )

        if ($candidates.Count -eq 0) { continue }

        $chosen = $candidates[0]
        $deduplicated.Add($chosen)

        if ($candidates.Count -gt 1) {
            for ($i = 1; $i -lt $candidates.Count; $i++) {
                $alternate = $candidates[$i]
                $duplicateVersionUrls.Add([pscustomobject]@{
                    ReleaseVersion = [string]$chosen.ReleaseVersion
                    SelectedUrl = [string]$chosen.ReleaseNotesUrl
                    SelectedSource = [string]$chosen.DiscoverySource
                    AlternateUrl = [string]$alternate.ReleaseNotesUrl
                    AlternateSource = [string]$alternate.DiscoverySource
                })
            }
        }
    }

    if ($duplicateVersionUrls.Count -gt 0) {
        Write-AmdSkip ('Discovery normalized {0} alternate release-note URL(s) to a single record per release version.' -f $duplicateVersionUrls.Count)
    }

    $sorted = @(
        $deduplicated |
            Sort-Object `
                @{ Expression = {
                    try { [version]$_.ReleaseVersion } catch { [version]'0.0.0.0' }
                } }, `
                ReleaseNotesUrl
    )

    $output = [pscustomobject]@{
        SchemaVersion = '1.0'
        ToolkitVersion = $script:AmdChipsetResearchToolkitVersion
        GeneratedAtUtc = [DateTime]::UtcNow.ToString('o')
        Completeness = 'BestEffort'
        ReleaseCount = $sorted.Count
        Releases = $sorted
        DiscoveryDiagnostics = [pscustomobject]@{
            SitemapErrors = $sitemapErrors.ToArray()
            DuplicateReleaseUrls = $duplicateVersionUrls.ToArray()
            SeedPath = $SeedPath
        }
    }

    Write-AmdJsonFile -Path $OutputPath -Value $output

    Write-AmdOk ('Discovery complete: {0} release(s).' -f $sorted.Count)
    Write-AmdDetail ('Output: {0}' -f $OutputPath)
}


function Get-AmdInstallerDownloadCandidates {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$ReleaseVersion,
        [Parameter(Mandatory = $true)][string]$ReleaseNotesUrl,
        [AllowEmptyString()][string]$Html
    )

    $results = New-Object System.Collections.Generic.List[string]

    function Add-Candidate {
        param([string]$Value)
        if ([string]::IsNullOrWhiteSpace($Value)) { return }
        $decoded = [System.Net.WebUtility]::HtmlDecode($Value.Trim())
        if ($decoded -notmatch [regex]::Escape($ReleaseVersion)) { return }
        if ($decoded -notmatch '(?i)^https://drivers\.amd\.com/drivers/') { return }
        if ($decoded -notmatch '(?i)\.(exe|zip)(?:[?#].*)?$') { return }
        if ($decoded -notmatch '(?i)/(amd(?:_chipset)?_software_|amd_chipset_software_win10_)') { return }
        if (-not $results.Contains($decoded)) { $results.Add($decoded) }
    }

    if ($Html) {
        $directPattern = '(?i)https://drivers\.amd\.com/drivers/(?:amd(?:_chipset)?_software_|amd_chipset_software_win10_)[A-Za-z0-9._-]+\.(?:exe|zip)'
        foreach ($m in [regex]::Matches($Html, $directPattern)) { Add-Candidate -Value $m.Value }
        foreach ($m in [regex]::Matches($Html, '(?is)href\s*=\s*["'']([^"'']+)["'']')) {
            $absolute = Resolve-AmdAbsoluteUrl -BaseUrl $ReleaseNotesUrl -Candidate $m.Groups[1].Value
            Add-Candidate -Value $absolute
        }
    }

    $major = 0
    try { $major = [int]($ReleaseVersion.Split('.')[0]) } catch { }
    if ($major -le 3) {
        $generated = @(
            ('https://drivers.amd.com/drivers/amd_chipset_software_{0}.zip' -f $ReleaseVersion),
            ('https://drivers.amd.com/drivers/amd_chipset_software_win10_{0}.zip' -f $ReleaseVersion),
            ('https://drivers.amd.com/drivers/amd_software_{0}.zip' -f $ReleaseVersion),
            ('https://drivers.amd.com/drivers/amd_chipset_software_{0}.exe' -f $ReleaseVersion),
            ('https://drivers.amd.com/drivers/amd_software_{0}.exe' -f $ReleaseVersion)
        )
    }
    else {
        $generated = @(
            ('https://drivers.amd.com/drivers/amd_chipset_software_{0}.exe' -f $ReleaseVersion),
            ('https://drivers.amd.com/drivers/amd_software_{0}.exe' -f $ReleaseVersion),
            ('https://drivers.amd.com/drivers/amd_chipset_software_{0}.zip' -f $ReleaseVersion)
        )
    }
    foreach ($candidate in $generated) { Add-Candidate -Value $candidate }

    return $results.ToArray()
}

function Invoke-AmdMetadataStage {
    [CmdletBinding()]
    param(
        [string]$ReleasesPath,
        [string]$OutputPath,
        [string]$EvidenceDirectory,
        [switch]$Force
    )

    $toolRoot = Get-AmdResearchToolkitRoot

    if (-not $ReleasesPath) { $ReleasesPath = Join-Path $toolRoot 'inventory\releases.json' }
    if (-not $OutputPath) { $OutputPath = Join-Path $toolRoot 'inventory\release-metadata.json' }
    if (-not $EvidenceDirectory) { $EvidenceDirectory = Join-Path $toolRoot 'evidence\release-notes' }

    New-AmdDirectory -Path $EvidenceDirectory | Out-Null

    $releaseData = Read-AmdJsonFile -Path $ReleasesPath
    $releaseItems = @($releaseData.Releases)
    $releaseTotal = $releaseItems.Count
    $releaseIndex = 0
    $results = New-Object System.Collections.Generic.List[object]

    Write-AmdStep ('Collecting release-note metadata for {0} release(s).' -f $releaseTotal)

    foreach ($release in $releaseItems) {
        $releaseIndex++
        $itemSw = [System.Diagnostics.Stopwatch]::StartNew()
        $version = [string]$release.ReleaseVersion
        $url = [string]$release.ReleaseNotesUrl

        Write-AmdStep ('Metadata [{0}/{1}] {2}' -f $releaseIndex, $releaseTotal, $version)

        $safe = if ($version) { ConvertTo-AmdSafeName -Value $version } else { Get-AmdStringSha256 -Text $url }
        $htmlPath = Join-Path $EvidenceDirectory ($safe + '.html')

        $status = 'Fetched'
        $errorText = $null
        $html = $null

        if ((Test-Path -LiteralPath $htmlPath -PathType Leaf) -and -not $Force) {
            try {
                $html = Read-AmdTextFile -Path $htmlPath
                $status = 'Cached'
            }
            catch {
                $status = 'FetchFailed'
                $errorText = Get-AmdCompactErrorMessage -Message $_.Exception.Message -MaximumLength 300
            }
        }
        else {
            $response = Invoke-AmdQuietTextRequest -Uri $url
            if ($response.Success) {
                $html = [string]$response.Content
                try {
                    Write-AmdUtf8NoBom -Path $htmlPath -Text $html
                }
                catch {
                    $status = 'FetchFailed'
                    $errorText = Get-AmdCompactErrorMessage -Message $_.Exception.Message -MaximumLength 300
                    $html = $null
                }
            }
            else {
                $status = 'FetchFailed'
                $errorText = $response.Error
            }
        }

        $title = $null
        $articleNumber = $null
        $downloadUrls = @()
        $htmlSha256 = $null

        if ($html) {
            $htmlSha256 = Get-AmdStringSha256 -Text $html

            $titleMatch = [regex]::Match($html, '(?is)<title[^>]*>(.*?)</title>')
            if ($titleMatch.Success) {
                $title = [System.Net.WebUtility]::HtmlDecode(
                    ([regex]::Replace($titleMatch.Groups[1].Value, '<[^>]+>', '')).Trim()
                )
            }

            $plain = [System.Net.WebUtility]::HtmlDecode(
                [regex]::Replace($html, '(?is)<script.*?</script>|<style.*?</style>|<[^>]+>', ' ')
            )

            $articleMatch = [regex]::Match($plain, '(?i)Article\s+Number\s*:\s*(RN-[A-Z0-9\-]+)')
            if ($articleMatch.Success) {
                $articleNumber = $articleMatch.Groups[1].Value
            }

            $downloadUrls = @(Get-AmdInstallerDownloadCandidates -ReleaseVersion $version -ReleaseNotesUrl $url -Html $html)
        }

        $results.Add([pscustomobject]@{
            ReleaseVersion = $version
            ReleaseNotesUrl = $url
            ArticleNumber = $articleNumber
            PageTitle = $title
            FetchStatus = $status
            FetchError = $errorText
            RetrievedAtUtc = [DateTime]::UtcNow.ToString('o')
            HtmlEvidencePath = $htmlPath
            HtmlSha256 = $htmlSha256
            CandidateDownloadUrls = @($downloadUrls)
        })

        $itemSw.Stop()
        if ($status -in @('Fetched','Cached')) {
            Write-AmdOk ('Metadata [{0}/{1}] {2} -> {3}; candidates={4}; elapsed={5}' -f `
                $releaseIndex, $releaseTotal, $version, $status, $downloadUrls.Count, (Format-AmdElapsed $itemSw.Elapsed))
        }
        else {
            Write-AmdCaution ('Metadata [{0}/{1}] {2} -> {3}; {4}; elapsed={5}' -f `
                $releaseIndex, $releaseTotal, $version, $status, $errorText, (Format-AmdElapsed $itemSw.Elapsed))
        }
    }

    $output = [pscustomobject]@{
        SchemaVersion = '1.0'
        ToolkitVersion = $script:AmdChipsetResearchToolkitVersion
        GeneratedAtUtc = [DateTime]::UtcNow.ToString('o')
        Releases = $results.ToArray()
    }

    Write-AmdJsonFile -Path $OutputPath -Value $output

    $ok = @($results | Where-Object { $_.FetchStatus -in @('Fetched', 'Cached') }).Count
    $failed = @($results | Where-Object { $_.FetchStatus -eq 'FetchFailed' }).Count

    Write-AmdOk ('Metadata complete: successful={0}; failed={1}.' -f $ok, $failed)
    Write-AmdDetail ('Output: {0}' -f $OutputPath)
}


function Invoke-AmdAcquireStage {
    [CmdletBinding()]
    param(
        [string]$MetadataPath,
        [string]$OutputDirectory,
        [string]$ManifestPath,
        [string[]]$ReleaseVersion = @(),
        [switch]$Force,
        [switch]$AllowNonAmdHost
    )

    $toolRoot = Get-AmdResearchToolkitRoot

    if (-not $MetadataPath) { $MetadataPath = Join-Path $toolRoot 'inventory\release-metadata.json' }
    if (-not $OutputDirectory) { $OutputDirectory = Join-Path $toolRoot 'evidence\installers' }
    if (-not $ManifestPath) { $ManifestPath = Join-Path $toolRoot 'inventory\acquisition.json' }

    New-AmdDirectory -Path $OutputDirectory | Out-Null

    $metadata = Read-AmdJsonFile -Path $MetadataPath
    $releaseItems = @(
        $metadata.Releases | Where-Object {
            $ReleaseVersion.Count -eq 0 -or $ReleaseVersion -contains ([string]$_.ReleaseVersion)
        }
    )
    $releaseTotal = $releaseItems.Count
    $releaseIndex = 0
    $results = New-Object System.Collections.Generic.List[object]

    Write-AmdStep ('Acquiring installer artifacts for {0} release(s).' -f $releaseTotal)

    foreach ($release in $releaseItems) {
        $releaseIndex++
        $itemSw = [System.Diagnostics.Stopwatch]::StartNew()
        $version = [string]$release.ReleaseVersion
        $candidates = @($release.CandidateDownloadUrls)

        Write-AmdStep ('Acquire [{0}/{1}] {2}; candidates={3}' -f $releaseIndex, $releaseTotal, $version, $candidates.Count)

        if ($candidates.Count -eq 0) {
            $results.Add([pscustomobject]@{
                ReleaseVersion = $version
                Status = 'MissingUrl'
                SourceUrl = $null
                ReferrerUrl = [string]$release.ReleaseNotesUrl
                LocalPath = $null
                FileName = $null
                Sha256 = $null
                SizeBytes = $null
                RetrievedAtUtc = $null
                Error = 'No candidate installer URL was parsed from the release-note page.'
            })
            $itemSw.Stop()
            Write-AmdCaution ('Acquire [{0}/{1}] {2} -> MissingUrl; elapsed={3}' -f $releaseIndex, $releaseTotal, $version, (Format-AmdElapsed $itemSw.Elapsed))
            continue
        }

        $downloaded = $false
        $errors = New-Object System.Collections.Generic.List[string]
        $candidateIndex = 0

        foreach ($candidate in $candidates) {
            $candidateIndex++
            $candidate = [string]$candidate

            if (-not $AllowNonAmdHost -and -not (Test-AmdAllowedDownloadHost -Uri $candidate)) {
                $errors.Add(('Rejected non-AMD host: {0}' -f $candidate))
                continue
            }

            $uri = $null
            try { $uri = [System.Uri]$candidate }
            catch {
                $errors.Add(('Invalid URL: {0}' -f $candidate))
                continue
            }

            $fileName = [System.IO.Path]::GetFileName($uri.AbsolutePath)
            if (-not $fileName) {
                $fileName = ('amd_chipset_{0}.exe' -f (ConvertTo-AmdSafeName -Value $version))
            }

            $versionDir = Join-Path $OutputDirectory (ConvertTo-AmdSafeName -Value $version)
            New-AmdDirectory -Path $versionDir | Out-Null
            $localPath = Join-Path $versionDir $fileName

            $status = $null
            if ((Test-Path -LiteralPath $localPath -PathType Leaf) -and -not $Force) {
                $status = 'Cached'
            }
            else {
                $downloadResult = Invoke-AmdQuietFileDownload `
                    -Uri $candidate `
                    -OutFile $localPath `
                    -Referer ([string]$release.ReleaseNotesUrl) `
                    -TimeoutSec 600 `
                    -MaximumRedirection 10
                if (-not $downloadResult.Success) {
                    $errors.Add(('{0}: {1}' -f $candidate, $downloadResult.Error))
                    continue
                }
                $status = 'Downloaded'
            }

            $validation = $null
            try {
                $validation = Get-AmdInstallerFileValidation -Path $localPath
            }
            catch {
                $errors.Add(('{0}: validation failed: {1}' -f $candidate, (Get-AmdCompactErrorMessage -Message $_.Exception.Message -MaximumLength 300)))
                Remove-Item -LiteralPath $localPath -Force -ErrorAction SilentlyContinue
                continue
            }

            if (-not $validation.Valid) {
                $diagnosticsRoot = Join-Path (Get-AmdPrivateEvidenceRoot) 'download-diagnostics'
                New-AmdDirectory -Path $diagnosticsRoot | Out-Null
                $diagName = ('invalid-download-{0}-{1}' -f (ConvertTo-AmdSafeName -Value $version), [System.IO.Path]::GetFileName($localPath))
                $diagPath = Join-Path $diagnosticsRoot $diagName
                Copy-Item -LiteralPath $localPath -Destination $diagPath -Force -ErrorAction SilentlyContinue
                Remove-Item -LiteralPath $localPath -Force -ErrorAction SilentlyContinue
                $errors.Add(('{0}: downloaded/cached artifact failed validation ({1}); diagnostic={2}' -f $candidate, $validation.Error, $diagPath))
                continue
            }

            try {
                $item = Get-Item -LiteralPath $localPath
                $sha256 = Get-AmdSha256 -Path $localPath

                $results.Add([pscustomobject]@{
                    ReleaseVersion = $version
                    Status = $status
                    SourceUrl = $candidate
                    ReferrerUrl = [string]$release.ReleaseNotesUrl
                    LocalPath = $item.FullName
                    FileName = $item.Name
                    Sha256 = $sha256
                    SizeBytes = [int64]$item.Length
                    Validation = $validation
                    RetrievedAtUtc = [DateTime]::UtcNow.ToString('o')
                    Error = $null
                })

                $downloaded = $true
                $itemSw.Stop()
                Write-AmdOk ('Acquire [{0}/{1}] {2} -> {3} {4}; candidate={5}/{6}; elapsed={7}' -f `
                    $releaseIndex, $releaseTotal, $version, $status, (Format-AmdByteSize $item.Length), `
                    $candidateIndex, $candidates.Count, (Format-AmdElapsed $itemSw.Elapsed))
                break
            }
            catch {
                $errors.Add(('{0}: artifact finalization failed: {1}' -f $candidate, (Get-AmdCompactErrorMessage -Message $_.Exception.Message -MaximumLength 300)))
                Remove-Item -LiteralPath $localPath -Force -ErrorAction SilentlyContinue
            }
        }

        if (-not $downloaded) {
            $itemSw.Stop()
            $results.Add([pscustomobject]@{
                ReleaseVersion = $version
                Status = 'DownloadFailed'
                SourceUrl = $null
                ReferrerUrl = [string]$release.ReleaseNotesUrl
                LocalPath = $null
                FileName = $null
                Sha256 = $null
                SizeBytes = $null
                RetrievedAtUtc = $null
                Error = ($errors -join ' | ')
            })
            Write-AmdCaution ('Acquire [{0}/{1}] {2} -> DownloadFailed after {3} candidate(s); elapsed={4}' -f `
                $releaseIndex, $releaseTotal, $version, $candidates.Count, (Format-AmdElapsed $itemSw.Elapsed))
            if ($errors.Count -gt 0) {
                Write-AmdDetail ('Last error: {0}' -f $errors[$errors.Count - 1]) -Color DarkYellow
            }
        }
    }

    $output = [pscustomobject]@{
        SchemaVersion = '1.0'
        ToolkitVersion = $script:AmdChipsetResearchToolkitVersion
        GeneratedAtUtc = [DateTime]::UtcNow.ToString('o')
        Artifacts = $results.ToArray()
    }

    Write-AmdJsonFile -Path $ManifestPath -Value $output

    $success = @($results | Where-Object { $_.Status -in @('Downloaded', 'Cached') }).Count
    $failed = @($results | Where-Object { $_.Status -notin @('Downloaded', 'Cached') }).Count

    Write-AmdOk ('Acquisition complete: available={0}; missing={1}.' -f $success, $failed)
    Write-AmdDetail ('Manifest: {0}' -f $ManifestPath)
}



function Initialize-AmdInstallShieldStreamDecoder {
    [CmdletBinding()]
    param()

    if ('AmdChipsetResearch.IsSetupStreamReader' -as [type]) {
        return
    }

    # The ISSetupStream format parser below is an in-script implementation
    # informed by the MIT-licensed ISx project by lifenjoiner:
    # https://github.com/lifenjoiner/ISx
    # See THIRD-PARTY-NOTICES.md for attribution and license text.
    $source = @'
using System;
using System.Collections.Generic;
using System.IO;
using System.IO.Compression;
using System.Security.Cryptography;
using System.Text;

namespace AmdChipsetResearch
{
    public sealed class IsSetupStreamProbe
    {
        public bool IsSetupStream { get; set; }
        public long OverlayOffset { get; set; }
        public ushort FileCount { get; set; }
        public uint Type { get; set; }
        public string Error { get; set; }
    }

    public sealed class IsSetupStreamEntry
    {
        public string FileName { get; set; }
        public uint EncodedFlags { get; set; }
        public uint EncodedLength { get; set; }
        public ushort InflateFlag { get; set; }
        public long DataOffset { get; set; }
        public string OutputPath { get; set; }
        public long OutputLength { get; set; }
        public bool Inflated { get; set; }
        public bool MsiMagicValid { get; set; }
    }

    public sealed class IsSetupStreamExtraction
    {
        public bool Success { get; set; }
        public long OverlayOffset { get; set; }
        public ushort FileCount { get; set; }
        public uint Type { get; set; }
        public string Error { get; set; }
        public List<IsSetupStreamEntry> Entries { get; set; }

        public IsSetupStreamExtraction()
        {
            Entries = new List<IsSetupStreamEntry>();
        }
    }

    public static class IsSetupStreamReader
    {
        private static readonly byte[] MagicDec = new byte[] { 0x13, 0x35, 0x86, 0x07 };
        private static readonly byte[] MsiMagic = new byte[] { 0xD0, 0xCF, 0x11, 0xE0, 0xA1, 0xB1, 0x1A, 0xE1 };

        private static long GetPeOverlayOffset(BinaryReader br)
        {
            Stream stream = br.BaseStream;
            if (stream.Length < 0x40)
                throw new InvalidDataException("File is too small to be a PE image.");

            stream.Position = 0;
            if (br.ReadUInt16() != 0x5A4D)
                throw new InvalidDataException("DOS MZ signature is absent.");

            stream.Position = 0x3C;
            uint peOffset = br.ReadUInt32();
            if (peOffset + 24 > stream.Length)
                throw new InvalidDataException("PE header offset is outside the file.");

            stream.Position = peOffset;
            if (br.ReadUInt32() != 0x00004550)
                throw new InvalidDataException("PE signature is absent.");

            br.ReadUInt16(); // Machine
            ushort sectionCount = br.ReadUInt16();
            br.ReadUInt32(); // TimeDateStamp
            br.ReadUInt32(); // PointerToSymbolTable
            br.ReadUInt32(); // NumberOfSymbols
            ushort optionalHeaderSize = br.ReadUInt16();
            br.ReadUInt16(); // Characteristics

            if (sectionCount == 0)
                throw new InvalidDataException("PE image has no sections.");

            long sectionTable = peOffset + 4 + 20 + optionalHeaderSize;
            long lastSection = sectionTable + ((long)sectionCount - 1L) * 40L;
            if (lastSection + 40 > stream.Length)
                throw new InvalidDataException("Last PE section header is outside the file.");

            stream.Position = lastSection + 16;
            uint sizeOfRawData = br.ReadUInt32();
            uint pointerToRawData = br.ReadUInt32();
            long overlay = (long)pointerToRawData + (long)sizeOfRawData;

            if (overlay < 0 || overlay > stream.Length)
                throw new InvalidDataException("Calculated PE overlay offset is invalid.");

            return overlay;
        }

        public static IsSetupStreamProbe Probe(string path)
        {
            IsSetupStreamProbe result = new IsSetupStreamProbe();
            try
            {
                using (FileStream fs = new FileStream(path, FileMode.Open, FileAccess.Read, FileShare.Read))
                using (BinaryReader br = new BinaryReader(fs, Encoding.UTF8))
                {
                    long overlay = GetPeOverlayOffset(br);
                    result.OverlayOffset = overlay;

                    if (overlay + 46 > fs.Length)
                        return result;

                    fs.Position = overlay;
                    byte[] sigBytes = br.ReadBytes(14);
                    string sig = Encoding.ASCII.GetString(sigBytes).TrimEnd('\0');
                    if (!String.Equals(sig, "ISSetupStream", StringComparison.Ordinal))
                        return result;

                    result.IsSetupStream = true;
                    result.FileCount = br.ReadUInt16();
                    result.Type = br.ReadUInt32();
                    if (result.Type > 4)
                        result.Error = "Unsupported ISSetupStream type " + result.Type + ".";
                }
            }
            catch (Exception ex)
            {
                result.Error = ex.Message;
            }
            return result;
        }

        private static byte[] GenerateKey(string seed)
        {
            byte[] seedBytes = Encoding.UTF8.GetBytes(seed);
            byte[] key = new byte[seedBytes.Length];
            for (int i = 0; i < seedBytes.Length; i++)
                key[i] = (byte)(seedBytes[i] ^ MagicDec[i % MagicDec.Length]);
            return key;
        }

        private static void DecodeStreamBlocks(byte[] data, byte[] key)
        {
            if (key == null || key.Length == 0)
                return;

            const int BlockSize = 1024;
            for (int blockStart = 0; blockStart < data.Length; blockStart += BlockSize)
            {
                int blockLength = Math.Min(BlockSize, data.Length - blockStart);
                for (int i = 0; i < blockLength; i++)
                {
                    byte value = data[blockStart + i];
                    int swapped = ((value << 4) | (value >> 4)) & 0xFF;
                    data[blockStart + i] = unchecked((byte)~(key[i % key.Length] ^ swapped));
                }
            }
        }

        private static byte[] InflateZlib(byte[] input)
        {
            if (input == null || input.Length < 6)
                throw new InvalidDataException("zlib stream is too short.");

            int cmf = input[0];
            int flg = input[1];
            if ((cmf & 0x0F) != 8 || (((cmf << 8) + flg) % 31) != 0)
                throw new InvalidDataException("Decoded payload does not have a valid zlib header.");

            int start = 2;
            if ((flg & 0x20) != 0)
                start += 4;

            int compressedLength = input.Length - start - 4; // exclude Adler-32
            if (compressedLength <= 0)
                throw new InvalidDataException("zlib payload has no DEFLATE body.");

            using (MemoryStream source = new MemoryStream(input, start, compressedLength, false))
            using (DeflateStream deflate = new DeflateStream(source, CompressionMode.Decompress))
            using (MemoryStream destination = new MemoryStream())
            {
                deflate.CopyTo(destination);
                return destination.ToArray();
            }
        }

        private static string GetSafeOutputPath(string outputDirectory, string fileName)
        {
            string normalizedName = fileName.Replace('\\', Path.DirectorySeparatorChar).Replace('/', Path.DirectorySeparatorChar);
            string root = Path.GetFullPath(outputDirectory);
            string full = Path.GetFullPath(Path.Combine(root, normalizedName));
            string rootWithSep = root.EndsWith(Path.DirectorySeparatorChar.ToString())
                ? root
                : root + Path.DirectorySeparatorChar;

            StringComparison comparison = Path.DirectorySeparatorChar == '\\'
                ? StringComparison.OrdinalIgnoreCase
                : StringComparison.Ordinal;

            if (!full.StartsWith(rootWithSep, comparison))
                throw new InvalidDataException("ISSetupStream file name escapes the extraction root: " + fileName);

            return full;
        }

        private static bool HasMsiMagic(byte[] data)
        {
            if (data == null || data.Length < MsiMagic.Length)
                return false;

            for (int i = 0; i < MsiMagic.Length; i++)
                if (data[i] != MsiMagic[i])
                    return false;

            return true;
        }

        public static IsSetupStreamExtraction Extract(string inputPath, string outputDirectory)
        {
            IsSetupStreamExtraction result = new IsSetupStreamExtraction();

            try
            {
                Directory.CreateDirectory(outputDirectory);

                using (FileStream fs = new FileStream(inputPath, FileMode.Open, FileAccess.Read, FileShare.Read))
                using (BinaryReader br = new BinaryReader(fs, Encoding.UTF8))
                {
                    long overlay = GetPeOverlayOffset(br);
                    result.OverlayOffset = overlay;
                    fs.Position = overlay;

                    byte[] sigBytes = br.ReadBytes(14);
                    string sig = Encoding.ASCII.GetString(sigBytes).TrimEnd('\0');
                    if (!String.Equals(sig, "ISSetupStream", StringComparison.Ordinal))
                        throw new InvalidDataException("PE overlay is not an ISSetupStream container.");

                    ushort fileCount = br.ReadUInt16();
                    uint type = br.ReadUInt32();
                    result.FileCount = fileCount;
                    result.Type = type;

                    if (type > 4)
                        throw new InvalidDataException("Unsupported ISSetupStream type " + type + ".");

                    br.ReadBytes(8);
                    br.ReadUInt16();
                    br.ReadBytes(16);

                    for (int index = 0; index < fileCount; index++)
                    {
                        if (fs.Position + 24 > fs.Length)
                            throw new EndOfStreamException("ISSetupStream file attributes are truncated.");

                        uint filenameLength = br.ReadUInt32();
                        uint encodedFlags = br.ReadUInt32();
                        br.ReadBytes(2);
                        uint fileLength = br.ReadUInt32();
                        br.ReadBytes(8);
                        ushort inflateFlag = br.ReadUInt16();

                        if (filenameLength == 0 || filenameLength > 4096)
                            throw new InvalidDataException("Invalid ISSetupStream filename length " + filenameLength + ".");

                        if (type == 4)
                        {
                            if (fs.Position + 24 > fs.Length)
                                throw new EndOfStreamException("ISSetupStream v4 extended attributes are truncated.");
                            br.ReadBytes(24);
                        }

                        if (fs.Position + filenameLength > fs.Length)
                            throw new EndOfStreamException("ISSetupStream filename is truncated.");

                        byte[] fileNameBytes = br.ReadBytes((int)filenameLength);
                        string fileName = Encoding.Unicode.GetString(fileNameBytes).TrimEnd('\0');
                        long dataOffset = fs.Position;

                        if ((long)fileLength > fs.Length - fs.Position)
                            throw new EndOfStreamException("ISSetupStream payload is truncated for " + fileName + ".");

                        byte[] payload = br.ReadBytes((int)fileLength);

                        if ((encodedFlags & 4U) != 0U)
                        {
                            byte[] key = GenerateKey(fileName);
                            DecodeStreamBlocks(payload, key);
                        }

                        bool inflated = false;
                        if (inflateFlag != 0)
                        {
                            payload = InflateZlib(payload);
                            inflated = true;
                        }

                        string outputPath = GetSafeOutputPath(outputDirectory, fileName);
                        string parent = Path.GetDirectoryName(outputPath);
                        if (!String.IsNullOrEmpty(parent))
                            Directory.CreateDirectory(parent);

                        File.WriteAllBytes(outputPath, payload);

                        result.Entries.Add(new IsSetupStreamEntry {
                            FileName = fileName,
                            EncodedFlags = encodedFlags,
                            EncodedLength = fileLength,
                            InflateFlag = inflateFlag,
                            DataOffset = dataOffset,
                            OutputPath = outputPath,
                            OutputLength = payload.LongLength,
                            Inflated = inflated,
                            MsiMagicValid = fileName.EndsWith(".msi", StringComparison.OrdinalIgnoreCase) ? HasMsiMagic(payload) : false
                        });
                    }
                }

                result.Success = true;
            }
            catch (Exception ex)
            {
                result.Success = false;
                result.Error = ex.ToString();
            }

            return result;
        }
    }
}
'@

    Add-Type -TypeDefinition $source -Language CSharp -ErrorAction Stop
}

function Get-AmdIsSetupStreamProbe {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    Initialize-AmdInstallShieldStreamDecoder
    return [AmdChipsetResearch.IsSetupStreamReader]::Probe((Resolve-Path -LiteralPath $Path).Path)
}

function Expand-AmdIsSetupStream {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [string]$Destination
    )

    Initialize-AmdInstallShieldStreamDecoder
    New-AmdDirectory -Path $Destination | Out-Null

    $result = [AmdChipsetResearch.IsSetupStreamReader]::Extract(
        (Resolve-Path -LiteralPath $Path).Path,
        (Resolve-Path -LiteralPath $Destination).Path
    )

    if (-not $result.Success) {
        throw ('ISSetupStream extraction failed for {0}: {1}' -f $Path, $result.Error)
    }

    return $result
}

function Invoke-AmdExtractStage {
    [CmdletBinding()]
    param(
        [string]$AcquisitionPath,
        [string]$OutputDirectory,
        [string]$ManifestPath,
        [string]$SevenZipPath,
        [int]$MaxDepth = 5,
        [switch]$Force
    )

    $toolRoot = Get-AmdResearchToolkitRoot

    if (-not $AcquisitionPath) {
        $AcquisitionPath = Join-Path $toolRoot 'inventory\acquisition.json'
    }

    if (-not $OutputDirectory) {
        $OutputDirectory = Join-Path $toolRoot 'work\extracted'
    }

    if (-not $ManifestPath) {
        $ManifestPath = Join-Path $toolRoot 'inventory\extraction.json'
    }

    if ($MaxDepth -lt 0 -or $MaxDepth -gt 10) {
        throw 'MaxDepth must be between 0 and 10.'
    }

    $sevenZip = Get-AmdSevenZipPath -ExplicitPath $SevenZipPath
    New-AmdDirectory -Path $OutputDirectory | Out-Null
    $logRoot = Join-Path (Get-AmdPrivateEvidenceRoot) 'extraction-logs'
    New-AmdDirectory -Path $logRoot | Out-Null

    $acquisition = Read-AmdJsonFile -Path $AcquisitionPath
    $releaseResults = New-Object System.Collections.Generic.List[object]
    $artifactItems = @(
        $acquisition.Artifacts | Where-Object { $_.Status -in @('Downloaded', 'Cached', 'Provided') }
    )
    $releaseTotal = $artifactItems.Count
    $releaseIndex = 0

    Write-AmdStep ('Extracting {0} installer artifact(s); max depth={1}.' -f $releaseTotal, $MaxDepth)

    foreach ($artifact in $artifactItems) {
        $releaseIndex++
        $itemSw = [System.Diagnostics.Stopwatch]::StartNew()
        $version = [string]$artifact.ReleaseVersion
        $installerPath = [string]$artifact.LocalPath
        Write-AmdStep ('Extract [{0}/{1}] {2} - {3}' -f $releaseIndex, $releaseTotal, $version, ([System.IO.Path]::GetFileName($installerPath)))

        if (-not (Test-Path -LiteralPath $installerPath -PathType Leaf)) {
            $releaseResults.Add([pscustomobject]@{
                ReleaseVersion = $version
                Status = 'ExtractionFailed'
                InstallerPath = $installerPath
                ExtractionRoot = $null
                InfFileCount = 0
                Containers = @()
                Error = 'Installer path does not exist.'
            })
            $itemSw.Stop()
            Write-AmdFail ('Extract [{0}/{1}] {2} -> missing installer path; elapsed={3}' -f `
                $releaseIndex, $releaseTotal, $version, (Format-AmdElapsed $itemSw.Elapsed))
            continue
        }

        $safeVersion = ConvertTo-AmdSafeName -Value $version
        $releaseRoot = Join-Path $OutputDirectory $safeVersion
        $releaseLogRoot = Join-Path $logRoot $safeVersion

        if ($Force -and (Test-Path -LiteralPath $releaseRoot -PathType Container)) {
            Remove-Item -LiteralPath $releaseRoot -Recurse -Force
        }
        if ($Force -and (Test-Path -LiteralPath $releaseLogRoot -PathType Container)) {
            Remove-Item -LiteralPath $releaseLogRoot -Recurse -Force
        }

        New-AmdDirectory -Path $releaseRoot | Out-Null
        New-AmdDirectory -Path $releaseLogRoot | Out-Null

        $containers = New-Object System.Collections.Generic.List[object]
        $queue = New-Object System.Collections.Queue

        $queue.Enqueue([pscustomobject]@{
            Path = (Resolve-Path -LiteralPath $installerPath).Path
            Depth = 0
            Parent = $null
        })

        $seenHashes = @{}
        $releaseFailed = $false
        $releaseErrors = New-Object System.Collections.Generic.List[string]
        $containerSequence = 0

        while ($queue.Count -gt 0) {
            $entry = $queue.Dequeue()
            $containerPath = [string]$entry.Path
            $depth = [int]$entry.Depth

            if ($depth -gt $MaxDepth) {
                continue
            }

            try {
                $containerHash = Get-AmdSha256 -Path $containerPath
            }
            catch {
                $releaseErrors.Add(('Hash failed for {0}: {1}' -f $containerPath, $_.Exception.Message))
                $releaseFailed = $true
                continue
            }

            if ($seenHashes.ContainsKey($containerHash)) {
                continue
            }
            $seenHashes[$containerHash] = $true
            $containerSequence++

            $safeLeaf = ConvertTo-AmdSafeName -Value ([System.IO.Path]::GetFileName($containerPath))
            $out = Join-Path $releaseRoot ('d{0}_{1}_{2}' -f $depth, $safeLeaf, $containerHash.Substring(0, 12))
            New-AmdDirectory -Path $out | Out-Null

            $status = 'Extracted'
            $extractorType = '7-Zip'
            $exitCode = $null
            $errorText = $null
            $outputText = @()
            $isSetupType = $null
            $isSetupFileCount = $null
            $isSetupEntries = @()
            $msiValidationFailures = New-Object System.Collections.Generic.List[string]

            $probe = $null
            if ([System.IO.Path]::GetExtension($containerPath) -ieq '.exe') {
                try {
                    $probe = Get-AmdIsSetupStreamProbe -Path $containerPath
                }
                catch {
                    $probe = $null
                }
            }

            if ($probe -and $probe.IsSetupStream) {
                $extractorType = 'ISSetupStream'
                $isSetupType = [uint32]$probe.Type
                $isSetupFileCount = [int]$probe.FileCount

                try {
                    $isResult = Expand-AmdIsSetupStream -Path $containerPath -Destination $out
                    $isSetupEntries = @(
                        foreach ($item in @($isResult.Entries)) {
                            if ($item.FileName -match '(?i)\.msi$' -and -not $item.MsiMagicValid) {
                                $msiValidationFailures.Add([string]$item.FileName)
                            }

                            [pscustomobject][ordered]@{
                                FileName = [string]$item.FileName
                                EncodedFlags = [uint32]$item.EncodedFlags
                                EncodedLength = [uint32]$item.EncodedLength
                                InflateFlag = [int]$item.InflateFlag
                                DataOffset = [int64]$item.DataOffset
                                OutputPath = [string]$item.OutputPath
                                OutputLength = [int64]$item.OutputLength
                                Inflated = [bool]$item.Inflated
                                MsiMagicValid = [bool]$item.MsiMagicValid
                                Sha256 = if (Test-Path -LiteralPath ([string]$item.OutputPath) -PathType Leaf) {
                                    Get-AmdSha256 -Path ([string]$item.OutputPath)
                                } else { $null }
                            }
                        }
                    )

                    if ($msiValidationFailures.Count -gt 0) {
                        $status = 'ExtractionFailed'
                        $errorText = ('Recovered MSI failed OLE/CFBF magic validation: {0}' -f ($msiValidationFailures -join ', '))
                        $releaseFailed = $true
                        $releaseErrors.Add(('{0}: {1}' -f $containerPath, $errorText))
                    }
                    else {
                        $outputText = @(
                            ('ISSetupStream type : {0}' -f $isSetupType),
                            ('Declared files     : {0}' -f $isSetupFileCount),
                            ('Recovered files    : {0}' -f $isSetupEntries.Count)
                        )
                    }
                }
                catch {
                    $status = 'ExtractionFailed'
                    $errorText = $_.Exception.Message
                    $releaseFailed = $true
                    $releaseErrors.Add(('{0}: {1}' -f $containerPath, $errorText))
                }
            }
            else {
                try {
                    $outputText = @(& $sevenZip 'x' '-y' "-o$out" $containerPath 2>&1 | ForEach-Object { [string]$_ })
                    $exitCode = $LASTEXITCODE

                    if ($exitCode -eq 1) {
                        $status = 'ExtractedWithWarnings'
                    }
                    elseif ($exitCode -ne 0) {
                        $status = 'ExtractionFailed'
                        $errorText = ('7-Zip exit code {0}' -f $exitCode)
                        $releaseFailed = $true
                        $releaseErrors.Add(('{0}: {1}' -f $containerPath, $errorText))
                    }
                }
                catch {
                    $status = 'ExtractionFailed'
                    $errorText = $_.Exception.Message
                    $releaseFailed = $true
                    $releaseErrors.Add(('{0}: {1}' -f $containerPath, $errorText))
                }
            }

            $logPath = Join-Path $releaseLogRoot ('{0:D3}-d{1}-{2}-{3}.log' -f $containerSequence, $depth, $extractorType, $containerHash.Substring(0, 12))
            $logLines = New-Object System.Collections.Generic.List[string]
            $logLines.Add(('Container      : {0}' -f $containerPath))
            $logLines.Add(('SHA-256       : {0}' -f $containerHash))
            $logLines.Add(('Depth          : {0}' -f $depth))
            $logLines.Add(('Extractor      : {0}' -f $extractorType))
            $logLines.Add(('Status         : {0}' -f $status))
            if ($null -ne $exitCode) { $logLines.Add(('7-Zip exit    : {0}' -f $exitCode)) }
            if ($null -ne $isSetupType) { $logLines.Add(('ISSetup type   : {0}' -f $isSetupType)) }
            if ($errorText) { $logLines.Add(('Error          : {0}' -f $errorText)) }
            $logLines.Add('')
            foreach ($line in @($outputText)) { $logLines.Add([string]$line) }
            Write-AmdUtf8NoBom -Path $logPath -Text ($logLines.ToArray() -join [Environment]::NewLine)

            $containers.Add([pscustomobject][ordered]@{
                ContainerPath = $containerPath
                ContainerSha256 = $containerHash
                ContainerExtension = [System.IO.Path]::GetExtension($containerPath)
                Depth = $depth
                ParentContainer = $entry.Parent
                OutputDirectory = $out
                ExtractorType = $extractorType
                Status = $status
                SevenZipExitCode = $exitCode
                ISSetupStreamType = $isSetupType
                ISSetupStreamDeclaredFileCount = $isSetupFileCount
                ISSetupStreamEntries = @($isSetupEntries)
                Error = $errorText
                EvidenceLogPath = $logPath
                Log = ($outputText -join [Environment]::NewLine)
            })

            if ($status -eq 'ExtractionFailed' -or $depth -ge $MaxDepth) {
                continue
            }

            $nested = @(
                Get-ChildItem -LiteralPath $out -File -Recurse -ErrorAction SilentlyContinue |
                    Where-Object {
                        $ext = $_.Extension.ToLowerInvariant()
                        if ($ext -in @('.msi', '.cab', '.zip', '.7z')) {
                            return $true
                        }

                        if ($ext -eq '.exe') {
                            # AMD historical ZIP releases (observed 2.04 / 3.08 /
                            # 3.09) wrap the normal outer AMD installer EXE inside
                            # a ZIP. Follow known AMD installer names even when the
                            # EXE itself is NSIS rather than ISSetupStream.
                            if ($_.Name -match '(?i)^amd_(?:chipset_software|software).*\.exe$' -or
                                $_.Name -ieq 'AMD_Chipset_Drivers.exe') {
                                return $true
                            }

                            try {
                                $innerProbe = Get-AmdIsSetupStreamProbe -Path $_.FullName
                                return [bool]$innerProbe.IsSetupStream
                            }
                            catch {
                                return $false
                            }
                        }

                        return $false
                    }
            )

            foreach ($file in $nested) {
                $queue.Enqueue([pscustomobject]@{
                    Path = $file.FullName
                    Depth = $depth + 1
                    Parent = $containerPath
                })
            }
        }

        $infFiles = @(
            Get-ChildItem -LiteralPath $releaseRoot -Filter '*.inf' -File -Recurse -ErrorAction SilentlyContinue
        )
        $isSetupContainers = @($containers.ToArray() | Where-Object { $_.ExtractorType -eq 'ISSetupStream' })
        $failedContainers = @($containers.ToArray() | Where-Object { $_.Status -eq 'ExtractionFailed' })

        $releaseStatus = if ($containers.Count -eq 0) {
            'ExtractionFailed'
        }
        elseif ($releaseFailed -or $failedContainers.Count -gt 0) {
            'ExtractedWithErrors'
        }
        elseif ($infFiles.Count -gt 0) {
            'ExtractionComplete'
        }
        else {
            'PartialExtraction'
        }

        if ($releaseStatus -eq 'PartialExtraction') {
            $releaseErrors.Add('No INF files were discovered after recursive extraction. The release is not considered analysis-complete.')
        }

        $releaseResults.Add([pscustomobject][ordered]@{
            ReleaseVersion = $version
            Status = $releaseStatus
            InstallerPath = $installerPath
            InstallerSha256 = [string]$artifact.Sha256
            ExtractionRoot = $releaseRoot
            InfFileCount = $infFiles.Count
            ISSetupStreamContainerCount = $isSetupContainers.Count
            ContainerCount = $containers.Count
            Containers = $containers.ToArray()
            Error = if ($releaseErrors.Count -gt 0) { $releaseErrors -join ' | ' } else { $null }
        })

        $itemSw.Stop()
        $extractMessage = 'Extract [{0}/{1}] {2} -> {3}; containers={4}; INF={5}; ISSetup={6}; elapsed={7}' -f `
            $releaseIndex, $releaseTotal, $version, $releaseStatus, $containers.Count, $infFiles.Count, `
            $isSetupContainers.Count, (Format-AmdElapsed $itemSw.Elapsed)
        if ($releaseStatus -eq 'ExtractionComplete') {
            Write-AmdOk $extractMessage
        }
        elseif ($releaseStatus -eq 'PartialExtraction') {
            Write-AmdCaution $extractMessage
        }
        else {
            Write-AmdFail $extractMessage
        }
    }

    $output = [pscustomobject][ordered]@{
        SchemaVersion = '2.0'
        ToolkitVersion = $script:AmdChipsetResearchToolkitVersion
        GeneratedAtUtc = [DateTime]::UtcNow.ToString('o')
        Extractors = @(
            [pscustomobject]@{
                Type = '7-Zip'
                Path = $sevenZip
            },
            [pscustomobject]@{
                Type = 'ISSetupStream'
                Implementation = 'InScript'
                Reference = 'https://github.com/lifenjoiner/ISx'
                SupportedObservedTypes = @(3, 4)
            }
        )
        MaxDepth = $MaxDepth
        Releases = $releaseResults.ToArray()
    }

    Write-AmdJsonFile -Path $ManifestPath -Value $output

    $complete = @($releaseResults.ToArray() | Where-Object { $_.Status -eq 'ExtractionComplete' }).Count
    $incomplete = @($releaseResults.ToArray() | Where-Object { $_.Status -ne 'ExtractionComplete' }).Count

    Write-Host ('Extraction releases complete  : {0}' -f $complete)
    Write-Host ('Extraction releases incomplete: {0}' -f $incomplete)
    Write-Host ('Manifest                      : {0}' -f $ManifestPath)
}


function Invoke-AmdEmbeddedMetadataInspection {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object]$Extraction,
        [string]$OutputPath
    )

    $toolRoot = Get-AmdResearchToolkitRoot
    if (-not $OutputPath) {
        $OutputPath = Join-Path $toolRoot 'inventory\embedded-installer-metadata.json'
    }

    $releaseRecords = New-Object System.Collections.Generic.List[object]

    function Get-AmdXmlChildText {
        param(
            [Parameter(Mandatory = $true)][object]$Node,
            [Parameter(Mandatory = $true)][string]$ChildName
        )
        $child = $Node.SelectSingleNode($ChildName)
        if ($null -eq $child) { return $null }
        return [string]$child.InnerText
    }

    foreach ($release in @($Extraction.Releases)) {
        $version = [string]$release.ReleaseVersion
        $root = [string]$release.ExtractionRoot
        $infoSources = New-Object System.Collections.Generic.List[object]
        $apsSources = New-Object System.Collections.Generic.List[object]
        $devIdSources = New-Object System.Collections.Generic.List[object]
        $errors = New-Object System.Collections.Generic.List[string]

        if (-not $root -or -not (Test-Path -LiteralPath $root -PathType Container)) {
            $releaseRecords.Add([pscustomobject][ordered]@{
                ReleaseVersion = $version
                Status = 'NotInspected'
                ExtractionRoot = $root
                PreferredInfoXmlPath = $null
                PreferredDevIdXmlPath = $null
                ProductCount = 0
                DeviceMappingCount = 0
                Products = @()
                DeviceMappings = @()
                InfoXmlSources = @()
                DevIdXmlSources = @()
                Errors = @('Extraction root is unavailable.')
            })
            continue
        }

        $infoFiles = @(
            Get-ChildItem -LiteralPath $root -Filter 'Info.xml' -File -Recurse -ErrorAction SilentlyContinue |
                Sort-Object FullName
        )
        $apsFiles = @(
            Get-ChildItem -LiteralPath $root -Filter 'APS_*.xml' -File -Recurse -ErrorAction SilentlyContinue |
                Sort-Object FullName
        )
        $devIdFiles = @(
            Get-ChildItem -LiteralPath $root -Filter 'DevID.xml' -File -Recurse -ErrorAction SilentlyContinue |
                Sort-Object FullName
        )

        foreach ($file in $infoFiles) {
            try {
                $relative = Get-AmdRelativePath -BasePath $root -Path $file.FullName
                $xmlText = [System.IO.File]::ReadAllText($file.FullName)
                $xml = ConvertFrom-AmdXmlText -Text $xmlText -Source $relative
                $products = New-Object System.Collections.Generic.List[object]

                foreach ($node in @($xml.Packaging.Product)) {
                    if ($null -eq $node) { continue }
                    $products.Add([pscustomobject][ordered]@{
                        Name = Get-AmdXmlChildText -Node $node -ChildName 'Name'
                        OS = Get-AmdXmlChildText -Node $node -ChildName 'OS'
                        Version = Get-AmdXmlChildText -Node $node -ChildName 'Version'
                        Installer = Get-AmdXmlChildText -Node $node -ChildName 'Installer'
                        Brand = Get-AmdXmlChildText -Node $node -ChildName 'Brand'
                        Released = Get-AmdXmlChildText -Node $node -ChildName 'Released'
                    })
                }

                $infoSources.Add([pscustomobject][ordered]@{
                    Path = $file.FullName
                    RelativePath = $relative
                    Sha256 = Get-AmdSha256 -Path $file.FullName
                    ProductCount = $products.Count
                    Products = $products.ToArray()
                    ParseStatus = 'Parsed'
                    ParseError = $null
                })
            }
            catch {
                $relative = Get-AmdRelativePath -BasePath $root -Path $file.FullName
                $failedSha256 = $null
                try { $failedSha256 = Get-AmdSha256 -Path $file.FullName } catch { }
                $infoSources.Add([pscustomobject][ordered]@{
                    Path = $file.FullName
                    RelativePath = $relative
                    Sha256 = $failedSha256
                    ProductCount = 0
                    Products = @()
                    ParseStatus = 'ParseFailed'
                    ParseError = $_.Exception.Message
                })
                $errors.Add(('Info.xml parse failed ({0}): {1}' -f $relative, $_.Exception.Message))
            }
        }

        foreach ($file in $apsFiles) {
            try {
                $relative = Get-AmdRelativePath -BasePath $root -Path $file.FullName
                $xmlText = [System.IO.File]::ReadAllText($file.FullName)
                $xml = ConvertFrom-AmdXmlText -Text $xmlText -Source $relative
                $products = New-Object System.Collections.Generic.List[object]

                foreach ($node in @($xml.Packaging.Product)) {
                    if ($null -eq $node) { continue }
                    $products.Add([pscustomobject][ordered]@{
                        Name = Get-AmdXmlChildText -Node $node -ChildName 'Name'
                        OS = Get-AmdXmlChildText -Node $node -ChildName 'OS'
                        Version = Get-AmdXmlChildText -Node $node -ChildName 'Version'
                        Installer = Get-AmdXmlChildText -Node $node -ChildName 'Installer'
                        Brand = Get-AmdXmlChildText -Node $node -ChildName 'Brand'
                        Released = Get-AmdXmlChildText -Node $node -ChildName 'Released'
                    })
                }

                $apsSources.Add([pscustomobject][ordered]@{
                    Path = $file.FullName
                    RelativePath = $relative
                    Sha256 = Get-AmdSha256 -Path $file.FullName
                    ProductCount = $products.Count
                    Products = $products.ToArray()
                    ParseStatus = 'Parsed'
                    ParseError = $null
                    IdenticalToPreferredInfoXml = $false
                })
            }
            catch {
                $relative = Get-AmdRelativePath -BasePath $root -Path $file.FullName
                $failedSha256 = $null
                try { $failedSha256 = Get-AmdSha256 -Path $file.FullName } catch { }
                $apsSources.Add([pscustomobject][ordered]@{
                    Path = $file.FullName
                    RelativePath = $relative
                    Sha256 = $failedSha256
                    ProductCount = 0
                    Products = @()
                    ParseStatus = 'ParseFailed'
                    ParseError = $_.Exception.Message
                    IdenticalToPreferredInfoXml = $false
                })
                $errors.Add(('APS XML parse failed ({0}): {1}' -f $relative, $_.Exception.Message))
            }
        }

        foreach ($file in $devIdFiles) {
            try {
                $relative = Get-AmdRelativePath -BasePath $root -Path $file.FullName
                $xmlText = [System.IO.File]::ReadAllText($file.FullName)
                $xml = ConvertFrom-AmdXmlText -Text $xmlText -Source $relative
                $mappings = New-Object System.Collections.Generic.List[object]

                foreach ($node in @($xml.Packaging.Product)) {
                    if ($null -eq $node) { continue }
                    $rawDevIds = Get-AmdXmlChildText -Node $node -ChildName 'DevID'
                    $devIds = @()
                    if ($rawDevIds) {
                        $devIds = @(
                            $rawDevIds -split ',' |
                                ForEach-Object { $_.Trim() } |
                                Where-Object { $_ } |
                                Sort-Object -Unique
                        )
                    }
                    $mappings.Add([pscustomobject][ordered]@{
                        Tag = Get-AmdXmlChildText -Node $node -ChildName 'Tag'
                        RawDeviceIds = $rawDevIds
                        DeviceIds = @($devIds)
                    })
                }

                $devIdSources.Add([pscustomobject][ordered]@{
                    Path = $file.FullName
                    RelativePath = $relative
                    Sha256 = Get-AmdSha256 -Path $file.FullName
                    MappingCount = $mappings.Count
                    DeviceMappings = $mappings.ToArray()
                    ParseStatus = 'Parsed'
                    ParseError = $null
                })
            }
            catch {
                $relative = Get-AmdRelativePath -BasePath $root -Path $file.FullName
                $failedSha256 = $null
                try { $failedSha256 = Get-AmdSha256 -Path $file.FullName } catch { }
                $devIdSources.Add([pscustomobject][ordered]@{
                    Path = $file.FullName
                    RelativePath = $relative
                    Sha256 = $failedSha256
                    MappingCount = 0
                    DeviceMappings = @()
                    ParseStatus = 'ParseFailed'
                    ParseError = $_.Exception.Message
                })
                $errors.Add(('DevID.xml parse failed ({0}): {1}' -f $relative, $_.Exception.Message))
            }
        }

        $preferredInfo = @(
            $infoSources.ToArray() |
                Where-Object { $_.ParseStatus -eq 'Parsed' } |
                Sort-Object @{Expression = {
                    if ($_.RelativePath -match '(?i)(^|[\\/])Q[tT]_Dependencies[\\/]Info\.xml$') { 0 }
                    elseif ($_.RelativePath -match '(?i)(^|[\\/])Info\.xml$') { 1 }
                    else { 2 }
                }}, RelativePath |
                Select-Object -First 1
        )

        $preferredDevId = @(
            $devIdSources.ToArray() |
                Where-Object { $_.ParseStatus -eq 'Parsed' } |
                Sort-Object @{Expression = {
                    if ($_.RelativePath -match '(?i)(^|[\\/])Q[tT]_Dependencies[\\/]DevID\.xml$') { 0 }
                    elseif ($_.RelativePath -match '(?i)(^|[\\/])DevID\.xml$') { 1 }
                    else { 2 }
                }}, RelativePath |
                Select-Object -First 1
        )

        $preferredProducts = @()
        $preferredMappings = @()
        $preferredInfoPath = $null
        $preferredApsXmlPath = $null
        $preferredDevIdPath = $null
        $apsIdenticalCount = 0

        if ($preferredInfo.Count -gt 0) {
            $preferredInfoPath = [string]$preferredInfo[0].RelativePath
            $preferredProducts = @($preferredInfo[0].Products)
            $preferredInfoSha = [string]$preferredInfo[0].Sha256
            foreach ($aps in @($apsSources.ToArray())) {
                if ($aps.ParseStatus -eq 'Parsed' -and $preferredInfoSha -and ([string]$aps.Sha256 -eq $preferredInfoSha)) {
                    $aps.IdenticalToPreferredInfoXml = $true
                    $apsIdenticalCount++
                    if (-not $preferredApsXmlPath) { $preferredApsXmlPath = [string]$aps.RelativePath }
                }
            }
            if (-not $preferredApsXmlPath) {
                $firstParsedAps = @($apsSources.ToArray() | Where-Object { $_.ParseStatus -eq 'Parsed' } | Select-Object -First 1)
                if ($firstParsedAps.Count -gt 0) { $preferredApsXmlPath = [string]$firstParsedAps[0].RelativePath }
            }
        }
        elseif ($apsSources.Count -gt 0) {
            $firstParsedAps = @($apsSources.ToArray() | Where-Object { $_.ParseStatus -eq 'Parsed' } | Select-Object -First 1)
            if ($firstParsedAps.Count -gt 0) { $preferredApsXmlPath = [string]$firstParsedAps[0].RelativePath }
        }
        if ($preferredDevId.Count -gt 0) {
            $preferredDevIdPath = [string]$preferredDevId[0].RelativePath
            $preferredMappings = @($preferredDevId[0].DeviceMappings)
        }

        $status = if ($preferredInfo.Count -gt 0 -or $apsSources.Count -gt 0 -or $preferredDevId.Count -gt 0) {
            if ($errors.Count -gt 0) { 'ParsedWithErrors' } else { 'Parsed' }
        }
        elseif ($infoFiles.Count -eq 0 -and $apsFiles.Count -eq 0 -and $devIdFiles.Count -eq 0) {
            'NotPresent'
        }
        else {
            'ParseFailed'
        }

        $releaseRecords.Add([pscustomobject][ordered]@{
            ReleaseVersion = $version
            Status = $status
            ExtractionRoot = $root
            PreferredInfoXmlPath = $preferredInfoPath
            PreferredApsXmlPath = $preferredApsXmlPath
            PreferredDevIdXmlPath = $preferredDevIdPath
            ProductCount = $preferredProducts.Count
            ApsXmlCount = $apsSources.Count
            ApsIdenticalToPreferredInfoXmlCount = $apsIdenticalCount
            DeviceMappingCount = $preferredMappings.Count
            Products = @($preferredProducts)
            DeviceMappings = @($preferredMappings)
            InfoXmlSources = $infoSources.ToArray()
            ApsXmlSources = $apsSources.ToArray()
            DevIdXmlSources = $devIdSources.ToArray()
            Errors = $errors.ToArray()
        })
    }

    $output = [pscustomobject][ordered]@{
        SchemaVersion = '1.1'
        ToolkitVersion = $script:AmdChipsetResearchToolkitVersion
        GeneratedAtUtc = [DateTime]::UtcNow.ToString('o')
        Purpose = 'EmbeddedInstallerMetadataAndSelectorXmlEvidence'
        Releases = $releaseRecords.ToArray()
    }

    Write-AmdJsonFile -Path $OutputPath -Value $output
    Write-Host ('Embedded metadata releases: {0}' -f $releaseRecords.Count)
    Write-Host ('Embedded metadata output  : {0}' -f $OutputPath)

    return $output
}

function Invoke-AmdInspectStage {
    [CmdletBinding()]
    param(
        [string]$ExtractionPath,
        [string]$OutputPath
    )

    $toolRoot = Get-AmdResearchToolkitRoot

    if (-not $ExtractionPath) {
        $ExtractionPath = Join-Path $toolRoot 'inventory\extraction.json'
    }

    if (-not $OutputPath) {
        $OutputPath = Join-Path $toolRoot 'inventory\driver-packages.json'
    }

    $extraction = Read-AmdJsonFile -Path $ExtractionPath
    $embeddedMetadataPath = Join-Path $toolRoot 'inventory\embedded-installer-metadata.json'
    Write-AmdStep 'Inspecting embedded AMD Info.xml / APS XML / DevID.xml selector metadata.'
    $null = Invoke-AmdEmbeddedMetadataInspection -Extraction $extraction -OutputPath $embeddedMetadataPath
    $driverRecords = New-Object System.Collections.Generic.List[object]
    $releaseItems = @($extraction.Releases)
    $releaseTotal = $releaseItems.Count
    $releaseIndex = 0

    Write-AmdStep ('Inspecting INF packages for {0} release(s).' -f $releaseTotal)

    foreach ($release in $releaseItems) {
        $releaseIndex++
        $itemSw = [System.Diagnostics.Stopwatch]::StartNew()
        $version = [string]$release.ReleaseVersion
        $root = [string]$release.ExtractionRoot
        Write-AmdStep ('Inspect [{0}/{1}] {2}' -f $releaseIndex, $releaseTotal, $version)

        if (-not $root -or -not (Test-Path -LiteralPath $root -PathType Container)) {
            $itemSw.Stop()
            Write-AmdCaution ('Inspect [{0}/{1}] {2} -> extraction root unavailable; elapsed={3}' -f `
                $releaseIndex, $releaseTotal, $version, (Format-AmdElapsed $itemSw.Elapsed))
            continue
        }

        $infFiles = @(
            Get-ChildItem -LiteralPath $root -Filter '*.inf' -File -Recurse -ErrorAction SilentlyContinue
        )
        $releaseKmdfDeclared = 0
        $releaseUmdfDeclared = 0
        $releaseParseFailed = 0

        foreach ($inf in $infFiles) {
            try {
                $infDocument = Read-AmdInfDocument -Path $inf.FullName
                $lines = @($infDocument.Lines)

                $provider = Get-AmdInfVersionSectionValue -Lines $lines -Name 'Provider'
                $class = Get-AmdInfVersionSectionValue -Lines $lines -Name 'Class'
                $classGuid = Get-AmdInfVersionSectionValue -Lines $lines -Name 'ClassGuid'
                $driverVer = Get-AmdInfVersionSectionValue -Lines $lines -Name 'DriverVer'
                $catalogFile = Get-AmdInfVersionSectionValue -Lines $lines -Name 'CatalogFile'

                $kmdfEvidence = @(Get-AmdInfDirectiveValue -Lines $lines -Directive 'KmdfLibraryVersion')
                $umdfEvidence = @(Get-AmdInfDirectiveValue -Lines $lines -Directive 'UmdfLibraryVersion')
                $serviceBinaryEvidence = @(Get-AmdInfDirectiveValue -Lines $lines -Directive 'ServiceBinary')
                if ($kmdfEvidence.Count -gt 0) { $releaseKmdfDeclared++ }
                if ($umdfEvidence.Count -gt 0) { $releaseUmdfDeclared++ }

                $kmdfVersions = @(
                    $kmdfEvidence |
                        ForEach-Object { $_.RawValue } |
                        Where-Object { $_ } |
                        Sort-Object -Unique
                )

                $umdfVersions = @(
                    $umdfEvidence |
                        ForEach-Object { $_.RawValue } |
                        Where-Object { $_ } |
                        Sort-Object -Unique
                )

                $hardwareIds = @(Get-AmdInfHardwareIds -Lines $lines)
                $infTopology = Get-AmdInfTopology -Document $infDocument

                $driverDate = $null
                $driverVersion = $null
                if ($driverVer) {
                    $parts = $driverVer -split ',', 2
                    if ($parts.Count -ge 1) {
                        $driverDate = $parts[0].Trim()
                    }
                    if ($parts.Count -ge 2) {
                        $driverVersion = $parts[1].Trim()
                    }
                }

                $relativePath = $inf.FullName.Substring($root.Length).TrimStart('\', '/')

                $serviceBinaries = New-Object System.Collections.Generic.List[object]
                foreach ($ev in $serviceBinaryEvidence) {
                    $raw = [string]$ev.RawValue
                    $fileNameMatch = [regex]::Match($raw, '(?i)([^\\/%"]+\.sys)\b')
                    $fileName = if ($fileNameMatch.Success) { $fileNameMatch.Groups[1].Value } else { $null }
                    $resolvedBinary = $null
                    $fileVersion = $null
                    $productVersion = $null
                    $binarySha256 = $null

                    if ($fileName) {
                        $matches = @(
                            Get-ChildItem -LiteralPath $root -Filter $fileName -File -Recurse -ErrorAction SilentlyContinue
                        )

                        if ($matches.Count -gt 0) {
                            $resolvedBinary = $matches[0].FullName
                            try {
                                $binarySha256 = Get-AmdSha256 -Path $resolvedBinary
                                $versionInfo = (Get-Item -LiteralPath $resolvedBinary).VersionInfo
                                $fileVersion = $versionInfo.FileVersion
                                $productVersion = $versionInfo.ProductVersion
                            }
                            catch {
                                Write-Verbose ('Binary metadata unavailable for {0}: {1}' -f $resolvedBinary, $_.Exception.Message)
                            }
                        }
                    }

                    $serviceBinaries.Add([pscustomobject]@{
                        RawValue = $raw
                        FileName = $fileName
                        ResolvedPath = $resolvedBinary
                        Sha256 = $binarySha256
                        FileVersion = $fileVersion
                        ProductVersion = $productVersion
                        EvidenceLineNumber = $ev.LineNumber
                        EvidenceRawLine = $ev.RawLine
                    })
                }

                $driverRecords.Add([pscustomobject]@{
                    ReleaseVersion = $version
                    InspectionStatus = 'Inspected'
                    InspectionError = $null
                    InfPath = $inf.FullName
                    InfRelativePath = $relativePath
                    InfSha256 = Get-AmdSha256 -Path $inf.FullName
                    VersionSection = [pscustomobject]@{
                        Provider = $provider
                        Class = $class
                        ClassGuid = $classGuid
                        DriverVerRaw = $driverVer
                        DriverDate = $driverDate
                        DriverVersion = $driverVersion
                        CatalogFile = $catalogFile
                    }
                    Wdf = [pscustomobject]@{
                        KMDF = [pscustomobject]@{
                            Status = if ($kmdfEvidence.Count -gt 0) { 'Declared' } else { 'NotDeclared' }
                            Versions = @($kmdfVersions)
                            Evidence = @($kmdfEvidence)
                        }
                        UMDF = [pscustomobject]@{
                            Status = if ($umdfEvidence.Count -gt 0) { 'Declared' } else { 'NotDeclared' }
                            Versions = @($umdfVersions)
                            Evidence = @($umdfEvidence)
                        }
                    }
                    HardwareIds = @($hardwareIds)
                    InfTopology = $infTopology
                    ServerApplicability = @(Get-AmdServerApplicability -Topology $infTopology -Wdf ([pscustomobject]@{
                        KMDF = [pscustomobject]@{ Status = if ($kmdfEvidence.Count -gt 0) { 'Declared' } else { 'NotDeclared' }; Versions = @($kmdfVersions); Evidence = @($kmdfEvidence) }
                        UMDF = [pscustomobject]@{ Status = if ($umdfEvidence.Count -gt 0) { 'Declared' } else { 'NotDeclared' }; Versions = @($umdfVersions); Evidence = @($umdfEvidence) }
                    }))
                    ServiceBinaries = $serviceBinaries.ToArray()
                })
            }
            catch {
                $releaseParseFailed++
                $driverRecords.Add([pscustomobject]@{
                    ReleaseVersion = $version
                    InspectionStatus = 'ParseFailed'
                    InspectionError = $_.Exception.Message
                    InfPath = $inf.FullName
                    InfRelativePath = $null
                    InfSha256 = $null
                    VersionSection = $null
                    Wdf = $null
                    HardwareIds = @()
                    InfTopology = $null
                    ServerApplicability = @()
                    ServiceBinaries = @()
                })
            }
        }

        $itemSw.Stop()
        $inspectMessage = 'Inspect [{0}/{1}] {2} -> INF={3}; KMDF={4}; UMDF={5}; parse-failed={6}; elapsed={7}' -f `
            $releaseIndex, $releaseTotal, $version, $infFiles.Count, $releaseKmdfDeclared, $releaseUmdfDeclared, `
            $releaseParseFailed, (Format-AmdElapsed $itemSw.Elapsed)
        if ($releaseParseFailed -gt 0) {
            Write-AmdCaution $inspectMessage
        }
        elseif ($infFiles.Count -gt 0) {
            Write-AmdOk $inspectMessage
        }
        else {
            Write-AmdCaution $inspectMessage
        }
    }

    $output = [pscustomobject]@{
        SchemaVersion = '2.0'
        ToolkitVersion = $script:AmdChipsetResearchToolkitVersion
        GeneratedAtUtc = [DateTime]::UtcNow.ToString('o')
        DriverPackageCount = $driverRecords.Count
        DriverPackages = $driverRecords.ToArray()
    }

    Write-AmdJsonFile -Path $OutputPath -Value $output -Compress

    $kmdfCount = @(
        $driverRecords |
            Where-Object { $_.Wdf -and $_.Wdf.KMDF.Status -eq 'Declared' }
    ).Count

    $umdfCount = @(
        $driverRecords |
            Where-Object { $_.Wdf -and $_.Wdf.UMDF.Status -eq 'Declared' }
    ).Count

    Write-Host ('INF files inspected : {0}' -f $driverRecords.Count)
    Write-Host ('KMDF declarations   : {0}' -f $kmdfCount)
    Write-Host ('UMDF declarations   : {0}' -f $umdfCount)
    Write-Host ('Output              : {0}' -f $OutputPath)
}




function Get-AmdSelectorPropertyName {
    [CmdletBinding()]
    param([AllowNull()][string]$Tag)

    if ([string]::IsNullOrWhiteSpace($Tag)) { return $null }
    $value = $Tag.Trim()
    $slashIndex = $value.LastIndexOf('/')
    if ($slashIndex -ge 0 -and $slashIndex -lt ($value.Length - 1)) {
        $value = $value.Substring($slashIndex + 1)
    }
    if ($value.StartsWith('SET', [System.StringComparison]::OrdinalIgnoreCase)) {
        return $value.ToUpperInvariant()
    }
    return ('SET{0}' -f $value).ToUpperInvariant()
}

function Get-AmdSelectorFeatureName {
    [CmdletBinding()]
    param([AllowNull()][string]$PropertyName)
    if ([string]::IsNullOrWhiteSpace($PropertyName)) { return $null }
    $value = $PropertyName.Trim().ToUpperInvariant()
    if ($value.StartsWith('SET')) { return $value.Substring(3) }
    return $value
}

function Get-AmdSelectorProductAliases {
    [CmdletBinding()]
    param([Parameter(Mandatory=$true)][string]$PropertyName)

    $map = @{
        'SETSMBUS'       = @('SMBus')
        'SETPCI'         = @('PCI Device','PCI Driver')
        'SETI2C'         = @('I2C Driver')
        'SETPSP'         = @('PSP Driver')
        'SETGPIO2'       = @('GPIO2 Driver')
        'SETGPIO3'       = @('Promontory','PT GPIO')
        'SETUART'        = @('UART Driver')
        'SETSFHI2C'      = @('SFH I2C')
        'SETSFH1.1'      = @('SFH1.1')
        'SETSFHDRVR'     = @('SFH Driver','Sensor Fusion Hub')
        'SETUPEP'        = @('MicroPEP')
        'SETIOV_WT'      = @('IOV')
        'SETAS4ACPI'     = @('AS4 ACPI','Start Now Technology')
        'SETUSBCNTRL'    = @('USB Controller')
        'SETUSBCNTRL_HD' = @('USB Controller')
        'SETUSBCNTRL_PT' = @('USB Controller')
        'SETSATA'        = @('SATA')
        'SETFILTERUSB'   = @('USB Filter')
        'SETCIR'         = @('CIR')
        'SETEMBCCP'      = @('CCP')
        'SETUSB31'       = @('USB3.1','USB 3.1')
        'SETWBD'         = @('Wireless Button')
        'SETSERIAL'      = @('Serial')
        'SETEMBFLASH'    = @('SPI Flash','Flash')
        'SETPPM'         = @('PPM Provisioning')
        'SETUSB4CM'      = @('USB4 CM')
        'SETCVAC'        = @('3D V-Cache')
        'SETMAIL'        = @('AMS Mailbox')
        'SETS0I3'        = @('S0i3')
        'SETINTERFACE'   = @('Interface Driver')
        'SETOEMPF'       = @('Provisioning for OEM','OEM Provisioning')
        'SETNAIPMF300'   = @('PMF Ryzen AI 300 Series')
        'SETTAIPMF300'   = @('PMF Ryzen AI 300 Series')
        'SETAIPMFMAX300' = @('PMF Ryzen AI MAX 300')
        'SETAPPCOMPATDB' = @('Application Compatibility')
        'SETMSFT1'       = @('Pluton Security Processor 1')
        'SETMSFT2'       = @('Pluton Security Processor 2')
        'SETHSMP'        = @('HSMP')
        'SETSFH1.2'      = @('SFH1.2')
        'SETUPMF'        = @('PMF Driver')
        'SETXGBE'        = @('XGBE','10GbE')
        'SETRYZENPPKG'   = @('Processor Power Management','Ryzen Power Plan')
        'SETEMBSMBUS'    = @('Embedded SMBus','EMBSMBus')
        'SETWDT'         = @('WDT','Watchdog')
    }
    $key = $PropertyName.ToUpperInvariant()
    if ($map.ContainsKey($key)) { return @($map[$key]) }
    return @((Get-AmdSelectorFeatureName -PropertyName $key))
}

function Get-AmdSelectorInfoProductCandidates {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][string]$PropertyName,
        [AllowNull()][object[]]$Products
    )
    $aliases = @(Get-AmdSelectorProductAliases -PropertyName $PropertyName)
    $hits = New-Object System.Collections.Generic.List[object]
    foreach ($product in @($Products)) {
        $haystack = ('{0} {1}' -f [string]$product.Name,[string]$product.Installer)
        foreach ($alias in $aliases) {
            if ($alias -and $haystack.IndexOf([string]$alias, [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
                $hits.Add([pscustomobject][ordered]@{
                    Name = [string]$product.Name
                    Installer = [string]$product.Installer
                    OS = [string]$product.OS
                    Version = [string]$product.Version
                    MatchAlias = [string]$alias
                })
                break
            }
        }
    }
    return @($hits.ToArray())
}


function ConvertTo-AmdNormalizedArchitecture {
    [CmdletBinding()]
    param(
        [AllowNull()][string]$Architecture,
        [AllowNull()][object]$Cpu
    )

    $raw = [string]$Architecture
    if ([string]::IsNullOrWhiteSpace($raw)) { return 'unknown' }
    $token = $raw.Trim().ToLowerInvariant()

    if ($token -match '(^|[^a-z0-9])(amd64|x64|x86[_\-\s]?64)([^a-z0-9]|$)') { return 'x86_64' }
    if ($token -match '(^|[^a-z0-9])(arm64|aarch64)([^a-z0-9]|$)') { return 'arm64' }
    if ($token -match '(^|[^a-z0-9])(x86|i[3-6]86)([^a-z0-9]|$)') { return 'x86' }

    # Win32_OperatingSystem.OSArchitecture is localized on non-English Windows
    # (for example, Japanese "64 ビット"). Treat a generic 64-bit label as x86-64
    # only when CPU evidence identifies an AMD64 host.
    if ($token -match '64') {
        $cpuText = ''
        if ($null -ne $Cpu) {
            $parts = New-Object System.Collections.Generic.List[string]
            foreach ($name in @('Caption','Name','Manufacturer')) {
                if ($null -ne $Cpu.PSObject.Properties[$name]) {
                    $parts.Add([string]$Cpu.$name)
                }
            }
            $cpuText = ($parts.ToArray() -join ' ')
        }
        if ($cpuText -match '(?i)(AMD64|AuthenticAMD|AMD\s+Ryzen|Advanced Micro Devices)') { return 'x86_64' }
        if ($cpuText -match '(?i)(ARM64|AArch64)') { return 'arm64' }
        return '64bit-unknown'
    }
    if ($token -match '32') { return 'x86' }
    return 'unknown'
}

function Get-AmdHostNormalizedArchitecture {
    [CmdletBinding()]
    param([AllowNull()][object]$HostInventory)

    if ($null -eq $HostInventory -or $null -eq $HostInventory.OS) { return 'unknown' }
    foreach ($propertyName in @('NormalizedArchitecture','ArchitectureNormalized')) {
        if ($null -ne $HostInventory.OS.PSObject.Properties[$propertyName]) {
            $candidate = ConvertTo-AmdNormalizedArchitecture -Architecture ([string]$HostInventory.OS.$propertyName) -Cpu $HostInventory.CPU
            if ($candidate -ne 'unknown') { return $candidate }
        }
    }
    return ConvertTo-AmdNormalizedArchitecture -Architecture ([string]$HostInventory.OS.OSArchitecture) -Cpu $HostInventory.CPU
}

function Test-AmdHostArchitectureNormalizationSelfTest {
    [CmdletBinding()]
    param()

    $cpu = [pscustomobject]@{ Caption='AMD64 Family 25 Model 33 Stepping 2'; Name='AMD Ryzen'; Manufacturer='AuthenticAMD' }
    $cases = @(
        [pscustomobject]@{ Input='AMD64'; Expected='x86_64' },
        [pscustomobject]@{ Input='X64'; Expected='x86_64' },
        [pscustomobject]@{ Input='x86_64'; Expected='x86_64' },
        [pscustomobject]@{ Input='64-bit'; Expected='x86_64' },
        [pscustomobject]@{ Input='64 ビット'; Expected='x86_64' },
        [pscustomobject]@{ Input='x86'; Expected='x86' },
        [pscustomobject]@{ Input='ARM64'; Expected='arm64' }
    )
    $failures = New-Object System.Collections.Generic.List[string]
    foreach ($case in $cases) {
        $actual = ConvertTo-AmdNormalizedArchitecture -Architecture $case.Input -Cpu $cpu
        if ($actual -ne $case.Expected) {
            $failures.Add(('{0}: expected {1}, got {2}' -f $case.Input,$case.Expected,$actual))
        }
    }
    return [pscustomobject][ordered]@{
        Status = if ($failures.Count -eq 0) { 'Pass' } else { 'Fail' }
        CaseCount = $cases.Count
        Failures = @($failures.ToArray())
    }
}

function Select-AmdSelectorProductsForHost {
    [CmdletBinding()]
    param(
        [AllowNull()][object[]]$Products,
        [AllowNull()][object]$HostInventory,
        [AllowNull()][string]$ReleaseVersion,
        [AllowNull()][object]$SelectorBinaryEvidence
    )

    $all=@($Products)
    if ($all.Count -eq 0 -or $null -eq $HostInventory -or $null -eq $HostInventory.OS) {
        return [pscustomobject][ordered]@{ Status='NotEvaluated'; MatchingProducts=@($all); EvidenceLevel='AmdDeclarativeProven'; OsClassification=$null; Notes=@() }
    }
    $caption=[string]$HostInventory.OS.Caption
    $productType=[int]$HostInventory.OS.ProductType
    $build=0
    try { $build=[int]$HostInventory.OS.BuildNumber } catch { }

    # Prefer a vetted exact-binary contract over heuristic ProductType/build inference.
    $compiledContract=$null
    if($null -ne $SelectorBinaryEvidence -and $null -ne $SelectorBinaryEvidence.PSObject.Properties['CompiledSelectorContract']){
        $compiledContract=$SelectorBinaryEvidence.CompiledSelectorContract
    }
    if($null -ne $compiledContract){
        $classification=Get-AmdCompiledSelectorOsClassification -CompiledSelectorContract $compiledContract -Caption $caption
        $osArch=[string]$HostInventory.OS.OSArchitecture
        $normalizedArch=Get-AmdHostNormalizedArchitecture -HostInventory $HostInventory
        $is64=($normalizedArch -eq 'x86_64')
        if(-not $is64){
            return [pscustomobject][ordered]@{Status='CompiledArchitectureNotMatched';MatchingProducts=@();EvidenceLevel='AmdCompiledStaticProven';OsClassification=$classification;Notes=@(('The exact SHA-256-scoped Qt selector Client branch compares QSysInfo currentCpuArchitecture with x86_64. Raw host architecture="{0}", normalized="{1}".' -f $osArch,$normalizedArch))}
        }
        if([int]$classification.EnumValue -lt 0){
            return [pscustomobject][ordered]@{
                Status='CompiledCaptionClassificationExclusion'
                MatchingProducts=@()
                EvidenceLevel='AmdCompiledStaticProven'
                OsClassification=$classification
                Notes=@(
                    'The exact SHA-256-scoped Qt Setup.exe initializes its OS-family field to -1 and changes it only when Win32_OperatingSystem.Caption contains Windows 7, Windows 10, or Windows 11 (case-insensitive).',
                    ('Caption "{0}" matches none of those client substrings, so the enum remains -1. In the Client Info.xml branch, enum -1 appends no product to the filtered XML list.' -f $caption),
                    ('This is a compiled AMD selector condition for release {0} and is independent from the Microsoft INF ProductType/TargetOSVersion analysis. Dynamic corroboration is reported only when separately available for that release.' -f [string]$compiledContract.Scope.ReleaseVersion),
                    'The code path is scoped to the exact recovered Setup.exe SHA-256 and must not be generalized to other AMD releases.'
                )
            }
        }
        $targetLabel=[string]$classification.XmlOsLabel
        $matching=New-Object System.Collections.Generic.List[object]
        foreach($product in $all){
            $os=[string]$product.OS
            if([string]::IsNullOrWhiteSpace($os)){ $matching.Add($product); continue }
            if($targetLabel -and $os.Equals($targetLabel,[System.StringComparison]::OrdinalIgnoreCase)){ $matching.Add($product) }
        }
        if($matching.Count -gt 0){
            return [pscustomobject][ordered]@{Status='MatchingEmbeddedOsEntryCompiled';MatchingProducts=@($matching.ToArray());EvidenceLevel='AmdCompiledStaticProven';OsClassification=$classification;Notes=@(('Exact-binary Qt selector classification maps this host to Info.xml OS label "{0}".' -f $targetLabel))}
        }
        return [pscustomobject][ordered]@{Status='NoMatchingEmbeddedOsEntryCompiled';MatchingProducts=@();EvidenceLevel='AmdCompiledStaticProven';OsClassification=$classification;Notes=@(('Exact-binary Qt selector classification maps this host to "{0}", but this component has no matching Info.xml product record.' -f $targetLabel))}
    }

    # Fallback for releases/binaries without a code-level contract.
    if ($productType -ne 1) {
        if ($productType -eq 3 -and $ReleaseVersion -eq '8.07.16.1035') {
            return [pscustomobject][ordered]@{ Status='ObservedServerXmlListExclusion'; MatchingProducts=@(); EvidenceLevel='AmdDynamicObservedMultiHost'; OsClassification=$null; Notes=@('Fallback only: for AMD Chipset Software 8.07.16.1035, independent Server 2022 and Server 2025 observations both show an explicitly empty final SupportedDrivers list. Prefer the SHA-256-scoped compiled Qt selector contract whenever static selector evidence is available.') }
        }
        return [pscustomobject][ordered]@{ Status='HostOsFamilyMappingUnknown'; MatchingProducts=@($all); EvidenceLevel='AmdStaticInferred'; OsClassification=$null; Notes=@('Info.xml uses client OS labels; this toolkit does not infer AMD manifest selection behavior for Windows Server unless compiled or release-scoped dynamic evidence exists.') }
    }
    $isWin11=($caption -match '(?i)Windows\s+11' -or $build -ge 22000)
    $isWin10=($caption -match '(?i)Windows\s+10' -or ($build -gt 0 -and $build -lt 22000))
    $matching=New-Object System.Collections.Generic.List[object]
    foreach($product in $all){
        $os=[string]$product.OS
        if([string]::IsNullOrWhiteSpace($os)){ $matching.Add($product); continue }
        if($isWin11 -and $os -match '(?i)Windows\s*11'){ $matching.Add($product); continue }
        if($isWin10 -and $os -match '(?i)Windows\s*10'){ $matching.Add($product); continue }
    }
    if($matching.Count -gt 0){
        return [pscustomobject][ordered]@{ Status='MatchingEmbeddedOsEntry'; MatchingProducts=@($matching.ToArray()); EvidenceLevel='AmdStaticInferred'; OsClassification=$null; Notes=@('Info.xml product OS label matches the actual client OS family. Use as selector evidence, not as a documented AMD contract.') }
    }
    return [pscustomobject][ordered]@{ Status='NoMatchingEmbeddedOsEntry'; MatchingProducts=@(); EvidenceLevel='AmdStaticInferred'; OsClassification=$null; Notes=@('Matching AMD component exists in Info.xml, but only for a different client OS family. This is a static explanation candidate for AMD-side filtering.') }
}

function Get-AmdRecoveredTopLevelMsiPath {
    [CmdletBinding()]
    param([Parameter(Mandatory=$true)][object]$ExtractionRelease)

    foreach ($container in @($ExtractionRelease.Containers)) {
        $path = [string]$container.ContainerPath
        if (-not $path) { continue }
        if ([System.IO.Path]::GetFileName($path) -ieq 'AMD_Chipset_Drivers.msi' -and (Test-Path -LiteralPath $path -PathType Leaf)) {
            return (Resolve-Path -LiteralPath $path).Path
        }
    }
    return $null
}

function Get-AmdMsiRecordStringData {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][object]$Record,
        [Parameter(Mandatory=$true)][int]$Field
    )

    # Windows Installer exposes StringData as an indexed Automation property. PowerShell's
    # COM adapter does not surface every Windows Installer property consistently across
    # Windows PowerShell 5.1 and PowerShell 7, so keep both the normal adapter path and an
    # IDispatch/reflection fallback.
    $directError = $null
    try {
        return [string]$Record.StringData($Field)
    }
    catch {
        $directError = $_.Exception.Message
    }

    try {
        $flags = [System.Reflection.BindingFlags]::GetProperty
        return [string]$Record.GetType().InvokeMember(
            'StringData',
            $flags,
            $null,
            $Record,
            [object[]]@([int]$Field)
        )
    }
    catch {
        throw ('Unable to read Windows Installer Record.StringData field {0}. Adapter error: {1}; IDispatch error: {2}' -f $Field,$directError,$_.Exception.Message)
    }
}

function Get-AmdMsiViewColumnInfoRecord {
    [CmdletBinding()]
    param([Parameter(Mandatory=$true)][object]$View)

    $directError = $null
    try {
        return $View.ColumnInfo(0)
    }
    catch {
        $directError = $_.Exception.Message
    }

    try {
        $flags = [System.Reflection.BindingFlags]::GetProperty
        return $View.GetType().InvokeMember(
            'ColumnInfo',
            $flags,
            $null,
            $View,
            [object[]]@(0)
        )
    }
    catch {
        throw ('Unable to read Windows Installer View.ColumnInfo. Adapter error: {0}; IDispatch error: {1}' -f $directError,$_.Exception.Message)
    }
}

function Get-AmdMsiColumnNamesFromRecord {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][object]$ColumnRecord,
        [int]$MaximumColumns = 128
    )

    # Do not depend on Record.FieldCount. Real Windows PowerShell 5.1 evidence from
    # 2026-08-11 showed that the Windows Installer COM Record was usable while FieldCount
    # was not surfaced by the PowerShell COM adapter. ColumnInfo returns one non-empty
    # name per selected nonconstant column, so probe StringData sequentially until the
    # record reports end-of-fields.
    $columns = New-Object System.Collections.Generic.List[string]
    for ($i=1; $i -le $MaximumColumns; $i++) {
        $name = $null
        try {
            $name = Get-AmdMsiRecordStringData -Record $ColumnRecord -Field $i
        }
        catch {
            if ($i -eq 1) { throw }
            break
        }
        if ([string]::IsNullOrWhiteSpace([string]$name)) { break }
        $columns.Add([string]$name)
    }

    if ($columns.Count -eq 0) {
        throw 'Windows Installer View.ColumnInfo returned no usable column names.'
    }
    if ($columns.Count -ge $MaximumColumns) {
        throw ('Windows Installer column discovery reached the safety limit ({0}) without an end-of-fields signal.' -f $MaximumColumns)
    }
    return @($columns.ToArray())
}

function Invoke-AmdMsiViewFetch {
    [CmdletBinding()]
    param([Parameter(Mandatory=$true)][object]$View)

    $directError = $null
    try {
        return $View.Fetch()
    }
    catch {
        $directError = $_.Exception.Message
    }

    try {
        $flags = [System.Reflection.BindingFlags]::InvokeMethod
        return $View.GetType().InvokeMember('Fetch',$flags,$null,$View,[object[]]@())
    }
    catch {
        throw ('Unable to invoke Windows Installer View.Fetch. Adapter error: {0}; IDispatch error: {1}' -f $directError,$_.Exception.Message)
    }
}

function Get-AmdMsiTableRows {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][object]$Database,
        [Parameter(Mandatory=$true)][string]$TableName,
        [int]$MaximumRows = 5000
    )

    $rows = New-Object System.Collections.Generic.List[object]
    $view = $null
    $columnRecord = $null
    try {
        $query = ('SELECT * FROM `{0}`' -f $TableName.Replace('`',''))
        $view = $Database.OpenView($query)
        [void]$view.Execute()
        $columnRecord = Get-AmdMsiViewColumnInfoRecord -View $view
        $columns = @(Get-AmdMsiColumnNamesFromRecord -ColumnRecord $columnRecord)
        $columnCount = $columns.Count
        $count = 0
        while ($count -lt $MaximumRows) {
            $record = Invoke-AmdMsiViewFetch -View $view
            if ($null -eq $record) { break }
            $obj = [ordered]@{}
            for ($i=1; $i -le $columnCount; $i++) {
                $value = $null
                try { $value = Get-AmdMsiRecordStringData -Record $record -Field $i } catch { $value = $null }
                $obj[$columns[$i-1]] = $value
            }
            $rows.Add([pscustomobject]$obj)
            $count++
            try { [void][System.Runtime.InteropServices.Marshal]::FinalReleaseComObject($record) } catch { }
        }
    }
    finally {
        if ($null -ne $columnRecord) { try { [void][System.Runtime.InteropServices.Marshal]::FinalReleaseComObject($columnRecord) } catch { } }
        if ($null -ne $view) { try { [void]$view.Close() } catch { }; try { [void][System.Runtime.InteropServices.Marshal]::FinalReleaseComObject($view) } catch { } }
    }
    return @($rows.ToArray())
}

function Get-AmdMsiTableNamesFromRows {
    [CmdletBinding()]
    param([AllowNull()][object[]]$Rows)

    $names = New-Object System.Collections.Generic.List[string]
    foreach ($row in @($Rows)) {
        if ($null -eq $row) { continue }
        $value = $null
        $nameProperty = $row.PSObject.Properties['Name']
        if ($null -ne $nameProperty) {
            $value = [string]$nameProperty.Value
        }
        else {
            $properties = @($row.PSObject.Properties)
            if ($properties.Count -eq 1) {
                $value = [string]$properties[0].Value
            }
        }
        if (-not [string]::IsNullOrWhiteSpace($value)) { $names.Add($value) }
    }
    return @($names.ToArray() | Sort-Object -Unique)
}

function Test-AmdMsiTableNameProjectionSelfTest {
    [CmdletBinding()]
    param()

    $normal = @([pscustomobject]@{Name='Feature'},[pscustomobject]@{Name='Property'})
    $fallback = @([pscustomobject]@{Column1='CustomAction'})
    $normalNames = @(Get-AmdMsiTableNamesFromRows -Rows $normal)
    $fallbackNames = @(Get-AmdMsiTableNamesFromRows -Rows $fallback)
    $ok = (($normalNames -contains 'Feature') -and ($normalNames -contains 'Property') -and ($fallbackNames -contains 'CustomAction'))
    return [pscustomobject][ordered]@{
        Status = if ($ok) { 'Pass' } else { 'Fail' }
        NormalCount = $normalNames.Count
        FallbackCount = $fallbackNames.Count
    }
}

function Test-AmdMsiFieldCountIndependentColumnDiscoverySelfTest {
    [CmdletBinding()]
    param()

    # Mimic the real Windows PowerShell 5.1 failure shape: StringData works but no
    # FieldCount property is visible to the PowerShell adapter.
    $mock = [pscustomobject]@{ Values=@('Name','Value') }
    $mock | Add-Member -MemberType ScriptMethod -Name StringData -Value {
        param([int]$Field)
        if ($Field -ge 1 -and $Field -le $this.Values.Count) { return [string]$this.Values[$Field-1] }
        return $null
    } -Force

    $columns = @(Get-AmdMsiColumnNamesFromRecord -ColumnRecord $mock -MaximumColumns 16)
    $hasFieldCount = ($null -ne $mock.PSObject.Properties['FieldCount'])
    $ok = (-not $hasFieldCount -and $columns.Count -eq 2 -and $columns[0] -eq 'Name' -and $columns[1] -eq 'Value')
    return [pscustomobject][ordered]@{
        Status = if ($ok) { 'Pass' } else { 'Fail' }
        FieldCountPropertyPresent = $hasFieldCount
        ColumnCount = $columns.Count
        Columns = @($columns)
    }
}

function Test-AmdMsiTableRowPipelineIsolationSelfTest {
    [CmdletBinding()]
    param()

    function New-AmdMockMsiRecord {
        param([object[]]$Values)
        $record = [pscustomobject]@{ Values=@($Values) }
        $record | Add-Member -MemberType ScriptMethod -Name StringData -Value {
            param([int]$Field)
            if ($Field -ge 1 -and $Field -le $this.Values.Count) { return [string]$this.Values[$Field-1] }
            return $null
        } -Force
        return $record
    }

    $view = [pscustomobject]@{
        Index = 0
        Records = @(
            (New-AmdMockMsiRecord -Values @('A','1')),
            (New-AmdMockMsiRecord -Values @('B','2'))
        )
        ColumnRecord = (New-AmdMockMsiRecord -Values @('Name','Value'))
    }
    $view | Add-Member -MemberType ScriptMethod -Name Execute -Value { return '__EXECUTE_SENTINEL__' } -Force
    $view | Add-Member -MemberType ScriptMethod -Name ColumnInfo -Value { param([int]$Kind) return $this.ColumnRecord } -Force
    $view | Add-Member -MemberType ScriptMethod -Name Fetch -Value {
        if ($this.Index -ge $this.Records.Count) { return $null }
        $value = $this.Records[$this.Index]
        $this.Index++
        return $value
    } -Force
    $view | Add-Member -MemberType ScriptMethod -Name Close -Value { return '__CLOSE_SENTINEL__' } -Force

    $database = [pscustomobject]@{ View=$view }
    $database | Add-Member -MemberType ScriptMethod -Name OpenView -Value { param([string]$Query) return $this.View } -Force

    $rows = @(Get-AmdMsiTableRows -Database $database -TableName 'Property' -MaximumRows 16)
    $nullRows = @($rows | Where-Object {
        $null -eq $_ -or (
            $null -ne $_.PSObject.Properties['Name'] -and
            $null -ne $_.PSObject.Properties['Value'] -and
            [string]::IsNullOrEmpty([string]$_.Name) -and
            [string]::IsNullOrEmpty([string]$_.Value)
        )
    })
    $ok = (
        $rows.Count -eq 2 -and $nullRows.Count -eq 0 -and
        [string]$rows[0].Name -eq 'A' -and [string]$rows[0].Value -eq '1' -and
        [string]$rows[1].Name -eq 'B' -and [string]$rows[1].Value -eq '2'
    )
    return [pscustomobject][ordered]@{
        Status = if ($ok) { 'Pass' } else { 'Fail' }
        RowCount = $rows.Count
        NullRowCount = $nullRows.Count
        ExecuteSentinelLeaked = (@($rows | Where-Object { [string]$_ -eq '__EXECUTE_SENTINEL__' }).Count -gt 0)
        CloseSentinelLeaked = (@($rows | Where-Object { [string]$_ -eq '__CLOSE_SENTINEL__' }).Count -gt 0)
    }
}

function Invoke-AmdMsiDeclarativeAnalysis {
    [CmdletBinding()]
    param([AllowNull()][string]$MsiPath)

    $platform = Get-AmdPlatformInfo
    if ([string]::IsNullOrWhiteSpace($MsiPath)) {
        return [pscustomobject][ordered]@{ Status='MsiNotRecovered'; MsiPath=$null; MsiSha256=$null; Tables=@{}; Errors=@() }
    }
    if ($platform.PlatformFamily -ne 'Windows') {
        return [pscustomobject][ordered]@{ Status='WindowsInstallerComUnavailableOnPlatform'; MsiPath=$MsiPath; MsiSha256=(Get-AmdSha256 -Path $MsiPath); Tables=@{}; Errors=@('Windows Installer COM read-only database inspection is Windows-only in this development line.') }
    }

    $installer = $null
    $db = $null
    $errors = New-Object System.Collections.Generic.List[string]
    $tablesResult = [ordered]@{}
    try {
        $installer = New-Object -ComObject WindowsInstaller.Installer
        $db = $installer.OpenDatabase((Resolve-Path -LiteralPath $MsiPath).Path, 0)
        $tableRows = @(Get-AmdMsiTableRows -Database $db -TableName '_Tables')
        $tableNames = @(Get-AmdMsiTableNamesFromRows -Rows $tableRows)
        if ($tableNames.Count -eq 0) {
            throw 'Windows Installer _Tables query returned rows but no usable table names.'
        }
        $wanted = @('Property','Feature','Condition','LaunchCondition','AppSearch','RegLocator','CustomAction','InstallUISequence','InstallExecuteSequence','Upgrade')
        foreach ($table in $wanted) {
            if ($tableNames -contains $table) {
                try { $tablesResult[$table] = @(Get-AmdMsiTableRows -Database $db -TableName $table) }
                catch { $errors.Add(('{0}: {1}' -f $table, $_.Exception.Message)); $tablesResult[$table] = @() }
            }
        }
        $qualityProbe = Get-AmdMsiDeclarativeEvidenceQuality -MsiDeclarativeAnalysis ([pscustomobject]@{ Tables=[pscustomobject]$tablesResult })
        if ([int]$qualityProbe.AllNullRowCount -gt 0) {
            $errors.Add(('MSI declarative table output contains {0} all-null row(s); evidence quality requires review.' -f $qualityProbe.AllNullRowCount))
        }
        $quality = [pscustomobject][ordered]@{
            TableCount = [int]$qualityProbe.TableCount
            TotalRowCount = [int]$qualityProbe.TotalRowCount
            AllNullRowCount = [int]$qualityProbe.AllNullRowCount
            ErrorCount = $errors.Count
        }

        return [pscustomobject][ordered]@{
            Status = if ($errors.Count -eq 0) { 'ParsedReadOnly' } else { 'ParsedWithErrors' }
            MsiPath = (Resolve-Path -LiteralPath $MsiPath).Path
            MsiSha256 = Get-AmdSha256 -Path $MsiPath
            TableNames = @($tableNames)
            Tables = [pscustomobject]$tablesResult
            Quality = $quality
            Errors = @($errors.ToArray())
        }
    }
    catch {
        return [pscustomobject][ordered]@{ Status='ParseFailed'; MsiPath=$MsiPath; MsiSha256=(Get-AmdSha256 -Path $MsiPath); Tables=@{}; Errors=@($_.Exception.Message) }
    }
    finally {
        if ($null -ne $db) { try { [void][System.Runtime.InteropServices.Marshal]::FinalReleaseComObject($db) } catch { } }
        if ($null -ne $installer) { try { [void][System.Runtime.InteropServices.Marshal]::FinalReleaseComObject($installer) } catch { } }
    }
}

function Get-AmdPrintableAsciiStrings {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][string]$Path,
        [int]$MinimumLength = 4
    )
    $bytes = [System.IO.File]::ReadAllBytes((Resolve-Path -LiteralPath $Path).Path)
    $text = [System.Text.Encoding]::ASCII.GetString($bytes)
    $pattern = ('[ -~]{{{0},}}' -f $MinimumLength)
    $values = New-Object System.Collections.Generic.List[string]
    foreach ($m in [regex]::Matches($text, $pattern)) {
        $value = $m.Value.Trim()
        if ($value -and -not $values.Contains($value)) { $values.Add($value) }
    }
    return @($values.ToArray())
}

function Get-AmdPrintableUnicodeStrings {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][string]$Path,
        [int]$MinimumLength = 4
    )
    $bytes = [System.IO.File]::ReadAllBytes((Resolve-Path -LiteralPath $Path).Path)
    $text = [System.Text.Encoding]::Unicode.GetString($bytes)
    $pattern = ('[ -~]{{{0},}}' -f $MinimumLength)
    $values = New-Object System.Collections.Generic.List[string]
    foreach ($m in [regex]::Matches($text, $pattern)) {
        $value = $m.Value.Trim()
        if ($value -and -not $values.Contains($value)) { $values.Add($value) }
    }
    return @($values.ToArray())
}

function Get-AmdKnownCompiledSelectorContract {
    [CmdletBinding()]
    param(
        [AllowNull()][string]$ReleaseVersion,
        [AllowNull()][string]$SelectorBinarySha256
    )

    $hash = if ($SelectorBinarySha256) { $SelectorBinarySha256.ToLowerInvariant() } else { '' }
    if ($ReleaseVersion -eq '3.10.08.506' -and $hash -eq '4a0cf13c66f873319ff44eba1867f9cc7dc865d0f422c007bcb25c6ced148ee9') {
        return [pscustomobject][ordered]@{
            SchemaVersion = 'amd-chipset-compiled-selector-contract/1.0'
            ContractId = '3.10.08.506|QtSetup|4a0cf13c66f873319ff44eba1867f9cc7dc865d0f422c007bcb25c6ced148ee9'
            EvidenceLevel = 'AmdCompiledStaticProven'
            Scope = [pscustomobject][ordered]@{
                ReleaseVersion = '3.10.08.506'
                SelectorBinarySha256 = '4a0cf13c66f873319ff44eba1867f9cc7dc865d0f422c007bcb25c6ced148ee9'
                SelectorBinary = 'Qt_Dependencies/Setup.exe'
                ImageBase = '0x00400000'
                PeArchitecture = 'x86'
                QtGeneration = 'Qt5'
                Generalization = 'ExactBinaryOnly'
                ProvenScope = @('HostOsDetection','InfoXmlFilter')
            }
            HostOsDetection = [pscustomobject][ordered]@{
                FunctionVa = '0x0040d2b0'
                WmiNamespace = 'root\cimv2'
                WmiQuery = 'Select * from Win32_OperatingSystem'
                WmiFields = @('BuildNumber','Caption','Version')
                OsFamilyFieldOffset = '0xe0'
                InitialValue = 3
                MatchSource = 'Win32_OperatingSystem.Caption'
                MatchKind = 'CaseInsensitiveSubstring'
                OrderedMappings = @(
                    [pscustomobject][ordered]@{ Contains='Windows 7'; EnumValue=0; ClientXmlOsLabel='Windows 7(64-bit)' },
                    [pscustomobject][ordered]@{ Contains='Windows 10'; EnumValue=1; ClientXmlOsLabel='Windows 10(64-bit)' },
                    [pscustomobject][ordered]@{ Contains='Windows 11'; EnumValue=2; ClientXmlOsLabel='Windows 11(64-bit)' }
                )
                Observation = 'The exact 3.10.08.506 x86 Qt5 selector initializes the OS-family field to 3 and changes it only for Windows 7/10/11 Caption substrings. No ProductType string or WMI ProductType query was recovered in this code path.'
            }
            InfoXmlFilter = [pscustomobject][ordered]@{
                FunctionVa = '0x0040d720'
                ManifestPath = '/info.xml'
                Fields = @('Version','OS','Installer','Brand')
                ArchitectureLiteral = 'x86_64'
                ClientBranch = [pscustomobject][ordered]@{
                    ArchitectureRequirement = 'x86_64'
                    EnumToXmlOsLabel = @(
                        [pscustomobject][ordered]@{ EnumValue=0; XmlOsLabel='Windows 7(64-bit)' },
                        [pscustomobject][ordered]@{ EnumValue=1; XmlOsLabel='Windows 10(64-bit)' },
                        [pscustomobject][ordered]@{ EnumValue=2; XmlOsLabel='Windows 11(64-bit)' }
                    )
                    UnknownEnumBehavior = 'NoProductAppended'
                }
                Observation = 'The recovered 3.10.08.506 manifest contains Client records only for Windows 10(64-bit) and Windows 11(64-bit). Enum 3 reaches no recovered Client OS-label branch, so an unmatched Windows Server caption contributes no matching Client product.'
            }
            UnresolvedHardwarePredicates = @(
                [pscustomobject][ordered]@{
                    Candidate = '/SETFILTERUSB'
                    Status = 'Unresolved'
                    Observation = 'The binary contains the property literal but not the 7.x/8.x DEV_790B/DEV_780B and REV_16/REV_61/REV_59/REV_51 token vocabulary. The exact compiled FILTERUSB survival/removal predicate has not been proven for this binary.'
                },
                [pscustomobject][ordered]@{
                    Candidate = '/SETRYZENPPKG'
                    Status = 'Unresolved'
                    Observation = 'The binary contains the property literal but not the 7.x/8.x DEV_790B/DEV_780B and REV_16/REV_61/REV_59/REV_51 token vocabulary. The exact compiled RYZENPPKG candidate predicate has not been proven for this binary.'
                }
            )
            ReverseEngineeringNotes = @(
                'Function addresses and OS/XML predicates were recovered from static x86 disassembly of the exact SHA-256-scoped 3.10.08.506 Qt Setup.exe binary. The toolkit did not execute this binary.',
                'This release uses Qt5 and a 32-bit selector and carries no recovered DevID.xml. The later 7.x/8.x DevID declarative mapping model is not retroactively inferred.',
                'SETFILTERUSB and SETRYZENPPKG hardware predicates remain explicitly unresolved for this release. Do not import the separately proven 7.x/8.x predicates into this contract.',
                'Do not generalize this compiled contract to another AMD release or selector binary.'
            )
        }
    }

    if ($ReleaseVersion -eq '4.08.09.2337' -and $hash -eq '95d0428ea90bee14704bf556a3ad6c91971e63d6d63c0807e9e7a8791d024160') {
        return [pscustomobject][ordered]@{
            SchemaVersion = 'amd-chipset-compiled-selector-contract/1.0'
            ContractId = '4.08.09.2337|QtSetup|95d0428ea90bee14704bf556a3ad6c91971e63d6d63c0807e9e7a8791d024160'
            EvidenceLevel = 'AmdCompiledStaticProven'
            Scope = [pscustomobject][ordered]@{
                ReleaseVersion = '4.08.09.2337'
                SelectorBinarySha256 = '95d0428ea90bee14704bf556a3ad6c91971e63d6d63c0807e9e7a8791d024160'
                SelectorBinary = 'Qt_Dependencies/Setup.exe'
                ImageBase = '0x00400000'
                PeArchitecture = 'x86'
                QtGeneration = 'Qt5'
                Generalization = 'ExactBinaryOnly'
                ProvenScope = @('HostOsDetection','InfoXmlFilter')
            }
            HostOsDetection = [pscustomobject][ordered]@{
                FunctionVa = '0x0040cfa0'
                WmiNamespace = 'root\cimv2'
                WmiQuery = 'Select * from Win32_OperatingSystem'
                WmiFields = @('BuildNumber','Caption','Version')
                OsFamilyFieldOffset = '0xa4'
                InitialValue = 3
                MatchSource = 'Win32_OperatingSystem.Caption'
                MatchKind = 'CaseInsensitiveSubstring'
                OrderedMappings = @(
                    [pscustomobject][ordered]@{ Contains='Windows 7'; EnumValue=0; ClientXmlOsLabel='Windows 7(64-bit)' },
                    [pscustomobject][ordered]@{ Contains='Windows 10'; EnumValue=1; ClientXmlOsLabel='Windows 10(64-bit)' },
                    [pscustomobject][ordered]@{ Contains='Windows 11'; EnumValue=2; ClientXmlOsLabel='Windows 11(64-bit)' }
                )
                Observation = 'The exact 4.08.09.2337 x86 Qt5 selector initializes the OS-family field to 3 and changes it only for Windows 7/10/11 Caption substrings. No ProductType string or WMI ProductType query was recovered in this code path.'
            }
            InfoXmlFilter = [pscustomobject][ordered]@{
                FunctionVa = '0x0040d3f0'
                ManifestPath = '/info.xml'
                Fields = @('Version','OS','Installer','Brand')
                ArchitectureLiteral = 'x86_64'
                ClientBranch = [pscustomobject][ordered]@{
                    ArchitectureRequirement = 'x86_64'
                    EnumToXmlOsLabel = @(
                        [pscustomobject][ordered]@{ EnumValue=0; XmlOsLabel='Windows 7(64-bit)' },
                        [pscustomobject][ordered]@{ EnumValue=1; XmlOsLabel='Windows 10(64-bit)' },
                        [pscustomobject][ordered]@{ EnumValue=2; XmlOsLabel='Windows 11(64-bit)' }
                    )
                    UnknownEnumBehavior = 'NoProductAppended'
                }
                Observation = 'The recovered 4.08.09.2337 manifest contains Client records only for Windows 10(64-bit) and Windows 11(64-bit). Enum 3 reaches no recovered Client OS-label branch, so an unmatched Windows Server caption contributes no matching Client product.'
            }
            UnresolvedHardwarePredicates = @(
                [pscustomobject][ordered]@{
                    Candidate = '/SETFILTERUSB'
                    Status = 'Unresolved'
                    Observation = 'The binary contains the property literal but not the 7.x/8.x DEV_790B/DEV_780B and REV_16/REV_61/REV_59/REV_51 token vocabulary. The exact compiled FILTERUSB survival/removal predicate has not been proven for this binary.'
                },
                [pscustomobject][ordered]@{
                    Candidate = '/SETRYZENPPKG'
                    Status = 'Unresolved'
                    Observation = 'The binary contains the property literal but not the 7.x/8.x DEV_790B/DEV_780B and REV_16/REV_61/REV_59/REV_51 token vocabulary. The exact compiled RYZENPPKG candidate predicate has not been proven for this binary.'
                }
            )
            ReverseEngineeringNotes = @(
                'Function addresses and OS/XML predicates were recovered from static x86 disassembly of the exact SHA-256-scoped 4.08.09.2337 Qt Setup.exe binary. The toolkit did not execute this binary.',
                'This release uses Qt5 and a 32-bit selector and carries no recovered DevID.xml. The later 7.x/8.x DevID declarative mapping model is not retroactively inferred.',
                'SETFILTERUSB and SETRYZENPPKG hardware predicates remain explicitly unresolved for this release. Do not import the separately proven 7.x/8.x predicates into this contract.',
                'Do not generalize this compiled contract to another AMD release or selector binary.'
            )
        }
    }

    if ($ReleaseVersion -eq '5.08.02.027' -and $hash -eq '8f4e0f27397786275db0a45282b05bf39da1f16ee9379712a75544fdb49460cf') {
        return [pscustomobject][ordered]@{
            SchemaVersion = 'amd-chipset-compiled-selector-contract/1.0'
            ContractId = '5.08.02.027|QtSetup|8f4e0f27397786275db0a45282b05bf39da1f16ee9379712a75544fdb49460cf'
            EvidenceLevel = 'AmdCompiledStaticProven'
            Scope = [pscustomobject][ordered]@{
                ReleaseVersion = '5.08.02.027'
                SelectorBinarySha256 = '8f4e0f27397786275db0a45282b05bf39da1f16ee9379712a75544fdb49460cf'
                SelectorBinary = 'Qt_Dependencies/Setup.exe'
                ImageBase = '0x00400000'
                PeArchitecture = 'x86'
                QtGeneration = 'Qt5'
                Generalization = 'ExactBinaryOnly'
                ProvenScope = @('HostOsDetection','InfoXmlFilter')
            }
            HostOsDetection = [pscustomobject][ordered]@{
                FunctionVa = '0x0040cfa0'
                WmiNamespace = 'root\cimv2'
                WmiQuery = 'Select * from Win32_OperatingSystem'
                WmiFields = @('BuildNumber','Caption','Version')
                OsFamilyFieldOffset = '0xac'
                InitialValue = 3
                MatchSource = 'Win32_OperatingSystem.Caption'
                MatchKind = 'CaseInsensitiveSubstring'
                OrderedMappings = @(
                    [pscustomobject][ordered]@{ Contains='Windows 7'; EnumValue=0; ClientXmlOsLabel='Windows 7(64-bit)' },
                    [pscustomobject][ordered]@{ Contains='Windows 10'; EnumValue=1; ClientXmlOsLabel='Windows 10(64-bit)' },
                    [pscustomobject][ordered]@{ Contains='Windows 11'; EnumValue=2; ClientXmlOsLabel='Windows 11(64-bit)' }
                )
                Observation = 'The exact 5.08.02.027 x86 Qt5 selector initializes the OS-family field to 3 and changes it only for Windows 7/10/11 Caption substrings. No ProductType string or WMI ProductType query was recovered in this code path.'
            }
            InfoXmlFilter = [pscustomobject][ordered]@{
                FunctionVa = '0x0040d3f0'
                ManifestPath = '/info.xml'
                Fields = @('Version','OS','Installer','Brand')
                ArchitectureLiteral = 'x86_64'
                ClientBranch = [pscustomobject][ordered]@{
                    ArchitectureRequirement = 'x86_64'
                    EnumToXmlOsLabel = @(
                        [pscustomobject][ordered]@{ EnumValue=0; XmlOsLabel='Windows 7(64-bit)' },
                        [pscustomobject][ordered]@{ EnumValue=1; XmlOsLabel='Windows 10(64-bit)' },
                        [pscustomobject][ordered]@{ EnumValue=2; XmlOsLabel='Windows 11(64-bit)' }
                    )
                    UnknownEnumBehavior = 'NoProductAppended'
                }
                Observation = 'The recovered 5.08.02.027 manifest contains Client records only for Windows 10(64-bit) and Windows 11(64-bit). Enum 3 reaches no recovered Client OS-label branch, so an unmatched Windows Server caption contributes no matching Client product.'
            }
            UnresolvedHardwarePredicates = @(
                [pscustomobject][ordered]@{
                    Candidate = '/SETFILTERUSB'
                    Status = 'Unresolved'
                    Observation = 'The binary contains older hardware literals including AMD SMBUS, 790B, 14EC and 14AC, but not the 7.x/8.x DEV_/REV_ token contract. The exact compiled FILTERUSB survival/removal predicate has not been proven for this binary.'
                },
                [pscustomobject][ordered]@{
                    Candidate = '/SETRYZENPPKG'
                    Status = 'Unresolved'
                    Observation = 'The binary contains older hardware literals including AMD SMBUS, 790B, 14EC and 14AC, but not the 7.x/8.x DEV_/REV_ token contract. The exact compiled RYZENPPKG candidate predicate has not been proven for this binary.'
                }
            )
            ReverseEngineeringNotes = @(
                'Function addresses and OS/XML predicates were recovered from static x86 disassembly of the exact SHA-256-scoped 5.08.02.027 Qt Setup.exe binary. The toolkit did not execute this binary.',
                'This release uses Qt5 and a 32-bit selector and carries no recovered DevID.xml. The later 7.x/8.x DevID declarative mapping model is not retroactively inferred.',
                'SETFILTERUSB and SETRYZENPPKG hardware predicates remain explicitly unresolved for this release. Do not import the separately proven 7.x/8.x predicates into this contract.',
                'Do not generalize this compiled contract to another AMD release or selector binary.'
            )
        }
    }

    if ($ReleaseVersion -eq '6.10.17.152' -and $hash -eq '83d82a4775c0793ace86b1b07f98eadfc262f22d4c275fab2d74b9d86f19379a') {
        return [pscustomobject][ordered]@{
            SchemaVersion = 'amd-chipset-compiled-selector-contract/1.0'
            ContractId = '6.10.17.152|QtSetup|83d82a4775c0793ace86b1b07f98eadfc262f22d4c275fab2d74b9d86f19379a'
            EvidenceLevel = 'AmdCompiledStaticProven'
            Scope = [pscustomobject][ordered]@{
                ReleaseVersion = '6.10.17.152'
                SelectorBinarySha256 = '83d82a4775c0793ace86b1b07f98eadfc262f22d4c275fab2d74b9d86f19379a'
                SelectorBinary = 'Qt_Dependencies/Setup.exe'
                ImageBase = '0x00400000'
                PeArchitecture = 'x86'
                QtGeneration = 'Qt5'
                Generalization = 'ExactBinaryOnly'
                ProvenScope = @('HostOsDetection','InfoXmlFilter')
            }
            HostOsDetection = [pscustomobject][ordered]@{
                FunctionVa = '0x0040d8d0'
                WmiNamespace = 'root\cimv2'
                WmiQuery = 'Select * from Win32_OperatingSystem'
                WmiFields = @('BuildNumber','Caption','Version')
                OsFamilyFieldOffset = '0xac'
                InitialValue = 3
                MatchSource = 'Win32_OperatingSystem.Caption'
                MatchKind = 'CaseInsensitiveSubstring'
                OrderedMappings = @(
                    [pscustomobject][ordered]@{ Contains='Windows 7'; EnumValue=0; ClientXmlOsLabel='Windows 7(64-bit)' },
                    [pscustomobject][ordered]@{ Contains='Windows 10'; EnumValue=1; ClientXmlOsLabel='Windows 10(64-bit)' },
                    [pscustomobject][ordered]@{ Contains='Windows 11'; EnumValue=2; ClientXmlOsLabel='Windows 11(64-bit)' }
                )
                Observation = 'The exact 6.10.17.152 x86 Qt5 selector initializes the OS-family field to 3 and changes it only for Windows 7/10/11 Caption substrings. No ProductType string or query was recovered in this code path.'
            }
            InfoXmlFilter = [pscustomobject][ordered]@{
                FunctionVa = '0x0040dd20'
                ManifestPath = '/info.xml'
                Fields = @('Version','OS','Installer','Brand')
                ArchitectureLiteral = 'x86_64'
                ClientBranch = [pscustomobject][ordered]@{
                    ArchitectureRequirement = 'x86_64'
                    EnumToXmlOsLabel = @(
                        [pscustomobject][ordered]@{ EnumValue=0; XmlOsLabel='Windows 7(64-bit)' },
                        [pscustomobject][ordered]@{ EnumValue=1; XmlOsLabel='Windows 10(64-bit)' },
                        [pscustomobject][ordered]@{ EnumValue=2; XmlOsLabel='Windows 11(64-bit)' }
                    )
                    UnknownEnumBehavior = 'NoProductAppended'
                }
                Observation = 'The recovered 6.10.17.152 manifest contains Client records only for Windows 10(64-bit) and Windows 11(64-bit). Enum 3 reaches no recovered Client OS-label branch, so an unmatched Windows Server caption contributes no matching Client product.'
            }
            UnresolvedHardwarePredicates = @(
                [pscustomobject][ordered]@{
                    Candidate = '/SETFILTERUSB'
                    Status = 'Unresolved'
                    Observation = 'The property literal is present, but the 7.x/8.x DEV_790B/DEV_780B and REV_16 token literals do not exist in this binary. No equivalent exact compiled survival/removal predicate has been proven.'
                },
                [pscustomobject][ordered]@{
                    Candidate = '/SETRYZENPPKG'
                    Status = 'Unresolved'
                    Observation = 'The property literal is referenced by multiple x86 code paths and the binary contains older hardware literals including AMD SMBUS, 790B, 14EC and 14AC. The 7.x/8.x DEV_/REV_ token contract is absent, so the exact 6.x candidate predicate is not generalized.'
                }
            )
            ReverseEngineeringNotes = @(
                'Function addresses and OS/XML predicates were recovered from static x86 disassembly of the exact SHA-256-scoped 6.10.17.152 Qt Setup.exe binary. The toolkit did not execute this binary.',
                '6.10.17.152 uses Qt5 and a 32-bit selector. 7.11.26.2142 changes to Qt6/x64 and introduces DevID.xml; this is treated as a major implementation boundary.',
                'The absence of DevID.xml in the 6.10.17.152 extracted payload means 7.x/8.x DevID declarative device mapping is not retroactively inferred for 6.x.',
                'SETFILTERUSB and SETRYZENPPKG hardware predicates remain explicitly unresolved for this release. Do not import the separately proven 7.x/8.x predicates into this contract.',
                'Do not generalize this compiled contract to another AMD release or selector binary.'
            )
        }
    }

    if ($ReleaseVersion -eq '7.11.26.2142' -and $hash -eq '7b3714b3ff5c6add70987e0aacb0c5b5a2d523ea13ddf39bf0ac02b5f79d2b1a') {
        return [pscustomobject][ordered]@{
            SchemaVersion = 'amd-chipset-compiled-selector-contract/1.0'
            ContractId = '7.11.26.2142|QtSetup|7b3714b3ff5c6add70987e0aacb0c5b5a2d523ea13ddf39bf0ac02b5f79d2b1a'
            EvidenceLevel = 'AmdCompiledStaticProven'
            Scope = [pscustomobject][ordered]@{
                ReleaseVersion = '7.11.26.2142'
                SelectorBinarySha256 = '7b3714b3ff5c6add70987e0aacb0c5b5a2d523ea13ddf39bf0ac02b5f79d2b1a'
                SelectorBinary = 'Qt_Dependencies/Setup.exe'
                ImageBase = '0x140000000'
                Generalization = 'ExactBinaryOnly'
            }
            HostOsDetection = [pscustomobject][ordered]@{
                FunctionVa = '0x140014c60'
                WmiNamespace = 'root\cimv2'
                WmiQuery = 'Select * from Win32_OperatingSystem'
                WmiFields = @('BuildNumber','Caption','Version')
                OsFamilyFieldOffset = '0x224'
                InitialValue = -1
                MatchSource = 'Win32_OperatingSystem.Caption'
                MatchKind = 'CaseInsensitiveSubstring'
                OrderedMappings = @(
                    [pscustomobject][ordered]@{ Contains='Windows 7'; EnumValue=0; ClientXmlOsLabel='Windows 7(64-bit)' },
                    [pscustomobject][ordered]@{ Contains='Windows 10'; EnumValue=1; ClientXmlOsLabel='Windows 10(64-bit)' },
                    [pscustomobject][ordered]@{ Contains='Windows 11'; EnumValue=2; ClientXmlOsLabel='Windows 11(64-bit)' }
                )
                Observation = 'The 7.11.26.2142 selector initializes the field to -1 and changes it only for Windows 7/10/11 Caption substrings. This code path does not query WMI ProductType.'
            }
            InfoXmlFilter = [pscustomobject][ordered]@{
                FunctionVa = '0x140015410'
                ManifestPath = '/info.xml'
                Fields = @('Version','OS','Installer','Brand')
                ArchitectureLiteral = 'x86_64'
                EmbeddedBrandLiteral = 'Embedded'
                ClientBranch = [pscustomobject][ordered]@{
                    ArchitectureRequirement = 'x86_64'
                    EnumToXmlOsLabel = @(
                        [pscustomobject][ordered]@{ EnumValue=0; XmlOsLabel='Windows 7(64-bit)' },
                        [pscustomobject][ordered]@{ EnumValue=1; XmlOsLabel='Windows 10(64-bit)' },
                        [pscustomobject][ordered]@{ EnumValue=2; XmlOsLabel='Windows 11(64-bit)' }
                    )
                    UnknownEnumBehavior = 'NoProductAppended'
                }
                EmbeddedBranchObservedLabels = @('Win 10 RS5 LTS(64-bit)','Win 10 RS5 LTS(32-bit)','Windows 10(64-bit)','Windows 7(64-bit)','Windows 11(64-bit)')
                Observation = 'For the recovered 7.11.26.2142 Client-only manifest, enum -1 reaches no Client branch and contributes no matching product to the selector XML list.'
            }
            FilterUsbRule = [pscustomobject][ordered]@{
                EnclosingFunctionVa = '0x1400177b0'
                CandidateLookupVa = '0x140018b80'
                Candidate = '/SETFILTERUSB'
                DeviceTokenPrimary = 'DEV_790B'
                DeviceTokenFallback = 'DEV_780B'
                RequiredRevisionToken = 'REV_16'
                RemovalVa = '0x140018d5b'
                VectorEraseHelperVa = '0x1400165a0'
                Rule = '(DEV_790B or DEV_780B context) AND REV_16 is required for SETFILTERUSB to survive this compiled branch.'
                FailureBehavior = 'SETFILTERUSB is erased from the candidate vector without the generic "not present in xml list" removal message.'
                DynamicCorroboration = @()
            }
            RyzenPpkgRule = [pscustomobject][ordered]@{
                EnclosingFunctionVa = '0x1400177b0'
                DeviceTokenLookupVa = '0x140018143'
                DeviceToken = 'DEV_790B'
                CpuSpecialCompareVa = '0x14001818b'
                CpuSpecialFamily = 23
                CpuSpecialModel = 160
                RevisionGateStartVa = '0x140018324'
                AcceptedRevisionTokens = @('REV_61','REV_59','REV_51')
                CandidateCreateVa = '0x140018625'
                Candidate = '/SETRYZENPPKG'
                Rule = 'Within a DEV_790B device context, SETRYZENPPKG reaches its candidate-creation path for the CPU Family 23 / Model 160 special path or when the device identifier contains REV_61, REV_59, or REV_51. The surrounding AMDI0052 branch is retained as a reverse-engineering boundary and is not generalized beyond this exact binary.'
                DynamicCorroboration = @()
                ScopeNote = 'This is static code-level evidence for the exact 7.11.26.2142 selector. No 7.x live-host Device_ID/MSI qualification fixture has been supplied, so dynamic behavior is not claimed.'
            }
            ReverseEngineeringNotes = @(
                'Function addresses and predicates were recovered from static x86-64 disassembly of the exact SHA-256-scoped 7.11.26.2142 Qt Setup.exe binary. The research toolkit did not execute this binary.',
                'The recovered OS classifier and Client XML filter are structurally equivalent to the separately proven 8.07.16.1035 selector, but this contract is independently release/hash scoped.',
                'No 7.x live-host selector log is used as corroboration in this contract.',
                'Do not generalize this compiled contract to another AMD release or selector binary.'
            )
        }
    }

    if ($ReleaseVersion -eq '8.07.16.1035' -and $hash -eq '9b8411b3f77312a770bdac35756081e77c74fb22b7c4c4f367db4f6e5ddf5462') {
        return [pscustomobject][ordered]@{
            SchemaVersion = 'amd-chipset-compiled-selector-contract/1.0'
            ContractId = '8.07.16.1035|QtSetup|9b8411b3f77312a770bdac35756081e77c74fb22b7c4c4f367db4f6e5ddf5462'
            EvidenceLevel = 'AmdCompiledStaticProven'
            Scope = [pscustomobject][ordered]@{
                ReleaseVersion = '8.07.16.1035'
                SelectorBinarySha256 = '9b8411b3f77312a770bdac35756081e77c74fb22b7c4c4f367db4f6e5ddf5462'
                SelectorBinary = 'Qt_Dependencies/Setup.exe'
                ImageBase = '0x140000000'
                Generalization = 'ExactBinaryOnly'
            }
            HostOsDetection = [pscustomobject][ordered]@{
                FunctionVa = '0x140017130'
                WmiNamespace = 'root\cimv2'
                WmiQuery = 'Select * from Win32_OperatingSystem'
                WmiFields = @('BuildNumber','Caption','Version')
                OsFamilyFieldOffset = '0x224'
                InitialValue = -1
                MatchSource = 'Win32_OperatingSystem.Caption'
                MatchKind = 'CaseInsensitiveSubstring'
                OrderedMappings = @(
                    [pscustomobject][ordered]@{ Contains='Windows 7'; EnumValue=0; ClientXmlOsLabel='Windows 7(64-bit)' },
                    [pscustomobject][ordered]@{ Contains='Windows 10'; EnumValue=1; ClientXmlOsLabel='Windows 10(64-bit)' },
                    [pscustomobject][ordered]@{ Contains='Windows 11'; EnumValue=2; ClientXmlOsLabel='Windows 11(64-bit)' }
                )
                Observation = 'A Windows Server caption containing none of the three client substrings leaves the selector OS-family field at -1. This code path does not query ProductType.'
            }
            InfoXmlFilter = [pscustomobject][ordered]@{
                FunctionVa = '0x1400178e0'
                ManifestPath = '/info.xml'
                Fields = @('Version','OS','Installer','Brand')
                ArchitectureLiteral = 'x86_64'
                EmbeddedBrandLiteral = 'Embedded'
                ClientBranch = [pscustomobject][ordered]@{
                    ArchitectureRequirement = 'x86_64'
                    EnumToXmlOsLabel = @(
                        [pscustomobject][ordered]@{ EnumValue=0; XmlOsLabel='Windows 7(64-bit)' },
                        [pscustomobject][ordered]@{ EnumValue=1; XmlOsLabel='Windows 10(64-bit)' },
                        [pscustomobject][ordered]@{ EnumValue=2; XmlOsLabel='Windows 11(64-bit)' }
                    )
                    UnknownEnumBehavior = 'NoProductAppended'
                }
                EmbeddedBranchObservedLabels = @('Win 10 RS5 LTS(64-bit)','Win 10 RS5 LTS(32-bit)','Windows 10(64-bit)','Windows 7(64-bit)','Windows 11(64-bit)')
                Observation = 'For the recovered Client-only manifest, OS-family enum -1 reaches no Client branch and therefore contributes no matching product to the selector XML list.'
            }
            FilterUsbRule = [pscustomobject][ordered]@{
                EnclosingFunctionVa = '0x14001a090'
                CandidateLookupVa = '0x14001b450'
                Candidate = '/SETFILTERUSB'
                DeviceTokenPrimary = 'DEV_790B'
                DeviceTokenFallback = 'DEV_780B'
                RequiredRevisionToken = 'REV_16'
                RemovalVa = '0x14001b5c4'
                VectorEraseHelperVa = '0x140018e80'
                Rule = '(DEV_790B or DEV_780B context) AND REV_16 is required for SETFILTERUSB to survive this compiled branch.'
                FailureBehavior = 'SETFILTERUSB is erased from the candidate vector without the generic "not present in xml list" removal message.'
                DynamicCorroboration = @(
                    'Windows 11 build 26200: DEV_790B REV_61 -> candidate observed, no explicit removal line, absent from final list.',
                    'Windows Server 2022 build 20348: DEV_790B REV_51 -> candidate observed, no explicit removal line, absent from final list.',
                    'Windows Server 2025 build 26100: DEV_790B REV_51 -> candidate observed, no explicit removal line, absent from final list.'
                )
            }
            RyzenPpkgRule = [pscustomobject][ordered]@{
                EnclosingFunctionVa = '0x14001a090'
                DeviceTokenLookupVa = '0x14001aa33'
                DeviceToken = 'DEV_790B'
                CpuSpecialCompareVa = '0x14001aa7b'
                CpuSpecialFamily = 23
                CpuSpecialModel = 160
                RevisionGateStartVa = '0x14001ac09'
                AcceptedRevisionTokens = @('REV_61','REV_59','REV_51')
                CandidateCreateVa = '0x14001af0d'
                Candidate = '/SETRYZENPPKG'
                Rule = 'Within a DEV_790B device context, SETRYZENPPKG is created for the CPU Family 23 / Model 160 special path or when the device identifier contains REV_61, REV_59, or REV_51.'
                DynamicCorroboration = @(
                    'Windows 11 build 26200: DEV_790B REV_61 -> SETRYZENPPKG candidate observed and selected.',
                    'Windows Server 2022 build 20348: DEV_790B REV_51 -> SETRYZENPPKG candidate observed before Client XML-list exclusion.',
                    'Windows Server 2025 build 26100: DEV_790B REV_51 -> SETRYZENPPKG candidate observed before Client XML-list exclusion.'
                )
                ScopeNote = 'This rule describes candidate creation in the exact SHA-256-scoped selector binary. Later Info.xml filtering still determines whether the component remains in SupportedDrivers.'
            }
            ReverseEngineeringNotes = @(
                'Function addresses and predicates were recovered from static x86-64 disassembly of the exact SHA-256-scoped Qt Setup.exe binary. The research toolkit does not execute this binary.',
                'The Server exclusion is a vendor-selector behavior distinct from Microsoft INF ProductType/TargetOSVersion applicability.',
                'Do not generalize this compiled contract to another AMD release unless its selector binary is independently matched or reverse-engineered.'
            )
        }
    }
    return $null
}

function Get-AmdCompiledSelectorOsClassification {
    [CmdletBinding()]
    param(
        [AllowNull()][object]$CompiledSelectorContract,
        [AllowNull()][string]$Caption
    )
    if ($null -eq $CompiledSelectorContract -or $null -eq $CompiledSelectorContract.HostOsDetection) {
        return [pscustomobject][ordered]@{ Status='ContractUnavailable'; EnumValue=$null; MatchedSubstring=$null; XmlOsLabel=$null; EvidenceLevel='Unresolved' }
    }
    $enumValue = [int]$CompiledSelectorContract.HostOsDetection.InitialValue
    $matched = $null
    $label = $null
    foreach ($mapping in @($CompiledSelectorContract.HostOsDetection.OrderedMappings)) {
        if (-not [string]::IsNullOrWhiteSpace($Caption) -and $Caption.IndexOf([string]$mapping.Contains,[System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
            $enumValue = [int]$mapping.EnumValue
            $matched = [string]$mapping.Contains
            $label = [string]$mapping.ClientXmlOsLabel
            break
        }
    }
    return [pscustomobject][ordered]@{
        Status = if ($null -ne $matched) { 'CompiledCaptionMatched' } else { 'CompiledCaptionUnmatched' }
        EnumValue = $enumValue
        MatchedSubstring = $matched
        XmlOsLabel = $label
        EvidenceLevel = 'AmdCompiledStaticProven'
    }
}

function Test-AmdCompiledSelectorContractSelfTest {
    [CmdletBinding()]
    param()
    $known = @(
        [pscustomobject]@{ ReleaseVersion='3.10.08.506'; Sha256='4a0cf13c66f873319ff44eba1867f9cc7dc865d0f422c007bcb25c6ced148ee9'; RequireHardwareRules=$false },
        [pscustomobject]@{ ReleaseVersion='4.08.09.2337'; Sha256='95d0428ea90bee14704bf556a3ad6c91971e63d6d63c0807e9e7a8791d024160'; RequireHardwareRules=$false },
        [pscustomobject]@{ ReleaseVersion='5.08.02.027'; Sha256='8f4e0f27397786275db0a45282b05bf39da1f16ee9379712a75544fdb49460cf'; RequireHardwareRules=$false },
        [pscustomobject]@{ ReleaseVersion='6.10.17.152'; Sha256='83d82a4775c0793ace86b1b07f98eadfc262f22d4c275fab2d74b9d86f19379a'; RequireHardwareRules=$false },
        [pscustomobject]@{ ReleaseVersion='7.11.26.2142'; Sha256='7b3714b3ff5c6add70987e0aacb0c5b5a2d523ea13ddf39bf0ac02b5f79d2b1a'; RequireHardwareRules=$true },
        [pscustomobject]@{ ReleaseVersion='8.07.16.1035'; Sha256='9b8411b3f77312a770bdac35756081e77c74fb22b7c4c4f367db4f6e5ddf5462'; RequireHardwareRules=$true }
    )
    $cases = @(
        [pscustomobject]@{ Caption='Microsoft Windows 7 Professional'; Expected=0 },
        [pscustomobject]@{ Caption='Microsoft Windows 10 Pro'; Expected=1 },
        [pscustomobject]@{ Caption='Microsoft Windows 11 Pro'; Expected=2 }
    )
    $contractIds = New-Object System.Collections.Generic.List[string]
    foreach($item in $known){
        $contract = Get-AmdKnownCompiledSelectorContract -ReleaseVersion $item.ReleaseVersion -SelectorBinarySha256 $item.Sha256
        if ($null -eq $contract) { throw ('Known compiled selector contract was not returned for {0}.' -f $item.ReleaseVersion) }
        foreach ($case in $cases) {
            $actual = Get-AmdCompiledSelectorOsClassification -CompiledSelectorContract $contract -Caption $case.Caption
            if ([int]$actual.EnumValue -ne [int]$case.Expected) {
                throw ('Compiled selector OS classification self-test failed for {0} / "{1}": expected {2}, got {3}.' -f $item.ReleaseVersion,$case.Caption,$case.Expected,$actual.EnumValue)
            }
        }
        foreach ($serverCaption in @('Microsoft Windows Server 2022 Datacenter','Microsoft Windows Server 2025 Datacenter')) {
            $serverActual = Get-AmdCompiledSelectorOsClassification -CompiledSelectorContract $contract -Caption $serverCaption
            if ([int]$serverActual.EnumValue -ne [int]$contract.HostOsDetection.InitialValue) {
                throw ('Compiled selector unmatched-caption self-test failed for {0} / "{1}": expected initial value {2}, got {3}.' -f $item.ReleaseVersion,$serverCaption,$contract.HostOsDetection.InitialValue,$serverActual.EnumValue)
            }
        }
        if ([bool]$item.RequireHardwareRules) {
            if ($null -eq $contract.PSObject.Properties['FilterUsbRule'] -or [string]$contract.FilterUsbRule.RequiredRevisionToken -ne 'REV_16') {
                throw ('Compiled selector FILTERUSB contract self-test failed for {0}.' -f $item.ReleaseVersion)
            }
            if ($null -eq $contract.PSObject.Properties['RyzenPpkgRule'] -or -not (@($contract.RyzenPpkgRule.AcceptedRevisionTokens) -contains 'REV_61') -or -not (@($contract.RyzenPpkgRule.AcceptedRevisionTokens) -contains 'REV_59') -or -not (@($contract.RyzenPpkgRule.AcceptedRevisionTokens) -contains 'REV_51')) {
                throw ('Compiled selector RYZENPPKG contract self-test failed for {0}.' -f $item.ReleaseVersion)
            }
        }
        $contractIds.Add([string]$contract.ContractId)
    }
    return [pscustomobject][ordered]@{ Status='Pass'; ContractIds=@($contractIds.ToArray()); ContractCount=$known.Count; ClientCaseCountPerContract=$cases.Count; UnmatchedCaptionCasesPerContract=2; HardwareRuleContracts=2; PartialContracts=4; FilterUsbRule='PassFor7x8x'; RyzenPpkgRule='PassFor7x8x' }
}

function Get-AmdSelectorBinaryEvidence {
    [CmdletBinding()]
    param([Parameter(Mandatory=$true)][object]$ExtractionRelease)

    $root = [string]$ExtractionRelease.ExtractionRoot
    if (-not $root -or -not (Test-Path -LiteralPath $root -PathType Container)) {
        return [pscustomobject][ordered]@{ Status='ExtractionRootUnavailable'; SelectorBinaryPath=$null; SelectorBinarySha256=$null; StringEvidence=@(); UnicodeStringEvidence=@(); CompiledSelectorContract=$null; Notes=@() }
    }

    $candidates = @(Get-ChildItem -LiteralPath $root -Filter 'Setup.exe' -File -Recurse -ErrorAction SilentlyContinue |
        Sort-Object @{Expression={ if ($_.FullName -match '(?i)Q[tT]_Dependencies[\\/]Setup\.exe$') {0} else {1} }}, FullName)
    if ($candidates.Count -eq 0) {
        return [pscustomobject][ordered]@{ Status='SelectorBinaryNotFound'; SelectorBinaryPath=$null; SelectorBinarySha256=$null; StringEvidence=@(); UnicodeStringEvidence=@(); CompiledSelectorContract=$null; Notes=@('Qt selector Setup.exe was not recovered in the extraction tree.') }
    }

    $binary = $candidates[0]
    $relative = Get-AmdRelativePath -BasePath $root -Path $binary.FullName
    $sha256 = Get-AmdSha256 -Path $binary.FullName
    $allStrings = @(Get-AmdPrintableAsciiStrings -Path $binary.FullName -MinimumLength 4)
    $allUnicodeStrings = @(Get-AmdPrintableUnicodeStrings -Path $binary.FullName -MinimumLength 4)
    $patterns = @(
        '/info.xml','/DevID.xml','Brand','Windows 10(64-bit)','Windows 11(64-bit)','/SETFILTERUSB','/SETRYZENPPKG','REV_16','DEV_790B','DEV_780B','AMD SMBUS','790B','14EC','14AC',
        'is not present in xml list. Hence removing.','Writing supported drivers to registry:',
        'readXmlFile','traverseDevIdXml','getDriverInfo','writeSupportedDriversToRegistry','Processor is not PHX or latest. Hence removing property',
        'VerifyVersionInfoW','SetupDiGetClassDevsW','SetupDiGetDeviceRegistryPropertyW'
    )
    $widePatterns = @('root\cimv2','Select * from Win32_OperatingSystem','BuildNumber','Caption','Version','Windows 7','Windows 10','Windows 11')
    $evidence = New-Object System.Collections.Generic.List[string]
    foreach ($needle in $patterns) {
        foreach ($value in $allStrings) {
            if ($value.IndexOf($needle,[System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
                if (-not $evidence.Contains($value)) { $evidence.Add($value) }
            }
        }
    }
    $unicodeEvidence = New-Object System.Collections.Generic.List[string]
    foreach ($needle in $widePatterns) {
        foreach ($value in $allUnicodeStrings) {
            if ($value.IndexOf($needle,[System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
                if (-not $unicodeEvidence.Contains($value)) { $unicodeEvidence.Add($value) }
            }
        }
    }
    $compiledContract = Get-AmdKnownCompiledSelectorContract -ReleaseVersion ([string]$ExtractionRelease.ReleaseVersion) -SelectorBinarySha256 $sha256
    $status = if ($null -ne $compiledContract) { 'CompiledSelectorContractMatched' } else { 'StaticStringEvidenceRecovered' }
    return [pscustomobject][ordered]@{
        Status = $status
        SelectorBinaryPath = $relative
        SelectorBinarySha256 = $sha256
        StringEvidence = @($evidence.ToArray())
        UnicodeStringEvidence = @($unicodeEvidence.ToArray())
        CompiledSelectorContract = $compiledContract
        Notes = @(
            'Printable strings are static binary evidence only unless a SHA-256-scoped CompiledSelectorContract is present.',
            'For current Qt-based packages, Setup.exe is the strongest recovered candidate for the pre-MSI device/component selector because it contains Info.xml/DevID.xml paths, selector log text, XML traversal symbols and SetupAPI/OS-version evidence.',
            'AmdCompiledStaticProven is used only when this toolkit has a vetted code-level contract for the exact selector-binary SHA-256; it is not inferred from strings alone.'
        )
    }
}

function Get-AmdEmbeddedXmlContract {
    [CmdletBinding()]
    param([AllowNull()][object[]]$Products)
    $items=@($Products)
    $osLabels=@($items|ForEach-Object{[string]$_.OS}|Where-Object{$_}|Sort-Object -Unique)
    $brands=@($items|ForEach-Object{[string]$_.Brand}|Where-Object{$_}|Sort-Object -Unique)
    $serverLike=@($items|Where-Object{([string]$_.OS -match '(?i)Server') -or ([string]$_.Brand -match '(?i)Server')})
    return [pscustomobject][ordered]@{
        ProductCount=$items.Count
        OsLabels=@($osLabels)
        BrandValues=@($brands)
        ServerLikeEntryCount=$serverLike.Count
        ClientOnlyByObservedFields=($items.Count -gt 0 -and $serverLike.Count -eq 0 -and @($brands|Where-Object{$_ -notmatch '(?i)^Client$'}).Count -eq 0)
        EvidenceLevel='AmdDeclarativeProven'
        Interpretation='This describes fields present in the recovered XML. It does not by itself prove how Setup.exe evaluates ProductType/SKU.'
    }
}

function Invoke-AmdSelectorStaticStage {
    [CmdletBinding()]
    param(
        [string]$ExtractionPath,
        [string]$EmbeddedMetadataPath,
        [string]$OutputPath
    )

    $toolRoot = Get-AmdResearchToolkitRoot
    if (-not $ExtractionPath) { $ExtractionPath = Join-Path $toolRoot 'inventory\extraction.json' }
    if (-not $EmbeddedMetadataPath) { $EmbeddedMetadataPath = Join-Path $toolRoot 'inventory\embedded-installer-metadata.json' }
    if (-not $OutputPath) { $OutputPath = Join-Path $toolRoot 'inventory\amd-selector-static.json' }

    $extraction = Read-AmdJsonFile -Path $ExtractionPath
    $embedded = Read-AmdJsonFile -Path $EmbeddedMetadataPath
    $records = New-Object System.Collections.Generic.List[object]
    $releaseItems = @($extraction.Releases)
    $index = 0
    Write-AmdStep ('Building AMD selector static model for {0} release(s).' -f $releaseItems.Count)

    foreach ($release in $releaseItems) {
        $index++
        $version = [string]$release.ReleaseVersion
        $meta = @($embedded.Releases | Where-Object { [string]$_.ReleaseVersion -eq $version } | Select-Object -First 1)
        $products = @()
        $mappings = @()
        if ($meta.Count -gt 0) { $products=@($meta[0].Products); $mappings=@($meta[0].DeviceMappings) }
        $rules = New-Object System.Collections.Generic.List[object]
        foreach ($mapping in $mappings) {
            $property = Get-AmdSelectorPropertyName -Tag ([string]$mapping.Tag)
            $rules.Add([pscustomobject][ordered]@{
                RuleKind = 'DevIdXmlMapping'
                EvidenceLevel = 'AmdDeclarativeProven'
                Tag = [string]$mapping.Tag
                PropertyName = $property
                FeatureName = Get-AmdSelectorFeatureName -PropertyName $property
                DeviceIds = @($mapping.DeviceIds)
                RawDeviceIds = [string]$mapping.RawDeviceIds
                InfoProductCandidates = @(Get-AmdSelectorInfoProductCandidates -PropertyName $property -Products $products)
            })
        }
        $msiPath = Get-AmdRecoveredTopLevelMsiPath -ExtractionRelease $release
        $msiAnalysis = Invoke-AmdMsiDeclarativeAnalysis -MsiPath $msiPath
        $binaryEvidence = Get-AmdSelectorBinaryEvidence -ExtractionRelease $release
        $xmlContract = Get-AmdEmbeddedXmlContract -Products $products
        $manifestEvidence = if ($meta.Count -gt 0) { [pscustomobject][ordered]@{ PreferredInfoXmlPath=[string]$meta[0].PreferredInfoXmlPath; PreferredApsXmlPath=if($null -ne $meta[0].PSObject.Properties['PreferredApsXmlPath']){[string]$meta[0].PreferredApsXmlPath}else{$null}; ApsXmlCount=if($null -ne $meta[0].PSObject.Properties['ApsXmlCount']){[int]$meta[0].ApsXmlCount}else{0}; ApsIdenticalToPreferredInfoXmlCount=if($null -ne $meta[0].PSObject.Properties['ApsIdenticalToPreferredInfoXmlCount']){[int]$meta[0].ApsIdenticalToPreferredInfoXmlCount}else{0}; PreferredDevIdXmlPath=[string]$meta[0].PreferredDevIdXmlPath } } else { $null }
        $records.Add([pscustomobject][ordered]@{
            ReleaseVersion = $version
            DevIdRuleCount = $rules.Count
            DevIdRules = @($rules.ToArray())
            EmbeddedXmlContract = $xmlContract
            ManifestEvidence = $manifestEvidence
            SelectorBinaryEvidence = $binaryEvidence
            MsiDeclarativeAnalysis = $msiAnalysis
            Notes = @(
                'DevID.xml mappings are AMD declarative selector evidence, but a matching token alone does not prove the component survives later CPU/OS/manifest/custom-action filters.',
                'MSI table inspection is read-only and never invokes MSI installation. On non-Windows platforms the Windows Installer COM portion is recorded as unavailable rather than treated as success.',
                'APS_*.xml payloads are preserved and SHA-compared with preferred Info.xml. Byte identity is evidence that the same component manifest is carried into the second-stage MSI payload; it does not prove the selector predicate.',
                'Qt Setup.exe static string evidence is recorded separately from declarative XML and dynamic observation.'
            )
        })
        Write-AmdOk ('Selector [{0}/{1}] {2} -> DevID rules={3}; MSI={4}' -f $index,$releaseItems.Count,$version,$rules.Count,$msiAnalysis.Status)
    }

    $output = [pscustomobject][ordered]@{
        SchemaVersion = 'amd-chipset-selector-static/1.2'
        ToolkitVersion = $script:AmdChipsetResearchToolkitVersion
        GeneratedAtUtc = Get-AmdUtcTimestamp
        Purpose = 'AmdInstallerSelectorStaticResearch'
        Releases = @($records.ToArray())
    }
    Write-AmdJsonFile -Path $OutputPath -Value $output -Depth 40
    return $output
}

function Expand-AmdObservedIdentifierVariants {
    [CmdletBinding()]
    param([AllowNull()][string]$Identifier)

    $values = New-Object System.Collections.Generic.List[string]
    function Add-ObservedId([string]$Value) {
        if ([string]::IsNullOrWhiteSpace($Value)) { return }
        $v = $Value.Trim()
        if (-not $values.Contains($v)) { $values.Add($v) }
    }

    if ([string]::IsNullOrWhiteSpace($Identifier)) { return @() }
    foreach ($part in @($Identifier -split '#')) {
        $candidate = $part.Trim().TrimEnd('.')
        if (-not $candidate) { continue }
        Add-ObservedId $candidate

        # Device_ID.log contains both PnP hardware IDs and full device-instance IDs.
        # Remove the instance suffix when a bus-enumerated identifier is followed by one.
        if ($candidate -match '^(?i)((?:PCI|ACPI|USB|HID|BTH|SCSI|ROOT|SWD|STORAGE|UEFI|MONITOR)\\[^\\]+)\\.+$') {
            Add-ObservedId $Matches[1]
            $candidate = $Matches[1]
        }

        # Preserve the observed PCI specificity ladder so INF IDs such as
        # PCI\VEN_1022&DEV_1485 can be matched without inventing a foreign device ID.
        if ($candidate -match '^(?i)PCI\\VEN_([0-9A-F]{4})&DEV_([0-9A-F]{4})(?:&SUBSYS_([0-9A-F]{8}))?(?:&REV_([0-9A-F]{2}))?') {
            $ven=$Matches[1]; $dev=$Matches[2]; $subsys=$Matches[3]
            if ($subsys) { Add-ObservedId ('PCI\VEN_{0}&DEV_{1}&SUBSYS_{2}' -f $ven,$dev,$subsys) }
            Add-ObservedId ('PCI\VEN_{0}&DEV_{1}' -f $ven,$dev)
        }

        # AMD logs often contain both ACPI\VEN_AMDI&DEV_0030 and ACPI\AMDI0030.
        # Derive only the equivalent ACPI namespace spelling from the observed value.
        if ($candidate -match '^(?i)ACPI\\([A-Z]{3,4})([0-9A-F]{4})$') {
            Add-ObservedId ('ACPI\VEN_{0}&DEV_{1}' -f $Matches[1],$Matches[2])
        }
        if ($candidate -match '^(?i)ACPI\\VEN_([A-Z]{3,4})&DEV_([0-9A-F]{4})$') {
            Add-ObservedId ('ACPI\{0}{1}' -f $Matches[1],$Matches[2])
            Add-ObservedId ('*{0}{1}' -f $Matches[1],$Matches[2])
        }
    }
    return @($values.ToArray())
}

function ConvertFrom-AmdObservedMsiLog {
    [CmdletBinding()]
    param([Parameter(Mandatory=$true)][string]$Path)

    $resolved=(Resolve-Path -LiteralPath $Path).Path
    $text=[System.IO.File]::ReadAllText($resolved)
    $releaseVersion=$null
    $finalStatus=$null
    $commandLine=$null
    $setProperties=New-Object System.Collections.Generic.List[string]
    $addLocal=@()
    $addLocalObserved=$false
    $actionProperty=$null
    $transactionMode='Unknown'
    $productTypes=New-Object System.Collections.Generic.List[int]

    foreach($line in @($text -split "`r?`n")){
        if($line -match '(?i)Product Name:\s*AMD_Chipset_Drivers\.\s*Product Version:\s*([0-9]+(?:\.[0-9]+){3}).*Installation success or error status:\s*([0-9]+)'){
            $releaseVersion=$Matches[1]; $finalStatus=[int]$Matches[2]
        }
        elseif($line -match '製品名:\s*AMD_Chipset_Drivers、製品バージョン:\s*([0-9]+(?:\.[0-9]+){3}).*インストールの成功またはエラーの状態:\s*([0-9]+)'){
            $releaseVersion=$Matches[1]; $finalStatus=[int]$Matches[2]
        }
        if(-not $commandLine -and $line -match '(?i)Command Line:\s*(.+SETUPEXENAME=AMD_Chipset_Drivers\.exe.+)$'){
            $commandLine=$Matches[1].Trim()
        }
        if($line -match '(?i)^Property\([SC]\):\s*MsiNTProductType\s*=\s*(\d+)\s*$'){
            $pt=[int]$Matches[1]
            if(-not $productTypes.Contains($pt)){$productTypes.Add($pt)}
        }
    }
    if(-not $releaseVersion){
        $matches=[regex]::Matches($text,'(?im)^Property\([SC]\):\s*ProductVersion\s*=\s*([0-9]+(?:\.[0-9]+){3})\s*$')
        if($matches.Count -gt 0){$releaseVersion=$matches[$matches.Count-1].Groups[1].Value}
    }
    if($commandLine){
        foreach($m in [regex]::Matches($commandLine,'(?i)\b(SET[A-Z0-9_.]+)=YES\b')){
            $p=$m.Groups[1].Value.ToUpperInvariant(); if(-not $setProperties.Contains($p)){$setProperties.Add($p)}
        }
        $action=[regex]::Match($commandLine,'(?i)\bACTION=([^\s]+)')
        if($action.Success){$actionProperty=$action.Groups[1].Value.ToUpperInvariant()}
        $add=[regex]::Match($commandLine,'(?i)\bADDLOCAL=([^\s]+)')
        if($add.Success){
            $addLocalObserved=$true
            $addLocal=@($add.Groups[1].Value.Split([char]',')|ForEach-Object{$_.Trim().ToUpperInvariant()}|Where-Object{$_})
        }
    }
    if(-not $addLocalObserved){
        $matches=[regex]::Matches($text,'(?im)^Property\(C\):\s*ADDLOCAL\s*=\s*(.*)$')
        if($matches.Count -gt 0){
            $addLocalObserved=$true
            $value=$matches[$matches.Count-1].Groups[1].Value
            $addLocal=@($value.Split([char]',')|ForEach-Object{$_.Trim().ToUpperInvariant()}|Where-Object{$_})
        }
    }

    if($actionProperty -eq 'ADMIN'){$transactionMode='AdministrativeExtraction'}
    elseif($commandLine -match '(?i)\bREMOVE=ALL\b'){$transactionMode='Uninstall'}
    elseif($commandLine -match '(?i)\bREINSTALL=ALL\b'){$transactionMode='MaintenanceOrUpgrade'}
    elseif($commandLine -or $addLocalObserved){$transactionMode='NormalInstallOrSelection'}

    $primaryProductType=$null
    if($productTypes.Count -eq 1){$primaryProductType=$productTypes[0]}

    return [pscustomobject][ordered]@{
        SchemaVersion='amd-chipset-msi-observation/1.1'
        SourcePath=$resolved
        SourceSha256=Get-AmdSha256 -Path $resolved
        ParsedAtUtc=Get-AmdUtcTimestamp
        ReleaseVersion=$releaseVersion
        CommandLine=$commandLine
        ActionProperty=$actionProperty
        TransactionMode=$transactionMode
        MsiNtProductTypes=@($productTypes.ToArray())
        PrimaryMsiNtProductType=$primaryProductType
        SetProperties=@($setProperties.ToArray())
        AddLocalObserved=$addLocalObserved
        AddLocalFeatures=@($addLocal)
        FeatureSelectionInterpretation=if($transactionMode -eq 'AdministrativeExtraction'){'Administrative extraction requests local files for payload expansion; Feature Request=Local is not AMD install-selection evidence.'}else{'ADDLOCAL/SET properties may represent AMD component selection when observed in the primary non-admin transaction.'}
        FinalInstallStatus=$finalStatus
    }
}
function ConvertFrom-AmdObservedDeviceIdLog {
    [CmdletBinding()]
    param([Parameter(Mandatory=$true)][string]$Path,[string]$ObservedReleaseVersion)

    $resolved = (Resolve-Path -LiteralPath $Path).Path
    $lines = [System.IO.File]::ReadAllLines($resolved)
    $deviceIds = New-Object System.Collections.Generic.List[string]
    $candidateEvents = New-Object System.Collections.Generic.List[object]
    $observedDeviceGroups = New-Object System.Collections.Generic.List[object]
    $removalEvents = New-Object System.Collections.Generic.List[object]
    $installAttempts = New-Object System.Collections.Generic.List[object]
    $finalFeatures = @()
    $finalSupportedListObserved=$false
    $finalSupportedRawLine=$null
    $cpu = $null
    $osVersion = $null
    $buildNumber = $null
    $caption = $null
    $architecture = $null

    foreach ($line in $lines) {
        if ($line -match ';Information;Windows Caption:\s*(.+)$') { $caption = $Matches[1].Trim() }
        if ($line -match ';Information;OS Version:\s*([0-9.]+)') { $osVersion = $Matches[1] }
        if ($line -match ';Information;Build Number:\s*(\d+)') { $buildNumber = [int]$Matches[1] }
        if ($line -match ';Information;Machine Architecture:\s*(\S+)') { $architecture = $Matches[1] }
        if ($line -match 'OS Version is\s*:\s*([0-9.]+)') { $osVersion = $Matches[1] }
        if ($line -match 'Family:\s*AMD64 Family\s+(\d+)\s+Model\s+(\d+)\s+Stepping\s+(\d+)') {
            $cpu = [pscustomobject][ordered]@{ Family=[int]$Matches[1]; Model=[int]$Matches[2]; Stepping=[int]$Matches[3]; Raw=$Matches[0] }
        }
        if ($line -match 'Device ID:\s*(.+)$') {
            $id = $Matches[1].Trim()
            if ($id -and -not $deviceIds.Contains($id)) { $deviceIds.Add($id) }
        }
        if ($line -match ';Information;((?:PCI|ACPI|USB|ROOT|SWD|BTH|HID|SCSI|STORAGE|COMPUTER|UEFI|MMDEVAPI|PRINTENUM|MONITOR|VCAMDEVAPI|XvddRootDevice|\{)[^;]*)$') {
            $id = $Matches[1].Trim()
            if ($id -and -not $deviceIds.Contains($id)) { $deviceIds.Add($id) }
        }
        $deviceSelectionMatch = [regex]::Match($line, '(?i)Device found with device id(?: and revision id)?\s*(.*?)\s*\.?\s*Hence setting property\s+/?(SET[A-Za-z0-9_.]+)')
        if ($deviceSelectionMatch.Success) {
            $propertyName = $deviceSelectionMatch.Groups[2].Value.ToUpperInvariant()
            $rawSequence = $deviceSelectionMatch.Groups[1].Value.Trim()
            $ids = @()
            foreach ($rawId in @($rawSequence -split '#')) { $ids += @(Expand-AmdObservedIdentifierVariants -Identifier $rawId) }
            $ids = @($ids | Where-Object { $_ } | Select-Object -Unique)
            $candidateEvents.Add([pscustomobject][ordered]@{ PropertyName=$propertyName; Reason='DeviceDetection'; DeviceIdentifiers=@($ids); RawIdentifierSequence=$rawSequence; RawLine=$line })
            $observedDeviceGroups.Add([pscustomobject][ordered]@{ PropertyName=$propertyName; Identifiers=@($ids); RawIdentifierSequence=$rawSequence })
        }
        elseif ($line -match '(?i)Hence setting property\s+/?(SET[A-Za-z0-9_.]+)') {
            $candidateEvents.Add([pscustomobject][ordered]@{ PropertyName=$Matches[1].ToUpperInvariant(); Reason='DeviceDetection'; DeviceIdentifiers=@(); RawIdentifierSequence=$null; RawLine=$line })
        }
        foreach ($m in [regex]::Matches($line, '(?i)Setting property\s+(SET[A-Za-z0-9_.]+)\s+since')) {
            $candidateEvents.Add([pscustomobject][ordered]@{ PropertyName=$m.Groups[1].Value.ToUpperInvariant(); Reason='OsArchitectureRule'; DeviceIdentifiers=@(); RawIdentifierSequence=$null; RawLine=$line })
        }
        if ($line -match '(?i)Processor is not PHX or latest\. Hence removing property\s+/?(SET[A-Za-z0-9_.]+)') {
            $removalEvents.Add([pscustomobject][ordered]@{ PropertyName=$Matches[1].ToUpperInvariant(); Reason='CpuGenerationRule'; RawLine=$line })
        }
        if ($line -match '(?i)/?(SET[A-Za-z0-9_.]+) is not present in xml list\. Hence removing') {
            $removalEvents.Add([pscustomobject][ordered]@{ PropertyName=$Matches[1].ToUpperInvariant(); Reason='EmbeddedManifestRule'; RawLine=$line })
        }
        if ($line -match '(?i)Writing supported drivers to registry:\s*(.*)$') {
            $finalSupportedListObserved=$true
            $finalSupportedRawLine=$line
            $value=$Matches[1]
            $finalFeatures = @($value.Split([char]',') | ForEach-Object { $_.Trim().ToUpperInvariant() } | Where-Object { $_ })
        }
        if ($line -match '(?i)Install_Driver_[^:]*\s*:\s*.+?\\([^\\\"]+\.inf)\"?') {
            $installAttempts.Add([pscustomobject][ordered]@{ InfName=$Matches[1]; RawLine=$line })
        }
    }

    if($null -eq $buildNumber -and $osVersion -match '^\d+\.\d+\.(\d+)'){$buildNumber=[int]$Matches[1]}
    $productType=$null
    $productTypeDerivation='UnknownFromDeviceIdLog'
    if($caption -match '(?i)Windows\s+Server'){$productType=3;$productTypeDerivation='CaptionHeuristicServer'}
    elseif($caption -match '(?i)Windows\s+(?:10|11)'){$productType=1;$productTypeDerivation='CaptionHeuristicWorkstation'}

    $finalProperties = @($finalFeatures | ForEach-Object { ('SET{0}' -f $_).ToUpperInvariant() })
    $explicitRemoved=@{}
    foreach($ev in @($removalEvents.ToArray())){$explicitRemoved[[string]$ev.PropertyName]=$true}
    $implicitRemovalEvents=New-Object System.Collections.Generic.List[object]
    if($finalSupportedListObserved){
        foreach($p in @($candidateEvents.ToArray()|ForEach-Object{$_.PropertyName}|Where-Object{$_}|Sort-Object -Unique)){
            if(($finalProperties -notcontains $p) -and -not $explicitRemoved.ContainsKey([string]$p)){
                $implicitRemovalEvents.Add([pscustomobject][ordered]@{PropertyName=[string]$p;Reason='AbsentFromObservedFinalListWithoutExplicitRemoval';EvidenceLevel='AmdDynamicObserved';RawLine=$finalSupportedRawLine})
            }
        }
    }
    $selectionStatus=if(-not $finalSupportedListObserved){'NotObserved'}elseif($finalFeatures.Count -eq 0){'ObservedEmpty'}else{'ObservedNonEmpty'}

    return [pscustomobject][ordered]@{
        SchemaVersion = 'amd-chipset-selector-observation/1.1'
        SourcePath = $resolved
        SourceSha256 = Get-AmdSha256 -Path $resolved
        ParsedAtUtc = Get-AmdUtcTimestamp
        ObservedReleaseVersion = $ObservedReleaseVersion
        Host = [pscustomobject][ordered]@{ WindowsCaption=$caption; OSVersion=$osVersion; BuildNumber=$buildNumber; ProductType=$productType; ProductTypeDerivation=$productTypeDerivation; Architecture=$architecture; CPU=$cpu }
        DeviceIds = @($deviceIds.ToArray())
        CandidateEvents = @($candidateEvents.ToArray())
        ObservedDeviceGroups = @($observedDeviceGroups.ToArray())
        RemovalEvents = @($removalEvents.ToArray())
        ImplicitRemovalEvents = @($implicitRemovalEvents.ToArray())
        FinalSupportedListObserved = $finalSupportedListObserved
        FinalSelectionStatus = $selectionStatus
        FinalSupportedRawLine = $finalSupportedRawLine
        FinalSupportedFeatures = @($finalFeatures)
        FinalSupportedProperties = @($finalProperties)
        InstallAttempts = @($installAttempts.ToArray())
        Summary = [pscustomobject][ordered]@{CandidateEventCount=$candidateEvents.Count;ExplicitRemovalCount=$removalEvents.Count;ImplicitRemovalCount=$implicitRemovalEvents.Count;FinalSupportedFeatureCount=$finalFeatures.Count}
    }
}
function Get-AmdHostDeviceSelectorTokens {
    [CmdletBinding()]
    param([AllowNull()][string[]]$Identifiers)

    $tokens = New-Object System.Collections.Generic.List[string]
    foreach ($id in @($Identifiers)) {
        if ([string]::IsNullOrWhiteSpace($id)) { continue }
        $upper = $id.ToUpperInvariant()
        if (-not $tokens.Contains($upper)) { $tokens.Add($upper) }
        foreach ($m in [regex]::Matches($upper, '(?i)DEV_[0-9A-F]{4}')) { if (-not $tokens.Contains($m.Value)) { $tokens.Add($m.Value) } }
        foreach ($m in [regex]::Matches($upper, '(?i)REV_[0-9A-F]{2}')) { if (-not $tokens.Contains($m.Value)) { $tokens.Add($m.Value) } }
        foreach ($m in [regex]::Matches($upper, '(?i)(?:AMDI|AMDIF|AMDF|AMD|GPIO|MSFT)[0-9A-F]{3,4}')) { if (-not $tokens.Contains($m.Value)) { $tokens.Add($m.Value) } }
        foreach ($m in [regex]::Matches($upper, '(?i)PCCINTAA')) { if (-not $tokens.Contains($m.Value)) { $tokens.Add($m.Value) } }
        $acpiVenDev = [regex]::Match($upper, 'ACPI\\VEN_([A-Z0-9]{3,4})&DEV_([0-9A-F]{4})')
        if ($acpiVenDev.Success) {
            $combined = $acpiVenDev.Groups[1].Value + $acpiVenDev.Groups[2].Value
            if (-not $tokens.Contains($combined)) { $tokens.Add($combined) }
        }
    }
    return @($tokens.ToArray())
}

function Test-AmdHostDeviceTokenContext {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][object]$HostInventory,
        [Parameter(Mandatory=$true)][string[]]$DeviceTokens,
        [AllowNull()][string[]]$RevisionTokens = @()
    )

    $deviceTokenUpper=@($DeviceTokens|ForEach-Object{([string]$_).ToUpperInvariant()})
    $revisionTokenUpper=@($RevisionTokens|ForEach-Object{([string]$_).ToUpperInvariant()})
    foreach($device in @($HostInventory.Devices)){
        $ids=@([string]$device.InstanceId)+@($device.HardwareIds)+@($device.CompatibleIds)
        $tokens=@(Get-AmdHostDeviceSelectorTokens -Identifiers @($ids))
        $hasDevice=@($deviceTokenUpper|Where-Object{$tokens -contains $_}).Count -gt 0
        if(-not $hasDevice){continue}
        $hasRevision=($revisionTokenUpper.Count -eq 0 -or @($revisionTokenUpper|Where-Object{$tokens -contains $_}).Count -gt 0)
        if($hasRevision){
            return [pscustomobject][ordered]@{Matched=$true;Device=$device;Tokens=@($tokens);MatchedDeviceTokens=@($deviceTokenUpper|Where-Object{$tokens -contains $_});MatchedRevisionTokens=@($revisionTokenUpper|Where-Object{$tokens -contains $_})}
        }
    }
    return [pscustomobject][ordered]@{Matched=$false;Device=$null;Tokens=@();MatchedDeviceTokens=@();MatchedRevisionTokens=@()}
}

function Get-AmdWindowsPnpDevicePropertyData {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][string]$InstanceId,
        [Parameter(Mandatory=$true)][string]$KeyName
    )
    $cmd=Get-Command -Name Get-PnpDeviceProperty -ErrorAction SilentlyContinue
    if($null -eq $cmd){return $null}
    try{
        $property=Get-PnpDeviceProperty -InstanceId $InstanceId -KeyName $KeyName -ErrorAction Stop
        if($null -ne $property){return $property.Data}
    }catch{}
    return $null
}

function Get-AmdLiveWindowsHostInventory {
    [CmdletBinding()]
    param()

    $platform = Get-AmdPlatformInfo
    if ($platform.PlatformFamily -ne 'Windows') { throw 'Live host survey is available only on Windows.' }
    $os = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction Stop | Select-Object -First 1
    $cpu = Get-CimInstance -ClassName Win32_Processor -ErrorAction Stop | Select-Object -First 1
    $signedDrivers = @{}
    try {
        foreach ($drv in @(Get-CimInstance -ClassName Win32_PnPSignedDriver -ErrorAction Stop)) {
            $key = ([string]$drv.DeviceID).ToUpperInvariant()
            if ($key -and -not $signedDrivers.ContainsKey($key)) { $signedDrivers[$key] = $drv }
        }
    } catch { }

    $devices = New-Object System.Collections.Generic.List[object]
    foreach ($dev in @(Get-CimInstance -ClassName Win32_PnPEntity -ErrorAction Stop)) {
        $instanceId = [string]$dev.PNPDeviceID
        $drv = $null
        if ($instanceId -and $signedDrivers.ContainsKey($instanceId.ToUpperInvariant())) { $drv = $signedDrivers[$instanceId.ToUpperInvariant()] }
        $hardwareIds = @()
        $compatibleIds = @()
        if ($null -ne $dev.PSObject.Properties['HardwareID']) { $hardwareIds = @($dev.HardwareID) }
        if ($null -ne $dev.PSObject.Properties['CompatibleID']) { $compatibleIds = @($dev.CompatibleID) }
        if($instanceId){
            $pnpHardware=Get-AmdWindowsPnpDevicePropertyData -InstanceId $instanceId -KeyName 'DEVPKEY_Device_HardwareIds'
            $pnpCompatible=Get-AmdWindowsPnpDevicePropertyData -InstanceId $instanceId -KeyName 'DEVPKEY_Device_CompatibleIds'
            if($null -ne $pnpHardware){$hardwareIds=@($pnpHardware)}
            if($null -ne $pnpCompatible){$compatibleIds=@($pnpCompatible)}
        }
        $matchingDeviceId=if($instanceId){Get-AmdWindowsPnpDevicePropertyData -InstanceId $instanceId -KeyName 'DEVPKEY_Device_MatchingDeviceId'}else{$null}
        $devices.Add([pscustomobject][ordered]@{
            InstanceId = $instanceId
            Name = [string]$dev.Name
            Manufacturer = [string]$dev.Manufacturer
            PnpClass = [string]$dev.PNPClass
            ClassGuid = [string]$dev.ClassGuid
            Service = [string]$dev.Service
            Status = [string]$dev.Status
            ConfigManagerErrorCode = $dev.ConfigManagerErrorCode
            HardwareIds = @($hardwareIds)
            CompatibleIds = @($compatibleIds)
            MatchingDeviceId = [string]$matchingDeviceId
            CurrentDriver = if ($null -ne $drv) { [pscustomobject][ordered]@{ InfName=[string]$drv.InfName; DriverVersion=[string]$drv.DriverVersion; DriverDate=[string]$drv.DriverDate; DriverProviderName=[string]$drv.DriverProviderName; Manufacturer=[string]$drv.Manufacturer } } else { $null }
        })
    }

    $cpuParsed = $null
    $caption = [string]$cpu.Caption
    if ($caption -match '(?i)Family\s+(\d+)\s+Model\s+(\d+)\s+Stepping\s+(\d+)') {
        $cpuParsed = [pscustomobject][ordered]@{ Family=[int]$Matches[1]; Model=[int]$Matches[2]; Stepping=[int]$Matches[3] }
    }
    $wdfPath = Join-Path $env:WINDIR 'System32\drivers\Wdf01000.sys'
    $kmdfObserved = $null
    $wdfFileVersion = $null
    if (Test-Path -LiteralPath $wdfPath -PathType Leaf) {
        try {
            $wdfFileVersion = (Get-Item -LiteralPath $wdfPath).VersionInfo.FileVersion
            $m = [regex]::Match([string]$wdfFileVersion, '^(\d+)\.(\d+)')
            if ($m.Success) { $kmdfObserved = ('{0}.{1}' -f $m.Groups[1].Value,$m.Groups[2].Value) }
        } catch { }
    }
    return [pscustomobject][ordered]@{
        SchemaVersion = 'amd-chipset-host-inventory/1.0'
        CollectedAtUtc = Get-AmdUtcTimestamp
        Source = 'LiveWindowsCimReadOnly'
        OS = [pscustomobject][ordered]@{
            Caption=[string]$os.Caption
            Version=[string]$os.Version
            BuildNumber=[int]$os.BuildNumber
            ProductType=[int]$os.ProductType
            OSArchitecture=[string]$os.OSArchitecture
            NormalizedArchitecture=(ConvertTo-AmdNormalizedArchitecture -Architecture ([string]$platform.OSArchitecture) -Cpu $cpu)
            ArchitectureSource='RuntimeInformation.OSArchitecture'
            SuiteMask=$null
        }
        CPU = [pscustomobject][ordered]@{
            Name=[string]$cpu.Name; Caption=$caption; Manufacturer=[string]$cpu.Manufacturer; ProcessorId=[string]$cpu.ProcessorId; Family=if($cpuParsed){$cpuParsed.Family}else{$null}; Model=if($cpuParsed){$cpuParsed.Model}else{$null}; Stepping=if($cpuParsed){$cpuParsed.Stepping}else{$null}
        }
        WDF = [pscustomobject][ordered]@{ Wdf01000Path=$wdfPath; FileVersion=$wdfFileVersion; ObservedKMDF=$kmdfObserved; Derivation='First two numeric FileVersion fields; controlled host-observation heuristic.' }
        Devices = @($devices.ToArray())
    }
}

function ConvertTo-AmdHostInventoryFromObservation {
    [CmdletBinding()]
    param([Parameter(Mandatory=$true)][object]$Observation)

    $build = $Observation.Host.BuildNumber
    $major=10; $minor=0
    if ($Observation.Host.OSVersion -match '^(\d+)\.(\d+)(?:\.(\d+))?') { $major=[int]$Matches[1]; $minor=[int]$Matches[2]; if($null -eq $build -and $Matches[3]){$build=[int]$Matches[3]} }
    $devices = New-Object System.Collections.Generic.List[object]
    foreach ($rawDeviceId in @($Observation.DeviceIds)) {
        $ids=@(Expand-AmdObservedIdentifierVariants -Identifier ([string]$rawDeviceId))
        $devices.Add([pscustomobject][ordered]@{ InstanceId=[string]$rawDeviceId; Name=$null; Manufacturer=$null; PnpClass=$null; ClassGuid=$null; Service=$null; Status='ObservedLog'; ConfigManagerErrorCode=$null; HardwareIds=@($ids); CompatibleIds=@(); MatchingDeviceId=$null; CurrentDriver=$null; IdentifierDerivation='ObservedLogNormalization' })
    }
    foreach ($group in @($Observation.ObservedDeviceGroups)) {
        if (@($group.Identifiers).Count -eq 0) { continue }
        $devices.Add([pscustomobject][ordered]@{ InstanceId=('AMD-SELECTOR-OBSERVATION\{0}' -f [string]$group.PropertyName); Name=('AMD selector observation {0}' -f [string]$group.PropertyName); Manufacturer='AMD'; PnpClass=$null; ClassGuid=$null; Service=$null; Status='ObservedSelectorLog'; ConfigManagerErrorCode=$null; HardwareIds=@($group.Identifiers); CompatibleIds=@(); MatchingDeviceId=$null; CurrentDriver=$null; IdentifierDerivation='AmdSelectorDeviceIdSequence' })
    }
    return [pscustomobject][ordered]@{
        SchemaVersion='amd-chipset-host-inventory/1.0'; CollectedAtUtc=Get-AmdUtcTimestamp; Source='AmdDeviceIdLogObservation'
        OS=[pscustomobject][ordered]@{ Caption=$Observation.Host.WindowsCaption; Version=$Observation.Host.OSVersion; BuildNumber=$build; ProductType=if($null -ne $Observation.Host.ProductType){[int]$Observation.Host.ProductType}else{1}; ProductTypeDerivation=if($Observation.Host.ProductTypeDerivation){[string]$Observation.Host.ProductTypeDerivation}else{'ObservationFallback'}; OSArchitecture=$Observation.Host.Architecture; NormalizedArchitecture=(ConvertTo-AmdNormalizedArchitecture -Architecture ([string]$Observation.Host.Architecture) -Cpu ([pscustomobject]@{Caption=if($Observation.Host.CPU){$Observation.Host.CPU.Raw}else{$null};Name=$null;Manufacturer='AuthenticAMD'})); ArchitectureSource='ObservedLogNormalization'; SuiteMask=$null }
        CPU=[pscustomobject][ordered]@{ Name=$null; Caption=if($Observation.Host.CPU){$Observation.Host.CPU.Raw}else{$null}; Manufacturer='AuthenticAMD'; ProcessorId=$null; Family=if($Observation.Host.CPU){$Observation.Host.CPU.Family}else{$null}; Model=if($Observation.Host.CPU){$Observation.Host.CPU.Model}else{$null}; Stepping=if($Observation.Host.CPU){$Observation.Host.CPU.Stepping}else{$null} }
        WDF=$null; Devices=@($devices.ToArray())
    }
}

function Invoke-AmdHostSurveyStage {
    [CmdletBinding()]
    param([string]$ObservedDeviceIdLog,[string]$ObservedMsiLog,[string]$ObservedReleaseVersion,[string]$OutputPath,[string]$ObservationOutputPath,[string]$MsiObservationOutputPath)

    $toolRoot=Get-AmdResearchToolkitRoot
    if (-not $OutputPath) { $OutputPath=Join-Path $toolRoot 'inventory\host\host-inventory.json' }
    if (-not $ObservationOutputPath) { $ObservationOutputPath=Join-Path $toolRoot 'inventory\host\amd-selector-observation.json' }
    if (-not $MsiObservationOutputPath) { $MsiObservationOutputPath=Join-Path $toolRoot 'inventory\host\amd-msi-observation.json' }
    $platform=Get-AmdPlatformInfo
    $observation=$null
    $msiObservation=$null
    if($ObservedMsiLog){
        Write-AmdStep ('Parsing AMD MSI observation log: {0}' -f $ObservedMsiLog)
        $msiObservation=ConvertFrom-AmdObservedMsiLog -Path $ObservedMsiLog
        Write-AmdJsonFile -Path $MsiObservationOutputPath -Value $msiObservation -Depth 20
        if([string]::IsNullOrWhiteSpace($ObservedReleaseVersion) -and -not [string]::IsNullOrWhiteSpace([string]$msiObservation.ReleaseVersion)){$ObservedReleaseVersion=[string]$msiObservation.ReleaseVersion}
    }
    if ($ObservedDeviceIdLog) {
        Write-AmdStep ('Parsing AMD selector observation log: {0}' -f $ObservedDeviceIdLog)
        $observation=ConvertFrom-AmdObservedDeviceIdLog -Path $ObservedDeviceIdLog -ObservedReleaseVersion $ObservedReleaseVersion
        Write-AmdJsonFile -Path $ObservationOutputPath -Value $observation -Depth 30
    }
    if ($platform.PlatformFamily -eq 'Windows') {
        Write-AmdStep 'Collecting read-only Windows host PnP/CPU/OS inventory.'
        $hostInventory=Get-AmdLiveWindowsHostInventory
        if ($null -ne $observation) { $hostInventory | Add-Member -NotePropertyName ObservationReference -NotePropertyValue ([pscustomobject]@{ Path=$ObservationOutputPath; Sha256=$observation.SourceSha256 }) -Force }
        if ($null -ne $msiObservation) { $hostInventory | Add-Member -NotePropertyName MsiObservationReference -NotePropertyValue ([pscustomobject]@{ Path=$MsiObservationOutputPath; Sha256=$msiObservation.SourceSha256; ReleaseVersion=$msiObservation.ReleaseVersion }) -Force }
    } elseif ($null -ne $observation) {
        Write-AmdSkip 'Live host survey is unavailable on this platform; constructing a qualification host inventory from the supplied AMD Device_ID log.'
        $hostInventory=ConvertTo-AmdHostInventoryFromObservation -Observation $observation
        if($null -ne $msiObservation -and $null -ne $msiObservation.PrimaryMsiNtProductType){
            $hostInventory.OS.ProductType=[int]$msiObservation.PrimaryMsiNtProductType
            $hostInventory.OS.ProductTypeDerivation='ObservedMsiNTProductType'
        }
    } else {
        $hostInventory=[pscustomobject][ordered]@{ SchemaVersion='amd-chipset-host-inventory/1.0'; CollectedAtUtc=Get-AmdUtcTimestamp; Source='NotCollected'; Platform=$platform; Status='NotAvailableOnPlatform'; Devices=@() }
    }
    Write-AmdJsonFile -Path $OutputPath -Value $hostInventory -Depth 30
    Write-AmdOk ('Host survey -> source={0}; devices={1}' -f [string]$hostInventory.Source,@($hostInventory.Devices).Count)
    return $hostInventory
}

function Get-AmdHostProfileFromInventory {
    [CmdletBinding()]
    param([Parameter(Mandatory=$true)][object]$HostInventory)
    if ($null -eq $HostInventory.OS -or $null -eq $HostInventory.OS.BuildNumber) { return $null }
    $normalizedArch=Get-AmdHostNormalizedArchitecture -HostInventory $HostInventory
    $arch=if($normalizedArch -eq 'x86_64'){'amd64'}elseif($normalizedArch -eq 'arm64'){'arm64'}elseif($normalizedArch -eq 'x86'){'x86'}else{'unknown'}
    $version=[string]$HostInventory.OS.Version
    $major=10; $minor=0
    if ($version -match '^(\d+)\.(\d+)') { $major=[int]$Matches[1]; $minor=[int]$Matches[2] }
    return [pscustomobject][ordered]@{ Id='actual-host'; Name=[string]$HostInventory.OS.Caption; Architecture=$arch; OSMajorVersion=$major; OSMinorVersion=$minor; BuildNumber=[int]$HostInventory.OS.BuildNumber; ProductType=[int]$HostInventory.OS.ProductType; SuiteMask=$HostInventory.OS.SuiteMask; DocumentedKMDF=$null; ObservedKMDF=if($HostInventory.WDF){$HostInventory.WDF.ObservedKMDF}else{$null}; DocumentedUMDF=$null; ObservedUMDF=$null; WdfConfidence='HostObservation' }
}

function Test-AmdHostIdentifierMatch {
    [CmdletBinding()]
    param([Parameter(Mandatory=$true)][object]$Model,[Parameter(Mandatory=$true)][object]$HostDevice)
    $hostHw=@($HostDevice.HardwareIds | ForEach-Object { ([string]$_).ToUpperInvariant() })
    $hostCompat=@($HostDevice.CompatibleIds | ForEach-Object { ([string]$_).ToUpperInvariant() })
    $modelIds=@([string]$Model.HardwareId)+@($Model.CompatibleIds)
    foreach($midRaw in $modelIds){
        if([string]::IsNullOrWhiteSpace([string]$midRaw)){continue}
        $mid=([string]$midRaw).ToUpperInvariant()
        if($hostHw -contains $mid){return [pscustomobject][ordered]@{Matched=$true;MatchType='HostHardwareId';MatchedIdentifier=[string]$midRaw}}
        if($hostCompat -contains $mid){return [pscustomobject][ordered]@{Matched=$true;MatchType='HostCompatibleId';MatchedIdentifier=[string]$midRaw}}
    }
    return [pscustomobject][ordered]@{Matched=$false;MatchType=$null;MatchedIdentifier=$null}
}

function Invoke-AmdHostMatchStage {
    [CmdletBinding()]
    param([string]$HostInventoryPath,[string]$DriverPackagesPath,[string]$EmbeddedMetadataPath,[string]$SelectorStaticPath,[string]$ObservationPath,[string]$MsiObservationPath,[string]$OutputPath,[string]$ReportPath)

    $toolRoot=Get-AmdResearchToolkitRoot
    if(-not $HostInventoryPath){$HostInventoryPath=Join-Path $toolRoot 'inventory\host\host-inventory.json'}
    if(-not $DriverPackagesPath){$DriverPackagesPath=Join-Path $toolRoot 'inventory\driver-packages.json'}
    if(-not $EmbeddedMetadataPath){$EmbeddedMetadataPath=Join-Path $toolRoot 'inventory\embedded-installer-metadata.json'}
    if(-not $SelectorStaticPath){$SelectorStaticPath=Join-Path $toolRoot 'inventory\amd-selector-static.json'}
    if(-not $ObservationPath){$ObservationPath=Join-Path $toolRoot 'inventory\host\amd-selector-observation.json'}
    if(-not $MsiObservationPath){$MsiObservationPath=Join-Path $toolRoot 'inventory\host\amd-msi-observation.json'}
    if(-not $OutputPath){$OutputPath=Join-Path $toolRoot 'inventory\host\amd-chipset-host-analysis.json'}
    if(-not $ReportPath){$ReportPath=Join-Path $toolRoot 'reports\amd-chipset-host-analysis.md'}

    $hostInventory=Read-AmdJsonFile -Path $HostInventoryPath
    if([string]$hostInventory.Source -eq 'NotCollected'){
        $result=[pscustomobject][ordered]@{SchemaVersion='amd-chipset-host-analysis/1.0';ToolkitVersion=$script:AmdChipsetResearchToolkitVersion;GeneratedAtUtc=Get-AmdUtcTimestamp;Status='NotCollected';Host=$hostInventory;Releases=@()}
        Write-AmdJsonFile -Path $OutputPath -Value $result -Depth 30
        Write-AmdUtf8NoBom -Path $ReportPath -Text "# AMD Chipset Host Analysis`n`nHost analysis was not collected on this platform/run.`n"
        Write-AmdSkip 'Host matching skipped because no live/observed host inventory is available.'
        return $result
    }
    $drivers=Read-AmdJsonFile -Path $DriverPackagesPath
    $embedded=Read-AmdJsonFile -Path $EmbeddedMetadataPath
    $selector=Read-AmdJsonFile -Path $SelectorStaticPath
    $observation=$null
    if(Test-Path -LiteralPath $ObservationPath -PathType Leaf){$observation=Read-AmdJsonFile -Path $ObservationPath}
    $msiObservation=$null
    if(Test-Path -LiteralPath $MsiObservationPath -PathType Leaf){$msiObservation=Read-AmdJsonFile -Path $MsiObservationPath}
    $profile=Get-AmdHostProfileFromInventory -HostInventory $hostInventory
    $hostAllIds=New-Object System.Collections.Generic.List[string]
    $hostIdentifierIndex=@{}
    foreach($dev in @($hostInventory.Devices)){
        foreach($id in @($dev.InstanceId)+@($dev.HardwareIds)+@($dev.CompatibleIds)){if($id -and -not $hostAllIds.Contains([string]$id)){$hostAllIds.Add([string]$id)}}
        foreach($id in @($dev.HardwareIds)){
            if([string]::IsNullOrWhiteSpace([string]$id)){continue}
            $k=([string]$id).ToUpperInvariant()
            if(-not $hostIdentifierIndex.ContainsKey($k)){$hostIdentifierIndex[$k]=@()}
            $hostIdentifierIndex[$k]=@($hostIdentifierIndex[$k])+@([pscustomobject]@{Device=$dev;MatchType='HostHardwareId';MatchedIdentifier=[string]$id})
        }
        foreach($id in @($dev.CompatibleIds)){
            if([string]::IsNullOrWhiteSpace([string]$id)){continue}
            $k=([string]$id).ToUpperInvariant()
            if(-not $hostIdentifierIndex.ContainsKey($k)){$hostIdentifierIndex[$k]=@()}
            $hostIdentifierIndex[$k]=@($hostIdentifierIndex[$k])+@([pscustomobject]@{Device=$dev;MatchType='HostCompatibleId';MatchedIdentifier=[string]$id})
        }
    }
    $hostTokens=@(Get-AmdHostDeviceSelectorTokens -Identifiers @($hostAllIds.ToArray()))
    $releaseRecords=New-Object System.Collections.Generic.List[object]
    $versions=@($embedded.Releases|ForEach-Object{[string]$_.ReleaseVersion}|Sort-Object {try{[version]$_}catch{[version]'0.0.0.0'}} -Descending)

    foreach($version in $versions){
        $meta=@($embedded.Releases|Where-Object{$_.ReleaseVersion -eq $version}|Select-Object -First 1)
        $static=@($selector.Releases|Where-Object{$_.ReleaseVersion -eq $version}|Select-Object -First 1)
        $releaseDrivers=@($drivers.DriverPackages|Where-Object{$_.ReleaseVersion -eq $version -and $_.InspectionStatus -eq 'Inspected'})
        $selectorCandidates=New-Object System.Collections.Generic.List[object]
        if($static.Count -gt 0){
            foreach($rule in @($static[0].DevIdRules)){
                $matchedTokens=@($rule.DeviceIds|Where-Object{$hostTokens -contains ([string]$_).ToUpperInvariant()})
                if($matchedTokens.Count -eq 0){continue}
                $manifest=@($rule.InfoProductCandidates)
                $hostManifest=Select-AmdSelectorProductsForHost -Products @($manifest) -HostInventory $hostInventory -ReleaseVersion $version -SelectorBinaryEvidence $(if($static.Count -gt 0){$static[0].SelectorBinaryEvidence}else{$null})
                $manifestFilterStatuses=@('NoMatchingEmbeddedOsEntry','ObservedServerXmlListExclusion','CompiledCaptionClassificationExclusion','CompiledArchitectureNotMatched','NoMatchingEmbeddedOsEntryCompiled')
                $state=if($manifest.Count -eq 0){'FilteredByEmbeddedManifest'}elseif($hostManifest.Status -in $manifestFilterStatuses){'FilteredByEmbeddedManifestOs'}else{'SelectedCandidate'}
                $evidenceLevel=if([string]$hostManifest.EvidenceLevel){[string]$hostManifest.EvidenceLevel}elseif($state -eq 'FilteredByEmbeddedManifestOs'){'AmdStaticInferred'}else{'AmdDeclarativeProven'}
                $selectorCandidates.Add([pscustomobject][ordered]@{PropertyName=[string]$rule.PropertyName;FeatureName=[string]$rule.FeatureName;Source='DevID.xml';EvidenceLevel=$evidenceLevel;MatchedDeviceTokens=@($matchedTokens);ManifestProducts=@($manifest);HostManifestProducts=@($hostManifest.MatchingProducts);HostManifestStatus=$hostManifest.Status;OsClassification=$hostManifest.OsClassification;EmulatedState=$state;RuleNotes=@($hostManifest.Notes)})
            }
        }
        # Release-specific empirically observed special rules. These are intentionally narrow
        # and carry their evidence level so they cannot be mistaken for a general AMD contract.
        if($version -eq '8.07.16.1035'){
            if($hostTokens -contains 'DEV_790B'){
                $ryzenCompiledContract=$null
                if($static.Count -gt 0 -and $null -ne $static[0].SelectorBinaryEvidence -and $null -ne $static[0].SelectorBinaryEvidence.PSObject.Properties['CompiledSelectorContract']){$ryzenCompiledContract=$static[0].SelectorBinaryEvidence.CompiledSelectorContract}
                $ryzenCompiledRule=if($null -ne $ryzenCompiledContract -and $null -ne $ryzenCompiledContract.PSObject.Properties['RyzenPpkgRule']){$ryzenCompiledContract.RyzenPpkgRule}else{$null}
                $ryzenCompiledCandidate=$true
                $ryzenRuleNotes=@()
                $ryzenSource='ObservedSpecialRule'
                $ryzenBaseEvidence='AmdDynamicObservedSingleHost'
                if($null -ne $ryzenCompiledRule){
                    $ryzenCpuSpecial=($hostInventory.CPU -and $hostInventory.CPU.Family -eq [int]$ryzenCompiledRule.CpuSpecialFamily -and $hostInventory.CPU.Model -eq [int]$ryzenCompiledRule.CpuSpecialModel)
                    $ryzenDeviceContext=Test-AmdHostDeviceTokenContext -HostInventory $hostInventory -DeviceTokens @('DEV_790B') -RevisionTokens @($ryzenCompiledRule.AcceptedRevisionTokens)
                    $ryzenRevisionMatched=[bool]$ryzenDeviceContext.Matched
                    $ryzenCompiledCandidate=($ryzenCpuSpecial -or $ryzenRevisionMatched)
                    $ryzenSource='CompiledSpecialRule'
                    $ryzenBaseEvidence='AmdCompiledStaticProven'
                    $ryzenRuleNotes=@('Exact 8.07.16.1035 Qt Setup.exe candidate-creation path first matches DEV_790B, then accepts the CPU Family 23 / Model 160 special path or revision tokens REV_61, REV_59, or REV_51 in the same device context before creating /SETRYZENPPKG. Later Info.xml filtering remains separate.')
                }
                if($ryzenCompiledCandidate){
                    $ryzenProducts=@()
                    if($meta.Count -gt 0){$ryzenProducts=@(Get-AmdSelectorInfoProductCandidates -PropertyName 'SETRYZENPPKG' -Products @($meta[0].Products))}
                    $ryzenHostManifest=Select-AmdSelectorProductsForHost -Products @($ryzenProducts) -HostInventory $hostInventory -ReleaseVersion $version -SelectorBinaryEvidence $(if($static.Count -gt 0){$static[0].SelectorBinaryEvidence}else{$null})
                    $ryzenFiltered=($ryzenHostManifest.Status -in @('ObservedServerXmlListExclusion','CompiledCaptionClassificationExclusion','CompiledArchitectureNotMatched','NoMatchingEmbeddedOsEntryCompiled','NoMatchingEmbeddedOsEntry'))
                    $ryzenState=if($ryzenFiltered){'FilteredByEmbeddedManifestOs'}else{'SelectedCandidate'}
                    $ryzenEvidence=if($ryzenFiltered -and [string]$ryzenHostManifest.EvidenceLevel){[string]$ryzenHostManifest.EvidenceLevel}else{$ryzenBaseEvidence}
                    $selectorCandidates.Add([pscustomobject][ordered]@{PropertyName='SETRYZENPPKG';FeatureName='RYZENPPKG';Source=$ryzenSource;EvidenceLevel=$ryzenEvidence;MatchedDeviceTokens=@($(if($null -ne $ryzenCompiledRule -and $ryzenDeviceContext.Matched){@($ryzenDeviceContext.MatchedDeviceTokens)+@($ryzenDeviceContext.MatchedRevisionTokens)}else{@($hostTokens|Where-Object{$_ -eq 'DEV_790B'})}));ManifestProducts=@($ryzenProducts);HostManifestProducts=@($ryzenHostManifest.MatchingProducts);HostManifestStatus=$ryzenHostManifest.Status;OsClassification=$ryzenHostManifest.OsClassification;EmulatedState=$ryzenState;RuleNotes=@($ryzenRuleNotes)+@($ryzenHostManifest.Notes)})
                }
            }
            $is64=((Get-AmdHostNormalizedArchitecture -HostInventory $hostInventory) -eq 'x86_64')
            if($is64){
                foreach($p in @('SETEMBSMBUS','SETWDT')){
                    $mp=@()
                    if($meta.Count -gt 0){$mp=@(Get-AmdSelectorInfoProductCandidates -PropertyName $p -Products @($meta[0].Products))}
                    $mpHostManifest=Select-AmdSelectorProductsForHost -Products @($mp) -HostInventory $hostInventory -ReleaseVersion $version -SelectorBinaryEvidence $(if($static.Count -gt 0){$static[0].SelectorBinaryEvidence}else{$null})
                    $mpFiltered=($mpHostManifest.Status -in @('ObservedServerXmlListExclusion','CompiledCaptionClassificationExclusion','CompiledArchitectureNotMatched','NoMatchingEmbeddedOsEntryCompiled','NoMatchingEmbeddedOsEntry'))
                    $mpState=if($mp.Count -eq 0){'FilteredByEmbeddedManifest'}elseif($mpFiltered){'FilteredByEmbeddedManifestOs'}else{'SelectedCandidate'}
                    $mpEvidence=if($mpFiltered -and [string]$mpHostManifest.EvidenceLevel){[string]$mpHostManifest.EvidenceLevel}else{'AmdDynamicObservedSingleHost'}
                    $selectorCandidates.Add([pscustomobject][ordered]@{PropertyName=$p;FeatureName=(Get-AmdSelectorFeatureName -PropertyName $p);Source='ObservedSpecialRule';EvidenceLevel=$mpEvidence;MatchedDeviceTokens=@();ManifestProducts=@($mp);HostManifestProducts=@($mpHostManifest.MatchingProducts);HostManifestStatus=$mpHostManifest.Status;OsClassification=$mpHostManifest.OsClassification;EmulatedState=$mpState;RuleNotes=@('8.07.16.1035 observation sets this property on 64-bit WIN10-family OS before XML-list filtering.')+@($mpHostManifest.Notes)})
                }
            }
            if($hostInventory.CPU -and $hostInventory.CPU.Family -eq 25 -and $hostInventory.CPU.Model -eq 33){
                foreach($c in @($selectorCandidates|Where-Object{$_.PropertyName -eq 'SETINTERFACE'})){ $c.EmulatedState='FilteredByCpu'; $c.RuleNotes=@($c.RuleNotes)+@('Exact Family 25 / Model 33 host is dynamically observed as "not PHX or latest" for 8.07.16.1035. This rule is not generalized to other CPU models.') }
            }
            $compiledContract=$null
            if($static.Count -gt 0 -and $null -ne $static[0].SelectorBinaryEvidence -and $null -ne $static[0].SelectorBinaryEvidence.PSObject.Properties['CompiledSelectorContract']){$compiledContract=$static[0].SelectorBinaryEvidence.CompiledSelectorContract}
            if($null -ne $compiledContract -and $null -ne $compiledContract.FilterUsbRule){
                $filterUsbDeviceContext=Test-AmdHostDeviceTokenContext -HostInventory $hostInventory -DeviceTokens @('DEV_790B','DEV_780B') -RevisionTokens @('REV_16')
                foreach($c in @($selectorCandidates|Where-Object{$_.PropertyName -eq 'SETFILTERUSB'})){
                    if(-not $filterUsbDeviceContext.Matched){
                        $c.EmulatedState='FilteredByCompiledDeviceRevision'
                        $c.EvidenceLevel='AmdCompiledStaticProven'
                        $c.RuleNotes=@($c.RuleNotes)+@('Exact 8.07.16.1035 Qt Setup.exe branch searches for /SETFILTERUSB, requires DEV_790B (or DEV_780B fallback context) together with REV_16, and otherwise erases SETFILTERUSB through its vector-removal helper without emitting the generic XML-list removal message.')
                    } else {
                        $c.RuleNotes=@($c.RuleNotes)+@('Exact 8.07.16.1035 Qt SETFILTERUSB device/revision prerequisite is satisfied in the same device context (DEV_790B/DEV_780B + REV_16); later manifest/selector checks may still apply.')
                    }
                }
            }
        }

        $selectorComparison=New-Object System.Collections.Generic.List[object]
        $observedVersion=if($null -ne $observation -and -not [string]::IsNullOrWhiteSpace([string]$observation.ObservedReleaseVersion)){[string]$observation.ObservedReleaseVersion}elseif($null -ne $msiObservation){[string]$msiObservation.ReleaseVersion}else{$null}
        $observationApplies=($null -ne $observation -and -not [string]::IsNullOrWhiteSpace($observedVersion) -and $observedVersion -eq $version)
        if($observationApplies){
            $observedFinal=@($observation.FinalSupportedProperties)
            $observedRemoved=@{}
            foreach($ev in @($observation.RemovalEvents)){$observedRemoved[[string]$ev.PropertyName]=[string]$ev.Reason}
            $observedImplicit=@{}
            foreach($ev in @($observation.ImplicitRemovalEvents)){$observedImplicit[[string]$ev.PropertyName]=[string]$ev.Reason}
            $observedCandidates=@($observation.CandidateEvents|ForEach-Object{$_.PropertyName}|Where-Object{$_}|Sort-Object -Unique)
            $allProps=@(@($selectorCandidates|ForEach-Object{$_.PropertyName})+@($observedCandidates)+@($observedFinal)|Sort-Object -Unique)
            foreach($p in $allProps){
                $pred=@($selectorCandidates|Where-Object{$_.PropertyName -eq $p}|Select-Object -First 1)
                $predSelected=($pred.Count -gt 0 -and $pred[0].EmulatedState -eq 'SelectedCandidate')
                $obsCandidate=($observedCandidates -contains $p)
                $obsSelected=($observedFinal -contains $p)
                $predState=if($pred.Count -gt 0){[string]$pred[0].EmulatedState}else{'NoEmulatedCandidate'}
                $predEvidence=if($pred.Count -gt 0){[string]$pred[0].EvidenceLevel}else{$null}
                $status=if(-not $observation.FinalSupportedListObserved){'ObservedFinalSelectionUnavailable'}elseif($predSelected -and $obsSelected){'EmulationConfirmed'}elseif($predSelected -and -not $obsSelected){if($observedRemoved.ContainsKey($p)){'ObservedFilterExplained'}elseif($observedImplicit.ContainsKey($p)){'UnknownAmdFilterSuspected'}else{'UnknownAmdFilterSuspected'}}elseif(-not $predSelected -and $obsSelected){'ObservedSelectionNotEmulated'}elseif($predState -eq 'FilteredByCompiledDeviceRevision' -and $observedImplicit.ContainsKey($p)){'ObservedFilterExplainedByCompiledRule'}elseif($observedRemoved.ContainsKey($p)){'ObservedFilterExplained'}elseif($observedImplicit.ContainsKey($p)){if($predEvidence -eq 'AmdCompiledStaticProven'){'ObservedFilterExplainedByCompiledRule'}else{'UnknownAmdFilterSuspected'}}elseif($pred.Count -gt 0 -and $predEvidence -eq 'AmdStaticInferred'){'ObservedFilterExplainedByStaticInference'}else{'NotSelected'}
                $selectorComparison.Add([pscustomobject][ordered]@{PropertyName=$p;PredictedState=if($pred.Count -gt 0){$pred[0].EmulatedState}else{'NoEmulatedCandidate'};ObservedCandidate=$obsCandidate;ObservedSelected=$obsSelected;ObservedRemovalReason=if($observedRemoved.ContainsKey($p)){$observedRemoved[$p]}elseif($observedImplicit.ContainsKey($p)){'ImplicitRemoval: absent from observed final list without explicit AMD removal log'}else{$null};Comparison=$status})
            }
        }

        $infMatches=New-Object System.Collections.Generic.List[object]
        $infMatchKeys=@{}
        if($null -ne $profile){
            foreach($driver in $releaseDrivers){
                if($null -eq $driver.InfTopology){continue}
                $selectedModels=New-Object System.Collections.Generic.List[object]
                foreach($mfg in @($driver.InfTopology.ManufacturerEntries)){
                    $sel=Select-AmdModelsSectionForProfile -Topology $driver.InfTopology -ManufacturerEntry $mfg -Profile $profile -Mode 'AsPublished'
                    if($sel.Status -in @('Applicable','ApplicableFallback')){foreach($model in @($sel.Models)){$selectedModels.Add($model)}}
                }
                foreach($model in @($selectedModels.ToArray())){
                    $modelIds=@([string]$model.HardwareId)+@($model.CompatibleIds)
                    foreach($modelId in $modelIds){
                        if([string]::IsNullOrWhiteSpace([string]$modelId)){continue}
                        $lookupKey=([string]$modelId).ToUpperInvariant()
                        if(-not $hostIdentifierIndex.ContainsKey($lookupKey)){continue}
                        foreach($indexed in @($hostIdentifierIndex[$lookupKey])){
                            $hostDev=$indexed.Device
                            $keyHost=if([string]$hostInventory.Source -eq 'AmdDeviceIdLogObservation'){'QUALIFICATION-HOST'}else{[string]$hostDev.InstanceId}
                            $matchKey=('{0}|{1}|{2}|{3}' -f [string]$driver.InfRelativePath,[string]$model.HardwareId,[string]$model.InstallSection,$keyHost).ToUpperInvariant()
                            if(-not $infMatchKeys.ContainsKey($matchKey)){
                                $infMatchKeys[$matchKey]=$true
                                $infMatches.Add([pscustomobject][ordered]@{InfRelativePath=[string]$driver.InfRelativePath;DriverVersion=if($driver.VersionSection){[string]$driver.VersionSection.DriverVersion}else{$null};DeviceDescription=[string]$model.Description;InstallSection=[string]$model.InstallSection;InfIdentifier=[string]$model.HardwareId;HostInstanceId=if([string]$hostInventory.Source -eq 'AmdDeviceIdLogObservation'){$null}else{[string]$hostDev.InstanceId};HostDeviceName=if([string]$hostInventory.Source -eq 'AmdDeviceIdLogObservation'){'Observed qualification host'}else{[string]$hostDev.Name};MatchType=[string]$indexed.MatchType;MatchedIdentifier=[string]$indexed.MatchedIdentifier;Wdf=$driver.Wdf;CurrentDriver=$hostDev.CurrentDriver})
                            }
                        }
                    }
                }
            }
        }
        $msiConsistency=$null
        if($null -ne $msiObservation -and [string]$msiObservation.ReleaseVersion -eq $version){
            $deviceFeatures=if($null -ne $observation){@($observation.FinalSupportedFeatures|Sort-Object -Unique)}else{@()}
            $msiFeatures=@($msiObservation.AddLocalFeatures|Where-Object{$_ -ne 'DRIVERS'}|Sort-Object -Unique)
            $same=(($deviceFeatures -join ',') -eq ($msiFeatures -join ','))
            $comparison=if([string]$msiObservation.TransactionMode -eq 'AdministrativeExtraction'){'NotApplicableAdministrativeExtraction'}elseif(-not $msiObservation.AddLocalObserved){'AddLocalNotObserved'}elseif($null -ne $observation){if($same){'Consistent'}else{'Mismatch'}}else{'DeviceObservationUnavailable'}
            $msiConsistency=[pscustomobject][ordered]@{ReleaseVersion=[string]$msiObservation.ReleaseVersion;TransactionMode=[string]$msiObservation.TransactionMode;ActionProperty=[string]$msiObservation.ActionProperty;MsiNtProductTypes=@($msiObservation.MsiNtProductTypes);PrimaryMsiNtProductType=$msiObservation.PrimaryMsiNtProductType;AddLocalObserved=[bool]$msiObservation.AddLocalObserved;AddLocalFeatures=@($msiObservation.AddLocalFeatures);SetProperties=@($msiObservation.SetProperties);FeatureSelectionInterpretation=[string]$msiObservation.FeatureSelectionInterpretation;FinalInstallStatus=$msiObservation.FinalInstallStatus;DeviceLogVsMsiAddLocal=$comparison}
        }
        $releaseRecords.Add([pscustomobject][ordered]@{ReleaseVersion=$version;SelectorCandidates=@($selectorCandidates.ToArray());SelectorComparison=@($selectorComparison.ToArray());MsiObservation=$msiConsistency;WindowsPnpInfMatches=@($infMatches.ToArray());Summary=[pscustomobject][ordered]@{SelectorCandidateCount=$(@($selectorCandidates|Where-Object{$_.EmulatedState -eq 'SelectedCandidate'}).Count);FilteredByManifestCount=$(@($selectorCandidates|Where-Object{$_.EmulatedState -in @('FilteredByEmbeddedManifest','FilteredByEmbeddedManifestOs')}).Count);CompiledCaptionExclusionCount=$(@($selectorCandidates|Where-Object{$_.HostManifestStatus -eq 'CompiledCaptionClassificationExclusion'}).Count);FilteredByCompiledRuleCount=$(@($selectorCandidates|Where-Object{$_.EmulatedState -eq 'FilteredByCompiledDeviceRevision'}).Count);ObservedServerXmlFilterCount=$(@($selectorCandidates|Where-Object{$_.HostManifestStatus -in @('ObservedServerXmlListExclusion','CompiledCaptionClassificationExclusion')}).Count);FilteredByCpuCount=$(@($selectorCandidates|Where-Object{$_.EmulatedState -eq 'FilteredByCpu'}).Count);PnpInfMatchCount=$infMatches.Count;UnknownAmdFilterCount=$(@($selectorComparison|Where-Object{$_.Comparison -eq 'UnknownAmdFilterSuspected'}).Count)}})
    }

    $result=[pscustomobject][ordered]@{SchemaVersion='amd-chipset-host-analysis/1.3';ToolkitVersion=$script:AmdChipsetResearchToolkitVersion;GeneratedAtUtc=Get-AmdUtcTimestamp;Status='Analyzed';Semantics=[pscustomobject][ordered]@{WindowsPnp='Microsoft INF Models/TargetOSVersion + actual host identifier matching.';AmdSelector='DevID.xml declarative mapping plus exact-binary compiled Qt selector contracts when SHA-256 matched, followed by narrowly scoped dynamic observations; unresolved mismatches remain visible.';CompatibilityBoundary='Read-only candidate analysis. No driver installation, staging, AMD EXE execution, or runtime compatibility claim.';AdministrativeExtraction='MSI ACTION=ADMIN is payload extraction evidence. Feature Request=Local in that transaction is not AMD install-selection evidence.';ImplicitRemoval='A detected AMD SETxxx candidate absent from observed final SupportedDrivers without an explicit removal line remains unresolved unless an exact-binary compiled rule explains the silent removal. SETFILTERUSB has such a compiled rule for the independently matched 7.11.26.2142 and 8.07.16.1035 Qt selectors.';CompiledQtSelector='Independent SHA-256-scoped contracts exist for representative 3.x, 4.x, 5.x, 6.x, 7.x and 8.x Qt Setup.exe binaries. Static disassembly proves Caption substring classification and Client Info.xml filtering for 3.x-8.x, while compiled SETFILTERUSB and RYZENPPKG hardware predicates are proven only for the exact 7.11.26.2142 and 8.07.16.1035 selectors. Dynamic multi-host corroboration currently applies only to the 8.07.16.1035 qualification fixtures.'};Host=$hostInventory;Observation=[pscustomobject][ordered]@{DeviceLog=if($null -ne $observation){[pscustomobject]@{SourceSha256=$observation.SourceSha256;ObservedReleaseVersion=$observation.ObservedReleaseVersion;FinalSupportedListObserved=[bool]$observation.FinalSupportedListObserved;FinalSelectionStatus=[string]$observation.FinalSelectionStatus;FinalSupportedFeatures=@($observation.FinalSupportedFeatures);ImplicitRemovalCount=@($observation.ImplicitRemovalEvents).Count}}else{$null};MsiLog=if($null -ne $msiObservation){[pscustomobject]@{SourceSha256=$msiObservation.SourceSha256;ReleaseVersion=$msiObservation.ReleaseVersion;TransactionMode=$msiObservation.TransactionMode;PrimaryMsiNtProductType=$msiObservation.PrimaryMsiNtProductType;AddLocalObserved=[bool]$msiObservation.AddLocalObserved;AddLocalFeatures=@($msiObservation.AddLocalFeatures);FinalInstallStatus=$msiObservation.FinalInstallStatus}}else{$null}};Releases=@($releaseRecords.ToArray())}
    Write-AmdJsonFile -Path $OutputPath -Value $result -Depth 50

    $md=New-Object System.Text.StringBuilder
    [void]$md.AppendLine('# AMD Chipset Host / AMD Selector Analysis')
    [void]$md.AppendLine('')
    [void]$md.AppendLine('> Read-only analysis. `EmulationConfirmed` means the current emulation agreed with supplied AMD installer observation evidence; it is not a guarantee of installation/runtime compatibility.')
    [void]$md.AppendLine('')
    [void]$md.AppendLine(('Host source: `{0}`' -f [string]$hostInventory.Source))
    if($hostInventory.OS){[void]$md.AppendLine(('Host OS: `{0}` build `{1}` ProductType `{2}`' -f [string]$hostInventory.OS.Caption,[string]$hostInventory.OS.BuildNumber,[string]$hostInventory.OS.ProductType))}
    if($hostInventory.CPU){[void]$md.AppendLine(('Host CPU: `{0}` / Family `{1}` Model `{2}` Stepping `{3}`' -f [string]$hostInventory.CPU.Name,[string]$hostInventory.CPU.Family,[string]$hostInventory.CPU.Model,[string]$hostInventory.CPU.Stepping))}
    [void]$md.AppendLine('')
    foreach($rel in @($releaseRecords.ToArray())){
        [void]$md.AppendLine(('## AMD Chipset Software {0}' -f $rel.ReleaseVersion));[void]$md.AppendLine('')
        [void]$md.AppendLine(('- Selector selected candidates: **{0}**; PnP INF matches: **{1}**; unresolved AMD-filter mismatches: **{2}**' -f $rel.Summary.SelectorCandidateCount,$rel.Summary.PnpInfMatchCount,$rel.Summary.UnknownAmdFilterCount));[void]$md.AppendLine('')
        if($rel.MsiObservation){
            if([string]$rel.MsiObservation.TransactionMode -eq 'AdministrativeExtraction'){[void]$md.AppendLine(('- AMD MSI observation: **AdministrativeExtraction** (`ACTION=ADMIN`); `MsiNTProductType={0}`; ADDLOCAL comparison: **{1}**. Feature `Request=Local` in this transaction is payload-extraction evidence, not install-selection evidence.' -f [string]$rel.MsiObservation.PrimaryMsiNtProductType,[string]$rel.MsiObservation.DeviceLogVsMsiAddLocal))}
            else{[void]$md.AppendLine(('- AMD MSI observation: mode `{0}`; ADDLOCAL `{1}`; Device_ID vs MSI: **{2}**; install status: `{3}`' -f [string]$rel.MsiObservation.TransactionMode,(@($rel.MsiObservation.AddLocalFeatures)-join ','),[string]$rel.MsiObservation.DeviceLogVsMsiAddLocal,[string]$rel.MsiObservation.FinalInstallStatus))}
            [void]$md.AppendLine('')
        }
        if(@($rel.SelectorComparison).Count -gt 0){
            [void]$md.AppendLine('| Property | Emulated | AMD candidate observed | AMD final selected | Observed filter reason | Comparison |');[void]$md.AppendLine('|---|---|---|---|---|---|')
            foreach($c in @($rel.SelectorComparison)){[void]$md.AppendLine(('| `{0}` | {1} | {2} | {3} | {4} | **{5}** |' -f $c.PropertyName,$c.PredictedState,$c.ObservedCandidate,$c.ObservedSelected,([string]$c.ObservedRemovalReason),$c.Comparison))};[void]$md.AppendLine('')
        }
        if(@($rel.WindowsPnpInfMatches).Count -gt 0){
            [void]$md.AppendLine('| Host device | INF | Device | Match | Current driver | Candidate version |');[void]$md.AppendLine('|---|---|---|---|---|---|')
            foreach($m in @($rel.WindowsPnpInfMatches|Select-Object -First 200)){$cur=if($m.CurrentDriver){('{0} {1}' -f $m.CurrentDriver.InfName,$m.CurrentDriver.DriverVersion)}else{''};[void]$md.AppendLine(('| {0} | `{1}` | {2} | {3} | {4} | {5} |' -f ([string]$m.HostDeviceName).Replace('|','\|'),$m.InfRelativePath,([string]$m.DeviceDescription).Replace('|','\|'),$m.MatchType,$cur,$m.DriverVersion))};[void]$md.AppendLine('')
        }
    }
    Write-AmdUtf8NoBom -Path $ReportPath -Text $md.ToString()
    Write-AmdOk ('Host analysis -> releases={0}; output={1}' -f $releaseRecords.Count,$OutputPath)
    return $result
}

function Test-AmdPortableAnalysisPathProperty {
    [CmdletBinding()]
    param([AllowNull()][string]$PropertyName)

    if ([string]::IsNullOrWhiteSpace($PropertyName)) { return $false }
    return ($PropertyName -in @(
        'LocalPath','ExtractionRoot','InstallerPath','ContainerPath','ResolvedPath','InfPath','MsiPath',
        'OutputPath','OutputDirectory','ParentContainer','EvidenceLogPath','HtmlEvidencePath','Path'
    ))
}

function ConvertTo-AmdPortableAnalysisPath {
    [CmdletBinding()]
    param(
        [AllowNull()]
        [string]$Path,

        [AllowNull()]
        [string]$ExtractionRoot,

        [AllowNull()]
        [string]$InstallerPath,

        [Parameter(Mandatory = $true)]
        [string]$ReleaseVersion
    )

    if ([string]::IsNullOrWhiteSpace($Path)) {
        return $Path
    }

    # Only normalize strings that look like rooted Windows/POSIX paths. URLs,
    # INF directives, HWIDs and already-relative evidence strings remain intact.
    $looksRooted = $false
    if ($Path -match '^[A-Za-z]:[\\/]') { $looksRooted = $true }
    elseif ($Path.StartsWith('/')) { $looksRooted = $true }
    if (-not $looksRooted) { return $Path }

    $normalized = $Path.Replace('\', '/')
    $normalizedExtractionRoot = if ($ExtractionRoot) { $ExtractionRoot.Replace('\', '/').TrimEnd('/') } else { $null }
    $normalizedInstallerPath = if ($InstallerPath) { $InstallerPath.Replace('\', '/') } else { $null }

    if ($normalizedExtractionRoot) {
        if ($normalized -ieq $normalizedExtractionRoot) {
            return ('work/extracted/{0}' -f $ReleaseVersion)
        }
        $prefix = $normalizedExtractionRoot + '/'
        if ($normalized.StartsWith($prefix, [System.StringComparison]::OrdinalIgnoreCase)) {
            $relative = $normalized.Substring($prefix.Length)
            return ('work/extracted/{0}/{1}' -f $ReleaseVersion, $relative)
        }
    }

    if ($normalizedInstallerPath -and $normalized -ieq $normalizedInstallerPath) {
        return ('external-artifact/{0}' -f [System.IO.Path]::GetFileName($normalized))
    }

    $evidenceMarker = '/evidence/extraction-logs/'
    $markerIndex = $normalized.IndexOf($evidenceMarker, [System.StringComparison]::OrdinalIgnoreCase)
    if ($markerIndex -ge 0) {
        return $normalized.Substring($markerIndex + 1)
    }

    # A per-release canonical record must remain repository-portable even when
    # the runtime analysis was performed on a different machine. Retain the
    # leaf name while explicitly marking that the original path was external.
    return ('external-path/{0}' -f [System.IO.Path]::GetFileName($normalized))
}

function ConvertTo-AmdPortableAnalysisValue {
    [CmdletBinding()]
    param(
        [AllowNull()]
        $Value,

        [AllowNull()]
        [string]$ExtractionRoot,

        [AllowNull()]
        [string]$InstallerPath,

        [Parameter(Mandatory = $true)]
        [string]$ReleaseVersion,

        [AllowNull()]
        [string]$PropertyName
    )

    if ($null -eq $Value) { return $null }

    if ($Value -is [string]) {
        # Portable-path normalization is field-scoped. AMD selector/MSI/XML tokens
        # such as /SETFILTERUSB, /SETRYZENPPKG, /info.xml, /DevID.xml and C:\
        # are evidence values, not execution-host filesystem paths, and must remain byte-faithful.
        if (Test-AmdPortableAnalysisPathProperty -PropertyName $PropertyName) {
            return ConvertTo-AmdPortableAnalysisPath -Path ([string]$Value) -ExtractionRoot $ExtractionRoot -InstallerPath $InstallerPath -ReleaseVersion $ReleaseVersion
        }
        return [string]$Value
    }

    if ($Value -is [System.Collections.IDictionary]) {
        $result = [ordered]@{}
        foreach ($key in $Value.Keys) {
            $name = [string]$key
            # Full extractor stdout/stderr belongs in the Evidence ZIP. Keeping it
            # in every release JSON would duplicate megabytes of run-specific paths
            # and reduce the value of the GitHub-committed canonical record.
            if ($name -eq 'Log') { continue }
            $result[$name] = ConvertTo-AmdPortableAnalysisValue -Value $Value[$key] -ExtractionRoot $ExtractionRoot -InstallerPath $InstallerPath -ReleaseVersion $ReleaseVersion -PropertyName $name
        }
        return [pscustomobject]$result
    }

    if ($Value -is [psobject] -and -not ($Value -is [ValueType])) {
        $properties = @($Value.PSObject.Properties)
        if ($properties.Count -gt 0) {
            $result = [ordered]@{}
            foreach ($property in $properties) {
                $name = [string]$property.Name
                if ($name -eq 'Log') { continue }
                $result[$name] = ConvertTo-AmdPortableAnalysisValue -Value $property.Value -ExtractionRoot $ExtractionRoot -InstallerPath $InstallerPath -ReleaseVersion $ReleaseVersion -PropertyName $name
            }
            return [pscustomobject]$result
        }
    }

    if ($Value -is [System.Collections.IEnumerable] -and -not ($Value -is [string])) {
        $items = New-Object System.Collections.Generic.List[object]
        foreach ($item in $Value) {
            $convertedItem = ConvertTo-AmdPortableAnalysisValue -Value $item -ExtractionRoot $ExtractionRoot -InstallerPath $InstallerPath -ReleaseVersion $ReleaseVersion -PropertyName $PropertyName
            $items.Add($convertedItem)
        }
        # PowerShell enumerates arrays returned from functions. Without -NoEnumerate,
        # a one-element array becomes a scalar and an empty array becomes $null when
        # embedded into the portable JSON object graph. Preserve the original array
        # contract explicitly for stable JSON/schema output on PS 5.1 and PS 7.x.
        Write-Output -NoEnumerate ([object[]]$items.ToArray())
        return
    }

    return $Value
}

function ConvertTo-AmdPortableReleaseAnalysisRecord {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $Release
    )

    $releaseVersion = [string]$Release.ReleaseVersion
    $extractionRoot = if ($Release.Extraction -and $Release.Extraction.ExtractionRoot) { [string]$Release.Extraction.ExtractionRoot } else { $null }
    $installerPath = if ($Release.Extraction -and $Release.Extraction.InstallerPath) { [string]$Release.Extraction.InstallerPath } elseif ($Release.Acquisition -and $Release.Acquisition.LocalPath) { [string]$Release.Acquisition.LocalPath } else { $null }

    [pscustomobject][ordered]@{
        Version = $releaseVersion
        Discovery = ConvertTo-AmdPortableAnalysisValue -Value $Release.Discovery -ExtractionRoot $extractionRoot -InstallerPath $installerPath -ReleaseVersion $releaseVersion
        Metadata = ConvertTo-AmdPortableAnalysisValue -Value $Release.Metadata -ExtractionRoot $extractionRoot -InstallerPath $installerPath -ReleaseVersion $releaseVersion
        Acquisition = ConvertTo-AmdPortableAnalysisValue -Value $Release.Acquisition -ExtractionRoot $extractionRoot -InstallerPath $installerPath -ReleaseVersion $releaseVersion
        Extraction = ConvertTo-AmdPortableAnalysisValue -Value $Release.Extraction -ExtractionRoot $extractionRoot -InstallerPath $installerPath -ReleaseVersion $releaseVersion
        EmbeddedInstallerMetadata = ConvertTo-AmdPortableAnalysisValue -Value $Release.EmbeddedInstallerMetadata -ExtractionRoot $extractionRoot -InstallerPath $installerPath -ReleaseVersion $releaseVersion
        AmdSelectorStatic = ConvertTo-AmdPortableAnalysisValue -Value $(if ($null -ne $Release.PSObject.Properties['AmdSelectorStatic']) { $Release.AmdSelectorStatic } else { $null }) -ExtractionRoot $extractionRoot -InstallerPath $installerPath -ReleaseVersion $releaseVersion
        DriverPackages = @(
            @($Release.DriverPackages) | ForEach-Object {
                ConvertTo-AmdPortableAnalysisValue -Value $_ -ExtractionRoot $extractionRoot -InstallerPath $installerPath -ReleaseVersion $releaseVersion
            }
        )
    }
}

function Test-AmdPortableAnalysisNormalizationSelfTest {
    [CmdletBinding()]
    param()

    $release = '8.07.16.1035'
    $root = 'D:\Research\work\extracted\8.07.16.1035'
    $installer = 'D:\Research\private\evidence\installers\8.07.16.1035\amd_software_8.07.16.1035.exe'

    $token = ConvertTo-AmdPortableAnalysisValue -Value '/SETFILTERUSB' -ExtractionRoot $root -InstallerPath $installer -ReleaseVersion $release -PropertyName 'Candidate'
    $manifestToken = ConvertTo-AmdPortableAnalysisValue -Value '/info.xml' -ExtractionRoot $root -InstallerPath $installer -ReleaseVersion $release -PropertyName 'ManifestPath'
    $msiValue = ConvertTo-AmdPortableAnalysisValue -Value 'C:\' -ExtractionRoot $root -InstallerPath $installer -ReleaseVersion $release -PropertyName 'Value'
    $infPath = ConvertTo-AmdPortableAnalysisValue -Value 'D:\Research\work\extracted\8.07.16.1035\d3_Data1.cab_deadbeef\amdtest.inf' -ExtractionRoot $root -InstallerPath $installer -ReleaseVersion $release -PropertyName 'InfPath'
    $externalPath = ConvertTo-AmdPortableAnalysisValue -Value 'D:\VendorCache\Data1.cab' -ExtractionRoot $root -InstallerPath $installer -ReleaseVersion $release -PropertyName 'ContainerPath'

    $ok = (
        $token -eq '/SETFILTERUSB' -and
        $manifestToken -eq '/info.xml' -and
        $msiValue -eq 'C:\' -and
        $infPath -eq 'work/extracted/8.07.16.1035/d3_Data1.cab_deadbeef/amdtest.inf' -and
        $externalPath -eq 'external-path/Data1.cab'
    )

    return [pscustomobject][ordered]@{
        Status = if ($ok) { 'Pass' } else { 'Fail' }
        SelectorToken = $token
        ManifestToken = $manifestToken
        MsiPropertyValue = $msiValue
        PortableInfPath = $infPath
        ExternalFilesystemPath = $externalPath
    }
}

function Invoke-AmdBuildStage {
    [CmdletBinding()]
    param(
        [string]$ReleasesPath,
        [string]$MetadataPath,
        [string]$AcquisitionPath,
        [string]$ExtractionPath,
        [string]$DriverPackagesPath,
        [string]$EnvironmentPath,
        [string]$EmbeddedMetadataPath,
        [string]$SelectorStaticPath,
        [string]$HostAnalysisPath,
        [string]$OutputJsonPath,
        [string]$OutputCsvPath,
        [string]$OutputMarkdownPath,
        [string]$ReleaseAnalysisRoot,
        [string]$ReleaseReportRoot,
        [string]$CompatibilityCsvPath,
        [string]$CompatibilityMarkdownPath
    )

    $toolRoot = Get-AmdResearchToolkitRoot

    if (-not $ReleasesPath) { $ReleasesPath = Join-Path $toolRoot 'inventory\releases.json' }
    if (-not $MetadataPath) { $MetadataPath = Join-Path $toolRoot 'inventory\release-metadata.json' }
    if (-not $AcquisitionPath) { $AcquisitionPath = Join-Path $toolRoot 'inventory\acquisition.json' }
    if (-not $ExtractionPath) { $ExtractionPath = Join-Path $toolRoot 'inventory\extraction.json' }
    if (-not $DriverPackagesPath) { $DriverPackagesPath = Join-Path $toolRoot 'inventory\driver-packages.json' }
    if (-not $EnvironmentPath) { $EnvironmentPath = Join-Path $toolRoot 'inventory\environment.json' }
    if (-not $EmbeddedMetadataPath) { $EmbeddedMetadataPath = Join-Path $toolRoot 'inventory\embedded-installer-metadata.json' }
    if (-not $SelectorStaticPath) { $SelectorStaticPath = Join-Path $toolRoot 'inventory\amd-selector-static.json' }
    if (-not $HostAnalysisPath) { $HostAnalysisPath = Join-Path $toolRoot 'inventory\host\amd-chipset-host-analysis.json' }
    if (-not $OutputJsonPath) { $OutputJsonPath = Join-Path $toolRoot 'inventory\amd-chipset-driver-inventory.json' }
    if (-not $OutputCsvPath) { $OutputCsvPath = Join-Path $toolRoot 'inventory\amd-chipset-driver-inventory.csv' }
    if (-not $OutputMarkdownPath) { $OutputMarkdownPath = Join-Path $toolRoot 'reports\amd-chipset-driver-history.md' }
    if (-not $ReleaseAnalysisRoot) { $ReleaseAnalysisRoot = Join-Path $toolRoot 'inventory\releases' }
    if (-not $ReleaseReportRoot) { $ReleaseReportRoot = Join-Path $toolRoot 'reports\releases' }
    if (-not $CompatibilityCsvPath) { $CompatibilityCsvPath = Join-Path $toolRoot 'inventory\amd-chipset-windows-server-compatibility.csv' }
    if (-not $CompatibilityMarkdownPath) { $CompatibilityMarkdownPath = Join-Path $toolRoot 'reports\amd-chipset-windows-server-compatibility.md' }

    function Read-OptionalJson {
        param([string]$Path)
        if (Test-Path -LiteralPath $Path -PathType Leaf) {
            return Read-AmdJsonFile -Path $Path
        }
        return $null
    }

    $releasesData = Read-OptionalJson -Path $ReleasesPath
    $metadataData = Read-OptionalJson -Path $MetadataPath
    $acquisitionData = Read-OptionalJson -Path $AcquisitionPath
    $extractionData = Read-OptionalJson -Path $ExtractionPath
    $driversData = Read-OptionalJson -Path $DriverPackagesPath
    $environmentData = Read-OptionalJson -Path $EnvironmentPath
    $embeddedMetadataData = Read-OptionalJson -Path $EmbeddedMetadataPath
    $selectorStaticData = Read-OptionalJson -Path $SelectorStaticPath
    $hostAnalysisData = Read-OptionalJson -Path $HostAnalysisPath

    $versionSet = @{}

    if ($releasesData) {
        foreach ($r in @($releasesData.Releases)) {
            if ($r.ReleaseVersion) { $versionSet[[string]$r.ReleaseVersion] = $true }
        }
    }
    if ($metadataData) {
        foreach ($r in @($metadataData.Releases)) {
            if ($r.ReleaseVersion) { $versionSet[[string]$r.ReleaseVersion] = $true }
        }
    }
    if ($acquisitionData) {
        foreach ($r in @($acquisitionData.Artifacts)) {
            if ($r.ReleaseVersion) { $versionSet[[string]$r.ReleaseVersion] = $true }
        }
    }
    if ($driversData) {
        foreach ($r in @($driversData.DriverPackages)) {
            if ($r.ReleaseVersion) { $versionSet[[string]$r.ReleaseVersion] = $true }
        }
    }
    if ($embeddedMetadataData) {
        foreach ($r in @($embeddedMetadataData.Releases)) {
            if ($r.ReleaseVersion) { $versionSet[[string]$r.ReleaseVersion] = $true }
        }
    }
    if ($selectorStaticData) {
        foreach ($r in @($selectorStaticData.Releases)) { if ($r.ReleaseVersion) { $versionSet[[string]$r.ReleaseVersion] = $true } }
    }

    $releaseInventory = New-Object System.Collections.Generic.List[object]

    $versions = @(
        $versionSet.Keys |
            Sort-Object {
                try { [version]$_ } catch { [version]'0.0.0.0' }
            }
    )

    foreach ($version in $versions) {
        $releaseRecord = $null
        $metadataRecord = $null
        $acquisitionRecord = $null
        $extractionRecord = $null
        $embeddedMetadataRecord = $null
        $selectorStaticRecord = $null
        $driverRecords = @()

        if ($releasesData) {
            $tmp = @($releasesData.Releases | Where-Object { $_.ReleaseVersion -eq $version } | Select-Object -First 1)
            if ($tmp.Count -gt 0) { $releaseRecord = $tmp[0] }
        }

        if ($metadataData) {
            $tmp = @($metadataData.Releases | Where-Object { $_.ReleaseVersion -eq $version } | Select-Object -First 1)
            if ($tmp.Count -gt 0) { $metadataRecord = $tmp[0] }
        }

        if ($acquisitionData) {
            $tmp = @($acquisitionData.Artifacts | Where-Object { $_.ReleaseVersion -eq $version } | Select-Object -First 1)
            if ($tmp.Count -gt 0) { $acquisitionRecord = $tmp[0] }
        }

        if ($extractionData) {
            $tmp = @($extractionData.Releases | Where-Object { $_.ReleaseVersion -eq $version } | Select-Object -First 1)
            if ($tmp.Count -gt 0) { $extractionRecord = $tmp[0] }
        }

        if ($embeddedMetadataData) {
            $tmp = @($embeddedMetadataData.Releases | Where-Object { $_.ReleaseVersion -eq $version } | Select-Object -First 1)
            if ($tmp.Count -gt 0) { $embeddedMetadataRecord = $tmp[0] }
        }

        if ($selectorStaticData) {
            $tmp = @($selectorStaticData.Releases | Where-Object { $_.ReleaseVersion -eq $version } | Select-Object -First 1)
            if ($tmp.Count -gt 0) { $selectorStaticRecord = $tmp[0] }
        }
        if ($driversData) {
            $driverRecords = @($driversData.DriverPackages | Where-Object { $_.ReleaseVersion -eq $version })
        }

        $releaseInventory.Add([pscustomobject]@{
            ReleaseVersion = $version
            Discovery = $releaseRecord
            Metadata = $metadataRecord
            Acquisition = $acquisitionRecord
            Extraction = $extractionRecord
            EmbeddedInstallerMetadata = $embeddedMetadataRecord
            AmdSelectorStatic = $selectorStaticRecord
            DriverPackages = @($driverRecords)
        })
    }

    $inventory = [pscustomobject]@{
        SchemaVersion = '1.0'
        ToolkitVersion = $script:AmdChipsetResearchToolkitVersion
        GeneratedAtUtc = [DateTime]::UtcNow.ToString('o')
        Purpose = 'ResearchInventory'
        CompatibilityPolicyIncluded = $false
        WindowsServerStaticAnalysisIncluded = $true
        AmdSelectorStaticAnalysisIncluded = ($null -ne $selectorStaticData)
        HostAnalysisIncluded = ($null -ne $hostAnalysisData -and [string]$hostAnalysisData.Status -eq 'Analyzed')
        HostAnalysisReference = if ($null -ne $hostAnalysisData) { [pscustomobject]@{ Status=$hostAnalysisData.Status; Path='inventory/host/amd-chipset-host-analysis.json' } } else { $null }
        WindowsServerProfiles = @(Get-AmdWindowsServerProfiles)
        ResearchEnvironment = $environmentData
        Releases = $releaseInventory.ToArray()
    }

    Write-AmdJsonFile -Path $OutputJsonPath -Value $inventory -Compress

    $csvRows = New-Object System.Collections.Generic.List[object]

    foreach ($release in $releaseInventory) {
        foreach ($driver in @($release.DriverPackages)) {
            $kmdf = @()
            $umdf = @()

            if ($driver.Wdf) {
                $kmdf = @(Get-AmdCollectionItems -Value $driver.Wdf.KMDF.Versions)
                $umdf = @(Get-AmdCollectionItems -Value $driver.Wdf.UMDF.Versions)
            }

            $csvRows.Add([pscustomobject]@{
                ReleaseVersion = $release.ReleaseVersion
                InfRelativePath = $driver.InfRelativePath
                InfSha256 = $driver.InfSha256
                Provider = if ($driver.VersionSection) { $driver.VersionSection.Provider } else { $null }
                Class = if ($driver.VersionSection) { $driver.VersionSection.Class } else { $null }
                DriverVersion = if ($driver.VersionSection) { $driver.VersionSection.DriverVersion } else { $null }
                DriverDate = if ($driver.VersionSection) { $driver.VersionSection.DriverDate } else { $null }
                KmdfStatus = if ($driver.Wdf) { $driver.Wdf.KMDF.Status } else { 'NotInspected' }
                KmdfVersions = ($kmdf -join ';')
                UmdfStatus = if ($driver.Wdf) { $driver.Wdf.UMDF.Status } else { 'NotInspected' }
                UmdfVersions = ($umdf -join ';')
                HardwareIds = (@(Get-AmdCollectionItems -Value $driver.HardwareIds) -join ';')
            })
        }
    }

    New-AmdDirectory -Path (Split-Path -Parent $OutputCsvPath) | Out-Null

    if ($csvRows.Count -gt 0) {
        $csvRows | Export-Csv -LiteralPath $OutputCsvPath -NoTypeInformation -Encoding UTF8
    }
    else {
        Write-AmdUtf8NoBom -Path $OutputCsvPath -Text ''
    }

    $md = New-Object System.Text.StringBuilder
    [void]$md.AppendLine('# AMD Chipset Driver Research Inventory')
    [void]$md.AppendLine('')
    [void]$md.AppendLine(('Generated: `{0}`' -f $inventory.GeneratedAtUtc))
    [void]$md.AppendLine('')
    [void]$md.AppendLine('This report is derived from the canonical JSON inventory. It records research evidence and does not assert Windows Server compatibility.')
    [void]$md.AppendLine('')
    [void]$md.AppendLine('## Release summary')
    [void]$md.AppendLine('')
    [void]$md.AppendLine('| Release | Metadata | Installer | Extraction | Embedded products | Device maps | INF count | KMDF declarations | UMDF declarations |')
    [void]$md.AppendLine('|---|---|---|---|---:|---:|---:|---:|---:|')

    foreach ($release in $releaseInventory) {
        $metadataStatus = if ($release.Metadata) { [string]$release.Metadata.FetchStatus } else { 'NotInspected' }
        $acquisitionStatus = if ($release.Acquisition) { [string]$release.Acquisition.Status } else { 'NotInspected' }
        $extractionStatus = if ($release.Extraction) { [string]$release.Extraction.Status } else { 'NotInspected' }

        $drivers = @($release.DriverPackages)
        $kmdfCount = @($drivers | Where-Object { $_.Wdf -and $_.Wdf.KMDF.Status -eq 'Declared' }).Count
        $umdfCount = @($drivers | Where-Object { $_.Wdf -and $_.Wdf.UMDF.Status -eq 'Declared' }).Count

        $embeddedProductCount = if ($release.EmbeddedInstallerMetadata) { [int]$release.EmbeddedInstallerMetadata.ProductCount } else { 0 }
        $deviceMapCount = if ($release.EmbeddedInstallerMetadata) { [int]$release.EmbeddedInstallerMetadata.DeviceMappingCount } else { 0 }

        [void]$md.AppendLine(('| {0} | {1} | {2} | {3} | {4} | {5} | {6} | {7} | {8} |' -f
            $release.ReleaseVersion,
            $metadataStatus,
            $acquisitionStatus,
            $extractionStatus,
            $embeddedProductCount,
            $deviceMapCount,
            $drivers.Count,
            $kmdfCount,
            $umdfCount))
    }

    [void]$md.AppendLine('')
    [void]$md.AppendLine('## WDF declarations')
    [void]$md.AppendLine('')
    [void]$md.AppendLine('| Release | INF | Driver version | KMDF | UMDF |')
    [void]$md.AppendLine('|---|---|---|---|---|')

    foreach ($release in $releaseInventory) {
        foreach ($driver in @($release.DriverPackages)) {
            $driverVersion = if ($driver.VersionSection) { [string]$driver.VersionSection.DriverVersion } else { '' }

            $kmdfText = if ($driver.Wdf -and $driver.Wdf.KMDF.Status -eq 'Declared') {
                @(Get-AmdCollectionItems -Value $driver.Wdf.KMDF.Versions) -join ', '
            }
            else {
                if ($driver.Wdf) { [string]$driver.Wdf.KMDF.Status } else { 'NotInspected' }
            }

            $umdfText = if ($driver.Wdf -and $driver.Wdf.UMDF.Status -eq 'Declared') {
                @(Get-AmdCollectionItems -Value $driver.Wdf.UMDF.Versions) -join ', '
            }
            else {
                if ($driver.Wdf) { [string]$driver.Wdf.UMDF.Status } else { 'NotInspected' }
            }

            $infDisplay = ([string]$driver.InfRelativePath).Replace('|', '\|')

            [void]$md.AppendLine(('| {0} | `{1}` | {2} | {3} | {4} |' -f
                $release.ReleaseVersion,
                $infDisplay,
                $driverVersion,
                $kmdfText,
                $umdfText))
        }
    }

    [void]$md.AppendLine('')
    [void]$md.AppendLine('## Interpretation')
    [void]$md.AppendLine('')
    [void]$md.AppendLine('- `Declared` means the INF explicitly contains the corresponding WDF directive.')
    [void]$md.AppendLine('- `NotDeclared` means no corresponding directive was found in that INF; it does not mean the package is compatible with every OS.')
    [void]$md.AppendLine('- Compatibility with Windows Server is intentionally resolved outside this research toolkit.')


    New-AmdDirectory -Path $ReleaseAnalysisRoot | Out-Null
    New-AmdDirectory -Path $ReleaseReportRoot | Out-Null
    $compatRows = New-Object System.Collections.Generic.List[object]
    $serverProfiles = @(Get-AmdWindowsServerProfiles)

    foreach ($release in $releaseInventory) {
        $versionDir = Join-Path $ReleaseAnalysisRoot ([string]$release.ReleaseVersion)
        New-AmdDirectory -Path $versionDir | Out-Null
        $releaseAnalysisPath = Join-Path $versionDir ('amd-chipset-analysis-{0}.json' -f $release.ReleaseVersion)

        $profileSummary = New-Object System.Collections.Generic.List[object]
        foreach ($profile in $serverProfiles) {
            $recordsForProfile = @(
                @($release.DriverPackages) | ForEach-Object {
                    $driver = $_
                    @(Get-AmdCollectionItems -Value $driver.ServerApplicability) | Where-Object { $_.Profile.Id -eq $profile.Id } | ForEach-Object {
                        [pscustomobject]@{ Driver=$driver; Applicability=$_ }
                    }
                }
            )
            $profileSummary.Add([pscustomobject][ordered]@{
                ProfileId = $profile.Id
                Name = $profile.Name
                NativeCandidateInfCount = @($recordsForProfile | Where-Object { $_.Applicability.StaticAssessment -eq 'NativeCandidate' }).Count
                ProjectionCandidateInfCount = @($recordsForProfile | Where-Object { $_.Applicability.StaticAssessment -eq 'ProjectionCandidate' }).Count
                WdfRequirementReviewInfCount = @($recordsForProfile | Where-Object { $_.Applicability.StaticAssessment -eq 'WdfRequirementReview' }).Count
                ReviewRequiredInfCount = @($recordsForProfile | Where-Object { $_.Applicability.StaticAssessment -eq 'ReviewRequired' }).Count
                NotApplicableInfCount = @($recordsForProfile | Where-Object { $_.Applicability.StaticAssessment -eq 'NotApplicable' }).Count
                NativeDeviceCount = @($recordsForProfile | ForEach-Object { @(Get-AmdCollectionItems -Value $_.Applicability.NativeDevices) } | ForEach-Object { $_ }).Count
                ProjectionDeviceCount = @($recordsForProfile | ForEach-Object { @(Get-AmdCollectionItems -Value $_.Applicability.ProjectionDevices) } | ForEach-Object { $_ }).Count
            })
        }

        $portableRelease = ConvertTo-AmdPortableReleaseAnalysisRecord -Release $release
        $releaseAnalysis = [pscustomobject][ordered]@{
            SchemaVersion = $script:AmdChipsetResearchAnalysisSchemaVersion
            ToolkitVersion = $script:AmdChipsetResearchToolkitVersion
            GeneratedAtUtc = Get-AmdUtcTimestamp
            AnalysisSemantics = [pscustomobject][ordered]@{
                SharedInfSemanticContract = $script:AmdInfSemanticContractVersion
                IdentifierTaxonomy = $script:AmdInfIdentifierTaxonomyVersion
                CanonicalUnitKind = 'ReleaseVersion'
                AsPublished = 'Microsoft TargetOSVersion / Models selection semantics applied to the unmodified INF.'
                ServerProjection = 'Analytical projection that changes explicit ProductType=1 decorations to ProductType=3 without modifying the source INF.'
                CompatibilityBoundary = 'Static candidate analysis only. Runtime compatibility, signature acceptance, binary ABI behavior, and actual device installation are not proven.'
                WdfScope = 'INF-wide conservative maximum requirement.'
                RepositoryPortability = 'Machine-local absolute paths are converted to logical paths; extractor console logs remain in the run Evidence bundle rather than the per-release canonical JSON.'
                AmdSelectorBoundary = 'DevID.xml/MSI declarative evidence is preserved separately from host-specific selector emulation and dynamic observation. Host-specific output is not embedded into canonical per-release JSON.'
            }
            Release = [pscustomobject][ordered]@{
                Version = $portableRelease.Version
                Discovery = $portableRelease.Discovery
                Metadata = $portableRelease.Metadata
                Acquisition = $portableRelease.Acquisition
                Extraction = $portableRelease.Extraction
                EmbeddedInstallerMetadata = $portableRelease.EmbeddedInstallerMetadata
                AmdSelectorStatic = $portableRelease.AmdSelectorStatic
            }
            WindowsServerProfiles = $serverProfiles
            Summary = [pscustomobject][ordered]@{
                DriverPackageCount = @($portableRelease.DriverPackages).Count
                ServerProfiles = @($profileSummary.ToArray())
            }
            DriverPackages = @($portableRelease.DriverPackages)
        }
        Write-AmdJsonFile -Path $releaseAnalysisPath -Value $releaseAnalysis -Depth 50 -Compress

        $releaseMd = New-Object System.Text.StringBuilder
        [void]$releaseMd.AppendLine(('# AMD Chipset Software {0} - Windows Server static analysis' -f $release.ReleaseVersion))
        [void]$releaseMd.AppendLine('')
        [void]$releaseMd.AppendLine('> Static INF/WDF analysis only. `NativeCandidate` and `ProjectionCandidate` do not prove runtime compatibility.')
        [void]$releaseMd.AppendLine('')
        [void]$releaseMd.AppendLine('## Release summary')
        [void]$releaseMd.AppendLine('')
        [void]$releaseMd.AppendLine('| Windows Server | Native INF | Projection INF | WDF review | Review | Not applicable | Native devices | Projection devices |')
        [void]$releaseMd.AppendLine('|---|---:|---:|---:|---:|---:|---:|---:|')
        foreach ($ps in $profileSummary.ToArray()) {
            [void]$releaseMd.AppendLine(('| {0} | {1} | {2} | {3} | {4} | {5} | {6} | {7} |' -f $ps.Name,$ps.NativeCandidateInfCount,$ps.ProjectionCandidateInfCount,$ps.WdfRequirementReviewInfCount,$ps.ReviewRequiredInfCount,$ps.NotApplicableInfCount,$ps.NativeDeviceCount,$ps.ProjectionDeviceCount))
        }
        [void]$releaseMd.AppendLine('')
        [void]$releaseMd.AppendLine('## Device-driver details')
        [void]$releaseMd.AppendLine('')

        foreach ($driver in @($release.DriverPackages)) {
            $infName = if ($driver.InfRelativePath) { [string]$driver.InfRelativePath } else { '(parse failed)' }
            [void]$releaseMd.AppendLine(('### `{0}`' -f $infName.Replace('`','')))
            [void]$releaseMd.AppendLine('')
            $driverVersion = if ($driver.VersionSection) { [string]$driver.VersionSection.DriverVersion } else { '' }
            $className = if ($driver.VersionSection) { [string]$driver.VersionSection.Class } else { '' }
            $kmdfText = if ($driver.Wdf -and $driver.Wdf.KMDF.Status -eq 'Declared') { @(Get-AmdCollectionItems -Value $driver.Wdf.KMDF.Versions) -join ', ' } else { 'NotDeclared' }
            $umdfText = if ($driver.Wdf -and $driver.Wdf.UMDF.Status -eq 'Declared') { @(Get-AmdCollectionItems -Value $driver.Wdf.UMDF.Versions) -join ', ' } else { 'NotDeclared' }
            [void]$releaseMd.AppendLine(('- Driver version: `{0}`; Class: `{1}`; KMDF: `{2}`; UMDF: `{3}`' -f $driverVersion,$className,$kmdfText,$umdfText))
            [void]$releaseMd.AppendLine('')
            [void]$releaseMd.AppendLine('| Device | Device identifier | Identifier type | Install section | WS2016 | WS2019 | WS2022 | WS2025 |')
            [void]$releaseMd.AppendLine('|---|---|---|---|---|---|---|---|')

            $deviceMap = @{}
            # Prefer the union of device models that are actually selected by at least
            # one of the four Server profiles (native or projected). This avoids noisy
            # x86-only duplicate rows such as AMDPCI vs AMDPCI64 while preserving the
            # complete topology in the per-release Raw JSON. If no Server profile can
            # select any device from this INF, fall back to amd64/generic model sections
            # so the report can still show why the INF is currently not applicable.
            foreach ($app in @(Get-AmdCollectionItems -Value $driver.ServerApplicability)) {
                foreach ($model in @(Get-AmdCollectionItems -Value $app.NativeDevices) + @(Get-AmdCollectionItems -Value $app.ProjectionDevices)) {
                    $key = ('{0}|{1}|{2}' -f [string]$model.HardwareId,[string]$model.InstallSection,[string]$model.Description).ToUpperInvariant()
                    if (-not $deviceMap.ContainsKey($key)) { $deviceMap[$key] = $model }
                }
            }
            if ($deviceMap.Count -eq 0 -and $driver.InfTopology) {
                foreach ($section in @(Get-AmdCollectionItems -Value $driver.InfTopology.ModelsSections)) {
                    $arch = if ($section.Decoration) { [string]$section.Decoration.Architecture } else { '' }
                    if ($arch -and $arch -ine 'amd64') { continue }
                    foreach ($model in @(Get-AmdCollectionItems -Value $section.Models)) {
                        $key = ('{0}|{1}|{2}' -f [string]$model.HardwareId,[string]$model.InstallSection,[string]$model.Description).ToUpperInvariant()
                        if (-not $deviceMap.ContainsKey($key)) { $deviceMap[$key] = $model }
                    }
                }
            }
            foreach ($model in @($deviceMap.Values | Sort-Object Description, HardwareId)) {
                $cells = @()
                foreach ($profileId in @('windows-server-2016','windows-server-2019','windows-server-2022','windows-server-2025')) {
                    $app = @(Get-AmdCollectionItems -Value $driver.ServerApplicability | Where-Object { $_.Profile.Id -eq $profileId } | Select-Object -First 1)
                    $cell = 'No'
                    if ($app.Count -gt 0) {
                        $nativeMatch = @(Get-AmdCollectionItems -Value $app[0].NativeDevices | Where-Object { $_.HardwareId -ieq $model.HardwareId -and $_.InstallSection -ieq $model.InstallSection }).Count -gt 0
                        $projectionMatch = @(Get-AmdCollectionItems -Value $app[0].ProjectionDevices | Where-Object { $_.HardwareId -ieq $model.HardwareId -and $_.InstallSection -ieq $model.InstallSection }).Count -gt 0
                        if ($nativeMatch) { $cell = 'Native' }
                        elseif ($projectionMatch) { $cell = 'Projection' }
                        elseif ($app[0].AsPublishedStatus -eq 'ExplicitlyExcluded') { $cell = 'Excluded' }
                        elseif ($app[0].AsPublishedStatus -eq 'SuiteDependent') { $cell = 'Review(Suite)' }
                        elseif ($app[0].AsPublishedStatus -eq 'NotApplicableByBuild') { $cell = 'No(Build)' }
                        elseif ($app[0].AsPublishedStatus -eq 'NotApplicableByProductType') { $cell = 'No(ProductType)' }
                    }
                    $cells += $cell
                    $compatRows.Add([pscustomobject][ordered]@{
                        ReleaseVersion=$release.ReleaseVersion; InfRelativePath=$driver.InfRelativePath; DeviceDescription=$model.Description; HardwareId=$model.HardwareId; IdentifierKind=if($null -ne $model.PSObject.Properties['Identifier'] -and $model.Identifier){$model.Identifier.Kind}else{(Get-AmdInfIdentifierInfo -Identifier ([string]$model.HardwareId) -InfClass $className).Kind}; IdentifierType=if($null -ne $model.PSObject.Properties['Identifier'] -and $model.Identifier){$model.Identifier.DisplayName}else{(Get-AmdInfIdentifierInfo -Identifier ([string]$model.HardwareId) -InfClass $className).DisplayName}; CompatibleIds=(@(Get-AmdCollectionItems -Value $model.CompatibleIds)-join ';'); InstallSection=$model.InstallSection
                        ServerProfile=$profileId; AsPublishedStatus=if($app.Count -gt 0){$app[0].AsPublishedStatus}else{'NotAnalyzed'}; ServerProjectionStatus=if($app.Count -gt 0){$app[0].ServerProjectionStatus}else{'NotAnalyzed'}; DeviceSelection=$cell; StaticAssessment=if($app.Count -gt 0){$app[0].StaticAssessment}else{'NotAnalyzed'}
                        KmdfRequired=if($app.Count -gt 0){$app[0].WdfAssessment.KMDF.Required}else{$null}; KmdfAssessment=if($app.Count -gt 0){$app[0].WdfAssessment.KMDF.Status}else{'NotAnalyzed'}; UmdfRequired=if($app.Count -gt 0){$app[0].WdfAssessment.UMDF.Required}else{$null}; UmdfAssessment=if($app.Count -gt 0){$app[0].WdfAssessment.UMDF.Status}else{'NotAnalyzed'}
                    })
                }
                $description = ([string]$model.Description).Replace('|','\|')
                $hwid = ([string]$model.HardwareId).Replace('|','\|')
                $identifierInfo = if ($null -ne $model.PSObject.Properties['Identifier'] -and $model.Identifier) { $model.Identifier } else { Get-AmdInfIdentifierInfo -Identifier ([string]$model.HardwareId) -InfClass $className }
                $identifierType = ([string]$identifierInfo.DisplayName).Replace('|','\|')
                [void]$releaseMd.AppendLine(('| {0} | `{1}` | {2} | `{3}` | {4} | {5} | {6} | {7} |' -f $description,$hwid,$identifierType,$model.InstallSection,$cells[0],$cells[1],$cells[2],$cells[3]))
            }
            if ($deviceMap.Count -eq 0) { [void]$releaseMd.AppendLine('| _(no Models entries parsed)_ | | | | | | | |') }
            [void]$releaseMd.AppendLine('')
        }
        $releaseReportPath = Join-Path $ReleaseReportRoot ('amd-chipset-{0}.md' -f $release.ReleaseVersion)
        Write-AmdUtf8NoBom -Path $releaseReportPath -Text $releaseMd.ToString()
    }

    New-AmdDirectory -Path (Split-Path -Parent $CompatibilityCsvPath) | Out-Null
    if ($compatRows.Count -gt 0) {
        $sortedCompatibilityRows = @($compatRows.ToArray() | Sort-Object @{Expression={ [version]$_.ReleaseVersion }; Descending=$true}, InfRelativePath, DeviceDescription, HardwareId, ServerProfile)
        $sortedCompatibilityRows | Export-Csv -LiteralPath $CompatibilityCsvPath -NoTypeInformation -Encoding UTF8
    }
    else { Write-AmdUtf8NoBom -Path $CompatibilityCsvPath -Text '' }

    $compatMd = New-Object System.Text.StringBuilder
    [void]$compatMd.AppendLine('# AMD Chipset Driver - Windows Server static applicability')
    [void]$compatMd.AppendLine('')
    [void]$compatMd.AppendLine('This report is generated from per-INF semantic analysis. It distinguishes AMD-published applicability from the analytical ProductType=1 -> ProductType=3 server projection used by the deployment project. It does **not** prove runtime compatibility.')
    [void]$compatMd.AppendLine('')
    [void]$compatMd.AppendLine('Releases are listed newest first. The identifier column preserves the exact Models-section identifier from the source INF; `Identifier type` distinguishes bus/root PnP hardware IDs from class-specific IDs and software component IDs.')
    [void]$compatMd.AppendLine('')

    $releaseVersions = @($compatRows.ToArray() | Select-Object -ExpandProperty ReleaseVersion -Unique | Sort-Object { [version]$_ } -Descending)
    foreach ($releaseVersion in $releaseVersions) {
        [void]$compatMd.AppendLine(('## AMD Chipset Software {0}' -f $releaseVersion))
        [void]$compatMd.AppendLine('')
        [void]$compatMd.AppendLine('| INF | Device | Device identifier | Identifier type | Install section | WS2016 | WS2019 | WS2022 | WS2025 | WDF |')
        [void]$compatMd.AppendLine('|---|---|---|---|---|---|---|---|---|---|')

        $releaseRows = @($compatRows.ToArray() | Where-Object { [string]$_.ReleaseVersion -eq [string]$releaseVersion })
        $deviceGroups = @($releaseRows | Group-Object { ('{0}|{1}|{2}|{3}' -f [string]$_.InfRelativePath,[string]$_.DeviceDescription,[string]$_.HardwareId,[string]$_.InstallSection) } | Sort-Object { [string]$_.Group[0].InfRelativePath }, { [string]$_.Group[0].DeviceDescription }, { [string]$_.Group[0].HardwareId })
        foreach ($deviceGroup in $deviceGroups) {
            $groupRows = @($deviceGroup.Group)
            if ($groupRows.Count -eq 0) { continue }
            $first = $groupRows[0]
            $serverCells = @()
            foreach ($profileId in @('windows-server-2016','windows-server-2019','windows-server-2022','windows-server-2025')) {
                $r = @($groupRows | Where-Object { [string]$_.ServerProfile -eq $profileId } | Select-Object -First 1)
                $serverCells += if ($r.Count -gt 0) { [string]$r[0].DeviceSelection } else { 'NotAnalyzed' }
            }
            $wdfParts = @()
            if ($first.KmdfRequired) { $wdfParts += ('KMDF {0}' -f $first.KmdfRequired) }
            if ($first.UmdfRequired) { $wdfParts += ('UMDF {0}' -f $first.UmdfRequired) }
            if ($wdfParts.Count -eq 0) { $wdfParts += 'NotDeclared' }
            $wdfText = $wdfParts -join '; '
            $infText = ([string]$first.InfRelativePath).Replace('`','')
            $deviceText = ([string]$first.DeviceDescription).Replace('|','\|')
            $idText = ([string]$first.HardwareId).Replace('`','').Replace('|','\|')
            $idTypeText = ([string]$first.IdentifierType).Replace('|','\|')
            $installText = ([string]$first.InstallSection).Replace('`','')
            [void]$compatMd.AppendLine(('| `{0}` | {1} | `{2}` | {3} | `{4}` | {5} | {6} | {7} | {8} | {9} |' -f $infText,$deviceText,$idText,$idTypeText,$installText,$serverCells[0],$serverCells[1],$serverCells[2],$serverCells[3],$wdfText))
        }
        [void]$compatMd.AppendLine('')
    }
    Write-AmdUtf8NoBom -Path $CompatibilityMarkdownPath -Text $compatMd.ToString()

    Write-AmdUtf8NoBom -Path $OutputMarkdownPath -Text $md.ToString()

    Write-Host ('Canonical JSON : {0}' -f $OutputJsonPath)
    Write-Host ('Derived CSV    : {0}' -f $OutputCsvPath)
    Write-Host ('Markdown report: {0}' -f $OutputMarkdownPath)
    Write-Host ('Per-release JSON: {0}' -f $ReleaseAnalysisRoot)
    Write-Host ('Per-release reports: {0}' -f $ReleaseReportRoot)
    Write-Host ('Server matrix CSV: {0}' -f $CompatibilityCsvPath)
    Write-Host ('Server matrix MD : {0}' -f $CompatibilityMarkdownPath)
}


function Resolve-AmdRequestedStages {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$RequestedStages
    )

    $allowed = @('Test', 'Discover', 'Metadata', 'Acquire', 'Extract', 'Inspect', 'Selector', 'HostSurvey', 'HostMatch', 'Build', 'All')
    $normalized = @()

    foreach ($item in @($RequestedStages)) {
        if ($null -eq $item) {
            continue
        }

        foreach ($part in ([string]$item -split ',')) {
            $candidate = $part.Trim()
            if (-not $candidate) {
                continue
            }

            $canonical = $allowed | Where-Object { $_ -ieq $candidate } | Select-Object -First 1
            if (-not $canonical) {
                throw ('Invalid stage "{0}". Allowed values: {1}' -f $candidate, ($allowed -join ', '))
            }

            if ($normalized -notcontains $canonical) {
                $normalized += $canonical
            }
        }
    }

    if ($normalized.Count -eq 0 -or $normalized -contains 'All') {
        $full = @('Test', 'Discover', 'Metadata', 'Acquire', 'Extract', 'Inspect', 'Selector')
        $platform = Get-AmdPlatformInfo
        if (-not $script:SkipHostAnalysis -and ($platform.PlatformFamily -eq 'Windows' -or $script:ObservedAmdDeviceIdLog)) {
            $full += @('HostSurvey','HostMatch')
        }
        $full += 'Build'
        return @($full)
    }

    return @($normalized)
}

$resolvedStages = @()
$finalAssessment = $null
$finalExitCode = 1

$invocationEvidence = [pscustomobject][ordered]@{
    Stages = @($Stages)
    ReleaseVersion = @($ReleaseVersion)
    SevenZipPath = $SevenZipPath
    MaxDepth = $MaxDepth
    SitemapUri = @($SitemapUri)
    AdditionalReleaseNotesUrl = @($AdditionalReleaseNotesUrl)
    EvidenceOutputRoot = $EvidenceOutputRoot
    EvidenceLabel = $EvidenceLabel
    PublicOutputRoot = $PublicOutputRoot
    SkipPublicExport = [bool]$SkipPublicExport
    SkipEvidenceArchive = [bool]$SkipEvidenceArchive
    IncludeInstallersInEvidence = [bool]$IncludeInstallersInEvidence
    AllowNonAmdHost = [bool]$AllowNonAmdHost
    SkipHostAnalysis = [bool]$SkipHostAnalysis
    ObservedAmdDeviceIdLog = $ObservedAmdDeviceIdLog
    ObservedAmdMsiLog = $ObservedAmdMsiLog
    ObservedAmdReleaseVersion = $ObservedAmdReleaseVersion
    Force = [bool]$Force
}

try {
    $null = Start-AmdResearchEvidenceSession `
        -OutputRoot $EvidenceOutputRoot `
        -Label $EvidenceLabel `
        -InvocationParameters $invocationEvidence

    Restore-AmdRuntimeBaselineFromPublic
    $resolvedStages = @(Resolve-AmdRequestedStages -RequestedStages $Stages)
    $script:AmdResolvedStageCount = $resolvedStages.Count
    $script:AmdStageOrdinal = 0

    Write-Host '=== AMD Chipset Driver Research Toolkit ==='
    Write-Host ('Toolkit    : {0}' -f $script:AmdChipsetResearchToolkitVersion)
    $startupPlatform = Get-AmdPlatformInfo
    Write-Host ('PowerShell : {0}' -f $PSVersionTable.PSVersion)
    Write-Host ('Platform   : {0} ({1})' -f $startupPlatform.PlatformFamily, $startupPlatform.OSDescription)
    Write-Host ('Stages     : {0}' -f ($resolvedStages -join ', '))
    Write-Host ('Started    : {0}' -f $script:AmdRunStartTime.ToString('yyyy-MM-dd HH:mm:ss'))
    Write-Host ('Root       : {0}' -f $script:AmdChipsetResearchToolkitRoot)
    if ($null -ne $script:AmdEvidenceContext) {
        Write-Host ('Evidence   : {0}' -f $script:AmdEvidenceContext.EvidenceDirectory)
    }
    Write-Host ('Public     : {0}' -f $(if($SkipPublicExport){'SKIPPED'}else{Get-AmdPublicOutputRoot}))
    Write-Host ''

    foreach ($stage in $resolvedStages) {
        $blockedReason = Get-AmdStageDependencyBlockReason -Name $stage -ResolvedStages $resolvedStages
        switch ($stage) {
            'Test' {
                $null = Invoke-AmdTrackedStage -Name 'Test' -BlockedReason $blockedReason -Body {
                    $envResult = Invoke-AmdResearchEnvironmentTest -SevenZipPath $SevenZipPath
                    $envResult | Format-List | Out-Host
                }
            }

            'Discover' {
                $null = Invoke-AmdTrackedStage -Name 'Discover' -BlockedReason $blockedReason -Body {
                    Invoke-AmdDiscoverStage `
                        -SitemapUri $SitemapUri `
                        -AdditionalReleaseNotesUrl $AdditionalReleaseNotesUrl
                }
            }

            'Metadata' {
                $null = Invoke-AmdTrackedStage -Name 'Metadata' -BlockedReason $blockedReason -Body {
                    $stageArgs = @{}
                    if ($Force) { $stageArgs['Force'] = $true }
                    Invoke-AmdMetadataStage @stageArgs
                }
            }

            'Acquire' {
                $null = Invoke-AmdTrackedStage -Name 'Acquire' -BlockedReason $blockedReason -Body {
                    $stageArgs = @{}
                    if ($ReleaseVersion.Count -gt 0) { $stageArgs['ReleaseVersion'] = $ReleaseVersion }
                    if ($Force) { $stageArgs['Force'] = $true }
                    if ($AllowNonAmdHost) { $stageArgs['AllowNonAmdHost'] = $true }
                    Invoke-AmdAcquireStage @stageArgs
                }
            }

            'Extract' {
                $null = Invoke-AmdTrackedStage -Name 'Extract' -BlockedReason $blockedReason -Body {
                    $stageArgs = @{ MaxDepth = $MaxDepth }
                    if ($SevenZipPath) { $stageArgs['SevenZipPath'] = $SevenZipPath }
                    if ($Force) { $stageArgs['Force'] = $true }
                    Invoke-AmdExtractStage @stageArgs
                }
            }

            'Inspect' {
                $null = Invoke-AmdTrackedStage -Name 'Inspect' -BlockedReason $blockedReason -Body {
                    Invoke-AmdInspectStage
                }
            }

            'Selector' {
                $null = Invoke-AmdTrackedStage -Name 'Selector' -BlockedReason $blockedReason -Body {
                    Invoke-AmdSelectorStaticStage
                }
            }

            'HostSurvey' {
                $null = Invoke-AmdTrackedStage -Name 'HostSurvey' -BlockedReason $blockedReason -Body {
                    Invoke-AmdHostSurveyStage -ObservedDeviceIdLog $ObservedAmdDeviceIdLog -ObservedMsiLog $ObservedAmdMsiLog -ObservedReleaseVersion $ObservedAmdReleaseVersion
                }
            }

            'HostMatch' {
                $null = Invoke-AmdTrackedStage -Name 'HostMatch' -BlockedReason $blockedReason -Body {
                    Invoke-AmdHostMatchStage
                }
            }

            'Build' {
                $null = Invoke-AmdTrackedStage -Name 'Build' -BlockedReason $blockedReason -Body {
                    Invoke-AmdBuildStage
                }
            }
        }

        Write-Host ''
    }

    Write-AmdOk 'Research run processing complete; finalizing evidence.'
}
catch {
    $script:AmdTopLevelFatalError = $_.Exception.ToString()
    Write-Warning ('Fatal research runner error: {0}' -f $_.Exception.Message)

    if ($null -ne $script:AmdEvidenceContext) {
        try {
            $fatalPath = Join-Path (Join-Path $script:AmdEvidenceContext.EvidenceDirectory 'errors') 'fatal-runner-error.txt'
            $fatalText = @(
                ('OccurredUtc: {0}' -f (Get-AmdUtcTimestamp)),
                ('Exception  : {0}' -f $_.Exception.ToString()),
                ('ScriptStack: {0}' -f $_.ScriptStackTrace)
            ) -join [Environment]::NewLine
            Write-AmdUtf8NoBom -Path $fatalPath -Text $fatalText
        }
        catch {
            # Preserve the original fatal error.
        }
    }
}
finally {
    try {
        $finalAssessment = Finalize-AmdResearchEvidenceSession `
            -ResolvedStages $resolvedStages `
            -SkipArchive:$SkipEvidenceArchive `
            -IncludeInstallers:$IncludeInstallersInEvidence
        $finalExitCode = [int]$finalAssessment.ExitCode
    }
    catch {
        $finalExitCode = 1
        if (-not $script:AmdTopLevelFatalError) {
            $script:AmdTopLevelFatalError = $_.Exception.ToString()
        }
        Write-Warning ('Evidence finalization failed: {0}' -f $_.Exception.Message)

        if ($script:AmdTranscriptStarted) {
            try { Stop-Transcript | Out-Null } catch { }
            $script:AmdTranscriptStarted = $false
        }
    }

    if ($null -eq $finalAssessment) {
        $finalAssessment = [pscustomobject][ordered]@{
            OverallStatus = 'FatalError'
            ExitCode = 1
            Items = @(
                [pscustomobject]@{
                    Name = 'Runner'
                    Status = 'REVIEW'
                    Detail = if ($script:AmdTopLevelFatalError) { $script:AmdTopLevelFatalError } else { 'Evidence finalization failed.' }
                }
            )
        }
    }

    $finalEvidenceDir = if ($null -ne $script:AmdEvidenceContext) { [string]$script:AmdEvidenceContext.EvidenceDirectory } else { $null }
    $finalZipPath = if ($null -ne $script:AmdEvidenceContext -and -not $SkipEvidenceArchive) { [string]$script:AmdEvidenceContext.ZipPath } else { $null }

    Write-AmdAssessmentConsoleReport `
        -Assessment $finalAssessment `
        -EvidenceDirectory $finalEvidenceDir `
        -ZipPath $finalZipPath
}

exit $finalExitCode
