# AMD Platform Hardware Identity Evidence Collector Testing

This document defines the companion collector qualification contract. It is separate from the main NPU research runner's `../TESTING.md`.

## 1. Source/static validation

The exact collector source SHALL parse with PowerShell without AST errors.

Windows runtime qualification is required because the collector depends on Windows CIM/PnP/SetupAPI/registry/Authenticode behavior that Linux parser tests cannot reproduce.

## 2. Negative-control host

A real Windows PowerShell 5.1 run on an AMD Ryzen 7 5700X non-NPU host is retained as an important negative control.

Expected behavior:

- AMD platform devices are still collected;
- NPU candidate count is zero;
- the collector does not invent NPU capability from AMD CPU vendor identity;
- SetupAPI substring matching does not produce the old `input` / `xinput` false positives.

## 3. Positive-control Ryzen AI Z2 Extreme baseline

The qualified earlier collector path observed:

```text
CPU                    AMD Ryzen AI Z2 Extreme
CPU Family/Model/Step  26 / 36 / 0
NPU                    PCI\VEN_1022&DEV_17F0&SUBSYS_20CF1043&REV_10
Class                  ComputeAccelerator
Service                IpuMcdmDriver
Status                 OK
Driver                 32.0.20101.3760
```

The test SHALL keep architectural CPU Family/Model/Stepping separate from WMI classification fields.

The test SHALL keep:

```text
PCI REV_10
PCIe ExpressSpecVersion
firmware device revision
```

as distinct properties.

The firmware device revision was not observed through the standard collected PnP properties and SHALL remain unresolved unless an explicit source provides it.

## 4. Platform-correlation regression

A Ryzen AI positive-control run SHOULD verify:

- `AmdPlatformDevices` includes relevant `VEN_1022` and `VEN_1002` devices;
- `NpuCandidates` retains the exact NPU HWID/revision;
- GPU evidence identifies the installed AMD Radeon adapter and installed graphics INF relation where available;
- device roles are descriptive/correlative only, not applicability decisions;
- firmware-class devices are collected without intentionally storing serial-number properties;
- installed INF snapshots are unique, hash-manifested, and referenced to relevant devices;
- service-backed devices retain service-binary hash/version/signature evidence where resolvable;
- SetupAPI / `pnputil` slices remain focused and read-only;
- no install/update/remove action occurs.

## 5. Privacy regression

Inspect the Evidence ZIP and verify the collector does not intentionally retain:

- system serial/UUID;
- network identifiers;
- storage identifiers;
- serial/network-address PnP property values;
- other explicitly filtered sensitive device properties.

Do **not** claim the archive is anonymous. Normal PowerShell transcript headers and raw vendor output may contain user/computer/hostname data.

Privacy metadata SHALL state that raw XRT output can contain hostname data.

## 6. Recursive manifest / failure-finalization regression

Windows PowerShell 5.1 previously exposed a nested-path normalization bug during manifest generation. Qualification SHALL verify:

- nested `driver-inf/`, `xrt/`, and other evidence paths are covered recursively;
- manifest paths use `/`;
- manifest entries have correct length/SHA-256;
- transcript is finalized before its manifest hash is computed;
- an intentional probe failure still attempts `collector-status.json`, error evidence, manifest, and ZIP finalization;
- failed runs retain the working evidence directory;
- ZIP fallback is attempted when the primary archive path fails.

A synthetic Linux failure path may exercise generic finalization behavior, but it does not replace Windows qualification.

## 7. XRT / xrt-smi regression

When XRT is installed, verify discovery and immutable executable evidence for `xrt-smi.exe`.

Only these commands may be automatically executed:

```text
xrt-smi --version
xrt-smi examine -f JSON -o <private-path>
xrt-smi examine
```

Acceptance requires that executed argument logs never contain automatic:

```text
validate
configure
```

Timeout/non-zero/JSON parse failures SHALL be recorded as probe evidence and SHALL NOT automatically abort the entire collector.

Normalized output MAY retain:

- XRT version/build;
- driver name/version;
- device name;
- BDF;
- ready/status;
- firmware version.

Firmware **version** SHALL NOT be labeled firmware **device revision**.

## 8. Quicktest regression

If `quicktest.py` is present:

- locate/hash evidence;
- optionally preserve source privately;
- do not execute inference;
- apply reviewed quicktest-style PCI-revision classification only as its own evidence field.

For the reviewed Z2 Extreme relation:

```text
DEV_17F0 / REV_10 -> quicktest-style STX
```

This SHALL NOT be used to claim STXA or STXB.

## 9. v1.2.1 structured-XRT regression

A v1.2.1 Ryzen AI positive-control rerun SHALL verify:

- `XrtEvidence.StructuredJson` separates host/build, driver, and device records;
- XRT version/build metadata remains separate from NPU device identity;
- a `NPU Driver` record is not treated as an NPU device name;
- a `NPU Strix` device record carries its own firmware/BDF/ready data;
- raw-XRT hostname exposure is represented honestly in privacy metadata;
- NPU installed-INF correlation resolves the exact matching model/install section for `DEV_17F0`;
- relevant Radeon INF model-section hints may be retained as platform-correlation evidence without becoming the NPU identity authority;
- `ReviewedPublishedPayloadCorrelation` reports exact public-376 INF / `ipustack.sys` / `xrt-smi.exe` component matches when hashes match;
- exact client-stack correlation leaves Windows Server runtime proof false.

A synthetic structured-XRT helper regression is useful but does not replace the real Windows positive-control rerun.

## 10. Evidence ZIP byte/path regression

Verify:

- ZIP entries use `/` even on Windows;
- nested files are present where expected;
- manifest covers all intended evidence files;
- all manifest hashes/lengths recompute correctly;
- vendor binaries themselves are not copied merely because their metadata/hash was collected, unless the collector contract explicitly says otherwise.

## 11. Current qualification state

### Completed/retained evidence

- real Ryzen 7 5700X non-NPU negative-control qualification;
- real Ryzen AI Z2 Extreme positive-control evidence for CPU/NPU/PCI revision and client 376 stack;
- later successful XRT evidence establishes `NPU Strix` and firmware version `1.1.2.64`;
- main research toolkit has reviewed/promoted only generalized facts from the private evidence.

### Still required for collector v1.2.1 final qualification

Run the **current v1.2.1 source** again on the Ryzen AI Z2 Extreme positive-control system and verify all Section 9 outputs.

Expected purpose of that rerun:

- qualify the final structured-XRT schema;
- qualify improved INF/model correlation;
- qualify exact reviewed-376 correlation output;
- qualify current privacy metadata and Evidence finalization as one coherent v1.2.1 run.

This rerun is a release-quality check for the companion utility; it is not required to re-prove the already reviewed main-tool CPU/NPU applicability model.

## 12. Release acceptance for bundled collector

If the main toolkit v1.0.0 describes collector v1.2.1 as fully real-device-qualified, require:

- [ ] collector AST/source preflight PASS;
- [ ] negative-control behavior retained;
- [ ] current v1.2.1 Z2 Extreme positive-control run completed;
- [ ] structured XRT separation PASS;
- [ ] INF/model correlation PASS;
- [ ] reviewed-376 exact component correlation PASS where components match;
- [ ] privacy metadata reviewed;
- [ ] recursive manifest/hash verification PASS;
- [ ] no prohibited XRT/quicktest/installer execution;
- [ ] Evidence ZIP retained privately for audit.
