# TESTING.md — Physical Hardware Validation Results

This document consolidates the validation results for `Deploy-Drivers-For-WindowsServer`. Because this repository ships **experimental scripts that target AMD's consumer-class Ryzen chipset / Radeon iGPU / Ryzen AI NPU**, all meaningful validation depends on access to physical AMD consumer hardware. Testing on non-AMD-consumer hardware (server-class EPYC, ARM, Intel, virtual machines without the target devices, etc.) cannot exercise the device-bind, driver-upgrade, or post-install verification paths that this pipeline exists to validate. This document therefore covers only physical-hardware validation:

1. **Validation Result 1: ThinkCentre M75q Tiny Gen 2** (Windows Server 2025 physical / Cezanne Zen 3 — chipset & graphics validated)
2. **Validation Result 2: ThinkPad X13 Gen 1 AMD (2020)** (Windows 11 Enterprise LTSC 2024 / Renoir Zen 2 — chipset & graphics validated)
3. **Validation Result 3 (NPU script)** — **🆘 NOT YET VALIDATED on physical NPU hardware. See [§3](#3-validation-result-3-npu-script--currently-unverified) for the current limited validation status.**
4. **Validation Result 4 (BthPan script)** — ⏳ **PLANNED.** ThinkPad + Intel AX210 + Windows Server 2025 build 26100.32860 is the first physical-validation target. See [§4](#4-validation-result-4-bthpan-script--planned) for the planned test sequence.

> **Documentation language policy**: This document is maintained in
> English only. See `README.md` and `README.ja.md` for the bilingual
> entry-point documentation; for the repository-wide language policy
> see `SPEC.md` §A.12.

---

## 0. Validation status summary

> Read this before sections 1-3. The four scripts have **very different validation maturity levels**.

| Script | Physical-hardware validation | Real driver install on target HW | Recommended use |
|---|---|---|---|
| **Chipset** | ✓ M75q Tiny Gen 2, X13 Gen 1 AMD (see CHANGELOG for per-revision validation history) | ✓ install completed successfully on M75q (WS2025) | Lab + cautious production |
| **Graphics** | ✓ M75q Tiny Gen 2, X13 Gen 1 AMD (see CHANGELOG for per-revision validation history) | ✓ install completed successfully on M75q (WS2025) | Lab + cautious production |
| **NPU** | ❌ **none** (no physical NPU machine in maintainer's lab) | ❌ **never executed** | **Experimental / research-grade only. Do not deploy in production.** |
| **BthPan** | ⏳ **planned** — ThinkPad + Intel AX210 + Windows Server 2025 build 26100.32860 is the first target (see §4 below) | ❌ **not yet executed** | New script; physical validation pending. Logic shares the proven Phase / Secure Boot / WDAC framework from the Chipset script (Edit-InfForServer, Get-OsContext, Resolve-PhaseSelection, etc. are verbatim-inherited). |

> **Note on the category-priority override** (see SPEC §D.15): The
> category-priority override changes the install-decision semantics
> in a breaking way for chipset and graphics: self-signed `[C]` drivers
> now always supersede Microsoft generic `[A]` and vendor `[B]` drivers
> regardless of version. Earlier physical-hardware validation results
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

1. **Static analysis** with `psa.py` (latest mainline) (36-rule check set including the PSA8xxx cross-file consistency / PSA9xxx complexity / PSAPxxxx project-convention families — `PSAP0001`..`PSAP0004`, **0 errors / 0 warnings / 0 info** with the repository-shipped `.psa.config.json` — see `SPEC.md` §A.11.5). `psa.py` is maintained as a canonical artifact in the [ai-generated-artifacts](https://github.com/usui-tk/ai-generated-artifacts) repository; obtain it per `SPEC.md` §A.11 before running, and follow the "Version policy" subsection there (validate against the latest mainline, no fixed-version pinning). Before the analysis pass, two cheap pre-flight self-quality gates SHOULD be run when applicable: `psa.py --config-check .psa.config.json` whenever `.psa.config.json` has been edited, and `psa.py --self-check` whenever a freshly-fetched `psa.py` is being introduced — see `SPEC.md` §A.11.6 for the activation matrix.
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
| 3 | I02 prints the warning block as Write-Warn2 messages and continues to the existing legacy Secure Boot guard (which uses the OS-layer `$bootEnvBefore.SecureBootEnabled` view). | If both views agree on "off", Path B proceeds normally. If they diverge, the legacy guard fires. |

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
| 1 | WS2019 host without the WDK installed; `Find-Signtool` returns `$null`. Install set has a non-WHQL primary signer (typical for AMD's own publisher cert on non-co-signed drivers). | — |
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

---
