# AMD Chipset Driver Research Toolkit

**Current toolkit version: 2.0.0 (Windows retest candidate; aggregate-schema/publication hardening)**


## 2.0.0 Windows retest hardening — aggregate JSON canonical shape

The first `2.0.0` Windows regeneration completed the research pipeline successfully, but independent schema validation found that the derived `public/inventory/amd-selector-static.json` aggregate still contained Windows PowerShell 5.1 collection serialization wrappers (`{ "value": [...], "Count": n }`) in fields whose public schema requires JSON arrays. The canonical 25 per-release Raw JSON files were correct and are not rewritten.

The `2.0.0` retest generator now:

- recursively canonicalizes PS5.1 collection wrappers **only while generating tool-derived aggregate indexes**;
- leaves `public/inventory/releases/**/amd-chipset-analysis-*.json` byte-faithful and untouched by that aggregate projection;
- rejects a public aggregate if a PS5.1 collection wrapper remains after canonicalization;
- performs an explicit selector-aggregate shape check before publication can be promoted;
- extends the PublicationContract self-test with nested wrapper data and preserved `/SETFILTERUSB` evidence; and
- declares this aggregate-only transformation in `publication-manifest.json`.

The first `2.0.0` dataset must therefore be regenerated once more on Windows. Generated JSON must not be repaired by hand.

## 1.3.3 Windows full-run validation and final-publication hardening

The user-provided Windows 11 / Windows PowerShell 5.1 full run of `1.3.1-publication-dev` completed all 10 stages with `OverallStatus=Pass` and exit code 0. The run acquired and extracted all 25 tracked releases, produced 643 INF package records, parsed all 25 recovered MSI databases as `ParsedReadOnly`, reported zero all-null MSI rows, and published a 65-file `public/**` surface with `publication-validation.json = Pass`. The public dataset preserves AMD selector/XML tokens without the withdrawn-v2 F-01 corruption and contains no detected host-root or CPU ProcessorId leakage.

No new analysis defect was found in that run. This checkpoint therefore focuses on release hardening before the final Windows run:

- canonical per-release Raw JSON is now written in compact JSON form **at Build generation time**, not rewritten after publication. `public/**` still copies those canonical files byte-for-byte, so source and published SHA-256 remain identical; only insignificant indentation whitespace is removed by the canonical generator;
- the 1.3.1 full public surface was about 527 MiB uncompressed because deep `ConvertTo-Json` indentation amplified otherwise identical Raw JSON. Compact canonical generation is expected to reduce the same 25-release dataset to roughly one tenth of that size without dropping any property or scalar value;
- large runtime-only aggregates such as `driver-packages.json` and `amd-chipset-driver-inventory.json` are also written compactly to reduce memory/string and disk pressure;
- `Get-AmdCollectionItems` adds a read-time compatibility layer for the Windows PowerShell 5.1 `{ "value": [...], "Count": n }` collection wrapper. Raw JSON is not modified. This closes a fresh-checkout Build failure observed when real 8.07.16.1035 public data was rehydrated;
- fresh-checkout reconstruction was retested with the real 8.07.16.1035 31-INF Raw JSON and now passes; the rebuilt per-release document is structurally identical to the 1.3.1 source after ignoring expected toolkit-version/timestamp metadata;
- publication manifest schema `1.1` makes the self-exclusion rule explicit through `ManifestEntryCount` and `PublicFileCountIncludingManifest`, and records manifested payload size plus largest-file metrics for repository-growth review.

The current `1.3.1` Windows run remains strong diagnostic evidence, but the final GitHub candidate must be generated once more with `1.3.3-publication-dev` because canonical JSON serialization and fresh-checkout rehydration logic changed. Generated JSON must not be hand-edited.


## 1.3.2 revised-script review checkpoint

This checkpoint applies the follow-up Claude review of the `1.3.1-publication-dev` script. Claude independently verified the F-01 generator correction against the exact selector/MSI/XML values that had been corrupted in the withdrawn v2.0.0 candidate: all 10 normalization cases passed and vendor tokens remained byte-faithful.

The remaining merge blocker was a new PSA2001 instance in `Finalize-AmdResearchEvidenceSession`, where the script-level `-SkipPublicExport` parameter was referenced without scope qualification. 1.3.2 changes that reference to `$script:SkipPublicExport`, matching the already-correct `$script:SkipHostAnalysis` / `$script:ObservedAmdDeviceIdLog` pattern.

The publication self-test is also independently callable after function-only dot-sourcing. If normal script bootstrap has not initialized toolkit root/version variables, the self-test creates temporary diagnostic defaults and removes them afterward. This is diagnostic hardening; normal stage execution is unchanged.

The public manifest transformation contract now explicitly declares the `external-artifact/<leaf>` representation used for the acquired installer in path-bearing canonical fields, the `work/extracted/<release>/...` / `evidence/extraction-logs/...` portable path families, and the fact that public Markdown receives LF/no-BOM normalization without publication-time annotation insertion.

The two Markdown files previously called out for UTF-8 BOM in the withdrawn v2.0.0 candidate are already LF/no-BOM in this development line and remain so. A fresh Windows full run with this generator remains required before renewed v2.0.0 candidacy.

## 1.3.1 publication hardening checkpoint

A Windows 11 / Windows PowerShell 5.1 full run of 1.3.0 completed the research pipeline and generated a complete 25-release public dataset (643 INF packages, 25/25 MSI `ParsedReadOnly`, zero all-null MSI rows, and zero F-01 `external-path/SET*` corruption), but the final result was `ReviewRequired` because the `PublicationContract` self-test failed.

Root cause: the self-test wrote a private Windows path to JSON, where backslashes are escaped. The 1.3.0 validator scanned serialized JSON text with regexes built from decoded filesystem paths, so the private-path test was not detected on Windows. This also meant the same validator could theoretically miss a private Windows path in repository-public JSON.

1.3.1 fixes the validator at the contract level: JSON is parsed first and privacy patterns are evaluated against decoded scalar strings. The self-test now includes an explicit `C:\Users\SensitiveUser\...` JSON case so Windows escaping is tested even on Linux. Publication also re-runs the publication-contract self-test immediately before promotion and refuses to replace the previous `public/**` baseline if that contract is unhealthy.

Repository-path provenance is hardened at the same time: public indexes/manifests serialize relative paths with `/` on every OS, and byte-copied/Markdown-normalized runtime artifacts record `SourceRelativePath` plus `SourceSha256`. No generated JSON is hand-edited.

The supplied 1.3.0 Windows `public/**` was independently checked during this repair: 25 per-release Raw JSON documents, 643 DriverPackages, MSI 25/25 `ParsedReadOnly`, 0 all-null rows, 0 `external-path/SET*|info.xml|DevID.xml` corruption, 977 raw `/SET*` tokens retained, and no test-host root/ProcessorId leakage found. A fresh 1.3.1 Windows full run is required to close this checkpoint.

## 1.3.0 publication development checkpoint

This development line is rebuilt directly from the accepted `1.2.11-qt-dev` source after the withdrawn v2.0.0 release candidate. It does **not** reuse hand-modified publication JSON from that candidate. The goal is to make repository publication itself a deterministic toolkit function.

Key changes:

- `public/**` is now the only generated output surface intended for unattended Git commits.
- `private/evidence/**` is the default host/runtime/debug evidence surface and is never auto-published.
- `inventory/**`, generated `reports/**`, and `work/**` are runtime staging only.
- canonical repository Raw JSON is `public/inventory/releases/<version>/amd-chipset-analysis-<version>.json`; it is copied byte-for-byte from the Build-stage canonical per-release document.
- `publication-validation.json` is a fail-closed privacy/portability/token-integrity gate.
- `publication-manifest.json` records every public file, SHA-256, generation mode, source path/hash when applicable, and `HandEdited=false`.
- publication staging is atomic: a failed validation preserves the previous public baseline.
- partial runs preserve unrelated validated public Raw JSON.
- a fresh checkout can reconstruct runtime `driver-packages.json` from public per-release Raw JSON instead of tracking a GitHub-oversized monolithic aggregate.
- generated public Markdown is normalized by the script to UTF-8 without BOM and LF line endings, with that transformation declared in the manifest.

### Claude F-01 generator correction

The former portable-value logic treated any string beginning with `/` as a filesystem path. That corrupted AMD selector and XML evidence such as `/SETFILTERUSB`, `/SETRYZENPPKG`, `/info.xml`, and `/DevID.xml` into `external-path/...` values in per-release Raw JSON.

1.3.0-publication-dev changes normalization to an explicit **path-bearing field allow-list**. Artifact-derived values are not rewritten merely because they resemble a path. The built-in Test stage proves that `/SETFILTERUSB`, `/info.xml`, and the MSI value `C:\` remain exact while genuine extraction paths are made portable.

Do not repair previously generated JSON by hand. A corrected Windows full run is required before v2.0.0 candidacy so that the Raw JSON, reports, evidence source, and publication manifest are generated in lock-step.

See `PUBLICATION-POLICY.md` and `TESTING.md`.


## 1.2.11 development checkpoint

A Windows 11 / Windows PowerShell 5.1 rerun of 1.2.10 completed all 10 stages with `OverallStatus=Pass` and closed the remaining release-quality gate. All 25 MSI databases report `ParsedReadOnly`, the final assessment correctly records `ParsedCount=25`, all self-tests are readiness-PASS, the Japanese `64 ビット` host architecture remains normalized to `x86_64`, and the 8.07.16.1035 host match retains six selected candidates with zero unknown AMD filters.

The rerun also confirms that the 1.2.10 row-pipeline repair is effective in real Windows COM output: 13,993 selected MSI table rows were recovered across the 25 releases with **zero all-null rows** and zero MSI analysis errors.

1.2.11 is a hardening-only checkpoint. MSI declarative results now carry an explicit `Quality` summary (`TableCount`, `TotalRowCount`, `AllNullRowCount`, `ErrorCount`). Final assessment independently treats any all-null row in an otherwise successful MSI parse as an evidence-quality review condition. The existing MSI assessment self-test now includes a deliberately contaminated successful parse and proves that it becomes `REVIEW`. No selector predicate, release inventory, INF semantic contract, or host-selection rule is changed.

See `reports/AMD-Chipset-Driver-Research-1.2.11-WINDOWS-FINAL-QUALIFICATION.md`.


## 1.2.10 development checkpoint

A Windows 11 / Windows PowerShell 5.1 rerun of 1.2.9 completed all 10 stages with overall `Pass` and proved the revised Windows Installer COM read path end-to-end: all 25 recovered MSI databases now report `MsiDeclarativeAnalysis.Status=ParsedReadOnly` with zero per-release MSI errors. The prior `FieldCount` failure is resolved.

The live evidence also exposed two post-parse robustness issues. First, final assessment counted only legacy status `Parsed`, so 25 successful `ParsedReadOnly` results were displayed as `parsed=0`. Second, every selected MSI table contained exactly two synthetic all-null rows because return values from COM `View.Execute()` and `View.Close()` were not explicitly suppressed and leaked into PowerShell function output. 1.2.10 recognizes `ParsedReadOnly` as successful parsing, reviews `ParsedWithErrors` / `MsiNotRecovered` / unknown or missing analysis states, and explicitly discards `Execute` / `Close` return values.

The environment Test stage is hardened further: all internal self-tests are now part of readiness and a failed self-test terminates Test instead of merely being printed. A new `MsiTableRowPipelineIsolationSelfTest` verifies that method-return sentinels cannot become MSI rows, while the FieldCount-independent self-test no longer intentionally emits a caught terminating error into the PowerShell transcript.

See `reports/AMD-Chipset-Driver-Research-1.2.10-WINDOWS-MSI-LIVE-VALIDATION.md`.


## 1.2.9 development checkpoint

A Windows 11 / Windows PowerShell 5.1 rerun of 1.2.8 completed all 10 stages with overall `Pass`, confirming the localized architecture fix (`64 ビット` -> `x86_64`), full 25-release acquisition/extraction/INF inspection, and the existing 8.x host-selector behavior. The rerun also proved that the previous Windows Installer COM repair was incomplete: all 25 recovered MSI databases reported `MsiDeclarativeAnalysis.Status=ParseFailed` because the PowerShell 5.1 COM adapter did not surface `Record.FieldCount`.

1.2.9 removes the `FieldCount` dependency. Column names are recovered from `View.ColumnInfo` by reading indexed `Record.StringData` fields sequentially, with an IDispatch/reflection fallback for COM-member access. `View.Fetch` receives the same defensive fallback. A new self-test reproduces a record that supports indexed `StringData` while exposing no `FieldCount` property.

Assessment is also hardened: if the Selector stage PASSes but any recovered MSI reports `ParseFailed`, `MsiDeclarativeInspection` is `REVIEW` and the final result becomes `ReviewRequired` instead of silently remaining `Pass`. This keeps MSI declarative analysis supplemental to selector research while preventing COM-analysis failures from being hidden by an otherwise successful Selector stage.

The MSI COM correction is statically/self-test qualified on Linux PowerShell 7.6.4 and requires one additional Windows rerun for true COM end-to-end confirmation.

See `reports/AMD-Chipset-Driver-Research-1.2.9-WINDOWS-RERUN-VALIDATION.md`.

## 1.2.8 development checkpoint

Three real Windows evidence runs (Windows 11 / Windows PowerShell 5.1, Windows Server 2025 / PowerShell 7.6.3, and Windows Server 2022 / Windows PowerShell 5.1 without 7-Zip) were used to harden the development line. The runs exposed a localized-architecture correctness bug, weak stage-dependency semantics after extraction failure, and a Windows Installer COM `_Tables` projection bug.

1.2.8 normalizes localized architecture values such as Japanese `64 ビット`, records a runtime-normalized architecture, introduces prerequisite-aware `BLOCKED` stages, prevents assessment from consuming producer inventories that did not PASS in the current run, and defensively projects Windows Installer table names instead of assuming every `_Tables` row has a `.Name` property. Architecture and dependency changes are replay/regression-qualified; the MSI COM repair needs one Windows rerun for end-to-end confirmation.

The Windows evidence also changes the 2.x availability boundary. All three runs acquired the canonical `amd_software_2.04.04.111.zip` (52,428,763 bytes, SHA-256 `d23a9cc4be06ab46c88918e523d11a96ca56b132f3b4646d2e8f9e17abf97185`) through the toolkit's AMD HTTP acquisition path. On the two hosts with 7-Zip, static extraction recovered 24 INF files, `Info.xml`, byte-identical APS XML, no `DevID.xml`, and selector candidate `Qt_Dependancies/Setup.exe` SHA-256 `24cd52cc5a1eff6e082b2408681e4e90d759ef3ddcc8fedd9077fb632cd8bd76`. Because the selector bytes are not bundled in the shared evidence, 2.x compiled predicates remain `Unresolved`; no 2.x exact compiled contract is added.

The 3.x-8.x exact-release/hash contracts from 1.2.7 are preserved. Releases 3.x-6.x remain the independently proven x86/Qt5 OS/XML contract set, while 7.x/8.x retain the x64/Qt6 exact-binary hardware contracts.

See `reports/AMD-Chipset-Driver-Research-1.2.8-WINDOWS-LIVE-VALIDATION.md`; the development preview ZIP also carries a curated `qualification/1.2.8-qt-dev/` bundle.


PowerShell research tooling for reconstructing AMD Ryzen Chipset Driver history, acquiring original AMD installer artifacts, statically extracting their nested packages, performing content-level INF semantic analysis, reverse-engineering AMD installer component-selection rules, and producing evidence-backed inventory data for both generic Windows Server applicability and the actual hardware of a Windows host.

The toolkit remains a **research and evidence layer**, not a deployment-policy engine. The 1.1.x development line adds a static analysis layer that simulates Microsoft INF selection rules for Windows Server 2016/2019/2022/2025 and separately evaluates an analytical `ProductType=1 -> ProductType=3` server projection. The resulting `NativeCandidate` / `ProjectionCandidate` states are **not runtime compatibility claims**: signing, binary ABI behavior, actual hardware matching, installation, reboot behavior and runtime stability still require host validation.

## Goals

This tool exists to make AMD chipset-driver research repeatable even if AMD changes its website, download links, installer format, or package layout.

The core goals are:

- reconstruct release history from multiple AMD sources instead of relying on a single history page;
- preserve source URLs, timestamps, SHA-256 values, raw release-note evidence, extraction logs and parser evidence;
- download original AMD artifacts without executing them;
- extract modern EXE and historical ZIP delivery formats on Windows or Linux;
- recover nested InstallShield payloads without running AMD setup programs;
- inspect the actual INF payload for `KmdfLibraryVersion` and `UmdfLibraryVersion`;
- preserve `[Manufacturer]`, TargetOSVersion decorations, referenced Models sections, device descriptions, install sections, hardware IDs and compatible IDs as structured INF topology;
- simulate the Microsoft Models-section selection rules for Windows Server 2016 / 2019 / 2022 / 2025;
- distinguish AMD-published applicability from the deployment project's analytical ProductType=3 projection;
- generate one canonical Raw JSON record per AMD installer version plus human-readable per-release and device/OS compatibility reports;
- preserve AMD selector evidence from `DevID.xml`, `Info.xml`, and read-only MSI database tables separately from Microsoft INF/PnP semantics;
- collect a read-only Windows host inventory and match actual Hardware IDs / Compatible IDs against analyzed INF Models entries;
- compare AMD selector emulation with optional real AMD installer observation logs without executing the AMD installer from the research toolkit;
- keep `MicrosoftDefined`, `AmdDeclarativeProven`, `AmdCompiledStaticProven`, `AmdStaticInferred`, `AmdDynamicObservedSingleHost`, `AmdDynamicObservedMultiHost`, and unresolved findings distinct;
- keep published metadata, embedded installer metadata and observed payload metadata separate;
- generate compact Evidence ZIP files suitable for repeated review with ChatGPT or another reviewer;
- remain usable from Windows PowerShell 5.1 and PowerShell 7.x;
- keep the PowerShell implementation aggregated into one `.ps1` file.

## Repository location and single-script policy

Canonical layout:

```text
Deploy-Drivers-For-WindowsServer/
└─ tools/
   └─ amd-chipset-driver-research/
      ├─ README.md
      ├─ SPEC.md
      ├─ THIRD-PARTY-NOTICES.md
      ├─ Invoke-AmdChipsetDriverResearch.ps1
      ├─ data/
      ├─ schemas/
      ├─ inventory/
      ├─ evidence/
      ├─ reports/
      └─ work/
```

The implementation intentionally uses **one PowerShell script**. Discovery, HTTP acquisition, extraction, InstallShield decoding, INF parsing, evidence collection, logging and inventory generation are internal functions of `Invoke-AmdChipsetDriverResearch.ps1`.

Future tools should follow the same repository convention when practical:

```text
tools/
├─ amd-chipset-driver-research/
├─ amd-graphics-driver-research/
└─ ...
```

## Runtime support

Supported execution environments:

- Windows PowerShell 5.1 on Windows
- PowerShell 7.x on Windows
- PowerShell 7.x on Linux

The script avoids PowerShell-7-only syntax in the shared implementation.

Encoding conventions:

- `.ps1`: UTF-8 with BOM + CRLF
- Markdown / canonical JSON: UTF-8 without BOM
- ZIP entry paths: normalized to `/` so Evidence ZIP files created on Windows can be consumed cleanly by Linux ZIP tools

## Safety model

The toolkit is designed for static research.

- Downloaded AMD EXEs are **never executed**.
- MSI packages are **never installed**. On Windows, recovered top-level MSI databases may be opened read-only through Windows Installer COM to enumerate declarative tables such as `Feature`, `Condition`, `LaunchCondition`, `CustomAction`, and sequences.
- INF packages are **never installed**.
- `pnputil`, driver-store modification, catalog re-signing and certificate installation are outside scope. Host analysis uses read-only CIM/PnP property queries only.
- Outer containers are processed with 7-Zip.
- AMD InstallShield `ISSetupStream` payloads are decoded by the in-script static decoder.
- Recovered MSI/CAB/ZIP/7z containers are recursively inspected to a bounded depth.
- AMD installer binaries are excluded from the Evidence ZIP by default.

## Quick start

### Default: full research

No `-Stages` argument means the full workflow:

```powershell
cd .\tools\amd-chipset-driver-research
.\Invoke-AmdChipsetDriverResearch.ps1
```

Equivalent explicit form:

```powershell
.\Invoke-AmdChipsetDriverResearch.ps1 -Stages All
```

Environment check only:

```powershell
.\Invoke-AmdChipsetDriverResearch.ps1 -Stages Test
```

Metadata-only research:

```powershell
.\Invoke-AmdChipsetDriverResearch.ps1 `
    -Stages Discover,Metadata,Build
```

Specific release:

```powershell
.\Invoke-AmdChipsetDriverResearch.ps1 `
    -ReleaseVersion 8.07.16.1035
```

The explicit stage switch remains useful for troubleshooting:

```powershell
.\Invoke-AmdChipsetDriverResearch.ps1 `
    -Stages Acquire,Extract,Inspect,Build `
    -ReleaseVersion 7.11.26.2142
```

From Bash / POSIX shells, comma-separated stage values are accepted:

```bash
pwsh -File ./Invoke-AmdChipsetDriverResearch.ps1 -Stages Extract,Inspect,Build
```

## Host analysis and AMD-selector qualification

On Windows, the default full run includes read-only `HostSurvey` and `HostMatch` stages. To perform static repository research only:

```powershell
.\Invoke-AmdChipsetDriverResearch.ps1 -SkipHostAnalysis
```

Host analysis does **not** execute the AMD installer, stage a driver, install an INF, or modify the registry. It inventories the current OS/CPU/PnP devices and compares them with the already-extracted AMD payload.

Host inventory is machine-specific evidence and can contain PnP instance identifiers and other configuration details. Runtime `inventory/host/` and per-run host reports are ignored by Git and are intended for local/Evidence review. Review/redact them before sharing outside the intended audit workflow.

For reverse-engineering qualification, previously captured AMD installer logs can be replayed without executing AMD software:

```powershell
.\Invoke-AmdChipsetDriverResearch.ps1 `
    -Stages Selector,HostSurvey,HostMatch `
    -ObservedAmdDeviceIdLog 'C:\AMD\Chipset_Software\Logs\Device_ID.log' `
    -ObservedAmdMsiLog 'C:\AMD\Chipset_Software\Logs\AMD_Chipset_Software_Install.log'
```

The MSI log can supply the observed installer version. If only `Device_ID.log` is available, use `-ObservedAmdReleaseVersion <version>` so a captured selector result is never compared against the wrong AMD release.

Observed `Device_ID.log` parsing distinguishes three different final-list states:

- `ObservedNonEmpty` — AMD wrote a non-empty supported-driver list;
- `ObservedEmpty` — AMD explicitly wrote `Writing supported drivers to registry:` with no components;
- `NotObserved` — no final-list line was captured.

This distinction is essential for Windows Server negative qualification. An empty observed final list is positive evidence that AMD completed selector processing and selected zero supported components; it must not be confused with an incomplete/missing log. Candidates that disappear from that observed final list without an explicit `Hence removing` line are retained as `UnknownAmdFilterSuspected` rather than explained by invention.

The MSI observation parser also classifies the primary top-level transaction. `ACTION=ADMIN` is recorded as `AdministrativeExtraction`: MSI Feature `Request: Local` in that mode means payload extraction and **must not** be interpreted as AMD selecting those features for installation.

For 8.07.16.1035, the earlier Server-side multi-host observation has now been connected to the exact recovered Qt selector binary. The SHA-256-scoped `Qt_Dependencies/Setup.exe` initializes an internal OS-family enum to `-1`, queries `Win32_OperatingSystem` for `BuildNumber`, `Caption`, and `Version`, and changes the enum only when `Caption` contains `Windows 7`, `Windows 10`, or `Windows 11` (case-insensitive). The Client `Info.xml` filtering branch maps enum `0/1/2` to Windows 7/10/11 XML labels; any other enum contributes no product. Consequently, captions such as `Microsoft Windows Server 2022 Datacenter` and `Microsoft Windows Server 2025 Datacenter` remain enum `-1`, which explains the observed empty XML/product list without relying on a guessed `ProductType==3` predicate. This compiled contract is restricted to the exact Setup.exe SHA-256 and is not generalized to other AMD releases.

Normal end users do not need the observed-log options. They exist for qualification and reverse engineering.

## Stages

### Test

Records execution-environment evidence:

- platform family;
- OS and process architecture;
- PowerShell version and edition;
- 7-Zip path/command;
- Linux package-manager evidence when available;
- metadata-research readiness;
- full static-extraction readiness.

Output:

```text
inventory/environment.json
```

### Discover

Combines:

1. curated seed releases;
2. AMD sitemap discovery;
3. operator-provided release-note URLs.

AMD release-note URL is treated as provenance, not release identity. The release identity is the four-part chipset version.

The parser handles AMD URLs that contain more than one version token. For example AMD currently publishes the 7.02.13.148 page under a path containing both `6-10-17-152` and `7-02-13-148`; the leaf-side/final version token is used.

Multiple URLs for the same release version are normalized to one release record, with alternate URLs retained in `DiscoveryDiagnostics`.

Output:

```text
inventory/releases.json
```

### Metadata

For every discovered release, records:

- release-note URL;
- article number/title;
- retrieval timestamp;
- captured HTML SHA-256;
- candidate artifact URLs;
- parser/fetch diagnostics.

The candidate resolver uses both page links and known AMD historical naming patterns because old release-note pages may no longer expose a usable download link.

Output:

```text
inventory/release-metadata.json
evidence/release-notes/
```

### Acquire

Downloads the AMD artifact without executing it.

The implementation uses browser-like AMD request headers and verifies that the response is an actual binary artifact rather than AMD's `Download Not Complete` HTML page.

Observed delivery formats include:

- modern/normal EXE delivery;
- historical ZIP delivery containing an AMD outer installer EXE.

Output:

```text
inventory/acquisition.json
private/evidence/installers/
```

### Extract

Static extraction pipeline:

```text
AMD artifact
   │
   ├─ EXE (NSIS outer container)
   │
   └─ historical ZIP
          │
          └─ AMD outer EXE
                 │
                 ▼
        AMD_Chipset_Drivers.exe
                 │
                 │ InstallShield ISSetupStream
                 ▼
        AMD_Chipset_Drivers.msi
                 │
                 ▼
              Data1.cab
                 │
                 ▼
          INF / SYS / CAT / MSI
```

7-Zip handles normal archive/container layers. The single PowerShell script statically decodes the observed InstallShield `ISSetupStream` layer and feeds recovered containers back into recursive extraction.

`ExtractionComplete` requires INF discovery. Successfully opening only the outer archive with zero INF files is not considered a complete extraction.

Outputs:

```text
work/extracted/
inventory/extraction.json
evidence/extraction-logs/
```

### Inspect

Inspects embedded AMD metadata and every discovered INF.

INF evidence includes:

- INF path and SHA-256;
- `Provider`, `Class`, `ClassGuid`;
- `DriverVer`, driver date/version;
- `CatalogFile`;
- hardware IDs;
- referenced service binaries and hashes where resolvable;
- all `KmdfLibraryVersion` directives;
- all `UmdfLibraryVersion` directives;
- directive line number and raw source line.

No WDF version is inferred when the INF does not declare one.

#### INF semantic topology and Windows Server analysis (1.1.0)

`Inspect` now preserves content-level INF structure instead of reducing every INF to a flat HWID list. For every INF it records:

- every `[Manufacturer]` entry and its source line;
- the manufacturer label after `[Strings]` resolution;
- each referenced TargetOSVersion decoration, including architecture, major/minor version, ProductType, SuiteMask and minimum BuildNumber;
- only the Models sections reachable from `[Manufacturer]` (DDInstall/`.Wdf` sections that merely share a name prefix are not misclassified as Models);
- device description, DDInstall section, primary HWID and compatible IDs for every Models entry;
- raw decoration strings and evidence line numbers so parser logic can be re-evaluated later.

For each INF the tool evaluates four static host profiles:

| Profile | Build | ProductType | KMDF reference | UMDF reference |
|---|---:|---:|---|---|
| Windows Server 2016 | 14393 | 3 | documented 1.19 | documented 2.19 |
| Windows Server 2019 | 17763 | 3 | documented/observed 1.27 | documented 2.27 |
| Windows Server 2022 | 20348 | 3 | documented 1.33 | documented 2.33 |
| Windows Server 2025 | 26100 | 3 | documented 1.33; observed 1.35 reference | documented 2.33 |

Two evaluations are kept separate:

1. **As Published** — the original AMD INF is evaluated exactly as shipped.
2. **Server Projection** — only an explicit `ProductType=1` TargetOSVersion is analytically treated as ProductType 3. The source INF is not modified. Decorations with an empty ProductType already include Server and are not treated as patch requirements.

The selector follows Microsoft's documented rules: BuildNumber is a **minimum** build when major/minor match; the closest applicable Models section is selected per Manufacturer line; a selected empty Models section is an explicit exclusion. SuiteMask-restricted entries remain `SuiteDependent` when edition/suite information is not part of the generic Server profile.

The static status vocabulary deliberately avoids `Compatible=true`:

- `NativeCandidate` — the unmodified INF selects one or more Server-relevant Models entries.
- `ProjectionCandidate` — no native model is selected, but ProductType=1 -> 3 projection selects one or more models.
- `NotApplicable` — no current Server profile selection exists.
- `ReviewRequired` — suite/section ambiguity prevents a deterministic static answer.
- `WdfRequirementReview` — an INF-wide WDF requirement exceeds the profile reference.

WDF comparison in 1.1.0 is intentionally **INF-wide conservative**. Per-DDInstall WDF scoping is a planned Graphics/Chipset sync topic before this line is finalized.

Embedded metadata output:

```text
inventory/embedded-installer-metadata.json
```

Driver-package output:

```text
inventory/driver-packages.json
```

### Selector

Builds a release-static AMD component-selection model from evidence embedded in the installer.

Current evidence sources:

- `DevID.xml`: AMD `/SET...` property to device-token mapping;
- `Info.xml`: component name, installer name, target client OS label and component version;
- recovered `AMD_Chipset_Drivers.msi`: on Windows only, opened **read-only** to inventory declarative MSI tables and custom-action metadata.

Output:

```text
inventory/amd-selector-static.json
```

A Linux run still records the XML selector model. MSI table analysis is marked `WindowsInstallerComUnavailableOnPlatform` rather than treated as a false failure.

### HostSurvey

Windows-only live mode collects a read-only host inventory:

- OS caption/version/build/ProductType/architecture;
- CPU name and Family/Model/Stepping where available;
- PnP instance IDs;
- Hardware IDs and Compatible IDs, preferring `Get-PnpDeviceProperty` when available and retaining CIM fallback behavior;
- current signed-driver metadata;
- current `MatchingDeviceId` when exposed by the PnP property API;
- on-disk `Wdf01000.sys` FileVersion as a controlled host-observation heuristic.

Outputs:

```text
inventory/host/host-inventory.json
```

When `-ObservedAmdDeviceIdLog` is supplied on Linux, a qualification-only host inventory is reconstructed from the observed log so the emulator can be regression-tested without pretending Linux has a live Windows PnP stack.

Optional observation outputs:

```text
inventory/host/amd-selector-observation.json
inventory/host/amd-msi-observation.json
```

### HostMatch

Runs two independent analyses and then compares them:

1. **Windows/PnP view** — actual host identifiers are matched against the INF Models section selected for the actual host OS profile.
2. **AMD selector view** — host device tokens are matched to AMD `DevID.xml`, filtered against embedded component metadata, and supplemented only by narrowly scoped observed rules that are explicitly labeled as empirical.

Output:

```text
inventory/host/amd-chipset-host-analysis.json
reports/amd-chipset-host-analysis.md
```

Decision vocabulary includes:

- `EmulationConfirmed`
- `ObservedFilterExplained`
- `ObservedFilterExplainedByStaticInference`
- `ObservedSelectionNotEmulated`
- `UnknownAmdFilterSuspected`

These states describe evidence agreement, not runtime compatibility.

### Build

Builds canonical and human-readable views:

```text
inventory/amd-chipset-driver-inventory.json
inventory/amd-chipset-driver-inventory.csv
reports/amd-chipset-driver-history.md
```

#### Per-release canonical analysis and reports (1.1.0)

`Build` now creates an installer-version 1:1 analysis record under:

```text
inventory/releases/<version>/amd-chipset-analysis-<version>.json
```

This Raw JSON is the canonical historical record intended for later GitHub baseline commits. It contains the release/artifact identity, extraction evidence, embedded AMD metadata, complete per-INF topology, WDF declarations, four Server profile analyses and summary counts. Raw evidence and interpreted fields coexist; an interpretation change therefore does not require silently rewriting the original decoration/HWID evidence.

Per-release canonical JSON is repository-portable: machine-local absolute paths are converted to logical paths and full extractor console logs remain in the run Evidence ZIP rather than being duplicated into Git-tracked release records.

Human-readable derived views are generated separately:

```text
reports/releases/amd-chipset-<version>.md
inventory/amd-chipset-windows-server-compatibility.csv
reports/amd-chipset-windows-server-compatibility.md
```

Each per-release Markdown report contains both a Server-version summary and a concrete **device name + HWID + DDInstall + WS2016/2019/2022/2025** table. Server reports suppress irrelevant x86-only duplicate Models rows, while the Raw JSON preserves the full topology.

**JSON is the source of truth. Markdown and CSV are generated views.**

## Device identifier semantics

The INF `Models` field traditionally called `hw-id` is preserved verbatim, but the toolkit does not assume that every value is a PCI-style bus hardware ID. The semantic parser classifies the identifier and records the classification in per-release Raw JSON. Examples include:

- `PCI\VEN_...`, `ACPI\...`, `USB\...`: enumerator-specific PnP hardware IDs.
- `ROOT\...`: root-enumerated PnP hardware IDs.
- `{GUID}\component`: device-class-specific identifiers used by some INFs.
- bare identifiers in `NetService` / `NetTrans` / `NetClient` packages: network software component IDs rather than bus hardware IDs.

Reports therefore use the neutral column name **Device identifier** plus **Identifier type**. The toolkit never fabricates a PCI/ACPI ID when the source INF declares a root, class-specific, or software-component identifier. The original source string remains canonical evidence.

## Evidence and iterative troubleshooting

Every invocation creates a run-scoped evidence session before stage execution.

Default layout:

```text
private/evidence/runs/
├─ AmdChipsetDriverResearchEvidence_<timestamp>_<platform>/
└─ AmdChipsetDriverResearchEvidence_<timestamp>_<platform>.zip
```

The Evidence ZIP contains compact review material:

```text
assessment.json
stage-results.json
run-context.json
run-summary.json
run-summary.txt
external-artifacts.json
evidence-manifest.json
archive-capability.json
logs/console-transcript.txt
errors/
snapshot/tool/
snapshot/inventory/
snapshot/reports/
snapshot/release-notes/
snapshot/extraction-logs/
```

The large `work/extracted` tree and AMD installer binaries are excluded by default.

Useful switches:

```powershell
# Label the review bundle.
.\Invoke-AmdChipsetDriverResearch.ps1 -EvidenceLabel 'server2019-check'

# Choose another evidence root.
.\Invoke-AmdChipsetDriverResearch.ps1 `
    -EvidenceOutputRoot 'D:\Evidence\AMD'

# Keep loose evidence only.
.\Invoke-AmdChipsetDriverResearch.ps1 -SkipEvidenceArchive

# Explicitly include downloaded AMD binaries.
.\Invoke-AmdChipsetDriverResearch.ps1 -IncludeInstallersInEvidence
```

Outcome contract:

- exit `0` = `Pass`
- exit `2` = `ReviewRequired`
- exit `1` = fatal top-level failure

A stage failure does not normally prevent final evidence packaging. If ZIP creation fails, the loose evidence directory is retained.

## Operator-facing logging

The console uses the same general operational style as the repository deployment scripts:

```text
[HH:mm:ss] [+elapsed] [*] progress
[HH:mm:ss] [+elapsed] [+] success
[HH:mm:ss] [+elapsed] [!] warning/review item
[HH:mm:ss] [+elapsed] [X] failure
[HH:mm:ss] [+elapsed] [~] expected fallback / informational skip
```

Long stages show `[current/total]`, release version, per-item outcome and elapsed time.

Each stage has a start/end banner, and finalization prints total elapsed time plus a per-stage timing table.

A representative Windows PowerShell 5.1 full run on 2026-08-09 took about 4 minutes 30 seconds, with most time spent in `Acquire` and `Extract`.

## Research findings from real AMD installers

The following findings were derived from real AMD artifacts and Evidence runs, not from filename guesses.

### 1. AMD chipset software is a bundle of independent drivers

The chipset installer is not one driver with one KMDF requirement. It contains many independent packages such as PCI, I2C, GPIO, PSP, SMBus, SFH, MicroPEP, USB4 CM, PMF, 3D V-Cache and other components.

Therefore the meaningful research unit is:

```text
AMD chipset installer release
    -> contained driver package / INF
        -> hardware/OS applicability
        -> declared WDF requirement
```

An installer-wide "KMDF version" is only an envelope over the contained packages and must not be interpreted as a requirement that applies to every target machine.

### 2. Historical delivery format changed, but static Linux analysis remains possible

Observed delivery formats:

- 2.04.04.111: ZIP wrapper
- 3.08.17.735: ZIP wrapper
- 3.09.01.140: ZIP wrapper
- 3.10.08.506 and later validated releases: EXE delivery

The historical ZIPs contain another AMD outer installer EXE. The tool recursively processes that EXE without executing it.

### 3. The inner installer architecture is stable across a long period

Validated real installers from 2.04 through 8.07 use an outer AMD package that ultimately exposes an InstallShield `ISSetupStream` payload.

Observed stream generations:

- 2.04 through 6.10: type 3
- 7.02 through 8.07: type 4

The pre-GA v0.4.3 Windows PowerShell 5.1 acceptance run, which is the functional acceptance baseline promoted to 1.0.0, directly confirmed 7.02.13.148 as `ISSetupStream` type 4 and recovered its MSI successfully.

This means Linux does not require Wine or Windows Installer execution for the validated generations.

### 4. Real INF WDF observations

The pre-GA v0.4.3 Windows PowerShell 5.1 acceptance run, which is the functional acceptance baseline promoted to 1.0.0, discovered **25 unique releases**, acquired **25/25 artifacts**, reached `ExtractionComplete` for **25/25 releases**, and inspected **643 INF files** with zero INF parse failures. The run recorded **158 KMDF declarations** and **25 UMDF declarations**.

| Release | AMD artifact | ISSetupStream | INF | KMDF versions declared by INF | UMDF versions declared by INF |
|---|---|---:|---:|---|---|
| 2.04.04.111 | ZIP | 3 | 24 | 1.11, 1.15 | 2.15.0 |
| 3.08.17.735 | ZIP | 3 | 16 | 1.11, 1.15 | 2.15.0 |
| 3.09.01.140 | ZIP | 3 | 16 | 1.11, 1.15 | 2.15.0 |
| 3.10.08.506 | EXE | 3 | 16 | 1.11, 1.15 | 2.15.0 |
| 4.03.03.431 | EXE | 3 | 16 | 1.11, 1.15 | 2.15.0 |
| 4.06.10.651 | EXE | 3 | 24 | 1.11, 1.15, 1.19 | 2.15.0 |
| 4.08.09.2337 | EXE | 3 | 24 | 1.11, 1.15, 1.19 | 2.15.0 |
| 4.09.23.507 | EXE | 3 | 24 | 1.11, 1.15, 1.19 | 2.15.0 |
| 4.11.15.342 | EXE | 3 | 24 | 1.11, 1.15, 1.19 | 2.15.0 |
| 5.02.19.2221 | EXE | 3 | 25 | 1.11, 1.15, 1.19 | 2.15.0 |
| 5.05.16.529 | EXE | 3 | 26 | 1.11, 1.15, 1.19 | 2.15.0 |
| 5.08.02.027 | EXE | 3 | 27 | 1.11, 1.15, 1.19 | 2.15.0 |
| 6.01.25.342 | EXE | 3 | 27 | 1.11, 1.15, 1.19 | 2.15.0 |
| 6.02.07.2300 | EXE | 3 | 27 | 1.11, 1.15, 1.19 | 2.15.0 |
| 6.05.28.016 | EXE | 3 | 28 | 1.11, 1.15, 1.19 | 2.15.0 |
| 6.07.22.037 | EXE | 3 | 28 | 1.11, 1.13, 1.15, 1.19 | 2.15.0 |
| 6.10.17.152 | EXE | 3 | 28 | 1.11, 1.13, 1.15, 1.19 | 2.15.0 |
| 7.02.13.148 | EXE | 4 | 30 | 1.11, 1.13, 1.15, 1.19 | 2.15.0 |
| 7.04.09.545 | EXE | 4 | 30 | 1.11, 1.13, 1.15, 1.19 | 2.15.0 |
| 7.06.02.123 | EXE | 4 | 30 | 1.11, 1.13, 1.15, 1.19 | 2.15.0 |
| 7.11.26.2142 | EXE | 4 | 31 | 1.13, 1.15, 1.19 | 2.15.0 |
| 8.01.20.513 | EXE | 4 | 29 | 1.13, 1.15, 1.19 | 2.15.0 |
| 8.02.18.557 | EXE | 4 | 31 | 1.13, 1.15, 1.19 | 2.15.0 |
| 8.05.04.516 | EXE | 4 | 31 | 1.13, 1.15, 1.19 | 2.15.0 |
| 8.07.16.1035 | EXE | 4 | 31 | 1.13, 1.15, 1.19 | 2.15.0 |

Important interpretation:

- no validated release in this 2.04 through 8.07 dataset declares KMDF newer than **1.19**;
- UMDF declarations observed in every validated release are **2.15.0**;
- 1.19 first appears in this validated history at 4.06.10.651, including `amdusb4cm.inf`;
- 1.13 first appears in the collected sequence at 6.07.22.037;
- 7.02.13.148 increases the number of KMDF-declaring INF packages to 8, but the highest declared KMDF remains 1.19;
- 7.11 and 8.x no longer contain the 1.11 declaration observed in earlier generations;
- PSP changed across generations and has been observed with KMDF 1.11 and later 1.13;
- SFH KMDF packages remain examples of KMDF 1.15 declarations;
- these are **per-INF declarations**, not blanket installer requirements.

This result does **not** prove that every component in a modern AMD installer is compatible with every old Windows release. WDF version is only one compatibility dimension. OS decorations, supported hardware IDs, component-selection rules, binary behavior, signing and other dependencies must also be evaluated by the deployment project.

### 5. The original "newest installer implies newest KMDF" hypothesis is too simple

The initial investigation was motivated by concern that newer AMD chipset installers might unconditionally require newer KMDF generations.

The observed INF history does not support that as a simple installer-version rule. Modern validated 7.x/8.x packages still contain WDF declarations such as KMDF 1.13, 1.15 and 1.19 rather than a monotonically increasing installer-wide requirement.

The deployment project should therefore avoid rules such as:

```text
AMD chipset installer 8.x -> KMDF 1.33 required
```

unless a specific package/INF/binary provides that evidence.

Instead, compatibility resolution should eventually use the actual package selected for the target hardware.

### 6. Published release notes and embedded installer metadata can differ

AMD's public release-note table and the installer's embedded `Qt_Dependencies/Info.xml` are distinct evidence layers.

For 8.07.16.1035, observed examples include:

- published PPM Provisioning File Driver: 8.0.0.62; embedded metadata: 8.0.0.64;
- published Windows 10 AMS Mailbox Driver: 5.1.0.1480; embedded metadata: 5.0.0.1075;
- published Windows 11 PMF-7040 Series Driver: 25.2.7.0; embedded metadata: 26.2.8.0;
- some embedded Windows 11 component records exist even where the public table says `Not Applicable`.

Therefore the toolkit keeps these layers separate:

```text
PublishedMetadata
EmbeddedInstallerMetadata
PayloadObservedMetadata
```

No layer silently overwrites another. Actual INF/SYS evidence remains independently inspectable.

### 7. AMD historical links can remain recoverable even when they are not obvious on the page

The Windows PowerShell 5.1 acceptance run automatically acquired 2.04.04.111 from:

```text
https://drivers.amd.com/drivers/amd_software_2.04.04.111.zip
```

even though the operator could not locate a working manual download link during earlier research.

This is why the acquisition logic combines captured page links with version-scoped historical filename synthesis and validates the resulting payload before accepting it.

### 8. AMD release-note URLs are not guaranteed to have a clean one-version path

AMD currently exposes 7.02.13.148 under:

```text
https://www.amd.com/en/resources/support-articles/release-notes/
RN-RYZEN-CHIPSET-6-10-17-152/RN-RYZEN-CHIPSET-7-02-13-148.html
```

A parser that takes the first version token incorrectly identifies this as 6.10.17.152.

1.0.0 uses the final/leaf-side four-part version token and normalizes alternate URLs to one record per release identity.

### 9. Content-level INF analysis produces materially different Server results

The 1.1.0 development parser was regression-tested against six real installers that are locally available for repeatable testing: 3.10.08.506, 4.08.09.2337, 5.08.02.027, 6.10.17.152, 7.11.26.2142 and 8.07.16.1035. The run parsed **157 INF files with zero parse failures** and preserved the Manufacturer -> TargetOSVersion -> Models -> device/HWID relationships instead of treating every HWID in the file as universally applicable.

The resulting INF-level Server summary demonstrates why installer-level compatibility is too coarse:

| Release | WS2016 | WS2019 | WS2022 | WS2025 |
|---|---|---|---|---|
| 3.10.08.506 | 16 Native | 16 Native | 16 Native | 16 Native |
| 4.08.09.2337 | 24 Native | 24 Native | 24 Native | 24 Native |
| 5.08.02.027 | 26 Native / 1 Not applicable | 26 Native / 1 Not applicable | 27 Native | 27 Native |
| 6.10.17.152 | 24 Native / 4 Not applicable | 26 Native / 2 Not applicable | 25 Native / 3 Not applicable | 26 Native / 2 Not applicable |
| 7.11.26.2142 | 24 Native / 7 Not applicable | 27 Native / 1 Projection / 3 Not applicable | 27 Native / 1 Projection / 3 Not applicable | 27 Native / 1 Projection / 3 Not applicable |
| 8.07.16.1035 | 17 Native / 14 Not applicable | 23 Native / 1 Projection / 7 Not applicable | 25 Native / 1 Projection / 5 Not applicable | 27 Native / 1 Projection / 3 Not applicable |

These counts are **INF-package static assessments**, not runtime compatibility counts. A single INF can contain many device models.

Concrete 8.07.16.1035 examples illustrate the added value:

- `amd3dvcache.inf` requires minimum build 18362 for its selected amd64 Models section, so Server 2016/2019 are `NotApplicableByBuild` while Server 2022/2025 are native static candidates.
- `amdappcompat.inf` excludes Server 2016 by build but is natively selectable on Server 2019/2022/2025.
- `amdgpio3.inf` is not selectable by the generic Server 2016/2019/2022 profiles and becomes a native candidate on Server 2025.
- `amdhsmpdriver.inf` becomes a native candidate on Server 2022/2025 but not the older profiles.
- `amdmicropep.inf` is not natively selected for the tested Server profiles; for Server 2019/2022/2025, the analytical ProductType=1 -> 3 projection reaches the relevant Models entries, so it is reported as `ProjectionCandidate` rather than `NativeCandidate`.
- explicit empty Models sections are preserved as exclusions. For example, the regression set contains cases where Windows selection reaches an intentionally empty decorated Models section; these are not merged with a broader fallback section.

This analysis also reinforces an important boundary: WDF requirements and OS selection are separate dimensions. A package can satisfy the host WDF reference while still being excluded by TargetOSVersion/BuildNumber/ProductType, and vice versa.

The current WDF comparison deliberately uses the maximum WDF declaration found anywhere in the INF. This is conservative and can overstate the requirement when different DDInstall paths carry different WDF versions. A DDInstall-scoped WDF association is therefore an explicit **Chipset/Graphics sync topic before 1.1.0 finalization**; see `INF-ANALYSIS-SYNC.md`.

## Validated environments

### Windows

Validated with:

- Windows 11 build 26200
- Windows PowerShell 5.1.26100.8972
- 7-Zip 26.02

The 2026-08-09 pre-GA acceptance run (v0.4.3 code, promoted functionally unchanged to 1.0.0 except version metadata/document packaging) completed:

```text
StageExecution          PASS
ResearchEnvironment     PASS
Acquisition             PASS
ExtractionCompleteness  PASS
InfInspection           PASS
Overall                 Pass
Exit code               0
```

Acceptance-run totals:

```text
Unique releases         : 25
Artifacts acquired      : 25 / 25
ExtractionComplete      : 25 / 25
INF files inspected     : 643
KMDF declarations       : 158
UMDF declarations       : 25
INF parse failures      : 0
Total runtime           : 4m43.5s
```

Stage timings from that run:

```text
Test       0.17s
Discover   0.77s
Metadata   3.36s
Acquire    2m38.8s
Extract    1m29.4s
Inspect    28.55s
Build      1.24s
```

The corrected discovery logic independently identified and processed 7.02.13.148 rather than duplicating 6.10.17.152. Its installer was acquired from AMD, statically extracted, identified as `ISSetupStream` type 4, and produced 30 INF records.

The generated Evidence ZIP was also verified independently: all **588 manifest-tracked files** matched their recorded SHA-256 values with zero missing or mismatched entries.

### Linux

Validated with:

- Debian GNU/Linux 13.x
- PowerShell 7.6.4
- Debian 7-Zip package / native CLI

Real AMD 3.x through 8.x artifacts were previously validated through the full static extraction path. The same extraction design is used for historical ZIP wrappers.

The toolkit also recognizes the Debian packaging difference observed during testing:

- Debian 12 package: `7zz`
- Debian 13 package: `7z` / `7za` / `7zr`

Automatic discovery therefore checks `7zz`, then `7z`, then `7za`.


## Repository publication model

The old 1.0.0-era `inventory/accepted-baseline/` / `reports/accepted-baseline/` snapshot model is retained only in Git history and in older development checkpoints. It is **not** the intended current-main publication model for the future v2.0.0 release.

The current generated repository surface is:

```text
public/
├─ inventory/
│  └─ releases/<version>/amd-chipset-analysis-<version>.json
├─ reports/
├─ run-summary.json
├─ run-report.md
├─ publication-validation.json
└─ publication-manifest.json
```

This makes the main tree represent the current research dataset instead of keeping parallel versioned report trees. Historical versions remain recoverable through Git history.

`public/**` is an allow-list, not a filename convention. Runtime/private files outside it are not automatically repository-safe. Generated public files must come from the script; they are not to be hand-edited during packaging.

## Cross-platform evidence portability

Evidence bundles are expected to move between Windows test machines and Linux/ChatGPT analysis environments.

1.0.0 writes ZIP entry names with `/` separators. This avoids the warning/non-zero behavior that common Linux `unzip` tools can produce when a Windows-created ZIP stores entry names with backslashes.

## Related host-side WDF context

This toolkit intentionally inventories **driver-side declarations**. Host-side WDF capability must be measured separately and should not be guessed only from the Windows Server marketing version.

Separate project research in the same investigation observed:

- Windows Server 2019: on-disk `Wdf01000.sys` reported KMDF **1.27**, matching the published 1809-generation reference;
- Windows Server 2025: on-disk `Wdf01000.sys` reported KMDF **1.35**, newer than the Microsoft public WDF history reference used during the investigation;
- UMDF minor/API level should not be inferred from the PE `FileVersion` of `WUDFx02000.dll`, because that binary can use Windows component-style versions such as `10.0.x.y`.

The intended future integration model is therefore:

```text
Host-side observed WDF capability
        +
hardware-matched AMD INF declaration
        +
OS decoration / hardware ID / binary / signing constraints
        ↓
Deploy-Drivers-For-WindowsServer compatibility decision
```

The research toolkit supplies only the AMD package side of that decision.

## Data philosophy

### Observed facts plus bounded static applicability, not deployment policy

The canonical data model records observations, provenance, and bounded static Windows Server applicability. It does not encode deployment policy or assert runtime compatibility.

A future project resolver may compare, for example:

```text
Host KMDF
vs.
hardware-matched INF KmdfLibraryVersion
```

but that decision is downstream of this research toolkit.

### Unknown is not compatible

`NotDeclared`, `NotInspected`, `ParseFailed`, `FetchFailed`, and `ExtractionFailed` are distinct states.

A null WDF version must never be interpreted as "compatible".

### Provenance is first-class

Important observations retain enough evidence to reproduce or audit them:

- AMD source URL;
- captured page;
- retrieval time;
- artifact SHA-256;
- extraction log;
- INF SHA-256;
- line number;
- raw directive text;
- parser/toolkit version;
- execution environment.

## Canonical outputs

Runtime staging remains under `inventory/**` and generated `reports/**`. These files may include execution context or very large reconstructable aggregates and are **not** the automatic Git publication boundary.

The canonical repository Raw JSON is:

```text
public/inventory/releases/<version>/amd-chipset-analysis-<version>.json
```

A third-party reviewer should treat these per-release files as the primary machine-readable audit surface and use `public/inventory/release-index.json` to verify their SHA-256 values. Lightweight aggregate views and CSVs are deterministic derivatives. Human-readable generated reports live under `public/reports/**`.

The future `Deploy-Drivers-For-WindowsServer` resolver should consume explicit machine-readable contracts and preserve the distinction between AMD selector evidence, INF/PnP applicability, WDF requirements, and project deployment policy.


### New 1.1.0 analysis outputs

- `inventory/releases/<version>/amd-chipset-analysis-<version>.json` — canonical version-specific Raw JSON.
- `reports/releases/amd-chipset-<version>.md` — installer-version summary plus device/Server detail.
- `inventory/amd-chipset-windows-server-compatibility.csv` — device/HWID/Server matrix for machine processing.
- `reports/amd-chipset-windows-server-compatibility.md` — cross-release human-readable matrix.

The release JSON schema is versioned independently of Evidence ZIP schema so future interpretation logic can evolve while provenance remains explicit.

## Known limitations and next research areas

- Historical discovery remains best-effort even though the 2026-08-09 acceptance run successfully reconstructed and processed 25 releases from 2.04.04.111 through 8.07.16.1035. AMD may remove or rename additional historical pages or artifacts in the future.
- INF-declared WDF versions do not alone establish complete Windows Server compatibility.
- Some driver packages may have important binary/runtime behavior not represented by `KmdfLibraryVersion` / `UmdfLibraryVersion`.
- Published AMD metadata may disagree with embedded installer metadata.
- Future AMD installers may replace NSIS, InstallShield, MSI or CAB with another packaging model; extractor detection must fail explicitly rather than treating zero-INF output as success.
- `msitools`, `cabextract`, Wine and similar tools are not currently mandatory because the validated pipeline can reach INF using PowerShell + 7-Zip + the in-script decoder.

## Third-party reference implementation

The static InstallShield decoder was informed by the MIT-licensed ISx project:

```text
https://github.com/lifenjoiner/ISx
```

Attribution and license information are preserved in `THIRD-PARTY-NOTICES.md`.

## Primary external references

AMD:

```text
https://www.amd.com/en/resources/support-articles/release-notes/
https://www.amd.com/en/support/downloads/previous-drivers.html/chipsets/
https://drivers.amd.com/
```

Microsoft WDF:

```text
https://learn.microsoft.com/en-us/windows-hardware/drivers/wdf/framework-library-versioning
https://learn.microsoft.com/en-us/windows-hardware/drivers/wdf/kmdf-version-history
https://learn.microsoft.com/en-us/windows-hardware/drivers/wdf/umdf-version-history
```

## Pre-GA hardening promoted into 1.0.0

The final pre-GA v0.4.3 cycle added two hardening fixes found during review of the Windows PowerShell 5.1 runs. Both are part of the 1.0.0 GA baseline:

1. **Release identity hardening**
   - uses the final four-part version token when an AMD URL contains multiple versions;
   - adds 7.02.13.148 to the curated seed set;
   - normalizes multiple release-note URLs to a single four-part release identity;
   - retains alternate URLs as discovery diagnostics.

2. **Cross-platform Evidence ZIP hardening**
   - writes ZIP entries explicitly using `/` separators;
   - avoids Windows-created backslash entry names that trigger warnings/non-zero status in common Linux `unzip` tooling.

The PowerShell implementation remains a single `.ps1` file and retains Windows PowerShell 5.1 / PowerShell 7.x compatibility requirements.

### 1.0.0 functional acceptance provenance

The subsequent Windows PowerShell 5.1 full run accepted both hardening changes. Version 1.0.0 promotes that functionally accepted code; the accepted dataset intentionally retains its original generating version for provenance:

- 7.02.13.148 was independently discovered and processed as its own release;
- all 25 releases reached `ExtractionComplete`;
- the run finished `Pass` with exit code 0;
- the Windows-created Evidence ZIP was portable to Linux ZIP tooling;
- all 588 manifest-tracked evidence files passed SHA-256 verification.

No additional functional script defect was identified in that acceptance evidence.

## AMD selector reverse-engineering model

The 1.2.x line intentionally separates Microsoft's normal INF/PnP candidate rules from AMD's installer-specific selection process.

The current model is:

```text
Host PnP inventory
  -> AMD device-token / SETxxx candidates
  -> CPU/platform filters
  -> OS / architecture filters
  -> embedded component-manifest filters
  -> prior-install / MSI feature state (partially modeled)
  -> supported component list
  -> MSI SETxxx + ADDLOCAL
  -> component installer / pnputil behavior
```

The model must never infer an undocumented AMD rule merely to make an observation fit. Unknown differences remain visible.

### Recovered selector XML and second-stage provenance

For 8.07.16.1035, static extraction now records the selector XML chain rather than treating `Info.xml` as an isolated metadata file. The outer NSIS package contains:

```text
Qt_Dependencies/Setup.exe
Qt_Dependencies/Info.xml
Qt_Dependencies/DevID.xml
AMD_Chipset_Drivers.exe
```

`AMD_Chipset_Drivers.exe` is an InstallShield `ISSetupStream` type-4 launcher. Static decoding recovers `AMD_Chipset_Drivers.msi`; its `Data1.cab` contains an `APS_*.xml` file. For the analyzed 8.07.16.1035 artifact, `APS_7162026103425_2391.xml` is **byte-identical** to the outer `Info.xml` (same SHA-256). This strongly establishes that the component manifest is carried from the Qt front-end into the second-stage MSI payload.

The recovered `Info.xml`/APS manifest contains 64 product records, only the OS labels `Windows 10(64-bit)` and `Windows 11(64-bit)`, and only `Brand=Client`; no Server-labelled product record is present. `DevID.xml` independently maps AMD `/SET...` tags to device tokens.

The Qt `Setup.exe` binary contains static strings/import names including `/info.xml`, `/DevID.xml`, `Brand`, the Windows 7/10/11 XML labels, `readXmlFile`, `traverseDevIdXml`, `getDriverInfo`, `writeSupportedDriversToRegistry`, `is not present in xml list. Hence removing.`, `VerifyVersionInfoW`, and SetupAPI device-enumeration functions. Code-level disassembly of the exact 8.07.16.1035 binary (`SHA-256 9b8411b3f77312a770bdac35756081e77c74fb22b7c4c4f367db4f6e5ddf5462`) now goes beyond string evidence:

- `0x140017130` queries `root\cimv2` / `Select * from Win32_OperatingSystem`, retrieves `BuildNumber`, `Caption`, and `Version`, and classifies only caption substrings `Windows 7` -> enum `0`, `Windows 10` -> enum `1`, and `Windows 11` -> enum `2`. The field is initialized to `-1` before this call.
- `0x1400178e0` parses `/info.xml`, uses `Version`, `OS`, `Installer`, and `Brand`, checks `x86_64`, and in the non-Embedded/Client branch maps enum `0/1/2` to `Windows 7(64-bit)`, `Windows 10(64-bit)`, and `Windows 11(64-bit)`. An unknown enum appends no Client product.
- The identified OS-classification path does not query WMI `ProductType`; the sampled `VerifyVersionInfoW` helper also does not request the ProductType type-mask bit. This does not prove that no other binary path can ever inspect SKU, but the Server empty-list path no longer requires a ProductType hypothesis.

The toolkit records this as `AmdCompiledStaticProven` only when both release and selector-binary SHA-256 match the vetted contract. String-only observations remain `AmdStaticInferred`.

### 8.07.16.1035 qualification fixture

A real Windows 11 observation for 8.07.16.1035 provides a first selector ground truth. The AMD logs show initial candidates for GPIO3, PCI, Interface, PSP, USB-controller/PT, SMBus, USB Filter, GPIO2 and Ryzen power-management-related selection, followed by CPU and embedded-list filtering. The final supported list and MSI `ADDLOCAL` are both:

```text
GPIO3,PCI,PSP,SMBUS,GPIO2,RYZENPPKG
```

The current emulator reproduces the six final selections for that fixture and the explicit CPU/embedded-manifest removals. The previously unresolved `SETFILTERUSB` disappearance is now explained by a code-level branch in the exact Qt selector. The branch locates `/SETFILTERUSB`, requires a `DEV_790B` (or `DEV_780B` fallback) context together with `REV_16`, and otherwise erases `SETFILTERUSB` through a vector-removal helper without emitting the generic `not present in xml list` message. The supplied Windows 11 fixture has `DEV_790B` with `REV_61`, so its silent removal is consistent with the compiled branch and is now reported as `ObservedFilterExplainedByCompiledRule` rather than `UnknownAmdFilterSuspected`.

`SETRYZENPPKG` candidate creation is also now covered by the exact-binary compiled contract. Inside the `DEV_790B` device path, the selector has a CPU Family 23 / Model 160 special branch and otherwise accepts revision tokens `REV_61`, `REV_59`, or `REV_51` before constructing `/SETRYZENPPKG`. The supplied Windows 11 fixture (`REV_61`) and both Server fixtures (`REV_51`) satisfy this candidate-creation gate. This remains distinct from the later `Info.xml` filter: Server hosts can create `SETRYZENPPKG` and then lose it when their Caption classifies to enum `-1` and no Client product is appended.


### Windows Server 2025 negative qualification fixture

A second real observation for the same 8.07.16.1035 installer was captured on Windows Server 2025 Datacenter, build 26100. This fixture is intentionally the negative counterpart to the Windows 11 qualification host.

AMD still enumerates real AMD hardware and creates initial selector candidates including Interface, PSP, SATA, SMBus, USB Filter, GPIO2 and RyzenPPKG. It then explicitly removes Interface by CPU/platform logic and removes PSP, SATA, SMBus, GPIO2, RyzenPPKG, WDT and embedded-SMBus candidates because they are not present in the selected XML list. The final log line is present but empty:

```text
Writing supported drivers to registry:
```

Therefore the observation is recorded as `FinalSupportedListObserved=true`, `FinalSelectionStatus=ObservedEmpty`, and zero supported features. The exact Qt OS classifier provides the compiled explanation for the empty Client XML list, while the separate compiled `SETFILTERUSB` device/revision branch explains why that property disappears silently: the Server 2025 fixture carries `DEV_790B` with `REV_51`, not the required `REV_16`.

The accompanying top-level MSI transaction uses `ACTION=ADMIN`. The toolkit classifies it as `AdministrativeExtraction`; the fact that MSI lists many Features as `Request: Local` is **not** evidence that AMD considered those features installable on Server 2025. This prevents administrative extraction from becoming a false compatibility/selection signal.

For observation replay, ProductType is taken from live CIM when the tool runs on Windows. In non-Windows qualification replay, `MsiNTProductType` from the observed MSI log is preferred when present; otherwise the `Device_ID.log` Windows caption is used only as an explicitly labeled heuristic.

### Windows Server 2022 negative qualification fixture

A third independent observation for 8.07.16.1035 was captured on Windows Server 2022 Datacenter, build 20348. AMD detects a different physical-device set from the Server 2025 machine, including `SETUPEP` and `SETI2C` in addition to Interface, PSP, SMBus, USB Filter, GPIO2 and RyzenPPKG candidates. It nevertheless reaches the same final state: Interface is explicitly removed by CPU/platform logic, the XML-list stage explicitly removes UPEP/I2C/PSP/SMBus/GPIO2/RyzenPPKG/WDT/embedded-SMBus, and the final `Writing supported drivers to registry:` line is present but empty.

The 2022/2025 pair is intentionally used to prevent a weak emulator shortcut such as `if Server then []`. Qualification is decision-trace oriented: the tool must preserve the different detected candidate sets and their removal paths before the common empty final result. With the compiled Qt contract, both Server captions classify to enum `-1`, and `SETFILTERUSB` is separately removed by the silent revision gate because both Server fixtures carry `DEV_790B` with `REV_51` rather than `REV_16`.

### Evidence levels

| Evidence level | Meaning |
|---|---|
| `MicrosoftDefined` | Result derives from the parsed INF/PnP model used by the toolkit. |
| `AmdDeclarativeProven` | Rule is directly represented in AMD embedded metadata such as `DevID.xml`. |
| `AmdCompiledStaticProven` | Code-level predicate has been recovered from a specific AMD selector binary and is activated only when the exact selector SHA-256 matches the vetted contract. |
| `AmdStaticInferred` | Static package evidence provides a plausible explanation, but the exact AMD code path is not proven. |
| `AmdDynamicObservedSingleHost` | Rule is reproduced from a specific captured AMD installer observation and is intentionally scoped to that fixture/release. |
| `AmdDynamicObservedMultiHost` | Equivalent AMD behavior is observed on multiple independent hosts, while remaining scoped to the observed release/host class unless code/declarative evidence proves broader scope. |
| `EmulationConfirmed` | Emulator output agrees with the applicable captured observation. |
| unresolved status | Evidence is insufficient; the toolkit must preserve the mismatch rather than invent a rule. |

