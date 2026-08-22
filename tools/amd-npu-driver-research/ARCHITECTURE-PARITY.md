# AMD NPU Research — Architecture Convergence and Predecessor Parity

> Current-use note (REV65): the 80/41-function predecessor snapshot below is a
> historical convergence baseline, not the current three-tool parity authority.
> Current executable parity is governed by
> `data/current-three-tool-common-core-contract.json` and its 165
> source-identical functions. Product-specific NPU selection semantics remain
> outside that common core.

This document records the implementation-level convergence retained by AMD NPU Driver Research Toolkit `3.0.0`, including the qualified `1.0.0` shared-kernel history.

The reviewed predecessor baselines are the current chipset and graphics research scripts captured on 2026-08-13:

- `tools/amd-chipset-driver-research/Invoke-AmdChipsetDriverResearch.ps1`
  - source SHA-256: `1ad2287c20b507497e1b883f1e90e1c4c06eb202287eb8c5d22453180dedde29`
- `tools/amd-graphics-driver-research/Invoke-AmdGraphicsDriverResearch.ps1`
  - source SHA-256: `a08b741b33378922f57c51a2bebadca04d3ccd55744684197a853491387ea33b`

The predecessor snapshots contain 80 common function names. Forty-one function definitions are byte-equivalent after CRLF/CR is normalized to LF. Those 41 exact-common functions are imported into NPU and bound by `data/predecessor-shared-core-contract.json`.

## Architecture decision

`0.7.1-dev` retains the 0.7.0 architecture convergence and adds a fourth executable requirement: publication bytes must not depend on PowerShell runtime, platform culture, or host text decoding.

1. **Shared infrastructure kernel**
   - platform/runtime detection;
   - logging and timing;
   - HTTP/TLS/download/cache mechanics;
   - 7-Zip discovery/probe/extraction mechanics;
   - stage runner state machine;
   - Evidence lifecycle and archive finalization;
   - publication privacy/encoding/manifest mechanics;
   - requested-stage parsing;
   - process exit-code policy.
2. **NPU adapters**
   - NPU stage graph;
   - NPU artifact catalog selection;
   - NPU evidence snapshot list;
   - NPU public dataset consistency checks;
   - NPU analysis-surface predicate used by the generic extractor.
3. **NPU research semantics**
   - CPU/SKU catalog;
   - NPU hardware identity;
   - INF applicability;
   - `ipustack.sys` and installer reverse engineering;
   - firmware device-revision mapping;
   - cross-release comparison;
   - Windows Server compatibility matrix.

Layer 1 is intentionally device-neutral. New NPU-only logic must not be added there without an explicit architecture review.

## Exact predecessor shared core

`data/predecessor-shared-core-contract.json` contains all **41** functions whose definitions are identical in the reviewed chipset and graphics baselines. `Test-NpuPredecessorParityContract` parses the executing NPU script with the PowerShell AST and validates every normalized function hash before research begins.

This includes `Get-AmdSevenZipPath`, INF helpers, XML parsing, installer-file validation, platform/TLS/HTTP/download helpers, path/hash helpers, ZIP creation, evidence archive probing, and logging primitives.

`data/predecessor-extraction-core-contract.json` separately binds the selected Graphics implementations of:

- `Get-AmdSevenZipInfo`
- `Get-AmdSevenZipArchiveProbe`

These are used by the real NPU `Extract` path, not retained merely as dormant compatibility helpers.

## Architecture-converged generic kernel

`data/architecture-convergence-contract.json` binds **27 generic kernel functions**: the 23 architecture-convergence functions plus four 0.7.1 deterministic-publication helpers. The contract is executable: the `Test` stage hashes the currently running function bodies and rejects drift.

The generic kernel covers:

### Runner

- `Write-AmdStageHeader`
- `Write-AmdStageFooter`
- `Write-AmdRunTimingSummary`
- `Write-AmdStageResultsEvidence`
- `Invoke-AmdTrackedStage`
- `Get-AmdRunAssessment`
- `Write-AmdAssessmentConsoleReport`
- `Resolve-AmdRequestedStages`

### Evidence

- `Start-AmdResearchEvidenceSession`
- `Start-AmdEmergencyEvidenceSession`
- `Finalize-AmdResearchEvidenceSession`

NPU-specific evidence content is supplied only by `Invoke-NpuEvidenceSnapshot`.

### Publication

- `Get-AmdResearchToolkitRoot`
- `Write-AmdJsonFile`
- `ConvertTo-AmdRepositoryRelativePath`
- `Write-AmdPublicMarkdownText`
- `Copy-AmdPublicMarkdownFile`
- `Get-AmdPublicForbiddenPatterns`
- `Get-AmdPublicScalarStrings`
- `Test-AmdCompactJsonWhitespaceFile`
- `Test-AmdPublicRepositorySurface`
- `Publish-AmdRepositorySurface`

The generic validator checks decoded JSON scalar privacy, compact JSON structural whitespace, UTF-8 no-BOM/LF publication formatting, and invokes the NPU dataset-consistency adapter. Promotion from a run-scoped candidate tree to `public/**` is performed only after validation succeeds.

### Acquisition and extraction

- `Invoke-AmdArtifactAcquisitionKernel`
- `Invoke-AmdArtifactExtractionKernel`

The NPU acquisition adapter supplies the reviewed AMD artifact catalog and download callback. The generic kernel owns cache reuse, hash/size enforcement and per-artifact result capture.

The NPU extraction adapter supplies three callbacks only:

- artifact format resolver;
- NPU analysis-surface probe;
- nested-container predicate.

The generic extraction kernel owns bounded recursive 7-Zip probing/extraction, container de-duplication, evidence logging and extraction-state recording.

## Removed legacy NPU infrastructure

The following earlier NPU-specific infrastructure functions are forbidden by the executable architecture contract and must not reappear:

- `Start-NpuEvidenceSession`
- `Start-NpuEmergencyEvidenceSession`
- `Write-NpuStageEvidence`
- `Write-NpuStageHeader`
- `Invoke-NpuTrackedStage`
- `Get-NpuRunAssessment`
- `Finalize-NpuEvidenceSession`

Their responsibilities are now handled by the generic kernel.

## NPU adapters that intentionally remain

The following are device-specific adapters rather than duplicated infrastructure:

- `Get-NpuRunAssessmentExtensions`
- `Get-NpuEvidenceInventorySnapshotFileNames`
- `Test-NpuEvidenceSnapshotContract`
- `Invoke-NpuEvidenceSnapshot`
- `Test-NpuPublicDatasetConsistency`
- `Resolve-NpuRequestedStages`
- `Invoke-NpuDiscoveryStage`
- `Invoke-NpuMetadataStage`
- `Invoke-NpuAcquireStage`
- `Invoke-NpuExtractStage`
- `Invoke-NpuInspectStage`
- `Get-NpuEffectiveCertificateVerificationPlan`
- `Invoke-NpuSignatureStage`
- `Invoke-NpuBuildStage`
- `Invoke-NpuValidateStage`

`Discover`, `Metadata`, `Inspect`, and `Signature` remain NPU-specific because
their data model, package-case selection and reverse-engineering semantics differ
from chipset and graphics. `Acquire`, `Extract`, `Build`, and `Validate` are thin
adapters over shared mechanics. The Signature implementation reuses common
cryptographic/native primitives but consumes the NPU-owned certificate execution
plan; it does not import chipset release ranking.

## Hardened behavior retained from NPU development

Convergence does not discard improvements that were first implemented in the NPU toolkit:

- Evidence is established before work-root or network activity.
- If normal Evidence bootstrap fails, `Start-AmdEmergencyEvidenceSession` attempts a writable fallback and creates a `BootstrapFatal` archive.
- Exit codes remain `0=Pass`, `2=ReviewRequired`, `1=FatalError`.
- Build writes only to a run-scoped candidate publication tree.
- Validate must pass before atomic promotion to `public/**`.
- AMD installers are never executed by the research pipeline.

These hardened patterns are candidates for reverse feedback into the predecessor toolkits rather than reasons to keep NPU-only infrastructure.

## Release gates

Architecture parity is release-blocking. Qualification must prove:

1. 41/41 predecessor shared-core hashes pass;
2. selected 7-Zip extraction hashes pass;
3. 27/27 architecture-kernel hashes pass;
4. all forbidden legacy NPU infrastructure functions are absent;
5. all required NPU adapters are present;
6. no-argument stage resolution selects the complete workflow;
7. three-package local replay passes;
8. repeated full replays produce byte-identical `public/**`;
9. ordinary stage failure returns exit 2 and produces hash-valid Evidence;
10. bootstrap fatal returns exit 1 and produces fallback Evidence when any configured fallback root is writable;
11. Windows PowerShell 5.1 no-argument online execution passes before release candidacy.


## 0.7.1 cross-runtime determinism delta

The first real Windows PowerShell 5.1 online full run completed all 13 stages successfully, but a byte-level comparison against the Linux/PowerShell 7 public tree exposed platform-dependent publication bytes. The causes were not NPU semantics: reviewed UTF-8 no-BOM JSON was read through `Get-Content` on Windows PowerShell 5.1, `ConvertTo-Json` escaped characters differently across runtimes, and `Sort-Object` applied culture-sensitive ordering to publication-visible sets.

0.7.1 moves these concerns into the generic architecture kernel. Reviewed JSON is read by an explicit text reader, canonical JSON is serialized by `ConvertTo-AmdCanonicalJsonText`, and publication-visible strings/objects are ordered with ordinal comparers. These four helpers are included in `data/architecture-convergence-contract.json` and hash-validated by `Test`. A release candidate now requires byte-identical `public/**` from Windows PowerShell 5.1 and Linux/PowerShell 7 for the same source and exact artifact corpus.

## 0.8.0 data-plane note

0.8.0 adds reviewed observed-runtime evidence and matrix semantics without changing the predecessor-shared infrastructure or architecture-convergence kernels. The shared-core, extraction-core, canonical JSON, ordinal ordering, Evidence, acquisition, extraction, and publication hash contracts remain the qualified 0.7.1 architecture. Runtime host archives remain private inputs; only generalized reviewed facts enter repository source data.

## 0.9.0 applicability-layer delta

0.9.0 adds reviewed exact-SKU processor coverage and a generated processor-driver applicability layer without moving acquisition, extraction, evidence, canonical JSON or publication mechanics out of the qualified generic kernel. The new NPU-specific adapter combines processor identity, compatibility-matrix selections and explicitly non-recommendable private qualification metadata; unknown identity/support relationships remain fail-closed.

## 0.9.0 documentation consolidation note

The documentation/audit checkpoint after the successful Windows PowerShell 5.1 0.9.0-dev run does not change predecessor/shared-core or architecture-convergence function hashes. It reorganizes the human documentation so the shared infrastructure boundary remains separate from NPU-specific findings and future deployment-script feedback.

## 0.9.1 audit-remediation delta

0.9.1 changes only NPU-specific orchestration/data-contract surfaces: partial-stage dependency enforcement and reviewed source-data schema/version coverage. The predecessor-shared infrastructure and architecture-convergence hash contracts are unchanged. `Get-NpuStageDependencyBlockReason` now blocks when a declared prerequisite was not selected or has no result. Source-data schema validation is represented by NPU adapter functions and external JSON Schema qualification, not by modifying shared predecessor functions.

## 1.2.0 signature-engine delta

1.2.0-dev ports the common CMS, Authenticode, catalog and SignTool primitives
into the NPU tool while preserving NPU-owned package selection. `Signature`
depends on `Inspect`; `Build` depends on both `Inspect` and `Signature`. Default
deep verification consumes the two current package-case targets emitted by
Metadata, while full research retains all three reviewed artifacts and explicit
single-artifact replay may target the historical fixture.

Static cryptographic evidence is host-neutral. Windows-native trust-policy,
catalog association, tool output and host posture are private evidence and have
a separate Windows Client qualification gate. No GPU source, schema, test or
documentation surface is changed by this NPU delta.

## 1.2.1 Windows Client gate delta

1.2.1-dev adds only NPU qualification orchestration around the 1.2.0 signature
engine. The acceptance evaluator is a pure NPU adapter: it binds the expected
three-artifact research corpus, two current package-case targets, Windows Client
execution, SignTool availability and complete catalog-bound per-kernel coverage.
It does not change the shared cryptographic primitives or import Chipset/GPU
selection semantics.

## 1.2.2 Windows PowerShell 5.1 cardinality correction

1.2.2-dev preserves the 1.2.1 Gate A contract and corrects only NPU orchestration.
`Get-NpuCertificateVerificationTargetPlan` now protects the complete conditional
selection expression with `@(...)`, so zero, one and many selected artifacts
retain collection shape before `.Count` access under Windows PowerShell 5.1.

The previously migrated shared cardinality self-test and source-contract audit
are now invoked by the NPU Test stage. This closes the migration-wiring gap that
allowed the unsafe NPU-specific target-plan assignment to pass PowerShell 7
qualification. Chipset and Graphics implementation surfaces remain unchanged.

## 1.2.3 NPU operator-presentation correction

1.2.3-dev preserves all shared/generic kernel hashes and all 1.2.2 signature and
package-selection decisions. The NPU adapter now translates internal shared
acquisition/extraction implementation state into NPU-specific operator wording,
names the full research and deep-certificate scopes separately, and records the
final report before transcript close. These changes do not alter Chipset or
Graphics implementation surfaces.

## 1.3.0 NPU hardware-only selection delta

1.3.1-dev adds NPU-owned automatic Windows PnP/build collection, reviewed data,
resolver and self-test adapters without
changing the predecessor/shared runner, evidence, acquisition, extraction,
signature or publication kernels. The resolver consumes one device instance's
PnP HardwareID/CompatibleID set and target build. It does not consume CPU,
firmware or Linux topology data, never enables 280 fallback, and never authorizes
installation or Server runtime claims. Chipset and Graphics surfaces are unchanged.

## 1.3.2 NPU Evidence-snapshot correction

1.3.2-dev changes only the NPU-owned Evidence adapter and Test-stage evidence
surface. `Get-NpuEvidenceInventorySnapshotFileNames` centralizes the inventory
allowlist, and `Test-NpuEvidenceSnapshotContract` requires the local PnP,
hardware-selection and structured Test-stage artifacts without modifying the
generic Evidence finalizer. The files are copied before the generic manifest and
ZIP operations, so the existing generic hash/length contract protects them.
Hardware selection, package lanes, shared cryptographic primitives, Chipset,
Graphics and generated NPU `public/**` remain unchanged.

## 1.3.3 canonical JSON enum correction

The v1.3.2-dev NPU positive-control archive exposed a NPU-local use of a Windows
CIM enum. The canonical serializer previously emitted enum names without JSON
quoting. v1.3.3-dev corrects the existing serializer contract, adds a
runtime-independent enum round-trip self-test, stabilizes the NPU PnP evidence
field as a string, and validates the generated runtime JSON before stage PASS.
Static inspection found no matching defective enum branch in the rev37 Chipset
or Graphics sources, so those frozen trees are not modified.
## rev57 current three-tool authority

The earlier 2026-08-13 predecessor comparison is retained below as historical migration evidence. It is no longer the current parity authority.

The current authority is `data/current-three-tool-common-core-contract.json`, generated from the exact Chipset, Graphics, and NPU scripts in the same umbrella revision. Each Test stage verifies its own embedded common function bodies against that contract. NPU additionally retains `architecture-convergence-contract.json` for NPU kernel/adapter boundaries.

rev57 converges the HTTP/diagnostic infrastructure, path-safety primitives, archive-entry preflight, emergency bootstrap evidence, repository path normalization, 7-Zip executable validation, collection-cardinality source audit, read-only process argument contract, and ordinal ordering helpers. NPU-specific discovery, 280/376 selection, hardware identity, CPU/NPU reference data, and certificate orchestration remain adapters.
