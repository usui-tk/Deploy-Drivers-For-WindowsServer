# Changelog
## v2.0.0 documentation alignment — 2026-08-13 (documentation only)
- Reorganizes the AMD Chipset Driver Research Toolkit documentation without changing `Invoke-AmdChipsetDriverResearch.ps1`, toolkit version, schemas, static data, or generated `public/**` research artifacts.
- Aligns the tool-top Markdown surface with the AMD Graphics Driver Research Toolkit: `README.md`, `SPEC.md`, `TESTING.md`, `RESEARCH-NOTES.md`, `CHANGELOG.md`, `PUBLICATION-POLICY.md`, and `THIRD-PARTY-NOTICES.md`.
- Rewrites README as the stable current entry point, moves normative requirements into SPEC, expands TESTING into the current release/integration gate, and consolidates reverse-engineering plus downstream self-signed-driver engineering knowledge in `RESEARCH-NOTES.md`.
- Moves the former top-level `INF-ANALYSIS-SYNC.md` and `QT-SELECTOR-REVERSE-ENGINEERING.md` narratives to `reports/design-history/` and adds `reports/README.md`; no historical research content is discarded.
- Clarifies that historical reports are evidence/history, while top-level v2.0.0 documents define the current contract.
## 2.0.0 — pre-release aggregate-schema hardening — 2026-08-12

- Reviewed the first 2.0.0 Windows regeneration: research execution itself passed (10/10 stages, 25 releases, 643 INF package records, MSI 25/25 `ParsedReadOnly`, F-01 token corruption 0, public identity/privacy checks healthy).
- Found one release blocker in the generated public surface: `public/inventory/amd-selector-static.json` carried Windows PowerShell 5.1 `{ "value": [...], "Count": n }` serialization wrappers in schema-array fields, producing 131 Draft 2020-12 validation errors.
- Added recursive collection-wrapper canonicalization **only for tool-generated public aggregate indexes**. Canonical per-release Raw JSON remains byte-unchanged.
- Hardened wrapper detection so only an exact `value` + `Count` object with an enumerable `value` and matching count is treated as the PS5.1 collection artifact.
- Added fail-closed aggregate validation: generated aggregate JSON is rejected if a PS5.1 wrapper remains; `amd-selector-static.json` also receives a targeted array-shape check.
- Extended `PublicationContract` self-test with nested wrapper structures and verified `/SETFILTERUSB` remains byte-faithful.
- Declared aggregate collection canonicalization in `publication-manifest.json` `TransformationPolicy`.
- Regression against the first 2.0.0 Windows-generated dataset: 25/25 per-release Raw JSON SHA-256 unchanged; all generated aggregates wrapper-free; selector schema errors 131 -> 0; vendor token counts preserved.
- A new Windows full run with this corrected 2.0.0 source is required; generated files must not be hand-edited.

## 1.3.3-publication-dev — 2026-08-11

Windows full-run validation follow-up and final-publication hardening.

- Reviewed the user-provided 1.3.1 Windows 11 / Windows PowerShell 5.1 full run: 10/10 stages PASS, overall exit 0, 25/25 acquisition and extraction, 643 INF package records, MSI 25/25 `ParsedReadOnly`, zero all-null MSI rows, and `public/**` validation PASS.
- Confirmed the 1.3.1 public dataset contains 25 per-release Raw JSON files, 643 package records with exact CSV key-set equality, zero F-01 `external-path/SET*|info.xml|DevID.xml` regression, zero detected test-host path/ProcessorId leakage, and manifest/source-hash verification with zero mismatches.
- Changed canonical per-release Raw JSON generation to compact JSON **at Build time**. Publication remains a byte-for-byte copy of the canonical runtime file; no post-generation JSON editing or value transformation is introduced. This addresses indentation-only public-tree growth (the 1.3.1 public surface was ~527 MiB uncompressed).
- Changed large runtime-only `driver-packages.json` and `amd-chipset-driver-inventory.json` outputs to compact serialization to reduce disk/string-memory pressure.
- Added `Get-AmdCollectionItems` compatibility handling for the Windows PowerShell 5.1 `{ "value": [...], "Count": n }` wrapper when rehydrating generated public Raw JSON. The Raw JSON itself remains unchanged.
- Reproduced and fixed a fresh-checkout Build failure against real 8.07.16.1035 public Raw JSON; Build now passes with the realistic 31-INF structure. Rebuilt semantic content matches the 1.3.1 source after excluding expected toolkit-version/timestamp metadata.
- Bumped publication manifest to schema `amd-chipset-publication-manifest/1.1` with explicit payload-vs-manifest counts and repository size metrics.
- The final GitHub dataset still requires one fresh Windows full run with 1.3.3 because the script hash and canonical JSON serialization changed.

## 1.3.2-publication-dev — 2026-08-11

Claude revised-script review remediation and publication-contract hardening.

- Kept the F-01 field-scoped portable-path correction unchanged; Claude independently verified 10/10 exact normalization cases.
- Fixed the remaining PSA2001 merge blocker by changing the function-scope read of the script parameter to `$script:SkipPublicExport`.
- Made `Test-AmdPublicationContractSelfTest` independently callable after function-only dot-sourcing by lazily supplying/removing diagnostic script-scope root/version defaults when normal initialization has not run.
- Explicitly documented `external-artifact/<leaf>`, `work/extracted/<release>/...`, extraction-log portability, Markdown LF/no-BOM conversion, and no publication-time report annotation insertion in the generated publication manifest.
- Reverified the two Markdown files named in the withdrawn v2.0.0 F-03 finding are already UTF-8 no-BOM + LF in this development line.
- F-04 remains repository-side: parity/inventory consumers must be repointed when legacy `accepted-baseline` paths are removed.
- A fresh Windows full run remains required before renewed v2.0.0 candidacy; generated JSON must not be hand-edited.

## 1.3.1-publication-dev — 2026-08-11

- Diagnosed the 1.3.0 Windows full-run `ReviewRequired`: only Test failed, because `PublicationContract` did not detect a private Windows path after JSON backslash escaping. All research stages and public publication otherwise completed.
- Changed public JSON privacy validation to parse JSON and inspect decoded scalar strings, fixing the Windows escape blind spot instead of weakening the self-test.
- Added an explicit JSON-escaped `C:\Users\SensitiveUser\...` private-path self-test while preserving safe AMD/MSI evidence values such as `/SETFILTERUSB`, `/info.xml`, and `C:\`.
- Added a publication-time publication-contract gate so a broken contract cannot promote a new `public/**` surface even if Test was omitted or failed earlier.
- Canonicalized repository-relative paths in public indexes/manifests to `/` on all hosts.
- Fixed Windows manifest provenance matching so byte-copied Raw JSON/CSV and normalized Markdown record `SourceRelativePath` and `SourceSha256` instead of losing provenance because of `\` vs `/` matching.
- Independently validated the supplied 1.3.0 Windows public surface: 25 releases, 643 packages, MSI 25/25 `ParsedReadOnly`, zero all-null rows, zero F-01 token corruption, and no detected host-root/ProcessorId leakage.
- A fresh 1.3.1 Windows full run remains required before v2.0.0 candidacy. Generated JSON remains non-editable.


## 1.3.0-publication-dev — reproducible repository publication

- Rebuilt directly from `1.2.11-qt-dev`; the withdrawn v2.0.0 packaging candidate is not a source baseline.
- Fixed Claude F-01 in the generator: portable path conversion is now field-scoped, so `/SETFILTERUSB`, `/SETRYZENPPKG`, `/info.xml`, `/DevID.xml`, and MSI `C:\` values are not corrupted into `external-path/...`.
- Fixed the static-analysis scope issue by explicitly referencing `$script:SkipHostAnalysis` and `$script:ObservedAmdDeviceIdLog` in stage resolution.
- Added `public/**` as the only generated repository-publication allow-list and moved default private evidence to `private/evidence/**`.
- Added `-PublicOutputRoot` and `-SkipPublicExport`.
- Added fail-closed public staging/validation/atomic promotion, previous-public preservation, and partial-run preservation.
- Added canonical public per-release Raw JSON, deterministic release/selector/metadata indexes, repository-safe run summary, publication validation and publication manifest.
- Added source/public SHA-256 provenance and `HandEdited=false` to public manifest entries.
- Added deterministic LF/no-BOM normalization for generated public Markdown and declared the transformation in the manifest.
- Added runtime reconstruction of large `driver-packages.json` from public per-release Raw JSON for fresh-checkout workflows.
- Added portable-normalization and publication-contract self-tests; publication failures now force `ReviewRequired`.
- Added `PUBLICATION-POLICY.md`, `TESTING.md`, public surface README and publication JSON schemas.
- Future v2.0.0 Raw JSON must be regenerated by a corrected Windows full run; hand-edited publication JSON is explicitly prohibited.

## 1.2.11-qt-dev — 2026-08-11

Windows final qualification and MSI evidence-quality hardening.

- Live-qualified 1.2.10 on Windows 11 / Windows PowerShell 5.1: all 10 stages PASS, `OverallStatus=Pass`, and `ExitCode=0`.
- Confirmed final MSI gate closure: 25/25 releases are `ParsedReadOnly`; `ParsedCount=25`; `ParseFailed=0`; `ParsedWithErrors=0`; MSI analysis errors=0.
- Confirmed the 1.2.10 COM row-pipeline isolation fix against real Windows output: 13,993 selected MSI table rows and zero all-null rows.
- Preserved `SelfTestsReady=True`, all six internal self-tests PASS, Japanese `64 ビット -> x86_64` normalization, and the 8.07.16.1035 six-candidate / zero-unknown-filter host result.
- Added per-release MSI `Quality` evidence (`TableCount`, `TotalRowCount`, `AllNullRowCount`, `ErrorCount`).
- Hardened final assessment so all-null MSI rows force `REVIEW` even if a malformed or older analysis claims `Parsed` / `ParsedReadOnly`.
- Extended the MSI assessment self-test with a contaminated-success case that MUST become `REVIEW`.
- No AMD selector predicate, INF semantic, release-identity, or host-selection logic changed.

## 1.2.10-qt-dev — 2026-08-11

Windows Installer COM live confirmation and post-parse robustness hardening.

- Reviewed `AmdChipsetDriverResearchEvidence_20260811-034730_Windows.zip` from Windows 11 build 26200 / Windows PowerShell 5.1 with 7-Zip available.
- Confirmed all 10 stages PASS, overall exit 0, 25/25 acquisitions, 25/25 complete extractions, 643 INF records and zero INF parse failures.
- Live-confirmed the 1.2.9 Windows Installer COM repair: all 25 recovered MSI databases report `ParsedReadOnly`; no `FieldCount`, `ColumnInfo`, `StringData`, or `Fetch` runtime failure remains in selector processing.
- Fixed MSI final assessment so `ParsedReadOnly` is counted as a successful parse instead of producing the misleading `parsed=0` summary. `ParsedWithErrors`, `MsiNotRecovered`, unknown and missing analysis states now surface `REVIEW`.
- Fixed MSI table output contamination by explicitly discarding `View.Execute()` and `View.Close()` return values. The supplied evidence showed exactly two all-null synthetic rows in each of eight selected tables for every release (400 rows total).
- Added `MsiTableRowPipelineIsolationSelfTest` to catch COM/method return-value leakage into row output.
- Made all Test-stage self-tests readiness-gating; a failed self-test now fails Test after diagnostic evidence is persisted.
- Changed the FieldCount-independent self-test end marker so the normal Test transcript no longer contains an intentional caught terminating error.
- Preserved Windows 11 host matching: localized `64 ビット` normalizes to `x86_64`; 8.07.16.1035 still selects six expected candidates with `UnknownAmdFilterCount=0`.

## 1.2.9-qt-dev — 2026-08-11

Windows PowerShell 5.1 MSI COM hardening after the 1.2.8 live rerun.

- Reviewed `AmdChipsetDriverResearchEvidence_20260811-023713_Windows.zip` from Windows 11 build 26200 / Windows PowerShell 5.1 with 7-Zip available.
- Confirmed all 10 stages PASS, overall exit 0, 25/25 artifacts available, 25/25 extraction complete, 643 INF package records, and localized `64 ビット` architecture normalized to `x86_64`.
- Confirmed the 8.07.16.1035 Windows 11 host replay remains healthy: six selected candidates and zero unknown AMD-filter outcomes.
- Found the remaining MSI COM defect: all 25 releases reported `ParseFailed` because `Get-AmdMsiTableRows` accessed `Record.FieldCount`, which was not surfaced by the Windows PowerShell 5.1 COM adapter.
- Removed the `FieldCount` dependency and now discovers `View.ColumnInfo` names by sequential indexed `Record.StringData` reads.
- Added IDispatch/reflection fallbacks for indexed `Record.StringData`, `View.ColumnInfo`, and `View.Fetch` COM access.
- Added `MsiFieldCountIndependentColumnDiscoverySelfTest`, reproducing a usable record with no `FieldCount` property.
- Hardened final assessment with `MsiDeclarativeInspection`: any Windows MSI `ParseFailed` result now produces `ReviewRequired` rather than a silent overall `Pass`.
- Corrected generated host-analysis semantic text so 3.x-8.x exact-binary contracts are represented accurately; compiled hardware predicates remain limited to 7.x/8.x.
- Linux PowerShell 7.6.4 AST/Test qualification passes; live Windows Installer COM confirmation remains the next gate.

## 1.2.8-qt-dev — 2026-08-11

Windows-live qualification and robustness correction after three user-provided evidence runs.

- Reviewed Windows 11 build 26200 / Windows PowerShell 5.1, Windows Server 2025 build 26100 / PowerShell 7.6.3, and Windows Server 2022 build 20348 / Windows PowerShell 5.1 without 7-Zip.
- Fixed localized `OSArchitecture` handling: Japanese `64 ビット` no longer causes false `CompiledArchitectureNotMatched`; HostSurvey now preserves a normalized runtime architecture and selector matching uses the normalized value.
- Added architecture-normalization self-test. Captured Windows 11 replay now selects the expected 8.x six-feature set (SMBUS, PCI, PSP, GPIO2, GPIO3, RYZENPPKG); Server 2022/2025 remain negative through Caption classification.
- Added prerequisite-aware `BLOCKED` stage semantics. A failed Extract now blocks selected Inspect/Selector/Build dependencies rather than allowing PASS over empty/stale inventory.
- Hardened assessment so acquisition/extraction/INF inventories are evaluated only when the corresponding producer stage PASSed in the current run.
- Fixed fragile Windows Installer COM `_Tables` projection by accepting either `.Name` or the sole one-column property; added table-name projection self-test. Real Windows COM end-to-end rerun remains required.
- Updated 2.04.04.111 status from artifact-unavailable to canonical acquisition/static-topology observed: all three Windows runs downloaded the expected 52,428,763-byte ZIP with SHA-256 `d23a9cc4be06ab46c88918e523d11a96ca56b132f3b4646d2e8f9e17abf97185`; two 7-Zip-capable runs extracted 24 INF files.
- Recorded 2.x selector candidate `Qt_Dependancies/Setup.exe` SHA-256 `24cd52cc5a1eff6e082b2408681e4e90d759ef3ddcc8fedd9077fb632cd8bd76`, 26-product Windows 7/10 `Info.xml`, byte-identical APS XML, and no DevID.xml. No 2.x compiled contract is claimed without selector bytes/code-level reverse engineering.
- Added `reports/AMD-Chipset-Driver-Research-1.2.8-WINDOWS-LIVE-VALIDATION.md` and curated `qualification/1.2.8-qt-dev/` evidence/replays.

## 1.2.7-qt-dev — 2026-08-11

Reverse-chronological batch research for **5.x -> 4.x -> 3.x**, after 5.x was confirmed to share the same broad selector generation as frozen 6.x.

- Independently analyzed canonical 5.08.02.027, 4.08.09.2337 and 3.10.08.506 artifacts; all Test/Extract/Inspect/Selector/Build qualifications PASS with zero INF parse failures.
- Confirmed all three use NSIS outer packaging with `Qt_Dependencies/Setup.exe`, x86 Qt5, Client-only Win10/11 `Info.xml`, byte-identical APS XML, and no recovered `DevID.xml`.
- Added exact-release/SHA-256 partial compiled contracts for selector hashes `8f4e0f27...460cf` (5.x), `95d0428e...24160` (4.x), and `4a0cf13c...48ee9` (3.x).
- Proved the same logical Caption classifier for 3.x-6.x: initial/unmatched enum `3`; `Windows 7/10/11` map to `0/1/2`; only mapped Client labels are appended from `Info.xml`.
- Kept 3.x-6.x `/SETFILTERUSB` and `/SETRYZENPPKG` hardware predicates explicitly `Unresolved`; later 7.x/8.x `DEV_...` / `REV_...` predicates are not generalized backward.
- Recorded product growth 27 -> 39 -> 47 -> 53 across 3.x -> 4.x -> 5.x -> 6.x, followed by the previously proven 6.x -> 7.x architecture/Qt/DevID boundary.
- Requalified 6.x/7.x/8.x under 1.2.7; existing compiled predicates remain unchanged.
- Corrected metadata/static-string matching from the accidental doubled-backslash `root\\cimv2` representation to the actual WMI namespace literal `root\cimv2`; this is a metadata/evidence normalization, not a selector predicate change.
- Stopped before 2.x because no canonical 2.04.04.111 archive was available for binary verification; no 2.x topology is inferred.

## 1.2.6-qt-dev — 2026-08-11

Reverse-chronological major selector research: **6.x only**, using frozen 7.x/8.x results as regression references.

- Analyzed canonical `AMD_Chipset_Software_6.10.17.152.exe` (`e5bb2e43218248103a0aa8841b906ae96c7391598de416e51373b255819554bf`).
- Identified `Qt_Dependencies/Setup.exe` as a 1,631,440-byte PE32 x86 Qt5 selector, SHA-256 `83d82a4775c0793ace86b1b07f98eadfc262f22d4c275fab2d74b9d86f19379a`, FileVersion `6.0.0.0`.
- Added an exact-release/hash **partial** compiled contract proving the 6.x OS classifier and Client `Info.xml` filter. Unmatched Caption enum is `3`, not the 7.x/8.x `-1`.
- Fingerprinted 53 Product records, Client-only Win10/11 x64, byte-identical `Info.xml` / APS XML, and no recovered `DevID.xml` (zero declarative device mappings).
- Kept 6.x `SETFILTERUSB` and `SETRYZENPPKG` hardware predicates explicitly `Unresolved`; later `DEV_...` / `REV_...` contracts are not generalized backward.
- Established the 6.x→7.x boundary: Qt5→Qt6, x86→x64, DevID.xml absent→38 mappings, Product 53→62, and six additional SET properties in 7.x.
- 6.x Test/Extract/Inspect/Selector/Build requalification PASS; 7.x/8.x regressions remain PASS.
- Fixed generated `driver-packages.json` `SchemaVersion` to `2.0` so it matches the already-published `driver-package.schema.json` contract discovered by the release-precheck.

## 1.2.5-qt-dev — 2026-08-11

Reverse-chronological major selector research: **7.x only**, using 8.x as the frozen reference.

- Independently reverse-engineered AMD Chipset Software `7.11.26.2142`; canonical outer EXE SHA-256 `1acd6dadcc3b4bca9451ff170d7a5a049309b827f74cf54b2a3684bf16a34856`.
- Identified the 7.x selector owner as `Qt_Dependencies/Setup.exe`, size 1,391,880 bytes, SHA-256 `7b3714b3ff5c6add70987e0aacb0c5b5a2d523ea13ddf39bf0ac02b5f79d2b1a`, PE64 ImageBase `0x140000000`, resource FileVersion/ProductVersion `7.0.0.0`.
- Added an independent exact-release/exact-hash `AmdCompiledStaticProven` contract for 7.x. No rule is inherited merely because the binary is Qt-based.
- Proved the 7.x Caption classifier (`Windows 7/10/11 -> 0/1/2`, otherwise `-1`) and Client `Info.xml` filter (`0/1/2 -> Win7/10/11`, unknown enum -> no product appended).
- Proved 7.x `SETFILTERUSB` handling: same-device `(DEV_790B OR DEV_780B) AND REV_16`; failed candidates are erased silently.
- Proved the modeled 7.x `SETRYZENPPKG` path: `DEV_790B` plus Family 23 / Model 160 special path or revision `REV_61`, `REV_59`, or `REV_51`; surrounding `AMDI0052` logic remains explicitly bounded rather than over-generalized.
- Fingerprinted 7.x XML topology: 62 Product records, 38 DevID mappings, Client-only Windows 10/11 x64, and byte-identical `Info.xml` / `APS_11262025214138_657.xml`.
- Added `reports/amd-chipset-selector-major-version-comparison.md` and machine-readable comparison evidence. 8.x adds three DevID tags (`/SETSFH1.2`, `/SETUPMF`, `/SETXGBE`), two Product identities, and extends `/SETUPEP` and `/SETINTERFACE`.
- Preserved 8.07.16.1035 exact-binary contract and three-host qualification as regression references. 7.x has no live-host fixture, so 8.x dynamic evidence is not copied to 7.x.
- AST, Test self-test, 7.x static pipeline, and 8.x static regression pass under PowerShell 7.6.4 on Debian 13.
- The historical `1.0.0` accepted baseline remains unchanged. **6.x analysis is not started by this release.**


## 1.2.4-qt-dev — 2026-08-11

Qt selector code-level reverse engineering for AMD Chipset Software 8.07.16.1035.

- Added SHA-256-scoped `AmdCompiledStaticProven` selector evidence for the exact recovered `Qt_Dependencies/Setup.exe` (`9b8411b3f77312a770bdac35756081e77c74fb22b7c4c4f367db4f6e5ddf5462`).
- Recovered the WMI OS classifier at `0x140017130`: it reads `Win32_OperatingSystem` `BuildNumber`, `Caption`, and `Version`; the OS-family field is initialized to `-1` and only caption substrings Windows 7/10/11 set enum 0/1/2.
- Recovered the `Info.xml` filter at `0x1400178e0`: the x64 Client branch maps enum 0/1/2 to Windows 7/10/11 XML labels; unknown enum values append no Client product. This gives a compiled explanation for Server 2022/2025 empty XML lists without assuming a direct ProductType check.
- Resolved the former `SETFILTERUSB` implicit-removal mystery: the exact binary locates `/SETFILTERUSB`, requires DEV_790B (or DEV_780B fallback) with `REV_16`, and silently erases the candidate when the prerequisite is not met. The supplied Win11 REV_61 and Server REV_51 fixtures therefore become `ObservedFilterExplainedByCompiledRule`.
- Recovered the `SETRYZENPPKG` candidate-creation gate in the same selector function: after `DEV_790B` matching, CPU Family 23 / Model 160 is a special accepted path; otherwise `REV_61`, `REV_59`, or `REV_51` permits `/SETRYZENPPKG` creation. This explains candidate creation on the supplied Win11 REV_61 and Server REV_51 fixtures while preserving the later XML-list filter as a separate stage.
- Added UTF-16 selector string evidence, compiled-contract self-tests, `REV_..` host-token extraction, and compiled-rule-aware host matching.
- Bumped selector-static schema to 1.2, host-analysis schema to 1.3, and per-release analysis schema to 2.5.
- The code-level contract remains exact-binary scoped; no claim is made that other AMD releases use the same Qt predicates.
- Added `QT-SELECTOR-REVERSE-ENGINEERING.md` documenting the exact-binary Qt selector contract, three-host corroboration, and remaining reverse-engineering boundaries.
- Graphics artifacts remain reference-only in this Chipset session and are not modified by this release.

## 1.2.3-sync-dev — 2026-08-10

Chipset / Graphics INF semantic-contract synchronization.

- Added shared `amd-inf-semantic-contract/1.0` and `amd-inf-identifier-taxonomy/1.0` markers/schema.
- Imported Graphics' quote-aware INF CSV splitter for Manufacturer and Models parsing.
- Added shared Server-profile aliases while retaining the established Chipset canonical profile fields.
- Added `CanonicalStaticAssessment` as the cross-tool machine-readable status alias.
- Keeps WDF scope at the explicitly labeled `InfWideConservative`; DDInstall-scoped WDF is deferred.
- Keeps `CanonicalUnitKind=ReleaseVersion`, while Graphics deliberately uses `ArtifactKey`.
- Updated per-release analysis schema to 2.4 and topology contract metadata to the shared Contract 1.0.
- Source AST and `-Stages Test` pass under PowerShell 7.6.4. The 1.0.0 accepted baseline is not replaced and the 25-release PowerShell 5.1 acceptance has not yet been rerun.


## 1.2.2-dev

- Added Windows Server 2022 / build 20348 as a second independent negative Server fixture for AMD Chipset Software 8.07.16.1035.
- Added release-scoped `AmdDynamicObservedMultiHost` XML-list exclusion semantics for 8.07.16.1035 ProductType 3 hosts; this is explicitly not generalized to other releases and does not claim the exact compiled SKU predicate is proven.
- Qualification now preserves the different Server 2022 and Server 2025 candidate/removal traces rather than accepting a trivial `if Server then []` emulator shortcut.
- Kept `SETFILTERUSB` as `UnknownAmdFilterSuspected`: it is detected and implicitly removed on both Server fixtures without an explicit AMD removal message.
- Extended embedded metadata inspection to discover `APS_*.xml`, parse product records, and SHA-compare them with the preferred outer `Info.xml`.
- Added selector-binary static evidence collection from the recovered Qt `Setup.exe` (XML paths, selector strings, XML traversal symbols, OS/device API names) without executing the binary.
- For the analyzed 8.07.16.1035 artifact, confirmed `APS_7162026103425_2391.xml` is byte-identical to outer `Info.xml`; the XML exposes only Windows 10/11 Client product records.
- Fixed a StrictMode ordering bug in embedded `Info.xml`/`DevID.xml` parsing where the relative source path could be referenced before assignment.
- Bumped embedded metadata schema to 1.1, selector-static schema to 1.1, host-analysis schema to 1.2, and per-release analysis schema to 2.3.

## 1.2.1-dev

- Hardened AMD `Device_ID.log` observation parsing for an explicitly empty final `SupportedDrivers` list; `ObservedEmpty` is now distinct from `NotObserved`.
- Added implicit-removal evidence for `SETxxx` candidates that disappear before the final list without an explicit AMD `Hence removing` event; these remain `UnknownAmdFilterSuspected`.
- Added observed host build/ProductType provenance and fixed non-Windows replay so Windows Server logs are no longer hard-coded as ProductType 1.
- Added MSI observation transaction classification, including `ACTION=ADMIN` -> `AdministrativeExtraction`, and prevented administrative Feature `Request: Local` rows from being treated as install-selection evidence.
- Added `MsiNTProductType`, `AddLocalObserved`, transaction mode, and feature-selection interpretation to MSI observation evidence.
- Added Windows Server 2025 / build 26100 negative selector fixture semantics: AMD hardware detection can succeed while the final supported-driver list is explicitly empty after AMD-specific filtering.
- Fixed empty-set host/MSI consistency comparison so a zero-component Server observation no longer fails `HostMatch` through PowerShell `Compare-Object` null binding.
- Updated selector/MSI/host-analysis schemas to 1.1 while preserving the 1.0.0 accepted repository baseline as historical provenance.

## 1.2.0-dev

- Added release-static AMD selector analysis from `DevID.xml` / `Info.xml` and read-only Windows Installer MSI tables.
- Added `Selector`, `HostSurvey`, and `HostMatch` stages while keeping the implementation in the single PowerShell script.
- Added read-only live Windows PnP/CPU/OS inventory; no AMD EXE execution, driver staging, INF install, or registry modification.
- Added optional replay of real `Device_ID.log` and MSI verbose logs for selector qualification without executing AMD software.
- Added release binding for observed logs so one captured AMD result is never compared to unrelated historical releases.
- Added actual-host INF Models/TargetOSVersion matching and host-specific report/JSON outputs.
- Indexed host Hardware/Compatible IDs for matching so HostMatch does not perform a full device scan for every INF model row.
- Added AMD selector decision/evidence vocabulary including `EmulationConfirmed`, explicit observed filters, static-inference filters, and unresolved mismatches.
- Qualified 8.07.16.1035 using the supplied Windows 11 AMD logs: six final features reproduced (`GPIO3,PCI,PSP,SMBUS,GPIO2,RYZENPPKG`) and MSI `ADDLOCAL` consistency confirmed.
- Kept `SETRYZENPPKG` as a release/single-host empirical rule until its exact declarative predicate is recovered.
- Identified the Windows-10-only embedded USB Filter record as a static explanation candidate for the observed absence of `SETFILTERUSB` on the Windows-11 qualification host.
- Added host-OS filtering of embedded component candidates and tightened `SETGPIO2` product correlation to avoid conflating it with Promontory GPIO.
- Existing 1.0.0 accepted baseline remains unchanged; 1.2.0-dev requires Windows PowerShell 5.1 live-host qualification before GA/baseline promotion.

## 1.1.1-dev

- Grouped `amd-chipset-windows-server-compatibility.md` by release and sorted releases newest first.
- Changed compatibility tables from one row per Server profile to one row per device with WS2016/2019/2022/2025 columns.
- Added semantic identifier classification for bus PnP, root-enumerated, device-class-specific, generic, and network software component identifiers.
- Added `Identifier` and `CompatibleIdentifiers` to INF topology Raw JSON while retaining the original `HardwareId`/`CompatibleIds` fields.
- Added `IdentifierKind` / `IdentifierType` to compatibility CSV output and sorted CSV releases newest first.
- Bumped per-release analysis schema to 2.1 and INF topology schema to 1.1.

## 1.1.0 — development (2026-08-10)

INF semantic-analysis feature line.

- Preserves `[Manufacturer]`, TargetOSVersion decorations, reachable Models sections, device descriptions, DDInstall sections, HWIDs and compatible IDs as canonical topology.
- Simulates Microsoft INF Models selection for Windows Server 2016/2019/2022/2025.
- Keeps AMD-published applicability separate from an analytical ProductType=1 -> ProductType=3 Server projection.
- Adds conservative host WDF cross-checking with documented/observed references kept distinct.
- Adds one Raw JSON analysis file per AMD installer version plus per-release device/Server Markdown reports and cross-release CSV/Markdown matrices.
- Incorporates the Graphics-side hardening lesson that Models parsing must follow Manufacturer references rather than wildcard section prefixes.
- Initial Linux regression: real AMD installers 3.10.08.506, 4.08.09.2337, 5.08.02.027, 6.10.17.152, 7.11.26.2142 and 8.07.16.1035; 157 INF files, zero parse failures.
- The repository-committed accepted baseline remains the 1.0.0-era dataset until a new 25-release Windows PowerShell 5.1 acceptance run is performed.

## 1.0.0 — 2026-08-09

First GitHub commit candidate / GA research-tool baseline.

- Promotes the fully accepted v0.4.3 implementation to semantic version `1.0.0`.
- Keeps the single-PowerShell-script project policy.
- Supports Windows PowerShell 5.1 and PowerShell 7.x on Windows/Linux.
- Defaults to the complete Test → Discover → Metadata → Acquire → Extract → Inspect → Build workflow.
- Supports AMD historical ZIP wrappers, NSIS outer containers, InstallShield `ISSetupStream` type 3/4 recovery, MSI/CAB expansion, INF inspection, and KMDF/UMDF directive capture.
- Produces stage timing/progress logs and review-oriented Evidence ZIPs.
- Adds a repository-committed accepted baseline for 25 releases from 2.04.04.111 through 8.07.16.1035.
- The accepted Windows PowerShell 5.1 run completed all seven stages with `Pass / exit 0`, 25/25 acquisitions, 25/25 `ExtractionComplete`, 643 INF records, 158 KMDF declarations, 25 UMDF declarations, and zero INF parse failures.

### Provenance note

The accepted dataset was generated by pre-GA v0.4.3. Version 1.0.0 changes the toolkit version metadata and repository documentation/data packaging, not the accepted extraction or INF-analysis behavior. The checked-in dataset intentionally retains its original `ToolkitVersion` value.
