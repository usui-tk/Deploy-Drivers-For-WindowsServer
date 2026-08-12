# AMD Chipset Driver Research Toolkit Specification

This document defines the normative behavior of `Invoke-AmdChipsetDriverResearch.ps1` for the v2.0.0 research/release contract. Historical implementation and qualification narratives are intentionally kept outside this specification under `reports/**`.

Normative terms **SHALL**, **SHALL NOT**, **SHOULD**, **SHOULD NOT**, and **MAY** are used in their ordinary specification sense.

## 1. Purpose and scope

The toolkit SHALL statically research AMD Ryzen Chipset Software publication, artifact structure, INF/WDF semantics, AMD selector behavior, and Windows Server applicability.

It SHALL support:

- release discovery and metadata provenance;
- immutable vendor-artifact identity;
- bounded static extraction;
- INF semantic/topology analysis;
- Windows Server static selector analysis;
- WDF evidence evaluation;
- AMD declarative/binary selector evidence;
- optional read-only host survey and observed-log comparison;
- private Evidence capture;
- repository-safe generated publication.

The toolkit SHALL NOT:

- execute AMD Setup as part of research;
- install or modify drivers;
- patch INF files;
- generate/re-sign catalog files;
- install trust certificates;
- claim AMD support for Windows Server;
- claim runtime compatibility based only on static analysis.

## 2. Repository placement and single-script policy

The runtime implementation SHALL remain a single PowerShell script:

```text
tools/amd-chipset-driver-research/Invoke-AmdChipsetDriverResearch.ps1
```

Static data, schemas, documentation, public generated data, and historical reports MAY exist as separate repository files.

The top-level Markdown contract SHALL consist of:

```text
README.md
SPEC.md
TESTING.md
RESEARCH-NOTES.md
CHANGELOG.md
PUBLICATION-POLICY.md
THIRD-PARTY-NOTICES.md
```

One-off design/qualification narratives SHOULD live under `reports/**`, not the tool top directory.

## 3. Runtime and source encoding

The Windows qualification path SHALL remain compatible with Windows PowerShell 5.1.

The distributed `.ps1` SHALL use:

- UTF-8 with BOM;
- CRLF line endings.

PowerShell 7 on Windows and Linux MAY be used for supported static/offline qualification paths.

Public generated Markdown SHALL use UTF-8 without BOM and LF-only line endings.

## 4. Safety invariants

Downloaded/local AMD artifacts SHALL be treated as untrusted input.

The toolkit SHALL NOT launch an AMD installer to obtain research data.

Static extraction SHALL be bounded by configured depth/guards and content-aware container probes.

Recovered MSI databases MAY be opened read-only through Windows Installer COM on Windows. The toolkit SHALL NOT install MSI packages.

INF inspection, host survey, and selector comparison SHALL be read-only.

The original AMD vendor artifact SHA-256 SHALL remain immutable source provenance.

Any transformed, patched, catalog-rebuilt, or self-signed package is outside this toolkit and SHALL be treated as a derived project artifact.

## 5. Stage model

### 5.1 Normal pipeline

The normal full Windows pipeline SHALL be:

```text
Test
Discover
Metadata
Acquire
Extract
Inspect
Selector
HostSurvey
HostMatch
Build
```

`-Stages All` and the default no-stage invocation SHALL resolve to the normal workflow, subject to platform/applicability rules.

### 5.2 Static-only execution

`-SkipHostAnalysis` SHALL omit host-specific survey/match behavior without changing artifact-level static analysis.

### 5.3 Explicit release selection

`-ReleaseVersion` MAY pin one or more releases. A release-audit run SHOULD pin the intended release set so vendor website changes cannot silently change the dataset.

### 5.4 Observed installer evidence

`-ObservedAmdDeviceIdLog`, `-ObservedAmdMsiLog`, and `-ObservedAmdReleaseVersion` MAY supply external qualification evidence. The toolkit SHALL NOT execute the AMD installer to obtain those logs.

### 5.5 Stage outcomes

Stage states SHALL distinguish at minimum:

- `PASS`;
- `REVIEW` / `FAIL` where a selected stage cannot meet its contract;
- `BLOCKED` when an upstream prerequisite failed or was not available;
- `SKIP` where a stage is intentionally not applicable/not selected.

A publication failure SHALL be able to change final assessment even when research stages pass.

## 6. Environment test contract

The Test stage SHALL record/validate enough information to determine research readiness, including:

- platform family;
- OS/process architecture;
- PowerShell version/edition;
- 7-Zip availability;
- metadata/acquisition readiness where applicable;
- extraction readiness;
- internal self-tests.

Internal self-tests SHALL include regression coverage for:

- exact compiled-selector contracts;
- localized architecture normalization;
- Windows Installer COM table/row projection behavior;
- MSI evidence-quality assessment;
- portable path normalization/token fidelity;
- publication privacy/manifest/path contracts;
- PowerShell 5.1 collection-wrapper handling.

A failed required self-test SHALL fail Test readiness.

## 7. Release discovery and metadata contract

### 7.1 Release identity

The canonical chipset release identity SHALL be the four-part AMD Chipset Software version.

Release-note URLs SHALL be provenance, not identity. If one AMD URL contains multiple version-like tokens, the parser SHALL retain enough diagnostics to explain which version became the release identity.

### 7.2 Discovery

Discovery MAY combine:

- curated seed releases;
- AMD site/sitemap evidence;
- explicit operator URLs.

Duplicate URLs/records referring to the same release SHALL be normalized without losing alternate-source provenance.

### 7.3 Metadata

Metadata SHALL retain AMD publication facts separately, including where available:

- release-note URL/title/article identity;
- retrieval timestamp;
- page/content SHA-256;
- candidate artifact URLs;
- parser/fetch diagnostics.

Published metadata SHALL NOT be silently overwritten by embedded/payload observations when they disagree.

## 8. Acquisition contract

Acquire SHALL obtain/register the original AMD artifact without executing it.

For each release it SHALL retain enough provenance to identify:

- version;
- file name;
- file size;
- SHA-256;
- source URL/provenance;
- transfer/result diagnostics.

The implementation SHALL detect HTML/error responses masquerading as binary downloads where practical.

A user-created transfer archive SHALL NOT replace the inner AMD artifact as canonical vendor identity.

## 9. Static extraction contract

Extraction SHALL be bounded and recursive only where static evidence justifies recursion.

Observed container families include:

- historical ZIP delivery;
- outer executable container;
- Qt selector/XML assets;
- InstallShield `ISSetupStream` inner installer payload;
- MSI;
- CAB;
- INF/SYS/CAT/XML payload.

The in-script static InstallShield decoder MAY be informed by third-party reference implementations only where attribution/licensing is preserved.

`ExtractionComplete` SHALL require driver-analysis content such as at least one INF.

Each recovered container/file SHALL retain enough relative-path/hash provenance to reconstruct the extraction chain.

Run-specific absolute filesystem paths SHALL NOT become public artifact identity.

## 10. Embedded AMD metadata contract

The toolkit SHALL preserve embedded AMD metadata separately from published support-page facts and payload observations.

Potential evidence includes:

- `Info.xml`;
- APS XML;
- `DevID.xml` where present;
- embedded product/component records;
- OS/Brand labels;
- nested installer metadata.

Byte identity between duplicated manifests SHALL be recorded where observed; similarity SHALL NOT be assumed without hash/content evidence.

## 11. Evidence-layer contract

The canonical evidence model SHALL distinguish:

- **Published** — AMD support-page/download facts;
- **Embedded** — metadata bundled in the AMD installer;
- **PayloadObserved** — files/INF/XML reached by static extraction;
- **MicrosoftDefined** — Windows INF/PnP/WDF semantics derived from Microsoft-defined formats/rules;
- **AmdDeclarativeProven** — AMD XML/MSI declarative evidence;
- **AmdCompiledStaticProven** — exact-binary compiled selector behavior proven by static reverse engineering;
- **AmdStaticInferred** — bounded inference not promoted to compiled proof;
- **AmdDynamicObservedSingleHost** / **AmdDynamicObservedMultiHost** — observed vendor behavior from qualification fixtures;
- **Unresolved** — evidence insufficient to establish a rule;
- **Runtime** — deployment/load/functional evidence produced outside this static toolkit.

Derived analysis SHALL NOT overwrite or relabel the source evidence that produced it.

## 12. Canonical INF topology

INF analysis SHALL preserve the relationship:

```text
Manufacturer
  -> TargetOSVersion
     -> ModelsSection
        -> Model
           -> DDInstall
           -> identifiers / compatible identifiers
```

The parser SHALL NOT treat every `*.NT*` section as a Models section.

Empty referenced Models sections SHALL be retained as evidence.

Identifiers SHALL NOT be limited to a fixed PCI prefix list. Unknown/component/software identifiers SHALL be preserved rather than discarded or fabricated.

## 13. TargetOSVersion and Server profiles

TargetOSVersion dimensions SHALL be represented independently when present:

- architecture;
- OS major/minor version;
- ProductType;
- SuiteMask;
- BuildNumber.

For this project:

```text
ProductType 1 = Workstation/client
ProductType 2 = Domain Controller
ProductType 3 = Server/member server
```

BuildNumber SHALL be evaluated as a minimum build in static selector simulation where Microsoft semantics require it.

Static target profiles SHALL include Windows Server 2016, 2019, 2022, and 2025 according to versioned profile data.

## 14. Windows Server analysis modes

The toolkit SHALL maintain distinct results for:

- `AsPublished` / native INF selection;
- `ServerProjection` — non-mutating client ProductType 1 -> Server ProductType 3 analytical simulation;
- `RuntimeCompatibility` — not established by static analysis.

A projected candidate SHALL NOT be represented as vendor-supported or runtime-compatible.

AMD installer selector exclusion SHALL NOT be collapsed into INF/PnP inapplicability.

## 15. WDF evidence contract

KMDF/UMDF declarations SHALL remain attached to the INF/package that produced them.

Where dependency scope cannot be safely narrowed, the toolkit SHALL preserve conservative INF-wide WDF evidence rather than invent a DDInstall/component dependency.

No WDF requirement SHALL be invented for an INF that declares none.

WDF compatibility SHALL NOT be treated as sufficient runtime acceptance.

Installer release recency SHALL NOT be used as a substitute for package-level WDF evidence.

## 16. AMD selector static-analysis contract

AMD selector analysis SHALL remain independent from Microsoft INF/PnP analysis.

The toolkit MAY preserve:

- `Info.xml` / APS XML product lists;
- `DevID.xml` rules;
- selector binary path/hash/architecture/version;
- printable ASCII/Unicode string evidence;
- read-only MSI declarative tables;
- exact-binary compiled contracts;
- unresolved candidate/hardware predicates.

### 16.1 Exact-binary scope

`AmdCompiledStaticProven` rules SHALL be scoped to an exact selector SHA-256 and release context. Same Qt generation SHALL NOT imply same predicate.

### 16.2 Server classification

When a compiled selector's OS classifier is proven, the toolkit SHALL record the actual input and branch semantics rather than replacing them with a convenient SKU shortcut.

For qualified 7.x/8.x selectors, Client caption classification and Client-only manifest filtering explain observed Windows Server empty-list behavior. This evidence SHALL remain distinct from INF Server applicability.

### 16.3 Hardware predicates

A hardware candidate/filter predicate SHALL be promoted to `AmdCompiledStaticProven` only when code-level evidence supports the exact release/hash.

Older 3.x-6.x hardware predicates that were not proven SHALL remain `Unresolved` even if newer 7.x/8.x selectors contain a similar candidate name.

## 17. MSI declarative-analysis contract

Recovered top-level MSI databases MAY be opened read-only on Windows.

The toolkit SHALL distinguish at minimum:

- `ParsedReadOnly`;
- `ParsedWithErrors`;
- `ParseFailed`;
- `MsiNotRecovered`;
- platform-unavailable states where Windows Installer COM is not available.

Selected MSI tables MAY include `Property`, `Feature`, `Condition`, `LaunchCondition`, `CustomAction`, install sequences, and `Upgrade`.

COM method return values SHALL NOT leak into row data.

A successful parse containing all-null synthetic rows SHALL become a review condition.

`ACTION=ADMIN`/administrative extraction observations SHALL NOT be interpreted as feature installation selection.

## 18. Host survey and HostMatch contract

HostSurvey SHALL be read-only and MAY collect:

- OS caption/build/architecture;
- CPU information needed for selector qualification;
- PnP Hardware IDs / Compatible IDs;
- selected environment facts required for comparison.

Host-specific evidence SHALL remain private by default.

HostMatch SHALL compare host identifiers against analyzed INF/selector evidence without installing drivers.

Observed AMD final-list states SHALL distinguish:

- non-empty final list;
- explicitly observed empty final list;
- final list not observed.

An observed candidate that disappears without a proven explanation SHALL remain unknown/suspected rather than being explained by invention.

## 19. Canonical per-release Raw JSON

Each analyzed release SHALL have a 1:1 canonical Raw Analysis JSON representation:

```text
public/inventory/releases/<release>/amd-chipset-analysis-<release>.json
```

Canonical per-release JSON SHALL be generated compact.

Publication SHALL copy the canonical file byte-for-byte and SHALL NOT parse/reserialize it merely to change whitespace or collection shape.

Artifact-derived values such as selector tokens, MSI property values, XML paths/tokens, identifiers, and INF semantics SHALL remain byte-faithful except for explicitly defined path-bearing portability fields.

## 20. Portable-path normalization

Portable normalization SHALL be **field-scoped**, not based solely on string shape.

A string beginning with `/` SHALL NOT automatically be treated as a filesystem path.

Evidence values such as:

```text
/SETFILTERUSB
/SETRYZENPPKG
/info.xml
/DevID.xml
C:\
```

SHALL remain unchanged when they occur in non-path evidence fields.

Known execution-host path-bearing fields MAY be normalized to declared repository-portable families such as:

- `external-artifact/<leaf>`;
- `work/extracted/<release>/...`;
- `evidence/extraction-logs/...`;
- last-resort `external-path/<leaf>` for unrelated absolute paths in path-bearing fields.

The transformation policy SHALL be represented in publication metadata.

## 21. Aggregate and derived views

Aggregate indexes, CSVs, compatibility views, and generated reports SHALL be derived from canonical per-release records.

Adding or rebuilding one release SHALL NOT silently remove an unrelated retained canonical release during a partial run.

### 21.1 PowerShell 5.1 collection wrappers

Canonical per-release Raw JSON MAY retain a Windows PowerShell 5.1 serialization wrapper of the form:

```json
{ "value": [ ... ], "Count": n }
```

because the Raw JSON is primary evidence.

Tool-generated **aggregate** views SHALL project a recognized wrapper to a plain JSON array when:

- the object has the expected wrapper shape;
- `value` is enumerable/collection-like;
- the observed value count matches `Count`.

A normal domain object merely containing property names `value` and `Count` SHALL NOT be rewritten.

Publication SHALL fail closed if a recognized wrapper remains in a generated aggregate where the public schema requires an array.

## 22. Public/private output classification

### 22.1 Public surface

Repository-safe generated content SHALL live only beneath:

```text
public/**
```

The public surface MAY include canonical Raw JSON, aggregates/CSVs, generated reports, run summary, publication validation, and publication manifest.

### 22.2 Private/debug/runtime surfaces

The following are not automatic generated-commit surfaces:

```text
private/**
inventory/**
reports/** generated runtime reports
work/**
evidence/** legacy location
```

Static source/docs/schemas/data remain normal explicitly reviewed source files, not unattended generated output.

### 22.3 Privacy boundary

Before publication, repository-public data SHALL be validated so host/runtime-private values do not cross into `public/**`.

JSON privacy validation SHALL inspect **decoded scalar strings** so escaped Windows paths cannot bypass validation.

Host values such as ProcessorId/device instance IDs/local tool/work paths SHALL remain private unless an explicit separate publication review approves them.

## 23. Public Markdown byte contract

Every generated `.md` under `public/**` SHALL be:

- UTF-8 without BOM;
- LF-only;
- CR byte count zero.

When a runtime Markdown report is published, the declared transformation SHALL be deterministic and SHALL NOT silently change report conclusions/content.

## 24. JSON and CSV publication contract

Canonical JSON and CSV SHALL remain byte-faithful to declared runtime publication sources unless an explicitly specified generated aggregate projection applies.

JSON/CSV SHALL NOT be line-ending-normalized merely to match Markdown convention.

Repository integration SHALL preserve generated `public/**` bytes verbatim so Git attributes do not invalidate manifest hashes.

## 25. Publication transaction

Publication SHALL use staging and fail closed.

The publisher SHALL:

1. seed from the last valid public baseline where partial-run preservation requires it;
2. overlay current generated public candidates;
3. apply only declared transformations;
4. build publication metadata;
5. validate privacy, path portability, selector-token fidelity, schema/shape, file coverage, size/hash, dataset consistency, and Markdown format;
6. promote staging atomically only on PASS.

A failed publication SHALL NOT replace the previous valid `public/**` surface.

## 26. Publication manifest contract

`public/publication-manifest.json` SHALL describe every public payload except itself.

It SHALL record at minimum:

- manifest entry count;
- total public file count including the manifest;
- relative path using `/` separators;
- classification;
- generation mode / transformation;
- source relative path when source-backed;
- source size/SHA-256 when source-backed;
- published size/SHA-256;
- `HandEdited` state;
- transformation policy;
- payload size/largest-file metrics required by the current schema.

`HandEdited=true` SHALL NOT occur in accepted generated output.

Manifest hashes SHALL be computed from the bytes actually staged for publication.

## 27. Private Evidence contract

A normal evidence run SHALL retain enough private evidence to audit execution without making that context public.

Evidence MAY include:

- transcript/logs;
- environment and host metadata;
- acquisition/extraction diagnostics;
- cached pages;
- optional vendor binaries only when explicitly requested.

For release provenance, Evidence SHALL snapshot the exact runtime source files referenced by publication manifest `SourceRelativePath` values under `snapshot/**`.

The Evidence manifest SHALL identify the exact script SHA-256 and run result.

## 28. Failure policy

The toolkit SHALL prefer `ReviewRequired`/non-zero release assessment to a silent inconsistent public baseline.

Examples requiring review/failure include:

- acquisition/extraction incompleteness;
- INF parse failures that violate the selected gate;
- unresolved current-stage producer data required by a downstream stage;
- MSI parse/quality failure on Windows where a recovered MSI is expected;
- publication privacy/path/schema/token/manifest failure;
- package conservation mismatch;
- required self-test failure.

Unknown evidence SHALL remain unknown rather than being converted to compatibility.

## 29. Exit-code contract

The toolkit SHALL distinguish successful completion, review-required/incomplete qualification, and fatal execution failure according to its current run-assessment implementation.

Release qualification SHALL require the expected success exit code recorded in `TESTING.md`.

## 30. Release acceptance contract

A repository release SHALL require all gates in `TESTING.md`, including:

- source/AST/static-analysis gates;
- internal self-tests;
- controlled Windows PowerShell 5.1 full run;
- intended release-set conservation;
- zero relevant parse failures;
- MSI quality;
- F-01 token-fidelity regression;
- per-release/CSV/aggregate consistency;
- public schema and privacy checks;
- manifest/source identity;
- private Evidence integrity;
- Git byte-identity validation;
- repository-side consumer/test updates when paths/contracts change.

Generated data SHALL NOT be accepted if it required post-run hand editing.

## 31. Relationship to downstream deployment

This toolkit SHALL remain evidence, not deployment policy.

A downstream self-signed build/deployment system SHOULD consume research evidence through an explicit decision record that links:

- AMD source release/hash;
- original INF/SYS/CAT identity;
- target hardware identifiers;
- native INF applicability;
- analytical Server projection;
- AMD selector outcome/evidence level;
- WDF requirement/decision;
- package completeness/source payload set;
- transformation applied;
- derived INF/catalog/package hashes;
- signing identity;
- target Server install/load/runtime qualification.

The downstream system SHALL NOT treat an AMD Setup empty selection as proof that an INF is incompatible, and SHALL NOT treat a static INF candidate as proof of runtime compatibility.

## 32. Explicit non-goals and unknowns

The toolkit intentionally leaves these outside its claims:

- AMD support entitlement for Server SKUs;
- kernel-mode trust/loadability of a transformed package;
- runtime device correctness/stability;
- unproven old-major hardware selector predicates;
- equivalence of AMD proprietary selector logic and Microsoft INF rules;
- guaranteed future availability of historical AMD artifacts;
- complete historical reverse engineering of every selector binary.

These boundaries SHALL remain explicit until new evidence changes them.
