# AMD Graphics Driver Research Toolkit Specification

This document defines the normative behavior of `Invoke-AmdGraphicsDriverResearch.ps1` for the v1.0.0 research/release contract. Historical implementation and qualification narratives are intentionally kept outside this specification under `reports/**`.

Normative terms **SHALL**, **SHALL NOT**, **SHOULD**, **SHOULD NOT**, and **MAY** are used in their ordinary specification sense.

## 1. Purpose and scope

The toolkit SHALL statically research AMD Windows graphics-driver publication and package structure. It SHALL support product-driven discovery/selection, immutable installer provenance, bounded static extraction, INF/WDF analysis, Windows Server selector analysis, evidence generation, and repository-safe publication.

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

Any later transformed, patched, catalog-rebuilt or self-signed package is outside this toolkit and SHALL be treated as a derived project artifact.

## 5. Stage model

### 5.1 Normal product-driven pipeline

The normal full pipeline SHALL be:

```text
Test
ProductDiscover
ProductMetadata
Select
Acquire
Extract
Inspect
Build
```

`-Stages All` SHALL select the normal full pipeline.

### 5.2 Local installer path

`-LocalInstallerPath` SHALL permit deep qualification of explicitly supplied installer artifacts without requiring product discovery.

When no incompatible explicit historical selector is supplied, stage resolution SHALL select the local research stages required to test, acquire/register, extract, inspect and build the local artifact.

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

A user-created split/archive transport envelope SHALL NOT replace the inner AMD EXE as canonical vendor artifact identity.

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
