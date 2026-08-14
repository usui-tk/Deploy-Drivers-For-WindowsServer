# AMD Chipset Driver Research Toolkit 1.2.8-qt-dev — Windows Live Evidence Validation

Date: 2026-08-11

## Executive result

Three Windows evidence runs exposed two correctness defects and one Windows-only MSI parsing defect in 1.2.7. The 1.2.8 development patch corrects/hardens all three paths. Linux static/self-tests and deterministic replay pass; the MSI COM change remains **pending one Windows rerun** because Windows Installer COM is unavailable on Linux.

## Source runs

| Environment | PowerShell | 7-Zip | 1.2.7 result | Key observation |
|---|---|---|---|---|
| Windows 11 Pro build 26200 | 5.1.26100.8972 Desktop | 26.02 | Pass / exit 0 | raw OSArchitecture=`64 ビット`; Client manifest selection was falsely filtered by architecture |
| Windows Server 2025 Datacenter build 26100 | 7.6.3 Core | 26.01 | Pass / exit 0 | Selector emitted repeated `_Tables.Name` property errors; MSI status `ParseFailed` |
| Windows Server 2022 Datacenter build 20348 | 5.1.20348.5386 Desktop | absent | ReviewRequired / exit 2 | Extract failed correctly, but downstream stages continued and some reported PASS over empty data |

## Finding 1 — localized architecture correctness

1.2.7 only recognized ASCII-style architecture tokens such as `AMD64`, `x64`, `x86_64`, `64-bit`, and `64 bit` at the relevant selector filter. Japanese CIM returned `64 ビット`; therefore the Windows 11 host incorrectly accumulated `CompiledArchitectureNotMatched` results.

1.2.8 adds `ConvertTo-AmdNormalizedArchitecture` / `Get-AmdHostNormalizedArchitecture`, captures a runtime-normalized architecture during HostSurvey, and conservatively handles localized/fallback values. A self-test covers the Japanese value.

Replay result for 8.07.16.1035 on the captured Windows 11 host:

- `SelectedCandidate`: 6
- selected features: SMBUS, PCI, PSP, GPIO2, GPIO3, RYZENPPKG
- no architecture-mismatch exclusion

This matches the previously frozen 8.x positive fixture at the feature-set level. Server 2022 and Server 2025 replay remain negative, but now through the expected compiled Caption-classification exclusion.

## Finding 2 — stage dependency/stale inventory hardening

The Server 2022 run correctly reported the missing 7-Zip dependency and failed Extract. In 1.2.7, Inspect/Selector/HostMatch/Build could still execute and PASS against empty or pre-existing inventory. This weakens the meaning of a stage PASS.

1.2.8 adds a `BLOCKED` stage state and explicit dependencies. Data-derived assessment items are read only when their producer stage passed in the current run. Synthetic missing-7z regression now produces:

```text
Extract   FAIL
Inspect   BLOCKED
Selector  BLOCKED
Build     BLOCKED
Overall   ReviewRequired
```

HostSurvey remains independent and can still collect host evidence when extraction is unavailable.

## Finding 3 — Windows Installer COM table enumeration

Both Windows PowerShell 5.1 and PowerShell 7 evidence recorded MSI declarative analysis as `ParseFailed`; the PowerShell 7 transcript additionally surfaced repeated non-terminating errors stating that property `Name` was not found. The failure is in the read-only `_Tables` row projection, not in MSI installation (the toolkit never installs MSI packages).

1.2.8 no longer assumes direct `.Name` access. `Get-AmdMsiTableNamesFromRows` accepts a named `Name` property or, for a one-column row, the sole returned property. `Test-AmdMsiTableNameProjectionSelfTest` validates both shapes.

**Qualification boundary:** this repair is statically/self-test validated but cannot be declared Windows-COM-qualified until a rerun on Windows shows `ParsedReadOnly` or a specific table-level error instead of the old `.Name` failure.

## 2.x availability/topology update

The supplied Windows evidence demonstrates successful acquisition of 2.04.04.111 despite manual/browser retrieval difficulties:

- source URL recorded by acquisition: `https://drivers.amd.com/drivers/amd_software_2.04.04.111.zip`
- size: 52,428,763 bytes
- SHA-256: `d23a9cc4be06ab46c88918e523d11a96ca56b132f3b4646d2e8f9e17abf97185`
- validation: valid ZIP, not HTML
- acquisition status: Downloaded
- extraction on 7-Zip-capable hosts: ExtractionComplete
- INF: 24; parse failures: 0 in completed runs

Observed nested topology:

```text
amd_software_2.04.04.111.zip
└─ AMD_Chipset_Software.exe
   ├─ $WINDIR/Info.xml
   ├─ Qt_Dependancies/Setup.exe
   └─ Packages/AMD_Chipset_Drivers.exe
      └─ ISSetupStream type 3
         ├─ AMD_Chipset_Drivers.msi
         └─ ...
            └─ Data1.cab / aps_4042020011117_3.xml / INF payload
```

Static selector candidate:

- path: `Qt_Dependancies/Setup.exe`
- SHA-256: `24cd52cc5a1eff6e082b2408681e4e90d759ef3ddcc8fedd9077fb632cd8bd76`
- recovered strings include `/info.xml`, `/SETFILTERUSB`, `/SETRYZENPPKG`, `AMD SMBus Driver`, `readXmlFile`
- `Info.xml`: 26 products; Windows 7 and Windows 10 labels; no recovered Brand values; no Server-like products
- APS XML: one and byte-identical to preferred `Info.xml`
- `DevID.xml`: not recovered

This is sufficient to change 2.x from `HistoricalArtifactUnavailable` to **canonical acquisition and static topology observed**. It is not sufficient to claim an `AmdCompiledStaticProven` contract because the selector bytes themselves are deliberately absent from the shared evidence ZIP.

## 1.2.8 validation completed in this session

- PowerShell 7.6.4 AST: 0 errors
- `-Stages Test`: PASS
- compiled selector contract self-test: PASS
- host architecture normalization self-test: PASS
- MSI table-name projection self-test: PASS
- missing-7z dependency regression: expected FAIL/BLOCKED behavior PASS
- captured Windows 11 HostMatch replay: PASS and expected six 8.x selected features
- captured Server 2022 HostMatch replay: PASS with Server Caption exclusion
- captured Server 2025 HostMatch replay: PASS with Server Caption exclusion

## Remaining gate

Run 1.2.8 once on a Windows host with 7-Zip. The primary acceptance check is that MSI declarative analysis no longer emits the `.Name` error and reports meaningful table parsing status. No additional hardware fleet is required for this specific gate.
