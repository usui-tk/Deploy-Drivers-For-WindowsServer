#requires -Version 5.1
# AMD Chipset Driver Research Toolkit 3.0.0
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

    [ValidateSet('ZipOnly', 'ZipAndDirectory')]
    [string]$EvidenceRetention = 'ZipOnly',

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

$script:AmdChipsetResearchToolkitVersion = '3.0.0'
$script:AmdResearchToolkitVersion = $script:AmdChipsetResearchToolkitVersion
$script:AmdChipsetResearchToolkitRoot = $PSScriptRoot
$script:AmdPublicOutputRoot = if ([string]::IsNullOrWhiteSpace($PublicOutputRoot)) { Join-Path $PSScriptRoot 'public' } else { $PublicOutputRoot }
$script:AmdPublicationResult = $null

$script:AmdChipsetResearchEvidenceSchemaVersion = 'amd-chipset-driver-research-evidence/1.2'
$script:AmdResearchEvidenceSchemaVersion = $script:AmdChipsetResearchEvidenceSchemaVersion
$script:AmdResearchEvidencePrefix = 'AmdChipsetDriverResearchEvidence'
$script:AmdResearchDisplayName = 'AMD Chipset Driver Research Toolkit'
$script:SourceScriptPath = $PSCommandPath
$script:AmdChipsetResearchAnalysisSchemaVersion = 'amd-chipset-driver-release-analysis/2.6'
$script:AmdInfSemanticContractVersion = 'amd-inf-semantic-contract/1.0'
$script:AmdDriverSignatureAnalysisSchemaVersion = 'amd-driver-signature-analysis/1.0'
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
$script:AmdRequestedReleaseVersions = @($ReleaseVersion)
$script:AmdHttpMaximumConcurrency = 1
$script:AmdDiagnosticTraceContext = $null
$script:AmdDiagnosticCurrentFunction = $null
$script:AmdDiagnosticCurrentStep = $null
$script:AmdDiagnosticHistoryLimit = 256
$script:AmdDiagnosticBodyPreviewLimit = 2048
$script:AmdWindowsSafeFullPathLimit = 240
$script:AmdWindowsSafeToolRootLimit = 100
$script:AmdVendorRelativePathReserve = 120
$script:AmdPathSafetyAssessment = $null
$script:AmdRequireWindowsClientSignatureQualification = $false
$script:AmdResearchPathSafetySchemaVersion = 'amd-chipset-path-safety-assessment/1.0'
$script:AmdResearchRecommendedRootName = 'AMD-Chipset'

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
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [AllowNull()]
        [object]$Value,

        [int]$Depth = 30,

        [switch]$Compress
    )

    # -Compress is retained only for call-site compatibility; persisted JSON
    # always uses the common canonical format.
    Save-CanonicalJsonFile -InputObject $Value -Path $Path -Depth $Depth
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

function Test-AmdWindowsPowerShell51SourceCompatibility {
    [CmdletBinding()]
    param([Parameter(Mandatory=$true)][string]$Path)

    $issues = New-Object 'System.Collections.Generic.List[string]'
    $bytes = [System.IO.File]::ReadAllBytes($Path)
    if ($bytes.Length -lt 3 -or $bytes[0] -ne 0xEF -or $bytes[1] -ne 0xBB -or $bytes[2] -ne 0xBF) {
        $issues.Add('Source file must be UTF-8 with BOM so Windows PowerShell 5.1 decodes non-ASCII text deterministically.') | Out-Null
    }
    for ($i = 3; $i -lt $bytes.Length; $i++) {
        if ($bytes[$i] -eq 0x0A -and $bytes[$i-1] -ne 0x0D) {
            $issues.Add(('Source file contains LF without CR at byte offset {0}; repository .ps1 contract is CRLF.' -f $i)) | Out-Null
            break
        }
    }
    try {
        $strictUtf8 = New-Object System.Text.UTF8Encoding($true, $true)
        [void]$strictUtf8.GetString($bytes, 3, [Math]::Max(0, $bytes.Length - 3))
    }
    catch { $issues.Add(('Source is not valid UTF-8: {0}' -f $_.Exception.Message)) | Out-Null }
    try {
        $sourceText = [System.IO.File]::ReadAllText($Path)
        $frameworkSignedCmsAssembly = 'System.Security, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a'
        if (-not $sourceText.Contains($frameworkSignedCmsAssembly)) {
            $issues.Add('SignedCms runtime initialization must use the complete .NET Framework System.Security strong name for clean Windows PowerShell 5.1 processes.') | Out-Null
        }
        if ($sourceText -match 'foreach\s*\(\s*\$assemblyName\s+in\s+@\([^\)]*''System\.Security''\s*\)\s*\)') {
            $issues.Add('SignedCms runtime initialization must not use the partial System.Security assembly name.') | Out-Null
        }
    }
    catch { $issues.Add(('Source contract inspection failed: {0}' -f $_.Exception.Message)) | Out-Null }
    return @($issues.ToArray())
}

function Test-AmdToolVersionConsistency {
    [CmdletBinding()]
    param([Parameter(Mandatory=$true)][string]$Path)

    $issues = New-Object 'System.Collections.Generic.List[string]'
    try { $sourceText = [System.IO.File]::ReadAllText($Path) }
    catch {
        $issues.Add(('Cannot read source script for tool version consistency: {0}' -f $_.Exception.Message)) | Out-Null
        return @($issues.ToArray())
    }
    $m = [regex]::Match($sourceText, '(?m)^# AMD Chipset Driver Research Toolkit\s+([^\r\n]+)\s*$')
    if (-not $m.Success) { $issues.Add('Toolkit version header was not found in the source script.') | Out-Null }
    elseif ([string]$m.Groups[1].Value.Trim() -ne [string]$script:AmdChipsetResearchToolkitVersion) {
        $issues.Add(('Toolkit version mismatch: header={0}; runtime={1}' -f $m.Groups[1].Value.Trim(),$script:AmdChipsetResearchToolkitVersion)) | Out-Null
    }
    return @($issues.ToArray())
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

function Invoke-AmdTimedOperation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][string]$Name,
        [Parameter(Mandatory=$true)][scriptblock]$Operation
    )

    $started = Get-Date
    Write-Host ('[CHECK] START {0}' -f $Name) -ForegroundColor Cyan
    try {
        $result = & $Operation
        Write-Host ('[CHECK] DONE  {0} ({1})' -f $Name,(Format-AmdElapsed ((Get-Date)-$started))) -ForegroundColor Green
        return $result
    }
    catch {
        Write-Host ('[CHECK] FAIL  {0} ({1}): {2}' -f $Name,(Format-AmdElapsed ((Get-Date)-$started)),$_.Exception.Message) -ForegroundColor Red
        throw
    }
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
        [Parameter(Mandatory=$true)][ValidateSet('PASS','FAIL','BLOCKED','INTERRUPTED')][string]$Status,
        [Parameter(Mandatory=$true)][TimeSpan]$Elapsed
    )

    $color = if ($Status -eq 'PASS') { 'Green' } elseif ($Status -in @('BLOCKED','INTERRUPTED')) { 'Yellow' } else { 'Red' }
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
            $color = if ($t.Status -eq 'PASS') { 'Green' } elseif ($t.Status -eq 'INTERRUPTED') { 'Yellow' } else { 'Red' }
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
        [Alias('Path')]
        [AllowEmptyString()]
        [string]$RelativePath
    )

    # Repository/publication paths are serialized with '/' regardless of the host OS.
    # This keeps manifests and cross-file references byte-stable between Windows and Linux.
    $normalized = ($RelativePath -replace '\\', '/').TrimStart('/')
    while ($normalized -match '//') {
        $normalized = $normalized -replace '//', '/'
    }
    return $normalized
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
        'AmdChipsetDriverResearchEvidence_{0}_{1}_{2}' -f $stamp, $platformFragment, $labelFragment
    }
    else {
        'AmdChipsetDriverResearchEvidence_{0}_{1}' -f $stamp, $platformFragment
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

    $hostExecutionContext = Get-AmdWindowsExecutionContext -PlatformInfo $platform
    $context = [pscustomobject][ordered]@{
        SchemaVersion = $script:AmdChipsetResearchEvidenceSchemaVersion
        ToolkitVersion = $script:AmdChipsetResearchToolkitVersion
        RunId = $baseName
        StartedAtUtc = Get-AmdUtcTimestamp
        ToolDisplayName = 'AMD Chipset Driver Research Toolkit'
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
        DiagnosticTracePath = Join-Path (Join-Path $evidenceDir 'logs') 'diagnostic-events.jsonl'
        FailureSnapshotDirectory = Join-Path (Join-Path $evidenceDir 'errors') 'failure-snapshots'
        HttpMaximumConcurrency = $script:AmdHttpMaximumConcurrency
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
    Write-AmdDiagnosticEvent -EventName 'StageStarted' -Level 'Info' -FunctionName 'Invoke-AmdTrackedStage' -Step $Name -Data @{ Ordinal=$script:AmdStageOrdinal; Total=$script:AmdResolvedStageCount; BlockedReason=$BlockedReason }
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    # Do not pre-mark a stage PASS. Ctrl+C / pipeline stop can execute finally without
    # returning normally through the body, and a pre-set PASS would create false evidence.
    $status = if ([string]::IsNullOrWhiteSpace($BlockedReason)) { 'RUNNING' } else { 'BLOCKED' }
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
            $status = 'PASS'
            Write-AmdDiagnosticEvent -EventName 'StageBodyCompleted' -Level 'Info' -FunctionName 'Invoke-AmdTrackedStage' -Step $Name -Data @{ Status='PASS' }
        }
    }
    catch {
        $status = 'FAIL'
        $errorText = $_.Exception.Message
        Write-AmdDiagnosticEvent -EventName 'StageFailure' -Level 'Error' -FunctionName 'Invoke-AmdTrackedStage' -Step $Name -Data @{ Error=$errorText; ErrorRecord=(Get-AmdExceptionDiagnostic -ErrorRecord $_) }
        [void](Write-AmdFailureSnapshot -Scope ('stage-{0}' -f $Name) -ErrorRecord $_ -AdditionalData @{ Stage=$Name })

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
            # Reaching finally while still RUNNING means the body did not return normally.
            # In interactive use this is most commonly Ctrl+C / PipelineStoppedException.
            # Preserve that distinction instead of converting a user interruption into a research FAIL.
            $status = 'INTERRUPTED'
            if ([string]::IsNullOrWhiteSpace($errorText)) {
                $errorText = 'Stage execution was interrupted before normal completion.'
            }
        }
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
        Write-AmdDiagnosticEvent -EventName 'StageCompleted' -Level $(if($status -eq 'FAIL'){'Error'}elseif($status -in @('BLOCKED','INTERRUPTED')){'Warning'}else{'Info'}) -FunctionName 'Invoke-AmdTrackedStage' -Step $Name -Data $entry
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

function Get-AmdStageStatusCurrentRun {
    [CmdletBinding()]
    param([Parameter(Mandatory=$true)][string]$Name)

    $entry = Get-AmdStageResultEntry -Name $Name
    if ($null -eq $entry) { return 'NOT_RUN' }
    return [string]$entry.Status
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
        Signature = @('Inspect')
        Selector = @('Inspect')
        HostMatch = @('HostSurvey','Selector')
        Build = @('Inspect','Signature','Selector')
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
    param(
        [switch]$IncludeDriverPackages
    )

    $started = Get-Date

    $root = Get-AmdResearchToolkitRoot
    $publicInventory = Join-Path (Get-AmdPublicOutputRoot) 'inventory'
    $runtimeInventory = Join-Path $root 'inventory'
    if (-not (Test-Path -LiteralPath $publicInventory -PathType Container)) {
        Write-Host '[BOOTSTRAP] Runtime baseline restore skipped: public inventory is not present.' -ForegroundColor DarkGray
        return
    }
    Write-Host ('[BOOTSTRAP] Runtime baseline restore started (driver aggregate: {0}).' -f $(if($IncludeDriverPackages){'required'}else{'not required'})) -ForegroundColor Cyan
    New-AmdDirectory -Path $runtimeInventory | Out-Null

    # Lightweight aggregate files are deterministically generated from canonical public per-release Raw JSON.
    foreach ($name in @('releases.json','release-metadata.json','acquisition.json','extraction.json','embedded-installer-metadata.json','amd-selector-static.json','toolchain-capabilities.json','amd-chipset-driver-inventory.csv','amd-chipset-windows-server-compatibility.csv')) {
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
    if ($IncludeDriverPackages -and -not (Test-Path -LiteralPath $driverPackagesPath -PathType Leaf) -and (Test-Path -LiteralPath $srcReleases -PathType Container)) {
        $drivers = New-Object 'System.Collections.Generic.List[object]'
        $releaseFiles = @(Get-AmdOrdinalSortedObjectsByStringProperty -Values @(Get-ChildItem -LiteralPath $srcReleases -Filter 'amd-chipset-analysis-*.json' -File -Recurse -Force) -PropertyName 'FullName')
        $releaseIndex = 0
        Write-Host ('[BOOTSTRAP] Reconstructing driver-packages.json from {0} per-release JSON file(s).' -f $releaseFiles.Count) -ForegroundColor Cyan
        foreach ($file in $releaseFiles) {
            $releaseIndex++
            $fileStarted = Get-Date
            Write-Host ('[BOOTSTRAP] JSON {0}/{1}: {2} ({3:N1} MiB)' -f $releaseIndex,$releaseFiles.Count,$file.Name,($file.Length / 1MB)) -ForegroundColor DarkGray
            $doc = Read-AmdJsonFile -Path $file.FullName
            foreach ($driver in @(Get-AmdCollectionItems -Value $doc.DriverPackages)) { $drivers.Add($driver) }
            Write-Host ('[BOOTSTRAP] JSON {0}/{1} complete in {2}.' -f $releaseIndex,$releaseFiles.Count,(Format-AmdElapsed ((Get-Date)-$fileStarted))) -ForegroundColor DarkGray
        }
        if ($drivers.Count -gt 0) {
            Write-Host ('[BOOTSTRAP] Writing driver-packages.json ({0} driver record(s)).' -f $drivers.Count) -ForegroundColor Cyan
            Write-AmdJsonFile -Path $driverPackagesPath -Value ([pscustomobject][ordered]@{
                SchemaVersion='2.0';ToolkitVersion=$script:AmdChipsetResearchToolkitVersion;GeneratedAtUtc=Get-AmdUtcTimestamp
                Purpose='RuntimeBaselineReconstructedFromPublicPerReleaseRawJson';DriverPackageCount=$drivers.Count;DriverPackages=@($drivers.ToArray())
            }) -Compress
        }
    }
    Write-Host ('[BOOTSTRAP] Runtime baseline restore completed in {0}.' -f (Format-AmdElapsed ((Get-Date)-$started))) -ForegroundColor Cyan
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
                    'inventory/extraction.json','inventory/embedded-installer-metadata.json','inventory/amd-selector-static.json','inventory/toolchain-capabilities.json'
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
        foreach ($file in @(Get-AmdOrdinalSortedObjectsByStringProperty -Values @(Get-ChildItem -LiteralPath $releaseRoot -Filter 'amd-chipset-analysis-*.json' -File -Recurse -Force) -PropertyName 'FullName')) {
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

function Get-AmdPublicationEligibility {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][object]$CoreAssessment,
        [Parameter(Mandatory=$true)][string[]]$ResolvedStages,
        [Parameter(Mandatory=$true)][string]$BuildStageStatus
    )

    if ([string]$CoreAssessment.OverallStatus -notin @('Pass','PassWithNotes')) {
        return [pscustomobject][ordered]@{
            Eligible=$false
            Status='NotAttemptedAssessmentNotEligible'
            Reason=('core assessment status={0}; publication requires Pass or PassWithNotes' -f [string]$CoreAssessment.OverallStatus)
        }
    }
    if ($ResolvedStages -notcontains 'Build') {
        return [pscustomobject][ordered]@{
            Eligible=$false
            Status='NotAttemptedNoBuildStage'
            Reason='Build was not selected for the current run; the previous validated public baseline must be preserved.'
        }
    }
    if ($BuildStageStatus -ne 'PASS') {
        return [pscustomobject][ordered]@{
            Eligible=$false
            Status='NotAttemptedNoSuccessfulBuild'
            Reason=('Build current-run status={0}; publication requires a current-run successful Build stage.' -f $BuildStageStatus)
        }
    }
    return [pscustomobject][ordered]@{
        Eligible=$true
        Status='Eligible'
        Reason='core assessment is publishable and the current run completed Build successfully'
    }
}

function Test-AmdPublicationEligibilitySelfTest {
    [CmdletBinding()]
    param()

    $passAssessment = [pscustomobject]@{ OverallStatus='Pass' }
    $noteAssessment = [pscustomobject]@{ OverallStatus='PassWithNotes' }
    $reviewAssessment = [pscustomobject]@{ OverallStatus='ReviewRequired' }
    $full = Get-AmdPublicationEligibility -CoreAssessment $passAssessment -ResolvedStages @('Test','Build') -BuildStageStatus 'PASS'
    $notes = Get-AmdPublicationEligibility -CoreAssessment $noteAssessment -ResolvedStages @('Build') -BuildStageStatus 'PASS'
    $noBuild = Get-AmdPublicationEligibility -CoreAssessment $passAssessment -ResolvedStages @('Test') -BuildStageStatus 'NOT_RUN'
    $failedBuild = Get-AmdPublicationEligibility -CoreAssessment $passAssessment -ResolvedStages @('Build') -BuildStageStatus 'FAIL'
    $review = Get-AmdPublicationEligibility -CoreAssessment $reviewAssessment -ResolvedStages @('Build') -BuildStageStatus 'PASS'
    $ok = (
        $full.Eligible -and $notes.Eligible -and
        -not $noBuild.Eligible -and $noBuild.Status -eq 'NotAttemptedNoBuildStage' -and
        -not $failedBuild.Eligible -and $failedBuild.Status -eq 'NotAttemptedNoSuccessfulBuild' -and
        -not $review.Eligible -and $review.Status -eq 'NotAttemptedAssessmentNotEligible'
    )
    return [pscustomobject][ordered]@{
        Status=if($ok){'Pass'}else{'Fail'}
        FullBuildEligible=[bool]$full.Eligible
        PassWithNotesBuildEligible=[bool]$notes.Eligible
        TestOnlyStatus=[string]$noBuild.Status
        FailedBuildStatus=[string]$failedBuild.Status
        ReviewStatus=[string]$review.Status
    }
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
    $toolchainSummarySource = Join-Path $runtimeInventory 'toolchain-capabilities.json'
    if (Test-Path -LiteralPath $toolchainSummarySource -PathType Leaf) {
        Copy-Item -LiteralPath $toolchainSummarySource -Destination (Join-Path $pubInv 'toolchain-capabilities.json') -Force
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
    foreach ($file in @(Get-AmdOrdinalSortedObjectsByStringProperty -Values @(Get-ChildItem -LiteralPath $staging -File -Recurse -Force) -PropertyName 'FullName')) {
        if ($file.Name -eq 'publication-manifest.json') { continue }
        $relative = ConvertTo-AmdRepositoryRelativePath -Path (Get-AmdRelativePath -BasePath $staging -Path $file.FullName)
        $sourceRelative = $null; $sourceSha = $null; $mode='ToolkitGenerated'
        if ($relative -like 'inventory/releases/*') { $sourceRelative=$relative; $mode='ByteCopyFromRuntimeCanonical' }
        elseif ($relative -eq 'inventory/toolchain-capabilities.json') { $sourceRelative=$relative; $mode='ByteCopyFromRuntimeCanonical' }
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
            'toolchain-capabilities.json is a host-portable capability summary containing tool binary identities, help-output digests, observed command/options and verification-profile contracts; raw help text and absolute executable paths remain private evidence.',
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

function Get-AmdAcquisitionAssessmentFromArtifacts {
    [CmdletBinding()]
    param(
        [AllowNull()][object[]]$Artifacts,
        [string[]]$RequestedReleaseVersions = @()
    )

    $all = @($Artifacts | Where-Object { $null -ne $_ })
    if ($all.Count -eq 0) {
        return [pscustomobject][ordered]@{ Status='REVIEW'; Detail='no installer artifacts were recorded'; AvailableCount=0; UnavailableCount=0; UnavailableReleaseVersions=@() }
    }

    $available = @($all | Where-Object { [string]$_.Status -in @('Downloaded','Cached') })
    $unavailable = @($all | Where-Object { [string]$_.Status -notin @('Downloaded','Cached') })
    $unavailableVersions = @(Get-AmdOrdinalSortedUniqueStrings -Values @($unavailable | ForEach-Object { [string]$_.ReleaseVersion }))
    $requested = @(Get-AmdOrdinalSortedUniqueStrings -Values @($RequestedReleaseVersions))

    if ($requested.Count -gt 0) {
        $missingRequested = @($requested | Where-Object {
            $version = $_
            -not (@($available | Where-Object { [string]$_.ReleaseVersion -eq $version }).Count -gt 0)
        })
        if ($missingRequested.Count -gt 0) {
            return [pscustomobject][ordered]@{
                Status='REVIEW';Detail=('explicitly requested release artifact(s) unavailable: {0}' -f ($missingRequested -join ', '))
                AvailableCount=$available.Count;UnavailableCount=$unavailable.Count;UnavailableReleaseVersions=$unavailableVersions
            }
        }
        return [pscustomobject][ordered]@{
            Status='PASS';Detail=('{0} explicitly requested installer artifact(s) available' -f $available.Count)
            AvailableCount=$available.Count;UnavailableCount=$unavailable.Count;UnavailableReleaseVersions=$unavailableVersions
        }
    }

    if ($available.Count -eq 0) {
        return [pscustomobject][ordered]@{
            Status='REVIEW';Detail=('all {0} discovered installer artifact(s) are unavailable' -f $all.Count)
            AvailableCount=0;UnavailableCount=$unavailable.Count;UnavailableReleaseVersions=$unavailableVersions
        }
    }

    $newest = @($all | Sort-Object @{Expression={ try { [version]([string]$_.ReleaseVersion) } catch { [version]'0.0.0.0' } }; Descending=$true} | Select-Object -First 1)
    $newestVersion = if ($newest.Count -gt 0) { [string]$newest[0].ReleaseVersion } else { $null }
    $newestAvailable = ($null -ne $newestVersion -and @($available | Where-Object { [string]$_.ReleaseVersion -eq $newestVersion }).Count -gt 0)
    if (-not $newestAvailable) {
        return [pscustomobject][ordered]@{
            Status='REVIEW';Detail=('newest discovered release artifact is unavailable: {0}' -f $newestVersion)
            AvailableCount=$available.Count;UnavailableCount=$unavailable.Count;UnavailableReleaseVersions=$unavailableVersions
        }
    }

    if ($unavailable.Count -gt 0) {
        return [pscustomobject][ordered]@{
            Status='PASS_WITH_NOTES'
            Detail=('{0}/{1} installer artifact(s) available; historical artifact gap(s) preserved as evidence: {2}' -f $available.Count,$all.Count,($unavailableVersions -join ', '))
            AvailableCount=$available.Count;UnavailableCount=$unavailable.Count;UnavailableReleaseVersions=$unavailableVersions
        }
    }

    return [pscustomobject][ordered]@{
        Status='PASS';Detail=('{0} installer artifact(s) available' -f $available.Count)
        AvailableCount=$available.Count;UnavailableCount=0;UnavailableReleaseVersions=@()
    }
}

function Test-AmdAcquisitionAssessmentSelfTest {
    [CmdletBinding()]
    param()
    $latest='8.07.16.1035';$old='7.11.26.2142'
    $allGood=@([pscustomobject]@{ReleaseVersion=$old;Status='Cached'},[pscustomobject]@{ReleaseVersion=$latest;Status='Downloaded'})
    $historicalGap=@([pscustomobject]@{ReleaseVersion=$old;Status='DownloadFailed'},[pscustomobject]@{ReleaseVersion=$latest;Status='Downloaded'})
    $latestGap=@([pscustomobject]@{ReleaseVersion=$old;Status='Downloaded'},[pscustomobject]@{ReleaseVersion=$latest;Status='DownloadFailed'})
    $r1=Get-AmdAcquisitionAssessmentFromArtifacts -Artifacts $allGood
    $r2=Get-AmdAcquisitionAssessmentFromArtifacts -Artifacts $historicalGap
    $r3=Get-AmdAcquisitionAssessmentFromArtifacts -Artifacts $latestGap
    $r4=Get-AmdAcquisitionAssessmentFromArtifacts -Artifacts $historicalGap -RequestedReleaseVersions @($old,$latest)
    $ok=($r1.Status -eq 'PASS' -and $r2.Status -eq 'PASS_WITH_NOTES' -and $r3.Status -eq 'REVIEW' -and $r4.Status -eq 'REVIEW')
    return [pscustomobject][ordered]@{Status=if($ok){'Pass'}else{'Fail'};AllAvailable=$r1.Status;HistoricalGap=$r2.Status;NewestGap=$r3.Status;ExplicitGap=$r4.Status}
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

    $interruptedStages = @($script:AmdStageResults.ToArray() | Where-Object { $_.Status -eq 'INTERRUPTED' })
    $failedStages = @($script:AmdStageResults.ToArray() | Where-Object { $_.Status -in @('FAIL','BLOCKED') })
    $runInterrupted = ($interruptedStages.Count -gt 0)
    $items.Add([pscustomobject]@{
        Name = 'StageExecution'
        Status = if (@($ResolvedStages).Count -eq 0) { 'NOT_ASSESSED' } elseif ($runInterrupted) { 'INTERRUPTED' } elseif ($failedStages.Count -eq 0) { 'PASS' } else { 'REVIEW' }
        Detail = if (@($ResolvedStages).Count -eq 0) {
            'no stage was resolved or executed before bootstrap termination'
        }
        elseif ($runInterrupted) {
            ('run interrupted during: {0}; later selected stages were not executed' -f (@($interruptedStages | ForEach-Object { $_.Name }) -join ', '))
        }
        elseif ($failedStages.Count -eq 0) {
            ('all {0} executed stage(s) completed without terminating errors' -f $script:AmdStageResults.Count)
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
            $acquireStage = @($script:AmdStageResults | Where-Object { $_.Name -eq 'Acquire' } | Select-Object -Last 1)
            $notAssessed = $runInterrupted -and ($acquireStage.Count -eq 0 -or [string]$acquireStage[0].Status -eq 'INTERRUPTED')
            $items.Add([pscustomobject]@{ Name='Acquisition'; Status=if($notAssessed){'NOT_ASSESSED'}else{'REVIEW'}; Detail=if($notAssessed){'Acquire did not complete because the run was interrupted; acquisition was not assessed.'}else{'not assessed from inventory because Acquire did not PASS in the current run'} })
        }
        else {
            $path = Join-Path (Join-Path $toolRoot 'inventory') 'acquisition.json'
            if (Test-Path -LiteralPath $path -PathType Leaf) {
                try {
                    $data = Read-AmdJsonFile -Path $path
                    $acquisitionAssessment = Get-AmdAcquisitionAssessmentFromArtifacts -Artifacts @($data.Artifacts) -RequestedReleaseVersions @($script:AmdRequestedReleaseVersions)
                    $items.Add([pscustomobject]@{
                        Name = 'Acquisition'
                        Status = [string]$acquisitionAssessment.Status
                        Detail = [string]$acquisitionAssessment.Detail
                        AvailableCount = [int]$acquisitionAssessment.AvailableCount
                        UnavailableCount = [int]$acquisitionAssessment.UnavailableCount
                        UnavailableReleaseVersions = @($acquisitionAssessment.UnavailableReleaseVersions)
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
            $extractStage = @($script:AmdStageResults | Where-Object { $_.Name -eq 'Extract' } | Select-Object -Last 1)
            $notAssessed = $runInterrupted -and $extractStage.Count -eq 0
            $items.Add([pscustomobject]@{ Name='ExtractionCompleteness'; Status=if($notAssessed){'NOT_ASSESSED'}else{'REVIEW'}; Detail=if($notAssessed){'Extract was not reached because the run was interrupted earlier.'}else{'not assessed from inventory because Extract did not PASS in the current run'} })
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
            $inspectStage = @($script:AmdStageResults | Where-Object { $_.Name -eq 'Inspect' } | Select-Object -Last 1)
            $notAssessed = $runInterrupted -and $inspectStage.Count -eq 0
            $items.Add([pscustomobject]@{ Name='InfInspection'; Status=if($notAssessed){'NOT_ASSESSED'}else{'REVIEW'}; Detail=if($notAssessed){'Inspect was not reached because the run was interrupted earlier.'}else{'not assessed from inventory because Inspect did not PASS in the current run'} })
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

    if ($ResolvedStages -contains 'Signature') {
        $signatureStageStatus = Get-AmdStageStatusCurrentRun -Name 'Signature'
        if ($signatureStageStatus -eq 'INTERRUPTED') {
            $items.Add([pscustomobject]@{ Name='SignatureAnalysis'; Status='NOT_ASSESSED'; Detail='Signature analysis was interrupted before completion; partial observations are evidence only and are not assessed.' })
        }
        elseif ($signatureStageStatus -eq 'NOT_RUN' -and $runInterrupted) {
            $items.Add([pscustomobject]@{ Name='SignatureAnalysis'; Status='NOT_ASSESSED'; Detail='Signature stage was not reached because the run was interrupted earlier.' })
        }
        elseif ($signatureStageStatus -ne 'PASS') {
            $items.Add([pscustomobject]@{ Name='SignatureAnalysis'; Status='REVIEW'; Detail=('Signature stage status={0}; inspect stage-results.json.' -f $signatureStageStatus) })
        }
        else {
            $path = Join-Path (Join-Path $toolRoot 'inventory') 'signature-analysis.json'
            if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
                $items.Add([pscustomobject]@{ Name='SignatureAnalysis'; Status='REVIEW'; Detail='Signature passed but signature-analysis.json is missing.' })
            }
            else {
                $data = Read-AmdJsonFile -Path $path
                $files = @($data.Releases | ForEach-Object { @($_.Files) } | ForEach-Object { $_ })
                $envelopeQueue = New-Object 'System.Collections.Generic.Queue[object]'
                foreach ($file in $files) {
                    foreach ($envelope in @($file.Envelopes)) { if ($null -ne $envelope) { $envelopeQueue.Enqueue($envelope) } }
                }
                $allEnvelopes = New-Object System.Collections.Generic.List[object]
                while ($envelopeQueue.Count -gt 0) {
                    $envelope = $envelopeQueue.Dequeue()
                    $allEnvelopes.Add($envelope)
                    $nestedProperty = $envelope.PSObject.Properties['NestedSignatures']
                    if ($null -ne $nestedProperty) {
                        foreach ($nested in @($nestedProperty.Value)) { if ($null -ne $nested) { $envelopeQueue.Enqueue($nested) } }
                    }
                    $timestampProperty = $envelope.PSObject.Properties['TimestampTokens']
                    if ($null -ne $timestampProperty) {
                        foreach ($timestamp in @($timestampProperty.Value)) { if ($null -ne $timestamp) { $envelopeQueue.Enqueue($timestamp) } }
                    }
                }
                $parseFailures = @($allEnvelopes.ToArray() | Where-Object { [string]$_.Status -eq 'ParseFailed' })
                $digestMismatches = @($allEnvelopes.ToArray() | Where-Object {
                    $digestProperty = $_.PSObject.Properties['PeDigestMatchesSignedDigest']
                    $null -ne $digestProperty -and $null -ne $digestProperty.Value -and [bool]$digestProperty.Value -eq $false
                })
                if ($parseFailures.Count -gt 0 -or $digestMismatches.Count -gt 0) {
                    $items.Add([pscustomobject]@{ Name='SignatureAnalysis'; Status='REVIEW'; Detail=('static signature files={0}; recursive envelope parse failures={1}; PE signed-digest mismatches={2}' -f $files.Count,$parseFailures.Count,$digestMismatches.Count) })
                }
                else {
                    $analyzedVersions = @($data.Releases | ForEach-Object { [string]$_.ReleaseVersion })
                    $selectionPolicy = if ($null -ne $data.PSObject.Properties['ReleaseSelectionPolicy']) { [string]$data.ReleaseSelectionPolicy } else { 'Unspecified' }
                    $nativePath = Join-Path (Join-Path $toolRoot 'inventory') 'host/signature-native-verification.json'
                    $nativeCheckCount = 0
                    $nativeInvocationErrors = 0
                    if (Test-Path -LiteralPath $nativePath -PathType Leaf) {
                        try {
                            $nativeData = Read-AmdJsonFile -Path $nativePath
                            $nativeChecks = @($nativeData.Releases | ForEach-Object { @($_.Files) } | ForEach-Object { $_ } | ForEach-Object { @($_.SignToolChecks) } | ForEach-Object { $_ })
                            $nativeCheckCount = $nativeChecks.Count
                            $nativeInvocationErrors = @($nativeChecks | Where-Object {
                                [string]$_.ResultClass -eq 'ToolExecutionFailed' -or
                                [string]$_.Status -eq 'ExecutionFailed' -or
                                -not [string]::IsNullOrWhiteSpace([string]$_.Error)
                            }).Count
                        }
                        catch { $nativeInvocationErrors = 1 }
                    }
                    if ($nativeInvocationErrors -gt 0) {
                        $items.Add([pscustomobject]@{ Name='SignatureAnalysis'; Status='REVIEW'; Detail=('static signature files={0}; native checks={1}; Windows-native tool invocation/configuration errors={2}' -f $files.Count,$nativeCheckCount,$nativeInvocationErrors) })
                    }
                    else {
                        $targetChecks = @()
                        $catalogKernelChecks = @()
                        $mixedKernelChecks = @()
                        $nativeKernelFiles = @()
                        $targetUnavailableKernelFiles = @()
                        $catalogHashFailures = @()
                        if (Test-Path -LiteralPath $nativePath -PathType Leaf) {
                            $targetChecks = @($nativeChecks | Where-Object { [string]$_.Policy -like 'WindowsDriverCatalogTarget*' })
                            $catalogKernelChecks = @($nativeChecks | Where-Object { [string]$_.Policy -eq 'KernelModeExplicitCatalog' })
                            $nonZeroKernelChecks = @($nativeChecks | Where-Object { [string]$_.Policy -eq 'KernelModeEmbeddedOrCatalog' -and [string]$_.ResultClass -eq 'NonZeroExit' })
                            $nativeKernelFiles = @($nativeData.Releases | ForEach-Object { @($_.Files) } | ForEach-Object { $_ } | Where-Object { [string]$_.FileType -eq 'KernelBinary' })
                            $targetUnavailableKernelFiles = @($nativeKernelFiles | Where-Object {
                                $p = $_.PSObject.Properties['CatalogBoundTargetVerification']
                                $null -ne $p -and $null -ne $p.Value -and [string]$p.Value.Status -eq 'NotObservedCatalogAssociationUnavailable'
                            })
                            $catalogHashFailures = @($nativeKernelFiles | Where-Object {
                                $p = $_.PSObject.Properties['CatalogHash']
                                $null -ne $p -and $null -ne $p.Value -and [string]$p.Value.Status -notin @('Calculated','NotApplicableOnPlatform')
                            })
                        }
                        $targetPass = @($targetChecks | Where-Object { [string]$_.ResultClass -eq 'Verified' }).Count
                        $targetNonZero = @($targetChecks | Where-Object { [string]$_.ResultClass -eq 'NonZeroExit' }).Count
                        $catalogKernelPass = @($catalogKernelChecks | Where-Object { [string]$_.ResultClass -eq 'Verified' }).Count
                        $catalogKernelNonZero = @($catalogKernelChecks | Where-Object { [string]$_.ResultClass -eq 'NonZeroExit' }).Count
                        $perKernelCoverage = Get-AmdKernelSignatureCoverageAssessment -NativeData $nativeData
                        $coverageStatus = 'PASS'
                        if (
                            $nativeKernelFiles.Count -gt 0 -and
                            $targetChecks.Count -eq 0 -and
                            $null -ne $nativeData -and
                            [string]$nativeData.ExecutionContext.ExecutionClass -in @('WindowsClient','WindowsServer','WindowsOther')
                        ) {
                            $coverageStatus = 'REVIEW'
                        }
                        elseif ($targetChecks.Count -gt 0 -and $targetPass -eq 0) {
                            # Without parsing localized prose, zero successful checks cannot prove that
                            # the CLI option combination was accepted. Preserve the raw localized output
                            # and require review rather than guessing from English error text.
                            $coverageStatus = 'REVIEW'
                        }
                        elseif ($catalogKernelChecks.Count -gt 0 -and $catalogKernelPass -eq 0) {
                            $coverageStatus = 'REVIEW'
                        }
                        elseif ($perKernelCoverage.CoverageGapKernelCount -gt 0) {
                            # Aggregate success counts can hide a file-specific coverage hole. Require
                            # every catalog-associated kernel binary to have at least one Verified
                            # explicit /kp catalog check and at least one Verified check for each of
                            # WS2016/2019/2022/2025.
                            $coverageStatus = 'REVIEW'
                        }
                        elseif ($targetUnavailableKernelFiles.Count -gt 0 -or $catalogHashFailures.Count -gt 0 -or $targetNonZero -gt 0 -or $catalogKernelNonZero -gt 0) {
                            $coverageStatus = 'PASS_WITH_NOTES'
                        }

                        $detail = ('release(s)={0}; policy={1}; static signature files={2}; recursive envelope parse failures=0; PE signed-digest mismatches=0; Windows-native checks={3}; Windows Driver catalog-bound target checks={4} (verified={5}, nonzero-exit={6}); explicit catalog kernel-policy checks={7} (verified={8}, nonzero-exit={9}); kernel files={10}; per-kernel catalog-bound coverage={11}/{10}; per-kernel coverage gaps={12}; target-association-unavailable={13}; catalog-hash-failures={14}; supplemental unbound /kp nonzero={15} (diagnostic-only); tool execution failures=0; native output classification=locale-neutral' -f ($analyzedVersions -join ','),$selectionPolicy,$files.Count,$nativeCheckCount,$targetChecks.Count,$targetPass,$targetNonZero,$catalogKernelChecks.Count,$catalogKernelPass,$catalogKernelNonZero,$nativeKernelFiles.Count,$perKernelCoverage.FullyCoveredKernelCount,$perKernelCoverage.CoverageGapKernelCount,$targetUnavailableKernelFiles.Count,$catalogHashFailures.Count,$nonZeroKernelChecks.Count)
                        $items.Add([pscustomobject]@{ Name='SignatureAnalysis'; Status=$coverageStatus; Detail=$detail })
                    }
                }
            }
        }
    }

    if ($ResolvedStages -contains 'Selector') {
        $selectorStageStatus = Get-AmdStageStatusCurrentRun -Name 'Selector'
        if ($selectorStageStatus -eq 'INTERRUPTED') {
            $items.Add([pscustomobject]@{ Name='MsiDeclarativeInspection'; Status='NOT_ASSESSED'; Detail='Selector was interrupted before completion.' })
        }
        elseif ($selectorStageStatus -eq 'NOT_RUN' -and $runInterrupted) {
            $items.Add([pscustomobject]@{ Name='MsiDeclarativeInspection'; Status='NOT_ASSESSED'; Detail='Selector was not reached because the run was interrupted earlier.' })
        }
        elseif ($selectorStageStatus -ne 'PASS') {
            $items.Add([pscustomobject]@{ Name='MsiDeclarativeInspection'; Status='REVIEW'; Detail=('Selector stage status={0}; declarative MSI evidence was not accepted.' -f $selectorStageStatus) })
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
        $pubStatus = [string]$script:AmdPublicationResult.Status
        $pubOk = ([bool]$script:AmdPublicationResult.Published -and $pubStatus -eq 'Pass')
        if ($pubOk) {
            $items.Add([pscustomobject]@{
                Name='PublicRepositorySurface';Status='PASS'
                Detail=('validated public surface published: {0} file(s)' -f [int]$script:AmdPublicationResult.FileCount)
            })
        }
        elseif ($pubStatus -in @('NotAttemptedAssessmentNotEligible','NotAttemptedNoBuildStage','NotAttemptedNoSuccessfulBuild')) {
            $detail = switch ($pubStatus) {
                'NotAttemptedAssessmentNotEligible' { ('core assessment was not publication-eligible ({0}); public publication was not attempted and the previous validated public baseline was preserved' -f [string]$script:AmdPublicationResult.Reason) }
                'NotAttemptedNoBuildStage' { 'Build was not selected in the current run; public publication was not attempted and the previous validated public baseline was preserved' }
                'NotAttemptedNoSuccessfulBuild' { 'Build did not complete successfully in the current run; public publication was not attempted and the previous validated public baseline was preserved' }
                default { 'public publication was not attempted and the previous validated public baseline was preserved' }
            }
            $items.Add([pscustomobject]@{
                Name='PublicRepositorySurface';Status='NOT_ASSESSED'
                Detail=$detail
            })
        }
        else {
            $items.Add([pscustomobject]@{
                Name='PublicRepositorySurface';Status='REVIEW'
                Detail='publication validation failed; previous public baseline was preserved'
            })
        }
    }

    $reviewCount = @($items.ToArray() | Where-Object { $_.Status -eq 'REVIEW' }).Count
    $noteCount = @($items.ToArray() | Where-Object { $_.Status -eq 'PASS_WITH_NOTES' }).Count
    $overall = if ($script:AmdTopLevelFatalError) { 'FatalError' }
        elseif ($runInterrupted) { 'Interrupted' }
        elseif ($reviewCount -gt 0) { 'ReviewRequired' }
        elseif ($noteCount -gt 0) { 'PassWithNotes' }
        else { 'Pass' }

    return [pscustomobject][ordered]@{
        SchemaVersion = 'amd-chipset-driver-research-assessment/1.2'
        ToolkitVersion = $script:AmdChipsetResearchToolkitVersion
        GeneratedAtUtc = Get-AmdUtcTimestamp
        OverallStatus = $overall
        ExitCode = if ($overall -in @('Pass','PassWithNotes')) { 0 } elseif ($overall -eq 'FatalError') { 1 } elseif ($overall -eq 'Interrupted') { 130 } else { 2 }
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
        $color = if ($item.Status -eq 'PASS') { 'Green' } elseif ($item.Status -eq 'PASS_WITH_NOTES') { 'DarkYellow' } elseif ($item.Status -eq 'NOT_ASSESSED') { 'DarkGray' } else { 'Yellow' }
        Write-Host (('[{0}]' -f $item.Status).PadRight(19)) -NoNewline -ForegroundColor $color
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

    # Publication is an explicit fail-closed gate. Build the public surface from runtime output,
    # then recompute the final assessment so a publication failure becomes ReviewRequired.
    $coreAssessment = Get-AmdRunAssessment -ResolvedStages $ResolvedStages
    if (-not $script:SkipPublicExport -and @($ResolvedStages).Count -gt 0) {
        $publicationEligibility = Get-AmdPublicationEligibility -CoreAssessment $coreAssessment -ResolvedStages $ResolvedStages -BuildStageStatus (Get-AmdStageStatusCurrentRun -Name 'Build')
        if ($publicationEligibility.Eligible) {
            $script:AmdPublicationResult = Publish-AmdRepositorySurface -CoreAssessment $coreAssessment -ResolvedStages $ResolvedStages
        }
        else {
            $script:AmdPublicationResult = [pscustomobject][ordered]@{
                Status=[string]$publicationEligibility.Status
                Published=$false
                PreservedPrevious=$true
                FileCount=0
                Reason=[string]$publicationEligibility.Reason
            }
        }
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
        EvidenceRoot = $ctx.EvidenceRoot
        EvidenceRetention = $ctx.EvidenceRetention
        EvidenceStoragePolicy = 'ToolLocalCanonicalRootOnly/1.0'
        IncludeInstallersInEvidence = [bool]$IncludeInstallers
        RawWorkDirectoryIncluded = $false
        DiagnosticTraceEnabled = ($null -ne $script:AmdDiagnosticTraceContext)
        DiagnosticTracePath = if($script:AmdDiagnosticTraceContext){$script:AmdDiagnosticTraceContext.EventLogPath}else{$null}
        FailureSnapshotDirectory = if($script:AmdDiagnosticTraceContext){$script:AmdDiagnosticTraceContext.FailureSnapshotDirectory}else{$null}
        HttpMaximumConcurrency = $script:AmdHttpMaximumConcurrency
        Notes = @(
            'The work/extracted tree is intentionally excluded from the evidence ZIP to keep review bundles manageable.',
            'Installer binaries are excluded by default; acquisition.json records path, SHA-256 and size.',
            'Use -IncludeInstallersInEvidence only when binary preservation inside the review ZIP is explicitly required.',
            'Generated repository-public output is under public/**; when publication succeeds a review copy is also included under snapshot/public inside the private evidence ZIP.',
            'AMD network acquisition is deliberately sequential (maximum concurrency = 1) to reduce vendor throttling/blocklist risk.',
            'diagnostic-events.jsonl is lightweight structured trace; detailed failure snapshots are emitted only on failure and are subject to Evidence retention governance.'
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
    Stop-AmdDiagnosticTrace -Assessment $assessment

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
        $publicRoot = Get-AmdPublicOutputRoot
        $publicManifest = Join-Path $publicRoot 'publication-manifest.json'
        # Keep the private evidence ZIP self-contained for downstream LLM and third-party review.
        # public/** remains the only generated Git commit surface; this is only a review copy.
        Copy-AmdEvidenceTree -Source $publicRoot -Destination (Join-Path $snapshot 'public')
        if (Test-Path -LiteralPath $publicManifest -PathType Leaf) {
            Write-AmdJsonFile -Path (Join-Path $snapshot 'public-publication-reference.json') -Value ([pscustomobject][ordered]@{
                Classification='PrivateEvidenceReference';PublicManifest='snapshot/public/publication-manifest.json';PublicManifestSha256=Get-AmdSha256 -Path $publicManifest
                PublicFileCount=[int]$script:AmdPublicationResult.FileCount;PublicDatasetIncludedInEvidence=$true;Note='A byte-identical copy of the validated public dataset is included under snapshot/public for self-contained review.'
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
            RelativePath = ConvertTo-AmdRepositoryRelativePath -Path (Get-AmdRelativePath -BasePath $ctx.EvidenceDirectory -Path $file.FullName)
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
    param(
        [AllowNull()][object]$ErrorRecord,
        [switch]$SkipArchive
    )

    $ctx = $script:AmdEvidenceContext
    if ($null -eq $ctx) { return $null }

    if ($script:AmdTranscriptStarted) {
        try { Stop-Transcript | Out-Null } catch { }
        $script:AmdTranscriptStarted = $false
    }

    try {
        $errorsDirectory = Join-Path $ctx.EvidenceDirectory 'errors'
        [void][System.IO.Directory]::CreateDirectory($errorsDirectory)
        $errorText = if ($null -ne $ErrorRecord) { $ErrorRecord.ToString() } else { 'Normal evidence finalization failed without an ErrorRecord.' }
        $content = @(
            'AMD DRIVER RESEARCH EMERGENCY EVIDENCE FINALIZATION',
            ('OccurredUtc : {0}' -f (Get-AmdUtcTimestamp)),
            ('RunId       : {0}' -f $ctx.RunId),
            ('Reason      : {0}' -f $errorText),
            'The normal evidence finalizer failed. This emergency archive preserves the raw evidence directory and is not a PASS qualification artifact.'
        ) -join [Environment]::NewLine
        [System.IO.File]::WriteAllText((Join-Path $errorsDirectory 'emergency-finalization.txt'),$content,(New-Object System.Text.UTF8Encoding($false)))
    }
    catch {
        Write-Warning ('Emergency finalization could not write its diagnostic file: {0}' -f $_.Exception.Message)
    }

    if ($SkipArchive) { return $null }

    try {
        $archive = New-AmdZipFromDirectory -SourceDirectory $ctx.EvidenceDirectory -DestinationZip $ctx.ZipPath
        if ($null -eq $archive -or $archive.Length -le 0) { throw 'Emergency evidence archive is empty.' }
        $integrity = Test-AmdEvidenceZipIntegrity -Path $ctx.ZipPath
        if ([string]$integrity.Status -ne 'Pass') { throw ('Emergency evidence ZIP integrity verification failed: {0}' -f [string]$integrity.Error) }
        $ctx.ZipSha256 = Write-AmdEvidenceSha256File -ZipPath $ctx.ZipPath -Sha256Path $ctx.ZipSha256Path
        $ctx.ArchiveCreated = $true
        $ctx.EvidenceDirectoryRetained = $true
        Write-Warning ('Emergency evidence ZIP created: {0}' -f $ctx.ZipPath)
        Write-Warning ('Raw evidence was retained for recovery: {0}' -f $ctx.EvidenceDirectory)
        return [pscustomobject][ordered]@{ Status='EmergencyArchiveCreated'; ZipPath=$ctx.ZipPath; ZipSha256=$ctx.ZipSha256; EvidenceDirectory=$ctx.EvidenceDirectory }
    }
    catch {
        $ctx.ArchiveCreated = $false
        $ctx.EvidenceDirectoryRetained = (Test-Path -LiteralPath $ctx.EvidenceDirectory -PathType Container)
        Write-Warning ('Emergency evidence ZIP creation failed: {0}' -f $_.Exception.Message)
        Write-Warning ('Raw evidence remains available: {0}' -f $ctx.EvidenceDirectory)
        return [pscustomobject][ordered]@{ Status='EmergencyArchiveFailed'; ZipPath=$ctx.ZipPath; Error=$_.Exception.Message; EvidenceDirectory=$ctx.EvidenceDirectory }
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
    $request.KeepAlive = (-not $DisableKeepAlive)
    $request.Headers['Accept-Language'] = 'en-US,en;q=0.9'
    if ($Referer) { $request.Referer = $Referer }
    if ($CookieContainer) { $request.CookieContainer = $CookieContainer }
    if ($NoCache) {
        try { $request.CachePolicy = [System.Net.Cache.RequestCachePolicy]::new([System.Net.Cache.RequestCacheLevel]::Reload) } catch { }
        try { $request.Headers['Cache-Control'] = 'no-cache, no-store, max-age=0' } catch { }
        try { $request.Headers['Pragma'] = 'no-cache' } catch { }
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
    $compiledSelectorSelfTest = Invoke-AmdTimedOperation 'Compiled selector contract' { Test-AmdCompiledSelectorContractSelfTest }
    $architectureSelfTest = Invoke-AmdTimedOperation 'Host architecture normalization' { Test-AmdHostArchitectureNormalizationSelfTest }
    $msiProjectionSelfTest = Invoke-AmdTimedOperation 'MSI table-name projection' { Test-AmdMsiTableNameProjectionSelfTest }
    $msiColumnDiscoverySelfTest = Invoke-AmdTimedOperation 'MSI column discovery' { Test-AmdMsiFieldCountIndependentColumnDiscoverySelfTest }
    $msiTableRowPipelineIsolationSelfTest = Invoke-AmdTimedOperation 'MSI row pipeline isolation' { Test-AmdMsiTableRowPipelineIsolationSelfTest }
    $msiAssessmentSelfTest = Invoke-AmdTimedOperation 'MSI declarative assessment' { Test-AmdMsiDeclarativeAssessmentSelfTest }
    $acquisitionAssessmentSelfTest = Invoke-AmdTimedOperation 'Acquisition assessment' { Test-AmdAcquisitionAssessmentSelfTest }
    $httpDownloadTransportSelfTest = Invoke-AmdTimedOperation 'HTTP download transport' { Test-AmdHttpDownloadTransportSelfTest }
    $httpRetryPolicySelfTest = Invoke-AmdTimedOperation 'HTTP retry policy' { Test-AmdHttpRetryPolicySelfTest }
    $requestedReleaseDiscoverySelfTest = Invoke-AmdTimedOperation 'Requested-release discovery' { Test-AmdRequestedReleaseDiscoverySelfTest }
    $releaseNotesUrlCandidateSelfTest = Invoke-AmdTimedOperation 'Release-notes URL candidates' { Test-AmdReleaseNotesUrlCandidateSelfTest }
    $curatedLatestReleaseSelfTest = Invoke-AmdTimedOperation 'Curated current-latest release' { Test-AmdCuratedLatestReleaseSelfTest }
    $selectorProductCorrelationSelfTest = Invoke-AmdTimedOperation 'Selector product correlation' { Test-AmdSelectorProductCorrelationSelfTest }
    $curatedReleaseNoteCorrelationSelfTest = Invoke-AmdTimedOperation 'Curated release-note correlation' { Test-AmdCuratedReleaseNoteCorrelationSelfTest }
    $diagnosticPrimitiveSelfTest = Invoke-AmdTimedOperation 'Diagnostic primitives' { Test-AmdDiagnosticPrimitiveSelfTest }
    $expectedFallbackProbeSelfTest = Invoke-AmdTimedOperation 'Expected fallback probe' { Test-AmdExpectedFallbackProbeSelfTest }
    $sequentialDownloadSourceContract = Invoke-AmdTimedOperation 'Sequential-download source contract' { Test-AmdSequentialDownloadSourceContract -Path $PSCommandPath }
    $publicationEligibilitySelfTest = Invoke-AmdTimedOperation 'Publication eligibility' { Test-AmdPublicationEligibilitySelfTest }
    $sourceCompatibilityIssues = @(Invoke-AmdTimedOperation 'Windows PowerShell 5.1 source compatibility' { @(Test-AmdWindowsPowerShell51SourceCompatibility -Path $PSCommandPath) })
    $toolVersionIssues = @(Invoke-AmdTimedOperation 'Tool version consistency' { @(Test-AmdToolVersionConsistency -Path $PSCommandPath) })
    $portableNormalizationSelfTest = Invoke-AmdTimedOperation 'Portable analysis normalization' { Test-AmdPortableAnalysisNormalizationSelfTest }
    $publicationContractSelfTest = Invoke-AmdTimedOperation 'Publication contract' { Test-AmdPublicationContractSelfTest }
    $signaturePrimitiveSelfTest = Invoke-AmdTimedOperation 'Signature primitives' { Test-AmdSignaturePrimitiveSelfTest }
    $signatureContentTypeRoutingSelfTest = Invoke-AmdTimedOperation 'Signature content-type routing' { Test-AmdSignatureContentTypeRoutingSelfTest }
    $toolchainCapabilityParserSelfTest = Invoke-AmdTimedOperation 'Toolchain capability parser' { Test-AmdToolchainCapabilityParserSelfTest }
    $signToolVerificationProfileSelfTest = Invoke-AmdTimedOperation 'SignTool verification profile' { Test-AmdSignToolVerificationProfileSelfTest }
    $kernelSignatureCoverageSelfTest = Invoke-AmdTimedOperation 'Kernel signature coverage' { Test-AmdKernelSignatureCoverageSelfTest }
    $nativeToolLocalizationSelfTest = Invoke-AmdTimedOperation 'Native tool localization' { Test-AmdNativeToolLocalizationSelfTest }
    $nativeInteropTypeContractSelfTest = Invoke-AmdTimedOperation 'Native interop type contract' { Test-AmdNativeInteropTypeContractSelfTest }
    $collectionCardinalitySelfTest = Invoke-AmdTimedOperation 'PowerShell 5.1 collection cardinality' { Test-AmdPowerShell51CollectionCardinalitySelfTest }
    $collectionCardinalitySourceContract = Invoke-AmdTimedOperation 'Collection-cardinality source contract' { Test-AmdCollectionCardinalitySourceContract -Path $PSCommandPath }
    $canonicalJsonCrossRuntimeSelfTest = Invoke-AmdTimedOperation 'Canonical JSON cross-runtime contract' { Test-AmdCanonicalJsonCrossRuntimeSelfTest }
    $windowsExecutionContextSelfTest = Invoke-AmdTimedOperation 'Windows execution-context evidence contract' { Test-AmdWindowsExecutionContextSelfTest }
    $threeToolCommonCoreSelfTest = Invoke-AmdTimedOperation 'Three-tool common-core contract' { Test-AmdThreeToolCommonCoreContract }
    $ordinalOrderingSelfTest = Invoke-AmdTimedOperation 'Ordinal ordering contract' { Test-AmdOrdinalOrderingSelfTest }
    $pathSafetyLogicSelfTest = Invoke-AmdTimedOperation 'Path safety logic' { Test-AmdPathSafetyLogic }
    $archivePathSafetyLogicSelfTest = Invoke-AmdTimedOperation 'Archive path safety logic' { Test-AmdArchivePathSafetyLogic }
    $toolchainCapabilityEvidence = Invoke-AmdTimedOperation 'Windows driver toolchain capability evidence' { Get-AmdWindowsDriverToolchainCapabilityEvidence }
    $toolchainPrivatePath = Join-Path $toolRoot 'inventory\host\toolchain-capabilities-private.json'
    $toolchainSummaryPath = Join-Path $toolRoot 'inventory\toolchain-capabilities.json'
    Write-AmdJsonFile -Path $toolchainPrivatePath -Value $toolchainCapabilityEvidence.PrivateEvidence -Depth 40
    Write-AmdJsonFile -Path $toolchainSummaryPath -Value $toolchainCapabilityEvidence.PublicSummary -Depth 40 -Compress
    $selfTestResults = @(
        $compiledSelectorSelfTest,
        $architectureSelfTest,
        $msiProjectionSelfTest,
        $msiColumnDiscoverySelfTest,
        $msiTableRowPipelineIsolationSelfTest,
        $msiAssessmentSelfTest,
        [pscustomobject][ordered]@{Status=if($acquisitionAssessmentSelfTest.Status -eq 'Pass'){'Pass'}else{'Fail'}},
        $httpDownloadTransportSelfTest,
        $httpRetryPolicySelfTest,
        $requestedReleaseDiscoverySelfTest,
        $releaseNotesUrlCandidateSelfTest,
        $curatedLatestReleaseSelfTest,
        $selectorProductCorrelationSelfTest,
        $curatedReleaseNoteCorrelationSelfTest,
        $diagnosticPrimitiveSelfTest,
        $expectedFallbackProbeSelfTest,
        $sequentialDownloadSourceContract,
        [pscustomobject][ordered]@{Status=if($publicationEligibilitySelfTest.Status -eq 'Pass'){'Pass'}else{'Fail'}},
        [pscustomobject][ordered]@{Status=if($sourceCompatibilityIssues.Count -eq 0){'Pass'}else{'Fail'}},
        [pscustomobject][ordered]@{Status=if($toolVersionIssues.Count -eq 0){'Pass'}else{'Fail'}},
        $portableNormalizationSelfTest,
        $publicationContractSelfTest,
        $signaturePrimitiveSelfTest,
        $signatureContentTypeRoutingSelfTest,
        $toolchainCapabilityParserSelfTest,
        $signToolVerificationProfileSelfTest,
        $kernelSignatureCoverageSelfTest,
        $nativeToolLocalizationSelfTest,
        $nativeInteropTypeContractSelfTest,
        $collectionCardinalitySelfTest,
        $collectionCardinalitySourceContract,
        $canonicalJsonCrossRuntimeSelfTest,
        $windowsExecutionContextSelfTest,
        $threeToolCommonCoreSelfTest,
        $ordinalOrderingSelfTest,
        $pathSafetyLogicSelfTest,
        $archivePathSafetyLogicSelfTest
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
        SchemaVersion = '1.3'
        ToolkitVersion = $script:AmdChipsetResearchToolkitVersion
        CollectedAtUtc = [DateTime]::UtcNow.ToString('o')
        Platform = $platform
        ExecutionContext = Get-AmdWindowsExecutionContext
        LocalizationContext = $toolchainCapabilityEvidence.PublicSummary.LocalizationContext
        PowerShell = [pscustomobject]@{
            Version = $version.ToString()
            PSEdition = $engine
            RuntimeSupported = $runtimeSupported
        }
        Dependencies = [pscustomobject]@{
            SevenZip = $sevenZipInfo
            WindowsDriverToolchain = $toolchainCapabilityEvidence.PublicSummary
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
            AcquisitionAssessment = $acquisitionAssessmentSelfTest
            HttpDownloadTransport = $httpDownloadTransportSelfTest
            HttpRetryPolicy = $httpRetryPolicySelfTest
            RequestedReleaseDiscovery = $requestedReleaseDiscoverySelfTest
            ReleaseNotesUrlCandidates = $releaseNotesUrlCandidateSelfTest
            CuratedLatestRelease = $curatedLatestReleaseSelfTest
            SelectorProductCorrelation = $selectorProductCorrelationSelfTest
            CuratedReleaseNoteCorrelation = $curatedReleaseNoteCorrelationSelfTest
            DiagnosticPrimitives = $diagnosticPrimitiveSelfTest
            ExpectedFallbackProbe = $expectedFallbackProbeSelfTest
            SequentialDownloadSourceContract = $sequentialDownloadSourceContract
            SourceCompatibility = [pscustomobject][ordered]@{Status=if($sourceCompatibilityIssues.Count -eq 0){'Pass'}else{'Fail'};Issues=@($sourceCompatibilityIssues)}
            ToolVersionConsistency = [pscustomobject][ordered]@{Status=if($toolVersionIssues.Count -eq 0){'Pass'}else{'Fail'};Issues=@($toolVersionIssues)}
            PortableAnalysisNormalization = $portableNormalizationSelfTest
            PublicationEligibility = $publicationEligibilitySelfTest
            PublicationContract = $publicationContractSelfTest
            SignaturePrimitives = $signaturePrimitiveSelfTest
            SignatureContentTypeRouting = $signatureContentTypeRoutingSelfTest
            ToolchainCapabilityParser = $toolchainCapabilityParserSelfTest
            SignToolVerificationProfile = $signToolVerificationProfileSelfTest
            KernelSignatureCoverage = $kernelSignatureCoverageSelfTest
            NativeToolLocalization = $nativeToolLocalizationSelfTest
            NativeInteropTypeContract = $nativeInteropTypeContractSelfTest
            PowerShell51CollectionCardinality = $collectionCardinalitySelfTest
            CollectionCardinalitySourceContract = $collectionCardinalitySourceContract
            CanonicalJsonCrossRuntime = $canonicalJsonCrossRuntimeSelfTest
            ThreeToolCommonCoreContract = $threeToolCommonCoreSelfTest
            OrdinalOrderingContract = $ordinalOrderingSelfTest
            PathSafetyLogic = $pathSafetyLogicSelfTest
            ArchivePathSafetyLogic = $archivePathSafetyLogicSelfTest
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
        CanonicalJsonCrossRuntimeSelfTest = $canonicalJsonCrossRuntimeSelfTest.Status
        ThreeToolCommonCoreContractSelfTest = $threeToolCommonCoreSelfTest.Status
        OrdinalOrderingContractSelfTest = $ordinalOrderingSelfTest.Status
        CompiledSelectorContractSelfTest = $compiledSelectorSelfTest.Status
        HostArchitectureNormalizationSelfTest = $architectureSelfTest.Status
        MsiTableNameProjectionSelfTest = $msiProjectionSelfTest.Status
        MsiFieldCountIndependentColumnDiscoverySelfTest = $msiColumnDiscoverySelfTest.Status
        MsiTableRowPipelineIsolationSelfTest = $msiTableRowPipelineIsolationSelfTest.Status
        MsiDeclarativeAssessmentSelfTest = $msiAssessmentSelfTest.Status
        AcquisitionAssessmentSelfTest = $acquisitionAssessmentSelfTest.Status
        HttpDownloadTransportSelfTest = $httpDownloadTransportSelfTest.Status
        HttpRetryPolicySelfTest = $httpRetryPolicySelfTest.Status
        RequestedReleaseDiscoverySelfTest = $requestedReleaseDiscoverySelfTest.Status
        ReleaseNotesUrlCandidateSelfTest = $releaseNotesUrlCandidateSelfTest.Status
        CuratedLatestReleaseSelfTest = $curatedLatestReleaseSelfTest.Status
        SelectorProductCorrelationSelfTest = $selectorProductCorrelationSelfTest.Status
        CuratedReleaseNoteCorrelationSelfTest = $curatedReleaseNoteCorrelationSelfTest.Status
        DiagnosticPrimitiveSelfTest = $diagnosticPrimitiveSelfTest.Status
        ExpectedFallbackProbeSelfTest = $expectedFallbackProbeSelfTest.Status
        SequentialDownloadSourceContractSelfTest = $sequentialDownloadSourceContract.Status
        PublicationEligibilitySelfTest = $publicationEligibilitySelfTest.Status
        SourceCompatibilitySelfTest = if($sourceCompatibilityIssues.Count -eq 0){'Pass'}else{'Fail'}
        ToolVersionConsistencySelfTest = if($toolVersionIssues.Count -eq 0){'Pass'}else{'Fail'}
        PortableAnalysisNormalizationSelfTest = $portableNormalizationSelfTest.Status
        PublicationContractSelfTest = $publicationContractSelfTest.Status
        SignaturePrimitiveSelfTest = $signaturePrimitiveSelfTest.Status
        SignatureContentTypeRoutingSelfTest = $signatureContentTypeRoutingSelfTest.Status
        ToolchainCapabilityParserSelfTest = $toolchainCapabilityParserSelfTest.Status
        SignToolVerificationProfileSelfTest = $signToolVerificationProfileSelfTest.Status
        KernelSignatureCoverageSelfTest = $kernelSignatureCoverageSelfTest.Status
        NativeToolLocalizationSelfTest = $nativeToolLocalizationSelfTest.Status
        NativeInteropTypeContractSelfTest = $nativeInteropTypeContractSelfTest.Status
        PowerShell51CollectionCardinalitySelfTest = $collectionCardinalitySelfTest.Status
        CollectionCardinalitySourceContractSelfTest = $collectionCardinalitySourceContract.Status
        PathSafetyLogicSelfTest = $pathSafetyLogicSelfTest.Status
        ArchivePathSafetyLogicSelfTest = $archivePathSafetyLogicSelfTest.Status
        SignToolCapabilityStatus = if ($toolchainCapabilityEvidence.PublicSummary.Tools) { $st=@($toolchainCapabilityEvidence.PublicSummary.Tools | Where-Object { $_.Family -eq 'SignTool' } | Select-Object -First 1); if($st.Count -gt 0){$st[0].Status}else{'NotObserved'} } else { $toolchainCapabilityEvidence.PublicSummary.Status }
        Inf2CatCapabilityStatus = if ($toolchainCapabilityEvidence.PublicSummary.Tools) { $it=@($toolchainCapabilityEvidence.PublicSummary.Tools | Where-Object { $_.Family -eq 'Inf2Cat' } | Select-Object -First 1); if($it.Count -gt 0){$it[0].Status}else{'NotObserved'} } else { $toolchainCapabilityEvidence.PublicSummary.Status }
        ExecutionClass = $result.ExecutionContext.ExecutionClass
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

function Get-AmdCanonicalChipsetReleaseNotesUrl {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$ReleaseVersion
    )

    $normalized = Get-AmdVersionFromText -Text $ReleaseVersion
    if ([string]::IsNullOrWhiteSpace($normalized)) {
        throw ('Invalid AMD chipset release version for release-note URL construction: {0}' -f $ReleaseVersion)
    }

    return ('https://www.amd.com/en/resources/support-articles/release-notes/RN-RYZEN-CHIPSET-{0}.html' -f $normalized.Replace('.', '-'))
}

function Get-AmdChipsetReleaseNotesUrlCandidates {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$ReleaseVersion,
        [string]$PrimaryUrl
    )

    $results = New-Object 'System.Collections.Generic.List[string]'
    function Add-Url {
        param([string]$Url)
        if ([string]::IsNullOrWhiteSpace($Url)) { return }
        if (-not $results.Contains($Url)) { $results.Add($Url) }
    }

    if ($PrimaryUrl) {
        Add-Url -Url $PrimaryUrl
    }
    else {
        Add-Url -Url (Get-AmdCanonicalChipsetReleaseNotesUrl -ReleaseVersion $ReleaseVersion)
    }

    # AMD's CMS currently exposes 7.02.13.148 beneath a migrated legacy path rather
    # than the otherwise-stable flat release-notes URL. Keep the vendor-observed
    # alias explicit and SHA/version-scoped instead of guessing arbitrary parent paths.
    if ($ReleaseVersion -eq '7.02.13.148') {
        Add-Url -Url 'https://www.amd.com/en/resources/support-articles/release-notes/RN-RYZEN-CHIPSET-6-10-17-152/RN-RYZEN-CHIPSET-7-02-13-148.html'
    }

    return @($results.ToArray())
}

function Test-AmdReleaseNotesUrlCandidateSelfTest {
    [CmdletBinding()]
    param()

    $latest = @(Get-AmdChipsetReleaseNotesUrlCandidates -ReleaseVersion '8.08.12.551')
    $historical = @(Get-AmdChipsetReleaseNotesUrlCandidates -ReleaseVersion '7.02.13.148')

    $expectedAlias = 'https://www.amd.com/en/resources/support-articles/release-notes/RN-RYZEN-CHIPSET-6-10-17-152/RN-RYZEN-CHIPSET-7-02-13-148.html'
    $derivedDownloads = @(
        Get-AmdInstallerDownloadCandidates `
            -ReleaseVersion '7.02.13.148' `
            -ReleaseNotesUrl $expectedAlias `
            -Html ''
    )
    $expectedInstaller = 'https://drivers.amd.com/drivers/amd_chipset_software_7.02.13.148.exe'
    $ok = (
        $latest.Count -ge 1 -and
        $historical.Count -ge 2 -and
        ($historical -contains $expectedAlias) -and
        ($derivedDownloads -contains $expectedInstaller)
    )

    return [pscustomobject][ordered]@{
        Status=if($ok){'Pass'}else{'Fail'}
        LatestCandidateCount=$latest.Count
        HistoricalCandidateCount=$historical.Count
        HistoricalAliasObserved=($historical -contains $expectedAlias)
        DerivedInstallerCandidateObserved=($derivedDownloads -contains $expectedInstaller)
    }
}

function Test-AmdRequestedReleaseDiscoverySelfTest {
    [CmdletBinding()]
    param()

    $version = '8.08.12.551'
    $expected = 'https://www.amd.com/en/resources/support-articles/release-notes/RN-RYZEN-CHIPSET-8-08-12-551.html'
    $actual = Get-AmdCanonicalChipsetReleaseNotesUrl -ReleaseVersion $version
    $roundTrip = Get-AmdVersionFromText -Text $actual

    # Negative self-tests must validate rejection without intentionally emitting a
    # caught terminating error into the user-visible transcript.
    $invalidNormalized = Get-AmdVersionFromText -Text 'not-a-release-version'
    $invalidRejected = [string]::IsNullOrWhiteSpace([string]$invalidNormalized)

    $ok = ($actual -eq $expected -and $roundTrip -eq $version -and $invalidRejected)
    return [pscustomobject][ordered]@{
        Status = if ($ok) { 'Pass' } else { 'Fail' }
        ReleaseVersion = $version
        CanonicalUrl = $actual
        RoundTripVersion = $roundTrip
        InvalidVersionRejected = $invalidRejected
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
        [string[]]$AdditionalReleaseNotesUrl = @(),
        [string[]]$RequestedReleaseVersion = @()
    )

    $toolRoot = Get-AmdResearchToolkitRoot

    if (-not $SeedPath) {
        $SeedPath = Join-Path $toolRoot 'data\seed-releases.json'
    }

    if (-not $OutputPath) {
        $OutputPath = Join-Path $toolRoot 'inventory\releases.json'
    }

    $requestedVersionsList = New-Object 'System.Collections.Generic.List[string]'
    foreach ($requestedValue in @($RequestedReleaseVersion)) {
        if ([string]::IsNullOrWhiteSpace([string]$requestedValue)) { continue }
        $normalizedRequestedVersion = Get-AmdVersionFromText -Text ([string]$requestedValue)
        if ([string]::IsNullOrWhiteSpace($normalizedRequestedVersion)) {
            throw ('Invalid -ReleaseVersion value: {0}' -f [string]$requestedValue)
        }
        $requestedVersionsList.Add($normalizedRequestedVersion)
    }
    $requestedVersions = @(Get-AmdOrdinalSortedUniqueStrings -Values @($requestedVersionsList.ToArray()))

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

    $requestedFallbackCount = 0
    if ($requestedVersions.Count -gt 0) {
        foreach ($requestedVersion in $requestedVersions) {
            $existingRequested = @($records | Where-Object { [string]$_.ReleaseVersion -eq $requestedVersion })
            if ($existingRequested.Count -gt 0) { continue }

            Add-ReleaseRecord `
                -Version $requestedVersion `
                -Url (Get-AmdCanonicalChipsetReleaseNotesUrl -ReleaseVersion $requestedVersion) `
                -Source 'RequestedRelease' `
                -Detail 'Canonical AMD release-note URL derived from exact -ReleaseVersion input; Metadata validates the page before acquisition.'
            $requestedFallbackCount++
        }
        Write-AmdStep ('Exact-release discovery mode: requested={0}; synthesized canonical release-note record(s)={1}; global sitemap enumeration skipped.' -f ($requestedVersions -join ', '),$requestedFallbackCount)
    }

    $sitemapErrors = New-Object System.Collections.Generic.List[object]
    $sitemapIndex = 0
    if ($requestedVersions.Count -eq 0) {
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
    }


    # Release-note URL is provenance, not identity. AMD can expose aliases or
    # unusual nested URLs for the same release, so normalize to one record per
    # four-part release version. Operator input has highest precedence, then
    # curated seed data, then exact-request fallback, then sitemap discovery. Alternate URLs remain in
    # DiscoveryDiagnostics for auditability.
    $deduplicated = New-Object System.Collections.Generic.List[object]
    $duplicateVersionUrls = New-Object System.Collections.Generic.List[object]

    foreach ($group in @($records | Group-Object -Property ReleaseVersion)) {
        $candidates = @(
            $group.Group |
                Sort-Object `
                    @{ Expression = {
                        switch ([string]$_.DiscoverySource) {
                            'Operator'         { 40 }
                            'Seed'             { 30 }
                            'RequestedRelease' { 20 }
                            'AmdSitemap'       { 10 }
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

    if ($requestedVersions.Count -gt 0) {
        $sorted = @($sorted | Where-Object { $requestedVersions -contains [string]$_.ReleaseVersion })
        $missingRequestedVersionsList = New-Object 'System.Collections.Generic.List[string]'
        foreach ($requestedVersion in $requestedVersions) {
            if (@($sorted | Where-Object { [string]$_.ReleaseVersion -eq $requestedVersion }).Count -eq 0) {
                $missingRequestedVersionsList.Add($requestedVersion)
            }
        }
        $missingRequestedVersions = @($missingRequestedVersionsList.ToArray())
        if ($missingRequestedVersions.Count -gt 0) {
            throw ('Requested release discovery did not produce record(s) for: {0}' -f ($missingRequestedVersions -join ', '))
        }
    }

    $output = [pscustomobject]@{
        SchemaVersion = '1.0'
        ToolkitVersion = $script:AmdChipsetResearchToolkitVersion
        GeneratedAtUtc = [DateTime]::UtcNow.ToString('o')
        Completeness = if ($requestedVersions.Count -gt 0) { 'RequestedReleasePinned' } else { 'BestEffort' }
        ReleaseCount = $sorted.Count
        Releases = $sorted
        DiscoveryDiagnostics = [pscustomobject]@{
            SitemapErrors = $sitemapErrors.ToArray()
            DuplicateReleaseUrls = $duplicateVersionUrls.ToArray()
            SeedPath = $SeedPath
            RequestedReleaseVersions = @($requestedVersions)
            ExactReleaseMode = ($requestedVersions.Count -gt 0)
            RequestedReleaseFallbackCount = $requestedFallbackCount
            SitemapEnumerationSkipped = ($requestedVersions.Count -gt 0)
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
            ('https://drivers.amd.com/drivers/AMD_Chipset_Software_{0}.exe' -f $ReleaseVersion),
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
        $requestedUrl = [string]$release.ReleaseNotesUrl

        Write-AmdStep ('Metadata [{0}/{1}] {2}' -f $releaseIndex, $releaseTotal, $version)

        $safe = if ($version) { ConvertTo-AmdSafeName -Value $version } else { Get-AmdStringSha256 -Text $requestedUrl }
        $htmlPath = Join-Path $EvidenceDirectory ($safe + '.html')

        $status = 'Fetched'
        $errorText = $null
        $html = $null
        $effectiveUrl = $requestedUrl
        $fetchAttempts = New-Object 'System.Collections.Generic.List[object]'
        $urlCandidates = @(Get-AmdChipsetReleaseNotesUrlCandidates -ReleaseVersion $version -PrimaryUrl $requestedUrl)

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
            $candidateIndex = 0
            foreach ($candidateUrl in $urlCandidates) {
                $candidateIndex++
                Set-AmdDiagnosticStep -FunctionName 'Invoke-AmdMetadataStage' -Step 'FetchReleaseNotes' -Data @{ ReleaseVersion=$version; CandidateIndex=$candidateIndex; CandidateCount=$urlCandidates.Count; Uri=$candidateUrl }
                $response = Invoke-AmdQuietTextRequest `
                    -Uri $candidateUrl `
                    -TimeoutSec 90 `
                    -MaximumRedirection 10 `
                    -MaximumAttempts 4 `
                    -BaseRetryDelayMilliseconds 1000 `
                    -MaximumRetryDelayMilliseconds 15000

                foreach ($attempt in @($response.Attempts)) {
                    $fetchAttempts.Add([pscustomobject][ordered]@{
                        CandidateIndex=$candidateIndex
                        CandidateUrl=$candidateUrl
                        Attempt=$attempt
                    })
                }

                if (-not $response.Success) {
                    $errorText = $response.Error
                    $effectiveUrl = $candidateUrl
                    continue
                }

                $html = [string]$response.Content
                $effectiveUrl = if (-not [string]::IsNullOrWhiteSpace([string]$response.ResponseUri)) {
                    [string]$response.ResponseUri
                }
                else {
                    $candidateUrl
                }

                try {
                    Write-AmdUtf8NoBom -Path $htmlPath -Text $html
                    $status = 'Fetched'
                    $errorText = $null
                    break
                }
                catch {
                    $status = 'FetchFailed'
                    $errorText = Get-AmdCompactErrorMessage -Message $_.Exception.Message -MaximumLength 300
                    $html = $null
                }
            }

            if (-not $html) {
                $status = 'FetchFailed'
            }
        }

        $title = $null
        $articleNumber = $null
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
        }

        # Important resilience contract: installer candidate derivation is independent
        # of release-note HTML availability. Exact version-derived vendor candidates
        # remain available when AMD temporarily closes a metadata connection.
        $downloadUrls = @(
            Get-AmdInstallerDownloadCandidates `
                -ReleaseVersion $version `
                -ReleaseNotesUrl $effectiveUrl `
                -Html ([string]$html)
        )

        $candidateDerivation = if ($html) { 'HtmlPlusVersionDerivedFallback' } else { 'VersionDerivedFallbackOnly' }

        $results.Add([pscustomobject]@{
            ReleaseVersion = $version
            RequestedReleaseNotesUrl = $requestedUrl
            ReleaseNotesUrl = $effectiveUrl
            ReleaseNotesUrlCandidates = @($urlCandidates)
            ArticleNumber = $articleNumber
            PageTitle = $title
            FetchStatus = $status
            FetchError = $errorText
            FetchAttempts = @($fetchAttempts.ToArray())
            RetrievedAtUtc = [DateTime]::UtcNow.ToString('o')
            HtmlEvidencePath = $htmlPath
            HtmlSha256 = $htmlSha256
            CandidateDerivation = $candidateDerivation
            CandidateDownloadUrls = @($downloadUrls)
        })

        $itemSw.Stop()
        if ($status -in @('Fetched','Cached')) {
            Write-AmdOk ('Metadata [{0}/{1}] {2} -> {3}; candidates={4}; elapsed={5}' -f `
                $releaseIndex, $releaseTotal, $version, $status, $downloadUrls.Count, (Format-AmdElapsed $itemSw.Elapsed))
        }
        else {
            Write-AmdCaution ('Metadata [{0}/{1}] {2} -> {3}; derived candidates={4}; {5}; elapsed={6}' -f `
                $releaseIndex, $releaseTotal, $version, $status, $downloadUrls.Count, $errorText, (Format-AmdElapsed $itemSw.Elapsed))
        }
    }

    $output = [pscustomobject]@{
        SchemaVersion = '1.1'
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
        $downloadAttempts = New-Object 'System.Collections.Generic.List[object]'
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
            $validation = $null
            $downloadRequired = $true

            if ((Test-Path -LiteralPath $localPath -PathType Leaf) -and -not $Force) {
                # Validate a cached artifact before treating it as authoritative. If an
                # earlier interrupted/partial transfer left a bad cache entry, retain
                # that object as private diagnostics, remove it, and retry the SAME
                # highest-priority candidate over the network instead of skipping to a
                # speculative alternate filename.
                try {
                    $validation = Get-AmdInstallerFileValidation -Path $localPath
                }
                catch {
                    $validation = [pscustomobject]@{ Valid=$false; Error=('cached validation threw: {0}' -f (Get-AmdCompactErrorMessage -Message $_.Exception.Message -MaximumLength 300)) }
                }

                if ($validation.Valid) {
                    $status = 'Cached'
                    $downloadRequired = $false
                }
                else {
                    $diagnosticsRoot = Join-Path (Get-AmdPrivateEvidenceRoot) 'download-diagnostics'
                    New-AmdDirectory -Path $diagnosticsRoot | Out-Null
                    $diagName = ('invalid-cache-{0}-{1}' -f (ConvertTo-AmdSafeName -Value $version), [System.IO.Path]::GetFileName($localPath))
                    $diagPath = Join-Path $diagnosticsRoot $diagName
                    Copy-Item -LiteralPath $localPath -Destination $diagPath -Force -ErrorAction SilentlyContinue
                    Remove-Item -LiteralPath $localPath -Force -ErrorAction SilentlyContinue
                    $downloadAttempts.Add([pscustomobject][ordered]@{
                        CandidateUrl=$candidate
                        CandidateIndex=$candidateIndex
                        Attempt=[pscustomobject][ordered]@{
                            Attempt=0
                            NoCache=$false
                            DisableKeepAlive=$false
                            Warmup=$null
                            StatusCode=$null
                            ResponseUri=$null
                            ContentRange=$null
                            ContentLength=$null
                            ContentType=$null
                            ContentEncoding=$null
                            AcceptRanges=$null
                            RetryAfter=$null
                            BytesWritten=$null
                            Classification='InvalidCachedArtifact'
                            Validation=$validation
                            DiagnosticPath=$diagPath
                            WebExceptionStatus=$null
                            Retryable=$true
                            RetryReason='InvalidCachedArtifactNetworkRefresh'
                            DelayBeforeNextAttemptMilliseconds=0
                            Error=('Cached artifact rejected before network retry: {0}' -f $validation.Error)
                        }
                    })
                }
            }

            if ($downloadRequired) {
                $diagnosticsRoot = Join-Path (Get-AmdPrivateEvidenceRoot) 'download-diagnostics'
                $downloadResult = Invoke-AmdQuietFileDownload `
                    -Uri $candidate `
                    -OutFile $localPath `
                    -Referer ([string]$release.ReleaseNotesUrl) `
                    -TimeoutSec 600 `
                    -MaximumRedirection 10 `
                    -MaximumAttempts 4 `
                    -BaseRetryDelayMilliseconds 1000 `
                    -MaximumRetryDelayMilliseconds 15000 `
                    -DiagnosticDirectory $diagnosticsRoot `
                    -DiagnosticPrefix ('invalid-download-{0}' -f (ConvertTo-AmdSafeName -Value $version))
                foreach ($attemptEvidence in @($downloadResult.Attempts)) {
                    $downloadAttempts.Add([pscustomobject][ordered]@{ CandidateUrl=$candidate; CandidateIndex=$candidateIndex; Attempt=$attemptEvidence })
                }
                if (-not $downloadResult.Success) {
                    $errors.Add(('{0}: {1} [{2}]' -f $candidate, $downloadResult.Error, $downloadResult.Classification))
                    continue
                }
                $status = 'Downloaded'
                $validation = $null
            }

            if ($null -eq $validation) {
                try {
                    $validation = Get-AmdInstallerFileValidation -Path $localPath
                }
                catch {
                    $errors.Add(('{0}: validation failed: {1}' -f $candidate, (Get-AmdCompactErrorMessage -Message $_.Exception.Message -MaximumLength 300)))
                    Remove-Item -LiteralPath $localPath -Force -ErrorAction SilentlyContinue
                    continue
                }
            }

            if (-not $validation.Valid) {
                $diagnosticsRoot = Join-Path (Get-AmdPrivateEvidenceRoot) 'download-diagnostics'
                New-AmdDirectory -Path $diagnosticsRoot | Out-Null
                $diagName = ('invalid-download-{0}-{1}' -f (ConvertTo-AmdSafeName -Value $version), [System.IO.Path]::GetFileName($localPath))
                $diagPath = Join-Path $diagnosticsRoot $diagName
                Copy-Item -LiteralPath $localPath -Destination $diagPath -Force -ErrorAction SilentlyContinue
                Remove-Item -LiteralPath $localPath -Force -ErrorAction SilentlyContinue
                $errors.Add(('{0}: downloaded artifact failed validation ({1}); diagnostic={2}' -f $candidate, $validation.Error, $diagPath))
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
                    DownloadAttempts = @($downloadAttempts.ToArray())
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
                DownloadAttempts = @($downloadAttempts.ToArray())
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

    if ($ReleaseVersion.Count -gt 0 -and $failed -gt 0) {
        $requestedFailures = @(
            $results |
                Where-Object { $_.Status -notin @('Downloaded','Cached') } |
                ForEach-Object { '{0}={1}' -f $_.ReleaseVersion,$_.Status }
        )
        throw ('Explicitly requested release artifact(s) unavailable after resilient acquisition: {0}. Inspect acquisition.json DownloadAttempts and metadata FetchAttempts.' -f ($requestedFailures -join ', '))
    }
}



function Initialize-AmdInstallShieldStreamDecoder {
    [CmdletBinding()]
    param()

    $existingType = 'AmdChipsetResearchV2.IsSetupStreamReader' -as [type]
    if ($existingType) {
        if ($null -ne $existingType.GetMethod('Probe',[System.Reflection.BindingFlags]'Public,Static') -and
            $null -ne $existingType.GetMethod('Extract',[System.Reflection.BindingFlags]'Public,Static')) {
            return
        }
        throw 'Loaded InstallShield decoder type does not satisfy the required Probe/Extract method contract.'
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

namespace AmdChipsetResearchV2
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
    return [AmdChipsetResearchV2.IsSetupStreamReader]::Probe((Resolve-Path -LiteralPath $Path).Path)
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

    $result = [AmdChipsetResearchV2.IsSetupStreamReader]::Extract(
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
        $artifactPathId = ('a{0:D4}' -f $releaseIndex)
        $releaseRoot = Get-AmdShortExtractionPath -ArtifactOrdinal $releaseIndex -ExtractionBasePath $OutputDirectory
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
            $containerPathId = ('c{0:D4}' -f $containerSequence)
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
            $archivePathSafety = $null

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
                    $archivePathSafety=Get-AmdArchiveExtractionPathAssessment -SevenZipPath $sevenZip -ArchivePath $containerPath -OutputDirectory $out
                    if([string]$archivePathSafety.Status -ne 'Pass'){
                        $status='ExtractionBlockedPathSafety'
                        $errorText=('Archive path-safety preflight blocked extraction: {0}' -f (@($archivePathSafety.Issues)-join ' | '))
                        $releaseFailed = $true
                        $releaseErrors.Add(('{0}: {1}' -f $containerPath, $errorText))
                    }
                    else {
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
                PathSafety = $archivePathSafety
                Error = $errorText
                EvidenceLogPath = $logPath
                Log = ($outputText -join [Environment]::NewLine)
            })

            if ($status -in @('ExtractionFailed','ExtractionBlockedPathSafety') -or $depth -ge $MaxDepth) {
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
            ArtifactPathId = $artifactPathId
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
    $null = Assert-AmdExtractionCompleteSet -Items @($releaseResults.ToArray()) -Context 'Chipset downstream analysis'
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
    # A partial-name System.Security load can fail in a clean Windows PowerShell 5.1
    # process even when the .NET Framework assembly is installed. Use the complete
    # strong name so SignedCms availability does not depend on an earlier command
    # having incidentally loaded System.Security into the process.
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
            InstallShieldNativeType='NotApplicable';InstallShieldRequiredMethods=@('Probe','Extract');InstallShieldMissingMethods=@()
        }
    }

    $catalogReady = Initialize-AmdWindowsCatalogNativeType
    $localizationReady = Initialize-AmdWindowsLocalizationNativeTypes
    try { Initialize-AmdInstallShieldStreamDecoder; $installShieldReady = $true } catch { $installShieldReady = $false }

    $catalogType = 'AmdResearchCatalogNativeV2' -as [type]
    $localizationType = 'AmdResearchWindowsLocalizationNativeV1' -as [type]
    $installShieldType = 'AmdChipsetResearchV2.IsSetupStreamReader' -as [type]

    $catalogRequired = @('CalculateCatalogHashes','Enumerate')
    $localizationRequired = @('UserDefaultLocaleName','SystemDefaultLocaleName','GetUserDefaultUILanguage','GetSystemDefaultUILanguage','GetConsoleCP','GetConsoleOutputCP')
    $installShieldRequired = @('Probe','Extract')

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
    $installShieldMissing = @(
        if($installShieldReady -and $installShieldType){
            $installShieldRequired | Where-Object { $null -eq $installShieldType.GetMethod($_,[System.Reflection.BindingFlags]'Public,Static') }
        }
        else { $installShieldRequired }
    )

    $ok = (@($catalogMissing).Count -eq 0 -and @($localizationMissing).Count -eq 0 -and @($installShieldMissing).Count -eq 0)
    return [pscustomobject][ordered]@{
        Status=if($ok){'Pass'}else{'Fail'};Applicable=$true
        CatalogNativeType=if($catalogType){$catalogType.FullName}else{$null};CatalogRequiredMethods=$catalogRequired;CatalogMissingMethods=$catalogMissing
        LocalizationNativeType=if($localizationType){$localizationType.FullName}else{$null};LocalizationRequiredMethods=$localizationRequired;LocalizationMissingMethods=$localizationMissing
        InstallShieldNativeType=if($installShieldType){$installShieldType.FullName}else{$null};InstallShieldRequiredMethods=$installShieldRequired;InstallShieldMissingMethods=$installShieldMissing
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

    # Reproduce the Windows PowerShell 5.1 shape that caused 2.1.9 Test to fail:
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

function Test-AmdCuratedLatestReleaseSelfTest {
    [CmdletBinding()]
    param()

    $expectedVersion = '8.08.12.551'
    $expectedReleaseNotesUrl = 'https://www.amd.com/en/resources/support-articles/release-notes/RN-RYZEN-CHIPSET-8-08-12-551.html'
    $expectedInstallerUrl = 'https://drivers.amd.com/drivers/AMD_Chipset_Software_8.08.12.551.exe'
    $seedPath = Join-Path (Get-AmdResearchToolkitRoot) 'data\seed-releases.json'
    $issues = New-Object 'System.Collections.Generic.List[string]'
    $records = @()

    try {
        $seed = Read-AmdJsonFile -Path $seedPath
        $records = @($seed.Records)
    }
    catch {
        $issues.Add(('Seed release data could not be read: {0}' -f $_.Exception.Message))
    }

    $duplicateVersions = @($records | Group-Object ReleaseVersion | Where-Object { $_.Count -ne 1 })
    if ($duplicateVersions.Count -gt 0) {
        $issues.Add(('Duplicate curated release version(s): {0}' -f (@($duplicateVersions | ForEach-Object { $_.Name }) -join ', ')))
    }

    $latest = @(
        $records |
            Sort-Object @{ Expression = { try { [version]([string]$_.ReleaseVersion) } catch { [version]'0.0.0.0' } }; Descending = $true } |
            Select-Object -First 1
    )
    $record = @($records | Where-Object { [string]$_.ReleaseVersion -eq $expectedVersion })
    if ($latest.Count -ne 1 -or [string]$latest[0].ReleaseVersion -ne $expectedVersion) {
        $issues.Add(('Curated current-latest release is not {0}.' -f $expectedVersion))
    }
    if ($record.Count -ne 1 -or [string]$record[0].ReleaseNotesUrl -ne $expectedReleaseNotesUrl) {
        $issues.Add(('Curated release-note identity for {0} is missing or incorrect.' -f $expectedVersion))
    }

    $derivedInstallerUrls = @(
        Get-AmdInstallerDownloadCandidates `
            -ReleaseVersion $expectedVersion `
            -ReleaseNotesUrl $expectedReleaseNotesUrl `
            -Html ''
    )
    if ($derivedInstallerUrls.Count -eq 0 -or [string]$derivedInstallerUrls[0] -ne $expectedInstallerUrl) {
        $issues.Add(('The exact vendor current-latest installer URL is not the first deterministic candidate: {0}' -f $expectedInstallerUrl))
    }

    return [pscustomobject][ordered]@{
        Status = if ($issues.Count -eq 0) { 'Pass' } else { 'Fail' }
        ExpectedReleaseVersion = $expectedVersion
        CuratedLatestReleaseVersion = if ($latest.Count -eq 1) { [string]$latest[0].ReleaseVersion } else { $null }
        ReleaseNotesUrlMatched = ($record.Count -eq 1 -and [string]$record[0].ReleaseNotesUrl -eq $expectedReleaseNotesUrl)
        PreferredInstallerUrlMatched = ($derivedInstallerUrls.Count -gt 0 -and [string]$derivedInstallerUrls[0] -eq $expectedInstallerUrl)
        DuplicateReleaseVersionCount = $duplicateVersions.Count
        Issues = @($issues.ToArray())
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
            ToolkitVersion=$script:AmdChipsetResearchToolkitVersion
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
        ToolkitVersion=$script:AmdChipsetResearchToolkitVersion
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
        ToolkitVersion=$script:AmdChipsetResearchToolkitVersion
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
        return [pscustomobject][ordered]@{ SchemaVersion='amd-driver-windows-host-security-posture/1.0'; ToolkitVersion=$script:AmdChipsetResearchToolkitVersion; EvidenceScope='WindowsNative'; Status='NotApplicable'; ExecutionClass=$context.ExecutionClass; MutationPerformed=$false }
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
        ToolkitVersion = $script:AmdChipsetResearchToolkitVersion
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
        return [pscustomobject][ordered]@{ SchemaVersion='amd-driver-target-server-host-evidence/1.0'; ToolkitVersion=$script:AmdChipsetResearchToolkitVersion; Status='NotApplicable'; EvidenceScope='TargetServerHost'; ExecutionClass=$context.ExecutionClass; MutationPerformed=$false }
    }

    return [pscustomobject][ordered]@{
        SchemaVersion = 'amd-driver-target-server-host-evidence/1.0'
        ToolkitVersion = $script:AmdChipsetResearchToolkitVersion
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

function Invoke-AmdSignatureStage {
    [CmdletBinding()]
    param(
        [string]$ExtractionPath,
        [string]$OutputPath,
        [string]$NativeVerificationPath,
        [string]$WindowsHostPosturePath,
        [string]$ServerHostPosturePath
    )

    $toolRoot = Get-AmdResearchToolkitRoot
    if (-not $ExtractionPath) { $ExtractionPath = Join-Path $toolRoot 'inventory\extraction.json' }
    if (-not $OutputPath) { $OutputPath = Join-Path $toolRoot 'inventory\signature-analysis.json' }
    if (-not $NativeVerificationPath) { $NativeVerificationPath = Join-Path $toolRoot 'inventory\host\signature-native-verification.json' }
    if (-not $WindowsHostPosturePath) { $WindowsHostPosturePath = Join-Path $toolRoot 'inventory\host\windows-host-security-posture.json' }
    if (-not $ServerHostPosturePath) { $ServerHostPosturePath = Join-Path $toolRoot 'inventory\host\target-server-host-evidence.json' }

    if (-not (Test-Path -LiteralPath $ExtractionPath -PathType Leaf)) { throw ('Extraction inventory is missing: {0}' -f $ExtractionPath) }
    $extraction = Read-AmdJsonFile -Path $ExtractionPath
    $runtimeContext = Get-AmdWindowsExecutionContext
    Write-AmdStep ('Signature analysis execution class: {0}; evidence scopes: {1}' -f $runtimeContext.ExecutionClass,($runtimeContext.EvidenceScopes -join ', '))

    $signTool = Get-AmdWindowsSdkToolInfo -ToolName 'signtool.exe'
    $releaseResults = New-Object System.Collections.Generic.List[object]
    $nativeReleaseResults = New-Object System.Collections.Generic.List[object]
    $signatureStageSw = [System.Diagnostics.Stopwatch]::StartNew()

    # Chipset signature qualification is release-scoped rather than historical.
    # Other stages continue to inspect the whole selected release set. The expensive
    # Windows-native signature policy checks analyze only the newest selected release.
    # A single -ReleaseVersion selection therefore analyzes exactly that release.
    $availableReleases = @($extraction.Releases)
    if ($availableReleases.Count -eq 0) { throw 'Extraction inventory contains no releases for signature analysis.' }
    $signatureReleases = @(
        $availableReleases |
            Sort-Object @{ Expression = {
                try { [version]([string]$_.ReleaseVersion) } catch { [version]'0.0.0.0' }
            }; Descending = $true } |
            Select-Object -First 1
    )
    $releaseSelectionPolicy = if ($availableReleases.Count -eq 1) { 'OnlySelectedRelease' } else { 'NewestSelectedReleaseOnly' }
    Write-AmdStep ('Signature release policy: {0}; selected {1} from {2} release(s).' -f $releaseSelectionPolicy,[string]$signatureReleases[0].ReleaseVersion,$availableReleases.Count)
    $null = Assert-AmdExtractionCompleteSet -Items @($signatureReleases) -Context 'Chipset signature analysis'

    foreach ($release in $signatureReleases) {
        $version = [string]$release.ReleaseVersion
        $root = [string]$release.ExtractionRoot
        if (-not $root -or -not (Test-Path -LiteralPath $root -PathType Container)) {
            $releaseResults.Add([pscustomobject][ordered]@{ SchemaVersion=$script:AmdDriverSignatureAnalysisSchemaVersion; EvidenceScope='Static'; ReleaseVersion=$version; Status='ExtractionUnavailable'; FileCount=0; Files=@(); Certificates=@() })
            continue
        }

        Write-AmdStep ('Analyzing Authenticode and catalog signatures for release {0}.' -f $version)
        $candidateFiles = @(
            Get-ChildItem -LiteralPath $root -File -Recurse -ErrorAction SilentlyContinue |
                Where-Object { Test-AmdStaticSignatureCandidateFile -File $_ }
        )
        $groups = @($candidateFiles | Group-Object { Get-AmdSha256 -Path $_.FullName })
        $certificateStore = @{}
        $files = New-Object System.Collections.Generic.List[object]
        $nativeFiles = New-Object System.Collections.Generic.List[object]
        $runtimeVerificationPathByFileId = @{}
        $groupIndex = 0
        $groupTotal = $groups.Count
        Write-AmdStep ('Signature {0}: {1} unique file content group(s) queued.' -f $version,$groupTotal)

        foreach ($group in $groups) {
            $groupIndex++
            $representative = $group.Group | Select-Object -First 1
            $occurrences = @($group.Group | ForEach-Object { $_.FullName.Substring($root.Length).TrimStart('\','/') })
            $fileEvidence = Get-AmdStaticFileSignatureEvidence -Path $representative.FullName -Occurrences $occurrences -CertificateStore $certificateStore
            $files.Add($fileEvidence)

            if ($runtimeContext.ExecutionClass -in @('WindowsClient','WindowsServer','WindowsOther')) {
                $nativeVerificationFile = $representative.FullName
                $verificationPathKind = 'OriginalExtractedPath'
                # 7-Zip collision handling can rename catalogs to *.cat1, *.cat2, ... .
                # WinVerifyTrust/SignTool uses the filename extension when choosing catalog semantics,
                # so verify a byte-identical temporary *.cat alias rather than reporting a false HashMismatch.
                if ($fileEvidence.FileType -eq 'Catalog' -and [System.IO.Path]::GetExtension($representative.Name) -ine '.cat') {
                    $aliasRoot = Join-Path (Join-Path (Get-AmdPrivateEvidenceRoot) 'native-signature-aliases') $version
                    New-AmdDirectory -Path $aliasRoot | Out-Null
                    $nativeVerificationFile = Join-Path $aliasRoot ('{0}.cat' -f ([string]$fileEvidence.Sha256))
                    if (-not (Test-Path -LiteralPath $nativeVerificationFile -PathType Leaf)) {
                        Copy-Item -LiteralPath $representative.FullName -Destination $nativeVerificationFile -Force
                    }
                    $verificationPathKind = 'ByteIdenticalCanonicalCatalogAlias'
                }

                $runtimeVerificationPathByFileId[[string]$fileEvidence.FileId] = $nativeVerificationFile
                $authenticode = Get-AmdWindowsAuthenticodeObservation -Path $nativeVerificationFile
                $catalogEnumeration = $null
                $catalogHash = $null
                if ($fileEvidence.FileType -eq 'Catalog') {
                    $catalogEnumeration = Get-AmdWindowsCatalogMemberEvidence -Path $nativeVerificationFile
                }
                elseif ($fileEvidence.FileType -eq 'KernelBinary') {
                    $catalogHash = Get-AmdWindowsCatalogHashEvidence -Path $nativeVerificationFile
                }

                if ($signTool.Status -eq 'Available') {
                    $checks = @(Get-AmdSignToolVerificationEvidence -SignToolPath $signTool.Path -Path $nativeVerificationFile -FileType $fileEvidence.FileType)
                    $publicChecks = @($checks | ForEach-Object {
                        [pscustomobject][ordered]@{
                            Policy=$_.Policy
                            VerificationProfileId=$_.VerificationProfileId
                            Arguments=@($_.Arguments)
                            ExitCode=$_.ExitCode
                            Status=$_.Status
                            ResultClass=$_.ResultClass
                            CatalogFileId=$_.CatalogFileId
                            OutputSha256=$_.OutputSha256
                            OutputLineCount=$_.OutputLineCount
                            Error=$_.Error
                        }
                    })
                    $privateChecks = @($checks | ForEach-Object {
                        [pscustomobject][ordered]@{
                            Policy=$_.Policy
                            VerificationProfileId=$_.VerificationProfileId
                            Arguments=@($_.Arguments)
                            ExitCode=$_.ExitCode
                            Status=$_.Status
                            ResultClass=$_.ResultClass
                            CatalogFileId=$_.CatalogFileId
                            Output=@($_.PrivateOutput)
                            Error=$_.Error
                        }
                    })
                    $nativeFiles.Add([pscustomobject][ordered]@{
                        FileId=$fileEvidence.FileId
                        FileName=$fileEvidence.FileName
                        FileType=$fileEvidence.FileType
                        VerificationPathKind=$verificationPathKind
                        Authenticode=$authenticode
                        CatalogEnumeration=$catalogEnumeration
                        CatalogHash=$catalogHash
                        SignToolChecks=$privateChecks
                        SanitizedSignToolSummary=$publicChecks
                    })
                }
                else {
                    $nativeFiles.Add([pscustomobject][ordered]@{
                        FileId=$fileEvidence.FileId
                        FileName=$fileEvidence.FileName
                        FileType=$fileEvidence.FileType
                        VerificationPathKind=$verificationPathKind
                        Authenticode=$authenticode
                        CatalogEnumeration=$catalogEnumeration
                        CatalogHash=$catalogHash
                        SignToolChecks=@()
                        SanitizedSignToolSummary=@()
                        SignToolStatus='NotObservedToolUnavailable'
                    })
                }
            }

            if ($groupIndex -eq 1 -or ($groupIndex % 10) -eq 0 -or $groupIndex -eq $groupTotal) {
                Write-AmdStep ('Signature {0}: file {1}/{2}; static={3}; WindowsNative={4}; elapsed={5}' -f $version,$groupIndex,$groupTotal,$files.Count,$nativeFiles.Count,(Format-AmdElapsed $signatureStageSw.Elapsed))
            }
        }

        # Build content-addressed catalog associations after every catalog has been
        # enumerated. Catalog member reference tags are SHA-1/SHA-256 values; this is
        # more reliable than relying on collision-renamed extraction filenames.
        if ($runtimeContext.ExecutionClass -in @('WindowsClient','WindowsServer','WindowsOther') -and $signTool.Status -eq 'Available') {
            $staticFileById = @{}
            foreach ($staticFile in @($files.ToArray())) { $staticFileById[[string]$staticFile.FileId] = $staticFile }

            $catalogIdsByDigest = @{}
            foreach ($nativeCatalog in @($nativeFiles.ToArray() | Where-Object { $_.FileType -eq 'Catalog' -and $_.CatalogEnumeration -and $_.CatalogEnumeration.Status -eq 'Enumerated' })) {
                foreach ($member in @($nativeCatalog.CatalogEnumeration.Members)) {
                    $tag = ([string]$member.ReferenceTag).ToUpperInvariant()
                    if ([string]::IsNullOrWhiteSpace($tag)) { continue }
                    if (-not $catalogIdsByDigest.ContainsKey($tag)) {
                        $catalogIdsByDigest[$tag] = New-Object 'System.Collections.Generic.List[string]'
                    }
                    if (-not $catalogIdsByDigest[$tag].Contains([string]$nativeCatalog.FileId)) {
                        $catalogIdsByDigest[$tag].Add([string]$nativeCatalog.FileId)
                    }
                }
            }

            foreach ($nativeKernel in @($nativeFiles.ToArray() | Where-Object { $_.FileType -eq 'KernelBinary' })) {
                if (-not $staticFileById.ContainsKey([string]$nativeKernel.FileId)) { continue }
                $staticKernel = $staticFileById[[string]$nativeKernel.FileId]
                $catalogIds = New-Object 'System.Collections.Generic.List[string]'
                $catalogHashProperty = $nativeKernel.PSObject.Properties['CatalogHash']
                if ($null -ne $catalogHashProperty -and $null -ne $catalogHashProperty.Value) {
                    foreach ($digest in @([string]$catalogHashProperty.Value.Sha256,[string]$catalogHashProperty.Value.Sha1)) {
                        if ([string]::IsNullOrWhiteSpace($digest)) { continue }
                        $digestKey = $digest.ToUpperInvariant()
                        if ($catalogIdsByDigest.ContainsKey($digestKey)) {
                            foreach ($catalogId in @($catalogIdsByDigest[$digestKey].ToArray())) {
                                if (-not $catalogIds.Contains($catalogId)) { $catalogIds.Add($catalogId) }
                            }
                        }
                    }
                }

                $targetChecks = New-Object 'System.Collections.Generic.List[object]'
                foreach ($catalogId in @($catalogIds.ToArray())) {
                    if (-not $runtimeVerificationPathByFileId.ContainsKey($catalogId)) { continue }
                    if (-not $runtimeVerificationPathByFileId.ContainsKey([string]$nativeKernel.FileId)) { continue }
                    foreach ($check in @(Get-AmdCatalogBoundSignToolEvidence -SignToolPath $signTool.Path -DriverPath $runtimeVerificationPathByFileId[[string]$nativeKernel.FileId] -CatalogPath $runtimeVerificationPathByFileId[$catalogId] -CatalogFileId $catalogId)) {
                        $targetChecks.Add($check)
                    }
                }

                if ($targetChecks.Count -gt 0) {
                    $privateTargetChecks = @($targetChecks.ToArray() | ForEach-Object {
                        [pscustomobject][ordered]@{
                            Policy=$_.Policy
                            VerificationProfileId=$_.VerificationProfileId
                            Arguments=@($_.Arguments)
                            ExitCode=$_.ExitCode
                            Status=$_.Status
                            ResultClass=$_.ResultClass
                            CatalogFileId=$_.CatalogFileId
                            Output=@($_.PrivateOutput)
                            Error=$_.Error
                        }
                    })
                    $publicTargetChecks = @($targetChecks.ToArray() | ForEach-Object {
                        [pscustomobject][ordered]@{
                            Policy=$_.Policy
                            VerificationProfileId=$_.VerificationProfileId
                            Arguments=@($_.Arguments)
                            ExitCode=$_.ExitCode
                            Status=$_.Status
                            ResultClass=$_.ResultClass
                            CatalogFileId=$_.CatalogFileId
                            OutputSha256=$_.OutputSha256
                            OutputLineCount=$_.OutputLineCount
                            Error=$_.Error
                        }
                    })
                    $nativeKernel.SignToolChecks = @($nativeKernel.SignToolChecks) + @($privateTargetChecks)
                    $nativeKernel.SanitizedSignToolSummary = @($nativeKernel.SanitizedSignToolSummary) + @($publicTargetChecks)
                }
                else {
                    # Not a toolkit failure. Some binaries may be embedded-signature-only or
                    # the extracted catalog may not expose a digest reference that can be
                    # correlated read-only. Preserve the absence as an observation.
                    $nativeKernel | Add-Member -NotePropertyName CatalogBoundTargetVerification -NotePropertyValue ([pscustomobject][ordered]@{
                        Status='NotObservedCatalogAssociationUnavailable'
                        MatchedCatalogCount=0
                    }) -Force
                }
            }
        }

        $certificates = @($certificateStore.Keys | Sort-Object | ForEach-Object { $certificateStore[$_] })
        $releaseResults.Add([pscustomobject][ordered]@{
            SchemaVersion = $script:AmdDriverSignatureAnalysisSchemaVersion
            EvidenceScope = 'Static'
            ReleaseVersion = $version
            Status = 'Analyzed'
            FileCount = $files.Count
            UniqueCertificateCount = $certificates.Count
            Files = @($files.ToArray())
            Certificates = @($certificates)
        })
        if ($runtimeContext.ExecutionClass -in @('WindowsClient','WindowsServer','WindowsOther')) {
            $nativeReleaseResults.Add([pscustomobject][ordered]@{
                ReleaseVersion=$version
                SignToolStatus=$signTool.Status
                SignToolVersion=$signTool.Version
                Files=@($nativeFiles.ToArray())
            })
        }
    }

    $staticOutput = [pscustomobject][ordered]@{
        SchemaVersion = $script:AmdDriverSignatureAnalysisSchemaVersion
        ToolkitVersion = $script:AmdChipsetResearchToolkitVersion
        GeneratedAtUtc = Get-AmdUtcTimestamp
        EvidenceScope = 'Static'
        ReleaseSelectionPolicy = $releaseSelectionPolicy
        CandidateReleaseCount = $availableReleases.Count
        AnalyzedReleaseVersions = @($signatureReleases | ForEach-Object { [string]$_.ReleaseVersion })
        AnalysisBoundary = 'Cryptographic and structural evidence only. PE WIN_CERTIFICATE, CMS/PKCS#7, nested signatures, timestamps, certificates, and signed PE digests are static evidence. Windows catalog member enumeration, Windows trust policy, target-server acceptance, PnP installation, kernel load, and runtime functionality are separate evidence scopes.'
        Releases = @($releaseResults.ToArray())
    }
    Write-AmdJsonFile -Path $OutputPath -Value $staticOutput -Depth 80 -Compress

    $nativeOutput = [pscustomobject][ordered]@{
        SchemaVersion = 'amd-driver-signature-native-verification/1.2'
        ToolkitVersion = $script:AmdChipsetResearchToolkitVersion
        CollectedAtUtc = Get-AmdUtcTimestamp
        EvidenceScope = 'WindowsNative'
        ReleaseSelectionPolicy = $releaseSelectionPolicy
        CandidateReleaseCount = $availableReleases.Count
        AnalyzedReleaseVersions = @($signatureReleases | ForEach-Object { [string]$_.ReleaseVersion })
        ExecutionContext = $runtimeContext
        Tool = [pscustomobject][ordered]@{ Name='signtool.exe'; Status=$signTool.Status; Version=$signTool.Version; FileVersion=$signTool.FileVersion; ProductVersion=$signTool.ProductVersion; Sha256=$signTool.Sha256; SizeBytes=$signTool.SizeBytes; Architecture=$signTool.Architecture; Path=$signTool.Path; PortablePath=$signTool.PortablePath; KitVersion=$signTool.KitVersion }
        ToolchainCapabilityReference = 'inventory/host/toolchain-capabilities-private.json'
        ToolchainCapabilitySummaryReference = 'inventory/toolchain-capabilities.json'
        Releases = @($nativeReleaseResults.ToArray())
        MutationPerformed = $false
    }
    Write-AmdJsonFile -Path $NativeVerificationPath -Value $nativeOutput -Depth 80

    if ($runtimeContext.ExecutionClass -in @('WindowsClient','WindowsServer','WindowsOther')) {
        $windowsHostPosture = Get-AmdWindowsHostSecurityPosture
        Write-AmdJsonFile -Path $WindowsHostPosturePath -Value $windowsHostPosture -Depth 30
        if ($runtimeContext.ExecutionClass -eq 'WindowsServer') {
            $targetServerEvidence = Get-AmdTargetServerHostEvidence -WindowsHostSecurityPosture $windowsHostPosture
            Write-AmdJsonFile -Path $ServerHostPosturePath -Value $targetServerEvidence -Depth 40
        }
    }

    $signedKernelCount = @(
        $releaseResults.ToArray() | ForEach-Object { @($_.Files) } | ForEach-Object { $_ } |
            Where-Object { $_.FileType -eq 'KernelBinary' -and $_.EmbeddedSignatureState -eq 'Present' }
    ).Count
    $kernelCount = @(
        $releaseResults.ToArray() | ForEach-Object { @($_.Files) } | ForEach-Object { $_ } |
            Where-Object { $_.FileType -eq 'KernelBinary' }
    ).Count
    $consoleCoverage = if ($runtimeContext.ExecutionClass -in @('WindowsClient','WindowsServer','WindowsOther')) {
        Get-AmdKernelSignatureCoverageAssessment -NativeData ([pscustomobject][ordered]@{ Releases=@($nativeReleaseResults.ToArray()) })
    }
    else { $null }
    $coverageText = if ($null -ne $consoleCoverage) { ('; catalog-bound kernel coverage={0}/{1}; supplemental unbound /kp nonzero={2} (diagnostic-only)' -f $consoleCoverage.FullyCoveredKernelCount,$consoleCoverage.KernelFileCount,$consoleCoverage.SupplementalUnboundKernelPolicyNonZeroCount) } else { '' }
    Write-AmdOk ('Signature analysis -> release={0}; policy={1}; kernel binaries={2}; embedded-signed kernel binaries={3}; WindowsNative={4}{5}' -f ([string]$signatureReleases[0].ReleaseVersion),$releaseSelectionPolicy,$kernelCount,$signedKernelCount,$runtimeContext.ExecutionClass,$coverageText)
    return $staticOutput
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
    $friendlyNames = @{
        'SETNAIPMF300'   = 'PMF Ryzen AI 300 Series Driver 1'
        'SETTAIPMF300'   = 'PMF Ryzen AI 300 Series Driver 2'
        'SETAIPMFMAX300' = 'PMF Ryzen AI MAX 300 Series Driver'
        'SETUPMF'        = 'PMF Driver'
    }
    if ($friendlyNames.ContainsKey($value)) { return [string]$friendlyNames[$value] }
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
        'SETWIRELESSFILTER' = @('Wireless Filter')
        'SETVIRTUALSTORAGE' = @('Virtual Storage')
        'SETINTERFACE'   = @('Interface Driver')
        'SETOEMPF'       = @('Provisioning for OEM','OEM Provisioning')
        'SETNAIPMF300'   = @('PMF Ryzen AI 300 Series Driver')
        'SETTAIPMF300'   = @('PMF Ryzen AI 300 Series-2')
        'SETAIPMFMAX300' = @('PMF Ryzen AI MAX 300')
        'SETAPPCOMPATDB' = @('Application Compatibility')
        'SETMSFT1'       = @('Pluton Security Processor 1')
        'SETMSFT2'       = @('Pluton Security Processor 2')
        'SETHSMP'        = @('HSMP')
        'SETSFH1.2'      = @('SFH1.2')
        'SETUPMF'        = @('PMF Driver')
        'SETXGBE'        = @('XGBE','10GbE')
        'SETSDXINULL'    = @('SDXI NULL','SDXI Null')
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

function Get-AmdSelectorProductCorrelation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][string]$PropertyName,
        [AllowNull()][object[]]$Products
    )

    $productItems = @($Products)
    $candidates = @(Get-AmdSelectorInfoProductCandidates -PropertyName $PropertyName -Products $productItems)
    $status = if ($candidates.Count -gt 0) {
        'MatchedInfoProduct'
    }
    elseif ($productItems.Count -eq 0) {
        'InfoManifestUnavailable'
    }
    else {
        'NoInfoProductCandidate'
    }
    $note = switch ($status) {
        'MatchedInfoProduct' { 'One or more Info.xml product names/installers match a curated selector alias.' }
        'InfoManifestUnavailable' { 'DevID.xml mapping is retained, but Info.xml product correlation cannot be evaluated because no product manifest is available.' }
        default { 'DevID.xml proves the selector token/device mapping, but Info.xml contains no matching product name/installer. Do not infer an independent driver package from the token alone.' }
    }

    return [pscustomobject][ordered]@{
        Status = $status
        InfoProductCandidates = @($candidates)
        Note = $note
    }
}

function Test-AmdSelectorProductCorrelationSelfTest {
    [CmdletBinding()]
    param()

    $products = @(
        [pscustomobject]@{ Name='AMD AMS Mailbox Driver'; Installer='AMD AMS Mailbox Driver'; OS='Windows 11(64-bit)'; Version='6.0.0.6' },
        [pscustomobject]@{ Name='AMD Wireless Filter Driver'; Installer='AMD Wireless Filter Driver'; OS='Windows 11(64-bit)'; Version='1.0.0.0' },
        [pscustomobject]@{ Name='AMD PMF Ryzen AI 300 Series Driver'; Installer='AMD PMF Ryzen AI 300 Series Driver'; OS='Windows 11(64-bit)'; Version='26.10.15.0' },
        [pscustomobject]@{ Name='AMD PMF Ryzen AI 300 Series-2 Driver'; Installer='AMD PMF Ryzen AI 300 Series-2 Driver'; OS='Windows 11(64-bit)'; Version='26.10.15.0' }
    )
    $matched = Get-AmdSelectorProductCorrelation -PropertyName 'SETWIRELESSFILTER' -Products $products
    $unmatched = Get-AmdSelectorProductCorrelation -PropertyName 'SETVIRTUALSTORAGE' -Products $products
    $unavailable = Get-AmdSelectorProductCorrelation -PropertyName 'SETSDXINULL' -Products @()
    $naiPmf = Get-AmdSelectorProductCorrelation -PropertyName 'SETNAIPMF300' -Products $products
    $taiPmf = Get-AmdSelectorProductCorrelation -PropertyName 'SETTAIPMF300' -Products $products
    $ok = (
        $matched.Status -eq 'MatchedInfoProduct' -and
        @($matched.InfoProductCandidates).Count -eq 1 -and
        $unmatched.Status -eq 'NoInfoProductCandidate' -and
        @($unmatched.InfoProductCandidates).Count -eq 0 -and
        $unavailable.Status -eq 'InfoManifestUnavailable' -and
        @($naiPmf.InfoProductCandidates).Count -eq 1 -and
        [string]$naiPmf.InfoProductCandidates[0].Name -eq 'AMD PMF Ryzen AI 300 Series Driver' -and
        @($taiPmf.InfoProductCandidates).Count -eq 1 -and
        [string]$taiPmf.InfoProductCandidates[0].Name -eq 'AMD PMF Ryzen AI 300 Series-2 Driver'
    )

    return [pscustomobject][ordered]@{
        Status = if ($ok) { 'Pass' } else { 'Fail' }
        MatchedStatus = $matched.Status
        UnmatchedStatus = $unmatched.Status
        ManifestUnavailableStatus = $unavailable.Status
        RyzenAi300Driver1CandidateCount = @($naiPmf.InfoProductCandidates).Count
        RyzenAi300Driver2CandidateCount = @($taiPmf.InfoProductCandidates).Count
    }
}

function Get-AmdCuratedReleaseNoteRecord {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][string]$ReleaseVersion,
        [string]$Path
    )

    if (-not $Path) {
        $Path = Join-Path (Get-AmdResearchToolkitRoot) 'data\curated-release-notes.json'
    }
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return $null }
    $data = Read-AmdJsonFile -Path $Path
    $matches = @($data.Records | Where-Object { [string]$_.ReleaseVersion -eq $ReleaseVersion })
    if ($matches.Count -gt 1) {
        throw ('Curated release-note data contains duplicate release version {0}.' -f $ReleaseVersion)
    }
    if ($matches.Count -eq 0) { return $null }
    return $matches[0]
}

function Get-AmdReleaseNoteOsManifestComparison {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][string]$Expected,
        [Parameter(Mandatory=$true)][ValidateSet('Windows10','Windows11')][string]$OsField,
        [Parameter(Mandatory=$true)][string[]]$InfoProductNames,
        [AllowNull()][object[]]$Products
    )

    $productItems = @($Products)
    $osPattern = if ($OsField -eq 'Windows10') { '^Windows 10(?:\(|$)' } else { '^Windows 11(?:\(|$)' }
    $nameSet = @{}
    foreach ($name in @($InfoProductNames)) {
        if (-not [string]::IsNullOrWhiteSpace([string]$name)) { $nameSet[[string]$name] = $true }
    }
    $candidates = @(
        $productItems | Where-Object {
            $nameSet.ContainsKey([string]$_.Name) -and [string]$_.OS -match $osPattern
        } | ForEach-Object {
            [pscustomobject][ordered]@{
                Name = [string]$_.Name
                OS = [string]$_.OS
                Version = [string]$_.Version
                Installer = [string]$_.Installer
            }
        }
    )

    $notApplicable = $Expected -eq 'Not Applicable'
    $status = if ($productItems.Count -eq 0) {
        'InfoManifestUnavailable'
    }
    elseif ($notApplicable -and $candidates.Count -gt 0) {
        'ManifestProductPresentWhileReleaseNotesNotApplicable'
    }
    elseif ($notApplicable) {
        'NotApplicableNoManifestProduct'
    }
    elseif ($candidates.Count -eq 0) {
        'ExpectedReleaseNoteProductMissingFromManifest'
    }
    elseif (@($candidates | Where-Object { [string]$_.Version -eq $Expected }).Count -gt 0) {
        'VersionMatched'
    }
    else {
        'VersionMismatch'
    }

    return [pscustomobject][ordered]@{
        OsField = $OsField
        ExpectedReleaseNoteValue = $Expected
        Status = $status
        MatchedInfoProducts = @($candidates)
        PublicSupportApplicable = (-not $notApplicable)
        Interpretation = switch ($status) {
            'VersionMatched' { 'The public package version and an exact-name Info.xml product version agree for this operating system.' }
            'VersionMismatch' { 'The public package version and exact-name Info.xml product version differ. Preserve both sources; do not silently normalize either value.' }
            'ExpectedReleaseNoteProductMissingFromManifest' { 'The public release note lists a package version, but no exact-name Info.xml product is present for this operating system.' }
            'ManifestProductPresentWhileReleaseNotesNotApplicable' { 'An internal Info.xml product exists although the public release note marks this operating system Not Applicable. The internal row does not override the public support boundary.' }
            'NotApplicableNoManifestProduct' { 'The public release note marks this operating system Not Applicable and no exact-name Info.xml product was observed.' }
            default { 'Info.xml product correlation is unavailable.' }
        }
    }
}

function Get-AmdReleaseNoteManifestCorrelation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][string]$ReleaseVersion,
        [AllowNull()][object[]]$Products,
        [string]$CuratedDataPath
    )

    $record = Get-AmdCuratedReleaseNoteRecord -ReleaseVersion $ReleaseVersion -Path $CuratedDataPath
    if ($null -eq $record) {
        return [pscustomobject][ordered]@{
            Status = 'NotCurated'
            ReleaseVersion = $ReleaseVersion
            PackageComparisons = @()
            Summary = [pscustomobject][ordered]@{ ComparisonCount=0; StatusCounts=[pscustomobject]@{} }
            InterpretationBoundaries = @()
            WindowsServerSupportProven = $false
            NpuDriverPackageSelectionAuthority = $false
        }
    }

    $comparisons = New-Object 'System.Collections.Generic.List[object]'
    foreach ($package in @($record.PackageContents)) {
        $windows10 = Get-AmdReleaseNoteOsManifestComparison -Expected ([string]$package.Windows10) -OsField 'Windows10' -InfoProductNames @($package.InfoProductNames) -Products @($Products)
        $windows11 = Get-AmdReleaseNoteOsManifestComparison -Expected ([string]$package.Windows11) -OsField 'Windows11' -InfoProductNames @($package.InfoProductNames) -Products @($Products)
        $comparisons.Add([pscustomobject][ordered]@{
            PackageName = [string]$package.Name
            InfoProductNames = @($package.InfoProductNames)
            ChangeDetails = [string]$package.ChangeDetails
            Windows10 = $windows10
            Windows11 = $windows11
        })
    }

    $allOsComparisons = @($comparisons.ToArray() | ForEach-Object { $_.Windows10; $_.Windows11 })
    $statusCounts = [ordered]@{}
    foreach ($group in @($allOsComparisons | Group-Object Status | Sort-Object Name)) {
        $statusCounts[[string]$group.Name] = [int]$group.Count
    }
    $productItems = @($Products)
    return [pscustomobject][ordered]@{
        Status = if ($productItems.Count -eq 0) { 'InfoManifestUnavailable' } else { 'Correlated' }
        ReleaseVersion = $ReleaseVersion
        ArticleNumber = [string]$record.ArticleNumber
        Source = $record.Source
        ReleaseHighlights = @($record.ReleaseHighlights)
        KnownIssues = @($record.KnownIssues)
        ChipsetSupport = @($record.ChipsetSupport)
        ProcessorSupport = @($record.ProcessorSupport)
        PackageComparisons = @($comparisons.ToArray())
        Summary = [pscustomobject][ordered]@{
            PackageCount = @($record.PackageContents).Count
            ComparisonCount = $allOsComparisons.Count
            StatusCounts = [pscustomobject]$statusCounts
        }
        InterpretationBoundaries = @($record.InterpretationBoundaries)
        WindowsServerSupportProven = $false
        NpuDriverPackageSelectionAuthority = $false
    }
}

function Test-AmdCuratedReleaseNoteCorrelationSelfTest {
    [CmdletBinding()]
    param()

    $issues = New-Object 'System.Collections.Generic.List[string]'
    $record = Get-AmdCuratedReleaseNoteRecord -ReleaseVersion '8.08.12.551'
    if ($null -eq $record) {
        $issues.Add('Curated 8.08.12.551 release-note record is missing.')
        return [pscustomobject][ordered]@{ Status='Fail'; Issues=@($issues.ToArray()) }
    }
    if (@($record.ChipsetSupport).Count -ne 17) { $issues.Add('Expected 17 chipset-support rows.') }
    if (@($record.ProcessorSupport).Count -ne 21) { $issues.Add('Expected 21 processor-support rows.') }
    if (@($record.PackageContents).Count -ne 37) { $issues.Add('Expected 37 package-content rows.') }

    $products = @(
        [pscustomobject]@{ Name='AMD S0i3 Filter Driver'; Installer='AMD S0i3 Filter Driver'; OS='Windows 10(64-bit)'; Version='1.1.0.12' },
        [pscustomobject]@{ Name='AMD S0i3 Filter Driver'; Installer='AMD S0i3 Filter Driver'; OS='Windows 11(64-bit)'; Version='1.1.0.12' },
        [pscustomobject]@{ Name='AMD IOV Driver'; Installer='NULL Driver for AMD IOMMU Devices'; OS='Windows 11(64-bit)'; Version='1.2.0.52' },
        [pscustomobject]@{ Name='AMD PMF Ryzen AI 300 Series Driver'; Installer='AMD PMF Ryzen AI 300 Series Driver'; OS='Windows 11(64-bit)'; Version='26.10.15.0' },
        [pscustomobject]@{ Name='AMD PMF Ryzen AI 300 Series-2 Driver'; Installer='AMD PMF Ryzen AI 300 Series-2 Driver'; OS='Windows 11(64-bit)'; Version='26.10.15.0' }
    )
    $correlation = Get-AmdReleaseNoteManifestCorrelation -ReleaseVersion '8.08.12.551' -Products $products
    $s0i3 = @($correlation.PackageComparisons | Where-Object { [string]$_.PackageName -eq 'AMD S0i3 Filter Driver' })
    $iov = @($correlation.PackageComparisons | Where-Object { [string]$_.PackageName -eq 'AMD IOV Driver' })
    $pmf1 = @($correlation.PackageComparisons | Where-Object { [string]$_.PackageName -eq 'AMD PMF Ryzen AI 300 Series Driver 1' })
    $pmf2 = @($correlation.PackageComparisons | Where-Object { [string]$_.PackageName -eq 'AMD PMF Ryzen AI 300 Series Driver 2' })
    if ($s0i3.Count -ne 1 -or [string]$s0i3[0].Windows11.Status -ne 'VersionMismatch') { $issues.Add('S0i3 public/internal version mismatch was not preserved.') }
    if ($iov.Count -ne 1 -or [string]$iov[0].Windows11.Status -ne 'ManifestProductPresentWhileReleaseNotesNotApplicable') { $issues.Add('IOV Windows 11 public-support boundary was not preserved.') }
    if ($pmf1.Count -ne 1 -or [string]$pmf1[0].Windows11.Status -ne 'VersionMatched') { $issues.Add('Ryzen AI 300 PMF Driver 1 exact correlation failed.') }
    if ($pmf2.Count -ne 1 -or [string]$pmf2[0].Windows11.Status -ne 'VersionMatched') { $issues.Add('Ryzen AI 300 PMF Driver 2 exact correlation failed.') }
    if ($correlation.WindowsServerSupportProven -or $correlation.NpuDriverPackageSelectionAuthority) { $issues.Add('Release-note scope boundary flags must remain false.') }

    return [pscustomobject][ordered]@{
        Status = if ($issues.Count -eq 0) { 'Pass' } else { 'Fail' }
        ChipsetSupportRowCount = @($record.ChipsetSupport).Count
        ProcessorSupportRowCount = @($record.ProcessorSupport).Count
        PackageContentRowCount = @($record.PackageContents).Count
        S0i3Windows11Status = if ($s0i3.Count -eq 1) { [string]$s0i3[0].Windows11.Status } else { $null }
        IovWindows11Status = if ($iov.Count -eq 1) { [string]$iov[0].Windows11.Status } else { $null }
        RyzenAi300Driver1Status = if ($pmf1.Count -eq 1) { [string]$pmf1[0].Windows11.Status } else { $null }
        RyzenAi300Driver2Status = if ($pmf2.Count -eq 1) { [string]$pmf2[0].Windows11.Status } else { $null }
        Issues = @($issues.ToArray())
    }
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
            $productCorrelation = Get-AmdSelectorProductCorrelation -PropertyName $property -Products $products
            $rules.Add([pscustomobject][ordered]@{
                RuleKind = 'DevIdXmlMapping'
                EvidenceLevel = 'AmdDeclarativeProven'
                Tag = [string]$mapping.Tag
                PropertyName = $property
                FeatureName = Get-AmdSelectorFeatureName -PropertyName $property
                DeviceIds = @($mapping.DeviceIds)
                RawDeviceIds = [string]$mapping.RawDeviceIds
                ProductCorrelationStatus = [string]$productCorrelation.Status
                ProductCorrelationNote = [string]$productCorrelation.Note
                InfoProductCandidates = @($productCorrelation.InfoProductCandidates)
            })
        }
        $msiPath = Get-AmdRecoveredTopLevelMsiPath -ExtractionRelease $release
        $msiAnalysis = Invoke-AmdMsiDeclarativeAnalysis -MsiPath $msiPath
        $binaryEvidence = Get-AmdSelectorBinaryEvidence -ExtractionRelease $release
        $xmlContract = Get-AmdEmbeddedXmlContract -Products $products
        $releaseNoteCorrelation = Get-AmdReleaseNoteManifestCorrelation -ReleaseVersion $version -Products $products
        $manifestEvidence = if ($meta.Count -gt 0) { [pscustomobject][ordered]@{ PreferredInfoXmlPath=[string]$meta[0].PreferredInfoXmlPath; PreferredApsXmlPath=if($null -ne $meta[0].PSObject.Properties['PreferredApsXmlPath']){[string]$meta[0].PreferredApsXmlPath}else{$null}; ApsXmlCount=if($null -ne $meta[0].PSObject.Properties['ApsXmlCount']){[int]$meta[0].ApsXmlCount}else{0}; ApsIdenticalToPreferredInfoXmlCount=if($null -ne $meta[0].PSObject.Properties['ApsIdenticalToPreferredInfoXmlCount']){[int]$meta[0].ApsIdenticalToPreferredInfoXmlCount}else{0}; PreferredDevIdXmlPath=[string]$meta[0].PreferredDevIdXmlPath } } else { $null }
        $records.Add([pscustomobject][ordered]@{
            ReleaseVersion = $version
            DevIdRuleCount = $rules.Count
            DevIdRules = @($rules.ToArray())
            EmbeddedXmlContract = $xmlContract
            ManifestEvidence = $manifestEvidence
            SelectorBinaryEvidence = $binaryEvidence
            MsiDeclarativeAnalysis = $msiAnalysis
            ReleaseNoteCorrelation = $releaseNoteCorrelation
            Notes = @(
                'DevID.xml mappings are AMD declarative selector evidence, but a matching token alone does not prove the component survives later CPU/OS/manifest/custom-action filters.',
                'ProductCorrelationStatus makes an unmatched DevID.xml token explicit. NoInfoProductCandidate is unresolved selector evidence, not proof of a missing payload or an independent driver package.',
                'MSI table inspection is read-only and never invokes MSI installation. On non-Windows platforms the Windows Installer COM portion is recorded as unavailable rather than treated as success.',
                'APS_*.xml payloads are preserved and SHA-compared with preferred Info.xml. Byte identity is evidence that the same component manifest is carried into the second-stage MSI payload; it does not prove the selector predicate.',
                'Qt Setup.exe static string evidence is recorded separately from declarative XML and dynamic observation.',
                'Release-note package versions and Info.xml product versions are kept as separate evidence. An internal product row does not override a public Not Applicable support boundary.',
                'Release-note processor support is chipset-package scope only; it is neither Windows Server support proof nor NPU driver-package selection authority.'
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


function ConvertTo-AmdPortableEmbeddedRuntimePathText {
    [CmdletBinding()]
    param(
        [AllowNull()][string]$Text
    )

    if ([string]::IsNullOrWhiteSpace($Text)) { return $Text }

    $result = [string]$Text
    $toolRoot = [string](Get-AmdResearchToolkitRoot)
    if (-not [string]::IsNullOrWhiteSpace($toolRoot)) {
        $rootVariants = @(
            $toolRoot.TrimEnd('\','/'),
            $toolRoot.Replace('\','/').TrimEnd('/')
        ) | Select-Object -Unique
        foreach ($rootVariant in $rootVariants) {
            if ([string]::IsNullOrWhiteSpace($rootVariant)) { continue }
            $escapedRoot = [regex]::Escape($rootVariant)
            $result = [regex]::Replace(
                $result,
                ('(?i){0}[\\/]+private[\\/]+evidence[\\/]+([^|;\r\n]+)' -f $escapedRoot),
                {
                    param($m)
                    $relative = ([string]$m.Groups[1].Value).Replace('\','/').Trim()
                    return ('evidence-artifact/{0}' -f $relative)
                }
            )
            $result = [regex]::Replace(
                $result,
                ('(?i){0}[\\/]+evidence[\\/]+([^|;\r\n]+)' -f $escapedRoot),
                {
                    param($m)
                    $relative = ([string]$m.Groups[1].Value).Replace('\','/').Trim()
                    return ('evidence-artifact/{0}' -f $relative)
                }
            )
            $result = [regex]::Replace(
                $result,
                ('(?i){0}[\\/]+work[\\/]+([^|;\r\n]+)' -f $escapedRoot),
                {
                    param($m)
                    $relative = ([string]$m.Groups[1].Value).Replace('\','/').Trim()
                    return ('work-artifact/{0}' -f $relative)
                }
            )
            $result = [regex]::Replace(
                $result,
                ('(?i){0}[\\/]+inventory[\\/]+([^|;\r\n]+)' -f $escapedRoot),
                {
                    param($m)
                    $relative = ([string]$m.Groups[1].Value).Replace('\','/').Trim()
                    return ('inventory-artifact/{0}' -f $relative)
                }
            )
            $result = [regex]::Replace(
                $result,
                ('(?i){0}[\\/]+reports[\\/]+([^|;\r\n]+)' -f $escapedRoot),
                {
                    param($m)
                    $relative = ([string]$m.Groups[1].Value).Replace('\','/').Trim()
                    return ('report-artifact/{0}' -f $relative)
                }
            )
            # Last-resort protection for any other embedded tool-root path. Keep only
            # a repository-neutral marker plus the leaf name rather than publishing
            # the execution host's absolute path.
            $result = [regex]::Replace(
                $result,
                ('(?i){0}[\\/]+([^|;\r\n]+)' -f $escapedRoot),
                {
                    param($m)
                    $candidate = ([string]$m.Groups[1].Value).Replace('\','/').Trim()
                    $leaf = [System.IO.Path]::GetFileName($candidate)
                    if ([string]::IsNullOrWhiteSpace($leaf)) { $leaf = 'runtime-path' }
                    return ('host-path-redacted/{0}' -f $leaf)
                }
            )
        }
    }

    return $result
}

function Test-AmdPortableFreeTextProperty {
    [CmdletBinding()]
    param([AllowNull()][string]$PropertyName)

    if ([string]::IsNullOrWhiteSpace($PropertyName)) { return $false }
    return ($PropertyName -in @(
        'Error','ErrorMessage','Detail','Reason','Message','Note','Notes','Warning','Warnings'
    ))
}

function Test-AmdPortableAnalysisPathProperty {
    [CmdletBinding()]
    param([AllowNull()][string]$PropertyName)

    if ([string]::IsNullOrWhiteSpace($PropertyName)) { return $false }
    if ($PropertyName -eq 'Path') { return $true }
    return (Test-AmdPublicPathPropertyName -PropertyName $PropertyName)
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
        if (Test-AmdPortableFreeTextProperty -PropertyName $PropertyName) {
            return ConvertTo-AmdPortableEmbeddedRuntimePathText -Text ([string]$Value)
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
        SignatureAnalysis = ConvertTo-AmdPortableAnalysisValue -Value $(if ($null -ne $Release.PSObject.Properties['SignatureAnalysis']) { $Release.SignatureAnalysis } else { $null }) -ExtractionRoot $extractionRoot -InstallerPath $installerPath -ReleaseVersion $releaseVersion
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
    $archivePath = ConvertTo-AmdPortableAnalysisValue -Value 'D:\Research\work\extracted\8.07.16.1035\d3_Data1.cab_deadbeef\Data1.cab' -ExtractionRoot $root -InstallerPath $installer -ReleaseVersion $release -PropertyName 'ArchivePath'
    $externalPath = ConvertTo-AmdPortableAnalysisValue -Value 'D:\VendorCache\Data1.cab' -ExtractionRoot $root -InstallerPath $installer -ReleaseVersion $release -PropertyName 'ContainerPath'
    $savedRoot = $script:AmdChipsetResearchToolkitRoot
    try {
        $script:AmdChipsetResearchToolkitRoot = 'D:\Research'
        $embeddedError = ConvertTo-AmdPortableAnalysisValue -Value 'download failed; diagnostic=D:\Research\private\evidence\download-diagnostics\invalid.exe | HTTP 404' -ExtractionRoot $root -InstallerPath $installer -ReleaseVersion $release -PropertyName 'Error'
    }
    finally {
        $script:AmdChipsetResearchToolkitRoot = $savedRoot
    }

    $ok = (
        $token -eq '/SETFILTERUSB' -and
        $manifestToken -eq '/info.xml' -and
        $msiValue -eq 'C:\' -and
        $infPath -eq 'work/extracted/8.07.16.1035/d3_Data1.cab_deadbeef/amdtest.inf' -and
        $archivePath -eq 'work/extracted/8.07.16.1035/d3_Data1.cab_deadbeef/Data1.cab' -and
        $externalPath -eq 'external-path/Data1.cab' -and
        $embeddedError -eq 'download failed; diagnostic=evidence-artifact/download-diagnostics/invalid.exe| HTTP 404'
    )

    return [pscustomobject][ordered]@{
        Status = if ($ok) { 'Pass' } else { 'Fail' }
        SelectorToken = $token
        ManifestToken = $manifestToken
        MsiPropertyValue = $msiValue
        PortableInfPath = $infPath
        PortableArchivePath = $archivePath
        ExternalFilesystemPath = $externalPath
        PortableEmbeddedError = $embeddedError
    }
}

function Clear-AmdRunScopedBuildOutputs {
    [CmdletBinding()]
    param()

    $root = Get-AmdResearchToolkitRoot
    foreach ($path in @(
        (Join-Path (Join-Path $root 'inventory') 'releases'),
        (Join-Path (Join-Path $root 'reports') 'releases')
    )) {
        if (Test-Path -LiteralPath $path -PathType Container) {
            Remove-Item -LiteralPath $path -Recurse -Force -ErrorAction Stop
        }
        New-AmdDirectory -Path $path | Out-Null
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
        [string]$SignatureAnalysisPath,
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
    Clear-AmdRunScopedBuildOutputs

    if (-not $ReleasesPath) { $ReleasesPath = Join-Path $toolRoot 'inventory\releases.json' }
    if (-not $MetadataPath) { $MetadataPath = Join-Path $toolRoot 'inventory\release-metadata.json' }
    if (-not $AcquisitionPath) { $AcquisitionPath = Join-Path $toolRoot 'inventory\acquisition.json' }
    if (-not $ExtractionPath) { $ExtractionPath = Join-Path $toolRoot 'inventory\extraction.json' }
    if (-not $DriverPackagesPath) { $DriverPackagesPath = Join-Path $toolRoot 'inventory\driver-packages.json' }
    if (-not $SignatureAnalysisPath) { $SignatureAnalysisPath = Join-Path $toolRoot 'inventory\signature-analysis.json' }
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
    $signatureData = Read-OptionalJson -Path $SignatureAnalysisPath
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
    if ($signatureData) {
        foreach ($r in @($signatureData.Releases)) {
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
        $signatureRecord = $null
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
        if ($signatureData) {
            $tmp = @($signatureData.Releases | Where-Object { $_.ReleaseVersion -eq $version } | Select-Object -First 1)
            if ($tmp.Count -gt 0) { $signatureRecord = $tmp[0] }
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
            SignatureAnalysis = $signatureRecord
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
        StaticSignatureAnalysisIncluded = ($null -ne $signatureData)
        HostAnalysisIncluded = ($null -ne $hostAnalysisData -and [string]$hostAnalysisData.Status -eq 'Analyzed')
        HostAnalysisReference = if ($null -ne $hostAnalysisData) { [pscustomobject]@{ Status=$hostAnalysisData.Status; Path='inventory/host/amd-chipset-host-analysis.json' } } else { $null }
        WindowsServerProfiles = @(Get-AmdWindowsServerProfiles)
        ResearchEnvironment = $environmentData
        ToolchainCapabilities = if ($environmentData -and $environmentData.Dependencies) { $environmentData.Dependencies.WindowsDriverToolchain } else { $null }
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
                SignatureBoundary = 'Canonical per-release JSON contains host-neutral static cryptographic evidence only. Windows native SignTool output and target-server host security posture remain private runtime evidence.'
            }
            Release = [pscustomobject][ordered]@{
                Version = $portableRelease.Version
                Discovery = $portableRelease.Discovery
                Metadata = $portableRelease.Metadata
                Acquisition = $portableRelease.Acquisition
                Extraction = $portableRelease.Extraction
                EmbeddedInstallerMetadata = $portableRelease.EmbeddedInstallerMetadata
                AmdSelectorStatic = $portableRelease.AmdSelectorStatic
                SignatureAnalysis = $portableRelease.SignatureAnalysis
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

    $allowed = @('PathSafety', 'Test', 'Discover', 'Metadata', 'Acquire', 'Extract', 'Inspect', 'Signature', 'Selector', 'HostSurvey', 'HostMatch', 'Build', 'All')
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
        $full = @('PathSafety', 'Test', 'Discover', 'Metadata', 'Acquire', 'Extract', 'Inspect', 'Signature', 'Selector')
        $platform = Get-AmdPlatformInfo
        if (-not $script:SkipHostAnalysis -and ($platform.PlatformFamily -eq 'Windows' -or $script:ObservedAmdDeviceIdLog)) {
            $full += @('HostSurvey','HostMatch')
        }
        $full += 'Build'
        return @($full)
    }

    return @('PathSafety')+@($normalized|Where-Object{$_ -ne 'PathSafety'})
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
    EvidenceRetention = $EvidenceRetention
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
    Write-Host '=== AMD Chipset Driver Research Toolkit — BOOTSTRAP ===' -ForegroundColor Cyan
    Write-Host ('Toolkit    : {0}' -f $script:AmdChipsetResearchToolkitVersion)
    Write-Host ('PowerShell : {0}' -f $PSVersionTable.PSVersion)
    Write-Host ('Requested  : {0}' -f (@($Stages) -join ', '))
    $resolvedStages = @(Resolve-AmdRequestedStages -RequestedStages $Stages)
    $startupPathAssessment=Get-AmdPathSafetyAssessment -SevenZipPath $SevenZipPath -ResolvedStages $resolvedStages
    if([string]$startupPathAssessment.Status -eq 'Blocked'){
        Write-Host '=== AMD Chipset Driver Research Toolkit — PATH SAFETY BLOCK ===' -ForegroundColor Red
        foreach($issue in @($startupPathAssessment.Issues)){Write-Host ('BLOCK: {0}' -f [string]$issue) -ForegroundColor Red}
        Write-Host ('Move whole tool : {0}' -f [string]$startupPathAssessment.RecommendedToolRoot) -ForegroundColor Yellow
        Write-Host 'No AMD network request was started.' -ForegroundColor Yellow
        throw('PathSafety BLOCKED: {0}' -f (@($startupPathAssessment.Issues)-join ' | '))
    }
    Write-Host 'Initializing tool-local evidence session and Canonical JSON runtime...' -ForegroundColor Cyan

    $null = Start-AmdResearchEvidenceSession `
        -OutputRoot $EvidenceOutputRoot `
        -Label $EvidenceLabel `
        -EvidenceRetention $EvidenceRetention `
        -InvocationParameters $invocationEvidence

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
        Write-Host ('Evidence ZIP planned : {0}' -f $script:AmdEvidenceContext.ZipPath)
        Write-Host ('Evidence work dir    : {0}' -f $script:AmdEvidenceContext.EvidenceDirectory)
    }
    Write-Host ('Public     : {0}' -f $(if($SkipPublicExport){'SKIPPED'}else{Get-AmdPublicOutputRoot}))
    Write-Host ''

    $nonTestStages = @($resolvedStages | Where-Object { $_ -notin @('PathSafety','Test') })
    if ($nonTestStages.Count -eq 0) {
        Write-Host '[BOOTSTRAP] Runtime baseline restore skipped: Test-only execution does not consume the research baseline.' -ForegroundColor Green
    }
    else {
        $driverPackageConsumers = @('Signature','Selector','HostMatch','Build')
        $requiresDriverPackages = (
            @($resolvedStages | Where-Object { $driverPackageConsumers -contains $_ }).Count -gt 0 -and
            $resolvedStages -notcontains 'Inspect'
        )
        Restore-AmdRuntimeBaselineFromPublic -IncludeDriverPackages:$requiresDriverPackages
    }
    Write-Host ''

    foreach ($stage in $resolvedStages) {
        $blockedReason = Get-AmdStageDependencyBlockReason -Name $stage -ResolvedStages $resolvedStages
        switch ($stage) {
            'PathSafety' {
                $null=Invoke-AmdTrackedStage -Name 'PathSafety' -Body {
                    Write-AmdOk ('Path safety passed: root length={0}/{1}; predicted maximum={2}/{3}.' -f $startupPathAssessment.ToolRootLength,$startupPathAssessment.Policy.MaximumToolRootLength,$startupPathAssessment.PredictedPaths.MaximumDesignedExtractionPathLength,$startupPathAssessment.Policy.SafeFullPathLimit)
                    $startupPathAssessment
                }
            }

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
                        -AdditionalReleaseNotesUrl $AdditionalReleaseNotesUrl `
                        -RequestedReleaseVersion $ReleaseVersion
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

            'Signature' {
                $null = Invoke-AmdTrackedStage -Name 'Signature' -BlockedReason $blockedReason -Body {
                    Invoke-AmdSignatureStage
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
    if ($null -eq $script:AmdEvidenceContext -and ($null -eq $script:AmdPathSafetyAssessment -or [string]$script:AmdPathSafetyAssessment.Status -ne 'Blocked')) {
        try {
            $null=Start-AmdEmergencyEvidenceSession -PreferredOutputRoot $EvidenceOutputRoot -Label $EvidenceLabel -EvidenceRetention $EvidenceRetention -InvocationParameters $invocationEvidence -BootstrapError $script:AmdTopLevelFatalError
        }
        catch { Write-Warning ('Bootstrap evidence recovery could not start: {0}' -f $_.Exception.Message) }
    }
    Write-AmdDiagnosticEvent -EventName 'FatalRunnerError' -Level 'Error' -FunctionName 'TopLevelRunner' -Step 'Catch' -Data @{ ErrorRecord=(Get-AmdExceptionDiagnostic -ErrorRecord $_) }
    [void](Write-AmdFailureSnapshot -Scope 'fatal-runner' -ErrorRecord $_ -AdditionalData @{ ResolvedStages=@($resolvedStages) })
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
