# Deploy-Drivers-For-WindowsServer

PowerShell pipeline that makes AMD's consumer-targeted Ryzen chipset, Radeon graphics, and Ryzen AI NPU (XDNA) drivers — **plus Microsoft's inbox Bluetooth PAN driver (`bthpan.inf` / `bthpan.sys`)** — installable on Windows Server 2016 / 2019 / 2022 / 2025 by patching the INF `ProductType=3` decoration and re-signing the catalog with a self-generated certificate.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE) [![PowerShell 5.1+](https://img.shields.io/badge/PowerShell-5.1%2B-blue.svg)](https://learn.microsoft.com/en-us/powershell/) [![Target: Windows Server 2025](https://img.shields.io/badge/Target-Windows%20Server%202025-success.svg)](https://learn.microsoft.com/en-us/windows-server/get-started/windows-server-2025)

> **Read this twice before running anything.** This is a *last-resort, lab-only* tool. AMD does not officially support Windows Server 2025 for consumer Ryzen platforms (e.g. Cezanne / Renoir / Phoenix APUs in Lenovo ThinkCentre Tiny / ThinkPad / mini-PC builds). When official drivers exist, **always prefer those**. This repository exists for the narrow case where official Server-class drivers are unavailable and you are willing to operate a self-signed driver chain on your own hardware, at your own risk.

> **🆘 EXTRA WARNING for the NPU script (`Deploy-AMDNpuDriverOnWindowsServer.ps1`):** The NPU script is **markedly more dangerous and far less mature** than the chipset and graphics scripts. It is **unvalidated on physical NPU hardware** as of this writing, the AMD account auto-download flow is **best-effort and can break without notice** when AMD changes form layouts, and Ryzen AI Software (the user-mode stack required to actually use the NPU) is **officially unsupported on Windows Server 2025 by AMD**. Treat the NPU script as **experimental / research-grade**, not as a production tool. See [Risk classification](#risk-classification-of-the-four-scripts) below.

🇯🇵 **日本語版 README は [README.ja.md](./README.ja.md) を参照してください。**

---

## Table of Contents

- [Why this exists](#why-this-exists)
- [⚠️ Disclaimer (read before running)](#%EF%B8%8F-disclaimer-read-before-running)
- [What's in the box](#whats-in-the-box)
- [What's new](#whats-new)
- [Risk classification of the four scripts](#risk-classification-of-the-four-scripts)
- [Scope of coverage](#scope-of-coverage)
- [Folder layout](#folder-layout)
- [Quick start](#quick-start)
- [BthPan-specific quick start](#bthpan-specific-quick-start)
- [NPU-specific quick start](#npu-specific-quick-start)
- [Pipeline architecture (21 phases)](#pipeline-architecture-21-phases)
- [Parameters (per script)](#parameters-per-script)
- [Output files](#output-files)
- [UEFI Secure Boot baseline](#uefi-secure-boot-baseline)
- [Console output format](#console-output-format)
- [System requirements](#system-requirements)
- [Self-signed certificate: expiry, renewal, and revocation](#self-signed-certificate-expiry-renewal-and-revocation)
- [Disclaimer & at-your-own-risk acknowledgements](#disclaimer--at-your-own-risk-acknowledgements)
- [Troubleshooting](#troubleshooting)
- [Development tools](#development-tools)
- [Developer specification](#developer-specification)
- [File encoding](#file-encoding)
- [References](#references)
- [License](#license)
- [Contributing](#contributing)

Related documents:

- [`CHANGELOG.md`](./CHANGELOG.md) — chronological per-release change log (English only)
- [`SPEC.md`](./SPEC.md) — developer specification (architecture, conventions, design rationale; English only)
- [`TESTING.md`](./TESTING.md) — physical-hardware validation results and regression checklist (English only)
- [`CONTRIBUTING.md`](./CONTRIBUTING.md) — how to file issues, propose changes, and run regression tests (English only)
- [`README.ja.md`](./README.ja.md) — Japanese translation of this document, kept in sync

---

## Why this exists

When you install Windows Server 2025 on a consumer-class AMD platform (Ryzen 4000 / 5000 / 6000 / 7000 / 8000 mobile / desktop APU, plus discrete Vega / Polaris / RDNA Radeon GPUs, plus Ryzen AI 300 / AI Max 300 with NPU) several AMD devices end up bound to **Microsoft's generic in-box drivers** (`machine.inf`, `pci.inf`, `hdaudbus.inf`, `display.inf`) or remain unbound entirely (NPU). The reasons are two-fold:

1. **AMD's INF files contain a `ProductType=1` (Workstation) restriction** in the `[Manufacturer]` decoration. Windows Setup honours this and refuses to bind the driver on a Server SKU (`ProductType=3`).
2. **AMD's catalog (.cat) signature attests to the original INF.** Even if you patch the INF to add Server decorations, the signature is invalidated and the driver fails kernel-mode signing checks — which Windows Server 2025 enforces strictly via Secure Boot and HVCI.

This pipeline solves both problems by:

- Parsing AMD's Workstation `[Manufacturer]` decorations and **mirroring each one with `ProductType=3` (Server)**, leaving the original Workstation entries intact (so the patched INF is bi-compatible).
- Generating a fresh `.cat` catalog with `inf2cat /os:Server2025_X64`.
- **Signing the catalog with a self-generated code-signing certificate**, importing the cert into `LocalMachine\Root` + `LocalMachine\TrustedPublisher`, and authorising the cert as a kernel-mode signer via a **WDAC supplemental Code Integrity policy** (which keeps Secure Boot **on** — no `bcdedit /set testsigning on` required on Windows Server 2022+ / Windows 11 22H2+).

---

## ⚠️ Disclaimer (read before running)

**USE AT YOUR OWN RISK.** These scripts are provided "AS IS" without warranty of any kind, express or implied. The authors and contributors are not liable for any damages, data loss, BSODs, BitLocker recovery prompts, account suspension, hardware instability, or any other problems — direct or indirect — that may arise from using, modifying, or distributing these scripts.

> **🆘 BRICK-LEVEL RISK (2026-05-23 field observation).** On the WS2019 + Ryzen 5 PRO 4650U (Renoir) pilot bench, a successful end-to-end run of `Chipset Install` → `Graphics Install` → `MSBthPan Install` (in that order, **no reboot between scripts**, post-r04 orchestrator) left the host **unable to complete the next boot — including Safe Mode** — requiring an OS reinstall. The most plausible root cause is the cumulative kernel-driver surface installed during a single uninterrupted Install pass: the patched AMD display driver (`u0201039.inf`, 1066+ HWID variants) replaces the inbox `display.inf`, AMD PSP firmware bindings change, and the WDAC SPF policy must be re-evaluated by the boot loader against several brand-new self-signed catalogs at once. Any one of those interacting with Secure Boot enforcement at boot time can leave the host without a working display path or with kernel CI rejection of a boot-critical driver. The post-r04 I00 risk summary currently labels the typical case `[MEDIUM]` — that label is **too low for hosts with Secure Boot ON, BitLocker enabled, or no spare display path**. Treat any `Install` action on a production-shaped host as having a non-trivial probability of leaving the host non-bootable until reinstall. See SPEC §D.26 and TESTING §12 for the full incident narrative and the strict best-practice sequencing this surfaced.

> **🖥️ Physical-machine-only deployment model.** This repository targets **physical Windows Server hosts** running on consumer Ryzen / Athlon hardware (Lenovo M75q Tiny, ThinkPad X13 Gen 1 AMD, etc.). It is not a VM-targeted toolkit. **Physical machines have no native "snapshot" mechanism** — there is no `Hyper-V Checkpoint` or `VMware Revert to Snapshot` you can call before `-Action Install` and roll back to in seconds after. Full disk imaging (Macrium Reflect, Clonezilla, dd via Linux Live USB) is possible but is a **separate, hours-long, requires-second-storage-device** workflow that lives entirely outside this repository. **Windows Server System Restore is OFF by default**, and even when enabled it does **not** capture `C:\Windows\System32\CodeIntegrity\SiPolicy.p7b` (the WDAC SPF policy this orchestrator deploys, which is evaluated by the boot loader before System Restore can run). The practical consequence is that **a failed `-Action Install` on a physical machine has no fast-rollback path**; remediation is either offline WinRE repair (covered in [Recovery from unbootable state](#recovery-from-unbootable-state)) or OS reinstall. **The supported deployment model is therefore: a physical machine you are prepared to wipe and reinstall.** Do not run these scripts on a physical host whose current OS install you cannot afford to lose.

By running these scripts, you acknowledge that:

* You are solely responsible for verifying that your use complies with AMD's End User License Agreement, Microsoft's Windows Software License Terms, and any applicable laws or regulations
* You understand that patching AMD's INFs and re-signing them with your own certificate makes **you** — not AMD, not Microsoft — the cryptographic publisher of those drivers from Windows' point of view
* You accept that **WHQL certification is invalidated** for any driver this pipeline replaces; if you rely on Microsoft Premier Support for affected hardware, your support contract may not cover issues caused by self-signed drivers
* You will record your **BitLocker recovery keys** before running `-Action Install` on the chipset script (the PSP driver replacement interacts with Platform Security Processor firmware and can trigger recovery prompts on next boot)
* You accept that **the host may fail to boot at all — including Safe Mode** — after an `-Action Install`, and that recovery in that case requires WinRE / installation media / a separate working host to repair the disk offline (or, as the project's primary remediation, an OS reinstall). The supported deployment model is therefore: **a physical machine you are prepared to wipe and reinstall** — not an in-production server you cannot afford to lose. Optional non-destructive rollback paths require advance preparation BEFORE `-Action Install`: see the "Step 0 — pre-flight" subsection of [Full installation](#full-installation-chipset-graphics-bthpan) below for the recommended pre-flight checklist on physical machines.
* You will run **only one script at a time**, reboot, and verify with `-OnlyPhases V06` before running the next script. Running `Chipset Install` → `Graphics Install` → `MSBthPan Install` back-to-back without reboots has been observed to brick the host (see the field observation above).
* You will review the script source code and understand its behavior before running it in any environment
* For the **NPU script specifically**, you understand it is **experimental / research-grade** — see [Risk classification](#risk-classification-of-the-four-scripts) below

Operate these tools considerately. **Always prefer official AMD Server-supported drivers when they exist.** This repository targets the narrow case where official Server-class drivers are unavailable and you are willing to operate a self-signed driver chain on your own hardware.

For the full at-your-own-risk acknowledgements (BitLocker, anti-cheat software, support implications, cert expiry, etc.), see the [Disclaimer & at-your-own-risk acknowledgements](#disclaimer--at-your-own-risk-acknowledgements) section further down. For the recommended sequence of operations and what to do when the host is unbootable, see the [Recovery from unbootable state](#recovery-from-unbootable-state) section.

---

## What's in the box

| File | Purpose | Maturity |
| --- | --- | --- |
| `Deploy-AMDChipsetDriverOnWindowsServer.ps1` | Chipset driver pipeline (GPIO, SMBus, PSP, MicroPEP, PMF, etc.). Source: AMD Chipset Software ~75 MB EXE, ~67 INFs. | **Stable** — validated on M75q Tiny Gen 2 (WS2025) and X13 Gen 1 AMD (Win11 LTSC 2024). |
| `Deploy-AMDGraphicsDriverOnWindowsServer.ps1` | Graphics driver pipeline (Display, HD Audio, Audio CoProcessor, ACP, USB-C UCSI, etc.). Source: AMD Adrenalin Edition ~600 MB EXE, ~19 INFs (Vega-Polaris Legacy branch) or ~67 INFs (Main Adrenalin branch for Phoenix+). | **Stable** — same validation hosts as chipset. |
| **`Deploy-AMDNpuDriverOnWindowsServer.ps1`** | **NPU (Ryzen AI XDNA) driver pipeline (PHX/HPT/STX/KRK).** Source: AMD Ryzen AI Software ZIP, ~250 MB, EULA-gated download (no public direct URL). Kernel-mode driver only — does NOT install Ryzen AI Software user-mode stack. | **🆘 Experimental / research-grade — NOT production-ready.** No physical-NPU validation runs have been performed. AMD account auto-download is best-effort and may break with AMD form changes. Ryzen AI Software is officially unsupported on Windows Server 2025. |
| `Deploy-MSBthPanInboxOnWindowsServer.ps1` | **Microsoft inbox Bluetooth PAN driver (`bthpan.inf` / `bthpan.sys`) enablement pipeline.** Source: the host's own `C:\Windows\System32\DriverStore\FileRepository\bthpan.inf_amd64_*` directory — **no remote download required.** Single INF, single HWID (`BTH\MS_BTHPAN`). Distinguishes Phantom OK (bth.inf proxy match) from true resolution (Class=Net, Service=BthPan) on Windows Server. | **New** — initial release. Logic shares the same Phase / Secure Boot / WDAC framework as the AMD scripts; INF patch surface is much smaller (1 INF, 1 HWID). Physical validation on ThinkPad + Intel AX210 + WS2025 build 26100.32860 is the planned first test target. |
| **`Deploy-WdacSinglePolicyFormatOnLegacyWindowsServer.ps1`** | **External WDAC orchestrator for Windows Server 2019 / 2016.** Builds, deploys, and tracks WDAC Single Policy Format (SPF) policies — the only WDAC format available on these legacy server OSes (the Multiple Policy Format used on WS2022+ requires `CiTool.exe` which is not present on WS2019/2016). Called automatically by the four driver scripts' I02 phase when running on WS2019/2016 (build < 20348). Eight Actions: `GetStatus`, `AddCert`, `RemoveCert`, `Verify`, `Uninstall`, `Repair`, `ComputeCanonicalHash`, `ComputeOwnCanonicalHash`. | **r04 — pilot-validated on WS2019.** Added in r67 (r03 release); pilot validation on WS2019 build 17763 + Ryzen 5 PRO 4650U (Renoir) + Secure Boot ON succeeded at r04 (2026-05-23) after r03 surfaced an `Add-HistoryEntry` `param()`-block scope-qualifier defect that left hosts in a stuck-Foreign state. Seeded from Chipset r66 per the sister-script discipline (SPEC §A.13); 34 shared helpers are inherited byte-for-byte from Chipset r66 (PSA8001 actively enforces sync for 30 of them; the 4 Secure Boot baseline diagnostic helpers are in `.psa.config.json` `psa8001_ignore_functions` but are still inherited verbatim). See SPEC §D.25 for design rationale and r01..r04 validation history, and TESTING §11 for test cases. |
| `README.md` | This document (English; the master). |  |
| `README.ja.md` | Japanese translation of `README.md`, kept in sync. |  |
| `SPEC.md` | Developer specification (per-script details, INF parsing strategy, WDAC policy structure). **English only.** |  |
| `TESTING.md` | Physical-hardware validation results. Includes the NPU script's far weaker validation status. **English only.** |  |
| `CHANGELOG.md` | Chronological per-release change log. **English only.** |  |
| `CONTRIBUTING.md` | How to file issues, propose changes, and run regression tests. **English only.** |  |
| `LICENSE` | MIT License. |  |

All four PowerShell scripts share the same 21-phase architecture, the same self-signing model, and the same WDAC authorisation path. They write to separate workspaces (`C:\Temp\Workspace_AMD-Chipset`, `C:\Temp\Workspace_AMD-Graphics`, `C:\Temp\Workspace_AMD-NPU`, `C:\Temp\Workspace_Microsoft-BthPan`) and use separate self-signed certificates + separate WDAC supplemental policy GUIDs so they never collide. All four workspaces sit under `C:\Temp\Workspace_*` for cluster-and-purge convenience; the script auto-creates `C:\Temp` on demand.

---

## What's new

See [CHANGELOG.md](./CHANGELOG.md) for the chronological per-release entry log
organised by date and by script — this is the single source of truth for
what the main branch ships at any given moment. For the architectural
rationale behind individual fixes, see
[SPEC.md Part D](./SPEC.md#part-d--known-pitfalls--lessons-learned).

## Risk classification of the four scripts

> This section exists because the NPU script is materially riskier than its sister scripts and operators must understand the difference before running it. The BthPan script is the lowest-risk of the four because its driver source is the host's own DriverStore (no remote download), the INF surface is exactly one file with one HWID, and Microsoft itself signs the inbox driver — only the catalog must be re-signed.

| Aspect | Chipset script | Graphics script | **NPU script** | **BthPan script** |
| --- | --- | --- | --- | --- |
| **Maturity** | Stable, multiple validation cycles | Stable, multiple validation cycles | **🆘 Experimental — not yet validated on physical NPU hardware** | **New** — initial release. Logic shares the proven Phase / Secure Boot / WDAC framework. Single-INF surface is small enough that physical validation is feasible in one session. |
| **Distribution format** | Public EXE direct download | Public EXE direct download | **EULA-gated ZIP, requires AMD account** | **No download** — `bthpan.inf` is already staged at `C:\Windows\System32\DriverStore\FileRepository\bthpan.inf_amd64_*` on every Windows install. |
| **Public download URL** | Yes (direct) | Yes (direct) | **No — requires AMD account login + EULA acceptance per release** | **N/A — driver is on the host.** |
| **AMD account auto-download** | N/A | N/A | **Best-effort; depends on AMD's form HTML staying stable; can break without notice** | **N/A.** |
| **OS support stance** | AMD does not officially support, but drivers run | AMD does not officially support, but drivers run | **Driver loads on Server 2025, but Ryzen AI Software (user-mode stack) does NOT work on Server 2025 per AMD docs** | **Microsoft inbox driver — fully supported by Microsoft on Workstation SKUs.** Filtered out on Server SKUs only because of the `NTamd64...1` ProductType decoration. This script supplies the missing ProductType=3 decoration without touching Microsoft's binary at all. |
| **Hardware availability** | Common (any AMD APU machine) | Common (any AMD GPU/APU machine) | **Limited to Ryzen AI 300 / Ryzen AI Max 300 / Ryzen 7040/8040 series** | Common — any machine with a Bluetooth host controller bound and `BTH\MS_BTHPAN` enumerated. Most ThinkPads, mini-PCs, NUCs ship one. |
| **Test fixtures available in repo** | M75q Tiny Gen 2, X13 Gen 1 AMD | M75q Tiny Gen 2, X13 Gen 1 AMD | **NONE — no physical NPU machine in the maintainer's lab as of this writing** | ThinkPad + Intel AX210 + WS2025 build 26100.32860 (planned first physical validation). |
| **Failure modes specific to this script** | PSP / TPM driver replacement may trigger BitLocker recovery | Display reset on signed-cat install | NPU device may not enumerate; Ryzen AI Software won't work | **Phantom OK trap** — bth.inf may proxy-match and report Status=OK even though bthpan.sys is NOT loaded. V06 / I04 must explicitly distinguish Phantom OK (DriverInfPath=bth.inf, Class=Bluetooth) from true resolution (DriverInfPath=oem*.inf, Class=Net, Service=BthPan). |
| **Recommended use** | Lab + cautious production | Lab + cautious production | **Lab / research only. Do not deploy on production hosts.** | **Lab + cautious production.** Risk is low because the script does not replace any vendor driver — it only enables the Microsoft-published inbox driver on a SKU class where Microsoft chose not to ship it by default. |
| **Recommended Action mode** | `Install` after `PrepareVerify` review | `Install` after `PrepareVerify` review | **`PrepareVerify` ONLY until you can confirm the host is a real NPU machine and you accept that Ryzen AI Software won't function on Server 2025** | `PrepareVerify` first to confirm Phantom-OK vs true-resolution state, then `Install`. |

**Practical rules of thumb for the NPU script**:

1. **Do not run `-Action Install` on a host you cannot afford to roll back.** The cleanup path is implemented but driver-store removal is best-effort and may require manual `pnputil /delete-driver oemNN.inf /force` cleanup.
2. **The Ryzen AI Software user-mode stack** (Python conda env + ONNX Runtime VitisAI EP + OGA) **is officially Windows-11-only.** Even if the kernel driver loads on Server 2025, you will not be able to run inference workloads through the supported stack. Do not expect AI workload functionality on Server 2025; the kernel driver is at most an experiment in driver bring-up.
3. **There are no physical-NPU validation runs yet.** All current verification is static analysis with `psa.py` and code-review of the AMD-published `quicktest.py` detection logic translated to PowerShell. **Real hardware behaviour is unconfirmed.**
4. **AMD's account auto-download flow can break without notice.** AMD periodically updates their `account.amd.com` form structure, CSRF token names, and EULA acceptance endpoint. The script's Tier 2 authentication is best-effort. **Always prefer Tier 4 (`-OfflineZip`)** for reproducible runs.

If after reading the above you still want to run the NPU script: see [NPU-specific quick start](#npu-specific-quick-start).

---

## Scope of coverage

### Hardware in scope

- **AMD Ryzen Mobile**: Ryzen 4000 (Renoir), 5000 (Cezanne / Lucienne / Barcelo / Barcelo-R), 6000 (Rembrandt), 7000 (Phoenix / Hawk Point), 8000 (Hawk Point refresh), AI 300 (Strix Point / Krackan Point), AI Max 300 (Strix Halo).
- **AMD Ryzen Desktop APU**: Ryzen 5000G / 5000GE (Cezanne), 7000G / 8000G (Phoenix).
- **AMD Radeon Graphics**: Vega 6 / 7 / 8 / 11 (integrated, Renoir → Cezanne → Barcelo), RDNA 3 (Phoenix 780M / 760M), RDNA 3.5 (Strix Point), discrete RX 5000 / 6000 / 7000 / 9000 series.
- **AMD AM4 / AM5 chipsets**: X470, X570, X670/X670E, X870/X870E, B450, B550, B650, B850.
- **AMD ACPI devices**: GPIO controllers (`AMDI0030`, `AMDF030`), I2C (`AMD0010`), Micro PEP (`AMD0004`), HSMP (`AMDI0097`), PMF (`AMDI0100` / `AMDI0102`), SFH (`AMDI0080` / `AMDI0011`), UART (`AMD0020`), Wireless Button (`AMDI0051`), Pluton stub (`MSFT0200` / `MSFT0201`).
- **AMD NPU / XDNA Compute Accelerator** *(experimental, NPU script only)*:
  - **Phoenix / Hawk Point** (`PCI\VEN_1022&DEV_1502&REV_00`) — Ryzen 7040 / 8040 / 8040 PRO mobile series. Driver build `32.0.203.280` (RAI 1.5).
  - **Strix Point / Strix Halo** (`PCI\VEN_1022&DEV_17F0&REV_00/10/11`) — Ryzen AI 300 / Ryzen AI Max 300 series. Driver build `32.0.203.314` (RAI 1.6.1) or newer.
  - **Krackan Point** (`PCI\VEN_1022&DEV_17F0&REV_20`) — Ryzen AI 200 series. Driver build `32.0.203.314` (RAI 1.6.1) or newer.
- **Microsoft inbox Bluetooth PAN** *(BthPan script only)*:
  - **HWID**: `BTH\MS_BTHPAN` — child device exposed by every Microsoft-supported Bluetooth host controller after the host controller binds. Vendor-agnostic (Intel AX2xx, Realtek RTL88xx, MediaTek MT7xxx, Broadcom BCM43xx, etc.).
  - **Prerequisite**: a Bluetooth host controller driver is bound and showing Status=OK in Device Manager. If the host controller itself is unknown-device, install its vendor driver first; this script does NOT cover host controllers.
  - **Symptom this script solves**: on Windows Server SKU, `BTH\MS_BTHPAN` shows as Unknown Device (code 28), or shows Status=OK but with `DriverInfPath=bth.inf` and `Class=Bluetooth` (Phantom OK; `bthpan.sys` is NOT loaded and `BthPan` service is NOT running).
  - **Verified true-resolution criteria**: `DriverInfPath=oem*.inf`, `Class=Net`, `Service=BthPan`, `C:\Windows\System32\drivers\bthpan.sys` present, `BthPan` service registered, a Bluetooth PAN NetAdapter visible to `Get-NetAdapter`.

### Operating systems in scope

The driver scripts (Chipset, Graphics, NPU, BthPan) support both
**modern Windows Server** (2022 build 20348, 2025 build 26100) and
**legacy Windows Server** (2019 build 17763, 2016 build 14393):

| OS | Build | I02 path | Notes |
|---|---|---|---|
| Windows Server 2025 | 26100 | Path A (MPF supplemental) | Primary validation target. |
| Windows Server 2022 | 20348 | Path A (MPF supplemental) | Validated. |
| Windows Server 2019 | 17763 | **Path C (legacy WDAC SPF via external orchestrator)** | r67 new path; pilot-validated at r04 (2026-05-23) on WS2019 + Renoir + Secure Boot ON. r03 surfaced an `Add-HistoryEntry` `param()`-block defect (`$Script:CertThumbprint` scope qualifier); r04 fixes it. See SPEC §D.25. |
| Windows Server 2016 | 14393 | **Path C (legacy WDAC SPF via external orchestrator)** | Path C also covers this build (same r04 fix applies). Field validation pending on a physical WS2016 host. |
| Windows 10 / 11 (Workstation) | any | PrepareVerify only | Install phases auto-blocked. |

Legacy server hosts (WS2019 / WS2016) automatically delegate I02 to
`Deploy-WdacSinglePolicyFormatOnLegacyWindowsServer.ps1` because the
`CiTool.exe` + Multiple Policy Format infrastructure used on WS2022+
is not available on the older Windows kernel. Keep this orchestrator
co-located with the driver scripts (it is part of this repository),
or ensure outbound access to `raw.githubusercontent.com` so the
driver scripts can fetch it. See [SPEC §D.25](./SPEC.md) for the full
design rationale.

### Hardware **out of scope**

- **AMD EPYC server chips** (server-class CPUs found in cloud instances, Hetzner AX dedicated, etc.): EPYC uses a different chipset model and ships first-party Server-supported drivers via Microsoft Update. This pipeline targets *consumer* Ryzen, not EPYC.
- **Real-time GPU compute stacks** (ROCm, HIP SDK, OpenCL beyond the user-mode driver shipped in the Adrenalin package): consult AMD's ROCm documentation for Server.
- **Ryzen AI Software user-mode stack** (Python conda env, ONNX Runtime VitisAI Execution Provider, OnnxRuntime GenAI/OGA, Vitis AI Quantizer, Lemonade SDK, etc.): **out of scope of the NPU script.** The NPU script installs the kernel-mode driver only. Ryzen AI Software must be installed separately by the operator from the AMD installer at <https://account.amd.com/en/forms/downloads/xef.html?filename=ryzen-ai-lt-1.7.1.exe>, and per AMD documentation it is officially supported on Windows 11 build >= 22621.3527 only.

---

## Folder layout

Repository structure (after `git clone`):

```
Deploy-Drivers-For-WindowsServer/
├── Deploy-AMDChipsetDriverOnWindowsServer.ps1     Chipset driver pipeline (21 phases)
├── Deploy-AMDGraphicsDriverOnWindowsServer.ps1    Graphics driver pipeline (21 phases)
├── Deploy-AMDNpuDriverOnWindowsServer.ps1         NPU (Ryzen AI XDNA) pipeline (21 phases)
├── Deploy-MSBthPanInboxOnWindowsServer.ps1        Microsoft inbox bthpan pipeline (21 phases)
├── README.md                                      This document (English; master)
├── README.ja.md                                   Japanese translation, kept in sync
├── TESTING.md                                     Physical-hardware validation results (EN only)
├── SPEC.md                                        Developer specification (EN only)
├── CHANGELOG.md                                   Chronological per-release change log (EN only)
├── CONTRIBUTING.md                                Issue / PR guidelines (EN only)
├── SECURITY.md                                    Vulnerability reporting (EN only)
├── CODE_OF_CONDUCT.md                             Community behaviour (EN only)
├── LICENSE                                        MIT License
├── .psa.config.json                               psa.py configuration (PSAP rules opt-in)
├── .gitattributes                                 Git line-ending normalization
└── .gitignore                                     Standard ignores
```

### What the scripts produce

After `-Action PrepareVerify` (or `-Action All`), each script populates its workspace:

```
C:\Temp\Workspace_AMD-Chipset\   (or C:\Temp\Workspace_AMD-Graphics\, C:\Temp\Workspace_AMD-NPU\, C:\Temp\Workspace_Microsoft-BthPan\)
├── download\              AMD installer EXE / NPU driver ZIP
│                          (BthPan: empty — driver source is DriverStore, not downloaded)
├── extracted\             Original INFs and binaries from the EXE / ZIP / DriverStore
│                          (BthPan: extracted\bthpan\bthpan.inf / .sys / .cat)
├── patched\               Patched INFs with mirrored ProductType=3 sections
│                          + generated .cat files + signtool signatures
│                          (BthPan: patched\bthpan\ — single INF directory)
├── cert\                  Self-signed code-signing cert (PFX + CER) +
│                          WDAC supplemental policy XML/CIP
└── inf_inventory.csv / inf_inventory_report.txt
                           P05 inventory and per-INF analysis
                           (BthPan: single-row CSV — exactly one INF)
```

After `-Action Install` (or phases I01-I04), the script also deploys:

- The cert to `LocalMachine\Root` + `LocalMachine\TrustedPublisher`.
- A **WDAC supplemental Code Integrity policy** to `C:\Windows\System32\CodeIntegrity\CiPolicies\Active\` that allowlists this specific cert as a kernel-mode signer. This is activated immediately via `CiTool --update-policy` (no reboot required on Windows Server 2022+ / Windows 11 22H2+).
- The patched + self-signed drivers via `pnputil /add-driver /install`.

---

## Quick start

### Prerequisites

- Windows Server 2025 host (build 26100), or Windows 11 24H2 (build 26100) for **preview-only verification** (the script will block `Install` phases on Workstation OS unless `-AllowWorkstationInstall` is passed; see [TESTING.md](./TESTING.md) for the WS2025 pre-migration verification workflow).
- PowerShell 5.1 or higher (Desktop or Core), 64-bit, running as Administrator.
- Internet connectivity (for AMD installer download and Windows SDK / WDK installation via `winget`).
- ~5 GB free disk space on the workspace volume (~7 GB if you also run the NPU script — Ryzen AI ZIPs are ~250 MB plus extracted contents).

### Get the scripts

```powershell
# Option 1: clone the repository
git clone https://github.com/usui-tk/Deploy-Drivers-For-WindowsServer.git
cd Deploy-Drivers-For-WindowsServer

# Option 2: download a release ZIP from
# https://github.com/usui-tk/Deploy-Drivers-For-WindowsServer/releases
```

### One-shot dry run (safe; modifies nothing)

```powershell
# In an elevated PowerShell session
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass

.\Deploy-AMDChipsetDriverOnWindowsServer.ps1   -Action PrepareVerify -CleanWorkRoot
.\Deploy-AMDGraphicsDriverOnWindowsServer.ps1  -Action PrepareVerify -CleanWorkRoot
.\Deploy-MSBthPanInboxOnWindowsServer.ps1      -Action PrepareVerify -CleanWorkRoot

# NPU script — REQUIRES an offline ZIP (or other download source) to actually run P03.
# On a clean machine without -OfflineZip, P03 will throw "All 4 download tiers exhausted".
# See the NPU-specific quick start below for the full pattern.
.\Deploy-AMDNpuDriverOnWindowsServer.ps1 -Action PrepareVerify -CleanWorkRoot `
    -OfflineZip .\NPU_RAI1.6.1_314_WHQL.zip -AssumeIfMissing
```

`PrepareVerify` runs `P00-P09` (locate / extract source, patch, generate catalog, sign) followed by `V01-V06` (verify artefacts, dry-run install plan, hardware impact analysis). **No system state is modified** — no certs are imported, no WDAC policy is deployed, no drivers are installed. Read the V05 / V06 output to understand exactly what `Install` *would* do.

> **BthPan-specific note**: the BthPan script's P03 (FetchInstaller) does NOT download anything — it locates `bthpan.inf` in the host's own `C:\Windows\System32\DriverStore\FileRepository\bthpan.inf_amd64_*` directory. P03 fails only on hosts where the inbox driver has been deliberately removed (extremely rare).

### Full installation (chipset, graphics, BthPan)

> **🆘 Do NOT run these three scripts back-to-back without reboots.** That sequence was directly observed to leave WS2019 + Renoir unable to boot — including Safe Mode — and there is no automated rollback. The supported sequence is described below.

> **Physical-machine reality check (read before Step 0).** This repository targets physical Windows Server hosts, not VMs. Physical machines have no "snapshot" feature you can call from PowerShell, no `Restore-VMSnapshot` to roll back to seconds after a bad `Install`. Server SKU System Restore is OFF by default and even when on does **not** roll back `SiPolicy.p7b`. Full disk imaging (Macrium Reflect, Clonezilla, dd) is possible but requires an external drive sized for your C: and is a separate workflow that runs outside Windows. The Step 0 checklist below codifies what is actually practical and effective on a physical machine: ensure you have a working repair path **before** you need it, record the keys you would otherwise be locked out by, and run scripts one at a time so the blast radius of any failure is bounded.

```powershell
# ---- 0. Pre-flight (physical machine) — complete BEFORE -Action Install ----
#
#   A. Create a Windows recovery USB on a SECOND machine.
#      You cannot create one after the target is bricked.
#         - In Windows 10/11/Server 2022+: search for "Create a recovery
#           drive" (`RecoveryDrive.exe`) on a working host. Use a 16+ GB
#           USB stick. This gives you WinRE: command prompt, Startup
#           Repair, System Image Recovery, and `bcdedit`.
#         - Alternative: download the Windows Server 2019/2022/2025 ISO
#           matching the failed host's edition from the Volume Licensing
#           Service Center (VLSC) or Microsoft Evaluation Center, then
#           use Rufus / MediaCreationTool to write it to a USB stick.
#           Installation media also boots straight into WinRE via
#           "Repair your computer" on the first screen.
#         - Test the USB boots on a known-good machine before you need it.
#
#   B. Record BitLocker recovery keys IF BitLocker is enabled on C:.
#         manage-bde -protectors -get C: | Out-File C:\BitLockerKeys.txt
#      Print the file or save it to a separate device. The chipset
#      script's PSP driver replacement can trigger BitLocker recovery
#      on next boot.
#
#   C. (Strongly recommended, but optional.) Take a full disk image of
#      the system drive to external media:
#         - Macrium Reflect Free (rescue media boot + image C: to USB-
#           attached drive), or Clonezilla, or `dd if=/dev/sdX` from a
#           Linux Live USB. Expect 20-60 minutes for typical NVMe sizes.
#         - This is the ONLY mechanism that allows full rollback of a
#           bricked physical host without OS reinstall. It is not
#           required by the scripts, but it is the difference between
#           "30 minutes to restore" and "an afternoon to reinstall +
#           reconfigure".
#
#   D. Confirm you have an OS install ISO + matching license key on
#      hand. If steps A-C all fail at recovery time, reinstall is the
#      explicitly-supported recovery path of last resort. Knowing in
#      advance that you can rebuild the host within the day is part of
#      "a physical machine you are prepared to wipe".
#
#   E. Note: -CleanWorkRoot does NOT make this any safer. The destructive
#      side effects of Install are on the OS itself, not the workspace.

# ---- 1. Install the chipset drivers FIRST and reboot ----
.\Deploy-AMDChipsetDriverOnWindowsServer.ps1 -Action Install
# After completion, REVIEW the I04 output:
#   - Count of LOADED, REBOOT_NEEDED, LOAD_FAILED, FAILED
#   - If LOAD_FAILED > 0: STOP. Diagnose before continuing.
#   - If REBOOT_NEEDED > 0: reboot now.
Restart-Computer
# After the host comes back up, confirm baseline:
.\Deploy-AMDChipsetDriverOnWindowsServer.ps1 -OnlyPhases V06
# Only if V06 reports the expected post-install state, proceed.

# ---- 2. Install the graphics drivers and reboot ----
.\Deploy-AMDGraphicsDriverOnWindowsServer.ps1 -Action Install
# I04 review (same as step 1). If LOAD_FAILED > 0 OR Section 2 shows
# functional probe failures, STOP. Recovery is much easier from this
# checkpoint than from later in the chain.
Restart-Computer
.\Deploy-AMDGraphicsDriverOnWindowsServer.ps1 -OnlyPhases V06

# ---- 3. Install BthPan (smallest surface, lowest risk) ----
.\Deploy-MSBthPanInboxOnWindowsServer.ps1 -Action Install
# If I04 prints "*** TRUE RESOLUTION NOT YET ACHIEVED ***", reboot
# and re-run. PnP rebind sometimes requires a fresh boot.
```

All scripts are idempotent and cleanup-safe (`-Action Cleanup` removes the workspace, the certs from the trust stores, and the deployed WDAC policy). However, **Cleanup runs from a booted host**; if `Install` left the host unbootable, see [Recovery from unbootable state](#recovery-from-unbootable-state).

> **What about running everything in one pass?** Conceptually, all three Install actions converge on the same end state — patched INFs in the driver store plus a single WDAC SPF policy authorizing all three self-signed certs. In practice, doing it as one uninterrupted sequence has a strictly worse failure mode: each Install can introduce a regression that only becomes visible at the next boot, and the per-script post-install verification (I04 / V06) cannot fully predict boot-time behaviour because it runs in the live OS, before the boot loader re-evaluates the WDAC SPF policy against the new catalogs. Running one script at a time with a reboot between bounds the blast radius of any single regression to "the most recently installed family", which is the difference between "roll back one driver via WinRE" and "reinstall the OS".

> **BthPan-specific outcome check**: after the BthPan script's `Install` action completes, I04 (PostInstallVerification) explicitly distinguishes Phantom OK from true resolution. The script prints `*** TRUE RESOLUTION ACHIEVED ***` only when `bthpan.sys` is loaded, `BthPan` service is running, and `BTH\MS_BTHPAN` reports `Class=Net, Service=BthPan, DriverInfPath=oem*.inf`. If you instead see `*** TRUE RESOLUTION NOT YET ACHIEVED ***`, a reboot is the typical fix (PnP rebind sometimes requires a fresh boot).

> **NPU script `Install`**: see [NPU-specific quick start](#npu-specific-quick-start). The `Install` action requires extra preconditions (offline ZIP availability or AMD account credentials) and is **not recommended without physical NPU hardware**.

### Recovery from unbootable state

If a reboot after `-Action Install` leaves the host unable to boot (display blank, infinite reboot loop, BSOD-on-boot, **Safe Mode also fails**, etc.), the realistic recovery options on a physical machine are listed below in the order operators should actually attempt them. Note the ordering is different from a VM context: WinRE-based offline repair comes first here because most physical-host operators will not have a disk image ready.

1. **WinRE-based offline repair** (primary path on a physical machine without a pre-existing disk image). Boot the recovery USB you created in Step 0A. From WinRE → Troubleshoot → Advanced options → Command Prompt, try the following in order, rebooting between each step to see if the host comes back:

   1.1. **Identify the system drive's letter under WinRE.** WinRE re-letters drives, so `C:` from the running OS may be `D:` or `E:` here. Run `diskpart`, `list volume`, find the volume with the Windows installation, note its letter, then `exit`. The examples below use `C:` — replace with your actual letter.

   1.2. **Revert any uncommitted Setup transaction:**
   ```cmd
   dism /image:C:\ /cleanup-image /revertpendingactions
   ```
   This undoes a pending driver install or servicing operation that didn't finish before the failed reboot. Always try this first — it is the cheapest fix and resolves a meaningful fraction of cases where the install transaction itself was the problem.

   1.3. **Remove the published OEM drivers this repository's scripts added:**
   ```cmd
   dism /image:C:\ /get-drivers /format:table
   ```
   Identify the `oem<NN>.inf` entries published by this repository (the Provider column will show the self-signed cert Subject CN, e.g. `AMD Chipset Driver Self-Sign (WS2019 Lab, At Own Risk)`). For each, remove it:
   ```cmd
   dism /image:C:\ /remove-driver /driver:oem<NN>.inf
   ```
   This removes the offending driver-store entries without booting the broken OS. After all repository-published OEM drivers are removed, reboot.

   1.4. **Last-resort: remove the WDAC SPF policy.** If the host still doesn't boot, the WDAC SPF policy itself may be rejecting a boot-critical driver. Delete it from WinRE:
   ```cmd
   del C:\Windows\System32\CodeIntegrity\SiPolicy.p7b
   ```
   This reverts the host to "no WDAC SPF policy", which removes the orchestrator's enforcement layer entirely. **If BitLocker is enabled on C:, you will be prompted for your recovery key on the next boot** — this is why Step 0B is mandatory.

   1.5. **Startup Repair as a final WinRE-side attempt:** Troubleshoot → Advanced options → Startup Repair. Microsoft's automatic repair handles a small set of boot-loader-only corruptions that the above commands don't address.

2. **Roll back to a pre-Install full disk image** (if you took one in Step 0C). On a physical machine this means booting the imaging tool's rescue media (Macrium / Clonezilla / etc.) and restoring the C: image to the original drive. Expect 20–60 minutes depending on drive size. This is the **fastest path to a known-good state IF you have an image**, but most physical-machine operators will not.

3. **Pull the disk and read offline from a working machine.** If the recovery USB doesn't boot for some reason (UEFI Secure Boot policy on the failed host rejecting it, etc.), the next step is to physically remove the drive, attach it to a working machine via USB-to-NVMe / SATA adapter, and run `dism /image:` and `del` commands from that second machine. This is slower than option 1 but covers cases where the failed host won't boot any external media.

4. **OS reinstall** (last resort). When options 1–3 fail or are not practical (no recovery USB, no spare machine, no disk image), reinstall from your Step 0D media. This is the explicitly-supported recovery path of last resort for this repository, and is the reason the disclaimer emphasises "a physical machine you are prepared to wipe and reinstall".

The repository **does not** ship a recovery script that runs from inside a broken OS, because by the nature of the failure mode the OS is no longer running. The protections we do ship are entirely pre-emptive: the Step 0 checklist above, aggressive `-Action PrepareVerify` dry-run output, V05/V06 hardware-impact analysis, and the strict reboot-between-scripts sequencing.

### Selective phase execution

```powershell
# Just regenerate the patched INFs and catalogs without re-downloading
.\Deploy-AMDChipsetDriverOnWindowsServer.ps1 -Action Prepare -OnlyPhases P05,P06,P08,P09

# Run only the cert-trust phase
.\Deploy-AMDChipsetDriverOnWindowsServer.ps1 -Action Install -OnlyPhases I01

# Run only the BthPan Phantom-OK readiness analysis (no system change)
.\Deploy-MSBthPanInboxOnWindowsServer.ps1 -OnlyPhases V06

# List all phases the script knows about
.\Deploy-AMDChipsetDriverOnWindowsServer.ps1 -Action ListPhases
```

---

## BthPan-specific quick start

> The BthPan script is the simplest of the four to run because the driver source is the host's own DriverStore — no network download, no AMD account, no EULA-gated ZIP.

### Step 1 — confirm the Bluetooth host controller is bound

The BthPan script handles only `BTH\MS_BTHPAN` (the Personal Area Network child device exposed after the Bluetooth host controller is bound). The host controller itself is **out of scope**.

```powershell
# Confirm the host controller is showing Status=OK (NOT "Unknown device").
Get-PnpDevice -Class Bluetooth -ErrorAction SilentlyContinue |
    Select-Object FriendlyName, Status, InstanceId

# If the host controller (e.g. Intel AX210, Realtek RTL8852, MediaTek MT7921)
# is "Unknown device", install its vendor driver first. The bthpan script
# does NOT install host-controller drivers.
```

### Step 2 — diagnose the current state (no system change)

```powershell
.\Deploy-MSBthPanInboxOnWindowsServer.ps1 -OnlyPhases V06
```

V06 prints the per-instance classification of every `BTH\MS_BTHPAN*` device on the host. Three states are possible:

| Classification | Meaning | Recommended next step |
| --- | --- | --- |
| **Unknown** | Status=Error (code 28). No driver is bound. | Run `-Action Install`. |
| **Phantom** | Status=OK, but `DriverInfPath=bth.inf`, `Class=Bluetooth`, `Service=(empty)`. `bthpan.sys` is **NOT** loaded; PAN networking is broken even though Device Manager looks fine. | Run `-Action Install`. After install, I04 verifies the rebind. |
| **True** | `DriverInfPath=oem*.inf`, `Class=Net`, `Service=BthPan`. `bthpan.sys` is loaded; BthPan service is running. | No action needed. The host is already at true resolution. |

### Step 3 — full installation

```powershell
.\Deploy-MSBthPanInboxOnWindowsServer.ps1 -Action All -CleanWorkRoot
```

`-Action All` runs all 21 phases (`P00-P09` → `V01-V06` → `I00-I04`) in a single command. I03 includes `pnputil /scan-devices` to force the PnP manager to re-evaluate `BTH\MS_BTHPAN` so it rebinds from `bth.inf` (the Phantom proxy match) to the patched `oem*.inf` (true resolution).

If I04 reports `*** TRUE RESOLUTION NOT YET ACHIEVED ***`, a reboot is the typical fix; sometimes the PnP rebind only takes effect on next boot. Re-run the same command after reboot — the script's resume-after-reboot logic detects the new state and reports `*** TRUE RESOLUTION ACHIEVED ***`.

### Step 4 — decoration strategy choice (advanced)

```powershell
# Strategy A (default): NTamd64...3 only (ProductType=3 covers all Server SKUs).
.\Deploy-MSBthPanInboxOnWindowsServer.ps1 -DecorationStrategy A

# Strategy B: also add NTamd64.10.0...14393 / 17763 / 20348 / 26100 explicitly.
# Provides slightly higher PnP-ranking advantage when a future Microsoft inbox
# update adds Server decorations of its own. Requires manual update for any
# new Server SKU build that ships in the future.
.\Deploy-MSBthPanInboxOnWindowsServer.ps1 -DecorationStrategy B
```

In practice **Strategy A is sufficient** on all four supported Server builds (14393 / 17763 / 20348 / 26100). Strategy B exists for environments where multiple coexisting bthpan packages compete for the binding slot and per-build entries give a deterministic tie-break.

### Step 5 — verify the outcome

```powershell
# bthpan.sys present?
Test-Path C:\Windows\System32\drivers\bthpan.sys

# BthPan service registered + running?
Get-Service BthPan -ErrorAction SilentlyContinue

# Bluetooth PAN NetAdapter visible?
Get-NetAdapter | Where-Object InterfaceDescription -Match 'Bluetooth.*Personal Area Network'

# Device-level state (Class should be Net, Service should be BthPan):
Get-PnpDevice -InstanceId 'BTH\MS_BTHPAN*' |
    Get-PnpDeviceProperty -KeyName DEVPKEY_Device_Class, DEVPKEY_Device_Service, DEVPKEY_Device_DriverInfPath
```

---

## NPU-specific quick start

> **Reminder**: this script is experimental. Read [Risk classification of the four scripts](#risk-classification-of-the-four-scripts) before continuing.

> **🆘 r17 (2026-05-23, Q-X1) — NPU refuses Install on legacy Windows Server.** Starting in r17, `Deploy-AMDNpuDriverOnWindowsServer.ps1` will **refuse `-Action Install` and `-Action All` on Windows Server 2019 (build 17763) and Windows Server 2016 (build 14393)**. The AMD NPU driver pipeline has not been validated on legacy Server SKUs that require the WDAC Single Policy Format (SPF) path, and running it would exercise unvalidated SPF interaction code with no physical-hardware test coverage. **Non-destructive actions remain available** on WS2019/2016: `-Action PrepareVerify` (default), `-Action Prepare`, `-Action Verify`, `-Action Cleanup`, `-Action ListPhases`. If you need NPU on WS2019/2016, open a GitHub issue — the path can be enabled after dedicated physical validation. See SPEC §D.27.

### Step 1 — obtain the NPU driver ZIP (one of the four tiers)

The NPU script supports **four download tiers** in priority order:

| Tier | Method | When to use |
| --- | --- | --- |
| **1** | `-InstallerUrl <url>` explicit URL | You already have a fresh AMD CDN URL (e.g. from an `entitlenow.com` link captured in a browser session). |
| **2** | `-AmdAccountUser <email> -AmdAccountPassword <SecureString> -ForceAmdAccountAuth` | Attempt EULA acceptance flow automatically. **❌ Disabled by default since 2026-05-10 verification found `account.amd.com` is a JavaScript-driven SPA. Use `-ForceAmdAccountAuth` to opt in (expected to fail on the current AMD portal).** See TESTING.md §3.6 for the full verification report. |
| **3** | EULA-gated direct fetch probe | Automatic; almost always falls through (AMD requires JS-driven submission). |
| **4** ★ | `-OfflineZip <path>` or sibling `NPU_RAI*_WHQL.zip` in the script directory | **Recommended.** Manually download the ZIP once, place it next to the script. Reproducible across runs. |

For Tier 4, manually download the ZIP from the AMD documentation page:

- <https://ryzenai.docs.amd.com/en/latest/inst.html#install-npu-drivers>
- Click the appropriate driver link for your detected NPU (e.g. NPU Driver 32.0.203.314 for STX/KRK, RAI 1.6.1).
- Sign in to your AMD account, accept the EULA, save the ZIP locally (typical filename: `NPU_RAI1.6.1_314_WHQL.zip`).

### Step 2 — dry run (no system state modified)

The recommended pattern is **`-Action PrepareVerify` + `-OfflineZip`**. With `-OfflineZip`, the 4-tier resolution short-circuits at the Tier 4 priority block (line 824 of the script) and your local ZIP is used immediately — no AMD network calls, no form-parsing fragility.

```powershell
# RECOMMENDED — pipeline soundness check, system state UNCHANGED.
# OfflineZip is taken from the Tier 4 priority block immediately; no AMD network calls.
# On a real NPU host (Ryzen AI 300 / AI Max 300 / 7040 / 8040 series):
.\Deploy-AMDNpuDriverOnWindowsServer.ps1 `
    -Action PrepareVerify `
    -CleanWorkRoot `
    -OfflineZip .\NPU_RAI1.6.1_314_WHQL.zip
```

```powershell
# Pipeline-soundness check on a host without an NPU device — same as above plus -AssumeIfMissing.
# When P03 detects no NPU device, the script falls back to the default Strix Point profile
# instead of failing. Useful only for testing the pipeline mechanics; produces 0 device bindings
# and provides no validation of real NPU behaviour.
.\Deploy-AMDNpuDriverOnWindowsServer.ps1 `
    -Action PrepareVerify `
    -CleanWorkRoot `
    -OfflineZip .\NPU_RAI1.6.1_314_WHQL.zip `
    -AssumeIfMissing                            # default Strix Point + RAI 1.7.1
```

```powershell
# DISCOURAGED — pipeline check WITHOUT -OfflineZip on a clean machine.
# This command will:
#   Tier 1 (-InstallerUrl)            : skipped (not provided)
#   Tier 4 priority (-OfflineZip)     : skipped (not provided)
#   Tier 2 (AMD account auto-download): skipped (no credentials)
#   Tier 3 (EULA-gated direct probe)  : almost always falls through (HTML form)
#   Tier 4 auto-scan                  : checks script dir, ./cache, workspace, ~/Downloads
# If -CleanWorkRoot has wiped the workspace AND no NPU_RAI*_WHQL.zip is in any of the
# auto-scan locations, P03 will throw "All 4 download tiers exhausted".
.\Deploy-AMDNpuDriverOnWindowsServer.ps1 -Action PrepareVerify -CleanWorkRoot
```

### Step 3 — install (only if you have real NPU hardware AND have read all warnings)

```powershell
# RECOMMENDED — full install using a manually-downloaded offline ZIP.
.\Deploy-AMDNpuDriverOnWindowsServer.ps1 `
    -Action Install `
    -OfflineZip .\NPU_RAI1.6.1_314_WHQL.zip
# I00 will require you to type "I AGREE" to acknowledge:
#   1) AMD Ryzen AI EULA acceptance
#   2) Ryzen AI Software being officially Windows-11-only
#   3) Kernel-mode driver only (user-mode stack must be installed separately)
#   4) BitLocker recovery keys recorded
```

After successful installation, the script prints a guidance block reminding you that **Ryzen AI Software (Python conda env, OGA, Vitis AI EP) must be installed separately** from <https://account.amd.com/en/forms/downloads/xef.html?filename=ryzen-ai-lt-1.7.1.exe>, and that this user-mode stack is officially supported on Windows 11 build >= 22621.3527 only — **not on Windows Server 2025**.

### Useful NPU-specific switches

The NPU script tracks **two independent versioning axes** plus a **separate compatibility evaluation axis**, per AMD's [Ryzen AI Software installation documentation](https://ryzenai.docs.amd.com/en/latest/inst.html):

| Axis | Parameter | Default | What it controls |
|---|---|---|---|
| **A. NPU kernel-mode driver** | `-NpuDriverPackage` | `latest` (= `NPU_RAI1.6.1_314`) | Which NPU driver ZIP package the script targets. AMD currently publishes only two: `NPU_RAI1.5_280` (driver 32.0.203.280) and `NPU_RAI1.6.1_314` (driver 32.0.203.314). Both cover all NPU codenames (PHX/HPT/STX/STH/KRK). Driver versioning evolves slowly. |
| **B. Ryzen AI Software (user-mode stack)** | `-RyzenAiSoftwareVersion` | `latest` (= `1.7.1`) | Which Ryzen AI Software version is referenced in the post-install guidance (you install the EXE separately). AMD recommends **always using the latest** for end-user workloads. |
| **C. Compatibility evaluation** | (automatic) | n/a | Computed from A + B at P03. Currently AMD documents that all RAI versions require driver `≥ 32.0.203.280`, so both `280` and `314` are compatible with RAI `1.5` through `1.7.1`. |

Switches in column A and B are **independent**. They do not need to share a version label; e.g. `-NpuDriverPackage NPU_RAI1.6.1_314 -RyzenAiSoftwareVersion 1.7.1` is a valid, AMD-supported combination (newer driver + latest RAI Software).

These switches **modify behaviour but do not provide a download source** by themselves. Always combine them with `-OfflineZip`, `-InstallerUrl`, or `-AmdAccountUser`/`-AmdAccountPassword -ForceAmdAccountAuth` (Tier 4 / Tier 1 / Tier 2 respectively).

```powershell
# Force a specific NPU codename (when CPU name detection is ambiguous; e.g. PHX vs HPT).
# Combine with -OfflineZip for predictable behaviour:
.\Deploy-AMDNpuDriverOnWindowsServer.ps1 `
    -Action PrepareVerify `
    -OfflineZip .\NPU_RAI1.6.1_314_WHQL.zip `
    -NpuOverride STX                            # PHX | HPT | STX | KRK

# Pin a specific NPU driver package (axis A). Note: -NpuDriverPackage selects which
# package the script reasons about. Your -OfflineZip must match the same package.
.\Deploy-AMDNpuDriverOnWindowsServer.ps1 `
    -Action Install `
    -OfflineZip .\NPU_RAI1.6.1_314_WHQL.zip `
    -NpuDriverPackage NPU_RAI1.6.1_314          # NPU_RAI1.5_280 | NPU_RAI1.6.1_314 | latest

# Pin a specific Ryzen AI Software version (axis B). Default 'latest' is recommended.
# This affects only the post-install guidance message - the user installs the
# Ryzen AI Software EXE separately via the AMD download page.
.\Deploy-AMDNpuDriverOnWindowsServer.ps1 `
    -Action Install `
    -OfflineZip .\NPU_RAI1.6.1_314_WHQL.zip `
    -RyzenAiSoftwareVersion latest              # 1.5 | 1.6.1 | 1.7 | 1.7.1 | latest

# AMD account auto-download (Tier 2 — DISABLED by default since 2026-05-10 verification.
# Pass -ForceAmdAccountAuth to opt in. Expected to fail on current AMD SPA portal.)
$cred = Get-Credential -UserName 'you@example.com' -Message 'AMD account password'
.\Deploy-AMDNpuDriverOnWindowsServer.ps1 `
    -Action Install `
    -ForceAmdAccountAuth `
    -AmdAccountUser $cred.UserName `
    -AmdAccountPassword $cred.Password
```

> **Common pitfall**: running `-Action Install -NpuOverride STX -NpuDriverPackage NPU_RAI1.6.1_314` **without** specifying any download source will fall through to Tier 4 auto-scan and silently use whatever `NPU_RAI*_WHQL.zip` happens to be in `~/Downloads` — which may or may not match the package you specified. **Always pin the source explicitly**.

---

## Pipeline architecture (21 + 1 phases)

The four scripts share a 21-phase pipeline (P00–P09, V01–V06, I00–I04). The BthPan script adds **one extra Install-group phase (`I05`)** that recovers from a stuck-driver state without reboot when (and only when) I04 detected one. The 21 shared phases are run by all four scripts; I05 is BthPan-only.

| Group | ID | Name | What it does |
| --- | --- | --- | --- |
| Prep | P00 | Initialize | OS detection, admin/TLS pre-flight, WS2025-preview-mode banner if Workstation; the NPU script also prints a Ryzen-AI-Software OS-support warning |
| Prep | P01 | PrepareWorkspace | Create `C:\Temp\Workspace_AMD-{Chipset,Graphics,NPU}\` or `C:\Temp\Workspace_Microsoft-BthPan\` (auto-creates `C:\Temp` on demand) |
| Prep | P02 | AcquireTools | Install 7-Zip, Windows SDK (signtool) and Windows WDK (inf2cat) via `winget`, fall back to direct EXE |
| Prep | P03 | FetchInstaller | Detect host AMD platform; resolve the latest installer URL from amd.com (chipset/graphics) or run the 4-tier resolution (NPU); download |
| Prep | P04 | ExtractInstaller | 7-Zip extraction; the NPU script also handles nested ZIP detection |
| Prep | P05 | AnalyzeInfs | Inventory every INF, classify by source variant (W11x64 / WTx64 / WT6A_INF / WT64A; for NPU: PHX/HPT vs STX/KRK), and select those in scope for the host OS / NPU |
| Prep | P06 | PatchInfs | For INFs lacking Server decorations, mirror each Workstation `[Manufacturer]` entry with `ProductType=3`; copy already-Server-compatible INFs to the patched folder so they reach the install pipeline |
| Prep | P07 | CreateCertificate | Self-sign a 4096-bit RSA / SHA-384 code-signing cert (5-year validity), exported as PFX and CER |
| Prep | P08 | GenerateCatalogs | `inf2cat /os:Server2025_X64` for each patched INF folder |
| Prep | P09 | SignCatalogs | `signtool sign /fd SHA384 /td SHA384 /tr <timestamp-url>` on every catalog |
| Verify | V01 | VerifyArtifacts | Confirm cert + patched INFs + catalogs all exist |
| Verify | V02 | VerifyCertificate | Decode the PFX, check EKU, validity, key length |
| Verify | V03 | VerifyCatalogs | `signtool verify /pa` (expected to fail until I01 trusts the cert) |
| Verify | V04 | VerifyInfs | Re-parse patched INFs and confirm `ProductType=3` decoration coverage |
| Verify | V05 | DryRunInstall | Simulate I01-I03 against `Win32_PnPSignedDriver`; predict every install / skip / upgrade decision; produce the install plan |
| Verify | V06 | HardwareImpactAnalysis | Enumerate AMD hardware on this host, compare AS-IS drivers against TO-BE patched drivers, classify upgrade risk (HIGH / MEDIUM / LOW); the NPU script also reminds the operator about the Ryzen AI Software user-mode stack |
| Inst | I00 | PreInstallReview | Print the V06 risk summary; require operator acknowledgement (NPU script: also requires explicit `I AGREE` for the Ryzen AI EULA) |
| Inst | I01 | TrustCertificate | Import CER into `LocalMachine\Root` + `LocalMachine\TrustedPublisher` |
| Inst | I02 | AuthorizeDriverSigning | Build + deploy the WDAC supplemental policy that allowlists this cert as a kernel-mode signer (default path); fall back to `bcdedit /set testsigning on` only if `-UseTestSigning` is passed. Activation is attempted via three tiers (`CiTool.exe --json` on WS2022+, the WMI/CIM `PS_UpdateAndCompareCIPolicy` bridge on WS2019, and the BCDEdit testsigning + reboot path on WS2016 or any host where both above fail) — see [SPEC §D.22](./SPEC.md). |
| Inst | I03 | InstallDrivers | `pnputil /add-driver <patched.inf> /install` for every in-scope INF |
| Inst | I04 | PostInstallVerification | Re-enumerate AMD hardware, confirm `[C] Self-signed` driver bound to each target device; the NPU script also displays Ryzen AI Software user-mode stack installation guidance. For the BthPan script, this phase uses language-independent identifiers (`DriverFileName`, `ComponentID`, `PnPDeviceID`) and is therefore correct on Japanese, Chinese, German, etc. SKUs — see [SPEC §D.19](./SPEC.md). |
| Inst | **I05** | **ForceRebind** (**BthPan only**) | When (and only when) `I04 OverallResult = PartialOrPhantom`, escalate through `Restart-PnpDevice` → `Disable/Enable-PnpDevice` → `pnputil /remove-device /scan-devices` → `Stop/Start-Service BthPan` to recover the driver binding without reboot. Capabilities are auto-detected on WS2016 / WS2019 / WS2022 / WS2025 and missing cmdlets are gracefully skipped — see [SPEC §D.22](./SPEC.md). On success, `I04 OverallResult` is promoted to `TrueResolution` and the pending-reboot marker is cleared. |

---

## Parameters (per script)

All four scripts share a common parameter contract for `-Action`, `-OnlyPhases`, `-CleanWorkRoot`, `-AllowWorkstationInstall`, `-UseTestSigning`, `-WorkRoot`, and `-PfxPassword`. The chipset and graphics scripts share additional source-discovery and help switches; the NPU script adds a 4-tier installer source resolution and platform override block; the BthPan script adds a single `-DecorationStrategy A|B` switch and otherwise reuses the common contract.

### Common parameters (chipset, graphics, NPU, BthPan)

| Parameter                  | Default              | Description                                                                                       |
| -------------------------- | -------------------- | ------------------------------------------------------------------------------------------------- |
| `-Action`                  | `PrepareVerify`      | `Prepare` / `Verify` / `PrepareVerify` / `Install` / `All` / `Cleanup` / `ListPhases`             |
| `-OnlyPhases`              | `@()`                | Phase IDs (e.g. `P05`, `P06`, `P08`, `P09`) or short names (e.g. `PatchInfs`); overrides `-Action` |
| `-CleanWorkRoot`           | (off)                | Delete the workspace directory before starting (forces a fresh download/extract/copy)             |
| `-AllowWorkstationInstall` | (off)                | Permit Install-phase actions on Workstation OS (Win11). Discouraged — default blocks Install      |
| `-UseTestSigning`          | (off)                | Fall back to `bcdedit /set testsigning on` instead of WDAC supplemental policy. Discouraged       |
| `-WorkRoot`                | per-script           | Override workspace path (chipset: `C:\Temp\Workspace_AMD-Chipset`, graphics: `C:\Temp\Workspace_AMD-Graphics`, NPU: `C:\Temp\Workspace_AMD-NPU`, BthPan: `C:\Temp\Workspace_Microsoft-BthPan`). Located under `C:\Temp\Workspace_*`; the script auto-creates `C:\Temp` on demand |
| `-LogFile`                 | `''` (disabled)      | Optional path to capture the full console transcript via `Start-Transcript` / `Stop-Transcript`. The file receives every stream (Output / Host / Error / Warning / Verbose / Debug) as plain text; the interactive console keeps its `Write-Host -ForegroundColor` decoration intact. Recommended over the legacy `... \|*>&1 \| Tee-Object -FilePath ...` idiom, which strips Write-Host coloring. Suggested filename: `C:\Temp\<tag>_<Action>_<yyyyMMdd-HHmmss>.log` |
| `-PfxPassword`             | per-script           | Password for the self-signed PFX (chipset/graphics/BthPan: `'ChangeMe!2026'`, NPU: `''`)          |
| `-WdacPolicyGuid`          | per-script (fixed UUID v4) | Override the fixed WDAC supplemental policy GUID. Default is per-script (chipset: `503860EA-…`, graphics: `85336828-…`, NPU: `8B2C4F12-…`, BthPan: `A6E72D4F-3B98-4C5A-9E1D-7F8B2A4C6E5D`). Used for legacy-deploy cleanup or side-by-side multi-instance deploy |
| `-StrictBootValidation`    | (off)                | **r69+ (Chipset/Graphics/BthPan only).** After `I02 (AuthorizeDriverSigning)` succeeds, run the WDAC SPF orchestrator's `BootLoadableCheck` action and abort before `I03 (InstallDrivers)` if the deployed `SiPolicy.p7b` fails structural validation (missing manifest, signtool reports invalid signature, etc.). Without this switch, structural warnings are printed but I03 proceeds. On non-legacy hosts (WS2022 / WS2025) the check is a no-op. See SPEC §D.29 |
| `-ForceUnsafe`             | (off)                | **r69+ (Chipset/Graphics/BthPan only).** Bypass the CRITICAL acknowledgement checklist that I00 PreInstallReview prompts the operator with when conditions C1/C2/C3/C5 fire (display driver replacement on single-display host; BitLocker ON + AMD PSP driver replacement; another self-signed cert already authorized in the WDAC SPF manifest; host hasn't been rebooted in 24+ hours). Intended for CI/CD automation only; the bypass is logged via `Set-DebugStep` in the run transcript. **Do NOT use in production.** See SPEC §D.28 |

### Chipset / Graphics-specific parameters

| Parameter           | Default                          | Description                                                                                       |
| ------------------- | -------------------------------- | ------------------------------------------------------------------------------------------------- |
| `-Help` / `-h` / `-?` | (off)                          | Show formatted usage information and exit                                                         |
| `-References`       | (off)                            | Display curated list of Microsoft Learn documentation links and exit                              |
| `-InstallerUrl`     | `''`                             | Explicit URL to the AMD installer EXE — bypasses the URL discovery probe                          |
| `-AmdLandingUrls`   | per-script default array         | Landing pages to scrape for installer EXE URL (override only if AMD changes their site structure) |
| `-AmdFallbackUrl`   | per-script default URL           | Last-resort hard-coded installer URL when landing page scraping fails                             |
| `-Force`            | (off)                            | Force overwrite of existing workspace files (use with care)                                       |
| `-TimestampUrl`     | `http://timestamp.digicert.com`  | RFC 3161 timestamp server for `signtool sign /tr`                                                 |
| `-WdacBasePolicyGuid` | `A244370E-44C9-4C06-B551-F6016E563076` (Windows-shipped base CI policy) | Override the SupplementsBasePolicyID that the WDAC supplemental policy targets. Change only if your environment uses a custom base policy |

> **Note**: The chipset and graphics scripts do not currently expose `-CertValidityYears`; the default 5-year validity is hard-coded. Only the NPU script exposes this as a configurable parameter.

### NPU-specific parameters

| Parameter                | Default               | Description                                                                                                      |
| ------------------------ | --------------------- | ---------------------------------------------------------------------------------------------------------------- |
| `-InstallerUrl`          | (none)                | Tier 1: explicit URL to the NPU driver ZIP                                                                       |
| `-OfflineZip`            | (none)                | Tier 4 priority: path to a pre-downloaded NPU driver ZIP (**recommended pattern**)                                |
| `-AmdAccountUser`        | (none)                | Tier 2: AMD account email for auto-download (BEST-EFFORT — disabled by default)                                  |
| `-AmdAccountPassword`    | (none)                | Tier 2: AMD account password (SecureString)                                                                      |
| `-ForceAmdAccountAuth`   | (off)                 | Opt in to Tier 2 form-based auth (expected to fail against current AMD JS-driven SPA portal)                     |
| `-NpuOverride`           | (none)                | Force a specific NPU codename: `PHX` / `HPT` / `STX` / `KRK`                                                     |
| `-NpuDriverPackage`      | `latest`              | NPU kernel-mode driver package: `NPU_RAI1.5_280` / `NPU_RAI1.6.1_314` / `latest` (resolves to `NPU_RAI1.6.1_314`) |
| `-RyzenAiSoftwareVersion`| `latest`              | Ryzen AI Software (user-mode stack) version recommendation: `1.5` / `1.6.1` / `1.7` / `1.7.1` / `latest`         |
| `-AssumeIfMissing`       | (off)                 | If NPU not detected, proceed using default profile (Strix Point + NPU driver 32.0.203.314 + RAI Software latest) |
| `-CertValidityYears`     | `5`                   | Self-signed cert validity period in years (NPU script only)                                                      |

> **Note** on NPU driver vs Ryzen AI Software versioning: per AMD documentation at <https://ryzenai.docs.amd.com/en/latest/inst.html>, NPU kernel driver and Ryzen AI Software are versioned **independently**. `-NpuDriverPackage` and `-RyzenAiSoftwareVersion` are therefore independent switches; you can combine any driver with any software (e.g. `-NpuDriverPackage NPU_RAI1.6.1_314 -RyzenAiSoftwareVersion 1.7.1`).

### BthPan-specific parameters

| Parameter             | Default | Description                                                                                                |
| --------------------- | ------- | ---------------------------------------------------------------------------------------------------------- |
| `-Help` / `-h` / `-?` | (off)   | Show formatted usage information and exit                                                                  |
| `-References`         | (off)   | Display curated list of Microsoft Learn documentation links and exit                                       |
| `-Force`              | (off)   | Force overwrite of existing workspace files (bypass cached Phase markers)                                  |
| `-TimestampUrl`       | `http://timestamp.digicert.com` | RFC 3161 timestamp server for `signtool sign /tr`                                            |
| `-DecorationStrategy` | `A`     | `A` (default): add only `NTamd64...3` (ProductType=3 covers all Server SKUs). Simple, durable against future Server SKUs. |
|                       |         | `B`: also add `NTamd64.10.0...14393 / 17763 / 20348 / 26100` per-build entries. Useful when explicit PnP-ranking tie-break is required, but needs manual update for any new Server SKU build. |
| `-WdacBasePolicyGuid` | `A244370E-44C9-4C06-B551-F6016E563076` (Windows-shipped base CI policy) | Override the SupplementsBasePolicyID that the WDAC supplemental policy targets |

> **Note**: the BthPan script intentionally does NOT expose `-InstallerUrl` / `-AmdLandingUrls` / `-AmdFallbackUrl` / `-OfflineZip` parameters, because there is no remote installer to fetch — the driver is the host's own `bthpan.inf` from `C:\Windows\System32\DriverStore\FileRepository\bthpan.inf_amd64_*`.

---

## Output files

Each script writes the following artifacts under its workspace (`C:\Temp\Workspace_AMD-{Chipset,Graphics,NPU}\` or `C:\Temp\Workspace_Microsoft-BthPan\`):

| Path (relative to workspace)                | Content                                                                                                          |
| ------------------------------------------- | ---------------------------------------------------------------------------------------------------------------- |
| `download\<installer>`                      | AMD installer EXE (chipset/graphics) or NPU driver ZIP (NPU); empty for BthPan (no remote source)                |
| `extracted\`                                | Unpacked installer contents (original INFs, SYS, DLL, CAT files); for BthPan: `extracted\bthpan\` with the DriverStore copy |
| `patched\<inf>`                             | Patched INF files with `ProductType=3` decoration mirrors (BthPan: `patched\bthpan\bthpan.inf`)                  |
| `patched\<cat>`                             | Regenerated catalog files (`inf2cat /os:Server2025_X64,...` output)                                              |
| `cert\AMD-Chipset-Driver-CodeSign.pfx` (chipset) / `cert\AMD-Graphics-Driver-CodeSign.pfx` (graphics) / `cert\AMD-NPU-Driver-CodeSign.pfx` (NPU) / `cert\MS-BthPan-Driver-CodeSign.pfx` (BthPan) | Self-signed code-signing certificate (PFX format) |
| `cert\AMD-Chipset-Driver-CodeSign.cer` (chipset) / `cert\AMD-Graphics-Driver-CodeSign.cer` (graphics) / `cert\AMD-NPU-Driver-CodeSign.cer` (NPU) / `cert\MS-BthPan-Driver-CodeSign.cer` (BthPan) | Public certificate (CER format) for trust-store import |
| `cert\AmdSuppPolicyId.txt` (chipset/graphics) / `cert\MsBthPanSuppPolicyId.txt` (BthPan) | Marker file recording the WDAC supplemental PolicyId for later cleanup                   |
| `cert\WDAC-Supplemental-NPU.xml` / `.cip` (NPU) | WDAC supplemental Code Integrity policy (XML source + binary deployed to `C:\Windows\System32\CodeIntegrity\CiPolicies\Active\`) |
| `cert\MsBthPanSelfSignedSupplementalPolicy.xml` / `.cip` (BthPan) | WDAC supplemental Code Integrity policy for BthPan (XML source + binary deployed to `C:\Windows\System32\CodeIntegrity\CiPolicies\Active\`). Uses the BthPan-specific GUID `A6E72D4F-3B98-4C5A-9E1D-7F8B2A4C6E5D`. |
| `inf_inventory.csv`                         | Per-INF inventory from P05 (file name, provider, class, HWID count, decoration status, etc.). BthPan: single-row CSV |
| `inf_inventory_report.txt`                  | Human-readable summary of P05 INF analysis (includes UEFI Secure Boot baseline appendix)                          |
| `logs\inf2cat_bthpan.log` (BthPan) | inf2cat verbose log; useful for diagnosing catalog generation failures                                                |
| `logs\pnputil_bthpan.log` (BthPan) | pnputil add-driver/install output                                                                                     |
| `logs\pnputil_scan-devices.log` (BthPan) | pnputil /scan-devices output (I03 forces PnP rebind)                                                            |

### CSV column conventions

`inf_inventory.csv` follows these conventions across all four scripts:

| Column                | Type   | Meaning                                                                            |
| --------------------- | ------ | ---------------------------------------------------------------------------------- |
| `FileName`            | string | INF filename (e.g. `kipudrv.inf`, `bthpan.inf`)                                    |
| `FullPath`            | string | Absolute path inside the workspace                                                 |
| `Provider`            | string | INF `[Version]` Provider field (e.g. `AdvancedMicroDevicesInc.`, `Microsoft`)      |
| `DriverVer`           | string | INF `DriverVer` line (e.g. `07/08/2025,32.0.203.314`)                              |
| `Class`               | string | Device class (e.g. `Computer`, `Display`, `System`, `Net`)                         |
| `HwidCount`           | int    | Total Hardware IDs referenced in the INF                                           |
| `MatchesTargetNpu`    | bool   | (NPU only) INF references the target NPU PCI HWID pattern                          |
| `MatchedHwidCount`    | int    | Number of HWIDs in this INF that match the target device                           |
| `HasServerDecoration` | bool   | INF already has `ProductType=3` decoration (no patching needed)                    |
| `NeedsPatch`          | bool   | INF has Workstation-only decorations and requires `ProductType=3` mirroring        |
| `SelectedForPipeline` | bool   | INF passes the script's filter and enters the patch/sign pipeline                  |

---

## UEFI Secure Boot baseline

All four scripts (chipset / graphics / NPU / BthPan) capture the host's UEFI Secure Boot certificate rollout state once at P00 and reuse the snapshot throughout the pipeline. This is informational only — the OS-layer self-signing trust chain that these scripts operate on is **independent** of the firmware-layer UEFI Secure Boot certificate database. Operators who run multiple sister scripts on the same host see consistent baseline reporting and can correlate UEFI cert-rollout state with driver-install outcomes.

### What gets captured

The snapshot combines two sources:

1. **Embedded inventory** — direct reads via `Confirm-SecureBootUEFI`, `Get-SecureBootUEFI db/kek` for the five canonical certificates (`Windows UEFI CA 2023`, `Microsoft KEK 2K CA 2023`, `Microsoft UEFI CA 2011`, `Microsoft UEFI CA 2023`, `Microsoft Option ROM UEFI CA 2023`), `HKLM:\SYSTEM\CurrentControlSet\Control\SecureBoot{,\Servicing,\Servicing\DeviceAttributes}` registry keys, and the `\Microsoft\Windows\PI\Secure-Boot-Update` scheduled task state (via `Get-ScheduledTask` for locale-independent results on ja-JP hosts).

2. **Microsoft sample script** — when present at `%SystemRoot%\SecureBoot\ExampleRolloutScripts\Detect-SecureBootCertUpdateStatus.ps1` (delivered by KB5089549 on Windows 11, KB5087544 / KB5088863 on Windows 10, and the WS2025 equivalent starting 2026-05-12), the script is launched as a child PowerShell to fetch Microsoft's confidence bucket assessment. A stdout-JSON fallback handles the MS script's input-validator bug that rejects any `-OutputPath` containing `:` (every absolute Windows path).

### Where it's displayed

| Phase | Form | Purpose |
|---|---|---|
| P00 | one-line compact: `Secure Boot baseline: enabled=true UEFI-CA-2023=NotStarted health=Warning [MS-sample=ok]` | Immediate operator awareness |
| P05 | full text appendix at the bottom of `inf_inventory_report.txt` | Change-management documentation |
| V05 | one-line compact `[Dry-Run UEFI Baseline]` block | Pre-commit sanity readout |
| V06 | full multi-section breakdown (Section 4 for chipset/graphics, Section 5 for NPU) | Detailed forensics view |
| I02 | pre-check + cross-reference with planned WDAC / testsigning path | Operator confirmation before touching OS-layer signing |

The same in-memory snapshot is reused across all five sites; the MS sample script is invoked at most once per run.

### Health classification

- **Healthy** — Secure Boot ON, UEFI CA 2023 rollout `Updated` (or not applicable), no rollout errors.
- **Warning** — Secure Boot ON but rollout is in flight (`NotStarted` / `Started` / `Pending`), scheduled task is disabled, or MS sample reports rollout-event diagnostics.
- **Critical** — Secure Boot OFF (planned WDAC path expects ON), or a non-zero `UEFICA2023Error` indicates a stuck rollout.

I02 surfaces the classification but **never blocks** on it (the two trust layers are independent). On `Critical` or `Warning` the operator sees a yellow advisory and decides whether to proceed.

### Diagnostic files

When the MS sample script is invoked, the following files are written under `<WorkRoot>\secureboot_ms_sample\`:

```
detect_stdout.log                  - Raw captured stdout (Write-Host + JSON)
detect_stdout_extracted.json       - Parsed JSON object (BucketId, Confidence, Event1801..1803 counts)
```

These are retained as part of the workspace artefact set and survive subsequent runs unless `-CleanWorkRoot` is passed.

---

## Console output format

Every line written by the scripts follows a structured, time-stamped format that is **identical across all four scripts** (chipset, graphics, NPU, BthPan). This is intentional — operators reading logs from mixed runs see the same vocabulary and visual layout.

### Marker semantics

| Marker | Colour    | Semantic | Example                                                          |
| ------ | --------- | -------- | ---------------------------------------------------------------- |
| `[*]`  | Cyan      | Step     | `[*] Acquiring signtool, inf2cat, and 7-Zip`                     |
| `[+]`  | Green     | Ok       | `[+] Cert thumbprint: A1B2C3D4...`                               |
| `[!]`  | Yellow    | Warn     | `[!] Tier 2 (AMD account auto-download) is disabled by default`  |
| `[X]`  | Red       | Fail     | `[X] Top-level error: AMD NPU not detected`                      |
| `[~]`  | DarkGray  | Skip     | `[~] Inventory CSV: C:\Temp\Workspace_AMD-NPU\inf_inventory.csv` |

Continuation lines that sit inside a section-banner table (PowerShell environment dump, OS profile, Secure Boot baseline, INF inventory rows, V05 / V06 / I00 sub-blocks) are rendered via the `Write-Detail` helper, which emits a 4-space-indented line with no timestamp or marker prefix. This is the single sanctioned exception to the "every line has a marker" rule. Operators reading raw logs should treat any 4-space-indented line as visually subordinate to the most recent marker line above it. (See SPEC §A.5.)

### Sample output (NPU script, P00 → P03)

```
========================================================================
 Deploy-AMDNpuDriverOnWindowsServer
 Version: npu-<yyyy.MM.dd>-r<NN>  [<short-kebab-tag>]  SHA256: <12-hex-chars>
 Action : PrepareVerify
 Repo   : https://github.com/usui-tk/Deploy-Drivers-For-WindowsServer
========================================================================

========================================================================
 PHASE P00 - Initialize                 (Prep  )  start: 14:23:05
 script: npu-<yyyy.MM.dd>-r<NN>/<hash12>
========================================================================
[14:23:05]            [*] Running environment and sanity checks
[14:23:05]            [+] Administrator privileges confirmed.
[14:23:05]            [~] TLS protocols enabled: Tls, Tls11, Tls12, Tls13
[14:23:06] [+0.42s]   [+] OS detected     : Microsoft Windows Server 2025 (build 26100)
[14:23:06] [+0.42s]   [~] Profile applied : WS2025
[14:23:06] [+0.42s]   [~] inf2cat /os: switch : Server2025_X64
 PHASE P00 -> DONE     elapsed: 0.45s

========================================================================
 PHASE P03 - FetchInstaller             (Prep  )  start: 14:23:12
========================================================================
[14:23:12]            [*] Detecting NPU platform and resolving installer source (4-tier fallback)
[14:23:12] [+0.18s]   [+] NPU codename         : Strix Point / Strix Halo
[14:23:12] [+0.18s]   [+] NPU short name       : STX
[14:23:12] [+0.18s]   [+] Hardware ID          : PCI\VEN_1022&DEV_17F0&REV_00
[14:23:12] [+0.18s]   [+] NPU driver package   : NPU_RAI1.6.1_314
[14:23:12] [+0.18s]   [+] NPU driver build     : 32.0.203.314
 PHASE P03 -> DONE     elapsed: 1.23s
```

The phase header banner (`=` × 72, Magenta) is emitted by the dispatcher; phase functions never print their own banner. The `[+X.XXs]` elapsed-tag is reset at each phase entry so it tracks **time inside the current phase**, not total runtime.

---

## Run log capture (`-LogFile`)

All four scripts expose a `-LogFile <path>` parameter that captures the full console transcript via `Start-Transcript` / `Stop-Transcript`:

```powershell
# Recommended: color is preserved in the console, the file gets every stream as plain text
$ts  = Get-Date -Format 'yyyyMMdd-HHmmss'
$log = "C:\Temp\amd-chipset_PrepareVerify_$ts.log"
.\Deploy-AMDChipsetDriverOnWindowsServer.ps1 -Action PrepareVerify -CleanWorkRoot -LogFile $log
```

Key properties:

- **Console keeps its `Write-Host -ForegroundColor` decoration intact** — unlike the legacy `*>&1 | Tee-Object -FilePath …` idiom, which strips Write-Host coloring on the way through the pipeline.
- **File receives every stream** (Output / Host / Error / Warning / Verbose / Debug) as plain UTF-8 text.
- **Parent directory auto-created** on demand (e.g. `C:\Temp\` is created if missing).
- **Append mode** (`-Append -Force`) — concurrent re-runs accumulate rather than truncate.
- **Idempotent cleanup** — `Stop-Transcript` is invoked from the top-level `finally` block and from a `PowerShell.Exiting` engine event handler as a fallback.

Recommended filename convention:

```
C:\Temp\<scripttag>_<Action>_<yyyyMMdd-HHmmss>.log
```

Examples:

| Script   | Suggested filename                                              |
| -------- | --------------------------------------------------------------- |
| Chipset  | `C:\Temp\amd-chipset_PrepareVerify_20260517-143022.log`         |
| Graphics | `C:\Temp\amd-graphics_Install_20260517-143022.log`              |
| NPU      | `C:\Temp\amd-npu_All_20260517-143022.log`                       |
| BthPan   | `C:\Temp\ms-bthpan_PrepareVerify_20260517-143022.log`           |

### Legacy fallback (`Tee-Object`)

The legacy `*>&1 | Tee-Object` idiom is still supported and may be preferable when the log file needs to be piped further into another tool. Note that **Write-Host coloring is stripped** in this mode (PowerShell's pipeline does not propagate the host stream's color information):

```powershell
.\Deploy-AMDChipsetDriverOnWindowsServer.ps1 -Action Install *>&1 |
    Tee-Object -FilePath "C:\Temp\amd-chipset_Install_$(Get-Date -Format 'yyyyMMdd-HHmmss').log"
```

If you redirect output to a file (whether via `-LogFile` or `Tee-Object`) on a ja-JP host with the default code page (932 / Shift-JIS), set your file encoding explicitly to UTF-8 to avoid double-encoding of Japanese strings — the scripts call `Set-ConsoleUtf8` in P00 to enforce UTF-8 for `[Console]::OutputEncoding`, but consumers of the captured file (text editors, `Get-Content`, etc.) may still need to be told the file is UTF-8.

---

## System requirements

- **CPU**: For AMD scripts: AMD Ryzen 4000 series or newer (the script's `Get-AmdChipsetPlatform` heuristic recognises 4000 → AI 300, AI Max 300; older silicon may run but is untested). For the NPU script: Ryzen 7040 / 8040 / AI 300 / AI Max 300 / AI 200 series with an integrated NPU. For the BthPan script: any CPU; the prerequisite is a bound Bluetooth host controller (vendor-agnostic — Intel AX2xx, Realtek RTL88xx, MediaTek MT79xx, Broadcom BCM43xx all qualify).
- **OS**: Windows Server 2025 (build 26100) is the production target. Windows 11 24H2 (build 26100) is supported as a *preview* host (see [TESTING.md](./TESTING.md)). Windows Server 2016 / 2019 / 2022 are recognised by the OS profile matrix and inf2cat will pick a corresponding `/os:` switch (e.g. `Server2016_X64`, `ServerRS5_X64`, `ServerFE_X64`). The BthPan script's P08 explicitly targets all four (`Server2025_X64,ServerFE_X64,ServerRS5_X64,Server2016_X64`) in a single inf2cat invocation, so one signed catalog covers all Server SKUs.
- **PowerShell**: 5.1 (Windows PowerShell Desktop) or 7.x (PowerShell Core). The script's `Show-PowerShellEnvironment` phase prints the compatibility matrix it sees.
- **Disk**: ~5 GB on the workspace volume (~7 GB if you also run the NPU script). BthPan workspace is small (<10 MB — single INF/SYS/CAT).
- **Network**: outbound HTTPS to `*.amd.com`, `download.microsoft.com`, `go.microsoft.com`, `aka.ms` (winget), `timestamp.digicert.com` (signing timestamp), and (for the NPU script with Tier 2 download) `account.amd.com` and `*.entitlenow.com`. **The BthPan script needs network access only for timestamp signing** (`timestamp.digicert.com`); no AMD or Microsoft download endpoints are contacted.
- **Privileges**: Administrator on the local machine. No domain rights are required.
- **BthPan-specific**: a Bluetooth host controller bound and showing `Status=OK` in Device Manager (the script's V05 / V06 explicitly checks this before running Install). Without a host controller, the patched bthpan driver is still staged in the driver store but cannot bind to any device.

---

## Self-signed certificate: expiry, renewal, and revocation

The certificate generated in P07 is the **trust anchor** for every patched driver this pipeline installs. It deserves its own section.

### Certificate properties

- **Subject**:
  - `CN=AMD Chipset Driver Self-Sign (WS2025 Lab, At Own Risk)` (chipset)
  - `CN=AMD Graphics Driver Self-Sign (WS2025 Lab, At Own Risk)` (graphics)
  - `CN=AMD NPU Driver Self-Sign (WS2025 Lab, At Own Risk)` (NPU)
  - `CN=Microsoft BthPan Driver Self-Sign (<OsCode> Lab, At Own Risk)` (BthPan; `<OsCode>` is the host OS short name, e.g. `WS2025`)
- **Key**: RSA 4096-bit on WS2019+ / Win11+, RSA 2048-bit on WS2016. SHA-384 signature algorithm on WS2025, SHA-256 on WS2016/2019/2022.
- **EKU**: Code Signing (`1.3.6.1.5.5.7.3.3`).
- **Validity**: **5 years from the day P07 ran** (WS2019+); 3 years on WS2016. Hard-coded in the script.
- **Storage**: PFX in `C:\Temp\Workspace_AMD-{Chipset,Graphics,NPU}\cert\` or `C:\Temp\Workspace_Microsoft-BthPan\cert\`. The PFX is **not** password-protected by default (this is a lab tool; if you need a real password, change `[string]$PfxPassword = ''` in the param block).
- **Trust anchor for**: every `.cat` file under `patched\`, the WDAC supplemental policy, and (via I01) `LocalMachine\Root` + `LocalMachine\TrustedPublisher`.

### What happens at year 5

After the certificate expires:

- The catalog signatures embedded in `.cat` files **remain valid for files installed before expiry**, because Windows checks the signing timestamp (which proves the signature was made while the cert was valid) — *not* the cert's current validity at boot. This is identical to how every WHQL-signed driver works long after the AMD / Microsoft signing cert has rotated.
- However, **adding new patched drivers** with the expired cert via `pnputil /add-driver` will fail.
- **Re-running this script** after expiry is the recovery path. It generates a *new* cert (different thumbprint, same subject), re-signs the catalogs, and re-imports the new cert. Existing installed drivers are untouched and continue to work.

### Renewal procedure (every 5 years, or sooner if compromised)

```powershell
# 1. Roll the cert and re-sign everything
.\Deploy-AMDChipsetDriverOnWindowsServer.ps1  -Action Prepare -OnlyPhases P07,P08,P09
.\Deploy-AMDGraphicsDriverOnWindowsServer.ps1 -Action Prepare -OnlyPhases P07,P08,P09
.\Deploy-AMDNpuDriverOnWindowsServer.ps1      -Action Prepare -OnlyPhases P07,P08,P09

# 2. Trust the new cert (the old one stays trusted until you remove it)
.\Deploy-AMDChipsetDriverOnWindowsServer.ps1  -Action Install -OnlyPhases I01,I02
.\Deploy-AMDGraphicsDriverOnWindowsServer.ps1 -Action Install -OnlyPhases I01,I02
.\Deploy-AMDNpuDriverOnWindowsServer.ps1      -Action Install -OnlyPhases I01,I02

# 3. Add the freshly-signed drivers to the store (binds existing devices to the new sig)
.\Deploy-AMDChipsetDriverOnWindowsServer.ps1  -Action Install -OnlyPhases I03
.\Deploy-AMDGraphicsDriverOnWindowsServer.ps1 -Action Install -OnlyPhases I03
.\Deploy-AMDNpuDriverOnWindowsServer.ps1      -Action Install -OnlyPhases I03

# 4. Optionally remove the old cert
$old = 'OLD-THUMBPRINT-FROM-PREVIOUS-RUN'
Get-ChildItem 'Cert:\LocalMachine\Root', 'Cert:\LocalMachine\TrustedPublisher' |
  Where-Object Thumbprint -EQ $old | Remove-Item
```

### Revoking the cert

If you suspect the PFX has leaked, immediately:

```powershell
# 1. Cleanup — removes cert from trust stores, deletes WDAC policy, removes drivers
.\Deploy-AMDChipsetDriverOnWindowsServer.ps1  -Action Cleanup
.\Deploy-AMDGraphicsDriverOnWindowsServer.ps1 -Action Cleanup
.\Deploy-AMDNpuDriverOnWindowsServer.ps1      -Action Cleanup

# 2. Reboot to ensure WDAC policy unload (the script attempts a CiTool --refresh, but a
#    reboot guarantees no residual signing-authority is in the kernel)
Restart-Computer
```

After reboot, re-run the full pipeline to generate a new cert.

### Why 5 years? Why self-signed?

- **5 years** matches the upper bound for Microsoft's own kernel-mode signing certs (rotated every 1-3 years, but issued for up to 5). Long enough that you don't think about it monthly; short enough that a leaked cert has bounded blast radius.
- **Self-signed** because no public CA issues code-signing certs for arbitrary hobbyists patching consumer drivers. EV Code Signing certs from Sectigo / DigiCert require business verification (~$300-600/year) and won't issue if the patching activity violates AMD's EULA.

This is *intentionally* a lab tool. **If you are deploying this in production at scale, you should either: (a) negotiate Server-class drivers from AMD directly, or (b) use a properly managed code-signing CA, not this self-signed model.**

---

## Disclaimer & at-your-own-risk acknowledgements

By running these scripts, you acknowledge:

1. **No warranty.** The scripts are provided "as is" under MIT License. There is no guarantee that they will work on your hardware, will not damage your installation, or will be supported in future Windows updates. See `LICENSE`.

2. **You are the publisher of record.** Patching AMD's INFs and re-signing them with your own certificate makes *you* — not AMD, not Microsoft — the cryptographic publisher of those drivers from Windows' point of view. If a patched driver causes a BSOD, system instability, or data loss, the bug is attributed to your self-signed cert, not to AMD.

3. **AMD's End User License Agreement** for the chipset / graphics / Ryzen AI installers permits redistribution under specific terms. Re-signing modified INFs is a grey area; you should read AMD's EULA for your specific package and form your own judgement. **This repository takes no position on whether your use is permitted under AMD's terms.** For Ryzen AI specifically, the EULA must be accepted at <https://account.amd.com/en/forms/downloads/ryzenai-eula-public-xef.html> before downloading; the NPU script's I00 phase requires explicit `I AGREE` confirmation that this acceptance has occurred.

4. **Microsoft's Windows Hardware Lab Kit (HLK) certification is invalidated** for any driver this pipeline replaces. WHQL-signed drivers carry Microsoft's attestation that they passed HLK; self-signed drivers do not. If you rely on Microsoft Premier Support for the affected hardware, your support contract may not cover issues caused by self-signed drivers.

5. **BitLocker, TPM, and Secure Boot interactions.** The chipset script's PSP driver replacement (`amdpsp.inf`) interacts with Platform Security Processor firmware. On systems with BitLocker enabled, a failed PSP driver upgrade can trigger BitLocker recovery prompts on next boot. **Always have your BitLocker recovery key recorded before running `-Action Install` on the chipset script.**

6. **Anti-cheat software (Easy Anti-Cheat, BattlEye, Vanguard, etc.)** may flag self-signed kernel-mode drivers. This pipeline is not intended for gaming workloads on competitive titles and may result in account bans if used as such.

7. **The 5-year cert expiry is real.** Schedule a renewal task in your calendar for year 4.5 of any production deployment, or accept that drivers stop installing in year 5.

8. **Driver-category priority override (BREAKING change).** The script's install-decision logic ranks self-signed drivers ([C]) above hardware-vendor drivers ([B]) and Microsoft generic drivers ([A]), regardless of driver version. On a clean WS2025 install this is exactly the intent — Microsoft's in-box generics will be replaced by AMD-vendor drivers carrying the script's signature. The trade-off is that any AMD-vendor driver already installed via Windows Update or an OEM package will *also* be overwritten by the script's self-signed equivalent (the binaries are the same; only the publisher differs). If you want to preserve a vendor driver, run `-Action PrepareVerify` first, inspect V06 Section 2, and decide whether to proceed. See SPEC §D.15 for the full rationale.

9. **NPU script (`Deploy-AMDNpuDriverOnWindowsServer.ps1`) is markedly higher-risk than its sister scripts.** Specifically:
   - **No physical-NPU validation** has been performed by the maintainers as of this writing. All testing has been static analysis with `psa.py` and code-review of the AMD-published `quicktest.py` detection logic translated to PowerShell.
   - **AMD account auto-download (Tier 2) is best-effort and may break without notice** when AMD updates `account.amd.com` form layouts, CSRF handling, or the entitlenow.com CDN URL scheme. Always prefer Tier 4 (`-OfflineZip`) for reproducible runs.
   - **Ryzen AI Software is officially Windows-11-only per AMD documentation** (build >= 22621.3527). Even if the NPU kernel driver loads on Windows Server 2025, the user-mode stack (Python conda env, ONNX Runtime VitisAI EP, OGA) is not expected to function. **Do not deploy the NPU script in environments expecting AI inference workloads on Server 2025.**
   - **Driver-store cleanup is best-effort.** Removing self-signed NPU drivers from the driver store after `-Action Install` may require manual `pnputil /delete-driver oemNN.inf /force` or use of Driver Store Explorer (Rapr.exe).

10. **No commercial support is offered through this repository.** GitHub Issues at <https://github.com/usui-tk/Deploy-Drivers-For-WindowsServer/issues> are best-effort for bug reports and clarification questions. Pull requests are welcome but not guaranteed to be reviewed on any timeline.

---

## Troubleshooting

### "OS detected: Windows Server 2025 (build 26100) [WS2025] but ProductType: 1"

You are running on Windows 11 24H2 (which shares NT build 26100 with Windows Server 2025). The script intentionally maps Win11 24H2 to the WS2025 profile because they share kernel ABI. `Install` phases are blocked on Workstation OS by default; use `-Action PrepareVerify` only, or pass `-AllowWorkstationInstall` if you really want to install on Win11 (read the warnings first). See [TESTING.md](./TESTING.md) for the pre-migration verification workflow.

### "P02 takes 2-3 minutes to install the WDK"

The Windows WDK download is ~2.5 GB. This is a one-time install per machine. Subsequent runs reuse the installed `inf2cat.exe` and complete P02 in under a second.

### "P03 fails with 'no AMD installer URL resolved'"

AMD periodically reorganises their support pages. The script probes 3-6 candidate URLs; if all return 0 hits, the parser broke. Workarounds:

- Pass `-InstallerUrl https://drivers.amd.com/drivers/...` to skip URL discovery and download a specific version.
- Open the `Probe results:` block in P03 output and visit each URL manually to confirm AMD's site changed.
- File an issue: <https://github.com/usui-tk/Deploy-Drivers-For-WindowsServer/issues>

### NPU script "All 4 download tiers exhausted"

This is the most common NPU-script failure. The EULA-gated AMD form requires an authenticated AMD account session that the script cannot fully simulate. Workarounds in priority order:

1. **Manually download** the ZIP from <https://ryzenai.docs.amd.com/en/latest/inst.html#install-npu-drivers>, place it next to the script, re-run with `-OfflineZip .\NPU_RAI*.zip`.
2. **Try `-AmdAccountUser` / `-AmdAccountPassword`** but expect breakage; AMD form structure changes are not announced.
3. **Capture the entitlenow.com URL** from a browser session after manual EULA acceptance, pass via `-InstallerUrl <captured-url>`. The URL has a time-limited hash; download immediately after capture.

### NPU script "No AMD NPU detected via pnputil"

The host has no AMD NPU device. Either:

- This is intentional (pipeline-soundness check on a host without NPU): pass `-AssumeIfMissing` to proceed with the default Strix Point + RAI 1.7.1 profile.
- This was unexpected (you believed you had a Ryzen AI machine): check Device Manager for unbound PCI devices; check Task Manager → Performance for an NPU0 entry; check that the BIOS has not disabled the NPU.

### "V06 shows MS-GENERIC drivers on AMD hardware that the patched INFs don't cover"

CPU cores (`cpu.inf`), PCI Express Root Ports (`pci.inf`), Host CPU Bridges (`machine.inf`), USB xHCI (`usbxhci.inf`), HD Audio Controller (`hdaudbus.inf`) are **all expected to remain on Microsoft generic drivers**. AMD does not ship vendor drivers for these (they're enumerated by core OS subsystems). The "ALERT" message in V06 Section 1 is informational, not an error.

### "I02 deploys WDAC policy but new driver still doesn't load"

Check `eventvwr` → `Applications and Services Logs` → `Microsoft` → `Windows` → `CodeIntegrity` → `Operational` for events 3076 / 3077 / 3091. The Issuer / Subject / Thumbprint of the blocked signature should match your self-signed cert. If they don't match, the WDAC policy isn't deployed correctly — try `CiTool -lp` to list active policies.

### "AMD driver was installed but Device Manager still shows MS generic on the device"

Run `pnputil /scan-devices` to force a re-enumeration. If still bound to MS, the patched INF's HWID may not match the device's PNP ID exactly. Check V06 Section 2 ("WILL be replaced" / "have no patched INF") — if the device falls into the latter category, no patched driver claims that HWID, which is expected for some devices (USB hubs, generic xHCI controllers, etc.).

### "I02 appears to hang for 60+ seconds between 'Converting XML to .cip binary...' and 'Deployed:' lines"

**Historical defect (now fixed in current mainline).** CiTool.exe was invoked without the `--json` flag and printed "続行するには、Enter キーを押してください" (Press Enter to Exit) to the console, blocking the script on stdin. Pressing ENTER in the active console window resumed the script. This is fixed by passing `--json` to all CiTool.exe invocations, which suppresses the interactive prompt per Microsoft's CiTool design (the `--json` flag documents itself as "出力を json として書式設定し、入力を抑制する"). Upgrade the script and the hang will no longer occur. See SPEC §D.16 for the full root-cause analysis.

### "CiTool log line shows mojibake like '蜃ｦ逅・・謌仙粥縺励∪縺励◆'"

**Historical defect (now fixed in current mainline).** This is the UTF-8 byte sequence of `処理が成功しました` interpreted as cp932 (Shift-JIS). CiTool.exe writes UTF-8 to stdout, but PowerShell decoded it using the default ja-JP `[Console]::OutputEncoding` (cp932). SPEC §A.5 / §D.5 mandated UTF-8 enforcement at P00 but the implementation was missing. Fixed via `Set-ConsoleUtf8` at P00. See SPEC §D.16.

### "I03 says '3 failed' but I04 says 'Failed: 0' on the same install run"

**Historical defect (now fixed in current mainline).** I03's classification logic treated pnputil `exit=259` (`ERROR_NO_MORE_ITEMS`) as a failure, but I04's PostInstallVerification reads the actual device state and correctly identifies these as `REBOOT_NEEDED` (when a sibling-INF first install already queued the binding) or as no-op (driver package already in store). The exit=259 cases are typically from duplicate-source INFs (e.g. `Chipset_Software\SMBus Driver\W11x64\SMBUSamd.inf` and `SMBus Driver\W11x64\SMBUSamd.inf` are both visited by I03, the second returns 259). The current I03 summary reports four categories — `ok` / `need reboot` / `no-op` / `failed` — and exit=259 maps to the `no-op (already present)` status (Write-Skip / DarkGray). See SPEC §D.17.

### NPU script "I04 shows the device is bound but Ryzen AI Software won't initialize"

This is the expected outcome on Windows Server 2025. The kernel-mode driver loads, but the Ryzen AI Software user-mode stack (Python conda env, ONNX Runtime VitisAI EP, OGA) is officially Windows-11-only. Do not expect AI workload functionality on Server 2025. Either:

- Use Windows 11 24H2 for actual NPU inference workloads.
- Treat the Server 2025 install as kernel driver bring-up only (lab / research).

### Chipset script "P08 reports '1 failed' for the CIR Driver folder" (or any other INF folder)

**This is now handled automatically in mainline (Chipset r66+).** The AMD Chipset Software package occasionally ships an INF whose `[SourceDisksFiles]` references files that AMD did not actually package in the sub-MSI's cabinet. The most reproducible cases are `AmdAppCompat.inf`, `AmdAS4.inf`, `AMDCIR.inf`, and `usbfilter.inf` in Chipset 8.05.04.516 on Renoir / WS2019: each declares one or more files in `[SourceDisksFiles]` that the cabinet does not include. `inf2cat.exe` therefore fails at P08 with error 22.9.1 ("driver package is missing some files"). The upstream cause is a `SECREPAIR Error: 3` cascade visible in the sub-MSI's `msiexec /a` log.

In r65 the script started detecting this at P05 (new `Get-InfReferencedFile` helper cross-checks every patched INF's `[SourceDisksFiles]` against the files actually extracted by P04), recording the result in `inf_inventory.csv` via the new `EligibleForCatalog` column, and propagating the skip through P06 / P08 / V03 / V04 / V05 / V06 / I03. The expected P08 summary becomes tri-state (`N ok / 0 failed / K skipped`).

r66 closes a follow-on gap: P06 had been copying the AMD-shipped original `.cat` files alongside the ineligible INFs, and P09 then re-signed those orphans with the self-signed cert. r66 adds two cooperating defense layers — P08 now deletes orphan `.cat` files in skipped directories, and P09 additionally filters any survivors by directory. Net result: V01's `Catalog files: N` count now matches P08's `N ok` exactly, no orphan catalogs end up in `patched/`, and standalone P09 runs (`-OnlyPhases P09`) on a recovered workspace remain safe.

See [SPEC §D.24](./SPEC.md) for the full root-cause analysis and the layered defense design, and [CHANGELOG.md](./CHANGELOG.md) for the r65 (detect-and-skip) and r66 (orphan cleanup) entries. The submsi-failures-diag.txt pattern frequency now correctly classifies these 1603s as `SECREPAIR missing source files` (SPEC §D.21).

If you are still seeing P08 fail on r66, the affected INF is exhibiting a different failure mode — open an issue with the INF name and the full `[P08]` console block.

---

## Development tools

### `psa.py` — PowerShell Static Analyzer

The PowerShell static analyzer used to validate the pipeline scripts is `psa.py`. It is **maintained as a single canonical artifact** in a separate repository — [`usui-tk/ai-generated-artifacts`](https://github.com/usui-tk/ai-generated-artifacts) — under [`scripts/python/powershell-static-analyzer/`](https://github.com/usui-tk/ai-generated-artifacts/tree/main/scripts/python/powershell-static-analyzer). This repository does **not** bundle a local copy; obtain `psa.py` via one of the methods below before using it.

A single-file Python 3 static analyzer that catches common PowerShell mistakes the regular parser does not flag.

#### Obtaining `psa.py`

**Method 1 — Clone the canonical repository (recommended for ongoing development)**

```bash
# Clone the canonical repository as a sibling directory to this repo
git clone https://github.com/usui-tk/ai-generated-artifacts.git ../ai-generated-artifacts

# Run from this repository's root
python3 ../ai-generated-artifacts/scripts/python/powershell-static-analyzer/psa.py Deploy-AMDChipsetDriverOnWindowsServer.ps1
python3 ../ai-generated-artifacts/scripts/python/powershell-static-analyzer/psa.py Deploy-AMDGraphicsDriverOnWindowsServer.ps1
python3 ../ai-generated-artifacts/scripts/python/powershell-static-analyzer/psa.py Deploy-AMDNpuDriverOnWindowsServer.ps1
```

**Method 2 — Download the single file (recommended for one-shot CI runs)**

Linux / macOS (curl):

```bash
curl -sSLO https://raw.githubusercontent.com/usui-tk/ai-generated-artifacts/main/scripts/python/powershell-static-analyzer/psa.py
python3 psa.py Deploy-AMDChipsetDriverOnWindowsServer.ps1
python3 psa.py Deploy-AMDGraphicsDriverOnWindowsServer.ps1
python3 psa.py Deploy-AMDNpuDriverOnWindowsServer.ps1
```

Windows PowerShell (Invoke-WebRequest):

```powershell
Invoke-WebRequest `
    -Uri  "https://raw.githubusercontent.com/usui-tk/ai-generated-artifacts/main/scripts/python/powershell-static-analyzer/psa.py" `
    -OutFile psa.py
python3 psa.py Deploy-AMDChipsetDriverOnWindowsServer.ps1
python3 psa.py Deploy-AMDGraphicsDriverOnWindowsServer.ps1
python3 psa.py Deploy-AMDNpuDriverOnWindowsServer.ps1
```

In the rest of this document and in `SPEC.md` / `TESTING.md` / `CONTRIBUTING.md`, commands of the form `python3 psa.py <script>.ps1` assume that `psa.py` has already been obtained via Method 1 or Method 2 above and is accessible on a path of your choice.

#### Checks performed

`psa.py` (latest mainline) ships with a **36-rule** check set spanning `PSA1001`..`PSA9002` for generic rules plus `PSAP0001`..`PSAP0004` for project / pipeline convention rules. This repository validates its scripts against the latest mainline `psa.py` (no fixed-version pinning); see `SPEC.md` §A.11 *Version policy* for the rationale and the LLM / AI workflow for adopting a new version. The 36 rules are grouped into nine categories:

| Category                       | Code range                | Examples                                                                                                                                                                                                                                       |
| ---                            | ---                       | ---                                                                                                                                                                                                                                            |
| Syntax balance                 | `PSA1001`..`PSA1003`      | brace / paren / bracket balance                                                                                                                                                                                                                |
| Semantics                      | `PSA2001`..`PSA2006`      | undefined variable, auto-variable shadowing, `-match` against bare variable, `$null` on the right of `-eq`/`-ne`, assignment / redirection inside conditional                                                                                  |
| Coding pattern                 | `PSA3001`..`PSA3005`      | `Start-Process -ArgumentList`, trailing backtick before empty line, `-match` against empty string, empty `catch` block, `Start-Transcript -Path` should be `-LiteralPath`                                                                       |
| Hygiene                        | `PSA4001`..`PSA4004`      | unfinished markers (TODO / FIXME / XXX / HACK), trailing whitespace, long line, trailing semicolon                                                                                                                                             |
| Security                       | `PSA5001`..`PSA5004`      | plain-text password parameter, `Invoke-Expression`, broken hash algorithm, hardcoded `ComputerName`                                                                                                                                            |
| Best practice                  | `PSA6001`..`PSA6006`      | non-approved verb, cmdlet alias, plural function noun, `$global:` definition, mandatory parameter with default, switch defaulting to `$true`                                                                                                   |
| File format                    | `PSA7001`                 | missing UTF-8 BOM on `.ps1` (Windows PowerShell 5.1 ja-JP falls back to Shift-JIS / cp932 without BOM)                                                                                                                                          |
| Cross-file consistency         | `PSA8001`                 | function body hash drift across files in the same scan — enforces that shared helper functions (`Format-Elapsed`, `Write-Detail`, `Start-DebugTrace` family, etc.) stay byte-for-byte synchronised across the four pipeline scripts            |
| Complexity metrics             | `PSA9001`..`PSA9002`      | function-body length threshold (off by default), external-process invocation without `$LASTEXITCODE` check (off by default)                                                                                                                    |
| Project / pipeline conventions | `PSAP0001`..`PSAP0004`    | phase function naming convention, required script-identifier variables, **new in 3.3.0:** inline `# rNN:` revision-tag comments (`PSAP0003`), end-of-file `REVISION HISTORY` blocks (`PSAP0004`) — **all PSAPxxxx rules are off by default**; this repository opts in to all four |

For the authoritative specification of every rule, see [`scripts/python/powershell-static-analyzer/SPEC.md`](https://github.com/usui-tk/ai-generated-artifacts/blob/main/scripts/python/powershell-static-analyzer/SPEC.md) §4 in the [ai-generated-artifacts](https://github.com/usui-tk/ai-generated-artifacts) repository.

#### Repository-specific configuration

This repository ships its own `.psa.config.json` at the repository root. It is the **canonical configuration for the four pipeline scripts** and does three things:

1. **Opts in to `PSAP0001`, `PSAP0002`, `PSAP0003`, and `PSAP0004`** so that the 21-phase naming convention (`Invoke-(Prep|Verify|Inst)PhaseNN_DescriptiveName`), the script-identity trio (`$Script:ScriptVersion` / `ScriptHash` / `ScriptShortTag`), and the revision-discipline rules (no inline `# rNN:` tags, no in-script `REVISION HISTORY` blocks — history lives in `CHANGELOG.md`) are all enforced.

2. **Configures `PSA8001` (cross-file function-body drift)** with `psa8001_ignore_functions`, listing roughly 45 function names that are intentionally per-script (phase functions, per-driver-family helpers, `Show-Help`, etc.). Shared helpers NOT listed there MUST stay byte-for-byte identical across all four scripts.

3. **Disables `PSA4003` (long line)** because the pipeline scripts intentionally use multi-clause `-f` format strings that exceed 120 columns for readability.

Run static analysis against all four pipeline scripts via:

```bash
# From the repository root, after psa.py has been obtained (Method 1 or 2 above)
python3 path/to/psa.py --config ./.psa.config.json \
    Deploy-AMDChipsetDriverOnWindowsServer.ps1 \
    Deploy-AMDGraphicsDriverOnWindowsServer.ps1 \
    Deploy-AMDNpuDriverOnWindowsServer.ps1 \
    Deploy-MSBthPanInboxOnWindowsServer.ps1
```

All four scripts MUST be passed in a single invocation for PSA8001 cross-file analysis to work; with a single file PSA8001 has no peers to compare against and emits nothing. See [`CHANGELOG.md`](./CHANGELOG.md) for the current verified baseline.

Exit codes: `0` = clean, `1` = warnings only, `2` = errors. Useful in CI:

```yaml
# .github/workflows/lint.yml example (Method 2 — single-file download)
- name: Fetch psa.py from canonical repository
  run: |
    curl -sSLO https://raw.githubusercontent.com/usui-tk/ai-generated-artifacts/main/scripts/python/powershell-static-analyzer/psa.py
- name: Static-analyze PowerShell scripts
  run: |
    python3 psa.py --config ./.psa.config.json \
        Deploy-AMDChipsetDriverOnWindowsServer.ps1 \
        Deploy-AMDGraphicsDriverOnWindowsServer.ps1 \
        Deploy-AMDNpuDriverOnWindowsServer.ps1 \
        Deploy-MSBthPanInboxOnWindowsServer.ps1
```

For the full design rationale, output format reference, and an extended CI integration example, see the canonical README at [`scripts/python/powershell-static-analyzer/README.md`](https://github.com/usui-tk/ai-generated-artifacts/blob/main/scripts/python/powershell-static-analyzer/README.md) in the [ai-generated-artifacts](https://github.com/usui-tk/ai-generated-artifacts) repository.

---

## Developer specification

For the full developer specification — including phase architecture rules, banner / log conventions, parameter naming conventions, CSV / JSONL output format, path-handling rules (`-LiteralPath`), and the quality gates enforced by `psa.py` — see:

- [**SPEC.md**](./SPEC.md) — Developer specification (the authoritative reference for contributors and AI assistants working on this codebase). **English only** per the repository-wide documentation language policy (see SPEC.md §A.12).

`SPEC.md` is structured in three parts:

- **Part A — Common Specification.** Reusable rules across the four scripts (phase architecture, banner / log markers, parameter conventions, error handling, CSV column conventions, path-handling rules). Pick this up first if you are extending any of the four scripts or adding a fifth.
- **Part B — Script-specific Specifications.** One section per script (Chipset / Graphics / NPU) documenting the unique platform-detection logic, INF inventory filters, installer source resolution tiers, and known platform quirks.
- **Part C — Quality Gates & Lessons Learned.** What `psa.py` checks for, what regression tests `TESTING.md` covers, and the historical fixes (e.g. timezone-induced DriverDate false positives in an earlier chipset revision) that are baked into the current implementation.

If you are adding a new feature, the recommended workflow is: read `SPEC.md` → read the relevant script's existing `Invoke-*Phase*_*` functions → make changes → run `python3 psa.py <script>.ps1` (after obtaining it per [Development tools](#development-tools)) → update `TESTING.md` with any new regression scenarios.

---

## File encoding

### PowerShell scripts (`*.ps1`)

All `*.ps1` files in this repository are **checked out as UTF-8 with BOM and CRLF line endings** on every platform. This is the canonical encoding for PowerShell 5.1 + 7.x scripts that contain non-ASCII characters (the Japanese log strings inside `Write-Skip` / `Write-Warn2` calls). The `.gitattributes` rule that enforces this is:

```
*.ps1 text working-tree-encoding=UTF-8 eol=crlf
```

A note on git's internal storage: git applies standard text normalization at commit time. The blob inside the repository stores **BOM + LF** (line endings normalized to LF). On `git clone` / `git checkout`, git converts LF back to CRLF for `*.ps1` files thanks to the `eol=crlf` directive, so the file on disk is **BOM + CRLF** — which is what Windows PowerShell expects. The BOM is preserved as content bytes in both forms.

**Caveat for raw downloads**: if you download a `.ps1` file via the GitHub "Raw" button or `curl https://raw.githubusercontent.com/.../*.ps1`, you receive the blob form directly (**BOM + LF**) — git's checkout-time conversion does not apply to raw blob downloads. PowerShell 5.1 and 7.x handle both LF and CRLF in scripts correctly, so the file still executes, but if you need the exact canonical form (BOM + CRLF) you should clone the repository rather than downloading individual raw files. Practical recommendations:

- **For execution on Windows**: clone the repo (`git clone https://github.com/usui-tk/Deploy-Drivers-For-WindowsServer.git`), don't right-click → "Save raw as" individual files.
- **For inspection or quick patching**: raw downloads are fine; PowerShell tolerates LF line endings.
- **For re-publication or mirroring**: if you re-host the scripts elsewhere, regenerate them as BOM + CRLF to match the canonical form.

### Markdown documents (`*.md`)

All `*.md` files (`README.md`, `README.ja.md`, `TESTING.md`, `SPEC.md`, `CHANGELOG.md`, `CONTRIBUTING.md`, `SECURITY.md`, `CODE_OF_CONDUCT.md`) are stored and checked out as **UTF-8 without BOM** with **LF** line endings — the GitHub-native convention for Markdown rendering. The `.gitattributes` rule:

```
*.md text eol=lf
```

If you edit these files on Windows with an editor that auto-injects a BOM into `.md` files (some older Notepad++ versions do this), strip the BOM before committing or let `.gitattributes` normalize on next checkout.

### Console output and the Japanese log strings

The Japanese log strings inside the `.ps1` scripts are designed to render correctly on a ja-JP Windows console that is set to UTF-8 (`chcp 65001`). If your console is at the default ja-JP code page (932 / Shift-JIS), Japanese strings may garble. The scripts include a `[Console]::OutputEncoding = [System.Text.Encoding]::UTF8` call in P00 to enforce this, but if you redirect output to a file via `*>&1 | Tee-Object`, set your file encoding explicitly to UTF-8 to avoid double-encoding.

### Programmatic emission of `.ps1` content (Python helpers, AI agents, code generators)

If you ever produce `.ps1` content from a program (a Python helper script, a Bash heredoc, an AI agent that writes files, a code generator that synthesises new helper functions), you **must** ensure the bytes you emit conform to the UTF-8 + BOM + CRLF contract before they reach disk. Language defaults are uniformly wrong for this — Python's `"""..."""` triple-quoted strings, Node's template literals, Go raw strings, and shell heredocs all emit LF-only output on Linux / macOS regardless of the destination file's convention. A `.ps1` file with mixed line endings (some lines CRLF, others LF) will pass `pwsh -ParseFile` cleanly and look identical in any visual diff, but a byte-level check reveals the defect — and on a strict-CRLF consumer (some signtool builds, certain MSI authoring tools) it will fail at use time.

The canonical reference for the per-file-type contract, the corrective tooling patterns (Python `open(..., 'wb')` + explicit BOM + `\n` → `\r\n`), and the pre-commit verification commands is **[SPEC §A.2](./SPEC.md#a2-source-file-format)** (subsections **A.2.1** through **A.2.4**). The full forensic trail of the one occurrence of this defect that reached this repository — caught and silently corrected by `.gitattributes` at commit time — is recorded in **[SPEC §D.23](./SPEC.md#d23-mixed-line-endings-in-programmatically-emitted-ps1-content-python-script-defect)**.

---

## References

### Microsoft Learn

- [INF File Sections and Directives](https://learn.microsoft.com/en-us/windows-hardware/drivers/install/inf-file-sections-and-directives)
- [INF Manufacturer Section (TargetOSVersion / ProductType)](https://learn.microsoft.com/en-us/windows-hardware/drivers/install/inf-manufacturer-section)
- [Differences in Driver Installation Between Server and Client SKUs](https://learn.microsoft.com/en-us/windows-hardware/drivers/install/sku-specific-files-and-installation)
- [Inf2Cat command reference](https://learn.microsoft.com/en-us/windows-hardware/drivers/devtest/inf2cat)
- [SignTool command reference](https://learn.microsoft.com/en-us/windows/win32/seccrypto/signtool)
- [PnPUtil overview](https://learn.microsoft.com/en-us/windows-hardware/drivers/devtest/pnputil)
- [PnPUtil Command Syntax](https://learn.microsoft.com/en-us/windows-hardware/drivers/devtest/pnputil-command-syntax)
- [Windows Defender Application Control (WDAC) overview](https://learn.microsoft.com/en-us/windows/security/application-security/application-control/app-control-for-business/wdac)
- [Deploy WDAC policies with script (CiTool)](https://learn.microsoft.com/en-us/windows/security/application-security/application-control/app-control-for-business/deployment/deploy-wdac-policies-with-script)
- [Windows Driver Kit (WDK) installation](https://learn.microsoft.com/en-us/windows-hardware/drivers/download-the-wdk)
- [Windows Software Development Kit (SDK) downloads](https://learn.microsoft.com/en-us/windows/win32/devnotes/windows-sdk)
- [Driver signing requirements for Windows](https://learn.microsoft.com/en-us/windows-hardware/drivers/install/kernel-mode-code-signing-policy--windows-vista-and-later-)

### AMD

- [AMD Chipset Drivers (download)](https://www.amd.com/en/support/category/chipsets)
- [AMD Adrenalin Edition (download)](https://www.amd.com/en/support/category/graphics)
- [AMD Ryzen AI Software (installation guide)](https://ryzenai.docs.amd.com/en/latest/inst.html)
- [AMD Ryzen AI Software (release notes)](https://ryzenai.docs.amd.com/en/latest/relnotes.html)
- [AMD Ryzen AI Software (supported configurations)](https://ryzenai.docs.amd.com/en/latest/relnotes.html#supported-configurations)
- [AMD RyzenAI-SW (GitHub examples and source)](https://github.com/amd/RyzenAI-SW)
- [AMD RyzenAI-SW (latest releases)](https://github.com/amd/RyzenAI-SW/releases)

### This repository

- [TESTING.md](./TESTING.md) — Physical-hardware validation results and the NPU script's far weaker validation status. **English only.**
- [SPEC.md](./SPEC.md) — Developer specification. **English only.**
- [CHANGELOG.md](./CHANGELOG.md) — Chronological per-release change log. **English only.**
- [CONTRIBUTING.md](./CONTRIBUTING.md) — How to contribute.
- [README.ja.md](./README.ja.md) — Japanese translation of this document, kept in sync.
- [`psa.py` canonical location (ai-generated-artifacts)](https://github.com/usui-tk/ai-generated-artifacts/tree/main/scripts/python/powershell-static-analyzer) — PowerShell static analyzer used by this repository's CI gates.

---

## License

[MIT License](./LICENSE). Copyright (c) 2026 contributors.

The MIT licence applies to the **PowerShell scripts and accompanying documentation in this repository only**. The scripts download AMD installer EXEs and Ryzen AI driver ZIPs at runtime and do not redistribute AMD's binaries, INFs, or catalogs. AMD's redistribution terms apply to those files independently.

---

## Contributing

See [CONTRIBUTING.md](./CONTRIBUTING.md) for issue templates, PR guidelines, and how to run the regression test suite (including `psa.py`).

Issues and pull requests are tracked at: <https://github.com/usui-tk/Deploy-Drivers-For-WindowsServer>

Additional community documents:

- [`CODE_OF_CONDUCT.md`](./CODE_OF_CONDUCT.md) — Expected behaviour when interacting through Issues, Pull Requests, and Security Advisories. Tailored to the safety implications of self-signed kernel-mode drivers.
- [`SECURITY.md`](./SECURITY.md) — How to report security-impacting defects (driver-signing flaws, WDAC policy scope errors, credential exposure). **Do NOT file these as public Issues** — use the private Security Advisory channel instead.
- [`CHANGELOG.md`](./CHANGELOG.md) — Chronological per-release change log, organised by date and by script.
