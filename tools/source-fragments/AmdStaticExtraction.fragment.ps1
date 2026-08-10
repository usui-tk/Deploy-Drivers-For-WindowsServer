# psa-disable-file PSAP0002 -- source fragment, not a pipeline script: it
# declares no ScriptVersion / ScriptHash / ScriptShortTag because it ships no
# standalone runtime identity; the consuming deployment script carries the
# identity.
#
# AmdStaticExtraction.fragment.ps1 - canonical source of the static
# extraction shadow block (wave W12 of the audit remediation).
#
# Contract:
#   * This file is the single source of truth for the marker-delimited
#     payload below. The AMD chipset deployment script embeds the payload
#     verbatim - byte-identical, markers included - and the suite identity
#     gate (Test-ExtractionGraphCompleteness.ps1) pins the equality.
#   * To change the block: edit HERE, re-embed into every consumer, and let
#     the identity gate prove the copies. Never edit an embedded copy alone.
#   * The research toolkit under tools/amd-chipset-driver-research/ is a
#     separate, manifest-preserved artifact: agreement between this fragment
#     and the research decoder is reported (namespace-normalized), never
#     enforced, and the research files are never edited from here.
#   * Third-party attribution: the C# decoder is informed by the MIT-licensed
#     ISx project (lifenjoiner/ISx). See THIRD-PARTY-NOTICES.md at the
#     repository root.

# ===== BEGIN SOURCE-FRAGMENT amd-static-extraction v1 =====
function Initialize-AmdStaticExtractionDecoder {
    [CmdletBinding()]
    [OutputType([void])]
    param()

    if ('AmdStaticExtraction.IsSetupStreamReader' -as [type]) {
        return
    }

    # The ISSetupStream format parser below is an in-script implementation
    # informed by the MIT-licensed ISx project by lifenjoiner:
    # https://github.com/lifenjoiner/ISx
    # See THIRD-PARTY-NOTICES.md at the repository root for attribution and
    # license text.
    $source = @'
using System;
using System.Collections.Generic;
using System.IO;
using System.IO.Compression;
using System.Security.Cryptography;
using System.Text;

namespace AmdStaticExtraction
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

function Get-AmdStaticIsSetupStreamProbe {
    [CmdletBinding()]
    [OutputType([object])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    Initialize-AmdStaticExtractionDecoder
    return [AmdStaticExtraction.IsSetupStreamReader]::Probe((Resolve-Path -LiteralPath $Path).Path)
}

function Expand-AmdStaticIsSetupStream {
    [CmdletBinding()]
    [OutputType([object])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [string]$Destination
    )

    Initialize-AmdStaticExtractionDecoder
    if (-not (Test-Path -LiteralPath $Destination -PathType Container)) {
        New-Item -ItemType Directory -Path $Destination -Force | Out-Null
    }

    $result = [AmdStaticExtraction.IsSetupStreamReader]::Extract(
        (Resolve-Path -LiteralPath $Path).Path,
        (Resolve-Path -LiteralPath $Destination).Path
    )

    if (-not $result.Success) {
        throw ('ISSetupStream extraction failed for {0}: {1}' -f $Path, $result.Error)
    }

    return $result
}
function Invoke-AmdStaticExtractionShadow {
    <#
    .SYNOPSIS
        Static (non-executing) extraction of an AMD installer into an
        isolated shadow tree, returning an extraction-graph object.
    .DESCRIPTION
        Adaptation of the research toolkit's queue-based bounded recursive
        extraction: SHA-256 dedup, MaxDepth bound, ISSetupStream probe-first
        EXE routing with 7-Zip fallback, MSI OLE/CFBF magic validation, and
        per-container records in the audit-mandated field shape. Evidence
        only: it never launches the installer, never mutates anything
        outside -DestinationRoot, and no deployment decision reads the
        result. The caller fills ToolIdentity and
        ParityNote.CurrentTreeInfCount on the returned object.
    #>
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$InstallerPath,

        [Parameter(Mandatory = $true)]
        [string]$DestinationRoot,

        [Parameter(Mandatory = $true)]
        [string]$SevenZipPath,

        [int]$MaxDepth = 5
    )

    if ($MaxDepth -lt 0 -or $MaxDepth -gt 10) {
        throw 'MaxDepth must be between 0 and 10.'
    }
    if (-not (Test-Path -LiteralPath $InstallerPath -PathType Leaf)) {
        throw ('Installer path does not exist: {0}' -f $InstallerPath)
    }
    if (-not (Test-Path -LiteralPath $DestinationRoot -PathType Container)) {
        New-Item -ItemType Directory -Path $DestinationRoot -Force | Out-Null
    }

    $destRootFull = (Resolve-Path -LiteralPath $DestinationRoot).Path
    $sourceFull   = (Resolve-Path -LiteralPath $InstallerPath).Path
    $sourceSha    = (Get-FileHash -LiteralPath $sourceFull -Algorithm SHA256).Hash.ToLowerInvariant()

    $containers = New-Object System.Collections.Generic.List[object]
    $queue      = New-Object System.Collections.Queue
    $seenHashes = @{}
    $hadError   = $false

    $queue.Enqueue([pscustomobject]@{
        Path         = $sourceFull
        Depth        = 0
        ParentSha256 = $null
    })

    while ($queue.Count -gt 0) {
        $entry = $queue.Dequeue()
        $containerPath = [string]$entry.Path
        $depth = [int]$entry.Depth

        if ($depth -gt $MaxDepth) {
            continue
        }

        $containerSha = $null
        try {
            $containerSha = (Get-FileHash -LiteralPath $containerPath -Algorithm SHA256).Hash.ToLowerInvariant()
        }
        catch {
            $hadError = $true
            $containers.Add([pscustomobject][ordered]@{
                SourceArtifactSha256  = $sourceSha
                ContainerSha256       = $null
                ParentContainerSha256 = $entry.ParentSha256
                RelativePath          = [System.IO.Path]::GetFileName($containerPath)
                Depth                 = $depth
                Extractor             = $null
                Status                = 'ExtractionFailed'
                ExitCode              = $null
                Error                 = ('Hash failed: {0}' -f $_.Exception.Message)
                OutputRoot            = $null
                ProducedFiles         = 0
                ProducedContainers    = 0
                ProducedInfs          = 0
            })
            continue
        }

        if ($seenHashes.ContainsKey($containerSha)) {
            continue
        }
        $seenHashes[$containerSha] = $true

        $safeLeaf = ([System.IO.Path]::GetFileName($containerPath) -replace '[^A-Za-z0-9._-]', '_')
        $out = Join-Path $destRootFull ('d{0}_{1}_{2}' -f $depth, $safeLeaf, $containerSha.Substring(0, 12))
        if (-not (Test-Path -LiteralPath $out -PathType Container)) {
            New-Item -ItemType Directory -Path $out -Force | Out-Null
        }

        $status = 'Extracted'
        $extractor = '7-Zip'
        $exitCode = $null
        $errorText = $null

        $probe = $null
        if ([System.IO.Path]::GetExtension($containerPath) -ieq '.exe') {
            try {
                $probe = Get-AmdStaticIsSetupStreamProbe -Path $containerPath
            }
            catch {
                $probe = $null
            }
        }

        if ($probe -and $probe.IsSetupStream) {
            $extractor = 'ISSetupStream'
            try {
                $isResult = Expand-AmdStaticIsSetupStream -Path $containerPath -Destination $out
                $msiFailures = @(
                    @($isResult.Entries) | Where-Object {
                        $_.FileName -match '(?i)\.msi$' -and -not $_.MsiMagicValid
                    }
                )
                if ($msiFailures.Count -gt 0) {
                    $status = 'ExtractionFailed'
                    $errorText = ('Recovered MSI failed OLE/CFBF magic validation: {0}' -f `
                        (@($msiFailures | ForEach-Object { [string]$_.FileName }) -join ', '))
                    $hadError = $true
                }
            }
            catch {
                $status = 'ExtractionFailed'
                $errorText = $_.Exception.Message
                $hadError = $true
            }
        }
        else {
            try {
                $null = & $SevenZipPath 'x' '-y' ('-o{0}' -f $out) $containerPath 2>&1
                $exitCode = $LASTEXITCODE
                if ($exitCode -eq 1) {
                    $status = 'ExtractedWithWarnings'
                }
                elseif ($exitCode -ne 0) {
                    $status = 'ExtractionFailed'
                    $errorText = ('7-Zip exit code {0}' -f $exitCode)
                    $hadError = $true
                }
            }
            catch {
                $status = 'ExtractionFailed'
                $errorText = $_.Exception.Message
                $hadError = $true
            }
        }

        $relPath = if ($containerPath.StartsWith($destRootFull, [System.StringComparison]::OrdinalIgnoreCase)) {
            $containerPath.Substring($destRootFull.Length).TrimStart('\', '/')
        }
        else {
            [System.IO.Path]::GetFileName($containerPath)
        }

        $producedFiles = 0
        $producedInfs = 0
        $nested = @()
        if ($status -ne 'ExtractionFailed') {
            $outFiles = @(Get-ChildItem -LiteralPath $out -File -Recurse -ErrorAction SilentlyContinue)
            $producedFiles = $outFiles.Count
            $producedInfs = @($outFiles | Where-Object { $_.Name -match '(?i)\.inf\d*$' }).Count

            if ($depth -lt $MaxDepth) {
                $nested = @(
                    $outFiles | Where-Object {
                        $ext = $_.Extension.ToLowerInvariant()
                        if ($ext -in @('.msi', '.cab', '.zip', '.7z')) {
                            return $true
                        }
                        if ($ext -eq '.exe') {
                            # AMD historical ZIP releases wrap the outer AMD
                            # installer EXE inside a ZIP. Follow known AMD
                            # installer names even when the EXE itself is NSIS
                            # rather than ISSetupStream.
                            if ($_.Name -match '(?i)^amd_(?:chipset_software|software).*\.exe$' -or
                                $_.Name -ieq 'AMD_Chipset_Drivers.exe') {
                                return $true
                            }
                            try {
                                $innerProbe = Get-AmdStaticIsSetupStreamProbe -Path $_.FullName
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
                        Path         = $file.FullName
                        Depth        = $depth + 1
                        ParentSha256 = $containerSha
                    })
                }
            }
        }

        $containers.Add([pscustomobject][ordered]@{
            SourceArtifactSha256  = $sourceSha
            ContainerSha256       = $containerSha
            ParentContainerSha256 = $entry.ParentSha256
            RelativePath          = $relPath
            Depth                 = $depth
            Extractor             = $extractor
            Status                = $status
            ExitCode              = $exitCode
            Error                 = $errorText
            OutputRoot            = $out
            ProducedFiles         = $producedFiles
            ProducedContainers    = @($nested).Count
            ProducedInfs          = $producedInfs
        })
    }

    # ---- MSI File-table read across every extracted MSI (read-only) ----
    $msiRows = New-Object System.Collections.Generic.List[object]
    $msiTableStatus = 'Unavailable'
    $msiFiles = @(
        Get-ChildItem -LiteralPath $destRootFull -File -Recurse -ErrorAction SilentlyContinue |
            Where-Object { $_.Extension -ieq '.msi' }
    )
    if ($msiFiles.Count -gt 0) {
        $readAny = $false
        $failedAny = $false
        foreach ($msi in $msiFiles) {
            $map = Get-AmdStaticMsiFileTableMap -MsiPath $msi.FullName
            if ($map.Status -eq 'Read') {
                $readAny = $true
                foreach ($row in @($map.Rows)) {
                    $msiRows.Add($row)
                }
            }
            elseif ($map.Status -eq 'Failed') {
                $failedAny = $true
            }
        }
        if ($readAny) {
            $msiTableStatus = 'Read'
        }
        elseif ($failedAny) {
            $msiTableStatus = 'Failed'
        }
    }

    # ---- INF universe: base entries plus suffix-versioned variants ----
    $infRecords = New-Object System.Collections.Generic.List[object]
    $infBaseCount = 0
    $infVariantCount = 0
    $infFiles = @(
        Get-ChildItem -LiteralPath $destRootFull -File -Recurse -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -match '(?i)\.inf\d*$' }
    )
    foreach ($infFile in $infFiles) {
        $resolved = Resolve-AmdStaticCabEntryName -EntryName $infFile.Name -FileTableRows ($msiRows.ToArray())
        if ($resolved.VariantIndex -gt 0) {
            $infVariantCount++
        }
        else {
            $infBaseCount++
        }
        $infRel = $infFile.FullName.Substring($destRootFull.Length).TrimStart('\', '/')
        $infRecords.Add([pscustomobject][ordered]@{
            CabEntryName = $infFile.Name
            ResolvedName = $resolved.ResolvedName
            VariantIndex = $resolved.VariantIndex
            RelativePath = $infRel
            InfSha256    = (Get-FileHash -LiteralPath $infFile.FullName -Algorithm SHA256).Hash.ToLowerInvariant()
        })
    }

    $failedContainers = @($containers.ToArray() | Where-Object { $_.Status -eq 'ExtractionFailed' })
    $graphStatus = if ($containers.Count -eq 0) {
        'ExtractionFailed'
    }
    elseif ($hadError -or $failedContainers.Count -gt 0) {
        'ExtractedWithErrors'
    }
    elseif ($infFiles.Count -gt 0) {
        'ExtractionComplete'
    }
    else {
        'PartialExtraction'
    }

    return [pscustomobject][ordered]@{
        SchemaVersion  = '1.0'
        GeneratedAtUtc = [DateTime]::UtcNow.ToString('o')
        ToolIdentity   = $null
        MaxDepth       = $MaxDepth
        Status         = $graphStatus
        MsiFileTable   = [pscustomobject][ordered]@{
            Status   = $msiTableStatus
            RowCount = $msiRows.Count
        }
        Containers     = $containers.ToArray()
        Infs           = $infRecords.ToArray()
        ParityNote     = [pscustomobject][ordered]@{
            ShadowInfBaseCount    = $infBaseCount
            ShadowInfVariantCount = $infVariantCount
            CurrentTreeInfCount   = $null
        }
    }
}

function Get-AmdStaticMsiFileTableMap {
    <#
    .SYNOPSIS
        Read-only File-table read of an MSI via the Windows Installer COM
        automation interface.
    .DESCRIPTION
        Opens the MSI database with OpenDatabase mode 0 (read-only) and
        queries only the File table. No process is launched and no install
        sequence runs. On non-Windows hosts or COM failure the caller
        receives a typed status instead of a guess.
    #>
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$MsiPath
    )

    if ($env:OS -ne 'Windows_NT') {
        return [pscustomobject]@{
            Status = 'Unavailable'
            Rows   = @()
            Error  = 'Windows Installer COM is only available on Windows.'
        }
    }

    $installer = $null
    $database = $null
    $view = $null
    try {
        $installer = New-Object -ComObject 'WindowsInstaller.Installer'
        $database = $installer.GetType().InvokeMember(
            'OpenDatabase', 'InvokeMethod', $null, $installer, @($MsiPath, 0))
        $view = $database.GetType().InvokeMember(
            'OpenView', 'InvokeMethod', $null, $database,
            @('SELECT `File`, `FileName` FROM `File`'))
        $null = $view.GetType().InvokeMember('Execute', 'InvokeMethod', $null, $view, $null)

        $rows = New-Object System.Collections.Generic.List[object]
        while ($true) {
            $record = $view.GetType().InvokeMember('Fetch', 'InvokeMethod', $null, $view, $null)
            if ($null -eq $record) {
                break
            }
            $fileKey = [string]$record.GetType().InvokeMember(
                'StringData', 'GetProperty', $null, $record, @(1))
            $fileName = [string]$record.GetType().InvokeMember(
                'StringData', 'GetProperty', $null, $record, @(2))
            $rows.Add([pscustomobject]@{
                File     = $fileKey
                FileName = $fileName
            })
        }
        return [pscustomobject]@{
            Status = 'Read'
            Rows   = $rows.ToArray()
            Error  = $null
        }
    }
    catch {
        return [pscustomobject]@{
            Status = 'Failed'
            Rows   = @()
            Error  = $_.Exception.Message
        }
    }
    finally {
        foreach ($comObject in @($view, $database, $installer)) {
            if ($null -ne $comObject) {
                try {
                    $null = [System.Runtime.InteropServices.Marshal]::ReleaseComObject($comObject)
                }
                catch {
                    Write-Verbose 'COM release failed (ignored).'
                }
            }
        }
    }
}

function Resolve-AmdStaticCabEntryName {
    <#
    .SYNOPSIS
        Pure resolver: CAB entry leaf name to real file name plus variant
        index.
    .DESCRIPTION
        Suffix-versioned sibling entries (name.inf, name.inf2, ...) are the
        MSI external-CAB multi-version convention; the authoritative real
        name lives in the MSI File table (File key to FileName short|long).
        Pure by design so the mapping is testable off-Windows with
        synthetic rows. Resolution values: FileTable (a row matched the
        entry key), SuffixConvention (no row; base name derived from the
        suffix convention), Verbatim (no row and no suffix).
    #>
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$EntryName,

        [object[]]$FileTableRows = @()
    )

    $leaf = [System.IO.Path]::GetFileName($EntryName)
    $variantIndex = 0
    $baseName = $leaf
    $suffixMatch = [regex]::Match($leaf, '(?i)^(?<base>.+\.inf)(?<idx>\d+)$')
    if ($suffixMatch.Success) {
        $baseName = $suffixMatch.Groups['base'].Value
        $variantIndex = [int]$suffixMatch.Groups['idx'].Value
    }

    $resolvedName = $null
    $resolution = 'Unresolved'
    foreach ($row in @($FileTableRows)) {
        if ($null -eq $row) {
            continue
        }
        if ([string]::Equals([string]$row.File, $leaf, [System.StringComparison]::OrdinalIgnoreCase)) {
            $fileName = [string]$row.FileName
            if ($fileName.Contains('|')) {
                $fileName = $fileName.Split('|')[-1]
            }
            $resolvedName = $fileName
            $resolution = 'FileTable'
            break
        }
    }
    if (-not $resolvedName) {
        $resolvedName = $baseName
        if ($variantIndex -gt 0) {
            $resolution = 'SuffixConvention'
        }
        else {
            $resolution = 'Verbatim'
        }
    }

    return [pscustomobject][ordered]@{
        EntryName    = $leaf
        BaseName     = $baseName
        VariantIndex = $variantIndex
        ResolvedName = $resolvedName
        Resolution   = $resolution
    }
}

function Write-AmdStaticExtractionGraph {
    <#
    .SYNOPSIS
        Write an extraction-graph object as canonical JSON.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $Graph,

        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    $parent = Split-Path -Parent $Path
    if ($parent -and -not (Test-Path -LiteralPath $parent -PathType Container)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }
    $Graph | ConvertTo-Json -Depth 6 | Set-Content -Encoding UTF8 -LiteralPath $Path
}
# ===== END SOURCE-FRAGMENT amd-static-extraction v1 =====
