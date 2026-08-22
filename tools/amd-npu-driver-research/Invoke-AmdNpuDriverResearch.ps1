#requires -Version 5.1
<#
.SYNOPSIS
    Static research and reverse-engineering survey for AMD Ryzen AI NPU driver packages.

.DESCRIPTION
    Research-only tooling for AMD NPU driver packages. The script never executes an AMD
    installer and never modifies vendor payloads. With no arguments, the toolkit performs
    the complete staged workflow: environment/source validation, AMD publication discovery,
    download/cache acquisition, static package analysis, driver-binary contract analysis,
    cross-release comparison, hardware-only driver-track resolution, retained non-authoritative
    CPU/NPU research-reference generation, deterministic public
    publication, validation, and evidence-archive finalization.

    Local ZIP/EXE/MSI/CAB/7z artifacts remain supported through -PackagePath, but they are an override/qualification
    path rather than the default operating model. Static extraction is performed with the same 7-Zip
    discovery/probe model used by the predecessor AMD research toolkits. Runtime failures are captured as stage evidence;
    the top-level runner finalizes an evidence ZIP even when a stage fails or is blocked.

.NOTES
    Project: Deploy-Drivers-For-WindowsServer
    Tool version: 3.0.0
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

    [ValidateSet('ZipOnly', 'ZipAndDirectory')]
    [string]$EvidenceRetention = 'ZipOnly',

    [string]$PublicOutputRoot,

    [Alias('SkipPublic')]
    [switch]$SkipPublicExport,

    [switch]$SkipEvidenceArchive,

    [switch]$IncludePackagesInEvidence,

    [switch]$RequireWindowsClientSignatureQualification,

    [switch]$ResolveHardwareSelection,

    [switch]$UseObservedNpuHardwareIdOverride,

    [string[]]$ObservedNpuHardwareId = @(),

    [ValidateRange(0,999999)]
    [int]$TargetWindowsBuild = 0,

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
$script:ToolVersion = '3.0.0'
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
$script:HardwareSelectionDoc = $null
$script:HardwareSelectionResult = $null
$script:LocalNpuPnpEvidence = $null
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
$script:AmdResearchEvidenceSchemaVersion = 'amd-npu-driver-research-evidence/1.3'
$script:AmdResearchStageResultsSchemaVersion = 'amd-npu-driver-research-stage-results/1.1'
$script:AmdResearchEvidencePrefix = 'AmdNpuDriverResearchEvidence'
$script:AmdResearchDisplayName = 'AMD NPU Driver Research Toolkit'
$script:AmdDriverSignatureAnalysisSchemaVersion = 'amd-npu-driver-signature-analysis/1.0'
$script:AmdDriverSignatureNativeSchemaVersion = 'amd-npu-driver-signature-native-verification/1.0'
$script:NpuSignatureAnalysisDoc = $null
$script:NpuSignatureNativeDoc = $null
$script:NpuToolchainCapabilityEvidence = $null
$script:AmdStageResults = $script:StageResults
$script:AmdEvidenceContext = $null
$script:AmdTranscriptStarted = $false
$script:AmdStageOrdinal = 0
$script:AmdResolvedStageCount = 0
$script:AmdHttpMaximumConcurrency = 1
$script:AmdDownloadRetryCount = $DownloadRetryCount
$script:AmdDownloadTimeoutSeconds = $DownloadTimeoutSeconds
$script:AmdDiagnosticHistoryLimit = 256
$script:AmdDiagnosticBodyPreviewLimit = 2048
$script:AmdDiagnosticTraceContext = $null
$script:AmdDiagnosticCurrentFunction = $null
$script:AmdDiagnosticCurrentStep = $null
$script:AmdWindowsSafeFullPathLimit = 240
$script:AmdWindowsSafeToolRootLimit = 100
$script:AmdVendorRelativePathReserve = 120
$script:AmdPathSafetyAssessment = $null
$script:AmdRequireWindowsClientSignatureQualification = [bool]$RequireWindowsClientSignatureQualification
$script:AmdResearchPathSafetySchemaVersion = 'amd-npu-path-safety-assessment/1.0'
$script:AmdResearchRecommendedRootName = 'AMD-NPU'
# Windows PowerShell 5.1 requires a deterministic source encoding contract.
# The reviewed root script is UTF-8 with BOM + CRLF; generated public files remain UTF-8 no-BOM/LF.
$script:MarkdownEmDash = [string][char]0x2014
$script:MarkdownRightArrow = [string][char]0x2192

function Get-AmdPrivateEvidenceRoot {
    [CmdletBinding()]
    param()

    return (Join-Path (Join-Path $PSScriptRoot 'private') 'evidence')
}

function Get-AmdEvidenceStoragePolicy {
    [CmdletBinding()]
    param()

    $toolRoot = [IO.Path]::GetFullPath((Get-AmdResearchToolkitRoot))
    $canonicalRoot = [IO.Path]::GetFullPath((Join-Path $toolRoot 'private\evidence'))
    return [pscustomobject][ordered]@{
        SchemaVersion = 'amd-research-evidence-storage-policy/1.0'
        ToolRoot = $toolRoot
        CanonicalEvidenceRoot = $canonicalRoot
        RunsDirectoryName = 'runs'
        LatestPointerFileName = 'LATEST-EVIDENCE.txt'
        ExternalStoragePermitted = $false
        UncPermitted = $false
        ReparsePointPermitted = $false
        SubstDrivePermitted = $false
    }
}

function Get-AmdEvidenceSafeLabel {
    [CmdletBinding()]
    param([AllowNull()][string]$Value, [int]$MaximumLength = 48)

    $fragment = ConvertTo-AmdEvidenceSafeFragment -Value $Value
    if ([string]::IsNullOrWhiteSpace($fragment) -or $fragment.Length -le $MaximumLength) { return $fragment }
    $algorithm = [Security.Cryptography.SHA256]::Create()
    try {
        $bytes = [Text.Encoding]::UTF8.GetBytes($fragment)
        $hash = ([BitConverter]::ToString($algorithm.ComputeHash($bytes))).Replace('-', '').ToLowerInvariant().Substring(0, 8)
    }
    finally { $algorithm.Dispose() }
    return ('{0}-{1}' -f $fragment.Substring(0, $MaximumLength - 9), $hash)
}

function Test-AmdEvidenceOutputPolicy {
    [CmdletBinding()]
    param([string]$RequestedPath)

    $policy = Get-AmdEvidenceStoragePolicy
    $candidate = if ([string]::IsNullOrWhiteSpace($RequestedPath)) { $policy.CanonicalEvidenceRoot } else { [IO.Path]::GetFullPath($RequestedPath) }
    $issues = New-Object 'System.Collections.Generic.List[string]'
    $separator = [IO.Path]::DirectorySeparatorChar
    $canonicalWithSeparator = $policy.CanonicalEvidenceRoot.TrimEnd('\', '/') + $separator
    if (-not ($candidate.Equals($policy.CanonicalEvidenceRoot, [StringComparison]::OrdinalIgnoreCase) -or $candidate.StartsWith($canonicalWithSeparator, [StringComparison]::OrdinalIgnoreCase))) {
        $issues.Add(('EvidenceOutputRoot must be the canonical tool-local root or its descendant: {0}' -f $policy.CanonicalEvidenceRoot)) | Out-Null
    }
    if ($candidate.StartsWith('\\')) { $issues.Add('UNC evidence paths are not permitted.') | Out-Null }

    $probe = $candidate
    while (-not [string]::IsNullOrWhiteSpace($probe)) {
        if (Test-Path -LiteralPath $probe) {
            try {
                $item = Get-Item -LiteralPath $probe -Force
                if (($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
                    $issues.Add(('Evidence path traverses a reparse point: {0}' -f $item.FullName)) | Out-Null
                    break
                }
            }
            catch { $issues.Add(('Unable to inspect evidence path component: {0}: {1}' -f $probe, $_.Exception.Message)) | Out-Null; break }
        }
        $parent = Split-Path -Parent $probe
        if ($parent -eq $probe) { break }
        $probe = $parent
    }

    if ($env:OS -eq 'Windows_NT') {
        try {
            $substPath = Join-Path $env:SystemRoot 'System32\subst.exe'
            $substOutput = @(& $substPath 2>&1 | ForEach-Object { [string]$_ })
            if ($LASTEXITCODE -ne 0) { throw ('subst.exe returned exit code {0}' -f $LASTEXITCODE) }
            $drive = [IO.Path]::GetPathRoot($candidate).TrimEnd('\')
            foreach ($line in $substOutput) {
                if ($line -match '^\s*([A-Za-z]:)\\:\s*=>') {
                    if ($drive.Equals($matches[1], [StringComparison]::OrdinalIgnoreCase)) {
                        $issues.Add(('SUBST-backed evidence paths are not permitted: {0}' -f $drive)) | Out-Null
                    }
                }
            }
        }
        catch { $issues.Add(('SUBST mapping diagnostic failed; evidence storage is blocked fail-closed: {0}' -f $_.Exception.Message)) | Out-Null }
    }

    return [pscustomobject][ordered]@{
        SchemaVersion = 'amd-research-evidence-output-policy-assessment/1.0'
        Status = if ($issues.Count -eq 0) { 'Pass' } else { 'Blocked' }
        RequestedPath = $RequestedPath
        ResolvedPath = $candidate
        CanonicalEvidenceRoot = $policy.CanonicalEvidenceRoot
        Issues = @($issues.ToArray())
        OperatorInstruction = ('Move the whole tool to a short local path if necessary, then use {0} or omit -EvidenceOutputRoot.' -f $policy.CanonicalEvidenceRoot)
    }
}

function Resolve-AmdEvidenceOutputRoot {
    [CmdletBinding()]
    param([string]$RequestedPath)

    $assessment = Test-AmdEvidenceOutputPolicy -RequestedPath $RequestedPath
    if ($assessment.Status -ne 'Pass') {
        throw ('Evidence storage policy BLOCKED before research: {0} {1}' -f (@($assessment.Issues) -join ' | '), $assessment.OperatorInstruction)
    }
    return [string]$assessment.ResolvedPath
}

function Test-AmdEvidenceZipIntegrity {
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)][string]$Path)

    Add-Type -AssemblyName System.IO.Compression -ErrorAction SilentlyContinue
    Add-Type -AssemblyName System.IO.Compression.FileSystem -ErrorAction SilentlyContinue
    $archive = $null
    $entryCount = 0
    try {
        $archive = [IO.Compression.ZipFile]::OpenRead($Path)
        foreach ($entry in $archive.Entries) {
            $entryCount++
            $stream = $null
            try {
                $stream = $entry.Open()
                $buffer = New-Object byte[] 65536
                while ($stream.Read($buffer, 0, $buffer.Length) -gt 0) { }
            }
            finally { if ($null -ne $stream) { $stream.Dispose() } }
        }
        return [pscustomobject]@{ Status = 'Pass'; EntryCount = $entryCount; Error = $null }
    }
    catch { return [pscustomobject]@{ Status = 'Fail'; EntryCount = $entryCount; Error = $_.Exception.Message } }
    finally { if ($null -ne $archive) { $archive.Dispose() } }
}

function Write-AmdEvidenceSha256File {
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)][string]$ZipPath, [Parameter(Mandatory = $true)][string]$Sha256Path)

    $hash = Get-AmdSha256 -Path $ZipPath
    Write-AmdUtf8NoBom -Path $Sha256Path -Text ('{0}  {1}{2}' -f $hash, [IO.Path]::GetFileName($ZipPath), [Environment]::NewLine)
    return $hash
}

function Write-AmdLatestEvidencePointer {
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)][object]$Context, [Parameter(Mandatory = $true)][object]$Assessment)

    $text = @(
        'AMD DRIVER RESEARCH - LATEST EVIDENCE',
        ('Tool                 : {0}' -f $Context.ToolDisplayName),
        ('Result               : {0}' -f $Assessment.OverallStatus),
        ('Completed UTC        : {0}' -f (Get-AmdUtcTimestamp)),
        ('EVIDENCE ZIP TO SHARE: {0}' -f $Context.ZipPath),
        ('ZIP SHA-256          : {0}' -f $Context.ZipSha256),
        ('SHA-256 file         : {0}' -f $Context.ZipSha256Path),
        ('Working directory    : {0}' -f $Context.EvidenceDirectory),
        ('Working dir retained : {0}' -f $Context.EvidenceDirectoryRetained),
        'Share the ZIP and its .sha256 companion file.'
    ) -join [Environment]::NewLine
    Write-AmdUtf8NoBom -Path $Context.LatestEvidencePointerPath -Text ($text + [Environment]::NewLine)
}

function Write-AmdEvidenceCompletionBanner {
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)][object]$Context)

    Write-Host ''
    Write-Host '================ EVIDENCE OUTPUT ================' -ForegroundColor Cyan
    if ($Context.ArchiveCreated) {
        Write-Host ('EVIDENCE ZIP TO SHARE : {0}' -f $Context.ZipPath) -ForegroundColor Green
        Write-Host ('EVIDENCE ZIP SHA-256  : {0}' -f $Context.ZipSha256)
        Write-Host ('SHA-256 COMPANION     : {0}' -f $Context.ZipSha256Path)
    }
    else { Write-Host 'EVIDENCE ZIP TO SHARE : NOT CREATED' -ForegroundColor Yellow }
    Write-Host ('LATEST POINTER        : {0}' -f $Context.LatestEvidencePointerPath)
    Write-Host ('EVIDENCE WORK DIR     : {0} ({1})' -f $Context.EvidenceDirectory, $(if ($Context.EvidenceDirectoryRetained) { 'retained' } else { 'removed after verified ZIP' }))
    Write-Host '=================================================' -ForegroundColor Cyan
}


function Write-AmdDiagnosticEvent {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][string]$EventName,
        [ValidateSet('Debug','Info','Warning','Error')][string]$Level='Info',
        [string]$FunctionName,
        [string]$Step,
        [AllowNull()]$Data
    )

    if ($null -eq $script:AmdDiagnosticTraceContext -or -not $script:AmdDiagnosticTraceContext.Enabled) { return }
    try {
        $entry = [pscustomobject][ordered]@{
            SchemaVersion='amd-diagnostic-event/1.0'
            TimestampUtc=(Get-AmdUtcTimestamp)
            Level=$Level
            Event=$EventName
            Stage=$script:AmdCurrentStageName
            Function=if($FunctionName){$FunctionName}else{$script:AmdDiagnosticCurrentFunction}
            Step=if($Step){$Step}else{$script:AmdDiagnosticCurrentStep}
            Data=(Protect-AmdDiagnosticValue -Value $Data)
        }
        $history = $script:AmdDiagnosticTraceContext.History
        $history.Add($entry)
        while ($history.Count -gt [int]$script:AmdDiagnosticTraceContext.HistoryLimit) { $history.RemoveAt(0) }
        $json = $entry | ConvertTo-Json -Depth 12 -Compress
        $utf8 = New-Object System.Text.UTF8Encoding($false)
        [System.IO.File]::AppendAllText($script:AmdDiagnosticTraceContext.EventLogPath, ($json + [Environment]::NewLine), $utf8)
    }
    catch {
        # Diagnostics are best-effort and must never become the cause of a research failure.
    }
}


# --- predecessor shared infrastructure core --------------------------------
# The functions in this block are definition-identical (after line-ending normalization)
# in the reviewed chipset and graphics research tools. NPU-specific code reuses the
# same infrastructure rather than maintaining a third independent implementation.
function Test-AmdSensitiveDiagnosticKey {
    [CmdletBinding()]
    param([AllowNull()][string]$Name)

    if ([string]::IsNullOrWhiteSpace($Name)) { return $false }

    # Structured diagnostic keys use an allow-to-redact contract rather than a broad
    # substring rule. Public research fields such as HasMzSignature,
    # HasZipSignature, SignatureStatus, and SignerSignatureAlgorithm are not secrets.
    $normalized = ([string]$Name).Trim().ToLowerInvariant().Replace('_','-')
    $sensitive = @(
        'authorization',
        'proxy-authorization',
        'cookie',
        'set-cookie',
        'token',
        'access-token',
        'id-token',
        'refresh-token',
        'session-token',
        'secret',
        'password',
        'passwd',
        'api-key',
        'apikey',
        'x-api-key',
        'client-secret',
        'access-key',
        'secret-access-key',
        'credential',
        'credentials',
        'x-amz-security-token',
        'x-amz-credential',
        'x-amz-signature',
        'x-goog-signature',
        'x-ms-signature'
    )
    return ($sensitive -contains $normalized)
}

function Protect-AmdDiagnosticString {
    [CmdletBinding()]
    param([AllowNull()][string]$Value)

    if ($null -eq $Value) { return $null }
    $result = [string]$Value
    $result = [regex]::Replace($result, '(?i)(Bearer\s+)[A-Za-z0-9._~+\-/=]+', '$1<redacted>')
    $result = [regex]::Replace($result, '(?i)([?&](?:token|access_token|api[_-]?key|key|secret|password|passwd|signature|sig)=)[^&#\s]+', '$1<redacted>')
    $result = [regex]::Replace($result, '(?i)([\"'']?(?:token|access_token|api[_-]?key|secret|password|passwd|signature|sig)[\"'']?\s*[:=]\s*[\"'']?)[^\"''&\s<>{},]+', '$1<redacted>')
    return $result
}

function Protect-AmdDiagnosticValue {
    [CmdletBinding()]
    param(
        [AllowNull()]$Value,
        [int]$Depth = 0,
        [int]$MaximumDepth = 8
    )

    if ($null -eq $Value) { return $null }
    if ($Depth -ge $MaximumDepth) { return '<max-depth>' }
    if ($Value -is [string]) { return (Protect-AmdDiagnosticString -Value ([string]$Value)) }
    if ($Value -is [datetime] -or $Value -is [datetimeoffset] -or $Value.GetType().IsPrimitive -or $Value -is [decimal]) { return $Value }

    if ($Value -is [System.Collections.IDictionary]) {
        $map = [ordered]@{}
        foreach ($key in @($Value.Keys)) {
            $name = [string]$key
            $map[$name] = if (Test-AmdSensitiveDiagnosticKey -Name $name) { '<redacted>' } else { Protect-AmdDiagnosticValue -Value $Value[$key] -Depth ($Depth + 1) -MaximumDepth $MaximumDepth }
        }
        return [pscustomobject]$map
    }

    if ($Value -is [System.Management.Automation.PSCustomObject]) {
        $map = [ordered]@{}
        foreach ($prop in @($Value.PSObject.Properties)) {
            $map[$prop.Name] = if (Test-AmdSensitiveDiagnosticKey -Name $prop.Name) { '<redacted>' } else { Protect-AmdDiagnosticValue -Value $prop.Value -Depth ($Depth + 1) -MaximumDepth $MaximumDepth }
        }
        return [pscustomobject]$map
    }

    if ($Value -is [System.Collections.IEnumerable]) {
        $items = New-Object 'System.Collections.Generic.List[object]'
        foreach ($item in $Value) { $items.Add((Protect-AmdDiagnosticValue -Value $item -Depth ($Depth + 1) -MaximumDepth $MaximumDepth)) }
        return ,@($items.ToArray())
    }

    return (Protect-AmdDiagnosticString -Value ([string]$Value))
}

function ConvertTo-AmdRedactedHeaderMap {
    [CmdletBinding()]
    param([AllowNull()]$Headers)

    if ($null -eq $Headers) { return $null }
    $result = [ordered]@{}
    try {
        foreach ($name in @($Headers.AllKeys)) {
            if ([string]::IsNullOrWhiteSpace([string]$name)) { continue }
            $result[[string]$name] = if (Test-AmdSensitiveDiagnosticKey -Name ([string]$name)) { '<redacted>' } else { Protect-AmdDiagnosticString -Value ([string]$Headers[$name]) }
        }
    }
    catch { return [pscustomobject]@{ Error='HeaderEnumerationFailed' } }
    return [pscustomobject]$result
}

function Get-AmdBoundedTextPreview {
    [CmdletBinding()]
    param(
        [AllowNull()][string]$Text,
        [int]$MaximumLength = 2048
    )

    if ($null -eq $Text) { return $null }
    $clean = ($Text -replace '[\u0000-\u0008\u000B\u000C\u000E-\u001F]', '?')
    if ($clean.Length -le $MaximumLength) { return (Protect-AmdDiagnosticString -Value $clean) }
    return ((Protect-AmdDiagnosticString -Value $clean.Substring(0,$MaximumLength)) + '<truncated>')
}

function Get-AmdWebExceptionResponseDiagnostic {
    [CmdletBinding()]
    param(
        [AllowNull()]$Response,
        [int]$BodyPreviewLimit = 2048
    )

    if ($null -eq $Response) { return $null }
    $headers = $null
    $bodyPreview = $null
    $statusCode = $null
    $contentType = $null
    $responseUri = $null
    try { $headers = ConvertTo-AmdRedactedHeaderMap -Headers $Response.Headers } catch { }
    try { $statusCode = [int]$Response.StatusCode } catch { }
    try { $contentType = [string]$Response.ContentType } catch { }
    try { if ($Response.ResponseUri) { $responseUri = Protect-AmdDiagnosticString -Value $Response.ResponseUri.AbsoluteUri } } catch { }

    $stream = $null
    $reader = $null
    try {
        $stream = $Response.GetResponseStream()
        if ($stream) {
            $reader = New-Object System.IO.StreamReader($stream, [System.Text.Encoding]::UTF8, $true, 1024, $true)
            $buffer = New-Object char[] ([Math]::Max(1,$BodyPreviewLimit + 1))
            $count = $reader.ReadBlock($buffer,0,$buffer.Length)
            if ($count -gt 0) { $bodyPreview = Get-AmdBoundedTextPreview -Text (-join $buffer[0..($count-1)]) -MaximumLength $BodyPreviewLimit }
        }
    }
    catch { $bodyPreview = '<response-body-preview-unavailable>' }
    finally { if ($reader) { $reader.Dispose() }; if ($stream) { $stream.Dispose() } }

    return [pscustomobject][ordered]@{
        StatusCode=$statusCode
        ResponseUri=$responseUri
        ContentType=$contentType
        Headers=$headers
        BodyPreview=$bodyPreview
    }
}

function Start-AmdDiagnosticTrace {
    [CmdletBinding()]
    param([Parameter(Mandatory=$true)][string]$EvidenceDirectory)

    $logs = Join-Path $EvidenceDirectory 'logs'
    $errors = Join-Path $EvidenceDirectory 'errors'
    New-AmdDirectory -Path $logs | Out-Null
    New-AmdDirectory -Path $errors | Out-Null
    $snapshots = Join-Path $errors 'failure-snapshots'
    New-AmdDirectory -Path $snapshots | Out-Null

    $script:AmdDiagnosticTraceContext = [pscustomobject][ordered]@{
        SchemaVersion='amd-diagnostic-trace/1.0'
        Enabled=$true
        EventLogPath=(Join-Path $logs 'diagnostic-events.jsonl')
        FailureSnapshotDirectory=$snapshots
        History=(New-Object 'System.Collections.Generic.List[object]')
        HistoryLimit=[int]$script:AmdDiagnosticHistoryLimit
        StartedAtUtc=(Get-AmdUtcTimestamp)
    }
    Write-AmdDiagnosticEvent -EventName 'TraceStarted' -Level 'Info' -FunctionName 'Start-AmdDiagnosticTrace' -Step 'Initialize' -Data @{ HttpMaximumConcurrency=$script:AmdHttpMaximumConcurrency; HistoryLimit=$script:AmdDiagnosticHistoryLimit; BodyPreviewLimit=$script:AmdDiagnosticBodyPreviewLimit }
}

function Set-AmdDiagnosticStep {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][string]$FunctionName,
        [Parameter(Mandatory=$true)][string]$Step,
        [AllowNull()]$Data
    )

    $script:AmdDiagnosticCurrentFunction=$FunctionName
    $script:AmdDiagnosticCurrentStep=$Step
    Write-AmdDiagnosticEvent -EventName 'Step' -Level 'Debug' -FunctionName $FunctionName -Step $Step -Data $Data
}

function Get-AmdExceptionDiagnostic {
    [CmdletBinding()]
    param([AllowNull()]$ErrorRecord)

    if ($null -eq $ErrorRecord) { return $null }
    $chain = New-Object 'System.Collections.Generic.List[object]'
    $ex = $ErrorRecord.Exception
    $depth = 0
    while ($null -ne $ex -and $depth -lt 8) {
        $chain.Add([pscustomobject][ordered]@{ Type=$ex.GetType().FullName; Message=(Protect-AmdDiagnosticString -Value $ex.Message); HResult=$ex.HResult })
        $ex=$ex.InnerException; $depth++
    }
    return [pscustomobject][ordered]@{
        ExceptionChain=@($chain.ToArray())
        FullyQualifiedErrorId=[string]$ErrorRecord.FullyQualifiedErrorId
        Category=[string]$ErrorRecord.CategoryInfo
        ScriptStackTrace=[string]$ErrorRecord.ScriptStackTrace
        Invocation=[pscustomobject][ordered]@{
            ScriptName=[string]$ErrorRecord.InvocationInfo.ScriptName
            ScriptLineNumber=[int]$ErrorRecord.InvocationInfo.ScriptLineNumber
            OffsetInLine=[int]$ErrorRecord.InvocationInfo.OffsetInLine
            Line=(Get-AmdBoundedTextPreview -Text ([string]$ErrorRecord.InvocationInfo.Line) -MaximumLength 1000)
        }
    }
}

function Write-AmdFailureSnapshot {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][string]$Scope,
        [AllowNull()]$ErrorRecord,
        [AllowNull()]$AdditionalData
    )

    if ($null -eq $script:AmdDiagnosticTraceContext) { return $null }
    try {
        $safe = ConvertTo-AmdEvidenceSafeFragment -Value $Scope
        $stamp = [DateTime]::UtcNow.ToString('yyyyMMdd-HHmmss-fff')
        $path = Join-Path $script:AmdDiagnosticTraceContext.FailureSnapshotDirectory ('failure-{0}-{1}.json' -f $stamp,$safe)
        $snapshot = [pscustomobject][ordered]@{
            SchemaVersion='amd-diagnostic-failure-snapshot/1.0'
            CapturedAtUtc=(Get-AmdUtcTimestamp)
            ToolkitVersion=$script:AmdResearchToolkitVersion
            Scope=$Scope
            Stage=$script:AmdCurrentStageName
            Function=$script:AmdDiagnosticCurrentFunction
            Step=$script:AmdDiagnosticCurrentStep
            HttpMaximumConcurrency=$script:AmdHttpMaximumConcurrency
            Error=(Get-AmdExceptionDiagnostic -ErrorRecord $ErrorRecord)
            AdditionalData=(Protect-AmdDiagnosticValue -Value $AdditionalData)
            RecentEvents=@($script:AmdDiagnosticTraceContext.History.ToArray())
        }
        Write-AmdJsonFile -Path $path -Value $snapshot -Depth 20
        Write-AmdDiagnosticEvent -EventName 'FailureSnapshotWritten' -Level 'Error' -FunctionName 'Write-AmdFailureSnapshot' -Step $Scope -Data @{ Path=$path }
        return $path
    }
    catch { return $null }
}

function Stop-AmdDiagnosticTrace {
    [CmdletBinding()]
    param([AllowNull()]$Assessment)

    if ($null -eq $script:AmdDiagnosticTraceContext) { return }
    Write-AmdDiagnosticEvent -EventName 'TraceStopped' -Level 'Info' -FunctionName 'Stop-AmdDiagnosticTrace' -Step 'Finalize' -Data @{ OverallStatus=if($Assessment){$Assessment.OverallStatus}else{$null}; ExitCode=if($Assessment){$Assessment.ExitCode}else{$null} }
}

function Test-AmdDiagnosticPrimitiveSelfTest {
    [CmdletBinding()]
    param()

    $headers = New-Object System.Net.WebHeaderCollection
    $headers['Authorization']='Bearer abc.def.ghi'
    $headers['Cookie']='session=secret'
    $headers['X-Test']='visible'
    $redacted = ConvertTo-AmdRedactedHeaderMap -Headers $headers
    $url = Protect-AmdDiagnosticString -Value 'https://example.invalid/path?token=secret&x=1'
    $preview = Get-AmdBoundedTextPreview -Text ('x' * 3000) -MaximumLength 128
    $protectedArray = @(Protect-AmdDiagnosticValue -Value @('one'))
    $protectedSignatureEvidence = Protect-AmdDiagnosticValue -Value ([pscustomobject][ordered]@{
        HasMzSignature = $true
        HasZipSignature = $false
        SignatureStatus = 'Verified'
        'X-Amz-Signature' = 'secret-signature-token'
    })
    $signatureEvidencePreserved = (
        $protectedSignatureEvidence.HasMzSignature -eq $true -and
        $protectedSignatureEvidence.HasZipSignature -eq $false -and
        [string]$protectedSignatureEvidence.SignatureStatus -eq 'Verified'
    )
    $signedUrlCredentialRedacted = ([string]$protectedSignatureEvidence.'X-Amz-Signature' -eq '<redacted>')

    $ok = (
        [string]$redacted.Authorization -eq '<redacted>' -and
        [string]$redacted.Cookie -eq '<redacted>' -and
        [string]$redacted.'X-Test' -eq 'visible' -and
        $url -notmatch 'secret' -and
        $preview.Length -le 139 -and
        $protectedArray.Count -eq 1 -and $protectedArray[0] -eq 'one' -and
        $signatureEvidencePreserved -and
        $signedUrlCredentialRedacted -and
        $script:AmdHttpMaximumConcurrency -eq 1
    )
    return [pscustomobject][ordered]@{
        Status=if($ok){'Pass'}else{'Fail'}
        SensitiveHeadersRedacted=([string]$redacted.Authorization -eq '<redacted>' -and [string]$redacted.Cookie -eq '<redacted>')
        NonSensitiveHeaderPreserved=([string]$redacted.'X-Test' -eq 'visible')
        SensitiveQueryRedacted=($url -notmatch 'secret')
        BodyPreviewBounded=($preview.Length -le 139)
        ProtectedArrayCardinality=($protectedArray.Count -eq 1 -and $protectedArray[0] -eq 'one')
        NonSecretSignatureEvidencePreserved=$signatureEvidencePreserved
        SignedUrlCredentialRedacted=$signedUrlCredentialRedacted
        HttpMaximumConcurrency=$script:AmdHttpMaximumConcurrency
        SequentialHttpPolicy=($script:AmdHttpMaximumConcurrency -eq 1)
    }
}

function Test-AmdSequentialDownloadSourceContract {
    [CmdletBinding()]
    param([Parameter(Mandatory=$true)][string]$Path)

    $tokens=$null; $errors=$null
    $ast=[System.Management.Automation.Language.Parser]::ParseFile($Path,[ref]$tokens,[ref]$errors)
    $forbidden=@('Start-Job','Start-ThreadJob')
    $commandHits=New-Object 'System.Collections.Generic.List[string]'
    foreach($commandAst in @($ast.FindAll({param($node) $node -is [System.Management.Automation.Language.CommandAst]},$true))) {
        $name=$commandAst.GetCommandName()
        if($name -and $forbidden -contains $name){$commandHits.Add($name)}
        if($name -eq 'ForEach-Object') {
            $text=[string]$commandAst.Extent.Text
            if($text -match '(?i)-Parallel(?:\s|$)'){$commandHits.Add('ForEach-Object -Parallel')}
        }
    }
    $unique=@($commandHits | Sort-Object -Unique)
    return [pscustomobject][ordered]@{
        Status=if($errors.Count -eq 0 -and $unique.Count -eq 0 -and $script:AmdHttpMaximumConcurrency -eq 1){'Pass'}else{'Fail'}
        HttpMaximumConcurrency=$script:AmdHttpMaximumConcurrency
        ForbiddenConcurrencyPrimitiveHits=@($unique)
        ParseErrorCount=@($errors).Count
    }
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

function Invoke-AmdTimedOperation {
    [CmdletBinding()]
    param([Parameter(Mandatory=$true)][string]$Name,[Parameter(Mandatory=$true)][scriptblock]$Operation)
    $started=Get-Date;Write-Host ('[CHECK] START {0}' -f $Name) -ForegroundColor Cyan
    try{$result=& $Operation;Write-Host ('[CHECK] DONE  {0} ({1})' -f $Name,(Format-AmdElapsed ((Get-Date)-$started))) -ForegroundColor Green;return $result}
    catch{Write-Host ('[CHECK] FAIL  {0} ({1}): {2}' -f $Name,(Format-AmdElapsed ((Get-Date)-$started)),$_.Exception.Message) -ForegroundColor Red;throw}
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
        [int]$MaximumRedirection = 10,
        [int]$MaximumAttempts = 4,
        [int]$BaseRetryDelayMilliseconds = 1000,
        [int]$MaximumRetryDelayMilliseconds = 15000
    )

    $attempts = New-Object 'System.Collections.Generic.List[object]'
    $attemptCount = [Math]::Max(1, $MaximumAttempts)
    $lastResult = $null

    for ($attempt = 1; $attempt -le $attemptCount; $attempt++) {
        $request = $null
        $response = $null
        $stream = $null
        $memory = $null
        $statusCode = $null
        $contentType = $null
        $responseUri = $null
        $retryAfterHeader = $null
        $webExceptionStatus = $null
        $errorText = $null
        $classification = $null
        $retryable = $false
        $retryReason = $null
        $delayMs = [int64]0
        $noCache = ($attempt -gt 1)
        $disableKeepAlive = ($attempt -gt 1)
        $responseHeaders = $null
        $responseBodyPreview = $null

        Set-AmdDiagnosticStep -FunctionName 'Invoke-AmdQuietTextRequest' -Step 'HttpAttempt' -Data @{ Uri=$Uri; Attempt=$attempt; MaximumAttempts=$attemptCount; NoCache=$noCache; DisableKeepAlive=$disableKeepAlive }
        try {
            $request = New-AmdHttpRequest `
                -Uri $Uri `
                -Referer $Referer `
                -TimeoutSec $TimeoutSec `
                -MaximumRedirection $MaximumRedirection `
                -NoCache:$noCache `
                -DisableKeepAlive:$disableKeepAlive

            $response = [System.Net.HttpWebResponse]$request.GetResponse()
            $statusCode = [int]$response.StatusCode
            $contentType = [string]$response.ContentType
            $responseUri = if ($response.ResponseUri) { $response.ResponseUri.AbsoluteUri } else { $Uri }
            $retryAfterHeader = [string]$response.Headers['Retry-After']

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

            $responseHeaders = ConvertTo-AmdRedactedHeaderMap -Headers $response.Headers
            $attempts.Add([pscustomobject][ordered]@{
                Attempt=$attempt
                NoCache=$noCache
                DisableKeepAlive=$disableKeepAlive
                StatusCode=$statusCode
                ResponseUri=$responseUri
                ContentType=$contentType
                RetryAfter=$retryAfterHeader
                WebExceptionStatus=$null
                Classification='Success'
                Retryable=$false
                RetryReason=$null
                DelayBeforeNextAttemptMilliseconds=0
                ResponseHeaders=$responseHeaders
                ResponseBodyPreview=$null
                Error=$null
            })
            Write-AmdDiagnosticEvent -EventName 'HttpRequestSucceeded' -Level 'Info' -FunctionName 'Invoke-AmdQuietTextRequest' -Step 'HttpAttempt' -Data @{ Uri=$Uri; Attempt=$attempt; StatusCode=$statusCode; ResponseUri=$responseUri; ContentType=$contentType }

            return [pscustomobject][ordered]@{
                Success=$true
                StatusCode=$statusCode
                ContentType=$contentType
                ResponseUri=$responseUri
                Content=$content
                Attempts=@($attempts.ToArray())
                Error=$null
            }
        }
        catch [System.Net.WebException] {
            $webExceptionStatus = [string]$_.Exception.Status
            $reason = $_.Exception.Message
            if ($_.Exception.Response) {
                try {
                    $webResponse = [System.Net.HttpWebResponse]$_.Exception.Response
                    $statusCode = [int]$webResponse.StatusCode
                    $reason = [string]$webResponse.StatusDescription
                    $contentType = [string]$webResponse.ContentType
                    $retryAfterHeader = [string]$webResponse.Headers['Retry-After']
                    if ($webResponse.ResponseUri) { $responseUri = $webResponse.ResponseUri.AbsoluteUri }
                    $responseDiagnostic = Get-AmdWebExceptionResponseDiagnostic -Response $webResponse -BodyPreviewLimit $script:AmdDiagnosticBodyPreviewLimit
                    if ($responseDiagnostic) {
                        $responseHeaders = $responseDiagnostic.Headers
                        $responseBodyPreview = $responseDiagnostic.BodyPreview
                    }
                }
                catch { }
            }

            $classification = if ($statusCode) { 'HttpError' } else { 'TransportError' }
            $errorText = if ($statusCode) {
                'HTTP {0} {1} for {2}' -f $statusCode,$reason,$Uri
            }
            else {
                'HTTP request failed for {0}: {1}' -f $Uri,(Get-AmdCompactErrorMessage -Message $_.Exception.Message -MaximumLength 300)
            }
        }
        catch {
            $classification = 'UnexpectedRequestFailure'
            $errorText = Get-AmdCompactErrorMessage -Message $_.Exception.Message -MaximumLength 400
        }
        finally {
            if ($memory) { $memory.Dispose() }
            if ($stream) { $stream.Dispose() }
            if ($response) { $response.Close() }
        }

        $retryDecision = Get-AmdHttpRetryDecision `
            -StatusCode $statusCode `
            -WebExceptionStatus $webExceptionStatus `
            -Classification $classification
        $retryable = [bool]$retryDecision.Retryable
        $retryReason = [string]$retryDecision.Reason

        $retryAfterMs = Get-AmdRetryAfterMilliseconds -RetryAfter $retryAfterHeader
        if ($retryable -and $attempt -lt $attemptCount) {
            $delayMs = Get-AmdRetryDelayMilliseconds `
                -Attempt $attempt `
                -BaseDelayMilliseconds $BaseRetryDelayMilliseconds `
                -MaximumDelayMilliseconds $MaximumRetryDelayMilliseconds `
                -RetryAfterMilliseconds $retryAfterMs
        }

        $attempts.Add([pscustomobject][ordered]@{
            Attempt=$attempt
            NoCache=$noCache
            DisableKeepAlive=$disableKeepAlive
            StatusCode=$statusCode
            ResponseUri=$responseUri
            ContentType=$contentType
            RetryAfter=$retryAfterHeader
            WebExceptionStatus=$webExceptionStatus
            Classification=$classification
            Retryable=$retryable
            RetryReason=$retryReason
            DelayBeforeNextAttemptMilliseconds=$delayMs
            ResponseHeaders=$responseHeaders
            ResponseBodyPreview=$responseBodyPreview
            Error=$errorText
        })
        Write-AmdDiagnosticEvent -EventName 'HttpRequestFailed' -Level $(if($retryable){'Warning'}else{'Error'}) -FunctionName 'Invoke-AmdQuietTextRequest' -Step 'HttpAttempt' -Data @{ Uri=$Uri; Attempt=$attempt; StatusCode=$statusCode; WebExceptionStatus=$webExceptionStatus; Classification=$classification; Retryable=$retryable; RetryReason=$retryReason; DelayBeforeNextAttemptMilliseconds=$delayMs; ResponseHeaders=$responseHeaders; ResponseBodyPreview=$responseBodyPreview; Error=$errorText }

        $lastResult = [pscustomobject][ordered]@{
            Success=$false
            StatusCode=$statusCode
            ContentType=$contentType
            ResponseUri=$responseUri
            Content=$null
            Attempts=@($attempts.ToArray())
            Error=$errorText
        }

        if (-not $retryable -or $attempt -ge $attemptCount) { break }
        if ($delayMs -gt 0) { Start-Sleep -Milliseconds ([int]$delayMs) }
    }

    return $lastResult
}

function Invoke-AmdQuietFileDownload {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$Uri,
        [Parameter(Mandatory = $true)][string]$OutFile,
        [string]$Referer,
        [int]$TimeoutSec = 600,
        [int]$MaximumRedirection = 10,
        [int]$MaximumAttempts = 4,
        [int]$BaseRetryDelayMilliseconds = 1000,
        [int]$MaximumRetryDelayMilliseconds = 15000,
        [string]$DiagnosticDirectory,
        [string]$DiagnosticPrefix = 'invalid-download'
    )

    # AMD explicitly requires a valid HTTP referrer for protected driver downloads.
    # Each attempt uses a fresh CookieContainer, warms the release-note page first,
    # and then downloads the installer with that same session and referrer. A second
    # attempt uses cache-bypass semantics to avoid replaying a bad CDN/cache response.
    # Transport success is not accepted merely because GetResponse() succeeded: an
    # unsolicited partial response, Download-Incomplete redirect, byte-count mismatch,
    # or non-installer payload is evidence and triggers a fresh-session retry.
    $attemptEvidence = New-Object 'System.Collections.Generic.List[object]'
    $lastError = $null
    $attemptCount = [Math]::Max(1, $MaximumAttempts)

    $directory = Split-Path -Parent $OutFile
    if ($directory) { New-AmdDirectory -Path $directory | Out-Null }
    if (Test-Path -LiteralPath $OutFile -PathType Leaf) { Remove-Item -LiteralPath $OutFile -Force -ErrorAction SilentlyContinue }

    for ($attempt = 1; $attempt -le $attemptCount; $attempt++) {
        $response = $null
        $stream = $null
        $file = $null
        $partialPath = '{0}.partial.{1}.{2}' -f $OutFile,$PID,$attempt
        Remove-Item -LiteralPath $partialPath -Force -ErrorAction SilentlyContinue
        $cookies = New-Object System.Net.CookieContainer
        $noCache = ($attempt -gt 1)
        $disableKeepAlive = ($attempt -gt 1)
        $retryAfterHeader = $null
        $webExceptionStatus = $null
        $retryable = $false
        $retryReason = $null
        $delayMs = [int64]0
        $responseHeaders = $null
        $responseBodyPreview = $null
        Set-AmdDiagnosticStep -FunctionName 'Invoke-AmdQuietFileDownload' -Step 'DownloadAttempt' -Data @{ Uri=$Uri; Attempt=$attempt; MaximumAttempts=$attemptCount; OutFile=$OutFile; NoCache=$noCache; DisableKeepAlive=$disableKeepAlive }
        $warmup = Invoke-AmdDownloadSessionWarmup -Uri $Referer -CookieContainer $cookies -TimeoutSec ([Math]::Min($TimeoutSec,90)) -MaximumRedirection $MaximumRedirection -NoCache:$noCache

        $statusCode = $null
        $responseUri = $null
        $contentRange = $null
        $contentLength = [long]-1
        $contentType = $null
        $contentEncoding = $null
        $acceptRanges = $null
        $bytesWritten = [long]0
        $classification = $null
        $diagnosticPath = $null
        $validation = $null

        try {
            $request = New-AmdHttpRequest -Uri $Uri -Referer $Referer -TimeoutSec $TimeoutSec -MaximumRedirection $MaximumRedirection -CookieContainer $cookies -NoCache:$noCache -DisableKeepAlive:$disableKeepAlive
            $response = [System.Net.HttpWebResponse]$request.GetResponse()
            $statusCode = [int]$response.StatusCode
            $responseUri = if ($response.ResponseUri) { $response.ResponseUri.AbsoluteUri } else { $Uri }
            $contentRange = [string]$response.Headers['Content-Range']
            $contentLength = [long]$response.ContentLength
            $contentType = [string]$response.ContentType
            $contentEncoding = [string]$response.ContentEncoding
            $acceptRanges = [string]$response.Headers['Accept-Ranges']
            $retryAfterHeader = [string]$response.Headers['Retry-After']
            $responseHeaders = ConvertTo-AmdRedactedHeaderMap -Headers $response.Headers

            $decision = Get-AmdHttpDownloadResponseDecision -StatusCode $statusCode -ContentRange $contentRange -ContentLength $contentLength -ResponseUri $responseUri
            $classification = [string]$decision.Classification
            if (-not $decision.Accept) { throw [System.IO.InvalidDataException]::new([string]$decision.Detail) }

            $stream = $response.GetResponseStream()
            $file = [System.IO.File]::Open($partialPath, [System.IO.FileMode]::CreateNew, [System.IO.FileAccess]::Write, [System.IO.FileShare]::None)
            $stream.CopyTo($file)
            $file.Flush()
            $file.Dispose(); $file = $null
            $stream.Dispose(); $stream = $null
            $bytesWritten = [long](Get-Item -LiteralPath $partialPath).Length

            $expectedBytes = if ($null -ne $decision.ExpectedBytes) { [long]$decision.ExpectedBytes } elseif ($contentLength -ge 0) { $contentLength } else { [long]-1 }
            $validation = Get-AmdInstallerFileValidation -Path $partialPath
            $payloadDecision = Get-AmdDownloadedPayloadDecision -ExpectedBytes $expectedBytes -BytesWritten $bytesWritten -Validation $validation
            if (-not $payloadDecision.Accept) {
                $classification = [string]$payloadDecision.Classification
                if ($DiagnosticDirectory -and $bytesWritten -gt 0) {
                    New-AmdDirectory -Path $DiagnosticDirectory | Out-Null
                    $diagName = '{0}-attempt{1}-{2}' -f $DiagnosticPrefix,$attempt,[System.IO.Path]::GetFileName($OutFile)
                    $diagnosticPath = Join-Path $DiagnosticDirectory $diagName
                    Copy-Item -LiteralPath $partialPath -Destination $diagnosticPath -Force -ErrorAction SilentlyContinue
                }
                throw [System.IO.InvalidDataException]::new([string]$payloadDecision.Detail)
            }

            Move-Item -LiteralPath $partialPath -Destination $OutFile -Force
            $attemptEvidence.Add([pscustomobject][ordered]@{
                Attempt=$attempt;NoCache=$noCache;DisableKeepAlive=$disableKeepAlive;Warmup=$warmup;StatusCode=$statusCode;ResponseUri=$responseUri
                ContentRange=$contentRange;ContentLength=$contentLength;ContentType=$contentType;ContentEncoding=$contentEncoding;AcceptRanges=$acceptRanges;RetryAfter=$retryAfterHeader
                BytesWritten=$bytesWritten;Classification=$classification;Validation=$validation;DiagnosticPath=$diagnosticPath
                WebExceptionStatus=$null;Retryable=$false;RetryReason=$null;DelayBeforeNextAttemptMilliseconds=0
                ResponseHeaders=$responseHeaders;ResponseBodyPreview=$null;Error=$null
            })
            Write-AmdDiagnosticEvent -EventName 'DownloadAttemptSucceeded' -Level 'Info' -FunctionName 'Invoke-AmdQuietFileDownload' -Step 'DownloadAttempt' -Data @{ Uri=$Uri; Attempt=$attempt; StatusCode=$statusCode; ResponseUri=$responseUri; BytesWritten=$bytesWritten; Validation=$validation }
            return [pscustomobject][ordered]@{
                Success=$true;StatusCode=$statusCode;ResponseUri=$responseUri;Classification=$classification;BytesWritten=$bytesWritten
                ContentRange=$contentRange;ContentLength=$contentLength;ContentType=$contentType;Attempts=@($attemptEvidence.ToArray());Error=$null
            }
        }
        catch [System.Net.WebException] {
            $webExceptionStatus = [string]$_.Exception.Status
            $reason = $_.Exception.Message
            if ($_.Exception.Response) {
                try {
                    $webResponse = [System.Net.HttpWebResponse]$_.Exception.Response
                    $statusCode = [int]$webResponse.StatusCode
                    $reason = [string]$webResponse.StatusDescription
                    if ($webResponse.ResponseUri) { $responseUri = $webResponse.ResponseUri.AbsoluteUri }
                    $contentRange = [string]$webResponse.Headers['Content-Range']
                    $contentLength = [long]$webResponse.ContentLength
                    $contentType = [string]$webResponse.ContentType
                    $retryAfterHeader = [string]$webResponse.Headers['Retry-After']
                    $responseDiagnostic = Get-AmdWebExceptionResponseDiagnostic -Response $webResponse -BodyPreviewLimit $script:AmdDiagnosticBodyPreviewLimit
                    if ($responseDiagnostic) {
                        $responseHeaders = $responseDiagnostic.Headers
                        $responseBodyPreview = $responseDiagnostic.BodyPreview
                    }
                }
                catch { }
            }
            $classification = if($statusCode){'HttpError'}else{'TransportError'}
            $lastError = if ($statusCode) { 'HTTP {0} {1} for {2}' -f $statusCode,$reason,$Uri } else { 'HTTP request failed for {0}: {1}' -f $Uri,(Get-AmdCompactErrorMessage -Message $_.Exception.Message -MaximumLength 300) }
        }
        catch {
            if (-not $classification) { $classification = 'DownloadRejected' }
            $lastError = Get-AmdCompactErrorMessage -Message $_.Exception.Message -MaximumLength 500
        }
        finally {
            if ($file) { $file.Dispose() }
            if ($stream) { $stream.Dispose() }
            if ($response) { $response.Close() }
        }

        if (Test-Path -LiteralPath $partialPath -PathType Leaf) { Remove-Item -LiteralPath $partialPath -Force -ErrorAction SilentlyContinue }
        if (Test-Path -LiteralPath $OutFile -PathType Leaf) { Remove-Item -LiteralPath $OutFile -Force -ErrorAction SilentlyContinue }

        $retryDecision = Get-AmdHttpRetryDecision `
            -StatusCode $statusCode `
            -WebExceptionStatus $webExceptionStatus `
            -Classification $classification
        $retryable = [bool]$retryDecision.Retryable
        $retryReason = [string]$retryDecision.Reason
        $retryAfterMs = Get-AmdRetryAfterMilliseconds -RetryAfter $retryAfterHeader

        if ($retryable -and $attempt -lt $attemptCount) {
            $delayMs = Get-AmdRetryDelayMilliseconds `
                -Attempt $attempt `
                -BaseDelayMilliseconds $BaseRetryDelayMilliseconds `
                -MaximumDelayMilliseconds $MaximumRetryDelayMilliseconds `
                -RetryAfterMilliseconds $retryAfterMs
        }

        $attemptEvidence.Add([pscustomobject][ordered]@{
            Attempt=$attempt;NoCache=$noCache;DisableKeepAlive=$disableKeepAlive;Warmup=$warmup;StatusCode=$statusCode;ResponseUri=$responseUri
            ContentRange=$contentRange;ContentLength=$contentLength;ContentType=$contentType;ContentEncoding=$contentEncoding;AcceptRanges=$acceptRanges;RetryAfter=$retryAfterHeader
            BytesWritten=$bytesWritten;Classification=$classification;Validation=$validation;DiagnosticPath=$diagnosticPath
            WebExceptionStatus=$webExceptionStatus;Retryable=$retryable;RetryReason=$retryReason;DelayBeforeNextAttemptMilliseconds=$delayMs
            ResponseHeaders=$responseHeaders;ResponseBodyPreview=$responseBodyPreview;Error=$lastError
        })
        Write-AmdDiagnosticEvent -EventName 'DownloadAttemptFailed' -Level $(if($retryable){'Warning'}else{'Error'}) -FunctionName 'Invoke-AmdQuietFileDownload' -Step 'DownloadAttempt' -Data @{ Uri=$Uri; Attempt=$attempt; StatusCode=$statusCode; WebExceptionStatus=$webExceptionStatus; Classification=$classification; Retryable=$retryable; RetryReason=$retryReason; DelayBeforeNextAttemptMilliseconds=$delayMs; BytesWritten=$bytesWritten; ResponseHeaders=$responseHeaders; ResponseBodyPreview=$responseBodyPreview; Error=$lastError }

        if (-not $retryable -or $attempt -ge $attemptCount) { break }
        if ($delayMs -gt 0) { Start-Sleep -Milliseconds ([int]$delayMs) }
    }

    return [pscustomobject][ordered]@{
        Success=$false;StatusCode=$statusCode;ResponseUri=$responseUri;Classification=$classification;BytesWritten=$bytesWritten
        ContentRange=$contentRange;ContentLength=$contentLength;ContentType=$contentType;Attempts=@($attemptEvidence.ToArray());Error=$lastError
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

function Get-AmdRetryAfterMilliseconds {
    [CmdletBinding()]
    param(
        [AllowNull()][string]$RetryAfter,
        [datetime]$NowUtc = ([DateTime]::UtcNow),
        [int]$MaximumRetryAfterMilliseconds = 60000
    )

    if ([string]::IsNullOrWhiteSpace($RetryAfter)) { return $null }

    $seconds = 0
    if ([int]::TryParse($RetryAfter.Trim(), [ref]$seconds)) {
        if ($seconds -lt 0) { return $null }
        return [Math]::Min([int64]$MaximumRetryAfterMilliseconds, ([int64]$seconds * 1000))
    }

    $retryDate = [datetime]::MinValue
    if ([datetime]::TryParse(
        $RetryAfter,
        [System.Globalization.CultureInfo]::InvariantCulture,
        [System.Globalization.DateTimeStyles]::AssumeUniversal,
        [ref]$retryDate
    )) {
        $delay = [int64][Math]::Ceiling(($retryDate.ToUniversalTime() - $NowUtc.ToUniversalTime()).TotalMilliseconds)
        if ($delay -le 0) { return 0 }
        return [Math]::Min([int64]$MaximumRetryAfterMilliseconds, $delay)
    }

    return $null
}

function Get-AmdHttpRetryDecision {
    [CmdletBinding()]
    param(
        [AllowNull()][Nullable[int]]$StatusCode,
        [AllowNull()][string]$WebExceptionStatus,
        [AllowNull()][string]$Classification
    )

    $status = if ($null -ne $StatusCode) { [int]$StatusCode } else { $null }
    $webStatus = [string]$WebExceptionStatus
    $class = [string]$Classification

    if ($status -in @(408,425,429,500,502,503,504)) {
        return [pscustomobject][ordered]@{ Retryable=$true; Reason=('RetryableHttpStatus:{0}' -f $status) }
    }

    # AMD has previously returned transient 403 responses from discovery endpoints.
    # Retry conservatively with backoff/fresh transport rather than immediately
    # treating the response as a permanent authorization failure.
    if ($status -eq 403) {
        return [pscustomobject][ordered]@{ Retryable=$true; Reason='AmdHttp403TransientOrWaf' }
    }

    if ($status -in @(400,401,404,405,410,422)) {
        return [pscustomobject][ordered]@{ Retryable=$false; Reason=('NonRetryableHttpStatus:{0}' -f $status) }
    }

    if ($class -in @(
        'AmdDownloadIncompleteRedirect',
        'UnexpectedContentRange',
        'PartialContentRejected',
        'ByteCountMismatch',
        'EmptyResponseBody',
        'InstallerPayloadValidationFailed',
        'TransportError'
    )) {
        return [pscustomobject][ordered]@{ Retryable=$true; Reason=('RetryableClassification:{0}' -f $class) }
    }

    if ($webStatus -in @(
        'Timeout',
        'ConnectFailure',
        'ConnectionClosed',
        'ReceiveFailure',
        'SendFailure',
        'PipelineFailure',
        'KeepAliveFailure',
        'NameResolutionFailure',
        'ProxyNameResolutionFailure',
        'RequestCanceled'
    )) {
        return [pscustomobject][ordered]@{ Retryable=$true; Reason=('RetryableWebException:{0}' -f $webStatus) }
    }

    if ($status) {
        return [pscustomobject][ordered]@{ Retryable=$false; Reason=('HttpStatusNotInRetryPolicy:{0}' -f $status) }
    }

    return [pscustomobject][ordered]@{ Retryable=$false; Reason='UnclassifiedFailure' }
}

function Get-AmdRetryDelayMilliseconds {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][int]$Attempt,
        [int]$BaseDelayMilliseconds = 1000,
        [int]$MaximumDelayMilliseconds = 15000,
        [AllowNull()][Nullable[long]]$RetryAfterMilliseconds,
        [AllowNull()][Nullable[int]]$JitterMilliseconds
    )

    $safeAttempt = [Math]::Max(1, $Attempt)
    $power = [Math]::Min(20, ($safeAttempt - 1))
    $base = [int64]$BaseDelayMilliseconds * [int64][Math]::Pow(2, $power)
    $delay = [Math]::Min([int64]$MaximumDelayMilliseconds, $base)

    $jitter = if ($null -ne $JitterMilliseconds) {
        [Math]::Max(0, [int]$JitterMilliseconds)
    }
    else {
        Get-Random -Minimum 0 -Maximum 501
    }
    $delay = [Math]::Min([int64]$MaximumDelayMilliseconds, ($delay + $jitter))

    if ($null -ne $RetryAfterMilliseconds -and [long]$RetryAfterMilliseconds -gt $delay) {
        $delay = [long]$RetryAfterMilliseconds
    }

    return [int64]$delay
}

function Test-AmdHttpRetryPolicySelfTest {
    [CmdletBinding()]
    param()

    $connectionClosed = Get-AmdHttpRetryDecision -WebExceptionStatus 'ConnectionClosed'
    $http429 = Get-AmdHttpRetryDecision -StatusCode 429
    $http403 = Get-AmdHttpRetryDecision -StatusCode 403
    $http404 = Get-AmdHttpRetryDecision -StatusCode 404
    $partial = Get-AmdHttpRetryDecision -Classification 'PartialContentRejected'

    $d1 = Get-AmdRetryDelayMilliseconds -Attempt 1 -BaseDelayMilliseconds 1000 -MaximumDelayMilliseconds 10000 -JitterMilliseconds 0
    $d2 = Get-AmdRetryDelayMilliseconds -Attempt 2 -BaseDelayMilliseconds 1000 -MaximumDelayMilliseconds 10000 -JitterMilliseconds 0
    $d3 = Get-AmdRetryDelayMilliseconds -Attempt 3 -BaseDelayMilliseconds 1000 -MaximumDelayMilliseconds 10000 -JitterMilliseconds 0
    $retryAfter = Get-AmdRetryAfterMilliseconds -RetryAfter '5' -MaximumRetryAfterMilliseconds 60000

    $ok = (
        $connectionClosed.Retryable -and
        $http429.Retryable -and
        $http403.Retryable -and
        -not $http404.Retryable -and
        $partial.Retryable -and
        $d1 -eq 1000 -and
        $d2 -eq 2000 -and
        $d3 -eq 4000 -and
        $retryAfter -eq 5000
    )

    return [pscustomobject][ordered]@{
        Status = if ($ok) { 'Pass' } else { 'Fail' }
        ConnectionClosedRetryable = [bool]$connectionClosed.Retryable
        Http429Retryable = [bool]$http429.Retryable
        Http403Retryable = [bool]$http403.Retryable
        Http404Retryable = [bool]$http404.Retryable
        PartialContentRetryable = [bool]$partial.Retryable
        BackoffMilliseconds = @($d1,$d2,$d3)
        RetryAfterMilliseconds = $retryAfter
    }
}

function Get-AmdHttpDownloadResponseDecision {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][int]$StatusCode,
        [AllowNull()][string]$ContentRange,
        [long]$ContentLength = -1,
        [AllowNull()][string]$ResponseUri
    )

    if ($ResponseUri -and $ResponseUri -match '(?i)/Download-Incomplete(?:\.html)?(?:[?#]|$)') {
        return [pscustomobject][ordered]@{ Accept=$false; Classification='AmdDownloadIncompleteRedirect'; ExpectedBytes=$null; Detail='AMD redirected the request to Download-Incomplete.' }
    }

    if ($StatusCode -eq 200) {
        if (-not [string]::IsNullOrWhiteSpace($ContentRange)) {
            return [pscustomobject][ordered]@{ Accept=$false; Classification='UnexpectedContentRange'; ExpectedBytes=$null; Detail=('HTTP 200 unexpectedly included Content-Range: {0}' -f $ContentRange) }
        }
        return [pscustomobject][ordered]@{ Accept=$true; Classification='FullResponse200'; ExpectedBytes=if($ContentLength -ge 0){[long]$ContentLength}else{$null}; Detail='HTTP 200 full-response candidate.' }
    }

    if ($StatusCode -eq 206) {
        $match = [regex]::Match([string]$ContentRange, '^\s*bytes\s+(\d+)-(\d+)/(\d+|\*)\s*$', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
        if (-not $match.Success) {
            return [pscustomobject][ordered]@{ Accept=$false; Classification='PartialContentRejected'; ExpectedBytes=$null; Detail=('HTTP 206 without a parseable complete Content-Range: {0}' -f $ContentRange) }
        }
        $start = [long]$match.Groups[1].Value
        $end = [long]$match.Groups[2].Value
        $totalText = [string]$match.Groups[3].Value
        if ($totalText -eq '*') {
            return [pscustomobject][ordered]@{ Accept=$false; Classification='PartialContentRejected'; ExpectedBytes=$null; Detail=('HTTP 206 has an unknown total length: {0}' -f $ContentRange) }
        }
        $total = [long]$totalText
        $rangeLength = ($end - $start + 1)
        $isComplete = ($start -eq 0 -and $total -gt 0 -and $end -eq ($total - 1) -and ($ContentLength -lt 0 -or $ContentLength -eq $rangeLength))
        if (-not $isComplete) {
            return [pscustomobject][ordered]@{ Accept=$false; Classification='PartialContentRejected'; ExpectedBytes=$total; Detail=('Unsolicited partial content rejected: {0}; Content-Length={1}' -f $ContentRange,$ContentLength) }
        }
        return [pscustomobject][ordered]@{ Accept=$true; Classification='CompleteRange206'; ExpectedBytes=$total; Detail='HTTP 206 covers the complete object from byte zero through EOF.' }
    }

    return [pscustomobject][ordered]@{ Accept=$false; Classification='UnexpectedHttpStatus'; ExpectedBytes=$null; Detail=('Unexpected HTTP status for installer download: {0}' -f $StatusCode) }
}

function Get-AmdDownloadedPayloadDecision {
    [CmdletBinding()]
    param(
        [long]$ExpectedBytes = -1,
        [Parameter(Mandatory = $true)][long]$BytesWritten,
        [AllowNull()]$Validation
    )

    if ($BytesWritten -le 0) {
        return [pscustomobject][ordered]@{ Accept=$false; Classification='EmptyResponseBody'; Detail='Downloaded response body is empty.' }
    }
    if ($ExpectedBytes -ge 0 -and $BytesWritten -ne $ExpectedBytes) {
        return [pscustomobject][ordered]@{ Accept=$false; Classification='ByteCountMismatch'; Detail=('Downloaded byte count mismatch: expected={0}; actual={1}' -f $ExpectedBytes,$BytesWritten) }
    }
    if ($null -eq $Validation -or -not [bool]$Validation.Valid) {
        $validationError = if ($null -ne $Validation -and -not [string]::IsNullOrWhiteSpace([string]$Validation.Error)) { [string]$Validation.Error } else { 'installer payload validation did not establish a valid artifact' }
        return [pscustomobject][ordered]@{ Accept=$false; Classification='InstallerPayloadValidationFailed'; Detail=('Downloaded payload failed installer validation: {0}' -f $validationError) }
    }

    return [pscustomobject][ordered]@{ Accept=$true; Classification='PayloadAccepted'; Detail='Received byte count and installer payload validation are consistent.' }
}

function Test-AmdHttpDownloadTransportSelfTest {
    [CmdletBinding()]
    param()

    $full200 = Get-AmdHttpDownloadResponseDecision -StatusCode 200 -ContentRange $null -ContentLength 78301768 -ResponseUri 'https://drivers.amd.com/drivers/example.exe'
    $partial206 = Get-AmdHttpDownloadResponseDecision -StatusCode 206 -ContentRange 'bytes 24101867-78301767/78301768' -ContentLength 54199901 -ResponseUri 'https://drivers.amd.com/drivers/example.exe'
    $full206 = Get-AmdHttpDownloadResponseDecision -StatusCode 206 -ContentRange 'bytes 0-78301767/78301768' -ContentLength 78301768 -ResponseUri 'https://drivers.amd.com/drivers/example.exe'
    $bad200 = Get-AmdHttpDownloadResponseDecision -StatusCode 200 -ContentRange 'bytes 100-199/1000' -ContentLength 100 -ResponseUri 'https://drivers.amd.com/drivers/example.exe'
    $incomplete = Get-AmdHttpDownloadResponseDecision -StatusCode 200 -ContentRange $null -ContentLength 123 -ResponseUri 'https://www.amd.com/en/support/downloads/Download-Incomplete.html'

    $validPayload = [pscustomobject][ordered]@{ Valid=$true; Error=$null }
    $invalidPayload = [pscustomobject][ordered]@{ Valid=$false; Error='synthetic invalid payload' }
    $payloadAccepted = Get-AmdDownloadedPayloadDecision -ExpectedBytes 78301768 -BytesWritten 78301768 -Validation $validPayload
    $payloadTruncated = Get-AmdDownloadedPayloadDecision -ExpectedBytes 78301768 -BytesWritten 54199901 -Validation $validPayload
    $payloadEmpty = Get-AmdDownloadedPayloadDecision -ExpectedBytes 0 -BytesWritten 0 -Validation $validPayload
    $payloadInvalid = Get-AmdDownloadedPayloadDecision -ExpectedBytes 78301768 -BytesWritten 78301768 -Validation $invalidPayload

    $ok = (
        $full200.Accept -and $full200.Classification -eq 'FullResponse200' -and
        -not $partial206.Accept -and $partial206.Classification -eq 'PartialContentRejected' -and
        $full206.Accept -and $full206.Classification -eq 'CompleteRange206' -and
        -not $bad200.Accept -and $bad200.Classification -eq 'UnexpectedContentRange' -and
        -not $incomplete.Accept -and $incomplete.Classification -eq 'AmdDownloadIncompleteRedirect' -and
        $payloadAccepted.Accept -and $payloadAccepted.Classification -eq 'PayloadAccepted' -and
        -not $payloadTruncated.Accept -and $payloadTruncated.Classification -eq 'ByteCountMismatch' -and
        -not $payloadEmpty.Accept -and $payloadEmpty.Classification -eq 'EmptyResponseBody' -and
        -not $payloadInvalid.Accept -and $payloadInvalid.Classification -eq 'InstallerPayloadValidationFailed'
    )
    return [pscustomobject][ordered]@{
        Status=if($ok){'Pass'}else{'Fail'}
        Full200=$full200.Classification
        Partial206=$partial206.Classification
        Complete206=$full206.Classification
        UnexpectedRangeOn200=$bad200.Classification
        AmdIncompleteRedirect=$incomplete.Classification
        CompletePayload=$payloadAccepted.Classification
        TruncatedPayload=$payloadTruncated.Classification
        EmptyPayload=$payloadEmpty.Classification
        InvalidInstallerPayload=$payloadInvalid.Classification
    }
}

function Invoke-AmdDownloadSessionWarmup {
    [CmdletBinding()]
    param(
        [AllowNull()][string]$Uri,
        [Parameter(Mandatory = $true)][System.Net.CookieContainer]$CookieContainer,
        [int]$TimeoutSec = 90,
        [int]$MaximumRedirection = 10,
        [switch]$NoCache
    )

    if ([string]::IsNullOrWhiteSpace($Uri)) {
        return [pscustomobject][ordered]@{ Success=$false; Status='NotRequested'; StatusCode=$null; ResponseUri=$null; Error=$null }
    }

    $response = $null
    try {
        $request = New-AmdHttpRequest -Uri $Uri -TimeoutSec $TimeoutSec -MaximumRedirection $MaximumRedirection -CookieContainer $CookieContainer -NoCache:$NoCache
        $response = [System.Net.HttpWebResponse]$request.GetResponse()
        return [pscustomobject][ordered]@{
            Success=$true
            Status='Observed'
            StatusCode=[int]$response.StatusCode
            ResponseUri=if($response.ResponseUri){$response.ResponseUri.AbsoluteUri}else{$Uri}
            Error=$null
        }
    }
    catch {
        return [pscustomobject][ordered]@{
            Success=$false
            Status='Failed'
            StatusCode=$null
            ResponseUri=$null
            Error=(Get-AmdCompactErrorMessage -Message $_.Exception.Message -MaximumLength 300)
        }
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
        [int]$MaximumRedirection = 10,
        [System.Net.CookieContainer]$CookieContainer,
        [switch]$NoCache,
        [switch]$DisableKeepAlive
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
    if ($CookieContainer) {
        $request.CookieContainer = $CookieContainer
    }
    if ($NoCache) {
        $request.CachePolicy = New-Object System.Net.Cache.RequestCachePolicy([System.Net.Cache.RequestCacheLevel]::NoCacheNoStore)
        $request.Headers['Pragma'] = 'no-cache'
        $request.Headers['Cache-Control'] = 'no-cache'
    }
    if ($DisableKeepAlive) {
        $request.KeepAlive = $false
    }
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

    $resolved=(Resolve-Path -LiteralPath $Path -ErrorAction Stop).Path
    $utf8=New-Object Text.UTF8Encoding($false,$true)
    $raw=[IO.File]::ReadAllText($resolved,$utf8)
    return (ConvertFrom-CanonicalJson -Json $raw)
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

function Test-AmdPathWithinToolkitRoot {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][string]$Path,
        [Parameter(Mandatory=$true)][string]$ToolkitRoot
    )

    try {
        $root=[System.IO.Path]::GetFullPath($ToolkitRoot).TrimEnd('\','/')
        $candidate=[System.IO.Path]::GetFullPath($Path).TrimEnd('\','/')
        if($candidate.Equals($root,[System.StringComparison]::OrdinalIgnoreCase)){return $true}
        return $candidate.StartsWith(($root+[System.IO.Path]::DirectorySeparatorChar),[System.StringComparison]::OrdinalIgnoreCase)
    }
    catch{return $false}
}

function Get-AmdPathReparsePoints {
    [CmdletBinding()]
    param([Parameter(Mandatory=$true)][string]$Path)

    $items=New-Object 'System.Collections.Generic.List[string]'
    try{
        $current=Get-Item -LiteralPath $Path -Force -ErrorAction Stop
        while($null -ne $current){
            if(($current.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0){$items.Add([string]$current.FullName)|Out-Null}
            $parent=Split-Path -Parent ([string]$current.FullName)
            if([string]::IsNullOrWhiteSpace($parent)-or $parent -eq [string]$current.FullName){break}
            $current=Get-Item -LiteralPath $parent -Force -ErrorAction SilentlyContinue
        }
    }catch{}
    return @($items.ToArray())
}

function New-AmdExactLengthProbePath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][string]$Directory,
        [Parameter(Mandatory=$true)][int]$TargetLength,
        [string]$Extension='.tmp'
    )

    $prefix=(Join-Path $Directory 'p')
    $padding=$TargetLength-$prefix.Length-$Extension.Length
    if($padding -lt 0){return $null}
    return ($prefix+('x'*$padding)+$Extension)
}

function Invoke-AmdFilePathLengthProbe {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][string]$Directory,
        [Parameter(Mandatory=$true)][int]$TargetLength
    )

    $path=New-AmdExactLengthProbePath -Directory $Directory -TargetLength $TargetLength
    if(-not $path){return [pscustomobject][ordered]@{TargetLength=$TargetLength;ActualLength=$null;Status='NotRun';Error='Probe directory is already longer than the requested target length.'}}
    $status='Pass';$errorText=$null
    try{
        Write-AmdUtf8NoBom -Path $path -Text 'AMD research path-safety probe.'
        $read=Read-AmdTextFile -Path $path
        if($read -ne 'AMD research path-safety probe.'){throw 'Probe readback differed from the written content.'}
    }catch{$status='Fail';$errorText=$_.Exception.Message}
    finally{if(Test-Path -LiteralPath $path -PathType Leaf){Remove-Item -LiteralPath $path -Force -ErrorAction SilentlyContinue}}
    return [pscustomobject][ordered]@{TargetLength=$TargetLength;ActualLength=$path.Length;Status=$status;Error=$errorText}
}

function Invoke-AmdSevenZipPathProbe {
    [CmdletBinding()]
    param(
        [AllowNull()]$SevenZipInfo,
        [Parameter(Mandatory=$true)][string]$ProbeRoot
    )

    if($null -eq $SevenZipInfo -or [string]$SevenZipInfo.Status -ne 'Available'){
        return [pscustomobject][ordered]@{Status='NotRun';ArchivePathLength=$null;ExitCode=$null;Error='7-Zip is unavailable.'}
    }
    $source=Join-Path $ProbeRoot 'zsrc'
    $archivePath=New-AmdExactLengthProbePath -Directory $ProbeRoot -TargetLength 220 -Extension '.zip'
    if(-not $archivePath){return [pscustomobject][ordered]@{Status='Fail';ArchivePathLength=$null;ExitCode=$null;Error='Unable to construct the 220-character 7-Zip probe path.'}}
    try{
        New-AmdDirectory -Path $source|Out-Null
        Write-AmdUtf8NoBom -Path (Join-Path $source 'probe.txt') -Text 'AMD research 7-Zip path probe.'
        $null=New-AmdZipFromDirectory -SourceDirectory $source -DestinationZip $archivePath
        $result=Invoke-AmdReadOnlyProcess -FilePath ([string]$SevenZipInfo.Path) -Arguments @('t',$archivePath)
        return [pscustomobject][ordered]@{Status=if($result.ExitCode -eq 0){'Pass'}else{'Fail'};ArchivePathLength=$archivePath.Length;ExitCode=$result.ExitCode;Error=$result.Error;OutputSha256=$result.OutputSha256}
    }
    catch{return [pscustomobject][ordered]@{Status='Fail';ArchivePathLength=$archivePath.Length;ExitCode=$null;Error=$_.Exception.Message}}
    finally{
        if(Test-Path -LiteralPath $archivePath -PathType Leaf){Remove-Item -LiteralPath $archivePath -Force -ErrorAction SilentlyContinue}
        if(Test-Path -LiteralPath $source -PathType Container){Remove-Item -LiteralPath $source -Recurse -Force -ErrorAction SilentlyContinue}
    }
}

function Invoke-AmdSignToolShortPathProbe {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][string]$ProbeRoot,
        [switch]$Required
    )

    $platform=Get-AmdPlatformInfo
    if([string]$platform.PlatformFamily -ne 'Windows'){
        return [pscustomobject][ordered]@{Status='NotApplicable';Required=[bool]$Required;SourceSha256=$null;AliasSha256=$null;AliasPathLength=$null;ExitCode=$null;Error=$null}
    }
    $signTool=Get-AmdWindowsSdkToolInfo -ToolName 'signtool.exe'
    if([string]$signTool.Status -ne 'Available'){
        return [pscustomobject][ordered]@{Status=if($Required){'Fail'}else{'NotRun'};Required=[bool]$Required;ToolStatus=[string]$signTool.Status;SourceSha256=$null;AliasSha256=$null;AliasPathLength=$null;ExitCode=$null;Error='signtool.exe is unavailable.'}
    }
    $aliasRoot=Join-Path (Get-AmdResearchToolkitRoot) 'work\n'
    $aliasPath=Join-Path $aliasRoot 'p.exe'
    try{
        New-AmdDirectory -Path $aliasRoot|Out-Null
        Copy-Item -LiteralPath ([string]$signTool.Path) -Destination $aliasPath -Force
        $sourceSha=Get-AmdSha256 -Path ([string]$signTool.Path)
        $aliasSha=Get-AmdSha256 -Path $aliasPath
        if($sourceSha -ne $aliasSha){throw 'SignTool probe alias is not byte-identical to its source.'}
        $result=Invoke-AmdReadOnlyProcess -FilePath ([string]$signTool.Path) -Arguments @('verify','/pa',$aliasPath)
        return [pscustomobject][ordered]@{Status=if($result.ExitCode -eq 0){'Pass'}else{'Fail'};Required=[bool]$Required;ToolStatus=[string]$signTool.Status;SourceSha256=$sourceSha;AliasSha256=$aliasSha;AliasPathLength=$aliasPath.Length;ExitCode=$result.ExitCode;Error=$result.Error;OutputSha256=$result.OutputSha256}
    }
    catch{return [pscustomobject][ordered]@{Status='Fail';Required=[bool]$Required;ToolStatus=[string]$signTool.Status;SourceSha256=$null;AliasSha256=$null;AliasPathLength=$aliasPath.Length;ExitCode=$null;Error=$_.Exception.Message}}
    finally{if(Test-Path -LiteralPath $aliasPath -PathType Leaf){Remove-Item -LiteralPath $aliasPath -Force -ErrorAction SilentlyContinue}}
}

function Get-AmdPathSafetyAssessment {
    [CmdletBinding()]
    param(
        [string]$SevenZipPath,
        [string[]]$ResolvedStages=@()
    )

    $toolRoot=[System.IO.Path]::GetFullPath((Get-AmdResearchToolkitRoot)).TrimEnd('\','/')
    $platform=Get-AmdPlatformInfo
    $windowsPlatform=([string]$platform.PlatformFamily -eq 'Windows')
    $issues=New-Object 'System.Collections.Generic.List[string]'
    $diagnostics=New-Object 'System.Collections.Generic.List[string]'
    $requiresSevenZip=@($ResolvedStages|Where-Object{$_ -eq 'Extract'}).Count -gt 0
    $requiresSignTool=@($ResolvedStages|Where-Object{$_ -in @('Signature','SignatureNative')}).Count -gt 0 -and [bool]$script:AmdRequireWindowsClientSignatureQualification

    $isUnc=$toolRoot.StartsWith('\\')
    if($windowsPlatform -and $isUnc){$issues.Add('UNC tool roots are not supported for qualification.')|Out-Null}
    if($windowsPlatform -and $toolRoot.Length -gt $script:AmdWindowsSafeToolRootLimit){$issues.Add(('Tool root length {0} exceeds the policy limit {1}.' -f $toolRoot.Length,$script:AmdWindowsSafeToolRootLimit))|Out-Null}
    $reparse=@(Get-AmdPathReparsePoints -Path $toolRoot)
    if($windowsPlatform -and $reparse.Count -gt 0){$issues.Add('The tool root or one of its ancestors is a reparse point; junction/subst-style qualification paths are prohibited.')|Out-Null}

    foreach($configured in @(
        [pscustomobject]@{Name='EvidenceOutputRoot';Value=$script:EvidenceOutputRoot},
        [pscustomobject]@{Name='PublicOutputRoot';Value=$script:PublicOutputRoot}
    )){
        if(-not [string]::IsNullOrWhiteSpace([string]$configured.Value)-and -not(Test-AmdPathWithinToolkitRoot -Path ([string]$configured.Value) -ToolkitRoot $toolRoot)){
            $issues.Add(('{0} must be inside the research tool folder.' -f [string]$configured.Name))|Out-Null
        }
    }

    $longPathsEnabled=$null
    $substMapping=$null
    if($windowsPlatform){
        try{$longPathsEnabled=[int](Get-ItemProperty -LiteralPath 'HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem' -Name LongPathsEnabled -ErrorAction Stop).LongPathsEnabled}catch{$diagnostics.Add(('LongPathsEnabled could not be read: {0}' -f $_.Exception.Message))|Out-Null}
        try{
            $substPath=Get-AmdCommandPath -Name 'subst.exe'
            if($substPath){
                $substResult=Invoke-AmdReadOnlyProcess -FilePath $substPath -Arguments @()
                $driveQualifier=([System.IO.Path]::GetPathRoot($toolRoot)).TrimEnd('\')
                $substLine=@($substResult.Output|Where-Object{[string]$_ -match ('(?i)^'+[regex]::Escape($driveQualifier)+'\\:\s*=>')}|Select-Object -First 1)
                if($substLine.Count -gt 0){$substMapping=[string]$substLine[0];$issues.Add('SUBST-backed tool roots are not supported for qualification.')|Out-Null}
            }
        }catch{$issues.Add(('SUBST mapping diagnostic failed; path qualification is blocked fail-closed: {0}' -f $_.Exception.Message))|Out-Null}
    }

    $designedContainerRoot=Get-AmdShortExtractionPath -ArtifactOrdinal 1 -ContainerOrdinal 1 -ExtractionBasePath (Join-Path $toolRoot 'work\x')
    $predicted=[pscustomobject][ordered]@{
        AcquisitionPathLength=(Join-Path $toolRoot 'private\a\a000000000000.exe').Length
        ExtractionBasePathLength=$designedContainerRoot.Length
        VendorRelativePathReserve=$script:AmdVendorRelativePathReserve
        MaximumDesignedExtractionPathLength=($designedContainerRoot.Length+1+$script:AmdVendorRelativePathReserve)
        NativeAliasPathLength=(Join-Path $toolRoot 'work\n\f000001.sys').Length
        EvidenceRootPathLength=(Join-Path $toolRoot 'private\evidence').Length
    }
    if($windowsPlatform -and $predicted.MaximumDesignedExtractionPathLength -gt $script:AmdWindowsSafeFullPathLimit){$issues.Add(('Designed extraction path length {0} exceeds the safe full-path limit {1}.' -f $predicted.MaximumDesignedExtractionPathLength,$script:AmdWindowsSafeFullPathLimit))|Out-Null}

    $probeRoot=Join-Path $toolRoot 'work\p'
    $fileProbes=@()
    $sevenZipInfo=$null
    $sevenZipProbe=[pscustomobject][ordered]@{Status='NotApplicable';ArchivePathLength=$null;ExitCode=$null;Error=$null}
    $signToolProbe=[pscustomobject][ordered]@{Status='NotApplicable';Required=[bool]$requiresSignTool;AliasPathLength=$null;ExitCode=$null;Error=$null}
    if($windowsPlatform){
        try{
            New-AmdDirectory -Path $probeRoot|Out-Null
            $fileProbes=@(@(200,220,240)|ForEach-Object{Invoke-AmdFilePathLengthProbe -Directory $probeRoot -TargetLength $_})
            foreach($probe in $fileProbes){if([string]$probe.Status -ne 'Pass'){$issues.Add(('Windows file path probe failed at target length {0}: {1}' -f $probe.TargetLength,$probe.Error))|Out-Null}}
            try{$sevenZipInfo=Get-AmdSevenZipInfo -ExplicitPath $SevenZipPath}catch{$sevenZipInfo=[pscustomobject]@{Status='InvalidExplicitPath';Path=$null;Guidance=$_.Exception.Message}}
            $sevenZipProbe=Invoke-AmdSevenZipPathProbe -SevenZipInfo $sevenZipInfo -ProbeRoot $probeRoot
            if($requiresSevenZip -and [string]$sevenZipProbe.Status -ne 'Pass'){$issues.Add(('7-Zip path probe did not pass: {0}' -f [string]$sevenZipProbe.Error))|Out-Null}
            $signToolProbe=Invoke-AmdSignToolShortPathProbe -ProbeRoot $probeRoot -Required:$requiresSignTool
            if($requiresSignTool -and [string]$signToolProbe.Status -ne 'Pass'){$issues.Add(('SignTool short-path probe did not pass: {0}' -f [string]$signToolProbe.Error))|Out-Null}
        }
        finally{if(Test-Path -LiteralPath $probeRoot -PathType Container){Remove-Item -LiteralPath $probeRoot -Recurse -Force -ErrorAction SilentlyContinue}}
    }
    else{
        $fileProbes=@([pscustomobject][ordered]@{TargetLength=$null;ActualLength=$null;Status='NotApplicable';Error=$null})
    }

    $driveRoot=[System.IO.Path]::GetPathRoot($toolRoot)
    $recommendedRoot=if($windowsPlatform -and $driveRoot -and -not $isUnc){Join-Path $driveRoot $script:AmdResearchRecommendedRootName}else{'D:\{0}' -f $script:AmdResearchRecommendedRootName}
    $status=if($issues.Count -eq 0){'Pass'}else{'Blocked'}
    $assessment=[pscustomobject][ordered]@{
        SchemaVersion=$script:AmdResearchPathSafetySchemaVersion
        ToolkitVersion=$script:AmdResearchToolkitVersion
        GeneratedAtUtc=Get-AmdUtcTimestamp
        Status=$status
        Policy=[pscustomobject][ordered]@{SafeFullPathLimit=$script:AmdWindowsSafeFullPathLimit;MaximumToolRootLength=$script:AmdWindowsSafeToolRootLimit;VendorRelativePathReserve=$script:AmdVendorRelativePathReserve;LongPathsEnabledIsDiagnosticOnly=$true;QualificationBypassAllowed=$false;ExternalDataRootsAllowed=$false;UncQualificationAllowed=$false;ReparsePointQualificationAllowed=$false}
        PlatformFamily=[string]$platform.PlatformFamily
        ToolRoot=$toolRoot
        ToolRootLength=$toolRoot.Length
        IsUnc=[bool]$isUnc
        ReparsePoints=@($reparse)
        SubstMapping=$substMapping
        LongPathsEnabled=$longPathsEnabled
        PredictedPaths=$predicted
        FileSystemProbes=@($fileProbes)
        SevenZipProbe=$sevenZipProbe
        SignToolProbe=$signToolProbe
        RequiredByStages=[pscustomobject][ordered]@{SevenZip=[bool]$requiresSevenZip;SignTool=[bool]$requiresSignTool}
        Issues=@($issues.ToArray())
        Diagnostics=@($diagnostics.ToArray())
        RecommendedToolRoot=$recommendedRoot
        OperatorInstruction=if($status -eq 'Blocked'){('Move the entire research tool folder to {0}, then rerun. Do not move inventory, private, or work separately. No AMD network request was started by this blocked run.' -f $recommendedRoot)}else{$null}
    }
    $outputPath=Join-Path $toolRoot 'inventory\path-safety-assessment.json'
    Write-AmdJsonFile -Path $outputPath -Value $assessment -Depth 30
    $script:AmdPathSafetyAssessment=$assessment
    return $assessment
}

function Get-AmdShortExtractionPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][ValidateRange(1,9999)][int]$ArtifactOrdinal,
        [ValidateRange(0,9999)][int]$ContainerOrdinal=0,
        [string]$ExtractionBasePath
    )

    if([string]::IsNullOrWhiteSpace([string]$ExtractionBasePath)){
        $ExtractionBasePath=Join-Path (Get-AmdResearchToolkitRoot) 'work\x'
    }
    $artifactPath=Join-Path $ExtractionBasePath ('a{0:D4}' -f $ArtifactOrdinal)
    if($ContainerOrdinal -eq 0){return $artifactPath}
    return Join-Path $artifactPath ('c{0:D4}' -f $ContainerOrdinal)
}

function Assert-AmdExtractionCompleteSet {
    [CmdletBinding()]
    param(
        [AllowEmptyCollection()][object[]]$Items=@(),
        [string]$Context='Downstream analysis',
        [switch]$ReturnFailureAsResult
    )

    $records=@($Items)
    if($records.Count -eq 0){
        $message=('{0} requires at least one extraction record.' -f $Context)
        if($ReturnFailureAsResult){
            return [pscustomobject][ordered]@{Status='Blocked';Context=$Context;CompleteCount=0;IncompleteCount=0;ReasonCode='NoExtractionRecords';Message=$message}
        }
        throw $message
    }
    $incomplete=@($records|Where-Object{[string]$_.Status -ne 'ExtractionComplete'})
    if($incomplete.Count -gt 0){
        $detail=@($incomplete|ForEach-Object{
            $name=if($_.PSObject.Properties['ReleaseVersion']){[string]$_.ReleaseVersion}elseif($_.PSObject.Properties['FileName']){[string]$_.FileName}elseif($_.PSObject.Properties['ArtifactKey']){[string]$_.ArtifactKey}else{'<unknown>'}
            '{0}={1}' -f $name,[string]$_.Status
        })-join ', '
        $message=('{0} is blocked because {1} of {2} extraction record(s) are incomplete: {3}' -f $Context,$incomplete.Count,$records.Count,$detail)
        if($ReturnFailureAsResult){
            return [pscustomobject][ordered]@{Status='Blocked';Context=$Context;CompleteCount=($records.Count-$incomplete.Count);IncompleteCount=$incomplete.Count;ReasonCode='IncompleteExtractionRecords';Message=$message}
        }
        throw $message
    }
    return [pscustomobject][ordered]@{Status='Pass';Context=$Context;CompleteCount=$records.Count;IncompleteCount=0}
}

function Test-AmdPathSafetyLogic {
    [CmdletBinding()]
    param()

    $actualRoot=Get-AmdResearchToolkitRoot
    $within=Test-AmdPathWithinToolkitRoot -Path (Join-Path $actualRoot 'private\r') -ToolkitRoot $actualRoot
    $outside=Test-AmdPathWithinToolkitRoot -Path ([System.IO.Path]::GetPathRoot([System.IO.Path]::GetFullPath($actualRoot))) -ToolkitRoot $actualRoot
    $syntheticRoot=if([System.IO.Path]::DirectorySeparatorChar -eq '\'){'D:\AMD-Research\tool'}else{'/AMD-Research/tool'}
    $syntheticBase=Join-Path (Join-Path $syntheticRoot 'work') 'x'
    $artifactPath=Get-AmdShortExtractionPath -ArtifactOrdinal 1 -ExtractionBasePath $syntheticBase
    $containerPath=Get-AmdShortExtractionPath -ArtifactOrdinal 1 -ContainerOrdinal 1 -ExtractionBasePath $syntheticBase
    $predicted=($containerPath.Length+1+$script:AmdVendorRelativePathReserve)
    $completeGate=Assert-AmdExtractionCompleteSet -Items @([pscustomobject]@{ReleaseVersion='fixture';Status='ExtractionComplete'}) -Context 'Path-safety self-test'
    # Exercise the same fail-closed predicate without emitting an expected caught
    # terminating error into the Windows PowerShell 5.1 transcript.
    $incompleteGate=Assert-AmdExtractionCompleteSet -Items @([pscustomobject]@{ReleaseVersion='fixture';Status='ExtractedWithErrors'}) -Context 'Path-safety self-test' -ReturnFailureAsResult
    $incompleteBlocked=([string]$incompleteGate.Status -eq 'Blocked' -and [string]$incompleteGate.ReasonCode -eq 'IncompleteExtractionRecords' -and [int]$incompleteGate.IncompleteCount -eq 1)
    $expectedContainerSuffix=Join-Path 'a0001' 'c0001'
    $ok=($within -and -not $outside -and $artifactPath.EndsWith('a0001') -and $containerPath.EndsWith($expectedContainerSuffix) -and $predicted -le $script:AmdWindowsSafeFullPathLimit -and [string]$completeGate.Status -eq 'Pass' -and $incompleteBlocked)
    return [pscustomobject][ordered]@{Status=if($ok){'Pass'}else{'Fail'};InsideAccepted=[bool]$within;OutsideRejected=[bool](-not $outside);ArtifactPath=$artifactPath;ContainerPath=$containerPath;PredictedMaximum=$predicted;IncompleteExtractionBlocked=[bool]$incompleteBlocked}
}

function ConvertFrom-AmdSevenZipSltPathEntries {
    [CmdletBinding()]
    param([AllowEmptyCollection()][string[]]$Lines)

    $entries=New-Object 'System.Collections.Generic.List[string]'
    $insideEntries=$false
    foreach($line in @($Lines)){
        if($line -match '^-{5,}\s*$'){$insideEntries=$true;continue}
        if(-not $insideEntries){continue}
        if($line -match '^Path\s*=\s*(.*?)\s*$'){
            $value=[string]$Matches[1]
            if(-not [string]::IsNullOrWhiteSpace($value)){$entries.Add($value)|Out-Null}
        }
    }
    return @($entries.ToArray())
}

function Test-AmdArchivePathEntries {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][string]$OutputDirectory,
        [AllowEmptyCollection()][string[]]$Entries
    )

    $issues=New-Object 'System.Collections.Generic.List[string]'
    $maxLength=$OutputDirectory.Length
    $maxEntry=$null
    foreach($entry in @($Entries)){
        $normalized=([string]$entry).Replace('/',[System.IO.Path]::DirectorySeparatorChar).Replace('\',[System.IO.Path]::DirectorySeparatorChar)
        $segments=@($normalized -split '[\\/]')
        if([System.IO.Path]::IsPathRooted($normalized)-or $normalized -match '^[A-Za-z]:' -or @($segments|Where-Object{$_ -eq '..'}).Count -gt 0){
            $issues.Add(('Unsafe archive entry path: {0}' -f [string]$entry))|Out-Null
            continue
        }
        $length=$OutputDirectory.Length+1+$normalized.Length
        if($length -gt $maxLength){$maxLength=$length;$maxEntry=[string]$entry}
        if($length -gt $script:AmdWindowsSafeFullPathLimit){$issues.Add(('Predicted extracted path length {0} exceeds limit {1}: {2}' -f $length,$script:AmdWindowsSafeFullPathLimit,[string]$entry))|Out-Null}
    }
    return [pscustomobject][ordered]@{Status=if($issues.Count -eq 0){'Pass'}else{'Blocked'};EntryCount=@($Entries).Count;MaximumPredictedPathLength=$maxLength;MaximumPathEntry=$maxEntry;Issues=@($issues.ToArray())}
}

function Get-AmdArchiveExtractionPathAssessment {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][string]$SevenZipPath,
        [Parameter(Mandatory=$true)][string]$ArchivePath,
        [Parameter(Mandatory=$true)][string]$OutputDirectory
    )

    try{
        $result=Invoke-AmdReadOnlyProcess -FilePath $SevenZipPath -Arguments @('l','-slt',$ArchivePath)
        if($result.ExitCode -notin @(0,1)){
            return [pscustomobject][ordered]@{Status='Blocked';ArchivePath=$ArchivePath;OutputDirectory=$OutputDirectory;ListExitCode=$result.ExitCode;EntryCount=0;MaximumPredictedPathLength=$null;MaximumPathEntry=$null;Issues=@(('7-Zip listing failed before extraction; exit code={0}.' -f $result.ExitCode))}
        }
        $entries=@(ConvertFrom-AmdSevenZipSltPathEntries -Lines @($result.Output))
        $assessment=Test-AmdArchivePathEntries -OutputDirectory $OutputDirectory -Entries $entries
        return [pscustomobject][ordered]@{Status=[string]$assessment.Status;ArchivePath=$ArchivePath;OutputDirectory=$OutputDirectory;ListExitCode=$result.ExitCode;EntryCount=$assessment.EntryCount;MaximumPredictedPathLength=$assessment.MaximumPredictedPathLength;MaximumPathEntry=$assessment.MaximumPathEntry;Issues=@($assessment.Issues)}
    }
    catch{return [pscustomobject][ordered]@{Status='Blocked';ArchivePath=$ArchivePath;OutputDirectory=$OutputDirectory;ListExitCode=$null;EntryCount=0;MaximumPredictedPathLength=$null;MaximumPathEntry=$null;Issues=@($_.Exception.Message)}}
}

function Test-AmdArchivePathSafetyLogic {
    [CmdletBinding()]
    param()
    $lines=@('Path = fixture.zip','Type = zip','----------','Path = Packages/Drivers/Display/WT6A_INF/a.cat','Size = 1')
    $entries=@(ConvertFrom-AmdSevenZipSltPathEntries -Lines $lines)
    $pass=Test-AmdArchivePathEntries -OutputDirectory 'D:\AMD-Research\work\x\a0001\c0001' -Entries $entries
    $blocked=Test-AmdArchivePathEntries -OutputDirectory ('D:\'+('x'*220)) -Entries $entries
    $ok=($entries.Count -eq 1 -and [string]$pass.Status -eq 'Pass' -and [string]$blocked.Status -eq 'Blocked')
    return [pscustomobject][ordered]@{Status=if($ok){'Pass'}else{'Fail'};ParsedEntryCount=$entries.Count;SafeCase=[string]$pass.Status;OverLimitCase=[string]$blocked.Status}
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
    return (ConvertTo-CanonicalJson -InputObject $Value -Depth 2 -NoTrailingNewline)
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
    $map = New-Object 'System.Collections.Generic.Dictionary[string,object]' ([System.StringComparer]::Ordinal)
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
    if($Level -ne 0){throw 'The compatibility wrapper no longer supports recursive Level calls.'}
    return (ConvertTo-CanonicalJson -InputObject $Value -Depth $Depth -NoTrailingNewline)
}

function Test-AmdCanonicalJsonEnumSerializationSelfTest {
    [CmdletBinding()]
    param()

    $issues=New-Object 'System.Collections.Generic.List[string]'
    $json=$null
    try {
        $fixture=[pscustomobject][ordered]@{ConfigManagerErrorCode=[System.DayOfWeek]::Monday}
        $json=ConvertTo-CanonicalJson -InputObject $fixture -Depth 4 -NoTrailingNewline
        if($json -ne "{`n  `"ConfigManagerErrorCode`": `"Monday`"`n}"){
            $issues.Add(('Canonical JSON enum encoding mismatch: {0}' -f $json))|Out-Null
        }
        $parsed=ConvertFrom-CanonicalJson -Json $json
        if([string]$parsed.ConfigManagerErrorCode -ne 'Monday'){
            $issues.Add(('Canonical JSON enum round-trip mismatch: {0}' -f [string]$parsed.ConfigManagerErrorCode))|Out-Null
        }
    }
    catch {
        $issues.Add(('Canonical JSON enum round-trip failed: {0}' -f $_.Exception.Message))|Out-Null
    }
    return [pscustomobject][ordered]@{
        Status=if($issues.Count -eq 0){'Pass'}else{'Fail'}
        EncodedJson=$json
        Issues=@($issues.ToArray())
    }
}

function Assert-AmdJsonFileSyntax {
    [CmdletBinding()]
    param([Parameter(Mandatory=$true)][string]$Path)

    if(-not(Test-Path -LiteralPath $Path -PathType Leaf)){throw('JSON syntax validation target is missing: {0}' -f $Path)}
    try {
        # Windows PowerShell 5.1 Get-Content -Raw uses the active ANSI code page
        # for a UTF-8 no-BOM file. Japanese exception text can then be decoded as
        # mojibake and may introduce invalid JSON escape/quote sequences. Read the
        # repository encoding contract explicitly and reject malformed UTF-8.
        $resolvedPath=(Resolve-Path -LiteralPath $Path -ErrorAction Stop).Path
        $utf8=New-Object System.Text.UTF8Encoding($false,$true)
        $text=[System.IO.File]::ReadAllText($resolvedPath,$utf8)
        $null=ConvertFrom-CanonicalJson -Json $text
    }
    catch {
        throw('Generated JSON is not parseable: {0}: {1}' -f $Path,$_.Exception.Message)
    }
}

function Test-NpuUtf8JsonSyntaxSelfTest {
    [CmdletBinding()]
    param()

    $selfTestDirectory=Join-Path $script:RunRoot '_utf8-json-syntax-selftest'
    $selfTestPath=Join-Path $selfTestDirectory 'japanese-message.json'
    $expectedMessage='日本語のエラーメッセージを含む UTF-8 JSON'
    $actualMessage=$null
    $errorMessage=$null
    try {
        if(Test-Path -LiteralPath $selfTestDirectory){Remove-Item -LiteralPath $selfTestDirectory -Recurse -Force -ErrorAction Stop}
        New-AmdDirectory -Path $selfTestDirectory|Out-Null
        $fixture=[pscustomobject][ordered]@{Status='ExpectedFailure';Message=$expectedMessage}
        Write-AmdJsonFile -Path $selfTestPath -Value $fixture -Depth 4
        Assert-AmdJsonFileSyntax -Path $selfTestPath
        $roundTrip=Read-AmdJsonFile -Path $selfTestPath
        $actualMessage=[string]$roundTrip.Message
        if($actualMessage -ne $expectedMessage){throw('UTF-8 JSON message round-trip mismatch.')}
    }
    catch{$errorMessage=$_.Exception.Message}
    finally{
        if(Test-Path -LiteralPath $selfTestDirectory){Remove-Item -LiteralPath $selfTestDirectory -Recurse -Force -ErrorAction SilentlyContinue}
    }
    return [pscustomobject][ordered]@{
        Status=$(if($null -eq $errorMessage){'Pass'}else{'Fail'})
        MessageRoundTrip=$actualMessage
        Error=$errorMessage
    }
}

function Write-JsonFile {
    param([Parameter(Mandatory=$true)]$Value,[Parameter(Mandatory=$true)][string]$Path,[switch]$Compress)
    Save-CanonicalJsonFile -InputObject $Value -Path $Path -Depth 30
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
        [pscustomobject][ordered]@{FileName='current-three-tool-common-core-contract.json';SchemaVersion='amd-three-tool-common-core-contract/1.0';SchemaRelativePath='schemas/source-data/current-three-tool-common-core-contract.source.schema.json'}
        [pscustomobject][ordered]@{FileName='driver-compatibility-rules.json';SchemaVersion='1.1';SchemaRelativePath='schemas/source-data/driver-compatibility-rules.source.schema.json'}
        [pscustomobject][ordered]@{FileName='hardware-identities.json';SchemaVersion='1.1';SchemaRelativePath='schemas/source-data/hardware-identities.source.schema.json'}
        [pscustomobject][ordered]@{FileName='hardware-driver-selection.json';SchemaVersion='amd-npu-hardware-driver-selection/1.0';SchemaRelativePath='schemas/source-data/hardware-driver-selection.source.schema.json'}
        [pscustomobject][ordered]@{FileName='known-driver-binary-contracts.json';SchemaVersion='1.0';SchemaRelativePath='schemas/source-data/known-driver-binary-contracts.source.schema.json'}
        [pscustomobject][ordered]@{FileName='known-installer-contracts.json';SchemaVersion='1.0';SchemaRelativePath='schemas/source-data/known-installer-contracts.source.schema.json'}
        [pscustomobject][ordered]@{FileName='observed-runtime-evidence.json';SchemaVersion='1.0';SchemaRelativePath='schemas/source-data/observed-runtime-evidence.source.schema.json'}
        [pscustomobject][ordered]@{FileName='predecessor-extraction-core-contract.json';SchemaVersion='amd-npu-predecessor-extraction-core-contract/1.0';SchemaRelativePath='schemas/source-data/predecessor-extraction-core-contract.source.schema.json'}
        [pscustomobject][ordered]@{FileName='predecessor-shared-core-contract.json';SchemaVersion='amd-research-predecessor-shared-core-contract/1.0';SchemaRelativePath='schemas/source-data/predecessor-shared-core-contract.source.schema.json'}
        [pscustomobject][ordered]@{FileName='processor-catalog.json';SchemaVersion='1.3';SchemaRelativePath='schemas/source-data/processor-catalog.source.schema.json'}
        [pscustomobject][ordered]@{FileName='processor-driver-applicability.json';SchemaVersion='1.0';SchemaRelativePath='schemas/source-data/processor-driver-applicability.source.schema.json'}
        [pscustomobject][ordered]@{FileName='published-driver-artifacts.json';SchemaVersion='amd-npu-published-driver-artifacts/1.3';SchemaRelativePath='schemas/source-data/published-driver-artifacts.source.schema.json'}
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

function ConvertTo-NpuNormalizedHardwareId {
    [CmdletBinding()]
    param([AllowNull()][string]$HardwareId)

    if ([string]::IsNullOrWhiteSpace([string]$HardwareId)) { return $null }
    return ([string]$HardwareId).Trim().ToUpperInvariant()
}

function Test-NpuHardwareIdMatchesInfModel {
    [CmdletBinding()]
    param(
        [AllowNull()][string]$HardwareId,
        [AllowNull()][string]$InfHardwareIdPattern
    )

    $observed=ConvertTo-NpuNormalizedHardwareId -HardwareId $HardwareId
    $pattern=ConvertTo-NpuNormalizedHardwareId -HardwareId $InfHardwareIdPattern
    if ([string]::IsNullOrWhiteSpace([string]$observed) -or [string]::IsNullOrWhiteSpace([string]$pattern)) { return $false }
    if (-not $observed.StartsWith($pattern,[System.StringComparison]::OrdinalIgnoreCase)) { return $false }
    return ($observed.Length -eq $pattern.Length -or $observed[$pattern.Length] -eq '&')
}

function Test-NpuHardwareDriverSelectionData {
    [CmdletBinding()]
    param([Parameter(Mandatory=$true)]$SelectionDoc)

    $issues=New-Object 'System.Collections.Generic.List[string]'
    if ([string]$SelectionDoc.schemaVersion -ne 'amd-npu-hardware-driver-selection/1.0') { $issues.Add('Unexpected hardware-driver-selection schemaVersion.')|Out-Null }
    if ([string]$SelectionDoc.authority.selectionKey -ne 'WindowsPnpHardwareIdsMatchedAgainstReviewedInfModels') { $issues.Add('Hardware selection key must be Windows PnP HardwareIDs matched against reviewed INF models.')|Out-Null }
    foreach($propertyName in @('cpuSkuUsed','cpuIdUsed','cpuNpuCombinationUsed','npuMarketingNameUsed','firmwareDeviceRevisionRequired','linuxAieTopologyRequired')){
        if ([bool]$SelectionDoc.authority.$propertyName) { $issues.Add(('Hardware selection authority must keep {0}=false.' -f $propertyName))|Out-Null }
    }
    if ([string]$SelectionDoc.policy.preferredProductionTrack -ne '376') { $issues.Add('Preferred production track must be 376.')|Out-Null }
    if ([bool]$SelectionDoc.policy.automatic280SelectionEnabled -or [bool]$SelectionDoc.policy.automatic280FallbackEnabled) { $issues.Add('280 automatic selection and fallback must remain disabled.')|Out-Null }
    if ([string]$SelectionDoc.policy.unknownOrIncompleteInputDecision -ne 'ReviewRequired') { $issues.Add('Unknown or incomplete hardware input must resolve to ReviewRequired.')|Out-Null }
    if ([string]$SelectionDoc.policy.explicitEmptyCompletedEnumerationDecision -ne 'NoNpuDriverRequired') { $issues.Add('An explicitly completed empty NPU enumeration must resolve to NoNpuDriverRequired.')|Out-Null }
    $trackNames=@($SelectionDoc.tracks|ForEach-Object{[string]$_.track}|Sort-Object -Unique)
    if (($trackNames -join ',') -ne '280,376') { $issues.Add('Hardware selection contract must retain exactly the 280 and 376 research tracks.')|Out-Null }
    $automaticTracks=@($SelectionDoc.tracks|Where-Object{[bool]$_.automaticSelectionEnabled})
    if ($automaticTracks.Count -ne 1 -or [string]$automaticTracks[0].track -ne '376') { $issues.Add('376 must be the only automatic hardware-selection track.')|Out-Null }
    foreach($track in @($SelectionDoc.tracks)){
        if ([string]$track.artifactSha256 -notmatch '^[0-9a-f]{64}$') { $issues.Add(('Invalid artifact hash for track {0}.' -f [string]$track.track))|Out-Null }
        if ([string]$track.infSha256 -notmatch '^[0-9a-f]{64}$') { $issues.Add(('Invalid INF hash for track {0}.' -f [string]$track.track))|Out-Null }
        if ([int]$track.minimumWindowsBuild -lt 1) { $issues.Add(('Invalid minimum Windows build for track {0}.' -f [string]$track.track))|Out-Null }
        foreach($pattern in @($track.hardwareIdPatterns)){
            if ([string]$pattern -notmatch '^PCI\\VEN_[0-9A-F]{4}&DEV_[0-9A-F]{4}$') { $issues.Add(('Invalid reviewed INF HardwareID pattern for track {0}: {1}' -f [string]$track.track,[string]$pattern))|Out-Null }
        }
    }
    return @($issues.ToArray())
}

function Resolve-NpuHardwareDriverTrack {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]$SelectionDoc,
        [AllowEmptyCollection()][string[]]$HardwareIds=@(),
        [Parameter(Mandatory=$true)][ValidateRange(1,999999)][int]$WindowsBuild
    )

    $normalized=New-Object 'System.Collections.Generic.List[string]'
    foreach($value in @($HardwareIds)){
        $item=ConvertTo-NpuNormalizedHardwareId -HardwareId ([string]$value)
        if (-not [string]::IsNullOrWhiteSpace([string]$item) -and -not $normalized.Contains($item)) { $normalized.Add($item)|Out-Null }
    }
    if ($normalized.Count -eq 0) {
        return [pscustomobject][ordered]@{
            SchemaVersion='amd-npu-hardware-selection-result/1.0';Decision='NoNpuDriverRequired';SelectedTrack=$null;SelectedArtifact=$null
            WindowsBuild=$WindowsBuild;ObservedHardwareIds=@();MatchedInfHardwareIdPatterns=@();CpuIdentityUsed=$false;FirmwareDeviceRevisionUsed=$false
            InstallationAuthorized=$false;WindowsServerRuntimeProof=$false;Reason='The caller explicitly requested resolution after a completed NPU-device enumeration and supplied no NPU device instance.'
        }
    }

    $preferred=@($SelectionDoc.tracks|Where-Object{[string]$_.track -eq [string]$SelectionDoc.policy.preferredProductionTrack -and [bool]$_.automaticSelectionEnabled})
    if ($preferred.Count -ne 1) {
        return [pscustomobject][ordered]@{
            SchemaVersion='amd-npu-hardware-selection-result/1.0';Decision='ReviewRequired';SelectedTrack=$null;SelectedArtifact=$null
            WindowsBuild=$WindowsBuild;ObservedHardwareIds=@($normalized.ToArray());MatchedInfHardwareIdPatterns=@();CpuIdentityUsed=$false;FirmwareDeviceRevisionUsed=$false
            InstallationAuthorized=$false;WindowsServerRuntimeProof=$false;Reason='The reviewed hardware-selection contract does not expose exactly one automatic preferred-production track.'
        }
    }

    $matched=New-Object 'System.Collections.Generic.List[string]'
    foreach($hardwareId in @($normalized.ToArray())){
        foreach($pattern in @($preferred[0].hardwareIdPatterns)){
            if (Test-NpuHardwareIdMatchesInfModel -HardwareId $hardwareId -InfHardwareIdPattern ([string]$pattern)) {
                if (-not $matched.Contains([string]$pattern)) { $matched.Add([string]$pattern)|Out-Null }
            }
        }
    }
    if ($matched.Count -eq 0) {
        return [pscustomobject][ordered]@{
            SchemaVersion='amd-npu-hardware-selection-result/1.0';Decision='ReviewRequired';SelectedTrack=$null;SelectedArtifact=$null
            WindowsBuild=$WindowsBuild;ObservedHardwareIds=@($normalized.ToArray());MatchedInfHardwareIdPatterns=@();CpuIdentityUsed=$false;FirmwareDeviceRevisionUsed=$false
            InstallationAuthorized=$false;WindowsServerRuntimeProof=$false;Reason='The enumerated NPU device identity does not match a reviewed preferred-production-track INF model. CPU or marketing-name inference is prohibited.'
        }
    }
    if ($WindowsBuild -lt [int]$preferred[0].minimumWindowsBuild) {
        return [pscustomobject][ordered]@{
            SchemaVersion='amd-npu-hardware-selection-result/1.0';Decision='ReviewRequired';SelectedTrack=$null;SelectedArtifact=$null
            WindowsBuild=$WindowsBuild;ObservedHardwareIds=@($normalized.ToArray());MatchedInfHardwareIdPatterns=@($matched.ToArray());CpuIdentityUsed=$false;FirmwareDeviceRevisionUsed=$false
            InstallationAuthorized=$false;WindowsServerRuntimeProof=$false;Reason=('The PnP identity matches the reviewed 376 INF model, but Windows build {0} is below the reviewed INF build floor {1}.' -f $WindowsBuild,[int]$preferred[0].minimumWindowsBuild)
        }
    }
    return [pscustomobject][ordered]@{
        SchemaVersion='amd-npu-hardware-selection-result/1.0';Decision='376';SelectedTrack='376';SelectedArtifact=[string]$preferred[0].artifactFileName
        SelectedArtifactSha256=[string]$preferred[0].artifactSha256;SelectedInfSha256=[string]$preferred[0].infSha256;WindowsBuild=$WindowsBuild
        ObservedHardwareIds=@($normalized.ToArray());MatchedInfHardwareIdPatterns=@($matched.ToArray());CpuIdentityUsed=$false;FirmwareDeviceRevisionUsed=$false
        Automatic280FallbackEnabled=$false;InstallationAuthorized=$false;WindowsServerRuntimeProof=$false
        Reason='The complete Windows PnP identity set for one NPU device instance matches the reviewed 376 INF model and the target build satisfies its static selector. 376 is the preferred production track by project policy; this is not deployment authorization.'
    }
}

function Get-NpuLocalWindowsBuildEvidence {
    [CmdletBinding()]
    param()

    $platform=Get-AmdPlatformInfo
    if ([string]$platform.PlatformFamily -ne 'Windows') {
        return [pscustomobject][ordered]@{Status='NotApplicable';Build=0;Source='None';Error='Local Windows build discovery is available only on Windows.'}
    }
    $cimError=$null
    try {
        $os=Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction Stop|Select-Object -First 1
        $build=0
        if ($null -ne $os -and [int]::TryParse([string]$os.BuildNumber,[ref]$build) -and $build -gt 0) {
            return [pscustomobject][ordered]@{Status='Complete';Build=$build;Source='Win32_OperatingSystem.BuildNumber';Error=$null}
        }
    }
    catch {
        $cimError=Get-AmdCompactErrorMessage -Message $_.Exception.Message -MaximumLength 600
    }
    $fallback=[int][Environment]::OSVersion.Version.Build
    if ($fallback -gt 0) {
        return [pscustomobject][ordered]@{Status='Complete';Build=$fallback;Source='Environment.OSVersion.Version.Build';Error=$(if($cimError){$cimError}else{$null})}
    }
    return [pscustomobject][ordered]@{Status='Failed';Build=0;Source='None';Error=$(if($cimError){$cimError}else{'Windows build number could not be determined.'})}
}

function Get-NpuPnpPropertyValues {
    [CmdletBinding()]
    param(
        [AllowEmptyCollection()][object[]]$Properties=@(),
        [Parameter(Mandatory=$true)][string]$KeyName
    )

    $values=New-Object 'System.Collections.Generic.List[string]'
    foreach($property in @($Properties|Where-Object{[string]$_.KeyName -eq $KeyName})){
        foreach($value in @($property.Data)){
            if (-not [string]::IsNullOrWhiteSpace([string]$value) -and -not $values.Contains([string]$value)){$values.Add([string]$value)|Out-Null}
        }
    }
    return @($values.ToArray())
}

function Get-NpuLocalWindowsPnpEvidence {
    [CmdletBinding()]
    param([Parameter(Mandatory=$true)]$SelectionDoc)

    $platform=Get-AmdPlatformInfo
    if ([string]$platform.PlatformFamily -ne 'Windows') {
        return [pscustomobject][ordered]@{
            SchemaVersion='amd-npu-local-pnp-evidence/1.0';EnumerationStatus='NotApplicable';InputSource='LocalWindowsPnP'
            CandidateDevices=@();ScannedPnpEntityCount=0;ScannedAmdPciEntityCount=0;Error='Local Windows PnP enumeration is available only on Windows.'
        }
    }
    try {
        $entities=@(Get-CimInstance -ClassName Win32_PnPEntity -ErrorAction Stop)
    }
    catch {
        return [pscustomobject][ordered]@{
            SchemaVersion='amd-npu-local-pnp-evidence/1.0';EnumerationStatus='Failed';InputSource='LocalWindowsPnP'
            CandidateDevices=@();ScannedPnpEntityCount=0;ScannedAmdPciEntityCount=0;Error=(Get-AmdCompactErrorMessage -Message $_.Exception.Message -MaximumLength 800)
        }
    }

    $knownPatterns=@($SelectionDoc.tracks|ForEach-Object{@($_.hardwareIdPatterns)}|Sort-Object -Unique)
    $amdPci=@($entities|Where-Object{[string]$_.PNPDeviceID -match '(?i)^PCI\\VEN_1022&DEV_[0-9A-F]{4}'})
    $getPropertyCommand=Get-Command -Name Get-PnpDeviceProperty -ErrorAction SilentlyContinue
    $candidates=New-Object 'System.Collections.Generic.List[object]'
    foreach($entity in $amdPci){
        $instanceId=ConvertTo-NpuNormalizedHardwareId -HardwareId ([string]$entity.PNPDeviceID)
        $known=$false
        foreach($pattern in $knownPatterns){if(Test-NpuHardwareIdMatchesInfModel -HardwareId $instanceId -InfHardwareIdPattern ([string]$pattern)){$known=$true;break}}
        $signalText=('{0} {1} {2}' -f [string]$entity.Name,[string]$entity.Description,[string]$entity.Service)
        $npuSignal=($signalText -match '(?i)(\bNPU\b|NEURAL PROCESS|RYZEN AI|IPU|XDNA)')
        if (-not $known -and -not $npuSignal){continue}

        $properties=@();$propertyStatus='CommandUnavailable';$propertyError=$null
        if ($null -ne $getPropertyCommand){
            try{$properties=@(Get-PnpDeviceProperty -InstanceId ([string]$entity.PNPDeviceID) -ErrorAction Stop);$propertyStatus='Complete'}
            catch{$propertyStatus='Failed';$propertyError=Get-AmdCompactErrorMessage -Message $_.Exception.Message -MaximumLength 600}
        }
        $hardwareIds=@(Get-NpuPnpPropertyValues -Properties $properties -KeyName 'DEVPKEY_Device_HardwareIds')
        $compatibleIds=@(Get-NpuPnpPropertyValues -Properties $properties -KeyName 'DEVPKEY_Device_CompatibleIds')
        $identitySet=New-Object 'System.Collections.Generic.List[string]'
        foreach($value in @($instanceId)+@($hardwareIds)+@($compatibleIds)){
            $normalized=ConvertTo-NpuNormalizedHardwareId -HardwareId ([string]$value)
            if (-not [string]::IsNullOrWhiteSpace([string]$normalized) -and -not $identitySet.Contains($normalized)){$identitySet.Add($normalized)|Out-Null}
        }
        $candidates.Add([pscustomobject][ordered]@{
            InstanceId=$instanceId;Name=[string]$entity.Name;Description=[string]$entity.Description;Service=[string]$entity.Service
            Status=[string]$entity.Status;ConfigManagerErrorCode=[string]$entity.ConfigManagerErrorCode;KnownReviewedInfIdentity=$known
            CandidateReason=$(if($known){'ReviewedInfIdentityMatch'}else{'AmdPciNpuSemanticSignal'})
            HardwareIds=@($hardwareIds);CompatibleIds=@($compatibleIds);IdentitySet=@($identitySet.ToArray())
            PropertyCollectionStatus=$propertyStatus;PropertyCollectionError=$propertyError
        })|Out-Null
    }
    return [pscustomobject][ordered]@{
        SchemaVersion='amd-npu-local-pnp-evidence/1.0';EnumerationStatus='Complete';InputSource='LocalWindowsPnP'
        CandidateDevices=@($candidates.ToArray());ScannedPnpEntityCount=$entities.Count;ScannedAmdPciEntityCount=$amdPci.Count;Error=$null
    }
}

function Resolve-NpuEnumeratedHardwareSelection {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]$SelectionDoc,
        [Parameter(Mandatory=$true)]$PnpEvidence,
        [Parameter(Mandatory=$true)][ValidateRange(1,999999)][int]$WindowsBuild,
        [string]$WindowsBuildSource='Caller',
        [switch]$ManualOverride
    )

    $deviceResults=New-Object 'System.Collections.Generic.List[object]'
    if ([string]$PnpEvidence.EnumerationStatus -eq 'Complete'){
        foreach($device in @($PnpEvidence.CandidateDevices)){
            $resolution=Resolve-NpuHardwareDriverTrack -SelectionDoc $SelectionDoc -HardwareIds @($device.IdentitySet) -WindowsBuild $WindowsBuild
            $deviceResults.Add([pscustomobject][ordered]@{
                InstanceId=[string]$device.InstanceId;Name=[string]$device.Name;Service=[string]$device.Service
                CandidateReason=[string]$device.CandidateReason;HardwareIds=@($device.HardwareIds);CompatibleIds=@($device.CompatibleIds)
                IdentitySet=@($device.IdentitySet);PropertyCollectionStatus=[string]$device.PropertyCollectionStatus;Resolution=$resolution
            })|Out-Null
        }
    }
    $decision='ReviewRequired';$reason='Local PnP enumeration did not complete; the tool cannot prove that no NPU is present.'
    if ([string]$PnpEvidence.EnumerationStatus -eq 'Complete'){
        if ($deviceResults.Count -eq 0){$decision='NoNpuDriverRequired';$reason='Completed local Windows PnP enumeration found no reviewed or NPU-signaled AMD PCI device instance.'}
        elseif (@($deviceResults|Where-Object{[string]$_.Resolution.Decision -eq 'ReviewRequired'}).Count -gt 0){$decision='ReviewRequired';$reason='At least one enumerated NPU candidate cannot be resolved from the reviewed INF identity set.'}
        elseif (@($deviceResults|Where-Object{[string]$_.Resolution.Decision -eq '376'}).Count -eq $deviceResults.Count){$decision='376';$reason='Every enumerated NPU candidate independently matches the reviewed preferred 376 INF identity and Windows build floor.'}
    }
    return [pscustomobject][ordered]@{
        SchemaVersion='amd-npu-local-hardware-selection/1.0';Decision=$decision;SelectedTrack=$(if($decision -eq '376'){'376'}else{$null})
        WindowsBuild=$WindowsBuild;WindowsBuildSource=$WindowsBuildSource;InputSource=[string]$PnpEvidence.InputSource;LocalEnumerationPerformed=(-not [bool]$ManualOverride)
        ManualOverrideUsed=[bool]$ManualOverride;EnumerationStatus=[string]$PnpEvidence.EnumerationStatus
        ScannedPnpEntityCount=[int]$PnpEvidence.ScannedPnpEntityCount;ScannedAmdPciEntityCount=[int]$PnpEvidence.ScannedAmdPciEntityCount
        CandidateDeviceCount=$deviceResults.Count;Devices=@($deviceResults.ToArray());CpuIdentityUsed=$false;FirmwareDeviceRevisionUsed=$false
        Automatic280FallbackEnabled=$false;InstallationAuthorized=$false;WindowsServerRuntimeProof=$false;Reason=$reason;EnumerationError=$PnpEvidence.Error
    }
}

function Test-NpuLocalHardwareSelectionLogic {
    [CmdletBinding()]
    param([Parameter(Mandatory=$true)]$SelectionDoc)

    $issues=New-Object 'System.Collections.Generic.List[string]'
    $empty=[pscustomobject]@{EnumerationStatus='Complete';InputSource='Fixture';CandidateDevices=@();ScannedPnpEntityCount=10;ScannedAmdPciEntityCount=2;Error=$null}
    $known=[pscustomobject]@{EnumerationStatus='Complete';InputSource='Fixture';ScannedPnpEntityCount=10;ScannedAmdPciEntityCount=3;Error=$null;CandidateDevices=@([pscustomobject]@{InstanceId='PCI\VEN_1022&DEV_17F0&SUBSYS_20CF1043&REV_10\FIXTURE';Name='AMD NPU';Service='IpuMcdmDriver';CandidateReason='ReviewedInfIdentityMatch';HardwareIds=@('PCI\VEN_1022&DEV_17F0&SUBSYS_20CF1043&REV_10');CompatibleIds=@();IdentitySet=@('PCI\VEN_1022&DEV_17F0&SUBSYS_20CF1043&REV_10');PropertyCollectionStatus='Complete'})}
    $unknown=[pscustomobject]@{EnumerationStatus='Complete';InputSource='Fixture';ScannedPnpEntityCount=10;ScannedAmdPciEntityCount=3;Error=$null;CandidateDevices=@([pscustomobject]@{InstanceId='PCI\VEN_1022&DEV_FFFF&SUBSYS_00000000\FIXTURE';Name='AMD NPU';Service='IpuMcdmDriver';CandidateReason='AmdPciNpuSemanticSignal';HardwareIds=@('PCI\VEN_1022&DEV_FFFF&SUBSYS_00000000');CompatibleIds=@();IdentitySet=@('PCI\VEN_1022&DEV_FFFF&SUBSYS_00000000');PropertyCollectionStatus='Complete'})}
    $failed=[pscustomobject]@{EnumerationStatus='Failed';InputSource='Fixture';CandidateDevices=@();ScannedPnpEntityCount=0;ScannedAmdPciEntityCount=0;Error='Fixture failure'}
    $multiple=[pscustomobject]@{EnumerationStatus='Complete';InputSource='Fixture';ScannedPnpEntityCount=10;ScannedAmdPciEntityCount=4;Error=$null;CandidateDevices=@($known.CandidateDevices[0],[pscustomobject]@{InstanceId='PCI\VEN_1022&DEV_1502&REV_00\FIXTURE';Name='AMD NPU';Service='IpuMcdmDriver';CandidateReason='ReviewedInfIdentityMatch';HardwareIds=@('PCI\VEN_1022&DEV_1502&REV_00');CompatibleIds=@();IdentitySet=@('PCI\VEN_1022&DEV_1502&REV_00');PropertyCollectionStatus='Complete'})}
    $cases=@(
        [pscustomobject]@{Name='CompletedNoNpu';Evidence=$empty;Expected='NoNpuDriverRequired';ExpectedCount=0},
        [pscustomobject]@{Name='KnownOne';Evidence=$known;Expected='376';ExpectedCount=1},
        [pscustomobject]@{Name='UnknownSignaled';Evidence=$unknown;Expected='ReviewRequired';ExpectedCount=1},
        [pscustomobject]@{Name='EnumerationFailed';Evidence=$failed;Expected='ReviewRequired';ExpectedCount=0},
        [pscustomobject]@{Name='KnownMultipleIndependent';Evidence=$multiple;Expected='376';ExpectedCount=2}
    )
    foreach($case in $cases){
        $result=Resolve-NpuEnumeratedHardwareSelection -SelectionDoc $SelectionDoc -PnpEvidence $case.Evidence -WindowsBuild 26100
        if ([string]$result.Decision -ne [string]$case.Expected -or [int]$result.CandidateDeviceCount -ne [int]$case.ExpectedCount){$issues.Add(('Local hardware-selection self-test failed: {0}; expected={1}/{2}; actual={3}/{4}' -f $case.Name,$case.Expected,$case.ExpectedCount,$result.Decision,$result.CandidateDeviceCount))|Out-Null}
        if ([bool]$result.CpuIdentityUsed -or [bool]$result.FirmwareDeviceRevisionUsed -or [bool]$result.Automatic280FallbackEnabled -or [bool]$result.InstallationAuthorized){$issues.Add(('Local hardware-selection self-test crossed an authority boundary: {0}' -f $case.Name))|Out-Null}
        if (@($result.Devices|Where-Object{[string]$_.Resolution.Decision -eq '280'}).Count -gt 0){$issues.Add(('Local hardware-selection self-test selected 280: {0}' -f $case.Name))|Out-Null}
    }
    return @($issues.ToArray())
}

function Test-NpuHardwareDriverSelectionLogic {
    [CmdletBinding()]
    param([Parameter(Mandatory=$true)]$SelectionDoc)

    $issues=New-Object 'System.Collections.Generic.List[string]'
    $cases=@(
        [pscustomobject]@{Name='PhoenixBroadId';Ids=@('PCI\VEN_1022&DEV_1502');Build=26100;Expected='376'},
        [pscustomobject]@{Name='FullStrixId';Ids=@('PCI\VEN_1022&DEV_17F0&SUBSYS_20CF1043&REV_10');Build=26100;Expected='376'},
        [pscustomobject]@{Name='UnknownNpuId';Ids=@('PCI\VEN_1022&DEV_FFFF&SUBSYS_00000000');Build=26100;Expected='ReviewRequired'},
        [pscustomobject]@{Name='CompletedEmptyEnumeration';Ids=@();Build=26100;Expected='NoNpuDriverRequired'},
        [pscustomobject]@{Name='BelowInfBuildFloor';Ids=@('PCI\VEN_1022&DEV_17F0');Build=20348;Expected='ReviewRequired'}
    )
    foreach($case in $cases){
        $result=Resolve-NpuHardwareDriverTrack -SelectionDoc $SelectionDoc -HardwareIds @($case.Ids) -WindowsBuild ([int]$case.Build)
        if ([string]$result.Decision -ne [string]$case.Expected) { $issues.Add(('Hardware selection self-test failed: {0}; expected={1}; actual={2}' -f [string]$case.Name,[string]$case.Expected,[string]$result.Decision))|Out-Null }
        if ([bool]$result.CpuIdentityUsed -or [bool]$result.FirmwareDeviceRevisionUsed -or [bool]$result.InstallationAuthorized) { $issues.Add(('Hardware selection self-test crossed a prohibited authority boundary: {0}' -f [string]$case.Name))|Out-Null }
    }
    $selectionResults=@($cases|ForEach-Object{Resolve-NpuHardwareDriverTrack -SelectionDoc $SelectionDoc -HardwareIds @($_.Ids) -WindowsBuild ([int]$_.Build)})
    if (@($selectionResults|Where-Object{[string]$_.Decision -eq '280'}).Count -ne 0) { $issues.Add('Hardware selection self-test must never select 280 automatically.')|Out-Null }
    return @($issues.ToArray())
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
        if (@('HistoricalRegressionFixture','CurrentNpuTypeCandidate') -notcontains [string]$rule.packageRole) { $issues.Add("Invalid NPU packageRole: $($rule.artifactFileName) -> $($rule.packageRole)") | Out-Null }
        if ([string]::IsNullOrWhiteSpace([string]$rule.selectionLaneId)) { $issues.Add("NPU artifact rule missing selectionLaneId: $($rule.artifactFileName)") | Out-Null }
        if (@('HistoricalOnly','ReviewRequired','Resolved') -notcontains [string]$rule.selectionBoundaryStatus) { $issues.Add("Invalid NPU selectionBoundaryStatus: $($rule.artifactFileName) -> $($rule.selectionBoundaryStatus)") | Out-Null }
        foreach ($identityId in @($rule.reviewedStaticNpuIdentityIds) + @($rule.recommendationEligibleNpuIdentityIds)) {
            if (-not $identityIds.ContainsKey([string]$identityId)) { $issues.Add("NPU artifact rule references unknown identity: $($rule.artifactFileName) -> $identityId") | Out-Null }
        }
        if ([string]$rule.selectionBoundaryStatus -ne 'Resolved' -and @($rule.recommendationEligibleNpuIdentityIds).Count -gt 0) { $issues.Add("Unresolved NPU package boundary must not expose recommendation-eligible identities: $($rule.artifactFileName)") | Out-Null }
    }
    if (-not [bool]$CompatibilityDoc.packageSelectionModel.globalVersionRankingProhibited) { $issues.Add('NPU package-selection model must prohibit global version ranking.') | Out-Null }
    if ([int]$CompatibilityDoc.packageSelectionModel.currentPackageCaseCount -ne 2) { $issues.Add('NPU package-selection model must retain exactly two current device-type cases at this checkpoint.') | Out-Null }
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
    if ([bool]$ApplicabilityDoc.recommendationPolicy.highestReviewedPublishedStaticCandidate) { $issues.Add('Applicability policy must not rank all NPU packages as one global latest stream.') | Out-Null }
    if (-not [bool]$ApplicabilityDoc.recommendationPolicy.resolvedNpuTypePackageLaneRequired) { $issues.Add('Applicability policy must require a resolved NPU-type package lane.') | Out-Null }
    if (-not [bool]$ApplicabilityDoc.recommendationPolicy.globalVersionRankingProhibited) { $issues.Add('Applicability policy must prohibit global NPU package version ranking.') | Out-Null }
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

function Get-NpuPublicSchemaVersionConst {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateSet('driver-compatibility-matrix.schema.json','processor-catalog.schema.json','processor-driver-applicability.schema.json')]
        [string]$SchemaFileName
    )

    $schemaPath = Join-Path (Join-Path (Get-AmdResearchToolkitRoot) 'schemas') $SchemaFileName
    if (-not (Test-Path -LiteralPath $schemaPath -PathType Leaf)) {
        throw ('Required NPU public schema is missing: {0}' -f $SchemaFileName)
    }
    $schema = Read-AmdJsonFile -Path $schemaPath
    $schemaVersion = [string]$schema.properties.SchemaVersion.const
    if ([string]::IsNullOrWhiteSpace($schemaVersion)) {
        throw ('Required NPU public schema has no properties.SchemaVersion.const: {0}' -f $SchemaFileName)
    }
    return $schemaVersion
}

function Test-NpuPublicSchemaVersionContracts {
    [CmdletBinding()]
    param()

    $contracts = @(
        [pscustomobject]@{FileName='driver-compatibility-matrix.schema.json';Expected='1.3'},
        [pscustomobject]@{FileName='processor-catalog.schema.json';Expected='1.3'},
        [pscustomobject]@{FileName='processor-driver-applicability.schema.json';Expected='1.1'}
    )
    $issues = New-Object 'System.Collections.Generic.List[string]'
    foreach ($contract in $contracts) {
        try {
            $actual = Get-NpuPublicSchemaVersionConst -SchemaFileName $contract.FileName
            if ([string]$actual -ne [string]$contract.Expected) {
                $issues.Add(('NPU public schema version contract mismatch: {0}; expected={1}; actual={2}' -f $contract.FileName,$contract.Expected,$actual)) | Out-Null
            }
        }
        catch {
            $issues.Add(('NPU public schema version contract unavailable: {0}: {1}' -f $contract.FileName,$_.Exception.Message)) | Out-Null
        }
    }
    try {
        $matrixSchema = Read-AmdJsonFile -Path (Join-Path (Join-Path (Get-AmdResearchToolkitRoot) 'schemas') 'driver-compatibility-matrix.schema.json')
        $selectionAuthority = Read-AmdJsonFile -Path (Join-Path (Join-Path (Get-AmdResearchToolkitRoot) 'data') 'hardware-driver-selection.json')
        $schemaSelectionKey = [string]$matrixSchema.properties.Scope.properties.PackageSelectionKey.const
        $authoritySelectionKey = [string]$selectionAuthority.authority.selectionKey
        if ([string]::IsNullOrWhiteSpace($schemaSelectionKey)) {
            $issues.Add('NPU driver compatibility matrix schema has no Scope.PackageSelectionKey const.') | Out-Null
        }
        elseif ($schemaSelectionKey -ne $authoritySelectionKey) {
            $issues.Add(('NPU public schema selection authority mismatch: schema={0}; authority={1}' -f $schemaSelectionKey,$authoritySelectionKey)) | Out-Null
        }
    }
    catch {
        $issues.Add(('NPU public schema selection authority contract unavailable: {0}' -f $_.Exception.Message)) | Out-Null
    }
    return [pscustomobject][ordered]@{
        Status=if($issues.Count -eq 0){'Pass'}else{'Fail'}
        SchemaCount=$contracts.Count
        Issues=@($issues.ToArray())
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
        SchemaVersion=(Get-NpuPublicSchemaVersionConst -SchemaFileName 'processor-catalog.schema.json');ToolVersion=$script:ToolVersion;HandEdited=$false
        ReviewedAt=[string]$ProcessorDoc.reviewedAt
        CatalogCompleteness=[string]$ProcessorDoc.catalogCompleteness
        UnknownSkuPolicy=[string]$ProcessorDoc.unknownSkuPolicy
        Normalization=[string]$ProcessorDoc.normalization
        Sources=@($ProcessorDoc.sources)
        Processors=@($ProcessorDoc.processors)
        CanonicalNameSelfTests=$selfTests.ToArray()
    }
}

function Select-NpuPackageCandidateWithinResolvedLane {
    param([Parameter(Mandatory=$true)]$CandidateRows)

    $resolvedRows = @($CandidateRows | Where-Object {
        [string]$_.PackageRole -eq 'CurrentNpuTypeCandidate' -and
        [string]$_.SelectionBoundaryStatus -eq 'Resolved' -and
        [string]$_.NpuIdentityApplicability -eq 'RecommendationEligible'
    })
    $resolvedLaneIds = @($resolvedRows | ForEach-Object { [string]$_.SelectionLaneId } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Sort-Object -Unique)
    if ($resolvedLaneIds.Count -gt 1) {
        return [pscustomobject][ordered]@{Status='ReviewRequired';SelectedRow=$null;Reason='More than one resolved NPU-type package lane is applicable. Cross-lane version comparison is prohibited.'}
    }
    if ($resolvedLaneIds.Count -eq 0) {
        $reason = if (@($CandidateRows).Count -gt 0) {
            'Static package candidates exist, but no current package case has a reviewed NPU-identity boundary. Global latest selection is prohibited.'
        }
        else {
            'No package satisfies the static compatibility gates.'
        }
        return [pscustomobject][ordered]@{Status='ReviewRequired';SelectedRow=$null;Reason=$reason}
    }

    $versioned = @($resolvedRows | Where-Object { $_.PublishedDriverLabel })
    if ($versioned.Count -eq 0) {
        return [pscustomobject][ordered]@{Status='ReviewRequired';SelectedRow=$null;Reason='The resolved NPU-type package lane has no parseable published driver candidate.'}
    }
    $maxVersion = $null
    foreach ($row in $versioned) {
        try { $parsedVersion = [version][string]$row.PublishedDriverLabel } catch { $parsedVersion = [version]'0.0' }
        if ($null -eq $maxVersion -or $parsedVersion -gt $maxVersion) { $maxVersion = $parsedVersion }
    }
    $topVersionRows = @($versioned | Where-Object {
        try { ([version][string]$_.PublishedDriverLabel) -eq $maxVersion } catch { ([version]'0.0') -eq $maxVersion }
    })
    $selected = @(Get-AmdOrdinalSortedObjectsByStringProperty -Values $topVersionRows -PropertyName 'ArtifactFileName' | Select-Object -First 1)
    if ($selected.Count -ne 1) {
        return [pscustomobject][ordered]@{Status='ReviewRequired';SelectedRow=$null;Reason='The resolved NPU-type package lane did not produce one deterministic candidate.'}
    }
    return [pscustomobject][ordered]@{Status='Selected';SelectedRow=$selected[0];Reason='Latest reviewed artifact inside one resolved NPU-type package lane.'}
}

function Test-NpuPackageLaneSelectionLogic {
    $issues = New-Object System.Collections.Generic.List[string]
    $make = {
        param($name,$version,$lane,$boundary,$role,$applicability)
        [pscustomobject]([ordered]@{ArtifactFileName=$name;PublishedDriverLabel=$version;SelectionLaneId=$lane;SelectionBoundaryStatus=$boundary;PackageRole=$role;NpuIdentityApplicability=$applicability})
    }

    $unresolved = Select-NpuPackageCandidateWithinResolvedLane -CandidateRows @(
        (& $make 'npu-280.exe' '32.0.203.280' 'current-280' 'ReviewRequired' 'CurrentNpuTypeCandidate' 'StaticCandidateBoundaryUnresolved'),
        (& $make 'npu-376.exe' '32.0.203.376' 'current-376' 'ReviewRequired' 'CurrentNpuTypeCandidate' 'StaticCandidateBoundaryUnresolved')
    )
    if ($unresolved.Status -ne 'ReviewRequired' -or $null -ne $unresolved.SelectedRow) { $issues.Add('Unresolved two-package NPU cases must fail closed.') | Out-Null }

    $sameLane = Select-NpuPackageCandidateWithinResolvedLane -CandidateRows @(
        (& $make 'npu-280.exe' '32.0.203.280' 'npu-type-a' 'Resolved' 'CurrentNpuTypeCandidate' 'RecommendationEligible'),
        (& $make 'npu-376.exe' '32.0.203.376' 'npu-type-a' 'Resolved' 'CurrentNpuTypeCandidate' 'RecommendationEligible')
    )
    if ($sameLane.Status -ne 'Selected' -or [string]$sameLane.SelectedRow.ArtifactFileName -ne 'npu-376.exe') { $issues.Add('Version ranking must select latest only inside one resolved NPU-type lane.') | Out-Null }

    $crossLane = Select-NpuPackageCandidateWithinResolvedLane -CandidateRows @(
        (& $make 'npu-280.exe' '32.0.203.280' 'npu-type-a' 'Resolved' 'CurrentNpuTypeCandidate' 'RecommendationEligible'),
        (& $make 'npu-376.exe' '32.0.203.376' 'npu-type-b' 'Resolved' 'CurrentNpuTypeCandidate' 'RecommendationEligible')
    )
    if ($crossLane.Status -ne 'ReviewRequired' -or $null -ne $crossLane.SelectedRow) { $issues.Add('Cross-lane NPU version comparison must be prohibited.') | Out-Null }

    $historical = Select-NpuPackageCandidateWithinResolvedLane -CandidateRows @(
        (& $make 'historical-280.zip' '32.0.203.280' 'historical' 'HistoricalOnly' 'HistoricalRegressionFixture' 'NotRecommendationEligible')
    )
    if ($historical.Status -ne 'ReviewRequired' -or $null -ne $historical.SelectedRow) { $issues.Add('Historical NPU fixtures must never become recommendations.') | Out-Null }
    return $issues.ToArray()
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
            $artifactRule = @($CompatibilityDoc.artifactRules | Where-Object { [string]$_.artifactSha256 -eq [string]$analysis.Artifact.Sha256 } | Select-Object -First 1)
            $packageRole = 'UnreviewedArtifact'
            $selectionLaneId = $null
            $selectionBoundaryStatus = 'NoReviewedRule'
            $npuIdentityApplicability = 'NoReviewedRule'
            if ($artifactRule.Count -eq 1) {
                $packageRole = [string]$artifactRule[0].packageRole
                $selectionLaneId = [string]$artifactRule[0].selectionLaneId
                $selectionBoundaryStatus = [string]$artifactRule[0].selectionBoundaryStatus
                if (@($artifactRule[0].recommendationEligibleNpuIdentityIds) -contains [string]$processor.npuIdentityId) {
                    $npuIdentityApplicability = 'RecommendationEligible'
                }
                elseif (@($artifactRule[0].reviewedStaticNpuIdentityIds) -contains [string]$processor.npuIdentityId) {
                    $npuIdentityApplicability = if ($selectionBoundaryStatus -eq 'Resolved') { 'NotRecommendationEligible' } else { 'StaticCandidateBoundaryUnresolved' }
                }
                else {
                    $npuIdentityApplicability = 'NotInReviewedStaticIdentitySet'
                }
            }
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
                PackageRole=$packageRole;SelectionLaneId=$selectionLaneId;SelectionBoundaryStatus=$selectionBoundaryStatus;NpuIdentityApplicability=$npuIdentityApplicability;
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
            $selections.Add([ordered]@{ProcessorId=[string]$processor.processorId;ProcessorName=[string]$processor.canonicalName;Codename=[string]$processor.codename;NpuAvailability=$npuAvailability;Decision='NoNpuDriverRequired';SelectionLaneId=$null;RecommendedArtifact=$null;PublishedDriverLabel=$null;ObservedClientRuntimeEvidenceStatus='NoObservedClientRuntimeEvidence';ObservedClientRuntimeEvidenceIds=@();Reason='Reviewed AMD product evidence does not expose an NPU capability for this exact SKU.'}) | Out-Null
            continue
        }
        $candidateRows = @($rows | Where-Object {$_.ProcessorId -eq $processor.processorId -and $_.Decision -eq 'StaticCandidateWithPublishedFamilyEvidence'})
        $laneSelection = Select-NpuPackageCandidateWithinResolvedLane -CandidateRows $candidateRows
        if ($laneSelection.Status -eq 'Selected' -and $null -ne $laneSelection.SelectedRow) {
            $selected = $laneSelection.SelectedRow
            $selectedObservedStatus=[string]$selected.ObservedClientRuntimeEvidenceStatus
            $selectedReason=if($selectedObservedStatus -eq 'ExactArtifactRuntimeObserved'){'Latest reviewed artifact inside the single resolved NPU-type package lane. The exact artifact is also observed working on the reviewed client SKU, but Windows Server runtime validation is still required.'}else{'Latest reviewed artifact inside the single resolved NPU-type package lane. Windows Server runtime validation is still required.'}
            $selections.Add([ordered]@{ProcessorId=[string]$processor.processorId;ProcessorName=[string]$processor.canonicalName;Codename=[string]$processor.codename;NpuAvailability=$npuAvailability;Decision='SelectLatestWithinResolvedNpuTypeLane';SelectionLaneId=[string]$selected.SelectionLaneId;RecommendedArtifact=$selected.ArtifactFileName;PublishedDriverLabel=$selected.PublishedDriverLabel;ObservedClientRuntimeEvidenceStatus=$selectedObservedStatus;ObservedClientRuntimeEvidenceIds=$observedSelectionIds;Reason=$selectedReason}) | Out-Null
        }
        else {
            $reviewObservedStatus=if($observedSelectionRecords.Count -gt 0){'ProcessorRuntimeObservedDifferentArtifact'}else{'NoObservedClientRuntimeEvidence'}
            $selections.Add([ordered]@{ProcessorId=[string]$processor.processorId;ProcessorName=[string]$processor.canonicalName;Codename=[string]$processor.codename;NpuAvailability=$npuAvailability;Decision='ReviewRequired';SelectionLaneId=$null;RecommendedArtifact=$null;PublishedDriverLabel=$null;ObservedClientRuntimeEvidenceStatus=$reviewObservedStatus;ObservedClientRuntimeEvidenceIds=$observedSelectionIds;Reason=[string]$laneSelection.Reason}) | Out-Null
        }
    }

    return [ordered]@{
        SchemaVersion='1.3';ToolVersion=$script:ToolVersion;HandEdited=$false
        Scope=[ordered]@{TargetServer=$TargetServer;ProcessorCatalogCompleteness=[string]$ProcessorDoc.catalogCompleteness;UnknownSkuPolicy=[string]$ProcessorDoc.unknownSkuPolicy;UnknownHardwarePolicy=[string]$HardwareDoc.unknownHardwarePolicy;SelectionAuthority='NonAuthoritativeProcessorResearchReference';RuntimeSelectionAuthority='data/hardware-driver-selection.json';PackageSelectionKey='WindowsPnpHardwareIdsMatchedAgainstReviewedInfModels';CpuNpuCombinationUsedForRuntimeSelection=$false;CurrentPackageCaseCount=2;GlobalVersionRankingProhibited=$true;ClientRuntimeEvidenceIncluded=$true;RuntimeProof=$false}
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
            PackageRole=[string]$artifact.packageRole
            SelectionLaneId=[string]$artifact.selectionLaneId
            SelectionBoundaryStatus=[string]$artifact.selectionBoundaryStatus
            RecommendationEligible=([string]$artifact.packageRole -eq 'CurrentNpuTypeCandidate' -and [string]$artifact.selectionBoundaryStatus -eq 'Resolved')
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
                        RecommendationEligible=[bool]$release.RecommendationEligible
                        PackageRole=[string]$mr.PackageRole
                        SelectionLaneId=[string]$mr.SelectionLaneId
                        SelectionBoundaryStatus=[string]$mr.SelectionBoundaryStatus
                        NpuIdentityApplicability=[string]$mr.NpuIdentityApplicability
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
                        ReleaseId=[string]$release.ReleaseId;Visibility=[string]$release.Visibility;RecommendationEligible=[bool]$release.RecommendationEligible;PackageRole=[string]$release.PackageRole;SelectionLaneId=[string]$release.SelectionLaneId;SelectionBoundaryStatus=[string]$release.SelectionBoundaryStatus;NpuIdentityApplicability='NoAnalyzedArtifactRow';Applicability='ReviewRequired';ServerStaticAssessment='Unknown';PublishedCodenameStatus='NoReviewedRule';InfHardwareCandidate=$false;InstallerBroadFamilyCandidate=$false;EvidenceClass='MissingAnalyzedArtifactRow';Reason='No unique compatibility-matrix row exists for this processor and reviewed public artifact.'
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
                $releaseMatch = @($releaseArray | Where-Object { [string]$_.ArtifactFileName -eq [string]$recommendedArtifact -and [string]$_.Visibility -eq 'PublicReviewed' } | Select-Object -First 1)
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
        SchemaVersion=(Get-NpuPublicSchemaVersionConst -SchemaFileName 'processor-driver-applicability.schema.json')
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
            ResolvedNpuTypePackageLaneRequired=[bool]$ApplicabilityDoc.recommendationPolicy.resolvedNpuTypePackageLaneRequired
            GlobalVersionRankingProhibited=[bool]$ApplicabilityDoc.recommendationPolicy.globalVersionRankingProhibited
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
    [void]$sb.AppendLine('- Exact-SKU research/audit reference only. It is not a driver-selection authority; runtime selection uses `data/hardware-driver-selection.json`.')
    [void]$sb.AppendLine('- CPU SKU, CPU ID and CPU/NPU combination inference are not inputs to the hardware-only driver-track resolver.')
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
    [void]$sb.AppendLine('- The catalog is retained only for research, coverage and human audit. It is not a driver-selection authority.')
    [void]$sb.AppendLine('- CPU SKU, CPU ID and CPU/NPU combination inference are not used by the hardware-only driver-track resolver.')
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
    [void]$sb.AppendLine('- This processor matrix is a retained research/audit reference and is not a driver-selection authority.')
    [void]$sb.AppendLine('- Runtime track selection is hardware-only through `data/hardware-driver-selection.json`; no result is installation or runtime proof.')
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
    if ($null -ne $Analysis.PSObject.Properties['SignatureAnalysis'] -and $null -ne $Analysis.SignatureAnalysis) {
        $signatureFiles = @($Analysis.SignatureAnalysis.Files)
        $signedEnvelopeFiles = @($signatureFiles | Where-Object { @($_.Envelopes).Count -gt 0 })
        [void]$sb.AppendLine('')
        [void]$sb.AppendLine('## Static signature analysis')
        [void]$sb.AppendLine('')
        [void]$sb.AppendLine("- Certificate target lane: ``$($Analysis.SignatureAnalysis.SelectionLaneId)``")
        [void]$sb.AppendLine("- Candidate files: $($signatureFiles.Count)")
        [void]$sb.AppendLine("- Files with parsed CMS/Authenticode envelopes: $($signedEnvelopeFiles.Count)")
        [void]$sb.AppendLine("- Unique embedded certificates: $($Analysis.SignatureAnalysis.UniqueCertificateCount)")
        [void]$sb.AppendLine('> This section is host-neutral static evidence. Windows trust-policy acceptance, catalog-bound SignTool verification, kernel load, and NPU runtime behavior require separate Windows evidence.')
    }
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
    try {
        $sourceText=[System.IO.File]::ReadAllText($Path)
        if($sourceText -match '\$text\s*=\s*Get-Content\s+-LiteralPath\s+\$Path\s+-Raw'){
            $issues.Add('JSON syntax validation must not use Get-Content -Raw for UTF-8 no-BOM files under Windows PowerShell 5.1.')|Out-Null
        }
        if(-not $sourceText.Contains('New-Object System.Text.UTF8Encoding($false,$true)')){
            $issues.Add('JSON syntax validation must explicitly use strict UTF-8 decoding.')|Out-Null
        }
    }
    catch{$issues.Add(('Source contract inspection failed: {0}' -f $_.Exception.Message))|Out-Null}
    return $issues.ToArray()
}

# --- shared certificate/signature verification engine -----------------------
function Get-AmdKernelSignatureCoverageAssessment {
    [CmdletBinding()]
    param(
        [AllowNull()]$NativeData
    )

    $expectedTargetPolicies = @(
        'WindowsDriverCatalogTargetWS2016',
        'WindowsDriverCatalogTargetWS2019',
        'WindowsDriverCatalogTargetWS2022',
        'WindowsDriverCatalogTargetWS2025'
    )

    $kernelFiles = @()
    if ($null -ne $NativeData -and $null -ne $NativeData.PSObject.Properties['Releases']) {
        $kernelFiles = @(
            $NativeData.Releases |
                ForEach-Object { @($_.Files) } |
                ForEach-Object { $_ } |
                Where-Object { [string]$_.FileType -eq 'KernelBinary' }
        )
    }

    $fullyCovered = New-Object 'System.Collections.Generic.List[string]'
    $coverageGaps = New-Object 'System.Collections.Generic.List[object]'
    $associationUnavailable = New-Object 'System.Collections.Generic.List[string]'
    $supplementalKernelNonZero = 0
    $defaultAuthenticodeNonZero = 0
    $requiredProfileNonZero = 0

    foreach ($file in $kernelFiles) {
        $checks = @($file.SignToolChecks)
        $supplementalKernelNonZero += @($checks | Where-Object {
            [string]$_.Policy -eq 'KernelModeEmbeddedOrCatalog' -and
            [string]$_.ResultClass -eq 'NonZeroExit'
        }).Count
        $defaultAuthenticodeNonZero += @($checks | Where-Object {
            [string]$_.Policy -eq 'DefaultAuthenticode' -and
            [string]$_.ResultClass -eq 'NonZeroExit'
        }).Count

        $associationProperty = $file.PSObject.Properties['CatalogBoundTargetVerification']
        if (
            $null -ne $associationProperty -and
            $null -ne $associationProperty.Value -and
            [string]$associationProperty.Value.Status -eq 'NotObservedCatalogAssociationUnavailable'
        ) {
            $associationUnavailable.Add([string]$file.FileId)
            continue
        }

        $kernelChecks = @($checks | Where-Object { [string]$_.Policy -eq 'KernelModeExplicitCatalog' })
        $kernelVerified = @($kernelChecks | Where-Object { [string]$_.ResultClass -eq 'Verified' }).Count
        $requiredProfileNonZero += @($kernelChecks | Where-Object { [string]$_.ResultClass -eq 'NonZeroExit' }).Count

        $missingTargets = New-Object 'System.Collections.Generic.List[string]'
        $unverifiedTargets = New-Object 'System.Collections.Generic.List[string]'
        foreach ($policy in $expectedTargetPolicies) {
            $policyChecks = @($checks | Where-Object { [string]$_.Policy -eq $policy })
            if ($policyChecks.Count -eq 0) {
                $missingTargets.Add($policy)
                continue
            }
            $requiredProfileNonZero += @($policyChecks | Where-Object { [string]$_.ResultClass -eq 'NonZeroExit' }).Count
            if (@($policyChecks | Where-Object { [string]$_.ResultClass -eq 'Verified' }).Count -eq 0) {
                $unverifiedTargets.Add($policy)
            }
        }

        if ($kernelVerified -gt 0 -and $missingTargets.Count -eq 0 -and $unverifiedTargets.Count -eq 0) {
            $fullyCovered.Add([string]$file.FileId)
        }
        else {
            $coverageGaps.Add([pscustomobject][ordered]@{
                FileId = [string]$file.FileId
                FileName = [string]$file.FileName
                KernelExplicitCatalogCheckCount = $kernelChecks.Count
                KernelExplicitCatalogVerifiedCount = $kernelVerified
                MissingTargetPolicies = @($missingTargets.ToArray())
                UnverifiedTargetPolicies = @($unverifiedTargets.ToArray())
            })
        }
    }

    $status = if ($coverageGaps.Count -gt 0) {
        'Fail'
    }
    elseif ($associationUnavailable.Count -gt 0 -or $requiredProfileNonZero -gt 0) {
        'PassWithNotes'
    }
    else {
        'Pass'
    }

    return [pscustomobject][ordered]@{
        Status = $status
        KernelFileCount = $kernelFiles.Count
        FullyCoveredKernelCount = $fullyCovered.Count
        CoverageGapKernelCount = $coverageGaps.Count
        AssociationUnavailableKernelCount = $associationUnavailable.Count
        RequiredProfileNonZeroCount = $requiredProfileNonZero
        SupplementalUnboundKernelPolicyNonZeroCount = $supplementalKernelNonZero
        DefaultAuthenticodeNonZeroCount = $defaultAuthenticodeNonZero
        ExpectedTargetPolicies = @($expectedTargetPolicies)
        FullyCoveredFileIds = @($fullyCovered.ToArray())
        AssociationUnavailableFileIds = @($associationUnavailable.ToArray())
        CoverageGaps = @($coverageGaps.ToArray())
    }
}

function Test-AmdKernelSignatureCoverageSelfTest {
    [CmdletBinding()]
    param()

    $verified = {
        param([string]$Policy)
        [pscustomobject][ordered]@{ Policy=$Policy; ResultClass='Verified'; Status='Pass'; ExitCode=0 }
    }

    $goodChecks = @(
        (& $verified 'KernelModeExplicitCatalog'),
        (& $verified 'WindowsDriverCatalogTargetWS2016'),
        (& $verified 'WindowsDriverCatalogTargetWS2019'),
        (& $verified 'WindowsDriverCatalogTargetWS2022'),
        (& $verified 'WindowsDriverCatalogTargetWS2025'),
        [pscustomobject][ordered]@{ Policy='KernelModeEmbeddedOrCatalog'; ResultClass='NonZeroExit'; Status='Fail'; ExitCode=1 }
    )
    $goodData = [pscustomobject][ordered]@{
        Releases=@([pscustomobject][ordered]@{
            Files=@([pscustomobject][ordered]@{FileId='sha256:good';FileName='good.sys';FileType='KernelBinary';SignToolChecks=@($goodChecks)})
        })
    }

    $missingData = [pscustomobject][ordered]@{
        Releases=@([pscustomobject][ordered]@{
            Files=@([pscustomobject][ordered]@{
                FileId='sha256:missing'
                FileName='missing.sys'
                FileType='KernelBinary'
                SignToolChecks=@(
                    (& $verified 'KernelModeExplicitCatalog'),
                    (& $verified 'WindowsDriverCatalogTargetWS2016'),
                    (& $verified 'WindowsDriverCatalogTargetWS2019'),
                    (& $verified 'WindowsDriverCatalogTargetWS2022')
                )
            })
        })
    }

    $unavailableData = [pscustomobject][ordered]@{
        Releases=@([pscustomobject][ordered]@{
            Files=@([pscustomobject][ordered]@{
                FileId='sha256:unavailable'
                FileName='unavailable.sys'
                FileType='KernelBinary'
                SignToolChecks=@()
                CatalogBoundTargetVerification=[pscustomobject][ordered]@{
                    Status='NotObservedCatalogAssociationUnavailable'
                    MatchedCatalogCount=0
                }
            })
        })
    }

    $good = Get-AmdKernelSignatureCoverageAssessment -NativeData $goodData
    $missing = Get-AmdKernelSignatureCoverageAssessment -NativeData $missingData
    $unavailable = Get-AmdKernelSignatureCoverageAssessment -NativeData $unavailableData
    $ok = (
        $good.Status -eq 'Pass' -and
        $good.KernelFileCount -eq 1 -and
        $good.FullyCoveredKernelCount -eq 1 -and
        $good.CoverageGapKernelCount -eq 0 -and
        $good.SupplementalUnboundKernelPolicyNonZeroCount -eq 1 -and
        $missing.Status -eq 'Fail' -and
        $missing.CoverageGapKernelCount -eq 1 -and
        $missing.CoverageGaps[0].MissingTargetPolicies -contains 'WindowsDriverCatalogTargetWS2025' -and
        $unavailable.Status -eq 'PassWithNotes' -and
        $unavailable.AssociationUnavailableKernelCount -eq 1
    )

    return [pscustomobject][ordered]@{
        Status=if($ok){'Pass'}else{'Fail'}
        GoodCoverageStatus=$good.Status
        MissingTargetCoverageStatus=$missing.Status
        AssociationUnavailableCoverageStatus=$unavailable.Status
    }
}
function ConvertTo-AmdHexString {
    [CmdletBinding()]
    param(
        [AllowNull()]
        [byte[]]$Bytes
    )

    if ($null -eq $Bytes) { return $null }
    return ([System.BitConverter]::ToString($Bytes) -replace '-', '').ToLowerInvariant()
}

function Get-AmdByteArraySha256 {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [AllowNull()]
        [AllowEmptyCollection()]
        [byte[]]$Bytes
    )

    # Windows PowerShell 5.1 collapses an empty array emitted from an if/script
    # expression to $null.  Native tools may legitimately return zero output,
    # so normalize that PS5.1 representation to an empty payload.
    if ($null -eq $Bytes) {
        $Bytes = New-Object byte[] 0
    }

    $hash = [System.Security.Cryptography.SHA256]::Create()
    try {
        return ConvertTo-AmdHexString -Bytes ($hash.ComputeHash($Bytes))
    }
    finally {
        $hash.Dispose()
    }
}

function Read-AmdDerLength {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][byte[]]$Bytes,
        [Parameter(Mandatory = $true)][ref]$Offset
    )

    if ($Offset.Value -ge $Bytes.Length) { throw 'DER length is truncated.' }
    $first = [int]$Bytes[$Offset.Value]
    $Offset.Value++
    if (($first -band 0x80) -eq 0) { return $first }

    $count = $first -band 0x7f
    if ($count -eq 0 -or $count -gt 4) { throw ('Unsupported DER length width: {0}' -f $count) }
    if (($Offset.Value + $count) -gt $Bytes.Length) { throw 'DER long-form length is truncated.' }

    $value = 0
    for ($i = 0; $i -lt $count; $i++) {
        $value = ($value -shl 8) -bor [int]$Bytes[$Offset.Value]
        $Offset.Value++
    }
    return $value
}

function Read-AmdDerElement {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][byte[]]$Bytes,
        [Parameter(Mandatory = $true)][int]$Offset
    )

    if ($Offset -lt 0 -or $Offset -ge $Bytes.Length) { throw 'DER element offset is outside the input buffer.' }
    $cursor = $Offset
    $tag = [int]$Bytes[$cursor]
    $cursor++
    $length = Read-AmdDerLength -Bytes $Bytes -Offset ([ref]$cursor)
    if (($cursor + $length) -gt $Bytes.Length) { throw 'DER element content is truncated.' }

    return [pscustomobject][ordered]@{
        Tag = $tag
        Offset = $Offset
        ContentOffset = $cursor
        ContentLength = $length
        NextOffset = $cursor + $length
    }
}

function ConvertFrom-AmdDerOid {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][byte[]]$Bytes,
        [Parameter(Mandatory = $true)][int]$Offset,
        [Parameter(Mandatory = $true)][int]$Length
    )

    if ($Length -le 0 -or ($Offset + $Length) -gt $Bytes.Length) { throw 'DER OID bounds are invalid.' }
    $first = [int]$Bytes[$Offset]
    $parts = New-Object System.Collections.Generic.List[long]
    $firstArc = [Math]::Min(2, [Math]::Floor($first / 40))
    $secondArc = $first - (40 * $firstArc)
    $parts.Add([long]$firstArc)
    $parts.Add([long]$secondArc)

    $value = [long]0
    for ($i = $Offset + 1; $i -lt ($Offset + $Length); $i++) {
        $value = ($value -shl 7) -bor ([int]$Bytes[$i] -band 0x7f)
        if (([int]$Bytes[$i] -band 0x80) -eq 0) {
            $parts.Add($value)
            $value = 0
        }
    }
    return ($parts.ToArray() -join '.')
}

function Get-AmdSpcIndirectDataDigest {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][byte[]]$Content
    )

    try {
        $outer = Read-AmdDerElement -Bytes $Content -Offset 0
        if ($outer.Tag -ne 0x30) { throw 'SPC indirect data is not a DER sequence.' }
        $data = Read-AmdDerElement -Bytes $Content -Offset $outer.ContentOffset
        $digestInfo = Read-AmdDerElement -Bytes $Content -Offset $data.NextOffset
        if ($digestInfo.Tag -ne 0x30) { throw 'SPC DigestInfo is not a DER sequence.' }
        $algorithm = Read-AmdDerElement -Bytes $Content -Offset $digestInfo.ContentOffset
        if ($algorithm.Tag -ne 0x30) { throw 'SPC digest algorithm is not a DER sequence.' }
        $oidElement = Read-AmdDerElement -Bytes $Content -Offset $algorithm.ContentOffset
        if ($oidElement.Tag -ne 0x06) { throw 'SPC digest algorithm OID is missing.' }
        $oid = ConvertFrom-AmdDerOid -Bytes $Content -Offset $oidElement.ContentOffset -Length $oidElement.ContentLength
        $digestElement = Read-AmdDerElement -Bytes $Content -Offset $algorithm.NextOffset
        if ($digestElement.Tag -ne 0x04) { throw 'SPC digest value is not an OCTET STRING.' }
        $digest = New-Object byte[] $digestElement.ContentLength
        [System.Array]::Copy($Content, $digestElement.ContentOffset, $digest, 0, $digest.Length)
        return [pscustomobject][ordered]@{
            Status = 'Parsed'
            DigestAlgorithmOid = $oid
            DigestHex = ConvertTo-AmdHexString -Bytes $digest
            Error = $null
        }
    }
    catch {
        return [pscustomobject][ordered]@{
            Status = 'ParseFailed'
            DigestAlgorithmOid = $null
            DigestHex = $null
            Error = $_.Exception.Message
        }
    }
}

function Test-AmdSpcIndirectDataContentType {
    [CmdletBinding()]
    param([AllowNull()][string]$ContentTypeOid)

    return ([string]$ContentTypeOid -eq '1.3.6.1.4.1.311.2.1.4')
}

function Get-AmdSpcIndirectDataDigestForContentType {
    [CmdletBinding()]
    param(
        [AllowNull()][string]$ContentTypeOid,
        [Parameter(Mandatory = $true)][byte[]]$Content
    )

    # SPC Indirect Data parsing is meaningful only for Authenticode
    # SpcIndirectDataContent (1.3.6.1.4.1.311.2.1.4). RFC3161 timestamp
    # TSTInfo and Authenticode catalog CTL content are different ASN.1 payloads;
    # treating them as malformed SPC data creates false ParseFailed evidence.
    if (-not (Test-AmdSpcIndirectDataContentType -ContentTypeOid $ContentTypeOid)) {
        return [pscustomobject][ordered]@{
            Status='NotApplicableContentType'
            ContentTypeOid=$ContentTypeOid
            DigestAlgorithmOid=$null
            DigestHex=$null
            Error=$null
        }
    }
    return Get-AmdSpcIndirectDataDigest -Content $Content
}

function Test-AmdSignatureContentTypeRoutingSelfTest {
    [CmdletBinding()]
    param()

    $dummy = [byte[]](0x30,0x00)
    $timestamp = Get-AmdSpcIndirectDataDigestForContentType -ContentTypeOid '1.2.840.113549.1.9.16.1.4' -Content $dummy
    $catalog = Get-AmdSpcIndirectDataDigestForContentType -ContentTypeOid '1.3.6.1.4.1.311.10.1' -Content $dummy
    $authenticodeRoute = Test-AmdSpcIndirectDataContentType -ContentTypeOid '1.3.6.1.4.1.311.2.1.4'
    $timestampRoute = Test-AmdSpcIndirectDataContentType -ContentTypeOid '1.2.840.113549.1.9.16.1.4'
    $catalogRoute = Test-AmdSpcIndirectDataContentType -ContentTypeOid '1.3.6.1.4.1.311.10.1'

    # The normal Test stage must not intentionally feed malformed Authenticode DER
    # to a parser that is expected to reject it, because Start-Transcript records
    # caught terminating errors. Routing is tested without exception injection.
    $ok = (
        $timestamp.Status -eq 'NotApplicableContentType' -and $null -eq $timestamp.Error -and
        $catalog.Status -eq 'NotApplicableContentType' -and $null -eq $catalog.Error -and
        $authenticodeRoute -and
        -not $timestampRoute -and
        -not $catalogRoute
    )

    return [pscustomobject][ordered]@{
        Status=if($ok){'Pass'}else{'Fail'}
        TimestampStatus=$timestamp.Status
        CatalogStatus=$catalog.Status
        AuthenticodeRouteRecognized=$authenticodeRoute
        TimestampRouteRejected=(-not $timestampRoute)
        CatalogRouteRejected=(-not $catalogRoute)
        MalformedDerInjectedDuringSelfTest=$false
    }
}

function New-AmdHashAlgorithmForOid {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$Oid
    )

    switch ($Oid) {
        '1.3.14.3.2.26' {
            # SHA-1 is used only to reproduce legacy Authenticode evidence.
            # psa-disable-next-line PSA5003
            return [System.Security.Cryptography.SHA1]::Create()
        }
        '2.16.840.1.101.3.4.2.1' { return [System.Security.Cryptography.SHA256]::Create() }
        '2.16.840.1.101.3.4.2.2' { return [System.Security.Cryptography.SHA384]::Create() }
        '2.16.840.1.101.3.4.2.3' { return [System.Security.Cryptography.SHA512]::Create() }
        default { return $null }
    }
}

function Add-AmdHashSegment {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][System.Security.Cryptography.HashAlgorithm]$Hash,
        [Parameter(Mandatory = $true)][byte[]]$Bytes,
        [Parameter(Mandatory = $true)][int]$Offset,
        [Parameter(Mandatory = $true)][int]$Length
    )

    if ($Length -le 0) { return }
    if ($Offset -lt 0 -or ($Offset + $Length) -gt $Bytes.Length) { throw 'Authenticode hash segment is outside the file.' }
    $buffer = New-Object byte[] $Length
    [System.Array]::Copy($Bytes, $Offset, $buffer, 0, $Length)
    $null = $Hash.TransformBlock($buffer, 0, $buffer.Length, $buffer, 0)
}

function Get-AmdAuthenticodePeDigest {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$DigestAlgorithmOid
    )

    $hash = New-AmdHashAlgorithmForOid -Oid $DigestAlgorithmOid
    if ($null -eq $hash) {
        return [pscustomobject][ordered]@{ Status='UnsupportedDigestAlgorithm'; DigestAlgorithmOid=$DigestAlgorithmOid; DigestHex=$null; Error=$null }
    }

    try {
        $bytes = [System.IO.File]::ReadAllBytes($Path)
        if ($bytes.Length -lt 0x100) { throw 'PE file is too small.' }
        if ($bytes[0] -ne 0x4d -or $bytes[1] -ne 0x5a) { throw 'DOS MZ signature is missing.' }
        $peOffset = [System.BitConverter]::ToInt32($bytes, 0x3c)
        if ($peOffset -lt 0 -or ($peOffset + 24) -gt $bytes.Length) { throw 'PE header offset is invalid.' }
        if ($bytes[$peOffset] -ne 0x50 -or $bytes[$peOffset + 1] -ne 0x45 -or $bytes[$peOffset + 2] -ne 0 -or $bytes[$peOffset + 3] -ne 0) { throw 'PE signature is missing.' }

        $numberOfSections = [int][System.BitConverter]::ToUInt16($bytes, $peOffset + 6)
        $sizeOfOptionalHeader = [int][System.BitConverter]::ToUInt16($bytes, $peOffset + 20)
        $optionalOffset = $peOffset + 24
        $magic = [System.BitConverter]::ToUInt16($bytes, $optionalOffset)
        if ($magic -eq 0x20b) { $securityDirectoryOffset = $optionalOffset + 144 }
        elseif ($magic -eq 0x10b) { $securityDirectoryOffset = $optionalOffset + 128 }
        else { throw ('Unsupported PE optional-header magic: 0x{0:x}' -f $magic) }

        $checksumOffset = $optionalOffset + 64
        $sizeOfHeaders = [int][System.BitConverter]::ToUInt32($bytes, $optionalOffset + 60)
        if ($sizeOfHeaders -le 0 -or $sizeOfHeaders -gt $bytes.Length) { throw 'PE SizeOfHeaders is invalid.' }
        if (($securityDirectoryOffset + 8) -gt $sizeOfHeaders) { throw 'PE security directory is outside the headers.' }

        $certificateOffset = [int64][System.BitConverter]::ToUInt32($bytes, $securityDirectoryOffset)
        $certificateSize = [int64][System.BitConverter]::ToUInt32($bytes, $securityDirectoryOffset + 4)

        Add-AmdHashSegment -Hash $hash -Bytes $bytes -Offset 0 -Length $checksumOffset
        Add-AmdHashSegment -Hash $hash -Bytes $bytes -Offset ($checksumOffset + 4) -Length ($securityDirectoryOffset - ($checksumOffset + 4))
        Add-AmdHashSegment -Hash $hash -Bytes $bytes -Offset ($securityDirectoryOffset + 8) -Length ($sizeOfHeaders - ($securityDirectoryOffset + 8))

        $sectionTableOffset = $optionalOffset + $sizeOfOptionalHeader
        $sections = New-Object System.Collections.Generic.List[object]
        for ($index = 0; $index -lt $numberOfSections; $index++) {
            $sectionOffset = $sectionTableOffset + (40 * $index)
            if (($sectionOffset + 40) -gt $bytes.Length) { throw 'PE section table is truncated.' }
            $rawSize = [int][System.BitConverter]::ToUInt32($bytes, $sectionOffset + 16)
            $rawPointer = [int][System.BitConverter]::ToUInt32($bytes, $sectionOffset + 20)
            if ($rawSize -gt 0) {
                $sections.Add([pscustomobject]@{ Pointer=$rawPointer; Size=$rawSize })
            }
        }

        $sumOfBytesHashed = [int64]$sizeOfHeaders
        foreach ($section in @($sections.ToArray() | Sort-Object Pointer)) {
            Add-AmdHashSegment -Hash $hash -Bytes $bytes -Offset ([int]$section.Pointer) -Length ([int]$section.Size)
            $sumOfBytesHashed += [int64]$section.Size
        }

        if ($certificateSize -gt 0 -and $certificateOffset -gt $sumOfBytesHashed) {
            Add-AmdHashSegment -Hash $hash -Bytes $bytes -Offset ([int]$sumOfBytesHashed) -Length ([int]($certificateOffset - $sumOfBytesHashed))
        }
        elseif ($certificateSize -eq 0 -and $sumOfBytesHashed -lt $bytes.Length) {
            Add-AmdHashSegment -Hash $hash -Bytes $bytes -Offset ([int]$sumOfBytesHashed) -Length ([int]($bytes.Length - $sumOfBytesHashed))
        }

        $empty = New-Object byte[] 0
        $null = $hash.TransformFinalBlock($empty, 0, 0)
        return [pscustomobject][ordered]@{
            Status = 'Calculated'
            DigestAlgorithmOid = $DigestAlgorithmOid
            DigestHex = ConvertTo-AmdHexString -Bytes $hash.Hash
            Error = $null
        }
    }
    catch {
        return [pscustomobject][ordered]@{ Status='CalculationFailed'; DigestAlgorithmOid=$DigestAlgorithmOid; DigestHex=$null; Error=$_.Exception.Message }
    }
    finally {
        $hash.Dispose()
    }
}

function Get-AmdPeCertificateEntries {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$Path
    )

    $entries = New-Object System.Collections.Generic.List[object]
    try {
        $bytes = [System.IO.File]::ReadAllBytes($Path)
        if ($bytes.Length -lt 0x100 -or $bytes[0] -ne 0x4d -or $bytes[1] -ne 0x5a) {
            return [pscustomobject][ordered]@{ Status='NotPe'; Entries=@(); Error=$null }
        }
        $peOffset = [System.BitConverter]::ToInt32($bytes, 0x3c)
        $optionalOffset = $peOffset + 24
        $magic = [System.BitConverter]::ToUInt16($bytes, $optionalOffset)
        if ($magic -eq 0x20b) { $securityDirectoryOffset = $optionalOffset + 144 }
        elseif ($magic -eq 0x10b) { $securityDirectoryOffset = $optionalOffset + 128 }
        else { return [pscustomobject][ordered]@{ Status='UnsupportedPe'; Entries=@(); Error=('Optional header magic 0x{0:x}' -f $magic) } }

        $certificateOffset = [int][System.BitConverter]::ToUInt32($bytes, $securityDirectoryOffset)
        $certificateSize = [int][System.BitConverter]::ToUInt32($bytes, $securityDirectoryOffset + 4)
        if ($certificateOffset -eq 0 -or $certificateSize -eq 0) {
            return [pscustomobject][ordered]@{ Status='NoCertificateTable'; Entries=@(); Error=$null }
        }
        if ($certificateOffset -lt 0 -or ($certificateOffset + $certificateSize) -gt $bytes.Length) { throw 'PE certificate table is outside the file.' }

        $cursor = $certificateOffset
        $end = $certificateOffset + $certificateSize
        $index = 0
        while (($cursor + 8) -le $end) {
            $length = [int][System.BitConverter]::ToUInt32($bytes, $cursor)
            $revision = [int][System.BitConverter]::ToUInt16($bytes, $cursor + 4)
            $certificateType = [int][System.BitConverter]::ToUInt16($bytes, $cursor + 6)
            if ($length -lt 8 -or ($cursor + $length) -gt $end) { throw 'WIN_CERTIFICATE entry length is invalid.' }
            $payloadLength = $length - 8
            $payload = New-Object byte[] $payloadLength
            [System.Array]::Copy($bytes, $cursor + 8, $payload, 0, $payloadLength)
            $entries.Add([pscustomobject][ordered]@{
                Index = $index
                Offset = $cursor
                Length = $length
                Revision = ('0x{0:x4}' -f $revision)
                CertificateType = ('0x{0:x4}' -f $certificateType)
                PayloadSha256 = Get-AmdByteArraySha256 -Bytes $payload
                Payload = $payload
            })
            $aligned = (($length + 7) -band (-bnot 7))
            if ($aligned -le 0) { break }
            $cursor += $aligned
            $index++
        }
        return [pscustomobject][ordered]@{ Status='Parsed'; Entries=@($entries.ToArray()); Error=$null }
    }
    catch {
        return [pscustomobject][ordered]@{ Status='ParseFailed'; Entries=@($entries.ToArray()); Error=$_.Exception.Message }
    }
}

function Get-AmdCertificateEvidence {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][System.Security.Cryptography.X509Certificates.X509Certificate2]$Certificate
    )

    $raw = $Certificate.RawData
    $certificateId = 'sha256:' + (Get-AmdByteArraySha256 -Bytes $raw)
    $extensions = New-Object System.Collections.Generic.List[object]
    $ekuValues = New-Object System.Collections.Generic.List[object]
    foreach ($extension in @($Certificate.Extensions)) {
        $extensions.Add([pscustomobject][ordered]@{
            Oid = [string]$extension.Oid.Value
            Critical = [bool]$extension.Critical
            RawDataSha256 = Get-AmdByteArraySha256 -Bytes $extension.RawData
        })
        if ([string]$extension.Oid.Value -eq '2.5.29.37') {
            try {
                $eku = New-Object System.Security.Cryptography.X509Certificates.X509EnhancedKeyUsageExtension
                $eku.CopyFrom($extension)
                foreach ($oid in @($eku.EnhancedKeyUsages)) {
                    $ekuValues.Add([pscustomobject][ordered]@{ Oid=[string]$oid.Value; FriendlyName=[string]$oid.FriendlyName })
                }
            }
            catch { }
        }
    }

    $keySize = $null
    try { $keySize = [int]$Certificate.PublicKey.Key.KeySize } catch { }

    return [pscustomobject][ordered]@{
        CertificateId = $certificateId
        DerSha256 = $certificateId.Substring(7)
        ThumbprintSha1 = ([string]$Certificate.Thumbprint).ToLowerInvariant()
        Subject = [string]$Certificate.Subject
        Issuer = [string]$Certificate.Issuer
        SerialNumber = [string]$Certificate.SerialNumber
        NotBeforeUtc = $Certificate.NotBefore.ToUniversalTime().ToString('o')
        NotAfterUtc = $Certificate.NotAfter.ToUniversalTime().ToString('o')
        SignatureAlgorithm = [pscustomobject][ordered]@{ Oid=[string]$Certificate.SignatureAlgorithm.Value; FriendlyName=[string]$Certificate.SignatureAlgorithm.FriendlyName }
        PublicKeyAlgorithm = [pscustomobject][ordered]@{ Oid=[string]$Certificate.PublicKey.Oid.Value; FriendlyName=[string]$Certificate.PublicKey.Oid.FriendlyName; KeySize=$keySize }
        EnhancedKeyUsages = @($ekuValues.ToArray())
        Extensions = @($extensions.ToArray())
    }
}

function Add-AmdCertificateEvidence {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][System.Security.Cryptography.X509Certificates.X509Certificate2]$Certificate,
        [Parameter(Mandatory = $true)][hashtable]$CertificateStore
    )

    $record = Get-AmdCertificateEvidence -Certificate $Certificate
    if (-not $CertificateStore.ContainsKey($record.CertificateId)) {
        $CertificateStore[$record.CertificateId] = $record
    }
    return $record.CertificateId
}

function ConvertTo-AmdCryptographicAttributeEvidence {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]$Attribute
    )

    $valueHashes = New-Object System.Collections.Generic.List[string]
    foreach ($value in @($Attribute.Values)) {
        $valueHashes.Add((Get-AmdByteArraySha256 -Bytes $value.RawData))
    }
    return [pscustomobject][ordered]@{
        Oid = [string]$Attribute.Oid.Value
        FriendlyName = [string]$Attribute.Oid.FriendlyName
        ValueCount = @($Attribute.Values).Count
        ValueSha256 = @($valueHashes.ToArray())
    }
}

function Get-AmdSignerInfoEvidence {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]$SignerInfo,
        [Parameter(Mandatory = $true)][hashtable]$CertificateStore,
        [Parameter(Mandatory = $true)][string]$Role,
        [AllowNull()][string]$ParentSignerId,
        [Parameter(Mandatory = $true)][string]$SignerId
    )

    $certificateId = $null
    if ($null -ne $SignerInfo.Certificate) {
        $certificateId = Add-AmdCertificateEvidence -Certificate $SignerInfo.Certificate -CertificateStore $CertificateStore
    }
    $signedAttributes = @($SignerInfo.SignedAttributes | ForEach-Object { ConvertTo-AmdCryptographicAttributeEvidence -Attribute $_ })
    $unsignedAttributes = @($SignerInfo.UnsignedAttributes | ForEach-Object { ConvertTo-AmdCryptographicAttributeEvidence -Attribute $_ })
    $counterSigners = New-Object System.Collections.Generic.List[object]
    $counterIndex = 0
    foreach ($counterSigner in @($SignerInfo.CounterSignerInfos)) {
        $counterSigners.Add((Get-AmdSignerInfoEvidence -SignerInfo $counterSigner -CertificateStore $CertificateStore -Role 'CounterSignature' -ParentSignerId $SignerId -SignerId ('{0}/counter/{1}' -f $SignerId,$counterIndex)))
        $counterIndex++
    }

    $signatureAlgorithmOid = $null
    $signatureAlgorithmFriendlyName = $null
    if ($null -ne $SignerInfo.PSObject.Properties['SignatureAlgorithm'] -and $null -ne $SignerInfo.SignatureAlgorithm) {
        $signatureAlgorithmOid = [string]$SignerInfo.SignatureAlgorithm.Value
        $signatureAlgorithmFriendlyName = [string]$SignerInfo.SignatureAlgorithm.FriendlyName
    }

    return [pscustomobject][ordered]@{
        SignerId = $SignerId
        Role = $Role
        ParentSignerId = $ParentSignerId
        CertificateId = $certificateId
        DigestAlgorithm = [pscustomobject][ordered]@{ Oid=[string]$SignerInfo.DigestAlgorithm.Value; FriendlyName=[string]$SignerInfo.DigestAlgorithm.FriendlyName }
        SignatureAlgorithm = [pscustomobject][ordered]@{ Oid=$signatureAlgorithmOid; FriendlyName=$signatureAlgorithmFriendlyName }
        SignedAttributes = @($signedAttributes)
        UnsignedAttributes = @($unsignedAttributes)
        CounterSigners = @($counterSigners.ToArray())
    }
}

function Initialize-AmdManagedAssemblyProbeType {
    [CmdletBinding()]
    param()

    $typeName = 'AmdResearch.ManagedAssemblyProbe'
    if ($null -ne ($typeName -as [type])) {
        return [pscustomobject][ordered]@{ Status='Available'; TypeName=$typeName; Error=$null }
    }

    $source = @'
using System;
using System.Reflection;

namespace AmdResearch
{
    public sealed class ManagedAssemblyProbeResult
    {
        public bool Loaded;
        public string RequestedAssemblyName;
        public string LoadedAssemblyName;
        public string ExceptionType;
        public string Error;
    }

    public static class ManagedAssemblyProbe
    {
        public static ManagedAssemblyProbeResult TryLoad(string assemblyName)
        {
            var result = new ManagedAssemblyProbeResult();
            result.RequestedAssemblyName = assemblyName;
            try
            {
                var loaded = Assembly.Load(new AssemblyName(assemblyName));
                result.Loaded = loaded != null;
                result.LoadedAssemblyName = loaded != null ? loaded.GetName().Name : null;
                return result;
            }
            catch (Exception ex)
            {
                result.Loaded = false;
                result.ExceptionType = ex.GetType().FullName;
                result.Error = ex.Message;
                return result;
            }
        }
    }
}
'@

    try {
        Add-Type -TypeDefinition $source -Language CSharp -ErrorAction Stop
    }
    catch {
        return [pscustomobject][ordered]@{
            Status='Unavailable'
            TypeName=$typeName
            Error=(Get-AmdCompactErrorMessage -Message $_.Exception.Message -MaximumLength 600)
        }
    }

    return [pscustomobject][ordered]@{
        Status=if($null -ne ($typeName -as [type])){'Available'}else{'Unavailable'}
        TypeName=$typeName
        Error=if($null -ne ($typeName -as [type])){$null}else{'Managed assembly probe type did not resolve after Add-Type.'}
    }
}

function Invoke-AmdExpectedAssemblyLoadAttempt {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$AssemblyName
    )

    $probeType = Initialize-AmdManagedAssemblyProbeType
    if ($probeType.Status -ne 'Available') {
        return [pscustomobject][ordered]@{
            AssemblyName=$AssemblyName
            Status='ProbeUnavailable'
            ErrorCount=1
            Errors=@($probeType.Error)
            LoadedAssemblyName=$null
        }
    }

    # The C# helper catches Assembly.Load exceptions internally. Expected "not found"
    # outcomes remain structured data and never become PowerShell ErrorRecords.
    $probe = [AmdResearch.ManagedAssemblyProbe]::TryLoad($AssemblyName)
    $errors = @()
    if (-not $probe.Loaded) {
        $detail = if ($probe.ExceptionType) {
            '{0}: {1}' -f $probe.ExceptionType,(Get-AmdCompactErrorMessage -Message ([string]$probe.Error) -MaximumLength 400)
        }
        else {
            Get-AmdCompactErrorMessage -Message ([string]$probe.Error) -MaximumLength 400
        }
        $errors = @($detail)
    }

    return [pscustomobject][ordered]@{
        AssemblyName=$AssemblyName
        Status=if($probe.Loaded){'LoadCompleted'}else{'LoadFailed'}
        ErrorCount=@($errors).Count
        Errors=@($errors)
        LoadedAssemblyName=[string]$probe.LoadedAssemblyName
    }
}

function Test-AmdExpectedFallbackProbeSelfTest {
    [CmdletBinding()]
    param()

    $output = @(& {
        Invoke-AmdExpectedAssemblyLoadAttempt -AssemblyName 'Amd.Research.Intentionally.Missing.Assembly.For.SelfTest'
    } 2>&1)

    $errorStreamItems = @($output | Where-Object { $_ -is [System.Management.Automation.ErrorRecord] })
    $resultItems = @($output | Where-Object { $_ -isnot [System.Management.Automation.ErrorRecord] })
    $result = if ($resultItems.Count -gt 0) { $resultItems[0] } else { $null }

    $ok = (
        $errorStreamItems.Count -eq 0 -and
        $null -ne $result -and
        [string]$result.Status -eq 'LoadFailed' -and
        [int]$result.ErrorCount -ge 1
    )

    return [pscustomobject][ordered]@{
        Status = if ($ok) { 'Pass' } else { 'Fail' }
        ErrorStreamItemCount = $errorStreamItems.Count
        ProbeStatus = if ($result) { [string]$result.Status } else { 'NoResult' }
        CapturedErrorCount = if ($result) { [int]$result.ErrorCount } else { 0 }
        ExpectedFallbackErrorsRemainStructured = ($errorStreamItems.Count -eq 0)
        ProbeImplementation = 'ManagedAssemblyProbeNoThrow/1'
    }
}


function Initialize-AmdSignedCmsRuntime {
    [CmdletBinding()]
    param()

    $typeName = 'System.Security.Cryptography.Pkcs.SignedCms'
    $resolvedType = $typeName -as [type]
    if ($null -ne $resolvedType) {
        return [pscustomobject][ordered]@{
            Status = 'Available'
            TypeName = $typeName
            AssemblyName = [string]$resolvedType.Assembly.GetName().Name
            LoadAttempts = @()
            Error = $null
        }
    }

    $attempts = New-Object System.Collections.Generic.List[object]
    # Assembly.Load(new AssemblyName('System.Security')) is a partial-name load and
    # can fail in a clean Windows PowerShell 5.1 process even though the .NET
    # Framework assembly is installed. Keep the .NET/Core candidate first, then
    # use the complete .NET Framework strong name so the result does not depend on
    # some earlier command having already loaded System.Security.
    foreach ($assemblyName in @(
        'System.Security.Cryptography.Pkcs',
        'System.Security, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a'
    )) {
        $loadAttempt = Invoke-AmdExpectedAssemblyLoadAttempt -AssemblyName $assemblyName
        $resolvedType = $typeName -as [type]
        $status = if ($null -ne $resolvedType) {
            'LoadedAndResolved'
        }
        elseif ($loadAttempt.Status -eq 'LoadFailed') {
            'LoadFailedExpectedFallback'
        }
        else {
            'LoadedTypeUnresolved'
        }

        $attempts.Add([pscustomobject][ordered]@{
            AssemblyName = $assemblyName
            Status = $status
            Error = if ($loadAttempt.ErrorCount -gt 0) { ($loadAttempt.Errors -join ' | ') } else { $null }
        })

        if ($status -eq 'LoadFailedExpectedFallback') {
            Write-AmdDiagnosticEvent `
                -EventName 'ExpectedAssemblyFallback' `
                -Level 'Info' `
                -FunctionName 'Initialize-AmdSignedCmsRuntime' `
                -Step 'LoadOptionalAssembly' `
                -Data @{ AssemblyName=$assemblyName; Status=$status; Errors=@($loadAttempt.Errors) }
        }

        if ($null -ne $resolvedType) {
            return [pscustomobject][ordered]@{
                Status = 'Available'
                TypeName = $typeName
                AssemblyName = [string]$resolvedType.Assembly.GetName().Name
                LoadAttempts = @($attempts.ToArray())
                Error = $null
            }
        }
    }

    return [pscustomobject][ordered]@{
        Status = 'Unavailable'
        TypeName = $typeName
        AssemblyName = $null
        LoadAttempts = @($attempts.ToArray())
        Error = 'System.Security.Cryptography.Pkcs.SignedCms could not be resolved after attempting the supported runtime assemblies.'
    }
}

function Get-AmdSignedCmsEvidence {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][byte[]]$Bytes,
        [Parameter(Mandatory = $true)][hashtable]$CertificateStore,
        [Parameter(Mandatory = $true)][string]$EnvelopeId,
        [Parameter(Mandatory = $true)][string]$Role,
        [AllowNull()][string]$PePath,
        [int]$Depth = 0,
        [int]$MaxDepth = 8
    )

    if ($Depth -gt $MaxDepth) {
        return [pscustomobject][ordered]@{ EnvelopeId=$EnvelopeId; Role=$Role; Status='DepthLimit'; Error='Nested signature depth limit reached.' }
    }

    $pkcsRuntime = Initialize-AmdSignedCmsRuntime
    if ($pkcsRuntime.Status -ne 'Available') {
        return [pscustomobject][ordered]@{
            EnvelopeId = $EnvelopeId
            Role = $Role
            Status = 'RuntimeUnavailable'
            CmsSha256 = Get-AmdByteArraySha256 -Bytes $Bytes
            Runtime = $pkcsRuntime
            Error = $pkcsRuntime.Error
        }
    }

    try {
        $cms = New-Object System.Security.Cryptography.Pkcs.SignedCms
        $cms.Decode($Bytes)
        foreach ($certificate in @($cms.Certificates)) {
            $null = Add-AmdCertificateEvidence -Certificate $certificate -CertificateStore $CertificateStore
        }

        $cryptographicStatus = 'Valid'
        $cryptographicError = $null
        try { $cms.CheckSignature($true) }
        catch { $cryptographicStatus='Invalid'; $cryptographicError=$_.Exception.Message }

        $contentTypeOid = [string]$cms.ContentInfo.ContentType.Value
        $spcDigest = Get-AmdSpcIndirectDataDigestForContentType -ContentTypeOid $contentTypeOid -Content $cms.ContentInfo.Content
        $peDigest = $null
        $digestMatches = $null
        if ($PePath -and $spcDigest.Status -eq 'Parsed') {
            $peDigest = Get-AmdAuthenticodePeDigest -Path $PePath -DigestAlgorithmOid $spcDigest.DigestAlgorithmOid
            if ($peDigest.Status -eq 'Calculated') {
                $digestMatches = ([string]$spcDigest.DigestHex -eq [string]$peDigest.DigestHex)
            }
        }

        $signers = New-Object System.Collections.Generic.List[object]
        $nested = New-Object System.Collections.Generic.List[object]
        $timestamps = New-Object System.Collections.Generic.List[object]
        $signerIndex = 0
        foreach ($signer in @($cms.SignerInfos)) {
            $signerId = '{0}/signer/{1}' -f $EnvelopeId,$signerIndex
            $signers.Add((Get-AmdSignerInfoEvidence -SignerInfo $signer -CertificateStore $CertificateStore -Role $Role -ParentSignerId $null -SignerId $signerId))
            $attributeIndex = 0
            foreach ($attribute in @($signer.UnsignedAttributes)) {
                $oid = [string]$attribute.Oid.Value
                $valueIndex = 0
                foreach ($value in @($attribute.Values)) {
                    if ($oid -eq '1.3.6.1.4.1.311.2.4.1') {
                        $nested.Add((Get-AmdSignedCmsEvidence -Bytes $value.RawData -CertificateStore $CertificateStore -EnvelopeId ('{0}/nested/{1}/{2}' -f $EnvelopeId,$attributeIndex,$valueIndex) -Role 'NestedSignature' -PePath $PePath -Depth ($Depth + 1) -MaxDepth $MaxDepth))
                    }
                    elseif ($oid -eq '1.3.6.1.4.1.311.3.3.1') {
                        $timestamps.Add((Get-AmdSignedCmsEvidence -Bytes $value.RawData -CertificateStore $CertificateStore -EnvelopeId ('{0}/timestamp/{1}/{2}' -f $EnvelopeId,$attributeIndex,$valueIndex) -Role 'Rfc3161Timestamp' -Depth ($Depth + 1) -MaxDepth $MaxDepth))
                    }
                    $valueIndex++
                }
                $attributeIndex++
            }
            $signerIndex++
        }

        return [pscustomobject][ordered]@{
            EnvelopeId = $EnvelopeId
            Role = $Role
            Status = 'Parsed'
            CmsSha256 = Get-AmdByteArraySha256 -Bytes $Bytes
            ContentType = [pscustomobject][ordered]@{ Oid=$contentTypeOid; FriendlyName=[string]$cms.ContentInfo.ContentType.FriendlyName }
            ContentSha256 = Get-AmdByteArraySha256 -Bytes $cms.ContentInfo.Content
            CmsLibrarySignatureCheck = [pscustomobject][ordered]@{ Status=$cryptographicStatus; Error=$cryptographicError; Semantics='Diagnostic .NET SignedCms verification only; not a Windows trust-policy decision.' }
            SpcIndirectDataDigest = $spcDigest
            PeAuthenticodeDigest = $peDigest
            PeDigestMatchesSignedDigest = $digestMatches
            Signers = @($signers.ToArray())
            NestedSignatures = @($nested.ToArray())
            TimestampTokens = @($timestamps.ToArray())
            Error = $null
        }
    }
    catch {
        return [pscustomobject][ordered]@{
            EnvelopeId = $EnvelopeId
            Role = $Role
            Status = 'ParseFailed'
            CmsSha256 = Get-AmdByteArraySha256 -Bytes $Bytes
            Error = $_.Exception.Message
        }
    }
}

function Test-AmdPortableExecutableFile {
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)][string]$Path)

    try {
        $stream = [System.IO.File]::Open($Path, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite)
        try {
            if ($stream.Length -lt 2) { return $false }
            return ($stream.ReadByte() -eq 0x4d -and $stream.ReadByte() -eq 0x5a)
        }
        finally { $stream.Dispose() }
    }
    catch { return $false }
}

function Get-AmdSignatureArtifactKind {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string[]]$ObservedFileNames,
        [Parameter(Mandatory = $true)][bool]$IsPortableExecutable
    )

    foreach ($name in $ObservedFileNames) {
        if ($name -match '(?i)\.cat\d*$') { return 'Catalog' }
    }
    foreach ($name in $ObservedFileNames) {
        if ($name -match '(?i)\.sys\d*$') { return 'KernelBinary' }
    }
    foreach ($name in $ObservedFileNames) {
        if ($name -match '(?i)\.dll\d*$') { return 'Library' }
    }
    foreach ($name in $ObservedFileNames) {
        if ($name -match '(?i)\.exe\d*$') { return 'Executable' }
    }
    foreach ($name in $ObservedFileNames) {
        if ($name -match '(?i)\.(p7b|p7s|p7x)\d*$') { return 'CmsSignedData' }
        if ($name -match '(?i)\.(cer|crt|der)\d*$') { return 'CertificateFile' }
    }
    if ($IsPortableExecutable) { return 'PortableExecutable' }
    return 'Other'
}

function Test-AmdStaticSignatureCandidateFile {
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)][System.IO.FileInfo]$File)

    $name = $File.Name
    if ($name -match '(?i)\.(cat|p7b|p7s|p7x|cer|crt|der)\d*$') { return $true }
    return (Test-AmdPortableExecutableFile -Path $File.FullName)
}

function Get-AmdStaticFileSignatureEvidence {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string[]]$Occurrences,
        [Parameter(Mandatory = $true)][hashtable]$CertificateStore
    )

    $file = Get-Item -LiteralPath $Path -ErrorAction Stop
    $extension = $file.Extension.ToLowerInvariant()
    $observedFileNames = @(
        $Occurrences | ForEach-Object {
            $parts = @(([string]$_) -split '[\\/]')
            if ($parts.Count -gt 0) { [string]$parts[$parts.Count - 1] }
        } | Where-Object { $_ } | Sort-Object -Unique
    )
    if ($observedFileNames.Count -eq 0) { $observedFileNames = @($file.Name) }
    $isPortableExecutable = Test-AmdPortableExecutableFile -Path $file.FullName
    $fileType = Get-AmdSignatureArtifactKind -ObservedFileNames $observedFileNames -IsPortableExecutable $isPortableExecutable
    $sha256 = Get-AmdSha256 -Path $file.FullName
    # SHA-1 is captured only as legacy catalog/signature correlation evidence, never as a security decision hash.
    # psa-disable-next-line PSA5003
    $sha1 = ([string](Get-FileHash -LiteralPath $file.FullName -Algorithm SHA1 -ErrorAction Stop).Hash).ToLowerInvariant()
    $envelopes = New-Object System.Collections.Generic.List[object]
    $peCertificateEntries = New-Object System.Collections.Generic.List[object]
    $peStatus = $null

    if ($fileType -in @('Catalog','CmsSignedData')) {
        $bytes = [System.IO.File]::ReadAllBytes($file.FullName)
        $role = if ($fileType -eq 'Catalog') { 'CatalogSignature' } else { 'StandaloneCmsSignedData' }
        $envelopes.Add((Get-AmdSignedCmsEvidence -Bytes $bytes -CertificateStore $CertificateStore -EnvelopeId ('file:{0}/cms/0' -f $sha256) -Role $role))
        $peStatus = 'NotApplicable'
    }
    elseif ($fileType -eq 'CertificateFile') {
        $peStatus = 'NotApplicable'
        try {
            $certificate = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2 -ArgumentList @(,$([System.IO.File]::ReadAllBytes($file.FullName)))
            $null = Add-AmdCertificateEvidence -Certificate $certificate -CertificateStore $CertificateStore
        }
        catch {
            $peStatus = 'CertificateParseFailed'
        }
    }
    elseif ($isPortableExecutable) {
        $certificateTable = Get-AmdPeCertificateEntries -Path $file.FullName
        $peStatus = $certificateTable.Status
        foreach ($entry in @($certificateTable.Entries)) {
            $peCertificateEntries.Add([pscustomobject][ordered]@{
                Index = $entry.Index
                Offset = $entry.Offset
                Length = $entry.Length
                Revision = $entry.Revision
                CertificateType = $entry.CertificateType
                PayloadSha256 = $entry.PayloadSha256
            })
            if ([string]$entry.CertificateType -eq '0x0002') {
                $envelopes.Add((Get-AmdSignedCmsEvidence -Bytes $entry.Payload -CertificateStore $CertificateStore -EnvelopeId ('file:{0}/pe/{1}' -f $sha256,$entry.Index) -Role 'PrimaryAuthenticode' -PePath $file.FullName))
            }
        }
    }
    else {
        $peStatus = 'NotApplicable'
    }

    $signed = (@($envelopes.ToArray() | Where-Object { $_.Status -eq 'Parsed' }).Count -gt 0)
    return [pscustomobject][ordered]@{
        FileId = 'sha256:' + $sha256
        FileName = $file.Name
        ObservedFileNames = @($observedFileNames)
        FileType = $fileType
        DetectedFormat = if ($fileType -eq 'Catalog') { 'Catalog' } elseif ($fileType -eq 'CmsSignedData') { 'CMS' } elseif ($fileType -eq 'CertificateFile') { 'X509Certificate' } elseif ($isPortableExecutable) { 'PE' } else { 'Other' }
        Extension = $extension
        Size = [int64]$file.Length
        Sha256 = $sha256
        Sha1 = $sha1
        Occurrences = @($Occurrences | Sort-Object -Unique)
        EmbeddedSignatureState = if ($fileType -eq 'Catalog') { 'CatalogSignedData' } elseif ($fileType -eq 'CmsSignedData') { 'CmsSignedData' } elseif ($fileType -eq 'CertificateFile') { 'CertificateArtifact' } elseif ($signed) { 'Present' } elseif ($peStatus -eq 'NoCertificateTable') { 'Absent' } else { 'Unknown' }
        PeCertificateTableStatus = $peStatus
        PeCertificateEntries = @($peCertificateEntries.ToArray())
        Envelopes = @($envelopes.ToArray())
    }
}


function Get-AmdWindowsAuthenticodeObservation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$Path
    )

    $platform = Get-AmdPlatformInfo
    if ($platform.PlatformFamily -ne 'Windows') {
        return [pscustomobject][ordered]@{ Status='NotApplicableOnPlatform'; SignatureStatus=$null; StatusMessage=$null; SignatureType=$null; SignerCertificate=$null; TimeStamperCertificate=$null }
    }

    try {
        $signature = Get-AuthenticodeSignature -LiteralPath $Path -ErrorAction Stop
        $signatureType = $null
        if ($null -ne $signature.PSObject.Properties['SignatureType']) { $signatureType = [string]$signature.SignatureType }
        $signer = $null
        if ($signature.SignerCertificate) {
            $signer = [pscustomobject][ordered]@{
                DerSha256 = Get-AmdByteArraySha256 -Bytes $signature.SignerCertificate.RawData
                ThumbprintSha1 = ([string]$signature.SignerCertificate.Thumbprint).ToLowerInvariant()
                Subject = [string]$signature.SignerCertificate.Subject
                Issuer = [string]$signature.SignerCertificate.Issuer
            }
        }
        $timestamp = $null
        if ($signature.TimeStamperCertificate) {
            $timestamp = [pscustomobject][ordered]@{
                DerSha256 = Get-AmdByteArraySha256 -Bytes $signature.TimeStamperCertificate.RawData
                ThumbprintSha1 = ([string]$signature.TimeStamperCertificate.Thumbprint).ToLowerInvariant()
                Subject = [string]$signature.TimeStamperCertificate.Subject
                Issuer = [string]$signature.TimeStamperCertificate.Issuer
            }
        }
        return [pscustomobject][ordered]@{
            Status = 'Observed'
            SignatureStatus = [string]$signature.Status
            StatusMessage = [string]$signature.StatusMessage
            SignatureType = $signatureType
            SignerCertificate = $signer
            TimeStamperCertificate = $timestamp
        }
    }
    catch {
        return [pscustomobject][ordered]@{ Status='QueryFailed'; SignatureStatus=$null; StatusMessage=$null; SignatureType=$null; SignerCertificate=$null; TimeStamperCertificate=$null; Error=$_.Exception.Message }
    }
}

function Initialize-AmdWindowsCatalogNativeType {
    [CmdletBinding()]
    param()

    $platform = Get-AmdPlatformInfo
    if ($platform.PlatformFamily -ne 'Windows') { return $false }
    $existingType = 'AmdResearchCatalogNativeV2' -as [type]
    if ($existingType) {
        return ($null -ne $existingType.GetMethod('CalculateCatalogHashes',[System.Reflection.BindingFlags]'Public,Static') -and
                $null -ne $existingType.GetMethod('Enumerate',[System.Reflection.BindingFlags]'Public,Static'))
    }

    $source = @'
using System;
using System.Collections.Generic;
using System.IO;
using System.Runtime.InteropServices;

public static class AmdResearchCatalogNativeV2
{
    [StructLayout(LayoutKind.Sequential)]
    private struct CRYPT_ATTR_BLOB
    {
        public uint cbData;
        public IntPtr pbData;
    }

    [StructLayout(LayoutKind.Sequential)]
    private struct CRYPTCATMEMBER
    {
        public uint cbStruct;
        public IntPtr pwszReferenceTag;
        public IntPtr pwszFileName;
        public Guid gSubjectType;
        public uint fdwMemberFlags;
        public IntPtr pIndirectData;
        public uint dwCertVersion;
        public uint dwReserved;
        public IntPtr hReserved;
        public CRYPT_ATTR_BLOB sEncodedIndirectData;
        public CRYPT_ATTR_BLOB sEncodedMemberInfo;
    }

    [StructLayout(LayoutKind.Sequential)]
    private struct CRYPTCATATTRIBUTE
    {
        public uint cbStruct;
        public IntPtr pwszReferenceTag;
        public uint dwAttrTypeAndAction;
        public uint cbValue;
        public IntPtr pbValue;
        public uint dwReserved;
    }

    public sealed class AttributeRecord
    {
        public string ReferenceTag;
        public uint TypeAndAction;
        public byte[] Value;
    }

    public sealed class MemberRecord
    {
        public string ReferenceTag;
        public string FileName;
        public Guid SubjectType;
        public uint MemberFlags;
        public uint CertVersion;
        public byte[] EncodedIndirectData;
        public byte[] EncodedMemberInfo;
        public List<AttributeRecord> Attributes = new List<AttributeRecord>();
    }

    public sealed class CatalogRecord
    {
        public bool Opened;
        public uint PublicVersion;
        public int Win32Error;
        public List<AttributeRecord> CatalogAttributes = new List<AttributeRecord>();
        public List<MemberRecord> Members = new List<MemberRecord>();
    }

    public sealed class CatalogHashRecord
    {
        public string Status;
        public string Sha1;
        public string Sha256;
        public int Sha1Win32Error;
        public int Sha256Win32Error;
    }

    [DllImport("wintrust.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    private static extern IntPtr CryptCATOpen(string pwszFileName, uint fdwOpenFlags, IntPtr hProv, uint dwPublicVersion, uint dwEncodingType);

    [DllImport("wintrust.dll", SetLastError = true)]
    [return: MarshalAs(UnmanagedType.Bool)]
    private static extern bool CryptCATClose(IntPtr hCatalog);

    [DllImport("wintrust.dll", SetLastError = true)]
    private static extern IntPtr CryptCATEnumerateMember(IntPtr hCatalog, IntPtr pPrevMember);

    [DllImport("wintrust.dll", SetLastError = true)]
    private static extern IntPtr CryptCATEnumerateAttr(IntPtr hCatalog, IntPtr pCatMember, IntPtr pPrevAttr);

    [DllImport("wintrust.dll", SetLastError = true)]
    private static extern IntPtr CryptCATEnumerateCatAttr(IntPtr hCatalog, IntPtr pPrevAttr);

    [DllImport("wintrust.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    [return: MarshalAs(UnmanagedType.Bool)]
    private static extern bool CryptCATAdminAcquireContext2(out IntPtr phCatAdmin, IntPtr pgSubsystem, string pwszHashAlgorithm, IntPtr pStrongHashPolicy, uint dwFlags);

    [DllImport("wintrust.dll", SetLastError = true)]
    [return: MarshalAs(UnmanagedType.Bool)]
    private static extern bool CryptCATAdminCalcHashFromFileHandle2(IntPtr hCatAdmin, IntPtr hFile, ref uint pcbHash, byte[] pbHash, uint dwFlags);

    [DllImport("wintrust.dll", SetLastError = true)]
    [return: MarshalAs(UnmanagedType.Bool)]
    private static extern bool CryptCATAdminReleaseContext(IntPtr hCatAdmin, uint dwFlags);

    private static byte[] CopyBytes(IntPtr pointer, uint length)
    {
        if (pointer == IntPtr.Zero || length == 0) return new byte[0];
        byte[] bytes = new byte[length];
        Marshal.Copy(pointer, bytes, 0, checked((int)length));
        return bytes;
    }

    private static AttributeRecord ReadAttribute(IntPtr pointer)
    {
        CRYPTCATATTRIBUTE value = (CRYPTCATATTRIBUTE)Marshal.PtrToStructure(pointer, typeof(CRYPTCATATTRIBUTE));
        return new AttributeRecord
        {
            ReferenceTag = value.pwszReferenceTag == IntPtr.Zero ? null : Marshal.PtrToStringUni(value.pwszReferenceTag),
            TypeAndAction = value.dwAttrTypeAndAction,
            Value = CopyBytes(value.pbValue, value.cbValue)
        };
    }

    private static string BytesToHex(byte[] bytes)
    {
        if (bytes == null || bytes.Length == 0) return null;
        return BitConverter.ToString(bytes).Replace("-", String.Empty);
    }

    private static string CalculateCatalogHash(string path, string algorithm, out int win32Error)
    {
        win32Error = 0;
        IntPtr admin = IntPtr.Zero;
        try
        {
            if (!CryptCATAdminAcquireContext2(out admin, IntPtr.Zero, algorithm, IntPtr.Zero, 0))
            {
                win32Error = Marshal.GetLastWin32Error();
                return null;
            }

            using (FileStream file = new FileStream(path, FileMode.Open, FileAccess.Read, FileShare.Read | FileShare.Delete))
            {
                IntPtr handle = file.SafeFileHandle.DangerousGetHandle();
                uint length = 0;
                bool first = CryptCATAdminCalcHashFromFileHandle2(admin, handle, ref length, null, 0);
                if (!first && length == 0)
                {
                    win32Error = Marshal.GetLastWin32Error();
                    return null;
                }
                byte[] buffer = new byte[length];
                if (!CryptCATAdminCalcHashFromFileHandle2(admin, handle, ref length, buffer, 0))
                {
                    win32Error = Marshal.GetLastWin32Error();
                    return null;
                }
                if (length != buffer.Length)
                {
                    Array.Resize(ref buffer, checked((int)length));
                }
                return BytesToHex(buffer);
            }
        }
        catch
        {
            win32Error = Marshal.GetLastWin32Error();
            return null;
        }
        finally
        {
            if (admin != IntPtr.Zero) CryptCATAdminReleaseContext(admin, 0);
        }
    }

    public static CatalogHashRecord CalculateCatalogHashes(string path)
    {
        CatalogHashRecord result = new CatalogHashRecord();
        result.Sha256 = CalculateCatalogHash(path, "SHA256", out result.Sha256Win32Error);
        result.Sha1 = CalculateCatalogHash(path, "SHA1", out result.Sha1Win32Error);
        result.Status = (!String.IsNullOrEmpty(result.Sha256) || !String.IsNullOrEmpty(result.Sha1)) ? "Calculated" : "Failed";
        return result;
    }

    public static CatalogRecord Enumerate(string path)
    {
        CatalogRecord result = new CatalogRecord();
        IntPtr invalidHandle = new IntPtr(-1);
        IntPtr catalog = invalidHandle;
        uint[] versions = new uint[] { 0x200, 0x100 };
        foreach (uint version in versions)
        {
            catalog = CryptCATOpen(path, 0x00000004, IntPtr.Zero, version, 0);
            if (catalog != IntPtr.Zero && catalog != invalidHandle)
            {
                result.Opened = true;
                result.PublicVersion = version;
                break;
            }
            result.Win32Error = Marshal.GetLastWin32Error();
        }
        if (!result.Opened) return result;

        try
        {
            IntPtr previousCatalogAttribute = IntPtr.Zero;
            while (true)
            {
                IntPtr current = CryptCATEnumerateCatAttr(catalog, previousCatalogAttribute);
                if (current == IntPtr.Zero) break;
                result.CatalogAttributes.Add(ReadAttribute(current));
                previousCatalogAttribute = current;
            }

            IntPtr previousMember = IntPtr.Zero;
            while (true)
            {
                IntPtr memberPointer = CryptCATEnumerateMember(catalog, previousMember);
                if (memberPointer == IntPtr.Zero) break;
                CRYPTCATMEMBER member = (CRYPTCATMEMBER)Marshal.PtrToStructure(memberPointer, typeof(CRYPTCATMEMBER));
                MemberRecord record = new MemberRecord
                {
                    ReferenceTag = member.pwszReferenceTag == IntPtr.Zero ? null : Marshal.PtrToStringUni(member.pwszReferenceTag),
                    FileName = member.pwszFileName == IntPtr.Zero ? null : Marshal.PtrToStringUni(member.pwszFileName),
                    SubjectType = member.gSubjectType,
                    MemberFlags = member.fdwMemberFlags,
                    CertVersion = member.dwCertVersion,
                    EncodedIndirectData = CopyBytes(member.sEncodedIndirectData.pbData, member.sEncodedIndirectData.cbData),
                    EncodedMemberInfo = CopyBytes(member.sEncodedMemberInfo.pbData, member.sEncodedMemberInfo.cbData)
                };

                IntPtr previousAttribute = IntPtr.Zero;
                while (true)
                {
                    IntPtr attributePointer = CryptCATEnumerateAttr(catalog, memberPointer, previousAttribute);
                    if (attributePointer == IntPtr.Zero) break;
                    record.Attributes.Add(ReadAttribute(attributePointer));
                    previousAttribute = attributePointer;
                }

                result.Members.Add(record);
                previousMember = memberPointer;
            }
        }
        finally
        {
            CryptCATClose(catalog);
        }
        return result;
    }
}
'@

    try {
        Add-Type -TypeDefinition $source -Language CSharp -ErrorAction Stop
        return $true
    }
    catch {
        Write-AmdWarn ('Windows catalog native API type initialization failed: {0}' -f $_.Exception.Message)
        return $false
    }
}

function ConvertTo-AmdCatalogAttributeEvidence {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]$Attribute
    )

    $bytes = [byte[]]@($Attribute.Value)
    return [pscustomobject][ordered]@{
        ReferenceTag = [string]$Attribute.ReferenceTag
        TypeAndAction = ('0x{0:x8}' -f [uint32]$Attribute.TypeAndAction)
        ValueLength = $bytes.Length
        ValueSha256 = if ($bytes.Length -gt 0) { Get-AmdByteArraySha256 -Bytes $bytes } else { $null }
    }
}

function Get-AmdWindowsCatalogHashEvidence {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$Path
    )

    $platform = Get-AmdPlatformInfo
    if ($platform.PlatformFamily -ne 'Windows') {
        return [pscustomobject][ordered]@{ Status='NotApplicableOnPlatform'; Sha1=$null; Sha256=$null; Sha1Win32Error=$null; Sha256Win32Error=$null }
    }
    if (-not (Initialize-AmdWindowsCatalogNativeType)) {
        return [pscustomobject][ordered]@{ Status='NativeApiUnavailable'; Sha1=$null; Sha256=$null; Sha1Win32Error=$null; Sha256Win32Error=$null }
    }
    try {
        $native = [AmdResearchCatalogNativeV2]::CalculateCatalogHashes($Path)
        return [pscustomobject][ordered]@{
            Status=[string]$native.Status
            Sha1=if([string]::IsNullOrWhiteSpace([string]$native.Sha1)){$null}else{([string]$native.Sha1).ToUpperInvariant()}
            Sha256=if([string]::IsNullOrWhiteSpace([string]$native.Sha256)){$null}else{([string]$native.Sha256).ToUpperInvariant()}
            Sha1Win32Error=[int]$native.Sha1Win32Error
            Sha256Win32Error=[int]$native.Sha256Win32Error
        }
    }
    catch {
        return [pscustomobject][ordered]@{ Status='CalculationFailed'; Sha1=$null; Sha256=$null; Sha1Win32Error=$null; Sha256Win32Error=$null; Error=$_.Exception.Message }
    }
}

function Get-AmdWindowsCatalogMemberEvidence {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$Path
    )

    $platform = Get-AmdPlatformInfo
    if ($platform.PlatformFamily -ne 'Windows') {
        return [pscustomobject][ordered]@{ Status='NotApplicableOnPlatform'; CatalogAttributes=@(); Members=@(); Error=$null }
    }
    if (-not (Initialize-AmdWindowsCatalogNativeType)) {
        return [pscustomobject][ordered]@{ Status='NativeApiUnavailable'; CatalogAttributes=@(); Members=@(); Error='WinTrust catalog enumeration API could not be initialized.' }
    }

    try {
        $native = [AmdResearchCatalogNativeV2]::Enumerate($Path)
        if (-not $native.Opened) {
            return [pscustomobject][ordered]@{ Status='OpenFailed'; PublicVersion=$null; Win32Error=$native.Win32Error; CatalogAttributes=@(); Members=@(); Error='CryptCATOpen failed.' }
        }

        $catalogAttributes = @($native.CatalogAttributes | ForEach-Object { ConvertTo-AmdCatalogAttributeEvidence -Attribute $_ })
        $members = New-Object System.Collections.Generic.List[object]
        foreach ($member in @($native.Members)) {
            $indirect = [byte[]]@($member.EncodedIndirectData)
            $memberInfo = [byte[]]@($member.EncodedMemberInfo)
            $members.Add([pscustomobject][ordered]@{
                ReferenceTag = [string]$member.ReferenceTag
                FileName = [string]$member.FileName
                SubjectType = [string]$member.SubjectType
                MemberFlags = ('0x{0:x8}' -f [uint32]$member.MemberFlags)
                CertVersion = [uint32]$member.CertVersion
                EncodedIndirectDataLength = $indirect.Length
                EncodedIndirectDataSha256 = if ($indirect.Length -gt 0) { Get-AmdByteArraySha256 -Bytes $indirect } else { $null }
                EncodedMemberInfoLength = $memberInfo.Length
                EncodedMemberInfoSha256 = if ($memberInfo.Length -gt 0) { Get-AmdByteArraySha256 -Bytes $memberInfo } else { $null }
                Attributes = @($member.Attributes | ForEach-Object { ConvertTo-AmdCatalogAttributeEvidence -Attribute $_ })
            })
        }
        return [pscustomobject][ordered]@{
            Status = 'Enumerated'
            PublicVersion = ('0x{0:x3}' -f [uint32]$native.PublicVersion)
            Win32Error = 0
            CatalogAttributeCount = $catalogAttributes.Count
            MemberCount = $members.Count
            CatalogAttributes = @($catalogAttributes)
            Members = @($members.ToArray())
            Error = $null
        }
    }
    catch {
        return [pscustomobject][ordered]@{ Status='EnumerationFailed'; PublicVersion=$null; Win32Error=$null; CatalogAttributes=@(); Members=@(); Error=$_.Exception.Message }
    }
}

function Get-AmdWindowsExecutionContext {
    [CmdletBinding()]
    param(
        [AllowNull()][object]$PlatformInfo,
        [AllowNull()][object]$OperatingSystem
    )

    try {
        $platform = if ($PSBoundParameters.ContainsKey('PlatformInfo')) { $PlatformInfo } else { Get-AmdPlatformInfo }
    }
    catch {
        return [pscustomobject][ordered]@{
            ExecutionClass = 'Unknown'
            ProductType = $null
            ProductRole = 'Unknown'
            Caption = $null
            Version = $null
            BuildNumber = $null
            EvidenceScopes = @('Static')
            CollectionStatus = 'Unavailable'
            CollectionSource = 'PlatformProbe'
        }
    }
    if ($platform.PlatformFamily -ne 'Windows') {
        return [pscustomobject][ordered]@{
            ExecutionClass = 'NonWindows'
            ProductType = $null
            ProductRole = 'NonWindows'
            Caption = $platform.OSDescription
            Version = $null
            BuildNumber = $null
            EvidenceScopes = @('Static')
            CollectionStatus = 'NotApplicable'
            CollectionSource = 'PlatformProbe'
        }
    }

    try {
        $os = if ($PSBoundParameters.ContainsKey('OperatingSystem')) {
            if ($null -eq $OperatingSystem) { throw 'The supplied operating-system fixture is null.' }
            $OperatingSystem
        }
        else {
            Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction Stop | Select-Object -First 1
        }
        $productType = [int]$os.ProductType
        $productRole = if ($productType -eq 1) { 'Client' } elseif ($productType -eq 2) { 'DomainController' } elseif ($productType -eq 3) { 'Server' } else { 'UnknownWindows' }
        $executionClass = if ($productType -eq 1) { 'WindowsClient' } elseif ($productType -in @(2,3)) { 'WindowsServer' } else { 'WindowsOther' }
        $scopes = New-Object System.Collections.Generic.List[string]
        $scopes.Add('Static')
        $scopes.Add('WindowsNative')
        if ($executionClass -eq 'WindowsServer') { $scopes.Add('TargetServerHost') }
        return [pscustomobject][ordered]@{
            ExecutionClass = $executionClass
            ProductType = $productType
            ProductRole = $productRole
            Caption = [string]$os.Caption
            Version = [string]$os.Version
            BuildNumber = [int]$os.BuildNumber
            EvidenceScopes = @($scopes.ToArray())
            CollectionStatus = 'Collected'
            CollectionSource = if ($PSBoundParameters.ContainsKey('OperatingSystem')) { 'ProvidedFixture' } else { 'Win32_OperatingSystem' }
        }
    }
    catch {
        return [pscustomobject][ordered]@{
            ExecutionClass = 'WindowsOther'
            ProductType = $null
            ProductRole = 'UnknownWindows'
            Caption = $platform.OSDescription
            Version = $null
            BuildNumber = $null
            EvidenceScopes = @('Static','WindowsNative')
            CollectionStatus = 'Unavailable'
            CollectionSource = if ($PSBoundParameters.ContainsKey('OperatingSystem')) { 'ProvidedFixture' } else { 'Win32_OperatingSystem' }
        }
    }
}

function Test-AmdWindowsExecutionContextSelfTest {
    [CmdletBinding()]
    param()

    $failures = New-Object 'System.Collections.Generic.List[string]'
    $windows = [pscustomobject]@{ PlatformFamily='Windows'; OSDescription='Windows fixture' }
    $cases = @(
        [pscustomobject]@{ Name='Client'; ProductType=1; ExpectedClass='WindowsClient'; ExpectedRole='Client'; ExpectedScopes=@('Static','WindowsNative') },
        [pscustomobject]@{ Name='DomainController'; ProductType=2; ExpectedClass='WindowsServer'; ExpectedRole='DomainController'; ExpectedScopes=@('Static','WindowsNative','TargetServerHost') },
        [pscustomobject]@{ Name='Server'; ProductType=3; ExpectedClass='WindowsServer'; ExpectedRole='Server'; ExpectedScopes=@('Static','WindowsNative','TargetServerHost') },
        [pscustomobject]@{ Name='OtherWindows'; ProductType=0; ExpectedClass='WindowsOther'; ExpectedRole='UnknownWindows'; ExpectedScopes=@('Static','WindowsNative') }
    )
    foreach ($case in $cases) {
        $os = [pscustomobject]@{ ProductType=$case.ProductType; Caption=('Windows {0}' -f $case.Name); Version='10.0.26100'; BuildNumber=26100 }
        $actual = Get-AmdWindowsExecutionContext -PlatformInfo $windows -OperatingSystem $os
        if ($actual.ExecutionClass -ne $case.ExpectedClass -or $actual.ProductRole -ne $case.ExpectedRole -or $actual.CollectionStatus -ne 'Collected' -or (@($actual.EvidenceScopes) -join '|') -ne (@($case.ExpectedScopes) -join '|')) {
            $failures.Add(('{0}: execution-context classification mismatch.' -f $case.Name)) | Out-Null
        }
    }
    $nonWindows = Get-AmdWindowsExecutionContext -PlatformInfo ([pscustomobject]@{ PlatformFamily='Linux'; OSDescription='Linux fixture' })
    if ($nonWindows.ExecutionClass -ne 'NonWindows' -or $nonWindows.CollectionStatus -ne 'NotApplicable' -or (@($nonWindows.EvidenceScopes) -join '|') -ne 'Static') {
        $failures.Add('NonWindows: execution-context classification mismatch.') | Out-Null
    }
    $unavailable = Get-AmdWindowsExecutionContext -PlatformInfo $windows -OperatingSystem $null
    if ($unavailable.ExecutionClass -ne 'WindowsOther' -or $unavailable.CollectionStatus -ne 'Unavailable' -or $unavailable.CollectionSource -ne 'ProvidedFixture') {
        $failures.Add('Unavailable Windows inventory: typed fallback mismatch.') | Out-Null
    }
    return [pscustomobject][ordered]@{
        Status = if ($failures.Count -eq 0) { 'Pass' } else { 'Fail' }
        TestCount = 6
        Failures = @($failures.ToArray())
    }
}

function Get-AmdPortableWindowsKitPathIdentity {
    [CmdletBinding()]
    param(
        [AllowNull()][string]$Path
    )

    if ([string]::IsNullOrWhiteSpace($Path)) {
        return [pscustomobject][ordered]@{ PathClass='Unknown'; KitVersion=$null; Architecture=$null; PortablePath=$null }
    }

    $normalized = $Path -replace '/', '\\'
    $m = [regex]::Match($normalized, '(?i)\\Windows Kits\\(?<Kit>[^\\]+)\\bin\\(?:(?<Version>[^\\]+)\\)?(?<Arch>x86|x64|arm64)\\(?<Leaf>[^\\]+)$')
    if ($m.Success) {
        $kit = [string]$m.Groups['Kit'].Value
        $version = if ($m.Groups['Version'].Success) { [string]$m.Groups['Version'].Value } else { $null }
        $arch = [string]$m.Groups['Arch'].Value.ToLowerInvariant()
        $leaf = [string]$m.Groups['Leaf'].Value
        $portable = if ($version) {
            'WindowsKits/{0}/bin/{1}/{2}/{3}' -f $kit,$version,$arch,$leaf
        }
        else {
            'WindowsKits/{0}/bin/{1}/{2}' -f $kit,$arch,$leaf
        }
        return [pscustomobject][ordered]@{
            PathClass = if ($version) { 'WindowsKitVersionedBin' } else { 'WindowsKitBin' }
            KitVersion = $version
            Architecture = $arch
            PortablePath = $portable
        }
    }

    return [pscustomobject][ordered]@{
        PathClass='OtherResolvedExecutable'
        KitVersion=$null
        Architecture=$null
        PortablePath=('external-tool/{0}' -f [System.IO.Path]::GetFileName($Path))
    }
}

function Get-AmdPeMachineArchitecture {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][string]$Path
    )

    try {
        $stream = [System.IO.File]::Open($Path,[System.IO.FileMode]::Open,[System.IO.FileAccess]::Read,[System.IO.FileShare]::ReadWrite)
        try {
            if ($stream.Length -lt 64) { return 'Unknown' }
            $reader = New-Object System.IO.BinaryReader($stream)
            if ($reader.ReadUInt16() -ne 0x5A4D) { return 'NotPE' }
            $stream.Position = 0x3c
            $peOffset = $reader.ReadInt32()
            if ($peOffset -lt 0 -or ($peOffset + 6) -gt $stream.Length) { return 'Unknown' }
            $stream.Position = $peOffset
            if ($reader.ReadUInt32() -ne 0x00004550) { return 'Unknown' }
            $machine = $reader.ReadUInt16()
            switch ($machine) {
                0x014c { return 'x86' }
                0x8664 { return 'x64' }
                0xAA64 { return 'arm64' }
                default { return ('Machine0x{0:X4}' -f $machine) }
            }
        }
        finally { $stream.Dispose() }
    }
    catch { return 'Unknown' }
}

function Get-AmdWindowsSdkToolInfo {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$ToolName
    )

    $platform = Get-AmdPlatformInfo
    if ($platform.PlatformFamily -ne 'Windows') {
        return [pscustomobject][ordered]@{
            Status='NotApplicableOnPlatform';ToolName=$ToolName;Path=$null;Version=$null;FileVersion=$null;ProductVersion=$null
            Sha256=$null;SizeBytes=$null;Architecture=$null;PathClass=$null;KitVersion=$null;PortablePath=$null;CandidateCount=0;Candidates=@()
        }
    }

    $candidateRecords = New-Object 'System.Collections.Generic.List[object]'
    $seen = @{}
    foreach ($command in @(Get-Command -Name $ToolName -All -ErrorAction SilentlyContinue)) {
        $candidatePath = if ($command.Source) { [string]$command.Source } elseif ($command.Path) { [string]$command.Path } else { $null }
        if ([string]::IsNullOrWhiteSpace($candidatePath) -or -not (Test-Path -LiteralPath $candidatePath -PathType Leaf)) { continue }
        $key = $candidatePath.ToLowerInvariant()
        if ($seen.ContainsKey($key)) { continue }
        $seen[$key] = $true
        $candidateRecords.Add([pscustomobject][ordered]@{Path=$candidatePath;Discovery='GetCommand'})
    }

    $roots = New-Object System.Collections.Generic.List[string]
    $pf86 = [Environment]::GetEnvironmentVariable('ProgramFiles(x86)')
    if ($pf86) { $roots.Add((Join-Path $pf86 'Windows Kits\10\bin')) }
    if ($env:ProgramFiles) { $roots.Add((Join-Path $env:ProgramFiles 'Windows Kits\10\bin')) }
    foreach ($rootPath in @($roots.ToArray() | Select-Object -Unique)) {
        if (-not (Test-Path -LiteralPath $rootPath -PathType Container)) { continue }
        foreach ($file in @(Get-ChildItem -LiteralPath $rootPath -Filter $ToolName -File -Recurse -ErrorAction SilentlyContinue | Where-Object { $_.FullName -match '(?i)[\\/](?:x64|x86|arm64)[\\/]' } | Sort-Object @{Expression={ if ($_.FullName -match '(?i)[\\/]x64[\\/]') { 0 } elseif ($_.FullName -match '(?i)[\\/]arm64[\\/]') { 1 } else { 2 } }}, @{Expression={$_.FullName};Descending=$true})) {
            $key = $file.FullName.ToLowerInvariant()
            if ($seen.ContainsKey($key)) { continue }
            $seen[$key] = $true
            $candidateRecords.Add([pscustomobject][ordered]@{Path=$file.FullName;Discovery='WindowsKitsSearch'})
        }
    }

    if ($candidateRecords.Count -eq 0) {
        return [pscustomobject][ordered]@{
            Status='NotFound';ToolName=$ToolName;Path=$null;Version=$null;FileVersion=$null;ProductVersion=$null
            Sha256=$null;SizeBytes=$null;Architecture=$null;PathClass=$null;KitVersion=$null;PortablePath=$null;CandidateCount=0;Candidates=@()
        }
    }

    # Preserve PATH/Get-Command precedence. If it does not resolve a tool, the Windows Kits search is sorted newest-first.
    $selected = $candidateRecords[0]
    $path = [string]$selected.Path
    $item = Get-Item -LiteralPath $path
    $identity = Get-AmdPortableWindowsKitPathIdentity -Path $path
    $fileVersion = $null; $productVersion = $null
    try { $fileVersion = [string]$item.VersionInfo.FileVersion } catch { }
    try { $productVersion = [string]$item.VersionInfo.ProductVersion } catch { }

    $publicCandidates = New-Object 'System.Collections.Generic.List[object]'
    foreach ($candidate in @($candidateRecords.ToArray())) {
        $candidateIdentity = Get-AmdPortableWindowsKitPathIdentity -Path ([string]$candidate.Path)
        $candidateItem = Get-Item -LiteralPath ([string]$candidate.Path)
        $candidateVersion = $null
        try { $candidateVersion = [string]$candidateItem.VersionInfo.FileVersion } catch { }
        $publicCandidates.Add([pscustomobject][ordered]@{
            PortablePath=$candidateIdentity.PortablePath
            PathClass=$candidateIdentity.PathClass
            KitVersion=$candidateIdentity.KitVersion
            Discovery=[string]$candidate.Discovery
            FileVersion=$candidateVersion
        })
    }

    return [pscustomobject][ordered]@{
        Status='Available'
        ToolName=$ToolName
        Path=$path
        Version=$fileVersion
        FileVersion=$fileVersion
        ProductVersion=$productVersion
        Sha256=Get-AmdSha256 -Path $path
        SizeBytes=[int64]$item.Length
        Architecture=Get-AmdPeMachineArchitecture -Path $path
        PathClass=$identity.PathClass
        KitVersion=$identity.KitVersion
        PortablePath=$identity.PortablePath
        CandidateCount=$candidateRecords.Count
        Candidates=@($publicCandidates.ToArray())
    }
}

function Initialize-AmdWindowsLocalizationNativeTypes {
    [CmdletBinding()]
    param()

    try {
        $existingType = 'AmdResearchWindowsLocalizationNativeV1' -as [type]
        if ($existingType) {
            $required = @('UserDefaultLocaleName','SystemDefaultLocaleName','GetUserDefaultUILanguage','GetSystemDefaultUILanguage','GetConsoleCP','GetConsoleOutputCP')
            return (@($required | Where-Object { $null -eq $existingType.GetMethod($_,[System.Reflection.BindingFlags]'Public,Static') }).Count -eq 0)
        }
        if (-not $existingType) {
            Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
using System.Text;

public static class AmdResearchWindowsLocalizationNativeV1
{
    [DllImport("kernel32.dll")]
    public static extern uint GetConsoleCP();

    [DllImport("kernel32.dll")]
    public static extern uint GetConsoleOutputCP();

    [DllImport("kernel32.dll", CharSet = CharSet.Unicode)]
    private static extern int GetUserDefaultLocaleName(StringBuilder lpLocaleName, int cchLocaleName);

    [DllImport("kernel32.dll", CharSet = CharSet.Unicode)]
    private static extern int GetSystemDefaultLocaleName(StringBuilder lpLocaleName, int cchLocaleName);

    [DllImport("kernel32.dll")]
    public static extern ushort GetUserDefaultUILanguage();

    [DllImport("kernel32.dll")]
    public static extern ushort GetSystemDefaultUILanguage();

    public static string UserDefaultLocaleName()
    {
        var sb = new StringBuilder(85);
        return GetUserDefaultLocaleName(sb, sb.Capacity) > 0 ? sb.ToString() : null;
    }

    public static string SystemDefaultLocaleName()
    {
        var sb = new StringBuilder(85);
        return GetSystemDefaultLocaleName(sb, sb.Capacity) > 0 ? sb.ToString() : null;
    }
}
'@ -ErrorAction Stop
        }
        return $true
    }
    catch {
        return $false
    }
}

function Get-AmdCultureNameFromLcid {
    [CmdletBinding()]
    param([AllowNull()][Nullable[int]]$Lcid)

    if ($null -eq $Lcid) { return $null }
    try { return [System.Globalization.CultureInfo]::GetCultureInfo([int]$Lcid).Name }
    catch { return $null }
}

function Get-AmdNativeToolLocalizationContext {
    [CmdletBinding()]
    param()

    $nativeExecutionContext = Get-AmdWindowsExecutionContext
    $observedPsCulture = $null; $observedPsUiCulture = $null
    try { $observedPsCulture = Get-Culture } catch { }
    try { $observedPsUiCulture = Get-UICulture } catch { }

    $consoleInputEncoding = $null; $consoleOutputEncoding = $null
    try { $consoleInputEncoding = [Console]::InputEncoding } catch { }
    try { $consoleOutputEncoding = [Console]::OutputEncoding } catch { }

    $nativeApiStatus = if ($nativeExecutionContext.ExecutionClass -in @('WindowsClient','WindowsServer','WindowsOther')) { 'Unavailable' } else { 'NotApplicableOnPlatform' }
    $userDefaultLocale = $null; $systemDefaultLocale = $null
    $userUiLcid = $null; $systemUiLcid = $null
    $consoleInputCodePage = $null; $consoleOutputCodePage = $null

    if ($nativeExecutionContext.ExecutionClass -in @('WindowsClient','WindowsServer','WindowsOther')) {
        if (Initialize-AmdWindowsLocalizationNativeTypes) {
            try {
                $nativeApiStatus = 'Observed'
                $userDefaultLocale = [AmdResearchWindowsLocalizationNativeV1]::UserDefaultLocaleName()
                $systemDefaultLocale = [AmdResearchWindowsLocalizationNativeV1]::SystemDefaultLocaleName()
                $userUiLcid = [int][AmdResearchWindowsLocalizationNativeV1]::GetUserDefaultUILanguage()
                $systemUiLcid = [int][AmdResearchWindowsLocalizationNativeV1]::GetSystemDefaultUILanguage()
                $consoleInputCodePage = [int][AmdResearchWindowsLocalizationNativeV1]::GetConsoleCP()
                $consoleOutputCodePage = [int][AmdResearchWindowsLocalizationNativeV1]::GetConsoleOutputCP()
            }
            catch {
                $nativeApiStatus = 'QueryFailed'
            }
        }
    }

    return [pscustomobject][ordered]@{
        SchemaVersion='amd-native-tool-localization-context/1.0'
        ClassificationPolicy='LocaleNeutral'
        NaturalLanguageOutputRequiredForCorrectness=$false
        NativeToolOutputLanguageForced=$false
        ExecutionClass=$nativeExecutionContext.ExecutionClass
        PowerShell=[pscustomobject][ordered]@{
            Culture=if($observedPsCulture){[string]$observedPsCulture.Name}else{$null}
            UICulture=if($observedPsUiCulture){[string]$observedPsUiCulture.Name}else{$null}
            CurrentCulture=[string][System.Globalization.CultureInfo]::CurrentCulture.Name
            CurrentUICulture=[string][System.Globalization.CultureInfo]::CurrentUICulture.Name
            InstalledUICulture=[string][System.Globalization.CultureInfo]::InstalledUICulture.Name
        }
        Windows=[pscustomobject][ordered]@{
            NativeApiStatus=$nativeApiStatus
            UserDefaultLocale=$userDefaultLocale
            SystemDefaultLocale=$systemDefaultLocale
            UserDefaultUILanguageLcid=$userUiLcid
            UserDefaultUILanguage=Get-AmdCultureNameFromLcid -Lcid $userUiLcid
            SystemDefaultUILanguageLcid=$systemUiLcid
            SystemDefaultUILanguage=Get-AmdCultureNameFromLcid -Lcid $systemUiLcid
        }
        Console=[pscustomobject][ordered]@{
            InputCodePage=$consoleInputCodePage
            OutputCodePage=$consoleOutputCodePage
            InputEncoding=if($consoleInputEncoding){[string]$consoleInputEncoding.WebName}else{$null}
            OutputEncoding=if($consoleOutputEncoding){[string]$consoleOutputEncoding.WebName}else{$null}
        }
        PosixLocaleEnvironmentHints=[pscustomobject][ordered]@{
            LANG=[Environment]::GetEnvironmentVariable('LANG')
            LC_ALL=[Environment]::GetEnvironmentVariable('LC_ALL')
            LC_MESSAGES=[Environment]::GetEnvironmentVariable('LC_MESSAGES')
            Contract='InformationalOnlyOnWindowsNativeTools'
        }
    }
}

function Get-AmdLocaleNeutralNativeResultClass {
    [CmdletBinding()]
    param([Parameter(Mandatory=$true)]$ProcessResult)

    if ([string]$ProcessResult.Status -eq 'ExecutionFailed' -or -not [string]::IsNullOrWhiteSpace([string]$ProcessResult.Error)) {
        return 'ToolExecutionFailed'
    }
    if ([int]$ProcessResult.ExitCode -eq 0) { return 'Succeeded' }
    return 'NonZeroExit'
}

function Test-AmdNativeInteropTypeContractSelfTest {
    [CmdletBinding()]
    param()

    $platform = Get-AmdPlatformInfo
    if ($platform.PlatformFamily -ne 'Windows') {
        return [pscustomobject][ordered]@{
            Status='Pass';Applicable=$false
            CatalogNativeType='NotApplicable';CatalogRequiredMethods=@('CalculateCatalogHashes','Enumerate');CatalogMissingMethods=@()
            LocalizationNativeType='NotApplicable';LocalizationRequiredMethods=@('UserDefaultLocaleName','SystemDefaultLocaleName','GetUserDefaultUILanguage','GetSystemDefaultUILanguage','GetConsoleCP','GetConsoleOutputCP');LocalizationMissingMethods=@()
        }
    }

    $catalogReady = Initialize-AmdWindowsCatalogNativeType
    $localizationReady = Initialize-AmdWindowsLocalizationNativeTypes

    $catalogType = 'AmdResearchCatalogNativeV2' -as [type]
    $localizationType = 'AmdResearchWindowsLocalizationNativeV1' -as [type]

    $catalogRequired = @('CalculateCatalogHashes','Enumerate')
    $localizationRequired = @('UserDefaultLocaleName','SystemDefaultLocaleName','GetUserDefaultUILanguage','GetSystemDefaultUILanguage','GetConsoleCP','GetConsoleOutputCP')

    # IMPORTANT for Windows PowerShell 5.1:
    # Assignment from a statement expression (`$x = if (...) { ... }`) enumerates the
    # branch output. An empty branch therefore becomes $null and a one-item branch
    # becomes a scalar. Under StrictMode, direct `.Count` on either shape is unsafe.
    # Wrap the *entire* conditional expression in @() so the cardinality contract is
    # always 0/1/N as an array.
    $catalogMissing = @(
        if($catalogReady -and $catalogType){
            $catalogRequired | Where-Object { $null -eq $catalogType.GetMethod($_,[System.Reflection.BindingFlags]'Public,Static') }
        }
        else { $catalogRequired }
    )
    $localizationMissing = @(
        if($localizationReady -and $localizationType){
            $localizationRequired | Where-Object { $null -eq $localizationType.GetMethod($_,[System.Reflection.BindingFlags]'Public,Static') }
        }
        else { $localizationRequired }
    )
    $ok = (@($catalogMissing).Count -eq 0 -and @($localizationMissing).Count -eq 0)
    return [pscustomobject][ordered]@{
        Status=if($ok){'Pass'}else{'Fail'};Applicable=$true
        CatalogNativeType=if($catalogType){$catalogType.FullName}else{$null};CatalogRequiredMethods=$catalogRequired;CatalogMissingMethods=$catalogMissing
        LocalizationNativeType=if($localizationType){$localizationType.FullName}else{$null};LocalizationRequiredMethods=$localizationRequired;LocalizationMissingMethods=$localizationMissing
    }
}

function Test-AmdCollectionCardinalitySourceContract {
    [CmdletBinding()]
    param([Parameter(Mandatory=$true)][string]$Path)

    $issues = New-Object 'System.Collections.Generic.List[string]'
    try { $sourceText = [System.IO.File]::ReadAllText($Path) }
    catch {
        $issues.Add(('Cannot read source for collection-cardinality audit: {0}' -f $_.Exception.Message)) | Out-Null
        return [pscustomobject][ordered]@{Status='Fail';IssueCount=$issues.Count;Issues=@($issues.ToArray())}
    }

    # Detect the exact unsafe family seen first in Chipset 2.1.9 and again in NPU
    # 1.2.1: a variable assigned directly from an `if` statement expression and
    # later dereferenced with `.Count` in the same function. Keeping function
    # scope prevents unrelated reuse of a common variable name from becoming a
    # false positive.
    $analyzeSource = {
        param([Parameter(Mandatory=$true)][string]$Text)
        $found = New-Object 'System.Collections.Generic.List[string]'
        $assignmentMatches = [regex]::Matches($Text, '(?m)^\s*\$(?<name>[A-Za-z_][A-Za-z0-9_]*)\s*=\s*if\s*\(')
        foreach ($match in $assignmentMatches) {
            $name = [string]$match.Groups['name'].Value
            $nextFunction = [regex]::Match($Text.Substring($match.Index + $match.Length), '(?m)^function\s+')
            $auditLength = if($nextFunction.Success){$match.Length + $nextFunction.Index}else{$Text.Length - $match.Index}
            $functionRemainder = $Text.Substring($match.Index,$auditLength)
            if ([regex]::IsMatch($functionRemainder, ('\${0}\.Count\b' -f [regex]::Escape($name)))) {
                $found.Add(('Unsafe conditional collection cardinality pattern: ${0} is assigned directly from if(...) and later uses .Count. Wrap the entire conditional in @(...).' -f $name)) | Out-Null
            }
        }
        return $found.ToArray()
    }

    foreach($sourceIssue in @(& $analyzeSource $sourceText)) { $issues.Add([string]$sourceIssue) | Out-Null }

    # Deliberate negative and false-positive controls prove that the migrated
    # audit is active, catches the causal family and respects function scope.
    $nl = [Environment]::NewLine
    $unsafeFixture = 'function Test-Unsafe {'+$nl+'    $items = '+'if ($true) { "one" } else { @() }'+$nl+'    if ($items.Count -eq 1) { return }'+$nl+'}'
    $safeFixture = 'function Test-Safe {'+$nl+'    $items = @('+$nl+'        if ($true) { "one" } else { @() }'+$nl+'    )'+$nl+'    if ($items.Count -eq 1) { return }'+$nl+'}'
    $crossFunctionFixture = 'function Test-A {'+$nl+'    $items = '+'if ($true) { "one" } else { @() }'+$nl+'}'+$nl+'function Test-B {'+$nl+'    $items = @()'+$nl+'    if ($items.Count -eq 0) { return }'+$nl+'}'
    $unsafeResults = @(& $analyzeSource $unsafeFixture)
    $safeResults = @(& $analyzeSource $safeFixture)
    $crossFunctionResults = @(& $analyzeSource $crossFunctionFixture)
    if($unsafeResults.Count -ne 1){$issues.Add(('Collection-cardinality source audit negative control failed: expected 1 issue; actual={0}.' -f $unsafeResults.Count)) | Out-Null}
    if($safeResults.Count -ne 0){$issues.Add(('Collection-cardinality source audit safe control failed: expected 0 issues; actual={0}.' -f $safeResults.Count)) | Out-Null}
    if($crossFunctionResults.Count -ne 0){$issues.Add(('Collection-cardinality source audit function-scope control failed: expected 0 issues; actual={0}.' -f $crossFunctionResults.Count)) | Out-Null}

    return [pscustomobject][ordered]@{
        Status = if($issues.Count -eq 0){'Pass'}else{'Fail'}
        IssueCount = $issues.Count
        Issues = @($issues.ToArray())
        Contract = 'SameFunctionNoDirectIfAssignmentBeforeDotCountWithNegativeControl/3'
    }
}

function Test-AmdPowerShell51CollectionCardinalitySelfTest {
    [CmdletBinding()]
    param()

    # Reproduce the Windows PowerShell 5.1 shape that caused Chipset 2.1.9 and
    # NPU 1.2.1 Test runs to fail:
    # statement-expression assignment unwraps 0/1 item collections unless the
    # entire expression is protected with @(...).
    $zero = @(
        if ($true) { @() }
        else { 'unexpected' }
    )
    $one = @(
        if ($true) { 'one' }
        else { @() }
    )
    $many = @(
        if ($true) { 'one'; 'two' }
        else { @() }
    )

    # Also exercise the exact "missing static methods" pattern used by the
    # NativeInterop contract test. System.String supplies IsNullOrEmpty but not
    # the sentinel method, giving deterministic zero- and one-missing cases.
    $type = [string]
    $zeroMissing = @(
        @('IsNullOrEmpty') | Where-Object {
            $null -eq $type.GetMethod($_,[System.Reflection.BindingFlags]'Public,Static')
        }
    )
    $oneMissing = @(
        @('IsNullOrEmpty','__AmdMissingMethodSentinel__') | Where-Object {
            $null -eq $type.GetMethod($_,[System.Reflection.BindingFlags]'Public,Static')
        }
    )

    $ok = (
        @($zero).Count -eq 0 -and
        @($one).Count -eq 1 -and
        @($many).Count -eq 2 -and
        @($zeroMissing).Count -eq 0 -and
        @($oneMissing).Count -eq 1
    )

    return [pscustomobject][ordered]@{
        Status = if($ok){'Pass'}else{'Fail'}
        ZeroCount = @($zero).Count
        OneCount = @($one).Count
        ManyCount = @($many).Count
        ZeroMissingMethodCount = @($zeroMissing).Count
        OneMissingMethodCount = @($oneMissing).Count
        Contract = 'WrapEntireConditionalOrPipelineExpressionBeforeCardinality/1'
    }
}

function Test-AmdNativeToolLocalizationSelfTest {
    [CmdletBinding()]
    param()

    $localizedHelp = '使用法: verify /all /kp /o /pa /c /a 署名を検証します'
    $tokens = @(Get-AmdOptionObservationsFromText -Text $localizedHelp -Tokens @('/all','/kp','/o','/pa','/c','/a','/missing'))
    $emptyTokens = @(Get-AmdOptionObservationsFromText -Text $localizedHelp -Tokens @())
    $tokenPass = @($tokens | Where-Object { $_.Token -ne '/missing' -and $_.Observed }).Count -eq 6 -and @($tokens | Where-Object { $_.Token -eq '/missing' -and -not $_.Observed }).Count -eq 1 -and $emptyTokens.Count -eq 0

    $jpFailure = [pscustomobject]@{ Status='Fail'; ExitCode=1; Error=$null; Output=@('署名を検証できませんでした') }
    $enFailure = [pscustomobject]@{ Status='Fail'; ExitCode=1; Error=$null; Output=@('No signature found') }
    $success = [pscustomobject]@{ Status='Pass'; ExitCode=0; Error=$null; Output=@('任意のローカライズ済み出力') }
    $classificationPass = (
        (Get-AmdLocaleNeutralNativeResultClass -ProcessResult $jpFailure) -eq 'NonZeroExit' -and
        (Get-AmdLocaleNeutralNativeResultClass -ProcessResult $enFailure) -eq 'NonZeroExit' -and
        (Get-AmdLocaleNeutralNativeResultClass -ProcessResult $success) -eq 'Succeeded'
    )
    $emptyOutputHashPass = ((Get-AmdByteArraySha256 -Bytes $null) -eq 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855')

    return [pscustomobject][ordered]@{
        Status=if($tokenPass -and $classificationPass -and $emptyOutputHashPass){'Pass'}else{'Fail'}
        TokenParsingLocaleNeutral=[bool]$tokenPass
        EmptyTokenCollectionAccepted=[bool]($emptyTokens.Count -eq 0)
        EmptyNativeOutputSha256Accepted=[bool]$emptyOutputHashPass
        ResultClassificationLocaleNeutral=[bool]$classificationPass
        EnglishOutputRequired=$false
    }
}

function Invoke-AmdReadOnlyProcess {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$FilePath,
        [Parameter(Mandatory = $true)][AllowEmptyCollection()][string[]]$Arguments
    )

    $output = @()
    $exitCode = $null
    $errorText = $null
    # Windows PowerShell 5.1 turns native stderr into ErrorRecord objects. With the toolkit's
    # fail-closed ErrorActionPreference=Stop, expected negative verification output (for
    # example SignTool's "No signature found") would otherwise become a terminating error.
    # Keep native process exit status as evidence instead of treating stderr itself as a crash.
    $savedErrorActionPreference = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        $output = @(& $FilePath @Arguments 2>&1 | ForEach-Object { [string]$_ })
        $exitCode = $LASTEXITCODE
    }
    catch {
        $errorText = $_.Exception.Message
        $exitCode = -1
    }
    finally {
        $ErrorActionPreference = $savedErrorActionPreference
    }
    $joined = $output -join "`n"
    $bytes = if ([string]::IsNullOrEmpty($joined)) { [byte[]]@() } else { [System.Text.Encoding]::UTF8.GetBytes($joined) }
    return [pscustomobject][ordered]@{
        ExitCode = $exitCode
        Status = if ($exitCode -eq 0) { 'Pass' } elseif ($exitCode -eq -1) { 'ExecutionFailed' } else { 'Fail' }
        OutputSha256 = Get-AmdByteArraySha256 -Bytes $bytes
        OutputTextSha256 = Get-AmdByteArraySha256 -Bytes $bytes
        OutputLineCount = $output.Count
        Output = @($output)
        Error = $errorText
        ResultClass = Get-AmdLocaleNeutralNativeResultClass -ProcessResult ([pscustomobject]@{Status=if ($exitCode -eq 0) { 'Pass' } elseif ($exitCode -eq -1) { 'ExecutionFailed' } else { 'Fail' };ExitCode=$exitCode;Error=$errorText;Output=@($output)})
        OutputCaptureMode = 'PowerShellNativeMergedDecodedText'
        NaturalLanguageOutputUsedForClassification = $false
    }
}

function Get-AmdToolHelpProbe {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][string]$ToolPath,
        [Parameter(Mandatory=$true)][string[]]$Arguments,
        [Parameter(Mandatory=$true)][string]$ProbeId
    )

    $result = Invoke-AmdReadOnlyProcess -FilePath $ToolPath -Arguments $Arguments
    return [pscustomobject][ordered]@{
        ProbeId=$ProbeId
        Arguments=@($Arguments)
        ProbeStatus=if([string]$result.Status -eq 'ExecutionFailed'){'ExecutionFailed'}elseif($result.OutputLineCount -gt 0){'Observed'}else{'NoOutputObserved'}
        ExitCode=$result.ExitCode
        OutputSha256=$result.OutputSha256
        OutputLineCount=$result.OutputLineCount
        Error=$result.Error
        PrivateOutput=@($result.Output)
    }
}

function Get-AmdOptionObservationsFromText {
    [CmdletBinding()]
    param(
        [AllowNull()][string]$Text,
        [Parameter(Mandatory=$true)][AllowEmptyCollection()][string[]]$Tokens
    )

    $results = New-Object 'System.Collections.Generic.List[object]'
    $source = if ($null -eq $Text) { '' } else { [string]$Text }
    foreach ($token in $Tokens) {
        $observed = ($source.IndexOf($token,[System.StringComparison]::OrdinalIgnoreCase) -ge 0)
        $results.Add([pscustomobject][ordered]@{Token=$token;Observed=[bool]$observed})
    }
    return @($results.ToArray())
}

function Get-AmdToolBinaryPublicIdentity {
    [CmdletBinding()]
    param([Parameter(Mandatory=$true)]$ToolInfo)

    return [pscustomobject][ordered]@{
        Status=[string]$ToolInfo.Status
        ToolName=[string]$ToolInfo.ToolName
        PortablePath=$ToolInfo.PortablePath
        PathClass=$ToolInfo.PathClass
        KitVersion=$ToolInfo.KitVersion
        Architecture=$ToolInfo.Architecture
        SizeBytes=$ToolInfo.SizeBytes
        Sha256=$ToolInfo.Sha256
        FileVersion=$ToolInfo.FileVersion
        ProductVersion=$ToolInfo.ProductVersion
        CandidateCount=[int]$ToolInfo.CandidateCount
        Candidates=@($ToolInfo.Candidates)
    }
}

function Get-AmdWindowsDriverToolchainCapabilityEvidence {
    [CmdletBinding()]
    param()

    $runtimeToolchainContext = Get-AmdWindowsExecutionContext
    if ($runtimeToolchainContext.ExecutionClass -notin @('WindowsClient','WindowsServer','WindowsOther')) {
        $summary = [pscustomobject][ordered]@{
            SchemaVersion='amd-driver-toolchain-capability-summary/1.1'
            ToolkitVersion=$script:AmdResearchToolkitVersion
            EvidenceScope='WindowsNativeToolchain'
            Status='NotApplicableOnPlatform'
            ExecutionClass=$runtimeToolchainContext.ExecutionClass
            LocalizationContext=Get-AmdNativeToolLocalizationContext
            ResultClassificationContract=[pscustomobject][ordered]@{Version='amd-native-tool-result-classification/1.0';PrimarySignals=@('ProcessLaunch','ExitCode','ObservedOptionTokens','ExpectedResultCoverage');NaturalLanguageOutputRole='DiagnosticOnly';EnglishOutputRequired=$false}
            Tools=@()
            MutationPerformed=$false
        }
        return [pscustomobject][ordered]@{PublicSummary=$summary;PrivateEvidence=$summary}
    }

    $localizationContext = Get-AmdNativeToolLocalizationContext

    $toolDefinitions = @(
        [pscustomobject]@{
            Name='signtool.exe'
            Family='SignTool'
            HelpProbes=@(
                [pscustomobject]@{Id='RootHelp';Arguments=@('/?')},
                [pscustomobject]@{Id='VerifyHelp';Arguments=@('verify','/?')}
            )
            OptionTokens=@('/a','/ad','/ag','/all','/as','/c','/d','/ds','/hash','/kp','/ms','/o','/pa','/pg','/ph','/r','/tw','/v')
            TargetTokens=@()
        },
        [pscustomobject]@{
            Name='Inf2Cat.exe'
            Family='Inf2Cat'
            HelpProbes=@([pscustomobject]@{Id='RootHelp';Arguments=@('/?')})
            OptionTokens=@('/driver:','/os:','/nocat','/uselocaltime','/verbose','/?')
            TargetTokens=@('SERVER2016_X64','ServerRS5_X64','ServerFE_X64','Server2025_X64')
        }
    )

    $privateTools = New-Object 'System.Collections.Generic.List[object]'
    $publicTools = New-Object 'System.Collections.Generic.List[object]'
    foreach ($definition in $toolDefinitions) {
        $toolInfo = Get-AmdWindowsSdkToolInfo -ToolName $definition.Name
        if ([string]$toolInfo.Status -ne 'Available') {
            $publicTool = [pscustomobject][ordered]@{
                Name=$definition.Name;Family=$definition.Family;Status=$toolInfo.Status
                Binary=Get-AmdToolBinaryPublicIdentity -ToolInfo $toolInfo
                HelpProbes=@();OptionObservations=@();TargetObservations=@()
            }
            $publicTools.Add($publicTool)
            $privateTools.Add($publicTool)
            continue
        }

        $privateProbes = New-Object 'System.Collections.Generic.List[object]'
        $publicProbes = New-Object 'System.Collections.Generic.List[object]'
        $allHelpText = New-Object System.Text.StringBuilder
        foreach ($probe in @($definition.HelpProbes)) {
            $probeResult = Get-AmdToolHelpProbe -ToolPath $toolInfo.Path -Arguments @($probe.Arguments) -ProbeId $probe.Id
            $privateProbes.Add([pscustomobject][ordered]@{
                ProbeId=$probeResult.ProbeId;Arguments=@($probeResult.Arguments);ProbeStatus=$probeResult.ProbeStatus;ExitCode=$probeResult.ExitCode
                OutputSha256=$probeResult.OutputSha256;OutputLineCount=$probeResult.OutputLineCount;Error=$probeResult.Error;Output=@($probeResult.PrivateOutput);NaturalLanguageOutputRole='DiagnosticOnly';TokenParsingPolicy='OrdinalIgnoreCase'
            })
            $publicProbes.Add([pscustomobject][ordered]@{
                ProbeId=$probeResult.ProbeId;Arguments=@($probeResult.Arguments);ProbeStatus=$probeResult.ProbeStatus;ExitCode=$probeResult.ExitCode
                OutputSha256=$probeResult.OutputSha256;OutputLineCount=$probeResult.OutputLineCount;Error=$probeResult.Error;NaturalLanguageOutputRole='DiagnosticOnly';TokenParsingPolicy='OrdinalIgnoreCase'
            })
            foreach ($line in @($probeResult.PrivateOutput)) { [void]$allHelpText.AppendLine([string]$line) }
        }
        $combinedHelp = $allHelpText.ToString()
        $options = @(Get-AmdOptionObservationsFromText -Text $combinedHelp -Tokens @($definition.OptionTokens))
        $targets = @(Get-AmdOptionObservationsFromText -Text $combinedHelp -Tokens @($definition.TargetTokens))
        $binaryPublic = Get-AmdToolBinaryPublicIdentity -ToolInfo $toolInfo

        $privateTools.Add([pscustomobject][ordered]@{
            Name=$definition.Name;Family=$definition.Family;Status='Available';ResolvedPath=$toolInfo.Path;Binary=$binaryPublic
            CandidatePortableIdentities=@($toolInfo.Candidates);HelpProbes=@($privateProbes.ToArray());OptionObservations=$options;TargetObservations=$targets
        })
        $publicTools.Add([pscustomobject][ordered]@{
            Name=$definition.Name;Family=$definition.Family;Status='Available';Binary=$binaryPublic
            HelpProbes=@($publicProbes.ToArray());OptionObservations=$options;TargetObservations=$targets
        })
    }

    $publicSummary = [pscustomobject][ordered]@{
        SchemaVersion='amd-driver-toolchain-capability-summary/1.1'
        ToolkitVersion=$script:AmdResearchToolkitVersion
        CollectedAtUtc=Get-AmdUtcTimestamp
        EvidenceScope='WindowsNativeToolchain'
        Status='Observed'
        ExecutionClass=$runtimeToolchainContext.ExecutionClass
        LocalizationContext=$localizationContext
        ResultClassificationContract=[pscustomobject][ordered]@{
            Version='amd-native-tool-result-classification/1.0'
            PrimarySignals=@('ProcessLaunch','ExitCode','ObservedOptionTokens','ExpectedResultCoverage')
            NaturalLanguageOutputRole='DiagnosticOnly'
            EnglishOutputRequired=$false
            PosixLangVariablesControlWindowsSdkTools=$false
        }
        Tools=@($publicTools.ToArray())
        VerificationProfileContract=[pscustomobject][ordered]@{
            Version='amd-driver-verification-profile-contract/1.0'
            Profiles=@(
                [pscustomobject]@{Id='AuthenticodeDefault/1';ToolFamily='SignTool';Purpose='Default Authenticode verification';MutationPerformed=$false},
                [pscustomobject]@{Id='KernelEmbeddedOrCatalog/1';ToolFamily='SignTool';Purpose='Kernel-mode policy verification without an explicit target-OS claim';MutationPerformed=$false},
                [pscustomobject]@{Id='KernelExplicitCatalog/1';ToolFamily='SignTool';Purpose='Kernel-mode policy verification bound to an explicitly correlated catalog without combining /kp and /o';MutationPerformed=$false},
                [pscustomobject]@{Id='WindowsDriverExplicitCatalogTargetOs/1';ToolFamily='SignTool';Purpose='Windows Driver Verification Policy bound to an explicitly correlated catalog and explicit target OS; /pa and /kp are intentionally omitted';MutationPerformed=$false},
                [pscustomobject]@{Id='DriverPackageSignabilityMatrix/1';ToolFamily='Inf2Cat';Purpose='Driver-package signability for explicit Windows target tokens; qualification commands may generate catalogs only in a private disposable workspace';MutationPerformed=$true}
            )
        }
        MutationPerformed=$false
    }
    $privateEvidence = [pscustomobject][ordered]@{
        SchemaVersion='amd-driver-toolchain-capability-evidence/1.1'
        ToolkitVersion=$script:AmdResearchToolkitVersion
        CollectedAtUtc=$publicSummary.CollectedAtUtc
        EvidenceScope='WindowsNativeToolchain'
        ExecutionContext=$runtimeToolchainContext
        LocalizationContext=$localizationContext
        Tools=@($privateTools.ToArray())
        PublicSummary=$publicSummary
        MutationPerformed=$false
    }
    return [pscustomobject][ordered]@{PublicSummary=$publicSummary;PrivateEvidence=$privateEvidence}
}

function Test-AmdToolchainCapabilityParserSelfTest {
    [CmdletBinding()]
    param()

    $signText = 'verify /all /kp /o /pa /c /a'
    $infText = '/driver: /os: /nocat /uselocaltime SERVER2016_X64 ServerRS5_X64 ServerFE_X64 Server2025_X64'
    $sign = @(Get-AmdOptionObservationsFromText -Text $signText -Tokens @('/all','/kp','/o','/pa','/c','/a','/missing'))
    $inf = @(Get-AmdOptionObservationsFromText -Text $infText -Tokens @('/driver:','/os:','/nocat','/uselocaltime','SERVER2016_X64','Server2025_X64','MissingToken'))
    $signMissing = @($sign | Where-Object { $_.Token -eq '/missing' -and -not $_.Observed }).Count -eq 1
    $signPresent = @($sign | Where-Object { $_.Token -in @('/all','/kp','/o','/pa','/c','/a') -and $_.Observed }).Count -eq 6
    $infMissing = @($inf | Where-Object { $_.Token -eq 'MissingToken' -and -not $_.Observed }).Count -eq 1
    $infPresent = @($inf | Where-Object { $_.Token -ne 'MissingToken' -and $_.Observed }).Count -eq 6
    return [pscustomobject][ordered]@{
        Status=if($signMissing -and $signPresent -and $infMissing -and $infPresent){'Pass'}else{'Fail'}
        SignToolObservedCount=@($sign | Where-Object {$_.Observed}).Count
        Inf2CatObservedCount=@($inf | Where-Object {$_.Observed}).Count
    }
}

function Get-AmdSignToolResultClass {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]$ProcessResult
    )

    $nativeClass = Get-AmdLocaleNeutralNativeResultClass -ProcessResult $ProcessResult
    switch ($nativeClass) {
        'ToolExecutionFailed' { return 'ToolExecutionFailed' }
        'Succeeded' { return 'Verified' }
        default { return 'NonZeroExit' }
    }
}

function New-AmdSignToolCheckEvidence {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$Policy,
        [Parameter(Mandatory = $true)][string]$VerificationProfileId,
        [Parameter(Mandatory = $true)][string]$SignToolPath,
        [Parameter(Mandatory = $true)][string[]]$ProcessArguments,
        [Parameter(Mandatory = $true)][string[]]$RecordedArguments,
        [AllowNull()][string]$CatalogFileId
    )

    $result = Invoke-AmdReadOnlyProcess -FilePath $SignToolPath -Arguments $ProcessArguments
    return [pscustomobject][ordered]@{
        Policy = $Policy
        VerificationProfileId = $VerificationProfileId
        Arguments = @($RecordedArguments)
        CatalogFileId = $CatalogFileId
        ExitCode = $result.ExitCode
        Status = $result.Status
        ResultClass = Get-AmdSignToolResultClass -ProcessResult $result
        OutputSha256 = $result.OutputSha256
        OutputLineCount = $result.OutputLineCount
        Error = $result.Error
        NaturalLanguageOutputRole = 'DiagnosticOnly'
        NaturalLanguageOutputUsedForClassification = $false
        PrivateOutput = @($result.Output)
    }
}

function Get-AmdSignToolVerificationEvidence {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$SignToolPath,
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$FileType
    )

    $checks = New-Object System.Collections.Generic.List[object]
    $policies = New-Object System.Collections.Generic.List[object]
    $policies.Add([pscustomobject]@{ Name='DefaultAuthenticode'; Args=@('verify','/all','/v','/pa') })
    if ($FileType -in @('KernelBinary','Catalog')) {
        # /all is deliberate here: it exposes mixed multi-signature behavior rather
        # than collapsing a vendor-primary + Microsoft-secondary signature set into a
        # single boolean. ResultClass distinguishes this from tool invocation failure.
        $policies.Add([pscustomobject]@{ Name='KernelModeEmbeddedOrCatalog'; Args=@('verify','/all','/v','/kp') })
    }

    foreach ($policy in $policies.ToArray()) {
        $processArgs = @($policy.Args) + @($Path)
        $profileId = if ($policy.Name -eq 'DefaultAuthenticode') { 'AuthenticodeDefault/1' } else { 'KernelEmbeddedOrCatalog/1' }
        $checks.Add((New-AmdSignToolCheckEvidence -Policy $policy.Name -VerificationProfileId $profileId -SignToolPath $SignToolPath -ProcessArguments $processArgs -RecordedArguments @($policy.Args)))
    }
    return @($checks.ToArray())
}

function Get-AmdCatalogBoundSignToolProfileDefinitions {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$DriverPath,
        [Parameter(Mandatory = $true)][string]$CatalogPath
    )

    $profiles = New-Object 'System.Collections.Generic.List[object]'
    # Microsoft documents /kp /c <catalog> <driver> for explicit catalog-bound
    # kernel-policy verification. Keep /o out of this profile because the Windows
    # 11 qualification run showed the current SignTool build rejects the combined
    # /kp + /c + /o form before verification begins.
    $profiles.Add([pscustomobject][ordered]@{
        Policy='KernelModeExplicitCatalog'
        VerificationProfileId='KernelExplicitCatalog/1'
        ProcessArguments=@('verify','/v','/kp','/c',$CatalogPath,$DriverPath)
        RecordedArguments=@('verify','/v','/kp','/c','<catalog-by-file-id>','<driver-by-file-id>')
    })

    foreach ($target in @(
        [pscustomobject]@{ Name='WS2016'; Version='2:10.0.14393' },
        [pscustomobject]@{ Name='WS2019'; Version='2:10.0.17763' },
        [pscustomobject]@{ Name='WS2022'; Version='2:10.0.20348' },
        [pscustomobject]@{ Name='WS2025'; Version='2:10.0.26100' }
    )) {
        # SignTool documents that when /pa is absent the Windows Driver Verification
        # Policy is used, and /o applies an explicit OS version. Keep this target-OS
        # profile distinct from /kp so each observation has one unambiguous policy.
        $profiles.Add([pscustomobject][ordered]@{
            Policy=('WindowsDriverCatalogTarget' + $target.Name)
            VerificationProfileId='WindowsDriverExplicitCatalogTargetOs/1'
            ProcessArguments=@('verify','/v','/c',$CatalogPath,'/o',$target.Version,$DriverPath)
            RecordedArguments=@('verify','/v','/c','<catalog-by-file-id>','/o',$target.Version,'<driver-by-file-id>')
        })
    }
    return @($profiles.ToArray())
}

function Test-AmdSignToolVerificationProfileSelfTest {
    [CmdletBinding()]
    param()

    $profiles = @(Get-AmdCatalogBoundSignToolProfileDefinitions -DriverPath 'C:\evidence\driver.sys' -CatalogPath 'C:\evidence\driver.cat')
    $kernel = @($profiles | Where-Object { $_.Policy -eq 'KernelModeExplicitCatalog' })
    $targets = @($profiles | Where-Object { $_.Policy -like 'WindowsDriverCatalogTarget*' })
    $kernelArgs = if($kernel.Count -eq 1){@($kernel[0].ProcessArguments)}else{@()}
    $targetArgsValid = $true
    foreach ($profile in $targets) {
        $args = @($profile.ProcessArguments)
        if (($args -notcontains '/o') -or ($args -notcontains '/c') -or ($args -contains '/kp') -or ($args -contains '/pa')) { $targetArgsValid = $false }
    }
    $kernelValid = ($kernel.Count -eq 1 -and $kernelArgs -contains '/kp' -and $kernelArgs -contains '/c' -and $kernelArgs -notcontains '/o' -and $kernelArgs -notcontains '/pa')
    $targetVersions = @($targets | ForEach-Object { $a=@($_.ProcessArguments); $idx=[Array]::IndexOf($a,'/o'); if($idx -ge 0 -and $idx+1 -lt $a.Count){[string]$a[$idx+1]} })
    $versionsValid = (@($targetVersions | Sort-Object -Unique).Count -eq 4 -and @('2:10.0.14393','2:10.0.17763','2:10.0.20348','2:10.0.26100' | Where-Object { $targetVersions -notcontains $_ }).Count -eq 0)
    $ok = ($profiles.Count -eq 5 -and $targets.Count -eq 4 -and $kernelValid -and $targetArgsValid -and $versionsValid)
    return [pscustomobject][ordered]@{Status=if($ok){'Pass'}else{'Fail'};ProfileCount=$profiles.Count;KernelProfileCount=$kernel.Count;TargetProfileCount=$targets.Count;KernelProfileValid=$kernelValid;TargetProfilesValid=$targetArgsValid;TargetVersionsValid=$versionsValid}
}

function Get-AmdCatalogBoundSignToolEvidence {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$SignToolPath,
        [Parameter(Mandatory = $true)][string]$DriverPath,
        [Parameter(Mandatory = $true)][string]$CatalogPath,
        [Parameter(Mandatory = $true)][string]$CatalogFileId
    )

    $checks = New-Object System.Collections.Generic.List[object]
    foreach ($profile in @(Get-AmdCatalogBoundSignToolProfileDefinitions -DriverPath $DriverPath -CatalogPath $CatalogPath)) {
        $checks.Add((New-AmdSignToolCheckEvidence -Policy $profile.Policy -VerificationProfileId $profile.VerificationProfileId -SignToolPath $SignToolPath -ProcessArguments @($profile.ProcessArguments) -RecordedArguments @($profile.RecordedArguments) -CatalogFileId $CatalogFileId))
    }
    return @($checks.ToArray())
}

function Get-AmdWindowsHostSecurityPosture {
    [CmdletBinding()]
    param()

    $context = Get-AmdWindowsExecutionContext
    if ($context.ExecutionClass -notin @('WindowsClient','WindowsServer','WindowsOther')) {
        return [pscustomobject][ordered]@{ SchemaVersion='amd-driver-windows-host-security-posture/1.0'; ToolkitVersion=$script:AmdResearchToolkitVersion; EvidenceScope='WindowsNative'; Status='NotApplicable'; ExecutionClass=$context.ExecutionClass; MutationPerformed=$false }
    }

    $secureBoot = [pscustomobject][ordered]@{ Status='Unknown'; Enabled=$null; Error=$null }
    $secureBootCommand = Get-Command -Name Confirm-SecureBootUEFI -ErrorAction SilentlyContinue
    if ($secureBootCommand) {
        try { $secureBoot = [pscustomobject][ordered]@{ Status='Observed'; Enabled=[bool](Confirm-SecureBootUEFI -ErrorAction Stop); Error=$null } }
        catch { $secureBoot = [pscustomobject][ordered]@{ Status='QueryFailed'; Enabled=$null; Error=$_.Exception.Message } }
    }

    $deviceGuard = $null
    try {
        $dg = Get-CimInstance -Namespace 'root\Microsoft\Windows\DeviceGuard' -ClassName Win32_DeviceGuard -ErrorAction Stop | Select-Object -First 1
        if ($dg) {
            $deviceGuard = [pscustomobject][ordered]@{
                Status='Observed'
                VirtualizationBasedSecurityStatus=$dg.VirtualizationBasedSecurityStatus
                SecurityServicesConfigured=@($dg.SecurityServicesConfigured)
                SecurityServicesRunning=@($dg.SecurityServicesRunning)
                CodeIntegrityPolicyEnforcementStatus=$dg.CodeIntegrityPolicyEnforcementStatus
                UsermodeCodeIntegrityPolicyEnforcementStatus=$dg.UsermodeCodeIntegrityPolicyEnforcementStatus
            }
        }
    }
    catch {
        $deviceGuard = [pscustomobject][ordered]@{ Status='QueryFailed'; Error=$_.Exception.Message }
    }

    $testSigning = [pscustomobject][ordered]@{ Status='NotObserved'; Value=$null; Error=$null }
    $bcdedit = Get-Command -Name bcdedit.exe -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($bcdedit -and $bcdedit.Source) {
        $probe = Invoke-AmdReadOnlyProcess -FilePath $bcdedit.Source -Arguments @('/enum','{current}')
        $line = @($probe.Output | Where-Object { $_ -match '(?i)^\s*testsigning\s+' } | Select-Object -First 1)
        if ($line.Count -gt 0) {
            $testSigning = [pscustomobject][ordered]@{ Status='Observed'; Value=([string]$line[0] -replace '(?i)^\s*testsigning\s+','').Trim(); Error=$null }
        }
        elseif ($probe.Status -eq 'Pass') {
            $testSigning = [pscustomobject][ordered]@{ Status='ObservedDefault'; Value='OffOrNotSet'; Error=$null }
        }
        else {
            $testSigning = [pscustomobject][ordered]@{ Status='QueryFailed'; Value=$null; Error=$probe.Error }
        }
    }

    return [pscustomobject][ordered]@{
        SchemaVersion = 'amd-driver-windows-host-security-posture/1.0'
        ToolkitVersion = $script:AmdResearchToolkitVersion
        EvidenceScope = 'WindowsNative'
        Status = 'Observed'
        CollectedAtUtc = Get-AmdUtcTimestamp
        ExecutionContext = $context
        SecureBoot = $secureBoot
        DeviceGuard = $deviceGuard
        TestSigning = $testSigning
        MutationPerformed = $false
    }
}


function Get-AmdTargetServerHostEvidence {
    [CmdletBinding()]
    param(
        [AllowNull()]$WindowsHostSecurityPosture
    )

    $context = Get-AmdWindowsExecutionContext
    if ($context.ExecutionClass -ne 'WindowsServer') {
        return [pscustomobject][ordered]@{ SchemaVersion='amd-driver-target-server-host-evidence/1.0'; ToolkitVersion=$script:AmdResearchToolkitVersion; Status='NotApplicable'; EvidenceScope='TargetServerHost'; ExecutionClass=$context.ExecutionClass; MutationPerformed=$false }
    }

    return [pscustomobject][ordered]@{
        SchemaVersion = 'amd-driver-target-server-host-evidence/1.0'
        ToolkitVersion = $script:AmdResearchToolkitVersion
        Status = 'ObservedHostContext'
        CollectedAtUtc = Get-AmdUtcTimestamp
        EvidenceScope = 'TargetServerHost'
        ExecutionContext = $context
        WindowsHostSecurityPosture = $WindowsHostSecurityPosture
        RuntimeDriverValidation = [pscustomobject][ordered]@{
            Status = 'NotPerformedBySignatureStage'
            PnpInstallation = 'NotObserved'
            KernelLoad = 'NotObserved'
            CodeIntegrityRuntime = 'NotObserved'
            DeviceRuntime = 'NotObserved'
            Note = 'TargetServerHost establishes the server execution context only. Driver installation, kernel load, Code Integrity event correlation, and device runtime require an explicit later qualification workflow.'
        }
        MutationPerformed = $false
    }
}

function Test-AmdSignaturePrimitiveSelfTest {
    [CmdletBinding()]
    param()

    $oidBytes = [byte[]](0x2b,0x06,0x01,0x04,0x01,0x82,0x37,0x02,0x04,0x01)
    $oid = ConvertFrom-AmdDerOid -Bytes $oidBytes -Offset 0 -Length $oidBytes.Length
    $abcBytes = [System.Text.Encoding]::ASCII.GetBytes('abc')
    $abcSha256 = Get-AmdByteArraySha256 -Bytes $abcBytes
    $emptySha256 = Get-AmdByteArraySha256 -Bytes ([byte[]]@())
    $nativeNegativeCase = $null
    $selfTestPlatform = Get-AmdPlatformInfo
    if ($selfTestPlatform.PlatformFamily -eq 'Windows' -and $env:ComSpec -and (Test-Path -LiteralPath $env:ComSpec -PathType Leaf)) {
        $nativeNegativeCase = Invoke-AmdReadOnlyProcess -FilePath $env:ComSpec -Arguments @('/d','/c','echo SignaturePrimitiveNegativeCase 1>&2 & exit /b 1')
    }
    elseif (Test-Path -LiteralPath '/bin/sh' -PathType Leaf) {
        $nativeNegativeCase = Invoke-AmdReadOnlyProcess -FilePath '/bin/sh' -Arguments @('-c','echo SignaturePrimitiveNegativeCase 1>&2; exit 1')
    }
    $nativeNegativeCaseOk = ($null -ne $nativeNegativeCase -and $nativeNegativeCase.Status -eq 'Fail' -and $nativeNegativeCase.ExitCode -eq 1 -and -not [string]::IsNullOrWhiteSpace($nativeNegativeCase.OutputSha256))
    $pkcsRuntime = Initialize-AmdSignedCmsRuntime
    $cmsAvailable = ($pkcsRuntime.Status -eq 'Available')
    if ($cmsAvailable) {
        try { $null = New-Object System.Security.Cryptography.Pkcs.SignedCms }
        catch { $cmsAvailable = $false }
    }
    $ok = (
        $oid -eq '1.3.6.1.4.1.311.2.4.1' -and
        $abcSha256 -eq 'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad' -and
        $emptySha256 -eq 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855' -and
        $nativeNegativeCaseOk -and
        $cmsAvailable
    )
    return [pscustomobject][ordered]@{
        Status = if ($ok) { 'Pass' } else { 'Fail' }
        NestedSignatureOid = $oid
        Sha256KnownAnswer = $abcSha256
        EmptySha256KnownAnswer = $emptySha256
        NativeNegativeCase = $nativeNegativeCase
        NativeNegativeCaseHandled = $nativeNegativeCaseOk
        SignedCmsAvailable = $cmsAvailable
        SignedCmsRuntime = $pkcsRuntime
    }
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

# Common Canonical JSON contract: byte-identical on Windows PowerShell 5.1,
# PowerShell 7.x and the Python json.dumps reference configuration.
# Ported and adapted from projects/powershell-update-windows-server-iso/
# Update-WindowsServerIso.ps1 (SPEC Part B.23 contract).
function Initialize-AmdCanonicalJsonRuntime {
    [CmdletBinding()]
    param()

    $runtimeType = [System.Management.Automation.PSTypeName]'AmdDriverResearch.CanonicalJsonRuntime'
    if ($null -ne $runtimeType.Type) { return }

    $source = @'
using System;
using System.Collections;
using System.Collections.Generic;
using System.Globalization;
using System.Management.Automation;
using System.Text;

namespace AmdDriverResearch
{
    public static class CanonicalJsonRuntime
    {
        public static string Serialize(object value, int maxDepth, int indentWidth, bool trailingNewline)
        {
            if (maxDepth < 1) throw new ArgumentOutOfRangeException("maxDepth");
            if (indentWidth < 1) throw new ArgumentOutOfRangeException("indentWidth");
            StringBuilder builder = new StringBuilder();
            WriteValue(value, 0, maxDepth, new string(' ', indentWidth), builder);
            if (trailingNewline) builder.Append('\n');
            return builder.ToString();
        }

        public static object Deserialize(string json)
        {
            if (json == null) throw new ArgumentNullException("json");
            Parser parser = new Parser(json);
            object value = parser.ParseValue();
            parser.SkipWhitespace();
            if (!parser.AtEnd) throw new FormatException("Unexpected trailing content at position " + parser.Position + ".");
            return value;
        }

        private static void WriteValue(object value, int depth, int maxDepth, string indent, StringBuilder builder)
        {
            if (value == null || value.GetType().FullName == "System.Management.Automation.Internal.AutomationNull")
            {
                builder.Append("null");
                return;
            }

            PSObject wrapped = value as PSObject;
            object baseValue = wrapped == null ? value : wrapped.BaseObject;
            if (baseValue == null)
            {
                builder.Append("null");
                return;
            }

            Type type = baseValue.GetType();
            if (baseValue is bool)
            {
                builder.Append((bool)baseValue ? "true" : "false");
                return;
            }
            if (baseValue is DateTime)
            {
                DateTime date = (DateTime)baseValue;
                DateTime utc = date.Kind == DateTimeKind.Unspecified ? DateTime.SpecifyKind(date, DateTimeKind.Utc) : date.ToUniversalTime();
                WriteString(utc.ToString("o", CultureInfo.InvariantCulture), builder);
                return;
            }
            if (baseValue is DateTimeOffset)
            {
                WriteString(((DateTimeOffset)baseValue).UtcDateTime.ToString("o", CultureInfo.InvariantCulture), builder);
                return;
            }
            if (type.IsEnum)
            {
                WriteString(baseValue.ToString(), builder);
                return;
            }
            if (baseValue is string || baseValue is char || baseValue is Uri || baseValue is Guid || baseValue is Version)
            {
                WriteString(Convert.ToString(baseValue, CultureInfo.InvariantCulture), builder);
                return;
            }
            if (IsInteger(type))
            {
                builder.Append(Convert.ToString(baseValue, CultureInfo.InvariantCulture));
                return;
            }
            if (baseValue is double || baseValue is float || baseValue is decimal)
            {
                WriteNumber(baseValue, builder);
                return;
            }

            IDictionary dictionary = baseValue as IDictionary;
            if (dictionary != null)
            {
                List<KeyValuePair<string, object>> pairs = new List<KeyValuePair<string, object>>();
                foreach (object key in dictionary.Keys)
                    pairs.Add(new KeyValuePair<string, object>(Convert.ToString(key, CultureInfo.InvariantCulture), dictionary[key]));
                WriteObject(pairs, depth, maxDepth, indent, builder);
                return;
            }

            IEnumerable enumerable = baseValue as IEnumerable;
            if (enumerable != null)
            {
                List<object> items = new List<object>();
                foreach (object item in enumerable) items.Add(item);
                WriteArray(items, depth, maxDepth, indent, builder);
                return;
            }

            PSObject psObject = wrapped ?? PSObject.AsPSObject(baseValue);
            List<KeyValuePair<string, object>> properties = new List<KeyValuePair<string, object>>();
            foreach (PSPropertyInfo property in psObject.Properties)
                properties.Add(new KeyValuePair<string, object>(property.Name, property.Value));
            if (properties.Count == 0 && type.FullName != "System.Management.Automation.PSCustomObject")
            {
                WriteString(Convert.ToString(baseValue, CultureInfo.InvariantCulture), builder);
                return;
            }
            WriteObject(properties, depth, maxDepth, indent, builder);
        }

        private static bool IsInteger(Type type)
        {
            return type == typeof(byte) || type == typeof(sbyte) || type == typeof(short) || type == typeof(ushort) ||
                   type == typeof(int) || type == typeof(uint) || type == typeof(long) || type == typeof(ulong);
        }

        private static void WriteNumber(object value, StringBuilder builder)
        {
            if (value is decimal)
            {
                builder.Append(((decimal)value).ToString(CultureInfo.InvariantCulture));
                return;
            }
            double number = Convert.ToDouble(value, CultureInfo.InvariantCulture);
            if (Double.IsNaN(number) || Double.IsInfinity(number)) throw new InvalidOperationException("Non-finite number cannot be encoded as canonical JSON.");
            string text = number.ToString("R", CultureInfo.InvariantCulture);
            if (text.IndexOf('.') < 0 && text.IndexOf('e') < 0 && text.IndexOf('E') < 0) text += ".0";
            builder.Append(text.Replace('E', 'e'));
        }

        private static void WriteObject(IList<KeyValuePair<string, object>> pairs, int depth, int maxDepth, string indent, StringBuilder builder)
        {
            if (pairs.Count == 0) { builder.Append("{}"); return; }
            if (depth + 1 > maxDepth) throw new InvalidOperationException("Object nests deeper than allowed depth (" + maxDepth + "); reached depth " + (depth + 1) + ".");
            builder.Append("{\n");
            string child = Repeat(indent, depth + 1);
            string close = Repeat(indent, depth);
            for (int i = 0; i < pairs.Count; i++)
            {
                builder.Append(child);
                WriteString(pairs[i].Key, builder);
                builder.Append(": ");
                WriteValue(pairs[i].Value, depth + 1, maxDepth, indent, builder);
                if (i + 1 < pairs.Count) builder.Append(',');
                builder.Append('\n');
            }
            builder.Append(close).Append('}');
        }

        private static void WriteArray(IList<object> items, int depth, int maxDepth, string indent, StringBuilder builder)
        {
            if (items.Count == 0) { builder.Append("[]"); return; }
            if (depth + 1 > maxDepth) throw new InvalidOperationException("Object nests deeper than allowed depth (" + maxDepth + "); reached depth " + (depth + 1) + ".");
            builder.Append("[\n");
            string child = Repeat(indent, depth + 1);
            string close = Repeat(indent, depth);
            for (int i = 0; i < items.Count; i++)
            {
                builder.Append(child);
                WriteValue(items[i], depth + 1, maxDepth, indent, builder);
                if (i + 1 < items.Count) builder.Append(',');
                builder.Append('\n');
            }
            builder.Append(close).Append(']');
        }

        private static string Repeat(string value, int count)
        {
            if (count == 0) return String.Empty;
            StringBuilder builder = new StringBuilder(value.Length * count);
            for (int i = 0; i < count; i++) builder.Append(value);
            return builder.ToString();
        }

        private static void WriteString(string value, StringBuilder builder)
        {
            if (value == null) { builder.Append("null"); return; }
            builder.Append('"');
            foreach (char c in value)
            {
                switch (c)
                {
                    case '"': builder.Append("\\\""); break;
                    case '\\': builder.Append("\\\\"); break;
                    case '\b': builder.Append("\\b"); break;
                    case '\t': builder.Append("\\t"); break;
                    case '\n': builder.Append("\\n"); break;
                    case '\f': builder.Append("\\f"); break;
                    case '\r': builder.Append("\\r"); break;
                    default:
                        if (c < 32) builder.Append("\\u").Append(((int)c).ToString("x4", CultureInfo.InvariantCulture));
                        else builder.Append(c);
                        break;
                }
            }
            builder.Append('"');
        }

        private sealed class Parser
        {
            private readonly string text;
            private int index;
            public Parser(string text) { this.text = text; }
            public bool AtEnd { get { return index >= text.Length; } }
            public int Position { get { return index; } }

            public void SkipWhitespace()
            {
                while (!AtEnd)
                {
                    char c = text[index];
                    if (c == ' ' || c == '\t' || c == '\n' || c == '\r') index++;
                    else break;
                }
            }

            public object ParseValue()
            {
                SkipWhitespace();
                if (AtEnd) throw new FormatException("Unexpected end of input.");
                char c = text[index];
                if (c == '{') return ParseObject();
                if (c == '[') return ParseArray();
                if (c == '"') return ParseString();
                if (c == '-' || (c >= '0' && c <= '9')) return ParseNumber();
                if (Matches("true")) { index += 4; return true; }
                if (Matches("false")) { index += 5; return false; }
                if (Matches("null")) { index += 4; return null; }
                throw new FormatException("Unexpected character '" + c + "' at position " + index + ".");
            }

            private object ParseObject()
            {
                PSObject result = new PSObject();
                index++;
                SkipWhitespace();
                if (!AtEnd && text[index] == '}') { index++; return result; }
                while (true)
                {
                    SkipWhitespace();
                    if (AtEnd || text[index] != '"') throw new FormatException("Expected string key at position " + index + ".");
                    string key = ParseString();
                    SkipWhitespace();
                    if (AtEnd || text[index] != ':') throw new FormatException("Expected ':' at position " + index + ".");
                    index++;
                    object value = ParseValue();
                    if (result.Properties[key] != null) throw new FormatException("Duplicate object key '" + key + "'.");
                    result.Properties.Add(new PSNoteProperty(key, value));
                    SkipWhitespace();
                    if (AtEnd) throw new FormatException("Unterminated object.");
                    char c = text[index++];
                    if (c == '}') break;
                    if (c != ',') throw new FormatException("Expected ',' or '}' at position " + (index - 1) + ".");
                }
                return result;
            }

            private object[] ParseArray()
            {
                List<object> result = new List<object>();
                index++;
                SkipWhitespace();
                if (!AtEnd && text[index] == ']') { index++; return result.ToArray(); }
                while (true)
                {
                    result.Add(ParseValue());
                    SkipWhitespace();
                    if (AtEnd) throw new FormatException("Unterminated array.");
                    char c = text[index++];
                    if (c == ']') break;
                    if (c != ',') throw new FormatException("Expected ',' or ']' at position " + (index - 1) + ".");
                }
                return result.ToArray();
            }

            private string ParseString()
            {
                StringBuilder builder = new StringBuilder();
                index++;
                while (!AtEnd)
                {
                    char c = text[index++];
                    if (c == '"') return builder.ToString();
                    if (c == '\\')
                    {
                        if (AtEnd) throw new FormatException("Unterminated escape.");
                        char escape = text[index++];
                        switch (escape)
                        {
                            case '"': builder.Append('"'); break;
                            case '\\': builder.Append('\\'); break;
                            case '/': builder.Append('/'); break;
                            case 'b': builder.Append('\b'); break;
                            case 't': builder.Append('\t'); break;
                            case 'n': builder.Append('\n'); break;
                            case 'f': builder.Append('\f'); break;
                            case 'r': builder.Append('\r'); break;
                            case 'u':
                                if (index + 4 > text.Length) throw new FormatException("Bad unicode escape.");
                                string hex = text.Substring(index, 4);
                                int code;
                                if (!Int32.TryParse(hex, NumberStyles.AllowHexSpecifier, CultureInfo.InvariantCulture, out code)) throw new FormatException("Bad unicode escape at position " + index + ".");
                                builder.Append((char)code);
                                index += 4;
                                break;
                            default: throw new FormatException("Bad escape at position " + (index - 1) + ".");
                        }
                    }
                    else
                    {
                        if (c < 32) throw new FormatException("Unescaped control character at position " + (index - 1) + ".");
                        builder.Append(c);
                    }
                }
                throw new FormatException("Unterminated string.");
            }

            private object ParseNumber()
            {
                int start = index;
                if (text[index] == '-') index++;
                while (!AtEnd && text[index] >= '0' && text[index] <= '9') index++;
                if (!AtEnd && text[index] == '.')
                {
                    index++;
                    while (!AtEnd && text[index] >= '0' && text[index] <= '9') index++;
                }
                if (!AtEnd && (text[index] == 'e' || text[index] == 'E'))
                {
                    index++;
                    if (!AtEnd && (text[index] == '+' || text[index] == '-')) index++;
                    while (!AtEnd && text[index] >= '0' && text[index] <= '9') index++;
                }
                string value = text.Substring(start, index - start);
                if (value.IndexOf('.') < 0 && value.IndexOf('e') < 0 && value.IndexOf('E') < 0)
                {
                    long integer;
                    if (Int64.TryParse(value, NumberStyles.Integer, CultureInfo.InvariantCulture, out integer)) return integer;
                }
                return Double.Parse(value, NumberStyles.Float, CultureInfo.InvariantCulture);
            }

            private bool Matches(string value)
            {
                return index + value.Length <= text.Length && String.CompareOrdinal(text, index, value, 0, value.Length) == 0;
            }
        }
    }
}
'@
    Add-Type -TypeDefinition $source -Language CSharp -ErrorAction Stop
}

function ConvertTo-CanonicalJson {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory=$true,Position=0)][AllowNull()]$InputObject,
        [int]$Depth=20,
        [int]$IndentWidth=2,
        [switch]$NoTrailingNewline
    )

    if ($Depth -lt 1) { throw "depth must be >= 1, got $Depth" }
    if ($IndentWidth -lt 1) { throw "indent_width must be >= 1, got $IndentWidth" }
    Initialize-AmdCanonicalJsonRuntime
    return [AmdDriverResearch.CanonicalJsonRuntime]::Serialize($InputObject,$Depth,$IndentWidth,(-not $NoTrailingNewline))
}
function _CanonicalJson_WriteValue {
    param($Value,[int]$Depth,[int]$MaxDepth,[string]$IndentUnit,[System.Text.StringBuilder]$Sb)
    if($null -eq $Value){[void]$Sb.Append('null');return};if($Value -is [bool]){[void]$Sb.Append($(if($Value){'true'}else{'false'}));return}
    if($Value -is [datetime]){$ic=[Globalization.CultureInfo]::InvariantCulture;$utc=$(if($Value.Kind -eq [DateTimeKind]::Unspecified){[datetime]::SpecifyKind($Value,[DateTimeKind]::Utc)}else{$Value.ToUniversalTime()});_CanonicalJson_WriteString -S $utc.ToString('o',$ic) -Sb $Sb;return}
    if($Value -is [datetimeoffset]){_CanonicalJson_WriteString -S $Value.UtcDateTime.ToString('o',[Globalization.CultureInfo]::InvariantCulture) -Sb $Sb;return}
    if($Value.GetType().IsEnum){_CanonicalJson_WriteString -S ([string]$Value) -Sb $Sb;return}
    if($Value -is [string] -or $Value -is [char] -or $Value -is [uri] -or $Value -is [guid] -or $Value -is [version]){_CanonicalJson_WriteString -S ([string]$Value) -Sb $Sb;return}
    if($Value -is [int] -or $Value -is [long] -or $Value -is [int16] -or $Value -is [byte] -or $Value -is [sbyte] -or $Value -is [uint16] -or $Value -is [uint32] -or $Value -is [uint64]){[void]$Sb.Append($Value.ToString([Globalization.CultureInfo]::InvariantCulture));return}
    if($Value -is [double] -or $Value -is [single] -or $Value -is [decimal]){_CanonicalJson_WriteNumber -N $Value -Sb $Sb;return}
    if($Value -is [Collections.IDictionary]){$pairs=New-Object 'Collections.Generic.List[object]';foreach($k in $Value.Keys){$pairs.Add([pscustomobject]@{K=[string]$k;V=$Value[$k]})|Out-Null};if($pairs.Count -eq 0){[void]$Sb.Append('{}')}else{_CanonicalJson_WriteObject -Pairs $pairs.ToArray() -Depth $Depth -MaxDepth $MaxDepth -IndentUnit $IndentUnit -Sb $Sb};return}
    if($Value -is [Collections.IEnumerable]){$items=New-Object 'Collections.Generic.List[object]';foreach($item in $Value){$items.Add($item)|Out-Null};if($items.Count -eq 0){[void]$Sb.Append('[]')}else{_CanonicalJson_WriteArray -Items $items.ToArray() -Depth $Depth -MaxDepth $MaxDepth -IndentUnit $IndentUnit -Sb $Sb};return}
    $props=@($Value.PSObject.Properties);if($props.Count -eq 0){if($Value -is [Management.Automation.PSCustomObject]){[void]$Sb.Append('{}')}else{_CanonicalJson_WriteString -S ([string]$Value) -Sb $Sb};return}
    $pairs=New-Object 'Collections.Generic.List[object]';foreach($p in $props){$pairs.Add([pscustomobject]@{K=$p.Name;V=$p.Value})|Out-Null};_CanonicalJson_WriteObject -Pairs $pairs.ToArray() -Depth $Depth -MaxDepth $MaxDepth -IndentUnit $IndentUnit -Sb $Sb
}
function _CanonicalJson_WriteObject { param([object[]]$Pairs,[int]$Depth,[int]$MaxDepth,[string]$IndentUnit,[Text.StringBuilder]$Sb);if(($Depth+1)-gt $MaxDepth){throw "Object nests deeper than allowed depth ($MaxDepth); reached depth $($Depth+1)."};$child=$IndentUnit*($Depth+1);$close=$IndentUnit*$Depth;[void]$Sb.Append("{`n");for($i=0;$i-lt $Pairs.Count;$i++){[void]$Sb.Append($child);_CanonicalJson_WriteString -S $Pairs[$i].K -Sb $Sb;[void]$Sb.Append(': ');_CanonicalJson_WriteValue -Value $Pairs[$i].V -Depth ($Depth+1) -MaxDepth $MaxDepth -IndentUnit $IndentUnit -Sb $Sb;if($i-lt $Pairs.Count-1){[void]$Sb.Append(',')};[void]$Sb.Append("`n")};[void]$Sb.Append($close);[void]$Sb.Append('}') }
function _CanonicalJson_WriteArray { param([object[]]$Items,[int]$Depth,[int]$MaxDepth,[string]$IndentUnit,[Text.StringBuilder]$Sb);if(($Depth+1)-gt $MaxDepth){throw "Object nests deeper than allowed depth ($MaxDepth); reached depth $($Depth+1)."};$child=$IndentUnit*($Depth+1);$close=$IndentUnit*$Depth;[void]$Sb.Append("[`n");for($i=0;$i-lt $Items.Count;$i++){[void]$Sb.Append($child);_CanonicalJson_WriteValue -Value $Items[$i] -Depth ($Depth+1) -MaxDepth $MaxDepth -IndentUnit $IndentUnit -Sb $Sb;if($i-lt $Items.Count-1){[void]$Sb.Append(',')};[void]$Sb.Append("`n")};[void]$Sb.Append($close);[void]$Sb.Append(']') }
function _CanonicalJson_WriteString { param([AllowNull()][string]$S,[Text.StringBuilder]$Sb);if($null-eq$S){[void]$Sb.Append('null');return};[void]$Sb.Append('"');foreach($ch in $S.ToCharArray()){$n=[int]$ch;switch($n){34{[void]$Sb.Append('\"')}92{[void]$Sb.Append('\\')}8{[void]$Sb.Append('\b')}9{[void]$Sb.Append('\t')}10{[void]$Sb.Append('\n')}12{[void]$Sb.Append('\f')}13{[void]$Sb.Append('\r')}default{if($n-lt32){[void]$Sb.Append(('\u{0:x4}'-f$n))}else{[void]$Sb.Append($ch)}}}};[void]$Sb.Append('"') }
function _CanonicalJson_WriteNumber { param($N,[Text.StringBuilder]$Sb);$ic=[Globalization.CultureInfo]::InvariantCulture;if(($N-is[double] -and ([double]::IsNaN($N)-or[double]::IsInfinity($N))) -or ($N-is[single] -and ([single]::IsNaN($N)-or[single]::IsInfinity($N)))){throw 'Non-finite number cannot be encoded as canonical JSON.'};if($N-is[double]-or$N-is[single]){$s=([double]$N).ToString('R',$ic);if($s-notmatch'[.eE]'){$s+='.0'}}else{$s=([decimal]$N).ToString($ic)};$s=[regex]::Replace($s,'(?<=\d)E(?=[+\-]?\d)','e');[void]$Sb.Append($s) }
function Save-CanonicalJsonFile { [CmdletBinding()]param([Parameter(Mandatory=$true,Position=0)][AllowNull()]$InputObject,[Parameter(Mandatory=$true,Position=1)][string]$Path,[int]$Depth=20);$parent=Split-Path -Parent $Path;if($parent){New-AmdDirectory -Path $parent|Out-Null};$json=ConvertTo-CanonicalJson -InputObject $InputObject -Depth $Depth;$enc=New-Object Text.UTF8Encoding($false);$tmp=$Path+'.tmp';try{[IO.File]::WriteAllBytes($tmp,$enc.GetBytes($json));Move-Item -LiteralPath $tmp -Destination $Path -Force}catch{Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue;throw} }
function ConvertFrom-CanonicalJson {
    [CmdletBinding()]
    [OutputType([object])]
    param(
        [Parameter(Mandatory=$true,Position=0,ValueFromPipeline=$true)]
        [AllowEmptyString()]
        [string]$Json
    )

    process {
        Initialize-AmdCanonicalJsonRuntime
        return [AmdDriverResearch.CanonicalJsonRuntime]::Deserialize($Json)
    }
}
function _CanonicalJson_SkipWs { param($State);while($State.i-lt$State.n){$c=$State.s[$State.i];if($c-eq' '-or$c-eq"`t"-or$c-eq"`n"-or$c-eq"`r"){$State.i++}else{break}} }
function _CanonicalJson_ParseValue { param($State);if($State.i-ge$State.n){throw 'Unexpected end of input.'};$c=$State.s[$State.i];if($c-eq'{'){return _CanonicalJson_ParseObject $State};if($c-eq'['){return _CanonicalJson_ParseArray $State};if($c-eq'"'){return _CanonicalJson_ParseString $State};if($c-eq'-'-or($c-ge'0'-and$c-le'9')){return _CanonicalJson_ParseNumber $State};if($c-eq't'-or$c-eq'f'){return _CanonicalJson_ParseBool $State};if($c-eq'n'){return _CanonicalJson_ParseNull $State};throw "Unexpected character '$c' at position $($State.i)." }
function _CanonicalJson_ParseObject { param($State);$o=[ordered]@{};$State.i++;_CanonicalJson_SkipWs $State;if($State.i-lt$State.n-and$State.s[$State.i]-eq'}'){$State.i++;return [pscustomobject]$o};while($true){_CanonicalJson_SkipWs $State;if($State.i-ge$State.n-or$State.s[$State.i]-ne'"'){throw "Expected string key at position $($State.i)."};$k=_CanonicalJson_ParseString $State;_CanonicalJson_SkipWs $State;if($State.i-ge$State.n-or$State.s[$State.i]-ne':'){throw "Expected ':' at position $($State.i)."};$State.i++;_CanonicalJson_SkipWs $State;$o[$k]=_CanonicalJson_ParseValue $State;_CanonicalJson_SkipWs $State;if($State.i-ge$State.n){throw 'Unterminated object.'};$c=$State.s[$State.i];if($c-eq','){$State.i++;continue};if($c-eq'}'){$State.i++;break};throw "Expected ',' or '}' at position $($State.i)."};return [pscustomobject]$o }
function _CanonicalJson_ParseArray { param($State);$a=New-Object 'Collections.Generic.List[object]';$State.i++;_CanonicalJson_SkipWs $State;if($State.i-lt$State.n-and$State.s[$State.i]-eq']'){$State.i++;return ,$a.ToArray()};while($true){_CanonicalJson_SkipWs $State;$a.Add((_CanonicalJson_ParseValue $State))|Out-Null;_CanonicalJson_SkipWs $State;if($State.i-ge$State.n){throw 'Unterminated array.'};$c=$State.s[$State.i];if($c-eq','){$State.i++;continue};if($c-eq']'){$State.i++;break};throw "Expected ',' or ']' at position $($State.i)."};return ,$a.ToArray() }
function _CanonicalJson_ParseString { param($State);$sb=New-Object Text.StringBuilder;$State.i++;while($State.i-lt$State.n){$c=$State.s[$State.i];$State.i++;if($c-eq'"'){return ($sb.ToString())};if($c-eq'\'){if($State.i-ge$State.n){throw 'Unterminated escape.'};$e=$State.s[$State.i];$State.i++;switch($e){'"'{[void]$sb.Append('"')}'\'{[void]$sb.Append('\')}'/'{[void]$sb.Append('/')}b{[void]$sb.Append([char]8)}t{[void]$sb.Append([char]9)}n{[void]$sb.Append([char]10)}f{[void]$sb.Append([char]12)}r{[void]$sb.Append([char]13)}u{if($State.i+4-gt$State.n){throw 'Bad unicode escape.'};$h=$State.s.Substring($State.i,4);$State.i+=4;[void]$sb.Append([char][Convert]::ToInt32($h,16))}default{throw "Bad escape at position $($State.i)."}}}else{if([int]$c-lt32){throw "Unescaped control character at position $($State.i-1)."};[void]$sb.Append($c)}};throw 'Unterminated string.' }
function _CanonicalJson_ParseNumber { param($State);$start=$State.i;$s=$State.s;if($s[$State.i]-eq'-'){$State.i++};while($State.i-lt$State.n-and$s[$State.i]-ge'0'-and$s[$State.i]-le'9'){$State.i++};if($State.i-lt$State.n-and$s[$State.i]-eq'.'){$State.i++;while($State.i-lt$State.n-and$s[$State.i]-ge'0'-and$s[$State.i]-le'9'){$State.i++}};if($State.i-lt$State.n-and($s[$State.i]-eq'e'-or$s[$State.i]-eq'E')){$State.i++;if($State.i-lt$State.n-and($s[$State.i]-eq'+'-or$s[$State.i]-eq'-')){$State.i++};while($State.i-lt$State.n-and$s[$State.i]-ge'0'-and$s[$State.i]-le'9'){$State.i++}};$v=$s.Substring($start,$State.i-$start);$ic=[Globalization.CultureInfo]::InvariantCulture;if($v-notmatch'[.eE]'){$n=[long]0;if([long]::TryParse($v,[Globalization.NumberStyles]::Integer,$ic,[ref]$n)){return $n}};return [double]::Parse($v,[Globalization.NumberStyles]::Float,$ic) }
function _CanonicalJson_ParseBool { param($State);if($State.i+4-le$State.n-and$State.s.Substring($State.i,4)-eq'true'){$State.i+=4;return $true};if($State.i+5-le$State.n-and$State.s.Substring($State.i,5)-eq'false'){$State.i+=5;return $false};throw "Invalid literal at position $($State.i)." }
function _CanonicalJson_ParseNull { param($State);if($State.i+4-le$State.n-and$State.s.Substring($State.i,4)-eq'null'){$State.i+=4;return $null};throw "Invalid literal at position $($State.i)." }
function Get-CanonicalObjectSha256 { [CmdletBinding()][OutputType([string])]param([Parameter(Mandatory=$true)][AllowNull()]$InputObject,[int]$Depth=20);$json=ConvertTo-CanonicalJson -InputObject $InputObject -Depth $Depth;$enc=New-Object Text.UTF8Encoding($false);$sha=[Security.Cryptography.SHA256]::Create();try{$b=$sha.ComputeHash($enc.GetBytes($json))}finally{$sha.Dispose()};return [BitConverter]::ToString($b).Replace('-','').ToLowerInvariant() }
function Test-CanonicalJsonFile { [CmdletBinding()][OutputType([bool])]param([Parameter(Mandatory=$true)][string]$Path,[int]$Depth=100);$p=(Resolve-Path -LiteralPath $Path -ErrorAction Stop).Path;$bytes=[IO.File]::ReadAllBytes($p);if($bytes.Length-ge3-and$bytes[0]-eq0xEF-and$bytes[1]-eq0xBB-and$bytes[2]-eq0xBF){return $false};$enc=New-Object Text.UTF8Encoding($false,$true);try{$text=$enc.GetString($bytes);$value=ConvertFrom-CanonicalJson -Json $text;$canonical=ConvertTo-CanonicalJson -InputObject $value -Depth $Depth;return ([Convert]::ToBase64String($bytes)-ceq[Convert]::ToBase64String($enc.GetBytes($canonical)))}catch{return $false} }
function Test-AmdCanonicalJsonCrossRuntimeSelfTest { [CmdletBinding()]param();$issues=New-Object 'Collections.Generic.List[string]';$fixture=[pscustomobject][ordered]@{text='日本語 / "quote" / \ slash';array=@(1,$true,$null);float=[double]100;dateText='2026-08-19T12:34:56+09:00';enum=[DayOfWeek]::Monday};$json=$null;$hash=$null;try{$json=ConvertTo-CanonicalJson -InputObject $fixture -Depth 8;$hash=Get-CanonicalObjectSha256 -InputObject $fixture -Depth 8;if($hash-ne'85c339be2fbfe8488cce582d432999278506cf91b815940b428b2b9dc06fbdd0'){$issues.Add(('Python parity SHA-256 mismatch: {0}'-f$hash))|Out-Null};if($json.Contains("`r")-or-not$json.EndsWith("`n")-or$json.EndsWith("`n`n")){$issues.Add('Canonical newline contract failed.')|Out-Null};$parsed=ConvertFrom-CanonicalJson -Json $json;if($parsed.dateText.GetType().FullName-ne'System.String'-or[string]$parsed.enum-ne'Monday'-or@(($parsed.array)).Count-ne3){$issues.Add('Canonical parser round-trip contract failed.')|Out-Null}}catch{$issues.Add($_.Exception.Message)|Out-Null};return [pscustomobject][ordered]@{Status=$(if($issues.Count-eq0){'Pass'}else{'Fail'});PythonReferenceSha256=$hash;Issues=@($issues.ToArray())} }

function Test-AmdOrdinalOrderingSelfTest {
    [CmdletBinding()]
    param()

    $strings=@(Get-AmdOrdinalSortedUniqueStrings -Values @('z','A','a','z',[string][char]0x00E4))
    $objects=@(Get-AmdOrdinalSortedObjectsByStringProperty -Values @(
        [pscustomobject]@{Key='a';Value=2},
        [pscustomobject]@{Key='A';Value=1},
        [pscustomobject]@{Key='z';Value=3}
    ) -PropertyName 'Key')
    $stringOrder=($strings -join '|')
    $objectOrder=(@($objects|ForEach-Object{[string]$_.Key}) -join '|')
    $ok=($stringOrder -ceq ('A|a|z|'+[string][char]0x00E4) -and $objectOrder -ceq 'A|a|z')
    return [pscustomobject][ordered]@{Status=if($ok){'Pass'}else{'Fail'};StringOrder=$stringOrder;ObjectOrder=$objectOrder;Comparer='System.StringComparer.Ordinal'}
}

function Test-AmdThreeToolCommonCoreContract {
    [CmdletBinding()]
    param(
        [string]$ContractPath=(Join-Path (Join-Path (Get-AmdResearchToolkitRoot) 'data') 'current-three-tool-common-core-contract.json'),
        [string]$ScriptPath=$script:SourceScriptPath
    )

    $issues=New-Object 'System.Collections.Generic.List[string]'
    if(-not(Test-Path -LiteralPath $ContractPath -PathType Leaf)){
        return [pscustomobject][ordered]@{Status='Fail';ContractPath=$ContractPath;ExpectedFunctionCount=0;VerifiedFunctionCount=0;Issues=@('Current three-tool common-core contract is missing.')}
    }
    $contract=Read-AmdJsonFile -Path $ContractPath
    $tokens=$null;$parseErrors=$null
    $ast=[System.Management.Automation.Language.Parser]::ParseFile($ScriptPath,[ref]$tokens,[ref]$parseErrors)
    if(@($parseErrors).Count -gt 0){$issues.Add(('Executing script has {0} parse error(s).' -f @($parseErrors).Count))|Out-Null}
    $map=@{}
    foreach($fn in @($ast.FindAll({param($node)$node -is [System.Management.Automation.Language.FunctionDefinitionAst]},$true))){$map[[string]$fn.Name]=$fn}
    $verified=0
    foreach($entry in @($contract.Functions)){
        $name=[string]$entry.Name
        if(-not $map.ContainsKey($name)){$issues.Add(('Common-core function is missing: {0}' -f $name))|Out-Null;continue}
        $normalized=([string]$map[$name].Extent.Text)-replace "`r`n","`n"-replace"`r","`n"
        $actual=Get-AmdStringSha256 -Text $normalized
        if($actual -ne ([string]$entry.Sha256).ToLowerInvariant()){$issues.Add(('Common-core function hash mismatch: {0}' -f $name))|Out-Null;continue}
        $verified++
    }
    if([int]$contract.FunctionCount -ne @($contract.Functions).Count){$issues.Add('Contract FunctionCount does not match its function list.')|Out-Null}
    if($verified -ne [int]$contract.FunctionCount){$issues.Add(('Verified function count mismatch: expected={0}; actual={1}.' -f [int]$contract.FunctionCount,$verified))|Out-Null}
    return [pscustomobject][ordered]@{Status=if($issues.Count -eq 0){'Pass'}else{'Fail'};ContractPath=$ContractPath;ExpectedFunctionCount=[int]$contract.FunctionCount;VerifiedFunctionCount=$verified;Issues=@($issues.ToArray())}
}

function Write-AmdJsonFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][string]$Path,
        [Parameter(Mandatory=$true)][AllowNull()][object]$Value,
        [int]$Depth = 30
    )
    Save-CanonicalJsonFile -InputObject $Value -Path $Path -Depth $Depth
}

function ConvertTo-AmdRepositoryRelativePath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$RelativePath
    )

    $normalized = ($RelativePath -replace '\\', '/').TrimStart('/')
    while ($normalized -match '//') {
        $normalized = $normalized -replace '//', '/'
    }
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
    foreach ($candidate in @((Get-AmdResearchToolkitRoot),(Get-AmdPrivateEvidenceRoot),$HOME,$env:USERPROFILE,$env:TEMP,$env:TMP)) {
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

function Test-AmdPublicPathPropertyName {
    [CmdletBinding()]
    param([AllowNull()][string]$PropertyName)

    if ([string]::IsNullOrWhiteSpace($PropertyName)) { return $false }
    return ($PropertyName -in @(
        'LocalPath','ArtifactPath','ExtractionRoot','ExtractRoot','InstallerPath','ContainerPath','ParentContainer',
        'ArchivePath','ResolvedPath','InfPath','MsiPath','OutputPath','OutputDirectory','EvidenceLogPath','HtmlEvidencePath',
        'TranscriptPath','ScriptPath','SeedPath','LatestEvidencePath','PreviousEvidencePath','EnvironmentEvidencePath',
        'SevenZipPath','ToolRoot','WorkingDirectory','HomeDirectory','EvidenceDirectory','EvidenceZip','EvidenceOutputRoot'
    ))
}

function ConvertTo-NpuPublicRepositoryObject {
    [CmdletBinding()]
    param([AllowNull()][object]$Value)

    if ($null -eq $Value) { return $null }
    if ($Value -is [string]) {
        $text = [string]$Value
        foreach ($pattern in @(Get-AmdPublicForbiddenPatterns)) {
            if ($text -match $pattern) { return $null }
        }
        return $text
    }
    if ($Value -is [ValueType]) { return $Value }

    $privateNames = @(
        'Log','Transcript','StackTrace','Exception','Error','Errors','FetchError','LatestFetchError','PreviousFetchError',
        'DiscoveryDiagnostics','InvocationParameters','UserName','ComputerName','HostName','OSDescription','PowerShellVersion','PSEdition'
    )

    if ($Value -is [System.Collections.IDictionary]) {
        $out = [ordered]@{}
        foreach ($key in $Value.Keys) {
            $name = [string]$key
            if ((Test-AmdPublicPathPropertyName -PropertyName $name) -or $privateNames -contains $name) { continue }
            $candidate = $Value[$key]
            if ($name -eq 'Path' -and $candidate -is [string] -and [System.IO.Path]::IsPathRooted([string]$candidate)) { continue }
            if ($null -eq $candidate) { $out[$name] = $null; continue }
            $converted = ConvertTo-NpuPublicRepositoryObject -Value $candidate
            if ($null -ne $converted) { $out[$name] = $converted }
        }
        return [pscustomobject]$out
    }
    if ($Value -is [System.Collections.IEnumerable]) {
        $items = New-Object 'System.Collections.Generic.List[object]'
        foreach ($item in $Value) {
            if ($null -eq $item) { $items.Add($null) | Out-Null; continue }
            $converted = ConvertTo-NpuPublicRepositoryObject -Value $item
            if ($null -ne $converted) { $items.Add($converted) | Out-Null }
        }
        return ,$items.ToArray()
    }
    if ($Value.PSObject -and $Value.PSObject.Properties) {
        $out = [ordered]@{}
        foreach ($property in $Value.PSObject.Properties) {
            $name = [string]$property.Name
            if ((Test-AmdPublicPathPropertyName -PropertyName $name) -or $privateNames -contains $name) { continue }
            $candidate = $property.Value
            if ($name -eq 'Path' -and $candidate -is [string] -and [System.IO.Path]::IsPathRooted([string]$candidate)) { continue }
            if ($null -eq $candidate) { $out[$name] = $null; continue }
            $converted = ConvertTo-NpuPublicRepositoryObject -Value $candidate
            if ($null -ne $converted) { $out[$name] = $converted }
        }
        return [pscustomobject]$out
    }
    return $Value
}

function Test-NpuPublicRepositorySanitizationLogic {
    [CmdletBinding()]
    param()

    $fixture = [pscustomobject][ordered]@{
        VendorSelector = '/SETFILTERUSB'
        PublicRelativePath = 'catalog/driver-compatibility-matrix.json'
        OptionalNull = $null
        SafeArray = @($null, 'safe')
        PathSafety = [pscustomobject][ordered]@{
            ArchivePath = Join-Path (Get-AmdResearchToolkitRoot) 'work\x\a0001\c0001\fixture.zip'
            OutputDirectory = Join-Path (Get-AmdResearchToolkitRoot) 'work\x\a0001\c0002'
            Status = 'Pass'
        }
        Error = ('failed while reading {0}' -f (Join-Path (Get-AmdPrivateEvidenceRoot) 'runs\fixture.log'))
    }
    $portable = ConvertTo-NpuPublicRepositoryObject -Value $fixture
    $blocked = $false
    foreach ($scalar in @(Get-AmdPublicScalarStrings -Value $portable)) {
        foreach ($pattern in @(Get-AmdPublicForbiddenPatterns)) {
            if ($scalar -match $pattern) { $blocked = $true; break }
        }
        if ($blocked) { break }
    }
    $ok = (
        -not $blocked -and
        [string]$portable.VendorSelector -ceq '/SETFILTERUSB' -and
        [string]$portable.PublicRelativePath -ceq 'catalog/driver-compatibility-matrix.json' -and
        $null -ne $portable.PSObject.Properties['OptionalNull'] -and
        $null -eq $portable.OptionalNull -and
        @($portable.SafeArray).Count -eq 2 -and
        $null -eq @($portable.SafeArray)[0] -and
        [string]@($portable.SafeArray)[1] -ceq 'safe' -and
        [string]$portable.PathSafety.Status -ceq 'Pass' -and
        $null -eq $portable.PathSafety.PSObject.Properties['ArchivePath'] -and
        $null -eq $portable.PathSafety.PSObject.Properties['OutputDirectory'] -and
        $null -eq $portable.PSObject.Properties['Error']
    )
    return [pscustomobject][ordered]@{
        Status = if ($ok) { 'Pass' } else { 'Fail' }
        RuntimePathBlocked = (-not $blocked)
        ArchivePathRemoved = ($null -eq $portable.PathSafety.PSObject.Properties['ArchivePath'])
        OutputDirectoryRemoved = ($null -eq $portable.PathSafety.PSObject.Properties['OutputDirectory'])
        VendorSelectorPreserved = ([string]$portable.VendorSelector -ceq '/SETFILTERUSB')
        PublicRelativePathPreserved = ([string]$portable.PublicRelativePath -ceq 'catalog/driver-compatibility-matrix.json')
        NullPropertyPreserved = ($null -ne $portable.PSObject.Properties['OptionalNull'] -and $null -eq $portable.OptionalNull)
        NullArrayItemPreserved = (@($portable.SafeArray).Count -eq 2 -and $null -eq @($portable.SafeArray)[0])
    }
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
            if(-not(Test-CanonicalJsonFile -Path $file.FullName)){$msg=('public JSON violates the canonical byte contract: {0}' -f $relative);$jsonWhitespaceErrors.Add($msg)|Out-Null;$errors.Add($msg)|Out-Null}
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
    $list=New-Object 'System.Collections.Generic.List[object]';$base=Join-Path (Get-AmdResearchToolkitRoot) 'work\x';if(Test-Path -LiteralPath $base -PathType Container){Remove-Item -LiteralPath $base -Recurse -Force};New-AmdDirectory -Path $base|Out-Null;New-AmdDirectory -Path $EvidenceLogRoot|Out-Null;$artifactOrdinal=0
    foreach($input in @($ArtifactPaths)){
        $artifactOrdinal++
        $artifactSw=[Diagnostics.Stopwatch]::StartNew();$hash=Get-AmdSha256 -Path $input;$format=& $FormatResolver $input
        $stem=ConvertTo-AmdSafeName -Value ([IO.Path]::GetFileNameWithoutExtension($input));$artifactPathId=('a{0:D4}' -f $artifactOrdinal);$dest=Get-AmdShortExtractionPath -ArtifactOrdinal $artifactOrdinal -ExtractionBasePath $base;New-AmdDirectory -Path $dest|Out-Null
        $artifactLogRoot=Join-Path $EvidenceLogRoot ('{0}-{1}' -f $stem,$hash.Substring(0,12));New-AmdDirectory -Path $artifactLogRoot|Out-Null
        Write-AmdStep ('Static 7-Zip extraction: {0} ({1}); max depth={2}' -f [IO.Path]::GetFileName($input),$format,$MaxDepth)
        $queue=New-Object Collections.Queue;$queue.Enqueue([pscustomobject]@{Path=(Resolve-Path -LiteralPath $input).Path;Depth=0;Parent=$null})
        $seen=@{};$containers=New-Object 'System.Collections.Generic.List[object]';$errors=New-Object 'System.Collections.Generic.List[string]';$seq=0
        while($queue.Count -gt 0){
            $entry=$queue.Dequeue();$containerPath=[string]$entry.Path;$depth=[int]$entry.Depth;if($depth -gt $MaxDepth){continue}
            try{$containerHash=Get-AmdSha256 -Path $containerPath}catch{$errors.Add(('Hash failed for {0}: {1}' -f $containerPath,$_.Exception.Message))|Out-Null;continue}
            if($seen.ContainsKey($containerHash)){continue};$seen[$containerHash]=$true;$seq++
            $leaf=ConvertTo-AmdSafeName -Value ([IO.Path]::GetFileName($containerPath));$containerPathId=('c{0:D4}' -f $seq);$out=Get-AmdShortExtractionPath -ArtifactOrdinal $artifactOrdinal -ContainerOrdinal $seq -ExtractionBasePath $base;New-AmdDirectory -Path $out|Out-Null
            $probe=Get-AmdSevenZipArchiveProbe -SevenZipPath $SevenZipExecutable -Path $containerPath;$status='ExtractionFailed';$exitCode=$null;$errorText=$null;$outputText=@();$archivePathSafety=$null
            if(-not $probe.ProbeSucceeded -or -not $probe.ContainerLike){$errorText=if($probe.Error){[string]$probe.Error}else{('7-Zip did not classify this object as an extractable container (type={0}).' -f $probe.ArchiveType)}}
            else{try{$archivePathSafety=Get-AmdArchiveExtractionPathAssessment -SevenZipPath $SevenZipExecutable -ArchivePath $containerPath -OutputDirectory $out;if([string]$archivePathSafety.Status -ne 'Pass'){$status='ExtractionBlockedPathSafety';$errorText=('Archive path-safety preflight blocked extraction: {0}' -f (@($archivePathSafety.Issues)-join ' | '))}else{$outputText=@(& $SevenZipExecutable 'x' '-y' "-o$out" $containerPath 2>&1|ForEach-Object{[string]$_});$exitCode=$LASTEXITCODE;if($exitCode -eq 0){$status='Extracted'}elseif($exitCode -eq 1){$status='ExtractedWithWarnings'}else{$errorText=('7-Zip exit code {0}' -f $exitCode)}}}catch{$errorText=$_.Exception.Message}}
            if($errorText){$errors.Add(('{0}: {1}' -f $containerPath,$errorText))|Out-Null}
            $surface=& $SurfaceProbe $out;$logPath=Join-Path $artifactLogRoot ('{0:D3}-d{1}-7zip-{2}.log' -f $seq,$depth,$containerHash.Substring(0,12))
            $log=@(('Container      : {0}' -f $containerPath),('SHA-256       : {0}' -f $containerHash),('Depth          : {0}' -f $depth),('Archive type   : {0}' -f $probe.ArchiveType),('Status         : {0}' -f $status),('7-Zip exit    : {0}' -f $exitCode),('Analysis reached: {0}' -f [bool]$surface.Reached),('Error          : {0}' -f $errorText),'')+@($outputText);Write-AmdUtf8NoBom -Path $logPath -Text ($log -join [Environment]::NewLine)
            $containers.Add([pscustomobject][ordered]@{ContainerPathId=$containerPathId;ContainerPath=$containerPath;OriginalContainerFileName=[IO.Path]::GetFileName($containerPath);ContainerSha256=$containerHash;ContainerFormat=(& $FormatResolver $containerPath);Depth=$depth;ParentContainer=$entry.Parent;OutputDirectory=$out;ExtractorType='7-Zip';Status=$status;SevenZipExitCode=$exitCode;ArchiveProbe=$probe;PathSafety=$archivePathSafety;AnalysisSurface=$surface;Error=$errorText;EvidenceLogPath=$logPath})|Out-Null
            if($status -in @('ExtractionFailed','ExtractionBlockedPathSafety') -or $depth -ge $MaxDepth){continue}
            foreach($f in @(Get-ChildItem -LiteralPath $out -File -Recurse -ErrorAction SilentlyContinue)){if(& $NestedArtifactPredicate $f.FullName $SevenZipExecutable){$queue.Enqueue([pscustomobject]@{Path=$f.FullName;Depth=$depth+1;Parent=$containerPath})}}
        }
        $allFiles=@(Get-ChildItem -LiteralPath $dest -File -Recurse -ErrorAction SilentlyContinue);$infs=@($allFiles|Where-Object{$_.Extension -ieq '.inf'});$surfaceFinal=& $SurfaceProbe $dest;$failed=@($containers.ToArray()|Where-Object{$_.Status -in @('ExtractionFailed','ExtractionBlockedPathSafety')})
        $releaseStatus=if($containers.Count -eq 0){'ExtractionFailed'}elseif($surfaceFinal.Reached -and $failed.Count -eq 0){'ExtractionComplete'}elseif($surfaceFinal.Reached){'ExtractedWithErrors'}else{'PartialExtraction'}
        if(-not $surfaceFinal.Reached){$errors.Add('No device-specific analysis surface was discovered after bounded recursive extraction.')|Out-Null};$artifactSw.Stop()
        $list.Add([pscustomobject][ordered]@{ArtifactPathId=$artifactPathId;ArtifactPath=$input;FileName=[IO.Path]::GetFileName($input);ArtifactFormat=$format;Sha256=$hash;ExtractRoot=$dest;Status=$releaseStatus;FileCount=$allFiles.Count;InfFileCount=$infs.Count;NpuInfFileCount=if($surfaceFinal.PSObject.Properties['NpuInfCount']){[int]$surfaceFinal.NpuInfCount}else{0};ContainerCount=$containers.Count;Containers=@($containers.ToArray());Error=if($errors.Count){$errors -join ' | '}else{$null}})|Out-Null
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
    param([Parameter(Mandatory=$true)][string]$Name,[Parameter(Mandatory=$true)][ValidateSet('PASS','FAIL','BLOCKED','SKIPPED','INTERRUPTED')][string]$Status,[Parameter(Mandatory=$true)][TimeSpan]$Elapsed)
    $color=switch($Status){'PASS'{'Green'}'FAIL'{'Red'}'BLOCKED'{'Yellow'}'SKIPPED'{'DarkGray'}'INTERRUPTED'{'Yellow'}default{'Gray'}}
    Write-Host (' STAGE {0,-20} -> {1,-8} elapsed: {2}' -f $Name,$Status,(Format-AmdElapsed $Elapsed)) -ForegroundColor $color
    $script:AmdCurrentStageStart=$null;$script:AmdCurrentStageName=$null
}

function Write-AmdRunTimingSummary {
    [CmdletBinding()]
    param([Parameter(Mandatory=$true)][object]$Assessment)
    $totalElapsed=(Get-Date)-$script:AmdRunStartTime;Write-Host '';Write-Host ('='*72) -ForegroundColor Magenta;Write-Host ' RUN TIMING SUMMARY' -ForegroundColor Magenta;Write-Host ('='*72) -ForegroundColor Magenta
    Write-Host (' Started at      : {0}' -f $script:AmdRunStartTime.ToString('yyyy-MM-dd HH:mm:ss'));Write-Host (' Current/ended   : {0}' -f (Get-Date).ToString('yyyy-MM-dd HH:mm:ss'));Write-Host (' Total elapsed   : {0}' -f (Format-AmdElapsed $totalElapsed)) -ForegroundColor Cyan
    if($script:AmdStageResults.Count -gt 0){Write-Host '';Write-Host ' Stage timings:' -ForegroundColor Cyan;foreach($t in $script:AmdStageResults){$span=[TimeSpan]::FromMilliseconds([double]$t.DurationMilliseconds);$color=switch([string]$t.Status){'PASS'{'Green'}'FAIL'{'Red'}'BLOCKED'{'Yellow'}'SKIPPED'{'DarkGray'}'INTERRUPTED'{'Yellow'}default{'Gray'}};Write-Host ('   {0,-18} {1,-8} {2,12}' -f $t.Name,$t.Status,(Format-AmdElapsed $span)) -ForegroundColor $color}}
    Write-Host '';Write-Host (' Assessment      : {0}' -f $Assessment.OverallStatus);Write-Host (' Exit code       : {0}' -f $Assessment.ExitCode);Write-Host ('='*72) -ForegroundColor Magenta
}

function Start-AmdResearchEvidenceSession {
    [CmdletBinding()]
    param([string]$OutputRoot,[string]$Label,[ValidateSet('ZipOnly','ZipAndDirectory')][string]$EvidenceRetention='ZipOnly',[Parameter(Mandatory=$true)][object]$InvocationParameters)
    $toolRoot=Get-AmdResearchToolkitRoot;$OutputRoot=Resolve-AmdEvidenceOutputRoot -RequestedPath $OutputRoot;New-AmdDirectory -Path $OutputRoot|Out-Null;$runsRoot=Join-Path $OutputRoot 'runs';New-AmdDirectory -Path $runsRoot|Out-Null
    $platform=Get-AmdPlatformInfo;$stamp=(Get-Date).ToUniversalTime().ToString('yyyyMMddTHHmmssZ');$pf=ConvertTo-AmdEvidenceSafeFragment -Value ([string]$platform.PlatformFamily);$lf=Get-AmdEvidenceSafeLabel -Value $Label
    $base=if($lf){'{0}_{1}_{2}_{3}' -f $script:AmdResearchEvidencePrefix,$stamp,$pf,$lf}else{'{0}_{1}_{2}' -f $script:AmdResearchEvidencePrefix,$stamp,$pf};$workId='r{0}-{1}' -f $stamp,([Guid]::NewGuid().ToString('N').Substring(0,8));$dir=Join-Path $runsRoot $workId;$zip=Join-Path $OutputRoot ($base+'.zip')
    foreach($sub in @($dir,(Join-Path $dir 'logs'),(Join-Path $dir 'errors'),(Join-Path $dir 'snapshot'))){New-AmdDirectory -Path $sub|Out-Null}
    $scriptHash=$null;try{if(Test-Path -LiteralPath $script:SourceScriptPath -PathType Leaf){$scriptHash=Get-AmdSha256 -Path $script:SourceScriptPath}}catch{}
    $hostExecutionContext=Get-AmdWindowsExecutionContext -PlatformInfo $platform
    $ctx=[pscustomobject][ordered]@{SchemaVersion=$script:AmdResearchEvidenceSchemaVersion;ToolkitVersion=$script:AmdResearchToolkitVersion;RunId=$base;StartedAtUtc=Get-AmdUtcTimestamp;ToolDisplayName='AMD NPU Driver Research Toolkit';EvidenceRoot=$OutputRoot;EvidenceDirectory=$dir;ZipPath=$zip;ZipSha256Path=$zip+'.sha256';LatestEvidencePointerPath=Join-Path $OutputRoot 'LATEST-EVIDENCE.txt';EvidenceRetention=$EvidenceRetention;EvidenceDirectoryRetained=$true;ArchiveCreated=$false;ZipSha256=$null;Platform=$platform;ExecutionContext=$hostExecutionContext;PowerShellVersion=$PSVersionTable.PSVersion.ToString();PSEdition=if($PSVersionTable.PSEdition){[string]$PSVersionTable.PSEdition}else{'Desktop'};ScriptPath=$script:SourceScriptPath;ScriptSha256=$scriptHash;InvocationParameters=$InvocationParameters;ArchiveCapability=$null;TranscriptPath=Join-Path (Join-Path $dir 'logs') 'console-transcript.txt';TranscriptStarted=$false}
    $script:AmdEvidenceContext=$ctx;$script:EvidenceContext=$ctx;Write-AmdJsonFile -Path (Join-Path $dir 'run-context.json') -Value $ctx
    try{$ctx.ArchiveCapability=Test-AmdEvidenceArchiveCapability -EvidenceDirectory $dir}catch{$ctx.ArchiveCapability=[pscustomobject][ordered]@{CollectedAtUtc=Get-AmdUtcTimestamp;ProbeAttempted=$true;ProbeSucceeded=$false;ProbeArchiveBytes=0;Error=$_.Exception.Message}}
    Write-AmdJsonFile -Path (Join-Path $dir 'archive-capability.json') -Value $ctx.ArchiveCapability
    try{Start-Transcript -LiteralPath $ctx.TranscriptPath -Force -ErrorAction Stop|Out-Null;$script:AmdTranscriptStarted=$true;$script:TranscriptStarted=$true;$ctx.TranscriptStarted=$true}catch{$script:AmdTranscriptStarted=$false;$script:TranscriptStarted=$false;$ctx.TranscriptStarted=$false;Write-AmdUtf8NoBom -Path (Join-Path (Join-Path $dir 'logs') 'transcript-start-error.txt') -Text $_.Exception.ToString()}
    Write-AmdJsonFile -Path (Join-Path $dir 'run-context.json') -Value $ctx
    Start-AmdDiagnosticTrace -EvidenceDirectory $dir
    Write-AmdDiagnosticEvent -EventName 'EvidenceSessionStarted' -Level 'Info' -FunctionName 'Start-AmdResearchEvidenceSession' -Step 'Initialize' -Data @{ArchiveCapability=$ctx.ArchiveCapability;EvidenceRetention=$ctx.EvidenceRetention}
    return $ctx
}

function Start-AmdEmergencyEvidenceSession {
    [CmdletBinding()]
    param([string]$PreferredOutputRoot,[string]$Label,[ValidateSet('ZipOnly','ZipAndDirectory')][string]$EvidenceRetention='ZipOnly',[Parameter(Mandatory=$true)][object]$InvocationParameters,[string]$BootstrapError)
    if($null -ne $script:AmdEvidenceContext){return $script:AmdEvidenceContext}
    $root=Resolve-AmdEvidenceOutputRoot -RequestedPath $PreferredOutputRoot;New-AmdDirectory -Path $root|Out-Null;$runsRoot=Join-Path $root 'runs';New-AmdDirectory -Path $runsRoot|Out-Null
    $stamp=(Get-Date).ToUniversalTime().ToString('yyyyMMddTHHmmssZ');$lf=Get-AmdEvidenceSafeLabel -Value $Label;$base=if($lf){'{0}_{1}_BootstrapFatal_{2}' -f $script:AmdResearchEvidencePrefix,$stamp,$lf}else{'{0}_{1}_BootstrapFatal' -f $script:AmdResearchEvidencePrefix,$stamp};$workId='r{0}-{1}' -f $stamp,([Guid]::NewGuid().ToString('N').Substring(0,8));$dir=Join-Path $runsRoot $workId;$zip=Join-Path $root ($base+'.zip')
    foreach($sub in @($dir,(Join-Path $dir 'logs'),(Join-Path $dir 'errors'),(Join-Path $dir 'snapshot'))){New-AmdDirectory -Path $sub|Out-Null}
    $hostExecutionContext=Get-AmdWindowsExecutionContext
    $ctx=[pscustomobject][ordered]@{SchemaVersion=$script:AmdResearchEvidenceSchemaVersion;ToolkitVersion=$script:AmdResearchToolkitVersion;RunId=$base;StartedAtUtc=Get-AmdUtcTimestamp;ToolDisplayName=$script:AmdResearchDisplayName;EvidenceRoot=$root;EvidenceDirectory=$dir;ZipPath=$zip;ZipSha256Path=$zip+'.sha256';LatestEvidencePointerPath=Join-Path $root 'LATEST-EVIDENCE.txt';EvidenceRetention=$EvidenceRetention;EvidenceDirectoryRetained=$true;ArchiveCreated=$false;ZipSha256=$null;Platform=[pscustomobject][ordered]@{PlatformFamily='Unknown';OSDescription='UnavailableDuringBootstrap';ProcessArchitecture='Unknown';PowerShellArchitecture='Unknown'};ExecutionContext=$hostExecutionContext;PowerShellVersion=$PSVersionTable.PSVersion.ToString();PSEdition=if($PSVersionTable.PSEdition){[string]$PSVersionTable.PSEdition}else{'Desktop'};ScriptPath=$script:SourceScriptPath;ScriptSha256=if(Test-Path -LiteralPath $script:SourceScriptPath){Get-AmdSha256 -Path $script:SourceScriptPath}else{$null};InvocationParameters=$InvocationParameters;TranscriptPath=Join-Path (Join-Path $dir 'logs') 'console-transcript.txt';TranscriptStarted=$false;BootstrapFallback=$true}
    $script:AmdEvidenceContext=$ctx;$script:EvidenceContext=$ctx;Write-AmdJsonFile -Path (Join-Path $dir 'run-context.json') -Value $ctx;Start-AmdDiagnosticTrace -EvidenceDirectory $dir;$lines=@('Emergency evidence session created because normal evidence bootstrap failed.',('OccurredUtc: {0}' -f (Get-AmdUtcTimestamp)));if($BootstrapError){$lines+=('BootstrapError: '+$BootstrapError)};Write-AmdUtf8NoBom -Path $ctx.TranscriptPath -Text ($lines -join [Environment]::NewLine);Write-AmdDiagnosticEvent -EventName 'EmergencyEvidenceSessionStarted' -Level 'Error' -FunctionName 'Start-AmdEmergencyEvidenceSession' -Step 'BootstrapFallback' -Data @{BootstrapError=$BootstrapError};return $ctx
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
    param(
        [Parameter(Mandatory=$true)][string]$Name,
        [scriptblock]$Body,
        [string]$BlockedReason,
        [string]$SkippedReason
    )

    $script:AmdStageOrdinal++
    $script:StageOrdinal=$script:AmdStageOrdinal
    $script:AmdCurrentStageName=$Name
    Write-AmdStageHeader -Name $Name -Ordinal $script:AmdStageOrdinal -Total $script:AmdResolvedStageCount

    $started=[DateTime]::UtcNow
    Write-AmdDiagnosticEvent -EventName 'StageStarted' -Level 'Info' -FunctionName 'Invoke-AmdTrackedStage' -Step $Name -Data @{Ordinal=$script:AmdStageOrdinal;Total=$script:AmdResolvedStageCount;BlockedReason=$BlockedReason;SkippedReason=$SkippedReason}
    $sw=[Diagnostics.Stopwatch]::StartNew()
    $status=if($BlockedReason){'BLOCKED'}elseif($SkippedReason){'SKIPPED'}elseif($null -eq $Body){'FAIL'}else{'RUNNING'}
    $errorText=$null
    $errorFile=$null
    $output=$null
    $reason=$null
    $entry=$null

    try {
        if($status -eq 'BLOCKED'){
            $reason=$BlockedReason
            Write-AmdCaution ('Stage {0} blocked: {1}' -f $Name,$BlockedReason)
        }
        elseif($status -eq 'SKIPPED'){
            $reason=$SkippedReason
            Write-AmdSkip ('Stage {0} skipped: {1}' -f $Name,$SkippedReason)
        }
        elseif($status -eq 'FAIL'){
            $errorText='Tracked stage body was not supplied.'
            Write-AmdFail ('Stage {0} failed: {1}' -f $Name,$errorText)
        }
        else {
            $output=& $Body
            $status='PASS'
            Write-AmdDiagnosticEvent -EventName 'StageBodyCompleted' -Level 'Info' -FunctionName 'Invoke-AmdTrackedStage' -Step $Name -Data @{Status='PASS'}
        }
    }
    catch {
        $status='FAIL'
        $errorText=$_.Exception.Message
        Write-AmdDiagnosticEvent -EventName 'StageFailure' -Level 'Error' -FunctionName 'Invoke-AmdTrackedStage' -Step $Name -Data @{Error=$errorText;Exception=$_.Exception.ToString();ScriptStack=$_.ScriptStackTrace}
        $null=Write-AmdFailureSnapshot -Scope ('stage-'+$Name) -ErrorRecord $_ -AdditionalData @{Stage=$Name}
        if($script:AmdEvidenceContext){
            $safeName=ConvertTo-AmdEvidenceSafeFragment -Value $Name
            $errorFile=Join-Path (Join-Path $script:AmdEvidenceContext.EvidenceDirectory 'errors') ('stage-{0}.txt' -f $safeName)
            $detail=@(
                ('Stage      : {0}' -f $Name),
                ('OccurredUtc: {0}' -f (Get-AmdUtcTimestamp)),
                ('Exception  : {0}' -f $_.Exception.ToString()),
                ('ScriptStack: {0}' -f $_.ScriptStackTrace)
            )-join[Environment]::NewLine
            Write-AmdUtf8NoBom -Path $errorFile -Text $detail
        }
        Write-AmdFail ('Stage {0} failed: {1}' -f $Name,$errorText)
    }
    finally {
        if($status -eq 'RUNNING'){
            $status='INTERRUPTED'
            $reason='Stage execution was interrupted before normal completion.'
            if([string]::IsNullOrWhiteSpace($errorText)){$errorText=$reason}
        }
        $sw.Stop()
        $summary='Completed'
        if($null -ne $output -and $output.PSObject.Properties['Summary']){$summary=[string]$output.Summary}
        $entry=[pscustomobject][ordered]@{
            Name=$Name
            Status=$status
            StartedAtUtc=$started.ToString('o')
            CompletedAtUtc=Get-AmdUtcTimestamp
            DurationMilliseconds=[int64]$sw.ElapsedMilliseconds
            Reason=$reason
            Message=if($errorText){$errorText}elseif($reason){$reason}else{$summary}
            Error=$errorText
            ErrorEvidencePath=$errorFile
        }
        $script:AmdStageResults.Add($entry)|Out-Null
        Write-AmdDiagnosticEvent -EventName 'StageCompleted' -Level $(if($status -eq 'PASS'){'Info'}elseif($status -in @('BLOCKED','SKIPPED','INTERRUPTED')){'Warning'}else{'Error'}) -FunctionName 'Invoke-AmdTrackedStage' -Step $Name -Data $entry
        Write-AmdStageResultsEvidence
        Write-AmdStageFooter -Name $Name -Status $status -Elapsed $sw.Elapsed
        $script:AmdCurrentStageName=$null
    }

    return [pscustomobject][ordered]@{Success=($status -eq 'PASS');Status=$status;Output=$output;Reason=$reason;Error=$errorText}
}

function Get-AmdRunAssessment {
    [CmdletBinding()]
    param([string[]]$ResolvedStages=@())
    $stages=@($script:AmdStageResults.ToArray());$failed=@($stages|Where-Object{$_.Status -eq 'FAIL'});$blocked=@($stages|Where-Object{$_.Status -eq 'BLOCKED'});$skipped=@($stages|Where-Object{$_.Status -eq 'SKIPPED'});$interrupted=@($stages|Where-Object{$_.Status -eq 'INTERRUPTED'});$items=New-Object 'System.Collections.Generic.List[object]'
    if(@($ResolvedStages).Count -eq 0){$items.Add([pscustomobject]@{Name='Bootstrap';Status='REVIEW';Detail='stage resolution did not complete; evidence was finalized from bootstrap state'})|Out-Null}
    $stageStatus=if(@($ResolvedStages).Count -eq 0){'NOT_ASSESSED'}elseif($interrupted.Count -gt 0){'INTERRUPTED'}elseif(-not $script:TopLevelFatalError -and $failed.Count -eq 0 -and $blocked.Count -eq 0){'PASS'}else{'REVIEW'}
    $stageDetail=if(@($ResolvedStages).Count -eq 0){'no stage was resolved or executed before bootstrap termination'}elseif($interrupted.Count -gt 0){'run interrupted during: '+(@($interrupted|ForEach-Object{$_.Name})-join ', ') }else{('pass={0}; fail={1}; blocked={2}; skipped={3}; interrupted={4}; fatal={5}' -f @($stages|Where-Object{$_.Status -eq 'PASS'}).Count,$failed.Count,$blocked.Count,$skipped.Count,$interrupted.Count,[bool]$script:TopLevelFatalError)}
    $items.Add([pscustomobject]@{Name='StageExecution';Status=$stageStatus;Detail=$stageDetail})|Out-Null
    foreach($extra in @(Get-NpuRunAssessmentExtensions -ResolvedStages $ResolvedStages)){$items.Add($extra)|Out-Null}
    if($script:TopLevelFatalError){return [pscustomobject][ordered]@{SchemaVersion='amd-research-run-assessment/1.0';OverallStatus='FatalError';ExitCode=1;FailedOrBlockedStageCount=($failed.Count+$blocked.Count);Items=@($items.ToArray());FatalError=$script:TopLevelFatalError}}
    $review=($failed.Count -gt 0 -or $blocked.Count -gt 0 -or @($items.ToArray()|Where-Object{$_.Status -eq 'REVIEW'}).Count -gt 0)
    $overall=if($interrupted.Count -gt 0){'Interrupted'}elseif($review){'ReviewRequired'}else{'Pass'}
    return [pscustomobject][ordered]@{SchemaVersion='amd-research-run-assessment/1.0';OverallStatus=$overall;ExitCode=if($overall -eq 'Interrupted'){130}elseif($review){2}else{0};FailedOrBlockedStageCount=($failed.Count+$blocked.Count);InterruptedStageCount=$interrupted.Count;Items=@($items.ToArray());FatalError=$null}
}

function Write-AmdAssessmentConsoleReport {
    [CmdletBinding()]
    param([Parameter(Mandatory=$true)][object]$Assessment,[string]$EvidenceDirectory,[string]$ZipPath,[switch]$SkipPublicExport)
    Write-Host '';Write-Host ('='*100) -ForegroundColor Cyan;Write-Host (' {0} - FINAL ASSESSMENT' -f $script:AmdResearchDisplayName) -ForegroundColor Cyan;Write-Host ('='*100) -ForegroundColor Cyan
    foreach($item in @($Assessment.Items)){$color=if($item.Status -eq 'PASS'){'Green'}elseif($item.Status -eq 'SKIP'){'DarkGray'}else{'Yellow'};Write-Host (('[{0}]' -f $item.Status).PadRight(10)) -NoNewline -ForegroundColor $color;Write-Host ('{0,-30} {1}' -f $item.Name,$item.Detail)}
    Write-Host ('-'*100) -ForegroundColor DarkGray;Write-Host ('FINAL RESULT  : {0}' -f $Assessment.OverallStatus);Write-Host ('EXIT CODE     : {0}' -f $Assessment.ExitCode);Write-Host ('TOTAL ELAPSED : {0}' -f (Format-AmdElapsed ((Get-Date)-$script:AmdRunStartTime))) -ForegroundColor Cyan;if($ZipPath){Write-Host ('EVIDENCE ZIP PLANNED : {0}' -f $ZipPath)};if($EvidenceDirectory){Write-Host ('EVIDENCE WORK DIR    : {0}' -f $EvidenceDirectory)};if(-not $SkipPublicExport -and $script:ResolvedPublicOutputRoot){Write-Host ('PUBLIC ROOT   : {0}' -f $script:ResolvedPublicOutputRoot)};Write-Host ('='*100) -ForegroundColor Cyan
}

function Finalize-AmdResearchEvidenceSession {
    [CmdletBinding()]
    param([string[]]$ResolvedStages=@(),[switch]$SkipArchive,[switch]$IncludePackages)
    $assessment=Get-AmdRunAssessment -ResolvedStages $ResolvedStages;if($null -eq $script:AmdEvidenceContext){return $assessment};$ctx=$script:AmdEvidenceContext;$dir=$ctx.EvidenceDirectory;$errors=New-Object 'System.Collections.Generic.List[string]'
    try{Write-AmdStageResultsEvidence;Write-AmdJsonFile -Path (Join-Path $dir 'assessment.json') -Value $assessment;$summary=[pscustomobject][ordered]@{SchemaVersion='amd-npu-driver-research-run-summary/1.2';ToolkitVersion=$script:AmdResearchToolkitVersion;RunId=$ctx.RunId;StartedAtUtc=$ctx.StartedAtUtc;CompletedAtUtc=Get-AmdUtcTimestamp;TotalDurationMilliseconds=[int64]((Get-Date)-$script:AmdRunStartTime).TotalMilliseconds;TotalDuration=Format-AmdElapsed ((Get-Date)-$script:AmdRunStartTime);StageTimings=@($script:AmdStageResults.ToArray());OverallStatus=$assessment.OverallStatus;ExitCode=$assessment.ExitCode;ScriptSha256=$ctx.ScriptSha256;EvidenceRoot=$ctx.EvidenceRoot;EvidenceDirectory=$ctx.EvidenceDirectory;EvidenceZip=if($SkipArchive){$null}else{$ctx.ZipPath};EvidenceRetention=$ctx.EvidenceRetention;EvidenceStoragePolicy='ToolLocalCanonicalRootOnly/1.0';InputCount=@($script:RunInputs).Count;Inputs=@($script:RunInputs|ForEach-Object{[pscustomobject][ordered]@{FileName=[IO.Path]::GetFileName($_);Sha256=if(Test-Path -LiteralPath $_){Get-AmdSha256 -Path $_}else{$null}}});IncludePackagesInEvidence=[bool]$IncludePackages;RawWorkDirectoryIncluded=$false;Safety=[pscustomobject][ordered]@{VendorExecutablesExecuted=$false;VendorPayloadModified=$false}};Write-AmdJsonFile -Path (Join-Path $dir 'run-summary.json') -Value $summary;Invoke-NpuEvidenceSnapshot -EvidenceDirectory $dir -IncludePackages:$IncludePackages}catch{$errors.Add(('summary/snapshot finalization: {0}' -f $_.Exception.ToString()))|Out-Null}
    Stop-AmdDiagnosticTrace -Assessment $assessment
    if($script:AmdTranscriptStarted -or $script:TranscriptStarted){try{Stop-Transcript|Out-Null}catch{$errors.Add(('transcript stop: {0}' -f $_.Exception.Message))|Out-Null};$script:AmdTranscriptStarted=$false;$script:TranscriptStarted=$false}
    if($errors.Count -gt 0){
        try{Write-AmdUtf8NoBom -Path (Join-Path (Join-Path $dir 'errors') 'evidence-finalization-errors.txt') -Text ($errors -join ([Environment]::NewLine+[Environment]::NewLine))}catch{}
        throw('Evidence finalization failed closed before archive creation: '+($errors -join ' | '))
    }
    try{$manifestFiles=New-Object 'System.Collections.Generic.List[object]';$evidenceFileMap=@{};foreach($f in @(Get-ChildItem -LiteralPath $dir -File -Recurse -Force)){if($f.Name -eq 'evidence-manifest.json'){continue};$rel=(ConvertTo-AmdRepositoryRelativePath -RelativePath (Get-AmdRelativePath -BasePath $dir -Path $f.FullName));if($evidenceFileMap.ContainsKey($rel)){throw('Duplicate evidence relative path: {0}' -f $rel)};$evidenceFileMap[$rel]=$f};foreach($rel in @(Get-AmdOrdinalSortedUniqueStrings -Values @($evidenceFileMap.Keys))){$f=$evidenceFileMap[$rel];$manifestFiles.Add([pscustomobject][ordered]@{Path=$rel;Length=[int64]$f.Length;Sha256=Get-AmdSha256 -Path $f.FullName})|Out-Null};Write-AmdJsonFile -Path (Join-Path $dir 'evidence-manifest.json') -Value ([pscustomobject][ordered]@{SchemaVersion='amd-npu-driver-research-evidence-manifest/1.2';ToolkitVersion=$script:AmdResearchToolkitVersion;GeneratedAtUtc=Get-AmdUtcTimestamp;Files=@($manifestFiles.ToArray())})}catch{Write-Warning ('Evidence manifest creation failed: {0}' -f $_.Exception.Message)}
    if(-not $SkipArchive){try{$archive=New-AmdZipFromDirectory -SourceDirectory $dir -DestinationZip $ctx.ZipPath;if($null -eq $archive -or $archive.Length -le 0){throw 'Evidence archive is empty.'};$integrity=Test-AmdEvidenceZipIntegrity -Path $ctx.ZipPath;if($integrity.Status -ne 'Pass'){throw('Evidence ZIP integrity verification failed: {0}' -f $integrity.Error)};$ctx.ZipSha256=Write-AmdEvidenceSha256File -ZipPath $ctx.ZipPath -Sha256Path $ctx.ZipSha256Path;$ctx.ArchiveCreated=$true}catch{$ctx.ArchiveCreated=$false;$ctx.EvidenceDirectoryRetained=(Test-Path -LiteralPath $ctx.EvidenceDirectory -PathType Container);if($ctx.EvidenceDirectoryRetained){Write-AmdUtf8NoBom -Path (Join-Path $ctx.EvidenceDirectory 'archive-error.txt') -Text $_.Exception.ToString()};Write-Warning ('Evidence archive creation failed: {0}' -f $_.Exception.Message);Write-Warning ('Evidence directory remains available: {0}' -f $ctx.EvidenceDirectory)};if($ctx.ArchiveCreated){if($ctx.EvidenceRetention -eq 'ZipOnly'){try{Remove-Item -LiteralPath $ctx.EvidenceDirectory -Recurse -Force -ErrorAction Stop;$ctx.EvidenceDirectoryRetained=$false}catch{$ctx.EvidenceDirectoryRetained=$true;Write-Warning ('Verified ZIP was retained, but the raw evidence directory could not be removed: {0}' -f $_.Exception.Message)}};try{Write-AmdLatestEvidencePointer -Context $ctx -Assessment $assessment}catch{Write-Warning ('Verified ZIP was retained, but LATEST-EVIDENCE.txt could not be updated: {0}' -f $_.Exception.Message)}}}
    Write-AmdEvidenceCompletionBanner -Context $ctx
    return $assessment
}

function Invoke-AmdEmergencyEvidenceFinalization {
    [CmdletBinding()]
    param([AllowNull()][object]$ErrorRecord,[switch]$SkipArchive)
    $ctx=$script:AmdEvidenceContext;if($null -eq $ctx){return $null}
    if($script:AmdTranscriptStarted -or $script:TranscriptStarted){try{Stop-Transcript|Out-Null}catch{};$script:AmdTranscriptStarted=$false;$script:TranscriptStarted=$false}
    try{
        $errorsDirectory=Join-Path $ctx.EvidenceDirectory 'errors';[void][IO.Directory]::CreateDirectory($errorsDirectory)
        $errorText=if($null -ne $ErrorRecord){$ErrorRecord.ToString()}else{'Normal evidence finalization failed without an ErrorRecord.'}
        $content=@('AMD DRIVER RESEARCH EMERGENCY EVIDENCE FINALIZATION',('OccurredUtc : {0}' -f (Get-AmdUtcTimestamp)),('RunId       : {0}' -f $ctx.RunId),('Reason      : {0}' -f $errorText),'The normal evidence finalizer failed. This emergency archive preserves the raw evidence directory and is not a PASS qualification artifact.')-join[Environment]::NewLine
        [IO.File]::WriteAllText((Join-Path $errorsDirectory 'emergency-finalization.txt'),$content,(New-Object Text.UTF8Encoding($false)))
    }catch{Write-Warning ('Emergency finalization could not write its diagnostic file: {0}' -f $_.Exception.Message)}
    if($SkipArchive){return $null}
    try{
        $archive=New-AmdZipFromDirectory -SourceDirectory $ctx.EvidenceDirectory -DestinationZip $ctx.ZipPath;if($null -eq $archive -or $archive.Length -le 0){throw 'Emergency evidence archive is empty.'}
        $integrity=Test-AmdEvidenceZipIntegrity -Path $ctx.ZipPath;if([string]$integrity.Status -ne 'Pass'){throw('Emergency evidence ZIP integrity verification failed: {0}' -f [string]$integrity.Error)}
        $ctx.ZipSha256=Write-AmdEvidenceSha256File -ZipPath $ctx.ZipPath -Sha256Path $ctx.ZipSha256Path;$ctx.ArchiveCreated=$true;$ctx.EvidenceDirectoryRetained=$true
        Write-Warning ('Emergency evidence ZIP created: {0}' -f $ctx.ZipPath);Write-Warning ('Raw evidence was retained for recovery: {0}' -f $ctx.EvidenceDirectory)
        return [pscustomobject][ordered]@{Status='EmergencyArchiveCreated';ZipPath=$ctx.ZipPath;ZipSha256=$ctx.ZipSha256;EvidenceDirectory=$ctx.EvidenceDirectory}
    }catch{
        $ctx.ArchiveCreated=$false;$ctx.EvidenceDirectoryRetained=(Test-Path -LiteralPath $ctx.EvidenceDirectory -PathType Container)
        Write-Warning ('Emergency evidence ZIP creation failed: {0}' -f $_.Exception.Message);Write-Warning ('Raw evidence remains available: {0}' -f $ctx.EvidenceDirectory)
        return [pscustomobject][ordered]@{Status='EmergencyArchiveFailed';ZipPath=$ctx.ZipPath;Error=$_.Exception.Message;EvidenceDirectory=$ctx.EvidenceDirectory}
    }
}

function Get-NpuRunAssessmentExtensions {
    [CmdletBinding()]
    param([string[]]$ResolvedStages=@())
    $items=New-Object 'System.Collections.Generic.List[object]'
    if($ResolvedStages -contains 'Test'){$stage=Get-NpuLatestStageResult -Name 'Test';$items.Add([pscustomobject]@{Name='ResearchEnvironment';Status=if($stage -and $stage.Status -eq 'PASS'){'PASS'}else{'REVIEW'};Detail=if($stage){[string]$stage.Message}else{'Test stage not recorded'}})|Out-Null}
    if($ResolvedStages -contains 'Acquire'){$stage=Get-NpuLatestStageResult -Name 'Acquire';$items.Add([pscustomobject]@{Name='ArtifactAcquisition';Status=if($stage -and $stage.Status -eq 'PASS'){'PASS'}elseif($stage -and $stage.Status -eq 'SKIPPED'){'SKIP'}else{'REVIEW'};Detail=if($stage){[string]$stage.Message}else{'Acquire stage not recorded'}})|Out-Null}
    if($ResolvedStages -contains 'Signature'){
        $stage=Get-NpuLatestStageResult -Name 'Signature'
        if(-not$stage -or $stage.Status -ne 'PASS'){$items.Add([pscustomobject]@{Name='SignatureAnalysis';Status='REVIEW';Detail=if($stage){[string]$stage.Message}else{'Signature stage not recorded'}})|Out-Null}
        elseif($null -eq $script:NpuSignatureAnalysisDoc){$items.Add([pscustomobject]@{Name='SignatureAnalysis';Status='REVIEW';Detail='Signature stage passed but static signature analysis is unavailable.'})|Out-Null}
        else{
            $staticFiles=@($script:NpuSignatureAnalysisDoc.Artifacts|ForEach-Object{@($_.Files)}|ForEach-Object{$_})
            $envelopes=@($staticFiles|ForEach-Object{@($_.Envelopes)}|ForEach-Object{Get-NpuSignatureEnvelopeTree -Envelope $_})
            $parseFailures=@($envelopes|Where-Object{[string]$_.Status -ne 'Parsed'})
            $digestMismatches=@($envelopes|Where-Object{$null -ne $_.PSObject.Properties['PeDigestMatchesSignedDigest'] -and $_.PeDigestMatchesSignedDigest -eq $false})
            $nativeContext=if($script:NpuSignatureNativeDoc){[string]$script:NpuSignatureNativeDoc.ExecutionContext.ExecutionClass}else{'NotObserved'}
            $status=if($parseFailures.Count -eq 0 -and $digestMismatches.Count -eq 0){'PASS'}else{'REVIEW'}
            $items.Add([pscustomobject]@{Name='SignatureAnalysis';Status=$status;Detail=('full research NPU packages={0}; deep certificate targets={1}; files={2}; envelope parse failures={3}; PE digest mismatches={4}; native={5}' -f [int]$script:NpuSignatureAnalysisDoc.CandidateArtifactCount,@($script:NpuSignatureAnalysisDoc.Artifacts).Count,$staticFiles.Count,$parseFailures.Count,$digestMismatches.Count,$nativeContext)})|Out-Null
        }
    }
    if($ResolvedStages -contains 'Matrix'){$stage=Get-NpuLatestStageResult -Name 'Matrix';$items.Add([pscustomobject]@{Name='NpuCompatibilityMatrix';Status=if($stage -and $stage.Status -eq 'PASS'){'PASS'}elseif($stage -and $stage.Status -eq 'SKIPPED'){'SKIP'}else{'REVIEW'};Detail=if($stage){[string]$stage.Message}else{'Matrix stage not recorded'}})|Out-Null}
    if($ResolvedStages -contains 'Validate'){$stage=Get-NpuLatestStageResult -Name 'Validate';$items.Add([pscustomobject]@{Name='PublicationValidation';Status=if($stage -and $stage.Status -eq 'PASS'){'PASS'}elseif($stage -and $stage.Status -eq 'SKIPPED'){'SKIP'}else{'REVIEW'};Detail=if($stage){[string]$stage.Message}else{'Validate stage not recorded'}})|Out-Null}
    return @($items.ToArray())
}

function Get-NpuSignatureEnvelopeTree {
    [CmdletBinding()]
    param([AllowNull()]$Envelope)

    if($null -eq $Envelope){return @()}
    $items=New-Object System.Collections.Generic.List[object]
    $items.Add($Envelope)|Out-Null
    foreach($propertyName in @('NestedSignatures','TimestampTokens')){
        $property=$Envelope.PSObject.Properties[$propertyName]
        if($null -eq $property -or $null -eq $property.Value){continue}
        foreach($child in @($property.Value)){foreach($descendant in @(Get-NpuSignatureEnvelopeTree -Envelope $child)){$items.Add($descendant)|Out-Null}}
    }
    return @($items.ToArray())
}

function Get-NpuEvidenceInventorySnapshotFileNames {
    [CmdletBinding()]
    param()

    return @(
        'acquisition.json'
        'discovery.json'
        'hardware-selection-result.json'
        'local-npu-pnp-evidence.json'
        'release-metadata.json'
        'signature-analysis.json'
        'test-stage-evidence.json'
        'toolchain-capabilities.json'
    )
}

function Test-NpuEvidenceSnapshotContract {
    [CmdletBinding()]
    param()

    $required=@(
        'hardware-selection-result.json'
        'local-npu-pnp-evidence.json'
        'test-stage-evidence.json'
    )
    $configured=@(Get-NpuEvidenceInventorySnapshotFileNames)
    $missing=@($required|Where-Object{$configured -notcontains $_})
    $duplicates=@($configured|Group-Object|Where-Object{$_.Count -gt 1}|ForEach-Object{$_.Name})
    return [pscustomobject][ordered]@{
        Status=if($missing.Count -eq 0 -and $duplicates.Count -eq 0){'Pass'}else{'Fail'}
        RequiredFiles=$required
        ConfiguredFiles=$configured
        MissingFiles=$missing
        DuplicateFiles=$duplicates
    }
}

function Test-AmdEvidencePublicSnapshot {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][string]$PublicRoot,
        [Parameter(Mandatory=$true)][string]$SnapshotRoot
    )

    $errors=New-Object 'System.Collections.Generic.List[string]'
    $sourceMap=@{};$snapshotMap=@{};$manifestMap=@{}
    foreach($pair in @(@($PublicRoot,$sourceMap,'source'),@($SnapshotRoot,$snapshotMap,'snapshot'))){
        $root=[string]$pair[0];$map=$pair[1];$label=[string]$pair[2]
        if(-not(Test-Path -LiteralPath $root -PathType Container)){$errors.Add(('Evidence public {0} root is missing: {1}' -f $label,$root))|Out-Null;continue}
        foreach($file in @(Get-ChildItem -LiteralPath $root -File -Recurse -Force)){
            $relative=ConvertTo-AmdRepositoryRelativePath -RelativePath (Get-AmdRelativePath -BasePath $root -Path $file.FullName)
            if($map.ContainsKey($relative)){$errors.Add(('Duplicate Evidence public {0} path: {1}' -f $label,$relative))|Out-Null;continue}
            $map[$relative]=$file
        }
    }
    $manifestPath=Join-Path $PublicRoot 'publication-manifest.json'
    if(Test-Path -LiteralPath $manifestPath -PathType Leaf){
        try{
            $manifest=Read-AmdJsonFile -Path $manifestPath
            $rows=@(if($null -ne $manifest.PSObject.Properties['GeneratedFiles']){@($manifest.GeneratedFiles)}elseif($null -ne $manifest.PSObject.Properties['Files']){@($manifest.Files)}else{@()})
            if($rows.Count -eq 0){$errors.Add('Evidence public publication manifest has no supported payload rows.')|Out-Null}
            foreach($row in $rows){
                $relative=if($null -ne $row.PSObject.Properties['Path']){[string]$row.Path}else{[string]$row.RelativePath}
                $length=if($null -ne $row.PSObject.Properties['Length']){[int64]$row.Length}else{[int64]$row.SizeBytes}
                $sha=[string]$row.Sha256
                if([string]::IsNullOrWhiteSpace($relative) -or [IO.Path]::IsPathRooted($relative) -or $relative -match '(^|/)\.\.(/|$)'){$errors.Add(('Invalid Evidence public manifest path: {0}' -f $relative))|Out-Null;continue}
                $relative=ConvertTo-AmdRepositoryRelativePath -RelativePath $relative
                if($manifestMap.ContainsKey($relative)){$errors.Add(('Duplicate Evidence public manifest path: {0}' -f $relative))|Out-Null;continue}
                $manifestMap[$relative]=[pscustomobject]@{Length=$length;Sha256=$sha}
            }
        }catch{$errors.Add(('Evidence public publication manifest could not be read: {0}' -f $_.Exception.Message))|Out-Null}
    }else{$errors.Add('Evidence public publication-manifest.json is missing.')|Out-Null}
    foreach($relative in @($sourceMap.Keys)){
        if(-not $snapshotMap.ContainsKey($relative)){$errors.Add(('Evidence public snapshot file is missing: {0}' -f $relative))|Out-Null;continue}
        $source=$sourceMap[$relative];$snapshot=$snapshotMap[$relative]
        if([int64]$source.Length -ne [int64]$snapshot.Length -or (Get-AmdSha256 -Path $source.FullName) -ne (Get-AmdSha256 -Path $snapshot.FullName)){$errors.Add(('Evidence public snapshot byte mismatch: {0}' -f $relative))|Out-Null}
    }
    foreach($relative in @($snapshotMap.Keys)){if(-not $sourceMap.ContainsKey($relative)){$errors.Add(('Unexpected Evidence public snapshot file: {0}' -f $relative))|Out-Null}}
    foreach($relative in @($sourceMap.Keys|Where-Object{$_ -ne 'publication-manifest.json'})){
        if(-not $manifestMap.ContainsKey($relative)){$errors.Add(('Evidence public payload is absent from publication manifest: {0}' -f $relative))|Out-Null;continue}
        $file=$sourceMap[$relative];$row=$manifestMap[$relative]
        if([int64]$file.Length -ne [int64]$row.Length -or (Get-AmdSha256 -Path $file.FullName) -ne [string]$row.Sha256){$errors.Add(('Evidence public manifest size/hash mismatch: {0}' -f $relative))|Out-Null}
    }
    foreach($relative in @($manifestMap.Keys)){if(-not $sourceMap.ContainsKey($relative)){$errors.Add(('Evidence public manifest references a missing payload: {0}' -f $relative))|Out-Null}}
    return [pscustomobject][ordered]@{Status=if($errors.Count -eq 0){'Pass'}else{'Fail'};ErrorCount=$errors.Count;Errors=@($errors.ToArray());PublicFileCount=$sourceMap.Count;ManifestPayloadCount=$manifestMap.Count;SnapshotFileCount=$snapshotMap.Count}
}

function Invoke-NpuEvidenceSnapshot {
    [CmdletBinding()]
    param([Parameter(Mandatory=$true)][string]$EvidenceDirectory,[switch]$IncludePackages)
    $snap=Join-Path $EvidenceDirectory 'snapshot'
    foreach($name in @(Get-NpuEvidenceInventorySnapshotFileNames)){Copy-NpuEvidenceFileIfPresent (Join-Path (Join-Path $PSScriptRoot 'inventory') $name) (Join-Path (Join-Path $snap 'inventory') $name)}
    Copy-NpuEvidenceTreeIfPresent (Join-Path (Join-Path $PSScriptRoot 'inventory') 'host') (Join-Path (Join-Path $snap 'inventory') 'host')
    $buildStage=Get-NpuLatestStageResult -Name 'Build';$validateStage=Get-NpuLatestStageResult -Name 'Validate'
    if(-not $SkipPublicExport -and $buildStage -and $buildStage.Status -eq 'PASS' -and $validateStage -and $validateStage.Status -eq 'PASS'){
        $publicSnapshotRoot=Join-Path $snap 'public'
        Copy-NpuEvidenceTreeIfPresent $script:ResolvedPublicOutputRoot $publicSnapshotRoot
        $publicSnapshotValidation=Test-AmdEvidencePublicSnapshot -PublicRoot $script:ResolvedPublicOutputRoot -SnapshotRoot $publicSnapshotRoot
        if([string]$publicSnapshotValidation.Status -ne 'Pass'){throw('Evidence public snapshot validation failed: '+(@($publicSnapshotValidation.Errors)-join '; '))}
        $publicManifest=Join-Path $script:ResolvedPublicOutputRoot 'publication-manifest.json'
        Write-AmdJsonFile -Path (Join-Path $snap 'public-publication-reference.json') -Value ([pscustomobject][ordered]@{
            Classification='PrivateEvidenceReference';PublicManifest='snapshot/public/publication-manifest.json';PublicManifestSha256=Get-AmdSha256 -Path $publicManifest
            PublicFileCount=[int]$publicSnapshotValidation.PublicFileCount;ManifestPayloadCount=[int]$publicSnapshotValidation.ManifestPayloadCount;PublicDatasetIncludedInEvidence=$true
            SnapshotValidationStatus=[string]$publicSnapshotValidation.Status;Note='A byte-identical copy of the validated public dataset is included under snapshot/public for self-contained review.'
        })
    }
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
            $matrixSchemaPath=Join-Path (Join-Path (Get-AmdResearchToolkitRoot) 'schemas') 'driver-compatibility-matrix.schema.json'
            $matrixSchema=Read-AmdJsonFile -Path $matrixSchemaPath
            $selectionAuthority=Read-AmdJsonFile -Path (Join-Path (Join-Path (Get-AmdResearchToolkitRoot) 'data') 'hardware-driver-selection.json')
            $matrixSchemaVersion=Get-NpuPublicSchemaVersionConst -SchemaFileName 'driver-compatibility-matrix.schema.json'
            $processorSchemaVersion=Get-NpuPublicSchemaVersionConst -SchemaFileName 'processor-catalog.schema.json'
            $applicabilitySchemaVersion=Get-NpuPublicSchemaVersionConst -SchemaFileName 'processor-driver-applicability.schema.json'
            $schemaSelectionKey=[string]$matrixSchema.properties.Scope.properties.PackageSelectionKey.const
            $authoritySelectionKey=[string]$selectionAuthority.authority.selectionKey
            if([string]$matrix.SchemaVersion -ne [string]$matrixSchemaVersion){$errors.Add(('driver compatibility matrix public schema mismatch: expected={0}; actual={1}' -f [string]$matrixSchemaVersion,[string]$matrix.SchemaVersion))|Out-Null}
            if($schemaSelectionKey -ne $authoritySelectionKey){$errors.Add(('driver compatibility matrix schema selection authority mismatch: schema={0}; authority={1}' -f $schemaSelectionKey,$authoritySelectionKey))|Out-Null}
            if([string]$matrix.Scope.PackageSelectionKey -ne $schemaSelectionKey){$errors.Add(('driver compatibility matrix PackageSelectionKey mismatch: expected={0}; actual={1}' -f $schemaSelectionKey,[string]$matrix.Scope.PackageSelectionKey))|Out-Null}
            if([string]$processors.SchemaVersion -ne [string]$processorSchemaVersion){$errors.Add(('processor catalog public schema mismatch: expected={0}; actual={1}' -f [string]$processorSchemaVersion,[string]$processors.SchemaVersion))|Out-Null}
            if([string]$applicability.SchemaVersion -ne [string]$applicabilitySchemaVersion){$errors.Add(('processor-driver applicability public schema mismatch: expected={0}; actual={1}' -f [string]$applicabilitySchemaVersion,[string]$applicability.SchemaVersion))|Out-Null}
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
        Signature=@('Inspect')
        DriverBinary=@('Inspect')
        Compare=@('Inspect')
        Matrix=@('Inspect','HardwareIdentity','ProcessorCatalog')
        Build=@('Inspect','Signature','Matrix')
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
        $contractPath = Join-Path $PSScriptRoot 'data/current-three-tool-common-core-contract.json'
        if (-not (Test-Path -LiteralPath $contractPath -PathType Leaf)) {
            $issues.Add('Current three-tool common-core contract is missing.') | Out-Null
            return @($issues.ToArray())
        }
        try { $contract = Read-AmdJsonFile -Path $contractPath }
        catch {
            $issues.Add(('Current three-tool common-core contract cannot be read: {0}' -f $_.Exception.Message)) | Out-Null
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
            $issues.Add(('Current common-core function missing: {0}' -f $name)) | Out-Null
            continue
        }
        $normalized = ([string]$functionMap[$name]) -replace "`r`n","`n" -replace "`r","`n"
        $actualHash = Get-AmdStringSha256 -Text $normalized
        if ($actualHash -ne ([string]$entry.sha256).ToLowerInvariant()) {
            $issues.Add(('Current common-core function drifted from reviewed contract: {0}' -f $name)) | Out-Null
        }
    }
    if ([int]$contract.functionCount -ne @($contract.functions).Count) {
        $issues.Add('Current common-core contract FunctionCount does not match its function list.') | Out-Null
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
        foreach($required in @('Test','Discover','Metadata','Acquire','Extract','Inspect','Signature','Build','Validate')){
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
    Write-AmdDetail ('download with bounded retry policy: attempts={0}; uri={1}' -f $RetryCount,$Uri)
    $diagnosticDirectory=if($script:AmdEvidenceContext){Join-Path (Join-Path $script:AmdEvidenceContext.EvidenceDirectory 'errors') 'invalid-downloads'}else{$null}
    $downloadResult=Invoke-AmdQuietFileDownload -Uri $Uri -OutFile $Destination -TimeoutSec $TimeoutSeconds -MaximumAttempts $RetryCount -DiagnosticDirectory $diagnosticDirectory -DiagnosticPrefix 'npu-invalid-download'
    if(-not $downloadResult.Success){throw('Download failed after {0} bounded attempt(s): {1} : {2}' -f $RetryCount,$Uri,[string]$downloadResult.Error)}
    if(-not(Test-Path -LiteralPath $Destination -PathType Leaf)){throw 'Download reported success without creating the destination file.'}
    return (Get-Item -LiteralPath $Destination)
}

function Invoke-NpuDiscoveryStage {
    [CmdletBinding()]
    param(
        [string[]]$DocumentationUri=@('https://ryzenai.docs.amd.com/en/latest/inst.html'),
        [string[]]$AdditionalDriverUrl=@(),
        [int]$DownloadRetryCount=3,
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
        $probe = Invoke-AmdQuietTextRequest -Uri $sourceUri -TimeoutSec $DownloadTimeoutSeconds -MaximumAttempts $DownloadRetryCount
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

function Select-NpuNewestArtifactByPublishedLabel {
    param([Parameter(Mandatory=$true)]$Artifacts)
    $items = @($Artifacts)
    if ($items.Count -eq 0) { return $null }
    $maxVersion = $null
    foreach ($artifact in $items) {
        try { $parsed = [version][string]$artifact.publishedDriverLabel } catch { $parsed = [version]'0.0' }
        if ($null -eq $maxVersion -or $parsed -gt $maxVersion) { $maxVersion = $parsed }
    }
    $newest = @($items | Where-Object {
        try { ([version][string]$_.publishedDriverLabel) -eq $maxVersion } catch { ([version]'0.0') -eq $maxVersion }
    })
    return @(Get-AmdOrdinalSortedObjectsByStringProperty -Values $newest -PropertyName 'fileName' | Select-Object -First 1)[0]
}

function Get-NpuCertificateVerificationTargetPlan {
    param(
        [Parameter(Mandatory=$true)]$Catalog,
        [string[]]$SelectedArtifactIds=@(),
        [switch]$ExplicitSelection
    )
    # Windows PowerShell 5.1 enumerates the output of an if statement expression
    # assigned to a variable. Protect the entire expression so a single selected
    # artifact remains a one-element array before the .Count checks below.
    $selected = @(
        if ($SelectedArtifactIds.Count -gt 0) {
            $Catalog.artifacts | Where-Object { $SelectedArtifactIds -contains [string]$_.artifactId }
        }
        else {
            $Catalog.artifacts | Where-Object { $_.defaultAcquire -eq $true }
        }
    )
    $targets = New-Object System.Collections.Generic.List[object]
    $policy = [string]$Catalog.discovery.certificateVerificationPolicy

    if ($ExplicitSelection -and $selected.Count -eq 1) {
        $artifact = $selected[0]
        $targets.Add([pscustomobject][ordered]@{
            ArtifactId=[string]$artifact.artifactId;FileName=[string]$artifact.fileName;PublishedDriverLabel=[string]$artifact.publishedDriverLabel
            PackageRole=[string]$artifact.packageRole;SelectionLaneId=[string]$artifact.selectionLaneId;SelectionReason='OnlyExplicitlySelectedArtifact'
        }) | Out-Null
        $policy = 'OnlySelectedArtifact'
    }
    else {
        $current = @($selected | Where-Object {
            [string]$_.packageRole -eq 'CurrentNpuTypeCandidate' -and
            [string]$_.certificateVerificationRole -eq 'CurrentCaseCandidate'
        })
        $laneIds = @($current | ForEach-Object { [string]$_.selectionLaneId } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Sort-Object -Unique)
        foreach ($laneId in $laneIds) {
            $newest = Select-NpuNewestArtifactByPublishedLabel -Artifacts @($current | Where-Object { [string]$_.selectionLaneId -eq $laneId })
            if ($null -ne $newest) {
                $targets.Add([pscustomobject][ordered]@{
                    ArtifactId=[string]$newest.artifactId;FileName=[string]$newest.fileName;PublishedDriverLabel=[string]$newest.publishedDriverLabel
                    PackageRole=[string]$newest.packageRole;SelectionLaneId=[string]$newest.selectionLaneId;SelectionReason='NewestWithinCurrentNpuTypeCase'
                }) | Out-Null
            }
        }
        if ($targets.Count -eq 0 -and $ExplicitSelection -and $selected.Count -gt 0) {
            $newest = Select-NpuNewestArtifactByPublishedLabel -Artifacts $selected
            $targets.Add([pscustomobject][ordered]@{
                ArtifactId=[string]$newest.artifactId;FileName=[string]$newest.fileName;PublishedDriverLabel=[string]$newest.publishedDriverLabel
                PackageRole=[string]$newest.packageRole;SelectionLaneId=[string]$newest.selectionLaneId;SelectionReason='NewestExplicitlySelectedArtifactFallback'
            }) | Out-Null
            $policy = 'NewestSelectedArtifactFallback'
        }
    }

    $targetIds = @($targets.ToArray() | ForEach-Object { [string]$_.ArtifactId })
    $excluded = @($selected | Where-Object { $targetIds -notcontains [string]$_.artifactId } | ForEach-Object {
        $exclusionReason = 'OlderArtifactInsideSelectedCurrentCase'
        if ([string]$_.packageRole -eq 'HistoricalRegressionFixture') { $exclusionReason = 'HistoricalResearchArtifact_NotCurrentCertificateTarget' }
        [pscustomobject][ordered]@{ArtifactId=[string]$_.artifactId;FileName=[string]$_.fileName;PackageRole=[string]$_.packageRole;Reason=$exclusionReason}
    })
    return [pscustomobject][ordered]@{
        SchemaVersion='amd-npu-certificate-verification-target-plan/1.0'
        Policy=$policy
        FullResearchArtifactCount=$selected.Count
        CertificateVerificationTargetCount=$targets.Count
        SelectedTargets=@($targets.ToArray())
        ExcludedFromCertificateVerification=$excluded
        ExplicitSelection=[bool]$ExplicitSelection
        ScopeSeparation='Acquire/Extract/Inspect/DriverBinary/Compare/Matrix evaluate the selected full research corpus. Deep certificate verification evaluates only this target plan.'
    }
}

function Test-NpuResearchAndCertificateScopeSeparation {
    param([Parameter(Mandatory=$true)]$Catalog)
    $issues = New-Object System.Collections.Generic.List[string]
    $defaultPlan = Get-NpuCertificateVerificationTargetPlan -Catalog $Catalog
    $defaultTargetIds = @($defaultPlan.SelectedTargets | ForEach-Object { [string]$_.ArtifactId })
    if ($defaultPlan.FullResearchArtifactCount -ne 3) { $issues.Add('Full-scope NPU research must include all three reviewed public artifacts.') | Out-Null }
    if ($defaultPlan.CertificateVerificationTargetCount -ne 2 -or $defaultTargetIds -notcontains 'rai-280' -or $defaultTargetIds -notcontains 'rai-376') { $issues.Add('Default certificate verification must select the newest artifact in each current NPU type case.') | Out-Null }
    if ($defaultTargetIds -contains 'rai-1.5-280') { $issues.Add('Historical RAI1.5 must remain in research scope but outside default certificate-verification targets.') | Out-Null }

    $historicalOnly = Get-NpuCertificateVerificationTargetPlan -Catalog $Catalog -SelectedArtifactIds @('rai-1.5-280') -ExplicitSelection
    if ($historicalOnly.Policy -ne 'OnlySelectedArtifact' -or $historicalOnly.CertificateVerificationTargetCount -ne 1 -or [string]$historicalOnly.SelectedTargets[0].ArtifactId -ne 'rai-1.5-280') { $issues.Add('An explicit single-artifact run must analyze exactly that artifact, matching the Chipset OnlySelectedRelease behavior.') | Out-Null }

    $fixture = [pscustomobject]@{discovery=[pscustomobject]@{certificateVerificationPolicy='NewestWithinEachCurrentNpuTypeCase'};artifacts=@(
        [pscustomobject]@{artifactId='lane-a-old';fileName='a-old.zip';publishedDriverLabel='1.0.0.0';packageRole='CurrentNpuTypeCandidate';selectionLaneId='lane-a';certificateVerificationRole='CurrentCaseCandidate';defaultAcquire=$true},
        [pscustomobject]@{artifactId='lane-a-new';fileName='a-new.zip';publishedDriverLabel='2.0.0.0';packageRole='CurrentNpuTypeCandidate';selectionLaneId='lane-a';certificateVerificationRole='CurrentCaseCandidate';defaultAcquire=$true},
        [pscustomobject]@{artifactId='history';fileName='history.zip';publishedDriverLabel='9.0.0.0';packageRole='HistoricalRegressionFixture';selectionLaneId='history';certificateVerificationRole='HistoricalWhenExplicitOnly';defaultAcquire=$true}
    )}
    $fixturePlan = Get-NpuCertificateVerificationTargetPlan -Catalog $fixture
    if ($fixturePlan.CertificateVerificationTargetCount -ne 1 -or [string]$fixturePlan.SelectedTargets[0].ArtifactId -ne 'lane-a-new') { $issues.Add('A numerically newer historical version must not defeat newest-within-current-case certificate selection.') | Out-Null }
    return $issues.ToArray()
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
            PackageRole=[string]$artifact.packageRole;SelectionLaneId=[string]$artifact.selectionLaneId;SelectionBoundaryStatus=[string]$artifact.selectionBoundaryStatus
            CertificateVerificationRole=[string]$artifact.certificateVerificationRole
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
            PackageRole='UnreviewedArtifact';SelectionLaneId=$null;SelectionBoundaryStatus='NoReviewedRule'
            CertificateVerificationRole='UnreviewedNotEligible'
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
    $selectedReviewedIds=@($selectedRecords|Where-Object{$_.Reviewed}|ForEach-Object{[string]$_.ArtifactId})
    $certificatePlan=Get-NpuCertificateVerificationTargetPlan -Catalog $script:ArtifactCatalogDoc -SelectedArtifactIds $selectedReviewedIds -ExplicitSelection:($ArtifactId.Count -gt 0)
    $doc=[pscustomobject][ordered]@{
        SchemaVersion='amd-npu-driver-release-metadata/1.1';ToolkitVersion=$script:ToolVersion;GeneratedAtUtc=Get-AmdUtcTimestamp
        Records=@(Get-AmdOrdinalSortedObjectsByStringProperty -Values @($records.ToArray()) -PropertyName 'FileName');SelectedCount=$selectedRecords.Count
        FullScopeAcquisitionPolicy=[string]$script:ArtifactCatalogDoc.discovery.fullScopeAcquisitionPolicy
        CertificateVerificationPlan=$certificatePlan
        Summary=('records={0}; selected={1}; reviewed={2}; unreviewed={3}' -f $records.Count,$selectedRecords.Count,@($records.ToArray()|Where-Object{$_.Reviewed}).Count,@($records.ToArray()|Where-Object{-not $_.Reviewed}).Count)
    }
    $script:ReleaseMetadataDoc=$doc
    Write-JsonFile -Value $doc -Path (Join-Path $PSScriptRoot 'inventory/release-metadata.json')
    return $doc
}

function Test-NpuPublishedArtifactCatalog {
    param([Parameter(Mandatory=$true)]$Catalog,[switch]$AllowNonAmdHost)
    $issues=New-Object System.Collections.Generic.List[string];$ids=@{};$files=@{}
    if([string]$Catalog.schemaVersion -ne 'amd-npu-published-driver-artifacts/1.3'){$issues.Add('Unexpected published-driver-artifacts schemaVersion.')|Out-Null}
    if([string]::IsNullOrWhiteSpace([string]$Catalog.discovery.documentationUrl)){$issues.Add('Discovery documentationUrl is missing.')|Out-Null}
    foreach($a in @($Catalog.artifacts)){
        $id=[string]$a.artifactId;$name=[string]$a.fileName;$url=[string]$a.downloadUrl;$hash=[string]$a.expectedSha256
        if([string]::IsNullOrWhiteSpace($id)){$issues.Add('Artifact entry missing artifactId.')|Out-Null}elseif($ids.ContainsKey($id)){$issues.Add("Duplicate artifactId: $id")|Out-Null}else{$ids[$id]=$true}
        if([string]::IsNullOrWhiteSpace($name) -or -not (Test-NpuSupportedArtifactPath -Path $name)){$issues.Add("Invalid or unsupported artifact filename: $name")|Out-Null}elseif($files.ContainsKey($name)){$issues.Add("Duplicate artifact filename: $name")|Out-Null}else{$files[$name]=$true}
        if(-not $AllowNonAmdHost -and -not(Test-NpuAllowedDownloadUri $url)){$issues.Add("Reviewed artifact URL is not an approved AMD HTTPS download URL: $url")|Out-Null}
        if([string]$a.artifactFormat -ne (Get-NpuArtifactFormatFromPath -Path $name)){$issues.Add("artifactFormat does not match filename extension for $id")|Out-Null}
        if(-not [string]::IsNullOrWhiteSpace($hash) -and $hash -notmatch '^[0-9a-f]{64}$'){$issues.Add("Invalid expected SHA-256 for $id")|Out-Null}
        if($null -ne $a.expectedSizeBytes -and [long]$a.expectedSizeBytes -lt 1){$issues.Add("Invalid expected size for $id")|Out-Null}
        if(@('HistoricalRegressionFixture','CurrentNpuTypeCandidate') -notcontains [string]$a.packageRole){$issues.Add("Invalid packageRole for $id")|Out-Null}
        if([string]::IsNullOrWhiteSpace([string]$a.selectionLaneId)){$issues.Add("Missing selectionLaneId for $id")|Out-Null}
        if(@('HistoricalOnly','ReviewRequired','Resolved') -notcontains [string]$a.selectionBoundaryStatus){$issues.Add("Invalid selectionBoundaryStatus for $id")|Out-Null}
        if(@('HistoricalWhenExplicitOnly','CurrentCaseCandidate') -notcontains [string]$a.certificateVerificationRole){$issues.Add("Invalid certificateVerificationRole for $id")|Out-Null}
        if([string]$a.packageRole -eq 'HistoricalRegressionFixture' -and [string]$a.certificateVerificationRole -ne 'HistoricalWhenExplicitOnly'){$issues.Add("Historical artifact has an invalid certificate verification role: $id")|Out-Null}
        if([string]$a.packageRole -eq 'CurrentNpuTypeCandidate' -and [string]$a.certificateVerificationRole -ne 'CurrentCaseCandidate'){$issues.Add("Current NPU package case has an invalid certificate verification role: $id")|Out-Null}
    }
    $currentCases=@($Catalog.artifacts|Where-Object{[string]$_.packageRole -eq 'CurrentNpuTypeCandidate'})
    if($currentCases.Count -ne 2){$issues.Add('Exactly two current NPU package cases must be defined.')|Out-Null}
    if(@($Catalog.artifacts|Where-Object{$_.defaultAcquire -eq $true}).Count -ne @($Catalog.artifacts).Count){$issues.Add('A full-scope run must acquire every reviewed public NPU research artifact, including historical fixtures.')|Out-Null}
    if(@($Catalog.artifacts|Where-Object{[string]$_.packageRole -eq 'HistoricalRegressionFixture' -and $_.defaultAcquire -eq $true}).Count -ne 1){$issues.Add('The reviewed historical RAI1.5 fixture must remain in default full-scope acquisition.')|Out-Null}
    if($Catalog.discovery.globalVersionRankingProhibited -ne $true){$issues.Add('NPU catalog must prohibit global version ranking across package cases.')|Out-Null}
    if([string]$Catalog.discovery.fullScopeAcquisitionPolicy -ne 'AllReviewedPublicArtifacts'){$issues.Add('Unexpected full-scope acquisition policy.')|Out-Null}
    if([string]$Catalog.discovery.certificateVerificationPolicy -ne 'NewestWithinEachCurrentNpuTypeCase'){$issues.Add('Unexpected certificate verification policy.')|Out-Null}
    if($Catalog.discovery.explicitArtifactSelectionCanOverrideCertificateScope -ne $true){$issues.Add('Explicit artifact selection override contract is missing.')|Out-Null}
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
    $script:RunInputs=@(Resolve-PackageInputs -Requested @($kernel.Paths))
    if($PackagePath.Count -gt 0){$summary=('NPU packages={0}; research scope=explicit local NPU package set; source=LocalReplay' -f $script:RunInputs.Count)}
    else{
        $records=@($Metadata.Records)
        $historicalCount=@($records|Where-Object{[string]$_.PackageRole -eq 'HistoricalRegressionFixture'}).Count
        $currentCaseCount=@($records|Where-Object{[string]$_.PackageRole -eq 'CurrentNpuTypeCandidate'}).Count
        $summary=('NPU packages={0}; research scope=all reviewed public NPU packages; historical research packages={1}; current NPU package cases={2}; source=DownloadOrCache' -f $script:RunInputs.Count,$historicalCount,$currentCaseCount)
    }
    return [pscustomobject]@{Summary=$summary;Paths=$script:RunInputs;Acquisition=$doc}
}


function Resolve-NpuRequestedStages {
    [CmdletBinding()]
    param([string[]]$Stages=@('All'),[string]$Mode)
    $full=@('PathSafety','Test','HardwareIdentity','ProcessorCatalog','Discover','Metadata','Acquire','Extract','Inspect','Signature','DriverBinary','Compare','Matrix','Build','Validate')
    $modeMap=@{Full=@('All');Analyze=@('Test','HardwareIdentity','ProcessorCatalog','Acquire','Extract','Inspect','Signature','DriverBinary','Matrix','Build','Validate');Compare=@('Test','HardwareIdentity','ProcessorCatalog','Acquire','Extract','Inspect','Signature','DriverBinary','Compare','Matrix','Build','Validate');Validate=@('Test','Validate')}
    $aliasMap=@{Analyze=@('Extract','Inspect')}
    $resolved=@(Resolve-AmdRequestedStages -AvailableStages $full -RequestedStages @($Stages) -LegacyMode $Mode -ModeMap $modeMap -AliasMap $aliasMap)
    return @('PathSafety')+@($resolved|Where-Object{$_ -ne 'PathSafety'})
}


function Invoke-NpuExtractStage {
    [CmdletBinding()]
    param([string]$SevenZipPath,[int]$ExtractionMaxDepth=5)
    if(@($script:RunInputs).Count -eq 0){throw 'No acquired package is available for extraction.'};$sevenZip=Get-AmdSevenZipPath -ExplicitPath $SevenZipPath;$logRoot=Join-Path (Join-Path (Join-Path $PSScriptRoot 'private') 'evidence') 'extraction-logs'
    $formatResolver={param($p) Get-NpuArtifactFormatFromPath -Path $p};$surfaceProbe={param($root) Get-NpuAnalysisSurface -Root $root};$nestedPredicate={param($p,$sevenZipExe) if(-not(Test-NpuSupportedArtifactPath -Path $p)){return $false};$probe=Get-AmdSevenZipArchiveProbe -SevenZipPath $sevenZipExe -Path $p;return [bool]$probe.ContainerLike}
    $script:ExtractedPackages=@(Invoke-AmdArtifactExtractionKernel -ArtifactPaths @($script:RunInputs) -RunRoot $script:RunRoot -EvidenceLogRoot $logRoot -SevenZipExecutable $sevenZip -MaxDepth $ExtractionMaxDepth -FormatResolver $formatResolver -SurfaceProbe $surfaceProbe -NestedArtifactPredicate $nestedPredicate)
    $null=Assert-AmdExtractionCompleteSet -Items @($script:ExtractedPackages) -Context 'NPU downstream analysis'
    return [pscustomobject]@{Summary=('NPU packages={0}; containers={1}; extracted files={2}; extraction=Static7Zip; sevenZip={3}' -f $script:ExtractedPackages.Count,(@($script:ExtractedPackages|ForEach-Object{$_.ContainerCount})|Measure-Object -Sum).Sum,(@($script:ExtractedPackages|ForEach-Object{$_.FileCount})|Measure-Object -Sum).Sum,$sevenZip);Packages=$script:ExtractedPackages;SevenZipPath=$sevenZip;MaxDepth=$ExtractionMaxDepth}
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
    return [pscustomobject]@{Summary=('NPU packages={0}; inspection=Static' -f $script:Analyses.Count);Analyses=$script:Analyses}
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

function Get-NpuEffectiveCertificateVerificationPlan {
    [CmdletBinding()]
    param(
        [AllowNull()]$Metadata,
        [Parameter(Mandatory=$true)]$ExtractedPackages,
        [AllowNull()]$ArtifactCatalog,
        [switch]$LocalPackageOverride
    )

    $packages=@($ExtractedPackages)
    if($packages.Count -eq 0){throw 'No extracted NPU package is available for certificate verification.'}
    $targets=New-Object System.Collections.Generic.List[object]
    $missing=New-Object System.Collections.Generic.List[object]
    $excluded=@()
    $policy=$null

    if($LocalPackageOverride){
        $policy=if($packages.Count -eq 1){'OnlySelectedArtifact'}else{'ExplicitLocalArtifactSet'}
        foreach($package in $packages){
            $reviewed=@()
            if($null -ne $ArtifactCatalog){$reviewed=@($ArtifactCatalog.artifacts|Where-Object{[string]$_.fileName -ieq [string]$package.FileName}|Select-Object -First 1)}
            $catalogItem=if($reviewed.Count -eq 1){$reviewed[0]}else{$null}
            $targets.Add([pscustomobject][ordered]@{
                ArtifactId=if($catalogItem){[string]$catalogItem.artifactId}else{('local:'+[string]$package.Sha256)}
                FileName=[string]$package.FileName
                PublishedDriverLabel=if($catalogItem){[string]$catalogItem.publishedDriverLabel}else{$null}
                PackageRole=if($catalogItem){[string]$catalogItem.packageRole}else{'ExplicitLocalArtifact'}
                SelectionLaneId=if($catalogItem){[string]$catalogItem.selectionLaneId}else{$null}
                SelectionReason=if($packages.Count -eq 1){'OnlyExplicitlySelectedArtifact'}else{'ExplicitLocalArtifactSetMember'}
                ArtifactPath=[string]$package.ArtifactPath
                ExtractRoot=[string]$package.ExtractRoot
            })|Out-Null
        }
    }
    else{
        if($null -eq $Metadata -or $null -eq $Metadata.PSObject.Properties['CertificateVerificationPlan']){throw 'CertificateVerificationPlan is missing from NPU release metadata.'}
        $declared=$Metadata.CertificateVerificationPlan
        $policy=[string]$declared.Policy
        $excluded=@($declared.ExcludedFromCertificateVerification)
        foreach($target in @($declared.SelectedTargets)){
            $match=@($packages|Where-Object{[string]$_.FileName -ieq [string]$target.FileName}|Select-Object -First 1)
            if($match.Count -ne 1){
                $missing.Add([pscustomobject][ordered]@{ArtifactId=[string]$target.ArtifactId;FileName=[string]$target.FileName;Reason='PlannedCertificateTargetExtractionUnavailable'})|Out-Null
                continue
            }
            $targets.Add([pscustomobject][ordered]@{
                ArtifactId=[string]$target.ArtifactId;FileName=[string]$target.FileName;PublishedDriverLabel=[string]$target.PublishedDriverLabel
                PackageRole=[string]$target.PackageRole;SelectionLaneId=[string]$target.SelectionLaneId;SelectionReason=[string]$target.SelectionReason
                ArtifactPath=[string]$match[0].ArtifactPath;ExtractRoot=[string]$match[0].ExtractRoot
            })|Out-Null
        }
    }

    return [pscustomobject][ordered]@{
        SchemaVersion='amd-npu-certificate-verification-execution-plan/1.0'
        Status=if($missing.Count -eq 0 -and $targets.Count -gt 0){'Ready'}else{'Blocked'}
        Policy=$policy
        FullResearchArtifactCount=$packages.Count
        CertificateVerificationTargetCount=$targets.Count
        SelectedTargets=@($targets.ToArray())
        ExcludedFromCertificateVerification=@($excluded)
        MissingTargets=@($missing.ToArray())
        LocalPackageOverride=[bool]$LocalPackageOverride
        ScopeSeparation='Full research remains all selected artifacts. This execution plan alone controls deep certificate verification.'
    }
}

function Get-NpuCertificateVerificationOperatorMessages {
    [CmdletBinding()]
    param([Parameter(Mandatory=$true)]$ExecutionPlan)

    $scopeLine=('Certificate scope: full research NPU packages={0}; deep certificate targets={1}; policy={2}.' -f [int]$ExecutionPlan.FullResearchArtifactCount,[int]$ExecutionPlan.CertificateVerificationTargetCount,[string]$ExecutionPlan.Policy)
    $exclusionLines=New-Object System.Collections.Generic.List[string]
    foreach($excluded in @($ExecutionPlan.ExcludedFromCertificateVerification)){
        $exclusionLines.Add(('Research-only NPU package: {0} [{1}]; acquired/extracted/inspected in full scope; intentionally excluded only from default deep certificate verification; reason={2}.' -f [string]$excluded.FileName,[string]$excluded.ArtifactId,[string]$excluded.Reason))|Out-Null
    }
    return [pscustomobject][ordered]@{ScopeLine=$scopeLine;ExclusionLines=@($exclusionLines.ToArray())}
}

function Get-NpuCertificateTargetOperatorLine {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]$Target,
        [int]$Ordinal,
        [int]$TargetCount,
        [int]$UniqueFileContentGroupCount
    )

    $identity=('Deep certificate target {0}/{1}: {2} [{3}]' -f $Ordinal,$TargetCount,[string]$Target.FileName,[string]$Target.ArtifactId)
    if([string]$Target.PackageRole -eq 'ExplicitLocalArtifact'){
        return ('{0}; role=explicit local NPU package; reason={1}; unique file-content groups={2}.' -f $identity,[string]$Target.SelectionReason,$UniqueFileContentGroupCount)
    }
    return ('{0}; published={1}; NPU package case={2}; reason={3}; unique file-content groups={4}.' -f $identity,[string]$Target.PublishedDriverLabel,[string]$Target.SelectionLaneId,[string]$Target.SelectionReason,$UniqueFileContentGroupCount)
}

function Test-NpuOperatorMessageContractSelfTest {
    [CmdletBinding()]
    param()

    $plan=[pscustomobject]@{
        Policy='NewestWithinEachCurrentNpuTypeCase';FullResearchArtifactCount=3;CertificateVerificationTargetCount=2
        ExcludedFromCertificateVerification=@([pscustomobject]@{ArtifactId='rai-1.5-280';FileName='NPU_RAI1.5_280_WHQL.zip';Reason='HistoricalResearchArtifact_NotCurrentCertificateTarget'})
    }
    $messages=Get-NpuCertificateVerificationOperatorMessages -ExecutionPlan $plan
    $currentTargetLine=Get-NpuCertificateTargetOperatorLine -Target ([pscustomobject]@{ArtifactId='rai-280';FileName='NPU_RAI_280_WHQL.zip';PublishedDriverLabel='32.0.203.280';PackageRole='CurrentNpuTypeCandidate';SelectionLaneId='current-npu-package-280';SelectionReason='NewestWithinCurrentNpuTypeCase'}) -Ordinal 1 -TargetCount 2 -UniqueFileContentGroupCount 21
    $localTargetLine=Get-NpuCertificateTargetOperatorLine -Target ([pscustomobject]@{ArtifactId='local:01';FileName='local.zip';PackageRole='ExplicitLocalArtifact';SelectionReason='OnlyExplicitlySelectedArtifact'}) -Ordinal 1 -TargetCount 1 -UniqueFileContentGroupCount 2
    $combined=(@([string]$messages.ScopeLine)+@($messages.ExclusionLines)+@($currentTargetLine,$localTargetLine)) -join ' '
    $ok=(
        [string]$messages.ScopeLine -match 'full research NPU packages=3' -and
        [string]$messages.ScopeLine -match 'deep certificate targets=2' -and
        @($messages.ExclusionLines).Count -eq 1 -and
        $combined -match 'NPU_RAI1\.5_280_WHQL\.zip' -and
        $combined -match 'acquired/extracted/inspected in full scope' -and
        $combined -match 'excluded only from default deep certificate verification' -and
        $currentTargetLine -match 'NPU package case=current-npu-package-280' -and
        $localTargetLine -match 'role=explicit local NPU package' -and
        $localTargetLine -notmatch 'published=|NPU package case=' -and
        $combined -notmatch 'targets=2/3|SharedAcquisition|SharedExtraction|OnlySelectedRelease|chipset installer'
    )
    return [pscustomobject][ordered]@{Status=if($ok){'Pass'}else{'Fail'};ScopeLine=[string]$messages.ScopeLine;ExclusionLineCount=@($messages.ExclusionLines).Count}
}

function Test-NpuCertificateVerificationExecutionPlanSelfTest {
    [CmdletBinding()]
    param()

    $catalog=[pscustomobject]@{artifacts=@(
        [pscustomobject]@{artifactId='history';fileName='history.zip';publishedDriverLabel='9.0';packageRole='HistoricalRegressionFixture';selectionLaneId='history'},
        [pscustomobject]@{artifactId='current-a';fileName='a.zip';publishedDriverLabel='2.0';packageRole='CurrentNpuTypeCandidate';selectionLaneId='a'},
        [pscustomobject]@{artifactId='current-b';fileName='b.zip';publishedDriverLabel='3.0';packageRole='CurrentNpuTypeCandidate';selectionLaneId='b'}
    )}
    $metadata=[pscustomobject]@{CertificateVerificationPlan=[pscustomobject]@{
        Policy='NewestWithinEachCurrentNpuTypeCase';SelectedTargets=@(
            [pscustomobject]@{ArtifactId='current-a';FileName='a.zip';PublishedDriverLabel='2.0';PackageRole='CurrentNpuTypeCandidate';SelectionLaneId='a';SelectionReason='NewestWithinCurrentNpuTypeCase'},
            [pscustomobject]@{ArtifactId='current-b';FileName='b.zip';PublishedDriverLabel='3.0';PackageRole='CurrentNpuTypeCandidate';SelectionLaneId='b';SelectionReason='NewestWithinCurrentNpuTypeCase'}
        );ExcludedFromCertificateVerification=@([pscustomobject]@{ArtifactId='history';FileName='history.zip';Reason='HistoricalResearchArtifact_NotCurrentCertificateTarget'})
    }}
    $packages=@(
        [pscustomobject]@{FileName='history.zip';Sha256='01';ArtifactPath='history.zip';ExtractRoot='history'},
        [pscustomobject]@{FileName='a.zip';Sha256='02';ArtifactPath='a.zip';ExtractRoot='a'},
        [pscustomobject]@{FileName='b.zip';Sha256='03';ArtifactPath='b.zip';ExtractRoot='b'}
    )
    $defaultPlan=Get-NpuEffectiveCertificateVerificationPlan -Metadata $metadata -ExtractedPackages $packages -ArtifactCatalog $catalog
    $singlePlan=Get-NpuEffectiveCertificateVerificationPlan -ExtractedPackages @($packages[0]) -ArtifactCatalog $catalog -LocalPackageOverride
    $missingPlan=Get-NpuEffectiveCertificateVerificationPlan -Metadata $metadata -ExtractedPackages @($packages[0],$packages[1]) -ArtifactCatalog $catalog
    $ok=(
        $defaultPlan.Status -eq 'Ready' -and $defaultPlan.FullResearchArtifactCount -eq 3 -and $defaultPlan.CertificateVerificationTargetCount -eq 2 -and
        @($defaultPlan.SelectedTargets|Where-Object{$_.ArtifactId -eq 'history'}).Count -eq 0 -and
        $singlePlan.Status -eq 'Ready' -and $singlePlan.Policy -eq 'OnlySelectedArtifact' -and [string]$singlePlan.SelectedTargets[0].ArtifactId -eq 'history' -and
        $missingPlan.Status -eq 'Blocked' -and $missingPlan.MissingTargets.Count -eq 1
    )
    return [pscustomobject][ordered]@{Status=if($ok){'Pass'}else{'Fail'};DefaultTargetCount=$defaultPlan.CertificateVerificationTargetCount;SinglePolicy=$singlePlan.Policy;MissingTargetCount=$missingPlan.MissingTargets.Count}
}

function Test-NpuSignatureSchemaContracts {
    [CmdletBinding()]
    param()

    $contracts = @(
        [pscustomobject]@{ FileName='signature-analysis.schema.json'; Const='amd-npu-driver-signature-analysis/1.0' },
        [pscustomobject]@{ FileName='signature-native-verification.schema.json'; Const='amd-npu-driver-signature-native-verification/1.0' },
        [pscustomobject]@{ FileName='toolchain-capability.schema.json'; Const='amd-driver-toolchain-capability-summary/1.1' },
        [pscustomobject]@{ FileName='windows-host-security-posture.schema.json'; Const='amd-driver-windows-host-security-posture/1.0' },
        [pscustomobject]@{ FileName='target-server-host-evidence.schema.json'; Const='amd-driver-target-server-host-evidence/1.0' },
        [pscustomobject]@{ FileName='windows-client-signature-qualification.schema.json'; Const='amd-npu-windows-client-signature-qualification/1.0' }
    )
    $issues = New-Object 'System.Collections.Generic.List[string]'
    foreach ($contract in $contracts) {
        $path = Join-Path (Join-Path $PSScriptRoot 'schemas') $contract.FileName
        try { $schema = Get-ReviewedJsonDocument -Path $path }
        catch {
            $issues.Add(('Signature schema unavailable or invalid JSON: {0}: {1}' -f $contract.FileName,$_.Exception.Message)) | Out-Null
            continue
        }
        if ([string]$schema.properties.SchemaVersion.const -ne [string]$contract.Const) {
            $issues.Add(('Signature schema version contract mismatch: {0}' -f $contract.FileName)) | Out-Null
        }
    }
    return [pscustomobject][ordered]@{
        Status=if($issues.Count -eq 0){'Pass'}else{'Fail'}
        SchemaCount=$contracts.Count
        Issues=@($issues.ToArray())
    }
}

function Get-NpuWindowsClientSignatureQualificationAssessment {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]$ExecutionPlan,
        [Parameter(Mandatory=$true)]$StaticAnalysis,
        [Parameter(Mandatory=$true)]$NativeVerification,
        [Parameter(Mandatory=$true)]$KernelCoverage
    )

    $issues = New-Object 'System.Collections.Generic.List[string]'
    if ([string]$ExecutionPlan.Policy -ne 'NewestWithinEachCurrentNpuTypeCase') {
        $issues.Add(('Unexpected certificate policy: {0}' -f [string]$ExecutionPlan.Policy)) | Out-Null
    }
    if ([int]$ExecutionPlan.FullResearchArtifactCount -ne 3) {
        $issues.Add(('Expected three full-research artifacts; observed {0}.' -f [int]$ExecutionPlan.FullResearchArtifactCount)) | Out-Null
    }
    if ([int]$ExecutionPlan.CertificateVerificationTargetCount -ne 2) {
        $issues.Add(('Expected two current-case certificate targets; observed {0}.' -f [int]$ExecutionPlan.CertificateVerificationTargetCount)) | Out-Null
    }
    if (@($ExecutionPlan.MissingTargets).Count -ne 0) {
        $issues.Add(('Certificate execution plan has {0} missing target(s).' -f @($ExecutionPlan.MissingTargets).Count)) | Out-Null
    }
    if ([string]$NativeVerification.ExecutionContext.ExecutionClass -ne 'WindowsClient') {
        $issues.Add(('Expected WindowsClient execution; observed {0}.' -f [string]$NativeVerification.ExecutionContext.ExecutionClass)) | Out-Null
    }
    if ([string]$NativeVerification.Tool.Status -ne 'Available') {
        $issues.Add(('SignTool is not available: {0}.' -f [string]$NativeVerification.Tool.Status)) | Out-Null
    }
    if ($NativeVerification.MutationPerformed -ne $false) {
        $issues.Add('Native signature evidence does not assert MutationPerformed=false.') | Out-Null
    }
    if (@($StaticAnalysis.Artifacts).Count -ne 2) {
        $issues.Add(('Expected static analysis for two current-case targets; observed {0}.' -f @($StaticAnalysis.Artifacts).Count)) | Out-Null
    }
    if (@($NativeVerification.Artifacts).Count -ne 2) {
        $issues.Add(('Expected Windows-native analysis for two current-case targets; observed {0}.' -f @($NativeVerification.Artifacts).Count)) | Out-Null
    }

    $staticFiles = @($StaticAnalysis.Artifacts | ForEach-Object { @($_.Files) } | ForEach-Object { $_ })
    $envelopes = @($staticFiles | ForEach-Object { @($_.Envelopes) } | ForEach-Object { Get-NpuSignatureEnvelopeTree -Envelope $_ })
    $parseFailures = @($envelopes | Where-Object { [string]$_.Status -ne 'Parsed' })
    $digestMismatches = @($envelopes | Where-Object {
        $null -ne $_.PSObject.Properties['PeDigestMatchesSignedDigest'] -and $_.PeDigestMatchesSignedDigest -eq $false
    })
    if ($parseFailures.Count -ne 0) {
        $issues.Add(('CMS/Authenticode envelope parse failures={0}.' -f $parseFailures.Count)) | Out-Null
    }
    if ($digestMismatches.Count -ne 0) {
        $issues.Add(('PE signed-digest mismatches={0}.' -f $digestMismatches.Count)) | Out-Null
    }
    if ([int]$KernelCoverage.KernelFileCount -le 0) {
        $issues.Add('No kernel binary was available for catalog-bound qualification.') | Out-Null
    }
    if ([int]$KernelCoverage.FullyCoveredKernelCount -ne [int]$KernelCoverage.KernelFileCount) {
        $issues.Add(('Catalog-bound kernel coverage is incomplete: {0}/{1}.' -f [int]$KernelCoverage.FullyCoveredKernelCount,[int]$KernelCoverage.KernelFileCount)) | Out-Null
    }
    if ([int]$KernelCoverage.CoverageGapKernelCount -ne 0) {
        $issues.Add(('Kernel coverage gaps={0}.' -f [int]$KernelCoverage.CoverageGapKernelCount)) | Out-Null
    }
    if ([int]$KernelCoverage.AssociationUnavailableKernelCount -ne 0) {
        $issues.Add(('Catalog association unavailable for {0} kernel file(s).' -f [int]$KernelCoverage.AssociationUnavailableKernelCount)) | Out-Null
    }
    if ([int]$KernelCoverage.RequiredProfileNonZeroCount -ne 0) {
        $issues.Add(('Required catalog-bound SignTool non-zero results={0}.' -f [int]$KernelCoverage.RequiredProfileNonZeroCount)) | Out-Null
    }

    return [pscustomobject][ordered]@{
        SchemaVersion='amd-npu-windows-client-signature-qualification/1.0'
        Requested=$true
        Status=if($issues.Count -eq 0){'Pass'}else{'Fail'}
        ExpectedExecutionClass='WindowsClient'
        ExpectedFullResearchArtifactCount=3
        ExpectedCertificateTargetCount=2
        StaticEnvelopeCount=$envelopes.Count
        EnvelopeParseFailureCount=$parseFailures.Count
        PeDigestMismatchCount=$digestMismatches.Count
        KernelCoverage=$KernelCoverage
        Issues=@($issues.ToArray())
        EnablesOnPass='Client evidence review and explicit decision whether to authorize the separate Windows Server gate.'
    }
}

function Test-NpuWindowsClientSignatureQualificationAssessmentSelfTest {
    [CmdletBinding()]
    param()

    $plan=[pscustomobject]@{Policy='NewestWithinEachCurrentNpuTypeCase';FullResearchArtifactCount=3;CertificateVerificationTargetCount=2;MissingTargets=@()}
    $envelope=[pscustomobject]@{Status='Parsed';PeDigestMatchesSignedDigest=$true;NestedSignatures=@();TimestampTokens=@()}
    $static=[pscustomobject]@{Artifacts=@(
        [pscustomobject]@{Files=@([pscustomobject]@{Envelopes=@($envelope)})},
        [pscustomobject]@{Files=@([pscustomobject]@{Envelopes=@($envelope)})}
    )}
    $native=[pscustomobject]@{ExecutionContext=[pscustomobject]@{ExecutionClass='WindowsClient'};Tool=[pscustomobject]@{Status='Available'};Artifacts=@([pscustomobject]@{},[pscustomobject]@{});MutationPerformed=$false}
    $coverage=[pscustomobject]@{KernelFileCount=2;FullyCoveredKernelCount=2;CoverageGapKernelCount=0;AssociationUnavailableKernelCount=0;RequiredProfileNonZeroCount=0}
    $good=Get-NpuWindowsClientSignatureQualificationAssessment -ExecutionPlan $plan -StaticAnalysis $static -NativeVerification $native -KernelCoverage $coverage
    $badNative=[pscustomobject]@{ExecutionContext=[pscustomobject]@{ExecutionClass='WindowsClient'};Tool=[pscustomobject]@{Status='NotFound'};Artifacts=@([pscustomobject]@{},[pscustomobject]@{});MutationPerformed=$false}
    $bad=Get-NpuWindowsClientSignatureQualificationAssessment -ExecutionPlan $plan -StaticAnalysis $static -NativeVerification $badNative -KernelCoverage $coverage
    $ok=($good.Status -eq 'Pass' -and $bad.Status -eq 'Fail' -and @($bad.Issues).Count -eq 1)
    return [pscustomobject][ordered]@{Status=if($ok){'Pass'}else{'Fail'};PositiveStatus=$good.Status;NegativeStatus=$bad.Status;NegativeIssueCount=@($bad.Issues).Count}
}

function ConvertTo-NpuPublicSignToolCheck {
    param([Parameter(Mandatory=$true)]$Check)
    return [pscustomobject][ordered]@{
        Policy=$Check.Policy;VerificationProfileId=$Check.VerificationProfileId;Arguments=@($Check.Arguments);ExitCode=$Check.ExitCode
        Status=$Check.Status;ResultClass=$Check.ResultClass;CatalogFileId=$Check.CatalogFileId;OutputSha256=$Check.OutputSha256
        OutputLineCount=$Check.OutputLineCount;Error=$Check.Error
    }
}

function ConvertTo-NpuPrivateSignToolCheck {
    param([Parameter(Mandatory=$true)]$Check)
    return [pscustomobject][ordered]@{
        Policy=$Check.Policy;VerificationProfileId=$Check.VerificationProfileId;Arguments=@($Check.Arguments);ExitCode=$Check.ExitCode
        Status=$Check.Status;ResultClass=$Check.ResultClass;CatalogFileId=$Check.CatalogFileId;Output=@($Check.PrivateOutput);Error=$Check.Error
    }
}

function Invoke-NpuSignatureStage {
    [CmdletBinding()]
    param(
        [switch]$LocalPackageOverride,
        [string]$OutputPath,
        [string]$NativeVerificationPath,
        [string]$WindowsHostPosturePath,
        [string]$ServerHostPosturePath,
        [switch]$RequireWindowsClientQualification
    )

    $toolRoot=Get-AmdResearchToolkitRoot
    if(-not $OutputPath){$OutputPath=Join-Path $toolRoot 'inventory/signature-analysis.json'}
    if(-not $NativeVerificationPath){$NativeVerificationPath=Join-Path $toolRoot 'inventory/host/signature-native-verification.json'}
    if(-not $WindowsHostPosturePath){$WindowsHostPosturePath=Join-Path $toolRoot 'inventory/host/windows-host-security-posture.json'}
    if(-not $ServerHostPosturePath){$ServerHostPosturePath=Join-Path $toolRoot 'inventory/host/target-server-host-evidence.json'}

    $null=Assert-AmdExtractionCompleteSet -Items @($script:ExtractedPackages) -Context 'NPU signature analysis'
    $executionPlan=Get-NpuEffectiveCertificateVerificationPlan -Metadata $script:ReleaseMetadataDoc -ExtractedPackages @($script:ExtractedPackages) -ArtifactCatalog $script:ArtifactCatalogDoc -LocalPackageOverride:$LocalPackageOverride
    if($executionPlan.Status -ne 'Ready'){
        throw('Certificate verification execution plan is blocked: missing targets={0}; selected targets={1}.' -f $executionPlan.MissingTargets.Count,$executionPlan.CertificateVerificationTargetCount)
    }
    $runtimeContext=Get-AmdWindowsExecutionContext
    $signTool=Get-AmdWindowsSdkToolInfo -ToolName 'signtool.exe'
    if($RequireWindowsClientQualification -and $runtimeContext.ExecutionClass -ne 'WindowsClient'){
        throw('Windows Client signature qualification requires ExecutionClass=WindowsClient; observed {0}.' -f $runtimeContext.ExecutionClass)
    }
    if($RequireWindowsClientQualification -and $signTool.Status -ne 'Available'){
        throw('Windows Client signature qualification requires signtool.exe; observed status={0}.' -f $signTool.Status)
    }
    Write-AmdStep ('Certificate verification execution class: {0}.' -f $runtimeContext.ExecutionClass)
    $operatorMessages=Get-NpuCertificateVerificationOperatorMessages -ExecutionPlan $executionPlan
    Write-AmdStep ([string]$operatorMessages.ScopeLine)
    foreach($line in @($operatorMessages.ExclusionLines)){Write-AmdStep ([string]$line)}

    if($null -eq $script:NpuToolchainCapabilityEvidence){$script:NpuToolchainCapabilityEvidence=Get-AmdWindowsDriverToolchainCapabilityEvidence}
    Write-AmdJsonFile -Path (Join-Path $toolRoot 'inventory/host/toolchain-capabilities-private.json') -Value $script:NpuToolchainCapabilityEvidence.PrivateEvidence -Depth 40
    Write-AmdJsonFile -Path (Join-Path $toolRoot 'inventory/toolchain-capabilities.json') -Value $script:NpuToolchainCapabilityEvidence.PublicSummary -Depth 40

    $artifactResults=New-Object System.Collections.Generic.List[object]
    $nativeArtifactResults=New-Object System.Collections.Generic.List[object]
    $signatureStageSw=[Diagnostics.Stopwatch]::StartNew()
    $targetOrdinal=0
    foreach($target in @($executionPlan.SelectedTargets)){
        $targetOrdinal++
        $artifactId=[string]$target.ArtifactId;$root=[string]$target.ExtractRoot
        if(-not(Test-Path -LiteralPath $root -PathType Container)){throw('Planned certificate target extraction root is unavailable: {0}' -f [string]$target.FileName)}
        $candidateFiles=@(Get-ChildItem -LiteralPath $root -File -Recurse -ErrorAction SilentlyContinue|Where-Object{Test-AmdStaticSignatureCandidateFile -File $_}|Sort-Object FullName)
        $groups=@($candidateFiles|Group-Object{Get-AmdSha256 -Path $_.FullName}|Sort-Object Name)
        $certificateStore=@{};$files=New-Object System.Collections.Generic.List[object];$nativeFiles=New-Object System.Collections.Generic.List[object];$verificationPathByFileId=@{}
        $groupIndex=0
        Write-AmdStep (Get-NpuCertificateTargetOperatorLine -Target $target -Ordinal $targetOrdinal -TargetCount $executionPlan.CertificateVerificationTargetCount -UniqueFileContentGroupCount $groups.Count)
        foreach($group in $groups){
            $groupIndex++;$representative=$group.Group|Select-Object -First 1
            $occurrences=@($group.Group|ForEach-Object{$_.FullName.Substring($root.Length).TrimStart('\','/')}|Sort-Object -Unique)
            $fileEvidence=Get-AmdStaticFileSignatureEvidence -Path $representative.FullName -Occurrences $occurrences -CertificateStore $certificateStore
            $files.Add($fileEvidence)|Out-Null
            if($runtimeContext.ExecutionClass -in @('WindowsClient','WindowsServer','WindowsOther')){
                $nativePath=$representative.FullName;$pathKind='OriginalExtractedPath'
                if($fileEvidence.FileType -eq 'Catalog' -and [IO.Path]::GetExtension($representative.Name) -ine '.cat'){
                    $aliasRoot=Join-Path (Join-Path (Get-AmdPrivateEvidenceRoot) 'native-signature-aliases') (ConvertTo-AmdEvidenceSafeFragment -Value $artifactId)
                    New-AmdDirectory -Path $aliasRoot|Out-Null;$nativePath=Join-Path $aliasRoot ('{0}.cat' -f [string]$fileEvidence.Sha256)
                    if(-not(Test-Path -LiteralPath $nativePath -PathType Leaf)){Copy-Item -LiteralPath $representative.FullName -Destination $nativePath -Force}
                    $pathKind='ByteIdenticalCanonicalCatalogAlias'
                }
                $verificationPathByFileId[[string]$fileEvidence.FileId]=$nativePath
                $authenticode=Get-AmdWindowsAuthenticodeObservation -Path $nativePath;$catalogEnumeration=$null;$catalogHash=$null
                if($fileEvidence.FileType -eq 'Catalog'){$catalogEnumeration=Get-AmdWindowsCatalogMemberEvidence -Path $nativePath}
                elseif($fileEvidence.FileType -eq 'KernelBinary'){$catalogHash=Get-AmdWindowsCatalogHashEvidence -Path $nativePath}
                $checks=@();if($signTool.Status -eq 'Available'){$checks=@(Get-AmdSignToolVerificationEvidence -SignToolPath $signTool.Path -Path $nativePath -FileType $fileEvidence.FileType)}
                $nativeFiles.Add([pscustomobject][ordered]@{
                    FileId=$fileEvidence.FileId;FileName=$fileEvidence.FileName;FileType=$fileEvidence.FileType;VerificationPathKind=$pathKind
                    Authenticode=$authenticode;CatalogEnumeration=$catalogEnumeration;CatalogHash=$catalogHash
                    SignToolChecks=@($checks|ForEach-Object{ConvertTo-NpuPrivateSignToolCheck -Check $_})
                    SanitizedSignToolSummary=@($checks|ForEach-Object{ConvertTo-NpuPublicSignToolCheck -Check $_})
                    SignToolStatus=if($signTool.Status -eq 'Available'){'Available'}else{'NotObservedToolUnavailable'}
                })|Out-Null
            }
            if($groupIndex -eq 1 -or ($groupIndex%10)-eq 0 -or $groupIndex -eq $groups.Count){Write-AmdStep ('Certificate verification {0}: file {1}/{2}; elapsed={3}' -f $artifactId,$groupIndex,$groups.Count,(Format-AmdElapsed $signatureStageSw.Elapsed))}
        }

        if($runtimeContext.ExecutionClass -in @('WindowsClient','WindowsServer','WindowsOther') -and $signTool.Status -eq 'Available'){
            $staticFileById=@{};foreach($f in @($files.ToArray())){$staticFileById[[string]$f.FileId]=$f}
            $catalogIdsByDigest=@{}
            foreach($catalog in @($nativeFiles.ToArray()|Where-Object{$_.FileType -eq 'Catalog' -and $_.CatalogEnumeration -and $_.CatalogEnumeration.Status -eq 'Enumerated'})){
                foreach($member in @($catalog.CatalogEnumeration.Members)){$tag=([string]$member.ReferenceTag).ToUpperInvariant();if([string]::IsNullOrWhiteSpace($tag)){continue};if(-not$catalogIdsByDigest.ContainsKey($tag)){$catalogIdsByDigest[$tag]=New-Object System.Collections.Generic.List[string]};if(-not$catalogIdsByDigest[$tag].Contains([string]$catalog.FileId)){$catalogIdsByDigest[$tag].Add([string]$catalog.FileId)|Out-Null}}
            }
            foreach($kernel in @($nativeFiles.ToArray()|Where-Object{$_.FileType -eq 'KernelBinary'})){
                $catalogIds=New-Object System.Collections.Generic.List[string]
                if($kernel.CatalogHash){foreach($digest in @([string]$kernel.CatalogHash.Sha256,[string]$kernel.CatalogHash.Sha1)){if([string]::IsNullOrWhiteSpace($digest)){continue};$key=$digest.ToUpperInvariant();if($catalogIdsByDigest.ContainsKey($key)){foreach($id in @($catalogIdsByDigest[$key].ToArray())){if(-not$catalogIds.Contains($id)){$catalogIds.Add($id)|Out-Null}}}}}
                $targetChecks=New-Object System.Collections.Generic.List[object]
                foreach($catalogId in @($catalogIds.ToArray())){if($verificationPathByFileId.ContainsKey($catalogId)-and$verificationPathByFileId.ContainsKey([string]$kernel.FileId)){foreach($check in @(Get-AmdCatalogBoundSignToolEvidence -SignToolPath $signTool.Path -DriverPath $verificationPathByFileId[[string]$kernel.FileId] -CatalogPath $verificationPathByFileId[$catalogId] -CatalogFileId $catalogId)){$targetChecks.Add($check)|Out-Null}}}
                if($targetChecks.Count -gt 0){$kernel.SignToolChecks=@($kernel.SignToolChecks)+@($targetChecks.ToArray()|ForEach-Object{ConvertTo-NpuPrivateSignToolCheck -Check $_});$kernel.SanitizedSignToolSummary=@($kernel.SanitizedSignToolSummary)+@($targetChecks.ToArray()|ForEach-Object{ConvertTo-NpuPublicSignToolCheck -Check $_})}
                else{$kernel|Add-Member -NotePropertyName CatalogBoundTargetVerification -NotePropertyValue ([pscustomobject][ordered]@{Status='NotObservedCatalogAssociationUnavailable';MatchedCatalogCount=0}) -Force}
            }
        }

        $certificates=@($certificateStore.Keys|Sort-Object|ForEach-Object{$certificateStore[$_]})
        $artifactResult=[pscustomobject][ordered]@{
            SchemaVersion=$script:AmdDriverSignatureAnalysisSchemaVersion;EvidenceScope='Static';ArtifactId=$artifactId;FileName=[string]$target.FileName
            PublishedDriverLabel=[string]$target.PublishedDriverLabel;SelectionLaneId=[string]$target.SelectionLaneId;SelectionReason=[string]$target.SelectionReason
            Status='Analyzed';FileCount=$files.Count;UniqueCertificateCount=$certificates.Count;Files=@($files.ToArray());Certificates=$certificates
        }
        $artifactResults.Add($artifactResult)|Out-Null
        foreach($analysis in @($script:Analyses|Where-Object{[string]$_.Artifact.FileName -ieq [string]$target.FileName})){$analysis|Add-Member -NotePropertyName SignatureAnalysis -NotePropertyValue $artifactResult -Force}
        if($runtimeContext.ExecutionClass -in @('WindowsClient','WindowsServer','WindowsOther')){$nativeArtifactResults.Add([pscustomobject][ordered]@{ArtifactId=$artifactId;FileName=[string]$target.FileName;PublishedDriverLabel=[string]$target.PublishedDriverLabel;SelectionLaneId=[string]$target.SelectionLaneId;SignToolStatus=$signTool.Status;SignToolVersion=$signTool.Version;Files=@($nativeFiles.ToArray())})|Out-Null}
    }

    $staticOutput=[pscustomobject][ordered]@{
        SchemaVersion=$script:AmdDriverSignatureAnalysisSchemaVersion;ToolkitVersion=$script:ToolVersion;GeneratedAtUtc=Get-AmdUtcTimestamp;EvidenceScope='Static'
        ArtifactSelectionPolicy=$executionPlan.Policy;CandidateArtifactCount=$executionPlan.FullResearchArtifactCount
        AnalyzedArtifactIds=@($executionPlan.SelectedTargets|ForEach-Object{[string]$_.ArtifactId});CertificateVerificationExecutionPlan=$executionPlan
        AnalysisBoundary='Static CMS/PKCS#7, nested-signature, certificate and signed-PE-digest evidence is host-neutral. Windows trust policy, target-server acceptance, PnP installation, kernel load and NPU functionality remain separate evidence scopes.'
        Artifacts=@($artifactResults.ToArray());Summary=('full research NPU packages={0}; deep certificate targets={1}; executionClass={2}; policy={3}' -f $executionPlan.FullResearchArtifactCount,$artifactResults.Count,$runtimeContext.ExecutionClass,$executionPlan.Policy)
    }
    Write-AmdJsonFile -Path $OutputPath -Value $staticOutput -Depth 80;$script:NpuSignatureAnalysisDoc=$staticOutput

    $nativeOutput=[pscustomobject][ordered]@{
        SchemaVersion=$script:AmdDriverSignatureNativeSchemaVersion;ToolkitVersion=$script:ToolVersion;CollectedAtUtc=Get-AmdUtcTimestamp;EvidenceScope='WindowsNative'
        ArtifactSelectionPolicy=$executionPlan.Policy;CandidateArtifactCount=$executionPlan.FullResearchArtifactCount;AnalyzedArtifactIds=@($executionPlan.SelectedTargets|ForEach-Object{[string]$_.ArtifactId})
        ExecutionContext=$runtimeContext;Tool=[pscustomobject][ordered]@{Name='signtool.exe';Status=$signTool.Status;Version=$signTool.Version;FileVersion=$signTool.FileVersion;ProductVersion=$signTool.ProductVersion;Sha256=$signTool.Sha256;SizeBytes=$signTool.SizeBytes;Architecture=$signTool.Architecture;Path=$signTool.Path;PortablePath=$signTool.PortablePath;KitVersion=$signTool.KitVersion}
        ToolchainCapabilityReference='inventory/host/toolchain-capabilities-private.json';ToolchainCapabilitySummaryReference='inventory/toolchain-capabilities.json';Artifacts=@($nativeArtifactResults.ToArray());MutationPerformed=$false
    }
    $coverage=if($runtimeContext.ExecutionClass -in @('WindowsClient','WindowsServer','WindowsOther')){Get-AmdKernelSignatureCoverageAssessment -NativeData ([pscustomobject]@{Releases=@($nativeArtifactResults.ToArray())})}else{$null}
    $qualification=$null
    if($RequireWindowsClientQualification){
        $qualification=Get-NpuWindowsClientSignatureQualificationAssessment -ExecutionPlan $executionPlan -StaticAnalysis $staticOutput -NativeVerification $nativeOutput -KernelCoverage $coverage
        $nativeOutput|Add-Member -NotePropertyName WindowsClientQualification -NotePropertyValue $qualification -Force
    }
    else{
        $nativeOutput|Add-Member -NotePropertyName WindowsClientQualification -NotePropertyValue ([pscustomobject][ordered]@{SchemaVersion='amd-npu-windows-client-signature-qualification/1.0';Requested=$false;Status='NotRequested'}) -Force
    }
    Write-AmdJsonFile -Path $NativeVerificationPath -Value $nativeOutput -Depth 80;$script:NpuSignatureNativeDoc=$nativeOutput
    if($runtimeContext.ExecutionClass -in @('WindowsClient','WindowsServer','WindowsOther')){$posture=Get-AmdWindowsHostSecurityPosture;Write-AmdJsonFile -Path $WindowsHostPosturePath -Value $posture -Depth 30;if($runtimeContext.ExecutionClass -eq 'WindowsServer'){Write-AmdJsonFile -Path $ServerHostPosturePath -Value (Get-AmdTargetServerHostEvidence -WindowsHostSecurityPosture $posture) -Depth 40}}
    if($RequireWindowsClientQualification -and $qualification.Status -ne 'Pass'){
        throw('Windows Client signature qualification failed: {0}' -f (@($qualification.Issues) -join ' | '))
    }
    $coverageText=if($coverage){'; catalog-bound kernel coverage={0}/{1}; association unavailable={2}' -f $coverage.FullyCoveredKernelCount,$coverage.KernelFileCount,$coverage.AssociationUnavailableKernelCount}else{''}
    Write-AmdOk ('Certificate analysis -> full research NPU packages={0}; deep certificate targets={1}; policy={2}; WindowsNative={3}{4}' -f $executionPlan.FullResearchArtifactCount,$artifactResults.Count,$executionPlan.Policy,$runtimeContext.ExecutionClass,$coverageText)
    return $staticOutput
}

function Invoke-NpuBuildStage {
    [CmdletBinding()]
    param([switch]$SkipPublicExport)
    if($SkipPublicExport){Write-AmdSkip 'Public generation skipped by -SkipPublicExport.';return [pscustomobject]@{Summary='public generation skipped by caller';Skipped=$true}}
    $staging=Join-Path $script:RunRoot 'public-staging';if(Test-Path -LiteralPath $staging){Remove-Item -LiteralPath $staging -Recurse -Force};foreach($sub in @('releases','comparisons','catalog')){New-AmdDirectory -Path (Join-Path $staging $sub)|Out-Null}
    $hardwarePublic=ConvertTo-NpuPublicRepositoryObject -Value (Get-HardwareIdentityPublicDocument -HardwareDoc $script:HardwareDoc);$processorPublic=ConvertTo-NpuPublicRepositoryObject -Value (Get-ProcessorCatalogPublicDocument -ProcessorDoc $script:ProcessorDoc);$observedPublic=ConvertTo-NpuPublicRepositoryObject -Value (Get-ObservedRuntimePublicDocument -ObservedRuntimeDoc $script:ObservedRuntimeDoc)
    Write-JsonFile -Value $hardwarePublic -Path (Join-Path $staging 'catalog/hardware-identities.json') -Compress;Write-AmdPublicMarkdownText -Path (Join-Path $staging 'catalog/hardware-identities.md') -Text (Convert-HardwareIdentityToMarkdown -Document $hardwarePublic)
    Write-JsonFile -Value $processorPublic -Path (Join-Path $staging 'catalog/processor-catalog.json') -Compress;Write-AmdPublicMarkdownText -Path (Join-Path $staging 'catalog/processor-catalog.md') -Text (Convert-ProcessorCatalogToMarkdown -Document $processorPublic)
    Write-JsonFile -Value $observedPublic -Path (Join-Path $staging 'catalog/observed-runtime-evidence.json') -Compress;Write-AmdPublicMarkdownText -Path (Join-Path $staging 'catalog/observed-runtime-evidence.md') -Text (Convert-ObservedRuntimeEvidenceToMarkdown -Document $observedPublic)
    if($script:CompatibilityMatrix){$publicMatrix=ConvertTo-NpuPublicRepositoryObject -Value $script:CompatibilityMatrix;Write-JsonFile -Value $publicMatrix -Path (Join-Path $staging 'catalog/driver-compatibility-matrix.json') -Compress;Write-AmdPublicMarkdownText -Path (Join-Path $staging 'catalog/driver-compatibility-matrix.md') -Text (Convert-DriverCompatibilityMatrixToMarkdown -Matrix $publicMatrix)}
    if($script:ProcessorDriverApplicability){$publicApplicability=ConvertTo-NpuPublicRepositoryObject -Value $script:ProcessorDriverApplicability;Write-JsonFile -Value $publicApplicability -Path (Join-Path $staging 'catalog/processor-driver-applicability.json') -Compress;Write-AmdPublicMarkdownText -Path (Join-Path $staging 'catalog/processor-driver-applicability.md') -Text (Convert-ProcessorDriverApplicabilityToMarkdown -Document $publicApplicability)}
    foreach($a in @($script:Analyses)){$stem=[IO.Path]::GetFileNameWithoutExtension($a.Artifact.FileName)-replace '[^A-Za-z0-9._-]','_';$publicAnalysis=ConvertTo-NpuPublicRepositoryObject -Value $a;Write-JsonFile -Value $publicAnalysis -Path (Join-Path $staging ("releases/$stem.json")) -Compress;Write-AmdPublicMarkdownText -Path (Join-Path $staging ("releases/$stem.md")) -Text (Convert-AnalysisToMarkdown -Analysis $publicAnalysis)}
    foreach($c in @($script:Comparisons)){$ls=[IO.Path]::GetFileNameWithoutExtension($c.Left.FileName)-replace '[^A-Za-z0-9._-]','_';$rs=[IO.Path]::GetFileNameWithoutExtension($c.Right.FileName)-replace '[^A-Za-z0-9._-]','_';$stem="$ls--vs--$rs";$publicComparison=ConvertTo-NpuPublicRepositoryObject -Value $c;Write-JsonFile -Value $publicComparison -Path (Join-Path $staging ("comparisons/$stem.json")) -Compress;Write-AmdPublicMarkdownText -Path (Join-Path $staging ("comparisons/$stem.md")) -Text (Convert-ComparisonToMarkdown -Comparison $publicComparison)}
    $manifest=New-PublicationManifest -PublicRoot $staging -SourceScriptPath $script:SourceScriptPath;Write-JsonFile -Value $manifest -Path (Join-Path $staging 'publication-manifest.json') -Compress;$script:PendingPublicRoot=$staging
    return [pscustomobject]@{Summary=('candidatePublicFiles={0}; publicationScope=NpuResearchDataset' -f @(Get-ChildItem -LiteralPath $staging -File -Recurse).Count);StagingRoot=$staging;Skipped=$false}
}


function Invoke-NpuValidateStage {
    [CmdletBinding()]
    param([switch]$SkipPublicExport)
    $target=if($script:PendingPublicRoot){$script:PendingPublicRoot}else{$script:ResolvedPublicOutputRoot};if(-not(Test-Path -LiteralPath $target -PathType Container)){throw('No public surface exists to validate: {0}' -f $target)}
    $validation=Test-AmdPublicRepositorySurface -Root $target -DatasetValidator {param($root) Test-NpuPublicDatasetConsistency -Root $root};$issues=New-Object 'System.Collections.Generic.List[string]';foreach($i in @($validation.Errors)){$issues.Add([string]$i)|Out-Null};foreach($i in @(Test-PublicationManifest -PublicRoot $target -SourceScriptPath $script:SourceScriptPath)){$issues.Add([string]$i)|Out-Null}
    if($issues.Count -gt 0){throw('Public validation failed: '+($issues -join '; '))}
    if($script:PendingPublicRoot -and -not $SkipPublicExport){$backup=Join-Path $script:RunRoot 'public-previous';$null=Publish-AmdRepositorySurface -CandidateRoot $script:PendingPublicRoot -PublicRoot $script:ResolvedPublicOutputRoot -BackupRoot $backup;$script:PendingPublicRoot=$null}
    return [pscustomobject]@{Summary=('public validation passed; privacy={0}; dataset={1}; JSON={2}; Markdown={3}; promotionScope=NpuResearchDataset' -f $validation.PrivacyStatus,$validation.DatasetConsistencyStatus,$validation.JsonWhitespaceStatus,$validation.MarkdownFormatStatus);Status='Pass';ValidatedRoot=$script:ResolvedPublicOutputRoot;Validation=$validation}
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
        [ValidateSet('ZipOnly','ZipAndDirectory')][string]$EvidenceRetention='ZipOnly',
        [string]$PublicOutputRoot,
        [switch]$SkipPublicExport,
        [switch]$SkipEvidenceArchive,
        [switch]$IncludePackagesInEvidence,
        [switch]$RequireWindowsClientSignatureQualification,
        [switch]$ResolveHardwareSelection,
        [switch]$UseObservedNpuHardwareIdOverride,
        [string[]]$ObservedNpuHardwareId=@(),
        [int]$TargetWindowsBuild=0,
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
    $script:RunStartTime=Get-Date;$script:AmdRunStartTime=$script:RunStartTime;$script:NpuFinalConsoleReportWritten=$false
    $finalAssessment=$null;$finalExitCode=1;$resolvedStages=@();$discovery=$null;$metadata=$null
    $effectiveTargetWindowsBuild=$TargetWindowsBuild;$windowsBuildEvidence=$null

    # Keep invocation evidence construction side-effect free so even path/bootstrap failures
    # can be captured by the emergency evidence path.
    $invocation=[pscustomobject][ordered]@{
        Stages=@($Stages);PackagePath=@($PackagePath|ForEach-Object{[IO.Path]::GetFileName([string]$_)});ArtifactId=@($ArtifactId)
        Mode=if(-not [string]::IsNullOrWhiteSpace([string]$Mode)){$Mode}else{$null};OutputRoot=$OutputRoot;EvidenceOutputRoot=$EvidenceOutputRoot;EvidenceLabel=$EvidenceLabel;EvidenceRetention=$EvidenceRetention
        PublicOutputRoot=$PublicOutputRoot;SkipPublicExport=[bool]$SkipPublicExport;SkipEvidenceArchive=[bool]$SkipEvidenceArchive;IncludePackagesInEvidence=[bool]$IncludePackagesInEvidence;RequireWindowsClientSignatureQualification=[bool]$RequireWindowsClientSignatureQualification
        ResolveHardwareSelection=[bool]$ResolveHardwareSelection;UseObservedNpuHardwareIdOverride=[bool]$UseObservedNpuHardwareIdOverride;ObservedNpuHardwareId=@($ObservedNpuHardwareId);RequestedTargetWindowsBuild=$TargetWindowsBuild
        Force=[bool]$Force;DownloadRetryCount=$DownloadRetryCount;DownloadTimeoutSeconds=$DownloadTimeoutSeconds;SevenZipPath=$SevenZipPath;ExtractionMaxDepth=$ExtractionMaxDepth;DocumentationUri=@($DocumentationUri);AdditionalDriverUrl=@($AdditionalDriverUrl);AllowNonAmdHost=[bool]$AllowNonAmdHost
    }

    try {
        Write-Host '=== AMD NPU Driver Research Toolkit — BOOTSTRAP ===' -ForegroundColor Cyan
        Write-Host ('Toolkit    : {0}' -f $script:ToolVersion)
        Write-Host ('PowerShell : {0}' -f $PSVersionTable.PSVersion)
        Write-Host ('Requested  : {0}' -f (@($Stages)-join ', '))
        $resolvedStages=@(Resolve-NpuRequestedStages -Stages $Stages -Mode $Mode)
        $startupPathAssessment=Get-AmdPathSafetyAssessment -SevenZipPath $SevenZipPath -ResolvedStages $resolvedStages
        if([string]$startupPathAssessment.Status -eq 'Blocked'){
            Write-Host '=== AMD NPU Driver Research Toolkit — PATH SAFETY BLOCK ===' -ForegroundColor Red
            foreach($issue in @($startupPathAssessment.Issues)){Write-Host ('BLOCK: {0}' -f [string]$issue) -ForegroundColor Red}
            Write-Host ('Move whole tool : {0}' -f [string]$startupPathAssessment.RecommendedToolRoot) -ForegroundColor Yellow
            Write-Host 'No AMD network request was started.' -ForegroundColor Yellow
            throw('PathSafety BLOCKED: {0}' -f (@($startupPathAssessment.Issues)-join ' | '))
        }
        Write-Host 'Initializing tool-local evidence session and Canonical JSON runtime...' -ForegroundColor Cyan
        # Predecessor parity: evidence is established before work-root initialization or network access.
        $null=Start-AmdResearchEvidenceSession -OutputRoot $EvidenceOutputRoot -Label $EvidenceLabel -EvidenceRetention $EvidenceRetention -InvocationParameters $invocation

        $resolvedOutputRoot=if([string]::IsNullOrWhiteSpace([string]$OutputRoot)){Join-Path $PSScriptRoot 'work'}else{$OutputRoot}
        $resolvedOutputRoot=[IO.Path]::GetFullPath($resolvedOutputRoot);New-AmdDirectory -Path $resolvedOutputRoot|Out-Null
        $runId=[DateTime]::UtcNow.ToString('yyyyMMddTHHmmssfffZ');$script:RunRoot=Join-Path $resolvedOutputRoot ('run-'+$runId)
        if((Test-Path -LiteralPath $script:RunRoot)-and -not $NoClean){Remove-Item -LiteralPath $script:RunRoot -Recurse -Force}
        New-AmdDirectory -Path $script:RunRoot|Out-Null
        $script:ResolvedPublicOutputRoot=Resolve-NpuPublicOutputRootPath -RequestedPath $PublicOutputRoot

        $script:ResolvedStageCount=$resolvedStages.Count;$script:AmdResolvedStageCount=$resolvedStages.Count;$script:StageOrdinal=0;$script:AmdStageOrdinal=0
        if($RequireWindowsClientSignatureQualification){
            if($resolvedStages -notcontains 'Signature'){throw 'Windows Client signature qualification requires the Signature stage.'}
            if($PackagePath.Count -gt 0 -or $ArtifactId.Count -gt 0){throw 'Windows Client signature qualification requires the default reviewed artifact corpus; do not use -PackagePath or -ArtifactId.'}
            if($SkipEvidenceArchive){throw 'Windows Client signature qualification requires an Evidence ZIP; do not use -SkipEvidenceArchive.'}
        }
        if($ResolveHardwareSelection){
            if($resolvedStages -notcontains 'HardwareIdentity'){throw 'Hardware selection resolution requires the HardwareIdentity stage.'}
            if(@($ObservedNpuHardwareId).Count -gt 0 -and -not $UseObservedNpuHardwareIdOverride){throw '-ObservedNpuHardwareId is an offline/test input and requires -UseObservedNpuHardwareIdOverride. Omit both parameters for normal local PnP enumeration.'}
            if($UseObservedNpuHardwareIdOverride -and @($ObservedNpuHardwareId).Count -eq 0){throw '-UseObservedNpuHardwareIdOverride requires at least one -ObservedNpuHardwareId value; an empty manual override cannot prove a completed no-NPU enumeration.'}
            if($effectiveTargetWindowsBuild -lt 1){
                $windowsBuildEvidence=Get-NpuLocalWindowsBuildEvidence
                if([string]$windowsBuildEvidence.Status -ne 'Complete'){throw ('Hardware selection could not determine the local Windows build: {0}' -f [string]$windowsBuildEvidence.Error)}
                $effectiveTargetWindowsBuild=[int]$windowsBuildEvidence.Build
            }
            else{$windowsBuildEvidence=[pscustomobject][ordered]@{Status='Complete';Build=$effectiveTargetWindowsBuild;Source='ExplicitTargetWindowsBuild';Error=$null}}
        }
        elseif($UseObservedNpuHardwareIdOverride -or @($ObservedNpuHardwareId).Count -gt 0){
            throw 'Hardware identity override parameters require -ResolveHardwareSelection.'
        }
        $startupPlatform=Get-AmdPlatformInfo
        Write-Host '=== AMD NPU Driver Research Toolkit ==='
        Write-Host ('Toolkit    : {0}' -f $script:ToolVersion)
        Write-Host ('PowerShell : {0}' -f $PSVersionTable.PSVersion)
        Write-Host ('Platform   : {0} ({1})' -f $startupPlatform.PlatformFamily,$startupPlatform.OSDescription)
        Write-Host ('Stages     : {0}' -f ($resolvedStages -join ', '))
        Write-Host ('Started    : {0}' -f $script:RunStartTime.ToString('yyyy-MM-dd HH:mm:ss'))
        Write-Host ('Root       : {0}' -f $PSScriptRoot)
        Write-Host ('Evidence ZIP planned : {0}' -f $script:EvidenceContext.ZipPath)
        Write-Host ('Evidence work dir    : {0}' -f $script:EvidenceContext.EvidenceDirectory)
        Write-Host ('Public     : {0}' -f $(if($SkipPublicExport){'SKIPPED'}else{$script:ResolvedPublicOutputRoot}))
        Write-Host ('Input mode : {0}' -f $(if($PackagePath.Count -gt 0){'Local PackagePath override'}else{'Automatic AMD publication acquisition'}))
        if($ResolveHardwareSelection){Write-Host ('NPU input  : {0}; Windows build={1} ({2})' -f $(if($UseObservedNpuHardwareIdOverride){'Explicit offline/test override'}else{'Automatic local Windows PnP enumeration'}),$effectiveTargetWindowsBuild,[string]$windowsBuildEvidence.Source)}
        Write-Host ''

        foreach($stage in $resolvedStages){
            $blocked=Get-NpuStageDependencyBlockReason -Name $stage -ResolvedStages $resolvedStages -PackagePath $PackagePath
            switch($stage){
                'PathSafety' {
                    $null=Invoke-AmdTrackedStage -Name 'PathSafety' -Body {
                        Write-AmdOk ('Path safety passed: root length={0}/{1}; predicted maximum={2}/{3}.' -f $startupPathAssessment.ToolRootLength,$startupPathAssessment.Policy.MaximumToolRootLength,$startupPathAssessment.PredictedPaths.MaximumDesignedExtractionPathLength,$startupPathAssessment.Policy.SafeFullPathLimit)
                        $startupPathAssessment
                    }
                }

                'Test' {
                    $null=Invoke-AmdTrackedStage -Name 'Test' -BlockedReason $blocked -Body {
                        $issues=New-Object 'System.Collections.Generic.List[string]'
                        $publicRootProbe=Join-Path $script:RunRoot 'public-output-root-regression-probe';$expectedPublicRootProbe=[IO.Path]::GetFullPath($publicRootProbe);$actualPublicRootProbe=Resolve-NpuPublicOutputRootPath -RequestedPath $publicRootProbe;if($actualPublicRootProbe -ne $expectedPublicRootProbe){$issues.Add(('PublicOutputRoot resolver ignored explicit path. expected={0}; actual={1}' -f $expectedPublicRootProbe,$actualPublicRootProbe))|Out-Null}
                        foreach($i in @(Invoke-AmdTimedOperation 'Windows PowerShell 5.1 source compatibility' { @(Test-WindowsPowerShell51SourceCompatibility -Path $script:SourceScriptPath) })){$issues.Add([string]$i)|Out-Null}
                        $script:PredecessorCoreContractDoc=Get-ReviewedJsonDocument (Join-Path $PSScriptRoot 'data/current-three-tool-common-core-contract.json')
                        foreach($i in @(Invoke-AmdTimedOperation 'Current three-tool common-core parity contract' { @(Test-NpuPredecessorParityContract -Stages $Stages -Mode $Mode) })){$issues.Add([string]$i)|Out-Null}
                        $script:PredecessorExtractionContractDoc=Get-ReviewedJsonDocument (Join-Path $PSScriptRoot 'data/predecessor-extraction-core-contract.json')
                        foreach($i in @(Invoke-AmdTimedOperation 'Extraction parity contract' { @(Test-NpuExtractionParityContract) })){$issues.Add([string]$i)|Out-Null}
                        foreach($i in @(Invoke-AmdTimedOperation 'Architecture convergence contract' { @(Test-NpuArchitectureConvergenceContract) })){$issues.Add([string]$i)|Out-Null}
                        try{$script:SevenZipInfo=Invoke-AmdTimedOperation '7-Zip qualification' { Get-AmdSevenZipInfo -ExplicitPath $SevenZipPath };if($script:SevenZipInfo.Status -ne 'Available'){$issues.Add(('7-Zip is not ready: {0}' -f $script:SevenZipInfo.Guidance))|Out-Null}}catch{$issues.Add(('7-Zip qualification failed: {0}' -f $_.Exception.Message))|Out-Null}
                        $platformProbe=Get-NpuPlatformInfo
                        if($null -eq $platformProbe -or [string]::IsNullOrWhiteSpace([string]$platformProbe.Architecture)){$issues.Add('Platform probe did not produce an architecture value.')|Out-Null}
                        foreach($i in @(Invoke-AmdTimedOperation 'Reviewed source-data contracts' { @(Test-NpuReviewedSourceDataContracts) })){$issues.Add([string]$i)|Out-Null}
                        foreach($i in @(Invoke-AmdTimedOperation 'Tool version consistency' { @(Test-NpuToolVersionConsistency) })){$issues.Add([string]$i)|Out-Null}
                        $publicSchemaVersionSelfTest=Invoke-AmdTimedOperation 'NPU public schema version contracts' { Test-NpuPublicSchemaVersionContracts }
                        if([string]$publicSchemaVersionSelfTest.Status -ne 'Pass'){$issues.Add(('NPU public schema version self-test failed: {0}' -f ($publicSchemaVersionSelfTest|ConvertTo-Json -Depth 8 -Compress)))|Out-Null}
                        $script:ProfilesDoc=Get-ReviewedJsonDocument (Join-Path $PSScriptRoot 'data/windows-server-profiles.json')
                        $script:InstallerContractsDoc=Get-ReviewedJsonDocument (Join-Path $PSScriptRoot 'data/known-installer-contracts.json')
                        $script:DriverContractsDoc=Get-ReviewedJsonDocument (Join-Path $PSScriptRoot 'data/known-driver-binary-contracts.json')
                        $script:HardwareDoc=Get-ReviewedJsonDocument (Join-Path $PSScriptRoot 'data/hardware-identities.json')
                        $script:HardwareSelectionDoc=Get-ReviewedJsonDocument (Join-Path $PSScriptRoot 'data/hardware-driver-selection.json')
                        $script:ProcessorDoc=Get-ReviewedJsonDocument (Join-Path $PSScriptRoot 'data/processor-catalog.json')
                        $script:CompatibilityDoc=Get-ReviewedJsonDocument (Join-Path $PSScriptRoot 'data/driver-compatibility-rules.json')
                        $script:ObservedRuntimeDoc=Get-ReviewedJsonDocument (Join-Path $PSScriptRoot 'data/observed-runtime-evidence.json')
                        $script:ArtifactCatalogDoc=Get-ReviewedJsonDocument (Join-Path $PSScriptRoot 'data/published-driver-artifacts.json')
                        $script:ApplicabilityDoc=Get-ReviewedJsonDocument (Join-Path $PSScriptRoot 'data/processor-driver-applicability.json')
                        foreach($i in @(Invoke-AmdTimedOperation 'Published artifact catalog' { @(Test-NpuPublishedArtifactCatalog -Catalog $script:ArtifactCatalogDoc -AllowNonAmdHost:$AllowNonAmdHost) })){$issues.Add([string]$i)|Out-Null}
                        foreach($i in @(Invoke-AmdTimedOperation 'Hardware-driver selection data' { @(Test-NpuHardwareDriverSelectionData -SelectionDoc $script:HardwareSelectionDoc) })){$issues.Add([string]$i)|Out-Null}
                        foreach($i in @(Invoke-AmdTimedOperation 'Hardware-driver selection logic' { @(Test-NpuHardwareDriverSelectionLogic -SelectionDoc $script:HardwareSelectionDoc) })){$issues.Add([string]$i)|Out-Null}
                        foreach($i in @(Invoke-AmdTimedOperation 'Local hardware selection logic' { @(Test-NpuLocalHardwareSelectionLogic -SelectionDoc $script:HardwareSelectionDoc) })){$issues.Add([string]$i)|Out-Null}
                        foreach($i in @(Invoke-AmdTimedOperation 'Processor-driver applicability' { @(Test-ProcessorDriverApplicabilityResearchData -ApplicabilityDoc $script:ApplicabilityDoc -ArtifactCatalogDoc $script:ArtifactCatalogDoc) })){$issues.Add([string]$i)|Out-Null}
                        foreach($i in @(Invoke-AmdTimedOperation 'Package-lane selection logic' { @(Test-NpuPackageLaneSelectionLogic) })){$issues.Add([string]$i)|Out-Null}
                        foreach($i in @(Invoke-AmdTimedOperation 'Research/certificate scope separation' { @(Test-NpuResearchAndCertificateScopeSeparation -Catalog $script:ArtifactCatalogDoc) })){$issues.Add([string]$i)|Out-Null}
                        $signaturePrimitiveSelfTest=Invoke-AmdTimedOperation 'Signature primitives' { Test-AmdSignaturePrimitiveSelfTest }
                        $signatureSelfTests=@(
                            (Invoke-AmdTimedOperation 'Expected fallback probe' { Test-AmdExpectedFallbackProbeSelfTest }),
                            $signaturePrimitiveSelfTest,
                            (Invoke-AmdTimedOperation 'Signature content-type routing' { Test-AmdSignatureContentTypeRoutingSelfTest }),
                            (Invoke-AmdTimedOperation 'Toolchain capability parser' { Test-AmdToolchainCapabilityParserSelfTest }),
                            (Invoke-AmdTimedOperation 'SignTool verification profile' { Test-AmdSignToolVerificationProfileSelfTest }),
                            (Invoke-AmdTimedOperation 'Kernel signature coverage' { Test-AmdKernelSignatureCoverageSelfTest }),
                            (Invoke-AmdTimedOperation 'Native tool localization' { Test-AmdNativeToolLocalizationSelfTest }),
                            (Invoke-AmdTimedOperation 'Native interop type contract' { Test-AmdNativeInteropTypeContractSelfTest }),
                            (Invoke-AmdTimedOperation 'PowerShell 5.1 collection cardinality' { Test-AmdPowerShell51CollectionCardinalitySelfTest }),
                            (Invoke-AmdTimedOperation 'Collection-cardinality source contract' { Test-AmdCollectionCardinalitySourceContract -Path $script:SourceScriptPath }),
                            (Invoke-AmdTimedOperation 'NPU signature schema contracts' { Test-NpuSignatureSchemaContracts }),
                            (Invoke-AmdTimedOperation 'Windows Client signature qualification assessment' { Test-NpuWindowsClientSignatureQualificationAssessmentSelfTest }),
                            (Invoke-AmdTimedOperation 'Certificate verification execution plan' { Test-NpuCertificateVerificationExecutionPlanSelfTest }),
                            (Invoke-AmdTimedOperation 'Operator message contract' { Test-NpuOperatorMessageContractSelfTest })
                        )
                        foreach($selfTest in $signatureSelfTests){if([string]$selfTest.Status -ne 'Pass'){$issues.Add(('Signature self-test failed: {0}' -f ($selfTest|ConvertTo-Json -Depth 8 -Compress)))|Out-Null}}
                        $commonInfrastructureSelfTests=@(
                            (Invoke-AmdTimedOperation 'Diagnostic primitives' { Test-AmdDiagnosticPrimitiveSelfTest }),
                            (Invoke-AmdTimedOperation 'Sequential-download source contract' { Test-AmdSequentialDownloadSourceContract -Path $script:SourceScriptPath }),
                            (Invoke-AmdTimedOperation 'HTTP retry policy' { Test-AmdHttpRetryPolicySelfTest }),
                            (Invoke-AmdTimedOperation 'HTTP download transport' { Test-AmdHttpDownloadTransportSelfTest }),
                            (Invoke-AmdTimedOperation 'Path safety logic' { Test-AmdPathSafetyLogic }),
                            (Invoke-AmdTimedOperation 'Archive path safety logic' { Test-AmdArchivePathSafetyLogic }),
                            (Invoke-AmdTimedOperation 'Public repository path sanitization' { Test-NpuPublicRepositorySanitizationLogic }),
                            (Invoke-AmdTimedOperation 'Three-tool common-core contract' { Test-AmdThreeToolCommonCoreContract }),
                            (Invoke-AmdTimedOperation 'Ordinal ordering contract' { Test-AmdOrdinalOrderingSelfTest })
                            (Invoke-AmdTimedOperation 'Windows execution-context evidence contract' { Test-AmdWindowsExecutionContextSelfTest })
                        )
                        foreach($selfTest in $commonInfrastructureSelfTests){if([string]$selfTest.Status -ne 'Pass'){$issues.Add(('Common infrastructure self-test failed: {0}' -f ($selfTest|ConvertTo-Json -Depth 8 -Compress)))|Out-Null}}
                        $canonicalJsonEnumSelfTest=Invoke-AmdTimedOperation 'Canonical JSON enum serialization' { Test-AmdCanonicalJsonEnumSerializationSelfTest }
                        if([string]$canonicalJsonEnumSelfTest.Status -ne 'Pass'){$issues.Add(('Canonical JSON enum self-test failed: {0}' -f ($canonicalJsonEnumSelfTest|ConvertTo-Json -Depth 8 -Compress)))|Out-Null}
                        $canonicalJsonCrossRuntimeSelfTest=Invoke-AmdTimedOperation 'Canonical JSON cross-runtime contract' { Test-AmdCanonicalJsonCrossRuntimeSelfTest }
                        if([string]$canonicalJsonCrossRuntimeSelfTest.Status -ne 'Pass'){$issues.Add(('Canonical JSON cross-runtime self-test failed: {0}' -f ($canonicalJsonCrossRuntimeSelfTest|ConvertTo-Json -Depth 8 -Compress)))|Out-Null}
                        $utf8JsonSyntaxSelfTest=Invoke-AmdTimedOperation 'UTF-8 JSON syntax' { Test-NpuUtf8JsonSyntaxSelfTest }
                        if([string]$utf8JsonSyntaxSelfTest.Status -ne 'Pass'){$issues.Add(('UTF-8 JSON syntax self-test failed: {0}' -f ($utf8JsonSyntaxSelfTest|ConvertTo-Json -Depth 8 -Compress)))|Out-Null}
                        $evidenceSnapshotSelfTest=Invoke-AmdTimedOperation 'Evidence snapshot contract' { Test-NpuEvidenceSnapshotContract }
                        if([string]$evidenceSnapshotSelfTest.Status -ne 'Pass'){$issues.Add(('Evidence snapshot self-test failed: {0}' -f ($evidenceSnapshotSelfTest|ConvertTo-Json -Depth 8 -Compress)))|Out-Null}
                        $script:NpuToolchainCapabilityEvidence=Invoke-AmdTimedOperation 'Windows driver toolchain capability evidence' { Get-AmdWindowsDriverToolchainCapabilityEvidence }
                        Write-AmdJsonFile -Path (Join-Path $PSScriptRoot 'inventory/host/toolchain-capabilities-private.json') -Value $script:NpuToolchainCapabilityEvidence.PrivateEvidence -Depth 40
                        Write-AmdJsonFile -Path (Join-Path $PSScriptRoot 'inventory/toolchain-capabilities.json') -Value $script:NpuToolchainCapabilityEvidence.PublicSummary -Depth 40
                        $testStageEvidence=[pscustomobject][ordered]@{
                            SchemaVersion='amd-npu-test-stage-evidence/1.1'
                            ToolkitVersion=$script:ToolVersion
                            CollectedAtUtc=Get-AmdUtcTimestamp
                            PowerShellVersion=$PSVersionTable.PSVersion.ToString()
                            PSEdition=$(if($PSVersionTable.PSEdition){[string]$PSVersionTable.PSEdition}else{'Desktop'})
                            Status=$(if($issues.Count -eq 0){'Pass'}else{'Fail'})
                            SourceDataContractCount=@(Get-NpuReviewedSourceDataContracts).Count
                            HardwareOnlySelectionTestCount=10
                            PackageLaneSelectionTestCount=4
                            ResearchAndCertificateScopeTestCount=3
                            SignatureSelfTestCount=$signatureSelfTests.Count
                            CommonInfrastructureSelfTestCount=$commonInfrastructureSelfTests.Count
                            PublicSchemaVersionSelfTestCount=1
                            Utf8JsonSyntaxSelfTestCount=1
                            CanonicalJsonCrossRuntimeSelfTestCount=1
                            EvidenceSnapshotSelfTestCount=1
                            SignedCmsAvailable=[bool]$signaturePrimitiveSelfTest.SignedCmsAvailable
                            SignedCmsRuntime=$signaturePrimitiveSelfTest.SignedCmsRuntime
                            Utf8JsonSyntaxContract=$utf8JsonSyntaxSelfTest
                            CanonicalJsonCrossRuntimeContract=$canonicalJsonCrossRuntimeSelfTest
                            EvidenceSnapshotContract=$evidenceSnapshotSelfTest
                        }
                        $testStageEvidencePath=Join-Path $PSScriptRoot 'inventory/test-stage-evidence.json'
                        Write-AmdJsonFile -Path $testStageEvidencePath -Value $testStageEvidence -Depth 20
                        Assert-AmdJsonFileSyntax -Path $testStageEvidencePath
                        if($issues.Count){throw($issues -join '; ')}
                        return [pscustomobject]@{Summary=('PowerShell {0}; core contract functions={1}; 7Zip={2}; NPU research packages={3}; source data contracts={4}; hardware-only selection tests=10; legacy package-lane tests=4; research/certificate scope tests=3; signature and operator-message tests={5}; common infrastructure tests={6}; public schema version tests=1; canonical JSON enum tests=1; canonical JSON cross-runtime tests=1; UTF-8 JSON syntax tests=1; evidence snapshot tests=1' -f $PSVersionTable.PSVersion,[int]$script:PredecessorCoreContractDoc.functionCount,[string]$script:SevenZipInfo.Status,@($script:ArtifactCatalogDoc.artifacts).Count,@(Get-NpuReviewedSourceDataContracts).Count,$signatureSelfTests.Count,$commonInfrastructureSelfTests.Count);PowerShell=$PSVersionTable.PSVersion.ToString();SharedCoreFunctionCount=[int]$script:PredecessorCoreContractDoc.functionCount;SevenZip=$script:SevenZipInfo;ArtifactCatalogCount=@($script:ArtifactCatalogDoc.artifacts).Count;SourceDataContractCount=@(Get-NpuReviewedSourceDataContracts).Count;HardwareOnlySelectionTestCount=10;PackageLaneSelectionTestCount=4;ResearchAndCertificateScopeTestCount=3;SignatureSelfTestCount=$signatureSelfTests.Count;CommonInfrastructureSelfTestCount=$commonInfrastructureSelfTests.Count;PublicSchemaVersionSelfTestCount=1;CanonicalJsonEnumSelfTestCount=1;CanonicalJsonCrossRuntimeSelfTestCount=1;Utf8JsonSyntaxSelfTestCount=1;EvidenceSnapshotSelfTestCount=1;SignedCmsAvailable=[bool]$signaturePrimitiveSelfTest.SignedCmsAvailable;ToolchainCapabilityStatus=[string]$script:NpuToolchainCapabilityEvidence.PublicSummary.Status}
                    }
                }
                'HardwareIdentity' {$null=Invoke-AmdTrackedStage -Name $stage -BlockedReason $blocked -Body {$issues=@(Test-ReviewedResearchData -HardwareDoc $script:HardwareDoc -ProcessorDoc $script:ProcessorDoc -CompatibilityDoc $script:CompatibilityDoc);$issues+=@(Test-ObservedRuntimeEvidence -ObservedRuntimeDoc $script:ObservedRuntimeDoc -ProcessorDoc $script:ProcessorDoc -HardwareDoc $script:HardwareDoc);$issues+=@(Test-DriverBinaryContracts -Contracts $script:DriverContractsDoc.contracts);$issues+=@(Test-NpuHardwareDriverSelectionData -SelectionDoc $script:HardwareSelectionDoc);if($issues.Count){throw($issues -join '; ')};if($ResolveHardwareSelection){if($UseObservedNpuHardwareIdOverride){$overrideDevice=[pscustomobject][ordered]@{InstanceId='EXPLICIT-OFFLINE-OVERRIDE';Name='Explicit offline/test override';Service='';CandidateReason='ExplicitOfflineOverride';HardwareIds=@($ObservedNpuHardwareId);CompatibleIds=@();IdentitySet=@($ObservedNpuHardwareId);PropertyCollectionStatus='NotApplicable'};$script:LocalNpuPnpEvidence=[pscustomobject][ordered]@{SchemaVersion='amd-npu-local-pnp-evidence/1.0';EnumerationStatus='Complete';InputSource='ExplicitOfflineOverride';CandidateDevices=@($overrideDevice);ScannedPnpEntityCount=0;ScannedAmdPciEntityCount=0;Error=$null}}else{$script:LocalNpuPnpEvidence=Get-NpuLocalWindowsPnpEvidence -SelectionDoc $script:HardwareSelectionDoc};$script:HardwareSelectionResult=Resolve-NpuEnumeratedHardwareSelection -SelectionDoc $script:HardwareSelectionDoc -PnpEvidence $script:LocalNpuPnpEvidence -WindowsBuild $effectiveTargetWindowsBuild -WindowsBuildSource ([string]$windowsBuildEvidence.Source) -ManualOverride:$UseObservedNpuHardwareIdOverride;$localPnpEvidencePath=Join-Path $PSScriptRoot 'inventory/local-npu-pnp-evidence.json';$hardwareSelectionResultPath=Join-Path $PSScriptRoot 'inventory/hardware-selection-result.json';Write-AmdJsonFile -Path $localPnpEvidencePath -Value $script:LocalNpuPnpEvidence -Depth 30;Write-AmdJsonFile -Path $hardwareSelectionResultPath -Value $script:HardwareSelectionResult -Depth 30;Assert-AmdJsonFileSyntax -Path $localPnpEvidencePath;Assert-AmdJsonFileSyntax -Path $hardwareSelectionResultPath};return [pscustomobject]@{Summary=('identities={0}; observedRuntime={1}; driver contracts={2}; selectionAuthority=AutomaticWindowsPnp; requestedDecision={3}; candidates={4}; manualOverride={5}; runtimeJsonSyntax={6}' -f @($script:HardwareDoc.identities).Count,@($script:ObservedRuntimeDoc.records).Count,@($script:DriverContractsDoc.contracts).Count,$(if($script:HardwareSelectionResult){[string]$script:HardwareSelectionResult.Decision}else{'NotRequested'}),$(if($script:HardwareSelectionResult){[int]$script:HardwareSelectionResult.CandidateDeviceCount}else{0}),[bool]$UseObservedNpuHardwareIdOverride,$(if($ResolveHardwareSelection){'Pass'}else{'NotRequested'}));IdentityCount=@($script:HardwareDoc.identities).Count;ObservedRuntimeCount=@($script:ObservedRuntimeDoc.records).Count;LocalNpuPnpEvidence=$script:LocalNpuPnpEvidence;HardwareSelectionResult=$script:HardwareSelectionResult;RuntimeJsonSyntax=$(if($ResolveHardwareSelection){'Pass'}else{'NotRequested'})}}}
                'ProcessorCatalog' {$null=Invoke-AmdTrackedStage -Name $stage -BlockedReason $blocked -Body {$fails=0;foreach($p in @($script:ProcessorDoc.processors)){$r=Resolve-ProcessorCatalogIdentity -ProcessorName ([string]$p.canonicalName) -ProcessorDoc $script:ProcessorDoc;if($r.Status -ne 'ExactCatalogMatch' -or $r.ProcessorId -ne [string]$p.processorId){$fails++}};if($fails){throw("Processor catalog self-test failures=$fails")};return [pscustomobject]@{Summary=('processors={0}' -f @($script:ProcessorDoc.processors).Count);ProcessorCount=@($script:ProcessorDoc.processors).Count}}}
                'Discover' {$res=Invoke-AmdTrackedStage -Name $stage -BlockedReason $blocked -Body {Invoke-NpuDiscoveryStage -DocumentationUri $DocumentationUri -AdditionalDriverUrl $AdditionalDriverUrl -DownloadRetryCount $DownloadRetryCount -DownloadTimeoutSeconds $DownloadTimeoutSeconds -AllowNonAmdHost:$AllowNonAmdHost};if($res.Success){$discovery=$res.Output}}
                'Metadata' {$res=Invoke-AmdTrackedStage -Name $stage -BlockedReason $blocked -Body {Invoke-NpuMetadataStage -Discovery $discovery -ArtifactId $ArtifactId -PackagePath $PackagePath};if($res.Success){$metadata=$res.Output;$script:ReleaseMetadataDoc=$metadata}}
                'Acquire' {$res=Invoke-AmdTrackedStage -Name $stage -BlockedReason $blocked -Body {Invoke-NpuAcquireStage -Metadata $metadata -PackagePath $PackagePath -DownloadRetryCount $DownloadRetryCount -DownloadTimeoutSeconds $DownloadTimeoutSeconds -AllowNonAmdHost:$AllowNonAmdHost -Force:$Force};if($res.Success){$script:RunInputs=@($res.Output.Paths)}}
                'Extract' {$null=Invoke-AmdTrackedStage -Name $stage -BlockedReason $blocked -Body {Invoke-NpuExtractStage -SevenZipPath $SevenZipPath -ExtractionMaxDepth $ExtractionMaxDepth}}
                'Inspect' {$null=Invoke-AmdTrackedStage -Name $stage -BlockedReason $blocked -Body {Invoke-NpuInspectStage}}
                'Signature' {$null=Invoke-AmdTrackedStage -Name $stage -BlockedReason $blocked -Body {Invoke-NpuSignatureStage -LocalPackageOverride:($PackagePath.Count -gt 0) -RequireWindowsClientQualification:$RequireWindowsClientSignatureQualification}}
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
        if($null -eq $script:EvidenceContext -and ($null -eq $script:AmdPathSafetyAssessment -or [string]$script:AmdPathSafetyAssessment.Status -ne 'Blocked')){try{$null=Start-AmdEmergencyEvidenceSession -PreferredOutputRoot $EvidenceOutputRoot -Label $EvidenceLabel -EvidenceRetention $EvidenceRetention -InvocationParameters $invocation -BootstrapError $script:TopLevelFatalError}catch{}}
        Write-AmdDiagnosticEvent -EventName 'FatalRunnerError' -Level 'Error' -FunctionName 'Invoke-AmdNpuResearchMain' -Step 'Catch' -Data @{Exception=$fatalRecord.Exception.ToString();ScriptStack=$fatalRecord.ScriptStackTrace}
        $null=Write-AmdFailureSnapshot -Scope 'fatal-runner' -ErrorRecord $fatalRecord -AdditionalData @{ResolvedStages=@($resolvedStages)}
        Write-AmdFail ('Fatal research runner error: {0}' -f $fatalRecord.Exception.Message)
        if($script:EvidenceContext){try{Write-AmdUtf8NoBom -Path (Join-Path (Join-Path $script:EvidenceContext.EvidenceDirectory 'errors') 'fatal-runner-error.txt') -Text ((@(('OccurredUtc: {0}' -f (Get-AmdUtcTimestamp)),('Exception  : {0}' -f $fatalRecord.Exception.ToString()),('ScriptStack: {0}' -f $fatalRecord.ScriptStackTrace))) -join [Environment]::NewLine)}catch{}}
    }
    finally {
        if($null -eq $script:EvidenceContext -and $script:TopLevelFatalError -and ($null -eq $script:AmdPathSafetyAssessment -or [string]$script:AmdPathSafetyAssessment.Status -ne 'Blocked')){try{$null=Start-AmdEmergencyEvidenceSession -PreferredOutputRoot $EvidenceOutputRoot -Label $EvidenceLabel -EvidenceRetention $EvidenceRetention -InvocationParameters $invocation -BootstrapError $script:TopLevelFatalError}catch{}}
        if($script:AmdEvidenceContext -and ($script:AmdTranscriptStarted -or $script:TranscriptStarted)){
            $finalAssessment=Get-AmdRunAssessment -ResolvedStages $resolvedStages
            Write-AmdAssessmentConsoleReport -Assessment $finalAssessment -EvidenceDirectory $script:AmdEvidenceContext.EvidenceDirectory -ZipPath $(if(-not $SkipEvidenceArchive){$script:AmdEvidenceContext.ZipPath}else{$null}) -SkipPublicExport:$SkipPublicExport
            Write-AmdRunTimingSummary -Assessment $finalAssessment
            $script:NpuFinalConsoleReportWritten=$true
        }
        try{$finalAssessment=Finalize-AmdResearchEvidenceSession -ResolvedStages $resolvedStages -SkipArchive:$SkipEvidenceArchive -IncludePackages:$IncludePackagesInEvidence;$finalExitCode=[int]$finalAssessment.ExitCode}
        catch{$finalizationError=$_;$finalExitCode=1;if(-not $script:TopLevelFatalError){$script:TopLevelFatalError=$finalizationError.Exception.ToString()};Write-Warning ('Evidence finalization failed: {0}' -f $finalizationError.Exception.Message);if($script:TranscriptStarted -or $script:AmdTranscriptStarted){try{Stop-Transcript|Out-Null}catch{};$script:TranscriptStarted=$false;$script:AmdTranscriptStarted=$false};[void](Invoke-AmdEmergencyEvidenceFinalization -ErrorRecord $finalizationError -SkipArchive:$SkipEvidenceArchive)}
        if($null -eq $finalAssessment){$finalAssessment=Get-AmdRunAssessment -ResolvedStages $resolvedStages}
        if(-not $script:NpuFinalConsoleReportWritten){
            Write-AmdAssessmentConsoleReport -Assessment $finalAssessment -EvidenceDirectory $(if($script:AmdEvidenceContext){$script:AmdEvidenceContext.EvidenceDirectory}else{$null}) -ZipPath $(if($script:AmdEvidenceContext -and -not $SkipEvidenceArchive){$script:AmdEvidenceContext.ZipPath}else{$null}) -SkipPublicExport:$SkipPublicExport
            Write-AmdRunTimingSummary -Assessment $finalAssessment
        }
    }
    return $finalExitCode
}

$mainParameters=@{
    Stages=$Stages;PackagePath=$PackagePath;ArtifactId=$ArtifactId;Mode=$Mode;OutputRoot=$OutputRoot;EvidenceOutputRoot=$EvidenceOutputRoot;EvidenceLabel=$EvidenceLabel;EvidenceRetention=$EvidenceRetention
    PublicOutputRoot=$PublicOutputRoot;SkipPublicExport=$SkipPublicExport;SkipEvidenceArchive=$SkipEvidenceArchive;IncludePackagesInEvidence=$IncludePackagesInEvidence;RequireWindowsClientSignatureQualification=$RequireWindowsClientSignatureQualification
    ResolveHardwareSelection=$ResolveHardwareSelection;UseObservedNpuHardwareIdOverride=$UseObservedNpuHardwareIdOverride;ObservedNpuHardwareId=$ObservedNpuHardwareId;TargetWindowsBuild=$TargetWindowsBuild;NoClean=$NoClean
    Force=$Force;DownloadRetryCount=$DownloadRetryCount;DownloadTimeoutSeconds=$DownloadTimeoutSeconds;SevenZipPath=$SevenZipPath;ExtractionMaxDepth=$ExtractionMaxDepth
    DocumentationUri=$DocumentationUri;AdditionalDriverUrl=$AdditionalDriverUrl;AllowNonAmdHost=$AllowNonAmdHost
}
$finalCode = Invoke-AmdNpuResearchMain @mainParameters
exit $finalCode
