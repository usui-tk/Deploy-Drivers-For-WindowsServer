# AMD Platform Hardware Identity Evidence Collector Testing

This document defines the companion collector qualification contract. It is separate from the main NPU research runner's `../TESTING.md`.

## 1. Source/static validation

The exact collector source SHALL parse with PowerShell without AST errors.

Collector 1.3.0 also exposes a hardware-independent self-test:

```powershell
.\Collect-AmdNpuHardwareIdentityEvidence.ps1 -SelfTest
```

It SHALL pass before any user real-machine run is requested. The self-test
covers stable `ConfigManagerErrorCode` strings, normalized/deduplicated identity
sets, complete versus failed zero-candidate semantics, Windows Server host
classification, a synthetic Server/custom-driver positive case, JSON
round-trip validation, manifest verification and ZIP reopen/hash/path checks.

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
- CPU, CPUID, CPU/NPU combination, firmware revision and XRT labels are not inputs to the main hardware-only driver-track resolver;
- the resolver consumes PnP HardwareID/CompatibleID values per NPU device instance and keeps `SUBSYS`/`REV` as evidence;
- firmware-class devices are collected without intentionally storing serial-number properties;
- installed INF snapshots are unique, hash-manifested, and referenced to relevant devices;
- service-backed devices retain service-binary hash/version/signature evidence where resolvable;
- SetupAPI / `pnputil` slices remain focused and read-only;
- no install/update/remove action occurs.

The compact `npu-hardware-selection-input.json` SHALL additionally verify:

- `InputSource = LocalWindowsPnP`;
- `LocalEnumerationPerformed = true` and `ManualOverrideUsed = false`;
- complete Hardware ID and Compatible ID arrays remain scoped to each device instance;
- `IdentitySet` is ordinally normalized and deduplicated;
- `ConfigManagerErrorCode` is serialized as a stable string such as `CM_PROB_NONE`;
- CPU, firmware and XRT observations are not copied into the downstream selection input;
- the collector reports an observation but does not select 280 or 376;
- automatic 280 fallback remains false.

## 4.1 Enumeration completeness / no-NPU fail-closed regression

The following cases are distinct:

| Enumeration | Candidate count | Required observation |
| --- | ---: | --- |
| `Complete` | 0 | `NoNpuObserved` |
| `Complete` | 1 or more | `NpuCandidateObserved` |
| `Partial` or `Failed` | any | `IncompleteEvidence` |

An incomplete enumeration SHALL NOT become a no-NPU result. The collector does
not emit the downstream policy decision `NoNpuDriverRequired`; that decision
belongs to the reviewed machine authority.

## 4.2 Windows Server positive-control contract

After a built NPU driver is applied to Windows Server, one collector run MAY be
used as the v1.3.0 real-device positive gate. Acceptance requires:

- `Host.ExecutionClass = WindowsServer` and `ProductType` is 2 or 3;
- PnP enumeration is complete;
- at least one NPU candidate retains its exact instance/HWID/compatible-ID set;
- Service, status and stable `ConfigManagerErrorCode` are present;
- installed INF, driver record and service-binary hash/signature evidence are retained where resolvable;
- a custom-built or self-signed signer is accepted as observed runtime evidence;
- public-376 exact hash correlation is not required;
- XRT is not required;
- the result does not approve deployment and does not claim application workload success.

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

## 9. v1.3.0 structured-XRT and selection-input regression

A v1.3.0 NPU-positive run SHALL verify:

- `XrtEvidence.StructuredJson` separates host/build, driver, and device records;
- XRT version/build metadata remains separate from NPU device identity;
- a `NPU Driver` record is not treated as an NPU device name;
- a `NPU Strix` device record carries its own firmware/BDF/ready data;
- raw-XRT hostname exposure is represented honestly in privacy metadata;
- NPU installed-INF correlation resolves the exact matching model/install section for `DEV_17F0`;
- relevant Radeon INF model-section hints may be retained as platform-correlation evidence without becoming the NPU identity authority;
- `ReviewedPublishedPayloadCorrelation` reports exact public-376 INF / `ipustack.sys` / `xrt-smi.exe` component matches when hashes match;
- exact client-stack correlation leaves Windows Server runtime proof false;
- `npu-hardware-selection-input.json` records the host, enumeration and independent candidate identities without performing a track decision;
- Server positive evidence, when applicable, preserves a built/self-signed installed stack without requiring reviewed public-376 equality.

A synthetic structured-XRT helper regression is useful but does not replace the real Windows positive-control rerun.

## 10. Evidence ZIP byte/path regression

Verify:

- ZIP entries use `/` even on Windows;
- nested files are present where expected;
- manifest covers all intended evidence files;
- all manifest hashes/lengths recompute correctly;
- vendor binaries themselves are not copied merely because their metadata/hash was collected, unless the collector contract explicitly says otherwise;
- every generated JSON reparses successfully before manifest creation;
- the manifest is recomputed and verified for exact file set, length and SHA-256;
- the completed ZIP is reopened and checked for portable paths, duplicates, entry count, length and SHA-256;
- a created ZIP that fails any integrity gate is not reported as accepted evidence and the working directory is retained.

## 11. Current qualification state

### Completed/retained evidence

- real Ryzen 7 5700X non-NPU negative-control qualification;
- real Ryzen AI Z2 Extreme positive-control evidence for CPU/NPU/PCI revision and client 376 stack;
- later successful XRT evidence establishes `NPU Strix` and firmware version `1.1.2.64`;
- main research toolkit has reviewed/promoted only generalized facts from the private evidence.
- collector v1.3.0 PowerShell parser/static gate passed;
- collector v1.3.0 hardware-independent self-test passed (15/15), including JSON array shape, independent multiple candidates, driver-query failure fail-closed behavior, the synthetic Windows Server/custom-driver positive case and all integrity gates.

### Still required for collector v1.3.0 real-device qualification

This gate is `DeferredDependencyBlocked`, not an immediate test request. First
complete production NPU driver build-script redevelopment and review, then
separately authorize and complete Server driver build/application. Only when an
NPU-positive Server state exists, run the **current v1.3.0 source** once and
verify Sections 4, 4.2, 9 and 10.

Expected purpose of that single run:

- qualify complete Windows PnP enumeration and the compact selection-input schema;
- qualify Windows Server positive runtime-driver observation when that host is used;
- qualify stable `ConfigManagerErrorCode`, identity-set and host-class fields;
- qualify improved INF/model correlation;
- qualify exact reviewed-376 correlation only if the observed components happen to match;
- qualify current privacy metadata and all three Evidence integrity gates as one coherent v1.3.0 run.

Do not request a ceremonial Client rerun in addition to a successful Server
positive run. This gate qualifies the companion utility; it does not re-prove
the already accepted main-runner Client positive or Server no-NPU results.

## 12. Release acceptance for bundled collector

If the main toolkit describes collector v1.3.0 as fully real-device-qualified, require:

- [ ] collector AST/source preflight PASS;
- [ ] collector `-SelfTest` PASS;
- [ ] negative-control behavior retained;
- [ ] one current v1.3.0 NPU-positive run completed;
- [ ] Windows Server/custom/self-signed positive contract PASS when Server is the selected host;
- [ ] structured XRT separation PASS;
- [ ] INF/model correlation PASS;
- [ ] reviewed-376 exact component correlation is reported accurately where components match, without being required for a custom Server build;
- [ ] privacy metadata reviewed;
- [ ] JSON round-trip, recursive manifest/hash and ZIP reopen/hash/path verification PASS;
- [ ] no prohibited XRT/quicktest/installer execution;
- [ ] Evidence ZIP retained privately for audit.

## 13. Deferred single real-device gate

This is the only remaining collector 1.3.0 qualification run. It is not a
main-runner regression and does not require a second Client run. It is blocked
by production build-script redevelopment and is not currently schedulable.

Retain this command for later. Execute it only after the production build script
is redeveloped/reviewed and a built/self-signed NPU driver is separately
authorized and already applied to Windows Server:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass `
  -File .\Collect-AmdNpuHardwareIdentityEvidence.ps1 `
  -SkipXrtSmiProbe `
  -SkipQuicktestSnapshot
```

Windows PowerShell 5.1 is preferred when available; the collector contract
itself remains runtime-neutral within its supported Windows PowerShell range.
Review the exact-source hash, Server host classification, complete candidate
identity, healthy device/service/driver observations, JSON round trips,
manifest and reopened ZIP. Exact public-376 component correlation and XRT may be
recorded when present but are not PASS prerequisites for a custom Server build.

Stop after evidence collection. Do not run an installer, alter device state,
perform an inference workload or infer production support from this gate.

Until those prerequisites exist, keep the gate deferred and preserve the
static/synthetic qualification disclaimer. Do not ask the user to manufacture a
temporary Server-positive state solely for collector qualification.
