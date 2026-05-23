<#
.SYNOPSIS
    AMD Graphics Driver Build/Verify/Install deployment pipeline for
    Windows Server 2016 / 2019 / 2022 / 2025.

.DESCRIPTION
    21-phase pipeline that takes the AMD Graphics Driver installer
    (designed for Client SKUs) and deploys it on a Windows SERVER SKU
    that does NOT officially support these drivers. The pipeline:

      Build (P00..P09): Download + extract the AMD installer, patch
                        every INF with ProductType=3 / NTamd64 server
                        decorations, generate fresh catalogs with
                        inf2cat, and sign them with a SELF-SIGNED code-
                        signing certificate created by this script.

      Verify (V01..V06): Confirm the build's correctness - certificate
                         chain, catalog signatures, INF decorations -
                         then dry-run the install phases and produce
                         a per-device AS-IS / TO-BE comparison with
                         driver-source categorization ([A] Microsoft,
                         [B] Vendor, [C] Self-signed) and version-
                         aware install decisions (UPGRADE / SKIP-newer
                         / NEW-INSTALL).

      Install (I00..I04): Trust the cert into LocalMachine\Root +
                          TrustedPublisher, authorize the cert as a
                          kernel-mode signer via a WDAC supplemental
                          policy (Secure Boot stays ON, no testsigning
                          needed on WS2022+ / Win11 22H2+), call
                          pnputil per patched INF, and verify the
                          per-device disposition.

    The default authorization path is WDAC supplemental policy. Use
    -UseTestSigning only when WDAC tools are unavailable; that path
    requires Secure Boot OFF in firmware and a reboot.

    DIFFERENCE FROM THE CHIPSET EDITION
    ===================================
    The chipset script probes 3 fixed AMD landing pages
    (X870E / X570 / mobile chipset) to find the latest AMD chipset
    .exe. THIS script does something different: it FIRST detects the
    AMD GPU/APU running on the host (Win32_PnPEntity for PCI\VEN_1002
    Display devices, falling back to Win32_Processor for APUs), THEN
    builds the AMD support page URL for that specific product, and
    only THEN probes for the installer .exe.

    Detection priority:
      1. Discrete AMD GPU (e.g. AMD Radeon RX 9070 XT)        -> dGPU
      2. AMD APU integrated graphics (e.g. AMD Ryzen 7 PRO 5750GE) -> APU
      3. Detection failure -> 5 default landing pages cover the
         major product lines (Ryzen Pro APU, Ryzen consumer APU,
         Radeon RX, Radeon AI Pro)
      4. Hard fallback: -AmdFallbackUrl (defaults to the lab system's
         Ryzen 7 PRO 5750GE product page)

    GRAPHICS DRIVERS ARE HIGHER-RISK THAN CHIPSET DRIVERS
    =====================================================
    A failed graphics-driver install can leave the system with NO
    DISPLAY OUTPUT (black screen). Recovery requires Safe Mode boot
    and pnputil rollback. Strongly recommended before -Action Install:
      - Take a full system image / VM snapshot
      - Have a Windows Recovery USB ready
      - Verify a System Restore point exists
      - Ensure RDP / out-of-band console access works (so you don't
        need the local display to recover)

    COEXISTENCE WITH THE CHIPSET EDITION
    ====================================
    This script uses a SEPARATE workspace (C:\Temp\Workspace_AMD-Graphics; was C:\AMD-Graphics-WS earlier), a SEPARATE certificate
    subject ('CN=AMD Graphics Driver Self-Sign ...'), and a SEPARATE
    WDAC supplemental policy ID. Running the chipset script first and
    the graphics script second produces TWO co-existing supplemental
    policies, both authorized to load self-signed kernel drivers.
    Neither overrides the other.

    ====================================================================
    IMPORTANT: WHEN TO USE THIS SCRIPT  (read this first)
    ====================================================================
    This script produces SELF-SIGNED kernel-mode drivers. Self-signed
    drivers should be a LAST-RESORT, gap-fill measure - used ONLY for
    devices that have no working OEM- or Microsoft-signed driver.

    Recommended pre-install workflow (in order):

      Step 1.  Install official VENDOR drivers (chipset, GPU, NIC, etc.)
               from the hardware manufacturer's website. These ship with
               valid OEM signatures, are recognized by Secure Boot
               natively, and do NOT need any of this script's policy
               work. Any device a vendor driver covers is one fewer
               device this script has to handle.

      Step 2.  Run Windows Update / Microsoft Update Catalog. Microsoft-
               distributed driver updates are signed by Microsoft and
               also load on Secure Boot without policy changes.

      Step 3.  Inspect Device Manager. Confirm the count of "Unknown
               device" / "Other device" / "yellow-bang" entries - those
               are the only devices THIS script should be expected to
               cover. Devices already served by Steps 1-2 should NOT be
               replaced by self-signed drivers.

      Step 4.  AFTER Steps 1-3 are complete, run THIS script. It will:
                 - Detect remaining AMD devices that have no Server-
                   decorated driver from the official path
                 - Re-sign AMD's Client INFs with ProductType=3 added
                 - Deploy a WDAC supplemental policy that allowlists
                   only this script's self-signed cert (Secure Boot
                   stays ON; no test-mode watermark; no firmware change)
                 - Install the patched drivers via pnputil

    Why this order matters:
      - Microsoft / OEM-signed drivers always rank higher than self-
        signed ones in Windows' driver-store ranking. If a vendor
        driver is installed later, it will (correctly) supersede the
        self-signed one - so the self-signed install is wasted work
        unless we are last.
      - Self-signed drivers expand the trust surface only to devices
        we genuinely cannot solve any other way. Doing Steps 1-2 first
        keeps that surface small.
      - V06 (HardwareImpactAnalysis) and I04 (PostInstallVerification)
        in this script ASSUME the system is already in its baseline,
        properly-driven state. If you skip Steps 1-2, V06's "AS-IS /
        TO-BE" comparison will be misleading.

    ====================================================================
    Pipeline phases
    ====================================================================
    PREPARATION (idempotent, file artifacts only under -WorkRoot):
      P00 Initialize         Admin check, TLS, OS detection, env display
                             (incl. boot-signing environment summary)
      P01 PrepareWorkspace   Create / optionally clean working directories
      P02 AcquireTools       Install 7-Zip / Windows SDK / Windows WDK
      P03 FetchInstaller     Download AMD chipset installer
      P04 ExtractInstaller   Extract installer + nested archives
      P05 AnalyzeInfs        Inventory INF files into CSV
      P06 PatchInfs          Generate ProductType=3 patched INFs
      P07 CreateCertificate  Generate self-signed cert files (PFX/CER)
                             - does NOT add to system trust stores
      P08 GenerateCatalogs   inf2cat to regenerate .cat files
      P09 SignCatalogs       signtool to sign .cat files

    VERIFICATION (read-only diagnostics, no system / file changes):
      V01 VerifyArtifacts    Existence of PFX/CER/INFs/CATs
      V02 VerifyCertificate  Cert validity, EKU, private key
      V03 VerifyCatalogs     signtool /verify /pa on each .cat
      V04 VerifyInfs         INF parsing + ProductType=3 decoration check
      V05 DryRunInstall      Simulate I03 without modifying state
      V06 HardwareImpactAnalysis
                             Per-device AS-IS / TO-BE risk classification

    INSTALLATION (modifies system state):
      I00 PreInstallReview   Final review, boot-signing env, risk summary
      I01 TrustCertificate   Import cert to LocalMachine\Root + TrustedPublisher
      I02 AuthorizeDriverSigning
                             Authorize self-signed driver loading. Default
                             path: WDAC supplemental policy (Secure Boot
                             stays ON; no reboot on WS2022+). Legacy path
                             via -UseTestSigning (requires Secure Boot off).
      I03 InstallDrivers     pnputil /add-driver for each patched INF
      I04 PostInstallVerification
                             Per-device disposition + functional probe

    All preparation phases are idempotent: re-running produces the same
    output. Each phase writes a marker file when complete; with -Force
    the marker is ignored and the phase re-runs from scratch.
    -CleanWorkRoot deletes the entire working directory before starting.

    ====================================================================
    RESUME AFTER REBOOT (just re-run the same command)
    ====================================================================
    Install phases I01/I02/I03 each START by inspecting the live system
    to see if their target end state is already present. If yes, the
    phase prints "Target state already holds - skipped" and moves on to
    the next phase. This means a single command works for all stages:

        # First run (anywhere from cold start):
        .\Deploy-AMDGraphicsDriverOnWindowsServer.ps1 -Action Install

        # If a reboot was requested, reboot, then re-run THE SAME
        # command. The script auto-detects which phases are already
        # done and continues from where it left off:
        .\Deploy-AMDGraphicsDriverOnWindowsServer.ps1 -Action Install

    The state validators check the actual system, not just marker files:
      I01: cert presence in LocalMachine\Root and \TrustedPublisher
      I02: WDAC supplemental policy in active CI policies stack
           (or BCD testsigning=Yes for -UseTestSigning path)
      I03: every patched .inf present in pnputil /enum-drivers output
      I04: always runs (it is the verification report)

    Pending-reboot tracking:
      When I02 (testsigning path) or I03 needs a reboot to finalize,
      the script writes a sentinel under .markers\PENDING_REBOOT.txt
      with the boot-time at which the marker was written. The next
      run's I00 inspects this and reports whether the reboot has
      happened. I04 deletes the sentinel once the system is in a good
      end state.

      You don't need to track any of this manually - just re-run the
      same command after rebooting and the script does the right thing.

    ====================================================================
    COEXISTENCE WITH THE CHIPSET / NPU / BTHPAN COMPANION SCRIPTS
    ====================================================================
    This script (GRAPHICS) is designed to live alongside the chipset,
    NPU, and BthPan companion scripts on the same Windows Server
    installation without conflict. Three design decisions enable this:

    [1] Working directory is fully separated.
        Default for THIS script: C:\Temp\Workspace_AMD-Graphics
        Default for the chipset script:            C:\Temp\Workspace_AMD-Chipset
        Default for the NPU script:                C:\Temp\Workspace_AMD-NPU
        Default for the BthPan script:             C:\Temp\Workspace_Microsoft-BthPan
        (workspaces are now relocated under C:\Temp\Workspace_*
        instead of directly under C:\. The script auto-creates
        C:\Temp itself if it does not yet exist.)
        Each workspace owns its own .markers/, cert/, download/,
        extracted/, patched/, logs/ subtrees. -CleanWorkRoot and
        -Action Cleanup operate ONLY on this workspace.

    [2] Self-signed certificate is per-script (NOT shared).
        Subject CN includes "Graphics" so the certmgr.msc display, the
        signed catalog files, and the WDAC supplemental policy all
        unambiguously identify which script the cert belongs to.
        Trust scope is per-cert: revoking the chipset cert does not
        affect graphics drivers, and vice versa. The trade-off is that
        you will see two AMD self-signed certs in LocalMachine\Root +
        \TrustedPublisher (one per category) - acceptable for lab use.

    [3] Concurrent execution is guarded.
        A workspace lock file (.markers\RUN.lock) is acquired in P01
        and held for the duration of the run. A second instance of
        THIS script against the SAME workspace will fail-fast with an
        actionable error. The graphics script uses a different
        workspace and therefore a different lock - they do NOT
        conflict at the lock level. However, BOTH scripts ultimately
        call pnputil /add-driver (in I03), and Windows allows only one
        driver-store mutation at a time. Therefore the recommendation
        for first-time users is:

            Run one script to completion (or to its reboot break),
            THEN start the other.

        For experienced users on stable hardware, running them in
        sequence within a single PowerShell session is also fine.

.NOTES
    Repository     : https://github.com/usui-tk/Deploy-Drivers-For-WindowsServer
    Sister scripts : Deploy-AMD{Chipset,Npu}DriverOnWindowsServer.ps1,
                     Deploy-MSBthPanInboxOnWindowsServer.ps1
    License        : MIT (see LICENSE)
    Current version: see `$Script:ScriptVersion` below

    - Run from an elevated PowerShell session.
    - Lab / verification use only - this is not a Microsoft-supported
      configuration.
    - Always perform Steps 1-2 (vendor drivers + Windows Update) BEFORE
      using this script. See "WHEN TO USE THIS SCRIPT" above.

.EXAMPLE
    # Default: full preparation only (no system changes outside tool install)
    .\Deploy-AMDGraphicsDriverOnWindowsServer.ps1

.EXAMPLE
    # Re-run only INF patching after editing the script
    .\Deploy-AMDGraphicsDriverOnWindowsServer.ps1 -OnlyPhases P06 -Force

.EXAMPLE
    # Wipe workspace and start over
    .\Deploy-AMDGraphicsDriverOnWindowsServer.ps1 -CleanWorkRoot

.EXAMPLE
    # After verification, deploy WDAC policy + install drivers (Secure Boot stays ON)
    .\Deploy-AMDGraphicsDriverOnWindowsServer.ps1 -Action Install

.EXAMPLE
    # End-to-end run (prep + verify + install)
    .\Deploy-AMDGraphicsDriverOnWindowsServer.ps1 -Action All

.EXAMPLE
    # Force the legacy testsigning path (requires Secure Boot off in firmware)
    .\Deploy-AMDGraphicsDriverOnWindowsServer.ps1 -Action Install -UseTestSigning

.EXAMPLE
    # Tear down the deployed WDAC supplemental policy and workspace
    .\Deploy-AMDGraphicsDriverOnWindowsServer.ps1 -Action Cleanup

.EXAMPLE
    # Capture full transcript while keeping console colors
    $ts  = Get-Date -Format 'yyyyMMdd-HHmmss'
    $log = "C:\Temp\amd-graphics_PrepareVerify_$ts.log"
    .\Deploy-AMDGraphicsDriverOnWindowsServer.ps1 `
        -Action PrepareVerify -CleanWorkRoot `
        -LogFile $log

.EXAMPLE
    # Legacy fallback (color is stripped from the captured file)
    .\Deploy-AMDGraphicsDriverOnWindowsServer.ps1 -Action Install *>&1 |
        Tee-Object -FilePath "C:\Temp\amd-graphics_Install_$(Get-Date -Format 'yyyyMMdd-HHmmss').log"

.EXAMPLE
    # Show formatted help inline
    .\Deploy-AMDGraphicsDriverOnWindowsServer.ps1 -Help

.PARAMETER Help
    Show a formatted help screen and exit. Aliases: -h, -?

.PARAMETER Action
    Pipeline mode. One of: Prepare (default), Verify, Install, All, Cleanup, ListPhases.

.PARAMETER OnlyPhases
    Run only the specified phase IDs (e.g. P05) or names (e.g. PatchInfs).
    P00 / P01 are always included implicitly.

.PARAMETER WorkRoot
    Working directory root. Default: C:\Temp\Workspace_AMD-Graphics
    (relocated under C:\Temp\Workspace_* to keep workspace data
    clustered under a single, easily-cleaned root.)

.PARAMETER CleanWorkRoot
    Delete -WorkRoot completely before running anything.

.PARAMETER Force
    Bypass cached phase markers and re-run each selected phase.

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
        C:\Temp\amd-graphics_<Action>_<yyyyMMdd-HHmmss>.log

.PARAMETER UseTestSigning
    Force the legacy bcdedit testsigning path in I02 instead of the
    default WDAC supplemental policy path. Requires Secure Boot off in
    firmware and a reboot. Use only when WDAC tools are unavailable or
    when you specifically need a testsigning lab.

.PARAMETER References
    Display the curated list of Microsoft Learn documentation links
    that explain the prerequisite knowledge for this script and exit.
    No admin / no work. Use this switch to learn about Secure Boot,
    test signing, WDAC, INF file structure, Windows SDK + WDK, and
    PnPUtil before running the script for real.

.LINK
    https://learn.microsoft.com/en-us/windows-hardware/drivers/bringup/secure-boot

.LINK
    https://learn.microsoft.com/en-us/windows-hardware/drivers/install/the-testsigning-boot-configuration-option

.LINK
    https://learn.microsoft.com/en-us/windows/security/application-security/application-control/windows-defender-application-control/

.LINK
    https://learn.microsoft.com/en-us/windows-hardware/drivers/display/sku-differentiation-directive

.LINK
    https://learn.microsoft.com/en-us/windows-hardware/drivers/install/inf-manufacturer-section

.LINK
    https://learn.microsoft.com/en-us/windows-hardware/drivers/install/combining-platform-extensions-with-operating-system-versions

.LINK
    https://learn.microsoft.com/en-us/windows-hardware/drivers/download-the-wdk

.LINK
    https://learn.microsoft.com/en-us/windows-hardware/drivers/devtest/pnputil-command-syntax

.LINK
    https://docs.kernel.org/gpu/amdgpu/amd-hardware-list-info.html

.LINK
    https://en.wikipedia.org/wiki/List_of_AMD_graphics_processing_units

.LINK
    https://www.amd.com/en/products/specifications/graphics.html

.LINK
    https://www.amd.com/en/products/specifications/processors.html
#>

#####################################################################
# MICROSOFT LEARN REFERENCE LIBRARY
#####################################################################
# This block is the user-facing reference index for the prerequisite
# knowledge required to understand what THIS SCRIPT does. The same
# content is also available at runtime via the -References switch
# (see Show-ReferenceLinks function later in the file).
#
# All URLs are en-US; for Japanese versions, replace "/en-us/" with
# "/ja-jp/" in the URL path. Both locales serve the same content tree.
#
# === [1] SECURE BOOT (UEFI signature enforcement) ==================
#   Why it matters: Secure Boot is what prevents this script's self-
#   signed kernel-mode drivers from loading by default. The WDAC path
#   in I02 keeps Secure Boot ENABLED while still loading the drivers.
#
#   - What Is Secure Boot for Windows
#     https://learn.microsoft.com/en-us/windows-hardware/drivers/bringup/secure-boot
#   - Secure Boot and Trusted Boot (chain-of-trust architecture)
#     https://learn.microsoft.com/en-us/windows/security/operating-system-security/system-security/trusted-boot
#   - Secure the Windows boot process (Secure Boot, Trusted Boot, ELAM, Measured Boot)
#     https://learn.microsoft.com/en-us/windows/security/operating-system-security/system-security/secure-the-windows-10-boot-process
#   - Secure Boot Key Creation and Management Guidance (PK / KEK / db / dbx)
#     https://learn.microsoft.com/en-us/windows-hardware/manufacture/desktop/windows-secure-boot-key-creation-and-management-guidance
#
# === [2] TEST SIGNING / DRIVER SIGNING POLICY ======================
#   Why it matters: The legacy I02 path (-UseTestSigning) uses BCD
#   testsigning. The WDAC path is the modern alternative this script
#   prefers; this section is here for context.
#
#   - Test Signing (overview of dev/lab signing process)
#     https://learn.microsoft.com/en-us/windows-hardware/drivers/install/test-signing
#   - The TESTSIGNING boot configuration option
#     https://learn.microsoft.com/en-us/windows-hardware/drivers/install/the-testsigning-boot-configuration-option
#   - BCDEdit /set (testsigning, nointegritychecks, etc.)
#     https://learn.microsoft.com/en-us/windows-hardware/drivers/devtest/bcdedit--set
#   - Installing an Unsigned Driver during Development and Test
#     https://learn.microsoft.com/en-us/windows-hardware/drivers/install/installing-an-unsigned-driver-during-development-and-test
#   - How to Test Preproduction Drivers with Secure Boot Enabled
#     https://learn.microsoft.com/en-us/windows-hardware/drivers/install/preproduction-driver-signing-and-install
#
# === [3] WDAC / APP CONTROL FOR BUSINESS ===========================
#   (formerly Windows Defender Application Control)
#   Why it matters: This is the I02 default path. The script builds a
#   supplemental policy that adds its self-signed cert as a kernel-
#   mode signer, deploys via CiTool, and reverses cleanly via Cleanup.
#
#   - Application Control / WDAC documentation root
#     https://learn.microsoft.com/en-us/windows/security/application-security/application-control/windows-defender-application-control/
#   - Use multiple App Control policies (base + supplemental design)
#     https://learn.microsoft.com/en-us/windows/security/application-security/application-control/windows-defender-application-control/design/deploy-multiple-wdac-policies
#   - Deploy App Control policies using script (CiTool --update-policy)
#     https://learn.microsoft.com/en-us/windows/security/application-security/application-control/windows-defender-application-control/deployment/deploy-wdac-policies-with-script
#   - Remove App Control policies (CiTool --remove-policy)
#     https://learn.microsoft.com/en-us/windows/security/application-security/application-control/windows-defender-application-control/deployment/disable-wdac-policies
#
# === [4] INF FILE STRUCTURE ========================================
#   Why it matters: The whole P05/P06 phase is INF-section parsing
#   and patching. ProductType=3 in the [Manufacturer] decoration is
#   what makes a Client INF apply to Windows Server.
#
#   ** PRIMARY REFERENCE for this script's core technique: **
#   - SKU Differentiation Directive
#     The authoritative document describing how IHVs use TargetOSVersion
#     ProductType to make INFs valid on Server vs Client SKUs. Defines
#     the three ProductType values:
#         0x0000001 (VER_NT_WORKSTATION)
#         0x0000002 (VER_NT_DOMAIN_CONTROLLER)
#         0x0000003 (VER_NT_SERVER)
#     And clarifies the default behavior: an INF whose [Manufacturer]
#     decoration omits ProductType (or uses an empty field) installs on
#     ALL SKUs (Workstation + Server). This is why P06's strategy of
#     ADDING explicit '...3...' mirrors works, and is also why V04 must
#     accept empty ProductType as Server-compatible.
#     https://learn.microsoft.com/en-us/windows-hardware/drivers/display/sku-differentiation-directive
#
#   - Summary of INF Sections (Version, Manufacturer, Models, DDInstall,...)
#     https://learn.microsoft.com/en-us/windows-hardware/drivers/install/summary-of-inf-sections
#   - General Syntax Rules for INF Files
#     https://learn.microsoft.com/en-us/windows-hardware/drivers/install/general-syntax-rules-for-inf-files
#   - INF Manufacturer Section (TargetOSVersion, ProductType=3 etc.)
#     https://learn.microsoft.com/en-us/windows-hardware/drivers/install/inf-manufacturer-section
#   - INF Models Section
#     https://learn.microsoft.com/en-us/windows-hardware/drivers/install/inf-models-section
#   - Combining Platform Extensions with Operating System Versions
#     The authoritative TargetOSVersion grammar:
#         nt[Architecture][.[OSMajorVersion][.[OSMinorVersion][.[ProductType][.[SuiteMask][.[BuildNumber]]]]]]
#     Note that each field is INDEPENDENTLY OPTIONAL - a decoration
#     like 'NTamd64.10.0...22000' (ProductType + SuiteMask both empty,
#     BuildNumber=22000) is valid and matches every product type.
#     https://learn.microsoft.com/en-us/windows-hardware/drivers/install/combining-platform-extensions-with-operating-system-versions
#   - Creating INF Files for Multiple Platforms and Operating Systems
#     https://learn.microsoft.com/en-us/windows-hardware/drivers/install/creating-inf-files-for-multiple-platforms-and-operating-systems
#   - Using a Universal INF File (declarative-only restrictions)
#     https://learn.microsoft.com/en-us/windows-hardware/drivers/install/using-a-universal-inf-file
#
# === [5] WINDOWS SDK + WDK =========================================
#   Why it matters: P02 acquires these because P08 needs inf2cat (WDK)
#   and P09 needs signtool (SDK).
#
#   - Download the Windows Driver Kit (WDK) - includes inf2cat
#     https://learn.microsoft.com/en-us/windows-hardware/drivers/download-the-wdk
#   - Windows SDK downloads - includes signtool
#     https://learn.microsoft.com/en-us/windows/apps/windows-sdk/downloads
#   - Install the WDK using WinGet
#     https://learn.microsoft.com/en-us/windows-hardware/drivers/install-the-wdk-using-winget
#   - Install the WDK using NuGet
#     https://learn.microsoft.com/en-us/windows-hardware/drivers/install-the-wdk-using-nuget
#   - Kits and tools overview (relationships between SDK / WDK / EWDK / HLK)
#     https://learn.microsoft.com/en-us/windows-hardware/get-started/kits-and-tools-overview
#   - Running InfVerif from the Command Line (validate INF files)
#     https://learn.microsoft.com/en-us/windows-hardware/drivers/devtest/running-infverif-from-the-command-line
#
# === [6] PNPUTIL (driver-store management) =========================
#   Why it matters: I03 calls pnputil /add-driver. I04 / V05 use
#   /enum-drivers. Cleanup advice references /delete-driver.
#
#   - PnPUtil overview
#     https://learn.microsoft.com/en-us/windows-hardware/drivers/devtest/pnputil
#   - PnPUtil Command Syntax (full flag reference, exit codes)
#     https://learn.microsoft.com/en-us/windows-hardware/drivers/devtest/pnputil-command-syntax
#   - PnPUtil Command Examples (typical workflows)
#     https://learn.microsoft.com/en-us/windows-hardware/drivers/devtest/pnputil-examples
#   - Create Installed Driver Package Inventory (audit installed drivers)
#     https://learn.microsoft.com/en-us/windows-hardware/drivers/driversecurity/create-a-driver-inventory
#
# === [7] AMD GPU TAXONOMY ==========================================
#   Why it matters: P03 uses Get-AmdDriverBranchPreference to decide
#   between AMD's MAIN Adrenalin branch and the LEGACY vega-polaris
#   branch. The decision is rooted in the architecture generation
#   (GCN 1-5 / RDNA 1-4) of the user's GPU/APU silicon. Picking the
#   wrong branch silently no-ops the install (the driver lands in
#   the driver store but no device's HWID matches the [Models]
# section, so PnP never binds it).
#
#   The script now uses TWO complementary sources for branch decision:
#
#   (a) Live AMD page query - the script fetches the AMD product spec
#       page that corresponds to the detected CPU/APU/GPU and extracts
#       the "Former Codename" field that AMD publishes on every
#       product page. For example:
#         /processors/.../amd-ryzen-7-pro-5750ge.html -> "Cezanne"
#         /processors/.../amd-ryzen-7-pro-4750ge.html -> "Renoir"
#         /graphics/.../amd-radeon-rx-9070-xt.html -> "Navi 4x"
#       The codename is then looked up in $Script:AmdCodenameMap to
#       determine the architecture and branch. This is the
#       AUTHORITATIVE path because the codename comes directly from
#       AMD's own spec.
#
#   (b) Heuristic fallback - if (a) fails (network error, page format
#       mismatch, codename not in map), the script falls back to a
#       name-pattern + series-number heuristic that catches the most
#       common configurations including known traps like Ryzen 7x30
#       (Barcelo-R Vega rebrand into the 7000 series).
#
#   ** PRIMARY REFERENCES (codename / architecture mapping): **
#   - AMD CPU/APU specifications (used for live "Former Codename" lookup)
#     The complete AMD CPU/APU catalog. Each individual product page
#     in this catalog exposes a "Former Codename" field that the
#     script queries at runtime to determine the iGPU architecture.
#     https://www.amd.com/en/products/specifications/processors.html
#   - AMD Graphics specifications (used for live dGPU lookup)
#     https://www.amd.com/en/products/specifications/graphics.html
#   - AMD Hardware Components Information per Product (Linux kernel)
#     The cleanest, most authoritative public table mapping retail
#     product names (Ryzen 5000, Ryzen 7x30, RX 9070 XT, etc.) to
#     internal codenames and Graphics Core (GC) version numbers.
#     The GC version is the architecture identifier that determines
#     branch eligibility:
#         GC 6 / 7 / 8 -> GCN 1-4 (pre-Polaris / Polaris) -> Legacy
#         GC 9.x -> GCN 5 (Vega) -> Legacy
#         GC 10.x -> RDNA 1 (10.1) / RDNA 2 (10.3) -> Main
#         GC 11.x -> RDNA 3 (11.0) / RDNA 3.5 (11.5) -> Main
#         GC 12.x -> RDNA 4 -> Main
#     Critical entry this table reveals (which a naive series-number
#     heuristic misses):
#         "Ryzen 5000 series / Ryzen 7x30 series" -> GREEN_SARDINE /
#         Cezanne / Barcelo / Barcelo-R -> GC 9.3 = Vega
#         (i.e., Ryzen 7x30 mobile is a Vega rebrand even though the
#         model number suggests an RDNA-class 7000-series part)
#     https://docs.kernel.org/gpu/amdgpu/amd-hardware-list-info.html
#
#   ** SECONDARY REFERENCES: **
#   - List of AMD graphics processing units (Wikipedia)
#     Cross-reference for SKU -> microarchitecture (GCN 1-5 / RDNA 1-4)
#     -> instruction set generation (GFX6 -> GFX12) -> launch year.
#     Useful for older or rare SKUs not listed in the kernel doc.
#     https://en.wikipedia.org/wiki/List_of_AMD_graphics_processing_units
#
#   - AMD Software: Adrenalin Edition (release notes / branch policy)
#     Documents which GPU families each Adrenalin release officially
#     supports. Confirms the Adrenalin branch split (Main vs Vega-
#     Polaris legacy) introduced around Adrenalin 23.11.1 (Nov 2023).
#     https://www.amd.com/en/products/software/adrenalin.html
#####################################################################

[CmdletBinding()]
param(
    # === Help ========================================================
    # Show formatted usage information and exit.
    [Alias('h','?')]
    [switch]$Help,

    # === References =================================================
    # Display the curated list of Microsoft Learn documentation links
    # that explain the prerequisite knowledge for this script (Secure
    # Boot, test signing, WDAC, INF files, Windows SDK + WDK, PnPUtil)
    # and exit. No system changes; no admin required.
    [switch]$References,

    # === Action selection ============================================
    # PrepareVerify is the default: runs all preparation phases (P00-P09)
    # followed immediately by all verification phases (V01-V05). This
    # gives the user a complete dry-run that produces all artifacts AND
    # validates them, without modifying the running OS.
    [ValidateSet('Prepare','Verify','PrepareVerify','Install','All','Cleanup','ListPhases')]
    [string]$Action = 'PrepareVerify',

    # Specific phases to run; empty = all phases for the action.
    # Accepts ID ('P05') or short name ('PatchInfs').
    [string[]]$OnlyPhases = @(),

    # === AMD installer source =========================================
    [string]$InstallerUrl    = '',
    # AMD support pages used as landing pages when GPU/APU detection
    # fails. The 5 URLs below cover the user's lab APU (Ryzen 7 PRO
    # 5750GE - same family as 5755GE), an additional Ryzen Pro APU
    # generation, a consumer Ryzen APU, a consumer dGPU, and an AI Pro
    # workstation dGPU - i.e. the four major product lines that ship
    # AMD graphics drivers. Get-AmdGpuTarget at runtime will detect
    # the actual GPU/APU and PREPEND the resolved product page to this
    # list, keeping these 5 as a fallback.
    [string[]]$AmdLandingUrls = @(
        'https://www.amd.com/ja/support/downloads/drivers.html/processors/ryzen-pro/ryzen-pro-5000-series/amd-ryzen-7-pro-5755ge.html',
        'https://www.amd.com/ja/support/downloads/drivers.html/processors/ryzen-pro/ryzen-pro-4000-series/amd-ryzen-7-pro-4750ge.html',
        'https://www.amd.com/ja/support/downloads/drivers.html/processors/ryzen/ryzen-5000-series/amd-ryzen-7-5800u.html',
        'https://www.amd.com/ja/support/downloads/drivers.html/graphics/radeon-rx/radeon-rx-9000-series/amd-radeon-rx-9070-xt.html',
        'https://www.amd.com/ja/support/downloads/drivers.html/graphics/radeon-ai-pro/radeon-ai-pro-r9000-series/amd-radeon-ai-pro-r9700.html'
    ),
    # Last-resort URL when ALL probing fails. Points at the user's lab
    # APU (Ryzen 7 PRO 5750GE) AMD support page - best educated guess
    # if nothing else worked.
    [string]$AmdFallbackUrl  = 'https://www.amd.com/ja/support/downloads/drivers.html/processors/ryzen-pro/ryzen-pro-5000-series/amd-ryzen-7-pro-5750ge.html',

    # === Workspace ====================================================
    # Default workspace path is intentionally GRAPHICS-specific so the
    # chipset, NPU, and BthPan companion scripts do NOT collide with
    # this one. Pass -WorkRoot to override (for example, if you
    # previously used 'C:\AMD-Graphics-WS' or 'C:\AMD-WS'
    # and want to keep that workspace).
    #
    # Relocated under C:\Temp\Workspace_* to keep workspace data
    # clustered under one parent directory that is trivial to inspect
    # and purge. The script auto-creates C:\Temp if it does not exist.
    [string]$WorkRoot      = 'C:\Temp\Workspace_AMD-Graphics',
    [switch]$CleanWorkRoot,
    [switch]$Force,

    # === Console transcript capture ============================
    # Optional path; when set, the script wraps its execution in
    # Start-Transcript / Stop-Transcript so the file gets every stream
    # as plain text while the live console keeps its Write-Host color
    # decoration. This is the recommended replacement for the legacy
    # `... *>&1 | Tee-Object -FilePath...` idiom, which strips
    # Write-Host coloring on the way through the pipeline.
    [string]$LogFile       = '',

    # === Driver-load authorization mode ===============================
    # By default, I02 deploys a WDAC supplemental Code Integrity policy
    # that allowlists this script's self-signed cert as a kernel-mode
    # signer. This keeps Secure Boot ENABLED and does not require any
    # firmware changes. Pass -UseTestSigning to fall back to the legacy
    # bcdedit testsigning approach (which requires Secure Boot OFF in
    # firmware - the script will refuse if Secure Boot is on, unless
    # -Force is also passed).
    [switch]$UseTestSigning,

    # === Workstation override =========================================
    # By default the script REFUSES to run any Install phase (I01-I04)
    # on a Workstation OS (ProductType=1, e.g. Windows 10 / Windows 11).
    # The intended use case for these scripts is Windows Server 2025+
    # hosts. Workstation Windows is supported only as a "preview /
    # pre-migration verification" target, where -Action PrepareVerify
    # is used to validate the script end-to-end before the host is
    # wiped and re-installed with Windows Server.
    #
    # Pass this switch to override that block. You almost certainly
    # do NOT want this on a laptop with BitLocker enabled, because
    # the graphics Install path replaces the AMD display / audio
    # drivers and may invalidate vendor signatures. See P00's banner
    # output for the full reasoning.
    [switch]$AllowWorkstationInstall,

    # === Certificate ==================================================
    # NOTE: [string] (not [SecureString]) because the password is forwarded to
    # signtool.exe via /p and to X509Certificate2(.., String) — both of these
    # APIs require a plaintext String. SecureString would have to be unwrapped
    # at the call site anyway. The default value below is an intentional
    # placeholder; rotate this in real deployments.
    [string]$PfxPassword   = 'ChangeMe!2026',  # psa-disable-line PSA5001 -- signtool /p and X509Certificate2 require plaintext String; default is a placeholder
    [string]$TimestampUrl  = 'http://timestamp.digicert.com',

    # === WDAC supplemental policy GUID overrides ======================
    # By default, the script uses a fixed PolicyID for its WDAC
    # supplemental policy (see $Script:WdacPolicyGuidDefault below).
    # This means re-runs deploy / replace the same policy slot rather
    # than accumulating one new policy per run.
    #
    # -WdacPolicyGuid:
    #   Override the supplemental policy GUID. Useful for two cases:
    #     1) Cleanup of a legacy deploy: such deploys used
    #        a dynamically-generated PolicyID, recorded in
    #        <workspace>\cert\AmdSuppPolicyId.txt. To remove a legacy
    #        policy, run:
    #          .\Deploy-AMDGraphicsDriverOnWindowsServer.ps1 -Action Cleanup `
    #              -WdacPolicyGuid <PolicyId from AmdSuppPolicyId.txt>
    #     2) Side-by-side deploy of multiple copies of this script with
    #        different PolicyIDs.
    #   Accepts GUID with or without surrounding braces.
    [string]$WdacPolicyGuid     = '',

    # -WdacBasePolicyGuid:
    #   Override the SupplementsBasePolicyID written into the
    #   supplemental policy. By default this is the Microsoft standard
    #   base policy ID {A244370E-44C9-4C06-B551-F6016E563076} (the
    #   Windows-shipped default CI base policy). changed the
    #   default away from a non-standard value used in earlier versions
    #   ({B355481F-...}) that does not correspond to any Microsoft-
    #   shipped base policy. Change only if your environment uses a
    #   custom base policy that this supplemental should extend.
    [string]$WdacBasePolicyGuid = '',

    # === Debug Trace Facility ===================================
    # When set, the script unconditionally writes a
    # debugtrace_export_final_<timestamp>.json snapshot to
    # <WorkRoot>\logs at the end of the run, whether the run succeeded
    # or failed. This is the post-mortem companion to the always-on
    # JSONL stream and the auto-on-failure exports - useful when you
    # want a single self-contained file to inspect or to attach to a
    # bug report, even when nothing actually failed.
    [switch]$ExportTraceOnExit,

    # r69 (QI-6): bypass the CRITICAL acknowledgement checklist in
    # I00. Intended for CI/CD or controlled-lab automation where an
    # interactive Read-Host prompt is not possible. The bypass is
    # logged via Set-DebugStep in the run transcript so an audit can
    # reconstruct whether C1/C2/C5 were ever surfaced. NEVER use
    # in production without out-of-band review. See SPEC SS D.28.
    [switch]$ForceUnsafe,

    # Skip the non-WHQL-co-signed subset of the install plan.
    # When this switch is set, P05's WHQL co-sign analysis is used to
    # trim P06 / P07 / P08 / I03 to only the INFs whose .sys files all
    # carry a Microsoft Windows Hardware Compatibility co-signature.
    # Use this when the host must keep UEFI Secure Boot ENABLED in
    # firmware and Path B (testsigning) is not acceptable. The non-
    # WHQL subset is reported but not installed; operators who need
    # those devices must accept Path B or leave the device unbound.
    # See SPEC SS D.31 for the design rationale.
    [switch]$SkipNonCosignedDrivers
)

$ErrorActionPreference = 'Stop'
$ProgressPreference    = 'SilentlyContinue'

# Cache the param() values into $Script: scope so phase functions can read them
# without re-binding param() variables across function-call boundaries.
$Script:ForceUnsafe = [bool]$ForceUnsafe.IsPresent
$Script:SkipNonCosignedDrivers = [bool]$SkipNonCosignedDrivers.IsPresent

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
$Script:ScriptVersion = 'graphics-2026.05.23-r38'
$Script:ScriptTag     = 'legacy-ws2019-wdac-spf-integration'
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
# Target: <script-dir>\Deploy-AMDGraphicsDriverOnWindowsServer_<Action>_<ts>.log
# Fallback: %TEMP%\Deploy-AMDGraphicsDriverOnWindowsServer_<Action>_<ts>.log
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
            $newLogLeaf  = ('Deploy-AMDGraphicsDriverOnWindowsServer_{0}_{1}.log' -f $Action, $ts)
            $newLogFile  = Join-Path $targetDir $newLogLeaf

            Write-Warning '[-LogFile guard] Specified -LogFile is inside -WorkRoot:'
            Write-Warning ('     -LogFile  : {0}' -f $resolvedLog)
            Write-Warning ('     -WorkRoot : {0}' -f $resolvedWorkRoot)
            Write-Warning '   With -CleanWorkRoot set, the P01 wipe would collide with the active'
            Write-Warning '   Start-Transcript file handle. Auto-relocating transcript to a safe path:'
            Write-Warning ('     New -LogFile -> {0}' -f $newLogFile)
            Write-Warning '   Tip: pass -LogFile outside -WorkRoot to avoid this notice. Example:'
            Write-Warning ("       `$ts  = Get-Date -Format 'yyyyMMdd-HHmmss'")
            Write-Warning ("       `$log = `"C:\Temp\Deploy-AMDGraphicsDriverOnWindowsServer_{0}_`$ts.log`"" -f $Action)
            Write-Warning '       .\Deploy-AMDGraphicsDriverOnWindowsServer.ps1 -Action <Action> -CleanWorkRoot -LogFile $log'

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
        Write-Warning '       .\Deploy-AMDGraphicsDriverOnWindowsServer.ps1 -Action PrepareVerify *>&1 | Tee-Object -FilePath C:\Temp\out.log'
        $Script:LogFileActive = $false
    } finally {
        $logSetupSw.Stop()
        $Script:LogFileSetup.ElapsedMs = $logSetupSw.ElapsedMilliseconds
        if ($Script:LogFileActive) {
            Write-Host ('[*] Transcript setup elapsed: {0} ms' -f $Script:LogFileSetup.ElapsedMs) -ForegroundColor DarkGray
        }
    }
}

#####################################################################
# SECTION 0.5: WDAC supplemental policy GUID configuration #####################################################################
# Previously the supplemental PolicyID was generated dynamically with
# Set-CIPolicyIdInfo -ResetPolicyID and persisted to the workspace as
# AmdSuppPolicyId.txt. The base policy ID it supplemented was a
# non-standard value {B355481F-55DA-5D17-C662-07127F674187} which does
# not correspond to any Microsoft-shipped CI base policy (almost
# certainly a copy-paste error from earlier development).
#
# Now:
#   - PolicyID: fixed UUID v4, graphics-specific so it does not
#                  collide with the chipset or NPU scripts' WDAC
#                  policies on a host that has all three deployed.
#                  Override via -WdacPolicyGuid.
#   - BasePolicyID: now defaults to the Microsoft standard base
#                  policy ID {A244370E-44C9-4C06-B551-F6016E563076},
#                  the same value used by the chipset and NPU
#                  scripts. Override via -WdacBasePolicyGuid.
$Script:WdacPolicyGuidDefault     = '85336828-3080-41C5-81EC-FD587DC090D3'
$Script:WdacBasePolicyGuidDefault = 'A244370E-44C9-4C06-B551-F6016E563076'

# Resolved values (use operator override if non-empty, else default).
$Script:WdacPolicyGuid = if (-not [string]::IsNullOrWhiteSpace($WdacPolicyGuid)) {
    $WdacPolicyGuid.Trim('{','}','(',')',' ')
} else {
    $Script:WdacPolicyGuidDefault
}
$Script:WdacBasePolicyGuid = if (-not [string]::IsNullOrWhiteSpace($WdacBasePolicyGuid)) {
    $WdacBasePolicyGuid.Trim('{','}','(',')',' ')
} else {
    $Script:WdacBasePolicyGuidDefault
}

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
    # lines that compose a label-then-value pair.
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

function Show-DriverInstallationOrderNotice {
    # Prominent reminder of the recommended driver-installation order.
    # Self-signed drivers (the output of this script) MUST come last,
    # AFTER any official OEM- or Microsoft-signed drivers are already
    # in place. Without that, this script's policy work is wasted on
    # devices that have a better-signed alternative available, AND the
    # baseline V06 / I04 comparisons become misleading because the
    # "AS-IS" state is incomplete.
    #
    # Two display modes:
    #   -Compact: 4-line summary used by the P00 startup banner
    #   (default): full 30-line block used by I00 PreInstallReview
    #               and -Help
    param([switch]$Compact)

    if ($Compact) {
        Write-Host ''
        Write-Host '    PREREQUISITE WORKFLOW (do these BEFORE running this script):' -ForegroundColor Yellow
        Write-Host '      1. Install official VENDOR drivers (chipset/GPU/NIC) from manufacturer site' -ForegroundColor Yellow
        Write-Host '      2. Run Windows Update / Microsoft Update Catalog'                            -ForegroundColor Yellow
        Write-Host '      3. THEN run this script for any AMD devices still without a working driver' -ForegroundColor Yellow
        Write-Host '    (at install-decision layer [C] self-signed outranks [B]/[A]; SPEC D.15)'   -ForegroundColor DarkYellow
        return
    }

    Write-Host ''
    Write-Host '+------------------------------------------------------------------------+' -ForegroundColor Yellow
    Write-Host '|  IMPORTANT: Recommended driver installation order                      |' -ForegroundColor Yellow
    Write-Host '+------------------------------------------------------------------------+' -ForegroundColor Yellow
    Write-Host '|  This script produces SELF-SIGNED kernel-mode drivers. The recommended |' -ForegroundColor Yellow
    Write-Host '|  operator workflow is to use OEM / Windows Update drivers FIRST and    |' -ForegroundColor Yellow
    Write-Host '|  reserve this script for devices those channels do not cover.         |' -ForegroundColor Yellow
    Write-Host '|                                                                        |' -ForegroundColor Yellow
    Write-Host '|  Pre-install workflow (in order):                                      |' -ForegroundColor Yellow
    Write-Host '|                                                                        |' -ForegroundColor Yellow
    Write-Host '|    Step 1.  Install official VENDOR drivers (chipset, GPU, NIC, etc.) |' -ForegroundColor Yellow
    Write-Host '|             from the hardware manufacturer''s website. Any device a    |' -ForegroundColor Yellow
    Write-Host '|             vendor driver covers is one fewer device this script      |' -ForegroundColor Yellow
    Write-Host '|             needs to handle.                                           |' -ForegroundColor Yellow
    Write-Host '|                                                                        |' -ForegroundColor Yellow
    Write-Host '|    Step 2.  Run Windows Update / Microsoft Update Catalog. MS-signed  |' -ForegroundColor Yellow
    Write-Host '|             drivers load on Secure Boot WITHOUT any policy changes.   |' -ForegroundColor Yellow
    Write-Host '|                                                                        |' -ForegroundColor Yellow
    Write-Host '|    Step 3.  Inspect Device Manager. Confirm "Unknown device" /        |' -ForegroundColor Yellow
    Write-Host '|             "yellow-bang" entries - those are what this script        |' -ForegroundColor Yellow
    Write-Host '|             should cover. Run -Action PrepareVerify and inspect V06   |' -ForegroundColor Yellow
    Write-Host '|             Section 2 to see exactly which [A]/[B] drivers the script |' -ForegroundColor Yellow
    Write-Host '|             will replace with [C] before committing to -Action Install.|' -ForegroundColor Yellow
    Write-Host '|                                                                        |' -ForegroundColor Yellow
    Write-Host '|    Step 4.  AFTER Steps 1-3 are complete, run THIS script.            |' -ForegroundColor Yellow
    Write-Host '|                                                                        |' -ForegroundColor Yellow
    Write-Host '|  Why this order matters:                                               |' -ForegroundColor Yellow
    Write-Host '|    - V06 (HardwareImpactAnalysis) and I04 (PostInstallVerification)   |' -ForegroundColor Yellow
    Write-Host '|      ASSUME the system is already in its baseline driven state.       |' -ForegroundColor Yellow
    Write-Host '|      If you skip Steps 1-2, more devices fall into the "replaced by   |' -ForegroundColor Yellow
    Write-Host '|      [C]" bucket than necessary, growing the trust surface.           |' -ForegroundColor Yellow
    Write-Host '|    - Self-signed drivers expand the trust surface only to devices we  |' -ForegroundColor Yellow
    Write-Host '|      genuinely cannot solve any other way. Doing Steps 1-2 first      |' -ForegroundColor Yellow
    Write-Host '|      keeps that surface small.                                         |' -ForegroundColor Yellow
    Write-Host '+------------------------------------------------------------------------+' -ForegroundColor Yellow
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
# SECTION 1c: Boot-signing environment (Secure Boot / testsigning /
# HVCI / VBS / Memory Integrity)
#####################################################################
# These helpers inspect every system-level setting that controls
# whether a self-signed kernel-mode driver can load. They are read-only
# and intended to be called from:
#   - Show-PowerShellEnvironment (P00 startup banner, compact line)
#   - I00 PreInstallReview (dedicated section with AS-IS / TO-BE)
#   - I02 AuthorizeDriverSigning (pre-check + AS-IS / TO-BE)
#   - I04 PostInstallVerification (post-reboot effective state)
#
# Why this matters for this script:
#   This script signs catalogs with a SELF-SIGNED certificate (P07).
#   Windows will refuse to load a kernel-mode driver bound to such a
#   catalog UNLESS:
#     (a) Secure Boot is OFF in firmware (UEFI setup) AND
#     (b) BCD testsigning is ON (set by I02, takes effect at boot) AND
#     (c) HVCI / Memory Integrity is OFF (otherwise CI policy still
#         enforces Microsoft-rooted signing)
#   If ANY of (a), (b), (c) is wrong, the user can run pnputil all day
#   and the driver will load briefly then be refused / reverted.
#
# Secure Boot can ONLY be disabled in firmware (UEFI setup), not from
# Windows. This script can detect, instruct, and refuse to enable
# testsigning when Secure Boot is on (because the bcdedit setting
# would be silently dropped on next boot).

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
        Reasons    = @($reasons)
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

function Get-OrEnsureSecureBootBaseline {
    # Port from chipset: idempotent accessor for the cached
    # Secure Boot baseline. Returns $Ctx.SecureBootBaseline when it is
    # still valid; otherwise re-invokes Get-SecureBootBaselineSnapshot
    # into the current $Ctx.WorkRoot so the diagnostic files
    # (detect_stdout.log, detect_stdout_extracted.json) are co-located
    # with the workspace.
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
            Write-Warn2 ("Secure Boot baseline (re-)capture failed: {0}" -f $_.Exception.Message)
        }
    }

    return $Ctx.SecureBootBaseline
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

function Get-BootSigningEnvironment {
    # Returns a flat object describing the runtime boot-signing state.
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

function Update-BootSigningEnvironmentForCtx {
    # Companion to Get-BootSigningEnvironment that also fills in the
    # AmdSuppPolicyActive / AmdSuppPolicyId fields by consulting the
    # workspace marker file. Use this from any phase that has a $Ctx
    # in scope. The plain Get-BootSigningEnvironment is safe to call
    # at startup before $Ctx is populated.
    param([Parameter(Mandatory)] $Ctx)
    $env = Get-BootSigningEnvironment
    $deployed = Test-AmdWdacPolicyDeployed -Ctx $Ctx
    if ($deployed) {
        $env.AmdSuppPolicyActive = $true
        $env.AmdSuppPolicyId     = $deployed.PolicyId
        # Recompute effective with this updated knowledge
        $env.BlockReasons = @($env.BlockReasons | Where-Object {
            $_ -ne 'No WDAC supplemental policy authorizes the AMD self-signing certificate'
        })
        $path2Open = ($env.SecureBootEnabled -ne $true) -and `
                     ($env.TestSigningEnabled -eq $true) -and `
                     (-not $env.HvciRunning)
        $env.EffectiveCanLoadSelfSigned = ($true -or $path2Open)  # path1 is open
        return $env
    }
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

function Show-BootSigningChangeRequired {
    # Side-by-side AS-IS / TO-BE display. The TO-BE keeps Secure Boot
    # ENABLED whenever possible and prefers the WDAC supplemental
    # policy path (script-managed) over disabling Secure Boot.
    # Falls back to documenting the legacy testsigning path only when
    # WDAC tools are not available.
    param([Parameter(Mandatory)] $BootEnv)

    function _Status($v) {
        if ($null -eq $v) { return '?' }
        if ($v -eq $true)  { return 'ON' }
        return 'off'
    }

    $useWdac = $BootEnv.WdacToolsAvailable

    Write-Host  '    AS-IS (current)              TO-BE (recommended target)'
    Write-Host  '    ---------------------------  --------------------------------'
    Write-Host ('    Firmware     : {0,-14}  Firmware     : {0} (no change)' -f $BootEnv.FirmwareType)
    if ($useWdac) {
        Write-Host ('    Secure Boot  : {0,-14}  Secure Boot  : ON     (NO CHANGE - keep enabled)' -f (_Status $BootEnv.SecureBootEnabled))
        Write-Host ('    testsigning  : {0,-14}  testsigning  : off    (NO CHANGE - not needed with WDAC)' -f (_Status $BootEnv.TestSigningEnabled))
        Write-Host ('    HVCI         : {0,-14}  HVCI         : {1,-6} (NO CHANGE - WDAC supplemental is HVCI-compatible)' -f (_Status $BootEnv.HvciRunning), (_Status $BootEnv.HvciRunning))
        Write-Host ('    WDAC supp.   : {0,-14}  WDAC supp.   : ON     (script will install via I02)' -f (_Status $BootEnv.AmdSuppPolicyActive))
    } else {
        Write-Host ('    Secure Boot  : {0,-14}  Secure Boot  : off    (USER MUST CHANGE in firmware - WDAC unavailable)' -f (_Status $BootEnv.SecureBootEnabled))
        Write-Host ('    testsigning  : {0,-14}  testsigning  : ON     (script will set via I02 -UseTestSigning)' -f (_Status $BootEnv.TestSigningEnabled))
        Write-Host ('    HVCI         : {0,-14}  HVCI         : off    (USER MUST DISABLE if currently on)' -f (_Status $BootEnv.HvciRunning))
        Write-Host ('    WDAC supp.   : {0,-14}  WDAC supp.   : n/a    (tools not available on this system)' -f (_Status $BootEnv.AmdSuppPolicyActive))
    }
    Write-Host ''

    if ($BootEnv.EffectiveCanLoadSelfSigned) {
        Write-Host '    System is already in a state that allows self-signed driver loads.' -ForegroundColor Green
        return
    }

    # ---- Recommended path (WDAC) ----
    if ($useWdac) {
        Write-Host '    RECOMMENDED PATH: WDAC supplemental policy (keeps Secure Boot ON)' -ForegroundColor Cyan
        Write-Host '    --------------------------------------------------------------------'
        Write-Host '    This path uses Windows Defender Application Control to add THIS'      -ForegroundColor Cyan
        Write-Host '    SCRIPT''S self-signed code-signing certificate as an allowed kernel-' -ForegroundColor Cyan
        Write-Host '    mode signer. Secure Boot stays ON, no firmware changes, no test-mode' -ForegroundColor Cyan
        Write-Host '    watermark, no HVCI changes, and the policy can be revoked cleanly.'   -ForegroundColor Cyan
        Write-Host ''
        Write-Host '    The script will perform the following on your behalf in I02:'         -ForegroundColor Yellow
        Write-Host '      1. Build a WDAC supplemental-policy XML allowlisting only this'     -ForegroundColor Yellow
        Write-Host '         script''s self-signed cert as a kernel-mode signer.'             -ForegroundColor Yellow
        Write-Host '      2. Convert the XML to a .cip binary policy.'                        -ForegroundColor Yellow
        Write-Host '      3. Deploy to %SystemRoot%\System32\CodeIntegrity\CiPolicies\Active.' -ForegroundColor Yellow
        Write-Host '      4. Activate via CiTool --update-policy (no reboot on WS2022+).'     -ForegroundColor Yellow
        Write-Host ''
        Write-Host '    Run:  .\Deploy-AMDGraphicsDriverOnWindowsServer.ps1 -Action Install -OnlyPhases I02' -ForegroundColor Yellow
        Write-Host ''
        Write-Host '    Reversal (later): the same script with -Action Cleanup will remove the' -ForegroundColor DarkGray
        Write-Host '    deployed supplemental policy via CiTool --remove-policy <PolicyId>.'    -ForegroundColor DarkGray
        return
    }

    # ---- Fallback path (testsigning, legacy) ----
    Write-Host '    FALLBACK PATH: legacy testsigning (requires Secure Boot OFF)' -ForegroundColor DarkYellow
    Write-Host '    --------------------------------------------------------------------'
    Write-Host '    The platform is missing WDAC tooling (ConfigCI module / CiTool /'    -ForegroundColor DarkYellow
    Write-Host '    AllowAll template). Falling back to bcdedit testsigning, which'      -ForegroundColor DarkYellow
    Write-Host '    requires disabling Secure Boot in firmware.'                         -ForegroundColor DarkYellow
    Write-Host ''
    $step = 1
    if ($BootEnv.SecureBootEnabled -eq $true) {
        Write-Host ('      {0}. Disable Secure Boot in firmware (UEFI setup):' -f $step) -ForegroundColor Yellow
        Write-Host  '         a. Reboot to firmware setup (Settings -> Recovery -> Advanced'
        Write-Host  '            startup -> Restart now -> Troubleshoot -> Advanced ->'
        Write-Host  '            UEFI Firmware Settings) or interrupt boot with the firmware'
        Write-Host  '            key (Dell=F2/F12, HP=ESC/F10, Lenovo=F1/F2, ASUS/Gigabyte=DEL).'
        Write-Host  '         b. Locate "Secure Boot" and set to Disabled. Save & exit.'
        Write-Host ''
        Write-Host  '         WARNING: if BitLocker is enabled, suspend it BEFORE this change'
        Write-Host  '         (Suspend-BitLocker -MountPoint $env:SystemDrive).'
        Write-Host ''
        $step++
    }
    if ($BootEnv.HvciRunning) {
        Write-Host ('      {0}. Disable HVCI / Memory Integrity:' -f $step) -ForegroundColor Yellow
        Write-Host  '         GUI: Windows Security -> Device security -> Core isolation'
        Write-Host  '              details -> turn OFF "Memory integrity", then reboot.'
        Write-Host ''
        $step++
    }
    Write-Host ('      {0}. Enable BCD testsigning (script handles it):' -f $step) -ForegroundColor Yellow
    Write-Host  '         Run: .\Deploy-AMDGraphicsDriverOnWindowsServer.ps1 -Action Install -OnlyPhases I02 -UseTestSigning'
    Write-Host  '         Then reboot.'
    Write-Host ''
    Write-Host '    After all of the above, the desktop will display a "Test Mode" watermark.' -ForegroundColor DarkYellow
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

function New-AmdDriverWdacSupplementalPolicy {
    # Build a WDAC supplemental-policy XML that allowlists ONLY this
    # script's self-signed code-signing certificate as a kernel-mode
    # signer. The supplemental is intentionally minimal:
    #   - It does NOT carry over any "AllowAll" rules from the template
    #     (we strip them after copying).
    #   - It only adds one Signer entry (our cert), referenced by the
    #     Driver Signing Scenario (KMCI, value 131) in AllowedSigners.
    # Result: the base policy still enforces strict signing for
    # everything else; only catalogs signed by our cert get the extra
    # green light.
    #
    # The PolicyID is now a STABLE fixed GUID (from
    # $Script:WdacPolicyGuid). The BasePolicyId now defaults to the
    # Microsoft standard {A244370E-...} instead of the previous
    # non-standard {B355481F-...}. Both can be overridden via the
    # corresponding -WdacPolicyGuid / -WdacBasePolicyGuid parameters.
    param(
        [Parameter(Mandatory)] [string]$CerPath,
        [Parameter(Mandatory)] [string]$OutputXml,
        [string]$PolicyName  = 'AMD Graphics Driver Self-Signed Allowlist (script-managed)',
        [string]$BasePolicyId = $Script:WdacBasePolicyGuid,
        [string]$PolicyId     = $Script:WdacPolicyGuid
    )
    if (-not (Test-Path $CerPath)) {
        throw "Certificate not found at $CerPath"
    }
    $template = Join-Path $env:windir 'schemas\CodeIntegrity\ExamplePolicies\AllowAll.xml'
    if (-not (Test-Path $template)) {
        throw "WDAC AllowAll template missing at $template"
    }

    # Normalize GUID format: Set-CIPolicyIdInfo accepts {GUID} form
    $basePolicyIdBraced = if ($BasePolicyId -match '^\{.*\}$') { $BasePolicyId } else { '{' + $BasePolicyId + '}' }
    $policyIdBraced     = if ($PolicyId     -match '^\{.*\}$') { $PolicyId     } else { '{' + $PolicyId     + '}' }

    # Step 1: copy AllowAll template (gives us valid schema scaffolding)
    Copy-Item $template $OutputXml -Force

    # Step 2: convert to supplemental policy targeting the base, then
    # set OUR fixed PolicyID (replaces previous -ResetPolicyID approach).
    Set-CIPolicyIdInfo -FilePath $OutputXml -SupplementsBasePolicyID $basePolicyIdBraced | Out-Null
    Set-CIPolicyIdInfo -FilePath $OutputXml -PolicyName $PolicyName | Out-Null

    # Step 2b: manually set the PolicyID GUID into the XML (PowerShell's
    # Set-CIPolicyIdInfo has no -PolicyId switch; -ResetPolicyID would
    # randomize it. We patch the XML directly.)
    [xml]$xmlForId = Get-Content $OutputXml
    $nsForId = New-Object System.Xml.XmlNamespaceManager($xmlForId.NameTable)
    $nsForId.AddNamespace('si', 'urn:schemas-microsoft-com:sipolicy')
    $policyIdNode = $xmlForId.SelectSingleNode('//si:SiPolicy/si:PolicyID', $nsForId)
    if (-not $policyIdNode) {
        $policyIdNode = $xmlForId.SiPolicy.PolicyID
        if ($policyIdNode -is [string] -or $null -eq $policyIdNode) {
            try { $xmlForId.SiPolicy.PolicyID = $policyIdBraced } catch { } # psa-disable-line PSA3004 -- intentional best-effort cleanup; no error to surface
        }
    }
    if ($policyIdNode -and ($policyIdNode -isnot [string])) {
        $policyIdNode.InnerText = $policyIdBraced
    }
    $xmlForId.Save($OutputXml)

    # Step 3: strip the catch-all AllowAll rules so the supplemental
    # ONLY adds our specific signer. WDAC supplemental policies are
    # ADDITIVE - keeping AllowAll rules would effectively turn off
    # enforcement for everything, defeating the point of Secure Boot.
    #
    # We now strip the ENTIRE <FileRulesRef> container, not
    # just its <FileRuleRef> children. On Windows Server 2025 (build
    # 26100) the AllowAll.xml template embeds <FileRulesRef> nodes
    # inside every <ProductSigners> block, and the WDAC schema
    # (urn:schemas-microsoft-com:sipolicy) requires <FileRulesRef> to
    # contain at least one <FileRuleRef> child. Leaving an empty
    # <FileRulesRef> behind made Add-SignerRule fail in I02 with:
    #   "Element 'FileRulesRef' has incomplete content. Required
    #    element 'FileRuleRef' is needed."
    # The <FileRulesRef> element itself is minOccurs=0, so removing
    # the container outright is schema-valid.
    [xml]$xml = Get-Content $OutputXml
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

    # Step 4: add ONLY our cert as kernel-mode signer
    Add-SignerRule -FilePath $OutputXml -CertificatePath $CerPath -Kernel | Out-Null

    # Step 5: return new policy ID for caller's records
    [xml]$updated = Get-Content $OutputXml
    return $updated.SiPolicy.PolicyID
}

function Install-AmdWdacPolicy {
    # Convert the supplemental XML to.cip binary form and deploy it
    # into %SystemRoot%\System32\CodeIntegrity\CiPolicies\Active. On
    # platforms with CiTool.exe, refresh the active policy stack so
    # the new supplemental takes effect WITHOUT a reboot. Returns a
    # status object the caller can display.
    #
    # CiTool is invoked with the --json flag. Per CiTool --help,
    # the --json flag "formats the output as JSON and suppresses
    # input" - i.e. it removes the "Press Enter to Exit" interactive
    # prompt that CiTool prints by default when run in a console host.
    # Without --json, CiTool blocked at I02 waiting for ENTER, causing
    # the script to appear hung for the duration of the user's wait.
    # See SPEC D.16 for the root-cause analysis.
    param(
        [Parameter(Mandatory)] [string]$XmlPath,
        [string]$BinaryOutPath
    )
    if (-not $BinaryOutPath) {
        $BinaryOutPath = [System.IO.Path]::ChangeExtension($XmlPath, '.cip')
    }

    ConvertFrom-CIPolicy -XmlFilePath $XmlPath -BinaryFilePath $BinaryOutPath | Out-Null

    [xml]$xml = Get-Content $XmlPath
    $policyId = $xml.SiPolicy.PolicyID
    if (-not $policyId) { throw 'Could not read PolicyID from XML.' }

    $activeDir = Join-Path $env:windir 'System32\CodeIntegrity\CiPolicies\Active'
    if (-not (Test-Path $activeDir)) {
        New-Item -ItemType Directory -Path $activeDir -Force | Out-Null
    }
    $deployedPath = Join-Path $activeDir "$policyId.cip"
    Copy-Item $BinaryOutPath $deployedPath -Force

    $immediate = $false
    $citoolStdout = ''
    $citoolStderr = ''
    $citoolStatusLine = ''
    if (Get-Command CiTool.exe -ErrorAction SilentlyContinue) {
        try {
            # CiTool returns 0 on success and prints a confirmation line.
            # --json flag is REQUIRED: without it, CiTool prints
            # "Press Enter to Exit" and waits for stdin, blocking I02.
            $citoolStdout = & CiTool.exe --update-policy $deployedPath --json 2>&1 | Out-String
            if ($LASTEXITCODE -eq 0) { $immediate = $true }
            # Parse the JSON envelope so callers can display a friendly
            # status line. CiTool --json emits an object with keys like
            # "OperationResult" and "FriendlyName"; we extract the
            # canonical success message for log display.
            try {
                $j = $citoolStdout | ConvertFrom-Json -ErrorAction SilentlyContinue
                if ($j) {
                    if ($j.OperationResult) { $citoolStatusLine = [string]$j.OperationResult }
                    elseif ($j.Status)      { $citoolStatusLine = [string]$j.Status }
                    elseif ($j.PSObject.Properties.Name -contains 'PolicyGUID') {
                        $citoolStatusLine = ('PolicyGUID={0}' -f $j.PolicyGUID)
                    }
                }
            } catch {
                # JSON parse failure is non-fatal; fall back to the raw
                # first non-empty stdout line for display.
                $citoolStatusLine = ($citoolStdout -split "`r?`n" | Where-Object { $_.Trim() } | Select-Object -First 1)
            }
        } catch {
            $citoolStderr = $_.Exception.Message
        }
    }

    # ---- WS2019 fallback: PS_UpdateAndCompareCIPolicy CIM method ----
    # When CiTool.exe is absent (WS2019 and earlier do not ship it),
    # the policy may still be hot-loaded via the WMI/CIM bridge
    # PS_UpdateAndCompareCIPolicy in root\Microsoft\Windows\CI. This
    # method exists on WS2019+ but not on WS2016, so failure here is
    # not fatal - the legacy reboot path remains as the final fallback.
    $cimBridgeTried   = $false
    $cimBridgeStdout  = ''
    $cimBridgeError   = ''
    if (-not $immediate) {
        $cimBridgeTried = $true
        try {
            $cimArgs = @{ FilePath = $deployedPath }
            $cimResult = Invoke-CimMethod -Namespace 'root\Microsoft\Windows\CI' `
                -ClassName 'PS_UpdateAndCompareCIPolicy' `
                -MethodName 'Update' `
                -Arguments $cimArgs `
                -ErrorAction Stop
            $rv = if ($null -ne $cimResult.ReturnValue) { [int]$cimResult.ReturnValue } else { -1 }
            $cimBridgeStdout = ('PS_UpdateAndCompareCIPolicy.Update returned {0}' -f $rv)
            if ($rv -eq 0) {
                $immediate = $true
                if (-not $citoolStatusLine) { $citoolStatusLine = $cimBridgeStdout }
            }
        } catch {
            # CIM class not present (WS2016) or other failure - fall through to reboot
            $cimBridgeError = $_.Exception.Message
        }
    }

    return [pscustomobject]@{
        PolicyId         = $policyId
        XmlPath          = $XmlPath
        BinaryPath       = $BinaryOutPath
        DeployedPath     = $deployedPath
        ActivationMethod = if ($immediate) { if ($cimBridgeTried -and (-not $citoolStdout)) { 'CIM bridge (PS_UpdateAndCompareCIPolicy, no reboot)' } else { 'CiTool (immediate, no reboot)' } } else { 'reboot' }
        RebootRequired   = -not $immediate
        CiToolStdout     = $citoolStdout
        CiToolStderr     = $citoolStderr
        CiToolStatusLine = $citoolStatusLine
    }
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

#####################################################################
# SECTION 1f: Install-phase state validators (resume-after-reboot)
#####################################################################
# These predicates answer "is the END STATE of install phase X already
# present on this system?" by inspecting the live system, NOT by
# checking marker files. They exist so that an install run can be
# safely re-executed (e.g. after a reboot) and skip phases whose work
# is already in place.
#
# Why state-based, not marker-based:
#   The phase-marker files in $Ctx.Paths.Markers tell us "this script
#   ran I01 successfully in some past run". They do NOT tell us
#   whether the change is still present. If the user manually deleted
#   the cert from certmgr.msc, or someone removed the WDAC policy
#   with CiTool, or pnputil's driver-store was cleared, the marker
#   would lie. State validation reads the actual current state, so
#   skip/run is decided correctly regardless of marker status.
#
# Combined helper Test-InstallPhaseAlreadyDone is the entry point
# install phases use at their top. It honours -Force (always returns
# $false so the work re-runs).
#
# These helpers are intentionally read-only and side-effect free.

function Test-CertAlreadyTrusted {
    # I01 target state: the script's self-signed cert is present in
    # both LocalMachine\Root and LocalMachine\TrustedPublisher.
    # If $Ctx.CertThumbprint is unset (e.g. user invoked I01 directly
    # without P07 having populated Ctx in this run), derive it from
    # the.cer file on disk.
    param([Parameter(Mandatory)] $Ctx)

    $thumbprint = $Ctx.CertThumbprint
    if (-not $thumbprint) {
        $cerPath = if ($Ctx.CertCerPath) { $Ctx.CertCerPath } `
                   else { Join-Path $Ctx.Paths.Cert 'AMD-Graphics-Driver-CodeSign.cer' }
        if (-not (Test-Path $cerPath)) { return $false }
        try {
            $certObj = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2 $cerPath
            $thumbprint = $certObj.Thumbprint
        } catch {
            return $false
        }
    }
    if (-not $thumbprint) { return $false }

    foreach ($storeName in 'Root', 'TrustedPublisher') {
        $found = Get-ChildItem -Path "Cert:\LocalMachine\$storeName" -ErrorAction SilentlyContinue |
                 Where-Object { $_.Thumbprint -eq $thumbprint } |
                 Select-Object -First 1
        if (-not $found) { return $false }
    }
    return $true
}

function Test-I02InTargetState {
    # I02 target state depends on which path was selected.
    #   PATH A (default, WDAC supplemental policy):
    #     A supplemental policy whose PolicyId matches our marker file
    #     is present in the active CI policies stack.
    #   PATH B (legacy testsigning, opt-in via -UseTestSigning):
    #     BCD testsigning is set to Yes for the {current} loader entry.
    # We don't try to verify "effective at runtime" here - that's I04's
    # job (per-driver load status). Here we only ask "is the change
    # we make in I02 already on disk / in the boot-config?"
    param([Parameter(Mandatory)] $Ctx)

    if ($Ctx.UseTestSigning) {
        # PATH B: read BCD testsigning flag
        $env = Get-BootSigningEnvironment
        return ($env.TestSigningEnabled -eq $true)
    } else {
        # PATH A: marker file exists AND its PolicyId is currently active
        $deployed = Test-AmdWdacPolicyDeployed -Ctx $Ctx
        return ($null -ne $deployed)
    }
}

function Test-AllPatchedDriversInStore {
    # I03 target state: every patched.inf in $Ctx.Paths.Patched is
    # present in the Windows driver store. We use pnputil /enum-drivers
    # because that is exactly what I03 itself uses to add them, so the
    # round-trip is symmetric.
    #
    # NOTE: pnputil reports drivers by their published OEM name
    # (oemNN.inf) AND by their original INF name (Original Name:
    # amdpcidev.inf). We match on the original name because that is
    # what we have in $Ctx.Paths.Patched.
    #
    # If the patched directory is empty or pnputil fails, return
    # $false (force I03 to re-run, which will surface the real error).
    param([Parameter(Mandatory)] $Ctx)

    if (-not $Ctx.Paths -or -not $Ctx.Paths.Patched -or -not (Test-Path $Ctx.Paths.Patched)) {
        return $false
    }
    $expected = @(Get-ChildItem -Path $Ctx.Paths.Patched -Recurse -Filter *.inf -ErrorAction SilentlyContinue)
    if ($expected.Count -eq 0) { return $false }

    try {
        $output = & pnputil.exe /enum-drivers 2>&1 | Out-String
    } catch {
        return $false
    }
    if (-not $output -or -not $output.Trim()) { return $false }

    foreach ($inf in $expected) {
        $infName = $inf.Name
        # Match against "Original Name: <inf>" (case-insensitive,
        # tolerate variable whitespace and non-ASCII labels in
        # localized pnputil output).
        $pattern = '(?im)Original\s+Name\s*:\s*' + [regex]::Escape($infName)
        if ($output -notmatch $pattern) {
            return $false
        }
    }
    return $true
}

function Test-InstallPhaseAlreadyDone {
    # Single entry point install phases call at their top. Returns
    # $true if the phase's target state is already present and the
    # phase can be safely skipped. Returns $false otherwise.
    #
    # Honours -Force: always returns $false so the work re-runs.
    param(
        [Parameter(Mandatory)] $Ctx,
        [Parameter(Mandatory)] [string]$PhaseId
    )
    if ($Ctx.Force) { return $false }
    switch ($PhaseId) {
        'I01' { return Test-CertAlreadyTrusted -Ctx $Ctx }
        'I02' { return Test-I02InTargetState   -Ctx $Ctx }
        'I03' { return Test-AllPatchedDriversInStore -Ctx $Ctx }
        default { return $false }
    }
}

function Get-WorkspaceLockPath {
    # Path to a per-workspace lock file used to prevent two
    # simultaneous executions of THIS script. The graphics-driver
    # companion script uses its own workspace and therefore its own
    # lock file - it does NOT collide with this one. The intent is
    # only to protect against the user accidentally running the same
    # script twice in parallel (e.g. two PowerShell windows), which
    # would race I02 (WDAC deploy) and I03 (pnputil) against itself.
    param([Parameter(Mandatory)] $Ctx)
    if (-not $Ctx.Paths -or -not $Ctx.Paths.Markers) { return $null }
    return (Join-Path $Ctx.Paths.Markers 'RUN.lock')
}

function Test-WorkspaceLockHeld {
    # Returns @{ Held=$bool; Pid=$int; ProcessRunning=$bool; Stale=$bool; SelfPid=$bool }
    # If no lock exists, Held=$false and other fields are blank.
    # If a lock exists but the recorded PID is no longer running, the
    # lock is stale (Held=$true, ProcessRunning=$false, Stale=$true).
    # If a lock exists AND the recorded PID matches our current
    # PowerShell process ($PID), the lock is treated as stale and
    # taken over silently. This handles the interactive-console case
    # where a previous run completed but the PowerShell.Exiting hook
    # did not fire (because the console host is still alive); without
    # this, the next run in the same console would mis-detect the
    # leftover lock as "another instance running" and refuse to start.
    # Mirrors Chipset fix; see SPEC §A.1.4 sister-script symmetry.
    param([Parameter(Mandatory)] $Ctx)
    $info = [pscustomobject]@{
        Held           = $false
        Pid            = $null
        StartedAt      = $null
        CommandLine    = $null
        ProcessRunning = $false
        Stale          = $false
        SelfPid        = $false
    }
    $path = Get-WorkspaceLockPath -Ctx $Ctx
    if (-not $path -or -not (Test-Path $path)) { return $info }
    $info.Held = $true
    try {
        $lines = Get-Content -LiteralPath $path -ErrorAction Stop
        foreach ($l in $lines) {
            if ($l -match '^Pid\s*:\s*(\d+)')           { $info.Pid         = [int]$matches[1] }
            elseif ($l -match '^StartedAt\s*:\s*(.+)$') { $info.StartedAt   = $matches[1].Trim() }
            elseif ($l -match '^CommandLine\s*:\s*(.+)$') { $info.CommandLine = $matches[1].Trim() }
        }
    } catch { } # psa-disable-line PSA3004 -- intentional best-effort cleanup; no error to surface
    if ($info.Pid) {
        # Lock written by the very same PowerShell process we are
        # running in. This happens when a previous script invocation in
        # the same interactive console completed without firing the
        # Register-EngineEvent PowerShell.Exiting hook (the hook only
        # fires when the host process itself exits). Mark as stale so
        # Assert-NoConcurrentRun can supersede silently.
        if ($info.Pid -eq $PID) {
            $info.SelfPid        = $true
            $info.ProcessRunning = $false
            $info.Stale          = $true
        } else {
            $proc = Get-Process -Id $info.Pid -ErrorAction SilentlyContinue
            if ($proc) {
                $info.ProcessRunning = $true
            } else {
                $info.Stale = $true
            }
        }
    }
    return $info
}

function Set-WorkspaceLock {
    # Write a lock file recording our PID + start time + command line.
    # Caller MUST ensure the lock isn't already held by a running
    # process before calling this (use Test-WorkspaceLockHeld).
    param([Parameter(Mandatory)] $Ctx)
    $path = Get-WorkspaceLockPath -Ctx $Ctx
    if (-not $path) { return }
    $cmd = $null
    try {
        $cmd = ([System.Environment]::CommandLine)
    } catch { } # psa-disable-line PSA3004 -- intentional best-effort cleanup; no error to surface
    $payload = @(
        ('Pid         : {0}' -f $PID),
        ('StartedAt   : {0:yyyy-MM-dd HH:mm:ss}' -f (Get-Date)),
        ('CommandLine : {0}' -f $cmd),
        ('Workspace   : {0}' -f $Ctx.WorkRoot)
    ) -join "`n"
    Set-Content -LiteralPath $path -Value $payload -Encoding ASCII -ErrorAction SilentlyContinue
    # Ensure the lock is released even if the script exits with throw
    # or Ctrl-C. Register-EngineEvent on PowerShell.Exiting is the
    # supported hook in PS 5.1.
    Register-EngineEvent -SourceIdentifier ([System.Management.Automation.PsEngineEvent]::Exiting) `
        -Action {
            $lp = $Event.MessageData
            if ($lp -and (Test-Path $lp)) {
                Remove-Item -LiteralPath $lp -Force -ErrorAction SilentlyContinue
            }
        } -MessageData $path -SupportEvent | Out-Null
}

function Clear-WorkspaceLock {
    param([Parameter(Mandatory)] $Ctx)
    $path = Get-WorkspaceLockPath -Ctx $Ctx
    if ($path -and (Test-Path $path)) {
        Remove-Item -LiteralPath $path -Force -ErrorAction SilentlyContinue
    }
}

function Assert-NoConcurrentRun {
    # Called from P00 right after the workspace directory exists. If
    # another live instance of this same script is running against
    # this same workspace, fail fast with an actionable error. If a
    # stale lock is found (PID no longer alive), warn and overtake.
    param([Parameter(Mandatory)] $Ctx)
    $info = Test-WorkspaceLockHeld -Ctx $Ctx
    if ($info.Held -and $info.ProcessRunning) {
        $msg = @(
            ''
            ('*** Another instance of this script is already running in workspace {0} ***' -f $Ctx.WorkRoot)
            ('    PID         : {0}' -f $info.Pid)
            ('    StartedAt   : {0}' -f $info.StartedAt)
            ('    CommandLine : {0}' -f $info.CommandLine)
            ''
            '    Wait for the other instance to finish, or terminate it (Stop-Process -Id <PID> -Force).'
            '    If you are running BOTH the chipset and the graphics scripts, that is fine - they use'
            '    separate workspaces - but do NOT start two copies of THIS script against the same'
            '    workspace at the same time (pnputil and CiTool would race).'
            ''
        ) -join "`n"
        throw $msg
    }
    if ($info.Held -and $info.Stale) {
        # Distinguish "stale because the recorded PID is dead" from
        # "stale because the recorded PID is OUR pid" (interactive
        # PowerShell re-run scenario). The second case is benign and
        # frequent enough that it deserves a non-alarming message.
        # Mirrors Chipset fix; see SPEC §A.1.4 sister-script symmetry.
        if ($info.SelfPid) {
            Write-Host ('    [+] Reusing workspace lock from earlier run in this PowerShell session (PID {0}).' -f $info.Pid) -ForegroundColor DarkGray
        } else {
            Write-Warn2 ('Found stale lock from PID {0} (process no longer running) - taking over.' -f $info.Pid)
        }
        Clear-WorkspaceLock -Ctx $Ctx
    }
    Set-WorkspaceLock -Ctx $Ctx
}

function Get-PendingRebootMarkerPath {
    # Path to the sentinel file that records "the previous run asked
    # the user to reboot." I02 (testsigning path) and I03 (drivers
    # that pnputil could not live-load) write this file. I04 reads it
    # and clears it once the post-reboot state is confirmed good.
    param([Parameter(Mandatory)] $Ctx)
    if (-not $Ctx.Paths -or -not $Ctx.Paths.Markers) { return $null }
    return (Join-Path $Ctx.Paths.Markers 'PENDING_REBOOT.txt')
}

function Set-PendingRebootMarker {
    # Record that a reboot is required, with metadata so a future run
    # can decide whether the reboot already happened.
    param(
        [Parameter(Mandatory)] $Ctx,
        [Parameter(Mandatory)] [string]$Source,
        [string]$Reason = ''
    )
    $path = Get-PendingRebootMarkerPath -Ctx $Ctx
    if (-not $path) { return }
    $bootTime = $null
    try {
        $bootTime = (Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction Stop).LastBootUpTime
    } catch { } # psa-disable-line PSA3004 -- intentional best-effort cleanup; no error to surface
    $payload = @(
        ('RecordedAt   : {0:yyyy-MM-dd HH:mm:ss}' -f (Get-Date)),
        ('LastBootTime : {0}' -f ($bootTime)),
        ('Source       : {0}' -f $Source),
        ('Reason       : {0}' -f $Reason)
    ) -join "`n"
    Set-Content -LiteralPath $path -Value $payload -Encoding ASCII -ErrorAction SilentlyContinue
}

function Get-PendingRebootMarker {
    # If the sentinel file exists, return a structured object;
    # otherwise $null. Includes a heuristic flag RebootHasOccurred
    # that is $true when the current LastBootUpTime is later than the
    # one recorded when the marker was written.
    param([Parameter(Mandatory)] $Ctx)
    $path = Get-PendingRebootMarkerPath -Ctx $Ctx
    if (-not $path -or -not (Test-Path $path)) { return $null }

    $info = [pscustomobject]@{
        Path              = $path
        RecordedAt        = $null
        RecordedBootTime  = $null
        Source            = $null
        Reason            = $null
        CurrentBootTime   = $null
        RebootHasOccurred = $false
    }
    try {
        $lines = Get-Content -LiteralPath $path -ErrorAction Stop
        foreach ($l in $lines) {
            if ($l -match '^RecordedAt\s*:\s*(.+)$')   { $info.RecordedAt       = $matches[1].Trim() }
            elseif ($l -match '^LastBootTime\s*:\s*(.+)$') { $info.RecordedBootTime = $matches[1].Trim() }
            elseif ($l -match '^Source\s*:\s*(.+)$')   { $info.Source           = $matches[1].Trim() }
            elseif ($l -match '^Reason\s*:\s*(.+)$')   { $info.Reason           = $matches[1].Trim() }
        }
    } catch { return $info }

    try {
        $info.CurrentBootTime = (Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction Stop).LastBootUpTime
    } catch { } # psa-disable-line PSA3004 -- intentional best-effort cleanup; no error to surface

    if ($info.RecordedBootTime -and $info.CurrentBootTime) {
        try {
            $recordedDt = [datetime]$info.RecordedBootTime
            if ($info.CurrentBootTime -gt $recordedDt) {
                $info.RebootHasOccurred = $true
            }
        } catch { } # psa-disable-line PSA3004 -- intentional best-effort cleanup; no error to surface
    }
    return $info
}

function Clear-PendingRebootMarker {
    # Called by I04 when post-install verification confirms the system
    # is in a good end state, so subsequent runs do not see a stale
    # "reboot required" warning.
    param([Parameter(Mandatory)] $Ctx)
    $path = Get-PendingRebootMarkerPath -Ctx $Ctx
    if ($path -and (Test-Path $path)) {
        Remove-Item -LiteralPath $path -Force -ErrorAction SilentlyContinue
    }
}

#####################################################################
# SECTION 2: Phase registry
#####################################################################
$Script:PhaseRegistry = @(
    [pscustomobject]@{ Id='P00'; Name='Initialize';        Group='Prep';   Func='Invoke-PrepPhase00_Initialize'          }
    [pscustomobject]@{ Id='P01'; Name='PrepareWorkspace';  Group='Prep';   Func='Invoke-PrepPhase01_PrepareWorkspace'    }
    [pscustomobject]@{ Id='P02'; Name='AcquireTools';      Group='Prep';   Func='Invoke-PrepPhase02_AcquireTools'        }
    [pscustomobject]@{ Id='P03'; Name='FetchInstaller';    Group='Prep';   Func='Invoke-PrepPhase03_FetchInstaller'      }
    [pscustomobject]@{ Id='P04'; Name='ExtractInstaller';  Group='Prep';   Func='Invoke-PrepPhase04_ExtractInstaller'    }
    [pscustomobject]@{ Id='P05'; Name='AnalyzeInfs';       Group='Prep';   Func='Invoke-PrepPhase05_AnalyzeInfs'         }
    [pscustomobject]@{ Id='P06'; Name='PatchInfs';         Group='Prep';   Func='Invoke-PrepPhase06_PatchInfs'           }
    [pscustomobject]@{ Id='P07'; Name='CreateCertificate'; Group='Prep';   Func='Invoke-PrepPhase07_CreateCertificate'   }
    [pscustomobject]@{ Id='P08'; Name='GenerateCatalogs';  Group='Prep';   Func='Invoke-PrepPhase08_GenerateCatalogs'    }
    [pscustomobject]@{ Id='P09'; Name='SignCatalogs';      Group='Prep';   Func='Invoke-PrepPhase09_SignCatalogs'        }
    [pscustomobject]@{ Id='V01'; Name='VerifyArtifacts';   Group='Verify'; Func='Invoke-VerifyPhase01_VerifyArtifacts'   }
    [pscustomobject]@{ Id='V02'; Name='VerifyCertificate'; Group='Verify'; Func='Invoke-VerifyPhase02_VerifyCertificate' }
    [pscustomobject]@{ Id='V03'; Name='VerifyCatalogs';    Group='Verify'; Func='Invoke-VerifyPhase03_VerifyCatalogs'    }
    [pscustomobject]@{ Id='V04'; Name='VerifyInfs';        Group='Verify'; Func='Invoke-VerifyPhase04_VerifyInfs'        }
    [pscustomobject]@{ Id='V05'; Name='DryRunInstall';     Group='Verify'; Func='Invoke-VerifyPhase05_DryRunInstall'     }
    [pscustomobject]@{ Id='V06'; Name='HardwareImpactAnalysis'; Group='Verify'; Func='Invoke-VerifyPhase06_HardwareImpactAnalysis' }
    [pscustomobject]@{ Id='I00'; Name='PreInstallReview';   Group='Inst';   Func='Invoke-InstPhase00_PreInstallReview'    }
    [pscustomobject]@{ Id='I01'; Name='TrustCertificate';  Group='Inst';   Func='Invoke-InstPhase01_TrustCertificate'    }
    [pscustomobject]@{ Id='I02'; Name='AuthorizeDriverSigning'; Group='Inst';   Func='Invoke-InstPhase02_AuthorizeDriverSigning' }
    [pscustomobject]@{ Id='I03'; Name='InstallDrivers';    Group='Inst';   Func='Invoke-InstPhase03_InstallDrivers'      }
    [pscustomobject]@{ Id='I04'; Name='PostInstallVerification'; Group='Inst'; Func='Invoke-InstPhase04_PostInstallVerification' }
)

function Resolve-PhaseSelection {
    param([string]$Action, [string[]]$OnlyPhases)
    $all = $Script:PhaseRegistry
    $byAction = switch ($Action) {
        'Prepare'        { $all | Where-Object Group -eq 'Prep'   }
        'Verify'         { $all | Where-Object Group -eq 'Verify' }
        'PrepareVerify'  { $all | Where-Object { $_.Group -eq 'Prep' -or $_.Group -eq 'Verify' } }
        'Install'        { $all | Where-Object Group -eq 'Inst'   }
        'All'            { $all }
        default          { $all }
    }
    if (-not $OnlyPhases -or $OnlyPhases.Count -eq 0) { return $byAction }

    # Backward-compatible alias map for phase names that have been
    # renamed across script versions. Keys are old names, values are
    # current names. The ID lookup ('I02') always works directly and is
    # the recommended way to reference phases in scripts and pipelines.
    # This alias map exists so callers that predate this revision don't break.
    $nameAliases = @{
        'EnableTestSigning' = 'AuthorizeDriverSigning'   # renamed
    }

    $resolved = foreach ($needle in $OnlyPhases) {
        # Resolve old-name aliases to current names before lookup. We
        # surface a one-time deprecation notice so the caller knows to
        # migrate, but we still proceed with the resolved phase.
        $effective = $needle
        if ($nameAliases.ContainsKey($needle)) {
            $effective = $nameAliases[$needle]
            Write-Host ("[i] Phase name '{0}' was renamed to '{1}'; please update your scripts." -f $needle, $effective) -ForegroundColor DarkYellow
        }
        $hit = $all | Where-Object { $_.Id -eq $effective -or $_.Name -eq $effective }
        if (-not $hit) { throw "Unknown phase: '$needle' (use -Action ListPhases to see all)" }
        $hit
    }
    # Preserve registry order
    $ids = $resolved | ForEach-Object Id
    return $all | Where-Object { $_.Id -in $ids }
}


#####################################################################
# SECTION (r69, QI-6): CRITICAL severity acknowledgement helpers
#####################################################################
# Adds a CRITICAL severity level to the I00 PreInstallReview risk
# summary. When any of conditions C1, C2, C5 (per Q6-A) hit,
# the operator must acknowledge each item via an interactive y/N
# checklist before I01 begins. -ForceUnsafe bypasses the prompt
# (intended for CI/CD; the bypass is logged via Set-DebugStep).
#
# Conditions:
#   C1: Display driver replacement on single-display host
#   C2: BitLocker ON + AMD PSP driver replacement
#   C5: Host has not been rebooted in 24+ hours
# (C4, System Restore disabled, is handled by QI-9 as a non-blocking
#  warning per Q6-A.)
#
# Byte-identical across Chipset / Graphics / BthPan (PSA8001).
# NPU is excluded via psa8001_ignore_functions because NPU refuses
# Install on legacy Windows Server (Q-X1, r17).
#
# Data contract for $Matched (B2 decision, 2026-05-23):
#   [pscustomobject]@{
#       Device     = <PnP device object>
#       MatchKey   = <HWID match key>
#       Current    = <current driver info from Get-DeviceCurrentDriver>
#       Category   = <driver-source classification record>
#       Candidates = <INF object array, each with .InfName>
#   }
# BthPan does not build $matched (single inbox INF only); callers
# pass @() and C1/C2 simply yield no items.
#
# See SPEC SS D.28 for the CRITICAL judgement logic in detail.

function Get-CriticalRiskItem {
    [CmdletBinding()]
    [OutputType([pscustomobject[]])]
    param(
        [Parameter(Mandatory)] $Ctx,
        [Parameter(Mandatory)] [AllowEmptyCollection()] [object[]]$Matched
    )
    $items = New-Object System.Collections.Generic.List[pscustomobject]

    # --- C1: Display driver replacement on single-display host ---
    $displays = @()
    try {
        $displays = @(Get-PnpDevice -Class Display -ErrorAction SilentlyContinue |
                      Where-Object Status -eq 'OK')
    } catch { } # psa-disable-line PSA3004 -- best-effort PnP enumeration; not having Get-PnpDevice means there are no enumerable displays anyway
    $willReplaceDisplay = $false
    foreach ($entry in $Matched) {
        if (-not $entry.Candidates) { continue }
        foreach ($cand in $entry.Candidates) {
            $infName = $cand.InfName
            if ([string]::IsNullOrEmpty($infName)) { continue }
            if ($infName -match '(?i)^(display\.inf|u020.*\.inf)$') {
                $willReplaceDisplay = $true
                break
            }
        }
        if ($willReplaceDisplay) { break }
    }
    if ($willReplaceDisplay -and $displays.Count -le 1) {
        $items.Add([pscustomobject]@{
            Id = 'C1'
            Title = 'Display driver replacement on single-display host'
            Detail = (@(
                '  Only one Display class device is currently bound (Get-PnpDevice).',
                '  The install plan will replace the inbox or current Display driver.',
                '  If the new driver fails to load at boot, you may lose all display output.',
                '  Recovery would require an external display or remote-access workaround.'
            ) -join "`n")
            AckQuestion = 'I understand display loss is possible and have an alternative display path or remote access ready (y/N): '
        })
    }

    # --- C2: BitLocker ON + AMD PSP driver replacement ---
    $bitlocker = $null
    try {
        $bitlocker = Get-BitLockerVolume -MountPoint $env:SystemDrive -ErrorAction SilentlyContinue
    } catch { } # psa-disable-line PSA3004 -- best-effort BitLocker query; absence means no BitLocker concern
    $willReplacePsp = $false
    foreach ($entry in $Matched) {
        if (-not $entry.Candidates) { continue }
        foreach ($cand in $entry.Candidates) {
            $infName = $cand.InfName
            if ([string]::IsNullOrEmpty($infName)) { continue }
            if ($infName -match '(?i)psp') {
                $willReplacePsp = $true
                break
            }
        }
        if ($willReplacePsp) { break }
    }
    if ($bitlocker -and $bitlocker.ProtectionStatus -eq 'On' -and $willReplacePsp) {
        $protectorTypes = ''
        if ($bitlocker.KeyProtector) {
            $protectorTypes = (($bitlocker.KeyProtector | ForEach-Object { $_.KeyProtectorType }) -join ', ')
        }
        $items.Add([pscustomobject]@{
            Id = 'C2'
            Title = 'BitLocker ON + AMD PSP driver replacement'
            Detail = (@(
                '  BitLocker is currently ON on the system drive.',
                '  The install plan replaces an AMD PSP (Platform Security Processor) driver.',
                '  PSP firmware changes can trigger BitLocker recovery prompts on next boot.',
                '  Without the BitLocker recovery key, the drive contents become inaccessible.'
            ) -join "`n")
            AckQuestion = ('I have my BitLocker recovery key saved (KeyProtector: {0}) and accept the risk (y/N): ' -f $protectorTypes)
        })
    }

    # --- C5: No reboot in last 24 hours ---
    try {
        $os = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction Stop
        $hoursSince = ((Get-Date) - $os.LastBootUpTime).TotalHours
        if ($hoursSince -gt 24) {
            $items.Add([pscustomobject]@{
                Id = 'C5'
                Title = ('Host has not been rebooted in {0:N1} hours' -f $hoursSince)
                Detail = (@(
                    ('  Last boot: {0}' -f $os.LastBootUpTime.ToString('u')),
                    '  PnP changes may have accumulated; the next reboot will process them all',
                    '  at once, which raises the probability of cumulative regression.',
                    '  RECOMMENDED: reboot the host now, then re-run -Action Install.'
                ) -join "`n")
                AckQuestion = 'I accept that accumulated pending PnP changes may interact with this Install (y/N): '
            })
        }
    } catch { } # psa-disable-line PSA3004 -- CIM unavailable means we cannot compute hours-since-boot; non-fatal

    # --- C6: WHQL co-sign shortfall on Secure-Boot-ON host ---
    # Fires when ALL of the following hold:
    #   (a) the install plan contains at least one non-WHQL-co-signed INF
    #   (b) the host is currently running with UEFI Secure Boot ENABLED
    #   (c) the operator did NOT pass -SkipNonCosignedDrivers
    #   (d) the operator did NOT pass -UseTestSigning (Path B path)
    # In that combination, the non-WHQL drivers will be rejected by
    # kernel CI at boot time regardless of WDAC trust-store state (see
    # SPEC SS D.30 F6, F7). The operator should know this before I03
    # starts modifying the driver store. Recovery from a partial-load
    # state typically requires manual pnputil intervention from WinRE.
    try {
        $analysisField = $Ctx.WhqlCoSignAnalysis
        $hasAnalysis = ($null -ne $analysisField -and $analysisField.Count -gt 0)
        if ($hasAnalysis -and -not $Script:SkipNonCosignedDrivers -and -not $Ctx.UseTestSigning) {
            $sbOn = Test-SecureBootEnabledFromFirmware
            $nonCoSignedInfs = @($analysisField | Where-Object { -not $_.IsFullyCoSigned })
            if ($sbOn -eq $true -and $nonCoSignedInfs.Count -gt 0) {
                $sample = @($nonCoSignedInfs | Select-Object -First 5 | ForEach-Object { '    - ' + $_.InfName })
                $more = $nonCoSignedInfs.Count - $sample.Count
                $moreLine = if ($more -gt 0) { ('    ... and {0} more' -f $more) } else { '' }
                $detailLines = New-Object System.Collections.Generic.List[string]
                [void]$detailLines.Add('  UEFI Secure Boot is ENABLED in firmware on this host.')
                [void]$detailLines.Add(('  The install plan contains {0} INF(s) whose .sys files are NOT' -f $nonCoSignedInfs.Count))
                [void]$detailLines.Add('  WHQL co-signed by Microsoft. On a Secure-Boot-ON Windows Server')
                [void]$detailLines.Add('  host, kernel CI will REJECT these drivers at boot time even after')
                [void]$detailLines.Add('  trust-store import of the self-signing certificate (Path A).')
                [void]$detailLines.Add('  Trust-store authorisation does not bypass the WHQL co-signature')
                [void]$detailLines.Add('  requirement enforced by the boot loader.')
                [void]$detailLines.Add('  Non-WHQL INFs that will be rejected:')
                foreach ($s in $sample) { [void]$detailLines.Add($s) }
                if ($moreLine) { [void]$detailLines.Add($moreLine) }
                [void]$detailLines.Add('  To avoid this CRITICAL condition, choose ONE of:')
                [void]$detailLines.Add('    a) Re-run with -SkipNonCosignedDrivers to install only the')
                [void]$detailLines.Add('       WHQL-co-signed subset (keeps Secure Boot ON).')
                [void]$detailLines.Add('    b) Disable UEFI Secure Boot in firmware setup, save BitLocker')
                [void]$detailLines.Add('       recovery key, reboot, and re-run with -UseTestSigning (Path B).')
                [void]$detailLines.Add('    c) Accept the install as-is. The WHQL-co-signed subset will load;')
                [void]$detailLines.Add('       the non-WHQL subset will appear in Device Manager with')
                [void]$detailLines.Add('       Status=Error, ProblemCode=39 (CM_PROB_DRIVER_FAILED_LOAD).')
                $items.Add([pscustomobject]@{
                    Id = 'C6'
                    Title = ('WHQL co-sign shortfall on Secure-Boot-ON host ({0} non-co-signed INF(s))' -f $nonCoSignedInfs.Count)
                    Detail = ($detailLines -join "`n")
                    AckQuestion = 'I understand non-WHQL drivers will be kernel-CI-rejected at boot and accept this outcome (y/N): '
                })
            }
        }
    } catch { } # psa-disable-line PSA3004 -- C6 enrichment is best-effort; the install can still proceed without it

    return ,@($items.ToArray())
}

function Invoke-CriticalAcknowledgementChecklist {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)] [AllowEmptyCollection()] [pscustomobject[]]$Items,
        [switch]$ForceUnsafe
    )
    if ($Items.Count -eq 0) { return $true }
    Write-Host ''
    Write-Host '========================================================================' -ForegroundColor Red
    Write-Host (' CRITICAL RISK ITEMS ({0}) - operator acknowledgement required' -f $Items.Count) -ForegroundColor Red
    Write-Host '========================================================================' -ForegroundColor Red
    foreach ($it in $Items) {
        Write-Host ''
        Write-Host ('[CRITICAL][{0}] {1}' -f $it.Id, $it.Title) -ForegroundColor Red
        Write-Host $it.Detail -ForegroundColor DarkRed
    }
    Write-Host ''
    if ($ForceUnsafe) {
        Write-Warn2 '  [!] -ForceUnsafe is set; CRITICAL acknowledgement checklist is BYPASSED.'
        Write-Warn2 '  [!] This is recorded in the run transcript for audit purposes.'
        Set-DebugStep ('CRITICAL bypass via -ForceUnsafe: items=' + (($Items | ForEach-Object { $_.Id }) -join ','))
        return $true
    }
    $allAcked = $true
    foreach ($it in $Items) {
        Write-Host ('  [{0}] ' -f $it.Id) -ForegroundColor Red -NoNewline
        Write-Host $it.AckQuestion -ForegroundColor Yellow -NoNewline
        $resp = Read-Host
        $ack = ($resp -match '^(y|yes)$')
        Set-DebugStep ('CRITICAL ack {0}: response="{1}" ack={2}' -f $it.Id, $resp, $ack)
        if (-not $ack) {
            Write-Fail ('  [X] CRITICAL[{0}] NOT acknowledged. Aborting before I01.' -f $it.Id)
            $allAcked = $false
            break
        }
        Write-Host ('  [+] CRITICAL[{0}] acknowledged.' -f $it.Id) -ForegroundColor Green
    }
    return $allAcked
}


#####################################################################
# SECTION r71: WHQL co-sign pre-detection + Path B prerequisite check
#####################################################################
# r71 adds two operator-protection mechanisms that the now-removed Path C
# orchestrator was supposed to provide but did not:
#
#   1) Test-WhqlCoSignature: classify each candidate INF's accompanying
#      .sys file(s) as WHQL co-signed or not. Surfaced by P05 into
#      $Ctx.WhqlCoSignAnalysis so I00 PreInstallReview and the new C6
#      CRITICAL condition can act on it. WHQL co-signed drivers load on
#      Secure-Boot-ON hosts via trust-store-only authorisation (Path A);
#      non-WHQL drivers require Path B (testsigning + Secure Boot
#      Disabled in firmware) or rejection.
#
#   2) Invoke-PathBPrerequisiteCheck: called from I02 when Path B
#      (testsigning) is the active branch. Verifies bcdedit will accept
#      the TESTSIGNING flag (i.e. Secure Boot is OFF in firmware) before
#      any driver-store modification. The check is documented by
#      Microsoft Learn ("The TESTSIGNING boot configuration option") to
#      fail at command execution under Secure Boot ON with the error
#      "The value is protected by Secure Boot policy and cannot be
#      modified or deleted." See SPEC SS D.30.4 / F9.
#
# Operator-facing switch: -SkipNonCosignedDrivers (param block). When
# set, P06/P07/P08 skip non-WHQL drivers entirely; the install plan is
# trimmed to the WHQL co-signed subset and the operator can remain on
# Path A with Secure Boot ON. The flag is the safer alternative to
# Path B for hosts where firmware-level Secure Boot disablement is not
# acceptable.
#
# Byte-identical across Chipset / Graphics / BthPan (PSA8001).
# NPU is excluded via psa8001_ignore_functions: NPU refuses Install on
# legacy Server (Q-X1), so Path B prerequisite checking has no call
# site there.
#
# See SPEC SS D.31 for the full r71 design contract; SPEC SS D.31.11
# documents the r72 follow-on I02 short-circuit that consumes the
# WHQL analysis produced here when -SkipNonCosignedDrivers is set.

function Test-WhqlCoSignature { # psa-disable-line PSA6003 -- "Signature" is a singular noun; the function returns a single classification result per file
    # Inspect a .sys file's Authenticode certificate chain and report
    # whether it carries a Microsoft Windows Hardware Compatibility
    # co-signature (i.e. WHQL). WHQL co-signed drivers load on
    # Secure-Boot-ON Windows Server hosts via trust-store-only
    # authorisation (Path A); non-WHQL drivers require Path B.
    #
    # OUTPUT: pscustomobject with:
    #   - Path             ([string])     full path to the inspected file
    #   - IsCoSigned       ([bool])       true if WHQL co-signature is present
    #   - SignerCount      ([int])        number of signers in the chain
    #   - SignerSubjects   ([string[]])   subject CNs of each signer
    #   - WhqlMarker       ([string])     the matched marker text if found, else ''
    #   - Reason           ([string])     short diagnostic ('cosigned', 'self-only', 'unsigned', 'inspect-failed')
    #
    # NOTES:
    #   - Get-AuthenticodeSignature returns only the primary signer on
    #     PS 5.1. To enumerate co-signers we shell out to
    #     [System.Security.Cryptography.X509Certificates.X509Certificate2]
    #     via the signtool-style nested-signature parsing path. When
    #     signtool.exe is available we prefer its output because it
    #     emits a fully populated "Number of signatures" table; when it
    #     is absent we fall back to a best-effort parse.
    #   - WHQL co-signers historically carry CN markers including
    #     'Microsoft Windows Hardware Compatibility', 'Microsoft Windows
    #     Hardware Compatibility Publisher', and the older 'Microsoft
    #     Windows Hardware Compatibility Authority'. The matcher uses a
    #     case-insensitive regex to cover all three.
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param([Parameter(Mandatory)][string]$Path)
    $result = [pscustomobject]@{
        Path           = $Path
        IsCoSigned     = $false
        SignerCount    = 0
        SignerSubjects = @()
        WhqlMarker     = ''
        Reason         = 'inspect-failed'
    }
    if (-not (Test-Path -LiteralPath $Path)) {
        $result.Reason = 'file-not-found'
        return $result
    }
    $whqlPattern = '(?i)Microsoft Windows Hardware Compatibility'
    # Step 1: primary signer via Get-AuthenticodeSignature. If the
    # primary already matches WHQL we're done.
    try {
        $sig = Get-AuthenticodeSignature -LiteralPath $Path -ErrorAction Stop
        if ($sig -and $sig.SignerCertificate) {
            $primarySubject = [string]$sig.SignerCertificate.Subject
            $result.SignerSubjects = @($primarySubject)
            $result.SignerCount = 1
            $whqlMatch = [regex]::Match($primarySubject, $whqlPattern)
            if ($whqlMatch.Success) {
                $result.IsCoSigned = $true
                $result.WhqlMarker = $whqlMatch.Value
                $result.Reason = 'cosigned'
                return $result
            }
        } elseif ($sig -and $sig.Status -eq 'NotSigned') {
            $result.Reason = 'unsigned'
            return $result
        }
    } catch {
        # Fall through to signtool probe; the file may still have a
        # parseable nested-signature even when Get-AuthenticodeSignature
        # rejects the surface.
        Set-DebugStep ('Test-WhqlCoSignature: Get-AuthenticodeSignature failed for {0}: {1}' -f $Path, $_.Exception.Message)
    }
    # Step 2: try signtool to enumerate co-signers. Find-Signtool is the
    # cross-script helper used elsewhere; it returns $null if WDK is
    # not installed, in which case we cannot reach nested signatures
    # from PS 5.1.
    $signtool = $null
    try {
        $signtool = Find-Signtool
    } catch {
        Set-DebugStep ('Test-WhqlCoSignature: Find-Signtool threw: {0}' -f $_.Exception.Message)
    }
    if (-not $signtool) {
        # Without signtool we cannot enumerate co-signers on PS 5.1.
        # Conservative classification: if the primary signer was a non-
        # WHQL Microsoft cert (e.g. AMD's own publisher), we cannot
        # confirm a WHQL co-signature; report 'self-only' which the
        # caller will treat as non-cosigned for Path B purposes.
        if ($result.SignerCount -gt 0) {
            $result.Reason = 'self-only'
        }
        return $result
    }
    # signtool verify /pa /v <file> exits 0 when at least one signature
    # is valid for kernel-mode use. We parse stdout for the per-
    # signature certificate chain block. The output is stable across
    # signtool versions 6.0..10.0.x.
    $stdOut = ''
    try {
        $stdOut = & $signtool verify /pa /v $Path 2>&1 | Out-String
    } catch {
        Set-DebugStep ('Test-WhqlCoSignature: signtool invocation failed for {0}: {1}' -f $Path, $_.Exception.Message)
        return $result
    }
    # Parse signer subjects from "Issued to:" lines. Each "Number of
    # signatures successfully Verified: N" block precedes one or more
    # certificate chains; each chain ends with the leaf "Issued to:".
    $subjects = New-Object System.Collections.Generic.List[string]
    foreach ($line in ($stdOut -split "`r?`n")) {
        $trim = $line.Trim()
        if ($trim -match '^Issued to:\s*(.+)$') {
            [void]$subjects.Add($Matches[1].Trim())
        }
    }
    if ($subjects.Count -gt 0) {
        $result.SignerSubjects = $subjects.ToArray()
        $result.SignerCount = $subjects.Count
        foreach ($subj in $subjects) {
            $whqlMatch = [regex]::Match($subj, $whqlPattern)
            if ($whqlMatch.Success) {
                $result.IsCoSigned = $true
                $result.WhqlMarker = $whqlMatch.Value
                $result.Reason = 'cosigned'
                return $result
            }
        }
        $result.Reason = 'self-only'
    }
    return $result
}

function Get-InfDriverFileList { # psa-disable-line PSA6003 -- compound noun (e.g., Policies, Drivers, Catalogs) is semantically plural for set-returning helpers
    # Resolve the list of .sys files that an INF declares via its
    # [SourceDisksFiles] / [CopyFiles] sections. Returns absolute paths
    # under the INF's containing directory. The .sys list is what
    # kernel CI evaluates at boot time; .dll/.exe siblings load in
    # user-mode and are out of scope.
    [CmdletBinding()]
    [OutputType([string[]])]
    param([Parameter(Mandatory)][string]$InfPath)
    if (-not (Test-Path -LiteralPath $InfPath)) {
        return @()
    }
    $infDir = Split-Path -LiteralPath $InfPath -Parent
    $result = New-Object System.Collections.Generic.List[string]
    $seen = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::OrdinalIgnoreCase)
    # Pass 1: extract referenced .sys filenames from the INF text body.
    $text = ''
    try {
        $text = Get-Content -LiteralPath $InfPath -Raw -ErrorAction Stop
    } catch {
        Set-DebugStep ('Get-InfDriverFileList: cannot read {0}: {1}' -f $InfPath, $_.Exception.Message)
        return @()
    }
    foreach ($m in [regex]::Matches($text, '(?im)([A-Za-z0-9_.\-]+\.sys)')) {
        $sys = $m.Groups[1].Value
        if ($seen.Add($sys)) {
            $candidate = Join-Path -Path $infDir -ChildPath $sys
            if (Test-Path -LiteralPath $candidate) {
                $result.Add($candidate)
            } else {
                # Some AMD packages stage .sys files in a sibling arch
                # subdirectory (e.g. .md64oo.sys). Probe one level
                # down for any arch directories.
                foreach ($sub in @('amd64', 'x64', 'Win64')) {
                    $subCandidate = Join-Path -Path (Join-Path -Path $infDir -ChildPath $sub) -ChildPath $sys
                    if (Test-Path -LiteralPath $subCandidate) {
                        $result.Add($subCandidate)
                        break
                    }
                }
            }
        }
    }
    return ,@($result.ToArray())
}

function New-WhqlCoSignAnalysis { # psa-disable-line PSA6003 -- "Analysis" is the singular form of "Analyses"; this returns one analysis record
    # Build the per-INF WHQL co-sign analysis attached to $Ctx by P05.
    # Each entry in the returned array has:
    #   - InfName        ([string])   INF base name
    #   - InfPath        ([string])   absolute path to the INF
    #   - DriverFiles    ([string[]]) absolute paths to .sys files
    #   - CoSignedFiles  ([string[]]) subset of DriverFiles that are WHQL co-signed
    #   - NonCoSignedFiles ([string[]]) the rest
    #   - IsFullyCoSigned ([bool])    true iff DriverFiles.Count -gt 0 AND CoSignedFiles.Count -eq DriverFiles.Count
    #   - HasMixedSigning ([bool])    true iff both lists are non-empty (partial coverage; rare)
    [CmdletBinding()]
    [OutputType([pscustomobject[]])]
    param([Parameter(Mandatory)][AllowEmptyCollection()][object[]]$InfRecords)
    $analyses = New-Object System.Collections.Generic.List[pscustomobject]
    foreach ($rec in $InfRecords) {
        $infName = if ($rec.InfName) { [string]$rec.InfName } else { Split-Path -Leaf $rec.InfPath }
        $infPath = if ($rec.InfPath) { [string]$rec.InfPath } elseif ($rec.FullName) { [string]$rec.FullName } else { '' }
        if ([string]::IsNullOrEmpty($infPath)) {
            continue
        }
        $sysFiles = Get-InfDriverFileList -InfPath $infPath
        $coSigned = New-Object System.Collections.Generic.List[string]
        $nonCoSigned = New-Object System.Collections.Generic.List[string]
        foreach ($sys in $sysFiles) {
            $verdict = Test-WhqlCoSignature -Path $sys
            if ($verdict.IsCoSigned) {
                $coSigned.Add($sys)
            } else {
                $nonCoSigned.Add($sys)
            }
        }
        $totalCount = $sysFiles.Count
        $coCount = $coSigned.Count
        $analyses.Add([pscustomobject]@{
            InfName          = $infName
            InfPath          = $infPath
            DriverFiles      = $sysFiles
            CoSignedFiles    = $coSigned.ToArray()
            NonCoSignedFiles = $nonCoSigned.ToArray()
            IsFullyCoSigned  = ($totalCount -gt 0 -and $coCount -eq $totalCount)
            HasMixedSigning  = ($coCount -gt 0 -and $coCount -lt $totalCount)
        })
    }
    return ,@($analyses.ToArray())
}

function Show-WhqlCoSignAnalysisReport {
    # Pretty-print the WHQL co-sign analysis to the operator console.
    # Called from P05 after New-WhqlCoSignAnalysis completes.
    [CmdletBinding()]
    param([Parameter(Mandatory)][AllowEmptyCollection()][object[]]$Analyses)
    if ($Analyses.Count -eq 0) {
        Write-Detail '  (no INFs analysed; WHQL co-sign analysis is empty)'
        return
    }
    $fully = @($Analyses | Where-Object IsFullyCoSigned)
    $mixed = @($Analyses | Where-Object HasMixedSigning)
    $none  = @($Analyses | Where-Object { -not $_.IsFullyCoSigned -and -not $_.HasMixedSigning })
    Write-Host '--- WHQL co-signature analysis ---' -ForegroundColor Cyan
    Write-Host ('  Fully WHQL co-signed INFs   : {0}' -f $fully.Count) -ForegroundColor Green
    Write-Host ('  Mixed-signing INFs (partial): {0}' -f $mixed.Count) -ForegroundColor Yellow
    $noneColor = if ($none.Count -gt 0) { 'Yellow' } else { 'Green' }
    Write-Host ('  No WHQL co-signature        : {0}' -f $none.Count) -ForegroundColor $noneColor
    if ($mixed.Count -gt 0) {
        Write-Host '  Mixed-signing detail:' -ForegroundColor DarkYellow
        foreach ($a in $mixed) {
            Write-Host ('    - {0}: {1} co-signed, {2} not co-signed' -f $a.InfName, $a.CoSignedFiles.Count, $a.NonCoSignedFiles.Count) -ForegroundColor DarkYellow
        }
    }
    if ($none.Count -gt 0) {
        Write-Host '  Non-co-signed detail (first 10):' -ForegroundColor DarkYellow
        $sample = $none | Select-Object -First 10
        foreach ($a in $sample) {
            Write-Host ('    - {0} ({1} .sys file(s))' -f $a.InfName, $a.DriverFiles.Count) -ForegroundColor DarkYellow
        }
        if ($none.Count -gt $sample.Count) {
            Write-Host ('    ... and {0} more' -f ($none.Count - $sample.Count)) -ForegroundColor DarkYellow
        }
    }
}

function Test-SecureBootEnabledFromFirmware { # psa-disable-line PSA6003 -- "Firmware" is a mass noun; the function returns a single boolean state
    # Returns $true if UEFI Secure Boot is currently ENABLED in
    # firmware, $false if disabled, $null if undetermined (legacy BIOS
    # or constrained host without Confirm-SecureBootUEFI permission).
    # This is the firmware-layer check that Path B prerequisite logic
    # cares about: bcdedit /set TESTSIGNING ON is refused by the
    # firmware when Secure Boot is ON, regardless of OS-layer state.
    [CmdletBinding()]
    [OutputType([System.Nullable[bool]])]
    param()
    try {
        $state = Confirm-SecureBootUEFI
        return [bool]$state
    } catch {
        # Common reasons: not running as admin, legacy BIOS (no UEFI),
        # or running inside a constrained VM without firmware
        # passthrough. The caller's branch logic treats $null as a
        # request for explicit operator guidance rather than auto-
        # proceeding.
        Set-DebugStep ('Test-SecureBootEnabledFromFirmware: Confirm-SecureBootUEFI threw: {0}' -f $_.Exception.Message)
        return $null
    }
}

function Invoke-PathBPrerequisiteCheck {
    # Verify the firmware prerequisites for Path B (testsigning) before
    # I02 commits the bcdedit change. Microsoft Learn documents
    # ("The TESTSIGNING boot configuration option") that
    # `bcdedit /set TESTSIGNING ON` is REFUSED AT COMMAND EXECUTION
    # with the error "The value is protected by Secure Boot policy and
    # cannot be modified or deleted." when Secure Boot is ON. Detect
    # that condition here and ABORT with explicit firmware-change
    # instructions rather than letting bcdedit fail mid-phase.
    #
    # Returns a pscustomobject with:
    #   - Result        ([string]) 'ok' | 'abort'
    #   - Reason        ([string]) short diagnostic key
    #   - GuidanceLines ([string[]]) operator-facing instruction block
    #
    # The caller is expected to throw on Result='abort' so I02 stops
    # before any host-state modification.
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param([Parameter(Mandatory)] $Ctx)
    $result = [pscustomobject]@{
        Result        = 'ok'
        Reason        = ''
        GuidanceLines = @()
    }
    $sbState = Test-SecureBootEnabledFromFirmware
    if ($sbState -eq $true) {
        $lines = @(
            '',
            '========================================================================',
            ' PATH B PREREQUISITE NOT MET: UEFI Secure Boot is ENABLED in firmware.',
            '========================================================================',
            '',
            '  bcdedit /set TESTSIGNING ON is REFUSED by the firmware when Secure',
            '  Boot is ON. Microsoft documents this rejection in the article',
            '  "The TESTSIGNING boot configuration option" with the verbatim',
            '  error message:',
            '',
            '      The value is protected by Secure Boot policy and',
            '      cannot be modified or deleted.',
            '',
            '  To proceed on Path B, perform these steps in order:',
            '',
            '    1. Save your BitLocker recovery key. Disabling Secure Boot may',
            '       force a recovery prompt on the next boot. Without the key,',
            '       the drive contents become inaccessible.',
            '',
            '    2. Reboot into firmware setup (vendor-specific; typically F1 / F2',
            '       / F10 / F12 / Delete during POST).',
            '',
            '    3. Navigate to Security or Boot menu and set Secure Boot = Disabled.',
            '       Save and exit firmware setup.',
            '',
            '    4. Boot normally into Windows. If prompted, enter your BitLocker',
            '       recovery key.',
            '',
            '    5. Re-run this script with -UseTestSigning. I02 will then accept',
            '       Path B and apply the TESTSIGNING flag.',
            '',
            '  Alternative: if all candidate INFs are WHQL co-signed (see the',
            '  P05 WHQL co-sign analysis output earlier in this run), you can',
            '  drop -UseTestSigning and re-run on Path A (trust-store only,',
            '  Secure Boot may remain ON).',
            '',
            '  Alternative: if you want to keep Secure Boot ON and accept that',
            '  non-WHQL drivers will not load, pass -SkipNonCosignedDrivers to',
            '  remove the non-WHQL subset from the install plan and stay on',
            '  Path A.',
            '',
            '  See SPEC SS D.30.4 (Microsoft Learn cross-reference F9) and',
            '  SPEC SS D.31 for the full r71 design rationale.',
            ''
        )
        $result.Result = 'abort'
        $result.Reason = 'secure-boot-on'
        $result.GuidanceLines = $lines
        return $result
    }
    if ($null -eq $sbState) {
        $lines = @(
            '',
            '  WARNING: Could not determine UEFI Secure Boot state from this host.',
            '  Confirm-SecureBootUEFI failed (likely: legacy BIOS host, constrained',
            '  VM, or insufficient privilege). Path B will be attempted; if bcdedit',
            '  refuses with the "protected by Secure Boot policy" error, return to',
            '  firmware setup and verify Secure Boot is Disabled before retrying.',
            ''
        )
        $result.Result = 'ok'
        $result.Reason = 'secure-boot-unknown'
        $result.GuidanceLines = $lines
        return $result
    }
    # Secure Boot is OFF in firmware. Path B will succeed.
    $result.Result = 'ok'
    $result.Reason = 'secure-boot-off'
    return $result
}

function Get-EligibleInfRecordList { # psa-disable-line PSA6003 -- compound noun (e.g., Policies, Drivers, Catalogs) is semantically plural for set-returning helpers
    # Apply the -SkipNonCosignedDrivers filter (when set) to a candidate
    # INF list, using the WHQL co-sign analysis captured by P05.
    # Returns the subset eligible for Path A install. When the switch is
    # off, returns the input unchanged.
    [CmdletBinding()]
    [OutputType([pscustomobject[]])]
    param(
        [Parameter(Mandatory)] $Ctx,
        [Parameter(Mandatory)] [AllowEmptyCollection()] [object[]]$InfRecords,
        [switch]$SkipNonCosignedDrivers
    )
    if (-not $SkipNonCosignedDrivers) {
        return ,@($InfRecords)
    }
    if (-not $Ctx.WhqlCoSignAnalysis) {
        # No analysis on Ctx (P05 was skipped or did not populate the
        # field). Conservative behaviour: do not filter; let the
        # operator see the un-trimmed plan and trace the issue.
        Set-DebugStep 'Get-EligibleInfRecordList: -SkipNonCosignedDrivers set but $Ctx.WhqlCoSignAnalysis is empty; pass-through'
        return ,@($InfRecords)
    }
    $coSignedLookup = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::OrdinalIgnoreCase)
    foreach ($a in $Ctx.WhqlCoSignAnalysis) {
        if ($a.IsFullyCoSigned) {
            [void]$coSignedLookup.Add($a.InfName)
        }
    }
    $eligible = New-Object System.Collections.Generic.List[pscustomobject]
    foreach ($rec in $InfRecords) {
        $name = if ($rec.InfName) { [string]$rec.InfName } else { Split-Path -Leaf $rec.InfPath }
        if ($coSignedLookup.Contains($name)) {
            $eligible.Add($rec)
        }
    }
    return ,@($eligible.ToArray())
}


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
# SECTION 4: Tool installation helpers
#####################################################################
function Test-WingetWorking {
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) { return $false }
    try { $null = & winget --version 2>&1; return ($LASTEXITCODE -eq 0) }
    catch { return $false }
}

function Get-MachineRegion {
    # Returns the 2-letter ISO region code that winget / msstore APIs
    # expect. Tries multiple sources in order of authority:
    #   1. Get-WinHomeLocation (explicit per-user "Home location" setting
    #      under Region settings; this is the value the Microsoft Store
    #      and msstore source naturally consult).
    #   2. [System.Globalization.RegionInfo]::CurrentRegion (derived from
    #      the active culture).
    #   3. Tail of Get-Culture.Name (e.g. en-US -> US).
    #   4. Static fallback "US".
    try {
        $winHomeLocation = Get-WinHomeLocation -ErrorAction Stop
        if ($winHomeLocation -and $winHomeLocation.HomeLocation) {
            # GeoId -> 2-letter via RegionInfo enumeration. Looking up by
            # English name is brittle, so prefer CurrentRegion.
            $r = [System.Globalization.RegionInfo]::CurrentRegion.TwoLetterISORegionName
            if ($r -and $r.Length -eq 2) { return $r.ToUpper() }
        }
    } catch { } # psa-disable-line PSA3004 -- intentional best-effort cleanup; no error to surface
    try {
        $r = [System.Globalization.RegionInfo]::CurrentRegion.TwoLetterISORegionName
        if ($r -and $r.Length -eq 2) { return $r.ToUpper() }
    } catch { } # psa-disable-line PSA3004 -- intentional best-effort cleanup; no error to surface
    try {
        $tail = (Get-Culture).Name.Split('-')[-1]
        if ($tail -and $tail.Length -eq 2) { return $tail.ToUpper() }
    } catch { } # psa-disable-line PSA3004 -- intentional best-effort cleanup; no error to surface
    return 'US'
}

function Invoke-WingetSilently {
    # Wraps `winget install` with the flags needed for unattended use:
    #   --source winget -> skip msstore (avoids first-use disclaimers
    #                         about Terms of Transaction and the
    #                         "2-letter geographic region" notice)
    #   --accept-source-agreements / --accept-package-agreements
    #   --silent -> no installer GUI / no progress bars
    #
    # Output from winget is captured and lines that match known noise
    # patterns (msstore disclaimers, package licensing boilerplate) are
    # suppressed. The final exit code is preserved via $LASTEXITCODE.
    param(
        [Parameter(Mandatory)] [string]$PackageId
    )
    $noisePattern = '(?i)' + (@(
        'msstore',
        'terms of transaction',
        'aka\.ms/microsoft-store',
        'geographic region',
        '地理的リージョン',
        '2\s*文字',
        '所有者からライセンス',
        'サードパーティのパッケージ',
        'licensed to you by its owner',
        'is not responsible for'
    ) -join '|')

    $output = & winget install -e --id $PackageId `
                  --source winget `
                  --accept-source-agreements `
                  --accept-package-agreements `
                  --silent 2>&1 | Out-String
    $exit = $LASTEXITCODE
    foreach ($rawLine in ($output -split "`r?`n")) {
        if ([string]::IsNullOrWhiteSpace($rawLine)) { continue }
        if ($rawLine -match $noisePattern)          { continue } # psa-disable-line PSA2003 -- pattern variable is initialized in the enclosing scope; $null impossible by construction
        Write-Detail "$rawLine" -Color DarkGray
    }
    return $exit
}

function Get-SevenZipPath {
    foreach ($p in @("${env:ProgramFiles}\7-Zip\7z.exe","${env:ProgramFiles(x86)}\7-Zip\7z.exe")) {
        if (Test-Path $p) { return $p }
    }
    $cmd = Get-Command 7z.exe -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    return $null
}

function Find-KitTool {
    param([string]$Name)

    # First check PATH (winget / installer may have updated environment)
    $cmd = Get-Command $Name -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }

    # Then walk Windows Kits installation directories.
    # NOTE: signtool.exe ships in x64/ AND x86/, but inf2cat.exe is
    # x86-only. We therefore prefer x64 when available, then fall back
    # to any architecture - filtering by x64 alone misses inf2cat.exe
    # entirely and triggers an unnecessary EXE-installer fallback that
    # then fails because the kit is already installed (exit 2008).
    foreach ($root in @("${env:ProgramFiles(x86)}\Windows Kits\10\bin","${env:ProgramFiles}\Windows Kits\10\bin")) {
        if (-not (Test-Path $root)) { continue }
        $allHits = @(Get-ChildItem -Path $root -Recurse -Filter $Name -ErrorAction SilentlyContinue)
        if ($allHits.Count -eq 0) { continue }
        $x64 = $allHits | Where-Object { $_.FullName -match '\\x64\\' } |
               Sort-Object FullName -Descending | Select-Object -First 1
        if ($x64) { return $x64.FullName }
        $any = $allHits | Sort-Object FullName -Descending | Select-Object -First 1
        if ($any) { return $any.FullName }
    }
    return $null
}

function Get-LatestSevenZipUrl {
    # Tier 1: 7-zip.org
    try {
        $resp = Invoke-WebRequest -Uri 'https://www.7-zip.org/download.html' -UseBasicParsing -TimeoutSec 30
        $verMatch = [regex]::Match($resp.Content, 'Download 7-Zip\s+(\d+\.\d+)')
        $msiHits  = [regex]::Matches($resp.Content, 'https?://[^\s"''<>)]+?/7z\d+-x64\.msi')
        if ($msiHits.Count -gt 0) {
            return [pscustomobject]@{
                Version = if ($verMatch.Success) { $verMatch.Groups[1].Value } else { $null }
                MsiUrl  = $msiHits[0].Value
                Source  = '7-zip.org (parsed)'
            }
        }
    } catch { Write-Warn2 "7-zip.org parse failed: $($_.Exception.Message)" }

    # Tier 2: GitHub API
    try {
        $headers = @{ 'User-Agent' = 'PowerShell-AMD-Driver-Prep'; 'Accept' = 'application/vnd.github+json' }
        $api = Invoke-RestMethod -Uri 'https://api.github.com/repos/ip7z/7zip/releases/latest' -Headers $headers -TimeoutSec 30
        $msi = $api.assets | Where-Object { $_.name -match '^7z\d+-x64\.msi$' } | Select-Object -First 1
        if ($msi) {
            return [pscustomobject]@{ Version=$api.tag_name; MsiUrl=$msi.browser_download_url; Source='GitHub Releases API' }
        }
    } catch { Write-Warn2 "GitHub Releases API failed: $($_.Exception.Message)" }

    # Tier 3: pinned
    Write-Warn2 'Both online lookups failed - using pinned URL.'
    return [pscustomobject]@{
        Version='26.01 (pinned)'
        MsiUrl='https://github.com/ip7z/7zip/releases/download/26.01/7z2601-x64.msi'
        Source='pinned fallback'
    }
}

function Install-SevenZipFallback {
    param([string]$DownloadDir)
    $info = Get-LatestSevenZipUrl
    Write-Detail "Version : $($info.Version)"
    Write-Detail "Source  : $($info.Source)"
    Write-Detail "URL     : $($info.MsiUrl)"
    $msi = Join-Path $DownloadDir (Split-Path $info.MsiUrl -Leaf)
    if (-not (Test-Path $msi)) {
        Invoke-WebRequest -Uri $info.MsiUrl -OutFile $msi -UseBasicParsing
    }
    $proc = Start-Process msiexec.exe -ArgumentList @('/i',"`"$msi`"",'/qn','/norestart') -Wait -PassThru # psa-disable-line PSA3001 -- Start-Process -ArgumentList is the canonical pattern for invoking signtool/inf2cat/pnputil with explicit args
    if ($proc.ExitCode -ne 0) { throw "7-Zip MSI install failed (exit $($proc.ExitCode))" }
}

function Install-WindowsSdkFallback {
    param($OsContext, [string]$DownloadDir)
    Write-Detail "Target build : $($OsContext.SdkBuild)"
    Write-Detail "URL          : $($OsContext.SdkUrl)"
    $exe = Join-Path $DownloadDir "winsdksetup_$($OsContext.Code).exe"
    if (-not (Test-Path $exe)) {
        Invoke-WebRequest -Uri $OsContext.SdkUrl -OutFile $exe -UseBasicParsing
    }
    $proc = Start-Process $exe -ArgumentList $OsContext.SdkInstallArgs -Wait -PassThru # psa-disable-line PSA3001 -- Start-Process -ArgumentList is the canonical pattern for invoking signtool/inf2cat/pnputil with explicit args

    # Some MSI / VS-style bootstrap installers (winsdksetup.exe, wdksetup.exe)
    # exit non-zero when the kit is already present on the machine
    # (commonly observed: 2008 = "already installed"). Verify by tool
    # presence rather than trusting the exit code.
    if (Find-KitTool 'signtool.exe') {
        if ($proc.ExitCode -ne 0) {
            Write-Warn2 "SDK installer exit code $($proc.ExitCode); signtool.exe is present, treating as already installed."
        }
        return
    }
    throw "Windows SDK install failed (exit $($proc.ExitCode)) - signtool.exe still not found"
}

function Install-WindowsWdkFallback {
    param($OsContext, [string]$DownloadDir)
    Write-Detail "Target build : $($OsContext.WdkBuild)"
    Write-Detail "URL          : $($OsContext.WdkUrl)"
    $exe = Join-Path $DownloadDir "wdksetup_$($OsContext.Code).exe"
    if (-not (Test-Path $exe)) {
        Invoke-WebRequest -Uri $OsContext.WdkUrl -OutFile $exe -UseBasicParsing
    }
    $proc = Start-Process $exe -ArgumentList $OsContext.WdkInstallArgs -Wait -PassThru # psa-disable-line PSA3001 -- Start-Process -ArgumentList is the canonical pattern for invoking signtool/inf2cat/pnputil with explicit args

    # Same defensive check as the SDK fallback above.
    if (Find-KitTool 'inf2cat.exe') {
        if ($proc.ExitCode -ne 0) {
            Write-Warn2 "WDK installer exit code $($proc.ExitCode); inf2cat.exe is present, treating as already installed."
        }
        return
    }
    throw "Windows WDK install failed (exit $($proc.ExitCode)) - inf2cat.exe still not found"
}

#####################################################################
# SECTION 5: AMD URL discovery
#####################################################################
#
#=======================================================================================================================
# AMD Site Query Specification (used by P03 - URL discovery and codename lookup)
#=======================================================================================================================
#
# Unlike NVIDIA's processDriver.aspx / lookupValueSearch.aspx XML API
# (a public structured API used as the model for this section), AMD
# does NOT publish a structured public query API for driver discovery.
# AMD's driver-distribution model has three exposed paths, only the
# first two of which are scriptable:
#
#   1. Per-product HTML LANDING PAGE on www.amd.com that lists
#      currently-recommended driver download(s) plus a side-panel
#      Specifications block (Family / Series / Former Codename / etc).
#      <-- this script PARSES these pages.
#
#   2. Direct DRIVER EXE URLs on drivers.amd.com that the landing
#      pages link to. Filename naming convention encodes branch
#      (Main vs Vega-Polaris Legacy) and version.
#      <-- this script DOWNLOADS these.
#
#   3. The "AMD Software Installer" Auto-detect tool - a binary
#      Windows utility at amd.com/en/support/download/auto-detect.html
#      that discovers the local hardware and fetches drivers.
#      <-- not scriptable; not used by this script.
#
# This script therefore takes a SCRAPING approach: build the right
# product page URL, GET it with browser-style headers, and extract:
#   (a) Driver EXE URL(s) from the page [Get-LatestAmdGraphicsUrl]
#   (b) "Former Codename" specification field [Get-AmdCodenameFromUrl]
#   (c) Source page identity (for logging / audit)
#
#=======================================================================================================================
#
# === [1] Product page URL conventions ==============================
#
#   ROOT (en-US):
#     https://www.amd.com/en/support/downloads/drivers.html
#   ROOT (ja-JP - the script auto-uses this when host locale is JP):
#     https://www.amd.com/ja/support/downloads/drivers.html
#
#   Below ROOT, AMD organizes products into two top-level branches
#   (processors / graphics) and then into family / series / model:
#
#   [Processors / APUs - CPU page hierarchy]
#     /processors/<family>/<series>/<product-slug>.html
#
#     <family> examples: 'ryzen', 'ryzen-pro', 'epyc',
#                     'threadripper', 'threadripper-pro', 'athlon',
#                     'ryzen-ai'
#     <series> examples: 'ryzen-5000-series',
#                     'ryzen-pro-5000-series', 'ryzen-pro-4000-series',
#                     'ryzen-7000-series', 'ryzen-ai-300-series'
#     <product-slug> product name lower-cased with dashes:
#                     'amd-ryzen-7-pro-5750ge', 'amd-ryzen-7-5800u'
#
#   [Graphics / Discrete GPUs - GPU page hierarchy]
#     /graphics/<family>/<series>/<product-slug>.html
#
#     <family> examples: 'radeon-rx', 'radeon-pro',
#                     'radeon-ai-pro', 'radeon-rx-vega-series',
#                     'radeon-instinct'
#     <series> examples: 'radeon-rx-9000-series',
#                     'radeon-rx-7000-series', 'radeon-rx-vega-series',
#                     'radeon-ai-pro-r9000-series'
#     <product-slug> examples: 'amd-radeon-rx-9070-xt',
#                     'amd-radeon-rx-vega-64', 'amd-radeon-ai-pro-r9700'
#
#   Concrete examples (verified live 2026-05):
#     # Cezanne APU (this script's primary target)
#     /processors/ryzen-pro/ryzen-pro-5000-series/amd-ryzen-7-pro-5750ge.html
#     # Cezanne refresh
#     /processors/ryzen-pro/ryzen-pro-5000-series/amd-ryzen-7-pro-5755ge.html
#     # Renoir APU
#     /processors/ryzen-pro/ryzen-pro-4000-series/amd-ryzen-7-pro-4750ge.html
#     # Cezanne consumer (Lucienne)
#     /processors/ryzen/ryzen-5000-series/amd-ryzen-7-5800u.html
#     # RDNA 4 dGPU
#     /graphics/radeon-rx/radeon-rx-9000-series/amd-radeon-rx-9070-xt.html
#     # RDNA 4 AI Pro
#     /graphics/radeon-ai-pro/radeon-ai-pro-r9000-series/amd-radeon-ai-pro-r9700.html
#
# === [2] How the script constructs the URL for detected hardware ===
#
#   Step 1: Detect AMD product name on the local host.
#             dGPU: Win32_PnPEntity with PCI\VEN_1002 + Display class
#             APU: Win32_Processor.Name (when no dGPU found)
#           See: Get-AmdGpuTarget
#
#   Step 2: Slugify the product name.
#             'AMD Ryzen 7 PRO 5750GE' -> 'amd-ryzen-7-pro-5750ge'
#             'AMD Radeon RX 9070 XT' -> 'amd-radeon-rx-9070-xt'
#           See: Convert-AmdProductNameToSlug
#
#   Step 3: Extract 4-digit (or 'Rxxxx'/'Wxxxx') series number to
#           build the {N}000-series path component.
#             '5750GE' -> 5000
#             '9070' -> 9000
#             'R9700' -> 9000
#           See: Get-AmdProductSeriesNumber
#
#   Step 4: Compose the path based on family (Ryzen / Ryzen Pro /
#           Radeon RX / Radeon AI Pro / Radeon Pro).
#           See: Get-AmdProductPageUrl
#
# === [3] Fields extracted from the product page ====================
#
#   Each AMD product page renders a side-panel Specifications block
#   as bullet-separated key-value pairs (rendered "Key Value" with
#   a U+00B7 MIDDLE DOT separator on most page templates).
#
#   FIELDS RELEVANT TO THIS SCRIPT:
#
#     Former Codename The single most important field.
#                                    Maps directly to the AMD code
#                                    reference (Cezanne, Renoir,
#                                    Phoenix, Strix Point,...) which
#                                    in turn maps to GPU architecture
#                                    (Vega vs RDNA) and therefore the
#                                    Adrenalin driver branch (Main vs
#                                    Vega-Polaris Legacy).
#
#                                    Example values (verified 2026-05):
#                                      "Cezanne" (Ryzen 5000G/U)
#                                      "Renoir" (Ryzen 4000G/U)
#                                      "Picasso" (Ryzen 3000G)
#                                      "Raven Ridge" (Ryzen 2000G)
#                                      "Rembrandt" (Ryzen 6000U/H)
#                                      "Phoenix" (Ryzen 7040)
#                                      "Hawk Point" (Ryzen 8040)
#                                      "Strix Point" (Ryzen AI 300)
#                                      "Strix Halo" (Ryzen AI Max)
#
#                                    See: Get-AmdCodenameFromUrl,
#                                    $Script:AmdCodenameMap
#
#     Family / Series Useful for sanity-checking the
#                                    URL slug. Not used today.
#
#     Processor Architecture Zen 1/2/3/4/5 (CPU side, NOT the
#                                    GPU architecture).
#
#     Graphics Model / Graphics Tells whether an APU is present
#     Core Count / Graphics and how big the iGPU is. Not
#     Frequency used today; could later be used
#                                    to skip patching for SKUs without
#                                    integrated graphics (e.g. Ryzen
#                                    5 5600X has no iGPU; its product
#                                    page omits these Graphics-* fields).
#
# === [4] Driver download URL patterns =============================
#
#   AMD hosts driver EXEs on a dedicated CDN domain:
#
#     https://drivers.amd.com/drivers/<filename>.exe
#
#   FILENAME PATTERNS recognized by Get-LatestAmdGraphicsUrl:
#
#     whql-amd-software-adrenalin-edition-{VERSION}-{...}.exe
#       Standard consumer Adrenalin Edition driver.
#       Two parallel branches are distributed simultaneously:
#
#       (A) Main / RDNA branch:
#             ...adrenalin-edition-{VERSION}-win11-b.exe
#             (no 'vega-polaris' substring)
#             Supports RDNA-class GPUs/APUs only
#             (RX 5000 / 6000 / 7000 / 9000, Rembrandt+/Phoenix+/...)
#
#       (B) Legacy / Vega-Polaris branch:
#             ...adrenalin-edition-{VERSION}-win11-...vega-polaris.exe
#             (substring 'vega-polaris' or 'polaris-vega' present)
#             Supports Polaris dGPUs and Vega-class APUs/dGPUs
#             (RX 4xx/5xx, Vega 56/64/VII, Raven/Picasso/Renoir/
#             Cezanne/Barcelo/Barcelo-R)
#
#       VERSION format: YY.M.M (e.g., '26.5.1' = May 2026, minor 1).
#       Branch (A) version always >= branch (B) version because the
#       legacy branch is on a slower release cadence.
#
#     amd-software-pro-edition-{VERSION}-...exe
#       Workstation / Radeon Pro class driver (e.g., for Pro Wxxxx
#       cards). Recognized by the URL pattern but secondary for
#       typical consumer/lab use.
#
#     embedded-radeon-software-{VERSION}-...exe
#       Embedded SKUs (Ryzen Embedded V/R series). Rare on Windows.
#
#   The script's URL extraction regex deliberately accepts any of the
#   above filename styles because all three contain at least one of
#   the keywords {adrenalin, software, radeon}. See $pattern in
#   Get-LatestAmdGraphicsUrl.
#
# === [5] OS targeting (key difference vs the NVIDIA model) =========
#
#   NVIDIA's processDriver.aspx API takes an explicit osid parameter:
#       Win2008R2 = 21
#       Win2012R2 = 44
#       Win2016 = 74
#       Win2019 = 119
#       Win2022 = 134
#
#   AMD does NOT have an equivalent. A single AMD installer EXE
#   supports BOTH Windows 10 and Windows 11 (and, after this script's
#   INF patching, Windows Server 2022 / 2025). AMD uses 'win11' or
#   'win10' in some filenames as a binary-platform tag, but the same
#   EXE will install on the other client major version.
#
#   There is no separate Server build either - the consumer driver
#   is the only one published, and it requires the
#   ProductType=3 / SKU-Differentiation patching that this script
#   performs in P05/P06 to install on Windows Server.
#
#   Implication: P03 never needs to switch URL based on host OS.
#
# === [6] Comparison summary: NVIDIA vs AMD discovery models ========
#
#       Aspect NVIDIA AMD
# ------------------ --------------------------- --------------------------
#       Public API XML query API NONE (HTML scraping only)
#                           (lookupValueSearch.aspx,
#                           processDriver.aspx)
#       Product catalog Numeric IDs (psid/pfid) URL slug strings
#                           in 3-level hierarchy in 3-level URL path
#                           (TypeID 1->2->3) (family/series/product)
#       OS selection Numeric osid query param Same EXE for all OSes;
#                                                        no per-OS URL variant
#       Language Numeric lid query param 'en'/'ja' segment in
#                                                        landing-page URL
#       Driver discovery Direct API call returns Scrape product page,
#                           the EXE URL parse <a href> for EXE
#       Branch selection N/A (single branch) 'vega-polaris' substring
#                                                        marks legacy branch
#       Auto-detect tool GeForce Experience AMD Software Installer
#                           (binary, not scriptable) (binary, not scriptable)
#       Codename exposure Driver naming only "Former Codename" field
#                                                        on each product page
#                                                        (publicly readable)
#
#=======================================================================================================================

# ====================================================================
# Get-AmdGpuTarget
# --------------------------------------------------------------------
# Identify the AMD GPU/APU running on this system so the script can
# resolve the correct AMD product page (which lists the matching
# graphics driver download).
#
# Detection priority:
#   1. Discrete GPU (dGPU) — Win32_PnPEntity with PCI\VEN_1002 and a
#      Display class. If multiple are present, the first one with a
#      bound driver wins. dGPU takes precedence over iGPU because if
#      a discrete card is present that's what the user wants drivers
#      for.
#   2. Integrated APU (iGPU) — when no dGPU is found, fall back to
#      the CPU's Win32_Processor.Name. APU graphics drivers ship from
#      the CPU's product page on AMD support, not a graphics page.
#   3. Unknown — return $null. Caller falls back to the user-provided
#      AmdLandingUrls / AmdFallbackUrl pinned defaults.
#
# Returns @{ Type; FullName; Source } where:
#   Type = 'DGPU' | 'APU' | $null
#   FullName = the device/CPU display name (e.g. 'AMD Radeon RX 9070 XT'
#              or 'AMD Ryzen 7 PRO 5750GE')
#   Source = short label of where the value came from (for logging)
# ====================================================================
function Get-AmdGpuTarget {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    # Step 1: dGPU search via PnPEntity. Only accept a dGPU if it has
    # a SPECIFIC model identifier in its name (RX/Pro/AI Pro/Wxxxx/
    # Rxxxx with 4-digit model). The generic "AMD Radeon(TM) Graphics"
    # name used for ALL Cezanne / Renoir / Phoenix APU iGPUs has no
    # model number and would not yield a product page URL - in that
    # case we fall through to CPU-based APU detection instead.
    try {
        $displayDevs = Get-CimInstance -ClassName Win32_PnPEntity -ErrorAction Stop |
            Where-Object {
                $_.PNPDeviceID -match '^PCI\\VEN_1002&' -and
                $_.PNPClass -eq 'Display'
            }
    } catch {
        $displayDevs = @()
    }
    foreach ($d in @($displayDevs)) {
        if (-not $d.Name) { continue }
        if ($d.Name -match '^(Microsoft|Standard|Generic).*Display') { continue }
        # Heuristic: a real dGPU advertises a specific product line.
        # Names that lack a discriminating qualifier (e.g. plain
        # "AMD Radeon(TM) Graphics") are APU iGPUs - skip and let
        # CPU detection handle them.
        $hasModelQualifier =
            ($d.Name -match '\bRX\s+\d{3,4}') -or
            ($d.Name -match '\bRadeon\s+(?:AI\s+)?Pro\b') -or
            ($d.Name -match '\b[RW]\d{3,4}\b')
        if (-not $hasModelQualifier) { continue }
        return [pscustomobject]@{
            Type     = 'DGPU'
            FullName = $d.Name
            Source   = 'Win32_PnPEntity (PCI\VEN_1002, Display, model-qualified)'
        }
    }

    # Step 2: APU iGPU via CPU detection. Used both when no dGPU is
    # present and when the dGPU name is a generic APU iGPU label.
    try {
        $cpu = Get-CimInstance -ClassName Win32_Processor -ErrorAction Stop |
            Select-Object -First 1
    } catch {
        $cpu = $null
    }
    if ($cpu -and $cpu.Name -and $cpu.Name -match '\bAMD\b|\bRyzen\b|\bAthlon\b|\bEPYC\b') {
        return [pscustomobject]@{
            Type     = 'APU'
            FullName = $cpu.Name.Trim()
            Source   = 'Win32_Processor (AMD CPU)'
        }
    }

    # Step 3: unknown
    return $null
}

# ====================================================================
# Convert-AmdProductNameToSlug
# --------------------------------------------------------------------
# Convert a product display name to the URL-slug form AMD uses on
# its support pages. Examples:
#   'AMD Ryzen 7 PRO 5750GE' -> 'amd-ryzen-7-pro-5750ge'
#   'AMD Radeon RX 9070 XT' -> 'amd-radeon-rx-9070-xt'
#   'AMD Radeon AI Pro R9700' -> 'amd-radeon-ai-pro-r9700'
# Strips trademark markers (TM)/(R), normalizes whitespace, and uses
# hyphens as the path separator.
# ====================================================================
function Convert-AmdProductNameToSlug {
    [CmdletBinding()]
    [OutputType([string])]
    param([Parameter(Mandatory)] [string]$Name)
    $s = $Name.ToLower().Trim()
    $s = $s -replace '\(tm\)|\(r\)|\(c\)', ''
    $s = $s -replace 'with\s+radeon\s+graphics', ''   # APU "AMD Ryzen 7 5800U with Radeon Graphics"
    $s = $s -replace '\s+processor\s*$', ''
    $s = $s.Trim()
    $s = $s -replace '\s+', '-'
    $s = $s -replace '-+', '-'
    return $s.Trim('-')
}

# ====================================================================
# Get-AmdProductSeriesNumber
# --------------------------------------------------------------------
# Extract the AMD "series" thousand-base from a model number.
# Examples:
#   '5750GE' -> 5000
#   '9070' -> 9000
#   'R9700' -> 9000
#   'W6800' -> 6000
# Returns $null if no recognizable 4-digit model is found.
# ====================================================================
function Get-AmdProductSeriesNumber {
    [CmdletBinding()]
    [OutputType([int])]
    param([Parameter(Mandatory)] [string]$Name)
    # Match a 4-digit (or "Rxxxx" / "Wxxxx") model number embedded in the name.
    if ($Name -match '\b[RW]?(\d)\d{3}\w*\b') {
        return ([int]$matches[1]) * 1000
    }
    return $null
}

# ====================================================================
# AMD Codename -> Driver Branch lookup table
# --------------------------------------------------------------------
# Authoritative codename -> {branch, architecture, GC version} table
# derived from the Linux kernel AMD hardware list and confirmed
# against AMD's per-product spec pages (the "Former Codename" field
# that appears in the side panel of every CPU/APU/GPU product page on
# www.amd.com). This is the SOURCE OF TRUTH for branch selection
# when a codename can be determined.
#
# Sources cross-referenced:
#   - docs.kernel.org/gpu/amdgpu/amd-hardware-list-info.html
#       Code Reference -> GC version table
#   - www.amd.com/en/products/specifications/processors.html
#       CPU/APU spec catalog (Former Codename field per product)
#   - www.amd.com/en/products/specifications/graphics.html
#       Graphics spec catalog (Former Codename for dGPUs)
#
# Keys are normalized to lowercase, hyphens removed, single spaces.
# Lookup is done via Test-AmdCodenameLookup which normalizes the
# input the same way before matching.
# ====================================================================
$Script:AmdCodenameMap = @{
    # === APU codenames (Vega-class -> Legacy branch) ===
    'bristol ridge'  = @{ Branch='Legacy'; Arch='Excavator + GCN 3 (very old, possibly EOL)'; GC='-' }
    'carrizo'        = @{ Branch='Legacy'; Arch='GCN 3 (very old)'; GC='8' }
    'stoney'         = @{ Branch='Legacy'; Arch='GCN 3 (very old)'; GC='8' }
    'raven ridge'    = @{ Branch='Legacy'; Arch='Vega'; GC='9.1.0' }
    'raven'          = @{ Branch='Legacy'; Arch='Vega'; GC='9.1.0' }
    'raven2'         = @{ Branch='Legacy'; Arch='Vega Embedded'; GC='9.2.2' }
    'picasso'        = @{ Branch='Legacy'; Arch='Vega'; GC='9.1.0' }
    'renoir'         = @{ Branch='Legacy'; Arch='Vega'; GC='9.3' }
    'lucienne'       = @{ Branch='Legacy'; Arch='Vega (Renoir refresh)'; GC='9.3' }
    'cezanne'        = @{ Branch='Legacy'; Arch='Vega'; GC='9.3' }
    'green sardine'  = @{ Branch='Legacy'; Arch='Vega (kernel-internal name for Cezanne family)'; GC='9.3' }
    'barcelo'        = @{ Branch='Legacy'; Arch='Vega (Cezanne refresh)'; GC='9.3' }
    'barcelo r'      = @{ Branch='Legacy'; Arch='Vega (Cezanne re-refresh, Ryzen 7x30)'; GC='9.3' }

    # === APU codenames (RDNA-class -> Main branch) ===
    'vangogh'        = @{ Branch='Main'; Arch='RDNA 2 (SteamDeck)'; GC='10.3.1' }
    'rembrandt'      = @{ Branch='Main'; Arch='RDNA 2'; GC='10.3.3' }
    'yellow carp'    = @{ Branch='Main'; Arch='RDNA 2 (kernel-internal name for Rembrandt)'; GC='10.3.3' }
    'rembrandt r'    = @{ Branch='Main'; Arch='RDNA 2 (Rembrandt refresh, Ryzen 7x35/7x36)'; GC='10.3.3' }
    'mendocino'      = @{ Branch='Main'; Arch='RDNA 2 (entry-level, Ryzen 7x20)'; GC='10.3.7' }
    'phoenix'        = @{ Branch='Main'; Arch='RDNA 3 (Ryzen 7x40)'; GC='11.0.x' }
    'hawk point'     = @{ Branch='Main'; Arch='RDNA 3 (Ryzen 8x40, Phoenix refresh)'; GC='11.0.x' }
    'strix point'    = @{ Branch='Main'; Arch='RDNA 3.5 (Ryzen AI 300)'; GC='11.5.0' }
    'krackan point'  = @{ Branch='Main'; Arch='RDNA 3.5 (Ryzen AI 330/350)'; GC='11.5.x' }
    'strix halo'     = @{ Branch='Main'; Arch='RDNA 3.5 (Ryzen AI Max 300)'; GC='11.5.1' }
    'gorgon point'   = @{ Branch='Main'; Arch='RDNA 3.5 (Ryzen AI 9 4xx etc.)'; GC='11.5.x' }
    'raphael'        = @{ Branch='Main'; Arch='RDNA 2 iGPU lite (Ryzen 7000 desktop AM5)'; GC='10.3.6' }
    'granite ridge'  = @{ Branch='Main'; Arch='RDNA 2 iGPU lite (Ryzen 9000 desktop AM5)'; GC='10.3.6' }
    'dragon range'   = @{ Branch='Main'; Arch='RDNA 2 iGPU lite (Ryzen 7x45 mobile HX)'; GC='10.3.6' }

    # === Discrete GPU codenames (Polaris/Vega -> Legacy) ===
    'polaris10'      = @{ Branch='Legacy'; Arch='GCN 4 / Polaris (RX 470/480/570/580/590)'; GC='8' }
    'polaris11'      = @{ Branch='Legacy'; Arch='GCN 4 / Polaris (RX 460)'; GC='8' }
    'polaris12'      = @{ Branch='Legacy'; Arch='GCN 4 / Polaris (RX 540/550/640)'; GC='8' }
    'vega10'         = @{ Branch='Legacy'; Arch='Vega (RX Vega 56/64, MI25)'; GC='9.0.1' }
    'vega20'         = @{ Branch='Legacy'; Arch='Vega 7nm (Radeon VII, Pro VII, MI50/60)'; GC='9.4.0' }
    'tahiti'         = @{ Branch='Legacy'; Arch='GCN 1 (HD 7800/7900) - very old'; GC='6' }
    'pitcairn'       = @{ Branch='Legacy'; Arch='GCN 1 (HD 7800) - very old'; GC='6' }
    'verde'          = @{ Branch='Legacy'; Arch='GCN 1 (HD 7700) - very old'; GC='6' }
    'oland'          = @{ Branch='Legacy'; Arch='GCN 1 - very old'; GC='6' }
    'hainan'         = @{ Branch='Legacy'; Arch='GCN 1 - very old'; GC='6' }
    'bonaire'        = @{ Branch='Legacy'; Arch='GCN 2 - very old'; GC='7' }
    'hawaii'         = @{ Branch='Legacy'; Arch='GCN 2 (R9 290/390) - very old'; GC='7' }
    'topaz'          = @{ Branch='Legacy'; Arch='GCN 3 - very old'; GC='8' }
    'tonga'          = @{ Branch='Legacy'; Arch='GCN 3 (R9 380) - very old'; GC='8' }
    'fiji'           = @{ Branch='Legacy'; Arch='GCN 3 (R9 Fury) - very old'; GC='8' }

    # === Discrete GPU codenames (RDNA -> Main) ===
    # Both spaced and unspaced forms are accepted (Linux kernel uses
    # "NAVI10" while AMD product pages tend to use "Navi 10" / "Navi 4x").
    'navi10'         = @{ Branch='Main'; Arch='RDNA 1 (RX 5600/5700)'; GC='10.1.10' }
    'navi 10'        = @{ Branch='Main'; Arch='RDNA 1 (RX 5600/5700)'; GC='10.1.10' }
    'navi14'         = @{ Branch='Main'; Arch='RDNA 1 (RX 5300/5500)'; GC='10.1.1' }
    'navi 14'        = @{ Branch='Main'; Arch='RDNA 1 (RX 5300/5500)'; GC='10.1.1' }
    'navi21'         = @{ Branch='Main'; Arch='RDNA 2 (RX 6800/6900)'; GC='10.3.0' }
    'navi 21'        = @{ Branch='Main'; Arch='RDNA 2 (RX 6800/6900)'; GC='10.3.0' }
    'sienna cichlid' = @{ Branch='Main'; Arch='RDNA 2 (kernel name for Navi 21)'; GC='10.3.0' }
    'navi22'         = @{ Branch='Main'; Arch='RDNA 2 (RX 6700)'; GC='10.3.2' }
    'navi 22'        = @{ Branch='Main'; Arch='RDNA 2 (RX 6700)'; GC='10.3.2' }
    'navy flounder'  = @{ Branch='Main'; Arch='RDNA 2 (kernel name for Navi 22)'; GC='10.3.2' }
    'navi23'         = @{ Branch='Main'; Arch='RDNA 2 (RX 6600)'; GC='10.3.4' }
    'navi 23'        = @{ Branch='Main'; Arch='RDNA 2 (RX 6600)'; GC='10.3.4' }
    'dimgrey cavefish' = @{ Branch='Main'; Arch='RDNA 2 (kernel name for Navi 23)'; GC='10.3.4' }
    'navi24'         = @{ Branch='Main'; Arch='RDNA 2 (RX 6500/6300 mobile)'; GC='10.3.5' }
    'navi 24'        = @{ Branch='Main'; Arch='RDNA 2 (RX 6500/6300 mobile)'; GC='10.3.5' }
    'beige goby'     = @{ Branch='Main'; Arch='RDNA 2 (kernel name for Navi 24)'; GC='10.3.5' }
    'navi31'         = @{ Branch='Main'; Arch='RDNA 3 (RX 7900)'; GC='11.0.0' }
    'navi 31'        = @{ Branch='Main'; Arch='RDNA 3 (RX 7900)'; GC='11.0.0' }
    'navi32'         = @{ Branch='Main'; Arch='RDNA 3 (RX 7800)'; GC='11.0.3' }
    'navi 32'        = @{ Branch='Main'; Arch='RDNA 3 (RX 7800)'; GC='11.0.3' }
    'navi33'         = @{ Branch='Main'; Arch='RDNA 3 (RX 7600)'; GC='11.0.2' }
    'navi 33'        = @{ Branch='Main'; Arch='RDNA 3 (RX 7600)'; GC='11.0.2' }
    'navi 3x'        = @{ Branch='Main'; Arch='RDNA 3 family wildcard'; GC='11.0.x' }
    'navi44'         = @{ Branch='Main'; Arch='RDNA 4 (RX 9060)'; GC='12.0.0' }
    'navi 44'        = @{ Branch='Main'; Arch='RDNA 4 (RX 9060)'; GC='12.0.0' }
    'navi48'         = @{ Branch='Main'; Arch='RDNA 4 (RX 9070)'; GC='12.0.1' }
    'navi 48'        = @{ Branch='Main'; Arch='RDNA 4 (RX 9070)'; GC='12.0.1' }
    'navi 4x'        = @{ Branch='Main'; Arch='RDNA 4 family wildcard'; GC='12.0.x' }

    # === Compute-only (CDNA) - typically for MI Instinct, not consumer ===
    'arcturus'       = @{ Branch='Legacy'; Arch='CDNA 1 (MI100, compute)'; GC='9.4.1' }
    'aldebaran'      = @{ Branch='Legacy'; Arch='CDNA 2 (MI200, compute)'; GC='9.4.2' }
    'aqua vanjaram'  = @{ Branch='Legacy'; Arch='CDNA 3 (MI300, compute)'; GC='9.4.3' }
}

# ====================================================================
# Get-AmdCodenameNormalizedKey
# --------------------------------------------------------------------
# Normalize a free-form codename string ("Cezanne", "Barcelo-R",
# "Strix Point", "GREEN SARDINE",...) to the canonical lookup key
# used in $Script:AmdCodenameMap (lowercase, single spaces, hyphens
# replaced with spaces, surrounding whitespace trimmed).
# ====================================================================
function Get-AmdCodenameNormalizedKey {
    [CmdletBinding()]
    [OutputType([string])]
    param([Parameter(Mandatory)] [string]$Codename)
    $key = $Codename.Trim().ToLower()
    # Split on whitespace and hyphens, collapse to single space
    $parts = [regex]::Split($key, '[\s_\-/]+') | Where-Object { $_ }
    return ($parts -join ' ')
}

# ====================================================================
# Get-AmdCodenameFromUrl
# --------------------------------------------------------------------
# Fetch an AMD product page (e.g., a CPU/APU/GPU support or product
# page on www.amd.com) and extract the "Former Codename" field. AMD
# ships this field on essentially every individual product page in
# the side-panel spec list. Examples (snippets verified by web
# search 2026-05):
#   /en/support/downloads/drivers.html/processors/.../amd-ryzen-7-pro-5750ge.html
#       -> "Former Codename · Cezanne"
#   /en/support/downloads/drivers.html/processors/.../amd-ryzen-7-pro-4750ge.html
#       -> "Former Codename · Renoir"
#
# Returns the raw codename string (e.g., "Cezanne") or $null on any
# failure (network error, page format mismatch, robots-style block,
# etc.). Caller is expected to fall back to heuristic detection on
# null.
# ====================================================================
function Get-AmdCodenameFromUrl {
    [CmdletBinding()]
    [OutputType([string])]
    param([Parameter(Mandatory)] [string]$Url)
    $browserUA = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0 Safari/537.36'
    try {
        $resp = Invoke-WebRequest -Uri $Url -UseBasicParsing -TimeoutSec 30 -UserAgent $browserUA -ErrorAction Stop
    } catch {
        return $null
    }
    if (-not $resp -or -not $resp.Content) { return $null }

    # AMD's product pages use a key/value spec list rendered as
    # adjacent <div>s or list items. The HTML pattern varies a bit
    # between page types but the literal text "Former Codename" is
    # consistent. We look for the label, then take the next short
    # alphanumeric token as the value, allowing hyphens and spaces.
    #
    # Patterns tried, in order:
    #   1. Label and value separated by whitespace/HTML tags only
    #   2. Label inside one element, value in the next
    #   3. Bullet "·" separator (used in some AMD page templates)
    $patterns = @(
        '(?is)Former\s*Codename[\s\S]{0,400}?>\s*([A-Za-z][A-Za-z0-9\- ]{1,40}?)\s*<'
        '(?is)Former\s*Codename[^A-Za-z]{1,30}([A-Za-z][A-Za-z0-9\- ]{1,40}?)(?:\s*<|\s*\u00b7|\s*\.)'
        '(?is)Former\s+Codename\s*[\u00b7\:\|]\s*([A-Za-z][A-Za-z0-9\- ]{1,40})'
    )
    foreach ($pat in $patterns) {
        $m = [regex]::Match($resp.Content, $pat)
        if ($m.Success) {
            $raw = $m.Groups[1].Value.Trim()
            # Filter out captured HTML attribute fragments
            if ($raw -notmatch '^\s*$' -and $raw -notmatch 'class=|style=|http') {
                return $raw
            }
        }
    }
    return $null
}

# ====================================================================
# Get-AmdDriverBranchPreference
# --------------------------------------------------------------------
# Decide which AMD driver branch is appropriate for the detected GPU.
#
# AMD has SPLIT the Adrenalin Edition driver into two parallel branches
# since around Adrenalin 23.11.1 (Nov 2023):
#
#   [Main / RDNA branch]
#     - Filename: whql-amd-software-adrenalin-edition-X.Y.Z-...
#                 (NO 'vega-polaris' or 'polaris-vega' in the name)
#     - Supports: RX 5000 (RDNA 1) / 6000 (RDNA 2) / 7000 (RDNA 3) /
#                 9000 (RDNA 4) discrete GPUs, plus APUs with
#                 RDNA 2/3 graphics (Rembrandt 6000, Phoenix 7040,
#                 Hawk Point 8040, Strix Point Ryzen AI 300,...).
#
#   [Legacy / Vega-Polaris branch]
#     - Filename:...vega-polaris*.exe
#     - Supports: GCN/Polaris RX 400/500, Vega 56/64, Radeon VII,
#                 and ALL APUs with Vega graphics (Raven Ridge,
#                 Picasso, Renoir, Lucienne, Cezanne, Barcelo,
#                 Barcelo-R rebrand into Ryzen 7x30).
#
# Decision priority (highest confidence first):
#   1. Codename lookup via $Script:AmdCodenameMap. If a codename is
#      provided (typically extracted from AMD's product page via
#      Get-AmdCodenameFromUrl), match against the table and return
#      the precise mapping. This is the AUTHORITATIVE path because
#      the codename comes directly from AMD's own product spec.
#   2. Specific name-pattern traps (Ryzen 7x30 Barcelo-R, Athlon
#      Vega 200/240GE, Embedded V1*/R1*, Ryzen AI Max).
#   3. Series-number heuristic (Ryzen 1000-5000 -> Vega -> Legacy;
#      Ryzen 6000+ -> RDNA -> Main).
#   4. Discrete GPU name patterns (RX 4xx/5xx Polaris, RX 5xxx-9xxx
#      RDNA, Vega 56/64/Frontier, Radeon VII,...).
#   5. Default fallback.
#
# Returns a pscustomobject with:
#   Branch - 'Legacy' / 'Main' / 'Either'
#   Codename - matched codename (e.g. 'Cezanne', 'Phoenix'), or
#                  best-guess label, or $null
#   Architecture - human-readable arch label, or $null
#   Confidence - 'High' (codename match), 'Medium' (heuristic),
#                  'Low' (default), 'None' (no target)
#   Source - 'amd.com page' / 'name pattern' / 'series number'
#                  / 'default'
#   Reason - human-readable explanation
# ====================================================================
function Get-AmdDriverBranchPreference {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [pscustomobject]$GpuTarget,
        [string]$Codename
    )

    if (-not $GpuTarget) {
        return [pscustomobject]@{
            Branch='Either'; Codename=$null; Architecture=$null
            Confidence='None'; Source='none'; Reason='no GPU target was detected'
        }
    }
    $name   = $GpuTarget.FullName
    $series = Get-AmdProductSeriesNumber -Name $name

    # === Step 1: Codename lookup (AMD-authoritative when available) ===
    if ($Codename) {
        $key = Get-AmdCodenameNormalizedKey -Codename $Codename
        if ($Script:AmdCodenameMap.ContainsKey($key)) {
            $info = $Script:AmdCodenameMap[$key]
            return [pscustomobject]@{
                Branch=$info.Branch; Codename=$Codename
                Architecture=$info.Arch; Confidence='High'
                Source='amd.com page'
                Reason="codename '$Codename' (GC $($info.GC)) maps to $($info.Branch) branch via AMD codename table"
            }
        }
        # Codename returned by AMD but unknown to our table -> log
        # the codename for future map updates but fall through to
        # heuristic for the actual decision.
    }

    if ($GpuTarget.Type -eq 'APU') {
        # === Step 2: Specific name-pattern traps ===

        # Ryzen 7x30 (Barcelo-R) Vega rebrand trap
        if ($name -match '\bRyzen\s+(?:\d+\s+)?(?:PRO\s+)?7\d30\w*\b') {
            return [pscustomobject]@{
                Branch='Legacy'; Codename='Barcelo-R'
                Architecture='Vega (GC 9.3)'; Confidence='High'
                Source='name pattern'
                Reason='Ryzen 7x30 series is a Vega rebrand from Cezanne/Barcelo (model-number trap)'
            }
        }
        # Athlon Vega APUs (3-digit model number missed by series detector)
        if ($name -match '\bAthlon\s+(?:Silver\s+|Gold\s+)?(?:200|220|240|300|3000)\w*\b') {
            return [pscustomobject]@{
                Branch='Legacy'; Codename='Raven Ridge / Picasso (Athlon)'
                Architecture='Vega (GC 9.1.x)'; Confidence='High'
                Source='name pattern'; Reason='Athlon Vega APU'
            }
        }
        # Ryzen Embedded V1*/R1* (Raven Ridge)
        if ($name -match '\bRyzen\s+Embedded\s+[VR]\d') {
            return [pscustomobject]@{
                Branch='Legacy'; Codename='Raven Ridge Embedded'
                Architecture='Vega (GC 9.1.0)'; Confidence='High'
                Source='name pattern'; Reason='Embedded Ryzen V1*/R1* uses Vega graphics'
            }
        }
        # Ryzen AI series (3-digit model number missed by series detector)
        if ($name -match '\bRyzen\s+AI\b') {
            $codeName = if ($name -match '\bRyzen\s+AI\s+Max') { 'Strix Halo' }
                        else { 'Strix / Krackan / Gorgon Point' }
            return [pscustomobject]@{
                Branch='Main'; Codename=$codeName
                Architecture='RDNA 3.5 (GC 11.5.x)'; Confidence='High'
                Source='name pattern'; Reason='Ryzen AI series uses RDNA 3.5 graphics'
            }
        }

        # === Step 3: Series-number heuristic ===
        if ($series) {
            if ($series -le 5000) {
                $codename = switch ($series) {
                    1000 { 'Bristol Ridge' }
                    2000 { 'Raven Ridge' }
                    3000 { 'Picasso' }
                    4000 { 'Renoir' }
                    5000 { 'Cezanne / Lucienne / Barcelo' }
                    default { 'Vega-era APU' }
                }
                return [pscustomobject]@{
                    Branch='Legacy'; Codename=$codename
                    Architecture='Vega'; Confidence='Medium'
                    Source='series number'
                    Reason="Ryzen $($series)-series APU is Vega-class (series-number heuristic)"
                }
            }
            $codename = switch ($series) {
                6000 { 'Rembrandt (RDNA 2)' }
                7000 { 'Phoenix / Mendocino / Rembrandt-R / Raphael (varies by suffix)' }
                8000 { 'Hawk Point (RDNA 3)' }
                9000 { 'Granite Ridge (RDNA 2 iGPU)' }
                default { 'RDNA-era APU' }
            }
            return [pscustomobject]@{
                Branch='Main'; Codename=$codename
                Architecture='RDNA 2 / 3'; Confidence='Medium'
                Source='series number'
                Reason="Ryzen $($series)-series APU uses RDNA-class graphics (series-number heuristic)"
            }
        }
        # APU with unrecognized name -> Main as safer default for unknown modern names
        return [pscustomobject]@{
            Branch='Main'; Codename=$null; Architecture=$null
            Confidence='Low'; Source='default'
            Reason='APU detected but model not recognized; assuming RDNA-class'
        }
    }

    if ($GpuTarget.Type -eq 'DGPU') {
        # === Step 4: dGPU name-pattern matching ===
        if ($name -match '\bRX\s+[45]\d{2}\b' -and $name -notmatch '\bRX\s+[45]\d{3}\b') {
            return [pscustomobject]@{
                Branch='Legacy'; Codename='POLARIS10/11/12'
                Architecture='GCN 4 / Polaris (GC 8)'; Confidence='High'
                Source='name pattern'; Reason='Polaris RX 4xx/5xx (3-digit model number)'
            }
        }
        if ($name -match 'Vega\s+(?:56|64|Frontier|FE)\b') {
            return [pscustomobject]@{
                Branch='Legacy'; Codename='VEGA10'
                Architecture='Vega (GC 9.0.1)'; Confidence='High'
                Source='name pattern'; Reason='Vega 56/64/Frontier discrete GPU'
            }
        }
        if ($name -match '\bRadeon\s+VII\b' -or $name -match '\bRadeon\s+Pro\s+VII\b') {
            return [pscustomobject]@{
                Branch='Legacy'; Codename='VEGA20'
                Architecture='Vega (GC 9.4.0)'; Confidence='High'
                Source='name pattern'; Reason='Radeon VII / Pro VII (7nm Vega refresh)'
            }
        }
        if ($name -match '\bRadeon\s+(?:HD\s+)?(?:7\d{3}|8\d{3})\b' -or
            $name -match '\bRadeon\s+R[579]\s+(?:200|300|Fury)\b' -or
            $name -match '\b(?:HD|R7|R9)\s+M(?:\d{3})\b') {
            return [pscustomobject]@{
                Branch='Legacy'; Codename='Tahiti / Bonaire / Hawaii / Tonga / Fiji'
                Architecture='GCN 1-3 (pre-Polaris, may be EOL)'
                Confidence='Medium'; Source='name pattern'
                Reason='Pre-Polaris GCN dGPU; current legacy branch may have limited support'
            }
        }
        if ($name -match '\bRX\s+5[3-7]\d{2}\b' -or $name -match '\bW5\d{3}\b') {
            return [pscustomobject]@{
                Branch='Main'; Codename='Navi 10 / Navi 14'
                Architecture='RDNA 1 (GC 10.1.x)'; Confidence='High'
                Source='name pattern'; Reason='RX 5000 / W5000 series (Navi 1x, RDNA 1)'
            }
        }
        if ($name -match '\bRX\s+6\d{3}\b' -or $name -match '\bW6\d{3}\b') {
            return [pscustomobject]@{
                Branch='Main'
                Codename='Sienna Cichlid / Navy Flounder / Dimgrey Cavefish / Beige Goby'
                Architecture='RDNA 2 (GC 10.3.x)'; Confidence='High'
                Source='name pattern'; Reason='RX 6000 / W6000 series (Navi 2x, RDNA 2)'
            }
        }
        if ($name -match '\bRX\s+7\d{3}\b' -or $name -match '\bW7\d{3}\b') {
            return [pscustomobject]@{
                Branch='Main'; Codename='Navi 31 / Navi 32 / Navi 33'
                Architecture='RDNA 3 (GC 11.0.x)'; Confidence='High'
                Source='name pattern'; Reason='RX 7000 / W7000 series (Navi 3x, RDNA 3)'
            }
        }
        if ($name -match '\bRX\s+9\d{3}\b' -or $name -match '\bR9\d{3}\b') {
            return [pscustomobject]@{
                Branch='Main'; Codename='Navi 4x'
                Architecture='RDNA 4 (GC 12.0.x)'; Confidence='High'
                Source='name pattern'; Reason='RX/R 9000 series (Navi 4x, RDNA 4)'
            }
        }
        if ($name -match '\bW[5-9]\d{3}\b') {
            return [pscustomobject]@{
                Branch='Main'; Codename='Pro RDNA workstation'
                Architecture='RDNA 1 / 2 / 3'; Confidence='Medium'
                Source='name pattern'; Reason='Radeon Pro Wxxxx (workstation RDNA)'
            }
        }
        return [pscustomobject]@{
            Branch='Main'; Codename=$null; Architecture=$null
            Confidence='Low'; Source='default'
            Reason='discrete GPU detected but model not recognized; assuming RDNA-class'
        }
    }

    return [pscustomobject]@{
        Branch='Either'; Codename=$null; Architecture=$null
        Confidence='None'; Source='none'; Reason='unknown target type'
    }
}

# ====================================================================
# Get-AmdProductPageUrl
# --------------------------------------------------------------------
# Build the AMD support download page URL for a given product name.
#
# URL conventions (from user-provided examples):
#   Ryzen Pro APU:
#     /processors/ryzen-pro/ryzen-pro-{N}000-series/{slug}.html
#   Ryzen consumer APU:
#     /processors/ryzen/ryzen-{N}000-series/{slug}.html
#   Radeon RX consumer dGPU:
#     /graphics/radeon-rx/radeon-rx-{N}000-series/{slug}.html
#   Radeon AI Pro dGPU:
#     /graphics/radeon-ai-pro/radeon-ai-pro-r{N}000-series/{slug}.html
#   Radeon Pro workstation dGPU:
#     /graphics/radeon-pro/radeon-pro-w{N}000-series/{slug}.html
#
# Returns $null if no pattern matched (caller should fall back).
# ====================================================================
function Get-AmdProductPageUrl {
    [CmdletBinding()]
    [OutputType([string])]
    param([Parameter(Mandatory)] [string]$ProductName)
    $slug   = Convert-AmdProductNameToSlug -Name $ProductName
    $series = Get-AmdProductSeriesNumber  -Name $ProductName
    if (-not $series) { return $null }

    $base = 'https://www.amd.com/ja/support/downloads/drivers.html'

    if ($ProductName -match 'Radeon\s+AI\s+Pro') {
        $seriesPath = 'radeon-ai-pro-r{0}-series' -f $series
        return "$base/graphics/radeon-ai-pro/$seriesPath/$slug.html"
    }
    if ($ProductName -match 'Radeon\s+Pro\b') {
        $seriesPath = 'radeon-pro-w{0}-series' -f $series
        return "$base/graphics/radeon-pro/$seriesPath/$slug.html"
    }
    if ($ProductName -match 'Radeon\s+RX') {
        $seriesPath = 'radeon-rx-{0}-series' -f $series
        return "$base/graphics/radeon-rx/$seriesPath/$slug.html"
    }
    if ($ProductName -match '\bRyzen\b.*\bPRO\b') {
        $seriesPath = 'ryzen-pro-{0}-series' -f $series
        return "$base/processors/ryzen-pro/$seriesPath/$slug.html"
    }
    if ($ProductName -match '\bRyzen\b') {
        $seriesPath = 'ryzen-{0}-series' -f $series
        return "$base/processors/ryzen/$seriesPath/$slug.html"
    }
    return $null
}

# ====================================================================
# Get-AmdGraphicsLandingUrls
# --------------------------------------------------------------------
# Build the ordered list of AMD support pages this script will probe
# in P03. The result is:
#   1. The GPU/APU-derived product page (if detection succeeded)
#   2. The user-supplied -AmdLandingUrls (5 default product pages
#      covering the 4 major AMD graphics product lines)
#
# This function emits diagnostic Write-Host lines describing the
# detection result so the operator sees how the URL list was built.
# ====================================================================
function Get-AmdGraphicsLandingUrls { # psa-disable-line PSA6003 -- compound noun (e.g., Policies, Drivers, Catalogs) is semantically plural for set-returning helpers
    # Returns a pscustomobject with two fields:
    #   LandingUrls: the list of AMD support page URLs to probe (the
    #                 GPU/APU-derived URL is prepended when detection
    #                 succeeds)
    #   Target: the detected Get-AmdGpuTarget result (or $null)
    # Returning the Target alongside the URLs lets the P03 caller pass
    # it to Get-AmdDriverBranchPreference WITHOUT re-running detection
    # (and re-printing the detection log lines).
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param([Parameter(Mandatory)] [string[]]$DefaultUrls)

    $detected = Get-AmdGpuTarget
    if ($null -eq $detected) {
        Write-Host '    GPU detection: no AMD GPU/APU detected on this host' -ForegroundColor Yellow
        Write-Host '                   -> using -AmdLandingUrls defaults only'           -ForegroundColor DarkGray
        return [pscustomobject]@{ LandingUrls = $DefaultUrls; Target = $null }
    }
    $derivedUrl = Get-AmdProductPageUrl -ProductName $detected.FullName
    if ($null -eq $derivedUrl) {
        Write-Host ('    GPU detection: {0} ({1})' -f $detected.FullName, $detected.Type) -ForegroundColor Cyan
        Write-Host '                   -> name pattern not recognized; using -AmdLandingUrls defaults' -ForegroundColor Yellow
        return [pscustomobject]@{ LandingUrls = $DefaultUrls; Target = $detected }
    }
    Write-Host ('    GPU detection: {0} ({1})' -f $detected.FullName, $detected.Type)    -ForegroundColor Green
    Write-Host ('                   Source: {0}' -f $detected.Source)                    -ForegroundColor DarkGray
    Write-Host ('                   Derived AMD product URL: {0}' -f $derivedUrl)        -ForegroundColor Green
    # Prepend the derived URL; keep defaults as fallback. De-duplicate
    # in case the same URL already appears in the defaults.
    $combined = @($derivedUrl) + @($DefaultUrls | Where-Object { $_ -ne $derivedUrl })
    return [pscustomobject]@{ LandingUrls = $combined; Target = $detected }
}

function Get-LatestAmdGraphicsUrl {
    # ====================================================================
    # Resolve the latest AMD graphics-driver installer URL by probing
    # AMD support pages.
    #
    # Differences from the chipset version:
    #   - Pattern is broadened to match graphics-installer naming
    #     (whql-amd-software-..., amd-software-pro-edition-...,
    #     embedded-radeon-software-...). Any.exe under
    #     drivers.amd.com/drivers that contains 'amd' and 'software'
    #     in its filename is accepted.
    #   - The "version" parsed from the URL is opportunistic - graphics
    #     installer filenames sometimes encode a YY.M.M version (e.g.
    #     25.10.1) while chipset uses N.N.N.N. The function returns the
    #     raw matched substring as VersionString without forcing a
    #     particular numeric shape.
    #   - BranchPreference (Legacy/Main/Either) filters URLs BEFORE the
    #     version-sort. AMD's separate vega-polaris branch trails the
    #     main branch in version, so picking 'highest version' across
    #     branches gives the wrong driver for Vega-generation hardware.
    # ====================================================================
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)] [string[]]$LandingUrls,
        [Parameter(Mandatory)] [string]$FallbackUrl,
        [ValidateSet('Legacy','Main','Either')]
        [string]$BranchPreference = 'Either'
    )
    $browserUA = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0 Safari/537.36'
    # Match any AMD driver.exe under drivers.amd.com/drivers whose
    # filename suggests it's an AMD Software / Adrenalin / Pro / Radeon
    # graphics installer. Version extraction is done as a SEPARATE step
    # below (extracting it inline made the optional capture group
    # unreliable - the lazy quantifier swallowed the version digits).
    $pattern        = 'https://drivers\.amd\.com/drivers/[\w\-\.]*(?:adrenalin|software|radeon)[\w\-\.]*\.exe'
    # Version pattern: 2-4 numeric components separated by dots, anchored
    # by [-_] before and a word boundary (\b) after so we accept versions
    # whether they're followed by another segment or end the meaningful
    # part of the filename (e.g....-26.1.1-win11... or..._8.02.18.557.exe).
    $verPattern     = '[-_](\d+\.\d+(?:\.\d+){0,2})\b'
    # Identifies the AMD legacy "Vega/Polaris" branch in a URL filename.
    # AMD has used both spellings ('vega-polaris' since ~Adrenalin 23.11
    # and 'polaris-vega' historically); accept either ordering.
    $legacyMarker   = '(?i)(vega[-_]?polaris|polaris[-_]?vega)'
    $perPage        = @()
    $allHits        = @()

    foreach ($url in $LandingUrls) {
        $short = ($url -replace 'https://www\.amd\.com/[^/]+/support/downloads/drivers\.html','').TrimStart('/')
        try {
            $resp = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 60 -UserAgent $browserUA
            $hits = [regex]::Matches($resp.Content, $pattern)
            $perPage += [pscustomobject]@{ Page=$short; Found=$hits.Count }
            foreach ($m in $hits) {
                # Extract version from the matched URL itself, not from
                # the original regex (which deliberately avoids capture
                # groups for robustness).
                $verMatch = [regex]::Match($m.Value, $verPattern)
                $verStr   = if ($verMatch.Success) { $verMatch.Groups[1].Value } else { '0' }
                # Sort key padded to handle 4-part or YY.MM.PP version strings.
                $parts  = ($verStr.Split('.') + @('0','0','0','0'))[0..3] | ForEach-Object { try { [int]$_ } catch { 0 } }
                $isLegacy = $m.Value -match $legacyMarker # psa-disable-line PSA2003 -- pattern variable is initialized in the enclosing scope; $null impossible by construction
                $allHits += [pscustomobject]@{
                    Url=$m.Value; VersionString=$verStr; Page=$short
                    SortKey = '{0:D5}{1:D5}{2:D5}{3:D5}' -f $parts[0],$parts[1],$parts[2],$parts[3]
                    IsLegacy = $isLegacy
                }
            }
        } catch {
            $perPage += [pscustomobject]@{ Page=$short; Found=0; Note=$_.Exception.Message }
            Write-Warn2 "  Page failed ($short): $($_.Exception.Message)"
        }
    }

    Write-Host '    Probe results:' -ForegroundColor DarkGray
    foreach ($s in $perPage) {
        Write-Detail ("  [{0,-50}] hits={1}" -f $s.Page, $s.Found) -Color DarkGray
    }

    if ($allHits.Count -gt 0) {
        $unique = @($allHits | Group-Object Url | ForEach-Object { $_.Group | Select-Object -First 1 })
        $totalUnique = $unique.Count
        $legacyCount = @($unique | Where-Object { $_.IsLegacy }).Count
        $mainCount   = $totalUnique - $legacyCount
        Write-Detail ("Branch inventory: {0} legacy (vega-polaris) / {1} main / {2} total unique" -f `
            $legacyCount, $mainCount, $totalUnique) -Color DarkGray
        Write-Detail ("Branch preference (from GPU detection): {0}" -f $BranchPreference) -Color DarkGray

        # Apply branch preference. If the preferred branch yields no
        # hits, fall back to the other branch with a clear warning.
        $branchUsed = $BranchPreference
        $filtered   = $unique
        if ($BranchPreference -eq 'Legacy') {
            $f = @($unique | Where-Object { $_.IsLegacy })
            if ($f.Count -gt 0) {
                $filtered = $f
            } else {
                Write-Warn2 'Branch preference is Legacy but no vega-polaris URL was found on any landing page.'
                Write-Warn2 'Falling back to MAIN branch - this driver almost certainly will NOT bind to your Vega-era GPU.'
                Write-Warn2 'Consider supplying -InstallerUrl with a manually-located Vega/Polaris legacy installer URL.'
                $branchUsed = 'Main (fallback)'
            }
        } elseif ($BranchPreference -eq 'Main') {
            $f = @($unique | Where-Object { -not $_.IsLegacy })
            if ($f.Count -gt 0) {
                $filtered = $f
            } else {
                Write-Warn2 'Branch preference is Main but only legacy vega-polaris URLs were found.'
                $branchUsed = 'Legacy (fallback)'
            }
        }

        $best = $filtered | Sort-Object SortKey -Descending | Select-Object -First 1
        return [pscustomobject]@{
            Version=$best.VersionString; Url=$best.Url
            Source="AMD support pages (parsed: $totalUnique unique URL across $($perPage.Count) page(s); branch=$branchUsed)"
            SourcePage=$best.Page
            BranchUsed=$branchUsed
            IsLegacy=[bool]$best.IsLegacy
        }
    }
    Write-Warn2 'No landing page yielded a parseable URL - falling back.'
    return [pscustomobject]@{
        Version = 'unknown (pinned)'
        Url     = $FallbackUrl
        Source  = 'pinned fallback'
        SourcePage = $null
        BranchUsed = 'Unknown'
        IsLegacy = $false
    }
}

function Expand-AmdInstaller {
    # Multi-strategy AMD chipset installer extraction.
    #
    # Two strategies, in order of preference:
    #   Strategy 1: 7-Zip auto-detect
    #               Works for old (6.x and earlier) self-extracting EXEs.
    #               Free, fast, no side effects. Fails cleanly on modern
    #               (8.x+) AMD bootstrappers.
    #   Strategy 2: launch installer with /S, watch C:\AMD\ for the
    #               extraction directory, terminate before install runs.
    #               This is the only reliable path for AMD's modern
    #               proprietary bootstrapper (8.x+).
    #
    # Removed strategies (and why):
    #   - Bootstrapper extract switches (/layout, /extract:, -extract,
    #     --extract): the AMD 8.x bootstrapper is not WIX BURN and does
    #     not honor any of these. Every variant returns exit 2. Removed
    #     to save ~5 minutes of wasted attempts on modern installers.
    #   - "Reuse pre-existing extraction" cache: removed for clarity;
    #     run-to-run state should not implicitly leak between runs.
    param(
        [Parameter(Mandatory)] [string]$InstallerPath,
        [Parameter(Mandatory)] [string]$DestinationPath,
        [Parameter(Mandatory)] [string]$SevenZipPath
    )

    function _HasPayload {
        param([string]$Path)
        # Strategy success criterion: we need INF files (drivers) or
        # MSI / CAB files (which the nested-archive pass below will
        # unpack to yield INFs). EXE / DLL alone are NOT sufficient -
        # 7-Zip's PE handler can extract resource-section EXEs and
        # satellite DLLs from a WIX BURN wrapper while completely
        # missing the BURN-encoded MSI payload. Counting EXE/DLL as
        # success would let Strategy 1 silently mask the problem.
        $items = @(Get-ChildItem -Path $Path -Recurse `
            -Include '*.inf','*.msi','*.cab' `
            -ErrorAction SilentlyContinue)
        return ($items.Count -gt 0)
    }
    function _ClearDest {
        Get-ChildItem -Path $DestinationPath -Force -ErrorAction SilentlyContinue |
            Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
    }

    # ---------- Strategy 1/2: 7-Zip auto-detect ----------
    Write-Detail "Strategy 1/2: 7-Zip auto-detect" -Color DarkGray
    & $SevenZipPath x $InstallerPath "-o$DestinationPath" -y -bsp0 -bso0 2>$null | Out-Null
    $exit1 = $LASTEXITCODE
    if ($exit1 -eq 0 -and (_HasPayload $DestinationPath)) {
        Write-Ok "    Extracted with 7-Zip auto-detect"
        return
    }
    _ClearDest
    Write-Warn2 "    7-Zip auto-detect produced no usable payload (exit $exit1) - trying next strategy"

    # ---------- Strategy 2/2: launch + watch ----------
    Write-Detail "Strategy 2/2: launch installer and harvest from C:\AMD\" -Color DarkGray
    Expand-AmdInstaller_ViaLaunch -InstallerPath $InstallerPath -DestinationPath $DestinationPath
    if (-not (_HasPayload $DestinationPath)) {
        throw "Both extraction strategies failed for $InstallerPath. The installer format may be unsupported by this script. As a workaround, manually extract the installer payload to $DestinationPath (or to C:\AMD\<anything>) and re-run with -OnlyPhases P05+."
    }
}

function Test-RobocopyResult {
    # Verify that a robocopy (or any other file-copy operation)
    # produced a destination tree identical to the source tree. Used to
    # catch silent partial-copy bugs that previously went undetected
    # (e.g. the PowerShell Copy-Item wildcard quirk fixed).
    #
    # Verification levels applied:
    #   L1: Total file count and total directory count must match
    #   L2: Relative-path set of all files must match (no missing files,
    #       no unexpected extras)
    # Size / hash level verification is intentionally NOT performed:
    # robocopy /COPY:DAT preserves attributes/timestamps and the L1+L2
    # check is sufficient signal for our use case. A 1-2 second overhead
    # against a thousand-file tree on SSD is acceptable.
    #
    # Returns a result object; does NOT throw. The caller decides how to
    # react (throw / warn / retry) based on.Success.
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)] [string]$SourcePath,
        [Parameter(Mandatory)] [string]$DestinationPath
    )

    # Recursive enumeration of both trees. -Force includes hidden /
    # system entries (not expected in the AMD installer payload, but
    # defensive: a missed hidden file would still be a silent failure).
    $srcFiles = @(Get-ChildItem -LiteralPath $SourcePath      -Recurse -File      -Force -ErrorAction SilentlyContinue)
    $srcDirs  = @(Get-ChildItem -LiteralPath $SourcePath      -Recurse -Directory -Force -ErrorAction SilentlyContinue)
    $dstFiles = @(Get-ChildItem -LiteralPath $DestinationPath -Recurse -File      -Force -ErrorAction SilentlyContinue)
    $dstDirs  = @(Get-ChildItem -LiteralPath $DestinationPath -Recurse -Directory -Force -ErrorAction SilentlyContinue)

    # ----- L1: count check -----
    $countMatch = ($srcFiles.Count -eq $dstFiles.Count) -and ($srcDirs.Count -eq $dstDirs.Count)

    # ----- L2: relative-path set check -----
    # Strip the source / destination root prefix to produce comparable
    # relative paths, then use a HashSet for O(n) lookup. Where-Object
    # -notin against a large array would be O(n^2) and noticeably slow
    # for the graphics installer tree (~10k files in some packages).
    $srcLen = $SourcePath.TrimEnd('\').Length
    $dstLen = $DestinationPath.TrimEnd('\').Length
    $srcRel = $srcFiles | ForEach-Object { $_.FullName.Substring($srcLen).TrimStart('\') }
    $dstRel = $dstFiles | ForEach-Object { $_.FullName.Substring($dstLen).TrimStart('\') }

    # Case-insensitive comparison: NTFS is normally case-insensitive,
    # and the AMD installer paths are mixed-case but stable. Treating
    # 'PACKAGES\IODriver' the same as 'Packages\IODriver' is correct.
    $dstRelSet = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::OrdinalIgnoreCase)
    foreach ($p in $dstRel) { [void]$dstRelSet.Add($p) }
    $srcRelSet = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::OrdinalIgnoreCase)
    foreach ($p in $srcRel) { [void]$srcRelSet.Add($p) }

    $missing = @($srcRel | Where-Object { -not $dstRelSet.Contains($_) })  # in src, not in dst
    $extra   = @($dstRel | Where-Object { -not $srcRelSet.Contains($_) })  # in dst, not in src
    $pathsMatch = ($missing.Count -eq 0) -and ($extra.Count -eq 0)

    return [pscustomobject]@{
        SourcePath      = $SourcePath
        DestinationPath = $DestinationPath
        SrcFileCount    = $srcFiles.Count
        DstFileCount    = $dstFiles.Count
        SrcDirCount     = $srcDirs.Count
        DstDirCount     = $dstDirs.Count
        SrcInfCount     = @($srcFiles | Where-Object Extension -eq '.inf').Count
        DstInfCount     = @($dstFiles | Where-Object Extension -eq '.inf').Count
        CountMatch      = $countMatch
        PathsMatch      = $pathsMatch
        Success         = $countMatch -and $pathsMatch
        MissingFiles    = $missing
        ExtraFiles      = $extra
    }
}

function Expand-AmdInstaller_ViaLaunch {
    # Launches the AMD installer with /S, watches C:\AMD\ for the
    # extraction directory, waits for the file set to settle, then
    # terminates the installer process before the actual driver
    # installation step proceeds.
    #
    # Detection logic:
    #   We look for any subdirectory of C:\AMD\ whose own LastWriteTime
    #   is greater than the launch time AND that contains INF files.
    #   IMPORTANT: we check the DIRECTORY mtime, NOT the INF file mtimes.
    #   AMD's installer copies INF files preserving their original
    #   timestamps from the build, so INF LastWriteTimes are stale
    #   even immediately after extraction. The directory mtime, on the
    #   other hand, is updated by the filesystem when the installer
    #   creates or rewrites the directory.
    param([string]$InstallerPath, [string]$DestinationPath)

    $amdRoot = 'C:\AMD'

    # ---- Pre-launch state dump ----
    Write-Detail "Pre-launch state of ${amdRoot}:" -Color DarkGray
    if (Test-Path $amdRoot) {
        $existing = @(Get-ChildItem $amdRoot -Directory -ErrorAction SilentlyContinue)
        if ($existing.Count -eq 0) {
            Write-Detail "  (empty)" -Color DarkGray
        } else {
            foreach ($d in $existing) {
                Write-Detail ("  [{0,-30}] mtime={1:yyyy-MM-dd HH:mm:ss}" -f $d.Name, $d.LastWriteTime) -Color DarkGray
            }
        }
    } else {
        Write-Detail "  ($amdRoot does not exist yet - will be created by installer)" -Color DarkGray
    }

    # ---- Pre-clean known residual AMD subdirs ----
    # The previous implementation tried to diff the dir set "before vs
    # after" launch, which broke when an earlier run had left AMD
    # extraction artefacts behind. We now just delete known names
    # outright so the launch starts clean.
    $knownAmdSubdirs = @(
        'Chipset_Software_Backup',
        'Chipset_Software',
        'Chipset',
        'Chipset Software'
    )
    $toDelete = @()
    if (Test-Path $amdRoot) {
        foreach ($sd in $knownAmdSubdirs) {
            $p = Join-Path $amdRoot $sd
            if (Test-Path $p) { $toDelete += $p }
        }
    }

    if ($toDelete.Count -gt 0) {
        Write-Host ''
        Write-Detail "Pre-cleanup: $($toDelete.Count) known AMD dir(s) will be DELETED:" -Color DarkGray
        foreach ($p in $toDelete) {
            Write-Detail "  [DELETE] $p" -Color Yellow
            try {
                Remove-Item -LiteralPath $p -Recurse -Force -ErrorAction Stop
                Write-Detail "  [  OK  ] deleted" -Color DarkGray
            } catch {
                Write-Warn2 "      [ FAIL ] $($_.Exception.Message)"
            }
        }
    } else {
        Write-Host ''
        Write-Detail "Pre-cleanup: no known AMD dirs to delete" -Color DarkGray
    }

    # ---- Show what remains (preserved) ----
    if (Test-Path $amdRoot) {
        $preserved = @(Get-ChildItem $amdRoot -Directory -ErrorAction SilentlyContinue)
        if ($preserved.Count -gt 0) {
            Write-Detail "Preserved (not in known-clean list):" -Color DarkGray
            foreach ($p in $preserved) {
                Write-Detail "  [ KEEP ] $($p.FullName)" -Color DarkGray
            }
        }
    }

    # Record launch time. We treat any DIRECTORY whose LastWriteTime is
    # greater than this as "fresh" (i.e. created or rewritten by the
    # launch we are about to do). Subtract a small grace period to
    # allow for minor clock skew and filesystem timestamp granularity.
    $launchStart = (Get-Date).AddSeconds(-2)

    Write-Host ''
    Write-Detail "Launching installer (silent /S) at $($launchStart.AddSeconds(2).ToString('HH:mm:ss'))" -Color DarkGray

    # /S = silent. The AMD installer extracts to C:\AMD\... and then
    # tries to install. We kill before the install step modifies state.
    $proc = Start-Process -FilePath $InstallerPath `
        -ArgumentList @('/S') `
        -PassThru -WindowStyle Minimized
    if (-not $proc) { throw 'Could not launch AMD installer for self-extraction.' }

    $maxWaitSec = 180
    Write-Detail "Watching $amdRoot for fresh extraction directory (timeout ${maxWaitSec}s)..." -Color DarkGray
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $newDir = $null
    $lastInfCount = 0
    $stableTicks = 0

    while ($sw.Elapsed.TotalSeconds -lt $maxWaitSec -and -not $newDir) {
        Start-Sleep -Seconds 3
        if (-not (Test-Path $amdRoot)) { continue }

        # Find subdirs whose own mtime > launchStart AND that contain
        # at least one INF. We check directory mtime (which changes
        # when AMD writes the dir) instead of INF mtime (which is
        # preserved from the original AMD build and therefore stale).
        $candidates = @(Get-ChildItem $amdRoot -Directory -ErrorAction SilentlyContinue |
            Where-Object { $_.LastWriteTime -gt $launchStart })

        $best = $null
        $bestInfCount = 0
        foreach ($c in $candidates) {
            $infCount = @(Get-ChildItem -Path $c.FullName -Recurse -Filter *.inf -File -ErrorAction SilentlyContinue).Count
            if ($infCount -gt $bestInfCount) {
                $best = $c
                $bestInfCount = $infCount
            }
        }

        if ($bestInfCount -eq 0) { continue }

        # Track stability: if INF count stops growing for 6 seconds
        # (2 ticks of 3s each), the installer is done extracting.
        if ($bestInfCount -eq $lastInfCount) {
            $stableTicks++
        } else {
            $stableTicks = 0
            Write-Detail "  growing: $($best.Name) -> $bestInfCount INFs" -Color DarkGray
        }
        $lastInfCount = $bestInfCount

        if ($stableTicks -ge 2) {
            $newDir = $best
        }
    }

    # ---- Diagnostic dump on timeout ----
    if (-not $newDir) {
        Write-Host ''
        Write-Warn2 "    Diagnostic dump of $amdRoot at timeout (launchStart=$($launchStart.ToString('HH:mm:ss'))):"
        if (Test-Path $amdRoot) {
            $dirs = @(Get-ChildItem $amdRoot -Directory -ErrorAction SilentlyContinue)
            if ($dirs.Count -eq 0) {
                Write-Detail "  (no directories under $amdRoot)" -Color DarkGray
            } else {
                foreach ($d in $dirs) {
                    $isFresh = ($d.LastWriteTime -gt $launchStart)
                    $infCount = @(Get-ChildItem $d.FullName -Recurse -Filter *.inf -File -ErrorAction SilentlyContinue).Count
                    $marker = if ($isFresh) { '[FRESH]' } else { '[old  ]' }
                    Write-Detail ("  $marker {0,-30} mtime={1:HH:mm:ss}  INFs={2}" -f $d.Name, $d.LastWriteTime, $infCount) -Color DarkGray
                }
            }
        } else {
            Write-Detail "  $amdRoot does not exist (installer never created it)" -Color DarkGray
        }
        Write-Detail "  installer process (PID $($proc.Id)) still running: $(-not $proc.HasExited)" -Color DarkGray
    }

    # Terminate the installer (and any children) before it installs.
    if (-not $proc.HasExited) {
        try { taskkill.exe /T /F /PID $proc.Id 2>&1 | Out-Null } catch { } # psa-disable-line PSA3004 -- intentional best-effort cleanup; no error to surface
    }
    Start-Sleep -Seconds 2
    foreach ($pname in @('AMDInstaller','AMD-Software-Installer','InstallManagerApp','AMDChipsetSetup','AMDChipsetSoftware','setup','InstallManagerApp.HostX86')) {
        Get-Process -Name $pname -ErrorAction SilentlyContinue |
            Stop-Process -Force -ErrorAction SilentlyContinue
    }

    if (-not $newDir) {
        throw "AMD installer did not produce a recognizable extraction directory under $amdRoot within ${maxWaitSec}s. See the diagnostic dump above. Look for a [FRESH] entry with INFs > 0; if you see one but the script timed out, the stability check (6s) may not have fired - try increasing maxWaitSec or accepting the first match."
    }

    Write-Detail "Detected extraction at $($newDir.FullName) (waited $([math]::Round($sw.Elapsed.TotalSeconds,1))s, $lastInfCount INFs)" -Color DarkGray

    # Replace Copy-Item with robocopy.
    # The previous code:
    #   Copy-Item -Path "$src\*" -Destination $dst -Recurse -Force -ErrorAction SilentlyContinue
    # exhibits a long-standing PowerShell 5.1 quirk: when -Path contains a
    # trailing wildcard AND -Destination already exists AND -Force is used,
    # top-level subdirectories are created at the destination but their
    # contents are NOT always recursively copied. On Windows Server 2025
    # (build 26100) ja-JP this was reproducibly observed against the AMD
    # chipset extracted tree (sister script's fix), so the same
    # mitigation is applied here to the graphics extraction path. The
    # graphics installer payload (~600 MB, ~19-67 INFs) is even more
    # vulnerable to silent partial-copy than the chipset one.
    #
    # robocopy is the right tool for this job because:
    #   1. Its recursion is unambiguous and reliable across edge cases.
    #   2. It has built-in lock-retry (/R:n /W:n) for residual handles.
    #   3. It reports a structured exit code so we can verify success.
    #   4. It is available on every supported Windows host (no add-on).
    #
    # /E: copy subdirectories, INCLUDING empty ones
    # /COPY:DAT: copy Data + Attributes + Timestamps (omit ACLs/owner)
    # /R:3 /W:2: 3 retries with 2s wait per attempted-locked-file
    # /NFL /NDL: suppress per-file / per-directory log output (noisy)
    # /NJH /NJS: suppress the job header / summary footer
    # /NP: suppress per-file progress bar (also noisy)
    # /MT:8: 8 copy threads (small files speed up significantly)
    #
    # robocopy exit codes 0-7 = success/info (no failures); >=8 = error.
    & robocopy.exe $newDir.FullName $DestinationPath /E /COPY:DAT /R:3 /W:2 `
        /NFL /NDL /NJH /NJS /NP /MT:8 | Out-Null
    $robocopyExit = $LASTEXITCODE
    if ($robocopyExit -ge 8) {
        throw ("robocopy failed copying '{0}' -> '{1}' with exit code {2}. Robocopy exit codes >= 8 indicate hard failures (access denied, missing source, etc.). Inspect the source and destination manually." -f $newDir.FullName, $DestinationPath, $robocopyExit)
    }

    # Post-copy verification.
    # Even though robocopy is more reliable than Copy-Item, "external
    # tool exit code = success" is not a strong enough contract for an
    # irreversible step in the middle of a long pipeline. We follow up
    # with an L1+L2 inventory comparison to catch any discrepancy that
    # the exit code might miss (file system quirks, partial copy due to
    # permission edge cases, etc.). If the verification fails we throw -
    # consistent with the rest of P04 (e.g. the "0 INFs" guard below),
    # because letting P05+ run on an incomplete extract just propagates
    # the corruption to harder-to-diagnose downstream symptoms.
    $verify = Test-RobocopyResult -SourcePath $newDir.FullName -DestinationPath $DestinationPath
    Write-Detail ("Post-copy verification: src/dst files = {0}/{1}, src/dst dirs = {2}/{3}, INFs = {4}/{5}" `
        -f $verify.SrcFileCount, $verify.DstFileCount,
            $verify.SrcDirCount,  $verify.DstDirCount,
            $verify.SrcInfCount,  $verify.DstInfCount) -Color DarkGray

    if (-not $verify.Success) {
        Write-Warn2 ("    robocopy reported exit={0} but post-copy verification FAILED:" -f $robocopyExit)
        Write-Warn2 ("      file counts (src/dst): {0}/{1}    dir counts (src/dst): {2}/{3}" `
            -f $verify.SrcFileCount, $verify.DstFileCount, $verify.SrcDirCount, $verify.DstDirCount)
        if ($verify.MissingFiles.Count -gt 0) {
            Write-Warn2 ("      Missing in destination ({0} file(s); showing first 10):" -f $verify.MissingFiles.Count)
            $verify.MissingFiles | Select-Object -First 10 | ForEach-Object {
                Write-Detail ("    - $_") -Color DarkYellow
            }
        }
        if ($verify.ExtraFiles.Count -gt 0) {
            Write-Warn2 ("      Unexpected in destination ({0} file(s); showing first 10):" -f $verify.ExtraFiles.Count)
            $verify.ExtraFiles | Select-Object -First 10 | ForEach-Object {
                Write-Detail ("    - $_") -Color DarkYellow
            }
        }
        throw ("Post-robocopy verification failed: src={0} files / dst={1} files, missing={2}, extra={3}. The source tree at '{4}' appears intact; the destination at '{5}' is incomplete. Re-run with -CleanWorkRoot, or inspect both trees manually." `
            -f $verify.SrcFileCount, $verify.DstFileCount, $verify.MissingFiles.Count, $verify.ExtraFiles.Count, $newDir.FullName, $DestinationPath)
    }

    Write-Detail ("robocopy result: exit={0}  files copied={1}  INFs copied={2}  [VERIFIED]" `
        -f $robocopyExit, $verify.DstFileCount, $verify.DstInfCount) -Color DarkGray
    Write-Ok "    Extracted via installer self-launch from $($newDir.FullName)"
}

#####################################################################
# SECTION 6: INF helpers
#####################################################################
function Read-InfFile {
    param([string]$Path)
    $bytes = [System.IO.File]::ReadAllBytes($Path)
    if ($bytes.Length -ge 2 -and $bytes[0] -eq 0xFF -and $bytes[1] -eq 0xFE) {
        return @{
            Encoding=(New-Object System.Text.UnicodeEncoding $false,$true)
            EncodingName='UTF-16 LE BOM'
            Content=[System.Text.Encoding]::Unicode.GetString($bytes,2,$bytes.Length-2)
        }
    }
    if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
        return @{
            Encoding=(New-Object System.Text.UTF8Encoding $true)
            EncodingName='UTF-8 BOM'
            Content=[System.Text.Encoding]::UTF8.GetString($bytes,3,$bytes.Length-3)
        }
    }
    return @{
        Encoding=[System.Text.Encoding]::Default
        EncodingName='ANSI'
        Content=[System.Text.Encoding]::Default.GetString($bytes)
    }
}

function Get-InfMetadata {
    # Extract human-readable metadata from an INF file's text:
    #   - Provider: driver vendor (e.g. "AMD")
    #   - Class: Windows device class (System, USB, HIDClass,...)
    #   - ClassGuid: raw GUID of the device class
    #   - DriverVer: version string from [Version]
    #   - Manufacturer: manufacturer label (resolved from [Strings])
    #   - Devices: list of {Description, HardwareId} pairs from
    #                    the manufacturer's model section, with strings
    #                    resolved against the [Strings] section
    #   - DeviceCount: count of distinct device entries
    #
    # Returns a [pscustomobject] with the above fields. Missing fields
    # are returned as $null or empty arrays so callers can format them
    # safely without null checks.
    param([Parameter(Mandatory)] [string]$Content)

    function _GetField {
        param([string]$Text, [string]$Key)
        $rx = '(?im)^\s*' + [regex]::Escape($Key) + '\s*=\s*(.+?)\s*(?:;.*)?$'
        $m = [regex]::Match($Text, $rx)
        if ($m.Success) {
            return ($m.Groups[1].Value.Trim().Trim('"'))
        }
        return $null
    }

    function _ParseSections {
        # Returns a hashtable: section name -> array of raw lines
        param([string]$Text)
        $sections = [ordered]@{}
        $current = $null
        $buf = New-Object System.Collections.Generic.List[string]
        foreach ($line in ($Text -split "`r?`n")) {
            $trim = $line.Trim()
            if ($trim -match '^\s*\[([^\]]+)\]\s*$') {
                if ($current) { $sections[$current] = $buf.ToArray() }
                $current = $matches[1].Trim()
                $buf = New-Object System.Collections.Generic.List[string]
                continue
            }
            if ($current) { [void]$buf.Add($line) }
        }
        if ($current) { $sections[$current] = $buf.ToArray() }
        return $sections
    }

    function _ResolveString {
        param([string]$Token, [hashtable]$Strings)
        if ($null -eq $Token) { return $null }
        $t = $Token.Trim().Trim('"')
        # %Foo% references a [Strings] entry
        if ($t -match '^%([^%]+)%$') {
            $key = $matches[1]
            if ($Strings.ContainsKey($key)) {
                return $Strings[$key]
            }
            return $t  # unresolved - return original
        }
        return $t
    }

    $sections = _ParseSections -Text $Content

    # Build [Strings] table for token resolution
    #
    # IMPORTANT: the LHS character class MUST include dot
    # and backslash. AMD universal INFs use token names like
    #     AMD1638.963 = "AMD Radeon(TM) Graphics"
    #     PCI\AMDPCIE.DeviceDesc = "AMD PCI Express Bridge"
    #     amdacpbus.DeviceDesc = "AMD Audio Coprocessor Bus"
    # earlier the regex `[A-Za-z0-9_]+` would only match `AMD1638`
    # (truncating at the dot), and the key 'AMD1638' would be stored
    # instead of the full 'AMD1638.963'. When a device line later
    # referenced %AMD1638.963% the lookup failed and the literal
    # %Token% was shown in P05's "device:" column. This was a
    # pre-existing bug exposed by an earlier revision (which made device-line parsing
    # work in the first place; previously the parser failed on the
    # whole [Models] section so no description was needed).
    #
    # We allow non-whitespace, non-`=`, non-`;` characters which
    # covers all real-world AMD INF token names (alphanumeric +
    # underscore + dot + backslash + occasional hyphen).
    $strings = @{}
    if ($sections.Contains('Strings')) {
        foreach ($ln in $sections['Strings']) {
            if ($ln -match '^\s*([^\s=;]+)\s*=\s*"?(.*?)"?\s*(?:;.*)?$') {
                $strings[$matches[1]] = $matches[2]
            }
        }
    }

    # [Version] section field extraction
    $versionText = ''
    if ($sections.Contains('Version')) {
        $versionText = ($sections['Version'] -join "`n")
    }
    $provider     = _ResolveString (_GetField $versionText 'Provider')      $strings
    $class        = _GetField $versionText 'Class'
    $classGuid    = _GetField $versionText 'ClassGuid'
    $driverVer    = _GetField $versionText 'DriverVer'
    $catalogFile  = _GetField $versionText 'CatalogFile'

    # [Manufacturer] -> mfgLabel = mfgSection,decorations
    #
    # IMPORTANT: collect ALL manufacturer entries, not just the
    # first one. Modern AMD universal INFs (notably u0197843.inf, the
    # base Display INF in the Adrenalin Vega-Polaris branch) can list
    # multiple manufacturer lines:
    #     %ATI% = ATI.Mfg, NTamd64.10.0...19041, NTamd64.10.0...22000
    #     %AMD% = AMD.Mfg, NTamd64.10.0...19041, NTamd64.10.0...22000
    # earlier the parser only took the first entry's section ('ATI.Mfg')
    # and missed every device listed under 'AMD.Mfg'. The reported
    # symptom was P05 logging 'device: (no device entries parsed)' for
    # u0197843.inf even though [Manufacturer] decoration parsing in P06
    # succeeded (decoration parsing iterates ALL [Manufacturer] lines).
    # The downstream effect was V06 reporting 0 patched-INF candidates
    # for the iGPU's HWID, and V05 dry-run flagging '(no device)' for
    # the install-store add of u0197843.inf - i.e. the user's iGPU was
    # silently excluded from upgrade analysis.
    $mfgLabel = $null
    $mfgSectionNames = @()
    if ($sections.Contains('Manufacturer')) {
        foreach ($ln in $sections['Manufacturer']) {
            if ($ln.Trim().StartsWith(';')) { continue }
            if ([string]::IsNullOrWhiteSpace($ln)) { continue }
            if ($ln -match '^\s*([^=;\s][^=;]*?)\s*=\s*([^;]+?)\s*(?:;.*)?$') {
                $thisLabel = _ResolveString $matches[1] $strings
                if (-not $mfgLabel) { $mfgLabel = $thisLabel }
                $rhs = $matches[2].Trim()
                # rhs is "SectionName" or "SectionName,decoration1,decoration2,..."
                $first = ($rhs -split ',')[0].Trim()
                if ($first -and ($mfgSectionNames -notcontains $first)) {
                    $mfgSectionNames += $first
                }
            }
        }
    }

    # Collect device entries from the manufacturer section AND its
    # decorated variants (e.g. "Mfg" plus "Mfg.NTamd64.10.0.3..26100").
    #
    # IMPORTANT: the wildcard `$baseName.*` can also match
    # DDInstall sections when the install-section name happens to share
    # a prefix with the Manufacturer section name (this happens in
    # AmdMicroPEP.inf, where DDInstall.Services entries previously
    # leaked into the device list and surfaced as bogus "device:
    # AddService / hwid: %SERVICE_FLAGS%" rows in P05).
    #
    # IMPORTANT: the device-line LHS can be ANY of three
    # forms in real-world AMD INFs - the earlier parser only accepted
    # form (a) which is why u0197843.inf parsed 0 devices despite
    # having a perfectly valid [Models] section:
    #
    #   (a) %Token% -- canonical AMD INF convention, where the
    #                       token resolves against [Strings]
    #                       Example: %RV2_DESC% = ati2mtag_RV2, PCI\VEN_1002&DEV_1638
    #
    #   (b) "Quoted lit" -- literal string in quotes (used in some
    #                       universal INFs that embed user-facing
    #                       text inline rather than tokenizing it)
    #                       Example: "AMD Radeon Graphics" = ati2mtag_RV2, PCI\VEN_1002&DEV_1638
    #
    #   (c) BareIdent -- bare identifier (rare; seen in some
    #                       legacy AMD universal INFs). Must NOT be
    #                       a known INF directive keyword - the
    #                       blacklist below filters those.
    #                       Example: RV2_DESC = ati2mtag_RV2, PCI\VEN_1002&DEV_1638
    #
    # Defense-in-depth (three checks):
    #   1. Skip lines whose LHS is a known directive keyword
    #      (AddService, AddReg, CopyFiles,...). This protects against
    #      DDInstall sections that share the manufacturer's name prefix.
    #   2. Each LHS form is matched by a SEPARATE regex - we don't
    #      try to consolidate them into one pattern (alternation in
    #      a single regex made the rules harder to reason about).
    #   3. Require the RHS to have AT LEAST a comma separating
    #      install-section and HWID. Lines without a comma cannot be
    #      device entries no matter what their LHS looks like.
    $infDirectiveBlacklist = @(
        'AddService','DelService','AddReg','DelReg','BitReg',
        'LogConfig','CopyFiles','DelFiles','RenFiles',
        'AddInterface','DelInterface','AddProperty','DelProperty',
        'AddComponent','DelComponent','AddSoftware','AddTrigger',
        'AddPowerSetting','AddRegisteredFile','Include','Needs',
        'Reboot','BootCritical','ExcludeFromSelect','FeatureScore'
    )
    $devices = @()
    $modelsSectionsScanned = 0
    foreach ($baseName in $mfgSectionNames) {
        if (-not $baseName) { continue }
        $matchingSecs = $sections.Keys | Where-Object {
            $_ -eq $baseName -or $_ -like "$baseName.*"
        }
        foreach ($secName in $matchingSecs) {
            $modelsSectionsScanned++
            foreach ($ln in $sections[$secName]) {
                if ($ln.Trim().StartsWith(';')) { continue }
                if ([string]::IsNullOrWhiteSpace($ln)) { continue }

                # Pre-filter: skip lines whose LHS bare-ident is a
                # known DDInstall directive (defends against section-
                # name collisions, see related comment).
                if ($ln -match '^\s*([A-Za-z][A-Za-z0-9_]+)\s*=' -and
                    ($infDirectiveBlacklist -contains $matches[1])) {
                    continue
                }

                $desc = $null
                $hwid = $null

                # Form (a): %Token% LHS - canonical AMD convention.
                if ($ln -match '^\s*%([^%]+)%\s*=\s*[^,;]+\s*,\s*([^,;]+?)\s*(?:,.*)?(?:;.*)?$') {
                    $tok  = $matches[1]
                    $desc = if ($strings.ContainsKey($tok)) { $strings[$tok] } else { "%$tok%" }
                    $hwid = $matches[2].Trim()
                }
                # Form (b): "Quoted literal" LHS.
                # NOTE (enhancement after seeing real u0197843.inf): AMD's
                # WHQL Adrenalin Vega-Polaris driver wraps %Token% references
                # inside double quotes, e.g.:
                #     "%AMD1638.963%" = ati2mtag_Cezanne, PCI\VEN_1002&DEV_1638&REV_DB
                # Form (a) above won't match (LHS doesn't start with %), so
                # we land in this Form (b) branch. If the quoted content is
                # itself a %Token% reference, resolve it against [Strings]
                # so the device description displays cleanly as the actual
                # product name (e.g. "AMD Radeon(TM) Graphics") rather than
                # a literal token reference. The HWID extraction works the
                # same either way.
                elseif ($ln -match '^\s*"([^"]*)"\s*=\s*[^,;]+\s*,\s*([^,;]+?)\s*(?:,.*)?(?:;.*)?$') {
                    $quoted = $matches[1]
                    $hwid = $matches[2].Trim()
                    if ($quoted -match '^%([^%]+)%$') {
                        $tok = $matches[1]
                        $desc = if ($strings.ContainsKey($tok)) { $strings[$tok] } else { "%$tok%" }
                    } else {
                        $desc = $quoted
                    }
                }
                # Form (c): bare identifier LHS (already filtered for
                # directive keywords by the pre-filter above).
                elseif ($ln -match '^\s*([A-Za-z_][A-Za-z0-9_\.]*)\s*=\s*[^,;]+\s*,\s*([^,;]+?)\s*(?:,.*)?(?:;.*)?$') {
                    $desc = $matches[1]
                    $hwid = $matches[2].Trim()
                }

                if ($desc -and $hwid) {
                    $devices += [pscustomobject]@{
                        Description = $desc
                        HardwareId  = $hwid
                        FromSection = $secName
                    }
                }
            }
        }
    }
    # Deduplicate by HardwareId (the same device can appear under
    # multiple architecture decorations - we want to count it once
    # in the per-INF summary).
    $devices = @($devices | Group-Object HardwareId | ForEach-Object { $_.Group | Select-Object -First 1 })

    return [pscustomobject]@{
        Provider              = $provider
        Class                 = $class
        ClassGuid             = $classGuid
        DriverVer             = $driverVer
        CatalogFile           = $catalogFile
        Manufacturer          = $mfgLabel
        Devices               = $devices
        DeviceCount           = $devices.Count
        ManufacturerEntries   = $mfgSectionNames.Count   # number of distinct mfg sections (>1 = multi-mfg INF)
        ModelsSectionsScanned = $modelsSectionsScanned   # number of [Mfg.NT...] sections that were scanned
    }
}

function Write-InfFile {
    param([string]$Path, [string]$Content, $Encoding)
    [System.IO.File]::WriteAllText($Path, $Content, $Encoding)
}

function ConvertTo-ServerDecoration {
    param([string]$ClientDec)
    if ($ClientDec -notmatch '^NT(amd64|x86|arm|arm64)') { return $null }
    $parts = $ClientDec.Split('.')
    while ($parts.Count -lt 4) { $parts += '' }
    if ($parts[3] -eq '3') { return $null }
    $parts[3] = '3'
    return ($parts -join '.')
}

function Edit-InfForServer {
    param([string]$InfPath, [string]$OutputPath, [pscustomobject]$OsContext)

    $infData = Read-InfFile -Path $InfPath
    $lines = $infData.Content -split "(?<=`n)"
    if (-not ($lines -is [array])) { $lines = @($lines) }

    # Pass 1: collect [Manufacturer] entries / decorations
    $clientDecorations = @{}
    $mfgIndices = @()
    $inMfg = $false
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $t = $lines[$i].Trim().TrimEnd("`r")
        if ($t -match '^\[Manufacturer\]') { $inMfg = $true; continue }
        if ($inMfg -and $t -match '^\[')   { $inMfg = $false }
        if ($inMfg -and $t -and -not $t.StartsWith(';')) {
            $mfgIndices += $i
            $kv = $t -split '=', 2
            if ($kv.Count -ne 2) { continue }
            $rhs = $kv[1].Split(',')
            $sectionName = $rhs[0].Trim()
            for ($j = 1; $j -lt $rhs.Count; $j++) {
                $dec = $rhs[$j].Trim()
                if ($dec -match '^NT' -and $dec -notmatch '^NT\w+\.\d+\.\d+\.3\.') {
                    if (-not $clientDecorations.ContainsKey($dec)) {
                        $clientDecorations[$dec] = @{ Sections=@() }
                    }
                    if ($clientDecorations[$dec].Sections -notcontains $sectionName) {
                        $clientDecorations[$dec].Sections += $sectionName
                    }
                }
            }
        }
    }

    if ($clientDecorations.Count -eq 0) {
        return @{ Patched=$false; Reason='No client decorations found'; Encoding=$infData.EncodingName }
    }

    $decMap = @{}
    foreach ($cd in $clientDecorations.Keys) {
        $sd = ConvertTo-ServerDecoration -ClientDec $cd
        if ($sd) { $decMap[$cd] = $sd }
    }

    # Pass 2: append server decorations to each [Manufacturer] entry
    foreach ($idx in $mfgIndices) {
        $line = $lines[$idx]
        $eolMatch = [regex]::Match($line, "(`r?`n)$")
        $eol = if ($eolMatch.Success) { $eolMatch.Value } else { '' }
        $core = if ($eol) { $line.Substring(0, $line.Length - $eol.Length) } else { $line }
        $appended = $core
        foreach ($cd in $decMap.Keys) {
            $sd = $decMap[$cd]
            if ($appended -match [regex]::Escape($cd) -and $appended -notmatch [regex]::Escape($sd)) {
                $appended = $appended.TrimEnd() + ", $sd"
            }
        }
        $lines[$idx] = $appended + $eol
    }

    # Pass 3: collect sections to mirror
    $sectionsToMirror = @{}
    $current = $null
    $body    = New-Object System.Collections.Generic.List[string]
    foreach ($line in $lines) {
        $t = $line.Trim().TrimEnd("`r")
        if ($t -match '^\[(.+?)\]$') {
            if ($current -and $sectionsToMirror.ContainsKey($current)) {
                $sectionsToMirror[$current] = $body.ToArray()
            }
            $current = $matches[1]
            $body.Clear()
            foreach ($cd in $decMap.Keys) {
                if ($current.EndsWith(".$cd")) { $sectionsToMirror[$current] = @(); break }
            }
            continue
        }
        if ($current -and $sectionsToMirror.ContainsKey($current)) { [void]$body.Add($line) }
    }
    if ($current -and $sectionsToMirror.ContainsKey($current)) {
        $sectionsToMirror[$current] = $body.ToArray()
    }

    # Pass 4: emit mirrored sections
    $sb = New-Object System.Text.StringBuilder
    foreach ($l in $lines) { [void]$sb.Append($l) }
    [void]$sb.AppendLine()
    [void]$sb.AppendLine('; ====================================================')
    [void]$sb.AppendLine('; Auto-generated: ProductType=3 (Server) sections')
    [void]$sb.AppendLine("; Target OS: $($OsContext.Name) (build $($OsContext.Build))")
    [void]$sb.AppendLine("; Generated: $(Get-Date -Format o)")
    [void]$sb.AppendLine('; ====================================================')

    foreach ($origHeader in $sectionsToMirror.Keys) {
        $cd = $decMap.Keys | Where-Object { $origHeader.EndsWith(".$_") } | Select-Object -First 1
        if (-not $cd) { continue }
        $sd = $decMap[$cd]
        $base = $origHeader.Substring(0, $origHeader.Length - $cd.Length - 1)
        [void]$sb.AppendLine('')
        [void]$sb.AppendLine("[$base.$sd]")
        foreach ($bl in $sectionsToMirror[$origHeader]) { [void]$sb.Append($bl) }
    }

    Write-InfFile -Path $OutputPath -Content $sb.ToString() -Encoding $infData.Encoding
    return @{
        Patched              = $true
        Encoding             = $infData.EncodingName
        ManufacturerEntries  = $mfgIndices.Count
        Decorations          = $decMap
        SectionsMirrored     = $sectionsToMirror.Keys.Count
    }
}

#####################################################################
# SECTION 7: Phase idempotency helpers
#####################################################################
function Test-PhaseMarker {
    param($Ctx, [string]$PhaseId)
    $marker = Join-Path $Ctx.Paths.Markers ".$PhaseId.done"
    if ((Test-Path $marker) -and -not $Ctx.Force) { return $true }
    return $false
}

function Set-PhaseMarker {
    param($Ctx, [string]$PhaseId, [hashtable]$Metadata = @{})
    $marker = Join-Path $Ctx.Paths.Markers ".$PhaseId.done"
    $payload = @{ phase=$PhaseId; completedAt=(Get-Date -Format o); meta=$Metadata }
    $payload | ConvertTo-Json -Depth 5 | Set-Content -Path $marker -Encoding UTF8
}

function Clear-PhaseMarker {
    param($Ctx, [string]$PhaseId)
    $marker = Join-Path $Ctx.Paths.Markers ".$PhaseId.done"
    if (Test-Path $marker) { Remove-Item $marker -Force }
}

#####################################################################
# SECTION 8: PREPARATION PHASES
#####################################################################

#####################################################################
# SECTION (r69, QI-9): System Restore status helpers
#####################################################################
# Operator-facing warning about System Restore state. Called from
# P01 (PrepareWorkspace) after the workspace is created. We DO NOT
# enable System Restore automatically (Q9-A) - the warning is
# informational only. The most important caveat is that SiPolicy.p7b
# is excluded from System Restore by design, so rolling back a
# restore point will NOT recover a WDAC boot-policy regression.
# See SPEC SS D.26.2.D / D.26.3 (QI-9) / D.27.
#
# These two functions are PSA8001-enforced byte-identical across
# Chipset / Graphics / BthPan. NPU is excluded via
# psa8001_ignore_functions because NPU refuses Install on legacy
# Windows Server (Q-X1, r17).

function Get-SystemRestorePointStatus { # psa-disable-line PSA6003 -- "Status" is a Latin-origin singular noun (no plural form in PowerShell idiom); the -s suffix is morphological, not plural
    # Returns the current System Restore configuration for the
    # system drive.
    #
    # OUTPUT: pscustomobject with:
    #   - Enabled            ([bool])  true if System Restore is enabled
    #   - ConfigurationFound ([bool])  true if SR config registry exists
    #   - RecentPoints       (object[]) recent restore points (<= 30 days)
    #   - SiPolicyExcluded   ([bool])  always $true - informational
    #
    # NOTES:
    #   - On Windows Server, System Restore is OFF by default.
    #   - Get-ComputerRestorePoint throws on disabled SR; we catch.
    #   - SR does NOT capture C:\Windows\System32\CodeIntegrity\SiPolicy.p7b
    #     (boot-time policy is excluded from System Restore by
    #     design); this is surfaced to the operator by
    #     Show-SystemRestorePointWarning. See SPEC SS D.26.2.D.
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()
    $result = [pscustomobject]@{
        Enabled            = $false
        ConfigurationFound = $false
        RecentPoints       = @()
        SiPolicyExcluded   = $true
    }
    try {
        $srKey = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore'
        if (Test-Path $srKey) {
            $result.ConfigurationFound = $true
        }
        $points = Get-ComputerRestorePoint -ErrorAction Stop
        $result.Enabled = $true
        $cutoff = (Get-Date).AddDays(-30)
        $result.RecentPoints = @($points | Where-Object {
            $_.CreationTime -ge $cutoff
        })
    } catch {
        # Either SR is disabled (most common on Server SKUs) or we
        # lack privileges. Leave Enabled=$false, RecentPoints=@().
        $result.Enabled = $false
    }
    return $result
}

function Show-SystemRestorePointWarning {
    # Print the operator-facing warning about System Restore status.
    # Called from P01 (PrepareWorkspace) after the workspace is created.
    #
    # CRITICAL: this function MUST mention that SiPolicy.p7b is
    # excluded from System Restore, because operators reading
    # 'Restore Point available' without that caveat would expect a
    # roll-back to recover boot-policy regressions, which it cannot.
    # See SPEC SS D.26.2.D and the catastrophic field failure case
    # study in SPEC SS D.26.
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [pscustomobject]$Status
    )
    Write-Host ''
    Write-Host '--- System Restore status (snapshot recommendation) ---' -ForegroundColor Cyan
    if ($Status.Enabled) {
        Write-Host '  System Restore is ENABLED on the system drive' -ForegroundColor Green
        Write-Host ('  Recent restore points (last 30 days): {0}' -f $Status.RecentPoints.Count) -ForegroundColor Green
        if ($Status.RecentPoints.Count -eq 0) {
            Write-Host '  [!] No recent restore points exist. Create one BEFORE running -Action Install:' -ForegroundColor Yellow
            Write-Host '      Checkpoint-Computer -Description "pre-driver-install"' -ForegroundColor DarkYellow
        }
    } else {
        Write-Host '  System Restore is DISABLED on the system drive (default on Windows Server SKUs)' -ForegroundColor Yellow
        Write-Host '  [!] You have NO automatic rollback path for driver-store regressions.' -ForegroundColor Yellow
        Write-Host '  RECOMMENDED: take a VM snapshot, full disk image, or external backup BEFORE proceeding.' -ForegroundColor Yellow
        Write-Host '  Alternative (Windows-native): enable System Restore manually with:' -ForegroundColor DarkYellow
        Write-Host '      Enable-ComputerRestore -Drive C:' -ForegroundColor DarkYellow
        Write-Host '      Checkpoint-Computer -Description "pre-driver-install"' -ForegroundColor DarkYellow
    }
    # CRITICAL caveat - must always be printed regardless of SR state.
    Write-Host ''
    Write-Host '  [IMPORTANT] System Restore does NOT capture WDAC boot policy.' -ForegroundColor Red
    Write-Host ('             {0} is excluded from System Restore by design.' -f 'C:\Windows\System32\CodeIntegrity\SiPolicy.p7b') -ForegroundColor Red
    Write-Host '             If the host fails to boot due to WDAC policy regression,' -ForegroundColor Red
    Write-Host '             rolling back System Restore alone will NOT fix it. You will' -ForegroundColor Red
    Write-Host '             need WinRE-driven manual SiPolicy.p7b deletion or OS reinstall.' -ForegroundColor Red
    Write-Host '             See README "Recovery from unbootable state" for details.' -ForegroundColor Red
    Write-Host ''
}


function Invoke-PrepPhase00_Initialize {
    param($Ctx)
    Write-PhaseHeader 'P00' 'Initialize' 'Prep'

    # Always show the runtime environment first - this is what the
    # user sees if anything else later fails, and it provides the
    # context needed to triage compatibility issues.
    Set-DebugStep 'show PS environment'
    Show-PowerShellEnvironment

    # Hard pre-flight checks that the script cannot continue without.
    # Order matters: PS version & bitness first (a 32-bit / PS4 host
    # cannot even reliably parse this script), then Administrator,
    # then network TLS configuration, then UTF-8 console encoding (SPEC
    # A.5 / D.5 / D.16 — required for CiTool.exe and signtool.exe ja-JP
    # output to decode correctly instead of becoming mojibake).
    Set-DebugStep 'pre-flight checks (PS compat / admin / TLS / UTF8)'
    Assert-PowerShellCompatibility
    Assert-Admin
    Set-Tls12
    Set-ConsoleUtf8

    Set-DebugStep 'detect OS context'
    $Ctx.Os = Get-OsContext
    $isWorkstation = ($Ctx.Os.ProductType -eq 1)
    $isBuild26100  = ($Ctx.Os.ActualBuild -eq 26100)

    if ($isWorkstation) {
        # Show the ACTUAL OS Caption (e.g. "Microsoft Windows 11 Pro") plus
        # the Server profile this script will treat it as. Previously the
        # display only showed the mapped profile name, which made it look
        # like the script had mis-detected the OS.
        Write-Ok "OS detected: $($Ctx.Os.Caption) (build $($Ctx.Os.ActualBuild))"
        Write-Detail "Profile applied : $($Ctx.Os.Code) ($($Ctx.Os.Name))" -Color DarkGray
        Write-Detail "ProductType     : $($Ctx.Os.ProductType)  (1=Workstation, 3=Server)"
        Write-Host ''
        if ($isBuild26100) {
            # IDEAL preview scenario: Win11 24H2 (26100) shares the WS2025 kernel.
            Write-Host '    +-----------------------------------------------------------------+' -ForegroundColor Cyan
            Write-Host '    | WS2025 PRE-MIGRATION PREVIEW MODE                               |' -ForegroundColor Cyan
            Write-Host '    | (Windows 11 24H2 and Windows Server 2025 share NT build 26100)  |' -ForegroundColor Cyan
            Write-Host '    +-----------------------------------------------------------------+' -ForegroundColor Cyan
            Write-Host '    | This host is a high-fidelity preview target for WS2025. The    |' -ForegroundColor Cyan
            Write-Host '    | P00-V05 outputs (INF inventory, patching, catalogs, install     |' -ForegroundColor Cyan
            Write-Host '    | plan) will match a future WS2025 run on this same hardware.    |' -ForegroundColor Cyan
            Write-Host '    |                                                                 |' -ForegroundColor Cyan
            Write-Host '    | Caveat: V06 (Hardware Impact Analysis) will differ. Win11''s    |' -ForegroundColor Cyan
            Write-Host '    | OEM driver baseline disappears after WS2025 clean install, so   |' -ForegroundColor Cyan
            Write-Host '    | many devices that look "kept" here will become "WILL be        |' -ForegroundColor Cyan
            Write-Host '    | replaced" on the actual WS2025 host (MS-generic baseline).     |' -ForegroundColor Cyan
            Write-Host '    +-----------------------------------------------------------------+' -ForegroundColor Cyan
        } else {
            # Workstation but NOT build 26100 - profile mismatch warning
            Write-Host '    +-----------------------------------------------------------------+' -ForegroundColor Yellow
            Write-Host '    | WORKSTATION OS - LOWER-FIDELITY PREVIEW                         |' -ForegroundColor Yellow
            Write-Host '    +-----------------------------------------------------------------+' -ForegroundColor Yellow
            Write-Host ('    | This Workstation host (build {0}) is mapped to the {1} profile.' -f $Ctx.Os.ActualBuild, $Ctx.Os.Code) -ForegroundColor Yellow
            Write-Host '    | For maximum WS2025 fidelity, run this preview on Windows 11    |' -ForegroundColor Yellow
            Write-Host '    | 24H2 (build 26100) instead.                                    |' -ForegroundColor Yellow
            Write-Host '    +-----------------------------------------------------------------+' -ForegroundColor Yellow
        }
        Write-Host ''
        # Determine derived script type from version string for the log filename hint
        $logTag = switch -Wildcard ($Script:ScriptVersion) {
            'graphics-*' { 'graphics'; break }
            'chipset-*'  { 'chipset';  break }
            'npu-*'      { 'npu';      break }
            'msbthpan-*' { 'msbthpan'; break }
            default      { 'driver' }
        }
        $scriptLeaf = if ($Script:ScriptPath) { Split-Path $Script:ScriptPath -Leaf } else { '<this-script>.ps1' }
        Write-Host '    RECOMMENDED USAGE on this Workstation host:' -ForegroundColor White
        Write-Host '      1. Use -Action PrepareVerify -CleanWorkRoot only (no system' -ForegroundColor White
        Write-Host '         changes; safe to run repeatedly).' -ForegroundColor White
        Write-Host '      2. Save the run log for post-WS2025-install comparison.' -ForegroundColor White
        Write-Host '         Preferred: use -LogFile, which keeps console colors.' -ForegroundColor White
        Write-Detail ('     $ts = Get-Date -Format ''yyyyMMdd-HHmmss''') -Color DarkGray
        Write-Detail ("     .\{0} -Action PrepareVerify -CleanWorkRoot ``" -f $scriptLeaf) -Color DarkGray
        Write-Detail ("       -LogFile ""C:\Temp\{0}_PrepareVerify_Win11-preview_`$ts.log""" -f $logTag) -Color DarkGray
        Write-Host '         Legacy fallback (Tee-Object, colors stripped):' -ForegroundColor White
        Write-Detail ("     .\{0} -Action PrepareVerify -CleanWorkRoot *>&1 |" -f $scriptLeaf) -Color DarkGray
        Write-Detail ("       Tee-Object -FilePath ""C:\Temp\{0}_PrepareVerify_Win11-preview_`$(Get-Date -Format 'yyyyMMdd-HHmmss').log""" -f $logTag) -Color DarkGray
        Write-Host '      3. After WS2025 clean install, re-run with the same command' -ForegroundColor White
        Write-Detail ("       (-LogFile ""C:\Temp\{0}_PrepareVerify_WS2025_`$ts.log"")" -f $logTag) -Color DarkGray
        Write-Host '         and compare the two logs (especially V06 section 2/3).' -ForegroundColor White
        Write-Host '      4. -Action Install / I01-I04 phases are REJECTED on Workstation' -ForegroundColor White
        Write-Host '         (would import certs, deploy WDAC policy, displace OEM drivers).' -ForegroundColor White
        Write-Host '         Use -AllowWorkstationInstall to override (NOT recommended).' -ForegroundColor White
        Write-Host ''

        # ===== Workstation Install guard =====
        # Refuse to run any Install phase (I01-I04) on Workstation,
        # unless -AllowWorkstationInstall was explicitly passed.
        Set-DebugStep 'workstation install guard check'
        $hasInstallPhases = @($Ctx.SelectedPhaseIds | Where-Object { $_ -match '^I0[0-4]$' }).Count -gt 0
        if ($hasInstallPhases -and -not $Ctx.AllowWorkstationInstall) {
            $msg = @"
Refusing to run Install phases (I01-I04) on Workstation OS (ProductType=1).

This script's installation pipeline is designed for Windows Server hosts.
Running it on a Workstation Windows host (e.g. Windows 11 used as a WS2025
preview) would:
  - Import a self-signed certificate into LocalMachine\Root and TrustedPublisher
  - Deploy a WDAC supplemental Code Integrity policy
  - Replace OEM AMD graphics / audio drivers with self-signed patched versions
  - Invalidate vendor signatures on the host (visible in Device Manager)

Recommended:
  * Use -Action PrepareVerify -CleanWorkRoot (no system changes).
  * After clean-installing Windows Server 2025 on this hardware, re-run
    with -Action Install on the actual Server host.

If you really need to install on this Workstation host, pass
-AllowWorkstationInstall (you accept the consequences).
"@
            throw $msg
        }
    } else {
        Write-Ok "OS detected: $($Ctx.Os.Name) (build $($Ctx.Os.ActualBuild)) [$($Ctx.Os.Code)]"
        Write-Detail "ProductType: $($Ctx.Os.ProductType)  (1=Workstation, 3=Server)"
    }

    # ---- UEFI Secure Boot certificate baseline (port from chipset) ----
    # Capture once at P00 and cache on $Ctx so later phases (P05 report
    # append, V05 / V06 display, I02 pre-check) can reuse the same
    # snapshot without re-invoking the Microsoft sample script multiple
    # times in a single run. an earlier revision (mirrored from chipset): the snapshot
    # function uses New-Item -Force internally so the WorkRoot directory
    # is auto-created if it does not exist yet (P01 hasn't run);
    # subsequent phases revisit the snapshot via
    # Get-OrEnsureSecureBootBaseline which detects a missing diagnostic
    # file (e.g. when -CleanWorkRoot wipes it at P01) and re-captures.
    Set-DebugStep 'capture Secure Boot baseline'
    try {
        $Ctx.SecureBootBaseline = Get-SecureBootBaselineSnapshot -WorkRoot $Ctx.WorkRoot
        Show-SecureBootBaselineSnapshot -Snapshot $Ctx.SecureBootBaseline -Compact
    } catch {
        Write-Warn2 ("Secure Boot baseline capture failed: {0}" -f $_.Exception.Message)
    }

    Write-PhaseFooter 'P00' 'done'
}

function Invoke-PrepPhase01_PrepareWorkspace {
    param($Ctx)
    Write-PhaseHeader 'P01' 'PrepareWorkspace' 'Prep'

    Set-DebugStep 'optional: wipe existing workspace (-CleanWorkRoot)'
    if ($Ctx.CleanWorkRoot -and (Test-Path $Ctx.WorkRoot)) {
        Write-Step "Removing existing -WorkRoot for clean run: $($Ctx.WorkRoot)"
        Remove-Item -Path $Ctx.WorkRoot -Recurse -Force
        Write-Ok 'Workspace wiped.'
    }

    Set-DebugStep 'create workspace subdirectories'
    $paths = [pscustomobject]@{
        Root      = $Ctx.WorkRoot
        Download  = Join-Path $Ctx.WorkRoot 'download'
        Extract   = Join-Path $Ctx.WorkRoot 'extracted'
        Patched   = Join-Path $Ctx.WorkRoot 'patched'
        Cert      = Join-Path $Ctx.WorkRoot 'cert'
        Markers   = Join-Path $Ctx.WorkRoot '.markers'
        Logs      = Join-Path $Ctx.WorkRoot 'logs'
    }
    foreach ($prop in $paths.PSObject.Properties) {
        if (-not (Test-Path $prop.Value)) {
            New-Item -ItemType Directory -Path $prop.Value -Force | Out-Null
        }
    }
    $Ctx.Paths = $paths
    Write-Ok "Workspace ready under $($Ctx.WorkRoot)"

    # Enable Debug Trace JSONL writer. Now that $paths.Logs exists
    # (created above), we can switch JSONL output to "default ON for file
    # output" - any pre-P01 trace events that are sitting in the in-memory
    # buffer get flushed in one shot. Failures are absorbed and warned
    # about (see Enable-DebugTraceFileOutput).
    Set-DebugStep 'enable Debug Trace JSONL writer'
    Enable-DebugTraceFileOutput -Directory $paths.Logs

    # Also activate auto-export-on-phase-failure. The phase
    # dispatcher's catch block calls Write-DebugFailureReport -AutoExport,
    # which writes a debugtrace_export_<phaseId>_<ts>.json snapshot to
    # this directory so the user has a single self-contained file to
    # attach to a bug report.
    Enable-AutoExportOnPhaseFailure -OutputDirectory $paths.Logs

    # Rehydrate $Ctx from existing workspace artifacts so that
    # -Action Verify / -Action Install (-OnlyPhases I01) can run
    # against a populated workspace without re-running P02-P09.
    # See function Resume-CtxFromWorkspace below.
    Set-DebugStep 'rehydrate $Ctx from existing workspace artifacts'
    Resume-CtxFromWorkspace -Ctx $Ctx

    # Acquire the workspace lock NOW (after the.markers/ directory
    # exists). This catches the case where the user accidentally
    # starts a second instance against the same workspace - we fail
    # fast with a clear error rather than racing pnputil / CiTool.
    # Stale locks (from crashed previous runs) are auto-detected and
    # superseded.
    Set-DebugStep 'acquire workspace concurrency lock'
    Assert-NoConcurrentRun -Ctx $Ctx

    Set-PhaseMarker -Ctx $Ctx -PhaseId 'P01'
    # QI-9 (r69, 2026-05-23): System Restore status check.
    # Workspace has been created; this is the natural place to remind
    # the operator that no Windows-managed rollback path exists for a
    # WDAC boot-policy regression. See SPEC SS D.27. Non-fatal and
    # never blocks; informational only.
    Set-DebugStep 'QI-9: System Restore status check'
    try {
        $srStatus = Get-SystemRestorePointStatus
        Show-SystemRestorePointWarning -Status $srStatus
    } catch {
        # SR status is informational; failure here MUST NOT block
        # workspace preparation. Log and continue.
        Write-Warn2 ('System Restore status check failed (non-fatal): {0}' -f $_.Exception.Message)
    }

    Write-PhaseFooter 'P01' 'done'
}

function Resume-CtxFromWorkspace {
    <#
    .SYNOPSIS
        Rebuild a SUBSET of $Ctx properties from artifacts already
        present in the workspace. Called from P01 to support
        non-Prepare run modes (-Action Verify, -Action Install
        -OnlyPhases I01).
    .DESCRIPTION
        Unlike BthPan (single bthpan.inf), AMD graphics drivers
        contain MULTIPLE INFs whose patched artifacts cannot be
        fully reconstructed without re-running P05-P06 analysis.
        This helper therefore restores only the artifacts that CAN
        be deduced from the on-disk workspace alone:
          - Cert PFX path    (Paths.Cert\AMD-Graphics-Driver-CodeSign.pfx)
          - Cert CER path    (Paths.Cert\AMD-Graphics-Driver-CodeSign.cer)
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
            $pfx = Join-Path $Ctx.Paths.Cert 'AMD-Graphics-Driver-CodeSign.pfx'
            if (Test-Path -LiteralPath $pfx) {
                $Ctx.CertPfxPath = $pfx
                $rehydrated.Add('CertPfxPath') | Out-Null
            }
        } catch {} # psa-disable-line PSA3004 -- best-effort scan; missing artifact = leave $null
    }

    # ----- Cert CER + Thumbprint (decoded from CER on disk) -----
    if (-not $Ctx.CertCerPath) {
        try {
            $cer = Join-Path $Ctx.Paths.Cert 'AMD-Graphics-Driver-CodeSign.cer'
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

function Invoke-PrepPhase02_AcquireTools { # psa-disable-line PSA6003 -- compound noun (e.g., Policies, Drivers, Catalogs) is semantically plural for set-returning helpers
    param($Ctx)
    Write-PhaseHeader 'P02' 'AcquireTools' 'Prep'

    Set-DebugStep 'check phase marker (cache hit?)'
    if (Test-PhaseMarker -Ctx $Ctx -PhaseId 'P02') {
        $Ctx.SevenZip = Get-SevenZipPath
        $Ctx.Signtool = Find-KitTool 'signtool.exe'
        $Ctx.Inf2cat  = Find-KitTool 'inf2cat.exe'
        if ($Ctx.SevenZip -and $Ctx.Signtool -and $Ctx.Inf2cat) {
            Write-Skip 'Tools already present (cached marker).'
            Write-Detail "7-Zip   : $($Ctx.SevenZip)"
            Write-Detail "signtool: $($Ctx.Signtool)"
            Write-Detail "inf2cat : $($Ctx.Inf2cat)"
            Write-PhaseFooter 'P02' 'cached'
            return
        }
        Write-Warn2 'Marker present but tool missing - re-running.'
    }

    Set-DebugStep 'detect region for winget'
    # Detect machine region (2-letter ISO). winget will use this when
    # any source needs it (notably msstore). We pre-detect and log it
    # for transparency, then route winget to --source winget so the
    # msstore disclaimer prompts are skipped entirely.
    $region = Get-MachineRegion
    Write-Detail "Region       : $region (auto-detected from system locale / home location)"
    Write-Detail "winget source: 'winget' only (msstore is bypassed for these packages)"

    Set-DebugStep 'install 7-Zip (winget -> direct MSI fallback)'
    # 7-Zip
    if (-not (Get-SevenZipPath)) {
        if ((Test-WingetWorking)) {
            Write-Step '7-Zip: trying winget'
            try {
                $null = Invoke-WingetSilently -PackageId '7zip.7zip'
            } catch { Write-Warn2 "winget failed: $($_.Exception.Message)" }
        }
        if (-not (Get-SevenZipPath)) {
            Write-Step '7-Zip: direct MSI fallback'
            Install-SevenZipFallback -DownloadDir $Ctx.Paths.Download
        }
    }
    $Ctx.SevenZip = Get-SevenZipPath
    if (-not $Ctx.SevenZip) { throw '7-Zip install failed' }
    Write-Ok "7-Zip: $($Ctx.SevenZip)"

    # Signing tools
    $signtool = Find-KitTool 'signtool.exe'
    $inf2cat  = Find-KitTool 'inf2cat.exe'
    Write-Detail "Profile      : $($Ctx.Os.Code)"
    Write-Detail "SDK build    : $($Ctx.Os.SdkBuild)"
    Write-Detail "WDK build    : $($Ctx.Os.WdkBuild)"
    Write-Detail "Notes        : $($Ctx.Os.ToolkitNotes)"

    # On a clean-installed host the SDK and WDK packages are
    # absent and must be downloaded via winget. The bootstrap EXEs
    # (winsdksetup.exe / wdksetup.exe) are ~1.3 MB each but the
    # background payloads they pull from Microsoft Download CDN are
    # several hundred MB to multi-GB; the install typically takes
    # ~5 min for the SDK and ~3 min for the WDK on a typical
    # connection in JP (total P02 elapsed ~8-10 min). On subsequent
    # runs in the same workspace, the P02 PhaseMarker is hit and
    # this whole block is skipped in ~2 s. We surface this once,
    # up-front, so the user is not surprised by the long pause.
    $needsSdk = (-not $signtool) -and $Ctx.Os.WingetSdkId
    $needsWdk = (-not $inf2cat)  -and $Ctx.Os.WingetWdkId
    if ($needsSdk -or $needsWdk) {
        $missing = @()
        if ($needsSdk) { $missing += 'Windows SDK (~5 min)' }
        if ($needsWdk) { $missing += 'Windows WDK (~3 min)' }
        Write-Warn2 ('First-run install required for: {0}.' -f ($missing -join ', '))
        Write-Host  '       Bootstrap EXEs are small (~1-2 MB) but each fetches several hundred MB'  -ForegroundColor DarkYellow
        Write-Host  '       to multi-GB of background payload from Microsoft Download CDN.'         -ForegroundColor DarkYellow
        Write-Host  '       Expected P02 elapsed on a clean host (JP): ~8-10 minutes.'              -ForegroundColor DarkYellow
        Write-Host  '       Subsequent runs in the same workspace will skip P02 (PhaseMarker hit).' -ForegroundColor DarkGray
    }

    Set-DebugStep 'install Windows SDK / WDK (winget -> direct EXE fallback)'
    $wingetWorks = (Test-WingetWorking) -and $Ctx.Os.CanInstallWinget
    if ($wingetWorks -and $Ctx.Os.WingetSdkId -and -not $signtool) {
        Write-Step "Windows SDK: winget ($($Ctx.Os.WingetSdkId))"
        try { $null = Invoke-WingetSilently -PackageId $Ctx.Os.WingetSdkId }
        catch { Write-Warn2 "winget SDK failed: $($_.Exception.Message)" }
    }
    if ($wingetWorks -and $Ctx.Os.WingetWdkId -and -not $inf2cat) {
        Write-Step "Windows WDK: winget ($($Ctx.Os.WingetWdkId))"
        try { $null = Invoke-WingetSilently -PackageId $Ctx.Os.WingetWdkId }
        catch { Write-Warn2 "winget WDK failed: $($_.Exception.Message)" }
    }
    if (-not (Find-KitTool 'signtool.exe')) {
        Write-Step "Windows SDK: direct EXE fallback for $($Ctx.Os.Name)"
        Install-WindowsSdkFallback -OsContext $Ctx.Os -DownloadDir $Ctx.Paths.Download
    }
    if (-not (Find-KitTool 'inf2cat.exe')) {
        Write-Step "Windows WDK: direct EXE fallback for $($Ctx.Os.Name)"
        Install-WindowsWdkFallback -OsContext $Ctx.Os -DownloadDir $Ctx.Paths.Download
    }
    $Ctx.Signtool = Find-KitTool 'signtool.exe'
    $Ctx.Inf2cat  = Find-KitTool 'inf2cat.exe'
    if (-not $Ctx.Signtool) { throw 'signtool.exe not found after install' }
    if (-not $Ctx.Inf2cat)  { throw 'inf2cat.exe not found after install' }
    Write-Ok "signtool: $($Ctx.Signtool)"
    Write-Ok "inf2cat : $($Ctx.Inf2cat)"
    Set-PhaseMarker -Ctx $Ctx -PhaseId 'P02' -Metadata @{
        SevenZip = $Ctx.SevenZip
        Signtool = $Ctx.Signtool
        Inf2cat  = $Ctx.Inf2cat
        Region   = $region
    }
    Write-PhaseFooter 'P02' 'done'
}

function Invoke-PrepPhase03_FetchInstaller {
    param($Ctx)
    Write-PhaseHeader 'P03' 'FetchInstaller' 'Prep'

    Set-DebugStep 'check phase marker (cache hit?)'
    if (Test-PhaseMarker -Ctx $Ctx -PhaseId 'P03') {
        $cached = Get-ChildItem $Ctx.Paths.Download -Filter 'amd_chipset_software_*.exe' -ErrorAction SilentlyContinue |
                  Sort-Object LastWriteTime -Descending | Select-Object -First 1
        if ($cached -and $cached.Length -ge 5MB) {
            $Ctx.Installer = $cached.FullName
            Write-Skip "Installer already cached: $($cached.Name) ($([math]::Round($cached.Length/1MB,1)) MB)"
            Write-PhaseFooter 'P03' 'cached'
            return
        }
        if ($cached) {
            Write-Warn2 "Cached installer is suspiciously small ($([math]::Round($cached.Length/1MB,1)) MB) - re-downloading."
            Remove-Item $cached.FullName -Force
            Clear-PhaseMarker -Ctx $Ctx -PhaseId 'P03'
        } else {
            Write-Warn2 'Marker present but installer missing - re-running.'
        }
    }

    if ($Ctx.InstallerUrl) {
        Write-Step "Using user-supplied URL: $($Ctx.InstallerUrl)"
        $url = $Ctx.InstallerUrl
        $sourcePage = $null
    } else {
        Set-DebugStep 'resolve latest AMD Graphics Driver URL'
        Write-Step "Resolving latest AMD Graphics Driver URL ($($Ctx.AmdLandingUrls.Count) page(s))"
        # GPU/APU detection drives both URL probe order and branch
        #     selection (Vega-era APU -> 'vega-polaris' Legacy branch).
        # Branch decision uses richer codename/architecture info
        #     derived from docs.kernel.org AMD hardware list.
        # Codename is now ALSO extracted directly from AMD's own
        #     product spec page (the "Former Codename" field that AMD
        #     publishes on every CPU/APU/GPU page). When available
        #     this is the authoritative source - heuristics only run
        #     as a fallback when the page fetch fails or the codename
        #     isn't in our lookup table.
        $landing    = Get-AmdGraphicsLandingUrls -DefaultUrls $Ctx.AmdLandingUrls
        # Try to extract the AMD-published codename from the first
        # landing URL (which is the GPU/APU-derived product page when
        # detection succeeded). This adds 1-2 seconds of latency for
        # one HTTP fetch but yields a high-confidence answer.
        $amdCodename = $null
        if ($landing.Target -and $landing.LandingUrls.Count -gt 0) {
            try {
                Write-Host '    Querying AMD page for "Former Codename" field...' -ForegroundColor DarkGray
                $amdCodename = Get-AmdCodenameFromUrl -Url $landing.LandingUrls[0]
                if ($amdCodename) {
                    Write-Host ('                  -> AMD published codename: {0}' -f $amdCodename) -ForegroundColor Green
                } else {
                    Write-Host '                  -> codename not found on page (will use heuristic)' -ForegroundColor DarkGray
                }
            } catch {
                Write-Host ('                  -> page query failed: {0}' -f $_.Exception.Message) -ForegroundColor DarkGray
            }
        }
        $branchInfo = Get-AmdDriverBranchPreference -GpuTarget $landing.Target -Codename $amdCodename
        $branchPref = $branchInfo.Branch
        if ($landing.Target) {
            $confColor = switch ($branchInfo.Confidence) {
                'High'   { 'Cyan' }
                'Medium' { 'Yellow' }
                'Low'    { 'Yellow' }
                default  { 'DarkGray' }
            }
            Write-Host ('    Driver branch decision : {0,-7}  (confidence: {1}, source: {2})' -f `
                $branchInfo.Branch, $branchInfo.Confidence, $branchInfo.Source) -ForegroundColor $confColor
            if ($branchInfo.Codename) {
                Write-Host ('                             Codename     : {0}' -f $branchInfo.Codename) -ForegroundColor DarkGray
            }
            if ($branchInfo.Architecture) {
                Write-Host ('                             Architecture : {0}' -f $branchInfo.Architecture) -ForegroundColor DarkGray
            }
            Write-Host ('                             Reason       : {0}' -f $branchInfo.Reason) -ForegroundColor DarkGray
        }
        $info = Get-LatestAmdGraphicsUrl -LandingUrls $landing.LandingUrls -FallbackUrl $Ctx.AmdFallbackUrl -BranchPreference $branchPref
        Write-Host ''
        Write-Detail "Version    : $($info.Version)"
        Write-Detail "Source     : $($info.Source)"
        Write-Detail "Source page: $(if ($info.SourcePage) { $info.SourcePage } else { 'n/a' })"
        Write-Detail "URL        : $($info.Url)"
        $url = $info.Url
        $sourcePage = $info.SourcePage
    }

    $path = Join-Path $Ctx.Paths.Download (Split-Path $url -Leaf)

    # Pre-existing file check: only consider valid if size looks correct.
    if (Test-Path $path) {
        $existing = Get-Item $path
        if ($existing.Length -ge 5MB) {
            Write-Skip "Already cached: $path ($([math]::Round($existing.Length/1MB,1)) MB)"
            $Ctx.Installer = $path
            Set-PhaseMarker -Ctx $Ctx -PhaseId 'P03' -Metadata @{ Url=$url; Path=$path; SizeMB=[math]::Round($existing.Length/1MB,1) }
            Write-PhaseFooter 'P03' 'done'
            return
        }
        Write-Warn2 "Discarding undersized existing file ($([math]::Round($existing.Length/1MB,1)) MB)"
        Remove-Item $path -Force
    }

    # Download with browser-style headers. AMD's CDN serves the actual
    # binary only when User-Agent and (in some cases) Referer look like
    # a real browser; without these it returns a small redirect or
    # error HTML page (~200 KB), which causes confusing PE-extraction
    # errors downstream.
    $browserUA = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0 Safari/537.36'
    $headers = @{
        'User-Agent'      = $browserUA
        'Accept'          = '*/*'
        'Accept-Language' = 'en-US,en;q=0.9'
    }
    if ($sourcePage) {
        # Reconstruct the full landing-page URL we found this download on
        $referer = ($Ctx.AmdLandingUrls | Where-Object { $_ -match [regex]::Escape($sourcePage) } | Select-Object -First 1)
        if (-not $referer -and $Ctx.AmdLandingUrls.Count -gt 0) { $referer = $Ctx.AmdLandingUrls[0] }
        if ($referer) { $headers['Referer'] = $referer }
    } elseif ($Ctx.AmdLandingUrls.Count -gt 0) {
        $headers['Referer'] = $Ctx.AmdLandingUrls[0]
    }

    Set-DebugStep 'download AMD graphics installer'
    Write-Step "Downloading: $url"
    Write-Detail "User-Agent : (browser)" -Color DarkGray
    if ($headers.ContainsKey('Referer')) {
        Write-Detail "Referer    : $($headers['Referer'])" -Color DarkGray
    }

    try {
        Invoke-WebRequest -Uri $url -OutFile $path `
            -Headers $headers -UserAgent $browserUA `
            -MaximumRedirection 10 -UseBasicParsing -TimeoutSec 600
    } catch {
        throw "Download failed for $url : $($_.Exception.Message)"
    }

    $sizeBytes = (Get-Item $path).Length
    $sizeMB = [math]::Round($sizeBytes / 1MB, 1)

    # Sanity check: AMD chipset installers are 50-150 MB. Anything
    # smaller is almost certainly an error page or a redirect HTML
    # placeholder. Fail loudly here rather than letting the user hit
    # an opaque 7-Zip "Cannot open as PE archive" later.
    if ($sizeBytes -lt 5MB) {
        # Capture the first chunk of the response for diagnostics.
        $head = ''
        try { $head = (Get-Content $path -TotalCount 5 -ErrorAction SilentlyContinue) -join "`n" } catch { } # psa-disable-line PSA3004 -- intentional best-effort cleanup; no error to surface
        Remove-Item $path -Force -ErrorAction SilentlyContinue
        $msg = "Downloaded file is only $sizeMB MB (expected >50 MB). " +
               "AMD's CDN likely returned an error/redirect page rather than the installer. "
        if ($head -match '<html|<!DOCTYPE|<head') {
            $msg += 'Response appears to be HTML.  '
        }
        $msg += "Try passing -InstallerUrl with a known-good direct URL, or check that the AMD support page still serves this version."
        throw $msg
    }

    Write-Ok "Downloaded: $path ($sizeMB MB)"
    $Ctx.Installer = $path
    Set-PhaseMarker -Ctx $Ctx -PhaseId 'P03' -Metadata @{ Url=$url; Path=$path; SizeMB=$sizeMB }
    Write-PhaseFooter 'P03' 'done'
}

function Invoke-PrepPhase04_ExtractInstaller {
    param($Ctx)
    Write-PhaseHeader 'P04' 'ExtractInstaller' 'Prep'

    Set-DebugStep 'check phase marker (cache hit?)'
    if (Test-PhaseMarker -Ctx $Ctx -PhaseId 'P04') {
        Write-Skip "Extraction cached at $($Ctx.Paths.Extract)"
        Write-PhaseFooter 'P04' 'cached'
        return
    }

    Set-DebugStep 'precondition: installer present and valid size'
    if (-not $Ctx.Installer) {
        $cached = Get-ChildItem $Ctx.Paths.Download -Filter 'amd_chipset_software_*.exe' -ErrorAction SilentlyContinue |
                  Sort-Object LastWriteTime -Descending | Select-Object -First 1
        if (-not $cached) { throw 'No installer found - run Phase P03 first.' }
        $Ctx.Installer = $cached.FullName
    }
    if (-not $Ctx.SevenZip) { $Ctx.SevenZip = Get-SevenZipPath }

    # Sanity check: AMD chipset installers are normally 50-150 MB.
    # If the file is much smaller, the download was probably an
    # error page or got truncated, and any extraction will fail
    # confusingly. Bail out with an actionable message.
    $sizeBytes = (Get-Item $Ctx.Installer).Length
    $sizeMB = [math]::Round($sizeBytes / 1MB, 1)
    Write-Detail "Installer    : $($Ctx.Installer) ($sizeMB MB)"
    if ($sizeBytes -lt 5MB) {
        throw "Installer at $($Ctx.Installer) is only $sizeMB MB (expected >50 MB). The download may be corrupt or have served an error page. Re-run with -CleanWorkRoot to retry, or pass -InstallerUrl with a known-good URL."
    }

    # Idempotency: clean prior extraction so re-runs are deterministic
    if (Test-Path $Ctx.Paths.Extract) {
        Write-Step "Cleaning prior extraction at $($Ctx.Paths.Extract)"
        Get-ChildItem -LiteralPath $Ctx.Paths.Extract -Force -ErrorAction SilentlyContinue |
            Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
    }

    Set-DebugStep 'extract installer (multi-strategy + nested archives)'
    Write-Step 'Extracting installer (multiple strategies will be attempted)'
    Expand-AmdInstaller -InstallerPath $Ctx.Installer `
                        -DestinationPath $Ctx.Paths.Extract `
                        -SevenZipPath $Ctx.SevenZip
    Write-Ok "Extracted to: $($Ctx.Paths.Extract)"

    # Nested archives - covers MSIs/CABs from /layout, sub-installers
    # extracted by Strategy 3, etc.
    #
    # Previously this loop called 7-Zip with `2>$null | Out-Null`,
    # which silently swallowed any error. A corrupt or password-locked
    # nested archive would extract zero files and produce no visible
    # failure, mirroring the silent-fail pattern that bit us with
    # Copy-Item in earlier. We now capture $LASTEXITCODE and verify
    # that at least one file emerged. Exit codes for 7-Zip:
    #   0 = success
    #   1 = warning (non-fatal, e.g. some files locked but rest OK)
    #   2 = fatal error (corrupt archive, unsupported format, etc.)
    #   7 = command-line error
    #   8 = memory allocation failure
    #   255 = user interrupted
    # We treat exit <= 1 as acceptable and >= 2 as hard failure.
    $nested = Get-ChildItem -Path $Ctx.Paths.Extract -Recurse -Include *.msi,*.cab,*.7z,*.zip -ErrorAction SilentlyContinue
    foreach ($n in $nested) {
        $dest = Join-Path $n.DirectoryName ($n.BaseName + '__contents')
        if (Test-Path $dest) { continue }
        New-Item -ItemType Directory -Path $dest -Force | Out-Null
        Write-Detail "Nested: $($n.Name)" -Color DarkCyan

        & $Ctx.SevenZip x $n.FullName "-o$dest" -y -bsp0 -bso0 2>&1 | Out-Null
        $sevenZipExit = $LASTEXITCODE
        if ($sevenZipExit -ge 2) {
            throw ("7-Zip failed to extract nested archive '{0}' (exit={1}). Common causes: corrupt archive, password-protected payload, or unsupported nested format. Inspect '{2}' manually, or re-run with -CleanWorkRoot to fetch a fresh installer." -f $n.FullName, $sevenZipExit, $dest)
        }

        # 0 files extracted is suspicious but not always fatal: some
        # nested MSIs are metadata-only and legitimately produce no
        # payload. We log it but defer the final decision to the
        # downstream "0 INFs" guard, which catches the cases that
        # actually matter for the pipeline.
        $extractedCount = @(Get-ChildItem -LiteralPath $dest -Recurse -File -Force -ErrorAction SilentlyContinue).Count
        if ($extractedCount -eq 0) {
            Write-Warn2 ("      7-Zip exit={0} but 0 files extracted from {1} - flagged for downstream INF-count check" -f $sevenZipExit, $n.Name)
        } else {
            Write-Detail ("  -> exit={0}, {1} file(s) extracted" -f $sevenZipExit, $extractedCount) -Color DarkGray
        }
    }

    # Final verification: after all extraction and nested expansion,
    # we MUST have INF files - otherwise downstream phases (P05/P06/P08)
    # will silently process zero drivers and the user only learns about
    # the failure at P09 ("no.cat files"). Fail loudly here instead.
    Set-DebugStep 'verify extracted INF files (>= 1 required)'
    $infCount = @(Get-ChildItem -Path $Ctx.Paths.Extract -Recurse -Filter *.inf -ErrorAction SilentlyContinue).Count
    if ($infCount -eq 0) {
        # Diagnostic dump: list what we DID extract, to help triage.
        $diag = Get-ChildItem -Path $Ctx.Paths.Extract -Recurse -File -ErrorAction SilentlyContinue |
                Group-Object Extension |
                Sort-Object Count -Descending |
                Select-Object -First 10
        $summary = ($diag | ForEach-Object { "$($_.Name)=$($_.Count)" }) -join ', '
        throw "P04: extraction completed but produced 0 INF files in $($Ctx.Paths.Extract). Top extensions found: { $summary }. The AMD installer format may have changed - try a different version with -InstallerUrl, or inspect $($Ctx.Paths.Extract) manually."
    }
    Write-Ok "INF files found: $infCount"

    Set-PhaseMarker -Ctx $Ctx -PhaseId 'P04'
    Write-PhaseFooter 'P04' 'done'
}

function Get-AmdSourceVariant {
    # Classify an INF's relative path into the AMD installer's source-OS
    # variant family. AMD organizes drivers under sub-folders named after
    # the original Windows version they were built for:
    #
    # Chipset installer (Deploy-AMDChipsetDriver*):
    #   W11x64 = Windows 11 x64 (build 22000+, including 24H2 = 26100)
    #   WTx64 = Windows Threshold x64 (Windows 10, build 10240+)
    #
    # Graphics installer (Deploy-AMDGraphicsDriver* - this script):
    #   WT6A_INF = Display class drivers (display, OpenCL, Crash Defender,
    #              etc. - everything under Packages\Drivers\Display\)
    #   WT64A = Audio / SBDrv / RadeonLED drivers (everything under
    #              Packages\Drivers\Audio\, Packages\Drivers\SBDrv\,
    #              Packages\Drivers\RadeonLED\, etc.)
    #
    # The classification is purely path-based: we scan each path segment
    # and return the first matching token, case-insensitively.
    param([Parameter(Mandatory)] [string]$RelativePath)

    $segments = $RelativePath -split '[\\/]'
    foreach ($s in $segments) {
        $u = $s.ToUpperInvariant()
        # --- Chipset variants (legacy in this script; harmless to keep) ---
        if ($u -eq 'W11X64' -or $u.EndsWith('_W11X64') -or $u.EndsWith('-W11X64')) { return 'W11x64' }
        if ($u -eq 'WTX64'  -or $u.EndsWith('_WTX64')  -or $u.EndsWith('-WTX64'))  { return 'WTx64'  }
        # --- Graphics variants (display / audio / USB-C / RadeonLED) ---
        if ($u -eq 'WT6A_INF' -or $u.EndsWith('_WT6A_INF') -or $u.EndsWith('-WT6A_INF')) { return 'WT6A_INF' }
        if ($u -eq 'WT64A'    -or $u.EndsWith('_WT64A')    -or $u.EndsWith('-WT64A'))    { return 'WT64A'    }
    }
    return 'Unknown'
}

function Get-PreferredAmdSourceVariants { # psa-disable-line PSA6003 -- compound noun (e.g., Policies, Drivers, Catalogs) is semantically plural for set-returning helpers
    # Decide which AMD source-folder variants are in-scope for the given
    # host OS.
    #
    # Unlike the chipset installer (which has separate W11x64 / WTx64
    # trees and selects one based on host OS), the graphics installer
    # ships ONE tree per subsystem (WT6A_INF for display, WT64A for
    # audio/SBDrv/LED), so ALL recognized graphics variants are
    # in-scope on every Windows Server SKU. We also keep the chipset
    # variants in the in-scope list as a defense-in-depth measure -
    # if a hybrid AMD bundle ever ships both trees, we'd patch them
    # all on WS2022/WS2025 too. WTx64 (chipset Win10 tree) is omitted
    # on WS2022/WS2025 to avoid pulling in stale ABI files.
    param([Parameter(Mandatory)] [pscustomobject]$OsContext)

    switch ($OsContext.Code) {
        'WS2025' { return @('W11x64', 'WT6A_INF', 'WT64A') }
        'WS2022' { return @('W11x64', 'WT6A_INF', 'WT64A') }
        'WS2019' { return @('WTx64',  'WT6A_INF', 'WT64A') }
        'WS2016' { return @('WTx64',  'WT6A_INF', 'WT64A') }
        default  { return @('W11x64','WTx64','WT6A_INF','WT64A') }
    }
}

function Write-InfInventorySummary {
    # Render a human-readable per-variant listing of INFs to the
    # console: file name, relative directory, target device(s),
    # device class, and whether this INF is in-scope for the host OS.
    #
    # The display is grouped by SourceVariant. Selected variants
    # appear first (green), skipped variants appear in dim style.
    param(
        [Parameter(Mandatory)] $Detail,
        [Parameter(Mandatory)] [string[]]$PreferredVariants
    )

    $byVariant = $Detail | Group-Object SourceVariant | Sort-Object @{
        Expression = { if ($PreferredVariants -contains $_.Name) { 0 } else { 1 } }
    }, Name

    foreach ($g in $byVariant) {
        $isSelected = $PreferredVariants -contains $g.Name
        $hdrColor = if ($isSelected) { 'Cyan' } else { 'DarkGray' }
        $itemColor = if ($isSelected) { 'Gray' } else { 'DarkGray' }

        Write-Host ''
        Write-Detail ("+" + ("-" * 110)) -Color $hdrColor
        $marker = if ($isSelected) { '[SELECTED]' } else { '[ skip   ]' }
        Write-Detail ("| $marker Variant: {0}    {1} INF(s)    Patch in-scope: {2}" -f `
            $g.Name, $g.Count, $isSelected) -Color $hdrColor
        Write-Detail ("+" + ("-" * 110)) -Color $hdrColor

        # Sort INFs in this variant by relative directory then INF name
        $sorted = $g.Group | Sort-Object RelativeDir, Inf

        foreach ($i in $sorted) {
            # Compose primary device line. Show first device if any,
            # plus "(+N more)" if multiple devices.
            $primaryDev = $null
            $extraCount = 0
            if ($i.Devices -and $i.Devices.Count -gt 0) {
                $primaryDev = $i.Devices[0]
                $extraCount = $i.Devices.Count - 1
            }

            $infNameTrim = if ($i.Inf.Length -gt 32) { $i.Inf.Substring(0,29) + '...' } else { $i.Inf }
            $relDirShown = if ([string]::IsNullOrEmpty($i.RelativeDir)) { '.' } else { $i.RelativeDir }
            if ($relDirShown.Length -gt 60) { $relDirShown = '...' + $relDirShown.Substring($relDirShown.Length - 57) }

            Write-Detail ("{0,-32}  class={1,-12}  driverver={2}" -f `
                $infNameTrim, ($i.Class), ($i.DriverVer)) -Color $itemColor
            Write-Detail ("    dir   : {0}" -f $relDirShown) -Color DarkGray

            $providerShown = if ($i.Provider) { $i.Provider } else { '(unknown)' }
            $mfgShown      = if ($i.Manufacturer) { $i.Manufacturer } else { '(unknown)' }
            Write-Detail ("    prov  : {0}    mfg: {1}" -f $providerShown, $mfgShown) -Color DarkGray

            if ($primaryDev) {
                $extraSuffix = if ($extraCount -gt 0) { "  (+$extraCount more device variants)" } else { '' }
                $descShown = $primaryDev.Description
                if ($descShown -and $descShown.Length -gt 78) { $descShown = $descShown.Substring(0,75) + '...' }
                Write-Detail ("    device: {0}{1}" -f $descShown, $extraSuffix) -Color DarkGray
                $hwidShown = $primaryDev.HardwareId
                if ($hwidShown -and $hwidShown.Length -gt 78) { $hwidShown = $hwidShown.Substring(0,75) + '...' }
                Write-Detail ("    hwid  : {0}" -f $hwidShown) -Color DarkGray
            } else {
                # Distinguish "INF has no [Models]" from "[Models] scanned but parser couldn't extract devices"
                $scanned = if ($i.PSObject.Properties.Name -contains 'ModelsSectionsScanned') { [int]$i.ModelsSectionsScanned } else { 0 }
                $mfgEnt  = if ($i.PSObject.Properties.Name -contains 'ManufacturerEntries')   { [int]$i.ManufacturerEntries   } else { 0 }
                if ($scanned -gt 0) {
                    Write-Detail ("    device: (no device entries parsed; {0} [Models] section(s) scanned, {1} mfg entry(ies))" -f $scanned, $mfgEnt) -Color Yellow
                    Write-Detail ("             ^ INF format may use a non-standard LHS in [Models] (parser regressed?). V05/V06 may not match this INF's HWIDs.") -Color Yellow
                } else {
                    Write-Detail ("    device: (no device entries parsed)") -Color DarkGray
                }
            }
        }
    }
    Write-Host ''
}

function Export-InfInventoryReport {
    # Write a plain-text inventory report suitable for archiving or
    # pasting into change-management documentation. Unlike the CSV
    # (which is machine-readable), this format prioritises human
    # readability with full unwrapped lines and section headers.
    #
    # Port from chipset: SecureBootSnapshot (optional) appends a
    # UEFI Secure Boot baseline section at the end of the report. Pass
    # $Ctx.SecureBootBaseline captured at P00; if omitted, the appendix
    # is skipped silently.
    param(
        [Parameter(Mandatory)] $Detail,
        [Parameter(Mandatory)] [string[]]$PreferredVariants,
        [Parameter(Mandatory)] [string]$Path,
        [Parameter(Mandatory)] [string]$OsName,
        [Parameter()] $SecureBootSnapshot
    )

    $sb = New-Object System.Text.StringBuilder
    [void]$sb.AppendLine("AMD Graphics Driver - INF Inventory Report")
    [void]$sb.AppendLine(("=" * 78))
    [void]$sb.AppendLine("Generated      : $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")
    [void]$sb.AppendLine("Host OS        : $OsName")
    [void]$sb.AppendLine("Preferred variants: $($PreferredVariants -join ', ')")
    [void]$sb.AppendLine("Total INFs analyzed: $($Detail.Count)")
    [void]$sb.AppendLine('')

    $byVariant = $Detail | Group-Object SourceVariant | Sort-Object @{
        Expression = { if ($PreferredVariants -contains $_.Name) { 0 } else { 1 } }
    }, Name

    foreach ($g in $byVariant) {
        $isSelected = $PreferredVariants -contains $g.Name
        $marker = if ($isSelected) { '[SELECTED]' } else { '[ skip   ]' }
        [void]$sb.AppendLine(("=" * 78))
        [void]$sb.AppendLine("$marker  Variant: $($g.Name)    INFs in variant: $($g.Count)    In-scope: $isSelected")
        [void]$sb.AppendLine(("=" * 78))

        $sorted = $g.Group | Sort-Object RelativeDir, Inf
        foreach ($i in $sorted) {
            [void]$sb.AppendLine('')
            [void]$sb.AppendLine("INF        : $($i.Inf)")
            [void]$sb.AppendLine("Directory  : $($i.RelativeDir)")
            [void]$sb.AppendLine("Variant    : $($i.SourceVariant)    in-scope=$($i.VariantSelected)    needs-patch=$($i.NeedsPatch)")
            [void]$sb.AppendLine("Provider   : $($i.Provider)")
            [void]$sb.AppendLine("Class      : $($i.Class)    ClassGuid: $($i.ClassGuid)")
            [void]$sb.AppendLine("DriverVer  : $($i.DriverVer)")
            [void]$sb.AppendLine("Catalog    : $($i.CatalogFile)")
            [void]$sb.AppendLine("Mfg label  : $($i.Manufacturer)")
            [void]$sb.AppendLine("Devices    : $($i.DeviceCount)")
            if ($i.Devices) {
                $idx = 1
                foreach ($d in $i.Devices) {
                    [void]$sb.AppendLine(("  [{0,2}] {1}" -f $idx, $d.Description))
                    [void]$sb.AppendLine(("       hwid: {0}" -f $d.HardwareId))
                    $idx++
                }
            }
        }
        [void]$sb.AppendLine('')
    }

    # port: append UEFI Secure Boot baseline appendix at the END.
    if ($SecureBootSnapshot) {
        try {
            $appendix = Format-SecureBootBaselineForReport -Snapshot $SecureBootSnapshot
            if ($appendix) {
                [void]$sb.AppendLine('')
                [void]$sb.Append($appendix)
            }
        } catch {
            [void]$sb.AppendLine('')
            [void]$sb.AppendLine(("=" * 78))
            [void]$sb.AppendLine('UEFI Secure Boot Baseline (appendix render failed)')
            [void]$sb.AppendLine(("=" * 78))
            [void]$sb.AppendLine("Reason: $($_.Exception.Message)")
            [void]$sb.AppendLine('')
        }
    }

    Set-Content -LiteralPath $Path -Value $sb.ToString() -Encoding UTF8
}

function Invoke-PrepPhase05_AnalyzeInfs { # psa-disable-line PSA6003 -- compound noun (e.g., Policies, Drivers, Catalogs) is semantically plural for set-returning helpers
    param($Ctx)
    Write-PhaseHeader 'P05' 'AnalyzeInfs' 'Prep'

    Set-DebugStep 'check phase marker (cache hit?)'
    if (Test-PhaseMarker -Ctx $Ctx -PhaseId 'P05') {
        $csv = Join-Path $Ctx.Paths.Root 'inf_inventory.csv'
        if (Test-Path $csv) {
            $Ctx.InfInventory = Import-Csv $csv
            Write-Skip "Inventory cached: $csv ($($Ctx.InfInventory.Count) rows)"
            Write-PhaseFooter 'P05' 'cached'
            return
        }
    }

    Set-DebugStep 'enumerate INF files and select preferred variants'
    $infFiles = Get-ChildItem -Path $Ctx.Paths.Extract -Recurse -Filter *.inf -ErrorAction SilentlyContinue
    Write-Step "Analyzing $($infFiles.Count) INF files..."

    # Determine which AMD source-folder variants are appropriate
    # for THIS host OS.
    $preferredVariants = Get-PreferredAmdSourceVariants -OsContext $Ctx.Os
    # When running on a Workstation OS (e.g. Win11 24H2 used as a WS2025
    # preview), display BOTH the actual OS Caption and the Server profile
    # being applied. Previously only the profile name was shown, which made it
    # look like the script had mis-detected the host (e.g. "Host OS: Windows
    # Server 2025" while running on Win11 24H2).
    if ($Ctx.Os.ProductType -eq 1 -and $Ctx.Os.Caption) {
        Write-Detail "Host OS         : $($Ctx.Os.Caption)  [profile: $($Ctx.Os.Name)]" -Color DarkGray
    } else {
        Write-Detail "Host OS         : $($Ctx.Os.Name)" -Color DarkGray
    }
    Write-Detail "Preferred AMD source variant(s): $($preferredVariants -join ', ')" -Color DarkGray

    # Use the same parser V04 uses to check for server decorations.
    # The previous regex 'NTamd64\.10\.0\.3\.' was too strict (required
    # trailing dot, hardcoded version 10.0). Test-InfHasServerDecoration
    # walks the [Manufacturer] section and checks parts[3]=='3' on each
    # NT decoration, matching what P06 actually writes.
    Set-DebugStep 'parse each INF for Manufacturer / decorations / metadata'
    $detailReport = foreach ($inf in $infFiles) {
        $infData = Read-InfFile -Path $inf.FullName
        $rel = $inf.FullName.Substring($Ctx.Paths.Extract.Length).TrimStart('\')
        $variant = Get-AmdSourceVariant -RelativePath $rel
        $meta = Get-InfMetadata -Content $infData.Content
        $relDir = if ($rel.Contains('\')) { Split-Path $rel -Parent } else { '' }

        [pscustomobject]@{
            Inf             = $inf.Name
            FullPath        = $inf.FullName
            RelativePath    = $rel
            RelativeDir     = $relDir
            SourceVariant   = $variant
            VariantSelected = ($preferredVariants -contains $variant)
            Encoding        = $infData.EncodingName
            HasMfg          = ($infData.Content -match '\[Manufacturer\]')
            HasServerDeco   = (Test-InfHasServerDecoration -Content $infData.Content)
            NeedsPatch      = (
                ($infData.Content -match '\[Manufacturer\]') -and
                -not (Test-InfHasServerDecoration -Content $infData.Content) -and
                ($preferredVariants -contains $variant)
            )
            Provider        = $meta.Provider
            Class           = $meta.Class
            ClassGuid       = $meta.ClassGuid
            DriverVer       = $meta.DriverVer
            CatalogFile     = $meta.CatalogFile
            Manufacturer    = $meta.Manufacturer
            DeviceCount     = $meta.DeviceCount
            Devices         = $meta.Devices  # array of pscustomobject
            # Diagnostic fields (used by P05 display to detect parser/INF format mismatches):
            ManufacturerEntries   = $meta.ManufacturerEntries
            ModelsSectionsScanned = $meta.ModelsSectionsScanned
        }
    }
    # Stash the rich detail (with Devices array) on the context so
    # later phases / summaries can render device-level breakdowns
    # without re-parsing INFs.
    $Ctx.InfInventoryDetail = $detailReport

    # Build the CSV-friendly inventory (flat, no nested Devices array).
    # Devices are flattened into a "DeviceList" string for CSV export.
    $report = $detailReport | ForEach-Object {
        $deviceList = if ($_.Devices) {
            ($_.Devices | ForEach-Object { "$($_.Description)|$($_.HardwareId)" }) -join ' || '
        } else { '' }
        [pscustomobject]@{
            Inf             = $_.Inf
            RelativePath    = $_.RelativePath
            RelativeDir     = $_.RelativeDir
            SourceVariant   = $_.SourceVariant
            VariantSelected = $_.VariantSelected
            Encoding        = $_.Encoding
            HasMfg          = $_.HasMfg
            HasServerDeco   = $_.HasServerDeco
            NeedsPatch      = $_.NeedsPatch
            Provider        = $_.Provider
            Class           = $_.Class
            ClassGuid       = $_.ClassGuid
            DriverVer       = $_.DriverVer
            CatalogFile     = $_.CatalogFile
            Manufacturer    = $_.Manufacturer
            DeviceCount     = $_.DeviceCount
            DeviceList      = $deviceList
        }
    }
    Set-DebugStep 'export inventory CSV'
    $csvPath = Join-Path $Ctx.Paths.Root 'inf_inventory.csv'
    $report | Sort-Object NeedsPatch -Descending |
        Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8
    $Ctx.InfInventory = $report

    # Variant breakdown summary
    $byVariant = $report | Group-Object SourceVariant | Sort-Object Name
    Write-Host ''
    Write-Detail "INF inventory by source variant:" -Color DarkGray
    foreach ($g in $byVariant) {
        $selectedFlag = if ($preferredVariants -contains $g.Name) { '[SELECTED]' } else { '[ skip   ]' }
        $color = if ($preferredVariants -contains $g.Name) { 'Green' } else { 'DarkGray' }
        Write-Detail ("  $selectedFlag {0,-10} {1,3} INF(s)" -f $g.Name, $g.Count) -Color $color
    }
    Write-Host ''

    # ---- Per-variant detailed listing (human-readable) ----
    Write-InfInventorySummary -Detail $detailReport -PreferredVariants $preferredVariants

    # Write a more detailed flat report alongside the CSV, suitable
    # for pasting into change-management documents.
    Set-DebugStep 'export inventory text report'
    $reportTxtPath = Join-Path $Ctx.Paths.Root 'inf_inventory_report.txt'

    # Port from chipset: include UEFI Secure Boot baseline appendix.
    # Use Get-OrEnsureSecureBootBaseline so the diagnostic file is
    # guaranteed to be co-located with the workspace (re-captures into
    # $Ctx.WorkRoot if P00 wrote to TEMP or if P01 wiped the workspace).
    $sbSnapshot = Get-OrEnsureSecureBootBaseline -Ctx $Ctx
    Export-InfInventoryReport -Detail $detailReport -PreferredVariants $preferredVariants -Path $reportTxtPath -OsName $Ctx.Os.Name -SecureBootSnapshot $sbSnapshot

    $totalSelected = @($report | Where-Object NeedsPatch).Count
    $totalAll = $report.Count
    Write-Ok "Inventory: $csvPath ($totalAll total / $totalSelected selected for patching from $($preferredVariants -join '+'))"
    Write-Ok "Detail   : $reportTxtPath"
    Set-PhaseMarker -Ctx $Ctx -PhaseId 'P05' -Metadata @{ Total=$totalAll; Selected=$totalSelected; CsvPath=$csvPath; ReportPath=$reportTxtPath; Variants=($preferredVariants -join ',') }
    Write-PhaseFooter 'P05' 'done'
}

function Invoke-PrepPhase06_PatchInfs { # psa-disable-line PSA6003 -- compound noun (e.g., Policies, Drivers, Catalogs) is semantically plural for set-returning helpers
    param($Ctx)
    Write-PhaseHeader 'P06' 'PatchInfs' 'Prep'

    Set-DebugStep 'check phase marker (cache hit?)'
    if (Test-PhaseMarker -Ctx $Ctx -PhaseId 'P06') {
        Write-Skip "Patched INFs cached at $($Ctx.Paths.Patched)"
        Write-PhaseFooter 'P06' 'cached'
        return
    }

    Set-DebugStep 'precondition: load InfInventory (CSV fallback)'
    if (-not $Ctx.InfInventory) {
        $csv = Join-Path $Ctx.Paths.Root 'inf_inventory.csv'
        if (-not (Test-Path $csv)) { throw 'INF inventory missing - run Phase P05 first.' }
        $Ctx.InfInventory = Import-Csv $csv
    }

    # Apply the -SkipNonCosignedDrivers filter at P06 entry (added in the r71 release). Trimming
    # $Ctx.InfInventory here propagates to every downstream phase
    # (P06 patch, P07 cert, P08 catalog, V03/V04/V05/V06, I03 install)
    # without any additional integration sites. The filter is a no-op
    # when -SkipNonCosignedDrivers is absent. See SPEC SS D.31.
    if ($Script:SkipNonCosignedDrivers) {
        $beforeCount = @($Ctx.InfInventory).Count
        $Ctx.InfInventory = Get-EligibleInfRecordList -Ctx $Ctx -InfRecords $Ctx.InfInventory -SkipNonCosignedDrivers
        $afterCount = @($Ctx.InfInventory).Count
        $skipped = $beforeCount - $afterCount
        if ($skipped -gt 0) {
            Write-Host '--- r71: -SkipNonCosignedDrivers filter applied ---' -ForegroundColor Cyan
            Write-Host ('  Inventory trimmed: {0} INF(s) eligible / {1} non-WHQL-co-signed INF(s) skipped (kept Secure Boot ON safe).' -f $afterCount, $skipped) -ForegroundColor Yellow
            Write-Host '  Skipped INFs will not be patched, cataloged, signed, or installed by this run.' -ForegroundColor DarkYellow
            Set-DebugStep ('r71 SkipNonCosignedDrivers: trimmed {0} -> {1} INF(s)' -f $beforeCount, $afterCount)
        } else {
            Write-Detail '  r71: -SkipNonCosignedDrivers set but inventory is already fully WHQL co-signed (no trim).'
        }
    }

    Set-DebugStep 'idempotency: clean prior patched output'
    # Idempotency: clean -WorkRoot/patched
    if (Test-Path $Ctx.Paths.Patched) {
        Write-Step "Cleaning prior patched output at $($Ctx.Paths.Patched)"
        Get-ChildItem -LiteralPath $Ctx.Paths.Patched -Force -ErrorAction SilentlyContinue |
            Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
    }

    Set-DebugStep 'classify INFs: needsPatch vs copyOnly (variant-aware)'
    $needsPatch = @($Ctx.InfInventory | Where-Object { $_.NeedsPatch -eq $true -or $_.NeedsPatch -eq 'True' })

    # SELECTED variant INFs that don't need patching (= already
    # Server-compatible because their [Manufacturer] decoration has
    # parts[3]='' or '3'). These also belong in the install pipeline.
    #
    # EARLIER BUG (severity: high): only $needsPatch INFs were written
    # to $Ctx.Paths.Patched. The patching loop's `Copy-Item $srcFolder/*`
    # brought sibling INFs in the SAME folder along incidentally, but
    # any selected-variant INF in a SEPARATE folder was silently
    # dropped from V03/V04/V05/V06/I03 (which all scan patched/).
    #
    # IN GRAPHICS THIS HID 11 OF 19 INFS:
    # When u0197843.inf in WT6A_INF\ is patched, the wildcard copy
    # brings the 7 sibling subfolders (amdafd, amdocl,...) into
    # patched/, which is why WT6A_INF appeared to work end-to-end.
    # But the 11 WT64A INFs live in completely separate trees
    # (Audio\ACPAfd\WT64A\, Audio\HDABus\WT64A\,...) and NEVER got
    # copied. They include amdacpbus.inf (matches user's
    # PCI\VEN_1022&DEV_15E2 Audio CoProcessor) and AtihdWT6.inf
    # (matches HDAUDIO\...DEV_AA01 HD Audio Device), so the bug
    # silently suppressed real upgrade candidates.
    #
    # Mirrored from chipset.
    $copyOnly = @($Ctx.InfInventory | Where-Object {
        ($_.VariantSelected -eq $true -or $_.VariantSelected -eq 'True') -and
        -not ($_.NeedsPatch -eq $true -or $_.NeedsPatch -eq 'True')
    })

    # Show variant distribution of what will be patched (echoes what
    # P05 already showed, but useful here when running P06 standalone).
    $skippedAll = @($Ctx.InfInventory | Where-Object {
        # An INF is "out of scope for this host OS" only when
        # its source variant is NOT selected. Previously we lumped
        # already-universal selected-variant INFs into this category,
        # which mis-described them as "out of scope" and explained
        # why they never reached the install pipeline.
        ($_.VariantSelected -ne $true -and $_.VariantSelected -ne 'True')
    })
    $skippedByVariant = $skippedAll | Group-Object SourceVariant | Sort-Object Name
    if ($skippedByVariant) {
        $skipSummary = ($skippedByVariant | ForEach-Object { "$($_.Name)=$($_.Count)" }) -join ', '
        Write-Detail "Skipping $($skippedAll.Count) INF(s) not in scope for host OS: $skipSummary" -Color DarkGray
    }
    Write-Step "Patching $($needsPatch.Count) INF file(s)..."

    $results = @()
    Set-DebugStep 'patch each INF needing Server decorations (Edit-InfForServer)'
    foreach ($row in $needsPatch) {
        $src = Join-Path $Ctx.Paths.Extract $row.RelativePath
        $dst = Join-Path $Ctx.Paths.Patched $row.RelativePath
        $dstDir = Split-Path $dst -Parent
        if (-not (Test-Path $dstDir)) { New-Item -ItemType Directory -Path $dstDir -Force | Out-Null }
        $srcFolder = Split-Path $src -Parent
        Copy-Item -Path (Join-Path $srcFolder '*') -Destination $dstDir -Recurse -Force -Exclude $row.Inf
        try {
            $r = Edit-InfForServer -InfPath $src -OutputPath $dst -OsContext $Ctx.Os
            $r | Add-Member -NotePropertyName 'Inf' -NotePropertyValue $row.Inf -Force
            $r | Add-Member -NotePropertyName 'OutputPath' -NotePropertyValue $dst -Force
            $r | Add-Member -NotePropertyName 'SourceVariant' -NotePropertyValue $row.SourceVariant -Force
            $results += $r
            Write-Ok "Patched: $($row.Inf) [variant=$($row.SourceVariant) decorations=$($r.Decorations.Count) mirrored=$($r.SectionsMirrored)]"
        } catch {
            Write-Fail "$($row.Inf) [variant=$($row.SourceVariant)]: $($_.Exception.Message)"
        }
    }

    # Copy-only loop for already-Server-compatible INFs.
    Set-DebugStep 'copy already-Server-compatible INFs (no rewrite)'
    if ($copyOnly.Count -gt 0) {
        Write-Step "Copying $($copyOnly.Count) already-Server-compatible INF file(s) (no patching needed)..."
        $copiedCount = 0
        foreach ($row in $copyOnly) {
            $src = Join-Path $Ctx.Paths.Extract $row.RelativePath
            $dst = Join-Path $Ctx.Paths.Patched $row.RelativePath
            $dstDir = Split-Path $dst -Parent
            if (-not (Test-Path $dstDir)) { New-Item -ItemType Directory -Path $dstDir -Force | Out-Null }
            $srcFolder = Split-Path $src -Parent
            try {
                # Copy the entire source folder. -Force makes the copy
                # idempotent if a sibling INF was already brought in by
                # the patching loop's wildcard copy above.
                Copy-Item -Path (Join-Path $srcFolder '*') -Destination $dstDir -Recurse -Force
                $copiedCount++
            } catch {
                Write-Warn2 "Copy failed for $($row.Inf): $($_.Exception.Message)"
            }
        }
        Write-Ok "Copied $copiedCount of $($copyOnly.Count) Server-compatible INF(s) to patched/"
    }

    $Ctx.PatchResults = $results
    Set-PhaseMarker -Ctx $Ctx -PhaseId 'P06' -Metadata @{
        Patched=$results.Count
        Copied =$copyOnly.Count   # diagnostic field
    }
    Write-PhaseFooter 'P06' 'done'
}

function Invoke-PrepPhase07_CreateCertificate {
    param($Ctx)
    Write-PhaseHeader 'P07' 'CreateCertificate' 'Prep'

    $pfxPath = Join-Path $Ctx.Paths.Cert 'AMD-Graphics-Driver-CodeSign.pfx'
    $cerPath = Join-Path $Ctx.Paths.Cert 'AMD-Graphics-Driver-CodeSign.cer'

    # Subject (CN) - emphasises that this is a self-signed test cert,
    # NOT an official AMD or Microsoft-issued certificate, and is
    # SCOPED to the chipset-driver workflow so a future graphics-driver
    # companion script can safely run with its own cert in parallel
    # without trust-store ambiguity:
    #   - "Chipset": driver category (coexists with Graphics script)
    #   - "Self-Signed": technical clarity (no CA chain of trust)
    #   - "At Own Risk": explicit personal-responsibility disclaimer
    # Length is kept at or below 64 characters to satisfy the X.509
    # printable-string practical limit recommended by RFC 5280.
    $subject = "CN=AMD Graphics Driver Self-Sign ($($Ctx.Os.Code) Lab, At Own Risk)"

    Set-DebugStep 'check phase marker (cache hit?)'
    if ((Test-PhaseMarker -Ctx $Ctx -PhaseId 'P07') -and (Test-Path $pfxPath)) {
        $Ctx.CertPfxPath = $pfxPath
        $Ctx.CertCerPath = $cerPath
        Write-Skip "Certificate cached: $pfxPath"
        Write-PhaseFooter 'P07' 'cached'
        return
    }

    Set-DebugStep 'cleanup previous cert artifacts'
    # Idempotency: remove old cert files
    Get-ChildItem -Path $Ctx.Paths.Cert -Force -ErrorAction SilentlyContinue | Remove-Item -Force

    # Always create a fresh self-signed certificate. Before creation,
    # scan LocalMachine\My for any pre-existing certificates that
    # share the same Subject ("same-named" cert) and delete them
    # explicitly. This prevents the personal certificate store from
    # accumulating duplicates over multiple runs of P07, and makes the
    # cleanup auditable: each deletion is logged with its thumbprint
    # and not-after date. We only touch LocalMachine\My (where this
    # script registers its certs); TrustedRoot and TrustedPublisher
    # are managed by I01 separately and are not modified here.
    $preexisting = @(Get-ChildItem Cert:\LocalMachine\My -ErrorAction SilentlyContinue |
        Where-Object { $_.Subject -eq $subject })

    if ($preexisting.Count -gt 0) {
        Write-Warn2 ("Found {0} existing certificate(s) in LocalMachine\My with the same Subject - deleting before re-creation" -f $preexisting.Count)
        foreach ($oldCert in $preexisting) {
            $line = '    Deleting : thumbprint={0}  not-after={1:yyyy-MM-dd}  friendly-name="{2}"' -f `
                $oldCert.Thumbprint, $oldCert.NotAfter, $oldCert.FriendlyName
            Write-Host $line -ForegroundColor DarkGray
            try {
                Remove-Item -LiteralPath ("Cert:\LocalMachine\My\{0}" -f $oldCert.Thumbprint) -Force -ErrorAction Stop
            } catch {
                Write-Warn2 ("    Failed to delete {0}: {1}" -f $oldCert.Thumbprint, $_.Exception.Message)
                throw "P07: cannot remove existing cert $($oldCert.Thumbprint) from LocalMachine\My. Run as Administrator and try again."
            }
        }
        Write-Ok ("Deleted {0} same-subject certificate(s) from LocalMachine\My" -f $preexisting.Count)
    }

    Set-DebugStep 'New-SelfSignedCertificate (RSA / code-signing)'
    # Now create the fresh certificate
    $params = @{
        Subject = $subject; Type = 'CodeSigningCert'
        KeySpec = 'Signature'; KeyUsage = 'DigitalSignature'
        KeyAlgorithm = 'RSA'; KeyLength = $Ctx.Os.CertKeyLength
        HashAlgorithm = $Ctx.Os.CertHashAlgorithm
        NotAfter = (Get-Date).AddYears($Ctx.Os.CertValidYears)
        CertStoreLocation = 'Cert:\LocalMachine\My'
        # FriendlyName: not size-constrained; we can be more verbose
        # here than in the Subject CN. Make the warning extremely
        # obvious in the Windows Certificate Manager UI display.
        FriendlyName = "AMD Graphics Driver Codesign ($($Ctx.Os.Code) Self-Signed Lab - Personal Use, At Own Risk)"
    }
    if ($Ctx.Os.UseModernCertExtension) {
        $params.TextExtension = @('2.5.29.37={text}1.3.6.1.5.5.7.3.3')
    }
    $cert = New-SelfSignedCertificate @params
    Write-Ok "Created cert $($cert.Thumbprint)"
    Write-Detail "Subject: $subject"
    Write-Detail "Key    : RSA $($Ctx.Os.CertKeyLength) / $($Ctx.Os.CertHashAlgorithm)"
    Write-Detail "Valid  : $($Ctx.Os.CertValidYears) years"
    Write-Host ''
    Write-Host '    *** SELF-SIGNED CERTIFICATE - PERSONAL VERIFICATION USE ONLY ***' -ForegroundColor Yellow
    Write-Host '    This is NOT issued by a CA or by AMD/Microsoft. It is generated' -ForegroundColor DarkYellow
    Write-Host '    locally on this machine for lab/personal verification purposes.' -ForegroundColor DarkYellow
    Write-Host '    Use is at your own risk; do not deploy outside this lab system.' -ForegroundColor DarkYellow

    Set-DebugStep 'export PFX and CER files'
    $secPwd = ConvertTo-SecureString -String $Ctx.PfxPassword -AsPlainText -Force
    Export-PfxCertificate -Cert $cert -FilePath $pfxPath -Password $secPwd -Force | Out-Null
    Export-Certificate    -Cert $cert -FilePath $cerPath -Force | Out-Null
    Write-Ok "PFX exported: $pfxPath"
    Write-Ok "CER exported: $cerPath"
    Write-Host '    NOTE: cert is NOT yet in Trusted Root / Trusted Publisher.'
    Write-Host '          Run -Action Install (or phase I01) to import it.'

    $Ctx.CertPfxPath  = $pfxPath
    $Ctx.CertCerPath  = $cerPath
    $Ctx.CertThumbprint = $cert.Thumbprint
    Set-PhaseMarker -Ctx $Ctx -PhaseId 'P07' -Metadata @{ Thumbprint=$cert.Thumbprint; Subject=$subject }
    Write-PhaseFooter 'P07' 'done'
}

function Get-Inf2catVersion {
    # Retrieve version information for the inf2cat.exe binary.
    #
    # inf2cat itself has no /version switch, so we read the EXE's
    # embedded version metadata via System.Diagnostics.FileVersionInfo.
    # Returns a [pscustomobject] with:
    #   FileVersion - dotted version like "10.0.26100.1"
    #   ProductVersion - same or similar
    #   ProductName - usually "Microsoft Windows Operating System"
    #   FileDescription - usually "Driver Catalog File Generator Tool"
    #   FullPath - resolved path to the executable
    # Returns $null if the file is missing or metadata can't be read.
    param([Parameter(Mandatory)] [string]$Inf2catPath)

    if (-not (Test-Path -LiteralPath $Inf2catPath)) { return $null }
    try {
        $info = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($Inf2catPath)
        return [pscustomobject]@{
            FileVersion     = $info.FileVersion
            ProductVersion  = $info.ProductVersion
            ProductName     = $info.ProductName
            FileDescription = $info.FileDescription
            FullPath        = (Resolve-Path -LiteralPath $Inf2catPath).Path
        }
    } catch {
        return $null
    }
}

function Get-Inf2catSupportedOsValues { # psa-disable-line PSA6003 -- compound noun (e.g., Policies, Drivers, Catalogs) is semantically plural for set-returning helpers
    # Probe inf2cat to discover the /os values it actually accepts.
    #
    # SDK 10.0.26100 changed the /os value format - it dropped the
    # underscore separator (e.g. "10_X64" -> "10X64"). Older SDKs
    # use the underscored form. Rather than hard-code a list per
    # SDK build, we just ask inf2cat itself by running it with /?.
    #
    # Returns: array of /os values inf2cat reported as valid.
    #          Returns empty array if probe fails (caller should fall
    #          back to its hard-coded candidate list).
    param([Parameter(Mandatory)] [string]$Inf2catPath)

    try {
        $help = & $Inf2catPath '/?' 2>&1
    } catch {
        return @()
    }
    if (-not $help) { return @() }

    $helpText = ($help | Out-String)

    # The help output lists supported OS values in a section like:
    #   /os {os1,os2,...,osN}
    # or each on its own line. We grab anything that looks like an
    # /os token: alphanumerics, optionally with one underscore and
    # an architecture suffix (X64, X86, ARM, ARM64, IA64).
    $tokens = [regex]::Matches($helpText, '\b([A-Za-z][A-Za-z0-9]*_?(?:X64|X86|ARM64|ARM|IA64))\b') |
              ForEach-Object { $_.Groups[1].Value } |
              Select-Object -Unique

    # Filter out obviously-not-OS tokens that pattern-match (e.g.
    # 'AMD64' in some help text). Keep tokens that look like OS
    # platform names: must contain a digit OR a known prefix.
    $valid = $tokens | Where-Object {
        $_ -match '\d' -or $_ -match '^(Server|Vista|XP|RS|TH)'
    }
    return @($valid)
}

function Invoke-PrepPhase08_GenerateCatalogs { # psa-disable-line PSA6003 -- compound noun (e.g., Policies, Drivers, Catalogs) is semantically plural for set-returning helpers
    param($Ctx)
    Write-PhaseHeader 'P08' 'GenerateCatalogs' 'Prep'

    Set-DebugStep 'precondition: Patched dir + inf2cat available'
    if (-not (Test-Path $Ctx.Paths.Patched)) { throw 'Patched dir missing - run P06 first.' }
    if (-not $Ctx.Inf2cat) { $Ctx.Inf2cat = Find-KitTool 'inf2cat.exe' }
    if (-not $Ctx.Inf2cat) { throw 'inf2cat.exe not found - run P02 first.' }

    Set-DebugStep 'check phase marker (cache hit?)'
    if (Test-PhaseMarker -Ctx $Ctx -PhaseId 'P08') {
        Write-Skip "Catalogs already generated (cached)."
        Write-PhaseFooter 'P08' 'cached'
        return
    }

    Set-DebugStep 'enumerate INF-bearing directories under patched/'
    $infDirs = @(Get-ChildItem -Path $Ctx.Paths.Patched -Recurse -Directory |
        Where-Object {
            (Get-ChildItem -LiteralPath $_.FullName -Filter *.inf -ErrorAction SilentlyContinue).Count -gt 0
        })

    # Early-fail if the patched directory has nothing to process.
    # This catches the common case where the user runs P08 in
    # isolation (e.g. -OnlyPhases P08,P09) before P06 has produced
    # patched output, OR when P06 was wiped/cleared between runs.
    # Without this check P08 would silently succeed with 0/0,
    # leaving P09 to fail with the cryptic "no.cat files found"
    # error.
    if ($infDirs.Count -eq 0) {
        $allDirs = @(Get-ChildItem -Path $Ctx.Paths.Patched -Recurse -Directory -ErrorAction SilentlyContinue)
        $allInfs = @(Get-ChildItem -Path $Ctx.Paths.Patched -Recurse -Filter *.inf -ErrorAction SilentlyContinue)

        Write-Host ''
        Write-Warn2 "P08: no INF-bearing directories found under the patched root."
        Write-Detail  "Patched root         : $($Ctx.Paths.Patched)" -Color DarkGray
        Write-Detail  "Subdirectories found : $($allDirs.Count)" -Color DarkGray
        Write-Detail  ".inf files found     : $($allInfs.Count)" -Color DarkGray
        if ($allInfs.Count -gt 0) {
            Write-Host '    First few .inf paths:' -ForegroundColor DarkGray
            $allInfs | Select-Object -First 5 | ForEach-Object {
                Write-Detail "  $($_.FullName)" -Color DarkGray
            }
        } else {
            Write-Host '    (no .inf files exist anywhere under patched root)' -ForegroundColor DarkGray
        }
        Write-Host ''
        Write-Host '    Likely causes:' -ForegroundColor Yellow
        Write-Host '      1. P06 (PatchInfs) was never run for the current workspace.' -ForegroundColor Yellow
        Write-Host '      2. The workspace was cleaned between P06 and P08.' -ForegroundColor Yellow
        Write-Host '      3. -OnlyPhases P08 was used without first running P02..P06.' -ForegroundColor Yellow
        Write-Host ''
        Write-Host '    To fix:' -ForegroundColor Cyan
        Write-Host '      .\Deploy-AMDGraphicsDriverOnWindowsServer.ps1 -CleanWorkRoot' -ForegroundColor Cyan
        Write-Host '        - or -' -ForegroundColor Cyan
        Write-Host '      .\Deploy-AMDGraphicsDriverOnWindowsServer.ps1 -OnlyPhases P03,P04,P05,P06 -Force' -ForegroundColor Cyan
        Write-Host ''

        throw "P08: patched directory has no INFs to catalog. Run preparation phases first (see guidance above)."
    }

    # ============================================================
    # PRE-FLIGHT: determine the SINGLE /os switch we will use.
    # ============================================================
    # The /os switch tells inf2cat which target OS the catalog is
    # being signed for. Since this script's purpose is to enable
    # AMD chipset drivers on a SPECIFIC Windows Server host (the
    # one we're running on), there is exactly ONE correct value:
    # the one matching the host OS.
    #
    # IMPORTANT: do not confuse the AMD installer's source folder
    # names (W11x64, WTx64) with the inf2cat /os value. The folder
    # names indicate AMD's internal source-OS classification of the
    # driver bits; the /os switch selects the catalog's TARGET OS.
    # We always target the host (e.g. Server2025_X64), regardless
    # of which AMD source folder the INF was extracted from.
    #
    # We probe inf2cat /? to discover what /os values this build
    # of inf2cat supports, then pick the host-matching value with
    # graceful fallback only if the precise value isn't available.

    Set-DebugStep 'select inf2cat /os switch (probe + match host OS)'
    $hostPreferred = $Ctx.Os.Inf2catOsArg
    $hostFallbacks = @($Ctx.Os.Inf2catOsArgFallbacks)
    if (-not $hostPreferred) {
        throw "P08: OS profile $($Ctx.Os.Code) has no Inf2catOsArg defined."
    }

    Write-Host ''
    Write-Detail "=== inf2cat /os switch selection ===" -Color Cyan
    Write-Detail "Host OS              : $($Ctx.Os.Name) (build $($Ctx.Os.Build))" -Color Gray

    # ---- inf2cat tool identification ----
    # Show the path and embedded version metadata of the inf2cat
    # binary we will use. This makes it easy to tell which Windows
    # SDK version provided the catalog generator (the supported
    # /os values list depends on this).
    $inf2catVer = Get-Inf2catVersion -Inf2catPath $Ctx.Inf2cat
    if ($inf2catVer) {
        Write-Detail "inf2cat tool         : $($inf2catVer.FullPath)" -Color Gray
        Write-Detail "inf2cat description  : $($inf2catVer.FileDescription)" -Color DarkGray
        Write-Detail "inf2cat file version : $($inf2catVer.FileVersion)" -Color DarkGray
        if ($inf2catVer.ProductVersion -and ($inf2catVer.ProductVersion -ne $inf2catVer.FileVersion)) {
            Write-Detail "inf2cat product ver  : $($inf2catVer.ProductVersion)" -Color DarkGray
        }
    } else {
        Write-Warn2 "    inf2cat tool path    : $($Ctx.Inf2cat) (version metadata unavailable)"
    }

    Write-Detail "Preferred /os switch : $hostPreferred" -Color Gray
    if ($hostFallbacks.Count -gt 0) {
        Write-Detail "Configured fallbacks : $($hostFallbacks -join ', ')" -Color Gray
    }

    Write-Detail "Probing inf2cat /? for supported /os values..." -Color DarkGray
    $supportedByTool = @(Get-Inf2catSupportedOsValues -Inf2catPath $Ctx.Inf2cat)
    if ($supportedByTool.Count -eq 0) {
        Write-Warn2 "    Could not parse inf2cat help output - will try preferred value blindly."
    }

    # Pick the actual switch we'll use:
    # 1. If the preferred value is in the tool's supported list -> use it.
    # 2. Otherwise scan fallbacks in order for the first supported one.
    # 3. If neither match (or probe failed), use the preferred value as-is
    #    (will fail loudly downstream rather than silently picking wrong OS).
    $chosenOs = $null
    $chosenReason = $null
    if ($supportedByTool.Count -eq 0) {
        $chosenOs = $hostPreferred
        $chosenReason = 'preferred (tool probe failed - using preferred as-is)'
    } elseif ($supportedByTool -contains $hostPreferred) {
        $chosenOs = $hostPreferred
        $chosenReason = "preferred value matches host OS exactly and is supported by this inf2cat"
    } else {
        foreach ($fb in $hostFallbacks) {
            if ($supportedByTool -contains $fb) {
                $chosenOs = $fb
                $chosenReason = "fallback (preferred '$hostPreferred' is not supported by this inf2cat)"
                break
            }
        }
    }

    # ---- Display the full list of supported /os values ----
    if ($supportedByTool.Count -gt 0) {
        Write-Detail "inf2cat reports $($supportedByTool.Count) supported /os value(s):" -Color DarkGray

        # Categorize values for readability:
        #   Server X64 - Windows Server x64 builds (our primary interest)
        #   Server ARM64 - Windows Server ARM64 builds
        #   Server other - Server SKUs on other architectures (X86, IA64)
        #   Client - XP/Vista/etc client builds
        $categories = [ordered]@{
            'Windows Server x64'      = @($supportedByTool | Where-Object { $_ -like 'Server*_X64' })
            'Windows Server ARM64'    = @($supportedByTool | Where-Object { $_ -like 'Server*_ARM64' })
            'Windows Server (other)'  = @($supportedByTool | Where-Object { $_ -like 'Server*' -and $_ -notlike 'Server*_X64' -and $_ -notlike 'Server*_ARM64' })
            'Other (Client/legacy)'   = @($supportedByTool | Where-Object { $_ -notlike 'Server*' })
        }

        foreach ($cat in $categories.Keys) {
            $values = $categories[$cat]
            if ($values.Count -eq 0) { continue }
            Write-Host ('      [{0}] ({1})' -f $cat, $values.Count) -ForegroundColor DarkCyan
            # Display 4 values per line, padded for alignment
            $line = '        '
            $i = 0
            foreach ($v in $values) {
                # Decorate the value:
                #   * = chosen for use
                #   . = configured fallback for this OS
                #   (space) = other supported value
                $marker = '  '
                $color = 'DarkGray'
                if ($v -eq $chosenOs) {
                    $marker = '* '   # chosen
                    $color = 'Green'
                } elseif ($hostPreferred -eq $v -or $hostFallbacks -contains $v) {
                    $marker = '. '   # configured but not chosen
                    $color = 'Cyan'
                }
                # Output one value at a time (in-place) so we can color
                # individual entries. NoNewline keeps them on same row.
                Write-Host ('  {0}{1,-18}' -f $marker, $v) -NoNewline -ForegroundColor $color
                $i++
                if ($i % 4 -eq 0) { Write-Host '' }
            }
            if ($i % 4 -ne 0) { Write-Host '' }
        }
        Write-Host '      Legend: ' -NoNewline -ForegroundColor DarkGray
        Write-Host '* selected' -NoNewline -ForegroundColor Green
        Write-Host '  ' -NoNewline -ForegroundColor DarkGray
        Write-Host '. configured fallback' -NoNewline -ForegroundColor Cyan
        Write-Host '  (other = available but unused)' -ForegroundColor DarkGray
    }

    if (-not $chosenOs) {
        throw "P08: cannot select an /os value compatible with $($Ctx.Os.Name). Preferred '$hostPreferred' and fallbacks ($($hostFallbacks -join ', ')) are all absent from inf2cat's supported list. Available values: $($supportedByTool -join ', ')"
    }

    Write-Host ''
    Write-Detail "-> Selected /os : " -Color Cyan -NoNewline
    Write-Host $chosenOs -ForegroundColor Green
    Write-Detail "   Reason       : $chosenReason" -Color DarkGray
    Write-Host ''
    Write-Detail "All inf2cat invocations in P08 will use ONLY: /os:$chosenOs" -Color DarkGray
    Write-Detail "No per-INF switch alternation. The /os switch selects the" -Color DarkGray
    Write-Detail "catalog's target OS (= host), not the INF's source folder." -Color DarkGray
    Write-Host ''

    Write-Step "Generating catalogs for $($infDirs.Count) INF folder(s) using /os:$chosenOs"

    $okCount = 0; $failCount = 0
    $failureSamples = @()  # collect first few failures' log content for summary

    Set-DebugStep 'run inf2cat per INF directory (multi-folder loop)'
    foreach ($dir in $infDirs) {
        # Idempotency: clean any prior.cat
        Get-ChildItem -LiteralPath $dir.FullName -Filter *.cat -ErrorAction SilentlyContinue | Remove-Item -Force

        # Build a UNIQUE log file name. Multiple INF dirs share base names
        # like "W11x64", so $dir.Name alone collides and overwrites earlier
        # logs. Use the full relative path (with separators flattened).
        $rel = $dir.FullName.Substring($Ctx.Paths.Patched.Length).TrimStart('\','/').Replace('\','_').Replace('/','_')
        if ($rel.Length -eq 0) { $rel = $dir.Name }
        if ($rel.Length -gt 80) { $rel = $rel.Substring(0,80) }
        $rel = ($rel -replace '[^A-Za-z0-9_.\-]','_')
        $logFile = Join-Path $Ctx.Paths.Logs ("inf2cat_{0}.log" -f $rel)

        # Detect this INF folder's AMD source variant (W11x64 / WTx64 /
        # Unknown) so we can surface it in logs. Folders that survived
        # P05/P06 filtering must be in the host's preferred-variants
        # set, but we still display the variant for traceability.
        $relForVariant = $dir.FullName.Substring($Ctx.Paths.Patched.Length).TrimStart('\','/')
        $variant = Get-AmdSourceVariant -RelativePath $relForVariant

        # Single-shot invocation with the chosen /os switch.
        #
        # We use System.Diagnostics.ProcessStartInfo directly instead of
        # Start-Process. Reason: 28 of 32 W11x64 INF directories have
        # SPACES in their paths (e.g. "GPIO Promontory Driver",
        # "PMF_8000Series Driver", "Wireless Button Driver"). PowerShell
        # 5.1's Start-Process -ArgumentList does not reliably quote
        # array items containing spaces - the result is that inf2cat
        # receives split arguments and reports
        # "Parameter format not correct."
        #
        # By building the command line ourselves and calling
        # [Process]::Start with a manually-quoted Arguments string,
        # we guarantee inf2cat sees exactly:
        #   inf2cat /driver:"C:\path with spaces" /os:Server2025_X64 /v
        # which is the documented invocation form.
        $cmdLine = '/driver:"{0}" /os:{1} /v' -f $dir.FullName, $chosenOs

        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = $Ctx.Inf2cat
        $psi.Arguments = $cmdLine
        $psi.UseShellExecute = $false
        $psi.RedirectStandardOutput = $true
        $psi.RedirectStandardError = $true
        $psi.CreateNoWindow = $true
        $psi.WorkingDirectory = (Split-Path $Ctx.Inf2cat -Parent)

        $exit = $null
        $stdoutText = ''
        $stderrText = ''
        $launchError = $null
        try {
            $proc = [System.Diagnostics.Process]::Start($psi)
            # ReadToEndAsync prevents deadlocks if both streams fill at
            # the same time (sync ReadToEnd on stdout while stderr is
            # blocked waiting for buffer drain would deadlock).
            $stdoutTask = $proc.StandardOutput.ReadToEndAsync()
            $stderrTask = $proc.StandardError.ReadToEndAsync()
            $proc.WaitForExit()
            $stdoutText = $stdoutTask.Result
            $stderrText = $stderrTask.Result
            $exit = $proc.ExitCode
            $proc.Dispose()
        } catch {
            $launchError = $_.Exception.Message
            $stderrText = "Failed to launch inf2cat: $launchError"
        }

        # Write per-folder log with full output of the single attempt.
        # Include the exact command line for traceability/debugging.
        $logBuilder = New-Object System.Text.StringBuilder
        [void]$logBuilder.AppendLine("=== /os:$chosenOs (exit=$exit) [variant=$variant] ===")
        [void]$logBuilder.AppendLine("Command: `"$($Ctx.Inf2cat)`" $cmdLine")
        [void]$logBuilder.AppendLine('')
        if ($stdoutText) { [void]$logBuilder.AppendLine($stdoutText) }
        if ($stderrText) {
            [void]$logBuilder.AppendLine('--- stderr ---')
            [void]$logBuilder.AppendLine($stderrText)
        }
        Set-Content -LiteralPath $logFile -Value $logBuilder.ToString() -Encoding UTF8

        # inf2cat exits 0 on full success, 1 on warnings-only success.
        $succeeded = ($null -ne $exit -and ($exit -eq 0 -or $exit -eq 1))

        if ($succeeded) {
            $okCount++
            Write-Detail "inf2cat: [$variant] $rel" -Color DarkGray
            Write-Ok "  ok (exit=$exit)"
        } else {
            $failCount++
            $exitDisplay = if ($null -eq $exit) { 'launch-failed' } else { $exit }
            Write-Detail "inf2cat: [$variant] $rel" -Color DarkGray
            Write-Warn2 "  FAILED (exit=$exitDisplay)"
            Write-Detail "  log : $logFile" -Color DarkGray

            # Capture failure details for end-of-phase summary.
            # Strategy:
            #   1. Try to find lines with error keywords (any locale).
            #   2. If that yields nothing (silent failure), grab the
            #      first non-blank lines of stdout/stderr instead - we
            #      always want SOMETHING to show the user.
            if ($failureSamples.Count -lt 3) {
                $allLines = $logBuilder.ToString() -split "`r?`n" |
                    Where-Object { $_.Trim().Length -gt 0 }
                $errorLines = @($allLines |
                    Where-Object { $_ -match '(?i)\b(error|warning|fail|invalid|unsupported|not\s+found|missing|cannot|could\s+not|unable|reject)\b' } |
                    Select-Object -First 8)
                if ($errorLines.Count -eq 0) {
                    # Fallback: just take the first few non-blank lines
                    # (excluding our own "=== /os:..." header)
                    $errorLines = @($allLines |
                        Where-Object { -not $_.StartsWith('===') -and -not $_.StartsWith('---') } |
                        Select-Object -First 8)
                    if ($errorLines.Count -eq 0) {
                        $errorLines = @('(no output captured - inf2cat exited silently)')
                    }
                }
                $failureSamples += [pscustomobject]@{
                    Dir   = $rel
                    Exit  = $exitDisplay
                    Lines = $errorLines
                    LogFile = $logFile
                }
            }
        }
    }

    # End-of-phase failure summary: always print if any failures
    # occurred. Show the actual log content for the first failure in
    # full (most useful for diagnosis), and excerpts for the next 2.
    if ($failCount -gt 0 -and $failureSamples.Count -gt 0) {
        Write-Host ''
        Write-Warn2 "Sample failure details (first $($failureSamples.Count) of $failCount):"
        Write-Host ''
        $idx = 0
        foreach ($s in $failureSamples) {
            $idx++
            Write-Host "  [Sample $idx of $($failureSamples.Count)] [$($s.Dir)] exit=$($s.Exit)" -ForegroundColor Yellow
            Write-Detail "log file: $($s.LogFile)" -Color DarkGray
            foreach ($l in $s.Lines) {
                Write-Detail "| $l" -Color DarkYellow
            }
            Write-Host ''
        }

        # Dump the FIRST failed INF's full log content to the screen.
        # This is the single most useful diagnostic for the user when
        # they don't have time to inspect each log file individually.
        if ($failureSamples[0].LogFile -and (Test-Path $failureSamples[0].LogFile)) {
            Write-Host '  Full log content of first failure (for root-cause analysis):' -ForegroundColor Yellow
            Write-Host ('  ' + ('-' * 70)) -ForegroundColor DarkGray
            $fullLog = Get-Content $failureSamples[0].LogFile -ErrorAction SilentlyContinue
            foreach ($ln in $fullLog) {
                Write-Host "  | $ln" -ForegroundColor DarkGray
            }
            Write-Host ('  ' + ('-' * 70)) -ForegroundColor DarkGray
            Write-Host ''
        }
    }

    # If EVERYTHING failed, fail the phase loudly so user sees it
    # rather than silently proceeding to P09.
    if ($okCount -eq 0 -and $infDirs.Count -gt 0) {
        throw "P08: inf2cat failed for all $($infDirs.Count) INF folder(s) using /os:$chosenOs. See per-folder logs under $($Ctx.Paths.Logs). Check that patched INFs reference real files and that decorations are well-formed."
    }

    Set-PhaseMarker -Ctx $Ctx -PhaseId 'P08' -Metadata @{ Ok=$okCount; Failed=$failCount; OsArg=$chosenOs }
    Write-Ok "Catalog generation: $okCount ok / $failCount failed (using /os:$chosenOs)"
    Write-PhaseFooter 'P08' 'done'
}

function Invoke-PrepPhase09_SignCatalogs { # psa-disable-line PSA6003 -- compound noun (e.g., Policies, Drivers, Catalogs) is semantically plural for set-returning helpers
    param($Ctx)
    Write-PhaseHeader 'P09' 'SignCatalogs' 'Prep'

    Set-DebugStep 'precondition: signtool + PFX available'
    if (-not $Ctx.Signtool) { $Ctx.Signtool = Find-KitTool 'signtool.exe' }
    if (-not $Ctx.Signtool) { throw 'signtool.exe not found - run P02 first.' }

    if (-not $Ctx.CertPfxPath -or -not (Test-Path $Ctx.CertPfxPath)) {
        $Ctx.CertPfxPath = Join-Path $Ctx.Paths.Cert 'AMD-Graphics-Driver-CodeSign.pfx'
        if (-not (Test-Path $Ctx.CertPfxPath)) { throw 'PFX missing - run P07 first.' }
    }

    Set-DebugStep 'check phase marker (cache hit?)'
    if (Test-PhaseMarker -Ctx $Ctx -PhaseId 'P09') {
        Write-Skip "Catalogs already signed (cached)."
        Write-PhaseFooter 'P09' 'cached'
        return
    }

    Set-DebugStep 'enumerate .cat files under patched/'
    $cats = Get-ChildItem -Path $Ctx.Paths.Patched -Recurse -Filter *.cat -ErrorAction SilentlyContinue
    if ($cats.Count -eq 0) {
        throw 'P09: no .cat files found - run P08 (GenerateCatalogs) first.'
    }
    Write-Step "Signing $($cats.Count) catalog(s) with cert and timestamp ($($Ctx.TimestampUrl))"
    Write-Detail "Method        : ProcessStartInfo + manual quoting (v2: spaces-in-path safe)" -Color DarkCyan
    Write-Detail "Signtool      : $($Ctx.Signtool)" -Color DarkGray
    Write-Detail "Cert PFX      : $($Ctx.CertPfxPath)" -Color DarkGray
    Write-Detail "Timestamp URL : $($Ctx.TimestampUrl)" -Color DarkGray

    # Cleanup legacy '.err' files left over from previous runs that used
    # Start-Process -RedirectStandardError. The current ProcessStartInfo
    # path writes a single combined log file (no.err sibling), so any
    # remaining.err files are stale and could confuse diagnostics.
    $legacyErrFiles = Get-ChildItem -LiteralPath $Ctx.Paths.Logs -Filter '*.err' -ErrorAction SilentlyContinue
    if ($legacyErrFiles -and $legacyErrFiles.Count -gt 0) {
        Write-Detail "Cleaning $($legacyErrFiles.Count) legacy .err file(s) from prior runs" -Color DarkGray
        foreach ($lf in $legacyErrFiles) {
            Remove-Item -LiteralPath $lf.FullName -Force -ErrorAction SilentlyContinue
        }
    }

    $okCount = 0; $failCount = 0
    $failureSamples = @()

    # Pre-flight: verify all.cat files have content. inf2cat with
    # exit=0 should always produce a non-empty file, but we check
    # explicitly to detect any silent corruption.
    $emptyCount = 0
    foreach ($cat in $cats) {
        if ($cat.Length -eq 0) { $emptyCount++ }
    }
    if ($emptyCount -gt 0) {
        Write-Warn2 "    Pre-flight: $emptyCount of $($cats.Count) .cat file(s) are EMPTY (size=0 bytes)"
        Write-Warn2 "    These will fail signing and indicate inf2cat silently produced corrupt output."
    } else {
        Write-Detail "Pre-flight: all $($cats.Count) .cat files have content (>0 bytes)" -Color DarkGray
    }
    Write-Host ''

    Set-DebugStep 'sign each catalog with signtool (loop)'
    foreach ($cat in $cats) {
        $logFile = Join-Path $Ctx.Paths.Logs ("signtool_{0}.log" -f ($cat.BaseName))

        # Build the signtool command line manually with proper quoting
        # of paths that may contain spaces. Same rationale as P08:
        # PowerShell 5.1's Start-Process -ArgumentList does not reliably
        # quote array items containing spaces, so signtool receives
        # truncated paths and fails.
        $cmdLine = ('sign /fd SHA256 /f "{0}" /p "{1}" /tr "{2}" /td SHA256 "{3}"' -f `
            $Ctx.CertPfxPath, $Ctx.PfxPassword, $Ctx.TimestampUrl, $cat.FullName)

        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = $Ctx.Signtool
        $psi.Arguments = $cmdLine
        $psi.UseShellExecute = $false
        $psi.RedirectStandardOutput = $true
        $psi.RedirectStandardError = $true
        $psi.CreateNoWindow = $true

        $exit = $null
        $stdoutText = ''
        $stderrText = ''
        try {
            $proc = [System.Diagnostics.Process]::Start($psi)
            $stdoutTask = $proc.StandardOutput.ReadToEndAsync()
            $stderrTask = $proc.StandardError.ReadToEndAsync()
            $proc.WaitForExit()
            $stdoutText = $stdoutTask.Result
            $stderrText = $stderrTask.Result
            $exit = $proc.ExitCode
            $proc.Dispose()
        } catch {
            $stderrText = "Failed to launch signtool: $($_.Exception.Message)"
        }

        # Persist log (cmdline + stdout + stderr) for traceability.
        # Don't include the PFX password in the log even though it was
        # in the command line - we redact it for security.
        $redactedCmdLine = $cmdLine -replace ('/p "' + [regex]::Escape($Ctx.PfxPassword) + '"'), '/p "<redacted>"'
        $logBody = New-Object System.Text.StringBuilder
        [void]$logBody.AppendLine("=== signtool (exit=$exit) ===")
        [void]$logBody.AppendLine("Command: `"$($Ctx.Signtool)`" $redactedCmdLine")
        [void]$logBody.AppendLine('')
        if ($stdoutText) { [void]$logBody.AppendLine($stdoutText) }
        if ($stderrText) {
            [void]$logBody.AppendLine('--- stderr ---')
            [void]$logBody.AppendLine($stderrText)
        }
        Set-Content -LiteralPath $logFile -Value $logBody.ToString() -Encoding UTF8

        if ($null -ne $exit -and $exit -eq 0) {
            $okCount++
            Write-Ok "  signed: $($cat.Name)"
        } else {
            $failCount++
            $exitDisplay = if ($null -eq $exit) { 'launch-failed' } else { $exit }
            Write-Warn2 "  exit=$exitDisplay ($($cat.Name)) - see $logFile"

            # On the VERY FIRST failure, dump the full log content to
            # screen immediately. This is the fastest path to diagnosis
            # for the user - no need to wait for end-of-phase summary
            # or open a log file separately.
            if ($failCount -eq 1) {
                Write-Host ''
                Write-Host ' ========== FIRST FAILURE - FULL LOG DUMP ==========' -ForegroundColor Yellow
                Write-Detail "Catalog file path: $($cat.FullName)" -Color DarkYellow
                Write-Detail "(This dump is shown only for the first failure to keep output readable)" -Color DarkGray
                Write-Host '    -----------------------------------------------------' -ForegroundColor DarkGray
                $dumpLines = $logBody.ToString() -split "`r?`n"
                foreach ($dl in $dumpLines) {
                    Write-Detail "| $dl" -Color DarkYellow
                }
                Write-Host '    -----------------------------------------------------' -ForegroundColor DarkGray
                Write-Host ''
            }

            # Capture sample failure details for end-of-phase diagnostics
            if ($failureSamples.Count -lt 3) {
                $allLines = $logBody.ToString() -split "`r?`n" |
                    Where-Object { $_.Trim().Length -gt 0 -and -not $_.StartsWith('===') -and -not $_.StartsWith('Command:') -and -not $_.StartsWith('---') }
                $failureSamples += [pscustomobject]@{
                    Cat = $cat.Name
                    Exit = $exitDisplay
                    Lines = @($allLines | Select-Object -First 5)
                    LogFile = $logFile
                }
            }
        }
    }

    if ($failCount -gt 0 -and $failureSamples.Count -gt 0) {
        Write-Host ''
        Write-Warn2 "Sample failure details (first $($failureSamples.Count) of $failCount):"
        Write-Host ''
        $idx = 0
        foreach ($s in $failureSamples) {
            $idx++
            Write-Host "  [Sample $idx of $($failureSamples.Count)] [$($s.Cat)] exit=$($s.Exit)" -ForegroundColor Yellow
            Write-Detail "log file: $($s.LogFile)" -Color DarkGray
            foreach ($l in $s.Lines) {
                Write-Detail "| $l" -Color DarkYellow
            }
            Write-Host ''
        }
    }

    Set-PhaseMarker -Ctx $Ctx -PhaseId 'P09' -Metadata @{ Ok=$okCount; Failed=$failCount }
    Write-Ok "Signing: $okCount ok / $failCount failed"
    Write-PhaseFooter 'P09' 'done'
}

#####################################################################
# SECTION 9: VERIFICATION PHASES
#####################################################################
# Verification phases NEVER modify the running system. They examine
# preparation artifacts and / or the current OS state in read-only
# mode and report what would change if Installation phases ran.

function Invoke-VerifyPhase01_VerifyArtifacts { # psa-disable-line PSA6003 -- compound noun (e.g., Policies, Drivers, Catalogs) is semantically plural for set-returning helpers
    param($Ctx)
    Write-PhaseHeader 'V01' 'VerifyArtifacts' 'Verify'

    $issues = New-Object System.Collections.Generic.List[string]
    $checks = New-Object System.Collections.Generic.List[string]

    function _Check {
        param([bool]$Cond, [string]$Ok, [string]$Bad)
        if ($Cond) { $checks.Add("[OK]   $Ok") | Out-Null }
        else       { $checks.Add("[FAIL] $Bad") | Out-Null; $issues.Add($Bad) | Out-Null }
    }

    Set-DebugStep 'check cert artifacts (PFX/CER)'
    $pfx = Join-Path $Ctx.Paths.Cert 'AMD-Graphics-Driver-CodeSign.pfx'
    $cer = Join-Path $Ctx.Paths.Cert 'AMD-Graphics-Driver-CodeSign.cer'
    _Check (Test-Path $pfx) "PFX present : $pfx"  "PFX MISSING (run P07): $pfx"
    _Check (Test-Path $cer) "CER present : $cer"  "CER MISSING (run P07): $cer"

    Set-DebugStep 'check patched INFs'
    $patchedInfs = @()
    if (Test-Path $Ctx.Paths.Patched) {
        $patchedInfs = Get-ChildItem -Path $Ctx.Paths.Patched -Recurse -Filter *.inf -ErrorAction SilentlyContinue
    }
    _Check ($patchedInfs.Count -gt 0) `
        "Patched INFs: $($patchedInfs.Count) file(s) under $($Ctx.Paths.Patched)" `
        "No patched INFs found in $($Ctx.Paths.Patched) (run P06)"

    Set-DebugStep 'check catalog files'
    $cats = @()
    if (Test-Path $Ctx.Paths.Patched) {
        $cats = Get-ChildItem -Path $Ctx.Paths.Patched -Recurse -Filter *.cat -ErrorAction SilentlyContinue
    }
    if ($cats.Count -eq 0) {
        $checks.Add("[WARN] No .cat files (P08 + P09 not yet run?)") | Out-Null
    } else {
        $checks.Add("[OK]   Catalog files: $($cats.Count) .cat file(s)") | Out-Null
    }

    Set-DebugStep 'check inventory CSV'
    $csv = Join-Path $Ctx.Paths.Root 'inf_inventory.csv'
    _Check (Test-Path $csv) "Inventory CSV: $csv" "INF inventory CSV missing (run P05): $csv"

    Set-DebugStep 'render verification result'
    foreach ($c in $checks) { Write-Host "  $c" }
    if ($issues.Count -gt 0) {
        Write-Warn2 "$($issues.Count) artifact issue(s) detected"
        throw "V01 found $($issues.Count) missing artifact(s) - run earlier phases first."
    }
    Write-Ok 'All preparation artifacts are present.'
    Write-PhaseFooter 'V01' 'done'
}

function Invoke-VerifyPhase02_VerifyCertificate {
    param($Ctx)
    Write-PhaseHeader 'V02' 'VerifyCertificate' 'Verify'

    Set-DebugStep 'locate and check PFX file'
    $pfx = Join-Path $Ctx.Paths.Cert 'AMD-Graphics-Driver-CodeSign.pfx'
    if (-not (Test-Path $pfx)) {
        Write-Fail "PFX not found: $pfx"
        throw 'V02: cannot verify certificate without PFX (run P07)'
    }

    Set-DebugStep 'load X509Certificate2 from PFX'
    # Use.NET API instead of Get-PfxCertificate so the password is
    # supplied non-interactively (PFX is password-protected from P07).
    $cert = [System.Security.Cryptography.X509Certificates.X509Certificate2]::new($pfx, $Ctx.PfxPassword)
    Write-Host "  Subject       : $($cert.Subject)"
    Write-Host "  Thumbprint    : $($cert.Thumbprint)"
    Write-Host "  Issuer        : $($cert.Issuer)"
    Write-Host "  Valid from    : $($cert.NotBefore)"
    Write-Host "  Valid to      : $($cert.NotAfter)"
    Write-Host "  Signature alg : $($cert.SignatureAlgorithm.FriendlyName)"
    Write-Host "  Has priv key  : $($cert.HasPrivateKey)"

    Set-DebugStep 'validate private key + expiry'
    $problems = New-Object System.Collections.Generic.List[string]

    if (-not $cert.HasPrivateKey) {
        $problems.Add('Certificate has no private key - signtool will fail') | Out-Null
    }

    $daysLeft = ($cert.NotAfter - (Get-Date)).Days
    if ($daysLeft -le 0) {
        $problems.Add("Certificate has EXPIRED ($daysLeft days)") | Out-Null
    } elseif ($daysLeft -le 30) {
        Write-Warn2 "Certificate expires in $daysLeft days - consider renewal"
    } else {
        Write-Ok "Certificate valid for $daysLeft more days"
    }

    Set-DebugStep 'check Code Signing EKU (1.3.6.1.5.5.7.3.3)'
    # Code Signing EKU = 1.3.6.1.5.5.7.3.3
    $hasCodeSigning = $false
    foreach ($ext in $cert.Extensions) {
        if ($ext.Oid.Value -eq '2.5.29.37') {
            foreach ($eku in $ext.EnhancedKeyUsages) {
                if ($eku.Value -eq '1.3.6.1.5.5.7.3.3') { $hasCodeSigning = $true }
            }
        }
    }
    if ($hasCodeSigning) {
        Write-Ok 'Code Signing EKU (1.3.6.1.5.5.7.3.3) present'
    } else {
        Write-Warn2 'Code Signing EKU NOT present - some signtool flows may reject'
    }

    if ($problems.Count -gt 0) {
        foreach ($p in $problems) { Write-Fail "  $p" }
        throw "V02: certificate has $($problems.Count) blocking issue(s)"
    }
    Write-PhaseFooter 'V02' 'done'
}

function Invoke-VerifyPhase03_VerifyCatalogs { # psa-disable-line PSA6003 -- compound noun (e.g., Policies, Drivers, Catalogs) is semantically plural for set-returning helpers
    param($Ctx)
    Write-PhaseHeader 'V03' 'VerifyCatalogs' 'Verify'

    Set-DebugStep 'locate signtool.exe'
    if (-not $Ctx.Signtool) { $Ctx.Signtool = Find-KitTool 'signtool.exe' }
    if (-not $Ctx.Signtool) {
        throw 'V03: signtool.exe not found - run P02 (AcquireTools) first.'
    }

    Set-DebugStep 'enumerate catalogs to verify'
    $cats = @()
    if (Test-Path $Ctx.Paths.Patched) {
        $cats = Get-ChildItem -Path $Ctx.Paths.Patched -Recurse -Filter *.cat -ErrorAction SilentlyContinue
    }
    if ($cats.Count -eq 0) {
        Write-Warn2 'No .cat files to verify (P08 + P09 not yet run?)'
        Write-PhaseFooter 'V03' 'skipped'
        return
    }

    # ---- Pre-flight: is the signing certificate actually trusted? ----
    # signtool verify /pa requires the cert chain to terminate at a
    # trusted root. Self-signed test certs are NOT trusted until I01
    # imports them into LocalMachine\Root and TrustedPublisher. If V03
    # runs before I01, all verifications will fail with "untrusted
    # root" - this is EXPECTED, not a bug.
    #
    # We detect this state up-front so failures can be classified
    # correctly (expected vs. real corruption) at the end of the phase.
    Set-DebugStep 'check cert trust state (Root + TrustedPublisher)'
    $certTrusted = $false
    $certInRoot = $false
    $certInTrustedPublisher = $false
    if ($Ctx.CertThumbprint) {
        $certInRoot = [bool](Get-ChildItem 'Cert:\LocalMachine\Root' -ErrorAction SilentlyContinue |
                            Where-Object { $_.Thumbprint -eq $Ctx.CertThumbprint })
        $certInTrustedPublisher = [bool](Get-ChildItem 'Cert:\LocalMachine\TrustedPublisher' -ErrorAction SilentlyContinue |
                            Where-Object { $_.Thumbprint -eq $Ctx.CertThumbprint })
        $certTrusted = $certInRoot -and $certInTrustedPublisher
    }

    Write-Detail "Cert thumbprint   : $($Ctx.CertThumbprint)" -Color DarkGray
    Write-Detail ("In TrustedRoot    : {0}" -f $certInRoot) -Color $(if ($certInRoot) { 'DarkGray' } else { 'Yellow' })
    Write-Detail ("In TrustedPublisher: {0}" -f $certInTrustedPublisher) -Color $(if ($certInTrustedPublisher) { 'DarkGray' } else { 'Yellow' })
    if (-not $certTrusted) {
        Write-Host ''
        Write-Warn2 '    NOTE: Certificate is NOT yet in trusted stores.'
        Write-Host  '          signtool verify /pa will fail with "untrusted root" for all'
        Write-Host  '          catalogs - this is EXPECTED at this stage of the pipeline.'
        Write-Host  '          To pass V03, run -Action Install -OnlyPhases I01 first to'
        Write-Host  '          import the cert, then re-run V03.'
        Write-Host  '          V03 will treat untrusted-root failures as informational, NOT'
        Write-Host  '          as real verification failures.'
        Write-Host ''
    }

    Write-Step "Verifying $($cats.Count) catalog signature(s) with signtool /verify /pa..."

    # Patterns that indicate an "expected" failure (cert not yet trusted).
    # These are NOT real verification problems - the catalog signature is
    # cryptographically valid, but the trust chain can't be validated yet.
    #
    # IMPORTANT: signtool wraps long error messages across multiple lines
    # at ~80 columns. PowerShell's -match operator does NOT allow `.` to
    # span newlines by default, so we must either use the (?s) inline
    # flag or normalise the input before matching. Below we use SHORTER
    # substrings that are guaranteed to fit on a single line, plus we
    # normalise whitespace before comparison as a belt-and-braces fix.
    $expectedFailPatterns = @(
        'is not trusted by the trust provider',           # most common
        'A certificate chain processed, but terminated',  # fits on one line
        'The signing certificate is not trusted',
        'A certificate chain could not be built',
        '0x800B0109',                                     # CERT_E_UNTRUSTEDROOT (numeric)
        '0x800B010A',                                     # CERT_E_CHAINING
        'CERT_E_UNTRUSTEDROOT',
        'CERT_E_CHAINING',
        'No signature was present in the subject',
        'Number of files successfully Verified: 0'        # signtool's count line
    )

    $okCount = 0
    $failExpected = 0     # untrusted root etc - expected when cert not yet imported
    $failReal = 0         # actual verification problems
    $firstFailureLogged = $false

    Set-DebugStep 'signtool verify /pa loop over catalogs'
    foreach ($cat in $cats) {
        $logFile = Join-Path $Ctx.Paths.Logs ("verify_{0}.log" -f $cat.BaseName)

        # Same ProcessStartInfo pattern as P08/P09/I03 to handle paths
        # with spaces correctly.
        $cmdLine = 'verify /pa /v "{0}"' -f $cat.FullName

        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = $Ctx.Signtool
        $psi.Arguments = $cmdLine
        $psi.UseShellExecute = $false
        $psi.RedirectStandardOutput = $true
        $psi.RedirectStandardError = $true
        $psi.CreateNoWindow = $true

        $exit = $null
        $stdoutText = ''
        $stderrText = ''
        try {
            $proc = [System.Diagnostics.Process]::Start($psi)
            $stdoutTask = $proc.StandardOutput.ReadToEndAsync()
            $stderrTask = $proc.StandardError.ReadToEndAsync()
            $proc.WaitForExit()
            $stdoutText = $stdoutTask.Result
            $stderrText = $stderrTask.Result
            $exit = $proc.ExitCode
            $proc.Dispose()
        } catch {
            $stderrText = "Failed to launch signtool: $($_.Exception.Message)"
        }

        $logBody = New-Object System.Text.StringBuilder
        [void]$logBody.AppendLine("=== signtool verify (exit=$exit) ===")
        [void]$logBody.AppendLine("Command: `"$($Ctx.Signtool)`" $cmdLine")
        [void]$logBody.AppendLine('')
        if ($stdoutText) { [void]$logBody.AppendLine($stdoutText) }
        if ($stderrText) {
            [void]$logBody.AppendLine('--- stderr ---')
            [void]$logBody.AppendLine($stderrText)
        }
        Set-Content -LiteralPath $logFile -Value $logBody.ToString() -Encoding UTF8

        if ($null -ne $exit -and $exit -eq 0) {
            $okCount++
            Write-Ok "  $($cat.Name)"
        } else {
            $exitDisplay = if ($null -eq $exit) { 'launch-failed' } else { $exit }

            # Classify: expected (untrusted) vs real failure.
            #
            # Normalise whitespace before matching: signtool wraps long
            # error messages across newlines at ~80 columns, so the
            # phrase "A certificate chain processed, but terminated in a
            # root\n\tcertificate which is not trusted" would NOT match
            # a regex like ".*terminated.*certificate.*not trusted"
            # because PowerShell's -match operator does not allow `.` to
            # span newlines by default.
            #
            # We collapse all runs of whitespace (newlines, tabs,
            # multiple spaces) into a single space so multi-line errors
            # become single-line strings that simple substring patterns
            # can match reliably.
            $combinedRaw = ($stdoutText + "`n" + $stderrText)
            $combinedFlat = ($combinedRaw -replace '\s+', ' ')

            $isExpected = $false
            foreach ($p in $expectedFailPatterns) {
                if ($combinedFlat -match $p) { $isExpected = $true; break } # psa-disable-line PSA2003 -- pattern variable is initialized in the enclosing scope; $null impossible by construction
            }
            # Also: if cert isn't in trusted stores, treat ALL failures
            # as expected (we know the chain validation will fail).
            # This is the ultimate safety net - even if the regex
            # patterns fail to match, an untrusted cert in the store
            # makes verification failure inevitable and expected.
            if (-not $certTrusted) { $isExpected = $true }

            if ($isExpected) {
                $failExpected++
                # Print first 3 [skip] lines explicitly so the
                # operator can see at least a few catalog names; after
                # that, suppress further per-catalog noise. The full
                # count appears in the verification summary below.
                if ($failExpected -le 3) {
                    Write-Detail ("[skip] {0} (expected: cert not yet trusted)" -f $cat.Name) -Color DarkGray
                } elseif ($failExpected -eq 4) {
                    Write-Host '    [skip] ... (further "cert not yet trusted" skips suppressed; see summary)' -ForegroundColor DarkGray
                }
            } else {
                $failReal++
                Write-Warn2 "  exit=$exitDisplay - $($cat.Name) - see $logFile"
            }

            # Dump first failure log to screen for diagnosis
            if (-not $firstFailureLogged) {
                $firstFailureLogged = $true
                Write-Host ''
                Write-Host ' ========== FIRST VERIFY FAILURE - LOG DUMP ==========' -ForegroundColor Yellow
                Write-Detail "Catalog: $($cat.FullName)" -Color DarkYellow
                Write-Detail "Classified as: $(if ($isExpected) { 'EXPECTED (untrusted root)' } else { 'REAL FAILURE' })" -Color DarkYellow
                Write-Host '    -----------------------------------------------------' -ForegroundColor DarkGray
                $dumpLines = $logBody.ToString() -split "`r?`n"
                foreach ($dl in $dumpLines) {
                    Write-Detail "| $dl" -Color DarkYellow
                }
                Write-Host '    -----------------------------------------------------' -ForegroundColor DarkGray
                Write-Host ''
            }
        }
    }

    # ---- Phase outcome classification ----
    Write-Host ''
    Write-Detail "Catalog verification summary:" -Color Cyan
    Write-Detail ("  ok                : {0}" -f $okCount) -Color Green
    Write-Detail ("  expected failures : {0}  (cert not yet trusted)" -f $failExpected) -Color DarkGray
    Write-Detail ("  REAL failures     : {0}" -f $failReal) -Color $(if ($failReal -gt 0) { 'Red' } else { 'DarkGray' })

    if ($failReal -eq 0 -and $failExpected -gt 0) {
        # All failures are due to cert-not-yet-trusted state.
        # This is informational, not an error. Phase passes with a warning.
        Write-Warn2 "V03: $failExpected expected failure(s) - cert not yet imported by I01."
        Write-Ok    "V03: no real verification failures. Re-run after I01 to confirm trust."
        Write-PhaseFooter 'V03' 'done'
        return
    }
    if ($failReal -gt 0) {
        # At least one real failure - this is an error.
        throw "V03: $failReal catalog(s) had real verification failure (not just untrusted-root). See per-catalog logs in $($Ctx.Paths.Logs)."
    }
    # All passed
    Write-Ok "V03: all $okCount catalog(s) verified successfully (cert trust chain valid)."
    Write-PhaseFooter 'V03' 'done'
}

function Test-InfHasServerDecoration {
    # Walk the [Manufacturer] section the same way P06 does and report
    # whether ANY decoration has ProductType=3 (parts[3] == '3').
    #
    # This mirrors the logic in ConvertTo-ServerDecoration / Edit-InfForServer:
    # an NT decoration's 4th dot-separated component is the ProductType
    # (1=workstation, 3=server). P06 sets parts[3]='3', so we look for
    # the same.
    #
    # Why we don't just regex-search the whole file:
    # The previous V04 used a regex like 'NTamd64\.10\.0\.3\.' which
    # required (a) the architecture be amd64, (b) the OS major.minor be
    # exactly 10.0, and (c) a TRAILING DOT after the '3'. P06 produces
    # decorations of varying length depending on the original (e.g. an
    # original 'NTamd64.10.0' becomes 'NTamd64.10.0.3' with NO trailing
    # dot), so the strict regex misses valid server decorations and
    # reports false negatives.
    param([string]$Content)

    if ([string]::IsNullOrEmpty($Content)) { return $false }

    $lines = $Content -split "(?<=`n)"
    $inMfg = $false
    foreach ($line in $lines) {
        $t = $line.Trim().TrimEnd("`r")
        if ($t -match '^\[Manufacturer\]') { $inMfg = $true; continue }
        if ($inMfg -and $t -match '^\[')   { $inMfg = $false; continue }
        if (-not $inMfg)                   { continue }
        if (-not $t -or $t.StartsWith(';')) { continue }

        # Parse "%name% = SectionName, dec1, dec2,..."
        $kv = $t -split '=', 2
        if ($kv.Count -ne 2) { continue }
        $rhs = $kv[1].Split(',')
        # Index 0 is the section name; decorations start at index 1.
        for ($j = 1; $j -lt $rhs.Count; $j++) {
            $dec = $rhs[$j].Trim()
            if ($dec -notmatch '^NT(amd64|x86|arm|arm64)') { continue }
            $parts = $dec.Split('.')
            # Pad to at least 4 parts so parts[3] is always defined.
            while ($parts.Count -lt 4) { $parts += '' }
            # Per Microsoft Learn INF TargetOSVersion specification, the
            # ProductType field (parts[3]) may be:
            #   '3' - explicit Server-only (Server is supported)
            #   '1' - explicit Workstation-only (Server is NOT supported)
            #   '' - empty = "any product type", which INCLUDES Server
            # Both '3' and '' satisfy "this decoration permits Server
            # installation". An INF whose [Manufacturer] only carries
            # decorations like 'NTamd64.10.0...22000' (empty ProductType
            # + empty SuiteMask + BuildNumber) is already implicitly
            # Server-compatible without P06 needing to mirror anything.
            # Earlier versions of this check rejected those INFs as
            # missing-decoration; this is now corrected.
            if ($parts[3] -eq '3' -or $parts[3] -eq '') { return $true }
        }
    }
    return $false
}

function Invoke-VerifyPhase04_VerifyInfs { # psa-disable-line PSA6003 -- compound noun (e.g., Policies, Drivers, Catalogs) is semantically plural for set-returning helpers
    param($Ctx)
    Write-PhaseHeader 'V04' 'VerifyInfs' 'Verify'

    Set-DebugStep 'enumerate patched INFs'
    $infs = @()
    if (Test-Path $Ctx.Paths.Patched) {
        $infs = Get-ChildItem -Path $Ctx.Paths.Patched -Recurse -Filter *.inf -ErrorAction SilentlyContinue
    }
    if ($infs.Count -eq 0) {
        throw 'V04: no patched INFs to verify - run P06 (PatchInfs) first.'
    }

    Set-DebugStep 'inspect ProductType=3 decoration on each INF'
    Write-Step "Inspecting $($infs.Count) patched INF file(s) for ProductType=3 decoration..."
    $okCount = 0; $failCount = 0
    $details = @()
    foreach ($inf in $infs) {
        $infData = Read-InfFile -Path $inf.FullName
        $hasMfg        = $infData.Content -match '\[Manufacturer\]'
        # Use the proper parser that walks [Manufacturer] entries and
        # checks parts[3]=='3' on each NT decoration. This is the same
        # interpretation P06 used to write the decoration.
        $hasServerDeco = Test-InfHasServerDecoration -Content $infData.Content
        $row = [pscustomobject]@{
            Inf           = $inf.Name
            Encoding      = $infData.EncodingName
            HasMfg        = $hasMfg
            HasServerDeco = $hasServerDeco
            Ok            = ($hasMfg -and $hasServerDeco)
        }
        $details += $row
        if ($row.Ok) {
            $okCount++
            Write-Ok "  $($inf.Name) [$($infData.EncodingName)]"
        } else {
            $failCount++
            Write-Warn2 "  $($inf.Name) (Mfg=$hasMfg ServerDeco=$hasServerDeco)"

            # On first failure, dump the [Manufacturer] section content
            # so the user can see what was actually written. This is the
            # quickest way to diagnose any future regression in P06.
            if ($failCount -eq 1) {
                Write-Host ''
                Write-Host ' ========== FIRST V04 FAILURE - [Manufacturer] DUMP ==========' -ForegroundColor Yellow
                Write-Detail "INF: $($inf.FullName)" -Color DarkYellow
                Write-Detail "Encoding: $($infData.EncodingName)" -Color DarkYellow
                Write-Host '    -----------------------------------------------------' -ForegroundColor DarkGray
                $mfgLines = $infData.Content -split "(?<=`n)"
                $inSection = $false
                foreach ($l in $mfgLines) {
                    $tt = $l.TrimEnd("`r","`n")
                    if ($tt -match '^\[Manufacturer\]') { $inSection = $true }
                    if ($inSection) {
                        Write-Detail "| $tt" -Color DarkYellow
                        if ($tt -match '^\[' -and $tt -notmatch '^\[Manufacturer\]') { break }
                    }
                }
                Write-Host '    -----------------------------------------------------' -ForegroundColor DarkGray
                Write-Host ''
            }
        }
    }
    Write-Ok "INF verification: $okCount ok / $failCount missing decoration"
    if ($failCount -gt 0) {
        throw "V04: $failCount INF(s) lack ProductType=3 decoration"
    }
    Write-PhaseFooter 'V04' 'done'
}

function Invoke-VerifyPhase05_DryRunInstall {
    param($Ctx)
    Write-PhaseHeader 'V05' 'DryRunInstall' 'Verify'
    Write-Host '  Simulating Installation phases I01 / I02 / I03 - NO system changes will be made.'
    Write-Host ''

    Set-DebugStep 'dry-run I01: trust cert state check'
    # ----- I01 dry-run: TrustCertificate -----
    Write-Host '[Dry-Run I01] TrustCertificate -----------------------' -ForegroundColor Cyan
    $pfx = Join-Path $Ctx.Paths.Cert 'AMD-Graphics-Driver-CodeSign.pfx'
    if (-not (Test-Path $pfx)) {
        Write-Warn2 '  PFX missing - I01 would FAIL'
    } else {
        $cert = [System.Security.Cryptography.X509Certificates.X509Certificate2]::new($pfx, $Ctx.PfxPassword)
        Write-Host "  Subject     : $($cert.Subject)"
        Write-Host "  Thumbprint  : $($cert.Thumbprint)"
        foreach ($storeName in 'Root','TrustedPublisher') {
            $store = New-Object System.Security.Cryptography.X509Certificates.X509Store($storeName, 'LocalMachine')
            $store.Open('ReadOnly')
            $exists = $store.Certificates | Where-Object Thumbprint -eq $cert.Thumbprint
            $store.Close()
            if ($exists) {
                Write-Host "  LocalMachine\$storeName -> already present (would SKIP)" -ForegroundColor DarkGray
            } else {
                Write-Host "  LocalMachine\$storeName -> would IMPORT" -ForegroundColor Yellow
            }
        }
    }
    Write-Host ''

    Set-DebugStep 'dry-run I02: WDAC/testsigning path probe'
    # ----- I02 dry-run: AuthorizeDriverSigning -----
    # Two paths to surface depending on which one this run will use:
    #   PATH A (default): WDAC supplemental policy
    #   PATH B (-UseTestSigning): bcdedit testsigning
    Write-Host '[Dry-Run I02] AuthorizeDriverSigning -------------------' -ForegroundColor Cyan
    if ($Ctx.UseTestSigning) {
        Write-Host '  Path: B (bcdedit testsigning, legacy) - selected via -UseTestSigning' -ForegroundColor Yellow
        $bcdoutput = & bcdedit /enum '{current}' 2>&1 | Out-String
        if ($bcdoutput -match 'testsigning\s+Yes') {
            Write-Host '  testsigning is currently ON  -> would SKIP' -ForegroundColor DarkGray
        } elseif ($bcdoutput -match 'testsigning\s+No') {
            Write-Host '  testsigning is currently OFF -> would set to ON (REBOOT required after I02)' -ForegroundColor Yellow
        } else {
            Write-Host '  testsigning state unknown    -> would attempt to set to ON' -ForegroundColor Yellow
        }
    } else {
        Write-Host '  Path: A (WDAC supplemental policy, default)' -ForegroundColor Cyan
        $deployed = $false
        try { $deployed = Test-AmdWdacPolicyDeployed -Ctx $Ctx } catch { } # psa-disable-line PSA3004 -- intentional best-effort cleanup; no error to surface
        if ($deployed) {
            Write-Host '  WDAC supplemental policy already deployed -> would SKIP' -ForegroundColor DarkGray
        } else {
            Write-Host '  WDAC supplemental policy not yet deployed -> would CREATE + DEPLOY' -ForegroundColor Yellow
            Write-Host '  Secure Boot stays ON; testsigning stays OFF; no reboot on WS2022+ / Windows 11 22H2+' -ForegroundColor DarkGray
        }
    }
    Write-Host ''

    Set-DebugStep 'dry-run I03: enumerate patched INFs + device match'
    # ----- I03 dry-run: InstallDrivers -----
    # This dry-run now mirrors the version-aware install decision
    # used by I03 itself (Resolve-PerInfInstallDecision). For each
    # patched INF we show:
    #   - Whether it's already in the driver store
    #   - Whether the install decision is INSTALL or SKIP, and why
    # The same logic runs in I03, so an INF flagged SKIP here will
    # actually be skipped at install time.
    Write-Host '[Dry-Run I03] InstallDrivers -------------------------' -ForegroundColor Cyan
    $infs = @()
    if (Test-Path $Ctx.Paths.Patched) {
        $infs = Get-ChildItem -Path $Ctx.Paths.Patched -Recurse -Filter *.inf -ErrorAction SilentlyContinue
    }
    if ($infs.Count -eq 0) {
        Write-Warn2 '  No INFs to install - I03 would do nothing'
    } else {
        Write-Host "  $($infs.Count) INF(s) would be processed by 'pnputil /add-driver /install':"
        # Snapshot driver store once
        $storeSnapshot = ''
        try { $storeSnapshot = (& pnputil /enum-drivers 2>&1 | Out-String) } catch {} # psa-disable-line PSA3004 -- intentional best-effort cleanup; no error to surface

        # Pre-compute duplicate-name detection so we can flag entries
        # whose filename alone is ambiguous. Many AMD INFs share the
        # same filename across different driver variants - the most
        # extreme case is amdpmf.inf, which exists in 7 separate
        # directories (one per Ryzen generation: PMF_6000SERIES,
        # PMF_7040SERIES, PMF_7736SERIES, PMF_8000SERIES,
        # PMF_RyzenAI300SERIES, PMF_RYZEN_AI300SERIES2,
        # PMF_RyzenAIMAX300SERIES). Without source-directory info,
        # the user cannot tell which one is which in the dry-run report.
        $nameCounts = @{}
        foreach ($f in $infs) {
            if ($nameCounts.ContainsKey($f.Name)) {
                $nameCounts[$f.Name]++
            } else {
                $nameCounts[$f.Name] = 1
            }
        }

        # Pre-compute install decisions using the same logic I03
        # will apply. We build a tiny version of the per-device current
        # driver lookup once and reuse it for every INF.
        # Switched to a two-pass design - first PASS 1 collects
        # every INF with its metadata, decision, and matched-device
        # list; PASS 2 groups by matched-device name and prints in
        # "Device: <name>" sections so the operator can see at a glance
        # WHICH device each INF will affect (rather than scanning a
        # flat 32-line list).
        $beforeHwLocal = @(Get-AmdHardwareInventory -HardwareOnly)
        $beforeCurrentLocal = @{}
        foreach ($d in $beforeHwLocal) {
            $beforeCurrentLocal[$d.DeviceID] = Get-DeviceCurrentDriver -DeviceID $d.DeviceID
        }

        # ---- PASS 1: collect records (one per INF) ----
        $infRecords = @()
        $decisionCount = @{ INSTALL_UPGRADE=0; INSTALL_NEW=0; SKIP_NEWER=0 }
        foreach ($inf in $infs) {
            $infData = Read-InfFile -Path $inf.FullName
            $clsMatch  = [regex]::Match($infData.Content, '(?im)^\s*Class\s*=\s*([^\r\n;]+)')
            $provMatch = [regex]::Match($infData.Content, '(?im)^\s*Provider\s*=\s*([^\r\n;]+)')
            $cls  = if ($clsMatch.Success)  { $clsMatch.Groups[1].Value.Trim()  } else { '?' }
            $prov = if ($provMatch.Success) { $provMatch.Groups[1].Value.Trim() } else { '?' }

            # Resolve %TokenName% in Provider against the INF's own
            # [Strings] section so the dry-run shows the human-readable
            # vendor name ("Advanced Micro Devices, Inc") instead of
            # the raw token ("%ManufacturerName%"). an earlier revision: previously the
            # token was emitted unresolved, which made it hard for
            # operators to confirm at a glance that the patched INFs
            # are still attributed to AMD.
            if ($prov -match '^%([^%]+)%$') {
                $stringsKey = $matches[1]
                $stringsMatch = [regex]::Match(
                    $infData.Content,
                    '(?ims)^\s*\[\s*Strings\s*\][\r\n]+(.+?)(?=^\s*\[|\Z)'
                )
                if ($stringsMatch.Success) {
                    $stringsBody = $stringsMatch.Groups[1].Value
                    $resolveRx = '(?im)^\s*' + [regex]::Escape($stringsKey) + '\s*=\s*"?(.*?)"?\s*(?:;.*)?$'
                    $resolveMatch = [regex]::Match($stringsBody, $resolveRx)
                    if ($resolveMatch.Success) {
                        $resolved = $resolveMatch.Groups[1].Value.Trim().Trim('"')
                        if ($resolved) { $prov = $resolved }
                    }
                }
            }

            # Compute the install decision for this INF
            $meta = Get-InfMetadata -Content $infData.Content
            $infEntry = [pscustomobject]@{ InfName=$inf.Name; FullPath=$inf.FullName; DriverVer=$meta.DriverVer }
            # Dedupe matchedDevices by physical DeviceID. Without
            # this, an INF that declares N HWID variants matching the same
            # physical device produces N entries for that single device,
            # inflating the V05 "matched device(s)" count and the V05/V06
            # "(+N more)" device-label suffix. Example: u0197843.inf
            # declares 5047 device variants; on a host with 1 matching
            # GPU, ~1067 of those variants compat-match it - producing
            # the misleading "would upgrade 1067/1067 matched device(s)"
            # for what is really a single physical device.
            $matchedDevices = @()
            $seenDeviceIds = @{}
            foreach ($dev in $meta.Devices) {
                $infKey = ConvertTo-DeviceMatchKey -HwId $dev.HardwareId
                if (-not $infKey) { continue }
                foreach ($d in $beforeHwLocal) {
                    $devKey = ConvertTo-DeviceMatchKey -HwId $d.PNPDeviceID
                    if ($devKey -eq $infKey -and -not $seenDeviceIds.ContainsKey($d.DeviceID)) {
                        $matchedDevices += @{ Device=$d; Current=$beforeCurrentLocal[$d.DeviceID] }
                        $seenDeviceIds[$d.DeviceID] = $true
                    }
                }
            }
            $decision = Resolve-PerInfInstallDecision -InfEntry $infEntry -InfMatchedDevices $matchedDevices
            $decisionCount[$decision.Decision]++

            $alreadyInStore = $storeSnapshot -match [regex]::Escape($inf.Name)

            # Compute source-directory disambiguation (relative path
            # from the patched root). Strip the common prefix
            # 'Packages\IODriver\' and the AMD-internal architecture
            # folder ('W11x64' or 'WTx64') to keep the line compact
            # while preserving the part that uniquely identifies which
            # variant of a duplicated filename we are looking at.
            $relSrc = $inf.Directory.FullName.Substring($Ctx.Paths.Patched.Length).TrimStart('\')
            if ($relSrc.StartsWith('Packages\IODriver\', [StringComparison]::OrdinalIgnoreCase)) {
                $relSrc = $relSrc.Substring('Packages\IODriver\'.Length)
            }
            $relSrc = $relSrc -replace '\\W11x64\\', '\'
            $relSrc = $relSrc -replace '\\W11x64$', ''
            $relSrc = $relSrc -replace '\\WTx64\\', '\'
            $relSrc = $relSrc -replace '\\WTx64$', ''
            $relSrc = $relSrc.TrimEnd('\').TrimStart('\')
            if ([string]::IsNullOrEmpty($relSrc)) { $relSrc = '(root)' }

            # Derive the device-name group key. INFs that match
            # a current device are grouped under that device's Name.
            # INFs that match multiple devices land under the FIRST
            # matched device with a "+N more" suffix - this keeps the
            # tree compact while still indicating multi-targeting.
            # INFs that match no current device fall into the
            # driver-store-only bucket (group key '(no current device)').
            $groupKey = if ($matchedDevices.Count -gt 0) {
                if ($matchedDevices.Count -eq 1) {
                    $matchedDevices[0].Device.Name
                } else {
                    '{0} (+{1} more)' -f $matchedDevices[0].Device.Name, ($matchedDevices.Count - 1)
                }
            } else {
                '(no current device match - driver-store-only)'
            }

            $infRecords += [pscustomobject]@{
                Inf            = $inf
                Class          = $cls
                Provider       = $prov
                Decision       = $decision
                MatchedDevices = $matchedDevices
                GroupKey       = $groupKey
                AlreadyInStore = $alreadyInStore
                RelSrc         = $relSrc
                IsDuplicate    = ($nameCounts[$inf.Name] -gt 1)
            }
        }

        # ---- PASS 2: render grouped output ----
        # First emit the device-targeted groups (sorted by device
        # name), then emit the driver-store-only group at the bottom.
        # The slash-separated header line "Device name / INF file name"
        # is what the user explicitly requested in an earlier revision.
        $matchedGroups = @($infRecords |
            Where-Object { $_.MatchedDevices.Count -gt 0 } |
            Group-Object -Property GroupKey | Sort-Object Name)
        $noMatchRecords = @($infRecords | Where-Object { $_.MatchedDevices.Count -eq 0 })

        $matchedInfTotal = ($matchedGroups | Measure-Object -Property Count -Sum).Sum
        if (-not $matchedInfTotal) { $matchedInfTotal = 0 }

        if ($matchedGroups.Count -gt 0) {
            Write-Host ''
            Write-Host ('  --- Group A: INFs targeting AMD HARDWARE on this machine ({0} INF / {1} device) ---' -f `
                $matchedInfTotal, $matchedGroups.Count) -ForegroundColor White
            foreach ($g in $matchedGroups) {
                Write-Host ''
                Write-Host ('  Device: {0}' -f $g.Name) -ForegroundColor Cyan
                foreach ($r in $g.Group) {
                    $storeTag = if ($r.AlreadyInStore) { '[in store]' } else { '[would ADD]' }
                    $decTag = switch ($r.Decision.Decision) {
                        'INSTALL_UPGRADE' { '[UPGRADE]' }
                        'INSTALL_NEW'     { '[ADD]' }
                        'SKIP_NEWER'      { '[SKIP-newer]' }
                        default           { '[?]' }
                    }
                    $color = switch ($r.Decision.Decision) {
                        'INSTALL_UPGRADE' { 'Yellow' }
                        'INSTALL_NEW'     { 'DarkGray' }
                        'SKIP_NEWER'      { 'DarkCyan' }
                        default           { 'Gray' }
                    }
                    $srcColor = if ($r.IsDuplicate) { 'Yellow' } else { 'DarkGray' }
                    # The slash-separated header form requested in an earlier revision:
                    # "<device name> / <inf file name>"
                    Write-Host ('    {0} / {1,-32}  {2} {3}' -f $g.Name, $r.Inf.Name, $storeTag, $decTag) -ForegroundColor $color
                    Write-Host ('        Class={0,-15}  Provider={1}' -f $r.Class, $r.Provider) -ForegroundColor DarkGray
                    Write-Host ('        src: {0}' -f $r.RelSrc) -ForegroundColor $srcColor
                    if ($r.Decision.Decision -eq 'SKIP_NEWER' -or $r.Decision.Decision -eq 'INSTALL_UPGRADE') {
                        Write-Host ('        reason: {0}' -f $r.Decision.Reason) -ForegroundColor DarkGray
                    }
                }
            }
        }

        if ($noMatchRecords.Count -gt 0) {
            Write-Host ''
            Write-Host ('  --- Group B: INFs with NO matching device (driver-store-only, {0} INF) ---' -f $noMatchRecords.Count) -ForegroundColor White
            Write-Host  '  (these INFs will be added to the driver store but bind to no current device)' -ForegroundColor DarkGray
            foreach ($r in $noMatchRecords | Sort-Object { $_.Inf.Name }) {
                $storeTag = if ($r.AlreadyInStore) { '[in store]' } else { '[would ADD]' }
                $color = 'DarkGray'
                $srcColor = if ($r.IsDuplicate) { 'Yellow' } else { 'DarkGray' }
                Write-Host ('    (no device) / {0,-32}  {1} [ADD]' -f $r.Inf.Name, $storeTag) -ForegroundColor $color
                Write-Host ('        Class={0,-15}  Provider={1}' -f $r.Class, $r.Provider) -ForegroundColor DarkGray
                Write-Host ('        src: {0}' -f $r.RelSrc) -ForegroundColor $srcColor
            }
        }

        Write-Host ''
        Write-Host ('  I03 install plan: {0} UPGRADE / {1} new ADD / {2} SKIP (current driver same/newer)' -f `
            $decisionCount['INSTALL_UPGRADE'], $decisionCount['INSTALL_NEW'], $decisionCount['SKIP_NEWER']) -ForegroundColor Cyan
    }
    Write-Host ''
    Write-Ok 'Dry-run complete - no system state was modified.'

    Set-DebugStep 'dry-run UEFI Secure Boot baseline cross-ref'
    # Port from chipset: append a compact UEFI Secure Boot baseline
    # readout so operators reviewing V05 know whether the host's
    # firmware-layer trust state is healthy BEFORE they commit to the
    # OS-layer self-signing path in I02/I03.
    Write-Host ''
    Write-Host '[Dry-Run UEFI Baseline] ---------------------------' -ForegroundColor Cyan
    $sbSnapshot = Get-OrEnsureSecureBootBaseline -Ctx $Ctx
    if ($sbSnapshot) {
        Show-SecureBootBaselineSnapshot -Snapshot $sbSnapshot -Compact
        if ($sbSnapshot.Health -eq 'Warning' -or $sbSnapshot.Health -eq 'Critical') {
            Write-Host ("  Health is {0} - review the V06 / report appendix for details." -f $sbSnapshot.Health) -ForegroundColor Yellow
        }
    }

    Write-PhaseFooter 'V05' 'done'
}

#####################################################################
# SECTION 9a-2: V06 helper functions (hardware impact analysis)
#####################################################################
# These helpers support V06 (HardwareImpactAnalysis). They are
# read-only and inspect:
#   1. Currently-attached AMD PnP devices on this machine
#   2. The currently-loaded driver for each such device
#   3. The patched INFs we would install via I03
# and produce a side-by-side AS-IS / TO-BE comparison plus a risk
# classification of each replacement so the user knows what could
# go wrong.

function Resolve-AmdDeviceClassification {
    # ====================================================================
    # Classify an AMD-affiliated PnP device by its enumeration path
    #. Returns @{ Source; IsHardware; Category } where:
    #
    #   Source - one-line label of the enumeration source:
    #                'PCI_VEN_1002' | 'PCI_VEN_1022' | 'ACPI_AMD' |
    #                'ACPI_CPU' | 'ROOT_SW' | 'SWD_SW' |
    #                'MFG_ONLY'
    #
    #   IsHardware - boolean. True for real AMD hardware (PCI vendor
    #                ID 1002 or 1022, or ACPI AMD/AuthenticAMD path).
    #                False for software-only AMD-named entities
    #                (ROOT\, SWD\) and for devices matched only on
    #                their Manufacturer string with no recognizable
    #                AMD vendor ID.
    #
    #   Category - human-readable bucket for grouped display:
    #                'AMD GPU (PCI VEN_1002)'
    #                'AMD CPU/Chipset (PCI VEN_1022)'
    #                'AMD ACPI device'
    #                'AMD CPU core (ACPI)'
    #                'AMD software-only (ROOT)'
    #                'AMD software-only (SWD)'
    #                'Manufacturer-matched only'
    #
    # Detection logic (in order, first match wins):
    #
    #   PCI_VEN_1002 - PCI device whose vendor ID is 1002. Historically
    #                  ATI; AMD acquired ATI in 2006 and continues to
    #                  use 1002 for GPU-related hardware (Radeon, HD
    #                  Audio bus on the GPU side, USB-C on GPU, etc.).
    #
    #   PCI_VEN_1022 - PCI device whose vendor ID is 1022. AMD's
    #                  primary CPU/chipset vendor ID. Covers SMBus,
    #                  PSP, USB controllers, root-port bridges, ISA
    #                  bridge, AHCI/SATA controllers, etc.
    #
    #   ACPI_AMD - ACPI-enumerated AMD motherboard devices like
    #                  AMDI0030 (GPIO), AMDI0090 (mailbox), AMDF030,
    #                  AMD0010, etc. These are firmware-described
    #                  devices on the SoC.
    #
    #   ACPI_CPU - CPU-side enumeration via ACPI. Each logical
    #                  core appears as a separate AUTHENTICAMD_-...
    #                  entry. Hardware, but not a driver-replacement
    #                  target (the CPU runs on AmdPPM in-box).
    #
    #   ROOT_SW - Root-enumerated software-only "devices" with
    #                  AMD-themed names. AMD ships several of these
    #                  (AMDLOG = Crash Defender, AMDXE = Link Controller
    #                  Emulation). They have no underlying hardware -
    #                  they are kernel/user-mode services that PnP
    #                  manages because they ship with their own INF.
    #
    #   SWD_SW - Software-Defined Devices enumerator. AMD-UWP
    #                  Version Control is an example (path
    #                  SWD\DRIVERENUM\AMDUWP&...).
    #
    #   MFG_ONLY - Caught only because Manufacturer string matches
    #                  AMD/ATI but the PNPDeviceID prefix is not AMD-
    #                  recognizable. Treated as software/uncertain.
    # ====================================================================
    param(
        [string]$DeviceID,
        [string]$Manufacturer
    )
    if ($DeviceID -match '^PCI\\VEN_1002\b') {
        return @{ Source='PCI_VEN_1002'; IsHardware=$true;  Category='AMD GPU (PCI VEN_1002)' }
    }
    if ($DeviceID -match '^PCI\\VEN_1022\b') {
        return @{ Source='PCI_VEN_1022'; IsHardware=$true;  Category='AMD CPU/Chipset (PCI VEN_1022)' }
    }
    # HDAUDIO\FUNC_*&VEN_(1002|1022)\... is enumerated as a child
    # of an HD Audio bus, but the FUNC subdevice is real hardware (GPU
    # HDMI audio function for VEN_1002, on-board HDA for VEN_1022).
    # Previously these were buckted under MFG_ONLY and thus excluded
    # from strict-hardware view. The user reported AMD High Definition
    # Audio Device (HDAUDIO\FUNC_01&VEN_1002&DEV_AA01&...) being
    # spuriously excluded.
    if ($DeviceID -match '^HDAUDIO\\FUNC_\d+&VEN_1002\b') {
        return @{ Source='HDAUDIO_VEN_1002'; IsHardware=$true; Category='AMD HD Audio function (HDAUDIO/VEN_1002)' }
    }
    if ($DeviceID -match '^HDAUDIO\\FUNC_\d+&VEN_1022\b') {
        return @{ Source='HDAUDIO_VEN_1022'; IsHardware=$true; Category='AMD HD Audio function (HDAUDIO/VEN_1022)' }
    }
    if ($DeviceID -match '^ACPI\\AMD[FI0-9]') {
        return @{ Source='ACPI_AMD';     IsHardware=$true;  Category='AMD ACPI device' }
    }
    if ($DeviceID -match '^ACPI\\AUTHENTICAMD_') {
        return @{ Source='ACPI_CPU';     IsHardware=$true;  Category='AMD CPU core (ACPI)' }
    }
    if ($DeviceID -match '^ROOT\\') {
        return @{ Source='ROOT_SW';      IsHardware=$false; Category='AMD software-only (ROOT)' }
    }
    if ($DeviceID -match '^SWD\\') {
        return @{ Source='SWD_SW';       IsHardware=$false; Category='AMD software-only (SWD)' }
    }
    return @{ Source='MFG_ONLY';         IsHardware=$false; Category='Manufacturer-matched only' }
}

function Test-DriverIsMicrosoftGeneric {
    # ====================================================================
    # Return $true if the supplied driver record looks like a Microsoft
    # IN-BOX GENERIC driver - i.e. one of the catch-all drivers Windows
    # ships for unmatched hardware. Used by V06/I04 to flag the case
    # described in an earlier revision: "AMD hardware running on a Microsoft generic
    # driver, not on an AMD-specific one".
    #
    # ---- BUGFIX: do not use the Signer field ----
    # Previously this function returned $true whenever the Signer was
    # "Microsoft Windows", which is wrong: Microsoft cosigns every
    # WHQL-certified driver, so an AMD chipset driver shipped via
    # Windows Update will report Signer="Microsoft Windows" while
    # being a genuine vendor driver. The user reported this in an earlier revision:
    # all oem*.inf vendor drivers were spuriously flagged *MS-GENERIC*.
    #
    # New decision rules (any one => generic):
    #   1. InfName matches a known Microsoft generic INF
    #      (storahci.inf, pci.inf, machine.inf, cpu.inf, etc.) AND
    #      InfName does NOT match the oem*.inf pattern (oem*.inf is
    #      ALWAYS a third-party driver registered via pnputil).
    #   2. Provider is exactly "Microsoft" (or Microsoft Windows /
    #      Microsoft Corporation). Only Microsoft-AUTHORED drivers
    #      use this Provider value; vendor drivers report their
    #      vendor name even when WHQL-signed.
    # ====================================================================
    param([Parameter(Mandatory)] $Driver)
    if (-not $Driver) { return $false }

    # oem*.inf is the canonical name pattern for third-party drivers
    # in the Windows DriverStore (assigned by pnputil /add-driver).
    # If the bound INF name matches this pattern, the driver is
    # GUARANTEED to be a vendor driver, never a generic.
    if ($Driver.InfName -and $Driver.InfName -match '(?i)^oem\d+\.inf$') {
        return $false
    }

    $msGenericInfNames = @(
        'storahci.inf',         # Standard SATA AHCI controller
        'msahci.inf',           # legacy AHCI
        'mshdc.inf',            # generic IDE/AHCI host controller
        'pci.inf',              # PCI standard (root ports, bridges)
        'msisadrv.inf',         # PCI Standard ISA Bridge
        'machine.inf',          # PCI standard host CPU bridge / Plug and Play
        'hdaudbus.inf',         # High Definition Audio Bus (in-box)
        'usbxhci.inf',          # USB xHCI in-box
        'usbhub3.inf',          # USB hub in-box
        'basicdisplay.inf',     # Microsoft Basic Display Adapter
        'basicrender.inf',      # Microsoft Basic Render
        'cpu.inf'               # Generic CPU driver (amdppm.sys / intelppm.sys)
    )
    if ($Driver.InfName) {
        $infLower = $Driver.InfName.ToLower()
        foreach ($g in $msGenericInfNames) {
            if ($infLower -eq $g) { return $true }
        }
    }
    # Provider="Microsoft" means MS authored the driver.
    # Provider="AMD"/"Realtek"/etc. with Signer="Microsoft Windows"
    # is a WHQL-cosigned vendor driver - NOT generic.
    if ($Driver.Provider -and $Driver.Provider -match '(?i)^Microsoft\b') {
        return $true
    }
    return $false
}

function Get-AmdHardwareInventory {
    # ====================================================================
    # Enumerate AMD-affiliated PnP devices on the running system.
    #
    # # - Each entry now carries MatchSource, IsAmdHardware, and
    #     HwCategory fields produced by Resolve-AmdDeviceClassification.
    #   - The default behavior is unchanged - all matched entities are
    #     returned. Callers that want STRICT hardware-only results can
    #     pass -HardwareOnly to filter out ROOT\, SWD\, and
    #     manufacturer-only matches.
    #
    # Detection sources (broad query - we classify after):
    #   - PCI vendor IDs: 1002 (GPU/legacy ATI), 1022 (CPU/chipset)
    #   - ACPI vendor IDs: AMDF*, AMDI*, AMD0* (motherboard ACPI)
    #   - ACPI CPU: AUTHENTICAMD_ (one entry per logical core)
    #   - Manufacturer text: 'Advanced Micro Devices', 'AMD', 'ATI'
    #
    # The Manufacturer-only fallback is still part of the broad query
    # because some legitimate AMD ACPI devices report only via
    # Manufacturer (rare). Resolve-AmdDeviceClassification then
    # decides whether the result is real hardware or software-only.
    # ====================================================================
    param([switch]$HardwareOnly)

    $rxId  = '^(PCI\\VEN_(1002|1022)|ACPI\\AMD[FI0-9]|ACPI\\AUTHENTICAMD_)'
    $rxMfg = 'Advanced Micro Devices|^AMD$|^ATI'

    $devices = $null
    try {
        $devices = @(Get-CimInstance -ClassName Win32_PnPEntity -ErrorAction Stop |
            Where-Object {
                ($_.PNPDeviceID -and $_.PNPDeviceID -match $rxId) -or # psa-disable-line PSA2003 -- pattern variable is initialized in the enclosing scope; $null impossible by construction
                ($_.Manufacturer -and $_.Manufacturer -match $rxMfg) # psa-disable-line PSA2003 -- pattern variable is initialized in the enclosing scope; $null impossible by construction
            })
    } catch {
        try {
            $devices = @(Get-WmiObject -Class Win32_PnPEntity -ErrorAction Stop |  # psa-disable-line PSA3006 -- intentional fallback when CIM is constrained; PS 5.1 still supports WMI cmdlets
                Where-Object {
                    ($_.PNPDeviceID -and $_.PNPDeviceID -match $rxId) -or # psa-disable-line PSA2003 -- pattern variable is initialized in the enclosing scope; $null impossible by construction
                    ($_.Manufacturer -and $_.Manufacturer -match $rxMfg) # psa-disable-line PSA2003 -- pattern variable is initialized in the enclosing scope; $null impossible by construction
                })
        } catch {
            return @()
        }
    }
    if (-not $devices) { return @() }

    $out = foreach ($d in $devices) {
        $info = Resolve-AmdDeviceClassification -DeviceID $d.PNPDeviceID -Manufacturer $d.Manufacturer
        [pscustomobject]@{
            Name          = $d.Name
            PNPDeviceID   = $d.PNPDeviceID
            DeviceID      = $d.DeviceID
            Manufacturer  = $d.Manufacturer
            Status        = $d.Status
            Service       = $d.Service
            ConfigCode    = $d.ConfigManagerErrorCode
            ClassGuid     = $d.ClassGuid
            MatchSource   = $info.Source
            IsAmdHardware = $info.IsHardware
            HwCategory    = $info.Category
        }
    }

    if ($HardwareOnly) {
        $out = @($out | Where-Object IsAmdHardware)
    }
    return @($out | Sort-Object @{Expression='HwCategory'},@{Expression='Name'})
}

function Group-AmdDevicesByDisplayKey {
    # ====================================================================
    # Group AMD devices by visual identity so that long lists of
    # essentially-identical entries (e.g. 16 CPU cores, 9 PCI standard
    # host bridges) collapse into a single line with an "x N instances"
    # suffix.
    #
    # Grouping key (composite):
    #   Name - device display name from Win32_PnPEntity
    #   Current InfName - which driver INF is currently bound
    #   Current Version - driver version
    #   Category Code - [A]/[B]/[C]/[?]
    #
    # Two devices share a group iff ALL four fields match. This means
    # the visible information (name + driver + version + category)
    # would render identically for them. The DeviceID itself is NOT
    # part of the key - that's the field we expect to differ between
    # instances of the "same" device.
    #
    # Returns an array of pscustomobject:
    #   @{
    #     DisplayName - Name shared by all members
    #     Count - number of instances in the group
    #     Devices - array of underlying device objects
    #     First - representative device (used for display)
    #     Info - $deviceDriverInfo entry of First
    #     HwCategory - HwCategory of First (for sub-grouping)
    #   }
    #
    # The result preserves a deterministic order (DisplayName) so the
    # caller can iterate without a separate sort.
    # ====================================================================
    param(
        [Parameter(Mandatory)] [array]$Devices,
        [Parameter(Mandatory)] [hashtable]$DeviceDriverInfo
    )
    $groups = [ordered]@{}
    foreach ($d in $Devices) {
        $info = $DeviceDriverInfo[$d.DeviceID]
        $cur  = if ($info) { $info.Current } else { $null }
        $infName  = if ($cur -and $cur.InfName)       { $cur.InfName }       else { '(none)' }
        $infVer   = if ($cur -and $cur.DriverVersion) { $cur.DriverVersion } else { '?' }
        $catCode  = if ($info -and $info.Category)    { $info.Category.Code } else { '?' }
        $key = '{0}||{1}||{2}||{3}' -f $d.Name, $catCode, $infName, $infVer
        if (-not $groups.Contains($key)) {
            $groups[$key] = [pscustomobject]@{
                DisplayName = $d.Name
                Count       = 0
                Devices     = New-Object System.Collections.Generic.List[object]
                First       = $d
                Info        = $info
                HwCategory  = $d.HwCategory
            }
        }
        $groups[$key].Count++
        [void]$groups[$key].Devices.Add($d)
    }
    return @($groups.Values | Sort-Object DisplayName)
}


function ConvertTo-DeviceMatchKey {
    # Reduce a hardware ID to its canonical match key.
    # PCI: PCI\VEN_xxxx&DEV_yyyy[&SUBSYS&REV...] -> PCI\VEN_xxxx&DEV_yyyy
    # ACPI: ACPI\AMDI0090\3&... -> ACPI\AMDI0090
    # USB: USB\VID_xxxx&PID_yyyy\... -> USB\VID_xxxx&PID_yyyy
    # The match key is uppercase. Returns $null for unrecognized
    # formats so the caller can skip them safely.
    param([string]$HwId)
    if ([string]::IsNullOrWhiteSpace($HwId)) { return $null }
    $h = $HwId.ToUpper().Trim()
    if ($h -match '^(PCI\\VEN_[0-9A-F]{4}&DEV_[0-9A-F]{4})')         { return $matches[1] }
    if ($h -match '^(ACPI\\[A-Z0-9_]+)')                              { return $matches[1] }
    if ($h -match '^(USB\\VID_[0-9A-F]{4}&PID_[0-9A-F]{4})')          { return $matches[1] }
    if ($h -match '^([^\\]+\\[^\\&]+)')                               { return $matches[1] }
    return $h
}

function Get-DeviceCurrentDriver {
    # Look up the driver currently bound to a given PnP device.
    # Win32_PnPSignedDriver indexes by DeviceID. Returns $null if no
    # driver is bound (rare; typically means the device is "unknown").
    param([string]$DeviceID)
    if ([string]::IsNullOrWhiteSpace($DeviceID)) { return $null }
    try {
        $drv = Get-CimInstance -ClassName Win32_PnPSignedDriver -ErrorAction Stop |
            Where-Object DeviceID -eq $DeviceID | Select-Object -First 1
    } catch {
        try {
            $drv = Get-WmiObject -Class Win32_PnPSignedDriver -ErrorAction Stop |  # psa-disable-line PSA3006 -- intentional fallback when CIM is constrained; PS 5.1 still supports WMI cmdlets
                Where-Object DeviceID -eq $DeviceID | Select-Object -First 1
        } catch {
            return $null
        }
    }
    if (-not $drv) { return $null }
    $dt = $null
    if ($drv.DriverDate) {
        try {
            # CIM returns CimDateTime; WMI returns string. Both can be
            # rendered consistently via.DateTime / ToString.
            if ($drv.DriverDate -is [string]) {
                $dt = [System.Management.ManagementDateTimeConverter]::ToDateTime($drv.DriverDate)
            } else {
                $dt = [datetime]$drv.DriverDate
            }
        } catch { $dt = $null }
    }
    return [pscustomobject]@{
        DriverVersion = $drv.DriverVersion
        DriverDate    = $dt
        InfName       = $drv.InfName
        Provider      = $drv.DriverProviderName
        Signer        = $drv.Signer
        IsSigned      = $drv.IsSigned
    }
}

function Get-InfRiskCategory {
    # Classify a patched INF by the risk of its driver-install failure
    # destabilizing the running system. Levels:
    #   HIGH - boot or system-stability impact possible
    #   MEDIUM - features / subsystems may break, but system stays up
    #   LOW - peripheral or feature-only, no boot impact
    # The classification is heuristic and based on the driver's role.
    param([string]$InfName, [string]$Class)
    if (-not $InfName) {
        return [pscustomobject]@{ Level='MEDIUM'; Reason='unknown driver - assuming medium risk' }
    }
    $name = $InfName.ToLower()

    # ---- HIGH ----
    if ($name -match 'iov')        { return [pscustomobject]@{ Level='HIGH'; Reason='I/O virtualization (IOMMU) - failure may cause memory translation hangs or BSOD' } }
    if ($name -match 'pcidev')     { return [pscustomobject]@{ Level='HIGH'; Reason='PCI device enumeration - failure may make downstream PCI devices invisible' } }
    if ($name -match 'amdpsp')     { return [pscustomobject]@{ Level='HIGH'; Reason='Platform Security Processor - if BitLocker / TPM is enabled, boot may fail' } }
    if ($name -match 'plutonnull') { return [pscustomobject]@{ Level='HIGH'; Reason='Pluton security null driver - misload may disable hardware-backed BitLocker' } }

    # ---- MEDIUM ----
    if ($name -match 'smbus')      { return [pscustomobject]@{ Level='MEDIUM'; Reason='SMBus controller - motherboard sensors / fan control / RGB may stop working' } }
    if ($name -match 'gpio')       { return [pscustomobject]@{ Level='MEDIUM'; Reason='GPIO controller - hardware buttons and power-management signaling may fail' } }
    # Usbledfd rule placed BEFORE the generic 'usb' rule so the
    # specific (LOW) RGB-lighting classification wins. Without this
    # ordering, amdusbledfd.inf would fall into the generic MEDIUM
    # "USB filter / hub driver" bucket and overstate the risk.
    if ($name -match 'usbledfd')   { return [pscustomobject]@{ Level='LOW';    Reason='AMD Radeon LED USB driver - RGB lighting only; no boot or audio/display impact' } }
    if ($name -match 'usb')        { return [pscustomobject]@{ Level='MEDIUM'; Reason='USB filter / hub driver - all USB devices on this controller may stop responding' } }
    if ($name -match 'zenpromnf')  { return [pscustomobject]@{ Level='MEDIUM'; Reason='S0i3 Network Filter - connected standby / sleep on networked workloads may fail' } }
    if ($name -match 'amdi2c')     { return [pscustomobject]@{ Level='MEDIUM'; Reason='I2C bus - sensor / touchpad / camera / battery telemetry may fail' } }
    if ($name -match 'micropep')   { return [pscustomobject]@{ Level='MEDIUM'; Reason='Power Engine Plugin (PEP) - CPU power-state coordination, may affect modern standby' } }
    if ($name -match 'hsmp')       { return [pscustomobject]@{ Level='MEDIUM'; Reason='Host System Management Port - server-side telemetry/control feature for EPYC class' } }
    if ($name -match 'mailbox')    { return [pscustomobject]@{ Level='MEDIUM'; Reason='AMS mailbox - inter-component messaging, may affect platform features' } }
    if ($name -match 'interface')  { return [pscustomobject]@{ Level='MEDIUM'; Reason='AMD Interface (chipset enumeration) - infrastructure for other AMD drivers' } }

    # ---- MEDIUM (display / graphics-package additions, an earlier revision) ----
    # The graphics installer ships a numerical "universal INF" (e.g. u0197843.inf)
    # alongside several supporting INFs. Classify each by role so V06's
    # Risk Assessment doesn't fall back to the chipset-flavored generic.
    if ($name -match '^u\d{6,8}')  { return [pscustomobject]@{ Level='MEDIUM'; Reason='AMD display driver (universal INF) - rendering failure falls back to MS Basic Display Adapter; RDP and VGA console remain usable' } }
    if ($name -match 'amdpcibridge') { return [pscustomobject]@{ Level='MEDIUM'; Reason='AMD PCI Express bridge extension - downstream GPU enumeration may be affected if it fails to load' } }
    if ($name -match 'amdafd')     { return [pscustomobject]@{ Level='MEDIUM'; Reason='AMD Function Driver (display class enumerator) - low-level GPU subsystem helper' } }

    # ---- LOW ----
    if ($name -match 'wirelessbutton|wbd') { return [pscustomobject]@{ Level='LOW'; Reason='Wireless radio toggle button - laptop only; servers unaffected' } }
    if ($name -match 'sfh')        { return [pscustomobject]@{ Level='LOW'; Reason='Sensor Fusion Hub - laptop sensors; servers unaffected' } }
    if ($name -match 'uart')       { return [pscustomobject]@{ Level='LOW'; Reason='UART (serial) - rarely used; OS recovers if missing' } }
    if ($name -match 'pmf')        { return [pscustomobject]@{ Level='LOW'; Reason='Platform Management Framework - adaptive power feature; no boot impact' } }
    if ($name -match 'appcompat')  { return [pscustomobject]@{ Level='LOW'; Reason='Application compatibility database - utility driver; no boot impact' } }
    if ($name -match 'cache|3dv')  { return [pscustomobject]@{ Level='LOW'; Reason='3D V-Cache performance optimizer - X3D-only; no boot impact' } }
    if ($name -match 'ppmpf|ppkg|oemprov') { return [pscustomobject]@{ Level='LOW'; Reason='Provisioning / OEM customization - feature driver; no boot impact' } }
    if ($name -match 'cir')        { return [pscustomobject]@{ Level='LOW'; Reason='Consumer infrared receiver - rarely used' } }
    if ($name -match 'as4')        { return [pscustomobject]@{ Level='LOW'; Reason='AMD AS4 (legacy chipset) - older platforms only' } }

    # ---- LOW (display / graphics-package additions, an earlier revision) ----
    if ($name -match '^amdocl')    { return [pscustomobject]@{ Level='LOW'; Reason='AMD OpenCL user-mode runtime - GPU compute apps only; no boot or display impact' } }
    if ($name -match '^amdfendr')  { return [pscustomobject]@{ Level='LOW'; Reason='AMD Crash Defender - GPU crash telemetry/diagnostics; no boot or display impact' } }
    if ($name -match '^amdfdans')  { return [pscustomobject]@{ Level='LOW'; Reason='AMD Dynamic Audio Noise Suppression - audio enhancement only; no boot/display impact' } }
    if ($name -match '^amdwin')    { return [pscustomobject]@{ Level='LOW'; Reason='AMD Windows Support Components (UWP glue) - feature only; no boot impact' } }
    if ($name -match '^amdxe')     { return [pscustomobject]@{ Level='LOW'; Reason='AMD Link controller emulation (XE) - companion-app feature; no boot impact' } }

    # ---- MEDIUM (audio / connector additions, an earlier revision) ----
    # The graphics installer ships AMD's audio coprocessor stack
    # (ACPBus, HD Audio, HDMI audio) and USB-C connector manager.
    # earlier these all fell back to "AMD driver (uncategorized)"
    # in V06's risk assessment because the original classifier was
    # focused on chipset INFs (smbus, gpio, micropep,...).
    # Order matters: more specific first to avoid the broader
    # 'amdacp' rule swallowing 'amdacpbusext' / 'amdacpafd'.
    if ($name -match 'amdacpbusext') { return [pscustomobject]@{ Level='LOW';    Reason='AMD Audio CoProcessor extension - filter on top of ACPBus; primary audio function unaffected if it fails' } }
    if ($name -match 'amdacpbus')    { return [pscustomobject]@{ Level='MEDIUM'; Reason='AMD Audio CoProcessor PCI bus driver - if it fails, the entire AMD audio subsystem (mic input, internal speakers via ACP) may stop working; no boot impact' } }
    if ($name -match 'amdacpafd')    { return [pscustomobject]@{ Level='LOW';    Reason='AMD Audio CoProcessor Function Driver - audio path component; primary audio output via HD Audio bus is independent' } }
    if ($name -match 'amdacpbt')     { return [pscustomobject]@{ Level='LOW';    Reason='AMD Audio CoProcessor Bluetooth audio - BT audio only; no impact on wired/HDMI audio or boot' } }
    if ($name -match 'amdhdaudbus')  { return [pscustomobject]@{ Level='MEDIUM'; Reason='AMD HD Audio bus - replacing the bus driver may temporarily lose all HD Audio devices; system continues to boot, sound returns after reload' } }
    if ($name -match '^atihd')       { return [pscustomobject]@{ Level='MEDIUM'; Reason='AMD HDMI/DisplayPort audio - failure breaks audio over external displays; analog audio jack and Bluetooth unaffected; no boot impact' } }
    if ($name -match 'amdi2stdmafd'){ return [pscustomobject]@{ Level='LOW';    Reason='AMD I2S TDM Audio Function Driver - serial audio path used on some platforms; no boot impact' } }
    if ($name -match 'amdsafd')      { return [pscustomobject]@{ Level='LOW';    Reason='AMD Streaming Audio Function Driver - specialized audio path; no boot impact' } }
    if ($name -match 'amducsi')      { return [pscustomobject]@{ Level='MEDIUM'; Reason='AMD UCM-UCSI (USB-C connector manager) - if it fails, USB-C alt-modes (DisplayPort over USB-C, USB Power Delivery) may degrade; USB-A unaffected' } }
    # NOTE: the 'usbledfd' rule is intentionally placed earlier
    # in this function (before the generic 'usb' MEDIUM rule) so the
    # specific LOW classification for RGB lighting wins. Do not add a
    # duplicate here.

    return [pscustomobject]@{ Level='MEDIUM'; Reason='AMD driver (uncategorized) - replacement risk depends on its role' }
}

function Build-PatchedInfHwidIndex {
    # Walk every.inf in $Ctx.Paths.Patched and build a hashtable
    # mapping match-key (e.g. PCI\VEN_1022&DEV_1134) to the INF that
    # claims that hardware ID. The same key may map to multiple INFs
    # (rare, but possible in AMD's package - e.g. variants per SKU).
    param([Parameter(Mandatory)] $Ctx)
    $index = @{}
    if (-not (Test-Path $Ctx.Paths.Patched)) { return $index }
    $infs = @(Get-ChildItem -Path $Ctx.Paths.Patched -Recurse -Filter *.inf -ErrorAction SilentlyContinue)
    foreach ($inf in $infs) {
        $data = $null
        try {
            $data = Read-InfFile -Path $inf.FullName
        } catch { continue }
        if (-not $data) { continue }
        $meta = Get-InfMetadata -Content $data.Content
        $relSrc = $inf.Directory.FullName.Substring($Ctx.Paths.Patched.Length).TrimStart('\')
        if ($relSrc.StartsWith('Packages\IODriver\', [StringComparison]::OrdinalIgnoreCase)) {
            $relSrc = $relSrc.Substring('Packages\IODriver\'.Length)
        }
        $relSrc = $relSrc -replace '\\W11x64\\', '\' -replace '\\W11x64$', '' `
                          -replace '\\WTx64\\',  '\' -replace '\\WTx64$',  ''
        $relSrc = $relSrc.TrimEnd('\').TrimStart('\')

        $entry = [pscustomobject]@{
            InfName    = $inf.Name
            FullPath   = $inf.FullName
            SrcSubDir  = $relSrc
            DriverVer  = $meta.DriverVer
            Class      = $meta.Class
            Provider   = $meta.Provider
            DeviceCount = $meta.DeviceCount
        }
        foreach ($dev in $meta.Devices) {
            $key = ConvertTo-DeviceMatchKey -HwId $dev.HardwareId
            if (-not $key) { continue }
            if (-not $index.ContainsKey($key)) { $index[$key] = @() }
            $index[$key] += $entry
        }
    }
    return $index
}

function Format-DriverVerString {
    # Render an INF DriverVer field ("MM/DD/YYYY,version") in a single
    # consistent column-friendly form for display.
    param([string]$Raw)
    if ([string]::IsNullOrWhiteSpace($Raw)) { return '(none)' }
    $parts = $Raw.Split(',')
    if ($parts.Count -ge 2) {
        return ('v{0,-15} ({1})' -f $parts[1].Trim(), $parts[0].Trim())
    }
    return $Raw
}

function ConvertFrom-DriverVerString {
    # ====================================================================
    # Parse a DriverVer-style string into a structured form for
    # comparison. Accepts both INF DriverVer format and the bare
    # version string returned by Win32_PnPSignedDriver:
    #
    #   INF format: "MM/DD/YYYY,V.V.V.V" (e.g. "01/02/2026,5.43.0.0")
    #   PnP format: "V.V.V.V" (e.g. "5.22.0.0")
    #
    # Returns @{ Date=<datetime|null>; Version=<version|null>; Raw=string }.
    # Returns null if input is null/whitespace.
    # ====================================================================
    param([string]$Raw)
    if ([string]::IsNullOrWhiteSpace($Raw)) { return $null }
    $r = @{ Date=$null; Version=$null; Raw=$Raw.Trim() }
    if ($Raw -match '^\s*(\d{1,2}/\d{1,2}/\d{4})\s*,\s*([\d\.]+)\s*$') {
        try {
            $r.Date = [datetime]::ParseExact($matches[1], 'M/d/yyyy',
                [System.Globalization.CultureInfo]::InvariantCulture)
        } catch {} # psa-disable-line PSA3004 -- intentional best-effort cleanup; no error to surface
        try { $r.Version = [version]$matches[2] } catch {} # psa-disable-line PSA3004 -- intentional best-effort cleanup; no error to surface
        return $r
    }
    if ($Raw -match '^\s*([\d\.]+)\s*$') {
        try { $r.Version = [version]$matches[1] } catch {} # psa-disable-line PSA3004 -- intentional best-effort cleanup; no error to surface
        return $r
    }
    return $r
}

function Compare-InfDriverVer {
    # ====================================================================
    # Compare two driver versions and return:
    #   +1 if Left is strictly NEWER than Right
    #   -1 if Left is strictly OLDER than Right
    #    0 if same OR comparison is inconclusive
    #
    # Logic:
    #   1. Parse both sides. If both have a parseable Version, compare
    #      those first - this is the authoritative signal.
    #   2. If versions tie OR one is missing, fall back to the date.
    #   3. If neither version nor date can be compared, return 0.
    #
    # The Right-side date can be passed explicitly because
    # Win32_PnPSignedDriver returns date and version as separate
    # fields (the version string alone is "5.22.0.0", with no embedded
    # date). The Left side typically comes from an INF DriverVer.
    # ====================================================================
    param(
        [string]$LeftRaw,    [datetime]$LeftDate  = [datetime]::MinValue,
        [string]$RightRaw,   [datetime]$RightDate = [datetime]::MinValue
    )
    $L = ConvertFrom-DriverVerString -Raw $LeftRaw
    $R = ConvertFrom-DriverVerString -Raw $RightRaw

    $lDate = if ($LeftDate  -ne [datetime]::MinValue) { $LeftDate  } elseif ($L) { $L.Date } else { $null }
    $rDate = if ($RightDate -ne [datetime]::MinValue) { $RightDate } elseif ($R) { $R.Date } else { $null }

    if ($L -and $R -and $L.Version -and $R.Version) {
        if ($L.Version -gt $R.Version) { return  1 }
        if ($L.Version -lt $R.Version) { return -1 }
    }
    # Compare DATE PORTION only (year/month/day), not the full DateTime.
    # Win32_PnPSignedDriver returns DriverDate as UTC midnight, which the CIM
    # cmdlets convert to LOCAL time on read - so in non-UTC zones, a "midnight
    # UTC" date appears as a non-midnight local time (e.g. 09:00 in Tokyo,
    # UTC+9). The INF DriverVer date is parsed as local-midnight. Without
    # truncation, an identical date appears as "current is 9h newer" and
    # cmp returns -1 instead of 0 - producing the misleading V06 message
    # "current (X) newer than patched (X); keeping current" for same-version
    # drivers.
    if ($lDate -and $rDate) {
        $lD = $lDate.Date
        $rD = $rDate.Date
        if ($lD -gt $rD) { return  1 }
        if ($lD -lt $rD) { return -1 }
    }
    return 0
}

function Get-OurSignedOemInfSet {
    # ====================================================================
    # Build a lookup hashtable of INF / catalog filenames known to be
    # signed by the supplied $ExpectedThumbprint. Designed to be built
    # ONCE per Invoke-InstPhase04 invocation and passed into every
    # Get-DriverSourceCategory call via -KnownOurInfSet. This avoids
    # the per-device disk I/O that Step 0a otherwise pays when the
    # post-install snapshot enumerates dozens of devices.
    #
    # The set is built in two passes:
    #   1. Direct scan of C:\Windows\INF\oem*.cat - for each catalog
    #      file whose signer thumbprint matches $ExpectedThumbprint, add
    #      both 'oem<N>.inf' and 'oem<N>.cat' to the set.
    #   2. pnputil /enum-drivers cross-reference - the pnputil output
    #      maps each OEM-published name to its Original Name (e.g.,
    #      oem45.inf -> u0201039.inf). For every match found in pass 1,
    #      also add the Original Name to the set. This handles cases
    #      where Win32_PnPSignedDriver.InfName returns the original
    #      short name instead of the OEM-numbered form. The pnputil
    #      label-line regex matches both English ("Published Name",
    #      "Original Name") and Japanese ("公開名" / "発行された名前",
    #      "元の名前" / "元のファイル名") variants observed across
    #      WS2016 / WS2019 / WS2022 / WS2025 builds.
    #
    # Keys are stored lower-case; callers MUST use ToLowerInvariant
    # before lookup.
    #
    # Returns: hashtable on success, empty hashtable on failure or when
    #          no catalogs match the thumbprint.
    # ====================================================================
    param([Parameter(Mandatory)] [string]$ExpectedThumbprint)
    $set = @{}
    if ([string]::IsNullOrWhiteSpace($ExpectedThumbprint)) { return $set }

    # ---- Pass 1: scan C:\Windows\INF\oem*.cat ----
    $infDir = Join-Path $env:windir 'INF'
    if (-not (Test-Path -LiteralPath $infDir)) { return $set }
    $matchedOemBases = @{}
    try {
        $catFiles = @(Get-ChildItem -LiteralPath $infDir -Filter 'oem*.cat' -ErrorAction SilentlyContinue)
        foreach ($cat in $catFiles) {
            try {
                $sig = Get-AuthenticodeSignature -LiteralPath $cat.FullName -ErrorAction Stop
                if ($sig -and $sig.SignerCertificate -and
                    $sig.SignerCertificate.Thumbprint -eq $ExpectedThumbprint) {
                    $oemBase = [System.IO.Path]::GetFileNameWithoutExtension($cat.Name).ToLowerInvariant()
                    $matchedOemBases[$oemBase] = $true
                    $set[$oemBase + '.inf'] = $true
                    $set[$oemBase + '.cat'] = $true
                }
            } catch {} # psa-disable-line PSA3004 -- best-effort; one unreadable catalog must not abort the scan
        }
    } catch {} # psa-disable-line PSA3004 -- best-effort; INF dir enumeration failure leaves set unchanged

    if ($matchedOemBases.Count -eq 0) { return $set }

    # ---- Pass 2: pnputil /enum-drivers cross-reference ----
    # Parse text output rather than relying on pnputil /format:csv,
    # because /format support varies across WS2016 / 2019 / 2022 / 2025
    # builds. Label regexes accept both English and Japanese variants;
    # other locales degrade gracefully (Pass 1 oem<N>.inf entries are
    # still in the set).
    $stdout = $null
    try {
        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = 'pnputil.exe'
        $psi.Arguments = '/enum-drivers'
        $psi.UseShellExecute = $false
        $psi.RedirectStandardOutput = $true
        $psi.RedirectStandardError  = $true
        $psi.CreateNoWindow = $true
        $proc = [System.Diagnostics.Process]::Start($psi)
        $stdout = $proc.StandardOutput.ReadToEnd()
        [void]$proc.StandardError.ReadToEnd()
        $proc.WaitForExit()
        $proc.Dispose()
    } catch {} # psa-disable-line PSA3004 -- pnputil unavailable: degrade gracefully

    if (-not $stdout) { return $set }

    $currentPublished = $null
    $currentOriginal  = $null
    $commitRecord = {
        param($pub, $orig)
        if ($pub -and $orig) {
            $pubBase = [System.IO.Path]::GetFileNameWithoutExtension($pub).ToLowerInvariant()
            if ($matchedOemBases.ContainsKey($pubBase)) {
                $set[$orig.ToLowerInvariant()] = $true
            }
        }
    }
    foreach ($line in ($stdout -split "`r?`n")) {
        $t = $line.Trim()
        if ([string]::IsNullOrWhiteSpace($t)) {
            & $commitRecord $currentPublished $currentOriginal
            $currentPublished = $null
            $currentOriginal  = $null
            continue
        }
        # Published Name (English) / 公開名 / 発行された名前 (Japanese)
        if ($t -match '^(?:Published Name|Published name|公開名|発行された名前)\s*[:：]\s*(.+?)\s*$') {
            $currentPublished = $matches[1]
        } elseif ($t -match '^(?:Original Name|Original name|元の名前|元のファイル名|元のドライバー名)\s*[:：]\s*(.+?)\s*$') {
            $currentOriginal = $matches[1]
        }
    }
    # Commit the final record if the stdout did not end with a blank line.
    & $commitRecord $currentPublished $currentOriginal

    return $set
}

function Get-DriverSourceCategory {
    # ====================================================================
    # Classify a driver by its source / publisher into one of four
    # buckets:
    #
    #   [A] Microsoft (OS in-box drivers)
    #   [B] Hardware vendor / IHV (signed by AMD, NVIDIA, OEM, etc.)
    #   [C] Self-signed by THIS script's certificate
    #   [?] Unknown / unsigned / uncategorizable
    #
    # ---- Enhancement (2026-05): catalog-thumbprint primary path ----
    # The legacy implementation relied solely on Win32_PnPSignedDriver.
    # Signer (a friendly-name string) to detect [C] Self-Signed. In
    # practice WMI returns an empty Signer for self-signed catalogs
    # whose root CA is NOT in the Microsoft trust hierarchy, even
    # AFTER our cert has been imported into LocalMachine\Root and
    # WDAC has authorized it. That made Step 1 (string match) miss
    # legitimately self-signed drivers, which then fell through to
    # Step 3 and were reported as [B] Vendor because the patched INF
    # still has Provider="Advanced Micro Devices, Inc".
    #
    # New Step 0 reads the on-disk catalog (.cat) directly via
    # Get-AuthenticodeSignature and compares SignerCertificate.
    # Thumbprint against the caller-supplied ExpectedSelfSignThumbprint
    # (typically $Ctx.CertThumbprint). When the thumbprints match, the
    # driver is conclusively classified as [C], independent of how WMI
    # chose to render the Signer field.
    #
    # ---- BUGFIX (legacy): trust Provider, NOT Signer ----
    # The Signer field on ANY WHQL-signed driver reads "Microsoft
    # Windows" because MS cosigns WHQL submissions; that is why we
    # NEVER consult Signer for [A] Microsoft detection (vendor
    # drivers from AMD/NVIDIA/etc. would all collapse to [A]).
    #
    # Decision order:
    #   0a. (NEW) Catalog thumbprint matches ExpectedSelfSignThumbprint => [C]
    #   0b. (NEW) InfName is listed in a pre-built KnownOurInfSet => [C]
    #            (covers cases where Win32_PnPSignedDriver.InfName does
    #            not resolve to a C:\Windows\INF\<oemNN>.cat path, e.g.
    #            when it returns the original short name instead of the
    #            OEM-numbered short name on certain WS builds; the set
    #            is built once per I04 invocation by scanning every
    #            C:\Windows\INF\oem*.cat for our cert thumbprint and
    #            mapping back through pnputil /enum-drivers).
    #   1. Signer string matches our self-sign markers => [C]
    #      (fallback for callers that cannot resolve the .cat path)
    #   2. Provider is "Microsoft" / "Microsoft Windows" / "Microsoft Corporation" => [A]
    #   3. Any other non-empty Provider => [B]
    #   4. No Provider => [?]
    # ====================================================================
    param(
        [string]$Provider,
        [string]$Signer,
        # Optional: when provided, enables Step 0 (catalog-thumbprint
        # primary path). InfName is the OEM-numbered short form (e.g.,
        # 'oem32.inf'); the matching catalog is C:\Windows\INF\oem32.cat.
        [string]$InfName = '',
        [string]$ExpectedSelfSignThumbprint = '',
        # Optional: hashtable whose KEYS are filenames known to be signed
        # by ExpectedSelfSignThumbprint (e.g. 'oem45.inf', 'u0201039.inf').
        # Build once per I04 via Get-OurSignedOemInfSet, then pass into
        # every Get-DriverSourceCategory call to avoid re-signing-check
        # I/O per device. Lookup is case-insensitive.
        [hashtable]$KnownOurInfSet = $null
    )
    # Step 0a (NEW): direct catalog-signer thumbprint match.
    # Highest-confidence path. Skipped silently if either parameter is
    # empty or if the .cat file is not readable; falls through to the
    # legacy Signer-string heuristic in that case.
    if ($InfName -and $ExpectedSelfSignThumbprint) {
        $catPath = Join-Path (Join-Path $env:windir 'INF') ([System.IO.Path]::ChangeExtension($InfName, '.cat'))
        if (Test-Path -LiteralPath $catPath) {
            try {
                $sig = Get-AuthenticodeSignature -LiteralPath $catPath -ErrorAction Stop
                if ($sig -and $sig.SignerCertificate -and
                    $sig.SignerCertificate.Thumbprint -eq $ExpectedSelfSignThumbprint) {
                    return @{
                        Code='C'; ShortLabel='[C]'
                        Label='Self-Signed (this script, catalog thumbprint match)'
                        Color='Magenta'
                    }
                }
            } catch {} # psa-disable-line PSA3004 -- best-effort; fall through to Signer-string match
        }
    }
    # Step 0b (NEW): pre-built KnownOurInfSet lookup.
    # Authoritative when the caller built the set by walking
    # C:\Windows\INF\oem*.cat + pnputil /enum-drivers at the start of
    # I04. Case-insensitive on InfName because pnputil's published-name
    # column historically uses lower-case (oemNN.inf) but legacy code
    # paths sometimes mix cases.
    if ($InfName -and $KnownOurInfSet -and $KnownOurInfSet.Count -gt 0) {
        $lookupKey = $InfName.ToLowerInvariant()
        if ($KnownOurInfSet.ContainsKey($lookupKey)) {
            return @{
                Code='C'; ShortLabel='[C]'
                Label='Self-Signed (this script, OEM-name set match)'
                Color='Magenta'
            }
        }
    }
    # Step 1 (FALLBACK): Signer string match
    if ($Signer) {
        if ($Signer -match '(?i)\bSelf-Sign\b' -or
            $Signer -match '(?i)At Own Risk' -or
            $Signer -match '(?i)Self-Signed Lab') {
            return @{
                Code='C'; ShortLabel='[C]'
                Label='Self-Signed (this script)'
                Color='Magenta'
            }
        }
    }
    # Step 2: Microsoft - check Provider ONLY, not Signer (WHQL ≠ MS-authored)
    if ($Provider) {
        if ($Provider -match '(?i)^Microsoft\s+(Windows|Corporation)' -or
            $Provider -match '(?i)^Microsoft$') {
            return @{
                Code='A'; ShortLabel='[A]'
                Label='Microsoft (OS in-box)'
                Color='Cyan'
            }
        }
    }
    # Step 3: Vendor - any non-Microsoft Provider value
    if ($Provider) {
        return @{
            Code='B'; ShortLabel='[B]'
            Label=('Vendor: {0}' -f $Provider.Trim())
            Color='Green'
        }
    }
    # Step 4: No Provider - cannot categorize
    return @{
        Code='?'; ShortLabel='[?]'
        Label='Unknown / unsigned'
        Color='DarkGray'
    }
}

function Resolve-PerDeviceDriverDecision {
    # ====================================================================
    # Decide what should happen to a single device during I03.
    #
    # ---- BREAKING SPECIFICATION CHANGE: category-priority override ----
    # The driver-source category now takes precedence over version
    # comparison when AS-IS and TO-BE are in different categories.
    # Category priority (highest to lowest):
    #
    #   [C] Self-signed (this script's output) = highest
    #   [B] Hardware vendor / IHV = middle
    #   [A] Microsoft (OS in-box) = lowest
    #   [?] Unknown / unsigned = treated as lowest
    #
    # Because the TO-BE driver produced by this pipeline is ALWAYS [C]
    # (we just signed the patched INFs with our own certificate), the
    # rule simplifies to:
    #
    #   - AS-IS in [A]/[B]/[?] -> TO-BE [C] WINS (install regardless
    #                                of version comparison)
    #   - AS-IS in [C] -> fall back to version comparison
    #                                (avoid pointless reinstall of an
    #                                earlier run's self-signed driver)
    #
    # Rationale: Microsoft's generic in-box drivers (display.inf,
    # hdaudbus.inf, basicdisplay.inf, etc.) carry OS-build versions
    # (e.g. 10.0.26100.1150) that numerically dominate AMD's semantic
    # vendor versions (e.g. 6.0.1.83). Pure version comparison therefore
    # never replaces a Microsoft generic with an AMD vendor driver.
    # The operator's intent when running this script is to put AMD-
    # specific drivers on AMD hardware - so category overrides version.
    #
    # Inputs:
    #   $Current - Get-DeviceCurrentDriver result (or $null if no
    #                  driver bound)
    #   $Candidates - patched-INF entries from
    #                  Build-PatchedInfHwidIndex that match this
    #                  device's HWID
    #
    # Decisions:
    #   INSTALL_UPGRADE - patched INF should replace current driver.
    #                      Triggered by EITHER category-priority override
    #                      OR strictly-newer version (when both sides
    #                      are in the same category).
    #   INSTALL_NEW - device has no driver bound; safe to add.
    #   SKIP_NEWER - current driver is strictly newer (same-
    #                      category comparison only).
    #   SKIP_SAME - patched INF is the same version as current
    #                      (same-category comparison only).
    #
    # When multiple candidates exist for the same device, picks the
    # NEWEST candidate (highest version) and uses it for the decision.
    # The unchosen candidates are preserved in $sorted for reporting.
    #
    # Returns @{ Decision; ChosenInf; Reason; Comparison;
    #            CandidatesByNewest } - the comparison sign mirrors
    # Compare-InfDriverVer.
    # ====================================================================
    param($Current, $Candidates)
    if (-not $Candidates -or $Candidates.Count -eq 0) {
        return @{
            Decision='SKIP_SAME'; ChosenInf=$null
            Reason='no candidates'; Comparison=0
            CandidatesByNewest=@()
        }
    }
    # Sort candidates by parsed version (descending) so [0] is newest.
    # Falling back to [version]'0.0.0.0' for unparseable entries
    # ensures they sort to the bottom rather than throwing.
    $sorted = @($Candidates | Sort-Object @{
        Expression = {
            $p = ConvertFrom-DriverVerString -Raw $_.DriverVer
            if ($p -and $p.Version) { $p.Version } else { [version]'0.0.0.0' }
        }
        Descending = $true
    })
    $newest = $sorted[0]
    if (-not $Current) {
        return @{
            Decision='INSTALL_NEW'; ChosenInf=$newest
            Reason='no current driver bound; will install patched version'
            Comparison=1; CandidatesByNewest=$sorted
        }
    }
    # Category-priority override (see function header for rationale).
    # The TO-BE driver this pipeline produces is always [C] Self-signed,
    # so any AS-IS category OTHER than [C] is automatically superseded.
    $curCatInfo = Get-DriverSourceCategory -Provider $Current.Provider -Signer $Current.Signer -InfName $Current.InfName -ExpectedSelfSignThumbprint $Ctx.CertThumbprint
    $curCatCode = if ($curCatInfo) { $curCatInfo.Code } else { '?' }
    if ($curCatCode -ne 'C') {
        return @{
            Decision='INSTALL_UPGRADE'; ChosenInf=$newest
            Reason=('category priority [{0}] -> [C]: this script''s self-signed driver outranks the current [{0}] driver' -f $curCatCode)
            Comparison=1; CandidatesByNewest=$sorted
        }
    }
    # AS-IS is [C] (earlier run's output); use version comparison to avoid
    # pointless reinstall when nothing has changed.
    $rd = if ($Current.DriverDate) { $Current.DriverDate } else { [datetime]::MinValue }
    $cmp = Compare-InfDriverVer -LeftRaw $newest.DriverVer -RightRaw $Current.DriverVersion -RightDate $rd
    if ($cmp -gt 0) {
        # Distinguish "version-newer" from "same-version, date-newer".
        # Both produce cmp > 0 (UPGRADE), but the user-visible reason text
        # was previously identical, so a "10.0.1.30 -> 10.0.1.30 UPGRADE"
        # looked nonsensical. PnP ranking treats newer date as newer driver
        # when versions tie, which is the correct behavior - we just need
        # to explain it in plain language.
        $lParsed = ConvertFrom-DriverVerString -Raw $newest.DriverVer
        $rParsed = ConvertFrom-DriverVerString -Raw $Current.DriverVersion
        $sameVersion = ($lParsed -and $rParsed -and $lParsed.Version -and $rParsed.Version -and $lParsed.Version -eq $rParsed.Version)
        $reasonText = if ($sameVersion) {
            'patched same version ({0}) but newer date; PnP ranking prefers newer-dated driver' -f $rParsed.Version
        } else {
            'patched newer ({0}) than current ({1})' -f $newest.DriverVer.Trim(), $Current.DriverVersion
        }
        return @{
            Decision='INSTALL_UPGRADE'; ChosenInf=$newest
            Reason=$reasonText
            Comparison=1; CandidatesByNewest=$sorted
        }
    }
    if ($cmp -lt 0) {
        return @{
            Decision='SKIP_NEWER'; ChosenInf=$newest
            Reason=('current [C] ({0}) newer than patched [C] ({1}); keeping current self-signed' -f $Current.DriverVersion, $newest.DriverVer.Trim())
            Comparison=-1; CandidatesByNewest=$sorted
        }
    }
    return @{
        Decision='SKIP_SAME'; ChosenInf=$newest
        Reason=('same version ({0}); no upgrade benefit' -f $Current.DriverVersion)
        Comparison=0; CandidatesByNewest=$sorted
    }
}

function Resolve-PerInfInstallDecision {
    # ====================================================================
    # Decide install/skip for a single PATCHED INF. Mirror of
    # Resolve-PerDeviceDriverDecision, but per-INF rather than
    # per-device. Used by I03 to decide whether to call pnputil.
    #
    # ---- BREAKING SPECIFICATION CHANGE: category-priority override ----
    # See Resolve-PerDeviceDriverDecision for the full rationale.
    # Summary: the TO-BE driver this pipeline produces is always
    # [C] Self-signed, which now ranks ABOVE both [A] Microsoft
    # generic and [B] vendor drivers. Version comparison applies
    # only when the AS-IS driver is also [C].
    #
    # Inputs:
    #   $InfEntry - patched-INF metadata (from Get-InfMetadata)
    #   $InfMatchedDevices - array of @{Device; Current} pairs for
    #                          AMD devices whose HWID is declared by
    #                          this INF. Empty if no current device matches.
    #
    # Decisions:
    #   INSTALL_NEW - INF declares no HWIDs that match any current
    #                     device. Safe to add to driver store - it
    #                     won't displace any current driver and may
    #                     help if hardware appears later.
    #   INSTALL_UPGRADE - At least one matched device benefits from this
    #                     INF, either by category-priority override
    #                     (AS-IS is [A]/[B]/[?]) or by strictly-newer
    #                     version (same-category [C] vs [C] comparison).
    #   SKIP_NEWER - All matched devices are already on [C] and
    #                     have the same/newer self-signed driver
    #                     version. Skip to avoid pointless reinstall.
    #
    # Returns @{ Decision; Reason; AffectedDeviceCount; DetailReasons }
    # ====================================================================
    param(
        $InfEntry,
        $InfMatchedDevices
    )
    if (-not $InfMatchedDevices -or $InfMatchedDevices.Count -eq 0) {
        return @{
            Decision='INSTALL_NEW'
            Reason='INF has no HWID match against current devices; add to driver store only'
            AffectedDeviceCount=0
            DetailReasons=@()
        }
    }
    $upgrades = 0
    $reasons  = @()
    foreach ($pair in $InfMatchedDevices) {
        $cur = $pair.Current
        if (-not $cur) {
            $upgrades++
            $reasons += ('+ {0}: no current driver bound' -f $pair.Device.Name)
            continue
        }
        # Determine current-driver category. If [A]/[B]/[?], the
        # category-priority override makes this an UPGRADE regardless
        # of version comparison.
        $curCatInfo = Get-DriverSourceCategory -Provider $cur.Provider -Signer $cur.Signer -InfName $cur.InfName -ExpectedSelfSignThumbprint $Ctx.CertThumbprint
        $curCatCode = if ($curCatInfo) { $curCatInfo.Code } else { '?' }
        if ($curCatCode -ne 'C') {
            $upgrades++
            $reasons += ('+ {0}: category [{1}] -> [C] override' -f $pair.Device.Name, $curCatCode)
            continue
        }
        # AS-IS is [C] (earlier run's output); compare versions to avoid
        # pointless reinstall.
        $rd = if ($cur.DriverDate) { $cur.DriverDate } else { [datetime]::MinValue }
        $cmp = Compare-InfDriverVer -LeftRaw $InfEntry.DriverVer -RightRaw $cur.DriverVersion -RightDate $rd
        if ($cmp -gt 0) {
            $upgrades++
            $reasons += ('+ {0}: patched [C] newer than current [C] {1}' -f $pair.Device.Name, $cur.DriverVersion)
        } else {
            $sign = if ($cmp -eq 0) { '=' } else { '<' }
            $reasons += ('- {0}: patched [C] {1} current [C] {2}' -f $pair.Device.Name, $sign, $cur.DriverVersion)
        }
    }
    if ($upgrades -gt 0) {
        return @{
            Decision='INSTALL_UPGRADE'
            Reason=('would upgrade {0}/{1} matched device(s)' -f $upgrades, $InfMatchedDevices.Count)
            AffectedDeviceCount=$upgrades
            DetailReasons=$reasons
        }
    }
    return @{
        Decision='SKIP_NEWER'
        Reason=('all {0} matched device(s) already on [C] with same/newer self-signed driver; skipping reinstall' -f $InfMatchedDevices.Count)
        AffectedDeviceCount=0
        DetailReasons=$reasons
    }
}

function Invoke-VerifyPhase06_HardwareImpactAnalysis { # psa-disable-line PSA6003 -- compound noun (e.g., Policies, Drivers, Catalogs) is semantically plural for set-returning helpers
    param($Ctx)
    Write-PhaseHeader 'V06' 'HardwareImpactAnalysis' 'Verify'

    # ====================================================================
    Set-DebugStep 'Section 1: AMD hardware inventory (driver-source category)'
    # SECTION 1: AMD hardware inventory (with driver-source category)
    # ====================================================================
    # Each device row now shows BOTH:
    #   - Hardware-source category (PCI VEN, ACPI AMD, ROOT/SW software)
    #     produced by Resolve-AmdDeviceClassification
    #   - Driver-source category [A]/[B]/[C]/[?] produced by
    #     Get-DriverSourceCategory
    # The two are orthogonal: hardware-source tells us WHAT KIND of
    # AMD entity it is, driver-source tells us WHO SIGNED the driver
    # currently bound to it.
    Write-Host '--- 1. AMD Hardware Inventory (this machine) -----------------------'
    Write-Host '  Driver-source category legend (who signed the bound driver):' -ForegroundColor DarkGray
    Write-Host '    [A] Microsoft (OS in-box)   [B] Hardware vendor / IHV' -ForegroundColor DarkGray
    Write-Host '    [C] Self-signed (this script)   [?] Unknown / unsigned' -ForegroundColor DarkGray
    Write-Host '  Hardware-source classification (what kind of AMD entity):' -ForegroundColor DarkGray
    Write-Host '    PCI VEN_1002 = AMD GPU      PCI VEN_1022 = AMD CPU/Chipset' -ForegroundColor DarkGray
    Write-Host '    ACPI_AMD     = ACPI device  ACPI_CPU     = CPU core' -ForegroundColor DarkGray
    Write-Host '    ROOT_SW/SWD_SW = software-only AMD-named entity (not real hardware)' -ForegroundColor DarkGray
    Write-Host ''
    $hwAll = @(Get-AmdHardwareInventory)
    if ($hwAll.Count -eq 0) {
        Write-Warn2 'No AMD-affiliated PnP devices detected on this machine.'
        Write-Host '    The patched drivers will still install into the driver store,'
        Write-Host '    but no devices on this system would currently bind to them.'
        Write-Host ''
        Write-PhaseFooter 'V06' 'done'
        return
    }
    # Strict hardware vs software/uncertain. The Section 2
    # AS-IS/TO-BE comparison and Section 3 risk assessment use only
    # strict hardware - software-only entities aren't replaced.
    $hw       = @($hwAll | Where-Object IsAmdHardware)
    $hwSoftSw = @($hwAll | Where-Object { -not $_.IsAmdHardware })

    # Pre-compute per-device current-driver categorization. Doing
    # this once up-front lets us reuse the result in Sections 1, 2
    # and the AMD-on-MS-generic detection without re-querying
    # Win32_PnPSignedDriver.
    $deviceDriverInfo = @{}
    $catCounts = @{ A=0; B=0; C=0; '?'=0 }
    foreach ($d in $hwAll) {
        $cur = Get-DeviceCurrentDriver -DeviceID $d.DeviceID
        $cat = if ($cur) {
            Get-DriverSourceCategory -Provider $cur.Provider -Signer $cur.Signer -InfName $cur.InfName -ExpectedSelfSignThumbprint $Ctx.CertThumbprint
        } else {
            @{ Code='?'; ShortLabel='[?]'; Label='No driver bound'; Color='DarkGray' }
        }
        $deviceDriverInfo[$d.DeviceID] = @{
            Current        = $cur
            Category       = $cat
            IsMsGeneric    = (Test-DriverIsMicrosoftGeneric -Driver $cur)
        }
        if ($d.IsAmdHardware) { $catCounts[$cat.Code]++ }
    }

    Write-Host ('  Total AMD-affiliated entities: {0}' -f $hwAll.Count) -ForegroundColor White
    Write-Host ('    Strict AMD HARDWARE   : {0,3}  (PCI VEN_1002/1022, ACPI AMD, ACPI CPU)' -f $hw.Count)       -ForegroundColor Cyan
    Write-Host ('    Software-only / loose : {0,3}  (ROOT\, SWD\, manufacturer-only matches)' -f $hwSoftSw.Count) -ForegroundColor DarkGray
    Write-Host ''
    Write-Host ('  Driver-source distribution among AMD HARDWARE: [A]={0}  [B]={1}  [C]={2}  [?]={3}' -f `
        $catCounts['A'], $catCounts['B'], $catCounts['C'], $catCounts['?']) -ForegroundColor Cyan
    Write-Host ''

    # ---- Hardware listing, grouped by HwCategory ----
    # Group devices by their hardware-source category so it's
    # immediately clear which entries are GPUs, which are chipset
    # bridges, which are CPU-cores, etc.
    if ($hw.Count -gt 0) {
        Write-Host '  AMD hardware (strict vendor-ID match):' -ForegroundColor White
        # Collapse identical-name+driver entries into a single
        # "x N instances" line so 16 CPU cores or 9 standard host bridges
        # don't bloat the inventory. Grouping is per-HwCategory so the
        # outer +-- buckets remain distinct.
        $hwByCat = $hw | Group-Object -Property HwCategory
        foreach ($g in $hwByCat) {
            Write-Host ('    +-- {0} ({1} device(s))' -f $g.Name, $g.Count) -ForegroundColor Cyan
            $subGroups = Group-AmdDevicesByDisplayKey -Devices @($g.Group) -DeviceDriverInfo $deviceDriverInfo
            foreach ($sg in $subGroups) {
                $info = $sg.Info
                $cat  = $info.Category
                $cur  = $info.Current
                $genericMark = if ($info.IsMsGeneric) { ' *MS-GENERIC*' } else { '' }
                $countSuffix = if ($sg.Count -gt 1) { ('  x {0} instances' -f $sg.Count) } else { '' }
                $statusColor = if ($sg.First.ConfigCode -eq 0) { $cat.Color } else { 'Yellow' }
                # Device-name line has no [A]/[B]/[C] tag; the
                # driver-source tag now lives on the "Driver" line below.
                # Color of this line still encodes the category visually.
                Write-Host ('       - {0}{1}{2}' -f $sg.DisplayName, $countSuffix, $genericMark) -ForegroundColor $statusColor
                if ($sg.Count -eq 1) {
                    Write-Host ('           DeviceID : {0}' -f $sg.First.PNPDeviceID) -ForegroundColor DarkGray
                } else {
                    Write-Host ('           DeviceID : {0}' -f $sg.First.PNPDeviceID) -ForegroundColor DarkGray
                    Write-Host ('                       (and {0} other instance(s) with the same name + driver)' -f ($sg.Count - 1)) -ForegroundColor DarkGray
                }
                if ($cur) {
                    $curVer  = if ($cur.DriverVersion) { $cur.DriverVersion } else { '(unknown)' }
                    $curDate = if ($cur.DriverDate)    { $cur.DriverDate.ToString('yyyy-MM-dd') } else { '(unknown)' }
                    $curProv = if ($cur.Provider)      { $cur.Provider } else { '(unknown)' }
                    $curInf  = if ($cur.InfName)       { $cur.InfName  } else { '(unknown)' }
                    Write-Host ('           Driver   : {0} {1} v{2} ({3})  [{4}]  (INF: {5})' -f $cat.ShortLabel, $curProv, $curVer, $curDate, $cat.Label, $curInf) -ForegroundColor DarkGray
                } else {
                    Write-Host  '           Driver   : (no driver bound)' -ForegroundColor Yellow
                }
            }
        }
        Write-Host ''
    }

    # ---- Software-only / loose-match section (informational) ----
    if ($hwSoftSw.Count -gt 0) {
        Write-Host '  AMD-named software-only entities (informational; not replaced by I03):' -ForegroundColor DarkGray
        $swByCat = $hwSoftSw | Group-Object -Property HwCategory
        foreach ($g in $swByCat) {
            Write-Host ('    +-- {0} ({1} entry(ies))' -f $g.Name, $g.Count) -ForegroundColor DarkGray
            # Same grouping treatment for the software-only block
            $swSubGroups = Group-AmdDevicesByDisplayKey -Devices @($g.Group) -DeviceDriverInfo $deviceDriverInfo
            foreach ($sg in $swSubGroups) {
                $countSuffix = if ($sg.Count -gt 1) { (' x {0}' -f $sg.Count) } else { '' }
                Write-Host ('       - {0}{1,-50}  [{2}]' -f $sg.DisplayName, $countSuffix, $sg.First.PNPDeviceID) -ForegroundColor DarkGray
            }
        }
        Write-Host ''
    }

    # ---- AMD hardware on Microsoft generic driver (alert) ----
    # This is the case the user explicitly asked to detect: an AMD
    # GPU/chipset device that is currently bound to a Microsoft
    # generic driver instead of an AMD-specific driver. Common reasons:
    #   - The AMD vendor driver was never installed (GPU without
    #     Radeon Software, chipset without AMD Chipset Software).
    #   - The vendor driver failed to install or was uninstalled and
    #     PnP fell back to the in-box driver.
    #   - A Server SKU pruned the vendor driver (Server 2025
    #     historically does NOT include AMD GPU/chipset drivers in-box).
    # Surfacing this list lets the operator decide whether to:
    #   (a) Install the OEM/AMD-provided driver first (preferred), or
    #   (b) Run THIS script to apply the patched + self-signed driver.
    $hwOnGeneric = @($hw | Where-Object {
        $info = $deviceDriverInfo[$_.DeviceID]
        $info -and $info.IsMsGeneric
    })
    if ($hwOnGeneric.Count -gt 0) {
        Write-Host '  +---------------------------------------------------------------------------+' -ForegroundColor Yellow
        Write-Host '  | ALERT: AMD HARDWARE running on MICROSOFT GENERIC drivers                  |' -ForegroundColor Yellow
        Write-Host '  +---------------------------------------------------------------------------+' -ForegroundColor Yellow
        Write-Host ('  {0} AMD device(s) currently bound to a Microsoft in-box / generic driver' -f $hwOnGeneric.Count) -ForegroundColor Yellow
        Write-Host '  rather than an AMD-specific driver. The vendor-supplied driver may be more' -ForegroundColor DarkGray
        Write-Host '  feature-complete or performant. Consider installing the OEM/AMD package'   -ForegroundColor DarkGray
        Write-Host '  before relying on this script (THIS SCRIPT IS A LAST-RESORT GAP-FILL).'    -ForegroundColor DarkGray
        Write-Host ''
        # Collapse identical-name+driver entries (16 CPU cores, 9
        # standard host bridges, etc.) into a single "x N" line.
        $alertGroups = Group-AmdDevicesByDisplayKey -Devices $hwOnGeneric -DeviceDriverInfo $deviceDriverInfo
        foreach ($sg in $alertGroups) {
            $info = $sg.Info; $cur = $info.Current
            $curProv = if ($cur -and $cur.Provider) { $cur.Provider } else { '(unknown)' }
            $curInf  = if ($cur -and $cur.InfName)  { $cur.InfName  } else { '(unknown)' }
            $countSuffix = if ($sg.Count -gt 1) { (' x {0}' -f $sg.Count) } else { '' }
            Write-Host ('    - {0}{1} ({2})' -f $sg.DisplayName, $countSuffix, $sg.HwCategory) -ForegroundColor Yellow
            Write-Host ('        Generic driver: {0}  [INF: {1}]' -f $curProv, $curInf) -ForegroundColor DarkGray
        }
        Write-Host ''
    }

    # ====================================================================
    Set-DebugStep 'Section 2: AS-IS vs TO-BE driver comparison'
    # SECTION 2: AS-IS vs TO-BE driver comparison (version-aware, an earlier revision)
    # ====================================================================
    # Match each detected device against the patched-INF set,
    # then run Resolve-PerDeviceDriverDecision for each match. This
    # produces a per-device decision (INSTALL_UPGRADE / INSTALL_NEW /
    # SKIP_NEWER / SKIP_SAME), which we use to split the matched list
    # into "WILL be replaced" and "Already up to date".
    #
    # The TO-BE rows are always Category C (self-signed by this script
    # after I03 succeeds), so we don't need per-candidate categorization
    # - the script's certificate is the only signer for any patched INF.
    Write-Host '--- 2. AS-IS / TO-BE Driver Comparison (version-aware) -------------'
    # When running on a Workstation OS (WS2025 preview mode), the
    # AS-IS driver versions reflect the OEM-shipped baseline (vendor
    # signed, often newer than what AMD's driver package contains).
    # On the actual WS2025 host (after clean install), most of these
    # devices fall back to MS-generic drivers (display.inf, hdaudio.inf,
    # etc.) or become "Unknown device", so the "WILL be replaced"
    # count grows substantially.
    if ($Ctx.Os.ProductType -eq 1) {
        Write-Host ''
        Write-Host '  +-----------------------------------------------------------------+' -ForegroundColor Cyan
        Write-Host '  | NOTE: Workstation baseline - results below reflect this Win11   |' -ForegroundColor Cyan
        Write-Host '  | host. After WS2025 clean install on the same hardware, the     |' -ForegroundColor Cyan
        Write-Host '  | "WILL be replaced" count will INCREASE (OEM drivers disappear,  |' -ForegroundColor Cyan
        Write-Host '  | MS-generic drivers take their place, AMD upgrade scope grows).  |' -ForegroundColor Cyan
        Write-Host '  +-----------------------------------------------------------------+' -ForegroundColor Cyan
        Write-Host ''
    }
    Write-Host '  Matching detected AMD devices against the patched INF set...'
    $infIndex = Build-PatchedInfHwidIndex -Ctx $Ctx
    if ($infIndex.Keys.Count -eq 0) {
        Write-Warn2 '  No patched INFs to compare against (run P05/P06 first).'
        Write-Host ''
        Write-PhaseFooter 'V06' 'done'
        return
    }

    $matched   = @()  # devices for which we have at least one TO-BE INF
    $unmatched = @()  # devices with no patched INF in our set

    foreach ($d in $hw) {
        $key = ConvertTo-DeviceMatchKey -HwId $d.PNPDeviceID
        if (-not $key) { continue }
        $infs = if ($infIndex.ContainsKey($key)) { $infIndex[$key] } else { @() }
        if ($infs.Count -gt 0) {
            $info = $deviceDriverInfo[$d.DeviceID]
            $current = $info.Current
            $decision = Resolve-PerDeviceDriverDecision -Current $current -Candidates $infs
            $matched += [pscustomobject]@{
                Device      = $d
                MatchKey    = $key
                Current     = $current
                Category    = $info.Category
                Candidates  = $infs
                Decision    = $decision
            }
        } else {
            $unmatched += $d
        }
    }

    # Split matched into "will replace" (action) vs "will skip" (no-op).
    # The split drives the risk assessment below: only WILL_REPLACE
    # devices contribute risk, because SKIP_* devices remain on their
    # current (working) driver.
    $willReplace = @($matched | Where-Object {
        $_.Decision.Decision -eq 'INSTALL_UPGRADE' -or
        $_.Decision.Decision -eq 'INSTALL_NEW'
    })
    $willSkip = @($matched | Where-Object {
        $_.Decision.Decision -eq 'SKIP_NEWER' -or
        $_.Decision.Decision -eq 'SKIP_SAME'
    })

    Write-Host ('  Match summary:') -ForegroundColor Cyan
    Write-Host ('    {0,3} device(s) WILL be replaced (patched is newer)' -f $willReplace.Count) -ForegroundColor $(if ($willReplace.Count -gt 0) { 'Yellow' } else { 'DarkGray' })
    Write-Host ('    {0,3} device(s) keep current driver (already same/newer)' -f $willSkip.Count) -ForegroundColor DarkGray
    Write-Host ('    {0,3} device(s) have no patched INF (no change)' -f $unmatched.Count) -ForegroundColor DarkGray
    Write-Host ''

    if ($willReplace.Count -gt 0) {
        Write-Host '  +---------------------------------------------------------------------------+'
        Write-Host '  | Devices that WILL be replaced (AS-IS [A/B]  -->  TO-BE [C self-signed])    |'
        Write-Host '  +---------------------------------------------------------------------------+'
        # AS-IS and TO-BE rows now share the same column layout:
        #
        #   {tag}: {cat} {Provider,-32} v{Version,-16} ({Date}) [INF: {name}]
        #
        # AS-IS data comes from Win32_PnPSignedDriver, TO-BE data from
        # Get-InfMetadata of the patched INF. Both populate Provider,
        # Version, Date, InfName the same way so the columns line up.
        # The TO-BE row gets a sub-line "src:..." for the patched-set
        # source-directory (which has no AS-IS counterpart) and a
        # "*CHOSEN*" suffix on the row itself when applicable.
        $rowFmt = '    {0}  : {1} {2,-32} v{3,-16} ({4,10})  [INF: {5}]{6}'
        foreach ($m in $willReplace) {
            $d = $m.Device; $cur = $m.Current; $dec = $m.Decision
            # Device-name line carries no [A]/[B]/[C] tag - the
            # tag describes the DRIVER source, which is the AS-IS /
            # TO-BE concern, not a property of the hardware itself.
            Write-Host ('  Device   : {0}' -f $d.Name) -ForegroundColor White
            Write-Host ('    HWID(s): {0}' -f $m.MatchKey) -ForegroundColor DarkGray
            if ($cur) {
                $curVer  = if ($cur.DriverVersion) { $cur.DriverVersion } else { '?' }
                $curDate = if ($cur.DriverDate)    { $cur.DriverDate.ToString('yyyy-MM-dd') } else { '         ?' }
                $curProv = if ($cur.Provider)      { $cur.Provider } else { '(unknown)' }
                $curInf  = if ($cur.InfName)       { $cur.InfName } else { '(unknown)' }
                Write-Host ($rowFmt -f 'AS-IS', $m.Category.ShortLabel, $curProv, $curVer, $curDate, $curInf, '') -ForegroundColor $m.Category.Color
            } else {
                Write-Host  '    AS-IS  : (no driver currently bound to this device)' -ForegroundColor Yellow
            }
            # Show the chosen TO-BE candidate (newest) FIRST, then any
            # losing candidates as informational. Each candidate uses
            # the same column layout as AS-IS for visual alignment.
            $chosen = $dec.ChosenInf
            $chosenParsed = ConvertFrom-DriverVerString -Raw $chosen.DriverVer
            $chosenVer  = if ($chosenParsed -and $chosenParsed.Version) { $chosenParsed.Version.ToString() } else { '?' }
            $chosenDate = if ($chosenParsed -and $chosenParsed.Date)    { $chosenParsed.Date.ToString('yyyy-MM-dd') } else { '         ?' }
            $chosenProv = if ($chosen.Provider) { $chosen.Provider } else { '(unknown)' }
            Write-Host ($rowFmt -f 'TO-BE', '[C]', $chosenProv, $chosenVer, $chosenDate, $chosen.InfName, '  *CHOSEN*') -ForegroundColor Magenta
            Write-Host ('              src: {0}' -f $chosen.SrcSubDir) -ForegroundColor DarkGray
            foreach ($cand in $dec.CandidatesByNewest) {
                if ($cand.FullPath -eq $chosen.FullPath) { continue }
                $candParsed = ConvertFrom-DriverVerString -Raw $cand.DriverVer
                $candVer  = if ($candParsed -and $candParsed.Version) { $candParsed.Version.ToString() } else { '?' }
                $candDate = if ($candParsed -and $candParsed.Date)    { $candParsed.Date.ToString('yyyy-MM-dd') } else { '         ?' }
                $candProv = if ($cand.Provider) { $cand.Provider } else { '(unknown)' }
                Write-Host ($rowFmt -f '     ', '[C]', $candProv, $candVer, $candDate, $cand.InfName, '  (older candidate)') -ForegroundColor DarkGray
                Write-Host ('              src: {0}' -f $cand.SrcSubDir) -ForegroundColor DarkGray
            }
            $decTagColor = 'Yellow'
            $decTag = switch ($dec.Decision) {
                'INSTALL_UPGRADE' { 'UPGRADE: ' + $dec.Reason }
                'INSTALL_NEW'     { 'NEW INSTALL: ' + $dec.Reason }
            }
            Write-Host ('    DECIDE : {0}' -f $decTag) -ForegroundColor $decTagColor
            Write-Host ''
        }
    }

    if ($willSkip.Count -gt 0) {
        Write-Host '  +---------------------------------------------------------------------------+'
        Write-Host '  | Devices KEPT on current driver (already same or newer than patched)        |'
        Write-Host '  +---------------------------------------------------------------------------+'
        foreach ($m in $willSkip) {
            $d = $m.Device; $cur = $m.Current; $dec = $m.Decision
            # Device-name line has no category tag (see willReplace
            # comment above). The KEEP row carries the [A]/[B] tag for
            # the driver source.
            Write-Host ('  Device   : {0}' -f $d.Name) -ForegroundColor DarkGray
            if ($cur) {
                $curVer = if ($cur.DriverVersion) { $cur.DriverVersion } else { '(unknown)' }
                Write-Host ('    KEEP   : {0} {1} v{2}  ({3})' -f $m.Category.ShortLabel, $cur.Provider, $curVer, $dec.Reason) -ForegroundColor DarkGray
            }
        }
        Write-Host ''
    }

    if ($unmatched.Count -gt 0) {
        Write-Host '  Devices with NO matching patched INF (will not be replaced by I03):' -ForegroundColor DarkGray
        # Device-name only - category info already shown in
        # Section 1's full inventory; this list is just a roll-up.
        # Collapse identical-name+driver entries (16 CPU cores,
        # 9 standard host bridges, etc.) into a single "x N" line so
        # this list mirrors the tightened Section 1 inventory.
        $unmatchedGroups = Group-AmdDevicesByDisplayKey -Devices $unmatched -DeviceDriverInfo $deviceDriverInfo
        foreach ($sg in $unmatchedGroups) {
            $countSuffix = if ($sg.Count -gt 1) { (' x {0}' -f $sg.Count) } else { '' }
            $displayName = '{0}{1}' -f $sg.DisplayName, $countSuffix
            Write-Host ('    - {0,-52}  [{1}]' -f $displayName, $sg.First.PNPDeviceID) -ForegroundColor DarkGray
            if ($sg.Count -gt 1) {
                Write-Host ('         (and {0} other instance(s) with the same name + driver)' -f ($sg.Count - 1)) -ForegroundColor DarkGray
            }
        }
        Write-Host ''
    }

    # ====================================================================
    Set-DebugStep 'Section 3: risk assessment (replacement devices)'
    # SECTION 3: Risk assessment (only for devices that WILL be replaced)
    # ====================================================================
    # With version-aware decision logic, a device the operator
    # might intuitively expect to be at risk (e.g. AMD PSP) may actually
    # be in the "keep current driver" bucket if its current driver is
    # already same/newer. Only the WILL_REPLACE list can contribute
    # risk - everything else stays on the working driver. This is a
    # significantly more accurate picture than an earlier revision's "all matched
    # devices are at risk" model.
    Write-Host '--- 3. Risk Assessment (only for devices that WILL be replaced) -------'
    Write-Host '  For each device that will be replaced, classify the boot/stability risk'
    Write-Host '  of a failed install. Categories:'
    Write-Host '    HIGH   = boot or system-stability impact possible'
    Write-Host '    MEDIUM = subsystem features may break (system still boots)'
    Write-Host '    LOW    = peripheral / feature only'
    Write-Host ''

    if ($willReplace.Count -eq 0) {
        Write-Host '  (no replacements scheduled - no risk assessment needed)' -ForegroundColor Green
        Write-Host '  All AMD devices on this system already have a same/newer driver' -ForegroundColor Green
        Write-Host '  than the patched set. I03 will only add INFs to the driver store' -ForegroundColor Green
        Write-Host '  for future hardware - no current device will be displaced.'        -ForegroundColor Green
        Write-Host ''
        Write-PhaseFooter 'V06' 'done'
        return
    }

    $byRisk = @{ HIGH = @(); MEDIUM = @(); LOW = @() }
    foreach ($m in $willReplace) {
        # Risk applies to the CHOSEN INF only - the losing candidates
        # are informational and won't actually replace the driver.
        $cand = $m.Decision.ChosenInf
        $risk = Get-InfRiskCategory -InfName $cand.InfName -Class $cand.Class
        $byRisk[$risk.Level] += [pscustomobject]@{
            Device   = $m.Device
            Inf      = $cand
            Reason   = $risk.Reason
            FromCat  = $m.Category
        }
    }

    foreach ($lvl in 'HIGH','MEDIUM','LOW') {
        $items = $byRisk[$lvl]
        if (-not $items -or $items.Count -eq 0) { continue }
        $color = switch ($lvl) {
            'HIGH'   { 'Red' }
            'MEDIUM' { 'Yellow' }
            'LOW'    { 'DarkGray' }
        }
        Write-Host ('  [{0}] {1} item(s):' -f $lvl, $items.Count) -ForegroundColor $color
        foreach ($it in $items) {
            Write-Host ('    - {0}  ({1})' -f $it.Inf.InfName, $it.Inf.SrcSubDir) -ForegroundColor $color
            # Device-name line has no category tag (the Transition
            # row below carries [src cat] -> [C] so the category info
            # is still visible right next to the device name).
            Write-Host ('        Device     : {0}' -f $it.Device.Name) -ForegroundColor DarkGray
            Write-Host ('        Transition : {0} {1}  ->  [C] Self-signed' -f $it.FromCat.ShortLabel, $it.FromCat.Label) -ForegroundColor DarkGray
            Write-Host ('        Risk       : {0}' -f $it.Reason) -ForegroundColor DarkGray
        }
        Write-Host ''
    }

    if ($byRisk['HIGH'].Count -gt 0) {
        Write-Host '  *** HIGH-RISK NOTICE ***' -ForegroundColor Red
        Write-Host '  The HIGH-risk drivers above are critical to system boot or memory'  -ForegroundColor Red
        Write-Host '  integrity. If their installation fails AFTER I02 has authorized'    -ForegroundColor Red
        Write-Host '  self-signed drivers (WDAC or testsigning) and the previous driver'  -ForegroundColor Red
        Write-Host '  has been displaced, the system may fail to boot normally. Strongly' -ForegroundColor Red
        Write-Host '  consider one of:'                                                   -ForegroundColor Red
        Write-Host '    1. Take a full system image / VM snapshot before running I03'     -ForegroundColor Yellow
        Write-Host '    2. Have a Windows Recovery USB on hand (DISM /Add-Driver from WinRE)' -ForegroundColor Yellow
        Write-Host '    3. Verify a System Restore point exists (Get-ComputerRestorePoint)'   -ForegroundColor Yellow
        Write-Host '    4. If BitLocker is enabled, suspend it before running I02 (testsigning)' -ForegroundColor Yellow
        Write-Host ''
        Write-Host '  Recovery commands (if I03 leaves the system unstable):' -ForegroundColor Red
        Write-Host '    pnputil /enum-drivers                  # list all OEM driver packages'   -ForegroundColor DarkGray
        Write-Host '    pnputil /delete-driver oemNN.inf /uninstall   # remove a bad driver'    -ForegroundColor DarkGray
        Write-Host '    bcdedit /set testsigning off  &  reboot       # disable test mode'      -ForegroundColor DarkGray
        Write-Host ''
    }

    Set-DebugStep 'Section 4: UEFI Secure Boot baseline'
    # Port from chipset: Section 4 - UEFI Secure Boot Baseline.
    # Operator-facing detailed readout of the same snapshot that
    # appears in compact form at P00 / V05 and in textual form at the
    # bottom of inf_inventory_report.txt. Numbered '4.' to be
    # consistent with sections 1-3 above.
    Write-Host '--- 4. UEFI Secure Boot Baseline ------------------------' -ForegroundColor Cyan
    $sbSnapshot = Get-OrEnsureSecureBootBaseline -Ctx $Ctx
    if ($sbSnapshot) {
        Show-SecureBootBaselineSnapshot -Snapshot $sbSnapshot
    }

    Write-PhaseFooter 'V06' 'done'
}

#####################################################################
# SECTION 9b: INSTALLATION PHASES
#####################################################################

function Invoke-InstPhase00_PreInstallReview {
    # ====================================================================
    # I00 - PreInstallReview
    # ====================================================================
    # Last-chance display of what the install pipeline (I01..I04) is
    # about to do. Reuses the same hardware enumeration & risk
    # classification helpers as V06, but folds in cert info and an
    # explicit "this is what will change" cert/driver pair view.
    # Read-only - takes no destructive action. Skipping I00 (e.g. via
    # -OnlyPhases I01,I02,I03,I04) is supported but not recommended
    # because the HIGH-risk warnings live here.
    param($Ctx)
    Write-PhaseHeader 'I00' 'PreInstallReview' 'Inst'

    # ---- Prerequisite-workflow notice (full block) ----
    # Surface this BEFORE anything else in I00 so the operator
    # explicitly considers whether Steps 1-2 (vendor drivers / Windows
    # Update) have actually been done. Everything below assumes the
    # baseline-driven state.
    Show-DriverInstallationOrderNotice
    Show-ReferenceLinks -Compact
    Write-Host ''

    Set-DebugStep 'Section: pending-reboot check'
    # ---- Pending-reboot detection ----
    # If a previous run wrote the PENDING_REBOOT sentinel, surface it
    # here so the operator knows to either reboot or proceed (if the
    # reboot has already happened the heuristic detects that).
    $pending = Get-PendingRebootMarker -Ctx $Ctx
    if ($pending) {
        Write-Host '--- Pending reboot recorded by a previous run ---' -ForegroundColor Yellow
        Write-Host ('  Source       : {0}' -f $pending.Source)         -ForegroundColor Yellow
        Write-Host ('  Reason       : {0}' -f $pending.Reason)         -ForegroundColor Yellow
        Write-Host ('  Recorded at  : {0}' -f $pending.RecordedAt)     -ForegroundColor Yellow
        Write-Host ('  Recorded boot: {0}' -f $pending.RecordedBootTime) -ForegroundColor Yellow
        Write-Host ('  Current boot : {0}' -f $pending.CurrentBootTime) -ForegroundColor Yellow
        if ($pending.RebootHasOccurred) {
            Write-Host '  Reboot has occurred since the marker was written - safe to continue.' -ForegroundColor Green
        } else {
            Write-Host '  Reboot has NOT yet occurred - please reboot before proceeding to I03/I04.' -ForegroundColor Red
            Write-Host '  (The script will still run, but I03/I04 may report unexpected results.)' -ForegroundColor DarkYellow
        }
        Write-Host ''
    }

    Set-DebugStep 'Section: resume-after-reboot summary'
    # ---- Resume-after-reboot summary ----
    # Show which install phases are already in target state, so the
    # operator immediately sees what this run will actually do.
    Write-Host '--- Install phase resume status ---' -ForegroundColor Cyan
    $i02Desc = if ($Ctx.UseTestSigning) { 'BCD testsigning ON' } else { 'WDAC supplemental policy deployed' }
    $resume = @(
        @{ Id='I01'; Desc='Trust certificate (LocalMachine\Root + \TrustedPublisher)' },
        @{ Id='I02'; Desc=$i02Desc },
        @{ Id='I03'; Desc='All patched INFs in driver store' }
    )
    foreach ($r in $resume) {
        $done = Test-InstallPhaseAlreadyDone -Ctx $Ctx -PhaseId $r.Id
        if ($done) {
            Write-Host ('  [+] {0}: already in target state - will be skipped     ({1})' -f $r.Id, $r.Desc) -ForegroundColor Green
        } else {
            Write-Host ('  [ ] {0}: NOT yet in target state - will run             ({1})' -f $r.Id, $r.Desc) -ForegroundColor DarkYellow
        }
    }
    Write-Host '  [.] I04: post-install verification - always runs' -ForegroundColor DarkGray
    Write-Host ''

    if (-not (Test-Path $Ctx.Paths.Patched)) {
        Write-Warn2 'I00: patched/ directory missing; running on cached state. P05/P06 must have completed in a previous run.'
    }

    Set-DebugStep 'Section: hardware impact (V06 delegate)'
    # ---- Hardware impact (delegates to V06 helpers) ----
    # Filter to strict AMD hardware only (PCI VEN_1002/1022, ACPI
    # AMD/CPU). Software-only ROOT\/SWD\ entities are not driver-
    # replacement targets so they don't belong in the I00 review.
    Write-Host '--- Hardware on this system that I03 will affect ---' -ForegroundColor Cyan
    Write-Host '  Driver-source: [A]Microsoft  [B]Vendor  [C]Self-signed  [?]Unknown' -ForegroundColor DarkGray
    $hwAll = @(Get-AmdHardwareInventory)
    $hw    = @($hwAll | Where-Object IsAmdHardware)
    if ($hw.Count -eq 0) {
        Write-Warn2 'No AMD HARDWARE detected. I03 will still register the drivers in the driver store.'
    }
    $infIndex = Build-PatchedInfHwidIndex -Ctx $Ctx
    $matched   = @()
    $unmatched = @()
    foreach ($d in $hw) {
        $key = ConvertTo-DeviceMatchKey -HwId $d.PNPDeviceID
        if (-not $key) { continue }
        $infs = if ($infIndex.ContainsKey($key)) { $infIndex[$key] } else { @() }
        if ($infs.Count -gt 0) {
            $cur = Get-DeviceCurrentDriver -DeviceID $d.DeviceID
            $cat = if ($cur) {
                Get-DriverSourceCategory -Provider $cur.Provider -Signer $cur.Signer -InfName $cur.InfName -ExpectedSelfSignThumbprint $Ctx.CertThumbprint
            } else {
                @{ Code='?'; ShortLabel='[?]'; Label='No driver bound'; Color='DarkGray' }
            }
            $matched += [pscustomobject]@{
                Device     = $d
                MatchKey   = $key
                Current    = $cur
                Category   = $cat
                Candidates = $infs
            }
        } else {
            $unmatched += $d
        }
    }
    Write-Host ('  AMD HARDWARE (strict)          : {0}' -f $hw.Count)
    Write-Host ('  Will be replaced (AS-IS->TO-BE): {0}' -f $matched.Count)
    Write-Host ('  Will be left untouched         : {0}' -f $unmatched.Count)
    Write-Host ''

    # Persist matched list onto the Ctx so I04 can compare without
    # re-querying after I03 has run (devices may flicker mid-install).
    $Ctx | Add-Member -NotePropertyName PreInstallMatched -NotePropertyValue $matched -Force

    if ($matched.Count -gt 0) {
        Write-Host '  AS-IS  ->  TO-BE per device:' -ForegroundColor Cyan
        # Same column layout as V06 - shared row format string so
        # AS-IS and TO-BE columns line up visually.
        $rowFmt = '    {0}  : {1} {2,-32} v{3,-16} ({4,10})  [INF: {5}]'
        foreach ($m in $matched) {
            # Device-name line has no [A]/[B]/[C] tag - tag goes on AS-IS/TO-BE rows only
            # Align "Device" indent (3 spaces + label) with V06 for cross-section visual continuity
            Write-Host ('  Device   : {0}' -f $m.Device.Name) -ForegroundColor White
            if ($m.Current) {
                $cv = $m.Current
                $cd = if ($cv.DriverDate) { $cv.DriverDate.ToString('yyyy-MM-dd') } else { '         ?' }
                $cvProv = if ($cv.Provider) { $cv.Provider } else { '(unknown)' }
                $cvVer  = if ($cv.DriverVersion) { $cv.DriverVersion } else { '?' }
                $cvInf  = if ($cv.InfName) { $cv.InfName } else { '(unknown)' }
                Write-Host ($rowFmt -f 'AS-IS', $m.Category.ShortLabel, $cvProv, $cvVer, $cd, $cvInf) -ForegroundColor $m.Category.Color
            } else {
                Write-Host  '    AS-IS  : (no driver currently bound to this device)' -ForegroundColor Yellow
            }
            # ---- Deduplicate candidates for display ----
            # An INF can have N HWID variants (e.g., AMD's u0197843.inf
            # ships ~5046 PCI VEN/DEV variants). The candidate-collection
            # logic may return the same INF up to N times when many
            # variants matched. Showing 5046 identical TO-BE rows per
            # device is noise; collapse them and surface the variant
            # count instead.
            $uniqueCandidates = $m.Candidates | Group-Object -Property { '{0}|{1}' -f $_.InfName, $_.SrcSubDir } | ForEach-Object {
                $first = $_.Group[0]
                [pscustomobject]@{
                    InfName     = $first.InfName
                    SrcSubDir   = $first.SrcSubDir
                    DriverVer   = $first.DriverVer
                    Provider    = $first.Provider
                    Class       = $first.Class
                    FullPath    = $first.FullPath
                    HwidVariants = $_.Count
                }
            }
            foreach ($c in $uniqueCandidates) {
                $cParsed = ConvertFrom-DriverVerString -Raw $c.DriverVer
                $cVerStr = if ($cParsed -and $cParsed.Version) { $cParsed.Version.ToString() } else { '?' }
                $cDateStr = if ($cParsed -and $cParsed.Date)   { $cParsed.Date.ToString('yyyy-MM-dd') } else { '         ?' }
                $cProv = if ($c.Provider) { $c.Provider } else { '(unknown)' }
                $suffix = if ($c.HwidVariants -gt 1) { ('  [+{0} HWID variants]' -f ($c.HwidVariants - 1)) } else { '' }
                Write-Host (($rowFmt -f 'TO-BE', '[C]', $cProv, $cVerStr, $cDateStr, $c.InfName) + $suffix) -ForegroundColor Magenta
                Write-Host ('              src: {0}' -f $c.SrcSubDir) -ForegroundColor DarkGray
            }
        }
        Write-Host ''
    }

    Set-DebugStep 'Section: certificate info'
    # ---- Certificate info ----
    Write-Host '--- Certificate that I01 will trust ---' -ForegroundColor Cyan
    $pfx = if ($Ctx.CertPfxPath) { $Ctx.CertPfxPath } else { Join-Path $Ctx.Paths.Cert 'AMD-Graphics-Driver-CodeSign.pfx' }
    if (Test-Path $pfx) {
        try {
            $flags = [System.Security.Cryptography.X509Certificates.X509KeyStorageFlags]::DefaultKeySet
            $cert = [System.Security.Cryptography.X509Certificates.X509Certificate2]::new($pfx, $Ctx.PfxPassword, $flags)
            Write-Host ('  Subject     : {0}' -f $cert.Subject)
            Write-Host ('  Thumbprint  : {0}' -f $cert.Thumbprint)
            Write-Host ('  Valid until : {0}' -f $cert.NotAfter.ToString('yyyy-MM-dd'))
            Write-Host ('  Algorithm   : {0}' -f $cert.SignatureAlgorithm.FriendlyName)
            Write-Host  '  Will import : LocalMachine\Root, LocalMachine\TrustedPublisher'
        } catch {
            Write-Warn2 ('  Could not load PFX for preview: {0}' -f $_.Exception.Message)
        }
    } else {
        Write-Warn2 ('  PFX not found at {0} - I01 will fail.' -f $pfx)
    }
    Write-Host ''

    # ---- Risk summary (delegates to V06's risk classification) ----
    Set-DebugStep 'Section: boot-signing environment'
    # ---- Boot-signing environment ----
    Write-Host '--- Boot-signing environment (Secure Boot / testsigning / HVCI) ---' -ForegroundColor Cyan
    $bootEnv = Update-BootSigningEnvironmentForCtx -Ctx $Ctx
    Show-BootSigningEnvironment -BootEnv $bootEnv
    Write-Host ''
    if (-not $bootEnv.EffectiveCanLoadSelfSigned) {
        Show-BootSigningChangeRequired -BootEnv $bootEnv
        Write-Host ''
    }

    Set-DebugStep 'Section: risk summary (V06 delegate)'
    # ---- Risk summary (delegates to V06's risk classification) ----
    # Same HWID-variant deduplication as the TO-BE display above:
    # tally each (device, INF) pair ONCE so the risk counts reflect
    # actual replacement events, not HWID-variant noise.
    Write-Host '--- Risk summary (please review BEFORE proceeding) ---' -ForegroundColor Cyan
    $byRisk = @{ HIGH = @(); MEDIUM = @(); LOW = @() }
    $seenPairs = @{}
    foreach ($m in $matched) {
        foreach ($c in $m.Candidates) {
            $pairKey = '{0}|{1}|{2}' -f $m.Device.InstanceId, $c.InfName, $c.SrcSubDir
            if ($seenPairs.ContainsKey($pairKey)) { continue }
            $seenPairs[$pairKey] = $true
            $risk = Get-InfRiskCategory -InfName $c.InfName -Class $c.Class
            $byRisk[$risk.Level] += [pscustomobject]@{
                Device = $m.Device; Inf = $c; Reason = $risk.Reason
            }
        }
    }
    foreach ($lvl in 'HIGH','MEDIUM','LOW') {
        $items = $byRisk[$lvl]
        if (-not $items -or $items.Count -eq 0) { continue }
        $color = switch ($lvl) {
            'HIGH'   { 'Red' }
            'MEDIUM' { 'Yellow' }
            'LOW'    { 'DarkGray' }
        }
        Write-Host ('  [{0}] {1} item(s)' -f $lvl, $items.Count) -ForegroundColor $color
        if ($lvl -eq 'HIGH') {
            foreach ($it in $items) {
                Write-Host ('      - {0} affects {1}' -f $it.Inf.InfName, $it.Device.Name) -ForegroundColor Red
                Write-Host ('          {0}' -f $it.Reason) -ForegroundColor DarkGray
            }
        }
    }
    Write-Host ''

    if ($byRisk['HIGH'].Count -gt 0) {
        Write-Host '  *** HIGH-RISK INSTALL ***' -ForegroundColor Red
        Write-Host '  This install replaces drivers that are critical to system stability.' -ForegroundColor Red
        Write-Host '  Before continuing, ensure you have one of the following:'              -ForegroundColor Yellow
        Write-Host '    - System image / VM snapshot you can roll back to'                   -ForegroundColor Yellow
        Write-Host '    - Windows Recovery USB (DISM /Add-Driver from WinRE)'                -ForegroundColor Yellow
        Write-Host '    - System Restore point (Get-ComputerRestorePoint)'                   -ForegroundColor Yellow
        Write-Host '  If BitLocker is active, suspend it before I02 (testsigning).'          -ForegroundColor Yellow
        Write-Host ''
    }

    Write-Ok 'I00 review complete. The next phases (I01-I04) will modify the system.'

    # r69 (QI-6): CRITICAL severity acknowledgement (Q6-A).
    # C1/C2/C3/C5 may fire depending on host state + install plan;
    # if any item is returned, the operator must acknowledge each
    # via interactive y/N prompt before I01 begins. -ForceUnsafe
    # bypasses the prompt but logs the bypass via Set-DebugStep.
    # See SPEC SS D.28.
    Set-DebugStep 'QI-6: CRITICAL acknowledgement checklist'
    $criticalItems = Get-CriticalRiskItem -Ctx $Ctx -Matched $matched
    if ($criticalItems.Count -gt 0) {
        $acked = Invoke-CriticalAcknowledgementChecklist -Items $criticalItems -ForceUnsafe:$Script:ForceUnsafe
        if (-not $acked) {
            throw 'CRITICAL risk item(s) not acknowledged. Aborting before I01.'
        }
    }
    Write-PhaseFooter 'I00' 'done'
}

function Invoke-InstPhase01_TrustCertificate {
    param($Ctx)
    Write-PhaseHeader 'I01' 'TrustCertificate' 'Inst'

    # ---- Resume-after-reboot: skip if cert is already trusted ----
    # State validator inspects LocalMachine\Root and \TrustedPublisher
    # directly. If both already contain our thumbprint, I01 is a no-op
    # and we move on. -Force overrides this.
    Set-DebugStep 'resume check: cert already trusted?'
    if (Test-InstallPhaseAlreadyDone -Ctx $Ctx -PhaseId 'I01') {
        Write-Skip 'Certificate is already trusted in LocalMachine\Root and \TrustedPublisher.'
        Write-Host '  Target state already holds - I01 skipped.' -ForegroundColor Green
        Set-PhaseMarker -Ctx $Ctx -PhaseId 'I01'
        Write-PhaseFooter 'I01' 'cached'
        return
    }

    Set-DebugStep 'precondition: PFX file present'
    $pfx = if ($Ctx.CertPfxPath) { $Ctx.CertPfxPath } else { Join-Path $Ctx.Paths.Cert 'AMD-Graphics-Driver-CodeSign.pfx' }
    if (-not (Test-Path $pfx)) { throw "PFX not found at $pfx (run P07 first)." }

    Set-DebugStep 'load X509Certificate2 with MachineKeySet flags'
    # Use.NET API to load PFX with password non-interactively.
    # MachineKeySet ensures the private key is associated with the
    # machine context (matches the LocalMachine store target below).
    $flags = [System.Security.Cryptography.X509Certificates.X509KeyStorageFlags]::MachineKeySet `
        -bor [System.Security.Cryptography.X509Certificates.X509KeyStorageFlags]::PersistKeySet
    $cert = [System.Security.Cryptography.X509Certificates.X509Certificate2]::new($pfx, $Ctx.PfxPassword, $flags)
    Write-Step "Trusting certificate: $($cert.Thumbprint)"
    Write-Detail "Subject: $($cert.Subject)"

    Set-DebugStep 'import cert into LocalMachine\Root + TrustedPublisher (loop)'
    foreach ($storeName in 'Root','TrustedPublisher') {
        $store = New-Object System.Security.Cryptography.X509Certificates.X509Store($storeName, 'LocalMachine')
        $store.Open('ReadWrite')
        $existing = $store.Certificates | Where-Object Thumbprint -eq $cert.Thumbprint
        if ($existing) {
            Write-Skip "  Already in LocalMachine\$storeName"
        } else {
            $store.Add($cert)
            Write-Ok "  Imported into LocalMachine\$storeName"
        }
        $store.Close()
    }
    Set-PhaseMarker -Ctx $Ctx -PhaseId 'I01'
    Write-PhaseFooter 'I01' 'done'
}

function Invoke-InstPhase02_AuthorizeDriverSigning {
    # ====================================================================
    # I02 - Configure code-signing-policy authorization
    # ====================================================================
    # Authorize this script's self-signed code-signing certificate to
    # produce kernel-mode-loadable drivers. Two implementation paths:
    #
    #   PATH A (default, RECOMMENDED): WDAC supplemental policy
    #     - Build a Code Integrity supplemental policy XML that ONLY
    #       allowlists our cert as a kernel-mode signer.
    #     - Convert to.cip and deploy under
    #       %SystemRoot%\System32\CodeIntegrity\CiPolicies\Active.
    #     - Activate via CiTool.exe --update-policy (immediate, NO
    #       reboot needed on WS2022+ / Windows 11 22H2+).
    #     - Secure Boot stays ON. testsigning stays OFF. HVCI may
    #       remain ON. No firmware changes.
    #     - Reversible via -Action Cleanup (or CiTool --remove-policy).
    #
    #   PATH B (legacy, opt-in via -UseTestSigning): bcdedit testsigning
    #     - Sets the BCD testsigning flag and requires a reboot.
    #     - Only works when Secure Boot is OFF in firmware (Windows
    #       silently drops testsigning at boot otherwise).
    #     - The desktop will display a "Test Mode" watermark.
    #     - The script will REFUSE this path when Secure Boot is on,
    #       unless -Force is also passed.
    #
    # Renamed from Invoke-InstPhase02_EnableTestSigning to
    # accurately reflect that the default path is WDAC, not testsigning.
    # The phase ID 'I02' is unchanged and the old phase name
    # 'EnableTestSigning' remains accepted by Resolve-PhaseSelection
    # via an alias for backward-compatible -OnlyPhases callers.
    param($Ctx)
    Write-PhaseHeader 'I02' 'AuthorizeDriverSigning' 'Inst'

    # ---- Resume-after-reboot: skip if I02's target state already holds ----
    # State validator inspects either the WDAC active policies stack
    # (Path A) or the BCD testsigning value (Path B), depending on
    # which path the user is using. -Force overrides this.
    if (Test-InstallPhaseAlreadyDone -Ctx $Ctx -PhaseId 'I02') {
        Write-Skip 'Code-signing authorization for this script''s cert is already in place.'
        if (-not $Ctx.UseTestSigning) {
            $deployed = Test-AmdWdacPolicyDeployed -Ctx $Ctx
            if ($deployed) {
                Write-Host ('  WDAC supplemental policy is active (PolicyId={0}).' -f $deployed.PolicyId) -ForegroundColor Green
            }
        } else {
            Write-Host '  BCD testsigning is already ON.' -ForegroundColor Green
        }
        Write-Host '  Target state already holds - I02 skipped.' -ForegroundColor Green
        Set-PhaseMarker -Ctx $Ctx -PhaseId 'I02'
        Write-PhaseFooter 'I02' 'cached'
        return
    }

    # I02 short-circuit (added with the r72 release) for all-WHQL trimmed install plans.
    # When the operator passed -SkipNonCosignedDrivers and the post-P06
    # inventory is fully WHQL co-signed, no kernel-mode signer
    # authorization (WDAC supplemental policy or testsigning) is needed.
    # The WHQL embedded signatures authorize the drivers at kernel CI
    # directly; the trust-store import done in I01 is sufficient for
    # pnputil to accept the script-re-signed catalogs at I03. Skipping
    # the full Path A / Path B logic here is what makes the
    # -SkipNonCosignedDrivers + Secure Boot ON workflow actually
    # complete end-to-end (without this short-circuit, I02 falls
    # through to Path B which would abort on the Path B prerequisite
    # check). See SPEC SS D.31.11 for the design contract, including
    # the firing conditions and resume-after-reboot semantics.
    Set-DebugStep 'r72 short-circuit evaluation'
    if (-not $Ctx.UseTestSigning -and $Script:SkipNonCosignedDrivers -and $Ctx.WhqlCoSignAnalysis) {
        $nonCoSignedAfterTrim = @($Ctx.WhqlCoSignAnalysis | Where-Object { -not $_.IsFullyCoSigned })
        if ($nonCoSignedAfterTrim.Count -eq 0 -and $Ctx.WhqlCoSignAnalysis.Count -gt 0) {
            Write-Host '--- I02 short-circuit (r72): install plan is fully WHQL co-signed ---' -ForegroundColor Green
            Write-Ok ('  All {0} INF(s) in the trimmed install plan carry Microsoft Windows Hardware Compatibility co-signatures.' -f $Ctx.WhqlCoSignAnalysis.Count)
            Write-Detail '  No kernel-mode signer authorization is required:'
            Write-Detail '    - WHQL embedded signatures will authorize these drivers at kernel CI (Secure Boot can stay ON).'
            Write-Detail '    - Trust-store import (I01) is sufficient for pnputil to accept the re-signed catalogs at I03.'
            Write-Detail '  No WDAC supplemental policy will be deployed; no bcdedit testsigning flag will be set.'
            Set-PhaseMarker -Ctx $Ctx -PhaseId 'I02' -Metadata @{ ShortCircuit = $true; Reason = 'all-whql-skip'; AnalysedInfCount = $Ctx.WhqlCoSignAnalysis.Count }
            Set-DebugStep ('I02 short-circuit: SkipNonCosignedDrivers={0} UseTestSigning={1} AnalysedInfCount={2} NonCoSignedAfterTrim={3}' -f $Script:SkipNonCosignedDrivers, [bool]$Ctx.UseTestSigning, $Ctx.WhqlCoSignAnalysis.Count, $nonCoSignedAfterTrim.Count)
            Write-PhaseFooter 'I02' 'short-circuit'
            return
        }
    }

    Set-DebugStep 'capture AS-IS boot-signing environment'
    # ---- AS-IS state ----
    Write-Host '--- AS-IS: current boot-signing state ---' -ForegroundColor Cyan
    $bootEnvBefore = Update-BootSigningEnvironmentForCtx -Ctx $Ctx
    Show-BootSigningEnvironment -BootEnv $bootEnvBefore
    Write-Host ''

    Set-DebugStep 'UEFI Secure Boot baseline pre-check'
    # ---- UEFI Secure Boot baseline pre-check (port from chipset) ----
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
    #   - UEFI CA 2023 rollout in error state (UEFICA2023Error != 0,
    #     or Event 1795/1796/1802/1803 present): there is a concurrent
    #     firmware-level update in progress that may compete with
    #     post-I02 reboots. Operators should know this before they
    #     proceed.
    #
    #   - Secure-Boot-Update scheduled task disabled: the host has
    #     opted out of MS-managed rollout, which is fine for self-hosted
    #     deployments but worth recording.
    Write-Host '--- UEFI Secure Boot baseline pre-check ---' -ForegroundColor Cyan
    try {
        $sbSnapshot = Get-OrEnsureSecureBootBaseline -Ctx $Ctx
        if ($sbSnapshot) {
            Show-SecureBootBaselineSnapshot -Snapshot $sbSnapshot -Compact

            # WDAC path is planned but Secure Boot is OFF -> path is
            # overspecified (testsigning would suffice). Not a block.
            if (-not $Ctx.UseTestSigning -and $sbSnapshot.Embedded.SecureBootEnabled -eq $false) {
                Write-Warn2 'WDAC path is planned, but Secure Boot is OFF. Code Integrity policy will still apply; testsigning would also suffice. Continuing.'
            }
            # Surface UEFI rollout error state without blocking
            if ($sbSnapshot.Health -eq 'Critical') {
                Write-Warn2 ('UEFI Secure Boot baseline health is Critical. Reasons: ' + ($sbSnapshot.Reasons -join '; '))
                Write-Host '  This does NOT block I02 (different trust layer), but the operator should be aware.' -ForegroundColor Yellow
            } elseif ($sbSnapshot.Health -eq 'Warning') {
                Write-Host ('  Baseline health: Warning. ' + ($sbSnapshot.Reasons -join '; ')) -ForegroundColor Yellow
            }
        }
    } catch {
        Write-Warn2 ("UEFI Secure Boot baseline pre-check failed (non-fatal): {0}" -f $_.Exception.Message)
    }
    Write-Host ''

    Set-DebugStep 'decide Path A (WDAC) or Path B (testsigning)'
    # ---- Decide which path to take ----
    $useWdac = (-not $Ctx.UseTestSigning) -and $bootEnvBefore.WdacToolsAvailable

    if ($Ctx.UseTestSigning) {
        Write-Host 'Path: legacy testsigning (selected via -UseTestSigning).' -ForegroundColor DarkYellow
    } elseif ($useWdac) {
        Write-Host 'Path: WDAC supplemental policy (default, keeps Secure Boot ON).' -ForegroundColor Cyan
    } else {
        Write-Host 'Path: legacy testsigning (WDAC tools not available on this system).' -ForegroundColor DarkYellow
    }
    Write-Host ''

    Set-DebugStep 'Path A: deploy WDAC supplemental policy'
    # =====================================================================
    # PATH A: WDAC supplemental policy
    # =====================================================================
    if ($useWdac) {
        # Already deployed?
        $existing = Test-AmdWdacPolicyDeployed -Ctx $Ctx
        if ($existing -and -not $Ctx.Force) {
            Write-Skip ('WDAC supplemental policy is already deployed (PolicyId={0}).' -f $existing.PolicyId)
            Write-Host '  Self-signed AMD drivers are already authorized. No further action needed.' -ForegroundColor Green
            Write-PhaseFooter 'I02' 'cached'
            return
        }
        if ($existing -and $Ctx.Force) {
            Write-Step ('Removing existing AMD supplemental policy {0} (because -Force)...' -f $existing.PolicyId)
            $rm = Uninstall-AmdWdacPolicy -PolicyId $existing.PolicyId
            if ($rm.Removed) { Write-Ok 'Old policy removed.' } else { Write-Warn2 'Could not remove old policy; proceeding anyway.' }
        }

        # Need the.cer (P07 product). Allow -Force to skip the check.
        $cer = if ($Ctx.CertCerPath) { $Ctx.CertCerPath } else { Join-Path $Ctx.Paths.Cert 'AMD-Graphics-Driver-CodeSign.cer' }
        if (-not (Test-Path $cer)) {
            throw "I02: cert file not found at $cer - run P07 (CreateCertificate) first."
        }

        # Build supplemental policy XML
        $xmlPath = Join-Path $Ctx.Paths.Cert 'AmdSelfSignedSupplementalPolicy.xml'
        $cipPath = Join-Path $Ctx.Paths.Cert 'AmdSelfSignedSupplementalPolicy.cip'
        Write-Step "Building WDAC supplemental policy XML..."
        $policyId = New-AmdDriverWdacSupplementalPolicy -CerPath $cer -OutputXml $xmlPath
        Write-Ok ('Supplemental policy XML written: {0}' -f $xmlPath)
        Write-Host ('    PolicyId: {0}' -f $policyId)

        # Persist marker BEFORE deploying so we can clean up even if
        # deployment is interrupted.
        $markerPath = Get-AmdSuppPolicyMarkerPath -Ctx $Ctx
        Set-Content -LiteralPath $markerPath -Value $policyId -Encoding ASCII

        # Deploy
        Write-Step 'Converting XML to .cip binary and deploying to active CI policies...'
        $deploy = Install-AmdWdacPolicy -XmlPath $xmlPath -BinaryOutPath $cipPath
        Write-Ok ('Deployed: {0}' -f $deploy.DeployedPath)
        # Migrated from bare Write-Host '...' to Write-Detail
        # for SPEC A.5 compliance. CiToolStatusLine is parsed from the
        # --json envelope and is the canonical success message string.
        Write-Detail ('Activation method: {0}' -f $deploy.ActivationMethod) -Color Gray
        if ($deploy.CiToolStatusLine) {
            Write-Detail ('CiTool: {0}' -f $deploy.CiToolStatusLine) -Color DarkGray
        } elseif ($deploy.CiToolStdout) {
            $line = ($deploy.CiToolStdout -split "`r?`n" | Where-Object { $_.Trim() } | Select-Object -First 1)
            if ($line) { Write-Detail ('CiTool: {0}' -f $line.Trim()) -Color DarkGray }
        }
        Write-Host ''

        # ---- TO-BE state ----
        Write-Host '--- TO-BE: state immediately after I02 ---' -ForegroundColor Cyan
        $bootEnvAfter = Update-BootSigningEnvironmentForCtx -Ctx $Ctx
        Show-BootSigningEnvironment -BootEnv $bootEnvAfter
        Write-Host ''

        if ($deploy.RebootRequired) {
            Write-Warn2 'CiTool was not available; a REBOOT is required to activate the supplemental policy.'
        } else {
            Write-Ok 'Supplemental policy is active immediately. No reboot required.'
            Write-Host '  You can proceed to I03 (InstallDrivers) right away.' -ForegroundColor Green
        }
        Write-Host ''
        # Bare Write-Host '...' continuation lines migrated to
        # Write-Detail (SPEC A.5).
        Write-Detail 'Reversal (when you are done with this lab):' -Color DarkGray
        Write-Detail ('  .\Deploy-AMDGraphicsDriverOnWindowsServer.ps1 -Action Cleanup') -Color DarkGray
        Write-Detail ('  or: CiTool.exe --remove-policy {0}' -f $policyId) -Color DarkGray

        $reverseInstr = @(
            'To revert the WDAC supplemental policy:',
            ('  CiTool.exe --remove-policy {0}' -f $policyId),
            ('  Remove-Item -LiteralPath {0}' -f $deploy.DeployedPath)
        ) -join "`n"
        $Ctx | Add-Member -NotePropertyName I02ReverseInstructions -NotePropertyValue $reverseInstr -Force

        # WDAC path activates immediately via CiTool, so no reboot
        # required (unlike testsigning). Don't set the pending-reboot
        # marker for this path.
        Set-PhaseMarker -Ctx $Ctx -PhaseId 'I02'
        Write-PhaseFooter 'I02' 'done'
        return
    }

    Set-DebugStep 'Path B: enable BCD testsigning flag'
    # =====================================================================
    # PATH B: legacy bcdedit testsigning
    # =====================================================================
    # Already on?
    if ($bootEnvBefore.TestSigningEnabled -eq $true) {
        Write-Skip 'BCD testsigning is already ON.'
        if ($bootEnvBefore.SecureBootEnabled -eq $true) {
            Write-Warn2 'However, Secure Boot is also ON - testsigning is being dropped at boot.'
            Write-Warn2 'You MUST disable Secure Boot in firmware, or use the WDAC path (the default).'
        } elseif ($bootEnvBefore.HvciRunning) {
            Write-Warn2 'However, HVCI / Memory Integrity is RUNNING - it overrides testsigning.'
        } else {
            Write-Ok 'Legacy testsigning path is fully effective.'
        }
        Write-PhaseFooter 'I02' 'cached'
        return
    }

    # r71 Pre-check: Path B prerequisite check (Secure Boot firmware state)
    # Microsoft Learn documents that bcdedit /set TESTSIGNING ON is REFUSED
    # AT COMMAND EXECUTION when UEFI Secure Boot is ON in firmware (it does
    # NOT silently drop at boot as the older comment implied). Catch this
    # condition with a richer operator-facing guidance block BEFORE any
    # bcdedit call is attempted. See SPEC SS D.30.4 / F9 and SPEC SS D.31.
    Set-DebugStep 'Path B prerequisite check (r71)'
    $pathBCheck = Invoke-PathBPrerequisiteCheck -Ctx $Ctx
    if ($pathBCheck.Result -eq 'abort' -and -not $Ctx.Force) {
        foreach ($ln in $pathBCheck.GuidanceLines) {
            Write-Host $ln -ForegroundColor Red
        }
        throw ('I02: Path B prerequisite not met (reason={0}). Aborting before bcdedit is invoked.' -f $pathBCheck.Reason)
    }
    if ($pathBCheck.Reason -eq 'secure-boot-unknown') {
        foreach ($ln in $pathBCheck.GuidanceLines) {
            Write-Warn2 $ln
        }
    }

    # Pre-check: Secure Boot (legacy guard, retained as defense-in-depth in
    # case Invoke-PathBPrerequisiteCheck reported 'secure-boot-unknown' but
    # the OS-layer view says SB is on; both should agree, but if they
    # diverge we err on the safe side).
    if ($bootEnvBefore.SecureBootEnabled -eq $true -and -not $Ctx.Force) {
        Write-Host ''
        Write-Host '*** I02 ABORTED: -UseTestSigning was selected but Secure Boot is ON ***' -ForegroundColor Red
        Write-Host 'bcdedit /set testsigning on is silently dropped at next boot when Secure Boot is on.' -ForegroundColor Red
        Write-Host ''
        Show-BootSigningChangeRequired -BootEnv $bootEnvBefore
        Write-Host ''
        Write-Host 'Recommended: drop -UseTestSigning and let the script use the WDAC supplemental path.' -ForegroundColor Yellow
        throw 'I02: Secure Boot is enabled - testsigning would be ignored. Use the default WDAC path or disable Secure Boot first.'
    }

    # Pre-check: HVCI
    if ($bootEnvBefore.HvciRunning -and -not $Ctx.Force) {
        Write-Host ''
        Write-Host '*** I02 ABORTED: -UseTestSigning was selected but HVCI is RUNNING ***' -ForegroundColor Red
        Write-Host 'HVCI enforces a Code Integrity policy that rejects self-signed kernel-mode drivers.' -ForegroundColor Red
        Show-BootSigningChangeRequired -BootEnv $bootEnvBefore
        throw 'I02: HVCI is running - self-signed drivers will not load via testsigning. Use the WDAC path or disable HVCI.'
    }

    # Apply testsigning
    Write-Host '--- Applying change: bcdedit /set testsigning on ---' -ForegroundColor Cyan
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName               = 'bcdedit.exe'
    $psi.Arguments              = '/set testsigning on'
    $psi.UseShellExecute        = $false
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError  = $true
    $psi.CreateNoWindow         = $true
    $exit = $null
    $stdoutText = ''; $stderrText = ''
    try {
        $proc = [System.Diagnostics.Process]::Start($psi)
        $stdoutTask = $proc.StandardOutput.ReadToEndAsync()
        $stderrTask = $proc.StandardError.ReadToEndAsync()
        $proc.WaitForExit()
        $stdoutText = $stdoutTask.Result
        $stderrText = $stderrTask.Result
        $exit = $proc.ExitCode
        $proc.Dispose()
    } catch {
        $stderrText = "Failed to launch bcdedit: $($_.Exception.Message)"
    }
    if ($null -ne $stdoutText -and $stdoutText.Trim()) {
        Write-Host ('    bcdedit: {0}' -f $stdoutText.Trim()) -ForegroundColor DarkGray
    }
    if ($null -ne $exit -and $exit -ne 0) {
        Write-Host ('    bcdedit stderr: {0}' -f $stderrText.Trim()) -ForegroundColor Red
        throw "bcdedit failed (exit $exit)"
    }
    Write-Ok 'BCD testsigning was set to ON.'
    Write-Host ''

    Write-Host '--- TO-BE: state immediately after I02 (effective at next reboot) ---' -ForegroundColor Cyan
    $bootEnvAfter = Update-BootSigningEnvironmentForCtx -Ctx $Ctx
    Show-BootSigningEnvironment -BootEnv $bootEnvAfter
    Write-Host ''

    Write-Warn2 '*** A REBOOT IS REQUIRED FOR TESTSIGNING TO TAKE EFFECT ***'
    Write-Warn2 'After reboot the desktop will display a "Test Mode" watermark.'
    Write-Warn2 'Then run -Action Install AGAIN (same command). The script will'
    Write-Warn2 'detect that I01/I02 are already done and continue with I03/I04.'

    # Persist a "reboot pending" sentinel so a subsequent run can warn
    # the user if they re-execute without rebooting first. Cleared by
    # I04 once post-reboot state is verified good.
    Set-PendingRebootMarker -Ctx $Ctx -Source 'I02' `
        -Reason 'BCD testsigning was just set; reboot required for it to take effect.'

    $reverseInstr = @(
        'To revert testsigning later (after you are done):',
        '  bcdedit /set testsigning off',
        '  Restart-Computer'
    ) -join "`n"
    $Ctx | Add-Member -NotePropertyName I02ReverseInstructions -NotePropertyValue $reverseInstr -Force

    Set-PhaseMarker -Ctx $Ctx -PhaseId 'I02'
    Write-PhaseFooter 'I02' 'done'
}

function Invoke-InstPhase03_InstallDrivers { # psa-disable-line PSA6003 -- compound noun (e.g., Policies, Drivers, Catalogs) is semantically plural for set-returning helpers
    param($Ctx)
    Write-PhaseHeader 'I03' 'InstallDrivers' 'Inst'

    if (-not (Test-Path $Ctx.Paths.Patched)) {
        throw "I03: patched directory missing ($($Ctx.Paths.Patched)) - run P06 (PatchInfs) first."
    }
    $infs = Get-ChildItem -Path $Ctx.Paths.Patched -Recurse -Filter *.inf
    if ($infs.Count -eq 0) {
        throw 'I03: no patched INFs to install - run P06 (PatchInfs) first.'
    }

    Set-DebugStep 'resume check: drivers already in store?'
    # ---- Resume-after-reboot: skip if all drivers already in store ----
    # State validator runs pnputil /enum-drivers and verifies that
    # every patched INF is already present in the driver store. If
    # yes, I03 is a no-op (re-running pnputil /add-driver on an
    # already-added INF is harmless but slow and noisy). I04 will
    # still run and report the post-reboot disposition. -Force overrides.
    if (Test-InstallPhaseAlreadyDone -Ctx $Ctx -PhaseId 'I03') {
        Write-Skip ('All {0} patched INFs are already registered in the driver store.' -f $infs.Count)
        Write-Host '  Target state already holds - I03 skipped. Proceeding to I04 verification.' -ForegroundColor Green
        Set-PhaseMarker -Ctx $Ctx -PhaseId 'I03'
        Write-PhaseFooter 'I03' 'cached'
        return
    }

    Set-DebugStep 'snapshot driver state BEFORE pnputil'
    # ---- Snapshot driver state BEFORE pnputil runs ----
    # This is what I04 compares against to determine whether a driver
    # actually loaded vs is sitting in the store waiting for reboot.
    Write-Step 'Snapshotting driver state before install...'
    $beforeHw = @(Get-AmdHardwareInventory)
    $beforeState = @{}
    # Also pre-compute the per-device "current driver" record once so
    # we can reuse it for the install-decision logic below without
    # double-querying Win32_PnPSignedDriver.
    $beforeCurrent = @{}
    foreach ($d in $beforeHw) {
        $cur = Get-DeviceCurrentDriver -DeviceID $d.DeviceID
        $beforeCurrent[$d.DeviceID] = $cur
        $beforeState[$d.DeviceID] = [pscustomobject]@{
            DeviceName    = $d.Name
            PNPDeviceID   = $d.PNPDeviceID
            DriverVersion = if ($cur) { $cur.DriverVersion } else { $null }
            DriverDate    = if ($cur) { $cur.DriverDate    } else { $null }
            Provider      = if ($cur) { $cur.Provider      } else { $null }
            InfName       = if ($cur) { $cur.InfName       } else { $null }
            Service       = $d.Service
            Status        = $d.Status
            ConfigCode    = $d.ConfigCode
        }
    }
    Write-Ok ('Snapshot: {0} AMD device(s)' -f $beforeHw.Count)

    Set-DebugStep 'compute per-INF install decisions (version-aware)'
    # ---- Per-INF install-decision pass (version-aware) ----
    # For each patched INF, decide whether to call pnputil at all by
    # comparing the INF's DriverVer against the current driver of any
    # AMD device it would target. Skip downgrade scenarios (current
    # driver is same/newer than ours) so we don't churn the driver
    # store with no-op work and don't risk re-binding to an older
    # version when Windows PnP rank breaks ties unexpectedly.
    Write-Step 'Computing per-INF install decisions (version comparison)...'
    $infDecisions = @{}
    foreach ($inf in $infs) {
        $infData = $null
        try { $infData = Read-InfFile -Path $inf.FullName } catch {} # psa-disable-line PSA3004 -- intentional best-effort cleanup; no error to surface
        if (-not $infData) {
            # Could not parse - default to install (legacy behavior)
            $infDecisions[$inf.FullName] = @{
                Decision='INSTALL_NEW'
                Reason='unparseable INF; defaulting to install'
                AffectedDeviceCount=0
                DetailReasons=@()
                InfDriverVer=$null
            }
            continue
        }
        $meta = Get-InfMetadata -Content $infData.Content
        # Build a tiny entry that mimics the Build-PatchedInfHwidIndex
        # entry shape so Resolve-PerInfInstallDecision can reuse the
        # same code paths used by V06's display.
        $infEntry = [pscustomobject]@{
            InfName    = $inf.Name
            FullPath   = $inf.FullName
            DriverVer  = $meta.DriverVer
        }
        # Dedupe by physical DeviceID. See V05 builder for the
        # reason - without this, INFs with many HWID variants that
        # compat-match a single physical device produce many duplicate
        # entries.
        $matchedDevices = @()
        $seenDeviceIds = @{}
        foreach ($dev in $meta.Devices) {
            $infKey = ConvertTo-DeviceMatchKey -HwId $dev.HardwareId
            if (-not $infKey) { continue }
            foreach ($d in $beforeHw) {
                $devKey = ConvertTo-DeviceMatchKey -HwId $d.PNPDeviceID
                if ($devKey -eq $infKey -and -not $seenDeviceIds.ContainsKey($d.DeviceID)) {
                    $matchedDevices += @{
                        Device  = $d
                        Current = $beforeCurrent[$d.DeviceID]
                    }
                    $seenDeviceIds[$d.DeviceID] = $true
                }
            }
        }
        $decision = Resolve-PerInfInstallDecision -InfEntry $infEntry -InfMatchedDevices $matchedDevices
        $decision['InfDriverVer'] = $meta.DriverVer
        # Capture matched device names so the install loop can
        # log "Device: <name> / <inf>" for the operator's clarity.
        $decision['MatchedDeviceNames'] = @($matchedDevices | ForEach-Object { $_.Device.Name })
        $infDecisions[$inf.FullName] = $decision
    }
    $installCount = @($infDecisions.Values | Where-Object { $_.Decision -in 'INSTALL_UPGRADE','INSTALL_NEW' }).Count
    $skipCount    = @($infDecisions.Values | Where-Object { $_.Decision -eq 'SKIP_NEWER' }).Count
    Write-Ok ('Decisions: {0} INF(s) will install, {1} will skip (current driver is same/newer)' -f $installCount, $skipCount)
    Write-Host ''

    Set-DebugStep 'install INFs via pnputil /add-driver /install'
    Write-Step "Installing $($infs.Count) INF(s) via pnputil..."

    $okCount = 0; $failCount = 0; $rebootCount = 0; $skipNewerCount = 0; $noOpCount = 0
    $installResults = @()
    foreach ($inf in $infs) {
        $dec = $infDecisions[$inf.FullName]
        # Build a "device-name / INF" header so the pnputil log
        # line tells the operator WHICH AMD device this INF will
        # affect (or "(no device)" if it just goes to the driver
        # store). Matches the V05 dry-run output format introduced
        # in an earlier revision. If multiple devices match a single INF (rare),
        # show the first one with "+N more" suffix.
        $deviceLabel = if ($dec.MatchedDeviceNames -and $dec.MatchedDeviceNames.Count -gt 0) {
            if ($dec.MatchedDeviceNames.Count -eq 1) {
                $dec.MatchedDeviceNames[0]
            } else {
                '{0} (+{1} more)' -f $dec.MatchedDeviceNames[0], ($dec.MatchedDeviceNames.Count - 1)
            }
        } else {
            '(no device)'
        }

        # ---- Skip INFs whose current bound driver is same/newer ----
        # We deliberately do NOT call pnputil /add-driver in this case.
        # A skip here means the device stays on its (working) current
        # driver - this is the user's preferred policy ("install only
        # when our patched version is newer") currently.
        if ($dec.Decision -eq 'SKIP_NEWER') {
            $skipNewerCount++
            Write-Skip ("    {0} / {1} - SKIPPED ({2})" -f $deviceLabel, $inf.Name, $dec.Reason)
            $installResults += [pscustomobject]@{
                InfName        = $inf.Name
                ExitCode       = $null
                Status         = 'skipped-current-newer'
                RebootRequired = $false
                LogFile        = $null
                DriverPath     = $inf.FullName
                Reason         = $dec.Reason
                DetailReasons  = $dec.DetailReasons
            }
            continue
        }
        $logFile = Join-Path $Ctx.Paths.Logs ("pnputil_{0}.log" -f $inf.BaseName)
        Write-Detail ("{0} / {1}" -f $deviceLabel, $inf.Name)

        # Same rationale as P08/P09: use ProcessStartInfo with manually
        # quoted command line to handle paths containing spaces.
        $cmdLine = '/add-driver "{0}" /install' -f $inf.FullName

        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = 'pnputil.exe'
        $psi.Arguments = $cmdLine
        $psi.UseShellExecute = $false
        $psi.RedirectStandardOutput = $true
        $psi.RedirectStandardError = $true
        $psi.CreateNoWindow = $true

        $exit = $null
        $stdoutText = ''
        $stderrText = ''
        try {
            $proc = [System.Diagnostics.Process]::Start($psi)
            $stdoutTask = $proc.StandardOutput.ReadToEndAsync()
            $stderrTask = $proc.StandardError.ReadToEndAsync()
            $proc.WaitForExit()
            $stdoutText = $stdoutTask.Result
            $stderrText = $stderrTask.Result
            $exit = $proc.ExitCode
            $proc.Dispose()
        } catch {
            $stderrText = "Failed to launch pnputil: $($_.Exception.Message)"
        }

        # Persist log
        $logBody = New-Object System.Text.StringBuilder
        [void]$logBody.AppendLine("=== pnputil (exit=$exit) ===")
        [void]$logBody.AppendLine("Command: pnputil.exe $cmdLine")
        [void]$logBody.AppendLine('')
        if ($stdoutText) { [void]$logBody.AppendLine($stdoutText) }
        if ($stderrText) {
            [void]$logBody.AppendLine('--- stderr ---')
            [void]$logBody.AppendLine($stderrText)
        }
        Set-Content -LiteralPath $logFile -Value $logBody.ToString() -Encoding UTF8

        # Classify result. Windows convention:
        #   exit 0 = success, no reboot required
        #   exit 3010 = success, reboot required (ERROR_SUCCESS_REBOOT_REQUIRED)
        #   exit 259 = success, no-op (ERROR_NO_MORE_ITEMS; driver package
        #               was either already present in the driver store, or
        #               the device's current driver is already same-or-better
        #               so the new package was added to the store but not
        #               bound to the device). NOT a failure - investigation
        #               on WS2025 confirmed the pnputil stdout always
        #               reads "ドライバー パッケージが正常に追加されました"
        #               with "追加されたドライバー パッケージ: 0".
        #   anything else = failure (per pnputil)
        # Exit 259 was previously misclassified as failure; this
        # diverged from I04's PostInstallVerification which read the
        # actual device state and correctly classified those drivers as
        # REBOOT_NEEDED (when a sibling-INF first install had already
        # queued the binding). See SPEC D.17 for the root-cause.
        $rebootRequired = ($exit -eq 3010)
        $isNoOp         = ($exit -eq 259)
        $isSuccess      = ($exit -eq 0 -or $exit -eq 3010 -or $exit -eq 259)
        # pnputil text sometimes includes "Restart required: yes" in stdout
        # even on exit 0 (depends on Windows version), so honor either signal
        if (-not $rebootRequired -and $stdoutText -match '(?im)^\s*Restart required:\s*yes') {
            $rebootRequired = $true
        }

        $status = if ($isSuccess -and $rebootRequired) { 'reboot-required' }
                  elseif ($isNoOp)                      { 'no-op (already present)' }
                  elseif ($isSuccess)                   { 'installed' }
                  else                                  { 'failed' }

        $installResults += [pscustomobject]@{
            InfName        = $inf.Name
            FullPath       = $inf.FullName
            ExitCode       = $exit
            Status         = $status
            RebootRequired = $rebootRequired
            LogFile        = $logFile
        }

        if ($isSuccess) {
            $okCount++
            if ($rebootRequired) {
                $rebootCount++
                Write-Warn2 '  installed (REBOOT REQUIRED)'
            } elseif ($isNoOp) {
                $noOpCount++
                Write-Skip '  no-op (driver store already up-to-date)'
            } else {
                Write-Ok '  installed'
            }
        } else {
            $failCount++
            $exitDisplay = if ($null -eq $exit) { 'launch-failed' } else { $exit }
            Write-Warn2 "  exit=$exitDisplay (see $logFile)"
        }
    }
    Write-Ok ('Driver install: {0} ok ({1} need reboot, {2} no-op) / {3} failed / {4} skipped (current newer)' -f $okCount, $rebootCount, $noOpCount, $failCount, $skipNewerCount)

    # Persist state to context for I04 to consume
    $Ctx | Add-Member -NotePropertyName InstallResults     -NotePropertyValue $installResults -Force
    $Ctx | Add-Member -NotePropertyName BeforeDriverState  -NotePropertyValue $beforeState    -Force

    # If pnputil reported "reboot required" (exit 3010 or stdout text)
    # for any driver, set the pending-reboot sentinel. This lets a
    # subsequent run know the system is waiting for a reboot to
    # finalize driver activation.
    if ($rebootCount -gt 0) {
        Set-PendingRebootMarker -Ctx $Ctx -Source 'I03' `
            -Reason ("{0} driver(s) staged but require reboot to activate" -f $rebootCount)
        Write-Host ''
        Write-Warn2 ('{0} driver(s) need a reboot to activate.' -f $rebootCount)
        Write-Warn2 'After reboot, run -Action Install AGAIN (same command). The script will'
        Write-Warn2 'detect that I01/I02/I03 are done and run I04 to verify the new state.'
    }

    Set-PhaseMarker -Ctx $Ctx -PhaseId 'I03'
    Write-PhaseFooter 'I03' 'done'
}

function Invoke-InstPhase04_PostInstallVerification {
    # ====================================================================
    # I04 - PostInstallVerification
    # ====================================================================
    # After I03 ran pnputil for every patched INF, find out what
    # actually happened. For each AMD device we know about:
    #   - Re-query Win32_PnPSignedDriver for its current driver
    #   - Compare against the BEFORE snapshot (taken at the start of I03)
    #   - Classify: LOADED (driver replaced live) / REBOOT_NEEDED
    #     (still on old version, but pnputil added the new one to the
    #     store, so a reboot will pick it up) / UNCHANGED (no INF
    #     targeted this device) / FAILED (pnputil failed for the INF
    #     that targeted it).
    # For LOADED devices, also run a lightweight functional probe
    # (status, configCode, service running) and produce a per-device
    # health table.
    param($Ctx)
    Write-PhaseHeader 'I04' 'PostInstallVerification' 'Inst'

    if (-not $Ctx.InstallResults) {
        Write-Warn2 'I04: no I03 install results found in context. I03 must run first in the same session.'
        Write-PhaseFooter 'I04' 'done'
        return
    }
    if (-not $Ctx.BeforeDriverState) {
        Write-Warn2 'I04: no BEFORE driver snapshot found. I03 must run first in the same session.'
        Write-PhaseFooter 'I04' 'done'
        return
    }

    Set-DebugStep 'boot-signing effective-state check'
    # ---- Boot-signing effective-state check ----
    # If I02 set testsigning but Secure Boot was/is on, the kernel
    # silently dropped it at the next boot - the BCD entry stays "Yes"
    # in user-mode tools but the kernel ignores it. We can detect this
    # by reading the runtime CodeIntegrity policy, but the simplest
    # signal is: if testsigning is "on" in BCD AND the desktop is in
    # Test Mode, the kernel honored it. The desktop watermark is
    # observed indirectly via a registry key that Windows sets on
    # Test-Mode boots. Even simpler: check whether self-signed drivers
    # actually loaded for any device (we do this in the per-device
    # disposition below).
    Write-Step 'Re-evaluating boot-signing environment...'
    $bootEnvNow = Update-BootSigningEnvironmentForCtx -Ctx $Ctx
    Show-BootSigningEnvironment -BootEnv $bootEnvNow -Compact
    if (-not $bootEnvNow.EffectiveCanLoadSelfSigned) {
        Write-Warn2 'Self-signed driver loading is currently BLOCKED. The reasons are listed above.'
        Write-Warn2 'Devices below classified as REBOOT_NEEDED will NOT activate even after reboot'
        Write-Warn2 'until the blocking conditions (Secure Boot / HVCI) are resolved.'
    }
    Write-Host ''

    # Re-snapshot AFTER state
    Set-DebugStep 'snapshot driver state AFTER install'
    Write-Step 'Snapshotting driver state after install...'
    $afterHw = @(Get-AmdHardwareInventory)
    $afterState = @{}
    foreach ($d in $afterHw) {
        $cur = Get-DeviceCurrentDriver -DeviceID $d.DeviceID
        $afterState[$d.DeviceID] = [pscustomobject]@{
            DeviceName    = $d.Name
            PNPDeviceID   = $d.PNPDeviceID
            DriverVersion = if ($cur) { $cur.DriverVersion } else { $null }
            DriverDate    = if ($cur) { $cur.DriverDate    } else { $null }
            Provider      = if ($cur) { $cur.Provider      } else { $null }
            InfName       = if ($cur) { $cur.InfName       } else { $null }
            Service       = $d.Service
            Status        = $d.Status
            ConfigCode    = $d.ConfigCode
        }
    }
    Write-Ok ('Snapshot: {0} AMD device(s)' -f $afterHw.Count)

    Set-DebugStep 'build catalog signed-by-this-script index'
    # ---- Build OEM catalog signed-by-us index ----
    # Scan C:\Windows\INF\oem*.cat once, identify which entries carry
    # our cert thumbprint, and cross-reference pnputil /enum-drivers
    # to alias each match's Original Name as well. The resulting set
    # is passed to every Get-DriverSourceCategory call below so that
    # devices whose Win32_PnPSignedDriver.InfName field returns an
    # OS-reported short name OTHER than the OEM-numbered form still
    # classify as [C] Self-Signed instead of falling through to [B]
    # Vendor (Observation A symptom in the post-install log: Graphics
    # I04 LOADED row showed AFTER: [B] for self-signed-by-us drivers).
    $ourInfSet = Get-OurSignedOemInfSet -ExpectedThumbprint $Ctx.CertThumbprint
    Write-Detail ('  Known signed-by-us INF/CAT name(s): {0}' -f $ourInfSet.Count)

    # Map device-id to {before, after, matchedInf (TO-BE), pnputilResult}
    $infIndex = Build-PatchedInfHwidIndex -Ctx $Ctx
    $perDevice = @()
    foreach ($devId in $afterState.Keys) {
        $a = $afterState[$devId]
        $b = if ($Ctx.BeforeDriverState.ContainsKey($devId)) { $Ctx.BeforeDriverState[$devId] } else { $null }
        $matchKey = ConvertTo-DeviceMatchKey -HwId $a.PNPDeviceID
        $candidates = if ($matchKey -and $infIndex.ContainsKey($matchKey)) { $infIndex[$matchKey] } else { @() }

        # Find the pnputil result for the candidate INF that was supposed
        # to handle this device. For multi-candidate cases (rare), use
        # the first candidate's result.
        $pnpResult = $null
        if ($candidates.Count -gt 0) {
            $pnpResult = $Ctx.InstallResults | Where-Object { $_.InfName -eq $candidates[0].InfName } | Select-Object -First 1
        }

        # ---- Per-device categorization (BEFORE / AFTER) ----
        # Get-DriverSourceCategory needs Provider + Signer. The before
        # state captures Provider only (not Signer); the AFTER state
        # we re-query from Win32_PnPSignedDriver to get full Signer.
        $afterCur = Get-DeviceCurrentDriver -DeviceID $devId
        $afterCat  = if ($afterCur)  { Get-DriverSourceCategory -Provider $afterCur.Provider -Signer $afterCur.Signer -InfName $afterCur.InfName -ExpectedSelfSignThumbprint $Ctx.CertThumbprint -KnownOurInfSet $ourInfSet  } else { @{ Code='?'; ShortLabel='[?]'; Label='No driver'; Color='DarkGray' } }
        $beforeCat = if ($b -and $b.Provider) { Get-DriverSourceCategory -Provider $b.Provider -Signer $null -InfName $b.InfName -ExpectedSelfSignThumbprint $Ctx.CertThumbprint -KnownOurInfSet $ourInfSet } else { @{ Code='?'; ShortLabel='[?]'; Label='Unknown'; Color='DarkGray' } }

        # Classify disposition
        # Adds a new disposition KEPT_CURRENT for the case where
        # I03 deliberately skipped install because the current driver
        # was already same/newer than our patched version. This is
        # NOT a failure - it's the user-requested behavior to never
        # downgrade a working driver.
        $disposition = $null
        if ($candidates.Count -eq 0) {
            $disposition = 'UNCHANGED'   # no INF in our patched set targeted this device
        } elseif ($pnpResult -and $pnpResult.Status -eq 'skipped-current-newer') {
            $disposition = 'KEPT_CURRENT'
        } elseif ($pnpResult -and $pnpResult.Status -eq 'failed') {
            $disposition = 'FAILED'
        } elseif ($b -and $a -and $b.DriverVersion -ne $a.DriverVersion) {
            $disposition = 'LOADED'
        } elseif ($a -and $a.InfName -and $ourInfSet -and $ourInfSet.ContainsKey($a.InfName.ToLowerInvariant())) {
            # ---- LOADED via OS-reported binding (Observation C fix) ----
            # The Windows OS reports the device is currently bound to
            # one of OUR signed INFs (per oem*.cat thumbprint scan
            # above). Treat as LOADED even when BEFORE/AFTER DriverVersion
            # didn't change - the device has already accepted our binding
            # and re-reporting it as REBOOT_NEEDED would be misleading.
            # This narrows the conservative-fallback REBOOT_NEEDED bucket
            # to genuinely stuck devices (driver in store but binding
            # deferred). Was the I03 vs I04 reboot-count discrepancy
            # symptom: "I03 reports 0 reboot needed but I04 reports 4".
            $disposition = 'LOADED'
        } elseif ($pnpResult -and $pnpResult.RebootRequired) {
            $disposition = 'REBOOT_NEEDED'
        } else {
            # pnputil reported success but driver version didn't change.
            # Could mean: same version was already loaded, OR Windows
            # silently deferred binding. Treat as REBOOT_NEEDED to be
            # conservative.
            $disposition = 'REBOOT_NEEDED'
        }

        # r34 (SPEC §D.26): LOADED honesty gate. See the Chipset r68
        # version of this block for the full rationale. Briefly:
        # Win32_PnPSignedDriver reports a new INF binding regardless
        # of whether the kernel actually loaded the driver; on a
        # Secure-Boot-enforced host where SPF policy didn't authorize
        # the cert at boot, the device ends up bound on paper but
        # with ConfigManagerErrorCode != 0 and the service stopped.
        # The graphics-specific surface symptom was Audio CoProcessor
        # + HD Audio Controller showing up in [LOADED] yet also in
        # the [FAIL] functional probe (2026-05-23, WS2019 + Renoir).
        if ($disposition -eq 'LOADED' -and $a -and $a.PNPDeviceID) {
            try {
                $pnp = Get-PnpDevice -InstanceId $a.PNPDeviceID -ErrorAction Stop
                if ($pnp -and $pnp.ConfigManagerErrorCode -and ([int]$pnp.ConfigManagerErrorCode) -ne 0) {
                    $disposition = 'LOAD_FAILED'
                }
            } catch {
                # If we can't query PnP, leave the LOADED classification
                # as-is and let the functional probe surface details.
            }
        }

        $perDevice += [pscustomobject]@{
            DeviceName     = $a.DeviceName
            PNPDeviceID    = $a.PNPDeviceID
            Before         = $b
            After          = $a
            BeforeCategory = $beforeCat
            AfterCategory  = $afterCat
            Candidate      = if ($candidates.Count -gt 0) { $candidates[0] } else { $null }
            PnpResult      = $pnpResult
            Disposition    = $disposition
        }
    }

    Set-DebugStep 'Section 1: per-device disposition'
    # ---- Section 1: Per-device disposition ----
    Write-Host ''
    Write-Host '--- 1. Driver disposition by device ---' -ForegroundColor Cyan
    Write-Host '  Driver-source categories: [A]Microsoft  [B]Vendor  [C]Self-signed  [?]Unknown' -ForegroundColor DarkGray
    $loaded     = @($perDevice | Where-Object Disposition -eq 'LOADED')
    $reboot     = @($perDevice | Where-Object Disposition -eq 'REBOOT_NEEDED')
    $failed     = @($perDevice | Where-Object Disposition -eq 'FAILED')
    $loadFailed = @($perDevice | Where-Object Disposition -eq 'LOAD_FAILED')
    $unchanged  = @($perDevice | Where-Object Disposition -eq 'UNCHANGED')
    $keptCur    = @($perDevice | Where-Object Disposition -eq 'KEPT_CURRENT')

    Write-Host ('  LOADED        : {0,3} device(s)  - new driver active without reboot' -f $loaded.Count) -ForegroundColor Green
    Write-Host ('  REBOOT_NEEDED : {0,3} device(s)  - new driver in store, reboot to activate' -f $reboot.Count) -ForegroundColor Yellow
    Write-Host ('  LOAD_FAILED   : {0,3} device(s)  - INF bound but kernel rejected the driver (CM_PROB error)' -f $loadFailed.Count) -ForegroundColor Red
    Write-Host ('  KEPT_CURRENT  : {0,3} device(s)  - current driver newer; intentionally not replaced' -f $keptCur.Count) -ForegroundColor Cyan
    Write-Host ('  UNCHANGED     : {0,3} device(s)  - no replacement INF in the patched set' -f $unchanged.Count) -ForegroundColor DarkGray
    Write-Host ('  FAILED        : {0,3} device(s)  - pnputil failed for this INF' -f $failed.Count) -ForegroundColor Red
    Write-Host ''

    if ($loadFailed.Count -gt 0) {
        Write-Host '  [LOAD_FAILED] - kernel rejected the new driver (see functional probe in Section 2):' -ForegroundColor Red
        foreach ($p in $loadFailed) {
            $cv = if ($p.After)  { $p.After.DriverVersion  } else { '(unknown)' }
            $infName = if ($p.Candidate) { $p.Candidate.InfName } else { '(none)' }
            $cmErr = ''
            try {
                $pnp = Get-PnpDevice -InstanceId $p.PNPDeviceID -ErrorAction Stop
                if ($pnp) {
                    $cmErr = ('ConfigManagerErrorCode={0} ({1})' -f $pnp.ConfigManagerErrorCode, $pnp.Status)
                }
            } catch { } # psa-disable-line PSA3004 -- best-effort PnP enrichment; if Get-PnpDevice fails the diagnostic line is printed without the CM error code
            Write-Host ('    - {0}' -f $p.DeviceName) -ForegroundColor Red
            Write-Host ('        Bound INF: {0}, AFTER: v{1}  {2}' -f $infName, $cv, $cmErr) -ForegroundColor DarkRed
            Write-Host '        Likely cause: Secure Boot is enforcing kernel CI but the WDAC supplemental policy' -ForegroundColor DarkRed
            Write-Host '                      did not authorize this self-signed cert at boot time, OR HVCI is on.' -ForegroundColor DarkRed
            Write-Host '        Recovery   : reboot, verify the WDAC supplemental policy is active via -OnlyPhases V06,' -ForegroundColor DarkRed
            Write-Host '                     and re-check.  If still failing, run "pnputil /delete-driver"' -ForegroundColor DarkRed
            Write-Host '                     on the failed INF, then re-run -Action Install.' -ForegroundColor DarkRed
        }
        Write-Host ''
    }

    if ($keptCur.Count -gt 0) {
        Write-Host '  [KEPT_CURRENT] - version-aware skip; current driver is newer:' -ForegroundColor Cyan
        foreach ($p in $keptCur) {
            $catLabel = if ($p.AfterCategory) { $p.AfterCategory.ShortLabel } else { '[?]' }
            $cv = if ($p.After)  { $p.After.DriverVersion  } else { '(unknown)' }
            $candVer = if ($p.Candidate) { $p.Candidate.DriverVer } else { '(none)' }
            # Device-name line has no [A]/[B]/[C] tag; category
            # tag goes on the Current/Patched detail line.
            Write-Host ('    - {0}' -f $p.DeviceName) -ForegroundColor Cyan
            Write-Host ('        Current (kept): {0} v{1}   /   Patched (skipped): {2}' -f $catLabel, $cv, $candVer) -ForegroundColor DarkGray
        }
        Write-Host ''
    }

    if ($loaded.Count -gt 0) {
        Write-Host '  [LOADED] - new driver is active right now:' -ForegroundColor Green
        foreach ($p in $loaded) {
            $bv = if ($p.Before) { $p.Before.DriverVersion } else { '(unknown)' }
            $av = if ($p.After)  { $p.After.DriverVersion  } else { '(unknown)' }
            $bCat = if ($p.BeforeCategory) { $p.BeforeCategory.ShortLabel } else { '[?]' }
            $aCat = if ($p.AfterCategory)  { $p.AfterCategory.ShortLabel  } else { '[?]' }
            # Device-name line has no category tag; AS-IS/AFTER row keeps tags.
            Write-Host ('    - {0}' -f $p.DeviceName) -ForegroundColor Green
            Write-Host ('        AS-IS: {0} v{1}    AFTER: {2} v{3}    INF: {4}' -f $bCat, $bv, $aCat, $av, $p.Candidate.InfName) -ForegroundColor DarkGray
        }
        Write-Host ''
    }

    if ($reboot.Count -gt 0) {
        Write-Host '  [REBOOT_NEEDED] - reboot Windows to activate the new driver:' -ForegroundColor Yellow
        foreach ($p in $reboot) {
            # ---- Observation B fix: more informative display ----
            # $p.Before may exist but DriverVersion can still be empty
            # for devices whose previous binding was a Microsoft inbox
            # class driver that leaves the version field blank. Treat
            # empty string == unknown so we render "(unknown)" rather
            # than nothing.
            $bv = if ($p.Before -and $p.Before.DriverVersion) { $p.Before.DriverVersion } else { '(unknown)' }
            # When $p.Candidate is null (no HWID in our patched set
            # matched this device's PNPDeviceID via Build-PatchedInfHwidIndex),
            # fall back to the OS-reported InfName so the operator can
            # see which driver Windows is currently binding. This avoids
            # the unhelpful "new INF queued: (none)" line that gave no
            # actionable information.
            $infName = if ($p.Candidate) {
                $p.Candidate.InfName
            } elseif ($p.After -and $p.After.InfName) {
                ('(OS-bound: {0})' -f $p.After.InfName)
            } else {
                '(none)'
            }
            Write-Host ('    - {0}' -f $p.DeviceName) -ForegroundColor Yellow
            Write-Host ('        Still on v{0}, new INF queued: {1}' -f $bv, $infName) -ForegroundColor DarkGray
        }
        Write-Host ''
    }

    if ($failed.Count -gt 0) {
        Write-Host '  [FAILED] - pnputil reported failure for these INFs:' -ForegroundColor Red
        foreach ($p in $failed) {
            $exit = if ($p.PnpResult) { $p.PnpResult.ExitCode } else { '?' }
            $log  = if ($p.PnpResult) { $p.PnpResult.LogFile  } else { '?' }
            Write-Host ('    - {0}' -f $p.DeviceName) -ForegroundColor Red
            Write-Host ('        INF: {0}  exit={1}  log: {2}' -f $p.Candidate.InfName, $exit, $log) -ForegroundColor DarkGray
        }
        Write-Host ''
    }

    Set-DebugStep 'Section 2: functional health probe (LOADED only)'
    # ---- Section 2: Functional health probe (LOADED only) ----
    Write-Host '--- 2. Functional health probe (LOADED devices, no reboot needed) ---' -ForegroundColor Cyan
    if ($loaded.Count -eq 0) {
        Write-Host '  (no devices loaded a new driver in this session - nothing to probe)'
    } else {
        $passCount = 0; $warnCount = 0; $failCountFn = 0
        foreach ($p in $loaded) {
            $checks = @()

            # Check 1: device status reports OK
            $statusOk = ($p.After.Status -eq 'OK' -or $p.After.Status -eq 'Started')
            $checks += [pscustomobject]@{ Name='PnP status OK';    Pass = $statusOk; Detail = $p.After.Status }

            # Check 2: ConfigManagerErrorCode is 0
            $cfgOk = ($p.After.ConfigCode -eq 0)
            $checks += [pscustomobject]@{ Name='ConfigCode = 0';    Pass = $cfgOk; Detail = "$($p.After.ConfigCode)" }

            # Check 3: backing service is present and running (when applicable)
            $svcOk = $true
            $svcDetail = '(no service field)'
            if ($p.After.Service) {
                try {
                    $svc = Get-Service -Name $p.After.Service -ErrorAction Stop
                    $svcDetail = "$($p.After.Service) -> $($svc.Status)"
                    $svcOk = ($svc.Status -eq 'Running')
                } catch {
                    # Some kernel drivers don't surface as services; not
                    # always a failure. Treat as warning, not error.
                    $svcDetail = "$($p.After.Service) -> not-found-as-service"
                    $svcOk = $true
                }
            }
            $checks += [pscustomobject]@{ Name='Service running'; Pass = $svcOk; Detail = $svcDetail }

            # Check 4: driver version actually matches the TO-BE INF's
            # DriverVer (sanity check that we got the right driver, not
            # a different one that happened to bind).
            $verOk = $true
            $verDetail = 'n/a'
            if ($p.Candidate -and $p.Candidate.DriverVer -and $p.After.DriverVersion) {
                $expected = ($p.Candidate.DriverVer -split ',')[1]
                if ($expected) { $expected = $expected.Trim() }
                if ($expected -and $p.After.DriverVersion -ne $expected) {
                    # Allow a partial / prefix match (sometimes pnputil
                    # picks an older variant in the same INF group).
                    $verOk = ($p.After.DriverVersion -like "$expected*" -or $expected -like "$($p.After.DriverVersion)*")
                }
                $verDetail = "expected v$expected, got v$($p.After.DriverVersion)"
            }
            $checks += [pscustomobject]@{ Name='Version matches'; Pass = $verOk; Detail = $verDetail }

            $allPass = ($checks | Where-Object { -not $_.Pass }).Count -eq 0
            $someFail = ($checks | Where-Object { -not $_.Pass }).Count -gt 0
            $verdict = if ($allPass) { 'PASS' } elseif ($someFail -and ($checks | Where-Object Name -eq 'PnP status OK').Pass) { 'WARN' } else { 'FAIL' }
            switch ($verdict) {
                'PASS' { $passCount++;     $vColor = 'Green' }
                'WARN' { $warnCount++;     $vColor = 'Yellow' }
                'FAIL' { $failCountFn++;   $vColor = 'Red' }
            }

            Write-Host ('  [{0}] {1}' -f $verdict, $p.DeviceName) -ForegroundColor $vColor
            foreach ($c in $checks) {
                $mark = if ($c.Pass) { '+' } else { 'x' }
                $cColor = if ($c.Pass) { 'DarkGray' } else { 'Yellow' }
                Write-Host ('      [{0}] {1,-20} : {2}' -f $mark, $c.Name, $c.Detail) -ForegroundColor $cColor
            }
        }
        Write-Host ''
        Write-Host ('  Functional probe summary: {0} pass / {1} warn / {2} fail' -f $passCount, $warnCount, $failCountFn) -ForegroundColor Cyan
    }
    Write-Host ''

    Set-DebugStep 'Section 3: final summary & next steps'
    # ---- Section 3: Final summary & next steps ----
    Write-Host '--- 3. Summary & next steps ---' -ForegroundColor Cyan
    $totalDevices = $perDevice.Count
    $needReboot   = $reboot.Count -gt 0
    Write-Host ('  Total AMD devices examined : {0}' -f $totalDevices)
    Write-Host ('  Loaded immediately         : {0}' -f $loaded.Count)
    Write-Host ('  Awaiting reboot            : {0}' -f $reboot.Count)
    Write-Host ('  Failed                     : {0}' -f $failed.Count)
    Write-Host ('  Untouched                  : {0}' -f $unchanged.Count)
    Write-Host ''

    if ($failed.Count -gt 0) {
        Write-Host '  [!] Failed installs detected. Inspect the per-INF logs under:' -ForegroundColor Red
        Write-Host ('      {0}' -f $Ctx.Paths.Logs) -ForegroundColor Red
        Write-Host ''
    }

    if ($needReboot) {
        Write-Host ('  [!] REBOOT REQUIRED to finalize {0} driver(s).' -f $reboot.Count) -ForegroundColor Yellow
        Write-Host '      After reboot, re-run V06 or I04 to confirm the new drivers loaded.' -ForegroundColor Yellow
        Write-Host '      Suggested commands:' -ForegroundColor Yellow
        Write-Host '        Restart-Computer'  -ForegroundColor DarkGray
        Write-Host '        # after reboot:'   -ForegroundColor DarkGray
        Write-Host '        .\Deploy-AMDGraphicsDriverOnWindowsServer.ps1 -OnlyPhases V06' -ForegroundColor DarkGray
        Write-Host ''
        # If the boot-signing environment is currently blocking self-
        # signed loads, the reboot alone will not help; we have to
        # surface the firmware/HVCI requirement again.
        if (-not $bootEnvNow.EffectiveCanLoadSelfSigned) {
            Write-Host '  [!] Boot-signing environment will still BLOCK driver load after a plain reboot:' -ForegroundColor Red
            foreach ($r in $bootEnvNow.BlockReasons) {
                Write-Host ('      - {0}' -f $r) -ForegroundColor Red
            }
            Write-Host '      Resolve these BEFORE rebooting (see I00 instructions, or re-run I00).' -ForegroundColor Red
            Write-Host ''
        }
    } else {
        Write-Ok 'No reboot required. All installed drivers are active.'
    }
    Write-Host ''

    # Persist final state for downstream consumers
    $Ctx | Add-Member -NotePropertyName PostInstallReport -NotePropertyValue $perDevice -Force

    # If a previous run set the "pending reboot" marker AND the system
    # is now in a good state (no further reboot required), clear it.
    # This means the next invocation will not show a stale "reboot
    # pending" warning.
    if (-not $needReboot) {
        $pending = Get-PendingRebootMarker -Ctx $Ctx
        if ($pending) {
            Clear-PendingRebootMarker -Ctx $Ctx
            Write-Host ('  Cleared pending-reboot marker (recorded by {0} on {1}).' -f $pending.Source, $pending.RecordedAt) -ForegroundColor DarkGray
        }
    }

    Write-PhaseFooter 'I04' 'done'
}

#####################################################################
# SECTION 10: Cleanup action
#####################################################################
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
                Write-Warn2 ('Could not remove CI policy {0} - inspect manually with CiTool.exe -lp' -f $policyId)
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

#####################################################################
# SECTION 11: Main dispatcher
#####################################################################
function Show-PhaseList {
    Write-Host ''
    Write-Host 'Registered phases:' -ForegroundColor Magenta
    Write-Host ('  {0,-5} {1,-23} {2,-6} {3}' -f 'ID','Name','Group','Function') -ForegroundColor Magenta
    Write-Host ('  {0}' -f ('-' * 70)) -ForegroundColor Magenta
    foreach ($p in $Script:PhaseRegistry) {
        Write-Host ('  {0,-5} {1,-23} {2,-6} {3}' -f $p.Id, $p.Name, $p.Group, $p.Func)
    }
    Write-Host ''
}

function Show-ReferenceLinks { # psa-disable-line PSA6003 -- compound noun (e.g., Policies, Drivers, Catalogs) is semantically plural for set-returning helpers
    # Pretty-print the curated Microsoft Learn reference index. Same
    # content as the "MICROSOFT LEARN REFERENCE LIBRARY" comment block
    # at the top of the file. Triggered at runtime by -References, by
    # -Help, and by I00 when the user runs the install action.
    #
    # Display modes:
    #   (default) - full categorized table with explanatory blurbs
    #   -Compact - one-line pointer telling the user how to see the
    #               full table; used by I00 to keep its output short.
    param([switch]$Compact)

    if ($Compact) {
        Write-Host ''
        Write-Host '    For prerequisite reading (Secure Boot, WDAC, INF, SDK/WDK, PnPUtil),' -ForegroundColor Cyan
        Write-Host '    re-run this script with -References to see the curated Microsoft Learn link list.' -ForegroundColor Cyan
        return
    }

    # Each entry is { Title, Url, Why } - Why is a one-liner that
    # explains why this link is relevant to THIS script. Categories
    # mirror the comment block at the top of the file.
    $sections = @(
        @{
            Heading = '[1] SECURE BOOT (UEFI signature enforcement)'
            Why     = 'Secure Boot is what blocks self-signed kernel-mode drivers by default. The WDAC path in I02 keeps Secure Boot ENABLED while still loading the drivers - this section explains how Secure Boot works.'
            Links   = @(
                @{ T='What Is Secure Boot for Windows'
                   U='https://learn.microsoft.com/en-us/windows-hardware/drivers/bringup/secure-boot' }
                @{ T='Secure Boot and Trusted Boot (chain-of-trust architecture)'
                   U='https://learn.microsoft.com/en-us/windows/security/operating-system-security/system-security/trusted-boot' }
                @{ T='Secure the Windows boot process (Secure Boot, Trusted Boot, ELAM, Measured Boot)'
                   U='https://learn.microsoft.com/en-us/windows/security/operating-system-security/system-security/secure-the-windows-10-boot-process' }
                @{ T='Secure Boot Key Creation and Management Guidance (PK / KEK / db / dbx)'
                   U='https://learn.microsoft.com/en-us/windows-hardware/manufacture/desktop/windows-secure-boot-key-creation-and-management-guidance' }
            )
        }
        @{
            Heading = '[2] TEST SIGNING / DRIVER SIGNING POLICY'
            Why     = 'The legacy I02 path (-UseTestSigning) uses BCD testsigning. The WDAC path is the modern alternative this script prefers; this section is here for context.'
            Links   = @(
                @{ T='Test Signing (overview of dev/lab signing process)'
                   U='https://learn.microsoft.com/en-us/windows-hardware/drivers/install/test-signing' }
                @{ T='The TESTSIGNING boot configuration option'
                   U='https://learn.microsoft.com/en-us/windows-hardware/drivers/install/the-testsigning-boot-configuration-option' }
                @{ T='BCDEdit /set (testsigning, nointegritychecks, ...)'
                   U='https://learn.microsoft.com/en-us/windows-hardware/drivers/devtest/bcdedit--set' }
                @{ T='Installing an Unsigned Driver during Development and Test'
                   U='https://learn.microsoft.com/en-us/windows-hardware/drivers/install/installing-an-unsigned-driver-during-development-and-test' }
                @{ T='How to Test Preproduction Drivers with Secure Boot Enabled'
                   U='https://learn.microsoft.com/en-us/windows-hardware/drivers/install/preproduction-driver-signing-and-install' }
            )
        }
        @{
            Heading = '[3] WDAC / APP CONTROL FOR BUSINESS'
            Why     = 'This is the I02 default path. The script builds a supplemental policy that adds its self-signed cert as a kernel-mode signer, deploys via CiTool, and reverses cleanly via Cleanup.'
            Links   = @(
                @{ T='Application Control / WDAC documentation root'
                   U='https://learn.microsoft.com/en-us/windows/security/application-security/application-control/windows-defender-application-control/' }
                @{ T='Use multiple App Control policies (base + supplemental design)'
                   U='https://learn.microsoft.com/en-us/windows/security/application-security/application-control/windows-defender-application-control/design/deploy-multiple-wdac-policies' }
                @{ T='Deploy App Control policies using script (CiTool --update-policy)'
                   U='https://learn.microsoft.com/en-us/windows/security/application-security/application-control/windows-defender-application-control/deployment/deploy-wdac-policies-with-script' }
                @{ T='Remove App Control policies (CiTool --remove-policy)'
                   U='https://learn.microsoft.com/en-us/windows/security/application-security/application-control/windows-defender-application-control/deployment/disable-wdac-policies' }
            )
        }
        @{
            Heading = '[4] INF FILE STRUCTURE'
            Why     = 'P05/P06 parse and patch INFs. The ProductType=3 decoration in [Manufacturer] is what makes a Client INF apply to Windows Server.'
            Links   = @(
                @{ T='*** SKU Differentiation Directive (PRIMARY REF for ProductType=3 technique) ***'
                   U='https://learn.microsoft.com/en-us/windows-hardware/drivers/display/sku-differentiation-directive' }
                @{ T='Summary of INF Sections'
                   U='https://learn.microsoft.com/en-us/windows-hardware/drivers/install/summary-of-inf-sections' }
                @{ T='General Syntax Rules for INF Files'
                   U='https://learn.microsoft.com/en-us/windows-hardware/drivers/install/general-syntax-rules-for-inf-files' }
                @{ T='INF Manufacturer Section (TargetOSVersion, ProductType=3 ...)'
                   U='https://learn.microsoft.com/en-us/windows-hardware/drivers/install/inf-manufacturer-section' }
                @{ T='INF Models Section'
                   U='https://learn.microsoft.com/en-us/windows-hardware/drivers/install/inf-models-section' }
                @{ T='Combining Platform Extensions with Operating System Versions (TargetOSVersion grammar)'
                   U='https://learn.microsoft.com/en-us/windows-hardware/drivers/install/combining-platform-extensions-with-operating-system-versions' }
                @{ T='Creating INF Files for Multiple Platforms and Operating Systems'
                   U='https://learn.microsoft.com/en-us/windows-hardware/drivers/install/creating-inf-files-for-multiple-platforms-and-operating-systems' }
                @{ T='Using a Universal INF File (declarative-only restrictions)'
                   U='https://learn.microsoft.com/en-us/windows-hardware/drivers/install/using-a-universal-inf-file' }
            )
        }
        @{
            Heading = '[5] WINDOWS SDK + WDK'
            Why     = 'P02 acquires these because P08 needs inf2cat (WDK) and P09 needs signtool (SDK).'
            Links   = @(
                @{ T='Download the Windows Driver Kit (WDK) - includes inf2cat'
                   U='https://learn.microsoft.com/en-us/windows-hardware/drivers/download-the-wdk' }
                @{ T='Windows SDK downloads - includes signtool'
                   U='https://learn.microsoft.com/en-us/windows/apps/windows-sdk/downloads' }
                @{ T='Install the WDK using WinGet'
                   U='https://learn.microsoft.com/en-us/windows-hardware/drivers/install-the-wdk-using-winget' }
                @{ T='Install the WDK using NuGet'
                   U='https://learn.microsoft.com/en-us/windows-hardware/drivers/install-the-wdk-using-nuget' }
                @{ T='Kits and tools overview (SDK / WDK / EWDK / HLK relationships)'
                   U='https://learn.microsoft.com/en-us/windows-hardware/get-started/kits-and-tools-overview' }
                @{ T='Running InfVerif from the Command Line (validate INF files)'
                   U='https://learn.microsoft.com/en-us/windows-hardware/drivers/devtest/running-infverif-from-the-command-line' }
            )
        }
        @{
            Heading = '[6] PNPUTIL (driver-store management)'
            Why     = 'I03 calls pnputil /add-driver. I04 / V05 use /enum-drivers. Cleanup advice references /delete-driver.'
            Links   = @(
                @{ T='PnPUtil overview'
                   U='https://learn.microsoft.com/en-us/windows-hardware/drivers/devtest/pnputil' }
                @{ T='PnPUtil Command Syntax (full flag reference, exit codes)'
                   U='https://learn.microsoft.com/en-us/windows-hardware/drivers/devtest/pnputil-command-syntax' }
                @{ T='PnPUtil Command Examples (typical workflows)'
                   U='https://learn.microsoft.com/en-us/windows-hardware/drivers/devtest/pnputil-examples' }
                @{ T='Create Installed Driver Package Inventory (audit installed drivers)'
                   U='https://learn.microsoft.com/en-us/windows-hardware/drivers/driversecurity/create-a-driver-inventory' }
            )
        }
        @{
            Heading = '[7] AMD GPU TAXONOMY (drives Get-AmdDriverBranchPreference)'
            Why     = 'P03 picks the Adrenalin Main vs Vega-Polaris Legacy branch based on the architecture (GCN/Vega/RDNA generation) of the detected GPU/APU. Wrong branch -> silent install no-op. The script queries AMD product pages live for the "Former Codename" field and falls back to a heuristic when the page is unavailable. These references provide both the runtime data source (AMD product pages) and the codename->architecture mapping (kernel doc + Wikipedia).'
            Links   = @(
                @{ T='*** AMD CPU/APU specifications (live "Former Codename" lookup target) ***'
                   U='https://www.amd.com/en/products/specifications/processors.html' }
                @{ T='*** AMD Graphics specifications (live dGPU lookup target) ***'
                   U='https://www.amd.com/en/products/specifications/graphics.html' }
                @{ T='*** AMD Hardware Components Information per Product (Linux kernel - codename->GC mapping) ***'
                   U='https://docs.kernel.org/gpu/amdgpu/amd-hardware-list-info.html' }
                @{ T='List of AMD graphics processing units (Wikipedia)'
                   U='https://en.wikipedia.org/wiki/List_of_AMD_graphics_processing_units' }
                @{ T='AMD Software: Adrenalin Edition (release notes / branch policy)'
                   U='https://www.amd.com/en/products/software/adrenalin.html' }
            )
        }
    )

    $line = '=' * 72
    Write-Host ''
    Write-Host $line                                                                    -ForegroundColor Magenta
    Write-Host ' MICROSOFT LEARN REFERENCE LIBRARY                                       ' -ForegroundColor Magenta
    Write-Host $line                                                                    -ForegroundColor Magenta
    Write-Host '  Curated reading list for the prerequisite knowledge needed to'        -ForegroundColor Cyan
    Write-Host '  understand what THIS SCRIPT does. All URLs are en-US; replace'         -ForegroundColor Cyan
    Write-Host '  "/en-us/" with "/ja-jp/" in the URL path for Japanese versions.'       -ForegroundColor Cyan

    foreach ($s in $sections) {
        Write-Host ''
        Write-Host $s.Heading -ForegroundColor Yellow
        Write-Host ('  Why this matters here: {0}' -f $s.Why) -ForegroundColor DarkGray
        Write-Host ''
        foreach ($link in $s.Links) {
            Write-Host ('    - {0}' -f $link.T)
            Write-Host ('      {0}' -f $link.U) -ForegroundColor Blue
        }
    }

    Write-Host ''
    Write-Host $line -ForegroundColor Magenta
    Write-Host '  Quick map of which phase of THIS script each category supports:'         -ForegroundColor Cyan
    Write-Host '    P02  AcquireTools                  -> [5] Windows SDK + WDK'           -ForegroundColor DarkGray
    Write-Host '    P05/P06  AnalyzeInfs / PatchInfs   -> [4] INF File Structure'          -ForegroundColor DarkGray
    Write-Host '    P07  CreateCertificate             -> [2] Test Signing'                -ForegroundColor DarkGray
    Write-Host '    P08  GenerateCatalogs              -> [4][5] inf2cat + INF structure'  -ForegroundColor DarkGray
    Write-Host '    P09  SignCatalogs                  -> [2][5] signtool + signing policy' -ForegroundColor DarkGray
    Write-Host '    I01  TrustCertificate              -> [2] Driver signing policy'       -ForegroundColor DarkGray
    Write-Host '    I02  AuthorizeDriverSigning (default)  -> [3] WDAC supplemental policy' -ForegroundColor DarkGray
    Write-Host '    I02  AuthorizeDriverSigning (-UseTest) -> [1][2] Secure Boot + testsigning' -ForegroundColor DarkGray
    Write-Host '    I03  InstallDrivers                -> [6] PnPUtil'                      -ForegroundColor DarkGray
    Write-Host '    I04  PostInstallVerification       -> [1][6] Secure Boot + PnPUtil'    -ForegroundColor DarkGray
    Write-Host $line -ForegroundColor Magenta
}

function Show-Help {
    $line = '=' * 72
    Write-Host ''
    Write-Host $line -ForegroundColor Magenta
    Write-Host ' AMD Graphics Driver Pipeline for Windows Server 2016 / 2019 / 2022 / 2025' -ForegroundColor Magenta
    Write-Host (' Version: {0}  [{1}]  SHA256: {2}' -f $Script:ScriptVersion, $Script:ScriptTag, $Script:ScriptHash) -ForegroundColor DarkCyan
    Write-Host $line -ForegroundColor Magenta

    # Show the prerequisite-workflow block at the top of -Help so anyone
    # reading the help understands when this script is appropriate.
    Show-DriverInstallationOrderNotice

    Write-Host ''
    Write-Host 'SYNOPSIS' -ForegroundColor Cyan
    Write-Host '  Patches AMD chipset driver INF files with ProductType=3 decorations'
    Write-Host '  for Windows Server, regenerates and re-signs catalogs with a self-'
    Write-Host '  signed certificate, deploys a WDAC supplemental policy that allow-'
    Write-Host '  lists that cert as a kernel signer, and installs the patched drivers'
    Write-Host '  onto the running OS - all WITH Secure Boot remaining enabled.'
    Write-Host ''
    Write-Host '  The pipeline is split into three stages:'
    Write-Host '    PREPARATION  - file artifacts under -WorkRoot only (idempotent)'
    Write-Host '    VERIFICATION - read-only diagnostics + dry-run of installation'
    Write-Host '    INSTALLATION - modifies the running OS (cert trust / WDAC policy / pnputil)'

    Write-Host ''
    Write-Host 'USAGE' -ForegroundColor Cyan
    Write-Host '  .\Deploy-AMDGraphicsDriverOnWindowsServer.ps1 [-Action <mode>] [other parameters]'
    Write-Host '  .\Deploy-AMDGraphicsDriverOnWindowsServer.ps1 -Help'

    Write-Host ''
    Write-Host 'ACTIONS  ( -Action <value> )' -ForegroundColor Cyan
    Write-Host '  PrepareVerify [default] Prepare + Verify in one go.'
    Write-Host '               Runs all preparation phases (P00-P09) followed by all'
    Write-Host '               verification phases (V01-V05). Equivalent to running'
    Write-Host '               -Action Prepare and then -Action Verify back-to-back.'
    Write-Host '               Never modifies the running OS.'
    Write-Host ''
    Write-Host '  Prepare      Run all preparation phases (P00-P09) only.'
    Write-Host '               Outputs to -WorkRoot only.  Idempotent.'
    Write-Host '               P02 also installs 7-Zip / SDK / WDK system-wide.'
    Write-Host ''
    Write-Host '  Verify       Run all verification phases (V01-V05) only.'
    Write-Host '               Read-only diagnostics. Never modifies the OS.'
    Write-Host '                 V01 - Verify artifacts (PFX/CER/INFs/CATs exist)'
    Write-Host '                 V02 - Verify certificate (validity, EKU, private key)'
    Write-Host '                 V03 - Verify catalogs (signtool /verify /pa)'
    Write-Host '                 V04 - Verify INFs   (ProductType=3 decorations)'
    Write-Host '                 V05 - Dry-run Install (simulates I01/I02/I03)'
    Write-Host ''
    Write-Host '  Install      Run all installation phases (I01-I03) on the running OS:'
    Write-Host '                 I01 - Trust certificate (Root + TrustedPublisher)'
    Write-Host '                 I02 - Enable test signing (bcdedit, reboot required)'
    Write-Host '                 I03 - Install drivers via pnputil'
    Write-Host ''
    Write-Host '  All          Prepare + Verify + Install in sequence.'
    Write-Host '  Cleanup      Delete -WorkRoot entirely.'
    Write-Host '  ListPhases   Print the full phase registry and exit.'

    Write-Host ''
    Write-Host 'PARAMETERS' -ForegroundColor Cyan
    Write-Host '  Help / mode' -ForegroundColor DarkGray
    Write-Host '    -Help                    Show this help and exit. Aliases: -h, -?' -ForegroundColor Yellow
    Write-Host '    -Action <string>         Pipeline mode (see ACTIONS).' -ForegroundColor Yellow
    Write-Host '                             Default: PrepareVerify'
    Write-Host '    -OnlyPhases <string[]>   Restrict execution to specific phases.' -ForegroundColor Yellow
    Write-Host '                             Accepts IDs (P05) or names (PatchInfs).'
    Write-Host '                             Mandatory phases P00 / P01 always run first.'
    Write-Host ''
    Write-Host '  Workspace' -ForegroundColor DarkGray
    Write-Host '    -WorkRoot <path>         Working directory.' -ForegroundColor Yellow
    Write-Host '                             Default: C:\Temp\Workspace_AMD-Graphics'
    Write-Host '    -CleanWorkRoot           Delete -WorkRoot before running anything.' -ForegroundColor Yellow
    Write-Host '    -Force                   Bypass cached phase markers (force re-run).' -ForegroundColor Yellow
    Write-Host ''
    Write-Host '  Run log capture' -ForegroundColor DarkGray
    Write-Host '    -LogFile <path>          Capture full console transcript to <path>.' -ForegroundColor Yellow
    Write-Host '                             Console keeps Write-Host coloring; the file gets'
    Write-Host '                             every stream (Output / Host / Error / Warning /'
    Write-Host '                             Verbose / Debug) as plain text. Append mode.'
    Write-Host '                             Suggested name:'
    Write-Host '                               C:\Temp\amd-graphics_<Action>_<yyyyMMdd-HHmmss>.log'
    Write-Host ''
    Write-Host '  AMD installer source' -ForegroundColor DarkGray
    Write-Host '    -InstallerUrl <url>      Specific installer URL (skips auto-resolve).' -ForegroundColor Yellow
    Write-Host '                             Default: empty -> auto-resolve from AMD pages'
    Write-Host '    -AmdLandingUrls <s[]>    AMD support pages probed for the latest URL.' -ForegroundColor Yellow
    Write-Host '                             Default: 5 product pages covering Ryzen Pro APU,'
    Write-Host '                             Ryzen consumer APU, Radeon RX, Radeon AI Pro.'
    Write-Host '                             At runtime, Get-AmdGpuTarget detects the actual'
    Write-Host '                             GPU/APU and PREPENDS its product page to this list.'
    Write-Host '    -AmdFallbackUrl <url>    Last-resort URL when probe fails.' -ForegroundColor Yellow
    Write-Host '                             Default: lab Ryzen 7 PRO 5750GE product page'
    Write-Host ''
    Write-Host '  Certificate' -ForegroundColor DarkGray
    Write-Host '    -PfxPassword <string>    PFX export password.' -ForegroundColor Yellow
    Write-Host '                             Default: ChangeMe!2026  (CHANGE FOR PRODUCTION)'
    Write-Host '    -TimestampUrl <url>      RFC3161 timestamp URL for signtool.' -ForegroundColor Yellow
    Write-Host '                             Default: http://timestamp.digicert.com'

    Write-Host ''
    Write-Host 'PHASES' -ForegroundColor Cyan
    $phaseDescriptions = @{
        'P00' = 'Admin / TLS / OS detection'
        'P01' = 'Workspace directories (with optional clean)'
        'P02' = '7-Zip + Windows SDK (signtool) + Windows WDK (inf2cat)'
        'P03' = 'Download AMD installer (auto-resolve URL)'
        'P04' = '7z extraction (incl. nested archives)'
        'P05' = 'INF inventory CSV + DDInstall HWID parsing'
        'P06' = 'INF rewrite (add ProductType=3 / NTamd64 server decorations)'
        'P07' = 'Self-signed code-signing certificate -> PFX/CER files'
        'P08' = 'inf2cat regenerates .cat files (per Server2025_X64 / fallbacks)'
        'P09' = 'signtool signs each .cat with the self-signed cert'
        'V01' = 'Check that PFX/CER/INFs/CATs exist and are well-formed'
        'V02' = 'Validate cert chain / expiry / EKU (code-signing) / private key'
        'V03' = 'signtool /verify /pa on each .cat (trust-aware classification)'
        'V04' = 'INF parsing + ProductType=3 decoration coverage check'
        'V05' = 'Dry-run I01 trust / I02 WDAC / I03 driver install (read-only)'
        'V06' = 'Per-device AS-IS/TO-BE comparison + version-aware decision + risk eval'
        'I00' = 'Final pre-install review: hardware impact, cert, boot-signing env'
        'I01' = 'Import cert into LocalMachine\Root + LocalMachine\TrustedPublisher'
        'I02' = 'AuthorizeDriverSigning: WDAC supplemental policy (default) / testsigning (-UseTestSigning)'
        'I03' = 'pnputil /add-driver per patched INF (skips downgrade per version compare)'
        'I04' = 'Per-device disposition (LOADED/REBOOT_NEEDED/KEPT_CURRENT/UNCHANGED/FAILED)'
    }
    foreach ($p in $Script:PhaseRegistry) {
        $desc = $phaseDescriptions[$p.Id]
        Write-Host ('  {0}  {1,-23}  {2}' -f $p.Id, $p.Name, $desc)
    }

    Write-Host ''
    Write-Host 'EXAMPLES' -ForegroundColor Cyan
    Write-Host '  # Default: full preparation + verification (no system changes)'
    Write-Host '  .\Deploy-AMDGraphicsDriverOnWindowsServer.ps1' -ForegroundColor Green
    Write-Host ''
    Write-Host '  # Wipe workspace and start over from scratch (Prepare + Verify)'
    Write-Host '  .\Deploy-AMDGraphicsDriverOnWindowsServer.ps1 -CleanWorkRoot' -ForegroundColor Green
    Write-Host ''
    Write-Host '  # Run only preparation phases (skip verification)'
    Write-Host '  .\Deploy-AMDGraphicsDriverOnWindowsServer.ps1 -Action Prepare' -ForegroundColor Green
    Write-Host ''
    Write-Host '  # Run only verification phases (assumes Prepare already done)'
    Write-Host '  .\Deploy-AMDGraphicsDriverOnWindowsServer.ps1 -Action Verify' -ForegroundColor Green
    Write-Host ''
    Write-Host '  # Re-run only INF patching after editing the script'
    Write-Host '  .\Deploy-AMDGraphicsDriverOnWindowsServer.ps1 -OnlyPhases P06 -Force' -ForegroundColor Green
    Write-Host ''
    Write-Host '  # Run multiple specific phases'
    Write-Host '  .\Deploy-AMDGraphicsDriverOnWindowsServer.ps1 -OnlyPhases P05,P06,P07 -Force' -ForegroundColor Green
    Write-Host ''
    Write-Host '  # Apply prepared package to the running OS'
    Write-Host '  .\Deploy-AMDGraphicsDriverOnWindowsServer.ps1 -Action Install' -ForegroundColor Green
    Write-Host ''
    Write-Host '  # Dry-run only - simulate I01/I02/I03 without doing anything'
    Write-Host '  .\Deploy-AMDGraphicsDriverOnWindowsServer.ps1 -OnlyPhases V05' -ForegroundColor Green
    Write-Host ''
    Write-Host '  # Install just the cert trust step'
    Write-Host '  .\Deploy-AMDGraphicsDriverOnWindowsServer.ps1 -Action Install -OnlyPhases I01' -ForegroundColor Green
    Write-Host ''
    Write-Host '  # End-to-end (Prepare + Verify + Install)'
    Write-Host '  .\Deploy-AMDGraphicsDriverOnWindowsServer.ps1 -Action All' -ForegroundColor Green
    Write-Host ''
    Write-Host '  # Use a specific installer version'
    Write-Host '  .\Deploy-AMDGraphicsDriverOnWindowsServer.ps1 ``' -ForegroundColor Green
    Write-Detail "-InstallerUrl 'https://drivers.amd.com/drivers/amd_chipset_software_7.11.26.2142.exe'" -Color Green
    Write-Host ''
    Write-Host '  # Show registered phases'
    Write-Host '  .\Deploy-AMDGraphicsDriverOnWindowsServer.ps1 -Action ListPhases' -ForegroundColor Green
    Write-Host ''
    Write-Host '  # Wipe everything (workspace and re-cached files)'
    Write-Host '  .\Deploy-AMDGraphicsDriverOnWindowsServer.ps1 -Action Cleanup' -ForegroundColor Green

    Write-Host ''
    Write-Host 'TYPICAL WORKFLOW (production lab)' -ForegroundColor Cyan
    Write-Host '  1.  -CleanWorkRoot                                 # default: Prepare + Verify'
    Write-Host '  2.  inspect outputs / dry-run report'
    Write-Host '  3.  -Action Install -OnlyPhases I01                # trust cert'
    Write-Host '  4.  -Action Install -OnlyPhases I02                # testsigning ON'
    Write-Host '  5.  *** REBOOT ***'
    Write-Host '  6.  -Action Install -OnlyPhases I03                # install drivers'

    Write-Host ''
    Write-Host 'NOTES' -ForegroundColor Cyan
    Write-Host '  - Run from an elevated PowerShell session.'
    Write-Host '  - Lab / verification use only - this is NOT a Microsoft-supported'
    Write-Host '    configuration. Use at your own risk.'
    Write-Host '  - Each preparation phase writes a marker JSON under .markers\;'
    Write-Host '    re-runs without -Force will reuse cached state where possible.'
    Write-Host '  - For PowerShell-style help with full parameter syntax, also try:'
    Write-Host '      Get-Help .\Deploy-AMDGraphicsDriverOnWindowsServer.ps1 -Full'
    Write-Host '  - For the curated Microsoft Learn link list (Secure Boot, WDAC,'
    Write-Host '    INF, SDK/WDK, PnPUtil), run:'
    Write-Host '      .\Deploy-AMDGraphicsDriverOnWindowsServer.ps1 -References'    -ForegroundColor Cyan
    Write-Host ''
}

# ----- References short-circuit (highest priority - no admin / no work) -----
# Display the curated Microsoft Learn link list and exit. This is
# checked BEFORE -Help so a user who passes -References -Help (or the
# unlikely combination of both) gets the references view they asked
# for. -References is itself a top-priority short-circuit because it
# requires nothing - no admin, no workspace, no network.
if ($References) {
    Show-ReferenceLinks
    return
}

# ----- Help short-circuit (highest priority - no admin / no work) -----
if ($Help) {
    Show-Help
    return
}

# ----- ListPhases short-circuit -----
if ($Action -eq 'ListPhases') {
    Show-PhaseList
    return
}

# ----- Build context -----
$Ctx = [pscustomobject]@{
    # Params
    Action          = $Action
    OnlyPhases      = $OnlyPhases
    InstallerUrl    = $InstallerUrl
    AmdLandingUrls  = $AmdLandingUrls
    AmdFallbackUrl  = $AmdFallbackUrl
    WorkRoot        = $WorkRoot
    PfxPassword     = $PfxPassword
    TimestampUrl    = $TimestampUrl
    Force           = $Force.IsPresent
    CleanWorkRoot   = $CleanWorkRoot.IsPresent
    UseTestSigning  = $UseTestSigning.IsPresent
    AllowWorkstationInstall = $AllowWorkstationInstall.IsPresent
    # Populated by phases
    Os = $null; Paths = $null
    SevenZip = $null; Signtool = $null; Inf2cat = $null
    Installer = $null; InfInventory = $null; InfInventoryDetail = $null; PatchResults = @()
    PatchedDirs = @()  # rehydrated by Resume-CtxFromWorkspace
    CertPfxPath = $null; CertCerPath = $null; CertThumbprint = $null
    # List of phase IDs that will execute this run (used by P00's
    # Workstation-Install guard to know whether any I-phase is queued).
    SelectedPhaseIds = @()
    # Chipset port: UEFI Secure Boot baseline snapshot, captured
    # lazily at P00 and reused by P05 (report appendix), V05 / V06
    # (display), and I02 (pre-check). Pre-declared as $null so the
    # later '.SecureBootBaseline =...' assignment is a property
    # update on the existing pscustomobject rather than a new member
    # add (which is the safer pattern in PSv5 + StrictMode).
    SecureBootBaseline = $null
}

# ----- Cleanup short-circuit -----
if ($Action -eq 'Cleanup') {
    Assert-Admin
    Invoke-Cleanup -Ctx $Ctx
    $cleanupElapsed = (Get-Date) - $Script:ScriptStartTime
    Write-Host ''
    Write-Host (' Total elapsed   : {0}' -f (Format-Elapsed $cleanupElapsed)) -ForegroundColor Cyan
    return
}

# ----- Resolve phase selection -----
$selected = Resolve-PhaseSelection -Action $Action -OnlyPhases $OnlyPhases

$startedAtStr = $Script:ScriptStartTime.ToString('yyyy-MM-dd HH:mm:ss')
Write-Host ''
Write-Host '============================================================' -ForegroundColor Magenta
Write-Host (' AMD Graphics Driver Pipeline')                                -ForegroundColor Magenta
Write-Host (' Script version  : {0}' -f $Script:ScriptVersion)             -ForegroundColor Cyan
Write-Host (' Script tag      : {0}' -f $Script:ScriptTag)                 -ForegroundColor DarkCyan
Write-Host (' Script SHA256   : {0}  (first 12 chars; full hash differs if file edited)' -f $Script:ScriptHash) -ForegroundColor DarkCyan
if ($Script:ScriptPath) {
    Write-Host (' Script path     : {0}' -f $Script:ScriptPath)            -ForegroundColor DarkGray
}
Write-Host (' Started at      : {0}' -f $startedAtStr)
Write-Host (' Action          : {0}' -f $Action)
Write-Host (' OnlyPhases      : {0}' -f $(if ($OnlyPhases) { $OnlyPhases -join ',' } else { '(all for action)' }))
Write-Host (' WorkRoot        : {0}' -f $WorkRoot)
Write-Host (' CleanWorkRoot   : {0}' -f $CleanWorkRoot.IsPresent)
Write-Host (' Force           : {0}' -f $Force.IsPresent)
Write-Host (' Selected phases : {0}' -f (($selected | ForEach-Object Id) -join ' -> '))
Write-Host '============================================================' -ForegroundColor Magenta

# ----- Implicit prerequisites -----
# P00 + P01 are always required (admin/OS detect/workspace).
# Run them first (they're idempotent themselves) regardless of -OnlyPhases.
$mandatoryIds = @('P00','P01')
$mandatory = $Script:PhaseRegistry | Where-Object { $_.Id -in $mandatoryIds -and $_.Id -notin ($selected | ForEach-Object Id) }
$queue = @($mandatory) + @($selected)

# Stash the phase-ID list on the context so P00 can see whether
# any Install phase (I01-I04) is queued without re-resolving phases.
$Ctx.SelectedPhaseIds = @($queue | ForEach-Object Id)

# ----- Execute -----
# Wrap the whole phase loop + summary in a try/finally so the
# workspace lock (acquired in P01 via Assert-NoConcurrentRun) is
# released on EVERY exit path - normal completion, phase throw, or
# top-level error. The earlier design relied solely on the
# Register-EngineEvent PowerShell.Exiting hook in Set-WorkspaceLock,
# which only fires when the PowerShell host process itself exits.
# In an interactive console (where the host is reused across many
# script invocations), the hook never fires and the lock file leaks
# - the next run in the same console then mis-detects its own host's
# PID in the leftover lock and refuses to start with "Another
# instance is already running". The finally block + the new self-PID
# detection in Test-WorkspaceLockHeld together close that gap.
# Mirrors Chipset fix; see SPEC §A.1.4 sister-script symmetry.
try {
    foreach ($phase in $queue) {
        try {
            & $phase.Func -Ctx $Ctx
        } catch {
            Write-Fail "$($phase.Id) [$($phase.Name)] failed: $($_.Exception.Message)"
            Write-PhaseFooter $phase.Id 'failed'
            throw
        }
    }

    # ----- Summary -----
    $totalElapsed = (Get-Date) - $Script:ScriptStartTime
    $endedAtStr   = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')

    Write-Host ''
    Write-Host '============================================================' -ForegroundColor Magenta
    Write-Host ' RUN SUMMARY' -ForegroundColor Magenta
    Write-Host '============================================================' -ForegroundColor Magenta
    Write-Host " Script version  : $($Script:ScriptVersion) [$($Script:ScriptTag)]" -ForegroundColor Cyan
    Write-Host " Script SHA256   : $($Script:ScriptHash)" -ForegroundColor DarkCyan
    Write-Host " OS              : $($Ctx.Os.Name) (build $($Ctx.Os.ActualBuild))"
    Write-Host " Workspace       : $($Ctx.WorkRoot)"
    if ($Ctx.Installer)       { Write-Host " Installer       : $(Split-Path $Ctx.Installer -Leaf)" }
    if ($Ctx.InfInventory)    { Write-Host " INFs analyzed   : $($Ctx.InfInventory.Count)" }
    if ($Ctx.PatchResults)    { Write-Host " INFs patched    : $($Ctx.PatchResults.Count)" }
    if ($Ctx.CertThumbprint)  { Write-Host " Cert thumbprint : $($Ctx.CertThumbprint)" }
    Write-Host " Phases run      : $((($queue | ForEach-Object Id)) -join ' -> ')"
    Write-Host " Started at      : $startedAtStr"
    Write-Host " Ended at        : $endedAtStr"
    Write-Host (" Total elapsed   : {0}" -f (Format-Elapsed $totalElapsed)) -ForegroundColor Cyan

    # Per-phase timing breakdown
    if ($Script:PhaseTimings.Count -gt 0) {
        Write-Host ''
        Write-Host ' Phase timings:' -ForegroundColor Cyan
        Write-Host ('   {0,-5} {1,-23} {2,-8} {3,10}' -f 'ID','Name','Status','Elapsed')
        Write-Host ('   {0}' -f ('-' * 50))
        $sumSeconds = 0.0
        foreach ($t in $Script:PhaseTimings) {
            $name = ($Script:PhaseRegistry | Where-Object Id -eq $t.Id | Select-Object -First 1).Name
            if (-not $name) { $name = '(unknown)' }
            $color = switch ($t.Status) {
                'done'    { 'Green' }
                'cached'  { 'DarkGray' }
                'skipped' { 'DarkGray' }
                'failed'  { 'Red' }
                default   { 'White' }
            }
            Write-Host ('   {0,-5} {1,-23} {2,-8} {3,10}' -f `
                           $t.Id, $name, $t.Status, (Format-Elapsed $t.Elapsed)) `
                      -ForegroundColor $color
            $sumSeconds += $t.Elapsed.TotalSeconds
        }
        Write-Host ('   {0}' -f ('-' * 50))
        Write-Host ('   {0,-5} {1,-23} {2,-8} {3,10}' -f 'SUM','(phase total)','', (Format-Elapsed ([TimeSpan]::FromSeconds($sumSeconds)))) -ForegroundColor Cyan
    }
    Write-Host '============================================================' -ForegroundColor Magenta
}
finally {
    # -ExportTraceOnExit switch handling. When the user passed
    # -ExportTraceOnExit, write a final JSON snapshot of the trace state
    # to <WorkRoot>\logs\debugtrace_export_final_<timestamp>.json. This
    # runs INSIDE the finally so it executes regardless of how we got
    # here - success, phase-throw, or top-level error. We don't include
    # the full JSONL events block (-IncludeEvents) by default because
    # the snapshot can be cross-referenced with the live JSONL file
    # separately and including events doubles the export size.
    if ($ExportTraceOnExit -and $Ctx -and $Ctx.Paths -and $Ctx.Paths.Logs) {
        try {
            $ts = (Get-Date).ToString('yyyyMMdd-HHmmss')
            $exportPath = Join-Path $Ctx.Paths.Logs ("debugtrace_export_final_{0}.json" -f $ts)
            Export-DebugTraceJson -Path $exportPath | Out-Null
            Write-Host ('[*] Debug trace export -> {0}' -f $exportPath) -ForegroundColor DarkGreen
        } catch {
            # Don't let the export failure mask a more important error.
            Write-Warning ("[-ExportTraceOnExit] export failed: {0}" -f $_.Exception.Message)
        }
    }

    # Release the workspace lock regardless of how we got here.
    # Safe to call when the lock was never acquired (e.g. failure
    # before P01) because Clear-WorkspaceLock is idempotent and a
    # no-op when the lock file does not exist or $Ctx.Paths is null.
    if ($Ctx -and $Ctx.Paths -and $Ctx.Paths.Markers) {
        try { Clear-WorkspaceLock -Ctx $Ctx } catch { } # psa-disable-line PSA3004 -- intentional best-effort cleanup in finally; a failure here must not mask the original exception
    }

    # Close the transcript opened in SECTION 0.25. Idempotent;
    # best-effort, must not mask the original exception (if any).
    if ($Script:LogFileActive) {
        try {
            Stop-Transcript -ErrorAction SilentlyContinue | Out-Null
        } catch { } # psa-disable-line PSA3004 -- intentional best-effort cleanup
        $Script:LogFileActive = $false
    }
}

