# AMD Platform Hardware Identity Evidence Collector

**Collector source: `Collect-AmdNpuHardwareIdentityEvidence.ps1`**  
**Current collector version: 1.3.0**

This companion utility collects **private, read-only Windows platform evidence** when static NPU package analysis cannot resolve an actual CPU/NPU/GPU/firmware relation.

Driver-track selection no longer requires a CPU/NPU relation. The collector may
continue to retain CPU, firmware and XRT fields for diagnostics and research, but
the main resolver consumes only the complete PnP HardwareID/CompatibleID set for
one NPU device instance plus the target Windows build. See
`../data/hardware-driver-selection.json`.

It is intentionally stored under:

```text
tools/amd-npu-driver-research/tools/
```

so the main `Invoke-AmdNpuDriverResearch.ps1` remains the single-file primary research runner while platform-specific evidence collection stays an auxiliary tool.

The collector version lineage is independent from the main research toolkit version. The main toolkit source is now intentionally v1.0.0 and is undergoing final release qualification.

## Purpose

The collector can gather evidence needed to answer questions such as:

- What exact CPU SKU is installed?
- What architectural CPU Family/Model/Stepping is observable?
- Which AMD platform PnP devices are present?
- Does the host expose an AMD NPU, and under which exact HWID/PCI revision?
- Which NPU service/INF/driver binary is actually active?
- What AMD GPU and other platform devices correlate with the NPU platform?
- Does installed XRT identify the device independently?
- Do installed INF/model-section and reviewed public-driver component hashes correlate?
- Can multiple evidence planes narrow the NPU generation without confusing revision namespaces?

The collector does not make deployment decisions. It produces evidence for later review.

Collector 1.3.0 additionally emits a compact machine-readable observation file:

```text
npu-hardware-selection-input.json
```

Its authored review schema is
`schemas/npu-hardware-selection-input.schema.json` under this companion-tool
directory.

This file is intended as downstream input to the reviewed machine authority in
`../data/hardware-driver-selection.json`. The collector itself does not select
280 or 376 and never enables an automatic 280 fallback.

The compact artifact records:

- complete local PnP enumeration status;
- Windows Client/Server execution class and OS `ProductType`;
- PowerShell version/edition and administrator state;
- each candidate device instance independently;
- Hardware IDs, Compatible IDs and a normalized `IdentitySet`;
- stable string `ConfigManagerErrorCode` values;
- installed INF, service and driver-binary evidence;
- per-device PnP property collection status;
- `NoNpuObserved`, `NpuCandidateObserved` or `IncompleteEvidence` as an observation, not a deployment decision.

## Collected evidence planes

### CPU

- exact `Win32_Processor.Name`;
- architectural CPU Family/Model/Stepping where recoverable;
- WMI family/revision retained separately;
- processor-class PnP identity;
- `amdppm.sys` file/hash/version/signature evidence.

### NPU and AMD platform PnP

- AMD `VEN_1022` platform devices;
- AMD Radeon `VEN_1002` devices;
- hardware IDs / compatible IDs;
- PCI `VEN/DEV/SUBSYS/REV`;
- class/service/status;
- non-sensitive PnP properties;
- parent/location topology;
- installed driver/INF/signer metadata;
- service binary metadata/hash/signature;
- focused `pnputil` and SetupAPI evidence.

### GPU / platform correlation

Integrated GPU evidence is useful because a platform-specific graphics INF section such as a Strix-tagged model may act as an independent **correlation** plane. It is not treated as the authoritative NPU identity by itself.

### Firmware-class devices

The collector inventories relevant firmware-class device/version evidence while filtering intentionally sensitive serial/network-address properties.

### Installed INF snapshots

Unique installed INF files referenced by the relevant platform devices may be copied into the private Evidence ZIP with a manifest and exact hashes. This enables later model-section correlation without relying only on registry/CIM summaries.

## Identity and revision model

The collector intentionally separates:

```text
PCI REV_XX
PCIe ExpressSpecVersion
quicktest-style classification
XRT device label
XRT firmware version
firmware/NPU device revision
```

These fields are not aliases.

A real Ryzen AI Z2 Extreme run demonstrated why this matters: `DEVPKEY_PciDevice_ExpressSpecVersion = 2` is a PCIe specification property, not firmware NPU generation revision.

## XRT / xrt-smi policy

When `xrt-smi.exe` is present, the collector may run only the read-only paths:

```text
xrt-smi --version
xrt-smi examine -f JSON -o <private-path>
xrt-smi examine
```

It SHALL NOT automatically run:

```text
xrt-smi validate
xrt-smi configure
```

It also SHALL NOT execute a quicktest inference workload.

XRT evidence can include:

- XRT build/version;
- driver records;
- device name/BDF/readiness;
- NPU firmware version;
- raw vendor output retained privately.

The collector separates XRT host/build, driver, and device records so a `NPU Driver` entry cannot be flattened into a device identity such as `NPU Strix`.

## Quicktest source policy

If an AMD-authored `quicktest.py` is present in an installed Ryzen AI environment, the collector may:

- locate it;
- hash it;
- preserve source evidence privately when configured;
- apply the **reviewed static PCI-revision classification rule** as a separate evidence field.

The collector does not execute quicktest inference.

## Windows Server positive observation

Collector 1.3.0 explicitly supports a future positive run after a built NPU
driver has been applied to Windows Server. A positive Server observation means:

- local PnP enumeration completed;
- an NPU candidate identity was observed;
- installed Service/INF/driver-binary/signature evidence was collected where available.

The installed driver may be custom-built or self-signed. Its signer and an
exact public-376 hash match are evidence fields, not prerequisites for observing
the NPU. This does not approve deployment and does not by itself prove an NPU
application workload succeeded.

## Reviewed public-376 correlation

The collector can correlate an observed Windows client stack against reviewed public 376 component hashes for:

- NPU INF;
- `ipustack.sys`;
- `xrt-smi.exe`.

An exact component match establishes an exact reviewed **client stack** correlation only. It does not set Windows Server runtime proof.

## Safety and privacy

Collector output is:

```text
Private
Runtime
Non-Commit
May contain host-specific identifiers in raw vendor/transcript evidence
```

The collector intentionally filters known sensitive properties such as machine serial/UUID and serial/network-address PnP properties. However, raw vendor output and normal PowerShell transcript headers may still contain host/user/computer naming data.

Therefore the Evidence ZIP must be treated as private and reviewed/redacted before sharing outside the intended audit workflow.

The collector never installs, updates, removes, enables, disables, or re-signs a driver.

## Usage

Typical run:

```powershell
.\Collect-AmdNpuHardwareIdentityEvidence.ps1
```

Skip read-only XRT execution even if installed:

```powershell
.\Collect-AmdNpuHardwareIdentityEvidence.ps1 -SkipXrtSmiProbe
```

Use a longer XRT probe timeout where needed:

```powershell
.\Collect-AmdNpuHardwareIdentityEvidence.ps1 -XrtSmiTimeoutSeconds 60
```

Run the hardware-independent contract and archive self-test:

```powershell
.\Collect-AmdNpuHardwareIdentityEvidence.ps1 -SelfTest
```

The self-test does not enumerate the host and does not require an NPU. It covers
Client/Server classification, complete/failed zero-candidate semantics, stable
identity and enum serialization, a synthetic Server positive case, JSON
round-trip validation, exact manifest verification and ZIP reopen/hash/path
verification.

The exact supported parameter set is authoritative in the script's `param()` block.

## Failure preservation

The collector is designed to preserve evidence on failure where the output directory remains writable.

It attempts to retain:

- `collector-status.json`;
- console transcript;
- `errors/collector-error.txt`;
- recursive manifest;
- partial Evidence ZIP;
- the working evidence directory for debugging.

ZIP entries use forward-slash names for cross-platform review.

Collector 1.3.0 reports three separate finalization gates:

- JSON round-trip integrity;
- manifest length/SHA-256 completeness;
- ZIP reopen, entry path/count/length/SHA-256 integrity.

An archive that was physically created but fails one of these gates is retained
for diagnosis and must not be treated as accepted evidence.

## Relationship to the main research toolkit

Raw collector evidence does not go directly into `public/**`.

The promotion path is:

```text
private collector Evidence
  -> human/research review
  -> generalized fact in data/**
  -> generated public/**
```

This prevents machine-specific identifiers and unreviewed runtime observations from becoming deployment policy.

The current Ryzen AI Z2 Extreme generalized record was promoted only after multiple evidence planes converged on Strix/376 client runtime identity.

## Current qualification status

Qualified older positive-control evidence establishes:

- Ryzen AI Z2 Extreme CPU Family 26 / Model 36 / Stepping 0;
- NPU `DEV_17F0&REV_10`;
- `IpuMcdmDriver` active;
- client driver `32.0.20101.3760`;
- XRT `NPU Strix` / firmware `1.1.2.64` from the later successful evidence path;
- firmware device revision still unresolved by the collected standard interfaces.

Collector **v1.3.0** has passed its hardware-independent self-test and static
parser gate. Its new compact selection-input and integrity contract still needs
one real NPU-positive run before v1.3.0 is described as real-device-qualified.

To minimize user test cost, a ceremonial Windows Client rerun is not required.
The positive gate is dependency-blocked and deferred: production NPU driver
build-script redevelopment, review, and separately authorized Server driver
application must complete first. No collector execution is currently requested.
When that Server state eventually exists, a single run can validate PnP identity,
custom/self-signed runtime-driver observation and the v1.3.0 evidence package
together.

Until that run is reviewed, the Server-positive support is implemented and
synthetically qualified but not yet real-device-qualified. This does not alter
the already accepted main-runner Client positive and Server no-NPU evidence.

No additional collector implementation defect is presently known. The only
remaining collector qualification item is one current-v1.3.0 NPU-positive run.
It SHALL remain `DeferredDependencyBlocked` until production build-script
redevelopment and separately authorized Server application are complete. Do not
repeat the accepted Client or Server no-NPU main-runner gates.

The following bounded command is retained for that future dependency-satisfied
Server state; it is not a current execution request:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass `
  -File .\Collect-AmdNpuHardwareIdentityEvidence.ps1 `
  -SkipXrtSmiProbe `
  -SkipQuicktestSnapshot
```

Use Windows PowerShell 5.1 when practical at that future time so the same single run adds Server
runtime coverage not supplied by the earlier PowerShell 7.6.5 no-NPU result.
The collector does not install or repair the driver. If the intended installed
state is absent or unhealthy, preserve the evidence and stop; do not turn the
collector run into an installation/retry loop.

PASS qualifies only the collector's observation and evidence-integrity
contracts. Application/inference workload proof, driver deployment, signing,
INF transformation, public-376 equality and XRT are separate or optional
planes, as documented in the parent `SPEC.md` and `TESTING.md`.

Independent review or promotion of the main runner may proceed while the
collector remains explicitly static/synthetic-qualified. Do not label collector
1.3.0 real-device-qualified until the deferred Evidence is reviewed.

See `TESTING.md` in this directory.
