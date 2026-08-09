# AMD Chipset Driver Research Toolkit 1.0.0
# GA baseline promoted from the fully accepted v0.4.3 implementation.
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

    [switch]$SkipEvidenceArchive,

    [switch]$IncludeInstallersInEvidence,

    [switch]$AllowNonAmdHost,

    [switch]$Force
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2.0

$script:AmdChipsetResearchToolkitVersion = '1.0.0'
$script:AmdChipsetResearchToolkitRoot = $PSScriptRoot

$script:AmdChipsetResearchEvidenceSchemaVersion = 'amd-chipset-driver-research-evidence/1.0'
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

        [int]$Depth = 30
    )

    $json = $Value | ConvertTo-Json -Depth $Depth
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
        [Parameter(Mandatory=$true)][ValidateSet('PASS','FAIL')][string]$Status,
        [Parameter(Mandatory=$true)][TimeSpan]$Elapsed
    )

    $color = if ($Status -eq 'PASS') { 'Green' } else { 'Red' }
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
        $OutputRoot = Join-Path (Join-Path $toolRoot 'evidence') 'runs'
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
        [scriptblock]$Body
    )

    $script:AmdStageOrdinal++
    Write-AmdStageHeader -Name $Name -Ordinal $script:AmdStageOrdinal -Total $script:AmdResolvedStageCount

    $started = [DateTime]::UtcNow
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $status = 'PASS'
    $errorText = $null
    $errorFile = $null
    $output = $null

    try {
        $output = & $Body
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

function Get-AmdRunAssessment {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$ResolvedStages
    )

    $toolRoot = Get-AmdResearchToolkitRoot
    $items = New-Object 'System.Collections.Generic.List[object]'

    $failedStages = @($script:AmdStageResults.ToArray() | Where-Object { $_.Status -eq 'FAIL' })
    $items.Add([pscustomobject]@{
        Name = 'StageExecution'
        Status = if ($failedStages.Count -eq 0) { 'PASS' } else { 'REVIEW' }
        Detail = if ($failedStages.Count -eq 0) {
            ('all {0} selected stage(s) completed without terminating errors' -f $script:AmdStageResults.Count)
        }
        else {
            ('{0} stage(s) failed: {1}' -f $failedStages.Count, (@($failedStages.Name) -join ', '))
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
    }

    if ($ResolvedStages -contains 'Extract') {
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
    }

    if ($ResolvedStages -contains 'Inspect') {
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
            'Use -IncludeInstallersInEvidence only when binary preservation inside the review ZIP is explicitly required.'
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
    Copy-AmdEvidenceTree -Source (Join-Path (Join-Path (Get-AmdResearchToolkitRoot) 'evidence') 'release-notes') -Destination (Join-Path $snapshot 'release-notes')
    Copy-AmdEvidenceTree -Source (Join-Path (Join-Path (Get-AmdResearchToolkitRoot) 'evidence') 'extraction-logs') -Destination (Join-Path $snapshot 'extraction-logs')
    Copy-AmdEvidenceTree -Source (Join-Path (Join-Path (Get-AmdResearchToolkitRoot) 'evidence') 'download-diagnostics') -Destination (Join-Path $snapshot 'download-diagnostics')

    if ($IncludeInstallers) {
        Copy-AmdEvidenceTree -Source (Join-Path (Join-Path (Get-AmdResearchToolkitRoot) 'evidence') 'installers') -Destination (Join-Path $snapshot 'installers')
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
            FullResearchReady = ($runtimeSupported -and $sevenZipInfo.Status -eq 'Available')
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
        FullResearchReady = $result.Readiness.FullResearchReady
        EnvironmentEvidencePath = $OutputPath
        DependencyGuidance = $sevenZipInfo.Guidance
    }

    if (-not $runtimeSupported) {
        throw ('Unsupported PowerShell runtime: {0}. Windows PowerShell 5.1 or PowerShell 7.x is required.' -f $version)
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
                $diagnosticsRoot = Join-Path (Join-Path $toolRoot 'evidence') 'download-diagnostics'
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
    $logRoot = Join-Path (Join-Path $toolRoot 'evidence') 'extraction-logs'
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
        $devIdFiles = @(
            Get-ChildItem -LiteralPath $root -Filter 'DevID.xml' -File -Recurse -ErrorAction SilentlyContinue |
                Sort-Object FullName
        )

        foreach ($file in $infoFiles) {
            try {
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

                $relative = Get-AmdRelativePath -BasePath $root -Path $file.FullName
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

        foreach ($file in $devIdFiles) {
            try {
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

                $relative = Get-AmdRelativePath -BasePath $root -Path $file.FullName
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
        $preferredDevIdPath = $null

        if ($preferredInfo.Count -gt 0) {
            $preferredInfoPath = [string]$preferredInfo[0].RelativePath
            $preferredProducts = @($preferredInfo[0].Products)
        }
        if ($preferredDevId.Count -gt 0) {
            $preferredDevIdPath = [string]$preferredDevId[0].RelativePath
            $preferredMappings = @($preferredDevId[0].DeviceMappings)
        }

        $status = if ($preferredInfo.Count -gt 0 -or $preferredDevId.Count -gt 0) {
            if ($errors.Count -gt 0) { 'ParsedWithErrors' } else { 'Parsed' }
        }
        elseif ($infoFiles.Count -eq 0 -and $devIdFiles.Count -eq 0) {
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
            PreferredDevIdXmlPath = $preferredDevIdPath
            ProductCount = $preferredProducts.Count
            DeviceMappingCount = $preferredMappings.Count
            Products = @($preferredProducts)
            DeviceMappings = @($preferredMappings)
            InfoXmlSources = $infoSources.ToArray()
            DevIdXmlSources = $devIdSources.ToArray()
            Errors = $errors.ToArray()
        })
    }

    $output = [pscustomobject][ordered]@{
        SchemaVersion = '1.0'
        ToolkitVersion = $script:AmdChipsetResearchToolkitVersion
        GeneratedAtUtc = [DateTime]::UtcNow.ToString('o')
        Purpose = 'EmbeddedInstallerMetadataEvidence'
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
    Write-AmdStep 'Inspecting embedded AMD Info.xml / DevID.xml metadata.'
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
                $lines = [System.IO.File]::ReadAllLines($inf.FullName)

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
        SchemaVersion = '1.0'
        ToolkitVersion = $script:AmdChipsetResearchToolkitVersion
        GeneratedAtUtc = [DateTime]::UtcNow.ToString('o')
        DriverPackageCount = $driverRecords.Count
        DriverPackages = $driverRecords.ToArray()
    }

    Write-AmdJsonFile -Path $OutputPath -Value $output

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
        [string]$OutputJsonPath,
        [string]$OutputCsvPath,
        [string]$OutputMarkdownPath
    )

    $toolRoot = Get-AmdResearchToolkitRoot

    if (-not $ReleasesPath) { $ReleasesPath = Join-Path $toolRoot 'inventory\releases.json' }
    if (-not $MetadataPath) { $MetadataPath = Join-Path $toolRoot 'inventory\release-metadata.json' }
    if (-not $AcquisitionPath) { $AcquisitionPath = Join-Path $toolRoot 'inventory\acquisition.json' }
    if (-not $ExtractionPath) { $ExtractionPath = Join-Path $toolRoot 'inventory\extraction.json' }
    if (-not $DriverPackagesPath) { $DriverPackagesPath = Join-Path $toolRoot 'inventory\driver-packages.json' }
    if (-not $EnvironmentPath) { $EnvironmentPath = Join-Path $toolRoot 'inventory\environment.json' }
    if (-not $EmbeddedMetadataPath) { $EmbeddedMetadataPath = Join-Path $toolRoot 'inventory\embedded-installer-metadata.json' }
    if (-not $OutputJsonPath) { $OutputJsonPath = Join-Path $toolRoot 'inventory\amd-chipset-driver-inventory.json' }
    if (-not $OutputCsvPath) { $OutputCsvPath = Join-Path $toolRoot 'inventory\amd-chipset-driver-inventory.csv' }
    if (-not $OutputMarkdownPath) { $OutputMarkdownPath = Join-Path $toolRoot 'reports\amd-chipset-driver-history.md' }

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
            DriverPackages = @($driverRecords)
        })
    }

    $inventory = [pscustomobject]@{
        SchemaVersion = '1.0'
        ToolkitVersion = $script:AmdChipsetResearchToolkitVersion
        GeneratedAtUtc = [DateTime]::UtcNow.ToString('o')
        Purpose = 'ResearchInventory'
        CompatibilityPolicyIncluded = $false
        ResearchEnvironment = $environmentData
        Releases = $releaseInventory.ToArray()
    }

    Write-AmdJsonFile -Path $OutputJsonPath -Value $inventory

    $csvRows = New-Object System.Collections.Generic.List[object]

    foreach ($release in $releaseInventory) {
        foreach ($driver in @($release.DriverPackages)) {
            $kmdf = @()
            $umdf = @()

            if ($driver.Wdf) {
                $kmdf = @($driver.Wdf.KMDF.Versions)
                $umdf = @($driver.Wdf.UMDF.Versions)
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
                HardwareIds = (@($driver.HardwareIds) -join ';')
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
                @($driver.Wdf.KMDF.Versions) -join ', '
            }
            else {
                if ($driver.Wdf) { [string]$driver.Wdf.KMDF.Status } else { 'NotInspected' }
            }

            $umdfText = if ($driver.Wdf -and $driver.Wdf.UMDF.Status -eq 'Declared') {
                @($driver.Wdf.UMDF.Versions) -join ', '
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

    Write-AmdUtf8NoBom -Path $OutputMarkdownPath -Text $md.ToString()

    Write-Host ('Canonical JSON : {0}' -f $OutputJsonPath)
    Write-Host ('Derived CSV    : {0}' -f $OutputCsvPath)
    Write-Host ('Markdown report: {0}' -f $OutputMarkdownPath)
}


function Resolve-AmdRequestedStages {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$RequestedStages
    )

    $allowed = @('Test', 'Discover', 'Metadata', 'Acquire', 'Extract', 'Inspect', 'Build', 'All')
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
        return @('Test', 'Discover', 'Metadata', 'Acquire', 'Extract', 'Inspect', 'Build')
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
    SkipEvidenceArchive = [bool]$SkipEvidenceArchive
    IncludeInstallersInEvidence = [bool]$IncludeInstallersInEvidence
    AllowNonAmdHost = [bool]$AllowNonAmdHost
    Force = [bool]$Force
}

try {
    $null = Start-AmdResearchEvidenceSession `
        -OutputRoot $EvidenceOutputRoot `
        -Label $EvidenceLabel `
        -InvocationParameters $invocationEvidence

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
    Write-Host ''

    foreach ($stage in $resolvedStages) {
        switch ($stage) {
            'Test' {
                $null = Invoke-AmdTrackedStage -Name 'Test' -Body {
                    $envResult = Invoke-AmdResearchEnvironmentTest -SevenZipPath $SevenZipPath
                    $envResult | Format-List | Out-Host
                }
            }

            'Discover' {
                $null = Invoke-AmdTrackedStage -Name 'Discover' -Body {
                    Invoke-AmdDiscoverStage `
                        -SitemapUri $SitemapUri `
                        -AdditionalReleaseNotesUrl $AdditionalReleaseNotesUrl
                }
            }

            'Metadata' {
                $null = Invoke-AmdTrackedStage -Name 'Metadata' -Body {
                    $stageArgs = @{}
                    if ($Force) { $stageArgs['Force'] = $true }
                    Invoke-AmdMetadataStage @stageArgs
                }
            }

            'Acquire' {
                $null = Invoke-AmdTrackedStage -Name 'Acquire' -Body {
                    $stageArgs = @{}
                    if ($ReleaseVersion.Count -gt 0) { $stageArgs['ReleaseVersion'] = $ReleaseVersion }
                    if ($Force) { $stageArgs['Force'] = $true }
                    if ($AllowNonAmdHost) { $stageArgs['AllowNonAmdHost'] = $true }
                    Invoke-AmdAcquireStage @stageArgs
                }
            }

            'Extract' {
                $null = Invoke-AmdTrackedStage -Name 'Extract' -Body {
                    $stageArgs = @{ MaxDepth = $MaxDepth }
                    if ($SevenZipPath) { $stageArgs['SevenZipPath'] = $SevenZipPath }
                    if ($Force) { $stageArgs['Force'] = $true }
                    Invoke-AmdExtractStage @stageArgs
                }
            }

            'Inspect' {
                $null = Invoke-AmdTrackedStage -Name 'Inspect' -Body {
                    Invoke-AmdInspectStage
                }
            }

            'Build' {
                $null = Invoke-AmdTrackedStage -Name 'Build' -Body {
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
