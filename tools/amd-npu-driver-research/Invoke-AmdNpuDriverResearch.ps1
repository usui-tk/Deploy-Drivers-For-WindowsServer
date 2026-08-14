#requires -Version 5.1
<#
.SYNOPSIS
    Static research and reverse-engineering survey for AMD Ryzen AI NPU driver packages.

.DESCRIPTION
    Research-only tooling for AMD NPU driver packages. The script never executes an AMD
    installer and never modifies vendor payloads. With no arguments, the toolkit performs
    the complete staged workflow: environment/source validation, AMD publication discovery,
    download/cache acquisition, static package analysis, driver-binary contract analysis,
    cross-release comparison, CPU/NPU compatibility matrix generation, deterministic public
    publication, validation, and evidence-archive finalization.

    Local ZIP/EXE/MSI/CAB/7z artifacts remain supported through -PackagePath, but they are an override/qualification
    path rather than the default operating model. Static extraction is performed with the same 7-Zip
    discovery/probe model used by the predecessor AMD research toolkits. Runtime failures are captured as stage evidence;
    the top-level runner finalizes an evidence ZIP even when a stage fails or is blocked.

.NOTES
    Project: Deploy-Drivers-For-WindowsServer
    Tool version: 1.0.0
    Evidence model: Published / Embedded / PayloadObserved / StaticDisassemblyProven / Analysis / ObservedClientRuntime / Runtime
#>
[CmdletBinding()]
param(
    [string[]]$Stages = @('All'),

    [Parameter(Position = 0)]
    [string[]]$PackagePath = @(),

    [string[]]$ArtifactId = @(),

    [ValidateSet('Full', 'Analyze', 'Compare', 'Validate')]
    [string]$Mode,

    [string]$OutputRoot,

    [string]$EvidenceOutputRoot,

    [string]$EvidenceLabel,

    [string]$PublicOutputRoot,

    [Alias('SkipPublic')]
    [switch]$SkipPublicExport,

    [switch]$SkipEvidenceArchive,

    [switch]$IncludePackagesInEvidence,

    [switch]$NoClean,

    [Alias('ForceDownload')]
    [switch]$Force,

    [ValidateRange(1,10)]
    [int]$DownloadRetryCount = 3,

    [ValidateRange(10,3600)]
    [int]$DownloadTimeoutSeconds = 180,

    [string]$SevenZipPath,

    [ValidateRange(0,10)]
    [int]$ExtractionMaxDepth = 5,

    [string[]]$DocumentationUri = @('https://ryzenai.docs.amd.com/en/latest/inst.html'),

    [string[]]$AdditionalDriverUrl = @(),

    [switch]$AllowNonAmdHost
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'
$script:ToolVersion = '1.0.0'
$script:ToolName = 'AMD NPU Driver Research Toolkit'
$script:SourceScriptPath = $PSCommandPath
$script:StartTime = [DateTime]::UtcNow
$script:StageResults = New-Object System.Collections.Generic.List[object]
$script:EvidenceContext = $null
$script:TranscriptStarted = $false
$script:TopLevelFatalError = $null
$script:RunStartTime = Get-Date
$script:ResolvedStageCount = 0
$script:StageOrdinal = 0
$script:CurrentStageName = $null
$script:CurrentStageStart = $null
$script:AmdCurrentStageStart = $null
$script:AmdCurrentStageName = $null
$script:AmdRunStartTime = $script:RunStartTime
$script:ResolvedPublicOutputRoot = $null
$script:ReleaseMetadataDoc = $null
$script:ExtractedPackages = @()
$script:ProfilesDoc = $null
$script:InstallerContractsDoc = $null
$script:DriverContractsDoc = $null
$script:HardwareDoc = $null
$script:ProcessorDoc = $null
$script:CompatibilityDoc = $null
$script:ObservedRuntimeDoc = $null
$script:ArtifactCatalogDoc = $null
$script:ApplicabilityDoc = $null
$script:PredecessorCoreContractDoc = $null
$script:PredecessorExtractionContractDoc = $null
$script:SevenZipInfo = $null
$script:RunInputs = @()
$script:Analyses = @()
$script:Comparisons = @()
$script:CompatibilityMatrix = $null
$script:ProcessorDriverApplicability = $null
$script:PendingPublicRoot = $null
$script:AmdResearchToolkitVersion = $script:ToolVersion
$script:AmdResearchToolkitRoot = $PSScriptRoot
$script:AmdResearchEvidenceSchemaVersion = 'amd-npu-driver-research-evidence/1.2'
$script:AmdResearchStageResultsSchemaVersion = 'amd-npu-driver-research-stage-results/1.1'
$script:AmdResearchEvidencePrefix = 'AmdNpuDriverResearchEvidence'
$script:AmdResearchDisplayName = 'AMD NPU DRIVER RESEARCH'
$script:AmdStageResults = $script:StageResults
$script:AmdEvidenceContext = $null
$script:AmdTranscriptStarted = $false
$script:AmdStageOrdinal = 0
$script:AmdResolvedStageCount = 0
# Windows PowerShell 5.1 requires a deterministic source encoding contract.
# The reviewed root script is UTF-8 with BOM + CRLF; generated public files remain UTF-8 no-BOM/LF.
$script:MarkdownEmDash = [string][char]0x2014
$script:MarkdownRightArrow = [string][char]0x2192


# --- predecessor shared infrastructure core --------------------------------
# The functions in this block are definition-identical (after line-ending normalization)
# in the reviewed chipset and graphics research tools. NPU-specific code reuses the
# same infrastructure rather than maintaining a third independent implementation.
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

function Format-AmdByteSize {
    [CmdletBinding()]
    param([long]$Bytes)

    if ($Bytes -lt 1024) { return ('{0} B' -f $Bytes) }
    if ($Bytes -lt 1MB) { return ('{0:F1} KiB' -f ($Bytes / 1KB)) }
    if ($Bytes -lt 1GB) { return ('{0:F1} MiB' -f ($Bytes / 1MB)) }
    return ('{0:F2} GiB' -f ($Bytes / 1GB))
}

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

function Get-AmdSha256 {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant()
}

function Get-AmdStageElapsedTag {
    [CmdletBinding()]
    param()

    if ($null -eq $script:AmdCurrentStageStart) { return '' }
    return ('[+{0}]' -f (Format-AmdElapsed ((Get-Date) - $script:AmdCurrentStageStart)))
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

function Get-AmdUtcTimestamp {
    [CmdletBinding()]
    param()

    return [DateTime]::UtcNow.ToString('o')
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

function Read-AmdJsonFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    $raw = Read-AmdTextFile -Path $Path
    return ($raw | ConvertFrom-Json)
}

function Read-AmdTextFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    return [System.IO.File]::ReadAllText((Resolve-Path -LiteralPath $Path).Path)
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

function Write-AmdCaution { param([string]$Message) Write-AmdLogLine -Marker '[!]' -Message $Message -Color Yellow }

function Write-AmdDetail {
    [CmdletBinding()]
    param(
        [AllowEmptyString()][string]$Message,
        [ConsoleColor]$Color = [ConsoleColor]::Gray
    )
    Write-Host ('    {0}' -f $Message) -ForegroundColor $Color
}

function Write-AmdFail    { param([string]$Message) Write-AmdLogLine -Marker '[X]' -Message $Message -Color Red }

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

function Write-AmdOk      { param([string]$Message) Write-AmdLogLine -Marker '[+]' -Message $Message -Color Green }

function Write-AmdSkip    { param([string]$Message) Write-AmdLogLine -Marker '[~]' -Message $Message -Color DarkGray }

function Write-AmdStep    { param([string]$Message) Write-AmdLogLine -Marker '[*]' -Message $Message -Color Cyan }

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



# --- predecessor shared infrastructure extensions (extraction/INF) ---------
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

# --- selected predecessor extraction infrastructure ------------------------
# Get-AmdSevenZipInfo uses the hardened Graphics predecessor implementation;
# Get-AmdSevenZipArchiveProbe is the generic 7-Zip container classifier used by
# the Graphics extractor. Their exact source hashes are reviewed separately.
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
            # Native-command exit status can be unavailable after a PowerShell
            # pipeline on some runtimes. Require a recognizable 7-Zip banner;
            # this also rejects wrapper scripts whose inner binary is missing.
            $probeSucceeded = ($versionText -match '(?i)7-Zip')

            if ($probeSucceeded) {
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

function Get-AmdSevenZipArchiveProbe {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$SevenZipPath,
        [Parameter(Mandatory = $true)][string]$Path
    )

    $output = @()
    $exitCode = $null
    try {
        $output = @(& $SevenZipPath 'l' '-slt' $Path 2>&1 | ForEach-Object { [string]$_ })
        $exitCode = $LASTEXITCODE
    }
    catch {
        return [pscustomobject][ordered]@{
            ProbeSucceeded = $false; ExitCode = $null; ArchiveType = $null; Offset = $null
            PhysicalSize = $null; TailSize = $null; ContainerLike = $false; Error = $_.Exception.Message
        }
    }

    $type = $null; $offset = $null; $physical = $null; $tail = $null
    foreach ($line in $output) {
        if (-not $type -and $line -match '^Type\s*=\s*(.+?)\s*$') { $type = $Matches[1].Trim(); continue }
        if ($null -eq $offset -and $line -match '^Offset\s*=\s*(\d+)\s*$') { $offset = [int64]$Matches[1]; continue }
        if ($null -eq $physical -and $line -match '^Physical Size\s*=\s*(\d+)\s*$') { $physical = [int64]$Matches[1]; continue }
        if ($null -eq $tail -and $line -match '^Tail Size\s*=\s*(\d+)\s*$') { $tail = [int64]$Matches[1]; continue }
    }

    $nonContainerTypes = @('PE','ELF','Mach-O','COFF')
    $containerLike = ($exitCode -in @(0,1) -and $type -and $nonContainerTypes -notcontains $type)
    return [pscustomobject][ordered]@{
        ProbeSucceeded = ($exitCode -in @(0,1) -and [bool]$type)
        ExitCode = $exitCode
        ArchiveType = $type
        Offset = $offset
        PhysicalSize = $physical
        TailSize = $tail
        ContainerLike = $containerLike
        Error = if ($exitCode -in @(0,1)) { $null } else { ('7-Zip list probe exit code {0}' -f $exitCode) }
    }
}

# --- NPU-specific compatibility wrappers -----------------------------------
function New-Utf8NoBomEncoding {
    return New-Object System.Text.UTF8Encoding($false)
}

function Write-Utf8NoBomLf {
    param([Parameter(Mandatory=$true)][string]$Path, [AllowEmptyString()][string]$Text)
    $parent = Split-Path -Parent $Path
    if ($parent -and -not (Test-Path -LiteralPath $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }
    if ($null -eq $Text) { $Text = '' }
    $normalized = $Text -replace "`r`n", "`n" -replace "`r", "`n"
    [System.IO.File]::WriteAllText($Path, $normalized, (New-Utf8NoBomEncoding))
}

function ConvertTo-AmdCanonicalJsonString {
    [CmdletBinding()]
    param([AllowNull()][string]$Value)
    if ($null -eq $Value) { return 'null' }
    $sb = New-Object System.Text.StringBuilder
    [void]$sb.Append('"')
    foreach ($ch in $Value.ToCharArray()) {
        $code = [int][char]$ch
        if ($code -eq 8)  { [void]$sb.Append('\b'); continue }
        if ($code -eq 9)  { [void]$sb.Append('\t'); continue }
        if ($code -eq 10) { [void]$sb.Append('\n'); continue }
        if ($code -eq 12) { [void]$sb.Append('\f'); continue }
        if ($code -eq 13) { [void]$sb.Append('\r'); continue }
        if ($code -eq 34) { [void]$sb.Append('\"'); continue }
        if ($code -eq 92) { [void]$sb.Append('\\'); continue }
        if ($code -lt 32) { [void]$sb.Append(('\u{0:x4}' -f $code)) }
        else { [void]$sb.Append($ch) }
    }
    [void]$sb.Append('"')
    return $sb.ToString()
}

function Get-AmdOrdinalSortedUniqueStrings {
    [CmdletBinding()]
    param([AllowNull()][object[]]$Values)
    $set = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::Ordinal)
    foreach ($value in @($Values)) {
        if ($null -eq $value) { continue }
        [void]$set.Add([string]$value)
    }
    $array = [string[]]@($set)
    [System.Array]::Sort($array, [System.StringComparer]::Ordinal)
    return @($array)
}

function Get-AmdOrdinalSortedObjectsByStringProperty {
    [CmdletBinding()]
    param([AllowNull()][object[]]$Values,[Parameter(Mandatory=$true)][string]$PropertyName)
    $map = @{}
    foreach ($value in @($Values)) {
        if ($null -eq $value) { continue }
        $key = $null
        if ($value -is [System.Collections.IDictionary] -and $value.Contains($PropertyName)) {
            $key = [string]$value[$PropertyName]
        }
        else {
            $prop = $value.PSObject.Properties[$PropertyName]
            if ($null -ne $prop) { $key = [string]$prop.Value }
        }
        if ($null -eq $key) { throw ('Property {0} is missing from an object selected for ordinal sorting.' -f $PropertyName) }
        if ($map.ContainsKey($key)) { throw ('Duplicate ordinal sort key for {0}: {1}' -f $PropertyName, $key) }
        $map[$key] = $value
    }
    $ordered = New-Object 'System.Collections.Generic.List[object]'
    foreach ($key in @(Get-AmdOrdinalSortedUniqueStrings -Values @($map.Keys))) {
        $ordered.Add($map[$key]) | Out-Null
    }
    return @($ordered.ToArray())
}

function ConvertTo-AmdCanonicalJsonText {
    [CmdletBinding()]
    param([AllowNull()][object]$Value,[ValidateRange(1,100)][int]$Depth=30,[int]$Level=0)
    if ($Level -gt $Depth) { throw ('Canonical JSON depth exceeded the configured limit ({0}).' -f $Depth) }
    if ($null -eq $Value) { return 'null' }
    if ($Value -is [string] -or $Value -is [char] -or $Value -is [System.Uri] -or $Value -is [System.Guid] -or $Value -is [System.Version]) {
        return (ConvertTo-AmdCanonicalJsonString -Value ([string]$Value))
    }
    if ($Value -is [bool]) { if ([bool]$Value) { return 'true' } else { return 'false' } }
    if ($Value -is [datetime]) { return (ConvertTo-AmdCanonicalJsonString -Value $Value.ToString('o',[Globalization.CultureInfo]::InvariantCulture)) }
    if ($Value -is [datetimeoffset]) { return (ConvertTo-AmdCanonicalJsonString -Value $Value.ToString('o',[Globalization.CultureInfo]::InvariantCulture)) }
    if ($Value -is [double]) {
        if ([double]::IsNaN($Value) -or [double]::IsInfinity($Value)) { throw 'Non-finite Double cannot be encoded as canonical JSON.' }
        return $Value.ToString('R',[Globalization.CultureInfo]::InvariantCulture)
    }
    if ($Value -is [single]) {
        if ([single]::IsNaN($Value) -or [single]::IsInfinity($Value)) { throw 'Non-finite Single cannot be encoded as canonical JSON.' }
        return $Value.ToString('R',[Globalization.CultureInfo]::InvariantCulture)
    }
    if ($Value -is [decimal] -or $Value -is [byte] -or $Value -is [sbyte] -or $Value -is [int16] -or $Value -is [uint16] -or $Value -is [int32] -or $Value -is [uint32] -or $Value -is [int64] -or $Value -is [uint64]) {
        return $Value.ToString([Globalization.CultureInfo]::InvariantCulture)
    }
    if ($Value.GetType().IsEnum) { return $Value.ToString() }
    if ($Value -is [System.Collections.IDictionary]) {
        $keys=@($Value.Keys)
        if (-not ($Value -is [System.Collections.Specialized.OrderedDictionary])) {
            $keys=@(Get-AmdOrdinalSortedUniqueStrings -Values @($keys|ForEach-Object{[string]$_}))
        }
        $parts=New-Object 'System.Collections.Generic.List[string]'
        foreach($keyObject in @($keys)) {
            $parts.Add((ConvertTo-AmdCanonicalJsonString -Value ([string]$keyObject))+':'+(ConvertTo-AmdCanonicalJsonText -Value $Value[$keyObject] -Depth $Depth -Level ($Level+1)))|Out-Null
        }
        return '{'+($parts.ToArray()-join ',')+'}'
    }
    if (($Value -is [System.Collections.IEnumerable]) -and -not ($Value -is [string])) {
        $parts=New-Object 'System.Collections.Generic.List[string]'
        foreach($item in $Value){$parts.Add((ConvertTo-AmdCanonicalJsonText -Value $item -Depth $Depth -Level ($Level+1)))|Out-Null}
        return '['+($parts.ToArray()-join ',')+']'
    }
    $props=@($Value.PSObject.Properties|Where-Object{$_.MemberType -in @('NoteProperty','Property','AliasProperty','ScriptProperty')})
    if($props.Count -gt 0){
        $parts=New-Object 'System.Collections.Generic.List[string]'
        foreach($prop in $props){$parts.Add((ConvertTo-AmdCanonicalJsonString -Value ([string]$prop.Name))+':'+(ConvertTo-AmdCanonicalJsonText -Value $prop.Value -Depth $Depth -Level ($Level+1)))|Out-Null}
        return '{'+($parts.ToArray()-join ',')+'}'
    }
    return (ConvertTo-AmdCanonicalJsonString -Value ([string]$Value))
}

function Write-JsonFile {
    param([Parameter(Mandatory=$true)]$Value,[Parameter(Mandatory=$true)][string]$Path,[switch]$Compress)
    $json=ConvertTo-AmdCanonicalJsonText -Value $Value -Depth 30
    Write-Utf8NoBomLf -Path $Path -Text ($json+"`n")
}

function Get-Sha256 {
    param([Parameter(Mandatory=$true)][string]$Path)
    return (Get-AmdSha256 -Path $Path)
}

function Get-RelativePathCompat {
    param([Parameter(Mandatory=$true)][string]$BasePath, [Parameter(Mandatory=$true)][string]$TargetPath)
    return (Get-AmdRelativePath -BasePath $BasePath -Path $TargetPath)
}

function Add-StageResult {
    param([string]$Name, [string]$Status, [string]$Message, [DateTime]$Started)
    $script:StageResults.Add([ordered]@{
        Name = $Name
        Status = $Status
        Message = $Message
        ElapsedSeconds = [Math]::Round(([DateTime]::UtcNow - $Started).TotalSeconds, 3)
    }) | Out-Null
}

function Write-ProgressLine {
    param([string]$Kind, [string]$Message)
    $elapsed = [DateTime]::UtcNow - $script:StartTime
    $prefix = switch ($Kind) {
        'PASS' { '[+]' }
        'WARN' { '[!]' }
        'FAIL' { '[-]' }
        default { '[*]' }
    }
    Write-Host ('[{0:HH:mm:ss}] {1} {2} (elapsed {3:hh\:mm\:ss})' -f [DateTime]::Now, $prefix, $Message, $elapsed)
}

function Get-ReviewedJsonDocument {
    param([Parameter(Mandatory=$true)][string]$Path)
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { throw "Reviewed data file missing: $Path" }
    try { return (Read-AmdJsonFile -Path $Path) }
    catch { throw "Reviewed data file is invalid UTF-8 JSON: $Path : $($_.Exception.Message)" }
}

function Get-NpuReviewedSourceDataContracts {
    [CmdletBinding()]
    param()
    return @(
        [pscustomobject][ordered]@{FileName='architecture-convergence-contract.json';SchemaVersion='amd-npu-architecture-convergence-contract/1.0';SchemaRelativePath='schemas/source-data/architecture-convergence-contract.source.schema.json'}
        [pscustomobject][ordered]@{FileName='driver-compatibility-rules.json';SchemaVersion='1.0';SchemaRelativePath='schemas/source-data/driver-compatibility-rules.source.schema.json'}
        [pscustomobject][ordered]@{FileName='hardware-identities.json';SchemaVersion='1.1';SchemaRelativePath='schemas/source-data/hardware-identities.source.schema.json'}
        [pscustomobject][ordered]@{FileName='known-driver-binary-contracts.json';SchemaVersion='1.0';SchemaRelativePath='schemas/source-data/known-driver-binary-contracts.source.schema.json'}
        [pscustomobject][ordered]@{FileName='known-installer-contracts.json';SchemaVersion='1.0';SchemaRelativePath='schemas/source-data/known-installer-contracts.source.schema.json'}
        [pscustomobject][ordered]@{FileName='observed-runtime-evidence.json';SchemaVersion='1.0';SchemaRelativePath='schemas/source-data/observed-runtime-evidence.source.schema.json'}
        [pscustomobject][ordered]@{FileName='predecessor-extraction-core-contract.json';SchemaVersion='amd-npu-predecessor-extraction-core-contract/1.0';SchemaRelativePath='schemas/source-data/predecessor-extraction-core-contract.source.schema.json'}
        [pscustomobject][ordered]@{FileName='predecessor-shared-core-contract.json';SchemaVersion='amd-research-predecessor-shared-core-contract/1.0';SchemaRelativePath='schemas/source-data/predecessor-shared-core-contract.source.schema.json'}
        [pscustomobject][ordered]@{FileName='processor-catalog.json';SchemaVersion='1.3';SchemaRelativePath='schemas/source-data/processor-catalog.source.schema.json'}
        [pscustomobject][ordered]@{FileName='processor-driver-applicability.json';SchemaVersion='1.0';SchemaRelativePath='schemas/source-data/processor-driver-applicability.source.schema.json'}
        [pscustomobject][ordered]@{FileName='published-driver-artifacts.json';SchemaVersion='amd-npu-published-driver-artifacts/1.1';SchemaRelativePath='schemas/source-data/published-driver-artifacts.source.schema.json'}
        [pscustomobject][ordered]@{FileName='windows-server-profiles.json';SchemaVersion='1.0';SchemaRelativePath='schemas/source-data/windows-server-profiles.source.schema.json'}
    )
}

function Test-NpuReviewedSourceDataContracts {
    [CmdletBinding()]
    param()
    $issues=New-Object 'System.Collections.Generic.List[string]'
    $contracts=@(Get-NpuReviewedSourceDataContracts)
    $registered=@{}
    foreach($contract in $contracts){
        $name=[string]$contract.FileName
        if($registered.ContainsKey($name)){$issues.Add(('Duplicate reviewed source-data contract: {0}' -f $name))|Out-Null;continue}
        $registered[$name]=$true
        $dataPath=Join-Path (Join-Path $PSScriptRoot 'data') $name
        $schemaPath=Join-Path $PSScriptRoot ([string]$contract.SchemaRelativePath)
        if(-not(Test-Path -LiteralPath $dataPath -PathType Leaf)){$issues.Add(('Reviewed source-data file missing: {0}' -f $name))|Out-Null;continue}
        if(-not(Test-Path -LiteralPath $schemaPath -PathType Leaf)){$issues.Add(('Reviewed source-data schema missing: {0}' -f [string]$contract.SchemaRelativePath))|Out-Null;continue}
        try{$doc=Get-ReviewedJsonDocument -Path $dataPath}catch{$issues.Add($_.Exception.Message)|Out-Null;continue}
        $actualVersion=[string]$doc.schemaVersion
        if($actualVersion -ne [string]$contract.SchemaVersion){$issues.Add(('Reviewed source-data schemaVersion mismatch: {0}; expected={1}; actual={2}' -f $name,[string]$contract.SchemaVersion,$actualVersion))|Out-Null}
        try{$schema=Get-ReviewedJsonDocument -Path $schemaPath}catch{$issues.Add($_.Exception.Message)|Out-Null;continue}
        $schemaVersionProperty=$null
        if($schema.PSObject.Properties['properties'] -and $schema.properties.PSObject.Properties['schemaVersion']){$schemaVersionProperty=$schema.properties.schemaVersion}
        if($null -eq $schemaVersionProperty -or -not $schemaVersionProperty.PSObject.Properties['const'] -or [string]$schemaVersionProperty.const -ne [string]$contract.SchemaVersion){
            $issues.Add(('Reviewed source-data schema does not guard schemaVersion {0}: {1}' -f [string]$contract.SchemaVersion,[string]$contract.SchemaRelativePath))|Out-Null
        }
        if(-not $schema.PSObject.Properties['required'] -or @($schema.required) -notcontains 'schemaVersion'){$issues.Add(('Reviewed source-data schema must require schemaVersion: {0}' -f [string]$contract.SchemaRelativePath))|Out-Null}
    }
    foreach($file in @(Get-ChildItem -LiteralPath (Join-Path $PSScriptRoot 'data') -Filter '*.json' -File -ErrorAction Stop)){
        if(-not $registered.ContainsKey([string]$file.Name)){$issues.Add(('Reviewed source-data JSON has no registered schema/version contract: {0}' -f [string]$file.Name))|Out-Null}
    }
    return @($issues.ToArray())
}

function Test-NpuToolVersionConsistency {
    [CmdletBinding()]
    param()
    $issues=New-Object 'System.Collections.Generic.List[string]'
    if([string]::IsNullOrWhiteSpace([string]$script:SourceScriptPath) -or -not(Test-Path -LiteralPath $script:SourceScriptPath -PathType Leaf)){
        $issues.Add('Cannot verify tool version consistency because the source script path is unavailable.')|Out-Null
        return @($issues.ToArray())
    }
    try{$sourceText=Get-Content -LiteralPath $script:SourceScriptPath -Raw -ErrorAction Stop}catch{
        $issues.Add(('Cannot read source script for tool version consistency: {0}' -f $_.Exception.Message))|Out-Null
        return @($issues.ToArray())
    }
    $matches=[regex]::Matches($sourceText,'(?m)^\s*Tool version:\s*([^\r\n]+?)\s*$')
    if($matches.Count -ne 1){
        $issues.Add(('Expected exactly one .NOTES Tool version declaration; found={0}' -f $matches.Count))|Out-Null
        return @($issues.ToArray())
    }
    $declared=[string]$matches[0].Groups[1].Value.Trim()
    if($declared -ne [string]$script:ToolVersion){
        $issues.Add(('Tool version mismatch: .NOTES={0}; runtime={1}' -f $declared,[string]$script:ToolVersion))|Out-Null
    }
    return @($issues.ToArray())
}

function Get-DeviceIdFromHardwareId {
    param([AllowNull()][string]$HardwareId)
    if ($HardwareId -and $HardwareId -match '(?i)DEV_([0-9A-F]{4})') { return $matches[1].ToUpperInvariant() }
    return $null
}

function Test-ReviewedResearchData {
    param(
        [Parameter(Mandatory=$true)]$HardwareDoc,
        [Parameter(Mandatory=$true)]$ProcessorDoc,
        [Parameter(Mandatory=$true)]$CompatibilityDoc
    )
    $issues = New-Object System.Collections.Generic.List[string]
    $identityIds = @{}
    foreach ($identity in @($HardwareDoc.identities)) {
        if ([string]::IsNullOrWhiteSpace([string]$identity.identityId)) { $issues.Add('Hardware identity missing identityId.') | Out-Null; continue }
        if ($identityIds.ContainsKey([string]$identity.identityId)) { $issues.Add("Duplicate hardware identity: $($identity.identityId)") | Out-Null }
        $identityIds[[string]$identity.identityId] = $true
        if ([string]$identity.vendorId -ne '1022') { $issues.Add("Unexpected vendor ID for $($identity.identityId): $($identity.vendorId)") | Out-Null }
        if ([string]::IsNullOrWhiteSpace([string]$identity.deviceId)) { $issues.Add("Hardware identity missing deviceId: $($identity.identityId)") | Out-Null }
    }
    $processorIds = @{}
    foreach ($processor in @($ProcessorDoc.processors)) {
        if ([string]::IsNullOrWhiteSpace([string]$processor.processorId)) { $issues.Add('Processor entry missing processorId.') | Out-Null; continue }
        if ($processorIds.ContainsKey([string]$processor.processorId)) { $issues.Add("Duplicate processorId: $($processor.processorId)") | Out-Null }
        $processorIds[[string]$processor.processorId] = $true
        $availability = [string]$processor.npuAvailability
        if (@('AvailablePublished','NotAvailablePublished','NoPublishedNpuCapability','Unknown') -notcontains $availability) { $issues.Add("Invalid npuAvailability: $($processor.processorId) -> $availability") | Out-Null }
        $identityRef = [string]$processor.npuIdentityId
        if (-not [string]::IsNullOrWhiteSpace($identityRef) -and -not $identityIds.ContainsKey($identityRef)) { $issues.Add("Processor references unknown npuIdentityId: $($processor.processorId) -> $identityRef") | Out-Null }
        if ([string]::IsNullOrWhiteSpace($identityRef) -and @($processor.expectedDeviceIds).Count -gt 0) { $issues.Add("Processor has expectedDeviceIds without a resolved npuIdentityId: $($processor.processorId)") | Out-Null }
        if ($availability -ne 'AvailablePublished' -and (-not [string]::IsNullOrWhiteSpace($identityRef) -or @($processor.expectedDeviceIds).Count -gt 0)) { $issues.Add("Processor without published NPU capability must not carry an NPU identity: $($processor.processorId)") | Out-Null }
        try { [void](New-Object System.Text.RegularExpressions.Regex([string]$processor.matchRegex, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)) }
        catch { $issues.Add("Invalid processor regex: $($processor.processorId): $($_.Exception.Message)") | Out-Null }
    }
    $artifactHashes = @{}
    foreach ($rule in @($CompatibilityDoc.artifactRules)) {
        $hash = [string]$rule.artifactSha256
        if ($hash -notmatch '^[0-9a-f]{64}$') { $issues.Add("Invalid artifact rule SHA-256: $hash") | Out-Null; continue }
        if ($artifactHashes.ContainsKey($hash)) { $issues.Add("Duplicate artifact compatibility rule: $hash") | Out-Null }
        $artifactHashes[$hash] = $true
    }
    foreach ($runtime in @($CompatibilityDoc.ryzenAiSoftwareMinimumDrivers)) {
        try { [void]([version][string]$runtime.minimumDriver) }
        catch { $issues.Add("Invalid minimum driver version: $($runtime.softwareVersion) -> $($runtime.minimumDriver)") | Out-Null }
    }
    return $issues.ToArray()
}

function Test-ProcessorDriverApplicabilityResearchData {
    param(
        [Parameter(Mandatory=$true)]$ApplicabilityDoc,
        [Parameter(Mandatory=$true)]$ArtifactCatalogDoc
    )
    $issues = New-Object System.Collections.Generic.List[string]
    if ([string]$ApplicabilityDoc.schemaVersion -ne '1.0') { $issues.Add('Unexpected processor-driver-applicability schemaVersion.') | Out-Null }
    if ([string]$ApplicabilityDoc.unknownProcessorPolicy -ne 'ReviewRequired') { $issues.Add('processor-driver-applicability unknownProcessorPolicy must be ReviewRequired.') | Out-Null }
    if ([string]$ApplicabilityDoc.unknownHardwarePolicy -ne 'ReviewRequired') { $issues.Add('processor-driver-applicability unknownHardwarePolicy must be ReviewRequired.') | Out-Null }
    if (-not [bool]$ApplicabilityDoc.recommendationPolicy.publiclyObtainableArtifactsOnly) { $issues.Add('Applicability policy must require publicly obtainable recommendation artifacts.') | Out-Null }
    if (-not [bool]$ApplicabilityDoc.recommendationPolicy.privateQualificationArtifactsNeverRecommended) { $issues.Add('Applicability policy must prohibit recommendation of private qualification artifacts.') | Out-Null }
    if (-not [bool]$ApplicabilityDoc.recommendationPolicy.seriesNameOnlyInferenceProhibited) { $issues.Add('Applicability policy must prohibit series-name-only NPU inference.') | Out-Null }

    $publicHashes = @{}
    foreach ($artifact in @($ArtifactCatalogDoc.artifacts)) {
        $hash = ([string]$artifact.expectedSha256).ToLowerInvariant()
        if ($hash -match '^[0-9a-f]{64}$') { $publicHashes[$hash] = $true }
    }
    $privateHashes = @{}
    foreach ($artifact in @($ApplicabilityDoc.privateQualificationArtifacts)) {
        $hash = ([string]$artifact.sha256).ToLowerInvariant()
        if ($hash -notmatch '^[0-9a-f]{64}$') { $issues.Add("Invalid private qualification SHA-256: $hash") | Out-Null; continue }
        if ($privateHashes.ContainsKey($hash)) { $issues.Add("Duplicate private qualification artifact SHA-256: $hash") | Out-Null }
        $privateHashes[$hash] = $true
        if ($publicHashes.ContainsKey($hash)) { $issues.Add("Private qualification artifact must not duplicate a public acquisition artifact: $hash") | Out-Null }
        if ([bool]$artifact.recommendationEligible) { $issues.Add("Private qualification artifact must never be recommendationEligible: $($artifact.artifactId)") | Out-Null }
        if ([string]$artifact.acquisitionPolicy -ne 'ManualPrivateOnly') { $issues.Add("Private qualification artifact must use ManualPrivateOnly acquisition policy: $($artifact.artifactId)") | Out-Null }
        if (@($artifact.broadInfDeviceIds).Count -eq 0) { $issues.Add("Private qualification artifact missing broadInfDeviceIds: $($artifact.artifactId)") | Out-Null }
        foreach ($deviceId in @($artifact.broadInfDeviceIds)) {
            if ([string]$deviceId -notmatch '^[0-9A-Fa-f]{4}$') { $issues.Add("Invalid private qualification device ID: $($artifact.artifactId) -> $deviceId") | Out-Null }
        }
    }
    return $issues.ToArray()
}

function Test-ObservedRuntimeEvidence {
    param(
        [Parameter(Mandatory=$true)]$ObservedRuntimeDoc,
        [Parameter(Mandatory=$true)]$ProcessorDoc,
        [Parameter(Mandatory=$true)]$HardwareDoc
    )
    $issues = New-Object System.Collections.Generic.List[string]
    $processorIds = @{}
    foreach ($p in @($ProcessorDoc.processors)) { $processorIds[[string]$p.processorId] = $true }
    $identityIds = @{}
    foreach ($i in @($HardwareDoc.identities)) { $identityIds[[string]$i.identityId] = $true }
    $evidenceIds = @{}
    foreach ($record in @($ObservedRuntimeDoc.records)) {
        $eid=[string]$record.evidenceId
        if ([string]::IsNullOrWhiteSpace($eid)) { $issues.Add('Observed runtime record missing evidenceId.')|Out-Null; continue }
        if ($evidenceIds.ContainsKey($eid)) { $issues.Add("Duplicate observed runtime evidenceId: $eid")|Out-Null }
        $evidenceIds[$eid]=$true
        if (-not $processorIds.ContainsKey([string]$record.processorId)) { $issues.Add("Observed runtime record references unknown processorId: $($record.processorId)")|Out-Null }
        if ([bool]$record.serverRuntimeProof) { $issues.Add("Observed client runtime evidence must not claim Windows Server runtime proof: $eid")|Out-Null }
        if ([string]$record.npuIdentity.vendorId -ne '1022') { $issues.Add("Observed NPU vendor must be 1022: $eid")|Out-Null }
        $resolvedIdentity = [string]$record.conclusion.resolvedNpuIdentityId
        if (-not [string]::IsNullOrWhiteSpace($resolvedIdentity) -and -not $identityIds.ContainsKey($resolvedIdentity)) { $issues.Add("Observed runtime conclusion references unknown NPU identity: $eid -> $resolvedIdentity")|Out-Null }
        $artifactHash=[string]$record.runtimeDriver.reviewedArtifactSha256
        if ($artifactHash -notmatch '^[0-9a-f]{64}$') { $issues.Add("Observed runtime artifact SHA-256 invalid: $eid")|Out-Null }
        foreach($hashName in @('infSha256','ipustackSha256','xrtSmiSha256')) {
            $hash=[string]$record.runtimeDriver.$hashName
            if ($hash -notmatch '^[0-9a-f]{64}$') { $issues.Add("Observed runtime $hashName invalid: $eid")|Out-Null }
        }
    }
    foreach ($processor in @($ProcessorDoc.processors)) {
        foreach ($eid in $(if($processor.PSObject.Properties['observedEvidenceIds']){@($processor.observedEvidenceIds)}else{@()})) {
            if (-not $evidenceIds.ContainsKey([string]$eid)) { $issues.Add("Processor references unknown observedEvidenceId: $($processor.processorId) -> $eid")|Out-Null }
        }
    }
    return $issues.ToArray()
}

function Get-ObservedRuntimeEvidenceForProcessor {
    param([Parameter(Mandatory=$true)][string]$ProcessorId,[Parameter(Mandatory=$true)]$ObservedRuntimeDoc)
    return @($ObservedRuntimeDoc.records | Where-Object { [string]$_.processorId -eq $ProcessorId })
}

function Get-ObservedRuntimePublicDocument {
    param([Parameter(Mandatory=$true)]$ObservedRuntimeDoc)
    return [ordered]@{
        SchemaVersion='1.0';ToolVersion=$script:ToolVersion;HandEdited=$false
        ReviewedAt=[string]$ObservedRuntimeDoc.reviewedAt
        PublicationBoundary=[string]$ObservedRuntimeDoc.publicationBoundary
        Sources=@($ObservedRuntimeDoc.sources)
        Records=@($ObservedRuntimeDoc.records)
    }
}

function Convert-ObservedRuntimeEvidenceToMarkdown {
    param([Parameter(Mandatory=$true)]$Document)
    $sb=New-Object System.Text.StringBuilder
    [void]$sb.AppendLine('# AMD NPU Reviewed Observed Runtime Evidence')
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine('- Raw collector archives, transcripts, and INF snapshots remain private runtime evidence and are not committed.')
    [void]$sb.AppendLine('- These records contain generalized reviewed facts only. Client runtime evidence does not prove Windows Server runtime applicability.')
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine('| Processor | NPU identity | PCI REV | XRT device | Firmware | Reviewed artifact | Exact runtime stack | Server runtime proof |')
    [void]$sb.AppendLine('|---|---|---|---|---|---|---|---|')
    foreach($r in @($Document.Records)) {
        [void]$sb.AppendLine("| $($r.processorName) | ``$($r.npuIdentity.vendorId):$($r.npuIdentity.deviceId)`` | ``$($r.npuIdentity.pciRevision)`` | $($r.npuIdentity.xrtDeviceName) | ``$($r.npuIdentity.xrtFirmwareVersion)`` | ``$($r.runtimeDriver.reviewedArtifactFileName)`` | $($r.runtimeDriver.fullObservedStackExactMatch) | $($r.serverRuntimeProof) |")
    }
    return $sb.ToString()
}

function Test-DriverBinaryContracts {
    param([Parameter(Mandatory=$true)]$Contracts)
    $issues = New-Object System.Collections.Generic.List[string]
    $hashes = @{}
    foreach ($contract in @($Contracts)) {
        $hash = [string]$contract.sha256
        if ($hash -notmatch '^[0-9a-f]{64}$') { $issues.Add("Invalid driver-binary contract SHA-256: $hash") | Out-Null; continue }
        if ($hashes.ContainsKey($hash)) { $issues.Add("Duplicate driver-binary contract SHA-256: $hash") | Out-Null }
        $hashes[$hash] = $true
        if ([string]$contract.artifactName -ne 'ipustack.sys') { $issues.Add("Unexpected driver-binary contract artifact name: $($contract.artifactName)") | Out-Null }
        if ([string]::IsNullOrWhiteSpace([string]$contract.identitySemanticId)) { $issues.Add("Driver-binary contract missing identitySemanticId: $hash") | Out-Null }
        if ([bool]$contract.firmwareDeviceRevision.refinementObserved) {
            if ([string]$contract.firmwareDeviceRevision.messageOpcode -ne '0x117') { $issues.Add("Refined driver contract must bind message opcode 0x117: $hash") | Out-Null }
            if ([int]$contract.firmwareDeviceRevision.defaultUnknownValue -ne 9) { $issues.Add("Refined driver contract must preserve unknown revision 9: $hash") | Out-Null }
            $values = @($contract.firmwareDeviceRevision.map | ForEach-Object {[int]$_.value} | Sort-Object -Unique)
            if (($values -join ',') -ne '1,2,3,4,5,6,7,8') { $issues.Add("Refined driver contract revision map must contain values 1..8 exactly: $hash") | Out-Null }
        }
    }
    return $issues.ToArray()
}

function Get-ArtifactCompatibilityRule {
    param([Parameter(Mandatory=$true)][string]$ArtifactSha256, [Parameter(Mandatory=$true)]$Rules)
    foreach ($rule in @($Rules)) {
        if ([string]$rule.artifactSha256 -eq $ArtifactSha256) { return $rule }
    }
    return $null
}

function Get-PublishedCompatibilityView {
    param([Parameter(Mandatory=$true)][string]$ArtifactSha256, [Parameter(Mandatory=$true)]$Rules)
    $rule = Get-ArtifactCompatibilityRule -ArtifactSha256 $ArtifactSha256 -Rules $Rules
    if ($null -eq $rule) {
        return [ordered]@{
            RuleStatus='NoReviewedRule';PublishedDriverLabel=$null;PublishedSupportedCodenames=@();
            SupportEvidence='Unknown';SourceIds=@();Notes='No exact-artifact reviewed compatibility rule exists. Do not infer support from INF matching alone.'
        }
    }
    return [ordered]@{
        RuleStatus='ExactArtifactMatched'
        PublishedDriverLabel=[string]$rule.publishedDriverLabel
        PublishedSupportedCodenames=@($rule.publishedSupportedCodenames)
        SupportEvidence=[string]$rule.supportEvidence
        SourceIds=@($rule.sourceIds)
        Notes=[string]$rule.notes
    }
}

function Resolve-ProcessorCatalogIdentity {
    param([Parameter(Mandatory=$true)][string]$ProcessorName, [Parameter(Mandatory=$true)]$ProcessorDoc)
    $matches = New-Object System.Collections.Generic.List[object]
    foreach ($processor in @($ProcessorDoc.processors)) {
        if ([System.Text.RegularExpressions.Regex]::IsMatch($ProcessorName, [string]$processor.matchRegex, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)) {
            $matches.Add($processor) | Out-Null
        }
    }
    if ($matches.Count -eq 1) {
        return [ordered]@{Status='ExactCatalogMatch';ProcessorId=[string]$matches[0].processorId;CanonicalName=[string]$matches[0].canonicalName;Codename=[string]$matches[0].codename;NpuAvailability=[string]$matches[0].npuAvailability;NpuIdentityId=if ($null -eq $matches[0].npuIdentityId) {$null} else {[string]$matches[0].npuIdentityId}}
    }
    if ($matches.Count -gt 1) { return [ordered]@{Status='AmbiguousCatalogMatch';ProcessorId=$null;CanonicalName=$null;Codename=$null;NpuAvailability='Unknown';NpuIdentityId=$null} }
    return [ordered]@{Status='ReviewRequired';ProcessorId=$null;CanonicalName=$null;Codename=$null;NpuAvailability='Unknown';NpuIdentityId=$null}
}

function Get-HardwareIdentityPublicDocument {
    param([Parameter(Mandatory=$true)]$HardwareDoc)
    return [ordered]@{
        SchemaVersion='1.1';ToolVersion=$script:ToolVersion;HandEdited=$false
        ReviewedAt=[string]$HardwareDoc.reviewedAt
        CatalogCompleteness=[string]$HardwareDoc.catalogCompleteness
        UnknownHardwarePolicy=[string]$HardwareDoc.unknownHardwarePolicy
        IdentityOrder=@($HardwareDoc.identityOrder)
        Sources=@($HardwareDoc.sources)
        Identities=@($HardwareDoc.identities)
    }
}

function Get-ProcessorCatalogPublicDocument {
    param([Parameter(Mandatory=$true)]$ProcessorDoc)
    $selfTests = New-Object System.Collections.Generic.List[object]
    foreach ($processor in @($ProcessorDoc.processors)) {
        $resolved = Resolve-ProcessorCatalogIdentity -ProcessorName ([string]$processor.canonicalName) -ProcessorDoc $ProcessorDoc
        $selfTests.Add([ordered]@{ProcessorId=[string]$processor.processorId;CanonicalName=[string]$processor.canonicalName;Status=$resolved.Status;ResolvedProcessorId=$resolved.ProcessorId}) | Out-Null
    }
    return [ordered]@{
        SchemaVersion='1.3';ToolVersion=$script:ToolVersion;HandEdited=$false
        ReviewedAt=[string]$ProcessorDoc.reviewedAt
        CatalogCompleteness=[string]$ProcessorDoc.catalogCompleteness
        UnknownSkuPolicy=[string]$ProcessorDoc.unknownSkuPolicy
        Normalization=[string]$ProcessorDoc.normalization
        Sources=@($ProcessorDoc.sources)
        Processors=@($ProcessorDoc.processors)
        CanonicalNameSelfTests=$selfTests.ToArray()
    }
}

function Get-DriverCompatibilityMatrix {
    param(
        [Parameter(Mandatory=$true)]$Analyses,
        [Parameter(Mandatory=$true)]$ProcessorDoc,
        [Parameter(Mandatory=$true)]$HardwareDoc,
        [Parameter(Mandatory=$true)]$CompatibilityDoc,
        [Parameter(Mandatory=$true)]$ObservedRuntimeDoc,
        [string]$TargetServer='Windows Server 2025'
    )
    $rows = New-Object System.Collections.Generic.List[object]
    foreach ($processor in @($ProcessorDoc.processors)) {
        $npuAvailability = [string]$processor.npuAvailability
        $expected = @($processor.expectedDeviceIds | ForEach-Object {[string]$_})
        $identityResolved = (-not [string]::IsNullOrWhiteSpace([string]$processor.npuIdentityId)) -and $expected.Count -gt 0
        $observedRuntimeRecords = @(Get-ObservedRuntimeEvidenceForProcessor -ProcessorId ([string]$processor.processorId) -ObservedRuntimeDoc $ObservedRuntimeDoc)
        $observedRuntimeIds = @($observedRuntimeRecords | ForEach-Object { [string]$_.evidenceId })

        foreach ($analysis in @($Analyses)) {
            $packageDeviceIds = @($analysis.Summary.HardwareIds | ForEach-Object { Get-DeviceIdFromHardwareId -HardwareId ([string]$_) } | Where-Object {$_} | Sort-Object -Unique)
            $infCandidate = $false
            if ($identityResolved) {
                foreach ($d in $expected) { if ($packageDeviceIds -contains ([string]$d).ToUpperInvariant()) { $infCandidate = $true; break } }
            }

            $installerCandidate = $false
            if ($identityResolved -and $analysis.Installers.Count -gt 0 -and $analysis.Installers[0].ExactHashContract) {
                $installerIds = @($analysis.Installers[0].ExactHashContract.DeviceMatcher.deviceIds | ForEach-Object {([string]$_).ToUpperInvariant()})
                foreach ($d in $expected) { if ($installerIds -contains ([string]$d).ToUpperInvariant()) { $installerCandidate = $true; break } }
            }

            $driverBinaryCodenameStatus = 'NoReviewedDriverBinaryContract'
            if ($npuAvailability -ne 'AvailablePublished') {
                $driverBinaryCodenameStatus = 'NoPublishedNpuCapability'
            }
            elseif (-not $identityResolved -or [string]$processor.codename -eq 'Unresolved') {
                $driverBinaryCodenameStatus = 'ProcessorNpuIdentityUnresolved'
            }
            elseif ($analysis.DriverBinaries.Count -gt 0 -and $analysis.DriverBinaries[0].ContractStatus -eq 'ExactHashMatched' -and $analysis.DriverBinaries[0].ExactHashContract) {
                $recognition = @($analysis.DriverBinaries[0].ExactHashContract.CodenameRecognition | Where-Object { [string]$_.codename -eq [string]$processor.codename } | Select-Object -First 1)
                if ($recognition.Count -gt 0) {
                    $driverBinaryCodenameStatus = [string]$recognition[0].mode
                }
                else {
                    $driverBinaryCodenameStatus = 'CodenameNotObservedInReviewedBinaryLogic'
                }
            }

            $published = $analysis.PublishedCompatibility
            $publishedStatus = 'NoReviewedRule'
            if ($npuAvailability -ne 'AvailablePublished') {
                $publishedStatus = 'NoPublishedNpuCapability'
            }
            elseif (-not $identityResolved -or [string]$processor.codename -eq 'Unresolved') {
                $publishedStatus = 'ProcessorNpuIdentityUnresolved'
            }
            elseif ($published.RuleStatus -eq 'ExactArtifactMatched') {
                if (@($published.PublishedSupportedCodenames) -contains [string]$processor.codename) { $publishedStatus = 'PublishedSupported' }
                else { $publishedStatus = 'NotDocumentedForCodename' }
            }

            $server = @($analysis.ServerAssessment | Where-Object {$_.Server -eq $TargetServer} | Select-Object -First 1)
            $serverStatus = if ($server.Count -gt 0) {[string]$server[0].StaticAssessment} else {'Unknown'}

            $decision = 'ReviewRequired'
            $reason = 'One or more compatibility dimensions are unresolved.'
            if ($npuAvailability -in @('NotAvailablePublished','NoPublishedNpuCapability')) {
                $decision = 'NotApplicableNoPublishedNpu'
                $reason = 'AMD published product evidence does not expose an NPU capability for this exact processor SKU; no NPU driver should be selected from this catalog entry.'
            }
            elseif ($npuAvailability -ne 'AvailablePublished') {
                $decision = 'ReviewRequired'
                $reason = 'Processor NPU availability is not sufficiently established by reviewed published evidence.'
            }
            elseif (-not $identityResolved) {
                $decision = 'ReviewRequired'
                $reason = 'AMD publishes an NPU for this exact processor SKU, but the reviewed research data does not yet bind it to an exact NPU PCI identity/codename. Do not infer from a similar product name or CPU architecture.'
            }
            elseif (-not $infCandidate) {
                $decision = 'NotApplicable'
                $reason = 'Observed INF hardware IDs do not include the processor catalog expected NPU device ID.'
            }
            elseif ($serverStatus -ne 'StaticCandidateAsPublished') {
                $decision = 'NotApplicableAsPublished'
                $reason = "Package is not a static candidate for $TargetServer ($serverStatus)."
            }
            elseif (-not $installerCandidate) {
                $decision = 'ReviewRequired'
                $reason = 'INF matches, but the reviewed installer contract does not establish this NPU device family.'
            }
            elseif ($publishedStatus -eq 'PublishedSupported') {
                $decision = 'StaticCandidateWithPublishedFamilyEvidence'
                $reason = 'Exact processor codename is in AMD published support evidence, INF/installer match the broad NPU family, and the Server static package assessment is a candidate.'
            }
            elseif ($publishedStatus -eq 'NotDocumentedForCodename') {
                $decision = 'ReviewRequired'
                $reason = 'INF/installer match the broad NPU family, but AMD published support evidence reviewed for this exact driver artifact does not list this processor codename.'
            }

            $observedRuntimeStatus = 'NoObservedClientRuntimeEvidence'
            if ($observedRuntimeRecords.Count -gt 0) {
                $exactObserved = @($observedRuntimeRecords | Where-Object { [string]$_.runtimeDriver.reviewedArtifactSha256 -eq [string]$analysis.Artifact.Sha256 })
                if ($exactObserved.Count -gt 0) { $observedRuntimeStatus = 'ExactArtifactRuntimeObserved' }
                else { $observedRuntimeStatus = 'ProcessorRuntimeObservedDifferentArtifact' }
            }

            $runtimeCompatibility = New-Object System.Collections.Generic.List[object]
            foreach ($runtime in @($CompatibilityDoc.ryzenAiSoftwareMinimumDrivers)) {
                $satisfied = $false
                if ($npuAvailability -eq 'AvailablePublished' -and $published.PublishedDriverLabel) {
                    try { $satisfied = ([version][string]$published.PublishedDriverLabel -ge [version][string]$runtime.minimumDriver) } catch { $satisfied = $false }
                }
                $runtimeCompatibility.Add([ordered]@{SoftwareVersion=[string]$runtime.softwareVersion;MinimumDriver=[string]$runtime.minimumDriver;PublishedDriverLabelSatisfied=$satisfied}) | Out-Null
            }

            $rows.Add([ordered]@{
                ProcessorId=[string]$processor.processorId;ProcessorName=[string]$processor.canonicalName;Codename=[string]$processor.codename;Series=[string]$processor.series;
                NpuAvailability=$npuAvailability;NpuIdentityId=if ($null -eq $processor.npuIdentityId) {$null} else {[string]$processor.npuIdentityId};ExpectedDeviceIds=$expected;
                ArtifactFileName=[string]$analysis.Artifact.FileName;ArtifactSha256=[string]$analysis.Artifact.Sha256;
                PublishedDriverLabel=$published.PublishedDriverLabel;EmbeddedInfDriverVersions=@($analysis.Summary.DriverVersions);
                InfHardwareCandidate=$infCandidate;InstallerBroadFamilyCandidate=$installerCandidate;DriverBinaryCodenameStatus=$driverBinaryCodenameStatus;PublishedCodenameStatus=$publishedStatus;
                TargetServer=$TargetServer;ServerStaticAssessment=$serverStatus;Decision=$decision;Reason=$reason;
                RyzenAiSoftwareCompatibility=$runtimeCompatibility.ToArray();ObservedClientRuntimeEvidenceStatus=$observedRuntimeStatus;ObservedClientRuntimeEvidenceIds=$observedRuntimeIds;RuntimeProof=$false
            }) | Out-Null
        }
    }

    $selections = New-Object System.Collections.Generic.List[object]
    foreach ($processor in @($ProcessorDoc.processors)) {
        $npuAvailability = [string]$processor.npuAvailability
        $observedSelectionRecords = @(Get-ObservedRuntimeEvidenceForProcessor -ProcessorId ([string]$processor.processorId) -ObservedRuntimeDoc $ObservedRuntimeDoc)
        $observedSelectionIds = @($observedSelectionRecords | ForEach-Object { [string]$_.evidenceId })
        if ($npuAvailability -in @('NotAvailablePublished','NoPublishedNpuCapability')) {
            $selections.Add([ordered]@{ProcessorId=[string]$processor.processorId;ProcessorName=[string]$processor.canonicalName;Codename=[string]$processor.codename;NpuAvailability=$npuAvailability;Decision='NoNpuDriverRequired';RecommendedArtifact=$null;PublishedDriverLabel=$null;ObservedClientRuntimeEvidenceStatus='NoObservedClientRuntimeEvidence';ObservedClientRuntimeEvidenceIds=@();Reason='Reviewed AMD product evidence does not expose an NPU capability for this exact SKU.'}) | Out-Null
            continue
        }
        $candidateRows = @($rows | Where-Object {$_.ProcessorId -eq $processor.processorId -and $_.Decision -eq 'StaticCandidateWithPublishedFamilyEvidence'})
        $selected = $null
        if ($candidateRows.Count -gt 0) {
            $versioned = @($candidateRows | Where-Object {$_.PublishedDriverLabel})
            $maxVersion = $null
            foreach ($row in $versioned) {
                try { $parsedVersion = [version][string]$row.PublishedDriverLabel } catch { $parsedVersion = [version]'0.0' }
                if ($null -eq $maxVersion -or $parsedVersion -gt $maxVersion) { $maxVersion = $parsedVersion }
            }
            $topVersionRows = @($versioned | Where-Object {
                try { ([version][string]$_.PublishedDriverLabel) -eq $maxVersion } catch { ([version]'0.0') -eq $maxVersion }
            })
            $selected = @(Get-AmdOrdinalSortedObjectsByStringProperty -Values $topVersionRows -PropertyName 'ArtifactFileName' | Select-Object -First 1)
        }
        if ($selected -and $selected.Count -gt 0) {
            $selectedObservedStatus=[string]$selected[0].ObservedClientRuntimeEvidenceStatus
            $selectedReason=if($selectedObservedStatus -eq 'ExactArtifactRuntimeObserved'){'Highest reviewed published driver label among packages that pass all static family/server gates. The exact artifact is also observed working on the reviewed client SKU, but Windows Server runtime validation is still required.'}else{'Highest reviewed published driver label among packages that pass all static family/server gates. Windows Server runtime validation is still required.'}
            $selections.Add([ordered]@{ProcessorId=[string]$processor.processorId;ProcessorName=[string]$processor.canonicalName;Codename=[string]$processor.codename;NpuAvailability=$npuAvailability;Decision='SelectLatestPublishedStaticCandidate';RecommendedArtifact=$selected[0].ArtifactFileName;PublishedDriverLabel=$selected[0].PublishedDriverLabel;ObservedClientRuntimeEvidenceStatus=$selectedObservedStatus;ObservedClientRuntimeEvidenceIds=$observedSelectionIds;Reason=$selectedReason}) | Out-Null
        }
        else {
            $reviewObservedStatus=if($observedSelectionRecords.Count -gt 0){'ProcessorRuntimeObservedDifferentArtifact'}else{'NoObservedClientRuntimeEvidence'}
            $selections.Add([ordered]@{ProcessorId=[string]$processor.processorId;ProcessorName=[string]$processor.canonicalName;Codename=[string]$processor.codename;NpuAvailability=$npuAvailability;Decision='ReviewRequired';RecommendedArtifact=$null;PublishedDriverLabel=$null;ObservedClientRuntimeEvidenceStatus=$reviewObservedStatus;ObservedClientRuntimeEvidenceIds=$observedSelectionIds;Reason='No analyzed package has both a resolved processor NPU identity, published codename support evidence, and all static family/server gates.'}) | Out-Null
        }
    }

    return [ordered]@{
        SchemaVersion='1.2';ToolVersion=$script:ToolVersion;HandEdited=$false
        Scope=[ordered]@{TargetServer=$TargetServer;ProcessorCatalogCompleteness=[string]$ProcessorDoc.catalogCompleteness;UnknownSkuPolicy=[string]$ProcessorDoc.unknownSkuPolicy;UnknownHardwarePolicy=[string]$HardwareDoc.unknownHardwarePolicy;ClientRuntimeEvidenceIncluded=$true;RuntimeProof=$false}
        Sources=@($CompatibilityDoc.sources)+@($ObservedRuntimeDoc.sources)
        PackageCount=@($Analyses).Count;ProcessorCount=@($ProcessorDoc.processors).Count
        Rows=$rows.ToArray();Selections=$selections.ToArray()
    }
}

function Get-ProcessorDriverApplicabilityDocument {
    param(
        [Parameter(Mandatory=$true)]$ProcessorDoc,
        [Parameter(Mandatory=$true)]$HardwareDoc,
        [Parameter(Mandatory=$true)]$CompatibilityMatrix,
        [Parameter(Mandatory=$true)]$ApplicabilityDoc,
        [Parameter(Mandatory=$true)]$ArtifactCatalogDoc
    )
    $releases = New-Object System.Collections.Generic.List[object]
    $releaseOrder = 0
    foreach ($artifact in @($ArtifactCatalogDoc.artifacts)) {
        $releaseOrder++
        $shortLabel = switch ([string]$artifact.artifactId) {
            'rai-1.5-280' { '280 (RAI1.5)' }
            'rai-280' { '280' }
            'rai-376' { '376' }
            default { [string]$artifact.publishedDriverLabel }
        }
        $releases.Add([ordered]@{
            ReleaseId=[string]$artifact.artifactId
            DisplayLabel=$shortLabel
            ArtifactFileName=[string]$artifact.fileName
            ArtifactSha256=([string]$artifact.expectedSha256).ToLowerInvariant()
            DriverLabel=[string]$artifact.publishedDriverLabel
            Visibility='PublicReviewed'
            AcquisitionPolicy=if ([bool]$artifact.defaultAcquire) { 'PublicAutomatic' } else { 'PublicManual' }
            RecommendationEligible=$true
            EvidenceClass='ReviewedPublicArtifact'
            ReleaseOrder=($releaseOrder * 10)
        }) | Out-Null
    }
    foreach ($artifact in @($ApplicabilityDoc.privateQualificationArtifacts)) {
        $releaseOrder++
        $releases.Add([ordered]@{
            ReleaseId=[string]$artifact.artifactId
            DisplayLabel='314 private'
            ArtifactFileName=[string]$artifact.fileName
            ArtifactSha256=([string]$artifact.sha256).ToLowerInvariant()
            DriverLabel=[string]$artifact.embeddedInfDriverVersion
            Visibility='PrivateQualification'
            AcquisitionPolicy=[string]$artifact.acquisitionPolicy
            RecommendationEligible=$false
            EvidenceClass=[string]$artifact.evidenceClass
            ReleaseOrder=25
        }) | Out-Null
    }
    $releaseArray = @($releases.ToArray() | Sort-Object -Property @{Expression={ [int]$_['ReleaseOrder'] };Ascending=$true}, @{Expression={ [string]$_['ArtifactFileName'] };Ascending=$true})

    $identityById = @{}
    foreach ($identity in @($HardwareDoc.identities)) { $identityById[[string]$identity.identityId] = $identity }
    $rows = New-Object System.Collections.Generic.List[object]
    foreach ($processor in @($ProcessorDoc.processors)) {
        $processorId = [string]$processor.processorId
        $identity = $null
        if (-not [string]::IsNullOrWhiteSpace([string]$processor.npuIdentityId) -and $identityById.ContainsKey([string]$processor.npuIdentityId)) { $identity = $identityById[[string]$processor.npuIdentityId] }
        $hardwareId = if ($identity) { [string]$identity.hardwareIdPattern } else { $null }
        $npuLabel = if ([string]$processor.npuAvailability -ne 'AvailablePublished') {
            'No published NPU'
        } elseif ($identity) {
            [string]$identity.architectureFamily
        } else {
            'Published NPU; exact PCI identity unresolved'
        }
        $pciRevision = $null
        if ($processor.PSObject.Properties['observedNpuIdentity'] -and $null -ne $processor.observedNpuIdentity) { $pciRevision = [string]$processor.observedNpuIdentity.pciRevision }

        $driverApplicability = New-Object System.Collections.Generic.List[object]
        foreach ($release in $releaseArray) {
            if ([string]$release.Visibility -eq 'PublicReviewed') {
                $matrixRows = @($CompatibilityMatrix.Rows | Where-Object { [string]$_.ProcessorId -eq $processorId -and [string]$_.ArtifactSha256 -eq [string]$release.ArtifactSha256 })
                if ($matrixRows.Count -eq 1) {
                    $mr = $matrixRows[0]
                    $evidenceClass = if ([string]$mr.ObservedClientRuntimeEvidenceStatus -eq 'ExactArtifactRuntimeObserved') {
                        'ExactArtifactClientRuntimeObservedPlusStaticEvidence'
                    } elseif ([string]$mr.PublishedCodenameStatus -eq 'PublishedSupported') {
                        'PublishedFamilyPlusStaticArtifactEvidence'
                    } elseif ([string]$mr.PublishedCodenameStatus -eq 'NotDocumentedForCodename') {
                        'BroadArtifactEvidenceWithoutPublishedCodenameSupport'
                    } else {
                        'StaticArtifactEvidenceOnly'
                    }
                    $driverApplicability.Add([ordered]@{
                        ReleaseId=[string]$release.ReleaseId
                        Visibility=[string]$release.Visibility
                        RecommendationEligible=$true
                        Applicability=[string]$mr.Decision
                        ServerStaticAssessment=[string]$mr.ServerStaticAssessment
                        PublishedCodenameStatus=[string]$mr.PublishedCodenameStatus
                        InfHardwareCandidate=[bool]$mr.InfHardwareCandidate
                        InstallerBroadFamilyCandidate=[bool]$mr.InstallerBroadFamilyCandidate
                        EvidenceClass=$evidenceClass
                        Reason=[string]$mr.Reason
                    }) | Out-Null
                } else {
                    $driverApplicability.Add([ordered]@{
                        ReleaseId=[string]$release.ReleaseId;Visibility=[string]$release.Visibility;RecommendationEligible=$true;Applicability='ReviewRequired';ServerStaticAssessment='Unknown';PublishedCodenameStatus='NoReviewedRule';InfHardwareCandidate=$false;InstallerBroadFamilyCandidate=$false;EvidenceClass='MissingAnalyzedArtifactRow';Reason='No unique compatibility-matrix row exists for this processor and reviewed public artifact.'
                    }) | Out-Null
                }
            } else {
                $privateArtifact = @($ApplicabilityDoc.privateQualificationArtifacts | Where-Object { [string]$_.artifactId -eq [string]$release.ReleaseId } | Select-Object -First 1)
                $applicability = 'ReviewRequired'
                $reason = 'Private qualification applicability is unresolved.'
                $infCandidate = $false
                if ([string]$processor.npuAvailability -in @('NotAvailablePublished','NoPublishedNpuCapability')) {
                    $applicability = 'NotApplicableNoPublishedNpu'
                    $reason = 'AMD published product evidence does not expose an NPU capability for this exact processor SKU.'
                } elseif ([string]$processor.npuAvailability -ne 'AvailablePublished') {
                    $applicability = 'ReviewRequired'
                    $reason = 'Exact processor NPU availability is not sufficiently established.'
                } elseif ($null -eq $identity -or @($processor.expectedDeviceIds).Count -eq 0) {
                    $applicability = 'ReviewRequiredIdentityUnresolved'
                    $reason = 'AMD publishes an NPU for this exact SKU, but the reviewed PCI NPU identity is unresolved; broad private-INF matching must not be inferred.'
                } elseif ($privateArtifact.Count -eq 1) {
                    foreach ($deviceId in @($processor.expectedDeviceIds)) {
                        if (@($privateArtifact[0].broadInfDeviceIds | ForEach-Object { ([string]$_).ToUpperInvariant() }) -contains ([string]$deviceId).ToUpperInvariant()) { $infCandidate = $true; break }
                    }
                    if ($infCandidate) {
                        $applicability = 'PrivateQualificationOnlyBroadInfCandidate'
                        $reason = 'The manually supplied restricted artifact INF broadly matches the reviewed NPU device ID. This is static qualification evidence only and can never become an automatic recommendation without separate published support evidence.'
                    } else {
                        $applicability = 'NotApplicable'
                        $reason = 'The private qualification artifact INF does not contain the reviewed processor NPU device ID.'
                    }
                }
                $driverApplicability.Add([ordered]@{
                    ReleaseId=[string]$release.ReleaseId
                    Visibility=[string]$release.Visibility
                    RecommendationEligible=$false
                    Applicability=$applicability
                    ServerStaticAssessment=if ($infCandidate) { 'StaticBuildFloorCandidateOnly' } else { 'NotEstablished' }
                    PublishedCodenameStatus='PrivateArtifactNoPublishedSupportClaim'
                    InfHardwareCandidate=$infCandidate
                    InstallerBroadFamilyCandidate=$false
                    EvidenceClass='PrivateQualificationStaticArtifact'
                    Reason=$reason
                }) | Out-Null
            }
        }

        $selection = @($CompatibilityMatrix.Selections | Where-Object { [string]$_.ProcessorId -eq $processorId } | Select-Object -First 1)
        $recommendedArtifact = $null
        $recommendedReleaseId = $null
        $publishedDriverLabel = $null
        $recommendationDecision = 'ReviewRequired'
        $recommendationReason = 'No compatibility-matrix selection was produced.'
        if ($selection.Count -eq 1) {
            $recommendedArtifact = $selection[0].RecommendedArtifact
            $publishedDriverLabel = $selection[0].PublishedDriverLabel
            $recommendationDecision = [string]$selection[0].Decision
            $recommendationReason = [string]$selection[0].Reason
            if ($recommendedArtifact) {
                $releaseMatch = @($releaseArray | Where-Object { [string]$_.DriverLabel -eq [string]$publishedDriverLabel -and [string]$_.Visibility -eq 'PublicReviewed' } | Select-Object -First 1)
                if ($releaseMatch.Count -eq 1) { $recommendedReleaseId = [string]$releaseMatch[0].ReleaseId }
            }
        }
        [object[]]$observedEvidenceIds = @()
        if ($processor.PSObject.Properties['observedEvidenceIds']) { $observedEvidenceIds = @($processor.observedEvidenceIds | Where-Object { $null -ne $_ -and -not [string]::IsNullOrWhiteSpace([string]$_) }) }
        $rows.Add([ordered]@{
            ProcessorId=$processorId
            ProcessorName=[string]$processor.canonicalName
            ProductFamily=[string]$processor.series
            Codename=[string]$processor.codename
            NpuAvailability=[string]$processor.npuAvailability
            NpuLabel=$npuLabel
            NpuIdentityId=if ($null -eq $processor.npuIdentityId) { $null } else { [string]$processor.npuIdentityId }
            HardwareId=$hardwareId
            PciRevision=$pciRevision
            NpuTops=$processor.npuTops
            DriverApplicability=$driverApplicability.ToArray()
            RecommendationDecision=$recommendationDecision
            RecommendedReleaseId=$recommendedReleaseId
            RecommendedArtifact=$recommendedArtifact
            PublishedDriverLabel=$publishedDriverLabel
            RecommendationReason=$recommendationReason
            Evidence=[ordered]@{
                ProcessorEvidence=[string]$processor.npuEvidence
                ProcessorSourceIds=@($processor.sourceIds)
                ObservedEvidenceIds=@($observedEvidenceIds)
                ClientRuntimeEvidenceIncluded=(@($observedEvidenceIds).Count -gt 0)
                ServerRuntimeProof=$false
            }
        }) | Out-Null
    }
    return [ordered]@{
        SchemaVersion='1.0'
        ToolVersion=$script:ToolVersion
        HandEdited=$false
        ReviewedAt=[string]$ApplicabilityDoc.reviewedAt
        Scope=[string]$ApplicabilityDoc.scope
        Policies=[ordered]@{
            UnknownProcessorPolicy=[string]$ApplicabilityDoc.unknownProcessorPolicy
            UnknownHardwarePolicy=[string]$ApplicabilityDoc.unknownHardwarePolicy
            PubliclyObtainableArtifactsOnly=[bool]$ApplicabilityDoc.recommendationPolicy.publiclyObtainableArtifactsOnly
            PrivateQualificationArtifactsNeverRecommended=[bool]$ApplicabilityDoc.recommendationPolicy.privateQualificationArtifactsNeverRecommended
            HighestReviewedPublishedStaticCandidate=[bool]$ApplicabilityDoc.recommendationPolicy.highestReviewedPublishedStaticCandidate
            WindowsServerRuntimeProofRequiredForRuntimeClaim=[bool]$ApplicabilityDoc.recommendationPolicy.windowsServerRuntimeProofRequiredForRuntimeClaim
            SeriesNameOnlyInferenceProhibited=[bool]$ApplicabilityDoc.recommendationPolicy.seriesNameOnlyInferenceProhibited
        }
        Sources=@($ApplicabilityDoc.sources)
        Releases=$releaseArray
        ProcessorCount=@($ProcessorDoc.processors).Count
        Rows=$rows.ToArray()
    }
}

function Convert-ProcessorDriverApplicabilityToMarkdown {
    param([Parameter(Mandatory=$true)]$Document)
    $sb = New-Object System.Text.StringBuilder
    [void]$sb.AppendLine('# AMD NPU Processor-to-Driver Applicability')
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine('- Exact-SKU, fail-closed research dataset. Series-name-only inference is prohibited.')
    [void]$sb.AppendLine('- Recommendations use only reviewed publicly obtainable artifacts. `314 private` is manual/private qualification evidence and is never recommendation-eligible.')
    [void]$sb.AppendLine('- All Windows Server decisions are static applicability assessments; Windows client runtime observations do not prove Windows Server runtime operation.')
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine('| CPU SKU | Product family | Codename | NPU | HWID | PCI REV | 280 (RAI1.5) | 280 | 314 private | 376 | Recommended | Evidence |')
    [void]$sb.AppendLine('|---|---|---|---|---|---|---|---|---|---|---|---|')
    foreach ($row in @($Document.Rows)) {
        $statusByRelease = @{}
        foreach ($entry in @($row.DriverApplicability)) { $statusByRelease[[string]$entry.ReleaseId] = [string]$entry.Applicability }
        $hwid = if ([string]::IsNullOrWhiteSpace([string]$row.HardwareId)) { $script:MarkdownEmDash } else { "``$($row.HardwareId)``" }
        $rev = if ([string]::IsNullOrWhiteSpace([string]$row.PciRevision)) { $script:MarkdownEmDash } else { "``$($row.PciRevision)``" }
        $recommended = if ($row.RecommendedArtifact) { "``$($row.RecommendedArtifact)``" } elseif ([string]$row.RecommendationDecision -eq 'NoNpuDriverRequired') { 'None required' } else { '**ReviewRequired**' }
        $evidence = [string]$row.Evidence.ProcessorEvidence
        if ([bool]$row.Evidence.ClientRuntimeEvidenceIncluded) { $evidence += '; reviewed client runtime' }
        [void]$sb.AppendLine("| $($row.ProcessorName) | $($row.ProductFamily) | $($row.Codename) | $($row.NpuLabel) | $hwid | $rev | $($statusByRelease['rai-1.5-280']) | $($statusByRelease['rai-280']) | $($statusByRelease['rai-1.6.1-314-private']) | $($statusByRelease['rai-376']) | $recommended | $evidence |")
    }
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine('## Release policy')
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine('| Release | Visibility | Acquisition | Recommendation eligible |')
    [void]$sb.AppendLine('|---|---|---|---|')
    foreach ($release in @($Document.Releases)) { [void]$sb.AppendLine("| $($release.DisplayLabel) | $($release.Visibility) | $($release.AcquisitionPolicy) | $($release.RecommendationEligible) |") }
    return $sb.ToString()
}

function Convert-HardwareIdentityToMarkdown {
    param($Document)
    $sb = New-Object System.Text.StringBuilder
    [void]$sb.AppendLine('# AMD NPU Hardware Identity Catalog')
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine("- Completeness: **$($Document.CatalogCompleteness)**")
    [void]$sb.AppendLine("- Unknown hardware policy: **$($Document.UnknownHardwarePolicy)**")
    [void]$sb.AppendLine('- Firmware device revision values are not PCI `REV_XX` values.')
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine('| Identity | PCI device | AMD label | Broad codenames |')
    [void]$sb.AppendLine('|---|---|---|---|')
    foreach ($i in $Document.Identities) { [void]$sb.AppendLine("| ``$($i.identityId)`` | ``1022:$($i.deviceId)`` | $($i.amdNpuCheckLabel) | $([string]::Join(', ', @($i.broadCodenames))) |") }
    foreach ($i in $Document.Identities) {
        if ($i.PSObject.Properties['observedRuntimeBindings'] -and @($i.observedRuntimeBindings).Count -gt 0) {
            [void]$sb.AppendLine('')
            [void]$sb.AppendLine("## Observed runtime binding: ``$($i.identityId)``")
            [void]$sb.AppendLine('')
            [void]$sb.AppendLine('| Processor | PCI REV | XRT device | Firmware | Exact 376 stack |')
            [void]$sb.AppendLine('|---|---|---|---|---|')
            foreach($o in @($i.observedRuntimeBindings)){[void]$sb.AppendLine("| $($o.processorName) | ``$($o.pciRevision)`` | $($o.xrtDeviceName) | ``$($o.xrtFirmwareVersion)`` | $($o.fullObservedStackExactMatch) |")}
        }
        if (@($i.firmwareRevisionMap).Count -gt 0) {
            [void]$sb.AppendLine('')
            [void]$sb.AppendLine("## Firmware revision refinement: ``$($i.identityId)``")
            [void]$sb.AppendLine('')
            [void]$sb.AppendLine('| Value | Symbol | Linux label | Codename |')
            [void]$sb.AppendLine('|---:|---|---|---|')
            foreach ($r in $i.firmwareRevisionMap) { [void]$sb.AppendLine("| $($r.value) | ``$($r.symbol)`` | $($r.label) | $($r.codename) |") }
        }
    }
    return $sb.ToString()
}

function Convert-ProcessorCatalogToMarkdown {
    param($Document)
    $sb = New-Object System.Text.StringBuilder
    [void]$sb.AppendLine('# AMD NPU Processor Catalog')
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine("- Completeness: **$($Document.CatalogCompleteness)**")
    [void]$sb.AppendLine("- Unknown SKU policy: **$($Document.UnknownSkuPolicy)**")
    [void]$sb.AppendLine('- The catalog includes exact-SKU NPU-positive entries plus reviewed negative controls where AMD does not publish an NPU capability.')
    [void]$sb.AppendLine('- Similar CPU architecture or product naming must not be used to infer an NPU identity.')
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine('| Processor | Series | NPU availability | Codename | NPU identity | Expected DEV | Observed runtime | NPU TOPS | Tray product ID |')
    [void]$sb.AppendLine('|---|---|---|---|---|---|---|---:|---|')
    foreach ($p in $Document.Processors) {
        $identity = if ($null -eq $p.npuIdentityId) {$script:MarkdownEmDash} else {"``$($p.npuIdentityId)``"}
        $dev = if (@($p.expectedDeviceIds).Count -eq 0) {$script:MarkdownEmDash} else {"``$([string]::Join(', ', @($p.expectedDeviceIds)))``"}
        $tops = if ($null -eq $p.npuTops) {$script:MarkdownEmDash} else {[string]$p.npuTops}
        $tray = if ($null -eq $p.productIdTray) {$script:MarkdownEmDash} else {"``$($p.productIdTray)``"}
        $observed = if ($p.PSObject.Properties['observedEvidenceIds'] -and @($p.observedEvidenceIds).Count -gt 0) { 'Yes' } else { $script:MarkdownEmDash }
        [void]$sb.AppendLine("| $($p.canonicalName) | $($p.series) | **$($p.npuAvailability)** | $($p.codename) | $identity | $dev | $observed | $tops | $tray |")
    }
    return $sb.ToString()
}

function Convert-DriverCompatibilityMatrixToMarkdown {
    param($Matrix)
    $sb = New-Object System.Text.StringBuilder
    [void]$sb.AppendLine('# AMD NPU Driver Compatibility Matrix')
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine("- Target server: **$($Matrix.Scope.TargetServer)**")
    [void]$sb.AppendLine("- Processor catalog: **$($Matrix.Scope.ProcessorCatalogCompleteness)**")
    [void]$sb.AppendLine('- All decisions are static research decisions. None is runtime installation proof.')
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine('## Recommended selection from analyzed artifacts')
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine('| Processor | NPU availability | Codename | Client runtime | Decision | Recommended artifact | Published driver label |')
    [void]$sb.AppendLine('|---|---|---|---|---|')
    foreach ($s in $Matrix.Selections) { [void]$sb.AppendLine("| $($s.ProcessorName) | $($s.NpuAvailability) | $($s.Codename) | $($s.ObservedClientRuntimeEvidenceStatus) | **$($s.Decision)** | $($s.RecommendedArtifact) | $($s.PublishedDriverLabel) |") }
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine('## Evidence matrix')
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine('| Processor | Artifact | INF HWID | Installer family | Driver binary identity | AMD published codename | Client runtime | Server static | Decision |')
    [void]$sb.AppendLine('|---|---|---|---|---|---|---|---|')
    foreach ($r in $Matrix.Rows) { [void]$sb.AppendLine("| $($r.ProcessorName) | ``$($r.ArtifactFileName)`` | $($r.InfHardwareCandidate) | $($r.InstallerBroadFamilyCandidate) | $($r.DriverBinaryCodenameStatus) | $($r.PublishedCodenameStatus) | $($r.ObservedClientRuntimeEvidenceStatus) | $($r.ServerStaticAssessment) | **$($r.Decision)** |") }
    return $sb.ToString()
}


function Get-NpuArtifactFormatFromPath {
    [CmdletBinding()]
    param([Parameter(Mandatory=$true)][string]$Path)
    switch ([System.IO.Path]::GetExtension($Path).ToLowerInvariant()) {
        '.zip' { return 'zip' }
        '.exe' { return 'exe' }
        '.msi' { return 'msi' }
        '.cab' { return 'cab' }
        '.7z'  { return '7z' }
        default { return 'unknown' }
    }
}

function Test-NpuSupportedArtifactPath {
    [CmdletBinding()]
    param([Parameter(Mandatory=$true)][string]$Path)
    return ((Get-NpuArtifactFormatFromPath -Path $Path) -ne 'unknown')
}

function Get-NpuAnalysisSurface {
    [CmdletBinding()]
    param([Parameter(Mandatory=$true)][string]$Root)
    if (-not (Test-Path -LiteralPath $Root -PathType Container)) {
        return [pscustomobject][ordered]@{InfCount=0;NpuInfCount=0;DriverBinaryCount=0;InstallerCount=0;Reached=$false}
    }
    $infs=@(Get-ChildItem -LiteralPath $Root -Filter '*.inf' -File -Recurse -ErrorAction SilentlyContinue)
    $npuInf=0
    foreach($inf in $infs){
        if($inf.Name -ieq 'kipudrv.inf'){$npuInf++;continue}
        try{
            $s=[IO.File]::ReadAllText($inf.FullName)
            if($s -match '(?i)PCI\\VEN_1022&DEV_(1502|17F0)' -or $s -match '(?i)XDNA|NPU'){$npuInf++}
        }catch{}
    }
    $drivers=@(Get-ChildItem -LiteralPath $Root -Filter 'ipustack.sys' -File -Recurse -ErrorAction SilentlyContinue)
    $installers=@(Get-ChildItem -LiteralPath $Root -Filter 'npu_sw_installer.exe' -File -Recurse -ErrorAction SilentlyContinue)
    return [pscustomobject][ordered]@{
        InfCount=$infs.Count;NpuInfCount=$npuInf;DriverBinaryCount=$drivers.Count;InstallerCount=$installers.Count
        Reached=($npuInf -gt 0 -or $drivers.Count -gt 0)
    }
}

function Test-NpuExtractionParityContract {
    [CmdletBinding()]
    param()
    $issues=New-Object 'System.Collections.Generic.List[string]'
    $contract=$script:PredecessorExtractionContractDoc
    if($null -eq $contract){
        $p=Join-Path $PSScriptRoot 'data/predecessor-extraction-core-contract.json'
        if(-not(Test-Path -LiteralPath $p -PathType Leaf)){$issues.Add('Predecessor extraction-core contract is missing.')|Out-Null;return @($issues.ToArray())}
        try{$contract=Read-AmdJsonFile -Path $p}catch{$issues.Add(('Predecessor extraction-core contract cannot be read: {0}' -f $_.Exception.Message))|Out-Null;return @($issues.ToArray())}
    }
    $tokens=$null;$parseErrors=$null
    $ast=[Management.Automation.Language.Parser]::ParseFile($script:SourceScriptPath,[ref]$tokens,[ref]$parseErrors)
    if(@($parseErrors).Count){$issues.Add('Current NPU source cannot be parsed for extraction parity verification.')|Out-Null;return @($issues.ToArray())}
    $map=@{}
    foreach($fn in @($ast.FindAll({param($node)$node -is [Management.Automation.Language.FunctionDefinitionAst]},$true))){$map[[string]$fn.Name]=[string]$fn.Extent.Text}
    foreach($entry in @($contract.functions)){
        $name=[string]$entry.name
        if(-not $map.ContainsKey($name)){$issues.Add(('Predecessor extraction function missing: {0}' -f $name))|Out-Null;continue}
        $normalized=([string]$map[$name]) -replace "`r`n","`n" -replace "`r","`n"
        if((Get-AmdStringSha256 -Text $normalized) -ne ([string]$entry.sha256).ToLowerInvariant()){$issues.Add(('Predecessor extraction function drifted: {0}' -f $name))|Out-Null}
    }
    return @($issues.ToArray())
}

function Resolve-PackageInputs {
    param([string[]]$Requested)
    $resolved = New-Object System.Collections.Generic.List[string]
    if ($Requested -and $Requested.Count -gt 0) {
        foreach ($item in $Requested) {
            $matches = @(Get-ChildItem -Path $item -File -ErrorAction SilentlyContinue)
            if ($matches.Count -eq 0 -and (Test-Path -LiteralPath $item -PathType Leaf)) { $matches = @((Get-Item -LiteralPath $item)) }
            foreach ($m in $matches) { if (Test-NpuSupportedArtifactPath -Path $m.FullName) { $resolved.Add($m.FullName) | Out-Null } }
        }
    }
    else {
        $inventory = Join-Path $PSScriptRoot 'inventory'
        if (Test-Path -LiteralPath $inventory) {
            foreach ($m in @(Get-ChildItem -LiteralPath $inventory -File -ErrorAction SilentlyContinue)) {
                if (Test-NpuSupportedArtifactPath -Path $m.FullName) { $resolved.Add($m.FullName) | Out-Null }
            }
        }
    }
    $ordered = New-Object 'System.Collections.Generic.List[string]'
    foreach ($path in @($resolved | Select-Object -Unique)) { $ordered.Add([string]$path) | Out-Null }
    $comparison = [System.Comparison[string]]{
        param($left, $right)
        $nameCompare = [System.StringComparer]::OrdinalIgnoreCase.Compare([System.IO.Path]::GetFileName($left), [System.IO.Path]::GetFileName($right))
        if ($nameCompare -ne 0) { return $nameCompare }
        return [System.StringComparer]::OrdinalIgnoreCase.Compare($left, $right)
    }
    $ordered.Sort($comparison)
    return @($ordered)
}

function Expand-ZipStatic {
    param([Parameter(Mandatory=$true)][string]$ZipPath, [Parameter(Mandatory=$true)][string]$Destination)
    Add-Type -AssemblyName System.IO.Compression -ErrorAction SilentlyContinue
    Add-Type -AssemblyName System.IO.Compression.FileSystem -ErrorAction SilentlyContinue
    if (Test-Path -LiteralPath $Destination) { Remove-Item -LiteralPath $Destination -Recurse -Force }
    New-Item -ItemType Directory -Path $Destination -Force | Out-Null
    $destRoot = [System.IO.Path]::GetFullPath($Destination)
    if (-not $destRoot.EndsWith([System.IO.Path]::DirectorySeparatorChar.ToString())) { $destRoot += [System.IO.Path]::DirectorySeparatorChar }
    $archive = [System.IO.Compression.ZipFile]::OpenRead($ZipPath)
    try {
        foreach ($entry in $archive.Entries) {
            $entryName = $entry.FullName -replace '/', [System.IO.Path]::DirectorySeparatorChar
            if ([string]::IsNullOrWhiteSpace($entryName)) { continue }
            $candidate = [System.IO.Path]::GetFullPath((Join-Path $Destination $entryName))
            if (-not $candidate.StartsWith($destRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
                throw "Unsafe ZIP traversal entry: $($entry.FullName)"
            }
            if ($entry.FullName.EndsWith('/') -or $entry.FullName.EndsWith('\')) {
                New-Item -ItemType Directory -Path $candidate -Force | Out-Null
                continue
            }
            $parent = Split-Path -Parent $candidate
            if ($parent -and -not (Test-Path -LiteralPath $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
            $input = $entry.Open()
            try {
                $output = [System.IO.File]::Create($candidate)
                try { $input.CopyTo($output) } finally { $output.Dispose() }
            }
            finally { $input.Dispose() }
        }
    }
    finally { $archive.Dispose() }
}

function Get-InfSections {
    param([Parameter(Mandatory=$true)][string]$Path)
    $lines = [System.IO.File]::ReadAllLines($Path)
    $sections = [ordered]@{}
    $current = $null
    foreach ($raw in $lines) {
        $line = $raw.Trim()
        if ($line -match '^\s*\[([^\]]+)\]\s*$') {
            $current = $matches[1].Trim()
            if (-not $sections.Contains($current)) { $sections[$current] = New-Object System.Collections.Generic.List[string] }
            continue
        }
        if ($null -ne $current) { $sections[$current].Add($raw) | Out-Null }
    }
    return $sections
}

function Get-InfAssignment {
    param($Sections, [string]$SectionName, [string]$Key)
    if (-not $Sections.Contains($SectionName)) { return $null }
    foreach ($raw in $Sections[$SectionName]) {
        $line = ($raw -split ';', 2)[0].Trim()
        if ($line -match ('^' + [regex]::Escape($Key) + '\s*=\s*(.+)$')) { return $matches[1].Trim() }
    }
    return $null
}

function Get-TargetDecoration {
    param([Parameter(Mandatory=$true)][string]$Decoration)
    $d = $Decoration.Trim()
    $result = [ordered]@{
        Raw = $d; Architecture = $null; OSMajorVersion = $null; OSMinorVersion = $null;
        ProductType = $null; SuiteMask = $null; BuildNumber = $null; ParseStatus = 'Unknown'
    }
    if ($d -notmatch '^NT(?<arch>x86|amd64|ia64|arm64|arm)?(?:\.(?<rest>.*))?$') { return $result }
    $result.Architecture = $matches['arch']
    $rest = $matches['rest']
    if ([string]::IsNullOrEmpty($rest)) { $result.ParseStatus = 'Parsed'; return $result }
    $parts = $rest.Split([char]'.')
    if ($parts.Length -gt 0 -and $parts[0]) { $result.OSMajorVersion = [int]$parts[0] }
    if ($parts.Length -gt 1 -and $parts[1]) { $result.OSMinorVersion = [int]$parts[1] }
    if ($parts.Length -gt 2 -and $parts[2]) { $result.ProductType = $parts[2] }
    if ($parts.Length -gt 3 -and $parts[3]) { $result.SuiteMask = $parts[3] }
    if ($parts.Length -gt 4 -and $parts[4]) { $result.BuildNumber = [int]$parts[4] }
    $result.ParseStatus = 'Parsed'
    return $result
}

function Get-ServerProjection {
    param($Decoration, $Profiles)
    $rows = New-Object System.Collections.Generic.List[object]
    foreach ($profile in $Profiles) {
        $status = 'Candidate'
        $reason = 'Selector does not exclude this server profile.'
        if ($Decoration.ParseStatus -ne 'Parsed') {
            $status = 'Unknown'; $reason = 'TargetOSVersion decoration could not be parsed.'
        }
        elseif ($Decoration.Architecture -and $Decoration.Architecture -ne $profile.architecture) {
            $status = 'RejectedArchitecture'; $reason = 'Architecture mismatch.'
        }
        elseif ($null -ne $Decoration.OSMajorVersion -and [int]$Decoration.OSMajorVersion -gt [int]$profile.major) {
            $status = 'RejectedOSVersion'; $reason = 'OS major version is lower than selector.'
        }
        elseif ($null -ne $Decoration.OSMajorVersion -and [int]$Decoration.OSMajorVersion -eq [int]$profile.major -and
                $null -ne $Decoration.OSMinorVersion -and [int]$Decoration.OSMinorVersion -gt [int]$profile.minor) {
            $status = 'RejectedOSVersion'; $reason = 'OS minor version is lower than selector.'
        }
        elseif ($null -ne $Decoration.OSMajorVersion -and [int]$Decoration.OSMajorVersion -eq [int]$profile.major -and
                $null -ne $Decoration.OSMinorVersion -and [int]$Decoration.OSMinorVersion -eq [int]$profile.minor -and
                $null -ne $Decoration.BuildNumber -and [int]$profile.build -lt [int]$Decoration.BuildNumber) {
            $status = 'RejectedBuildFloor'; $reason = "OS build $($profile.build) is below selector build floor $($Decoration.BuildNumber)."
        }
        elseif ($null -ne $Decoration.ProductType -and [string]$Decoration.ProductType -ne [string]$profile.productType) {
            $status = 'RejectedProductType'; $reason = "ProductType $($profile.productType) does not match selector ProductType $($Decoration.ProductType)."
        }
        $rows.Add([ordered]@{
            Server = $profile.name
            Build = [int]$profile.build
            ProductType = [int]$profile.productType
            Status = $status
            Reason = $reason
            EvidenceLevel = 'Analysis'
        }) | Out-Null
    }
    return $rows.ToArray()
}

function Get-InfAnalysis {
    param([Parameter(Mandatory=$true)][string]$Path, [Parameter(Mandatory=$true)]$Profiles, [Parameter(Mandatory=$true)][string]$ExtractRoot)
    $sections = Get-InfSections -Path $Path
    $relative = (Get-RelativePathCompat -BasePath $ExtractRoot -TargetPath $Path) -replace '\\','/'
    $driverVer = Get-InfAssignment $sections 'Version' 'DriverVer'
    $catalog = Get-InfAssignment $sections 'Version' 'CatalogFile'
    $class = Get-InfAssignment $sections 'Version' 'Class'
    $classGuid = Get-InfAssignment $sections 'Version' 'ClassGuid'
    $pnpLockdown = Get-InfAssignment $sections 'Version' 'PnpLockdown'

    $manufacturerEntries = New-Object System.Collections.Generic.List[object]
    $models = New-Object System.Collections.Generic.List[object]
    $decorations = New-Object System.Collections.Generic.List[object]
    if ($sections.Contains('Manufacturer')) {
        foreach ($raw in $sections['Manufacturer']) {
            $line = ($raw -split ';', 2)[0].Trim()
            if (-not $line -or $line.StartsWith(';') -or $line -notmatch '=') { continue }
            $kv = $line -split '=', 2
            $rhs = $kv[1].Trim()
            $parts = @($rhs -split ',' | ForEach-Object { $_.Trim() })
            if ($parts.Count -lt 1) { continue }
            $base = $parts[0]
            $targets = @()
            if ($parts.Count -gt 1) { $targets = @($parts[1..($parts.Count-1)]) }
            $manufacturerEntries.Add([ordered]@{ Token=$kv[0].Trim(); ModelsSection=$base; TargetOSVersions=$targets }) | Out-Null
            foreach ($target in $targets) {
                $dec = Get-TargetDecoration -Decoration $target
                $decorations.Add($dec) | Out-Null
                $modelSection = "$base.$target"
                if ($sections.Contains($modelSection)) {
                    foreach ($modelRaw in $sections[$modelSection]) {
                        $modelLine = ($modelRaw -split ';',2)[0].Trim()
                        if (-not $modelLine -or $modelLine -notmatch '=') { continue }
                        $mkv = $modelLine -split '=',2
                        $mParts = @($mkv[1] -split ',' | ForEach-Object { $_.Trim() })
                        if ($mParts.Count -lt 2) { continue }
                        $models.Add([ordered]@{
                            DescriptionToken = $mkv[0].Trim()
                            InstallSection = $mParts[0]
                            HardwareId = $mParts[1]
                            ModelsSection = $modelSection
                            TargetOSVersion = $target
                        }) | Out-Null
                    }
                }
            }
        }
    }

    $serviceBinaries = New-Object System.Collections.Generic.List[string]
    $includes = New-Object System.Collections.Generic.List[string]
    $needs = New-Object System.Collections.Generic.List[string]
    $wdf = New-Object System.Collections.Generic.List[object]
    $productTypeLiteralObserved = $false
    foreach ($name in $sections.Keys) {
        foreach ($raw in $sections[$name]) {
            $line = ($raw -split ';',2)[0].Trim()
            if ($line -match '^ServiceBinary\s*=\s*(.+)$') { $serviceBinaries.Add($matches[1].Trim()) | Out-Null }
            if ($line -match '^Include\s*=\s*(.+)$') { $includes.Add($matches[1].Trim()) | Out-Null }
            if ($line -match '^Needs\s*=\s*(.+)$') { $needs.Add($matches[1].Trim()) | Out-Null }
            if ($line -match '^(KmdfLibraryVersion|UmdfLibraryVersion)\s*=\s*(.+)$') {
                $wdf.Add([ordered]@{Section=$name; Key=$matches[1]; Value=$matches[2].Trim()}) | Out-Null
            }
            if ($line -match 'ProductType\s*=') { $productTypeLiteralObserved = $true }
        }
    }

    $serverProjections = New-Object System.Collections.Generic.List[object]
    foreach ($dec in $decorations) {
        foreach ($projection in @(Get-ServerProjection -Decoration $dec -Profiles $Profiles)) {
            $serverProjections.Add([ordered]@{ TargetOSVersion=$dec.Raw; Server=$projection.Server; Build=$projection.Build; ProductType=$projection.ProductType; Status=$projection.Status; Reason=$projection.Reason; EvidenceLevel='Analysis' }) | Out-Null
        }
    }

    $dvDate = $null; $dvVersion = $null
    if ($driverVer -and $driverVer -match '^\s*([^,]+),\s*(.+?)\s*$') { $dvDate=$matches[1]; $dvVersion=$matches[2] }

    return [ordered]@{
        Path = $relative
        Sha256 = Get-Sha256 $Path
        Version = [ordered]@{
            Class = $class; ClassGuid = $classGuid; PnpLockdown = $pnpLockdown;
            DriverVerRaw = $driverVer; DriverDate = $dvDate; DriverVersion = $dvVersion; CatalogFile = $catalog
        }
        Manufacturer = $manufacturerEntries.ToArray()
        TargetOSVersions = $decorations.ToArray()
        Models = $models.ToArray()
        UniqueHardwareIds = @(Get-AmdOrdinalSortedUniqueStrings -Values @($models | ForEach-Object { $_.HardwareId }))
        ServiceBinaries = @(Get-AmdOrdinalSortedUniqueStrings -Values @($serviceBinaries))
        Includes = @(Get-AmdOrdinalSortedUniqueStrings -Values @($includes))
        Needs = @(Get-AmdOrdinalSortedUniqueStrings -Values @($needs))
        WdfDirectives = $wdf.ToArray()
        ProductTypeAssignmentObserved = $productTypeLiteralObserved
        ServerProjection = $serverProjections.ToArray()
        EvidenceLevel = 'PayloadObserved'
    }
}

function Get-AsciiStrings {
    param(
        [Parameter(Mandatory=$true)][string]$Path,
        [int]$MinimumLength = 5
    )
    # Decode once and let the .NET regex engine find printable runs. This avoids a
    # per-byte PowerShell loop, which is prohibitively slow on installer binaries.
    $text = [System.Text.Encoding]::ASCII.GetString([System.IO.File]::ReadAllBytes($Path))
    $pattern = '[ -~]{' + $MinimumLength + ',}'
    $result = New-Object System.Collections.Generic.List[string]
    foreach ($m in [System.Text.RegularExpressions.Regex]::Matches($text, $pattern)) {
        $result.Add($m.Value) | Out-Null
    }
    return $result.ToArray()
}

function Get-InstallerAnalysis {
    param([Parameter(Mandatory=$true)][string]$Path, [Parameter(Mandatory=$true)]$Contracts, [Parameter(Mandatory=$true)][string]$ExtractRoot)
    $hash = Get-Sha256 $Path
    $relative = (Get-RelativePathCompat -BasePath $ExtractRoot -TargetPath $Path) -replace '\\','/'
    $strings = @(Get-AsciiStrings -Path $Path -MinimumLength 5)
    $contract = $null
    foreach ($c in $Contracts) { if ($c.sha256 -eq $hash) { $contract = $c; break } }
    $contractStatus = 'UnknownBinary'
    $missing = @()
    $contractView = $null
    if ($null -ne $contract) {
        $contractStatus = 'ExactHashMatched'
        foreach ($needle in $contract.requiredStringEvidence) {
            $found = $false
            foreach ($s in $strings) { if ($s.Contains([string]$needle)) { $found = $true; break } }
            if (-not $found) { $missing += [string]$needle }
        }
        if ($missing.Count -gt 0) { $contractStatus = 'ExactHashMatchedButStringEvidenceIncomplete' }
        $pathPresence = New-Object System.Collections.Generic.List[object]
        foreach ($driverPath in @($contract.driverPaths)) {
            $localDriverPath = ([string]$driverPath) -replace '\\', [System.IO.Path]::DirectorySeparatorChar
            $candidate = Join-Path $ExtractRoot $localDriverPath
            $pathPresence.Add([ordered]@{Path=[string]$driverPath;Present=(Test-Path -LiteralPath $candidate -PathType Leaf)}) | Out-Null
        }
        $contractView = [ordered]@{
            ContractId = if ($contract.PSObject.Properties['contractId']) { [string]$contract.contractId } else { $null }
            RoutingSemanticId = if ($contract.PSObject.Properties['routingSemanticId']) { [string]$contract.routingSemanticId } else { $null }
            EvidenceLevel = $contract.evidenceLevel
            AnalysisStatus = $contract.analysisStatus
            DeviceMatcher = $contract.deviceMatcher
            PlatformFamilies = @($contract.platformFamilies)
            OsGates = @($contract.osGates)
            DriverPaths = @($contract.driverPaths)
            DriverPathPresence = $pathPresence.ToArray()
            ObservedApiFamilies = @($contract.observedApiFamilies)
            MissingRequiredStringEvidence = @($missing)
        }
    }
    $interestingPatterns = @(
        'NPU Smart Installer', 'Windows 24 detected', 'Windows 11 MCDM OS detected',
        'Windows 11 WDF OS detected', 'Windows 11 detected', 'Windows 10 detected',
        'Installing MCDM driver', 'Installing WDF/NULL driver', 'PCI\\VEN_1022',
        'PHX platform', 'STX platform', 'Win32_OperatingSystem', 'RtlGetVersion',
        'DiInstallDriver', 'npu_mcdm_stack_prod', 'npu_wdf_stack_prod'
    )
    $observed = New-Object System.Collections.Generic.List[string]
    foreach ($s in $strings) {
        foreach ($pattern in $interestingPatterns) {
            if ($s -like "*$pattern*") { $observed.Add($s) | Out-Null; break }
        }
    }
    return [ordered]@{
        Path = $relative
        Sha256 = $hash
        ContractStatus = $contractStatus
        ExactHashContract = $contractView
        InterestingStrings = @(Get-AmdOrdinalSortedUniqueStrings -Values @($observed.ToArray()))
        EvidenceLevel = 'PayloadObserved'
        Executed = $false
        SafetyStatement = 'AMD installer was not executed.'
    }
}

function Get-DriverBinaryAnalysis {
    param(
        [Parameter(Mandatory=$true)][string]$Path,
        [Parameter(Mandatory=$true)]$Contracts,
        [Parameter(Mandatory=$true)][string]$ExtractRoot
    )
    $hash = Get-Sha256 $Path
    $relative = (Get-RelativePathCompat -BasePath $ExtractRoot -TargetPath $Path) -replace '\\','/'
    $strings = @(Get-AsciiStrings -Path $Path -MinimumLength 5)
    $contract = $null
    foreach ($c in @($Contracts)) {
        if ([string]$c.sha256 -eq $hash) { $contract = $c; break }
    }

    $contractStatus = 'UnknownBinary'
    $missing = @()
    $contractView = $null
    if ($null -ne $contract) {
        $contractStatus = 'ExactHashMatched'
        foreach ($needle in @($contract.requiredStringEvidence)) {
            $found = $false
            foreach ($value in $strings) {
                if ($value.Contains([string]$needle)) { $found = $true; break }
            }
            if (-not $found) { $missing += [string]$needle }
        }
        if ($missing.Count -gt 0) { $contractStatus = 'ExactHashMatchedButStringEvidenceIncomplete' }
        $contractView = [ordered]@{
            ContractId = [string]$contract.contractId
            FileVersionObserved = [string]$contract.fileVersionObserved
            EvidenceLevel = [string]$contract.evidenceLevel
            IdentitySemanticId = [string]$contract.identitySemanticId
            AnalysisStatus = [string]$contract.analysisStatus
            BroadPlatformMap = @($contract.broadPlatformMap)
            BroadPlatformDefaultLabel = [string]$contract.broadPlatformDefaultLabel
            CodenameRecognition = @($contract.codenameRecognition)
            FirmwareDeviceRevision = $contract.firmwareDeviceRevision
            StaticEvidence = $contract.staticEvidence
            UpstreamCorrelation = if ($contract.PSObject.Properties['upstreamCorrelation']) { $contract.upstreamCorrelation } else { $null }
            MissingRequiredStringEvidence = @($missing)
        }
    }

    $interestingPatterns = @(
        'NPU Phoenix','NPU Strix','NPU Strix Halo','NPU Krackan','NPU Krackan2',
        'NPU GorgonPoint','STX Chipset NPU','NPU Medusa','NPU Soundwave'
    )
    $observed = New-Object System.Collections.Generic.List[string]
    foreach ($value in $strings) {
        foreach ($pattern in $interestingPatterns) {
            if ($value -like "*$pattern*") { $observed.Add($value) | Out-Null; break }
        }
    }

    return [ordered]@{
        Path = $relative
        Sha256 = $hash
        ContractStatus = $contractStatus
        ExactHashContract = $contractView
        InterestingStrings = @(Get-AmdOrdinalSortedUniqueStrings -Values @($observed.ToArray()))
        EvidenceLevel = 'PayloadObserved'
        Executed = $false
        SafetyStatement = 'AMD kernel driver was not executed by the research tool.'
    }
}

function Get-PackageServerAssessment {
    param(
        [Parameter(Mandatory=$true)]$InfResults,
        [Parameter(Mandatory=$true)]$InstallerResults,
        [Parameter(Mandatory=$true)]$Profiles
    )
    $rows = New-Object System.Collections.Generic.List[object]
    $knownInstaller = $null
    if ($InstallerResults.Count -gt 0 -and $InstallerResults[0].ContractStatus -eq 'ExactHashMatched') {
        $knownInstaller = $InstallerResults[0].ExactHashContract
    }
    foreach ($profile in $Profiles) {
        $infStatus = 'Unknown'
        if ($InfResults.Count -gt 0) {
            $projection = @($InfResults[0].ServerProjection | Where-Object {$_.Server -eq $profile.name} | Select-Object -First 1)
            if ($projection.Count -gt 0) { $infStatus = $projection[0].Status }
        }
        $route = 'Unknown'
        $routePayloadPresent = $null
        if ($null -ne $knownInstaller -and [int]$profile.major -eq 10) {
            if ([int]$profile.build -ge 26100) { $route = 'MCDM' }
            elseif ([int]$profile.build -ge 22621) { $route = 'MCDM-or-WDF-by-UBR' }
            elseif ([int]$profile.build -ge 22000) { $route = 'WDF-NULL' }
            else { $route = 'Windows10/WDF-NULL' }
            if ($route -eq 'MCDM') {
                $p = @($knownInstaller.DriverPathPresence | Where-Object {$_.Path -like 'npu_mcdm_stack_prod*'} | Select-Object -First 1)
                if ($p.Count -gt 0) { $routePayloadPresent = [bool]$p[0].Present }
            }
            elseif ($route -like '*WDF*') {
                $p = @($knownInstaller.DriverPathPresence | Where-Object {$_.Path -like 'npu_wdf_stack_prod*'} | Select-Object -First 1)
                if ($p.Count -gt 0) { $routePayloadPresent = [bool]$p[0].Present }
            }
        }
        $status = 'NeedsRuntimeEvidence'
        $reason = 'Static evidence is incomplete.'
        if ($infStatus -eq 'Candidate' -and $route -eq 'MCDM' -and $routePayloadPresent -eq $true) {
            $status = 'StaticCandidateAsPublished'
            $reason = 'INF selector accepts this Server build and the exact-hash installer selects an MCDM payload that is present.'
        }
        elseif ($infStatus -like 'Rejected*' -and $routePayloadPresent -eq $false) {
            $status = 'NotApplicableAsPublished'
            $reason = 'INF selector rejects this Server profile and the installer-selected legacy WDF/NULL payload is not present in the package.'
        }
        elseif ($infStatus -like 'Rejected*') {
            $status = 'RejectedByInfAsPublished'
            $reason = 'Published INF selector rejects this Server profile.'
        }
        elseif ($routePayloadPresent -eq $false) {
            $status = 'InstallerPayloadMissing'
            $reason = 'Installer-selected payload path is not present in the package.'
        }
        $rows.Add([ordered]@{
            Server=$profile.name;Build=[int]$profile.build;InfSelectorStatus=$infStatus;
            InstallerRoute=$route;InstallerRoutePayloadPresent=$routePayloadPresent;
            StaticAssessment=$status;Reason=$reason;RuntimeProof=$false;EvidenceLevel='Analysis'
        }) | Out-Null
    }
    return $rows.ToArray()
}

function Get-PackageAnalysis {
    param([Parameter(Mandatory=$true)][string]$ArtifactPath, [string]$WorkRoot, [string]$ExtractRoot, [Parameter(Mandatory=$true)]$Profiles, [Parameter(Mandatory=$true)]$Contracts, [Parameter(Mandatory=$true)]$DriverContracts, [Parameter(Mandatory=$true)]$CompatibilityRules)
    $artifactHash = Get-Sha256 $ArtifactPath
    $id = ([System.IO.Path]::GetFileNameWithoutExtension($ArtifactPath) -replace '[^A-Za-z0-9._-]','_')
    if ([string]::IsNullOrWhiteSpace([string]$ExtractRoot)) {
        if ([string]::IsNullOrWhiteSpace([string]$WorkRoot)) { throw 'Either ExtractRoot or WorkRoot is required.' }
        $ExtractRoot = Join-Path $WorkRoot ("extract-" + $id + '-' + $artifactHash.Substring(0,12))
        if ((Get-NpuArtifactFormatFromPath -Path $ArtifactPath) -ne 'zip') { throw 'Direct compatibility extraction without the Extract stage supports ZIP only. Run the canonical Extract stage for EXE/MSI/CAB/7z artifacts.' }
        Expand-ZipStatic -ZipPath $ArtifactPath -Destination $ExtractRoot
    }
    $extractRoot = $ExtractRoot

    $fileMap = @{}
    foreach ($file in @(Get-ChildItem -LiteralPath $extractRoot -File -Recurse)) {
        $rel = (Get-RelativePathCompat -BasePath $extractRoot -TargetPath $file.FullName) -replace '\\','/'
        if ($fileMap.ContainsKey($rel)) { throw ('Duplicate extracted relative path: {0}' -f $rel) }
        $fileMap[$rel] = $file
    }
    $filesList = New-Object 'System.Collections.Generic.List[object]'
    foreach ($rel in @(Get-AmdOrdinalSortedUniqueStrings -Values @($fileMap.Keys))) {
        $filesList.Add($fileMap[$rel]) | Out-Null
    }
    $files = @($filesList.ToArray())
    $fileInventory = New-Object System.Collections.Generic.List[object]
    foreach ($file in $files) {
        $rel = (Get-RelativePathCompat -BasePath $extractRoot -TargetPath $file.FullName) -replace '\\','/'
        $fileInventory.Add([ordered]@{Path=$rel;Length=[long]$file.Length;Sha256=(Get-Sha256 $file.FullName)}) | Out-Null
    }
    $infResults = New-Object System.Collections.Generic.List[object]
    foreach ($inf in @($files | Where-Object {$_.Extension -ieq '.inf'})) {
        $infResults.Add((Get-InfAnalysis -Path $inf.FullName -Profiles $Profiles -ExtractRoot $extractRoot)) | Out-Null
    }
    $installerResults = New-Object System.Collections.Generic.List[object]
    foreach ($exe in @($files | Where-Object {$_.Name -ieq 'npu_sw_installer.exe'})) {
        $installerResults.Add((Get-InstallerAnalysis -Path $exe.FullName -Contracts $Contracts -ExtractRoot $extractRoot)) | Out-Null
    }
    $driverBinaryResults = New-Object System.Collections.Generic.List[object]
    foreach ($driverBinary in @($files | Where-Object {$_.Name -ieq 'ipustack.sys'})) {
        $driverBinaryResults.Add((Get-DriverBinaryAnalysis -Path $driverBinary.FullName -Contracts $DriverContracts -ExtractRoot $extractRoot)) | Out-Null
    }

    $driverVersions = @(Get-AmdOrdinalSortedUniqueStrings -Values @($infResults | ForEach-Object { $_.Version.DriverVersion } | Where-Object { $_ }))
    $hwids = @(Get-AmdOrdinalSortedUniqueStrings -Values @($infResults | ForEach-Object { $_.UniqueHardwareIds }))
    $serverAssessment = @(Get-PackageServerAssessment -InfResults $infResults.ToArray() -InstallerResults $installerResults.ToArray() -Profiles $Profiles)
    $publishedCompatibility = Get-PublishedCompatibilityView -ArtifactSha256 $artifactHash -Rules $CompatibilityRules
    return [ordered]@{
        SchemaVersion = '1.1'
        ToolVersion = $script:ToolVersion
        Artifact = [ordered]@{
            FileName = [System.IO.Path]::GetFileName($ArtifactPath)
            Sha256 = $artifactHash
            Length = [long](Get-Item -LiteralPath $ArtifactPath).Length
            Format = (Get-NpuArtifactFormatFromPath -Path $ArtifactPath)
            EvidenceLevel = 'PayloadObserved'
        }
        Summary = [ordered]@{
            FileCount = $files.Count
            InfCount = $infResults.Count
            InstallerCount = $installerResults.Count
            DriverBinaryCount = $driverBinaryResults.Count
            DriverVersions = $driverVersions
            HardwareIds = $hwids
        }
        Infs = $infResults.ToArray()
        Installers = $installerResults.ToArray()
        DriverBinaries = $driverBinaryResults.ToArray()
        PublishedCompatibility = $publishedCompatibility
        ServerAssessment = $serverAssessment
        Files = $fileInventory.ToArray()
        Safety = [ordered]@{VendorExecutablesExecuted=$false;VendorPayloadModified=$false;AnalysisMode='StaticOnly'}
    }
}

function Compare-PackageAnalysis {
    param($Left, $Right)
    $leftMap = @{}; foreach ($f in $Left.Files) { $leftMap[$f.Path] = $f }
    $rightMap = @{}; foreach ($f in $Right.Files) { $rightMap[$f.Path] = $f }
    $allPaths = @(Get-AmdOrdinalSortedUniqueStrings -Values @($leftMap.Keys + $rightMap.Keys))
    $identical = New-Object System.Collections.Generic.List[string]
    $changed = New-Object System.Collections.Generic.List[object]
    $onlyLeft = New-Object System.Collections.Generic.List[string]
    $onlyRight = New-Object System.Collections.Generic.List[string]
    foreach ($p in $allPaths) {
        $hasL = $leftMap.ContainsKey($p); $hasR = $rightMap.ContainsKey($p)
        if ($hasL -and -not $hasR) { $onlyLeft.Add($p) | Out-Null; continue }
        if ($hasR -and -not $hasL) { $onlyRight.Add($p) | Out-Null; continue }
        if ($leftMap[$p].Sha256 -eq $rightMap[$p].Sha256) { $identical.Add($p) | Out-Null }
        else { $changed.Add([ordered]@{Path=$p;LeftSha256=$leftMap[$p].Sha256;RightSha256=$rightMap[$p].Sha256;LeftLength=$leftMap[$p].Length;RightLength=$rightMap[$p].Length}) | Out-Null }
    }
    return [ordered]@{
        SchemaVersion='1.1'; ToolVersion=$script:ToolVersion
        Left=[ordered]@{FileName=$Left.Artifact.FileName;Sha256=$Left.Artifact.Sha256}
        Right=[ordered]@{FileName=$Right.Artifact.FileName;Sha256=$Right.Artifact.Sha256}
        Counts=[ordered]@{CommonIdentical=$identical.Count;CommonChanged=$changed.Count;OnlyLeft=$onlyLeft.Count;OnlyRight=$onlyRight.Count}
        IdenticalFiles=$identical.ToArray();ChangedFiles=$changed.ToArray();OnlyLeft=$onlyLeft.ToArray();OnlyRight=$onlyRight.ToArray()
        InstallerBinaryRelationship = if (($Left.Installers.Count -gt 0) -and ($Right.Installers.Count -gt 0) -and ($Left.Installers[0].Sha256 -eq $Right.Installers[0].Sha256)) {'ByteIdentical'} else {'DifferentOrMissing'}
        InstallerRoutingRelationship = if (($Left.Installers.Count -gt 0) -and ($Right.Installers.Count -gt 0)) {
            if ($Left.Installers[0].Sha256 -eq $Right.Installers[0].Sha256) {
                'ExactHashIdentical'
            }
            elseif (($Left.Installers[0].ContractStatus -eq 'ExactHashMatched') -and
                    ($Right.Installers[0].ContractStatus -eq 'ExactHashMatched') -and
                    ($null -ne $Left.Installers[0].ExactHashContract) -and
                    ($null -ne $Right.Installers[0].ExactHashContract) -and
                    -not [string]::IsNullOrWhiteSpace([string]$Left.Installers[0].ExactHashContract.RoutingSemanticId) -and
                    ($Left.Installers[0].ExactHashContract.RoutingSemanticId -eq $Right.Installers[0].ExactHashContract.RoutingSemanticId)) {
                'SameRecoveredRoutingSemantics'
            }
            else {
                'DifferentOrUnknown'
            }
        } else {
            'DifferentOrUnknown'
        }
        DriverBinaryRelationship = if (($Left.DriverBinaries.Count -gt 0) -and ($Right.DriverBinaries.Count -gt 0) -and ($Left.DriverBinaries[0].Sha256 -eq $Right.DriverBinaries[0].Sha256)) {'ByteIdentical'} else {'DifferentOrMissing'}
        DriverIdentityLogicRelationship = if (($Left.DriverBinaries.Count -gt 0) -and ($Right.DriverBinaries.Count -gt 0)) {
            if ($Left.DriverBinaries[0].Sha256 -eq $Right.DriverBinaries[0].Sha256) {
                'ExactHashIdentical'
            }
            elseif (($Left.DriverBinaries[0].ContractStatus -eq 'ExactHashMatched') -and
                    ($Right.DriverBinaries[0].ContractStatus -eq 'ExactHashMatched') -and
                    ($null -ne $Left.DriverBinaries[0].ExactHashContract) -and
                    ($null -ne $Right.DriverBinaries[0].ExactHashContract)) {
                $leftRefine = [bool]$Left.DriverBinaries[0].ExactHashContract.FirmwareDeviceRevision.refinementObserved
                $rightRefine = [bool]$Right.DriverBinaries[0].ExactHashContract.FirmwareDeviceRevision.refinementObserved
                if ($leftRefine -ne $rightRefine) { 'FirmwareRevisionRefinementDiffers' }
                elseif ([string]$Left.DriverBinaries[0].ExactHashContract.IdentitySemanticId -eq [string]$Right.DriverBinaries[0].ExactHashContract.IdentitySemanticId) { 'SameRecoveredIdentitySemantics' }
                else { 'DifferentRecoveredIdentitySemantics' }
            }
            else { 'DifferentOrUnknown' }
        } else {
            'DifferentOrUnknown'
        }
    }
}

function Convert-AnalysisToMarkdown {
    param($Analysis)
    $sb = New-Object System.Text.StringBuilder
    [void]$sb.AppendLine('# AMD NPU Driver Artifact Research')
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine("- Artifact: ``$($Analysis.Artifact.FileName)``")
    [void]$sb.AppendLine("- SHA-256: ``$($Analysis.Artifact.Sha256)``")
    [void]$sb.AppendLine("- Files: $($Analysis.Summary.FileCount)")
    [void]$sb.AppendLine("- Driver version(s): $([string]::Join(', ', @($Analysis.Summary.DriverVersions)))")
    [void]$sb.AppendLine("- Hardware ID(s): $([string]::Join(', ', @($Analysis.Summary.HardwareIds)))")
    [void]$sb.AppendLine('- Safety: static-only; AMD executables were not executed.')
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine('## INF analysis')
    foreach ($inf in $Analysis.Infs) {
        [void]$sb.AppendLine('')
        [void]$sb.AppendLine("### ``$($inf.Path)``")
        [void]$sb.AppendLine("- SHA-256: ``$($inf.Sha256)``")
        [void]$sb.AppendLine("- Class: ``$($inf.Version.Class)``")
        [void]$sb.AppendLine("- DriverVer: ``$($inf.Version.DriverVerRaw)``")
        [void]$sb.AppendLine("- Catalog: ``$($inf.Version.CatalogFile)``")
        [void]$sb.AppendLine("- Explicit ProductType assignment observed: **$($inf.ProductTypeAssignmentObserved)**")
        [void]$sb.AppendLine('')
        [void]$sb.AppendLine('| TargetOSVersion | Server | Build | Static selector result |')
        [void]$sb.AppendLine('|---|---:|---:|---|')
        foreach ($p in $inf.ServerProjection) { [void]$sb.AppendLine("| ``$($p.TargetOSVersion)`` | $($p.Server) | $($p.Build) | $($p.Status) |") }
        [void]$sb.AppendLine('')
        [void]$sb.AppendLine('> Static selector projection is not runtime installation proof. Installer policy, signatures, dependencies, firmware, and hardware still require separate evidence.')
    }
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine('## AMD published compatibility evidence')
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine("- Rule status: **$($Analysis.PublishedCompatibility.RuleStatus)**")
    [void]$sb.AppendLine("- Published driver label: ``$($Analysis.PublishedCompatibility.PublishedDriverLabel)``")
    [void]$sb.AppendLine("- Published supported codenames: $([string]::Join(', ', @($Analysis.PublishedCompatibility.PublishedSupportedCodenames)))")
    [void]$sb.AppendLine("- Evidence binding: **$($Analysis.PublishedCompatibility.SupportEvidence)**")
    [void]$sb.AppendLine('> Published driver label and embedded INF `DriverVer` are separate evidence dimensions and are never normalized into one value.')
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine('## Combined Windows Server static assessment')
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine('| Server | INF selector | Installer route | Route payload present | Assessment |')
    [void]$sb.AppendLine('|---|---|---|---|---|')
    foreach ($row in $Analysis.ServerAssessment) { [void]$sb.AppendLine("| $($row.Server) | $($row.InfSelectorStatus) | $($row.InstallerRoute) | $($row.InstallerRoutePayloadPresent) | **$($row.StaticAssessment)** |") }
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine('> `StaticCandidateAsPublished` is deliberately weaker than installation support. It must be confirmed on real hardware and a clean Windows Server host.')
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine('## Installer analysis')
    foreach ($installer in $Analysis.Installers) {
        [void]$sb.AppendLine('')
        [void]$sb.AppendLine("- Path: ``$($installer.Path)``")
        [void]$sb.AppendLine("- SHA-256: ``$($installer.Sha256)``")
        [void]$sb.AppendLine("- Contract: **$($installer.ContractStatus)**")
        if ($installer.ExactHashContract) {
            [void]$sb.AppendLine('- Exact-hash static contract OS gates:')
            foreach ($gate in $installer.ExactHashContract.OsGates) { [void]$sb.AppendLine("  - ``$($gate.condition)`` $($script:MarkdownRightArrow) **$($gate.action)** ($($gate.confidence))") }
            [void]$sb.AppendLine("- Device matcher: ``$($installer.ExactHashContract.DeviceMatcher.regex)``")
            [void]$sb.AppendLine("- Revision discriminator observed: **$($installer.ExactHashContract.DeviceMatcher.revisionDiscriminatorObserved)**")
        }
    }
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine('## Driver binary identity analysis')
    foreach ($driver in $Analysis.DriverBinaries) {
        [void]$sb.AppendLine('')
        [void]$sb.AppendLine("- Path: ``$($driver.Path)``")
        [void]$sb.AppendLine("- SHA-256: ``$($driver.Sha256)``")
        [void]$sb.AppendLine("- Contract: **$($driver.ContractStatus)**")
        if ($driver.ExactHashContract) {
            [void]$sb.AppendLine("- Observed file version: ``$($driver.ExactHashContract.FileVersionObserved)``")
            [void]$sb.AppendLine("- Recovered identity semantic: ``$($driver.ExactHashContract.IdentitySemanticId)``")
            [void]$sb.AppendLine("- Firmware device-revision refinement observed: **$($driver.ExactHashContract.FirmwareDeviceRevision.refinementObserved)**")
            if ($driver.ExactHashContract.FirmwareDeviceRevision.refinementObserved) {
                [void]$sb.AppendLine("- Firmware message opcode correlation: ``$($driver.ExactHashContract.FirmwareDeviceRevision.messageOpcode)``")
                [void]$sb.AppendLine("- Unknown/default revision value: ``$($driver.ExactHashContract.FirmwareDeviceRevision.defaultUnknownValue)``")
                [void]$sb.AppendLine('')
                [void]$sb.AppendLine('| Revision | Symbol | Windows label | Codename |')
                [void]$sb.AppendLine('|---:|---|---|---|')
                foreach ($entry in @($driver.ExactHashContract.FirmwareDeviceRevision.map)) {
                    [void]$sb.AppendLine("| $($entry.value) | ``$($entry.symbol)`` | $($entry.label) | $($entry.codename) |")
                }
            }
            [void]$sb.AppendLine('> Firmware-reported device revision is a separate identity layer from PCI `REV_XX`.')
        }
    }
    return $sb.ToString()
}

function Convert-ComparisonToMarkdown {
    param($Comparison)
    $sb = New-Object System.Text.StringBuilder
    [void]$sb.AppendLine('# AMD NPU Driver Release Comparison')
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine("- Left: ``$($Comparison.Left.FileName)`` / ``$($Comparison.Left.Sha256)``")
    [void]$sb.AppendLine("- Right: ``$($Comparison.Right.FileName)`` / ``$($Comparison.Right.Sha256)``")
    [void]$sb.AppendLine("- Installer binary relationship: **$($Comparison.InstallerBinaryRelationship)**")
    [void]$sb.AppendLine("- Installer recovered-routing relationship: **$($Comparison.InstallerRoutingRelationship)**")
    [void]$sb.AppendLine("- Driver binary relationship: **$($Comparison.DriverBinaryRelationship)**")
    [void]$sb.AppendLine("- Driver identity-logic relationship: **$($Comparison.DriverIdentityLogicRelationship)**")
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine('| Relationship | Count |')
    [void]$sb.AppendLine('|---|---:|')
    [void]$sb.AppendLine("| Common identical | $($Comparison.Counts.CommonIdentical) |")
    [void]$sb.AppendLine("| Common changed | $($Comparison.Counts.CommonChanged) |")
    [void]$sb.AppendLine("| Left only | $($Comparison.Counts.OnlyLeft) |")
    [void]$sb.AppendLine("| Right only | $($Comparison.Counts.OnlyRight) |")
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine('## Right-only files')
    foreach ($p in $Comparison.OnlyRight) { [void]$sb.AppendLine("- ``$p``") }
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine('## Left-only files')
    foreach ($p in $Comparison.OnlyLeft) { [void]$sb.AppendLine("- ``$p``") }
    return $sb.ToString()
}

function New-PublicationManifest {
    param([Parameter(Mandatory=$true)][string]$PublicRoot, [Parameter(Mandatory=$true)][string]$SourceScriptPath)
    $entries = New-Object System.Collections.Generic.List[object]
    $fileMap = @{}
    foreach ($file in @(Get-ChildItem -LiteralPath $PublicRoot -File -Recurse | Where-Object {$_.Name -ne 'publication-manifest.json'})) {
        $rel = (Get-RelativePathCompat -BasePath $PublicRoot -TargetPath $file.FullName) -replace '\\','/'
        if ($fileMap.ContainsKey($rel)) { throw ('Duplicate public relative path: {0}' -f $rel) }
        $fileMap[$rel] = $file
    }
    foreach ($rel in @(Get-AmdOrdinalSortedUniqueStrings -Values @($fileMap.Keys))) {
        $file = $fileMap[$rel]
        $entries.Add([ordered]@{Path=$rel;Length=[long]$file.Length;Sha256=(Get-Sha256 $file.FullName)}) | Out-Null
    }
    return [ordered]@{
        SchemaVersion='1.0'; ToolVersion=$script:ToolVersion; HandEdited=$false
        Source=[ordered]@{Path='Invoke-AmdNpuDriverResearch.ps1';Sha256=(Get-Sha256 $SourceScriptPath)}
        GeneratedFiles=$entries.ToArray()
    }
}

function Test-PublicationManifest {
    param(
        [Parameter(Mandatory=$true)][string]$PublicRoot,
        [Parameter(Mandatory=$true)][string]$SourceScriptPath
    )
    $issues = New-Object System.Collections.Generic.List[string]
    $manifestPath = Join-Path $PublicRoot 'publication-manifest.json'
    if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) {
        $issues.Add('publication-manifest.json is missing.') | Out-Null
        return $issues.ToArray()
    }
    try { $manifest = Read-AmdJsonFile -Path $manifestPath }
    catch {
        $issues.Add(('publication-manifest.json is invalid JSON: ' + $_.Exception.Message)) | Out-Null
        return $issues.ToArray()
    }
    if ($manifest.HandEdited -ne $false) { $issues.Add('Manifest HandEdited must be false.') | Out-Null }
    $actualSource = Get-Sha256 $SourceScriptPath
    if ([string]$manifest.Source.Sha256 -ne $actualSource) { $issues.Add('Manifest source SHA-256 does not match the executing script.') | Out-Null }

    $listed = @{}
    foreach ($entry in @($manifest.GeneratedFiles)) {
        $rel = ([string]$entry.Path) -replace '/', [System.IO.Path]::DirectorySeparatorChar
        $target = Join-Path $PublicRoot $rel
        $listed[[string]$entry.Path] = $true
        if (-not (Test-Path -LiteralPath $target -PathType Leaf)) {
            $issues.Add(('Manifest target missing: ' + [string]$entry.Path)) | Out-Null
            continue
        }
        $actualLength = [long](Get-Item -LiteralPath $target).Length
        $actualHash = Get-Sha256 $target
        if ($actualLength -ne [long]$entry.Length) { $issues.Add(('Length mismatch: ' + [string]$entry.Path)) | Out-Null }
        if ($actualHash -ne [string]$entry.Sha256) { $issues.Add(('SHA-256 mismatch: ' + [string]$entry.Path)) | Out-Null }
    }
    foreach ($file in @(Get-ChildItem -LiteralPath $PublicRoot -File -Recurse | Where-Object {$_.Name -ne 'publication-manifest.json'})) {
        $rel = (Get-RelativePathCompat -BasePath $PublicRoot -TargetPath $file.FullName) -replace '\\','/'
        if (-not $listed.ContainsKey($rel)) { $issues.Add(('Unmanifested public file: ' + $rel)) | Out-Null }
    }
    return $issues.ToArray()
}

function Test-PublicTree {
    param([Parameter(Mandatory=$true)][string]$PublicRoot)
    $issues = New-Object System.Collections.Generic.List[string]
    foreach ($file in @(Get-ChildItem -LiteralPath $PublicRoot -File -Recurse)) {
        $bytes = [System.IO.File]::ReadAllBytes($file.FullName)
        if ($file.Extension -in @('.md','.json','.csv')) {
            if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) { $issues.Add("UTF-8 BOM: $($file.FullName)") | Out-Null }
            for ($i=0; $i -lt $bytes.Length; $i++) {
                if ($bytes[$i] -eq 0x0D) { $issues.Add("CR byte: $($file.FullName)") | Out-Null; break }
            }
        }
        if ($file.Extension -eq '.json') {
            try { [void](Read-AmdJsonFile -Path $file.FullName) }
            catch { $issues.Add("Invalid JSON: $($file.FullName): $($_.Exception.Message)") | Out-Null }
        }
    }
    return $issues.ToArray()
}

function Test-WindowsPowerShell51SourceCompatibility {
    param([Parameter(Mandatory=$true)][string]$Path)
    $issues = New-Object System.Collections.Generic.List[string]
    $bytes = [System.IO.File]::ReadAllBytes($Path)
    if ($bytes.Length -lt 3 -or $bytes[0] -ne 0xEF -or $bytes[1] -ne 0xBB -or $bytes[2] -ne 0xBF) {
        $issues.Add('Source file must be UTF-8 with BOM so Windows PowerShell 5.1 decodes non-ASCII text deterministically.') | Out-Null
    }
    for ($i = 3; $i -lt $bytes.Length; $i++) {
        if ($bytes[$i] -eq 0x0A -and ($i -eq 0 -or $bytes[$i-1] -ne 0x0D)) {
            $issues.Add(('Source file contains LF without CR at byte offset {0}; repository .ps1 contract is CRLF.' -f $i)) | Out-Null
            break
        }
    }
    try {
        $strictUtf8 = New-Object System.Text.UTF8Encoding($true, $true)
        [void]$strictUtf8.GetString($bytes, 3, [Math]::Max(0, $bytes.Length - 3))
    }
    catch {
        $issues.Add(('Source is not valid UTF-8: {0}' -f $_.Exception.Message)) | Out-Null
    }
    return $issues.ToArray()
}

# --- staged runner / acquisition / evidence ----------------------------------
function Get-NpuUtcTimestamp { return [DateTime]::UtcNow.ToString('o') }

function Get-NpuRuntimeInformationPropertyValue {
    param([Parameter(Mandatory=$true)][string]$PropertyName)
    try {
        $runtimeType = 'System.Runtime.InteropServices.RuntimeInformation' -as [type]
        if ($null -eq $runtimeType) { return $null }
        $prop = $runtimeType.GetProperty($PropertyName, [System.Reflection.BindingFlags]'Public,Static')
        if ($null -eq $prop) { return $null }
        return $prop.GetValue($null, $null)
    }
    catch { return $null }
}

function Get-NpuPowerShellEdition {
    try {
        $prop = $PSVersionTable.PSObject.Properties['PSEdition']
        if ($null -ne $prop -and -not [string]::IsNullOrWhiteSpace([string]$prop.Value)) { return [string]$prop.Value }
    }
    catch {}
    return 'Desktop'
}

function Get-NpuPlatformInfo {
    [CmdletBinding()]
    param()

    # Horizontal implementation rule: consume the exact shared platform probe used by
    # the chipset and graphics research tools. Add only NPU-compatible normalized fields.
    $base = Get-AmdPlatformInfo
    $arch = [string]$base.OSArchitecture
    $archSource = if (-not [string]::IsNullOrWhiteSpace($arch)) { 'SharedGet-AmdPlatformInfo' } else { 'Unavailable' }
    if ([string]::IsNullOrWhiteSpace($arch)) {
        try {
            if ([Environment]::Is64BitOperatingSystem) { $arch = '64-bit' } else { $arch = '32-bit' }
            $archSource = 'Environment.Is64BitOperatingSystem'
        }
        catch { $arch = 'Unknown'; $archSource = 'Unavailable' }
    }
    return [pscustomobject][ordered]@{
        PlatformFamily = [string]$base.PlatformFamily
        OSDescription = [string]$base.OSDescription
        OSArchitecture = [string]$base.OSArchitecture
        ProcessArchitecture = [string]$base.ProcessArchitecture
        Architecture = [string]$arch
        ArchitectureSource = [string]$archSource
        DirectorySeparator = [string]$base.DirectorySeparator
        PathSeparator = [string]$base.PathSeparator
    }
}

function ConvertTo-NpuSafeFragment {
    param([AllowEmptyString()][string]$Value)
    return (ConvertTo-AmdEvidenceSafeFragment -Value $Value)
}

function New-NpuDirectory {
    param([Parameter(Mandatory=$true)][string]$Path)
    return (New-AmdDirectory -Path $Path)
}

function New-NpuZipFromDirectory {
    param([Parameter(Mandatory=$true)][string]$SourceDirectory,[Parameter(Mandatory=$true)][string]$DestinationZip)
    return (New-AmdZipFromDirectory -SourceDirectory $SourceDirectory -DestinationZip $DestinationZip)
}

# --- architecture-converged shared infrastructure kernel -------------------
# This layer intentionally contains no NPU applicability semantics. Device-specific
# behavior enters through small NPU adapters/callbacks below.
function Get-AmdResearchToolkitRoot {
    [CmdletBinding()]
    param()
    return $script:AmdResearchToolkitRoot
}

function Write-AmdJsonFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][string]$Path,
        [Parameter(Mandatory=$true)][AllowNull()][object]$Value,
        [int]$Depth = 30
    )
    $json = ConvertTo-AmdCanonicalJsonText -Value $Value -Depth $Depth
    Write-AmdUtf8NoBom -Path $Path -Text ($json + [Environment]::NewLine)
}

function ConvertTo-AmdRepositoryRelativePath {
    [CmdletBinding()]
    param([Parameter(Mandatory=$true)][string]$RelativePath)
    $normalized = ($RelativePath -replace '\\','/').TrimStart('/')
    while ($normalized -match '//') { $normalized = $normalized -replace '//','/' }
    return $normalized
}

function Write-AmdPublicMarkdownText {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][string]$Path,
        [Parameter(Mandatory=$true)][AllowEmptyString()][string]$Text
    )
    $normalized = $Text.Replace("`r`n","`n").Replace("`r","`n")
    Write-AmdUtf8NoBom -Path $Path -Text $normalized
}

function Copy-AmdPublicMarkdownFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][string]$Source,
        [Parameter(Mandatory=$true)][string]$Destination
    )
    Write-AmdPublicMarkdownText -Path $Destination -Text (Read-AmdTextFile -Path $Source)
}

function Get-AmdPublicForbiddenPatterns {
    [CmdletBinding()]
    param()
    $patterns = New-Object 'System.Collections.Generic.List[string]'
    foreach ($pattern in @('(?i)/(?:home|Users|mnt/data|tmp|var/tmp)/','(?i)[A-Z]:\\Users\\')) { $patterns.Add($pattern) }
    foreach ($candidate in @((Get-AmdResearchToolkitRoot),$HOME,$env:USERPROFILE,$env:TEMP,$env:TMP)) {
        if (-not [string]::IsNullOrWhiteSpace([string]$candidate)) {
            $patterns.Add([regex]::Escape(([string]$candidate).TrimEnd([char]'\',[char]'/')))
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
        if ($current -is [string]) { $results.Add([string]$current); continue }
        if ($current -is [System.Collections.IDictionary]) { foreach ($key in @($current.Keys)) { $stack.Push($current[$key]) }; continue }
        if ($current -is [System.Management.Automation.PSCustomObject]) { foreach ($property in @($current.PSObject.Properties)) { $stack.Push($property.Value) }; continue }
        if ($current -is [System.Collections.IEnumerable]) { foreach ($item in @($current)) { $stack.Push($item) } }
    }
    return @($results.ToArray())
}

function Test-AmdCompactJsonWhitespaceFile {
    [CmdletBinding()]
    param([Parameter(Mandatory=$true)][string]$Path)
    $text = (Read-AmdTextFile -Path $Path).Trim()
    $inString = $false; $escaped = $false
    for ($i=0; $i -lt $text.Length; $i++) {
        $c = $text[$i]
        if ($inString) {
            if ($escaped) { $escaped=$false; continue }
            if ($c -eq '\\') { $escaped=$true; continue }
            if ($c -eq '"') { $inString=$false }
            continue
        }
        if ($c -eq '"') { $inString=$true; continue }
        if ([char]::IsWhiteSpace($c)) { return $false }
    }
    return $true
}

function Test-AmdPublicRepositorySurface {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][string]$Root,
        [scriptblock]$DatasetValidator
    )
    $errors=New-Object System.Collections.Generic.List[string]
    $privacyErrors=New-Object System.Collections.Generic.List[string]
    $jsonWhitespaceErrors=New-Object System.Collections.Generic.List[string]
    $markdownFormatErrors=New-Object System.Collections.Generic.List[string]
    $jsonFileCount=0; $markdownFileCount=0
    $forbiddenPatterns=@(Get-AmdPublicForbiddenPatterns)
    if(-not (Test-Path -LiteralPath $Root -PathType Container)){$errors.Add(('public root is missing: {0}' -f $Root))|Out-Null}
    foreach($file in @(Get-ChildItem -LiteralPath $Root -File -Recurse -Force -ErrorAction SilentlyContinue)){
        if($file.Extension -notin @('.json','.csv','.md','.txt')){continue}
        $relative=ConvertTo-AmdRepositoryRelativePath -RelativePath (Get-AmdRelativePath -BasePath $Root -Path $file.FullName)
        try{$text=Read-AmdTextFile -Path $file.FullName}catch{$errors.Add(('unable to read public file {0}' -f $relative))|Out-Null;continue}
        $bytes=[IO.File]::ReadAllBytes($file.FullName)
        if($bytes.Length -ge 3 -and $bytes[0]-eq 0xEF -and $bytes[1]-eq 0xBB -and $bytes[2]-eq 0xBF){$msg=('UTF-8 BOM found in public file: {0}' -f $relative);$errors.Add($msg)|Out-Null;if($file.Extension -eq '.md'){$markdownFormatErrors.Add($msg)|Out-Null}}
        if($text.Contains("`r")){$msg=('CR/CRLF line ending found in public file: {0}' -f $relative);$errors.Add($msg)|Out-Null;if($file.Extension -eq '.md'){$markdownFormatErrors.Add($msg)|Out-Null}}
        if($file.Extension -eq '.json'){
            $jsonFileCount++
            try{
                $json=Read-AmdJsonFile -Path $file.FullName
                foreach($scalar in @(Get-AmdPublicScalarStrings -Value $json)){foreach($pattern in $forbiddenPatterns){if($scalar -match $pattern){$msg=('privacy-sensitive decoded JSON scalar found in {0}' -f $relative);$privacyErrors.Add($msg)|Out-Null;$errors.Add($msg)|Out-Null;break}}}
            }catch{$errors.Add(('invalid JSON in public file {0}: {1}' -f $relative,$_.Exception.Message))|Out-Null}
            if(-not(Test-AmdCompactJsonWhitespaceFile -Path $file.FullName)){$msg=('canonical/public JSON contains structural whitespace: {0}' -f $relative);$jsonWhitespaceErrors.Add($msg)|Out-Null;$errors.Add($msg)|Out-Null}
        } else {
            foreach($pattern in $forbiddenPatterns){if($text -match $pattern){$msg=('privacy-sensitive pattern found in {0}' -f $relative);$privacyErrors.Add($msg)|Out-Null;$errors.Add($msg)|Out-Null;break}}
            if($file.Extension -eq '.md'){$markdownFileCount++}
        }
    }
    $dataset=[pscustomobject][ordered]@{Status='Pass';ErrorCount=0;Errors=@()}
    if($DatasetValidator){
        try{$dataset=& $DatasetValidator $Root;if($null -eq $dataset){$dataset=[pscustomobject][ordered]@{Status='Fail';ErrorCount=1;Errors=@('dataset validator returned null')}}}
        catch{$dataset=[pscustomobject][ordered]@{Status='Fail';ErrorCount=1;Errors=@($_.Exception.Message)}}
        foreach($e in @($dataset.Errors)){$errors.Add([string]$e)|Out-Null}
    }
    return [pscustomobject][ordered]@{
        SchemaVersion='amd-research-publication-validation/1.0';ToolkitVersion=$script:AmdResearchToolkitVersion;GeneratedAtUtc=Get-AmdUtcTimestamp
        Status=if($errors.Count -eq 0){'Pass'}else{'Fail'};ErrorCount=$errors.Count;Errors=$errors.ToArray()
        PrivacyStatus=if($privacyErrors.Count -eq 0){'Pass'}else{'Fail'};PrivacyErrorCount=$privacyErrors.Count
        DatasetConsistencyStatus=[string]$dataset.Status;DatasetConsistencyErrorCount=[int]$dataset.ErrorCount
        JsonWhitespaceStatus=if($jsonWhitespaceErrors.Count -eq 0){'Pass'}else{'Fail'};JsonWhitespaceErrorCount=$jsonWhitespaceErrors.Count;JsonFileCount=$jsonFileCount
        MarkdownFormatStatus=if($markdownFormatErrors.Count -eq 0){'Pass'}else{'Fail'};MarkdownFormatErrorCount=$markdownFormatErrors.Count;MarkdownFileCount=$markdownFileCount
        JsonDecodedScalarValidation=$true
    }
}

function Publish-AmdRepositorySurface {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][string]$CandidateRoot,
        [Parameter(Mandatory=$true)][string]$PublicRoot,
        [Parameter(Mandatory=$true)][string]$BackupRoot
    )
    if(-not(Test-Path -LiteralPath $CandidateRoot -PathType Container)){throw('Candidate publication root is missing: {0}' -f $CandidateRoot)}
    $parent=Split-Path -Parent $PublicRoot;if($parent){New-AmdDirectory -Path $parent|Out-Null}
    if(Test-Path -LiteralPath $BackupRoot){Remove-Item -LiteralPath $BackupRoot -Recurse -Force}
    try{
        if(Test-Path -LiteralPath $PublicRoot){Move-Item -LiteralPath $PublicRoot -Destination $BackupRoot -Force}
        Move-Item -LiteralPath $CandidateRoot -Destination $PublicRoot -Force
        if(Test-Path -LiteralPath $BackupRoot){Remove-Item -LiteralPath $BackupRoot -Recurse -Force}
    } catch {
        if((Test-Path -LiteralPath $BackupRoot) -and -not(Test-Path -LiteralPath $PublicRoot)){Move-Item -LiteralPath $BackupRoot -Destination $PublicRoot -Force}
        throw
    }
    return $PublicRoot
}

function Resolve-AmdRequestedStages {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][string[]]$AvailableStages,
        [string[]]$RequestedStages=@('All'),
        [AllowNull()][string]$LegacyMode,
        [hashtable]$ModeMap=@{},
        [hashtable]$AliasMap=@{}
    )
    $requested=@($RequestedStages)
    if(-not [string]::IsNullOrWhiteSpace([string]$LegacyMode)){
        if(-not $ModeMap.ContainsKey($LegacyMode)){throw('Unsupported mode: {0}' -f $LegacyMode)}
        $requested=@($ModeMap[$LegacyMode])
    }
    $allowed=@($AvailableStages + 'All' + @($AliasMap.Keys))
    $normalized=New-Object 'System.Collections.Generic.List[string]'
    foreach($item in @($requested)){
        if($null -eq $item){continue}
        foreach($part in ([string]$item -split ',')){
            $candidate=$part.Trim();if(-not $candidate){continue}
            $aliasKey=@($AliasMap.Keys|Where-Object{$_ -ieq $candidate}|Select-Object -First 1)
            if($aliasKey.Count -gt 0){foreach($mapped in @($AliasMap[$aliasKey[0]])){if(-not $normalized.Contains([string]$mapped)){$normalized.Add([string]$mapped)|Out-Null}};continue}
            $canonical=@($allowed|Where-Object{$_ -ieq $candidate}|Select-Object -First 1)
            if($canonical.Count -eq 0){throw('Invalid stage "{0}". Allowed values: {1}' -f $candidate,($allowed -join ', '))}
            if(-not $normalized.Contains([string]$canonical[0])){$normalized.Add([string]$canonical[0])|Out-Null}
        }
    }
    if($normalized.Count -eq 0 -or $normalized.Contains('All')){return @($AvailableStages)}
    return @($normalized.ToArray())
}

function Invoke-AmdArtifactAcquisitionKernel {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][object[]]$Candidates,
        [Parameter(Mandatory=$true)][string]$InventoryRoot,
        [Parameter(Mandatory=$true)][scriptblock]$DownloadCallback,
        [switch]$ForceDownload
    )
    New-AmdDirectory -Path $InventoryRoot|Out-Null
    $results=New-Object 'System.Collections.Generic.List[object]';$paths=New-Object 'System.Collections.Generic.List[string]'
    foreach($a in @($Candidates)){
        $dest=Join-Path $InventoryRoot ([string]$a.FileName);$status=$null;$actualHash=$null;$size=$null
        try{
            $need=$true
            if((Test-Path -LiteralPath $dest -PathType Leaf) -and -not $ForceDownload){
                $actualHash=Get-AmdSha256 -Path $dest
                if([string]::IsNullOrWhiteSpace([string]$a.ExpectedSha256) -or $actualHash -eq [string]$a.ExpectedSha256){$need=$false;$status='Cached'}else{Remove-Item -LiteralPath $dest -Force}
            }
            if($need){Write-AmdStep ('Downloading {0}' -f [string]$a.FileName);$null=& $DownloadCallback ([string]$a.DownloadUrl) $dest;$status='Downloaded';$actualHash=Get-AmdSha256 -Path $dest}
            $size=[long](Get-Item -LiteralPath $dest).Length
            if(-not [string]::IsNullOrWhiteSpace([string]$a.ExpectedSha256) -and $actualHash -ne [string]$a.ExpectedSha256){throw('SHA-256 mismatch. expected={0}; actual={1}' -f [string]$a.ExpectedSha256,$actualHash)}
            if($null -ne $a.ExpectedSizeBytes -and [long]$a.ExpectedSizeBytes -gt 0 -and $size -ne [long]$a.ExpectedSizeBytes){throw('Size mismatch. expected={0}; actual={1}' -f [long]$a.ExpectedSizeBytes,$size)}
            $paths.Add($dest)|Out-Null
            $results.Add([pscustomobject][ordered]@{ArtifactId=[string]$a.ArtifactId;FileName=[string]$a.FileName;ArtifactFormat=[string]$a.ArtifactFormat;Status=$status;SourceUrl=[string]$a.DownloadUrl;LocalPath=$dest;Sha256=$actualHash;SizeBytes=$size;IntegrityStatus=if([string]::IsNullOrWhiteSpace([string]$a.ExpectedSha256)){'ObservedUnreviewed'}else{'ExactReviewedHash'};Reviewed=[bool]$a.Reviewed})|Out-Null
            Write-AmdOk ('Acquire {0} -> {1}' -f [string]$a.FileName,$status)
        } catch {
            $results.Add([pscustomobject][ordered]@{ArtifactId=[string]$a.ArtifactId;FileName=[string]$a.FileName;ArtifactFormat=[string]$a.ArtifactFormat;Status='DownloadFailed';SourceUrl=[string]$a.DownloadUrl;LocalPath=$null;Sha256=$actualHash;SizeBytes=$size;IntegrityStatus='Failed';Reviewed=[bool]$a.Reviewed;Error=$_.Exception.Message})|Out-Null
            Write-AmdFail ('Acquire {0} -> {1}' -f [string]$a.FileName,$_.Exception.Message)
        }
    }
    return [pscustomobject][ordered]@{Results=@($results.ToArray());Paths=@($paths.ToArray())}
}

function Invoke-AmdArtifactExtractionKernel {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][string[]]$ArtifactPaths,
        [Parameter(Mandatory=$true)][string]$RunRoot,
        [Parameter(Mandatory=$true)][string]$EvidenceLogRoot,
        [Parameter(Mandatory=$true)][string]$SevenZipExecutable,
        [ValidateRange(0,10)][int]$MaxDepth=5,
        [Parameter(Mandatory=$true)][scriptblock]$FormatResolver,
        [Parameter(Mandatory=$true)][scriptblock]$SurfaceProbe,
        [Parameter(Mandatory=$true)][scriptblock]$NestedArtifactPredicate
    )
    $list=New-Object 'System.Collections.Generic.List[object]';$base=Join-Path $RunRoot 'extracted';New-AmdDirectory -Path $base|Out-Null;New-AmdDirectory -Path $EvidenceLogRoot|Out-Null
    foreach($input in @($ArtifactPaths)){
        $artifactSw=[Diagnostics.Stopwatch]::StartNew();$hash=Get-AmdSha256 -Path $input;$format=& $FormatResolver $input
        $stem=ConvertTo-AmdSafeName -Value ([IO.Path]::GetFileNameWithoutExtension($input));$dest=Join-Path $base ('{0}-{1}' -f $stem,$hash.Substring(0,12));New-AmdDirectory -Path $dest|Out-Null
        $artifactLogRoot=Join-Path $EvidenceLogRoot ('{0}-{1}' -f $stem,$hash.Substring(0,12));New-AmdDirectory -Path $artifactLogRoot|Out-Null
        Write-AmdStep ('Static 7-Zip extraction: {0} ({1}); max depth={2}' -f [IO.Path]::GetFileName($input),$format,$MaxDepth)
        $queue=New-Object Collections.Queue;$queue.Enqueue([pscustomobject]@{Path=(Resolve-Path -LiteralPath $input).Path;Depth=0;Parent=$null})
        $seen=@{};$containers=New-Object 'System.Collections.Generic.List[object]';$errors=New-Object 'System.Collections.Generic.List[string]';$seq=0
        while($queue.Count -gt 0){
            $entry=$queue.Dequeue();$containerPath=[string]$entry.Path;$depth=[int]$entry.Depth;if($depth -gt $MaxDepth){continue}
            try{$containerHash=Get-AmdSha256 -Path $containerPath}catch{$errors.Add(('Hash failed for {0}: {1}' -f $containerPath,$_.Exception.Message))|Out-Null;continue}
            if($seen.ContainsKey($containerHash)){continue};$seen[$containerHash]=$true;$seq++
            $leaf=ConvertTo-AmdSafeName -Value ([IO.Path]::GetFileName($containerPath));$out=if($depth -eq 0){$dest}else{Join-Path (Join-Path $dest '_containers') ('d{0}_{1}_{2}' -f $depth,$leaf,$containerHash.Substring(0,12))};New-AmdDirectory -Path $out|Out-Null
            $probe=Get-AmdSevenZipArchiveProbe -SevenZipPath $SevenZipExecutable -Path $containerPath;$status='ExtractionFailed';$exitCode=$null;$errorText=$null;$outputText=@()
            if(-not $probe.ProbeSucceeded -or -not $probe.ContainerLike){$errorText=if($probe.Error){[string]$probe.Error}else{('7-Zip did not classify this object as an extractable container (type={0}).' -f $probe.ArchiveType)}}
            else{try{$outputText=@(& $SevenZipExecutable 'x' '-y' "-o$out" $containerPath 2>&1|ForEach-Object{[string]$_});$exitCode=$LASTEXITCODE;if($exitCode -eq 0){$status='Extracted'}elseif($exitCode -eq 1){$status='ExtractedWithWarnings'}else{$errorText=('7-Zip exit code {0}' -f $exitCode)}}catch{$errorText=$_.Exception.Message}}
            if($errorText){$errors.Add(('{0}: {1}' -f $containerPath,$errorText))|Out-Null}
            $surface=& $SurfaceProbe $out;$logPath=Join-Path $artifactLogRoot ('{0:D3}-d{1}-7zip-{2}.log' -f $seq,$depth,$containerHash.Substring(0,12))
            $log=@(('Container      : {0}' -f $containerPath),('SHA-256       : {0}' -f $containerHash),('Depth          : {0}' -f $depth),('Archive type   : {0}' -f $probe.ArchiveType),('Status         : {0}' -f $status),('7-Zip exit    : {0}' -f $exitCode),('Analysis reached: {0}' -f [bool]$surface.Reached),('Error          : {0}' -f $errorText),'')+@($outputText);Write-AmdUtf8NoBom -Path $logPath -Text ($log -join [Environment]::NewLine)
            $containers.Add([pscustomobject][ordered]@{ContainerPath=$containerPath;ContainerSha256=$containerHash;ContainerFormat=(& $FormatResolver $containerPath);Depth=$depth;ParentContainer=$entry.Parent;OutputDirectory=$out;ExtractorType='7-Zip';Status=$status;SevenZipExitCode=$exitCode;ArchiveProbe=$probe;AnalysisSurface=$surface;Error=$errorText;EvidenceLogPath=$logPath})|Out-Null
            if($status -eq 'ExtractionFailed' -or $depth -ge $MaxDepth){continue}
            foreach($f in @(Get-ChildItem -LiteralPath $out -File -Recurse -ErrorAction SilentlyContinue)){if(& $NestedArtifactPredicate $f.FullName $SevenZipExecutable){$queue.Enqueue([pscustomobject]@{Path=$f.FullName;Depth=$depth+1;Parent=$containerPath})}}
        }
        $allFiles=@(Get-ChildItem -LiteralPath $dest -File -Recurse -ErrorAction SilentlyContinue);$infs=@($allFiles|Where-Object{$_.Extension -ieq '.inf'});$surfaceFinal=& $SurfaceProbe $dest;$failed=@($containers.ToArray()|Where-Object{$_.Status -eq 'ExtractionFailed'})
        $releaseStatus=if($containers.Count -eq 0){'ExtractionFailed'}elseif($surfaceFinal.Reached -and $failed.Count -eq 0){'ExtractionComplete'}elseif($surfaceFinal.Reached){'ExtractedWithErrors'}else{'PartialExtraction'}
        if(-not $surfaceFinal.Reached){$errors.Add('No device-specific analysis surface was discovered after bounded recursive extraction.')|Out-Null};$artifactSw.Stop()
        $list.Add([pscustomobject][ordered]@{ArtifactPath=$input;FileName=[IO.Path]::GetFileName($input);ArtifactFormat=$format;Sha256=$hash;ExtractRoot=$dest;Status=$releaseStatus;FileCount=$allFiles.Count;InfFileCount=$infs.Count;NpuInfFileCount=if($surfaceFinal.PSObject.Properties['NpuInfCount']){[int]$surfaceFinal.NpuInfCount}else{0};ContainerCount=$containers.Count;Containers=@($containers.ToArray());Error=if($errors.Count){$errors -join ' | '}else{$null}})|Out-Null
        $msg=('Extract {0} -> {1}; containers={2}; files={3}; INF={4}; elapsed={5}' -f [IO.Path]::GetFileName($input),$releaseStatus,$containers.Count,$allFiles.Count,$infs.Count,(Format-AmdElapsed $artifactSw.Elapsed));if($releaseStatus -eq 'ExtractionComplete'){Write-AmdOk $msg}elseif($releaseStatus -eq 'PartialExtraction'){Write-AmdCaution $msg}else{Write-AmdFail $msg}
    }
    return @($list.ToArray())
}

function Write-AmdStageHeader {
    [CmdletBinding()]
    param([Parameter(Mandatory=$true)][string]$Name,[int]$Ordinal,[int]$Total)
    $script:AmdCurrentStageStart=Get-Date;$script:AmdCurrentStageName=$Name
    $line='='*72;Write-Host '';Write-Host $line -ForegroundColor Magenta
    if($Total -gt 0){Write-Host (' STAGE {0}/{1} - {2,-20} start: {3}' -f $Ordinal,$Total,$Name,$script:AmdCurrentStageStart.ToString('HH:mm:ss')) -ForegroundColor Magenta}else{Write-Host (' STAGE {0,-24} start: {1}' -f $Name,$script:AmdCurrentStageStart.ToString('HH:mm:ss')) -ForegroundColor Magenta}
    Write-Host (' toolkit: v{0}' -f $script:AmdResearchToolkitVersion) -ForegroundColor DarkGray;Write-Host $line -ForegroundColor Magenta
}

function Write-AmdStageFooter {
    [CmdletBinding()]
    param([Parameter(Mandatory=$true)][string]$Name,[Parameter(Mandatory=$true)][ValidateSet('PASS','FAIL','BLOCKED','SKIPPED')][string]$Status,[Parameter(Mandatory=$true)][TimeSpan]$Elapsed)
    $color=switch($Status){'PASS'{'Green'}'FAIL'{'Red'}'BLOCKED'{'Yellow'}'SKIPPED'{'DarkGray'}default{'Gray'}}
    Write-Host (' STAGE {0,-20} -> {1,-8} elapsed: {2}' -f $Name,$Status,(Format-AmdElapsed $Elapsed)) -ForegroundColor $color
    $script:AmdCurrentStageStart=$null;$script:AmdCurrentStageName=$null
}

function Write-AmdRunTimingSummary {
    [CmdletBinding()]
    param([Parameter(Mandatory=$true)][object]$Assessment)
    $totalElapsed=(Get-Date)-$script:AmdRunStartTime;Write-Host '';Write-Host ('='*72) -ForegroundColor Magenta;Write-Host ' RUN TIMING SUMMARY' -ForegroundColor Magenta;Write-Host ('='*72) -ForegroundColor Magenta
    Write-Host (' Started at      : {0}' -f $script:AmdRunStartTime.ToString('yyyy-MM-dd HH:mm:ss'));Write-Host (' Current/ended   : {0}' -f (Get-Date).ToString('yyyy-MM-dd HH:mm:ss'));Write-Host (' Total elapsed   : {0}' -f (Format-AmdElapsed $totalElapsed)) -ForegroundColor Cyan
    if($script:AmdStageResults.Count -gt 0){Write-Host '';Write-Host ' Stage timings:' -ForegroundColor Cyan;foreach($t in $script:AmdStageResults){$span=[TimeSpan]::FromMilliseconds([double]$t.DurationMilliseconds);$color=switch([string]$t.Status){'PASS'{'Green'}'FAIL'{'Red'}'BLOCKED'{'Yellow'}'SKIPPED'{'DarkGray'}default{'Gray'}};Write-Host ('   {0,-18} {1,-8} {2,12}' -f $t.Name,$t.Status,(Format-AmdElapsed $span)) -ForegroundColor $color}}
    Write-Host '';Write-Host (' Assessment      : {0}' -f $Assessment.OverallStatus);Write-Host (' Exit code       : {0}' -f $Assessment.ExitCode);Write-Host ('='*72) -ForegroundColor Magenta
}

function Start-AmdResearchEvidenceSession {
    [CmdletBinding()]
    param([string]$OutputRoot,[string]$Label,[Parameter(Mandatory=$true)][object]$InvocationParameters)
    $toolRoot=Get-AmdResearchToolkitRoot;if([string]::IsNullOrWhiteSpace($OutputRoot)){$OutputRoot=Join-Path (Join-Path (Join-Path $toolRoot 'private') 'evidence') 'runs'};New-AmdDirectory -Path $OutputRoot|Out-Null
    $platform=Get-AmdPlatformInfo;$stamp=(Get-Date).ToUniversalTime().ToString('yyyyMMdd-HHmmss');$pf=ConvertTo-AmdEvidenceSafeFragment -Value ([string]$platform.PlatformFamily);$lf=ConvertTo-AmdEvidenceSafeFragment -Value $Label
    $base=if($lf){'{0}_{1}_{2}_{3}' -f $script:AmdResearchEvidencePrefix,$stamp,$pf,$lf}else{'{0}_{1}_{2}' -f $script:AmdResearchEvidencePrefix,$stamp,$pf};$dir=Join-Path $OutputRoot $base;$zip=Join-Path $OutputRoot ($base+'.zip')
    foreach($sub in @($dir,(Join-Path $dir 'logs'),(Join-Path $dir 'errors'),(Join-Path $dir 'snapshot'))){New-AmdDirectory -Path $sub|Out-Null}
    $scriptHash=$null;try{if(Test-Path -LiteralPath $script:SourceScriptPath -PathType Leaf){$scriptHash=Get-AmdSha256 -Path $script:SourceScriptPath}}catch{}
    $ctx=[pscustomobject][ordered]@{SchemaVersion=$script:AmdResearchEvidenceSchemaVersion;ToolkitVersion=$script:AmdResearchToolkitVersion;RunId=$base;StartedAtUtc=Get-AmdUtcTimestamp;EvidenceDirectory=$dir;ZipPath=$zip;Platform=$platform;PowerShellVersion=$PSVersionTable.PSVersion.ToString();PSEdition=if($PSVersionTable.PSEdition){[string]$PSVersionTable.PSEdition}else{'Desktop'};ScriptPath=$script:SourceScriptPath;ScriptSha256=$scriptHash;InvocationParameters=$InvocationParameters;ArchiveCapability=$null;TranscriptPath=Join-Path (Join-Path $dir 'logs') 'console-transcript.txt';TranscriptStarted=$false}
    $script:AmdEvidenceContext=$ctx;$script:EvidenceContext=$ctx;Write-AmdJsonFile -Path (Join-Path $dir 'run-context.json') -Value $ctx
    try{$ctx.ArchiveCapability=Test-AmdEvidenceArchiveCapability -EvidenceDirectory $dir}catch{$ctx.ArchiveCapability=[pscustomobject][ordered]@{CollectedAtUtc=Get-AmdUtcTimestamp;ProbeAttempted=$true;ProbeSucceeded=$false;ProbeArchiveBytes=0;Error=$_.Exception.Message}}
    Write-AmdJsonFile -Path (Join-Path $dir 'archive-capability.json') -Value $ctx.ArchiveCapability
    try{Start-Transcript -LiteralPath $ctx.TranscriptPath -Force -ErrorAction Stop|Out-Null;$script:AmdTranscriptStarted=$true;$script:TranscriptStarted=$true;$ctx.TranscriptStarted=$true}catch{$script:AmdTranscriptStarted=$false;$script:TranscriptStarted=$false;$ctx.TranscriptStarted=$false;Write-AmdUtf8NoBom -Path (Join-Path (Join-Path $dir 'logs') 'transcript-start-error.txt') -Text $_.Exception.ToString()}
    Write-AmdJsonFile -Path (Join-Path $dir 'run-context.json') -Value $ctx;return $ctx
}

function Start-AmdEmergencyEvidenceSession {
    [CmdletBinding()]
    param([string]$PreferredOutputRoot,[string]$Label,[Parameter(Mandatory=$true)][object]$InvocationParameters,[string]$BootstrapError)
    if($null -ne $script:AmdEvidenceContext){return $script:AmdEvidenceContext}
    $candidateRoots=New-Object 'System.Collections.Generic.List[string]';if(-not[string]::IsNullOrWhiteSpace($PreferredOutputRoot)){$candidateRoots.Add($PreferredOutputRoot)|Out-Null};$candidateRoots.Add((Join-Path (Get-AmdResearchToolkitRoot) 'private/evidence/runs'))|Out-Null;try{if($env:TEMP){$candidateRoots.Add((Join-Path $env:TEMP 'amd-research-evidence'))|Out-Null}}catch{}
    $lastError=$null
    foreach($rootCandidate in @($candidateRoots|Select-Object -Unique)){
        try{$root=New-AmdDirectory -Path $rootCandidate;$stamp=(Get-Date).ToUniversalTime().ToString('yyyyMMdd-HHmmss');$lf=ConvertTo-AmdEvidenceSafeFragment -Value $Label;$base=if($lf){'{0}_{1}_BootstrapFatal_{2}' -f $script:AmdResearchEvidencePrefix,$stamp,$lf}else{'{0}_{1}_BootstrapFatal' -f $script:AmdResearchEvidencePrefix,$stamp};$dir=Join-Path $root $base;$zip=Join-Path $root ($base+'.zip');foreach($sub in @($dir,(Join-Path $dir 'logs'),(Join-Path $dir 'errors'),(Join-Path $dir 'snapshot'))){New-AmdDirectory -Path $sub|Out-Null};$ctx=[pscustomobject][ordered]@{SchemaVersion=$script:AmdResearchEvidenceSchemaVersion;ToolkitVersion=$script:AmdResearchToolkitVersion;RunId=$base;StartedAtUtc=Get-AmdUtcTimestamp;EvidenceDirectory=$dir;ZipPath=$zip;Platform=[pscustomobject][ordered]@{PlatformFamily='Unknown';OSDescription='UnavailableDuringBootstrap';ProcessArchitecture='Unknown';PowerShellArchitecture='Unknown'};PowerShellVersion=$PSVersionTable.PSVersion.ToString();PSEdition=if($PSVersionTable.PSEdition){[string]$PSVersionTable.PSEdition}else{'Desktop'};ScriptPath=$script:SourceScriptPath;ScriptSha256=if(Test-Path -LiteralPath $script:SourceScriptPath){Get-AmdSha256 -Path $script:SourceScriptPath}else{$null};InvocationParameters=$InvocationParameters;TranscriptPath=Join-Path (Join-Path $dir 'logs') 'console-transcript.txt';TranscriptStarted=$false;BootstrapFallback=$true};$script:AmdEvidenceContext=$ctx;$script:EvidenceContext=$ctx;Write-AmdJsonFile -Path (Join-Path $dir 'run-context.json') -Value $ctx;$lines=@('Emergency evidence session created because normal evidence bootstrap failed.',('OccurredUtc: {0}' -f (Get-AmdUtcTimestamp)));if($BootstrapError){$lines+=('BootstrapError: '+$BootstrapError)};Write-AmdUtf8NoBom -Path $ctx.TranscriptPath -Text ($lines -join [Environment]::NewLine);return $ctx}catch{$lastError=$_.Exception.ToString()}
    }
    throw('Unable to establish emergency evidence session. Last error: '+$lastError)
}

function Write-AmdStageResultsEvidence {
    [CmdletBinding()]
    param()
    if($null -eq $script:AmdEvidenceContext){return}
    $payload=[pscustomobject][ordered]@{SchemaVersion=$script:AmdResearchStageResultsSchemaVersion;ToolkitVersion=$script:AmdResearchToolkitVersion;GeneratedAtUtc=Get-AmdUtcTimestamp;StageCount=$script:AmdStageResults.Count;Stages=@($script:AmdStageResults.ToArray())}
    Write-AmdJsonFile -Path (Join-Path $script:AmdEvidenceContext.EvidenceDirectory 'stage-results.json') -Value $payload
}

function Invoke-AmdTrackedStage {
    [CmdletBinding()]
    param([Parameter(Mandatory=$true)][string]$Name,[scriptblock]$Body,[string]$BlockedReason,[string]$SkippedReason)
    $script:AmdStageOrdinal++;$script:StageOrdinal=$script:AmdStageOrdinal;Write-AmdStageHeader -Name $Name -Ordinal $script:AmdStageOrdinal -Total $script:AmdResolvedStageCount
    $started=[DateTime]::UtcNow;$sw=[Diagnostics.Stopwatch]::StartNew();$status='PASS';$errorText=$null;$errorFile=$null;$output=$null;$reason=$null
    if($BlockedReason){$status='BLOCKED';$reason=$BlockedReason;Write-AmdCaution ('Stage {0} blocked: {1}' -f $Name,$BlockedReason)}elseif($SkippedReason){$status='SKIPPED';$reason=$SkippedReason;Write-AmdSkip ('Stage {0} skipped: {1}' -f $Name,$SkippedReason)}elseif($null -eq $Body){$status='FAIL';$errorText='Tracked stage body was not supplied.';Write-AmdFail ('Stage {0} failed: {1}' -f $Name,$errorText)}else{try{$output=& $Body}catch{$status='FAIL';$errorText=$_.Exception.Message;if($script:AmdEvidenceContext){$safeName=ConvertTo-AmdEvidenceSafeFragment -Value $Name;$errorFile=Join-Path (Join-Path $script:AmdEvidenceContext.EvidenceDirectory 'errors') ('stage-{0}.txt' -f $safeName);$detail=@(('Stage      : {0}' -f $Name),('OccurredUtc: {0}' -f (Get-AmdUtcTimestamp)),('Exception  : {0}' -f $_.Exception.ToString()),('ScriptStack: {0}' -f $_.ScriptStackTrace))-join[Environment]::NewLine;Write-AmdUtf8NoBom -Path $errorFile -Text $detail};Write-AmdFail ('Stage {0} failed: {1}' -f $Name,$errorText)}}
    $sw.Stop();$summary='Completed';if($null -ne $output -and $output.PSObject.Properties['Summary']){$summary=[string]$output.Summary}
    $entry=[pscustomobject][ordered]@{Name=$Name;Status=$status;StartedAtUtc=$started.ToString('o');CompletedAtUtc=Get-AmdUtcTimestamp;DurationMilliseconds=[int64]$sw.ElapsedMilliseconds;Reason=$reason;Message=if($errorText){$errorText}elseif($reason){$reason}else{$summary};Error=$errorText;ErrorEvidencePath=$errorFile};$script:AmdStageResults.Add($entry)|Out-Null;Write-AmdStageResultsEvidence;Write-AmdStageFooter -Name $Name -Status $status -Elapsed $sw.Elapsed
    return [pscustomobject][ordered]@{Success=($status -eq 'PASS');Status=$status;Output=$output;Reason=$reason;Error=$errorText}
}

function Get-AmdRunAssessment {
    [CmdletBinding()]
    param([string[]]$ResolvedStages=@())
    $stages=@($script:AmdStageResults.ToArray());$failed=@($stages|Where-Object{$_.Status -eq 'FAIL'});$blocked=@($stages|Where-Object{$_.Status -eq 'BLOCKED'});$skipped=@($stages|Where-Object{$_.Status -eq 'SKIPPED'});$items=New-Object 'System.Collections.Generic.List[object]'
    $items.Add([pscustomobject]@{Name='StageExecution';Status=if(-not $script:TopLevelFatalError -and $failed.Count -eq 0 -and $blocked.Count -eq 0){'PASS'}else{'REVIEW'};Detail=('pass={0}; fail={1}; blocked={2}; skipped={3}; fatal={4}' -f @($stages|Where-Object{$_.Status -eq 'PASS'}).Count,$failed.Count,$blocked.Count,$skipped.Count,[bool]$script:TopLevelFatalError)})|Out-Null
    foreach($extra in @(Get-NpuRunAssessmentExtensions -ResolvedStages $ResolvedStages)){$items.Add($extra)|Out-Null}
    if($script:TopLevelFatalError){return [pscustomobject][ordered]@{SchemaVersion='amd-research-run-assessment/1.0';OverallStatus='FatalError';ExitCode=1;FailedOrBlockedStageCount=($failed.Count+$blocked.Count);Items=@($items.ToArray());FatalError=$script:TopLevelFatalError}}
    $review=($failed.Count -gt 0 -or $blocked.Count -gt 0 -or @($items.ToArray()|Where-Object{$_.Status -eq 'REVIEW'}).Count -gt 0)
    return [pscustomobject][ordered]@{SchemaVersion='amd-research-run-assessment/1.0';OverallStatus=if($review){'ReviewRequired'}else{'Pass'};ExitCode=if($review){2}else{0};FailedOrBlockedStageCount=($failed.Count+$blocked.Count);Items=@($items.ToArray());FatalError=$null}
}

function Write-AmdAssessmentConsoleReport {
    [CmdletBinding()]
    param([Parameter(Mandatory=$true)][object]$Assessment,[string]$EvidenceDirectory,[string]$ZipPath,[switch]$SkipPublicExport)
    Write-Host '';Write-Host ('='*100) -ForegroundColor Cyan;Write-Host (' {0} - FINAL ASSESSMENT' -f $script:AmdResearchDisplayName) -ForegroundColor Cyan;Write-Host ('='*100) -ForegroundColor Cyan
    foreach($item in @($Assessment.Items)){$color=if($item.Status -eq 'PASS'){'Green'}elseif($item.Status -eq 'SKIP'){'DarkGray'}else{'Yellow'};Write-Host (('[{0}]' -f $item.Status).PadRight(10)) -NoNewline -ForegroundColor $color;Write-Host ('{0,-30} {1}' -f $item.Name,$item.Detail)}
    Write-Host ('-'*100) -ForegroundColor DarkGray;Write-Host ('FINAL RESULT  : {0}' -f $Assessment.OverallStatus);Write-Host ('EXIT CODE     : {0}' -f $Assessment.ExitCode);Write-Host ('TOTAL ELAPSED : {0}' -f (Format-AmdElapsed ((Get-Date)-$script:AmdRunStartTime))) -ForegroundColor Cyan;if($EvidenceDirectory){Write-Host ('EVIDENCE DIR  : {0}' -f $EvidenceDirectory)};if($ZipPath){Write-Host ('EVIDENCE ZIP  : {0}' -f $ZipPath)};if(-not $SkipPublicExport -and $script:ResolvedPublicOutputRoot){Write-Host ('PUBLIC ROOT   : {0}' -f $script:ResolvedPublicOutputRoot)};Write-Host ('='*100) -ForegroundColor Cyan
}

function Finalize-AmdResearchEvidenceSession {
    [CmdletBinding()]
    param([string[]]$ResolvedStages=@(),[switch]$SkipArchive,[switch]$IncludePackages)
    $assessment=Get-AmdRunAssessment -ResolvedStages $ResolvedStages;if($null -eq $script:AmdEvidenceContext){return $assessment};$ctx=$script:AmdEvidenceContext;$dir=$ctx.EvidenceDirectory;$errors=New-Object 'System.Collections.Generic.List[string]'
    try{Write-AmdStageResultsEvidence;Write-AmdJsonFile -Path (Join-Path $dir 'assessment.json') -Value $assessment;$summary=[pscustomobject][ordered]@{SchemaVersion='amd-npu-driver-research-run-summary/1.2';ToolkitVersion=$script:AmdResearchToolkitVersion;RunId=$ctx.RunId;StartedAtUtc=$ctx.StartedAtUtc;CompletedAtUtc=Get-AmdUtcTimestamp;TotalDurationMilliseconds=[int64]((Get-Date)-$script:AmdRunStartTime).TotalMilliseconds;TotalDuration=Format-AmdElapsed ((Get-Date)-$script:AmdRunStartTime);StageTimings=@($script:AmdStageResults.ToArray());OverallStatus=$assessment.OverallStatus;ExitCode=$assessment.ExitCode;ScriptSha256=$ctx.ScriptSha256;InputCount=@($script:RunInputs).Count;Inputs=@($script:RunInputs|ForEach-Object{[pscustomobject][ordered]@{FileName=[IO.Path]::GetFileName($_);Sha256=if(Test-Path -LiteralPath $_){Get-AmdSha256 -Path $_}else{$null}}});IncludePackagesInEvidence=[bool]$IncludePackages;RawWorkDirectoryIncluded=$false;Safety=[pscustomobject][ordered]@{VendorExecutablesExecuted=$false;VendorPayloadModified=$false}};Write-AmdJsonFile -Path (Join-Path $dir 'run-summary.json') -Value $summary;Invoke-NpuEvidenceSnapshot -EvidenceDirectory $dir -IncludePackages:$IncludePackages}catch{$errors.Add(('summary/snapshot finalization: {0}' -f $_.Exception.ToString()))|Out-Null}
    if($script:AmdTranscriptStarted -or $script:TranscriptStarted){try{Stop-Transcript|Out-Null}catch{$errors.Add(('transcript stop: {0}' -f $_.Exception.Message))|Out-Null};$script:AmdTranscriptStarted=$false;$script:TranscriptStarted=$false}
    if($errors.Count -gt 0){try{Write-AmdUtf8NoBom -Path (Join-Path (Join-Path $dir 'errors') 'evidence-finalization-errors.txt') -Text ($errors -join ([Environment]::NewLine+[Environment]::NewLine))}catch{}}
    try{$manifestFiles=New-Object 'System.Collections.Generic.List[object]';$evidenceFileMap=@{};foreach($f in @(Get-ChildItem -LiteralPath $dir -File -Recurse -Force)){if($f.Name -eq 'evidence-manifest.json'){continue};$rel=(ConvertTo-AmdRepositoryRelativePath -RelativePath (Get-AmdRelativePath -BasePath $dir -Path $f.FullName));if($evidenceFileMap.ContainsKey($rel)){throw('Duplicate evidence relative path: {0}' -f $rel)};$evidenceFileMap[$rel]=$f};foreach($rel in @(Get-AmdOrdinalSortedUniqueStrings -Values @($evidenceFileMap.Keys))){$f=$evidenceFileMap[$rel];$manifestFiles.Add([pscustomobject][ordered]@{Path=$rel;Length=[int64]$f.Length;Sha256=Get-AmdSha256 -Path $f.FullName})|Out-Null};Write-AmdJsonFile -Path (Join-Path $dir 'evidence-manifest.json') -Value ([pscustomobject][ordered]@{SchemaVersion='amd-npu-driver-research-evidence-manifest/1.2';ToolkitVersion=$script:AmdResearchToolkitVersion;GeneratedAtUtc=Get-AmdUtcTimestamp;Files=@($manifestFiles.ToArray())})}catch{Write-Warning ('Evidence manifest creation failed: {0}' -f $_.Exception.Message)}
    if(-not $SkipArchive){try{$archive=New-AmdZipFromDirectory -SourceDirectory $dir -DestinationZip $ctx.ZipPath;if($null -eq $archive -or $archive.Length -le 0){throw 'Evidence archive is empty.'}}catch{Write-Warning ('Evidence archive creation failed: {0}' -f $_.Exception.Message)}}
    return $assessment
}

function Get-NpuRunAssessmentExtensions {
    [CmdletBinding()]
    param([string[]]$ResolvedStages=@())
    $items=New-Object 'System.Collections.Generic.List[object]'
    if($ResolvedStages -contains 'Test'){$stage=Get-NpuLatestStageResult -Name 'Test';$items.Add([pscustomobject]@{Name='ResearchEnvironment';Status=if($stage -and $stage.Status -eq 'PASS'){'PASS'}else{'REVIEW'};Detail=if($stage){[string]$stage.Message}else{'Test stage not recorded'}})|Out-Null}
    if($ResolvedStages -contains 'Acquire'){$stage=Get-NpuLatestStageResult -Name 'Acquire';$items.Add([pscustomobject]@{Name='ArtifactAcquisition';Status=if($stage -and $stage.Status -eq 'PASS'){'PASS'}elseif($stage -and $stage.Status -eq 'SKIPPED'){'SKIP'}else{'REVIEW'};Detail=if($stage){[string]$stage.Message}else{'Acquire stage not recorded'}})|Out-Null}
    if($ResolvedStages -contains 'Matrix'){$stage=Get-NpuLatestStageResult -Name 'Matrix';$items.Add([pscustomobject]@{Name='NpuCompatibilityMatrix';Status=if($stage -and $stage.Status -eq 'PASS'){'PASS'}elseif($stage -and $stage.Status -eq 'SKIPPED'){'SKIP'}else{'REVIEW'};Detail=if($stage){[string]$stage.Message}else{'Matrix stage not recorded'}})|Out-Null}
    if($ResolvedStages -contains 'Validate'){$stage=Get-NpuLatestStageResult -Name 'Validate';$items.Add([pscustomobject]@{Name='PublicationValidation';Status=if($stage -and $stage.Status -eq 'PASS'){'PASS'}elseif($stage -and $stage.Status -eq 'SKIPPED'){'SKIP'}else{'REVIEW'};Detail=if($stage){[string]$stage.Message}else{'Validate stage not recorded'}})|Out-Null}
    return @($items.ToArray())
}

function Invoke-NpuEvidenceSnapshot {
    [CmdletBinding()]
    param([Parameter(Mandatory=$true)][string]$EvidenceDirectory,[switch]$IncludePackages)
    $snap=Join-Path $EvidenceDirectory 'snapshot'
    foreach($name in @('discovery.json','release-metadata.json','acquisition.json')){Copy-NpuEvidenceFileIfPresent (Join-Path (Join-Path $PSScriptRoot 'inventory') $name) (Join-Path (Join-Path $snap 'inventory') $name)}
    Copy-NpuEvidenceFileIfPresent (Join-Path $script:ResolvedPublicOutputRoot 'publication-manifest.json') (Join-Path $snap 'public/publication-manifest.json')
    $toolSnapshot=Join-Path $snap 'tool';New-AmdDirectory -Path $toolSnapshot|Out-Null
    foreach($name in @('Invoke-AmdNpuDriverResearch.ps1','README.md','SPEC.md','TESTING.md','SOURCES.md','REVERSE-ENGINEERING-NOTES.md','PUBLICATION-POLICY.md','CHANGELOG.md','CLAUDE-AUDIT-READINESS.md','ARCHITECTURE-PARITY.md')){Copy-NpuEvidenceFileIfPresent (Join-Path $PSScriptRoot $name) (Join-Path $toolSnapshot $name)}
    Copy-NpuEvidenceTreeIfPresent (Join-Path $PSScriptRoot 'data') (Join-Path $toolSnapshot 'data');Copy-NpuEvidenceTreeIfPresent (Join-Path $PSScriptRoot 'schemas') (Join-Path $toolSnapshot 'schemas');Copy-NpuEvidenceTreeIfPresent (Join-Path (Join-Path (Join-Path $PSScriptRoot 'private') 'evidence') 'extraction-logs') (Join-Path $snap 'extraction-logs')
    if($IncludePackages){foreach($ip in @($script:RunInputs)){if(Test-Path -LiteralPath $ip -PathType Leaf){Copy-NpuEvidenceFileIfPresent $ip (Join-Path (Join-Path $snap 'packages') ([IO.Path]::GetFileName($ip)))}}}
}

function Test-NpuPublicDatasetConsistency {
    [CmdletBinding()]
    param([Parameter(Mandatory=$true)][string]$Root)
    $errors=New-Object 'System.Collections.Generic.List[string]'
    foreach($required in @('catalog/hardware-identities.json','catalog/processor-catalog.json','catalog/observed-runtime-evidence.json','catalog/driver-compatibility-matrix.json','catalog/processor-driver-applicability.json','catalog/processor-driver-applicability.md','publication-manifest.json')){
        if(-not(Test-Path -LiteralPath (Join-Path $Root ($required -replace '/', [IO.Path]::DirectorySeparatorChar)) -PathType Leaf)){$errors.Add(('required public file missing: {0}' -f $required))|Out-Null}
    }
    $releaseJson=@(Get-ChildItem -LiteralPath (Join-Path $Root 'releases') -Filter '*.json' -File -ErrorAction SilentlyContinue)
    $releaseMd=@(Get-ChildItem -LiteralPath (Join-Path $Root 'releases') -Filter '*.md' -File -ErrorAction SilentlyContinue)
    if($releaseJson.Count -ne $releaseMd.Count){$errors.Add(('release JSON/Markdown count mismatch: json={0}; md={1}' -f $releaseJson.Count,$releaseMd.Count))|Out-Null}
    $comparisonJson=@(Get-ChildItem -LiteralPath (Join-Path $Root 'comparisons') -Filter '*.json' -File -ErrorAction SilentlyContinue)
    $comparisonMd=@(Get-ChildItem -LiteralPath (Join-Path $Root 'comparisons') -Filter '*.md' -File -ErrorAction SilentlyContinue)
    if($comparisonJson.Count -ne $comparisonMd.Count){$errors.Add(('comparison JSON/Markdown count mismatch: json={0}; md={1}' -f $comparisonJson.Count,$comparisonMd.Count))|Out-Null}

    $processorPath=Join-Path $Root 'catalog/processor-catalog.json'
    $matrixPath=Join-Path $Root 'catalog/driver-compatibility-matrix.json'
    $applicabilityPath=Join-Path $Root 'catalog/processor-driver-applicability.json'
    if((Test-Path -LiteralPath $processorPath -PathType Leaf) -and (Test-Path -LiteralPath $matrixPath -PathType Leaf) -and (Test-Path -LiteralPath $applicabilityPath -PathType Leaf)){
        try{
            $processors=Read-AmdJsonFile -Path $processorPath
            $matrix=Read-AmdJsonFile -Path $matrixPath
            $applicability=Read-AmdJsonFile -Path $applicabilityPath
            if([string]$processors.SchemaVersion -ne '1.3'){$errors.Add(('processor catalog public schema mismatch: {0}' -f [string]$processors.SchemaVersion))|Out-Null}
            if([string]$applicability.SchemaVersion -ne '1.0'){$errors.Add(('processor-driver applicability public schema mismatch: {0}' -f [string]$applicability.SchemaVersion))|Out-Null}
            if([int]$applicability.ProcessorCount -ne @($processors.Processors).Count){$errors.Add(('applicability ProcessorCount mismatch: applicability={0}; processors={1}' -f [int]$applicability.ProcessorCount,@($processors.Processors).Count))|Out-Null}
            if(@($applicability.Rows).Count -ne @($processors.Processors).Count){$errors.Add(('applicability row count mismatch: applicability={0}; processors={1}' -f @($applicability.Rows).Count,@($processors.Processors).Count))|Out-Null}
            $privateReleaseIds=@($applicability.Releases|Where-Object{[string]$_.Visibility -eq 'PrivateQualification'}|ForEach-Object{[string]$_.ReleaseId})
            foreach($release in @($applicability.Releases)){
                if([string]$release.Visibility -eq 'PrivateQualification' -and [bool]$release.RecommendationEligible){$errors.Add(('private release is recommendation eligible: {0}' -f [string]$release.ReleaseId))|Out-Null}
            }
            foreach($processor in @($processors.Processors)){
                $processorKey=[string]$processor.processorId
                $rows=@($applicability.Rows|Where-Object{[string]$_.ProcessorId -eq $processorKey})
                if($rows.Count -ne 1){$errors.Add(('processor must have exactly one applicability row: {0}; count={1}' -f $processorKey,$rows.Count))|Out-Null;continue}
                $row=$rows[0]
                if([bool]$row.Evidence.ServerRuntimeProof){$errors.Add(('applicability row must not claim Windows Server runtime proof: {0}' -f $processorKey))|Out-Null}
                if($null -eq $row.Evidence.ObservedEvidenceIds){$errors.Add(('applicability observed-evidence IDs must be an array, not null: {0}' -f $processorKey))|Out-Null}
                elseif(@($row.Evidence.ObservedEvidenceIds | Where-Object { $null -eq $_ -or [string]::IsNullOrWhiteSpace([string]$_) }).Count -gt 0){$errors.Add(('applicability observed-evidence IDs contain null/blank values: {0}' -f $processorKey))|Out-Null}
                if(@($row.DriverApplicability).Count -ne @($applicability.Releases).Count){$errors.Add(('driver applicability release count mismatch: {0}' -f $processorKey))|Out-Null}
                if($row.RecommendedReleaseId -and $privateReleaseIds -contains [string]$row.RecommendedReleaseId){$errors.Add(('private qualification release was recommended: {0} -> {1}' -f $processorKey,[string]$row.RecommendedReleaseId))|Out-Null}
                $selection=@($matrix.Selections|Where-Object{[string]$_.ProcessorId -eq $processorKey})
                if($selection.Count -ne 1){$errors.Add(('compatibility matrix selection missing/duplicate: {0}' -f $processorKey))|Out-Null}
                else{
                    if([string]$row.RecommendationDecision -ne [string]$selection[0].Decision){$errors.Add(('recommendation decision drift: {0}; applicability={1}; matrix={2}' -f $processorKey,[string]$row.RecommendationDecision,[string]$selection[0].Decision))|Out-Null}
                    if([string]$row.RecommendedArtifact -ne [string]$selection[0].RecommendedArtifact){$errors.Add(('recommended artifact drift: {0}; applicability={1}; matrix={2}' -f $processorKey,[string]$row.RecommendedArtifact,[string]$selection[0].RecommendedArtifact))|Out-Null}
                }
            }
        }catch{$errors.Add(('processor-driver applicability cross-dataset validation failed: {0}' -f $_.Exception.Message))|Out-Null}
    }
    return [pscustomobject][ordered]@{Status=if($errors.Count -eq 0){'Pass'}else{'Fail'};ErrorCount=$errors.Count;Errors=@($errors.ToArray());ReleaseCount=$releaseJson.Count;ComparisonCount=$comparisonJson.Count}
}

function Test-NpuArchitectureConvergenceContract {
    [CmdletBinding()]
    param()
    $path=Join-Path $PSScriptRoot 'data/architecture-convergence-contract.json';if(-not(Test-Path -LiteralPath $path -PathType Leaf)){return @('architecture-convergence-contract.json is missing.')}
    $contract=Read-AmdJsonFile -Path $path;$issues=New-Object 'System.Collections.Generic.List[string]';$tokens=$null;$parseErrors=$null;$ast=[Management.Automation.Language.Parser]::ParseFile($script:SourceScriptPath,[ref]$tokens,[ref]$parseErrors);if($parseErrors.Count){$issues.Add('Unable to parse executing script for architecture contract validation.')|Out-Null;return @($issues.ToArray())}
    $functions=@($ast.FindAll({param($n)$n -is [Management.Automation.Language.FunctionDefinitionAst]},$true));$lookup=@{};foreach($f in $functions){$lookup[$f.Name]=$f}
    foreach($entry in @($contract.genericKernelFunctions)){if(-not $lookup.ContainsKey([string]$entry.name)){$issues.Add(('Generic kernel function missing: {0}' -f [string]$entry.name))|Out-Null;continue};$text=$lookup[[string]$entry.name].Extent.Text -replace "`r`n","`n" -replace "`r","`n";$hash=Get-AmdStringSha256 -Text $text;if($hash -ne [string]$entry.sha256){$issues.Add(('Generic kernel function hash mismatch: {0}' -f [string]$entry.name))|Out-Null}}
    foreach($legacy in @($contract.forbiddenLegacyInfrastructureFunctions)){if($lookup.ContainsKey([string]$legacy)){$issues.Add(('Legacy NPU infrastructure function must not exist: {0}' -f [string]$legacy))|Out-Null}}
    foreach($adapter in @($contract.requiredNpuAdapterFunctions)){if(-not $lookup.ContainsKey([string]$adapter)){$issues.Add(('Required NPU adapter function missing: {0}' -f [string]$adapter))|Out-Null}}
    return @($issues.ToArray())
}










function Get-NpuLatestStageResult { param([string]$Name);$m=@($script:StageResults.ToArray()|Where-Object{$_.Name -eq $Name});if($m.Count){return $m[$m.Count-1]};return $null }
function Test-NpuStagePassed { param([string]$Name);$e=Get-NpuLatestStageResult $Name;return($null -ne $e -and [string]$e.Status -eq 'PASS') }
function Get-NpuStageDependencyBlockReason {
    [CmdletBinding()]
    param([string]$Name,[string[]]$ResolvedStages,[string[]]$PackagePath=@())
    $deps=@{
        HardwareIdentity=@('Test')
        ProcessorCatalog=@('Test','HardwareIdentity')
        Discover=@('Test')
        Metadata=@('Discover')
        Acquire=if($PackagePath.Count -gt 0){@('Test')}else{@('Metadata')}
        Extract=@('Acquire')
        Inspect=@('Extract')
        DriverBinary=@('Inspect')
        Compare=@('Inspect')
        Matrix=@('Inspect','HardwareIdentity','ProcessorCatalog')
        Build=@('Inspect','Matrix')
        Validate=@('Build')
    }
    if(-not $deps.ContainsKey($Name)){return $null}
    foreach($d in @($deps[$Name])){
        if($ResolvedStages -notcontains $d){
            return('Blocked because prerequisite stage {0} was not selected for this run.' -f $d)
        }
        $e=Get-NpuLatestStageResult $d
        if($null -eq $e){
            return('Blocked because prerequisite stage {0} has no execution result.' -f $d)
        }
        if([string]$e.Status -ne 'PASS'){return('Blocked because prerequisite stage {0} ended with status {1}.' -f $d,[string]$e.Status)}
    }
    return $null
}

function Test-NpuPredecessorParityContract {
    [CmdletBinding()]
    param([string[]]$Stages=@('All'),[string]$Mode)

    $issues = New-Object 'System.Collections.Generic.List[string]'
    $contract = $script:PredecessorCoreContractDoc
    if ($null -eq $contract) {
        $contractPath = Join-Path $PSScriptRoot 'data/predecessor-shared-core-contract.json'
        if (-not (Test-Path -LiteralPath $contractPath -PathType Leaf)) {
            $issues.Add('Predecessor shared-core contract is missing.') | Out-Null
            return @($issues.ToArray())
        }
        try { $contract = Read-AmdJsonFile -Path $contractPath }
        catch {
            $issues.Add(('Predecessor shared-core contract cannot be read: {0}' -f $_.Exception.Message)) | Out-Null
            return @($issues.ToArray())
        }
    }

    $tokens = $null
    $parseErrors = $null
    try {
        $ast = [System.Management.Automation.Language.Parser]::ParseFile($script:SourceScriptPath,[ref]$tokens,[ref]$parseErrors)
    }
    catch {
        $issues.Add(('Unable to parse current NPU source for predecessor parity verification: {0}' -f $_.Exception.Message)) | Out-Null
        return @($issues.ToArray())
    }
    if (@($parseErrors).Count -gt 0) {
        $issues.Add(('Current NPU source has {0} parser error(s) during predecessor parity verification.' -f @($parseErrors).Count)) | Out-Null
        return @($issues.ToArray())
    }

    $functionMap = @{}
    foreach ($fn in @($ast.FindAll({ param($node) $node -is [System.Management.Automation.Language.FunctionDefinitionAst] },$true))) {
        $functionMap[[string]$fn.Name] = [string]$fn.Extent.Text
    }

    foreach ($entry in @($contract.functions)) {
        $name = [string]$entry.name
        if (-not $functionMap.ContainsKey($name)) {
            $issues.Add(('Shared predecessor infrastructure function missing: {0}' -f $name)) | Out-Null
            continue
        }
        $normalized = ([string]$functionMap[$name]) -replace "`r`n","`n" -replace "`r","`n"
        $actualHash = Get-AmdStringSha256 -Text $normalized
        if ($actualHash -ne ([string]$entry.sha256).ToLowerInvariant()) {
            $issues.Add(('Shared predecessor infrastructure function drifted from reviewed contract: {0}' -f $name)) | Out-Null
        }
    }
    if ([int]$contract.functionCount -ne @($contract.functions).Count) {
        $issues.Add('Predecessor shared-core contract functionCount does not match its function list.') | Out-Null
    }

    $platform=$null
    try { $platform=Get-AmdPlatformInfo }
    catch { $issues.Add(('Shared platform probe failed: {0}' -f $_.Exception.Message)) | Out-Null }
    if($null -ne $platform){
        foreach($propName in @('PlatformFamily','OSDescription','OSArchitecture','ProcessArchitecture','DirectorySeparator','PathSeparator')){
            if($null -eq $platform.PSObject.Properties[$propName]){$issues.Add(('Shared platform probe property missing: {0}' -f $propName))|Out-Null}
        }
    }

    $resolved=$null
    try{$resolved=@(Resolve-NpuRequestedStages -Stages $Stages -Mode $Mode)}catch{$issues.Add(('Stage resolver self-test failed: {0}' -f $_.Exception.Message))|Out-Null}
    if($null -ne $resolved -and $Stages.Count -eq 1 -and $Stages[0] -eq 'All' -and [string]::IsNullOrWhiteSpace([string]$Mode)){
        foreach($required in @('Test','Discover','Metadata','Acquire','Extract','Inspect','Build','Validate')){
            if($resolved -notcontains $required){$issues.Add(('Default Full workflow missing predecessor-parity stage: {0}' -f $required))|Out-Null}
        }
    }
    return @($issues.ToArray())
}



function Copy-NpuEvidenceFileIfPresent { param([string]$Source,[string]$Destination);if(Test-Path -LiteralPath $Source -PathType Leaf){$parent=Split-Path -Parent $Destination;if($parent){New-NpuDirectory $parent|Out-Null};Copy-Item -LiteralPath $Source -Destination $Destination -Force} }
function Copy-NpuEvidenceTreeIfPresent { param([string]$Source,[string]$Destination);if(Test-Path -LiteralPath $Source -PathType Container){New-NpuDirectory $Destination|Out-Null;foreach($f in @(Get-ChildItem -LiteralPath $Source -File -Recurse -Force)){ $rel=Get-RelativePathCompat -BasePath $Source -TargetPath $f.FullName;$dest=Join-Path $Destination $rel;$parent=Split-Path -Parent $dest;if($parent){New-NpuDirectory $parent|Out-Null};Copy-Item -LiteralPath $f.FullName -Destination $dest -Force}} }



function Test-NpuAllowedDownloadUri { param([string]$Uri);try{$u=[Uri]$Uri;return($u.Scheme -eq 'https' -and (Test-AmdAllowedDownloadHost -Uri $Uri))}catch{return $false} }

function Invoke-NpuWebRequestToFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][string]$Uri,
        [Parameter(Mandatory=$true)][string]$Destination,
        [int]$RetryCount=3,
        [int]$TimeoutSeconds=180,
        [switch]$AllowNonAmdHost
    )
    if (-not $AllowNonAmdHost) {
        if (-not (Test-NpuAllowedDownloadUri -Uri $Uri)) { throw ('Rejected non-AMD HTTPS download host: {0}' -f $Uri) }
    }
    Enable-AmdTls12ForWindowsPowerShell
    $partial = $Destination + '.partial'
    Remove-Item -LiteralPath $partial -Force -ErrorAction SilentlyContinue
    $errors = New-Object 'System.Collections.Generic.List[string]'
    for ($attempt=1; $attempt -le $RetryCount; $attempt++) {
        try {
            Write-AmdDetail ('download attempt {0}/{1}: {2}' -f $attempt,$RetryCount,$Uri)
            $downloadResult = Invoke-AmdQuietFileDownload -Uri $Uri -OutFile $partial -TimeoutSec $TimeoutSeconds
            if (-not $downloadResult.Success) { throw ([string]$downloadResult.Error) }
            if (-not (Test-Path -LiteralPath $partial -PathType Leaf)) { throw 'Download did not create a partial file.' }
            $length = [int64](Get-Item -LiteralPath $partial).Length
            if ($length -le 0) { throw 'Downloaded file is empty.' }
            Move-Item -LiteralPath $partial -Destination $Destination -Force
            return (Get-Item -LiteralPath $Destination)
        }
        catch {
            $errors.Add(('attempt {0}: {1}' -f $attempt,(Get-AmdCompactErrorMessage -Message $_.Exception.Message -MaximumLength 400))) | Out-Null
            Remove-Item -LiteralPath $partial -Force -ErrorAction SilentlyContinue
            if ($attempt -lt $RetryCount) { Start-Sleep -Seconds ([Math]::Min(5,$attempt)) }
        }
    }
    throw ('Download failed after {0} attempt(s): {1} : {2}' -f $RetryCount,$Uri,($errors -join ' | '))
}

function Invoke-NpuDiscoveryStage {
    [CmdletBinding()]
    param(
        [string[]]$DocumentationUri=@('https://ryzenai.docs.amd.com/en/latest/inst.html'),
        [string[]]$AdditionalDriverUrl=@(),
        [int]$DownloadTimeoutSeconds=180,
        [switch]$AllowNonAmdHost
    )

    if ($null -eq $script:ArtifactCatalogDoc) {
        $script:ArtifactCatalogDoc = Get-ReviewedJsonDocument (Join-Path $PSScriptRoot 'data/published-driver-artifacts.json')
    }

    $sources = New-Object 'System.Collections.Generic.List[string]'
    foreach ($u in @($DocumentationUri)) {
        if (-not [string]::IsNullOrWhiteSpace([string]$u) -and -not $sources.Contains([string]$u)) { $sources.Add([string]$u) | Out-Null }
    }
    $catalogDocUrl = [string]$script:ArtifactCatalogDoc.discovery.documentationUrl
    if (-not [string]::IsNullOrWhiteSpace($catalogDocUrl) -and -not $sources.Contains($catalogDocUrl)) { $sources.Add($catalogDocUrl) | Out-Null }

    $sourceResults = New-Object 'System.Collections.Generic.List[object]'
    $observed = New-Object 'System.Collections.Generic.List[string]'
    $pattern = 'https://download\.amd\.com/opendownload/RyzenAI/Driver/[A-Za-z0-9._-]+\.(?:zip|exe|msi|cab|7z)'
    foreach ($sourceUri in @($sources.ToArray())) {
        if (-not $AllowNonAmdHost -and -not (Test-AmdAllowedDownloadHost -Uri $sourceUri)) {
            $sourceResults.Add([pscustomobject][ordered]@{Uri=$sourceUri;Status='RejectedHost';StatusCode=$null;ResponseUri=$null;ObservedLinkCount=0;Error='Source host is outside amd.com.'}) | Out-Null
            continue
        }
        $probe = Invoke-AmdQuietTextRequest -Uri $sourceUri -TimeoutSec $DownloadTimeoutSeconds
        if ($probe.Success) {
            $links = @(Get-AmdOrdinalSortedUniqueStrings -Values @([regex]::Matches([string]$probe.Content,$pattern,[Text.RegularExpressions.RegexOptions]::IgnoreCase) | ForEach-Object { $_.Value }))
            foreach ($link in $links) { if (-not $observed.Contains([string]$link)) { $observed.Add([string]$link) | Out-Null } }
            $sourceResults.Add([pscustomobject][ordered]@{Uri=$sourceUri;Status='Fetched';StatusCode=$probe.StatusCode;ResponseUri=$probe.ResponseUri;ObservedLinkCount=$links.Count;Error=$null}) | Out-Null
        }
        else {
            $sourceResults.Add([pscustomobject][ordered]@{Uri=$sourceUri;Status='Unavailable';StatusCode=$probe.StatusCode;ResponseUri=$probe.ResponseUri;ObservedLinkCount=0;Error=$probe.Error}) | Out-Null
        }
    }

    foreach ($url in @($AdditionalDriverUrl)) {
        if ([string]::IsNullOrWhiteSpace([string]$url)) { continue }
        if (-not $AllowNonAmdHost -and -not (Test-NpuAllowedDownloadUri -Uri $url)) { throw ('AdditionalDriverUrl is not an approved AMD HTTPS URL: {0}' -f $url) }
        if (-not $observed.Contains([string]$url)) { $observed.Add([string]$url) | Out-Null }
    }

    $doc = [pscustomobject][ordered]@{
        SchemaVersion='amd-npu-driver-discovery/1.1'
        ToolkitVersion=$script:ToolVersion
        GeneratedAtUtc=Get-AmdUtcTimestamp
        Sources=@($sourceResults.ToArray())
        ObservedDownloadUrls=@(Get-AmdOrdinalSortedUniqueStrings -Values @($observed.ToArray()))
        ReviewedArtifactCount=@($script:ArtifactCatalogDoc.artifacts).Count
        Summary=('sources={0}; fetched={1}; observedLinks={2}; reviewedArtifacts={3}' -f $sourceResults.Count,@($sourceResults.ToArray()|Where-Object{$_.Status -eq 'Fetched'}).Count,$observed.Count,@($script:ArtifactCatalogDoc.artifacts).Count)
    }
    Write-JsonFile -Value $doc -Path (Join-Path $PSScriptRoot 'inventory/discovery.json')
    return $doc
}

function Invoke-NpuMetadataStage {
    [CmdletBinding()]
    param([AllowNull()]$Discovery,[string[]]$ArtifactId=@(),[string[]]$PackagePath=@())

    if ($null -eq $script:ArtifactCatalogDoc) {
        $script:ArtifactCatalogDoc = Get-ReviewedJsonDocument (Join-Path $PSScriptRoot 'data/published-driver-artifacts.json')
    }
    $observedUrls = @()
    if ($null -ne $Discovery -and $Discovery.PSObject.Properties['ObservedDownloadUrls']) { $observedUrls = @($Discovery.ObservedDownloadUrls) }
    $observedByName = @{}
    foreach ($url in $observedUrls) {
        try { $observedByName[[IO.Path]::GetFileName(([Uri][string]$url).AbsolutePath)] = [string]$url } catch { }
    }

    $records = New-Object 'System.Collections.Generic.List[object]'
    $seen = @{}
    foreach ($artifact in @($script:ArtifactCatalogDoc.artifacts)) {
        $name = [string]$artifact.fileName
        $observedNow = $observedByName.ContainsKey($name)
        $selected = if ($ArtifactId.Count -gt 0) { $ArtifactId -contains [string]$artifact.artifactId } else { [bool]$artifact.defaultAcquire }
        $records.Add([pscustomobject][ordered]@{
            ArtifactId=[string]$artifact.artifactId;FileName=$name;ArtifactFormat=[string]$artifact.artifactFormat;DownloadUrl=[string]$artifact.downloadUrl
            ExpectedSha256=[string]$artifact.expectedSha256;ExpectedSizeBytes=$artifact.expectedSizeBytes
            PublishedDriverLabel=[string]$artifact.publishedDriverLabel;SourceStatus=[string]$artifact.sourceStatus
            ObservedOnCurrentDocumentation=$observedNow;SelectedForAcquisition=[bool]$selected;Reviewed=$true
        }) | Out-Null
        $seen[$name]=$true
    }
    foreach ($url in $observedUrls) {
        $name=$null;try{$name=[IO.Path]::GetFileName(([Uri][string]$url).AbsolutePath)}catch{continue}
        if ([string]::IsNullOrWhiteSpace($name) -or $seen.ContainsKey($name)) { continue }
        $id='discovered-'+($name -replace '[^A-Za-z0-9._-]','-')
        $selected = if ($ArtifactId.Count -gt 0) { $ArtifactId -contains $id } else { $true }
        $records.Add([pscustomobject][ordered]@{
            ArtifactId=$id;FileName=$name;ArtifactFormat=(Get-NpuArtifactFormatFromPath -Path $name);DownloadUrl=[string]$url;ExpectedSha256=$null;ExpectedSizeBytes=$null
            PublishedDriverLabel=$null;SourceStatus='DiscoveredUnreviewed';ObservedOnCurrentDocumentation=$true
            SelectedForAcquisition=[bool]$selected;Reviewed=$false
        }) | Out-Null
        $seen[$name]=$true
    }

    if ($ArtifactId.Count -gt 0) {
        $knownIds=@($records.ToArray()|ForEach-Object{[string]$_.ArtifactId})
        foreach($requested in @($ArtifactId)){if($knownIds -notcontains [string]$requested){throw('Requested ArtifactId was not discovered or reviewed: {0}' -f $requested)}}
    }
    $selectedRecords=@(Get-AmdOrdinalSortedObjectsByStringProperty -Values @($records.ToArray()|Where-Object{$_.SelectedForAcquisition}) -PropertyName 'FileName')
    if ($PackagePath.Count -eq 0 -and $selectedRecords.Count -eq 0) { throw 'Metadata selection produced zero acquisition candidates.' }
    $doc=[pscustomobject][ordered]@{
        SchemaVersion='amd-npu-driver-release-metadata/1.0';ToolkitVersion=$script:ToolVersion;GeneratedAtUtc=Get-AmdUtcTimestamp
        Records=@(Get-AmdOrdinalSortedObjectsByStringProperty -Values @($records.ToArray()) -PropertyName 'FileName');SelectedCount=$selectedRecords.Count
        Summary=('records={0}; selected={1}; reviewed={2}; unreviewed={3}' -f $records.Count,$selectedRecords.Count,@($records.ToArray()|Where-Object{$_.Reviewed}).Count,@($records.ToArray()|Where-Object{-not $_.Reviewed}).Count)
    }
    $script:ReleaseMetadataDoc=$doc
    Write-JsonFile -Value $doc -Path (Join-Path $PSScriptRoot 'inventory/release-metadata.json')
    return $doc
}

function Test-NpuPublishedArtifactCatalog {
    param([Parameter(Mandatory=$true)]$Catalog,[switch]$AllowNonAmdHost)
    $issues=New-Object System.Collections.Generic.List[string];$ids=@{};$files=@{}
    if([string]$Catalog.schemaVersion -ne 'amd-npu-published-driver-artifacts/1.1'){$issues.Add('Unexpected published-driver-artifacts schemaVersion.')|Out-Null}
    if([string]::IsNullOrWhiteSpace([string]$Catalog.discovery.documentationUrl)){$issues.Add('Discovery documentationUrl is missing.')|Out-Null}
    foreach($a in @($Catalog.artifacts)){
        $id=[string]$a.artifactId;$name=[string]$a.fileName;$url=[string]$a.downloadUrl;$hash=[string]$a.expectedSha256
        if([string]::IsNullOrWhiteSpace($id)){$issues.Add('Artifact entry missing artifactId.')|Out-Null}elseif($ids.ContainsKey($id)){$issues.Add("Duplicate artifactId: $id")|Out-Null}else{$ids[$id]=$true}
        if([string]::IsNullOrWhiteSpace($name) -or -not (Test-NpuSupportedArtifactPath -Path $name)){$issues.Add("Invalid or unsupported artifact filename: $name")|Out-Null}elseif($files.ContainsKey($name)){$issues.Add("Duplicate artifact filename: $name")|Out-Null}else{$files[$name]=$true}
        if(-not $AllowNonAmdHost -and -not(Test-NpuAllowedDownloadUri $url)){$issues.Add("Reviewed artifact URL is not an approved AMD HTTPS download URL: $url")|Out-Null}
        if([string]$a.artifactFormat -ne (Get-NpuArtifactFormatFromPath -Path $name)){$issues.Add("artifactFormat does not match filename extension for $id")|Out-Null}
        if(-not [string]::IsNullOrWhiteSpace($hash) -and $hash -notmatch '^[0-9a-f]{64}$'){$issues.Add("Invalid expected SHA-256 for $id")|Out-Null}
        if($null -ne $a.expectedSizeBytes -and [long]$a.expectedSizeBytes -lt 1){$issues.Add("Invalid expected size for $id")|Out-Null}
    }
    if(@($Catalog.artifacts|Where-Object{$_.defaultAcquire -eq $true}).Count -eq 0){$issues.Add('No default acquisition artifact is defined.')|Out-Null}
    return $issues.ToArray()
}

function Get-NpuAcquisitionCandidates {
    [CmdletBinding()]
    param([AllowNull()]$Metadata)
    if ($null -eq $Metadata) {
        $metadataPath=Join-Path $PSScriptRoot 'inventory/release-metadata.json'
        if (-not (Test-Path -LiteralPath $metadataPath -PathType Leaf)) { throw 'release-metadata.json is missing. Run Metadata before Acquire.' }
        $Metadata=Get-ReviewedJsonDocument $metadataPath
    }
    return @(Get-AmdOrdinalSortedObjectsByStringProperty -Values @($Metadata.Records | Where-Object { $_.SelectedForAcquisition -eq $true }) -PropertyName 'FileName')
}

function Invoke-NpuAcquireStage {
    [CmdletBinding()]
    param(
        [AllowNull()]$Metadata,
        [string[]]$PackagePath=@(),
        [int]$DownloadRetryCount=3,
        [int]$DownloadTimeoutSeconds=180,
        [switch]$AllowNonAmdHost,
        [switch]$Force
    )
    $inventoryRoot=Join-Path $PSScriptRoot 'inventory';New-AmdDirectory -Path $inventoryRoot|Out-Null
    if($PackagePath.Count -gt 0){
        $results=New-Object 'System.Collections.Generic.List[object]';$paths=New-Object 'System.Collections.Generic.List[string]';$locals=@(Resolve-PackageInputs -Requested $PackagePath);if($locals.Count -eq 0){throw 'PackagePath was supplied but no supported ZIP/EXE/MSI/CAB/7z artifact resolved.'}
        foreach($lp in $locals){$item=Get-Item -LiteralPath $lp;$results.Add([pscustomobject][ordered]@{ArtifactId='local';FileName=$item.Name;ArtifactFormat=(Get-NpuArtifactFormatFromPath -Path $item.FullName);Status='LocalSupplied';SourceUrl=$null;LocalPath=$item.FullName;Sha256=Get-AmdSha256 -Path $item.FullName;SizeBytes=[long]$item.Length;IntegrityStatus='Observed';Reviewed=$false})|Out-Null;$paths.Add($item.FullName)|Out-Null}
        $kernel=[pscustomobject][ordered]@{Results=@($results.ToArray());Paths=@($paths.ToArray())}
    } else {
        $candidates=@(Get-NpuAcquisitionCandidates -Metadata $Metadata);if($candidates.Count -eq 0){throw 'No NPU driver artifacts are selected for acquisition.'}
        $downloadCallback={param($uri,$destination) Invoke-NpuWebRequestToFile -Uri $uri -Destination $destination -RetryCount $DownloadRetryCount -TimeoutSeconds $DownloadTimeoutSeconds -AllowNonAmdHost:$AllowNonAmdHost}
        $kernel=Invoke-AmdArtifactAcquisitionKernel -Candidates $candidates -InventoryRoot $inventoryRoot -DownloadCallback $downloadCallback -ForceDownload:$Force
    }
    $doc=[pscustomobject][ordered]@{SchemaVersion='amd-npu-driver-acquisition/1.2';ToolkitVersion=$script:ToolVersion;GeneratedAtUtc=Get-AmdUtcTimestamp;Artifacts=@($kernel.Results)};Write-JsonFile -Value $doc -Path (Join-Path $inventoryRoot 'acquisition.json')
    $failed=@($kernel.Results|Where-Object{$_.Status -eq 'DownloadFailed'});if($failed.Count -gt 0){throw('{0} NPU artifact acquisition(s) failed. See inventory/acquisition.json and evidence ZIP.' -f $failed.Count)}
    $script:RunInputs=@(Resolve-PackageInputs -Requested @($kernel.Paths));return [pscustomobject]@{Summary=('artifacts={0}; mode={1}; kernel=SharedAcquisition' -f $script:RunInputs.Count,$(if($PackagePath.Count -gt 0){'LocalReplay'}else{'DownloadOrCache'}));Paths=$script:RunInputs;Acquisition=$doc}
}


function Resolve-NpuRequestedStages {
    [CmdletBinding()]
    param([string[]]$Stages=@('All'),[string]$Mode)
    $full=@('Test','HardwareIdentity','ProcessorCatalog','Discover','Metadata','Acquire','Extract','Inspect','DriverBinary','Compare','Matrix','Build','Validate')
    $modeMap=@{Full=@('All');Analyze=@('Test','HardwareIdentity','ProcessorCatalog','Acquire','Extract','Inspect','DriverBinary','Matrix','Build','Validate');Compare=@('Test','HardwareIdentity','ProcessorCatalog','Acquire','Extract','Inspect','DriverBinary','Compare','Matrix','Build','Validate');Validate=@('Test','Validate')}
    $aliasMap=@{Analyze=@('Extract','Inspect')}
    return @(Resolve-AmdRequestedStages -AvailableStages $full -RequestedStages @($Stages) -LegacyMode $Mode -ModeMap $modeMap -AliasMap $aliasMap)
}


function Invoke-NpuExtractStage {
    [CmdletBinding()]
    param([string]$SevenZipPath,[int]$ExtractionMaxDepth=5)
    if(@($script:RunInputs).Count -eq 0){throw 'No acquired package is available for extraction.'};$sevenZip=Get-AmdSevenZipPath -ExplicitPath $SevenZipPath;$logRoot=Join-Path (Join-Path (Join-Path $PSScriptRoot 'private') 'evidence') 'extraction-logs'
    $formatResolver={param($p) Get-NpuArtifactFormatFromPath -Path $p};$surfaceProbe={param($root) Get-NpuAnalysisSurface -Root $root};$nestedPredicate={param($p,$sevenZipExe) if(-not(Test-NpuSupportedArtifactPath -Path $p)){return $false};$probe=Get-AmdSevenZipArchiveProbe -SevenZipPath $sevenZipExe -Path $p;return [bool]$probe.ContainerLike}
    $script:ExtractedPackages=@(Invoke-AmdArtifactExtractionKernel -ArtifactPaths @($script:RunInputs) -RunRoot $script:RunRoot -EvidenceLogRoot $logRoot -SevenZipExecutable $sevenZip -MaxDepth $ExtractionMaxDepth -FormatResolver $formatResolver -SurfaceProbe $surfaceProbe -NestedArtifactPredicate $nestedPredicate)
    $bad=@($script:ExtractedPackages|Where-Object{$_.Status -notin @('ExtractionComplete','ExtractedWithErrors')});if($bad.Count -gt 0){throw('{0} artifact(s) did not reach an NPU analysis surface. See extraction evidence logs.' -f $bad.Count)}
    return [pscustomobject]@{Summary=('artifacts={0}; containers={1}; extractedFiles={2}; sevenZip={3}; kernel=SharedExtraction' -f $script:ExtractedPackages.Count,(@($script:ExtractedPackages|ForEach-Object{$_.ContainerCount})|Measure-Object -Sum).Sum,(@($script:ExtractedPackages|ForEach-Object{$_.FileCount})|Measure-Object -Sum).Sum,$sevenZip);Packages=$script:ExtractedPackages;SevenZipPath=$sevenZip;MaxDepth=$ExtractionMaxDepth}
}


function Invoke-NpuInspectStage {
    [CmdletBinding()]
    param()
    if (@($script:ExtractedPackages).Count -eq 0) { throw 'No extracted package is available for inspection.' }
    $analyses=New-Object 'System.Collections.Generic.List[object]'
    foreach($pkg in @($script:ExtractedPackages)){
        Write-AmdStep ('Static inspection: {0}' -f [string]$pkg.FileName)
        $analyses.Add((Get-PackageAnalysis -ArtifactPath ([string]$pkg.ArtifactPath) -ExtractRoot ([string]$pkg.ExtractRoot) -Profiles $script:ProfilesDoc.profiles -Contracts $script:InstallerContractsDoc.contracts -DriverContracts $script:DriverContractsDoc.contracts -CompatibilityRules $script:CompatibilityDoc.artifactRules))|Out-Null
    }
    if($analyses.Count -eq 0){throw 'No package analysis was produced.'}
    $script:Analyses=@($analyses.ToArray())
    return [pscustomobject]@{Summary=('packages={0}' -f $script:Analyses.Count);Analyses=$script:Analyses}
}

function Invoke-NpuAnalyzeStage {
    [CmdletBinding()]
    param([string]$SevenZipPath,[int]$ExtractionMaxDepth=5)
    # Legacy compatibility wrapper. Canonical staged workflow uses Extract + Inspect.
    $null=Invoke-NpuExtractStage -SevenZipPath $SevenZipPath -ExtractionMaxDepth $ExtractionMaxDepth
    return (Invoke-NpuInspectStage)
}
function Invoke-NpuDriverBinaryStage { $count=@($script:Analyses|ForEach-Object{$_.DriverBinaries}).Count;$exact=@($script:Analyses|ForEach-Object{$_.DriverBinaries}|Where-Object{$_.ContractStatus -eq 'ExactHashMatched'}).Count;return [pscustomobject]@{Summary=('driverBinaries={0}; exactHashContracts={1}' -f $count,$exact);DriverBinaryCount=$count;ExactHashContractCount=$exact} }
function Invoke-NpuCompareStage { $list=New-Object System.Collections.Generic.List[object];for($i=0;$i -lt $script:Analyses.Count;$i++){for($j=$i+1;$j -lt $script:Analyses.Count;$j++){$list.Add((Compare-PackageAnalysis -Left $script:Analyses[$i] -Right $script:Analyses[$j]))|Out-Null}};$script:Comparisons=@($list.ToArray());return [pscustomobject]@{Summary=('comparisons={0}' -f $script:Comparisons.Count);Comparisons=$script:Comparisons} }
function Invoke-NpuMatrixStage { $script:CompatibilityMatrix=Get-DriverCompatibilityMatrix -Analyses $script:Analyses -ProcessorDoc $script:ProcessorDoc -HardwareDoc $script:HardwareDoc -CompatibilityDoc $script:CompatibilityDoc -ObservedRuntimeDoc $script:ObservedRuntimeDoc -TargetServer 'Windows Server 2025';$script:ProcessorDriverApplicability=Get-ProcessorDriverApplicabilityDocument -ProcessorDoc $script:ProcessorDoc -HardwareDoc $script:HardwareDoc -CompatibilityMatrix $script:CompatibilityMatrix -ApplicabilityDoc $script:ApplicabilityDoc -ArtifactCatalogDoc $script:ArtifactCatalogDoc;return [pscustomobject]@{Summary=('rows={0}; selections={1}; applicability={2}; reviewRequired={3}' -f @($script:CompatibilityMatrix.Rows).Count,@($script:CompatibilityMatrix.Selections).Count,@($script:ProcessorDriverApplicability.Rows).Count,@($script:CompatibilityMatrix.Selections|Where-Object{$_.Decision -eq 'ReviewRequired'}).Count);Matrix=$script:CompatibilityMatrix;Applicability=$script:ProcessorDriverApplicability} }

function Invoke-NpuBuildStage {
    [CmdletBinding()]
    param([switch]$SkipPublicExport)
    if($SkipPublicExport){Write-AmdSkip 'Public generation skipped by -SkipPublicExport.';return [pscustomobject]@{Summary='public generation skipped by caller';Skipped=$true}}
    $staging=Join-Path $script:RunRoot 'public-staging';if(Test-Path -LiteralPath $staging){Remove-Item -LiteralPath $staging -Recurse -Force};foreach($sub in @('releases','comparisons','catalog')){New-AmdDirectory -Path (Join-Path $staging $sub)|Out-Null}
    $hardwarePublic=Get-HardwareIdentityPublicDocument -HardwareDoc $script:HardwareDoc;$processorPublic=Get-ProcessorCatalogPublicDocument -ProcessorDoc $script:ProcessorDoc;$observedPublic=Get-ObservedRuntimePublicDocument -ObservedRuntimeDoc $script:ObservedRuntimeDoc
    Write-JsonFile -Value $hardwarePublic -Path (Join-Path $staging 'catalog/hardware-identities.json') -Compress;Write-AmdPublicMarkdownText -Path (Join-Path $staging 'catalog/hardware-identities.md') -Text (Convert-HardwareIdentityToMarkdown -Document $hardwarePublic)
    Write-JsonFile -Value $processorPublic -Path (Join-Path $staging 'catalog/processor-catalog.json') -Compress;Write-AmdPublicMarkdownText -Path (Join-Path $staging 'catalog/processor-catalog.md') -Text (Convert-ProcessorCatalogToMarkdown -Document $processorPublic)
    Write-JsonFile -Value $observedPublic -Path (Join-Path $staging 'catalog/observed-runtime-evidence.json') -Compress;Write-AmdPublicMarkdownText -Path (Join-Path $staging 'catalog/observed-runtime-evidence.md') -Text (Convert-ObservedRuntimeEvidenceToMarkdown -Document $observedPublic)
    if($script:CompatibilityMatrix){Write-JsonFile -Value $script:CompatibilityMatrix -Path (Join-Path $staging 'catalog/driver-compatibility-matrix.json') -Compress;Write-AmdPublicMarkdownText -Path (Join-Path $staging 'catalog/driver-compatibility-matrix.md') -Text (Convert-DriverCompatibilityMatrixToMarkdown -Matrix $script:CompatibilityMatrix)}
    if($script:ProcessorDriverApplicability){Write-JsonFile -Value $script:ProcessorDriverApplicability -Path (Join-Path $staging 'catalog/processor-driver-applicability.json') -Compress;Write-AmdPublicMarkdownText -Path (Join-Path $staging 'catalog/processor-driver-applicability.md') -Text (Convert-ProcessorDriverApplicabilityToMarkdown -Document $script:ProcessorDriverApplicability)}
    foreach($a in @($script:Analyses)){$stem=[IO.Path]::GetFileNameWithoutExtension($a.Artifact.FileName)-replace '[^A-Za-z0-9._-]','_';Write-JsonFile -Value $a -Path (Join-Path $staging ("releases/$stem.json")) -Compress;Write-AmdPublicMarkdownText -Path (Join-Path $staging ("releases/$stem.md")) -Text (Convert-AnalysisToMarkdown -Analysis $a)}
    foreach($c in @($script:Comparisons)){$ls=[IO.Path]::GetFileNameWithoutExtension($c.Left.FileName)-replace '[^A-Za-z0-9._-]','_';$rs=[IO.Path]::GetFileNameWithoutExtension($c.Right.FileName)-replace '[^A-Za-z0-9._-]','_';$stem="$ls--vs--$rs";Write-JsonFile -Value $c -Path (Join-Path $staging ("comparisons/$stem.json")) -Compress;Write-AmdPublicMarkdownText -Path (Join-Path $staging ("comparisons/$stem.md")) -Text (Convert-ComparisonToMarkdown -Comparison $c)}
    $manifest=New-PublicationManifest -PublicRoot $staging -SourceScriptPath $script:SourceScriptPath;Write-JsonFile -Value $manifest -Path (Join-Path $staging 'publication-manifest.json') -Compress;$script:PendingPublicRoot=$staging
    return [pscustomobject]@{Summary=('candidatePublicFiles={0}; publicationKernel=Shared' -f @(Get-ChildItem -LiteralPath $staging -File -Recurse).Count);StagingRoot=$staging;Skipped=$false}
}


function Invoke-NpuValidateStage {
    [CmdletBinding()]
    param([switch]$SkipPublicExport)
    $target=if($script:PendingPublicRoot){$script:PendingPublicRoot}else{$script:ResolvedPublicOutputRoot};if(-not(Test-Path -LiteralPath $target -PathType Container)){throw('No public surface exists to validate: {0}' -f $target)}
    $validation=Test-AmdPublicRepositorySurface -Root $target -DatasetValidator {param($root) Test-NpuPublicDatasetConsistency -Root $root};$issues=New-Object 'System.Collections.Generic.List[string]';foreach($i in @($validation.Errors)){$issues.Add([string]$i)|Out-Null};foreach($i in @(Test-PublicationManifest -PublicRoot $target -SourceScriptPath $script:SourceScriptPath)){$issues.Add([string]$i)|Out-Null}
    if($issues.Count -gt 0){throw('Public validation failed: '+($issues -join '; '))}
    if($script:PendingPublicRoot -and -not $SkipPublicExport){$backup=Join-Path $script:RunRoot 'public-previous';$null=Publish-AmdRepositorySurface -CandidateRoot $script:PendingPublicRoot -PublicRoot $script:ResolvedPublicOutputRoot -BackupRoot $backup;$script:PendingPublicRoot=$null}
    return [pscustomobject]@{Summary=('public validation passed; privacy={0}; dataset={1}; JSON={2}; Markdown={3}; promotionKernel=Shared' -f $validation.PrivacyStatus,$validation.DatasetConsistencyStatus,$validation.JsonWhitespaceStatus,$validation.MarkdownFormatStatus);Status='Pass';ValidatedRoot=$script:ResolvedPublicOutputRoot;Validation=$validation}
}


function Resolve-NpuPublicOutputRootPath {
    [CmdletBinding()]
    param([AllowNull()][string]$RequestedPath)
    if([string]::IsNullOrWhiteSpace([string]$RequestedPath)){
        return [IO.Path]::GetFullPath((Join-Path $PSScriptRoot 'public'))
    }
    return [IO.Path]::GetFullPath($RequestedPath)
}


# --- main -------------------------------------------------------------------
function Invoke-AmdNpuResearchMain {
    [CmdletBinding()]
    param(
        [string[]]$Stages=@('All'),
        [string[]]$PackagePath=@(),
        [string[]]$ArtifactId=@(),
        [string]$Mode,
        [string]$OutputRoot,
        [string]$EvidenceOutputRoot,
        [string]$EvidenceLabel,
        [string]$PublicOutputRoot,
        [switch]$SkipPublicExport,
        [switch]$SkipEvidenceArchive,
        [switch]$IncludePackagesInEvidence,
        [switch]$NoClean,
        [switch]$Force,
        [int]$DownloadRetryCount=3,
        [int]$DownloadTimeoutSeconds=180,
        [string]$SevenZipPath,
        [int]$ExtractionMaxDepth=5,
        [string[]]$DocumentationUri=@('https://ryzenai.docs.amd.com/en/latest/inst.html'),
        [string[]]$AdditionalDriverUrl=@(),
        [switch]$AllowNonAmdHost
    )
    $script:RunStartTime=Get-Date;$script:AmdRunStartTime=$script:RunStartTime
    $finalAssessment=$null;$finalExitCode=1;$resolvedStages=@();$discovery=$null;$metadata=$null

    # Keep invocation evidence construction side-effect free so even path/bootstrap failures
    # can be captured by the emergency evidence path.
    $invocation=[pscustomobject][ordered]@{
        Stages=@($Stages);PackagePath=@($PackagePath|ForEach-Object{[IO.Path]::GetFileName([string]$_)});ArtifactId=@($ArtifactId)
        Mode=if(-not [string]::IsNullOrWhiteSpace([string]$Mode)){$Mode}else{$null};OutputRoot=$OutputRoot;EvidenceOutputRoot=$EvidenceOutputRoot;EvidenceLabel=$EvidenceLabel
        PublicOutputRoot=$PublicOutputRoot;SkipPublicExport=[bool]$SkipPublicExport;SkipEvidenceArchive=[bool]$SkipEvidenceArchive;IncludePackagesInEvidence=[bool]$IncludePackagesInEvidence
        Force=[bool]$Force;DownloadRetryCount=$DownloadRetryCount;DownloadTimeoutSeconds=$DownloadTimeoutSeconds;SevenZipPath=$SevenZipPath;ExtractionMaxDepth=$ExtractionMaxDepth;DocumentationUri=@($DocumentationUri);AdditionalDriverUrl=@($AdditionalDriverUrl);AllowNonAmdHost=[bool]$AllowNonAmdHost
    }

    try {
        # Predecessor parity: evidence is established before work-root initialization or network access.
        $null=Start-AmdResearchEvidenceSession -OutputRoot $EvidenceOutputRoot -Label $EvidenceLabel -InvocationParameters $invocation

        $resolvedOutputRoot=if([string]::IsNullOrWhiteSpace([string]$OutputRoot)){Join-Path $PSScriptRoot 'work'}else{$OutputRoot}
        $resolvedOutputRoot=[IO.Path]::GetFullPath($resolvedOutputRoot);New-AmdDirectory -Path $resolvedOutputRoot|Out-Null
        $runId=[DateTime]::UtcNow.ToString('yyyyMMddTHHmmssfffZ');$script:RunRoot=Join-Path $resolvedOutputRoot ('run-'+$runId)
        if((Test-Path -LiteralPath $script:RunRoot)-and -not $NoClean){Remove-Item -LiteralPath $script:RunRoot -Recurse -Force}
        New-AmdDirectory -Path $script:RunRoot|Out-Null
        $script:ResolvedPublicOutputRoot=Resolve-NpuPublicOutputRootPath -RequestedPath $PublicOutputRoot

        $resolvedStages=@(Resolve-NpuRequestedStages -Stages $Stages -Mode $Mode);$script:ResolvedStageCount=$resolvedStages.Count;$script:AmdResolvedStageCount=$resolvedStages.Count;$script:StageOrdinal=0;$script:AmdStageOrdinal=0
        $startupPlatform=Get-AmdPlatformInfo
        Write-Host '=== AMD NPU Driver Research Toolkit ==='
        Write-Host ('Toolkit    : {0}' -f $script:ToolVersion)
        Write-Host ('PowerShell : {0}' -f $PSVersionTable.PSVersion)
        Write-Host ('Platform   : {0} ({1})' -f $startupPlatform.PlatformFamily,$startupPlatform.OSDescription)
        Write-Host ('Stages     : {0}' -f ($resolvedStages -join ', '))
        Write-Host ('Started    : {0}' -f $script:RunStartTime.ToString('yyyy-MM-dd HH:mm:ss'))
        Write-Host ('Root       : {0}' -f $PSScriptRoot)
        Write-Host ('Evidence   : {0}' -f $script:EvidenceContext.EvidenceDirectory)
        Write-Host ('Public     : {0}' -f $(if($SkipPublicExport){'SKIPPED'}else{$script:ResolvedPublicOutputRoot}))
        Write-Host ('Input mode : {0}' -f $(if($PackagePath.Count -gt 0){'Local PackagePath override'}else{'Automatic AMD publication acquisition'}))
        Write-Host ''

        foreach($stage in $resolvedStages){
            $blocked=Get-NpuStageDependencyBlockReason -Name $stage -ResolvedStages $resolvedStages -PackagePath $PackagePath
            switch($stage){
                'Test' {
                    $null=Invoke-AmdTrackedStage -Name 'Test' -BlockedReason $blocked -Body {
                        $issues=New-Object 'System.Collections.Generic.List[string]'
                        $publicRootProbe=Join-Path $script:RunRoot 'public-output-root-regression-probe';$expectedPublicRootProbe=[IO.Path]::GetFullPath($publicRootProbe);$actualPublicRootProbe=Resolve-NpuPublicOutputRootPath -RequestedPath $publicRootProbe;if($actualPublicRootProbe -ne $expectedPublicRootProbe){$issues.Add(('PublicOutputRoot resolver ignored explicit path. expected={0}; actual={1}' -f $expectedPublicRootProbe,$actualPublicRootProbe))|Out-Null}
                        foreach($i in @(Test-WindowsPowerShell51SourceCompatibility -Path $script:SourceScriptPath)){$issues.Add([string]$i)|Out-Null}
                        $script:PredecessorCoreContractDoc=Get-ReviewedJsonDocument (Join-Path $PSScriptRoot 'data/predecessor-shared-core-contract.json')
                        foreach($i in @(Test-NpuPredecessorParityContract -Stages $Stages -Mode $Mode)){$issues.Add([string]$i)|Out-Null}
                        $script:PredecessorExtractionContractDoc=Get-ReviewedJsonDocument (Join-Path $PSScriptRoot 'data/predecessor-extraction-core-contract.json')
                        foreach($i in @(Test-NpuExtractionParityContract)){$issues.Add([string]$i)|Out-Null}
                        foreach($i in @(Test-NpuArchitectureConvergenceContract)){$issues.Add([string]$i)|Out-Null}
                        try{$script:SevenZipInfo=Get-AmdSevenZipInfo -ExplicitPath $SevenZipPath;if($script:SevenZipInfo.Status -ne 'Available'){$issues.Add(('7-Zip is not ready: {0}' -f $script:SevenZipInfo.Guidance))|Out-Null}}catch{$issues.Add(('7-Zip qualification failed: {0}' -f $_.Exception.Message))|Out-Null}
                        $platformProbe=Get-NpuPlatformInfo
                        if($null -eq $platformProbe -or [string]::IsNullOrWhiteSpace([string]$platformProbe.Architecture)){$issues.Add('Platform probe did not produce an architecture value.')|Out-Null}
                        foreach($i in @(Test-NpuReviewedSourceDataContracts)){$issues.Add([string]$i)|Out-Null}
                        foreach($i in @(Test-NpuToolVersionConsistency)){$issues.Add([string]$i)|Out-Null}
                        $script:ProfilesDoc=Get-ReviewedJsonDocument (Join-Path $PSScriptRoot 'data/windows-server-profiles.json')
                        $script:InstallerContractsDoc=Get-ReviewedJsonDocument (Join-Path $PSScriptRoot 'data/known-installer-contracts.json')
                        $script:DriverContractsDoc=Get-ReviewedJsonDocument (Join-Path $PSScriptRoot 'data/known-driver-binary-contracts.json')
                        $script:HardwareDoc=Get-ReviewedJsonDocument (Join-Path $PSScriptRoot 'data/hardware-identities.json')
                        $script:ProcessorDoc=Get-ReviewedJsonDocument (Join-Path $PSScriptRoot 'data/processor-catalog.json')
                        $script:CompatibilityDoc=Get-ReviewedJsonDocument (Join-Path $PSScriptRoot 'data/driver-compatibility-rules.json')
                        $script:ObservedRuntimeDoc=Get-ReviewedJsonDocument (Join-Path $PSScriptRoot 'data/observed-runtime-evidence.json')
                        $script:ArtifactCatalogDoc=Get-ReviewedJsonDocument (Join-Path $PSScriptRoot 'data/published-driver-artifacts.json')
                        $script:ApplicabilityDoc=Get-ReviewedJsonDocument (Join-Path $PSScriptRoot 'data/processor-driver-applicability.json')
                        foreach($i in @(Test-NpuPublishedArtifactCatalog -Catalog $script:ArtifactCatalogDoc -AllowNonAmdHost:$AllowNonAmdHost)){$issues.Add([string]$i)|Out-Null}
                        foreach($i in @(Test-ProcessorDriverApplicabilityResearchData -ApplicabilityDoc $script:ApplicabilityDoc -ArtifactCatalogDoc $script:ArtifactCatalogDoc)){$issues.Add([string]$i)|Out-Null}
                        if($issues.Count){throw($issues -join '; ')}
                        return [pscustomobject]@{Summary=('PowerShell {0}; sharedCore={1}; 7Zip={2}; reviewedArtifacts={3}; sourceDataContracts={4}' -f $PSVersionTable.PSVersion,[int]$script:PredecessorCoreContractDoc.functionCount,[string]$script:SevenZipInfo.Status,@($script:ArtifactCatalogDoc.artifacts).Count,@(Get-NpuReviewedSourceDataContracts).Count);PowerShell=$PSVersionTable.PSVersion.ToString();SharedCoreFunctionCount=[int]$script:PredecessorCoreContractDoc.functionCount;SevenZip=$script:SevenZipInfo;ArtifactCatalogCount=@($script:ArtifactCatalogDoc.artifacts).Count;SourceDataContractCount=@(Get-NpuReviewedSourceDataContracts).Count}
                    }
                }
                'HardwareIdentity' {$null=Invoke-AmdTrackedStage -Name $stage -BlockedReason $blocked -Body {$issues=@(Test-ReviewedResearchData -HardwareDoc $script:HardwareDoc -ProcessorDoc $script:ProcessorDoc -CompatibilityDoc $script:CompatibilityDoc);$issues+=@(Test-ObservedRuntimeEvidence -ObservedRuntimeDoc $script:ObservedRuntimeDoc -ProcessorDoc $script:ProcessorDoc -HardwareDoc $script:HardwareDoc);$issues+=@(Test-DriverBinaryContracts -Contracts $script:DriverContractsDoc.contracts);if($issues.Count){throw($issues -join '; ')};return [pscustomobject]@{Summary=('identities={0}; observedRuntime={1}; driver contracts={2}' -f @($script:HardwareDoc.identities).Count,@($script:ObservedRuntimeDoc.records).Count,@($script:DriverContractsDoc.contracts).Count);IdentityCount=@($script:HardwareDoc.identities).Count;ObservedRuntimeCount=@($script:ObservedRuntimeDoc.records).Count}}}
                'ProcessorCatalog' {$null=Invoke-AmdTrackedStage -Name $stage -BlockedReason $blocked -Body {$fails=0;foreach($p in @($script:ProcessorDoc.processors)){$r=Resolve-ProcessorCatalogIdentity -ProcessorName ([string]$p.canonicalName) -ProcessorDoc $script:ProcessorDoc;if($r.Status -ne 'ExactCatalogMatch' -or $r.ProcessorId -ne [string]$p.processorId){$fails++}};if($fails){throw("Processor catalog self-test failures=$fails")};return [pscustomobject]@{Summary=('processors={0}' -f @($script:ProcessorDoc.processors).Count);ProcessorCount=@($script:ProcessorDoc.processors).Count}}}
                'Discover' {$res=Invoke-AmdTrackedStage -Name $stage -BlockedReason $blocked -Body {Invoke-NpuDiscoveryStage -DocumentationUri $DocumentationUri -AdditionalDriverUrl $AdditionalDriverUrl -DownloadTimeoutSeconds $DownloadTimeoutSeconds -AllowNonAmdHost:$AllowNonAmdHost};if($res.Success){$discovery=$res.Output}}
                'Metadata' {$res=Invoke-AmdTrackedStage -Name $stage -BlockedReason $blocked -Body {Invoke-NpuMetadataStage -Discovery $discovery -ArtifactId $ArtifactId -PackagePath $PackagePath};if($res.Success){$metadata=$res.Output;$script:ReleaseMetadataDoc=$metadata}}
                'Acquire' {$res=Invoke-AmdTrackedStage -Name $stage -BlockedReason $blocked -Body {Invoke-NpuAcquireStage -Metadata $metadata -PackagePath $PackagePath -DownloadRetryCount $DownloadRetryCount -DownloadTimeoutSeconds $DownloadTimeoutSeconds -AllowNonAmdHost:$AllowNonAmdHost -Force:$Force};if($res.Success){$script:RunInputs=@($res.Output.Paths)}}
                'Extract' {$null=Invoke-AmdTrackedStage -Name $stage -BlockedReason $blocked -Body {Invoke-NpuExtractStage -SevenZipPath $SevenZipPath -ExtractionMaxDepth $ExtractionMaxDepth}}
                'Inspect' {$null=Invoke-AmdTrackedStage -Name $stage -BlockedReason $blocked -Body {Invoke-NpuInspectStage}}
                'DriverBinary' {$null=Invoke-AmdTrackedStage -Name $stage -BlockedReason $blocked -Body {Invoke-NpuDriverBinaryStage}}
                'Compare' {$null=Invoke-AmdTrackedStage -Name $stage -BlockedReason $blocked -Body {Invoke-NpuCompareStage}}
                'Matrix' {$null=Invoke-AmdTrackedStage -Name $stage -BlockedReason $blocked -Body {Invoke-NpuMatrixStage}}
                'Build' {$null=Invoke-AmdTrackedStage -Name $stage -BlockedReason $blocked -Body {Invoke-NpuBuildStage -SkipPublicExport:$SkipPublicExport}}
                'Validate' {$null=Invoke-AmdTrackedStage -Name $stage -BlockedReason $blocked -Body {Invoke-NpuValidateStage -SkipPublicExport:$SkipPublicExport}}
            }
            Write-Host ''
        }
        Write-AmdOk 'Research run processing complete; finalizing evidence.'
    }
    catch {
        $fatalRecord=$_;$script:TopLevelFatalError=$fatalRecord.Exception.ToString()
        if($null -eq $script:EvidenceContext){try{$null=Start-AmdEmergencyEvidenceSession -PreferredOutputRoot $EvidenceOutputRoot -Label $EvidenceLabel -InvocationParameters $invocation -BootstrapError $script:TopLevelFatalError}catch{}}
        Write-AmdFail ('Fatal research runner error: {0}' -f $fatalRecord.Exception.Message)
        if($script:EvidenceContext){try{Write-AmdUtf8NoBom -Path (Join-Path (Join-Path $script:EvidenceContext.EvidenceDirectory 'errors') 'fatal-runner-error.txt') -Text ((@(('OccurredUtc: {0}' -f (Get-AmdUtcTimestamp)),('Exception  : {0}' -f $fatalRecord.Exception.ToString()),('ScriptStack: {0}' -f $fatalRecord.ScriptStackTrace))) -join [Environment]::NewLine)}catch{}}
    }
    finally {
        if($null -eq $script:EvidenceContext -and $script:TopLevelFatalError){try{$null=Start-AmdEmergencyEvidenceSession -PreferredOutputRoot $EvidenceOutputRoot -Label $EvidenceLabel -InvocationParameters $invocation -BootstrapError $script:TopLevelFatalError}catch{}}
        try{$finalAssessment=Finalize-AmdResearchEvidenceSession -ResolvedStages $resolvedStages -SkipArchive:$SkipEvidenceArchive -IncludePackages:$IncludePackagesInEvidence;$finalExitCode=[int]$finalAssessment.ExitCode}
        catch{$finalExitCode=1;if(-not $script:TopLevelFatalError){$script:TopLevelFatalError=$_.Exception.ToString()};Write-Warning ('Evidence finalization failed: {0}' -f $_.Exception.Message);if($script:TranscriptStarted){try{Stop-Transcript|Out-Null}catch{};$script:TranscriptStarted=$false}}
        if($null -eq $finalAssessment){$finalAssessment=Get-AmdRunAssessment -ResolvedStages $resolvedStages}
        Write-AmdAssessmentConsoleReport -Assessment $finalAssessment -EvidenceDirectory $(if($script:AmdEvidenceContext){$script:AmdEvidenceContext.EvidenceDirectory}else{$null}) -ZipPath $(if($script:AmdEvidenceContext -and -not $SkipEvidenceArchive){$script:AmdEvidenceContext.ZipPath}else{$null}) -SkipPublicExport:$SkipPublicExport
        Write-AmdRunTimingSummary -Assessment $finalAssessment
    }
    return $finalExitCode
}

$mainParameters=@{
    Stages=$Stages;PackagePath=$PackagePath;ArtifactId=$ArtifactId;Mode=$Mode;OutputRoot=$OutputRoot;EvidenceOutputRoot=$EvidenceOutputRoot;EvidenceLabel=$EvidenceLabel
    PublicOutputRoot=$PublicOutputRoot;SkipPublicExport=$SkipPublicExport;SkipEvidenceArchive=$SkipEvidenceArchive;IncludePackagesInEvidence=$IncludePackagesInEvidence;NoClean=$NoClean
    Force=$Force;DownloadRetryCount=$DownloadRetryCount;DownloadTimeoutSeconds=$DownloadTimeoutSeconds;SevenZipPath=$SevenZipPath;ExtractionMaxDepth=$ExtractionMaxDepth
    DocumentationUri=$DocumentationUri;AdditionalDriverUrl=$AdditionalDriverUrl;AllowNonAmdHost=$AllowNonAmdHost
}
$finalCode = Invoke-AmdNpuResearchMain @mainParameters
exit $finalCode
