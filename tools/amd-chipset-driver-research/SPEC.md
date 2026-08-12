# AMD Chipset Driver Research Toolkit Specification

**Specification baseline: toolkit 1.2.11-qt-dev**


## Public/private generated-output contract (1.3.3-publication-dev)

### Release-publication hardening requirements (1.3.3)

- Script-level parameters referenced from functions must use explicit `$script:` qualification when required by the repository PSA2001 gate.
- `Test-AmdPublicationContractSelfTest` must be callable after function-only dot-sourcing without requiring the normal top-level initialization path.
- `publication-manifest.json` must enumerate every transformation family used by the current generator, including `external-artifact/<leaf>`, `work/extracted/<release>/...`, extraction-log portability, Markdown LF/no-BOM conversion, and the absence of publication-time report annotation insertion.
- Repository-public Markdown must be UTF-8 no-BOM and LF.
- F-04 remains a repository-integration task: consumers of the old accepted-baseline inventory path must be repointed when the current public inventory replaces that legacy path.
- Canonical per-release Raw JSON SHALL be compactly serialized at Build generation time to avoid indentation-only Git growth; publication SHALL still copy the canonical file byte-for-byte and preserve source/published SHA-256 equality.
- Fresh-checkout rehydration SHALL tolerate the Windows PowerShell 5.1 `{ "value": [...], "Count": n }` collection wrapper when consuming generated Raw JSON, without rewriting the canonical Raw JSON itself.
- Large runtime-only JSON aggregates SHOULD use compact serialization to reduce memory/string and disk pressure.
- Publication manifest schema 1.1 SHALL distinguish manifested payload entries from the manifest file itself and SHALL record payload-size/largest-file metrics.
- Tool-generated public aggregate indexes SHALL recursively canonicalize a verified Windows PowerShell 5.1 `{ "value": [...], "Count": n }` collection serialization artifact to a plain JSON array. This projection SHALL NOT rewrite canonical per-release Raw JSON.
- Publication validation SHALL fail if a recognized PS5.1 collection wrapper remains in a generated aggregate. `amd-selector-static.json` SHALL additionally satisfy its declared array-shape contract before promotion.


The toolkit SHALL classify generated output by location, not extension. `public/**` SHALL be the only generated output surface intended for unattended repository commits. `private/evidence/**`, runtime `inventory/**`, generated runtime `reports/**`, and `work/**` SHALL NOT be automatic generated-output commit surfaces.

Canonical public Raw JSON SHALL be the per-release Build output under `public/inventory/releases/**`. Publication SHALL copy those canonical per-release files byte-for-byte; it SHALL NOT apply a second value-level sanitization pass. Filesystem portability SHALL be resolved while composing the canonical per-release document and SHALL be field-scoped. A leading `/` SHALL NOT by itself classify a string as a path. Vendor evidence tokens such as `/SETFILTERUSB`, `/SETRYZENPPKG`, `/info.xml`, `/DevID.xml`, and MSI property values such as `C:\` SHALL remain unchanged unless the field contract explicitly defines a host filesystem path.

Publication privacy validation SHALL parse JSON and evaluate decoded scalar string values; it SHALL NOT rely on matching host paths against JSON-escaped serialized text. Repository-relative paths written to public indexes/manifests SHALL use `/` independent of host OS.

Publication SHALL be transactional and fail-closed. Staging SHALL begin from the last validated public surface for partial-run preservation, overlay current output, validate privacy/portability/token integrity, write validation/manifest metadata, and replace the retained `public/**` only after validation passes. Failure SHALL preserve the previous public surface and SHALL make the final assessment `ReviewRequired`.

`publication-manifest.json` SHALL record each public file's relative path, size, SHA-256, classification, generation mode, source-relative path/hash where meaningful, and `HandEdited=false`. Every deterministic transformation SHALL be declared. Generated public Markdown SHALL use UTF-8 without BOM and LF line endings.

Large runtime aggregates that are reconstructable from per-release Raw JSON MAY remain outside Git. A fresh checkout SHALL be able to reconstruct required runtime aggregates from retained public per-release data.

A corrected generator SHALL be rerun to regenerate affected Raw JSON. Manual repair of generated JSON is prohibited.

## MSI evidence-quality contract (1.2.11-qt-dev)

- A successful Windows MSI declarative analysis SHALL record a `Quality` summary containing parsed table count, total selected row count, all-null row count, and analysis error count.
- An all-null row in selected MSI table evidence SHALL be treated as evidence contamination. The analysis SHALL become `ParsedWithErrors`, or final assessment SHALL otherwise force `MsiDeclarativeInspection=REVIEW`.
- Final assessment SHALL independently inspect successful `Parsed` / `ParsedReadOnly` evidence for all-null rows so malformed or older evidence cannot remain PASS solely because its status string says success.
- The MSI declarative assessment self-test SHALL include a deliberately contaminated successful parse and SHALL prove that it produces `REVIEW`.
- The 1.2.10 Windows qualification baseline is 25/25 `ParsedReadOnly`, zero MSI errors, 13,993 selected table rows, and zero all-null rows.
- This contract is evidence-quality hardening only. It SHALL NOT change selector predicates, INF semantics, AMD release identity, or host-selection rules.


## Windows MSI COM live-validation and output-integrity contract (1.2.10-qt-dev)

- `ParsedReadOnly` SHALL be treated as a successful Windows Installer declarative parse state. Legacy `Parsed` MAY also be accepted as success for compatibility with older evidence.
- `ParsedWithErrors`, `ParseFailed`, `MsiNotRecovered`, unknown status values, or missing MSI analysis SHALL produce `MsiDeclarativeInspection=REVIEW` when selector MSI assessment is applicable.
- A non-Windows run where every release reports `WindowsInstallerComUnavailableOnPlatform` MAY report the MSI assessment as PASS because the limitation is platform-defined and explicit.
- MSI table row functions SHALL suppress return values from `View.Execute()` and `View.Close()` so COM method results cannot contaminate table-row evidence.
- Test-stage self-tests SHALL be readiness-gating. A failed self-test SHALL make Test fail after `environment.json` is written for diagnosis.
- The environment Test stage SHALL include a row-pipeline isolation self-test proving that synthetic method return values do not appear as MSI rows.
- Intentional self-test boundary checks SHOULD NOT emit caught terminating errors into normal console transcripts.

## Windows MSI COM hardening contract (1.2.9-qt-dev)

- Windows Installer declarative inspection SHALL NOT depend on the PowerShell COM adapter exposing `Record.FieldCount`.
- Column discovery SHALL use `View.ColumnInfo` plus indexed `Record.StringData`, with a bounded maximum-column safety limit.
- COM member access used by MSI table reading SHOULD provide a reflection/IDispatch fallback when normal PowerShell COM adaptation does not expose the member consistently.
- `MsiDeclarativeAnalysis.Status=ParseFailed` SHALL remain visible as release evidence. If Selector PASSes in the current run but one or more MSI analyses are `ParseFailed`, final assessment SHALL include `MsiDeclarativeInspection=REVIEW` and SHALL NOT report overall `Pass`.
- MSI declarative failure SHALL NOT erase otherwise valid XML/binary selector evidence; it is a review condition, not proof that the complete Selector stage is invalid.
- The environment Test stage SHALL include a self-test that discovers multiple column names from an indexed-string record with no exposed `FieldCount` property.

## Windows-live hardening contract (1.2.8-qt-dev)

- Host architecture comparison SHALL use a normalized architecture value. Localized display strings such as Japanese `64 ビット` MUST NOT cause an x64 AMD host to be classified as architecture-incompatible.
- Stage results SHALL support `BLOCKED`. If a selected prerequisite stage fails or is blocked, dependent selected stages SHALL be blocked rather than executed against empty/stale producer data.
- Assessment SHALL consume acquisition/extraction/inspection inventories only when the corresponding producer stage PASSed in the current run.
- Windows Installer COM table enumeration SHALL NOT assume `_Tables` rows expose a `.Name` property; one-column fallback projection SHALL be supported.
- 2.04.04.111 canonical acquisition/static topology MAY be reported as observed evidence, but no `AmdCompiledStaticProven` 2.x contract SHALL be emitted until the exact selector bytes have undergone code-level review.

## Exact-binary major selector contracts (preserved from 1.2.7)

The compiled selector contract registry SHALL recognize the following exact release/hash pairs independently:

- `3.10.08.506` / `Qt_Dependencies/Setup.exe` SHA-256 `4a0cf13c66f873319ff44eba1867f9cc7dc865d0f422c007bcb25c6ced148ee9`;
- `4.08.09.2337` / `Qt_Dependencies/Setup.exe` SHA-256 `95d0428ea90bee14704bf556a3ad6c91971e63d6d63c0807e9e7a8791d024160`;
- `5.08.02.027` / `Qt_Dependencies/Setup.exe` SHA-256 `8f4e0f27397786275db0a45282b05bf39da1f16ee9379712a75544fdb49460cf`;
- `6.10.17.152` / `Qt_Dependencies/Setup.exe` SHA-256 `83d82a4775c0793ace86b1b07f98eadfc262f22d4c275fab2d74b9d86f19379a`;
- `7.11.26.2142` / `Qt_Dependencies/Setup.exe` SHA-256 `7b3714b3ff5c6add70987e0aacb0c5b5a2d523ea13ddf39bf0ac02b5f79d2b1a`;
- `8.07.16.1035` / `Qt_Dependencies/Setup.exe` SHA-256 `9b8411b3f77312a770bdac35756081e77c74fb22b7c4c4f367db4f6e5ddf5462`.

A contract MUST NOT be selected by major version, filename, Qt presence, architecture, or string similarity alone. Both release and selector SHA-256 MUST match. The 3.x/4.x/5.x/6.x contracts are intentionally partial: compiled OS-family classification and Client `Info.xml` filtering are proven, while `/SETFILTERUSB` and `/SETRYZENPPKG` hardware predicates remain `Unresolved`. 7.x/8.x hardware predicates MUST NOT be imported into these older contracts. 7.x remains static-only unless a release-specific live fixture is supplied; 8.x three-host dynamic evidence MUST NOT be attributed to another major.

The current code-level compiled-contract scope is `8.x -> 7.x -> 6.x -> 5.x -> 4.x -> 3.x`. For 2.04.04.111, canonical acquisition and static installer topology are now observed from Windows evidence, including the `Qt_Dependancies/Setup.exe` selector candidate, but compiled predicates remain unresolved because the selector bytes have not yet undergone code-level review. The 3.x contract MUST NOT be inferred for 2.x.

The WMI namespace stored in compiled-selector metadata SHALL use the actual literal `root\cimv2`; doubled-backslash source metadata is not a distinct namespace and SHALL NOT be preserved as vendor evidence.

## 0.1 Shared INF semantic contract

Newly generated 1.2.4-qt-dev INF semantics SHALL conform to `amd-inf-semantic-contract/1.0` and `amd-inf-identifier-taxonomy/1.0`. Chipset SHALL retain `CanonicalUnitKind=ReleaseVersion`. WDF SHALL remain `InfWideConservative` for Contract 1.0; `DDInstallScoped` is not claimed until a later cross-tool qualification. `INF-ANALYSIS-SYNC.md` is the normative cross-tool mapping note.

## 1. Purpose

The toolkit SHALL provide a reproducible, PowerShell-based research workflow for AMD Ryzen Chipset Driver releases and their driver-package WDF requirements.

It SHALL remain logically independent from `Deploy-Drivers-For-WindowsServer` deployment policy.

Primary goals:

1. reconstruct AMD chipset release history;
2. retain release-note and installer provenance;
3. statically extract AMD packages without executing installers;
4. inspect INF declarations and preserve semantic topology;
5. produce canonical machine-readable inventory data;
6. remain maintainable if AMD changes release-note URLs or installer container formats.

## 2. Repository placement

The canonical path SHALL be:

```text
tools/amd-chipset-driver-research/
```

New research families SHALL use sibling directories under `tools/`, for example `tools/amd-graphics-driver-research/`.

## 3. PowerShell aggregation policy

The toolkit SHALL expose **one PowerShell script**:

```text
Invoke-AmdChipsetDriverResearch.ps1
```

Stage-specific implementation SHALL be aggregated into internal functions in that script rather than separate `.ps1` files or a `.psm1` module.

The implementation MAY use internal function boundaries for maintainability, but those functions SHALL NOT create runtime dependencies on additional PowerShell source files.

Additional PowerShell files SHOULD NOT be introduced unless a future requirement cannot reasonably be met within the single-script model and the exception is explicitly documented.

Data files, JSON schemas, generated inventory, raw evidence and Markdown documentation are not subject to the single-PowerShell-file restriction.

## 4. Runtime compatibility

The single `.ps1` SHALL support:

- Windows PowerShell 5.1 on Windows
- PowerShell 7.x on Windows and Linux

It SHALL NOT use ternary operators, null-coalescing operators, pipeline-chain operators, `ForEach-Object -Parallel`, or PowerShell-7-only cmdlet parameters without a compatibility branch.

Web helpers SHALL remain compatible with Windows PowerShell 5.1 and PowerShell 7.x. Expected HTTP failures SHOULD be handled through a .NET request path that does not leak caught cmdlet error records into the console transcript. TLS 1.2 SHALL be enabled for Windows PowerShell 5.1 where supported.

The single script SHALL detect the host platform at runtime. Linux support SHALL NOT require a second `.ps1` implementation or a PowerShell module.

## 5. Encoding

Repository policy:

- `.ps1`: UTF-8 with BOM, CRLF working-tree form;
- `.md`: UTF-8 without BOM, LF;
- canonical JSON: UTF-8 without BOM, LF;
- derived CSV: UTF-8; BOM differences between engines are non-authoritative.

Canonical JSON SHALL be written through .NET `System.IO.File` with `UTF8Encoding(false)` rather than relying on version-dependent `Set-Content -Encoding UTF8` behavior. Repository-facing per-release canonical JSON SHALL use compact serialization; this changes insignificant whitespace only and is performed by the generator before publication.

## 6. Stage model

The single script SHALL expose selectable stages through `-Stages` while keeping a single source artifact.

Supported stages:

- `Test`
- `Discover`
- `Metadata`
- `Acquire`
- `Extract`
- `Inspect`
- `Selector`
- `HostSurvey`
- `HostMatch`
- `Build`
- `All` as an ordered shorthand for the full applicable workflow.

When `-Stages` is omitted, the script SHALL behave as `-Stages All`. `All` SHALL include `Selector`. On Windows it SHALL also include read-only `HostSurvey` and `HostMatch` unless `-SkipHostAnalysis` is specified. On non-Windows systems the live-host stages SHALL be omitted unless an observed AMD `Device_ID.log` is explicitly supplied for qualification replay. Explicit stage selections SHALL retain their existing meaning.

### D0 Environment test

The `Test` stage SHALL validate the supported PowerShell runtime, detect the host platform, and report 7-Zip availability. Missing 7-Zip does not prevent metadata research, but extraction readiness SHALL be reported separately.

The stage SHALL persist reproducibility evidence to `inventory/environment.json`, including platform family, OS description/architecture, PowerShell version/edition, selected 7-Zip command/path, Linux package-manager/package evidence when available, and readiness state.

On Windows, 7-Zip discovery SHOULD prefer `7z.exe` and standard 7-Zip installation locations. On Linux/macOS, discovery SHALL prefer the native `7zz` command, then accept `7z` and `7za` as compatibility fallbacks. `-SevenZipPath` SHALL override automatic discovery on all platforms. On Linux, package-manager queries SHOULD check common package names when `dpkg-query`, `rpm`, or `apk` is available, but package-manager installation SHALL NOT be required when a usable standalone binary is present.

### D1 Discovery

Inputs: AMD sitemap(s), curated seed URLs and operator-supplied URLs.

Output: release identities and release-note URLs.

Discovery SHALL preserve `DiscoverySource` and SHALL NOT assert completeness merely because no more sitemap records are found.

### D2 Metadata

Inputs: discovered release-note URLs.

Outputs: captured raw HTML evidence, page metadata and candidate AMD installer URLs.

Metadata SHALL preserve fetch errors per release. HTML decoding SHALL honor declared charset information and default safely to UTF-8 when an HTTP stack reports an ambiguous legacy encoding. Candidate URL parsing SHALL reject unrelated navigation links and URLs whose embedded release version does not match the release record. Known AMD historical artifact naming patterns MAY be synthesized to recover releases whose current release-note page no longer exposes a direct artifact URL.

### D3 Acquisition

Inputs: candidate installer URLs.

Outputs: local installer evidence, artifact format, SHA-256, size and source/referrer provenance.

Acquisition SHALL support both modern PE/EXE installer artifacts and historical ZIP delivery artifacts. It SHALL reject HTML/error pages even when the HTTP request returns success. Acquisition SHALL NOT execute downloaded files. By default it SHALL reject candidate download hosts outside `amd.com` and its subdomains unless the operator explicitly overrides that policy. Expected 404/retired-URL conditions SHALL be persisted as structured acquisition evidence without dumping raw PowerShell terminating-error records to the console.

### D4 Extraction

Inputs: downloaded installer artifacts.

The default extractor adapter SHALL be 7-Zip and SHALL use the same command-line extraction model on Windows and Linux. Extraction SHALL never execute installer EXEs or MSI packages, SHALL recurse only to a bounded depth, and SHALL record extraction failures rather than treating them as empty packages.

No additional Linux extractor SHALL be mandatory unless real package evidence demonstrates a format that the selected 7-Zip implementation cannot inspect. Optional future adapters such as `msitools` or `cabextract` MAY be introduced only with documented justification.

The internal implementation SHOULD make later replacement of the extraction mechanism possible without redesigning canonical inventory data.

### D5 Driver inspection

For each INF, the parser SHALL record path, SHA-256, `Provider`, `Class`, `ClassGuid`, `DriverVer`, `CatalogFile`, hardware IDs, service binary references, and all observed `KmdfLibraryVersion` / `UmdfLibraryVersion` directives.

The parser SHALL additionally preserve INF semantic topology: all `[Manufacturer]` entries, raw and parsed TargetOSVersion decorations, only Models sections actually reachable from those Manufacturer entries, device descriptions, DDInstall section names, primary HWIDs, compatible IDs, source line numbers and parse warnings. Prefix-based wildcard section discovery MUST NOT classify DDInstall, `.Services`, `.HW` or `.Wdf` sections as Models merely because their names share a manufacturer prefix.

The parser SHALL evaluate TargetOSVersion using Microsoft semantics: architecture, major/minor OS version, explicit ProductType, SuiteMask, and BuildNumber. BuildNumber SHALL be treated as a minimum build for matching major/minor OS versions. Models-section resolution SHALL occur per Manufacturer line and SHALL prefer the closest applicable decoration. An empty selected Models section SHALL be represented as an explicit exclusion.

The toolkit SHALL evaluate both `AsPublished` and `ServerProjection` modes. `ServerProjection` MAY analytically replace explicit ProductType 1 with ProductType 3 but SHALL NOT modify the source INF. Empty ProductType SHALL be treated as already including Server; ProductType 2 SHALL NOT automatically be projected to ProductType 3.

Every WDF directive SHALL retain line number, raw line and normalized value. The parser SHALL NOT infer KMDF/UMDF from binary file versions.

### D6 AMD selector static analysis

`Selector` SHALL construct a release-static AMD component-selection evidence model without executing AMD setup code.

Current supported evidence sources are:

- `DevID.xml` `/SET...` tag and device-token mappings;
- `Info.xml` embedded component name, installer name, target client-OS label and version;
- recovered `APS_*.xml` component-manifest copies from nested MSI/CAB payloads, including SHA-256 identity comparison with preferred `Info.xml`;
- static evidence from the recovered Qt selector binary (`Setup.exe`) sufficient to preserve XML paths, selector log strings, XML traversal symbols and OS/device API import names without executing the binary;
- SHA-256-scoped compiled-selector contracts when code-level disassembly has recovered a predicate with enough confidence to reproduce it without executing AMD code;
- recovered top-level `AMD_Chipset_Drivers.msi` declarative database tables when the analysis runs on Windows.

For Qt-based 8.x packages, the implementation SHOULD model the recovered chain `outer NSIS -> Qt_Dependencies/Setup.exe + Info.xml + DevID.xml -> AMD_Chipset_Drivers.exe -> ISSetupStream -> AMD_Chipset_Drivers.msi -> Data1.cab -> APS_*.xml`. If an `APS_*.xml` is byte-identical to `Info.xml`, that identity SHALL be preserved as artifact provenance.

Windows MSI inspection SHALL open the recovered MSI database read-only and SHALL NOT schedule or execute MSI actions. The toolkit SHOULD inventory at least `Property`, `Feature`, `Condition`, `LaunchCondition`, `AppSearch`, `RegLocator`, `CustomAction`, `InstallUISequence`, `InstallExecuteSequence` and `Upgrade` when those tables are present. On Linux, Windows Installer COM unavailability SHALL be an explicit status and SHALL NOT invalidate the XML/static selector model.

The selector-static record SHALL keep declarative XML fields, APS/Info provenance, selector-binary static evidence, code-level compiled-selector contracts, and MSI declarative evidence as separate evidence layers. Presence of a binary string or API import SHALL NOT be represented as proof that a particular runtime branch was taken. `AmdCompiledStaticProven` SHALL be emitted only for an exact selector-binary SHA-256 whose control-flow predicate has been independently reverse-engineered and documented.

The canonical output is:

```text
inventory/amd-selector-static.json
```

Per-release canonical Raw JSON SHALL preserve the static selector record, but SHALL NOT embed machine-specific host results.

### D7 Read-only host survey and selector/PnP comparison

`HostSurvey` SHALL be read-only. It SHALL NOT execute the AMD installer, run `pnputil /add-driver`, stage/install an INF, modify the Driver Store, modify the registry, install certificates, or alter device state.

On Windows it SHOULD collect:

- OS caption/version/build/ProductType/architecture;
- CPU identity and Family/Model/Stepping where available;
- PnP instance ID, Hardware IDs and Compatible IDs;
- `MatchingDeviceId` where exposed;
- current signed-driver metadata;
- controlled host WDF observation data.

PnP property APIs SHOULD be preferred for Hardware/Compatible IDs when available; CIM/WMI SHALL remain a fallback path for compatibility.

`HostMatch` SHALL maintain two independent decision planes:

1. the Microsoft/INF plane: actual host identifiers + selected Models section + TargetOSVersion/WDF analysis;
2. the AMD selector plane: host tokens + AMD declarative selector evidence + explicitly labeled static inference/empirical rules.

The output SHALL record divergence rather than forcing the two planes into a single compatibility boolean.

Host-specific outputs:

```text
inventory/host/host-inventory.json
inventory/host/amd-chipset-host-analysis.json
reports/amd-chipset-host-analysis.md
```

Qualification-only observed inputs MAY include AMD `Device_ID.log` and verbose MSI logs. Captured observation SHALL be bound to one explicit/inferred AMD installer release before it is compared with a static release record. A captured 8.07 result MUST NOT be compared as if it were a 7.x or 6.x observation.

The Device_ID observation parser SHALL distinguish a non-empty final list, an explicitly observed empty final list, and a missing/unobserved final-list line. An observed empty `Writing supported drivers to registry:` line SHALL be represented as a valid zero-selection observation, not as parser failure or missing evidence.

When a candidate `SETxxx` property is observed but is absent from the observed final supported list and no explicit AMD removal event is present, the toolkit SHALL retain an implicit-removal record. The host-analysis comparison SHALL expose this as unresolved unless a matching exact-binary compiled selector contract provides a code-level silent-removal rule. A compiled explanation SHALL NOT erase the original dynamic implicit-removal evidence; it changes only the interpretation/comparison status.

Verbose MSI observations SHALL classify the primary top-level transaction. `ACTION=ADMIN` SHALL be recorded as `AdministrativeExtraction`. Feature `Request: Local` in an administrative extraction SHALL NOT be interpreted as AMD install selection, and Device_ID-vs-ADDLOCAL consistency SHALL be marked not applicable unless an actual ADDLOCAL selection transaction is separately observed.

For live Windows host analysis, OS `ProductType` SHALL come from the host OS/CIM data. For non-Windows replay, observed `MsiNTProductType` SHOULD take precedence when available; caption-derived ProductType SHALL be labeled as a heuristic.

Evidence levels SHALL distinguish direct AMD declarative evidence, exact-binary compiled static evidence, static inference, single-host dynamic observation, and multi-host dynamic observation. A rule reconstructed from one machine SHALL NOT silently become a global AMD contract. A multi-host rule SHALL remain scoped to the release/host-class actually observed unless the underlying declarative or compiled predicate is recovered. Compiled rules SHALL themselves remain scoped to the selector-binary SHA-256 unless a later cross-version comparison proves equivalence.

For the exact 8.07.16.1035 Qt selector contract, the host emulator MAY use the recovered `/SETRYZENPPKG` candidate gate only when the selector SHA-256 matches the vetted binary. The compiled gate requires a `DEV_790B` device context and then accepts either the CPU Family 23 / Model 160 special path or revision token `REV_61`, `REV_59`, or `REV_51`. Candidate creation SHALL remain separate from subsequent `Info.xml` OS/product filtering.

The toolkit SHALL preserve unresolved vendor differences. If PnP/AMD metadata predicts selection but the observed AMD list disagrees and no defensible filter is found, the result SHALL remain an unresolved selector mismatch.

### D8 Inventory build


Build SHALL emit one canonical **Per-release Raw JSON** object for every installer version present in the run. The path convention SHALL be `inventory/releases/<version>/amd-chipset-analysis-<version>.json`. The release object SHALL preserve artifact identity, extraction/metadata references, complete DriverPackages including INF topology, Server static analysis and the host-profile definitions used by that analysis.

Build SHALL also emit derived per-release Markdown reports and a device/HWID/Server compatibility CSV/Markdown matrix. Derived reports SHALL be reproducible from canonical JSON and SHALL NOT be the authoritative data source.


Canonical output:

```text
inventory/amd-chipset-driver-inventory.json
```

Derived outputs:

```text
inventory/amd-chipset-driver-inventory.csv
reports/amd-chipset-driver-history.md
```

Deployment compatibility policy SHALL NOT be hard-coded into the canonical research inventory. The toolkit MAY contain explicit Windows Server 2016/2019/2022/2025 **static analysis profiles** for reproducible TargetOSVersion/Models selection and WDF reference comparison, provided the output is labeled static/non-runtime analysis and preserves the original INF evidence.

## 7. State vocabulary

Network/artifact states SHOULD use explicit values such as `Discovered`, `Fetched`, `FetchFailed`, `Downloaded`, `DownloadFailed`, `Extracted`, `ExtractionFailed`, `Inspected`, `ParseFailed`, `NotDeclared`, and `NotInspected`.

`null` SHALL represent absence/unknown data only when paired with a status that describes why it is null.

## 8. WDF model

Canonical INF requirement representation SHALL preserve the declared framework, version and raw INF evidence. No server compatibility SHALL be inferred from `NotDeclared`.

## 9. Release identity

AMD release identity SHALL use the four-part chipset installer version string when available, e.g. `7.11.26.2142`.

The parser SHALL accept dot-separated and hyphen-separated forms when extracting a version from URLs/titles. Release-note URL is provenance, not identity.

If a URL contains multiple four-part version tokens, the parser SHALL prefer the final/leaf-side token. This is required for AMD URLs such as the currently published 7.02.13.148 release-note path that contains an older 6.10.17.152 version in a parent segment.

Discovery output SHALL normalize alternate URLs to one canonical record per four-part release identity. Alternate URLs and their discovery sources SHOULD remain available in diagnostics so deduplication does not discard provenance. Operator-supplied URLs SHOULD take precedence over curated seed URLs, which SHOULD take precedence over sitemap-discovered aliases.

## 10. Raw evidence retention

Raw AMD release-note HTML SHOULD be retained. Downloaded AMD installers MAY be retained locally as evidence but SHALL NOT be committed or redistributed unless licensing explicitly permits it.

The repository SHOULD commit metadata and inventory, not AMD binary payloads.

## 11. Reproducibility

Each canonical inventory SHALL contain schema version, toolkit version, generated UTC timestamp, input artifact SHA-256 values where available, source URLs, parser/extractor status, and SHOULD embed the most recent `inventory/environment.json` evidence when available.

A future parser SHALL be able to re-run against preserved evidence without requiring the original AMD page to remain online.

## 12. Failure policy

Individual release fetch/download/extraction failures SHALL be captured and processing SHOULD continue for other releases. Best-effort sitemap XML failures SHALL be summarized compactly; response bodies SHALL NOT be embedded verbatim in console exception text.

Fatal errors include unreadable canonical input files, invalid required schema structure, and output path collisions that would destroy unrelated data.

## 13. Security

The toolkit SHALL never invoke downloaded AMD EXEs, invoke MSI installation, call `pnputil`, import certificates, or modify driver store / Code Integrity policy.

Extraction is analysis, not installation.

## 14. Cross-platform invariants

Windows and Linux runs SHALL produce the same canonical research concepts for equivalent input artifacts. Platform-specific fields MAY differ only where the evidence itself is platform-specific, such as extractor path or PowerShell edition.

The canonical WDF requirements SHALL continue to come from INF declarations; running the parser on Linux SHALL NOT change KMDF/UMDF interpretation.

## 15. Windows Server static-analysis contract

The canonical static profiles are x64 ProductType 3 profiles for Windows Server 2016 build 14393, Server 2019 build 17763, Server 2022 build 20348 and Server 2025 build 26100. Generic profiles SHALL NOT assume Standard-vs-Datacenter SuiteMask. A SuiteMask-restricted TargetOSVersion therefore SHALL remain review/indeterminate unless an edition-specific profile is intentionally supplied later.

Static applicability states SHALL NOT be called runtime compatibility. At minimum, reports SHALL distinguish native applicability, ProductType projection candidates, explicit exclusion, build/product-type non-applicability, suite-dependent review, and WDF-reference review.

WDF comparison in 1.1.0 SHALL use the maximum parseable INF-wide declared KMDF/UMDF version as a conservative requirement. The output SHALL label this scope. Per-DDInstall WDF scoping is reserved for the planned Chipset/Graphics INF-analysis sync and MAY replace the conservative model only after regression evidence demonstrates equivalent or better correctness.

Host WDF references SHALL preserve `Documented` and `Observed` concepts separately. In particular, Server 2025 MAY carry the project-observed KMDF 1.35 reference while retaining the Microsoft-published 1.33 reference; the observed value SHALL NOT silently overwrite documentation provenance.

## 16. Per-release analysis data contract

The release-analysis schema SHALL be versioned independently (initial value `amd-chipset-driver-release-analysis/2.1`). Raw decoration strings, raw Manufacturer/Models evidence, INF SHA-256, installer SHA-256 and toolkit/schema version SHALL be retained sufficiently to support later reinterpretation and audit.

One release JSON SHALL map to exactly one AMD installer release identity. Alternate release-note URLs MUST NOT create duplicate release-analysis files.

Per-release canonical JSON SHALL be repository-portable. Machine-local absolute paths MUST be converted to stable logical paths (or otherwise removed), and full extractor console logs SHALL remain in run-scoped Evidence rather than being duplicated into Git-tracked release JSON.

## 17. Chipset/Graphics sync boundary

Before this development line is finalized, the project SHOULD compare the Chipset INF topology schema with the concurrently developed AMD Graphics INF parser. Candidate shared concepts are TargetOSVersion parsing, Manufacturer-line selection, Models entry representation, Server profile IDs, status vocabulary and evidence/provenance fields. PowerShell code MAY remain duplicated in each single-file tool; a shared PowerShell module is not required. Stable non-PowerShell schema conventions SHOULD be aligned where practical.

## 18. AMD selector and host-analysis contract

AMD-specific selection analysis SHALL be represented separately from INF/PnP applicability.

Recommended evidence vocabulary:

- `AmdDeclarativeProven`
- `AmdCompiledStaticProven`
- `AmdStaticInferred`
- `AmdDynamicObservedSingleHost`
- `AmdDynamicObservedMultiHost`
- `EmulationConfirmed`
- `ObservedFilterExplained`
- `ObservedFilterExplainedByCompiledRule`
- `ObservedFilterExplainedByStaticInference`
- `ObservedSelectionNotEmulated`
- unresolved selector status

An evidence-level label describes the strength/source of the reasoning, not install/runtime compatibility.

Host-specific data SHALL remain private/runtime Evidence and SHALL NOT be copied into the generated `public/**` surface. Release-static AMD selector findings and artifact-derived Raw JSON MAY be published only through the toolkit publication contract because they are properties of the installer artifact rather than the test host.

The qualification set for AMD Chipset Software 8.07.16.1035 SHALL include: (1) the supplied Windows 11 positive host, whose observed final features and MSI `ADDLOCAL` resolve to `GPIO3,PCI,PSP,SMBUS,GPIO2,RYZENPPKG`; (2) Windows Server 2022 build 20348, which detects UPEP/I2C/PSP/SMBus/GPIO2/RyzenPPKG and other candidates but emits an explicitly empty final supported list; and (3) Windows Server 2025 build 26100, which detects a different AMD candidate set but also emits an explicitly empty final list. Server qualification SHALL compare decision traces, not merely the final count.

For the exact 8.07.16.1035 Qt `Setup.exe` SHA-256 `9b8411b3f77312a770bdac35756081e77c74fb22b7c4c4f367db4f6e5ddf5462`, the toolkit MAY use the vetted compiled-selector contract: the internal OS-family field starts at `-1`; `Win32_OperatingSystem.Caption` substring matches map Windows 7/10/11 to enum `0/1/2`; the x64 Client `Info.xml` branch maps only those enum values to Client OS labels; enum `-1` appends no Client product. Thus the supplied Server 2022/2025 captions are explained by the compiled caption classifier rather than a guessed `ProductType==3` test. The same contract MAY explain the silent `SETFILTERUSB` removal through its `DEV_790B`/`DEV_780B` + `REV_16` prerequisite. Both rules SHALL remain exact-binary scoped. Release-specific empirical rules such as Ryzen PPKG reconstruction MUST remain narrowly scoped until a declarative or compiled predicate is recovered.

## 19. Future tools

Other research families SHOULD use the same repository placement rule:

```text
tools/<tool-name>/
```

Examples include AMD graphics and NPU driver research. Each tool SHOULD remain self-contained. Shared PowerShell modules SHOULD NOT be introduced merely for code reuse; the repository preference is aggregation. Shared non-PowerShell schemas or data conventions MAY be considered later if multiple tools demonstrate a stable need.

## 20. Cross-platform stage argument contract

`-Stages` MUST accept both native PowerShell string arrays and comma-separated values passed through `pwsh -File` from POSIX shells. Omitting `-Stages` MUST resolve to the full pipeline.

## 21. Evidence-run contract

Every invocation SHALL initialize a run-scoped evidence session before resolving or executing requested stages. Evidence collection is part of the research workflow, not a separate helper script.

The evidence run SHALL record at minimum:

- toolkit version and evidence schema version;
- executing script path and SHA-256 when obtainable;
- invocation parameters and selected platform;
- console transcript when supported, with `TranscriptStarted` reflecting the post-attempt state;
- per-stage start/end time, duration, status and error details in `stage-results.json`;
- final assessment and exit code;
- snapshots of generated inventory and reports;
- extraction/download diagnostic logs;
- external artifact metadata including installer SHA-256 without requiring installer bytes in the ZIP;
- per-file SHA-256 manifest for the final evidence directory.

Evidence finalization SHALL be attempted from top-level `finally` processing so a stage exception does not normally prevent creation of a troubleshooting bundle. ZIP failure SHALL NOT delete the loose evidence directory or mask an earlier research error.

Default status contract:

- exit 0: successful/complete research outcome;
- exit 2: evidence exists but the run requires review because one or more selected stages/results are incomplete or failed;
- exit 1: fatal top-level error.

AMD installer binaries SHALL be excluded from the evidence ZIP by default. `-IncludeInstallersInEvidence` MAY opt in to copying them. Extracted working trees SHALL remain external and SHALL be represented through manifests/logs rather than copied wholesale.

## 22. Deep static extraction contract

Real AMD installers MAY contain executable container layers that 7-Zip alone cannot directly recurse into. The tool SHALL recognize supported static inner-container formats without executing them.

For observed AMD 3.x through 8.x packages, the implementation SHALL support InstallShield `ISSetupStream` types 3 and 4 sufficiently to recover embedded files such as `AMD_Chipset_Drivers.msi`. Recovered MSI/CAB/ZIP/7z containers SHALL re-enter the bounded 7-Zip recursion pipeline. Historical ZIP delivery artifacts MAY wrap a recognizable AMD outer installer EXE; such known AMD EXE containers SHALL also re-enter static 7-Zip recursion without execution so analysis can continue to the inner InstallShield/MSI/CAB/INF layers.

The implementation SHALL validate recovered MSI artifacts using the CFBF/OLE MSI signature before treating recovery as successful.

A release SHALL NOT be classified `ExtractionComplete` merely because the outer NSIS container was expanded. `ExtractionComplete` requires actual INF discovery. Zero-INF results SHALL be represented as an explicit partial/incomplete state unless absence of driver packages is independently proven.

The ISSetupStream decoder MAY be implemented in embedded C# compiled at runtime from the single PowerShell entry script. This does not violate the one-PowerShell-script rule. Third-party algorithms or source-informed implementations SHALL retain required attribution/license notices.

## 23. Embedded AMD metadata

The `Inspect` stage SHALL preserve structured metadata from embedded AMD XML sources when present.

`Info.xml` evidence SHOULD capture source path/SHA-256 and product records including component name, OS, component version, installer, brand and release flag.

`DevID.xml` evidence SHOULD capture source path/SHA-256, installer tag, raw device-ID string and normalized device-ID list.

When multiple copies exist, all source records SHALL remain available while one preferred source MAY be selected deterministically for canonical summary fields. Embedded metadata SHALL remain distinct from AMD published release-note metadata and actual INF/payload observations so later comparison can expose disagreement rather than overwrite it.

## 24. Evidence retention for iterative review

The evidence ZIP SHALL be designed to be uploaded to a reviewer or analysis system without requiring the entire extracted working tree. It SHOULD remain compact while retaining enough provenance to reproduce or diagnose each stage. The ZIP SHOULD include the exact executing tool snapshot and documentation snapshot so later review can identify the code revision that produced the evidence.

ZIP entry names SHALL use the ZIP-standard forward slash (`/`) separator regardless of the host OS. A Windows-generated evidence bundle SHALL be consumable by common Linux ZIP tools without backslash-path warnings or avoidable non-zero exit status.

## 25. Operator-facing logging and timing contract

The toolkit SHALL provide enough live progress information for an operator to understand what is being processed during long research runs without opening the generated JSON files.

Normal activity lines SHOULD use a stable shape containing local wall-clock time, elapsed time within the current stage, a compact severity/progress marker, and the message. The marker vocabulary SHALL distinguish at least normal progress, success, review/warning, failure, and informational fallback/skip conditions.

Every selected stage SHALL print a clear start header and completion footer. The completion footer SHALL include stage status and elapsed time. Long-running release-oriented stages SHALL report the release index/total, release version, and a concise per-release completion/failure message. Acquisition SHOULD include artifact size/candidate information; extraction and inspection SHOULD include useful result counts.

Evidence finalization SHALL emit a final timing summary containing total elapsed time plus a per-stage status/duration table. The console transcript SHALL contain this summary, and equivalent structured timing data SHALL be persisted in the run summary evidence.

Expected probe failures such as candidate HTTP 404 responses, retired URLs, or a sitemap endpoint returning HTML instead of XML SHALL be represented as controlled diagnostics/structured evidence. They SHALL NOT intentionally generate raw PowerShell terminating-error records merely as part of normal fallback probing, especially under Windows PowerShell 5.1 `Start-Transcript`.

## 26. Repository publication surface

The historical `accepted-baseline` snapshot model is superseded for future v2.0.0 publication by the generated `public/**` allow-list. Git history is the historical record; the main tree should expose the current reviewable dataset.

The repository-public dataset SHALL prioritize canonical per-release Raw JSON plus generated human-readable reports and integrity metadata. Host-specific evidence SHALL remain private unless separately reviewed and intentionally published.

Automation SHALL stage only `tools/amd-chipset-driver-research/public/**` for generated-data updates and SHALL independently verify publication validation and manifest hashes before commit. Source/script/schema/document changes are a separate reviewed change class.

### Device identifier classification

The semantic INF model SHALL preserve the exact Models-section `hw-id` string and SHALL additionally classify its identifier semantics. At minimum the model SHALL distinguish enumerator PnP hardware IDs, root-enumerated hardware IDs, generic hardware IDs, device-class-specific identifiers, network software component IDs, and unclassified INF model identifiers. Reports SHALL use a neutral `Device identifier` label rather than implying that every identifier is PCI/ACPI hardware. No synthetic bus hardware ID SHALL be invented when the INF does not declare one.
