# AMD NPU Research — Architecture Convergence and Predecessor Parity

This document records the implementation-level convergence used by AMD NPU Driver Research Toolkit `1.0.0`.

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
- `Invoke-NpuEvidenceSnapshot`
- `Test-NpuPublicDatasetConsistency`
- `Resolve-NpuRequestedStages`
- `Invoke-NpuDiscoveryStage`
- `Invoke-NpuMetadataStage`
- `Invoke-NpuAcquireStage`
- `Invoke-NpuExtractStage`
- `Invoke-NpuInspectStage`
- `Invoke-NpuBuildStage`
- `Invoke-NpuValidateStage`

`Discover`, `Metadata`, and `Inspect` remain NPU-specific because their data model and reverse-engineering semantics differ from chipset and graphics. `Acquire`, `Extract`, `Build`, and `Validate` are now thin adapters over shared mechanics.

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
