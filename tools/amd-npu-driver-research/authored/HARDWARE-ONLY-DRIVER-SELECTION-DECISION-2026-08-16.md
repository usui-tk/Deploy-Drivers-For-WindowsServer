# AMD NPU Hardware-Only Driver Selection Decision

> **Current source note (corrected 2026-08-21):** the PnP/INF-only selection
> boundary remains valid. AMD's authoritative Ryzen AI Software 1.8.0
> installation page identifies `376` as production for the same five families.
> See `NPU-LIVE-PUBLICATION-DRIFT-2026-08-21.md` for the REV65 verification
> correction. Normal deployment gates still apply.

## Status

- Decision date: 2026-08-16
- Authority: user adjudication after Windows/Linux identity research and review of real Windows Client evidence
- Applies to: research-tool driver-track resolution
- Does not authorize: installation, deployment, INF conversion, certificate work, re-signing or Windows Server execution

## Decision

Windows driver-track selection does not require any of the following:

- CPU marketing SKU;
- CPUID family/model/stepping;
- CPU/NPU combination mapping;
- NPU marketing name or exact codename;
- firmware device revision;
- Linux AIE topology, BAR layout, row/column count or context count;
- XRT device label or firmware version.

The machine authority is `data/hardware-driver-selection.json`. The resolver uses:

1. the complete Windows HardwareID/CompatibleID set for one enumerated NPU device instance;
2. the reviewed INF model HardwareIDs;
3. the target Windows build and reviewed INF TargetOSVersion/build floor;
4. the project policy that 376 is the preferred production track.

`SUBSYS` and PCI `REV` are retained in evidence. They are not converted into
selection conditions unless a future reviewed INF actually contains such a
selector.

## Current deterministic decisions

| Observed condition | Research-tool decision |
|---|---|
| one NPU instance matches reviewed 376 INF model and build satisfies selector | `376` |
| explicitly completed enumeration contains no NPU instance | `NoNpuDriverRequired` |
| unknown/incomplete non-empty identity or selector-ineligible build | `ReviewRequired` |
| automatic selection or fallback to 280 | prohibited |

The 280 and 376 packages remain in the research corpus. 376 is the current
preferred production track. This preference is policy based on the current public
package direction and reviewed evidence; it is not a claim that AMD has published
mutually exclusive 280/376 hardware lanes. 280 remains available for package
evolution, regression, comparison and targeted research.

## Evidence supporting the boundary

- Reviewed 280 and 376 INFs both contain broad models for
  `PCI\VEN_1022&DEV_1502` and `PCI\VEN_1022&DEV_17F0`.
- Both reviewed INFs use `NTamd64.10.0...22000`; Server 2025 build 26100 is a
  static selector candidate, while Server 2016/2019/2022 are below the build floor.
- The reviewed Z2 Extreme Client host exposed
  `PCI\VEN_1022&DEV_17F0&SUBSYS_20CF1043&REV_10` and used an exact 376
  INF/ipustack/xrt-smi stack successfully.
- Linux `amdxdna` and the reviewed Windows 376 binary expose finer firmware and
  topology semantics, but those semantics occur below or beside INF selection and
  are not required to choose the Windows driver track.

## Disposition of earlier CPU/NPU mapping work

The authored Excel workbook, processor catalog, generated processor applicability
data and isolated rev34 742-row JSON candidate are preserved for research,
provenance and human audit. They are not promoted into runtime selection authority.
This preserves project history without making CPU identity a deployment prerequisite.

## Fail-closed and platform boundaries

- Resolver output always has `InstallationAuthorized=false`.
- Resolver output always has `WindowsServerRuntimeProof=false`.
- A Windows Client PASS does not authorize a Windows Server run.
- `ReviewRequired` is an expected safe result, not a failed collection.
- No 376 decision may silently enable 280 fallback.

## Implementation binding

- Reviewed authority: `data/hardware-driver-selection.json`
- Source schema: `schemas/source-data/hardware-driver-selection.source.schema.json`
- Per-device result schema: `schemas/hardware-selection-result.schema.json`
- Local aggregate schema: `schemas/local-hardware-selection.schema.json`
- Resolver: `Resolve-NpuHardwareDriverTrack`
- Local enumerator: `Get-NpuLocalWindowsPnpEvidence`
- Aggregate resolver: `Resolve-NpuEnumeratedHardwareSelection`
- Self-tests: `Test-NpuHardwareDriverSelectionLogic`, `Test-NpuLocalHardwareSelectionLogic`
- Operator switch: `-ResolveHardwareSelection`
- Normal identity input: automatic local Windows PnP enumeration
- Normal OS input: automatic local Windows build discovery
- Offline/test-only input: `-UseObservedNpuHardwareIdOverride -ObservedNpuHardwareId ...`

## 2026-08-17 implementation correction

The failed rev35 Client attempt proved that a manually supplied Z2 HardwareID is
not local hardware evidence and that an empty manual input cannot prove a no-NPU
host. Version 1.3.1-dev therefore makes local enumeration the normal path. Only a
completed local enumeration can produce `NoNpuDriverRequired`; unavailable
enumeration fails closed. The same failure exposed a clean-process Windows
PowerShell 5.1 `SignedCms` load-order dependency, corrected with the complete
.NET Framework `System.Security` assembly identity.
