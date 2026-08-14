# AMD Platform Hardware Identity Evidence Collector

**Collector source: `Collect-AmdNpuHardwareIdentityEvidence.ps1`**  
**Current collector version: 1.2.1**

This companion utility collects **private, read-only Windows platform evidence** when static NPU package analysis cannot resolve an actual CPU/NPU/GPU/firmware relation.

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

Collector 1.2.1 separates XRT host/build, driver, and device records so a `NPU Driver` entry cannot be flattened into a device identity such as `NPU Strix`.

## Quicktest source policy

If an AMD-authored `quicktest.py` is present in an installed Ryzen AI environment, the collector may:

- locate it;
- hash it;
- preserve source evidence privately when configured;
- apply the **reviewed static PCI-revision classification rule** as a separate evidence field.

The collector does not execute quicktest inference.

## Reviewed public-376 correlation

Collector 1.2.1 can correlate an observed Windows client stack against reviewed public 376 component hashes for:

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

Collector **v1.2.1 itself still requires a final real-device rerun** to qualify the structured XRT split, exact INF model correlation, reviewed-376 correlation output, and final privacy metadata as a complete v1.2.1 positive-control run.

This pending collector qualification does not invalidate the main v1.0.0 applicability dataset, but the disclaimer SHALL remain unless collector v1.2.1 is actually rerun on a positive-control Ryzen AI system before release claims it is real-device-qualified.

See `TESTING.md` in this directory.
