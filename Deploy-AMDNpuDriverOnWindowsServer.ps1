<#
.SYNOPSIS
    Patches and installs the AMD NPU (Ryzen AI XDNA) kernel-mode driver on Windows Server 2025.

.DESCRIPTION
    PowerShell pipeline that makes the AMD consumer-targeted Ryzen AI NPU driver installable
    on Windows Server 2025 by patching the INF ProductType decoration and re-signing the
    catalog with a self-generated certificate.

    Companion to:
      - Deploy-AMDChipsetDriverOnWindowsServer.ps1
      - Deploy-AMDGraphicsDriverOnWindowsServer.ps1

    Architecture: same 21-phase pipeline (P00-P09 prep, V01-V06 verify, I00-I04 install).

    NPU-SPECIFIC NOTES vs the chipset and graphics sister scripts:
      - Distribution format: ZIP (not EXE) - extracted with 7-Zip (same tooling as
        chipset / graphics sister scripts; uses 7z.exe x for consistent behaviour)
      - URL resolution: 4-tier fallback
          (1) -InstallerUrl explicit URL
          (2) AMD account credential auto-download (-AmdAccountUser / -AmdAccountPassword)
          (3) AMD EULA-gated direct fetch probe
          (4) Local cache (-OfflineZip or sibling .zip)
      - Hardware detection: pnputil PCI HWID + REV byte parsing (PHX/HPT/STX/KRK)
      - NPU driver versioning is INDEPENDENT from Ryzen AI Software versioning.
        Per AMD docs (https://ryzenai.docs.amd.com/en/latest/inst.html, 2026-04-19):
          NPU drivers   : 32.0.203.280 (NPU_RAI1.5_280) or 32.0.203.314 (NPU_RAI1.6.1_314)
          RAI Software  : 1.7.1 (latest, ryzen-ai-lt-1.7.1.exe)
      - Default-when-undetected: Strix Point + NPU driver 32.0.203.314 + RAI Software latest
      - Out of scope: Ryzen AI Software user-mode stack (Python conda env, OGA, VAI EP)
        Users must install Ryzen AI Software separately - guidance provided at end of run.

    SUPPORTED NPU GENERATIONS:
      Phoenix    (PHX) PCI\VEN_1022&DEV_1502&REV_00  Ryzen 7040 series        RAI <= 1.5
      Hawk Point (HPT) PCI\VEN_1022&DEV_1502&REV_00  Ryzen 8040 series        RAI <= 1.5
      Strix      (STX) PCI\VEN_1022&DEV_17F0&REV_00/10/11  Ryzen AI 300       RAI 1.5+
      Strix Halo (STX) PCI\VEN_1022&DEV_17F0&REV_*  Ryzen AI Max 300          RAI 1.5+
      Krackan    (KRK) PCI\VEN_1022&DEV_17F0&REV_20  Ryzen AI 200             RAI 1.6.1+

.PARAMETER Action
    The pipeline action: PrepareVerify (P00-V06), Prepare (P00-P09), Verify (V01-V06),
    Install (I00-I04 after Prepare+Verify), Cleanup (remove cert/policy/drivers/workspace),
    or ListPhases (show phase ID table and exit).

.PARAMETER OnlyPhases
    Comma-separated list of phase IDs to run (e.g. "P05,P06,P08,P09"). When specified,
    only listed phases execute; useful for re-runs after manual edits.

.PARAMETER InstallerUrl
    Explicit URL to download the NPU driver ZIP. Bypasses URL resolution (Tier 1).

.PARAMETER OfflineZip
    Path to a pre-downloaded NPU driver ZIP. Bypasses URL resolution and download (Tier 4).

.PARAMETER AmdAccountUser
    AMD account username/email for auto-download via account.amd.com login (Tier 2).
    When combined with -AmdAccountPassword, the script attempts to authenticate, accept
    the Ryzen AI EULA, and download the driver ZIP automatically.

.PARAMETER AmdAccountPassword
    AMD account password (SecureString). Required if -AmdAccountUser is specified.

.PARAMETER ForceAmdAccountAuth
    Force the script to attempt the AMD account form-based authentication flow (Tier 2).
    Disabled by default since 2026-05-10 verification confirmed account.amd.com is a
    JavaScript-driven SPA that does not respond to PowerShell HTTP form POSTs. Use only
    if AMD has updated their portal or you have evidence the flow can succeed. Manual
    download via -OfflineZip <path> is the recommended pattern.

.PARAMETER NpuOverride
    Force a specific NPU codename: PHX, HPT, STX, or KRK. Useful when detection is
    ambiguous (e.g. Phoenix vs Hawk Point share the same PCI HWID).

.PARAMETER NpuDriverPackage
    Selects which NPU kernel-mode driver package to use. The NPU driver versioning is
    INDEPENDENT from the Ryzen AI Software (user-mode stack) versioning per AMD's
    official documentation at https://ryzenai.docs.amd.com/en/latest/inst.html.

      'NPU_RAI1.5_280'    : NPU driver 32.0.203.280 (older, Phoenix/Hawk Point/Strix/STH/KRK)
      'NPU_RAI1.6.1_314'  : NPU driver 32.0.203.314 (newer, same NPU coverage)
      'latest' (default)  : NPU_RAI1.6.1_314 (the latest documented in AMD docs)

    AMD documents both 280 and 314 as valid drivers for current Ryzen AI Software (1.7.1).
    Pick 'NPU_RAI1.5_280' only if your offline ZIP is the older one.

.PARAMETER RyzenAiSoftwareVersion
    Selects which Ryzen AI Software (user-mode stack) installer to recommend in the
    post-install guidance message. This is INDEPENDENT from -NpuDriverPackage.

      '1.5' / '1.6.1' / '1.7' / '1.7.1' : pin to a specific release
      'latest' (default)                : recommend the latest available (1.7.1 as of
                                          AMD docs 2026-04-19)

    AMD recommends always using the latest Ryzen AI Software for end-user workloads;
    this script's default is therefore 'latest'. The Ryzen AI Software is downloaded
    and installed by the user separately (via ryzen-ai-lt-<ver>.exe), not by this
    script. This parameter only affects the guidance text shown in the I04 post-
    install banner.

.PARAMETER AssumeIfMissing
    If NPU is not detected (e.g. running on a host without an AMD NPU device for
    pipeline-soundness regression), proceed using the default profile
    (Strix Point + NPU_RAI1.6.1_314 + RAI Software latest).

.PARAMETER AllowWorkstationInstall
    Permit Install-phase actions on Workstation OS (Win11). Discouraged. Default behaviour
    blocks Install on Workstation and runs PrepareVerify only.

.PARAMETER UseTestSigning
    Fall back to bcdedit /set testsigning on instead of the default WDAC supplemental policy.
    Discouraged on Windows Server 2022+ / Windows 11 22H2+.

.PARAMETER CleanWorkRoot
    Delete the workspace directory before starting (forces a fresh download/extract).

.PARAMETER WorkRoot
    Override the default workspace path. Default: C:\Temp\Workspace_AMD-NPU
    (relocated under C:\Temp\Workspace_* to keep workspace data
    clustered under one parent directory that is trivial to inspect and
    purge. The script auto-creates C:\Temp on demand.)

.PARAMETER LogFile
    Optional path to capture the full console transcript to a
    file. When set, the script wraps its execution in
    Start-Transcript / Stop-Transcript so the file receives every
    stream (Output / Host / Error / Warning / Verbose / Debug) as
    plain text, while the interactive console keeps its color
    decoration (Write-Host -ForegroundColor) intact. This is the
    recommended way to retain a run log without losing console
    colors — Tee-Object on the outside of the pipeline strips
    Write-Host coloring, this option does not.

    The parent directory is created on demand. The file is opened
    in -Append mode so concurrent re-runs accumulate rather than
    truncate. Recommended filename convention:
        C:\Temp\npu_<Action>_<yyyyMMdd-HHmmss>.log

.PARAMETER PfxPassword
    Password for the self-signed PFX. Default is empty (lab tool).

.PARAMETER CertValidityYears
    Self-signed cert validity period in years. Default 5.

.EXAMPLE
    # Pipeline soundness check, no system change. Recommended for first-time runs
    # where Tier 4 auto-scan may not find a ZIP in default locations.
    .\Deploy-AMDNpuDriverOnWindowsServer.ps1 -Action PrepareVerify -CleanWorkRoot -OfflineZip .\NPU_RAI1.6.1_314_WHQL.zip

.EXAMPLE
    # Pipeline soundness check on a non-NPU host for regression testing.
    # -AssumeIfMissing forces the default Strix Point profile when no NPU is detected.
    # NOTE: This validates pipeline mechanics only — it does NOT validate real NPU behaviour.
    .\Deploy-AMDNpuDriverOnWindowsServer.ps1 -Action PrepareVerify -CleanWorkRoot `
        -OfflineZip .\NPU_RAI1.6.1_314_WHQL.zip -AssumeIfMissing

.EXAMPLE
    # Pipeline soundness check WITHOUT -OfflineZip. Will only succeed if a ZIP is
    # found via Tier 4 auto-scan (script dir /./cache / workspace download dir / ~/Downloads).
    # If no ZIP is cached anywhere, P03 will throw "All 4 download tiers exhausted".
    .\Deploy-AMDNpuDriverOnWindowsServer.ps1 -Action PrepareVerify -CleanWorkRoot

.EXAMPLE
    # Full install on a real NPU host using a manually-downloaded offline ZIP (most reliable).
    # Requires interactive "I AGREE" confirmation at I00 (EULA acknowledgement).
    .\Deploy-AMDNpuDriverOnWindowsServer.ps1 -Action Install -OfflineZip .\NPU_RAI1.6.1_314_WHQL.zip

.EXAMPLE
    # Full install via AMD account auto-download (Tier 2). BEST-EFFORT: may break
    # without notice when AMD changes their account.amd.com form layouts.
    .\Deploy-AMDNpuDriverOnWindowsServer.ps1 -Action Install `
        -AmdAccountUser 'user@example.com' `
        -AmdAccountPassword (Read-Host 'AMD password' -AsSecureString)

.EXAMPLE
    # Force a specific NPU codename + driver package, with offline ZIP as the source.
    # NPU driver and Ryzen AI Software versioning are independent: -NpuDriverPackage
    # selects the kernel driver, -RyzenAiSoftwareVersion selects the user-mode stack.
    .\Deploy-AMDNpuDriverOnWindowsServer.ps1 -Action Install `
        -OfflineZip .\NPU_RAI1.6.1_314_WHQL.zip `
        -NpuOverride STX `
        -NpuDriverPackage NPU_RAI1.6.1_314 `
        -RyzenAiSoftwareVersion latest

.EXAMPLE
    # Capture full transcript while keeping console colors
    $ts  = Get-Date -Format 'yyyyMMdd-HHmmss'
    $log = "C:\Temp\npu_PrepareVerify_$ts.log"
    .\Deploy-AMDNpuDriverOnWindowsServer.ps1 `
        -Action PrepareVerify -CleanWorkRoot `
        -OfflineZip .\NPU_RAI1.6.1_314_WHQL.zip `
        -LogFile $log

.EXAMPLE
    # Legacy fallback (color is stripped from the captured file)
    .\Deploy-AMDNpuDriverOnWindowsServer.ps1 -Action Install `
        -OfflineZip .\NPU_RAI1.6.1_314_WHQL.zip *>&1 |
        Tee-Object -FilePath "C:\Temp\npu_Install_$(Get-Date -Format 'yyyyMMdd-HHmmss').log"

.NOTES
    Repository     : https://github.com/usui-tk/Deploy-Drivers-For-WindowsServer
    Sister scripts : Deploy-AMD{Chipset,Graphics}DriverOnWindowsServer.ps1,
                     Deploy-MSBthPanInboxOnWindowsServer.ps1
    License        : MIT (see LICENSE)
    Current version: see `$Script:ScriptVersion` below

    PowerShell 5.1+ (Desktop or Core), 64-bit, run as Administrator.

    DISCLAIMER:
      - Lab/research tool. AMD does NOT officially support Ryzen AI on Windows Server.
      - This script installs the kernel-mode NPU driver only. Ryzen AI Software (Python
        conda env, ONNX Runtime, Vitis AI EP, OGA models) must be installed separately
        and is unlikely to function on Server 2025 without unofficial workarounds.
      - Self-signed driver chain. WHQL certification is invalidated for replaced drivers.
      - Every run with -Action Install requires accepting AMD's Ryzen AI EULA at
        https://account.amd.com/en/forms/downloads/ryzenai-eula-public-xef.html
#>

#Requires -Version 5.1
#Requires -RunAsAdministrator

[CmdletBinding()]
param(
    [Parameter()]
    [ValidateSet('Prepare','Verify','PrepareVerify','Install','All','Cleanup','ListPhases')]
    [string]$Action = 'PrepareVerify',

    [Parameter()]
    [string[]]$OnlyPhases = @(),

    [Parameter()]
    [string]$InstallerUrl = '',

    [Parameter()]
    [string]$OfflineZip = '',

    [Parameter()]
    [string]$AmdAccountUser = '',

    [Parameter()]
    [System.Security.SecureString]$AmdAccountPassword = $null,

    [Parameter()]
    [switch]$ForceAmdAccountAuth,

    [Parameter()]
    # bugfix: include '' so that the default (parameter omitted)
    # passes ValidateSet on the line 'Script:NpuOverride = $NpuOverride'
    # assignment, which re-evaluates parameter validation in PSv5. The
    # empty value means "no override; auto-detect via Get-AmdNpuPlatform".
    [ValidateSet('','PHX','HPT','STX','KRK')]
    [string]$NpuOverride = '',

    [Parameter()]
    [ValidateSet('NPU_RAI1.5_280', 'NPU_RAI1.6.1_314', 'latest')]
    [string]$NpuDriverPackage = 'latest',

    [Parameter()]
    [ValidateSet('1.5', '1.6.1', '1.7', '1.7.1', 'latest')]
    [string]$RyzenAiSoftwareVersion = 'latest',

    [Parameter()]
    [switch]$AssumeIfMissing,

    [Parameter()]
    [switch]$AllowWorkstationInstall,

    [Parameter()]
    [switch]$UseTestSigning,

    [Parameter()]
    [switch]$CleanWorkRoot,

    [Parameter()]
    # Relocated under C:\Temp\Workspace_* to keep workspace data
    # clustered under one parent directory that is trivial to inspect
    # and purge. The script auto-creates C:\Temp if it does not exist.
    [string]$WorkRoot = 'C:\Temp\Workspace_AMD-NPU',

    [Parameter()]
    # === Console transcript capture ============================
    # Optional path; when set, the script wraps its execution in
    # Start-Transcript / Stop-Transcript so the file gets every stream
    # as plain text while the live console keeps its Write-Host color
    # decoration. This is the recommended replacement for the legacy
    # `... *>&1 | Tee-Object -FilePath...` idiom, which strips
    # Write-Host coloring on the way through the pipeline.
    [string]$LogFile = '',

    [Parameter()]
    # NOTE: [string] (not [SecureString]) because the password is forwarded to
    # signtool.exe via /p and to X509Certificate2(.., String) — both APIs
    # require a plaintext String. Default is empty (no password).
    [string]$PfxPassword = '',  # psa-disable-line PSA5001 -- signtool /p and X509Certificate2 require plaintext String

    [Parameter()]
    [int]$CertValidityYears = 5,

    [Parameter()]
    [string]$WdacPolicyGuid = ''
)

# =============================================================================
# Script-scope infrastructure (logging, identity, timing).
#
# The script no longer mirrors operational parameters or derived paths
# into the Script scope - all of that state is carried on the $Ctx
# PSCustomObject that Invoke-MainEntryPoint constructs and threads
# through every phase / helper. Only the following remain at script
# scope:
#
#   * ScriptVersion / ScriptTag / ScriptName / RepoUrl / ScriptHash /
#     ScriptPath / ScriptShortTag - identity metadata read by banners,
#     log headers, and Write-DebugFailureReport.
#   * WdacPolicyGuidDefault / WdacPolicyGuid - read by the AMD-family
#     3-way Tier B-3 helper Test-AmdWdacPolicyDeployed (byte-identical
#     across Chipset / Graphics / NPU; migrating its consumer would
#     break the 3-way identity and is deferred to a future cross-script
#     refactor).
#   * HostStartTime / ScriptStartTime / CurrentPhaseStart /
#     CurrentPhaseId / PhaseTimings - dispatcher and phase-runner
#     instrumentation.
#   * PhaseResults - per-phase outcome registry (write side from
#     dispatcher; read side from Show-RunSummary).
# =============================================================================
$Script:ScriptVersion       = 'npu-2026.07.03-r32'
$Script:ScriptTag           = 'cross-repo-canon-vendored-region-markers-wave-1'
$Script:ScriptName          = 'Deploy-AMDNpuDriverOnWindowsServer'
$Script:RepoUrl             = 'https://github.com/usui-tk/Deploy-Drivers-For-WindowsServer'
# Default fixed WDAC Policy GUID (UUID v4). Operators can override via the
# -WdacPolicyGuid parameter, e.g. when cleaning up a legacy deploy whose
# PolicyId differs from the default. Kept at script scope because
# Test-AmdWdacPolicyDeployed (a 3-way Tier B-3 helper byte-identical
# across the AMD family) reads $Script:WdacPolicyGuid directly.
$Script:WdacPolicyGuidDefault = '8B2C4F12-1E9D-4D7B-A4F8-9C7E2B6A53D1'
$Script:WdacPolicyGuid      = if (-not [string]::IsNullOrWhiteSpace($WdacPolicyGuid)) {
    $WdacPolicyGuid.Trim('{','}','(',')',' ')
} else {
    $Script:WdacPolicyGuidDefault
}
$Script:HostStartTime       = Get-Date
$Script:ScriptStartTime     = Get-Date

# Sister-script-aligned: per-phase timing and elapsed-tag infrastructure
$Script:CurrentPhaseStart   = $null
$Script:CurrentPhaseId      = $null
$Script:PhaseTimings        = New-Object System.Collections.Generic.List[object]

# Sister-script-aligned: SHA256-based one-line script-identity tag.
# When users report unexpected behaviour, the hash uniquely identifies the
# exact file they ran (immune to filename collisions or partial overwrites).
$Script:ScriptHash = '(unknown)'
try {
    $scriptPath = $PSCommandPath
    if ([string]::IsNullOrEmpty($scriptPath)) { $scriptPath = $MyInvocation.MyCommand.Path }
    if ($scriptPath -and (Test-Path -LiteralPath $scriptPath)) {
        $hashFull = (Get-FileHash -LiteralPath $scriptPath -Algorithm SHA256).Hash
        $Script:ScriptHash = $hashFull.Substring(0, 12).ToLower()
        $Script:ScriptPath = $scriptPath
    }
} catch {
    $Script:ScriptHash = '(hash-error)'
}
$Script:ScriptShortTag = ('{0}/{1}' -f $Script:ScriptVersion, $Script:ScriptHash)

#####################################################################
# SECTION 0.25: Optional console transcript capture
#####################################################################
# When -LogFile is set, wrap execution in Start-Transcript so the file
# receives every stream (Output / Host / Error / Warning / Verbose /
# Debug) as plain text, while the interactive console keeps its
# Write-Host -ForegroundColor decoration intact. The matching
# Stop-Transcript is invoked in the top-level finally block at the
# bottom of this script; the PowerShell.Exiting hook below is a
# best-effort fallback if the script exits earlier than the finally.
#
# Tee-Object on the outside of the pipeline (`... *>&1 | Tee-Object`)
# strips Write-Host coloring because the host stream is captured into
# the pipeline value stream. The -LogFile path here is the recommended
# alternative when console coloring matters to the operator.
#
# Transcript verified activation:
#
#   Reports from PS 5.1.26100.32860 (Windows Server 2025) showed that
#   `Start-Transcript -Path X -Append -Force` raised
#   ParameterBindingException ("Parameter set cannot be resolved using
#   the specified named parameters") only when invoked from the actual
#   BthPan script body. Isolated minimal reproductions (clean session,
#   same param block in a separate small.ps1) all succeeded. The
#   root cause for the script-context-specific failure could not be
#   pinpointed within a reasonable budget; instead, takes a
#   defense-in-depth approach:
#
#     1. CAPTURE the cmdlet return value (a non-empty localized success
#        message proves the cmdlet completed normally).
#     2. POLL the log file's appearance on disk with a short timeout
#        (3 s default, 50 ms interval) - Start-Transcript opens the
#        file before returning, so a missing file means the transcript
#        did not actually start.
#     3. WRITE a probe marker via Write-Output, briefly Start-Sleep,
#        then read the file back and confirm the marker landed there.
#        This is the only deterministic way to know transcription is
#        actively capturing output (vs. silently dropping it).
#     4. STOP-TRANSCRIPT + Start-Sleep BETWEEN failed attempts so a
#        partially-initialized state from one attempt does not
#        contaminate the next.
#     5. RECORD per-attempt failure metadata (exception type, FQId,
#        message) so post-mortem diagnosis has enough material.
#
#   A failed transcript activation MUST NEVER prevent the script from
#   running its actual work. If activation fails, the script proceeds
#   uncaptured with a prominent warning and a Tee-Object workaround.
#####################################################################
# Auto-relocation guard for -LogFile vs -WorkRoot + -CleanWorkRoot
#####################################################################
# When the operator specifies a -LogFile path that resolves to a
# location INSIDE -WorkRoot AND -CleanWorkRoot is also requested, the
# P01 PrepareWorkspace phase would attempt Remove-Item on the WorkRoot
# subtree while Start-Transcript holds the transcript file open in
# write mode. That produces an IOException
# ("FileInfo: another process is using this file") partway through
# the recursive delete, leaving the workspace in a half-deleted
# state.
#
# Instead of throwing, we auto-relocate the transcript to a safe
# path (this script's own directory, falling back to %TEMP%) with a
# timestamp-suffixed filename. The user's transcript intent is
# preserved; only the LOCATION is corrected. A prominent Write-Warning
# is emitted so the new path is visible. Both the original and new
# paths are also recorded on $Script:LogFileSetup for the RUN
# SUMMARY.
#
# Trigger: $LogFile is non-empty AND $CleanWorkRoot AND $LogFile
#             resolves to a sub-path of $WorkRoot
# Target: <script-dir>\Deploy-AMDNpuDriverOnWindowsServer_<Action>_<ts>.log
# Fallback: %TEMP%\Deploy-AMDNpuDriverOnWindowsServer_<Action>_<ts>.log
#             when script-dir is unavailable
#
# The intentional design choice is "relocate, do not refuse" so a
# benign user mistake (putting transcript next to its peer artifacts
# under logs\) does not block the run. The P01 pre-flight guard below
# stays as a defense-in-depth backstop in case this relocation logic
# itself fails to apply for any reason.
$Script:LogFileRelocation = $null
if (-not [string]::IsNullOrWhiteSpace($LogFile) -and $CleanWorkRoot) {
    try {
        $resolvedLog      = [System.IO.Path]::GetFullPath($LogFile)
        $resolvedWorkRoot = [System.IO.Path]::GetFullPath($WorkRoot)
        # Normalize WorkRoot to end with separator so "C:\Workspace"
        # does not falsely match "C:\Workspace_Other\..." via prefix.
        if (-not $resolvedWorkRoot.EndsWith([System.IO.Path]::DirectorySeparatorChar) -and `
            -not $resolvedWorkRoot.EndsWith([System.IO.Path]::AltDirectorySeparatorChar)) {
            $resolvedWorkRoot = $resolvedWorkRoot + [System.IO.Path]::DirectorySeparatorChar
        }
        if ($resolvedLog.StartsWith($resolvedWorkRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
            # Determine target directory: prefer this script's own
            # directory, fall back to %TEMP% if unavailable.
            $targetDir = $null
            if ($Script:ScriptPath) {
                $candidate = [System.IO.Path]::GetDirectoryName($Script:ScriptPath)
                if (-not [string]::IsNullOrWhiteSpace($candidate) -and (Test-Path -LiteralPath $candidate)) {
                    $targetDir = $candidate
                }
            }
            if ([string]::IsNullOrWhiteSpace($targetDir)) {
                $targetDir = [System.IO.Path]::GetTempPath().TrimEnd([System.IO.Path]::DirectorySeparatorChar,
                                                                     [System.IO.Path]::AltDirectorySeparatorChar)
            }
            $ts          = (Get-Date).ToString('yyyyMMdd-HHmmss')
            $newLogLeaf  = ('Deploy-AMDNpuDriverOnWindowsServer_{0}_{1}.log' -f $Action, $ts)
            $newLogFile  = Join-Path $targetDir $newLogLeaf

            Write-Warning '[-LogFile guard] Specified -LogFile is inside -WorkRoot:'
            Write-Warning ('     -LogFile  : {0}' -f $resolvedLog)
            Write-Warning ('     -WorkRoot : {0}' -f $resolvedWorkRoot)
            Write-Warning '   With -CleanWorkRoot set, the P01 wipe would collide with the active'
            Write-Warning '   Start-Transcript file handle. Auto-relocating transcript to a safe path:'
            Write-Warning ('     New -LogFile -> {0}' -f $newLogFile)
            Write-Warning '   Tip: pass -LogFile outside -WorkRoot to avoid this notice. Example:'
            Write-Warning ("       `$ts  = Get-Date -Format 'yyyyMMdd-HHmmss'")
            Write-Warning ("       `$log = `"C:\Temp\Deploy-AMDNpuDriverOnWindowsServer_{0}_`$ts.log`"" -f $Action)
            Write-Warning '       .\Deploy-AMDNpuDriverOnWindowsServer.ps1 -Action <Action> -CleanWorkRoot -LogFile $log'

            $Script:LogFileRelocation = [pscustomobject]@{
                OriginalPath = $resolvedLog
                NewPath      = $newLogFile
                Reason       = '-LogFile inside -WorkRoot conflicts with -CleanWorkRoot wipe'
            }
            $LogFile = $newLogFile
        }
    } catch {
        # Pre-flight relocation failure is non-fatal; the P01 in-phase
        # guard below still catches an actual overlap as a backstop.
        Write-Warning ("[-LogFile guard] Pre-flight relocation check failed (non-fatal): {0}" -f $_.Exception.Message)
    }
}

$Script:LogFileActive = $false
if (-not [string]::IsNullOrWhiteSpace($LogFile)) {

    # Result accumulator. Populated whether activation succeeds or not.
    $Script:LogFileSetup = [pscustomobject]@{
        Path           = $LogFile
        Active         = $false
        SuccessfulForm = $null
        ReturnValue    = $null
        FileExists     = $false
        FileSizeBefore = 0
        FileSizeAfter  = 0
        ProbeWritten   = $false
        ProbeCaptured  = $false
        ElapsedMs      = 0
        FailedAttempts = New-Object System.Collections.Generic.List[object]
    }
    $logSetupSw = [System.Diagnostics.Stopwatch]::StartNew()

    try {
        # Ensure parent directory exists. Use -ErrorAction Stop so a
        # path-creation failure is caught by the outer catch and
        # reported clearly rather than producing a misleading
        # "transcript failed" message later.
        #
        # IMPORTANT: Use [System.IO.Path]::GetDirectoryName instead of
        # Split-Path -LiteralPath $LogFile -Parent. On Windows PowerShell
        # 5.1, Split-Path parameter sets put -LiteralPath into
        # LiteralPathSet and -Parent into ParentSet (mutually exclusive),
        # which causes an AmbiguousParameterSet binding error. This was
        # the root cause of long-standing -LogFile bind failures on
        # ja-JP PS 5.1. See Microsoft Learn:
        # https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.management/split-path?view=powershell-5.1
        $logDir = [System.IO.Path]::GetDirectoryName($LogFile)
        if (-not [string]::IsNullOrWhiteSpace($logDir) -and -not (Test-Path -LiteralPath $logDir)) {
            New-Item -ItemType Directory -Path $logDir -Force -ErrorAction Stop | Out-Null
        }

        # Defensive: stop any in-flight transcript from a previous run
        # in the same PowerShell host (Start-Transcript fails if one is
        # already active). Best-effort, no error if none is active.
        try { Stop-Transcript -ErrorAction SilentlyContinue | Out-Null } catch { } # psa-disable-line PSA3004 -- intentional best-effort cleanup
        Start-Sleep -Milliseconds 100  # let the host settle before next call

        # Progressively-simpler invocation forms. Each is invoked as a
        # script block to keep the call surface minimal. We try them in
        # order; the first one whose RETURN VALUE is non-empty AND
        # whose log file appears on disk within the timeout is taken
        # as the winner.
        $logSetupForms = @(
            @{ Label = '-Path -Append -Force'
               Block = { param($p) Start-Transcript -Path $p -Append -Force -ErrorAction Stop } } # psa-disable-line PSA3005 -- deliberate cascade of -Path vs -LiteralPath variants for transcript-handle fallback (see "logSetupForms" / "TranscriptAttempt" comment block)
            @{ Label = '-LiteralPath -Append -Force'
               Block = { param($p) Start-Transcript -LiteralPath $p -Append -Force -ErrorAction Stop } }
            @{ Label = '-Path -Force (no -Append)'
               Block = { param($p) Start-Transcript -Path $p -Force -ErrorAction Stop } } # psa-disable-line PSA3005 -- deliberate cascade of -Path vs -LiteralPath variants for transcript-handle fallback (see "logSetupForms" / "TranscriptAttempt" comment block)
            @{ Label = '-Path only (minimal)'
               Block = { param($p) Start-Transcript -Path $p -ErrorAction Stop } } # psa-disable-line PSA3005 -- deliberate cascade of -Path vs -LiteralPath variants for transcript-handle fallback (see "logSetupForms" / "TranscriptAttempt" comment block)
            @{ Label = 'Invoke-Expression re-parse (last resort)'
               Block = { param($p)
                   $escaped = ($p -replace "'", "''")
                   $cmd = "Start-Transcript -Path '{0}' -Force -ErrorAction Stop" -f $escaped
                   Invoke-Expression $cmd  # psa-disable-line PSA5002 -- last-resort re-parse path, input is the script's own -LogFile parameter with single-quote escape
               } }
        )

        $confirmTimeoutMs    = 3000
        $confirmPollMs       = 50
        $interAttemptWaitMs  = 300
        $probeFlushWaitMs    = 200

        foreach ($form in $logSetupForms) {
            $attemptDiag = [ordered]@{
                Form    = $form.Label
                Stage   = 'invocation'
                Type    = $null
                Message = $null
                FQId    = $null
            }
            $rv = $null

            # ----- Stage 1: invocation -----
            try {
                $rv = & $form.Block $LogFile
            } catch {
                $attemptDiag.Stage   = 'invocation'
                $attemptDiag.Type    = $_.Exception.GetType().FullName
                $attemptDiag.Message = $_.Exception.Message
                $attemptDiag.FQId    = $_.FullyQualifiedErrorId
                Write-Host ("[Transcript] {0} -> invocation FAILED: {1}" -f $form.Label, $_.Exception.Message) -ForegroundColor DarkYellow
                $Script:LogFileSetup.FailedAttempts.Add([pscustomobject]$attemptDiag)
                # Cleanup partial state, then continue
                try { Stop-Transcript -ErrorAction SilentlyContinue | Out-Null } catch { } # psa-disable-line PSA3004
                Start-Sleep -Milliseconds $interAttemptWaitMs
                continue
            }

            # ----- Stage 2: return value verification -----
            if (-not $rv) {
                $attemptDiag.Stage   = 'return-value-empty'
                $attemptDiag.Message = 'Start-Transcript returned $null or empty - transcript did not actually start'
                Write-Host ("[Transcript] {0} -> return value EMPTY" -f $form.Label) -ForegroundColor DarkYellow
                $Script:LogFileSetup.FailedAttempts.Add([pscustomobject]$attemptDiag)
                try { Stop-Transcript -ErrorAction SilentlyContinue | Out-Null } catch { } # psa-disable-line PSA3004
                Start-Sleep -Milliseconds $interAttemptWaitMs
                continue
            }

            # ----- Stage 3: file appearance verification (polling) -----
            $fileDeadline = (Get-Date).AddMilliseconds($confirmTimeoutMs)
            $fileReady    = $false
            while ((Get-Date) -lt $fileDeadline) {
                if (Test-Path -LiteralPath $LogFile) { $fileReady = $true; break }
                Start-Sleep -Milliseconds $confirmPollMs
            }
            if (-not $fileReady) {
                $attemptDiag.Stage   = 'file-not-appearing'
                $attemptDiag.Message = ("Log file did not appear within {0} ms: {1}" -f $confirmTimeoutMs, $LogFile)
                Write-Host ("[Transcript] {0} -> file did not appear ({1} ms)" -f $form.Label, $confirmTimeoutMs) -ForegroundColor DarkYellow
                $Script:LogFileSetup.FailedAttempts.Add([pscustomobject]$attemptDiag)
                try { Stop-Transcript -ErrorAction SilentlyContinue | Out-Null } catch { } # psa-disable-line PSA3004
                Start-Sleep -Milliseconds $interAttemptWaitMs
                continue
            }

            try {
                $Script:LogFileSetup.FileSizeBefore = (Get-Item -LiteralPath $LogFile -ErrorAction Stop).Length
            } catch {
                $Script:LogFileSetup.FileSizeBefore = -1
            }

            # ----- Stage 4: probe-marker write & read-back -----
            # The most reliable way to verify transcription is actively
            # capturing: write a known marker, wait for flush, read back.
            $probeMarker = '[transcript-probe-{0}]' -f ([Guid]::NewGuid().ToString('N').Substring(0, 12))
            Write-Output $probeMarker | Out-Null  # routed into the transcript
            Write-Host $probeMarker -ForegroundColor DarkGray  # also written via host stream
            $Script:LogFileSetup.ProbeWritten = $true
            Start-Sleep -Milliseconds $probeFlushWaitMs

            $probeFound = $false
            try {
                $content = Get-Content -LiteralPath $LogFile -Raw -ErrorAction Stop
                if ($content -and $content.Contains($probeMarker)) {
                    $probeFound = $true
                }
            } catch {
                # ignore read errors here; the probe just wasn't captured
            }
            $Script:LogFileSetup.ProbeCaptured = $probeFound

            try {
                $Script:LogFileSetup.FileSizeAfter = (Get-Item -LiteralPath $LogFile -ErrorAction Stop).Length
            } catch {
                $Script:LogFileSetup.FileSizeAfter = -1
            }

            if (-not $probeFound) {
                # File exists and cmdlet returned non-empty, but the
                # probe marker did not land in the file. This is a
                # silent capture failure - rare but possible.
                $attemptDiag.Stage   = 'probe-not-captured'
                $attemptDiag.Message = 'Probe marker was not captured in the log file - transcription is silently dropping output'
                Write-Host ("[Transcript] {0} -> probe NOT captured (transcript file exists but is not capturing)" -f $form.Label) -ForegroundColor DarkYellow
                $Script:LogFileSetup.FailedAttempts.Add([pscustomobject]$attemptDiag)
                try { Stop-Transcript -ErrorAction SilentlyContinue | Out-Null } catch { } # psa-disable-line PSA3004
                Start-Sleep -Milliseconds $interAttemptWaitMs
                continue
            }

            # ----- All stages passed -----
            $Script:LogFileSetup.Active         = $true
            $Script:LogFileSetup.SuccessfulForm = $form.Label
            $Script:LogFileSetup.ReturnValue    = $rv
            $Script:LogFileSetup.FileExists     = $true
            Write-Host ("[Transcript] {0} -> VERIFIED ACTIVE" -f $form.Label) -ForegroundColor DarkGreen
            Write-Host ("              Return    : {0}" -f $rv) -ForegroundColor DarkGray
            Write-Host ("              File size : {0} bytes (before-probe) -> {1} bytes (after-probe)" -f `
                            $Script:LogFileSetup.FileSizeBefore, $Script:LogFileSetup.FileSizeAfter) -ForegroundColor DarkGray
            break
        }

        if (-not $Script:LogFileSetup.Active) {
            throw 'Transcript activation could not be verified through any invocation form'
        }

        $Script:LogFileActive = $true
        Register-EngineEvent -SourceIdentifier PowerShell.Exiting -SupportEvent -Action {
            try { Stop-Transcript -ErrorAction SilentlyContinue | Out-Null } catch { } # psa-disable-line PSA3004
        } | Out-Null
        Write-Host ('[*] Transcript active -> {0}' -f $LogFile) -ForegroundColor DarkGreen
    } catch {
        Write-Warning ("Transcript activation failed at '{0}': {1}" -f $LogFile, $_.Exception.Message)
        Write-Warning '   Continuing without log capture. Script execution itself is not affected.'
        if ($Script:LogFileSetup.FailedAttempts.Count -gt 0) {
            Write-Warning '   Per-attempt failure log:'
            foreach ($f in $Script:LogFileSetup.FailedAttempts) {
                Write-Warning ('     - [{0}] {1}' -f $f.Form, $f.Stage)
                if ($f.Type)    { Write-Warning ('         Type   : {0}' -f $f.Type) }
                if ($f.FQId)    { Write-Warning ('         FQErrId: {0}' -f $f.FQId) }
                if ($f.Message) { Write-Warning ('         Message: {0}' -f $f.Message) }
            }
        }
        Write-Warning '   Workaround: capture the console output with the legacy Tee-Object idiom:'
        Write-Warning '       .\Deploy-AMDNpuDriverOnWindowsServer.ps1 -Action PrepareVerify *>&1 | Tee-Object -FilePath C:\Temp\out.log'
        $Script:LogFileActive = $false
    } finally {
        $logSetupSw.Stop()
        $Script:LogFileSetup.ElapsedMs = $logSetupSw.ElapsedMilliseconds
        if ($Script:LogFileActive) {
            Write-Host ('[*] Transcript setup elapsed: {0} ms' -f $Script:LogFileSetup.ElapsedMs) -ForegroundColor DarkGray
        }
    }
}
# Phase registry (sister-script-aligned: pscustomobject + Invoke-{Group}Phase{NN}_{Name})
$Script:PhaseRegistry = @(
    [pscustomobject]@{ Id='P00'; Name='Initialize';                Group='Prep';   Func='Invoke-PrepPhase00_Initialize'                }
    [pscustomobject]@{ Id='P01'; Name='PrepareWorkspace';          Group='Prep';   Func='Invoke-PrepPhase01_PrepareWorkspace'          }
    [pscustomobject]@{ Id='P02'; Name='AcquireTools';              Group='Prep';   Func='Invoke-PrepPhase02_AcquireTools'              }
    [pscustomobject]@{ Id='P03'; Name='FetchInstaller';            Group='Prep';   Func='Invoke-PrepPhase03_FetchInstaller'            }
    [pscustomobject]@{ Id='P04'; Name='ExtractInstaller';          Group='Prep';   Func='Invoke-PrepPhase04_ExtractInstaller'          }
    [pscustomobject]@{ Id='P05'; Name='AnalyzeInfs';               Group='Prep';   Func='Invoke-PrepPhase05_AnalyzeInfs'               }
    [pscustomobject]@{ Id='P06'; Name='PatchInfs';                 Group='Prep';   Func='Invoke-PrepPhase06_PatchInfs'                 }
    [pscustomobject]@{ Id='P07'; Name='CreateCertificate';         Group='Prep';   Func='Invoke-PrepPhase07_CreateCertificate'         }
    [pscustomobject]@{ Id='P08'; Name='GenerateCatalogs';          Group='Prep';   Func='Invoke-PrepPhase08_GenerateCatalogs'          }
    [pscustomobject]@{ Id='P09'; Name='SignCatalogs';              Group='Prep';   Func='Invoke-PrepPhase09_SignCatalogs'              }
    [pscustomobject]@{ Id='V01'; Name='VerifyArtifacts';           Group='Verify'; Func='Invoke-VerifyPhase01_VerifyArtifacts'         }
    [pscustomobject]@{ Id='V02'; Name='VerifyCertificate';         Group='Verify'; Func='Invoke-VerifyPhase02_VerifyCertificate'       }
    [pscustomobject]@{ Id='V03'; Name='VerifyCatalogs';            Group='Verify'; Func='Invoke-VerifyPhase03_VerifyCatalogs'          }
    [pscustomobject]@{ Id='V04'; Name='VerifyInfs';                Group='Verify'; Func='Invoke-VerifyPhase04_VerifyInfs'              }
    [pscustomobject]@{ Id='V05'; Name='DryRunInstall';             Group='Verify'; Func='Invoke-VerifyPhase05_DryRunInstall'           }
    [pscustomobject]@{ Id='V06'; Name='HardwareImpactAnalysis';    Group='Verify'; Func='Invoke-VerifyPhase06_HardwareImpactAnalysis'  }
    [pscustomobject]@{ Id='I00'; Name='PreInstallReview';          Group='Inst';   Func='Invoke-InstPhase00_PreInstallReview'          }
    [pscustomobject]@{ Id='I01'; Name='TrustCertificate';          Group='Inst';   Func='Invoke-InstPhase01_TrustCertificate'          }
    [pscustomobject]@{ Id='I02'; Name='AuthorizeDriverSigning';    Group='Inst';   Func='Invoke-InstPhase02_AuthorizeDriverSigning'    }
    [pscustomobject]@{ Id='I03'; Name='InstallDrivers';            Group='Inst';   Func='Invoke-InstPhase03_InstallDrivers'            }
    [pscustomobject]@{ Id='I04'; Name='PostInstallVerification';   Group='Inst';   Func='Invoke-InstPhase04_PostInstallVerification'   }
)



# Phase results
$Script:PhaseResults = @{}

# =============================================================================
# Output helpers - colour-coded console output (sister-script-aligned)
#
# Logging style is unified with the chipset / graphics deployment scripts in
# this repository. Each line is prefixed with [HH:mm:ss] [+X.XXs] markers so
# operators reading concatenated logs from all three pipelines see the same
# format and timing information.
#
# Marker semantics:
#   [*] Cyan - Step (action being performed)
#   [+] Green - Ok (success / positive result)
#   [!] Yellow - Warn (degraded / suspicious; non-fatal)
#   [X] Red - Fail (operation failed)
#   [~] DarkGray - Skip (no-op / cached / informational)
#
# Phase entry: Write-PhaseHeader (Magenta '=' x72) - rendered by dispatcher
# Sub-section: Write-SubHeader (Cyan '=' x72) - in-phase Level-1 banner
# Sub-section: Write-SubHeader2 (DarkCyan '-' x72) - in-phase Level-2 banner
# =============================================================================
# >>> CANONICAL unit_id=pwsh.helper.format-elapsed version=1.0.0 hash=b63f12c32ee28520 policy=canonical binding=follow-latest >>>
function Format-Elapsed {
    # Render a TimeSpan in a compact human-readable form.
    # Examples: '0.45s', '12.3s', '5m12.4s', '1h05m12s'
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
        return ('{0}h{1:D2}m{2:D2}s' -f $h, $m, $s)
    }
}
# <<< CANONICAL unit_id=pwsh.helper.format-elapsed <<<
# >>> CANONICAL unit_id=pwsh.helper.get-phaseelapsedtag version=1.0.0 hash=79f7a70e60311a27 policy=canonical binding=follow-latest >>>
function Get-PhaseElapsedTag {
    # Returns elapsed-since-current-phase-start as '[+X.XXs]' or empty.
    if ($null -eq $Script:CurrentPhaseStart) { return '' }
    $span = (Get-Date) - $Script:CurrentPhaseStart
    return ('[+{0}]' -f (Format-Elapsed $span))
}
# <<< CANONICAL unit_id=pwsh.helper.get-phaseelapsedtag <<<
# >>> CANONICAL unit_id=pwsh.helper.logline version=1.0.0 hash=de5d6e6301d19d87 policy=canonical binding=follow-latest >>>
function _LogLine {
    # Internal: emits '[HH:mm:ss] [+X.XXs]   [marker] message'
    param([string]$Marker, [string]$Msg, [string]$Color)
    $ts  = Get-Date -Format 'HH:mm:ss'
    $tag = Get-PhaseElapsedTag
    if ($tag) {
        Write-Host ("[{0}] {1,-12} {2} {3}" -f $ts, $tag, $Marker, $Msg) -ForegroundColor $Color
    } else {
        Write-Host ("[{0}] {1,-12} {2} {3}" -f $ts, '', $Marker, $Msg) -ForegroundColor $Color
    }
}
# <<< CANONICAL unit_id=pwsh.helper.logline <<<
# >>> CANONICAL unit_id=pwsh.helper.write-step version=1.0.0 hash=257272636c6d4122 policy=canonical binding=follow-latest >>>
function Write-Step  { param($Msg) _LogLine '[*]' $Msg 'Cyan'     }
# <<< CANONICAL unit_id=pwsh.helper.write-step <<<
# >>> CANONICAL unit_id=pwsh.helper.write-ok version=1.0.0 hash=383749ef0ee509b4 policy=canonical binding=follow-latest >>>
function Write-Ok    { param($Msg) _LogLine '[+]' $Msg 'Green'    }
# <<< CANONICAL unit_id=pwsh.helper.write-ok <<<
function Write-Caution { param($Msg) _LogLine '[!]' $Msg 'Yellow'   }
# >>> CANONICAL unit_id=pwsh.helper.write-fail version=1.0.0 hash=13071c0f83f38048 policy=canonical binding=follow-latest >>>
function Write-Fail  { param($Msg) _LogLine '[X]' $Msg 'Red'      }
# <<< CANONICAL unit_id=pwsh.helper.write-fail <<<
# >>> CANONICAL unit_id=pwsh.helper.write-skip version=1.0.0 hash=1fc992418d41baad policy=canonical binding=follow-latest >>>
function Write-Skip  { param($Msg) _LogLine '[~]' $Msg 'DarkGray' }
# <<< CANONICAL unit_id=pwsh.helper.write-skip <<<

# >>> CANONICAL unit_id=pwsh.helper.write-detail version=1.0.0 hash=7fa6224e26175e15 policy=canonical binding=follow-latest >>>
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
# <<< CANONICAL unit_id=pwsh.helper.write-detail <<<

function Write-SubHeader {
    # In-phase Level-1 sub-banner (Cyan = x72). Used for major sections within
    # a phase (e.g. "NPU platform detection" / "Driver package resolution").
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Message)
    Write-Host ''
    Write-Host ('=' * 72) -ForegroundColor Cyan
    Write-Host (" $Message") -ForegroundColor Cyan
    Write-Host ('=' * 72) -ForegroundColor Cyan
}

function Write-SubHeader2 {
    # In-phase Level-2 sub-banner (DarkCyan - x72). Used for finer subsections
    # (e.g. "Section 1: Detected NPU on this host").
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Message)
    Write-Host ''
    Write-Host ('-' * 72) -ForegroundColor DarkCyan
    Write-Host (" $Message") -ForegroundColor DarkCyan
    Write-Host ('-' * 72) -ForegroundColor DarkCyan
}

function Write-PhaseHeader {
    # Prints a magenta banner that opens a phase. Records phase start
    # time so subsequent log lines can show '[+elapsed]'.
    #
    # Params:
    #   Id    : short identifier (e.g. 'P01', 'P06', etc; always two digits)
    #   Name  : human-readable phase name (e.g. 'Listing-Collection')
    #   Group : phase group (e.g. 'Setup', 'Scan', 'Fetch', 'Report')
    param(
        [Parameter(Mandatory)] [string]$Id,
        [Parameter(Mandatory)] [string]$Name,
        [Parameter(Mandatory)] [string]$Group
    )
    $Script:CurrentPhaseStart = Get-Date
    $Script:CurrentPhaseId    = $Id
    $startStr = $Script:CurrentPhaseStart.ToString('HH:mm:ss')
    $line = '=' * 72
    Write-Host ''
    Write-Host $line -ForegroundColor Magenta
    Write-Host (' PHASE {0,-4} - {1,-22} ({2,-7}) start: {3}' -f $Id, $Name, $Group, $startStr) -ForegroundColor Magenta
    Write-Host (' script: {0}' -f $Script:ScriptShortTag) -ForegroundColor DarkGray
    Write-Host $line -ForegroundColor Magenta
}
# >>> CANONICAL unit_id=pwsh.helper.write-phasefooter version=1.0.0 hash=762ec88efd33dc33 policy=canonical binding=follow-latest >>>
function Write-PhaseFooter {
    # Closes a phase started by Write-PhaseHeader. Records the elapsed
    # duration in $Script:PhaseTimings (used by run-summary helpers).
    #
    # Idempotent: a second call with the same Id is ignored, so wrapping
    # try/finally blocks do not double-count.
    #
    # Status values:
    #   done    - phase completed successfully
    #   cached  - phase was a no-op because the target state was already met
    #   skipped - phase was intentionally skipped (e.g. -OnlyPhases filter)
    #   failed  - phase threw an exception
    param(
        [Parameter(Mandatory)] [string]$Id,
        [Parameter(Mandatory)] [ValidateSet('done','cached','skipped','failed')] [string]$Status
    )
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

    Write-Host (' PHASE {0,-4} -> {1,-7}  elapsed: {2}' -f $Id, $Status.ToUpper(), $elapsedStr) -ForegroundColor $color

    # Reset so any stray Write-Step/Ok between phases doesn't show a
    # misleading [+X.XXs] tag inherited from the previous phase.
    $Script:CurrentPhaseStart = $null
    $Script:CurrentPhaseId    = $null
}
# <<< CANONICAL unit_id=pwsh.helper.write-phasefooter <<<
# =============================================================================
# Environment detection helpers
# =============================================================================
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

function Show-OperatingSystemDetail {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param()

    Write-SubHeader2 'Host operating system'

    $os    = Get-CimInstance Win32_OperatingSystem -ErrorAction Stop
    $build = [int]$os.BuildNumber
    $caption = $os.Caption
    $productType = [int]$os.ProductType  # 1=Workstation, 2=DC, 3=Server

    # Profile mapping based on NT build (chipset/graphics scripts share this matrix)
    $osProfile = $null
    $inf2cat = $null
    if ($build -ge 26100) {
        # Win11 24H2 and Server 2025 share build 26100
        $osProfile = 'WS2025'
        $inf2cat = 'Server2025_X64'
    } elseif ($build -ge 22631) {
        # Win11 23H2
        $osProfile = 'WS2022-equiv'
        $inf2cat = 'ServerFE_X64'
    } elseif ($build -ge 22000) {
        # Win11 21H2/22H2
        $osProfile = 'WS2022-equiv'
        $inf2cat = 'ServerFE_X64'
    } elseif ($build -ge 20348) {
        # Server 2022
        $osProfile = 'WS2022'
        $inf2cat = 'ServerFE_X64'
    } elseif ($build -ge 19041) {
        # Win10 20H2/21H2/22H2
        $osProfile = 'WS2019-equiv'
        $inf2cat = 'ServerRS5_X64'
    } elseif ($build -ge 17763) {
        # Server 2019
        $osProfile = 'WS2019'
        $inf2cat = 'ServerRS5_X64'
    } elseif ($build -ge 14393) {
        # Server 2016
        $osProfile = 'WS2016'
        $inf2cat = 'Server2016_X64'
    } else {
        $osProfile = 'Unknown'
        $inf2cat = $null
    }

    Write-Ok ("OS detected     : {0} (build {1})" -f $caption, $build)
    Write-Skip ("Profile applied : {0}" -f $osProfile)
    Write-Skip ("inf2cat /os: switch : {0}" -f $inf2cat)
    Write-Skip ("ProductType     : {0}  (1=Workstation, 3=Server)" -f $productType)

    $isWorkstation = ($productType -eq 1)
    $isServer2025  = ($productType -eq 3 -and $build -ge 26100)

    if ($isWorkstation -and $build -ge 26100) {
        # WS2025 PRE-MIGRATION PREVIEW MODE banner
        Write-Host ''
        Write-Host '    +-----------------------------------------------------------------+' -ForegroundColor Magenta
        Write-Host '    | WS2025 PRE-MIGRATION PREVIEW MODE                               |' -ForegroundColor Magenta
        Write-Host '    | (Windows 11 24H2 and Windows Server 2025 share NT build 26100)  |' -ForegroundColor Magenta
        Write-Host '    +-----------------------------------------------------------------+' -ForegroundColor Magenta
    }

    return @{
        OsCaption       = $caption
        OsBuild         = $build
        OsProductType   = $productType
        OsProfile       = $osProfile
        Inf2CatOsSwitch = $inf2cat
        IsWorkstationOs = $isWorkstation
        IsServer2025    = $isServer2025
    }
}

# >>> CANONICAL unit_id=pwsh.helper.assert-powershellcompatibility version=1.0.0 hash=cbe202e59516c121 policy=canonical binding=follow-latest >>>
function Assert-PowerShellCompatibility {
    <#
    .SYNOPSIS
        Hard-fail the script early when running on an unsupported host.

    .DESCRIPTION
        Refuses to proceed when:
          - PowerShell version is below 5.1, or
          - The current process is 32-bit.

        Both conditions are categorical incompatibilities (not soft
        warnings): the script's runspace-based concurrency, .NET regex
        Unicode escapes, and large-file handling have all been validated
        only on 5.1+ / 64-bit hosts. Running on a 32-bit host or a
        pre-5.1 engine will produce silent miscompilations or hangs
        rather than honest errors, so we stop here with a clear message.

        Throws a terminating error so the script exits with non-zero
        status; downstream phases never run.
    #>
    param()

    $pv    = $PSVersionTable.PSVersion
    $minPs = [Version]'5.1'
    if ($pv -lt $minPs) {
        throw @"
This script requires PowerShell $minPs or later.
Detected: $pv

This script targets the default PowerShell included with Windows 10 /
11 and Windows Server 2016 / 2019 / 2022 / 2025, which is
PowerShell 5.1. PowerShell 7+ is NOT required, but PowerShell 5.1 is
the minimum.

If you are on Windows 7 / Windows Server 2012 R2 or earlier, install
the Windows Management Framework 5.1 update: https://aka.ms/wmf51
"@
    }
    if (-not [Environment]::Is64BitProcess) {
        throw @'
This script requires a 64-bit PowerShell process. Detected 32-bit.

On a 64-bit Windows, launch from "Windows PowerShell" (NOT "Windows
PowerShell (x86)"). 32-bit hosts may hit issues with concurrent
runspace pools and large file path operations that have only been
validated under 64-bit PowerShell.
'@
    }
}
# <<< CANONICAL unit_id=pwsh.helper.assert-powershellcompatibility <<<

function Assert-Admin {
    # ---- Renamed from Test-AdminPrivilege; body aligned with the
    # canonical implementation in the sister scripts (Chipset / Graphics
    # / MSBthPan). The previous AMDNpu-specific implementation returned
    # $true and emitted Write-Ok / Write-Fail; the canonical version is
    # silent on success (throws on failure only), which is the convention
    # the rest of this script tree follows.
    $id   = [Security.Principal.WindowsIdentity]::GetCurrent()
    $prin = [Security.Principal.WindowsPrincipal]::new($id)
    if (-not $prin.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        throw 'This script must be run from an elevated PowerShell session.'
    }
}

# >>> CANONICAL unit_id=pwsh.helper.set-tlssecurityprotocol version=1.0.0 hash=137ffea3b2034e15 policy=canonical binding=follow-latest >>>
function Set-TlsSecurityProtocol {
    # ====================================================================
    # Enable TLS for outbound HTTPS calls with best-effort multi-version
    # fallback. Tls12 is the baseline (required by most modern endpoints
    # including AMD/Microsoft download servers and Speaker Deck CDN).
    # Tls13 is added when the running .NET supports it (Framework 4.8+,
    # PowerShell 7+, WS2022 / WS2025). Tls11 and Tls (1.0) are added as
    # a defensive fallback for very old environments (WS2016 / WS2019
    # with stock .NET); modern hosts will negotiate Tls13/Tls12 and the
    # legacy bits are ignored by the server. Each enum lookup is wrapped
    # in try/catch because older .NET runtimes raise an enum-value error
    # for protocols they don't recognise.
    # ====================================================================
    $protos = [Net.SecurityProtocolType]::Tls12
    try { $protos = $protos -bor [Net.SecurityProtocolType]::Tls13 } catch { } # psa-disable-line PSA3004 -- Tls13 enum may not exist on older .NET
    try { $protos = $protos -bor [Net.SecurityProtocolType]::Tls11 } catch { } # psa-disable-line PSA3004 -- defensive legacy fallback for very old environments
    try { $protos = $protos -bor [Net.SecurityProtocolType]::Tls   } catch { } # psa-disable-line PSA3004 -- defensive legacy fallback for very old environments
    [Net.ServicePointManager]::SecurityProtocol = $protos
}
# <<< CANONICAL unit_id=pwsh.helper.set-tlssecurityprotocol <<<
function Set-Utf8PipelineEncoding {
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

function Show-DriverInstallationOrderNotice {
    # ====================================================================
    # NPU-specific driver install order notice (compact + verbose).
    # ====================================================================
    # Ported the API surface (-Compact switch, two-mode output) from
    # the sister scripts (Chipset / Graphics / MSBthPan) so that the
    # canonical Show-PowerShellEnvironment body can call it without
    # adaptation. The CONTENT however is NPU-specific because the install
    # order story is different for NPU drivers: NPU does NOT depend on
    # chipset/graphics being preinstalled, but it DOES need the AMD
    # Ryzen AI Software user-mode stack to be installed SEPARATELY (and
    # AMD does not officially support that on Windows Server 2025).
    param([switch]$Compact)
    if ($Compact) {
        Write-Host ''
        Write-Host '  NOTE: NPU kernel-mode driver only. Ryzen AI Software (user-mode' -ForegroundColor Yellow
        Write-Host '        stack, Python/conda/ONNX runtime) is NOT installed by this' -ForegroundColor Yellow
        Write-Host '        script and is officially UNSUPPORTED on Windows Server 2025.' -ForegroundColor Yellow
        Write-Host '        This script is EXPERIMENTAL and unvalidated on physical NPU.' -ForegroundColor Yellow
        return
    }
    Write-Host ''
    Write-Host ' =====================================================================' -ForegroundColor Yellow
    Write-Host '  ABOUT THIS SCRIPT (AMD NPU kernel-mode driver, EXPERIMENTAL)'           -ForegroundColor Yellow
    Write-Host ' =====================================================================' -ForegroundColor Yellow
    Write-Host '  This script deploys ONLY the AMD NPU (Ryzen AI XDNA) kernel-mode driver'
    Write-Host '  (kipudrv.sys / amdxdna.inf). It does NOT install the Ryzen AI Software'
    Write-Host '  user-mode stack (Python/conda environments, ONNX runtime, VAI EP). Per'
    Write-Host '  AMD documentation (https://ryzenai.docs.amd.com/), Ryzen AI Software is'
    Write-Host '  officially supported on Windows 11 only; running it on Windows Server'
    Write-Host '  2025 is UNSUPPORTED by AMD and is the responsibility of the operator.'
    Write-Host ''
    Write-Host '  Pre-install workflow expected by this script:'
    Write-Host '      1. Confirm the NPU device is enumerated (PCI\VEN_1022&DEV_17F0 for'
    Write-Host '         Strix/Krackan, PCI\VEN_1022&DEV_1502 for Phoenix/Hawk Point).'
    Write-Host '         If absent, BIOS/UEFI may have the NPU disabled.'
    Write-Host '      2. THEN run this script. It patches amdxdna.inf for ProductType=3,'
    Write-Host '         signs a fresh catalog, and installs via pnputil.'
    Write-Host '      3. AFTERWARDS, install Ryzen AI Software separately if you need'
    Write-Host '         user-mode inference (out of scope here, and unsupported on Server).'
    Write-Host ''
}

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
function Get-AmdSuppPolicyMarkerPath {
    # The marker file persists the policy ID we deployed, so subsequent
    # script invocations can detect "is our supplemental already
    # installed" and find it for uninstall.
    param($Ctx)
    if ($Ctx -and $Ctx.Paths -and $Ctx.Paths.Cert) {
        return (Join-Path $Ctx.Paths.Cert 'AmdSuppPolicyId.txt')
    }
    return $null
}
function Test-AmdWdacPolicyDeployed {
    # Returns the deployed-policy info if our supplemental is currently
    # active, otherwise $null.
    #
    # Detection logic is now in two stages:
    #   Stage 1 (primary): look for the fixed $Script:WdacPolicyGuid
    #     among active CI policies. This works for any current deploy.
    #   Stage 2 (legacy fallback): if a earlier AmdSuppPolicyId.txt
    #     marker file exists in the workspace cert dir, also look for
    #     the dynamic GUID recorded there. This lets current scripts
    #     detect legacy deploys for clean removal.
    param($Ctx)
    $active = Get-ActiveCodeIntegrityPolicies

    # Stage 1: fixed GUID
    if ($Script:WdacPolicyGuid) {
        $fixedGuid = $Script:WdacPolicyGuid.Trim('{','}')
        $hit = $active | Where-Object {
            $_.PolicyId -and ($_.PolicyId.Trim('{','}') -ieq $fixedGuid)
        } | Select-Object -First 1
        if ($hit) { return $hit }
    }

    # Stage 2: legacy marker fallback
    $markerPath = Get-AmdSuppPolicyMarkerPath -Ctx $Ctx
    if (-not $markerPath -or -not (Test-Path $markerPath)) { return $null }
    $policyId = (Get-Content $markerPath -Raw -ErrorAction SilentlyContinue).Trim()
    if (-not $policyId) { return $null }
    $hit = $active | Where-Object { $_.PolicyId -eq $policyId } | Select-Object -First 1
    return $hit
}
function Uninstall-AmdWdacPolicy {
    # Remove a previously-deployed supplemental policy. Used by the
    # Cleanup action and by I02 when redeploying with -Force.
    #
    # --json flag suppresses CiTool's interactive ENTER prompt.
    param(
        [Parameter(Mandatory)] [string]$PolicyId
    )
    $activeDir = Join-Path $env:windir 'System32\CodeIntegrity\CiPolicies\Active'
    $deployedPath = Join-Path $activeDir "$PolicyId.cip"
    $existed = Test-Path $deployedPath

    if ($existed) {
        if (Get-Command CiTool.exe -ErrorAction SilentlyContinue) {
            try { & CiTool.exe --remove-policy $PolicyId --json 2>&1 | Out-Null } catch { } # psa-disable-line PSA3004 -- intentional best-effort cleanup; no error to surface
        }
        Remove-Item -LiteralPath $deployedPath -Force -ErrorAction SilentlyContinue
    }
    return [pscustomobject]@{
        PolicyId = $PolicyId
        Existed  = $existed
        Removed  = $existed -and -not (Test-Path $deployedPath)
    }
}

function Get-BootSigningEnvironment {
    # Every field is best-effort; failures are recorded rather than
    # thrown so the caller can decide what to do with partial data.
    $env = [pscustomobject]@{
        FirmwareType               = 'unknown'
        IsUefi                     = $false
        SecureBootEnabled          = $null   # $true / $false / $null=unknown
        SecureBootDetectError      = $null
        TestSigningEnabled         = $null
        TestSigningStateText       = 'unknown'
        BcdEnumRaw                 = $null
        BcdLoadOptions             = $null
        VbsRunning                 = $false
        VbsStatus                  = $null
        HvciRunning                = $false
        HvciAvailable              = $false
        MemoryIntegrityEnabled     = $false
        EffectiveCanLoadSelfSigned = $false
        BlockReasons               = @()
    }

    # Firmware Type (UEFI vs BIOS) via the kernel-set registry value
    # HKLM\SYSTEM\CurrentControlSet\Control\PEFirmwareType:
    #   1 = BIOS (Legacy)
    #   2 = UEFI
    try {
        $val = (Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control' `
                                 -Name 'PEFirmwareType' -ErrorAction Stop).PEFirmwareType
        switch ([int]$val) {
            1 { $env.FirmwareType = 'BIOS (legacy)'; $env.IsUefi = $false }
            2 { $env.FirmwareType = 'UEFI';          $env.IsUefi = $true  }
            default { $env.FirmwareType = "unknown ($val)" }
        }
    } catch {
        # Some constrained installs lack PEFirmwareType; fall back to
        # presence of EFI system partition.
        try {
            $efi = Get-CimInstance -ClassName Win32_DiskPartition -ErrorAction Stop |
                Where-Object Type -match 'GPT' | Select-Object -First 1
            if ($efi) { $env.FirmwareType = 'UEFI (inferred from GPT)'; $env.IsUefi = $true }
        } catch { } # psa-disable-line PSA3004 -- intentional best-effort cleanup; no error to surface
    }

    # Secure Boot (only meaningful on UEFI)
    if ($env.IsUefi) {
        try {
            # Confirm-SecureBootUEFI throws on:
            #   - non-UEFI systems (caller should not even ask)
            #   - non-elevated sessions
            #   - some virtualized environments (returns "Cmdlet not supported")
            $env.SecureBootEnabled = [bool](Confirm-SecureBootUEFI -ErrorAction Stop)
        } catch {
            $env.SecureBootDetectError = $_.Exception.Message
        }
    } else {
        # Legacy BIOS: Secure Boot is N/A and treated as 'off'
        $env.SecureBootEnabled = $false
    }

    # BCD testsigning state. We deliberately query via bcdedit (text)
    # rather than peeking at HKLM\BCD00000000 because the latter is
    # not stable across Windows versions.
    try {
        $bcdOutput = & bcdedit /enum '{current}' 2>&1 | Out-String
        $env.BcdEnumRaw = $bcdOutput
        if ($bcdOutput -match '(?im)^testsigning\s+(Yes|No)') {
            $env.TestSigningStateText = $matches[1]
            $env.TestSigningEnabled   = ($matches[1] -eq 'Yes')
        } else {
            # If the line is absent, the default is 'No'.
            $env.TestSigningStateText = 'No (default)'
            $env.TestSigningEnabled   = $false
        }
        if ($bcdOutput -match '(?im)^loadoptions\s+(.+)$') {
            $env.BcdLoadOptions = $matches[1].Trim()
        }
    } catch {
        # bcdedit failed - probably non-elevated; leave fields null.
    }

    # VBS / HVCI / Memory Integrity via Win32_DeviceGuard (Windows 10+
    # / Server 2016+). On older systems this WMI class is absent and
    # we treat all flags as off.
    try {
        $dg = Get-CimInstance -Namespace 'root\Microsoft\Windows\DeviceGuard' `
                              -ClassName 'Win32_DeviceGuard' -ErrorAction Stop
        # VirtualizationBasedSecurityStatus:
        #   0 = VBS not enabled
        #   1 = VBS enabled but not running
        #   2 = VBS enabled AND running
        $env.VbsStatus  = [int]$dg.VirtualizationBasedSecurityStatus
        $env.VbsRunning = ($env.VbsStatus -eq 2)
        # SecurityServicesRunning is an int[]; codes:
        #   1 = Credential Guard
        #   2 = HVCI / Memory Integrity (Hypervisor-protected Code Integrity)
        #   3 = System Guard Secure Launch
        #   4 = SMM Firmware Measurement
        #   5 = Vendor TPM
        $running    = @($dg.SecurityServicesRunning)
        $configured = @($dg.SecurityServicesConfigured)
        $env.HvciRunning   = ($running    -contains 2)
        $env.HvciAvailable = ($configured -contains 2)
        $env.MemoryIntegrityEnabled = $env.HvciRunning
    } catch {
        # No Win32_DeviceGuard - keep defaults (all off).
    }

    # WDAC custom CI policy state. Two pieces of info:
    #   1. Are the WDAC tools available? (we can deploy if yes)
    #   2. Is OUR self-signed-allowlist supplemental currently active?
    #      (= we already have the green light to load self-signed
    #      drivers WITH Secure Boot enabled).
    $env | Add-Member -MemberType NoteProperty -Name WdacToolsAvailable -Value $false      -Force
    $env | Add-Member -MemberType NoteProperty -Name WdacActivePolicies -Value @()         -Force
    $env | Add-Member -MemberType NoteProperty -Name WdacBaseEnforced   -Value $null       -Force
    $env | Add-Member -MemberType NoteProperty -Name AmdSuppPolicyActive -Value $false     -Force
    $env | Add-Member -MemberType NoteProperty -Name AmdSuppPolicyId    -Value $null       -Force
    try {
        $caps = Test-WdacToolsAvailable
        $env.WdacToolsAvailable = $caps.AnyUsable
        $active = Get-ActiveCodeIntegrityPolicies
        $env.WdacActivePolicies = $active
        $base = $active | Where-Object { -not $_.IsSupplemental } | Select-Object -First 1
        if ($base) {
            $env.WdacBaseEnforced = [bool]$base.IsEnforced
        }
        # Caller-side check: the marker file lives in the workspace
        # cert dir; we do NOT have $Ctx here, so we look for a cip
        # whose name appears in any of the active policies AND which
        # we previously saved as ours. If the caller cares about the
        # marker, they should call Test-AmdWdacPolicyDeployed -Ctx...
        # directly. Here we only set AmdSuppPolicyActive to $false.
    } catch {
        # WDAC inspection failed - leave defaults
    }

    # Compute effective "can a self-signed kernel-mode driver load?"
    # There are now TWO valid paths:
    #   PATH 1 (Secure Boot ON, recommended):
    #     Secure Boot ON
    #     WDAC supplemental policy with our cert deployed (AmdSuppPolicyActive=true)
    #   PATH 2 (Secure Boot OFF, legacy):
    #     Secure Boot off
    #     testsigning ON
    #     HVCI off
    # The caller (I02) decides which path to take based on the current
    # firmware state and -UseTestSigning override.
    $env.BlockReasons = @()
    $path1Open = ($env.AmdSuppPolicyActive -eq $true)
    $path2Open = ($env.SecureBootEnabled -ne $true) -and `
                 ($env.TestSigningEnabled -eq $true) -and `
                 (-not $env.HvciRunning)

    if (-not $path1Open) {
        $env.BlockReasons += 'No WDAC supplemental policy authorizes the AMD self-signing certificate'
    }
    if (-not $path2Open) {
        if ($env.SecureBootEnabled -eq $true) {
            $env.BlockReasons += 'Secure Boot is ON (legacy testsigning path requires Secure Boot off)'
        }
        if ($env.TestSigningEnabled -ne $true) {
            $env.BlockReasons += 'BCD testsigning is OFF (legacy path)'
        }
        if ($env.HvciRunning) {
            $env.BlockReasons += 'HVCI / Memory Integrity is RUNNING (legacy path requires HVCI off)'
        }
    }
    $env.EffectiveCanLoadSelfSigned = ($path1Open -or $path2Open)

    return $env
}

function Show-BootSigningEnvironment {
    # Pretty-print the boot-signing environment. Two modes:
    #   -Compact: one-line summary suitable for the startup banner
    #   (default): full table with notes column
    param(
        [Parameter(Mandatory)] $BootEnv,
        [switch]$Compact
    )

    function _FmtTri($v) {
        if ($null -eq $v) { return '?' }
        if ($v -eq $true)  { return 'ON' }
        return 'off'
    }
    function _FmtBool($v) {
        if ($v -eq $true) { return 'ON' } else { return 'off' }
    }

    if ($Compact) {
        $sb  = _FmtTri  $BootEnv.SecureBootEnabled
        $ts  = _FmtBool $BootEnv.TestSigningEnabled
        $hv  = _FmtBool $BootEnv.HvciRunning
        $wd  = _FmtBool $BootEnv.AmdSuppPolicyActive
        $eff = if ($BootEnv.EffectiveCanLoadSelfSigned) { 'ALLOWED' } else { 'BLOCKED' }
        $effColor = if ($BootEnv.EffectiveCanLoadSelfSigned) { 'Green' } else { 'Yellow' }
        Write-Host ('    Boot Signing        : Firmware={0,-14} SecureBoot={1,-3} TestSigning={2,-3} HVCI={3,-3} WDAC-AMD={4,-3}' -f `
            $BootEnv.FirmwareType, $sb, $ts, $hv, $wd)
        Write-Host ('    Self-signed driver  : {0}' -f $eff) -ForegroundColor $effColor
        return
    }

    # Verbose table
    Write-Host '    +------------------------+-----------+------------------------------------------------+'
    Write-Host '    | Setting                | Value     | Role for self-signed driver load               |'
    Write-Host '    +------------------------+-----------+------------------------------------------------+'
    $rows = @(
        @{ N='Firmware Type';         V=$BootEnv.FirmwareType;                  Note='UEFI = subject to Secure Boot policy'         },
        @{ N='Secure Boot';           V=(_FmtTri  $BootEnv.SecureBootEnabled);  Note='Can stay ON if WDAC supplemental is deployed' },
        @{ N='BCD testsigning';       V=(_FmtBool $BootEnv.TestSigningEnabled); Note='Legacy path only (requires Secure Boot off)'  },
        @{ N='VBS Running';           V=(_FmtBool $BootEnv.VbsRunning);         Note='Informational'                                 },
        @{ N='HVCI / Memory Intgr.';  V=(_FmtBool $BootEnv.HvciRunning);        Note='Compatible with WDAC supplemental path'       },
        @{ N='WDAC tools available';  V=(_FmtBool $BootEnv.WdacToolsAvailable); Note='ConfigCI module + CiTool.exe + AllowAll tmpl' },
        @{ N='WDAC supp (AMD cert)';  V=(_FmtBool $BootEnv.AmdSuppPolicyActive);Note='RECOMMENDED path: keeps Secure Boot ON'       }
    )
    foreach ($r in $rows) {
        Write-Host ('    | {0,-22} | {1,-9} | {2,-46} |' -f $r.N, $r.V, $r.Note)
    }
    Write-Host '    +------------------------+-----------+------------------------------------------------+'

    if ($BootEnv.EffectiveCanLoadSelfSigned) {
        $via = if ($BootEnv.AmdSuppPolicyActive) { 'WDAC supplemental policy (Secure Boot ON)' }
               else { 'legacy testsigning + Secure Boot off' }
        Write-Host  ('    EFFECTIVE: self-signed kernel-mode drivers CAN load (via {0}).' -f $via) -ForegroundColor Green
    } else {
        Write-Host  '    EFFECTIVE: self-signed kernel-mode drivers will NOT load.' -ForegroundColor Red
        foreach ($reason in $BootEnv.BlockReasons) {
            Write-Host ('      - {0}' -f $reason) -ForegroundColor Red
        }
    }
    if ($BootEnv.SecureBootDetectError) {
        Write-Host ('    Note: Secure Boot detection raised "{0}" - status may be unreliable.' -f $BootEnv.SecureBootDetectError) -ForegroundColor DarkYellow
    }
}

# =============================================================================
# Phase orchestrator
# =============================================================================
function Invoke-PhaseRunner { # psa-disable-line PSAP0001 -- Invoke-PhaseRunner is the phase dispatcher, not a phase itself; intentional name
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] $Ctx,
        [Parameter(Mandatory)][string[]]$PhaseIds
    )
    foreach ($id in $PhaseIds) {
        $phase = $Script:PhaseRegistry | Where-Object Id -EQ $id | Select-Object -First 1
        if (-not $phase) {
            Write-Fail ("Unknown phase ID: {0}" -f $id)
            throw "Unknown phase: $id"
        }

        # Sister-script-aligned: dispatcher renders the phase entry banner,
        # records phase-start time, and emits a phase-exit footer on both
        # success and failure paths. Phase functions stay focused on their
        # logic; banner/timing concerns are owned here.
        Write-PhaseHeader $phase.Id $phase.Name $phase.Group

        $start = Get-Date
        $errCaught = $null

        try {
            & $phase.Func -Ctx $Ctx
            $Script:PhaseResults[$id] = @{
                Status   = 'OK'
                Duration = ((Get-Date) - $start)
                Error    = $null
            }
            Write-PhaseFooter $phase.Id 'done'
        } catch {
            $errCaught = $_
            $Script:PhaseResults[$id] = @{
                Status   = 'FAIL'
                Duration = ((Get-Date) - $start)
                Error    = $errCaught
            }
            Write-Fail ("Phase {0} FAILED: {1}" -f $id, $errCaught.Exception.Message)
            Write-PhaseFooter $phase.Id 'failed'
            throw $errCaught
        }
    }
}

function Get-PhaseListByAction {
    [CmdletBinding()]
    [OutputType([string[]])]
    param([string]$Action)
    # Sister-script-aligned action -> phase mapping:
    #   Prepare: Prep only
    #   Verify: Verify only
    #   PrepareVerify: Prep + Verify (no system-state change)
    #   Install: Inst only (assumes Prep+Verify ran in a prior invocation
    #                   and patched artifacts are still on disk)
    #   All: Prep + Verify + Inst (full pipeline end-to-end)
    switch ($Action) {
        'PrepareVerify' {
            return ($Script:PhaseRegistry | Where-Object { $_.Group -eq 'Prep' -or $_.Group -eq 'Verify' } | Select-Object -ExpandProperty Id)
        }
        'Prepare' {
            return ($Script:PhaseRegistry | Where-Object Group -EQ 'Prep' | Select-Object -ExpandProperty Id)
        }
        'Verify' {
            return ($Script:PhaseRegistry | Where-Object Group -EQ 'Verify' | Select-Object -ExpandProperty Id)
        }
        'Install' {
            return ($Script:PhaseRegistry | Where-Object Group -EQ 'Inst' | Select-Object -ExpandProperty Id)
        }
        'All' {
            return ($Script:PhaseRegistry | Select-Object -ExpandProperty Id)
        }
        default {
            return @()
        }
    }
}

function Show-PhaseList {
    [CmdletBinding()]
    param()
    # Sister-script-aligned: column order ID -> Name -> Group -> Function,
    # Magenta header, '-' x 70 divider.
    Write-Host ''
    Write-Host ('Registered phases for {0} {1}:' -f $Script:ScriptName, $Script:ScriptVersion) -ForegroundColor Magenta
    Write-Host ('  {0,-5} {1,-30} {2,-6} {3}' -f 'ID','Name','Group','Function') -ForegroundColor Magenta
    Write-Host ('  {0}' -f ('-' * 70)) -ForegroundColor Magenta
    foreach ($p in $Script:PhaseRegistry) {
        Write-Host ('  {0,-5} {1,-30} {2,-6} {3}' -f $p.Id, $p.Name, $p.Group, $p.Func)
    }
    Write-Host ''
    Write-Skip 'Use -OnlyPhases <P05,P06,...> to run a subset.'
    Write-Skip "Use -Action <Prepare|Verify|PrepareVerify|Install|All|Cleanup> to choose a phase group."
}

# =============================================================================
# UEFI Secure Boot certificate baseline (port from chipset/graphics)
# =============================================================================
# These helpers capture and present the host's UEFI Secure Boot rollout
# state - separately from the OS-layer self-signing pipeline this script
# operates. See the chipset / graphics scripts for the full design rationale.
# The 6 core functions below are byte-identical to those scripts; only the
# Get-OrEnsureSecureBootBaseline helper at the end of the block is NPU-
# specific (NPU keeps state on $Script:DetectedPlatform rather than $Ctx).

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

# >>> CANONICAL unit_id=pwsh.helper.debugtrace-nextseq version=1.0.0 hash=40affbda93e0dc92 policy=canonical binding=follow-latest >>>
function _DebugTrace_NextSeq {
    # Atomic-ish counter. Single-threaded PowerShell so no Interlocked
    # needed; this is just a small helper for readability.
    $Script:DebugTraceEventSeq++
    return $Script:DebugTraceEventSeq
}
# <<< CANONICAL unit_id=pwsh.helper.debugtrace-nextseq <<<

# >>> CANONICAL unit_id=pwsh.helper.debugtrace-now version=1.0.0 hash=6cef1239adbe85aa policy=canonical binding=follow-latest >>>
function _DebugTrace_Now {
    # Return current time as ISO 8601 string with milliseconds and Z
    # suffix. Pre-converted to string so ConvertTo-Json doesn't render
    # the PS 5.1 legacy /Date(N)/ format - we want the same machine-
    # readable representation regardless of PS version.
    return (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
}
# <<< CANONICAL unit_id=pwsh.helper.debugtrace-now <<<

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

# >>> CANONICAL unit_id=pwsh.helper.debugtrace-retireframe version=1.0.0 hash=d6ed295961b4416e policy=canonical binding=follow-latest >>>
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
# <<< CANONICAL unit_id=pwsh.helper.debugtrace-retireframe <<<

# --- 1b.3: Public API - trace primitives ------------------------------

function Start-DebugTrace {
    <#
    .SYNOPSIS
        Push a new debug trace frame onto the stack. Call at function
        entry.
    .PARAMETER Context
        Human-readable name for this frame, typically the function name
        or 'phase.PNN.<Name>' for phase-level frames.
    .PARAMETER Echo
        If set, every Set-DebugStep call also writes a live [trace] line
        to the console. Default off.
    .PARAMETER PhaseId
        Optional phase identifier (e.g. 'P05'). When set, the frame is
        registered in the per-phase trace registry so Export-DebugTraceJson
        can build a per-phase summary.
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

# >>> CANONICAL unit_id=pwsh.helper.set-debugstep version=1.0.0 hash=0ff66497b3b281c8 policy=canonical binding=follow-latest >>>
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
# <<< CANONICAL unit_id=pwsh.helper.set-debugstep <<<

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

# >>> CANONICAL unit_id=pwsh.helper.format-debugfailure version=1.0.0 hash=0ed20da6d346d5b8 policy=canonical binding=follow-latest >>>
function Format-DebugFailure {
    <#
    .SYNOPSIS
        Build a structured failure report from an ErrorRecord plus the
        currently-active trace frame. Use when you need the failure
        data programmatically (e.g. relay it elsewhere).
    .PARAMETER ErrorRecord
        The $_ inside a catch block.
    .OUTPUTS
        pscustomobject with: Context, FailedStep, Elapsed, ElapsedMs,
        PhaseId, ExType, ExMessage, InnerType, InnerMessage,
        FullyQualifiedId, ScriptStackTrace, StepHistory (object[]).
    #>
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param([Parameter(Mandatory)] $ErrorRecord)
    $ex = $ErrorRecord.Exception
    if ($Script:DebugTraceStack.Count -gt 0) {
        $frame       = $Script:DebugTraceStack.Peek()
        $context     = $frame.Context
        $failedStep  = $frame.Step
        # PS 5.1 ja-JP bug workaround: use .ToArray(), not @($list).
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
        Context          = $context
        FailedStep       = $failedStep
        Elapsed          = $elapsed
        ElapsedMs        = [int]$elapsed.TotalMilliseconds
        PhaseId          = $phaseId
        ExType           = $ex.GetType().FullName
        ExMessage        = $ex.Message
        InnerType        = if ($ex.InnerException) { $ex.InnerException.GetType().FullName } else { $null }
        InnerMessage     = if ($ex.InnerException) { $ex.InnerException.Message } else { $null }
        FullyQualifiedId = $ErrorRecord.FullyQualifiedErrorId
        ScriptStackTrace = $ErrorRecord.ScriptStackTrace
        StepHistory      = $stepHistory
    }
}
# <<< CANONICAL unit_id=pwsh.helper.format-debugfailure <<<

# >>> CANONICAL unit_id=pwsh.helper.write-debugfailurereport version=1.0.0 hash=8c1dda9940c309c1 policy=canonical binding=follow-latest >>>
function Write-DebugFailureReport {
    <#
    .SYNOPSIS
        Emit a formatted failure report via Write-Caution + log the
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

    Write-Caution ("{0}: FAILED at step '{1}' (elapsed {2:F2}s)" -f $r.Context, $r.FailedStep, $r.Elapsed.TotalSeconds)
    Write-Caution ("  ExType   : {0}" -f $r.ExType)
    Write-Caution ("  Message  : {0}" -f $r.ExMessage)
    if ($r.InnerType) {
        Write-Caution ("  Inner    : {0} - {1}" -f $r.InnerType, $r.InnerMessage)
    }
    if ($r.FullyQualifiedId) {
        Write-Caution ("  FQErrId  : {0}" -f $r.FullyQualifiedId)
    }
    if ($r.ScriptStackTrace) {
        $stackLines = $r.ScriptStackTrace -split "`r?`n"
        Write-Caution ("  Stack    : {0}" -f $stackLines[0])
        $maxStack = [Math]::Min(3, $stackLines.Count)
        for ($i = 1; $i -lt $maxStack; $i++) {
            Write-Caution ("             {0}" -f $stackLines[$i])
        }
    }
    if ($IncludeStepHistory -and $r.StepHistory.Count -gt 0) {
        Write-Caution ("  Steps    : {0} recorded" -f $r.StepHistory.Count)
        $firstAt = $r.StepHistory[0].At
        foreach ($h in $r.StepHistory) {
            $rel = ($h.At - $firstAt).TotalMilliseconds
            Write-Caution ('    +{0,7:F0}ms  {1}' -f $rel, $h.Step)
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
            Write-Caution ("  TraceJson: {0}" -f $exportPath)
        } catch {
            # Don't let auto-export failures hide the original error.
            Write-Caution ("  TraceJson: auto-export failed: {0}" -f $_.Exception.Message)
        }
    }
}
# <<< CANONICAL unit_id=pwsh.helper.write-debugfailurereport <<<

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

# >>> CANONICAL unit_id=pwsh.helper.disable-debugtracefileoutput version=1.0.0 hash=0dc4d90f4368280a policy=canonical binding=follow-latest >>>
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
# <<< CANONICAL unit_id=pwsh.helper.disable-debugtracefileoutput <<<

# >>> CANONICAL unit_id=pwsh.helper.get-debugtracefileoutputstatus version=1.0.0 hash=e03887fcc4e39fd3 policy=canonical binding=follow-latest >>>
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
# <<< CANONICAL unit_id=pwsh.helper.get-debugtracefileoutputstatus <<<

# --- 1b.5: Public API - JSON Export (Feature B) -----------------------

# >>> CANONICAL unit_id=pwsh.helper.enable-autoexportonphasefailure version=1.0.0 hash=81f2415bbc83f281 policy=canonical binding=follow-latest >>>
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
# <<< CANONICAL unit_id=pwsh.helper.enable-autoexportonphasefailure <<<

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

function Get-SecureBootBaselineSnapshot {
    # Top-level entry point. Returns a unified snapshot combining the
    # embedded inventory (always present) and the Microsoft sample
    # script output (when available). Adds an overall Health
    # classification used by the report and the I02 pre-check.
    #
    # Health classification:
    #   'Healthy' - Secure Boot ON, UEFICA2023Status=Updated (or not
    #                applicable), no UEFICA2023Error, no servicing error
    #                events captured by the MS script.
    #   'Warning' - Secure Boot ON but UEFI CA 2023 rollout is still
    #                in flight, OR scheduled task disabled, OR the MS
    #                script reports error events (1795/1796/1802/1803).
    #   'Critical' - Secure Boot OFF (with this script's WDAC path that
    #                normally requires Secure Boot ON), OR UEFICA2023Error
    #                non-zero indicating a stuck rollout.
    #   'Unknown' - Could not collect Secure Boot state at all (non-UEFI
    #                host, or Confirm-SecureBootUEFI cmdlet unavailable).
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [string]$WorkRoot
    )

    $emb = Get-SecureBootCertificateInventory

    $msInfo = Get-MsSecureBootExampleScriptPath
    $ms = $null
    if ($msInfo.Present) {
        $ms = Invoke-MsSecureBootDetectScript -WorkRoot $WorkRoot -DetectScriptPath $msInfo.DetectScript
    }

    # Compute health
    $health = 'Unknown'
    $reasons = New-Object System.Collections.Generic.List[string]
    if ($null -eq $emb.SecureBootEnabled) {
        $health = 'Unknown'
        $reasons.Add('Secure Boot state could not be determined.') | Out-Null
    } elseif ($emb.SecureBootEnabled -eq $false) {
        $health = 'Warning'   # not Critical: testsigning path still works on SB-OFF hosts
        $reasons.Add('Secure Boot is OFF in firmware - WDAC supplemental policy is unnecessary; legacy testsigning would apply.') | Out-Null
    } else {
        # Secure Boot ON - cert rollover progress matters
        $health = 'Healthy'
        if ($emb.UEFICA2023Status -and ($emb.UEFICA2023Status -ne 'Updated')) {
            $health = 'Warning'
            $reasons.Add("UEFI CA 2023 status: $($emb.UEFICA2023Status) (rollout not yet complete).") | Out-Null
        }
        if ($emb.UEFICA2023Error -and ($emb.UEFICA2023Error -ne 0)) {
            $health = 'Critical'
            $reasons.Add("UEFI CA 2023 error code recorded: $($emb.UEFICA2023Error).") | Out-Null
        }
        if ($emb.FirstPartyDB2023Updated -eq 0 -or $emb.FirstPartyKEK2023Updated -eq 0) {
            if ($health -eq 'Healthy') { $health = 'Warning' }
            $reasons.Add('First-party Secure Boot certs (UEFI CA 2023 / KEK 2K CA 2023) not yet present in firmware variables.') | Out-Null
        }
        if (($null -ne $emb.SecureBootTaskEnabled) -and ($emb.SecureBootTaskEnabled -eq $false)) {
            if ($health -eq 'Healthy') { $health = 'Warning' }
            $reasons.Add('Scheduled task \Microsoft\Windows\PI\Secure-Boot-Update is disabled or not ready.') | Out-Null
        }
    }
    # MS-script signals further refine the health
    if ($ms -and $ms.Available -and $ms.Data) {
        $d = $ms.Data
        foreach ($f in 'Event1795Count','Event1796Count','Event1802Count','Event1803Count') {
            $v = $d.$f
            if ($v -and ([int]$v -gt 0)) {
                if ($health -eq 'Healthy') { $health = 'Warning' }
                $reasons.Add("Microsoft sample script reports $f = $v.") | Out-Null
            }
        }
        if ($d.Confidence -and ($d.Confidence -match '(?i)Action Req')) {
            if ($health -eq 'Healthy') { $health = 'Warning' }
            $reasons.Add("Microsoft sample script reports Confidence = $($d.Confidence).") | Out-Null
        }
    }

    [pscustomobject]@{
        Generated  = (Get-Date)
        WorkRoot   = $WorkRoot
        MsInfo     = $msInfo
        Embedded   = $emb
        Microsoft  = $ms
        Health     = $health
        # PS 5.1 ja-JP latent bug guard: when `Reasons` (a hashtable
        # value here) is later cast to [pscustomobject] downstream,
        # `@($list)` over a Generic.List[T] has been observed to raise
        # System.ArgumentException in ja-JP locale builds (originally
        # localised in the BthPan Invoke-InfVerifValidation
        # investigation; see SPEC §D entry for the full post-mortem).
        # .ToArray() materialises eagerly to string[] and side-steps
        # the issue at near-zero cost; applied uniformly across all
        # four sister scripts.
        Reasons    = $reasons.ToArray()
    }
}

function Show-SecureBootBaselineSnapshot {
    # Renders a baseline snapshot in this script's standard log style.
    # -Compact prints a 3-line summary suitable for P00 / I02 banners.
    # Without -Compact, prints a full section with cert / registry /
    # task / Microsoft-script details for V05 / V06.
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] $Snapshot,
        [switch]$Compact
    )

    if (-not $Snapshot) { return }
    $emb = $Snapshot.Embedded
    $ms  = $Snapshot.Microsoft
    $health = $Snapshot.Health
    $healthColor = switch ($health) {
        'Healthy'  { 'Green'   }
        'Warning'  { 'Yellow'  }
        'Critical' { 'Red'     }
        default    { 'DarkGray' }
    }

    if ($Compact) {
        $sb = if ($null -eq $emb.SecureBootEnabled) { 'unknown' } else { ($emb.SecureBootEnabled.ToString().ToLower()) }
        $u2023 = if ($emb.UEFICA2023Status) { $emb.UEFICA2023Status } else { 'n/a' }
        $msTag = if ($ms -and $ms.Available) { 'MS-sample=ok' }
                 elseif ($Snapshot.MsInfo.Present) { 'MS-sample=present(err)' }
                 else { 'MS-sample=absent' }
        Write-Detail ("Secure Boot baseline: enabled={0,-5} UEFI-CA-2023={1,-12} health={2,-8} [{3}]" -f $sb, $u2023, $health, $msTag) -Color $healthColor
        return
    }

    # Non-compact mode: caller is responsible for printing the section
    # banner (V06 prefixes the section with its own '--- 4. UEFI Secure
    # Boot Baseline ---' header for numbering consistency with sections
    # 1-3 above it). We print only the body to avoid the duplicate
    # banner that was visible in early releases.
    Write-Host ("  Overall health     : {0}" -f $health) -ForegroundColor $healthColor
    foreach ($r in $Snapshot.Reasons) {
        Write-Detail ("- {0}" -f $r) -Color $healthColor
    }
    Write-Host ''
    Write-Host '  [Embedded inventory]'
    Write-Detail ("Secure Boot enabled              : {0}" -f $(if ($null -eq $emb.SecureBootEnabled) { 'unknown' } else { $emb.SecureBootEnabled }))
    if ($emb.SecureBootDetectError) {
        Write-Detail ("  Detect error: {0}" -f $emb.SecureBootDetectError) -Color DarkGray
    }
    Write-Detail ("Windows UEFI CA 2023 (db, 1P)    : {0}" -f $(if ($null -eq $emb.FirstPartyDB2023Updated)  { 'n/a' } elseif ($emb.FirstPartyDB2023Updated  -eq 1) { 'present'    } else { 'NOT present' }))
    Write-Detail ("Microsoft KEK 2K CA 2023 (KEK,1P): {0}" -f $(if ($null -eq $emb.FirstPartyKEK2023Updated) { 'n/a' } elseif ($emb.FirstPartyKEK2023Updated -eq 1) { 'present'    } else { 'NOT present' }))
    Write-Detail ("Microsoft UEFI CA 2011 (db, 3P)  : {0}" -f $(if ($null -eq $emb.ThirdParty2011CAPresent)  { 'n/a' } elseif ($emb.ThirdParty2011CAPresent  -eq 1) { 'present (3P trusted)' } else { 'not present (1P-only trust)' }))
    if ($emb.ThirdParty2023CertsRequired -eq 1) {
        Write-Detail ("Microsoft UEFI CA 2023 (db, 3P)        : {0}" -f $(if ($null -eq $emb.ThirdParty2023CertUpdated)          { 'n/a' } elseif ($emb.ThirdParty2023CertUpdated          -eq 1) { 'present' } else { 'NOT present' }))
        Write-Detail ("Microsoft Option ROM UEFI CA 2023 (3P) : {0}" -f $(if ($null -eq $emb.ThirdPartyOptionRom2023CertUpdated) { 'n/a' } elseif ($emb.ThirdPartyOptionRom2023CertUpdated -eq 1) { 'present' } else { 'NOT present' }))
    }
    Write-Detail ("UEFI CA 2023 status (registry)         : {0}" -f $(if ($emb.UEFICA2023Status)     { $emb.UEFICA2023Status     } else { 'n/a' }))
    if ($emb.UEFICA2023Error) {
        Write-Detail ("UEFI CA 2023 error code                : {0}" -f $emb.UEFICA2023Error) -Color Yellow
    }
    Write-Detail ("AvailableUpdates / Policy              : {0} / {1}" -f $(if ($emb.AvailableUpdatesHex)       { $emb.AvailableUpdatesHex       } else { 'n/a' }), $(if ($emb.AvailableUpdatesPolicyHex) { $emb.AvailableUpdatesPolicyHex } else { 'n/a' }))
    Write-Detail ("Secure-Boot-Update scheduled task      : {0}" -f $(
        if (-not $emb.SecureBootTaskExists) { 'task not present' }
        elseif ($null -eq $emb.SecureBootTaskEnabled) { "state=$($emb.SecureBootTaskStatus) (enabled-check skipped)" }
        elseif ($emb.SecureBootTaskEnabled) { "Ready/Running (state=$($emb.SecureBootTaskStatus))" }
        else { "Not running (state=$($emb.SecureBootTaskStatus))" }
    ))
    if ($emb.CanAttemptUpdateAfter) {
        Write-Detail ("CanAttemptUpdateAfter (UTC)            : {0}" -f $emb.CanAttemptUpdateAfter) -Color DarkGray
    }
    Write-Host ''
    Write-Host '  [Microsoft sample script (KB5089549+ delivery)]'
    if (-not $Snapshot.MsInfo.Present) {
        Write-Host '    Not deployed on this host.' -ForegroundColor DarkGray
        Write-Detail ("(Expected path: {0})" -f $Snapshot.MsInfo.RootPath) -Color DarkGray
        Write-Host '    Embedded inventory above is the sole source.' -ForegroundColor DarkGray
    } elseif (-not $ms -or -not $ms.Available) {
        Write-Host ('    Script present but invocation failed.') -ForegroundColor Yellow
        if ($ms -and $ms.ErrorMessage) {
            Write-Detail ("  Reason: {0}" -f $ms.ErrorMessage) -Color Yellow
        }
    } else {
        $d = $ms.Data
        Write-Host ('    Script invoked successfully.') -ForegroundColor Green
        Write-Detail ("Script path  : {0}" -f $ms.ScriptPath) -Color DarkGray
        Write-Detail ("JSON path    : {0}" -f $ms.JsonPath) -Color DarkGray
        Write-Detail ("BucketId     : {0}" -f $(if ($d.BucketId) { $d.BucketId } else { 'n/a' }))
        Write-Detail ("Confidence   : {0}" -f $(if ($d.Confidence) { $d.Confidence } else { 'n/a' }))
        if ($d.SkipReasonKnownIssue) {
            Write-Detail ("SkipReason   : {0}" -f $d.SkipReasonKnownIssue) -Color Yellow
        }
        if ($d.KnownIssueId) {
            Write-Detail ("KnownIssueId : {0}" -f $d.KnownIssueId) -Color Yellow
        }
        $evtFields = @('Event1801Count','Event1808Count','Event1795Count','Event1796Count','Event1800Count','Event1802Count','Event1803Count')
        $evtParts = foreach ($f in $evtFields) {
            $v = $d.$f
            if ($v -and ([int]$v -gt 0)) { ("{0}={1}" -f ($f -replace 'Count$',''), $v) }
        }
        if ($evtParts) {
            Write-Detail ("Events       : {0}" -f ($evtParts -join '  '))
        }
        if ($d.MissingKEK) {
            Write-Host '    MissingKEK   : TRUE (OEM needs to supply PK-signed KEK)' -ForegroundColor Yellow
        }
        if ($d.RebootPending) {
            Write-Host '    RebootPending: TRUE (Event 1800 was observed)' -ForegroundColor Cyan
        }
    }
    Write-Host ''
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

function Get-OrEnsureSecureBootBaseline {
    # Idempotent accessor for the cached Secure Boot baseline.
    # Returns $Ctx.SecureBootBaseline when it is still valid; otherwise
    # re-invokes Get-SecureBootBaselineSnapshot into the current
    # $Ctx.WorkRoot so the diagnostic files (detect_stdout.log,
    # detect_stdout_extracted.json) are co-located with the workspace.
    #
    # A cached snapshot is considered VALID when one of the following
    # holds:
    #   - The MS sample script was not available on this host, so
    #     there is no diagnostic file to keep in sync (MsInfo.JsonPath
    #     is $null). The in-memory data is the sole source of truth.
    #   - MsInfo.JsonPath references a file that still exists AND that
    #     file lives under the current $Ctx.WorkRoot tree.
    #
    # The cache becomes INVALID when:
    #   - P01 wiped the workspace under -CleanWorkRoot, deleting a
    #     JSON file that P00 had written to the workspace.
    #   - An earlier release's P00 had written the JSON to %TEMP%
    # and we are now reading the snapshot
    #     from a phase that displays the path.
    # In either case we re-capture so the displayed path is honest.
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)] $Ctx
    )

    $needCapture = $true
    if ($Ctx.SecureBootBaseline) {
        $cached = $Ctx.SecureBootBaseline
        $jsonPath = $null
        try { $jsonPath = $cached.MsInfo.JsonPath } catch { } # psa-disable-line PSA3004 -- intentional best-effort cleanup; no error to surface
        if (-not $jsonPath) {
            # MS sample script not present or did not produce a JSON
            # path - nothing to keep co-located. Cached snapshot is fine.
            $needCapture = $false
        } elseif ($Ctx.WorkRoot -and ($jsonPath -like "$($Ctx.WorkRoot)*") -and (Test-Path -LiteralPath $jsonPath)) {
            # JSON file is under the workspace and still exists.
            $needCapture = $false
        }
    }

    if ($needCapture) {
        try {
            $Ctx.SecureBootBaseline = Get-SecureBootBaselineSnapshot -WorkRoot $Ctx.WorkRoot
        } catch {
            Write-Caution ("Secure Boot baseline (re-)capture failed: {0}" -f $_.Exception.Message)
        }
    }

    return $Ctx.SecureBootBaseline
}

# =============================================================================
# AMD NPU platform detection (P03 helper)
# =============================================================================
function Get-AmdNpuPlatform {
    <#
    .SYNOPSIS
        Detects the AMD NPU codename (PHX/HPT/STX/KRK) using PCI HWID enumeration.
    .DESCRIPTION
        Translates the AMD-published Python detection logic from quicktest.py
        (https://ryzenai.docs.amd.com/en/latest/inst.html) to PowerShell.

        Uses pnputil /enum-devices /bus PCI /deviceids to get raw HWIDs, then
        regex-matches against known NPU patterns. Phoenix and Hawk Point share
        DEV_1502&REV_00, so CPU name disambiguates them.
    #>
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [string]$Override,
        [switch]$AssumeIfMissing,
        # NPU driver package selection (independent from Ryzen AI Software version)
        [string]$NpuDriverPackageSelection = 'latest',
        # Ryzen AI Software version selection (independent from NPU driver)
        [string]$RyzenAiSoftwareVersionSelection = 'latest'
    )

    $detected = @{
        NpuCodename             = $null
        NpuShortName            = $null
        HardwareId              = $null
        Revision                = $null
        IsDetected              = $false
        DetectionSource         = $null
        # ----- NPU kernel-mode driver fields (independent from RAI Software) -----
        NpuDriverPackage         = $null
        NpuDriverBuild           = $null
        NpuDriverZipName         = $null
        # ----- Ryzen AI Software fields (independent from NPU driver) -----
        RyzenAiSoftwareVersion   = $null
        RyzenAiSoftwareInstaller = $null
        # ----- Compatibility evaluation (driver <-> software) -----
        DriverSoftwareCompatible = $null
        DriverSoftwareCompatNote = $null
        CpuName                 = $null
        RawDeviceIds            = $null
    }

    # Get CPU name first (needed for PHX/HPT disambiguation)
    try {
        $cpu = (Get-CimInstance Win32_Processor -ErrorAction Stop | Select-Object -First 1).Name
        $detected.CpuName = $cpu
    } catch {
        Write-Caution ("Could not read Win32_Processor.Name: {0}" -f $_.Exception.Message)
        $cpu = ''
    }

    # Manual override path
    if ($Override) {
        Write-Caution ("NPU override active: {0} (auto-detection skipped)" -f $Override)
        $detected.NpuShortName = $Override
        $detected.DetectionSource = 'override'
        switch ($Override) {
            'PHX' {
                $detected.NpuCodename = 'Phoenix'
                $detected.HardwareId = 'PCI\VEN_1022&DEV_1502&REV_00'
                $detected.Revision   = 'REV_00'
            }
            'HPT' {
                $detected.NpuCodename = 'Hawk Point'
                $detected.HardwareId = 'PCI\VEN_1022&DEV_1502&REV_00'
                $detected.Revision   = 'REV_00'
            }
            'STX' {
                $detected.NpuCodename = 'Strix Point / Strix Halo'
                $detected.HardwareId = 'PCI\VEN_1022&DEV_17F0&REV_00'
                $detected.Revision   = 'REV_00'
            }
            'KRK' {
                $detected.NpuCodename = 'Krackan Point'
                $detected.HardwareId = 'PCI\VEN_1022&DEV_17F0&REV_20'
                $detected.Revision   = 'REV_20'
            }
        }
        $detected.IsDetected = $true
        # Populate NPU driver fields (driver versioning - INDEPENDENT axis)
        $pkgInfo = Get-NpuDriverPackageInfo -PackageSelection $NpuDriverPackageSelection
        $detected.NpuDriverPackage  = $pkgInfo.PackageId
        $detected.NpuDriverBuild    = $pkgInfo.DriverBuild
        $detected.NpuDriverZipName  = $pkgInfo.ZipFilename
        # Populate Ryzen AI Software fields (software versioning - INDEPENDENT axis)
        $swInfo = Get-LatestRyzenAiSoftwareInfo -VersionSelection $RyzenAiSoftwareVersionSelection
        $detected.RyzenAiSoftwareVersion   = $swInfo.ResolvedVersion
        $detected.RyzenAiSoftwareInstaller = $swInfo.InstallerFilename
        # Populate compatibility evaluation (separate axis)
        $compat = Test-NpuDriverRaiCompatibility -NpuDriverBuild $pkgInfo.DriverBuild -RyzenAiSoftwareVersion $swInfo.ResolvedVersion
        $detected.DriverSoftwareCompatible = $compat.IsCompatible
        $detected.DriverSoftwareCompatNote = $compat.Note
        return $detected
    }

    # Run pnputil for PCI device enumeration
    Write-Step 'Enumerating PCI devices via pnputil /enum-devices /bus PCI /deviceids'
    $pnpOutput = $null
    try {
        $pnpOutput = (& pnputil.exe /enum-devices /bus PCI /deviceids 2>&1) -join "`n"
        $detected.RawDeviceIds = $pnpOutput
    } catch {
        Write-Caution ("pnputil enumeration failed: {0}" -f $_.Exception.Message)
        $pnpOutput = ''
    }

    # Pattern match - PHX/HPT (DEV_1502)
    if ($pnpOutput -match 'PCI\\VEN_1022&DEV_1502&REV_00') {
        if ($cpu -match '7\d40\b|PRO\s+7\d40\b|7840|7640|7940|7740') {
            $detected.NpuCodename = 'Phoenix'
            $detected.NpuShortName = 'PHX'
        } elseif ($cpu -match '8\d40\b|PRO\s+8\d40\b|8840|8640|8945|8845|8845HS') {
            $detected.NpuCodename = 'Hawk Point'
            $detected.NpuShortName = 'HPT'
        } else {
            # Ambiguous - default to PHX (older silicon, conservative)
            $detected.NpuCodename = 'Phoenix or Hawk Point (ambiguous, assumed PHX)'
            $detected.NpuShortName = 'PHX'
        }
        $detected.HardwareId = 'PCI\VEN_1022&DEV_1502&REV_00'
        $detected.Revision   = 'REV_00'
        $detected.IsDetected = $true
        $detected.DetectionSource = 'pnputil'
    }
    # Pattern match - STX (DEV_17F0&REV_00/10/11)
    elseif ($pnpOutput -match 'PCI\\VEN_1022&DEV_17F0&REV_(00|10|11)') {
        $rev = $Matches[1]
        $detected.NpuCodename = 'Strix Point / Strix Halo'
        $detected.NpuShortName = 'STX'
        $detected.HardwareId   = "PCI\VEN_1022&DEV_17F0&REV_$rev"
        $detected.Revision     = "REV_$rev"
        $detected.IsDetected   = $true
        $detected.DetectionSource = 'pnputil'
    }
    # Pattern match - KRK (DEV_17F0&REV_20)
    elseif ($pnpOutput -match 'PCI\\VEN_1022&DEV_17F0&REV_20') {
        $detected.NpuCodename = 'Krackan Point'
        $detected.NpuShortName = 'KRK'
        $detected.HardwareId   = 'PCI\VEN_1022&DEV_17F0&REV_20'
        $detected.Revision     = 'REV_20'
        $detected.IsDetected   = $true
        $detected.DetectionSource = 'pnputil'
    }
    elseif ($AssumeIfMissing) {
        # Default - Strix Point + latest documented NPU driver + latest RAI Software
        Write-Caution 'No AMD NPU detected via pnputil. Using default profile (Strix Point + NPU driver 32.0.203.314 + RAI Software latest).'
        $detected.NpuCodename     = 'Strix Point (default - no NPU detected)'
        $detected.NpuShortName    = 'STX'
        $detected.HardwareId      = 'PCI\VEN_1022&DEV_17F0&REV_00'
        $detected.Revision        = 'REV_00'
        $detected.DetectionSource = 'default-strix-driver314-rai-latest'
        # IsDetected stays false to trigger downstream warning banners
    } else {
        Write-Fail 'No AMD NPU detected and -AssumeIfMissing was not specified.'
        Write-Skip 'Pass -AssumeIfMissing to proceed with the default Strix Point profile,'
        Write-Skip 'or pass -NpuOverride <PHX|HPT|STX|KRK> to force a specific platform.'
        throw 'AMD NPU not detected; cannot proceed.'
    }

    # Populate NPU driver fields (kernel driver versioning - INDEPENDENT axis)
    $pkgInfo = Get-NpuDriverPackageInfo -PackageSelection $NpuDriverPackageSelection
    $detected.NpuDriverPackage = $pkgInfo.PackageId
    $detected.NpuDriverBuild   = $pkgInfo.DriverBuild
    $detected.NpuDriverZipName = $pkgInfo.ZipFilename

    # Populate Ryzen AI Software fields (user-mode stack versioning - INDEPENDENT axis,
    # always recommend latest unless explicitly pinned by operator)
    $swInfo = Get-LatestRyzenAiSoftwareInfo -VersionSelection $RyzenAiSoftwareVersionSelection
    $detected.RyzenAiSoftwareVersion   = $swInfo.ResolvedVersion
    $detected.RyzenAiSoftwareInstaller = $swInfo.InstallerFilename

    # Populate compatibility evaluation (driver <-> software, SEPARATE axis from version)
    $compat = Test-NpuDriverRaiCompatibility -NpuDriverBuild $pkgInfo.DriverBuild -RyzenAiSoftwareVersion $swInfo.ResolvedVersion
    $detected.DriverSoftwareCompatible = $compat.IsCompatible
    $detected.DriverSoftwareCompatNote = $compat.Note

    return $detected
}

function Get-NpuDriverPackageInfo {
    <#
    .SYNOPSIS
        Returns NPU kernel-mode driver package metadata. Selection is based ONLY on the
        operator-supplied -NpuDriverPackage value (or 'latest'). NOT correlated with
        Ryzen AI Software version.
    .DESCRIPTION
        AMD publishes two NPU driver ZIPs on account.amd.com (verified 2026-05-10 against
        https://ryzenai.docs.amd.com/en/latest/inst.html, last updated 2026-04-19):

          NPU_RAI1.5_280     -> driver build 32.0.203.280 (older, all NPU codenames supported)
          NPU_RAI1.6.1_314   -> driver build 32.0.203.314 (newer, all NPU codenames supported)

        These are the ONLY NPU driver ZIPs documented in AMD's Ryzen AI install instructions.
        The version label "RAI1.5" / "RAI1.6.1" in the ZIP filename is a historical naming
        artefact — both ZIPs work with current Ryzen AI Software (1.7.1).

        AMD's own guidance is "Download and Install the NPU driver version: 32.0.203.280 or
        newer" — i.e. either ZIP is acceptable; pick the newer one (314) for new installs.

        If a future RAI release publishes a new ZIP (e.g. NPU_RAI1.8_400_WHQL.zip), update
        this function and the parameter ValidateSet on -NpuDriverPackage.
    .OUTPUTS
        Hashtable with: PackageId, DriverBuild, ZipFilename, EulaUrl, NpuCoverage, ReleaseDate
    #>
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('NPU_RAI1.5_280', 'NPU_RAI1.6.1_314', 'latest')]
        [string]$PackageSelection
    )

    $catalog = @{
        'NPU_RAI1.5_280' = @{
            PackageId    = 'NPU_RAI1.5_280'
            DriverBuild  = '32.0.203.280'
            ZipFilename  = 'NPU_RAI1.5_280_WHQL.zip'
            EulaUrl      = 'https://account.amd.com/en/forms/downloads/ryzenai-eula-public-xef.html?filename=NPU_RAI1.5_280_WHQL.zip'
            NpuCoverage  = @('PHX', 'HPT', 'STX', 'STH', 'KRK')
            ReleaseDate  = '2025-05-16'
            Status       = 'older — production driver per AMD docs'
        }
        'NPU_RAI1.6.1_314' = @{
            PackageId    = 'NPU_RAI1.6.1_314'
            DriverBuild  = '32.0.203.314'
            ZipFilename  = 'NPU_RAI1.6.1_314_WHQL.zip'
            EulaUrl      = 'https://account.amd.com/en/forms/downloads/ryzenai-eula-public-xef.html?filename=NPU_RAI1.6.1_314_WHQL.zip'
            NpuCoverage  = @('PHX', 'HPT', 'STX', 'STH', 'KRK')
            ReleaseDate  = '2025 (post-1.6.1 release)'
            Status       = 'newer — recommended for new installs'
        }
    }

    if ($PackageSelection -eq 'latest') {
        # 'latest' resolves to the newest documented package
        return $catalog['NPU_RAI1.6.1_314']
    }
    if ($catalog.ContainsKey($PackageSelection)) {
        return $catalog[$PackageSelection]
    }
    # Should be unreachable due to ValidateSet, but defend anyway
    throw ("Unknown NPU driver package selection: {0}" -f $PackageSelection)
}

function Get-LatestRyzenAiSoftwareInfo {
    <#
    .SYNOPSIS
        Returns metadata about the Ryzen AI Software (user-mode stack) for a given version
        or 'latest'. Independent from NPU kernel driver versioning.
    .DESCRIPTION
        Ryzen AI Software is the user-mode runtime (Python conda environment, ONNX Runtime
        VitisAI EP, OnnxRuntime GenAI/OGA, Vitis AI Quantizer, etc). Its versioning is
        completely separate from the NPU kernel driver — installing RAI Software 1.7.1 does
        NOT update the NPU driver, and updating the NPU driver does NOT update RAI Software.

        AMD's recommendation for RAI Software is "always use the latest" because it ships
        new model support, performance improvements, and bug fixes for end-user inference
        workloads. By contrast, the NPU kernel driver is updated less often and only when
        a new firmware/driver pair is released.

        Source of truth: https://ryzenai.docs.amd.com/en/latest/inst.html (currently 1.7.1).

        When AMD publishes a new RAI release (1.7.2, 1.8, etc.), update the catalog below.
    .OUTPUTS
        Hashtable with: Version, InstallerFilename, InstallerEulaUrl, NuGetFilename,
        NuGetEulaUrl, DefaultInstallPath, DefaultCondaEnv, IsLatest, ReleaseNotesUrl
    #>
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('1.5', '1.6.1', '1.7', '1.7.1', 'latest')]
        [string]$VersionSelection
    )

    $latestVersion = '1.7.1'  # update when AMD publishes a new RAI release

    $catalog = @{
        '1.5' = @{
            Version            = '1.5'
            InstallerFilename  = 'ryzen-ai-1.5.0.exe'
            DefaultInstallPath = 'C:\Program Files\RyzenAI\1.5.0'
            DefaultCondaEnv    = 'ryzen-ai-1.5.0'
        }
        '1.6.1' = @{
            Version            = '1.6.1'
            InstallerFilename  = 'ryzen-ai-1.6.1.exe'
            DefaultInstallPath = 'C:\Program Files\RyzenAI\1.6.1'
            DefaultCondaEnv    = 'ryzen-ai-1.6.1'
        }
        '1.7' = @{
            Version            = '1.7'
            InstallerFilename  = 'ryzen-ai-lt-1.7.0.exe'
            DefaultInstallPath = 'C:\Program Files\RyzenAI\1.7.0'
            DefaultCondaEnv    = 'ryzen-ai-1.7.0'
        }
        '1.7.1' = @{
            Version            = '1.7.1'
            InstallerFilename  = 'ryzen-ai-lt-1.7.1.exe'
            NuGetFilename      = '1.7.1_nuget_signed.zip'
            DefaultInstallPath = 'C:\Program Files\RyzenAI\1.7.1'
            DefaultCondaEnv    = 'ryzen-ai-1.7.1'
        }
    }

    $resolveVersion = if ($VersionSelection -eq 'latest') { $latestVersion } else { $VersionSelection }
    if (-not $catalog.ContainsKey($resolveVersion)) {
        throw ("Unknown Ryzen AI Software version: {0}" -f $resolveVersion)
    }

    $info = $catalog[$resolveVersion]
    # Augment with derived fields
    $info['InstallerEulaUrl'] = ('https://account.amd.com/en/forms/downloads/xef.html?filename={0}' -f $info['InstallerFilename'])
    if ($info.ContainsKey('NuGetFilename')) {
        $info['NuGetEulaUrl']  = ('https://account.amd.com/en/forms/downloads/xef.html?filename={0}' -f $info['NuGetFilename'])
    }
    $info['IsLatest']         = ($resolveVersion -eq $latestVersion)
    $info['ResolvedVersion']  = $resolveVersion
    $info['ReleaseNotesUrl']  = ('https://ryzenai.docs.amd.com/en/{0}/relnotes.html' -f $resolveVersion)

    return $info
}

function Test-NpuDriverRaiCompatibility {
    <#
    .SYNOPSIS
        Evaluates whether a given NPU kernel-mode driver build is compatible with a given
        Ryzen AI Software version. This is a SEPARATE evaluation axis from version selection.
    .DESCRIPTION
        AMD's compatibility statement is documented per Ryzen AI Software release. As of
        AMD docs 2026-04-19 (RAI 1.7.1):

            "Download and Install the NPU driver version: 32.0.203.280 or newer"

        Therefore, for RAI 1.7.1, both 32.0.203.280 and 32.0.203.314 are compatible.
        For older RAI releases (1.6.1 and earlier), the same driver minimum applies in
        practice; AMD does not publish a different minimum.

        The compatibility matrix below is conservative — it only allows combinations that
        AMD explicitly documents. Future releases may tighten or relax these rules; check
        the AMD release notes for the target RAI version.
    .OUTPUTS
        Hashtable with: IsCompatible (bool), Note (string), MinimumDriverBuild, ReferenceUrl
    #>
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory)][string]$NpuDriverBuild,
        [Parameter(Mandatory)][string]$RyzenAiSoftwareVersion
    )

    # Per AMD docs, the minimum driver requirement is the same across all current RAI
    # releases. If AMD documents a new minimum in a future release, add an entry here.
    $minimumPerRai = @{
        '1.5'   = '32.0.203.280'
        '1.6.1' = '32.0.203.280'
        '1.7'   = '32.0.203.280'
        '1.7.1' = '32.0.203.280'
    }

    if (-not $minimumPerRai.ContainsKey($RyzenAiSoftwareVersion)) {
        return @{
            IsCompatible       = $false
            Note               = ("Unknown RAI Software version '{0}'; cannot evaluate compatibility." -f $RyzenAiSoftwareVersion)
            MinimumDriverBuild = $null
            ReferenceUrl       = 'https://ryzenai.docs.amd.com/en/latest/inst.html'
        }
    }

    $minimum = $minimumPerRai[$RyzenAiSoftwareVersion]
    # Compare driver build numbers as 4-part System.Version
    try {
        $current = [version]$NpuDriverBuild
        $minVer  = [version]$minimum
        $isOk    = $current -ge $minVer
    } catch {
        return @{
            IsCompatible       = $false
            Note               = ("Could not parse driver build '{0}' as a version." -f $NpuDriverBuild)
            MinimumDriverBuild = $minimum
            ReferenceUrl       = ('https://ryzenai.docs.amd.com/en/{0}/inst.html' -f $RyzenAiSoftwareVersion)
        }
    }

    if ($isOk) {
        return @{
            IsCompatible       = $true
            Note               = ("Driver {0} satisfies the minimum requirement ({1}) for Ryzen AI Software {2}." -f $NpuDriverBuild, $minimum, $RyzenAiSoftwareVersion)
            MinimumDriverBuild = $minimum
            ReferenceUrl       = ('https://ryzenai.docs.amd.com/en/{0}/inst.html' -f $RyzenAiSoftwareVersion)
        }
    } else {
        return @{
            IsCompatible       = $false
            Note               = ("Driver {0} is older than the minimum required ({1}) for Ryzen AI Software {2}. Install a newer driver." -f $NpuDriverBuild, $minimum, $RyzenAiSoftwareVersion)
            MinimumDriverBuild = $minimum
            ReferenceUrl       = ('https://ryzenai.docs.amd.com/en/{0}/inst.html' -f $RyzenAiSoftwareVersion)
        }
    }
}
# =============================================================================
# NPU driver URL resolution & download (P03 implementation)
# 4-tier fallback strategy:
#   Tier 1: -InstallerUrl explicit URL (highest priority)
#   Tier 2: -AmdAccountUser/-AmdAccountPassword auto-download via account.amd.com
#   Tier 3: AMD EULA-gated direct fetch probe (typically fails but kept for future-proofing)
#   Tier 4: -OfflineZip or local cache (script-sibling.zip, $WorkRoot\download\*.zip)
# =============================================================================

function Resolve-AmdNpuDriverUrl {
    <#
    .SYNOPSIS
        Resolves the NPU driver ZIP source using the 4-tier fallback strategy.
    .OUTPUTS
        Hashtable with:
          - SourceType: 'ExplicitUrl' | 'AmdAuthenticated' | 'EulaGatedDirect' | 'LocalCache'
          - LocalPath  : path to a downloaded or pre-existing ZIP on disk
          - SourceUrl  : the URL that was fetched (or null for LocalCache)
    #>
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory)] $Ctx,
        [Parameter(Mandatory)][hashtable]$NpuPlatform,
        [string]$ExplicitInstallerUrl,
        [string]$ExplicitOfflineZip,
        [string]$AmdAccountUser = '',
        [System.Security.SecureString]$AmdAccountPassword
    )

    # NPU driver ZIP filename comes directly from the resolved package metadata.
    # NpuDriverZipName is populated in Get-AmdNpuPlatform via Get-NpuDriverPackageInfo
    # (independent of Ryzen AI Software version).
    if ([string]::IsNullOrEmpty($NpuPlatform.NpuDriverZipName)) {
        throw 'Resolve-AmdNpuDriverUrl: NpuPlatform.NpuDriverZipName is empty; Get-AmdNpuPlatform was not called or produced an incomplete result.'
    }
    $expectedZipName = $NpuPlatform.NpuDriverZipName

    $downloadDir = $Ctx.DownloadDir
    if (-not (Test-Path $downloadDir)) {
        New-Item -Path $downloadDir -ItemType Directory -Force | Out-Null
    }

    # ------------------------------------------------------------------------
    # Tier 1: -InstallerUrl explicit URL
    # ------------------------------------------------------------------------
    if (-not [string]::IsNullOrEmpty($ExplicitInstallerUrl)) {
        Write-SubHeader 'Tier 1: Explicit -InstallerUrl provided'
        Write-Step ("Source URL: {0}" -f $ExplicitInstallerUrl)
        $localZipPath = Join-Path $downloadDir $expectedZipName
        try {
            $result = Invoke-NpuZipDownload -Url $ExplicitInstallerUrl -OutFile $localZipPath
            if ($result) {
                return @{
                    SourceType = 'ExplicitUrl'
                    LocalPath  = $localZipPath
                    SourceUrl  = $ExplicitInstallerUrl
                }
            }
        } catch {
            Write-Fail ("Tier 1 download failed: {0}" -f $_.Exception.Message)
        }
        Write-Caution 'Tier 1 failed. Falling through to next tier.'
    }

    # ------------------------------------------------------------------------
    # Tier 4 (priority before Tier 2/3): -OfflineZip path
    # ------------------------------------------------------------------------
    if (-not [string]::IsNullOrEmpty($ExplicitOfflineZip)) {
        Write-SubHeader 'Tier 4 (offline): -OfflineZip provided'
        if (Test-Path $ExplicitOfflineZip) {
            Write-Ok ("Using offline ZIP: {0}" -f $ExplicitOfflineZip)
            $cachedPath = Join-Path $downloadDir (Split-Path $ExplicitOfflineZip -Leaf)
            try {
                Copy-Item -Path $ExplicitOfflineZip -Destination $cachedPath -Force
            } catch {
                # If copy fails (same file etc), use original
                $cachedPath = $ExplicitOfflineZip
            }
            return @{
                SourceType = 'LocalCache'
                LocalPath  = $cachedPath
                SourceUrl  = $null
            }
        } else {
            Write-Fail ("Specified -OfflineZip path does not exist: {0}" -f $ExplicitOfflineZip)
        }
    }

    # ------------------------------------------------------------------------
    # Tier 2: AMD account auto-download (if credentials provided)
    # ------------------------------------------------------------------------
    if (-not [string]::IsNullOrEmpty($AmdAccountUser) -and $AmdAccountPassword) {
        Write-SubHeader 'Tier 2: AMD account auto-download'
        Write-Step ("Account user: {0}" -f $AmdAccountUser)
        Write-Caution 'NOTE: Tier 2 attempts to authenticate against account.amd.com,'
        Write-Caution '      accept the Ryzen AI EULA, and fetch the ZIP via dynamic URL.'
        Write-Caution '      AMD periodically changes form layouts; if this fails, use Tier 1 or 4.'
        try {
            $authResult = Invoke-AmdAccountAuthentication -Ctx $Ctx `
                -Username $AmdAccountUser `
                -Password $AmdAccountPassword `
                -DriverFilename $expectedZipName

            if ($authResult -and $authResult.DownloadUrl) {
                $localZipPath = Join-Path $downloadDir $expectedZipName
                Write-Ok ("Resolved authenticated download URL")
                $result = Invoke-NpuZipDownload `
                    -Url $authResult.DownloadUrl `
                    -OutFile $localZipPath `
                    -WebSession $authResult.Session
                if ($result) {
                    return @{
                        SourceType = 'AmdAuthenticated'
                        LocalPath  = $localZipPath
                        SourceUrl  = $authResult.DownloadUrl
                    }
                }
            }
        } catch {
            Write-Fail ("Tier 2 authenticated download failed: {0}" -f $_.Exception.Message)
        }
        Write-Caution 'Tier 2 failed. Falling through to next tier.'
    }

    # ------------------------------------------------------------------------
    # Tier 3: AMD EULA-gated direct fetch probe
    # ------------------------------------------------------------------------
    Write-SubHeader 'Tier 3: AMD EULA-gated direct fetch probe'
    $eulaUrl = "https://account.amd.com/en/forms/downloads/ryzenai-eula-public-xef.html?filename=$expectedZipName"
    Write-Step ("Probing: {0}" -f $eulaUrl)
    Write-Skip 'NOTE: This URL is normally a HTML form page that requires JS-driven submission.'
    Write-Skip '      The probe will likely receive HTML rather than ZIP bytes; falls through.'

    try {
        $head = Invoke-WebRequest -Uri $eulaUrl -Method Head -UseBasicParsing -TimeoutSec 15 -ErrorAction Stop
        $contentType = $head.Headers['Content-Type']
        if ($contentType -match 'application/(zip|octet-stream)') {
            Write-Ok ("EULA-gated URL responded with Content-Type: {0}" -f $contentType)
            $localZipPath = Join-Path $downloadDir $expectedZipName
            $dl = Invoke-NpuZipDownload -Url $eulaUrl -OutFile $localZipPath
            if ($dl) {
                return @{
                    SourceType = 'EulaGatedDirect'
                    LocalPath  = $localZipPath
                    SourceUrl  = $eulaUrl
                }
            }
        } else {
            Write-Skip ("Probe Content-Type: {0} (not a ZIP, expected behaviour)" -f $contentType)
        }
    } catch {
        Write-Skip ("Probe failed (expected for EULA-gated form): {0}" -f $_.Exception.Message)
    }

    # ------------------------------------------------------------------------
    # Tier 4 fallback: scan for sibling ZIP files
    # ------------------------------------------------------------------------
    Write-SubHeader 'Tier 4 (auto-scan): looking for local ZIP cache'

    $searchPaths = @(
        $PSScriptRoot,                                                # script directory
        (Join-Path $PSScriptRoot 'cache'),                            # ./cache subdirectory
        $downloadDir,                                                 # workspace download dir
        (Join-Path $env:USERPROFILE 'Downloads')                      # user Downloads
    ) | Where-Object { -not [string]::IsNullOrEmpty($_) -and (Test-Path $_) } | Select-Object -Unique

    foreach ($searchPath in $searchPaths) {
        Write-Skip ("Scanning: {0}" -f $searchPath)

        # First preference: exact filename match
        $exactMatch = Get-ChildItem -Path $searchPath -Filter $expectedZipName -File -ErrorAction SilentlyContinue
        if ($exactMatch) {
            Write-Ok ("Found exact match: {0}" -f $exactMatch.FullName)
            $localZipPath = Join-Path $downloadDir $expectedZipName
            try {
                if ($exactMatch.FullName -ne $localZipPath) {
                    Copy-Item -Path $exactMatch.FullName -Destination $localZipPath -Force
                }
            } catch {
                $localZipPath = $exactMatch.FullName
            }
            return @{
                SourceType = 'LocalCache'
                LocalPath  = $localZipPath
                SourceUrl  = $null
            }
        }

        # Second preference: any NPU_RAI*_WHQL.zip
        $patternMatch = Get-ChildItem -Path $searchPath -Filter 'NPU_RAI*_WHQL.zip' -File -ErrorAction SilentlyContinue |
            Sort-Object LastWriteTime -Descending |
            Select-Object -First 1
        if ($patternMatch) {
            Write-Ok ("Found pattern match (newest): {0}" -f $patternMatch.FullName)
            Write-Caution ("Note: filename does not match expected '{0}' for current platform." -f $expectedZipName)
            Write-Caution '      Verify the version is compatible with your NPU codename before proceeding.'
            $localZipPath = Join-Path $downloadDir $patternMatch.Name
            try {
                if ($patternMatch.FullName -ne $localZipPath) {
                    Copy-Item -Path $patternMatch.FullName -Destination $localZipPath -Force
                }
            } catch {
                $localZipPath = $patternMatch.FullName
            }
            return @{
                SourceType = 'LocalCache'
                LocalPath  = $localZipPath
                SourceUrl  = $null
            }
        }
    }

    # ------------------------------------------------------------------------
    # All tiers exhausted
    # ------------------------------------------------------------------------
    Write-Fail 'All 4 download tiers exhausted; no NPU driver ZIP could be obtained.'
    Write-Host ''
    Write-Caution 'How to obtain the NPU driver ZIP manually:'
    Write-Host ''
    Write-Host '  1. Visit AMD Ryzen AI installation guide:' -ForegroundColor White
    Write-Host '     https://ryzenai.docs.amd.com/en/latest/inst.html#install-npu-drivers' -ForegroundColor Cyan
    Write-Host ''
    Write-Host '  2. Click the link for your target Ryzen AI version (e.g. NPU Driver 32.0.203.314):' -ForegroundColor White
    Write-Host ('     {0}' -f "https://account.amd.com/en/forms/downloads/ryzenai-eula-public-xef.html?filename=$expectedZipName") -ForegroundColor Cyan
    Write-Host ''
    Write-Host '  3. Sign in to your AMD account, accept the Ryzen AI EULA, and download.' -ForegroundColor White
    Write-Host ''
    Write-Host '  4. Re-run this script with one of:' -ForegroundColor White
    Write-Host ("     -OfflineZip <path>  (e.g. -OfflineZip .\{0})" -f $expectedZipName) -ForegroundColor Cyan
    Write-Host '     -InstallerUrl <url> (the dynamically-generated download URL after EULA accept)' -ForegroundColor Cyan
    Write-Host '     -AmdAccountUser <email> -AmdAccountPassword <SecureString>' -ForegroundColor Cyan
    Write-Host ''
    throw 'NPU driver ZIP could not be located via any tier.'
}

function Invoke-NpuZipDownload {
    <#
    .SYNOPSIS
        Downloads a ZIP from a URL with progress reporting and basic content-type validation.
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)][string]$Url,
        [Parameter(Mandatory)][string]$OutFile,
        [Microsoft.PowerShell.Commands.WebRequestSession]$WebSession
    )

    Write-Step ("Downloading: {0}" -f $Url)
    Write-Skip ("Output file: {0}" -f $OutFile)

    # Force fresh download
    if (Test-Path $OutFile) {
        Remove-Item $OutFile -Force
    }

    $start = Get-Date
    try {
        $iwrParams = @{
            Uri             = $Url
            OutFile         = $OutFile
            UseBasicParsing = $true
            TimeoutSec      = 600
            ErrorAction     = 'Stop'
        }
        if ($WebSession) {
            $iwrParams.WebSession = $WebSession
        }
        Invoke-WebRequest @iwrParams
    } catch {
        Write-Fail ("Download failed: {0}" -f $_.Exception.Message)
        return $false
    }

    if (-not (Test-Path $OutFile)) {
        Write-Fail 'Download completed but file is missing.'
        return $false
    }

    $size = (Get-Item $OutFile).Length
    if ($size -lt 1MB) {
        Write-Caution ("Downloaded file is suspiciously small: {0} bytes" -f $size)
        Write-Skip 'Inspecting first 256 bytes for HTML/error content...'
        $head = [System.IO.File]::ReadAllBytes($OutFile) | Select-Object -First 256
        $headText = -join ($head | ForEach-Object { [char]$_ })
        if ($headText -match '(?i)<html|<!DOCTYPE') {
            Write-Fail 'Downloaded content appears to be HTML rather than ZIP bytes.'
            Write-Fail 'This typically means EULA acceptance is required (use Tier 2 or 4).'
            Remove-Item $OutFile -Force -ErrorAction SilentlyContinue
            return $false
        }
    }

    # Verify ZIP magic bytes (PK\x03\x04)
    $bytes = New-Object byte[] 4
    $fs = [System.IO.File]::OpenRead($OutFile)
    try {
        $null = $fs.Read($bytes, 0, 4)
    } finally {
        $fs.Close()
    }
    if (-not ($bytes[0] -eq 0x50 -and $bytes[1] -eq 0x4B)) {
        Write-Fail 'Downloaded file is not a valid ZIP (missing PK magic bytes).'
        Remove-Item $OutFile -Force -ErrorAction SilentlyContinue
        return $false
    }

    $duration = ((Get-Date) - $start).TotalSeconds
    $sizeMB = [Math]::Round($size / 1MB, 2)
    $rateMBps = if ($duration -gt 0) { [Math]::Round($sizeMB / $duration, 2) } else { 0 }
    Write-Ok ("Downloaded {0} MB in {1:n1}s ({2} MB/s)" -f $sizeMB, $duration, $rateMBps)
    return $true
}

function Invoke-AmdAccountAuthentication {
    <#
    .SYNOPSIS
        Attempts to authenticate against account.amd.com and return a download session for the
        specified Ryzen AI driver ZIP.
    .DESCRIPTION
        AMD's download flow is a multi-step HTML form sequence:
          1. POST credentials to login endpoint, receive session cookies
          2. GET the EULA acceptance form for the target filename
          3. POST EULA acceptance to receive a time-limited dynamic download URL
          4. Optionally follow Location header / poll for download readiness

        VERIFICATION RESULT (2026-05-10):
        Public-facing pages on account.amd.com / docs.amd.com return HTML payloads that
        require JavaScript to render and submit forms (consistent with Salesforce
        Lightning / SPA architecture). Direct PowerShell HTTP form POST is therefore
        unlikely to succeed for the following reasons:

          * Login forms are likely XHR-driven; CSRF tokens are dynamically injected
            by JS and not present in the initial HTML response.
          * Session state may include JS-managed bearer tokens or specific Origin/
            Referer headers that PowerShell's WebRequestSession does not replicate.
          * Multi-step OAuth/SAML redirects may be involved between login.html and
            forms/downloads/ (no public documentation of the back-end auth provider).
          * EULA acceptance for Ryzen AI is interactive ("sign the Beta Software EULA"
            per AMD Ryzen AI on-boarding documentation and end-user reports).

        End-user evidence:
          * github.com/amd/RyzenAI-SW#249 confirms AMD account login is required
          * github.com/amd/RyzenAI-SW#328 confirms users still hit interactive forms
          * No publicly available PowerShell/Python implementation has been found
            that drives this flow successfully.

        IMPLEMENTATION DECISION:
        This function is retained as a best-effort fallback only. It will print an
        explicit "verification result" banner and return $null without attempting
        the request unless -ForceAmdAccountAuth is set. The default code path is
        Tier 4 (-OfflineZip) per the verified-working pattern in TESTING.md §3.3.

        If AMD changes their account portal to expose an HTTP-form-friendly endpoint
        in the future, remove the early-return below and re-enable the form posts.
    .OUTPUTS
        Hashtable with keys: DownloadUrl (string), Session (WebRequestSession), or $null on failure.
    #>
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory)] $Ctx,
        [Parameter(Mandatory)][string]$Username,
        [Parameter(Mandatory)][System.Security.SecureString]$Password,
        [Parameter(Mandatory)][string]$DriverFilename
    )

    Write-Step 'Initiating AMD account authentication flow...'
    Write-Caution '------------------------------------------------------------'
    Write-Caution 'VERIFIED 2026-05-10: account.amd.com is a JavaScript-driven SPA.'
    Write-Caution 'PowerShell HTTP form POST is highly unlikely to succeed against'
    Write-Caution 'this back-end. Tier 4 (-OfflineZip) is the recommended path.'
    Write-Caution '------------------------------------------------------------'

    if (-not $Ctx.ForceAmdAccountAuth) {
        Write-Fail 'Tier 2 (AMD account auto-download) is disabled by default since 2026-05-10.'
        Write-Skip 'Pass -ForceAmdAccountAuth to attempt anyway (best-effort, expected to fail).'
        Write-Skip 'Recommended: download the ZIP manually and use -OfflineZip <path>.'
        return $null
    }

    Write-Caution '-ForceAmdAccountAuth specified; attempting form-based auth (will likely fail).'

    # Convert SecureString -> plaintext (necessary for HTTP form post)
    $cred = New-Object System.Net.NetworkCredential('', $Password)
    $plainPassword = $cred.Password

    # Step 1: Establish a web session and visit the public EULA page
    $eulaUrl = "https://account.amd.com/en/forms/downloads/ryzenai-eula-public-xef.html?filename=$DriverFilename"
    $loginUrl = 'https://account.amd.com/en/forms/auth/login.html'
    $session = New-Object Microsoft.PowerShell.Commands.WebRequestSession
    $session.UserAgent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0 Safari/537.36'

    try {
        Write-Skip ("Step 1: GET {0}" -f $eulaUrl)
        $eulaPage = Invoke-WebRequest -Uri $eulaUrl `
            -WebSession $session `
            -UseBasicParsing `
            -TimeoutSec 30 `
            -ErrorAction Stop

        Write-Skip ("EULA page returned {0} bytes, HTTP {1}" -f $eulaPage.RawContentLength, $eulaPage.StatusCode)

        # Look for login form action / hidden CSRF tokens
        $csrfMatch = [regex]::Match($eulaPage.Content, 'name="(?:_csrf|csrf_token|authenticity_token)"\s+value="([^"]+)"')
        $csrfToken = if ($csrfMatch.Success) { $csrfMatch.Groups[1].Value } else { $null }

        if ($csrfToken) {
            Write-Skip 'CSRF token discovered (length redacted)'
        } else {
            Write-Skip 'No CSRF token in EULA page; proceeding without one'
        }
    } catch {
        Write-Caution ("Step 1 failed: {0}" -f $_.Exception.Message)
        return $null
    }

    # Step 2: POST credentials to login endpoint
    try {
        Write-Skip ("Step 2: POST credentials to {0}" -f $loginUrl)
        $loginBody = @{
            'email'      = $Username
            'password'   = $plainPassword
            'rememberMe' = 'false'
        }
        if ($csrfToken) {
            $loginBody['_csrf'] = $csrfToken
        }

        $loginResp = Invoke-WebRequest -Uri $loginUrl `
            -Method Post `
            -Body $loginBody `
            -WebSession $session `
            -UseBasicParsing `
            -TimeoutSec 30 `
            -ErrorAction Stop

        # Check for typical login failure markers
        if ($loginResp.Content -match '(?i)invalid (?:email|password|credentials)|login failed|authentication failed') {
            Write-Fail 'AMD account authentication failed (invalid credentials or form change).'
            return $null
        }

        if ($loginResp.StatusCode -ne 200 -and $loginResp.StatusCode -ne 302) {
            Write-Fail ("Unexpected login response: HTTP {0}" -f $loginResp.StatusCode)
            return $null
        }
        Write-Ok ("Login response: HTTP {0}" -f $loginResp.StatusCode)
    } catch {
        Write-Fail ("Step 2 (login POST) failed: {0}" -f $_.Exception.Message)
        Write-Skip 'AMD may have updated their login endpoint structure.'
        return $null
    } finally {
        # Clear plaintext password from local scope ASAP
        $plainPassword = $null
    }

    # Step 3: Re-fetch EULA page authenticated, find the download form
    try {
        Write-Skip ("Step 3: Re-fetch EULA page authenticated")
        $eulaAuth = Invoke-WebRequest -Uri $eulaUrl `
            -WebSession $session `
            -UseBasicParsing `
            -TimeoutSec 30 `
            -ErrorAction Stop

        # Look for the EULA accept form action and any required fields
        $formActionMatch = [regex]::Match($eulaAuth.Content, '<form[^>]+action="([^"]+)"[^>]*>')
        if (-not $formActionMatch.Success) {
            Write-Caution 'Could not locate EULA acceptance form action.'
            return $null
        }
        $formAction = $formActionMatch.Groups[1].Value
        if ($formAction -notmatch '^https?://') {
            $formAction = 'https://account.amd.com' + $formAction
        }
        Write-Skip ("EULA form action: {0}" -f $formAction)

        # Re-extract CSRF token from authenticated page
        $csrfMatch2 = [regex]::Match($eulaAuth.Content, 'name="(?:_csrf|csrf_token|authenticity_token)"\s+value="([^"]+)"')
        $csrfToken2 = if ($csrfMatch2.Success) { $csrfMatch2.Groups[1].Value } else { $null }

        # Step 4: POST EULA acceptance
        Write-Skip 'Step 4: POST EULA acceptance'
        $acceptBody = @{
            'filename'      = $DriverFilename
            'accept_eula'   = '1'
            'accept_terms'  = 'on'
        }
        if ($csrfToken2) {
            $acceptBody['_csrf'] = $csrfToken2
        }

        $acceptResp = Invoke-WebRequest -Uri $formAction `
            -Method Post `
            -Body $acceptBody `
            -WebSession $session `
            -UseBasicParsing `
            -TimeoutSec 60 `
            -MaximumRedirection 0 `
            -ErrorAction SilentlyContinue

        $location = $null
        if ($acceptResp -and $acceptResp.Headers.ContainsKey('Location')) {
            $location = $acceptResp.Headers['Location']
        } elseif ($acceptResp -and $acceptResp.Content -match 'href="(https?://[^"]*\.zip[^"]*)"') {
            $location = $Matches[1]
        }

        if (-not $location) {
            # Try matching entitlenow.com pattern (AMD's CDN)
            if ($acceptResp -and $acceptResp.Content -match 'https?://[\w\.\-]*entitlenow\.com/[^"\s]+\.zip[^"\s]*') {
                $location = $Matches[0]
            }
        }

        if (-not $location) {
            Write-Caution 'Could not extract download URL from EULA acceptance response.'
            Write-Skip 'AMD may use JS-driven URL generation or has changed the response structure.'
            return $null
        }

        Write-Ok ('Resolved authenticated download URL (entitlenow.com CDN)')
        return @{
            DownloadUrl = $location
            Session     = $session
        }
    } catch {
        Write-Fail ("Step 3/4 (EULA accept) failed: {0}" -f $_.Exception.Message)
        return $null
    }
}
# =============================================================================
# Tool acquisition (Windows SDK signtool, Windows WDK inf2cat, 7-Zip) — Phase P02
# Same toolchain as chipset/graphics sister scripts for maintenance parity.
# =============================================================================

function Test-CommandExists { # psa-disable-line PSA6003 -- compound noun (e.g., Policies, Drivers, Catalogs) is semantically plural for set-returning helpers
    [CmdletBinding()]
    [OutputType([bool])]
    param([Parameter(Mandatory)][string]$Name)
    $null -ne (Get-Command $Name -ErrorAction SilentlyContinue)
}

function Find-ToolPath {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)][string]$ToolFilename,
        [Parameter(Mandatory)][string[]]$SearchRoots
    )
    foreach ($root in $SearchRoots) {
        if (-not (Test-Path $root)) { continue }
        $hit = Get-ChildItem -Path $root -Filter $ToolFilename -Recurse -File -ErrorAction SilentlyContinue |
            Where-Object { $_.FullName -match '\\x64\\' -or $_.FullName -match '\\amd64\\' } |
            Sort-Object @{Expression={$_.VersionInfo.FileVersion};Descending=$true}, LastWriteTime -Descending |
            Select-Object -First 1
        if ($hit) { return $hit.FullName }
    }
    return $null
}

function Find-SignToolPath {
    [CmdletBinding()]
    [OutputType([string])]
    param()
    $roots = @(
        'C:\Program Files (x86)\Windows Kits\10\bin',
        'C:\Program Files\Windows Kits\10\bin',
        'C:\Program Files (x86)\Windows Kits\11\bin',
        'C:\Program Files\Windows Kits\11\bin'
    )
    return Find-ToolPath -ToolFilename 'signtool.exe' -SearchRoots $roots
}

function Find-Inf2CatPath {
    [CmdletBinding()]
    [OutputType([string])]
    param()
    # NOTE (bugfix - unrelated to secureboot baseline feature):
    # inf2cat.exe ships ONLY in x86 form under the Windows SDK/WDK 'bin'
    # tree (Microsoft has never produced an x64 build of this tool).
    # Therefore we cannot reuse the generic Find-ToolPath helper, which
    # filters to '\x64\' / '\amd64\' paths only. Previously NPU releases
    # called Find-ToolPath -ToolFilename 'inf2cat.exe' which silently
    # returned $null on every machine, then failed P02 by trying to
    # install the WDK via winget (which itself does not ship the WDK
    # as a winget package).
    # Replicates the lookup the sister scripts use: walk the SDK
    # bin tree directly, no architecture filter, pick the highest
    # FileVersion.
    $roots = @(
        'C:\Program Files (x86)\Windows Kits\10\bin',
        'C:\Program Files\Windows Kits\10\bin',
        'C:\Program Files (x86)\Windows Kits\11\bin'
    )
    foreach ($root in $roots) {
        if (-not (Test-Path $root)) { continue }
        $hit = Get-ChildItem -Path $root -Filter 'inf2cat.exe' -Recurse -File -ErrorAction SilentlyContinue |
            Sort-Object @{Expression={$_.VersionInfo.FileVersion};Descending=$true}, LastWriteTime -Descending |
            Select-Object -First 1
        if ($hit) { return $hit.FullName }
    }
    return $null
}

function Find-SevenZipPath {
    <#
    .SYNOPSIS
        Locates 7z.exe in the standard 7-Zip install paths or on PATH.
    .NOTES
        Same lookup strategy as the chipset and graphics sister scripts.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param()

    # Standard install paths (in priority order)
    $candidates = @(
        'C:\Program Files\7-Zip\7z.exe',
        'C:\Program Files (x86)\7-Zip\7z.exe',
        "$env:ProgramFiles\7-Zip\7z.exe",
        "${env:ProgramFiles(x86)}\7-Zip\7z.exe",
        "$env:LOCALAPPDATA\Programs\7-Zip\7z.exe"
    )
    foreach ($p in $candidates) {
        if (-not [string]::IsNullOrEmpty($p) -and (Test-Path $p)) {
            return $p
        }
    }
    # Fall back to PATH lookup
    $cmd = Get-Command 7z.exe -ErrorAction SilentlyContinue
    if ($cmd) {
        return $cmd.Source
    }
    return $null
}

function Install-RequiredTools { # psa-disable-line PSA6003 -- compound noun (e.g., Policies, Drivers, Catalogs) is semantically plural for set-returning helpers
    <#
    .SYNOPSIS
        Ensures Windows SDK (signtool), Windows WDK (inf2cat), and 7-Zip are available.
    .DESCRIPTION
        Same toolchain as the chipset and graphics sister scripts. 7-Zip is required
        for ZIP extraction in P04 to maintain parity with the EXE / nested-CAB extraction
        flows used by the chipset and graphics scripts.
    #>
    [CmdletBinding()]
    [OutputType([hashtable])]
    param()

    # Pre-flight detection so we can surface a single, consolidated
    # heads-up to the user BEFORE the long winget runs start. On a
    # clean-installed host the SDK and WDK packages are absent and
    # must be downloaded via winget. The bootstrap EXEs are small
    # (~1.3 MB each) but each fetches several hundred MB to multi-GB
    # of background payload from Microsoft Download CDN; total P02
    # elapsed on a clean host (JP) typically lands in the 8-10 minute
    # range. On subsequent runs in the same workspace, the P02
    # PhaseMarker is hit and this whole block is skipped in ~2 s.
    $preSigntool = Find-SignToolPath
    $preInf2cat  = Find-Inf2CatPath
    $needsSdk = -not $preSigntool
    $needsWdk = -not $preInf2cat
    if ($needsSdk -or $needsWdk) {
        $missing = @()
        if ($needsSdk) { $missing += 'Windows SDK (~5 min)' }
        if ($needsWdk) { $missing += 'Windows WDK (~3 min)' }
        Write-Caution ('First-run install required for: {0}.' -f ($missing -join ', '))
        Write-Host  '       Bootstrap EXEs are small (~1-2 MB) but each fetches several hundred MB'  -ForegroundColor DarkYellow
        Write-Host  '       to multi-GB of background payload from Microsoft Download CDN.'         -ForegroundColor DarkYellow
        Write-Host  '       Expected P02 elapsed on a clean host (JP): ~8-10 minutes.'              -ForegroundColor DarkYellow
        Write-Host  '       Subsequent runs in the same workspace will skip P02 (PhaseMarker hit).' -ForegroundColor DarkGray
    }

    Write-SubHeader2 'Step 1/3: signtool.exe (Windows SDK)'
    $signtool = Find-SignToolPath
    if ($signtool) {
        Write-Ok ("signtool found: {0}" -f $signtool)
    } else {
        Write-Caution 'signtool not found. Installing Windows SDK via winget...'
        try {
            $wingetCmd = Get-Command winget -ErrorAction Stop
            $procArgs = '--id Microsoft.WindowsSDK --silent --accept-package-agreements --accept-source-agreements --disable-interactivity'
            $proc = Start-Process -FilePath $wingetCmd.Source `
                -ArgumentList ('install ' + $procArgs).Split(' ') `
                -NoNewWindow -Wait -PassThru
            if ($proc.ExitCode -eq 0) {
                Write-Ok 'Windows SDK installed via winget.'
            } else {
                Write-Caution ("winget exit code: {0}; checking for signtool again..." -f $proc.ExitCode)
            }
        } catch {
            Write-Caution ("winget unavailable or failed: {0}" -f $_.Exception.Message)
            Write-Caution 'Manually install Windows 10/11 SDK from:'
            Write-Caution '  https://learn.microsoft.com/en-us/windows-hardware/drivers/download-the-wdk'
        }
        $signtool = Find-SignToolPath
        if (-not $signtool) {
            throw 'signtool.exe not found after install attempt.'
        }
        Write-Ok ("signtool now available at: {0}" -f $signtool)
    }

    Write-SubHeader2 'Step 2/3: inf2cat.exe (Windows WDK)'
    $inf2cat = Find-Inf2CatPath
    if ($inf2cat) {
        Write-Ok ("inf2cat found: {0}" -f $inf2cat)
    } else {
        Write-Caution 'inf2cat not found. Installing Windows WDK via winget (~2.5 GB)...'
        try {
            $wingetCmd = Get-Command winget -ErrorAction Stop
            $procArgs = '--id Microsoft.WindowsWDK --silent --accept-package-agreements --accept-source-agreements --disable-interactivity'
            $proc = Start-Process -FilePath $wingetCmd.Source `
                -ArgumentList ('install ' + $procArgs).Split(' ') `
                -NoNewWindow -Wait -PassThru
            if ($proc.ExitCode -eq 0) {
                Write-Ok 'Windows WDK installed via winget.'
            } else {
                Write-Caution ("winget exit code: {0}; checking for inf2cat again..." -f $proc.ExitCode)
            }
        } catch {
            Write-Caution ("winget unavailable or failed: {0}" -f $_.Exception.Message)
            Write-Caution 'Manually install Windows 10/11 WDK from:'
            Write-Caution '  https://learn.microsoft.com/en-us/windows-hardware/drivers/download-the-wdk'
        }
        $inf2cat = Find-Inf2CatPath
        if (-not $inf2cat) {
            throw 'inf2cat.exe not found after install attempt.'
        }
        Write-Ok ("inf2cat now available at: {0}" -f $inf2cat)
    }

    Write-SubHeader2 'Step 3/3: 7z.exe (7-Zip)'
    $sevenZip = Find-SevenZipPath
    if ($sevenZip) {
        Write-Ok ("7-Zip found: {0}" -f $sevenZip)
    } else {
        Write-Caution '7-Zip not found. Installing via winget...'
        try {
            $wingetCmd = Get-Command winget -ErrorAction Stop
            $procArgs = '--id 7zip.7zip --silent --accept-package-agreements --accept-source-agreements --disable-interactivity'
            $proc = Start-Process -FilePath $wingetCmd.Source `
                -ArgumentList ('install ' + $procArgs).Split(' ') `
                -NoNewWindow -Wait -PassThru
            if ($proc.ExitCode -eq 0) {
                Write-Ok '7-Zip installed via winget.'
            } else {
                Write-Caution ("winget exit code: {0}; checking for 7-Zip again..." -f $proc.ExitCode)
            }
        } catch {
            Write-Caution ("winget unavailable or failed: {0}" -f $_.Exception.Message)
            Write-Caution 'Manually install 7-Zip from:'
            Write-Caution '  https://www.7-zip.org/'
        }
        $sevenZip = Find-SevenZipPath
        if (-not $sevenZip) {
            throw '7z.exe not found after install attempt.'
        }
        Write-Ok ("7-Zip now available at: {0}" -f $sevenZip)
    }

    return @{
        SignTool = $signtool
        Inf2Cat  = $inf2cat
        SevenZip = $sevenZip
    }
}

# =============================================================================
# ZIP extraction (P04) - NPU specific, using 7-Zip for parity with sister scripts
# =============================================================================
function Expand-AmdNpuPackage {
    <#
    .SYNOPSIS
        Extracts the NPU driver ZIP using 7-Zip, handling potential nested ZIPs.
    .DESCRIPTION
        Uses 7z.exe x (extract with full paths) for consistency with the chipset and
        graphics sister scripts. 7-Zip handles ZIP, ZIPX, embedded CAB and other formats
        that PowerShell's native Expand-Archive does not, and produces deterministic
        output across PowerShell versions.
    .PARAMETER ZipPath
        Path to the source ZIP archive.
    .PARAMETER DestinationDir
        Directory to extract into (will be cleaned and recreated).
    .PARAMETER SevenZipPath
        Full path to 7z.exe (resolved by Find-SevenZipPath in P02).
    #>
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory)][string]$ZipPath,
        [Parameter(Mandatory)][string]$DestinationDir,
        [Parameter(Mandatory)][string]$SevenZipPath
    )

    if (-not (Test-Path $ZipPath)) {
        throw "ZIP file not found: $ZipPath"
    }
    if (-not (Test-Path $SevenZipPath)) {
        throw "7-Zip executable not found at: $SevenZipPath"
    }

    Write-Step ("Extracting (7-Zip): {0}" -f $ZipPath)
    Write-Skip ("Destination       : {0}" -f $DestinationDir)
    Write-Skip ("7-Zip executable  : {0}" -f $SevenZipPath)

    # Clean destination
    if (Test-Path $DestinationDir) {
        Remove-Item -Path $DestinationDir -Recurse -Force -ErrorAction SilentlyContinue
    }
    New-Item -Path $DestinationDir -ItemType Directory -Force | Out-Null

    # Run 7z.exe x with full paths, overwrite, no progress, no echo
    #   x - extract with full paths
    #   -y - assume yes on all queries
    #   -bso0 - disable standard-output messages (we still capture warnings/errors)
    #   -bsp0 - disable progress output
    #   -o<dir> - output directory (no space after -o per 7-Zip syntax)
    $sevenZipArgs = @(
        'x'
        $ZipPath
        ('-o' + $DestinationDir)
        '-y'
        '-bsp0'
    )
    $start = Get-Date
    $stdout = & $SevenZipPath @sevenZipArgs 2>&1
    $exitCode = $LASTEXITCODE
    $duration = ((Get-Date) - $start).TotalSeconds

    foreach ($line in $stdout) {
        if ($line -match '(?i)error|warning') {
            Write-Caution ("    {0}" -f $line)
        } else {
            Write-Skip ("    {0}" -f $line)
        }
    }

    # 7-Zip exit codes:
    #   0 = no error, 1 = warning (non-fatal), 2 = fatal error,
    #   7 = command-line error, 8 = out of memory, 255 = user cancel
    if ($exitCode -eq 0) {
        Write-Ok ("Initial extraction complete ({0:n1}s)." -f $duration)
    } elseif ($exitCode -eq 1) {
        Write-Caution ("7-Zip reported non-fatal warnings (exit {0}); continuing." -f $exitCode)
    } else {
        Write-Fail ("7-Zip extraction failed (exit code {0})." -f $exitCode)
        throw ("7-Zip extraction failed with exit code {0}" -f $exitCode)
    }

    # Inspect for nested ZIP files (some RAI 1.6+ packages ship nested)
    $nestedZips = Get-ChildItem -Path $DestinationDir -Filter '*.zip' -Recurse -File -ErrorAction SilentlyContinue
    if ($nestedZips) {
        foreach ($nz in $nestedZips) {
            Write-Step ("Nested ZIP detected: {0}" -f $nz.Name)
            $nestedDest = Join-Path $nz.DirectoryName ($nz.BaseName + '_extracted')
            $nestedArgs = @(
                'x'
                $nz.FullName
                ('-o' + $nestedDest)
                '-y'
                '-bsp0'
            )
            $nestedStdout = & $SevenZipPath @nestedArgs 2>&1
            $nestedExit = $LASTEXITCODE
            foreach ($line in $nestedStdout) {
                Write-Skip ("    {0}" -f $line)
            }
            if ($nestedExit -le 1) {
                Write-Skip ("Nested ZIP extracted to: {0}" -f $nestedDest)
            } else {
                Write-Caution ("Nested ZIP extraction failed (exit {0}); continuing." -f $nestedExit)
            }
        }
    }

    # Inventory the contents
    $infs   = Get-ChildItem -Path $DestinationDir -Filter '*.inf' -Recurse -File -ErrorAction SilentlyContinue
    $cats   = Get-ChildItem -Path $DestinationDir -Filter '*.cat' -Recurse -File -ErrorAction SilentlyContinue
    $syss   = Get-ChildItem -Path $DestinationDir -Filter '*.sys' -Recurse -File -ErrorAction SilentlyContinue
    $exes   = Get-ChildItem -Path $DestinationDir -Filter '*.exe' -Recurse -File -ErrorAction SilentlyContinue

    Write-Host ''
    Write-Skip ("INF files : {0}" -f $infs.Count)
    foreach ($i in $infs) {
        Write-Skip ("    {0}  ({1:n0} bytes)" -f $i.Name, $i.Length)
    }
    Write-Skip ("CAT files : {0}" -f $cats.Count)
    Write-Skip ("SYS files : {0}" -f $syss.Count)
    Write-Skip ("EXE files : {0}" -f $exes.Count)

    if ($infs.Count -eq 0) {
        throw 'No .inf files found in extracted package. Aborting.'
    }

    return @{
        InfFiles     = $infs
        CatFiles     = $cats
        SysFiles     = $syss
        ExeFiles     = $exes
        ExtractedDir = $DestinationDir
    }
}

# =============================================================================
# INF parser core (P05/P06) — same logic as chipset an earlier revision, NPU-tuned
# =============================================================================
function Read-InfFileLines { # psa-disable-line PSA6003 -- compound noun (e.g., Policies, Drivers, Catalogs) is semantically plural for set-returning helpers
    [CmdletBinding()]
    [OutputType([string[]])]
    param([Parameter(Mandatory)][string]$Path)
    # Try UTF-8 first, fall back to ASCII / Default for legacy INF encodings
    try {
        return [System.IO.File]::ReadAllLines($Path, [System.Text.Encoding]::UTF8)
    } catch {
        try {
            return [System.IO.File]::ReadAllLines($Path)
        } catch {
            Write-Caution ("Could not read INF as UTF-8 or default: {0}" -f $Path)
            return @()
        }
    }
}

function Read-InfManufacturer {
    <#
    .SYNOPSIS
        Parses the [Manufacturer] section of an INF file.
    .DESCRIPTION
        Returns metadata about the manufacturer decorations:
          - HasServerDecoration  : INF already has ProductType=3 mirror entries
          - WorkstationEntries   : list of [Manufacturer] decorations without ProductType=3
          - HwidEntries          : extracted Hardware IDs from each decoration block
    .OUTPUTS
        Hashtable per the description above.
    #>
    [CmdletBinding()]
    [OutputType([hashtable])]
    param([Parameter(Mandatory)][string]$InfPath)

    $lines = Read-InfFileLines -Path $InfPath
    $result = @{
        InfPath                 = $InfPath
        InfName                 = Split-Path $InfPath -Leaf
        ManufacturerSectionLines = @()
        ManufacturerDecorations  = @()  # array of strings like "AMD, NTamd64.10.0...26100"
        WorkstationDecorations   = @()  # subset that lacks ProductType=3
        ServerDecorations        = @()  # subset that has ProductType=3 (.3 suffix)
        HwidEntries              = @()
        HasServerDecoration      = $false
        DriverVer                = $null
        Provider                 = $null
        Class                    = $null
        ClassGuid                = $null
        SectionLineRanges        = @{}  # hash: section name -> @{Start; End}
    }

    if (-not $lines) { return $result }

    # First pass: build section index
    $currentSection = $null
    $sectionStart = -1
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i].Trim()
        # Skip comments
        $stripped = ($line -split ';', 2)[0].Trim()
        if ($stripped -match '^\[([^\]]+)\]$') {
            if ($currentSection) {
                $result.SectionLineRanges[$currentSection] = @{ Start = $sectionStart; End = ($i - 1) }
            }
            $currentSection = $Matches[1].Trim()
            $sectionStart = $i + 1
        }
    }
    if ($currentSection) {
        $result.SectionLineRanges[$currentSection] = @{ Start = $sectionStart; End = ($lines.Count - 1) }
    }

    # [Version] section parse
    if ($result.SectionLineRanges.ContainsKey('Version')) {
        $vRange = $result.SectionLineRanges['Version']
        for ($i = $vRange.Start; $i -le $vRange.End; $i++) {
            $line = $lines[$i].Trim()
            $stripped = ($line -split ';', 2)[0].Trim()
            if ($stripped -match '^DriverVer\s*=\s*(.+)$') {
                $result.DriverVer = $Matches[1].Trim()
            } elseif ($stripped -match '^Provider\s*=\s*(.+)$') {
                $result.Provider = $Matches[1].Trim()
            } elseif ($stripped -match '^Class\s*=\s*(.+)$') {
                $result.Class = $Matches[1].Trim()
            } elseif ($stripped -match '^ClassGuid\s*=\s*(.+)$') {
                $result.ClassGuid = $Matches[1].Trim()
            }
        }
    }

    # [Manufacturer] section parse
    if (-not $result.SectionLineRanges.ContainsKey('Manufacturer')) {
        return $result
    }
    $mRange = $result.SectionLineRanges['Manufacturer']
    for ($i = $mRange.Start; $i -le $mRange.End; $i++) {
        $line = $lines[$i]
        $result.ManufacturerSectionLines += $line
        $stripped = ($line -split ';', 2)[0].Trim()
        if ([string]::IsNullOrEmpty($stripped)) { continue }
        # Format: %ManufacturerName%=ManufacturerSection,decoration1,decoration2,...
        if ($stripped -match '^%[^%]+%\s*=\s*([^,]+)(?:,(.+))?$') {
            $sectionName = $Matches[1].Trim()
            $decorations = @()
            if ($Matches[2]) {
                $decorations = $Matches[2].Split(',') | ForEach-Object { $_.Trim() } | Where-Object { $_ }
            }
            foreach ($dec in $decorations) {
                # Build full section name: e.g. "AMD.NTamd64.10.0...26100" or "AMD.NTamd64.10.0...26100.3"
                $fullSection = "$sectionName.$dec"
                $result.ManufacturerDecorations += $dec

                # Detect ProductType=3 decoration (ends in.3 after the build number)
                if ($dec -match '\.3$') {
                    $result.ServerDecorations += $dec
                    $result.HasServerDecoration = $true
                } else {
                    $result.WorkstationDecorations += $dec
                }

                # Find HWIDs in the decorated section
                if ($result.SectionLineRanges.ContainsKey($fullSection)) {
                    $hwidRange = $result.SectionLineRanges[$fullSection]
                    for ($j = $hwidRange.Start; $j -le $hwidRange.End; $j++) {
                        $hwidLine = $lines[$j]
                        $hwidStripped = ($hwidLine -split ';', 2)[0].Trim()
                        if ([string]::IsNullOrEmpty($hwidStripped)) { continue }
                        # Format: %DeviceDesc% = InstallSection, HWID
                        if ($hwidStripped -match '^%[^%]+%\s*=\s*[^,]+,\s*(.+)$') {
                            $hwidPart = $Matches[1].Trim()
                            # May have additional HWIDs separated by commas
                            $hwids = $hwidPart.Split(',') | ForEach-Object { $_.Trim() } | Where-Object { $_ }
                            foreach ($hwid in $hwids) {
                                $result.HwidEntries += [pscustomobject]@{
                                    Decoration = $dec
                                    DecoratedSection = $fullSection
                                    HardwareId = $hwid
                                    LineNumber = $j + 1  # 1-indexed for human display
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    return $result
}

function Add-ProductType3Decoration {
    <#
    .SYNOPSIS
        Patches an INF file to add ProductType=3 (Server) decorations mirroring existing
        Workstation entries in the [Manufacturer] section.
    .DESCRIPTION
        - Reads the original INF
        - For each Workstation decoration (e.g. "NTamd64.10.0...26100"), creates a Server
          mirror by appending ".3" (e.g. "NTamd64.10.0...26100.3") to [Manufacturer]
        - Duplicates the original [<sec>.<decoration>] block as [<sec>.<decoration>.3]
        - Writes the patched INF to a new path
    .OUTPUTS
        Hashtable with: Patched (bool), MirroredCount (int), OutputPath (string)
    #>
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory)][string]$InputInfPath,
        [Parameter(Mandatory)][string]$OutputInfPath
    )

    $result = @{
        Patched       = $false
        MirroredCount = 0
        OutputPath    = $OutputInfPath
        Reason        = $null
    }

    $lines = Read-InfFileLines -Path $InputInfPath
    if (-not $lines -or $lines.Count -eq 0) {
        $result.Reason = 'Could not read INF file.'
        return $result
    }

    $inf = Read-InfManufacturer -InfPath $InputInfPath

    # Already has Server decorations? Just copy the file unchanged.
    if ($inf.HasServerDecoration -and $inf.WorkstationDecorations.Count -eq 0) {
        Write-Skip ("INF already has only Server decorations: {0}" -f (Split-Path $InputInfPath -Leaf))
        Copy-Item -Path $InputInfPath -Destination $OutputInfPath -Force
        $result.Reason = 'AlreadyServerCompatible'
        $result.Patched = $true
        return $result
    }

    # Workstation decorations exist — mirror them
    if ($inf.WorkstationDecorations.Count -eq 0) {
        $result.Reason = 'No [Manufacturer] decorations found.'
        Copy-Item -Path $InputInfPath -Destination $OutputInfPath -Force
        return $result
    }

    # Build new [Manufacturer] section content
    $newLines = New-Object 'System.Collections.Generic.List[string]'
    $manufacturerRange = $inf.SectionLineRanges['Manufacturer']

    # Write everything before [Manufacturer]
    if ($manufacturerRange.Start -gt 0) {
        for ($i = 0; $i -lt ($manufacturerRange.Start - 1); $i++) {
            $newLines.Add($lines[$i])
        }
    }
    $newLines.Add('[Manufacturer]')

    # Rewrite [Manufacturer] entries with appended.3 mirrors
    for ($i = $manufacturerRange.Start; $i -le $manufacturerRange.End; $i++) {
        $line = $lines[$i]
        $stripped = ($line -split ';', 2)[0].Trim()
        if ([string]::IsNullOrEmpty($stripped)) {
            $newLines.Add($line)
            continue
        }
        if ($stripped -match '^(%[^%]+%\s*=\s*)([^,]+)(?:,(.+))?$') {
            $prefix = $Matches[1]
            $sectionName = $Matches[2].Trim()
            $existingDecorations = @()
            if ($Matches[3]) {
                $existingDecorations = $Matches[3].Split(',') | ForEach-Object { $_.Trim() } | Where-Object { $_ }
            }
            # Mirror each Workstation decoration with.3 if not already present
            $mirroredDecorations = @($existingDecorations)
            foreach ($dec in $existingDecorations) {
                if ($dec -match '\.3$') { continue }
                $mirror = "$dec.3"
                if ($mirroredDecorations -notcontains $mirror) {
                    $mirroredDecorations += $mirror
                    $result.MirroredCount++
                }
            }
            $newLine = "$prefix$sectionName"
            if ($mirroredDecorations.Count -gt 0) {
                $newLine += ',' + ($mirroredDecorations -join ',')
            }
            $newLines.Add($newLine)
        } else {
            $newLines.Add($line)
        }
    }

    # Write everything after [Manufacturer] up to where decorated sections start
    # We need to also duplicate each [Section.decoration] block as [Section.decoration.3]
    $afterManufacturerStart = $manufacturerRange.End + 1
    $duplicateBlocks = New-Object 'System.Collections.Generic.List[string]'

    # Identify which sections need duplication
    foreach ($section in $inf.SectionLineRanges.Keys) {
        # Only mirror sections that look like "<Mfgr>.NT*" or "<Mfgr>.NTamd64*" decoration sections
        # (skip InstallSection blocks like "<HWID>" which are referenced from these decorated sections)
        $matchedDecoration = $null
        foreach ($dec in $inf.WorkstationDecorations) {
            if ($section.EndsWith('.' + $dec)) {
                $matchedDecoration = $dec
                break
            }
        }
        if (-not $matchedDecoration) { continue }

        # Build the.3 mirror
        $mirroredSectionName = "$section.3"
        if ($inf.SectionLineRanges.ContainsKey($mirroredSectionName)) { continue }  # already exists

        $blockRange = $inf.SectionLineRanges[$section]
        $duplicateBlocks.Add('')
        $duplicateBlocks.Add("[$mirroredSectionName]")
        $duplicateBlocks.Add(';')
        $duplicateBlocks.Add('; ProductType=3 (Server) mirror auto-generated by Deploy-AMDNpuDriverOnWindowsServer.ps1')
        $duplicateBlocks.Add(';')
        for ($i = $blockRange.Start; $i -le $blockRange.End; $i++) {
            $duplicateBlocks.Add($lines[$i])
        }
    }

    # Write everything after [Manufacturer]
    for ($i = $afterManufacturerStart; $i -lt $lines.Count; $i++) {
        $newLines.Add($lines[$i])
    }
    # Append duplicate blocks at end
    foreach ($l in $duplicateBlocks) {
        $newLines.Add($l)
    }

    # Write output INF (use ASCII to preserve compatibility with inf2cat parser)
    $outputDir = Split-Path $OutputInfPath -Parent
    if (-not (Test-Path $outputDir)) {
        New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
    }
    [System.IO.File]::WriteAllLines($OutputInfPath, $newLines.ToArray(), [System.Text.Encoding]::Unicode)

    $result.Patched = $true
    $result.Reason = ('Mirrored {0} decoration(s) with ProductType=3' -f $result.MirroredCount)
    return $result
}

function Test-InfProductTypeCoverage {
    <#
    .SYNOPSIS
        Verifies that a patched INF has ProductType=3 decorations for the expected build.
    #>
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory)][string]$InfPath,
        [int]$ExpectedBuild = 26100
    )
    $inf = Read-InfManufacturer -InfPath $InfPath
    $result = @{
        InfName            = $inf.InfName
        HasServerForBuild  = $false
        ServerDecorations  = $inf.ServerDecorations
        WorkstationOnly    = ($inf.WorkstationDecorations.Count -gt 0 -and $inf.ServerDecorations.Count -eq 0)
        Provider           = $inf.Provider
        DriverVer          = $inf.DriverVer
    }
    foreach ($srv in $inf.ServerDecorations) {
        $serverPattern = ('{0}\.3$' -f $ExpectedBuild)
        if ($srv -match $serverPattern) { # psa-disable-line PSA2003 -- pattern variable is initialized in the enclosing scope; $null impossible by construction
            $result.HasServerForBuild = $true
            break
        }
    }
    return $result
}
# =============================================================================
# Self-signed code-signing certificate (P07)
# =============================================================================
function New-SelfSignedCodeSigningCert {
    <#
    .SYNOPSIS
        Generates a self-signed code-signing certificate for NPU driver catalogs.
    .DESCRIPTION
        - RSA 4096-bit, SHA-384 signature
        - EKU: Code Signing (1.3.6.1.5.5.7.3.3)
        - Validity: $CertValidityYears (default 5)
        - Stored in CurrentUser\My (transient), exported to PFX/CER
    #>
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory)][string]$Subject,
        [Parameter(Mandatory)][string]$PfxPath,
        [Parameter(Mandatory)][string]$CerPath,
        [string]$PfxPassword = '',  # psa-disable-line PSA5001 -- forwarded to Export-PfxCertificate -Password (SecureString) via internal conversion; kept [string] for API symmetry with top-level param
        [int]$ValidityYears = 5
    )

    $expiry = (Get-Date).AddYears($ValidityYears)

    Write-Step ('Creating self-signed cert: CN={0}' -f $Subject)
    Write-Skip ('Key       : RSA 4096-bit / SHA-384')
    Write-Skip ('EKU       : Code Signing (1.3.6.1.5.5.7.3.3)')
    Write-Skip ('Validity  : {0} years (until {1:yyyy-MM-dd})' -f $ValidityYears, $expiry)

    $params = @{
        Subject           = "CN=$Subject"
        Type              = 'CodeSigningCert'
        KeyUsage          = 'DigitalSignature'
        TextExtension     = @('2.5.29.37={text}1.3.6.1.5.5.7.3.3')
        KeyAlgorithm      = 'RSA'
        KeyLength         = 4096
        HashAlgorithm     = 'SHA384'
        CertStoreLocation = 'Cert:\CurrentUser\My'
        NotAfter          = $expiry
        FriendlyName      = $Subject
    }

    $cert = New-SelfSignedCertificate @params
    if (-not $cert) {
        throw 'New-SelfSignedCertificate returned null.'
    }

    $certDir = Split-Path $PfxPath -Parent
    if (-not (Test-Path $certDir)) {
        New-Item -Path $certDir -ItemType Directory -Force | Out-Null
    }

    # Export PFX
    $pfxSecure = if ([string]::IsNullOrEmpty($PfxPassword)) {
        ConvertTo-SecureString -String 'placeholder' -AsPlainText -Force
    } else {
        ConvertTo-SecureString -String $PfxPassword -AsPlainText -Force
    }
    if ([string]::IsNullOrEmpty($PfxPassword)) {
        # Empty password: export with placeholder, then re-encode without password
        Export-PfxCertificate -Cert $cert -FilePath $PfxPath -Password $pfxSecure -Force | Out-Null
    } else {
        Export-PfxCertificate -Cert $cert -FilePath $PfxPath -Password $pfxSecure -Force | Out-Null
    }

    # Export CER (public)
    Export-Certificate -Cert $cert -FilePath $CerPath -Force | Out-Null

    Write-Ok ('Cert thumbprint: {0}' -f $cert.Thumbprint)
    Write-Skip ('PFX exported   : {0}' -f $PfxPath)
    Write-Skip ('CER exported   : {0}' -f $CerPath)

    return @{
        Cert       = $cert
        Thumbprint = $cert.Thumbprint
        PfxPath    = $PfxPath
        CerPath    = $CerPath
        Expiry     = $expiry
    }
}

# =============================================================================
# inf2cat / signtool wrappers (P08 / P09)
# =============================================================================
function Invoke-Inf2Cat {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory)][string]$Inf2CatPath,
        [Parameter(Mandatory)][string]$DriverDir,
        [Parameter(Mandatory)][string]$OsSwitch
    )

    Write-Step ('inf2cat /driver:"{0}" /os:{1}' -f $DriverDir, $OsSwitch)
    $start = Get-Date
    $stdout = & $Inf2CatPath /driver:$DriverDir /os:$OsSwitch 2>&1
    $exitCode = $LASTEXITCODE
    $duration = ((Get-Date) - $start).TotalSeconds

    foreach ($line in $stdout) {
        Write-Skip ("    {0}" -f $line)
    }

    return @{
        ExitCode = $exitCode
        Duration = $duration
        Output   = $stdout
        Success  = ($exitCode -eq 0)
    }
}

function Invoke-SignTool {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory)][string]$SignToolPath,
        [Parameter(Mandatory)][string]$CatPath,
        [Parameter(Mandatory)][string]$PfxPath,
        [string]$PfxPassword = '',  # psa-disable-line PSA5001 -- value flows to signtool.exe /p as a plaintext String; signtool's CLI does not accept SecureString
        [string]$TimestampUrl = 'http://timestamp.digicert.com',
        [string]$HashAlgo = 'SHA384'
    )

    $signArgs = @(
        'sign'
        '/fd', $HashAlgo
        '/td', $HashAlgo
        '/tr', $TimestampUrl
        '/f', $PfxPath
    )
    if (-not [string]::IsNullOrEmpty($PfxPassword)) {
        $signArgs += '/p'
        $signArgs += $PfxPassword
    }
    $signArgs += $CatPath

    $start = Get-Date
    $stdout = & $SignToolPath @signArgs 2>&1
    $exitCode = $LASTEXITCODE
    $duration = ((Get-Date) - $start).TotalSeconds

    foreach ($line in $stdout) {
        Write-Skip ("    {0}" -f $line)
    }

    return @{
        ExitCode = $exitCode
        Duration = $duration
        Output   = $stdout
        Success  = ($exitCode -eq 0)
    }
}

function Test-CatalogSignature {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory)][string]$SignToolPath,
        [Parameter(Mandatory)][string]$CatPath
    )

    $stdout = & $SignToolPath verify /pa /v $CatPath 2>&1
    $exitCode = $LASTEXITCODE

    return @{
        ExitCode = $exitCode
        Output   = $stdout
        Success  = ($exitCode -eq 0)
    }
}

# =============================================================================
# WDAC supplemental policy (I02)
# =============================================================================
function New-WdacSupplementalPolicy {
    <#
    .SYNOPSIS
        Generates a WDAC supplemental Code Integrity policy that allowlists the self-signed
        code-signing cert as a kernel-mode signer.
    .DESCRIPTION
        Uses New-CIPolicy + Add-SignerRule + ConvertFrom-CIPolicy. The policy is
        Allow-by-default with our cert as additional kernel-mode signer.
        Deployment via CiTool --update-policy avoids the need for a reboot on
        Windows Server 2022+ / Windows 11 22H2+.
    #>
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory)][string]$CerPath,
        [Parameter(Mandatory)][string]$XmlOutputPath,
        [Parameter(Mandatory)][string]$BinOutputPath,
        [Parameter(Mandatory)][string]$PolicyName,
        [Parameter(Mandatory)][string]$PolicyGuid
    )

    Write-Step ('Building WDAC supplemental policy XML: {0}' -f $XmlOutputPath)

    # Start with the AllowAll template
    $allowAllTemplate = "$env:windir\schemas\CodeIntegrity\ExamplePolicies\AllowAll.xml"
    if (-not (Test-Path $allowAllTemplate)) {
        # Older systems may not have the template - try alternate path
        $allowAllTemplate = "$env:windir\schemas\CodeIntegrity\ExamplePolicies\AllowMicrosoft.xml"
    }
    if (-not (Test-Path $allowAllTemplate)) {
        throw "WDAC AllowAll/AllowMicrosoft template not found in $env:windir\schemas\CodeIntegrity\ExamplePolicies\"
    }

    Copy-Item -Path $allowAllTemplate -Destination $XmlOutputPath -Force

    # Add our cert as a signer rule (kernel + user mode allow)
    Add-SignerRule -FilePath $XmlOutputPath -CertificatePath $CerPath -Kernel -User
    Set-CIPolicyIdInfo -FilePath $XmlOutputPath -PolicyName $PolicyName -PolicyId $PolicyGuid -SupplementsBasePolicyID '{A244370E-44C9-4C06-B551-F6016E563076}' -ErrorAction SilentlyContinue

    # Set as supplemental policy
    Set-RuleOption -FilePath $XmlOutputPath -Option 0  # Enabled:UMCI
    Set-RuleOption -FilePath $XmlOutputPath -Option 16 # Enabled:Update Policy No Reboot

    # Convert to binary.cip
    Write-Step ('ConvertFrom-CIPolicy -> {0}' -f $BinOutputPath)
    ConvertFrom-CIPolicy -XmlFilePath $XmlOutputPath -BinaryFilePath $BinOutputPath | Out-Null

    return @{
        XmlPath    = $XmlOutputPath
        BinPath    = $BinOutputPath
        PolicyName = $PolicyName
        PolicyGuid = $PolicyGuid
    }
}

function Install-WdacPolicy {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory)][string]$BinPath,
        [Parameter(Mandatory)][string]$PolicyGuid
    )

    $citool = Get-Command CiTool.exe -ErrorAction SilentlyContinue
    if ($citool) {
        # --json flag REQUIRED to suppress "Press Enter to Exit"
        # interactive prompt CiTool prints by default. Without it the
        # script blocks at I02 waiting for stdin. See SPEC D.16.
        Write-Step ('CiTool --update-policy --json "{0}"' -f $BinPath)
        $stdout = & $citool.Source --update-policy $BinPath --json 2>&1
        $exitCode = $LASTEXITCODE
        # Parse JSON for the canonical status line; fall back to raw.
        $statusLine = ''
        try {
            $j = ($stdout | Out-String) | ConvertFrom-Json -ErrorAction SilentlyContinue
            if ($j) {
                if ($j.OperationResult) { $statusLine = [string]$j.OperationResult }
                elseif ($j.Status)      { $statusLine = [string]$j.Status }
            }
        } catch { } # psa-disable-line PSA3004 -- intentional best-effort cleanup; no error to surface
        if ($statusLine) {
            Write-Skip ("    {0}" -f $statusLine)
        } else {
            foreach ($line in $stdout) {
                if ([string]$line -and [string]$line -ne '') { Write-Skip ("    {0}" -f $line) }
            }
        }
        return @{
            ExitCode = $exitCode
            Output   = $stdout
            Success  = ($exitCode -eq 0)
            Method   = 'CiTool'
            Status   = $statusLine
        }
    } else {
        # Older systems: copy CIP to active policy folder
        $activeDir = "$env:windir\System32\CodeIntegrity\CiPolicies\Active"
        if (-not (Test-Path $activeDir)) {
            New-Item -Path $activeDir -ItemType Directory -Force | Out-Null
        }
        $dest = Join-Path $activeDir ('{' + $PolicyGuid + '}.cip')
        Copy-Item -Path $BinPath -Destination $dest -Force

        # ---- WS2019 fallback: PS_UpdateAndCompareCIPolicy CIM method ----
        # WS2019 (build 17763) does not ship CiTool.exe but CAN hot-load
        # a supplemental policy via the WMI/CIM bridge in
        # root\Microsoft\Windows\CI. WS2016 lacks this class and falls
        # through to the original "reboot may be required" path.
        $cimSucceeded   = $false
        $cimError       = ''
        try {
            $cimResult = Invoke-CimMethod -Namespace 'root\Microsoft\Windows\CI' `
                -ClassName 'PS_UpdateAndCompareCIPolicy' `
                -MethodName 'Update' `
                -Arguments @{ FilePath = $dest } `
                -ErrorAction Stop
            if ($cimResult -and ([int]$cimResult.ReturnValue -eq 0)) {
                $cimSucceeded = $true
            }
        } catch {
            # CIM class not present (WS2016) or other failure
            $cimError = $_.Exception.Message
        }

        if ($cimSucceeded) {
            Write-Ok 'WS2019 CIM bridge (PS_UpdateAndCompareCIPolicy.Update): activated without reboot.'
            return @{
                ExitCode = 0
                Output   = @('Activated via PS_UpdateAndCompareCIPolicy')
                Success  = $true
                Method   = 'CIMBridge'
            }
        }

        Write-Caution 'CiTool not available; copied .cip to Active policy directory.'
        Write-Caution 'A reboot may be required for the policy to take effect.'
        if ($cimError) { Write-Detail ('  (WS2019 CIM bridge tried but failed: {0})' -f $cimError) }
        return @{
            ExitCode = 0
            Output   = @('Copied to Active dir')
            Success  = $true
            Method   = 'FileCopy'
            CimError = $cimError
        }
    }
}

function Remove-WdacPolicy {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$PolicyGuid)
    $citool = Get-Command CiTool.exe -ErrorAction SilentlyContinue
    if ($citool) {
        # --json flag suppresses CiTool's interactive ENTER prompt.
        Write-Step ('CiTool --remove-policy --json {{{0}}}' -f $PolicyGuid)
        & $citool.Source --remove-policy ('{' + $PolicyGuid + '}') --json 2>&1 | ForEach-Object {
            if ([string]$_ -and [string]$_ -ne '') { Write-Skip ("    {0}" -f $_) }
        }
    }
    # Also delete from Active dir if present
    $activePath = "$env:windir\System32\CodeIntegrity\CiPolicies\Active\{$PolicyGuid}.cip"
    if (Test-Path $activePath) {
        try {
            Remove-Item -Path $activePath -Force
            Write-Ok ('Removed: {0}' -f $activePath)
        } catch {
            Write-Caution ("Could not delete WDAC policy file: {0}" -f $_.Exception.Message)
        }
    }
}

# =============================================================================
# Driver install / cert trust (I01 / I03 / I04)
# =============================================================================
function Add-CertToTrustStore {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$CerPath
    )

    Write-Step ('Importing cert to LocalMachine\Root')
    Import-Certificate -FilePath $CerPath -CertStoreLocation Cert:\LocalMachine\Root | Out-Null

    Write-Step ('Importing cert to LocalMachine\TrustedPublisher')
    Import-Certificate -FilePath $CerPath -CertStoreLocation Cert:\LocalMachine\TrustedPublisher | Out-Null

    Write-Ok 'Cert successfully imported to LocalMachine trust stores.'
}

function Remove-CertFromTrustStore {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Thumbprint)
    foreach ($store in @('Cert:\LocalMachine\Root','Cert:\LocalMachine\TrustedPublisher')) {
        $cert = Get-ChildItem $store | Where-Object Thumbprint -EQ $Thumbprint
        if ($cert) {
            try {
                $cert | Remove-Item -Force
                Write-Ok ('Removed cert from {0}' -f $store)
            } catch {
                Write-Caution ("Could not remove cert from {0}: {1}" -f $store, $_.Exception.Message)
            }
        }
    }
}

function Install-PatchedDriver {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory)][string]$InfPath
    )

    Write-Step ('pnputil /add-driver "{0}" /install' -f $InfPath)
    $stdout = & pnputil.exe /add-driver $InfPath /install 2>&1
    $exitCode = $LASTEXITCODE

    foreach ($line in $stdout) {
        Write-Skip ("    {0}" -f $line)
    }

    return @{
        ExitCode = $exitCode
        Output   = $stdout
        Success  = ($exitCode -eq 0 -or $exitCode -eq 259 -or $exitCode -eq 3010)
    }
}

# =============================================================================
# Driver version comparison (timezone fix preserved)
# =============================================================================
function ConvertFrom-DriverVerString {
    <#
    .SYNOPSIS
        Parses an INF DriverVer string into structured date + version.
    #>
    [CmdletBinding()]
    [OutputType([hashtable])]
    param([Parameter(Mandatory)][string]$DriverVerString)

    $result = @{
        Date    = $null
        Version = $null
        Raw     = $DriverVerString
    }
    # Format: MM/DD/YYYY,Version (e.g. "07/08/2025,10.0.1.30")
    if ($DriverVerString -match '^(\d{1,2})/(\d{1,2})/(\d{4})\s*,\s*(.+)$') {
        try {
            $result.Date = [datetime]::ParseExact(
                ('{0:D2}/{1:D2}/{2}' -f [int]$Matches[1], [int]$Matches[2], $Matches[3]),
                'MM/dd/yyyy', [System.Globalization.CultureInfo]::InvariantCulture)
        } catch {
            # ignore
        }
        $vstr = $Matches[4].Trim()
        try {
            $result.Version = [version]$vstr
        } catch {
            $result.Version = $vstr
        }
    }
    return $result
}

function Compare-InfDriverVer {
    <#
    .SYNOPSIS
        Compares an installed driver's date/version (from Win32_PnPSignedDriver) vs a
        patched INF's DriverVer line.
    .NOTES
        Preserves chipset fix: Win32_PnPSignedDriver.DriverDate is stored as UTC
        midnight; CIM cmdlets convert to local time. Comparing .Date truncates to
        year/month/day to avoid timezone-induced false positives.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [datetime]$CurrentDate,
        $CurrentVersion,
        [datetime]$PatchedDate,
        $PatchedVersion
    )
    # Use.Date (year/month/day truncation) to avoid timezone mismatch
    $cdate = if ($CurrentDate) { $CurrentDate.Date } else { $null }
    $pdate = if ($PatchedDate) { $PatchedDate.Date } else { $null }

    # Version comparison
    $vCmp = 0
    try {
        $cv = if ($CurrentVersion -is [version]) { $CurrentVersion } else { [version]$CurrentVersion }
        $pv = if ($PatchedVersion -is [version]) { $PatchedVersion } else { [version]$PatchedVersion }
        $vCmp = $cv.CompareTo($pv)
    } catch {
        $vCmp = 0  # treat as equal if not parseable
    }

    if ($vCmp -lt 0) {
        return 'UpgradePatched'  # patched newer than current
    }
    if ($vCmp -gt 0) {
        return 'CurrentNewer'
    }
    # versions equal — compare dates
    if ($cdate -and $pdate) {
        if ($pdate -gt $cdate) {
            return 'SameVersionPatchedDateNewer'   # PnP ranking prefers newer date
        }
        if ($pdate -lt $cdate) {
            return 'SameVersionCurrentDateNewer'
        }
    }
    return 'Identical'
}


#####################################################################
# SECTION 1h: Legacy Windows Server OS detection helper
#####################################################################
# Generic OS-version predicate retained after the Path C deprecation.
# Used by the Q-X1 refuse check that prevents NPU -Action Install
# / -Action All on WS2019 / WS2016 (no physical-NPU validation exists
# on those OS versions yet). The function name keeps its historical
# form so existing call sites and future audits resolve cleanly.

function Test-IsLegacyWindowsServerOs { # psa-disable-line PSA6003 -- "Os" is singular; analyzer false positive on -os ending. The function name is a boolean predicate.
    # Returns $true on WS2019 (build 17763) and WS2016 (build 14393).
    # Returns $false on WS2022+, Windows client, and unknown builds.
    [OutputType([bool])]
    param()
    try {
        $os = Get-CimInstance Win32_OperatingSystem -ErrorAction Stop
    } catch {
        return $false
    }
    if ($os.ProductType -ne 2 -and $os.ProductType -ne 3) { return $false }
    $build = [int]([System.Environment]::OSVersion.Version.Build)
    return ($build -ge 14393 -and $build -lt 20348)
}


# =============================================================================
# Phase implementations P00 - P09 (Prep)
# =============================================================================

function Invoke-PrepPhase00_Initialize {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] $Ctx
    )
    Set-DebugStep 'show PS environment'
    Write-Step 'Running environment and sanity checks'

    Show-PowerShellEnvironment
    Assert-Admin
    Set-TlsSecurityProtocol
    Set-Utf8PipelineEncoding

    $os = Show-OperatingSystemDetail
    $Ctx.DetectedPlatform.OsCaption       = $os.OsCaption
    $Ctx.DetectedPlatform.OsBuild         = $os.OsBuild
    $Ctx.DetectedPlatform.OsProductType   = $os.OsProductType
    $Ctx.DetectedPlatform.OsProfile       = $os.OsProfile
    $Ctx.DetectedPlatform.Inf2CatOsSwitch = $os.Inf2CatOsSwitch
    $Ctx.DetectedPlatform.IsWorkstationOs = $os.IsWorkstationOs
    $Ctx.DetectedPlatform.IsServer2025    = $os.IsServer2025

    # (Q-X1; legacy WS2019): refuse NPU Install / All on legacy Windows Server
    # (WS2019 / WS2016) before any further initialization work runs. The
    # AMD NPU driver pipeline has not been validated on legacy Windows
    # Server SKUs that require the WDAC Single Policy Format (SPF) path,
    # and running it would exercise unvalidated SPF interaction code with
    # no physical-hardware test coverage. Non-destructive actions
    # (PrepareVerify, Verify, Prepare, Cleanup, ListPhases) remain
    # functional on legacy hosts so operators can still inspect the
    # workspace, run dry-runs, or clean up. See SPEC §D.27 and the
    # catastrophic field failure case study in SPEC §D.26.
    Set-DebugStep 'legacy Windows Server refuse check (Q-X1)'
    if ($Ctx.Action -in @('Install','All') -and (Test-IsLegacyWindowsServerOs)) {
        Write-Fail ''
        Write-Fail '========================================================================'
        Write-Fail (' NPU -Action {0} is NOT SUPPORTED on Windows Server 2019 / 2016.' -f $Ctx.Action)
        Write-Fail '========================================================================'
        Write-Fail ''
        Write-Fail '  The AMD NPU driver pipeline has not been validated on legacy Windows'
        Write-Fail '  Server SKUs (WS2019 / WS2016). The NPU script has no physical-hardware'
        Write-Fail '  test coverage on these OS versions, so running Install (or All, which'
        Write-Fail '  includes Install) on these hosts is refused as a safety measure.'
        Write-Fail ''
        Write-Fail '  Supported hosts for NPU Install:'
        Write-Fail '    - Windows Server 2025 (build 26100)  [primary target]'
        Write-Fail '    - Windows Server 2022 (build 20348)  [secondary]'
        Write-Fail ''
        Write-Fail '  Actions that REMAIN available on Windows Server 2019 / 2016:'
        Write-Fail '    - PrepareVerify (default) / Prepare / Verify / Cleanup / ListPhases'
        Write-Fail '    - These are non-destructive and do NOT modify the driver store.'
        Write-Fail ''
        Write-Fail '  If you need NPU support on WS2019/2016, please open a GitHub issue;'
        Write-Fail '  the path can be enabled after dedicated physical validation.'
        Write-Fail ''
        throw ('NPU -Action {0} refused on legacy Windows Server. See message above.' -f $Ctx.Action)
    }

    # NPU-specific OS support warning
    Write-Host ''
    Write-SubHeader2 'Ryzen AI Software OS support note'
    Set-DebugStep 'workstation install guard check'
    Write-Caution 'AMD officially supports Ryzen AI Software ONLY on Windows 11 (build >= 22621.3527).'
    Write-Caution 'Windows Server 2025 is NOT in AMD''s supported OS matrix.'
    Write-Caution 'This script patches the kernel-mode NPU driver to install on Server, but the'
    Write-Caution 'user-mode Ryzen AI Software stack (conda env, OGA, Vitis AI EP) will likely'
    Write-Caution 'not function on Server 2025 without unofficial workarounds.'
    Write-Host ''

    # ---- UEFI Secure Boot certificate baseline (port from chipset/graphics) ----
    # Capture once at P00 and cache on $Ctx.DetectedPlatform so later
    # phases (P05 report append, V05 / V06 display, I02 pre-check) can
    # reuse the same snapshot without re-invoking the Microsoft sample
    # script multiple times. The snapshot function uses New-Item -Force
    # internally so the WorkRoot directory is auto-created if it does
    # not exist yet (P01 hasn't run); subsequent phases revisit the
    # snapshot via Get-OrEnsureSecureBootBaseline which detects a
    # missing diagnostic file (e.g. when -CleanWorkRoot wipes it at
    # P01) and re-captures.
    try {
        $Ctx.DetectedPlatform.SecureBootBaseline = Get-SecureBootBaselineSnapshot -WorkRoot $Ctx.WorkRoot
        Show-SecureBootBaselineSnapshot -Snapshot $Ctx.DetectedPlatform.SecureBootBaseline -Compact
    } catch {
        Write-Caution ("Secure Boot baseline capture failed: {0}" -f $_.Exception.Message)
    }
}

function Resume-CtxFromWorkspace {
    <#
    .SYNOPSIS
        Rebuild a SUBSET of $Ctx properties from artifacts already
        present in the workspace. Called from P01 to support
        non-Prepare run modes (-Action Verify, -Action Install
        -OnlyPhases I01).
    .DESCRIPTION
        Unlike BthPan (single bthpan.inf), AMD NPU drivers
        contain MULTIPLE INFs whose patched artifacts cannot be
        fully reconstructed without re-running P05-P06 analysis.
        This helper therefore restores only the artifacts that CAN
        be deduced from the on-disk workspace alone:
          - Cert PFX path    (Paths.Cert\AMD-NPU-Driver-CodeSign.pfx)
          - Cert CER path    (Paths.Cert\AMD-NPU-Driver-CodeSign.cer)
          - Cert Thumbprint  (decoded from CER via X509Certificate2)
          - Patched subdirs  (each subdir under Paths.Patched - candidates
                              for pnputil)

        Result: -Action Verify against a populated workspace now
        resolves the cert triad without re-running P02-P09.
        -Action Install -OnlyPhases I01 (cert trust import) and I02
        (WDAC policy keyed by cert thumbprint) can also use this set.

        Failures are non-fatal: each branch swallows its own error,
        leaves the property $null/empty, and lets downstream
        preconditions raise a clearer error.

        an earlier revision (2026-05-17) - ported from the BthPan sister script's
        rehydration helper, simplified for the multi-INF AMD case
        (full PatchResults / InfInventory restoration deferred).
    #>
    param($Ctx)
    if (-not $Ctx.Paths) { return }
    $rehydrated = New-Object System.Collections.Generic.List[string]

    # ----- Cert PFX -----
    if (-not $Ctx.CertPfxPath) {
        try {
            $pfx = Join-Path $Ctx.Paths.Cert 'AMD-NPU-Driver-CodeSign.pfx'
            if (Test-Path -LiteralPath $pfx) {
                $Ctx.CertPfxPath = $pfx
                $rehydrated.Add('CertPfxPath') | Out-Null
            }
        } catch {} # psa-disable-line PSA3004 -- best-effort scan; missing artifact = leave $null
    }

    # ----- Cert CER + Thumbprint (decoded from CER on disk) -----
    if (-not $Ctx.CertCerPath) {
        try {
            $cer = Join-Path $Ctx.Paths.Cert 'AMD-NPU-Driver-CodeSign.cer'
            if (Test-Path -LiteralPath $cer) {
                $Ctx.CertCerPath = $cer
                $rehydrated.Add('CertCerPath') | Out-Null
                if (-not $Ctx.CertThumbprint) {
                    try {
                        $x509 = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2 $cer
                        $Ctx.CertThumbprint = $x509.Thumbprint
                        $rehydrated.Add('CertThumbprint') | Out-Null
                    } catch {} # psa-disable-line PSA3004
                }
            }
        } catch {} # psa-disable-line PSA3004
    }

    # ----- Patched subdirs (each is a pnputil candidate) -----
    if (-not $Ctx.PatchedDirs -or $Ctx.PatchedDirs.Count -eq 0) {
        try {
            if (Test-Path -LiteralPath $Ctx.Paths.Patched) {
                $dirs = @(Get-ChildItem -LiteralPath $Ctx.Paths.Patched -Directory -ErrorAction SilentlyContinue |
                            ForEach-Object { $_.FullName })
                if ($dirs.Count -gt 0) {
                    $Ctx.PatchedDirs = $dirs
                    $rehydrated.Add(('PatchedDirs ({0})' -f $dirs.Count)) | Out-Null
                }
            }
        } catch {} # psa-disable-line PSA3004
    }

    if ($rehydrated.Count -gt 0) {
        Write-Detail ('Rehydrated from existing workspace: {0}' -f ($rehydrated.ToArray() -join ', '))
    }
}

function Invoke-PrepPhase01_PrepareWorkspace {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] $Ctx
    )

    Set-DebugStep 'optional: wipe existing workspace (-CleanWorkRoot)'
    if ($Ctx.CleanWorkRoot -and (Test-Path $Ctx.WorkRoot)) {
        Write-Step ("CleanWorkRoot: removing {0}" -f $Ctx.WorkRoot)
        Remove-Item -Path $Ctx.WorkRoot -Recurse -Force -ErrorAction SilentlyContinue
    }

    Set-DebugStep 'create workspace subdirectories'
    foreach ($dir in @($Ctx.WorkRoot, $Ctx.DownloadDir, $Ctx.ExtractedDir, $Ctx.PatchedDir, $Ctx.CertDir)) {
        if (-not (Test-Path $dir)) {
            New-Item -Path $dir -ItemType Directory -Force | Out-Null
            Write-Skip ("Created: {0}" -f $dir)
        } else {
            Write-Skip ("Existing: {0}" -f $dir)
        }
    }
    Write-Ok ("Workspace ready at: {0}" -f $Ctx.WorkRoot)

    # Detect and log pre-existing workspace artifacts so that
    # -Action Verify / -Action Install (-OnlyPhases I01) running
    # against a populated workspace surfaces explicit confirmation.
    # See function Resume-CtxFromWorkspace above for design notes.
    Set-DebugStep 'rehydrate from existing workspace artifacts'
    Resume-CtxFromWorkspace -Ctx $Ctx
}

function Invoke-PrepPhase02_AcquireTools { # psa-disable-line PSA6003 -- compound noun (e.g., Policies, Drivers, Catalogs) is semantically plural for set-returning helpers
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] $Ctx
    )
    Set-DebugStep 'delegate to Initialize-ToolingStack'
    Write-Step 'Acquiring signtool, inf2cat, and 7-Zip'
    $tools = Install-RequiredTools
    $Ctx.DetectedPlatform.SignToolPath = $tools.SignTool
    $Ctx.DetectedPlatform.Inf2CatPath  = $tools.Inf2Cat
    $Ctx.DetectedPlatform.SevenZipPath = $tools.SevenZip
}

function Invoke-PrepPhase03_FetchInstaller {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] $Ctx
    )
    Set-DebugStep 'detect NPU platform and resolve installer source'
    Write-Step 'Detecting NPU platform and resolving installer source (4-tier fallback)'

    # ----- detect NPU platform
    Write-SubHeader2 'NPU platform detection'
    $npu = Get-AmdNpuPlatform `
        -Override $Ctx.NpuOverride `
        -AssumeIfMissing:$Ctx.AssumeIfMissing `
        -NpuDriverPackageSelection $Ctx.NpuDriverPackage `
        -RyzenAiSoftwareVersionSelection $Ctx.RyzenAiSoftwareVersion

    $Ctx.DetectedPlatform.NpuCodename             = $npu.NpuCodename
    $Ctx.DetectedPlatform.NpuShortName            = $npu.NpuShortName
    $Ctx.DetectedPlatform.NpuHardwareId           = $npu.HardwareId
    $Ctx.DetectedPlatform.NpuRevision             = $npu.Revision
    $Ctx.DetectedPlatform.NpuIsDetected           = $npu.IsDetected
    $Ctx.DetectedPlatform.NpuDetectionSource      = $npu.DetectionSource
    $Ctx.DetectedPlatform.CpuName                 = $npu.CpuName
    # NPU driver fields (independent axis)
    $Ctx.DetectedPlatform.NpuDriverPackage        = $npu.NpuDriverPackage
    $Ctx.DetectedPlatform.NpuDriverBuild          = $npu.NpuDriverBuild
    $Ctx.DetectedPlatform.NpuDriverZipName        = $npu.NpuDriverZipName
    # Ryzen AI Software fields (independent axis)
    $Ctx.DetectedPlatform.RyzenAiSoftwareVersion  = $npu.RyzenAiSoftwareVersion
    $Ctx.DetectedPlatform.RyzenAiSoftwareInstaller = $npu.RyzenAiSoftwareInstaller
    # Compatibility evaluation (separate axis)
    $Ctx.DetectedPlatform.DriverSoftwareCompatible = $npu.DriverSoftwareCompatible
    $Ctx.DetectedPlatform.DriverSoftwareCompatNote = $npu.DriverSoftwareCompatNote

    Write-Ok ('CPU                  : {0}' -f $npu.CpuName)
    Write-Ok ('NPU codename         : {0}' -f $npu.NpuCodename)
    Write-Ok ('NPU short name       : {0}' -f $npu.NpuShortName)
    Write-Ok ('Hardware ID          : {0}' -f $npu.HardwareId)
    Write-Ok ('Detection source     : {0}' -f $npu.DetectionSource)
    Write-Ok ('Detected on host     : {0}' -f $npu.IsDetected)
    Write-Host ''
    Write-Step '----- NPU kernel-mode driver (independent versioning axis) -----'
    Write-Ok ('NPU driver package   : {0}' -f $npu.NpuDriverPackage)
    Write-Ok ('NPU driver build     : {0}' -f $npu.NpuDriverBuild)
    Write-Ok ('NPU driver ZIP name  : {0}' -f $npu.NpuDriverZipName)
    Write-Host ''
    Write-Step '----- Ryzen AI Software (independent versioning axis - always latest unless pinned) -----'
    Write-Ok ('RAI Software version : {0}' -f $npu.RyzenAiSoftwareVersion)
    Write-Ok ('RAI Software EXE     : {0}' -f $npu.RyzenAiSoftwareInstaller)
    Write-Host ''
    Write-Step '----- Driver <-> RAI Software compatibility (separate evaluation axis) -----'
    if ($npu.DriverSoftwareCompatible) {
        Write-Ok ('Compatibility        : OK')
    } else {
        Write-Caution ('Compatibility        : MISMATCH')
    }
    Write-Skip ('Note                 : {0}' -f $npu.DriverSoftwareCompatNote)

    if (-not $npu.IsDetected) {
        Write-Host ''
        Write-Caution '------------------------------------------------------------------'
        Write-Caution 'NPU was NOT detected on the host (proceeding with default profile).'
        Write-Caution 'Driver Install (I03) will likely produce 0 device bindings here.'
        Write-Caution 'This run is useful for pipeline regression testing only.'
        Write-Caution '------------------------------------------------------------------'
        Write-Host ''
    }

    # ----- resolve and download package
    Write-SubHeader2 'NPU driver package resolution & download'
    $resolved = Resolve-AmdNpuDriverUrl -Ctx $Ctx `
        -NpuPlatform $npu `
        -ExplicitInstallerUrl $Ctx.InstallerUrl `
        -ExplicitOfflineZip $Ctx.OfflineZip `
        -AmdAccountUser $Ctx.AmdAccountUser `
        -AmdAccountPassword $Ctx.AmdAccountPassword

    if (-not $resolved) {
        throw 'Could not resolve NPU driver package source.'
    }

    $Ctx.DetectedPlatform.DownloadedZipPath = $resolved.LocalPath
    $Ctx.DetectedPlatform.DownloadedZipName = Split-Path $resolved.LocalPath -Leaf
    $Ctx.DetectedPlatform.DownloadSourceType = $resolved.SourceType
    $Ctx.DetectedPlatform.DownloadSourceUrl  = $resolved.SourceUrl

    Write-Host ''
    Write-Ok ('Source type   : {0}' -f $resolved.SourceType)
    Write-Ok ('Local ZIP path: {0}' -f $resolved.LocalPath)
    if ($resolved.SourceUrl) {
        Write-Ok ('Source URL    : {0}' -f $resolved.SourceUrl)
    }
    $size = (Get-Item $resolved.LocalPath).Length
    Write-Ok ('Size          : {0:n1} MB' -f ($size / 1MB))
}

function Invoke-PrepPhase04_ExtractInstaller {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] $Ctx
    )

    Set-DebugStep 'precondition: DownloadedZipPath and 7z available'
    if (-not $Ctx.DetectedPlatform.DownloadedZipPath) {
        throw 'No downloaded ZIP path; P03 did not complete successfully.'
    }
    if (-not $Ctx.DetectedPlatform.SevenZipPath) {
        throw 'No 7-Zip path; P02 did not complete successfully.'
    }

    $extracted = Expand-AmdNpuPackage `
        -ZipPath $Ctx.DetectedPlatform.DownloadedZipPath `
        -DestinationDir $Ctx.ExtractedDir `
        -SevenZipPath $Ctx.DetectedPlatform.SevenZipPath

    $Ctx.DetectedPlatform.ExtractedInfFiles = $extracted.InfFiles
    $Ctx.DetectedPlatform.ExtractedCatFiles = $extracted.CatFiles
    $Ctx.DetectedPlatform.ExtractedSysFiles = $extracted.SysFiles
    $Ctx.DetectedPlatform.ExtractedExeFiles = $extracted.ExeFiles
}

function Invoke-PrepPhase05_AnalyzeInfs { # psa-disable-line PSA6003 -- compound noun (e.g., Policies, Drivers, Catalogs) is semantically plural for set-returning helpers
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] $Ctx
    )
    Set-DebugStep 'inventory INF files and parse target NPU'
    Write-Step 'Inventorying INFs and filtering for target NPU'

    $infs = $Ctx.DetectedPlatform.ExtractedInfFiles
    if (-not $infs -or $infs.Count -eq 0) {
        throw 'No INF files to analyze; P04 did not extract any.'
    }

    Write-Ok ('Found {0} INF file(s) in extracted package.' -f $infs.Count)
    Set-DebugStep 'parse each INF for HW IDs and decorations'

    $inventory = New-Object 'System.Collections.Generic.List[psobject]'
    foreach ($inf in $infs) {
        Write-Step ('Parsing: {0}' -f $inf.Name)
        $parsed = Read-InfManufacturer -InfPath $inf.FullName

        # Determine if this INF claims an HWID matching our target NPU
        $matchesTarget = $false
        $matchedHwids = @()
        $targetPattern = $null
        switch ($Ctx.DetectedPlatform.NpuShortName) {
            'PHX' { $targetPattern = 'VEN_1022&DEV_1502' }
            'HPT' { $targetPattern = 'VEN_1022&DEV_1502' }
            'STX' { $targetPattern = 'VEN_1022&DEV_17F0' }
            'KRK' { $targetPattern = 'VEN_1022&DEV_17F0' }
        }
        if (-not [string]::IsNullOrEmpty($targetPattern)) {
            foreach ($hwidEntry in $parsed.HwidEntries) {
                if ($hwidEntry.HardwareId -match $targetPattern) { # psa-disable-line PSA2003 -- pattern variable is initialized in the enclosing scope; $null impossible by construction
                    $matchesTarget = $true
                    $matchedHwids += $hwidEntry.HardwareId
                }
            }
        }

        $hwidPreview = if ($parsed.HwidEntries.Count -gt 0) {
            $parsed.HwidEntries | Select-Object -First 3 | ForEach-Object { $_.HardwareId } | Out-String
        } else { '(none)' }

        $entry = [pscustomobject]@{
            FileName             = $inf.Name
            FullPath             = $inf.FullName
            Provider             = $parsed.Provider
            DriverVer            = $parsed.DriverVer
            Class                = $parsed.Class
            HwidCount            = $parsed.HwidEntries.Count
            MatchesTargetNpu     = $matchesTarget
            MatchedHwidCount     = $matchedHwids.Count
            HasServerDecoration  = $parsed.HasServerDecoration
            WorkstationDecCount  = $parsed.WorkstationDecorations.Count
            ServerDecCount       = $parsed.ServerDecorations.Count
            NeedsPatch           = ($parsed.WorkstationDecorations.Count -gt 0)
            SelectedForPipeline  = $matchesTarget   # primary filter
            HwidPreview          = $hwidPreview.Trim()
        }
        $inventory.Add($entry)
    }

    Write-Host ''
    Write-SubHeader2 'INF inventory'
    $fmt = "{0,-30} {1,-12} {2,-7} {3,-9} {4,-9} {5,-9} {6,-7}"
    Write-Host ($fmt -f 'INF', 'Provider', 'Class', 'HWIDs', 'Matches', 'NeedsPatch', 'Select')
    Write-Host ($fmt -f '-' * 30, '-' * 12, '-' * 7, '-' * 9, '-' * 9, '-' * 9, '-' * 7)
    foreach ($e in $inventory) {
        $providerShort = if ($e.Provider) { $e.Provider.Substring(0, [Math]::Min(11, $e.Provider.Length)) } else { '-' }
        $classShort = if ($e.Class) { $e.Class.Substring(0, [Math]::Min(6, $e.Class.Length)) } else { '-' }
        Write-Host ($fmt -f $e.FileName, $providerShort, $classShort, $e.HwidCount, $e.MatchedHwidCount, $e.NeedsPatch, $e.SelectedForPipeline)
    }

    # CSV export
    $inventory | Export-Csv -Path $Ctx.InventoryCsvPath -NoTypeInformation -Encoding UTF8
    Write-Skip ("Inventory CSV: {0}" -f $Ctx.InventoryCsvPath)

    $selected = $inventory | Where-Object SelectedForPipeline
    Write-Host ''
    Write-Ok ('Total INFs        : {0}' -f $inventory.Count)
    Write-Ok ('Selected (matches): {0}' -f $selected.Count)
    Write-Ok ('Need patch (Wstn) : {0}' -f (($inventory | Where-Object NeedsPatch).Count))

    if ($selected.Count -eq 0) {
        Write-Caution 'No INFs matched the target NPU codename. Pipeline will copy all INFs through anyway (will not bind).'
        # In that case, select all so they reach P06/P08/P09
        foreach ($e in $inventory) { $e.SelectedForPipeline = $true }
    }

    $Ctx.DetectedPlatform.InfInventory = $inventory

    # ---- Write inf_inventory_report.txt (text-format inventory + Secure Boot baseline appendix) ----
    # Previously, $Ctx.InventoryReportPath was declared but never written.
    # We now populate it so artefacts are aligned with the chipset / graphics
    # scripts (which both produce an inf_inventory_report.txt with a UEFI
    # Secure Boot Baseline appendix at the end). NPU's inventory is much
    # smaller than the sister scripts (typically 1-3 INFs for a single NPU
    # device), so the body is generated inline rather than via a dedicated
    # Export-InfInventoryReport function.
    try {
        $sbSnap = Get-OrEnsureSecureBootBaseline -Ctx $Ctx
        $sbReport = New-Object System.Text.StringBuilder
        [void]$sbReport.AppendLine('AMD NPU Driver - INF Inventory Report')
        [void]$sbReport.AppendLine(('=' * 78))
        [void]$sbReport.AppendLine(("Generated      : {0}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')))
        [void]$sbReport.AppendLine(("Host OS        : {0}" -f $Ctx.DetectedPlatform.OsCaption))
        [void]$sbReport.AppendLine(("NPU codename   : {0}  ({1})" -f $Ctx.DetectedPlatform.NpuCodename, $Ctx.DetectedPlatform.NpuShortName))
        [void]$sbReport.AppendLine(("Target HWID    : {0}" -f $Ctx.DetectedPlatform.NpuHardwareId))
        [void]$sbReport.AppendLine(("Total INFs     : {0}" -f $inventory.Count))
        [void]$sbReport.AppendLine(("Selected       : {0}" -f ($inventory | Where-Object SelectedForPipeline).Count))
        [void]$sbReport.AppendLine('')

        foreach ($e in $inventory) {
            $marker = if ($e.SelectedForPipeline) { '[SELECTED]' } else { '[ skip   ]' }
            [void]$sbReport.AppendLine(('=' * 78))
            [void]$sbReport.AppendLine(("$marker  INF: {0}" -f $e.FileName))
            [void]$sbReport.AppendLine(('=' * 78))
            [void]$sbReport.AppendLine(("Provider       : {0}" -f $e.Provider))
            [void]$sbReport.AppendLine(("Class          : {0}" -f $e.Class))
            [void]$sbReport.AppendLine(("DriverVer      : {0}" -f $e.DriverVer))
            [void]$sbReport.AppendLine(("HWIDs (total)  : {0}" -f $e.HwidCount))
            [void]$sbReport.AppendLine(("HWIDs (match)  : {0}" -f $e.MatchedHwidCount))
            [void]$sbReport.AppendLine(("Needs patch    : {0}" -f $e.NeedsPatch))
            [void]$sbReport.AppendLine(("HWID preview   :"))
            foreach ($hwLine in ($e.HwidPreview -split "[`r`n]+")) {
                if ($hwLine.Trim()) { [void]$sbReport.AppendLine(("  {0}" -f $hwLine.Trim())) }
            }
            [void]$sbReport.AppendLine('')
        }

        if ($sbSnap) {
            $appendix = Format-SecureBootBaselineForReport -Snapshot $sbSnap
            if ($appendix) {
                [void]$sbReport.AppendLine('')
                [void]$sbReport.Append($appendix)
            }
        }

        Set-Content -LiteralPath $Ctx.InventoryReportPath -Value $sbReport.ToString() -Encoding UTF8
        Write-Skip ("Inventory text report: {0}" -f $Ctx.InventoryReportPath)
    } catch {
        Write-Caution ("inf_inventory_report.txt generation failed (non-fatal): {0}" -f $_.Exception.Message)
    }
}

function Invoke-PrepPhase06_PatchInfs { # psa-disable-line PSA6003 -- compound noun (e.g., Policies, Drivers, Catalogs) is semantically plural for set-returning helpers
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] $Ctx
    )
    Set-DebugStep 'mirror Workstation decorations as ProductType=3'
    Write-Step 'Mirroring Workstation [Manufacturer] decorations as ProductType=3'

    $inventory = $Ctx.DetectedPlatform.InfInventory
    if (-not $inventory) {
        throw 'No INF inventory; P05 did not complete.'
    }

    $patched   = 0
    $copied    = 0
    $failed    = 0
    foreach ($e in $inventory | Where-Object SelectedForPipeline) {
        $outPath = Join-Path $Ctx.PatchedDir $e.FileName
        Write-Step ('Processing: {0}' -f $e.FileName)
        try {
            $r = Add-ProductType3Decoration -InputInfPath $e.FullPath -OutputInfPath $outPath
            if ($r.Patched -and $r.MirroredCount -gt 0) {
                Write-Ok ('  Mirrored {0} decoration(s) -> {1}' -f $r.MirroredCount, $outPath)
                $patched++
            } elseif ($r.Patched) {
                Write-Skip ('  Already Server-compatible, copied to {0}' -f $outPath)
                $copied++
            } else {
                Write-Caution ('  No patch applied: {0}' -f $r.Reason)
                $failed++
            }

            # Also copy associated.cat /.sys /.pdb / etc to patched dir (sibling files)
            $sourceDir = Split-Path $e.FullPath -Parent
            Get-ChildItem -Path $sourceDir -File | Where-Object {
                $_.Extension -in @('.cat','.sys','.dll','.pdb','.man','.cab','.exe','.bin','.xml','.json')
            } | ForEach-Object {
                $destFile = Join-Path $Ctx.PatchedDir $_.Name
                if (-not (Test-Path $destFile)) {
                    Copy-Item -Path $_.FullName -Destination $destFile -Force
                }
            }
        } catch {
            Write-Fail ('  Patch failed: {0}' -f $_.Exception.Message)
            $failed++
        }
    }

    Write-Host ''
    Set-DebugStep 'summary: report patched/copied/failed counts'
    Write-Ok ('Patched          : {0} INF(s)' -f $patched)
    Write-Ok ('Server-compat copy: {0} INF(s)' -f $copied)
    Write-Ok ('Failed           : {0} INF(s)' -f $failed)
}

function Invoke-PrepPhase07_CreateCertificate {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] $Ctx
    )
    Set-DebugStep 'delegate to New-CodeSignCert'

    $cert = New-SelfSignedCodeSigningCert `
        -Subject $Ctx.CertSubjectCn `
        -PfxPath $Ctx.PfxPath `
        -CerPath $Ctx.CerPath `
        -PfxPassword $PfxPassword `
        -ValidityYears $CertValidityYears

    $Ctx.DetectedPlatform.Cert = $cert
    # Mirror the Chipset / Graphics canon: persist the thumbprint at
    # $Ctx.CertThumbprint so the Tier B-4 helpers ported verbatim from
    # the Chipset canon (Get-BootSigningEnvironment, Show-BootSigningEnvironment,
    # Invoke-Cleanup) can read it without re-loading the PFX from disk.
    # Resume-CtxFromWorkspace populates the same property on the
    # Verify / Install paths where this phase is not re-run.
    $Ctx.CertThumbprint = $cert.Thumbprint
}

function Invoke-PrepPhase08_GenerateCatalogs { # psa-disable-line PSA6003 -- compound noun (e.g., Policies, Drivers, Catalogs) is semantically plural for set-returning helpers
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] $Ctx
    )

    Set-DebugStep 'precondition: Inf2CatPath available'
    if (-not $Ctx.DetectedPlatform.Inf2CatPath) {
        throw 'inf2cat path not resolved; P02 did not complete.'
    }

    Set-DebugStep 'run inf2cat against patched/'
    $r = Invoke-Inf2Cat `
        -Inf2CatPath $Ctx.DetectedPlatform.Inf2CatPath `
        -DriverDir $Ctx.PatchedDir `
        -OsSwitch $Ctx.DetectedPlatform.Inf2CatOsSwitch

    if (-not $r.Success) {
        Write-Fail ('inf2cat exit code: {0}' -f $r.ExitCode)
        throw 'inf2cat failed.'
    }

    $cats = Get-ChildItem -Path $Ctx.PatchedDir -Filter '*.cat' -File
    Write-Ok ('Generated {0} catalog file(s):' -f $cats.Count)
    foreach ($c in $cats) {
        Write-Skip ('  {0}' -f $c.Name)
    }
    $Ctx.DetectedPlatform.PatchedCatFiles = $cats
}

function Invoke-PrepPhase09_SignCatalogs { # psa-disable-line PSA6003 -- compound noun (e.g., Policies, Drivers, Catalogs) is semantically plural for set-returning helpers
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] $Ctx
    )

    Set-DebugStep 'precondition: SignToolPath available'
    if (-not $Ctx.DetectedPlatform.SignToolPath) {
        throw 'signtool path not resolved; P02 did not complete.'
    }

    $cats = Get-ChildItem -Path $Ctx.PatchedDir -Filter '*.cat' -File
    if ($cats.Count -eq 0) {
        throw 'No catalogs to sign.'
    }

    $signed = 0
    $failed = 0
    foreach ($c in $cats) {
        Write-Step ('Signing: {0}' -f $c.Name)
        $r = Invoke-SignTool `
            -SignToolPath $Ctx.DetectedPlatform.SignToolPath `
            -CatPath $c.FullName `
            -PfxPath $Ctx.PfxPath `
            -PfxPassword $PfxPassword `
            -TimestampUrl $Ctx.TimestampUrl `
            -HashAlgo 'SHA384'
        if ($r.Success) {
            $signed++
            Write-Ok ('  Signed OK ({0:n1}s)' -f $r.Duration)
        } else {
            $failed++
            Write-Fail ('  Sign FAILED (exit {0})' -f $r.ExitCode)
        }
    }
    Set-DebugStep 'summary: report signed/failed counts'
    Write-Ok ('Signed: {0} catalog(s); Failed: {1}' -f $signed, $failed)
    if ($failed -gt 0) {
        throw 'Some catalogs failed to sign.'
    }
}
# =============================================================================
# Phase implementations V01 - V06 (Verify)
# =============================================================================

function Invoke-VerifyPhase01_VerifyArtifacts { # psa-disable-line PSA6003 -- compound noun (e.g., Policies, Drivers, Catalogs) is semantically plural for set-returning helpers
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] $Ctx
    )
    Set-DebugStep 'verify cert + patched INFs + catalogs all exist'
    Write-Step 'Verifying cert + patched INFs + catalogs all exist'

    $ok = $true

    Set-DebugStep 'check PFX/CER/INF/catalog presence on disk'
    if (-not (Test-Path $Ctx.PfxPath)) {
        Write-Fail ('Missing PFX: {0}' -f $Ctx.PfxPath)
        $ok = $false
    } else {
        Write-Ok ('PFX present: {0}' -f $Ctx.PfxPath)
    }
    if (-not (Test-Path $Ctx.CerPath)) {
        Write-Fail ('Missing CER: {0}' -f $Ctx.CerPath)
        $ok = $false
    } else {
        Write-Ok ('CER present: {0}' -f $Ctx.CerPath)
    }

    $infs = Get-ChildItem -Path $Ctx.PatchedDir -Filter '*.inf' -File -ErrorAction SilentlyContinue
    Write-Ok ('Patched INFs: {0}' -f $infs.Count)
    if ($infs.Count -eq 0) { $ok = $false }

    $cats = Get-ChildItem -Path $Ctx.PatchedDir -Filter '*.cat' -File -ErrorAction SilentlyContinue
    Write-Ok ('Catalogs    : {0}' -f $cats.Count)
    if ($cats.Count -eq 0) { $ok = $false }

    if (-not $ok) { throw 'V01 detected missing artifacts.' }
}

function Invoke-VerifyPhase02_VerifyCertificate {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] $Ctx
    )
    Set-DebugStep 'check EKU, key length, and validity period'
    Write-Step 'Checking EKU, key length, and validity period'

    $pfxSecure = ConvertTo-SecureString -String 'placeholder' -AsPlainText -Force
    $cert = $null
    try {
    Set-DebugStep 'load PFX via X509Certificate2 (with fallback)'
        if ([string]::IsNullOrEmpty($PfxPassword)) {
            $cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2($Ctx.PfxPath, '', 'Exportable,PersistKeySet')
        } else {
            $cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2($Ctx.PfxPath, $PfxPassword, 'Exportable,PersistKeySet')
        }
    } catch {
        Write-Caution ('Could not load with placeholder password; trying empty: {0}' -f $_.Exception.Message)
        try {
            $cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2($Ctx.PfxPath)
        } catch {
            throw "Could not load PFX: $($_.Exception.Message)"
        }
    }

    Set-DebugStep 'dump cert attributes (Subject/Thumbprint/Validity)'
    Write-Ok ('Subject     : {0}' -f $cert.Subject)
    Write-Ok ('Thumbprint  : {0}' -f $cert.Thumbprint)
    Write-Ok ('NotBefore   : {0:yyyy-MM-dd}' -f $cert.NotBefore)
    Write-Ok ('NotAfter    : {0:yyyy-MM-dd} ({1} days from now)' -f $cert.NotAfter, [Math]::Round(($cert.NotAfter - (Get-Date)).TotalDays))
    Write-Ok ('Sig algo    : {0}' -f $cert.SignatureAlgorithm.FriendlyName)

    $rsaPub = $cert.PublicKey.Key
    if ($rsaPub) {
        Write-Ok ('Key size    : {0} bits' -f $rsaPub.KeySize)
    }

    # Check EKU = Code Signing
    $hasCodeSigningEku = $false
    foreach ($ext in $cert.Extensions) {
        if ($ext.Oid.Value -eq '2.5.29.37') {
            $eku = $ext -as [System.Security.Cryptography.X509Certificates.X509EnhancedKeyUsageExtension]
            if ($eku) {
                foreach ($oid in $eku.EnhancedKeyUsages) {
                    if ($oid.Value -eq '1.3.6.1.5.5.7.3.3') {
                        $hasCodeSigningEku = $true
                        break
                    }
                }
            }
        }
    }
    if ($hasCodeSigningEku) {
        Write-Ok 'EKU         : Code Signing (1.3.6.1.5.5.7.3.3) PRESENT'
    } else {
        Write-Caution 'EKU         : Code Signing NOT present!'
    }
}

function Invoke-VerifyPhase03_VerifyCatalogs { # psa-disable-line PSA6003 -- compound noun (e.g., Policies, Drivers, Catalogs) is semantically plural for set-returning helpers
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] $Ctx
    )
    Set-DebugStep 'run signtool verify /pa on each catalog'
    Write-Step 'Running signtool verify /pa on each catalog'
    Write-Skip 'NOTE: Verification will FAIL until I01 imports the cert into trust stores.'
    Write-Skip '      That failure is expected here.'

    $cats = Get-ChildItem -Path $Ctx.PatchedDir -Filter '*.cat' -File
    $ok = 0; $fail = 0
    Set-DebugStep 'verify each catalog (loop)'
    foreach ($c in $cats) {
        $r = Test-CatalogSignature -SignToolPath $Ctx.DetectedPlatform.SignToolPath -CatPath $c.FullName
        if ($r.Success) {
            $ok++
            Write-Skip ('  {0} OK' -f $c.Name)
        } else {
            $fail++
            Write-Skip ('  {0} not yet trusted (expected)' -f $c.Name)
        }
    }
    Write-Ok ('Verify pass : {0}' -f $ok)
    Write-Ok ('Verify fail : {0}  (expected before I01)' -f $fail)
}

function Invoke-VerifyPhase04_VerifyInfs { # psa-disable-line PSA6003 -- compound noun (e.g., Policies, Drivers, Catalogs) is semantically plural for set-returning helpers
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] $Ctx
    )
    Set-DebugStep 'verify ProductType=3 decoration coverage'
    Write-Step 'Verifying ProductType=3 decoration coverage'

    $build = $Ctx.DetectedPlatform.OsBuild
    $infs = Get-ChildItem -Path $Ctx.PatchedDir -Filter '*.inf' -File
    $covered = 0; $uncovered = 0
    Set-DebugStep 'check each INF for Server decoration (loop)'
    foreach ($inf in $infs) {
        $r = Test-InfProductTypeCoverage -InfPath $inf.FullName -ExpectedBuild $build
        if ($r.HasServerForBuild) {
            $covered++
            Write-Skip ('  {0,-30}  Server-decorated for build {1}' -f $r.InfName, $build)
        } else {
            $uncovered++
            if ($r.WorkstationOnly) {
                Write-Caution ('  {0,-30}  Workstation-only (no .3 decoration)' -f $r.InfName)
            } else {
                Write-Skip ('  {0,-30}  No build-{1} decoration (no Manufacturer entries?)' -f $r.InfName, $build)
            }
        }
    }
    Write-Ok ('INFs with build-{0} ProductType=3: {1}' -f $build, $covered)
    Write-Ok ('INFs without              : {0}' -f $uncovered)
}

function Invoke-VerifyPhase05_DryRunInstall {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] $Ctx
    )
    # V05 produces an install plan that the user can review before any system
    # state is mutated. The plan is structured to match the chipset / graphics
    # script conventions:
    #   * Group A: patched INFs whose HWIDs match a device on this host
    #     (i.e. INFs that WILL bind to a real device on Install)
    #   * Group B: patched INFs with no matching device on this host
    #     (i.e. INFs that will be added to the driver store but bind to
    #     nothing - "driver-store-only")
    # NPU normally has only 1 device, so Group B is usually empty, but keeping
    # the same layout means operators reading mixed logs from chipset /
    # graphics / NPU runs get a uniform mental model.
    Write-Host ''
    Set-DebugStep 'simulate installation phases I01/I02/I03 (dry-run)'
    Write-Step 'Simulating Installation phases I01 / I02 / I03 - NO system changes will be made.'

    $patched = Get-ChildItem -Path $Ctx.PatchedDir -Filter '*.inf' -File
    Set-DebugStep 'enumerate patched INFs for evaluation'
    if ($patched.Count -eq 0) {
        Write-Caution 'No patched INFs to evaluate.'
        return
    }

    $current = @(Get-CimInstance Win32_PnPSignedDriver -ErrorAction SilentlyContinue)
    Set-DebugStep 'snapshot Win32_PnPSignedDriver baseline'
    Write-Skip ('Current Win32_PnPSignedDriver entries: {0}' -f $current.Count)

    # ----- Build install plan records (per patched INF) -----
    $plan = New-Object 'System.Collections.Generic.List[psobject]'
    foreach ($infFile in $patched) {
        $parsed = Read-InfManufacturer -InfPath $infFile.FullName
        $action = '[ADD]'
        $notes  = ''

        # Find any current driver bound to one of the patched INF's HWIDs
        $matchedCurrent = $null
        foreach ($entry in $parsed.HwidEntries) {
            $hwid = $entry.HardwareId
            $cur = $current | Where-Object {
                ($_.HardwareID -and $_.HardwareID -join '|' -match [regex]::Escape($hwid)) -or
                ($_.CompatID   -and $_.CompatID   -join '|' -match [regex]::Escape($hwid))
            } | Select-Object -First 1
            if ($cur) {
                $matchedCurrent = $cur
                break
            }
        }

        if ($matchedCurrent) {
            $cur = $matchedCurrent
            try { $curVer = [version]$cur.DriverVersion } catch { $curVer = $null }
            $curDate = if ($cur.DriverDate) { $cur.DriverDate.Date } else { $null }
            $patchedVerInfo = ConvertFrom-DriverVerString -DriverVerString $parsed.DriverVer
            $cmp = Compare-InfDriverVer `
                -CurrentDate $curDate `
                -CurrentVersion $curVer `
                -PatchedDate $patchedVerInfo.Date `
                -PatchedVersion $patchedVerInfo.Version
            switch ($cmp) {
                'UpgradePatched' {
                    $action = '[UPGRADE]'
                    $notes  = ('AS-IS {0} -> TO-BE {1}' -f $cur.DriverVersion, $parsed.DriverVer)
                }
                'CurrentNewer' {
                    $action = '[DOWNGRADE]'
                    $notes  = ('AS-IS {0} newer than TO-BE {1}; pnputil will refuse downgrade' -f $cur.DriverVersion, $parsed.DriverVer)
                }
                'SameVersionPatchedDateNewer' {
                    $action = '[UPGRADE]'
                    $notes  = ('same version {0} but TO-BE date is newer; PnP ranking prefers newer-dated driver' -f $cur.DriverVersion)
                }
                'SameVersionCurrentDateNewer' {
                    $action = '[KEEP]'
                    $notes  = ('same version {0}; AS-IS date newer' -f $cur.DriverVersion)
                }
                'Identical' {
                    $action = '[KEEP]'
                    $notes  = ('identical to AS-IS ({0})' -f $cur.DriverVersion)
                }
            }
        } else {
            $action = '[ADD]'
            $notes  = 'no AS-IS driver bound to this HWID; TO-BE will install fresh'
        }

        $plan.Add([pscustomobject]@{
            Inf            = $infFile.Name
            Action         = $action
            DriverVer      = $parsed.DriverVer
            Notes          = $notes
            MatchedCurrent = [bool]$matchedCurrent
            AsIsDeviceName = if ($matchedCurrent) { $matchedCurrent.DeviceName } else { $null }
            AsIsProvider   = if ($matchedCurrent) { $matchedCurrent.DriverProviderName } else { $null }
            AsIsVersion    = if ($matchedCurrent) { $matchedCurrent.DriverVersion } else { $null }
        })
    }
    $Ctx.DetectedPlatform.InstallPlan = $plan

    # ----- Render plan in two groups (sister-aligned: Group A / Group B) -----
    $groupA = $plan | Where-Object MatchedCurrent
    $groupB = $plan | Where-Object { -not $_.MatchedCurrent }

    Write-Host ''
    Write-Host ('  --- Group A: INFs targeting AMD HARDWARE on this machine ({0} INF) ---' -f $groupA.Count) -ForegroundColor White
    if ($groupA.Count -eq 0) {
        Write-Host '       (no INF in this group; the host has no NPU device that matches a patched INF)' -ForegroundColor DarkGray
    } else {
        $fmt = '    {0,-32}  {1,-24}  {2,-12}  {3}'
        Write-Host ($fmt -f 'Patched INF (TO-BE)', 'TO-BE DriverVer', 'Action', 'Notes') -ForegroundColor Gray
        Write-Host ($fmt -f ('-' * 32), ('-' * 24), ('-' * 12), ('-' * 40)) -ForegroundColor DarkGray
        foreach ($r in $groupA) {
            $color = switch ($r.Action) {
                '[UPGRADE]'   { 'Yellow' }
                '[ADD]'       { 'Green' }
                '[KEEP]'      { 'DarkGray' }
                '[DOWNGRADE]' { 'Red' }
                default       { 'White' }
            }
            $verPreview = if ($r.DriverVer) { $r.DriverVer.Substring(0, [Math]::Min(23, $r.DriverVer.Length)) } else { '-' }
            Write-Host ($fmt -f $r.Inf, $verPreview, $r.Action, $r.Notes) -ForegroundColor $color
        }
    }

    Write-Host ''
    Write-Host ('  --- Group B: INFs with NO matching device (driver-store-only, {0} INF) ---' -f $groupB.Count) -ForegroundColor White
    if ($groupB.Count -eq 0) {
        Write-Host '       (no INF in this group; every patched INF binds to a host device)' -ForegroundColor DarkGray
    } else {
        Write-Host '       (these INFs will be added to the driver store but bind to no current device)' -ForegroundColor DarkGray
        $fmt = '    {0,-32}  {1,-24}  {2,-12}  {3}'
        Write-Host ($fmt -f 'Patched INF (TO-BE)', 'TO-BE DriverVer', 'Action', 'Notes') -ForegroundColor Gray
        Write-Host ($fmt -f ('-' * 32), ('-' * 24), ('-' * 12), ('-' * 40)) -ForegroundColor DarkGray
        foreach ($r in $groupB) {
            $verPreview = if ($r.DriverVer) { $r.DriverVer.Substring(0, [Math]::Min(23, $r.DriverVer.Length)) } else { '-' }
            Write-Host ($fmt -f $r.Inf, $verPreview, $r.Action, $r.Notes) -ForegroundColor Green
        }
    }

    # ----- Summary counts (sister-aligned action labels) -----
    Write-Host ''
    $cAdd       = ($plan | Where-Object Action -EQ '[ADD]').Count
    $cUpgrade   = ($plan | Where-Object Action -EQ '[UPGRADE]').Count
    $cKeep      = ($plan | Where-Object Action -EQ '[KEEP]').Count
    $cDowngrade = ($plan | Where-Object Action -EQ '[DOWNGRADE]').Count
    Write-Ok ('Plan summary: {0} INF total -> [ADD] {1}  [UPGRADE] {2}  [KEEP] {3}  [DOWNGRADE] {4}' -f `
        $plan.Count, $cAdd, $cUpgrade, $cKeep, $cDowngrade)
    if ($cDowngrade -gt 0) {
        Write-Caution ('{0} INF would attempt a downgrade; pnputil normally refuses these.' -f $cDowngrade)
    }

    # ---- Compact UEFI Secure Boot baseline readout (chipset/graphics parity) ----
    # Operators reviewing V05 should know whether the firmware-layer Secure
    # Boot trust state is healthy BEFORE committing to the OS-layer self-
    # signing path in I02 / I03. The compact one-liner here is identical to
    # what P00 displays; the full multi-line breakdown lives in V06 Section 5.
    Write-Host ''
    Write-Host '[Dry-Run UEFI Baseline] ---------------------------' -ForegroundColor Cyan
    $sbSnapshot = Get-OrEnsureSecureBootBaseline -Ctx $Ctx
    if ($sbSnapshot) {
        Show-SecureBootBaselineSnapshot -Snapshot $sbSnapshot -Compact
        if ($sbSnapshot.Health -in 'Warning','Critical') {
            Write-Host ('  Health is {0} - review the V06 / report appendix for details.' -f $sbSnapshot.Health) -ForegroundColor Yellow
        }
    }
}

function Invoke-VerifyPhase06_HardwareImpactAnalysis { # psa-disable-line PSA6003 -- compound noun (e.g., Policies, Drivers, Catalogs) is semantically plural for set-returning helpers
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] $Ctx
    )
    Set-DebugStep 'analyze hardware impact on detected NPU'
    # V06 reports the planned hardware impact of the I03 install. It is
    # structured to mirror the chipset / graphics V06 layout while accounting
    # for NPU's single-device characteristic:
    #
    # Section 1: AS-IS - hardware enumeration on this host (current state)
    # Section 2: AS-IS / TO-BE driver comparison (per-device delta)
    # Section 3: Risk classification (NPU-specific: HIGH / MEDIUM / LOW)
    # Section 4: Ryzen AI Software user-mode stack reminder
    #
    # The "WILL be replaced" / "WILL NOT be replaced" / "Already up to date"
    # terminology is borrowed directly from the chipset / graphics V06 so
    # operators reading multiple deployment logs see consistent vocabulary.

    # ------------------------------------------------------------------
    # Section 1: AS-IS hardware enumeration
    # ------------------------------------------------------------------
    Write-SubHeader2 'Section 1: AS-IS - NPU hardware enumeration on this host'
    $current = $null
    Set-DebugStep 'match detected NPU HW ID against patched INFs'
    if ($Ctx.DetectedPlatform.NpuIsDetected) {
        Write-Ok ('NPU codename       : {0}' -f $Ctx.DetectedPlatform.NpuCodename)
        Write-Ok ('Hardware ID        : {0}' -f $Ctx.DetectedPlatform.NpuHardwareId)
        Write-Ok ('Revision           : {0}' -f $Ctx.DetectedPlatform.NpuRevision)

        # Look up the actual current driver bound to this device
        $hwidPattern = if ($Ctx.DetectedPlatform.NpuHardwareId) {
            $Ctx.DetectedPlatform.NpuHardwareId.Replace('\','\\')
        } else { $null }
        if (-not [string]::IsNullOrEmpty($hwidPattern)) {
            $current = Get-CimInstance Win32_PnPSignedDriver -ErrorAction SilentlyContinue | Where-Object {
                ($_.HardwareID -and ($_.HardwareID -join '|') -match $hwidPattern) # psa-disable-line PSA2003 -- pattern variable is initialized in the enclosing scope; $null impossible by construction
            } | Select-Object -First 1
        }
        if ($current) {
            Write-Ok ('AS-IS driver name  : {0}' -f $current.DeviceName)
            Write-Ok ('AS-IS DriverVer    : {0}' -f $current.DriverVersion)
            $dateStr = if ($current.DriverDate) { '{0:yyyy-MM-dd}' -f $current.DriverDate } else { '(unknown)' }
            Write-Ok ('AS-IS DriverDate   : {0}' -f $dateStr)
            Write-Ok ('AS-IS Provider     : {0}' -f $current.DriverProviderName)
        } else {
            Write-Caution 'AS-IS driver       : (none bound to NPU device, or device unbound)'
            Write-Skip 'This is common on a freshly installed Windows Server 2025 - the NPU appears'
            Write-Skip 'as an unknown PCI device until the AMD / Microsoft driver is installed.'
        }
    } else {
        Write-Caution 'NPU was NOT detected on this host (running with -AssumeIfMissing default profile).'
        Write-Caution 'V06 cannot evaluate device-bind impact without a real NPU device present.'
    }

    # ------------------------------------------------------------------
    # Section 2: AS-IS / TO-BE driver comparison (sister-aligned)
    # ------------------------------------------------------------------
    Write-Host ''
    Write-SubHeader2 'Section 2: AS-IS / TO-BE driver comparison (version-aware)'
    if ($Ctx.DetectedPlatform.InstallPlan) {
        $plan       = $Ctx.DetectedPlatform.InstallPlan
        $matched    = $plan | Where-Object MatchedCurrent
        $unmatched  = $plan | Where-Object { -not $_.MatchedCurrent }
        $willReplace      = $matched | Where-Object Action -in '[UPGRADE]','[ADD]'
        $willNotReplace   = $matched | Where-Object Action -EQ '[KEEP]'
        $willDowngrade    = $matched | Where-Object Action -EQ '[DOWNGRADE]'

        # Summary header
        if ($matched.Count -eq 0 -and $unmatched.Count -gt 0) {
            Write-Skip 'No AS-IS driver to compare against; every TO-BE INF will be a fresh install.'
        }

        # Group: WILL be replaced (UPGRADE)
        if ($willReplace.Count -gt 0) {
            Write-Caution ('{0,3} device(s) WILL be replaced (TO-BE is newer or same-version-newer-date)' -f $willReplace.Count)
            foreach ($p in $willReplace) {
                Write-Host ''
                Write-Host ('    INF: {0}' -f $p.Inf) -ForegroundColor White
                Write-Host ('      AS-IS: {0,-12}  Provider={1}' -f $p.AsIsVersion, $p.AsIsProvider) -ForegroundColor DarkGray
                Write-Host ('      TO-BE: {0,-12}  Provider=Self-signed (this script)' -f $p.DriverVer) -ForegroundColor Yellow
                Write-Host ('      Note : {0}' -f $p.Notes) -ForegroundColor DarkGray
            }
        } else {
            Write-Skip '  0 device(s) WILL be replaced'
        }

        # Group: WILL NOT be replaced (KEEP)
        if ($willNotReplace.Count -gt 0) {
            Write-Host ''
            Write-Skip ('{0,3} device(s) WILL NOT be replaced (already up to date)' -f $willNotReplace.Count)
            foreach ($p in $willNotReplace) {
                Write-Skip ('      - {0}: AS-IS={1} (TO-BE same or older)' -f $p.Inf, $p.AsIsVersion)
            }
        }

        # Group: DOWNGRADE attempt
        if ($willDowngrade.Count -gt 0) {
            Write-Host ''
            Write-Fail ('{0,3} device(s) WILL ATTEMPT DOWNGRADE (pnputil normally refuses)' -f $willDowngrade.Count)
            foreach ($p in $willDowngrade) {
                Write-Fail ('      - {0}: AS-IS={1} -> TO-BE={2}' -f $p.Inf, $p.AsIsVersion, $p.DriverVer)
            }
        }

        # Group: fresh install (Group B)
        if ($unmatched.Count -gt 0) {
            Write-Host ''
            Write-Ok ('{0,3} INF(s) will install fresh (no AS-IS driver bound to HWID)' -f $unmatched.Count)
            foreach ($p in $unmatched) {
                Write-Ok ('      - {0}: TO-BE={1}' -f $p.Inf, $p.DriverVer)
            }
        }
    } else {
        Write-Caution 'No install plan available; run V05 (DryRunInstall) first.'
    }

    # ------------------------------------------------------------------
    # Section 3: Risk classification (NPU-specific)
    # ------------------------------------------------------------------
    Write-Host ''
    Write-SubHeader2 'Section 3: Risk classification of planned actions'
    if ($Ctx.DetectedPlatform.InstallPlan) {
        $plan = $Ctx.DetectedPlatform.InstallPlan
        $adds       = $plan | Where-Object Action -EQ '[ADD]'
        $upgrades   = $plan | Where-Object Action -EQ '[UPGRADE]'
        $keeps      = $plan | Where-Object Action -EQ '[KEEP]'
        $downgrades = $plan | Where-Object Action -EQ '[DOWNGRADE]'

        # Summary first (sister-aligned action labels)
        Write-Ok ('[ADD]       : {0} INF(s)' -f $adds.Count)
        Write-Ok ('[UPGRADE]   : {0} INF(s)' -f $upgrades.Count)
        Write-Ok ('[KEEP]      : {0} INF(s)' -f $keeps.Count)
        if ($downgrades.Count -gt 0) {
            Write-Fail ('[DOWNGRADE] : {0} INF(s)  (pnputil will refuse)' -f $downgrades.Count)
        }

        Write-Host ''
        if ($adds.Count -gt 0) {
            Write-Caution '[HIGH RISK]   Fresh install of NPU kernel-mode driver.'
            Write-Caution '              Reason: An unbound device will be claimed by a self-signed driver.'
            Write-Caution '                      Ryzen AI Software depends on the exact driver build version.'
            foreach ($p in $adds) {
                Write-Skip ('                - {0} ({1})' -f $p.Inf, $p.DriverVer)
            }
        }
        if ($upgrades.Count -gt 0) {
            Write-Caution '[MEDIUM RISK] Upgrade of NPU driver.'
            Write-Caution '              Reason: Cross-RAI-version upgrades may break Ryzen AI Software API.'
            Write-Caution '                      e.g. RAI 1.5 -> 1.6+ broke OGA API (0.7 -> 0.9.2).'
            foreach ($p in $upgrades) {
                Write-Skip ('                - {0}: {1}' -f $p.Inf, $p.Notes)
            }
        }
        if ($keeps.Count -gt 0 -and $adds.Count -eq 0 -and $upgrades.Count -eq 0) {
            Write-Ok '[LOW RISK]    No driver state change; existing AS-IS drivers will be retained.'
        }
    }

    # ------------------------------------------------------------------
    # Section 4: Ryzen AI Software reminder (NPU-specific)
    # ------------------------------------------------------------------
    Write-Host ''
    Write-SubHeader2 'Section 4: Ryzen AI Software (user-mode stack) reminder'
    Write-Caution 'This script installs the kernel-mode NPU driver only. To actually USE the NPU,'
    Write-Caution 'you must separately install Ryzen AI Software, which is OFFICIALLY supported'
    Write-Caution 'on Windows 11 only (build >= 22621.3527).'
    Write-Skip 'NPU driver and Ryzen AI Software are versioned INDEPENDENTLY (per AMD docs).'
    Write-Skip 'See the I04 post-install guidance for installer download URLs.'

    # ------------------------------------------------------------------
    # Section 5: UEFI Secure Boot Baseline (port from chipset/graphics)
    # ------------------------------------------------------------------
    # The same firmware-layer view that the sister scripts show. This is
    # informational only (the self-signing trust chain we operate on is
    # at the OS layer, independent of UEFI Secure Boot certificate
    # rollout) but operators reviewing all three pipelines benefit from
    # consistent baseline reporting. Note this is Section 5 in NPU (vs
    # Section 4 in chipset / graphics) so the NPU-specific Ryzen AI
    # reminder above keeps its established position.
    Write-Host ''
    Write-SubHeader2 'Section 5: UEFI Secure Boot Baseline'
    try {
        $sbSnapshot = Get-OrEnsureSecureBootBaseline -Ctx $Ctx
        if ($sbSnapshot) {
            Show-SecureBootBaselineSnapshot -Snapshot $sbSnapshot
        }
    } catch {
        Write-Caution ("Secure Boot baseline section failed: {0}" -f $_.Exception.Message)
    }
}

# =============================================================================
# Phase implementations I00 - I04 (Install)
# =============================================================================

function Invoke-InstPhase00_PreInstallReview {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] $Ctx
    )
    Set-DebugStep 'show pre-install review for operator acknowledgement'
    Write-Step 'Showing pre-install review for operator acknowledgement'

    Set-DebugStep 'workstation OS install guard check'
    if ($Ctx.DetectedPlatform.IsWorkstationOs -and -not $Ctx.AllowWorkstationInstall) {
        Write-Caution ''
        Write-Caution 'Install phases are blocked on Workstation OS by default.'
        Write-Caution 'Use -AllowWorkstationInstall to override (discouraged).'
        Write-Caution 'Skipping I00-I04.'
        Write-Caution ''
        throw 'Install blocked on Workstation OS.'
    }

    Write-Host ''
    Write-Host '+----------------------------------------------------------------+' -ForegroundColor Yellow
    Write-Host '| AMD RYZEN AI EULA ACCEPTANCE REQUIRED BEFORE INSTALL           |' -ForegroundColor Yellow
    Write-Host '+----------------------------------------------------------------+' -ForegroundColor Yellow
    Write-Host '|                                                                |' -ForegroundColor Yellow
    Write-Host '| By proceeding, you confirm:                                    |' -ForegroundColor Yellow
    Write-Host '| 1. You have accepted the Ryzen AI EULA at:                     |' -ForegroundColor Yellow
    Write-Host '|    https://account.amd.com/en/forms/downloads/                 |' -ForegroundColor Yellow
    Write-Host '|    ryzenai-eula-public-xef.html                                |' -ForegroundColor Yellow
    Write-Host '| 2. You acknowledge Windows Server 2025 is NOT officially       |' -ForegroundColor Yellow
    Write-Host '|    supported by AMD for Ryzen AI Software (Windows 11 only).   |' -ForegroundColor Yellow
    Write-Host '| 3. You understand the kernel-mode driver alone does not        |' -ForegroundColor Yellow
    Write-Host '|    enable AI inference; Ryzen AI SW must be installed manually.|' -ForegroundColor Yellow
    Write-Host '| 4. You have BitLocker recovery keys recorded if applicable.    |' -ForegroundColor Yellow
    Write-Host '|                                                                |' -ForegroundColor Yellow
    Write-Host '+----------------------------------------------------------------+' -ForegroundColor Yellow
    Write-Host ''

    Set-DebugStep 'prompt operator for EULA acknowledgement'
    $confirm = Read-Host 'Type "I AGREE" exactly to proceed with install (anything else aborts)'
    if ($confirm -ne 'I AGREE') {
        throw 'Install aborted by operator (EULA acknowledgement not given).'
    }
    Write-Ok 'Operator acknowledged. Proceeding with install phases.'
}

function Invoke-InstPhase01_TrustCertificate {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] $Ctx
    )
    Set-DebugStep 'delegate to Add-CertToTrustStore'
    Add-CertToTrustStore -CerPath $Ctx.CerPath
}

function Invoke-InstPhase02_AuthorizeDriverSigning {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] $Ctx
    )
    Set-DebugStep 'build and deploy WDAC supplemental Code Integrity policy'
    Write-Step 'Building and deploying WDAC supplemental Code Integrity policy'

    # ---- UEFI Secure Boot baseline pre-check (port from chipset/graphics) ----
    # Cross-check the firmware-layer UEFI Secure Boot state before we
    # touch the OS-layer signing surface. This is a SOFT pre-check: we
    # never block I02 on UEFI cert rollout state (the rollout and our
    # WDAC policy are independent trust chains). We surface signals
    # that have operational implications for what happens next:
    #
    #   - Secure Boot OFF + WDAC path planned: WDAC will still apply
    #     (CI policy is independent of UEFI variables), but the
    #     selected path is overspecified - testsigning would suffice.
    #
    #   - UEFI CA 2023 rollout in error state: there is a concurrent
    #     firmware-level update in progress that may compete with
    #     post-I02 reboots. Operators should know this.
    Write-Host ''
    Set-DebugStep 'UEFI Secure Boot baseline pre-check (soft)'
    Write-Host '--- UEFI Secure Boot baseline pre-check ---' -ForegroundColor Cyan
    try {
        $sbSnapshot = Get-OrEnsureSecureBootBaseline -Ctx $Ctx
        if ($sbSnapshot) {
            Show-SecureBootBaselineSnapshot -Snapshot $sbSnapshot -Compact

            # WDAC path is planned but Secure Boot is OFF -> path is
            # overspecified (testsigning would suffice). Not a block.
            if (-not $Ctx.UseTestSigning -and $sbSnapshot.Embedded.SecureBootEnabled -eq $false) {
                Write-Caution 'WDAC path is planned, but Secure Boot is OFF. Code Integrity policy will still apply; testsigning would also suffice. Continuing.'
            }
            # Surface UEFI rollout error state without blocking
            if ($sbSnapshot.Health -eq 'Critical') {
                Write-Caution ('UEFI Secure Boot baseline health is Critical. Reasons: ' + ($sbSnapshot.Reasons -join '; '))
                Write-Host '  This does NOT block I02 (different trust layer), but the operator should be aware.' -ForegroundColor Yellow
            } elseif ($sbSnapshot.Health -eq 'Warning') {
                Write-Host ('  Baseline health: Warning. ' + ($sbSnapshot.Reasons -join '; ')) -ForegroundColor Yellow
            }
        }
    } catch {
        Write-Caution ("UEFI Secure Boot baseline pre-check failed (non-fatal): {0}" -f $_.Exception.Message)
    }
    Write-Host ''

    Set-DebugStep 'testsigning fallback or WDAC policy build'
    if ($Ctx.UseTestSigning) {
        Write-Caution 'UseTestSigning specified; falling back to bcdedit /set testsigning on'
        Write-Caution 'A reboot is required for testsigning mode to take effect.'
        & bcdedit /set testsigning on 2>&1 | ForEach-Object { Write-Skip ("    {0}" -f $_) }
        return
    }

    $wdac = New-WdacSupplementalPolicy `
        -CerPath $Ctx.CerPath `
        -XmlOutputPath $Ctx.WdacXmlPath `
        -BinOutputPath $Ctx.WdacBinPath `
        -PolicyName $Ctx.WdacPolicyName `
        -PolicyGuid $Ctx.WdacPolicyGuid

    Set-DebugStep 'install WDAC policy via CiTool / Set-CIPolicy'
    $r = Install-WdacPolicy -BinPath $wdac.BinPath -PolicyGuid $Ctx.WdacPolicyGuid
    if (-not $r.Success) {
        throw 'WDAC policy deployment failed.'
    }
    Write-Ok ('WDAC policy deployed via {0}' -f $r.Method)
}

function Invoke-InstPhase03_InstallDrivers { # psa-disable-line PSA6003 -- compound noun (e.g., Policies, Drivers, Catalogs) is semantically plural for set-returning helpers
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] $Ctx
    )
    Set-DebugStep 'run pnputil /add-driver /install for each patched INF'
    Write-Step 'Running pnputil /add-driver /install for each patched INF'

    $infs = Get-ChildItem -Path $Ctx.PatchedDir -Filter '*.inf' -File
    $ok = 0; $fail = 0
    Set-DebugStep 'install each patched INF via pnputil (loop)'
    foreach ($inf in $infs) {
        $r = Install-PatchedDriver -InfPath $inf.FullName
        if ($r.Success) {
            $ok++
            Write-Ok ('  {0} OK (exit {1})' -f $inf.Name, $r.ExitCode)
        } else {
            $fail++
            Write-Caution ('  {0} FAILED (exit {1})' -f $inf.Name, $r.ExitCode)
        }
    }
    Write-Ok ('Install OK: {0}; FAILED: {1}' -f $ok, $fail)

    # Force enumeration
    Set-DebugStep 'force device enumeration via pnputil /scan-devices'
    Write-Step 'pnputil /scan-devices'
    & pnputil.exe /scan-devices 2>&1 | ForEach-Object { Write-Skip ("    {0}" -f $_) }
}

function Invoke-InstPhase04_PostInstallVerification {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] $Ctx
    )

    Set-DebugStep 'verify NPU device binding via Win32_PnPSignedDriver'
    if ($Ctx.DetectedPlatform.NpuHardwareId) {
        $hwidEscaped = [regex]::Escape($Ctx.DetectedPlatform.NpuHardwareId)
        $bound = $null
        if (-not [string]::IsNullOrEmpty($hwidEscaped)) {
            Set-DebugStep 'match NPU HWID against Win32_PnPSignedDriver entries'
            $bound = Get-CimInstance Win32_PnPSignedDriver -ErrorAction SilentlyContinue | Where-Object {
                $_.HardwareID -and ($_.HardwareID -join '|') -match $hwidEscaped # psa-disable-line PSA2003 -- pattern variable is initialized in the enclosing scope; $null impossible by construction
            } | Select-Object -First 1
        }

        if ($bound) {
            Write-Ok ('Bound device : {0}' -f $bound.DeviceName)
            Write-Ok ('Driver ver   : {0}' -f $bound.DriverVersion)
            Write-Ok ('Driver date  : {0:yyyy-MM-dd}' -f $bound.DriverDate)
            Write-Ok ('Provider     : {0}' -f $bound.DriverProviderName)

            if ($bound.DriverProviderName -match 'AMD') {
                Write-Ok '[C] Self-signed AMD NPU driver successfully bound.'
            } else {
                Write-Caution 'Driver provider is not AMD; check Device Manager for binding.'
            }
        } else {
            Write-Caution 'No driver appears bound to the target NPU HWID yet.'
            Write-Caution 'Try: Device Manager -> rescan; or pnputil /scan-devices.'
        }
    } else {
        Write-Skip 'NPU HWID not known; skipping post-install bind check.'
    }
}

# =============================================================================
# Cleanup action
# =============================================================================
function Invoke-Cleanup {
    param($Ctx)
    Write-PhaseHeader '---' 'Cleanup' 'Util'

    # Remove the deployed WDAC supplemental policy (if any) BEFORE we
    # wipe the workspace, otherwise we lose the marker file that tells
    # us which PolicyId is ours.
    $markerPath = Get-AmdSuppPolicyMarkerPath -Ctx $Ctx
    if ($markerPath -and (Test-Path $markerPath)) {
        $policyId = (Get-Content $markerPath -Raw -ErrorAction SilentlyContinue).Trim()
        if ($policyId) {
            Write-Step "Removing WDAC supplemental policy: $policyId"
            $rm = Uninstall-AmdWdacPolicy -PolicyId $policyId
            if ($rm.Removed) {
                Write-Ok ('Removed deployed CI policy {0}' -f $policyId)
            } elseif ($rm.Existed) {
                Write-Caution ('Could not remove CI policy {0} - inspect manually with CiTool.exe -lp' -f $policyId)
            } else {
                Write-Skip 'WDAC supplemental policy was not currently deployed.'
            }
        }
    }

    if (Test-Path $Ctx.WorkRoot) {
        Write-Step "Removing $($Ctx.WorkRoot)"
        Remove-Item -Path $Ctx.WorkRoot -Recurse -Force
        Write-Ok 'Workspace removed.'
    } else {
        Write-Skip 'Workspace already absent.'
    }

    Write-Host ''
    Write-Host 'Reminder: Cleanup does NOT undo:' -ForegroundColor DarkGray
    Write-Host '  - testsigning (use: bcdedit /set testsigning off; reboot)' -ForegroundColor DarkGray
    Write-Host '  - cert in LocalMachine\Root or \TrustedPublisher (manage via certmgr.msc)' -ForegroundColor DarkGray
    Write-Host '  - drivers added by I03 (use: pnputil /enum-drivers; pnputil /delete-driver oemNN.inf /uninstall)' -ForegroundColor DarkGray

    Write-PhaseFooter '---' 'done'
}

# =============================================================================
# Ryzen AI Software user-mode stack guidance (post-install)
# =============================================================================
function Show-RyzenAiSoftwareGuidance {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] $Ctx
    )
    Write-Host ''
    Write-Host '+================================================================+' -ForegroundColor Cyan
    Write-Host '| RYZEN AI SOFTWARE (USER-MODE STACK) - INSTALL THIS SEPARATELY |' -ForegroundColor Cyan
    Write-Host '+================================================================+' -ForegroundColor Cyan
    Write-Host ''
    Write-Host 'This script installed the kernel-mode NPU driver only.' -ForegroundColor White
    Write-Host 'To actually use the NPU for AI inference, install Ryzen AI Software:' -ForegroundColor White
    Write-Host ''
    Write-Host ('  Detected NPU codename       : {0}' -f $Ctx.DetectedPlatform.NpuShortName) -ForegroundColor Gray
    Write-Host ('  Installed NPU driver build  : {0} (kernel-mode, this script)' -f $Ctx.DetectedPlatform.NpuDriverBuild) -ForegroundColor Gray
    Write-Host ('  Recommended RAI Software    : {0} (user-mode stack, install separately)' -f $Ctx.DetectedPlatform.RyzenAiSoftwareVersion) -ForegroundColor Gray
    Write-Host '  Note: NPU driver and Ryzen AI Software are versioned INDEPENDENTLY.' -ForegroundColor Gray
    Write-Host '        Always use the LATEST Ryzen AI Software for end-user workloads.' -ForegroundColor Gray
    Write-Host ''
    Write-Host '  PREREQUISITES (per AMD documentation):' -ForegroundColor Yellow
    Write-Host '    1. Windows 11 build >= 22621.3527 (NOT supported on Server 2025!)' -ForegroundColor Yellow
    Write-Host '    2. Visual Studio 2022 (with Desktop Development with C++)' -ForegroundColor Yellow
    Write-Host '    3. cmake >= 3.26' -ForegroundColor Yellow
    Write-Host '    4. Miniforge (Python distribution); add condabin/Scripts to PATH' -ForegroundColor Yellow
    Write-Host ''
    Write-Host '  INSTALLATION STEPS:' -ForegroundColor White
    Write-Host '    1. Download Ryzen AI Software installer (user-mode stack):' -ForegroundColor White
    $raiInstaller = if ($Ctx.DetectedPlatform.RyzenAiSoftwareInstaller) { $Ctx.DetectedPlatform.RyzenAiSoftwareInstaller } else { 'ryzen-ai-lt-1.7.1.exe' }
    $raiVer       = if ($Ctx.DetectedPlatform.RyzenAiSoftwareVersion)   { $Ctx.DetectedPlatform.RyzenAiSoftwareVersion }   else { '1.7.1' }
    Write-Host ('       https://account.amd.com/en/forms/downloads/xef.html?filename={0}' -f $raiInstaller) -ForegroundColor Cyan
    Write-Host ("       Filename: {0}" -f $raiInstaller) -ForegroundColor Cyan
    Write-Host ''
    Write-Host '    2. Launch the EXE installer (run as Administrator):' -ForegroundColor White
    Write-Host '       - Accept the EULA' -ForegroundColor White
    Write-Host ('       - Default install dir: C:\Program Files\RyzenAI\{0}' -f $raiVer) -ForegroundColor White
    Write-Host ('       - Default conda env name: ryzen-ai-{0}' -f $raiVer) -ForegroundColor White
    Write-Host ''
    Write-Host '    3. Verify the install (Miniforge Prompt):' -ForegroundColor White
    Write-Host ("         conda activate ryzen-ai-{0}" -f $raiVer) -ForegroundColor Cyan
    Write-Host '         cd %RYZEN_AI_INSTALLATION_PATH%\quicktest' -ForegroundColor Cyan
    Write-Host '         python quicktest.py' -ForegroundColor Cyan
    Write-Host '         # Open Task Manager -> Performance -> NPU; should see utilization' -ForegroundColor Gray
    Write-Host ''
    Write-Host '  COMPONENTS INCLUDED IN RYZEN AI SOFTWARE:' -ForegroundColor White
    Write-Host '    - Vitis AI Execution Provider for ONNX Runtime (VitisAIExecutionProvider)' -ForegroundColor Gray
    Write-Host '    - OnnxRuntime GenAI (OGA) for hybrid CNN/LLM execution' -ForegroundColor Gray
    Write-Host '    - AMD Quark quantizer (PyTorch/ONNX)' -ForegroundColor Gray
    Write-Host '    - Whisper.cpp / Stable Diffusion / LLM hybrid runtime examples' -ForegroundColor Gray
    Write-Host '    - xrt-smi NPU management tool' -ForegroundColor Gray
    Write-Host ''
    Write-Host '  DOCUMENTATION & EXAMPLES:' -ForegroundColor White
    Write-Host '    Full installation guide:  https://ryzenai.docs.amd.com/en/latest/inst.html' -ForegroundColor Cyan
    Write-Host '    Release notes:            https://ryzenai.docs.amd.com/en/latest/relnotes.html' -ForegroundColor Cyan
    Write-Host '    GitHub examples:          https://github.com/amd/RyzenAI-SW' -ForegroundColor Cyan
    Write-Host '    Latest releases:          https://github.com/amd/RyzenAI-SW/releases' -ForegroundColor Cyan
    Write-Host ''
    Write-Host '  IMPORTANT - Server 2025 caveat:' -ForegroundColor Magenta
    if ($Ctx.DetectedPlatform.IsServer2025) {
        Write-Host '    You are on Windows Server 2025. AMD does NOT support Ryzen AI Software here.' -ForegroundColor Magenta
        Write-Host '    The kernel driver this script installed will load, but the user-mode' -ForegroundColor Magenta
        Write-Host '    Python/ONNX Runtime stack may fail to initialize on Server SKU.' -ForegroundColor Magenta
        Write-Host '    For inference workloads, consider using Windows 11 24H2 instead.' -ForegroundColor Magenta
    } else {
        Write-Host '    You are NOT on Windows Server 2025; Ryzen AI Software install should be' -ForegroundColor Magenta
        Write-Host '    straightforward following the steps above.' -ForegroundColor Magenta
    }
    Write-Host ''
    Write-Host '+================================================================+' -ForegroundColor Cyan
    Write-Host ''
}

# =============================================================================
# Final summary (run at end of every Action) - sister-script-aligned
# =============================================================================
function Show-RunSummary {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] $Ctx,
        [Parameter(Mandatory)][string]$Action
    )

    $totalElapsed = (Get-Date) - $Script:ScriptStartTime
    $endedAtStr   = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')

    Write-Host ''
    Write-Host ('=' * 72) -ForegroundColor Magenta
    Write-Host ' RUN SUMMARY' -ForegroundColor Magenta
    Write-Host ('=' * 72) -ForegroundColor Magenta
    Write-Host (" Script version  : {0} [{1}]" -f $Script:ScriptVersion, $Script:ScriptTag) -ForegroundColor Cyan
    Write-Host (" Script SHA256   : {0}" -f $Script:ScriptHash) -ForegroundColor DarkCyan
    Write-Host (" Action          : {0}" -f $Action) -ForegroundColor White
    Write-Host (" Started         : {0:yyyy-MM-dd HH:mm:ss}" -f $Script:HostStartTime) -ForegroundColor Gray
    Write-Host (" Ended           : {0}" -f $endedAtStr) -ForegroundColor Gray
    Write-Host (" Duration        : {0}" -f (Format-Elapsed $totalElapsed)) -ForegroundColor Gray
    Write-Host (" Workspace       : {0}" -f $WorkRoot) -ForegroundColor Gray
    if ($Ctx.DetectedPlatform.NpuShortName) {
        Write-Host (" NPU             : {0} ({1})" -f $Ctx.DetectedPlatform.NpuCodename, $Ctx.DetectedPlatform.NpuShortName) -ForegroundColor Gray
    }
    if ($Ctx.DetectedPlatform.NpuDriverPackage) {
        Write-Host (" NPU driver pkg  : {0} (build {1})" -f $Ctx.DetectedPlatform.NpuDriverPackage, $Ctx.DetectedPlatform.NpuDriverBuild) -ForegroundColor Gray
    }
    if ($Ctx.DetectedPlatform.RyzenAiSoftwareVersion) {
        Write-Host (" RAI Software    : {0} (separate user-mode install)" -f $Ctx.DetectedPlatform.RyzenAiSoftwareVersion) -ForegroundColor Gray
    }

    Write-Host ''
    Write-Host ('-' * 72) -ForegroundColor DarkCyan
    Write-Host ' Phase results' -ForegroundColor DarkCyan
    Write-Host ('-' * 72) -ForegroundColor DarkCyan
    $fmt = "{0,-5} {1,-7} {2,-30} {3,-8} {4,-12}"
    Write-Host ($fmt -f 'ID', 'Group', 'Name', 'Status', 'Duration') -ForegroundColor Gray
    Write-Host ($fmt -f ('-' * 4), ('-' * 5), ('-' * 28), ('-' * 6), ('-' * 10)) -ForegroundColor DarkGray
    $sumSeconds = 0.0
    foreach ($p in $Script:PhaseRegistry) {
        $r = $Script:PhaseResults[$p.Id]
        if (-not $r) {
            Write-Host ($fmt -f $p.Id, $p.Group, $p.Name, 'SKIP', '-') -ForegroundColor DarkGray
        } else {
            $color = switch ($r.Status) {
                'OK'   { 'Green' }
                'FAIL' { 'Red' }
                default { 'Gray' }
            }
            $sumSeconds += $r.Duration.TotalSeconds
            $statusLabel = switch ($r.Status) {
                'OK'   { 'DONE' }
                'FAIL' { 'FAILED' }
                default { $r.Status }
            }
            $durStr = Format-Elapsed $r.Duration
            Write-Host ($fmt -f $p.Id, $p.Group, $p.Name, $statusLabel, $durStr) -ForegroundColor $color
        }
    }
    Write-Host ($fmt -f ('-' * 4), ('-' * 5), ('-' * 28), ('-' * 6), ('-' * 10)) -ForegroundColor DarkGray
    Write-Host ($fmt -f '', '', 'Sum of executed phases', '', (Format-Elapsed ([TimeSpan]::FromSeconds($sumSeconds)))) -ForegroundColor White
    Write-Host ('=' * 72) -ForegroundColor Magenta
    Write-Host ''
}
# =============================================================================
# Main entry point / orchestrator
# =============================================================================

function Invoke-MainEntryPoint {
    [CmdletBinding()]
    param()

    # ----- Construct the canonical $Ctx (stage 3 of the NPU state-model refactor) -----
    #
    # The $Ctx PSCustomObject is the canonical state-passing channel used
    # by the Chipset / Graphics / BthPan sister scripts. NPU is fully
    # aligned with this canon: all five Tier B-4 helpers
    # (Get-OrEnsureSecureBootBaseline, Get-BootSigningEnvironment,
    # Show-BootSigningEnvironment, Invoke-Cleanup, Resume-CtxFromWorkspace)
    # are now byte-identical copies of the Chipset canon and consume $Ctx
    # via the canonical Chipset-compatible schema. NPU-specific extensions
    # (NpuDriverPackage, AmdAccountUser, WdacBinPath, etc.) are added in
    # their own block below the canon block to keep the diff against
    # Chipset's $Ctx initialiser visible and minimal.
    #
    # NPU initialises $Ctx.Paths up-front (instead of in P01 like Chipset)
    # because the entire path layout is known from $WorkRoot at script
    # start - no workspace-bootstrap step is required to compute valid
    # path values. NPU also keeps a parallel set of flat top-level path
    # properties ($Ctx.CertDir, $Ctx.PfxPath, etc.) that pre-date this
    # refactor and are still read by the NPU-specific phase functions;
    # these are kept as aliases to the corresponding $Ctx.Paths.* sub-keys
    # so a future stage can drop them once all NPU consumers migrate to
    # the canonical Chipset names. See CHANGELOG.md for the stage-by-stage
    # refactor history and SPEC §A.11.7 *Tier B-4* for the planned
    # end-state and outstanding 4-way Tier A alignment items.
    $certDir = Join-Path $WorkRoot 'cert'
    $Ctx = [pscustomobject]@{
        # ----- Chipset canon properties (mirror Chipset L14091..L14130) -----
        # Params
        Action          = $Action
        OnlyPhases      = $OnlyPhases
        InstallerUrl    = $InstallerUrl
        AmdLandingUrls  = $null  # NPU does not crawl AMD landing pages; placeholder for canon parity
        AmdFallbackUrl  = $null  # NPU does not use the AMD fallback URL; placeholder for canon parity
        WorkRoot        = $WorkRoot
        PfxPassword     = $PfxPassword
        TimestampUrl    = 'http://timestamp.digicert.com'
        Force           = $false  # NPU does not expose -Force at this stage; placeholder for canon parity
        CleanWorkRoot   = $CleanWorkRoot.IsPresent  # psa-disable-line PSA2001 -- script-param parent-scope lookup (switch params have no default-value form for PSA2001 recognition)
        UseTestSigning  = $UseTestSigning.IsPresent  # psa-disable-line PSA2001 -- script-param parent-scope lookup (switch params have no default-value form for PSA2001 recognition)
        AllowWorkstationInstall = $AllowWorkstationInstall.IsPresent  # psa-disable-line PSA2001 -- script-param parent-scope lookup (switch params have no default-value form for PSA2001 recognition)
        # Populated by phases
        Os = $null
        # Paths is a nested PSCustomObject with the canonical $Ctx.Paths.*
        # sub-properties read by the Tier B-4 helpers ported verbatim from
        # the Chipset canon. NPU initialises this at $Ctx-construction
        # time (instead of P01 like Chipset) because the path layout is
        # known up-front from $WorkRoot - no workspace-bootstrap step
        # is needed before the values are valid.
        Paths = [pscustomobject]@{
            Root      = $WorkRoot
            Download  = Join-Path $WorkRoot 'download'
            Extract   = Join-Path $WorkRoot 'extracted'
            Patched   = Join-Path $WorkRoot 'patched'
            Cert      = $certDir
            Markers   = Join-Path $WorkRoot '.markers'
            Logs      = Join-Path $WorkRoot 'logs'
        }
        SevenZip = $null; Signtool = $null; Inf2cat = $null
        Installer = $null; InfInventory = $null; InfInventoryDetail = $null; PatchResults = @()
        PatchedDirs = @()  # rehydrated by Resume-CtxFromWorkspace
        CertPfxPath = Join-Path $certDir 'AMD-NPU-Driver-CodeSign.pfx'
        CertCerPath = Join-Path $certDir 'AMD-NPU-Driver-CodeSign.cer'
        CertThumbprint = $null  # populated by Invoke-PrepPhase07_CreateCertificate (Prepare) or Resume-CtxFromWorkspace (Verify / Install)
        SelectedPhaseIds = @()
        SecureBootBaseline = $null
        WhqlCoSignAnalysis = $null
        # ----- NPU-specific extensions -----
        # The NPU pipeline acquires its driver via AMD's account-gated
        # download (no public direct URL like Chipset / Graphics), so it
        # carries account credentials, the resolved package metadata, and
        # an optional offline-ZIP fast path. NPU also manages its own
        # WDAC supplemental policy artefacts ($Ctx.WdacBinPath / Xml /
        # PolicyName) which the AMD-family scripts express via $Ctx.Paths.*.
        AmdAccountUser     = $AmdAccountUser
        AmdAccountPassword = $AmdAccountPassword
        ForceAmdAccountAuth = [bool]$ForceAmdAccountAuth  # psa-disable-line PSA2001 -- script-param parent-scope lookup (switch params have no default-value form for PSA2001 recognition)
        AssumeIfMissing    = [bool]$AssumeIfMissing  # psa-disable-line PSA2001 -- script-param parent-scope lookup (switch params have no default-value form for PSA2001 recognition)
        NpuOverride        = $NpuOverride
        RyzenAiSoftwareVersion = $RyzenAiSoftwareVersion
        OfflineZip         = $OfflineZip
        RepoUrl            = $Script:RepoUrl
        NpuDriverPackage   = $NpuDriverPackage
        # DetectedPlatform: NPU-specific hashtable populated by P00 (OS / NPU
        # detection) and P03 (driver download / extraction). Previously
        # carried as $Script:DetectedPlatform; folded under $Ctx by the state-model refactor
        # for unified state management. Additional keys (ExtractedInfFiles,
        # PatchedCatFiles, etc.) are added dynamically by their producing
        # phases - this initialiser only declares the keys read before
        # those phases run, plus the canon-aligned subset.
        DetectedPlatform = @{
            OsCaption              = $null
            OsBuild                = $null
            OsProductType          = $null  # 1=Workstation, 3=Server
            OsProfile              = $null  # WS2016 / WS2019 / WS2022 / WS2025
            Inf2CatOsSwitch        = $null  # e.g. Server2025_X64
            IsWorkstationOs        = $null
            IsServer2025           = $null
            NpuCodename            = $null
            NpuShortName           = $null
            NpuHardwareId          = $null
            NpuRevision            = $null
            NpuIsDetected          = $false
            NpuDetectionSource     = $null
            CpuName                = $null
            NpuDriverPackage       = $null
            NpuDriverBuild         = $null
            NpuDriverZipName       = $null
            RyzenAiSoftwareVersion = $null
            RyzenAiSoftwareInstaller = $null
            DriverSoftwareCompatible = $null
            DriverSoftwareCompatNote = $null
            DownloadedZipPath      = $null
            DownloadedZipName      = $null
            SignToolPath           = $null
            Inf2CatPath            = $null
            SevenZipPath           = $null
            SecureBootBaseline     = $null
        }
        # NPU-specific flat workspace path properties. These pre-date the
        # NPU state-model refactor and remain in active use by the NPU
        # phase functions and helpers. Future stages may collapse them
        # into the canonical $Ctx.Paths.* layout used by Chipset / Graphics.
        CertDir            = $certDir
        DownloadDir        = Join-Path $WorkRoot 'download'
        ExtractedDir       = Join-Path $WorkRoot 'extracted'
        PatchedDir         = Join-Path $WorkRoot 'patched'
        CerPath            = Join-Path $certDir 'AMD-NPU-Driver-CodeSign.cer'
        PfxPath            = Join-Path $certDir 'AMD-NPU-Driver-CodeSign.pfx'
        CertSubjectCn      = 'AMD NPU Driver Self-Sign (WS2025 Lab, At Own Risk)'
        CertValidityYears  = $CertValidityYears
        # NPU-specific WDAC artefact paths
        WdacBinPath        = Join-Path $certDir 'WDAC-Supplemental-NPU.cip'
        WdacXmlPath        = Join-Path $certDir 'WDAC-Supplemental-NPU.xml'
        WdacPolicyName     = 'AMD-NPU-Driver-SelfSign-Lab'
        WdacPolicyGuid     = $Script:WdacPolicyGuid  # mirrored from script-scope; see file header
        # NPU-specific inventory artefacts (for P05 output)
        InventoryCsvPath    = Join-Path $WorkRoot 'inf_inventory.csv'
        InventoryReportPath = Join-Path $WorkRoot 'inf_inventory_report.txt'
    }

    # Banner (sister-script-aligned: include ScriptTag and ScriptHash)
    Write-Host ''
    Write-Host ('=' * 72) -ForegroundColor Cyan
    Write-Host (" {0}" -f $Script:ScriptName) -ForegroundColor Cyan
    Write-Host (" Version: {0}  [{1}]  SHA256: {2}" -f $Script:ScriptVersion, $Script:ScriptTag, $Script:ScriptHash) -ForegroundColor DarkCyan
    Write-Host (" Action : {0}" -f $Action) -ForegroundColor White
    Write-Host (" Repo   : {0}" -f $Script:RepoUrl) -ForegroundColor DarkCyan
    Write-Host ('=' * 72) -ForegroundColor Cyan
    Write-Host ''

    # ListPhases short-circuit
    if ($Action -eq 'ListPhases') {
        Show-PhaseList
        return
    }

    # Cleanup short-circuit
    if ($Action -eq 'Cleanup') {
        # Best-effort: even Cleanup needs admin + TLS for cert removal
        try { Assert-Admin } catch { throw }
        Set-TlsSecurityProtocol
        Set-Utf8PipelineEncoding
        Invoke-Cleanup -Ctx $Ctx
        return
    }

    # Resolve which phases to run
    $phaseIds = $null
    if ($Ctx.OnlyPhases -and $Ctx.OnlyPhases.Count -gt 0) {
        # Honor explicit -OnlyPhases override (split commas, trim, dedupe)
        $phaseIds = @()
        foreach ($entry in $Ctx.OnlyPhases) {
            foreach ($id in ($entry -split ',')) {
                $trimmed = $id.Trim()
                if (-not [string]::IsNullOrEmpty($trimmed)) {
                    $phaseIds += $trimmed
                }
            }
        }
        $phaseIds = $phaseIds | Select-Object -Unique
        Write-Caution ('-OnlyPhases override active: running {0} phase(s)' -f $phaseIds.Count)
        Write-Skip ('  Phases: {0}' -f ($phaseIds -join ', '))
    } else {
        $phaseIds = Get-PhaseListByAction -Action $Action
    }

    if (-not $phaseIds -or $phaseIds.Count -eq 0) {
        throw "No phases resolved for Action='$Action'."
    }

    # Block Install / All on Workstation OS unless explicitly allowed
    # (handled by I00 itself, but we also short-circuit here for clarity).
    # 'All' is the sister-script-aligned full-pipeline action that includes
    # I phases, so it must trigger the same Workstation gate as 'Install'.
    if ($Action -eq 'Install' -or $Action -eq 'All') {
        # Quick OS detect to know if we should warn upfront
        try {
            $os = Get-CimInstance Win32_OperatingSystem -ErrorAction Stop
            $productType = [int]$os.ProductType
            if ($productType -eq 1 -and -not $Ctx.AllowWorkstationInstall) {
                Write-Caution ''
                Write-Caution '------------------------------------------------------------------'
                Write-Caution ('Action={0} on Workstation OS detected.' -f $Action)
                Write-Caution 'I00 will block install phases. Use -AllowWorkstationInstall to'
                Write-Caution 'override (discouraged), or use Action=PrepareVerify on Win11 hosts.'
                Write-Caution '------------------------------------------------------------------'
                Write-Caution ''
            }
        } catch {
            # Non-fatal: let phase runner handle it
        }
    }

    # Execute the resolved phase list
    Invoke-PhaseRunner -Ctx $Ctx -PhaseIds $phaseIds

    # Post-Install / Post-All: show Ryzen AI Software guidance to the operator
    if ($Action -eq 'Install' -or $Action -eq 'All') {
        $allInstallPhasesOk = $true
        foreach ($id in @('I01','I02','I03','I04')) {
            $r = $Script:PhaseResults[$id]
            if (-not $r -or $r.Status -ne 'OK') {
                $allInstallPhasesOk = $false
                break
            }
        }
        if ($allInstallPhasesOk) {
            Show-RyzenAiSoftwareGuidance -Ctx $Ctx
        }
    }
}

# =============================================================================
# Top-level dispatch with try/finally for guaranteed run summary
# =============================================================================
$Script:TopLevelException = $null
try {
    Invoke-MainEntryPoint
}
catch {
    $Script:TopLevelException = $_
    Write-Host ''
    Write-Fail ('Top-level error: {0}' -f $_.Exception.Message)
    if ($_.ScriptStackTrace) {
        Write-Skip 'Stack trace:'
        foreach ($line in ($_.ScriptStackTrace -split "`n")) {
            Write-Skip ("    {0}" -f $line.TrimEnd())
        }
    }
}
finally {
    # Always print run summary (except on ListPhases, which has nothing to summarize)
    if ($Action -ne 'ListPhases') {
        try {
            Show-RunSummary -Ctx $Ctx -Action $Action
        } catch {
            Write-Caution ('Could not render run summary: {0}' -f $_.Exception.Message)
        }
    }

    # Final exit code: non-zero if there was an exception
    if ($Script:TopLevelException) {
        Write-Host ''
        Write-Fail 'Script terminated with errors. See messages above.'
        # Close the transcript opened above. Idempotent; best-effort,
        # must not mask the original exception (if any).
        if ($Script:LogFileActive) {
            try { Stop-Transcript -ErrorAction SilentlyContinue | Out-Null } catch { } # psa-disable-line PSA3004 -- intentional best-effort cleanup
            $Script:LogFileActive = $false
        }
        exit 1
    } else {
        Write-Host ''
        Write-Ok 'Script completed successfully.'
        # Close the transcript opened above. Idempotent; best-effort.
        if ($Script:LogFileActive) {
            try { Stop-Transcript -ErrorAction SilentlyContinue | Out-Null } catch { } # psa-disable-line PSA3004 -- intentional best-effort cleanup
            $Script:LogFileActive = $false
        }
        exit 0
    }
}

