# AMD Graphics Driver Research Toolkit Testing Guide

This document defines how to verify the v1.0.0 contract in `SPEC.md`. It separates source/static gates, research-stage correctness, Windows full-run behavior, publication safety, Evidence provenance and final release acceptance.

## 1. Test principles

A valid release requires all of the following independent properties:

1. **Source correctness** — script parses and passes repository static analysis.
2. **Research correctness** — product selection, artifact acquisition/extraction and INF/WDF/Server analysis behave as specified.
3. **Artifact-chain integrity** — the same selected artifacts and source hashes survive Acquire -> Extract -> Inspect -> Build.
4. **Publication safety** — only repository-safe data reaches `public/**`.
5. **Publication byte correctness** — Markdown, JSON and CSV obey their distinct byte contracts.
6. **Provenance** — a third party can verify source -> Evidence -> runtime source -> published artifact identities.
7. **Automation safety** — a repository workflow can commit generated `public/**` without committing private/runtime state.

A research-stage PASS does not override a publication failure.

## 2. Output classifications

| Surface | Purpose | Generated commit target |
|---|---|---:|
| `public/**` | Validated repository-safe generated output | **Yes** |
| `private/evidence/**` | Private execution/audit evidence | No |
| `inventory/**` | Runtime staging and canonical analysis | No |
| `reports/**` | Runtime report staging + retained historical reports | No automatic generated commit |
| `work/**` | Downloads/extraction/temp workspace | No |
| `data/**`, `schemas/**`, source/docs | Static repository content | Explicit source changes only |

## 3. Source preflight

### 3.1 PowerShell AST

Parse the exact candidate source with the supported PowerShell version used for release audit.

Expected:

```text
AST parse errors = 0
```

### 3.2 Canonical PSA

Run the repository-maintained `quality-tools/powershell-static-analyzer/psa.py` with the repository `.psa.config.json`.

Release gate:

```text
PSA errors = 0
```

Warnings MAY remain if they are documented/non-blocking according to repository policy.

### 3.3 Encoding / line endings

Verify the `.ps1` source is:

```text
UTF-8 with BOM
CRLF throughout
bare LF = 0
```

### 3.4 Built-in Test

```powershell
.\Invoke-AmdGraphicsDriverResearch.ps1 -Stages Test
```

All built-in self-tests SHALL pass.

The v1.0.0 release candidate SHALL include coverage for at least:

- product/selection semantics;
- INF identifier taxonomy/topology;
- Windows Server selector logic;
- WDF vocabulary;
- supported generated-JSON rehydration;
- decoded-scalar privacy scanning;
- canonical compact JSON;
- portable path/publication manifest rules;
- public Markdown LF/no-BOM normalization.

## 4. Product-selection preview

Before a network-heavy full run, the operator MAY validate product discovery/metadata/selection only:

```powershell
.\Invoke-AmdGraphicsDriverResearch.ps1 `
  -Stages ProductDiscover,ProductMetadata,Select
```

Review:

```text
inventory/products.json
inventory/product-groups.json
inventory/product-driver-mapping.json
inventory/selection-plan.json
```

Acceptance checks:

- declared curated scope is explicit;
- product metadata completeness is `Complete` before default Acquire;
- newest configured major generations are selected per stable selection track;
- newest release inside each selected generation is chosen;
- identical AMD EXE URLs are globally deduplicated;
- product/track provenance remains preserved after deduplication;
- artifact count/download-size guards are satisfied;
- unresolved AMD page failures do not silently become a complete baseline.

## 5. Metadata failure-policy regression

Qualification SHOULD cover transient and terminal AMD page responses separately.

Expected policy includes:

- bounded retry/backoff for transient 403/429/selected 5xx conditions;
- no uncontrolled retry storm for terminal 404 conditions;
- request pacing;
- same-group alternate official support page recovery where configured;
- preservation of effective URL/retry/fallback provenance;
- Previous Drivers attempt for qualified product groups even when appropriate latest-page fetch fails;
- `MetadataCompleteness=Partial` and default Acquire block when required coverage remains unresolved.

## 6. Representative local-artifact regression

Use a known AMD installer without live discovery:

```powershell
.\Invoke-AmdGraphicsDriverResearch.ps1 `
  -LocalInstallerPath 'D:\Artifacts\amd-installer.exe'
```

Acceptance checks:

- AMD installer is never executed;
- static extraction reaches the INF-bearing graphics surface;
- qualified INF parse failures remain zero;
- embedded manifest paths resolve as expected;
- per-artifact shard integrity passes;
- Build aggregate integrity passes;
- Windows Server analysis remains static/non-runtime;
- final publication passes unless explicitly disabled.

The Adrenalin 26.7.1 artifact is a useful regression control because it exercises a modern 7z SFX, a substantial INF set, embedded manifest data and WDF declarations.

## 7. Windows PowerShell 5.1 full-run qualification

The final release candidate SHALL be run on Windows PowerShell 5.1 using the normal full product-driven pipeline:

```powershell
.\Invoke-AmdGraphicsDriverResearch.ps1 -Stages All
```

Record at minimum:

- PowerShell version;
- selected stage list;
- overall status and process exit code;
- product/group counts;
- published driver metadata count;
- selected unique artifact count;
- Acquire/Extract/Inspect counts;
- INF records and parse-failure count;
- Windows Server applicability row count;
- publication validation status;
- public manifest identity.

### 7.1 Artifact-chain checks

The selected ArtifactKey set SHALL equal the successfully acquired/extracted/inspected set for an accepted run.

Acquisition source SHA-256 values SHALL agree with extraction provenance.

Per-artifact driver counts SHALL agree with Build indexes and aggregate summaries.

## 8. Public repository surface verification

A successful full publication SHOULD contain, as applicable:

```text
public/publication-validation.json
public/publication-manifest.json
public/run-summary.json
public/run-report.md
public/inventory/**
public/reports/**
```

The exact file set is authoritative only through the publication manifest and dataset consistency rules; tests SHALL NOT require stale optional files from a stage that did not run.

## 9. Privacy verification

`publication-validation.json` SHALL report:

```text
Status = Pass
PrivacyStatus = Pass
PrivacyErrorCount = 0
```

Independent release qualification SHOULD search public output for concrete identifiers extracted from the private Evidence, not only generic patterns.

Include at least:

- host work root;
- evidence/run path;
- local 7-Zip/tool path;
- run ID;
- user-profile paths if present;
- UNC paths if present;
- processor/device-instance identifiers if private Evidence contains them;
- credentials/private-key/access-key patterns.

Decoded JSON scalar values SHALL be examined so an escaped Windows path cannot evade the test.

Vendor data such as AMD relative paths or MSI properties SHALL not be classified as private merely because they contain separators or `C:\`-like text unless they are actual host-specific values.

## 10. Public Markdown byte gate

Every `.md` file under final `public/**` SHALL satisfy:

```text
UTF-8 BOM = absent
CR byte count = 0
line endings = LF only
```

Runtime-backed Markdown manifest entries SHALL use the declared Markdown transformation mode, normally:

```text
MarkdownLfNoBomFromRuntime
```

Independent verification SHALL reconstruct each published runtime-backed Markdown file by:

1. reading the corresponding Evidence `snapshot/reports/**` source bytes;
2. stripping a UTF-8 BOM if present;
3. converting CRLF and lone CR to LF;
4. comparing the resulting bytes to the public file.

There SHALL be no other content change.

## 11. JSON contract verification

Every final public JSON file SHALL parse successfully.

Canonical JSON files SHALL contain no JSON-structural pretty-print whitespace beyond the allowed terminal line ending used by the generator.

Publication SHALL NOT parse/reserialize canonical JSON simply to alter whitespace.

PowerShell 5.1 collection-wrapper compatibility SHALL be tested on read without changing stored Raw JSON identity.

## 12. JSON/CSV byte-faithfulness

For manifest entries declared as byte-copy from runtime source:

1. locate the exact source in private Evidence `snapshot/inventory/**` or `snapshot/reports/**`;
2. recompute `SourceSha256`;
3. verify it equals the manifest;
4. compare source bytes to published bytes where the declared transformation is byte-copy;
5. verify published size/SHA-256 against the manifest.

Expected mismatches for accepted JSON/CSV byte-copy entries:

```text
0
```

## 13. Publication manifest verification

For every manifested public payload:

- relative path uses `/`;
- the file exists;
- no unexpected extra/omitted file exists;
- published size matches;
- published SHA-256 matches;
- classification is correct;
- `HandEdited` is not true;
- generation/transformation mode matches observed bytes;
- source-backed entries have verifiable `SourceRelativePath` / `SourceSha256`.

The manifest itself SHALL be externally hashed/reference-bound by private Evidence for release audit.

## 14. Evidence provenance verification

The private Evidence ZIP SHALL contain at least:

```text
run-summary.json
evidence-manifest.json
snapshot/tool/Invoke-AmdGraphicsDriverResearch.ps1
snapshot/public-publication-reference.json
snapshot/inventory/**
snapshot/reports/**
```

Verify:

- Evidence manifest: missing/hash/size mismatch = 0;
- snapshot source script SHA-256 equals supplied candidate source;
- `run-summary.json` `ScriptSha256` equals the same source SHA-256;
- private public-manifest reference equals the actual final public manifest SHA-256;
- every publication `SourceSha256` is recomputable from the exact Evidence source staging.

## 15. Dataset consistency verification

Recompute counts from primary public artifacts rather than trusting summary text.

At minimum compare:

- selected artifact count;
- per-artifact canonical document count;
- per-artifact driver count sum;
- aggregate driver count;
- compatibility CSV row counts;
- product group count;
- selection-plan artifacts vs Build artifacts.

Set differences and count mismatches SHALL be zero for the accepted dataset.

## 16. Publication fail-closed regression

Inject or simulate an invalid private marker/format condition in a controlled test.

Verify:

1. publication validation reports review/failure;
2. final status is not a successful publication;
3. invalid staging is not promoted;
4. previously validated `public/**` remains intact.

## 17. Partial-run preservation

A selected partial stage run SHALL NOT delete unrelated validated public data from a previous full run.

Publication staging MAY begin from the retained public baseline, overlay current outputs, and then validate the complete staged surface.

Dataset consistency SHALL only require artifacts that the selected run legitimately claims to have produced.

## 18. Fresh-checkout reconstruction

Qualification SHOULD test a clean repository-like state where runtime staging is absent but the retained `public/**` baseline exists.

Verify that Build-capable workflows can rehydrate the required canonical baseline without relying on host-private state.

Known Windows PowerShell 5.1 collection wrappers SHALL be handled during consumption.

## 19. Debug-only publication controls

### `-SkipPublicExport`

A debug/evidence run MAY skip public export explicitly. The final assessment SHALL not falsely claim a completed public publication.

### `-PublicOutputRoot`

A custom public root SHALL obey the same privacy, manifest, Markdown and dataset consistency contracts as the default root.

## 20. Release acceptance checklist

A v1.0.0 release candidate is ready for external final audit only when all required gates below pass:

- [ ] exact source SHA-256 recorded
- [ ] PowerShell AST errors = 0
- [ ] canonical PSA errors = 0
- [ ] script UTF-8 BOM + CRLF contract passes
- [ ] built-in Test passes
- [ ] Windows PowerShell 5.1 full run passes
- [ ] overall status = Pass
- [ ] exit code = 0
- [ ] selected/acquired/extracted/inspected artifact sets are consistent
- [ ] qualified INF parse failures = 0
- [ ] Build shard/aggregate integrity passes
- [ ] publication validation = Pass
- [ ] privacy errors = 0
- [ ] dataset consistency errors = 0
- [ ] final public Markdown BOM count = 0
- [ ] final public Markdown CR count = 0
- [ ] all final public JSON parses
- [ ] canonical JSON compactness violations = 0
- [ ] publication manifest missing/extra/hash/size mismatches = 0
- [ ] `HandEdited=true` count = 0
- [ ] every source-backed `SourceSha256` verifies from Evidence `snapshot/inventory/**` / `snapshot/reports/**`
- [ ] JSON/CSV declared byte-copy entries are byte-identical to Evidence source staging
- [ ] runtime-backed Markdown equals Evidence source after BOM/EOL normalization only
- [ ] Evidence manifest mismatches = 0
- [ ] Evidence snapshot script SHA equals supplied source and run-summary `ScriptSha256`
- [ ] private Evidence public-manifest reference equals final public manifest SHA
- [ ] generated artifacts were not manually edited

If a generated artifact fails any gate, fix the toolkit and regenerate the complete affected dataset. Do not post-process release output.
