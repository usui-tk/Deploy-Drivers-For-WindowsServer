# AMD NPU Driver Research Toolkit

**Current source version: v1.0.0**  
**Release state: final-version source under release qualification**

`Invoke-AmdNpuDriverResearch.ps1` is the research and evidence layer for AMD Ryzen AI NPU Windows driver work in `Deploy-Drivers-For-WindowsServer`.

The toolkit exists so that later changes to `Deploy-AMDNpuDriverOnWindowsServer.ps1` can be based on reproducible vendor/package/runtime evidence rather than assumptions about a CPU series name, a broad PCI ID, or a Windows client installer.

The toolkit is deliberately **research-only and static-first**. It does not install AMD drivers, execute AMD installer EXEs, patch INF files, generate replacement catalogs, install certificates, or claim Windows Server runtime compatibility from static evidence.

## What the toolkit answers

The normal workflow is designed to answer these questions:

1. Which exact AMD processor SKUs publish an NPU capability?
2. Which processor codename/NPU family is associated with an exact SKU?
3. Which broad Windows NPU PCI identities are represented by the reviewed AMD driver packages?
4. What do PCI `REV_XX`, AMD quicktest-style classifications, XRT device labels, and firmware device revision mean, and which of those namespaces are distinct?
5. Which AMD NPU driver artifacts are publicly obtainable and immutably identified by SHA-256?
6. Which Windows versions are selected by the published INF **without modification**?
7. Does `npu_sw_installer.exe` impose OS routing beyond INF selection?
8. Does the driver binary contain finer generation-identification logic than the INF/installer?
9. Which reviewed driver release is the latest published-family-supported static candidate for an exact processor SKU?
10. When must automation stop with `ReviewRequired` rather than infer support?
11. What evidence is client runtime proof, and what still requires Windows Server runtime qualification?

The toolkit does **not** answer whether an NPU package will actually initialize, remain stable, and run workloads on Windows Server. That is a separate deployment/runtime test plane.

## Quick start

### Built-in/self-test path

```powershell
.\Invoke-AmdNpuDriverResearch.ps1 -Stages Test
```

### Normal full research run

No arguments means the complete research workflow:

```powershell
.\Invoke-AmdNpuDriverResearch.ps1
```

Equivalent explicit form:

```powershell
.\Invoke-AmdNpuDriverResearch.ps1 -Stages All
```

The normal stage order is:

```text
Test
  -> HardwareIdentity
  -> ProcessorCatalog
  -> Discover
  -> Metadata
  -> Acquire
  -> Extract
  -> Inspect
  -> DriverBinary
  -> Compare
  -> Matrix
  -> Build
  -> Validate
```

### Local artifact replay / private qualification

Known local ZIP/EXE/MSI/CAB/7z artifacts can be supplied without changing the normal public acquisition catalog:

```powershell
.\Invoke-AmdNpuDriverResearch.ps1 `
  -PackagePath 'D:\Artifacts\NPU_RAI_376_WHQL.zip'
```

`-PackagePath` is the correct path for restricted/private qualification artifacts such as the reviewed 314 package. Supplying a private artifact does **not** make it public, recommendable, or automatically downloadable.

### Explicit public output root

```powershell
.\Invoke-AmdNpuDriverResearch.ps1 `
  -PublicOutputRoot 'D:\NpuResearchPublic'
```

`-PublicOutputRoot` is a caller-visible contract and is regression-tested after the 0.8.1-dev static-analysis correction.

## Safety model

The following are invariants:

1. AMD installer executables are treated as untrusted research inputs and are **not executed**.
2. AMD driver payloads are not patched or modified.
3. INF files are parsed, not installed.
4. Static extraction is bounded and uses the shared 7-Zip research kernel.
5. ZIP/EXE/MSI/CAB/7z outer containers are supported as research inputs.
6. Vendor binary observations are exact-hash scoped. An unknown hash does not inherit a reviewed contract.
7. A broad INF/PnP match is not automatically an AMD published-support claim.
8. A driver-binary recognition path is not automatically an AMD published-support claim.
9. Windows client runtime evidence is not Windows Server runtime proof.
10. Unknown processor or hardware identities fail closed.
11. Invalid generated publication is not promoted over the previous valid `public/**` surface.
12. Generated `public/**` files are never repaired by hand; source/data/generator logic is fixed and regeneration is required.

## Runtime and repository byte contracts

### Source-data schema contract

Every Git-tracked `data/*.json` document has a distinct camelCase source schema under `schemas/source-data/`. The Test stage maintains an explicit 12-file filename -> expected `schemaVersion` -> schema mapping and fails if a source file is unregistered, a schema is missing, or the guarded version differs. These source schemas are intentionally separate from the PascalCase generated-public schemas.


Supported runtime paths:

- Windows PowerShell 5.1 on Windows;
- PowerShell 7.x on Windows;
- PowerShell 7.x on Linux for static/offline research where 7-Zip is available.

Repository conventions:

- root `.ps1`: UTF-8 with BOM + CRLF;
- source Markdown/static JSON: UTF-8 without BOM + LF;
- generated public Markdown: UTF-8 without BOM + LF;
- generated public JSON: canonical deterministic JSON;
- Evidence/archive relative paths: `/` separators.

The main toolkit source is now intentionally `v1.0.0` for final release qualification after the 0.x development line passed Audit #3. The companion hardware collector has an independent utility version lineage and is documented under `tools/`.

## Current reviewed artifact corpus

The normal public/reviewed corpus is:

| Artifact | Role | SHA-256 |
|---|---|---|
| `NPU_RAI1.5_280_WHQL.zip` | historical public 280 | `a278a2c92cdc47e0da4cab2cbdb5347a127eee67311927578f4e151618446ce4` |
| `NPU_RAI_280_WHQL.zip` | later public 280 | `803afe1e2d75b717f60a368453306ccbd4877cdd936b6531b946b95109a22144` |
| `NPU_RAI_376_WHQL.zip` | public 376 | `aa836cbfcad5d0782c79b58f197aa50624af37e7cb8311c5f94d85b0dc3ccaad` |

Private qualification only:

| Artifact | Role | SHA-256 |
|---|---|---|
| `NPU_RAI1.6.1_314_WHQL.zip` | authenticated/restricted static comparison only | `023caa295d3b2fe4befccdba84db5867abb6428a5e057ac1acdbda03853cf0ac` |

The 314 artifact is intentionally excluded from the ordinary public acquisition catalog and has `RecommendationEligible=false` semantics.

## High-value research findings

### 1. The reviewed NPU INF is not blocked by ProductType=1

The reviewed 280/314/376 INF family uses the same broad model-selector shape:

```text
%ManufacturerName%=IpuMcdmDriver.Mfg,NTamd64.10.0...22000
PCI\VEN_1022&DEV_1502
PCI\VEN_1022&DEV_17F0
```

`NTamd64.10.0...22000` has a build floor but does not carry an explicit ProductType restriction.

Static consequence for the Server profiles currently modeled by the toolkit:

| Server | Build relation to 22000 | Published INF static state |
|---|---:|---|
| Windows Server 2016 | below | rejected by build floor |
| Windows Server 2019 | below | rejected by build floor |
| Windows Server 2022 | below | rejected by build floor |
| Windows Server 2025 | 26100, above | selector candidate |

This is one of the most important deployment-project corrections: the NPU path must not copy a generic assumption that AMD's client driver requires ProductType rewriting. Server 2025 first needs an **unmodified-package runtime test** before any INF modification is justified.

### 2. The AMD installer has a separate OS-routing layer

Static disassembly of the two reviewed exact installer hashes recovers the same relevant routing family:

```text
Windows major == 10
build >= 26100                  -> MCDM route
build >= 22621 and UBR >= 3527  -> MCDM route
build >= 22621 and UBR < 3527   -> WDF/NULL route
build >= 22000 and < 22621       -> WDF/NULL route
lower builds                     -> Windows 10 / WDF-NULL route
```

The reviewed packages contain the MCDM stack but do **not** contain the installer-referenced `npu_wdf_stack_prod\kipudrv\kipudrv.inf` payload.

This means Server 2016/2019/2022 are not merely an INF decoration problem. The reviewed current package corpus lacks the lower-build WDF payload referenced by the installer routing logic.

### 3. CPU/NPU identity is multi-layered

The toolkit keeps the following namespaces separate:

| Layer | Example | Meaning |
|---|---|---|
| exact CPU SKU | `AMD Ryzen AI Z2 Extreme` | product identity/published NPU capability |
| codename | Strix Point | reviewed product-family relation |
| broad PCI HWID | `PCI\VEN_1022&DEV_17F0` | broad Windows NPU identity |
| PCI revision | `REV_10` | PCI configuration-space revision byte |
| quicktest-style class | `STX` | AMD historical PCI-revision classification hint |
| XRT device label | `NPU Strix` | observed runtime identity label |
| firmware version | `1.1.2.64` | firmware version, not device revision |
| firmware device revision | STXA/STXB/KRK1/... | separate management-protocol refinement |

These values must not be collapsed into one field. In particular, PCI `REV_10`, XRT firmware version `1.1.2.64`, and firmware device revision `1/2/...` are different things.

### 4. `DEV_17F0` is not synonymous with Strix

AMD `npu_check` and the reviewed installer use broad identities (`1502` and `17F0`). Linux `amdxdna` and the reviewed Windows 376 `ipustack.sys` expose a finer NPU4 refinement model under the broad 17F0 family.

The cross-source revision order is:

| Firmware device revision | Family label |
|---:|---|
| 1 | Strix A |
| 2 | Strix B |
| 3 | Krackan 1 |
| 4 | Krackan 2 |
| 5 | Strix Halo |
| 6 | Gorgon Point 1 |
| 7 | Gorgon Point 2 |
| 8 | Gorgon Point 3 |
| 9 / other | unknown/fallback |

The reviewed Windows 376 binary also contains a `0x117` management primitive and the same refinement order. This is strong exact-binary/static correlation, but it is not a license to infer vendor support for every recognized generation.

### 5. Published support and binary capability remain independent gates

AMD Ryzen AI 1.8 documentation publishes NPU driver `32.0.203.376` as production for:

- Phoenix;
- Hawk Point;
- Strix;
- Strix Halo;
- Krackan Point.

The reviewed 376 binary can internally recognize Gorgon Point revision labels, but Gorgon Point is outside that reviewed AMD 376 production-family statement. Therefore:

```text
broad HWID match
+ binary generation recognition
+ exact Gorgon Point CPU
- reviewed 376 published-family support
= ReviewRequired
```

The same principle applies to Gorgon Halo: published processor/NPU capability is not enough when exact reviewed NPU identity/artifact-support evidence is incomplete.

## Exact-SKU processor catalog and driver applicability

Version 0.9.0-dev expands the reviewed processor catalog to **112 exact AMD processor SKUs**:

- 90 with AMD-published NPU capability;
- 18 with AMD-published NPU unavailability;
- 4 retained as no-published-NPU-capability negative controls.

Coverage includes reviewed exact SKUs from:

- Ryzen 7040 / Ryzen PRO 7040;
- Ryzen 8040 / Ryzen PRO 8040;
- Ryzen 8000G / Ryzen PRO 8000;
- Ryzen 200 / Ryzen PRO 200;
- Ryzen AI 300 / Ryzen AI PRO 300;
- Ryzen AI Max 300 / Max PRO 300;
- Ryzen AI 400 / Ryzen AI PRO 400 mobile and desktop;
- Ryzen AI Max PRO 400;
- Ryzen Z handheld controls including Ryzen AI Z2 Extreme.

The catalog is exact-SKU driven. Similar naming, series membership, CPU core layout, iGPU family, or presumed silicon lineage is never sufficient to synthesize an NPU capability.

Generated applicability outputs:

```text
public/catalog/processor-driver-applicability.json
public/catalog/processor-driver-applicability.md
```

The current decision classes are:

- `SelectLatestPublishedStaticCandidate`;
- `ReviewRequired`;
- `NoNpuDriverRequired`.

The 0.9.0-dev dataset produces:

```text
Processor catalog       112
Compatibility rows      336
Processor selections    112
Applicability rows      112
ReviewRequired           28
```

The recommendation relation is intentionally richer than `CPU name -> URL`:

```text
exact CPU SKU
  -> codename / NPU generation
  -> reviewed NPU identity
  -> reviewed artifact capability
  -> AMD published family support
  -> INF/installer/binary static evidence
  -> Windows Server static applicability
  -> observed runtime evidence, if any
  -> latest recommendation-eligible public artifact
```

Unknown processors and unexpected hardware fail closed.

## Reviewed Ryzen AI Z2 Extreme runtime evidence

Private runtime evidence from a Ryzen AI Z2 Extreme positive-control system was reviewed and only generalized facts were promoted into repository source data.

Reviewed observations:

```text
CPU                    AMD Ryzen AI Z2 Extreme
CPU family/model/step  26 / 36 / 0
NPU PCI                VEN_1022 DEV_17F0 SUBSYS_20CF1043 REV_10
Service                IpuMcdmDriver
Installed driver       32.0.20101.3760
XRT device             NPU Strix
XRT firmware version   1.1.2.64
```

The installed NPU INF, `ipustack.sys`, and `xrt-smi.exe` matched the reviewed public 376 payload exactly. This provides **exact-artifact Windows client runtime evidence** for that SKU.

It does not prove:

- Windows Server runtime support;
- STXA versus STXB;
- that every `DEV_17F0&REV_10` platform is the same exact SKU;
- that future AMD releases preserve the same mapping.

## Windows Server research interpretation

The toolkit intentionally separates four questions:

1. **Does the exact CPU publish an NPU?**
2. **Does the package's INF select the hardware/OS as published?**
3. **Does AMD's installer/binary contain a compatible route or recognition path?**
4. **Has the exact artifact actually run successfully on the target Windows Server?**

Only the fourth question is runtime proof.

For the current reviewed corpus:

- Server 2016/2019/2022 are below the INF build floor and the reviewed packages do not contain the lower-build WDF payload referenced by the installer;
- Server 2025 satisfies the INF build floor and enters the reviewed installer MCDM route, making it the correct first target for an unmodified-package runtime experiment;
- no reviewed Windows client runtime result may be copied into a Server-runtime field.

## Direct feedback for `Deploy-AMDNpuDriverOnWindowsServer.ps1`

The later deployment script should consume reviewed research data with a fail-closed decision model similar to:

```text
read exact CPU SKU
  -> catalog entry exists?
       no  -> ReviewRequired / stop
       yes
  -> NPU expected?
       no  -> no NPU action
       yes
  -> read actual NPU HWID / PCI revision
  -> expected CPU/NPU relation matches?
       no  -> ReviewRequired / stop
       yes
  -> evaluate recommendation-eligible reviewed artifacts
  -> require AMD published family support
  -> require static Windows Server package gate
  -> choose latest reviewed public candidate
  -> only patch/re-sign when runtime evidence proves a modification is actually necessary
```

Additional deployment rules derived from the research:

- do not use CPU series-prefix inference;
- do not treat `DEV_17F0` as a complete generation selector;
- do not replace published-support evidence with binary-string recognition;
- do not recommend private 314;
- do not rewrite the embedded INF version into AMD's published marketing/driver-label namespace;
- preserve exact vendor artifact SHA-256 before any transformation;
- for Server 2025, test the original WHQL package before applying a ProductType patch that the reviewed INF does not require;
- for Server 2016/2019/2022, treat the missing lower-build/WDF payload as a separate technical problem rather than assuming an INF-only fix;
- unknown CPU/NPU/revision combinations must stop automation.

See `REVERSE-ENGINEERING-NOTES.md` for the detailed evidence behind these rules and `SPEC.md` for the normative machine behavior.

## Evidence model

The toolkit keeps evidence planes separate:

| Level | Examples | Commit status |
|---|---|---|
| vendor artifact | AMD ZIP/EXE/MSI and contained binaries | runtime input, not committed |
| private host evidence | collector ZIP, PnP, XRT, SetupAPI, INF snapshots | private/runtime, not committed |
| reviewed source data | processor catalog, identity rules, contracts, generalized observations | Git-tracked |
| generated publication | `public/**` | generated commit surface |

Important evidence classes include `Published`, `Embedded`, `PayloadObserved`, `StaticDisassemblyProven`, `Analysis`, `ObservedClientRuntime`, and runtime/private evidence.

A stronger evidence class does not automatically replace a different evidence plane. For example, exact client-runtime evidence cannot satisfy a Server-runtime field.

## Repository surfaces

Canonical layout:

```text
Deploy-Drivers-For-WindowsServer/
└─ tools/
   └─ amd-npu-driver-research/
      ├─ Invoke-AmdNpuDriverResearch.ps1
      ├─ README.md
      ├─ SPEC.md
      ├─ TESTING.md
      ├─ CHANGELOG.md
      ├─ REVERSE-ENGINEERING-NOTES.md
      ├─ SOURCES.md
      ├─ PUBLICATION-POLICY.md
      ├─ ARCHITECTURE-PARITY.md
      ├─ data/
      ├─ schemas/
      ├─ authored/
      ├─ public/
      ├─ inventory/
      ├─ private/
      ├─ reports/
      ├─ work/
      └─ tools/
         ├─ Collect-AmdNpuHardwareIdentityEvidence.ps1
         ├─ README.md
         └─ TESTING.md
```

Surface policy:

- `data/**`, `schemas/**`, source/docs: reviewed Git source;
- `public/**`: generated commit surface;
- `inventory/**`: runtime staging;
- `private/**`: private evidence/runtime state;
- `work/**`: downloaded/extracted workspace;
- generated runtime reports are not hand-maintained source.

See `PUBLICATION-POLICY.md` for the exact publication contract.

## Companion hardware evidence collector

`tools/Collect-AmdNpuHardwareIdentityEvidence.ps1` is a separate read-only Windows collector used when static package evidence cannot resolve the actual platform.

It can collect CPU/NPU/GPU/platform PnP identity, installed INF/service-driver evidence, XRT/xrt-smi read-only observations, and quicktest-style classification evidence. It must not execute `xrt-smi validate`, `xrt-smi configure`, AMD installer programs, or quicktest inference workloads.

Collector output is private evidence and is not a Git commit surface. Only reviewed generalized facts may be promoted to `data/**`.

Collector v1.2.1 is implemented, but its final real-device rerun on the Ryzen AI Z2 Extreme remains a release-quality qualification item. See `tools/TESTING.md`.

## Pre-release 0.9.1-dev qualification baseline

Current source SHA-256:

```text
22036b61d64af2d272d011dadb381e41b850719d5bbc3f4efc3450c9d94aee07
```

The audit-remediation source has completed:

- Linux / PowerShell 7.6.4 full local replay: 13/13 stages PASS, exit 0;
- source-data schema/version contracts: 12/12 registered; external Draft 2020-12 validation 12/12 PASS;
- partial-stage negative controls (`Compare`, `DriverBinary`, `Matrix`, `Build`): explicit `BLOCKED`, exit 2 when prerequisites are absent;
- dataset: 336 matrix rows / 112 selections / 112 applicability rows / 28 `ReviewRequired`;
- publication privacy/dataset/JSON/Markdown validation: PASS.

The 0.9.1-dev source was subsequently qualified on Windows PowerShell 5.1.26100.9168 with 13/13 stages PASS, exit code 0, and the exact shipped pre-release script hash `22036b61d64af2d272d011dadb381e41b850719d5bbc3f4efc3450c9d94aee07`. That evidence remains historical pre-release evidence only and is not the final v1.0.0 qualification evidence.

This qualification does not constitute Windows Server NPU runtime qualification.

## v1.0.0 release-qualification status

Audit #3 approved the 0.9.1-dev implementation and closed all prior blocking findings. The source was then deliberately bumped to `1.0.0`; `1.0.0` is not used as an interim development version.

The v1.0.0 source adds a Test-stage guard that requires the `.NOTES` `Tool version:` declaration to match `$script:ToolVersion`. Generated `public/**` is never hand-edited during the bump.

Current release-candidate Linux qualification using the canonical reviewed public corpus:

```text
Script SHA-256        2dc94306ed7f9838a05be21ae2d6f44494446aaeded9ad978d3ebde5be0c04cf
PowerShell            7.6.4 / Linux
Full replay           13 / 13 PASS
ExitCode              0
Source data contracts 12
Matrix rows           336
Selections            112
Applicability rows    112
Select candidate       62
No NPU driver          22
ReviewRequired         28
```

Compared with the accepted 0.9.1-dev `public/**`, exactly 12 JSON files change because the tool version/source hash changes, while all 11 Markdown files remain byte-identical. This is the expected version-bump-only pattern.

Final v1.0.0 release-candidate qualification is now complete for the main research toolkit. The exact v1.0.0 script completed a fresh automatic AMD vendor re-acquisition on Windows PowerShell 5.1.26100.9168 with 13/13 stages PASS and exit code 0. The acquisition inventory records all three public reviewed artifacts as `Downloaded`, with `PackagePath=[]` and the expected reviewed SHA-256 values. The Windows-generated `public/**` tree is 23/23 byte-identical to the Linux/PowerShell 7 v1.0.0 canonical-corpus qualification output. Audit #4 remains the final independent release-readiness review.

The Linux build environment used during preparation temporarily could not resolve `download.amd.com`, so the successful Linux qualification uses canonical reviewed packages pinned to the same SHA-256 values. That limitation is explicitly retained in the audit evidence; fresh vendor re-acquisition was instead proven by the Windows v1.0.0 qualification run.

## Documentation map

- `README.md` — purpose, operating model, major findings, deployment implications.
- `SPEC.md` — normative contracts and fail-closed semantics.
- `TESTING.md` — source, runtime, dataset, publication, and release qualification requirements/results.
- `REVERSE-ENGINEERING-NOTES.md` — detailed payload/installer/binary/identity findings.
- `SOURCES.md` — upstream and evidence provenance references.
- `PUBLICATION-POLICY.md` — generated/public/private boundary.
- `ARCHITECTURE-PARITY.md` — shared research-runner architecture inherited from Chipset/Graphics.
- `CHANGELOG.md` — development chronology.
- `tools/README.md` / `tools/TESTING.md` — companion real-hardware evidence collector.
