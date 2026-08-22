#requires -Version 5.1
# AMD Graphics Driver Research Toolkit 3.0.0
# Real-artifact hardened graphics research implementation derived from the accepted chipset research architecture.
# PowerShell 5.1 and PowerShell 7.x; single-script implementation.
[CmdletBinding()]
param(
    [string[]]$Stages = @('All'),

    [string[]]$ReleaseVersion = @(),

    [string[]]$ReleaseKey = @(),

    [string[]]$ProductGroupKey = @(),

    [string[]]$AdditionalProductPageUrl = @(),

    [ValidateRange(1, 10)]
    [int]$MajorGenerationCount = 3,

    [ValidateRange(0, 512)]
    [int]$MaximumSelectedArtifactCount = 32,

    [ValidateRange(0, 1024)]
    [int]$MaximumEstimatedDownloadGiB = 32,

    [ValidateRange(1, 5)]
    [int]$ProductMetadataRetryCount = 3,

    [ValidateRange(0, 5000)]
    [int]$ProductMetadataRequestDelayMilliseconds = 350,

    [ValidateRange(1, 10)]
    [int]$DownloadRetryCount = 4,

    [ValidateRange(30, 3600)]
    [int]$DownloadTimeoutSeconds = 900,

    [switch]$AllowSeedOnlyProductDiscovery,

    [switch]$FullHistoricalResearch,

    [string[]]$LocalInstallerPath = @(),

    [string]$SevenZipPath,

    [int]$MaxDepth = 5,

    [string[]]$SitemapUri = @(
        'https://www.amd.com/en.sitemap.xml',
        'https://www.amd.com/sitemap.xml'
    ),

    [string[]]$AdditionalReleaseNotesUrl = @(),

    [string]$EvidenceOutputRoot,

    [string]$EvidenceLabel,

    [ValidateSet('ZipOnly', 'ZipAndDirectory')]
    [string]$EvidenceRetention = 'ZipOnly',

    [string]$PublicOutputRoot,

    [switch]$SkipPublicExport,

    [switch]$SkipEvidenceArchive,

    [switch]$IncludeInstallersInEvidence,

    [switch]$EmitDetailedDeviceMatrix,

    [switch]$RequireWindowsClientSignatureQualification,

    [switch]$AllowNonAmdHost,

    [switch]$Force
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2.0

$script:AmdGraphicsResearchToolkitVersion = '3.0.0'
$script:AmdResearchToolkitVersion = $script:AmdGraphicsResearchToolkitVersion
$script:AmdInfSemanticContractVersion = 'amd-inf-semantic-contract/1.0'
$script:AmdInfIdentifierTaxonomyVersion = 'amd-inf-identifier-taxonomy/1.0'
$script:AmdInfTopologySchemaVersion = 'amd-inf-topology/1.1'
$script:AmdSupportedDriverPackageIndexSchemas = @('amd-graphics-driver-packages-index/3.0','amd-graphics-driver-packages-index/3.1')
$script:AmdGraphicsResearchToolkitRoot = $PSScriptRoot

$script:AmdGraphicsResearchEvidenceSchemaVersion = 'amd-graphics-driver-research-evidence/1.1'
$script:AmdResearchEvidenceSchemaVersion = $script:AmdGraphicsResearchEvidenceSchemaVersion
$script:AmdResearchEvidencePrefix = 'AmdGraphicsDriverResearchEvidence'
$script:AmdResearchDisplayName = 'AMD Graphics Driver Research Toolkit'
$script:SourceScriptPath = $PSCommandPath
$script:AmdAssessmentSchemaVersion = 'amd-graphics-driver-research-assessment/1.3'
$script:AmdStageResults = New-Object 'System.Collections.Generic.List[object]'
$script:AmdEvidenceContext = $null
$script:AmdPublicationResult = $null
$script:AmdPublicOutputRoot = if ([string]::IsNullOrWhiteSpace($PublicOutputRoot)) { Join-Path $PSScriptRoot 'public' } else { $PublicOutputRoot }
$script:AmdTranscriptStarted = $false
$script:AmdTopLevelFatalError = $null
$script:AmdRunStartTime = Get-Date
$script:AmdCurrentStageStart = $null
$script:AmdCurrentStageName = $null
$script:AmdStageOrdinal = 0
$script:AmdResolvedStageCount = 0
$script:AmdLastProductPageRequestUtc = $null
$script:AmdHttpMaximumConcurrency = 1
$script:AmdDownloadRetryCount = $DownloadRetryCount
$script:AmdDownloadTimeoutSeconds = $DownloadTimeoutSeconds
$script:AmdDiagnosticHistoryLimit = 100
$script:AmdDiagnosticBodyPreviewLimit = 2048
$script:AmdDiagnosticTraceContext = $null
$script:AmdDiagnosticCurrentFunction = $null
$script:AmdDiagnosticCurrentStep = $null
$script:AmdDriverSignatureAnalysisSchemaVersion = 'amd-driver-signature-analysis/1.0'
$script:AmdDriverSignatureNativeSchemaVersion = 'amd-driver-signature-native-verification/1.0'
$script:AmdWindowsSafeFullPathLimit = 240
$script:AmdWindowsSafeToolRootLimit = 100
$script:AmdVendorRelativePathReserve = 120
$script:AmdPathSafetyAssessment = $null
$script:AmdRequireWindowsClientSignatureQualification = [bool]$RequireWindowsClientSignatureQualification
$script:AmdResearchPathSafetySchemaVersion = 'amd-graphics-path-safety-assessment/1.0'
$script:AmdResearchRecommendedRootName = 'AMD-Gfx'

function Get-AmdResearchToolkitRoot {
    [CmdletBinding()]
    param()

    return $script:AmdGraphicsResearchToolkitRoot
}

function Get-AmdPrivateEvidenceRoot {
    [CmdletBinding()]
    param()

    return (Join-Path (Join-Path (Get-AmdResearchToolkitRoot) 'private') 'evidence')
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

function Write-AmdPublicMarkdownText {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]$Text
    )

    # Repository publication contract: generated public Markdown is UTF-8 without BOM
    # and uses LF line endings on every host. No content transformation other than
    # BOM removal/newline normalization is permitted here.
    $normalized = $Text.Replace("`r`n", "`n").Replace("`r", "`n")
    Write-AmdUtf8NoBom -Path $Path -Text $normalized
}

function Copy-AmdPublicMarkdownFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Source,

        [Parameter(Mandatory = $true)]
        [string]$Destination
    )

    $text = Read-AmdTextFile -Path $Source
    Write-AmdPublicMarkdownText -Path $Destination -Text $text
}

function Read-AmdTextFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    return [System.IO.File]::ReadAllText((Resolve-Path -LiteralPath $Path).Path)
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

    Save-CanonicalJsonFile -InputObject $Value -Path $Path -Depth $Depth
}

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

function Initialize-AmdJsonWhitespaceScanner {
    [CmdletBinding()]
    param()

    if ('AmdGraphicsJsonWhitespaceScanner' -as [type]) { return }
    $source = @'
using System;
using System.IO;

public static class AmdGraphicsJsonWhitespaceScanner
{
    private static bool IsJsonWhitespace(byte value)
    {
        return value == 0x20 || value == 0x09 || value == 0x0A || value == 0x0D;
    }

    public static bool HasWhitespaceOutsideStrings(string path)
    {
        const int BufferSize = 65536;
        byte[] buffer = new byte[BufferSize];
        bool inString = false;
        bool escaped = false;
        bool pendingWhitespaceOutsideString = false;

        using (FileStream input = new FileStream(path, FileMode.Open, FileAccess.Read, FileShare.Read))
        {
            int read;
            while ((read = input.Read(buffer, 0, buffer.Length)) > 0)
            {
                for (int i = 0; i < read; i++)
                {
                    byte current = buffer[i];
                    if (!inString && IsJsonWhitespace(current)) { pendingWhitespaceOutsideString = true; continue; }
                    if (pendingWhitespaceOutsideString) { return true; }
                    if (inString)
                    {
                        if (escaped) { escaped = false; }
                        else if (current == 0x5C) { escaped = true; }
                        else if (current == 0x22) { inString = false; }
                    }
                    else if (current == 0x22) { inString = true; }
                }
            }
        }
        if (inString) { throw new InvalidDataException("JSON input ended inside a string literal."); }
        return false;
    }
}
'@
    Add-Type -TypeDefinition $source -Language CSharp -ErrorAction Stop
}

function Test-AmdCompactJsonWhitespaceFile {
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)][string]$Path)

    Initialize-AmdJsonWhitespaceScanner
    $resolved = (Resolve-Path -LiteralPath $Path -ErrorAction Stop).Path
    return (-not [AmdGraphicsJsonWhitespaceScanner]::HasWhitespaceOutsideStrings($resolved))
}

function Test-AmdCanonicalJsonPublicationLogic {
    [CmdletBinding()]
    param()

    $failures = New-Object System.Collections.Generic.List[string]
    $collectionWrapperContract = $false
    $decodedScalarPrivacyContract = $false
    $safeBlocked = $false
    $portableCanonicalPrivacyContract = $false
    $publicStructurePreservationContract = $false
    $legacyBaselineRepairContract = $false
    $tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ('amd-graphics-canonical-json-selftest-{0}' -f [guid]::NewGuid().ToString('N'))
    try {
        New-AmdDirectory -Path $tempRoot | Out-Null
        $path = Join-Path $tempRoot 'fixture.json'
        $fixture = [pscustomobject][ordered]@{
            alpha = 'spaces stay; escaped quote: "; slash: \\; unicode-like text: \u0041'
            beta = @([pscustomobject][ordered]@{ Profile=[pscustomobject][ordered]@{ Id='windows-server-2025' } })
        }
        Write-AmdJsonFile -Path $path -Value $fixture
        if (-not (Test-CanonicalJsonFile -Path $path)) { $failures.Add('canonical JSON writer did not satisfy the cross-runtime byte contract') }
        $roundTrip = Read-AmdJsonFile -Path $path
        if ([string]$roundTrip.alpha -cne [string]$fixture.alpha) { $failures.Add('canonical JSON round-trip changed string content') }

        $wrappedCollection = [pscustomobject][ordered]@{ value=@([pscustomobject]@{ Profile=[pscustomobject]@{ Id='windows-server-2025' } }); Count=1 }
        $unwrappedCollection = @(Get-AmdCollectionItems -Value $wrappedCollection)
        $collectionWrapperContract = ($unwrappedCollection.Count -eq 1 -and $unwrappedCollection[0].Profile.Id -eq 'windows-server-2025')
        if (-not $collectionWrapperContract) { $failures.Add('PowerShell 5.1 collection wrapper was not rehydrated') }

        # Validate privacy tokens after JSON decoding rather than against escaped raw JSON text.
        # Vendor selector/XML tokens that merely begin with '/' are not host paths and must survive.
        $forbiddenPatterns = @(Get-AmdPublicForbiddenPatterns)
        $safeObject = [pscustomobject][ordered]@{ Selector='/SETFILTERUSB'; ManifestPath='/info.xml'; Value='C:\' }
        $safeBlocked = $false
        foreach ($scalar in @(Get-AmdPublicScalarStrings -Value $safeObject)) {
            foreach ($pattern in $forbiddenPatterns) { if ($scalar -match $pattern) { $safeBlocked = $true; break } }
            if ($safeBlocked) { break }
        }
        $privateObject = [pscustomobject][ordered]@{
            RuntimePath = Join-Path (Get-AmdResearchToolkitRoot) 'work'
            WindowsRuntimePath = 'C:\Users\SensitiveUser\AppData\Local\Temp\amd-private'
        }
        $privateBlocked = $false
        foreach ($scalar in @(Get-AmdPublicScalarStrings -Value $privateObject)) {
            foreach ($pattern in $forbiddenPatterns) { if ($scalar -match $pattern) { $privateBlocked = $true; break } }
            if ($privateBlocked) { break }
        }
        $decodedScalarPrivacyContract = (-not $safeBlocked -and $privateBlocked)
        if (-not $decodedScalarPrivacyContract) { $failures.Add('decoded-scalar privacy validation contract failed') }

        $portableProbe = ConvertTo-AmdPortableEvidenceObject -Value ([pscustomobject][ordered]@{
            VendorSelector = '/SETFILTERUSB'
            MultilineLog = ("7-Zip banner`r`nExtracting archive: {0}`r`nEverything is Ok" -f (Join-Path (Get-AmdResearchToolkitRoot) 'work\extracted\fixture.exe'))
            PathSafety = [pscustomobject][ordered]@{ ArchivePath=(Join-Path (Get-AmdResearchToolkitRoot) 'work\x\a0001\c0001\fixture.exe'); Status='Pass' }
            NeutralText = 'vendor evidence without host path'
        })
        $portableCanonicalPrivacyContract = (
            [string]$portableProbe.VendorSelector -ceq '/SETFILTERUSB' -and
            $null -eq $portableProbe.MultilineLog -and
            $null -eq $portableProbe.PathSafety.PSObject.Properties['ArchivePath'] -and
            [string]$portableProbe.PathSafety.Status -ceq 'Pass' -and
            [string]$portableProbe.NeutralText -ceq 'vendor evidence without host path'
        )
        if (-not $portableCanonicalPrivacyContract) { $failures.Add('portable canonical privacy sanitization contract failed') }

        $publicProbe = ConvertTo-AmdPublicRepositoryObject -Value ([pscustomobject][ordered]@{
            OptionalNull = $null
            SafeArray = @($null, 'safe')
            PathSafety = [pscustomobject][ordered]@{
                ArchivePath = Join-Path (Get-AmdResearchToolkitRoot) 'work\x\a0001\c0001\fixture.exe'
                Status = 'Pass'
            }
        })
        $publicStructurePreservationContract = (
            $null -ne $publicProbe.PSObject.Properties['OptionalNull'] -and
            $null -eq $publicProbe.OptionalNull -and
            @($publicProbe.SafeArray).Count -eq 2 -and
            $null -eq @($publicProbe.SafeArray)[0] -and
            [string]@($publicProbe.SafeArray)[1] -ceq 'safe' -and
            $null -eq $publicProbe.PathSafety.PSObject.Properties['ArchivePath'] -and
            [string]$publicProbe.PathSafety.Status -ceq 'Pass'
        )
        if (-not $publicStructurePreservationContract) { $failures.Add('public repository sanitizer changed safe null structure') }

        $legacyRoot = Join-Path $tempRoot 'legacy-baseline'
        New-AmdDirectory -Path $legacyRoot | Out-Null
        $legacyPath = Join-Path $legacyRoot 'release.json'
        Write-AmdJsonFile -Path $legacyPath -Value ([pscustomobject][ordered]@{ SchemaVersion='fixture/1.0'; Values=@('alpha','beta') })
        $canonicalBytes = [System.IO.File]::ReadAllBytes($legacyPath)
        $canonicalText = (New-Object System.Text.UTF8Encoding($false,$true)).GetString($canonicalBytes)
        $legacyPayload = [System.Text.Encoding]::UTF8.GetBytes($canonicalText.Replace("`n","`r`n"))
        $legacyBytes = New-Object byte[] ($legacyPayload.Length + 3)
        $legacyBytes[0]=0xEF; $legacyBytes[1]=0xBB; $legacyBytes[2]=0xBF
        [Array]::Copy($legacyPayload,0,$legacyBytes,3,$legacyPayload.Length)
        [System.IO.File]::WriteAllBytes($legacyPath,$legacyBytes)
        $legacyRepair = Repair-AmdLegacyPublicJsonByteContract -Root $legacyRoot
        $legacyBaselineRepairContract = (
            [string]$legacyRepair.Status -eq 'Pass' -and
            [int]$legacyRepair.FileCount -eq 1 -and
            [int]$legacyRepair.RepairedFileCount -eq 1 -and
            (Test-CanonicalJsonFile -Path $legacyPath)
        )
        if (-not $legacyBaselineRepairContract) { $failures.Add('legacy public release baseline JSON repair contract failed') }
    }
    catch { $failures.Add($_.Exception.Message) }
    finally { if (Test-Path -LiteralPath $tempRoot -PathType Container) { Remove-Item -LiteralPath $tempRoot -Recurse -Force -ErrorAction SilentlyContinue } }
    return [pscustomobject][ordered]@{
        Status=if($failures.Count -eq 0){'Pass'}else{'Fail'}
        CanonicalJsonByteContract=($failures -notcontains 'canonical JSON writer did not satisfy the cross-runtime byte contract')
        PowerShell51CollectionWrapperRehydration=$collectionWrapperContract
        JsonDecodedScalarPrivacyValidation=$decodedScalarPrivacyContract
        PortableCanonicalPrivacySanitization=$portableCanonicalPrivacyContract
        PublicNullStructurePreserved=$publicStructurePreservationContract
        LegacyPublicBaselineJsonRepair=$legacyBaselineRepairContract
        VendorSelectorTokenPreserved=(-not $safeBlocked)
        Failures=@($failures.ToArray())
    }
}

function Test-AmdPublicMarkdownPublicationLogic {
    [CmdletBinding()]
    param()

    $failures = New-Object System.Collections.Generic.List[string]
    $tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ('amd-graphics-markdown-publication-selftest-{0}' -f [guid]::NewGuid().ToString('N'))
    try {
        New-AmdDirectory -Path $tempRoot | Out-Null
        $source = Join-Path $tempRoot 'source.md'
        $destination = Join-Path $tempRoot 'destination.md'
        $sourceText = "alpha`r`nbeta`rgamma`n"
        $sourcePayload = [System.Text.Encoding]::UTF8.GetBytes($sourceText)
        $sourceBytes = New-Object byte[] ($sourcePayload.Length + 3)
        $sourceBytes[0] = 0xEF; $sourceBytes[1] = 0xBB; $sourceBytes[2] = 0xBF
        [Array]::Copy($sourcePayload, 0, $sourceBytes, 3, $sourcePayload.Length)
        [System.IO.File]::WriteAllBytes($source, $sourceBytes)

        Copy-AmdPublicMarkdownFile -Source $source -Destination $destination
        $publishedBytes = [System.IO.File]::ReadAllBytes($destination)
        $publishedText = [System.Text.Encoding]::UTF8.GetString($publishedBytes)
        $hasBom = ($publishedBytes.Length -ge 3 -and $publishedBytes[0] -eq 0xEF -and $publishedBytes[1] -eq 0xBB -and $publishedBytes[2] -eq 0xBF)
        if ($hasBom) { $failures.Add('public Markdown writer retained a UTF-8 BOM') }
        if ($publishedText.Contains("`r")) { $failures.Add('public Markdown writer retained CR/CRLF line endings') }
        if ($publishedText -cne "alpha`nbeta`ngamma`n") { $failures.Add('public Markdown writer changed content beyond newline/BOM normalization') }

        $generated = Join-Path $tempRoot 'generated.md'
        Write-AmdPublicMarkdownText -Path $generated -Text "one`r`ntwo`rthree`n"
        $generatedBytes = [System.IO.File]::ReadAllBytes($generated)
        $generatedText = [System.Text.Encoding]::UTF8.GetString($generatedBytes)
        $generatedHasBom = ($generatedBytes.Length -ge 3 -and $generatedBytes[0] -eq 0xEF -and $generatedBytes[1] -eq 0xBB -and $generatedBytes[2] -eq 0xBF)
        if ($generatedHasBom -or $generatedText.Contains("`r") -or $generatedText -cne "one`ntwo`nthree`n") {
            $failures.Add('toolkit-generated public Markdown does not satisfy LF/no-BOM contract')
        }
    }
    catch { $failures.Add($_.Exception.Message) }
    finally { if (Test-Path -LiteralPath $tempRoot -PathType Container) { Remove-Item -LiteralPath $tempRoot -Recurse -Force -ErrorAction SilentlyContinue } }

    return [pscustomobject][ordered]@{
        Status = if ($failures.Count -eq 0) { 'Pass' } else { 'Fail' }
        Utf8NoBom = ($failures -notcontains 'public Markdown writer retained a UTF-8 BOM')
        LfOnly = ($failures -notcontains 'public Markdown writer retained CR/CRLF line endings')
        ContentPreserved = ($failures -notcontains 'public Markdown writer changed content beyond newline/BOM normalization')
        Failures = @($failures.ToArray())
    }
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

function Invoke-AmdTimedOperation {
    [CmdletBinding()]
    param([Parameter(Mandatory=$true)][string]$Name,[Parameter(Mandatory=$true)][scriptblock]$Operation)
    $started=Get-Date;Write-Host ('[CHECK] START {0}' -f $Name) -ForegroundColor Cyan
    try{$result=& $Operation;Write-Host ('[CHECK] DONE  {0} ({1})' -f $Name,(Format-AmdElapsed ((Get-Date)-$started))) -ForegroundColor Green;return $result}
    catch{Write-Host ('[CHECK] FAIL  {0} ({1}): {2}' -f $Name,(Format-AmdElapsed ((Get-Date)-$started)),$_.Exception.Message) -ForegroundColor Red;throw}
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
    Write-Host (' toolkit: v{0}' -f $script:AmdGraphicsResearchToolkitVersion) -ForegroundColor DarkGray
    Write-Host $line -ForegroundColor Magenta
}

function Write-AmdStageFooter {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][string]$Name,
        [Parameter(Mandatory=$true)][ValidateSet('PASS','FAIL','BLOCKED','SKIPPED','INTERRUPTED')][string]$Status,
        [Parameter(Mandatory=$true)][TimeSpan]$Elapsed
    )

    $color = switch ($Status) {
        'PASS'    { 'Green' }
        'FAIL'    { 'Red' }
        'BLOCKED' { 'Yellow' }
        'SKIPPED' { 'DarkGray' }
        'INTERRUPTED' { 'Yellow' }
        default   { 'Gray' }
    }
    Write-Host (' STAGE {0,-20} -> {1,-8} elapsed: {2}' -f $Name, $Status, (Format-AmdElapsed $Elapsed)) -ForegroundColor $color
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
            $color = switch ([string]$t.Status) {
                'PASS'    { 'Green' }
                'FAIL'    { 'Red' }
                'BLOCKED' { 'Yellow' }
                'SKIPPED' { 'DarkGray' }
                'INTERRUPTED' { 'Yellow' }
                default   { 'Gray' }
            }
            Write-Host ('   {0,-18} {1,-8} {2,12}' -f $t.Name, $t.Status, (Format-AmdElapsed $span)) -ForegroundColor $color
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
        [ValidateSet('ZipOnly', 'ZipAndDirectory')]
        [string]$EvidenceRetention = 'ZipOnly',
        [Parameter(Mandatory = $true)]
        [object]$InvocationParameters
    )

    $toolRoot = Get-AmdResearchToolkitRoot
    $OutputRoot = Resolve-AmdEvidenceOutputRoot -RequestedPath $OutputRoot
    New-AmdDirectory -Path $OutputRoot | Out-Null
    $runsRoot = Join-Path $OutputRoot 'runs'
    New-AmdDirectory -Path $runsRoot | Out-Null

    $platform = Get-AmdPlatformInfo
    $stamp = (Get-Date).ToUniversalTime().ToString('yyyyMMddTHHmmssZ')
    $platformFragment = ConvertTo-AmdEvidenceSafeFragment -Value ([string]$platform.PlatformFamily)
    $labelFragment = Get-AmdEvidenceSafeLabel -Value $Label

    $baseName = if ($labelFragment) {
        'AmdGraphicsDriverResearchEvidence_{0}_{1}_{2}' -f $stamp, $platformFragment, $labelFragment
    }
    else {
        'AmdGraphicsDriverResearchEvidence_{0}_{1}' -f $stamp, $platformFragment
    }

    $workId = 'r{0}-{1}' -f $stamp, ([Guid]::NewGuid().ToString('N').Substring(0, 8))
    $evidenceDir = Join-Path $runsRoot $workId
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
        $scriptPath = Join-Path $toolRoot 'Invoke-AmdGraphicsDriverResearch.ps1'
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

    $hostExecutionContext = Get-AmdWindowsExecutionContext -PlatformInfo $platform
    $context = [pscustomobject][ordered]@{
        SchemaVersion = $script:AmdGraphicsResearchEvidenceSchemaVersion
        ToolkitVersion = $script:AmdGraphicsResearchToolkitVersion
        RunId = $baseName
        StartedAtUtc = Get-AmdUtcTimestamp
        ToolDisplayName = 'AMD Graphics Driver Research Toolkit'
        EvidenceRoot = $OutputRoot
        EvidenceDirectory = $evidenceDir
        ZipPath = $zipPath
        ZipSha256Path = $zipPath + '.sha256'
        LatestEvidencePointerPath = Join-Path $OutputRoot 'LATEST-EVIDENCE.txt'
        EvidenceRetention = $EvidenceRetention
        EvidenceDirectoryRetained = $true
        ArchiveCreated = $false
        ZipSha256 = $null
        Platform = $platform
        ExecutionContext = $hostExecutionContext
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
    Start-AmdDiagnosticTrace -EvidenceDirectory $evidenceDir
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
        SchemaVersion = 'amd-graphics-driver-research-stage-results/1.1'
        ToolkitVersion = $script:AmdGraphicsResearchToolkitVersion
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

        [scriptblock]$Body,

        [string]$BlockedReason,

        [string]$SkippedReason
    )

    $script:AmdStageOrdinal++
    Write-AmdStageHeader -Name $Name -Ordinal $script:AmdStageOrdinal -Total $script:AmdResolvedStageCount
    Set-AmdDiagnosticStep -FunctionName 'Invoke-AmdTrackedStage' -Step ('StageStart:'+ $Name) -Data @{Name=$Name;Ordinal=$script:AmdStageOrdinal;Total=$script:AmdResolvedStageCount}

    $started = [DateTime]::UtcNow
    $script:AmdCurrentStageName = $Name
    Write-AmdDiagnosticEvent -EventName 'StageStarted' -Level 'Info' -FunctionName 'Invoke-AmdTrackedStage' -Step $Name -Data @{Ordinal=$script:AmdStageOrdinal;Total=$script:AmdResolvedStageCount;BlockedReason=$BlockedReason;SkippedReason=$SkippedReason}
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $status = if ($BlockedReason) { 'BLOCKED' } elseif ($SkippedReason) { 'SKIPPED' } elseif ($null -eq $Body) { 'FAIL' } else { 'RUNNING' }
    $errorText = $null
    $errorFile = $null
    $output = $null
    $reason = $null
    $entry = $null

    try {
        if ($status -eq 'BLOCKED') {
            $reason = $BlockedReason
            Write-AmdCaution ('Stage {0} blocked: {1}' -f $Name, $BlockedReason)
        }
        elseif ($status -eq 'SKIPPED') {
            $reason = $SkippedReason
            Write-AmdSkip ('Stage {0} skipped: {1}' -f $Name, $SkippedReason)
        }
        elseif ($status -eq 'FAIL') {
            $errorText = 'Tracked stage body was not supplied.'
            Write-AmdFail ('Stage {0} failed: {1}' -f $Name, $errorText)
        }
        else {
            $output = & $Body
            $status = 'PASS'
            Write-AmdDiagnosticEvent -EventName 'StageBodyCompleted' -Level 'Info' -FunctionName 'Invoke-AmdTrackedStage' -Step $Name -Data @{Status='PASS'}
        }
    }
    catch {
        $status = 'FAIL'
        $errorText = $_.Exception.Message
        Write-AmdDiagnosticEvent -EventName 'StageFailure' -Level 'Error' -FunctionName 'Invoke-AmdTrackedStage' -Step $Name -Data @{Error=$errorText;ErrorRecord=(Get-AmdExceptionDiagnostic -ErrorRecord $_)}
        $null=Write-AmdFailureSnapshot -Scope ('stage-'+$Name) -ErrorRecord $_ -AdditionalData @{Stage=$Name}

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
        if ($status -eq 'RUNNING') {
            $status = 'INTERRUPTED'
            $reason = 'Stage execution was interrupted before normal completion.'
            if ([string]::IsNullOrWhiteSpace($errorText)) { $errorText = $reason }
        }
        $sw.Stop()
        $entry = [pscustomobject][ordered]@{
            Name = $Name
            Status = $status
            StartedAtUtc = $started.ToString('o')
            CompletedAtUtc = Get-AmdUtcTimestamp
            DurationMilliseconds = [int64]$sw.ElapsedMilliseconds
            Reason = $reason
            Error = $errorText
            ErrorEvidencePath = $errorFile
        }
        $script:AmdStageResults.Add($entry)
        Write-AmdDiagnosticEvent -EventName 'StageCompleted' -Level $(if($status -eq 'PASS'){'Info'}elseif($status -in @('BLOCKED','SKIPPED','INTERRUPTED')){'Warning'}else{'Error'}) -FunctionName 'Invoke-AmdTrackedStage' -Step ('StageEnd:'+ $Name) -Data $entry
        Write-AmdStageResultsEvidence
        Write-AmdStageFooter -Name $Name -Status $status -Elapsed $sw.Elapsed
        $script:AmdCurrentStageName = $null
    }

    return [pscustomobject][ordered]@{
        Success = ($status -eq 'PASS')
        Status = $status
        Output = $output
        Reason = $reason
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


function Test-AmdSupportedDriverPackageIndexSchema {
    [CmdletBinding()]
    param([AllowEmptyString()][string]$SchemaVersion)

    return ($script:AmdSupportedDriverPackageIndexSchemas -contains [string]$SchemaVersion)
}

function Get-AmdOptionalIntProperty {
    [CmdletBinding()]
    param(
        [AllowNull()][object]$InputObject,
        [Parameter(Mandatory=$true)][string]$Name,
        [int]$DefaultValue = 0
    )

    if ($null -eq $InputObject) { return $DefaultValue }
    if ($InputObject.PSObject.Properties[$Name]) {
        try { return [int]$InputObject.$Name } catch { return $DefaultValue }
    }
    return $DefaultValue
}

function Get-AmdProductSelectionAssessment {
    [CmdletBinding()]
    param([Parameter(Mandatory=$true)][object]$Selection)

    $stableTracks = Get-AmdOptionalIntProperty -InputObject $Selection -Name 'SelectionTrackCount'
    $trackGenerations = Get-AmdOptionalIntProperty -InputObject $Selection -Name 'TrackGenerationSelectionCount'
    $artifactSelections = Get-AmdOptionalIntProperty -InputObject $Selection -Name 'ArtifactSelectionCount'
    $uniqueArtifacts = Get-AmdOptionalIntProperty -InputObject $Selection -Name 'UniqueSelectedArtifactCount'
    $evidenceConflicts = Get-AmdOptionalIntProperty -InputObject $Selection -Name 'TrackEvidenceConflictCount'
    $roleTransitions = Get-AmdOptionalIntProperty -InputObject $Selection -Name 'ArtifactRoleTransitionTrackCount'
    $unknownSizes = Get-AmdOptionalIntProperty -InputObject $Selection -Name 'UnknownSizeArtifactCount'
    $estimatedBytes = [int64]0
    if ($Selection.PSObject.Properties['EstimatedDownloadBytes']) {
        try { $estimatedBytes = [int64]$Selection.EstimatedDownloadBytes } catch { $estimatedBytes = 0 }
    }

    $problems = New-Object System.Collections.Generic.List[string]
    if ($stableTracks -lt 1) { $problems.Add('no stable selection tracks were produced') }
    if ($trackGenerations -lt 1) { $problems.Add('no track-generation selections were produced') }
    if ($artifactSelections -lt $trackGenerations) { $problems.Add('artifact selection count is lower than track-generation selection count') }
    if ($uniqueArtifacts -lt 1) { $problems.Add('no unique installer artifacts were selected') }
    if ($artifactSelections -lt $uniqueArtifacts) { $problems.Add('unique artifact count exceeds artifact selection count') }

    if ($Selection.PSObject.Properties['SelectedArtifacts']) {
        $selectedArtifactRows = @($Selection.SelectedArtifacts).Count
        if ($selectedArtifactRows -ne $uniqueArtifacts) {
            $problems.Add(('SelectedArtifacts row count ({0}) differs from UniqueSelectedArtifactCount ({1})' -f $selectedArtifactRows,$uniqueArtifacts))
        }
    }

    $status = if ($problems.Count -eq 0) { 'PASS' } else { 'REVIEW' }
    $detail = ('stable-tracks={0}; track-generations={1}; artifact-selections={2}; unique-artifacts={3}; estimated={4}; evidence-conflicts={5}; role-transition-tracks={6}; unknown-size-artifacts={7}' -f `
        $stableTracks, $trackGenerations, $artifactSelections, $uniqueArtifacts, (Format-AmdByteSize $estimatedBytes), $evidenceConflicts, $roleTransitions, $unknownSizes)
    if ($problems.Count -gt 0) {
        $detail += ('; validation={0}' -f ($problems.ToArray() -join ' | '))
    }

    return [pscustomobject][ordered]@{
        Status = $status
        Detail = $detail
        SelectionTrackCount = $stableTracks
        TrackGenerationSelectionCount = $trackGenerations
        ArtifactSelectionCount = $artifactSelections
        UniqueSelectedArtifactCount = $uniqueArtifacts
        EvidenceConflictCount = $evidenceConflicts
        ArtifactRoleTransitionTrackCount = $roleTransitions
        UnknownSizeArtifactCount = $unknownSizes
        Problems = @($problems.ToArray())
    }
}

function Get-AmdInfInspectionAssessment {
    [CmdletBinding()]
    param([Parameter(Mandatory=$true)][object]$DriverData)

    $count = 0
    $parseFailures = 0
    $artifactCount = 0
    $problems = New-Object System.Collections.Generic.List[string]
    $schema = [string]$DriverData.SchemaVersion

    if (Test-AmdSupportedDriverPackageIndexSchema -SchemaVersion $schema) {
        $count = Get-AmdOptionalIntProperty -InputObject $DriverData -Name 'DriverPackageCount'
        $artifactCount = Get-AmdOptionalIntProperty -InputObject $DriverData -Name 'ArtifactCount'
        foreach ($artifact in @(Get-AmdCollectionItems -Value $DriverData.Artifacts)) {
            $parseFailures += Get-AmdOptionalIntProperty -InputObject $artifact -Name 'ParseFailureCount'
        }
        if ($DriverData.PSObject.Properties['Artifacts']) {
            $actualArtifactRows = @(Get-AmdCollectionItems -Value $DriverData.Artifacts).Count
            if ($artifactCount -ne $actualArtifactRows) {
                $problems.Add(('ArtifactCount ({0}) differs from Artifacts row count ({1})' -f $artifactCount,$actualArtifactRows))
            }
        }
    }
    elseif ($DriverData.PSObject.Properties['DriverPackages']) {
        $count = @($DriverData.DriverPackages).Count
        $parseFailures = @($DriverData.DriverPackages | Where-Object { $_.InspectionStatus -eq 'ParseFailed' }).Count
        $artifactCount = 0
    }
    else {
        $problems.Add(('unsupported driver-packages assessment schema [{0}]' -f $schema))
        return [pscustomobject][ordered]@{
            Status = 'REVIEW'
            Detail = ('schema={0}; artifacts=0; INF-packages=0; parse-failures=0; validation={1}' -f $schema, ($problems.ToArray() -join ' | '))
            SchemaVersion = $schema
            ArtifactCount = 0
            DriverPackageCount = 0
            ParseFailureCount = 0
            Problems = @($problems.ToArray())
        }
    }

    if ($count -lt 1) { $problems.Add('no INF package records were produced') }
    if ($parseFailures -lt 0 -or $parseFailures -gt $count) {
        $problems.Add(('invalid parse-failure count {0} for {1} driver records' -f $parseFailures,$count))
    }

    $status = if ($count -gt 0 -and $parseFailures -eq 0 -and $problems.Count -eq 0) { 'PASS' } else { 'REVIEW' }
    $detail = ('schema={0}; artifacts={1}; INF-packages={2}; parse-failures={3}' -f $schema,$artifactCount,$count,$parseFailures)
    if ($problems.Count -gt 0) {
        $detail += ('; validation={0}' -f ($problems.ToArray() -join ' | '))
    }

    return [pscustomobject][ordered]@{
        Status = $status
        Detail = $detail
        SchemaVersion = $schema
        ArtifactCount = $artifactCount
        DriverPackageCount = $count
        ParseFailureCount = $parseFailures
        Problems = @($problems.ToArray())
    }
}


function Get-AmdArtifactPipelineConsistencyAssessment {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][object]$Selection,
        [Parameter(Mandatory=$true)][object]$Acquisition,
        [Parameter(Mandatory=$true)][object]$Extraction,
        [Parameter(Mandatory=$true)][object]$DriverData
    )

    $problems = New-Object System.Collections.Generic.List[string]

    $selectedKeys = @(
        @($Selection.SelectedArtifacts) |
            ForEach-Object { ('{0}|{1}' -f [string]$_.ReleaseKey,[string]$_.FileName) } |
            Where-Object { $_ -and $_ -notmatch '^\|$' } |
            Sort-Object -Unique
    )
    $acquisitionKeys = @(
        @(Get-AmdCollectionItems -Value $Acquisition.Artifacts) |
            Where-Object { [string]$_.Status -in @('Downloaded','Provided','Reused') } |
            ForEach-Object { [string]$_.ArtifactKey } |
            Where-Object { $_ } |
            Sort-Object -Unique
    )
    $extractionKeys = @(
        @(Get-AmdCollectionItems -Value $Extraction.Releases) |
            Where-Object { [string]$_.Status -eq 'ExtractionComplete' } |
            ForEach-Object { [string]$_.ArtifactKey } |
            Where-Object { $_ } |
            Sort-Object -Unique
    )
    $inspectionKeys = @(
        @(Get-AmdCollectionItems -Value $DriverData.Artifacts) |
            Where-Object { [string]$_.InspectionStatus -eq 'Inspected' } |
            ForEach-Object { [string]$_.ArtifactKey } |
            Where-Object { $_ } |
            Sort-Object -Unique
    )

    foreach ($pair in @(
        [pscustomobject]@{Name='selection/acquisition'; Left=$selectedKeys; Right=$acquisitionKeys},
        [pscustomobject]@{Name='acquisition/extraction'; Left=$acquisitionKeys; Right=$extractionKeys},
        [pscustomobject]@{Name='extraction/inspection'; Left=$extractionKeys; Right=$inspectionKeys}
    )) {
        $diff = @(Compare-Object -ReferenceObject @($pair.Left) -DifferenceObject @($pair.Right))
        if ($diff.Count -gt 0) {
            $sample = @($diff | Select-Object -First 4 | ForEach-Object { '{0}:{1}' -f $_.SideIndicator,$_.InputObject })
            $sampleSuffix = ''
            if ($sample.Count -gt 0) {
                $sampleSuffix = '; sample=' + ($sample -join ', ')
            }
            $problems.Add(('{0} ArtifactKey set mismatch ({1} difference(s)){2}' -f $pair.Name,$diff.Count,$sampleSuffix))
        }
    }

    $acquisitionByKey = @{}
    foreach ($artifact in @(Get-AmdCollectionItems -Value $Acquisition.Artifacts)) {
        $key = [string]$artifact.ArtifactKey
        if ($key) { $acquisitionByKey[$key] = $artifact }
    }
    $hashMismatchCount = 0
    foreach ($release in @(Get-AmdCollectionItems -Value $Extraction.Releases)) {
        $key = [string]$release.ArtifactKey
        if (-not $key -or -not $acquisitionByKey.ContainsKey($key)) { continue }
        $a = $acquisitionByKey[$key]
        $acqHash = [string]$a.Sha256
        $extHash = [string]$release.InstallerSha256
        if ($acqHash -and $extHash -and $acqHash.ToLowerInvariant() -ne $extHash.ToLowerInvariant()) {
            $hashMismatchCount++
        }
    }
    if ($hashMismatchCount -gt 0) {
        $problems.Add(('{0} acquisition/extraction installer SHA-256 mismatch(es)' -f $hashMismatchCount))
    }

    $estimatedBytes = [int64]0
    if ($Selection.PSObject.Properties['EstimatedDownloadBytes']) {
        try { $estimatedBytes = [int64]$Selection.EstimatedDownloadBytes } catch { $estimatedBytes = 0 }
    }
    $actualBytes = [int64]0
    foreach ($artifact in @(Get-AmdCollectionItems -Value $Acquisition.Artifacts)) {
        try { $actualBytes += [int64]$artifact.SizeBytes } catch { }
    }
    $variancePct = $null
    if ($estimatedBytes -gt 0) {
        $variancePct = [Math]::Round((($actualBytes - $estimatedBytes) / [double]$estimatedBytes) * 100.0, 2)
    }

    $status = if ($problems.Count -eq 0) { 'PASS' } else { 'REVIEW' }
    $detail = ('selected={0}; acquired={1}; extracted={2}; inspected={3}; hash-mismatches={4}; estimated={5}; actual={6}' -f `
        $selectedKeys.Count,$acquisitionKeys.Count,$extractionKeys.Count,$inspectionKeys.Count,$hashMismatchCount,(Format-AmdByteSize $estimatedBytes),(Format-AmdByteSize $actualBytes))
    if ($null -ne $variancePct) {
        $detail += ('; size-variance={0}%' -f $variancePct)
    }
    if ($problems.Count -gt 0) {
        $detail += ('; validation={0}' -f ($problems.ToArray() -join ' | '))
    }

    return [pscustomobject][ordered]@{
        Status = $status
        Detail = $detail
        SelectedArtifactCount = $selectedKeys.Count
        AcquiredArtifactCount = $acquisitionKeys.Count
        ExtractedArtifactCount = $extractionKeys.Count
        InspectedArtifactCount = $inspectionKeys.Count
        HashMismatchCount = $hashMismatchCount
        EstimatedDownloadBytes = $estimatedBytes
        ActualDownloadBytes = $actualBytes
        SizeVariancePercent = $variancePct
        Problems = @($problems.ToArray())
    }
}


function Test-AmdRunAssessmentLogic {
    [CmdletBinding()]
    param()

    $failures = New-Object System.Collections.Generic.List[string]

    try {
        $selection = [pscustomobject]@{
            SelectionTrackCount = 38
            TrackGenerationSelectionCount = 95
            ArtifactSelectionCount = 95
            UniqueSelectedArtifactCount = 23
            EstimatedDownloadBytes = [int64]20981376616
            TrackEvidenceConflictCount = 3
            ArtifactRoleTransitionTrackCount = 21
            UnknownSizeArtifactCount = 0
            SelectedArtifacts = @(1..23 | ForEach-Object { [pscustomobject]@{ FileName=('artifact-{0}.exe' -f $_) } })
        }
        $selectionAssessment = Get-AmdProductSelectionAssessment -Selection $selection
        if ($selectionAssessment.Status -ne 'PASS') { $failures.Add('ProductSelection assessment did not PASS for a valid selection plan.') }
        if ($selectionAssessment.EvidenceConflictCount -ne 3) { $failures.Add('ProductSelection assessment did not preserve evidence-conflict count.') }
        if ($selectionAssessment.ArtifactRoleTransitionTrackCount -ne 21) { $failures.Add('ProductSelection assessment did not preserve ArtifactRole transition count.') }
    }
    catch {
        $failures.Add(('ProductSelection assessment threw unexpectedly: {0}' -f $_.Exception.Message))
    }

    try {
        $index31 = [pscustomobject]@{
            SchemaVersion = 'amd-graphics-driver-packages-index/3.1'
            ArtifactCount = 2
            DriverPackageCount = 7
            Artifacts = @(
                [pscustomobject]@{ ParseFailureCount = 0 },
                [pscustomobject]@{ ParseFailureCount = 0 }
            )
        }
        $inspectionAssessment = Get-AmdInfInspectionAssessment -DriverData $index31
        if ($inspectionAssessment.Status -ne 'PASS' -or $inspectionAssessment.DriverPackageCount -ne 7) {
            $failures.Add('Current 3.1 driver-package index assessment did not PASS.')
        }
    }
    catch {
        $failures.Add(('Current 3.1 driver-package index assessment threw unexpectedly: {0}' -f $_.Exception.Message))
    }

    try {
        $index30 = [pscustomobject]@{
            SchemaVersion = 'amd-graphics-driver-packages-index/3.0'
            ArtifactCount = 1
            DriverPackageCount = 2
            Artifacts = @([pscustomobject]@{ ParseFailureCount = 0 })
        }
        $inspectionAssessment30 = Get-AmdInfInspectionAssessment -DriverData $index30
        if ($inspectionAssessment30.Status -ne 'PASS') { $failures.Add('Historical 3.0 driver-package index assessment did not PASS.') }
    }
    catch {
        $failures.Add(('Historical 3.0 driver-package index assessment threw unexpectedly: {0}' -f $_.Exception.Message))
    }

    try {
        $unsupported = [pscustomobject]@{ SchemaVersion='amd-graphics-driver-packages-index/99.0' }
        $unsupportedAssessment = Get-AmdInfInspectionAssessment -DriverData $unsupported
        if ($unsupportedAssessment.Status -ne 'REVIEW' -or @($unsupportedAssessment.Problems).Count -lt 1) {
            $failures.Add('Unsupported driver-package index schema was not classified as REVIEW.')
        }
    }
    catch {
        $failures.Add(('Unsupported-schema assessment threw unexpectedly: {0}' -f $_.Exception.Message))
    }

    try {
        $selection = [pscustomobject]@{
            EstimatedDownloadBytes = [int64]200
            SelectedArtifacts = @([pscustomobject]@{ ReleaseKey='Adrenalin|Main|26.1.1'; FileName='a.exe' })
        }
        $acquisition = [pscustomobject]@{
            Artifacts = @([pscustomobject]@{ ArtifactKey='Adrenalin|Main|26.1.1|a.exe'; Status='Downloaded'; Sha256=('a' * 64); SizeBytes=[int64]190 })
        }
        $extraction = [pscustomobject]@{
            Releases = @([pscustomobject]@{ ArtifactKey='Adrenalin|Main|26.1.1|a.exe'; Status='ExtractionComplete'; InstallerSha256=('a' * 64) })
        }
        $driverData = [pscustomobject]@{
            Artifacts = @([pscustomobject]@{ ArtifactKey='Adrenalin|Main|26.1.1|a.exe'; InspectionStatus='Inspected' })
        }
        $chainAssessment = Get-AmdArtifactPipelineConsistencyAssessment -Selection $selection -Acquisition $acquisition -Extraction $extraction -DriverData $driverData
        if ($chainAssessment.Status -ne 'PASS' -or $chainAssessment.HashMismatchCount -ne 0) {
            $failures.Add('Artifact pipeline consistency assessment did not PASS for a valid chain.')
        }
    }
    catch {
        $failures.Add(('Artifact pipeline consistency self-test threw unexpectedly: {0}' -f $_.Exception.Message))
    }

    return [pscustomobject][ordered]@{
        Status = if ($failures.Count -eq 0) { 'Pass' } else { 'Fail' }
        TestCount = 5
        Failures = @($failures.ToArray())
    }
}



function Test-AmdProductMetadataFetchPolicyLogic {
    [CmdletBinding()]
    param()

    $failures=New-Object System.Collections.Generic.List[string]

    try {
        foreach($code in @(403,429,503)){
            if(-not (Test-AmdTransientProductPageStatusCode -StatusCode $code)){
                $failures.Add(('HTTP {0} was not classified as transient/retryable.' -f $code))
            }
        }
        if(Test-AmdTransientProductPageStatusCode -StatusCode 404){
            $failures.Add('HTTP 404 was incorrectly classified as retryable.')
        }
    }
    catch{$failures.Add(('Transient-status policy threw unexpectedly: {0}' -f $_.Exception.Message))}

    try {
        $primary=Get-AmdProductSupportClassification -Url 'https://www.amd.com/en/support/downloads/drivers.html/processors/ryzen-pro/ryzen-pro-5000-series/amd-ryzen-7-pro-5755ge.html'
        $alternate=Get-AmdProductSupportClassification -Url 'https://www.amd.com/en/support/downloads/drivers.html/processors/ryzen-pro/ryzen-pro-5000-series/amd-ryzen-7-pro-5750ge.html'
        if($null -eq $primary -or $null -eq $alternate -or [string]$primary.ProductGroupKey -ne [string]$alternate.ProductGroupKey){
            $failures.Add('Ryzen PRO 5000 representative fallback does not preserve ProductGroupKey.')
        }
    }
    catch{$failures.Add(('Ryzen PRO 5000 fallback classification threw unexpectedly: {0}' -f $_.Exception.Message))}

    try {
        $primary=Get-AmdProductSupportClassification -Url 'https://www.amd.com/en/support/downloads/drivers.html/processors/ryzen-pro/ryzen-pro-8000-series/amd-ryzen-7-pro-8700g.html'
        $alternate=Get-AmdProductSupportClassification -Url 'https://www.amd.com/en/support/downloads/drivers.html/processors/ryzen-pro/ryzen-pro-8000-series/amd-ryzen-7-pro-8700ge.html'
        if($null -eq $primary -or $null -eq $alternate -or [string]$primary.ProductGroupKey -ne [string]$alternate.ProductGroupKey){
            $failures.Add('Ryzen PRO 8000 representative fallback does not preserve ProductGroupKey.')
        }
    }
    catch{$failures.Add(('Ryzen PRO 8000 fallback classification threw unexpectedly: {0}' -f $_.Exception.Message))}

    try {
        $catalog=[pscustomobject]@{CatalogKind='CuratedProductGroups'}
        $product=[pscustomobject]@{RootCategory='processors'}
        if(-not (Test-AmdShouldFetchPreviousProductPage -Catalog $catalog -Product $product -Summary $null -CurrentEntryCount 0)){
            $failures.Add('Curated processor product did not request Previous Drivers when latest metadata was unavailable.')
        }
    }
    catch{$failures.Add(('Curated previous-page policy threw unexpectedly: {0}' -f $_.Exception.Message))}

    return [pscustomobject][ordered]@{
        Status=if($failures.Count -eq 0){'Pass'}else{'Fail'}
        TestCount=4
        Failures=@($failures.ToArray())
    }
}

function Get-AmdRuntimeBaselinePublicFileNames {
    [CmdletBinding()]
    param()
    return @(
        'all-releases-summary.json',
        'signature-analysis.json',
        'toolchain-capabilities.json',
        'inf-topology.json',
        'windows-server-applicability.json',
        'windows-server-compatibility-analysis.json',
        'windows-server-compatibility-analysis.csv',
        'server-compatibility-matrix.csv',
        'device-server-compatibility-matrix.csv'
    )
}

function Initialize-AmdRuntimeBaselineFromPublicSurface {
    [CmdletBinding()]
    param()

    $started=Get-Date

    $root = Get-AmdResearchToolkitRoot
    $publicInventory = Join-Path $script:AmdPublicOutputRoot 'inventory'
    if (-not (Test-Path -LiteralPath $publicInventory -PathType Container)) {
        Write-Host '[BOOTSTRAP] Runtime baseline restore skipped: public inventory is not present.' -ForegroundColor DarkGray
        return
    }
    Write-Host '[BOOTSTRAP] Graphics runtime baseline copy started.' -ForegroundColor Cyan

    $runtimeInventory = Join-Path $root 'inventory'
    New-AmdDirectory -Path $runtimeInventory | Out-Null

    $publicReleases = Join-Path $publicInventory 'releases'
    $runtimeReleases = Join-Path $runtimeInventory 'releases'
    $runtimeReleaseCount = if (Test-Path -LiteralPath $runtimeReleases -PathType Container) { @(Get-ChildItem -LiteralPath $runtimeReleases -File -Recurse -Filter '*.json' -ErrorAction SilentlyContinue).Count } else { 0 }
    if ($runtimeReleaseCount -eq 0 -and (Test-Path -LiteralPath $publicReleases -PathType Container)) {
        Copy-AmdEvidenceTree -Source $publicReleases -Destination $runtimeReleases
    }
    $baselineJsonContract = Repair-AmdLegacyPublicJsonByteContract -Root $runtimeReleases
    if ([int]$baselineJsonContract.FileCount -gt 0) {
        Write-Host ('[BOOTSTRAP] Graphics release baseline JSON contract verified: files={0}; legacy newline/BOM repairs={1}.' -f [int]$baselineJsonContract.FileCount,[int]$baselineJsonContract.RepairedFileCount) -ForegroundColor DarkGray
    }

    foreach ($name in @(Get-AmdRuntimeBaselinePublicFileNames)) {
        $src = Join-Path $publicInventory $name
        $dst = Join-Path $runtimeInventory $name
        if ((Test-Path -LiteralPath $src -PathType Leaf) -and -not (Test-Path -LiteralPath $dst -PathType Leaf)) {
            Copy-Item -LiteralPath $src -Destination $dst -Force
        }
    }
    Write-Host ('[BOOTSTRAP] Graphics runtime baseline copy completed in {0}.' -f (Format-AmdElapsed ((Get-Date)-$started))) -ForegroundColor Cyan
}

function Repair-AmdLegacyPublicJsonByteContract {
    [CmdletBinding()]
    param([Parameter(Mandatory=$true)][string]$Root)

    if (-not (Test-Path -LiteralPath $Root -PathType Container)) {
        return [pscustomobject][ordered]@{Status='Pass';FileCount=0;RepairedFileCount=0;Repairs=@()}
    }

    $utf8 = New-Object System.Text.UTF8Encoding($false,$true)
    $repairs = New-Object 'System.Collections.Generic.List[string]'
    $files = @(Get-ChildItem -LiteralPath $Root -Filter '*.json' -File -Recurse -Force -ErrorAction Stop)
    foreach ($file in $files) {
        $changed = $false
        $bytes = [System.IO.File]::ReadAllBytes($file.FullName)
        $offset = 0
        if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) { $offset = 3 }
        $text = $utf8.GetString($bytes,$offset,$bytes.Length-$offset)
        $normalized = $text.Replace("`r`n","`n").Replace("`r","`n")
        if ($offset -ne 0 -or $normalized -cne $text) {
            [System.IO.File]::WriteAllBytes($file.FullName,$utf8.GetBytes($normalized))
            $changed = $true
        }
        if (-not (Test-CanonicalJsonFile -Path $file.FullName)) {
            $value = Read-AmdJsonFile -Path $file.FullName
            Write-AmdJsonFile -Path $file.FullName -Value $value
            $changed = $true
        }
        if (-not (Test-CanonicalJsonFile -Path $file.FullName)) {
            throw ('Runtime release baseline JSON violates the canonical byte contract after legacy canonical repair: {0}' -f $file.FullName)
        }
        if ($changed) {
            $repairs.Add((Get-AmdRelativePath -BasePath $Root -Path $file.FullName)) | Out-Null
        }
    }

    return [pscustomobject][ordered]@{
        Status='Pass'
        Root=$Root
        FileCount=$files.Count
        RepairedFileCount=$repairs.Count
        Repairs=@($repairs.ToArray())
    }
}

function ConvertTo-AmdPublicRepositoryObject {
    [CmdletBinding()]
    param([AllowNull()][object]$Value)

    if ($null -eq $Value) { return $null }
    if ($Value -is [string]) {
        $text = [string]$Value
        $privateRoots = New-Object 'System.Collections.Generic.List[string]'
        foreach ($candidate in @((Get-AmdResearchToolkitRoot), $HOME, $env:USERPROFILE, $env:TEMP, $env:TMP)) {
            if (-not [string]::IsNullOrWhiteSpace([string]$candidate)) { $privateRoots.Add(([string]$candidate).TrimEnd('\','/')) }
        }
        foreach ($privateRoot in @($privateRoots.ToArray())) {
            if ($text.StartsWith($privateRoot, [System.StringComparison]::OrdinalIgnoreCase)) { return $null }
        }
        if ($text -match '^/(?:home|Users|mnt/data|tmp|var/tmp)/' -or $text -match '(?i)^[A-Z]:\\Users\\') { return $null }
        return $text
    }
    if ($Value -is [ValueType]) { return $Value }

    $privateNames = @(
        'LocalPath','ExtractionRoot','InfPath','ResolvedPath','InstallerPath','ContainerPath','OutputDirectory','EvidenceLogPath',
        'EvidenceDirectory','EvidenceZip','EvidenceOutputRoot','EvidenceLabel','TranscriptPath','ScriptPath','SeedPath','HtmlEvidencePath',
        'LatestEvidencePath','PreviousEvidencePath','EnvironmentEvidencePath','SevenZipPath','ToolRoot','WorkingDirectory','DiscoveryDiagnostics',
        'OSDescription','PowerShellVersion','PSEdition','UserName','ComputerName','HostName','HomeDirectory','InvocationParameters','Error','Errors','FetchError','LatestFetchError','PreviousFetchError','StackTrace','Exception'
    )

    if ($Value -is [System.Collections.IDictionary]) {
        $out=[ordered]@{}
        foreach($key in $Value.Keys){
            $name=[string]$key
            if($privateNames -contains $name -or (Test-AmdPublicPathPropertyName -PropertyName $name)){continue}
            if($name -match '(?i)(?:^|)(?:StackTrace|Exception|Transcript)$'){continue}
            $candidate=$Value[$key]
            if($null -eq $candidate){$out[$name]=$null;continue}
            $v=ConvertTo-AmdPublicRepositoryObject -Value $candidate
            if($null -ne $v){$out[$name]=$v}
        }
        return [pscustomobject]$out
    }
    if ($Value -is [System.Collections.IEnumerable]) {
        $arr=New-Object System.Collections.Generic.List[object]
        foreach($item in $Value){if($null -eq $item){$arr.Add($null);continue};$v=ConvertTo-AmdPublicRepositoryObject -Value $item;if($null -ne $v){$arr.Add($v)}}
        return ,$arr.ToArray()
    }
    if ($Value.PSObject -and $Value.PSObject.Properties) {
        $out=[ordered]@{}
        foreach($prop in $Value.PSObject.Properties){
            $name=[string]$prop.Name
            if($privateNames -contains $name -or (Test-AmdPublicPathPropertyName -PropertyName $name)){continue}
            if($name -match '(?i)(?:^|)(?:StackTrace|Exception|Transcript)$'){continue}
            $candidate=$prop.Value
            if($null -eq $candidate){$out[$name]=$null;continue}
            $v=ConvertTo-AmdPublicRepositoryObject -Value $candidate
            if($null -ne $v){$out[$name]=$v}
        }
        return [pscustomobject]$out
    }
    return $Value
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

function Test-AmdPublicDatasetConsistency {
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)][string]$Root)

    $errors = New-Object System.Collections.Generic.List[string]
    try {
        $runSummaryPath = Join-Path $Root 'run-summary.json'
        $selectionPath = Join-Path (Join-Path $Root 'inventory') 'selection-plan.json'
        $summaryPath = Join-Path (Join-Path $Root 'inventory') 'all-releases-summary.json'
        $topologyPath = Join-Path (Join-Path $Root 'inventory') 'inf-topology.json'
        $serverPath = Join-Path (Join-Path $Root 'inventory') 'windows-server-compatibility-analysis.json'

        foreach ($requiredPath in @($runSummaryPath,$summaryPath,$topologyPath,$serverPath)) {
            if (-not (Test-Path -LiteralPath $requiredPath -PathType Leaf)) {
                $errors.Add(('required public consistency input is missing: {0}' -f (Split-Path -Leaf $requiredPath)))
            }
        }
        if ($errors.Count -eq 0) {
            $runSummary = Read-AmdJsonFile -Path $runSummaryPath
            $selectionRequired = ($null -ne $runSummary.ProductSelection -or @(Get-AmdCollectionItems -Value $runSummary.SelectedStages) -contains 'Select')
            $selection = $null
            if ($selectionRequired) {
                if (-not (Test-Path -LiteralPath $selectionPath -PathType Leaf)) {
                    $errors.Add('required public consistency input is missing: selection-plan.json')
                }
                else {
                    $selection = Read-AmdJsonFile -Path $selectionPath
                }
            }
            elseif (Test-Path -LiteralPath $selectionPath -PathType Leaf) {
                $selection = Read-AmdJsonFile -Path $selectionPath
            }
            $summary = Read-AmdJsonFile -Path $summaryPath
            $topology = Read-AmdJsonFile -Path $topologyPath
            $server = Read-AmdJsonFile -Path $serverPath

            $artifactCount = [int]$summary.ArtifactCount
            $driverCount = [int]$summary.DriverCount
            if ([int]$topology.ArtifactCount -ne $artifactCount) { $errors.Add('inf-topology ArtifactCount does not match all-releases-summary') }
            if ([int]$topology.DriverCount -ne $driverCount) { $errors.Add('inf-topology DriverCount does not match all-releases-summary') }
            if ($runSummary.PublishedDataset) {
                if ([int]$runSummary.PublishedDataset.ArtifactCount -ne $artifactCount) { $errors.Add('run-summary PublishedDataset.ArtifactCount does not match all-releases-summary') }
                if ([int]$runSummary.PublishedDataset.DriverCount -ne $driverCount) { $errors.Add('run-summary PublishedDataset.DriverCount does not match all-releases-summary') }
            }
            $serverProfiles = @(Get-AmdCollectionItems -Value $server.ServerProfiles).Count
            if ($serverProfiles -le 0) { $errors.Add('windows-server compatibility analysis has no ServerProfiles') }
            else {
                $expectedRows = $driverCount * $serverProfiles
                if ([int]$server.RowCount -ne $expectedRows) { $errors.Add(('windows-server RowCount mismatch: expected {0}, observed {1}' -f $expectedRows,[int]$server.RowCount)) }
                if (@(Get-AmdCollectionItems -Value $server.Rows).Count -ne [int]$server.RowCount) { $errors.Add('windows-server Rows array count does not match RowCount') }
            }
            if ($runSummary.ProductSelection -and $selection) {
                foreach ($field in @('SelectionTrackCount','TrackGenerationSelectionCount','ArtifactSelectionCount','UniqueSelectedArtifactCount')) {
                    if ($runSummary.ProductSelection.PSObject.Properties[$field] -and $selection.PSObject.Properties[$field]) {
                        if ([int64]$runSummary.ProductSelection.$field -ne [int64]$selection.$field) { $errors.Add(('run-summary ProductSelection.{0} does not match selection-plan' -f $field)) }
                    }
                }
            }
            if ($runSummary.BuildIntegrity) {
                if ([int]$runSummary.BuildIntegrity.CumulativeArtifactCount -ne $artifactCount) { $errors.Add('run-summary BuildIntegrity.CumulativeArtifactCount does not match all-releases-summary') }
                if ([int]$runSummary.BuildIntegrity.CumulativeDriverCount -ne $driverCount) { $errors.Add('run-summary BuildIntegrity.CumulativeDriverCount does not match all-releases-summary') }
                if ([int]$runSummary.BuildIntegrity.ServerRowCount -ne [int]$server.RowCount) { $errors.Add('run-summary BuildIntegrity.ServerRowCount does not match windows-server analysis') }
            }
        }
    }
    catch {
        $errors.Add(('public dataset consistency validation failed: {0}' -f $_.Exception.Message))
    }

    return [pscustomobject][ordered]@{
        Status = if ($errors.Count -eq 0) { 'Pass' } else { 'Fail' }
        ErrorCount = $errors.Count
        Errors = @($errors.ToArray())
    }
}

function Test-AmdPublicationManifestIntegrity {
    [CmdletBinding()]
    param([Parameter(Mandatory=$true)][string]$Root,[Parameter(Mandatory=$true)][object[]]$Entries)

    $errors=New-Object System.Collections.Generic.List[string]
    $seen=New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::OrdinalIgnoreCase)
    $manifestPaths=New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::OrdinalIgnoreCase)
    foreach($entry in @($Entries)){
        $path=[string]$entry.RelativePath
        if([string]::IsNullOrWhiteSpace($path) -or $path.StartsWith('/') -or $path -match '^[A-Za-z]:' -or $path.Contains('\\')){$errors.Add(('publication manifest path is not POSIX-relative: {0}' -f $path));continue}
        $segments=@($path -split '/')
        if(@($segments|Where-Object{$_ -eq '' -or $_ -eq '.' -or $_ -eq '..'}).Count -gt 0){$errors.Add(('publication manifest path contains unsafe segments: {0}' -f $path));continue}
        if(-not $seen.Add($path)){$errors.Add(('duplicate publication manifest path: {0}' -f $path));continue}
        $null=$manifestPaths.Add($path)
        $candidate=$Root;foreach($segment in $segments){$candidate=Join-Path $candidate $segment}
        if(-not (Test-Path -LiteralPath $candidate -PathType Leaf)){$errors.Add(('publication manifest file is missing: {0}' -f $path));continue}
        $file=Get-Item -LiteralPath $candidate -ErrorAction Stop;$actualSha=Get-AmdSha256 -Path $candidate
        if([int64]$entry.SizeBytes -ne [int64]$file.Length){$errors.Add(('publication manifest size mismatch: {0}' -f $path))}
        if([string]$entry.Sha256 -ne $actualSha){$errors.Add(('publication manifest SHA-256 mismatch: {0}' -f $path))}
        if([bool]$entry.HandEdited){$errors.Add(('publication manifest HandEdited must be false: {0}' -f $path))}
        if($entry.PSObject.Properties['SourceSha256'] -and -not [string]::IsNullOrWhiteSpace([string]$entry.SourceSha256) -and [string]$entry.SourceSha256 -notmatch '^[0-9a-f]{64}$'){$errors.Add(('publication manifest SourceSha256 is invalid: {0}' -f $path))}
    }
    $observed=New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::OrdinalIgnoreCase)
    foreach($file in @(Get-ChildItem -LiteralPath $Root -File -Recurse -Force -ErrorAction Stop)){
        if($file.Name -eq 'publication-manifest.json'){continue}
        $rel=ConvertTo-AmdRepositoryRelativePath -RelativePath (Get-AmdRelativePath -BasePath $Root -Path $file.FullName);$null=$observed.Add($rel)
    }
    foreach($path in @($observed)){if(-not $manifestPaths.Contains($path)){$errors.Add(('public file is not represented in publication manifest: {0}' -f $path))}}
    foreach($path in @($manifestPaths)){if(-not $observed.Contains($path)){$errors.Add(('publication manifest references a non-public file: {0}' -f $path))}}
    return [pscustomobject][ordered]@{Status=if($errors.Count -eq 0){'Pass'}else{'Fail'};PathFormat='POSIXRelative';ManifestEntryCount=@($Entries).Count;ObservedFileCount=$observed.Count;ErrorCount=$errors.Count;Errors=@($errors.ToArray())}
}

function Test-AmdPublicationManifestLogic {
    [CmdletBinding()]
    param()

    $failures=New-Object System.Collections.Generic.List[string]
    $tempRoot=Join-Path ([System.IO.Path]::GetTempPath()) ('amd-graphics-publication-selftest-{0}' -f [guid]::NewGuid().ToString('N'))
    try{
        New-AmdDirectory -Path (Join-Path $tempRoot 'inventory')|Out-Null
        $a=Join-Path (Join-Path $tempRoot 'inventory') 'a.json';$b=Join-Path $tempRoot 'README.md'
        Write-AmdUtf8NoBom -Path $a -Text '{"ok":true}';Write-AmdUtf8NoBom -Path $b -Text 'ok'
        $aItem=Get-Item $a;$aSha=Get-AmdSha256 -Path $a;$bItem=Get-Item $b;$bSha=Get-AmdSha256 -Path $b
        $entries=@(
            [pscustomobject][ordered]@{RelativePath='inventory/a.json';SizeBytes=[int64]$aItem.Length;Sha256=$aSha;Classification='PublicRepositoryArtifact';GenerationMode='ByteCopyFromRuntimeCanonical';SourceRelativePath='inventory/a.json';SourceSha256=$aSha;HandEdited=$false},
            [pscustomobject][ordered]@{RelativePath='README.md';SizeBytes=[int64]$bItem.Length;Sha256=$bSha;Classification='PublicRepositoryArtifact';GenerationMode='ToolkitGeneratedOrPreservedBaseline';SourceRelativePath=$null;SourceSha256=$null;HandEdited=$false}
        )
        $good=Test-AmdPublicationManifestIntegrity -Root $tempRoot -Entries $entries
        if([string]$good.Status -ne 'Pass'){$failures.Add('POSIX publication manifest was not accepted')}
        $badEntries=@($entries|ForEach-Object{$_});$badEntries[0]=[pscustomobject][ordered]@{RelativePath='inventory\\a.json';SizeBytes=[int64]$aItem.Length;Sha256=$aSha;Classification='PublicRepositoryArtifact';GenerationMode='ByteCopyFromRuntimeCanonical';HandEdited=$false}
        $bad=Test-AmdPublicationManifestIntegrity -Root $tempRoot -Entries $badEntries
        if([string]$bad.Status -ne 'Fail'){$failures.Add('Windows-style publication manifest path was not rejected')}
    }catch{$failures.Add($_.Exception.Message)}finally{if(Test-Path -LiteralPath $tempRoot -PathType Container){Remove-Item -LiteralPath $tempRoot -Recurse -Force -ErrorAction SilentlyContinue}}
    return [pscustomobject][ordered]@{Status=if($failures.Count -eq 0){'Pass'}else{'Fail'};Failures=@($failures.ToArray())}
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

function Test-AmdPublicRepositorySurface {
    [CmdletBinding()]
    param([Parameter(Mandatory=$true)][string]$Root)

    $errors=New-Object System.Collections.Generic.List[string]
    $privacyErrors=New-Object System.Collections.Generic.List[string]
    $jsonWhitespaceErrors=New-Object System.Collections.Generic.List[string]
    $markdownFormatErrors=New-Object System.Collections.Generic.List[string]
    $jsonFileCount=0
    $markdownFileCount=0
    $forbiddenPatterns=@(Get-AmdPublicForbiddenPatterns)

    if(-not (Test-Path -LiteralPath $Root -PathType Container)){$errors.Add(('public root is missing: {0}' -f $Root))}
    foreach($file in @(Get-ChildItem -LiteralPath $Root -File -Recurse -Force -ErrorAction SilentlyContinue)){
        if($file.Extension -notin @('.json','.csv','.md','.txt')){continue}
        $relative=ConvertTo-AmdRepositoryRelativePath -RelativePath (Get-AmdRelativePath -BasePath $Root -Path $file.FullName)
        try{$text=Read-AmdTextFile -Path $file.FullName}catch{$errors.Add(('unable to read public file {0}' -f $relative));continue}

        if($file.Extension -eq '.json'){
            $jsonFileCount++
            try{
                $json=Read-AmdJsonFile -Path $file.FullName
                foreach($scalar in @(Get-AmdPublicScalarStrings -Value $json)){
                    foreach($pattern in $forbiddenPatterns){
                        if($scalar -match $pattern){$message=('privacy-sensitive decoded JSON scalar found in {0}' -f $relative);$privacyErrors.Add($message);$errors.Add($message);break}
                    }
                }
            }catch{$errors.Add(('invalid JSON in public file {0}' -f $relative))}
            try{
                if(-not (Test-CanonicalJsonFile -Path $file.FullName)){
                    $message=('canonical/public JSON violates the cross-runtime byte contract: {0}' -f $relative)
                    $jsonWhitespaceErrors.Add($message);$errors.Add($message)
                }
            }catch{
                $message=('unable to verify canonical JSON policy for {0}: {1}' -f $relative,$_.Exception.Message)
                $jsonWhitespaceErrors.Add($message);$errors.Add($message)
            }
        }
        else{
            foreach($pattern in $forbiddenPatterns){
                if($text -match $pattern){$message=('privacy-sensitive pattern found in {0}' -f $relative);$privacyErrors.Add($message);$errors.Add($message);break}
            }
            if($file.Extension -eq '.md'){
                $markdownFileCount++
                $bytes=[System.IO.File]::ReadAllBytes($file.FullName)
                if($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF){
                    $message=('UTF-8 BOM found in public Markdown: {0}' -f $relative);$markdownFormatErrors.Add($message);$errors.Add($message)
                }
                if($text.Contains("`r")){
                    $message=('CR/CRLF line ending found in public Markdown: {0}' -f $relative);$markdownFormatErrors.Add($message);$errors.Add($message)
                }
            }
        }
    }
    $datasetConsistency=Test-AmdPublicDatasetConsistency -Root $Root
    foreach($datasetError in @($datasetConsistency.Errors)){ $errors.Add([string]$datasetError) }
    return [pscustomobject][ordered]@{
        SchemaVersion='amd-graphics-publication-validation/1.3';ToolkitVersion=$script:AmdGraphicsResearchToolkitVersion;GeneratedAtUtc=Get-AmdUtcTimestamp
        Status=if($errors.Count -eq 0){'Pass'}else{'Fail'};ErrorCount=$errors.Count;Errors=$errors.ToArray()
        PrivacyStatus=if($privacyErrors.Count -eq 0){'Pass'}else{'Fail'};PrivacyErrorCount=$privacyErrors.Count
        DatasetConsistencyStatus=[string]$datasetConsistency.Status;DatasetConsistencyErrorCount=[int]$datasetConsistency.ErrorCount
        JsonWhitespaceStatus=if($jsonWhitespaceErrors.Count -eq 0){'Pass'}else{'Fail'};JsonWhitespaceErrorCount=$jsonWhitespaceErrors.Count;JsonFileCount=$jsonFileCount
        MarkdownFormatStatus=if($markdownFormatErrors.Count -eq 0){'Pass'}else{'Fail'};MarkdownFormatErrorCount=$markdownFormatErrors.Count;MarkdownFileCount=$markdownFileCount
        JsonDecodedScalarValidation=$true
        Policy='public/** is the only generated repository-publication surface; JSON privacy checks inspect decoded scalar values; canonical public JSON must already be compact before publication; public Markdown must be UTF-8 no-BOM with LF line endings.'
    }
}

function Publish-AmdRepositorySurface {
    [CmdletBinding()]
    param([Parameter(Mandatory=$true)][object]$CoreAssessment,[Parameter(Mandatory=$true)][string[]]$ResolvedStages)

    $root=Get-AmdResearchToolkitRoot
    if([string]$CoreAssessment.OverallStatus -ne 'Pass'){
        return [pscustomobject][ordered]@{Status='Skipped';PublicRoot=$script:AmdPublicOutputRoot;FileCount=if(Test-Path -LiteralPath $script:AmdPublicOutputRoot -PathType Container){@(Get-ChildItem -LiteralPath $script:AmdPublicOutputRoot -File -Recurse -Force).Count}else{0};Validation=[pscustomobject][ordered]@{Status='NotRun';ErrorCount=0;Errors=@()};Published=$false;Reason=('Current run assessment is {0}; last validated public repository surface was preserved without modification.' -f [string]$CoreAssessment.OverallStatus)}
    }

    $publicRoot=$script:AmdPublicOutputRoot;$staging=('{0}.staging-{1}' -f $publicRoot,$PID)
    if(Test-Path -LiteralPath $staging -PathType Container){Remove-Item -LiteralPath $staging -Recurse -Force}
    New-AmdDirectory -Path $staging|Out-Null
    if(Test-Path -LiteralPath $publicRoot -PathType Container){Copy-AmdEvidenceTree -Source $publicRoot -Destination $staging}
    foreach($name in @('publication-manifest.json','publication-validation.json')){$p=Join-Path $staging $name;if(Test-Path -LiteralPath $p -PathType Leaf){Remove-Item -LiteralPath $p -Force}}

    $pubInv=Join-Path $staging 'inventory';$pubReports=Join-Path $staging 'reports';New-AmdDirectory -Path $pubInv|Out-Null;New-AmdDirectory -Path $pubReports|Out-Null
    $runtimeInventory=Join-Path $root 'inventory';$runtimeReports=Join-Path $root 'reports'

    foreach($name in @('products.json','product-driver-mapping.json')){
        $src=Join-Path $runtimeInventory $name
        if(Test-Path -LiteralPath $src -PathType Leaf){$obj=Read-AmdJsonFile -Path $src;Write-AmdJsonFile -Path (Join-Path $pubInv $name) -Value (ConvertTo-AmdPublicRepositoryObject -Value $obj)}
    }
    foreach($name in @('product-groups.json','selection-plan.json','selected-release-metadata.json','signature-analysis.json','toolchain-capabilities.json','all-releases-summary.json','inf-topology.json','windows-server-applicability.json','windows-server-compatibility-analysis.json')){
        $src=Join-Path $runtimeInventory $name;if(Test-Path -LiteralPath $src -PathType Leaf){Copy-Item -LiteralPath $src -Destination (Join-Path $pubInv $name) -Force}
    }
    foreach($name in @('windows-server-compatibility-analysis.csv','server-compatibility-matrix.csv','device-server-compatibility-matrix.csv')){
        $src=Join-Path $runtimeInventory $name;if(Test-Path -LiteralPath $src -PathType Leaf){Copy-Item -LiteralPath $src -Destination (Join-Path $pubInv $name) -Force}
    }
    $runtimeReleases=Join-Path $runtimeInventory 'releases'
    if(Test-Path -LiteralPath $runtimeReleases -PathType Container){
        # The runtime tree is the authoritative cumulative release set. Replacing the
        # staged baseline prevents an older same-key public file from surviving an overlay.
        $stagedReleases=Join-Path $pubInv 'releases'
        if(Test-Path -LiteralPath $stagedReleases -PathType Container){Remove-Item -LiteralPath $stagedReleases -Recurse -Force}
        Copy-AmdEvidenceTree -Source $runtimeReleases -Destination $stagedReleases
    }
    foreach($name in @('amd-graphics-driver-history.md','windows-server-compatibility-analysis.md')){$src=Join-Path $runtimeReports $name;if(Test-Path -LiteralPath $src -PathType Leaf){Copy-AmdPublicMarkdownFile -Source $src -Destination (Join-Path $pubReports $name)}}
    $runtimeReleaseReports=Join-Path $runtimeReports 'releases'
    if(Test-Path -LiteralPath $runtimeReleaseReports -PathType Container){
        $dstReleaseReports=Join-Path $pubReports 'releases';New-AmdDirectory -Path $dstReleaseReports|Out-Null
        foreach($file in @(Get-ChildItem -LiteralPath $runtimeReleaseReports -Filter '*.md' -File -Recurse -Force)){
            $relativeReport=Get-AmdRelativePath -BasePath $runtimeReleaseReports -Path $file.FullName
            Copy-AmdPublicMarkdownFile -Source $file.FullName -Destination (Join-Path $dstReleaseReports $relativeReport)
        }
    }

    $selection=$null;$signature=$null;$summary=$null;$build=$null
    foreach($pair in @(@('selection-plan.json','selection'),@('signature-analysis.json','signature'),@('all-releases-summary.json','summary'),@('build-integrity.json','build'))){$path=Join-Path $runtimeInventory $pair[0];if(Test-Path -LiteralPath $path -PathType Leaf){Set-Variable -Name $pair[1] -Value (Read-AmdJsonFile -Path $path) -Scope Local}}
    $publicSummary=[pscustomobject][ordered]@{
        SchemaVersion='amd-graphics-public-run-summary/1.0';ToolkitVersion=$script:AmdGraphicsResearchToolkitVersion;GeneratedAtUtc=Get-AmdUtcTimestamp;OverallStatus=$CoreAssessment.OverallStatus;ExitCode=$CoreAssessment.ExitCode;SelectedStages=@($ResolvedStages);ScriptSha256=if($script:AmdEvidenceContext){$script:AmdEvidenceContext.ScriptSha256}else{$null}
        ProductSelection=if($selection){[pscustomobject][ordered]@{SelectionTrackCount=$selection.SelectionTrackCount;TrackGenerationSelectionCount=$selection.TrackGenerationSelectionCount;ArtifactSelectionCount=$selection.ArtifactSelectionCount;UniqueSelectedArtifactCount=$selection.UniqueSelectedArtifactCount;EstimatedDownloadBytes=$selection.EstimatedDownloadBytes;TrackEvidenceConflictCount=$selection.TrackEvidenceConflictCount}}else{$null}
        SignatureAnalysis=if($signature){[pscustomobject][ordered]@{Policy=$signature.ArtifactSelectionPolicy;CertificateTrackReferenceCount=$signature.Summary.CertificateTrackReferenceCount;AnalyzedUniqueInstallerCount=$signature.Summary.AnalyzedUniqueInstallerCount;UniqueCandidateFileContentCount=$signature.Summary.UniqueCandidateFileContentCount;UnexpectedStaticParseFailureCount=$signature.Summary.UnexpectedStaticParseFailureCount;SignedDigestMismatchCount=$signature.Summary.SignedDigestMismatchCount}}else{$null}
        PublishedDataset=if($summary){[pscustomobject][ordered]@{ArtifactCount=$summary.ArtifactCount;DriverCount=$summary.DriverCount}}else{$null}
        BuildIntegrity=if($build){[pscustomobject][ordered]@{Status=$build.Status;CumulativeArtifactCount=$build.CumulativeArtifactCount;CumulativeDriverCount=$build.CumulativeDriverCount;ServerRowCount=$build.ServerRowCount}}else{$null}
        Privacy=[pscustomobject][ordered]@{Classification='PublicRepositoryArtifact';ContainsHostEnvironment=$false;ContainsAbsoluteLocalPaths=$false;DebugEvidenceLocation='private/evidence (not published)'}
    }
    Write-AmdJsonFile -Path (Join-Path $staging 'run-summary.json') -Value $publicSummary
    $runMd=@('# AMD Graphics Driver Research — Public Run Summary','',(' - Toolkit: `{0}`' -f $script:AmdGraphicsResearchToolkitVersion),(' - Result: **{0}**' -f $CoreAssessment.OverallStatus),(' - Exit code: `{0}`' -f $CoreAssessment.ExitCode),(' - Stages: `{0}`' -f (@($ResolvedStages)-join ', ')),'','Canonical public JSON is generated compact before publication. Publication copies canonical runtime JSON byte-for-byte and does not rewrite JSON tokens. Public Markdown is normalized to UTF-8 without BOM and LF line endings.') -join "`n"
    Write-AmdPublicMarkdownText -Path (Join-Path $staging 'run-report.md') -Text $runMd

    # Normalize every staged public Markdown file, including preserved baseline/toolkit-authored files.
    # This final sweep is intentionally Markdown-only: JSON and CSV remain byte-faithful.
    foreach($markdownFile in @(Get-ChildItem -LiteralPath $staging -Filter '*.md' -File -Recurse -Force)){
        Copy-AmdPublicMarkdownFile -Source $markdownFile.FullName -Destination $markdownFile.FullName
    }

    # Fail closed: canonical JSON must already be compact and public Markdown must already satisfy LF/no-BOM.
    $validation=Test-AmdPublicRepositorySurface -Root $staging
    if([string]$validation.Status -ne 'Pass'){Remove-Item -LiteralPath $staging -Recurse -Force -ErrorAction SilentlyContinue;return [pscustomobject][ordered]@{Status='Fail';PublicRoot=$publicRoot;FileCount=0;Validation=$validation;Published=$false}}
    Write-AmdJsonFile -Path (Join-Path $staging 'publication-validation.json') -Value $validation

    $entries=New-Object System.Collections.Generic.List[object]
    foreach($file in @(Get-AmdOrdinalSortedObjectsByStringProperty -Values @(Get-ChildItem -LiteralPath $staging -File -Recurse -Force) -PropertyName 'FullName')){
        if($file.Name -eq 'publication-manifest.json'){continue}
        $relative=ConvertTo-AmdRepositoryRelativePath -RelativePath (Get-AmdRelativePath -BasePath $staging -Path $file.FullName)
        $sourceRelative=$null;$sourceSha=$null;$mode='ToolkitGeneratedOrPreservedBaseline'
        if($relative -like 'inventory/releases/*'){$sourceRelative=$relative;$mode='ByteCopyFromRuntimeCanonical'}
        elseif($relative -in @('inventory/product-groups.json','inventory/selection-plan.json','inventory/selected-release-metadata.json','inventory/signature-analysis.json','inventory/toolchain-capabilities.json','inventory/all-releases-summary.json','inventory/inf-topology.json','inventory/windows-server-applicability.json','inventory/windows-server-compatibility-analysis.json','inventory/windows-server-compatibility-analysis.csv','inventory/server-compatibility-matrix.csv','inventory/device-server-compatibility-matrix.csv')){$sourceRelative=$relative;$mode='ByteCopyFromRuntime'}
        elseif($relative -like 'reports/*'){$sourceRelative=$relative;$mode='MarkdownLfNoBomFromRuntime'}
        elseif($file.Extension -eq '.md' -and $relative -eq 'run-report.md'){$mode='ToolkitGeneratedMarkdownLfNoBom'}
        elseif($file.Extension -eq '.md'){$mode='ToolkitGeneratedOrPreservedMarkdownLfNoBom'}
        if($sourceRelative){$sourceNative=$sourceRelative -replace '/', [System.IO.Path]::DirectorySeparatorChar;$sourcePath=Join-Path $root $sourceNative;if(Test-Path -LiteralPath $sourcePath -PathType Leaf){$sourceSha=Get-AmdSha256 -Path $sourcePath}else{$sourceRelative=$null;$mode='ToolkitGeneratedOrPreservedBaseline'}}
        $entries.Add([pscustomobject][ordered]@{RelativePath=$relative;SizeBytes=[int64]$file.Length;Sha256=Get-AmdSha256 -Path $file.FullName;Classification='PublicRepositoryArtifact';GenerationMode=$mode;SourceRelativePath=$sourceRelative;SourceSha256=$sourceSha;HandEdited=$false})
    }
    $payloadSize=[int64]0;$largestSize=[int64]0;$largestPath=$null
    foreach($entry in @($entries.ToArray())){$payloadSize += [int64]$entry.SizeBytes;if([int64]$entry.SizeBytes -gt $largestSize){$largestSize=[int64]$entry.SizeBytes;$largestPath=[string]$entry.RelativePath}}
    $manifestPath=Join-Path $staging 'publication-manifest.json'
    Write-AmdJsonFile -Path $manifestPath -Value ([pscustomobject][ordered]@{
        SchemaVersion='amd-graphics-publication-manifest/1.3';ToolkitVersion=$script:AmdGraphicsResearchToolkitVersion;GeneratedAtUtc=Get-AmdUtcTimestamp;PathFormat='POSIXRelative';ManifestSelfIncluded=$false
        PublicRootPolicy='Only files under public/ are intended for automated repository commits.';PrivateDataPolicy='private/, inventory/, reports/, work/ and operator-specified evidence locations are not publication surfaces.'
        CanonicalJsonPolicy='Canonical JSON is UTF-8 no-BOM, LF-only, 2-space indented, insertion-ordered and byte-identical across Windows PowerShell 5.1, PowerShell 7.x and Python. Publication copies canonical runtime JSON byte-for-byte.'
        TransformationPolicy=@('Canonical per-artifact Raw JSON and aggregate JSON are compact when generated by the toolkit.','Runtime canonical JSON and CSV are copied into staging byte-for-byte and are never publication-time reserialized or line-ending normalized.','Generated public Markdown is deterministically normalized to UTF-8 without BOM and LF line endings; Markdown content is otherwise unchanged.','Source SHA-256 is recorded against the runtime pre-publication artifact while published SHA-256 is computed from the normalized public Markdown bytes.','Public JSON privacy validation parses JSON and inspects decoded scalar strings so escaped Windows paths cannot evade detection.','No generated public JSON/CSV/Markdown is intended to be hand-edited.')
        FileCount=$entries.Count;ManifestEntryCount=$entries.Count;PublicFileCountIncludingManifest=($entries.Count+1);ManifestedPayloadSizeBytes=$payloadSize;LargestManifestedFileSizeBytes=$largestSize;LargestManifestedFileRelativePath=$largestPath;Files=@($entries.ToArray())
    })
    $manifestIntegrity=Test-AmdPublicationManifestIntegrity -Root $staging -Entries $entries.ToArray()
    if([string]$manifestIntegrity.Status -ne 'Pass'){Remove-Item -LiteralPath $staging -Recurse -Force -ErrorAction SilentlyContinue;return [pscustomobject][ordered]@{Status='Fail';PublicRoot=$publicRoot;FileCount=0;Validation=$validation;ManifestIntegrity=$manifestIntegrity;Published=$false}}
    if(Test-Path -LiteralPath $publicRoot -PathType Container){Remove-Item -LiteralPath $publicRoot -Recurse -Force}
    Move-Item -LiteralPath $staging -Destination $publicRoot
    return [pscustomobject][ordered]@{Status='Pass';PublicRoot=$publicRoot;FileCount=$entries.Count+1;Validation=$validation;ManifestIntegrity=$manifestIntegrity;Published=$true}
}

function Get-AmdLatestStageResult {
    [CmdletBinding()]
    param([Parameter(Mandatory=$true)][string]$Name)

    $matches=@($script:AmdStageResults.ToArray()|Where-Object{$_.Name -eq $Name})
    if($matches.Count -eq 0){return $null}
    return $matches[$matches.Count-1]
}

function Get-AmdRunAssessment {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [string[]]$ResolvedStages = @()
    )

    $toolRoot = Get-AmdResearchToolkitRoot
    $items = New-Object 'System.Collections.Generic.List[object]'

    if (@($ResolvedStages).Count -eq 0) {
        $items.Add([pscustomobject]@{
            Name = 'Bootstrap'
            Status = 'REVIEW'
            Detail = 'stage resolution did not complete; evidence was finalized from bootstrap state'
        })
    }

    $failedStages = @($script:AmdStageResults.ToArray() | Where-Object { $_.Status -eq 'FAIL' })
    $blockedStages = @($script:AmdStageResults.ToArray() | Where-Object { $_.Status -eq 'BLOCKED' })
    $skippedStages = @($script:AmdStageResults.ToArray() | Where-Object { $_.Status -eq 'SKIPPED' })
    $interruptedStages = @($script:AmdStageResults.ToArray() | Where-Object { $_.Status -eq 'INTERRUPTED' })
    $stageNeedsReview = ($failedStages.Count -gt 0 -or $blockedStages.Count -gt 0 -or $interruptedStages.Count -gt 0)
    $stageDetail = if (@($ResolvedStages).Count -eq 0) {
        'no stage was resolved or executed before bootstrap termination'
    }
    elseif ($interruptedStages.Count -gt 0) {
        ('run interrupted during: {0}; later selected stages were not executed' -f (@($interruptedStages.Name) -join ', '))
    }
    elseif (-not $stageNeedsReview) {
        if ($skippedStages.Count -gt 0) {
            ('{0} selected stage(s) completed; {1} stage(s) were intentionally skipped' -f (@($script:AmdStageResults.ToArray() | Where-Object { $_.Status -eq 'PASS' }).Count), $skippedStages.Count)
        }
        else {
            ('all {0} selected stage(s) completed without terminating errors' -f $script:AmdStageResults.Count)
        }
    }
    else {
        $parts = New-Object System.Collections.Generic.List[string]
        if ($failedStages.Count -gt 0) { $parts.Add(('{0} failed: {1}' -f $failedStages.Count, (@($failedStages.Name) -join ', '))) }
        if ($blockedStages.Count -gt 0) { $parts.Add(('{0} blocked: {1}' -f $blockedStages.Count, (@($blockedStages.Name) -join ', '))) }
        if ($skippedStages.Count -gt 0) { $parts.Add(('{0} downstream skipped: {1}' -f $skippedStages.Count, (@($skippedStages.Name) -join ', '))) }
        $parts -join '; '
    }
    $items.Add([pscustomobject]@{
        Name = 'StageExecution'
        Status = if (@($ResolvedStages).Count -eq 0) { 'NOT_ASSESSED' } elseif ($interruptedStages.Count -gt 0) { 'INTERRUPTED' } elseif ($stageNeedsReview) { 'REVIEW' } else { 'PASS' }
        Detail = $stageDetail
    })

    if($ResolvedStages -contains 'PathSafety'){
        $pathSafetyPath=Join-Path $toolRoot 'inventory\path-safety-assessment.json'
        if(Test-Path -LiteralPath $pathSafetyPath -PathType Leaf){
            try{$pathSafety=Read-AmdJsonFile -Path $pathSafetyPath;$items.Add([pscustomobject]@{Name='PathSafety';Status=if([string]$pathSafety.Status -eq 'Pass'){'PASS'}else{'REVIEW'};Detail=('status={0}; root-length={1}/{2}; predicted-max={3}/{4}' -f [string]$pathSafety.Status,[int]$pathSafety.ToolRootLength,[int]$pathSafety.Policy.MaximumToolRootLength,[int]$pathSafety.PredictedPaths.MaximumDesignedExtractionPathLength,[int]$pathSafety.Policy.SafeFullPathLimit)})}
            catch{$items.Add([pscustomobject]@{Name='PathSafety';Status='REVIEW';Detail=$_.Exception.Message})}
        }else{$items.Add([pscustomobject]@{Name='PathSafety';Status='REVIEW';Detail='path-safety-assessment.json is missing'})}
    }

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

    if ($ResolvedStages -contains 'ProductDiscover') {
        $catalogPath = Join-Path (Join-Path $toolRoot 'inventory') 'products.json'
        if (Test-Path -LiteralPath $catalogPath -PathType Leaf) {
            try {
                $catalog = Read-AmdJsonFile -Path $catalogPath
                $complete = [bool]$catalog.CanClaimFullProductCatalog
                $catalogCompleteness=[string]$catalog.Completeness
                $curatedScope=($catalogCompleteness -eq 'CuratedProductGroupCatalog')
                $items.Add([pscustomobject]@{
                    Name = 'ProductCatalogCoverage'
                    Status = if ($complete -or $curatedScope) { 'PASS' } else { 'REVIEW' }
                    Detail = if($curatedScope){('Curated research scope {0}; products={1}; groups={2}; every-product-model-claim=false' -f [string]$catalog.CatalogVersion,[int]$catalog.ProductCount,[int]$catalog.ProductGroupCount)}else{('{0}; products={1}; groups={2}; full-catalog-claim={3}' -f $catalogCompleteness,[int]$catalog.ProductCount,[int]$catalog.ProductGroupCount,$complete)}
                })
            }
            catch {
                $items.Add([pscustomobject]@{ Name = 'ProductCatalogCoverage'; Status = 'REVIEW'; Detail = $_.Exception.Message })
            }
        }
    }

    if ($ResolvedStages -contains 'ProductMetadata') {
        $mappingPath = Join-Path (Join-Path $toolRoot 'inventory') 'product-driver-mapping.json'
        if (Test-Path -LiteralPath $mappingPath -PathType Leaf) {
            try {
                $mapping = Read-AmdJsonFile -Path $mappingPath
                $metadataCompleteness=if($mapping.PSObject.Properties['MetadataCompleteness']){[string]$mapping.MetadataCompleteness}else{'LegacyUnknown'}
                $recoveredCount=if($mapping.PSObject.Properties['RecoveredFetchProductCount']){[int]$mapping.RecoveredFetchProductCount}else{0}
                $fallbackCount=if($mapping.PSObject.Properties['FallbackFetchProductCount']){[int]$mapping.FallbackFetchProductCount}else{0}
                $retryAttemptCount=if($mapping.PSObject.Properties['RetryAttemptCount']){[int]$mapping.RetryAttemptCount}else{0}
                $items.Add([pscustomobject]@{
                    Name = 'ProductMetadataCoverage'
                    Status = if ($metadataCompleteness -eq 'Complete') { 'PASS' } else { 'REVIEW' }
                    Detail = ('{0}; products={1}; driver entries={2}; latest failures={3}; previous failures={4}; no-driver products={5}; recovered-products={6}; fallback-products={7}; retry-attempts={8}' -f $metadataCompleteness,[int]$mapping.ProductCount,[int]$mapping.DriverEntryCount,[int]$mapping.LatestFetchFailureCount,[int]$mapping.PreviousFetchFailureCount,[int]$mapping.NoDriverEntryProductCount,$recoveredCount,$fallbackCount,$retryAttemptCount)
                })
            }
            catch {
                $items.Add([pscustomobject]@{ Name = 'ProductMetadataCoverage'; Status = 'REVIEW'; Detail = $_.Exception.Message })
            }
        }
    }

    if ($ResolvedStages -contains 'Select') {
        $selectionPath = Join-Path (Join-Path $toolRoot 'inventory') 'selection-plan.json'
        if (Test-Path -LiteralPath $selectionPath -PathType Leaf) {
            try {
                $selection = Read-AmdJsonFile -Path $selectionPath
                $selectionAssessment = Get-AmdProductSelectionAssessment -Selection $selection
                $items.Add([pscustomobject]@{
                    Name = 'ProductSelection'
                    Status = [string]$selectionAssessment.Status
                    Detail = [string]$selectionAssessment.Detail
                })
            }
            catch {
                $items.Add([pscustomobject]@{ Name = 'ProductSelection'; Status = 'REVIEW'; Detail = $_.Exception.Message })
            }
        }
        else {
            $items.Add([pscustomobject]@{ Name = 'ProductSelection'; Status = 'REVIEW'; Detail = 'selection-plan.json is missing' })
        }
    }

    if ($ResolvedStages -contains 'Acquire') {
        $path = Join-Path (Join-Path $toolRoot 'inventory') 'acquisition.json'
        $acquireStage = @($script:AmdStageResults.ToArray() | Where-Object { $_.Name -eq 'Acquire' } | Select-Object -Last 1)
        if ($acquireStage.Count -gt 0 -and $acquireStage[0].Status -eq 'BLOCKED') {
            $items.Add([pscustomobject]@{
                Name = 'Acquisition'
                Status = 'REVIEW'
                Detail = ('blocked before download: {0}' -f [string]$acquireStage[0].Reason)
            })
        }
        elseif (Test-Path -LiteralPath $path -PathType Leaf) {
            try {
                $data = Read-AmdJsonFile -Path $path
                $failed = @((Get-AmdCollectionItems -Value $data.Artifacts) | Where-Object { $_.Status -notin @('Downloaded', 'Cached', 'Provided') })
                $items.Add([pscustomobject]@{
                    Name = 'Acquisition'
                    Status = if ($failed.Count -eq 0) { 'PASS' } else { 'REVIEW' }
                    Detail = if ($failed.Count -eq 0) { ('{0} installer artifact(s) available' -f @(Get-AmdCollectionItems -Value $data.Artifacts).Count) } else { ('{0} installer artifact(s) unavailable' -f $failed.Count) }
                })
            }
            catch {
                $items.Add([pscustomobject]@{ Name = 'Acquisition'; Status = 'REVIEW'; Detail = $_.Exception.Message })
            }
        }
    }

    if ($ResolvedStages -contains 'Extract') {
        $extractStage=Get-AmdLatestStageResult -Name 'Extract'
        $path = Join-Path (Join-Path $toolRoot 'inventory') 'extraction.json'
        if($extractStage -and [string]$extractStage.Status -eq 'SKIPPED'){
            $items.Add([pscustomobject]@{Name='ExtractionCompleteness';Status='SKIP';Detail=('not evaluated because Extract was skipped: {0}' -f [string]$extractStage.Reason)})
        }
        elseif (Test-Path -LiteralPath $path -PathType Leaf) {
            try {
                $data = Read-AmdJsonFile -Path $path
                $partial = @((Get-AmdCollectionItems -Value $data.Releases) | Where-Object { $_.Status -ne 'ExtractionComplete' })
                $items.Add([pscustomobject]@{
                    Name = 'ExtractionCompleteness'
                    Status = if ($partial.Count -eq 0 -and @(Get-AmdCollectionItems -Value $data.Releases).Count -gt 0) { 'PASS' } else { 'REVIEW' }
                    Detail = if ($partial.Count -eq 0 -and @(Get-AmdCollectionItems -Value $data.Releases).Count -gt 0) {
                        ('{0} release(s) reached INF-bearing extraction output' -f @(Get-AmdCollectionItems -Value $data.Releases).Count)
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
        elseif($extractStage -and [string]$extractStage.Status -eq 'PASS'){
            $items.Add([pscustomobject]@{Name='ExtractionCompleteness';Status='REVIEW';Detail='Extract reported PASS but extraction.json is missing'})
        }
    }


    if ($ResolvedStages -contains 'Inspect') {
        $inspectStage=Get-AmdLatestStageResult -Name 'Inspect'
        $path = Join-Path (Join-Path $toolRoot 'inventory') 'driver-packages.json'
        if($inspectStage -and [string]$inspectStage.Status -eq 'SKIPPED'){
            $items.Add([pscustomobject]@{Name='InfInspection';Status='SKIP';Detail=('not evaluated because Inspect was skipped: {0}' -f [string]$inspectStage.Reason)})
        }
        elseif (Test-Path -LiteralPath $path -PathType Leaf) {
            try {
                $data = Read-AmdJsonFile -Path $path
                $inspectionAssessment = Get-AmdInfInspectionAssessment -DriverData $data
                $items.Add([pscustomobject]@{
                    Name = 'InfInspection'
                    Status = [string]$inspectionAssessment.Status
                    Detail = [string]$inspectionAssessment.Detail
                })
            }
            catch {
                $items.Add([pscustomobject]@{ Name = 'InfInspection'; Status = 'REVIEW'; Detail = $_.Exception.Message })
            }
        }
        else {
            $items.Add([pscustomobject]@{ Name = 'InfInspection'; Status = 'REVIEW'; Detail = 'driver-packages.json is missing' })
        }
    }

    if (($ResolvedStages -contains 'Signature') -or ($ResolvedStages -contains 'SignatureNative')) {
        $signatureStageName=if($ResolvedStages -contains 'SignatureNative'){'SignatureNative'}else{'Signature'}
        $signatureStage=Get-AmdLatestStageResult -Name $signatureStageName
        $signaturePath=Join-Path (Join-Path $toolRoot 'inventory') 'signature-analysis.json'
        $planPath=Join-Path (Join-Path $toolRoot 'inventory') 'certificate-verification-plan.json'
        if($signatureStage -and [string]$signatureStage.Status -eq 'SKIPPED'){
            $items.Add([pscustomobject]@{Name='SignatureAnalysis';Status='SKIP';Detail=('not evaluated because {0} was skipped: {1}' -f $signatureStageName,[string]$signatureStage.Reason)})
        }
        elseif((Test-Path -LiteralPath $signaturePath -PathType Leaf)-and(Test-Path -LiteralPath $planPath -PathType Leaf)){
            try{
                $signature=Read-AmdJsonFile -Path $signaturePath
                $plan=Read-AmdJsonFile -Path $planPath
                $parseFailures=[int]$signature.Summary.UnexpectedStaticParseFailureCount
                $digestMismatches=[int]$signature.Summary.SignedDigestMismatchCount
                $analyzed=@(Get-AmdCollectionItems -Value $signature.Artifacts).Count
                $expected=@(Get-AmdCollectionItems -Value $plan.Resolution.ExecutionArtifacts).Count
                $status=if([string]$plan.Status -eq 'Ready' -and $analyzed -eq $expected -and $parseFailures -eq 0 -and $digestMismatches -eq 0){'PASS'}else{'REVIEW'}
                $items.Add([pscustomobject]@{Name='SignatureAnalysis';Status=$status;Detail=('policy={0}; newest-track-references={1}; unique-installers={2}/{3}; unique-files={4}; parse-failures={5}; digest-mismatches={6}' -f [string]$plan.PolicyId,[int]$plan.CertificateTrackReferenceCount,$analyzed,$expected,[int]$signature.Summary.UniqueCandidateFileContentCount,$parseFailures,$digestMismatches)})
            }catch{
                $items.Add([pscustomobject]@{Name='SignatureAnalysis';Status='REVIEW';Detail=$_.Exception.Message})
            }
        }else{
            $items.Add([pscustomobject]@{Name='SignatureAnalysis';Status='REVIEW';Detail='certificate-verification-plan.json or signature-analysis.json is missing'})
        }
    }


    if (($ResolvedStages -contains 'Inspect') -or ($ResolvedStages -contains 'Build')) {
        $inspectStage=Get-AmdLatestStageResult -Name 'Inspect'
        $buildStage=Get-AmdLatestStageResult -Name 'Build'
        $integrityPath = Join-Path (Join-Path $toolRoot 'inventory') 'driver-packages-integrity.json'
        if($inspectStage -and [string]$inspectStage.Status -eq 'SKIPPED'){
            $items.Add([pscustomobject]@{Name='DriverPackageShardIntegrity';Status='SKIP';Detail='not evaluated because Inspect was skipped'})
        }
        elseif (Test-Path -LiteralPath $integrityPath -PathType Leaf) {
            try {
                $integrity = Read-AmdJsonFile -Path $integrityPath
                $items.Add([pscustomobject]@{
                    Name = 'DriverPackageShardIntegrity'
                    Status = if ([string]$integrity.Status -eq 'Pass') { 'PASS' } else { 'REVIEW' }
                    Detail = ('status={0}; artifacts={1}; drivers={2}; errors={3}' -f [string]$integrity.Status,[int]$integrity.ArtifactCount,[int]$integrity.DriverPackageCount,@($integrity.Errors).Count)
                })
            }
            catch {
                $items.Add([pscustomobject]@{ Name = 'DriverPackageShardIntegrity'; Status = 'REVIEW'; Detail = $_.Exception.Message })
            }
        }
        else {
            $items.Add([pscustomobject]@{ Name = 'DriverPackageShardIntegrity'; Status = 'REVIEW'; Detail = 'driver-packages-integrity.json is missing' })
        }
    }

    if (($ResolvedStages -contains 'Inspect') -or ($ResolvedStages -contains 'Build')) {
        $inspectStage=Get-AmdLatestStageResult -Name 'Inspect'
        $indexPath = Join-Path (Join-Path $toolRoot 'inventory') 'driver-packages.json'
        $integrityPath = Join-Path (Join-Path $toolRoot 'inventory') 'driver-packages-integrity.json'
        if($inspectStage -and [string]$inspectStage.Status -eq 'SKIPPED'){
            $items.Add([pscustomobject]@{Name='InspectionAssessmentConsistency';Status='SKIP';Detail='not evaluated because Inspect was skipped'})
        }
        elseif ((Test-Path -LiteralPath $indexPath -PathType Leaf) -and (Test-Path -LiteralPath $integrityPath -PathType Leaf)) {
            try {
                $indexData = Read-AmdJsonFile -Path $indexPath
                $inspectionAssessment = Get-AmdInfInspectionAssessment -DriverData $indexData
                $integrityData = Read-AmdJsonFile -Path $integrityPath
                $consistencyErrors = New-Object System.Collections.Generic.List[string]
                if ([int]$inspectionAssessment.ArtifactCount -ne [int]$integrityData.ArtifactCount) {
                    $consistencyErrors.Add(('artifact count assessment={0} integrity={1}' -f [int]$inspectionAssessment.ArtifactCount,[int]$integrityData.ArtifactCount))
                }
                if ([int]$inspectionAssessment.DriverPackageCount -ne [int]$integrityData.DriverPackageCount) {
                    $consistencyErrors.Add(('driver count assessment={0} integrity={1}' -f [int]$inspectionAssessment.DriverPackageCount,[int]$integrityData.DriverPackageCount))
                }
                if ([int]$inspectionAssessment.ParseFailureCount -ne [int]$integrityData.ParseFailureCount) {
                    $consistencyErrors.Add(('parse-failure count assessment={0} integrity={1}' -f [int]$inspectionAssessment.ParseFailureCount,[int]$integrityData.ParseFailureCount))
                }
                $items.Add([pscustomobject]@{
                    Name = 'InspectionAssessmentConsistency'
                    Status = if ($consistencyErrors.Count -eq 0) { 'PASS' } else { 'REVIEW' }
                    Detail = if ($consistencyErrors.Count -eq 0) {
                        ('assessment/index/integrity agree: artifacts={0}; drivers={1}; parse-failures={2}' -f [int]$integrityData.ArtifactCount,[int]$integrityData.DriverPackageCount,[int]$integrityData.ParseFailureCount)
                    }
                    else {
                        ($consistencyErrors.ToArray() -join ' | ')
                    }
                })
            }
            catch {
                $items.Add([pscustomobject]@{ Name = 'InspectionAssessmentConsistency'; Status = 'REVIEW'; Detail = $_.Exception.Message })
            }
        }
    }


    if (($ResolvedStages -contains 'Select') -and ($ResolvedStages -contains 'Acquire') -and ($ResolvedStages -contains 'Extract') -and ($ResolvedStages -contains 'Inspect')) {
        $inventoryRoot = Join-Path $toolRoot 'inventory'
        $selectionPath = Join-Path $inventoryRoot 'selection-plan.json'
        $acquisitionPath = Join-Path $inventoryRoot 'acquisition.json'
        $extractionPath = Join-Path $inventoryRoot 'extraction.json'
        $driverIndexPath = Join-Path $inventoryRoot 'driver-packages.json'
        if ((Test-Path -LiteralPath $selectionPath -PathType Leaf) -and
            (Test-Path -LiteralPath $acquisitionPath -PathType Leaf) -and
            (Test-Path -LiteralPath $extractionPath -PathType Leaf) -and
            (Test-Path -LiteralPath $driverIndexPath -PathType Leaf)) {
            try {
                $pipelineAssessment = Get-AmdArtifactPipelineConsistencyAssessment `
                    -Selection (Read-AmdJsonFile -Path $selectionPath) `
                    -Acquisition (Read-AmdJsonFile -Path $acquisitionPath) `
                    -Extraction (Read-AmdJsonFile -Path $extractionPath) `
                    -DriverData (Read-AmdJsonFile -Path $driverIndexPath)
                $items.Add([pscustomobject]@{
                    Name = 'ArtifactPipelineConsistency'
                    Status = [string]$pipelineAssessment.Status
                    Detail = [string]$pipelineAssessment.Detail
                })
            }
            catch {
                $items.Add([pscustomobject]@{ Name = 'ArtifactPipelineConsistency'; Status = 'REVIEW'; Detail = $_.Exception.Message })
            }
        }
        else {
            $acquireStage=Get-AmdLatestStageResult -Name 'Acquire'
            $extractStage=Get-AmdLatestStageResult -Name 'Extract'
            $inspectStage=Get-AmdLatestStageResult -Name 'Inspect'
            if(($acquireStage -and [string]$acquireStage.Status -eq 'BLOCKED') -or ($extractStage -and [string]$extractStage.Status -eq 'SKIPPED') -or ($inspectStage -and [string]$inspectStage.Status -eq 'SKIPPED')){
                $items.Add([pscustomobject]@{ Name = 'ArtifactPipelineConsistency'; Status = 'SKIP'; Detail = 'not evaluated because the download/analysis pipeline was blocked or skipped upstream' })
            }
            else{
                $items.Add([pscustomobject]@{ Name = 'ArtifactPipelineConsistency'; Status = 'REVIEW'; Detail = 'selection/acquisition/extraction/driver-package evidence is incomplete' })
            }
        }
    }

    if ($ResolvedStages -contains 'Build') {
        $buildStage=Get-AmdLatestStageResult -Name 'Build'
        $integrityPath = Join-Path (Join-Path $toolRoot 'inventory') 'build-integrity.json'
        if($buildStage -and [string]$buildStage.Status -eq 'SKIPPED'){
            $items.Add([pscustomobject]@{Name='BuildAggregateIntegrity';Status='SKIP';Detail=('not evaluated because Build was skipped: {0}' -f [string]$buildStage.Reason)})
        }
        elseif (Test-Path -LiteralPath $integrityPath -PathType Leaf) {
            try {
                $integrity = Read-AmdJsonFile -Path $integrityPath
                $items.Add([pscustomobject]@{
                    Name = 'BuildAggregateIntegrity'
                    Status = if ([string]$integrity.Status -eq 'Pass') { 'PASS' } else { 'REVIEW' }
                    Detail = ('status={0}; cumulative-artifacts={1}; cumulative-drivers={2}; server-rows={3}; errors={4}' -f [string]$integrity.Status,[int]$integrity.CumulativeArtifactCount,[int]$integrity.CumulativeDriverCount,[int]$integrity.ServerRowCount,@($integrity.Errors).Count)
                })
            }
            catch {
                $items.Add([pscustomobject]@{ Name = 'BuildAggregateIntegrity'; Status = 'REVIEW'; Detail = $_.Exception.Message })
            }
        }
        else {
            $items.Add([pscustomobject]@{ Name = 'BuildAggregateIntegrity'; Status = 'REVIEW'; Detail = 'build-integrity.json is missing' })
        }
    }

    if ($null -ne $script:AmdPublicationResult) {
        $publicationStatus=[string]$script:AmdPublicationResult.Status
        if($publicationStatus -eq 'Pass'){
            $pubStatus='PASS'
            $manifestStatus=if($script:AmdPublicationResult.PSObject.Properties['ManifestIntegrity']){[string]$script:AmdPublicationResult.ManifestIntegrity.Status}else{'Unknown'}
            $pubDetail=('public repository surface validated and updated; files={0}; host/debug evidence excluded; dataset-consistency={1}; manifest-integrity={2}; manifest-path-format=POSIXRelative' -f [int]$script:AmdPublicationResult.FileCount,[string]$script:AmdPublicationResult.Validation.DatasetConsistencyStatus,$manifestStatus)
        }
        elseif($publicationStatus -eq 'Skipped'){
            $pubStatus='SKIP'
            $pubDetail=if($script:AmdPublicationResult.PSObject.Properties['Reason']){[string]$script:AmdPublicationResult.Reason}else{'public repository surface was preserved without modification because the current run was not publishable'}
        }
        else{
            $pubStatus='REVIEW'
            $validation=$script:AmdPublicationResult.Validation
            $pubDetail=('public repository surface was not updated because validation failed; privacy={0}/{1}; canonical-json={2}/{3}; dataset-consistency={4}/{5}; markdown-format={6}/{7}; total-errors={8}' -f [string]$validation.PrivacyStatus,[int]$validation.PrivacyErrorCount,[string]$validation.JsonWhitespaceStatus,[int]$validation.JsonWhitespaceErrorCount,[string]$validation.DatasetConsistencyStatus,[int]$validation.DatasetConsistencyErrorCount,[string]$validation.MarkdownFormatStatus,[int]$validation.MarkdownFormatErrorCount,[int]$validation.ErrorCount)
        }
        $items.Add([pscustomobject][ordered]@{Name='PublicRepositorySurface';Status=$pubStatus;Detail=$pubDetail})
    }

    $reviewCount = @($items.ToArray() | Where-Object { $_.Status -eq 'REVIEW' }).Count
    $overall = if ($script:AmdTopLevelFatalError) { 'FatalError' }
        elseif ($interruptedStages.Count -gt 0) { 'Interrupted' }
        elseif ($reviewCount -gt 0) { 'ReviewRequired' }
        else { 'Pass' }

    return [pscustomobject][ordered]@{
        SchemaVersion = $script:AmdAssessmentSchemaVersion
        ToolkitVersion = $script:AmdGraphicsResearchToolkitVersion
        GeneratedAtUtc = Get-AmdUtcTimestamp
        OverallStatus = $overall
        ExitCode = if ($overall -eq 'Pass') { 0 } elseif ($overall -eq 'FatalError') { 1 } elseif ($overall -eq 'Interrupted') { 130 } else { 2 }
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
    Write-Host ' AMD GRAPHICS DRIVER RESEARCH RUN REPORT' -ForegroundColor Cyan
    Write-Host '================================================================================================================' -ForegroundColor Cyan
    foreach ($item in @($Assessment.Items)) {
        $color = if ($item.Status -eq 'PASS') { 'Green' } elseif ($item.Status -eq 'SKIP') { 'DarkGray' } else { 'Yellow' }
        Write-Host (('[{0}]' -f $item.Status).PadRight(10)) -NoNewline -ForegroundColor $color
        Write-Host ('{0,-28} {1}' -f $item.Name, $item.Detail)
    }
    Write-Host '----------------------------------------------------------------------------------------------------------------' -ForegroundColor DarkGray
    Write-Host ('FINAL RESULT  : {0}' -f $Assessment.OverallStatus)
    Write-Host ('EXIT CODE     : {0}' -f $Assessment.ExitCode)
    Write-Host ('TOTAL ELAPSED : {0}' -f (Format-AmdElapsed ((Get-Date) - $script:AmdRunStartTime))) -ForegroundColor Cyan
    if ($ZipPath) { Write-Host ('EVIDENCE ZIP TO SHARE : {0}' -f $ZipPath) }
    if ($EvidenceDirectory) { Write-Host ('EVIDENCE WORK DIR     : {0}' -f $EvidenceDirectory) }
    Write-Host '================================================================================================================' -ForegroundColor Cyan
}


function Copy-AmdPrivateRuntimeSnapshot {
    [CmdletBinding()]
    param([Parameter(Mandatory=$true)][string]$Destination)

    $root=Get-AmdResearchToolkitRoot
    $inventory=Join-Path $root 'inventory'
    New-AmdDirectory -Path $Destination|Out-Null
    $privateFiles=@(
        'environment.json','path-safety-assessment.json','products.json','product-groups.json','product-driver-mapping.json','selection-plan.json','selected-release-metadata.json',
        'releases.json','release-metadata.json','acquisition.json','artifact-path-map.json','extraction-path-safety.json','extraction.json','embedded-installer-metadata.json','driver-packages.json',
        'driver-packages-integrity.json','certificate-verification-plan.json','signature-analysis.json','native-verification-path-map.json','toolchain-capabilities.json',
        'build-integrity.json','amd-graphics-driver-inventory.json','amd-graphics-driver-inventory.csv'
    )
    foreach($name in $privateFiles){
        $src=Join-Path $inventory $name
        if(Test-Path -LiteralPath $src -PathType Leaf){Copy-Item -LiteralPath $src -Destination (Join-Path $Destination $name) -Force}
    }
    $detail=Join-Path $inventory 'driver-packages-artifacts'
    if(Test-Path -LiteralPath $detail -PathType Container){Copy-AmdEvidenceTree -Source $detail -Destination (Join-Path $Destination 'driver-packages-artifacts')}
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

function Finalize-AmdResearchEvidenceSession {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [string[]]$ResolvedStages = @(),

        [switch]$SkipArchive,

        [switch]$IncludeInstallers
    )

    if ($null -eq $script:AmdEvidenceContext) {
        return (Get-AmdRunAssessment -ResolvedStages $ResolvedStages)
    }

    $ctx = $script:AmdEvidenceContext
    Write-AmdStageResultsEvidence

    $coreAssessment = Get-AmdRunAssessment -ResolvedStages $ResolvedStages
    $publishRelevant = @($ResolvedStages | Where-Object { $_ -in @('ProductDiscover','ProductMetadata','Select','Signature','Build') }).Count -gt 0
    if (-not $script:SkipPublicExport -and $publishRelevant) {
        $script:AmdPublicationResult = Publish-AmdRepositorySurface -CoreAssessment $coreAssessment -ResolvedStages $ResolvedStages
    }
    $assessment = Get-AmdRunAssessment -ResolvedStages $ResolvedStages
    Stop-AmdDiagnosticTrace -Assessment $assessment
    Write-AmdJsonFile -Path (Join-Path $ctx.EvidenceDirectory 'assessment.json') -Value $assessment
    $runElapsed = (Get-Date) - $script:AmdRunStartTime

    $summary = [pscustomobject][ordered]@{
        SchemaVersion = $script:AmdGraphicsResearchEvidenceSchemaVersion
        ToolkitVersion = $script:AmdGraphicsResearchToolkitVersion
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
        EvidenceRoot = $ctx.EvidenceRoot
        EvidenceRetention = $ctx.EvidenceRetention
        EvidenceStoragePolicy = 'ToolLocalCanonicalRootOnly/1.0'
        PublicOutputRoot = if ($script:AmdPublicationResult -and $script:AmdPublicationResult.Published) { $script:AmdPublicationResult.PublicRoot } else { $null }
        IncludeInstallersInEvidence = [bool]$IncludeInstallers
        RawWorkDirectoryIncluded = $false
        Notes = @(
            'The work/extracted tree is intentionally excluded from the evidence ZIP to keep review bundles manageable.',
            'Installer binaries are excluded by default; acquisition.json records path, SHA-256 and size.',
            'Use -IncludeInstallersInEvidence only when binary preservation inside the review ZIP is explicitly required.',
            'Only public/** is intended for automated repository commits; this evidence bundle is private/debug data and may contain host/environment paths.',
            'The publication-source runtime staging under inventory/** and reports/** is snapshotted privately so publication-manifest SourceSha256 claims can be independently recomputed.',
            'When current-run publication succeeds, a byte-identical validated review copy of public/** is included under snapshot/public inside the private Evidence ZIP.'
        )
    }
    Write-AmdJsonFile -Path (Join-Path $ctx.EvidenceDirectory 'run-summary.json') -Value $summary

    $summaryText = @(
        'AMD GRAPHICS DRIVER RESEARCH EVIDENCE',
        ('Toolkit version : {0}' -f $script:AmdGraphicsResearchToolkitVersion),
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

    foreach ($name in @('Invoke-AmdGraphicsDriverResearch.ps1', 'README.md', 'SPEC.md', 'THIRD-PARTY-NOTICES.md')) {
        $src = Join-Path (Get-AmdResearchToolkitRoot) $name
        if (Test-Path -LiteralPath $src -PathType Leaf) {
            Copy-Item -LiteralPath $src -Destination (Join-Path $toolSnapshot $name) -Force
        }
    }

    # Preserve the historical private runtime-inventory subset for compatibility, and also
    # snapshot the exact runtime publication-source staging so SourceRelativePath/SourceSha256
    # claims in publication-manifest.json are independently verifiable from this Evidence ZIP.
    Copy-AmdPrivateRuntimeSnapshot -Destination (Join-Path $snapshot 'runtime-inventory')
    Copy-AmdEvidenceTree -Source (Join-Path (Get-AmdResearchToolkitRoot) 'inventory') -Destination (Join-Path $snapshot 'inventory')
    Copy-AmdEvidenceTree -Source (Join-Path (Get-AmdResearchToolkitRoot) 'reports') -Destination (Join-Path $snapshot 'reports')
    if($script:AmdPublicationResult -and $script:AmdPublicationResult.Published){
        $publicRoot=[string]$script:AmdPublicationResult.PublicRoot
        $publicSnapshotRoot=Join-Path $snapshot 'public'
        Copy-AmdEvidenceTree -Source $publicRoot -Destination $publicSnapshotRoot
        $publicSnapshotValidation=Test-AmdEvidencePublicSnapshot -PublicRoot $publicRoot -SnapshotRoot $publicSnapshotRoot
        if([string]$publicSnapshotValidation.Status -ne 'Pass'){throw('Evidence public snapshot validation failed: '+(@($publicSnapshotValidation.Errors)-join '; '))}
        $publicManifest=Join-Path $publicRoot 'publication-manifest.json'
        Write-AmdJsonFile -Path (Join-Path $snapshot 'public-publication-reference.json') -Value ([pscustomobject][ordered]@{
            Classification='PrivateEvidenceReference';PublicManifest='snapshot/public/publication-manifest.json';PublicManifestSha256=Get-AmdSha256 -Path $publicManifest
            PublicFileCount=[int]$publicSnapshotValidation.PublicFileCount;ManifestPayloadCount=[int]$publicSnapshotValidation.ManifestPayloadCount;PublicDatasetIncludedInEvidence=$true
            SnapshotValidationStatus=[string]$publicSnapshotValidation.Status;Note='A byte-identical copy of the validated public dataset is included under snapshot/public for self-contained review.'
        })
    }
    Copy-AmdEvidenceTree -Source (Join-Path (Join-Path (Join-Path (Get-AmdResearchToolkitRoot) 'private') 'evidence') 'release-notes') -Destination (Join-Path $snapshot 'release-notes')
    Copy-AmdEvidenceTree -Source (Join-Path (Get-AmdResearchToolkitRoot) 'private\l\x') -Destination (Join-Path $snapshot 'extraction-logs')
    Copy-AmdEvidenceTree -Source (Join-Path (Get-AmdResearchToolkitRoot) 'private\l\d') -Destination (Join-Path $snapshot 'download-diagnostics')
    Copy-AmdEvidenceTree -Source (Join-Path (Join-Path (Join-Path (Get-AmdResearchToolkitRoot) 'private') 'evidence') 'extraction-logs') -Destination (Join-Path $snapshot 'legacy-extraction-logs')
    Copy-AmdEvidenceTree -Source (Join-Path (Join-Path (Join-Path (Get-AmdResearchToolkitRoot) 'private') 'evidence') 'download-diagnostics') -Destination (Join-Path $snapshot 'legacy-download-diagnostics')

    if ($IncludeInstallers) {
        Copy-AmdEvidenceTree -Source (Join-Path (Get-AmdResearchToolkitRoot) 'private\a') -Destination (Join-Path $snapshot 'installers')
        Copy-AmdEvidenceTree -Source (Join-Path (Join-Path (Join-Path (Get-AmdResearchToolkitRoot) 'private') 'evidence') 'installers') -Destination (Join-Path $snapshot 'legacy-installers')
    }

    $artifactIndex = New-Object 'System.Collections.Generic.List[object]'
    $acquisitionPath = Join-Path (Join-Path (Get-AmdResearchToolkitRoot) 'inventory') 'acquisition.json'
    if (Test-Path -LiteralPath $acquisitionPath -PathType Leaf) {
        try {
            $acq = Read-AmdJsonFile -Path $acquisitionPath
            foreach ($artifact in @(Get-AmdCollectionItems -Value $acq.Artifacts)) {
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
            RelativePath = ConvertTo-AmdRepositoryRelativePath -RelativePath (Get-AmdRelativePath -BasePath $ctx.EvidenceDirectory -Path $file.FullName)
            SizeBytes = [int64]$file.Length
            Sha256 = try { Get-AmdSha256 -Path $file.FullName } catch { $null }
        })
    }

    Write-AmdJsonFile -Path (Join-Path $ctx.EvidenceDirectory 'evidence-manifest.json') -Value ([pscustomobject][ordered]@{
        SchemaVersion = 'amd-graphics-driver-research-evidence-manifest/1.0'
        GeneratedAtUtc = Get-AmdUtcTimestamp
        FileCount = $manifestEntries.Count
        Files = @($manifestEntries.ToArray())
    })

    if (-not $SkipArchive) {
        try {
            $archive = New-AmdZipFromDirectory -SourceDirectory $ctx.EvidenceDirectory -DestinationZip $ctx.ZipPath
            if ($null -eq $archive -or $archive.Length -le 0) { throw 'Evidence archive is empty.' }
            $integrity = Test-AmdEvidenceZipIntegrity -Path $ctx.ZipPath
            if ($integrity.Status -ne 'Pass') { throw ('Evidence ZIP integrity verification failed: {0}' -f $integrity.Error) }
            $ctx.ZipSha256 = Write-AmdEvidenceSha256File -ZipPath $ctx.ZipPath -Sha256Path $ctx.ZipSha256Path
            $ctx.ArchiveCreated = $true
        }
        catch {
            $ctx.ArchiveCreated = $false
            $ctx.EvidenceDirectoryRetained = (Test-Path -LiteralPath $ctx.EvidenceDirectory -PathType Container)
            if ($ctx.EvidenceDirectoryRetained) { Write-AmdUtf8NoBom -Path (Join-Path $ctx.EvidenceDirectory 'archive-error.txt') -Text $_.Exception.ToString() }
            Write-Warning ('Evidence archive could not be created: {0}' -f $_.Exception.Message)
            Write-Warning ('Evidence directory remains available: {0}' -f $ctx.EvidenceDirectory)
        }
        if ($ctx.ArchiveCreated) {
            if ($ctx.EvidenceRetention -eq 'ZipOnly') {
                try { Remove-Item -LiteralPath $ctx.EvidenceDirectory -Recurse -Force -ErrorAction Stop; $ctx.EvidenceDirectoryRetained = $false }
                catch { $ctx.EvidenceDirectoryRetained = $true; Write-Warning ('Verified ZIP was retained, but the raw evidence directory could not be removed: {0}' -f $_.Exception.Message) }
            }
            try { Write-AmdLatestEvidencePointer -Context $ctx -Assessment $assessment }
            catch { Write-Warning ('Verified ZIP was retained, but LATEST-EVIDENCE.txt could not be updated: {0}' -f $_.Exception.Message) }
        }
    }

    Write-AmdEvidenceCompletionBanner -Context $ctx

    return $assessment
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

function Invoke-AmdEmergencyEvidenceFinalization {
    [CmdletBinding()]
    param([AllowNull()][object]$ErrorRecord,[switch]$SkipArchive)

    $ctx=$script:AmdEvidenceContext
    if($null -eq $ctx){return $null}
    if($script:AmdTranscriptStarted){try{Stop-Transcript|Out-Null}catch{};$script:AmdTranscriptStarted=$false}
    try{
        $errorsDirectory=Join-Path $ctx.EvidenceDirectory 'errors';[void][IO.Directory]::CreateDirectory($errorsDirectory)
        $errorText=if($null -ne $ErrorRecord){$ErrorRecord.ToString()}else{'Normal evidence finalization failed without an ErrorRecord.'}
        $content=@('AMD DRIVER RESEARCH EMERGENCY EVIDENCE FINALIZATION',('OccurredUtc : {0}' -f (Get-AmdUtcTimestamp)),('RunId       : {0}' -f $ctx.RunId),('Reason      : {0}' -f $errorText),'The normal evidence finalizer failed. This emergency archive preserves the raw evidence directory and is not a PASS qualification artifact.')-join[Environment]::NewLine
        [IO.File]::WriteAllText((Join-Path $errorsDirectory 'emergency-finalization.txt'),$content,(New-Object Text.UTF8Encoding($false)))
    }catch{Write-Warning ('Emergency finalization could not write its diagnostic file: {0}' -f $_.Exception.Message)}
    if($SkipArchive){return $null}
    try{
        $archive=New-AmdZipFromDirectory -SourceDirectory $ctx.EvidenceDirectory -DestinationZip $ctx.ZipPath
        if($null -eq $archive -or $archive.Length -le 0){throw 'Emergency evidence archive is empty.'}
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

    # AMD graphics public release identities are not chipset-style four-part
    # numbers. Adrenalin normally uses YY.M.P (26.7.1) while PRO Edition uses
    # YY.QN or YY.QN.P (26.Q1 / 25.Q3.1). Prefer tokens close to RN-RAD-WIN /
    # RN-PRO-WIN when available, then fall back to the final matching token.
    $pro = [regex]::Matches($Text, '(?i)(?<![0-9A-Z])(\d{2})[\.\-_](Q[1-4])(?:[\.\-_](\d+))?(?![0-9A-Z])')
    if ($pro.Count -gt 0) {
        $m = $pro[$pro.Count - 1]
        if ($m.Groups[3].Success) {
            return ('{0}.{1}.{2}' -f [int]$m.Groups[1].Value, $m.Groups[2].Value.ToUpperInvariant(), [int]$m.Groups[3].Value)
        }
        return ('{0}.{1}' -f [int]$m.Groups[1].Value, $m.Groups[2].Value.ToUpperInvariant())
    }

    $matches = [regex]::Matches($Text, '(?<!\d)(\d{2})[\.\-_](\d{1,2})[\.\-_](\d{1,3})(?!\d)')
    if ($matches.Count -eq 0) { return $null }
    $m = $matches[$matches.Count - 1]
    return ('{0}.{1}.{2}' -f [int]$m.Groups[1].Value, [int]$m.Groups[2].Value, [int]$m.Groups[3].Value)
}

function Get-AmdGraphicsReleaseClassification {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$Url,
        [string]$ReleaseVersion,
        [string]$PackageFamily,
        [string]$Branch
    )

    if (-not $ReleaseVersion) { $ReleaseVersion = Get-AmdVersionFromText -Text $Url }

    if (-not $PackageFamily) {
        if ($Url -match '(?i)RN-PRO-WIN-|amd[-_ ]software[-_ ]pro[-_ ]edition') { $PackageFamily = 'ProEdition' }
        elseif ($Url -match '(?i)RN-RAD-WIN-|amd[-_ ]software[-_ ]adrenalin[-_ ]edition|radeon[-_ ]software') { $PackageFamily = 'Adrenalin' }
        elseif ($Url -match '(?i)embedded.*(?:radeon|graphics)|(?:radeon|graphics).*embedded') { $PackageFamily = 'Embedded' }
        else { $PackageFamily = 'Unknown' }
    }

    if (-not $Branch) {
        if ($PackageFamily -eq 'ProEdition') {
            # PRO release notes can expose multiple sibling artifacts (RDNA,
            # Vega/Polaris and Server-specific Vega/Polaris) under one public
            # release identity. Keep Branch stable as MultiArtifact and carry
            # the artifact-specific distinction in ArtifactRole.
            $Branch = 'MultiArtifact'
        }
        elseif ($Url -match '(?i)(POLARIS[-_]VEGA|VEGA[-_]POLARIS)') {
            $Branch = 'PolarisVega'
        }
        elseif ($PackageFamily -eq 'Embedded') {
            $Branch = 'Unspecified'
        }
        elseif ($PackageFamily -eq 'Adrenalin') {
            $isSplitEra = $false
            if ($ReleaseVersion -match '^(\d+)\.(\d+)\.(\d+)$') {
                $yy=[int]$matches[1]; $mm=[int]$matches[2]; $pp=[int]$matches[3]
                if ($yy -gt 23 -or ($yy -eq 23 -and ($mm -gt 11 -or ($mm -eq 11 -and $pp -ge 1)))) { $isSplitEra = $true }
            }
            $Branch = if ($isSplitEra) { 'Main' } else { 'Unified' }
        }
        else { $Branch = 'Unknown' }
    }

    $releaseKey = ('{0}|{1}|{2}' -f $PackageFamily, $Branch, $ReleaseVersion)
    return [pscustomobject]@{
        ReleaseVersion = $ReleaseVersion
        PackageFamily = $PackageFamily
        Branch = $Branch
        ReleaseKey = $releaseKey
    }
}

function Get-AmdArtifactRoleFromFileName {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FileName,
        [AllowEmptyString()][string]$Branch
    )

    $role = 'Unspecified'
    if ($FileName -match '(?i)winsvr|server') { $role = 'WindowsServer' }
    if ($FileName -match '(?i)(vega[-_]?polaris|polaris[-_]?vega)') {
        return $(if ($role -eq 'WindowsServer') { 'WindowsServer-PolarisVega' } else { 'PolarisVega' })
    }
    # Keep AMD's explicit "RDNA Combined" artifact identity distinct from the
    # RDNA-only artifact published under the same public release version.
    if ($FileName -match '(?i)(rdna[-_]?combined|combined[-_]?rdna)') { return 'RDNACombined' }
    if ($FileName -match '(?i)rdna') { return 'RDNA' }
    if ($Branch -eq 'Main') { return 'Main' }
    if ($Branch -eq 'Unified') { return 'Unified' }
    if ($Branch -eq 'PolarisVega') { return 'PolarisVega' }
    return $role
}

function Get-AmdGraphicsDriverComponent {
    [CmdletBinding()]
    param([AllowEmptyString()][string]$RelativePath)

    $normalized = ($RelativePath -replace '\\', '/')
    $m = [regex]::Match($normalized, '(?i)(?:^|/)Packages/Drivers/([^/]+)(?:/([^/]+))?')
    if (-not $m.Success) {
        return [pscustomobject]@{ Category = 'Unknown'; Subcomponent = $null }
    }

    return [pscustomobject]@{
        Category = $m.Groups[1].Value
        Subcomponent = if ($m.Groups[2].Success) { $m.Groups[2].Value } else { $null }
    }
}

function Get-AmdReleaseSortKey {
    [CmdletBinding()]
    param([AllowEmptyString()][string]$ReleaseVersion)
    if (-not $ReleaseVersion) { return '0000.00.0000' }
    if ($ReleaseVersion -match '^(\d+)\.(\d+)\.(\d+)$') {
        return ('{0:D4}.{1:D2}.{2:D4}' -f [int]$matches[1], [int]$matches[2], [int]$matches[3])
    }
    if ($ReleaseVersion -match '^(\d+)\.Q([1-4])(?:\.(\d+))?$') {
        $minor = if ($matches[3]) { [int]$matches[3] } else { 0 }
        return ('{0:D4}.{1:D2}.{2:D4}' -f [int]$matches[1], ([int]$matches[2] * 3), $minor)
    }
    return ('0000.00.0000-{0}' -f $ReleaseVersion)
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


function Test-AmdTransientProductPageStatusCode {
    [CmdletBinding()]
    param([AllowNull()][object]$StatusCode)

    if ($null -eq $StatusCode) { return $true }
    try { $code = [int]$StatusCode } catch { return $true }
    return ($code -in @(403,408,425,429,500,502,503,504))
}

function Wait-AmdProductPageRequestPacing {
    [CmdletBinding()]
    param([int]$MinimumDelayMilliseconds = 350)

    if ($MinimumDelayMilliseconds -le 0) {
        $script:AmdLastProductPageRequestUtc = [DateTime]::UtcNow
        return
    }

    if ($null -ne $script:AmdLastProductPageRequestUtc) {
        $elapsed = [DateTime]::UtcNow - [DateTime]$script:AmdLastProductPageRequestUtc
        $remaining = $MinimumDelayMilliseconds - [int][Math]::Floor($elapsed.TotalMilliseconds)
        if ($remaining -gt 0) {
            Start-Sleep -Milliseconds $remaining
        }
    }
    $script:AmdLastProductPageRequestUtc = [DateTime]::UtcNow
}

function Test-AmdShouldFetchPreviousProductPage {
    [CmdletBinding()]
    param(
        [AllowNull()][object]$Catalog,
        [AllowNull()][object]$Product,
        [AllowNull()][object]$Summary,
        [int]$CurrentEntryCount = 0
    )

    if ($Catalog -and $Catalog.PSObject.Properties['CatalogKind'] -and [string]$Catalog.CatalogKind -eq 'CuratedProductGroups') {
        return $true
    }
    if ($Product -and $Product.PSObject.Properties['RootCategory'] -and [string]$Product.RootCategory -eq 'graphics') {
        return $true
    }
    if ($CurrentEntryCount -gt 0) {
        return $true
    }
    if ($Summary -and $Summary.PSObject.Properties['ProductOrigin'] -and [string]$Summary.ProductOrigin -eq 'ProcessorIntegratedGraphics') {
        return $true
    }
    return $false
}

function Invoke-AmdResilientProductPageRequest {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$Uri,
        [string[]]$AlternateUri = @(),
        [ValidateRange(1,5)][int]$RetryCount = 3,
        [ValidateRange(0,5000)][int]$RequestDelayMilliseconds = 350,
        [string]$Referer = 'https://www.amd.com/en/support/download/drivers.html'
    )

    $candidates = New-Object System.Collections.Generic.List[string]
    foreach ($candidate in @($Uri) + @($AlternateUri)) {
        if ([string]::IsNullOrWhiteSpace([string]$candidate)) { continue }
        if (-not (@($candidates.ToArray()) -contains [string]$candidate)) {
            $candidates.Add([string]$candidate)
        }
    }

    $attempts = New-Object System.Collections.Generic.List[object]
    $lastError = $null
    $candidateOrdinal = 0
    foreach ($candidate in $candidates.ToArray()) {
        $candidateOrdinal++
        $candidateKind = if ($candidateOrdinal -eq 1) { 'Primary' } else { 'Alternate' }
        for ($attempt = 1; $attempt -le $RetryCount; $attempt++) {
            Wait-AmdProductPageRequestPacing -MinimumDelayMilliseconds $RequestDelayMilliseconds
            $result = Invoke-AmdQuietTextRequest -Uri $candidate -Referer $Referer
            $attempts.Add([pscustomobject][ordered]@{
                Uri = $candidate
                CandidateKind = $candidateKind
                AttemptNumber = $attempt
                Success = [bool]$result.Success
                StatusCode = $result.StatusCode
                ResponseUri = $result.ResponseUri
                Error = $result.Error
            })

            if ($result.Success) {
                $recovered = ($candidateOrdinal -gt 1 -or $attempt -gt 1)
                return [pscustomobject][ordered]@{
                    Success = $true
                    Content = [string]$result.Content
                    RequestedUri = $Uri
                    EffectiveUri = if ($result.ResponseUri) { [string]$result.ResponseUri } else { $candidate }
                    CandidateKind = $candidateKind
                    FetchStatus = if ($candidateOrdinal -gt 1) { 'FallbackFetched' } elseif ($attempt -gt 1) { 'RetriedFetched' } else { 'Fetched' }
                    Recovered = $recovered
                    AttemptCount = $attempts.Count
                    Attempts = @($attempts.ToArray())
                    Error = $null
                }
            }

            $lastError = [string]$result.Error
            $isTransient = Test-AmdTransientProductPageStatusCode -StatusCode $result.StatusCode
            if (-not $isTransient) { break }
            if ($attempt -lt $RetryCount) {
                $backoffSeconds = if ($attempt -eq 1) { 2 } elseif ($attempt -eq 2) { 5 } else { 10 }
                Start-Sleep -Seconds $backoffSeconds
            }
        }
    }

    return [pscustomobject][ordered]@{
        Success = $false
        Content = $null
        RequestedUri = $Uri
        EffectiveUri = $null
        CandidateKind = $null
        FetchStatus = 'FetchFailed'
        Recovered = $false
        AttemptCount = $attempts.Count
        Attempts = @($attempts.ToArray())
        Error = $lastError
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

function Get-AmdInfStringTable {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string[]]$Lines
    )

    $result = @{}
    $inStrings = $false

    foreach ($line in $Lines) {
        $trimmed = $line.Trim()
        if ($trimmed -match '^\s*\[(.+?)\]\s*$') {
            $section = $Matches[1]
            $inStrings = ($section -match '(?i)^Strings(?:\..+)?$')
            continue
        }
        if (-not $inStrings) { continue }

        $clean = ($line -split ';', 2)[0].Trim()
        if (-not $clean) { continue }
        $m = [regex]::Match($clean, '^\s*([^=]+?)\s*=\s*(.*?)\s*$')
        if (-not $m.Success) { continue }
        $name = $m.Groups[1].Value.Trim()
        $value = $m.Groups[2].Value.Trim().Trim('"')
        if ($name) { $result[$name.ToLowerInvariant()] = $value }
    }

    return $result
}

function Resolve-AmdInfStringValue {
    [CmdletBinding()]
    param(
        [AllowEmptyString()][string]$Value,
        [Parameter(Mandatory = $true)][hashtable]$StringTable
    )

    if ($null -eq $Value) {
        return [pscustomobject]@{ RawValue = $null; ResolvedValue = $null; Status = 'Null'; UnresolvedTokens = @() }
    }

    $resolved = [string]$Value
    $unresolved = New-Object System.Collections.Generic.List[string]
    for ($iteration = 0; $iteration -lt 8; $iteration++) {
        $changed = $false
        $matches = @([regex]::Matches($resolved, '%([^%]+)%'))
        if ($matches.Count -eq 0) { break }
        foreach ($m in $matches) {
            $token = $m.Groups[1].Value
            $key = $token.ToLowerInvariant()
            if ($StringTable.ContainsKey($key)) {
                $resolved = $resolved.Replace($m.Value, [string]$StringTable[$key])
                $changed = $true
            }
            elseif (-not $unresolved.Contains($token)) {
                $unresolved.Add($token)
            }
        }
        if (-not $changed) { break }
    }

    $remaining = @([regex]::Matches($resolved, '%([^%]+)%') | ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique)
    foreach ($token in $remaining) {
        if (-not $unresolved.Contains($token)) { $unresolved.Add($token) }
    }

    $status = if ($unresolved.Count -gt 0) { 'PartiallyResolved' }
              elseif ($resolved -ne [string]$Value) { 'Resolved' }
              else { 'Literal' }

    return [pscustomobject]@{
        RawValue = [string]$Value
        ResolvedValue = $resolved
        Status = $status
        UnresolvedTokens = $unresolved.ToArray()
    }
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



function Get-AmdWindowsServerTargetProfiles {
    [CmdletBinding()]
    param()

    # Canonical initial analysis scope is member/server ProductType=3. Domain
    # Controller (ProductType=2) is intentionally a future separate profile.
    # Canonical field names align with the shared AMD INF semantic contract;
    # legacy 0.4.x aliases remain available for compatibility.
    return @(
        [pscustomobject][ordered]@{
            ProfileId='windows-server-2016'; Id='windows-server-2016'; Name='Windows Server 2016'; ShortName='WS2016'; Architecture='amd64'
            OSMajorVersion=10; OSMinorVersion=0; BuildNumber=14393; ProductType=3; SuiteMask=$null
            DocumentedKMDF='1.19'; ObservedKMDF=$null; DocumentedUMDF='2.19'; ObservedUMDF=$null; WdfConfidence='PublishedReference'
            OSMajor=10; OSMinor=0; Build=14393
            Kmdf=[pscustomobject]@{ Documented='1.19'; Observed=$null }; Umdf=[pscustomobject]@{ Documented='2.19'; Observed=$null }
        },
        [pscustomobject][ordered]@{
            ProfileId='windows-server-2019'; Id='windows-server-2019'; Name='Windows Server 2019'; ShortName='WS2019'; Architecture='amd64'
            OSMajorVersion=10; OSMinorVersion=0; BuildNumber=17763; ProductType=3; SuiteMask=$null
            DocumentedKMDF='1.27'; ObservedKMDF='1.27'; DocumentedUMDF='2.27'; ObservedUMDF=$null; WdfConfidence='IncludedVersion+Observed'
            OSMajor=10; OSMinor=0; Build=17763
            Kmdf=[pscustomobject]@{ Documented='1.27'; Observed='1.27' }; Umdf=[pscustomobject]@{ Documented='2.27'; Observed=$null }
        },
        [pscustomobject][ordered]@{
            ProfileId='windows-server-2022'; Id='windows-server-2022'; Name='Windows Server 2022'; ShortName='WS2022'; Architecture='amd64'
            OSMajorVersion=10; OSMinorVersion=0; BuildNumber=20348; ProductType=3; SuiteMask=$null
            DocumentedKMDF='1.33'; ObservedKMDF=$null; DocumentedUMDF='2.33'; ObservedUMDF=$null; WdfConfidence='IncludedVersion'
            OSMajor=10; OSMinor=0; Build=20348
            Kmdf=[pscustomobject]@{ Documented='1.33'; Observed=$null }; Umdf=[pscustomobject]@{ Documented='2.33'; Observed=$null }
        },
        [pscustomobject][ordered]@{
            ProfileId='windows-server-2025'; Id='windows-server-2025'; Name='Windows Server 2025'; ShortName='WS2025'; Architecture='amd64'
            OSMajorVersion=10; OSMinorVersion=0; BuildNumber=26100; ProductType=3; SuiteMask=$null
            DocumentedKMDF='1.33'; ObservedKMDF='1.35'; DocumentedUMDF='2.33'; ObservedUMDF=$null; WdfConfidence='PublishedReference+ObservedKMDF'
            OSMajor=10; OSMinor=0; Build=26100
            Kmdf=[pscustomobject]@{ Documented='1.33'; Observed='1.35' }; Umdf=[pscustomobject]@{ Documented='2.33'; Observed=$null }
        }
    )
}

function Get-AmdInfSectionMap {
    [CmdletBinding()]
    param([Parameter(Mandatory=$true)][AllowEmptyString()][string[]]$Lines)

    $sections = @{}
    $current = $null
    for ($i = 0; $i -lt $Lines.Count; $i++) {
        $line = [string]$Lines[$i]
        $trimmed = $line.Trim()
        $m = [regex]::Match($trimmed, '^\[(.+?)\]$')
        if ($m.Success) {
            $current = $m.Groups[1].Value.Trim()
            if (-not $sections.ContainsKey($current)) {
                $sections[$current] = New-Object System.Collections.Generic.List[object]
            }
            continue
        }
        if (-not $current) { continue }
        $clean = ($line -split ';', 2)[0].Trim()
        $sections[$current].Add([pscustomobject]@{ LineNumber=$i+1; RawLine=$line; CleanLine=$clean })
    }
    return $sections
}

function Split-AmdInfCsv {
    [CmdletBinding()]
    param([AllowEmptyString()][string]$Text)

    $parts = New-Object System.Collections.Generic.List[string]
    if ($null -eq $Text) { return @() }
    $buffer = New-Object System.Text.StringBuilder
    $quoted = $false
    for ($i=0; $i -lt $Text.Length; $i++) {
        $c = $Text[$i]
        if ($c -eq '"') { $quoted = -not $quoted; [void]$buffer.Append($c); continue }
        if ($c -eq ',' -and -not $quoted) {
            $parts.Add($buffer.ToString().Trim())
            [void]$buffer.Clear()
            continue
        }
        [void]$buffer.Append($c)
    }
    $parts.Add($buffer.ToString().Trim())
    return $parts.ToArray()
}

function ConvertTo-AmdInfInteger {
    [CmdletBinding()]
    param([AllowEmptyString()][string]$Value)
    if ([string]::IsNullOrWhiteSpace($Value)) { return $null }
    $v = $Value.Trim()
    $n = 0
    if ($v -match '^(?i)0x[0-9a-f]+$') {
        try { return [Convert]::ToInt32($v.Substring(2),16) } catch { return $null }
    }
    if ([int]::TryParse($v, [ref]$n)) { return $n }
    return $null
}

function ConvertFrom-AmdInfTargetOsDecoration {
    [CmdletBinding()]
    param([AllowEmptyString()][string]$Decoration)

    if ([string]::IsNullOrWhiteSpace($Decoration)) {
        return [pscustomobject][ordered]@{
            Raw=$null; ParseStatus='Undecorated'; Architecture=$null
            OSMajorVersion=$null; OSMinorVersion=$null; ProductType=$null; ProductTypeName=$null; SuiteMaskRaw=$null; SuiteMask=$null; BuildNumber=$null
            OSMajor=$null; OSMinor=$null
        }
    }

    $raw = $Decoration.Trim()
    if ($raw -notmatch '^(?i)NT') {
        return [pscustomobject][ordered]@{
            Raw=$raw; ParseStatus='Unrecognized'; Architecture=$null
            OSMajorVersion=$null; OSMinorVersion=$null; ProductType=$null; ProductTypeName=$null; SuiteMaskRaw=$null; SuiteMask=$null; BuildNumber=$null
            OSMajor=$null; OSMinor=$null
        }
    }

    $parts = $raw.Split([char]'.')
    $head = $parts[0]
    $architecture = if ($head.Length -gt 2) { $head.Substring(2).ToLowerInvariant() } else { $null }
    $major = if ($parts.Length -gt 1) { ConvertTo-AmdInfInteger -Value $parts[1] } else { $null }
    $minor = if ($parts.Length -gt 2) { ConvertTo-AmdInfInteger -Value $parts[2] } else { $null }
    $productType = if ($parts.Length -gt 3) { ConvertTo-AmdInfInteger -Value $parts[3] } else { $null }
    $suiteRaw = if ($parts.Length -gt 4 -and -not [string]::IsNullOrWhiteSpace($parts[4])) { [string]$parts[4] } else { $null }
    $suite = ConvertTo-AmdInfInteger -Value $suiteRaw
    $build = if ($parts.Length -gt 5) { ConvertTo-AmdInfInteger -Value $parts[5] } else { $null }
    $productName = switch ($productType) { 1 {'Workstation'} 2 {'DomainController'} 3 {'Server'} default {$null} }

    return [pscustomobject][ordered]@{
        Raw=$raw; ParseStatus='Parsed'; Architecture=$architecture
        OSMajorVersion=$major; OSMinorVersion=$minor; ProductType=$productType; ProductTypeName=$productName; SuiteMaskRaw=$suiteRaw; SuiteMask=$suite; BuildNumber=$build
        # Legacy aliases retained for 0.4.x consumers.
        OSMajor=$major; OSMinor=$minor
    }
}

function Get-AmdInfIdentifierInfo {
    [CmdletBinding()]
    param(
        [AllowNull()][string]$Identifier,
        [AllowNull()][string]$InfClass
    )

    $raw = if ($null -eq $Identifier) { '' } else { $Identifier.Trim() }
    $className = if ($null -eq $InfClass) { '' } else { $InfClass.Trim() }
    $upper = $raw.ToUpperInvariant()
    $kind='UnclassifiedIdentifier'; $display='Unclassified identifier'; $enumerator=$null
    $isPnpHardwareId=$false; $isSoftwareComponentId=$false
    $notes=New-Object System.Collections.Generic.List[string]

    if (-not $raw) {
        $kind='MissingIdentifier'; $display='No device identifier declared'; $notes.Add('Models entry did not provide a non-empty identifier.')
    }
    elseif ($upper -match '^ROOT\\') {
        $kind='RootEnumeratedHardwareId'; $display='Root-enumerated PnP hardware ID'; $enumerator='ROOT'; $isPnpHardwareId=$true
    }
    elseif ($raw -match '^\{[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}\}\\.+$') {
        $kind='DeviceClassSpecificId'; $display='Device-class-specific ID'; $isPnpHardwareId=$true
        $notes.Add('The INF uses the device-class-specific hardware-ID form rather than a bus-enumerator ID such as PCI\\VEN_....')
    }
    elseif ($upper -match '^\*') {
        $kind='GenericHardwareId'; $display='Generic PnP hardware ID'; $isPnpHardwareId=$true
    }
    elseif ($raw -match '^([^\\]+)\\.+$') {
        $enumerator=$matches[1].ToUpperInvariant(); $kind='EnumeratorHardwareId'; $display=('{0}-enumerated PnP hardware ID' -f $enumerator); $isPnpHardwareId=$true
    }
    elseif ($className -in @('NetService','NetTrans','NetClient')) {
        $kind='NetworkSoftwareComponentId'; $display='Network software component ID'; $isSoftwareComponentId=$true
        $notes.Add('Network software components use a component ID in the Models-section identifier field; this is not a PCI/ACPI/USB bus hardware ID.')
    }
    elseif ($className -eq 'Net') {
        $kind='NetworkComponentOrSoftwareId'; $display='Network component identifier'; $isSoftwareComponentId=$true
        $notes.Add('The identifier is declared by a Net-class Models entry but does not use a bus-enumerator form; preserve it as an INF component identifier.')
    }
    else {
        $kind='InfModelIdentifier'; $display='INF Models identifier'
        $notes.Add('The value is a source INF Models identifier whose namespace was not classified as a known bus/root/class-specific form.')
    }

    return [pscustomobject][ordered]@{
        Raw=$raw; Kind=$kind; DisplayName=$display; Enumerator=$enumerator
        IsPnpHardwareId=$isPnpHardwareId; IsSoftwareComponentId=$isSoftwareComponentId; Notes=@($notes.ToArray())
    }
}

function Get-AmdInfModelsSectionDetail {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][hashtable]$Sections,
        [Parameter(Mandatory=$true)][string]$SectionName,
        [Parameter(Mandatory=$true)][hashtable]$StringTable,
        [AllowNull()][string]$InfClass
    )

    if (-not $Sections.ContainsKey($SectionName)) {
        return [pscustomobject][ordered]@{ SectionName=$SectionName; Exists=$false; IsEmpty=$null; ModelCount=0; Models=@(); HardwareIds=@() }
    }

    $models = New-Object System.Collections.Generic.List[object]
    $ids = New-Object System.Collections.Generic.List[string]
    foreach ($row in $Sections[$SectionName].ToArray()) {
        if (-not $row.CleanLine) { continue }
        $m = [regex]::Match([string]$row.CleanLine, '^\s*([^=]+?)\s*=\s*(.*?)\s*$')
        if (-not $m.Success) { continue }
        $descriptionRaw = $m.Groups[1].Value.Trim()
        $fields = @(Split-AmdInfCsv -Text $m.Groups[2].Value)
        if ($fields.Count -lt 1) { continue }
        $installRaw = $fields[0].Trim().Trim('"')
        $hardwareId = if ($fields.Count -gt 1) { $fields[1].Trim().Trim('"') } else { $null }
        $compatible = @()
        if ($fields.Count -gt 2) { $compatible = @($fields[2..($fields.Count-1)] | ForEach-Object { $_.Trim().Trim('"') } | Where-Object { $_ }) }
        $description = (Resolve-AmdInfStringValue -Value $descriptionRaw -StringTable $StringTable).ResolvedValue
        $install = (Resolve-AmdInfStringValue -Value $installRaw -StringTable $StringTable).ResolvedValue

        # Every non-empty Models identifier is source evidence. Do not filter to a
        # fixed set of bus prefixes; Windows INF Models identifiers can use other
        # enumerators, class-specific forms, generic IDs, and software components.
        if ($hardwareId -and -not $ids.Contains($hardwareId)) { $ids.Add($hardwareId) }

        $models.Add([pscustomobject][ordered]@{
            LineNumber=$row.LineNumber; RawLine=$row.RawLine
            DescriptionRaw=$descriptionRaw; Description=$description
            InstallSectionRaw=$installRaw; InstallSection=$install
            HardwareId=$hardwareId
            Identifier=(Get-AmdInfIdentifierInfo -Identifier $hardwareId -InfClass $InfClass)
            CompatibleIds=@($compatible)
            CompatibleIdentifiers=@($compatible | ForEach-Object { Get-AmdInfIdentifierInfo -Identifier ([string]$_) -InfClass $InfClass })
            RawFields=@($fields)
        })
    }

    return [pscustomobject][ordered]@{
        SectionName=$SectionName; Exists=$true; IsEmpty=($models.Count -eq 0); ModelCount=$models.Count
        Models=$models.ToArray(); HardwareIds=@($ids.ToArray() | Sort-Object -Unique)
    }
}

function Get-AmdInfManufacturerTargeting {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][AllowEmptyString()][string[]]$Lines,
        [Parameter(Mandatory=$true)][hashtable]$StringTable
    )

    $sections = Get-AmdInfSectionMap -Lines $Lines
    $infClass = $null
    if ($sections.ContainsKey('Version')) {
        foreach ($versionRow in $sections['Version']) {
            if ([string]$versionRow.CleanLine -match '^(?i)\s*Class\s*=\s*(.+?)\s*$') {
                $infClass = (Resolve-AmdInfStringValue -Value $matches[1].Trim().Trim('"') -StringTable $StringTable).ResolvedValue
                break
            }
        }
    }
    $entries = New-Object System.Collections.Generic.List[object]
    $manufacturerGroups = New-Object System.Collections.Generic.List[object]
    $modelSectionIndex = @{}
    if (-not $sections.ContainsKey('Manufacturer')) {
        return [pscustomobject][ordered]@{ Status='ManufacturerSectionMissing'; EntryCount=0; Entries=@(); ManufacturerEntries=@(); ModelsSections=@() }
    }

    foreach ($row in $sections['Manufacturer']) {
        if (-not $row.CleanLine) { continue }
        $m = [regex]::Match([string]$row.CleanLine, '^\s*([^=]+?)\s*=\s*(.+?)\s*$')
        if (-not $m.Success) { continue }
        $manufacturerToken = $m.Groups[1].Value.Trim()
        $resolvedManufacturer = (Resolve-AmdInfStringValue -Value $manufacturerToken -StringTable $StringTable).ResolvedValue
        $tokens = @(Split-AmdInfCsv -Text $m.Groups[2].Value)
        if ($tokens.Count -lt 1 -or -not $tokens[0]) { continue }
        $modelsBase = $tokens[0].Trim()
        $decorations = @()
        if ($tokens.Count -gt 1) { $decorations = @($tokens[1..($tokens.Count-1)] | ForEach-Object { $_.Trim() } | Where-Object { $_ }) }
        if ($decorations.Count -eq 0) { $decorations = @($null) }

        $groupDecorations = New-Object System.Collections.Generic.List[object]
        foreach ($dec in $decorations) {
            $parsed = ConvertFrom-AmdInfTargetOsDecoration -Decoration $dec
            $sectionName = if ($dec) { '{0}.{1}' -f $modelsBase, $dec } else { $modelsBase }
            $detail = Get-AmdInfModelsSectionDetail -Sections $sections -SectionName $sectionName -StringTable $StringTable -InfClass $infClass
            if (-not $modelSectionIndex.ContainsKey($sectionName)) { $modelSectionIndex[$sectionName] = $detail }
            $entry = [pscustomobject][ordered]@{
                ManufacturerToken=$manufacturerToken; Manufacturer=$resolvedManufacturer; ManufacturerLineNumber=$row.LineNumber
                ModelsBaseSection=$modelsBase; TargetOSVersion=$parsed; ModelsSection=$sectionName
                ModelsSectionExists=[bool]$detail.Exists; ModelsSectionIsEmpty=$detail.IsEmpty
                ModelsSectionModelCount=$detail.ModelCount; ModelsSectionHardwareIdCount=@(Get-AmdCollectionItems -Value $detail.HardwareIds).Count
                Models=@(Get-AmdCollectionItems -Value $detail.Models); HardwareIds=@(Get-AmdCollectionItems -Value $detail.HardwareIds)
            }
            $entries.Add($entry)
            $groupDecorations.Add([pscustomobject][ordered]@{
                Raw=$parsed.Raw; TargetOSVersion=$parsed; ModelsSection=$sectionName; Exists=$detail.Exists; IsEmpty=$detail.IsEmpty
                ModelCount=$detail.ModelCount; HardwareIdCount=@(Get-AmdCollectionItems -Value $detail.HardwareIds).Count
            })
        }
        $manufacturerGroups.Add([pscustomobject][ordered]@{
            ManufacturerToken=$manufacturerToken; Manufacturer=$resolvedManufacturer; LineNumber=$row.LineNumber
            ModelsBaseSection=$modelsBase; Decorations=$groupDecorations.ToArray()
        })
    }

    return [pscustomobject][ordered]@{
        Status=if ($entries.Count -gt 0) { 'Parsed' } else { 'NoTargetEntries' }
        EntryCount=$entries.Count; Entries=$entries.ToArray(); ManufacturerEntries=$manufacturerGroups.ToArray()
        ModelsSections=@($modelSectionIndex.Values | Sort-Object SectionName)
    }
}

function Get-AmdInfTopology {
    [CmdletBinding()]
    param([Parameter(Mandatory=$true)][object]$ManufacturerTargeting)
    $allIds = @($ManufacturerTargeting.ModelsSections | ForEach-Object { @(Get-AmdCollectionItems -Value $_.HardwareIds) } | Sort-Object -Unique)
    return [pscustomobject][ordered]@{
        SchemaVersion=$script:AmdInfTopologySchemaVersion
        SharedContractVersion=$script:AmdInfSemanticContractVersion
        IdentifierTaxonomyVersion=$script:AmdInfIdentifierTaxonomyVersion
        Status=$ManufacturerTargeting.Status
        ManufacturerEntries=@($ManufacturerTargeting.ManufacturerEntries)
        TargetEntries=@($ManufacturerTargeting.Entries)
        ModelsSections=@(Get-AmdCollectionItems -Value $ManufacturerTargeting.ModelsSections)
        TopologyHardwareIds=@($allIds)
        ParseWarnings=@()
    }
}

function Test-AmdInfTargetEntryForWindowsServer {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][object]$Entry,
        [Parameter(Mandatory=$true)][object]$ServerTarget,
        [switch]$ProjectWorkstationToServer
    )

    $reasons = New-Object System.Collections.Generic.List[string]
    $dec = $Entry.TargetOSVersion
    $projected = $false
    if (-not $Entry.ModelsSectionExists) {
        return [pscustomobject]@{ Status='Indeterminate'; ReasonCode='ModelsSectionMissing'; ProjectionApplied=$false; Reasons=@('ModelsSectionMissing') }
    }
    if ($dec.ParseStatus -eq 'Unrecognized') {
        return [pscustomobject]@{ Status='Indeterminate'; ReasonCode='TargetOSVersionUnrecognized'; ProjectionApplied=$false; Reasons=@('TargetOSVersionUnrecognized') }
    }
    if ($dec.Architecture -and $dec.Architecture -notin @('amd64')) {
        return [pscustomobject]@{ Status='NotApplicable'; ReasonCode='ArchitectureMismatch'; ProjectionApplied=$false; Reasons=@('ArchitectureMismatch') }
    }
    if ($null -ne $dec.OSMajor) {
        $targetVersionValue = ([int]$ServerTarget.OSMajor * 1000) + [int]$ServerTarget.OSMinor
        $decMinor = if ($null -ne $dec.OSMinor) { [int]$dec.OSMinor } else { 0 }
        $decVersionValue = ([int]$dec.OSMajor * 1000) + $decMinor
        if ($targetVersionValue -lt $decVersionValue) {
            return [pscustomobject]@{ Status='NotApplicable'; ReasonCode='OSVersionBelowTarget'; ProjectionApplied=$false; Reasons=@('OSVersionBelowTarget') }
        }
        if ($targetVersionValue -eq $decVersionValue -and $null -ne $dec.BuildNumber -and [int]$ServerTarget.Build -lt [int]$dec.BuildNumber) {
            return [pscustomobject]@{ Status='NotApplicable'; ReasonCode='BuildBelowTarget'; ProjectionApplied=$false; Reasons=@('BuildBelowTarget') }
        }
    }
    if ($null -ne $dec.ProductType) {
        if ([int]$dec.ProductType -eq 1 -and $ProjectWorkstationToServer) {
            $projected = $true; $reasons.Add('ProductType1VirtuallyMirroredTo3')
        }
        elseif ([int]$dec.ProductType -ne [int]$ServerTarget.ProductType) {
            return [pscustomobject]@{ Status='NotApplicable'; ReasonCode='ProductTypeMismatch'; ProjectionApplied=$false; Reasons=@('ProductTypeMismatch') }
        }
    }
    if ($null -ne $dec.SuiteMask -and [int]$dec.SuiteMask -ne 0) {
        $reasons.Add('SuiteMaskRestrictionRequiresEditionEvaluation')
        return [pscustomobject]@{ Status='Conditional'; ReasonCode='SuiteDependent'; ProjectionApplied=$projected; Reasons=$reasons.ToArray() }
    }
    if ($Entry.ModelsSectionIsEmpty -eq $true) {
        $reasons.Add('SelectedModelsSectionIsEmpty')
        return [pscustomobject]@{ Status='ExplicitlyExcluded'; ReasonCode='ExplicitlyExcluded'; ProjectionApplied=$projected; Reasons=$reasons.ToArray() }
    }
    if ([int]$Entry.ModelsSectionModelCount -le 0) {
        return [pscustomobject]@{ Status='NoMatchingModel'; ReasonCode='NoMatchingModel'; ProjectionApplied=$projected; Reasons=@('NoModelEntries') }
    }
    $reasons.Add('TargetOSVersionEligible')
    return [pscustomobject]@{ Status='Applicable'; ReasonCode=if($projected){'ApplicableAfterProductTypeMirror'}else{'NativeApplicable'}; ProjectionApplied=$projected; Reasons=$reasons.ToArray() }
}

function Get-AmdInfTargetSpecificityScore {
    [CmdletBinding()]
    param([Parameter(Mandatory=$true)][object]$Entry)
    $d=$Entry.TargetOSVersion
    $score=0L
    if ($null -ne $d.OSMajor) { $score += 1000000000000 }
    if ($null -ne $d.OSMinor) { $score += 100000000000 }
    # Build-specific OS targeting is treated as more specific than product/suite
    # targeting within the same major/minor family.
    if ($null -ne $d.BuildNumber) { $score += 1000000000 + [int64]$d.BuildNumber }
    if ($null -ne $d.ProductType) { $score += 10000000 }
    if ($null -ne $d.SuiteMask -and [int]$d.SuiteMask -ne 0) { $score += 1000000 }
    return $score
}

function Get-AmdInfApplicabilityForServerProfile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][object]$InfTopology,
        [Parameter(Mandatory=$true)][object]$ServerTarget,
        [switch]$ProjectWorkstationToServer
    )

    if (-not $InfTopology -or $InfTopology.Status -ne 'Parsed') {
        return [pscustomobject][ordered]@{ Status='Indeterminate'; SelectedModelsSections=@(); SelectedModelCount=0; SelectedHardwareIds=@(); ProjectionApplied=$false; SelectionEvidence=@(); Reasons=@('InfTopologyUnavailable') }
    }

    $selectionEvidence = New-Object System.Collections.Generic.List[object]
    $selectedEntries = New-Object System.Collections.Generic.List[object]
    $groups = @($InfTopology.TargetEntries | Group-Object { '{0}|{1}|{2}' -f $_.ManufacturerLineNumber,$_.Manufacturer,$_.ModelsBaseSection })
    $reasonBag = New-Object System.Collections.Generic.List[string]
    foreach ($g in $groups) {
        $eligible = New-Object System.Collections.Generic.List[object]
        foreach ($entry in @($g.Group)) {
            $matchArgs=@{Entry=$entry;ServerTarget=$ServerTarget}
            if ($ProjectWorkstationToServer) { $matchArgs['ProjectWorkstationToServer']=$true }
            $match=Test-AmdInfTargetEntryForWindowsServer @matchArgs
            $score=Get-AmdInfTargetSpecificityScore -Entry $entry
            $ev=[pscustomobject][ordered]@{
                ModelsBaseSection=$entry.ModelsBaseSection; ModelsSection=$entry.ModelsSection; TargetOSVersion=$entry.TargetOSVersion.Raw
                MatchStatus=$match.Status; ReasonCode=$match.ReasonCode; ProjectionApplied=$match.ProjectionApplied; SpecificityScore=$score
                IsEmpty=$entry.ModelsSectionIsEmpty; ModelCount=$entry.ModelsSectionModelCount; HardwareIdCount=$entry.ModelsSectionHardwareIdCount
                Reasons=@($match.Reasons)
            }
            $selectionEvidence.Add($ev)
            if ($match.Status -in @('Applicable','Conditional','ExplicitlyExcluded','NoMatchingModel')) {
                $eligible.Add([pscustomobject]@{Entry=$entry;Match=$match;Score=$score})
            } else {
                if ($match.ReasonCode -and -not $reasonBag.Contains([string]$match.ReasonCode)) { $reasonBag.Add([string]$match.ReasonCode) }
            }
        }
        if ($eligible.Count -gt 0) {
            $max = @($eligible.ToArray() | Measure-Object -Property Score -Maximum)[0].Maximum
            foreach ($item in @($eligible.ToArray() | Where-Object { $_.Score -eq $max })) { $selectedEntries.Add($item) }
        }
    }

    if ($selectedEntries.Count -eq 0) {
        $status='Indeterminate'
        if ($reasonBag.Contains('BuildBelowTarget')) { $status='NotApplicableByBuild' }
        elseif ($reasonBag.Contains('ProductTypeMismatch')) { $status='NotApplicableByProductType' }
        elseif ($reasonBag.Contains('ArchitectureMismatch') -or $reasonBag.Contains('OSVersionBelowTarget')) { $status='NotApplicableByOsTarget' }
        return [pscustomobject][ordered]@{ Status=$status; SelectedModelsSections=@(); SelectedModelCount=0; SelectedHardwareIds=@(); ProjectionApplied=$false; SelectionEvidence=$selectionEvidence.ToArray(); Reasons=$reasonBag.ToArray() }
    }

    $conditional=@($selectedEntries.ToArray()|Where-Object{$_.Match.Status -eq 'Conditional'})
    $excluded=@($selectedEntries.ToArray()|Where-Object{$_.Match.Status -eq 'ExplicitlyExcluded'})
    $applicable=@($selectedEntries.ToArray()|Where-Object{$_.Match.Status -eq 'Applicable'})
    $noModel=@($selectedEntries.ToArray()|Where-Object{$_.Match.Status -eq 'NoMatchingModel'})
    $proj=@($selectedEntries.ToArray()|Where-Object{$_.Match.ProjectionApplied}).Count -gt 0
    $selectedModels=@($selectedEntries.ToArray()|ForEach-Object{@($_.Entry.Models)} )
    $ids=@($selectedModels|ForEach-Object{$_.HardwareId}|Where-Object{$_}|Sort-Object -Unique)
    $sections=@($selectedEntries.ToArray()|ForEach-Object{$_.Entry.ModelsSection}|Sort-Object -Unique)
    $status = if ($conditional.Count -gt 0) {'SuiteDependent'}
              elseif ($excluded.Count -gt 0 -and $applicable.Count -eq 0) {'ExplicitlyExcluded'}
              elseif ($noModel.Count -gt 0 -and $applicable.Count -eq 0) {'NoMatchingModel'}
              elseif ($applicable.Count -gt 0 -and $proj) {'ProjectionCandidate'}
              elseif ($applicable.Count -gt 0) {'NativeApplicable'}
              else {'Indeterminate'}
    return [pscustomobject][ordered]@{
        Status=$status; SelectedModelsSections=$sections; SelectedModelCount=$selectedModels.Count; SelectedHardwareIds=$ids
        ProjectionApplied=$proj; SelectionEvidence=$selectionEvidence.ToArray(); Reasons=@()
    }
}

function Compare-AmdWdfVersionToReference {
    [CmdletBinding()]
    param(
        [string[]]$DeclaredVersions,
        [AllowEmptyString()][string]$DocumentedReference,
        [AllowEmptyString()][string]$ObservedReference,
        [Parameter(Mandatory=$true)][string]$Framework
    )

    $values=@($DeclaredVersions|Where-Object{$_}|Sort-Object -Unique)
    if ($values.Count -eq 0) { return [pscustomobject][ordered]@{Framework=$Framework;Status='NotDeclared';DeclaredVersions=@();HighestDeclared=$null;DocumentedReference=$DocumentedReference;ObservedReference=$ObservedReference;DocumentedStatus='NotDeclared';ObservedStatus='NotEvaluated'} }
    $parsed=New-Object System.Collections.Generic.List[version]
    foreach($v in $values){try{$parsed.Add([version]$v)}catch{return [pscustomobject][ordered]@{Framework=$Framework;Status='DeclaredVersionUnparseable';DeclaredVersions=$values;HighestDeclared=$null;DocumentedReference=$DocumentedReference;ObservedReference=$ObservedReference;DocumentedStatus='Indeterminate';ObservedStatus='Indeterminate'}}}
    $highest=@($parsed.ToArray()|Sort-Object -Descending|Select-Object -First 1)[0]
    $docStatus='ReferenceUnavailable'
    if ($DocumentedReference){try{$r=[version]$DocumentedReference;$docStatus=if($highest -le $r){'MeetsDocumentedReference'}else{'ExceedsDocumentedReference'}}catch{$docStatus='ReferenceUnparseable'}}
    $obsStatus='NotEvaluated'
    if ($ObservedReference){try{$r2=[version]$ObservedReference;$obsStatus=if($highest -le $r2){'MeetsObservedReference'}else{'ExceedsObservedReference'}}catch{$obsStatus='ReferenceUnparseable'}}
    $status=if($docStatus -eq 'ExceedsDocumentedReference'){'ReviewRequired'}elseif($docStatus -in @('ReferenceUnavailable','ReferenceUnparseable')){'Indeterminate'}else{'MeetsDocumentedReference'}
    return [pscustomobject][ordered]@{Framework=$Framework;Status=$status;DeclaredVersions=$values;HighestDeclared=$highest.ToString();DocumentedReference=$DocumentedReference;ObservedReference=$ObservedReference;DocumentedStatus=$docStatus;ObservedStatus=$obsStatus}
}

function Get-AmdWindowsServerInfAnalysis {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][object]$InfTopology,
        [string[]]$KmdfVersions,
        [string[]]$UmdfVersions
    )

    $results=New-Object System.Collections.Generic.List[object]
    foreach($server in @(Get-AmdWindowsServerTargetProfiles)){
        $asPublished=Get-AmdInfApplicabilityForServerProfile -InfTopology $InfTopology -ServerTarget $server
        $projection=Get-AmdInfApplicabilityForServerProfile -InfTopology $InfTopology -ServerTarget $server -ProjectWorkstationToServer
        $kmdf=Compare-AmdWdfVersionToReference -DeclaredVersions $KmdfVersions -DocumentedReference $server.Kmdf.Documented -ObservedReference $server.Kmdf.Observed -Framework 'KMDF'
        $umdf=Compare-AmdWdfVersionToReference -DeclaredVersions $UmdfVersions -DocumentedReference $server.Umdf.Documented -ObservedReference $server.Umdf.Observed -Framework 'UMDF'
        $wdfStatus=if($kmdf.Status -eq 'ReviewRequired' -or $umdf.Status -eq 'ReviewRequired'){'ReviewRequired'}elseif($kmdf.Status -eq 'Indeterminate' -or $umdf.Status -eq 'Indeterminate'){'Indeterminate'}else{'SatisfiedOrNotDeclared'}
        $assessment = if($asPublished.Status -eq 'NativeApplicable' -and $wdfStatus -eq 'SatisfiedOrNotDeclared'){'NATIVE_CANDIDATE'}
                      elseif($asPublished.Status -eq 'NativeApplicable'){'REVIEW_REQUIRED'}
                      elseif($projection.Status -eq 'ProjectionCandidate' -and $wdfStatus -eq 'SatisfiedOrNotDeclared'){'PATCH_CANDIDATE'}
                      elseif($projection.Status -in @('ProjectionCandidate','NativeApplicable')){'REVIEW_REQUIRED'}
                      elseif($asPublished.Status -eq 'SuiteDependent' -or $projection.Status -eq 'SuiteDependent'){'REVIEW_REQUIRED'}
                      elseif($asPublished.Status -eq 'Indeterminate' -and $projection.Status -eq 'Indeterminate'){'INDETERMINATE'}
                      else{'NOT_APPLICABLE'}
        $canonicalAssessment = switch ($assessment) {
            'NATIVE_CANDIDATE' { 'NativeCandidate' }
            'PATCH_CANDIDATE' { 'ProjectionCandidate' }
            'REVIEW_REQUIRED' { if($wdfStatus -eq 'ReviewRequired'){'WdfRequirementReview'}else{'ReviewRequired'} }
            'NOT_APPLICABLE' { 'NotApplicable' }
            'INDETERMINATE' { 'Indeterminate' }
            default { 'Indeterminate' }
        }
        $results.Add([pscustomobject][ordered]@{
            Profile=$server
            Server=$server.Name; ServerId=$server.Id; ShortName=$server.ShortName; OSVersion=('{0}.{1}' -f $server.OSMajorVersion,$server.OSMinorVersion); BaseBuild=$server.BuildNumber; ProductType=$server.ProductType
            AsPublished=$asPublished; ServerProjection=$projection; Wdf=[pscustomobject]@{Status=$wdfStatus;Scope='InfWideConservative';KMDF=$kmdf;UMDF=$umdf}
            WdfScope='InfWideConservative'
            StaticAssessment=$assessment; CanonicalStaticAssessment=$canonicalAssessment; Confidence='STATIC_CANDIDATE'; RuntimeCompatibility='NotEstablished'; RuntimeCompatibilityProven=$false
            # Compatibility aliases retained for 0.3.x/0.4.x consumers.
            InfTargetingStatus=$asPublished.Status; WdfStatus=$wdfStatus; ApplicableModelsSections=@($asPublished.SelectedModelsSections); ConditionalModelsSections=@()
            Kmdf=$kmdf; Umdf=$umdf; EntryEvidence=@($asPublished.SelectionEvidence)
        })
    }
    return $results.ToArray()
}

function Test-AmdWindowsServerAnalysisLogic {
    [CmdletBinding()]
    param()

    $failures=New-Object System.Collections.Generic.List[string]

    $workstationInf=@('[Version]','Signature="$WINDOWS NT$"','[Manufacturer]','%AMD%=AMD.Mfg,NTamd64.10.0.1..16299','[AMD.Mfg.NTamd64.10.0.1..16299]','%DEV%=Install,PCI\VEN_1002&DEV_TEST','[Strings]','AMD="AMD"','DEV="Synthetic"')
    $st=Get-AmdInfStringTable -Lines $workstationInf; $mt=Get-AmdInfManufacturerTargeting -Lines $workstationInf -StringTable $st; $top=Get-AmdInfTopology -ManufacturerTargeting $mt
    $a=@(Get-AmdWindowsServerInfAnalysis -InfTopology $top -KmdfVersions @() -UmdfVersions @())
    $w16=@($a|Where-Object{$_.ShortName -eq 'WS2016'})[0];$w19plus=@($a|Where-Object{$_.ShortName -in @('WS2019','WS2022','WS2025')})
    if($w16.AsPublished.Status -ne 'NotApplicableByBuild' -or @($w19plus|Where-Object{$_.AsPublished.Status -ne 'NotApplicableByProductType'}).Count -ne 0){$failures.Add('ProductType/build synthetic as-published split was not preserved.')}
    if($w16.ServerProjection.Status -ne 'NotApplicableByBuild' -or @($w19plus|Where-Object{$_.ServerProjection.Status -ne 'ProjectionCandidate'}).Count -ne 0){$failures.Add('ProductType=1 virtual projection did not preserve the build floor or produce later Server candidates.')}

    $buildInf=@('[Version]','Signature="$WINDOWS NT$"','[Manufacturer]','%AMD%=AMD.Mfg,NTamd64.10.0...17763','[AMD.Mfg.NTamd64.10.0...17763]','%DEV%=Install,PCI\VEN_1002&DEV_TEST','[Strings]','AMD="AMD"','DEV="Synthetic"')
    $st=Get-AmdInfStringTable -Lines $buildInf; $mt=Get-AmdInfManufacturerTargeting -Lines $buildInf -StringTable $st; $top=Get-AmdInfTopology -ManufacturerTargeting $mt
    $a=@(Get-AmdWindowsServerInfAnalysis -InfTopology $top -KmdfVersions @() -UmdfVersions @())
    if((@($a|Where-Object{$_.ShortName -eq 'WS2016'})[0].AsPublished.Status) -ne 'NotApplicableByBuild' -or (@($a|Where-Object{$_.ShortName -eq 'WS2019'})[0].AsPublished.Status) -ne 'NativeApplicable'){$failures.Add('BuildNumber selector did not separate WS2016 from WS2019.')}

    $selectorInf=@('[Version]','Signature="$WINDOWS NT$"','[Manufacturer]','%AMD%=AMD.Mfg,NTamd64.10.0,NTamd64.10.0...22000','[AMD.Mfg.NTamd64.10.0]','%OLD%=Install,PCI\VEN_1002&DEV_OLD','[AMD.Mfg.NTamd64.10.0...22000]','%NEW%=Install,PCI\VEN_1002&DEV_NEW','[Strings]','AMD="AMD"','OLD="Old"','NEW="New"')
    $st=Get-AmdInfStringTable -Lines $selectorInf; $mt=Get-AmdInfManufacturerTargeting -Lines $selectorInf -StringTable $st; $top=Get-AmdInfTopology -ManufacturerTargeting $mt
    $a=@(Get-AmdWindowsServerInfAnalysis -InfTopology $top -KmdfVersions @() -UmdfVersions @())
    $w22=@($a|Where-Object{$_.ShortName -eq 'WS2022'})[0]; $w25=@($a|Where-Object{$_.ShortName -eq 'WS2025'})[0]
    if(@($w22.AsPublished.SelectedHardwareIds) -contains 'PCI\VEN_1002&DEV_NEW'){$failures.Add('Specificity selector selected build 22000 section on WS2022 build 20348.')}
    if(-not (@($w25.AsPublished.SelectedHardwareIds) -contains 'PCI\VEN_1002&DEV_NEW')){$failures.Add('Specificity selector did not select build 22000 section on WS2025.')}

    $emptyInf=@('[Version]','Signature="$WINDOWS NT$"','[Manufacturer]','%AMD%=AMD.Mfg,NTamd64.10.0,NTamd64.10.0...22000','[AMD.Mfg.NTamd64.10.0]','%OLD%=Install,PCI\VEN_1002&DEV_OLD','[AMD.Mfg.NTamd64.10.0...22000]','[Strings]','AMD="AMD"','OLD="Old"')
    $st=Get-AmdInfStringTable -Lines $emptyInf; $mt=Get-AmdInfManufacturerTargeting -Lines $emptyInf -StringTable $st; $top=Get-AmdInfTopology -ManufacturerTargeting $mt
    $a=@(Get-AmdWindowsServerInfAnalysis -InfTopology $top -KmdfVersions @() -UmdfVersions @()); $w25=@($a|Where-Object{$_.ShortName -eq 'WS2025'})[0]
    if($w25.AsPublished.Status -ne 'ExplicitlyExcluded'){$failures.Add('Empty most-specific Models section was not preserved as explicit exclusion.')}

    $nativeServerInf=@('[Version]','Signature="$WINDOWS NT$"','[Manufacturer]','%AMD%=AMD.Mfg,NTamd64.10.0.3,NTamd64.10.0.3..20348','[AMD.Mfg.NTamd64.10.0.3]','[AMD.Mfg.NTamd64.10.0.3..20348]','%DEV%=Install,PCI\VEN_1002&DEV_SERVER','[Strings]','AMD="AMD"','DEV="Server Synthetic"')
    $st=Get-AmdInfStringTable -Lines $nativeServerInf; $mt=Get-AmdInfManufacturerTargeting -Lines $nativeServerInf -StringTable $st; $top=Get-AmdInfTopology -ManufacturerTargeting $mt
    $a=@(Get-AmdWindowsServerInfAnalysis -InfTopology $top -KmdfVersions @() -UmdfVersions @())
    if((@($a|Where-Object{$_.ShortName -eq 'WS2016'})[0].CanonicalStaticAssessment) -ne 'NotApplicable' -or (@($a|Where-Object{$_.ShortName -eq 'WS2019'})[0].CanonicalStaticAssessment) -ne 'NotApplicable' -or (@($a|Where-Object{$_.ShortName -eq 'WS2022'})[0].CanonicalStaticAssessment) -ne 'NativeCandidate' -or (@($a|Where-Object{$_.ShortName -eq 'WS2025'})[0].CanonicalStaticAssessment) -ne 'NativeCandidate'){$failures.Add('Native Server 20348 control did not preserve old-Server exclusion and WS2022/WS2025 native selection.')}

    $neutralInf=@('[Version]','Signature="$WINDOWS NT$"','[Manufacturer]','%AMD%=AMD.Mfg,NTamd64.10.0','[AMD.Mfg.NTamd64.10.0]','%DEV%=Install,PCI\VEN_1002&DEV_TEST','[Strings]','AMD="AMD"','DEV="Synthetic"')
    $st=Get-AmdInfStringTable -Lines $neutralInf; $mt=Get-AmdInfManufacturerTargeting -Lines $neutralInf -StringTable $st; $top=Get-AmdInfTopology -ManufacturerTargeting $mt
    $a=@(Get-AmdWindowsServerInfAnalysis -InfTopology $top -KmdfVersions @('1.31') -UmdfVersions @())
    if((@($a|Where-Object{$_.ShortName -eq 'WS2016'})[0].StaticAssessment) -ne 'REVIEW_REQUIRED' -or (@($a|Where-Object{$_.ShortName -eq 'WS2022'})[0].StaticAssessment) -ne 'NATIVE_CANDIDATE'){$failures.Add('KMDF 1.31 reference split did not produce expected review/native results.')}
    if((@($a|Select-Object -First 1)[0].WdfScope) -ne 'InfWideConservative'){$failures.Add('WDF scope is not explicitly InfWideConservative.')}

    return [pscustomobject][ordered]@{Status=if($failures.Count -eq 0){'Pass'}else{'Fail'};TestCount=9;Failures=$failures.ToArray()}
}

function Test-AmdInfIdentifierTaxonomyLogic {
    [CmdletBinding()]
    param()

    $failures=New-Object System.Collections.Generic.List[string]
    $cases=@(
        [pscustomobject]@{Id='PCI\VEN_1002&DEV_TEST';Class='Display';Kind='EnumeratorHardwareId'},
        [pscustomobject]@{Id='ACP\DEVTYPE_0001';Class='System';Kind='EnumeratorHardwareId'},
        [pscustomobject]@{Id='ROOT\SYNTHETIC';Class='System';Kind='RootEnumeratedHardwareId'},
        [pscustomobject]@{Id='{4d36e968-e325-11ce-bfc1-08002be10318}\Render';Class='Display';Kind='DeviceClassSpecificId'},
        [pscustomobject]@{Id='*GENERIC_ID';Class='System';Kind='GenericHardwareId'},
        [pscustomobject]@{Id='AMD_COMPONENT';Class='NetService';Kind='NetworkSoftwareComponentId'}
    )
    foreach($case in $cases){$info=Get-AmdInfIdentifierInfo -Identifier $case.Id -InfClass $case.Class;if($info.Raw -ne $case.Id -or $info.Kind -ne $case.Kind){$failures.Add(('Identifier taxonomy mismatch for {0}: expected {1}, got {2}.' -f $case.Id,$case.Kind,$info.Kind))}}

    $lines=@('[Version]','Signature="$WINDOWS NT$"','Class=System','[Manufacturer]','%AMD%=AMD.Mfg,NTamd64.10.0','[AMD.Mfg.NTamd64.10.0]','%A%=Install,ACP\DEVTYPE_0001','%B%=Install,{4d36e968-e325-11ce-bfc1-08002be10318}\Render','%C%=Install,*GENERIC_ID','[Strings]','AMD="AMD"','A="A"','B="B"','C="C"')
    $st=Get-AmdInfStringTable -Lines $lines; $mt=Get-AmdInfManufacturerTargeting -Lines $lines -StringTable $st; $top=Get-AmdInfTopology -ManufacturerTargeting $mt
    foreach($expected in @('ACP\DEVTYPE_0001','{4d36e968-e325-11ce-bfc1-08002be10318}\Render','*GENERIC_ID')){if(-not (@($top.TopologyHardwareIds) -contains $expected)){$failures.Add(('Full Models identifier preservation failed for {0}.' -f $expected))}}
    if($top.SharedContractVersion -ne $script:AmdInfSemanticContractVersion -or $top.IdentifierTaxonomyVersion -ne $script:AmdInfIdentifierTaxonomyVersion){$failures.Add('INF topology did not emit shared semantic/taxonomy versions.')}

    return [pscustomobject][ordered]@{Status=if($failures.Count -eq 0){'Pass'}else{'Fail'};TestCount=8;Failures=$failures.ToArray()}
}

function Test-AmdGraphicsIdentityClassificationLogic {
    [CmdletBinding()]
    param()

    $failures = New-Object System.Collections.Generic.List[string]

    $cases = @(
        [pscustomobject]@{
            Name='PRO RDNA'
            FileName='amd-software-pro-edition-26.q1-win11-rdna.exe'
            ExpectedBranch='MultiArtifact'
            ExpectedRole='RDNA'
        },
        [pscustomobject]@{
            Name='PRO VegaPolaris'
            FileName='amd-software-pro-edition-26.q1-win11-vega-polaris.exe'
            ExpectedBranch='MultiArtifact'
            ExpectedRole='PolarisVega'
        },
        [pscustomobject]@{
            Name='PRO WindowsServer VegaPolaris'
            FileName='amd-software-pro-edition-26.q1-winsvr2022-vega-polaris.exe'
            ExpectedBranch='MultiArtifact'
            ExpectedRole='WindowsServer-PolarisVega'
        },
        [pscustomobject]@{
            Name='Adrenalin VegaPolaris'
            FileName='whql-amd-software-adrenalin-edition-26.5.2-win11-may-vega-polaris.exe'
            ExpectedBranch='PolarisVega'
            ExpectedRole='PolarisVega'
        }
    )

    foreach ($case in $cases) {
        $c = Get-AmdGraphicsReleaseClassification -Url $case.FileName
        $role = Get-AmdArtifactRoleFromFileName -FileName $case.FileName -Branch $c.Branch
        if ($c.Branch -ne $case.ExpectedBranch) {
            $failures.Add(('{0}: expected Branch={1}, observed {2}' -f $case.Name,$case.ExpectedBranch,$c.Branch))
        }
        if ($role -ne $case.ExpectedRole) {
            $failures.Add(('{0}: expected ArtifactRole={1}, observed {2}' -f $case.Name,$case.ExpectedRole,$role))
        }
    }

    $proReleaseKeys = @(@(
        (Get-AmdGraphicsReleaseClassification -Url 'amd-software-pro-edition-26.q1-win11-rdna.exe').ReleaseKey,
        (Get-AmdGraphicsReleaseClassification -Url 'amd-software-pro-edition-26.q1-win11-vega-polaris.exe').ReleaseKey,
        (Get-AmdGraphicsReleaseClassification -Url 'amd-software-pro-edition-26.q1-winsvr2022-vega-polaris.exe').ReleaseKey
    ) | Sort-Object -Unique)
    if ($proReleaseKeys.Count -ne 1 -or $proReleaseKeys[0] -ne 'ProEdition|MultiArtifact|26.Q1') {
        $failures.Add(('PRO 26.Q1 sibling artifacts did not converge to one ReleaseKey: {0}' -f ($proReleaseKeys -join ', ')))
    }

    return [pscustomobject][ordered]@{
        Status = if ($failures.Count -eq 0) { 'Pass' } else { 'Fail' }
        TestCount = 5
        Failures = $failures.ToArray()
    }
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

    $staticAnalysisSelfTest = Invoke-AmdTimedOperation 'Windows Server static analysis' { Test-AmdWindowsServerAnalysisLogic }
    if ($staticAnalysisSelfTest.Status -ne 'Pass') {
        throw ('Windows Server static-analysis self-test failed: {0}' -f (@($staticAnalysisSelfTest.Failures) -join ' | '))
    }

    $identifierSelfTest = Invoke-AmdTimedOperation 'INF identifier taxonomy' { Test-AmdInfIdentifierTaxonomyLogic }
    if ($identifierSelfTest.Status -ne 'Pass') {
        throw ('INF identifier-taxonomy self-test failed: {0}' -f (@($identifierSelfTest.Failures) -join ' | '))
    }

    $identitySelfTest = Invoke-AmdTimedOperation 'Graphics identity classification' { Test-AmdGraphicsIdentityClassificationLogic }
    if ($identitySelfTest.Status -ne 'Pass') {
        throw ('Graphics identity self-test failed: {0}' -f (@($identitySelfTest.Failures) -join ' | '))
    }

    $productDrivenSelfTest = Invoke-AmdTimedOperation 'Product-driven selection' { Test-AmdProductDrivenSelectionLogic }
    if ($productDrivenSelfTest.Status -ne 'Pass') {
        throw ('Product-driven discovery/selection self-test failed: {0}' -f (@($productDrivenSelfTest.Failures) -join ' | '))
    }

    $runAssessmentSelfTest = Invoke-AmdTimedOperation 'Run assessment logic' { Test-AmdRunAssessmentLogic }
    if ($runAssessmentSelfTest.Status -ne 'Pass') {
        throw ('Run-assessment self-test failed: {0}' -f (@($runAssessmentSelfTest.Failures) -join ' | '))
    }

    $productMetadataFetchPolicySelfTest = Invoke-AmdTimedOperation 'Product metadata fetch policy' { Test-AmdProductMetadataFetchPolicyLogic }
    if ($productMetadataFetchPolicySelfTest.Status -ne 'Pass') {
        throw ('Product-metadata fetch-policy self-test failed: {0}' -f (@($productMetadataFetchPolicySelfTest.Failures) -join ' | '))
    }

    $publicationManifestSelfTest = Invoke-AmdTimedOperation 'Publication manifest logic' { Test-AmdPublicationManifestLogic }
    if ($publicationManifestSelfTest.Status -ne 'Pass') {
        throw ('Publication-manifest self-test failed: {0}' -f (@($publicationManifestSelfTest.Failures) -join ' | '))
    }

    $canonicalJsonPublicationSelfTest = Invoke-AmdTimedOperation 'Canonical JSON publication logic' { Test-AmdCanonicalJsonPublicationLogic }
    if ($canonicalJsonPublicationSelfTest.Status -ne 'Pass') {
        throw ('Canonical JSON publication self-test failed: {0}' -f (@($canonicalJsonPublicationSelfTest.Failures) -join ' | '))
    }

    $canonicalJsonCrossRuntimeSelfTest = Invoke-AmdTimedOperation 'Canonical JSON cross-runtime contract' { Test-AmdCanonicalJsonCrossRuntimeSelfTest }
    if ($canonicalJsonCrossRuntimeSelfTest.Status -ne 'Pass') {
        throw ('Canonical JSON cross-runtime self-test failed: {0}' -f (@($canonicalJsonCrossRuntimeSelfTest.Issues) -join ' | '))
    }

    $publicMarkdownPublicationSelfTest = Invoke-AmdTimedOperation 'Public Markdown publication logic' { Test-AmdPublicMarkdownPublicationLogic }
    if ($publicMarkdownPublicationSelfTest.Status -ne 'Pass') {
        throw ('Public Markdown publication self-test failed: {0}' -f (@($publicMarkdownPublicationSelfTest.Failures) -join ' | '))
    }

    $certificatePlanSelfTest=Invoke-AmdTimedOperation 'Certificate verification plan' { Test-AmdGraphicsCertificateVerificationPlanLogic }
    $diagnosticSelfTest=Invoke-AmdTimedOperation 'Diagnostic primitives' { Test-AmdDiagnosticPrimitiveSelfTest }
    $sequentialSourceSelfTest=Invoke-AmdTimedOperation 'Sequential-download source contract' { Test-AmdSequentialDownloadSourceContract -Path $PSCommandPath }
    $httpRetrySelfTest=Invoke-AmdTimedOperation 'HTTP retry policy' { Test-AmdHttpRetryPolicySelfTest }
    $httpTransportSelfTest=Invoke-AmdTimedOperation 'HTTP download transport' { Test-AmdHttpDownloadTransportSelfTest }
    $cardinalitySelfTest=Invoke-AmdTimedOperation 'PowerShell 5.1 collection cardinality' { Test-AmdPowerShell51CollectionCardinalitySelfTest }
    $cardinalitySourceSelfTest=Invoke-AmdTimedOperation 'Collection-cardinality source contract' { Test-AmdCollectionCardinalitySourceContract -Path $PSCommandPath }
    $threeToolCommonCoreSelfTest=Invoke-AmdTimedOperation 'Three-tool common-core contract' { Test-AmdThreeToolCommonCoreContract }
    $ordinalOrderingSelfTest=Invoke-AmdTimedOperation 'Ordinal ordering contract' { Test-AmdOrdinalOrderingSelfTest }
    $windowsExecutionContextSelfTest=Invoke-AmdTimedOperation 'Windows execution-context evidence contract' { Test-AmdWindowsExecutionContextSelfTest }
    $signatureSelfTests=@(
        $certificatePlanSelfTest,
        $diagnosticSelfTest,
        $sequentialSourceSelfTest,
        $httpRetrySelfTest,
        $httpTransportSelfTest,
        $cardinalitySelfTest,
        $cardinalitySourceSelfTest,
        $threeToolCommonCoreSelfTest,
        $ordinalOrderingSelfTest,
        $windowsExecutionContextSelfTest,
        (Invoke-AmdTimedOperation 'Path safety logic' { Test-AmdPathSafetyLogic }),
        (Invoke-AmdTimedOperation 'Archive path safety logic' { Test-AmdArchivePathSafetyLogic }),
        (Invoke-AmdTimedOperation 'Native alias logic' { Test-AmdNativeAliasLogic }),
        (Invoke-AmdTimedOperation 'Expected fallback probe' { Test-AmdExpectedFallbackProbeSelfTest }),
        (Invoke-AmdTimedOperation 'Signature content-type routing' { Test-AmdSignatureContentTypeRoutingSelfTest }),
        (Invoke-AmdTimedOperation 'Native interop type contract' { Test-AmdNativeInteropTypeContractSelfTest }),
        (Invoke-AmdTimedOperation 'Native tool localization' { Test-AmdNativeToolLocalizationSelfTest }),
        (Invoke-AmdTimedOperation 'Toolchain capability parser' { Test-AmdToolchainCapabilityParserSelfTest }),
        (Invoke-AmdTimedOperation 'SignTool verification profile' { Test-AmdSignToolVerificationProfileSelfTest }),
        (Invoke-AmdTimedOperation 'Kernel signature coverage' { Test-AmdKernelSignatureCoverageSelfTest }),
        (Invoke-AmdTimedOperation 'Signature primitives' { Test-AmdSignaturePrimitiveSelfTest }),
        (Invoke-AmdTimedOperation 'Windows Client qualification boundary' { Test-AmdGraphicsWindowsClientQualificationBoundarySelfTest })
    )
    $failedCommonSelfTests=@($signatureSelfTests|Where-Object{[string]$_.Status -ne 'Pass'})
    if($failedCommonSelfTests.Count -gt 0){
        throw('Common hardening/signature self-test failure(s): {0}' -f (@($failedCommonSelfTests|ForEach-Object{($_|ConvertTo-Json -Depth 8 -Compress)})-join ' | '))
    }

    $result = [pscustomobject]@{
        SchemaVersion = '1.0'
        ToolkitVersion = $script:AmdGraphicsResearchToolkitVersion
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
            WindowsServerAnalysisSelfTest = $staticAnalysisSelfTest
            InfIdentifierTaxonomySelfTest = $identifierSelfTest
            GraphicsIdentitySelfTest = $identitySelfTest
            ProductDrivenSelectionSelfTest = $productDrivenSelfTest
            RunAssessmentSelfTest = $runAssessmentSelfTest
            ProductMetadataFetchPolicySelfTest = $productMetadataFetchPolicySelfTest
            PublicationManifestSelfTest = $publicationManifestSelfTest
            CanonicalJsonPublicationSelfTest = $canonicalJsonPublicationSelfTest
            CanonicalJsonCrossRuntimeSelfTest = $canonicalJsonCrossRuntimeSelfTest
            PublicMarkdownPublicationSelfTest = $publicMarkdownPublicationSelfTest
            CertificateVerificationPlanSelfTest = $certificatePlanSelfTest
            DiagnosticPrimitiveSelfTest = $diagnosticSelfTest
            SequentialDownloadSourceContract = $sequentialSourceSelfTest
            HttpRetryPolicySelfTest = $httpRetrySelfTest
            HttpDownloadTransportSelfTest = $httpTransportSelfTest
            PowerShell51CollectionCardinalitySelfTest = $cardinalitySelfTest
            CollectionCardinalitySourceContract = $cardinalitySourceSelfTest
            ThreeToolCommonCoreContract = $threeToolCommonCoreSelfTest
            OrdinalOrderingContract = $ordinalOrderingSelfTest
            SignatureAndNativePrimitiveSelfTests = @($signatureSelfTests)
            WindowsClientQualificationBoundarySelfTest = @($signatureSelfTests|Where-Object{$_.PSObject.Properties['CompleteThreeGenerationUnfiltered']}|Select-Object -First 1)
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
        WindowsServerAnalysisSelfTest = $staticAnalysisSelfTest.Status
        InfIdentifierTaxonomySelfTest = $identifierSelfTest.Status
        GraphicsIdentitySelfTest = $identitySelfTest.Status
        ProductDrivenSelectionSelfTest = $productDrivenSelfTest.Status
        RunAssessmentSelfTest = $runAssessmentSelfTest.Status
        ProductMetadataFetchPolicySelfTest = $productMetadataFetchPolicySelfTest.Status
        PublicationManifestSelfTest = $publicationManifestSelfTest.Status
        CanonicalJsonPublicationSelfTest = $canonicalJsonPublicationSelfTest.Status
        CanonicalJsonCrossRuntimeSelfTest = $canonicalJsonCrossRuntimeSelfTest.Status
        PublicMarkdownPublicationSelfTest = $publicMarkdownPublicationSelfTest.Status
        CertificateVerificationPlanSelfTest = $certificatePlanSelfTest.Status
        DiagnosticPrimitiveSelfTest = $diagnosticSelfTest.Status
        SequentialDownloadSourceContract = $sequentialSourceSelfTest.Status
        HttpRetryPolicySelfTest = $httpRetrySelfTest.Status
        HttpDownloadTransportSelfTest = $httpTransportSelfTest.Status
        PowerShell51CollectionCardinalitySelfTest = $cardinalitySelfTest.Status
        CollectionCardinalitySourceContract = $cardinalitySourceSelfTest.Status
        ThreeToolCommonCoreContractSelfTest = $threeToolCommonCoreSelfTest.Status
        OrdinalOrderingContractSelfTest = $ordinalOrderingSelfTest.Status
        SignatureAndNativePrimitiveSelfTestCount = $signatureSelfTests.Count
        WindowsClientQualificationBoundarySelfTest = [string](@($signatureSelfTests|Where-Object{$_.PSObject.Properties['CompleteThreeGenerationUnfiltered']}|Select-Object -First 1).Status)
        EnvironmentEvidencePath = $OutputPath
        DependencyGuidance = $sevenZipInfo.Guidance
    }

    if (-not $runtimeSupported) {
        throw ('Unsupported PowerShell runtime: {0}. Windows PowerShell 5.1 or PowerShell 7.x is required.' -f $version)
    }
}


function ConvertTo-AmdPlainText {
    [CmdletBinding()]
    param([AllowEmptyString()][string]$Html)
    if ([string]::IsNullOrWhiteSpace($Html)) { return '' }
    $text = [regex]::Replace($Html, '(?is)<script\b.*?</script>|<style\b.*?</style>', ' ')
    $text = [regex]::Replace($text, '(?is)<[^>]+>', ' ')
    $text = [System.Net.WebUtility]::HtmlDecode($text)
    return ([regex]::Replace($text, '\s+', ' ')).Trim()
}

function Get-AmdProductSupportClassification {
    [CmdletBinding()]
    param([Parameter(Mandatory=$true)][string]$Url)
    try { $uri = [Uri]$Url } catch { return $null }
    $path = $uri.AbsolutePath.Trim('/')
    $marker = 'support/downloads/drivers.html/'
    $pos = $path.ToLowerInvariant().IndexOf($marker)
    if ($pos -lt 0) { return $null }
    $tail = $path.Substring($pos + $marker.Length)
    $segments = @($tail -split '/' | Where-Object { $_ })
    if ($segments.Count -lt 4) { return $null }
    $root = $segments[0].ToLowerInvariant()
    if ($root -notin @('graphics','processors')) { return $null }
    $family = $segments[1].ToLowerInvariant()
    $line = $segments[2].ToLowerInvariant()
    $model = [System.IO.Path]::GetFileNameWithoutExtension($segments[$segments.Count-1]).ToLowerInvariant()
    $groupKey = ('{0}|{1}|{2}' -f $root,$family,$line)
    $productKey = ('{0}|{1}' -f $groupKey,$model)
    $previousUrl = $Url -replace '(?i)/support/downloads/drivers\.html/', '/support/downloads/previous-drivers.html/'
    return [pscustomobject][ordered]@{
        ProductKey=$productKey;ProductGroupKey=$groupKey;RootCategory=$root
        ProductFamilySlug=$family;ProductLineSlug=$line;ProductModelSlug=$model
        PathSegments=@($segments);LatestPageUrl=$Url;PreviousPageUrl=$previousUrl
    }
}

function Get-AmdMajorGenerationFromReleaseVersion {
    [CmdletBinding()]
    param([AllowEmptyString()][string]$ReleaseVersion)
    if ($ReleaseVersion -match '^(\d{2})\.') { return [int]$matches[1] }
    return $null
}

function Get-AmdPublishedWindowsTrack {
    [CmdletBinding()]
    param([AllowEmptyString()][string]$Text)
    if (-not $Text) { return [pscustomobject]@{Track='WindowsUnknown';Label=$null} }
    $matches = [regex]::Matches($Text, '(?i)Windows(?:®|\s)*(?:Server\s+)?(?:2025|2022|2019|2016|11|10|7)\s*-?\s*64-Bit\s+Edition')
    if ($matches.Count -eq 0) { return [pscustomobject]@{Track='WindowsUnknown';Label=$null} }
    $label = $matches[$matches.Count-1].Value.Trim()
    if ($label -match '(?i)Server\s+2025') { $track='WindowsServer2025' }
    elseif ($label -match '(?i)Server\s+2022') { $track='WindowsServer2022' }
    elseif ($label -match '(?i)Server\s+2019') { $track='WindowsServer2019' }
    elseif ($label -match '(?i)Server\s+2016') { $track='WindowsServer2016' }
    elseif ($label -match '(?i)Windows(?:®|\s)*(?:11|10)') { $track='WindowsClient' }
    elseif ($label -match '(?i)Windows(?:®|\s)*7') { $track='Windows7Legacy' }
    else { $track='WindowsUnknown' }
    return [pscustomobject]@{Track=$track;Label=$label}
}

function Get-AmdFileNameWindowsTrack {
    [CmdletBinding()]
    param([AllowEmptyString()][string]$FileName)
    if (-not $FileName) { return [pscustomobject]@{Track='WindowsUnknown';Label=$null;Confidence='None'} }
    $n = $FileName.ToLowerInvariant()
    foreach($year in @(2025,2022,2019,2016)) {
        if($n -match ("(?i)(?:winsvr|winserver|server)[-_]?{0}" -f $year)) {
            return [pscustomobject]@{Track=('WindowsServer{0}' -f $year);Label=('FileName:Windows Server {0}' -f $year);Confidence='High'}
        }
    }
    if($n -match '(?i)(?:win11|win10|win10-win11|win11-win10)') {
        return [pscustomobject]@{Track='WindowsClient';Label='FileName:Windows Client';Confidence='High'}
    }
    return [pscustomobject]@{Track='WindowsUnknown';Label=$null;Confidence='None'}
}

function Resolve-AmdPublishedWindowsTrack {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][object]$PageTrack,
        [Parameter(Mandatory=$true)][object]$FileNameTrack
    )
    $page=[string]$PageTrack.Track; $file=[string]$FileNameTrack.Track
    if($file -ne 'WindowsUnknown') {
        if($page -eq 'WindowsUnknown') {
            return [pscustomobject]@{Track=$file;Label=$FileNameTrack.Label;Source='FileNameHint';Status='FileNameOnly';PageTrack=$page;FileNameTrack=$file}
        }
        if($page -ne $file) {
            return [pscustomobject]@{Track=$file;Label=$PageTrack.Label;Source='FileNameOverride';Status='EvidenceConflict';PageTrack=$page;FileNameTrack=$file}
        }
        return [pscustomobject]@{Track=$file;Label=$PageTrack.Label;Source='Consensus';Status='Consistent';PageTrack=$page;FileNameTrack=$file}
    }
    return [pscustomobject]@{Track=$page;Label=$PageTrack.Label;Source='PageContext';Status=if($page -eq 'WindowsUnknown'){'Unknown'}else{'PageOnly'};PageTrack=$page;FileNameTrack=$file}
}

function Get-AmdProductPageDriverEntries {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][string]$Html,
        [Parameter(Mandatory=$true)][object]$Product,
        [Parameter(Mandatory=$true)][ValidateSet('Latest','Previous')][string]$PageKind,
        [Parameter(Mandatory=$true)][string]$PageUrl
    )
    $entries = New-Object System.Collections.Generic.List[object]
    $linkPattern = '(?is)<a\b[^>]*href\s*=\s*["'']([^"'']*https?://drivers\.amd\.com/[^"'']+\.exe(?:\?[^"'']*)?)["''][^>]*>'
    $matches = [regex]::Matches($Html,$linkPattern)
    foreach($m in $matches){
        $downloadUrl=[System.Net.WebUtility]::HtmlDecode($m.Groups[1].Value).Replace('&amp;','&')
        if ($downloadUrl -notmatch '(?i)^https://drivers\.amd\.com/') { continue }
        try{$u=[Uri]$downloadUrl}catch{continue}
        $fileName=[IO.Path]::GetFileName($u.AbsolutePath)
        if(-not $fileName -or $fileName -notmatch '(?i)\.exe$'){continue}
        if($fileName -match '(?i)(minimalsetup|auto[-_]?detect|web[-_]?setup)'){continue}
        $start=[Math]::Max(0,$m.Index-7000);$length=$m.Index-$start
        $before=if($length -gt 0){$Html.Substring($start,$length)}else{''}
        $plain=ConvertTo-AmdPlainText -Html $before
        $tailPlain=if($plain.Length -gt 1400){$plain.Substring($plain.Length-1400)}else{$plain}
        if($plain -match '(?i)Auto-Detect\s+and\s+Install\s*$'){continue}
        if($tailPlain -match '(?i)AMD\s+FSR\s+Technical\s+Preview'){continue}
        $pageOsInfo=Get-AmdPublishedWindowsTrack -Text $tailPlain
        $fileOsInfo=Get-AmdFileNameWindowsTrack -FileName $fileName
        $osInfo=Resolve-AmdPublishedWindowsTrack -PageTrack $pageOsInfo -FileNameTrack $fileOsInfo
        if($osInfo.Track -eq 'WindowsUnknown'){continue}
        $title=$null
        $titlePatterns=@(
            'AMD Software:\s*PRO Edition(?:\s+on\s+Windows(?:®)?\s+Server\s+\d{4}\s*\(64-bit\))?',
            'AMD Software:\s*Adrenalin Edition',
            'Radeon(?:™)?\s+Pro Software for Enterprise[^R]{0,120}',
            'Radeon(?:™)?\s+Software[^R]{0,80}Adrenalin Edition'
        )
        $best=-1
        foreach($tp in $titlePatterns){foreach($tm in [regex]::Matches($plain,'(?i)'+$tp)){if($tm.Index -gt $best){$best=$tm.Index;$title=$tm.Value.Trim()}}}
        $family=$null
        if(($title -match '(?i)PRO Edition|Pro Software for Enterprise') -or ($fileName -match '(?i)pro[-_]?edition')){$family='ProEdition'}
        elseif(($title -match '(?i)Adrenalin') -or ($fileName -match '(?i)adrenalin')){$family='Adrenalin'}
        else{continue}
        $revIndex=$plain.LastIndexOf('Revision Number',[StringComparison]::OrdinalIgnoreCase)
        $revText=if($revIndex -ge 0){$plain.Substring($revIndex,[Math]::Min(320,$plain.Length-$revIndex))}else{$plain}
        $version=Get-AmdVersionFromText -Text $revText
        if(-not $version){$version=Get-AmdVersionFromText -Text $fileName}
        if(-not $version){continue}
        $classification=Get-AmdGraphicsReleaseClassification -Url ($downloadUrl+' '+$title) -ReleaseVersion $version -PackageFamily $family
        $role=Get-AmdArtifactRoleFromFileName -FileName $fileName -Branch ([string]$classification.Branch)
        $quality='Unspecified'
        if($revText -match '(?i)WHQL\s+Recommended|Recommended\s*\(WHQL\)'){$quality='WHQLRecommended'}
        elseif($revText -match '(?i)Optional'){$quality='Optional'}
        $sizeText=$null;$sm=[regex]::Match($revText,'(?i)File\s+Size\s+([0-9.,]+\s*(?:KB|MB|GB))');if($sm.Success){$sizeText=$sm.Groups[1].Value.Trim()}
        $dateText=$null;$dm=[regex]::Match($revText,'(?i)Release\s+Date\s+(\d{4}-\d{2}-\d{2})');if($dm.Success){$dateText=$dm.Groups[1].Value}
        $major=Get-AmdMajorGenerationFromReleaseVersion -ReleaseVersion $version
        $trackKey=('{0}|{1}|{2}|{3}' -f $Product.ProductGroupKey,$osInfo.Track,$family,$role);$selectionTrackKey=('{0}|{1}|{2}' -f $Product.ProductGroupKey,$osInfo.Track,$family)
        $entries.Add([pscustomobject][ordered]@{
            ProductKey=$Product.ProductKey;ProductGroupKey=$Product.ProductGroupKey
            RootCategory=$Product.RootCategory;ProductFamilySlug=$Product.ProductFamilySlug;ProductLineSlug=$Product.ProductLineSlug;ProductModelSlug=$Product.ProductModelSlug
            DriverTrackKey=$trackKey;SelectionTrackKey=$selectionTrackKey;OperatingSystemTrack=$osInfo.Track;PublishedOsLabel=$osInfo.Label
            OperatingSystemTrackSource=$osInfo.Source;OperatingSystemTrackStatus=$osInfo.Status;PageOperatingSystemTrack=$osInfo.PageTrack;FileNameOperatingSystemTrack=$osInfo.FileNameTrack
            PackageFamily=$family;Branch=$classification.Branch;ArtifactRole=$role
            ReleaseKey=$classification.ReleaseKey;ReleaseVersion=$version;MajorGeneration=$major;ReleaseSortKey=(Get-AmdReleaseSortKey -ReleaseVersion $version)
            DriverTitle=$title;ReleaseQuality=$quality;FileSizeText=$sizeText;ReleaseDateText=$dateText
            DownloadUrl=$downloadUrl;FileName=$fileName;ArtifactKey=('{0}|{1}' -f $classification.ReleaseKey,$fileName)
            SourcePageKind=$PageKind;SourcePageUrl=$PageUrl
        })
    }
    return $entries.ToArray()
}

function Get-AmdProductPageSummary {
    [CmdletBinding()]
    param([Parameter(Mandatory=$true)][string]$Html,[Parameter(Mandatory=$true)][object]$Product)
    $plain=ConvertTo-AmdPlainText -Html $Html
    $title=$null;$m=[regex]::Match($Html,'(?is)<title[^>]*>(.*?)</title>');if($m.Success){$title=(ConvertTo-AmdPlainText -Html $m.Groups[1].Value)}
    $name=$null
    if($title){
        $name=([regex]::Replace($title,'(?i)\s+Drivers\s+and\s+Downloads(?:\s*\|\s*Latest\s+Version|\s+-\s+Latest\s+Version)?.*$','')).Trim()
        if(-not $name){$name=$null}
    }
    $family=$null;$series=$null;$graphicsModel=$null
    $m=[regex]::Match($plain,'(?i)\bFamily\s+(.{1,100}?)\s+Series\s+');if($m.Success){$family=$m.Groups[1].Value.Trim()}
    $m=[regex]::Match($plain,'(?i)\bSeries\s+(.{1,120}?)\s+(?:Form Factor|Board Type|Former Codename|Launch Date|Compute Units)\b');if($m.Success){$series=$m.Groups[1].Value.Trim()}
    $m=[regex]::Match($plain,'(?i)Graphics\s+Model\s+(.{1,100}?)\s+(?:Graphics\s+Core\s+Count|Graphics\s+Frequency|Graphics\s+Capabilities|Product IDs)\b');if($m.Success){$graphicsModel=$m.Groups[1].Value.Trim()}
    $origin=if($Product.RootCategory -eq 'graphics'){'DiscreteOrProfessionalGraphics'}elseif($graphicsModel){'ProcessorIntegratedGraphics'}else{'ProcessorWithoutObservedGraphics'}
    return [pscustomobject][ordered]@{PageTitle=$title;ProductName=$name;FamilyName=$family;SeriesName=$series;GraphicsModel=$graphicsModel;ProductOrigin=$origin}
}

function Invoke-AmdProductDiscoverStage {
    [CmdletBinding()]
    param([string]$SeedPath,[string]$OutputPath,[string[]]$SitemapUri=@('https://www.amd.com/en.sitemap.xml','https://www.amd.com/sitemap.xml'),[string[]]$AdditionalProductPageUrl=@())
    $root=Get-AmdResearchToolkitRoot
    if(-not $SeedPath){$SeedPath=Join-Path $root 'data\seed-products.json'}
    if(-not $OutputPath){$OutputPath=Join-Path $root 'inventory\products.json'}
    $records=New-Object System.Collections.Generic.List[object];$seen=@{};$sourceCounts=@{Seed=0;Curated=0;Operator=0;AmdSitemap=0}
    function Add-ProductUrl([string]$Url,[string]$Source,[string]$Detail,[string]$GroupDisplayName=$null,[string]$GraphicsKind=$null,[string[]]$AlternateUrls=@()){
        if(-not $Url){return};$c=Get-AmdProductSupportClassification -Url $Url;if($null -eq $c){return};$key=$c.ProductKey.ToLowerInvariant();if($seen.ContainsKey($key)){return};$seen[$key]=$true
        $alternateLatest=New-Object System.Collections.Generic.List[string];$alternatePrevious=New-Object System.Collections.Generic.List[string]
        foreach($alternateUrl in @($AlternateUrls)){
            if([string]::IsNullOrWhiteSpace([string]$alternateUrl)){continue}
            $alternateClass=Get-AmdProductSupportClassification -Url ([string]$alternateUrl)
            if($null -eq $alternateClass){throw ('Curated alternate product URL is not a supported AMD product-driver URL: {0}' -f [string]$alternateUrl)}
            if([string]$alternateClass.ProductGroupKey -ne [string]$c.ProductGroupKey){throw ('Curated alternate product URL [{0}] resolves to product group [{1}] instead of [{2}].' -f [string]$alternateUrl,[string]$alternateClass.ProductGroupKey,[string]$c.ProductGroupKey)}
            if(-not (@($alternateLatest.ToArray()) -contains [string]$alternateClass.LatestPageUrl)){$alternateLatest.Add([string]$alternateClass.LatestPageUrl)}
            if(-not (@($alternatePrevious.ToArray()) -contains [string]$alternateClass.PreviousPageUrl)){$alternatePrevious.Add([string]$alternateClass.PreviousPageUrl)}
        }
        $records.Add([pscustomobject][ordered]@{ProductKey=$c.ProductKey;ProductGroupKey=$c.ProductGroupKey;RootCategory=$c.RootCategory;ProductFamilySlug=$c.ProductFamilySlug;ProductLineSlug=$c.ProductLineSlug;ProductModelSlug=$c.ProductModelSlug;PathSegments=@($c.PathSegments);LatestPageUrl=$c.LatestPageUrl;PreviousPageUrl=$c.PreviousPageUrl;FallbackLatestPageUrls=@($alternateLatest.ToArray());FallbackPreviousPageUrls=@($alternatePrevious.ToArray());ProductGroupDisplayName=$GroupDisplayName;GraphicsKind=$GraphicsKind;DiscoverySource=$Source;DiscoveryDetail=$Detail;DiscoveredAtUtc=[DateTime]::UtcNow.ToString('o')})
        if($sourceCounts.ContainsKey($Source)){$sourceCounts[$Source]=[int]$sourceCounts[$Source]+1}
    }
    $seedCatalogKind=$null;$seedCatalogVersion=$null;$seedCatalogScope=$null;$seedCoveragePolicy=$null;$seedExcludedByDefault=@()
    if(Test-Path -LiteralPath $SeedPath -PathType Leaf){
        $seed=Read-AmdJsonFile -Path $SeedPath
        if($seed.PSObject.Properties['CatalogKind']){$seedCatalogKind=[string]$seed.CatalogKind}
        if($seed.PSObject.Properties['CatalogVersion']){$seedCatalogVersion=[string]$seed.CatalogVersion}
        if($seed.PSObject.Properties['Scope']){$seedCatalogScope=[string]$seed.Scope}
        if($seed.PSObject.Properties['CoveragePolicy']){$seedCoveragePolicy=[string]$seed.CoveragePolicy}
        if($seed.PSObject.Properties['ExcludedByDefault']){$seedExcludedByDefault=@($seed.ExcludedByDefault)}
        $seedSource=if($seedCatalogKind -eq 'CuratedProductGroups'){'Curated'}else{'Seed'}
        foreach($r in @(Get-AmdCollectionItems -Value $seed.Products)){
            $alternateUrls=if($r.PSObject.Properties['AlternateUrls']){@($r.AlternateUrls)}else{@()}
            Add-ProductUrl -Url ([string]$r.Url) -Source $seedSource -Detail ([string]$r.Reason) -GroupDisplayName ([string]$r.ProductGroupDisplayName) -GraphicsKind ([string]$r.GraphicsKind) -AlternateUrls $alternateUrls
        }
    }
    foreach($u in $AdditionalProductPageUrl){Add-ProductUrl $u 'Operator' 'Operator-supplied product support URL.'}
    $errors=New-Object System.Collections.Generic.List[object];$si=0
    $attemptSitemap=($seedCatalogKind -ne 'CuratedProductGroups')
    if(-not $attemptSitemap){Write-AmdStep ('Using versioned curated product-group catalog {0}; AMD sitemap product discovery is not required for the default research scope.' -f $seedCatalogVersion)}
    foreach($sitemap in $(if($attemptSitemap){$SitemapUri}else{@()})){$si++;$before=$records.Count;Write-AmdStep ('Product sitemap [{0}/{1}] fetch: {2}' -f $si,$SitemapUri.Count,$sitemap);$r=Invoke-AmdQuietTextRequest -Uri $sitemap;if(-not $r.Success){$errors.Add([pscustomobject]@{Uri=$sitemap;Error=$r.Error});Write-AmdCaution $r.Error;continue};try{$xml=ConvertFrom-AmdXmlText -Text ([string]$r.Content) -Source $sitemap;foreach($n in @($xml.SelectNodes("//*[local-name()='loc']"))){$url=[string]$n.InnerText;if($url -notmatch '(?i)/en/support/downloads/drivers\.html/(graphics|processors)/'){continue};Add-ProductUrl $url 'AmdSitemap' $sitemap};Write-AmdOk ('Product sitemap parsed; +{0} product page(s).' -f ($records.Count-$before))}catch{$errors.Add([pscustomobject]@{Uri=$sitemap;Error=$_.Exception.Message})}}
    $sorted=@($records.ToArray()|Sort-Object RootCategory,ProductFamilySlug,ProductLineSlug,ProductModelSlug)
    $groups=@($sorted|Group-Object ProductGroupKey|ForEach-Object{[pscustomobject][ordered]@{ProductGroupKey=$_.Name;ProductGroupDisplayName=$_.Group[0].ProductGroupDisplayName;GraphicsKind=$_.Group[0].GraphicsKind;ProductCount=$_.Count;RootCategory=$_.Group[0].RootCategory;ProductFamilySlug=$_.Group[0].ProductFamilySlug;ProductLineSlug=$_.Group[0].ProductLineSlug}})
    $sitemapCount=[int]$sourceCounts['AmdSitemap'];$seedCount=[int]$sourceCounts['Seed'];$curatedCount=[int]$sourceCounts['Curated'];$operatorCount=[int]$sourceCounts['Operator']
    $completeness=if($curatedCount -gt 0){'CuratedProductGroupCatalog'}elseif($sitemapCount -gt 0){'SitemapBackedBestEffort'}elseif($seedCount -gt 0 -or $operatorCount -gt 0){'SeedOnlyFallback'}else{'NoUsableProducts'}
    $coverageStatus=if($curatedCount -gt 0){'CuratedResearchScope'}elseif($sitemapCount -gt 0){'BestEffort'}elseif($sorted.Count -gt 0){'Partial'}else{'Empty'}
    Write-AmdJsonFile -Path $OutputPath -Value ([pscustomobject][ordered]@{SchemaVersion='amd-graphics-product-catalog/2.0';ToolkitVersion=$script:AmdGraphicsResearchToolkitVersion;GeneratedAtUtc=[DateTime]::UtcNow.ToString('o');Completeness=$completeness;CoverageStatus=$coverageStatus;CanClaimFullProductCatalog=$false;CatalogKind=$seedCatalogKind;CatalogVersion=$seedCatalogVersion;CatalogScope=$seedCatalogScope;CatalogCoveragePolicy=$seedCoveragePolicy;CatalogExcludedByDefault=@($seedExcludedByDefault);ProductCount=$sorted.Count;ProductGroupCount=$groups.Count;Products=$sorted;ProductGroups=$groups;DiscoveryDiagnostics=[pscustomobject]@{SitemapDiscoveryAttempted=$attemptSitemap;SitemapErrors=$errors.ToArray();SeedPath=$SeedPath;SeedProductCount=$seedCount;CuratedProductCount=$curatedCount;OperatorProductCount=$operatorCount;SitemapProductCount=$sitemapCount}})
    if($completeness -eq 'SeedOnlyFallback'){Write-AmdCaution ('Product discovery is seed-only fallback: no curated product-group catalog or sitemap product pages were available. Preview/selection may continue, but default Acquire is blocked unless -AllowSeedOnlyProductDiscovery is specified.')}
    elseif($completeness -eq 'CuratedProductGroupCatalog'){Write-AmdOk ('Product discovery uses curated product-group research scope version {0}; this intentionally represents product groups rather than every AMD product model.' -f $seedCatalogVersion)}
    Write-AmdOk ('Product discovery complete: products={0}; groups={1}; completeness={2}.' -f $sorted.Count,$groups.Count,$completeness)
}

function Invoke-AmdProductMetadataStage {
    [CmdletBinding()]
    param(
        [string]$ProductsPath,
        [string]$OutputPath,
        [string]$GroupsPath,
        [string]$EvidenceDirectory,
        [ValidateRange(1,5)][int]$RetryCount=3,
        [ValidateRange(0,5000)][int]$RequestDelayMilliseconds=350,
        [switch]$Force
    )

    $root=Get-AmdResearchToolkitRoot
    if(-not $ProductsPath){$ProductsPath=Join-Path $root 'inventory\products.json'}
    if(-not $OutputPath){$OutputPath=Join-Path $root 'inventory\product-driver-mapping.json'}
    if(-not $GroupsPath){$GroupsPath=Join-Path $root 'inventory\product-groups.json'}
    if(-not $EvidenceDirectory){$EvidenceDirectory=Join-Path $root 'private\evidence\product-pages'}
    New-AmdDirectory -Path $EvidenceDirectory|Out-Null

    $script:AmdLastProductPageRequestUtc=$null
    $catalog=Read-AmdJsonFile -Path $ProductsPath
    $products=@(Get-AmdCollectionItems -Value $catalog.Products)
    $outProducts=New-Object System.Collections.Generic.List[object]
    $allEntries=New-Object System.Collections.Generic.List[object]
    $i=0

    foreach($product in $products){
        $i++
        $safe=ConvertTo-AmdSafeName ([string]$product.ProductKey)
        Write-AmdStep ('Product metadata [{0}/{1}] {2}' -f $i,$products.Count,$product.ProductKey)

        $alternateLatest=if($product.PSObject.Properties['FallbackLatestPageUrls']){@($product.FallbackLatestPageUrls)}else{@()}
        $alternatePrevious=if($product.PSObject.Properties['FallbackPreviousPageUrls']){@($product.FallbackPreviousPageUrls)}else{@()}

        $latestPath=Join-Path $EvidenceDirectory ($safe+'-latest.html')
        $latestMetaPath=Join-Path $EvidenceDirectory ($safe+'-latest.meta.json')
        $latestHtml=$null
        $latestStatus='Fetched'
        $latestError=$null
        $latestEffectiveUrl=[string]$product.LatestPageUrl
        $latestFetchSource='Primary'
        $latestAttempts=@()
        $latestRecovered=$false
        if((Test-Path $latestPath -PathType Leaf)-and -not $Force){
            $latestHtml=Read-AmdTextFile $latestPath
            $latestStatus='Cached'
            if(Test-Path -LiteralPath $latestMetaPath -PathType Leaf){
                try{
                    $cachedMeta=Read-AmdJsonFile -Path $latestMetaPath
                    if($cachedMeta.PSObject.Properties['EffectiveUri'] -and $cachedMeta.EffectiveUri){$latestEffectiveUrl=[string]$cachedMeta.EffectiveUri}
                    if($cachedMeta.PSObject.Properties['CandidateKind'] -and $cachedMeta.CandidateKind){$latestFetchSource=[string]$cachedMeta.CandidateKind}
                    if($cachedMeta.PSObject.Properties['Recovered']){$latestRecovered=[bool]$cachedMeta.Recovered}
                    if($cachedMeta.PSObject.Properties['Attempts']){$latestAttempts=@($cachedMeta.Attempts)}
                }catch{}
            }
        }
        else{
            $r=Invoke-AmdResilientProductPageRequest -Uri ([string]$product.LatestPageUrl) -AlternateUri $alternateLatest -RetryCount $RetryCount -RequestDelayMilliseconds $RequestDelayMilliseconds
            $latestAttempts=@($r.Attempts)
            if($r.Success){
                $latestHtml=[string]$r.Content
                $latestStatus=[string]$r.FetchStatus
                $latestEffectiveUrl=[string]$r.EffectiveUri
                $latestFetchSource=[string]$r.CandidateKind
                $latestRecovered=[bool]$r.Recovered
                Write-AmdUtf8NoBom $latestPath $latestHtml
                Write-AmdJsonFile -Path $latestMetaPath -Value ([pscustomobject][ordered]@{RequestedUri=[string]$product.LatestPageUrl;EffectiveUri=$latestEffectiveUrl;CandidateKind=$latestFetchSource;FetchStatus=$latestStatus;Recovered=$latestRecovered;Attempts=$latestAttempts})
                if($latestRecovered){
                    Write-AmdCaution ('Product metadata latest page recovered after retry/fallback: requested={0}; effective={1}; attempts={2}' -f [string]$product.LatestPageUrl,$latestEffectiveUrl,$latestAttempts.Count)
                }
            }
            else{
                $latestStatus='FetchFailed'
                $latestError=$r.Error
            }
        }

        $summary=if($latestHtml){Get-AmdProductPageSummary -Html $latestHtml -Product $product}else{$null}
        $entries=New-Object System.Collections.Generic.List[object]
        if($latestHtml){
            foreach($e in @(Get-AmdProductPageDriverEntries -Html $latestHtml -Product $product -PageKind Latest -PageUrl $latestEffectiveUrl)){
                $entries.Add($e)
                $allEntries.Add($e)
            }
        }

        $shouldFetchPrevious=Test-AmdShouldFetchPreviousProductPage -Catalog $catalog -Product $product -Summary $summary -CurrentEntryCount $entries.Count
        $previousStatus='NotRequested'
        $previousError=$null
        $previousPath=$null
        $previousEffectiveUrl=[string]$product.PreviousPageUrl
        $previousFetchSource='Primary'
        $previousAttempts=@()
        $previousRecovered=$false
        if($shouldFetchPrevious){
            $previousPath=Join-Path $EvidenceDirectory ($safe+'-previous.html')
            $previousMetaPath=Join-Path $EvidenceDirectory ($safe+'-previous.meta.json')
            $prevHtml=$null
            $previousStatus='Fetched'
            $previousFetchSource='Primary'
            if((Test-Path $previousPath -PathType Leaf)-and -not $Force){
                $prevHtml=Read-AmdTextFile $previousPath
                $previousStatus='Cached'
                if(Test-Path -LiteralPath $previousMetaPath -PathType Leaf){
                    try{
                        $cachedMeta=Read-AmdJsonFile -Path $previousMetaPath
                        if($cachedMeta.PSObject.Properties['EffectiveUri'] -and $cachedMeta.EffectiveUri){$previousEffectiveUrl=[string]$cachedMeta.EffectiveUri}
                        if($cachedMeta.PSObject.Properties['CandidateKind'] -and $cachedMeta.CandidateKind){$previousFetchSource=[string]$cachedMeta.CandidateKind}
                        if($cachedMeta.PSObject.Properties['Recovered']){$previousRecovered=[bool]$cachedMeta.Recovered}
                        if($cachedMeta.PSObject.Properties['Attempts']){$previousAttempts=@($cachedMeta.Attempts)}
                    }catch{}
                }
            }
            else{
                $r=Invoke-AmdResilientProductPageRequest -Uri ([string]$product.PreviousPageUrl) -AlternateUri $alternatePrevious -RetryCount $RetryCount -RequestDelayMilliseconds $RequestDelayMilliseconds
                $previousAttempts=@($r.Attempts)
                if($r.Success){
                    $prevHtml=[string]$r.Content
                    $previousStatus=[string]$r.FetchStatus
                    $previousEffectiveUrl=[string]$r.EffectiveUri
                    $previousFetchSource=[string]$r.CandidateKind
                    $previousRecovered=[bool]$r.Recovered
                    Write-AmdUtf8NoBom $previousPath $prevHtml
                    Write-AmdJsonFile -Path $previousMetaPath -Value ([pscustomobject][ordered]@{RequestedUri=[string]$product.PreviousPageUrl;EffectiveUri=$previousEffectiveUrl;CandidateKind=$previousFetchSource;FetchStatus=$previousStatus;Recovered=$previousRecovered;Attempts=$previousAttempts})
                    if($previousRecovered){
                        Write-AmdCaution ('Product metadata previous page recovered after retry/fallback: requested={0}; effective={1}; attempts={2}' -f [string]$product.PreviousPageUrl,$previousEffectiveUrl,$previousAttempts.Count)
                    }
                }
                else{
                    $previousStatus='FetchFailed'
                    $previousError=$r.Error
                }
            }
            if($prevHtml){
                foreach($e in @(Get-AmdProductPageDriverEntries -Html $prevHtml -Product $product -PageKind Previous -PageUrl $previousEffectiveUrl)){
                    $entries.Add($e)
                    $allEntries.Add($e)
                }
            }
        }

        $dedup=@($entries.ToArray()|Sort-Object DownloadUrl,OperatingSystemTrack,ReleaseVersion -Unique)
        $outProducts.Add([pscustomobject][ordered]@{
            ProductKey=$product.ProductKey
            ProductGroupKey=$product.ProductGroupKey
            ProductGroupDisplayName=if($product.PSObject.Properties['ProductGroupDisplayName']){$product.ProductGroupDisplayName}else{$null}
            GraphicsKind=if($product.PSObject.Properties['GraphicsKind']){$product.GraphicsKind}else{$null}
            RootCategory=$product.RootCategory
            ProductFamilySlug=$product.ProductFamilySlug
            ProductLineSlug=$product.ProductLineSlug
            ProductModelSlug=$product.ProductModelSlug
            ProductSummary=$summary
            LatestPageUrl=$product.LatestPageUrl
            LatestEffectivePageUrl=$latestEffectiveUrl
            FallbackLatestPageUrls=$alternateLatest
            PreviousPageUrl=$product.PreviousPageUrl
            PreviousEffectivePageUrl=$previousEffectiveUrl
            FallbackPreviousPageUrls=$alternatePrevious
            LatestFetchStatus=$latestStatus
            LatestFetchError=$latestError
            LatestFetchSource=$latestFetchSource
            LatestFetchRecovered=$latestRecovered
            LatestFetchAttempts=$latestAttempts
            PreviousFetchStatus=$previousStatus
            PreviousFetchError=$previousError
            PreviousFetchSource=$previousFetchSource
            PreviousFetchRecovered=$previousRecovered
            PreviousFetchAttempts=$previousAttempts
            DriverEntryCount=$dedup.Count
            DriverEntries=$dedup
        })

        if($latestStatus -ne 'FetchFailed'){
            Write-AmdOk ('Product metadata [{0}/{1}] -> {2}; graphics entries={3}' -f $i,$products.Count,$latestStatus,$dedup.Count)
        }
        else{
            Write-AmdCaution ('Product metadata latest page failed after {0} attempt(s): {1}' -f $latestAttempts.Count,$latestError)
        }
    }

    $entries=@($allEntries.ToArray()|Sort-Object ProductKey,DownloadUrl,OperatingSystemTrack,ReleaseVersion -Unique)
    $artifactGroups=@($entries|Group-Object DownloadUrl|ForEach-Object{
        $g=$_.Group;$first=$g[0]
        [pscustomobject][ordered]@{
            DownloadUrl=$_.Name
            FileName=$first.FileName
            ReleaseVersion=$first.ReleaseVersion
            MajorGeneration=$first.MajorGeneration
            PackageFamily=$first.PackageFamily
            Branch=$first.Branch
            ArtifactRole=$first.ArtifactRole
            ArtifactKey=$first.ArtifactKey
            ReferencedByProductKeys=@($g.ProductKey|Sort-Object -Unique)
            ReferencedByProductGroups=@($g.ProductGroupKey|Sort-Object -Unique)
            PublishedOsTracks=@($g.OperatingSystemTrack|Sort-Object -Unique)
            SourcePages=@($g.SourcePageUrl|Sort-Object -Unique)
        }
    })
    $groupRows=@($outProducts.ToArray()|Group-Object ProductGroupKey|ForEach-Object{
        $g=$_.Group
        $trackKeys=@($g|ForEach-Object{@($_.DriverEntries|ForEach-Object{$_.DriverTrackKey})}|Sort-Object -Unique)
        [pscustomobject][ordered]@{
            ProductGroupKey=$_.Name
            ProductGroupDisplayName=$g[0].ProductGroupDisplayName
            GraphicsKind=$g[0].GraphicsKind
            RootCategory=$g[0].RootCategory
            ProductFamilySlug=$g[0].ProductFamilySlug
            ProductLineSlug=$g[0].ProductLineSlug
            ProductCount=$g.Count
            GraphicsProductCount=@($g|Where-Object{$_.DriverEntryCount -gt 0}).Count
            DriverTrackKeys=$trackKeys
            ProductKeys=@($g.ProductKey|Sort-Object)
        }
    })

    $latestFetchFailures=@($outProducts.ToArray()|Where-Object{$_.LatestFetchStatus -eq 'FetchFailed'})
    $previousFetchFailures=@($outProducts.ToArray()|Where-Object{$_.PreviousFetchStatus -eq 'FetchFailed'})
    $noDriverProducts=@($outProducts.ToArray()|Where-Object{$_.DriverEntryCount -eq 0})
    $recoveredProducts=@($outProducts.ToArray()|Where-Object{$_.LatestFetchRecovered -or $_.PreviousFetchRecovered})
    $fallbackFetches=@($outProducts.ToArray()|Where-Object{$_.LatestFetchSource -eq 'Alternate' -or $_.PreviousFetchSource -eq 'Alternate'})
    $allAttemptRows=New-Object System.Collections.Generic.List[object]
    foreach($p in $outProducts.ToArray()){
        foreach($a in @($p.LatestFetchAttempts)){$allAttemptRows.Add($a)}
        foreach($a in @($p.PreviousFetchAttempts)){$allAttemptRows.Add($a)}
    }
    $retryAttemptCount=@($allAttemptRows.ToArray()|Where-Object{[int]$_.AttemptNumber -gt 1}).Count
    $metadataCompleteness=if($outProducts.Count -eq 0){'Empty'}elseif($latestFetchFailures.Count -eq 0 -and $previousFetchFailures.Count -eq 0 -and $noDriverProducts.Count -eq 0){'Complete'}else{'Partial'}
    $catalogKind=if($catalog.PSObject.Properties['CatalogKind']){[string]$catalog.CatalogKind}else{$null}
    $catalogVersion=if($catalog.PSObject.Properties['CatalogVersion']){[string]$catalog.CatalogVersion}else{$null}

    Write-AmdJsonFile -Path $OutputPath -Value ([pscustomobject][ordered]@{
        SchemaVersion='amd-graphics-product-driver-mapping/1.2'
        ToolkitVersion=$script:AmdGraphicsResearchToolkitVersion
        GeneratedAtUtc=[DateTime]::UtcNow.ToString('o')
        CatalogKind=$catalogKind
        CatalogVersion=$catalogVersion
        MetadataCompleteness=$metadataCompleteness
        CanProceedToAcquire=($metadataCompleteness -eq 'Complete')
        ProductCount=$outProducts.Count
        DriverEntryCount=$entries.Count
        UniqueArtifactUrlCount=$artifactGroups.Count
        LatestFetchFailureCount=$latestFetchFailures.Count
        PreviousFetchFailureCount=$previousFetchFailures.Count
        NoDriverEntryProductCount=$noDriverProducts.Count
        RecoveredFetchProductCount=$recoveredProducts.Count
        FallbackFetchProductCount=$fallbackFetches.Count
        RetryAttemptCount=$retryAttemptCount
        FetchFailureProductKeys=@(@($latestFetchFailures|ForEach-Object{$_.ProductKey})+@($previousFetchFailures|ForEach-Object{$_.ProductKey})|Sort-Object -Unique)
        NoDriverEntryProductKeys=@($noDriverProducts|ForEach-Object{$_.ProductKey}|Sort-Object -Unique)
        Products=$outProducts.ToArray()
        DriverEntries=$entries
        ArtifactMappings=$artifactGroups
    })
    Write-AmdJsonFile -Path $GroupsPath -Value ([pscustomobject][ordered]@{
        SchemaVersion='amd-graphics-product-groups/1.0'
        ToolkitVersion=$script:AmdGraphicsResearchToolkitVersion
        GeneratedAtUtc=[DateTime]::UtcNow.ToString('o')
        ProductGroupCount=$groupRows.Count
        ProductGroups=$groupRows
    })

    if($entries.Count -eq 0){
        throw 'No AMD graphics installer mappings were parsed from the discovered product pages. Review product-page fetch errors/evidence before continuing.'
    }
    if($metadataCompleteness -eq 'Complete'){
        Write-AmdOk ('Product metadata complete: products={0}; driver entries={1}; unique artifact URLs={2}; recovered-products={3}; fallback-products={4}; retry-attempts={5}.' -f $outProducts.Count,$entries.Count,$artifactGroups.Count,$recoveredProducts.Count,$fallbackFetches.Count,$retryAttemptCount)
    }
    else{
        Write-AmdCaution ('Product metadata is partial: latest fetch failures={0}; previous fetch failures={1}; products with no graphics driver entries={2}; recovered-products={3}. Selection may be reviewed, but default Acquire will be blocked.' -f $latestFetchFailures.Count,$previousFetchFailures.Count,$noDriverProducts.Count,$recoveredProducts.Count)
    }
}

function ConvertFrom-AmdFileSizeTextToBytes {
    [CmdletBinding()]
    param([AllowEmptyString()][string]$Text)
    if(-not $Text){return $null};$m=[regex]::Match($Text,'(?i)([0-9.,]+)\s*(KB|MB|GB)');if(-not $m.Success){return $null};$n=0.0;if(-not [double]::TryParse(($m.Groups[1].Value -replace ',',''),[Globalization.NumberStyles]::Float,[Globalization.CultureInfo]::InvariantCulture,[ref]$n)){return $null};switch($m.Groups[2].Value.ToUpperInvariant()){'KB'{return [int64]($n*1KB)}'MB'{return [int64]($n*1MB)}'GB'{return [int64]($n*1GB)}}
}

function New-AmdGraphicsCertificateVerificationPlan {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][object[]]$SelectionRows,
        [Parameter(Mandatory=$true)][object[]]$ArtifactRows,
        [int]$RequestedMajorGenerationCount=3,
        [string[]]$ProductGroupFilter=@()
    )

    $targetReferences=New-Object 'System.Collections.Generic.List[object]'
    $historicalExclusions=New-Object 'System.Collections.Generic.List[object]'
    foreach($track in @($SelectionRows|Group-Object SelectionTrackKey|Sort-Object Name)){
        $majors=@($track.Group|ForEach-Object{[int]$_.MajorGeneration}|Sort-Object -Descending -Unique)
        if($majors.Count -eq 0){continue}
        $newest=[int]$majors[0]
        foreach($row in @($track.Group|Sort-Object DownloadUrl,ArtifactKey)){
            $record=[pscustomobject][ordered]@{
                SelectionTrackKey=[string]$row.SelectionTrackKey
                DriverTrackKey=[string]$row.DriverTrackKey
                ProductGroupKey=[string]$row.ProductGroupKey
                OperatingSystemTrack=[string]$row.OperatingSystemTrack
                PackageFamily=[string]$row.PackageFamily
                ArtifactRole=[string]$row.ArtifactRole
                MajorGeneration=[int]$row.MajorGeneration
                ReleaseVersion=[string]$row.ReleaseVersion
                ReleaseKey=[string]$row.ReleaseKey
                ArtifactKey=[string]$row.ArtifactKey
                DownloadUrl=[string]$row.DownloadUrl
                FileName=[string]$row.FileName
            }
            if([int]$row.MajorGeneration -eq $newest){
                $targetReferences.Add($record)|Out-Null
            }
            else{
                $record|Add-Member -NotePropertyName Disposition -NotePropertyValue 'ExcludedByPolicy' -Force
                $record|Add-Member -NotePropertyName Reason -NotePropertyValue 'OlderSelectedMajorGenerationRetainedForOrdinaryResearch' -Force
                $historicalExclusions.Add($record)|Out-Null
            }
        }
    }

    $urlTargets=New-Object 'System.Collections.Generic.List[object]'
    foreach($group in @($targetReferences.ToArray()|Group-Object DownloadUrl|Sort-Object Name)){
        $rows=@($group.Group)
        $urlTargets.Add([pscustomobject][ordered]@{
            PlannedTargetId=('urlsha256:'+ (Get-AmdStringSha256 -Text ([string]$group.Name).ToLowerInvariant()))
            DownloadUrl=[string]$group.Name
            FileNames=@($rows.FileName|Where-Object{$_}|Sort-Object -Unique)
            ReleaseKeys=@($rows.ReleaseKey|Where-Object{$_}|Sort-Object -Unique)
            ReleaseVersions=@($rows.ReleaseVersion|Where-Object{$_}|Sort-Object -Unique)
            MajorGenerations=@($rows.MajorGeneration|Sort-Object -Descending -Unique)
            SelectionTrackReferences=@($rows.SelectionTrackKey|Sort-Object -Unique)
            DriverTrackReferences=@($rows.DriverTrackKey|Sort-Object -Unique)
            ProductGroupReferences=@($rows.ProductGroupKey|Sort-Object -Unique)
            ArtifactRoles=@($rows.ArtifactRole|Where-Object{$_}|Sort-Object -Unique)
        })|Out-Null
    }

    return [pscustomobject][ordered]@{
        SchemaVersion='amd-graphics-certificate-verification-plan/1.0'
        ToolkitVersion=$script:AmdGraphicsResearchToolkitVersion
        GeneratedAtUtc=Get-AmdUtcTimestamp
        PolicyId='NewestSelectedMajorGenerationPerSelectionTrack/1'
        Status='Planned'
        SelectionUnit='ProductGroupKey|OperatingSystemTrack|PackageFamily'
        FullResearchSelectionPolicy='NewestReleaseInEachOfNewestNMajorGenerationsPerStableSelectionTrack'
        CertificateSelectionPolicy='NewestSelectedMajorGenerationPerStableSelectionTrack'
        RequestedMajorGenerationCount=$RequestedMajorGenerationCount
        ProductGroupFilter=@($ProductGroupFilter)
        FullResearchTrackCount=@($SelectionRows.SelectionTrackKey|Sort-Object -Unique).Count
        FullResearchTrackGenerationCount=@($SelectionRows|ForEach-Object{('{0}|{1}' -f [string]$_.SelectionTrackKey,[int]$_.MajorGeneration)}|Sort-Object -Unique).Count
        FullResearchSelectionCount=$SelectionRows.Count
        FullResearchUniqueUrlCount=$ArtifactRows.Count
        CertificateTrackReferenceCount=$targetReferences.Count
        PlannedUniqueUrlTargetCount=$urlTargets.Count
        HistoricalExclusionCount=$historicalExclusions.Count
        TargetReferences=@($targetReferences.ToArray())
        PlannedUrlTargets=@($urlTargets.ToArray())
        HistoricalExclusions=@($historicalExclusions.ToArray())
        Resolution=[pscustomobject][ordered]@{
            Status='NotResolvedBeforeAcquire'
            MissingUrlTargetCount=0
            AmbiguousUrlTargetCount=0
            ResolvedUrlTargetCount=0
            UniqueInstallerSha256Count=0
            ExecutionArtifacts=@()
            UrlResolution=@()
        }
    }
}

function New-AmdGraphicsLocalCertificateVerificationPlan {
    [CmdletBinding()]
    param([Parameter(Mandatory=$true)][object[]]$AcquiredArtifacts)

    return [pscustomobject][ordered]@{
        SchemaVersion='amd-graphics-certificate-verification-plan/1.0'
        ToolkitVersion=$script:AmdGraphicsResearchToolkitVersion
        GeneratedAtUtc=Get-AmdUtcTimestamp
        PolicyId='OperatorProvidedLocalArtifacts/1'
        Status='Planned'
        SelectionUnit='ExplicitOperatorProvidedArtifact'
        FullResearchSelectionPolicy='OperatorProvidedLocalArtifacts'
        CertificateSelectionPolicy='EveryExplicitLocalArtifact'
        RequestedMajorGenerationCount=0
        ProductGroupFilter=@()
        FullResearchTrackCount=0
        FullResearchTrackGenerationCount=0
        FullResearchSelectionCount=$AcquiredArtifacts.Count
        FullResearchUniqueUrlCount=$AcquiredArtifacts.Count
        CertificateTrackReferenceCount=$AcquiredArtifacts.Count
        PlannedUniqueUrlTargetCount=$AcquiredArtifacts.Count
        HistoricalExclusionCount=0
        TargetReferences=@()
        PlannedUrlTargets=@($AcquiredArtifacts|ForEach-Object{
            [pscustomobject][ordered]@{
                PlannedTargetId=('local:'+[string]$_.ArtifactKey)
                DownloadUrl=[string]$_.SourceUrl
                FileNames=@([string]$_.FileName)
                ReleaseKeys=@([string]$_.ReleaseKey)
                ReleaseVersions=@([string]$_.ReleaseVersion)
                MajorGenerations=@()
                SelectionTrackReferences=@()
                DriverTrackReferences=@()
                ProductGroupReferences=@()
                ArtifactRoles=@([string]$_.ArtifactRole)
                ExplicitArtifactKey=[string]$_.ArtifactKey
            }
        })
        HistoricalExclusions=@()
        Resolution=[pscustomobject][ordered]@{
            Status='NotResolvedBeforeAcquire'
            MissingUrlTargetCount=0
            AmbiguousUrlTargetCount=0
            ResolvedUrlTargetCount=0
            UniqueInstallerSha256Count=0
            ExecutionArtifacts=@()
            UrlResolution=@()
        }
    }
}

function Resolve-AmdGraphicsCertificateVerificationPlan {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]$Plan,
        [Parameter(Mandatory=$true)]$Acquisition
    )

    $available=@((Get-AmdCollectionItems -Value $Acquisition.Artifacts)|Where-Object{
        [string]$_.Status -in @('Downloaded','Cached','Provided') -and
        -not [string]::IsNullOrWhiteSpace([string]$_.Sha256) -and
        -not [string]::IsNullOrWhiteSpace([string]$_.LocalPath)
    })
    $urlResolution=New-Object 'System.Collections.Generic.List[object]'
    $resolvedRows=New-Object 'System.Collections.Generic.List[object]'
    $missing=0
    $ambiguous=0

    foreach($target in @($Plan.PlannedUrlTargets)){
        $matches=@(if($Plan.PolicyId -eq 'OperatorProvidedLocalArtifacts/1'){
            @($available|Where-Object{[string]$_.ArtifactKey -eq [string]$target.ExplicitArtifactKey})
        }else{
            @($available|Where-Object{([string]$_.SourceUrl).Trim().ToLowerInvariant() -eq ([string]$target.DownloadUrl).Trim().ToLowerInvariant()})
        })
        $hashes=@($matches.Sha256|Where-Object{$_}|ForEach-Object{([string]$_).ToLowerInvariant()}|Sort-Object -Unique)
        $status=if($matches.Count -eq 0){$missing++;'MissingAcquiredArtifact'}elseif($hashes.Count -gt 1){$ambiguous++;'AmbiguousMultipleInstallerHashes'}else{'Resolved'}
        $urlResolution.Add([pscustomobject][ordered]@{
            PlannedTargetId=[string]$target.PlannedTargetId
            DownloadUrl=[string]$target.DownloadUrl
            Status=$status
            MatchedArtifactKeys=@($matches.ArtifactKey|Sort-Object -Unique)
            MatchedInstallerSha256=@($hashes)
            SelectionTrackReferences=@($target.SelectionTrackReferences)
            ProductGroupReferences=@($target.ProductGroupReferences)
        })|Out-Null
        if($status -eq 'Resolved'){
            foreach($match in $matches){
                $resolvedRows.Add([pscustomobject][ordered]@{
                    InstallerSha256=([string]$match.Sha256).ToLowerInvariant()
                    ArtifactKey=[string]$match.ArtifactKey
                    LocalPath=[string]$match.LocalPath
                    FileName=[string]$match.FileName
                    SourceUrl=[string]$match.SourceUrl
                    ReleaseKey=[string]$match.ReleaseKey
                    ReleaseVersion=[string]$match.ReleaseVersion
                    PackageFamily=[string]$match.PackageFamily
                    Branch=[string]$match.Branch
                    ArtifactRole=[string]$match.ArtifactRole
                    PlannedTargetId=[string]$target.PlannedTargetId
                    SelectionTrackReferences=@($target.SelectionTrackReferences)
                    DriverTrackReferences=@($target.DriverTrackReferences)
                    ProductGroupReferences=@($target.ProductGroupReferences)
                })|Out-Null
            }
        }
    }

    $executionArtifacts=New-Object 'System.Collections.Generic.List[object]'
    foreach($hashGroup in @($resolvedRows.ToArray()|Group-Object InstallerSha256|Sort-Object Name)){
        $rows=@($hashGroup.Group)
        $executionArtifacts.Add([pscustomobject][ordered]@{
            ExecutionArtifactId=('sha256:'+([string]$hashGroup.Name).ToLowerInvariant())
            InstallerSha256=([string]$hashGroup.Name).ToLowerInvariant()
            RepresentativeArtifactKey=[string]$rows[0].ArtifactKey
            RepresentativeLocalPath=[string]$rows[0].LocalPath
            FileNames=@($rows.FileName|Where-Object{$_}|Sort-Object -Unique)
            ArtifactKeys=@($rows.ArtifactKey|Where-Object{$_}|Sort-Object -Unique)
            SourceUrls=@($rows.SourceUrl|Where-Object{$_}|Sort-Object -Unique)
            ReleaseKeys=@($rows.ReleaseKey|Where-Object{$_}|Sort-Object -Unique)
            ReleaseVersions=@($rows.ReleaseVersion|Where-Object{$_}|Sort-Object -Unique)
            PackageFamilies=@($rows.PackageFamily|Where-Object{$_}|Sort-Object -Unique)
            Branches=@($rows.Branch|Where-Object{$_}|Sort-Object -Unique)
            ArtifactRoles=@($rows.ArtifactRole|Where-Object{$_}|Sort-Object -Unique)
            PlannedTargetIds=@($rows.PlannedTargetId|Where-Object{$_}|Sort-Object -Unique)
            SelectionTrackReferences=@($rows|ForEach-Object{@($_.SelectionTrackReferences)}|Sort-Object -Unique)
            DriverTrackReferences=@($rows|ForEach-Object{@($_.DriverTrackReferences)}|Sort-Object -Unique)
            ProductGroupReferences=@($rows|ForEach-Object{@($_.ProductGroupReferences)}|Sort-Object -Unique)
            ByteIdentityDuplicateReferenceCount=$rows.Count
        })|Out-Null
    }

    $resolutionStatus=if($missing -eq 0 -and $ambiguous -eq 0 -and $executionArtifacts.Count -gt 0){'Ready'}else{'Blocked'}
    $Plan.Status=$resolutionStatus
    $Plan.GeneratedAtUtc=Get-AmdUtcTimestamp
    $Plan.Resolution=[pscustomobject][ordered]@{
        Status=$resolutionStatus
        MissingUrlTargetCount=$missing
        AmbiguousUrlTargetCount=$ambiguous
        ResolvedUrlTargetCount=@($urlResolution.ToArray()|Where-Object{$_.Status -eq 'Resolved'}).Count
        UniqueInstallerSha256Count=$executionArtifacts.Count
        AcquiredArtifactReferenceCount=$resolvedRows.Count
        ByteIdentityDeduplicatedReferenceCount=[Math]::Max(0,$resolvedRows.Count-$executionArtifacts.Count)
        ExecutionArtifacts=@($executionArtifacts.ToArray())
        UrlResolution=@($urlResolution.ToArray())
    }
    return $Plan
}

function Sync-AmdGraphicsCertificateVerificationPlan {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]$Acquisition,
        [string]$SelectionPath,
        [string]$OutputPath
    )
    $root=Get-AmdResearchToolkitRoot
    if(-not $SelectionPath){$SelectionPath=Join-Path $root 'inventory\selection-plan.json'}
    if(-not $OutputPath){$OutputPath=Join-Path $root 'inventory\certificate-verification-plan.json'}
    $available=@((Get-AmdCollectionItems -Value $Acquisition.Artifacts)|Where-Object{[string]$_.Status -in @('Downloaded','Cached','Provided')})
    if([string]$Acquisition.AcquisitionMode -eq 'OperatorProvidedLocalArtifacts'){
        $plan=New-AmdGraphicsLocalCertificateVerificationPlan -AcquiredArtifacts $available
    }
    elseif(Test-Path -LiteralPath $SelectionPath -PathType Leaf){
        $selection=Read-AmdJsonFile -Path $SelectionPath
        if($selection.PSObject.Properties['CertificateVerificationPlan']){
            $plan=$selection.CertificateVerificationPlan
        }else{
            $selectionMajorCount=if($selection.PSObject.Properties['MajorGenerationCount']){[int]$selection.MajorGenerationCount}else{0}
            $selectionProductFilter=if($selection.PSObject.Properties['ProductGroupFilter']){@($selection.ProductGroupFilter)}else{@()}
            $plan=New-AmdGraphicsCertificateVerificationPlan -SelectionRows @(Get-AmdCollectionItems -Value $selection.Selections) -ArtifactRows @(Get-AmdCollectionItems -Value $selection.SelectedArtifacts) -RequestedMajorGenerationCount $selectionMajorCount -ProductGroupFilter $selectionProductFilter
        }
    }
    else{
        throw 'Certificate verification plan cannot be resolved because selection-plan.json is unavailable. Use product-driven Select or explicit -LocalInstallerPath.'
    }
    $resolved=Resolve-AmdGraphicsCertificateVerificationPlan -Plan $plan -Acquisition $Acquisition
    Write-AmdJsonFile -Path $OutputPath -Value $resolved -Depth 50
    return $resolved
}

function Test-AmdGraphicsCertificateVerificationPlanLogic {
    [CmdletBinding()]
    param()
    $rows=@(
        [pscustomobject]@{SelectionTrackKey='g1|WindowsClient|Adrenalin';DriverTrackKey='d1';ProductGroupKey='g1';OperatingSystemTrack='WindowsClient';PackageFamily='Adrenalin';ArtifactRole='RDNA';MajorGeneration=26;ReleaseVersion='26.7.1';ReleaseKey='a26';ArtifactKey='a26|same.exe';DownloadUrl='https://drivers.amd.com/same.exe';FileName='same.exe'},
        [pscustomobject]@{SelectionTrackKey='g1|WindowsClient|Adrenalin';DriverTrackKey='d1';ProductGroupKey='g1';OperatingSystemTrack='WindowsClient';PackageFamily='Adrenalin';ArtifactRole='RDNA';MajorGeneration=25;ReleaseVersion='25.12.1';ReleaseKey='a25';ArtifactKey='a25|old.exe';DownloadUrl='https://drivers.amd.com/old.exe';FileName='old.exe'},
        [pscustomobject]@{SelectionTrackKey='g2|WindowsClient|Adrenalin';DriverTrackKey='d2';ProductGroupKey='g2';OperatingSystemTrack='WindowsClient';PackageFamily='Adrenalin';ArtifactRole='RDNA';MajorGeneration=26;ReleaseVersion='26.7.1';ReleaseKey='a26';ArtifactKey='a26|same.exe';DownloadUrl='https://drivers.amd.com/same.exe';FileName='same.exe'},
        [pscustomobject]@{SelectionTrackKey='g3|WindowsServer2022|ProEdition';DriverTrackKey='d3';ProductGroupKey='g3';OperatingSystemTrack='WindowsServer2022';PackageFamily='ProEdition';ArtifactRole='RDNACombined';MajorGeneration=25;ReleaseVersion='25.Q3.1';ReleaseKey='p25';ArtifactKey='p25|server.exe';DownloadUrl='https://drivers.amd.com/server.exe';FileName='server.exe'}
    )
    $artifacts=@(
        [pscustomobject]@{DownloadUrl='https://drivers.amd.com/same.exe'},
        [pscustomobject]@{DownloadUrl='https://drivers.amd.com/old.exe'},
        [pscustomobject]@{DownloadUrl='https://drivers.amd.com/server.exe'}
    )
    $plan=New-AmdGraphicsCertificateVerificationPlan -SelectionRows $rows -ArtifactRows $artifacts
    $acq=[pscustomobject]@{Artifacts=@(
        [pscustomobject]@{Status='Downloaded';ArtifactKey='a26|same.exe';SourceUrl='https://drivers.amd.com/same.exe';LocalPath='x1';FileName='same.exe';Sha256=('a'*64);ReleaseKey='a26';ReleaseVersion='26.7.1';PackageFamily='Adrenalin';Branch='Main';ArtifactRole='RDNA'},
        [pscustomobject]@{Status='Downloaded';ArtifactKey='p25|server.exe';SourceUrl='https://drivers.amd.com/server.exe';LocalPath='x2';FileName='server.exe';Sha256=('a'*64);ReleaseKey='p25';ReleaseVersion='25.Q3.1';PackageFamily='ProEdition';Branch='Pro';ArtifactRole='RDNACombined'}
    )}
    $resolved=Resolve-AmdGraphicsCertificateVerificationPlan -Plan $plan -Acquisition $acq
    $execution=@($resolved.Resolution.ExecutionArtifacts)
    $ok=(
        $plan.CertificateTrackReferenceCount -eq 3 -and
        $plan.PlannedUniqueUrlTargetCount -eq 2 -and
        $plan.HistoricalExclusionCount -eq 1 -and
        $resolved.Status -eq 'Ready' -and
        $resolved.Resolution.UniqueInstallerSha256Count -eq 1 -and
        $execution.Count -eq 1 -and
        @($execution[0].SelectionTrackReferences).Count -eq 3
    )
    return [pscustomobject][ordered]@{
        Status=if($ok){'Pass'}else{'Fail'}
        CertificateTrackReferenceCount=$plan.CertificateTrackReferenceCount
        PlannedUniqueUrlTargetCount=$plan.PlannedUniqueUrlTargetCount
        HistoricalExclusionCount=$plan.HistoricalExclusionCount
        UniqueInstallerSha256Count=$resolved.Resolution.UniqueInstallerSha256Count
        PreservedSelectionTrackReferenceCount=if($execution.Count -eq 1){@($execution[0].SelectionTrackReferences).Count}else{0}
    }
}

function Invoke-AmdSelectStage {
    [CmdletBinding()]
    param(
        [string]$MappingPath,
        [string]$OutputPath,
        [string]$SelectedMetadataPath,
        [int]$MajorGenerationCount=3,
        [string[]]$ProductGroupKey=@(),
        [int]$MaximumSelectedArtifactCount=32,
        [int]$MaximumEstimatedDownloadGiB=32
    )

    $root=Get-AmdResearchToolkitRoot
    if(-not $MappingPath){$MappingPath=Join-Path $root 'inventory\product-driver-mapping.json'}
    if(-not $OutputPath){$OutputPath=Join-Path $root 'inventory\selection-plan.json'}
    if(-not $SelectedMetadataPath){$SelectedMetadataPath=Join-Path $root 'inventory\selected-release-metadata.json'}

    $mapping=Read-AmdJsonFile -Path $MappingPath
    $mappingCompleteness=if($mapping.PSObject.Properties['MetadataCompleteness']){[string]$mapping.MetadataCompleteness}else{'LegacyUnknown'}
    $entries=@($mapping.DriverEntries|Where-Object{$_.MajorGeneration -ne $null -and $_.OperatingSystemTrack -notin @('WindowsUnknown','Windows7Legacy')})
    $trackEvidenceConflictCount=@($entries|Where-Object{$_.PSObject.Properties['OperatingSystemTrackStatus'] -and $_.OperatingSystemTrackStatus -eq 'EvidenceConflict'}).Count

    if($ProductGroupKey.Count -gt 0){
        $entries=@($entries|Where-Object{
            $g=[string]$_.ProductGroupKey
            @($ProductGroupKey|Where-Object{$g -like $_}).Count -gt 0
        })
    }

    # DriverTrackKey preserves the raw package/artifact role evidence. SelectionTrackKey
    # is deliberately more stable: product group + OS track + package family. Artifact
    # naming/role changes across AMD generations must not create extra historical tracks.
    foreach($entry in $entries){
        $selectionKey=$null
        if($entry.PSObject.Properties['SelectionTrackKey']){$selectionKey=[string]$entry.SelectionTrackKey}
        if([string]::IsNullOrWhiteSpace($selectionKey)){
            $selectionKey=('{0}|{1}|{2}' -f [string]$entry.ProductGroupKey,[string]$entry.OperatingSystemTrack,[string]$entry.PackageFamily)
            $entry | Add-Member -NotePropertyName SelectionTrackKey -NotePropertyValue $selectionKey -Force
        }
    }

    $selections=New-Object System.Collections.Generic.List[object]
    foreach($track in @($entries|Group-Object SelectionTrackKey)){
        $trackEntries=@($track.Group)
        $majors=@($trackEntries.MajorGeneration|Sort-Object -Descending -Unique|Select-Object -First $MajorGenerationCount)
        foreach($major in $majors){
            $majorEntries=@($trackEntries|Where-Object{$_.MajorGeneration -eq $major})
            if($majorEntries.Count -eq 0){continue}
            $bestKey=@($majorEntries.ReleaseSortKey|Sort-Object -Descending|Select-Object -First 1)[0]
            $best=@($majorEntries|Where-Object{$_.ReleaseSortKey -eq $bestKey})
            foreach($artifact in @($best|Group-Object DownloadUrl|ForEach-Object{$_.Group[0]})){
                $selections.Add([pscustomobject][ordered]@{
                    SelectionTrackKey=$track.Name
                    DriverTrackKey=$artifact.DriverTrackKey
                    ProductGroupKey=$artifact.ProductGroupKey
                    OperatingSystemTrack=$artifact.OperatingSystemTrack
                    OperatingSystemTrackSource=if($artifact.PSObject.Properties['OperatingSystemTrackSource']){$artifact.OperatingSystemTrackSource}else{$null}
                    OperatingSystemTrackStatus=if($artifact.PSObject.Properties['OperatingSystemTrackStatus']){$artifact.OperatingSystemTrackStatus}else{$null}
                    PageOperatingSystemTrack=if($artifact.PSObject.Properties['PageOperatingSystemTrack']){$artifact.PageOperatingSystemTrack}else{$null}
                    FileNameOperatingSystemTrack=if($artifact.PSObject.Properties['FileNameOperatingSystemTrack']){$artifact.FileNameOperatingSystemTrack}else{$null}
                    PackageFamily=$artifact.PackageFamily
                    Branch=$artifact.Branch
                    ArtifactRole=$artifact.ArtifactRole
                    MajorGeneration=$major
                    ReleaseVersion=$artifact.ReleaseVersion
                    ReleaseKey=$artifact.ReleaseKey
                    ArtifactKey=$artifact.ArtifactKey
                    DownloadUrl=$artifact.DownloadUrl
                    FileName=$artifact.FileName
                    FileSizeText=$artifact.FileSizeText
                    SourcePageUrl=$artifact.SourcePageUrl
                    Reason='LatestReleaseInMajorGenerationForStableProductTrack'
                })
            }
        }
    }

    $selected=@($selections.ToArray())
    if($selected.Count -eq 0){
        throw 'Product-driven selection produced zero driver candidates. Inspect product-driver-mapping.json and product-page fetch diagnostics before acquisition.'
    }

    $artifactRows=@($selected|Group-Object DownloadUrl|ForEach-Object{
        $g=$_.Group
        $first=$g[0]
        $size=ConvertFrom-AmdFileSizeTextToBytes -Text ([string]$first.FileSizeText)
        [pscustomobject][ordered]@{
            DownloadUrl=$_.Name
            FileName=$first.FileName
            ReleaseVersion=$first.ReleaseVersion
            ReleaseKey=$first.ReleaseKey
            PackageFamily=$first.PackageFamily
            Branch=$first.Branch
            ArtifactRole=$first.ArtifactRole
            MajorGeneration=$first.MajorGeneration
            EstimatedSizeBytes=$size
            ReferrerUrls=@($g.SourcePageUrl|Sort-Object -Unique)
            SelectionTrackReferences=@($g.SelectionTrackKey|Sort-Object -Unique)
            DriverTrackReferences=@($g.DriverTrackKey|Sort-Object -Unique)
            ProductGroupReferences=@($g.ProductGroupKey|Sort-Object -Unique)
        }
    })

    if($MaximumSelectedArtifactCount -gt 0 -and $artifactRows.Count -gt $MaximumSelectedArtifactCount){
        throw ('Product-driven selection produced {0} unique artifacts, exceeding MaximumSelectedArtifactCount={1}. Narrow -ProductGroupKey or explicitly raise the safety limit.' -f $artifactRows.Count,$MaximumSelectedArtifactCount)
    }

    $estimated=[int64]0
    $unknownSizeCount=0
    foreach($a in $artifactRows){
        if($a.EstimatedSizeBytes){$estimated += [int64]$a.EstimatedSizeBytes}else{$unknownSizeCount++}
    }
    $maxEstimatedBytes=if($MaximumEstimatedDownloadGiB -gt 0){[int64]$MaximumEstimatedDownloadGiB * 1GB}else{[int64]0}
    if($maxEstimatedBytes -gt 0 -and $estimated -gt $maxEstimatedBytes){
        throw ('Product-driven selection estimates {0}, exceeding MaximumEstimatedDownloadGiB={1}. Narrow -ProductGroupKey or explicitly raise/disable the byte safety limit.' -f (Format-AmdByteSize $estimated),$MaximumEstimatedDownloadGiB)
    }

    $catalogPath=Join-Path $root 'inventory\products.json'
    $catalog=if(Test-Path -LiteralPath $catalogPath -PathType Leaf){Read-AmdJsonFile -Path $catalogPath}else{$null}
    $catalogCompleteness=if($catalog -and $catalog.PSObject.Properties['Completeness']){[string]$catalog.Completeness}else{'Unknown'}

    $selectionTrackCount=@($selected.SelectionTrackKey|Sort-Object -Unique).Count
    $trackGenerationSelectionCount=@($selected | ForEach-Object { ('{0}|{1}' -f [string]$_.SelectionTrackKey,[int]$_.MajorGeneration) } | Sort-Object -Unique).Count
    $artifactSelectionCount=$selected.Count
    $roleTransitionTracks=New-Object System.Collections.Generic.List[object]
    foreach($tg in @($selected|Group-Object SelectionTrackKey)){
        $roles=@($tg.Group.ArtifactRole|Where-Object{$_}|Sort-Object -Unique)
        if($roles.Count -gt 1){
            $roleTransitionTracks.Add([pscustomobject][ordered]@{
                SelectionTrackKey=$tg.Name
                ArtifactRoles=$roles
                MajorGenerations=@($tg.Group.MajorGeneration|Sort-Object -Descending -Unique)
                Note='ArtifactRole changed across selected major generations; role is preserved as evidence but does not split the stable selection track.'
            })
        }
    }

    $certificatePlan=New-AmdGraphicsCertificateVerificationPlan -SelectionRows $selected -ArtifactRows $artifactRows -RequestedMajorGenerationCount $MajorGenerationCount -ProductGroupFilter $ProductGroupKey
    $plan=[pscustomobject][ordered]@{
        SchemaVersion='amd-graphics-product-selection-plan/1.2'
        ToolkitVersion=$script:AmdGraphicsResearchToolkitVersion
        GeneratedAtUtc=[DateTime]::UtcNow.ToString('o')
        SelectionPolicy='For each stable AMD product-group + OS + package-family track, select the newest available release from each of the newest N major generations; preserve ArtifactRole as evidence; then deduplicate globally by AMD EXE URL.'
        MajorGenerationCount=$MajorGenerationCount
        MaximumSelectedArtifactCount=$MaximumSelectedArtifactCount
        MaximumEstimatedDownloadGiB=$MaximumEstimatedDownloadGiB
        ProductCatalogCompleteness=$catalogCompleteness
        ProductMetadataCompleteness=$mappingCompleteness
        ProductGroupFilter=@($ProductGroupKey)
        SelectionTrackCount=$selectionTrackCount
        TrackGenerationSelectionCount=$trackGenerationSelectionCount
        ArtifactSelectionCount=$artifactSelectionCount
        UniqueSelectedArtifactCount=$artifactRows.Count
        EstimatedDownloadBytes=$estimated
        EstimatedDownloadCompleteness=if($unknownSizeCount -eq 0){'Complete'}else{'Partial'}
        UnknownSizeArtifactCount=$unknownSizeCount
        TrackEvidenceConflictCount=$trackEvidenceConflictCount
        ArtifactRoleTransitionTrackCount=$roleTransitionTracks.Count
        ArtifactRoleTransitions=$roleTransitionTracks.ToArray()
        Selections=$selected
        SelectedArtifacts=$artifactRows
        CertificateVerificationPlan=$certificatePlan
    }
    Write-AmdJsonFile -Path $OutputPath -Value $plan
    Write-AmdJsonFile -Path (Join-Path $root 'inventory\certificate-verification-plan.json') -Value $certificatePlan -Depth 50

    $releaseRows=New-Object System.Collections.Generic.List[object]
    foreach($rg in @($artifactRows|Group-Object ReleaseKey)){
        $g=$rg.Group
        $first=$g[0]
        $refs=@($selected|Where-Object{$_.ReleaseKey -eq $rg.Name})
        $releaseRows.Add([pscustomobject][ordered]@{
            ReleaseKey=$rg.Name
            ReleaseVersion=$first.ReleaseVersion
            PackageFamily=$first.PackageFamily
            Branch=$first.Branch
            ReleaseNotesUrl=if($refs.Count -gt 0){[string]$refs[0].SourcePageUrl}else{$null}
            FetchStatus='SelectedFromProductMapping'
            CandidateDownloadUrls=@($g.DownloadUrl|Sort-Object -Unique)
            CandidateArtifacts=@($g|ForEach-Object{
                [pscustomobject][ordered]@{
                    Url=$_.DownloadUrl
                    ReferrerUrl=if(@($_.ReferrerUrls).Count -gt 0){[string]$_.ReferrerUrls[0]}else{$null}
                    FileName=$_.FileName
                    ArtifactRole=$_.ArtifactRole
                }
            })
            SelectionEvidence=[pscustomobject]@{
                ProductGroups=@($refs.ProductGroupKey|Sort-Object -Unique)
                SelectionTracks=@($refs.SelectionTrackKey|Sort-Object -Unique)
                DriverTracks=@($refs.DriverTrackKey|Sort-Object -Unique)
                MajorGenerations=@($refs.MajorGeneration|Sort-Object -Unique)
            }
        })
    }

    Write-AmdJsonFile -Path $SelectedMetadataPath -Value ([pscustomobject][ordered]@{
        SchemaVersion='1.2'
        ToolkitVersion=$script:AmdGraphicsResearchToolkitVersion
        GeneratedAtUtc=[DateTime]::UtcNow.ToString('o')
        Source='ProductDrivenSelection'
        Releases=$releaseRows.ToArray()
    })

    Write-AmdOk ('Selection complete: stable tracks={0}; track-generations={1}; artifact selections={2}; unique artifacts={3}; estimated download={4}.' -f $selectionTrackCount,$trackGenerationSelectionCount,$artifactSelectionCount,$artifactRows.Count,(Format-AmdByteSize $estimated))
    if($roleTransitionTracks.Count -gt 0){Write-AmdCaution ('ArtifactRole changes were observed in {0} stable track(s); see selection-plan.json for provenance.' -f $roleTransitionTracks.Count)}
    Write-AmdDetail ('Selection plan: {0}' -f $OutputPath)
}


function Test-AmdProductDrivenSelectionLogic {
    [CmdletBinding()]
    param()
    $failures=New-Object System.Collections.Generic.List[string]
    $g=Get-AmdProductSupportClassification -Url 'https://www.amd.com/en/support/downloads/drivers.html/graphics/radeon-rx/radeon-rx-9000-series/amd-radeon-rx-9070-xt.html'
    $p=Get-AmdProductSupportClassification -Url 'https://www.amd.com/en/support/downloads/drivers.html/processors/ryzen-pro/ryzen-pro-5000-series/amd-ryzen-7-pro-5755ge.html'
    if($null -eq $g -or $g.ProductGroupKey -ne 'graphics|radeon-rx|radeon-rx-9000-series'){$failures.Add('Graphics product URL classification failed.')}
    if($null -eq $p -or $p.ProductGroupKey -ne 'processors|ryzen-pro|ryzen-pro-5000-series'){$failures.Add('Processor/iGPU product URL classification failed.')}
    $fixture=@'
<html><body>
<h2>Windows 11 - 64-Bit Edition</h2><h4>AMD Software: Adrenalin Edition</h4><div>Revision Number Adrenalin 26.7.1 (WHQL Recommended) File Size 849 MB Release Date 2026-07-28</div><a href="https://drivers.amd.com/drivers/whql-amd-software-adrenalin-edition-26.7.1-win11-b.exe">Download</a>
<h2>Windows Server 2022 - 64-Bit Edition</h2><h4>AMD Software: PRO Edition on Windows® Server 2022 (64-bit)</h4><div>Revision Number 25.Q3 File Size 1.2 GB Release Date 2025-06-03</div><a href="https://drivers.amd.com/drivers/prographics/amd-software-pro-edition-25.q3-winsvr2022-vega-polaris.exe">Download</a>
<h2>Windows 11 - 64-Bit Edition</h2><h4>Auto-Detect and Install</h4><div>Revision Number 26.7.1 File Size 46 MB</div><a href="https://drivers.amd.com/drivers/installer/amd-software-adrenalin-edition-minimalsetup-26.7.1.exe">Download</a>
</body></html>
'@
    $entries=@(Get-AmdProductPageDriverEntries -Html $fixture -Product $g -PageKind Latest -PageUrl $g.LatestPageUrl)
    if($entries.Count -ne 2){$failures.Add(('Product driver card parser expected 2 full installer entries, got {0}.' -f $entries.Count))}
    $a=@($entries|Where-Object{$_.ReleaseVersion -eq '26.7.1'})
    $s=@($entries|Where-Object{$_.ReleaseVersion -eq '25.Q3'})
    if($a.Count -ne 1 -or $a[0].OperatingSystemTrack -ne 'WindowsClient' -or $a[0].MajorGeneration -ne 26){$failures.Add('Adrenalin product driver mapping semantics failed.')}
    if($s.Count -ne 1 -or $s[0].OperatingSystemTrack -ne 'WindowsServer2022' -or $s[0].ArtifactRole -ne 'WindowsServer-PolarisVega'){ $failures.Add('PRO Server product driver mapping semantics failed.') }
    if($a.Count -eq 1 -and $a[0].SelectionTrackKey -ne ($g.ProductGroupKey+'|WindowsClient|Adrenalin')){ $failures.Add('Stable selection track must not include Adrenalin ArtifactRole.') }
    if($s.Count -eq 1 -and $s[0].SelectionTrackKey -ne ($g.ProductGroupKey+'|WindowsServer2022|ProEdition')){ $failures.Add('Stable selection track must not include PRO ArtifactRole.') }
    $conflictFixture='<html><body><h2>Windows Server 2016 - 64-Bit Edition</h2><div>Revision Number 25.Q3.1 File Size 731 MB</div><a href="https://drivers.amd.com/drivers/prographics/amd-software-pro-edition-25.q3.1-winsvr2025-rdna.exe">Download</a></body></html>'
    $conflict=@(Get-AmdProductPageDriverEntries -Html $conflictFixture -Product $g -PageKind Latest -PageUrl $g.LatestPageUrl)
    if($conflict.Count -ne 1 -or $conflict[0].OperatingSystemTrack -ne 'WindowsServer2025' -or $conflict[0].OperatingSystemTrackStatus -ne 'EvidenceConflict'){ $failures.Add('Filename/server OS conflict hardening failed.') }
    $summaryFixture='<html><head><title>AMD Radeon™ PRO W6400 Drivers and Downloads | Latest Version</title></head><body></body></html>'
    $summary=Get-AmdProductPageSummary -Html $summaryFixture -Product $g
    if($summary.ProductName -ne 'AMD Radeon™ PRO W6400'){ $failures.Add('Product-name title parsing hardening failed.') }
    return [pscustomobject][ordered]@{Status=if($failures.Count -eq 0){'Pass'}else{'Fail'};TestCount=9;Failures=$failures.ToArray()}
}

function Invoke-AmdDiscoverStage {
    [CmdletBinding()]
    param(
        [string]$SeedPath,
        [string]$OutputPath,
        [string[]]$SitemapUri = @('https://www.amd.com/en.sitemap.xml','https://www.amd.com/sitemap.xml'),
        [string[]]$AdditionalReleaseNotesUrl = @()
    )

    $toolRoot = Get-AmdResearchToolkitRoot
    if (-not $SeedPath) { $SeedPath = Join-Path $toolRoot 'data\seed-releases.json' }
    if (-not $OutputPath) { $OutputPath = Join-Path $toolRoot 'inventory\releases.json' }

    $records = New-Object System.Collections.Generic.List[object]
    $seenUrl = @{}

    function Add-ReleaseRecord {
        param([string]$Version,[string]$Url,[string]$Source,[string]$Detail,[string]$PackageFamily,[string]$Branch)
        if (-not $Url) { return }
        $key = $Url.ToLowerInvariant()
        if ($seenUrl.ContainsKey($key)) { return }
        $c = Get-AmdGraphicsReleaseClassification -Url $Url -ReleaseVersion $Version -PackageFamily $PackageFamily -Branch $Branch
        if (-not $c.ReleaseVersion -or $c.PackageFamily -eq 'Unknown') { return }
        $seenUrl[$key] = $true
        $records.Add([pscustomobject][ordered]@{
            ReleaseKey = $c.ReleaseKey
            ReleaseVersion = $c.ReleaseVersion
            PackageFamily = $c.PackageFamily
            Branch = $c.Branch
            ReleaseNotesUrl = $Url
            DiscoverySource = $Source
            DiscoveryDetail = $Detail
            DiscoveredAtUtc = [DateTime]::UtcNow.ToString('o')
            Status = 'Discovered'
        })
    }

    $seedCount=0
    if (Test-Path -LiteralPath $SeedPath -PathType Leaf) {
        $seedData=Read-AmdJsonFile -Path $SeedPath
        foreach ($seed in @($seedData.Records)) {
            Add-ReleaseRecord -Version ([string]$seed.ReleaseVersion) -Url ([string]$seed.ReleaseNotesUrl) -Source 'Seed' -Detail ([string]$seed.Reason) -PackageFamily ([string]$seed.PackageFamily) -Branch ([string]$seed.Branch)
            $seedCount++
        }
    }
    Write-AmdStep ('Loaded {0} graphics seed release record(s).' -f $seedCount)

    foreach ($url in $AdditionalReleaseNotesUrl) {
        Add-ReleaseRecord -Version $null -Url $url -Source 'Operator' -Detail 'Operator-supplied release-note URL.' -PackageFamily $null -Branch $null
    }

    $sitemapErrors=New-Object System.Collections.Generic.List[object]
    $sitemapIndex=0
    foreach ($sitemap in $SitemapUri) {
        $sitemapIndex++; $before=$records.Count
        Write-AmdStep ('Sitemap [{0}/{1}] fetch: {2}' -f $sitemapIndex,$SitemapUri.Count,$sitemap)
        $response=Invoke-AmdQuietTextRequest -Uri $sitemap
        if (-not $response.Success) {
            $sitemapErrors.Add([pscustomobject]@{Uri=$sitemap;Error=$response.Error})
            Write-AmdCaution ('Sitemap unavailable; continuing with seeds: {0}' -f $response.Error)
            continue
        }
        $content=[string]$response.Content
        if ($content.TrimStart() -match '(?is)^<!doctype\s+html\b|^<html\b') {
            $sitemapErrors.Add([pscustomobject]@{Uri=$sitemap;Error='HTML returned where XML was expected.'}); continue
        }
        try {
            $xml=ConvertFrom-AmdXmlText -Text $content -Source $sitemap
            foreach ($node in @($xml.SelectNodes("//*[local-name()='loc']"))) {
                $url=[string]$node.InnerText
                if ($url -notmatch '(?i)/resources/support-articles/release-notes/') { continue }
                if ($url -notmatch '(?i)/(RN-RAD-WIN-|RN-PRO-WIN-)') { continue }
                Add-ReleaseRecord -Version $null -Url $url -Source 'AmdSitemap' -Detail $sitemap -PackageFamily $null -Branch $null
            }
            Write-AmdOk ('Sitemap parsed; +{0} graphics release URL(s).' -f ($records.Count-$before))
        } catch {
            $msg=Get-AmdCompactErrorMessage -Message $_.Exception.Message -MaximumLength 300
            $sitemapErrors.Add([pscustomobject]@{Uri=$sitemap;Error=$msg})
        }
    }

    # ReleaseKey, not version alone, is identity: the same Adrenalin version can
    # legitimately have Main and Polaris/Vega release notes/artifacts.
    $dedup=New-Object System.Collections.Generic.List[object]
    $duplicates=New-Object System.Collections.Generic.List[object]
    foreach ($group in @($records | Group-Object -Property ReleaseKey)) {
        $candidates=@($group.Group | Sort-Object @{Expression={switch([string]$_.DiscoverySource){'Operator'{30};'Seed'{20};'AmdSitemap'{10};default{0}}};Descending=$true}, @{Expression={[string]$_.ReleaseNotesUrl}})
        if ($candidates.Count -eq 0) { continue }
        $chosen=$candidates[0]; $dedup.Add($chosen)
        for($i=1;$i -lt $candidates.Count;$i++) {
            $duplicates.Add([pscustomobject]@{ReleaseKey=$chosen.ReleaseKey;SelectedUrl=$chosen.ReleaseNotesUrl;AlternateUrl=$candidates[$i].ReleaseNotesUrl;AlternateSource=$candidates[$i].DiscoverySource})
        }
    }

    $sorted=@($dedup | Sort-Object @{Expression={Get-AmdReleaseSortKey -ReleaseVersion ([string]$_.ReleaseVersion)}}, PackageFamily, Branch, ReleaseNotesUrl)
    $output=[pscustomobject][ordered]@{
        SchemaVersion='1.0'; ToolkitVersion=$script:AmdGraphicsResearchToolkitVersion; GeneratedAtUtc=[DateTime]::UtcNow.ToString('o')
        Completeness='BestEffort'; ReleaseCount=$sorted.Count; Releases=$sorted
        DiscoveryDiagnostics=[pscustomobject]@{SitemapErrors=$sitemapErrors.ToArray();DuplicateReleaseUrls=$duplicates.ToArray();SeedPath=$SeedPath;IdentityPolicy='PackageFamily + Branch + ReleaseVersion'}
    }
    Write-AmdJsonFile -Path $OutputPath -Value $output
    Write-AmdOk ('Discovery complete: {0} graphics release identity record(s).' -f $sorted.Count)
    Write-AmdDetail ('Output: {0}' -f $OutputPath)
}



function Get-AmdInstallerDownloadCandidates {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$ReleaseVersion,
        [Parameter(Mandatory = $true)][string]$ReleaseNotesUrl,
        [string]$PackageFamily,
        [string]$Branch,
        [AllowEmptyString()][string]$Html
    )

    $results=New-Object System.Collections.Generic.List[string]
    function Add-Candidate { param([string]$Value)
        if ([string]::IsNullOrWhiteSpace($Value)) { return }
        $decoded=[System.Net.WebUtility]::HtmlDecode($Value.Trim()).Replace('&amp;','&')
        if ($decoded -notmatch '(?i)^https://drivers\.amd\.com/') { return }
        if ($decoded -notmatch '(?i)\.exe(?:[?#].*)?$') { return }
        $leaf=[System.IO.Path]::GetFileName(([System.Uri]$decoded).AbsolutePath)
        if ($leaf -notmatch '(?i)(amd.*software|radeon.*software|adrenalin|pro-edition)') { return }

        # Release-note pages can contain unrelated AMD software links. Require
        # the expected public release token in the graphics installer filename.
        if ($ReleaseVersion -match '^(\d+)\.(\d+)\.(\d+)$') {
            $vp = '(?i)(?<!\d){0}[._-]{1}[._-]{2}(?!\d)' -f `
                [regex]::Escape($matches[1]), [regex]::Escape($matches[2]), [regex]::Escape($matches[3])
            if ($leaf -notmatch $vp) { return }
        }
        elseif ($ReleaseVersion -match '^(\d+)\.Q([1-4])(?:\.(\d+))?$') {
            $vp = '(?i){0}[._-]Q{1}' -f [regex]::Escape($matches[1]), [regex]::Escape($matches[2])
            if ($matches[3]) { $vp += ('[._-]{0}' -f [regex]::Escape($matches[3])) }
            if ($leaf -notmatch $vp) { return }
        }

        if (-not $results.Contains($decoded)) { $results.Add($decoded) }
    }
    if ($Html) {
        foreach($m in [regex]::Matches($Html,'(?i)https://drivers\.amd\.com/[A-Za-z0-9_./%+\-]+\.exe(?:\?[^"''<>\s]*)?')) { Add-Candidate $m.Value }
        foreach($m in [regex]::Matches($Html,'(?is)href\s*=\s*["'']([^"'']+)["'']')) {
            Add-Candidate (Resolve-AmdAbsoluteUrl -BaseUrl $ReleaseNotesUrl -Candidate $m.Groups[1].Value)
        }
    }
    return $results.ToArray()
}



function Invoke-AmdMetadataStage {
    [CmdletBinding()]
    param([string]$ReleasesPath,[string]$OutputPath,[string]$EvidenceDirectory,[switch]$Force)
    $toolRoot=Get-AmdResearchToolkitRoot
    if(-not $ReleasesPath){$ReleasesPath=Join-Path $toolRoot 'inventory\releases.json'}
    if(-not $OutputPath){$OutputPath=Join-Path $toolRoot 'inventory\release-metadata.json'}
    if(-not $EvidenceDirectory){$EvidenceDirectory=Join-Path $toolRoot 'private\evidence\release-notes'}
    New-AmdDirectory $EvidenceDirectory | Out-Null
    $releaseData=Read-AmdJsonFile $ReleasesPath; $items=@(Get-AmdCollectionItems -Value $releaseData.Releases); $results=New-Object System.Collections.Generic.List[object]; $idx=0
    foreach($release in $items){
        $idx++; $sw=[Diagnostics.Stopwatch]::StartNew(); $version=[string]$release.ReleaseVersion; $key=[string]$release.ReleaseKey; $url=[string]$release.ReleaseNotesUrl
        Write-AmdStep ('Metadata [{0}/{1}] {2}' -f $idx,$items.Count,$key)
        $safe=ConvertTo-AmdSafeName $key; $htmlPath=Join-Path $EvidenceDirectory ($safe+'.html'); $status='Fetched';$err=$null;$html=$null
        if((Test-Path $htmlPath -PathType Leaf)-and -not $Force){try{$html=Read-AmdTextFile $htmlPath;$status='Cached'}catch{$status='FetchFailed';$err=$_.Exception.Message}}
        else{$r=Invoke-AmdQuietTextRequest -Uri $url;if($r.Success){$html=[string]$r.Content;Write-AmdUtf8NoBom $htmlPath $html}else{$status='FetchFailed';$err=$r.Error}}
        $title=$null;$article=$null;$lastUpdated=$null;$releaseType='Unspecified';$os=@();$driverMentions=@();$urls=@();$sha=$null
        if($html){
            $sha=Get-AmdStringSha256 $html
            $m=[regex]::Match($html,'(?is)<title[^>]*>(.*?)</title>');if($m.Success){$title=[Net.WebUtility]::HtmlDecode(([regex]::Replace($m.Groups[1].Value,'<[^>]+>','')).Trim())}
            $plain=[Net.WebUtility]::HtmlDecode([regex]::Replace($html,'(?is)<script.*?</script>|<style.*?</style>|<[^>]+>',' ')); $plain=[regex]::Replace($plain,'\s+',' ')
            $m=[regex]::Match($plain,'(?i)Article\s+Number\s*:\s*(RN-[A-Z0-9\-]+)');if($m.Success){$article=$m.Groups[1].Value}
            $m=[regex]::Match($plain,'(?i)(?:Last\s+Updated|Date)\s*:\s*([^\.]{4,80}(?:\d{4})?)');if($m.Success){$lastUpdated=$m.Groups[1].Value.Trim()}
            if($plain -match '(?i)WHQL\s+Recommended|WHQL\s+Microsoft\s+Certification\s+Passed'){ $releaseType='WHQL' }
            elseif($plain -match '(?i)Optional\s+Update'){ $releaseType='Optional' }
            foreach($m in [regex]::Matches($plain,'(?i)Windows(?:®|\s)*(?:11|10|Server\s+2022|Server\s+2025|Server\s+2019)[^\.;]{0,90}')){ $v=$m.Value.Trim(); if($os -notcontains $v){$os+=$v} }
            foreach($m in [regex]::Matches($plain,'(?i)(?:AMD Software:\s*(?:Adrenalin Edition|PRO Edition)[^\.]{0,180}?(?:Driver Version|Windows Driver Store Version)[^\.]{0,120})')){ $v=$m.Value.Trim(); if($driverMentions -notcontains $v){$driverMentions+=$v} }
            $urls=@(Get-AmdInstallerDownloadCandidates -ReleaseVersion $version -ReleaseNotesUrl $url -PackageFamily ([string]$release.PackageFamily) -Branch ([string]$release.Branch) -Html $html)
        }
        $results.Add([pscustomobject][ordered]@{ReleaseKey=$key;ReleaseVersion=$version;PackageFamily=[string]$release.PackageFamily;Branch=[string]$release.Branch;ReleaseNotesUrl=$url;ArticleNumber=$article;PageTitle=$title;ReleaseType=$releaseType;PublishedDateText=$lastUpdated;PublishedOperatingSystemMentions=@($os);PublishedDriverVersionMentions=@($driverMentions);FetchStatus=$status;FetchError=$err;RetrievedAtUtc=[DateTime]::UtcNow.ToString('o');HtmlEvidencePath=$htmlPath;HtmlSha256=$sha;CandidateDownloadUrls=@($urls)})
        $sw.Stop(); if($status -in @('Fetched','Cached')){Write-AmdOk ('Metadata [{0}/{1}] -> {2}; candidates={3}; elapsed={4}' -f $idx,$items.Count,$status,$urls.Count,(Format-AmdElapsed $sw.Elapsed))}else{Write-AmdCaution $err}
    }
    Write-AmdJsonFile $OutputPath ([pscustomobject][ordered]@{SchemaVersion='1.0';ToolkitVersion=$script:AmdGraphicsResearchToolkitVersion;GeneratedAtUtc=[DateTime]::UtcNow.ToString('o');Releases=$results.ToArray()})
    Write-AmdOk ('Metadata complete: {0} record(s).' -f $results.Count)
}



function Write-AmdArtifactPathMap {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]$Acquisition,
        [string]$OutputPath
    )

    $toolRoot=Get-AmdResearchToolkitRoot
    if(-not $OutputPath){$OutputPath=Join-Path $toolRoot 'inventory\artifact-path-map.json'}
    $items=New-Object 'System.Collections.Generic.List[object]'
    foreach($artifact in @(Get-AmdCollectionItems -Value $Acquisition.Artifacts)){
        if([string]::IsNullOrWhiteSpace([string]$artifact.LocalPath)){continue}
        $relative=$null
        if(Test-AmdPathWithinToolkitRoot -Path ([string]$artifact.LocalPath) -ToolkitRoot $toolRoot){$relative=(Get-AmdRelativePath -BasePath $toolRoot -Path ([string]$artifact.LocalPath)) -replace '\\','/'}
        $items.Add([pscustomobject][ordered]@{
            ArtifactPathId=if($artifact.PSObject.Properties['ArtifactPathId']){[string]$artifact.ArtifactPathId}else{$null}
            ArtifactKey=[string]$artifact.ArtifactKey
            OriginalFileName=[string]$artifact.FileName
            ToolRelativePath=$relative
            SourceUrl=[string]$artifact.SourceUrl
            Sha256=[string]$artifact.Sha256
            SizeBytes=$artifact.SizeBytes
            Status=[string]$artifact.Status
        })|Out-Null
    }
    $result=[pscustomobject][ordered]@{SchemaVersion='amd-graphics-artifact-path-map/1.0';ToolkitVersion=$script:AmdGraphicsResearchToolkitVersion;GeneratedAtUtc=Get-AmdUtcTimestamp;ArtifactCount=$items.Count;Artifacts=@($items.ToArray())}
    Write-AmdJsonFile -Path $OutputPath -Value $result -Depth 20
    return $result
}

function Invoke-AmdAcquireStage {
    [CmdletBinding()]
    param(
        [string]$MetadataPath,
        [string]$OutputDirectory,
        [string]$ManifestPath,
        [string[]]$ReleaseVersion = @(),
        [string[]]$ReleaseKey = @(),
        [string[]]$LocalInstallerPath = @(),
        [switch]$Force,
        [switch]$AllowNonAmdHost
    )

    $toolRoot = Get-AmdResearchToolkitRoot
    if (-not $MetadataPath) { $MetadataPath = Join-Path $toolRoot 'inventory\release-metadata.json' }
    if (-not $OutputDirectory) { $OutputDirectory = Join-Path $toolRoot 'private\a' }
    if (-not $ManifestPath) { $ManifestPath = Join-Path $toolRoot 'inventory\acquisition.json' }
    New-AmdDirectory -Path $OutputDirectory | Out-Null

    $results = New-Object System.Collections.Generic.List[object]

    # Local artifact mode is intentionally self-contained. When one or more
    # paths are supplied, do not silently mix them with web-discovered artifacts.
    # This makes vendor binaries supplied for qualification reproducible and
    # prevents an offline real-artifact run from unexpectedly downloading data.
    if ($LocalInstallerPath.Count -gt 0) {
        Write-AmdStep ('Importing {0} operator-provided graphics installer artifact(s).' -f $LocalInstallerPath.Count)
        $localIndex = 0
        foreach ($pathValue in @($LocalInstallerPath)) {
            $localIndex++
            $sw = [Diagnostics.Stopwatch]::StartNew()
            if (-not (Test-Path -LiteralPath $pathValue -PathType Leaf)) {
                throw ('Local installer path does not exist: {0}' -f $pathValue)
            }

            $item = Get-Item -LiteralPath $pathValue -ErrorAction Stop
            $classification = Get-AmdGraphicsReleaseClassification -Url $item.Name
            if (-not $classification.ReleaseVersion -or $classification.PackageFamily -eq 'Unknown') {
                throw ('Unable to classify local AMD graphics installer from file name: {0}. Include a recognizable Adrenalin/PRO family and release version in the file name.' -f $item.Name)
            }

            if ($ReleaseVersion.Count -gt 0 -and $ReleaseVersion -notcontains ([string]$classification.ReleaseVersion)) { continue }
            if ($ReleaseKey.Count -gt 0 -and $ReleaseKey -notcontains ([string]$classification.ReleaseKey)) { continue }

            $validation = Get-AmdInstallerFileValidation -Path $item.FullName -MinimumSizeBytes 5MB
            if (-not $validation.Valid) {
                throw ('Local installer validation failed for {0}: {1}' -f $item.FullName, $validation.Error)
            }

            $sha = Get-AmdSha256 -Path $item.FullName
            $role = Get-AmdArtifactRoleFromFileName -FileName $item.Name -Branch ([string]$classification.Branch)
            $artifactKey = ('{0}|{1}' -f $classification.ReleaseKey, $item.Name)
            $results.Add([pscustomobject][ordered]@{
                ArtifactPathId = ('l{0:D4}' -f $localIndex)
                ArtifactKey = $artifactKey
                ReleaseKey = $classification.ReleaseKey
                ReleaseVersion = $classification.ReleaseVersion
                PackageFamily = $classification.PackageFamily
                Branch = $classification.Branch
                ArtifactRole = $role
                Status = 'Provided'
                SourceUrl = 'provided://operator-local-file'
                ReferrerUrl = $null
                LocalPath = $item.FullName
                FileName = $item.Name
                Sha256 = $sha
                SizeBytes = [int64]$item.Length
                Validation = $validation
                RetrievedAtUtc = [DateTime]::UtcNow.ToString('o')
                Error = $null
            })
            $sw.Stop()
            Write-AmdOk ('Import local artifact [{0}/{1}] {2} -> Provided, {3}, role={4}, elapsed={5}' -f `
                $localIndex, $LocalInstallerPath.Count, $item.Name, (Format-AmdByteSize $item.Length), $role, (Format-AmdElapsed $sw.Elapsed))
        }

        $output = [pscustomobject][ordered]@{
            SchemaVersion = '1.1'
            ToolkitVersion = $script:AmdGraphicsResearchToolkitVersion
            GeneratedAtUtc = [DateTime]::UtcNow.ToString('o')
            AcquisitionMode = 'OperatorProvidedLocalArtifacts'
            Artifacts = $results.ToArray()
        }
        Write-AmdJsonFile -Path $ManifestPath -Value $output
        $null=Write-AmdArtifactPathMap -Acquisition $output
        $certificatePlan=Sync-AmdGraphicsCertificateVerificationPlan -Acquisition $output
        Write-AmdOk ('Local acquisition complete: provided artifacts={0}.' -f $results.Count)
        Write-AmdDetail ('Certificate targets: status={0}; unique installer bytes={1}.' -f [string]$certificatePlan.Status,[int]$certificatePlan.Resolution.UniqueInstallerSha256Count)
        Write-AmdDetail ('Manifest: {0}' -f $ManifestPath)
        return
    }

    if (-not (Test-Path -LiteralPath $MetadataPath -PathType Leaf)) {
        throw ('Release metadata is required for web acquisition and was not found: {0}' -f $MetadataPath)
    }

    $metadata = Read-AmdJsonFile -Path $MetadataPath
    $releaseItems = @((Get-AmdCollectionItems -Value $metadata.Releases) | Where-Object {
        ($ReleaseVersion.Count -eq 0 -or $ReleaseVersion -contains ([string]$_.ReleaseVersion)) -and
        ($ReleaseKey.Count -eq 0 -or $ReleaseKey -contains ([string]$_.ReleaseKey))
    })
    $releaseIndex = 0
    Write-AmdStep ('Acquiring graphics installer artifacts for {0} release identity record(s).' -f $releaseItems.Count)

    foreach ($release in $releaseItems) {
        $releaseIndex++
        $version = [string]$release.ReleaseVersion
        $key = [string]$release.ReleaseKey
        if (-not $key) { $key = $version }
        $candidateRecords = @()
        if($release.PSObject.Properties.Name -contains 'CandidateArtifacts' -and @($release.CandidateArtifacts).Count -gt 0){
            $candidateRecords=@($release.CandidateArtifacts)
        } else {
            $candidateRecords=@($release.CandidateDownloadUrls | Select-Object -Unique | ForEach-Object{[pscustomobject]@{Url=[string]$_;ReferrerUrl=[string]$release.ReleaseNotesUrl}})
        }
        $candidates=@($candidateRecords)
        Write-AmdStep ('Acquire release [{0}/{1}] {2}; candidates={3}' -f $releaseIndex,$releaseItems.Count,$key,$candidates.Count)

        if ($candidates.Count -eq 0) {
            $results.Add([pscustomobject][ordered]@{
                ArtifactKey = ('{0}|MissingUrl' -f $key)
                ReleaseKey = $key; ReleaseVersion = $version
                PackageFamily = [string]$release.PackageFamily; Branch = [string]$release.Branch
                ArtifactRole = 'Unknown'; Status = 'MissingUrl'; SourceUrl = $null
                ReferrerUrl = [string]$release.ReleaseNotesUrl; LocalPath = $null; FileName = $null
                Sha256 = $null; SizeBytes = $null; RetrievedAtUtc = $null
                Error = 'No candidate graphics installer URL was parsed from the release-note page.'
            })
            continue
        }

        $candidateIndex = 0
        foreach ($candidateRaw in $candidates) {
            $candidateIndex++
            $candidate = if($candidateRaw -is [string]){[string]$candidateRaw}else{[string]$candidateRaw.Url}
            $candidateReferrer = if($candidateRaw -isnot [string] -and $candidateRaw.PSObject.Properties.Name -contains 'ReferrerUrl' -and $candidateRaw.ReferrerUrl){[string]$candidateRaw.ReferrerUrl}else{[string]$release.ReleaseNotesUrl}
            $sw = [Diagnostics.Stopwatch]::StartNew()
            if (-not $AllowNonAmdHost -and -not (Test-AmdAllowedDownloadHost -Uri $candidate)) {
                $results.Add([pscustomobject]@{ArtifactKey=('{0}|Rejected|{1}'-f $key,$candidateIndex);ReleaseKey=$key;ReleaseVersion=$version;PackageFamily=[string]$release.PackageFamily;Branch=[string]$release.Branch;ArtifactRole='Unknown';Status='RejectedHost';SourceUrl=$candidate;ReferrerUrl=$candidateReferrer;LocalPath=$null;FileName=$null;Sha256=$null;SizeBytes=$null;RetrievedAtUtc=$null;Error='Non-AMD host rejected.'})
                continue
            }
            try { $uri = [Uri]$candidate } catch { $uri = $null }
            if ($null -eq $uri) { continue }
            $fileName = [IO.Path]::GetFileName($uri.AbsolutePath)
            if (-not $fileName) { $fileName = ('amd_graphics_{0}_{1}.exe' -f (ConvertTo-AmdSafeName $key),$candidateIndex) }
            $role = Get-AmdArtifactRoleFromFileName -FileName $fileName -Branch ([string]$release.Branch)
            $artifactPathId=('a'+(Get-AmdStringSha256 -Text $candidate).Substring(0,12))
            $extension=[IO.Path]::GetExtension($fileName)
            if([string]::IsNullOrWhiteSpace($extension)-or $extension.Length -gt 8){$extension='.bin'}
            $localPath = Join-Path $OutputDirectory ($artifactPathId+$extension.ToLowerInvariant())
            $status = 'Cached'
            $dl = $null
            if ($Force -or -not (Test-Path -LiteralPath $localPath -PathType Leaf)) {
                $downloadDiagnosticRoot = Join-Path $toolRoot 'private\l\d'
                $dl = Invoke-AmdQuietFileDownload `
                    -Uri $candidate `
                    -OutFile $localPath `
                    -Referer $candidateReferrer `
                    -TimeoutSec $script:AmdDownloadTimeoutSeconds `
                    -MaximumRedirection 10 `
                    -MaximumAttempts $script:AmdDownloadRetryCount `
                    -DiagnosticDirectory $downloadDiagnosticRoot `
                    -DiagnosticPrefix (ConvertTo-AmdSafeName $key)
                if (-not $dl.Success) {
                    $results.Add([pscustomobject]@{ArtifactKey=('{0}|{1}'-f $key,$fileName);ReleaseKey=$key;ReleaseVersion=$version;PackageFamily=[string]$release.PackageFamily;Branch=[string]$release.Branch;ArtifactRole=$role;Status='DownloadFailed';SourceUrl=$candidate;ReferrerUrl=$candidateReferrer;LocalPath=$null;FileName=$fileName;Sha256=$null;SizeBytes=$null;RetrievedAtUtc=$null;TransportAttempts=@($dl.Attempts);Error=$dl.Error})
                    Write-AmdCaution ('Acquire artifact {0}/{1} failed: {2}' -f $candidateIndex,$candidates.Count,$dl.Error)
                    continue
                }
                $status='Downloaded'
            }

            $validation = Get-AmdInstallerFileValidation -Path $localPath -MinimumSizeBytes 5MB
            if (-not $validation.Valid) {
                $results.Add([pscustomobject]@{ArtifactKey=('{0}|{1}'-f $key,$fileName);ReleaseKey=$key;ReleaseVersion=$version;PackageFamily=[string]$release.PackageFamily;Branch=[string]$release.Branch;ArtifactRole=$role;Status='ValidationFailed';SourceUrl=$candidate;ReferrerUrl=$candidateReferrer;LocalPath=$localPath;FileName=$fileName;Sha256=$null;SizeBytes=(Get-Item $localPath).Length;RetrievedAtUtc=$null;Validation=$validation;Error=$validation.Error})
                continue
            }
            $item=Get-Item $localPath; $sha=Get-AmdSha256 $localPath
            $artifactKey=('{0}|{1}' -f $key,$fileName)
            $results.Add([pscustomobject][ordered]@{ArtifactPathId=$artifactPathId;ArtifactKey=$artifactKey;ReleaseKey=$key;ReleaseVersion=$version;PackageFamily=[string]$release.PackageFamily;Branch=[string]$release.Branch;ArtifactRole=$role;Status=$status;SourceUrl=$candidate;ReferrerUrl=$candidateReferrer;LocalPath=$item.FullName;FileName=$fileName;Sha256=$sha;SizeBytes=[int64]$item.Length;Validation=$validation;TransportAttempts=if($dl){@($dl.Attempts)}else{@()};RetrievedAtUtc=[DateTime]::UtcNow.ToString('o');Error=$null})
            $sw.Stop(); Write-AmdOk ('Acquire artifact [{0}/{1}] {2} -> {3}, {4}, id={5}, role={6}, elapsed={7}' -f $candidateIndex,$candidates.Count,$fileName,$status,(Format-AmdByteSize $item.Length),$artifactPathId,$role,(Format-AmdElapsed $sw.Elapsed))
        }
    }
    $output=[pscustomobject][ordered]@{SchemaVersion='1.1';ToolkitVersion=$script:AmdGraphicsResearchToolkitVersion;GeneratedAtUtc=[DateTime]::UtcNow.ToString('o');AcquisitionMode='PublishedWebArtifacts';Artifacts=$results.ToArray()}
    Write-AmdJsonFile -Path $ManifestPath -Value $output
    $null=Write-AmdArtifactPathMap -Acquisition $output
    $certificatePlan=Sync-AmdGraphicsCertificateVerificationPlan -Acquisition $output
    $ok=@($results|Where-Object{$_.Status -in @('Downloaded','Cached')}).Count
    Write-AmdOk ('Acquisition complete: available artifacts={0}; total records={1}.' -f $ok,$results.Count)
    Write-AmdDetail ('Certificate targets: status={0}; unique installer bytes={1}.' -f [string]$certificatePlan.Status,[int]$certificatePlan.Resolution.UniqueInstallerSha256Count)
    Write-AmdDetail ('Manifest: {0}' -f $ManifestPath)
}

function Initialize-AmdInstallShieldStreamDecoder {
    [CmdletBinding()]
    param()

    if ('AmdGraphicsResearch.IsSetupStreamReader' -as [type]) {
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

namespace AmdGraphicsResearch
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

            if (full.Length > 240)
                throw new PathTooLongException("ISSetupStream output exceeds the 240-character research path limit: " + fileName);

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
    return [AmdGraphicsResearch.IsSetupStreamReader]::Probe((Resolve-Path -LiteralPath $Path).Path)
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

    $result = [AmdGraphicsResearch.IsSetupStreamReader]::Extract(
        (Resolve-Path -LiteralPath $Path).Path,
        (Resolve-Path -LiteralPath $Destination).Path
    )

    if (-not $result.Success) {
        throw ('ISSetupStream extraction failed for {0}: {1}' -f $Path, $result.Error)
    }

    return $result
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

function Get-AmdGraphicsAnalysisSurface {
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)][string]$Root)

    $driverInf = @()
    $displayInf = @()
    if (Test-Path -LiteralPath $Root -PathType Container) {
        $allInf = @(Get-ChildItem -LiteralPath $Root -Filter '*.inf' -File -Recurse -ErrorAction SilentlyContinue)
        foreach ($inf in $allInf) {
            $normalized = ($inf.FullName -replace '\\','/')
            if ($normalized -match '(?i)/Packages/Drivers/') { $driverInf += $inf }
            # Combined packages can expose a second display payload as Display2.
            # Count Display, Display2, ... without changing the full recursive INF inventory.
            if ($normalized -match '(?i)/Packages/Drivers/Display\d*/(?:WT6A_INF|WT64A|U\d+_INF)(?:/|$)') { $displayInf += $inf }
        }
    }

    return [pscustomobject][ordered]@{
        Reached = ($driverInf.Count -gt 0 -and $displayInf.Count -gt 0)
        DriverInfCount = $driverInf.Count
        DisplayInfCount = $displayInf.Count
        Policy = 'Packages/Drivers plus Packages/Drivers/Display* graphics INF observed'
    }
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

function Invoke-AmdExtractionPathPreflight {
    [CmdletBinding()]
    param(
        [string]$AcquisitionPath,
        [string]$OutputDirectory,
        [string]$SevenZipPath,
        [string]$OutputPath
    )

    $toolRoot=Get-AmdResearchToolkitRoot
    if(-not $AcquisitionPath){$AcquisitionPath=Join-Path $toolRoot 'inventory\acquisition.json'}
    if(-not $OutputDirectory){$OutputDirectory=Join-Path $toolRoot 'work\x'}
    if(-not $OutputPath){$OutputPath=Join-Path $toolRoot 'inventory\extraction-path-safety.json'}
    if(-not(Test-Path -LiteralPath $AcquisitionPath -PathType Leaf)){throw 'Extraction path preflight requires inventory\acquisition.json.'}
    $sevenZip=Get-AmdSevenZipPath -ExplicitPath $SevenZipPath
    $acquisition=Read-AmdJsonFile -Path $AcquisitionPath
    $artifacts=@($acquisition.Artifacts|Where-Object{$_.Status -in @('Downloaded','Cached','Provided')})
    $items=New-Object 'System.Collections.Generic.List[object]'
    $issues=New-Object 'System.Collections.Generic.List[string]'
    $ordinal=0
    foreach($artifact in $artifacts){
        $ordinal++
        $artifactPathId=('a{0:D4}' -f $ordinal)
        $containerRoot=Join-Path (Join-Path $OutputDirectory $artifactPathId) 'c0001'
        $assessment=Get-AmdArchiveExtractionPathAssessment -SevenZipPath $sevenZip -ArchivePath ([string]$artifact.LocalPath) -OutputDirectory $containerRoot
        $assessment|Add-Member -NotePropertyName ArtifactPathId -NotePropertyValue $artifactPathId -Force
        $assessment|Add-Member -NotePropertyName ArtifactKey -NotePropertyValue ([string]$artifact.ArtifactKey) -Force
        $items.Add($assessment)|Out-Null
        foreach($issue in @($assessment.Issues)){$issues.Add(('{0}: {1}' -f $artifactPathId,[string]$issue))|Out-Null}
    }
    $result=[pscustomobject][ordered]@{
        SchemaVersion='amd-graphics-extraction-path-safety/1.0';ToolkitVersion=$script:AmdGraphicsResearchToolkitVersion;GeneratedAtUtc=Get-AmdUtcTimestamp
        Status=if($issues.Count -eq 0){'Pass'}else{'Blocked'};SafeFullPathLimit=$script:AmdWindowsSafeFullPathLimit;ArtifactCount=$artifacts.Count
        Assessments=@($items.ToArray());Issues=@($issues.ToArray())
    }
    Write-AmdJsonFile -Path $OutputPath -Value $result -Depth 30
    return $result
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
        $OutputDirectory = Join-Path $toolRoot 'work\x'
    }

    if (-not $ManifestPath) {
        $ManifestPath = Join-Path $toolRoot 'inventory\extraction.json'
    }

    if ($MaxDepth -lt 0 -or $MaxDepth -gt 10) {
        throw 'MaxDepth must be between 0 and 10.'
    }

    $sevenZip = Get-AmdSevenZipPath -ExplicitPath $SevenZipPath
    New-AmdDirectory -Path $OutputDirectory | Out-Null
    $logRoot = Join-Path $toolRoot 'private\l\x'
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
        $releaseKeyValue = [string]$artifact.ReleaseKey
        if (-not $releaseKeyValue) { $releaseKeyValue = $version }
        $artifactKeyValue = [string]$artifact.ArtifactKey
        if (-not $artifactKeyValue) { $artifactKeyValue = ('{0}|{1}' -f $releaseKeyValue, [IO.Path]::GetFileName([string]$artifact.LocalPath)) }
        $installerPath = [string]$artifact.LocalPath
        Write-AmdStep ('Extract [{0}/{1}] {2}' -f $releaseIndex, $releaseTotal, $artifactKeyValue)

        if (-not (Test-Path -LiteralPath $installerPath -PathType Leaf)) {
            $releaseResults.Add([pscustomobject]@{
                ArtifactKey = $artifactKeyValue
                ReleaseKey = $releaseKeyValue
                ReleaseVersion = $version
                PackageFamily = [string]$artifact.PackageFamily
                Branch = [string]$artifact.Branch
                ArtifactRole = [string]$artifact.ArtifactRole
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

        $artifactPathId=('a{0:D4}' -f $releaseIndex)
        $releaseRoot = Get-AmdShortExtractionPath -ArtifactOrdinal $releaseIndex -ExtractionBasePath $OutputDirectory
        $releaseLogRoot = Join-Path $logRoot $artifactPathId

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

            $containerPathId=('c{0:D4}' -f $containerSequence)
            $out = Get-AmdShortExtractionPath -ArtifactOrdinal $releaseIndex -ContainerOrdinal $containerSequence -ExtractionBasePath $OutputDirectory
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

            $archiveProbe = Get-AmdSevenZipArchiveProbe -SevenZipPath $sevenZip -Path $containerPath
            $archivePathSafety=$null
            if($archiveProbe -and $archiveProbe.ContainerLike){
                $archivePathSafety=Get-AmdArchiveExtractionPathAssessment -SevenZipPath $sevenZip -ArchivePath $containerPath -OutputDirectory $out
                if([string]$archivePathSafety.Status -ne 'Pass'){
                    $status='ExtractionBlockedPathSafety'
                    $errorText=('Archive path-safety preflight blocked extraction: {0}' -f (@($archivePathSafety.Issues)-join ' | '))
                    $releaseFailed=$true
                    $releaseErrors.Add(('{0}: {1}' -f $containerPath,$errorText))
                }
            }
            $probe = $null
            if ([System.IO.Path]::GetExtension($containerPath) -ieq '.exe') {
                try {
                    $probe = Get-AmdIsSetupStreamProbe -Path $containerPath
                }
                catch {
                    $probe = $null
                }
            }

            if ($status -eq 'ExtractionBlockedPathSafety') {
                $outputText=@('No extraction was performed because the predicted output path exceeded the fail-closed path policy.')
            }
            elseif ($probe -and $probe.IsSetupStream) {
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

            $analysisSurface = Get-AmdGraphicsAnalysisSurface -Root $out

            $logPath = Join-Path $releaseLogRoot ('{0:D3}-d{1}-{2}-{3}.log' -f $containerSequence, $depth, $extractorType, $containerHash.Substring(0, 12))
            $logLines = New-Object System.Collections.Generic.List[string]
            $logLines.Add(('Container      : {0}' -f $containerPath))
            $logLines.Add(('SHA-256       : {0}' -f $containerHash))
            $logLines.Add(('Depth          : {0}' -f $depth))
            $logLines.Add(('Extractor      : {0}' -f $extractorType))
            $logLines.Add(('Status         : {0}' -f $status))
            if ($null -ne $exitCode) { $logLines.Add(('7-Zip exit    : {0}' -f $exitCode)) }
            if ($null -ne $isSetupType) { $logLines.Add(('ISSetup type   : {0}' -f $isSetupType)) }
            if ($archiveProbe) {
                $logLines.Add(('Archive type   : {0}' -f $archiveProbe.ArchiveType))
                if ($null -ne $archiveProbe.Offset) { $logLines.Add(('Archive offset : {0}' -f $archiveProbe.Offset)) }
                if ($null -ne $archiveProbe.TailSize) { $logLines.Add(('Archive tail   : {0}' -f $archiveProbe.TailSize)) }
            }
            $logLines.Add(('Analysis INF   : drivers={0}; display={1}; reached={2}' -f $analysisSurface.DriverInfCount, $analysisSurface.DisplayInfCount, $analysisSurface.Reached))
            if ($errorText) { $logLines.Add(('Error          : {0}' -f $errorText)) }
            $logLines.Add('')
            foreach ($line in @($outputText)) { $logLines.Add([string]$line) }
            Write-AmdUtf8NoBom -Path $logPath -Text ($logLines.ToArray() -join [Environment]::NewLine)

            $containers.Add([pscustomobject][ordered]@{
                ContainerPathId = $containerPathId
                ContainerPath = $containerPath
                OriginalContainerFileName = [System.IO.Path]::GetFileName($containerPath)
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
                ArchiveProbe = $archiveProbe
                PathSafety = $archivePathSafety
                AnalysisSurface = $analysisSurface
                Error = $errorText
                EvidenceLogPath = $logPath
                Log = ($outputText -join [Environment]::NewLine)
            })

            if ($status -in @('ExtractionFailed','ExtractionBlockedPathSafety') -or $depth -ge $MaxDepth) {
                continue
            }

            # Modern Adrenalin installers are 7z SFX packages whose first
            # extraction already exposes Packages/Drivers/Display/WT6A_INF.
            # Once that canonical graphics analysis surface is present, chasing
            # application MSI files or ordinary helper PE files adds no INF
            # evidence and can create false failures on plugin-limited 7za.
            if ($analysisSurface.Reached) {
                continue
            }

            $nested = @(
                Get-ChildItem -LiteralPath $out -File -Recurse -ErrorAction SilentlyContinue |
                    Where-Object {
                        $ext = $_.Extension.ToLowerInvariant()
                        if ($ext -in @('.msi', '.cab', '.zip', '.7z', '.exe')) {
                            if ($ext -eq '.exe') {
                                try {
                                    $innerProbe = Get-AmdIsSetupStreamProbe -Path $_.FullName
                                    if ($innerProbe.IsSetupStream) { return $true }
                                }
                                catch {
                                }
                            }

                            # Follow only objects that 7-Zip identifies as an
                            # actual container. An ordinary PE executable (Type=PE)
                            # is evidence, not a nested package to unpack.
                            $candidateProbe = Get-AmdSevenZipArchiveProbe -SevenZipPath $sevenZip -Path $_.FullName
                            return [bool]$candidateProbe.ContainerLike
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
            ArtifactPathId = $artifactPathId
            ArtifactKey = $artifactKeyValue
            ReleaseKey = $releaseKeyValue
            ReleaseVersion = $version
            PackageFamily = [string]$artifact.PackageFamily
            Branch = [string]$artifact.Branch
            ArtifactRole = [string]$artifact.ArtifactRole
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
        ToolkitVersion = $script:AmdGraphicsResearchToolkitVersion
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
    $null = Assert-AmdExtractionCompleteSet -Items @($releaseResults.ToArray()) -Context 'Graphics downstream analysis'
}


function New-AmdPayloadPathIndex {
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)][string]$Root)

    $index = @{}
    foreach ($file in @(Get-ChildItem -LiteralPath $Root -File -Recurse -ErrorAction SilentlyContinue)) {
        $relative = (Get-AmdRelativePath -BasePath $Root -Path $file.FullName) -replace '\\','/'
        $lower = $relative.ToLowerInvariant()
        if (-not $index.ContainsKey($lower)) { $index[$lower] = $file.FullName }
        $marker = $lower.IndexOf('/packages/')
        if ($marker -ge 0) {
            $packageRelative = $lower.Substring($marker + 1)
            if (-not $index.ContainsKey($packageRelative)) { $index[$packageRelative] = $file.FullName }
        }
        elseif ($lower.StartsWith('packages/')) {
            if (-not $index.ContainsKey($lower)) { $index[$lower] = $file.FullName }
        }
    }
    return $index
}

function Resolve-AmdInstallManifestPayloadPath {
    [CmdletBinding()]
    param(
        [AllowEmptyString()][string]$ManifestUrl,
        [Parameter(Mandatory = $true)][hashtable]$PathIndex
    )

    if (-not $ManifestUrl) {
        return [pscustomobject]@{ Status='NoUrl'; ManifestUrl=$ManifestUrl; NormalizedKey=$null; Path=$null }
    }
    $normalized = ($ManifestUrl -replace '\\','/').TrimStart('/').ToLowerInvariant()
    if (-not $normalized.StartsWith('packages/')) { $normalized = 'packages/' + $normalized }
    if ($PathIndex.ContainsKey($normalized)) {
        return [pscustomobject]@{ Status='MatchedCaseInsensitive'; ManifestUrl=$ManifestUrl; NormalizedKey=$normalized; Path=[string]$PathIndex[$normalized] }
    }
    return [pscustomobject]@{ Status='NotFound'; ManifestUrl=$ManifestUrl; NormalizedKey=$normalized; Path=$null }
}

function ConvertTo-AmdInstallManifestSummary {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$ExtractionRoot,
        [AllowEmptyString()][string]$ExpectedReleaseVersion
    )

    $data = ConvertFrom-CanonicalJson -Json (Read-AmdTextFile -Path $Path)
    $build = $data.BuildInfo
    $pathIndex = New-AmdPayloadPathIndex -Root $ExtractionRoot
    $packages = New-Object System.Collections.Generic.List[object]
    $typeCounts = @{}

    foreach ($pkg in @($data.Packages.Package)) {
        if ($null -eq $pkg) { continue }
        $info = $pkg.Info
        $install = $pkg.Install
        $ptype = if ($info -and $info.PSObject.Properties['ptype']) { [string]$info.ptype } else { $null }
        if (-not $ptype) { $ptype = 'Unknown' }
        if (-not $typeCounts.ContainsKey($ptype)) { $typeCounts[$ptype] = 0 }
        $typeCounts[$ptype]++

        $url = if ($info -and $info.PSObject.Properties['url']) { [string]$info.url } else { $null }
        $payloadMatch = Resolve-AmdInstallManifestPayloadPath -ManifestUrl $url -PathIndex $pathIndex
        $conditions = if ($install -and $install.PSObject.Properties['Conditions']) { $install.Conditions } else { $null }

        $conditionCounts = [ordered]@{}
        if ($conditions) {
            foreach ($name in @('HWCheck','EnumCheck','OSCheck','OSCheckMinVer','DependencyCheck','DependencyCheckExclude')) {
                if ($conditions.PSObject.Properties[$name]) {
                    $conditionCounts[$name] = @($conditions.$name).Count
                }
            }
        }

        $packages.Add([pscustomobject][ordered]@{
            ProductName = if ($info -and $info.PSObject.Properties['productName']) { [string]$info.productName } else { $null }
            Description = if ($info -and $info.PSObject.Properties['Description']) { [string]$info.Description } else { $null }
            PackageType = $ptype
            Version = if ($info -and $info.PSObject.Properties['version']) { [string]$info.version } else { $null }
            PID = if ($info -and $info.PSObject.Properties['PID']) { [string]$info.PID } else { $null }
            PackageSize = if ($info -and $info.PSObject.Properties['packageSize']) { [string]$info.packageSize } else { $null }
            InstallByDefault = if ($info -and $info.PSObject.Properties['InstallByDefault']) { [string]$info.InstallByDefault } else { $null }
            DriverPackageInfFile = if ($info -and $info.PSObject.Properties['DrivePackageInffile']) { [string]$info.DrivePackageInffile } else { $null }
            UniversalInf = if ($info -and $info.PSObject.Properties['universalinf']) { [string]$info.universalinf } else { $null }
            ManifestUrl = $url
            PayloadMatch = $payloadMatch
            InstallOrder = if ($install -and $install.PSObject.Properties['Order']) { [string]$install.Order } else { $null }
            CmdParameters = if ($install -and $install.PSObject.Properties['CmdParameters']) { [string]$install.CmdParameters } else { $null }
            ConditionEvidenceCounts = [pscustomobject]$conditionCounts
            ConditionEvidenceRaw = $conditions
        })
    }

    $external = if ($build -and $build.PSObject.Properties['ExternalVersion']) { [string]$build.ExternalVersion } else { $null }
    $identityStatus = if (-not $ExpectedReleaseVersion -or -not $external) { 'Unavailable' }
                      elseif ($external -eq $ExpectedReleaseVersion) { 'Match' }
                      else { 'Mismatch' }

    $buildSummary = [ordered]@{}
    foreach ($name in @('ExternalVersion','RadeonSoftwareVersion','Version','BuildVersion','Betaversion','featureLevel','OEM','EnableChipsetInstall','EnableAIBundle','EnableAIQualityImprovement','AthenaUpdatedReleaseVersion')) {
        if ($build -and $build.PSObject.Properties[$name]) { $buildSummary[$name] = $build.$name }
    }

    $typeRows = New-Object System.Collections.Generic.List[object]
    foreach ($key in @($typeCounts.Keys | Sort-Object)) {
        $typeRows.Add([pscustomobject]@{ PackageType=$key; Count=[int]$typeCounts[$key] })
    }

    return [pscustomobject][ordered]@{
        ManifestKind = 'AMDInstallManifest'
        BuildInfo = [pscustomobject]$buildSummary
        ReleaseIdentityCheck = [pscustomobject]@{
            ExpectedReleaseVersion = $ExpectedReleaseVersion
            EmbeddedExternalVersion = $external
            Status = $identityStatus
        }
        PackageCount = $packages.Count
        PackageTypeCounts = $typeRows.ToArray()
        PayloadPathMatchCount = @($packages.ToArray() | Where-Object { $_.PayloadMatch.Status -eq 'MatchedCaseInsensitive' }).Count
        PayloadPathMissingCount = @($packages.ToArray() | Where-Object { $_.PayloadMatch.Status -eq 'NotFound' }).Count
        DisplayDriverPackages = @($packages.ToArray() | Where-Object { $_.ProductName -eq 'AMD Display Driver' -or $_.ManifestUrl -match '(?i)Drivers[\\/]Display[\\/]' })
        Packages = $packages.ToArray()
    }
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

    foreach ($release in @(Get-AmdCollectionItems -Value $Extraction.Releases)) {
        $version = [string]$release.ReleaseVersion
        $releaseKeyValue = [string]$release.ReleaseKey
        if (-not $releaseKeyValue) { $releaseKeyValue = $version }
        $artifactKeyValue = [string]$release.ArtifactKey
        if (-not $artifactKeyValue) { $artifactKeyValue = $releaseKeyValue }
        $root = [string]$release.ExtractionRoot
        $sources = New-Object System.Collections.Generic.List[object]
        $errors = New-Object System.Collections.Generic.List[string]

        if (-not $root -or -not (Test-Path -LiteralPath $root -PathType Container)) {
            $releaseRecords.Add([pscustomobject][ordered]@{
                ArtifactKey = $artifactKeyValue; ReleaseKey = $releaseKeyValue; ReleaseVersion = $version
                PackageFamily = [string]$release.PackageFamily; Branch = [string]$release.Branch; ArtifactRole = [string]$release.ArtifactRole
                Status = 'NotInspected'; ExtractionRoot = $root; CandidateMetadataFileCount = 0
                InstallManifestSummary = $null; Sources = @(); Errors = @('Extraction root is unavailable.')
            })
            continue
        }

        $candidateFiles = @(
            Get-ChildItem -LiteralPath $root -File -Recurse -ErrorAction SilentlyContinue |
                Where-Object {
                    $leaf = $_.Name
                    $leaf -match '(?i)^(?:Info|DevID|InstallManifest|PackageManifest.*|Manifest.*|Config.*|Setup.*Manifest.*)\.(?:xml|json)$'
                } |
                Sort-Object FullName
        )

        $installManifestSummary = $null
        foreach ($file in $candidateFiles) {
            $relative = Get-AmdRelativePath -BasePath $root -Path $file.FullName
            $format = [System.IO.Path]::GetExtension($file.Name).TrimStart('.').ToUpperInvariant()
            $parseStatus = 'Recorded'
            $parseError = $null
            $semanticKind = $null
            try {
                $fileText = [System.IO.File]::ReadAllText($file.FullName)
                if ($format -eq 'XML') {
                    $null = ConvertFrom-AmdXmlText -Text $fileText -Source $relative
                    $parseStatus = 'FormatValidated'
                }
                elseif ($format -eq 'JSON') {
                    $parsedJson = ConvertFrom-CanonicalJson -Json $fileText
                    $parseStatus = 'FormatValidated'
                    if ($file.Name -ieq 'InstallManifest.json' -and
                        $parsedJson.PSObject.Properties['BuildInfo'] -and
                        $parsedJson.PSObject.Properties['Packages']) {
                        $semanticKind = 'AMDInstallManifest'
                        $installManifestSummary = ConvertTo-AmdInstallManifestSummary -Path $file.FullName -ExtractionRoot $root -ExpectedReleaseVersion $version
                        $parseStatus = 'SemanticallyParsed'
                    }
                }
            }
            catch {
                $parseStatus = 'ParseFailed'
                $parseError = $_.Exception.Message
                $errors.Add(('{0} parse failed ({1}): {2}' -f $format, $relative, $_.Exception.Message))
            }

            $sources.Add([pscustomobject][ordered]@{
                Path = $file.FullName; RelativePath = $relative; FileName = $file.Name; Format = $format
                SemanticKind = $semanticKind; SizeBytes = [int64]$file.Length; Sha256 = Get-AmdSha256 -Path $file.FullName
                ParseStatus = $parseStatus; ParseError = $parseError
            })
        }

        $status = if ($candidateFiles.Count -eq 0) { 'NotPresent' }
                  elseif ($errors.Count -gt 0) { 'RecordedWithErrors' }
                  else { 'Recorded' }

        $releaseRecords.Add([pscustomobject][ordered]@{
            ArtifactKey = $artifactKeyValue; ReleaseKey = $releaseKeyValue; ReleaseVersion = $version
            PackageFamily = [string]$release.PackageFamily; Branch = [string]$release.Branch; ArtifactRole = [string]$release.ArtifactRole
            Status = $status; ExtractionRoot = $root; CandidateMetadataFileCount = $sources.Count
            InstallManifestSummary = $installManifestSummary; Sources = $sources.ToArray(); Errors = $errors.ToArray()
        })
    }

    $output = [pscustomobject][ordered]@{
        SchemaVersion = '2.1'
        ToolkitVersion = $script:AmdGraphicsResearchToolkitVersion
        GeneratedAtUtc = [DateTime]::UtcNow.ToString('o')
        Purpose = 'EmbeddedInstallerMetadataEvidence'
        InterpretationPolicy = 'Embedded facts are retained separately; InstallManifest semantics are parsed but never promoted into published or payload-observed layers.'
        Releases = $releaseRecords.ToArray()
    }

    Write-AmdJsonFile -Path $OutputPath -Value $output
    Write-Host ('Embedded metadata artifacts: {0}' -f $releaseRecords.Count)
    Write-Host ('Embedded metadata output   : {0}' -f $OutputPath)
    return $output
}

function Get-AmdGraphicsSourceVariant {
    [CmdletBinding()]
    param([AllowEmptyString()][string]$RelativePath)
    foreach($segment in @($RelativePath -split '[\\/]')) {
        $u=$segment.ToUpperInvariant()
        if($u -eq 'WT6A_INF' -or $u.EndsWith('_WT6A_INF') -or $u.EndsWith('-WT6A_INF')){return 'WT6A_INF'}
        if($u -eq 'WT64A' -or $u.EndsWith('_WT64A') -or $u.EndsWith('-WT64A')){return 'WT64A'}
        if($u -match '^U\d+_INF$'){return $u}
    }
    return 'Unknown'
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
    Write-AmdStep 'Recording candidate embedded graphics installer metadata files.'
    $embeddedInspection = Invoke-AmdEmbeddedMetadataInspection -Extraction $extraction -OutputPath $embeddedMetadataPath

    # Driver analysis can become very large when many historical artifacts are inspected.
    # Keep one compact detail JSON per artifact and make driver-packages.json a lightweight
    # index. This bounds ConvertTo-Json/ConvertFrom-Json memory use on Windows PowerShell 5.1.
    $detailRoot = Join-Path $toolRoot 'inventory\driver-packages-artifacts'
    if (Test-Path -LiteralPath $detailRoot) { Remove-Item -LiteralPath $detailRoot -Recurse -Force }
    New-AmdDirectory -Path $detailRoot | Out-Null
    $driverIndexRows = New-Object System.Collections.Generic.List[object]
    $driverPackageTotal = 0
    $kmdfTotal = 0
    $umdfTotal = 0

    $releaseItems = @($extraction.Releases)
    $releaseTotal = $releaseItems.Count
    $releaseIndex = 0

    Write-AmdStep ('Inspecting INF packages for {0} release(s).' -f $releaseTotal)

    foreach ($release in $releaseItems) {
        $releaseIndex++
        $itemSw = [System.Diagnostics.Stopwatch]::StartNew()
        $version = [string]$release.ReleaseVersion
        $releaseKeyValue = [string]$release.ReleaseKey
        if (-not $releaseKeyValue) { $releaseKeyValue = $version }
        $artifactKeyValue = [string]$release.ArtifactKey
        if (-not $artifactKeyValue) { $artifactKeyValue = $releaseKeyValue }
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
        $artifactDriverRecords = New-Object System.Collections.Generic.List[object]

        foreach ($inf in $infFiles) {
            try {
                $lines = [System.IO.File]::ReadAllLines($inf.FullName)
                $stringTable = Get-AmdInfStringTable -Lines $lines

                $providerRaw = Get-AmdInfVersionSectionValue -Lines $lines -Name 'Provider'
                $classRaw = Get-AmdInfVersionSectionValue -Lines $lines -Name 'Class'
                $classGuidRaw = Get-AmdInfVersionSectionValue -Lines $lines -Name 'ClassGuid'
                $driverVerRaw = Get-AmdInfVersionSectionValue -Lines $lines -Name 'DriverVer'
                $catalogFileRaw = Get-AmdInfVersionSectionValue -Lines $lines -Name 'CatalogFile'
                $provider = (Resolve-AmdInfStringValue -Value $providerRaw -StringTable $stringTable).ResolvedValue
                $class = (Resolve-AmdInfStringValue -Value $classRaw -StringTable $stringTable).ResolvedValue
                $classGuid = (Resolve-AmdInfStringValue -Value $classGuidRaw -StringTable $stringTable).ResolvedValue
                $driverVer = (Resolve-AmdInfStringValue -Value $driverVerRaw -StringTable $stringTable).ResolvedValue
                $catalogFile = (Resolve-AmdInfStringValue -Value $catalogFileRaw -StringTable $stringTable).ResolvedValue

                $kmdfEvidence = @(Get-AmdInfDirectiveValue -Lines $lines -Directive 'KmdfLibraryVersion')
                $umdfEvidence = @(Get-AmdInfDirectiveValue -Lines $lines -Directive 'UmdfLibraryVersion')
                $serviceBinaryEvidence = @(Get-AmdInfDirectiveValue -Lines $lines -Directive 'ServiceBinary')
                $addServiceEvidence = @(Get-AmdInfDirectiveValue -Lines $lines -Directive 'AddService')
                $serviceNames = @($addServiceEvidence | ForEach-Object { @((Split-AmdInfCsv -Text ([string]$_.RawValue)))[0].Trim().Trim('"') } | Where-Object { $_ } | Sort-Object -Unique)
                if ($kmdfEvidence.Count -gt 0) { $releaseKmdfDeclared++ }
                if ($umdfEvidence.Count -gt 0) { $releaseUmdfDeclared++ }

                foreach ($ev in @($kmdfEvidence + $umdfEvidence)) {
                    $resolvedDirective = Resolve-AmdInfStringValue -Value ([string]$ev.RawValue) -StringTable $stringTable
                    $ev | Add-Member -NotePropertyName ResolvedValue -NotePropertyValue $resolvedDirective.ResolvedValue -Force
                    $ev | Add-Member -NotePropertyName ResolutionStatus -NotePropertyValue $resolvedDirective.Status -Force
                    $ev | Add-Member -NotePropertyName UnresolvedTokens -NotePropertyValue @($resolvedDirective.UnresolvedTokens) -Force
                }

                $kmdfVersions = @(
                    $kmdfEvidence |
                        ForEach-Object { if ($_.PSObject.Properties['ResolvedValue']) { $_.ResolvedValue } else { $_.RawValue } } |
                        Where-Object { $_ } |
                        Sort-Object -Unique
                )

                $umdfVersions = @(
                    $umdfEvidence |
                        ForEach-Object { if ($_.PSObject.Properties['ResolvedValue']) { $_.ResolvedValue } else { $_.RawValue } } |
                        Where-Object { $_ } |
                        Sort-Object -Unique
                )

                $hardwareIds = @(Get-AmdInfHardwareIds -Lines $lines)
                $manufacturerTargeting = Get-AmdInfManufacturerTargeting -Lines $lines -StringTable $stringTable
                $infTopology = Get-AmdInfTopology -ManufacturerTargeting $manufacturerTargeting
                $windowsServerAnalysis = Get-AmdWindowsServerInfAnalysis -InfTopology $infTopology -KmdfVersions $kmdfVersions -UmdfVersions $umdfVersions

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
                $componentInfo = Get-AmdGraphicsDriverComponent -RelativePath $relativePath

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

                $artifactDriverRecords.Add([pscustomobject]@{
                    ArtifactKey = $artifactKeyValue
                    ReleaseKey = $releaseKeyValue
                    ReleaseVersion = $version
                    PackageFamily = [string]$release.PackageFamily
                    Branch = [string]$release.Branch
                    ArtifactRole = [string]$release.ArtifactRole
                    InspectionStatus = 'Inspected'
                    InspectionError = $null
                    InfPath = $inf.FullName
                    InfRelativePath = $relativePath
                    SourceVariant = Get-AmdGraphicsSourceVariant -RelativePath $relativePath
                    DriverComponent = $componentInfo
                    InfSha256 = Get-AmdSha256 -Path $inf.FullName

                    VersionSection = [pscustomobject]@{
                        Provider = $provider
                        Class = $class
                        ClassGuid = $classGuid
                        DriverVerRaw = $driverVerRaw
                        DriverDate = $driverDate
                        DriverVersion = $driverVersion
                        CatalogFileRaw = $catalogFileRaw
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
                    Services = [pscustomobject]@{ Names=@($serviceNames); AddServiceEvidence=@($addServiceEvidence) }
                    InfTargeting = $manufacturerTargeting
                    InfTopology = $infTopology
                    WindowsServerAnalysis = @($windowsServerAnalysis)
                    ServiceBinaries = $serviceBinaries.ToArray()
                })
            }
            catch {
                $releaseParseFailed++
                $artifactDriverRecords.Add([pscustomobject]@{
                    ArtifactKey = $artifactKeyValue
                    ReleaseKey = $releaseKeyValue
                    ReleaseVersion = $version
                    PackageFamily = [string]$release.PackageFamily
                    Branch = [string]$release.Branch
                    ArtifactRole = [string]$release.ArtifactRole
                    InspectionStatus = 'ParseFailed'
                    InspectionError = $_.Exception.Message
                    InfPath = $inf.FullName
                    InfRelativePath = $null
                    SourceVariant = 'Unknown'
                    InfSha256 = $null
                    VersionSection = $null
                    Wdf = $null
                    HardwareIds = @()
                    Services = $null
                    InfTargeting = $null
                    InfTopology = $null
                    WindowsServerAnalysis = @()
                    ServiceBinaries = @()
                })
            }
        }

        $artifactLeaf = ([string]$artifactKeyValue -split '\|')[-1]
        $versionLeaf = ConvertTo-AmdSafePathLeaf -Value $version
        $artifactStem = ConvertTo-AmdSafePathLeaf -Value ([System.IO.Path]::GetFileNameWithoutExtension($artifactLeaf))
        $detailDir = Join-Path $detailRoot $versionLeaf
        New-AmdDirectory -Path $detailDir | Out-Null
        $detailPath = Join-Path $detailDir ($artifactStem + '.json')
        $detailOutput = [pscustomobject][ordered]@{
            SchemaVersion='amd-graphics-driver-packages-artifact/1.0'
            ToolkitVersion=$script:AmdGraphicsResearchToolkitVersion
            GeneratedAtUtc=[DateTime]::UtcNow.ToString('o')
            ArtifactKey=$artifactKeyValue
            ReleaseKey=$releaseKeyValue
            ReleaseVersion=$version
            PackageFamily=[string]$release.PackageFamily
            Branch=[string]$release.Branch
            ArtifactRole=[string]$release.ArtifactRole
            DriverPackageCount=$artifactDriverRecords.Count
            ParseFailureCount=$releaseParseFailed
            KmdfDeclarationCount=$releaseKmdfDeclared
            UmdfDeclarationCount=$releaseUmdfDeclared
            DriverPackages=$artifactDriverRecords.ToArray()
        }
        Write-AmdJsonFile -Path $detailPath -Value $detailOutput
        $detailItem = Get-Item -LiteralPath $detailPath
        $detailSha256 = Get-AmdSha256 -Path $detailPath
        $detailRelative = Get-AmdRelativePath -BasePath $toolRoot -Path $detailPath
        $driverIndexRows.Add([pscustomobject][ordered]@{
            ArtifactKey=$artifactKeyValue;ReleaseKey=$releaseKeyValue;ReleaseVersion=$version
            PackageFamily=[string]$release.PackageFamily;Branch=[string]$release.Branch;ArtifactRole=[string]$release.ArtifactRole
            InspectionStatus=if($releaseParseFailed -gt 0){'Partial'}else{'Inspected'}
            DriverPackageCount=$artifactDriverRecords.Count;ParseFailureCount=$releaseParseFailed
            KmdfDeclarationCount=$releaseKmdfDeclared;UmdfDeclarationCount=$releaseUmdfDeclared
            DetailJson=$detailRelative;DetailJsonSha256=$detailSha256;DetailJsonSizeBytes=[int64]$detailItem.Length
        })
        $driverPackageTotal += $artifactDriverRecords.Count
        $kmdfTotal += $releaseKmdfDeclared
        $umdfTotal += $releaseUmdfDeclared

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

    $output = [pscustomobject][ordered]@{
        SchemaVersion='amd-graphics-driver-packages-index/3.1'
        ToolkitVersion=$script:AmdGraphicsResearchToolkitVersion
        GeneratedAtUtc=[DateTime]::UtcNow.ToString('o')
        AnalysisPolicy='StaticWindowsServerEligibilityNotRuntimeCompatibility'
        StorageModel='PerArtifactDetailJson'
        ArtifactCount=$driverIndexRows.Count
        DriverPackageCount=$driverPackageTotal
        KmdfDeclarationCount=$kmdfTotal
        UmdfDeclarationCount=$umdfTotal
        Artifacts=$driverIndexRows.ToArray()
    }

    Write-AmdJsonFile -Path $OutputPath -Value $output
    $shardIntegrity = Test-AmdDriverPackageShardIntegrity -DriverPackagesPath $OutputPath -OutputPath (Join-Path $toolRoot 'inventory\driver-packages-integrity.json')
    if ([string]$shardIntegrity.Status -ne 'Pass') {
        throw ('Driver-package shard integrity validation failed with {0} error(s). See inventory/driver-packages-integrity.json.' -f @($shardIntegrity.Errors).Count)
    }

    Write-Host ('INF files inspected : {0}' -f $driverPackageTotal)
    Write-Host ('KMDF declarations   : {0}' -f $kmdfTotal)
    Write-Host ('UMDF declarations   : {0}' -f $umdfTotal)
    Write-Host ('Artifact detail JSON: {0}' -f $detailRoot)
    Write-Host ('Output index        : {0}' -f $OutputPath)

}



function Test-AmdDriverPackageShardIntegrity {
    [CmdletBinding()]
    param(
        [string]$DriverPackagesPath,
        [string]$OutputPath
    )

    $root = Get-AmdResearchToolkitRoot
    if (-not $DriverPackagesPath) { $DriverPackagesPath = Join-Path $root 'inventory\driver-packages.json' }
    if (-not $OutputPath) { $OutputPath = Join-Path $root 'inventory\driver-packages-integrity.json' }

    $errors = New-Object System.Collections.Generic.List[string]
    $artifactResults = New-Object System.Collections.Generic.List[object]
    $seenArtifactKeys = @{}
    $seenDetailPaths = @{}
    $driverTotal = 0
    $parseFailureTotal = 0
    $kmdfTotal = 0
    $umdfTotal = 0

    if (-not (Test-Path -LiteralPath $DriverPackagesPath -PathType Leaf)) {
        $errors.Add(('driver package index is missing: {0}' -f $DriverPackagesPath))
        $index = $null
    }
    else {
        $index = Read-AmdJsonFile -Path $DriverPackagesPath
    }

    if ($index) {
        if (-not (Test-AmdSupportedDriverPackageIndexSchema -SchemaVersion ([string]$index.SchemaVersion))) {
            $errors.Add(('unsupported driver package index schema [{0}]' -f [string]$index.SchemaVersion))
        }

        foreach ($ref in @(Get-AmdCollectionItems -Value $index.Artifacts)) {
            $artifactKey = [string]$ref.ArtifactKey
            $detailRelative = [string]$ref.DetailJson
            if (-not $artifactKey) { $errors.Add('index contains an empty ArtifactKey'); continue }
            if ($seenArtifactKeys.ContainsKey($artifactKey)) { $errors.Add(('duplicate ArtifactKey in index: {0}' -f $artifactKey)) } else { $seenArtifactKeys[$artifactKey]=$true }
            if (-not $detailRelative) { $errors.Add(('DetailJson is empty for {0}' -f $artifactKey)); continue }
            $detailPath = $detailRelative
            if (-not [System.IO.Path]::IsPathRooted($detailPath)) { $detailPath = Join-Path $root $detailPath }
            $detailPathKey = ([System.IO.Path]::GetFullPath($detailPath)).ToLowerInvariant()
            if ($seenDetailPaths.ContainsKey($detailPathKey)) { $errors.Add(('duplicate DetailJson reference: {0}' -f $detailRelative)) } else { $seenDetailPaths[$detailPathKey]=$true }

            if (-not (Test-Path -LiteralPath $detailPath -PathType Leaf)) {
                $errors.Add(('detail JSON is missing for {0}: {1}' -f $artifactKey,$detailRelative))
                continue
            }

            try {
                $detailItem = Get-Item -LiteralPath $detailPath
                $detailSha = Get-AmdSha256 -Path $detailPath
                if ($ref.PSObject.Properties['DetailJsonSha256'] -and $ref.DetailJsonSha256 -and ([string]$ref.DetailJsonSha256 -ne $detailSha)) {
                    $errors.Add(('detail SHA-256 mismatch for {0}' -f $artifactKey))
                }
                if ($ref.PSObject.Properties['DetailJsonSizeBytes'] -and [int64]$ref.DetailJsonSizeBytes -ne [int64]$detailItem.Length) {
                    $errors.Add(('detail size mismatch for {0}' -f $artifactKey))
                }

                $detail = Read-AmdJsonFile -Path $detailPath
                if ([string]$detail.SchemaVersion -ne 'amd-graphics-driver-packages-artifact/1.0') { $errors.Add(('unsupported detail schema for {0}: {1}' -f $artifactKey,[string]$detail.SchemaVersion)) }
                if ([string]$detail.ArtifactKey -ne $artifactKey) { $errors.Add(('ArtifactKey mismatch between index and detail: {0}' -f $artifactKey)) }
                if ([string]$detail.ReleaseKey -ne [string]$ref.ReleaseKey) { $errors.Add(('ReleaseKey mismatch between index and detail: {0}' -f $artifactKey)) }

                $drivers = @($detail.DriverPackages)
                $detailDriverCount = $drivers.Count
                $detailParseFailures = @($drivers | Where-Object { $_.InspectionStatus -eq 'ParseFailed' }).Count
                $detailKmdf = @($drivers | Where-Object { $_.Wdf -and $_.Wdf.KMDF -and $_.Wdf.KMDF.Status -eq 'Declared' }).Count
                $detailUmdf = @($drivers | Where-Object { $_.Wdf -and $_.Wdf.UMDF -and $_.Wdf.UMDF.Status -eq 'Declared' }).Count

                if ([int]$ref.DriverPackageCount -ne $detailDriverCount) { $errors.Add(('driver count mismatch for {0}: index={1}, detail={2}' -f $artifactKey,[int]$ref.DriverPackageCount,$detailDriverCount)) }
                if ([int]$ref.ParseFailureCount -ne $detailParseFailures) { $errors.Add(('parse-failure count mismatch for {0}: index={1}, detail={2}' -f $artifactKey,[int]$ref.ParseFailureCount,$detailParseFailures)) }
                if ([int]$ref.KmdfDeclarationCount -ne $detailKmdf) { $errors.Add(('KMDF declaration count mismatch for {0}: index={1}, detail={2}' -f $artifactKey,[int]$ref.KmdfDeclarationCount,$detailKmdf)) }
                if ([int]$ref.UmdfDeclarationCount -ne $detailUmdf) { $errors.Add(('UMDF declaration count mismatch for {0}: index={1}, detail={2}' -f $artifactKey,[int]$ref.UmdfDeclarationCount,$detailUmdf)) }

                $driverTotal += $detailDriverCount
                $parseFailureTotal += $detailParseFailures
                $kmdfTotal += $detailKmdf
                $umdfTotal += $detailUmdf
                $artifactResults.Add([pscustomobject][ordered]@{
                    ArtifactKey=$artifactKey;DetailJson=$detailRelative;DetailJsonSha256=$detailSha;DetailJsonSizeBytes=[int64]$detailItem.Length
                    DriverPackageCount=$detailDriverCount;ParseFailureCount=$detailParseFailures;KmdfDeclarationCount=$detailKmdf;UmdfDeclarationCount=$detailUmdf
                })
                Remove-Variable detail,drivers -ErrorAction SilentlyContinue
            }
            catch {
                $errors.Add(('detail validation failed for {0}: {1}' -f $artifactKey,$_.Exception.Message))
            }
        }

        if ([int]$index.ArtifactCount -ne @(Get-AmdCollectionItems -Value $index.Artifacts).Count) { $errors.Add(('ArtifactCount mismatch: index={0}, entries={1}' -f [int]$index.ArtifactCount,@(Get-AmdCollectionItems -Value $index.Artifacts).Count)) }
        if ([int]$index.DriverPackageCount -ne $driverTotal) { $errors.Add(('DriverPackageCount mismatch: index={0}, details={1}' -f [int]$index.DriverPackageCount,$driverTotal)) }
        if ([int]$index.KmdfDeclarationCount -ne $kmdfTotal) { $errors.Add(('KmdfDeclarationCount mismatch: index={0}, details={1}' -f [int]$index.KmdfDeclarationCount,$kmdfTotal)) }
        if ([int]$index.UmdfDeclarationCount -ne $umdfTotal) { $errors.Add(('UmdfDeclarationCount mismatch: index={0}, details={1}' -f [int]$index.UmdfDeclarationCount,$umdfTotal)) }
    }

    $result = [pscustomobject][ordered]@{
        SchemaVersion='amd-graphics-driver-packages-integrity/1.0';ToolkitVersion=$script:AmdGraphicsResearchToolkitVersion;GeneratedAtUtc=[DateTime]::UtcNow.ToString('o')
        Status=if($errors.Count -eq 0){'Pass'}else{'Fail'};IndexSchemaVersion=if($index){[string]$index.SchemaVersion}else{$null}
        ArtifactCount=if($index){[int]$index.ArtifactCount}else{0};DriverPackageCount=$driverTotal;ParseFailureCount=$parseFailureTotal
        KmdfDeclarationCount=$kmdfTotal;UmdfDeclarationCount=$umdfTotal;Errors=$errors.ToArray();Artifacts=$artifactResults.ToArray()
    }
    Write-AmdJsonFile -Path $OutputPath -Value $result
    return $result
}

function ConvertTo-AmdLightweightServerAggregateRow {
    [CmdletBinding()]
    param([Parameter(Mandatory=$true)][object]$Row)

    $asCount = if($Row.PSObject.Properties['AsPublishedHardwareIdCount']){[int]$Row.AsPublishedHardwareIdCount}elseif($Row.PSObject.Properties['AsPublishedHardwareIds']){@($Row.AsPublishedHardwareIds).Count}else{0}
    $projectionCount = if($Row.PSObject.Properties['ProjectionHardwareIdCount']){[int]$Row.ProjectionHardwareIdCount}elseif($Row.PSObject.Properties['ProjectionHardwareIds']){@($Row.ProjectionHardwareIds).Count}else{0}
    $canonicalAssessment = if($Row.PSObject.Properties['CanonicalStaticAssessment'] -and $Row.CanonicalStaticAssessment){[string]$Row.CanonicalStaticAssessment}else{switch([string]$Row.StaticAssessment){'NATIVE_CANDIDATE'{'NativeCandidate'}'PATCH_CANDIDATE'{'ProjectionCandidate'}'REVIEW_REQUIRED'{'ReviewRequired'}'NOT_APPLICABLE'{'NotApplicable'}default{'Indeterminate'}}}
    $wdfScope = if($Row.PSObject.Properties['WdfScope'] -and $Row.WdfScope){[string]$Row.WdfScope}elseif($Row.PSObject.Properties['Wdf'] -and $Row.Wdf -and $Row.Wdf.PSObject.Properties['Scope']){[string]$Row.Wdf.Scope}else{'InfWideConservative'}
    $kmdfDeclared=@();$kmdfDocumented=$null;$kmdfObserved=$null;$umdfDeclared=@()
    if($Row.PSObject.Properties['KMDFDeclared']){$kmdfDeclared=@(Get-AmdCollectionItems -Value $Row.KMDFDeclared)}elseif($Row.PSObject.Properties['Wdf'] -and $Row.Wdf -and $Row.Wdf.KMDF){$kmdfDeclared=@(Get-AmdCollectionItems -Value $Row.Wdf.KMDF.DeclaredVersions);$kmdfDocumented=$Row.Wdf.KMDF.DocumentedReference;$kmdfObserved=$Row.Wdf.KMDF.ObservedReference}
    if($Row.PSObject.Properties['KMDFDocumented']){$kmdfDocumented=$Row.KMDFDocumented}
    if($Row.PSObject.Properties['KMDFObserved']){$kmdfObserved=$Row.KMDFObserved}
    if($Row.PSObject.Properties['UMDFDeclared']){$umdfDeclared=@(Get-AmdCollectionItems -Value $Row.UMDFDeclared)}elseif($Row.PSObject.Properties['Wdf'] -and $Row.Wdf -and $Row.Wdf.UMDF){$umdfDeclared=@(Get-AmdCollectionItems -Value $Row.Wdf.UMDF.DeclaredVersions)}
    $manifestCount=if($Row.PSObject.Properties['ManifestMatchCount']){[int]$Row.ManifestMatchCount}elseif($Row.PSObject.Properties['ManifestPackageEvidence']){@($Row.ManifestPackageEvidence).Count}else{0}

    return [pscustomobject][ordered]@{
        ReleaseKey=[string]$Row.ReleaseKey;ReleaseVersion=[string]$Row.ReleaseVersion;PackageFamily=[string]$Row.PackageFamily;Branch=[string]$Row.Branch
        ArtifactKey=[string]$Row.ArtifactKey;ArtifactRole=[string]$Row.ArtifactRole;DriverComponent=$Row.DriverComponent;InfRelativePath=$Row.InfRelativePath;InfSha256=$Row.InfSha256
        Server=$Row.Server;ShortName=$Row.ShortName;BaseBuild=$Row.BaseBuild;ProductType=$Row.ProductType
        AsPublishedStatus=$Row.AsPublishedStatus;ProjectionStatus=$Row.ProjectionStatus;StaticAssessment=$Row.StaticAssessment;CanonicalStaticAssessment=$canonicalAssessment
        Confidence=$Row.Confidence;RuntimeCompatibility=$Row.RuntimeCompatibility;RuntimeCompatibilityProven=if($Row.PSObject.Properties['RuntimeCompatibilityProven']){[bool]$Row.RuntimeCompatibilityProven}else{$false};WdfScope=$wdfScope
        AsPublishedModelsSections=if($Row.PSObject.Properties['AsPublishedModelsSections']){@($Row.AsPublishedModelsSections)}else{@()};ProjectionModelsSections=if($Row.PSObject.Properties['ProjectionModelsSections']){@($Row.ProjectionModelsSections)}else{@()}
        AsPublishedHardwareIdCount=$asCount;ProjectionHardwareIdCount=$projectionCount
        KMDFDeclared=@($kmdfDeclared);KMDFDocumented=$kmdfDocumented;KMDFObserved=$kmdfObserved;UMDFDeclared=@($umdfDeclared);ManifestMatchCount=$manifestCount
    }
}

function Test-AmdBuildAggregateIntegrity {
    [CmdletBinding()]
    param([string]$DriverPackagesPath,[string]$OutputPath)
    $root=Get-AmdResearchToolkitRoot
    if(-not $DriverPackagesPath){$DriverPackagesPath=Join-Path $root 'inventory\driver-packages.json'}
    if(-not $OutputPath){$OutputPath=Join-Path $root 'inventory\build-integrity.json'}
    $errors=New-Object System.Collections.Generic.List[string]
    try{$current=Read-AmdJsonFile -Path $DriverPackagesPath}catch{$current=$null;$errors.Add(('unable to read current driver index: {0}' -f $_.Exception.Message))}
    try{$summary=Read-AmdJsonFile -Path (Join-Path $root 'inventory\all-releases-summary.json')}catch{$summary=$null;$errors.Add(('unable to read all-releases-summary.json: {0}' -f $_.Exception.Message))}
    try{$topology=Read-AmdJsonFile -Path (Join-Path $root 'inventory\inf-topology.json')}catch{$topology=$null;$errors.Add(('unable to read inf-topology.json: {0}' -f $_.Exception.Message))}
    try{$server=Read-AmdJsonFile -Path (Join-Path $root 'inventory\windows-server-compatibility-analysis.json')}catch{$server=$null;$errors.Add(('unable to read windows-server-compatibility-analysis.json: {0}' -f $_.Exception.Message))}

    $summaryKeys=@{};$topologyKeys=@{};$serverKeys=@{}
    $summaryDriverCount=0
    if($summary){
        foreach($a in @(Get-AmdCollectionItems -Value $summary.Artifacts)){if($a.ArtifactKey){$summaryKeys[[string]$a.ArtifactKey]=$true};$summaryDriverCount += [int]$a.DriverCount}
        if([int]$summary.ArtifactCount -ne @(Get-AmdCollectionItems -Value $summary.Artifacts).Count){$errors.Add('all-releases-summary ArtifactCount does not match artifact entries')}
        if([int]$summary.DriverCount -ne $summaryDriverCount){$errors.Add(('all-releases-summary DriverCount mismatch: declared={0}, summed={1}' -f [int]$summary.DriverCount,$summaryDriverCount))}
    }
    if($topology){
        foreach($a in @(Get-AmdCollectionItems -Value $topology.Artifacts)){if($a.ArtifactKey){$topologyKeys[[string]$a.ArtifactKey]=$true}}
        if([int]$topology.ArtifactCount -ne @(Get-AmdCollectionItems -Value $topology.Artifacts).Count){$errors.Add('inf-topology ArtifactCount does not match artifact entries')}
        if($summary -and [int]$topology.DriverCount -ne [int]$summary.DriverCount){$errors.Add(('inf-topology DriverCount differs from all-releases-summary: topology={0}, summary={1}' -f [int]$topology.DriverCount,[int]$summary.DriverCount))}
    }
    if($server){
        foreach($r in @(Get-AmdCollectionItems -Value $server.Rows)){if($r.ArtifactKey){$serverKeys[[string]$r.ArtifactKey]=$true}}
        if([int]$server.RowCount -ne @(Get-AmdCollectionItems -Value $server.Rows).Count){$errors.Add('windows-server analysis RowCount does not match row entries')}
        $profileCount=@(Get-AmdCollectionItems -Value $server.ServerProfiles).Count
        if($summary -and $profileCount -gt 0){
            $expected=[int]$summary.DriverCount*$profileCount
            if([int]$server.RowCount -ne $expected){$errors.Add(('windows-server row count mismatch: expected={0}, actual={1}' -f $expected,[int]$server.RowCount))}
        }
    }
    foreach($key in @($summaryKeys.Keys)){
        if(-not $topologyKeys.ContainsKey($key)){$errors.Add(('artifact missing from inf-topology aggregate: {0}' -f $key))}
        if(-not $serverKeys.ContainsKey($key)){$errors.Add(('artifact missing from windows-server aggregate: {0}' -f $key))}
    }
    if($current){foreach($a in @(Get-AmdCollectionItems -Value $current.Artifacts)){if($a.ArtifactKey -and -not $summaryKeys.ContainsKey([string]$a.ArtifactKey)){$errors.Add(('current artifact missing from cumulative summary: {0}' -f [string]$a.ArtifactKey))}}}

    $result=[pscustomobject][ordered]@{
        SchemaVersion='amd-graphics-build-integrity/1.0';ToolkitVersion=$script:AmdGraphicsResearchToolkitVersion;GeneratedAtUtc=[DateTime]::UtcNow.ToString('o')
        Status=if($errors.Count -eq 0){'Pass'}else{'Fail'};CurrentArtifactCount=if($current){[int]$current.ArtifactCount}else{0};CurrentDriverCount=if($current){[int]$current.DriverPackageCount}else{0}
        CumulativeArtifactCount=if($summary){[int]$summary.ArtifactCount}else{0};CumulativeDriverCount=if($summary){[int]$summary.DriverCount}else{0}
        TopologyArtifactCount=if($topology){[int]$topology.ArtifactCount}else{0};ServerRowCount=if($server){[int]$server.RowCount}else{0};ServerProfileCount=if($server){@(Get-AmdCollectionItems -Value $server.ServerProfiles).Count}else{0}
        Errors=$errors.ToArray()
    }
    Write-AmdJsonFile -Path $OutputPath -Value $result
    return $result
}

function ConvertTo-AmdSafePathLeaf {
    [CmdletBinding()]
    param([AllowEmptyString()][string]$Value,[string]$Fallback='artifact')
    if ([string]::IsNullOrWhiteSpace($Value)) { return $Fallback }
    $v=$Value.ToLowerInvariant()
    $v=[regex]::Replace($v,'[^a-z0-9._-]+','-').Trim('-','.')
    if(-not $v){return $Fallback}
    if($v.Length -gt 120){$v=$v.Substring(0,120).Trim('-','.')}
    return $v
}

function Get-AmdManifestMatchesForDriver {
    [CmdletBinding()]
    param([Parameter(Mandatory=$true)][object[]]$ManifestPackages,[Parameter(Mandatory=$true)][object]$Driver)
    $leaf=if($Driver.InfRelativePath){[System.IO.Path]::GetFileName([string]$Driver.InfRelativePath)}else{$null}
    if(-not $leaf){return @()}
    return @($ManifestPackages|Where-Object{($_.DriverPackageInfFile -and ([string]$_.DriverPackageInfFile -ieq $leaf)) -or ($_.ManifestUrl -and ([System.IO.Path]::GetFileName(([string]$_.ManifestUrl -replace '\\','/')) -ieq $leaf))})
}

function ConvertTo-AmdPortableEvidenceObject {
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
    if ($Value -is [System.Collections.IDictionary]) {
        $out=[ordered]@{}
        foreach($key in $Value.Keys){
            $name=[string]$key
            if((Test-AmdPublicPathPropertyName -PropertyName $name) -or $name -in @('Log','Transcript','StackTrace','Exception')){continue}
            $v=$Value[$key]
            if($name -eq 'Log' -and $v -is [string] -and ($v -match '(?i)(/mnt/data/|^[A-Z]:\\|^\\\\)')){continue}
            if($name -eq 'Path' -and $v -is [string] -and ([System.IO.Path]::IsPathRooted([string]$v))){continue}
            $out[$name]=ConvertTo-AmdPortableEvidenceObject -Value $v
        }
        return [pscustomobject]$out
    }
    if ($Value -is [System.Collections.IEnumerable]) {
        $arr=New-Object System.Collections.Generic.List[object]
        foreach($item in $Value){$arr.Add((ConvertTo-AmdPortableEvidenceObject -Value $item))}
        # Preserve array cardinality in canonical JSON even when the collection has one item.
        return ,$arr.ToArray()
    }
    if ($Value.PSObject -and $Value.PSObject.Properties) {
        $out=[ordered]@{}
        foreach($prop in $Value.PSObject.Properties){
            $name=[string]$prop.Name
            if((Test-AmdPublicPathPropertyName -PropertyName $name) -or $name -in @('Log','Transcript','StackTrace','Exception')){continue}
            $v=$prop.Value
            if($name -eq 'Log' -and $v -is [string] -and ($v -match '(?i)(/mnt/data/|^[A-Z]:\\|^\\\\)')){continue}
            if($name -eq 'Path' -and $v -is [string] -and ([System.IO.Path]::IsPathRooted([string]$v))){continue}
            $out[$name]=ConvertTo-AmdPortableEvidenceObject -Value $v
        }
        return [pscustomobject]$out
    }
    return $Value
}

function Get-AmdCanonicalDriverRecord {
    [CmdletBinding()]
    param([Parameter(Mandatory=$true)][object]$Driver,[object[]]$ManifestMatches)
    $modelDescriptions=@()
    if($Driver.InfTopology){$modelDescriptions=@((Get-AmdCollectionItems -Value $Driver.InfTopology.ModelsSections)|ForEach-Object{@(Get-AmdCollectionItems -Value $_.Models)}|ForEach-Object{$_.Description}|Where-Object{$_}|Sort-Object -Unique)}
    $embeddedNames=@($ManifestMatches|ForEach-Object{$_.ProductName}|Where-Object{$_}|Sort-Object -Unique)
    $displayName=if($embeddedNames.Count -gt 0){$embeddedNames[0]}elseif($modelDescriptions.Count -gt 0){$modelDescriptions[0]}else{[System.IO.Path]::GetFileName([string]$Driver.InfRelativePath)}
    $serviceNames=if($Driver.Services){@($Driver.Services.Names)}else{@()}
    # Keep the large INF topology object direct for Build performance, but sanitize the
    # small path-bearing evidence envelopes so canonical JSON never captures workspace paths.
    $portableServiceBinaries=@($Driver.ServiceBinaries | ForEach-Object { ConvertTo-AmdPortableEvidenceObject -Value $_ })
    $portableManifestMatches=@($ManifestMatches | ForEach-Object { ConvertTo-AmdPortableEvidenceObject -Value $_ })
    return [pscustomobject][ordered]@{
        Identity=[pscustomobject][ordered]@{DisplayName=$displayName;EmbeddedProductNames=$embeddedNames;InfModelDescriptions=$modelDescriptions;ServiceNames=@($serviceNames)}
        Observed=[pscustomobject][ordered]@{
            InspectionStatus=$Driver.InspectionStatus;InspectionError=$Driver.InspectionError;InfRelativePath=$Driver.InfRelativePath;InfSha256=$Driver.InfSha256
            SourceVariant=$Driver.SourceVariant;DriverComponent=$Driver.DriverComponent;VersionSection=$Driver.VersionSection;Wdf=$Driver.Wdf
            HardwareIds=@(Get-AmdCollectionItems -Value $Driver.HardwareIds);InfTopology=$Driver.InfTopology;Services=$Driver.Services;ServiceBinaries=@($portableServiceBinaries);EmbeddedManifestPackages=@($portableManifestMatches)
        }
        Analysis=[pscustomobject][ordered]@{WindowsServerApplicability=@(Get-AmdCollectionItems -Value $Driver.WindowsServerAnalysis);RuntimeCompatibility='NotEstablished'}
    }
}

function Invoke-AmdBuildStage {
    [CmdletBinding()]
    param(
        [string]$ReleasesPath,[string]$MetadataPath,[string]$AcquisitionPath,[string]$ExtractionPath,[string]$DriverPackagesPath,[string]$EnvironmentPath,[string]$EmbeddedMetadataPath,
        [string]$OutputJsonPath,[string]$OutputCsvPath,[string]$OutputMarkdownPath,[string]$WindowsServerAnalysisJsonPath,[string]$WindowsServerAnalysisCsvPath,[string]$WindowsServerAnalysisMarkdownPath
    )

    $root=Get-AmdResearchToolkitRoot
    $buildIntegrityPath = Join-Path $root 'inventory\build-integrity.json'
    if(Test-Path -LiteralPath $buildIntegrityPath -PathType Leaf){Remove-Item -LiteralPath $buildIntegrityPath -Force -ErrorAction SilentlyContinue}
    if(-not $ReleasesPath){$ReleasesPath=Join-Path $root 'inventory\releases.json'}
    if(-not $MetadataPath){$MetadataPath=Join-Path $root 'inventory\release-metadata.json'}
    if(-not $AcquisitionPath){$AcquisitionPath=Join-Path $root 'inventory\acquisition.json'}
    if(-not $ExtractionPath){$ExtractionPath=Join-Path $root 'inventory\extraction.json'}
    if(-not $DriverPackagesPath){$DriverPackagesPath=Join-Path $root 'inventory\driver-packages.json'}
    if(-not $EnvironmentPath){$EnvironmentPath=Join-Path $root 'inventory\environment.json'}
    if(-not $EmbeddedMetadataPath){$EmbeddedMetadataPath=Join-Path $root 'inventory\embedded-installer-metadata.json'}
    if(-not $OutputJsonPath){$OutputJsonPath=Join-Path $root 'inventory\amd-graphics-driver-inventory.json'}
    if(-not $OutputCsvPath){$OutputCsvPath=Join-Path $root 'inventory\amd-graphics-driver-inventory.csv'}
    if(-not $OutputMarkdownPath){$OutputMarkdownPath=Join-Path $root 'reports\amd-graphics-driver-history.md'}
    if(-not $WindowsServerAnalysisJsonPath){$WindowsServerAnalysisJsonPath=Join-Path $root 'inventory\windows-server-compatibility-analysis.json'}
    if(-not $WindowsServerAnalysisCsvPath){$WindowsServerAnalysisCsvPath=Join-Path $root 'inventory\windows-server-compatibility-analysis.csv'}
    if(-not $WindowsServerAnalysisMarkdownPath){$WindowsServerAnalysisMarkdownPath=Join-Path $root 'reports\windows-server-compatibility-analysis.md'}

    function Read-AmdOptionalJson([string]$Path){
        if(Test-Path -LiteralPath $Path -PathType Leaf){return(Read-AmdJsonFile -Path $Path)}
        return $null
    }
    function Read-AmdDriverDetail([object]$Ref){
        if($null -eq $Ref -or -not $Ref.DetailJson){return $null}
        $path=[string]$Ref.DetailJson
        if(-not [System.IO.Path]::IsPathRooted($path)){$path=Join-Path $root $path}
        if(-not (Test-Path -LiteralPath $path -PathType Leaf)){throw ('Driver detail JSON not found: {0}' -f $path)}
        return (Read-AmdJsonFile -Path $path)
    }

    $releaseData=Read-AmdOptionalJson $ReleasesPath
    $metadataData=Read-AmdOptionalJson $MetadataPath
    $acquisitionData=Read-AmdOptionalJson $AcquisitionPath
    $extractionData=Read-AmdOptionalJson $ExtractionPath
    $driverData=Read-AmdOptionalJson $DriverPackagesPath
    $environmentData=Read-AmdOptionalJson $EnvironmentPath
    $embeddedData=Read-AmdOptionalJson $EmbeddedMetadataPath

    if($null -eq $driverData){
        throw 'driver-packages.json is required for Build. Run Inspect first.'
    }
    if(-not (Test-AmdSupportedDriverPackageIndexSchema -SchemaVersion ([string]$driverData.SchemaVersion))){
        throw ('Unsupported driver-packages storage schema [{0}]. This run contains a legacy monolithic driver-packages.json; rerun Inspect with toolkit {1} before Build.' -f [string]$driverData.SchemaVersion,$script:AmdGraphicsResearchToolkitVersion)
    }
    $shardIntegrity = Test-AmdDriverPackageShardIntegrity -DriverPackagesPath $DriverPackagesPath -OutputPath (Join-Path $root 'inventory\driver-packages-integrity.json')
    if ([string]$shardIntegrity.Status -ne 'Pass') {
        throw ('Driver-package shard integrity preflight failed with {0} error(s). See inventory/driver-packages-integrity.json.' -f @($shardIntegrity.Errors).Count)
    }
    $driverRefs=@(Get-AmdCollectionItems -Value $driverData.Artifacts)

    # Build a lightweight release-level research inventory. Dense driver records remain
    # in per-artifact detail JSON and are never embedded in this top-level inventory.
    $keys=@{}
    $releaseSets=New-Object System.Collections.Generic.List[object]
    if($releaseData){$releaseSets.Add(@(Get-AmdCollectionItems -Value $releaseData.Releases))}
    if($metadataData){$releaseSets.Add(@(Get-AmdCollectionItems -Value $metadataData.Releases))}
    if($acquisitionData){$releaseSets.Add(@(Get-AmdCollectionItems -Value $acquisitionData.Artifacts))}
    if($extractionData){$releaseSets.Add(@(Get-AmdCollectionItems -Value $extractionData.Releases))}
    if($embeddedData){$releaseSets.Add(@(Get-AmdCollectionItems -Value $embeddedData.Releases))}
    $releaseSets.Add(@($driverRefs))
    foreach($source in $releaseSets){
        foreach($item in @($source)){if($item -and $item.ReleaseKey){$keys[[string]$item.ReleaseKey]=$true}}
    }

    $inventoryRows=New-Object System.Collections.Generic.List[object]
    $orderedKeys=@($keys.Keys|Sort-Object @{Expression={$parts=@(([string]$_)-split '\|');Get-AmdReleaseSortKey -ReleaseVersion ([string]$parts[$parts.Count-1])}},@{Expression={[string]$_}})
    foreach($key in $orderedKeys){
        $discovery=@(if($releaseData){(Get-AmdCollectionItems -Value $releaseData.Releases)|Where-Object{$_.ReleaseKey -eq $key}|Select-Object -First 1})
        $metadata=@(if($metadataData){(Get-AmdCollectionItems -Value $metadataData.Releases)|Where-Object{$_.ReleaseKey -eq $key}|Select-Object -First 1})
        $acquisitions=@(if($acquisitionData){(Get-AmdCollectionItems -Value $acquisitionData.Artifacts)|Where-Object{$_.ReleaseKey -eq $key}})
        $extractions=@(if($extractionData){(Get-AmdCollectionItems -Value $extractionData.Releases)|Where-Object{$_.ReleaseKey -eq $key}})
        $embedded=@(if($embeddedData){(Get-AmdCollectionItems -Value $embeddedData.Releases)|Where-Object{$_.ReleaseKey -eq $key}})
        $refs=@($driverRefs|Where-Object{$_.ReleaseKey -eq $key})
        $basis=$null
        if($discovery.Count -gt 0){$basis=$discovery[0]}elseif($metadata.Count -gt 0){$basis=$metadata[0]}elseif($acquisitions.Count -gt 0){$basis=$acquisitions[0]}elseif($extractions.Count -gt 0){$basis=$extractions[0]}elseif($refs.Count -gt 0){$basis=$refs[0]}
        if($null -eq $basis){continue}
        $inventoryRows.Add([pscustomobject][ordered]@{
            ReleaseKey=$key;ReleaseVersion=[string]$basis.ReleaseVersion;PackageFamily=[string]$basis.PackageFamily;Branch=[string]$basis.Branch
            Discovery=if($discovery.Count -gt 0){$discovery[0]}else{$null}
            Metadata=if($metadata.Count -gt 0){$metadata[0]}else{$null}
            Acquisitions=@($acquisitions);Extractions=@($extractions);EmbeddedInstallerMetadata=@($embedded)
            DriverPackageCount=if($refs.Count -gt 0){[int](($refs|Measure-Object -Property DriverPackageCount -Sum).Sum)}else{0}
            DriverArtifactCount=$refs.Count
            DriverPackageIndex='inventory/driver-packages.json'
        })
    }
    $inventory=[pscustomobject][ordered]@{
        SchemaVersion='2.3';ToolkitVersion=$script:AmdGraphicsResearchToolkitVersion;GeneratedAtUtc=[DateTime]::UtcNow.ToString('o')
        Purpose='ResearchInventoryIndex';CompatibilityPolicyIncluded=$false
        EvidenceLayerPolicy='Published, embedded, payload-observed, and derived-analysis evidence are kept distinct.'
        DriverPackagesEmbedded=$false;DriverPackageStorage='PerArtifactDetailJson';Releases=$inventoryRows.ToArray();ResearchEnvironment=$environmentData
    }
    Write-AmdJsonFile -Path $OutputJsonPath -Value $inventory

    # Flat INF summary rows are collected while each per-artifact detail file is already
    # in memory during canonical generation. Do not parse every dense detail JSON twice.
    $csv=New-Object System.Collections.Generic.List[object]

    $md=New-Object System.Text.StringBuilder
    [void]$md.AppendLine('# AMD Graphics Driver Research Inventory');[void]$md.AppendLine('')
    [void]$md.AppendLine('Research evidence only. Dense INF topology is stored in canonical per-artifact JSON; Windows Server applicability is emitted as a separate derived analysis.');[void]$md.AppendLine('')
    [void]$md.AppendLine('| Release | Family | Branch | Artifacts | INF | KMDF | UMDF |');[void]$md.AppendLine('|---|---|---|---:|---:|---:|---:|')
    foreach($rel in $inventoryRows){
        $refs=@($driverRefs|Where-Object{$_.ReleaseKey -eq $rel.ReleaseKey})
        $driverCount = if($refs.Count -gt 0){[int](($refs|Measure-Object DriverPackageCount -Sum).Sum)}else{0}
        $kmdfCount = if($refs.Count -gt 0){[int](($refs|Measure-Object KmdfDeclarationCount -Sum).Sum)}else{0}
        $umdfCount = if($refs.Count -gt 0){[int](($refs|Measure-Object UmdfDeclarationCount -Sum).Sum)}else{0}
        [void]$md.AppendLine(('| {0} | {1} | {2} | {3} | {4} | {5} | {6} |' -f $rel.ReleaseVersion,$rel.PackageFamily,$rel.Branch,$refs.Count,$driverCount,$kmdfCount,$umdfCount))
    }
    Write-AmdUtf8NoBom -Path $OutputMarkdownPath -Text $md.ToString()

    # Canonical ArtifactKey 1:1 records are built one artifact at a time. This is the
    # primary memory boundary for large historical Windows PowerShell 5.1 runs.
    # Aggregate state is populated while each canonical artifact record is already in memory.
    # Existing historical canonical records that are not part of the current run are read once
    # before processing current artifacts. This avoids repeatedly parsing the same dense JSON.
    $deviceMatrixPath=Join-Path $root 'inventory\device-server-compatibility-matrix.csv'
    $deviceDetailPath=Join-Path $root 'inventory\device-server-compatibility-detail.csv'
    if(Test-Path -LiteralPath $deviceDetailPath -PathType Leaf){Remove-Item -LiteralPath $deviceDetailPath -Force}
    $aggregateState=@{
        Root=$root
        CumulativeIndex=(New-Object System.Collections.Generic.List[object])
        TopologyArtifacts=(New-Object System.Collections.Generic.List[object])
        ServerRows=(New-Object System.Collections.Generic.List[object])
        TotalCanonicalDrivers=0
        IdentifierKindCache=@{}
        DeviceDetailPath=$deviceDetailPath
        EmitDetailedDeviceMatrix=[bool]$script:EmitDetailedDeviceMatrix
        DeviceMatrixHeaderWritten=$false
        DeviceMatrixRowCount=0
    }

    $addCanonicalToAggregate = {
        param([object]$Record,[string]$CanonicalPath,[hashtable]$State)
        if(-not $Record -or $Record.RecordType -ne 'CanonicalPerArtifactAnalysis'){return}

        $relativeCanonical=Get-AmdRelativePath -BasePath $State.Root -Path $CanonicalPath
        $driverCount=[int]$Record.DriverCount
        $State.TotalCanonicalDrivers=[int]$State.TotalCanonicalDrivers+$driverCount

        $State.CumulativeIndex.Add([pscustomobject][ordered]@{
            ReleaseVersion=[string]$Record.Release.Version;ReleaseKey=[string]$Record.Release.ReleaseKey;ArtifactKey=[string]$Record.Artifact.ArtifactKey
            ArtifactRole=[string]$Record.Artifact.ArtifactRole;FileName=[string]$Record.Artifact.FileName;CanonicalJson=$relativeCanonical;DriverCount=$driverCount
        })
        $State.TopologyArtifacts.Add([pscustomobject][ordered]@{
            ReleaseVersion=[string]$Record.Release.Version;ReleaseKey=[string]$Record.Release.ReleaseKey;ArtifactKey=[string]$Record.Artifact.ArtifactKey
            ArtifactRole=[string]$Record.Artifact.ArtifactRole;CanonicalJson=$relativeCanonical;DriverCount=$driverCount
        })

        $deviceBatch=New-Object System.Collections.Generic.List[object]
        foreach($drv in @(Get-AmdCollectionItems -Value $Record.Drivers)){
            $observed=$drv.Observed
            foreach($srv in @(Get-AmdCollectionItems -Value $drv.Analysis.WindowsServerApplicability)){
                $legacyAssessment=[string]$srv.StaticAssessment
                $canonicalAssessment=if($srv.PSObject.Properties['CanonicalStaticAssessment']){[string]$srv.CanonicalStaticAssessment}else{switch($legacyAssessment){'NATIVE_CANDIDATE'{'NativeCandidate'}'PATCH_CANDIDATE'{'ProjectionCandidate'}'REVIEW_REQUIRED'{'ReviewRequired'}'NOT_APPLICABLE'{'NotApplicable'}'INDETERMINATE'{'Indeterminate'}default{'Indeterminate'}}}
                $wdfScope=if($srv.PSObject.Properties['WdfScope'] -and $srv.WdfScope){[string]$srv.WdfScope}else{'InfWideConservative'}
                $runtimeProven=if($srv.PSObject.Properties['RuntimeCompatibilityProven']){[bool]$srv.RuntimeCompatibilityProven}else{$false}
                $asPublishedIds=@(Get-AmdCollectionItems -Value $srv.AsPublished.SelectedHardwareIds)
                $projectionIds=@(Get-AmdCollectionItems -Value $srv.ServerProjection.SelectedHardwareIds)

                $State.ServerRows.Add([pscustomobject][ordered]@{
                    ReleaseKey=[string]$Record.Release.ReleaseKey;ReleaseVersion=[string]$Record.Release.Version;PackageFamily=[string]$Record.Release.PackageFamily;Branch=[string]$Record.Release.Branch
                    ArtifactKey=[string]$Record.Artifact.ArtifactKey;ArtifactRole=[string]$Record.Artifact.ArtifactRole
                    DriverComponent=if($observed.DriverComponent){$observed.DriverComponent.Category}else{$null};InfRelativePath=$observed.InfRelativePath;InfSha256=$observed.InfSha256
                    Server=$srv.Server;ShortName=$srv.ShortName;BaseBuild=$srv.BaseBuild;ProductType=$srv.ProductType
                    AsPublishedStatus=$srv.AsPublished.Status;ProjectionStatus=$srv.ServerProjection.Status
                    StaticAssessment=$legacyAssessment;CanonicalStaticAssessment=$canonicalAssessment;Confidence=$srv.Confidence
                    RuntimeCompatibility=$srv.RuntimeCompatibility;RuntimeCompatibilityProven=$runtimeProven;WdfScope=$wdfScope
                    AsPublishedModelsSections=@(Get-AmdCollectionItems -Value $srv.AsPublished.SelectedModelsSections);ProjectionModelsSections=@(Get-AmdCollectionItems -Value $srv.ServerProjection.SelectedModelsSections)
                    AsPublishedHardwareIdCount=$asPublishedIds.Count;ProjectionHardwareIdCount=$projectionIds.Count
                    KMDFDeclared=if($srv.Wdf){@(Get-AmdCollectionItems -Value $srv.Wdf.KMDF.DeclaredVersions)}else{@()};KMDFDocumented=if($srv.Wdf){$srv.Wdf.KMDF.DocumentedReference}else{$null};KMDFObserved=if($srv.Wdf){$srv.Wdf.KMDF.ObservedReference}else{$null}
                    UMDFDeclared=if($srv.Wdf){@(Get-AmdCollectionItems -Value $srv.Wdf.UMDF.DeclaredVersions)}else{@()};ManifestMatchCount=@(Get-AmdCollectionItems -Value $observed.EmbeddedManifestPackages).Count
                })

                if([bool]$State.EmitDetailedDeviceMatrix){
                    $ids=@(if($projectionIds.Count -gt 0){$projectionIds}else{$asPublishedIds})
                    if($ids.Count -eq 0){
                        $deviceBatch.Add([pscustomobject][ordered]@{
                            ReleaseVersion=[string]$Record.Release.Version;ArtifactRole=[string]$Record.Artifact.ArtifactRole;InfRelativePath=$observed.InfRelativePath;Server=$srv.Server
                            HardwareId=$null;IdentifierKind='MissingIdentifier';IdentifierType='MissingIdentifier'
                            AsPublishedStatus=$srv.AsPublished.Status;ProjectionStatus=$srv.ServerProjection.Status
                            StaticAssessment=$legacyAssessment;CanonicalStaticAssessment=$canonicalAssessment;RuntimeCompatibility=$srv.RuntimeCompatibility
                        })
                    }else{
                        foreach($id in $ids){
                            $identifierKey=([string]$id).ToUpperInvariant()
                            if(-not $State.IdentifierKindCache.ContainsKey($identifierKey)){
                                $State.IdentifierKindCache[$identifierKey]=[string](Get-AmdInfIdentifierInfo -Identifier ([string]$id) -InfClass $null).Kind
                            }
                            $identifierKind=[string]$State.IdentifierKindCache[$identifierKey]
                            $deviceBatch.Add([pscustomobject][ordered]@{
                                ReleaseVersion=[string]$Record.Release.Version;ArtifactRole=[string]$Record.Artifact.ArtifactRole;InfRelativePath=$observed.InfRelativePath;Server=$srv.Server
                                HardwareId=$id;IdentifierKind=$identifierKind;IdentifierType=$identifierKind
                                AsPublishedStatus=$srv.AsPublished.Status;ProjectionStatus=$srv.ServerProjection.Status
                                StaticAssessment=$legacyAssessment;CanonicalStaticAssessment=$canonicalAssessment;RuntimeCompatibility=$srv.RuntimeCompatibility
                            })
                        }
                    }
                }
            }
        }

        if($deviceBatch.Count -gt 0){
            if(-not [bool]$State.DeviceMatrixHeaderWritten){
                $deviceBatch.ToArray()|Export-Csv -LiteralPath $State.DeviceDetailPath -NoTypeInformation -Encoding UTF8
                $State.DeviceMatrixHeaderWritten=$true
            }else{
                $deviceBatch.ToArray()|Export-Csv -LiteralPath $State.DeviceDetailPath -NoTypeInformation -Encoding UTF8 -Append
            }
            $State.DeviceMatrixRowCount=[int]$State.DeviceMatrixRowCount+$deviceBatch.Count
        }
    }

    $currentArtifactKeys=@{}
    foreach($ref in $driverRefs){$currentArtifactKeys[[string]$ref.ArtifactKey]=$true}
    $topologyArtifactKeys=@{}

    # Retain historical aggregate entries without reparsing dense canonical records.
    # Canonical per-artifact JSON remains the source of truth, while the previous lightweight
    # aggregate indexes provide enough information to preserve artifacts not touched by this run.
    $previousSummary=Read-AmdOptionalJson (Join-Path $root 'inventory\all-releases-summary.json')
    if($previousSummary -and $previousSummary.PSObject.Properties['Artifacts'] -and $previousSummary.Artifacts){
        foreach($item in @(Get-AmdCollectionItems -Value $previousSummary.Artifacts)){
            $existingKey=[string]$item.ArtifactKey
            if(-not $existingKey -or $currentArtifactKeys.ContainsKey($existingKey)){continue}
            $aggregateState.CumulativeIndex.Add($item)
            $aggregateState.TotalCanonicalDrivers=[int]$aggregateState.TotalCanonicalDrivers+[int]$item.DriverCount
            $aggregateState.TopologyArtifacts.Add([pscustomobject][ordered]@{
                ReleaseVersion=[string]$item.ReleaseVersion;ReleaseKey=[string]$item.ReleaseKey;ArtifactKey=$existingKey
                ArtifactRole=[string]$item.ArtifactRole;CanonicalJson=[string]$item.CanonicalJson;DriverCount=[int]$item.DriverCount
            })
            $topologyArtifactKeys[$existingKey]=$true
        }
    }
    $previousTopology=Read-AmdOptionalJson (Join-Path $root 'inventory\inf-topology.json')
    if($previousTopology -and $previousTopology.PSObject.Properties['Artifacts'] -and $previousTopology.Artifacts){
        foreach($item in @(Get-AmdCollectionItems -Value $previousTopology.Artifacts)){
            $existingKey=[string]$item.ArtifactKey
            if(-not $existingKey -or $currentArtifactKeys.ContainsKey($existingKey) -or $topologyArtifactKeys.ContainsKey($existingKey)){continue}
            $aggregateState.TopologyArtifacts.Add($item)
            $topologyArtifactKeys[$existingKey]=$true
        }
    }
    $previousServer=Read-AmdOptionalJson $WindowsServerAnalysisJsonPath
    if($previousServer -and $previousServer.PSObject.Properties['Rows'] -and $previousServer.Rows){
        foreach($row in @(Get-AmdCollectionItems -Value $previousServer.Rows)){
            $existingKey=[string]$row.ArtifactKey
            if($existingKey -and $currentArtifactKeys.ContainsKey($existingKey)){continue}
            try {
                $normalizedRow = ConvertTo-AmdLightweightServerAggregateRow -Row $row
                if($normalizedRow -and $normalizedRow.ArtifactKey){$aggregateState.ServerRows.Add($normalizedRow)}
            }
            catch {
                Write-AmdCaution ('Historical server aggregate row skipped during in-memory migration: {0}' -f $_.Exception.Message)
            }
        }
    }

    $releaseAnalysisIndex=New-Object System.Collections.Generic.List[object]
    foreach($ref in $driverRefs){
        $detail=Read-AmdDriverDetail $ref
        $artifactKey=[string]$ref.ArtifactKey
        $releaseKey=[string]$ref.ReleaseKey
        $version=[string]$ref.ReleaseVersion
        $acq=@(if($acquisitionData){(Get-AmdCollectionItems -Value $acquisitionData.Artifacts)|Where-Object{$_.ArtifactKey -eq $artifactKey}|Select-Object -First 1})
        $ext=@(if($extractionData){(Get-AmdCollectionItems -Value $extractionData.Releases)|Where-Object{$_.ArtifactKey -eq $artifactKey}|Select-Object -First 1})
        $emb=@(if($embeddedData){(Get-AmdCollectionItems -Value $embeddedData.Releases)|Where-Object{$_.ArtifactKey -eq $artifactKey}|Select-Object -First 1})
        $manifestPackages=@();if($emb.Count -gt 0 -and $emb[0].InstallManifestSummary){$manifestPackages=@($emb[0].InstallManifestSummary.Packages)}
        $canonicalDrivers=New-Object System.Collections.Generic.List[object]
        foreach($drv in @($detail.DriverPackages)){
            $csv.Add([pscustomobject][ordered]@{
                ReleaseVersion=$ref.ReleaseVersion;PackageFamily=$ref.PackageFamily;Branch=$ref.Branch;ArtifactRole=$ref.ArtifactRole
                DriverComponent=if($drv.DriverComponent){$drv.DriverComponent.Category}else{$null};Subcomponent=if($drv.DriverComponent){$drv.DriverComponent.Subcomponent}else{$null}
                InfRelativePath=$drv.InfRelativePath;InfSha256=$drv.InfSha256;Provider=if($drv.VersionSection){$drv.VersionSection.Provider}else{$null}
                Class=if($drv.VersionSection){$drv.VersionSection.Class}else{$null};DriverVersion=if($drv.VersionSection){$drv.VersionSection.DriverVersion}else{$null};DriverDate=if($drv.VersionSection){$drv.VersionSection.DriverDate}else{$null}
                KmdfVersions=if($drv.Wdf){@(Get-AmdCollectionItems -Value $drv.Wdf.KMDF.Versions)-join ';'}else{''};UmdfVersions=if($drv.Wdf){@(Get-AmdCollectionItems -Value $drv.Wdf.UMDF.Versions)-join ';'}else{''}
                HardwareIdCount=@(Get-AmdCollectionItems -Value $drv.HardwareIds).Count;ModelsSectionCount=if($drv.InfTopology){@(Get-AmdCollectionItems -Value $drv.InfTopology.ModelsSections).Count}else{0}
            })
            $matches=@(Get-AmdManifestMatchesForDriver -ManifestPackages $manifestPackages -Driver $drv)
            $canonicalDrivers.Add((Get-AmdCanonicalDriverRecord -Driver $drv -ManifestMatches $matches))
        }

        $fileName=if($acq.Count -gt 0 -and $acq[0].FileName){[string]$acq[0].FileName}else{([string]$artifactKey -split '\|')[-1]}
        $stem=ConvertTo-AmdSafePathLeaf -Value ([System.IO.Path]::GetFileNameWithoutExtension($fileName))
        $versionLeaf=ConvertTo-AmdSafePathLeaf -Value $version
        $releaseDir=Join-Path (Join-Path $root 'inventory\releases') $versionLeaf;New-AmdDirectory -Path $releaseDir|Out-Null
        $rawPath=Join-Path $releaseDir ($stem+'.json')
        $discovery=@(if($releaseData){(Get-AmdCollectionItems -Value $releaseData.Releases)|Where-Object{$_.ReleaseKey -eq $releaseKey}|Select-Object -First 1})
        $metadata=@(if($metadataData){(Get-AmdCollectionItems -Value $metadataData.Releases)|Where-Object{$_.ReleaseKey -eq $releaseKey}|Select-Object -First 1})
        $record=[pscustomobject][ordered]@{
            SchemaVersion='amd-graphics-driver-analysis/1.2';ToolkitVersion=$script:AmdGraphicsResearchToolkitVersion;GeneratedAtUtc=[DateTime]::UtcNow.ToString('o');RecordType='CanonicalPerArtifactAnalysis'
            Release=[pscustomobject][ordered]@{
                ReleaseKey=$releaseKey;Version=$version;PackageFamily=[string]$ref.PackageFamily;Branch=[string]$ref.Branch
                Discovery=if($discovery.Count -gt 0){$discovery[0]}else{$null};PublishedMetadata=if($metadata.Count -gt 0){$metadata[0]}else{$null}
            }
            Artifact=[pscustomobject][ordered]@{
                ArtifactKey=$artifactKey;FileName=$fileName;ArtifactRole=[string]$ref.ArtifactRole
                Acquisition=if($acq.Count -gt 0){$acq[0]}else{$null};Extraction=if($ext.Count -gt 0){$ext[0]}else{$null};EmbeddedInstallerMetadata=if($emb.Count -gt 0){$emb[0]}else{$null}
            }
            AnalysisSemantics=[pscustomobject][ordered]@{
                SharedContractVersion=$script:AmdInfSemanticContractVersion;IdentifierTaxonomyVersion=$script:AmdInfIdentifierTaxonomyVersion;InfTopologySchemaVersion=$script:AmdInfTopologySchemaVersion
                AsPublished='Microsoft TargetOSVersion / Models selection semantics applied to the unmodified INF.'
                ServerProjection='Analytical projection that changes explicit ProductType=1 decorations to ProductType=3 without modifying the source INF.'
                CompatibilityBoundary='Static candidate analysis only. Runtime compatibility, signature acceptance, binary ABI behavior, and actual device installation are not proven.'
                WdfScope='InfWideConservative';RepositoryPortability='Machine-local absolute paths are removed from canonical records; run-specific extractor paths/logs remain Evidence-only.'
                VendorSelectorBoundary='Chipset-specific DevID.xml/MSI/SETxxx selector logic is not imported into Graphics. Vendor embedded conditions remain a separate evidence layer.'
            }
            AnalysisPolicy=[pscustomobject][ordered]@{CanonicalTruth='Observed INF/manifest facts are preserved separately from derived Windows Server analysis.';ServerProjection='ProductType=1 to ProductType=3 is simulated only; no INF file is modified.';RuntimeCompatibility='NotEstablished';WdfScope='InfWideConservative'}
            WindowsServerProfiles=@(Get-AmdWindowsServerTargetProfiles);DriverCount=$canonicalDrivers.Count;Drivers=$canonicalDrivers.ToArray()
        }
        $record.Release=ConvertTo-AmdPortableEvidenceObject -Value $record.Release
        $record.Artifact=ConvertTo-AmdPortableEvidenceObject -Value $record.Artifact
        Write-AmdJsonFile -Path $rawPath -Value $record
        $releaseAnalysisIndex.Add([pscustomobject][ordered]@{
            ReleaseVersion=$version;ReleaseKey=$releaseKey;ArtifactKey=$artifactKey;ArtifactRole=[string]$ref.ArtifactRole;FileName=$fileName
            CanonicalJson=(Get-AmdRelativePath -BasePath $root -Path $rawPath);DriverCount=$canonicalDrivers.Count
        })

        & $addCanonicalToAggregate -Record $record -CanonicalPath $rawPath -State $aggregateState

        $reportDir=Join-Path (Join-Path $root 'reports\releases') $versionLeaf;New-AmdDirectory -Path $reportDir|Out-Null
        $reportPath=Join-Path $reportDir ($stem+'.md')
        $rmd=New-Object System.Text.StringBuilder
        [void]$rmd.AppendLine(('# AMD Graphics {0} — {1}' -f $version,$fileName));[void]$rmd.AppendLine('');[void]$rmd.AppendLine(('ArtifactKey: `{0}`' -f $artifactKey));[void]$rmd.AppendLine('')
        [void]$rmd.AppendLine(('INF packages: **{0}**' -f $canonicalDrivers.Count));[void]$rmd.AppendLine('')
        [void]$rmd.AppendLine('| Server | Native | Patch candidate | Review | Not applicable |');[void]$rmd.AppendLine('|---|---:|---:|---:|---:|')
        foreach($profile in @(Get-AmdWindowsServerTargetProfiles)){
            $rows=@($canonicalDrivers.ToArray()|ForEach-Object{@(Get-AmdCollectionItems -Value $_.Analysis.WindowsServerApplicability)}|Where-Object{$_.ShortName -eq $profile.ShortName})
            [void]$rmd.AppendLine(('| {0} | {1} | {2} | {3} | {4} |' -f $profile.Name,@($rows|Where-Object{$_.StaticAssessment -eq 'NATIVE_CANDIDATE'}).Count,@($rows|Where-Object{$_.StaticAssessment -eq 'PATCH_CANDIDATE'}).Count,@($rows|Where-Object{$_.StaticAssessment -eq 'REVIEW_REQUIRED'}).Count,@($rows|Where-Object{$_.StaticAssessment -eq 'NOT_APPLICABLE'}).Count))
        }
        [void]$rmd.AppendLine('');[void]$rmd.AppendLine('`PATCH_CANDIDATE` is a static projection result, not a runtime compatibility claim.')
        Write-AmdUtf8NoBom -Path $reportPath -Text $rmd.ToString()

        Remove-Variable detail,record,canonicalDrivers,manifestPackages,acq,ext,emb,matches -ErrorAction SilentlyContinue
        # Per-artifact detail JSON can expand substantially when deserialized. Force a collection
        # at the artifact memory boundary on both Windows PowerShell and PowerShell 7 so RSS does
        # not grow monotonically across large product-driven runs.
        [GC]::Collect();[GC]::WaitForPendingFinalizers();[GC]::Collect()
    }

    if($csv.Count -gt 0){$csv|Export-Csv -LiteralPath $OutputCsvPath -NoTypeInformation -Encoding UTF8}else{Write-AmdUtf8NoBom -Path $OutputCsvPath -Text ''}

    if([bool]$script:EmitDetailedDeviceMatrix -and -not [bool]$aggregateState.DeviceMatrixHeaderWritten){Write-AmdUtf8NoBom -Path $deviceDetailPath -Text ''}

    $cumulativeIndex=$aggregateState.CumulativeIndex
    $topologyArtifacts=$aggregateState.TopologyArtifacts
    $serverRows=$aggregateState.ServerRows
    $totalCanonicalDrivers=[int]$aggregateState.TotalCanonicalDrivers
    $deviceMatrixRowCount=[int]$aggregateState.DeviceMatrixRowCount

    Write-AmdJsonFile -Path (Join-Path $root 'inventory\all-releases-summary.json') -Value ([pscustomobject][ordered]@{
        SchemaVersion='amd-graphics-all-releases-summary/1.2';ToolkitVersion=$script:AmdGraphicsResearchToolkitVersion;GeneratedAtUtc=[DateTime]::UtcNow.ToString('o')
        SourceOfTruth='inventory/releases/** canonical per-artifact JSON';ArtifactCount=$cumulativeIndex.Count;DriverCount=$totalCanonicalDrivers;Artifacts=$cumulativeIndex.ToArray()
    })
    Write-AmdJsonFile -Path (Join-Path $root 'inventory\inf-topology.json') -Value ([pscustomobject][ordered]@{
        SchemaVersion='inf-topology-collection/2.0';ToolkitVersion=$script:AmdGraphicsResearchToolkitVersion;SharedContractVersion=$script:AmdInfSemanticContractVersion
        IdentifierTaxonomyVersion=$script:AmdInfIdentifierTaxonomyVersion;GeneratedAtUtc=[DateTime]::UtcNow.ToString('o')
        SourceOfTruth='inventory/releases/** canonical per-artifact JSON';EmbeddedDrivers=$false;ArtifactCount=$topologyArtifacts.Count;DriverCount=$totalCanonicalDrivers;Artifacts=$topologyArtifacts.ToArray()
    })

    $serverOutput=[pscustomobject][ordered]@{
        SchemaVersion='windows-server-applicability/2.2';ToolkitVersion=$script:AmdGraphicsResearchToolkitVersion;GeneratedAtUtc=[DateTime]::UtcNow.ToString('o')
        Purpose='StaticWindowsServerApplicabilityAnalysisSummary';SharedContractVersion=$script:AmdInfSemanticContractVersion;IdentifierTaxonomyVersion=$script:AmdInfIdentifierTaxonomyVersion
        WdfScope='InfWideConservative';SourceOfTruth='inventory/releases/** canonical per-artifact JSON'
        Policy='AsPublished and virtual ProductType=1->3 ServerProjection are separate. Static candidates are not AMD support statements or runtime compatibility proof.'
        AggregatePayloadPolicy='Selected HWID arrays are not duplicated in this aggregate JSON; counts are stored here and full evidence remains in canonical per-artifact records.'
        ServerProfiles=@(Get-AmdWindowsServerTargetProfiles);RowCount=$serverRows.Count;Rows=$serverRows.ToArray()
    }
    Write-AmdJsonFile -Path $WindowsServerAnalysisJsonPath -Value $serverOutput
    Write-AmdJsonFile -Path (Join-Path $root 'inventory\windows-server-applicability.json') -Value $serverOutput

    $serverCsv=@($serverRows.ToArray()|ForEach-Object{[pscustomobject][ordered]@{
        ReleaseVersion=$_.ReleaseVersion;ArtifactRole=$_.ArtifactRole;DriverComponent=$_.DriverComponent;InfRelativePath=$_.InfRelativePath;Server=$_.Server;BaseBuild=$_.BaseBuild
        AsPublishedStatus=$_.AsPublishedStatus;ProjectionStatus=$_.ProjectionStatus;StaticAssessment=$_.StaticAssessment;CanonicalStaticAssessment=$_.CanonicalStaticAssessment
        WdfScope=$_.WdfScope;Confidence=$_.Confidence;RuntimeCompatibility=$_.RuntimeCompatibility
        AsPublishedModelsSections=@($_.AsPublishedModelsSections)-join ';';ProjectionModelsSections=@($_.ProjectionModelsSections)-join ';'
        AsPublishedHardwareIdCount=$_.AsPublishedHardwareIdCount;ProjectionHardwareIdCount=$_.ProjectionHardwareIdCount
        KMDFDeclared=@($_.KMDFDeclared)-join ';';KMDFDocumented=$_.KMDFDocumented;KMDFObserved=$_.KMDFObserved;UMDFDeclared=@($_.UMDFDeclared)-join ';';ManifestMatchCount=$_.ManifestMatchCount
    }})
    if($serverCsv.Count -gt 0){
        $serverCsv|Export-Csv -LiteralPath $WindowsServerAnalysisCsvPath -NoTypeInformation -Encoding UTF8
        $serverCsv|Export-Csv -LiteralPath (Join-Path $root 'inventory\server-compatibility-matrix.csv') -NoTypeInformation -Encoding UTF8
    }else{
        Write-AmdUtf8NoBom -Path $WindowsServerAnalysisCsvPath -Text ''
        Write-AmdUtf8NoBom -Path (Join-Path $root 'inventory\server-compatibility-matrix.csv') -Text ''
    }

    # Default device/server matrix is a compact INF x Server summary. Full per-HWID
    # expansion is opt-in via -EmitDetailedDeviceMatrix and is written separately.
    $deviceSummaryCsv=@($serverRows.ToArray()|ForEach-Object{[pscustomobject][ordered]@{
        ReleaseVersion=$_.ReleaseVersion;ArtifactRole=$_.ArtifactRole;InfRelativePath=$_.InfRelativePath;Server=$_.Server
        StaticAssessment=$_.StaticAssessment;CanonicalStaticAssessment=$_.CanonicalStaticAssessment
        SelectedHardwareIdCount=if([int]$_.ProjectionHardwareIdCount -gt 0){[int]$_.ProjectionHardwareIdCount}else{[int]$_.AsPublishedHardwareIdCount}
        AsPublishedHardwareIdCount=$_.AsPublishedHardwareIdCount;ProjectionHardwareIdCount=$_.ProjectionHardwareIdCount
        RuntimeCompatibility=$_.RuntimeCompatibility
    }})
    if($deviceSummaryCsv.Count -gt 0){$deviceSummaryCsv|Export-Csv -LiteralPath $deviceMatrixPath -NoTypeInformation -Encoding UTF8}
    else{Write-AmdUtf8NoBom -Path $deviceMatrixPath -Text ''}

    $smd=New-Object System.Text.StringBuilder
    [void]$smd.AppendLine('# Windows Server Static Applicability Analysis');[void]$smd.AppendLine('')
    [void]$smd.AppendLine('As-published INF selection and virtual Server projection are separate. Runtime compatibility is not established.');[void]$smd.AppendLine('')
    [void]$smd.AppendLine('| Server | Native | Patch candidate | Review | Not applicable | Indeterminate |');[void]$smd.AppendLine('|---|---:|---:|---:|---:|---:|')
    foreach($profile in @(Get-AmdWindowsServerTargetProfiles)){
        $rows=@($serverRows.ToArray()|Where-Object{$_.ShortName -eq $profile.ShortName})
        [void]$smd.AppendLine(('| {0} | {1} | {2} | {3} | {4} | {5} |' -f $profile.Name,@($rows|Where-Object{$_.StaticAssessment -eq 'NATIVE_CANDIDATE'}).Count,@($rows|Where-Object{$_.StaticAssessment -eq 'PATCH_CANDIDATE'}).Count,@($rows|Where-Object{$_.StaticAssessment -eq 'REVIEW_REQUIRED'}).Count,@($rows|Where-Object{$_.StaticAssessment -eq 'NOT_APPLICABLE'}).Count,@($rows|Where-Object{$_.StaticAssessment -eq 'INDETERMINATE'}).Count))
    }
    [void]$smd.AppendLine('');[void]$smd.AppendLine('- NATIVE_CANDIDATE: selected as-published Models section is native to the Server profile and WDF is within documented references.')
    [void]$smd.AppendLine('- PATCH_CANDIDATE: only the virtual ProductType=1→3 projection reaches a Models section; no file is modified.')
    [void]$smd.AppendLine('- REVIEW_REQUIRED: SuiteMask, WDF reference, or another static condition requires review.')
    [void]$smd.AppendLine('- NOT_APPLICABLE: target/build/product type/explicit empty-section evidence does not produce a candidate.')
    [void]$smd.AppendLine('- Runtime validation remains mandatory.')
    Write-AmdUtf8NoBom -Path $WindowsServerAnalysisMarkdownPath -Text $smd.ToString()

    $buildIntegrity = Test-AmdBuildAggregateIntegrity -DriverPackagesPath $DriverPackagesPath -OutputPath $buildIntegrityPath
    if ([string]$buildIntegrity.Status -ne 'Pass') {
        throw ('Build aggregate integrity validation failed with {0} error(s). See inventory/build-integrity.json.' -f @($buildIntegrity.Errors).Count)
    }

    Write-AmdOk ('Build complete: release identities={0}; current artifacts={1}; current INF rows={2}; cumulative artifacts={3}; cumulative drivers={4}; cumulative server rows={5}; detailed device rows={6}.' -f $inventoryRows.Count,$releaseAnalysisIndex.Count,$csv.Count,[int]$buildIntegrity.CumulativeArtifactCount,[int]$buildIntegrity.CumulativeDriverCount,[int]$buildIntegrity.ServerRowCount,$deviceMatrixRowCount)
}

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
    # expression to $null.  Native tools such as subst.exe legitimately return
    # zero output, so normalize that PS5.1 representation to an empty payload.
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
        Write-AmdCaution ('Windows catalog native API type initialization failed: {0}' -f $_.Exception.Message)
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

function ConvertTo-AmdGraphicsPublicSignToolCheck {
    [CmdletBinding()]
    param([Parameter(Mandatory=$true)]$Check)
    return [pscustomobject][ordered]@{
        Policy=$Check.Policy
        VerificationProfileId=$Check.VerificationProfileId
        Arguments=@($Check.Arguments)
        ExitCode=$Check.ExitCode
        Status=$Check.Status
        ResultClass=$Check.ResultClass
        CatalogFileId=$Check.CatalogFileId
        OutputSha256=$Check.OutputSha256
        OutputLineCount=$Check.OutputLineCount
        Error=$Check.Error
    }
}

function ConvertTo-AmdGraphicsPrivateSignToolCheck {
    [CmdletBinding()]
    param([Parameter(Mandatory=$true)]$Check)
    return [pscustomobject][ordered]@{
        Policy=$Check.Policy
        VerificationProfileId=$Check.VerificationProfileId
        Arguments=@($Check.Arguments)
        ExitCode=$Check.ExitCode
        Status=$Check.Status
        ResultClass=$Check.ResultClass
        CatalogFileId=$Check.CatalogFileId
        Output=@($Check.PrivateOutput)
        Error=$Check.Error
    }
}

function Get-AmdGraphicsSignatureEnvelopeTree {
    [CmdletBinding()]
    param([AllowNull()]$Envelope)
    if($null -eq $Envelope){return @()}
    $items=New-Object 'System.Collections.Generic.List[object]'
    $items.Add($Envelope)|Out-Null
    foreach($signer in @($Envelope.Signers)){
        if($signer.PSObject.Properties['NestedSignatures']){
            foreach($nested in @($signer.NestedSignatures)){
                foreach($child in @(Get-AmdGraphicsSignatureEnvelopeTree -Envelope $nested)){$items.Add($child)|Out-Null}
            }
        }
        if($signer.PSObject.Properties['TimestampTokens']){
            foreach($timestamp in @($signer.TimestampTokens)){
                foreach($child in @(Get-AmdGraphicsSignatureEnvelopeTree -Envelope $timestamp)){$items.Add($child)|Out-Null}
            }
        }
    }
    return @($items.ToArray())
}

function Get-AmdGraphicsWindowsClientSignatureQualificationAssessment {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]$ExecutionPlan,
        [Parameter(Mandatory=$true)]$StaticAnalysis,
        [Parameter(Mandatory=$true)]$NativeVerification,
        [AllowNull()]$KernelCoverage
    )
    $issues=New-Object 'System.Collections.Generic.List[string]'
    if([string]$ExecutionPlan.PolicyId -ne 'NewestSelectedMajorGenerationPerSelectionTrack/1'){$issues.Add('certificate selection policy is not the product-driven newest-generation policy')|Out-Null}
    if([int]$ExecutionPlan.RequestedMajorGenerationCount -ne 3){$issues.Add('ordinary research selection was not the required newest three major generations')|Out-Null}
    if(@($ExecutionPlan.ProductGroupFilter).Count -ne 0){$issues.Add('product-group filtering was used for the qualification corpus')|Out-Null}
    if([int]$ExecutionPlan.FullResearchTrackCount -le 0){$issues.Add('full-research selection contains no stable product tracks')|Out-Null}
    $coveredTracks=@($ExecutionPlan.TargetReferences|ForEach-Object{[string]$_.SelectionTrackKey}|Where-Object{$_}|Sort-Object -Unique)
    if($coveredTracks.Count -ne [int]$ExecutionPlan.FullResearchTrackCount){$issues.Add('newest-generation certificate targets do not cover every selected stable product track')|Out-Null}
    if([string]$ExecutionPlan.Status -ne 'Ready'){$issues.Add('certificate verification plan is not Ready')|Out-Null}
    if([string]$NativeVerification.ExecutionContext.ExecutionClass -ne 'WindowsClient'){$issues.Add('execution class is not WindowsClient')|Out-Null}
    if([string]$NativeVerification.Tool.Status -ne 'Available'){$issues.Add('signtool.exe is unavailable')|Out-Null}
    if([bool]$NativeVerification.MutationPerformed){$issues.Add('native verification reported mutation')|Out-Null}
    if([int]$StaticAnalysis.Summary.UnexpectedStaticParseFailureCount -gt 0){$issues.Add('unexpected static signature parse failures were observed')|Out-Null}
    if([int]$StaticAnalysis.Summary.SignedDigestMismatchCount -gt 0){$issues.Add('Authenticode signed-content digest mismatches were observed')|Out-Null}
    if(@($StaticAnalysis.Artifacts).Count -ne @($ExecutionPlan.Resolution.ExecutionArtifacts).Count){$issues.Add('analyzed artifact count does not match the resolved execution plan')|Out-Null}
    if(@($NativeVerification.Artifacts).Count -ne @($ExecutionPlan.Resolution.ExecutionArtifacts).Count){$issues.Add('native artifact count does not match the resolved execution plan')|Out-Null}
    if($KernelCoverage -and [int]$KernelCoverage.CoverageGapKernelCount -gt 0){$issues.Add('catalog-bound kernel verification coverage has gaps')|Out-Null}
    return [pscustomobject][ordered]@{
        SchemaVersion='amd-graphics-windows-client-signature-qualification/1.0'
        Requested=$true
        Status=if($issues.Count -eq 0){'Pass'}else{'Fail'}
        Issues=@($issues.ToArray())
        RequestedMajorGenerationCount=[int]$ExecutionPlan.RequestedMajorGenerationCount
        ProductGroupFilterCount=@($ExecutionPlan.ProductGroupFilter).Count
        FullResearchTrackCount=[int]$ExecutionPlan.FullResearchTrackCount
        CoveredCertificateTrackCount=$coveredTracks.Count
        PlannedExecutionArtifactCount=@($ExecutionPlan.Resolution.ExecutionArtifacts).Count
        StaticAnalyzedArtifactCount=@($StaticAnalysis.Artifacts).Count
        NativeAnalyzedArtifactCount=@($NativeVerification.Artifacts).Count
        KernelCoverage=$KernelCoverage
    }
}


function Test-AmdGraphicsWindowsClientQualificationBoundarySelfTest {
    [CmdletBinding()]
    param()
    $artifact=[pscustomobject]@{ExecutionArtifactId=('sha256:'+('a'*64));InstallerSha256=('a'*64)}
    $basePlan=[pscustomobject][ordered]@{
        PolicyId='NewestSelectedMajorGenerationPerSelectionTrack/1';RequestedMajorGenerationCount=3;ProductGroupFilter=@();Status='Ready'
        FullResearchTrackCount=1;TargetReferences=@([pscustomobject]@{SelectionTrackKey='g1|WindowsClient|Adrenalin'})
        Resolution=[pscustomobject]@{ExecutionArtifacts=@($artifact)}
    }
    $static=[pscustomobject]@{Artifacts=@($artifact);Summary=[pscustomobject]@{UnexpectedStaticParseFailureCount=0;SignedDigestMismatchCount=0}}
    $native=[pscustomobject]@{Artifacts=@($artifact);ExecutionContext=[pscustomobject]@{ExecutionClass='WindowsClient'};Tool=[pscustomobject]@{Status='Available'};MutationPerformed=$false}
    $complete=Get-AmdGraphicsWindowsClientSignatureQualificationAssessment -ExecutionPlan $basePlan -StaticAnalysis $static -NativeVerification $native -KernelCoverage ([pscustomobject]@{CoverageGapKernelCount=0})
    $oneGeneration=ConvertFrom-CanonicalJson -Json (ConvertTo-CanonicalJson -InputObject $basePlan -Depth 10)
    $oneGeneration.RequestedMajorGenerationCount=1
    $oneGenerationResult=Get-AmdGraphicsWindowsClientSignatureQualificationAssessment -ExecutionPlan $oneGeneration -StaticAnalysis $static -NativeVerification $native -KernelCoverage ([pscustomobject]@{CoverageGapKernelCount=0})
    $filtered=ConvertFrom-CanonicalJson -Json (ConvertTo-CanonicalJson -InputObject $basePlan -Depth 10)
    $filtered.ProductGroupFilter=@('graphics|radeon-rx|*')
    $filteredResult=Get-AmdGraphicsWindowsClientSignatureQualificationAssessment -ExecutionPlan $filtered -StaticAnalysis $static -NativeVerification $native -KernelCoverage ([pscustomobject]@{CoverageGapKernelCount=0})
    $ok=([string]$complete.Status -eq 'Pass' -and [string]$oneGenerationResult.Status -eq 'Fail' -and [string]$filteredResult.Status -eq 'Fail')
    return [pscustomobject][ordered]@{
        Status=if($ok){'Pass'}else{'Fail'}
        CompleteThreeGenerationUnfiltered=[string]$complete.Status
        OneGenerationNarrowed=[string]$oneGenerationResult.Status
        ProductGroupFiltered=[string]$filteredResult.Status
    }
}

function New-AmdNativeVerificationAliasSet {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]$FileOccurrenceMap,
        [Parameter(Mandatory=$true)]$StaticById,
        [string]$OutputPath
    )

    $toolRoot=Get-AmdResearchToolkitRoot
    if(-not $OutputPath){$OutputPath=Join-Path $toolRoot 'inventory\native-verification-path-map.json'}
    $aliasRoot=Join-Path $toolRoot 'work\n'
    New-AmdDirectory -Path $aliasRoot|Out-Null
    $aliases=@{}
    $records=New-Object 'System.Collections.Generic.List[object]'
    $ordinal=0
    foreach($fileId in @($FileOccurrenceMap.Keys|Sort-Object)){
        $ordinal++
        $fileEvidence=$StaticById[$fileId]
        $occurrences=@($FileOccurrenceMap[$fileId].ToArray())
        if($occurrences.Count -eq 0){throw('No extracted occurrence exists for native file id {0}.' -f $fileId)}
        $sourcePath=[string]$occurrences[0].Path
        $extension=[IO.Path]::GetExtension($sourcePath).ToLowerInvariant()
        switch([string]$fileEvidence.FileType){
            'Catalog'{$extension='.cat'}
            'KernelBinary'{$extension='.sys'}
            'Library'{$extension='.dll'}
            'Executable'{$extension='.exe'}
            'CmsSignedData'{if($extension -notin @('.p7b','.p7s','.p7x')){$extension='.p7b'}}
            'CertificateFile'{if($extension -notin @('.cer','.crt','.der')){$extension='.cer'}}
        }
        if([string]::IsNullOrWhiteSpace($extension)-or $extension.Length -gt 8){$extension='.bin'}
        $aliasId=('f{0:D6}' -f $ordinal)
        $aliasPath=Join-Path $aliasRoot ($aliasId+$extension)
        if($aliasPath.Length -gt $script:AmdWindowsSafeFullPathLimit){throw('Native verification alias path exceeds the safe path limit: length={0}; path={1}' -f $aliasPath.Length,$aliasPath)}
        $expectedSha=([string]$fileId).Replace('sha256:','')
        $copyRequired=$true
        if(Test-Path -LiteralPath $aliasPath -PathType Leaf){
            try{$copyRequired=((Get-AmdSha256 -Path $aliasPath) -ne $expectedSha)}catch{$copyRequired=$true}
        }
        if($copyRequired){Copy-Item -LiteralPath $sourcePath -Destination $aliasPath -Force}
        $aliasSha=Get-AmdSha256 -Path $aliasPath
        if($aliasSha -ne $expectedSha){throw('Native verification alias SHA-256 mismatch for {0}: expected={1}; actual={2}' -f $aliasId,$expectedSha,$aliasSha)}
        $record=[pscustomobject][ordered]@{
            AliasId=$aliasId;FileId=[string]$fileId;FileType=[string]$fileEvidence.FileType;OriginalFileName=[string]$fileEvidence.FileName
            AliasPath=$aliasPath;AliasPathLength=$aliasPath.Length;SourcePathLength=$sourcePath.Length;Sha256=$aliasSha;ByteIdentical=$true
            Occurrences=@($occurrences|ForEach-Object{[pscustomobject][ordered]@{ArtifactId=[string]$_.ArtifactId;RelativePath=[string]$_.RelativePath}})
        }
        $records.Add($record)|Out-Null
        $aliases[$fileId]=$record
    }
    $result=[pscustomobject][ordered]@{SchemaVersion='amd-graphics-native-verification-path-map/1.0';ToolkitVersion=$script:AmdGraphicsResearchToolkitVersion;GeneratedAtUtc=Get-AmdUtcTimestamp;AliasRoot=$aliasRoot;AliasCount=$records.Count;SafeFullPathLimit=$script:AmdWindowsSafeFullPathLimit;Aliases=@($records.ToArray())}
    Write-AmdJsonFile -Path $OutputPath -Value $result -Depth 30
    return [pscustomobject][ordered]@{Map=$result;ByFileId=$aliases}
}

function Test-AmdNativeAliasLogic {
    [CmdletBinding()]
    param()
    $root='D:\AMD-Gfx\amd-graphics-driver-research'
    $path=$root+'\work\n\f000001.sys'
    $ok=($path.Length -lt $script:AmdWindowsSafeFullPathLimit -and [IO.Path]::GetExtension($path) -eq '.sys')
    return [pscustomobject][ordered]@{Status=if($ok){'Pass'}else{'Fail'};AliasPathLength=$path.Length;SafeFullPathLimit=$script:AmdWindowsSafeFullPathLimit}
}

function Invoke-AmdGraphicsSignatureStage {
    [CmdletBinding()]
    param(
        [string]$PlanPath,
        [string]$ExtractionPath,
        [string]$OutputPath,
        [string]$NativeVerificationPath,
        [string]$WindowsHostPosturePath,
        [string]$ServerHostPosturePath,
        [switch]$ReuseStaticAnalysis,
        [switch]$RequireWindowsClientQualification
    )

    $toolRoot=Get-AmdResearchToolkitRoot
    if(-not $PlanPath){$PlanPath=Join-Path $toolRoot 'inventory\certificate-verification-plan.json'}
    if(-not $ExtractionPath){$ExtractionPath=Join-Path $toolRoot 'inventory\extraction.json'}
    if(-not $OutputPath){$OutputPath=Join-Path $toolRoot 'inventory\signature-analysis.json'}
    if(-not $NativeVerificationPath){$NativeVerificationPath=Join-Path $toolRoot 'inventory\host\signature-native-verification.json'}
    if(-not $WindowsHostPosturePath){$WindowsHostPosturePath=Join-Path $toolRoot 'inventory\host\windows-host-security-posture.json'}
    if(-not $ServerHostPosturePath){$ServerHostPosturePath=Join-Path $toolRoot 'inventory\host\target-server-host-evidence.json'}
    if(-not(Test-Path -LiteralPath $PlanPath -PathType Leaf)){throw 'Signature requires inventory\certificate-verification-plan.json.'}
    if(-not(Test-Path -LiteralPath $ExtractionPath -PathType Leaf)){throw 'Signature requires inventory\extraction.json.'}

    $plan=Read-AmdJsonFile -Path $PlanPath
    if([string]$plan.Status -ne 'Ready' -or [string]$plan.Resolution.Status -ne 'Ready'){
        throw('Certificate verification execution plan is blocked: status={0}; missing={1}; ambiguous={2}.' -f [string]$plan.Status,[int]$plan.Resolution.MissingUrlTargetCount,[int]$plan.Resolution.AmbiguousUrlTargetCount)
    }
    $executionArtifacts=@(Get-AmdCollectionItems -Value $plan.Resolution.ExecutionArtifacts)
    if($executionArtifacts.Count -eq 0){throw 'Certificate verification execution plan contains zero execution artifacts.'}
    $extraction=Read-AmdJsonFile -Path $ExtractionPath
    $extracted=@(Get-AmdCollectionItems -Value $extraction.Releases)
    $null=Assert-AmdExtractionCompleteSet -Items @($extracted) -Context 'Graphics signature analysis'
    if($ReuseStaticAnalysis){
        $acquisitionPath=Join-Path $toolRoot 'inventory\acquisition.json'
        if(-not(Test-Path -LiteralPath $acquisitionPath -PathType Leaf)){throw 'SignatureNative reuse requires inventory\acquisition.json.'}
        $acquisition=Read-AmdJsonFile -Path $acquisitionPath
        $acquired=@(Get-AmdCollectionItems -Value $acquisition.Artifacts)
        foreach($target in $executionArtifacts){
            $expectedInstallerSha=([string]$target.InstallerSha256).ToLowerInvariant()
            $matches=@($acquired|Where-Object{([string]$_.Sha256).ToLowerInvariant() -eq $expectedInstallerSha -and [string]$_.Status -in @('Downloaded','Cached','Provided')})
            if($matches.Count -eq 0){throw('SignatureNative reuse cannot resolve acquired installer SHA-256 {0}.' -f $expectedInstallerSha)}
            $verified=$false
            foreach($match in $matches){
                $installerPath=[string]$match.LocalPath
                if(Test-Path -LiteralPath $installerPath -PathType Leaf){
                    if((Get-AmdSha256 -Path $installerPath) -eq $expectedInstallerSha){$verified=$true;break}
                }
            }
            if(-not $verified){throw('SignatureNative reuse installer bytes do not match saved SHA-256 {0}.' -f $expectedInstallerSha)}
        }
        Write-AmdOk ('SignatureNative installer-byte validation passed: {0} planned artifact(s).' -f $executionArtifacts.Count)
    }
    $runtimeContext=Get-AmdWindowsExecutionContext
    $signTool=Get-AmdWindowsSdkToolInfo -ToolName 'signtool.exe'
    if($RequireWindowsClientQualification -and $runtimeContext.ExecutionClass -ne 'WindowsClient'){
        throw('Windows Client signature qualification requires ExecutionClass=WindowsClient; observed {0}.' -f $runtimeContext.ExecutionClass)
    }
    if($RequireWindowsClientQualification -and $signTool.Status -ne 'Available'){
        throw('Windows Client signature qualification requires signtool.exe; observed status={0}.' -f $signTool.Status)
    }

    $toolchain=Get-AmdWindowsDriverToolchainCapabilityEvidence
    Write-AmdJsonFile -Path (Join-Path $toolRoot 'inventory\host\toolchain-capabilities-private.json') -Value $toolchain.PrivateEvidence -Depth 50
    Write-AmdJsonFile -Path (Join-Path $toolRoot 'inventory\toolchain-capabilities.json') -Value $toolchain.PublicSummary -Depth 50

    $contexts=New-Object 'System.Collections.Generic.List[object]'
    $fileOccurrenceMap=@{}
    $artifactOrdinal=0
    foreach($target in $executionArtifacts){
        $artifactOrdinal++
        $matches=@($extracted|Where-Object{([string]$_.InstallerSha256).ToLowerInvariant() -eq ([string]$target.InstallerSha256).ToLowerInvariant()})
        if($matches.Count -ne 1){throw('Planned installer SHA-256 must resolve to exactly one extraction record: {0}; matches={1}.' -f [string]$target.InstallerSha256,$matches.Count)}
        $release=$matches[0]
        $root=[string]$release.ExtractionRoot
        if(-not(Test-Path -LiteralPath $root -PathType Container)){throw('Planned certificate target extraction root is unavailable: {0}.' -f [string]$target.ExecutionArtifactId)}
        $candidateFiles=@(Get-ChildItem -LiteralPath $root -File -Recurse -ErrorAction SilentlyContinue|Where-Object{Test-AmdStaticSignatureCandidateFile -File $_}|Sort-Object FullName)
        $fileIds=New-Object 'System.Collections.Generic.List[string]'
        foreach($file in $candidateFiles){
            $sha=Get-AmdSha256 -Path $file.FullName
            $fileId='sha256:'+$sha
            if(-not $fileOccurrenceMap.ContainsKey($fileId)){$fileOccurrenceMap[$fileId]=New-Object 'System.Collections.Generic.List[object]'}
            $relative=$file.FullName.Substring($root.Length).TrimStart('\','/')
            $fileOccurrenceMap[$fileId].Add([pscustomobject][ordered]@{ArtifactId=[string]$target.ExecutionArtifactId;Root=$root;Path=$file.FullName;RelativePath=$relative})|Out-Null
            if(-not $fileIds.Contains($fileId)){$fileIds.Add($fileId)|Out-Null}
        }
        $contexts.Add([pscustomobject][ordered]@{
            Target=$target
            Extraction=$release
            Root=$root
            CandidateFileCount=$candidateFiles.Count
            FileIds=@($fileIds.ToArray())
        })|Out-Null
        Write-AmdStep ('Signature target [{0}/{1}] {2}; unique candidate references={3}.' -f $artifactOrdinal,$executionArtifacts.Count,[string]$target.ExecutionArtifactId,$fileIds.Count)
    }

    $certificateStore=@{}
    $staticFiles=New-Object 'System.Collections.Generic.List[object]'
    $staticById=@{}
    $staticAnalysisMode='FreshStaticAnalysis'
    $reusedStaticSourceSha256=$null
    if($ReuseStaticAnalysis){
        if(-not(Test-Path -LiteralPath $OutputPath -PathType Leaf)){throw 'SignatureNative reuse requires the existing inventory\signature-analysis.json from the reviewed full run.'}
        $reusedStaticSourceSha256=Get-AmdSha256 -Path $OutputPath
        $reusedStatic=Read-AmdJsonFile -Path $OutputPath
        if([string]$reusedStatic.SchemaVersion -ne $script:AmdDriverSignatureAnalysisSchemaVersion){throw('Static signature reuse schema mismatch: {0}' -f [string]$reusedStatic.SchemaVersion)}
        foreach($file in @(Get-AmdCollectionItems -Value $reusedStatic.Files)){
            $id=[string]$file.FileId
            if([string]::IsNullOrWhiteSpace($id)){throw 'Static signature reuse contains a file without FileId.'}
            $staticFiles.Add($file)|Out-Null
            $staticById[$id]=$file
        }
        foreach($certificate in @(Get-AmdCollectionItems -Value $reusedStatic.Certificates)){
            $key=if($certificate.PSObject.Properties['DerSha256'] -and $certificate.DerSha256){[string]$certificate.DerSha256}elseif($certificate.PSObject.Properties['CertificateId'] -and $certificate.CertificateId){[string]$certificate.CertificateId}else{[guid]::NewGuid().ToString('N')}
            $certificateStore[$key]=$certificate
        }
        $missingIds=@($fileOccurrenceMap.Keys|Where-Object{-not $staticById.ContainsKey($_)})
        $extraIds=@($staticById.Keys|Where-Object{-not $fileOccurrenceMap.ContainsKey($_)})
        if($missingIds.Count -gt 0 -or $extraIds.Count -gt 0){throw('Static signature reuse file-set mismatch: missing={0}; extra={1}.' -f $missingIds.Count,$extraIds.Count)}
        $planInstallerIds=@($executionArtifacts|ForEach-Object{[string]$_.InstallerSha256}|Sort-Object -Unique)
        $staticInstallerIds=@((Get-AmdCollectionItems -Value $reusedStatic.Artifacts)|ForEach-Object{[string]$_.InstallerSha256}|Sort-Object -Unique)
        if(($planInstallerIds -join '|') -ne ($staticInstallerIds -join '|')){throw 'Static signature reuse installer SHA-256 set does not match the current certificate execution plan.'}
        if([int]$reusedStatic.Summary.UnexpectedStaticParseFailureCount -ne 0 -or [int]$reusedStatic.Summary.SignedDigestMismatchCount -ne 0){throw 'Static signature reuse is not eligible because the saved analysis contains parse failures or signed-content digest mismatches.'}
        $staticAnalysisMode='ReusedValidatedStaticAnalysis'
        Write-AmdOk ('Validated and reused static signature evidence: files={0}; source SHA-256={1}.' -f $staticFiles.Count,$reusedStaticSourceSha256)
    }
    else{
        $fileOrdinal=0
        foreach($fileId in @($fileOccurrenceMap.Keys|Sort-Object)){
            $fileOrdinal++
            $occurrences=@($fileOccurrenceMap[$fileId].ToArray())
            $representative=$occurrences[0]
            $occurrenceLabels=@($occurrences|ForEach-Object{('{0}|{1}' -f [string]$_.ArtifactId,[string]$_.RelativePath)}|Sort-Object -Unique)
            $evidence=Get-AmdStaticFileSignatureEvidence -Path ([string]$representative.Path) -Occurrences $occurrenceLabels -CertificateStore $certificateStore
            $staticFiles.Add($evidence)|Out-Null
            $staticById[$fileId]=$evidence
            if($fileOrdinal -eq 1 -or ($fileOrdinal%25)-eq 0 -or $fileOrdinal -eq $fileOccurrenceMap.Count){
                Write-AmdStep ('Static signature file {0}/{1}; elapsed={2}.' -f $fileOrdinal,$fileOccurrenceMap.Count,(Format-AmdElapsed ((Get-Date)-$script:AmdCurrentStageStart)))
            }
        }
    }

    $nativeAliasSet=$null
    if($runtimeContext.ExecutionClass -in @('WindowsClient','WindowsServer','WindowsOther')){$nativeAliasSet=New-AmdNativeVerificationAliasSet -FileOccurrenceMap $fileOccurrenceMap -StaticById $staticById}

    $staticArtifacts=New-Object 'System.Collections.Generic.List[object]'
    $nativeArtifacts=New-Object 'System.Collections.Generic.List[object]'
    foreach($context in @($contexts.ToArray())){
        $target=$context.Target
        $staticArtifacts.Add([pscustomobject][ordered]@{
            ExecutionArtifactId=[string]$target.ExecutionArtifactId
            InstallerSha256=[string]$target.InstallerSha256
            RepresentativeArtifactKey=[string]$target.RepresentativeArtifactKey
            SelectionTrackReferences=@($target.SelectionTrackReferences)
            ProductGroupReferences=@($target.ProductGroupReferences)
            ArtifactRoles=@($target.ArtifactRoles)
            Status='Analyzed'
            CandidateFileReferenceCount=@($context.FileIds).Count
            FileIds=@($context.FileIds)
        })|Out-Null

        if($runtimeContext.ExecutionClass -notin @('WindowsClient','WindowsServer','WindowsOther')){continue}
        $nativeFiles=New-Object 'System.Collections.Generic.List[object]'
        $verificationPathByFileId=@{}
        foreach($fileId in @($context.FileIds)){
            $fileEvidence=$staticById[$fileId]
            $occurrence=@($fileOccurrenceMap[$fileId].ToArray()|Where-Object{[string]$_.ArtifactId -eq [string]$target.ExecutionArtifactId}|Select-Object -First 1)
            if($occurrence.Count -eq 0){continue}
            if($null -eq $nativeAliasSet -or -not $nativeAliasSet.ByFileId.ContainsKey($fileId)){throw('Short native verification alias is missing for {0}.' -f $fileId)}
            $aliasRecord=$nativeAliasSet.ByFileId[$fileId]
            $nativePath=[string]$aliasRecord.AliasPath
            $pathKind='ByteIdenticalShortPathAlias'
            $verificationPathByFileId[$fileId]=$nativePath
            $authenticode=Get-AmdWindowsAuthenticodeObservation -Path $nativePath
            $catalogEnumeration=$null
            $catalogHash=$null
            if($fileEvidence.FileType -eq 'Catalog'){$catalogEnumeration=Get-AmdWindowsCatalogMemberEvidence -Path $nativePath}
            elseif($fileEvidence.FileType -eq 'KernelBinary'){$catalogHash=Get-AmdWindowsCatalogHashEvidence -Path $nativePath}
            $checks=@()
            if($signTool.Status -eq 'Available'){$checks=@(Get-AmdSignToolVerificationEvidence -SignToolPath $signTool.Path -Path $nativePath -FileType $fileEvidence.FileType)}
            $nativeFiles.Add([pscustomobject][ordered]@{
                FileId=$fileId
                FileName=$fileEvidence.FileName
                FileType=$fileEvidence.FileType
                VerificationPathKind=$pathKind
                VerificationAliasId=[string]$aliasRecord.AliasId
                OriginalPathLength=[int]$aliasRecord.SourcePathLength
                VerificationPathLength=[int]$aliasRecord.AliasPathLength
                ByteIdentical=[bool]$aliasRecord.ByteIdentical
                Authenticode=$authenticode
                CatalogEnumeration=$catalogEnumeration
                CatalogHash=$catalogHash
                SignToolChecks=@($checks|ForEach-Object{ConvertTo-AmdGraphicsPrivateSignToolCheck -Check $_})
                SanitizedSignToolSummary=@($checks|ForEach-Object{ConvertTo-AmdGraphicsPublicSignToolCheck -Check $_})
                SignToolStatus=if($signTool.Status -eq 'Available'){'Available'}else{'NotObservedToolUnavailable'}
            })|Out-Null
        }

        if($signTool.Status -eq 'Available'){
            $catalogIdsByDigest=@{}
            foreach($catalog in @($nativeFiles.ToArray()|Where-Object{$_.FileType -eq 'Catalog' -and $_.CatalogEnumeration -and $_.CatalogEnumeration.Status -eq 'Enumerated'})){
                foreach($member in @($catalog.CatalogEnumeration.Members)){
                    $tag=([string]$member.ReferenceTag).ToUpperInvariant()
                    if([string]::IsNullOrWhiteSpace($tag)){continue}
                    if(-not $catalogIdsByDigest.ContainsKey($tag)){$catalogIdsByDigest[$tag]=New-Object 'System.Collections.Generic.List[string]'}
                    if(-not $catalogIdsByDigest[$tag].Contains([string]$catalog.FileId)){$catalogIdsByDigest[$tag].Add([string]$catalog.FileId)|Out-Null}
                }
            }
            foreach($kernel in @($nativeFiles.ToArray()|Where-Object{$_.FileType -eq 'KernelBinary'})){
                $catalogIds=New-Object 'System.Collections.Generic.List[string]'
                if($kernel.CatalogHash){
                    foreach($digest in @([string]$kernel.CatalogHash.Sha256,[string]$kernel.CatalogHash.Sha1)){
                        if([string]::IsNullOrWhiteSpace($digest)){continue}
                        $key=$digest.ToUpperInvariant()
                        if($catalogIdsByDigest.ContainsKey($key)){foreach($id in @($catalogIdsByDigest[$key].ToArray())){if(-not $catalogIds.Contains($id)){$catalogIds.Add($id)|Out-Null}}}
                    }
                }
                $targetChecks=New-Object 'System.Collections.Generic.List[object]'
                foreach($catalogId in @($catalogIds.ToArray())){
                    if($verificationPathByFileId.ContainsKey($catalogId)-and $verificationPathByFileId.ContainsKey([string]$kernel.FileId)){
                        foreach($check in @(Get-AmdCatalogBoundSignToolEvidence -SignToolPath $signTool.Path -DriverPath $verificationPathByFileId[[string]$kernel.FileId] -CatalogPath $verificationPathByFileId[$catalogId] -CatalogFileId $catalogId)){$targetChecks.Add($check)|Out-Null}
                    }
                }
                if($targetChecks.Count -gt 0){
                    $kernel.SignToolChecks=@($kernel.SignToolChecks)+@($targetChecks.ToArray()|ForEach-Object{ConvertTo-AmdGraphicsPrivateSignToolCheck -Check $_})
                    $kernel.SanitizedSignToolSummary=@($kernel.SanitizedSignToolSummary)+@($targetChecks.ToArray()|ForEach-Object{ConvertTo-AmdGraphicsPublicSignToolCheck -Check $_})
                }else{
                    $kernel|Add-Member -NotePropertyName CatalogBoundTargetVerification -NotePropertyValue ([pscustomobject][ordered]@{Status='NotObservedCatalogAssociationUnavailable';MatchedCatalogCount=0}) -Force
                }
            }
        }
        $nativeArtifacts.Add([pscustomobject][ordered]@{
            ExecutionArtifactId=[string]$target.ExecutionArtifactId
            InstallerSha256=[string]$target.InstallerSha256
            SelectionTrackReferences=@($target.SelectionTrackReferences)
            SignToolStatus=$signTool.Status
            SignToolVersion=$signTool.Version
            Files=@($nativeFiles.ToArray())
        })|Out-Null
    }

    $unexpectedParseFailures=0
    $digestMismatches=0
    foreach($file in @($staticFiles.ToArray())){
        foreach($envelope in @($file.Envelopes)){
            foreach($node in @(Get-AmdGraphicsSignatureEnvelopeTree -Envelope $envelope)){
                if([string]$node.Status -notin @('Parsed','NotApplicable')){$unexpectedParseFailures++}
                foreach($signer in @($node.Signers)){
                    if($signer.PSObject.Properties['SignedContentDigestMatch'] -and $signer.SignedContentDigestMatch -eq $false){$digestMismatches++}
                }
            }
        }
    }
    $certificates=@($certificateStore.Keys|Sort-Object|ForEach-Object{$certificateStore[$_]})
    $staticOutput=[pscustomobject][ordered]@{
        SchemaVersion=$script:AmdDriverSignatureAnalysisSchemaVersion
        ToolkitVersion=$script:AmdGraphicsResearchToolkitVersion
        GeneratedAtUtc=Get-AmdUtcTimestamp
        EvidenceScope='Static'
        AnalysisMode=$staticAnalysisMode
        ReusedStaticSourceSha256=$reusedStaticSourceSha256
        ArtifactSelectionPolicy=[string]$plan.PolicyId
        CertificateVerificationExecutionPlan=(ConvertTo-AmdPublicRepositoryObject -Value $plan)
        AnalysisBoundary='Static CMS/PKCS#7, nested-signature, certificate and signed-PE-digest evidence is host-neutral. Windows trust policy, installation, kernel load and device function remain separate evidence scopes.'
        Artifacts=@($staticArtifacts.ToArray())
        Files=@($staticFiles.ToArray())
        Certificates=$certificates
        Summary=[pscustomobject][ordered]@{
            FullResearchSelectionCount=[int]$plan.FullResearchSelectionCount
            CertificateTrackReferenceCount=[int]$plan.CertificateTrackReferenceCount
            PlannedUniqueUrlTargetCount=[int]$plan.PlannedUniqueUrlTargetCount
            AnalyzedUniqueInstallerCount=$staticArtifacts.Count
            UniqueCandidateFileContentCount=$staticFiles.Count
            UniqueCertificateCount=$certificates.Count
            UnexpectedStaticParseFailureCount=$unexpectedParseFailures
            SignedDigestMismatchCount=$digestMismatches
            ExecutionClass=[string]$runtimeContext.ExecutionClass
        }
    }
    Write-AmdJsonFile -Path $OutputPath -Value $staticOutput -Depth 100

    $nativeOutput=[pscustomobject][ordered]@{
        SchemaVersion=$script:AmdDriverSignatureNativeSchemaVersion
        ToolkitVersion=$script:AmdGraphicsResearchToolkitVersion
        CollectedAtUtc=Get-AmdUtcTimestamp
        EvidenceScope='WindowsNative'
        ArtifactSelectionPolicy=[string]$plan.PolicyId
        ExecutionContext=$runtimeContext
        Tool=[pscustomobject][ordered]@{Name='signtool.exe';Status=$signTool.Status;Version=$signTool.Version;FileVersion=$signTool.FileVersion;ProductVersion=$signTool.ProductVersion;Sha256=$signTool.Sha256;SizeBytes=$signTool.SizeBytes;Architecture=$signTool.Architecture;Path=$signTool.Path;PortablePath=$signTool.PortablePath;KitVersion=$signTool.KitVersion}
        ToolchainCapabilityReference='inventory/host/toolchain-capabilities-private.json'
        ToolchainCapabilitySummaryReference='inventory/toolchain-capabilities.json'
        NativeVerificationPathMapReference='inventory/native-verification-path-map.json'
        StaticAnalysisMode=$staticAnalysisMode
        ReusedStaticSourceSha256=$reusedStaticSourceSha256
        Artifacts=@($nativeArtifacts.ToArray())
        MutationPerformed=$false
    }
    $coverage=if($runtimeContext.ExecutionClass -in @('WindowsClient','WindowsServer','WindowsOther')){Get-AmdKernelSignatureCoverageAssessment -NativeData ([pscustomobject]@{Releases=@($nativeArtifacts.ToArray())})}else{$null}
    $qualification=if($RequireWindowsClientQualification){
        Get-AmdGraphicsWindowsClientSignatureQualificationAssessment -ExecutionPlan $plan -StaticAnalysis $staticOutput -NativeVerification $nativeOutput -KernelCoverage $coverage
    }else{
        [pscustomobject][ordered]@{SchemaVersion='amd-graphics-windows-client-signature-qualification/1.0';Requested=$false;Status='NotRequested'}
    }
    $nativeOutput|Add-Member -NotePropertyName KernelSignatureCoverage -NotePropertyValue $coverage -Force
    $nativeOutput|Add-Member -NotePropertyName WindowsClientQualification -NotePropertyValue $qualification -Force
    Write-AmdJsonFile -Path $NativeVerificationPath -Value $nativeOutput -Depth 100
    if($runtimeContext.ExecutionClass -in @('WindowsClient','WindowsServer','WindowsOther')){
        $posture=Get-AmdWindowsHostSecurityPosture
        Write-AmdJsonFile -Path $WindowsHostPosturePath -Value $posture -Depth 40
        if($runtimeContext.ExecutionClass -eq 'WindowsServer'){Write-AmdJsonFile -Path $ServerHostPosturePath -Value (Get-AmdTargetServerHostEvidence -WindowsHostSecurityPosture $posture) -Depth 50}
    }
    if($RequireWindowsClientQualification -and [string]$qualification.Status -ne 'Pass'){
        throw('Windows Client signature qualification failed: {0}' -f (@($qualification.Issues)-join ' | '))
    }
    Write-AmdOk ('Signature analysis complete: full selections={0}; newest track references={1}; unique installer bytes={2}; unique signed-content candidates={3}; WindowsNative={4}.' -f [int]$plan.FullResearchSelectionCount,[int]$plan.CertificateTrackReferenceCount,$staticArtifacts.Count,$staticFiles.Count,[string]$runtimeContext.ExecutionClass)
    return $staticOutput
}

function Clear-AmdRunScopedDeepAnalysisOutputs {
    [CmdletBinding()]
    param()

    $inventoryRoot=Join-Path (Get-AmdResearchToolkitRoot) 'inventory'
    foreach($name in @(
        'acquisition.json',
        'artifact-path-map.json',
        'extraction.json',
        'extraction-path-safety.json',
        'driver-packages.json',
        'driver-packages-integrity.json',
        'certificate-verification-plan.json',
        'signature-analysis.json',
        'native-verification-path-map.json',
        'toolchain-capabilities.json',
        'build-integrity.json',
        'embedded-installer-metadata.json',
        'amd-graphics-driver-inventory.json'
    )){
        $path=Join-Path $inventoryRoot $name
        if(Test-Path -LiteralPath $path -PathType Leaf){
            Remove-Item -LiteralPath $path -Force -ErrorAction SilentlyContinue
        }
    }
    $detailRoot=Join-Path $inventoryRoot 'driver-packages-artifacts'
    if(Test-Path -LiteralPath $detailRoot -PathType Container){
        Remove-Item -LiteralPath $detailRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
    $hostRoot=Join-Path $inventoryRoot 'host'
    if(Test-Path -LiteralPath $hostRoot -PathType Container){
        Remove-Item -LiteralPath $hostRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}

function Resolve-AmdRequestedStages {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$RequestedStages
    )

    $allowed = @('PathSafety', 'Test', 'ProductDiscover', 'ProductMetadata', 'Select', 'Discover', 'Metadata', 'Acquire', 'Extract', 'Inspect', 'Signature', 'SignatureNative', 'Build', 'All')
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
        if ($script:LocalInstallerPath.Count -gt 0) {
            return @('PathSafety', 'Test', 'Acquire', 'Extract', 'Inspect', 'Signature', 'Build')
        }
        if ($script:FullHistoricalResearch -or $script:ReleaseVersion.Count -gt 0 -or $script:ReleaseKey.Count -gt 0) {
            return @('PathSafety', 'Test', 'Discover', 'Metadata', 'Acquire', 'Extract', 'Inspect', 'Build')
        }
        return @('PathSafety', 'Test', 'ProductDiscover', 'ProductMetadata', 'Select', 'Acquire', 'Extract', 'Inspect', 'Signature', 'Build')
    }

    return @('PathSafety')+@($normalized|Where-Object{$_ -ne 'PathSafety'})
}

$resolvedStages = @()
$finalAssessment = $null
$finalExitCode = 1

$invocationEvidence = [pscustomobject][ordered]@{
    Stages = @($Stages)
    ReleaseVersion = @($ReleaseVersion)
    ReleaseKey = @($ReleaseKey)
    ProductGroupKey = @($ProductGroupKey)
    AdditionalProductPageUrl = @($AdditionalProductPageUrl)
    MajorGenerationCount = $MajorGenerationCount
    MaximumSelectedArtifactCount = $MaximumSelectedArtifactCount
    MaximumEstimatedDownloadGiB = $MaximumEstimatedDownloadGiB
    DownloadRetryCount = $DownloadRetryCount
    DownloadTimeoutSeconds = $DownloadTimeoutSeconds
    AllowSeedOnlyProductDiscovery = [bool]$AllowSeedOnlyProductDiscovery
    FullHistoricalResearch = [bool]$FullHistoricalResearch
    LocalInstallerPath = @($LocalInstallerPath)
    SevenZipPath = $SevenZipPath
    MaxDepth = $MaxDepth
    SitemapUri = @($SitemapUri)
    AdditionalReleaseNotesUrl = @($AdditionalReleaseNotesUrl)
    EvidenceOutputRoot = $EvidenceOutputRoot
    EvidenceLabel = $EvidenceLabel
    EvidenceRetention = $EvidenceRetention
    PublicOutputRoot = $PublicOutputRoot
    SkipPublicExport = [bool]$SkipPublicExport
    SkipEvidenceArchive = [bool]$SkipEvidenceArchive
    IncludeInstallersInEvidence = [bool]$IncludeInstallersInEvidence
    RequireWindowsClientSignatureQualification = [bool]$RequireWindowsClientSignatureQualification
    AllowNonAmdHost = [bool]$AllowNonAmdHost
    Force = [bool]$Force
}

try {
    Write-Host '=== AMD Graphics Driver Research Toolkit — BOOTSTRAP ===' -ForegroundColor Cyan
    Write-Host ('Toolkit    : {0}' -f $script:AmdGraphicsResearchToolkitVersion)
    Write-Host ('PowerShell : {0}' -f $PSVersionTable.PSVersion)
    Write-Host ('Requested  : {0}' -f (@($Stages)-join ', '))
    $resolvedStages = @(Resolve-AmdRequestedStages -RequestedStages $Stages)
    $startupPathAssessment=Get-AmdPathSafetyAssessment -SevenZipPath $SevenZipPath -ResolvedStages $resolvedStages
    if([string]$startupPathAssessment.Status -eq 'Blocked'){
        Write-Host '=== AMD Graphics Driver Research Toolkit — PATH SAFETY BLOCK ===' -ForegroundColor Red
        Write-Host ('Root            : {0}' -f [string]$startupPathAssessment.ToolRoot)
        Write-Host ('Root length     : {0} (maximum {1})' -f [int]$startupPathAssessment.ToolRootLength,[int]$startupPathAssessment.Policy.MaximumToolRootLength)
        Write-Host ('Predicted max   : {0} (safe limit {1})' -f [int]$startupPathAssessment.PredictedPaths.MaximumDesignedExtractionPathLength,[int]$startupPathAssessment.Policy.SafeFullPathLimit)
        Write-Host ('Move whole tool : {0}' -f [string]$startupPathAssessment.RecommendedToolRoot) -ForegroundColor Yellow
        foreach($issue in @($startupPathAssessment.Issues)){Write-Host ('BLOCK: {0}' -f [string]$issue) -ForegroundColor Red}
        Write-Host 'No AMD network request was started.' -ForegroundColor Yellow
        throw('PathSafety BLOCKED: {0}' -f (@($startupPathAssessment.Issues)-join ' | '))
    }

    $baselineConsumers=@($resolvedStages|Where-Object{$_ -notin @('PathSafety','Test')})
    if($baselineConsumers.Count -eq 0){
        Write-Host '[BOOTSTRAP] Runtime baseline restore skipped: PathSafety/Test-only execution does not consume the research baseline.' -ForegroundColor Green
    }else{
        Initialize-AmdRuntimeBaselineFromPublicSurface
    }

    Write-Host '[BOOTSTRAP] Initializing tool-local evidence session and Canonical JSON runtime.' -ForegroundColor Cyan
    $null = Start-AmdResearchEvidenceSession `
        -OutputRoot $EvidenceOutputRoot `
        -Label $EvidenceLabel `
        -EvidenceRetention $EvidenceRetention `
        -InvocationParameters $invocationEvidence

    if($RequireWindowsClientSignatureQualification){
        if($resolvedStages -notcontains 'Signature' -and $resolvedStages -notcontains 'SignatureNative'){throw 'Windows Client signature qualification requires the Signature or SignatureNative stage.'}
        if($resolvedStages -contains 'Signature' -and $resolvedStages -contains 'SignatureNative'){throw 'Signature and SignatureNative are mutually exclusive in one run.'}
        if($LocalInstallerPath.Count -gt 0 -or $FullHistoricalResearch -or $ReleaseVersion.Count -gt 0 -or $ReleaseKey.Count -gt 0){throw 'Windows Client signature qualification requires the default product-driven selected corpus; local or historical overrides are not permitted.'}
        if($ProductGroupKey.Count -gt 0){throw 'Windows Client signature qualification requires all discovered product groups; -ProductGroupKey is not permitted.'}
        if($MajorGenerationCount -ne 3){throw 'Windows Client signature qualification requires -MajorGenerationCount 3 so ordinary research retains the newest three generations before certificate narrowing.'}
        if($AllowSeedOnlyProductDiscovery){throw 'Windows Client signature qualification does not permit -AllowSeedOnlyProductDiscovery.'}
        if($AllowNonAmdHost){throw 'Windows Client signature qualification does not permit -AllowNonAmdHost.'}
        if(-not $SkipPublicExport){throw 'Windows Client signature qualification requires -SkipPublicExport so qualification cannot publish an unreviewed corpus.'}
        if($IncludeInstallersInEvidence){throw 'Windows Client signature qualification does not permit installer binaries in the evidence ZIP.'}
        if($SkipEvidenceArchive){throw 'Windows Client signature qualification requires an Evidence ZIP; do not use -SkipEvidenceArchive.'}
    }
    $script:AmdResolvedStageCount = $resolvedStages.Count
    $script:AmdStageOrdinal = 0

    Write-Host '=== AMD Graphics Driver Research Toolkit ==='
    Write-Host ('Toolkit    : {0}' -f $script:AmdGraphicsResearchToolkitVersion)
    $startupPlatform = Get-AmdPlatformInfo
    Write-Host ('PowerShell : {0}' -f $PSVersionTable.PSVersion)
    Write-Host ('Platform   : {0} ({1})' -f $startupPlatform.PlatformFamily, $startupPlatform.OSDescription)
    Write-Host ('Stages     : {0}' -f ($resolvedStages -join ', '))
    Write-Host ('Started    : {0}' -f $script:AmdRunStartTime.ToString('yyyy-MM-dd HH:mm:ss'))
    Write-Host ('Root       : {0}' -f $script:AmdGraphicsResearchToolkitRoot)
    if ($null -ne $script:AmdEvidenceContext) {
        Write-Host ('Evidence ZIP planned : {0}' -f $script:AmdEvidenceContext.ZipPath)
        Write-Host ('Evidence work dir    : {0}' -f $script:AmdEvidenceContext.EvidenceDirectory)
    }
    Write-Host ('Public      : {0}' -f $script:AmdPublicOutputRoot)
    Write-Host ''

    $pipelineStopReason = $null

    foreach ($stage in $resolvedStages) {
        if ($pipelineStopReason) {
            $null = Invoke-AmdTrackedStage -Name $stage -SkippedReason ('Prerequisite pipeline stage did not complete: {0}' -f $pipelineStopReason)
            Write-Host ''
            continue
        }

        $stageResult = $null

        switch ($stage) {
            'PathSafety' {
                $pathAssessment=$startupPathAssessment
                if([string]$pathAssessment.Status -eq 'Blocked'){
                    $reason=(@($pathAssessment.Issues)+@([string]$pathAssessment.OperatorInstruction)) -join ' | '
                    $stageResult=Invoke-AmdTrackedStage -Name 'PathSafety' -BlockedReason $reason
                }else{
                    $stageResult=Invoke-AmdTrackedStage -Name 'PathSafety' -Body {
                        Write-AmdOk ('Path safety passed: root length={0}/{1}; predicted maximum={2}/{3}.' -f $pathAssessment.ToolRootLength,$pathAssessment.Policy.MaximumToolRootLength,$pathAssessment.PredictedPaths.MaximumDesignedExtractionPathLength,$pathAssessment.Policy.SafeFullPathLimit)
                        $pathAssessment
                    }
                }
            }

            'Test' {
                $stageResult = Invoke-AmdTrackedStage -Name 'Test' -Body {
                    $envResult = Invoke-AmdResearchEnvironmentTest -SevenZipPath $SevenZipPath
                    $envResult | Format-List | Out-Host
                }
            }

            'ProductDiscover' {
                $stageResult = Invoke-AmdTrackedStage -Name 'ProductDiscover' -Body {
                    Invoke-AmdProductDiscoverStage `
                        -SitemapUri $SitemapUri `
                        -AdditionalProductPageUrl $AdditionalProductPageUrl
                }
            }

            'ProductMetadata' {
                $stageResult = Invoke-AmdTrackedStage -Name 'ProductMetadata' -Body {
                    $stageArgs = @{
                        RetryCount = $ProductMetadataRetryCount
                        RequestDelayMilliseconds = $ProductMetadataRequestDelayMilliseconds
                    }
                    if ($Force) { $stageArgs['Force'] = $true }
                    Invoke-AmdProductMetadataStage @stageArgs
                }
            }

            'Select' {
                $stageResult = Invoke-AmdTrackedStage -Name 'Select' -Body {
                    Invoke-AmdSelectStage `
                        -MajorGenerationCount $MajorGenerationCount `
                        -ProductGroupKey $ProductGroupKey `
                        -MaximumSelectedArtifactCount $MaximumSelectedArtifactCount `
                        -MaximumEstimatedDownloadGiB $MaximumEstimatedDownloadGiB
                }
            }

            'Discover' {
                $stageResult = Invoke-AmdTrackedStage -Name 'Discover' -Body {
                    Invoke-AmdDiscoverStage `
                        -SitemapUri $SitemapUri `
                        -AdditionalReleaseNotesUrl $AdditionalReleaseNotesUrl
                }
            }

            'Metadata' {
                $stageResult = Invoke-AmdTrackedStage -Name 'Metadata' -Body {
                    $stageArgs = @{}
                    if ($Force) { $stageArgs['Force'] = $true }
                    Invoke-AmdMetadataStage @stageArgs
                }
            }

            'Acquire' {
                # Remove only transient deep-analysis outputs. Canonical historical
                # inventory/releases/** is preserved. This prevents a blocked/failed
                # current run from being mistaken for successful current-run data.
                Clear-AmdRunScopedDeepAnalysisOutputs

                $acquireBlockReason = $null
                if ($LocalInstallerPath.Count -eq 0 -and -not $FullHistoricalResearch -and $ReleaseVersion.Count -eq 0 -and $ReleaseKey.Count -eq 0) {
                    $productCatalogPath = Join-Path (Get-AmdResearchToolkitRoot) 'inventory\products.json'
                    $productMappingPath = Join-Path (Get-AmdResearchToolkitRoot) 'inventory\product-driver-mapping.json'
                    $selectedMetadataPath = Join-Path (Get-AmdResearchToolkitRoot) 'inventory\selected-release-metadata.json'

                    if (-not (Test-Path -LiteralPath $selectedMetadataPath -PathType Leaf)) {
                        $acquireBlockReason = 'Product-driven Select did not produce inventory\selected-release-metadata.json. Review ProductDiscover/ProductMetadata/Select before acquisition.'
                    }
                    elseif (Test-Path -LiteralPath $productCatalogPath -PathType Leaf) {
                        $productCatalog = Read-AmdJsonFile -Path $productCatalogPath
                        if ($productCatalog.PSObject.Properties['Completeness'] -and [string]$productCatalog.Completeness -eq 'SeedOnlyFallback' -and -not $AllowSeedOnlyProductDiscovery) {
                            $acquireBlockReason = 'Product discovery is SeedOnlyFallback because no curated product-group catalog or usable sitemap product pages were available. Acquisition was intentionally blocked before any download. Review products.json/selection-plan.json, supply -AdditionalProductPageUrl/-ProductGroupKey, or explicitly use -AllowSeedOnlyProductDiscovery for representative-seed qualification.'
                        }
                    }
                    if (-not $acquireBlockReason -and (Test-Path -LiteralPath $productMappingPath -PathType Leaf)) {
                        $productMapping = Read-AmdJsonFile -Path $productMappingPath
                        if ($productMapping.PSObject.Properties['MetadataCompleteness'] -and [string]$productMapping.MetadataCompleteness -ne 'Complete') {
                            $acquireBlockReason = ('Product metadata coverage is {0}: latest fetch failures={1}; previous fetch failures={2}; products with no graphics driver entries={3}. Acquisition was blocked to prevent a partial three-generation baseline.' -f [string]$productMapping.MetadataCompleteness,[int]$productMapping.LatestFetchFailureCount,[int]$productMapping.PreviousFetchFailureCount,[int]$productMapping.NoDriverEntryProductCount)
                        }
                    }

                    if (-not $acquireBlockReason -and (Test-Path -LiteralPath $selectedMetadataPath -PathType Leaf)) {
                        $selectedMetadata = Read-AmdJsonFile -Path $selectedMetadataPath
                        if (@(Get-AmdCollectionItems -Value $selectedMetadata.Releases).Count -eq 0) {
                            $acquireBlockReason = 'Product-driven selection metadata contains zero release records; acquisition was blocked.'
                        }
                    }
                }

                if ($acquireBlockReason) {
                    $stageResult = Invoke-AmdTrackedStage -Name 'Acquire' -BlockedReason $acquireBlockReason
                }
                else {
                    $stageResult = Invoke-AmdTrackedStage -Name 'Acquire' -Body {
                        $stageArgs = @{}
                        if ($ReleaseVersion.Count -gt 0) { $stageArgs['ReleaseVersion'] = $ReleaseVersion }
                        if ($ReleaseKey.Count -gt 0) { $stageArgs['ReleaseKey'] = $ReleaseKey }
                        if ($LocalInstallerPath.Count -gt 0) { $stageArgs['LocalInstallerPath'] = $LocalInstallerPath }
                        elseif (-not $FullHistoricalResearch -and $ReleaseVersion.Count -eq 0 -and $ReleaseKey.Count -eq 0) {
                            $stageArgs['MetadataPath'] = Join-Path (Get-AmdResearchToolkitRoot) 'inventory\selected-release-metadata.json'
                        }
                        if ($Force) { $stageArgs['Force'] = $true }
                        if ($AllowNonAmdHost) { $stageArgs['AllowNonAmdHost'] = $true }
                        Invoke-AmdAcquireStage @stageArgs
                    }
                }
            }

            'Extract' {
                $extractionPreflight=Invoke-AmdExtractionPathPreflight -SevenZipPath $SevenZipPath
                if([string]$extractionPreflight.Status -eq 'Blocked'){
                    $stageResult=Invoke-AmdTrackedStage -Name 'Extract' -BlockedReason (('Extraction path preflight blocked before extraction: {0}' -f (@($extractionPreflight.Issues)-join ' | ')))
                }else{
                    $stageResult = Invoke-AmdTrackedStage -Name 'Extract' -Body {
                        $stageArgs = @{ MaxDepth = $MaxDepth }
                        if ($SevenZipPath) { $stageArgs['SevenZipPath'] = $SevenZipPath }
                        if ($Force) { $stageArgs['Force'] = $true }
                        Invoke-AmdExtractStage @stageArgs
                    }
                }
            }

            'Inspect' {
                $stageResult = Invoke-AmdTrackedStage -Name 'Inspect' -Body {
                    Invoke-AmdInspectStage
                }
            }

            'Signature' {
                $stageResult = Invoke-AmdTrackedStage -Name 'Signature' -Body {
                    Invoke-AmdGraphicsSignatureStage -RequireWindowsClientQualification:$RequireWindowsClientSignatureQualification
                }
            }

            'SignatureNative' {
                $stageResult = Invoke-AmdTrackedStage -Name 'SignatureNative' -Body {
                    Invoke-AmdGraphicsSignatureStage -ReuseStaticAnalysis -RequireWindowsClientQualification:$RequireWindowsClientSignatureQualification
                }
            }

            'Build' {
                $stageResult = Invoke-AmdTrackedStage -Name 'Build' -Body {
                    Invoke-AmdBuildStage
                }
            }
        }

        if ($null -ne $stageResult -and -not $stageResult.Success) {
            if ($stageResult.Status -eq 'BLOCKED') {
                $pipelineStopReason = ('{0} BLOCKED - {1}' -f $stage, [string]$stageResult.Reason)
            }
            elseif ($stageResult.Status -eq 'FAIL') {
                $pipelineStopReason = ('{0} FAIL - {1}' -f $stage, [string]$stageResult.Error)
            }
        }

        Write-Host ''
    }

    Write-AmdOk 'Research run processing complete; finalizing evidence.'
}
catch {
    $fatalRecord = $_
    $script:AmdTopLevelFatalError = $fatalRecord.Exception.ToString()

    # Stage-resolution and other early argument failures can occur before the
    # normal evidence session exists. Create a recovery session only when the
    # tool-local root itself passes the non-stage-specific path-safety gate.
    # An unsafe root remains a strict no-write block by design.
    if ($null -eq $script:AmdEvidenceContext) {
        try {
            $bootstrapPathAssessment = Get-AmdPathSafetyAssessment -SevenZipPath $SevenZipPath -ResolvedStages @()
            if ([string]$bootstrapPathAssessment.Status -ne 'Blocked') {
                $null = Start-AmdEmergencyEvidenceSession `
                    -PreferredOutputRoot $EvidenceOutputRoot `
                    -Label $EvidenceLabel `
                    -EvidenceRetention $EvidenceRetention `
                    -InvocationParameters $invocationEvidence `
                    -BootstrapError $script:AmdTopLevelFatalError
            }
        }
        catch {
            Write-Warning ('Bootstrap evidence recovery could not start: {0}' -f $_.Exception.Message)
        }
    }

    $null=Write-AmdFailureSnapshot -Scope 'fatal-runner' -ErrorRecord $fatalRecord -AdditionalData @{ResolvedStages=@($resolvedStages)}
    Write-Warning ('Fatal research runner error: {0}' -f $fatalRecord.Exception.Message)

    if ($null -ne $script:AmdEvidenceContext) {
        try {
            $fatalPath = Join-Path (Join-Path $script:AmdEvidenceContext.EvidenceDirectory 'errors') 'fatal-runner-error.txt'
            $fatalText = @(
                ('OccurredUtc: {0}' -f (Get-AmdUtcTimestamp)),
                ('Exception  : {0}' -f $fatalRecord.Exception.ToString()),
                ('ScriptStack: {0}' -f $fatalRecord.ScriptStackTrace)
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
        $finalizationError = $_
        $finalExitCode = 1
        if (-not $script:AmdTopLevelFatalError) {
            $script:AmdTopLevelFatalError = $finalizationError.Exception.ToString()
        }
        Write-Warning ('Evidence finalization failed: {0}' -f $finalizationError.Exception.Message)

        if ($script:AmdTranscriptStarted) {
            try { Stop-Transcript | Out-Null } catch { }
            $script:AmdTranscriptStarted = $false
        }
        [void](Invoke-AmdEmergencyEvidenceFinalization -ErrorRecord $finalizationError -SkipArchive:$SkipEvidenceArchive)
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
