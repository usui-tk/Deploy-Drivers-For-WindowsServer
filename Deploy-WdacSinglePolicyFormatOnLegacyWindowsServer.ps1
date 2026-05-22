<#
.SYNOPSIS
    Deploy a Single Policy Format (SPF) Windows Defender Application Control
    (WDAC) authorization policy on legacy Windows Server hosts (WS2019 build
    17763 and WS2016 build 14393) so self-signed device drivers produced by
    this repository's driver scripts (Chipset, Graphics, NPU, BthPan) can
    load while Secure Boot stays ON.

.DESCRIPTION
    -----------------------------------------------------------------
    SCOPE: Windows Server 2019 and Windows Server 2016 ONLY
    -----------------------------------------------------------------

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

    -----------------------------------------------------------------
    SISTER-SCRIPT INHERITANCE
    -----------------------------------------------------------------

    Per SPEC.md Appendix "How to seed a new sister script from this SPEC",
    this script is seeded from the production-validated
    Deploy-AMDChipsetDriverOnWindowsServer.ps1 (r66 baseline).

    All 34 shared-helper functions are inherited BYTE-FOR-BYTE
    VERBATIM from the four sister scripts. PSA8001 (cross-file
    function-body drift) actively enforces sync for 30 of them; the
    remaining 4 Secure Boot baseline diagnostic helpers are present in
    the `.psa.config.json` `psa8001_ignore_functions` list because
    those helpers reference `$Ctx.WorkRoot` / `$Ctx.Paths` indirectly
    via their call sites, and one or two variants exist across the
    four driver scripts; the orchestrator carries an inert copy
    (called nowhere in the orchestrator code path) so that any future
    PSA8001 enforcement uplift on those 4 sees a consistent baseline.

      Logging primitives (12)  -- PSA8001-enforced
        Format-Elapsed, _LogLine, Write-Step, Write-Ok, Write-Warn2,
        Write-Fail, Write-Skip, Write-Detail, Write-PhaseHeader,
        Write-PhaseFooter, Get-PhaseElapsedTag, Format-DebugFailure

      Debug Trace framework (12)  -- PSA8001-enforced
        _DebugTrace_NextSeq, _DebugTrace_Now, _DebugTrace_WriteJsonlLine,
        _DebugTrace_RetireFrame, Start-DebugTrace, Stop-DebugTrace,
        Set-DebugStep, Write-DebugFailureReport,
        Enable-DebugTraceFileOutput, Disable-DebugTraceFileOutput,
        Get-DebugTraceFileOutputStatus, Enable-AutoExportOnPhaseFailure

      Environment / preflight (5)  -- PSA8001-enforced
        Set-Tls12, Set-ConsoleUtf8, Assert-Admin,
        Assert-PowerShellCompatibility, Show-PowerShellEnvironment

      Secure Boot baseline diagnostic helpers (5)
        Format-SecureBootBaselineForReport  -- in psa8001_ignore_functions
        Get-SecureBootCertificateInventory  -- in psa8001_ignore_functions
        Get-MsSecureBootExampleScriptPath   -- in psa8001_ignore_functions
        Invoke-MsSecureBootDetectScript     -- in psa8001_ignore_functions
        Export-DebugTraceJson               -- PSA8001-enforced

    PSA8001 (cross-file function-body drift) enforces this invariant. When
    any of these functions is updated in one sister script, ALL FIVE
    scripts (four driver scripts plus this orchestrator) must be updated
    in lockstep.

    -----------------------------------------------------------------
    JSON OUTPUT MODE - PSA8001-SAFE DESIGN
    -----------------------------------------------------------------

    When invoked with -OutputFormat Json, this script keeps the human-
    facing Write-Step / Write-Ok / Write-Warn2 / Write-Fail / Write-Skip /
    Write-Detail output VERBATIM (they go to the host stream via
    Write-Host). The structured JSON envelope is emitted on the SUCCESS
    output stream (Write-Output) at the very end of the run.

    PowerShell separates these streams: when the orchestrator is invoked
    via `Start-Process powershell.exe -ArgumentList @(...) -RedirectStandardOutput <file>`,
    only Write-Output content is captured to <file>. The Write-Host log
    is visible to the operator but not in the captured stream.

    This separation is essential to keep the 6 logging helpers (PSA8001-
    enforced) byte-for-byte identical with the four driver scripts.

    -----------------------------------------------------------------
    EXIT CODES
    -----------------------------------------------------------------

      0 = success
      1 = generic failure
      2 = state mismatch (e.g., Foreign without -ForceOverrideForeign)
      3 = invalid arguments / OS guard refused
      4 = system error (WMI, file I/O, parse failure)

.PARAMETER Action
    The operation to perform. One of: GetStatus, AddCert, RemoveCert,
    Verify, Uninstall, Repair, ComputeCanonicalHash,
    ComputeOwnCanonicalHash, Help.

.PARAMETER CertFile
    Required for Action=AddCert. Path to the .cer file of the self-
    signing certificate to authorize.

.PARAMETER CertThumbprint
    Required for Action=RemoveCert and Action=Verify. The thumbprint
    (40 hex chars) of the cert to remove or verify.

.PARAMETER CallerScript
    Required for Action=AddCert. The path or filename of the calling
    driver script, recorded in the manifest for provenance.

.PARAMETER CallerScriptVersion
    Optional for Action=AddCert. Version string of the calling driver
    script (e.g., 'chipset-2026.05.22-r67').

.PARAMETER File
    Required for Action=ComputeCanonicalHash. Path to the file whose
    canonical (BOM-strip + CRLF-normalize) SHA256 to compute.

.PARAMETER Force
    For Action=AddCert: required when state is Ours-Tampered.
    For Action=RemoveCert / Uninstall: required to act on Ours-Tampered.

.PARAMETER ForceOverrideForeign
    For Action=AddCert / Uninstall: required to operate when state is
    Foreign. Triggers backup of the foreign policy before replacement.

.PARAMETER ReplaceExistingFromCaller
    For Action=AddCert: when the manifest already has a cert from the
    same CallerScript with a different thumbprint, replace 1:1 instead
    of appending.

.PARAMETER RestoreForeignBackup
    For Action=Uninstall: after removing our policy, restore the most
    recent foreign-policy backup.

.PARAMETER AuditMode
    For Action=AddCert: deploy the policy with WDAC Rule Option 3
    (Enabled:Audit Mode) so violations are logged but not enforced.

.PARAMETER OutputFormat
    'Text' (default, human-readable to host stream) or 'Json' (machine-
    parseable envelope on stdout, log on host stream).

.PARAMETER CheckCertThumbprint
    For Action=GetStatus: in addition to the standard state report,
    explicitly check whether this specific thumbprint is authorized.

.PARAMETER HistoryMaxEntries
    For internal use. Caps the deploymentHistory[] array in the manifest
    (default 50).

.EXAMPLE
    .\Deploy-WdacSinglePolicyFormatOnLegacyWindowsServer.ps1 -Action GetStatus

.EXAMPLE
    .\Deploy-WdacSinglePolicyFormatOnLegacyWindowsServer.ps1 `
        -Action AddCert `
        -CertFile 'C:\Temp\Workspace_AMD-Chipset\cert\AMD-Chipset-Driver-CodeSign.cer' `
        -CallerScript 'Deploy-AMDChipsetDriverOnWindowsServer.ps1' `
        -CallerScriptVersion 'chipset-2026.05.22-r67' `
        -OutputFormat Json

.EXAMPLE
    .\Deploy-WdacSinglePolicyFormatOnLegacyWindowsServer.ps1 -Action ComputeOwnCanonicalHash

.NOTES
    Repository    : https://github.com/usui-tk/Deploy-Drivers-For-WindowsServer
    Seeded from   : Deploy-AMDChipsetDriverOnWindowsServer.ps1 r66 (production-validated)
    SPEC          : See SPEC.md section D.25 for the design rationale and
                    SPEC.md Appendix for the sister-script seeding workflow.
    Static gate   : psa.py (see SPEC §A.11); see TESTING.md §11 for test cases.
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

    # === Output =======================================================
    [ValidateSet('Text','Json')]
    [string]$OutputFormat = 'Text',

    # === Manifest housekeeping ========================================
    [ValidateRange(1, 1000)]
    [int]$HistoryMaxEntries = 50
)

$ErrorActionPreference = 'Stop'
$ProgressPreference    = 'SilentlyContinue'

#####################################################################
# SECTION 0: Script-level timing state
#####################################################################
# Captured at script load time. Used by the run summary at the end of
# the dispatcher, by Write-PhaseHeader to mark per-phase start, and by
# Write-PhaseFooter to compute per-phase elapsed time.
$Script:ScriptStartTime   = Get-Date
$Script:CurrentPhaseStart = $null
$Script:CurrentPhaseId    = $null
$Script:PhaseTimings      = New-Object System.Collections.Generic.List[object]

#####################################################################
# Script version identification
#####################################################################
# These constants are bumped manually whenever the script is edited.
# They are displayed in the startup banner, in each phase header, and
# in the final run summary so the user can verify which revision is
# valid.
#
# ScriptVersion: bump on every meaningful edit. Format: YYYY.MM.DD-rNN
# ScriptTag: short human-readable label describing the build
# ScriptHash: auto-computed SHA256 (first 12 chars) of the actual
#                file being executed. Changes for any byte-level edit;
#                does NOT need manual bumping. If two users disagree
#                about behaviour, comparing this hash tells them
#                instantly whether they are running the same file.
$Script:ScriptVersion = 'wdac-2026.05.23-r03'
$Script:ScriptTag     = 'sister-script-seeded-from-chipset-r66'
$Script:ScriptHash    = '(unknown)'
try {
    # $PSCommandPath is the full path to the running script. Falls
    # back to MyInvocation if not available (e.g. dot-sourced).
    $scriptPath = $PSCommandPath
    if ([string]::IsNullOrEmpty($scriptPath)) {
        $scriptPath = $MyInvocation.MyCommand.Path
    }
    if ($scriptPath -and (Test-Path -LiteralPath $scriptPath)) {
        $hashFull = (Get-FileHash -LiteralPath $scriptPath -Algorithm SHA256).Hash
        $Script:ScriptHash = $hashFull.Substring(0, 12).ToLower()
        $Script:ScriptPath = $scriptPath
    }
} catch {
    # If hash computation fails for any reason, the version still
    # works - we just don't get the file-hash component.
    $Script:ScriptHash = '(hash-error)'
}

# Compact one-line tag used in places where space is limited (per-phase
# headers). Format: "v2026.05.09-r10/a1b2c3d4e5f6"
$Script:ScriptShortTag = ('{0}/{1}' -f $Script:ScriptVersion, $Script:ScriptHash)


#####################################################################
# SECTION 0.25: Orchestrator constants
#####################################################################
# Project-reserved Policy GUID for the Deploy-Drivers-For-WindowsServer
# SPF orchestration. Documented in SPEC §D.25. Single fixed GUID so re-
# runs deploy / replace the same policy slot rather than accumulating
# new policies.
$Script:ReservedPolicyId = '{DDF8C2DA-A1B2-4D52-B551-446570577053}'

# ProgramData paths used by the orchestrator. Identical across all four
# driver scripts' integration blocks.
$Script:ProgramDataBase    = (Join-Path $env:ProgramData 'Deploy-Drivers-For-WindowsServer\wdac')
$Script:ManifestPath       = (Join-Path $Script:ProgramDataBase 'manifest.json')
$Script:SourceXmlPath      = (Join-Path $Script:ProgramDataBase 'active-policy.xml')
$Script:SourceP7bPath      = (Join-Path $Script:ProgramDataBase 'active-policy.p7b')
$Script:CertsDir           = (Join-Path $Script:ProgramDataBase 'certs')
$Script:BackupsDir         = (Join-Path $Script:ProgramDataBase 'backups')

# Deployed policy path for Single Policy Format. The kernel reads this
# file at boot, and the WMI method PS_UpdateAndCompareCIPolicy.Update()
# refreshes it without reboot on WS2019.
$Script:DeployedPolicyPath = (Join-Path $env:windir 'System32\CodeIntegrity\SiPolicy.p7b')

# Manifest schema version.
$Script:SchemaVersion = '1.0'
$Script:SchemaId      = 'deploy-drivers-for-windowsserver/wdac-manifest/v1'

# Cache slot for self-canonical-hash. Computed once lazily on first need
# (see Get-SelfCanonicalHash).
$Script:SelfCanonicalHash = $null

# JSON envelope state - populated by Set-JsonResult, emitted by _EmitJson.
$Script:JsonResult = $null

#####################################################################
# SECTION 1: Logging helpers
#####################################################################
function Format-Elapsed {
    param([TimeSpan]$Span)
    if ($null -eq $Span) { return '0.00s' }
    if ($Span.TotalSeconds -lt 60) {
        return ('{0:F2}s' -f $Span.TotalSeconds)
    } elseif ($Span.TotalMinutes -lt 60) {
        $m = [int][math]::Floor($Span.TotalMinutes)
        $s = $Span.TotalSeconds - ($m * 60)
        return ('{0}m{1:F1}s' -f $m, $s)
    } else {
        $h = [int][math]::Floor($Span.TotalHours)
        $m = $Span.Minutes
        $s = $Span.Seconds
        return ('{0}h{1}m{2}s' -f $h, $m, $s)
    }
}

function Get-PhaseElapsedTag {
    # Returns elapsed-since-current-phase-start as "[+X.XXs]" or empty.
    if ($null -eq $Script:CurrentPhaseStart) { return '' }
    $span = (Get-Date) - $Script:CurrentPhaseStart
    return ('[+{0}]' -f (Format-Elapsed $span))
}

function _LogLine {
    # Internal: emits "[HH:mm:ss] [+X.XXs] [marker] message"
    param([string]$Marker, [string]$Msg, [string]$Color)
    $ts  = Get-Date -Format 'HH:mm:ss'
    $tag = Get-PhaseElapsedTag
    if ($tag) {
        Write-Host ("[{0}] {1,-10} {2} {3}" -f $ts, $tag, $Marker, $Msg) -ForegroundColor $Color
    } else {
        Write-Host ("[{0}]            {1} {2}" -f $ts, $Marker, $Msg) -ForegroundColor $Color
    }
}

function Write-Step  { param($Msg) _LogLine '[*]' $Msg 'Cyan'     }
function Write-Ok    { param($Msg) _LogLine '[+]' $Msg 'Green'    }
function Write-Warn2 { param($Msg) _LogLine '[!]' $Msg 'Yellow'   }
function Write-Fail  { param($Msg) _LogLine '[X]' $Msg 'Red'      }
function Write-Skip  { param($Msg) _LogLine '[~]' $Msg 'DarkGray' }

function Write-Detail {
    # ====================================================================
    # Continuation / detail line for a preceding marker line, or a row
    # inside a section banner block (Show-PowerShellEnvironment,
    # Show-OperatingSystemDetail, Show-SecureBootBaselineSnapshot, etc.).
    # Renders 4-space-indented plain text with NO timestamp or marker
    # prefix, so it visually attaches to the preceding context.
    #
    # ---- Introduced to replace bare `Write-Host " XXX"` calls ----
    # Previously the scripts emitted ~100 bare Write-Host calls with a
    # hard-coded 4-space indent. Routing those through a single helper
    # makes future column-layout tweaks possible without touching every
    # call site, and gives the SPEC-mandated marker pattern a single
    # documented exception ("continuation row of a marker line").
    #
    # The 4-space indent is intentional and matches the historical
    # column convention used inside section-banner tables.
    #
    # -NoNewline mirrors Write-Host's switch and is used by two-part
    # lines that compose a label-then-value pair (e.g. P08's
    # "-> Selected /os:" + colored value).
    # ====================================================================
    param(
        [Parameter(Position=0)][string]$Msg,
        [ConsoleColor]$Color = [ConsoleColor]::Gray,
        [switch]$NoNewline
    )
    if ($NoNewline) {
        Write-Host ("    {0}" -f $Msg) -ForegroundColor $Color -NoNewline
    } else {
        Write-Host ("    {0}" -f $Msg) -ForegroundColor $Color
    }
}

function Write-PhaseHeader {
    param($Id, $Name, $Group)
    $Script:CurrentPhaseStart = Get-Date
    $Script:CurrentPhaseId    = $Id
    $startStr = $Script:CurrentPhaseStart.ToString('HH:mm:ss')
    $line = '=' * 72
    Write-Host ''
    Write-Host $line -ForegroundColor Magenta
    Write-Host (" PHASE {0} - {1,-23} ({2,-6})  start: {3}" -f $Id, $Name, $Group, $startStr) -ForegroundColor Magenta
    Write-Host (" script: {0}" -f $Script:ScriptShortTag) -ForegroundColor DarkGray
    Write-Host $line -ForegroundColor Magenta
}

function Write-PhaseFooter {
    param($Id, [ValidateSet('done','cached','skipped','failed')]$Status)

    # Idempotency: ignore duplicate calls for the same Id within one run.
    # Phases that emit their own footer before throwing would otherwise
    # be double-counted when the dispatcher's catch also calls us.
    foreach ($t in $Script:PhaseTimings) {
        if ($t.Id -eq $Id) { return }
    }

    $color = switch ($Status) {
        'done'    { 'Green' }
        'cached'  { 'DarkGray' }
        'skipped' { 'DarkGray' }
        'failed'  { 'Red' }
    }
    $elapsed = if ($Script:CurrentPhaseStart) { (Get-Date) - $Script:CurrentPhaseStart } else { [TimeSpan]::Zero }
    $elapsedStr = Format-Elapsed $elapsed

    $Script:PhaseTimings.Add([pscustomobject]@{
        Id      = $Id
        Status  = $Status
        Elapsed = $elapsed
        EndedAt = Get-Date
    }) | Out-Null

    Write-Host (" PHASE {0} -> {1,-7}  elapsed: {2}" -f $Id, $Status.ToUpper(), $elapsedStr) -ForegroundColor $color
    Write-Host ''

    # Reset so any stray Write-Step/Ok between phases doesn't show a
    # misleading [+X.XXs] tag inherited from the previous phase.
    $Script:CurrentPhaseStart = $null
    $Script:CurrentPhaseId    = $null
}

function Show-PowerShellEnvironment {
    # ====================================================================
    # Display the PowerShell execution environment for diagnostics.
    # ====================================================================
    # Designed to work all the way back to PowerShell 5.1 on Windows
    # Server 2016 (the oldest in-support Windows Server). All cmdlets
    # and APIs used here are present in PS 5.1 /.NET Framework 4.6+,
    # so this function itself does not introduce any new compatibility
    # risk. CIM queries fall back to WMI for fragile environments.
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSAvoidUsingWMICmdlet', '',
        Justification = 'Intentional Get-WmiObject fallback path. CIM is the primary path; WMI is the secondary path used only when CIM is constrained on Server Core / restricted images. PowerShell 5.1 supports both; the script targets PS 5.1+ as its baseline.')]  # psa-disable-line PSA3006 -- intentional fallback when CIM is constrained; PS 5.1 still supports WMI cmdlets
    param()

    Write-Host ''
    Write-Host '========================================================================'
    Write-Host ' PowerShell Execution Environment'
    Write-Host '========================================================================'

    # ---- PowerShell engine ----
    $pv = $PSVersionTable
    $editionDesc = if ($pv.PSEdition -eq 'Desktop') {
        'Windows PowerShell - shipped with Windows'
    } elseif ($pv.PSEdition -eq 'Core') {
        'PowerShell 7+ / Core - separately installed'
    } else {
        '(unknown edition)'
    }
    Write-Host ('    PowerShell Version  : {0}' -f $pv.PSVersion)
    Write-Host ('    PowerShell Edition  : {0,-25} ({1})' -f $pv.PSEdition, $editionDesc)
    if ($pv.CLRVersion) {
        Write-Host ('    CLR / .NET          : {0}' -f $pv.CLRVersion)
    } else {
        Write-Host  '    CLR / .NET          : (CLRVersion not exposed by this edition; PS Core is .NET Core / .NET 5+)'
    }
    if ($pv.BuildVersion) {
        Write-Host ('    Engine Build        : {0}' -f $pv.BuildVersion)
    }

    # ---- Process bitness / architecture ----
    $procBitness = if ([Environment]::Is64BitProcess) { '64-bit process' } else { '32-bit process' }
    $procArch    = $env:PROCESSOR_ARCHITECTURE
    Write-Host ('    Process Architecture: {0,-25} ({1})' -f $procArch, $procBitness)

    # ---- Operating system (CIM, fallback to WMI for restricted hosts) ----
    $os = $null
    try {
        $os = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction Stop
    } catch {
        try {
            # WS2016 / WS2019 sometimes have CIM service issues on
            # constrained images (e.g. Server Core); fall back to WMI.
            $os = Get-WmiObject -Class Win32_OperatingSystem -ErrorAction Stop  # psa-disable-line PSA3006 -- intentional fallback when CIM is constrained; PS 5.1 still supports WMI cmdlets
        } catch {
            $os = $null
        }
    }
    if ($os) {
        $caption = if ($os.Caption) { $os.Caption.Trim() } else { '(no caption)' }
        $arch    = if ($os.OSArchitecture) { $os.OSArchitecture } else { 'unknown' }
        Write-Host ('    OS                  : {0}' -f $caption)
        Write-Host ('    OS Build            : {0}' -f $os.BuildNumber)
        Write-Host ('    OS Architecture     : {0}' -f $arch)
    } else {
        Write-Host '    OS                  : (could not query Win32_OperatingSystem - both CIM and WMI failed)' -ForegroundColor Yellow
    }

    # ---- Host (the program hosting PowerShell) ----
    Write-Host ('    Host                : {0,-25} (Version {1})' -f $Host.Name, $Host.Version)

    # ---- Execution Policy (best-effort; some scopes may be unreadable) ----
    try {
        $pCurrent = Get-ExecutionPolicy
        $pUser    = Get-ExecutionPolicy -Scope CurrentUser  -ErrorAction SilentlyContinue
        $pMachine = Get-ExecutionPolicy -Scope LocalMachine -ErrorAction SilentlyContinue
        Write-Host ('    Execution Policy    : {0,-25} (CurrentUser: {1}, LocalMachine: {2})' -f $pCurrent, $pUser, $pMachine)
    } catch {
        Write-Host '    Execution Policy    : (query failed)' -ForegroundColor Yellow
    }

    # ---- Administrator status ----
    $id      = [Security.Principal.WindowsIdentity]::GetCurrent()
    $prin    = [Security.Principal.WindowsPrincipal]::new($id)
    $isAdmin = $prin.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if ($isAdmin) {
        Write-Host  '    Running as Admin    : Yes'
    } else {
        Write-Host  '    Running as Admin    : NO  (cert install / driver install will fail)' -ForegroundColor Yellow
    }

    # ---- TLS (relevant for download phases) ----
    Write-Host ('    TLS Default         : {0}' -f [Net.ServicePointManager]::SecurityProtocol)

    # ---- Culture / encoding ----
    Write-Host ('    Culture             : {0,-25} UICulture: {1}' -f (Get-Culture).Name, (Get-UICulture).Name)
    $defEnc = [System.Text.Encoding]::Default
    Write-Host ('    Default Encoding    : {0} (cp{1})' -f $defEnc.WebName, $defEnc.CodePage)
    Write-Host ('    Console OutputEnc.  : {0} (cp{1})' -f [Console]::OutputEncoding.WebName, [Console]::OutputEncoding.CodePage)

    # ---- Compatibility check summary ----
    Write-Host ''
    Write-Host '    Compatibility check (target: PS 5.1+ on Windows Server 2016 or later):'

    $minPs = [Version]'5.1'
    if ($pv.PSVersion -ge $minPs) {
        Write-Host ('      [+] PS 5.1+        OK    ({0} >= {1})' -f $pv.PSVersion, $minPs) -ForegroundColor Green
    } else {
        Write-Host ('      [X] PS 5.1+        FAIL  ({0} < {1})' -f $pv.PSVersion, $minPs) -ForegroundColor Red
    }

    Write-Host ('      [+] Edition        OK    ({0} - both Desktop and Core are supported)' -f $pv.PSEdition) -ForegroundColor Green

    if ([Environment]::Is64BitProcess) {
        Write-Host  '      [+] Bitness        OK    (64-bit process)' -ForegroundColor Green
    } else {
        Write-Host  '      [X] Bitness        FAIL  (32-bit process - launch the 64-bit PowerShell, not "(x86)")' -ForegroundColor Red
    }

    if ($isAdmin) {
        Write-Host  '      [+] Elevation      OK    (Administrator)' -ForegroundColor Green
    } else {
        Write-Host  '      [X] Elevation      FAIL  (not Administrator)' -ForegroundColor Red
    }

    if ($os) {
        $supportedBuilds = @{
            14393 = 'Windows Server 2016'
            17763 = 'Windows Server 2019'
            20348 = 'Windows Server 2022'
            26100 = 'Windows Server 2025'
        }
        $build = [int]$os.BuildNumber
        if ($supportedBuilds.ContainsKey($build)) {
            # When running on a Workstation OS (e.g. Win11 24H2 used as
            # a WS2025 preview), include "Workstation, profile: <ServerName>"
            # so it is obvious from this line alone that the host is NOT a
            # Server and a profile is being applied. Previously only the Server
            # profile name was shown, which made the line read like an OS
            # mis-detection on Workstation hosts.
            if ($os.ProductType -eq 1) {
                Write-Host ('      [+] OS             OK    (build {0} = Workstation; applying profile: {1})' -f $build, $supportedBuilds[$build]) -ForegroundColor Green
            } else {
                Write-Host ('      [+] OS             OK    ({0} / build {1})' -f $supportedBuilds[$build], $build) -ForegroundColor Green
            }
        } else {
            Write-Host ('      [!] OS             WARN  (build {0} not in known list - script may still work)' -f $build) -ForegroundColor Yellow
        }
    } else {
        Write-Host  '      [!] OS             WARN  (could not detect OS build)' -ForegroundColor Yellow
    }

    # ---- Boot-signing environment (Secure Boot, testsigning, HVCI) ----
    # This is the top concern for a self-signed-driver installer. We
    # show a compact one-line summary here and let I00 / I02 produce
    # the verbose table when actually needed.
    Write-Host ''
    try {
        $bootEnv = Get-BootSigningEnvironment
        Show-BootSigningEnvironment -BootEnv $bootEnv -Compact
    } catch {
        Write-Host ('    Boot Signing        : (query failed: {0})' -f $_.Exception.Message) -ForegroundColor Yellow
    }

    # ---- Prerequisite-workflow reminder (compact) ----
    # Make this visible on every run because skipping the OEM/WU step
    # invalidates V06's analysis and produces misleading AS-IS/TO-BE
    # comparisons in I00 / I04. The full block lives in Show-Help and
    # in I00.
    Show-DriverInstallationOrderNotice -Compact

    Write-Host '========================================================================'
    Write-Host ''
}

function Assert-PowerShellCompatibility {
    # ====================================================================
    # Hard-fail the script early if we cannot safely run.
    # ====================================================================
    # Conditions checked here are *fatal* (the script cannot proceed).
    # Soft warnings (e.g. unknown OS build) live in
    # Show-PowerShellEnvironment instead.
    $pv    = $PSVersionTable.PSVersion
    $minPs = [Version]'5.1'
    if ($pv -lt $minPs) {
        throw @"
This script requires PowerShell $minPs or later.
Detected: $pv

This script targets the default PowerShell included with Windows
Server 2016 / 2019 / 2022 / 2025, which is PowerShell 5.1.
PowerShell 7+ is NOT required, but PowerShell 5.1 is the minimum.

If you are on Windows Server 2012 R2 or earlier, install Windows
Management Framework 5.1: https://aka.ms/wmf51
"@
    }
    if (-not [Environment]::Is64BitProcess) {
        throw @'
This script requires a 64-bit PowerShell process. Detected 32-bit.

On a 64-bit Windows Server, launch from "Windows PowerShell"
(NOT "Windows PowerShell (x86)"). The driver / signtool tooling
will not work correctly inside a 32-bit host.
'@
    }
}

function Assert-Admin {
    $id   = [Security.Principal.WindowsIdentity]::GetCurrent()
    $prin = [Security.Principal.WindowsPrincipal]::new($id)
    if (-not $prin.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        throw 'This script must be run from an elevated PowerShell session.'
    }
}


function Set-Tls12 {
    # ====================================================================
    # Enable modern TLS for Invoke-WebRequest / Invoke-RestMethod.
    # ====================================================================
    # Tls12 is the must-have (some download endpoints require it).
    # Tls13 is added if the running.NET supports it (Framework 4.8+,
    # WS2022+ ships with it; WS2016/WS2019 may not). Tls11 and below
    # are intentionally NOT requested - they are deprecated and removed
    # from many endpoints.
    $protos = [Net.SecurityProtocolType]::Tls12
    try {
        $tls13 = [Net.SecurityProtocolType]::Tls13
        $protos = $protos -bor $tls13
    } catch {
        # Tls13 enum value not present in this.NET runtime; that is
        # fine - Tls12 alone is sufficient for everything this script
        # downloads.
    }
    [Net.ServicePointManager]::SecurityProtocol = $protos
}

function Set-ConsoleUtf8 {
    # ====================================================================
    # SPEC A.5 / D.5: enforce UTF-8 console encoding so ja-JP Japanese
    # log strings (and external tool output such as CiTool.exe) render
    # correctly instead of mojibake in cp932 (Shift-JIS). See SPEC D.16
    # for the root-cause analysis (CiTool.exe writes UTF-8 stdout).
    # ====================================================================
    # On ja-JP Windows, the console defaults to cp932 (Shift-JIS). When
    # external programs that write UTF-8 to stdout (CiTool.exe, modern
    # signtool, etc.) are captured via "& tool... | Out-String", PS
    # decodes the bytes using [Console]::OutputEncoding. If that is
    # cp932 and the tool wrote UTF-8, every multibyte character becomes
    # mojibake (e.g. "処理が成功しました" -> "蜃ｦ逅・・謌仙粥縺励∪縺励◆").
    #
    # The fix is to set ALL three encodings:
    #   - [Console]::OutputEncoding: how PS decodes external tool stdout
    #                                  AND how Write-Host writes to console
    #   - [Console]::InputEncoding: how external tools see piped stdin
    #   - $OutputEncoding: how PS writes piped data to external
    #                                  tools (e.g. "$json | tool.exe")
    # All three must be UTF-8 for consistent round-trip behaviour.
    #
    # This is wrapped in try/catch because some pinned-redirected
    # console hosts (e.g. CI runners writing to a file with no real
    # console) may throw on the assignment; in that case the original
    # encoding is preserved and we continue without UTF-8 enforcement.
    try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch { } # psa-disable-line PSA3004 -- intentional best-effort cleanup; no error to surface
    try { [Console]::InputEncoding  = [System.Text.Encoding]::UTF8 } catch { } # psa-disable-line PSA3004 -- intentional best-effort cleanup; no error to surface
    try { Set-Variable -Name OutputEncoding -Scope Global -Value ([System.Text.Encoding]::UTF8) -ErrorAction SilentlyContinue } catch { } # psa-disable-line PSA3004 -- intentional best-effort cleanup; no error to surface
}

#####################################################################
# SECTION 1b: Debug Trace Facility
#####################################################################
# A reusable diagnostic helper used to pinpoint the exact failing
# operation inside a complex function body, with three integrated
# subsystems:
#
#   (1) Trace primitives: Start-DebugTrace / Set-DebugStep /
#                           Stop-DebugTrace / Format-DebugFailure /
#                           Write-DebugFailureReport
#   (2) JSONL file output: Real-time append-only event stream to
#                           <WorkRoot>\logs\debugtrace.jsonl
#   (3) JSON Export: Point-in-time snapshot with full state,
#                           used manually and auto-triggered on phase
#                           failure.
#
# Motivation: investigation of Invoke-InfVerifValidation - the
# function raised System.ArgumentException but the stack trace only
# identified the function, not the line. By instrumenting with
# $debugStep checkpoints and a catch handler that reported the step
# name + exception type + message + script stack, the failure was
# localised to a single line (the `return [pscustomobject]@{...}`
# statement) and from there to a PS 5.1 ja-JP locale bug. This section
# generalises that ad-hoc pattern into a reusable facility that any
# function in this script (or sister scripts) can adopt.
#
# Typical usage pattern (function entry/body/catch/finally):
#
#   function Invoke-Something {
#       Start-DebugTrace -Context 'Invoke-Something'
#       try {
#           Set-DebugStep 'validate inputs'
#           ...
#           Set-DebugStep 'open file'
#           ...
#           Set-DebugStep 'parse content'
#           ...
#           Set-DebugStep 'return result'
#           return $result
#       } catch {
#           Write-DebugFailureReport $_ -IncludeStepHistory
#           throw
#       } finally {
#           Stop-DebugTrace
#       }
#   }
#
# Nesting: traces stack via Stack<object>; nested traced functions
# don't stomp on each other's state. Format-DebugFailure always
# reports against the frame that was at the top of the stack at the
# moment the exception was caught (= the function whose catch block
# is running).
#
# Phase integration: the top-level phase dispatcher loop wraps every
# phase invocation in Start-DebugTrace / Stop-DebugTrace with the
# phase ID as context (e.g. 'phase.P05.AnalyzeInfs'). Any Set-DebugStep
# inside the phase body is automatically attributed to that frame.
# On phase failure, the dispatcher emits Write-DebugFailureReport and
# triggers Export-DebugTraceJson automatically when auto-export is on.

# --- 1b.1: Module-level state -----------------------------------------

# Stack of currently-active trace frames (most recent on top).
# Each frame is a pscustomobject with: Context, Step, Steps, StartTime,
# Echo, Outcome (set on Stop), FailureRef (set on failure).
$Script:DebugTraceStack = New-Object 'System.Collections.Generic.Stack[object]'

# List of completed frames retained for JSON Export. Each entry is the
# same pscustomobject as in the stack, with Outcome and (if applicable)
# FailureRef populated. Used by Export-DebugTraceJson to reconstruct
# the full call history. Capped to prevent unbounded growth in long runs.
$Script:DebugTraceCompletedFrames = New-Object 'System.Collections.Generic.List[object]'
$Script:DebugTraceCompletedCap    = 1024  # cap on retained completed frames

# Step history cap per frame, to prevent unbounded growth in tight loops
# that call Set-DebugStep repeatedly.
$Script:DebugTraceHistoryCap = 256

# Per-event log line size cap (chars). Truncate very large RawOutput-style
# fields when writing to JSONL so the stream stays grep-able.
$Script:DebugTraceJsonlLineCap = 8192

# ConvertTo-Json depth. 100 = PS 5.1 ConvertTo-Json official maximum
# (per Microsoft Learn docs: "any number from 1 to 100"). Set to the
# max to ensure no nested object truncation when exporting trace state.
$Script:DebugTraceJsonDepth = 100

# JSONL writer state. Activated by Enable-DebugTraceFileOutput, typically
# from P01 (PrepareWorkspace) once the <WorkRoot>\logs dir exists.
$Script:DebugTraceJsonlEnabled = $false
$Script:DebugTraceJsonlPath    = $null
$Script:DebugTraceJsonlBuffer  = New-Object 'System.Collections.Generic.List[string]'  # pre-activation buffer
$Script:DebugTraceJsonlBufferCap = 4096  # pre-flush buffer cap (chars combined)
$Script:DebugTraceJsonlWriteCount = 0
$Script:DebugTraceJsonlErrorCount = 0
$Script:DebugTraceJsonlLastError  = $null

# Auto-export-on-failure state.
$Script:DebugTraceAutoExportEnabled = $false
$Script:DebugTraceAutoExportDir     = $null

# Per-phase trace registry. Phase id -> frame reference + outcome metadata.
$Script:DebugTracePhaseRegistry = @{}

# Script-level event sequence number. Monotonic across the whole run,
# included in every JSONL event so they can be ordered exactly even when
# multiple events share the same millisecond timestamp.
$Script:DebugTraceEventSeq = 0

# --- 1b.2: Internal helpers (not part of public API) ------------------

function _DebugTrace_NextSeq {
    # Atomic-ish counter. Single-threaded PowerShell so no Interlocked
    # needed; this is just a small helper for readability.
    $Script:DebugTraceEventSeq++
    return $Script:DebugTraceEventSeq
}

function _DebugTrace_Now {
    # Return current time as ISO 8601 string with milliseconds and Z
    # suffix. Pre-converted to string so ConvertTo-Json doesn't render
    # the PS 5.1 legacy /Date(N)/ format - we want the same machine-
    # readable representation regardless of PS version.
    return (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
}

function _DebugTrace_WriteJsonlLine {
    # Append one JSONL line to the debugtrace.jsonl file (or to the
    # pre-activation buffer if file output isn't enabled yet). All
    # failures are absorbed so the script body is never disrupted by
    # trace bookkeeping.
    #
    # The parameter is named $EventObject (rather than the more natural
    # $Event) because $Event is a PowerShell automatic variable populated
    # inside event-subscriber action blocks (Register-ObjectEvent,
    # Register-WmiEvent, etc.). Reusing the name would shadow that
    # built-in and silently misbehave if this function were ever called
    # from inside such a block. See PSScriptAnalyzer rule
    # PSAvoidAssignmentToAutomaticVariable.
    param([Parameter(Mandatory)] $EventObject)

    # Add monotonic sequence number for stable cross-event ordering.
    $EventObject | Add-Member -MemberType NoteProperty -Name 'seq' -Value (_DebugTrace_NextSeq) -Force

    try {
        $json = $EventObject | ConvertTo-Json -Depth $Script:DebugTraceJsonDepth -Compress
    } catch {
        # If JSON conversion fails (e.g. circular reference somewhere),
        # fall back to a minimal hand-written line so we still record
        # something. Increment error counter and stash last error.
        $Script:DebugTraceJsonlErrorCount++
        $Script:DebugTraceJsonlLastError = $_.Exception.Message
        $kind = if ($EventObject.PSObject.Properties['kind']) { $EventObject.kind } else { 'unknown' }
        $ctx  = if ($EventObject.PSObject.Properties['ctx'])  { $EventObject.ctx  } else { '?' }
        $json = ('{{"ts":"{0}","seq":{1},"kind":"{2}","ctx":"{3}","err":"json-serialize-failed"}}' `
                    -f (_DebugTrace_Now), $Script:DebugTraceEventSeq, $kind, $ctx)
    }

    # Truncate over-cap lines so the JSONL stream stays grep-able.
    if ($json.Length -gt $Script:DebugTraceJsonlLineCap) {
        $json = $json.Substring(0, $Script:DebugTraceJsonlLineCap - 16) + '...","truncated":1}'
    }

    if ($Script:DebugTraceJsonlEnabled -and $Script:DebugTraceJsonlPath) {
        try {
            # IMPORTANT: UTF-8 *with* BOM. On Windows PowerShell 5.1
            # with a ja-JP / non-English locale, `Get-Content` defaults
            # to the OS code page (Shift-JIS on ja-JP), which mojibakes
            # any Japanese / UTF-8 multi-byte content unless the file
            # has a BOM. AppendAllText only writes the BOM when the file
            # is freshly created, so subsequent appends incur no
            # overhead.
            [System.IO.File]::AppendAllText(
                $Script:DebugTraceJsonlPath,
                $json + "`r`n",
                [System.Text.UTF8Encoding]::new($true))
            $Script:DebugTraceJsonlWriteCount++
        } catch {
            # If file write fails (e.g. disk full, perm changed), revert
            # to buffer mode and remember the error for diagnostics.
            $Script:DebugTraceJsonlErrorCount++
            $Script:DebugTraceJsonlLastError = $_.Exception.Message
            $Script:DebugTraceJsonlEnabled = $false
            $Script:DebugTraceJsonlBuffer.Add($json) | Out-Null
            # Cap the buffer too so it can't grow unbounded after a long
            # disk-full period.
            while ($Script:DebugTraceJsonlBuffer.Count -gt $Script:DebugTraceJsonlBufferCap) {
                $Script:DebugTraceJsonlBuffer.RemoveAt(0)
            }
        }
    } else {
        # Pre-activation: buffer in memory. P01 will flush after the
        # workspace logs directory is created.
        $Script:DebugTraceJsonlBuffer.Add($json) | Out-Null
        while ($Script:DebugTraceJsonlBuffer.Count -gt $Script:DebugTraceJsonlBufferCap) {
            $Script:DebugTraceJsonlBuffer.RemoveAt(0)
        }
    }
}

function _DebugTrace_RetireFrame {
    # Move a frame from the active stack into the completed list.
    # Handles the history cap. Idempotent: safe to call even if the
    # frame has already been retired.
    param([Parameter(Mandatory)] $Frame, [Parameter(Mandatory)] [string]$Outcome)

    if (-not $Frame.PSObject.Properties['Outcome'] -or -not $Frame.Outcome) {
        $Frame | Add-Member -MemberType NoteProperty -Name 'Outcome'   -Value $Outcome -Force
        $Frame | Add-Member -MemberType NoteProperty -Name 'EndedAt'   -Value (Get-Date) -Force
        $durationMs = [int]((Get-Date) - $Frame.StartTime).TotalMilliseconds
        $Frame | Add-Member -MemberType NoteProperty -Name 'DurationMs' -Value $durationMs -Force
    }

    $Script:DebugTraceCompletedFrames.Add($Frame) | Out-Null
    while ($Script:DebugTraceCompletedFrames.Count -gt $Script:DebugTraceCompletedCap) {
        $Script:DebugTraceCompletedFrames.RemoveAt(0)
    }
}

# --- 1b.3: Public API - trace primitives ------------------------------

function Start-DebugTrace {
    <#
    .SYNOPSIS
        Push a new debug trace frame onto the stack. Call at function entry.
    .PARAMETER Context
        Human-readable name for this frame, typically the function name.
    .PARAMETER Echo
        If set, every Set-DebugStep call also writes a live [trace] line
        to the console. Default off.
    .PARAMETER PhaseId
        Optional phase identifier (e.g. 'P05'). When set, the frame is
        registered in the per-phase trace registry. Used by the phase
        dispatcher; do not set manually inside phase function bodies.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [string]$Context,
        [switch]$Echo,
        [string]$PhaseId
    )
    $frame = [pscustomobject]@{
        Context   = $Context
        Step      = 'entry'
        Steps     = (New-Object 'System.Collections.Generic.List[object]')
        StartTime = Get-Date
        Echo      = [bool]$Echo
        PhaseId   = $PhaseId
        Depth     = $Script:DebugTraceStack.Count + 1
    }
    $Script:DebugTraceStack.Push($frame)

    if ($PhaseId) {
        $Script:DebugTracePhaseRegistry[$PhaseId] = [pscustomobject]@{
            PhaseId    = $PhaseId
            Frame      = $frame
            StartedAt  = Get-Date
            EndedAt    = $null
            Outcome    = 'in-progress'
            FailureRef = $null
        }
    }

    _DebugTrace_WriteJsonlLine ([pscustomobject]@{
        ts    = _DebugTrace_Now
        kind  = 'frame.open'
        ctx   = $Context
        depth = $frame.Depth
        phase = $PhaseId
    })
}

function Set-DebugStep {
    <#
    .SYNOPSIS
        Mark the current step inside the active debug trace frame.
        No-op if no frame is active (so functions can use it
        opportunistically without callers having to set up tracing).
    .PARAMETER Step
        Short label describing the operation about to be performed.
    .PARAMETER Detail
        Optional extra context attached to this step in the JSONL log.
        Not surfaced in console output, only in the trace file.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position=0)] [string]$Step,
        [string]$Detail
    )
    if ($Script:DebugTraceStack.Count -eq 0) { return }
    $frame = $Script:DebugTraceStack.Peek()
    $frame.Step = $Step
    $now = Get-Date
    $frame.Steps.Add([pscustomobject]@{
        Step   = $Step
        At     = $now
        Detail = $Detail
    }) | Out-Null
    while ($frame.Steps.Count -gt $Script:DebugTraceHistoryCap) {
        $frame.Steps.RemoveAt(0)
    }
    if ($frame.Echo) {
        Write-Host ('[trace:{0}] {1}' -f $frame.Context, $Step) -ForegroundColor DarkMagenta
    }
    _DebugTrace_WriteJsonlLine ([pscustomobject]@{
        ts     = _DebugTrace_Now
        kind   = 'step'
        ctx    = $frame.Context
        step   = $Step
        detail = $Detail
    })
}

function Stop-DebugTrace {
    <#
    .SYNOPSIS
        Pop the most recent trace frame. Call in the finally block.
    .PARAMETER Outcome
        Optional outcome label. Defaults to 'success'. The catch block
        of the same function should set it to 'failure' before throwing
        if it wants the completed-frame record to reflect the failure.
    #>
    [CmdletBinding()]
    param(
        [ValidateSet('success','failure','cancelled','unknown')]
        [string]$Outcome = 'success'
    )
    if ($Script:DebugTraceStack.Count -eq 0) { return }
    $frame = $Script:DebugTraceStack.Pop()

    # If the frame was registered as a phase frame, finalise its
    # registry entry too.
    if ($frame.PhaseId -and $Script:DebugTracePhaseRegistry.ContainsKey($frame.PhaseId)) {
        $reg = $Script:DebugTracePhaseRegistry[$frame.PhaseId]
        $reg.EndedAt = Get-Date
        # Don't overwrite an already-set outcome (e.g. 'failure' set
        # by Write-DebugFailureReport).
        if ($reg.Outcome -eq 'in-progress') {
            $reg.Outcome = $Outcome
        }
    }

    _DebugTrace_RetireFrame -Frame $frame -Outcome $Outcome

    _DebugTrace_WriteJsonlLine ([pscustomobject]@{
        ts       = _DebugTrace_Now
        kind     = 'frame.close'
        ctx      = $frame.Context
        outcome  = $frame.Outcome
        durMs    = $frame.DurationMs
        steps    = $frame.Steps.Count
        phase    = $frame.PhaseId
    })
}

function Format-DebugFailure {
    <#
    .SYNOPSIS
        Build a structured failure report from an ErrorRecord plus the
        currently-active trace frame. Use when you need the failure
        data programmatically (e.g. relay it elsewhere).
    .PARAMETER ErrorRecord
        The $_ inside a catch block.
    .OUTPUTS
        pscustomobject with: Context, FailedStep, Elapsed, ExType,
        ExMessage, InnerType, InnerMessage, FullyQualifiedId,
        ScriptStackTrace, StepHistory (object[]).
    #>
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)] $ErrorRecord
    )
    $ex = $ErrorRecord.Exception
    if ($Script:DebugTraceStack.Count -gt 0) {
        $frame       = $Script:DebugTraceStack.Peek()
        $context     = $frame.Context
        $failedStep  = $frame.Step
        # PS 5.1 ja-JP bug workaround: use.ToArray not @($list).
        $stepHistory = $frame.Steps.ToArray()
        $elapsed     = (Get-Date) - $frame.StartTime
        $phaseId     = $frame.PhaseId
    } else {
        $context     = '(no active trace)'
        $failedStep  = '(no active trace)'
        $stepHistory = @()
        $elapsed     = [TimeSpan]::Zero
        $phaseId     = $null
    }
    return [pscustomobject]@{
        Context           = $context
        FailedStep        = $failedStep
        Elapsed           = $elapsed
        ElapsedMs         = [int]$elapsed.TotalMilliseconds
        PhaseId           = $phaseId
        ExType            = $ex.GetType().FullName
        ExMessage         = $ex.Message
        InnerType         = if ($ex.InnerException) { $ex.InnerException.GetType().FullName } else { $null }
        InnerMessage      = if ($ex.InnerException) { $ex.InnerException.Message } else { $null }
        FullyQualifiedId  = $ErrorRecord.FullyQualifiedErrorId
        ScriptStackTrace  = $ErrorRecord.ScriptStackTrace
        StepHistory       = $stepHistory
    }
}

function Write-DebugFailureReport {
    <#
    .SYNOPSIS
        Emit a formatted failure report via Write-Warn2 + log the
        failure event to JSONL. Call from a catch block. Also marks
        the active phase's registry entry as 'failure' if applicable.
    .PARAMETER ErrorRecord
        The $_ inside a catch block.
    .PARAMETER IncludeStepHistory
        If set, log every step the trace reached before the failure.
    .PARAMETER AutoExport
        If set, automatically write a JSON snapshot to the configured
        auto-export directory. Use this for top-level catch handlers.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] $ErrorRecord,
        [switch]$IncludeStepHistory,
        [switch]$AutoExport
    )
    $r = Format-DebugFailure -ErrorRecord $ErrorRecord

    # Update the phase registry if this failure happened inside a phase.
    if ($r.PhaseId -and $Script:DebugTracePhaseRegistry.ContainsKey($r.PhaseId)) {
        $reg = $Script:DebugTracePhaseRegistry[$r.PhaseId]
        $reg.Outcome    = 'failure'
        $reg.FailureRef = $r
    }

    Write-Warn2 ("{0}: FAILED at step '{1}' (elapsed {2:F2}s)" -f $r.Context, $r.FailedStep, $r.Elapsed.TotalSeconds)
    Write-Warn2 ("  ExType   : {0}" -f $r.ExType)
    Write-Warn2 ("  Message  : {0}" -f $r.ExMessage)
    if ($r.InnerType) {
        Write-Warn2 ("  Inner    : {0} - {1}" -f $r.InnerType, $r.InnerMessage)
    }
    if ($r.FullyQualifiedId) {
        Write-Warn2 ("  FQErrId  : {0}" -f $r.FullyQualifiedId)
    }
    if ($r.ScriptStackTrace) {
        $stackLines = $r.ScriptStackTrace -split "`r?`n"
        Write-Warn2 ("  Stack    : {0}" -f $stackLines[0])
        $maxStack = [Math]::Min(3, $stackLines.Count)
        for ($i = 1; $i -lt $maxStack; $i++) {
            Write-Warn2 ("             {0}" -f $stackLines[$i])
        }
    }
    if ($IncludeStepHistory -and $r.StepHistory.Count -gt 0) {
        Write-Warn2 ("  Steps    : {0} recorded" -f $r.StepHistory.Count)
        $firstAt = $r.StepHistory[0].At
        foreach ($h in $r.StepHistory) {
            $rel = ($h.At - $firstAt).TotalMilliseconds
            Write-Warn2 ('    +{0,7:F0}ms  {1}' -f $rel, $h.Step)
        }
    }

    _DebugTrace_WriteJsonlLine ([pscustomobject]@{
        ts          = _DebugTrace_Now
        kind        = 'failure'
        ctx         = $r.Context
        step        = $r.FailedStep
        elapsedMs   = $r.ElapsedMs
        phase       = $r.PhaseId
        exType      = $r.ExType
        msg         = $r.ExMessage
        innerType   = $r.InnerType
        innerMsg    = $r.InnerMessage
        fqErrId     = $r.FullyQualifiedId
        stack       = $r.ScriptStackTrace
        stepHistory = $r.StepHistory
    })

    if ($AutoExport -and $Script:DebugTraceAutoExportEnabled -and $Script:DebugTraceAutoExportDir) {
        try {
            $ts = (Get-Date).ToString('yyyyMMdd-HHmmss')
            $tag = if ($r.PhaseId) { $r.PhaseId } else { 'top' }
            $exportPath = Join-Path $Script:DebugTraceAutoExportDir ("debugtrace_export_{0}_{1}.json" -f $tag, $ts)
            Export-DebugTraceJson -Path $exportPath -IncludeEvents:$false | Out-Null
            Write-Warn2 ("  TraceJson: {0}" -f $exportPath)
        } catch {
            # Don't let auto-export failures hide the original error.
            Write-Warn2 ("  TraceJson: auto-export failed: {0}" -f $_.Exception.Message)
        }
    }
}

# --- 1b.4: Public API - file output (Feature A) -----------------------

function Enable-DebugTraceFileOutput {
    <#
    .SYNOPSIS
        Activate the JSONL writer. Typically called by P01 once the
        workspace logs directory exists. Flushes the pre-activation
        buffer into the file in one go.
    .PARAMETER Directory
        Target directory. The file is named 'debugtrace.jsonl' inside
        this dir. If a same-named file exists, it is appended.
    .PARAMETER Force
        If set, switch output to the new directory even if file output
        was already active. (Useful for re-routing.)
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [string]$Directory,
        [switch]$Force
    )
    if ($Script:DebugTraceJsonlEnabled -and -not $Force) { return }

    try {
        if (-not (Test-Path -LiteralPath $Directory)) {
            New-Item -ItemType Directory -Path $Directory -Force -ErrorAction Stop | Out-Null
        }
        $path = Join-Path $Directory 'debugtrace.jsonl'

        # Probe write a header line so the file exists and is writable.
        # If a same-name lock collision occurs, fall back to per-pid filename.
        $headerObj = [pscustomobject]@{
            ts        = _DebugTrace_Now
            kind      = 'file.open'
            scriptVer = $Script:ScriptVersion
            scriptSha = $Script:ScriptHash
            pid       = $PID
            host      = $Host.Name
            psVer     = $PSVersionTable.PSVersion.ToString()
            culture   = (Get-Culture).Name
        }
        $headerJson = $headerObj | ConvertTo-Json -Depth $Script:DebugTraceJsonDepth -Compress
        try {
            # UTF-8 with BOM (see _DebugTrace_WriteJsonlLine comment).
            [System.IO.File]::AppendAllText($path, $headerJson + "`r`n", [System.Text.UTF8Encoding]::new($true))
        } catch {
            # Path locked by another process; switch to per-pid filename.
            $path = Join-Path $Directory ("debugtrace_{0}.jsonl" -f $PID)
            [System.IO.File]::AppendAllText($path, $headerJson + "`r`n", [System.Text.UTF8Encoding]::new($true))
        }

        $Script:DebugTraceJsonlPath    = $path
        $Script:DebugTraceJsonlEnabled = $true

        # Flush pre-activation buffer
        if ($Script:DebugTraceJsonlBuffer.Count -gt 0) {
            $bufferedLines = $Script:DebugTraceJsonlBuffer.ToArray()
            $Script:DebugTraceJsonlBuffer.Clear()
            try {
                $blob = ($bufferedLines -join "`r`n") + "`r`n"
                # UTF-8 with BOM (see _DebugTrace_WriteJsonlLine comment).
                [System.IO.File]::AppendAllText($path, $blob, [System.Text.UTF8Encoding]::new($true))
                $Script:DebugTraceJsonlWriteCount += $bufferedLines.Count
            } catch {
                # If flush fails, re-buffer for the next opportunity.
                foreach ($l in $bufferedLines) { $Script:DebugTraceJsonlBuffer.Add($l) | Out-Null }
                $Script:DebugTraceJsonlErrorCount++
                $Script:DebugTraceJsonlLastError = $_.Exception.Message
                throw
            }
        }

        # Register a one-shot cleanup at PowerShell host exit so the
        # JSONL stream is flushed and a close marker is written even on
        # abnormal termination.
        Register-EngineEvent -SourceIdentifier PowerShell.Exiting -SupportEvent -Action {
            try {
                if ($Script:DebugTraceJsonlEnabled -and $Script:DebugTraceJsonlPath) {
                    $closeEvent = '{{"ts":"{0}","kind":"file.close","pid":{1}}}' -f `
                        (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ss.fffZ'), $PID
                    [System.IO.File]::AppendAllText(
                        $Script:DebugTraceJsonlPath,
                        $closeEvent + "`r`n",
                        [System.Text.UTF8Encoding]::new($true))
                }
            } catch { } # psa-disable-line PSA3004 -- intentional best-effort during PowerShell.Exiting; host is tearing down, surfacing errors is useless
        } | Out-Null

        Write-Host ('[*] Debug trace -> {0}' -f $path) -ForegroundColor DarkGreen
    } catch {
        # Activation failed; stay in buffer mode. The buffer continues
        # to accumulate but we never surface the failure as an error to
        # the caller - trace bookkeeping must not break the script.
        $Script:DebugTraceJsonlEnabled = $false
        $Script:DebugTraceJsonlErrorCount++
        $Script:DebugTraceJsonlLastError = $_.Exception.Message
        Write-Warning ("Debug trace file output activation failed: {0}" -f $_.Exception.Message)
        Write-Warning '   Trace events remain captured in memory and are exportable via Export-DebugTraceJson.'
    }
}

function Disable-DebugTraceFileOutput {
    <#
    .SYNOPSIS
        Stop appending trace events to the JSONL file. Events continue
        to be captured in memory and remain exportable via
        Export-DebugTraceJson.
    #>
    [CmdletBinding()]
    param()
    if (-not $Script:DebugTraceJsonlEnabled) { return }
    _DebugTrace_WriteJsonlLine ([pscustomobject]@{
        ts   = _DebugTrace_Now
        kind = 'file.disable'
    })
    $Script:DebugTraceJsonlEnabled = $false
}

function Get-DebugTraceFileOutputStatus { # psa-disable-line PSA6003 -- "Status" is singular; analyzer false positive on compound name
    <#
    .SYNOPSIS
        Return the current state of the JSONL writer for diagnostics.
    #>
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()
    return [pscustomobject]@{
        Enabled         = $Script:DebugTraceJsonlEnabled
        Path            = $Script:DebugTraceJsonlPath
        WriteCount      = $Script:DebugTraceJsonlWriteCount
        ErrorCount      = $Script:DebugTraceJsonlErrorCount
        LastError       = $Script:DebugTraceJsonlLastError
        BufferedLines   = $Script:DebugTraceJsonlBuffer.Count
        ActiveFrames    = $Script:DebugTraceStack.Count
        CompletedFrames = $Script:DebugTraceCompletedFrames.Count
    }
}

# --- 1b.5: Public API - JSON Export (Feature B) -----------------------

function Enable-AutoExportOnPhaseFailure {
    <#
    .SYNOPSIS
        Turn on automatic JSON Export when a phase fails. When enabled,
        Write-DebugFailureReport -AutoExport will write a snapshot to
        the configured directory.
    .PARAMETER OutputDirectory
        Where to write debugtrace_export_<phaseId>_<timestamp>.json files.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [string]$OutputDirectory
    )
    $Script:DebugTraceAutoExportEnabled = $true
    $Script:DebugTraceAutoExportDir     = $OutputDirectory
}

function Export-DebugTraceJson {
    <#
    .SYNOPSIS
        Write a point-in-time JSON snapshot of the current trace state.
        Use this to share a single diagnostic file (e.g. attach to a
        bug report) instead of the streaming JSONL log.
    .PARAMETER Path
        Output file path.
    .PARAMETER IncludeEvents
        If set, embed the full JSONL replay inside the export. Default
        off because it can produce multi-MB files.
    .PARAMETER Compress
        If set, single-line minified JSON. Default produces indented
        human-readable output.
    .OUTPUTS
        The output file path (for chaining).
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory=$true)] [string]$Path,
        [switch]$IncludeEvents,
        [switch]$Compress
    )

    # Refactor for robustness on PS 5.1 ja-JP. The previous
    # implementation used inline `if/else` expressions as hashtable values
    # and a property named `host` (which collides with the PS auto-
    # variable name in some parser contexts). User report on
    # 2026-05-17 showed AmbiguousParameterSet failure when
    # -ExportTraceOnExit triggered this function from the finally block.
    # This refactor:
    #   1. Pre-computes every hashtable value into a local variable so
    #      no `if/else` expression appears inside [pscustomobject]@{...}.
    #   2. Renames the `host` key to `hostInfo` defensively.
    #   3. Uses [Parameter(Mandatory=$true)] (explicit boolean) instead
    #      of bare [Parameter(Mandatory)] which is normally equivalent
    #      but has been observed to fail parameter-set resolution on
    #      some PS 5.1 builds.
    #   4. Adds Section 1b's Start-DebugTrace / Set-DebugStep instrumen-
    #      tation so any future failure surfaces the failing step name
    #      in the JSONL stream even if the JSON export itself can't be
    #      written.
    Start-DebugTrace -Context 'Export-DebugTraceJson'
    try {
        # ------ Section A: active frames (in-progress at snapshot time) -----
        Set-DebugStep 'build activeFrames array'
        $activeFrames = @()
        foreach ($f in $Script:DebugTraceStack.ToArray()) {
            $afStartedAtUtc = $f.StartTime.ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
            $afElapsedMs    = [int]((Get-Date) - $f.StartTime).TotalMilliseconds
            $afSteps        = @()
            foreach ($s in $f.Steps.ToArray()) {
                $afSteps += [pscustomobject]@{
                    step   = $s.Step
                    atUtc  = $s.At.ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
                    detail = $s.Detail
                }
            }
            $activeFrames += [pscustomobject]@{
                context      = $f.Context
                step         = $f.Step
                phaseId      = $f.PhaseId
                depth        = $f.Depth
                startedAtUtc = $afStartedAtUtc
                elapsedMs    = $afElapsedMs
                steps        = $afSteps
            }
        }

        # ------ Section B: completed frames (history) -----------------------
        Set-DebugStep 'build completedFrames array'
        $completedFrames = @()
        foreach ($f in $Script:DebugTraceCompletedFrames.ToArray()) {
            $cfStartedAtUtc = $f.StartTime.ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
            $cfEndedAtUtc = $null
            if ($f.PSObject.Properties['EndedAt'] -and $f.EndedAt) {
                $cfEndedAtUtc = $f.EndedAt.ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
            }
            $cfDurationMs = $null
            if ($f.PSObject.Properties['DurationMs']) {
                $cfDurationMs = $f.DurationMs
            }
            $cfSteps = @()
            foreach ($s in $f.Steps.ToArray()) {
                $cfSteps += [pscustomobject]@{
                    step   = $s.Step
                    atUtc  = $s.At.ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
                    detail = $s.Detail
                }
            }
            $completedFrames += [pscustomobject]@{
                context      = $f.Context
                phaseId      = $f.PhaseId
                outcome      = $f.Outcome
                depth        = $f.Depth
                startedAtUtc = $cfStartedAtUtc
                endedAtUtc   = $cfEndedAtUtc
                durationMs   = $cfDurationMs
                steps        = $cfSteps
            }
        }

        # ------ Section C: phase registry summary ---------------------------
        Set-DebugStep 'build phases array from registry'
        $phaseEntries = @()
        $sortedKeys = @($Script:DebugTracePhaseRegistry.Keys) | Sort-Object
        foreach ($key in $sortedKeys) {
            $reg = $Script:DebugTracePhaseRegistry[$key]
            $peStartedAtUtc = $null
            if ($reg.StartedAt) {
                $peStartedAtUtc = $reg.StartedAt.ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
            }
            $peEndedAtUtc = $null
            if ($reg.EndedAt) {
                $peEndedAtUtc = $reg.EndedAt.ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
            }
            $peFailure = $null
            if ($reg.FailureRef) {
                $peFailure = [pscustomobject]@{
                    failedStep       = $reg.FailureRef.FailedStep
                    exType           = $reg.FailureRef.ExType
                    exMessage        = $reg.FailureRef.ExMessage
                    innerType        = $reg.FailureRef.InnerType
                    innerMessage     = $reg.FailureRef.InnerMessage
                    fullyQualifiedId = $reg.FailureRef.FullyQualifiedId
                    scriptStackTrace = $reg.FailureRef.ScriptStackTrace
                }
            }
            $phaseEntries += [pscustomobject]@{
                phaseId      = $reg.PhaseId
                outcome      = $reg.Outcome
                startedAtUtc = $peStartedAtUtc
                endedAtUtc   = $peEndedAtUtc
                failure      = $peFailure
            }
        }

        # ------ Section D: optional JSONL event replay ---------------------
        Set-DebugStep 'optional: replay JSONL events'
        $events = @()
        if ($IncludeEvents -and $Script:DebugTraceJsonlPath -and (Test-Path -LiteralPath $Script:DebugTraceJsonlPath)) {
            try {
                $eventLines = Get-Content -LiteralPath $Script:DebugTraceJsonlPath -ErrorAction Stop
                foreach ($l in $eventLines) {
                    if ([string]::IsNullOrWhiteSpace($l)) { continue }
                    try {
                        $events += (ConvertFrom-Json -InputObject $l -ErrorAction Stop)
                    } catch {
                        # Skip lines that don't parse (malformed truncation).
                    }
                }
            } catch {
                # Ignore file-read errors; events stays empty.
            }
        }
        $eventsToSerialize = @()
        $eventCount = -1
        if ($IncludeEvents) {
            $eventsToSerialize = $events
            $eventCount = $events.Count
        }

        # ------ Section E: host + script metadata (pre-computed) ------------
        Set-DebugStep 'compose host + script metadata'
        # Pre-compute the host metadata as a standalone variable so no
        # inline expression appears in the outer hashtable. Renamed key
        # from 'host' to 'hostInfo' to avoid any chance of collision
        # with the $Host auto-variable on PS 5.1.
        $hostInfo = [pscustomobject]@{
            psVersion   = $PSVersionTable.PSVersion.ToString()
            psEdition   = $PSVersionTable.PSEdition
            clrVersion  = $PSVersionTable.CLRVersion.ToString()
            os          = ([System.Environment]::OSVersion.VersionString)
            culture     = (Get-Culture).Name
            uiCulture   = (Get-UICulture).Name
            hostName    = $Host.Name
            hostVersion = $Host.Version.ToString()
        }
        $scriptStartedAtUtc = $null
        if ($Script:ScriptStartTime) {
            $scriptStartedAtUtc = $Script:ScriptStartTime.ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
        }
        $scriptInfo = [pscustomobject]@{
            version      = $Script:ScriptVersion
            tag          = $Script:ScriptTag
            sha256       = $Script:ScriptHash
            startedAtUtc = $scriptStartedAtUtc
        }
        $fileOutputStatus = Get-DebugTraceFileOutputStatus
        $exportedAtUtcVal = _DebugTrace_Now

        # ------ Section F: compose final snapshot --------------------------
        Set-DebugStep 'compose final snapshot pscustomobject'
        $snapshot = [pscustomobject]@{
            schemaVersion   = '1'
            exportedAtUtc   = $exportedAtUtcVal
            hostInfo        = $hostInfo
            script          = $scriptInfo
            fileOutput      = $fileOutputStatus
            phases          = $phaseEntries
            activeFrames    = $activeFrames
            completedFrames = $completedFrames
            events          = $eventsToSerialize
            eventCount      = $eventCount
        }

        # ------ Section G: ensure output directory exists ------------------
        Set-DebugStep 'ensure parent directory exists'
        # IMPORTANT: [System.IO.Path]::GetDirectoryName instead of
        # `Split-Path -LiteralPath $Path -Parent`. On PS 5.1, those two
        # parameters belong to mutually-exclusive parameter sets
        # (LiteralPathSet vs ParentSet), which causes
        # AmbiguousParameterSet at runtime. The.NET method has no such
        # constraint and behaves identically.
        $parentDir = [System.IO.Path]::GetDirectoryName($Path)
        if ($parentDir -and -not (Test-Path -LiteralPath $parentDir)) {
            New-Item -ItemType Directory -Path $parentDir -Force -ErrorAction SilentlyContinue | Out-Null
        }

        # ------ Section H: serialize and write to disk ---------------------
        Set-DebugStep 'ConvertTo-Json + write to disk'
        # Render with the configured max depth so deeply nested objects
        # (especially ExInner chains and step details) never get clipped.
        if ($Compress) {
            $json = $snapshot | ConvertTo-Json -Depth $Script:DebugTraceJsonDepth -Compress
        } else {
            $json = $snapshot | ConvertTo-Json -Depth $Script:DebugTraceJsonDepth
        }
        # UTF-8 with BOM so the file is correctly read on PS 5.1 ja-JP
        # via `Get-Content` (default) without `-Encoding UTF8`.
        [System.IO.File]::WriteAllText($Path, $json, [System.Text.UTF8Encoding]::new($true))

        Set-DebugStep 'return result path'
        return $Path
    } catch {
        # Surface the failing checkpoint via the Debug Trace Facility
        # itself - this records a failure event in the JSONL stream with
        # the step name + exception details. Then re-throw so the outer
        # caller (e.g. finally block) can warn the user.
        Write-DebugFailureReport $_ -IncludeStepHistory
        throw
    } finally {
        Stop-DebugTrace
    }
}

#####################################################################
# SECTION 1d: UEFI Secure Boot certificate baseline
#####################################################################
# Captures the runtime UEFI Secure Boot certificate / servicing state
# and (when present) hands off to Microsoft's official sample script
# %SystemRoot%\SecureBoot\ExampleRolloutScripts\Detect-SecureBootCertUpdateStatus.ps1
# for additional fleet-rollout telemetry (BucketId / ConfidenceLevel /
# event-log counts).
#
# Why this matters for this script:
#   This script's drivers ride on top of UEFI Secure Boot. The UEFI db
#   and KEK variables hold the firmware-level trust anchors. From mid-
#   2026 onward, Microsoft is rolling out new UEFI CA 2023 certificates
#   to replace the 2011 ones that begin expiring in June 2026.
#   While our self-signed driver chain is at a HIGHER layer than UEFI
#   (Windows cert stores + WDAC supplemental CI policy), a host with an
#   incomplete or errored UEFI cert update is a meaningful diagnostic
#   signal: bootloader trust may be in flux, the Secure-Boot-Update
#   scheduled task may be running concurrently, and rollback / BitLocker
#   prompts become more likely if I02 / I03 fire in that window.
#
# Two information sources, fused via a "hybrid C" pattern (per user choice):
#
#   1. Embedded path (always available):
#        - Confirm-SecureBootUEFI + Get-SecureBootUEFI db / kek
#        - HKLM:\SYSTEM\CurrentControlSet\Control\SecureBoot
#        - HKLM:\SYSTEM\CurrentControlSet\Control\SecureBoot\Servicing
#        - \Microsoft\Windows\PI\Secure-Boot-Update scheduled task
#
#   2. Microsoft sample path (best-effort, only on devices that received
#      KB5089549 / KB5087544 / KB5088863 or the WS2025 equivalent):
#        - %SystemRoot%\SecureBoot\ExampleRolloutScripts\Detect-SecureBootCertUpdateStatus.ps1
#      Adds BucketId / ConfidenceLevel / SkipReason / event-1801-1808
#      counts that we cannot reasonably reimplement here.
#
# Reference:
#   - Sample Secure Boot E2E Automation Guide (Microsoft KB 5084567)
#   - May 12, 2026 cumulative update notes (KB5089549) - introduces the
#     %SystemRoot%\SecureBoot\ExampleRolloutScripts folder.

function Get-SecureBootCertificateInventory {
    # Read UEFI Secure Boot state, certificate presence in db/KEK, and
    # the Servicing registry block. This is the embedded fallback used
    # when Microsoft's sample Detect script is NOT present on the host.
    # All access is read-only; failures are captured rather than thrown.
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    $inv = [pscustomobject]@{
        Source                              = 'Embedded'
        Generated                           = (Get-Date)
        Available                           = $false
        ErrorMessage                        = $null
        # Top-level Secure Boot state
        SecureBootEnabled                   = $null
        SecureBootDetectError               = $null
        # 1P certs (required on ALL Secure-Boot-enabled systems)
        FirstPartyDB2023Updated             = $null    # Windows UEFI CA 2023
        FirstPartyKEK2023Updated            = $null    # Microsoft Corporation KEK 2K CA 2023
        # 3P / IHV certs (required ONLY when 3P 2011 CA is present)
        ThirdParty2011CAPresent             = $null    # Microsoft Corporation UEFI CA 2011
        ThirdParty2023CertsRequired         = $null
        ThirdParty2023CertUpdated           = $null    # Microsoft UEFI CA 2023
        ThirdPartyOptionRom2023CertUpdated  = $null    # Microsoft Option ROM UEFI CA 2023
        # HKLM:\...\Control\SecureBoot
        HighConfidenceOptOut                = $null
        MicrosoftUpdateManagedOptIn         = $null
        AvailableUpdates                    = $null    # raw DWORD
        AvailableUpdatesHex                 = $null    # hex repr
        AvailableUpdatesPolicy              = $null    # GPO-set
        AvailableUpdatesPolicyHex           = $null
        # HKLM:\...\Control\SecureBoot\Servicing
        UEFICA2023Status                    = $null    # Updated / In-Progress / etc.
        UEFICA2023Error                     = $null
        UEFICA2023ErrorEvent                = $null
        # Servicing\DeviceAttributes
        OEMManufacturerName                 = $null
        OEMModelSystemFamily                = $null
        OEMModelNumber                      = $null
        FirmwareVersion                     = $null
        FirmwareReleaseDate                 = $null
        CanAttemptUpdateAfter               = $null
        # Scheduled task \Microsoft\Windows\PI\Secure-Boot-Update
        SecureBootTaskExists                = $false
        SecureBootTaskStatus                = $null
        SecureBootTaskEnabled               = $null
    }

    # ---- Top-level: Confirm-SecureBootUEFI ----
    try {
        $inv.SecureBootEnabled = [bool](Confirm-SecureBootUEFI -ErrorAction Stop)
    } catch {
        $inv.SecureBootDetectError = $_.Exception.Message
        # Fallback via registry
        try {
            $rv = Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecureBoot\State' `
                                   -Name UEFISecureBootEnabled -ErrorAction Stop
            $inv.SecureBootEnabled = [bool]$rv.UEFISecureBootEnabled
        } catch {
            # leave as $null
        }
    }

    # ---- Certificate presence in UEFI db / KEK ----
    # Only meaningful when Secure Boot is on AND we have admin (we do).
    if ($inv.SecureBootEnabled -eq $true) {
        try {
            $dbBytes  = (Get-SecureBootUEFI db -ErrorAction Stop).bytes
            $dbString = [System.Text.Encoding]::ASCII.GetString($dbBytes)
            $inv.FirstPartyDB2023Updated = if ($dbString -match 'Windows UEFI CA 2023') { 1 } else { 0 }
            $inv.ThirdParty2011CAPresent = if ($dbString -match 'Microsoft Corporation UEFI CA 2011') { 1 } else { 0 }
            $inv.ThirdParty2023CertsRequired = if ($inv.ThirdParty2011CAPresent -eq 1) { 1 } else { 0 }
            $inv.ThirdParty2023CertUpdated          = if (($inv.ThirdParty2023CertsRequired -eq 1) -and ($dbString -match 'Microsoft UEFI CA 2023'))           { 1 } else { 0 }
            $inv.ThirdPartyOptionRom2023CertUpdated = if (($inv.ThirdParty2023CertsRequired -eq 1) -and ($dbString -match 'Microsoft Option ROM UEFI CA 2023')) { 1 } else { 0 }
        } catch {
            # Unable to read db - leave related fields at $null
        }
        try {
            $kekBytes  = (Get-SecureBootUEFI kek -ErrorAction Stop).bytes
            $kekString = [System.Text.Encoding]::ASCII.GetString($kekBytes)
            $inv.FirstPartyKEK2023Updated = if ($kekString -match 'Microsoft Corporation KEK 2K CA 2023') { 1 } else { 0 }
        } catch {
            # leave $null
        }

        # If 1P certs are not both present, 3P-updated flags lose meaning
        if (($inv.FirstPartyDB2023Updated -eq 0) -or ($inv.FirstPartyKEK2023Updated -eq 0)) {
            $inv.ThirdParty2023CertUpdated          = 0
            $inv.ThirdPartyOptionRom2023CertUpdated = 0
        }
    }

    # ---- HKLM:\...\Control\SecureBoot (optional values) ----
    $sbKey = 'HKLM:\SYSTEM\CurrentControlSet\Control\SecureBoot'
    foreach ($name in 'HighConfidenceOptOut','MicrosoftUpdateManagedOptIn') {
        try {
            $rv = Get-ItemProperty -Path $sbKey -Name $name -ErrorAction Stop
            $inv.$name = $rv.$name
        } catch { } # psa-disable-line PSA3004 -- intentional best-effort cleanup; no error to surface
    }
    foreach ($name in 'AvailableUpdates','AvailableUpdatesPolicy') {
        try {
            $rv = Get-ItemProperty -Path $sbKey -Name $name -ErrorAction Stop
            $inv.$name = $rv.$name
            if ($null -ne $rv.$name) {
                $hexProp = "${name}Hex"
                $inv.$hexProp = ('0x{0:X}' -f [int]$rv.$name)
            }
        } catch { } # psa-disable-line PSA3004 -- intentional best-effort cleanup; no error to surface
    }

    # ---- HKLM:\...\Control\SecureBoot\Servicing ----
    $svcKey = 'HKLM:\SYSTEM\CurrentControlSet\Control\SecureBoot\Servicing'
    foreach ($name in 'UEFICA2023Status','UEFICA2023Error','UEFICA2023ErrorEvent') {
        try {
            $rv = Get-ItemProperty -Path $svcKey -Name $name -ErrorAction Stop
            $inv.$name = $rv.$name
        } catch { } # psa-disable-line PSA3004 -- intentional best-effort cleanup; no error to surface
    }

    # ---- Servicing\DeviceAttributes ----
    $daKey = 'HKLM:\SYSTEM\CurrentControlSet\Control\SecureBoot\Servicing\DeviceAttributes'
    foreach ($name in 'OEMManufacturerName','OEMModelSystemFamily','OEMModelNumber','FirmwareVersion','FirmwareReleaseDate') {
        try {
            $rv = Get-ItemProperty -Path $daKey -Name $name -ErrorAction Stop
            $inv.$name = $rv.$name
        } catch { } # psa-disable-line PSA3004 -- intentional best-effort cleanup; no error to surface
    }
    try {
        $rv = Get-ItemProperty -Path $daKey -Name 'CanAttemptUpdateAfter' -ErrorAction Stop
        $caua = $rv.CanAttemptUpdateAfter
        if ($null -ne $caua) {
            if ($caua -is [byte[]]) {
                $ft = [BitConverter]::ToInt64($caua, 0)
                $inv.CanAttemptUpdateAfter = [DateTime]::FromFileTime($ft).ToUniversalTime()
            } elseif ($caua -is [long] -or $caua -is [int64]) {
                $inv.CanAttemptUpdateAfter = [DateTime]::FromFileTime($caua).ToUniversalTime()
            } else {
                $inv.CanAttemptUpdateAfter = $caua
            }
        }
    } catch { } # psa-disable-line PSA3004 -- intentional best-effort cleanup; no error to surface

    # ---- Scheduled task \Microsoft\Windows\PI\Secure-Boot-Update ----
    # Use the PowerShell-native Get-ScheduledTask cmdlet rather than
    # schtasks.exe /FO CSV. schtasks emits LOCALIZED CSV column headers
    # on non-English Windows (e.g. ja-JP returns the header in Japanese),
    # which breaks $row.Status property access and silently mis-reports
    # the task as 'Disabled' even when it is in fact Ready/Running.
    # Get-ScheduledTask returns CIM objects with locale-independent
    # English property names (.State = Ready / Running / Disabled /...).
    try {
        $task = Get-ScheduledTask -TaskPath '\Microsoft\Windows\PI\' -TaskName 'Secure-Boot-Update' -ErrorAction Stop
        if ($task) {
            $inv.SecureBootTaskExists  = $true
            $inv.SecureBootTaskStatus  = "$($task.State)"   # 'Ready' / 'Running' / 'Disabled' / 'Queued' / 'Unknown'
            $inv.SecureBootTaskEnabled = ($task.State -eq 'Ready' -or $task.State -eq 'Running')
        }
    } catch {
        # Task missing OR Get-ScheduledTask unavailable (very old PS).
        # Fall back to schtasks /Query just for existence detection;
        # status will remain locale-dependent but presence is unambiguous.
        try {
            $null = schtasks.exe /Query /TN '\Microsoft\Windows\PI\Secure-Boot-Update' /FO LIST 2>&1
            if ($LASTEXITCODE -eq 0) {
                $inv.SecureBootTaskExists  = $true
                $inv.SecureBootTaskStatus  = 'present (state unknown - schtasks fallback)'
                $inv.SecureBootTaskEnabled = $null
            }
        } catch { } # psa-disable-line PSA3004 -- intentional best-effort cleanup; no error to surface
    }

    $inv.Available = $true
    return $inv
}

function Get-MsSecureBootExampleScriptPath {
    # Detect whether the official Microsoft sample scripts (delivered by
    # KB5089549 / KB5087544 / KB5088863 from 2026-05-12 onward) are
    # deployed on this host. Returns a small descriptor object with
    # Present flag and per-script paths.
    [CmdletBinding()]
    param()

    $root = Join-Path $env:SystemRoot 'SecureBoot\ExampleRolloutScripts'
    $detect = Join-Path $root 'Detect-SecureBootCertUpdateStatus.ps1'
    $enable = Join-Path $root 'Enable-SecureBootUpdateTask.ps1'

    [pscustomobject]@{
        Present       = (Test-Path -LiteralPath $detect)
        RootPath      = $root
        DetectScript  = if (Test-Path -LiteralPath $detect) { $detect } else { $null }
        EnableScript  = if (Test-Path -LiteralPath $enable) { $enable } else { $null }
    }
}

function Invoke-MsSecureBootDetectScript {
    # Invoke %SystemRoot%\SecureBoot\ExampleRolloutScripts\Detect-SecureBootCertUpdateStatus.ps1
    # in a child PowerShell session with -OutputPath set to a transient
    # folder under the AMD workspace, then re-parse the resulting JSON.
    #
    # Returns a hybrid result object..Available indicates whether the
    # script ran AND produced parseable JSON. Failures (script missing,
    # non-zero exit + no JSON, parse errors, etc.) populate.ErrorMessage
    # and leave.Data null - callers should fall back to the embedded
    # inventory in that case.
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)] [string]$WorkRoot,
        [string]$DetectScriptPath
    )

    $result = [pscustomobject]@{
        Source       = 'Microsoft'
        Generated    = (Get-Date)
        Available    = $false
        ErrorMessage = $null
        ScriptPath   = $null
        JsonPath     = $null
        ExitCode     = $null
        Data         = $null
    }

    if (-not $DetectScriptPath) {
        $info = Get-MsSecureBootExampleScriptPath
        if (-not $info.Present) {
            $result.ErrorMessage = 'Detect-SecureBootCertUpdateStatus.ps1 not present (KB5089549/5087544/5088863 or WS2025 equivalent not installed, or device not eligible).'
            return $result
        }
        $DetectScriptPath = $info.DetectScript
    }
    $result.ScriptPath = $DetectScriptPath

    if (-not (Test-Path -LiteralPath $DetectScriptPath)) {
        $result.ErrorMessage = "Detect script not found: $DetectScriptPath"
        return $result
    }

    # Output folder under the AMD workspace (created if missing)
    $outDir = Join-Path $WorkRoot 'secureboot_ms_sample'
    try {
        if (-not (Test-Path -LiteralPath $outDir)) {
            New-Item -ItemType Directory -Path $outDir -Force | Out-Null
        }
    } catch {
        $result.ErrorMessage = "Could not create output directory $outDir : $($_.Exception.Message)"
        return $result
    }

    # Microsoft's sample writes "$HOSTNAME_latest.json" under -OutputPath
    $expectedJson = Join-Path $outDir ("$env:COMPUTERNAME" + '_latest.json')

    # Run in a child PowerShell. Determine the executable path from
    # $PSHOME and the current edition rather than Get-Process -Id $PID
    # (which can return the parent host - e.g. ISE / VS Code - rather
    # than a usable powershell.exe / pwsh.exe). Falls back to PATH
    # lookup if the resolved file is somehow missing.
    $psExeName = if ($PSVersionTable.PSEdition -eq 'Core') { 'pwsh.exe' } else { 'powershell.exe' }
    $psExe = Join-Path $PSHOME $psExeName
    if (-not (Test-Path -LiteralPath $psExe)) {
        # Fall back to PATH resolution; if even that fails, let the
        # invocation below surface the error.
        $psExe = $psExeName
    }

    # NOTE: variable named $psArgs (NOT $args) to avoid clobbering the
    # automatic $args variable that PowerShell uses for unbound
    # positional parameters in the enclosing function scope.
    $psArgs = @(
        '-NoProfile'
        '-NonInteractive'
        '-ExecutionPolicy','Bypass'
        '-File', $DetectScriptPath
        '-OutputPath', $outDir
    )

    try {
        $stdout = & $psExe @psArgs 2>&1
        $result.ExitCode = $LASTEXITCODE
        # Microsoft's script returns exit code 0 (certs updated) or 1
        # (not yet updated). Both are SUCCESSFUL invocations from our
        # POV - we treat any other code, or missing JSON, as failure.
        $stdoutText = ($stdout | Out-String)
        if ($result.ExitCode -notin 0,1) {
            $result.ErrorMessage = "Detect script exited with code $($result.ExitCode). stdout/err head: " + ($stdoutText.Substring(0, [Math]::Min(400, $stdoutText.Length)))
        }
    } catch {
        $result.ErrorMessage = "Failed to launch detect script: $($_.Exception.Message)"
        return $result
    }

    # Save the raw stdout for diagnostic purposes (helps debug when the
    # detect script behaves unexpectedly in the wild). Best-effort: a
    # write failure here is non-fatal.
    try {
        $stdoutPath = Join-Path $outDir 'detect_stdout.log'
        Set-Content -LiteralPath $stdoutPath -Value $stdoutText -Encoding UTF8 -Force
    } catch { } # psa-disable-line PSA3004 -- intentional best-effort cleanup; no error to surface

    # Try the file-based JSON path first (clean case: MS script accepted
    # our -OutputPath and wrote HOSTNAME_latest.json).
    if (Test-Path -LiteralPath $expectedJson) {
        $result.JsonPath = $expectedJson
        try {
            $raw = Get-Content -LiteralPath $expectedJson -Raw -Encoding UTF8
            $obj = $raw | ConvertFrom-Json
            $result.Data = $obj
            $result.Available = $true
            return $result
        } catch {
            $result.ErrorMessage = "Failed to parse JSON output at ${expectedJson}: $($_.Exception.Message)"
            # Fall through to stdout-parsing fallback
        }
    }

    # Fallback: extract JSON from captured stdout. This is required
    # because the Microsoft sample script (as of the 2026-05-12 delivery)
    # has an over-aggressive input validator that rejects ANY -OutputPath
    # containing ':' (which includes every absolute Windows path with a
    # drive letter). When validation fires, the script prints
    #   "Invalid OutputPath specified, outputting to stdout"
    # and then Write-Output's the JSON to stdout. We capture stdout
    # anyway (2>&1 above), so we can recover the JSON from there.
    try {
        # The detect script emits many Write-Host lines first, then the
        # JSON object at the end. Strategy: scan for the LAST occurrence
        # of a top-level '{' followed by a property the JSON always has
        # ("Hostname", "UEFICA2023Status", etc.), then take from that
        # '{' to the matching '}'.
        $json = $null
        # Look for the start of the JSON object. ConvertTo-Json output is
        # human-formatted by default, so the object opens at column 1 on
        # its own line: "^{" with leading whitespace.
        # NOTE: variable named $jsonMatches (NOT $matches) to avoid
        # clobbering the PowerShell automatic $matches that holds the
        # result of the -match operator.
        $jsonMatches = [regex]::Matches($stdoutText, '(?ms)^\s*\{[^{]*"(Hostname|UEFICA2023Status|SecureBootEnabled)"\s*:')
        if ($jsonMatches.Count -gt 0) {
            # Take the LAST match (in case earlier output happens to contain
            # a similar pattern - very unlikely but defensive).
            $start = $jsonMatches[$jsonMatches.Count - 1].Index
            # Find matching closing brace by counting depth from $start.
            $depth = 0
            $end = -1
            for ($i = $start; $i -lt $stdoutText.Length; $i++) {
                $c = $stdoutText[$i]
                if ($c -eq '{') { $depth++ }
                elseif ($c -eq '}') {
                    $depth--
                    if ($depth -eq 0) { $end = $i; break }
                }
            }
            if ($end -gt $start) {
                $json = $stdoutText.Substring($start, $end - $start + 1)
            }
        }

        if ($json) {
            $obj = $json | ConvertFrom-Json
            $result.Data = $obj
            $result.Available = $true
            $result.JsonPath = '(stdout fallback - file output rejected by MS script path validator)'
            # Optional: also persist the extracted JSON for forensics.
            try {
                $jsonRecoveryPath = Join-Path $outDir 'detect_stdout_extracted.json'
                Set-Content -LiteralPath $jsonRecoveryPath -Value $json -Encoding UTF8 -Force
                $result.JsonPath = $jsonRecoveryPath
            } catch { } # psa-disable-line PSA3004 -- intentional best-effort cleanup; no error to surface
            $result.ErrorMessage = $null     # clear earlier "file not found" message
            return $result
        }
    } catch {
        # Fall through to the final error path
    }

    if (-not $result.ErrorMessage) {
        $result.ErrorMessage = "Detect script ran but neither file output nor stdout JSON could be parsed. See $stdoutPath for raw output."
    }
    return $result
}


function Format-SecureBootBaselineForReport {
    # Render the baseline snapshot as a plain-text section suitable for
    # appending to inf_inventory_report.txt. Mirrors the on-screen V06
    # block but without colour codes / cursor positioning.
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)] $Snapshot
    )

    if (-not $Snapshot) { return '' }
    $emb = $Snapshot.Embedded
    $ms  = $Snapshot.Microsoft

    $sb = New-Object System.Text.StringBuilder
    [void]$sb.AppendLine(("=" * 78))
    [void]$sb.AppendLine('UEFI Secure Boot Baseline')
    [void]$sb.AppendLine(("=" * 78))
    [void]$sb.AppendLine("Captured       : $($Snapshot.Generated.ToString('yyyy-MM-dd HH:mm:ss'))")
    [void]$sb.AppendLine("Overall health : $($Snapshot.Health)")
    if ($Snapshot.Reasons.Count -gt 0) {
        [void]$sb.AppendLine('Reasons        :')
        foreach ($r in $Snapshot.Reasons) {
            [void]$sb.AppendLine("  - $r")
        }
    }
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine('-- Embedded inventory ' + ('-' * 56))
    [void]$sb.AppendLine("Secure Boot enabled               : $(if ($null -eq $emb.SecureBootEnabled) { 'unknown' } else { $emb.SecureBootEnabled })")
    if ($emb.SecureBootDetectError) {
        [void]$sb.AppendLine("  Detect error                    : $($emb.SecureBootDetectError)")
    }
    [void]$sb.AppendLine("Windows UEFI CA 2023 (db, 1P)     : $(if ($null -eq $emb.FirstPartyDB2023Updated)  { 'n/a' } elseif ($emb.FirstPartyDB2023Updated  -eq 1) { 'present' } else { 'NOT present' })")
    [void]$sb.AppendLine("Microsoft KEK 2K CA 2023 (KEK, 1P): $(if ($null -eq $emb.FirstPartyKEK2023Updated) { 'n/a' } elseif ($emb.FirstPartyKEK2023Updated -eq 1) { 'present' } else { 'NOT present' })")
    [void]$sb.AppendLine("Microsoft UEFI CA 2011 (db, 3P)   : $(if ($null -eq $emb.ThirdParty2011CAPresent)  { 'n/a' } elseif ($emb.ThirdParty2011CAPresent  -eq 1) { 'present (3P trusted)' } else { 'not present (1P-only trust)' })")
    if ($emb.ThirdParty2023CertsRequired -eq 1) {
        [void]$sb.AppendLine("Microsoft UEFI CA 2023 (db, 3P)        : $(if ($null -eq $emb.ThirdParty2023CertUpdated)          { 'n/a' } elseif ($emb.ThirdParty2023CertUpdated          -eq 1) { 'present' } else { 'NOT present' })")
        [void]$sb.AppendLine("Microsoft Option ROM UEFI CA 2023 (3P) : $(if ($null -eq $emb.ThirdPartyOptionRom2023CertUpdated) { 'n/a' } elseif ($emb.ThirdPartyOptionRom2023CertUpdated -eq 1) { 'present' } else { 'NOT present' })")
    }
    [void]$sb.AppendLine("UEFI CA 2023 status (registry)         : $(if ($emb.UEFICA2023Status) { $emb.UEFICA2023Status } else { 'n/a' })")
    if ($emb.UEFICA2023Error) {
        [void]$sb.AppendLine("UEFI CA 2023 error code                : $($emb.UEFICA2023Error)")
    }
    [void]$sb.AppendLine("AvailableUpdates                       : $(if ($emb.AvailableUpdatesHex)       { $emb.AvailableUpdatesHex       } else { 'n/a' })")
    [void]$sb.AppendLine("AvailableUpdatesPolicy                 : $(if ($emb.AvailableUpdatesPolicyHex) { $emb.AvailableUpdatesPolicyHex } else { 'n/a' })")
    [void]$sb.AppendLine("HighConfidenceOptOut                   : $(if ($null -ne $emb.HighConfidenceOptOut) { $emb.HighConfidenceOptOut } else { 'n/a' })")
    [void]$sb.AppendLine("MicrosoftUpdateManagedOptIn            : $(if ($null -ne $emb.MicrosoftUpdateManagedOptIn) { $emb.MicrosoftUpdateManagedOptIn } else { 'n/a' })")
    [void]$sb.AppendLine("OEM Manufacturer                       : $(if ($emb.OEMManufacturerName) { $emb.OEMManufacturerName } else { 'n/a' })")
    [void]$sb.AppendLine("OEM Model SystemFamily / Number        : $(if ($emb.OEMModelSystemFamily) { $emb.OEMModelSystemFamily } else { 'n/a' }) / $(if ($emb.OEMModelNumber) { $emb.OEMModelNumber } else { 'n/a' })")
    [void]$sb.AppendLine("Firmware Version / ReleaseDate         : $(if ($emb.FirmwareVersion) { $emb.FirmwareVersion } else { 'n/a' }) / $(if ($emb.FirmwareReleaseDate) { $emb.FirmwareReleaseDate } else { 'n/a' })")
    if ($emb.CanAttemptUpdateAfter) {
        [void]$sb.AppendLine("CanAttemptUpdateAfter (UTC)            : $($emb.CanAttemptUpdateAfter)")
    }
    $sbTaskText = if (-not $emb.SecureBootTaskExists) {
        'task not present'
    } elseif ($null -eq $emb.SecureBootTaskEnabled) {
        "state=$($emb.SecureBootTaskStatus) (enabled-check skipped)"
    } elseif ($emb.SecureBootTaskEnabled) {
        "Ready/Running (state=$($emb.SecureBootTaskStatus))"
    } else {
        "Not running (state=$($emb.SecureBootTaskStatus))"
    }
    [void]$sb.AppendLine("Secure-Boot-Update scheduled task      : $sbTaskText")

    [void]$sb.AppendLine('')
    [void]$sb.AppendLine('-- Microsoft sample script (KB5089549+ delivery) ' + ('-' * 26))
    if (-not $Snapshot.MsInfo.Present) {
        [void]$sb.AppendLine("Status         : NOT deployed on this host.")
        [void]$sb.AppendLine("Expected path  : $($Snapshot.MsInfo.RootPath)")
        [void]$sb.AppendLine("Result         : Embedded inventory above is the sole source.")
    } elseif (-not $ms -or -not $ms.Available) {
        [void]$sb.AppendLine("Status         : Present but invocation failed.")
        if ($ms -and $ms.ErrorMessage) {
            [void]$sb.AppendLine("Error          : $($ms.ErrorMessage)")
        }
    } else {
        $d = $ms.Data
        [void]$sb.AppendLine("Status         : Invoked successfully.")
        [void]$sb.AppendLine("Script path    : $($ms.ScriptPath)")
        [void]$sb.AppendLine("JSON path      : $($ms.JsonPath)")
        [void]$sb.AppendLine("BucketId       : $(if ($d.BucketId)   { $d.BucketId   } else { 'n/a' })")
        [void]$sb.AppendLine("Confidence     : $(if ($d.Confidence) { $d.Confidence } else { 'n/a' })")
        if ($d.SkipReasonKnownIssue) {
            [void]$sb.AppendLine("SkipReason     : $($d.SkipReasonKnownIssue)")
        }
        if ($d.KnownIssueId) {
            [void]$sb.AppendLine("KnownIssueId   : $($d.KnownIssueId)")
        }
        $evtLines = @()
        foreach ($f in 'Event1801Count','Event1808Count','Event1795Count','Event1796Count','Event1800Count','Event1802Count','Event1803Count') {
            $v = $d.$f
            if ($v -and ([int]$v -gt 0)) { $evtLines += ("  $f = $v") }
        }
        if ($evtLines.Count -gt 0) {
            [void]$sb.AppendLine('Event counts   :')
            foreach ($l in $evtLines) { [void]$sb.AppendLine($l) }
        }
        if ($d.MissingKEK) {
            [void]$sb.AppendLine('MissingKEK     : TRUE (OEM needs to supply PK-signed KEK)')
        }
        if ($d.RebootPending) {
            [void]$sb.AppendLine('RebootPending  : TRUE (Event 1800 was observed)')
        }
        if ($d.WinCSKeyStatus) {
            [void]$sb.AppendLine("WinCSKeyStatus : $($d.WinCSKeyStatus)")
        }
    }
    [void]$sb.AppendLine('')
    return $sb.ToString()
}

#####################################################################
# SECTION 1e: WDAC (Windows Defender Application Control)
# supplemental-policy helpers
#####################################################################
# These helpers exist to keep Secure Boot ENABLED while still allowing
# this script's self-signed code-signing certificate to load
# kernel-mode drivers. The mechanism is a WDAC "supplemental" Code
# Integrity policy:
#
#   - The base CI policy (default Windows policy) keeps enforcing
#     Microsoft-rooted signing.
#   - A supplemental policy is deployed alongside the base, ADDING the
#     self-signed cert as an allowed kernel-mode signer.
#   - On Server 2022+/Windows 11, CiTool.exe activates the supplemental
#     immediately (no reboot). On older systems, a reboot is required.
#
# Why this is preferable to bcdedit testsigning:
#   testsigning is silently dropped at boot when Secure Boot is on.
#   The user would have to disable Secure Boot in firmware - which
#   weakens the platform and may force BitLocker recovery.
#   WDAC supplemental policies are the supported, documented path to
#   "trust this additional publisher" with Secure Boot still on.
#
# Required platform components (all present on WS2022+ / WS2025):
#   - PowerShell 'ConfigCI' module (cmdlets: Add-SignerRule,
#                                             ConvertFrom-CIPolicy,
#                                             Set-CIPolicyIdInfo)
#   - C:\Windows\System32\CiTool.exe (immediate activation)
#   - WDAC AllowAll template under
#     C:\Windows\schemas\CodeIntegrity\ExamplePolicies\AllowAll.xml
#
# A marker file (Cert dir / 'AmdSuppPolicyId.txt') records the
# deployed policy ID so we can detect & uninstall later.

function Test-WdacToolsAvailable {
    # Inspect the platform for the prerequisites needed to build &
    # deploy a WDAC supplemental policy. Returns a structured report
    # so callers can present a precise error if something is missing.
    $caps = [pscustomobject]@{
        ConfigCiModule        = $false
        CiToolExe             = $false
        AllowAllTemplate      = $false
        ActivePoliciesDir     = $false
        AnyUsable             = $false
        ImmediateActivation   = $false
        Detail                = @()
    }

    if (Get-Module -ListAvailable -Name 'ConfigCI' -ErrorAction SilentlyContinue) {
        $caps.ConfigCiModule = $true
    } else {
        $caps.Detail += 'ConfigCI PowerShell module is not installed (cmdlets Add-SignerRule, ConvertFrom-CIPolicy, etc. unavailable)'
    }

    $citool = Get-Command CiTool.exe -ErrorAction SilentlyContinue
    if ($citool) {
        $caps.CiToolExe = $true
        $caps.ImmediateActivation = $true
    } else {
        $caps.Detail += 'CiTool.exe not found - policy deployment will require a reboot'
    }

    $template = Join-Path $env:windir 'schemas\CodeIntegrity\ExamplePolicies\AllowAll.xml'
    if (Test-Path $template) {
        $caps.AllowAllTemplate = $true
    } else {
        $caps.Detail += "AllowAll WDAC template missing at $template"
    }

    $activeDir = Join-Path $env:windir 'System32\CodeIntegrity\CiPolicies\Active'
    if (Test-Path $activeDir) {
        $caps.ActivePoliciesDir = $true
    } else {
        $caps.Detail += "Active CI policies directory missing at $activeDir"
    }

    $caps.AnyUsable = ($caps.ConfigCiModule -and $caps.AllowAllTemplate -and $caps.ActivePoliciesDir)
    return $caps
}

function Get-ActiveCodeIntegrityPolicies { # psa-disable-line PSA6003 -- compound noun (e.g., Policies, Drivers, Catalogs) is semantically plural for set-returning helpers
    # Enumerate currently-active CI policies. Prefers CiTool.exe (gives
    # full metadata: name, mode, base/supplemental, signed/unsigned).
    # Falls back to filesystem enumeration of the Active directory if
    # CiTool isn't available.
    $policies = @()

    if (Get-Command CiTool.exe -ErrorAction SilentlyContinue) {
        try {
            $raw = & CiTool.exe -lp -json 2>&1 | Out-String
            if ($LASTEXITCODE -eq 0 -and $raw.Trim()) {
                $parsed = $raw | ConvertFrom-Json -ErrorAction Stop
                $list = if ($parsed.Policies) { $parsed.Policies } else { $parsed }
                foreach ($p in $list) {
                    $policies += [pscustomobject]@{
                        PolicyId       = $p.PolicyID
                        BasePolicyId   = $p.BasePolicyID
                        Name           = $p.FriendlyName
                        IsSystemPolicy = [bool]$p.IsSystemPolicy
                        IsEnforced     = [bool]$p.IsEnforced
                        IsSignedPolicy = [bool]$p.IsSignedPolicy
                        IsSupplemental = ($p.PolicyID -ne $p.BasePolicyID)
                        Path           = $p.PolicyPath
                        Source         = 'CiTool'
                    }
                }
            }
        } catch {
            # Swallow and try filesystem fallback
        }
    }

    if ($policies.Count -eq 0) {
        $activeDir = Join-Path $env:windir 'System32\CodeIntegrity\CiPolicies\Active'
        if (Test-Path $activeDir) {
            foreach ($f in (Get-ChildItem $activeDir -Filter '*.cip' -ErrorAction SilentlyContinue)) {
                $policies += [pscustomobject]@{
                    PolicyId       = $f.BaseName
                    BasePolicyId   = $null
                    Name           = '(unknown - filesystem only)'
                    IsSystemPolicy = $null
                    IsEnforced     = $null
                    IsSignedPolicy = $null
                    IsSupplemental = $null
                    Path           = $f.FullName
                    Source         = 'filesystem'
                }
            }
        }
    }

    return $policies
}


# ---- SPF (Single Policy Format) helpers - r67 orchestrator additions ----
# These are the SPF analogues of the per-driver-family supplemental-policy
# helpers (New-AmdDriverWdacSupplementalPolicy / Install-AmdWdacPolicy /
# Uninstall-AmdWdacPolicy) that exist in the driver scripts. Key differences:
#
#   - SPF deploys a BASE policy to %WINDIR%\System32\CodeIntegrity\
#     SiPolicy.p7b, NOT a supplemental to Active\{GUID}.cip.
#   - SPF accepts MULTIPLE certs (one per driver script in the
#     allowlist) instead of a single cert.
#   - SPF activation uses ONLY the CIM bridge
#     PS_UpdateAndCompareCIPolicy.Update() because CiTool.exe is not
#     present on WS2019 / WS2016 (where this orchestrator runs).
#
# The WS2025 build 26100 schema fix from
# New-AmdDriverWdacSupplementalPolicy (strip the entire <FileRulesRef>
# container, not just <FileRuleRef> children) is REPLICATED verbatim
# here because WS2019's AllowAll.xml template may have the same
# variant once Microsoft backports schema updates via security
# updates. Either way the strip is defensive and schema-valid.

function New-WdacSpfBasePolicy {
    # Build a WDAC SPF base-policy XML that allowlists the provided
    # certs as kernel-mode signers. PolicyID is forced to the project-
    # reserved GUID so re-runs replace the same slot rather than
    # accumulating policies.
    param(
        [Parameter(Mandatory=$true)][string[]]$CerFiles,
        [Parameter(Mandatory=$true)][string]$OutputXml,
        [string]$PolicyName = 'Deploy-Drivers-For-WindowsServer WDAC SPF (script-managed)',
        [string]$PolicyId   = $Script:ReservedPolicyId,
        [bool]$AuditMode    = $false
    )

    foreach ($cer in $CerFiles) {
        if (-not (Test-Path -LiteralPath $cer)) {
            throw "Certificate not found at $cer"
        }
    }
    $template = Join-Path $env:windir 'schemas\CodeIntegrity\ExamplePolicies\AllowAll.xml'
    if (-not (Test-Path -LiteralPath $template)) {
        throw "WDAC AllowAll template missing at $template"
    }

    $policyIdBraced = if ($PolicyId -match '^\{.*\}$') { $PolicyId } else { '{' + $PolicyId + '}' }

    # Step 1: copy AllowAll template (valid schema scaffolding)
    Copy-Item -LiteralPath $template -Destination $OutputXml -Force

    # Step 2: set policy name. We deliberately do NOT call
    # -SupplementsBasePolicyID here (this is a base policy).
    # PolicyID is patched in Step 2b because Set-CIPolicyIdInfo has
    # no -PolicyId switch and -ResetPolicyID would randomize.
    Set-CIPolicyIdInfo -FilePath $OutputXml -PolicyName $PolicyName | Out-Null

    # Step 2b: patch PolicyID + BasePolicyID directly into the XML.
    # For SPF base policy, both elements must equal the reserved GUID.
    # Pattern adapted from Chipset r66 L3776-3791 (the per-script
    # supplemental's PolicyID rewrite), with schema-variant fallback.
    [xml]$xmlForId = Get-Content -LiteralPath $OutputXml
    $nsForId = New-Object System.Xml.XmlNamespaceManager($xmlForId.NameTable)
    $nsForId.AddNamespace('si', 'urn:schemas-microsoft-com:sipolicy')
    foreach ($elem in @('PolicyID','BasePolicyID')) {
        $node = $xmlForId.SelectSingleNode(("//si:SiPolicy/si:{0}" -f $elem), $nsForId)
        if (-not $node) {
            try {
                $xmlForId.SiPolicy.$elem = $policyIdBraced
            } catch {
                # Last-ditch: create the element. # psa-disable-line PSA3004 -- intentional best-effort fallback for schema-variant edge case
                $newNode = $xmlForId.CreateElement($elem, 'urn:schemas-microsoft-com:sipolicy')
                $newNode.InnerText = $policyIdBraced
                $null = $xmlForId.DocumentElement.AppendChild($newNode)
            }
        }
        if ($node -and ($node -isnot [string])) {
            $node.InnerText = $policyIdBraced
        }
    }
    $xmlForId.Save($OutputXml)

    # Step 3: strip catch-all rules from AllowAll template so the
    # resulting policy ONLY allowlists OUR certs.
    #
    # *** CRITICAL: WS2025 build 26100 schema fix (verbatim from Chipset
    #     r66 L3809-3827) ***
    # Strip the ENTIRE <FileRulesRef> container, not just its
    # <FileRuleRef> children. On WS2025 the AllowAll template embeds
    # <FileRulesRef> inside <ProductSigners> blocks, and the schema
    # requires <FileRulesRef> to contain at least one <FileRuleRef>.
    # Leaving an empty <FileRulesRef> makes Add-SignerRule fail with:
    #   "Element 'FileRulesRef' has incomplete content."
    # <FileRulesRef> itself is minOccurs=0, so removing the container
    # outright is schema-valid.
    [xml]$xml = Get-Content -LiteralPath $OutputXml
    $ns = New-Object System.Xml.XmlNamespaceManager($xml.NameTable)
    $ns.AddNamespace('si', 'urn:schemas-microsoft-com:sipolicy')
    $stripPaths = @(
        '//si:FileRules/si:Allow',
        '//si:FileRules/si:Deny',
        '//si:FileRules/si:FileAttrib',
        '//si:Signers/si:Signer',
        '//si:SigningScenarios/si:SigningScenario/si:ProductSigners/si:AllowedSigners/si:AllowedSigner',
        '//si:SigningScenarios/si:SigningScenario/si:ProductSigners/si:DeniedSigners/si:DeniedSigner',
        '//si:SigningScenarios/si:SigningScenario/si:ProductSigners/si:FileRulesRef',
        '//si:CiSigners/si:CiSigner',
        '//si:UpdatePolicySigners/si:UpdatePolicySigner'
    )
    foreach ($xp in $stripPaths) {
        $nodes = $xml.SelectNodes($xp, $ns)
        foreach ($n in @($nodes)) { [void]$n.ParentNode.RemoveChild($n) }
    }
    $xml.Save($OutputXml)

    # Step 4: add each cert as kernel-mode signer.
    foreach ($cer in $CerFiles) {
        Add-SignerRule -FilePath $OutputXml -CertificatePath $cer -Kernel | Out-Null
    }

    # Step 5: SPF Rule Options. See SPEC §D.25.
    #   6  = Enabled:Unsigned System Integrity Policy (we don't sign the policy itself)
    #   16 = Enabled:Update Policy No Reboot (critical for WMI refresh)
    #   10 = Enabled:Boot Audit on Failure
    # Explicitly deleted: 0 (UMCI), 2 (WHQL), 4 (Flight Signing),
    #                    8 (EV Signers), 11 (Script Enforcement)
    # Optional 3 = Enabled:Audit Mode (only when -AuditMode flag set)
    Set-RuleOption -FilePath $OutputXml -Option 6  -ErrorAction SilentlyContinue
    Set-RuleOption -FilePath $OutputXml -Option 16 -ErrorAction SilentlyContinue
    Set-RuleOption -FilePath $OutputXml -Option 10 -ErrorAction SilentlyContinue
    Set-RuleOption -FilePath $OutputXml -Option 0  -Delete -ErrorAction SilentlyContinue
    Set-RuleOption -FilePath $OutputXml -Option 2  -Delete -ErrorAction SilentlyContinue
    Set-RuleOption -FilePath $OutputXml -Option 4  -Delete -ErrorAction SilentlyContinue
    Set-RuleOption -FilePath $OutputXml -Option 8  -Delete -ErrorAction SilentlyContinue
    Set-RuleOption -FilePath $OutputXml -Option 11 -Delete -ErrorAction SilentlyContinue
    if ($AuditMode) {
        Set-RuleOption -FilePath $OutputXml -Option 3 -ErrorAction SilentlyContinue
    } else {
        Set-RuleOption -FilePath $OutputXml -Option 3 -Delete -ErrorAction SilentlyContinue
    }

    [xml]$updated = Get-Content -LiteralPath $OutputXml
    return $updated.SiPolicy.PolicyID
}

function ConvertFrom-WdacPolicyXmlToP7b {
    # Compile XML to .p7b. Thin wrapper around ConvertFrom-CIPolicy
    # consistent with Chipset r66 L3859.
    param(
        [Parameter(Mandatory=$true)][string]$XmlPath,
        [Parameter(Mandatory=$true)][string]$P7bPath
    )
    ConvertFrom-CIPolicy -XmlFilePath $XmlPath -BinaryFilePath $P7bPath | Out-Null
}

function Install-SpfPolicy {
    # Copies our source .p7b to %WINDIR%\System32\CodeIntegrity\SiPolicy.p7b
    # and activates via the CIM bridge. Returns activation result.
    # The CIM bridge invocation pattern is verbatim from Chipset r66
    # L3915-3934.
    param([Parameter(Mandatory=$true)][string]$SourceP7bPath)

    if (-not (Test-Path -LiteralPath $SourceP7bPath -PathType Leaf)) {
        throw ('Source .p7b not found at {0}.' -f $SourceP7bPath)
    }

    $deployDir = Split-Path -Parent -Path $Script:DeployedPolicyPath
    if (-not (Test-Path -LiteralPath $deployDir)) {
        $null = New-Item -ItemType Directory -Path $deployDir -Force
    }
    Copy-Item -LiteralPath $SourceP7bPath -Destination $Script:DeployedPolicyPath -Force

    $immediate = $false
    $cimBridgeStdout = ''
    $cimBridgeError  = ''
    try {
        $cimArgs = @{ FilePath = $Script:DeployedPolicyPath }
        $cimResult = Invoke-CimMethod -Namespace 'root\Microsoft\Windows\CI' `
            -ClassName 'PS_UpdateAndCompareCIPolicy' `
            -MethodName 'Update' `
            -Arguments $cimArgs `
            -ErrorAction Stop
        $rv = if ($null -ne $cimResult.ReturnValue) { [int]$cimResult.ReturnValue } else { -1 }
        $cimBridgeStdout = ('PS_UpdateAndCompareCIPolicy.Update returned {0}' -f $rv)
        if ($rv -eq 0) {
            $immediate = $true
        }
    } catch {
        $cimBridgeError = $_.Exception.Message
    }

    return [pscustomobject]@{
        DeployedPath     = $Script:DeployedPolicyPath
        DeployedSha256   = (Get-FileSha256Hex -Path $Script:DeployedPolicyPath)
        ActivationMethod = if ($immediate) { 'CIM bridge (PS_UpdateAndCompareCIPolicy, no reboot)' } else { 'reboot-required' }
        RebootRequired   = -not $immediate
        CimBridgeStdout  = $cimBridgeStdout
        CimBridgeError   = $cimBridgeError
    }
}

function Uninstall-SpfPolicy {
    # Removes the deployed SiPolicy.p7b. Per Microsoft Learn, the
    # standard SPF uninstall procedure is to delete the .p7b file;
    # the next reboot reverts to platform default (Microsoft-only
    # signing).
    if (Test-Path -LiteralPath $Script:DeployedPolicyPath -PathType Leaf) {
        Remove-Item -LiteralPath $Script:DeployedPolicyPath -Force -ErrorAction Stop
    }
}

function Backup-ForeignPolicy {
    # Copies the deployed (foreign) SiPolicy.p7b to ProgramData\backups\
    # with timestamp in the filename. Returns a record to embed in the
    # manifest under foreignPolicyBackup.
    Initialize-WdacDirectoryStructure
    $ts = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH-mm-ssZ')
    $backupName = ('{0}-foreign-policy.p7b.bak' -f $ts)
    $backupPath = Join-Path $Script:BackupsDir $backupName
    Copy-Item -LiteralPath $Script:DeployedPolicyPath -Destination $backupPath -Force
    return [pscustomobject]@{
        backupPath         = $backupPath
        backupSha256       = (Get-FileSha256Hex -Path $backupPath)
        backedUpAt         = (New-IsoTimestamp)
        originalDeployPath = $Script:DeployedPolicyPath
    }
}

function Restore-ForeignPolicyBackup {
    # Restores a previously-backed-up foreign policy onto the deploy
    # path. Used by -Action Uninstall -RestoreForeignBackup.
    param([Parameter(Mandatory=$true)]$Backup)
    if (-not $Backup -or -not $Backup.backupPath) {
        return $null
    }
    if (-not (Test-Path -LiteralPath $Backup.backupPath -PathType Leaf)) {
        throw ('Foreign policy backup not found at {0}.' -f $Backup.backupPath)
    }
    Copy-Item -LiteralPath $Backup.backupPath -Destination $Script:DeployedPolicyPath -Force
    try {
        $null = Invoke-CimMethod -Namespace 'root\Microsoft\Windows\CI' `
            -ClassName 'PS_UpdateAndCompareCIPolicy' `
            -MethodName 'Update' `
            -Arguments @{ FilePath = $Script:DeployedPolicyPath } -ErrorAction Stop
    } catch {
        Write-Warn2 ('WMI refresh after foreign restore failed; the policy will become active at next reboot. {0}' -f $_.Exception.Message)
    }
    return $Backup.backupPath
}


#####################################################################
# SECTION 1g: Canonical-hash, JSON envelope, and filesystem helpers
#####################################################################
# These helpers are NEW for the WDAC orchestrator. They will also
# appear identically in the four driver scripts' integration block so
# that the canonical-hash invariant is maintained across all 5 .ps1
# files (PSA8001 will then enforce byte-for-byte sync of these helpers
# once they have sister copies). See CHANGELOG.md for the introduction
# revision and per-revision evolution history.

function Get-CanonicalScriptHash {
    # Computes SHA256 of file content after BOM-strip and CRLF->LF normalize.
    # Invariant across UTF-8-BOM-CRLF (working tree) and UTF-8-LF (GitHub raw).
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateScript({Test-Path -LiteralPath $_ -PathType Leaf})]
        [string]$Path
    )
    $bytes = [System.IO.File]::ReadAllBytes($Path)
    if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
        $bytes = $bytes[3..($bytes.Length - 1)]
    }
    $text = [System.Text.Encoding]::UTF8.GetString($bytes)
    $text = $text -replace "`r`n", "`n"
    $text = $text -replace "`r",    "`n"
    $canonicalBytes = [System.Text.Encoding]::UTF8.GetBytes($text)
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try {
        $hash = $sha.ComputeHash($canonicalBytes)
        return ([System.BitConverter]::ToString($hash) -replace '-', '').ToLower()
    } finally {
        $sha.Dispose()
    }
}

function Get-SelfCanonicalHash {
    # Lazily compute (and cache) the canonical hash of THIS script file.
    if ($Script:SelfCanonicalHash) { return $Script:SelfCanonicalHash }
    $self = $PSCommandPath
    if ([string]::IsNullOrEmpty($self)) {
        $self = $MyInvocation.MyCommand.Path
    }
    if (-not $self -or -not (Test-Path -LiteralPath $self -PathType Leaf)) {
        return '(self-path-unavailable)'
    }
    $Script:SelfCanonicalHash = Get-CanonicalScriptHash -Path $self
    return $Script:SelfCanonicalHash
}

function New-IsoTimestamp {
    # ISO 8601 UTC timestamp with millisecond precision.
    # Pattern matches Chipset r66 L1615 - PowerShell 5.1 / 7.x compatible
    # (does NOT use the PS 7.1+ -AsUTC parameter).
    return (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
}

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
    # Get-FileHash pattern matches Chipset r66 L641.
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
    # Atomic file write: write to <path>.tmp, then Move-Item over the
    # target. On NTFS, Move-Item to an existing path is rename-and-replace.
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
    # UTF-8 without BOM - standard JSON convention.
    [System.IO.File]::WriteAllText($tmp, $json, [System.Text.UTF8Encoding]::new($false))
    if (Test-Path -LiteralPath $Path) {
        Remove-Item -LiteralPath $Path -Force -ErrorAction Stop
    }
    Move-Item -LiteralPath $tmp -Destination $Path -Force -ErrorAction Stop
}

function Read-JsonStrict {
    # Loads JSON from a file. Returns $null if file missing.
    # Throws on parse error (callers catch and mark Inconsistent).
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        return $null
    }
    $raw = [System.IO.File]::ReadAllText($Path, [System.Text.UTF8Encoding]::new($false))
    return ($raw | ConvertFrom-Json -ErrorAction Stop)
}

function Copy-CertToProgramData {
    # Copies a .cer file from a driver-script workspace into the
    # ProgramData certs/ directory, naming the copy after the cert's
    # thumbprint so multiple driver scripts can coexist.
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
    # Loads cert info from a .cer file. X509Certificate2 constructor
    # pattern matches Chipset r66 (multiple call sites).
    param([Parameter(Mandatory=$true)][string]$Path)
    $cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2 $Path
    $rawBytes = $cert.GetRawCertData()
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try {
        $hash = $sha.ComputeHash($rawBytes)
        $rawSha = ([System.BitConverter]::ToString($hash) -replace '-', '').ToLower()
    } finally {
        $sha.Dispose()
    }
    return [pscustomobject]@{
        Thumbprint    = $cert.Thumbprint.ToUpper()
        Subject       = $cert.Subject
        Issuer        = $cert.Issuer
        ValidFrom     = $cert.NotBefore.ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
        ValidTo       = $cert.NotAfter.ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
        RawDataSha256 = $rawSha
    }
}

function Initialize-JsonResult {
    # Initializes the JSON envelope. Called once at script start.
    $Script:JsonResult = [pscustomobject]@{
        action          = $Script:Action
        result          = 'unknown'
        state           = $null
        stateBefore     = $null
        stateAfter      = $null
        noOp            = $false
        message         = ''
        details         = @{}
        exitCode        = 0
        scriptVersion   = $Script:ScriptVersion
        timestamp       = (New-IsoTimestamp)
    }
}

function Set-JsonResult {
    # Populates JSON envelope fields. Only fields explicitly named in
    # the parameter list are updated. Safe to call multiple times.
    param(
        [string]$Result      = $null,
        [string]$State       = $null,
        [string]$StateBefore = $null,
        [string]$StateAfter  = $null,
        [Nullable[bool]]$NoOp = $null,
        [string]$Message     = $null,
        [Nullable[int]]$ExitCode = $null,
        [hashtable]$Details  = $null
    )
    if (-not $Script:JsonResult) { Initialize-JsonResult }
    if ($PSBoundParameters.ContainsKey('Result'))      { $Script:JsonResult.result      = $Result }
    if ($PSBoundParameters.ContainsKey('State'))       { $Script:JsonResult.state       = $State }
    if ($PSBoundParameters.ContainsKey('StateBefore')) { $Script:JsonResult.stateBefore = $StateBefore }
    if ($PSBoundParameters.ContainsKey('StateAfter'))  { $Script:JsonResult.stateAfter  = $StateAfter }
    if ($PSBoundParameters.ContainsKey('NoOp') -and $NoOp.HasValue) { $Script:JsonResult.noOp = $NoOp.Value }
    if ($PSBoundParameters.ContainsKey('Message'))     { $Script:JsonResult.message     = $Message }
    if ($PSBoundParameters.ContainsKey('ExitCode') -and $ExitCode.HasValue) { $Script:JsonResult.exitCode = $ExitCode.Value }
    if ($PSBoundParameters.ContainsKey('Details') -and $Details) {
        foreach ($k in $Details.Keys) {
            $Script:JsonResult.details[$k] = $Details[$k]
        }
    }
}

function _EmitJson {
    # Render $Script:JsonResult to stdout (Write-Output / pipeline) as
    # a single JSON document. Write-Host content is NOT emitted here;
    # callers that redirect stdout will get just this JSON.
    if ($Script:JsonResult.details -is [hashtable] -and $Script:JsonResult.details.Count -eq 0) {
        $Script:JsonResult.details = $null
    }
    $json = $Script:JsonResult | ConvertTo-Json -Depth 10
    Write-Output $json
}


#####################################################################
# SECTION 1h: Manifest schema and state model
#####################################################################
# The manifest tracks per-host orchestrator state:
#   - which certs are authorized
#   - which driver scripts asked for them
#   - the source .p7b SHA256 (so tampering can be detected)
#   - history of changes
# Stored at $Script:ManifestPath (ProgramData). Schema v1.0 per SPEC §D.25.
#
# State model returns one of:
#   None / Ours-Healthy / Ours-Stale / Ours-Tampered / Foreign / Inconsistent

function New-EmptyManifest {
    return [pscustomobject]@{
        schemaVersion               = $Script:SchemaVersion
        schemaId                    = $Script:SchemaId
        createdAt                   = (New-IsoTimestamp)
        lastUpdatedAt               = (New-IsoTimestamp)
        policy                      = $null
        authorizedCerts             = @()
        foreignPolicyBackup         = $null
        deploymentHistory           = @()
        historyMaxEntries           = $Script:HistoryMaxEntries
        externalScriptVersion       = $Script:ScriptVersion
        externalScriptCanonicalHash = (Get-SelfCanonicalHash)
    }
}

function Test-ManifestValid {
    param($Manifest)
    if (-not $Manifest) { return $false }
    if (-not $Manifest.schemaVersion) { return $false }
    return $true
}

function Read-Manifest {
    # Returns hashtable @{ Manifest = obj-or-null; Error = string-or-null; Inconsistent = bool }
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
    # PSCustomObject deserialization can yield $null for empty arrays - coerce.
    if ($null -eq $m.authorizedCerts) {
        $m | Add-Member -NotePropertyName authorizedCerts -NotePropertyValue @() -Force
    }
    if ($null -eq $m.deploymentHistory) {
        $m | Add-Member -NotePropertyName deploymentHistory -NotePropertyValue @() -Force
    }
    $out.Manifest = $m
    return $out
}

function Save-Manifest {
    param([Parameter(Mandatory=$true)]$Manifest)
    Initialize-WdacDirectoryStructure
    $Manifest.lastUpdatedAt = (New-IsoTimestamp)
    $Manifest.externalScriptVersion       = $Script:ScriptVersion
    $Manifest.externalScriptCanonicalHash = (Get-SelfCanonicalHash)
    # Trim deploymentHistory to the cap.
    if ($Manifest.deploymentHistory) {
        $cap = $Script:HistoryMaxEntries
        if ($Manifest.historyMaxEntries) { $cap = [int]$Manifest.historyMaxEntries }
        if ($Manifest.deploymentHistory.Count -gt $cap) {
            $Manifest.deploymentHistory = $Manifest.deploymentHistory[-$cap..-1]
        }
    }
    Save-JsonAtomic -Path $Script:ManifestPath -Object $Manifest
}

function Add-HistoryEntry {
    param(
        [Parameter(Mandatory=$true)]$Manifest,
        [Parameter(Mandatory=$true)][string]$ActionName,
        [string]$Script:CertThumbprint   = '',
        [string]$Caller           = '',
        [string]$CallerVersion    = '',
        [string]$StateBefore      = '',
        [string]$StateAfter       = '',
        [string]$ResultingSha256  = ''
    )
    $entry = [pscustomobject]@{
        timestamp             = (New-IsoTimestamp)
        action                = $ActionName
        certThumbprint        = $Script:CertThumbprint
        callerScript          = $Caller
        callerScriptVersion   = $CallerVersion
        stateBefore           = $StateBefore
        stateAfter            = $StateAfter
        resultingPolicySha256 = $ResultingSha256
    }
    if (-not $Manifest.deploymentHistory) { $Manifest.deploymentHistory = @() }
    $Manifest.deploymentHistory = @() + $Manifest.deploymentHistory + $entry
}

function Get-WdacState {
    # Returns pscustomobject describing the current state of WDAC SPF
    # on this host. See SECTION header above for state enumeration.
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
        $detail.manifestExists = $true
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
        # Identify certs expiring within 90 days (or already expired)
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
                } catch { } # psa-disable-line PSA3004 -- intentional best-effort cleanup; parse failure here is non-fatal
            }
        }
    } elseif ($r.Inconsistent) {
        $detail.manifestExists = $true
        $detail.manifestInconsistent = $true
    }

    # Decide state
    if ($detail.manifestInconsistent) {
        $detail.state = 'Inconsistent'
        $detail.recommendations += 'Run -Action Repair to attempt to rebuild the manifest from authorized .cer files in ProgramData\certs\.'
    } elseif (-not $detail.deployedExists -and -not $detail.manifestExists) {
        $detail.state = 'None'
    } elseif ($detail.deployedExists -and -not $detail.manifestExists) {
        $detail.state = 'Foreign'
        $detail.recommendations += 'A WDAC policy exists at the deploy path but we have no manifest for it. Use -Action AddCert -ForceOverrideForeign to back up the foreign policy and replace it, or merge our cert into the existing policy manually.'
    } elseif (-not $detail.deployedExists -and $detail.manifestExists) {
        $detail.state = 'Ours-Stale'
        $detail.recommendations += 'The deployed SiPolicy.p7b was removed but our manifest still claims it. -Action AddCert or -Action Repair will redeploy from our source.'
    } else {
        if ($detail.sourceP7bExists -and $detail.deployedSha256 -eq $detail.sourceP7bSha256) {
            $detail.state = 'Ours-Healthy'
        } elseif ($detail.manifestRecordedSha256 -and $detail.deployedSha256 -eq $detail.manifestRecordedSha256) {
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
# SECTION 3: OS context
#####################################################################
function Get-OsContext {
    # CIM is the preferred path. On extremely locked-down or Server
    # Core images (mainly older WS2016/WS2019), the CIM service can
    # occasionally fail; in that case fall back to WMI which uses the
    # legacy DCOM transport. Both surface Win32_OperatingSystem with
    # the same property names we need.
    $osCim = $null
    try {
        $osCim = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction Stop
    } catch {
        try {
            $osCim = Get-WmiObject -Class Win32_OperatingSystem -ErrorAction Stop  # psa-disable-line PSA3006 -- intentional fallback when CIM is constrained; PS 5.1 still supports WMI cmdlets
        } catch {
            throw "Failed to query Win32_OperatingSystem via both CIM and WMI: $($_.Exception.Message)"
        }
    }
    $build = [int]([System.Environment]::OSVersion.Version.Build)

    # Per-OS configuration. SDK/WDK URLs are intentionally identical
    # across all four OSes per Microsoft documentation: WDK 26100.6584
    # is the default supported kit, runs on Windows 7+, and builds for
    # Windows 10 / Server 2016+. Per-OS slots are kept so future
    # divergence can be expressed without code changes.
    $matrix = @{
        14393 = [pscustomobject]@{
            Name = 'Windows Server 2016'; Code = 'WS2016'; Build = 14393
            HasWingetByDefault = $false; CanInstallWinget = $false
            CertKeyLength = 2048; CertHashAlgorithm = 'SHA256'; CertValidYears = 3
            UseModernCertExtension = $false
            SdkBuild = '10.0.26100.6584'; SdkUrl = 'https://go.microsoft.com/fwlink/?linkid=2338977'
            SdkInstallArgs = @('/features','OptionId.SigningTools','/quiet','/norestart')
            WdkBuild = '10.0.26100.6584'; WdkUrl = 'https://go.microsoft.com/fwlink/?linkid=2335869'
            WdkInstallArgs = @('/quiet','/norestart')
            WingetSdkId = $null; WingetWdkId = $null
            ToolkitNotes = 'WS2016: winget absent, EXE install only'
            # WS2016 = build 14393. inf2cat has direct Server2016_X64.
            Inf2catOsArg = 'Server2016_X64'
            Inf2catOsArgFallbacks = @('Server10_X64')
        }
        17763 = [pscustomobject]@{
            Name = 'Windows Server 2019'; Code = 'WS2019'; Build = 17763
            HasWingetByDefault = $false; CanInstallWinget = $false
            CertKeyLength = 4096; CertHashAlgorithm = 'SHA256'; CertValidYears = 5
            UseModernCertExtension = $true
            SdkBuild = '10.0.26100.6584'; SdkUrl = 'https://go.microsoft.com/fwlink/?linkid=2338977'
            SdkInstallArgs = @('/features','OptionId.SigningTools','/quiet','/norestart')
            WdkBuild = '10.0.26100.6584'; WdkUrl = 'https://go.microsoft.com/fwlink/?linkid=2335869'
            WdkInstallArgs = @('/quiet','/norestart')
            WingetSdkId = $null; WingetWdkId = $null
            ToolkitNotes = 'WS2019: winget absent, EXE install only'
            # WS2019 = build 17763, codename "Redstone 5".
            Inf2catOsArg = 'ServerRS5_X64'
            Inf2catOsArgFallbacks = @('Server2016_X64','Server10_X64')
        }
        20348 = [pscustomobject]@{
            Name = 'Windows Server 2022'; Code = 'WS2022'; Build = 20348
            HasWingetByDefault = $false; CanInstallWinget = $true
            CertKeyLength = 4096; CertHashAlgorithm = 'SHA256'; CertValidYears = 5
            UseModernCertExtension = $true
            SdkBuild = '10.0.26100.6584'; SdkUrl = 'https://go.microsoft.com/fwlink/?linkid=2338977'
            SdkInstallArgs = @('/features','OptionId.SigningTools','/quiet','/norestart')
            WdkBuild = '10.0.26100.6584'; WdkUrl = 'https://go.microsoft.com/fwlink/?linkid=2335869'
            WdkInstallArgs = @('/quiet','/norestart')
            WingetSdkId = 'Microsoft.WindowsSDK.10.0.26100'
            WingetWdkId = 'Microsoft.WindowsWDK.10.0.26100'
            ToolkitNotes = 'WS2022: winget side-load possible'
            # WS2022 = build 20348, codename "Iron" (Fe is the
            # chemical symbol for iron). inf2cat uses ServerFE_X64.
            Inf2catOsArg = 'ServerFE_X64'
            Inf2catOsArgFallbacks = @('ServerRS5_X64','Server2016_X64','Server10_X64')
        }
        26100 = [pscustomobject]@{
            Name = 'Windows Server 2025'; Code = 'WS2025'; Build = 26100
            HasWingetByDefault = $true; CanInstallWinget = $true
            CertKeyLength = 4096; CertHashAlgorithm = 'SHA384'; CertValidYears = 5
            UseModernCertExtension = $true
            SdkBuild = '10.0.26100.6584'; SdkUrl = 'https://go.microsoft.com/fwlink/?linkid=2338977'
            SdkInstallArgs = @('/features','OptionId.SigningTools','/quiet','/norestart')
            WdkBuild = '10.0.26100.6584'; WdkUrl = 'https://go.microsoft.com/fwlink/?linkid=2335869'
            WdkInstallArgs = @('/quiet','/norestart')
            WingetSdkId = 'Microsoft.WindowsSDK.10.0.26100'
            WingetWdkId = 'Microsoft.WindowsWDK.10.0.26100'
            ToolkitNotes = 'WS2025: winget native; WDK matches host'
            # The inf2cat /os switch selects the TARGET OS for the
            # catalog file being generated. For Windows Server 2025
            # (build 26100), the SDK 10.0.26100 inf2cat directly
            # supports "Server2025_X64" - this is the canonical and
            # only correct primary value for WS2025.
            #
            # Fallbacks (older Server codenames, all underscore form)
            # are kept for the rare case where this script is run
            # against an older inf2cat that pre-dates the Server2025
            # support; on a properly matched SDK 10.0.26100 they are
            # never reached.
            Inf2catOsArg = 'Server2025_X64'
            Inf2catOsArgFallbacks = @('ServerFE_X64','ServerRS5_X64','Server2016_X64','Server10_X64')
        }
    }

    $ctx = $matrix[$build]
    if (-not $ctx) {
        $closest = $matrix.Keys | Sort-Object | Where-Object { $_ -le $build } | Select-Object -Last 1
        if (-not $closest) { throw "Unsupported OS build: $build (need 14393 or higher)" }
        Write-Warn2 "Build $build not in matrix; using $($matrix[$closest].Name) profile"
        $ctx = $matrix[$closest]
    }
    $ctx | Add-Member -NotePropertyName ActualBuild -NotePropertyValue $build      -Force
    $ctx | Add-Member -NotePropertyName ProductType -NotePropertyValue $osCim.ProductType -Force
    $ctx | Add-Member -NotePropertyName Caption     -NotePropertyValue $osCim.Caption     -Force
    return $ctx
}


#####################################################################
# SECTION 3b: OS guard for legacy Windows Server
#####################################################################
# This script targets WS2019 (build 17763) and WS2016 (build 14393)
# only. The Get-OsContext helper inherited in SECTION 3 already
# detects all four server builds (14393 / 17763 / 20348 / 26100); this
# section adds the legacy-only gating on top.

function Test-IsLegacyWindowsServerHost {
    # Returns pscustomobject describing whether this host is in scope.
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

    try {
        $os = Get-OsContext
    } catch {
        $result.Reason = $_.Exception.Message
        return $result
    }

    $result.ProductType = $os.ProductType
    $result.Build       = $os.ActualBuild
    $result.Caption     = $os.Caption

    # ProductType: 1=Workstation, 2=Domain Controller, 3=Server
    if ($result.ProductType -ne 2 -and $result.ProductType -ne 3) {
        $result.Reason = ('ProductType={0} is a Workstation SKU; this script is Server-only.' -f $result.ProductType)
        return $result
    }
    $result.IsWindowsServer = $true

    if ($result.Build -ge 20348) {
        $result.Reason = ('Build {0} is WS2022+ (Multiple Policy Format capable); use the driver scripts'' built-in WDAC supplemental policy path (I02 Path A) instead of this orchestrator.' -f $result.Build)
        return $result
    }
    if ($result.Build -lt 14393) {
        $result.Reason = ('Build {0} is older than WS2016 (build 14393); WDAC SPF is not available on this kernel.' -f $result.Build)
        return $result
    }

    $result.IsLegacy = $true
    return $result
}

function Assert-LegacyWindowsServerHost {
    # Throws (with JSON envelope populated for exit code 3) if this is
    # not a WS2019 / WS2016 host. Skipped for dev-helper Actions that
    # are useful to run on any platform.
    if ($Script:Action -in @('ComputeCanonicalHash', 'ComputeOwnCanonicalHash', 'Help')) {
        return $null
    }
    $r = Test-IsLegacyWindowsServerHost
    if (-not $r.IsLegacy) {
        $msg = ("This script is for Windows Server 2019 (build 17763) and Windows Server 2016 (build 14393) only. " +
                "Detected: ProductType={0}, Build={1}, Caption='{2}'. {3}" -f `
                $r.ProductType, $r.Build, $r.Caption, $r.Reason)
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
# SECTION 4: Action handler - GetStatus
#####################################################################

function Invoke-ActionGetStatus { # psa-disable-line PSA6003 -- "Status" is singular; analyzer false positive on -us ending. The function name mirrors the -Action GetStatus parameter value.
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
        checkedCertThumbprint  = if ($Script:CheckCertThumbprint) { $Script:CheckCertThumbprint.ToUpper() } else { $null }
        checkedCertPresent     = if ($Script:CheckCertThumbprint) {
                                    [bool]($detail.authorizedCerts | Where-Object { $_.thumbprint -eq $Script:CheckCertThumbprint.ToUpper() })
                                 } else { $null }
    }

    if ($Script:OutputFormat -ne 'Json') {
        Write-Host ''
        Write-Host '=======================================================================' -ForegroundColor Cyan
        Write-Host '  WDAC SINGLE POLICY FORMAT - STATUS' -ForegroundColor Cyan
        Write-Host '=======================================================================' -ForegroundColor Cyan
        $stateColor = switch ($detail.state) {
            'Ours-Healthy' { 'Green' }
            'None'         { 'Gray' }
            'Foreign'      { 'Yellow' }
            'Ours-Stale'   { 'Yellow' }
            'Ours-Tampered'{ 'Yellow' }
            'Inconsistent' { 'Red' }
            default        { 'White' }
        }
        Write-Host ('  State              : {0}' -f $detail.state) -ForegroundColor $stateColor
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
            Write-Host ('      Subject : {0}' -f $c.subject) -ForegroundColor DarkGray
            Write-Host ('      Added by: {0} ({1})' -f $c.addedBy, $c.addedByVersion) -ForegroundColor DarkGray
            Write-Host ('      Added at: {0}' -f $c.addedAt) -ForegroundColor DarkGray
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
        if ($Script:CheckCertThumbprint) {
            $present = [bool]($detail.authorizedCerts | Where-Object { $_.thumbprint -eq $Script:CheckCertThumbprint.ToUpper() })
            Write-Host ''
            Write-Host ('  Cross-check for {0}: {1}' -f $Script:CheckCertThumbprint.ToUpper(), $(if ($present) { 'PRESENT' } else { 'ABSENT' })) -ForegroundColor $(if ($present) { 'Green' } else { 'Yellow' })
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
# SECTION 5: Action handler - AddCert
#####################################################################

function Invoke-ActionAddCert {
    if ([string]::IsNullOrEmpty($Script:CertFile)) {
        throw '-CertFile is required for Action=AddCert.'
    }
    if (-not (Test-Path -LiteralPath $Script:CertFile -PathType Leaf)) {
        throw ('CertFile not found at {0}.' -f $Script:CertFile)
    }
    if ([string]::IsNullOrEmpty($Script:CallerScript)) {
        throw '-CallerScript is required for Action=AddCert (records provenance in the manifest).'
    }

    $caps = Test-WdacToolsAvailable
    if (-not $caps.ConfigCiModule) {
        throw 'ConfigCI PowerShell module is required for AddCert. Install via Windows optional features or import the module manually.'
    }
    if (-not $caps.AllowAllTemplate) {
        throw ('AllowAll template missing at {0}. Required to seed the SPF policy XML.' -f (Join-Path $env:windir 'schemas\CodeIntegrity\ExamplePolicies\AllowAll.xml'))
    }

    $stateBefore = (Get-WdacState).state
    Set-JsonResult -StateBefore $stateBefore

    if ($stateBefore -eq 'Foreign' -and -not $Script:ForceOverrideForeign) {
        $msg = ('Foreign WDAC policy detected at {0}. -ForceOverrideForeign is required to back up the foreign policy and replace it.' -f $Script:DeployedPolicyPath)
        Set-JsonResult -Result 'refused' -State $stateBefore -Message $msg -ExitCode 2
        throw $msg
    }
    if ($stateBefore -eq 'Ours-Tampered' -and -not $Script:Force) {
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

    $r = Read-Manifest
    $manifest = if ($r.Manifest) { $r.Manifest } else { New-EmptyManifest }

    $info = Get-CertInfoFromCer -Path $Script:CertFile
    $thumb = $info.Thumbprint

    if ($stateBefore -eq 'Foreign') {
        Write-Step 'Backing up the foreign policy before replacement...'
        $backup = Backup-ForeignPolicy
        $manifest.foreignPolicyBackup = $backup
        Write-Ok ('Foreign policy backed up to {0}' -f $backup.backupPath)
    }

    $existing = @($manifest.authorizedCerts | Where-Object { $_.thumbprint -eq $thumb })
    if ($existing.Count -gt 0 -and $stateBefore -eq 'Ours-Healthy') {
        Write-Skip ('Certificate {0} is already authorized in the policy.' -f $thumb)
        Set-JsonResult -Result 'success' -State $stateBefore -StateAfter $stateBefore -NoOp $true `
            -Message 'Cert already authorized; no-op.' -ExitCode 0 -Details @{
            certThumbprint = $thumb
            certSubject    = $info.Subject
        }
        Add-HistoryEntry -Manifest $manifest -ActionName 'AddCert' `
            -CertThumbprint $thumb -Caller $Script:CallerScript -CallerVersion $Script:CallerScriptVersion `
            -StateBefore $stateBefore -StateAfter $stateBefore `
            -ResultingSha256 (Get-FileSha256Hex -Path $Script:DeployedPolicyPath)
        Save-Manifest -Manifest $manifest
        return
    }

    if ($Script:ReplaceExistingFromCaller -and $existing.Count -eq 0) {
        $callerLeaf = Split-Path -Leaf -Path $Script:CallerScript
        $sameCaller = @($manifest.authorizedCerts | Where-Object {
            $_.addedBy -and (Split-Path -Leaf -Path $_.addedBy) -eq $callerLeaf
        })
        if ($sameCaller.Count -gt 0) {
            Write-Step ('-ReplaceExistingFromCaller: removing {0} prior cert(s) from same caller before append.' -f $sameCaller.Count)
            $keep = @($manifest.authorizedCerts | Where-Object {
                -not ($_.addedBy -and (Split-Path -Leaf -Path $_.addedBy) -eq $callerLeaf)
            })
            $manifest.authorizedCerts = $keep
        }
    }

    Write-Step ('Copying {0} to {1}...' -f $Script:CertFile, $Script:CertsDir)
    $certCopyPath = Copy-CertToProgramData -SourceCer $Script:CertFile -Thumbprint $thumb

    if ($existing.Count -eq 0) {
        $entry = [pscustomobject]@{
            thumbprint     = $thumb
            subject        = $info.Subject
            rawDataSha256  = $info.RawDataSha256
            cerFilePath    = $certCopyPath
            cerFileOrigin  = $Script:CertFile
            validFrom      = $info.ValidFrom
            validTo        = $info.ValidTo
            addedBy        = (Split-Path -Leaf -Path $Script:CallerScript)
            addedByVersion = $Script:CallerScriptVersion
            addedAt        = (New-IsoTimestamp)
        }
        $manifest.authorizedCerts = @() + $manifest.authorizedCerts + $entry
    }

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
    $null = New-WdacSpfBasePolicy -CerFiles $cerList -OutputXml $Script:SourceXmlPath `
        -PolicyId $Script:ReservedPolicyId -AuditMode:$Script:AuditMode.IsPresent

    Write-Step 'Compiling XML to .p7b...'
    ConvertFrom-WdacPolicyXmlToP7b -XmlPath $Script:SourceXmlPath -P7bPath $Script:SourceP7bPath

    $newSha = Get-FileSha256Hex -Path $Script:SourceP7bPath
    if (-not $manifest.policy) {
        $manifest.policy = [pscustomobject]@{
            policyId        = $Script:ReservedPolicyId
            deployPath      = $Script:DeployedPolicyPath
            deployedSha256  = $null
            sourceXmlPath   = $Script:SourceXmlPath
            sourceP7bPath   = $Script:SourceP7bPath
            sourceP7bSha256 = $newSha
            auditMode       = [bool]$Script:AuditMode.IsPresent
        }
    } else {
        $manifest.policy.sourceP7bSha256 = $newSha
        $manifest.policy.auditMode       = [bool]$Script:AuditMode.IsPresent
    }

    Write-Step 'Deploying SiPolicy.p7b and activating via WMI CIM bridge...'
    $deploy = Install-SpfPolicy -SourceP7bPath $Script:SourceP7bPath
    $manifest.policy.deployedSha256 = $deploy.DeployedSha256

    Add-HistoryEntry -Manifest $manifest -ActionName 'AddCert' `
        -CertThumbprint $thumb -Caller $Script:CallerScript -CallerVersion $Script:CallerScriptVersion `
        -StateBefore $stateBefore -StateAfter 'Ours-Healthy' `
        -ResultingSha256 $deploy.DeployedSha256
    Save-Manifest -Manifest $manifest

    Write-Ok ('Policy deployed. State: {0} -> Ours-Healthy' -f $stateBefore)
    Write-Detail ('Activation method: {0}' -f $deploy.ActivationMethod)
    Write-Detail ('Deployed SHA256  : {0}' -f $deploy.DeployedSha256)
    if ($deploy.RebootRequired) {
        Write-Warn2 'WMI activation reported reboot-required. The policy will take full effect on next reboot.'
    }

    Set-JsonResult -Result 'success' -State 'Ours-Healthy' -StateBefore $stateBefore -StateAfter 'Ours-Healthy' `
        -NoOp $false -Message 'AddCert succeeded; state transitioned to Ours-Healthy.' -ExitCode 0 -Details @{
        certThumbprint      = $thumb
        certSubject         = $info.Subject
        activationMethod    = $deploy.ActivationMethod
        rebootRequired      = $deploy.RebootRequired
        deployedSha256      = $deploy.DeployedSha256
        sourceP7bSha256     = $newSha
        policyId            = $Script:ReservedPolicyId
        auditMode           = [bool]$Script:AuditMode.IsPresent
        authorizedCertCount = $manifest.authorizedCerts.Count
    }
}

#####################################################################
# SECTION 6: Action handler - RemoveCert
#####################################################################

function Invoke-ActionRemoveCert {
    if ([string]::IsNullOrEmpty($Script:CertThumbprint)) {
        throw '-CertThumbprint is required for Action=RemoveCert.'
    }
    $thumb = $Script:CertThumbprint.ToUpper()

    $stateBefore = (Get-WdacState).state
    Set-JsonResult -StateBefore $stateBefore

    if ($stateBefore -in @('Foreign','Ours-Tampered','Inconsistent') -and -not $Script:Force) {
        $msg = ('Cannot RemoveCert when state is {0} without -Force.' -f $stateBefore)
        Set-JsonResult -Result 'refused' -State $stateBefore -Message $msg -ExitCode 2
        throw $msg
    }

    $r = Read-Manifest
    if (-not $r.Manifest) {
        $msg = 'No manifest found; nothing to remove.'
        Write-Skip $msg
        Set-JsonResult -Result 'success' -State $stateBefore -StateAfter $stateBefore -NoOp $true -Message $msg -ExitCode 0
        return
    }
    $manifest = $r.Manifest

    $remaining = @($manifest.authorizedCerts | Where-Object { $_.thumbprint -ne $thumb })
    if ($remaining.Count -eq $manifest.authorizedCerts.Count) {
        Write-Skip ('Thumbprint {0} not in manifest; no-op.' -f $thumb)
        Set-JsonResult -Result 'success' -State $stateBefore -StateAfter $stateBefore -NoOp $true -Message 'Thumbprint not in manifest; no-op.' -ExitCode 0
        return
    }
    $manifest.authorizedCerts = $remaining

    if ($remaining.Count -eq 0) {
        Write-Step 'Last cert removed. Uninstalling policy (default behavior).'
        Uninstall-SpfPolicy
        $manifest.policy = $null
        Add-HistoryEntry -Manifest $manifest -ActionName 'RemoveCert+AutoUninstall' `
            -CertThumbprint $thumb -StateBefore $stateBefore -StateAfter 'None' -ResultingSha256 ''
        Save-Manifest -Manifest $manifest
        foreach ($f in @($Script:SourceP7bPath, $Script:SourceXmlPath)) {
            if (Test-Path -LiteralPath $f) { Remove-Item -LiteralPath $f -Force }
        }
        Write-Ok ('State transitioned: {0} -> None' -f $stateBefore)
        Set-JsonResult -Result 'success' -State 'None' -StateBefore $stateBefore -StateAfter 'None' -NoOp $false -Message 'Last cert removed; policy fully uninstalled.' -ExitCode 0
        return
    }

    $caps = Test-WdacToolsAvailable
    if (-not $caps.ConfigCiModule -or -not $caps.AllowAllTemplate) {
        throw 'ConfigCI module and AllowAll template are required to re-build policy after RemoveCert.'
    }
    Write-Step ('Regenerating policy XML with {0} remaining cert(s)...' -f $remaining.Count)
    $cerList = @()
    foreach ($c in $remaining) {
        if (Test-Path -LiteralPath $c.cerFilePath) {
            $cerList += $c.cerFilePath
        } elseif ($c.cerFileOrigin -and (Test-Path -LiteralPath $c.cerFileOrigin)) {
            $cerList += $c.cerFileOrigin
        }
    }
    $auditMode = if ($manifest.policy -and $null -ne $manifest.policy.auditMode) { [bool]$manifest.policy.auditMode } else { $false }
    $null = New-WdacSpfBasePolicy -CerFiles $cerList -OutputXml $Script:SourceXmlPath `
        -PolicyId $Script:ReservedPolicyId -AuditMode:$auditMode
    ConvertFrom-WdacPolicyXmlToP7b -XmlPath $Script:SourceXmlPath -P7bPath $Script:SourceP7bPath
    $newSha = Get-FileSha256Hex -Path $Script:SourceP7bPath
    $manifest.policy.sourceP7bSha256 = $newSha
    $deploy = Install-SpfPolicy -SourceP7bPath $Script:SourceP7bPath
    $manifest.policy.deployedSha256 = $deploy.DeployedSha256
    Add-HistoryEntry -Manifest $manifest -ActionName 'RemoveCert' `
        -CertThumbprint $thumb -StateBefore $stateBefore -StateAfter 'Ours-Healthy' -ResultingSha256 $deploy.DeployedSha256
    Save-Manifest -Manifest $manifest
    Write-Ok ('Removed {0}; redeployed policy.' -f $thumb)
    Set-JsonResult -Result 'success' -State 'Ours-Healthy' -StateBefore $stateBefore -StateAfter 'Ours-Healthy' -NoOp $false -Message ('Cert {0} removed; policy redeployed.' -f $thumb) -ExitCode 0
}

#####################################################################
# SECTION 7: Action handler - Verify
#####################################################################

function Invoke-ActionVerify {
    if ([string]::IsNullOrEmpty($Script:CertThumbprint)) {
        throw '-CertThumbprint is required for Action=Verify.'
    }
    $thumb = $Script:CertThumbprint.ToUpper()
    $detail = Get-WdacState

    $present = $false
    if ($detail.state -eq 'Ours-Healthy' -or $detail.state -eq 'Ours-Stale') {
        $present = [bool]($detail.authorizedCerts | Where-Object { $_.thumbprint -eq $thumb })
    }

    if ($present) {
        Write-Ok ('Certificate {0} is authorized (state={1}).' -f $thumb, $detail.state)
        Set-JsonResult -Result 'success' -State $detail.state -Message 'Authorized.' -ExitCode 0 -Details @{
            certThumbprint = $thumb
            certPresent    = $true
            state          = $detail.state
        }
    } else {
        Write-Warn2 ('Certificate {0} is NOT authorized (state={1}).' -f $thumb, $detail.state)
        Set-JsonResult -Result 'absent' -State $detail.state -Message 'Not authorized.' -ExitCode 1 -Details @{
            certThumbprint = $thumb
            certPresent    = $false
            state          = $detail.state
        }
    }
}

#####################################################################
# SECTION 8: Action handler - Uninstall
#####################################################################

function Invoke-ActionUninstall {
    $stateBefore = (Get-WdacState).state
    Set-JsonResult -StateBefore $stateBefore

    if ($stateBefore -eq 'Foreign' -and -not $Script:ForceOverrideForeign) {
        $msg = 'Refusing to Uninstall a Foreign policy without -ForceOverrideForeign.'
        Set-JsonResult -Result 'refused' -State $stateBefore -Message $msg -ExitCode 2
        throw $msg
    }
    if ($stateBefore -eq 'Ours-Tampered' -and -not $Script:Force) {
        $msg = 'Refusing to Uninstall a tampered policy without -Force.'
        Set-JsonResult -Result 'refused' -State $stateBefore -Message $msg -ExitCode 2
        throw $msg
    }
    if ($stateBefore -eq 'Inconsistent' -and -not $Script:Force) {
        $msg = 'Manifest is Inconsistent. Use -Action Repair, or -Action Uninstall -Force.'
        Set-JsonResult -Result 'refused' -State $stateBefore -Message $msg -ExitCode 2
        throw $msg
    }

    $r = Read-Manifest
    $manifest = $r.Manifest

    $backup = $null
    if ($stateBefore -eq 'Foreign' -and $Script:ForceOverrideForeign) {
        Write-Step 'Backing up the foreign policy before removal...'
        $backup = Backup-ForeignPolicy
        Write-Ok ('Foreign policy backed up to {0}' -f $backup.backupPath)
    }

    if (Test-Path -LiteralPath $Script:DeployedPolicyPath) {
        Write-Step ('Removing {0}...' -f $Script:DeployedPolicyPath)
        Uninstall-SpfPolicy
        Write-Ok 'Deployed SiPolicy.p7b removed.'
    } else {
        Write-Skip 'Deployed SiPolicy.p7b already absent.'
    }

    if ($Script:RestoreForeignBackup) {
        $bk = if ($backup) { $backup } elseif ($manifest -and $manifest.foreignPolicyBackup) { $manifest.foreignPolicyBackup } else { $null }
        if ($bk) {
            Write-Step ('Restoring foreign policy backup from {0}...' -f $bk.backupPath)
            $null = Restore-ForeignPolicyBackup -Backup $bk
            Write-Ok 'Foreign policy backup restored.'
        } else {
            Write-Warn2 'No foreign backup recorded; -RestoreForeignBackup ignored.'
        }
    }

    foreach ($f in @($Script:SourceP7bPath, $Script:SourceXmlPath)) {
        if (Test-Path -LiteralPath $f) {
            Remove-Item -LiteralPath $f -Force -ErrorAction SilentlyContinue
        }
    }
    if ($manifest -and $manifest.deploymentHistory) {
        $manifest.policy          = $null
        $manifest.authorizedCerts = @()
        Add-HistoryEntry -Manifest $manifest -ActionName 'Uninstall' -StateBefore $stateBefore -StateAfter 'None' -ResultingSha256 ''
        Save-Manifest -Manifest $manifest
    }
    if (Test-Path -LiteralPath $Script:ManifestPath) {
        Remove-Item -LiteralPath $Script:ManifestPath -Force
    }
    if (Test-Path -LiteralPath $Script:CertsDir) {
        Get-ChildItem -LiteralPath $Script:CertsDir -Filter '*.cer' -ErrorAction SilentlyContinue |
            ForEach-Object { Remove-Item -LiteralPath $_.FullName -Force -ErrorAction SilentlyContinue }
    }

    Write-Ok ('State transitioned: {0} -> None' -f $stateBefore)
    Set-JsonResult -Result 'success' -State 'None' -StateBefore $stateBefore -StateAfter 'None' `
        -NoOp $false -Message 'Uninstall complete.' -ExitCode 0 -Details @{
        foreignBackup         = if ($backup) { $backup } else { $null }
        restoredForeignBackup = [bool]$Script:RestoreForeignBackup
    }
}

#####################################################################
# SECTION 9: Action handler - Repair
#####################################################################

function Invoke-ActionRepair {
    $stateBefore = (Get-WdacState).state
    Set-JsonResult -StateBefore $stateBefore
    Write-Step ('Repair: starting from state {0}.' -f $stateBefore)

    switch ($stateBefore) {
        'Ours-Healthy' {
            Write-Ok 'State is already Ours-Healthy; nothing to repair.'
            Set-JsonResult -Result 'success' -State $stateBefore -StateAfter $stateBefore -NoOp $true -Message 'No repair needed.' -ExitCode 0
            return
        }
        'None' {
            Write-Ok 'State is None; nothing to repair.'
            Set-JsonResult -Result 'success' -State $stateBefore -StateAfter $stateBefore -NoOp $true -Message 'No repair needed.' -ExitCode 0
            return
        }
        'Ours-Stale' {
            Write-Step 'Ours-Stale: redeploying from source .p7b...'
            if (-not (Test-Path -LiteralPath $Script:SourceP7bPath)) {
                throw 'Source .p7b is missing; cannot repair Ours-Stale automatically. Re-run a driver script which will re-add its cert via AddCert.'
            }
            $deploy = Install-SpfPolicy -SourceP7bPath $Script:SourceP7bPath
            $r = Read-Manifest
            if ($r.Manifest) {
                if ($r.Manifest.policy) { $r.Manifest.policy.deployedSha256 = $deploy.DeployedSha256 }
                Add-HistoryEntry -Manifest $r.Manifest -ActionName 'Repair' -StateBefore $stateBefore -StateAfter 'Ours-Healthy' -ResultingSha256 $deploy.DeployedSha256
                Save-Manifest -Manifest $r.Manifest
            }
            Write-Ok 'Ours-Stale repaired.'
            Set-JsonResult -Result 'success' -State 'Ours-Healthy' -StateBefore $stateBefore -StateAfter 'Ours-Healthy' -NoOp $false -Message 'Ours-Stale repaired.' -ExitCode 0
            return
        }
        'Inconsistent' {
            Write-Step 'Inconsistent: attempting to rebuild from cert files in ProgramData\certs\...'
            if (-not (Test-Path -LiteralPath $Script:CertsDir)) {
                throw ('No certs directory at {0}; cannot rebuild. Run -Action Uninstall -Force to clear and start over.' -f $Script:CertsDir)
            }
            $cerFiles = @(Get-ChildItem -LiteralPath $Script:CertsDir -Filter '*.cer' -ErrorAction SilentlyContinue)
            if ($cerFiles.Count -eq 0) {
                throw ('No .cer files found in {0}; cannot rebuild. Run -Action Uninstall -Force.' -f $Script:CertsDir)
            }
            $caps = Test-WdacToolsAvailable
            if (-not $caps.ConfigCiModule -or -not $caps.AllowAllTemplate) {
                throw 'ConfigCI module and AllowAll template are required to rebuild policy.'
            }
            $m = New-EmptyManifest
            foreach ($cf in $cerFiles) {
                $info = Get-CertInfoFromCer -Path $cf.FullName
                $entry = [pscustomobject]@{
                    thumbprint     = $info.Thumbprint
                    subject        = $info.Subject
                    rawDataSha256  = $info.RawDataSha256
                    cerFilePath    = $cf.FullName
                    cerFileOrigin  = $cf.FullName
                    validFrom      = $info.ValidFrom
                    validTo        = $info.ValidTo
                    addedBy        = '(recovered-from-cer-file)'
                    addedByVersion = ''
                    addedAt        = (New-IsoTimestamp)
                }
                $m.authorizedCerts = @() + $m.authorizedCerts + $entry
            }
            $null = New-WdacSpfBasePolicy -CerFiles ($cerFiles | ForEach-Object FullName) `
                -OutputXml $Script:SourceXmlPath -PolicyId $Script:ReservedPolicyId -AuditMode:$false
            ConvertFrom-WdacPolicyXmlToP7b -XmlPath $Script:SourceXmlPath -P7bPath $Script:SourceP7bPath
            $newSha = Get-FileSha256Hex -Path $Script:SourceP7bPath
            $m.policy = [pscustomobject]@{
                policyId        = $Script:ReservedPolicyId
                deployPath      = $Script:DeployedPolicyPath
                deployedSha256  = $null
                sourceXmlPath   = $Script:SourceXmlPath
                sourceP7bPath   = $Script:SourceP7bPath
                sourceP7bSha256 = $newSha
                auditMode       = $false
            }
            $deploy = Install-SpfPolicy -SourceP7bPath $Script:SourceP7bPath
            $m.policy.deployedSha256 = $deploy.DeployedSha256
            Add-HistoryEntry -Manifest $m -ActionName 'Repair (rebuild)' -StateBefore $stateBefore -StateAfter 'Ours-Healthy' -ResultingSha256 $deploy.DeployedSha256
            Save-Manifest -Manifest $m
            Write-Ok 'Manifest rebuilt and policy redeployed.'
            Set-JsonResult -Result 'success' -State 'Ours-Healthy' -StateBefore $stateBefore -StateAfter 'Ours-Healthy' -NoOp $false -Message 'Inconsistent repaired via cert-file rebuild.' -ExitCode 0
            return
        }
        default {
            throw ('Cannot Repair from state {0}. Foreign and Ours-Tampered require explicit user intervention.' -f $stateBefore)
        }
    }
}

#####################################################################
# SECTION 10: Action handlers - Dev helpers and Help
#####################################################################

function Invoke-ActionComputeCanonicalHash {
    if ([string]::IsNullOrEmpty($Script:File)) { throw '-File is required for Action=ComputeCanonicalHash.' }
    if (-not (Test-Path -LiteralPath $Script:File -PathType Leaf)) { throw ('-File path not found: {0}' -f $Script:File) }
    $h = Get-CanonicalScriptHash -Path $Script:File
    if ($Script:OutputFormat -ne 'Json') {
        Write-Host ('Canonical SHA256 of {0}:' -f $Script:File) -ForegroundColor Cyan
        Write-Host ('    {0}' -f $h) -ForegroundColor Green
    }
    Set-JsonResult -Result 'success' -Message 'Canonical hash computed.' -ExitCode 0 -Details @{
        file            = $Script:File
        canonicalSha256 = $h
    }
}

function Invoke-ActionComputeOwnCanonicalHash {
    $self = $PSCommandPath
    if ([string]::IsNullOrEmpty($self)) { $self = $MyInvocation.MyCommand.Path }
    $h = Get-SelfCanonicalHash
    if ($Script:OutputFormat -ne 'Json') {
        Write-Host 'Canonical SHA256 of this script:' -ForegroundColor Cyan
        Write-Host ('    {0}' -f $h) -ForegroundColor Green
        Write-Host ''
        Write-Host ('Path: {0}' -f $self) -ForegroundColor DarkGray
        Write-Host 'Embed this value into the calling driver scripts'' $Script:ExpectedWdacScriptCanonicalSha256 constant.' -ForegroundColor DarkGray
    }
    Set-JsonResult -Result 'success' -Message 'Self canonical hash computed.' -ExitCode 0 -Details @{
        file            = $self
        canonicalSha256 = $h
    }
}

function Invoke-ActionHelp {
    if ($Script:OutputFormat -eq 'Json') {
        Set-JsonResult -Result 'success' -Message 'See -Action GetStatus for runtime state.' -ExitCode 0 -Details @{
            availableActions  = @('GetStatus','AddCert','RemoveCert','Verify','Uninstall','Repair','ComputeCanonicalHash','ComputeOwnCanonicalHash')
            scriptVersion     = $Script:ScriptVersion
            selfCanonicalHash = (Get-SelfCanonicalHash)
        }
        return
    }
    Write-Host ''
    Write-Host '=======================================================================' -ForegroundColor Cyan
    Write-Host '  Deploy-WdacSinglePolicyFormatOnLegacyWindowsServer.ps1' -ForegroundColor Cyan
    Write-Host ('  Version: {0}  [{1}]  SHA256: {2}' -f $Script:ScriptVersion, $Script:ScriptTag, $Script:ScriptHash) -ForegroundColor Cyan
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
# SECTION 11: Main dispatcher
#####################################################################

function Invoke-Main {
    if ($Script:OutputFormat -ne 'Json' -and $Script:Action -ne 'Help') {
        Write-Host ''
        Write-Host ('=== Deploy-WdacSinglePolicyFormatOnLegacyWindowsServer ({0}) - Action: {1} ===' -f $Script:ScriptVersion, $Script:Action) -ForegroundColor Cyan
        Write-Host ''
    }

    $null = Assert-LegacyWindowsServerHost

    switch ($Script:Action) {
        'GetStatus'                { Invoke-ActionGetStatus }
        'AddCert'                  { Invoke-ActionAddCert }
        'RemoveCert'               { Invoke-ActionRemoveCert }
        'Verify'                   { Invoke-ActionVerify }
        'Uninstall'                { Invoke-ActionUninstall }
        'Repair'                   { Invoke-ActionRepair }
        'ComputeCanonicalHash'     { Invoke-ActionComputeCanonicalHash }
        'ComputeOwnCanonicalHash'  { Invoke-ActionComputeOwnCanonicalHash }
        'Help'                     { Invoke-ActionHelp }
        default                    { throw ('Unknown Action: {0}' -f $Script:Action) }
    }
}

# === Entry point with error trap ====================================
# Cache top-level params into $Script: scope so helper functions can read
# them without triggering PSA2001 (undefined variable). PSA2001 walks each
# function body's local + globally-assigned name sets; a `param()`-block
# variable is in neither set when referenced inside a sibling function, so
# we promote them to $Script: scope explicitly.
$Script:Action                    = $Action
$Script:CertFile                  = $CertFile
$Script:CertThumbprint            = $CertThumbprint
$Script:CallerScript              = $CallerScript
$Script:CallerScriptVersion       = $CallerScriptVersion
$Script:File                      = $File
$Script:CheckCertThumbprint       = $CheckCertThumbprint
$Script:Force                     = [bool]$Force.IsPresent
$Script:ForceOverrideForeign      = [bool]$ForceOverrideForeign.IsPresent
$Script:ReplaceExistingFromCaller = [bool]$ReplaceExistingFromCaller.IsPresent
$Script:RestoreForeignBackup      = [bool]$RestoreForeignBackup.IsPresent
$Script:AuditMode                 = [bool]$AuditMode.IsPresent
$Script:OutputFormat              = $OutputFormat
$Script:HistoryMaxEntries         = $HistoryMaxEntries

Initialize-JsonResult

try {
    Invoke-Main
}
catch {
    # Classify the caught exception into the granular exit-code scheme
    # documented in the comment-based help:
    #   0 = success (never reached here)
    #   1 = generic failure (default)
    #   2 = state mismatch (Set-JsonResult -ExitCode 2 was called before throw)
    #   3 = invalid arguments / OS guard refused
    #   4 = system error (WMI / file I/O / JSON parse / .NET I/O exceptions)
    # If a callee already populated an explicit non-zero exitCode in the
    # JSON envelope, honour that (most refuse-paths set ExitCode 2 or 3
    # before throwing). Otherwise classify the .NET exception type into
    # "system error" (code 4) vs "generic failure" (code 1).
    $code = if ($Script:JsonResult -and $Script:JsonResult.exitCode -ne 0) {
        [int]$Script:JsonResult.exitCode
    } else {
        $exType = if ($_.Exception) { $_.Exception.GetType().FullName } else { '' }
        if ($exType -match '^(System\.IO\.|System\.UnauthorizedAccessException$|Microsoft\.Management\.Infrastructure\.CimException$|System\.Management\.ManagementException$|System\.Xml\.XmlException$|Newtonsoft\.Json\.|System\.Text\.Json\.JsonException$|System\.Runtime\.Serialization\.SerializationException$)') {
            4
        } else {
            1
        }
    }
    if ($code -eq 0) { $code = 1 }
    if ($Script:OutputFormat -ne 'Json') {
        Write-Host ''
        Write-Host ('[X] FAILED: {0}' -f $_.Exception.Message) -ForegroundColor Red
        Write-Host ''
    }
    if ($Script:JsonResult.result -in @('unknown','')) {
        Set-JsonResult -Result 'error' -Message $_.Exception.Message -ExitCode $code
    } elseif ($Script:JsonResult.exitCode -eq 0) {
        Set-JsonResult -ExitCode $code -Message $_.Exception.Message
    }
    if ($Script:OutputFormat -eq 'Json') { _EmitJson }
    exit $code
}

if ($Script:OutputFormat -eq 'Json') { _EmitJson }
exit [int]$Script:JsonResult.exitCode
