# AMD Graphics Driver Research Toolkit Testing Guide

## REV81 release-state and no-rerun decision

Claude closed Cycle B at REV80. The bounded Windows Client Gate 2G is accepted
at 10/10 PASS with its complete 69-file public snapshot, and the exact REV77
Graphics source has an accepted Windows Server / Windows PowerShell 5.1
`PathSafety,Test` result at 2/2 PASS, exit `0`, manifest 19/19 exact. REV81 is
documentation-only and requires neither a Windows rerun nor the multi-hour
all-track survey. Lower revision commands remain historical reproducibility
records, not current operator actions.

## REV78 no-repeat decision

The exact REV77 Graphics Server smoke is accepted and the source is
byte-identical in REV78. Do not repeat the short smoke or bounded/full E2E for
this NPU-only contract-data correction.

## REV77 exact-source retest

Use Windows PowerShell 5.1 explicitly and keep the canonical path unchanged:

```powershell
& "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe" `
  -NoProfile -ExecutionPolicy Bypass `
  -File 'D:\Temp_AMD-Tool\Deploy-Drivers-For-WindowsServer\tools\amd-graphics-driver-research\Invoke-AmdGraphicsDriverResearch.ps1' `
  -Stages PathSafety,Test `
  -SkipPublicExport `
  -EvidenceLabel 'REV77-CycleB-WindowsServer-Graphics-ExecutionContext' `
  -EvidenceRetention ZipOnly
```

PASS additionally requires `run-context.json` to report `PSEdition=Desktop`,
Windows PowerShell 5.1, `ExecutionContext.ExecutionClass=WindowsServer`,
`ProductType` 2 or 3, `CollectionStatus=Collected`, and
`CollectionSource=Win32_OperatingSystem`. This is the decisive fix for the
REV76 Graphics REVIEW. No bounded/full Graphics E2E repetition is required.

## REV76 previous release gate

The exact bounded Windows Client Gate 2G is accepted/no-repeat: 10/10 stages,
exit code `0`, one selected Ryzen AI 400 artifact, complete native signature
coverage, and a self-contained validated public snapshot. Do not repeat the
bounded run or start the multi-hour all-track survey.

The remaining minimum-sufficient Windows Server command is:

```powershell
Set-Location 'D:\Temp_AMD-Tool\Deploy-Drivers-For-WindowsServer\tools\amd-graphics-driver-research'
.\Invoke-AmdGraphicsDriverResearch.ps1 `
  -Stages PathSafety,Test `
  -SkipPublicExport `
  -EvidenceLabel 'REV76-CycleB-WindowsServer-Graphics-Smoke' `
  -EvidenceRetention ZipOnly
```

PASS requires 2/2 stages, exit code `0`, Windows PowerShell 5.1 on Windows
Server, an exact Evidence manifest, and zero Warning/Error diagnostic events.
An AMD GPU may be present or absent because these two stages do not exercise
it. This smoke does not prove compatibility, installation/load or rendering /
compute behavior. No launcher is included.

## REV75 authorized bounded Graphics Gate 2G

The REV75 gate combines the required `PathSafety` and `Test` checks with the
one-artifact processing/publication route, so a separate smoke run is not
required. Use the existing canonical path:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
Set-Location 'C:\Temp\Deploy-Drivers-For-WindowsServer\tools\amd-graphics-driver-research'

.\Invoke-AmdGraphicsDriverResearch.ps1 `
  -ProductGroupKey 'processors|ryzen|ryzen-ai-400-series' `
  -MajorGenerationCount 1 `
  -MaximumSelectedArtifactCount 1 `
  -MaximumEstimatedDownloadGiB 2 `
  -DownloadRetryCount 4 `
  -DownloadTimeoutSeconds 900 `
  -EvidenceLabel 'REV75-CycleB-Graphics-BoundedE2E' `
  -EvidenceRetention ZipOnly
```

Do not add `-Stages` or `-SkipPublicExport`. PASS requires the complete bounded
stage chain, final `Pass`, exit code `0`, one selected artifact and one Evidence
ZIP with a complete validated `snapshot/public/**`. Return the Evidence ZIP and
stop for review. At REV75 the all-track survey and Windows Server remained
held; the later exact REV77 bounded Server gate is now accepted/no-repeat.

## REV74 PowerShell 5.1 cardinality gate (historical prerequisite)

REV74 applies the NPU-discovered conditional collection correction to the
byte-identical Graphics self-contained-public validator. This separate command
is retained as a diagnostic option; REV75 Gate 2G includes both stages and does
not require an additional run:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
Set-Location 'C:\Temp\Deploy-Drivers-For-WindowsServer\tools\amd-graphics-driver-research'
.\Invoke-AmdGraphicsDriverResearch.ps1 `
  -Stages PathSafety,Test `
  -SkipPublicExport `
  -EvidenceLabel 'REV74-CycleB-Graphics-Cardinality' `
  -EvidenceRetention ZipOnly
```

PASS requires 2/2 stages PASS, exit code `0`, no collection-cardinality issue,
and an integrity-valid Evidence ZIP. A multi-hour full Graphics rerun is not
authorized by this correction.

## REV72 self-contained public Evidence gate

The executable version remains `3.0.0`. REV72 changes Evidence packaging and
verification only; it does not change product selection, download scope,
extraction, signature targets or generated-public semantics.

The next authorized bounded Graphics Windows Client E2E SHALL also qualify this
contract. A PASS Evidence ZIP must contain the complete validated public tree
at `snapshot/public/**` plus
`snapshot/public-publication-reference.json` with
`PublicDatasetIncludedInEvidence=true` and
`SnapshotValidationStatus=Pass`. Independent review SHALL verify public schema,
privacy, canonical-byte, dataset, path, size and SHA-256 contracts directly
from that single Evidence ZIP.

Do not create or return a separate public ZIP. A missing or incomplete public
snapshot is `REVIEW`, even when the research stages themselves completed.
This packaging-only correction does not authorize a multi-hour full rerun.

## REV70 hardware-aware scope and transcript-hygiene gate

The tool version remains `3.0.0`. REV70 changes only the shared negative
extraction-completeness self-test path: the ordinary runtime assertion still
throws and blocks incomplete extraction, while the deliberate negative fixture
returns a structured `Blocked` result so Windows PowerShell 5.1 does not record
an expected caught terminating error.

Hardware presence has the following meaning for this tool:

- `PathSafety,Test` and static/publication research are valid whether an AMD
  graphics adapter is present or absent.
- the root Graphics research script does not enumerate the installed display
  adapter and does not test display output, device start, driver load or a GPU
  workload. An `All` PASS is therefore not runtime qualification of the local
  GPU.
- `-RequireWindowsClientSignatureQualification` qualifies Windows-native
  signature evidence for the selected package corpus; it does not require or
  prove an installed AMD GPU.
- AMD GPU presence/absence is declared in the test-host profile and may be
  corroborated with `Win32_VideoController`; it is not inferred from the
  research result.

The minimum direct regression remains:

```powershell
.\Invoke-AmdGraphicsDriverResearch.ps1 `
  -Stages PathSafety,Test `
  -SkipPublicExport `
  -EvidenceLabel REV70-Graphics-Common-Transcript `
  -EvidenceRetention ZipOnly
```

PASS requires 2/2 stages, exit code `0`, a valid Evidence ZIP/manifest, and no
transcript terminating-error record for the deliberate `ExtractedWithErrors`
path-safety fixture. A separate short run is not required before the Cycle B
full run when that exact full run will exercise `Test`. See
`project-management/CYCLE-B-HARDWARE-AWARE-TEST-MATRIX-REV70.md`.

## Current accepted gate and retest rule

The prior exact `1.1.2-dev` source has an accepted Windows Server 2025 / Windows
PowerShell `5.1.26100.33296` smoke result: `PathSafety,Test`, 2/2 PASS, final
`Pass`, exit code `0`, with an independently verified Evidence ZIP and manifest.
The separately accepted bounded short-E2E evidence remains the applicable
processing-path qualification; it is not replaced by this smoke.
Both are regression references and do not qualify the changed `3.0.0` source.

The Server smoke does not qualify live product discovery, a complete multi-hour
survey, all product tracks, installation, kernel load or device operation.
Documentation-only changes do not invalidate accepted executable evidence and
SHALL NOT trigger a ceremonial rerun. Historical revision gates below are
retained regression fixtures and are not automatically pending user actions.

For the historical REV69 `3.0.0` Cycle B candidate, the minimum direct smoke
command was:

```powershell
.\Invoke-AmdGraphicsDriverResearch.ps1 `
  -Stages PathSafety,Test `
  -SkipPublicExport
```

There is no release-included cross-tool test launcher. A future orchestrator
would require named scenarios and explicit scope/side-effect declarations.

## REV69 Cycle B qualification and regeneration gate

The exact `3.0.0` source SHALL parse without error, declare
`#requires -Version 5.1`, pass UTF-8 BOM + CRLF checks, and pass
`PathSafety,Test` with the repinned common-core contract. On a short-path
Windows Client workspace, the full regeneration command is:

```powershell
.\Invoke-AmdGraphicsDriverResearch.ps1 `
  -EvidenceLabel REV69-CycleB-Graphics-WindowsClient `
  -EvidenceRetention ZipOnly
```

Omitting `-Stages` deliberately selects `All`; the run may take more than ten
hours. Do not add `-SkipPublicExport`. Acceptance requires final `Pass`, exit
code `0`, a verified self-contained Evidence ZIP and manifest, and a complete
newly generated `snapshot/public/**` tree that passes schema, canonical-byte, privacy and provenance
validation. Do not substitute the bounded short-E2E gate for public
regeneration, and do not run Windows Server before Client evidence review.

## Rev60 public-null structure regression gate

`PathSafety,Test` SHALL pass a public-converter fixture that preserves an explicit null property and null array element while removing nested `ArchivePath`. This is a short preventive regression gate; it does not justify repeating the accepted multi-hour Graphics survey.

## Rev59 publication-path regression gate

`PathSafety,Test` SHALL pass the nested `PathSafety.ArchivePath` privacy fixture, vendor-token preservation, decoded-scalar audit and 165-function common contract. This is a publication adapter regression gate and does not require repeating the accepted multi-hour Graphics survey.

## Rev58 path-safety correction gate

At the historical REV58 gate, `PathSafety,Test` SHALL pass with the
162-function common contract. Source inspection SHALL confirm that both
release and recursive container destinations call the common short-path
constructor and that Extract/Signature call the shared completeness gate. No
12-hour survey was required for that adapter-only local gate; its then-pending
Windows PowerShell 5.1 requirement has since been satisfied by the accepted
later gates.



## Rev52 lifecycle-only regression gate

The exact candidate SHALL pass `PathSafety,Test`, produce a verified ZIP whose
manifest paths contain no backslashes, and pass an isolated interrupt probe
that persists `INTERRUPTED`. This gate does not reacquire packages, rerun static
certificate analysis, or replace the prior 12-hour research evidence.
An invalid-stage probe on a safe root SHALL return FatalError while producing a
verified normal Evidence ZIP; the same recovery SHALL NOT bypass a PathSafety
unsafe-root block.

## Rev51 regression gate

The PS7.6.5 clean-copy `PathSafety,Test` run completed both stages; the Test
stage took approximately 2.98 seconds. The final assessment remained REVIEW
only because the development container lacked 7-Zip. Forced normal-finalizer
failure produced a verified emergency ZIP/SHA-256 and retained raw evidence.
No 12-hour acquisition/full-research rerun is required for this correction;
At REV51, Windows PowerShell 5.1 was the next real-host gate after package
review; that historical prerequisite is now satisfied by later accepted gates.

## Rev50 Canonical JSON short gate

Run `-Stages Test -SkipPublicExport -EvidenceRetention ZipOnly`. PASS requires
both `CanonicalJsonPublicationSelfTest=Pass` and
`CanonicalJsonCrossRuntimeSelfTest=Pass`. Do not repeat the 12-hour full
Graphics run solely for this serialization change.

This document defines how to verify the `3.0.0` candidate contract in `SPEC.md`. It separates source/static gates, path-safety correctness, research-stage correctness, signature correctness, Windows full-run behavior, publication safety, Evidence provenance and final release acceptance.

## 1. Test principles

A valid release requires all of the following independent properties:

1. **Source correctness** — script parses and passes repository static analysis.
2. **Research correctness** — product selection, artifact acquisition/extraction and INF/WDF/Server analysis behave as specified.
3. **Artifact-chain integrity** — the same selected artifacts and source hashes survive Acquire -> Extract -> Inspect -> Build.
4. **Publication safety** — only repository-safe data reaches `public/**`.
5. **Publication byte correctness** — Markdown, JSON and CSV obey their distinct byte contracts.
6. **Provenance** — a third party can verify source -> Evidence -> runtime source -> published artifact identities.
7. **Automation safety** — a repository workflow can commit generated `public/**` without committing private/runtime state.
8. **Certificate-scope correctness** — three-generation ordinary research remains intact while deep certificate work is newest-generation-only per stable track.
9. **Signature evidence correctness** — identical installer/file bytes are analyzed once without losing provenance, and native checks remain artifact-contextual.
10. **Path safety** — an unsafe Windows root is blocked before Evidence output
    or AMD network access, and every SignTool input uses a byte-identical short alias.

A research-stage PASS does not override a publication failure.

## 1.1 Required local candidate gates

Before requesting a user-machine run, the exact candidate SHALL pass:

- PowerShell parser with zero errors;
- `Test` stage including diagnostic redaction, sequential-download source
  audit, HTTP retry/partial-content decisions, PowerShell 5.1
  zero/one/many-cardinality checks and signature primitive tests;
- retained selection regression: 38 stable tracks, 95 track-generation
  selections and 23 ordinary unique URLs;
- certificate narrowing regression: 38 newest-track references, 9 planned
  unique URLs and 57 explicit historical exclusions;
- offline signed-PE Signature integration with zero unexpected parse failures
  and zero signed-digest mismatches;
- schema and public privacy/manifest validation.
- path-safety, 7-Zip listing and native-alias self-tests.

These counts are pinned regression-fixture expectations, not future live-web
constants.

## 1.2 Platform qualification hold

Windows Client qualification is not satisfied by local/Linux PASS. The reviewed
`1.1.1-dev` run is retained as failure evidence: it completed static analysis but
failed native catalog-bound coverage because SignTool could not open 260–357
character paths. The bounded `1.1.2-dev` Client correction and short-E2E
follow-up were reviewed separately. The later Windows Server
`PathSafety,Test` smoke was authorized only after the Client hold point.

These accepted gates remain distinct: the Client result does not become Server
evidence, and the Server smoke does not become a full research or deployment
qualification. Every future real-machine request SHALL state its hypothesis,
exact source identity, minimum PASS evidence, and what the PASS authorizes.

## 2. Output classifications

| Surface | Purpose | Generated commit target |
|---|---|---:|
| `public/**` | Validated repository-safe generated output | **Yes** |
| `private/a/**`, `private/l/**`, `private/evidence/**` | Short-path installers, logs, Evidence work runs and verified final archives | No |
| `inventory/**` | Runtime staging and canonical analysis | No |
| `reports/**` | Script-generated runtime report staging | No |
| `authored/**` | Authored qualification/hardening records | Yes, reviewed |
| `work/x/**`, `work/n/**`, `work/p/**` | Short extraction, native aliases and transient path probes | No |
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

The manifest itself and every manifested payload SHALL be present and
byte-identical beneath private Evidence `snapshot/public/**` for release audit.

## 14. Evidence provenance verification

The private Evidence ZIP SHALL contain at least:

```text
run-summary.json
evidence-manifest.json
snapshot/tool/Invoke-AmdGraphicsDriverResearch.ps1
snapshot/public-publication-reference.json
snapshot/public/**
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

## Appendix A. Signature enhancement qualification history

Graphics v1.0.0 had no Signature acceptance gate. The plan in
`authored/GRAPHICS-SIGNATURE-AND-COMMON-HARDENING-PLAN-2026-08-17.md` is a
historical design record; the current `3.0.0` source includes the planned
bounded selection, Signature and `SignatureNative` contracts. Accepted Client,
short-E2E and Server-smoke evidence remains scope-specific rather than one
blanket qualification.

Before a future implementation requests another user-machine run, local and
synthetic qualification must prove preservation of the newest-three-generation
research surface, newest-generation-per-track certificate planning,
many-to-one provenance, URL/SHA-256 de-duplication, common signature-engine
known answers, atomic transfer integrity, sequential AMD HTTP concurrency and
PowerShell 5.1 zero/one/many collection behavior.

A future platform gate must state a concrete hypothesis, exact PASS evidence
and what the PASS enables. It ends at an Evidence review hold. No Windows
Server execution follows automatically from a Client result, and no signature
gate proves driver installation, kernel load or device functionality.
## Evidence-storage qualification (rev48)

A release candidate must pass the following short tests for all three tools; a full artifact research run is not required for this contract.

1. Parse the script with Windows PowerShell 5.1-compatible syntax.
2. Run the smallest local stage with default evidence settings.
3. Confirm the final ZIP, `.zip.sha256`, and `LATEST-EVIDENCE.txt` exist directly under `private\evidence`.
4. Confirm the hash companion matches the ZIP and every ZIP entry can be read.
5. Confirm the raw `runs\r...` directory is removed for `ZipOnly` and retained for `ZipAndDirectory`.
6. Supply an output root outside `private\evidence` and confirm the run blocks before creating that directory or starting a network request.
7. On Windows, qualify UNC, SUBST, and reparse-point rejection under PowerShell 5.1.
## rev57 common-core validation gate

The accepted earlier Graphics `PathSafety,Test` result remains historical evidence for the path correction, but it does not attest the changed rev57 bytes. The minimum future gate is `PathSafety,Test` only; a 12-hour full Graphics rerun is not justified by this common-core change.

PASS requires the common-core, ordinal-ordering, diagnostic, HTTP, collection-cardinality, and path-safety self-tests to pass. Stop for review after the Windows 11 evidence; do not proceed automatically to Windows Server.
