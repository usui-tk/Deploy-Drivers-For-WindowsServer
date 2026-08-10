# TESTING.md — Physical Hardware Validation Results

This document consolidates the validation results for `Deploy-Drivers-For-WindowsServer`. Because this repository ships **experimental scripts that target AMD's consumer-class Ryzen chipset / Radeon iGPU / Ryzen AI NPU**, all meaningful validation depends on access to physical AMD consumer hardware. Testing on non-AMD-consumer hardware (server-class EPYC, ARM, Intel, virtual machines without the target devices, etc.) cannot exercise the device-bind, driver-upgrade, or post-install verification paths that this pipeline exists to validate. This document therefore covers only physical-hardware validation:

1. **Validation Result 1: ThinkCentre M75q Tiny Gen 2** (Windows Server 2025 physical / Cezanne Zen 3 — chipset & graphics validated)
2. **Validation Result 2: ThinkPad X13 Gen 1 AMD (2020)** (Windows 11 Enterprise LTSC 2024 / Renoir Zen 2 — chipset & graphics validated)
3. **Validation Result 3 (NPU script)** — **🆘 NOT YET VALIDATED on physical NPU hardware. See [§3](#3-validation-result-3-npu-script--currently-unverified) for the current limited validation status.**
4. **Validation Result 4 (BthPan script)** — ⏳ **PLANNED.** ThinkPad + Intel AX210 + Windows Server 2025 build 26100.32860 is the first physical-validation target. See [§4](#4-validation-result-4-bthpan-script--planned) for the planned test sequence. **Update 2026-08-07**: `PrepareVerify` was field-executed on a WS2016 host without a Bluetooth controller (staging-path validation; the AX210 physical-bind validation is still pending) — see [§20](#20-validation-scenario-20-2026-08-07-ws2016--ryzen-5-pro-4650u-field-runs-chipset--graphics--bthpan-prepareverify).

> **Documentation language policy**: This document is maintained in
> English only. See `README.md` and `README.ja.md` for the bilingual
> entry-point documentation; for the repository-wide language policy
> see `SPEC.md` §A.12.

---

## 0. Validation status summary

> Read this before sections 1-3. The four scripts have **very different validation maturity levels**.

| Script | Physical-hardware validation | Real driver install on target HW | Recommended use |
|---|---|---|---|
| **Chipset** | ✓ M75q Tiny Gen 2, X13 Gen 1 AMD; WS2016 + Ryzen 5 PRO 4650U field host (`PrepareVerify`, 2026-08-07 — §20). See CHANGELOG for per-revision validation history | ✓ install completed successfully on M75q (WS2025) | Lab + cautious production |
| **Graphics** | ✓ M75q Tiny Gen 2, X13 Gen 1 AMD; WS2016 + Ryzen 5 PRO 4650U field host (`PrepareVerify`, 2026-08-07 — §20; this run surfaced the QuickEdit console-freeze, SPEC D.38). See CHANGELOG for per-revision validation history | ✓ install completed successfully on M75q (WS2025) | Lab + cautious production |
| **NPU** | ❌ **none** (no physical NPU machine in maintainer's lab) | ❌ **never executed** | **Experimental / research-grade only. Do not deploy in production.** |
| **BthPan** | ⏳ partial — **`PrepareVerify` field-executed 2026-08-07** on WS2016 + Ryzen 5 PRO 4650U (no Bluetooth controller present: staging-path validation only; §20). AX210 device-bind validation still planned (§4) | ❌ **not yet executed** | New script; physical validation pending. Logic shares the proven Phase / Secure Boot / WDAC framework from the Chipset script (Edit-InfForServer, Get-OsContext, Resolve-PhaseSelection, etc. are verbatim-inherited). |

> **Note on the ProjectPreference ordering** (see SPEC §D.15 for the
> original override and SPEC D.58.11 for the W5 vocabulary): the
> ordering changes the install-decision semantics in a breaking way for
> chipset and graphics: the scripts now *submit* self-signed `[C]`
> packages ahead of Microsoft generic `[A]` and vendor `[B]` ones as a
> project policy, independent of version — whether a device actually
> rebinds is decided by Windows' rank at install time (pnputil does not
> force a lower-ranked driver). Earlier physical-hardware validation results
> below remain *structurally* valid (extraction, patching, signing,
> WDAC deployment all behave the same), but the **V05 / V06 / I03
> driver-install decisions will differ** — devices that earlier
> revisions classified as `SKIP-newer` are now classified as
> `INSTALL_UPGRADE`. Re-validation on the M75q Tiny Gen 2 and X13 Gen 1
> AMD fixtures is recommended after upgrading.
>
> **Note on the CiTool / UTF-8 / pnputil operational fixes**
> (see SPEC §D.5 / §D.16 / §D.17, and the regression scenarios in
> [§9](#9-regression-scenarios-citool--utf-8--pnputil) below).
> Three operational issues were identified on a clean WS2025 install
> and fixed:
>
> 1. CiTool.exe was invoked without `--json` and blocked at I02 on
>    "Press Enter to Exit" stdin prompt (SPEC §D.16);
> 2. Console encoding was never set to UTF-8 so CiTool's ja-JP stdout
>    displayed as mojibake (SPEC §D.5 / §D.16);
> 3. pnputil exit=259 (`ERROR_NO_MORE_ITEMS`) was misclassified as
>    failure in the I03 summary, diverging from I04's correct
>    REBOOT_NEEDED / no-op recognition (SPEC §D.17).
>
> These fixes do NOT alter the structural pipeline behaviour validated
> on the M75q / X13 Gen 1 AMD fixtures (extraction, patching, signing,
> WDAC deployment all behave the same). The user-visible improvements
> are: I02 no longer hangs ~60-75 s waiting for ENTER; the CiTool log
> line reads `処理が成功しました` instead of mojibake; the I03 summary
> reports `no-op (already present)` instead of mis-counted failures.
> See [CHANGELOG.md](./CHANGELOG.md) for the release in which each fix
> landed.

The NPU script's verification is currently limited to:

1. **Static analysis** with `psa.py` (latest mainline) — full rule set including the `PSA1xxx`..`PSA9xxx` generic families and the `PSAP0xxx` project-convention family (this repository opts in to `PSAP0001`..`PSAP0005`, with `PSAP0005` in strict mode), **0 errors / 0 warnings / 0 info** with the repository-shipped `.psa.config.json` — see `SPEC.md` §A.11.5. The exact rule count is not reproduced here to avoid mechanical drift on upstream additions; the canonical source is the runtime `RULES` registry (visible via `psa.py --list-rules`). `psa.py` is maintained as a canonical artifact in the [ai-generated-artifacts](https://github.com/usui-tk/ai-generated-artifacts) repository; obtain it per `SPEC.md` §A.11 before running, and follow the "Version policy" subsection there (validate against the latest mainline, no fixed-version pinning). Before the analysis pass, two cheap pre-flight self-quality gates SHOULD be run when applicable: `psa.py --config-check .psa.config.json` whenever `.psa.config.json` has been edited, and `psa.py --self-check` whenever a freshly-fetched `psa.py` is being introduced — see `SPEC.md` §A.11.6 for the activation matrix.
2. **Code review** of the AMD-published `quicktest.py` NPU detection logic translated to PowerShell.
3. **No `-Action Install` execution** has been performed by the maintainers anywhere.
4. **No end-to-end run on physical NPU hardware** has been performed by the maintainers.

If you have a Ryzen AI 300 / Ryzen AI Max 300 / Ryzen 7040 / 8040 series machine and successfully run any phase of the NPU script, please report results via GitHub Issues so the validation gap can be closed.

---

## 1. Validation Result 1: ThinkCentre M75q Tiny Gen 2 (Windows Server 2025)

### 1.1 Hardware specifications

| Item | Value |
|---|---|
| Model | Lenovo ThinkCentre M75q Tiny Gen 2 |
| CPU | AMD Ryzen 7 PRO 5750GE (Cezanne, Zen 3, 8 core / 16 thread, 35 W TDP) |
| iGPU | AMD Radeon Graphics (Vega 8, integrated in Cezanne) |
| **NPU** | **none (Cezanne predates AMD's NPU; XDNA NPU first appears in Phoenix / 7040 series)** |
| Memory | DDR4 SO-DIMM 16–32 GB |
| Storage | M.2 NVMe SSD |
| BIOS | UEFI, Secure Boot configurable |
| TPM | fTPM (via AMD PSP) |

### 1.2 OS configuration

| Item | Value |
|---|---|
| OS | Windows Server 2025 Standard / Datacenter |
| Build | 26100 |
| ProductType | 3 (Server) |
| Secure Boot | ON |
| HVCI | OS default (varies by environment) |
| BitLocker | Optional (when enabled, **secure the recovery key in advance**) |

### 1.3 Validation procedure (chipset + graphics only — no NPU on this host)

```powershell
# Elevated PowerShell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force

# Stage 1: PrepareVerify, V06 review (system unchanged)
# Recommended: use -LogFile to keep console colors while capturing the run.
$ts = Get-Date -Format 'yyyyMMdd-HHmmss'
.\Deploy-AMDChipsetDriverOnWindowsServer.ps1  -Action PrepareVerify -CleanWorkRoot `
    -LogFile "C:\Temp\m75q-amd-chipset_PrepareVerify_$ts.log"
.\Deploy-AMDGraphicsDriverOnWindowsServer.ps1 -Action PrepareVerify -CleanWorkRoot `
    -LogFile "C:\Temp\m75q-amd-graphics_PrepareVerify_$ts.log"

# Legacy fallback (Write-Host coloring is stripped from the captured file):
#   .\Deploy-AMDChipsetDriverOnWindowsServer.ps1  -Action PrepareVerify -CleanWorkRoot *>&1 |
#     Tee-Object "C:\Temp\m75q-amd-chipset_PrepareVerify_$ts.log"

# Stage 2: Once V06 risk is acceptable, run Install
# IMPORTANT: secure the BitLocker recovery key beforehand
.\Deploy-AMDChipsetDriverOnWindowsServer.ps1  -Action Install
.\Deploy-AMDGraphicsDriverOnWindowsServer.ps1 -Action Install

# NPU script: NOT APPLICABLE on Cezanne hardware (no NPU device present)
# M75q has no NPU device, so the NPU script cannot be meaningfully exercised here.
```

### 1.4 Key validation results

#### Chipset script

- **P03 detection**: `Cezanne / Zen 3 / Desktop APU, AM4`
- **P03 download**: `amd_chipset_software_8.02.18.557.exe` (~75 MB)
- **P05 inventory**: 67 INFs detected; 32 W11x64 variant INFs selected
- **P06 patching**: 1 INF patched (`AmdMicroPEP.inf`); 31 INFs already Server-compatible and copied through
- **V06 main upgrade candidates** (varies with the actual OEM driver baseline):
  - AMD GPIO Controller: `oem17.inf v2.2.0.130` → `amdgpio2.inf v2.2.0.136`
  - AMD PSP 10.0 Device: `oem26.inf v5.22.0.0` → `amdpsp.inf v5.43.0.0` (HIGH risk — BitLocker caution)
  - AMD SMBus: `oem12.inf v5.12.0.38` → `SMBUSamd.inf v5.12.0.44`

#### Graphics script

- **P03 detection**: `Cezanne APU, Vega-Polaris Legacy branch`
- **P03 download**: `whql-amd-software-adrenalin-edition-XX.X.X-win11-XXX-vega-polaris.exe` (~600 MB)
- **P05 inventory**: 19 INFs detected; `WT64A` (audio) + `WT6A_INF` (display) variants selected
- **P06 patching**: 1 INF patched (`u0197843.inf`); 18 INFs already Server-compatible and copied through
- **V06 main upgrade candidates**:
  - AMD Audio CoProcessor: `oem70.inf v6.0.0.79` → `amdacpbus.inf v6.0.1.83` (MEDIUM risk)
  - AMD Radeon Graphics: newer version in the AMD package → display upgrade (MEDIUM risk)
  - AMD HD Audio Device: `oem58.inf v10.0.1.30` → `AtihdWT6.inf v10.0.1.30` (date-newer, MEDIUM risk)

#### NPU script

- **Not applicable on this host** (Cezanne has no NPU). The NPU script cannot be meaningfully exercised on hardware that lacks an XDNA NPU device.

#### Soundness checks

- All 21 phases completed successfully (chipset + graphics)
- Self-signed certificate (RSA 4096 / SHA-384, 5-year validity) generated successfully
- 32 catalogs (chipset) + 19 catalogs (graphics) generated by `inf2cat /os:Server2025_X64`
- All catalogs successfully timestamp-signed by `signtool`
- After I03 (Install), Device Manager shows 3 chipset + 3 graphics devices bound to `[C] Self-signed`

### 1.5 Known limitations

- On hosts with BitLocker enabled, a PSP driver upgrade can trigger a recovery prompt at the next boot. **Always have the recovery key available** (Control Panel BitLocker UI, or via Microsoft Account backup).
- Some `ROOT\AMD*` software-only entities (AMDLOG / AMDXE etc.) are added by I03 but never appear in `Win32_PnPSignedDriver` enumeration; V06 Section 1 reports them as "software-only" for information only.
- Successful install is confirmed by the `[B] Vendor` → `[C] Self-signed` transition observed in I04.

---

## 2. Validation Result 2: ThinkPad X13 Gen 1 AMD (2020) — Windows 11 Enterprise LTSC 2024

### 2.1 Hardware specifications

| Item | Value |
|---|---|
| Model | Lenovo ThinkPad X13 Gen 1 (AMD, 2020) |
| CPU | AMD Ryzen 5 PRO 4650U (Renoir, Zen 2, 6 core / 12 thread, 15 W TDP) |
| iGPU | AMD Radeon Graphics (Vega 6, integrated in Renoir) |
| **NPU** | **none (Renoir predates AMD's NPU)** |
| Memory | DDR4 16 GB on-board |
| Storage | M.2 NVMe SSD |
| BIOS | UEFI, Secure Boot toggleable |
| TPM | dTPM (Discrete TPM, e.g. Infineon SLB9670) |

### 2.2 OS configuration (at validation time)

| Item | Value |
|---|---|
| OS | Microsoft Windows 11 Enterprise LTSC 2024 |
| Build | 26100 (24H2 LTSC) |
| ProductType | 1 (Workstation) — runs in **WS2025 PREVIEW MODE** in this script |
| Secure Boot | OFF (toggled off for testing) |
| HVCI | ON |
| BitLocker | OFF (lab use) |

### 2.3 Validation procedure

Windows 11 Enterprise LTSC 2024 shares NT kernel build 26100 with Windows Server 2025, so the script runs in **WS2025 PRE-MIGRATION PREVIEW MODE** (P00 banner declares it explicitly).

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force

# Install phases auto-block on Workstation OS — PrepareVerify only
# Recommended: use -LogFile to keep console colors while capturing the run.
$ts = Get-Date -Format 'yyyyMMdd-HHmmss'
.\Deploy-AMDChipsetDriverOnWindowsServer.ps1  -Action PrepareVerify -CleanWorkRoot `
    -LogFile "C:\Temp\x13gen1-amd-chipset_PrepareVerify_Win11-preview_$ts.log"
.\Deploy-AMDGraphicsDriverOnWindowsServer.ps1 -Action PrepareVerify -CleanWorkRoot `
    -LogFile "C:\Temp\x13gen1-amd-graphics_PrepareVerify_Win11-preview_$ts.log"

# Legacy fallback (Write-Host coloring is stripped from the captured file):
#   .\Deploy-AMDChipsetDriverOnWindowsServer.ps1  -Action PrepareVerify -CleanWorkRoot *>&1 |
#     Tee-Object "C:\Temp\x13gen1-amd-chipset_PrepareVerify_Win11-preview_$ts.log"

# NPU script: NOT APPLICABLE (no NPU on Renoir)
```

### 2.4 Key validation results

#### P00 OS detection (Workstation preview)

```
[+] OS detected: Microsoft Windows 11 Enterprise LTSC (build 26100)
    Profile applied : WS2025 (Windows Server 2025)
    ProductType     : 1  (1=Workstation, 3=Server)

    +-----------------------------------------------------------------+
    | WS2025 PRE-MIGRATION PREVIEW MODE                               |
    | (Windows 11 24H2 and Windows Server 2025 share NT build 26100)  |
    +-----------------------------------------------------------------+
```

Install phases auto-block (override with `-AllowWorkstationInstall`, but discouraged).

#### Chipset script

- **P03 detection**: `Renoir / Zen 2 / Mobile`
- **P03 download**: `amd_chipset_software_8.02.18.557.exe` (same as M75q)
- **P05 inventory**: 67 INFs detected; 32 W11x64 variant INFs selected
- **P06 patching**: 1 INF patched (`AmdMicroPEP.inf`)
- **V06 main upgrade candidates** (compared against Win11 OEM drivers):
  - AMD PSP 10.0 Device: `oem144.inf v5.42.0.0` → `amdpsp.inf v5.43.0.0` (HIGH risk)
  - GPIO / I2C / SMBus / MicroPEP — same version (KEEP)

#### Graphics script

- **P03 detection**: `Renoir / Vega-Polaris Legacy`
- **P03 download**: `whql-amd-software-adrenalin-edition-26.1.1-win11-jan-vega-polaris.exe` (~624 MB)
- **P05 inventory**: 19 INFs detected; `WT64A` + `WT6A_INF` variants selected
- **P06 patching**: 1 INF patched (`u0197843.inf`), mirroring 6 decorations
- **V06 upgrade candidates**:
  - AMD Audio CoProcessor: `v6.0.0.79 → v6.0.1.83` (real version upgrade)
  - AMD Radeon Graphics: `v31.0.21923.11000 → v31.0.21924.61` (real version upgrade)
  - AMD HD Audio Device: `v10.0.1.30 → v10.0.1.30` (date-only newer; the graphics script explicitly displays "same version, but newer date")

#### Soundness checks

- All 21 phases completed (Install phases auto-blocked because the host is Workstation OS)
- All 19 INFs flow through the pipeline
- 19 catalogs + 19 signtool signatures all succeed
- AMD HW detected: AMD Audio CoProcessor, AMD Radeon Graphics, AMD HD Audio Device, AMD GPIO Controller, AMD I2C Controller, AMD Micro PEP, AMD SMBus, AMD PSP 10.0 Device, etc.

### 2.5 Expected delta between Win11 and WS2025 on identical hardware

Comparing Validation Result 1 (M75q + WS2025) and Validation Result 2 (X13 Gen 1 + Win11 24H2): **the script's decision logic is identical between the two OSes because they share kernel build 26100**, but **V06 upgrade candidate counts differ because the existing OEM driver baseline differs**:

| V06 section | M75q (WS2025) | X13 Gen 1 (Win11) |
|---|---|---|
| Detected AMD HW | identical detection logic (HW topology differs by machine) | identical |
| MS-GENERIC count | high (clean WS2025 has bare Server in-box drivers) | lower (Win11 has OEM drivers pre-installed) |
| WILL be replaced count | more (MS generic → AMD vendor swaps are frequent) | fewer (only swap when AMD package is newer than the OEM driver) |
| KEEP (same/newer) count | fewer | more |
| Recommended Install execution | YES (target host) | NO (Workstation OS, auto-blocked) |

In other words, **PrepareVerify on Win11 24H2 functions as pre-migration verification for WS2025**: the patched-INF signatures and catalog structures generated remain valid on WS2025 (same kernel build). The actual install decisions (which devices fall into WILL be replaced) should be re-confirmed on WS2025 after migration.

---

## 3. Validation Result 3 (NPU script) — currently UNVERIFIED

> **🆘 THIS SECTION DOCUMENTS WHAT HAS NOT BEEN VERIFIED.** Do not interpret it as evidence of working behaviour.

### 3.1 What is currently verified for the NPU script

| Verification activity | Status | Evidence |
|---|---|---|
| Static analysis with `psa.py` (latest mainline) with the repository-shipped `.psa.config.json` (see `SPEC.md` §A.11) | ✅ done | 0 errors / 0 warnings / 0 info — see `CHANGELOG.md` for the verified baseline (see §A.11.5) |
| Pre-flight `.psa.config.json` schema validation via `psa.py --config-check` (see `SPEC.md` §A.11.6) | ✅ done | Config reports `issues : 0` against `psa.py` latest mainline |
| Code review of NPU detection logic | ✅ done | `Get-AmdNpuPlatform` is a direct PowerShell port of AMD-published `quicktest.py` |
| Detection on physical NPU machine | ❌ **NOT DONE** | No physical NPU hardware in maintainer's lab as of this writing |
| INF parsing of real NPU driver ZIP | ❌ **NOT DONE** | NPU driver ZIPs (`NPU_RAI*_WHQL.zip`) are EULA-gated; maintainer does not have a verified copy of every RAI version's INF structure |
| `-Action Install` on physical NPU machine | ❌ **NOT DONE** | Same as above |
| Post-install bind to `[C] Self-signed` | ❌ **NOT DONE** | Same as above |
| AMD account auto-download (Tier 2) | ⚠️ **best-effort, unstable** | Implemented from public form structure observation; AMD form changes can break without notice |
| Ryzen AI Software user-mode stack on Server 2025 | ❌ **explicitly unsupported by AMD** | AMD documentation states Win11 24H2 (build >= 22621.3527) only |

> **Note on validation scope**: The validation of this NPU script is fundamentally bottlenecked by access to physical Ryzen AI hardware. Because the script is an experimental tool targeting AMD's consumer-class NPU silicon, no meaningful end-to-end validation can be performed on hardware that lacks the target NPU device. Static analysis and code review are the only verification activities completed; everything that depends on actual device-bind behaviour, INF parsing of real driver ZIPs, or post-install verification remains pending until a physical NPU machine becomes available.

### 3.2 Validation gaps (what should be done before treating the NPU script as production-ready)

1. **Acquire a Ryzen AI hardware test fixture.** Candidates:
   - **ThinkPad T14s Gen 6 AMD** (Ryzen AI 7 PRO 360 / Strix Point) — accessible via Lenovo retail.
   - **ASUS ProArt P16** (Ryzen AI 9 HX 370) — Strix Point with NPU enabled.
   - **HP OmniBook Ultra Flip 14** (Ryzen AI 9 HX 375) — Strix Point.
   - **Mini-PC builds with Ryzen AI Max 300** — limited availability as of 2026.

2. **Run `-Action PrepareVerify` on the fixture** with each of the 4 download tiers:
   - Tier 1: pre-captured `entitlenow.com` URL.
   - Tier 2: `-AmdAccountUser` / `-AmdAccountPassword` with a real AMD account. Confirm or adjust form-parsing regex.
   - Tier 3: probe AMD EULA URL (expected to fall through; document if AMD ever simplifies this).
   - Tier 4: `-OfflineZip` with manually-downloaded ZIPs for RAI 1.5 / 1.6.1 / 1.7 / 1.7.1.

3. **Run `-Action Install` on the fixture** with the recommended workflow:
   - Capture `Get-CimInstance Win32_PnPSignedDriver` before / after.
   - Confirm `[B] Vendor` → `[C] Self-signed` transition for the NPU device.
   - Run `Task Manager → Performance → NPU0` and confirm the device appears.
   - Try `pnputil /enum-drivers` and confirm the patched INF appears under our self-signed cert.

4. **Document the failure modes**:
   - Does Server 2025 ever load the NPU kernel driver successfully? (Per AMD docs, the user-mode stack does not work, but the kernel driver itself is the focus of this script.)
   - Does Cleanup actually remove the driver from the driver store, or does manual `pnputil /delete-driver oemNN.inf /force` remain necessary?
   - What event log entries appear in `CodeIntegrity / Operational` if WDAC blocks anything unexpected?

### 3.3 Recommended invocation patterns and 4-tier evaluation

The 4-tier URL resolution in `Resolve-AmdNpuDriverUrl` (script line 772) controls how P03 obtains the NPU driver ZIP. The behaviour is **not symmetric across all parameter combinations**, so the table below documents the actual outcome of each invocation pattern. Use this when planning runs.

| # | Invocation | Outcome | Path through 4-tier resolver |
|---|---|---|---|
| 1 | `-Action PrepareVerify -CleanWorkRoot -OfflineZip <path>` | ✅ **Recommended for first dry run.** | T4 priority block (line 824) → ZIP copied to workspace → P03 succeeds |
| 2 | `-Action PrepareVerify -CleanWorkRoot -OfflineZip <path> -AssumeIfMissing` | ⚠️ **Pipeline-soundness check only — does NOT validate real NPU behaviour.** | Same as #1 plus default Strix Point profile when no NPU detected |
| 3 | `-Action PrepareVerify -CleanWorkRoot` (no `-OfflineZip`) | ⚠️ **Likely fails on a clean machine.** | T1 skip → T4 priority skip → T2 skip → T3 falls through (HTML form) → T4 auto-scan (script dir, ./cache, workspace, ~/Downloads) → if nothing found, throws |
| 4 | `-Action Install -OfflineZip <path>` | ✅ **Recommended for real-NPU install.** | T4 priority block → I00 prompts for "I AGREE" → I01-I04 |
| 5 | `-Action Install -AmdAccountUser ... -AmdAccountPassword ...` | ⚠️ **Best-effort. AMD form changes can break this without notice.** | T1 skip → T4 priority skip → T2 attempts authenticated download → falls back to T3/T4 on failure |
| 6 | `-Action Install -InstallerUrl <captured-url>` | ✅ Works if the URL is fresh (entitlenow.com URLs expire). | T1 direct download → P03 succeeds |
| 7 | `-Action Install -NpuOverride STX -NpuDriverPackage NPU_RAI1.6.1_314` (no source) | ❌ **Misleading; do not use.** | T1/T2/T3 skip → T4 auto-scan picks up *whatever* `NPU_RAI*_WHQL.zip` is in `~/Downloads` (may not match the override) |

**Why pattern #1 (`PrepareVerify` + `OfflineZip`) is the strongest recommendation**:

- **Deterministic**: the Tier 4 priority block at line 824 short-circuits the resolver immediately. No network calls to AMD, no form-parsing fragility, no race against EULA URL expiry.
- **System-untouched**: `PrepareVerify` runs P00–P09 + V01–V06 only. No certs imported, no WDAC policy deployed, no drivers installed.
- **Reproducible across hosts**: copy the same ZIP to a new machine, get the same P05/P06/V05/V06 output. Critical for CI regression testing.
- **Gives you V05/V06 output**: dry-run install plan and hardware impact analysis are produced even when the host has no NPU device (in which case `-AssumeIfMissing` is needed to bypass detection failure).

**Common pitfall — pattern #7**: switches like `-NpuOverride`, `-NpuDriverPackage`, and `-RyzenAiSoftwareVersion` *modify resolver behaviour but do not provide a download source*. If you specify them without `-OfflineZip` / `-InstallerUrl` / `-AmdAccountUser`, the resolver falls through to Tier 4 auto-scan. Auto-scan picks up whichever `NPU_RAI*_WHQL.zip` it finds first — and that ZIP **may not match the codename or version you tried to override**. The version check happens inside the ZIP's INFs (P05), not against the filename. Always pin the source explicitly.

### 3.4 Pre-flight checklist before running the NPU script anywhere

Even before any of the above gaps are closed, follow this checklist before running the NPU script on **any** host:

- [ ] You have read [§ Risk classification](./README.md#risk-classification-of-the-four-scripts) of the README.
- [ ] You have a Ryzen AI 300 / Ryzen AI Max 300 / Ryzen 7040 / 8040 series CPU (or you accept that detection will fall through to `-AssumeIfMissing` and the run is a pipeline-soundness check only).
- [ ] You have downloaded the appropriate `NPU_RAI*_WHQL.zip` from <https://ryzenai.docs.amd.com/en/latest/inst.html#install-npu-drivers> and placed it next to the script (Tier 4 — recommended).
- [ ] You have read AMD's Ryzen AI EULA at <https://account.amd.com/en/forms/downloads/ryzenai-eula-public-xef.html> and accepted it.
- [ ] You understand that Ryzen AI Software user-mode stack is officially Windows-11-only and **will not give you AI inference on Server 2025**.
- [ ] If running `-Action Install`: you can roll back via `-Action Cleanup` (and you accept that driver-store removal may need manual intervention).
- [ ] If running on a host with BitLocker: you have your recovery key recorded.
- [ ] You will report results to GitHub Issues regardless of success or failure (especially failure — the maintainers need this data to close the validation gap).

### 3.5 Expected NPU script outputs

These are the outputs you should see when the script runs successfully. Deviation indicates a problem.

#### P00 NPU OS-support warning

```
-------------------------------------------------------------------------
 Ryzen AI Software OS support note
-------------------------------------------------------------------------
[!] AMD officially supports Ryzen AI Software ONLY on Windows 11 (build >= 22621.3527).
[!] Windows Server 2025 is NOT in AMD's supported OS matrix.
[!] This script patches the kernel-mode NPU driver to install on Server, but the
[!] user-mode Ryzen AI Software stack (conda env, OGA, Vitis AI EP) will likely
[!] not function on Server 2025 without unofficial workarounds.
```

#### P03 NPU detection (real Strix Point host)

```
[>] Enumerating PCI devices via pnputil /enum-devices /bus PCI /deviceids
[+] CPU              : AMD Ryzen AI 9 HX 370 w/ Radeon 890M
[+] NPU codename     : Strix Point / Strix Halo
[+] NPU short name   : STX
[+] Hardware ID      : PCI\VEN_1022&DEV_17F0&REV_00
[+] Detection source : pnputil
[+] Detected on host : True
[+] Preferred RAI ver: 1.7.1
[+] Recommended drv  : 32.0.203.380
```

#### P03 NPU detection (non-NPU host, with `-AssumeIfMissing`)

```
[>] Enumerating PCI devices via pnputil /enum-devices /bus PCI /deviceids
[!] No AMD NPU detected via pnputil. Using default profile (Strix Point + RAI 1.7.1).
[+] CPU              : (host CPU - no NPU)
[+] NPU codename     : Strix Point (default - no NPU detected)
[+] NPU short name   : STX
[+] Detection source : default-strix-rai1.7.1
[+] Detected on host : False
```

followed by:

```
------------------------------------------------------------------
[!] NPU was NOT detected on the host (proceeding with default profile).
[!] Driver Install (I03) will likely produce 0 device bindings here.
[!] This run is useful for pipeline regression testing only.
------------------------------------------------------------------
```

#### I00 EULA acknowledgement (Install only)

```
+----------------------------------------------------------------+
| AMD RYZEN AI EULA ACCEPTANCE REQUIRED BEFORE INSTALL           |
+----------------------------------------------------------------+
| By proceeding, you confirm:                                    |
| 1. You have accepted the Ryzen AI EULA at:                     |
|    https://account.amd.com/en/forms/downloads/                 |
|    ryzenai-eula-public-xef.html                                |
| 2. You acknowledge Windows Server 2025 is NOT officially       |
|    supported by AMD for Ryzen AI Software (Windows 11 only).   |
| 3. You understand the kernel-mode driver alone does not        |
|    enable AI inference; Ryzen AI SW must be installed manually.|
| 4. You have BitLocker recovery keys recorded if applicable.    |
+----------------------------------------------------------------+

Type "I AGREE" exactly to proceed with install (anything else aborts):
```

#### After Install: Ryzen AI Software guidance banner

```
+================================================================+
| RYZEN AI SOFTWARE (USER-MODE STACK) - INSTALL THIS SEPARATELY |
+================================================================+

This script installed the kernel-mode NPU driver only.
To actually use the NPU for AI inference, install Ryzen AI Software:

  Detected NPU codename : STX
  Recommended RAI ver   : 1.7.1

  PREREQUISITES (per AMD documentation):
    1. Windows 11 build >= 22621.3527 (NOT supported on Server 2025!)
    2. Visual Studio 2022 (with Desktop Development with C++)
    3. cmake >= 3.26
    4. Miniforge (Python distribution); add condabin/Scripts to PATH

  INSTALLATION STEPS:
    1. Download Ryzen AI installer:
       https://account.amd.com/en/forms/downloads/xef.html
       Filename: ryzen-ai-lt-1.7.1.exe
    2. Launch the EXE installer (run as Administrator)...
    3. Verify the install (Miniforge Prompt):
         conda activate ryzen-ai-1.7.1
         cd %RYZEN_AI_INSTALLATION_PATH%\quicktest
         python quicktest.py
```

### 3.6 Tier 2 (AMD account auth flow) verification result — 2026-05-10

The `Invoke-AmdAccountAuthentication` function in `Deploy-AMDNpuDriverOnWindowsServer.ps1` was reviewed against the actual AMD account portal on **2026-05-10** to determine whether the implemented HTTP form POST flow can succeed against the current `account.amd.com` back-end. The verification used only public sources (no real AMD account credentials were used).

#### 3.6.1 Method

| Step | What was checked | How |
|---|---|---|
| 1 | `account.amd.com` rendering model | Web fetch of related AMD portals (`docs.amd.com/auth/login`, `pensandosupport.amd.com`, `fsdz.amd.com`) |
| 2 | EULA URL pattern in current AMD docs | GitHub `amd/ryzen-ai-documentation/blob/main/docs/inst.rst` (latest commit) |
| 3 | Driver-version naming convention | Cross-check between RAI 1.5 / 1.6.1 / 1.7 / 1.7.1 documentation pages on `ryzenai.docs.amd.com` |
| 4 | End-user behavior of the EULA flow | GitHub `amd/RyzenAI-SW#249`, `#328`, and cnx-software.com end-user blog post (Feb 2024) |
| 5 | Existence of public PowerShell/Python automation | Web search for `account.amd.com` automation, AMD account download scripting |

#### 3.6.2 Findings

| # | Finding | Severity | Evidence |
|---|---|---|---|
| F1 | **`account.amd.com` is a JavaScript-driven SPA.** Related AMD portals return `"JavaScript is required"` or `"Loading application"` HTML stubs on direct fetch. | High | Direct probe of `docs.amd.com/auth/login` and `fsdz.amd.com/adfs/ls/...` |
| F2 | **Login forms are not present in the initial HTML payload.** CSRF tokens, form actions, and fields are likely injected by JavaScript at runtime. | High | F1 implies the login form is rendered client-side |
| F3 | **EULA acceptance is interactive.** End users report that they "could not avoid signing the Beta Software EULA" — implying a JS-driven multi-step modal, not a single hidden form POST. | Medium | cnx-software.com testimonial (2024); GitHub #249 (2025) |
| F4 | **Two distinct EULA URL patterns exist** in AMD's documentation. Original code assumed only one. | Medium | `ryzenai-eula-public-xef.html` for NPU drivers vs `xef.html` for RAI Software EXE / NuGet |
| F5 | **The default driver/RAI mapping `1.7.1 → 32.0.203.380` was not real.** AMD's RAI 1.7.1 documentation reuses the 1.6.1 driver (`32.0.203.314`) and there is no `NPU_RAI1.7.1_380_WHQL.zip` publicly listed. The script's own comment admitted this was a "placeholder build until AMD publishes". | Medium | Cross-check of `ryzenai.docs.amd.com/en/latest/inst.html` and `github.com/amd/ryzen-ai-documentation/blob/main/docs/inst.rst` |
| F6 | **No public automation script for AMD account login was found.** Web search returned zero PowerShell/Python implementations that successfully drive the form. | Low | Negative search result; informational |

#### 3.6.3 Conclusion

The `Invoke-AmdAccountAuthentication` function as implemented (HTTP form POST against `https://account.amd.com/en/forms/auth/login.html`) **is highly unlikely to succeed against the current AMD portal**. The portal architecture does not match the assumptions encoded in the function (server-rendered HTML form with hidden CSRF token, simple POST credentials → redirect to authenticated EULA → simple POST EULA accept → redirect to entitlenow.com).

This conclusion was reached without making authenticated requests against AMD's servers — it follows from publicly visible architectural evidence (F1–F3), driver-version inconsistency (F5), and absence of any working public implementation (F6).

#### 3.6.4 Remediation applied to the script

| Change | Description | Location |
|---|---|---|
| C1 | **Tier 2 disabled by default.** The function now returns `$null` immediately unless `-ForceAmdAccountAuth` is passed. | `Invoke-AmdAccountAuthentication` (~line 1170) |
| C2 | **`VERIFIED 2026-05-10` banner** added with explicit "highly unlikely to succeed" warning. | `Invoke-AmdAccountAuthentication` head |
| C3 | **`-ForceAmdAccountAuth` switch** added to `param()` block. Operators who believe AMD has changed their portal can opt in to test. | Top-level `param()` |
| C4 | **Versioning fully separated.** Parameter `-PreferredRyzenAiVersion` (mixed driver + software in one knob) was replaced by two independent parameters: `-NpuDriverPackage` (default `latest` = `NPU_RAI1.6.1_314`) and `-RyzenAiSoftwareVersion` (default `latest` = `1.7.1`). Filename generation now produces `NPU_RAI1.6.1_314_WHQL.zip` matching what AMD actually publishes. Compatibility between A and B is evaluated as a separate axis. | `[string]$NpuDriverPackage = 'latest'`; `[string]$RyzenAiSoftwareVersion = 'latest'`; new functions `Get-NpuDriverPackageInfo`, `Get-LatestRyzenAiSoftwareInfo`, `Test-NpuDriverRaiCompatibility` |
| C5 | **`Get-RecommendedNpuDriverBuild` mapping corrected.** RAI 1.7 / 1.7.1 entries now both return `32.0.203.314` (the real published driver) instead of fictional `329` / `380` builds. Cross-references to AMD docs are added in the function header. | `Get-RecommendedNpuDriverBuild` |
| C6 | **All header `.EXAMPLE` filenames** updated from `NPU_RAI1.7.1_380_WHQL.zip` (fictional) to `NPU_RAI1.6.1_314_WHQL.zip` (verified). | Script header lines ~93, 99, 110, 124, 132 |
| C7 | **Default-Strix profile label** changed from `default-strix-rai1.7.1` to `default-strix-rai1.6.1`. P03 banner reflects the verified driver build. | `Get-AmdNpuPlatform` `$AssumeIfMissing` branch |

#### 3.6.5 What `-ForceAmdAccountAuth` does

When set, the existing form-based POST sequence is attempted unchanged:

```powershell
.\Deploy-AMDNpuDriverOnWindowsServer.ps1 `
    -Action Install `
    -ForceAmdAccountAuth `
    -AmdAccountUser 'you@example.com' `
    -AmdAccountPassword (Read-Host 'AMD password' -AsSecureString)
```

Expected result on the current AMD portal: **failure** at one of the following points (most likely Step 2 or Step 3):

- Step 1 GET EULA page → fetch likely succeeds but no CSRF token in HTML
- Step 2 POST credentials → likely fails (no form actually exists at the documented URL)
- Step 3 GET authenticated EULA → likely succeeds but no acceptance form action found
- Step 4 POST EULA acceptance → likely fails (no form actually exists)

If by some chance AMD has reverted to a server-rendered form, the existing fallback code path handles success; no further changes needed in that case.

#### 3.6.6 Future re-verification

Re-run this verification when:

- AMD announces a new Ryzen AI release (≥ 1.7.2 or 1.8) — driver mapping table may need updates
- A user reports that `-ForceAmdAccountAuth` now succeeds — Tier 2 can be re-enabled by default
- A new EULA URL pattern appears in AMD documentation (a third path beyond the two known)

The verification re-run procedure is the same as in 4.6.1: fetch public AMD pages, cross-check EULA URL patterns in `amd/ryzen-ai-documentation` GitHub repository, and check for end-user reports of successful automation.

### 3.7 Versioning-axis separation verification — 2026-05-10

The NPU script's version-handling logic was redesigned on **2026-05-10** to fully separate the **NPU kernel-mode driver** versioning system from the **Ryzen AI Software (user-mode stack)** versioning system, per AMD's authoritative documentation at <https://ryzenai.docs.amd.com/en/latest/inst.html> (Last updated 2026-04-19).

#### 3.7.1 The two independent versioning systems

AMD's installation guide treats NPU drivers and Ryzen AI Software as fully decoupled artefacts:

| Aspect | NPU kernel-mode driver (axis A) | Ryzen AI Software (axis B) |
|---|---|---|
| What it is | Windows kernel-mode driver bundled in `npu_sw_installer.exe`, providing PCI device binding and firmware loading | User-mode runtime: Python conda environment, ONNX Runtime VitisAI EP, OnnxRuntime GenAI (OGA), AMD Quark quantizer, xrt-smi tool |
| Distribution | EULA-gated ZIP at `account.amd.com/en/forms/downloads/ryzenai-eula-public-xef.html?filename=NPU_RAI*_WHQL.zip` | EULA-gated EXE at `account.amd.com/en/forms/downloads/xef.html?filename=ryzen-ai-lt-*.exe` (note the different EULA URL pattern) |
| Currently published versions (per AMD docs 2026-04-19) | `NPU_RAI1.5_280_WHQL.zip` (driver 32.0.203.280) and `NPU_RAI1.6.1_314_WHQL.zip` (driver 32.0.203.314) | `1.7.1` (latest), with installer `ryzen-ai-lt-1.7.1.exe` and NuGet `1.7.1_nuget_signed.zip` |
| Update cadence | Slow — only when a new firmware/driver pair is released. Backward-compatible with prior RAI Software versions in the supported range. | Frequent — ships new model support, performance improvements, and bug fixes. **AMD recommends always using the latest** for end-user workloads. |
| Operator default in this script | `latest` → `NPU_RAI1.6.1_314` (the newer of the two documented packages) | `latest` → `1.7.1` (auto-resolves to whatever this script currently knows as the latest) |
| Naming inside ZIP filenames | The `RAI1.5` / `RAI1.6.1` token in `NPU_RAI*_WHQL.zip` is a **historical naming artefact** — both ZIPs work with current Ryzen AI Software 1.7.1 | Versioning is its own scheme: `1.5` → `1.6.1` → `1.7` → `1.7.1` |

The crucial point: the `1.6.1` in `NPU_RAI1.6.1_314_WHQL.zip` is **NOT** the Ryzen AI Software version. It is a release-channel label inherited from the original RAI 1.6.1 release window. The same driver ZIP is the recommended driver for RAI Software 1.7.1.

#### 3.7.2 Compatibility evaluation as a separate axis

AMD documents driver-software compatibility in the Ryzen AI Software installation guide. As of RAI 1.7.1 (the current latest):

> "Download and Install the NPU driver version: 32.0.203.280 or newer using the following links" — both `NPU_RAI1.5_280` and `NPU_RAI1.6.1_314` are listed as valid options.

This produces the following compatibility matrix (axis C — derived from axes A + B):

|  | RAI 1.5 | RAI 1.6.1 | RAI 1.7 | RAI 1.7.1 |
|---|---|---|---|---|
| Driver 32.0.203.280 (`NPU_RAI1.5_280`) | ✅ | ✅ | ✅ | ✅ |
| Driver 32.0.203.314 (`NPU_RAI1.6.1_314`) | ✅ | ✅ | ✅ | ✅ |

The minimum driver requirement (`32.0.203.280`) is consistent across all supported RAI Software versions per AMD's documentation. The script's `Test-NpuDriverRaiCompatibility` function encodes this matrix and emits `OK` or `MISMATCH` at P03.

#### 3.7.3 Code-level changes

| Layer | Before | After |
|---|---|---|
| **Operator parameters** | Single `-PreferredRyzenAiVersion <ver>` (mixed driver + software in one knob) | Two independent parameters: `-NpuDriverPackage <NPU_RAI1.5_280 \| NPU_RAI1.6.1_314 \| latest>` and `-RyzenAiSoftwareVersion <1.5 \| 1.6.1 \| 1.7 \| 1.7.1 \| latest>`. Both default to `latest`. |
| **Catalog functions** | `Get-RecommendedNpuDriverBuild $RaiVersion → $build` (incorrect coupling) and `Get-NpuZipFilename $RaiVersion $build → $filename` (string concatenation that produced fictional filenames) | Three independent functions: `Get-NpuDriverPackageInfo` (axis A: returns full package metadata for the documented ZIPs), `Get-LatestRyzenAiSoftwareInfo` (axis B: returns RAI Software metadata with `IsLatest` flag), `Test-NpuDriverRaiCompatibility` (axis C: evaluates the matrix above with `[version]` comparison) |
| **Detected-platform fields** | `RecommendedRaiVer`, `RecommendedDriver` (2 fields, ambiguously coupled) | `NpuDriverPackage`, `NpuDriverBuild`, `NpuDriverZipName` (axis A), `RyzenAiSoftwareVersion`, `RyzenAiSoftwareInstaller` (axis B), `DriverSoftwareCompatible`, `DriverSoftwareCompatNote` (axis C) — 7 fields with explicit axis attribution |
| **P03 banner output** | Single block listing "Preferred RAI ver" and "Recommended drv" | Three labelled blocks: "NPU kernel-mode driver (independent versioning axis)", "Ryzen AI Software (independent versioning axis - always latest unless pinned)", "Driver <-> RAI Software compatibility (separate evaluation axis)" with `OK`/`MISMATCH` status |
| **Post-install guidance (I04)** | Hardcoded fallback to `1.7.1` if RAI version was missing | Reads `RyzenAiSoftwareInstaller` field directly; falls back to `ryzen-ai-lt-1.7.1.exe` only if the field is empty. Explicitly states "NPU driver and Ryzen AI Software are versioned INDEPENDENTLY. Always use the LATEST Ryzen AI Software for end-user workloads." |

#### 3.7.4 Future maintenance

When AMD publishes a new Ryzen AI release, update the script in two places:

1. **If a new NPU driver ZIP is published** (e.g. `NPU_RAI1.8_400_WHQL.zip`): add an entry to the `Get-NpuDriverPackageInfo` catalog and the `-NpuDriverPackage` `ValidateSet`. If the new driver introduces a different minimum-required driver build for current RAI Software, update `Test-NpuDriverRaiCompatibility`.
2. **If a new Ryzen AI Software version is released** (e.g. `1.8.0`): add an entry to the `Get-LatestRyzenAiSoftwareInfo` catalog, update `$latestVersion` to the new version, and add the new value to the `-RyzenAiSoftwareVersion` `ValidateSet`. Cross-check the AMD release notes for any new minimum driver requirement and update `$minimumPerRai` in `Test-NpuDriverRaiCompatibility` accordingly.

The two updates are independent — adding driver support does not require touching software metadata, and vice versa. This is the central design property the redesign achieves.

---

## 4. Validation Result 4 (BthPan script) — planned

> **Status update (2026-08-07)**: the prep pipeline (`PrepareVerify`) has since been field-executed on a WS2016 host without a Bluetooth controller — see [§20](#20-validation-scenario-20-2026-08-07-ws2016--ryzen-5-pro-4650u-field-runs-chipset--graphics--bthpan-prepareverify). The planned AX210 device-bind sequence below remains the outstanding validation target and is kept as originally written.

> The BthPan script is brand-new; physical validation has not yet been performed. This section documents the planned first physical-validation run.

### 4.1 Planned target hardware

| Item | Value |
|---|---|
| Model | Lenovo ThinkPad (specific SKU TBD; any model with bound Intel AX210) |
| Bluetooth host controller | Intel AX210 (`USB\VID_8087&PID_0032`, also seen as `USB\VID_8087&PID_0033`) |
| Host controller driver source | Intel published `Bluetooth_22.x.x.x_64UWD-RetailWHCK.zip` (vendor-signed; loads on Server with no patching) |
| OS | Windows Server 2025 (build 26100.32860 — the first WS2025 GA build) |
| ProductType | 3 (Server) |
| Disk | NVMe (free space >5 GB for workspace; BthPan workspace is small ~10 MB) |

### 4.2 Pre-validation state (expected on a fresh WS2025 install)

After installing the Intel AX210 host controller driver via its vendor installer, `BTH\MS_BTHPAN` should appear in Device Manager. The expected starting state is **one of**:

- **Unknown Device (code 28)**: `BTH\MS_BTHPAN` enumerated but no driver bound. This is the cleanest case for I04 to verify true resolution against.
- **Phantom OK**: `BTH\MS_BTHPAN` showing Status=OK, with `DriverInfPath=bth.inf`, `Class=Bluetooth`, `Service=(empty)`. This is the trickier case the script is specifically designed to detect.

V06 will diagnose and print the actual starting classification.

### 4.3 Planned test commands

```powershell
# Stage 0: confirm host controller is bound
Get-PnpDevice -Class Bluetooth | Select-Object FriendlyName, Status, InstanceId

# Stage 1: diagnosis only (no system change)
.\Deploy-MSBthPanInboxOnWindowsServer.ps1 -Action PrepareVerify -CleanWorkRoot

# Read V05 + V06 output carefully. Confirm:
#   - V05 reports the device count and classification
#   - V06 risk class is LOW (BthPan default; only MEDIUM if Phantom OK detected)
#   - Patched bthpan.inf is at C:\Temp\Workspace_Microsoft-BthPan\patched\bthpan\bthpan.inf
#   - inf2cat catalog targets Server2025_X64 + ServerFE_X64 + ServerRS5_X64 + Server2016_X64

# Stage 2: full install
.\Deploy-MSBthPanInboxOnWindowsServer.ps1 -Action Install

# Expected I03 output:
#   pnputil /add-driver bthpan.inf /install   -> exit=0 (or 3010 if reboot needed)
#   pnputil /scan-devices                     -> exit=0

# Expected I04 output:
#   [OK]   TRUE resolution: oem*.inf bound, Class=Net, Service=BthPan
#   *** TRUE RESOLUTION ACHIEVED ***

# If I04 reports `*** TRUE RESOLUTION NOT YET ACHIEVED ***`:
#   Reboot, then re-run the same command. The script's resume-after-reboot
#   logic should detect the now-correct binding and confirm true resolution.
```

### 4.4 Verification commands to run after install

```powershell
# Runtime artifacts
Test-Path C:\Windows\System32\drivers\bthpan.sys           # expected: True
Get-Service BthPan                                          # expected: present, Status=Running or Stopped
(Get-Service BthPan).StartType                              # expected: Manual (default)

# Device-level binding
$dev = Get-PnpDevice -InstanceId 'BTH\MS_BTHPAN*'
$dev | Get-PnpDeviceProperty -KeyName DEVPKEY_Device_DriverInfPath, DEVPKEY_Device_Class, DEVPKEY_Device_Service
# Expected:
#   DriverInfPath = oem<N>.inf  (e.g. oem17.inf)
#   Class         = Net
#   Service       = BthPan

# NetAdapter visibility
Get-NetAdapter | Where-Object InterfaceDescription -Match 'Bluetooth.*Personal Area Network'
# Expected: one NetAdapter present, MediaType=Bluetooth

# Self-signed catalog still trusted
signtool verify /pa /v C:\Temp\Workspace_Microsoft-BthPan\patched\bthpan\bthpan.cat
# Expected: "Successfully verified"

# WDAC supplemental policy active
CiTool --list-policies --json | ConvertFrom-Json |
    Select-Object -ExpandProperty Policies |
    Where-Object PolicyID -eq '{A6E72D4F-3B98-4C5A-9E1D-7F8B2A4C6E5D}'
# Expected: one Policy returned, IsActive=True
```

### 4.5 Pass/Fail criteria

The validation run is considered PASS only if **all** of the following hold:

1. P03 locates the DriverStore source without errors (`bthpan.inf_amd64_*` directory exists)
2. P06 generates a patched bthpan.inf with at least one server decoration (`ServerDecCount >= 1`)
3. P08 generates a signed catalog targeting all four Server SKUs
4. I01 imports the cert into LocalMachine\Root + LocalMachine\TrustedPublisher without error
5. I02 deploys the WDAC supplemental policy with the BthPan-specific GUID `A6E72D4F-…`
6. I03 returns exit 0 (or 3010 with subsequent reboot)
7. I04 reports `*** TRUE RESOLUTION ACHIEVED ***`
8. Post-install verification commands in §4.4 all return their expected values

### 4.6 Strategy A vs Strategy B test plan

Once §4.5 PASS is achieved with the default Strategy A, the planned regression test sequence is:

1. **Strategy B run** — `-DecorationStrategy B -CleanWorkRoot`. Confirm that the patched INF gains four additional `NTamd64.10.0...XXXXX` entries in `[Manufacturer]` and four corresponding mirrored InstallSection blocks. Confirm the same `*** TRUE RESOLUTION ACHIEVED ***` outcome.
2. **Cleanup test** — `-Action Cleanup`. Confirm the workspace is removed, WDAC supplemental policy is uninstalled, and re-running V06 reports the system has returned to its pre-install state (Phantom OK or Unknown Device).
3. **Resume-after-reboot test** — simulate the I03 reboot scenario by running `-Action Install` on a Phantom OK host where PnP does not immediately rebind. After reboot, re-run `-Action Install` and confirm the resume-after-reboot logic correctly detects the now-true-resolution state and reports cached/skip for I01/I02/I03 + still runs I04 for the verdict.

### 4.7 Known unknowns to be resolved by this validation

- How reliably does `pnputil /scan-devices` cause an immediate rebind from `bth.inf` (Phantom proxy) to the patched `oem*.inf`, vs requiring a reboot?
- Are there any DEVPKEY values that differ between Strategy A and Strategy B-installed devices? (Expected: no — both should produce identical Class/Service/DriverInfPath, only the PnP ranking score differs.)
- Does Strategy B's per-build decoration actually improve PnP ranking over Strategy A, or is it functionally indistinguishable?

---

## 5. Summary of validation results

### 5.1 Per-environment matrix

| Item | M75q Tiny Gen 2 | X13 Gen 1 AMD | **Real NPU machine** |
|---|---|---|---|
| Instance / model | ThinkCentre physical | ThinkPad physical | **TBD** |
| OS | WS2025 | Win11 LTSC 2024 | TBD |
| ProductType | 3 | 1 (PREVIEW MODE) | TBD |
| CPU | Ryzen 7 PRO 5750GE (Cezanne) | Ryzen 5 PRO 4650U (Renoir) | Ryzen AI 300 / 7040 / 8040 |
| Has NPU | no | no | **yes** |
| Chipset INFs processed | 32/32 + 3 V06 upgrades | 32/32 + 1 V06 upgrade | n/a (out of scope for NPU script) |
| Graphics INFs processed | 19/19 + 3 V06 upgrades | 19/19 + 3 V06 upgrades | n/a (out of scope for NPU script) |
| NPU script PrepareVerify | n/a (no NPU device) | n/a (no NPU device) | **PENDING** |
| NPU script Install | n/a | n/a (auto-block) | **PENDING** |
| Validation purpose | Pre-production rehearsal (chipset+graphics) | WS2025 pre-migration check | **NPU end-to-end validation** |

### 5.2 Recommended validation patterns

| Scenario | Recommended environment |
|---|---|
| "Real driver install validation" (chipset/graphics) | M75q Gen 2 physical (production target) |
| "Win11 → WS2025 pre-migration evaluation" (chipset/graphics) | X13 Gen 1 physical |
| **"NPU end-to-end validation"** | **Ryzen AI 300 / 7040 / 8040 series host (NOT YET IN MAINTAINER'S LAB — PRs welcome)** |

> **Why no non-AMD-consumer-hardware testing is documented**: This pipeline is an experimental tool for AMD's consumer Ryzen / Radeon / NPU silicon. Validation outcomes are by definition dependent on physical access to those devices. Running the pipeline on server-class EPYC, ARM, Intel, or virtual hosts cannot exercise the device-bind logic (V06), the actual driver upgrade decisions, or the post-install verification path (I04). The maintainers have concluded that "pipeline-soundness only" testing on non-target hardware adds little value relative to the cost of maintaining such infrastructure, and have therefore restricted validation to physical AMD consumer hardware.

---

## 6. Discovered bugs and fix history

The complete per-bug discovery-and-fix history is consolidated in
[`CHANGELOG.md`](./CHANGELOG.md), under "Discovered bugs and fix history
(validation-discovered)". That table maps each validation-discovered bug
to the script revision where it was found and the revision where it was
fixed, with cross-references to the relevant SPEC.md Part D section for
root-cause analysis.

For full validation logs and the corresponding fix commits, see
<https://github.com/usui-tk/Deploy-Drivers-For-WindowsServer/commits/main>.

---

## 7. UEFI Secure Boot baseline validation checklist

This is the per-script validation checklist for the cross-script UEFI Secure Boot baseline feature. All three sister scripts share the same six core functions, so the expected output is uniform across them. Validate on at least one Windows Server 2025 host with KB5089549-equivalent updates installed.

### Per-phase expected output

| Phase | Expected | Actual on test host |
|---|---|---|
| P00 | One-line compact: `Secure Boot baseline: enabled=true UEFI-CA-2023=NotStarted health=Warning [MS-sample=ok]` (values vary by host state) | ✅ |
| P05 | New file `<WorkRoot>\inf_inventory_report.txt` exists and ends with a "UEFI Secure Boot Baseline" appendix block (chipset / graphics: as section after the INF inventory; NPU: at end after the inline inventory) | ✅ |
| V05 | New section: `[Dry-Run UEFI Baseline]` heading followed by one-line compact readout. If `Health` is `Warning` or `Critical`, a yellow advisory line follows | ✅ |
| V06 | New numbered section: "4. UEFI Secure Boot Baseline" (chipset / graphics) or "Section 5: UEFI Secure Boot Baseline" (NPU). Multi-line breakdown showing embedded inventory + MS sample script results (BucketId / Confidence / EventNNNN counts) | ✅ |
| I02 | New pre-check block: `--- UEFI Secure Boot baseline pre-check ---` followed by compact readout and advisory. Never blocks. | (Install phase — run separately) |

### Workspace artefact checklist

| Artefact | Expected location | Purpose |
|---|---|---|
| Raw stdout dump | `<WorkRoot>\secureboot_ms_sample\detect_stdout.log` | Forensics when MS sample script behaves unexpectedly |
| Extracted JSON | `<WorkRoot>\secureboot_ms_sample\detect_stdout_extracted.json` | Parsed `Hostname`, `UEFICA2023Status`, `BucketId`, `Confidence`, `Event1801..1803` |
| Inventory report appendix | `<WorkRoot>\inf_inventory_report.txt` | Persisted snapshot for change-management documentation |

Notes:
- The MS sample script is delivered by KB5089549 (Win 11), KB5087544 / KB5088863 (Win 10), or the WS2025 equivalent (starting 2026-05-12). On unpatched hosts, `[MS-sample=absent]` is expected instead of `[MS-sample=ok]`.
- The diagnostic files survive across runs unless `-CleanWorkRoot` is passed.

### Health-class assertions

| Host state | Expected `health=` value |
|---|---|
| Secure Boot ON, `UEFICA2023Status = Updated` (KB rollout complete) | `Healthy` |
| Secure Boot ON, `UEFICA2023Status = NotStarted / Started / Pending` | `Warning` |
| Secure Boot OFF | `Critical` |
| `UEFICA2023Error` non-zero | `Critical` |
| Secure Boot status unreadable (some firmware quirks) | `Unknown` |

### Cross-script consistency check

Run all four scripts in PrepareVerify mode on the same host with `-CleanWorkRoot`. The captured `BucketId`, `Confidence`, and event counts in V06 should be **identical** across all four scripts (the MS sample script returns deterministic results for the same host state).

---


## 8. AMD Chipset Software 8.x extraction diagnostic format

This section documents the expected diagnostic output and the
validation procedure for AMD's two-layer Chipset Software 8.x
(8.02.18.557 and later) extraction path. The extraction strategy and
its historical evolution are described in
[SPEC §D.12](./SPEC.md#d12-installshield-sfx-extraction-for-amd-8x-installers-chipset);
the revision in which this strategy was introduced is logged in
[CHANGELOG.md](./CHANGELOG.md).

### 8.1 Why a new strategy was needed

AMD Chipset Software 8.x ships as a two-layer wrapper:

1. **Outer layer**: NSIS self-extracting EXE (7-Zip can extract this).
2. **Inner layer**: InstallShield SFX in `ISSetupStream` format (7-Zip CANNOT extract; only InstallShield's own `/a` admin install can).

Earlier revisions detected the 7-Zip failure on the inner layer and fell back to launching the installer and harvesting from `C:\AMD\`, which is fragile because AMD aggressively cleans up that directory. The current pipeline inserts a dedicated InstallShield-aware strategy between the old 7-Zip strategy and the launch-watch fallback.

See `SPEC.md` §B.1 "AMD 8.x installer architecture" for the full architecture.

### 8.2 Expected diagnostic output when Strategy 2 succeeds

When the installer is AMD 8.x, P04 console output should look approximately like the following (truncated for readability):

```
[*] Phase 04 :  P04 ExtractInstaller   (Build group)
[*] Extracting installer (multiple strategies will be attempted)
    Strategy 1/3: 7-Zip auto-detect
[!] 7-Zip auto-detect produced no usable payload (exit 0) - trying next strategy
    Strategy 2/3: InstallShield /a admin install (AMD 8.x+ chain)
      Step 1/3: 7-Zip outer NSIS shell...
      Inner SFX  : C:\Temp\Workspace_AMD-Chipset\is-stage-nsis\AMD_Chipset_Drivers.exe (75.3 MB)
      Step 2/3: InstallShield /a admin install...
      Unpacked   : 36 MSI files (InstallShield exit 0)
      Step 3/3: msiexec /a on 36 sub-MSI(s)...
      msiexec /a : 35 succeeded, 1 failed
      INF total  : 96
      [PREFERRED] W11x64    :  32 INF(s)
      [ skip    ] WTx64     :  32 INF(s)
      [ skip    ] WTx86     :  32 INF(s)
[+]    Extracted via InstallShield admin install chain
[+] Extracted to: C:\Temp\Workspace_AMD-Chipset\extract
```

### 8.3 Validation checklist

When the new path runs successfully, all of these should hold:

| Check | Expected value | How to verify |
| --- | --- | --- |
| InstallShield exit code | `0` (best) or `1` (acceptable if MSI count is correct) | Console line `Unpacked   : NN MSI files (InstallShield exit X)` |
| MSI count | `>= 36` (1 parent + 35 sub-MSIs for 8.02.18.557; future versions may differ) | Same console line |
| msiexec /a success rate | `>= 30` of `36` | Console line `msiexec /a : NN succeeded, M failed` |
| INF total | `>= 80` (varies with version; usually 96 in 8.02.18.557) | Console line `INF total  : NN` |
| PREFERRED variant has non-zero INFs | `[PREFERRED] <variant> : >= 25 INF(s)` | Console line; **this is the critical signal** |
| PREFERRED variant matches host OS | `W11x64` on WS2022/WS2025; `WTx64` on WS2016/WS2019 | Cross-check `$Ctx.Os` from console banner |

### 8.4 Troubleshooting

If the PREFERRED variant shows `0 INF(s)` despite the extraction succeeding, the most likely causes are:

1. **InstallShield /a failed silently**: Check `C:\Temp\Workspace_AMD-Chipset\installshield-admin.log` for MSI errors during the admin install. Look for `Action ended ...` lines with non-zero return values.

2. **msiexec /a failed for the OS-variant sub-MSIs**: Check `C:\Temp\Workspace_AMD-Chipset\msiexec-admin-*.log` for the specific failing sub-MSIs. Each sub-MSI has its own log named after the MSI filename.

3. **AMD changed the directory layout in a future version**: If you are running against a Chipset Software version newer than 8.02.18.557 and the `Binaries\<DriverName>\<OS>\` structure changed, the `Get-AmdSourceVariant` classifier (script line ~5003) may need updating. File a GitHub issue with the directory tree under `C:\Temp\Workspace_AMD-Chipset\extract\`.

### 8.5 Fallback behaviour

If Strategy 2 fails for any reason (caught by the `try { ... } catch` block in `Expand-AmdInstaller`), the script falls through to Strategy 3/3 (launch + watch), preserving the legacy behaviour from earlier revisions. The console output in that case will be:

```
[!] InstallShield /a strategy failed: <error message>
    Strategy 3/3: launch installer and harvest from C:\AMD\
```

This is the legacy fallback path used by earlier revisions and should be considered a regression fallback only.

---

## 9. Regression scenarios: CiTool / UTF-8 / pnputil

These regression scenarios validate the three operational fixes for
the CiTool interactive-prompt, ja-JP UTF-8 console encoding, and the
pnputil exit=259 reclassification (root causes in SPEC §D.5 / §D.16 /
§D.17; release information in [CHANGELOG.md](./CHANGELOG.md)). All
three can be exercised on the same WS2025 install used for §1
(M75q Tiny Gen 2) without re-imaging.

### 9.1 CiTool ENTER-prompt hang (SPEC §D.16)

**Pre-fix symptom**: I02 stalls ~60-75 s between the two log lines below; pressing ENTER in the active console resumes the script:

```
[*] Converting XML to .cip binary and deploying to active CI policies...
[+] Deployed: ...
```

**Regression test**: After running `-Action Install -OnlyPhases I02` with the new revision:

| Observation | Pre-fix | Post-fix |
|---|---|---|
| Wall-clock elapsed for I02 | 60-75 s with ENTER input ~mid-phase | < 10 s end-to-end, no input required |
| Stdin requirement | Operator must press ENTER once per CiTool invocation (I02 + Cleanup) | No stdin interaction |
| CiTool stdout in log | `処理は成功しました\n続行するには、Enter キーを押してください` (literal) OR mojibake under cp932 | Clean JSON envelope, no "Press Enter" line |

**Pass criterion**: I02 completes without any stdin interaction; the operator can walk away from the console.

**Verification commands (operator can run in any elevated PS console)**:

```powershell
# This is a SAFE no-input test: CiTool --list-policies --json prints JSON and exits
# WITHOUT the "Press Enter to Exit" prompt. Without --json, it prints the prompt
# and blocks on stdin.
& CiTool.exe --list-policies --json | ConvertFrom-Json | Select-Object -First 3
```

If this returns control to the prompt immediately, the `--json` mechanism is functioning on this host.

### 9.2 Console UTF-8 enforcement (SPEC §D.5 / §D.16)

**Pre-fix symptom**: I02 log line reads:

```
CiTool: 蜃ｦ逅・・謌仙粥縺励∪縺励◆
```

(The UTF-8 byte sequence of `処理が成功しました` decoded as cp932.)

**Regression test**: With the fixed revision, the same line reads:

```
CiTool: 処理は成功しました
```

OR (when the CiTool `--json` parse extracts the canonical OperationResult):

```
CiTool: Success
```

**Pass criterion**: No CJK mojibake in any CiTool, signtool, or pnputil stdout captured in the run log.

**Verification commands**:

```powershell
# (a) Confirm the three encodings are UTF-8 after P00 has run.
# Run AFTER any phase of the script has executed.
[Console]::OutputEncoding.WebName   # expected: utf-8
[Console]::InputEncoding.WebName    # expected: utf-8
$OutputEncoding.WebName             # expected: utf-8

# (b) Confirm CiTool's ja-JP stdout decodes correctly.
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$stdout = & CiTool.exe --list-policies --json 2>&1 | Out-String
$stdout | Select-String '"OperationResult"' -CaseSensitive
# Expected: a line like  "OperationResult": "Success"
# NOT mojibake.
```

### 9.3 pnputil exit=259 reclassification (SPEC §D.17)

**Pre-fix symptom (chipset)**: On a clean WS2025 install, I03 final summary reports:

```
Driver install: 52 ok (2 need reboot) / 3 failed / 0 skipped (current newer)
```

but I04 PostInstallVerification immediately reports `FAILED: 0`. The three "failed" cases were duplicate-source INFs (`SMBUSamd.inf`, `AMDInterface.inf`, `AmdMicroPEP.inf`) where the second invocation returned exit=259 because the driver package was already in the store.

**Regression test**: With the fixed revision, the same I03 run reports:

```
Driver install: 52 ok (2 need reboot, 3 no-op) / 0 failed / 0 skipped (current newer)
```

And the I03 per-INF lines previously rendered as `[!]   exit=259 (see ...)` now render as `[~]   no-op (driver store already up-to-date)`.

**Pass criterion**:
1. I03 failure count is 0 on a clean install (modulo any genuine pnputil errors).
2. I04 `FAILED` count matches I03 `failed` count (both should be 0 or both should be the same non-zero number).
3. Devices that earlier showed under both "I03: 3 failed" AND "I04: REBOOT_NEEDED" now show only under "I04: REBOOT_NEEDED" with the corresponding I03 entries marked `no-op`.

**Verification command (post-install state inspection)**:

```powershell
# Compare I03 install result count vs I04 device classification
# Read the persisted I03 results
$ws = 'C:\Temp\Workspace_AMD-Chipset'
# I03 writes to install_results.csv if Export-Csv is wired in (otherwise check console log)
# Easier: re-run the script and compare summary line vs Section 1 of I04.
.\Deploy-AMDChipsetDriverOnWindowsServer.ps1 -Action Install -OnlyPhases I04
# Expected: "FAILED : 0 device(s)" and no devices in the [FAILED] sub-list.
```

### 9.4 Combined regression checklist

When validating these fixes on the M75q Tiny Gen 2 or X13 Gen 1 AMD fixtures:

| # | Check | Pass criterion |
|---|---|---|
| 1 | Banner shows the script version string (e.g., `chipset-YYYY.MM.DD-rNN`) at script startup | ✓ correct version string |
| 2 | P00 log emits `[~] Console encoding set to UTF-8` (NPU only) or simply does not display mojibake later | ✓ no cp932 indicator in CiTool output |
| 3 | I02 completes in < 10 s WITHOUT operator stdin input | ✓ no hang at "Converting XML to .cip binary..." |
| 4 | I02 final line includes `Activation method: CiTool (immediate, no reboot)` rendered via `Write-Detail` (4-space indent, Gray) | ✓ visually subordinate to the preceding `[+] Deployed:` marker line |
| 5 | I03 final summary line includes a `, N no-op` segment for chipset / graphics | ✓ matches the new 5-tuple format |
| 6 | I04 `FAILED` count = I03 `failed` count | ✓ both 0 on the clean-install scenario |
| 7 | All ja-JP strings in the log are readable (no `蜃ｦ`, `謌仙` etc.) | ✓ no mojibake |

## 10. Regression scenarios: detection accuracy + Multi-OS

These regression scenarios validate the nine enhancements bundled in the
`detection-accuracy-multi-os` release (root causes in SPEC §D.18 / §D.18b
/ §D.18c / §D.18d / §D.19 / §D.20 / §D.21 / §D.22 / §D.22b; release information
in [CHANGELOG.md](./CHANGELOG.md)). The scenarios are organized by feature;
each can be exercised independently on the same WS2025 install used for §1
(M75q Tiny Gen 2) without re-imaging.

### 10.1 `Get-DriverSourceCategory` Step 0 — catalog thumbprint match (SPEC §D.18)

**Pre-fix symptom**: On the first full Install pass on a clean WS2025 host, I00's TO-BE display incorrectly labels the script's own self-signed catalogs as `category=Vendor`, causing the priority override in SPEC D.15 to pick the wrong INF for binding.

**Regression test**: After running `-Action Install -OnlyPhases I00,I02,I03` with the new revision on a host with a fresh certificate / WDAC policy:

| Observation | Pre-fix | Post-fix |
|---|---|---|
| TO-BE category for AMD INFs after I02 activates the supplemental policy | `[B] Vendor` | `[C] Self-Signed (catalog thumbprint match)` |
| Source of classification | Step 1 string-match (failed → fell through to Step 2 Provider match) | Step 0 catalog thumbprint match |
| Decision matrix outcome | Wrong INF chosen for some devices | Correct INF chosen |

**Pass criterion**: I00 reports `category=[C] Self-Signed (this script, catalog thumbprint match)` (note the explicit "catalog thumbprint match" suffix that distinguishes Step 0 from the legacy Step 1 path) for every INF that was signed by `$Ctx.CertThumbprint` in I02. No INF that was signed by the script is misclassified as `[B] Vendor` on second-pass run.

**Verification commands**:

```powershell
# Inspect the I00 detail log for the classification label.
# After running -Action Install at least once:
Select-String -Path "$env:ProgramData\Deploy-Drivers-For-WindowsServer\logs\*.log" `
              -Pattern 'catalog thumbprint match|Self-Signed \(this script' |
    Select-Object -Last 20
```

The log should show every AMD INF (Chipset and Graphics) classified with the "catalog thumbprint match" label suffix once I02 has populated the policy. The Step-0 label is `Self-Signed (this script, catalog thumbprint match)`; the legacy Step-1 label is `Self-Signed (this script)` (no suffix). Either is a valid [C] classification; Step-0 is preferred because it is independent of the WMI `Signer` field (which may be empty for self-signed catalogs).

### 10.2 BthPan I04 language-independent detection (SPEC §D.19)

**Pre-fix symptom on Japanese WS2025**: `I04 OverallResult = PartialOrPhantom`, script requests reboot, but PAN connectivity is already functional and `Bluetooth デバイス (パーソナル エリア ネットワーク)` appears in `ncpa.cpl`.

**Regression test**: After running `-Action Install -OnlyPhases I00,I01,I02,I03,I04` with the new BthPan revision on a Japanese WS2025 host:

| Observation | Pre-fix | Post-fix |
|---|---|---|
| `$Ctx.I04OverallResult` on Japanese WS2025 | `PartialOrPhantom` | `TrueResolution` |
| Reboot request | Yes (spurious) | No |
| `Test-BthPanRuntimeArtifacts.HasNetAdapter` | `$false` (regex failed) | `$true` (language-independent match) |
| `Get-BthPanNetChildBinding` invoked | (helper does not exist) | Yes; returns Net-class child with `IsSignedByUs=$true` |
| `Invoke-InstPhase04` Section 1 display | parent `BTH\MS_BTHPAN\*` only | parent + Net-child binding sub-block |

**Pass criterion**: `I04 OverallResult = TrueResolution` on every Japanese-locale WS2025 / WS2022 host where bthpan.sys is loaded and the catalog signature matches `$Ctx.CertThumbprint`.

**Verification commands** (must run on a Japanese WS2025 host with the script's WDAC policy active):

```powershell
# (a) Confirm the language-independent Net-adapter detection works.
Get-NetAdapter | Where-Object {
    $_.DriverFileName -ieq 'bthpan.sys' -or
    $_.ComponentID    -ieq 'ms_bthpan'  -or
    $_.PnPDeviceID    -match '^BTH\\MS_BTHPAN(?:XFER)?\\'
} | Format-List Name, InterfaceDescription, DriverFileName, ComponentID, PnPDeviceID

# (b) On a Japanese SKU, InterfaceDescription will contain hiragana/katakana,
# but the three property fields above will still be in English. THIS IS THE POINT.
```

If (a) returns at least one adapter and the three matched fields are visibly English while `InterfaceDescription` contains Japanese characters, the language-independence design is functioning as specified.

### 10.3 Graphics I00 deduplication (SPEC §D.20)

**Pre-fix symptom**: I00 prints ~1000 visually-identical TO-BE rows per Graphics device, and Risk Summary reports `[MEDIUM] 1069 item(s)` for a single AMD u0197843.inf match.

**Regression test**: On the M75q Tiny Gen 2 host (or any Phoenix-class device matched by u0197843.inf):

| Observation | Pre-fix | Post-fix |
|---|---|---|
| TO-BE rows per Graphics device | ~5046 | 1 (with `[+5046 HWID variants]` suffix) |
| Risk Summary `[MEDIUM]` count | 1069 items | ~5 items |
| Visual scan time to review I00 output | minutes | seconds |

**Pass criterion**: TO-BE display shows one row per unique `(InfName, SrcSubDir)` pair. Risk Summary `[MEDIUM]` count reflects the number of actual replacement decisions, not HWID-variant impressions.

**Verification commands**:

```powershell
# Inspect the I00 output count for a Graphics-only run.
$logFile = Get-ChildItem "$env:ProgramData\Deploy-Drivers-For-WindowsServer\logs\graphics-*.log" |
           Sort-Object LastWriteTime -Descending | Select-Object -First 1
# Expect one TO-BE row per (InfName, SrcSubDir) with [+N HWID variants] suffix when N>1
Select-String -Path $logFile.FullName -Pattern 'TO-BE:.*\[\+\d+ HWID variants\]' |
    Measure-Object | Select-Object -ExpandProperty Count
```

### 10.4 Chipset P04 sub-MSI diagnostics (SPEC §D.21)

**Pre-fix symptom**: Sub-MSI failures in the P04 Nested loop are silently recovered (correct behaviour), but no breadcrumb is left if the parent EXE ultimately reports a payload-missing condition after Nested recovery succeeds.

**Regression test**: This is a diagnostics-only feature; normal runs produce no observable change. Forced regression test:

1. Run `-Action Install -OnlyPhases P04` on a clean WS2025 host with the AMD Chipset 8.x payload.
2. Mid-run (after the first MSI extraction), rename one of the `.cab` files in `%TEMP%\AMD\*\` to provoke MSI error 1335 ("corrupt cabinet").
3. The Nested loop retries and succeeds (because the original cab is reconstructed by AMD's installer on retry).

| Observation | Pre-fix | Post-fix |
|---|---|---|
| `$logRoot\submsi-failures-diag.txt` exists | No (file not created) | Yes (≥ 1 sub-MSI failure was captured) |
| Pattern classification in the diag file | (file absent) | `1335 corrupt cabinet` at least once |
| TARGETDIR snapshot at failure time | (file absent) | `Exists=True, InfCount=N, FileCount=M, LastWriteHint=...` |
| User-visible P04 outcome | `success` (parent EXE recovered) | `success` (unchanged) |

**Pass criterion**: `submsi-failures-diag.txt` is created and contains the pattern classification when sub-MSI failures occurred. The file is NOT created on clean runs with no sub-MSI failures (zero-noise default).

### 10.5 BthPan I05 ForceRebind + WS2019 CIM bridge (SPEC §D.22)

**E-1 — I05 ForceRebind regression test** (BthPan-only):

This phase activates ONLY when `$Ctx.I04OverallResult -eq 'PartialOrPhantom'`. Force-induced regression:

1. On a known-good WS2025 host with bthpan working, run `pnputil /delete-driver oem<N>.inf /uninstall /force` to manually break the binding (where `<N>` is the OEM number of the patched bthpan.inf).
2. Run `-Action Install -OnlyPhases I04,I05`.

| Observation | Without I05 | With I05 |
|---|---|---|
| I04 verdict | `PartialOrPhantom` | `PartialOrPhantom` (initially) |
| I05 invoked | (phase does not exist) | Yes |
| I05 cascade attempts | (n/a) | Attempt 1 (`Restart-PnpDevice`) succeeds on WS2025 |
| I04 verdict after I05 promotion | `PartialOrPhantom` | `TrueResolution` (promoted by I05) |
| Reboot required | Yes | No |
| `$Ctx.I05OverallResult` | (field does not exist) | `Recovered` |

**Pass criterion**: After I05, `$Ctx.I04OverallResult` is `TrueResolution` and no reboot is requested. The cascade attempt that succeeded is logged in `$Ctx.I05PerDeviceResults`.

I05 no-op test (on a clean working WS2025 host without breakage):

| Observation | Expected |
|---|---|
| I05 phase header printed | Yes |
| Cascade attempts run | 0 (short-circuited by `I04OverallResult -eq 'TrueResolution'`) |
| `$Ctx.I05OverallResult` | `$null` (no-op) |
| Run-time impact | < 1 s |

**E-2 — WS2019 CIM bridge regression test** (all four scripts):

This regression requires a WS2019 host (the CIM bridge is only activated when `CiTool.exe` is absent, i.e., on WS2019 and WS2016).

| OS | `CiTool.exe` | `PS_UpdateAndCompareCIPolicy` | Expected `ActivationMethod` |
|---|---|---|---|
| WS2025 (build 26100) | present | (skipped — CiTool already succeeded) | `CiTool (immediate, no reboot)` |
| WS2022 (build 20348) | present | (skipped) | `CiTool (immediate, no reboot)` |
| WS2019 (build 17763) | absent | present | `CIM bridge (PS_UpdateAndCompareCIPolicy, no reboot)` |
| WS2016 (build 14393) | absent | absent (class missing) | `reboot` (existing behaviour) |

**Pass criterion (WS2019 host)**:
- `Install-AmdWdacPolicy` / `Install-MsBthPanWdacPolicy` / `Install-WdacPolicy` returns `RebootRequired=$false` AND `ActivationMethod='CIM bridge (PS_UpdateAndCompareCIPolicy, no reboot)'`.
- Subsequent I03 verifies the supplemental policy is active (queryable via `Get-WmiObject -Namespace 'root\Microsoft\Windows\CI' -Class PS_QueryDeviceGuardStatus`).

**Pass criterion (WS2016 host)**:
- The CIM bridge attempt fails silently (`$cimBridgeError` is populated with "class not found" or equivalent).
- `ActivationMethod='reboot'` is selected.
- `-UseTestSigning` switch is the supported activation path on WS2016 and produces an explicit reboot request.

### 10.5b BthPan I05 phase-footer ValidateSet compliance (SPEC §D.22b)

**Pre-fix symptom**: I05 raises `ParameterArgumentValidationError` on the two early-return paths (`I04OverallResult` is `TrueResolution` / `NoDevice`, or `Get-MsBthPanDevice` returns empty) because `Write-PhaseFooter 'I05' 'no-op'` is rejected — `'no-op'` is not in the `[ValidateSet('done','cached','skipped','failed')]` allowed values.

**Regression test**: Run on a Japanese WS2022 / WS2025 host where bthpan is in a clean state (no phantom Net adapter to rebind):

```powershell
.\Deploy-MSBthPanInboxOnWindowsServer.ps1 -Action Install -OnlyPhases I04,I05
```

| Observation | Pre-fix | Post-fix |
|---|---|---|
| I05 ends with footer `Write-PhaseFooter 'I05' 'skipped'` | ✗ throws ParameterArgumentValidationError on `'no-op'` | ✓ accepts `'skipped'` |
| Pipeline exit code from I05 phase | non-zero (PowerShell error) | 0 (clean exit) |
| Debug-trace JSONL record | missing `status` field on I05 record | `{"phase":"I05","status":"skipped","reason":"TrueResolution|NoDevice|no device"}` |
| User-visible `Write-Skip` line | "no-op" wording preserved | "no-op" wording preserved |

**Pass criterion**: 
- The three early-return paths all emit `Write-PhaseFooter 'I05' 'skipped'`:
  1. `I04OverallResult` is null (existing — unchanged)
  2. `I04OverallResult` is `TrueResolution` or `NoDevice` (fixed)
  3. `Get-MsBthPanDevice` returns empty (fixed)
- The successful-rebind path still emits `Write-PhaseFooter 'I05' 'done'` (unchanged).
- No ParameterArgumentValidationError appears in the console log.

**Verification commands**:

```powershell
# Pattern-match every Write-PhaseFooter 'I05' callsite to confirm valid Status tokens.
Select-String -Path Deploy-MSBthPanInboxOnWindowsServer.ps1 `
              -Pattern "Write-PhaseFooter 'I05'" |
    ForEach-Object {
        if ($_.Line -match "Write-PhaseFooter 'I05' '(done|cached|skipped|failed)'") {
            "L$($_.LineNumber): OK ($($matches[1]))"
        } else {
            "L$($_.LineNumber): FAIL ($($_.Line.Trim()))"
        }
    }
# Expected: 3 'skipped' + 1 'done' = 4 OK lines, 0 FAIL lines.
```

### 10.5c Chipset / Graphics I04 classification + disposition robustness (SPEC §D.18b / §D.18c / §D.18d)

**Pre-fix symptoms (operator log, Japanese WS2022 Datacenter, build 20348)**:
- `[LOADED]` row shows `AFTER: [B]` (Vendor) for a device that was just bound to our self-signed driver (e.g., `AMD Radeon(TM) Graphics`).
- `[REBOOT_NEEDED]` count exceeds I03's actual "reboot required" count (e.g., I03 = `1 reboot required` but I04 = `5 REBOOT_NEEDED`).
- `[REBOOT_NEEDED]` rows render uninformative lines like `Still on v, new INF queued: (none)` for devices whose previous binding had an empty version field.

**Regression test (chipset; analogous on graphics)**: Run `-Action Install -OnlyPhases I00,I01,I02,I03,I04` on a Japanese WS2022 / WS2025 host. Then inspect the I04 output:

| Observation | Pre-fix | Post-fix |
|---|---|---|
| I04 builds `$ourInfSet` via `Get-OurSignedOemInfSet -ExpectedThumbprint $Ctx.CertThumbprint` | (not built) | `Known signed-by-us INF/CAT name(s): <N>` (N ≥ 1 after I03 installs) |
| `Get-DriverSourceCategory` called with `-KnownOurInfSet $ourInfSet` for both AS-IS and AFTER classification | (not passed) | Both calls receive the parameter |
| `[LOADED]` AFTER category for self-signed-by-us drivers | sometimes `[B]` Vendor | always `[C]` Self-Signed |
| Disposition decision when OS reports our InfName + same DriverVersion | conservative fallback → `REBOOT_NEEDED` | new branch → `LOADED` |
| `[REBOOT_NEEDED]` device count vs I03's reboot-required count | I04 > I03 (over-counting) | I04 = I03 (matching) |
| `[REBOOT_NEEDED]` display: empty `Before.DriverVersion` | renders `Still on v,` (no value) | renders `Still on v(unknown),` |
| `[REBOOT_NEEDED]` display: null `Candidate` | renders `new INF queued: (none)` | renders `new INF queued: (OS-bound: oemNN.inf)` |

**Pass criteria**:
- All AFTER-categories for self-signed-by-us drivers report `[C]` in the I04 `[LOADED]` block.
- I04 `REBOOT_NEEDED` device count equals I03's reboot-required INF count (within ±1 for race conditions in pnputil's status reporting).
- No `[REBOOT_NEEDED]` row contains `Still on v,` (empty version field after `v`) or `(none)` when the OS knows the bound INF.

**PSA8001 invariant check** (must pass on both Chipset and Graphics):

```bash
# Get-OurSignedOemInfSet must be byte-identical across Chipset + Graphics.
diff <(sed -n '/^function Get-OurSignedOemInfSet/,/^}$/p' Deploy-AMDChipsetDriverOnWindowsServer.ps1) \
     <(sed -n '/^function Get-OurSignedOemInfSet/,/^}$/p' Deploy-AMDGraphicsDriverOnWindowsServer.ps1)
# Expected: no output (zero diff).

# Get-DriverSourceCategory must remain byte-identical after the Step 0b extension.
diff <(sed -n '/^function Get-DriverSourceCategory/,/^}$/p' Deploy-AMDChipsetDriverOnWindowsServer.ps1) \
     <(sed -n '/^function Get-DriverSourceCategory/,/^}$/p' Deploy-AMDGraphicsDriverOnWindowsServer.ps1)
# Expected: no output (zero diff).
```

### 10.5d Chipset phantom file reference detection + P08 skip (SPEC §D.24)

**Pre-fix symptom** (r64): P08 reports `Catalog generation: 59 ok / 1 failed (using /os:ServerRS5_X64)` on AMD Chipset Software 8.05.04.516 against Renoir + WS2019. The single failure is `Chipset_Software_CIR_Driver_WTx64` with inf2cat error `22.9.1: amdcir.sys ... is missing or cannot be decompressed`. P04's `submsi-failures-diag.txt` classifies all 12 sub-MSI failures as `unknown`.

**Regression test (r65)** — natural reproduction on the same environment:

1. WS2019 host (build 17763), AMD Ryzen 5 PRO 4650U (Renoir) or any AMD platform that does **not** include a Consumer Infrared device.
2. Run `.\Deploy-AMDChipsetDriverOnWindowsServer.ps1 -Action PrepareVerify -CleanWorkRoot`.

| Observation | Pre-fix (r64) | Post-fix (r65) |
|---|---|---|
| P04 `submsi-failures-diag.txt` `Failure pattern frequency` | `12 x unknown` | `12 x 1603: SECREPAIR missing source files (AMD MSI packaging defect; ...)` |
| P05 console output for the CIR Driver | (not surfaced) | `[!] INFs ineligible for catalog generation (phantom file references): 1` block listing `AMDCIR.inf` with `missing: AMDCIR.sys` |
| P05 `inf_inventory.csv` new columns | absent | `ReferencedFilesCount`, `MissingReferencedFiles`, `EligibleForCatalog` |
| P05 phase marker metadata | `{Total, Selected, CsvPath, ReportPath, Variants}` | adds `Ineligible` |
| P06 console output | (not surfaced) | `Note: 1 INF(s) will be copied for traceability but skipped at P08 ...` listing `AMDCIR.inf` |
| P08 console output | `Generating catalogs for 60 INF folder(s)` then `inf2cat: [WTx64] Chipset_Software_CIR_Driver_WTx64` `[!] FAILED (exit=-2)` | `[~]  Skipping 1 INF folder(s) due to phantom file references (SPEC D.24):` block listing the CIR Driver, then `Generating catalogs for 59 INF folder(s)` |
| P08 summary line | `Catalog generation: 59 ok / 1 failed (using /os:ServerRS5_X64)` | `Catalog generation: 59 ok / 0 failed / 1 skipped (using /os:ServerRS5_X64)` |
| P08 phase marker metadata | `{Ok, Failed, OsArg}` | adds `Skipped` |
| P09 signing count | `59 ok / 0 failed` | unchanged (`59 ok / 0 failed`) — P09 enumerates `.cat` files; the CIR Driver folder has no `.cat` so P09 has nothing to act on for it |
| V03 console output | (no notice) | `[~]  Not verifying 1 INF folder(s) - no .cat exists (skipped at P08; phantom file references, SPEC D.24)` block listing `Chipset_Software\CIR Driver\WTx64\AMDCIR.inf`. The 59-catalog `Verifying ...` loop is unchanged. |
| V04 summary line | `INF verification: 60 ok / 0 missing decoration` | `INF verification: 59 ok / 0 missing decoration / 1 skipped` plus a `[~]` block listing `AMDCIR.inf` |
| V05 I03 dry-run output | `60 INF(s) would be processed by 'pnputil /add-driver /install'` (with `AMDCIR.inf` appearing in Group B "no matching device") | `[~]  Excluding 1 INF(s) from dry-run plan ...` block listing `Chipset_Software\CIR Driver\WTx64\AMDCIR.inf`, then `59 INF(s) would be processed by 'pnputil /add-driver /install'` |
| V06 output | `AMDCIR.inf` is listed under section 2 "Devices with NO matching patched INF" (as a fallback bucket entry) | `[~]  Excluding 1 ineligible INF(s) from TO-BE candidates (phantom file references, SPEC D.24):` block at the top of V06 listing `AMDCIR.inf`. Section 2's enumeration is unchanged for all other INFs. |
| I03 console output (when `-Action Install` is run) | `pnputil` would attempt to install `AMDCIR.inf`; without a `.cat` it fails with `0x80004005` "the third-party INF does not contain digital signature information" | `[~]  Excluding 1 ineligible INF(s) from install ...` block listing `AMDCIR.inf` (with explanation "no .cat exists; would have failed pnputil signature check"). I03 then iterates only 59 INFs. |

**Pass criterion**:

- P05's `inf_inventory.csv` row for `AMDCIR.inf` has `EligibleForCatalog=False` and `MissingReferencedFiles=AMDCIR.sys`.
- P08's tri-state summary line ends with `... / 1 skipped (using /os:ServerRS5_X64)`.
- V04's tri-state summary line ends with `... / 1 skipped`.
- V05's dry-run install plan reports 59 INFs (not 60).
- V06's section 2 ("Devices with NO matching patched INF") no longer lists `AMDCIR.inf` as part of any device's TO-BE candidates.
- I03's pnputil loop iterates 59 INFs and successfully completes without the `0x80004005` signature failure on the CIR Driver.
- Zero pipeline failures end-to-end (the original P08 `1 failed` is eliminated).
- `patched\Chipset_Software\CIR Driver\WTx64\` still contains `AMDCIR.inf` and `AMDCIR64.sys` (copied by P06 for traceability) but no newly-generated `amdcir.cat` (AMD's original 2015 `amdcir.cat` from the extracted tree is also not present in `patched/` because P06 only copies the source tree, and the script idempotently cleans existing `.cat` from each catalog target directory before inf2cat would have run; for the skipped directory, the cleanup step is itself skipped).

**Verification commands**:

```powershell
# Verify the CSV column addition and ineligibility flagging.
$csv = Import-Csv 'C:\Temp\Workspace_AMD-Chipset\inf_inventory.csv'
$csv | Where-Object Inf -eq 'AMDCIR.inf' |
    Select-Object Inf, SourceVariant, EligibleForCatalog, MissingReferencedFiles, ReferencedFilesCount

# Expected (Renoir + WS2019 + Chipset 8.05.04.516):
# Inf          : AMDCIR.inf
# SourceVariant: WTx64
# EligibleForCatalog    : False
# MissingReferencedFiles: AMDCIR.sys
# ReferencedFilesCount  : 2

# Verify the sub-MSI pattern classifier picks up the SECREPAIR pattern.
$diag = Get-Content 'C:\Temp\Workspace_AMD-Chipset\logs\submsi-failures-diag.txt'
$diag | Select-String 'Failure pattern frequency' -Context 0,4

# Expected (post-fix):
# Failure pattern frequency:
#     12 x 1603: SECREPAIR missing source files (AMD MSI packaging defect; ...)
```

**No-op test on a platform without the defect** (e.g. WS2025 + Phoenix Point with a newer Chipset Software version that doesn't include the dual-arch CIR Driver):

| Observation | Expected |
|---|---|
| P05 `[!] INFs ineligible ...` block | absent (no INFs flagged) |
| P05 inventory CSV new columns | present, all rows have `EligibleForCatalog=True` and empty `MissingReferencedFiles` |
| P06 phantom file notification | absent |
| P08 skip block | absent |
| P08 orphan-cleanup line (r66) | absent (no skip block to clean from) |
| P08 summary line | reverts to legacy two-state form `Catalog generation: N ok / 0 failed (using /os:...)` |
| P08 phase marker | includes `Skipped=0` |
| P09 orphan-filter block (r66) | absent (no ineligible dirs to filter) |
| P09 summary line | reverts to legacy two-state form `Signing: N ok / 0 failed` |
| P09 phase marker (r66) | includes `Skipped=0` |
| V01 catalog count | matches P08/P09 N (no orphan delta) |
| V03 skip notice | absent |
| V04 summary line | reverts to legacy two-state form `INF verification: N ok / 0 missing decoration` |
| V05 dry-run skip block | absent |
| V06 ineligible notice | absent |
| I03 ineligible-INF skip block | absent |

**Pass criterion (no-op test)**: pipeline behavior is identical to r64 on this platform; no spurious skip messages or count changes. All r65/r66 code paths are guarded by `Lookup.Count -gt 0` (V03/V04/V05/V06/I03) / `$copyOnlyIneligible.Count -gt 0` (P06) / `$ineligibleDirs.Count -gt 0` (P08) / `$ineligibleDirSet.Count -gt 0` (P09), so on a clean package the modifications are byte-identical-to-r64 silent.

#### 10.5d.r66 P09 orphan .cat cleanup (added 2026-05-22, gap surfaced by r65 real-machine run)

The r65 real-machine verification (2026-05-22, WS2019 + Renoir + Chipset 8.05.04.516) confirmed that P05/P06/P08/V03/V04/V05/V06/I03 all correctly skip ineligible INFs, but also surfaced a residual issue: P09 was enumerating `Get-ChildItem -Recurse -Filter *.cat` under `patched/` and picking up 5 original AMD-shipped `.cat` files that P06 had transitively copied alongside the ineligible INFs. P09 re-signed them with the self-signed cert, so V01 reported `Catalog files: 60` instead of 55, V03 verified 60 catalogs (5 of them orphans), and `patched/` ended up with 5 unused but signed `.cat` artifacts.

r66 closes this gap with two cooperating defense layers (case alpha B+C). Test against the same 2026-05-22 reproducer workspace (or a fresh `-CleanWorkRoot` run):

| Observation | r65 actual (defect) | r66 expected (fixed) |
|---|---|---|
| P05 ineligible block | 5 INFs flagged | 5 INFs flagged (unchanged) |
| P06 copy-only notification | 5 INFs listed | 5 INFs listed (unchanged) |
| P08 skip block | 5 directories listed | 5 directories listed (unchanged) |
| P08 orphan-cleanup line | absent | `Cleaned 5 orphan .cat file(s) from skipped directories (would otherwise be picked up by P09).` |
| P08 summary | `55 ok / 0 failed / 5 skipped` | `55 ok / 0 failed / 5 skipped` (unchanged) |
| P09 enumeration count | 60 .cat enumerated | 55 .cat enumerated (orphans deleted at P08) |
| P09 filter block | absent | absent (Layer B left nothing for Layer C to filter) |
| P09 summary | `Signing: 60 ok / 0 failed` | `Signing: 55 ok / 0 failed` |
| P09 phase marker | `Ok=60, Failed=0` | `Ok=55, Failed=0, Skipped=0` |
| V01 catalog count | `Catalog files: 60` | `Catalog files: 55` |
| V03 verifying count | 60 catalogs | 55 catalogs |
| V03 notice text | "no .cat exists" (inaccurate) | "no .cat exists" (now accurate) |

**Pass criterion (r66 fix)**:

- P09 enumeration finds exactly `(eligible variant-selected INFs) - (decoration patches that consolidate identical files)` `.cat` files; matches P08's `N ok` count.
- V01 `Catalog files: N` equals P08's `N ok`.
- After re-running on the workspace, no orphan `.cat` remains in any directory listed in the P08 skip block. Verify with:

```powershell
# Verify no orphan .cat survived in skipped directories.
$csv = Import-Csv 'C:\Temp\Workspace_AMD-Chipset\inf_inventory.csv'
$ineligibleDirs = $csv | Where-Object {
    $_.EligibleForCatalog -eq 'False' -and $_.VariantSelected -eq 'True'
} | Select-Object -ExpandProperty RelativeDir
foreach ($d in $ineligibleDirs) {
    $full = Join-Path 'C:\Temp\Workspace_AMD-Chipset\patched' $d
    $orphans = @(Get-ChildItem -LiteralPath $full -Filter *.cat -File -ErrorAction SilentlyContinue)
    Write-Host ('{0,-5} {1}' -f $orphans.Count, $d)
}
# Expected: all rows show 0 orphan .cat files.
```

**Standalone P09 test (Layer C exercise)**:

To confirm Layer C alone is sufficient when P08's cleanup is bypassed:

1. Run a fresh `-Action PrepareVerify -CleanWorkRoot` to populate `patched/` with the r66 expected state (55 catalogs).
2. Manually copy any 5 stray `.cat` files into the 5 ineligible directories (simulating an r65 workspace).
3. Run `-Action Prepare -OnlyPhases P09 -Force`.
4. Expected: P09 prints `[~]  Excluding 5 orphan .cat file(s) from signing ...` block, signs 55, reports `Signing: 55 ok / 0 failed / 5 skipped`. The orphans remain on disk (Layer C does not delete, only filters) but are never re-signed.

### 10.6 Multi-OS support matrix

Cross-script Multi-OS capability matrix to validate when expanding from the current WS2025-only validation to WS2022 / WS2019 / WS2016:

| Capability | WS2025 (26100) | WS2022 (20348) | WS2019 (17763) | WS2016 (14393) |
|---|---|---|---|---|
| `CiTool.exe --json --update-policy` | ✓ | ✓ | absent | absent |
| `PS_UpdateAndCompareCIPolicy` CIM | ✓ (skipped) | ✓ (skipped) | ✓ | absent |
| `Restart-PnpDevice` | ✓ | ✓ | ✓ | absent |
| `Disable-PnpDevice` / `Enable-PnpDevice` | ✓ | ✓ | ✓ | absent |
| `pnputil /add-driver /install` | ✓ | ✓ | ✓ | ✓ |
| `pnputil /remove-device /scan-devices` | ✓ | ✓ | ✓ | ✓ |
| `Stop-Service` / `Start-Service BthPan` | ✓ | ✓ | ✓ | ✓ |
| BCDEdit testsigning + reboot (`-UseTestSigning`) | ✓ | ✓ | ✓ | ✓ |
| `inf2cat /os Server2025_X64` | ✓ | (fallback: ServerFE_X64) | (fallback: ServerRS5_X64) | (fallback: Server2016_X64) |

**Current validation status**:
- WS2025: validated on M75q Tiny Gen 2 + ThinkPad X13 Gen 1 AMD (proxy via Win11 LTSC).
- WS2022 / WS2019 / WS2016: capability matrix is derived from Microsoft documentation. Field validation is pending on real hardware.

### 10.7 Language-independence regression check

For all four scripts, no production code path should match against `InterfaceDescription`, `FriendlyName`, `Description`, `Name`, or `Caption` for classification purposes. Manual audit command:

```powershell
# Grep for the forbidden localized-string matches across all four scripts.
$forbidden = @(
    'InterfaceDescription\s+-\s*(?:i?match|-i?eq|-i?like)',
    'FriendlyName\s+-\s*(?:i?match|-i?eq|-i?like)',
    'Description\s+-\s*(?:i?match|-i?like)'   # 'Description -eq' is acceptable in some unit-test contexts
)
foreach ($f in @(
    'Deploy-AMDChipsetDriverOnWindowsServer.ps1',
    'Deploy-AMDGraphicsDriverOnWindowsServer.ps1',
    'Deploy-AMDNpuDriverOnWindowsServer.ps1',
    'Deploy-MSBthPanInboxOnWindowsServer.ps1'
)) {
    foreach ($pat in $forbidden) {
        $hits = Select-String -Path $f -Pattern $pat -CaseSensitive
        if ($hits) {
            Write-Warning "Potential localization-dependent match in ${f}:"
            $hits | ForEach-Object { Write-Host ('  L{0}: {1}' -f $_.LineNumber, $_.Line.Trim()) }
        }
    }
}
```

**Pass criterion**: Zero hits. Any hit must be auditable (e.g., explicit comment noting that the matched string is hard-coded in English and not subject to localization on this code path, such as the inbox `Microsoft` provider strings used in V01 Secure Boot baseline classification).

---

## 12. Validation Scenario 12: Catastrophic field failure incident (2026-05-23)

### Status

**This is a post-mortem case study, not a reproducible test scenario.** The bench that surfaced this incident was retired to OS reinstall. The lessons documented here drive the bug fixes and design changes in `Chipset r68 / Graphics r34 / BthPan r16` and the planned improvements tracked under SPEC §D.26.3 for `r69/r35/r17`.

### Bench

| Attribute | Value |
| --- | --- |
| OS | Windows Server 2019 Datacenter, build 17763 |
| CPU | AMD Ryzen 5 PRO 4650U (Renoir) |
| Firmware | UEFI, GPT system disk |
| Secure Boot | ON (Healthy baseline; UEFI CA 2023 N/A; no MS sample script) |
| BitLocker | OFF |
| HVCI / VBS | OFF |
| Pre-existing drivers | Inbox display (`display.inf`), inbox AMD chipset stubs, inbox `bthpan.inf` (Phantom OK), no AMD Adrenalin, no AMD chipset software |
| Pipeline release | Chipset r67 / Graphics r33 / NPU r16 (not run) / BthPan r15 / WDAC SPF orchestrator r04 |

### Action sequence (as executed)

```
1. Chipset    -Action Install       -> reports success
2. Graphics   -Action Install       -> reports success (with internal inconsistencies, see below)
3. MSBthPan   -Action Install       -> reports I04 FAIL + I05 attempts all fail
4. Restart-Computer
5. Host fails to boot (normal mode, all Safe Mode variants, WinRE attempts)
```

**Step 4 was the first reboot of the entire sequence.** Steps 1–3 were run back-to-back with no reboot between scripts.

### Observed phase outputs

#### Chipset Install

I02 deployed SPF policy successfully (`State : None -> Ours-Healthy`, WMI bridge activation, 3.57 s). I03 installed 55 INFs (1 reboot-required for AMD PSP, 2 no-op, 0 failed). I04 enumerated 42 AMD devices: 0 LOADED / 5 REBOOT_NEEDED / 0 KEPT_CURRENT / 37 UNCHANGED / 0 FAILED.

#### Graphics Install (no reboot since chipset)

I02 reported `[+] Legacy WDAC SPF policy is active. No reboot required (per WMI CIM bridge)` — yet the I04 boot-signing table on the same run still printed:

```
Boot Signing : Firmware=UEFI ... SecureBoot=ON  TestSigning=off HVCI=off WDAC-AMD=off
Self-signed driver  : BLOCKED
[!] Self-signed driver loading is currently BLOCKED. ...
```

I04 Section 1 classified two devices as LOADED:

```
[LOADED] - new driver is active right now:
  - AMD Audio CoProcessor
      AS-IS: [?] v    AFTER: [B] v6.0.1.85    INF: amdacpbus.inf
  - AMD High Definition Audio Controller
      AS-IS: [A] v10.0.17763.1    AFTER: [B] v10.0.0.35    INF:
```

I04 Section 2 (functional probe) then immediately reported the **same two devices** as `[FAIL]`:

```
[FAIL] AMD Audio CoProcessor
    [x] PnP status OK        : Error
    [x] ConfigCode = 0       : CM_PROB_DRIVER_FAILED_LOAD
    [x] Service running      : amdacpbus -> Stopped
[FAIL] AMD High Definition Audio Controller
    [x] PnP status OK        : Error
    [x] ConfigCode = 0       : CM_PROB_NEED_RESTART
    [x] Service running      : AMDHDAudBusService -> Stopped
```

The script then placed `Microsoft 基本ディスプレイ アダプター` (the Microsoft Basic Display Adapter) in REBOOT_NEEDED, queued for replacement by `u0201039.inf` (the AMD Adrenalin display driver with 1066+ HWID variants), and exited successfully.

#### MSBthPan Install (no reboot since graphics)

I02 again reported SPF active. I03 installed `bthpan.inf`. I04 found `BTH\MS_BTHPAN\7&1F82E917&0&2` in Unknown state (PnP `Status: Error`, `Class:` blank, `Service:` blank, `DriverInfPath:` blank — driver bind had not occurred). I05 cascaded through Attempts 1–4 and failed all of them, including the Attempt 3 `Start-Process` validator failure documented in SPEC §D.26.1.C.

### Post-reboot state

The host did not present any visible boot progress on the next start, and did not respond to F8 / Shift+F8 / repeated power cycles intended to trigger automatic WinRE. Boot from installation media presented WinRE but `dism /image:C:\ /cleanup-image /revertpendingactions` did not restore boot. The host was added to the reinstall queue.

### Root-cause hypothesis (not directly confirmable post-reinstall)

The most plausible chain of causation, listed in order from most likely to least:

1. **Display driver replacement on a single-display-path host with Secure Boot enforcement.** The `display.inf -> u0201039.inf` swap installed a brand-new self-signed display driver whose catalog had to pass kernel CI at the boot loader's evaluation point. If the boot loader did not accept the SPF policy as authorizing that specific catalog (for any reason — Option 6 / Option 10 not actually set in the deployed policy, signature timestamp issue, etc.), the kernel falls back to Basic Display only IF that driver itself is still loadable; on a system where the Basic Display Adapter has already been visibly replaced in PnP, the fallback may not happen, leaving the host with no display path.
2. **AMD PSP driver replacement** on a host that may have firmware-level expectations on PSP behaviour. r67 already warns about this in the BitLocker context; BitLocker was off on this bench, but a PSP rejection at boot can still freeze the system before display init.
3. **Cumulative kernel-mode driver surface from three concurrent Installs**. Even individually-safe driver replacements can interact at boot — three new self-signed catalogs simultaneously evaluated against a SPF policy that has authorized three different certs is not a code path the orchestrator's pilot validation exercised in isolation.
4. **WDAC SPF policy regressions across re-deploys**. Each driver script's I02 invokes the orchestrator's `AddCert` action, which rewrites the SPF policy with the accumulated cert list. If any of the three I02 invocations produced a policy missing Option 10 (Boot Audit on Failure), the host has no audit fallback at boot.

None of these is individually confirmable without forensic offline access to the bricked system, which was reinstalled before forensic capture was attempted.

### Test artifacts that would have caught each defect earlier

| Defect | Test that would have caught it |
| --- | --- |
| §D.26.1.A SPF-aware boot-signing table | Run `Chipset Install` on a WS2019 bench; observe that I04 prints `BLOCKED` on a SPF-active host. There was no such test in §11 — a "self-consistency probe between I02 reported state and I04 reported state" check belongs in §11 or §12. |
| §D.26.1.B LOADED disposition vs functional probe | The graphics log itself contains the disagreement, side-by-side. A self-consistency cross-check between Section 1 (`LOADED`) and Section 2 (`PASS`) of I04 belongs in the harness. |
| §D.26.1.C BthPan I05 Attempt 3 redirect bug | Force I04 to fail (e.g. by running on a host where PnP rebind cannot complete in time), trigger I05, observe Attempt 3 fail with the validator error. Unit-test-shaped: `Invoke-BthPanPnputilRebind` can be exercised in isolation against a synthetic `$InstanceId`. |
| §D.26.1.D BthPan I05 Attempt 4 error visibility | Same as above; trigger Attempt 4 and inspect the captured Write-Detail output for the InnerException / NativeErrorCode lines. |
| §D.26.2.* (design defects) | No fast unit test catches these. They require the "back-to-back Install on a production-shaped host" scenario the README now explicitly disqualifies from the supported deployment model. |

### Boot-time policy validation (planned for r69/r35/r17)

The orchestrator currently activates the SPF policy via the WMI `PS_UpdateAndCompareCIPolicy` CIM bridge and treats a successful return as "policy is live". The planned `Test-WdacPolicyBootLoadable` extension will additionally:

1. Re-read `C:\Windows\System32\CodeIntegrity\SiPolicy.p7b` from disk.
2. Verify with `signtool verify /pa` (the policy file is self-contained; this catches corrupt deployments).
3. Parse the policy header and assert Option 6 (Enabled:Unsigned System Integrity Policy) and Option 10 (Enabled:Boot Audit on Failure) are both set.
4. Block I03 if any of (1)–(3) fail.

This does NOT guarantee boot-time acceptance (the boot loader has its own enforcement decisions that runtime tools cannot fully predict), but it eliminates the failure modes where the deployed policy is structurally invalid.

### 2026-05-23 second incident — Chipset alone is enough to brick the host (drives r70)

The October 2026 narrative above assumed the brick mechanism required a 3-script cumulative install (Chipset → Graphics → MSBthPan) on the same host without reboots. A second WS2019 + Renoir bench run on **2026-05-23** disproved that assumption: a fresh-install WS2019 host running **only `Chipset r69 -Action Install`** (Path C, Secure Boot ON) was left unable to complete the next boot, including Safe Mode. Graphics and MSBthPan were never run on this bench.

Recovery required booting WinRE from USB and `del C:\Windows\System32\CodeIntegrity\SiPolicy.p7b`. After the deletion, the host booted normally — and notably, the WHQL co-signed AMD drivers (`AmdMicroPEP.sys`, `amdgpio2.sys`, `amdpsp10.sys`) that had already been installed in I03 loaded with `Status=OK` without any WDAC policy in place. Conversely, the non-WHQL drivers in the same package (`amdi2c.sys`, `amdsfhkmdf.sys`) remained `Status=Error / ProblemCode=39 (CM_PROB_DRIVER_FAILED_LOAD)` after WDAC removal, demonstrating that the SPF policy was never the reason WHQL drivers loaded and never sufficient to make non-WHQL drivers load.

**Conclusion (drives r70):** the brick is caused by the WDAC SPF policy itself, not by any cumulative-stacking dynamic. A single Install execution can produce it. The two bench observations (2025 cumulative, 2026-05-23 single-script) are both expressions of the same underlying defect: the boot loader's re-evaluation of `SiPolicy.p7b` against the newly-installed boot-critical driver set is an enforcement layer that the WMI CIM bridge `Update()` success signal cannot speak to. That same boot loader layer also rejects non-WHQL drivers regardless of the policy's contents (see SPEC §D.30 F6, F7).

The full investigation summary, including Microsoft Learn cross-references on `bcdedit /set TESTSIGNING ON` behaviour under Secure Boot (the rejection happens at command execution, not silently in the boot loader) and on the silently-ignored `NOINTEGRITYCHECKS` / `DISABLE_INTEGRITY_CHECKS` flags on WS2008+ x64, is documented in **SPEC §D.30**. The decision to delete Path C entirely in r70 — rather than continue trying to harden it — flows directly from F1–F12 in that section.

**What r70 retires:** the Path C orchestrator, all driver-script delegation helpers (SECTION 1g, SECTION QI-10, `Invoke-LegacyWdacAuthorization`, the I02 Path C branch, the post-I02 BootLoadableCheck dispatcher hook, the manifest.json-based C3 CRITICAL check), and the `-ForceOverrideForeign` / `-AuditMode` / `-StrictBootValidation` switches. The "Boot-time policy validation (planned for r69/r35/r17)" paragraph above is preserved as historical context; its actual landing in `r69 / r35 / r17` (the `BootLoadableCheck` action and its driver-side helper) is also removed in r70 because the policy it was meant to validate is itself removed.

**What r70 does NOT retire:** the lesson that "kernel-mode signing-state changes on a fresh-install Server SKU are an inherently high-risk operation that has no fast rollback on a physical machine." The README's BRICK-LEVEL RISK disclaimer is rewritten to integrate the 2026-05-23 single-script observation alongside the original 3-script-cumulative observation. The Path B (testsigning + Secure Boot Disabled in firmware) path remains supported but requires an explicit `-UseTestSigning` invocation; r71 is planned to surface this as an early-abort prerequisite check.

---

## 13. Validation Scenario 13: QI-6 / QI-9 / Q-X1 (r69/r35/r17/r17)

### Status

Code-review validated only. The only WS2019 + Renoir bench is queued for OS reinstall as of release time; physical replay is not possible. Test cases below describe what should be observed when a bench becomes available and the r69/r35/r17/r17 release is replayed against it. (Note: the QI-10 / `r05` test cases previously documented in this section were removed in r70 along with the Path C orchestrator and the `Invoke-BootLoadableCheck` helper; see SPEC §D.30.)

### Scope

This section covers the three post-r04 improvements that remain in scope after the r70 Path C deprecation:

- **QI-6**: CRITICAL severity acknowledgement checklist in I00 (Chipset/Graphics/BthPan). See SPEC §D.28.
- **QI-9**: System Restore status warning in P01 (Chipset/Graphics/BthPan). See SPEC §D.26.2.D (now retained as historical context within the §D.30 deprecation narrative).
- **Q-X1**: NPU refuses Install / All on legacy Windows Server. See SPEC §D.27.

(QI-10 — `BootLoadableCheck` post-I02 — is intentionally absent from this list: the orchestrator and its `BootLoadableCheck` action were removed in r70, and the driver-side `Invoke-BootLoadableCheck` helper and post-I02 dispatcher hook were removed with them. See SPEC §D.30 for the rationale.)

### TC13.1 — Q-X1: NPU `-Action Install` on WS2019 must refuse before any destructive work

| Step | Setup | Expected outcome |
| --- | --- | --- |
| 1 | WS2019 (build 17763) host. Place `NPU_RAI1.6.1_314_WHQL.zip` next to the script. | — |
| 2 | Run `.\Deploy-AMDNpuDriverOnWindowsServer.ps1 -Action Install -OfflineZip ...` | P00 fires `Show-OperatingSystemDetail`, then immediately throws `NPU -Action Install refused on legacy Windows Server. See message above.` |
| 3 | Workspace is not modified; no certs are created; no WDAC policy is touched. | `Test-Path C:\Temp\Workspace_AMD-NPU` returns the previous state. |

### TC13.2 — Q-X1: NPU `-Action All` on WS2016 must refuse before any destructive work

Same as TC13.1 but on WS2016 (build 14393) with `-Action All`. Expected: the throw fires for both `Install` and `All`.

### TC13.3 — Q-X1: NPU `-Action PrepareVerify` on WS2019 must continue normally

| Step | Setup | Expected outcome |
| --- | --- | --- |
| 1 | WS2019 host. | — |
| 2 | Run `.\Deploy-AMDNpuDriverOnWindowsServer.ps1 -Action PrepareVerify -OfflineZip ...` | P00 completes without throw; P01–P09 run; V01–V05 run; no I-phases run. |

### TC13.4 — Q-X1: NPU `-Action Install` on WS2025 must run normally

WS2025 host. The refuse check does not fire (Test-IsLegacyWindowsServerOs returns false). Install proceeds as before r17.

### TC13.5 — QI-9: P01 prints System Restore status with SiPolicy.p7b exclusion caveat (SR disabled, default case)

| Step | Setup | Expected outcome |
| --- | --- | --- |
| 1 | Fresh WS2019 host (System Restore is OFF by default). | — |
| 2 | Run any of Chipset / Graphics / BthPan `-Action PrepareVerify`. | P01 finishes workspace creation, then prints: |
| | | `--- System Restore status (snapshot recommendation) ---` |
| | | `System Restore is DISABLED on the system drive` |
| | | `[!] You have NO automatic rollback path for driver-store regressions.` |
| | | `[IMPORTANT] System Restore does NOT capture WDAC boot policy.` |
| | | `C:\Windows\System32\CodeIntegrity\SiPolicy.p7b is excluded from System Restore by design.` |
| 3 | P01 completes normally; subsequent phases run. | The SR warning is informational only — it does NOT abort. |

### TC13.6 — QI-9: P01 prints System Restore status (SR enabled, recent checkpoint exists)

| Step | Setup | Expected outcome |
| --- | --- | --- |
| 1 | Workstation host (Win11) with SR enabled and a recent restore point. | — |
| 2 | Run Chipset `-Action PrepareVerify -AllowWorkstationInstall`. | P01 prints: |
| | | `System Restore is ENABLED on the system drive` |
| | | `Recent restore points (last 30 days): N` (where N > 0) |
| | | Still prints the `[IMPORTANT] SiPolicy.p7b is excluded` caveat. |

### TC13.7 — QI-9: P01 must NOT call Checkpoint-Computer automatically

Per Q9-A=b, the script should not create restore points automatically. Verify: after P01 completes, the count of restore points on the system drive is unchanged. (No regression of the deprecated Checkpoint-Computer behaviour that was withdrawn in §D.26.2.D.)

### TC13.8 — QI-6 C1: CRITICAL fires for display driver replacement on single-display host

| Step | Setup | Expected outcome |
| --- | --- | --- |
| 1 | Graphics script on a single-display host (laptop with only built-in panel). | — |
| 2 | Run `.\Deploy-AMDGraphicsDriverOnWindowsServer.ps1 -Action Install`. | I00 builds `$matched[]`, then `Get-CriticalRiskItem` finds C1 matches (display.inf candidate + single display). |
| 3 | I00 prints `[CRITICAL][C1] Display driver replacement on single-display host` with the C1 detail block. | The y/N prompt is presented: `I understand display loss is possible and have an alternative display path or remote access ready (y/N): ` |
| 4 | Operator types `N` and presses Enter. | I00 throws `CRITICAL risk item(s) not acknowledged. Aborting before I01.` |
| 5 | Re-run with `-ForceUnsafe`. | I00 prints the CRITICAL block but bypasses the prompt; `Set-DebugStep` records `CRITICAL bypass via -ForceUnsafe: items=C1`. |

### TC13.9 — QI-6 C2: CRITICAL fires for BitLocker ON + PSP driver replacement

| Step | Setup | Expected outcome |
| --- | --- | --- |
| 1 | WS2022 host with BitLocker enabled on `C:\`. Chipset install plan includes a PSP-family INF. | — |
| 2 | Run `.\Deploy-AMDChipsetDriverOnWindowsServer.ps1 -Action Install`. | I00 emits `[CRITICAL][C2] BitLocker ON + AMD PSP driver replacement` with the KeyProtector enumeration in the ack prompt. |
| 3 | Operator answers `y`. | I00 records the acknowledgement and proceeds to next item (or to I01 if C2 was the only item). |

### TC13.11 — QI-6 C5: CRITICAL fires after 24+ hour uptime

Verify: on a host that has not been rebooted in 25+ hours, `(Get-Date - LastBootUpTime).TotalHours -gt 24` is true and C5 is added to the items list with the uptime hours displayed.

### TC13.12 — QI-6 BthPan: only C5 evaluated (no C1/C2 because $matched is empty)

| Step | Setup | Expected outcome |
| --- | --- | --- |
| 1 | Any host (WS2022+ or legacy). | — |
| 2 | Run `.\Deploy-MSBthPanInboxOnWindowsServer.ps1 -Action Install`. | I00 passes `@()` to `Get-CriticalRiskItem`. C1 and C2 yield no items (empty $Matched). C5 may or may not fire depending on uptime. |
| 3 | The CRITICAL block contains C5 only (when applicable), no C1/C2. | — |

(TC13.10 — the original "QI-6 C3: same-session WDAC SPF cert stacking" test — was removed in r70. C3 inspected the orchestrator's `manifest.json` for cross-script cert deployment evidence, but the orchestrator and its manifest are gone after r70. See SPEC §D.28.1 for the historical rationale and SPEC §D.30 for the deprecation context. The r71 planned `C6` condition — "WHQL co-sign shortfall on a Secure-Boot-ON host" — will be tested in TESTING.md §14 once r71 ships.)

(TC13.13 – TC13.16 — the four "QI-10: BootLoadableCheck" tests — were also removed in r70. The driver-side `Invoke-BootLoadableCheck` helper, the post-I02 dispatcher hook, and the orchestrator's `BootLoadableCheck` action that those tests exercised were all deleted along with Path C. See SPEC §D.30.)

(Negative test — "orchestrator hash mismatch on disk" — was removed in r70. The driver scripts no longer reference an orchestrator, so the canonical-hash verification logic and the test that exercised it are both retired.)

---

## 14. Validation Scenario 14: r71 WHQL co-sign pre-detection + Path B prerequisite check + C6 + `-SkipNonCosignedDrivers` + r72 I02 short-circuit

### Status

Code-review validated only. The WS2019 + Renoir bench is queued for OS reinstall as of release time; physical replay is not possible. Test cases below describe what should be observed when the bench becomes available and r72 (`Chipset r72` / `Graphics r38` / `BthPan r20` / `NPU r18`) is replayed against it.

### Scope

This section covers the four r71 mechanisms documented in SPEC §D.31 and the one r72 follow-on documented in §D.31.11:

- **WHQL co-sign analysis** in P05 (`Test-WhqlCoSignature`, `New-WhqlCoSignAnalysis`, `Show-WhqlCoSignAnalysisReport`). See §D.31.2.
- **Path B prerequisite check** in I02 (`Invoke-PathBPrerequisiteCheck`, `Test-SecureBootEnabledFromFirmware`). See §D.31.3.
- **C6 CRITICAL acknowledgement** in I00 (`Get-CriticalRiskItem` extension). See §D.31.4.
- **`-SkipNonCosignedDrivers`** switch (`Get-EligibleInfRecordList`, P06 entry trim). See §D.31.5.
- **r72 I02 short-circuit** for all-WHQL trimmed plans. See §D.31.11. Covered by TC14.3, TC14.9, TC14.10, TC14.11.

### TC14.1 — WHQL analysis runs in P05 on WS2019 PrepareVerify

| Step | Setup | Expected outcome |
| --- | --- | --- |
| 1 | WS2019 (build 17763) host with WDK installed (signtool available). Place the AMD Chipset Driver installer zip next to the script. | — |
| 2 | Run `.\Deploy-AMDChipsetDriverOnWindowsServer.ps1 -Action PrepareVerify` | P05 completes the INF inventory, then prints `--- WHQL co-signature analysis ---` with three counts (Fully co-signed / Mixed / No WHQL co-signature). |
| 3 | Inspect `$Ctx.WhqlCoSignAnalysis` via the workspace-stored phase marker. | Array of pscustomobject; each entry has InfName, DriverFiles, CoSignedFiles, NonCoSignedFiles, IsFullyCoSigned, HasMixedSigning. |
| 4 | No I-phases run because PrepareVerify excludes them. C6 does not fire, Path B prerequisite check does not run, `-SkipNonCosignedDrivers` has no effect. | The run completes with the same V01–V06 output as before r71, plus the new WHQL summary block. |

### TC14.2 — Path B prerequisite ABORT on Secure Boot ON

| Step | Setup | Expected outcome |
| --- | --- | --- |
| 1 | WS2019 host with UEFI Secure Boot **ENABLED** in firmware. | — |
| 2 | Run `.\Deploy-AMDChipsetDriverOnWindowsServer.ps1 -Action Install -UseTestSigning` | I00 PreInstallReview completes (assume no C1/C2/C5/C6 fire for this scenario, or all are acknowledged). I01 succeeds. I02 enters the Path B branch. |
| 3 | I02 calls `Invoke-PathBPrerequisiteCheck`. `Confirm-SecureBootUEFI` returns `$true`. | The helper returns `Result=abort, Reason=secure-boot-on`. I02 prints the multi-line guidance block in red and throws `I02: Path B prerequisite not met (reason=secure-boot-on). Aborting before bcdedit is invoked.` |
| 4 | The host is unmodified: no `bcdedit /set TESTSIGNING ON` was attempted, no driver-store changes, no cert work. Re-running with `-Force` would bypass the check (intentionally less prominent in the message). | `bcdedit /enum {current}` shows testsigning unchanged. The patched-INF workspace exists (P-phases ran) but the host's boot policy is untouched. |

### TC14.3 — `-SkipNonCosignedDrivers` trims at P06 entry, C6 does not fire, r72 short-circuit fires at I02

| Step | Setup | Expected outcome |
| --- | --- | --- |
| 1 | WS2019 host with Secure Boot ON. AMD Chipset install set contains a mix of WHQL co-signed (e.g. AmdMicroPEP.sys, amdgpio2.sys) and non-WHQL (e.g. amdi2c.sys, amdsfhkmdf.sys) drivers. | — |
| 2 | Run `.\Deploy-AMDChipsetDriverOnWindowsServer.ps1 -Action Install -SkipNonCosignedDrivers` | P05 completes the WHQL analysis. P06 entry prints `--- r71: -SkipNonCosignedDrivers filter applied ---` with the before/after INF counts. After the trim, `$Ctx.WhqlCoSignAnalysis` retains only WHQL-co-signed INFs. |
| 3 | I00 PreInstallReview runs. `Get-CriticalRiskItem` evaluates C6. | C6 does NOT fire because `$Script:SkipNonCosignedDrivers` is `$true` (one of the four required AND conditions fails). C1/C2/C5 evaluate independently. |
| 4 | I02 entry: `Test-InstallPhaseAlreadyDone` returns `$false` (host has neither WDAC policy nor testsigning ON). The r72 short-circuit predicate evaluates: `-not $Ctx.UseTestSigning` (true) AND `$Script:SkipNonCosignedDrivers` (true) AND `$Ctx.WhqlCoSignAnalysis` populated (true) AND `$nonCoSignedAfterTrim.Count -eq 0` (true). | I02 prints `--- I02 short-circuit (r72): install plan is fully WHQL co-signed ---` and the rationale block. It writes the I02 phase marker with `Metadata=@{ ShortCircuit=$true; Reason='all-whql-skip'; AnalysedInfCount=<N> }` and emits `Write-PhaseFooter 'I02' 'short-circuit'`. The Path B prerequisite check is NOT invoked; no firmware ABORT occurs. |
| 5 | I03 runs normally. pnputil accepts the script-re-signed catalogs because the script's self-signing cert is in Trusted Publisher (from I01). | The WHQL-co-signed subset loads on the host with Secure Boot ON via the drivers' embedded Microsoft signatures. The non-WHQL subset was never patched (P06 trim removed it before P07/P08/P09). No WDAC supplemental policy file exists on disk; `bcdedit /enum {current}` shows testsigning unchanged. |

### TC14.4 — C6 fires on Secure-Boot-ON host with mixed install plan, no flags

| Step | Setup | Expected outcome |
| --- | --- | --- |
| 1 | WS2022 (build 20348) host with UEFI Secure Boot ON. AMD Chipset install set contains both WHQL and non-WHQL drivers. | — |
| 2 | Run `.\Deploy-AMDChipsetDriverOnWindowsServer.ps1 -Action Install` (no `-SkipNonCosignedDrivers`, no `-UseTestSigning`) | P05 WHQL analysis populates `$Ctx.WhqlCoSignAnalysis`. I00 evaluates C6. |
| 3 | C6 fires with `[CRITICAL][C6] WHQL co-sign shortfall on Secure-Boot-ON host (N non-co-signed INF(s))` listing up to 5 sample INFs. | The acknowledgement prompt asks: `I understand non-WHQL drivers will be kernel-CI-rejected at boot and accept this outcome (y/N): ` |
| 4 | Operator answers `N`. | I00 throws `CRITICAL risk item(s) not acknowledged. Aborting before I01.` No driver-store changes were made. |
| 5 | Re-run with `-SkipNonCosignedDrivers` OR `-UseTestSigning` (after disabling Secure Boot in firmware first per the C6 guidance text) OR `-ForceUnsafe` (audit-logged bypass). | The chosen escape route proceeds without C6 firing. |

### TC14.5 — Path B prerequisite "secure-boot-unknown" continues with warning

| Step | Setup | Expected outcome |
| --- | --- | --- |
| 1 | Constrained VM or legacy BIOS host where `Confirm-SecureBootUEFI` throws. | — |
| 2 | Run `.\Deploy-AMDChipsetDriverOnWindowsServer.ps1 -Action Install -UseTestSigning` | I02 calls `Invoke-PathBPrerequisiteCheck`. The helper catches the exception, returns `Result=ok, Reason=secure-boot-unknown`. |
| 3 | I02 prints the warning block as Write-Caution messages and continues to the existing legacy Secure Boot guard (which uses the OS-layer `$bootEnvBefore.SecureBootEnabled` view). | If both views agree on "off", Path B proceeds normally. If they diverge, the legacy guard fires. |

### TC14.6 — All-WHQL install plan: WHQL analysis is reported but no special branches fire

| Step | Setup | Expected outcome |
| --- | --- | --- |
| 1 | WS2025 (build 26100) host with a Chipset install set whose drivers are all WHQL co-signed (e.g. a release where AMD's INFs use only Microsoft-co-signed catalogs). | — |
| 2 | Run `.\Deploy-AMDChipsetDriverOnWindowsServer.ps1 -Action Install` | P05 prints `Fully WHQL co-signed INFs: N / Mixed: 0 / No WHQL: 0`. I00 evaluates C6; the predicate is `$nonCoSignedInfs.Count -gt 0` which is false, so C6 does not fire. |
| 3 | I02 runs the WDAC MPF Path A normally on WS2025. All drivers load. | Standard pre-r71 behaviour with one additional console block (the WHQL summary) and zero behavioural change. |

### TC14.7 — BthPan: WHQL analysis on the Microsoft inbox bthpan.inf

| Step | Setup | Expected outcome |
| --- | --- | --- |
| 1 | Any supported host (WS2022 / WS2025 since BthPan does not refuse on legacy Server as NPU does). | — |
| 2 | Run `.\Deploy-MSBthPanInboxOnWindowsServer.ps1 -Action PrepareVerify` | P05 builds a single-record WHQL analysis for `bthpan.inf`. The Microsoft inbox driver is WHQL co-signed; the report shows `Fully WHQL co-signed INFs: 1`. |
| 3 | Pass `-SkipNonCosignedDrivers`. | BthPan P06 entry prints `r71: -SkipNonCosignedDrivers set; bthpan.inf is WHQL co-signed by Microsoft. No trim needed.` and the run continues unchanged. |

### TC14.8 — `signtool absent` fallback: conservative classification

| Step | Setup | Expected outcome |
| --- | --- | --- |
| 1 | WS2019 host without the WDK installed; `Find-KitTool 'signtool.exe'` returns `$null`. Install set has a non-WHQL primary signer (typical for AMD's own publisher cert on non-co-signed drivers). | — |
| 2 | Run `.\Deploy-AMDChipsetDriverOnWindowsServer.ps1 -Action PrepareVerify` | `Test-WhqlCoSignature` falls back to the primary-signer-only check. Non-Microsoft primary signers are classified `Reason=self-only, IsCoSigned=$false`. |
| 3 | Inspect P05 output. | Conservative classification: the WHQL summary may over-report `No WHQL co-signature` on actually-co-signed drivers because nested signers are not visible. C6 may fire on Secure-Boot-ON hosts where it would not fire with signtool present. Operators with no WDK can either install signtool or accept the conservative outcome. |

### Negative test — `-ForceUnsafe` bypasses C6 with audit log entry

| Step | Setup | Expected outcome |
| --- | --- | --- |
| 1 | Any host where C6 would fire (mixed install plan + Secure Boot ON + no Skip / TestSigning). | — |
| 2 | Run with `-ForceUnsafe` added. | C6 (and any other CRITICAL items) appear in the console summary but the acknowledgement prompt is skipped. `Set-DebugStep` records the bypass with the comma-separated item ID list. |
| 3 | Inspect the debug trace JSONL stream. | A line containing `CRITICAL bypass via -ForceUnsafe: items=C6` (or with other IDs interleaved) is present. The audit anchor is preserved. |

### Negative test — TC14.3 follow-on: WS2019 with `-SkipNonCosignedDrivers` and the Path A fallback

**Historical note (pre-r72):** When `-SkipNonCosignedDrivers` was set on WS2019, the WDAC MPF Path A path could not run (legacy Server does not have CiTool.exe) and after the deprecation of Path C in r70, I02 fell through to Path B. Even though the install plan was fully WHQL co-signed (because Skip trimmed it), Path B's prerequisite check ABORTed on Secure Boot ON because the firmware state had not changed. SPEC §D.31.9 recorded this as a deferred follow-on refinement. The r72 release closes the gap with the I02 short-circuit documented in §D.31.11 and validated by TC14.3, TC14.9, TC14.10, and TC14.11 below.

### TC14.9 — r72 I02 short-circuit fires on WS2019 + Secure Boot ON + all-WHQL trimmed plan

| Step | Setup | Expected outcome |
| --- | --- | --- |
| 1 | WS2019 host with Secure Boot ON in firmware. AMD Chipset install set has at least one WHQL co-signed INF and at least one non-WHQL INF. | — |
| 2 | Run `.\Deploy-AMDChipsetDriverOnWindowsServer.ps1 -Action Install -SkipNonCosignedDrivers` | P05 emits the WHQL analysis. P06 entry trims `$Ctx.InfInventory` to the WHQL subset. I00 evaluates C6 — does not fire. I01 imports the script's self-signing cert into LocalMachine\Root + LocalMachine\TrustedPublisher. |
| 3 | I02 enters. `Test-InstallPhaseAlreadyDone -PhaseId 'I02'` returns false. `Set-DebugStep 'r72 short-circuit evaluation'` is recorded. The four-clause predicate evaluates as: `-not $Ctx.UseTestSigning=true` AND `$Script:SkipNonCosignedDrivers=true` AND `$Ctx.WhqlCoSignAnalysis.Count > 0` AND `$nonCoSignedAfterTrim.Count==0`. | The short-circuit fires. Console shows `--- I02 short-circuit (r72): install plan is fully WHQL co-signed ---` in green, then the rationale block. `Set-PhaseMarker -PhaseId 'I02' -Metadata @{ ShortCircuit=$true; Reason='all-whql-skip'; AnalysedInfCount=<N> }` is invoked. `Write-PhaseFooter 'I02' 'short-circuit'` closes the phase. |
| 4 | I03 runs unchanged. pnputil validates the script-re-signed catalogs against the cert chain (cert is in Trusted Publisher from I01). | All WHQL-co-signed drivers are installed and load via their embedded Microsoft signatures. No WDAC supplemental policy is written to `%SystemRoot%\System32\CodeIntegrity\CiPolicies\Active`. `bcdedit /enum {current}` shows testsigning unchanged. |
| 5 | After install completes, run `.\Deploy-AMDChipsetDriverOnWindowsServer.ps1 -Action Verify` | V-phases confirm drivers are installed and in Started state. Device Manager shows the WHQL-co-signed devices as `Status=OK`. |

### TC14.10 — r72 short-circuit fires uniformly on WS2022+ (OS-version-agnostic)

| Step | Setup | Expected outcome |
| --- | --- | --- |
| 1 | WS2022 (build 20348) or WS2025 (build 26100) host with Secure Boot ON. AMD Graphics install set contains a mix of WHQL and non-WHQL INFs. | — |
| 2 | Run `.\Deploy-AMDGraphicsDriverOnWindowsServer.ps1 -Action Install -SkipNonCosignedDrivers` | P05 / P06 / I00 / I01 behave as on WS2019 (P06 trim, no C6, cert import). |
| 3 | I02 entry. On WS2022+ the host has CiTool available, so a non-short-circuit run would have taken Path A and deployed a WDAC supplemental policy. With the r72 short-circuit, the four-clause predicate still holds and the short-circuit fires. | The console output is identical to TC14.9 step 3. No WDAC supplemental policy file is created on disk — even though the WS2022+ Path A would otherwise have created one. This is the intentional OS-version-uniform behaviour documented in SPEC §D.31.11.6. |
| 4 | Inspect `Get-CIPolicy -Online` or `%SystemRoot%\System32\CodeIntegrity\CiPolicies\Active`. | No script-deployed `.cip` file appears. (Existing OS-default policies are untouched; the short-circuit does not remove anything.) Drivers load via WHQL embedded signatures. |

### TC14.11 — Resume-after-reboot: short-circuit marker does NOT trap subsequent runs that drop `-SkipNonCosignedDrivers`

| Step | Setup | Expected outcome |
| --- | --- | --- |
| 1 | Any supported host. Workspace already contains a successful run from TC14.9 or TC14.10 (I02 phase marker has `Metadata.ShortCircuit=$true`). Driver state on host: WHQL drivers installed; no WDAC supplemental policy; no testsigning. | — |
| 2 | Re-run the script WITHOUT `-SkipNonCosignedDrivers`: `.\Deploy-AMDChipsetDriverOnWindowsServer.ps1 -Action Install` | P05 re-runs the WHQL analysis on the (now broader) install plan. P06 does NOT trim (Skip flag absent). I00 evaluates C6 with the un-trimmed analysis. |
| 3 | I02 entry. `Test-InstallPhaseAlreadyDone -PhaseId 'I02'` inspects HOST STATE (`Test-AmdWdacPolicyDeployed` and the BCD testsigning value), not the phase marker. Neither host-state predicate holds, so it returns `$false`. The phase enters its main body. | The r72 short-circuit predicate's clause 2 (`$Script:SkipNonCosignedDrivers`) is now `$false`, so the short-circuit does NOT fire. I02 proceeds with the standard Path A / Path B evaluation. The fact that a prior run wrote a short-circuit marker does not trap this new run. |
| 4 | On WS2022+, Path A deploys the WDAC supplemental policy normally. On WS2019, Path B prerequisite check runs (and ABORTs if Secure Boot ON, or proceeds to set testsigning if OFF). | The re-run is exactly equivalent to a first-time run on a host that happens to already have I01 trust-store import done — no surprise trapping behaviour. |
| 5 | Inspect the workspace's `phase-markers.json` (or equivalent). | The new I02 marker (Path A or Path B success) replaces the prior `ShortCircuit=$true` marker. The diagnostic history is not lost — operators inspecting the previous run's transcript still see the short-circuit invocation; only the current workspace state reflects the most recent outcome. |

### TC14.12 — `$Ctx.WhqlCoSignAnalysis` property-declaration smoke test (PSA2009 static-analysis gate)

Added with the Chipset r73 / Graphics r39 / BthPan r21 release as the static-analysis gate that prevents recurrence of the Chipset r72 P05 hard-failure defect. This test does NOT require a Windows host — it runs purely on the developer / CI machine via Python 3 and the canonical `psa.py` 3.8.0 (or newer) artifact.

| Step | Setup | Expected outcome |
| --- | --- | --- |
| 1 | Working tree at the current mainline of `Deploy-Drivers-For-WindowsServer`. Python 3.8+ installed. Fetch the canonical analyzer: `curl -sSL https://raw.githubusercontent.com/usui-tk/ai-generated-artifacts/main/quality-tools/powershell-static-analyzer/psa.py -o /tmp/psa.py` (and the sibling `VERSION` file). Confirm `python3 /tmp/psa.py --version` reports `psa.py 3.8.0` or later. | — |
| 2 | Run `python3 /tmp/psa.py --include PSA2009 --no-color Deploy-AMDChipsetDriverOnWindowsServer.ps1`. | `Issues : 0 errors, 0 warnings, 0 info` followed by `(no issues found)`. The exit code is 0. |
| 3 | Run `python3 /tmp/psa.py --include PSA2009 --no-color Deploy-AMDGraphicsDriverOnWindowsServer.ps1`. | Same as step 2. |
| 4 | Run `python3 /tmp/psa.py --include PSA2009 --no-color Deploy-AMDNpuDriverOnWindowsServer.ps1`. | Same as step 2. (NPU does not use `[pscustomobject]@{...}` for its `$Ctx` and is exempt from the WHQL producer-consumer contract; the rule still scans the file and finds zero violations.) |
| 5 | Run `python3 /tmp/psa.py --include PSA2009 --no-color Deploy-MSBthPanInboxOnWindowsServer.ps1`. | Same as step 2. |
| 6 | (Regression replay only — do not run on the current mainline). Check out the r72 / r38 / r18 / r20 baseline (i.e., the immediate predecessor of this release) and re-run steps 2–5. | Step 2 (Chipset) reports `Issues : 0 errors, 2 warnings, 0 info` with both warnings pointing at the P05 happy-path assignment line and the `catch`-block fallback line for `$Ctx.WhqlCoSignAnalysis`. Step 5 (BthPan) reports the same. Steps 3 and 4 (Graphics, NPU) report `0 warnings`. This replay confirms that PSA2009 would have caught the historical defect at static-analysis time, and that the current mainline closes the regression. |

CI integration: this test case is the recommended gate for any pre-commit hook or CI pipeline that wants to prevent recurrence of the `[pscustomobject]` sealed-object defect class. Adding `--include PSA2009` to the existing full-rule invocation is redundant but harmless (PSA2009 is on by default at warning severity in psa.py 3.8.0+).

### TC14.13 — Graphics P05 emits the WHQL co-signature analysis summary banner (r39 producer-site smoke test)

Added with the Graphics r39 release to verify that the historical producer-site gap (r37 / r38 shipped consumers but no producer) is closed. The test requires a Windows host with a real Adrenalin INF set extracted into the workspace — the Adrenalin 26.5.2 Vega-Polaris Legacy run already validated under TC10.x is the canonical reference.

| Step | Setup | Expected outcome |
| --- | --- | --- |
| 1 | Windows Server 2019 / 2022 / 2025 host with Adrenalin 26.5.2 Vega-Polaris Legacy (or a comparable Adrenalin package) cached. Run `.\Deploy-AMDGraphicsDriverOnWindowsServer.ps1 -Action PrepareVerify -CleanWorkRoot`. | P05 runs normally; the inventory CSV and TXT are written to the workspace. |
| 2 | Inspect the P05 phase transcript section. Look for the new three-line WHQL summary banner: `--- WHQL co-signature analysis ---` followed by `Fully WHQL co-signed INFs : <N>`, `Mixed-signing INFs (partial): <M>`, `No WHQL co-signature : <P>`. | The banner is present immediately before the `PHASE P05 -> DONE` footer. Prior to r39 this banner was missing entirely on the Graphics script. |
| 3 | Inspect `$Ctx.WhqlCoSignAnalysis` via the workspace-stored phase marker (`%WorkRoot%\markers\P05-*.json` or equivalent). | The marker's `Metadata` section now includes the WHQL analysis result count. Prior to r39 the field was absent (because the producer never ran). |
| 4 | Re-run with `-SkipNonCosignedDrivers`: `.\Deploy-AMDGraphicsDriverOnWindowsServer.ps1 -Action PrepareVerify -SkipNonCosignedDrivers -CleanWorkRoot`. | P06 entry now emits the `r71: -SkipNonCosignedDrivers filter applied` banner with a concrete trim count (or the "already fully WHQL co-signed" message if Adrenalin happens to be fully co-signed). Prior to r39 the filter was a silent no-op on Graphics because `$Ctx.WhqlCoSignAnalysis` was never populated. |
| 5 | Re-run with `-Action All` on a Secure-Boot-ON host with mixed-signing Adrenalin: `.\Deploy-AMDGraphicsDriverOnWindowsServer.ps1 -Action All`. | I00 §C6 ("WHQL co-sign shortfall on Secure-Boot-ON host") now fires (or correctly does not fire if Adrenalin is fully WHQL co-signed). Prior to r39, C6 was unreachable on Graphics because its `$hasAnalysis` precondition was always false. |

This test case is a runtime acceptance test (not a static-analysis test); it complements TC14.12's static gate by verifying that the wiring actually works end-to-end on real Adrenalin packaging.

---

## 15. Validation Scenario 15: Chipset r73 / Graphics r39 / BthPan r21 — `$Ctx.WhqlCoSignAnalysis` pre-declaration fix + Graphics WHQL producer port

This scenario records the field-reported defect that triggered the Chipset r73 / Graphics r39 / BthPan r21 release on 2026-05-23, together with the static-analysis hardening that closes the defect class going forward.

### 15.1 Field report

**Reporter**: end-user.
**Environment**: clean-installed Windows Server 2019 Datacenter (build 17763), ja-JP locale, shift_jis (cp932) console encoding, PowerShell 5.1.17763.8755 Desktop, ConsoleHost. AMD Ryzen 5 PRO 4650U with Radeon Graphics, mobile FP6-series BGA (Zen 2 / Renoir). UEFI firmware in GPT mode, Secure Boot OFF (legacy posture). System Restore disabled (default on Server SKUs). No prior workspace.
**Command**: `.\Deploy-AMDChipsetDriverOnWindowsServer.ps1 -Action PrepareVerify -CleanWorkRoot` at script version `chipset-2026.05.23-r72` (script tag `legacy-ws2019-wdac-spf-integration`, SHA256 first-12 `a580af9da833`).
**Outcome**: PHASE P05 transitioned to FAILED at `+6.42s` into the phase with the localised exception:

```
[X] P05 [AnalyzeInfs] failed: "WhqlCoSignAnalysis" の設定中に例外が発生しました:
"このオブジェクトにプロパティ 'WhqlCoSignAnalysis' が見つかりません。
プロパティが存在し、設定可能であることを確認してください。"
```

The stack trace pointed at line 8470 column 9 of the r72 source, which is the `catch`-block fallback assignment `$Ctx.WhqlCoSignAnalysis = @()`. The two warning lines emitted immediately before the failure (`r71: WHQL co-sign analysis failed: 指定された名前のパラメーターを使用してパラメーター セットを解決できません。` and `r71: I00 C6 condition and -SkipNonCosignedDrivers will operate on an empty analysis.`) were the script's own diagnostic narration from inside the same `catch` block — the initial exception inside the `try` block was a *different* defect (a `param`-binding failure in a downstream signtool helper) that the `catch` block correctly intercepted; the failure that aborted P05 was the `catch`-block fallback itself attempting to assign to a non-existent property.

The P04 extraction had already completed successfully (downloaded `amd_chipset_software_8.05.04.516.exe`, 76.5 MB; extracted via InstallShield admin-install chain; 117 INF files harvested; preferred variant `WTx64` selected; 60 INFs eligible for patching) and P05 had completed its inventory-CSV and inventory-TXT writes. The failure point was purely the WHQL-analysis production block at the end of P05, immediately before `Set-PhaseMarker`.

### 15.2 Root-cause analysis

Three nested defects:

1. **Inner defect (the trigger)** — The signtool helper `Test-WhqlCoSignature` (or one of its downstream helpers) raised a localised `指定された名前のパラメーターを使用してパラメーター セットを解決できません。` (English: "Cannot resolve parameter set with the specified named parameters") at parameter-binding time on this host. The exact site is not material to the P05 failure because the `try` block was specifically designed to catch this class of helper-side failure.
2. **Middle defect (the actual failure)** — The `catch` block was designed to write `$Ctx.WhqlCoSignAnalysis = @()` as a graceful-degradation sentinel. Because the `[pscustomobject]@{...}` `$Ctx` initialiser at the top of the r71 / r72 script does NOT include `WhqlCoSignAnalysis = $null`, the `catch` block's own assignment raises a SECOND terminating exception (the localised property-not-found message). This second exception is NOT caught by the same `try/catch` (the `catch` block is the one raising it) and propagates to the phase runner, which records P05 as FAILED.
3. **Outer defect (the silent regression)** — The same defective initialiser is shared between Chipset r72 and BthPan r20. Graphics r38 has a different but equally severe defect: the entire P05 WHQL-analysis production block is missing, so `$Ctx.WhqlCoSignAnalysis` remains at its (implicit, undeclared) `$null` value, every consumer site silently degrades to its fallback path, and the user never sees a runtime error — they just don't get the WHQL pre-detection benefit at all.

### 15.3 Why no existing static-analysis rule caught this

The `psa.py` v3.7.0 rule catalog (36 rules) did not include a check for "PSCustomObject property assigned without prior declaration". PSScriptAnalyzer's equivalent (`Invoke-ScriptAnalyzer`) also does not include such a rule. The defect is therefore detectable only by:

- **Runtime execution on a host that traverses the affected phase** (which is exactly how the user discovered it — they hit it on their first `-Action PrepareVerify` run).
- **A new static-analysis rule** that models the PSv5 sealed-object semantic specifically. This is what `psa.py` v3.8.0's new PSA2009 rule does. The rule was developed as part of the r73 / r39 / r21 fix work; see SPEC §A.11.5c for the rule documentation and §D.31.16 for the broader checklist applied to future `$Ctx.<NewField>` integrations.

The defect went undetected for two prior revisions (r71 introduced it on 2026-05-23, r72 hardened the I02 short-circuit on the same day but did not touch the initialiser) because:

- The project's CI matrix did not include a `PrepareVerify` run on WS2019 with the cleanest-possible workspace (no cached tools, fresh download, fresh extraction). The defect needs the `try`-block's inner failure to fire in order to reach the `catch`-block's outer failure; on hosts with cached signtool the inner failure does not fire reliably.
- The project's static-analysis baseline (`psa.py` --config .psa.config.json) reported 0 errors / 0 warnings / 0 info on r72, which appeared to confirm clean-baseline status. The defect was below the rule catalog's detection floor.

### 15.4 Repair scope and verification

The r73 / r39 / r21 release applies the following changes:

| Script | Change | Verification |
| --- | --- | --- |
| Chipset r73 | Add `WhqlCoSignAnalysis = $null` to the `$Ctx` initialiser with a multi-line explanatory comment cross-referencing SPEC §D.31 and PSA2009. | `psa.py --include PSA2009` reports 0 findings (was 2). Re-running TC10.x WS2019 PrepareVerify scenario completes P05 with the WHQL summary banner present. |
| Graphics r39 | Add `WhqlCoSignAnalysis = $null` to `$Ctx` (same shape as Chipset). Port the P05 WHQL-analysis production block from Chipset r71 (~17 lines, byte-identical except for revision-tag comments rephrased to `r39`). | `psa.py --include PSA2009` reports 0 findings (was 0; Graphics had the producer-gap defect, not the initialiser defect). New TC14.13 verifies the producer-site banner appears at runtime. |
| BthPan r21 | Add `WhqlCoSignAnalysis = $null` to `$Ctx` (same shape as Chipset). | `psa.py --include PSA2009` reports 0 findings (was 2). Re-running the bthpan flow completes P05 with the synthetic-record WHQL analysis. |
| NPU r18 | No change. NPU's `$Ctx` does not exercise `WhqlCoSignAnalysis`. | `psa.py --include PSA2009` reports 0 findings (was 0). Per SPEC §A.7 ("no empty revisions"), NPU is NOT bumped. |
| `psa.py` v3.7.0 → v3.8.0 | New rule PSA2009. | All four scripts report 0 findings at the new baseline. The r72 / r38 / r18 / r20 regression-replay (TC14.12 step 6) reproduces 2 + 0 + 0 + 2 findings, confirming the rule would have caught the defect at static-analysis time. |

### 15.5 Lessons learned (for future field-incident reports)

1. **Initial diagnosis must start with the script version recorded in the operator's transcript**, not with the current mainline. The r72 transcript line `chipset-2026.05.23-r72/a580af9da833` was the entry point; the fix branch is bumped to r73 to make the relationship explicit.
2. **A failed `catch` block is harder to debug than a failed `try` block** because the operator's transcript shows the `catch` block's own narration before the actual failure surfaces. Always read the FINAL exception in the transcript, then walk backward.
3. **PowerShell 5.1 sealed-object semantics are a recurring footgun**. The `[pscustomobject]@{...}` accelerator is the strictest form available in PSv5 and the project uses it intentionally to surface integration defects loudly — but the strictness backfires when the surfaced error is itself inside a `catch` block. SPEC §D.31.16 codifies the checklist that prevents this from recurring; PSA2009 is the static-analysis gate that mechanically enforces it.
4. **A clean static-analysis baseline is necessary but not sufficient.** The r72 baseline was clean under `psa.py` v3.7.0 and still shipped the defect. Adding new rules (when a defect class is identified) is the correct response — see SPEC §A.11 ("Static Analysis with psa.py") for the canonical artifact-versioning workflow that this release exercised.

---

## 16. r74 / r40 / r22 release validation (2026-05-24, Renoir + WS2019)

This section records the test scenarios that close the four r74 defects documented in SPEC §D.32. The bench host is the same one used for §15 (clean-installed Windows Server 2019 Datacenter, build 17763, ja-JP, PowerShell 5.1.17763.8755 Desktop, ConsoleHost, AMD Ryzen 5 PRO 4650U / Renoir, UEFI / GPT, Secure Boot OFF, no prior workspace, no BitLocker).

### 16.1 Field report

**Reporter**: end-user.
**Environment**: identical to §15.1 except the host had a prior `r73` install run completed and rebooted before the diagnostic snapshot was taken; testsigning ON, 5 AMD chipset devices on script-installed drivers.
**Command**: `.\Deploy-AMDChipsetDriverOnWindowsServer.ps1 -OnlyPhases V06` at script version `chipset-2026.05.23-r73`.
**Outcome**: V06 reported `[A]=36 [B]=5 [C]=0 [?]=1` and "Match summary: 2 device(s) WILL be replaced" — both incorrect on a freshly-installed-and-rebooted host. The diagnostic pre-reboot snapshot also surfaced that `Test-WhqlCoSignature` had been returning conservative `self-only` for every `.sys` file across the entire r71–r73 lifetime (the silent degradation documented in §D.32.2).

The user's report contained four artefacts that were critical to triage:
1. `CONSOLIDATED_REPORT.txt` (statement of work + raw signtool output for each staged `.sys`).
2. `12_pre-reboot-amd-driver-bindings.csv` (showed `IsSigned=False` for all script-installed drivers, expected for self-signed kernel drivers).
3. `13_pre-reboot-bcd.txt` (`testsigning Yes` plus the surprising `displaymessageoverride Recovery` value — later determined to be the WS2019 default).
4. The full `-Action Install` transcript that revealed I02 → I03 ran in the same execution despite the "reboot then re-run" message (Defect 4).

### 16.2 Test cases

#### TC16.1 — `Test-WhqlCoSignature` returns `cosigned` for a known WHQL-co-signed file (positive)

| Step | Action | Expected |
|---|---|---|
| 1 | Cherry-pick a Windows-inbox `.sys` known to be WHQL co-signed (e.g. `C:\Windows\System32\drivers\bthpan.sys`) into a temp directory. Install WDK 10 so `signtool.exe` is on PATH. | — |
| 2 | Dot-source the patched `Test-WhqlCoSignature` body or run the script's P05 against an INF that references this file. | `Test-WhqlCoSignature` returns `IsCoSigned=$true`, `Reason='cosigned'`, `WhqlMarker` non-empty. |
| 3 | Re-run with `Find-KitTool 'signtool.exe'` returning `$null` (no WDK). | Returns `IsCoSigned=$false`, `Reason='self-only'`. This is the conservative fallback documented in §D.32.2. |

#### TC16.2 — `Test-WhqlCoSignature` returns `self-only` for AmdMicroPEP.sys from chipset 8.05.04.516 (negative)

| Step | Action | Expected |
|---|---|---|
| 1 | After a successful `r74 Install` on the bench host, locate `C:\Windows\System32\DriverStore\FileRepository\amdmicropep.inf_amd64_*\AmdMicroPEP.sys`. | — |
| 2 | Dot-source and call `Test-WhqlCoSignature -Path <path>`. | Returns `IsCoSigned=$false`, `Reason='self-only'`. Confirms §D.32.3 finding that chipset 8.05.04.516 dropped the WHQL co-signature. |

#### TC16.3 — V06 on a freshly-installed host reports `[C]>0` for script-installed devices

| Step | Action | Expected |
|---|---|---|
| 1 | On the bench host, after a successful `r74 Install` + reboot, run `.\Deploy-AMDChipsetDriverOnWindowsServer.ps1 -OnlyPhases V06`. | — |
| 2 | Inspect the `Driver-source distribution among AMD HARDWARE:` line. | `[C]>0` for the 5 devices the script installed (chipset). On Graphics, the count is package-specific; on BthPan, V06 does not exercise Get-DriverSourceCategory and this TC is N/A. |
| 3 | Inspect Section 2 `Match summary:` line. | `0 device(s) WILL be replaced` (idempotent) on a clean install + reboot. If `>0`, V06 still flagged a legitimate replacement target — verify against the install plan to confirm. |

#### TC16.4 — V06 on a re-run after a successful install is idempotent

| Step | Action | Expected |
|---|---|---|
| 1 | After TC16.3, run `-Action Install` a second time (no flags). | I00 detects all phases in target state, I02 is cached, I03 hits "all patched INFs already in driver store" cached path, I04 reports the same disposition as TC16.3 step 2. |
| 2 | No driver is replaced. No `REBOOT_REQUIRED` lines appear. | — |

#### TC16.5 — `-Action Install` on a host with `testsigning OFF` halts after I02

| Step | Action | Expected |
|---|---|---|
| 1 | Boot a clean-installed WS2019 host (testsigning OFF in BCD). Secure Boot OFF in firmware so Path B is available. | — |
| 2 | Run `-Action PrepareVerify -CleanWorkRoot` then `-Action Install`. | P00–P09, V01–V06 complete normally. I00 reviews. I01 imports cert. I02 sets BCD testsigning ON. |
| 3 | I02 footer | `PHASE I02 -> DONE`. The next message line is the `*** A REBOOT IS REQUIRED ***` block (unchanged from r73). |
| 4 | I03 entry | Prints `I03: halting because I02 just enabled testsigning in this run.` followed by the 3-step operator workflow. Footer is `PHASE I03 -> halted-pending-reboot`. |
| 5 | I04 entry | Same halt body. Footer is `PHASE I04 -> halted-pending-reboot`. |
| 6 | Workspace markers | I02 marker is written; I03 / I04 markers are NOT written. PendingRebootMarker is written. |
| 7 | RUN SUMMARY | `Phases run` shows `P00 -> P01 -> I00 -> I01 -> I02 -> I03 -> I04`. Phase timings table shows I03 / I04 with `halted-pending-reboot` status. |

#### TC16.6 — Re-run after the reboot proceeds normally

| Step | Action | Expected |
|---|---|---|
| 1 | After TC16.5, reboot the host. Test Mode watermark appears. | — |
| 2 | Re-run `-Action Install` (same command). | `$Ctx.RebootRequiredBeforeI03` starts as `$false` (per-process, NOT persisted). |
| 3 | I02 entry | Hits the cached "already on" branch. Footer is `cached`. |
| 4 | I03 entry | Does NOT halt. Stages drivers normally. |
| 5 | I04 entry | Does NOT halt. Runs the post-install verification normally. |
| 6 | I04 functional-health probe | Reports actual driver-load state. PendingRebootMarker is cleared by I04. |

### 16.3 Static analysis posture for r74

The r74 release adds no new `psa.py` rule. The four r74 defects (per SPEC §D.32) are all integration-level defects that local-form analysis cannot detect. A planned `psa.py` v3.9.0 rule **PSA2010 — invocation of undefined function** would catch Defect 1 (`Find-Signtool`) at static-analysis time, but the rule needs the full function-definition table across all four scripts simultaneously, which is a structural change to the analyzer. PSA2010 is tracked as future work.

### 16.4 Regression risk

| Risk | Mitigation |
|---|---|
| `signtool verify /all` produces unexpectedly verbose output that breaks the `Issued to:` regex. | `/all` adds nested-signature blocks but the per-signer `Issued to:` line format is unchanged across signtool 6.0–10.0.x. Verified against signtool 10.0.26100.0 (the version this repository's `Find-KitTool` resolves to). |
| `$ourInfSet` build at V06 entry is slow on hosts with many oem*.cat files. | The same build runs in I04 already and has been stable since r60. V06's invocation reuses the helper unchanged. |
| `$Ctx.RebootRequiredBeforeI03` is added but not removed on `-CleanWorkRoot`. | The flag is per-process. `-CleanWorkRoot` rebuilds `$Ctx` from scratch, so the flag is implicitly absent in the next run. The flag is also explicitly NOT persisted to disk (per §D.32.5 design rationale). |
| Operator runs `-OnlyPhases I03,I04` skipping I02. | I03 / I04 do not check `RebootRequiredBeforeI03` against `$Ctx.UseTestSigning` — they trust the flag. If I02 was not run in this session, the flag is `$null`/`$false` and I03 / I04 proceed as before. This is the intended behavior. |

### 16.5 Lessons learned (additions to §15.5)

5. **Helper functions referenced by name but never defined are not caught by `psa.py`.** This is a structural blind spot the project lived with from r71 to r73. PSA2010 (planned, v3.9.0) is the static-analysis answer. Until then, a manual `grep -E '\bFind-[A-Z][a-zA-Z]+' *.ps1` cross-check against `grep -E '^function Find-[A-Z]'` is the recommended pre-commit gate.
6. **External-tool flag changes (e.g., signtool's `/all`) are easy to miss in code review** because the call site looks unchanged. The countermeasure is to inline the rationale for every flag (the r74 helper comment explicitly enumerates `/all`, `/pa`, `/v` and what each does) so future readers do not silently re-remove a flag they think is unused.
7. **V06 / I04 share the `Get-DriverSourceCategory` consumer surface but have asymmetric `Get-OurSignedOemInfSet` producer sites.** Any future helper that depends on a one-time-per-phase build SHOULD be invoked at the same site in BOTH V06 and I04 unless there is a documented reason not to. The r74 V06 fix codifies this pattern.

---

## 17. r75: 2026-05-25 WS2019 ja-JP + Renoir test scenarios (Defect A / B / C)

This section is the test-scenario counterpart of SPEC.md §D.33. The r75 release fixes three defects revealed by a clean-bench cycle on 2026-05-24/25 against a Windows Server 2019 Datacenter ja-JP host (build 17763.8755, PowerShell 5.1.17763.8755) with AMD Ryzen 5 PRO 4650U "Renoir" silicon. The diagnostic evidence captured during that cycle lives in two operator-side logs that this section references throughout:

- `diag-r40-followup-v2-20260524-111804.log` (347 lines) — the v2 diagnostic with Step 1.7 (Split-Path direct probe) and Steps 2.8a/b/c (CatRoot enumeration).
- `pre-reinstall-snapshot-20260524-113102.log` — the final state snapshot taken after the MSBthPan installation but before the next bench-cycle clean-install.

Both logs are kept in the bench's operator archive (not committed to this repository); the relevant excerpts are reproduced inline in each TC below.

### TC17.1 — Defect A direct probe (Split-Path -LiteralPath -Parent fails on PS 5.1 ja-JP)

**Purpose**: Confirm that the operator-visible warning `指定された名前のパラメーターを使用してパラメーター セットを解決できません。` from r71–r74 P05 was the `Split-Path` AmbiguousParameterSet bug, independent of the `Find-Signtool` typo that §D.32.2 misdiagnosed as the cause.

**Setup**: A clean-installed Windows Server 2019 Datacenter ja-JP host, build 17763.8755, with PowerShell 5.1.17763.8755 (the in-box `powershell.exe`, not pwsh 7.x). Any directory path is fine for the probe; `C:\Windows\System32\notepad.exe` is recommended for being a known-good file with a known parent.

**Procedure**:

```powershell
$p = 'C:\Windows\System32\notepad.exe'

# Form 1 — the r74 form (expected to fail on PS 5.1 ja-JP)
try {
    $r1 = Split-Path -LiteralPath $p -Parent
    Write-Host "[OK] Form 1: $r1"
} catch {
    Write-Host "[FAIL] Form 1: $($_.FullyQualifiedErrorId)"
}

# Form 2 — the r75 alternative (Split-Path -Path positional)
$r2 = Split-Path -Path $p -Parent
Write-Host "[OK] Form 2: $r2"

# Form 3 — the r75 chosen fix (.NET method, no PS binder)
$r3 = [System.IO.Path]::GetDirectoryName($p)
Write-Host "[OK] Form 3: $r3"
```

**Expected output (on a failing PS 5.1 ja-JP host)**:

```
[FAIL] Form 1: AmbiguousParameterSet,Microsoft.PowerShell.Commands.SplitPathCommand
[OK] Form 2: C:\Windows\System32
[OK] Form 3: C:\Windows\System32
```

**Reference**: `diag-r40-followup-v2-20260524-111804.log` Step 1.7 captured this exact pattern; Form 1's `FullyQualifiedErrorId` field reads `AmbiguousParameterSet, Microsoft.PowerShell.Commands.SplitPathCommand` (cmdlet identified directly by the binder).

**Pass criteria**: Form 1 fails with `AmbiguousParameterSet`. Forms 2 and 3 succeed and return the same string. On PowerShell 7.x or PS 5.1 en-US, Form 1 may succeed — this is expected (the defect is locale-and-build-specific) and does NOT contradict the r75 fix being necessary for ja-JP.

### TC17.2 — Defect A consumer-side (Get-InfDriverFileList returns non-empty after the fix)

**Purpose**: Confirm that `Get-InfDriverFileList` — the consumer of the line fixed in TC17.1's Form 3 — returns the expected `.sys` file list at the r75 baseline.

**Setup**: After installing Chipset r75 (or Graphics r41) with `-Action PrepareVerify`, the patched INF and `.sys` files are present in `<workspace>\patched\<InfBase>\`. Pick any one INF that has been patched.

**Procedure**:

```powershell
# Load r75's Chipset script (without running its main entry point)
. .\Deploy-AMDChipsetDriverOnWindowsServer.ps1 -SkipMain

$patchedInf = "<workspace>\patched\<InfBase>\AMD_Chipset_Drivers.inf"  # adjust path
$result = Get-InfDriverFileList -InfPath $patchedInf
Write-Host "Returned $($result.Count) file(s):"
$result | ForEach-Object { Write-Host "  $_" }
```

**Pass criteria**: At least one `.sys` file is returned. At the r74 baseline (without the Defect A fix), this same procedure returns an empty array on PS 5.1 ja-JP because `Get-InfDriverFileList`'s outer `try/catch` swallows the AmbiguousParameterSet exception silently. At the r75 baseline, the array contains the actual driver binaries.

### TC17.3 — Defect B Pass 1a (CatRoot scan finds the expected catalog set)

**Purpose**: Confirm that `Get-OurSignedOemInfSet` Pass 1a successfully enumerates `oem*.cat` files signed with the script's self-signed cert from `C:\Windows\System32\CatRoot\{F750E6C3-38EE-11D1-85E5-00C04FC295EE}\`.

**Setup**: A clean-installed WS2019 host with Chipset r75 or Graphics r41 freshly installed (the script's cert thumbprint is recorded in the workspace `.psd1` and the catalogs are physically present on disk).

**Procedure**:

```powershell
# Pre-check: how many oem*.cat files exist at the new CatRoot location?
$catRoot = 'C:\Windows\System32\CatRoot\{F750E6C3-38EE-11D1-85E5-00C04FC295EE}'
Write-Host "CatRoot oem*.cat count: $(@(Get-ChildItem -LiteralPath $catRoot -Filter 'oem*.cat').Count)"

# Pre-check: how many oem*.cat files exist at the r74 (wrong) location?
$infDir = "$env:windir\INF"
Write-Host "C:\Windows\INF oem*.cat count: $(@(Get-ChildItem -LiteralPath $infDir -Filter 'oem*.cat' -ErrorAction SilentlyContinue).Count)"

# Run the r75 helper directly
. .\Deploy-AMDChipsetDriverOnWindowsServer.ps1 -SkipMain
$ctx = Get-WorkspaceContext  # or however the script exposes it
$set = Get-OurSignedOemInfSet -ExpectedThumbprint $ctx.CertThumbprint
Write-Host "Helper returned $($set.Count) entries:"
$set.Keys | Sort-Object | ForEach-Object { Write-Host "  $_" }
```

**Pass criteria**: On a host that has Graphics r41 installed with the v2-diagnostic cert thumbprint `9FEB313999B8314D5B38744255A20C0A15648E2E`, the CatRoot pre-check reports **18 of 18 expected Graphics catalogs**, the `C:\Windows\INF\` pre-check reports **0**, and the helper's return-set count is non-zero (the exact size depends on how many INFs and OEM-aliases the cert covers). On a host that has additionally been through MSBthPan r23 (cert thumbprint `A0B563EAB490458B9CD4A920974C5EF27915E103`), the BthPan-cert call returns at least 1 entry.

**Reference**: `diag-r40-followup-v2-20260524-111804.log` Steps 2.8a/b/c performed exactly this enumeration on the bench host and recorded the 0 / 18 / 18 split (`C:\Windows\INF\` empty, CatRoot full, DriverStore\FileRepository full).

### TC17.4 — Defect B Pass 1b (pnputil Signer Name fallback when CatRoot is unreachable)

**Purpose**: Confirm that when Pass 1a finds 0 matches (CatRoot unreadable or empty), the new Pass 1b — pnputil `/enum-drivers` Signer Name lookup — populates the same set via the cert's Subject CN.

**Setup**: A clean-installed WS2019 host with Graphics r41 installed. To simulate "CatRoot unreachable", temporarily rename the CatRoot subfolder:

```powershell
# WARNING: This is invasive — only run on a disposable bench VM, then revert.
$catRoot = 'C:\Windows\System32\CatRoot\{F750E6C3-38EE-11D1-85E5-00C04FC295EE}'
$tempBak = $catRoot + '.tc17-4-bak'
Rename-Item -LiteralPath $catRoot -NewName ($tempBak | Split-Path -Leaf)
# ... run the test below ...
# Then restore:
Rename-Item -LiteralPath $tempBak -NewName ($catRoot | Split-Path -Leaf)
```

**Procedure**:

```powershell
. .\Deploy-AMDChipsetDriverOnWindowsServer.ps1 -SkipMain
$ctx = Get-WorkspaceContext
$set = Get-OurSignedOemInfSet -ExpectedThumbprint $ctx.CertThumbprint
Write-Host "Pass 1b returned $($set.Count) entries:"
```

**Pass criteria**: Even though Pass 1a found 0 (CatRoot renamed), the helper's return-set count is non-zero. The pnputil-side lookup of the cert's Subject CN against the Signer Name field in `pnputil /enum-drivers` output populates the set.

**Important**: Restore the CatRoot folder immediately after this test — running other scripts with the folder renamed will cause silent driver verification failures elsewhere in Windows.

### TC17.5 — V06 idempotency (the goal of Defect 3 + Defect B)

**Purpose**: Confirm that the combined r74 Defect 3 fix + r75 Defect B fix delivers the originally-promised V06 idempotency: after a successful install and reboot, running `-OnlyPhases V06` reports `0 device(s) WILL be replaced` for all script-installed drivers.

**Setup**: A clean-installed WS2019 host. Run the full r75 install cycle: `-Action PrepareVerify -CleanWorkRoot`, then `-Action Install`, then reboot the host, then `-Action Install -OnlyPhases V06`.

**Expected V06 output excerpt (Graphics)**:

```
--- AMD HARDWARE that this script can affect ---
  Driver-source: [A]Microsoft  [B]Vendor  [C]Self-signed  [?]Unknown
  ...
  Match summary:
    0 device(s) WILL be replaced
    9 device(s) keep current driver
```

**Pass criteria**: The V06 "Match summary" line reports `0 device(s) WILL be replaced` and a non-zero count of `device(s) keep current driver` matching the number of AMD devices that the script targets. At the r74 baseline, this same procedure reported N>0 `WILL be replaced` on a freshly-installed-and-rebooted host (the original Defect 3 symptom that r74's V06 fix could not fully close because Get-OurSignedOemInfSet returned an empty set). At the r75 baseline, the count is 0.

**Reference**: `pre-reinstall-snapshot-20260524-113102.log` documents the pre-r75 state where V06 reported N>0 despite a clean install + reboot.

### TC17.6 — psa.py 3.9.0 against r75 sources (0 errors, including no PSA2001 regression)

**Purpose**: Confirm that the r75 release passes the `0 errors` gate under psa.py 3.9.0 with the project's standard `.psa.config.json` opt-ins enabled (PSAP0001..PSAP0004 on, severity floor at `error`).

**Procedure**:

```bash
# From the repository root:
curl -sSL https://raw.githubusercontent.com/usui-tk/ai-generated-artifacts/main/quality-tools/powershell-static-analyzer/psa.py -o /tmp/psa-3.9.0.py
python3 /tmp/psa-3.9.0.py \
    --config .psa.config.json \
    --severity error \
    Deploy-AMDChipsetDriverOnWindowsServer.ps1 \
    Deploy-AMDGraphicsDriverOnWindowsServer.ps1 \
    Deploy-AMDNpuDriverOnWindowsServer.ps1 \
    Deploy-MSBthPanInboxOnWindowsServer.ps1
echo "Exit code: $?"
```

**Expected output**: Each file reports `Issues : 0 errors, 0 warnings, 0 info` and the overall exit code is `0`.

**Pass criteria**: Exit code is `0` AND every file reports 0 errors. Specifically, no PSA2001 firing on `$ourInfSet` inside `Invoke-InstPhase00_PreInstallReview` (this was the latent defect that the r75 Defect C fix closed).

**Negative-baseline reference**: Running the same command against the r74 sources reports 1 PSA2001 error each on Chipset and Graphics (`undefined variable $ourinfset in function Invoke-InstPhase00_PreInstallReview`), demonstrating that r75's Defect C fix is observable at static-analysis time as well as runtime.

### TC17.7 — psa.py PSA2010 sanity (catches the §D.32.2 family of typos at static-analysis time)

**Purpose**: Confirm that PSA2010 (the rule that, had it existed, would have caught the §D.32.2 `Find-Signtool` typo before r71 shipped) actually fires on its target pattern and does not fire on the correct call form.

**Procedure**:

```powershell
# Create a synthetic test file
$ScriptContent = @'
function Find-KitTool {
    param([string]$Name)
    # returns path to the Windows Kit tool
}

function Test-Foo {
    # Correct call — should NOT fire PSA2010
    $kit = Find-KitTool 'signtool.exe'

    # Typo — SHOULD fire PSA2010
    $sig = Find-Signtool
}
'@
$ScriptContent | Set-Content -Encoding utf8 -Path .\test-psa2010.ps1
```

```bash
python3 /tmp/psa-3.9.0.py --include PSA2010 --severity error ./test-psa2010.ps1
# Expected output: 1 error at the Find-Signtool line
```

**Pass criteria**: Exactly 1 PSA2010 error is reported, on the `Find-Signtool` call. The `Find-KitTool` call is not flagged because the function is defined in the same file. If `--include PSA2010` does not fire at all, the rule is broken — escalate before proceeding with releases.

### TC17.8 — psa.py PSA2011 sanity (catches the Defect A pattern at static-analysis time)

**Purpose**: Confirm that PSA2011 fires on `Split-Path -LiteralPath ... -Parent` and does not fire on the two recommended fix forms.

**Procedure**:

```powershell
$ScriptContent = @'
$p = "C:\Windows\System32\notepad.exe"

# Should fire PSA2011
$a = Split-Path -LiteralPath $p -Parent

# Should NOT fire (different switch order is still positive — also should fire)
$b = Split-Path -Parent -LiteralPath $p

# Should NOT fire — recommended fix 1
$c = [System.IO.Path]::GetDirectoryName($p)

# Should NOT fire — recommended fix 2
$d = Split-Path -Path $p -Parent
'@
$ScriptContent | Set-Content -Encoding utf8 -Path .\test-psa2011.ps1
```

```bash
python3 /tmp/psa-3.9.0.py --include PSA2011 --severity error ./test-psa2011.ps1
# Expected: 2 errors (both -LiteralPath + -Parent forms), 0 errors for fixes
```

**Pass criteria**: Exactly 2 PSA2011 errors are reported, one for each `-LiteralPath` + `-Parent` form. The `[System.IO.Path]::GetDirectoryName` call and the `Split-Path -Path` call are not flagged.

**Additional verification — historical reproduction**: Run PSA2011 against the r74 sources to confirm it would have caught Defect A in r71:

```bash
git checkout <commit-at-r74>
python3 /tmp/psa-3.9.0.py --include PSA2011 --severity error \
    Deploy-AMDChipsetDriverOnWindowsServer.ps1 \
    Deploy-AMDGraphicsDriverOnWindowsServer.ps1 \
    Deploy-MSBthPanInboxOnWindowsServer.ps1 \
    Deploy-AMDNpuDriverOnWindowsServer.ps1
# Expected: 3 errors (Chipset, Graphics, BthPan all have the same line in Get-InfDriverFileList)
# Expected: NPU reports 0 errors (no Get-InfDriverFileList helper)
```

This reproduction is the gold-standard verification that PSA2011 catches the *form* of the defect that surfaced in the 2026-05-25 bench cycle.

### TC17.9 — NPU r19 no-op identity (cross-script ScriptTag alignment)

**Purpose**: Confirm that NPU r19 differs from NPU r18 only in `$Script:ScriptVersion` and `$Script:ScriptTag`, validating the §D.33.10 documented exception to SPEC §A.7 ("no empty revisions").

**Procedure**:

```bash
# Extract just the source-meaningful bytes (excluding ScriptVersion / ScriptTag lines)
git show <r18-commit>:Deploy-AMDNpuDriverOnWindowsServer.ps1 \
    | grep -v '\$Script:ScriptVersion\s*=\|\$Script:ScriptTag\s*=' \
    | sha256sum > /tmp/npu-r18.sha256

git show HEAD:Deploy-AMDNpuDriverOnWindowsServer.ps1 \
    | grep -v '\$Script:ScriptVersion\s*=\|\$Script:ScriptTag\s*=' \
    | sha256sum > /tmp/npu-r19.sha256

diff /tmp/npu-r18.sha256 /tmp/npu-r19.sha256
```

**Pass criteria**: The two `sha256sum` outputs are identical (zero diff). Any non-empty diff fails this TC and means the NPU bump was not actually a clean ScriptTag-alignment; investigate the source-code change that snuck in.

**Pass criteria (positive verification)**: `git diff <r18-commit> HEAD -- Deploy-AMDNpuDriverOnWindowsServer.ps1` shows exactly two changed lines (the `$Script:ScriptVersion` assignment and the `$Script:ScriptTag` assignment).

---


## 18. r76: psa.py 4.0.0 LLM-governance baseline verification (PSAP0003 / PSAP0005)

This section documents the verification procedures for the r76 / r42 / r24 / r20 release. r76 has no runtime behaviour changes (see §17 for the most recent functional regression suite); the verification is entirely about confirming the static-analysis posture.

### TC18.1 — psa.py 4.0.0 against r76 sources (0 errors, strict baseline 0/0/0)

**Purpose**: Confirm that `psa.py` 4.0.0 with the canonical `.psa.config.json` produces **0 errors / 0 warnings / 0 info** on all four scripts EXCEPT for PSAP0005 warnings (which are documented separately in TC18.3 as the migration baseline).

**Procedure**:

```bash
# From the repository root with psa.py 4.0.0 on PATH or relative
python3 path/to/psa.py --config .psa.config.json \
    Deploy-AMDChipsetDriverOnWindowsServer.ps1 \
    Deploy-AMDGraphicsDriverOnWindowsServer.ps1 \
    Deploy-AMDNpuDriverOnWindowsServer.ps1 \
    Deploy-MSBthPanInboxOnWindowsServer.ps1
```

**Pass criteria**: All four scripts report **0 errors**. Warnings are PSAP0005 only (no PSAP0003 / no PSA2001 / no PSA8001 / etc.).

### TC18.2 — psa.py 4.0.0 PSAP0003 cleanup verification (the r74 inline-tag regression is gone)

**Purpose**: Confirm that the nine `# NOTE (r74):` / `# r74:` inline revision-tag comments introduced by r74 have been cleaned up and do not regress.

**Procedure**:

```bash
python3 path/to/psa.py --include PSAP0003 \
    Deploy-AMDChipsetDriverOnWindowsServer.ps1 \
    Deploy-AMDGraphicsDriverOnWindowsServer.ps1 \
    Deploy-AMDNpuDriverOnWindowsServer.ps1 \
    Deploy-MSBthPanInboxOnWindowsServer.ps1
```

**Pass criteria**: All four scripts report **0 PSAP0003 findings**. The r75 baseline reproduced 9 (7 Chipset, 1 Graphics, 1 BthPan); r76 reports 0.

**Regression replay** (optional, run only on the r75 source if revisiting historic state):

```bash
git checkout <r75-commit> -- Deploy-AMD*.ps1 Deploy-MSBthPan*.ps1
python3 path/to/psa.py --include PSAP0003 Deploy-*.ps1
# Expected: 9 findings (7 Chipset / 1 Graphics / 1 BthPan)
git checkout HEAD -- Deploy-AMD*.ps1 Deploy-MSBthPan*.ps1
```

### TC18.3 — psa.py 4.0.0 PSAP0005 migration-baseline counts

**Purpose**: Confirm that the per-script PSAP0005 counts under `psap0005_relaxed_mode: true` match the documented migration baseline in SPEC §A.11.5.

**Procedure**:

```bash
python3 path/to/psa.py --config .psa.config.json --include PSAP0005 \
    Deploy-AMDChipsetDriverOnWindowsServer.ps1 \
    Deploy-AMDGraphicsDriverOnWindowsServer.ps1 \
    Deploy-AMDNpuDriverOnWindowsServer.ps1 \
    Deploy-MSBthPanInboxOnWindowsServer.ps1
```

**Pass criteria** (initial migration baseline values; these will decrease across subsequent releases as cleanup phases complete per SPEC §A.13 Migration roadmap):

| Script  | PSAP0005 (relaxed) |
| ------- | -----------------: |
| Chipset |                 22 |
| Graphics |                24 |
| NPU     |                  2 |
| BthPan  |                 16 |

A deviation in either direction requires investigation: a higher count means a new revision-anchored reference has been added (regression); a lower count means a cleanup happened without an accompanying SPEC §A.11.5 baseline update.

### TC18.4 — psa.py 4.0.0 PSAP0005 relaxed-mode exemption verification (each pattern still works)

**Purpose**: Confirm that the four relaxed-mode exemption patterns (SECTION header, SPEC cross-reference, Added-in-release phrasing, Earlier-revisions prose) are correctly applied and that disallowed forms ("As of rNN, ...") still fire even under relaxed mode.

**Procedure**: Run the upstream `psa.py` test suite, which includes Section 2c (15 relaxed-mode test cases) and Section 2d (PSAP0003 + PSAP0005 dedupe).

```bash
cd path/to/ai-generated-artifacts/quality-tools/powershell-static-analyzer
python3 test_psa_rules.py
```

**Pass criteria**: `Result: 213 passed, 0 failed`. The relevant cases are tagged `PSAP0005 relaxed: ...` in the output.

### TC18.5 — r76 cross-script ScriptTag alignment (no functional change)

**Purpose**: Confirm that r76 / r42 / r24 / r20 differs from r75 / r41 / r23 / r19 only in (a) inline-comment hygiene rewrites and (b) `$Script:ScriptVersion` / `$Script:ScriptTag` updates, with no runtime behaviour change.

**Procedure**:

```bash
# Functional diff scope: ignore identity strings and pure-comment lines
git diff <r75-commit> HEAD -- Deploy-AMD*.ps1 Deploy-MSBthPan*.ps1 \
    | grep -E '^[+-]' \
    | grep -vE '^[+-]\s*#' \
    | grep -vE '\$Script:Script(Version|Tag)\s*='
```

**Pass criteria**: Empty output (zero non-comment, non-identity diff lines). The only differences are inline-comment text and the two `$Script:Script*` assignments.

---

## 19. r80: psa.py 4.0.2 LLM-governance strict-mode flip verification (PSAP0005 strict)

The 2026-05-24 r80 / r46 / r24 / r28 (`psa-py-v4-llm-governance-strict`)
release completes the migration started at r76. This section
documents the verification steps for the strict-mode flip.

### TC19.1 — All four scripts pass psa.py 4.0.2 strict mode with 0/0/0

The acceptance criterion of r80 is that all four sister scripts
report `0 errors, 0 warnings, 0 info` under the default `psa.py`
4.0.2 configuration (PSAP0001..PSAP0005 enabled, PSAP0005 in strict
mode because `psap0005_relaxed_mode` is omitted from
`.psa.config.json`).

```bash
# From the repository root with psa.py 4.0.2 on PATH or relative
python3 /path/to/psa.py --config .psa.config.json \
    Deploy-AMDChipsetDriverOnWindowsServer.ps1 \
    Deploy-AMDGraphicsDriverOnWindowsServer.ps1 \
    Deploy-AMDNpuDriverOnWindowsServer.ps1 \
    Deploy-MSBthPanInboxOnWindowsServer.ps1
```

**Pass criteria** (verified at the r80 release):

```text
File   : Deploy-AMDChipsetDriverOnWindowsServer.ps1
Issues : 0 errors, 0 warnings, 0 info
File   : Deploy-AMDGraphicsDriverOnWindowsServer.ps1
Issues : 0 errors, 0 warnings, 0 info
File   : Deploy-AMDNpuDriverOnWindowsServer.ps1
Issues : 0 errors, 0 warnings, 0 info
File   : Deploy-MSBthPanInboxOnWindowsServer.ps1
Issues : 0 errors, 0 warnings, 0 info
```

### TC19.2 — PSAP0005 strict-mode count is zero on all four scripts

A targeted PSAP0005-only run confirms the strict-mode rewrite is
complete:

```bash
python3 /path/to/psa.py --config .psa.config.json --include PSAP0005 \
    Deploy-AMDChipsetDriverOnWindowsServer.ps1 \
    Deploy-AMDGraphicsDriverOnWindowsServer.ps1 \
    Deploy-AMDNpuDriverOnWindowsServer.ps1 \
    Deploy-MSBthPanInboxOnWindowsServer.ps1
```

**Pass criteria**: No `[PSAP0005]` line in the output (the analyzer
reports `(no issues found)` for each script).

### TC19.3 — `psap0005_relaxed_mode` key is absent from `.psa.config.json`

The flip is irreversible — removing the relaxed_mode key ensures any
future regression fires immediately:

```bash
grep -E '"psap0005_relaxed_mode"' .psa.config.json
```

**Pass criteria**: No matching line (the key has been removed).

### TC19.4 — `$Script:ScriptTag` is `psa-py-v4-llm-governance-strict` on all four scripts

```bash
grep -E '^\$Script:ScriptTag' Deploy-AMD*.ps1 Deploy-MSBthPan*.ps1
```

**Pass criteria**: All four matches show `'psa-py-v4-llm-governance-strict'`.

### TC19.5 — File integrity preserved

The bulk rewrite must not corrupt UTF-8 BOM or CRLF line endings
(PSA7001 / PSA7002 invariants).

```bash
# UTF-8 BOM check (first 3 bytes must be 0xef 0xbb 0xbf)
for f in Deploy-AMD*.ps1 Deploy-MSBthPan*.ps1; do
    head -c 3 "$f" | od -An -tx1 -N3
done

# CRLF line-ending check (CR count == LF count)
for f in Deploy-AMD*.ps1 Deploy-MSBthPan*.ps1; do
    cr=$(tr -cd '\r' < "$f" | wc -c)
    lf=$(tr -cd '\n' < "$f" | wc -c)
    echo "$f: CR=$cr LF=$lf"
done
```

**Pass criteria**:
- All four BOM checks show `ef bb bf`.
- All four scripts have equal CR and LF counts (CRLF intact).

### TC19.6 — PSA8001 cross-script byte-identity preserved on shared helpers

The bulk rewrite must not introduce drift on cross-script-shared
helpers. PSA8001 enforces this automatically; a clean PSA8001 run
under TC19.1 is sufficient evidence. To verify a specific helper
manually (illustrative example):

```bash
# Compare the byte-identical New-WhqlCoSignAnalysis declaration
# block across Chipset / Graphics / BthPan
for f in Deploy-AMDChipsetDriverOnWindowsServer.ps1 \
         Deploy-AMDGraphicsDriverOnWindowsServer.ps1 \
         Deploy-MSBthPanInboxOnWindowsServer.ps1; do
    awk '/# WHQL co-signature analysis \(see SPEC §D.31\)/,/^    }/' "$f" \
        | sha256sum | awk -v f="$f" '{print $1, f}'
done
```

**Pass criteria**: All three SHA-256 hashes are identical (the
helper body is byte-for-byte the same across the three scripts).

### TC19.7 — No regression of historical AMD hardware suppressions

Five `# psa-disable-line PSAP0005 -- AMD ... identifier` suppression
directives exist in Graphics for hardware identifiers that
grammatically match `rNN` (`R9700`, `R1*`, `V1*`). These must remain
in place after the r80 rewrite.

```bash
grep -cE 'psa-disable-line PSAP0005 -- AMD' Deploy-AMDGraphicsDriverOnWindowsServer.ps1
```

**Pass criteria**: Returns `5` (the count is unchanged from r42).

### Reference: how the r80 rewrite was executed

The bulk-rewrite Python script (one-shot, all four files) is recorded
in SPEC.md §D.34 ("D.34.3 Rewrite patterns by category" table) and
in the CHANGELOG.md r80 entry. The script preserves UTF-8 BOM,
CRLF line endings, and applies the same set of regex / literal
replacements to all four `.ps1` files in one pass.


---

## 20. Validation Scenario 20: 2026-08-07 WS2016 + Ryzen 5 PRO 4650U field runs (Chipset / Graphics / BthPan PrepareVerify)

**Fixture**: Windows Server 2016 (build 14393), AMD Ryzen 5 PRO 4650U (Renoir-family APU with integrated Radeon graphics), Windows PowerShell 5.1, operator-driven interactive console session. No Bluetooth controller present on the host. Script generation: the wave-2b builds (Chipset r90 / Graphics r56 / BthPan r38 era).

**Runs** (all `-Action PrepareVerify -CleanWorkRoot`, operator-collected console logs analysed off-host):

| Script | Observed outcome | Consequence |
|---|---|---|
| Chipset | P03 URL discovery returned 0 hits on the current AMD landing pages | Root-caused to AMD's 2026-07 installer renaming (`amd_chipset_software_<v>.exe` → `amd_software_<v>.exe`); fixed in r91 with a widened pattern, dual-name cache filter, updated pinned fallback and probe-miss evidence preservation. Post-mortem: SPEC D.37 |
| Graphics | 18m37s of console silence in P04 immediately after `Extracted with 7-Zip auto-detect`; the operator's Ctrl-C made the run **continue** (nested-MSI extraction + INF discovery completed 0.6s later). A second unnoticed 3m41s silent gap existed in P03 | Root-caused to console QuickEdit mark-mode freeze, not a 7-Zip or script defect (7-Zip had exited 0 eighteen minutes before the release; Ctrl-C in mark mode is copy-and-release). Fixed in r92 with the QuickEdit guard. Post-mortem: SPEC D.38 |
| BthPan | Every phase ended `done`; the console showed several `[!]` notices (source-INF baseline InfVerif errors 1233/1204, `inf2cat` 22.9.8 refusal → `makecat` fallback, `signtool verify` untrusted-root before I01, no `BTH\MS_BTHPAN` device on the host) and the operator asked whether proceeding to Install was safe | All four notices confirmed expected-condition by design (the script itself classified `REAL failures: 0`); Install on this host would stage the driver only. The presentational gap (no explicit verdict in the RUN SUMMARY) was closed in r92 with the install-readiness digest. Analysis: SPEC D.38.4 |

**Validation value**:

- First field execution of the BthPan prep pipeline on physical hardware. Because the host has no Bluetooth controller, this validates the staging path only (INF patch, catalog generation via the documented `makecat` fallback, signing, expected pre-I01 verification states); the device-bind path still requires the §4 AX210 fixture.
- First WS2016-generation field fixture for the Chipset / Graphics prep pipelines (earlier physical validation was WS2025 / Win11 LTSC 2024).
- The two operator reports from these runs drove the r91 (URL discovery) and r92 (QuickEdit guard + readiness digest + run-artifact archive) hardening releases, and the session's evidence-handling needs motivated the r93 configuration-evidence collector.
- `Install` actions were **not** executed on this fixture as part of these runs.

---

## 21. Validation Scenario 21: 2026-08-08 WS2019 field run (Chipset PrepareVerify + Install attempt)

**Fixture**: Windows Server 2019 (build 17763, ja-JP), UEFI firmware with Secure Boot ON, Windows PowerShell 5.1, operator-driven console session. Script generation: r94 (`evidence-collection-default-on`), so this run also exercised the automatic pre/post evidence collection and the run-artifact archive for the first time in the field.

**Observed**:

| Item | Result |
|---|---|
| `PrepareVerify -CleanWorkRoot` | All 16 phases `done` in 9m34s: the renamed `amd_software_8.07.16.1035.exe` was discovered and downloaded (r91 fix confirmed working in the field), 119 INFs analysed, 2 patched, catalogs generated and signed |
| Automatic evidence collection (r94) | Pre/post pairs produced for both actions; collector completed with `REVIEW REQUIRED` verdicts (informational REVIEW items) and correct exit-code behaviour on WS2019 / PS 5.1 |
| Run-artifact archives (r92) | Created next to the script for both actions; `*.pfx` correctly absent |
| **Defect** — RUN SUMMARY truncation | `引数の型が一致しません` thrown inside `Write-InstallReadinessDigest` right after the SUM row; readiness verdict and closing separator lost. Root cause: WinPS 5.1 `Get-Variable -Scope` engine bug on a missing variable; the pwsh-7 harness could not have caught it. Fixed in r95 (SPEC D.39.2) |
| **Noise** — caught probe errors in transcript | ~12 `終了エラー` records per run from `-ErrorAction Stop` existence probes of legitimately-absent values (`PEFirmwareType`, `SecureBoot` optional values, `Servicing` tree, `Get-ComputerRestorePoint`). All were handled; policy changed in r95 to silent probes (SPEC D.39.3) |
| `Install` | I01 imported the certificate; **I02 aborted by design** with `PATH B PREREQUISITE NOT MET` — Secure Boot ON refuses testsigning, and on WS2019 (pre-1903) the WDAC supplemental path is architecturally unavailable (multiple-policy format requires build 18362+). r95 adds the explicit build-gated note to the banner (SPEC D.39.4). No system modification occurred beyond the I01 certificate import |

**Validation value**: first WS2019-generation fixture; first field confirmation of the r91 URL-discovery fix, the r92 archive and the r94 automatic evidence collection; surfaced the 5.1-only digest defect that the Core-based harness structurally cannot detect (harness false-negative lesson recorded in SPEC D.39.2).

## 22. Validation Scenario 22: 2026-08-08 WS2019 Path A field run (r95) and the r96 fix verification

**Fixture**: same host as Scenario 21 (Windows Server 2019 build 17763, ja-JP, UEFI Secure Boot ON, Windows PowerShell 5.1), same day, second session. Script generation: r95 (`ws2019-ps51-field-fixes`). Planned Path A evaluation per the WS2019 support matrix: `PrepareVerify -CleanWorkRoot -SkipNonCosignedDrivers` followed by `Install -SkipNonCosignedDrivers`. This was the first field execution of the `-SkipNonCosignedDrivers` mechanism.

**Observed**:

| Item | Result |
|---|---|
| `PrepareVerify -CleanWorkRoot -SkipNonCosignedDrivers` (04:40) | P00-P05 `done` (119 INFs inventoried; WHQL analysis produced 2 records, both `AmdMicroPEP.inf`, both non-co-signed with **0 `.sys` files**); **P06 `FAILED` in 0.08s**: `終了エラー(Split-Path): 引数が null であるため、パラメーター 'Path' にバインドできません` — the trim consumer read the producer schema (`InfName`/`InfPath`) against inventory rows (`Inf`/`RelativePath`). P07-P09/V01-V06 never ran; no PFX was produced (SPEC D.40.2) |
| `Install -SkipNonCosignedDrivers` (04:42) | I00 warned `PFX not found ... I01 will fail`; **I01 `FAILED` in 0.02s** on the PFX precondition. The r72 I02 short-circuit was unreachable: `$Ctx.WhqlCoSignAnalysis` does not survive the PrepareVerify -> Install process boundary (SPEC D.40.4). No system modification occurred |
| Latent defect (analysis) | Even without the crash, the pre-r96 trim rule kept only analysed fully-co-signed names — the 117 copy-only INFs fall outside the analysis universe and the 119-INF plan would have trimmed to 0 (SPEC D.40.3) |
| r95 in-field confirmations | Superseded/deferred: the digest and probe-noise confirmations planned for this run remain outstanding for the re-run (the Install run aborted at I01; transcripts were not part of this evidence set); the I02 pre-1903 banner item is superseded on Path A by the r96 short-circuit |

**r96 fix verification (sandbox)**: 15-case regression harness (pwsh 7.4.6 / Linux) against the shared helpers extracted from Chipset r96 — schema-crash regression (inventory rows, producer records, path-prop fallback, unresolvable record), trim semantics (copy-only always kept; non-co-signed patch-needing dropped; co-signed patch-needing kept; no-switch and no-analysis pass-through), persistence (analysis/plan JSON round-trip, single-element unwrap tolerance, empty-analysis known state, stale-plan purge), and the cross-process I01/I02 decision matrix including the field-run replay (plan-json source; I01 skips; I02 short-circuits). **15/15 PASS.** Static gates: psa.py 0 findings x 5, `Parser::ParseFile` 0 errors x 4, shared-function byte-identity (Chipset/Graphics/BthPan) for all five plan helpers, canon vendored regions untouched (32 units x 3, all diff hunks outside).

**Outstanding**: field re-execution of the WS2019 Path A evaluation on r96 — expected shape: P06 trims 119 -> 117 with `whql_cosign_plan.json` (`RemainingNeedsPatchCount = 0`), I01 skipped with `Reason = 'skipnoncosigned-no-selfsigned'` and both trust stores untouched, I02 short-circuit via `plan-json`, I03 installs the vendor-catalog subset, plus the deferred r95 digest / probe-noise confirmations.

## 23. Validation Scenario 23: 2026-08-08 WS2019 Path A field run (r96) and the r97 fix verification

**Fixture**: same host as Scenarios 21-22, third session of the day. Script generation: r96 (`path-a-plan-semantics-fixes`). Command sequence: `PrepareVerify -CleanWorkRoot -SkipNonCosignedDrivers` (08:55) then `Install -SkipNonCosignedDrivers` (09:01).

**Observed**:

| Item | Result |
|---|---|
| PrepareVerify (08:55) | **All phases P00-V06 `done`** — the D.40 fixes held: P06 trimmed 119 -> 117 ("2 non-WHQL-co-signed INF(s) skipped"), "Patching 0 / Copying 58 already-Server-compatible INF(s)", P08 generated 53 catalogs (`/os:ServerRS5_X64`, 5 phantom-skips), P09 signed all 53, V03 recorded "53 expected failure(s) - cert not yet imported by I01" |
| RUN SUMMARY digest | `Install readiness : (digest unavailable: 引数の型が一致しません)` — the D.39 containment held (no truncation) but a PSArgumentException escaped from outside the probe's try/catch: the r95 root-cause attribution was incomplete (SPEC D.41.4) |
| Install (09:01) — I01 | **SKIPPED by the r96 gate** (`plan source: plan-json`) — wrong: the plan carried 53 self-signed catalogs; `RemainingNeedsPatchCount = 0` is an INF-text-patch statistic, not a self-signing criterion (SPEC D.41.2) |
| Install (09:01) — I02 | Short-circuit refused (`PlanNonCoSignedCount = 2` — the trimmed `AmdMicroPEP.inf` name re-introduced by surviving out-of-scope W11x64 rows, SPEC D.41.3) -> normal path evaluation -> WS2019 pre-1903 has no WDAC path -> Path B -> **by-design abort** `reason=secure-boot-on`. No system modification occurred |

**r97 fix verification (sandbox)**: 22-case harness (pwsh 7.4.6 / Linux) against the shared helpers and digest extracted from Chipset r97 — includes a replay against the actual field `inf_inventory.csv` (T16: 119 rows -> 117 eligible; plan JSON v2 with `PlanCatalogSignCount = 53`, `RemainingNeedsPatchCount = 0`, `PlanNonCoSignedCount = 0`; I01 **runs**; I02 short-circuits), the W11-variant name-collision replay (T12), the degenerate zero-catalog plan (T17: I01 gate fires), pre-v2 plan rejection (T18), missing-`VariantSelected` conservatism (T19), and the digest probe/verdict semantics (T20). **22/22 PASS.** Static gates: psa.py 0 findings x 5, `Parser::ParseFile` 0 errors x 4, shared-helper byte-identity (plan helpers 3-way, digest 4-way), canon vendored regions untouched (32/32/29/32 units, all diff hunks outside).

**Outstanding**: field re-execution on r97 — expected shape: PrepareVerify writes plan JSON v2 (`PlanCatalogSignCount = 53`); Install: I01 **runs** and imports the certificate into `LocalMachine\Root` + `\TrustedPublisher`, I02 short-circuits (`plan source: plan-json`, banner "No non-WHQL-co-signed kernel content remains"), I03 installs the 53-catalog subset (first field proof that pnputil accepts the self-signed catalogs), I04 verification, and the readiness digest prints a verdict — or, if the residual 5.1 thrower persists, a self-located `[type] message at line N: statement` diagnostic that pinpoints it. Kernel-CI coverage of the no-patch subset remains an open observation item (SPEC D.41.5): watch I04/setupapi for load failures on non-WHQL-embedded `.sys` files.

## 24. Validation Scenario 24: 2026-08-08 WS2019 Path A field run (r97) and the r98 fix verification

**Fixture**: same host as Scenarios 21-23, fourth session of the day (Windows Server 2019 build 17763 ja-JP, UBR 9020, PowerShell 5.1.17763.9020, UEFI Secure Boot ON, System Restore disabled). Script generation: r97 (`path-a-scope-and-digest-fixes`). Command sequence: `PrepareVerify -SkipNonCosignedDrivers` (09:59) then `Install -SkipNonCosignedDrivers` (10:05). Evidence: run-artifact archives for both actions plus the collector's pre/post evidence pairs for both actions.

**Observed**:

| Item | Result |
|---|---|
| PrepareVerify (09:59) | **All phases completed.** P06 trimmed 119 -> 117 ("2 non-WHQL-co-signed INF(s) skipped"), "Patching 0 / Copying 58 already-Server-compatible INF(s)", P08 generated 53 catalogs (`/os:ServerRS5_X64`, 5 phantom-skips, 5 orphan `.cat` cleaned), P09 signed all 53, V03 recorded "53 expected failure(s) - cert not yet imported by I01", V05/V06 produced the install plan (6 UPGRADE / 47 ADD / 0 SKIP) |
| PrepareVerify RUN SUMMARY digest | `(digest unavailable: [System.ArgumentException] 引数の型が一致しません at line 1377: foreach ($t in @($Script:PhaseTimings)) {)` — **the r97 self-locating containment did its job**: it named the throwing statement instead of a guess about it (SPEC D.42.4) |
| Install (10:05) — I01 | **RAN.** Certificate `C01AD5E5...` imported into `LocalMachine\Root` and `LocalMachine\TrustedPublisher`. **First field confirmation of the r97 Fix 1 gate criterion** (SPEC D.41.2 / D.42.2) |
| Install (10:05) — I02 | **Short-circuit fired** (`plan source: plan-json`, banner "No non-WHQL-co-signed kernel content remains in the trimmed install plan"). **First field confirmation of the r97 Fix 2 aggregation scope** — no Path B fall-through, no `reason=secure-boot-on` abort |
| Install (10:05) — I02 phase close | **FAILED.** `Write-PhaseFooter 'I02' 'short-circuit'` violates the canon `[ValidateSet('done','cached','skipped','failed')]`; the phase runner caught the binding error and marked I02 `failed`. Run aborted before I03 (SPEC D.42.3). Latent since r72 — never reached until the short-circuit first fired |
| Install (10:05) — I03 / I04 | **Not reached.** The two D.41.5 premises (pnputil acceptance of self-signed catalogs; kernel-CI loadability of the 56-INF no-patch subset) remain unproven |
| Independent corroboration of I01 | Collector pre/post pair for the Install action: project certificate store 2 -> 4 certificates, run thumbprint present in **both** `Root` and `TrustedPublisher`, `StoresConsistent = true` |
| Collector exit code (both actions) | 2 (REVIEW REQUIRED) — `pfroBlocking = True` pending-reboot classification and 9 problem PnP devices (code 28). Expected on this fixture; not a script defect |

**System state after the run**: the I01 certificate import is the only modification. No driver-store change, no WDAC policy, no BCD flag.

**r98 fix verification (sandbox)**:

- **Reproduction of the digest thrower**, out of band on pwsh 7.4.6 / Linux: `@($list)` over `System.Collections.Generic.List[object]` throws `System.ArgumentException: Argument types do not match`; `List[string]`, `List[pscustomobject]`, `List[psobject]`, `List[int]`, `List[hashtable]` all pass; the empty `List[object]` also throws; safe forms (`.ToArray()`, `[object[]]`, bare `foreach`, pipeline operand) all pass. Captured stack: `PSToObjectArrayBinder.Bind` -> `PSEnumerableBinder.MaybeDebase` -> `Expression.Condition`.
- **AST audit** of `[ValidateSet]` call-site conformance and of `@( )`-over-`List[object]`: 13 findings on the pre-fix tree (9 + 4), **0 findings** on the post-fix tree. The audit was written for this investigation; its exhaustiveness claim carries that provenance (SPEC D.42.5). The durable home for both checks is a central `psa.py` rule, not a repository-local script.
- **Static gates**: `psa.py --config .psa.config.json` 0 errors / 0 warnings / 0 info x 5 files; `Parser::ParseFile` 0 errors x 5 files.
- **Shared-helper byte identity**: `Write-InstallReadinessDigest` 4-way byte-identical after the fix (§A.11.5b).
- **Canon integrity**, verified with the central authoritative tooling per §A.11.8a — `canonical-drift-scanner` run against the pre-edit and post-edit trees via `--satellite`: 125 dd observation records both times, `drift` 121 `match` + 4 `forked-frozen` both times, and **zero differences** across every non-volatile field including `observed_hash_raw`, `observed_hash_norm` and `region_locator`. `governance-state-validator` PASS (A-G, 0 findings) against the central root. `canon-hash-restamp` does not apply to this repository (its scan root is `reference-code/<family>/{Public,Private}`); the positive control against the central root reports 58/58 in sync.

**Outstanding**: field re-execution on r98. Expected shape — PrepareVerify as in this run, but the RUN SUMMARY now printing `Install readiness : READY - no failed phases.`; Install: I01 runs, I02 short-circuits and **closes as `cached`**, then:

1. **I03** installs the 53-catalog subset — first field proof that pnputil accepts the pipeline's self-signed catalogs (D.41.5 premise 1).
2. **I04 / setupapi** — whether the 56-INF no-patch subset loads under Secure Boot. These `.sys` files were never examined for WHQL embedded signatures, because P05 analyses only the `NeedsPatch` subset (D.41.5 premise 2). A signature-attributable load failure here promotes the deferred "widen the analysis population to the full install scope" design item to the critical path.
3. **RUN SUMMARY digest** prints a verdict. If any diagnostic still appears in its place, the self-locating form again names the statement — but note that the two previous residual-thrower attributions were wrong and this one was only settled by out-of-band reproduction; treat a third diagnostic the same way.

## 25. Validation Scenario 25: 2026-08-08 WS2019 Path A field run (r98) and the r99 changes

**Fixture**: same host as Scenarios 21-24, fifth session of the day (Windows Server 2019 build 17763 ja-JP, UBR 9020, PowerShell 5.1.17763.9020, UEFI Secure Boot ON). Script generation: r98 (`phase-status-and-digest-binder-fixes`). Command sequence: `PrepareVerify -SkipNonCosignedDrivers` (11:59) then `Install -SkipNonCosignedDrivers` (12:08). Evidence: run-artifact archives for both actions, collector pre/post pairs for both actions, plus a standalone collector run at 12:18 after the operator observed the failures.

**Observed — the run itself completed**:

| Item | Result |
|---|---|
| PrepareVerify | All phases completed. 119 total / 2 selected for patching, 117 eligible / 2 trimmed, Patching 0 / Copying 58, P08 53 catalogs, P09 53 signed |
| Install I01 | Certificate imported to `Root` + `TrustedPublisher` |
| Install I02 | Short-circuit fired, closed as **`cached`** — the r98 Fix 1 mapping confirmed in the field |
| Install **I03** | **53 ok / 0 failed / 2 no-op / 1 reboot-required.** **D.41.5 premise 1 PROVEN: pnputil accepts the pipeline's self-signed catalogs** |
| Install I04 | Completed. Reported `LOAD_FAILED: 0`, 4 devices `REBOOT_NEEDED`, and — in the same output — `Self-signed driver loading is currently BLOCKED` |
| RUN SUMMARY digest | `Install readiness : READY - no failed phases.` — the r98 Fix 2 binder fix confirmed (the digest speaks), the verdict itself wrong (SPEC D.43.4) |

**Observed — the host was left worse**:

| Device | Before (12:08:10) | After (12:12:01 / 12:18) | Diagnosis |
|---|---|---|---|
| **Intel Wi-Fi 6E AX210** | healthy, not in the problem list | `CM_PROB_NOT_CONFIGURED` (code 1) | Re-enumerated 32 ms after `pnputil /add-driver amdgpio2.inf /install` completed its `{Install Related Drivers}` pass; the re-install failed `0xe0000217` because `netwtw6e.inf` declares a `vwifibus` service whose binary is absent from this Server SKU. The script never names this device (SPEC D.43.3) |
| **AMD I2C Controller** | 9 problem devices, this one not among them | `CM_PROB_FAILED_DRIVER_LOAD` (code 39), NT status `0xC0000263` | `amdi2c.inf` was in the plan because `-SkipNonCosignedDrivers` examined only 2 of 119 INFs (SPEC D.43.2). `STATUS_DRIVER_ENTRYPOINT_NOT_FOUND` — an OS API mismatch, **not** a signature rejection |

Problem-device totals moved 9 (8x code 28 + 1x code 51) -> 8 (7x code 28 + 1x code 39), with the code 1 present in the immediate post-Install snapshot. The net count went *down*, which is exactly why a count is not a health check.

**r99 verification — STATIC ONLY**:

- `psa.py --config .psa.config.json`: **0 errors / 0 warnings / 0 info across all five scripts**.
- `Parser::ParseFile`: 0 errors x 5.
- ValidateSet call-site + `@()`-over-`List[object]` contract audit: 0 findings.
- Shared-helper byte identity: `Write-InstallReadinessDigest` / `Get-SystemDeviceHealthCensus` / `Write-DeviceHealthRegressionReport` 4-way; `Get-EligibleInfRecordList` / `Save-WhqlCoSignPlanJson` / `Get-WhqlCoSignPlanInfo` 3-way.
- Canon integrity via the central authoritative tooling (SPEC A.11.8a): 125 dd observation records, `drift` 121 `match` + 4 `forked-frozen`, zero differences on every non-volatile field.

**There is no runtime harness for the r99 changes and no field run.** Every behaviour below is unexercised. This is a weaker verification position than r97 (22-case harness) or r98 (out-of-band reproduction of the defect), and it is stated here rather than left to be inferred.

**Outstanding — the r99 field run must check, in this order**:

1. **PrepareVerify, plan coverage.** `-SkipNonCosignedDrivers` should now analyse the whole install scope. Expect the WHQL analysis line to report a population in the tens, not 2. Plan JSON should be **SchemaVersion 3** carrying `PlanUnverifiedCount`. If any INF now classifies non-co-signed, the eligible count drops below 117 — that is the fix working, not a regression.
2. **D.41.5 premise 2, finally.** The `.sys` files of the 56 no-patch INFs get a WHQL verdict for the first time. Whatever that verdict is, record it: it decides whether Path A on this hardware is viable at all.
3. **I02 behaviour.** If `PlanUnverifiedCount` is 0 the short-circuit fires as before. If it is non-zero the short-circuit is **refused** with an explicit message — verify the refusal path prints and does not throw. If any INF is non-co-signed, I02 takes the normal path and WS2019 has no WDAC route, so expect the by-design Path B abort. **That abort is now the correct outcome**, not a defect.
4. **I03 collateral census.** Expect a `Collateral device health` block after the install summary. On a clean run: `No device outside this run's plan changed to a worse problem state.` If the Intel adapter is still broken it will be reported as a pre-existing problem device, not a regression — the census reports *changes*, so re-running on an already-damaged host will not re-flag it.
5. **Digest.** With Secure Boot ON and no WDAC policy, expect `NOT READY` rather than `READY`. `READY` appearing under those conditions means the boot-signing gate did not wire up.
6. **Collector schema 1.1.** Expect `device-load-diagnostics.json` and an 11-stage run. Check `ProblemDevices[].ServiceBinaryPresent` is populated, that `ConfigManagerErrorName` decodes on the ja-JP host, and that `SetupApi.FailureSections` is non-empty on this host (it should pick up the vwifibus failures). Two new assessment rows: `Driver binary presence`, `Driver load failure classification`.

**Host recovery (untested)**: the Intel driver package is still registered (`oem17.inf`); only the `vwifibus` service binary is missing. The working hypothesis is that it arrives with a Windows Server wireless networking feature that is not installed by default. Confirm with `Test-Path C:\Windows\System32\drivers\vwifibus.sys` and `Get-WindowsFeature Wireless-Networking` before acting.

## 26. Validation Scenario 26: collector c3 — runtime harness for path resolution and service evidence

**Why this scenario exists**: collector c2 shipped a device-load diagnostic that never executed its own logic, and every static gate passed it (SPEC §D.44). Three string literals were mangled by the authoring tool; `psa.py` and `Parser::ParseFile` both validate that a literal is well-formed and neither can know what it was meant to contain. The only verification that could have caught this is executing the code. This scenario is that execution.

**Fixture**: pwsh 7.4.6 on Linux. The functions under test are extracted from the real `Collect-WindowsServerConfigurationEvidence.ps1` by AST, not copied — a divergence between the harness and the shipped file cannot hide here. Windows-only paths (CIM queries, registry enumeration, live `Test-Path` results) are out of scope; every piece of string handling the c2 defect lived in is in scope.

**Cases**:

| Group | Cases | What is being proven |
|---|---|---|
| T1-T9 | `Resolve-ServiceImagePath` across all observed `ImagePath` shapes | `\SystemRoot\...` kernel driver form, DriverStore path, `\??\` object-manager prefix, relative `system32\...`, quoted exe with arguments, unquoted exe with arguments, absolute path passthrough, empty and whitespace input |
| T10-T12 | Regression guards for the exact c2 failure | the `\SystemRoot` form is actually rewritten, the result starts with the system root, and no `\SystemRoot` remnant survives. The c2 implementation returned its input unchanged, so all three fail against it |
| T13-T16 | Literal checks against the file in the repository | the `Enum\` and `Services\` separators are present, the broken single-backslash `'^\SystemRoot'` regex is absent, and the device diagnostics call the shared resolver rather than re-implementing it |
| T17-T22 | Code decoding | CM_PROB 39 / 1 / 28 decode to their names, a null code returns empty, `0xC0000428` is flagged `SIGNATURE:`, and `0xC0000263` is flagged `NOT a signature` — the distinction that drove the D.43 attribution |

**Result: 22/22 PASS.**

**Negative control** (the part that makes the result mean something): the same literal checks run against the shipped c2 file report **3 findings** — `Enum` separator missing, `Services` separator missing, broken regex present — and exit non-zero. Against c3 they report 0. A harness that has never failed has not been shown to be capable of failing.

**Static gates alongside**: `psa.py --config .psa.config.json` 0 errors / 0 warnings / 0 info across all five scripts (with `Get-WindowsFeature` declared in `psa2010_known_cmdlets`; `--config-check` clean); `Parser::ParseFile` 0 errors x 5; ValidateSet and `@()`-over-`List[object]` contract audit 0 findings; canon integrity via the central authoritative tooling per SPEC §A.11.8a — 125 dd observation records, drift 121 `match` + 4 `forked-frozen`, zero differences on every non-volatile field.

**Outstanding — what the next field run must check**:

1. **`services.json` is produced and complete.** Expect a few hundred records on a Server install. Confirm `ServiceCount`, `DriverServiceCount`, and that `Source` shows a mix of `Win32_Service`, `Win32_SystemDriver` and `Registry` — if `Registry` never appears, the third enumeration path is not contributing and the census is narrower than intended.
2. **`ImagePathExists` is populated, not null.** This is the field c2 silently failed to produce. A run where every record has `ImagePathExists = null` means the resolver is not being reached at all.
3. **`MissingBinaryServices` on the affected host should contain `vwifibus`.** This is the specific prediction. If the collector runs on the damaged WS2019 host and does not list it, the diagnosis in SPEC §D.43.3 is wrong and must be revisited.
4. **`server-feature-services.json`**: `Wireless-Networking` install state recorded, and the `vwifibus` entry classified `ServiceKeyPresentBinaryMissing` (key exists, binary absent) or `ServiceKeyAbsent`. Which of the two it is determines whether `Install-WindowsFeature` is the remedy.
5. **Assessment rows**: `Service binary integrity` and `Server feature-dependent services` appear in the report, and `Driver binary presence` now reports something other than an unconditional PASS.
6. **Locale**: the host is ja-JP. Confirm `ConfigManagerErrorName` and the service type/start type names render from the numeric values rather than from localized strings.

## 27. Automated test suite (`tests/`)

`TESTING.md` records **physical-hardware validation**: what a human ran on real
metal and what happened. The suite under `tests/` is the other half — checks a
machine can run in seconds, with no hardware, before anything reaches a host.
The two are complementary and neither substitutes for the other.

### Running it

```powershell
./tests/Invoke-TestSuite.ps1                    # everything
./tests/Invoke-TestSuite.ps1 -Name '*Collector*'  # one subject area
```

Exit code is the number of failing cases. Windows PowerShell 5.1 or
PowerShell 7.x, Windows or Linux, nothing to install. Full contributor
documentation is in [`tests/README.md`](./tests/README.md).

Nothing in the suite executes a deploy script or touches driver state. Cases
extract the functions they exercise from the real files by AST and run them
against fixtures.

### Why it exists

Three defects shipped to a production host while the static gate battery
reported 0 errors / 0 warnings / 0 info across all five scripts (SPEC §D.45):

| Defect | Why static analysis could not see it |
|---|---|
| `Get-NamedRegistryValue -Path` — parameter does not exist on the callee | A call with a wrong parameter name is well-formed PowerShell; binding fails at runtime |
| `-like '>>>*[Device Install*'` — unterminated wildcard character class | A valid string literal. The pattern is only rejected when applied |
| All twelve collection stages inside one `try`, archive inside it too | Correct syntax. The scope is the bug |

Each throws or misbehaves on the **first call**. The common property is that
executing the code once would have caught all three, and nothing in the
pipeline executed any of it.

### Cases at introduction

| Case | Assertions | Covers |
|---|---|---|
| `Test-CollectorPathResolution.ps1` | 21 | `Resolve-ServiceImagePath` across every `ImagePath` shape observed in the field (`\SystemRoot\...`, `\??\...`, relative, quoted/unquoted exe with arguments, absolute); explicit regression guards that the resolver does not return its input unchanged; CM_PROB decoding; NTSTATUS decoding with signature failures separated from look-alike API mismatches |
| `Test-CollectorSetupApiParser.ps1` | 16 | `Get-SetupApiFailureEvidence` against a fixture reproducing the field log's structures: section detection, missing service binaries, SetupAPI error codes, CM problem codes with NT status, absent-log handling. First assertion is simply that the function does not throw |
| `Test-SisterConsistency.ps1` | 18 | Shared-helper byte identity (4-way and 3-way per SPEC §A.11.5b); ValidateSet call-site conformance repo-wide; `@( )` never applied to a `List[object]`; every script parses and declares a version |

**55 assertions, 3 cases, all passing.**

### Negative control

A check that has never failed has not been shown to be capable of failing.
Run against the previous release, `Test-CollectorSetupApiParser.ps1` fails on
the first assertion with the exact exception that aborted the field run:

```
FAIL  parsing a log with [Device Install] section headers does not throw
        threw: The specified wildcard character pattern is not valid: >>>*[Device Install*
```

Against the current tree it passes. Any case added to this suite should be
shown to fail against the defective version before it is considered done.

### What it found during its own construction

Four defects, three of them previously unknown:

1. A scoping bug in the harness — a module function that dot-sources defines
   into the module's scope, where the test file cannot see the result.
2. The fatal wildcard defect (already known, now guarded).
3. **A new collector defect**: setupapi sections whose only failure signal is
   a `!!!` marker and a CM problem code were being dropped by the extractor,
   because it keyed only off `Error 0x` and the exit status. That is exactly
   the shape of the section recording the `amdi2c` load failure in SPEC
   §D.43 — the extract would have silently omitted the evidence it exists to
   surface.
4. **An `@( )` over a `List[object]`** in the stage ledger written minutes
   earlier in the same change (SPEC §D.42.4). Caught before it left the
   working tree.

### Scope and limits

- **Linux-executable subset only.** CIM queries, registry enumeration,
  `Compress-Archive`, and anything requiring a live driver store are out of
  scope and remain verified by field runs recorded in the numbered scenarios
  above.
- **Fixtures are synthetic.** No host identifiers, no captured customer data.
- The suite does not replace `psa.py` or `Parser::ParseFile`; it covers the
  class of defect those two cannot see.

## 28. Validation Scenario 28: 2026-08-08 WS2019 clean-install run (r100) and the r101 fixes

**Fixture**: freshly installed Windows Server 2019 (build 17763, UBR 9020, ja-JP), UEFI Secure Boot ON, PowerShell 5.1.17763.9020. Generation r100 / collector c4. Three scripts run in sequence with `-Action PrepareVerify -SkipNonCosignedDrivers`: Chipset (15:25), Graphics (15:27), BthPan (15:28).

### What worked — the collector, completely, for the first time

| Check | Result |
|---|---|
| Stage isolation and archive | `stage-results.json` on all three runs: **13 stages, 0 failed, `Complete = True`**, full artefact set, ZIP produced |
| `services.json` | **560 services**, from all three sources: `Win32_SystemDriver` 343 / `Win32_Service` 206 / **`Registry` 11**. The union is doing real work — 11 services exist only as registry keys |
| `ImagePathExists` | **560 / 560 populated.** In c2 and c3 this field was never set at all |
| `vwifibus` | `Wireless-Networking` = `Installed` on this host, so the service is `Healthy`. Consistent with the SPEC §D.44 recovery hypothesis, though this is a rebuilt host and not the damaged one |

`MissingBinaryServices` is empty. That is not a refutation of §D.43.3: the host that carried the damaged Intel adapter was reinstalled, so the prediction lost its subject rather than failing.

### What failed

| Defect | Evidence |
|---|---|
| **P08 degenerate guard never reached** (Chipset, Graphics) | P06 detected the empty plan, printed the explanation and closed `SKIPPED`; P08 then threw `patched directory has no INFs to catalog. Run preparation phases first` — naming a phase that had run. The r100 guards were inserted into `Invoke-PrepPhase09_SignCatalogs` and `Invoke-VerifyPhase03_VerifyCatalogs` (SPEC §D.46.1) |
| **BthPan P01 pre-flight fired on its own default** | `-LogFile` was not passed; the script auto-placed the transcript under `<WorkRoot>\logs\` and then refused to run because the transcript was inside `-WorkRoot`. Only BthPan carries this check, so the same invocation succeeded for Chipset and Graphics (SPEC §D.46.2) |
| 9 problem devices, code 28 | Expected on a clean install with no vendor drivers yet. Not script-attributable |

The degenerate plan itself is not a defect — it is §D.45.5 reproducing on a clean OS: 55 in-scope INFs analysed, 0 fully WHQL co-signed.

### r101 verification

- **Test suite: 4 cases, 79 assertions, all passing.** New case `Test-CollectorOsCapability.ps1` (27) calls both new evidence functions rather than reading their source.
- **Negative control**: against r100 the suite reports exactly three failures — the two misplaced P08 guards and the BthPan pre-flight — and passes against this tree. The guard-placement check derives its scope from which sisters call `Get-EligibleInfRecordList`, so BthPan is excluded by measurement rather than by a hard-coded list.
- Static: `psa.py` 0/0/0 across eleven files; `Parser::ParseFile` 0 errors × 5; canon integrity via the central authoritative tooling per SPEC §A.11.8a — 125 records, zero differences.
- **Three defects were found by executing the new code** after it passed every static gate: empty `$env:TEMP`, `Split-Path -Qualifier` on a qualifier-less path, and a JSON literal on the left of `-f` (SPEC §D.46.5). All three are now regression guards.

## 29. Windows Server 2016 validation campaign — what to collect and what to compare

WS2016 (build 14393) is the OS this project adapts to most, and the campaign is expected to run several times. The point of this section is that each run should end with **data that settles a question**, not a transcript that invites a guess.

### Before anything else: run the collector standalone

```powershell
.\Collect-WindowsServerConfigurationEvidence.ps1
```

Read-only, stage-isolated, and it produces a ZIP even if a stage fails. Doing this **first** gives a baseline bundle for the untouched host, which is what every later comparison is against.

### The four questions a WS2016 bundle should answer without further investigation

1. **Did the scripts see the OS they think they saw?** `os-capability.json` → `ProfileCode` should be `WS2016`, `ProfileExactBuildMatch` `true`, `ExpectedInf2catOsArg` `Server2016_X64`, `ExpectedCertKeyLength` `2048`, `ExpectedCertValidYears` `3`. A `false` on the exact-match flag means the build fell back to a lower profile and every OS-dependent decision below is suspect.
2. **Which capabilities are actually absent here?** `os-capability.json` → `MissingCmdlets` should contain `Restart-PnpDevice` (documented WS2019+ boundary) and `MissingCimClasses` should contain `PS_UpdateAndCompareCIPolicy`. If either is *present* on WS2016, the SPEC §D.46.4 matrix is wrong and the rebind and policy paths need re-reading. If something *else* is missing, that is a new finding.
3. **Is `signtool` present?** `os-capability.json` → `Tools`. A WHQL verdict produced without it is a conservative default, not a measurement, and the difference decides whether a `0 co-signed` result means anything.
4. **Will the bundle survive?** `archive-capability.json` → `ProbeSucceeded`. WS2016 ships the oldest PowerShell 5.1 in the supported set; if `Compress-Archive` is going to be a problem, this says so before the real archive is attempted, with `ErrorMessage`, `MaxPathLengthSeen`, `LongPathsEnabled` and free space alongside.

### Feature names

`server-feature-services.json` → `UnknownFeatureNames`. The watch list is written from WS2019 naming. Any entry appearing here is a name that does not exist on WS2016, and the corresponding row is not a check — it is a blank. Report it rather than reading `Unknown` as "not installed".

### Comparing WS2016 against WS2019

The WS2019 bundles from Scenario 28 are the reference. Diffing `os-capability.json` between the two is the fastest way to see which differences are real on these hosts versus documented-but-unverified. Rows that differ are expected; rows that *match* where the matrix predicts a difference are the interesting ones.

### Expected shape of a WS2016 `-SkipNonCosignedDrivers` run

Based on the WS2019 measurement, expect P06 to report the same finding: analysis over the whole install scope, few or no fully co-signed INFs, and a degenerate plan closing `SKIPPED` with the options banner. **P08 and P09 must close `skipped`, not fail** — that is the r101 fix under test. If P08 throws `no INFs to catalog`, the guards are misplaced again.

A different co-signature count on WS2016 would itself be a finding worth recording: the analysis is over the same driver package, so the count should not depend on the host OS unless the variant selection differs.

### Scope for this campaign

Chipset, Graphics and BthPan. NPU refuses `Install` on legacy Server SKUs by design (SPEC §D.27) and has no NPU hardware here.

## 30. Validation Scenario 30: 2026-08-08 first Windows Server 2016 measurements (collector c5)

**Fixture**: Windows Server 2016 Datacenter Evaluation, build 14393 **UBR 9339**, ja-JP, PowerShell 5.1.14393.9339, **Secure Boot OFF** (reinstalled after a `WDF_VIOLATION` bugcheck loop during setup's configuration-change reboots with Secure Boot ON). Collector c5 run standalone, no deploy script involved.

**Result: 15 stages, 0 failed, complete bundle.** The r101 capability stages worked on their first contact with the OS they were written for.

### Answers to the four TESTING §29 questions

| # | Question | Answer |
|---|---|---|
| 1 | Did the scripts see the OS they think they saw? | **Yes.** `ProfileCode = WS2016`, `ProfileExactBuildMatch = true`, `Server2016_X64`, 2048-bit, 3 years — all as documented |
| 2 | Which capabilities are actually absent? | `MissingCmdlets = [Restart-PnpDevice]` as documented. **`MissingCimClasses` is empty** — `PS_UpdateAndCompareCIPolicy` is PRESENT, contradicting SPEC §D.46.4 (see below) |
| 3 | Is `signtool` present? | **No** — `MissingTools = [signtool.exe, inf2cat.exe]`. Expected on a fresh host with no SDK. Any WHQL verdict taken here would be a conservative default, not a measurement |
| 4 | Will the bundle survive? | **Yes.** Probe archived 4 entries / 499 bytes. `Compress-Archive` 1.0.1.0, `LongPathsEnabled = false`, longest probe path 101 chars |

`UnknownFeatureNames` is empty: the watch list, written from WS2019 naming, is valid on WS2016.

### Finding 1 — a documented OS fact contradicted on first measurement

`PS_UpdateAndCompareCIPolicy` is documented in SPEC §D.24 and §D.46.4 as absent on WS2016, and the WDAC path is built to probe for it and fall back to reboot activation when it throws. This host reports it **present**.

The structure of the WDAC path is unaffected — it probes rather than assumes, which is exactly why the discrepancy cost nothing. What it invalidates is the *planning assumption* that a WS2016 run necessarily takes the reboot fallback.

Note the qualifier: UBR **9339** is a heavily serviced 14393, and the class was plausibly added by a servicing update. The correct record is build-and-UBR-qualified, not a flat inversion of the documented claim. SPEC §D.47.2.

### Finding 2 — the `vwifibus` prediction, reproduced on a different host

§D.43.3 attributed a broken Intel Wi-Fi adapter to a missing `vwifibus` service binary; §D.44 predicted a bundle would show the key present and the binary absent when the wireless feature is not installed; §D.46 recorded that the WS2019 host was rebuilt before the prediction could be tested.

This host reproduces it exactly:

```
services.json                 MissingBinaryCount = 1
                              vwifibus -> C:\Windows\System32\drivers\vwifibus.sys
server-feature-services.json  vwifibus  Wireless-Networking = Available
                              key=True  binary=False  ->  ServiceKeyPresentBinaryMissing
```

A check written before this host existed found the exact predicted condition on a different OS version and a different installation. The diagnosis stands and the remedy — install the feature — now rests on a measurement.

### Baseline for comparison

`services.json`: **502 services** (308 driver services) versus 560 / 343 on the WS2019 reference in §28. `MissingBinaryCount = 1` versus 0 there — the difference being `vwifibus`, present as a key on both but with its binary only on the WS2019 host, where the feature was installed.

### Outstanding — what c6 adds and what the next WS2016 run must check

The `WDF_VIOLATION` loop that prompted the Secure Boot OFF reinstall could not be investigated from this bundle: it recorded that `Wdf01000` runs, and nothing about its version or any bugcheck. Collector c6 adds both.

1. **`driver-framework.json`** — `KmdfLibraryVersion` should be recorded. This is a ceiling: a driver whose INF declares a newer `KmdfLibraryVersion` cannot load, and `inf2cat /os:Server2016_X64` does not lower that requirement. Record the value; it is the number every later compatibility question is measured against.
2. **`crash-evidence.json`** — `CrashDumpEnabled` first. If it is `0`, no dump was ever written and an empty minidump directory needs no further theory. If bugcheck events exist, the **first parameter of a `0x10D` stop code** names the kind of framework contract violated and is the fastest route to a cause.
3. If the host bugchecks again and will not boot, use **`Collect-OfflineRecoveryEvidence.cmd`** from WinRE (Troubleshoot → Command Prompt). Find the Windows volume with `diskpart` / `list volume` — it is usually not `C:` in WinRE — and write output to removable media, never to the offline volume.
4. With `signtool` absent, **do not read a WHQL co-signature count from this host as a measurement.** Install the SDK first or treat the result as a conservative default (SPEC §D.31).

## 31. Using `Collect-OfflineRecoveryEvidence.cmd` when the host will not boot

The PowerShell collector needs a running Windows. When a host bugchecks in a
reboot loop there is none, and **the Windows Recovery Environment has no
PowerShell**. This is the procedure for that case.

### Before you need it

Copy `Collect-OfflineRecoveryEvidence.cmd` onto the USB stick you boot from,
**while the machine still works**. A recovery environment has no network and
no way to fetch it.

### Running it

1. Boot the installation media, or hold Shift while choosing Restart.
2. **Troubleshoot → Command Prompt.**
3. Run it from the stick:

```
E:\Collect-OfflineRecoveryEvidence.cmd
```

With no arguments it finds the Windows volume and a writable destination and
asks you to confirm before writing anything. To name them explicitly:

```
E:\Collect-OfflineRecoveryEvidence.cmd D: E:
```

Add `/Y` to skip the confirmation.

Drive letters in WinRE are not the letters Windows uses. The Windows volume
is usually **not** `C:`, and `X:` is WinRE's own RAM disk. The script accounts
for both; `diskpart` → `list volume` → `exit` confirms by hand if needed.

### What it produces

`<destination>\MSLogs-<timestamp>\` containing the full set Microsoft asks
for in a no-boot report — bcdedit in four forms, diskpart layout, a full
system-drive file listing, every event log, setupapi / CBS / DISM /
WindowsUpdate / USOShared logs, `SrtTrail.txt`, `ReportingEvents.log`, raw
SYSTEM / SOFTWARE / COMPONENTS / RegBack hives, `dism` package, driver and
feature inventories, `pagefile.sys` and `MEMORY.DMP` — plus this project's
own additions: driver framework binary versions, a boot-start driver
enumeration, minidumps, Panther logs and pending-servicing markers.

Two files are worth opening first:

- **`00-collection-manifest.txt`** — what was collected, with key values
  inlined (boot flags, CrashControl, disk layout).
- **`00-collection-errors.txt`** — what was not, and why. **An entry here is
  not a failed collection.** Microsoft's guidance is to send what was
  collected even when some commands failed, and absence is frequently the
  finding: `RegBack` empty is normal on newer builds, no `SrtTrail.txt` means
  startup repair never ran, no minidump alongside `CrashDumpEnabled = 0`
  means no dump was ever written.

### Large files

`pagefile.sys` and `MEMORY.DMP` are size-checked against `MAXCOPYMB` (default
16384 MB) and skipped with the actual size recorded rather than filling the
destination mid-run. To collect a skipped file, raise `MAXCOPYMB` at the top
of the script and re-run — the earlier output directory is timestamped and is
not overwritten.

### Reading the result

The bugcheck parameters are the fastest route to a cause. On a working
machine open `EventLogs\System.evtx` and find event ID 1001 from
`WER-SystemErrorReporting`. For **`WDF_VIOLATION` (0x10D)** the **first
parameter** names the kind of framework contract that was violated, which
decides where to look next.

If the bugcheck happens before anything can be logged, `registry\
boot-start-drivers.txt` lists the services with `Start=0` or `Start=1` —
almost always one of them.

`framework\driver-framework.txt` carries the KMDF/UMDF runtime versions. A
driver package requesting a newer `KmdfLibraryVersion` than the runtime
present cannot load regardless of signing, and `inf2cat /os:Server2016_X64`
does not lower that requirement.

### Then

Compress the output folder and send it. If the case goes to Microsoft, the
directory layout already matches what they ask for.

### Status

**This script has never run in a real recovery environment.** It is validated
structurally by `Test-CollectorFrameworkAndOffline.ps1` — encoding, control
flow, `reg load` balance, `setlocal` discipline, offline-hive correctness,
and all 22 Microsoft-required invocations asserted individually — but
structural validation is not execution. Treat the first real run as a test of
the script as much as of the host, and record what happened in a new scenario
section here.

## 32. Validation Scenario 32: 2026-08-08 first execution of `Collect-OfflineRecoveryEvidence.cmd`

**Fixture**: Windows Server 2016 (build 14393, ja-JP), **booted normally** rather than in WinRE — a useful way to exercise the script without needing a broken machine. Script generation: r103. Run from `C:\`, no arguments. Disk 0 = 931 GB system, Disk 1 = 112 GB removable (`D:`, labelled `WS2016_ja-j`).

### What worked

Auto-detection succeeded on first contact with real hardware:

```
Searching for the offline Windows installation...
  found: C:\Windows
Searching for a writable destination...
  found writable: D:
```

The 112 GB removable volume was chosen over the 931 GB system disk **by the write probe**, not by assumption — the script wrote a probe file, confirmed it existed, and deleted it. This is the mechanism §D.48.2 introduced for the case where boot media is mounted read-only, and it also does the right thing here.

Stages 1-4 completed: bcdedit in four forms, diskpart disk and volume list inlined into the manifest, a 22 MB `dir-systemdrive.log`, and 117 event log files.

### What failed

Stage 5 stopped the script:

```
[ 5/13] Setup, CBS, DISM, Windows Update logs...
: の使い方が誤っています。
```

The first `call :copytree` (SetupAPI, 4 files) succeeded; the second (CBS) aborted the run, taking stages 6-13 with it. Cause: a label containing parentheses expanded inside an `if` block, closing the block early — cmd.exe substitutes variables **before** parsing a parenthesised block. Full analysis in SPEC §D.49.

The partial bundle is exactly consistent: `EventLogs` 117 files, `SetupAPI` 4 files, every other directory empty, `00-collection-errors.txt` empty because nothing had recorded an error — the script died rather than failing a step.

### Why the existing checks passed it

`Test-CollectorFrameworkAndOffline.ps1` verified encoding, `goto` resolution, `reg load` balance, `setlocal` discipline and all 22 Microsoft-required invocations. All passed on the broken file. None modelled cmd.exe's expansion order, and the fault exists only when a specific value is substituted into a specific syntactic position.

The response was not to model the parser but to **forbid the shape**: subroutines no longer use parenthesised blocks at all, so no label content can re-create the fault.

### r104 verification

- Test suite **5 cases, 170 assertions**, all passing. New guards: no subroutine opens a parenthesised block; no subroutine label carries `( ) & | < >`; every branch target introduced by the `goto` rewrite resolves.
- **Negative control**: run against r103 the case reports **8 failures** — 4 metacharacter labels, 8 parenthesised blocks, 6 missing branch labels.
- Static: `psa.py` 0/0/0 across twelve files; `Parser::ParseFile` 0 errors × 5; canon integrity via the central authoritative tooling — 125 records, zero differences.

### Outstanding

1. **Re-run on the booted WS2016 host** and confirm all 13 stages complete. This is the cheap confirmation and should happen before the next reboot.
2. Check `registry\q-crashcontrol.txt` for `CrashDumpEnabled`. If it is `0`, no dump will be written when the host next bugchecks, and that is worth knowing **before** it does.
3. Check `Get-Packages.txt` for the state of KB4589210 — this settles what the pending update actually is, rather than what the Settings UI displays.
4. **The script has still not run in WinRE.** Drive letters differ there (`C:` will not be the Windows volume) and some volumes are read-only. The config-hive marker and the write probe are what handle both; neither has been exercised under those conditions.

## 33. Validation Scenario 33: 2026-08-08 second execution on a booted host (r104) and the r105 mode split

**Fixture**: same Windows Server 2016 host, booted normally. Script generation r104, run from `C:\` with no arguments.

**Result: all 13 stages completed.** The D.49 parser fault is gone.

### What the run revealed

The bundle had a coherent set of gaps, all traceable to one fact — the machine was running:

| Observation | Cause |
|---|---|
| `COPY FAILED` on `config\SYSTEM`, `SOFTWARE`, `RegBack\*` — "in use by another process" | the kernel holds live hives open |
| `reg load of SYSTEM hive FAILED` → **`q-crashcontrol.txt` never produced**, `boot-start-drivers.txt` never produced | same |
| `dism error 1639` → `Get-Packages.txt` / `Get-Drivers.txt` / `Get-Features.txt` all 406 bytes of error | DISM refuses `/image:` against its own live installation |
| `pagefile.sys: copying 0 MB` then `COPY FAILED` | `%~z` returns 0 for a file held open; the copy then failed |
| `COMPONENTS` copied successfully (104 MB) | the one hive not held open |
| `SrtTrail.txt`, `pending.xml`, `poqexec.log` NOT FOUND | **correct** — startup repair never ran, no servicing operations pending |

Collected successfully: 118 event logs, 20 USOShared, 16 Panther, 4 SetupAPI, 2 WindowsUpdate, 1 CBS, 1 DISM, `ReportingEvents.log`, a 22 MB system-drive listing, bcdedit in four forms, diskpart layout.

**The two gaps that mattered**: `CrashDumpEnabled` was never read, and the state of the pending update was never determined — the question that motivated running this before a reboot.

### r105: the script now detects which situation it is in

Running the recovery collector on a booted host is not misuse; it is the sensible rehearsal before a reboot that might not come back. Each mode also reaches evidence the other cannot, so the mode is detected and the commands chosen to match. Full rationale in SPEC §D.50.

| | Offline (WinRE) | Online (booted) |
|---|---|---|
| Hives | copy the files | `reg save` — a consistent snapshot, possible where a copy is not |
| Registry root | `HKLM\OFFSYS\ControlSet001` after `reg load` | `HKLM\SYSTEM\CurrentControlSet` directly |
| Packages | `dism /image:` | `dism /online` |
| `reg unload` | yes | skipped — nothing was loaded |

`CrashDumpEnabled` and `AutoReboot` are now echoed to the console as well as written to file.

### Verification

Test suite **5 cases, 200 assertions**, all passing. **Negative control**: against r104 the case reports **16 failures**. Static gates: `psa.py` 0/0/0 across twelve files; `Parser::ParseFile` 0 errors × 5; canon integrity — 125 records, zero differences.

### Outstanding — the r105 run, before the reboot

1. **Confirm the banner reads `Collection mode : online`.** If it says `offline` the detection is wrong and everything below is the old behaviour.
2. **`registry\q-crashcontrol.txt` must exist**, and `CrashDumpEnabled` is now printed on the console. **A value of `0` means the next bugcheck writes no dump** — worth changing before the reboot, not after.
3. **`Get-Packages.txt` should be a real table.** Look for KB4589210 and its state — `Installed`, `Install Pending` or `Staged`. This settles what the Settings UI has been showing.
4. `registry\SYSTEM` and `registry\SOFTWARE` should exist via `reg save`, and `boot-start-drivers.txt` should be populated.
5. `pagefile.sys` will report `size not reportable` and then attempt the copy. Either outcome is fine; the point is that it no longer claims 0 MB.

### Still unverified

**The offline branch has never executed against a genuinely offline volume.** The script has now run twice on a booted host — once revealing the D.49 parser fault, once revealing this — and both modes are structurally validated, but WinRE remains untested. Drive letters differ there and some volumes are read-only.

## 34. Validation Scenario 34: 2026-08-08 third execution on a booted host (r105) — the mode split works, stage 12 aborts

**Fixture**: same Windows Server 2016 host, booted normally. Script generation r105, run from `C:\` with no arguments.

### What worked — everything the mode split was built for

```
  Collection mode : online
[ 6/13] Registry hives...
  using reg save (hives are locked on a running system)
[ 7/13] Registry queries...
  querying the live registry (no hive load needed)
  CrashControl:
    AutoReboot    REG_DWORD    0x1
    CrashDumpEnabled    REG_DWORD    0x7
  enumerating boot-start drivers...
```

| Check from §33 | Result |
|---|---|
| Banner reads `Collection mode : online` | **yes** |
| `CrashDumpEnabled` shown on the console | **yes — `0x7`, automatic memory dump** |
| Hives taken via `reg save` | yes |
| Live registry queried without `reg load` | yes |
| Boot-start driver enumeration ran | yes — impossible in r104 |

**`CrashDumpEnabled = 0x7` answers the question that motivated running this before the reboot: a dump will be written if this host bugchecks.** `AutoReboot = 0x1` means it will restart on its own afterwards.

### What failed

Stages 1-11 completed; stage 12 aborted the script:

```
[12/13] Kernel dump and page file (size-checked)...
  MEMORY.DMP: not present
バッチ パラメーターの置き換えで、パス演算子の次の使用法は無効です:
%~z reports 0 for a file the kernel holds open - pagefile.sys on a running
```

Inside a `CALL`ed subroutine cmd.exe resolves argument modifiers **before** deciding a line is a comment, and a bare `%~z` is not a valid modifier. The offending line was the r105 comment explaining why a file's reported size cannot be trusted — **the comment about the modifier contained the modifier**. `MEMORY.DMP` was handled first and its `if not exist` branch jumped past the line; `pagefile.sys` exists, so its call reached it. Full analysis: SPEC §D.51.

### r106 verification

- Test suite **5 cases, 204 assertions**, all passing. New guard scans the subroutine section for any `%~` not followed by a digit, plus a companion assertion that the legitimate `FOR`-variable form (`%%~zf`) survived the edit.
- **Negative control**: against r105 the case reports exactly one failure — the bare modifier.
- Static: `psa.py` 0/0/0 across twelve files; `Parser::ParseFile` 0 errors × 5; canon integrity — 125 records, zero differences.

### Outstanding

1. **Re-run and confirm stages 12 and 13 complete.** `pagefile.sys` is expected to report `size not reportable` and then fail the copy — it is held open on a running system. That is the correct outcome; the point is that the script continues to stage 13 and writes the summary rather than aborting.
2. **Check `Get-Packages.txt`.** Stage 9 ran in this session but the output has not been reviewed — `dism /online` should now produce a real table, and KB4589210's state is in it.
3. `registry\SYSTEM` and `registry\SOFTWARE` should exist via `reg save`, and `registry\boot-start-drivers.txt` should be populated.

### Note on the pattern

This is the fourth defect in this file found only by running it, and the third caused by cmd.exe parsing a line differently from how it reads (SPEC §D.51.4). Each was well-formed by every property the suite checked at the time. The response in each case has been to forbid the construct by shape rather than to rely on remembering the rule.

## 35. Validation Scenario 35: 2026-08-08 first WinRE execution — `findstr` is not there

**Fixture**: the WS2016 host after it stopped booting. `WDF_VIOLATION` confirmed on screen. Booted to WinRE, script generation r106 run from `C:\` with no arguments.

### What worked — the parts that had never been exercised offline

```
Searching for the offline Windows installation...
  found: C:\Windows
Searching for a writable destination...
アクセスが拒否されました。
  found writable: D:
  Collection mode : offline
[ 1/13] 〜 [ 7/13]
```

| Check | Result |
|---|---|
| Mode detection selects `offline` | **yes** |
| Windows volume found by config hive | yes — and it was `C:` in WinRE, contrary to the usual assumption |
| Destination found by write probe | **yes** — the read-only volume ahead of it was rejected and the message proves the probe ran |
| Stages 1-7 | completed |

### What failed

```
[ 7/13] Registry queries...
  CrashControl:
'findstr' は、内部コマンドまたは外部コマンド、
操作可能なプログラムまたはバッチ ファイルとして認識されていません。
```

**WinRE does not ship `findstr`.** Stages 8-16 never ran: no framework binaries, no pending-servicing markers, no dump inventory, no summary — on the one machine that needed them.

The mistake was not using `findstr`; it was **assuming** which commands WinRE has. This project has a rule against that, and it had never been applied to the recovery environment because the recovery environment had never been measured. SPEC §D.52.

### BSOD evidence collected despite the abort

The partial bundle still settled several things:

| Finding | Evidence |
|---|---|
| **No dump exists** | `MEMORY.DMP` 0 hits and `Minidump` 0 hits in the 22 MB system-drive listing |
| **No bugcheck event** | System.evtx parsed: 702 records, zero event 1001, zero Kernel-Power 41 |
| **Log ends on a clean shutdown** | last record is 6006 at 11:02:58 UTC — the log has no record of the crash at all |
| **KB4589210 was mid-apply** | CBS: `Failed to commit CSI transaction due to file in use`, `poqexec` registered in `SetupExecute`, `Reboot required: yes` |
| **The pending work is one file** | `pending.xml`: 55 operations resolving to a single `mcupdate_GenuineIntel.dll` hardlink plus WinSxS/registry bookkeeping |
| **`CrashDumpEnabled` was 0x7** | measured in the previous online run — a dump *should* have been written |

The screen showed "エラー情報を収集しています 60% 完了", so dump writing had started. Why nothing survived is **not established**: the write may not have completed, a second bugcheck may have followed, or the `dir` was taken before the file was finalised.

### On the microcode hypothesis

`KB4589210` is classified `Update` with parent `Microsoft-Windows-MCUpdate-UpdateDLLs-IntelAMD-Package` — a **microcode loader**, not the servicing stack (that was KB5062799, already installed). Two earlier characterisations in this project were wrong and are corrected here.

The operator's hypothesis — that image customisation lost servicing history and Windows Update is re-offering an old package — **is supported for the re-offer** (1-A). It is **not supported as the cause of the bug check** (1-B): `WDF_VIOLATION` is a framework contract violation and does not fit a microcode loader, and the same stop code occurred on a Secure Boot ON clean install before any update ran.

### r107 verification

- Test suite **6 cases, 239 assertions**, all passing. New case `Test-CollectorWdfAssessment.ps1` (35) calls the assessment functions rather than reading their source.
- **Negative control**: against r106 the recovery-collector case reports 14 failures.
- Static: `psa.py` 0/0/0 across thirteen files; `Parser::ParseFile` 0 errors × 5; canon integrity — 125 records, zero differences.

### What the next WinRE run should produce

1. **All 16 stages.** If it stops again, the stage number names the missing tool.
2. **`misc\tool-census.txt`** — the definitive list of what this WinRE has. Read it before assuming anything else.
3. **`framework\driver-framework.txt`** — the KMDF version. Expect **1.19** on WS2016 (SPEC §D.52.2); anything else is a finding.
4. **`misc\dump-presence.txt`** — whether a dump appeared this time.
5. **`misc\bugcheck-reference.txt`** — the 0x10D parameter table, for reading `EventLogs\System.evtx` event 1001 on a working machine.

---

## 36. Measuring the test suite, and why the number must be measured

### 36.1 How to run it

```powershell
./tests/Invoke-TestSuite.ps1
```

No dependencies, no network, no driver state touched. Runs on Windows
PowerShell 5.1 and on PowerShell 7.x, on Windows and on Linux. A single case
can be run with `-Name 'Test-InfWdfRequirement.ps1'`.

The summary ends with the two lines that matter for documentation:

```
  Assertions : 329 passed, 0 failed
  Measured on: PowerShell 7.4.6 (Core) on Unix
```

### 36.2 Record the number the suite printed, not a number you computed

The assertion total is **loop-driven**. Several cases iterate over the
content of the scripts they check — the labels and subroutine calls in
`Collect-OfflineRecoveryEvidence.cmd`, the function names and hashtable keys
in the four sisters — so the count changes whenever that content changes,
including in commits that add no assertion statement at all.

This is not hypothetical. The counts published for r106 and r107 were 204 and
239; the suite reports 212 and 271 for those same trees. The r107 figure is
exactly the r106 **published** figure plus the 35 assertions of the case
added in r107 — a case that was also modified in that release grew by 24
assertions, and the addition never saw them. Both numbers were plausible and
neither was observed. SPEC D.53.7 records the correction; the earlier
CHANGELOG entries are historical records and stand as written.

So, for every release:

1. Run the suite on the current tree.
2. Copy the printed `Assertions :` figure into CHANGELOG and SPEC verbatim.
3. Record the `Measured on:` environment alongside it, because a figure
   without the environment it came from cannot be reproduced or disputed.

Never carry a figure forward and adjust it. If the number is not on screen,
it is not a verification value.

### 36.3 Adding a case

New cases are discovered automatically — any `Test-*.ps1` under `tests/cases`
is picked up, so nothing needs registering. Two things are worth doing in
order:

1. **Confirm the case fails against the defect first.** Place it in the tree
   before the fix and watch it fail, with a message that names the reason. A
   case that has only ever been seen passing is evidence of nothing. For the
   INF WDF work the case was added first and reported `function(s) not found:
   ConvertTo-WdfVersionNumber, Get-InfWdfRequirement`.
2. **Exercise the function, not only its parts.** Static gates see none of
   this: a parameter name that does not exist, an unterminated `[` character
   class, a `try` that spans the wrong range all pass `psa.py` and
   `Parser::ParseFile` (SPEC §D.45.7). Call the thing.

---

## 37. Reading the WDF requirement check on a real host

### 37.1 What to look for in P05

Two forms, both in the P05 phase output:

```
   WDF runtime on this host : KMDF 1.19 / UMDF 2.19
   WDF requirement check : all 55 inventoried INF(s) are within it.
```

or, when something exceeds the runtime:

```
   WDF runtime on this host : KMDF 1.19 / UMDF 2.19
[!] WDF requirement exceeds this host for 2 of 55 inventoried INF(s).
       These packages cannot load here even after cataloguing and signing.
       ...
         - amdpsp.inf (KMDF 1.33 > 1.19)
         - amdsfh.inf (UMDF 2.33 > 2.19)
```

A third form means the check did not run:

```
   WDF requirement check : host framework version could not be read; skipped.
```

That is not a pass. It means `Wdf01000.sys` / `WudfRd.sys` could not be read,
and no comparison was made. Treat it as an unanswered question, and check
`framework\driver-framework.txt` from the collector bundle instead.

### 37.2 What to look for in the run summary

The digest carries the verdict. `READY WITH EXCLUSIONS` is the new one: some
packages cannot load, the rest install normally. It is not `NOT READY` — that
word is reserved for the boot-signing case where nothing this run staged will
load at all. If a run reports `READY WITH EXCLUSIONS`, proceed and expect the
named drivers to be absent afterwards.

### 37.3 The open measurement

The five requirement columns and this comparison have been verified against
fixtures only. **Nobody has yet read them against the real AMD chipset package
— 55 INFs whose declared versions are unknown.** *Historical state as of the
r109 generation; superseded at the package-declaration level by the research
baseline (§44) — the chipset family's declared versions are now measured
across 25 releases (maximum KMDF 1.19). The host-side reading below remains
unperformed and still worth taking.* That measurement is what the
gating decision waits on (SPEC D.54.6), so it is worth taking deliberately:

1. Run `-Action PrepareVerify` on the target host.
2. Open `inf_inventory.csv` and read the `KmdfLibraryVersion`,
   `UmdfLibraryVersion`, `CoInstallerVersions` and `IsWdfDriver` columns.
3. Record how many of the 55 declare a requirement at all, and how many exceed
   the host. On Windows Server 2016 the runtime is KMDF 1.19 / UMDF 2.19
   (SPEC D.52.2), so a package built against a current WDK is the interesting
   case.
4. Note any INF with `IsWdfDriver = False` and a non-empty
   `CoInstallerVersions`. That combination is deliberate and documented
   (SPEC D.53.2) but has never been seen in the field; how often it occurs
   decides whether the definition is revisited.

Nothing in the pipeline changes on the strength of this reading yet. The point
of taking it is to know the numbers before deciding whether it should.

---

## 38. Re-running after the 2026-08-09 field failures

### 38.1 What changed for the operator

Nothing in how the scripts are invoked. The same command that failed now
completes:

```powershell
.\Deploy-AMDChipsetDriverOnWindowsServer.ps1 -Action PrepareVerify -CleanWorkRoot -SkipNonCosignedDrivers
```

### 38.2 What the re-run should look like

With this driver package on this host the plan is still empty — that is a
property of the package, not something the fix changes. The difference is
where the run ends:

| Phase | Before | After |
|---|---|---|
| P06 | `SKIPPED` (empty plan) | `SKIPPED` — unchanged |
| P08 / P09 | `SKIPPED` | `SKIPPED` — unchanged |
| V01 | **`FAILED`** | `done`, with a `[SKIP]` line for patched INFs |
| V02–V06 | **never ran** | run to completion |

If V01 still fails, the guard did not take effect and the tree is not the one
that was patched — check `Script version` in the run header.

### 38.3 What to read in P05

The WDF line now names only KMDF as measured, and states separately what it
could not judge:

```
   WDF runtime on this host : KMDF 1.27 (UMDF is not readable from any binary; see SPEC D.55)
   WDF requirement check : all 119 inventoried INF(s) are within the host KMDF version.
   NOT JUDGED : 8 INF(s) declare a UMDF requirement. ...
```

A `NOT JUDGED` line is not a warning about the package; it is a statement
about the check. To close it by hand, read `UmdfLibraryVersion` in
`inf_inventory.csv` and compare it against the UMDF version documented for the
host build (Windows Server 2019 / build 17763: UMDF 2.27).

If the previous output said `UMDF 10.0`, that was the operating system version
being read as a framework version, and it silently satisfied every UMDF
driver. Any earlier run's UMDF verdict should be treated as never having been
made.

### 38.4 What is still expected to be reported

These are correct outcomes on this host and package, not regressions:

- **P06 empty plan.** No in-scope INF carries a WHQL co-signature. Path A
  cannot proceed; the options are the vendor / Windows Update route, Path B
  with Secure Boot off, or leaving the devices unbound.
- **`Install readiness : NOT READY`** on a run that does produce a plan, while
  Secure Boot is on and the certificate is not yet trusted. That is the
  boot-signing gate doing its job.
- **Phantom file references** in the chipset package (AmdAppCompat, AmdAS4,
  AMDCIR, usbfilter). Documented in SPEC D.24.

---

## 39. Reading the WDF runtime line after the observed/documented split

### 39.1 Two shapes, and which one you are looking at

**The published table is current for this build** — Server 2016, 2019, 2022:

```
   WDF runtime on this host : KMDF 1.27 measured / UMDF 2.27 (documented, corroborated by the KMDF match)
       Wdf01000.sys 1.27.17763.1192 (numeric fields); version string reads 1.27.17763.1 (WinBuild.160101.0800)
```

Both frameworks are being judged. The UMDF figure is labelled `documented`
because nothing on the machine reports it; it is used because the measured
KMDF agreed with the documented KMDF on this same host, which is the evidence
that the published table has kept up with this build.

**Measurement has moved past the table** — seen on Server 2025:

```
   WDF runtime on this host : KMDF 1.35 measured / UMDF runtime present, version not readable from any binary
       Measured KMDF is newer than the published 1.33 for Windows Server 2025. ...
   NOT JUDGED : 8 INF(s) declare a UMDF requirement that was not compared.
```

This is not an error and needs no action. The measurement wins; the published
UMDF beside it is the same age as the published KMDF that was just overtaken,
so it is not used. To close the gap by hand, read `UmdfLibraryVersion` in
`inf_inventory.csv` and compare it against the UMDF version documented for
the build.

### 39.2 The two version readings, and why both are printed

The second line prints the numeric fields and the string resource separately
because they disagree on real hosts. On Windows Server 2019 at 17763.9020 the
same `Wdf01000.sys` reads `1.27.17763.1192` numerically and
`1.27.17763.1 (WinBuild.160101.0800)` as a string: the string is written at
RTM and left alone while the numeric fields move with servicing.

The derived KMDF version comes from the **numeric** fields. If the two lines
disagree in their first two parts, that is worth reporting — it would mean the
assumption behind the reading no longer holds.

Do not use the four-part version as an identity for a framework generation.
Two hosts of the same generation legitimately differ in the last part, and so
do the two readings of a single file.

### 39.3 What to capture on Server 2016 and Server 2022

Neither has been measured yet; the observed column in SPEC D.52.2 is empty for
both. When a host of either is available, the whole measurement is one line of
the P05 output plus one field:

```
   WDF runtime on this host : KMDF <observed> measured / UMDF ...
       Wdf01000.sys <numeric> (numeric fields); version string reads <string>
```

Expected: 1.19 on build 14393 and 1.33 on 20348, both agreeing with the
documented column. **An observation that exceeds the documented value is not a
failure** — it is the Server 2025 case, and it should be recorded in D.52.2
rather than corrected.

---

## 40. Re-running Install after the pre-mutation gate

### 40.1 The expected shape on this host and package

Secure Boot ON, no WHQL co-signature anywhere in the AMD chipset package. The
plan is still empty — that is a property of the package — but the run no
longer reaches anything that changes the machine:

| Phase | Before | After |
|---|---|---|
| I00 | DONE (review) | DONE — unchanged, and still where the guidance is printed |
| I01 | SKIPPED | SKIPPED |
| I02 | **FAILED** | **SKIPPED** |
| I03 | never ran | SKIPPED |
| I04 | never ran | runs |

The run closes with an explicit statement that nothing was installed and
nothing was changed, followed by the three options.

### 40.2 Confirming nothing was changed

The point of this release is that a run against an empty plan leaves no
trace. After an Install run that reports the empty-plan outcome, all three
should be true:

```powershell
bcdedit /enum | Select-String testsigning        # expect: no testsigning line, or "No"
Get-ChildItem Cert:\LocalMachine\Root | Where-Object { $_.Subject -like '*Self-Sign*' }
Get-ChildItem Cert:\LocalMachine\TrustedPublisher | Where-Object { $_.Subject -like '*Self-Sign*' }
```

Any of these returning the script's certificate, or testsigning reading `Yes`,
means a mutating phase ran when it should not have. Report it — that is the
defect this release exists to prevent, not a configuration question.

### 40.3 -UseTestSigning is now refused at startup

On a Secure Boot host the run stops before P00 with an explanation, rather
than in I02 after I01 has imported a certificate:

```
[!] -UseTestSigning cannot succeed on this system: UEFI Secure Boot is ON.
```

`-Force` overrides it and says so. I02 will still refuse the BCD write, which
is correct: `-Force` expresses that the operator knows, not that firmware will
comply.

### 40.4 The banner now says which mode ran

```
 CleanWorkRoot   : True
 Force           : False
 SkipNonCosigned : True
 UseTestSigning  : False
```

Read these first when interpreting any transcript. The same phase list
produces an empty plan or a full one depending on `SkipNonCosigned`, and a
transcript without that line cannot be interpreted after the fact.

### 40.5 What should no longer appear

Two `Get-WinEvent` terminating errors used to print before the first phase on
every run of every script, because bugcheck event 1001 and Kernel-Power 41
return nothing on a machine that has not crashed. They should be gone. Their
absence is not a loss of coverage: `crash-evidence.json` still records the
counts, and a real query failure still lands in its `QueryError` field.

If they reappear, the probe has been reverted to `-ErrorAction Stop`
somewhere — the JSON will still be correct, which is exactly why this needs
watching in the transcript rather than in the evidence.

## 41. The supplemental path now refuses without a base policy identity

Release: Chipset r113 / Graphics r79 / NPU r56 / BthPan r61
(`signing-model-correction`). Background: SPEC D.58. This section is a
reading guide plus the suite measurement; no field run of this release has
happened yet, so every console excerpt below is reconstructed from the code,
not quoted from a transcript.

### 41.1 What changed at the console

Running `-Action Install` without `-WdacBasePolicyGuid` on a host where the
WDAC path would previously have deployed a supplemental policy now refuses
at I02 instead. The Path A sisters print, via `Write-Caution` /
`Write-Detail`:

```
[!] Path A (WDAC supplemental policy) is NOT admissible: no -WdacBasePolicyGuid was supplied.
    A supplemental policy supplements a base policy that must actually exist on this host.
    This script no longer assumes the Windows-shipped base policy GUID as a default
    (third-party audit finding C-02; SPEC D.58.8). Supply -WdacBasePolicyGuid with the GUID
    of a base policy you have verified is deployed with rule option 17
    (Enabled:Allow Supplemental Policies), or use -UseTestSigning on a lab host.
```

The phase closes with footer status `skipped` and records
`Refused = true / Reason = 'no-verified-base-policy'` in the I02 phase
marker — the refusal refuses and returns, per the r112 discipline (SPEC
D.57); it does not fall through to Path B. The startup banner gains one
line, worth reading before interpreting any transcript of this release:

```
 WdacBaseGuid    : (none - supplemental path disabled)
```

A run that *should* deploy a supplemental policy therefore needs an
operator who has verified a base policy exists on the host with rule
option 17 (`Enabled:Allow Supplemental Policies`) and passes its GUID
explicitly. The `-SkipNonCosignedDrivers` Path A chain is unaffected: it
never deploys a policy, and PackageCatalogTrust via I01 does not involve
the gate.

### 41.2 What this does NOT verify yet

The gate checks that the operator supplied an identity, not that the
identity is real. On-host verification (does the named base policy exist;
does it carry option 17) is P1 evidence work — SPEC D.58.8 states the
staging explicitly. Read a passing I02 of this release as "the operator
asserted a verified base policy", nothing stronger.

### 41.3 Measuring the suite, and the negative control

Measured per §36 (counted from the runner's output, not calculated):

- **9 cases, 458 assertions, all passing** — PowerShell 7.4.6 (Core) on
  Linux.
- New case `Test-SupplementalPolicyGate.ps1`: 30 assertions. It checks the
  absence of the assumed GUID from code string constants (AST string
  constants, so historical comments stay legal), the repo-wide absence of
  the `WdacBasePolicyGuidDefault` variable, four-way byte identity of
  `Test-WdacSupplementalPolicyAdmissible`, an empty-`BasePolicyId` throw in
  every builder, and — on the AST — that each phase's gate condition names
  the helper and its refusal branch contains a `return` statement.
- **Negative control**: with the working tree at r112 (the release being
  corrected), the case reports **7 passed, 23 failed**, and every failure
  names its file and line — e.g. the chipset default assignment, the NPU
  hardcoded `Set-CIPolicyIdInfo` argument. A gate that cannot fail against
  the defective version proves nothing (§36, tests/README).

## 42. Reading the c11 evidence: Windows Driver Policy and the kernel trust census

Release: Collector c11 (`windows-driver-policy-and-kernel-trust-evidence`),
P1 remediation wave 1. No field run of c11 exists yet; this section says how
to read the two new files when one does.

### 42.1 `windows-driver-policy.json`

`Mode` is decided only by what `CiTool --list-policies --json` actually
listed: `enforce` / `audit` when the corresponding GUID is present, `absent`
when the parse succeeded and neither is, `unknown` when CiTool is missing or
the parse failed. A WS2019/WS2016 host therefore reads `unknown` with
`Detection.Method = none-available` — that is correct, not a gap.
`EspProbe.Attempted` is always `false` (ruling Q2: the read-only collector
never mounts the ESP; CiTool lists the same policy IDs without one).
`ObservedDriverPaths` comes from the locale-independent `EventDataFields` of
3076/3077 records, never from `Message`.

### 42.2 `kernel-image-trust.json`

One record per kernel-driver service binary. There is deliberately **no
can-load boolean** (gate G-03): read `TrustClassification` + `TrustSource`,
and remember `LegacyCrossSignedAllowListed` can never appear (ruling Q4) — a
cross-signed chain always reads `...NotProven` until an allow-list proof
mechanism exists. Nested/WHQL co-signature inspection is not performed in
c11 (signtool dependency): a binary whose WHQL signature is only nested may
read `PrivateOrTestSigned` — treat the census as a floor, not a verdict,
until the later-wave extension.

### 42.3 Measuring the suite, and the negative controls

Measured per §36: **12 cases, 531 assertions, all passing** on PowerShell
7.4.6 (Core) on Linux. Negative controls, measured against the c10 tree:
`Test-WindowsDriverPolicyEvidence.ps1` reports **20 failures** and
`Test-KernelImageTrustEvidence.ps1` **17 failures**, each naming the missing
function or schema key. `Test-CustomKernelSignersClaim.ps1` passes on both
trees by design — the retraction already landed in the previous release —
and carries its own embedded negative control instead.
## 43. Wave W5 (2026-08-09): measured PnP rank — operator-pending field validation

`ConvertFrom-PnputilEnumDevicesDrivers` is fixture-tested against a
SYNTHETIC transcript (assembled from the Microsoft Learn
pnputil-command-syntax page and public field observations). The following
remains operator-pending on a physical host with a WS2022+/Windows-11-era
pnputil build:

1. Run `pnputil /enum-devices /drivers` (elevated) and archive the raw
   output next to the run artifacts.
2. Confirm the field shapes the parser assumes: `Instance ID:` /
   `Device Description:` / `Matching Drivers:` / `Driver Name:` /
   `Original Name:` / `Provider Name:` / `Driver Version:` /
   `Matching Device Id:` / optional `Rank:` (0x hex or decimal).
3. If a shape differs, replace the synthetic fixture with a redacted real
   transcript excerpt and adjust the parser — fixtures must copy real
   output; synthetics are a bootstrap only.
4. On at least one device bound to a project INF, confirm that
   `Show-MeasuredDriverRankReport` marks `[ours]` correctly and that the
   first-listed candidate matches the actually-bound driver.

---

## 44. Package-side WDF declarations: the research baseline (2026-08-09)

§37 was written when the declared versions inside the AMD chipset package
were unknown. The package side is now measured — not by a field run, but by
the in-repo research layer:

- **Where**: `tools/amd-chipset-driver-research/` — a read-only toolkit and
  its accepted baseline covering **25 AMD chipset releases** with **643
  hardware-matched INF rows**, SHA-256-pinned.
- **What it says**: declared `KmdfLibraryVersion` across the family is
  1.11 / 1.13 / 1.15 / **1.19 (maximum)**; declared `UmdfLibraryVersion`
  is 2.15.0.
- **What that supersedes**: the §37 premise that the package's declared
  versions are unknown, and the README claim (now retracted) of a
  structural WS2016 KMDF ceiling — WS2016's *documented* runtime is
  KMDF 1.19 (SPEC D.52.2), equal to the maximum declaration measured.
- **What it does NOT supersede**: the host-side reading §37 instructs
  (WS2016's own KMDF has never been measured by this project — its
  D.52.2 cell still says `not yet measured`); the graphics and NPU
  package families, which have no measured baseline; and the
  `WDF_VIOLATION` investigation (SPEC D.47), which stays open and was
  never explained by a ceiling.
- **Standing**: the baseline is **evidence, not policy**. No pipeline
  decision consumes it at run time; it exists to be cited.

---

## 45. Reading SourceArtifact evidence files (W8)

Every completed download-verification writes `source-artifact_<file>.json`
next to the artifact itself (workspace download directory). Reading guide:

- `Attestation` is the headline: `verified` means the Authenticode gate
  passed; `operator-attested-unverified` means the operator supplied
  `-AllowUnverifiedDownload` on a FAILED verification and owns the risk —
  `FailReason` says why it failed, and `AuthenticodeStatus` may read
  `HostCannotVerify` when the host could not run the check at all.
- `Sha256` is always present and is the join key toward the research
  baseline and future provenance work (W13); `RetrievedAtUtc` is the
  artifact's own mtime (cache-honest), `ObservedAtUtc` is when the record
  was written.
- `FormatValidation` is a minimal magic check (`exe:MZ`, `msi:CFB`,
  `unknown`) — it detects container mismatch, not content validity.
- The record is evidence, not a gate: writing it is fail-open by design,
  and a missing record on an admitted file indicates an evidence-path
  problem worth a REVIEW, not a deployment failure by itself.

---

## 46. Reading the inventory-reconciliation delta report (W11)

`tools/inventory-reconciliation/Compare-ResearchDeploymentInventory.ps1`
joins the research accepted baseline against a deployment run's
`inf_inventory.csv` and writes a typed delta report. Reading guide:

- `ExitCriterion.UnexplainedDeploymentOnly` is the headline: the tool
  exits 0 iff it is 0. This is also the hard gate the static-extraction
  waves (W12/W15) depend on.
- `MatchedVariant` rows are explained by suffix-versioned CAB entries
  (`name.infN`) under the extraction tree — the MSI external-CAB
  multi-version convention; their `Evidence` is the variant file path.
- `MatchedNormalizedName` rows differ only by `-`/`_` separators; the
  research row is the `Evidence`.
- `ExplainedDeploymentOnly` rows come from the `-KnownExplanations`
  allowlist. Discipline: every entry requires an operator adjudication
  `Reason`, and the allowlist is reviewed like code — it narrows a
  named delta, never the criterion itself.
- `ResearchOnly` is informational (one run vs 25 releases). Input files
  are SHA-256-pinned in the report for provenance.
- Parity here is metadata-level; the optional content-hash upgrade is
  the operator bench step described in the tool README.

## 47. Reading the static-extraction shadow graph (W12)

Chipset r120 writes `<WorkRoot>\manifests\extraction-graph.json` on
every run (always on, fail-open). Reading guide:

- `Status` is the headline: `ExtractionComplete` (every container
  extracted cleanly AND at least one INF found), `PartialExtraction`
  (clean containers but zero INF — never conflated with complete),
  `ExtractedWithErrors` (at least one container failed),
  `ExtractionFailed`, or `ShadowFailed` (the orchestrator itself threw;
  the deployment run continued — the shadow is evidence, not a gate).
- `ParityNote` is the W15 decision input:
  `ShadowInfBaseCount + ShadowInfVariantCount` vs `CurrentTreeInfCount`.
  Variants are the suffix-versioned `name.infN` CAB entries; counting
  only base names reproduces the historical 31-INF blind spot.
- `Infs[]` rows carry `CabEntryName` (as extracted), `ResolvedName`
  (File-table `short|long` long name where available), `VariantIndex`,
  and a per-file SHA-256.
- `MsiFileTable.Status` is typed: `Read` (COM read succeeded),
  `Failed` (COM present but errored), `Unavailable` (non-Windows host
  or no MSI found). On `Failed`/`Unavailable` the resolver falls back
  to the suffix convention and says so — it never guesses silently.
- `Containers[]` records use the audit 13-field shape; `Depth`,
  `ParentContainerSha256` and `ProducedContainers` reconstruct the
  recursion tree. `Extractor` is `ISSetupStream` or `7-Zip`.
- The shadow tree itself sits under `<WorkRoot>\shadow-extracted\`,
  cleaned at the start of each run and retained afterwards for
  inspection.

## 48. Reading the content-addressed cache and canonical inventory (W13)

- A schemaVersion-2 marker is JSON with `input` / `output` blocks, each
  carrying `fields` and a `fingerprint` (lowercase SHA-256 of the sorted
  canonical `key=value` lines). `meta` still holds the legacy metadata
  payload unchanged.
- Cache MISS diagnostics are named in the phase log: an input-side miss
  says the artifact SHA / schema constant diverged (or the marker is
  legacy), an output-side miss says what changed on disk (the INF layer
  under the extract tree, or the canonical JSON's own hash). A pre-W13
  marker always misses a fingerprinted check — re-run the phase once to
  mint a v2 marker.
- `-Force` misses every marker check, v2 included; it does not delete
  evidence files.
- `package-inventory.json` is the canonical inventory;
  `inf_inventory.csv` and the TXT report are derived views. When they
  disagree, the JSON wins — and a hand-edited JSON will be rejected on
  the next cache hit because its SHA-256 no longer matches the P05
  marker's recorded `InventorySha256`.
- Per-record `InspectionStatus = ParseFailed` means the INF could not be
  read; `InspectionError` carries the reason and the WDF observation for
  that record is `ParseFailed` with zero versions. Absence of a WDF
  declaration is `NotDeclared` — the vocabulary never renders absence as
  a capability.
- On resume (`-OnlyPhases`), P05 chains `InfManifestSha256` from the P04
  marker record and MSBthPan's P05 chains `CopiedSetSha256` from its P04
  record; a broken chain surfaces as a named input-side miss, not a
  guess.
