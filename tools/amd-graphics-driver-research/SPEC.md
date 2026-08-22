# AMD Graphics Driver Research Toolkit Specification

## REV81 current release authority

This specification governs the coordinated `3.0.0` release candidate after
Claude closed Cycle B at REV80. The bounded Windows Client Gate 2G and exact
REV77 Windows Server / Windows PowerShell 5.1 `PathSafety,Test` gate are
accepted/no-repeat. REV81 changes documentation only; the executable,
contracts, schemas, reviewed data, generated `public/**`, canonical path and
accepted Evidence remain unchanged. Historical revision requirements retain
their original scope but SHALL NOT be interpreted as current pending gates.

## REV77 private Evidence execution-context contract

Every normal and emergency Evidence `run-context.json` SHALL contain one
`ExecutionContext` object. On Windows it SHALL record `ExecutionClass`,
`ProductType`, `ProductRole`, `Caption`, `Version`, `BuildNumber`,
`EvidenceScopes`, `CollectionStatus`, and `CollectionSource` from a read-only
operating-system inventory attempt. An unavailable inventory SHALL be typed and
retained rather than silently omitted. Six synthetic classification/fallback
cases SHALL run in Test. The contract SHALL remain identical across all three
research scripts.

The private Evidence schema advances to
`amd-graphics-driver-research-evidence/1.1`; executable version stays `3.0.0`.

## REV76 previous authority and release boundary

This specification governs executable version `3.0.0`. Graphics Gate 2G is
accepted against the exact current source and its generated public surface is
incorporated. The remaining Server gate is limited to `PathSafety,Test`; it
SHALL NOT be represented as product compatibility, installation/load, or GPU
runtime qualification. Umbrella revision `REV76` changes documentation,
history and generated public data but does not change the root script, schemas
or common-core contract.

## Current authority and release boundary

This specification governs executable version `3.0.0`. Umbrella revisions
such as `REV75` identify coordinated package/document evolution and do not
silently change the executable version, schemas, generated `public/**` data or
qualification scope.

Graphics Gate 2G used the bounded one-product-group, one-major-generation,
one-artifact Client E2E and is accepted/no-repeat. It exercised the normal
Build/publication and self-contained Evidence path. It SHALL NOT be cited as
all-track coverage or installed-device functional qualification.

The accepted Windows Server `PathSafety,Test` smoke establishes only the
environment, common self-test, Evidence-finalization and summary contracts for
the exact source. It SHALL NOT be cited as proof of live product discovery,
full multi-hour research/publication, driver installation, kernel load or
device function.

Ordinary research SHALL retain bounded generation coverage. Deep certificate
analysis SHALL remain newest-generation-only for each stable
product-category/OS/package-family track, with many-to-one installer identity
deduplicated without losing track provenance. Neither scope is a host driver
recommendation.

A qualification-only cross-tool launcher SHALL NOT be part of the release
surface. Any future included orchestrator requires a separately reviewed,
data-driven multi-scenario contract covering Smoke, bounded short E2E and
separately authorized full/target-host scenarios.

## rev74 cardinality requirements

- A conditional expression assigned to a collection variable that is later
  consumed through `.Count` SHALL wrap the entire expression in `@(...)`.
- `Test-AmdEvidencePublicSnapshot` SHALL remain byte-identical between Graphics
  and NPU.
- This correction SHALL NOT change product/category selection, download,
  extraction, signature targets or generated-public semantics.
- The canonical tool-local path policy SHALL remain unchanged.

## rev72 self-contained public Evidence requirements

- A successful current-run publication SHALL copy the complete validated
  `public/**` tree into private Evidence at `snapshot/public/**`.
- The Evidence finalizer SHALL compare live-public and snapshot path sets,
  sizes and SHA-256 values and SHALL reject missing, extra or byte-different
  files.
- Every public payload SHALL match exactly one declaration in
  `publication-manifest.json`; the manifest itself SHALL also be byte-identical
  between live public and the Evidence snapshot.
- Snapshot failure SHALL prevent a normal PASS Evidence archive and SHALL use
  the existing diagnostic emergency-evidence path.
- Independent release review SHALL require only the tool-generated Evidence
  ZIP and SHALL NOT require an operator-created public archive.

## rev62 cumulative baseline and publication-diagnostic requirements

- Imported historical release JSON SHALL satisfy the current Canonical JSON
  byte contract before it becomes runtime Build input.
- A legacy CRLF/BOM or other semantically valid non-canonical release JSON
  SHALL be migrated deterministically and revalidated; an invalid result SHALL
  stop before research stages consume the baseline.
- The cumulative runtime `inventory/releases/**` tree SHALL wholly replace the
  staged public release tree before validation.
- A failed public validation assessment SHALL identify privacy, Canonical JSON,
  dataset-consistency and Markdown-format status/counts independently.
- The normal Test stage SHALL cover legacy baseline Canonical JSON migration.

## rev60 public structure requirements

- Recursive public conversion SHALL preserve explicit safe null-valued properties and null array elements.
- Values rejected because they are private path fields, host-path strings, errors or invocation details SHALL remain absent.
- The normal Test stage SHALL prove both structural null preservation and nested `ArchivePath` removal.

## rev59 public-path requirements

- Canonical/public object conversion SHALL remove host-local values from every shared path-bearing property, including nested `ArchivePath`.
- The decoded-scalar public audit SHALL use the shared three-tool forbidden-pattern and traversal primitives.
- Selector, manifest and other vendor tokens SHALL NOT be rejected merely because they resemble path syntax.

## rev58 extraction path and downstream-gate requirements

Graphics SHALL use `Get-AmdShortExtractionPath` for every artifact/container directory. The startup predictor and runtime extractor SHALL therefore share the `work\\x\\aNNNN\\cNNNN` contract. Extract SHALL fail after writing diagnostic inventory when any selected release is incomplete, and Signature SHALL independently assert complete extraction input.



## rev52 interruption and Evidence portability requirements

Tracked stages SHALL remain `RUNNING` until normal body completion. An
interruption SHALL be recorded as `INTERRUPTED`, SHALL return exit code `130`,
and SHALL NOT be assessed as PASS. Private Evidence manifest relative paths
SHALL use `/` on Windows and non-Windows hosts.

If stage resolution or argument validation fails before the normal Evidence
session, the tool SHALL create Fatal Evidence when the tool-local root passes
the non-stage-specific PathSafety gate. A PathSafety-unsafe root SHALL remain a
strict no-write block and SHALL instruct the operator to move the whole tool.

## rev51 bootstrap and emergency-evidence contract

`PathSafety`/`Test`-only execution SHALL NOT copy the large public runtime
baseline. Bootstrap identity and long Test operations SHALL be visible with
elapsed time. Canonical JSON SHALL use the common accelerated runtime without
changing its byte contract. Normal-finalizer failure SHALL invoke verified
emergency ZIP/SHA-256 creation and SHALL retain raw evidence.

## Canonical JSON normative requirements (rev50)

All generated JSON MUST use the shared Canonical JSON implementation and MUST
pass `Test-CanonicalJsonFile` before publication. The byte contract is UTF-8
without BOM, LF, two-space indentation, `: ` separators, literal non-ASCII,
insertion-order properties, explicit nulls and exactly one trailing LF.

This document defines the normative behavior of `Invoke-AmdGraphicsDriverResearch.ps1` for the coordinated `3.0.0` release candidate. Historical implementation and qualification narratives are intentionally kept outside this specification under `authored/**`.

Normative terms **SHALL**, **SHALL NOT**, **SHOULD**, **SHOULD NOT**, and **MAY** are used in their ordinary specification sense.

## 1. Purpose and scope

The toolkit SHALL statically research AMD Windows graphics-driver publication and package structure. It SHALL support product-driven discovery/selection, immutable installer provenance, bounded static extraction, INF/WDF analysis, certificate/signature analysis, Windows Server selector analysis, evidence generation, and repository-safe publication.

The toolkit SHALL NOT:

- execute AMD Setup as part of research;
- install or modify drivers;
- patch INF files;
- generate or sign catalog files;
- claim AMD support for Windows Server;
- claim runtime compatibility based only on static analysis.

## 2. Repository placement and single-script policy

The runtime implementation SHALL remain a single PowerShell script:

```text
tools/amd-graphics-driver-research/Invoke-AmdGraphicsDriverResearch.ps1
```

Static data, schemas, documentation and generated output MAY exist as separate repository files.

## 3. Runtime and source encoding

The script SHALL remain compatible with Windows PowerShell 5.1 for the Windows qualification path.

The distributed `.ps1` source SHALL use:

- UTF-8 with BOM;
- CRLF line endings.

PowerShell 7 on Windows and Linux MAY be used for supported static/offline qualification paths.

## 4. Safety invariants

The toolkit SHALL treat downloaded/local AMD installers as untrusted input artifacts.

It SHALL NOT launch the AMD installer to obtain research data.

All extraction SHALL be static and bounded by configured depth/guards.

The original AMD EXE SHA-256 SHALL be preserved as immutable vendor-source provenance.

Before evidence-session creation or AMD network access on Windows, the toolkit
SHALL run a non-bypassable `PathSafety` assessment. Qualification SHALL be
blocked when the normalized tool root exceeds 100 characters, is UNC, contains
a reparse-point ancestor, uses a configured data/output root outside the tool
folder, or predicts a path beyond the conservative 240-character limit. The
tool SHALL reserve 120 characters for AMD archive-relative paths.

`LongPathsEnabled` SHALL be recorded as diagnostic evidence only. It SHALL NOT
override the path limit because native tools such as SignTool can retain
`MAX_PATH` behavior independently of the OS registry and PowerShell process.

Any later transformed, patched, catalog-rebuilt or self-signed package is outside this toolkit and SHALL be treated as a derived project artifact.

## 5. Stage model

### 5.1 Normal product-driven pipeline

The normal full pipeline SHALL be:

```text
PathSafety
Test
ProductDiscover
ProductMetadata
Select
Acquire
Extract
Inspect
Signature
Build
```

`-Stages All` SHALL select the normal full pipeline.

`PathSafety` SHALL be inserted first for every explicit stage selection.

`SignatureNative` SHALL be a purpose-specific correction stage. It SHALL verify
the current plan, extraction installer hashes, complete extracted-file SHA-256
set, existing static-analysis schema, zero parse/digest errors and installer set
before reusing `inventory/signature-analysis.json`. It SHALL then rerun only
Windows-native Authenticode/catalog/SignTool evidence through byte-identical
short aliases. `Signature` and `SignatureNative` SHALL be mutually exclusive.

Acquisition paths SHALL use `private/a/a<url-hash>.ext`; extraction paths SHALL
use `work/x/aNNNN/cNNNN`; native verification aliases SHALL use
`work/n/fNNNNNN.ext`; evidence work runs SHALL use `private/evidence/runs/r<UTC>-<8hex>` and final archives SHALL be placed directly under `private/evidence`. Original names, URLs,
SHA-256 values, product groups and selection tracks SHALL remain in mapping and
inventory evidence.

After Acquire and before Extract, the toolkit SHALL list each outer installer
with 7-Zip structured listing output, reject unsafe/rooted/traversal entries and
block extraction when any predicted output exceeds 240 characters. Each nested
container SHALL be checked again immediately before extraction.

### 5.2 Local installer path

`-LocalInstallerPath` SHALL permit deep qualification of explicitly supplied installer artifacts without requiring product discovery.

When no incompatible explicit historical selector is supplied, stage resolution SHALL select the local research stages required to test, acquire/register, extract, inspect, analyze signatures and build the local artifact.

### 5.3 Historical research

`-FullHistoricalResearch`, `-ReleaseVersion`, and `-ReleaseKey` SHALL remain explicit historical/release-catalog controls. They SHALL NOT silently replace the normal product-driven selection semantics.

### 5.4 Stage outcomes

Stage states SHALL distinguish at minimum:

- `PASS`;
- `REVIEW` / blocked condition;
- `SKIP` when downstream execution is not applicable because an upstream stage was intentionally blocked or not selected.

A publication failure SHALL be able to change the final assessment even when research stages themselves pass.

## 6. Product-driven research contract

### 6.1 Product catalog

The versioned curated catalog SHALL represent explicit **product groups**, not every AMD product model.

The catalog SHALL NOT claim complete enumeration unless a future catalog explicitly changes that coverage policy.

Product support pages MAY originate under AMD `Graphics` or `Processors` hierarchies.

### 6.2 Product identity

`ProductKey` SHALL derive from the AMD support hierarchy and identify the representative product page.

`ProductGroupKey` SHALL identify the stable research grouping unit.

### 6.3 Driver track identity

Raw published provenance SHALL retain enough information to distinguish at minimum:

- product group;
- operating-system track;
- package family;
- artifact role;
- release version;
- direct installer URL.

Historical bounded selection SHALL use a stable `SelectionTrackKey` that does not fragment one lineage merely because AMD changes an artifact-role label between releases.

### 6.4 Major-generation selection

For each selection track, the normal policy SHALL:

1. derive numeric major generations;
2. sort available major generations newest first;
3. retain the newest configured number of major generations (default three);
4. select the newest release inside each retained generation;
5. avoid synthesizing missing generations from another track;
6. globally deduplicate identical AMD EXE URLs while retaining all product/track provenance.

Selection SHALL fail closed when the selected artifact count or estimated download volume exceeds configured guards unless the operator explicitly disables the guard.

A zero-selection result SHALL fail closed.

### 6.5 Metadata completeness

Product metadata collection SHALL preserve published page fields separately rather than flattening conflicting evidence into one inferred value.

Transient web failures MAY be retried according to bounded policy. A partial unresolved metadata result SHALL NOT silently proceed as a complete baseline.

## 7. Release and artifact identity

The canonical graphics identity model SHALL separate release identity from concrete artifact identity:

```text
ReleaseKey  = PackageFamily | Branch | ReleaseVersion
ArtifactKey = ReleaseKey | FileName
```

A release MAY contain multiple sibling artifacts. `ReleaseVersion` alone SHALL NOT be used as a unique cache, analysis or overwrite key.

For qualified multi-artifact PRO Edition releases, siblings MAY share one `ReleaseKey` while `ArtifactRole`, filename and source SHA-256 distinguish artifacts.

## 8. Acquisition contract

Acquire SHALL obtain or register the original AMD installer artifact.

For each artifact it SHALL retain at minimum:

- ArtifactKey;
- file name;
- file size;
- SHA-256;
- source URL or local provenance;
- published release/product references where available.

AMD HTTP acquisition SHALL remain sequential with maximum concurrency one.
Installer transfer SHALL use bounded retry/backoff, fresh-session cache bypass
for retries, bounded `Retry-After`, `.partial` staging, byte-count
conservation, installer payload validation and atomic completion. Unsolicited
partial content and AMD `Download-Incomplete` redirects SHALL NOT be promoted
to the artifact cache. Each attempt SHALL be retained as structured,
redacted diagnostic evidence.

A user-created split/archive transport envelope SHALL NOT replace the inner AMD EXE as canonical vendor artifact identity.

## 8.1 Certificate target plan

`Select` SHALL select certificate target references from the newest selected
major generation independently for every stable `SelectionTrackKey`.
`ProductGroupKey` alone and one global Graphics version SHALL NOT be used as
the certificate selection unit.

The ordinary three-generation research corpus SHALL remain unchanged. Older
selected generations SHALL be recorded as `ExcludedByPolicy` from deep
certificate analysis, not as failures or missing artifacts.

`Acquire` SHALL resolve planned URL targets against acquired outer-installer
SHA-256 values. Byte-identical installer references SHALL execute once while
retaining every product-group, stable-track, driver-track and artifact-role
reference. `Signature` SHALL consume the resolved plan and SHALL NOT rank
releases independently.

## 8.2 Signature stage

`Signature` SHALL content-address candidate files by SHA-256 and SHALL perform
static CMS/PKCS#7, X.509, PE certificate-table and Authenticode digest analysis.
Byte-identical static files MAY be parsed once globally. Windows-native catalog
association and SignTool checks SHALL remain scoped to the concrete installer
artifact context.

Host-neutral static output MAY be published after privacy validation.
Windows-native tool output, host posture and absolute paths SHALL remain
private Evidence. The stage SHALL NOT execute AMD Setup, install certificates,
alter INF/CAT files, install a driver or claim runtime compatibility.

## 9. Static extraction contract

Extraction SHALL be bounded.

Each artifact SHALL have an independent extraction root and result.

`ExtractionComplete` SHALL require observed driver-analysis content, including at least one INF.

When a modern graphics driver analysis surface under `Packages/Drivers/**` has been reached, the extractor SHOULD stop unnecessary recursion into ordinary application MSI/helper executables.

Nested executable traversal SHALL require static evidence that the nested file is a container; filename resemblance alone SHALL NOT be sufficient.

Run-specific extraction logs and local workspace paths SHALL remain private Evidence and SHALL NOT enter canonical public-bound records.

## 10. Embedded manifest contract

When `Config/InstallManifest.json` is present, the toolkit SHALL preserve relevant embedded fields such as version/build identity, package type, package payload path and AMD condition strings.

Manifest path resolution SHALL tolerate Windows-style case-insensitive payload matching.

Embedded condition strings such as AMD `OSCheck` SHALL remain **Embedded evidence**. They SHALL NOT be silently redefined as Microsoft INF selector semantics.

## 11. Evidence-layer contract

The canonical evidence model SHALL distinguish:

- **Published** — AMD support-page/download facts;
- **Embedded** — metadata bundled in the AMD installer;
- **PayloadObserved** — files and INF content reached by static extraction;
- **Analysis** — toolkit-derived selector/topology/WDF interpretation;
- **Runtime** — target-OS execution evidence produced outside static analysis.

Derived analysis SHALL NOT overwrite the underlying evidence that produced it.

## 12. Canonical INF topology

INF analysis SHALL begin from `[Manufacturer]` references and preserve the exact relationship:

```text
Manufacturer
  -> TargetOSVersion
     -> ModelsSection
        -> Model
           -> DDInstall
           -> Identifiers
```

The parser SHALL NOT treat every `*.NT*` section as a Models section.

Empty referenced Models sections SHALL be preserved as meaningful evidence.

Identifiers SHALL NOT be limited to a fixed PCI/HDAUDIO/USB prefix list. Unknown or component/software identifiers SHALL be preserved rather than fabricated or discarded.

## 13. TargetOSVersion and Server profiles

TargetOSVersion dimensions SHALL be represented independently, including where present:

- architecture;
- major/minor OS version;
- ProductType;
- SuiteMask;
- BuildNumber.

For this project:

```text
ProductType 1 = Workstation/client
ProductType 2 = Domain Controller
ProductType 3 = Server/member server
```

BuildNumber SHALL be evaluated as a minimum build in static selector simulation.

## 14. Windows Server analysis modes

The toolkit SHALL maintain separate results for:

- `AsPublished` — vendor INF selection without modification;
- `ServerProjection` — non-mutating client ProductType 1 -> Server ProductType 3 simulation;
- `RuntimeCompatibility` — not established by static analysis.

A projected candidate SHALL NOT be represented as vendor-supported or runtime-compatible.

Static target profiles SHALL include Windows Server 2016, 2019, 2022 and 2025 according to the toolkit's versioned profile data.

## 15. Native Server control artifacts

When AMD publishes a native Windows Server graphics package, the toolkit SHALL preserve it as a high-value static control artifact.

Native Server selectors SHALL be analyzed as published. They SHALL NOT be collapsed into client-projection results.

A later Windows Server build satisfying an INF minimum build remains only a static selector candidate unless AMD publication/runtime evidence establishes broader support.

## 16. WDF evidence contract

KMDF/UMDF declarations SHALL be retained with the INF/package evidence that produced them.

Where dependency scope cannot be safely narrowed, the toolkit SHALL use the conservative INF-wide WDF scope rather than inventing a component-specific dependency.

WDF compatibility SHALL NOT be treated as sufficient runtime acceptance.

## 17. Canonical per-artifact JSON

Each analyzed artifact SHALL have a 1:1 canonical Raw Analysis JSON representation keyed by ArtifactKey/source identity.

Canonical JSON SHALL preserve evidence ordering/property semantics deterministically enough for reproducible publication.

Canonical JSON SHALL be generated compact. Publication SHALL NOT parse and reserialize canonical JSON merely to change whitespace.

When consuming PowerShell 5.1 generated JSON, known collection wrapper forms such as a `{ value: [...], Count: n }` wrapper MAY be rehydrated **on read**. The stored Raw JSON SHALL NOT be rewritten solely to hide that source representation.

## 18. Aggregate and derived views

Aggregate inventories, compatibility CSVs and Markdown reports SHALL be derived from retained canonical records.

Adding one artifact SHALL NOT cause an unrelated retained artifact to disappear from cumulative views.

Aggregate counts SHALL be cross-checked against per-artifact counts and sharded integrity data before publication.

## 19. Public/private output classification

### 19.1 Public surface

Repository-safe generated content SHALL live only beneath:

```text
public/**
```

The public surface MAY include:

- product/group catalogs and mappings;
- selection plan;
- canonical per-artifact analysis;
- aggregate inventory and Windows Server views;
- generated reports;
- repository-safe run summary;
- publication manifest and validation.

### 19.2 Private/debug surfaces

The following are not automatic generated-commit surfaces:

```text
private/**
inventory/**
reports/**
work/**
```

They MAY contain runtime paths, logs, host information, cached pages, extraction diagnostics and other operator context.

### 19.3 Privacy boundary

Before publication, canonical/public-bound objects SHALL be normalized so machine-local/runtime-private scalar values do not cross into `public/**`.

Privacy validation SHALL inspect decoded JSON scalar values so escaped Windows paths cannot bypass the check.

Run-specific log/transcript/stack/exception fields SHALL remain private where required by the publication contract.

## 20. Public Markdown byte contract

Every `.md` file under `public/**` SHALL be emitted as:

- UTF-8 without BOM;
- LF-only line endings;
- CR byte count zero.

When a runtime Markdown report is published, the transformation SHALL change only UTF-8 BOM and line-ending representation. Text content SHALL otherwise remain unchanged.

The manifest generation mode SHOULD use the cross-toolkit name:

```text
MarkdownLfNoBomFromRuntime
```

for runtime-backed Markdown.

Toolkit-authored public Markdown SHALL also satisfy the same byte contract.

## 21. JSON and CSV publication contract

Canonical JSON and CSV SHALL remain byte-faithful to their declared runtime publication sources unless a schema explicitly declares a different transformation.

JSON/CSV SHALL NOT be line-ending-normalized merely to match Markdown repository convention.

Repository integration MAY require `.gitattributes` to preserve these public bytes verbatim.

## 22. Publication transaction

Publication SHALL use a staging surface.

The publisher SHALL:

1. start from the last validated public baseline when partial-run preservation requires it;
2. overlay current generated public candidates;
3. apply declared Markdown normalization;
4. build publication metadata;
5. validate privacy, path portability, file coverage, size/hash, dataset consistency and format contracts;
6. promote the staging tree atomically only when validation passes.

A failed publication SHALL NOT replace the previous valid `public/**` surface.

## 23. Publication manifest contract

`public/publication-manifest.json` SHALL describe every public payload file except the manifest itself.

It SHALL distinguish at minimum:

- manifested entry count;
- total public file count including the manifest;
- relative path using `/` separators;
- classification;
- generation mode / transformation;
- source relative path when source-backed;
- source size and SHA-256 when source-backed;
- published size and SHA-256;
- whether a generated file was hand edited.

`HandEdited=true` SHALL NOT occur in accepted generated output.

Manifest hashes SHALL be computed from the bytes actually staged for publication.

## 24. Private Evidence contract

A normal evidence run SHALL produce private evidence sufficient to reconstruct and audit the execution without making that context public.

Evidence MAY include transcripts, host/runtime metadata, acquisition/extraction diagnostics and HTML/cache context.

For release provenance, Evidence SHALL also snapshot the exact runtime source files referenced by publication manifest `SourceRelativePath` values:

```text
snapshot/inventory/**
snapshot/reports/**
```

The snapshot bytes SHALL be the actual publication-source staging bytes, not copies of already-published files.

This SHALL allow a reviewer to recompute every source-backed `SourceSha256` from the Evidence archive alone.

The existing runtime-inventory diagnostic snapshot MAY be retained for compatibility, but it SHALL NOT be presented as a substitute for the exact publication-source snapshot.

## 25. Evidence manifest and source binding

The Evidence archive SHALL include a manifest of its archived files with size/SHA-256 values.

The Evidence run summary SHALL record the executing script SHA-256.

A release audit SHALL be able to prove:

```text
exact source script
  -> evidence ScriptSha256
     -> exact runtime publication source
        -> SourceSha256
           -> declared transformation
              -> public payload SHA-256
                 -> publication-manifest SHA-256
```

## 26. Failure policy

Failures that invalidate research completeness, artifact integrity, privacy, publication integrity or required format contracts SHALL fail closed.

The final status SHALL distinguish a completed valid publication from a research run that requires review.

Generated output SHALL NOT be manually repaired after execution. A generator defect SHALL be fixed in source and the dataset regenerated.

## 27. Exit-code contract

The process SHALL use stable non-success exit behavior for blocked/review-required outcomes and success exit code `0` only when the selected execution contract completes successfully.

Release qualification SHALL record both the final semantic status and process exit code.

## 28. Release acceptance contract

A release candidate SHALL require, at minimum:

- PowerShell AST parse without errors;
- canonical repository static-analysis gate without errors;
- built-in self-tests passing;
- Windows PowerShell 5.1 full-run qualification;
- selected/acquired/extracted/inspected artifact-chain integrity;
- zero qualified INF parse failures for the accepted run;
- aggregate/per-artifact consistency;
- privacy validation passing;
- public Markdown no-BOM/LF contract passing;
- JSON compactness contract passing;
- manifest coverage/size/hash integrity passing;
- every source-backed `SourceSha256` independently verifiable from private Evidence;
- no hand-edited generated files;
- exact source -> Evidence -> public provenance binding.

The detailed procedure is defined in `TESTING.md`.

## 29. Explicit non-goals and unknowns

The v1.0.0 contract intentionally leaves the following outside proof:

- complete enumeration of every AMD graphics product;
- complete historical branch coverage;
- runtime load/functionality of client-derived projected packages on every Windows Server version;
- semantic equivalence of AMD proprietary installer conditions and Microsoft INF selection rules;
- binary compatibility inferred only from same DriverVer or WDF version;
- future self-signed driver build/signing policy.

Those are separate research/deployment activities and SHALL remain explicitly identified as such.

## Appendix A. Non-normative future enhancement plan

The current v1.0.0 normative contract ends above and contains no `Signature`
stage. The project has recorded a future implementation plan under
`authored/GRAPHICS-SIGNATURE-AND-COMMON-HARDENING-PLAN-2026-08-17.md`.

The planned delta preserves the existing newest-three-major-generation
research contract and proposes a separate deep-certificate set containing only
the newest selected generation per stable `SelectionTrackKey`, followed by URL
and acquired SHA-256 de-duplication with complete provenance retention. It also
proposes reviewed common signature, toolchain, transport, diagnostic and
PowerShell 5.1 cardinality primitives.

This appendix does not create a v1.0.0 requirement, authorize source changes or
permit generated output to claim that Signature is implemented. A later
implementation must update the normative stage, schema, evidence, publication
and acceptance clauses through a separately reviewed version change.
## Common evidence-storage contract (rev48)

- Canonical final root: `<tool-root>\private\evidence`.
- Final archive: `Amd{Tool}DriverResearchEvidence_<UTC>_<Platform>[_<Label>].zip`.
- Integrity companion: the same path plus `.sha256`.
- Stable operator pointer: `LATEST-EVIDENCE.txt`, updated only after archive verification.
- Short raw directory: `private\evidence\runs\r<UTC>-<8hex>`.
- Default retention: `ZipOnly`; `ZipAndDirectory` is the explicit diagnostic-retention option.
- Storage boundary: no evidence data may be written outside the tool folder. External, UNC, SUBST-backed, or reparse-point destinations are fail-closed before network research.
- Archive failure retains the raw directory and does not replace the latest-success pointer.
## rev57 common infrastructure requirements

- The path-safety, archive-entry, diagnostic, emergency-evidence, ordinal-ordering, and common-core contract functions are shared source with Chipset and NPU.
- `data/current-three-tool-common-core-contract.json` is the current parity authority.

The per-artifact INF topology contract
`schemas/inf-topology.schema.json` (`amd-inf-topology/1.1`) and the aggregate
collection contract `schemas/inf-topology-collection.schema.json`
(`inf-topology-collection/2.0`) are separate schema families. Validators SHALL
select the schema by `SchemaVersion`/`$id` and SHALL NOT pair the aggregate
`public/inventory/inf-topology.json` with the per-artifact schema by filename.
- Graphics product discovery, generation/category selection, and certificate-target adapters remain tool-specific.
- Unsafe-root bootstrap failures SHALL NOT create emergency evidence outside the accepted tool-local path policy.
