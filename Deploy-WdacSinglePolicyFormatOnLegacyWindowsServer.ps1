<#
.SYNOPSIS
    Deploy a Single Policy Format (SPF) Windows Defender Application Control
    (WDAC) authorization policy on legacy Windows Server hosts (WS2019 and
    WS2016) so self-signed device drivers produced by this repository's
    driver scripts (Chipset, Graphics, NPU, BthPan) can load while Secure
    Boot stays ON.

.DESCRIPTION
    ================================================================
    SCOPE - WINDOWS SERVER 2019 AND 2016 ONLY
    ================================================================
    
    WDAC has two on-disk policy formats:
    
      - Single Policy Format (SPF)
        Deploy path: %WINDIR%\System32\CodeIntegrity\SiPolicy.p7b
        Supported on : Windows 10 1607+ / Server 2016+
        This is the ONLY format available on WS2019 / WS2016 (kernel-
        level OS limitation; the Multiple Policy Format infrastructure
        was added in Windows 10 1903 / Server 2022 and was never
        backported to older kernels).
    
      - Multiple Policy Format (MPF)
        Deploy path: %WINDIR%\System32\CodeIntegrity\CiPolicies\Active\{GUID}.cip
        Supported on : Windows 10 1903+ / Server 2022+
        Handled INSIDE each driver script's I02 phase via a supplemental
        policy that extends the Microsoft DefaultWindows base policy.
    
    This script targets the SPF path. WS2022 / WS2025 use the MPF path
    inside the driver scripts and do NOT call this script.
    
    The script refuses to run on:
      - Anything other than Windows Server (i.e., client SKUs)
      - Server build >= 20348 (WS2022 / WS2025) which has CiTool + MPF
    
    See SPEC.md section D.25 ("Legacy Windows Server WDAC single-policy
    format orchestration") for the design rationale.
    
    ================================================================
    HIGH-LEVEL FLOW
    ================================================================
    
    The script is invoked by the driver scripts (Chipset, Graphics, NPU,
    BthPan) and exposes an Action-based API:
    
      GetStatus                Query current WDAC state (read-only).
      AddCert                  Add a self-signing cert to the policy
                               and (re)deploy.
      RemoveCert               Remove a cert from the policy.
      Verify                   Check whether a thumbprint is authorized
                               in the current policy.
      Uninstall                Remove the entire WDAC policy + manifest.
      Repair                   Recover from Inconsistent / Ours-Stale.
      ComputeCanonicalHash     Developer helper: compute canonical
                               (BOM-strip + CRLF-normalize) SHA256 of
                               an arbitrary file.
      ComputeOwnCanonicalHash  Developer helper: emit own canonical hash.
    
    Internally, the script maintains a manifest at:
      C:\ProgramData\Deploy-Drivers-For-WindowsServer\wdac\manifest.json
    
    plus the source policy XML and .p7b, copies of authorized .cer
    files, and backup copies of foreign policies that we've replaced.
    
    ================================================================
    STATE MODEL
    ================================================================
    
    WDAC state on the host is classified as one of:
    
      None             - No SiPolicy.p7b deployed, no manifest.
      Ours-Healthy     - Our policy is deployed; deployed hash matches
                         our source hash matches manifest record.
      Ours-Stale       - Manifest exists but deployed .p7b is missing
                         (operator manually deleted). Auto-recoverable.
      Ours-Tampered    - Manifest exists and deployed .p7b exists, but
                         deployed hash differs from source hash. The
                         operator (or another tool) modified our policy.
      Foreign          - SiPolicy.p7b exists but no manifest matches;
                         some other tool / GPO / admin deployed it.
      Inconsistent     - Manifest is corrupt or unreadable.
    
    The State x Action matrix defines what each Action does in each
    state. See SPEC D.25 for the complete table.
    
    ================================================================
    EXIT CODES
    ================================================================
    
      0 = success
      1 = generic failure
      2 = state mismatch (e.g., Foreign without -ForceOverrideForeign)
      3 = invalid arguments
      4 = system error (WMI, file I/O, parse failure)

.PARAMETER Action
    The operation to perform. See HIGH-LEVEL FLOW above.

.PARAMETER CertFile
    Required for Action=AddCert. Path to the .cer file of the self-
    signing certificate to authorize. The script copies it to
    %ProgramData%\Deploy-Drivers-For-WindowsServer\wdac\certs\ and
    records both paths in the manifest.

.PARAMETER CertThumbprint
    Required for Action=RemoveCert and Action=Verify. The thumbprint
    (40 hex chars) of the cert to remove or verify.

.PARAMETER CallerScript
    Required for Action=AddCert. The path or filename of the calling
    driver script (e.g., 'Deploy-AMDChipsetDriverOnWindowsServer.ps1').
    Recorded in the manifest under authorizedCerts[].addedBy.

.PARAMETER CallerScriptVersion
    Optional for Action=AddCert. Version string of the calling driver
    script (e.g., 'chipset-2026.05.22-r67'). Recorded in the manifest.

.PARAMETER File
    Required for Action=ComputeCanonicalHash. Path to the file whose
    canonical (BOM-strip + CRLF-normalize) SHA256 to compute.

.PARAMETER Force
    For Action=AddCert: required when state is Ours-Tampered (operator
    confirms re-deploy from source).
    For Action=RemoveCert / Uninstall: required to act on Ours-Tampered
    or to bypass certain safeguards.

.PARAMETER ForceOverrideForeign
    For Action=AddCert / Uninstall: required to operate when state is
    Foreign. Triggers backup of the foreign policy before replacement.

.PARAMETER ReplaceExistingFromCaller
    For Action=AddCert: when the manifest already has a cert from the
    same CallerScript with a different thumbprint, replace the existing
    entry (1:1) instead of appending. Useful when a driver script is
    re-run with -CleanWorkRoot and generates a new cert.

.PARAMETER RestoreForeignBackup
    For Action=Uninstall: after removing our policy, restore the most
    recent foreign-policy backup from %ProgramData%\...\backups\.

.PARAMETER AuditMode
    For Action=AddCert: deploy the policy with WDAC Rule Option 3
    (Enabled:Audit Mode) so violations are logged but not enforced.
    The default is Enforced.

.PARAMETER OutputFormat
    'Text' (default, human-readable) or 'Json' (machine-parseable).
    Driver scripts that invoke this script programmatically should
    use -OutputFormat Json and pipe through ConvertFrom-Json.

.PARAMETER CheckCertThumbprint
    For Action=GetStatus: in addition to the standard state report,
    explicitly check whether this specific thumbprint is authorized.
    Reflected in the output's checkedCertThumbprint and
    checkedCertPresent fields.

.PARAMETER HistoryMaxEntries
    For internal use. Caps the deploymentHistory[] array in the
    manifest at this many entries (default 50). Older entries are
    dropped from the front.

.PARAMETER Help
    Show this help text and exit.

.EXAMPLE
    .\Deploy-WdacSinglePolicyFormatOnLegacyWindowsServer.ps1 -Action GetStatus
    
    Display the current WDAC state in human-readable form.

.EXAMPLE
    .\Deploy-WdacSinglePolicyFormatOnLegacyWindowsServer.ps1 `
        -Action AddCert `
        -CertFile 'C:\Temp\Workspace_AMD-Chipset\cert\AMD-Chipset-Driver-CodeSign.cer' `
        -CallerScript 'Deploy-AMDChipsetDriverOnWindowsServer.ps1' `
        -CallerScriptVersion 'chipset-2026.05.22-r67' `
        -OutputFormat Json
    
    Add the Chipset script's self-signing cert to the policy and
    redeploy. Output is JSON so the caller can parse the result.

.EXAMPLE
    .\Deploy-WdacSinglePolicyFormatOnLegacyWindowsServer.ps1 `
        -Action Verify -CertThumbprint '566D0B28E7A76B2464CF78FAFC5F93446723446D'
    
    Exit code 0 if the thumbprint is authorized, 1 otherwise.

.EXAMPLE
    .\Deploy-WdacSinglePolicyFormatOnLegacyWindowsServer.ps1 -Action Uninstall
    
    Remove our WDAC policy and manifest. Refuses if the deployed
    policy is Foreign (use -ForceOverrideForeign to bypass).

.EXAMPLE
    .\Deploy-WdacSinglePolicyFormatOnLegacyWindowsServer.ps1 `
        -Action ComputeOwnCanonicalHash
    
    Developer helper: emit the canonical hash of this script itself
    so it can be embedded in the calling driver scripts.

.NOTES
    Repository    : https://github.com/usui-tk/Deploy-Drivers-For-WindowsServer
    Companion to  : Deploy-AMDChipsetDriverOnWindowsServer.ps1,
                    Deploy-AMDGraphicsDriverOnWindowsServer.ps1,
                    Deploy-AMDNpuDriverOnWindowsServer.ps1,
                    Deploy-MSBthPanInboxOnWindowsServer.ps1
    Target OS     : Windows Server 2019 (build 17763), Windows Server 2016 (build 14393)
                    NOT for Windows Server 2022 / 2025 (use MPF path inside driver scripts)
                    NOT for Windows client SKUs (Workstation product type)
    SPEC          : See SPEC.md section D.25
#>

[CmdletBinding()]
param(
    # === Action selection =============================================
    [Parameter(Mandatory=$false, Position=0)]
    [ValidateSet(
        'GetStatus',
        'AddCert',
        'RemoveCert',
        'Verify',
        'Uninstall',
        'Repair',
        'ComputeCanonicalHash',
        'ComputeOwnCanonicalHash',
        'Help'
    )]
    [string]$Action = 'Help',

    # === Cert payload (AddCert) =======================================
    [string]$CertFile = '',

    # === Cert reference (RemoveCert / Verify / optional GetStatus) ====
    [string]$CertThumbprint = '',

    # === Provenance metadata (AddCert) ================================
    [string]$CallerScript = '',
    [string]$CallerScriptVersion = '',

    # === ComputeCanonicalHash =========================================
    [string]$File = '',

    # === GetStatus optional cross-check ===============================
    [string]$CheckCertThumbprint = '',

    # === Safeguard overrides ==========================================
    [switch]$Force,
    [switch]$ForceOverrideForeign,
    [switch]$ReplaceExistingFromCaller,
    [switch]$RestoreForeignBackup,

    # === Policy generation ============================================
    [switch]$AuditMode,

    # === Output ========================================================
    [ValidateSet('Text','Json')]
    [string]$OutputFormat = 'Text',

    # === Manifest housekeeping ========================================
    [ValidateRange(1, 1000)]
    [int]$HistoryMaxEntries = 50,

    # === Help =========================================================
    [switch]$Help_
)

$ErrorActionPreference = 'Stop'
$ProgressPreference    = 'SilentlyContinue'

#####################################################################
# SECTION 0: Script-level constants and state
#####################################################################

# ScriptVersion: bump on every meaningful edit. Format: wdac-YYYY.MM.DD-rNN
$Script:ScriptVersion = 'wdac-2026.05.22-r01'
$Script:ScriptTag     = 'legacy-wdac-single-policy-format-pilot'

# Reserved policy GUID for the Deploy-Drivers-For-WindowsServer
# single-policy-format orchestration. Documented in SPEC A.x as a
# project-reserved GUID. Detected by both PolicyID GUID match (fast)
# and source/deploy SHA256 match (authoritative).
$Script:ReservedPolicyId = '{DDF8C2DA-A1B2-4D52-B551-446570577053}'

# Microsoft-shipped GUIDs we reference
$Script:WindowsPlatformId = '{2E07F7E4-194C-4D20-B7C9-6F44A6C5A234}'

# ProgramData base path (constant across all driver scripts and this
# external script).
$Script:ProgramDataBase   = (Join-Path $env:ProgramData 'Deploy-Drivers-For-WindowsServer\wdac')
$Script:ManifestPath      = (Join-Path $Script:ProgramDataBase 'manifest.json')
$Script:SourceXmlPath     = (Join-Path $Script:ProgramDataBase 'active-policy.xml')
$Script:SourceP7bPath     = (Join-Path $Script:ProgramDataBase 'active-policy.p7b')
$Script:CertsDir          = (Join-Path $Script:ProgramDataBase 'certs')
$Script:BackupsDir        = (Join-Path $Script:ProgramDataBase 'backups')

# Deployed policy location for Single Policy Format
$Script:DeployedPolicyPath = (Join-Path $env:windir 'System32\CodeIntegrity\SiPolicy.p7b')

# Manifest schema version
$Script:SchemaVersion = '1.0'
$Script:SchemaId      = 'deploy-drivers-for-windowsserver/wdac-manifest/v1'

# Self-canonical-hash computed lazily on first need.
$Script:SelfCanonicalHash = $null

#####################################################################
# SECTION 1: Output helpers
#####################################################################
# Two output modes:
#   Text - human-readable, color-coded (caller is an operator)
#   Json - machine-parseable, no decoration  (caller is a driver script)
#
# The Json buffer is collected into $Script:JsonResult and emitted at
# the very end (after the Action handler completes) so that interim
# Write-Step / Write-Ok messages don't pollute JSON output.

$Script:JsonResult = [pscustomobject]@{
    action          = $Action
    result          = 'unknown'
    state           = $null
    stateBefore     = $null
    stateAfter      = $null
    noOp            = $false
    message         = ''
    details         = @{}
    exitCode        = 0
    scriptVersion   = $Script:ScriptVersion
    timestamp       = (Get-Date -Format 'yyyy-MM-ddTHH:mm:ssZ' -AsUTC -ErrorAction SilentlyContinue)
}
if (-not $Script:JsonResult.timestamp) {
    # PS 5 fallback (no -AsUTC)
    $Script:JsonResult.timestamp = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
}

function _IsTextMode { return ($OutputFormat -eq 'Text') }
function _IsJsonMode { return ($OutputFormat -eq 'Json') }

function Write-Step  { param($Msg) if (_IsTextMode) { Write-Host ('[*] ' + $Msg) -ForegroundColor Cyan     } }
function Write-Ok    { param($Msg) if (_IsTextMode) { Write-Host ('[+] ' + $Msg) -ForegroundColor Green    } }
function Write-Warn2 { param($Msg) if (_IsTextMode) { Write-Host ('[!] ' + $Msg) -ForegroundColor Yellow   } }
function Write-Fail  { param($Msg) if (_IsTextMode) { Write-Host ('[X] ' + $Msg) -ForegroundColor Red      } }
function Write-Skip  { param($Msg) if (_IsTextMode) { Write-Host ('[~] ' + $Msg) -ForegroundColor DarkGray } }
function Write-Detail { param($Msg) if (_IsTextMode) { Write-Host ('    ' + $Msg) -ForegroundColor Gray     } }

function _EmitJson {
    # Render $Script:JsonResult to stdout as compact JSON.
    if ($Script:JsonResult.details -is [hashtable] -and $Script:JsonResult.details.Count -eq 0) {
        $Script:JsonResult.details = $null
    }
    $json = $Script:JsonResult | ConvertTo-Json -Depth 10 -Compress:$false
    Write-Output $json
}

function Set-JsonResult {
    # Helper to populate the JSON result object.
    param(
        [string]$Result   = $null,
        [string]$State    = $null,
        [string]$StateBefore = $null,
        [string]$StateAfter  = $null,
        [Nullable[bool]]$NoOp = $null,
        [string]$Message  = $null,
        [int]$ExitCode    = $null,
        [hashtable]$Details = $null
    )
    if ($PSBoundParameters.ContainsKey('Result'))      { $Script:JsonResult.result      = $Result }
    if ($PSBoundParameters.ContainsKey('State'))       { $Script:JsonResult.state       = $State }
    if ($PSBoundParameters.ContainsKey('StateBefore')) { $Script:JsonResult.stateBefore = $StateBefore }
    if ($PSBoundParameters.ContainsKey('StateAfter'))  { $Script:JsonResult.stateAfter  = $StateAfter }
    if ($PSBoundParameters.ContainsKey('NoOp') -and $NoOp.HasValue)  { $Script:JsonResult.noOp = $NoOp.Value }
    if ($PSBoundParameters.ContainsKey('Message'))     { $Script:JsonResult.message     = $Message }
    if ($PSBoundParameters.ContainsKey('ExitCode'))    { $Script:JsonResult.exitCode    = $ExitCode }
    if ($PSBoundParameters.ContainsKey('Details') -and $Details) {
        foreach ($k in $Details.Keys) {
            $Script:JsonResult.details[$k] = $Details[$k]
        }
    }
}

#####################################################################
# SECTION 2: Canonical hash function
#####################################################################
# Computes a SHA256 hash of a script file's content normalized so that
# the result is invariant to:
#   - UTF-8 BOM presence (stripped if leading bytes 0xEF 0xBB 0xBF)
#   - Line ending convention (CRLF -> LF, residual CR -> LF)
#
# Rationale: the same .ps1 file checked out on a Windows host with
# .gitattributes "text working-tree-encoding=UTF-8 eol=crlf" has CRLF
# line endings and a leading BOM, while the same file fetched from
# raw.githubusercontent.com has LF endings (and BOM preserved or
# stripped depending on git config). A plain SHA256 of the bytes
# would therefore not match. This canonical form removes both
# differences so the hash is stable across local working tree and
# GitHub-raw fetch.
#
# This function is implemented IDENTICALLY in all 4 driver scripts
# (Chipset, Graphics, NPU, BthPan) plus this WDAC external script -
# total 5 copies. See SPEC A.x for the convention. When changing this
# function, ALL 5 copies must be updated together.

function Get-CanonicalScriptHash {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateScript({Test-Path -LiteralPath $_ -PathType Leaf})]
        [string]$Path
    )

    # 1. Read raw bytes
    $bytes = [System.IO.File]::ReadAllBytes($Path)

    # 2. Strip UTF-8 BOM if present
    if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
        $bytes = $bytes[3..($bytes.Length - 1)]
    }

    # 3. Decode as UTF-8 and normalize line endings
    $text = [System.Text.Encoding]::UTF8.GetString($bytes)
    $text = $text -replace "`r`n", "`n"
    $text = $text -replace "`r",    "`n"

    # 4. Re-encode and SHA256
    $canonicalBytes = [System.Text.Encoding]::UTF8.GetBytes($text)
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try {
        $hash = $sha.ComputeHash($canonicalBytes)
        $hex = ([System.BitConverter]::ToString($hash) -replace '-', '').ToLower()
        return $hex
    } finally {
        $sha.Dispose()
    }
}

function Get-SelfCanonicalHash {
    # Computes (or returns cached) canonical hash of this script itself.
    if ($Script:SelfCanonicalHash) { return $Script:SelfCanonicalHash }
    $self = $PSCommandPath
    if ([string]::IsNullOrEmpty($self)) {
        $self = $MyInvocation.MyCommand.Path
    }
    if (-not $self -or -not (Test-Path -LiteralPath $self)) {
        return '(self-path-unavailable)'
    }
    $Script:SelfCanonicalHash = Get-CanonicalScriptHash -Path $self
    return $Script:SelfCanonicalHash
}

#####################################################################
# SECTION 3: OS guard
#####################################################################
# This script is for Windows Server 2019 (build 17763) and Windows
# Server 2016 (build 14393) ONLY. Refuse to run on:
#   - Anything other than Windows Server (client SKUs)
#   - Windows Server 2022 / 2025 (build >= 20348) where the driver
#     scripts use the Multiple Policy Format supplemental policy
#     path directly and never call this script.
#   - Non-Windows hosts (PowerShell Core on Linux/macOS) - this
#     script does nothing useful there.

function Test-IsLegacyWindowsServerHost {
    [OutputType([pscustomobject])]
    param()

    $result = [pscustomobject]@{
        IsWindowsServer = $false
        ProductType     = $null
        Build           = $null
        Caption         = ''
        IsLegacy        = $false
        Reason          = ''
    }

    # Windows-only check
    if ([System.Environment]::OSVersion.Platform -ne 'Win32NT') {
        $result.Reason = ('OS platform is {0}, not Win32NT' -f [System.Environment]::OSVersion.Platform)
        return $result
    }

    try {
        $os = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction Stop
        # ProductType: 1=Workstation, 2=Domain Controller, 3=Server
        $result.ProductType = [int]$os.ProductType
        $result.Build       = [int]$os.BuildNumber
        $result.Caption     = $os.Caption
    } catch {
        # Fall back to environment
        $result.Build = [int][System.Environment]::OSVersion.Version.Build
        $result.Reason = ('Could not query Win32_OperatingSystem: {0}' -f $_.Exception.Message)
        return $result
    }

    if ($result.ProductType -ne 2 -and $result.ProductType -ne 3) {
        $result.Reason = ('ProductType={0} is a Workstation; this script is Server-only.' -f $result.ProductType)
        return $result
    }
    $result.IsWindowsServer = $true

    # WS2022 = build 20348, WS2025 = build 26100
    # WS2019 = build 17763, WS2016 = build 14393
    if ($result.Build -ge 20348) {
        $result.Reason = ('Build {0} is WS2022+ (MPF-capable); use the driver scripts'' built-in WDAC supplemental policy path instead of this script.' -f $result.Build)
        return $result
    }
    if ($result.Build -lt 14393) {
        $result.Reason = ('Build {0} is older than WS2016 (build 14393); WDAC SPF is not available.' -f $result.Build)
        return $result
    }

    $result.IsLegacy = $true
    return $result
}

function Assert-LegacyWindowsServerHost {
    # Throws if this is not a WS2019 / WS2016 host. Skipped for the
    # dev-helper Actions (ComputeCanonicalHash, ComputeOwnCanonicalHash,
    # Help) which are useful to run on any OS.
    if ($Action -in @('ComputeCanonicalHash', 'ComputeOwnCanonicalHash', 'Help')) {
        return
    }
    $r = Test-IsLegacyWindowsServerHost
    if (-not $r.IsLegacy) {
        $msg = ("This script is for Windows Server 2019 (build 17763) and Windows Server 2016 (build 14393) only. " +
                "Detected: ProductType={0}, Build={1}, Caption='{2}'. {3}" -f $r.ProductType, $r.Build, $r.Caption, $r.Reason)
        Set-JsonResult -Result 'refused' -Message $msg -ExitCode 3 -Details @{
            isWindowsServer = $r.IsWindowsServer
            productType     = $r.ProductType
            build           = $r.Build
            caption         = $r.Caption
            reason          = $r.Reason
        }
        throw $msg
    }
    return $r
}

#####################################################################
# SECTION 4: Filesystem helpers (atomic writes, paths, hashes)
#####################################################################

function Initialize-WdacDirectoryStructure {
    # Creates the ProgramData directory tree if missing. Idempotent.
    foreach ($d in @($Script:ProgramDataBase, $Script:CertsDir, $Script:BackupsDir)) {
        if (-not (Test-Path -LiteralPath $d)) {
            $null = New-Item -ItemType Directory -Path $d -Force
        }
    }
}

function Get-FileSha256Hex {
    # SHA256 of file bytes as lowercase hex. Returns $null on missing
    # file (rather than throwing) so callers can use it for state
    # detection where absence is a meaningful answer.
    param([string]$Path)
    if ([string]::IsNullOrEmpty($Path) -or -not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        return $null
    }
    try {
        return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLower()
    } catch {
        return $null
    }
}

function Save-JsonAtomic {
    # Atomic file write: write to .tmp, fsync (best-effort on Windows),
    # then Move-Item over the target. On NTFS, Move-Item to an existing
    # path is rename-and-replace which is atomic at the file level.
    param(
        [Parameter(Mandatory=$true)][string]$Path,
        [Parameter(Mandatory=$true)]$Object
    )
    $dir = Split-Path -Parent -Path $Path
    if (-not (Test-Path -LiteralPath $dir)) {
        $null = New-Item -ItemType Directory -Path $dir -Force
    }
    $tmp  = $Path + '.tmp'
    $json = $Object | ConvertTo-Json -Depth 12
    # Write with UTF-8 (no BOM) - standard JSON convention
    [System.IO.File]::WriteAllText($tmp, $json, [System.Text.UTF8Encoding]::new($false))
    if (Test-Path -LiteralPath $Path) {
        Remove-Item -LiteralPath $Path -Force -ErrorAction Stop
    }
    Move-Item -LiteralPath $tmp -Destination $Path -Force -ErrorAction Stop
}

function Read-JsonStrict {
    # Loads JSON from a file. Returns $null if file missing.
    # Throws on parse error (so callers can catch and mark Inconsistent).
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        return $null
    }
    $raw = [System.IO.File]::ReadAllText($Path, [System.Text.UTF8Encoding]::new($false))
    return ($raw | ConvertFrom-Json -ErrorAction Stop)
}

function New-IsoTimestamp {
    # ISO 8601 UTC timestamp.
    return (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
}

function Copy-CertToProgramData {
    # Copies a .cer file from a driver-script workspace into the
    # ProgramData certs/ directory, naming the copy after the cert's
    # thumbprint so multiple driver scripts can coexist.
    # Returns the copy's path.
    param(
        [Parameter(Mandatory=$true)][string]$SourceCer,
        [Parameter(Mandatory=$true)][string]$Thumbprint
    )
    Initialize-WdacDirectoryStructure
    $name = ('{0}.cer' -f $Thumbprint.ToUpper())
    $dest = Join-Path $Script:CertsDir $name
    if (-not (Test-Path -LiteralPath $dest) -or
        ((Get-FileSha256Hex $dest) -ne (Get-FileSha256Hex $SourceCer))) {
        Copy-Item -LiteralPath $SourceCer -Destination $dest -Force
    }
    return $dest
}

function Get-CertInfoFromCer {
    # Loads cert info from a .cer file. Returns thumbprint, subject,
    # validFrom / validTo, and TBS hash (needed for WDAC Signer rule).
    param([Parameter(Mandatory=$true)][string]$Path)
    $cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2 $Path
    # TBS hash is what WDAC uses to identify signers. Compute SHA256
    # over the TBS (To-Be-Signed) bytes.
    $tbsBytes = $cert.GetRawCertData()  # X509Certificate2 has no direct GetTbsCertificate(); use a fallback:
    # The Signer.CertRoot/@Type=TBS expected value is the SHA256 of the
    # SubjectKeyIdentifier-derived "certificate root" - in practice for
    # self-signed self-issued certs this aligns with the SHA256 of the
    # full DER. For accurate TBS extraction we use ConfigCI semantics
    # via Add-SignerRule when ConfigCI is present. For our purposes the
    # SHA256 of the full DER works as a deterministic identifier in the
    # manifest, while the actual WDAC XML is generated by Add-SignerRule
    # which extracts the proper TBS.
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try {
        $tbsHash = ([System.BitConverter]::ToString($sha.ComputeHash($tbsBytes)) -replace '-', '').ToLower()
    } finally {
        $sha.Dispose()
    }
    return [pscustomobject]@{
        Thumbprint = $cert.Thumbprint.ToUpper()
        Subject    = $cert.Subject
        Issuer     = $cert.Issuer
        ValidFrom  = $cert.NotBefore.ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
        ValidTo    = $cert.NotAfter.ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
        TbsHash    = $tbsHash
    }
}

#####################################################################
# SECTION 5: Manifest read / write / migration
#####################################################################

function New-EmptyManifest {
    # Factory for a fresh manifest object (no certs, no policy yet).
    return [pscustomobject]@{
        schemaVersion = $Script:SchemaVersion
        schemaId      = $Script:SchemaId
        createdAt     = (New-IsoTimestamp)
        lastUpdatedAt = (New-IsoTimestamp)
        policy = $null
        authorizedCerts        = @()
        foreignPolicyBackup    = $null
        deploymentHistory      = @()
        historyMaxEntries      = $HistoryMaxEntries
        externalScriptVersion       = $Script:ScriptVersion
        externalScriptCanonicalHash = (Get-SelfCanonicalHash)
    }
}

function Test-ManifestValid {
    # Lightweight required-field validation. Returns $true if the
    # required fields are present and have plausible types.
    param($Manifest)
    if (-not $Manifest) { return $false }
    if (-not $Manifest.schemaVersion) { return $false }
    if (-not $Manifest.authorizedCerts -or $Manifest.authorizedCerts -isnot [System.Collections.IEnumerable]) {
        # Allow null/empty by coercing into an empty array on read
        return $false
    }
    return $true
}

function Read-Manifest {
    # Returns ($manifestObj, $error) tuple as a hashtable.
    #   .Manifest  - the loaded object, or $null
    #   .Error     - a short string explaining why, or $null on success
    #   .Inconsistent - $true if the file existed but was unparseable
    $out = @{ Manifest = $null; Error = $null; Inconsistent = $false }
    if (-not (Test-Path -LiteralPath $Script:ManifestPath -PathType Leaf)) {
        $out.Error = 'not-found'
        return $out
    }
    try {
        $m = Read-JsonStrict -Path $Script:ManifestPath
    } catch {
        $out.Error = ('parse-failed: {0}' -f $_.Exception.Message)
        $out.Inconsistent = $true
        return $out
    }
    if (-not (Test-ManifestValid -Manifest $m)) {
        $out.Error = 'invalid-schema'
        $out.Inconsistent = $true
        return $out
    }
    $out.Manifest = $m
    return $out
}

function Save-Manifest {
    # Writes the manifest with atomicity and history trim.
    param([Parameter(Mandatory=$true)]$Manifest)
    Initialize-WdacDirectoryStructure
    $Manifest.lastUpdatedAt = (New-IsoTimestamp)
    $Manifest.externalScriptVersion       = $Script:ScriptVersion
    $Manifest.externalScriptCanonicalHash = (Get-SelfCanonicalHash)

    # Trim history to the cap
    if ($Manifest.deploymentHistory) {
        $cap = $HistoryMaxEntries
        if ($Manifest.historyMaxEntries) { $cap = [int]$Manifest.historyMaxEntries }
        if ($Manifest.deploymentHistory.Count -gt $cap) {
            $Manifest.deploymentHistory = $Manifest.deploymentHistory[-$cap..-1]
        }
    }

    Save-JsonAtomic -Path $Script:ManifestPath -Object $Manifest
}

function Add-HistoryEntry {
    # Appends a record to deploymentHistory[].
    param(
        [Parameter(Mandatory=$true)]$Manifest,
        [Parameter(Mandatory=$true)][string]$ActionName,
        [string]$CertThumbprint  = '',
        [string]$Caller          = '',
        [string]$CallerVersion   = '',
        [string]$StateBefore     = '',
        [string]$StateAfter      = '',
        [string]$ResultingSha256 = ''
    )
    $entry = [pscustomobject]@{
        timestamp            = (New-IsoTimestamp)
        action               = $ActionName
        certThumbprint       = $CertThumbprint
        callerScript         = $Caller
        callerScriptVersion  = $CallerVersion
        stateBefore          = $StateBefore
        stateAfter           = $StateAfter
        resultingPolicySha256 = $ResultingSha256
    }
    if (-not $Manifest.deploymentHistory) {
        $Manifest.deploymentHistory = @()
    }
    $list = @() + $Manifest.deploymentHistory + $entry
    $Manifest.deploymentHistory = $list
}

#####################################################################
# SECTION 6: State detection
#####################################################################
# Returns one of: None / Ours-Healthy / Ours-Stale / Ours-Tampered /
#                 Foreign / Inconsistent
#
# Plus a detail object usable in GetStatus output and Action dispatch.

function Get-WdacState {
    [OutputType([pscustomobject])]
    param()

    $detail = [pscustomobject]@{
        state                  = 'Unknown'
        deployedExists         = $false
        deployedPath           = $Script:DeployedPolicyPath
        deployedSha256         = $null
        sourceP7bExists        = $false
        sourceP7bSha256        = $null
        sourceXmlExists        = $false
        manifestExists         = $false
        manifestInconsistent   = $false
        manifestRecordedSha256 = $null
        manifestPolicyId       = $null
        authorizedCerts        = @()
        expiringCerts          = @()
        foreignPolicyBackup    = $null
        recommendations        = @()
    }

    $detail.deployedExists  = Test-Path -LiteralPath $Script:DeployedPolicyPath -PathType Leaf
    $detail.deployedSha256  = Get-FileSha256Hex -Path $Script:DeployedPolicyPath
    $detail.sourceP7bExists = Test-Path -LiteralPath $Script:SourceP7bPath -PathType Leaf
    $detail.sourceP7bSha256 = Get-FileSha256Hex -Path $Script:SourceP7bPath
    $detail.sourceXmlExists = Test-Path -LiteralPath $Script:SourceXmlPath -PathType Leaf

    $r = Read-Manifest
    if ($r.Manifest) {
        $detail.manifestExists  = $true
        if ($r.Manifest.policy) {
            $detail.manifestPolicyId       = $r.Manifest.policy.policyId
            $detail.manifestRecordedSha256 = $r.Manifest.policy.sourceP7bSha256
        }
        if ($r.Manifest.authorizedCerts) {
            $detail.authorizedCerts = @() + $r.Manifest.authorizedCerts
        }
        if ($r.Manifest.foreignPolicyBackup) {
            $detail.foreignPolicyBackup = $r.Manifest.foreignPolicyBackup
        }

        # Compute expiringCerts (validTo within 90 days OR past)
        $now = (Get-Date).ToUniversalTime()
        foreach ($c in $detail.authorizedCerts) {
            if ($c.validTo) {
                try {
                    $vt = [datetime]::Parse($c.validTo).ToUniversalTime()
                    $days = ($vt - $now).Days
                    if ($days -lt 90) {
                        $detail.expiringCerts += [pscustomobject]@{
                            thumbprint   = $c.thumbprint
                            subject      = $c.subject
                            validTo      = $c.validTo
                            daysToExpiry = $days
                            expired      = ($days -lt 0)
                        }
                    }
                } catch { }
            }
        }
    } elseif ($r.Inconsistent) {
        $detail.manifestExists = $true
        $detail.manifestInconsistent = $true
    }

    # ---- Decide state ----
    if ($detail.manifestInconsistent) {
        $detail.state = 'Inconsistent'
        $detail.recommendations += 'Run -Action Repair to attempt to rebuild the manifest from authorized .cer files in ProgramData\certs\.'
    } elseif (-not $detail.deployedExists -and -not $detail.manifestExists) {
        $detail.state = 'None'
    } elseif ($detail.deployedExists -and -not $detail.manifestExists) {
        $detail.state = 'Foreign'
        $detail.recommendations += 'A WDAC policy exists at the deploy path but we have no manifest for it. Use -Action AddCert -ForceOverrideForeign to back up the foreign policy and replace, or merge our cert into the existing policy manually.'
    } elseif (-not $detail.deployedExists -and $detail.manifestExists) {
        # Manifest claims Ours but deployed file is gone
        $detail.state = 'Ours-Stale'
        $detail.recommendations += 'The deployed SiPolicy.p7b was removed but our manifest still claims it. -Action AddCert or -Action Repair will redeploy from our source.'
    } else {
        # Both exist
        if ($detail.sourceP7bExists -and $detail.deployedSha256 -eq $detail.sourceP7bSha256) {
            $detail.state = 'Ours-Healthy'
        } elseif ($detail.manifestRecordedSha256 -and $detail.deployedSha256 -eq $detail.manifestRecordedSha256) {
            # Deployed matches what the manifest records; source diverged
            $detail.state = 'Ours-Healthy'
            $detail.recommendations += 'Note: deployed policy matches manifest but our source .p7b on disk has diverged. -Action Repair will reconcile.'
        } else {
            $detail.state = 'Ours-Tampered'
            $detail.recommendations += 'Deployed SiPolicy.p7b does not match our source or manifest record. Use -Action AddCert -Force to redeploy our source, or -Action Uninstall -Force to remove our policy.'
        }
    }

    return $detail
}

#####################################################################
# SECTION 7: WDAC policy XML generation
#####################################################################
# Builds an AllowAll-based SPF policy XML with one signer per
# authorized cert. Uses ConfigCI cmdlets when available (Add-SignerRule
# computes proper TBS hashes) and falls back to direct XML construction
# otherwise (since WS2019 may not have the ConfigCI module installed).

function Get-PolicyVersionEx {
    # Computes a Major.Minor.Build.Revision string. We increment
    # Revision each time we redeploy.
    param($Manifest)
    if ($Manifest -and $Manifest.policy -and $Manifest.policy.versionEx) {
        $parts = ($Manifest.policy.versionEx -split '\.')
        if ($parts.Count -eq 4) {
            $rev = [int]$parts[3]
            $rev++
            return ('{0}.{1}.{2}.{3}' -f $parts[0], $parts[1], $parts[2], $rev)
        }
    }
    return '10.0.0.1'
}

function Test-ConfigCiModuleAvailable {
    return [bool](Get-Module -ListAvailable -Name 'ConfigCI' -ErrorAction SilentlyContinue)
}

function New-WdacPolicyXmlViaConfigCi {
    # Preferred path: use ConfigCI cmdlets to derive proper TBS hashes
    # and produce a Microsoft-validated XML.
    param(
        [Parameter(Mandatory=$true)][string[]]$CerFiles,
        [Parameter(Mandatory=$true)][string]$OutputXmlPath,
        [bool]$AuditMode = $false
    )

    $allowAll = Join-Path $env:windir 'schemas\CodeIntegrity\ExamplePolicies\AllowAll.xml'
    if (-not (Test-Path -LiteralPath $allowAll)) {
        throw 'AllowAll template not found at {0}; cannot build SPF policy via ConfigCI.' -f $allowAll
    }

    Copy-Item -LiteralPath $allowAll -Destination $OutputXmlPath -Force

    # Add each cert as a kernel-mode signer rule. ConfigCI's
    # Add-SignerRule will compute the TBS hash for us.
    foreach ($cer in $CerFiles) {
        Add-SignerRule -FilePath $OutputXmlPath -CertificatePath $cer -Kernel -ErrorAction Stop
    }

    # Set Policy ID (fixed reserved) and policy options
    $idNoBraces = $Script:ReservedPolicyId.Trim('{','}')
    Set-CIPolicyIdInfo -FilePath $OutputXmlPath -PolicyId $idNoBraces -ResetPolicyID:$false -ErrorAction SilentlyContinue
    # Some ConfigCI builds use -PolicyName; ignore errors if PolicyId
    # parameter shape differs across builds. We will rewrite the
    # PolicyID directly after the cmdlet-driven generation as a safety
    # measure.

    # Apply Rule Options
    Set-RuleOption -FilePath $OutputXmlPath -Option 6  -ErrorAction SilentlyContinue   # Enabled:Unsigned System Integrity Policy
    Set-RuleOption -FilePath $OutputXmlPath -Option 16 -ErrorAction SilentlyContinue   # Enabled:Update Policy No Reboot
    Set-RuleOption -FilePath $OutputXmlPath -Option 10 -ErrorAction SilentlyContinue   # Enabled:Boot Audit on Failure
    Set-RuleOption -FilePath $OutputXmlPath -Option 11 -Delete -ErrorAction SilentlyContinue  # Disabled:Script Enforcement -> ensure NOT enabled
    Set-RuleOption -FilePath $OutputXmlPath -Option 4  -Delete -ErrorAction SilentlyContinue  # Disabled:Flight Signing -> ensure NOT enabled
    Set-RuleOption -FilePath $OutputXmlPath -Option 0  -Delete -ErrorAction SilentlyContinue  # UMCI: ensure NOT enabled (kernel-mode only)
    Set-RuleOption -FilePath $OutputXmlPath -Option 2  -Delete -ErrorAction SilentlyContinue  # WHQL: not required
    Set-RuleOption -FilePath $OutputXmlPath -Option 8  -Delete -ErrorAction SilentlyContinue  # EV Signers: not required

    if ($AuditMode) {
        Set-RuleOption -FilePath $OutputXmlPath -Option 3 -ErrorAction SilentlyContinue   # Enabled:Audit Mode
    } else {
        Set-RuleOption -FilePath $OutputXmlPath -Option 3 -Delete -ErrorAction SilentlyContinue
    }

    # Patch PolicyID directly to our reserved GUID
    Update-PolicyIdInXml -XmlPath $OutputXmlPath -PolicyId $Script:ReservedPolicyId
}

function Update-PolicyIdInXml {
    # Force-set PolicyID and BasePolicyID to the reserved GUID. Single
    # Policy Format treats the policy as a base policy, so PolicyID
    # equals BasePolicyID.
    param(
        [Parameter(Mandatory=$true)][string]$XmlPath,
        [Parameter(Mandatory=$true)][string]$PolicyId
    )
    [xml]$doc = [System.IO.File]::ReadAllText($XmlPath, [System.Text.UTF8Encoding]::new($false))
    $ns = New-Object System.Xml.XmlNamespaceManager $doc.NameTable
    $ns.AddNamespace('s', 'urn:schemas-microsoft-com:sipolicy')

    $pid = $doc.SelectSingleNode('/s:SiPolicy/s:PolicyID', $ns)
    if ($pid) { $pid.InnerText = $PolicyId } else {
        $el = $doc.CreateElement('PolicyID', 'urn:schemas-microsoft-com:sipolicy')
        $el.InnerText = $PolicyId
        $null = $doc.DocumentElement.AppendChild($el)
    }
    $bpid = $doc.SelectSingleNode('/s:SiPolicy/s:BasePolicyID', $ns)
    if ($bpid) { $bpid.InnerText = $PolicyId } else {
        $el = $doc.CreateElement('BasePolicyID', 'urn:schemas-microsoft-com:sipolicy')
        $el.InnerText = $PolicyId
        $null = $doc.DocumentElement.AppendChild($el)
    }
    $doc.Save($XmlPath)
}

function New-WdacPolicyXmlFallback {
    # ConfigCI-free fallback. Builds a minimal SPF policy XML that
    # references each cert by SHA256 (Hash) signer mechanism instead
    # of TBS. WDAC accepts both; TBS is preferred for kernel-mode
    # signers, but Hash works for our case where the cert is self-
    # signed and the consumer doesn't enforce TBS.
    #
    # This path is used when the ConfigCI module is NOT installed on
    # the target. On WS2019 this is common (ConfigCI is an optional
    # feature). The driver scripts can still produce signed .cat
    # files; what this fallback gives up is the Microsoft-validated
    # XML structure. ConfigCI is strongly recommended.
    param(
        [Parameter(Mandatory=$true)][string[]]$CerFiles,
        [Parameter(Mandatory=$true)][string]$OutputXmlPath,
        [bool]$AuditMode = $false
    )
    throw ('ConfigCI module is not installed on this host. Install the WDAC PowerShell module ' +
           '(typically via the optional component "WDAC Refresh Tool" / "ConfigCI") and retry. ' +
           'Note: this fallback path is intentionally not auto-implemented to ensure WDAC XML ' +
           'validity. See SPEC D.25.4 for guidance.')
}

function New-WdacPolicyXml {
    # Top-level XML builder. Chooses ConfigCI path or fallback.
    param(
        [Parameter(Mandatory=$true)][string[]]$CerFiles,
        [Parameter(Mandatory=$true)][string]$OutputXmlPath,
        [bool]$AuditMode = $false
    )
    if (Test-ConfigCiModuleAvailable) {
        New-WdacPolicyXmlViaConfigCi -CerFiles $CerFiles -OutputXmlPath $OutputXmlPath -AuditMode $AuditMode
    } else {
        New-WdacPolicyXmlFallback   -CerFiles $CerFiles -OutputXmlPath $OutputXmlPath -AuditMode $AuditMode
    }
}

function ConvertFrom-WdacPolicyXmlToP7b {
    # Calls ConvertFrom-CIPolicy (ConfigCI cmdlet) to produce the
    # binary .p7b form from XML.
    param(
        [Parameter(Mandatory=$true)][string]$XmlPath,
        [Parameter(Mandatory=$true)][string]$P7bPath
    )
    if (-not (Test-ConfigCiModuleAvailable)) {
        throw 'ConfigCI module is required to compile WDAC XML to .p7b.'
    }
    ConvertFrom-CIPolicy -XmlFilePath $XmlPath -BinaryFilePath $P7bPath -ErrorAction Stop | Out-Null
}

#####################################################################
# SECTION 8: Policy deployment + WMI activation
#####################################################################

function Install-SpfPolicy {
    # Copies our source .p7b to %WINDIR%\System32\CodeIntegrity\SiPolicy.p7b
    # and activates it via WMI (no reboot required when Rule Option 16
    # "Update Policy No Reboot" is set).
    param(
        [Parameter(Mandatory=$true)][string]$SourceP7bPath
    )
    if (-not (Test-Path -LiteralPath $SourceP7bPath -PathType Leaf)) {
        throw ('Source .p7b not found at {0}.' -f $SourceP7bPath)
    }

    # Copy to deploy path
    $deployDir = Split-Path -Parent -Path $Script:DeployedPolicyPath
    if (-not (Test-Path -LiteralPath $deployDir)) {
        $null = New-Item -ItemType Directory -Path $deployDir -Force
    }
    Copy-Item -LiteralPath $SourceP7bPath -Destination $Script:DeployedPolicyPath -Force

    # Activate via WMI PS_UpdateAndCompareCIPolicy.Update()
    $activationMethod = Invoke-WmiCiPolicyUpdate -PolicyPath $Script:DeployedPolicyPath
    return [pscustomobject]@{
        DeployedPath     = $Script:DeployedPolicyPath
        DeployedSha256   = (Get-FileSha256Hex -Path $Script:DeployedPolicyPath)
        ActivationMethod = $activationMethod
    }
}

function Invoke-WmiCiPolicyUpdate {
    # Invokes the WMI method PS_UpdateAndCompareCIPolicy.Update() which
    # tells the kernel to reload the SPF policy without a reboot.
    # Available on WS2019/2016 and is the documented mechanism for
    # SPF refresh on those OSes.
    param(
        [Parameter(Mandatory=$true)][string]$PolicyPath
    )

    $ns = 'root\Microsoft\Windows\CI'
    $cls = 'PS_UpdateAndCompareCIPolicy'

    # Verify WMI namespace exists
    try {
        $null = Get-CimClass -Namespace $ns -ClassName $cls -ErrorAction Stop
    } catch {
        throw ('WMI class {0}\{1} not available on this host. ' +
               'A reboot will be required to activate the policy. ' +
               'Underlying error: {2}') -f $ns, $cls, $_.Exception.Message
    }

    # Invoke the Update method
    try {
        $result = Invoke-CimMethod -Namespace $ns -ClassName $cls `
            -MethodName 'Update' -Arguments @{ FilePath = $PolicyPath } -ErrorAction Stop
        if ($result.ReturnValue -ne 0) {
            throw ('PS_UpdateAndCompareCIPolicy.Update() returned ReturnValue={0}.' -f $result.ReturnValue)
        }
        return 'WMI-PS_UpdateAndCompareCIPolicy'
    } catch {
        throw ('WMI activation of SPF policy failed: {0}. A reboot will be required to activate the policy.' -f $_.Exception.Message)
    }
}

function Uninstall-SpfPolicy {
    # Deletes the deployed SiPolicy.p7b. There is no direct "remove"
    # WMI method for SPF; the documented procedure is to deploy an
    # empty AllowAll-as-base (no restrictions) and then delete the
    # file. For our case where the policy was authoring trust for
    # self-signed drivers, simply removing the file restores the
    # default Code Integrity behavior (kernel-mode drivers must be
    # Microsoft- or WHQL-signed).
    if (Test-Path -LiteralPath $Script:DeployedPolicyPath -PathType Leaf) {
        Remove-Item -LiteralPath $Script:DeployedPolicyPath -Force -ErrorAction Stop
    }
    # Best-effort: trigger a WMI refresh against a known-empty path.
    # Some build levels accept passing a path to a freshly-empty file.
    # We don't fail Uninstall just because the refresh path is
    # unavailable - the next reboot will pick up the file deletion.
    try {
        $empty = Join-Path $env:TEMP ('ddws-wdac-empty-{0}.p7b' -f ([guid]::NewGuid()))
        Set-Content -LiteralPath $empty -Value ([byte[]]@()) -AsByteStream -Force -ErrorAction SilentlyContinue
        if (-not (Test-Path -LiteralPath $empty)) {
            # PS 5 (no -AsByteStream) fallback
            [System.IO.File]::WriteAllBytes($empty, [byte[]]@())
        }
        $null = Invoke-CimMethod -Namespace 'root\Microsoft\Windows\CI' -ClassName 'PS_UpdateAndCompareCIPolicy' `
            -MethodName 'Update' -Arguments @{ FilePath = $empty } -ErrorAction SilentlyContinue
        Remove-Item -LiteralPath $empty -Force -ErrorAction SilentlyContinue
    } catch { }
}

function Backup-ForeignPolicy {
    # Copies the deployed (foreign) SiPolicy.p7b to ProgramData\backups\
    # with timestamp + state in the filename, and returns a record to
    # be embedded in the manifest under foreignPolicyBackup.
    Initialize-WdacDirectoryStructure
    $ts = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH-mm-ssZ')
    $backupName = ('{0}-foreign-policy.p7b.bak' -f $ts)
    $backupPath = Join-Path $Script:BackupsDir $backupName
    Copy-Item -LiteralPath $Script:DeployedPolicyPath -Destination $backupPath -Force
    return [pscustomobject]@{
        backupPath       = $backupPath
        backupSha256     = (Get-FileSha256Hex -Path $backupPath)
        backedUpAt       = (New-IsoTimestamp)
        originalDeployPath = $Script:DeployedPolicyPath
    }
}

function Restore-ForeignPolicyBackup {
    # Restores a previously-backed-up foreign policy onto the deploy
    # path. Used by Uninstall -RestoreForeignBackup. Returns the path
    # of the backup that was restored (or $null if none).
    param([Parameter(Mandatory=$true)]$Backup)
    if (-not $Backup -or -not $Backup.backupPath) {
        return $null
    }
    if (-not (Test-Path -LiteralPath $Backup.backupPath -PathType Leaf)) {
        throw ('Foreign policy backup not found at {0}.' -f $Backup.backupPath)
    }
    Copy-Item -LiteralPath $Backup.backupPath -Destination $Script:DeployedPolicyPath -Force
    # WMI refresh
    try {
        $null = Invoke-WmiCiPolicyUpdate -PolicyPath $Script:DeployedPolicyPath
    } catch {
        Write-Warn2 ('WMI refresh after foreign restore failed; the policy will become active at next reboot. {0}' -f $_.Exception.Message)
    }
    return $Backup.backupPath
}

#####################################################################
# SECTION 9: Action handler - GetStatus
#####################################################################

function Invoke-ActionGetStatus {
    $detail = Get-WdacState

    Set-JsonResult -Result 'success' -State $detail.state -Message ('State: {0}' -f $detail.state) -ExitCode 0 -Details @{
        deployedPath           = $detail.deployedPath
        deployedExists         = $detail.deployedExists
        deployedSha256         = $detail.deployedSha256
        sourceP7bExists        = $detail.sourceP7bExists
        sourceP7bSha256        = $detail.sourceP7bSha256
        sourceXmlExists        = $detail.sourceXmlExists
        manifestPath           = $Script:ManifestPath
        manifestExists         = $detail.manifestExists
        manifestInconsistent   = $detail.manifestInconsistent
        manifestPolicyId       = $detail.manifestPolicyId
        manifestRecordedSha256 = $detail.manifestRecordedSha256
        authorizedCerts        = $detail.authorizedCerts
        expiringCerts          = $detail.expiringCerts
        foreignPolicyBackup    = $detail.foreignPolicyBackup
        recommendations        = $detail.recommendations
        checkedCertThumbprint  = if ($CheckCertThumbprint) { $CheckCertThumbprint.ToUpper() } else { $null }
        checkedCertPresent     = if ($CheckCertThumbprint) {
                                    [bool]($detail.authorizedCerts | Where-Object { $_.thumbprint -eq $CheckCertThumbprint.ToUpper() })
                                 } else { $null }
    }

    if (_IsTextMode) {
        Write-Host ''
        Write-Host '=======================================================================' -ForegroundColor Cyan
        Write-Host '  WDAC SINGLE POLICY FORMAT - STATUS' -ForegroundColor Cyan
        Write-Host '=======================================================================' -ForegroundColor Cyan
        Write-Host ('  State              : {0}' -f $detail.state) -ForegroundColor $(switch ($detail.state) {
            'Ours-Healthy' { 'Green' }
            'None'         { 'Gray' }
            'Foreign'      { 'Yellow' }
            'Ours-Stale'   { 'Yellow' }
            'Ours-Tampered'{ 'Yellow' }
            'Inconsistent' { 'Red' }
            default         { 'White' }
        })
        Write-Host ('  Deployed path      : {0}' -f $detail.deployedPath)
        Write-Host ('  Deployed exists    : {0}' -f $detail.deployedExists)
        if ($detail.deployedSha256) {
            Write-Host ('  Deployed SHA256    : {0}' -f $detail.deployedSha256)
        }
        Write-Host ('  Source .p7b exists : {0}' -f $detail.sourceP7bExists)
        if ($detail.sourceP7bSha256) {
            Write-Host ('  Source SHA256      : {0}' -f $detail.sourceP7bSha256)
        }
        Write-Host ('  Manifest path      : {0}' -f $Script:ManifestPath)
        Write-Host ('  Manifest exists    : {0}' -f $detail.manifestExists)
        if ($detail.manifestInconsistent) {
            Write-Host '  Manifest status    : INCONSISTENT (parse failed or invalid schema)' -ForegroundColor Red
        }
        Write-Host ''
        Write-Host ('  Authorized certs ({0}):' -f $detail.authorizedCerts.Count)
        foreach ($c in $detail.authorizedCerts) {
            Write-Host ('    - {0}' -f $c.thumbprint) -ForegroundColor Gray
            Write-Host ('      Subject : {0}' -f $c.subject)         -ForegroundColor DarkGray
            Write-Host ('      Added by: {0} ({1})' -f $c.addedBy, $c.addedByVersion) -ForegroundColor DarkGray
            Write-Host ('      Added at: {0}' -f $c.addedAt)         -ForegroundColor DarkGray
            if ($c.validTo) {
                Write-Host ('      Valid   : {0} - {1}' -f $c.validFrom, $c.validTo) -ForegroundColor DarkGray
            }
        }
        if ($detail.expiringCerts.Count -gt 0) {
            Write-Host ''
            Write-Host ('  Expiring soon ({0}):' -f $detail.expiringCerts.Count) -ForegroundColor Yellow
            foreach ($e in $detail.expiringCerts) {
                $tag = if ($e.expired) { '*EXPIRED*' } else { ('{0} days remaining' -f $e.daysToExpiry) }
                Write-Host ('    - {0} ({1})' -f $e.thumbprint, $tag) -ForegroundColor Yellow
            }
        }
        if ($CheckCertThumbprint) {
            $present = [bool]($detail.authorizedCerts | Where-Object { $_.thumbprint -eq $CheckCertThumbprint.ToUpper() })
            Write-Host ''
            Write-Host ('  Cross-check for {0}: {1}' -f $CheckCertThumbprint.ToUpper(), $(if ($present) { 'PRESENT' } else { 'ABSENT' })) -ForegroundColor $(if ($present) { 'Green' } else { 'Yellow' })
        }
        if ($detail.foreignPolicyBackup) {
            Write-Host ''
            Write-Host '  Foreign policy backup recorded:' -ForegroundColor Yellow
            Write-Host ('    backupPath: {0}' -f $detail.foreignPolicyBackup.backupPath) -ForegroundColor DarkGray
            Write-Host ('    backedUpAt: {0}' -f $detail.foreignPolicyBackup.backedUpAt) -ForegroundColor DarkGray
        }
        if ($detail.recommendations.Count -gt 0) {
            Write-Host ''
            Write-Host '  Recommendations:' -ForegroundColor Cyan
            foreach ($r in $detail.recommendations) {
                Write-Host ('    - {0}' -f $r) -ForegroundColor Gray
            }
        }
        Write-Host '=======================================================================' -ForegroundColor Cyan
    }
}

#####################################################################
# SECTION 10: Action handler - AddCert
#####################################################################

function Invoke-ActionAddCert {
    # Pre-flight argument validation
    if ([string]::IsNullOrEmpty($CertFile)) {
        throw '-CertFile is required for Action=AddCert.'
    }
    if (-not (Test-Path -LiteralPath $CertFile -PathType Leaf)) {
        throw ('CertFile not found at {0}.' -f $CertFile)
    }
    if ([string]::IsNullOrEmpty($CallerScript)) {
        throw '-CallerScript is required for Action=AddCert (records provenance in the manifest).'
    }

    $stateBefore = (Get-WdacState).state
    Set-JsonResult -StateBefore $stateBefore

    # Foreign requires explicit override
    if ($stateBefore -eq 'Foreign' -and -not $ForceOverrideForeign) {
        $msg = ('Foreign WDAC policy detected at {0}. -ForceOverrideForeign is required to back up the foreign policy and replace it with ours.' -f $Script:DeployedPolicyPath)
        Set-JsonResult -Result 'refused' -State $stateBefore -Message $msg -ExitCode 2
        throw $msg
    }
    if ($stateBefore -eq 'Ours-Tampered' -and -not $Force) {
        $msg = 'Deployed SiPolicy.p7b has been tampered with (does not match our source). Pass -Force to redeploy from our source.'
        Set-JsonResult -Result 'refused' -State $stateBefore -Message $msg -ExitCode 2
        throw $msg
    }
    if ($stateBefore -eq 'Inconsistent') {
        $msg = 'Manifest is inconsistent. Run -Action Repair first.'
        Set-JsonResult -Result 'refused' -State $stateBefore -Message $msg -ExitCode 2
        throw $msg
    }

    Initialize-WdacDirectoryStructure

    # Load existing manifest or start fresh
    $r = Read-Manifest
    if ($r.Manifest) {
        $manifest = $r.Manifest
    } else {
        $manifest = New-EmptyManifest
    }

    # Identify the incoming cert
    $info = Get-CertInfoFromCer -Path $CertFile
    $thumb = $info.Thumbprint

    # Foreign override: back up the existing policy before replacing
    if ($stateBefore -eq 'Foreign') {
        Write-Step 'Backing up the foreign policy before replacement...'
        $backup = Backup-ForeignPolicy
        $manifest.foreignPolicyBackup = $backup
        Write-Ok ('Foreign policy backed up to {0}' -f $backup.backupPath)
    }

    # Check if cert already authorized (idempotent EC-4)
    $existing = @($manifest.authorizedCerts | Where-Object { $_.thumbprint -eq $thumb })

    if ($existing.Count -gt 0 -and $stateBefore -eq 'Ours-Healthy') {
        Write-Skip ('Certificate {0} is already authorized in the policy.' -f $thumb)
        Set-JsonResult -Result 'success' -State $stateBefore -StateAfter $stateBefore -NoOp $true `
            -Message 'Cert already authorized; no-op.' -ExitCode 0 -Details @{
            certThumbprint = $thumb
            certSubject    = $info.Subject
        }
        Add-HistoryEntry -Manifest $manifest -ActionName 'AddCert' `
            -CertThumbprint $thumb -Caller $CallerScript -CallerVersion $CallerScriptVersion `
            -StateBefore $stateBefore -StateAfter $stateBefore `
            -ResultingSha256 (Get-FileSha256Hex -Path $Script:DeployedPolicyPath)
        Save-Manifest -Manifest $manifest
        return
    }

    # EC-5: Same callerScript, different thumbprint
    if ($ReplaceExistingFromCaller -and $existing.Count -eq 0) {
        $sameCaller = @($manifest.authorizedCerts | Where-Object {
            $_.addedBy -and (Split-Path -Leaf -Path $_.addedBy) -eq (Split-Path -Leaf -Path $CallerScript)
        })
        if ($sameCaller.Count -gt 0) {
            Write-Step ('-ReplaceExistingFromCaller: removing {0} prior cert(s) from same caller before append.' -f $sameCaller.Count)
            $keep = @($manifest.authorizedCerts | Where-Object {
                -not ($_.addedBy -and (Split-Path -Leaf -Path $_.addedBy) -eq (Split-Path -Leaf -Path $CallerScript))
            })
            $manifest.authorizedCerts = $keep
        }
    }

    # Copy cert to ProgramData
    Write-Step ('Copying {0} to {1}...' -f $CertFile, $Script:CertsDir)
    $certCopyPath = Copy-CertToProgramData -SourceCer $CertFile -Thumbprint $thumb

    # Append new authorizedCert entry (if not already present)
    if ($existing.Count -eq 0) {
        $entry = [pscustomobject]@{
            thumbprint       = $thumb
            subject          = $info.Subject
            tbsHash          = $info.TbsHash
            cerFilePath      = $certCopyPath
            cerFileOrigin    = $CertFile
            validFrom        = $info.ValidFrom
            validTo          = $info.ValidTo
            addedBy          = (Split-Path -Leaf -Path $CallerScript)
            addedByVersion   = $CallerScriptVersion
            addedAt          = (New-IsoTimestamp)
        }
        $manifest.authorizedCerts = @() + $manifest.authorizedCerts + $entry
    }

    # Regenerate the source policy XML + .p7b from all current
    # authorizedCerts (the cert copies in $Script:CertsDir).
    Write-Step 'Regenerating WDAC source XML from all authorized certs...'
    $cerList = @()
    foreach ($c in $manifest.authorizedCerts) {
        if (Test-Path -LiteralPath $c.cerFilePath) {
            $cerList += $c.cerFilePath
        } elseif ($c.cerFileOrigin -and (Test-Path -LiteralPath $c.cerFileOrigin)) {
            $cerList += $c.cerFileOrigin
        }
    }
    if ($cerList.Count -eq 0) {
        throw 'No usable .cer files found for any of the authorized certs.'
    }
    New-WdacPolicyXml -CerFiles $cerList -OutputXmlPath $Script:SourceXmlPath -AuditMode:$AuditMode.IsPresent

    Write-Step 'Compiling XML to .p7b...'
    ConvertFrom-WdacPolicyXmlToP7b -XmlPath $Script:SourceXmlPath -P7bPath $Script:SourceP7bPath

    # Update manifest.policy block
    $newSha = Get-FileSha256Hex -Path $Script:SourceP7bPath
    $newVer = Get-PolicyVersionEx -Manifest $manifest
    if (-not $manifest.policy) {
        $manifest.policy = [pscustomobject]@{
            policyId         = $Script:ReservedPolicyId
            deployPath       = $Script:DeployedPolicyPath
            deployedSha256   = $null
            sourceXmlPath    = $Script:SourceXmlPath
            sourceP7bPath    = $Script:SourceP7bPath
            sourceP7bSha256  = $newSha
            versionEx        = $newVer
            auditMode        = [bool]$AuditMode.IsPresent
        }
    } else {
        $manifest.policy.sourceP7bSha256 = $newSha
        $manifest.policy.versionEx       = $newVer
        $manifest.policy.auditMode       = [bool]$AuditMode.IsPresent
    }

    # Deploy
    Write-Step 'Deploying SiPolicy.p7b to %WINDIR%\System32\CodeIntegrity\ and activating via WMI...'
    $deploy = Install-SpfPolicy -SourceP7bPath $Script:SourceP7bPath
    $manifest.policy.deployedSha256 = $deploy.DeployedSha256

    Add-HistoryEntry -Manifest $manifest -ActionName 'AddCert' `
        -CertThumbprint $thumb -Caller $CallerScript -CallerVersion $CallerScriptVersion `
        -StateBefore $stateBefore -StateAfter 'Ours-Healthy' `
        -ResultingSha256 $deploy.DeployedSha256

    Save-Manifest -Manifest $manifest

    Write-Ok ('Policy deployed. State: {0} -> Ours-Healthy' -f $stateBefore)
    Write-Detail ('Activation method: {0}' -f $deploy.ActivationMethod)
    Write-Detail ('Deployed SHA256  : {0}' -f $deploy.DeployedSha256)

    Set-JsonResult -Result 'success' -State 'Ours-Healthy' -StateBefore $stateBefore -StateAfter 'Ours-Healthy' `
        -NoOp $false -Message ('AddCert succeeded; state transitioned to Ours-Healthy.') -ExitCode 0 -Details @{
        certThumbprint     = $thumb
        certSubject        = $info.Subject
        activationMethod   = $deploy.ActivationMethod
        deployedSha256     = $deploy.DeployedSha256
        sourceP7bSha256    = $newSha
        policyId           = $Script:ReservedPolicyId
        versionEx          = $newVer
        auditMode          = [bool]$AuditMode.IsPresent
        authorizedCertCount= $manifest.authorizedCerts.Count
    }
}

#####################################################################
# SECTION 11: Action handler - RemoveCert
#####################################################################

function Invoke-ActionRemoveCert {
    if ([string]::IsNullOrEmpty($CertThumbprint)) {
        throw '-CertThumbprint is required for Action=RemoveCert.'
    }
    $thumb = $CertThumbprint.ToUpper()

    $stateBefore = (Get-WdacState).state
    Set-JsonResult -StateBefore $stateBefore

    if ($stateBefore -in @('Foreign','Ours-Tampered','Inconsistent') -and -not $Force) {
        $msg = ('Cannot RemoveCert when state is {0} without -Force.' -f $stateBefore)
        Set-JsonResult -Result 'refused' -State $stateBefore -Message $msg -ExitCode 2
        throw $msg
    }

    $r = Read-Manifest
    if (-not $r.Manifest) {
        $msg = 'No manifest found; nothing to remove.'
        Write-Skip $msg
        Set-JsonResult -Result 'success' -State $stateBefore -StateAfter $stateBefore `
            -NoOp $true -Message $msg -ExitCode 0
        return
    }
    $manifest = $r.Manifest

    $remaining = @($manifest.authorizedCerts | Where-Object { $_.thumbprint -ne $thumb })
    if ($remaining.Count -eq $manifest.authorizedCerts.Count) {
        # No match - idempotent no-op
        Write-Skip ('Thumbprint {0} not in manifest; no-op.' -f $thumb)
        Set-JsonResult -Result 'success' -State $stateBefore -StateAfter $stateBefore `
            -NoOp $true -Message 'Thumbprint not in manifest; no-op.' -ExitCode 0
        return
    }
    $manifest.authorizedCerts = $remaining

    if ($remaining.Count -eq 0) {
        # P2 decision: last cert removal triggers full policy uninstall
        Write-Step ('Last cert removed. Uninstalling policy (P2 default behavior).')
        Uninstall-SpfPolicy
        # Wipe manifest.policy block but keep history
        $manifest.policy = $null
        Add-HistoryEntry -Manifest $manifest -ActionName 'RemoveCert+AutoUninstall' `
            -CertThumbprint $thumb -StateBefore $stateBefore -StateAfter 'None' `
            -ResultingSha256 ''
        Save-Manifest -Manifest $manifest

        # Optional: also remove .cer copies and source files for hygiene
        foreach ($f in @($Script:SourceP7bPath, $Script:SourceXmlPath)) {
            if (Test-Path -LiteralPath $f) { Remove-Item -LiteralPath $f -Force }
        }

        Write-Ok ('State transitioned: {0} -> None' -f $stateBefore)
        Set-JsonResult -Result 'success' -State 'None' -StateBefore $stateBefore -StateAfter 'None' `
            -NoOp $false -Message 'Last cert removed; policy fully uninstalled.' -ExitCode 0
        return
    }

    # Re-generate XML / .p7b from remaining certs and redeploy
    Write-Step ('Regenerating policy XML with {0} remaining cert(s)...' -f $remaining.Count)
    $cerList = @()
    foreach ($c in $remaining) {
        if (Test-Path -LiteralPath $c.cerFilePath) {
            $cerList += $c.cerFilePath
        } elseif ($c.cerFileOrigin -and (Test-Path -LiteralPath $c.cerFileOrigin)) {
            $cerList += $c.cerFileOrigin
        }
    }
    New-WdacPolicyXml -CerFiles $cerList -OutputXmlPath $Script:SourceXmlPath -AuditMode:([bool]$manifest.policy.auditMode)
    ConvertFrom-WdacPolicyXmlToP7b -XmlPath $Script:SourceXmlPath -P7bPath $Script:SourceP7bPath

    $newSha = Get-FileSha256Hex -Path $Script:SourceP7bPath
    $manifest.policy.sourceP7bSha256 = $newSha
    $manifest.policy.versionEx       = (Get-PolicyVersionEx -Manifest $manifest)

    $deploy = Install-SpfPolicy -SourceP7bPath $Script:SourceP7bPath
    $manifest.policy.deployedSha256 = $deploy.DeployedSha256

    Add-HistoryEntry -Manifest $manifest -ActionName 'RemoveCert' `
        -CertThumbprint $thumb -StateBefore $stateBefore -StateAfter 'Ours-Healthy' `
        -ResultingSha256 $deploy.DeployedSha256
    Save-Manifest -Manifest $manifest

    Write-Ok ('Removed {0}; redeployed policy.' -f $thumb)
    Set-JsonResult -Result 'success' -State 'Ours-Healthy' -StateBefore $stateBefore -StateAfter 'Ours-Healthy' `
        -NoOp $false -Message ('Cert {0} removed; policy redeployed.' -f $thumb) -ExitCode 0
}

#####################################################################
# SECTION 12: Action handler - Verify
#####################################################################

function Invoke-ActionVerify {
    if ([string]::IsNullOrEmpty($CertThumbprint)) {
        throw '-CertThumbprint is required for Action=Verify.'
    }
    $thumb = $CertThumbprint.ToUpper()
    $detail = Get-WdacState

    $present = $false
    if ($detail.state -eq 'Ours-Healthy' -or $detail.state -eq 'Ours-Stale') {
        $present = [bool]($detail.authorizedCerts | Where-Object { $_.thumbprint -eq $thumb })
    }

    if ($present) {
        Write-Ok ('Certificate {0} is authorized (state={1}).' -f $thumb, $detail.state)
        Set-JsonResult -Result 'success' -State $detail.state -Message ('Authorized.') -ExitCode 0 -Details @{
            certThumbprint = $thumb
            certPresent    = $true
            state          = $detail.state
        }
    } else {
        Write-Warn2 ('Certificate {0} is NOT authorized (state={1}).' -f $thumb, $detail.state)
        Set-JsonResult -Result 'absent' -State $detail.state -Message ('Not authorized.') -ExitCode 1 -Details @{
            certThumbprint = $thumb
            certPresent    = $false
            state          = $detail.state
        }
    }
}

#####################################################################
# SECTION 13: Action handler - Uninstall
#####################################################################

function Invoke-ActionUninstall {
    $stateBefore = (Get-WdacState).state
    Set-JsonResult -StateBefore $stateBefore

    if ($stateBefore -eq 'Foreign' -and -not $ForceOverrideForeign) {
        $msg = 'Refusing to Uninstall a Foreign policy without -ForceOverrideForeign.'
        Set-JsonResult -Result 'refused' -State $stateBefore -Message $msg -ExitCode 2
        throw $msg
    }
    if ($stateBefore -eq 'Ours-Tampered' -and -not $Force) {
        $msg = 'Refusing to Uninstall a tampered policy without -Force.'
        Set-JsonResult -Result 'refused' -State $stateBefore -Message $msg -ExitCode 2
        throw $msg
    }
    if ($stateBefore -eq 'Inconsistent' -and -not $Force) {
        $msg = 'Manifest is Inconsistent. Use -Action Repair, or -Action Uninstall -Force to forcibly clear all WDAC state managed by this script.'
        Set-JsonResult -Result 'refused' -State $stateBefore -Message $msg -ExitCode 2
        throw $msg
    }

    $r = Read-Manifest
    $manifest = $r.Manifest

    # Foreign override -> backup before delete
    $backup = $null
    if ($stateBefore -eq 'Foreign' -and $ForceOverrideForeign) {
        Write-Step 'Backing up the foreign policy before removal...'
        $backup = Backup-ForeignPolicy
        Write-Ok ('Foreign policy backed up to {0}' -f $backup.backupPath)
    }

    # Delete the deployed policy
    if (Test-Path -LiteralPath $Script:DeployedPolicyPath) {
        Write-Step ('Removing {0}...' -f $Script:DeployedPolicyPath)
        Uninstall-SpfPolicy
        Write-Ok 'Deployed SiPolicy.p7b removed.'
    } else {
        Write-Skip 'Deployed SiPolicy.p7b already absent.'
    }

    # If restoring a foreign backup, do that next
    if ($RestoreForeignBackup) {
        $bk = if ($backup) { $backup } elseif ($manifest -and $manifest.foreignPolicyBackup) { $manifest.foreignPolicyBackup } else { $null }
        if ($bk) {
            Write-Step ('Restoring foreign policy backup from {0}...' -f $bk.backupPath)
            $null = Restore-ForeignPolicyBackup -Backup $bk
            Write-Ok 'Foreign policy backup restored.'
        } else {
            Write-Warn2 'No foreign backup recorded; -RestoreForeignBackup ignored.'
        }
    }

    # Delete source files
    foreach ($f in @($Script:SourceP7bPath, $Script:SourceXmlPath)) {
        if (Test-Path -LiteralPath $f) {
            Remove-Item -LiteralPath $f -Force -ErrorAction SilentlyContinue
        }
    }

    # Delete manifest (full uninstall) - or update it (partial)
    if ($manifest -and $manifest.deploymentHistory) {
        # Keep last history by writing an empty-but-historical manifest
        $manifest.policy          = $null
        $manifest.authorizedCerts = @()
        Add-HistoryEntry -Manifest $manifest -ActionName 'Uninstall' `
            -StateBefore $stateBefore -StateAfter 'None' -ResultingSha256 ''
        # Then delete
        Save-Manifest -Manifest $manifest
    }
    if (Test-Path -LiteralPath $Script:ManifestPath) {
        Remove-Item -LiteralPath $Script:ManifestPath -Force
    }
    # Optionally clear certs directory (hygiene) - keep backups dir
    if (Test-Path -LiteralPath $Script:CertsDir) {
        Get-ChildItem -LiteralPath $Script:CertsDir -Filter '*.cer' -ErrorAction SilentlyContinue |
            ForEach-Object { Remove-Item -LiteralPath $_.FullName -Force -ErrorAction SilentlyContinue }
    }

    Write-Ok ('State transitioned: {0} -> None' -f $stateBefore)
    Set-JsonResult -Result 'success' -State 'None' -StateBefore $stateBefore -StateAfter 'None' `
        -NoOp $false -Message 'Uninstall complete.' -ExitCode 0 -Details @{
        foreignBackup = if ($backup) { $backup } else { $null }
        restoredForeignBackup = [bool]$RestoreForeignBackup
    }
}

#####################################################################
# SECTION 14: Action handler - Repair
#####################################################################

function Invoke-ActionRepair {
    $stateBefore = (Get-WdacState).state
    Set-JsonResult -StateBefore $stateBefore

    Write-Step ('Repair: starting from state {0}.' -f $stateBefore)

    switch ($stateBefore) {
        'Ours-Healthy' {
            Write-Ok 'State is already Ours-Healthy; nothing to repair.'
            Set-JsonResult -Result 'success' -State $stateBefore -StateAfter $stateBefore `
                -NoOp $true -Message 'No repair needed.' -ExitCode 0
            return
        }
        'None' {
            Write-Ok 'State is None; nothing to repair.'
            Set-JsonResult -Result 'success' -State $stateBefore -StateAfter $stateBefore `
                -NoOp $true -Message 'No repair needed.' -ExitCode 0
            return
        }
        'Ours-Stale' {
            # Redeploy from source .p7b
            Write-Step 'Ours-Stale: redeploying from source .p7b...'
            if (-not (Test-Path -LiteralPath $Script:SourceP7bPath)) {
                throw 'Source .p7b is missing; cannot repair Ours-Stale automatically. Re-run a driver script -Action Install which will re-add its cert via AddCert.'
            }
            $deploy = Install-SpfPolicy -SourceP7bPath $Script:SourceP7bPath
            $r = Read-Manifest
            if ($r.Manifest) {
                if ($r.Manifest.policy) {
                    $r.Manifest.policy.deployedSha256 = $deploy.DeployedSha256
                }
                Add-HistoryEntry -Manifest $r.Manifest -ActionName 'Repair' `
                    -StateBefore $stateBefore -StateAfter 'Ours-Healthy' `
                    -ResultingSha256 $deploy.DeployedSha256
                Save-Manifest -Manifest $r.Manifest
            }
            Write-Ok 'Ours-Stale repaired.'
            Set-JsonResult -Result 'success' -State 'Ours-Healthy' -StateBefore $stateBefore -StateAfter 'Ours-Healthy' `
                -NoOp $false -Message 'Ours-Stale repaired.' -ExitCode 0
            return
        }
        'Inconsistent' {
            Write-Step 'Inconsistent: attempting to rebuild from cert files in ProgramData\certs\...'
            if (-not (Test-Path -LiteralPath $Script:CertsDir)) {
                throw ('No certs directory at {0}; cannot rebuild. Run -Action Uninstall -Force to fully clear and start over.' -f $Script:CertsDir)
            }
            $cerFiles = @(Get-ChildItem -LiteralPath $Script:CertsDir -Filter '*.cer' -ErrorAction SilentlyContinue)
            if ($cerFiles.Count -eq 0) {
                throw ('No .cer files found in {0}; cannot rebuild. Run -Action Uninstall -Force to fully clear.' -f $Script:CertsDir)
            }
            # Rebuild manifest from scratch using the .cer files we have
            $m = New-EmptyManifest
            foreach ($cf in $cerFiles) {
                $info = Get-CertInfoFromCer -Path $cf.FullName
                $entry = [pscustomobject]@{
                    thumbprint    = $info.Thumbprint
                    subject       = $info.Subject
                    tbsHash       = $info.TbsHash
                    cerFilePath   = $cf.FullName
                    cerFileOrigin = $cf.FullName
                    validFrom     = $info.ValidFrom
                    validTo       = $info.ValidTo
                    addedBy       = '(recovered-from-cer-file)'
                    addedByVersion= ''
                    addedAt       = (New-IsoTimestamp)
                }
                $m.authorizedCerts = @() + $m.authorizedCerts + $entry
            }
            New-WdacPolicyXml -CerFiles ($cerFiles | ForEach-Object FullName) `
                -OutputXmlPath $Script:SourceXmlPath -AuditMode:$false
            ConvertFrom-WdacPolicyXmlToP7b -XmlPath $Script:SourceXmlPath -P7bPath $Script:SourceP7bPath
            $newSha = Get-FileSha256Hex -Path $Script:SourceP7bPath
            $m.policy = [pscustomobject]@{
                policyId         = $Script:ReservedPolicyId
                deployPath       = $Script:DeployedPolicyPath
                deployedSha256   = $null
                sourceXmlPath    = $Script:SourceXmlPath
                sourceP7bPath    = $Script:SourceP7bPath
                sourceP7bSha256  = $newSha
                versionEx        = '10.0.0.1'
                auditMode        = $false
            }
            $deploy = Install-SpfPolicy -SourceP7bPath $Script:SourceP7bPath
            $m.policy.deployedSha256 = $deploy.DeployedSha256
            Add-HistoryEntry -Manifest $m -ActionName 'Repair (rebuild)' `
                -StateBefore $stateBefore -StateAfter 'Ours-Healthy' `
                -ResultingSha256 $deploy.DeployedSha256
            Save-Manifest -Manifest $m
            Write-Ok 'Manifest rebuilt and policy redeployed.'
            Set-JsonResult -Result 'success' -State 'Ours-Healthy' -StateBefore $stateBefore -StateAfter 'Ours-Healthy' `
                -NoOp $false -Message 'Inconsistent repaired via cert-file rebuild.' -ExitCode 0
            return
        }
        default {
            throw ('Cannot Repair from state {0}. Foreign and Ours-Tampered require explicit user intervention (-Action AddCert -ForceOverrideForeign / -Force, or -Action Uninstall).' -f $stateBefore)
        }
    }
}

#####################################################################
# SECTION 15: Action handler - ComputeCanonicalHash
#####################################################################

function Invoke-ActionComputeCanonicalHash {
    if ([string]::IsNullOrEmpty($File)) {
        throw '-File is required for Action=ComputeCanonicalHash.'
    }
    if (-not (Test-Path -LiteralPath $File -PathType Leaf)) {
        throw ('-File path not found: {0}' -f $File)
    }
    $h = Get-CanonicalScriptHash -Path $File
    if (_IsTextMode) {
        Write-Host ('Canonical SHA256 of {0}:' -f $File) -ForegroundColor Cyan
        Write-Host ('    {0}' -f $h) -ForegroundColor Green
        Write-Host ''
        Write-Host 'Embed this value into the calling driver scripts'' $Script:ExpectedWdacScriptCanonicalSha256 constant.' -ForegroundColor DarkGray
    }
    Set-JsonResult -Result 'success' -Message 'Canonical hash computed.' -ExitCode 0 -Details @{
        file = $File
        canonicalSha256 = $h
    }
}

function Invoke-ActionComputeOwnCanonicalHash {
    $self = $PSCommandPath
    if ([string]::IsNullOrEmpty($self)) { $self = $MyInvocation.MyCommand.Path }
    $h = Get-SelfCanonicalHash
    if (_IsTextMode) {
        Write-Host 'Canonical SHA256 of this script:' -ForegroundColor Cyan
        Write-Host ('    {0}' -f $h) -ForegroundColor Green
        Write-Host ''
        Write-Host ('Path: {0}' -f $self) -ForegroundColor DarkGray
        Write-Host 'Embed this value into the calling driver scripts'' $Script:ExpectedWdacScriptCanonicalSha256 constant.' -ForegroundColor DarkGray
    }
    Set-JsonResult -Result 'success' -Message 'Self canonical hash computed.' -ExitCode 0 -Details @{
        file = $self
        canonicalSha256 = $h
    }
}

#####################################################################
# SECTION 16: Help action
#####################################################################

function Invoke-ActionHelp {
    if (_IsJsonMode) {
        Set-JsonResult -Result 'success' -Message 'See -Action GetStatus for runtime state.' -ExitCode 0 -Details @{
            usage = 'See -Help / Get-Help'
            availableActions = @('GetStatus','AddCert','RemoveCert','Verify','Uninstall','Repair','ComputeCanonicalHash','ComputeOwnCanonicalHash')
            scriptVersion    = $Script:ScriptVersion
            selfCanonicalHash = (Get-SelfCanonicalHash)
        }
        return
    }
    Write-Host ''
    Write-Host '=======================================================================' -ForegroundColor Cyan
    Write-Host '  Deploy-WdacSinglePolicyFormatOnLegacyWindowsServer.ps1' -ForegroundColor Cyan
    Write-Host ('  Version: {0}' -f $Script:ScriptVersion) -ForegroundColor Cyan
    Write-Host '=======================================================================' -ForegroundColor Cyan
    Write-Host ''
    Write-Host '  Scope: Windows Server 2019 (build 17763) and Windows Server 2016'
    Write-Host '         (build 14393). NOT for WS2022 / WS2025 / Windows client SKUs.'
    Write-Host ''
    Write-Host '  Usage: .\Deploy-WdacSinglePolicyFormatOnLegacyWindowsServer.ps1 -Action <action> [args]'
    Write-Host ''
    Write-Host '  Available actions:' -ForegroundColor Cyan
    Write-Host '    GetStatus                Report current WDAC SPF state.'
    Write-Host '    AddCert                  Add a self-signing cert and (re)deploy policy.'
    Write-Host '    RemoveCert               Remove a cert (last cert -> full Uninstall).'
    Write-Host '    Verify                   Check whether a thumbprint is authorized.'
    Write-Host '    Uninstall                Remove the entire WDAC policy + manifest.'
    Write-Host '    Repair                   Recover from Inconsistent / Ours-Stale.'
    Write-Host '    ComputeCanonicalHash     Dev: compute canonical hash of arbitrary file.'
    Write-Host '    ComputeOwnCanonicalHash  Dev: emit canonical hash of THIS script.'
    Write-Host ''
    Write-Host '  See Get-Help .\Deploy-WdacSinglePolicyFormatOnLegacyWindowsServer.ps1 -Full' -ForegroundColor DarkGray
    Write-Host '  for complete parameter documentation.' -ForegroundColor DarkGray
    Write-Host ''
    Write-Host ('  Self canonical hash: {0}' -f (Get-SelfCanonicalHash)) -ForegroundColor DarkGray
    Write-Host ''
    Set-JsonResult -Result 'success' -Message 'Help displayed.' -ExitCode 0
}

#####################################################################
# SECTION 17: Main dispatcher
#####################################################################

function Invoke-Main {
    # Help shortcut from -Help_ switch
    if ($Help_) { $Action = 'Help' }

    # Banner (Text mode only)
    if ((_IsTextMode) -and $Action -ne 'Help') {
        Write-Host ''
        Write-Host ('=== Deploy-WdacSinglePolicyFormatOnLegacyWindowsServer ({0}) - Action: {1} ===' -f $Script:ScriptVersion, $Action) -ForegroundColor Cyan
        Write-Host ''
    }

    # OS guard (skips dev-helper Actions)
    Assert-LegacyWindowsServerHost | Out-Null

    switch ($Action) {
        'GetStatus'                { Invoke-ActionGetStatus }
        'AddCert'                  { Invoke-ActionAddCert }
        'RemoveCert'               { Invoke-ActionRemoveCert }
        'Verify'                   { Invoke-ActionVerify }
        'Uninstall'                { Invoke-ActionUninstall }
        'Repair'                   { Invoke-ActionRepair }
        'ComputeCanonicalHash'     { Invoke-ActionComputeCanonicalHash }
        'ComputeOwnCanonicalHash'  { Invoke-ActionComputeOwnCanonicalHash }
        'Help'                     { Invoke-ActionHelp }
        default                    { throw ('Unknown Action: {0}' -f $Action) }
    }
}

#####################################################################
# SECTION 18: Entry point with error trapping
#####################################################################

$Global:LASTEXITCODE_FROM_WDAC_SCRIPT = 0

try {
    Invoke-Main
}
catch {
    # Translate to JSON or text and set exit code.
    $code = 1
    if ($Script:JsonResult.exitCode -ne 0) { $code = [int]$Script:JsonResult.exitCode }
    if ($code -eq 0) { $code = 1 }
    if (_IsTextMode) {
        Write-Host ''
        Write-Host ('[X] FAILED: {0}' -f $_.Exception.Message) -ForegroundColor Red
        Write-Host ''
    }
    if ($Script:JsonResult.result -in @('unknown','')) {
        Set-JsonResult -Result 'error' -Message $_.Exception.Message -ExitCode $code
    } elseif ($Script:JsonResult.exitCode -eq 0) {
        Set-JsonResult -ExitCode $code -Message $_.Exception.Message
    }
    $Global:LASTEXITCODE_FROM_WDAC_SCRIPT = $code
    if (_IsJsonMode) { _EmitJson }
    # Use throw so $LASTEXITCODE picks up non-zero and try-catch in
    # caller works naturally.
    exit $code
}

# Success path
if (_IsJsonMode) { _EmitJson }
exit [int]$Script:JsonResult.exitCode
