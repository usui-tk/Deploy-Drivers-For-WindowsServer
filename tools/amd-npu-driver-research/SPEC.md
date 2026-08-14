# AMD NPU Driver Research Toolkit Specification

This document defines the normative behavior of `Invoke-AmdNpuDriverResearch.ps1` for the stable v1.0.0 source contract. Release qualification evidence is bound to the exact v1.0.0 script SHA-256.

Historical implementation narratives belong in `CHANGELOG.md`, `DEVELOPMENT-HANDOVER.md`, and `REVERSE-ENGINEERING-NOTES.md`. This file defines what the toolkit **shall** do.

Normative terms **SHALL**, **SHALL NOT**, **SHOULD**, **SHOULD NOT**, and **MAY** are used in their ordinary specification sense.

## 1. Purpose and scope

The toolkit SHALL provide a reproducible research/evidence layer for AMD Ryzen AI NPU Windows driver packages before deployment logic is changed.

The toolkit SHALL support:

- reviewed artifact discovery and acquisition;
- immutable artifact identity;
- static bounded extraction;
- INF selector analysis;
- installer exact-hash contract analysis;
- driver-binary exact-hash contract analysis;
- exact processor/NPU identity modeling;
- Windows Server static applicability analysis;
- reviewed processor-to-driver recommendation modeling;
- private/runtime evidence promotion boundaries;
- deterministic repository-safe publication;
- Evidence ZIP creation for audit/replay.

The toolkit SHALL NOT:

- execute AMD installer EXEs as part of research;
- install/remove/update a driver;
- patch an INF;
- re-sign a package;
- create/install a certificate;
- claim AMD support for Windows Server;
- claim Windows Server runtime compatibility from static or Windows client evidence.

## 2. Repository placement and implementation policy

The main implementation SHALL remain:

```text
tools/amd-npu-driver-research/Invoke-AmdNpuDriverResearch.ps1
```

The root runtime implementation SHALL remain a single PowerShell script. Static data, schemas, documentation, generated `public/**`, and toolkit-local companion utilities MAY be separate files.

All NPU research assets SHALL remain under `tools/amd-npu-driver-research/`. Companion utilities SHALL remain under `tools/amd-npu-driver-research/tools/`.

## 3. Version policy

The first stable release SHALL be `v1.0.0`, and the current release-qualification source is intentionally versioned `1.0.0`.

The completed pre-release development line remained in the `0.x` namespace. `1.0.0` SHALL NOT be used as an interim development identifier, and no version greater than `1.0.0` belongs to this first-release qualification cycle.

The companion hardware collector has an independent utility version lineage; its version does not redefine the main toolkit release version.

## 4. Runtime and source byte contract

The main script SHALL remain compatible with Windows PowerShell 5.1 for the Windows qualification path.

PowerShell 7.x on Windows and Linux MAY be used for supported static/offline qualification paths.

The distributed root `.ps1` SHALL use:

```text
UTF-8 with BOM
CRLF line endings
```

Source Markdown and reviewed static JSON SHOULD use UTF-8 without BOM and LF.

Generated public Markdown SHALL use UTF-8 without BOM and LF only.

Generated public JSON SHALL use the toolkit's runtime-independent canonical JSON writer.

## 5. Safety invariants

AMD artifacts SHALL be treated as untrusted input.

The toolkit SHALL NOT launch an AMD installer to obtain research data.

Static extraction SHALL be bounded by configured depth/guards.

The original artifact bytes and SHA-256 SHALL remain immutable provenance.

A reviewed exact-hash installer or driver-binary contract SHALL apply only to that exact hash unless a separate reviewed relationship explicitly says otherwise.

Private/restricted artifacts SHALL NOT become automatic-download or recommendation targets merely because they were supplied through `-PackagePath`.

## 6. Stage model

### 6.1 Normal pipeline

The normal no-argument / `-Stages All` pipeline SHALL be:

```text
Test
HardwareIdentity
ProcessorCatalog
Discover
Metadata
Acquire
Extract
Inspect
DriverBinary
Compare
Matrix
Build
Validate
```

### 6.2 Stage outcomes

The stage runner SHALL distinguish successful, failed, blocked, and intentionally skipped work. Downstream work SHALL NOT consume producer data that did not satisfy the current run's prerequisite contract.

A declared prerequisite that was not selected/executed in the current run SHALL be treated as **unmet** and the dependent stage SHALL report `BLOCKED`; absence of a prerequisite MUST NOT be treated as success. A selected prerequisite with no result SHALL likewise block. This rule applies to partial `-Stages` invocations as well as the normal full pipeline.

A publication failure SHALL be capable of making the final run unsuccessful even when analysis stages pass.

### 6.3 Legacy mode/stage controls

`-Mode` MAY map older workflow concepts to the current stage model for compatibility. The canonical behavior is the stage model above.

## 7. Parameter-state contract

Caller-bound top-level parameters SHALL NOT be silently overwritten by same-named script-state initialization.

Functions SHALL NOT rely on accidental PowerShell dynamic-scope capture of top-level script parameters where an explicit parameter handoff is required.

`-PublicOutputRoot` SHALL resolve the caller-supplied path when supplied, otherwise the default toolkit `public` path.

The Test stage SHALL contain a regression check for the explicit public-output-root resolver.

## 8. Evidence taxonomy

The toolkit SHALL preserve evidence plane/type rather than flattening unlike evidence into one confidence flag.

At minimum, the following concepts SHALL remain distinguishable:

- vendor publication / `Published`;
- embedded artifact content / `Embedded`;
- extracted payload observation / `PayloadObserved`;
- exact-binary static disassembly / `StaticDisassemblyProven`;
- toolkit analysis/inference / `Analysis`;
- observed Windows client runtime / `ObservedClientRuntime`;
- private runtime/host evidence.

Evidence from one plane SHALL NOT automatically satisfy a requirement in a different plane.

Examples:

- binary recognition SHALL NOT substitute for AMD published-family support;
- client runtime SHALL NOT substitute for Windows Server runtime;
- PCI revision SHALL NOT substitute for firmware device revision.

## 9. Artifact identity and acquisition

### 9.1 Public reviewed artifacts

`data/published-driver-artifacts.json` SHALL be the reviewed machine-readable public acquisition catalog.

A reviewed public artifact SHALL preserve at minimum:

- artifact identifier;
- filename/container type;
- source URL/provenance;
- expected size when available;
- SHA-256;
- review status.

Runtime discovery from AMD documentation MAY add candidate links, but a newly observed link SHALL NOT automatically receive reviewed support/installer/binary semantics.

### 9.2 Cache/download integrity

Acquisition SHALL verify reviewed hash/size policy before an artifact is accepted as the known reviewed artifact.

Partial downloads SHALL NOT replace a validated cache entry.

### 9.3 Private 314 qualification artifact

`NPU_RAI1.6.1_314_WHQL.zip` is a manually supplied authenticated/restricted qualification artifact.

Its reviewed SHA-256 is:

```text
023caa295d3b2fe4befccdba84db5867abb6428a5e057ac1acdbda03853cf0ac
```

The toolkit SHALL NOT publish or infer an unauthenticated source URL for it.

It SHALL remain:

```text
Visibility = PrivateQualification
RecommendationEligible = false
```

## 10. Static extraction contract

The shared extraction kernel SHALL support top-level research artifacts of type:

```text
.zip
.exe
.msi
.cab
.7z
```

7-Zip discovery/qualification SHALL follow the predecessor research-tool architecture.

Extraction SHALL remain static; an executable container is data, not a command.

Recursive extraction SHALL be bounded by `-ExtractionMaxDepth` and shall preserve extraction evidence/logging.

## 11. INF analysis contract

### 11.1 Topology

INF analysis SHALL preserve the chain:

```text
[Manufacturer]
  -> TargetOSVersion decoration
     -> referenced Models section
        -> description
        -> DDInstall section
        -> HWID / compatible identifier
```

The analysis SHALL NOT reduce the INF to a loose string search for PCI IDs.

### 11.2 TargetOSVersion

Empty ProductType/SuiteMask fields SHALL remain empty. They SHALL NOT be normalized into a workstation-only selector.

For the reviewed NPU INF family:

```text
NTamd64.10.0...22000
```

SHALL be interpreted as an x64 Windows 10.0 selector with build floor 22000 and no explicit ProductType restriction.

### 11.3 Windows Server static projection

For the currently modeled Server releases, the toolkit SHALL keep the as-published selector result separate from any deployment-project transformation concept.

The reviewed 22000 build floor means:

- Server 2016/2019/2022: as-published build-floor rejection;
- Server 2025 build 26100: as-published static selector candidate.

This SHALL NOT be labeled runtime support.

## 12. Installer contract

`data/known-installer-contracts.json` SHALL store exact-hash reviewed installer findings.

The historical Ryzen AI 1.5 280 installer and the later 280/376 installer SHALL remain different exact-hash contracts even though the recovered relevant route semantics are the same.

The reviewed route family SHALL preserve at minimum:

```text
major == 10
build >= 26100                  -> MCDM
build >= 22621 + UBR >= 3527    -> MCDM
build >= 22621 + UBR < 3527     -> WDF/NULL
build >= 22000 and < 22621       -> WDF/NULL
lower build                      -> Windows 10 / WDF-NULL
```

The package-content check SHALL remain independent from route recovery. A route referencing a path that is absent from the reviewed artifact SHALL be reported as absent rather than synthesized.

The reviewed corpus currently contains `npu_mcdm_stack_prod/kipudrv.inf` and does not contain the referenced `npu_wdf_stack_prod/kipudrv/kipudrv.inf` path.

## 13. Driver-binary contract

`data/known-driver-binary-contracts.json` SHALL bind reverse-engineered behavior to exact binary hashes.

The broad Windows NPU identity layer SHALL remain separate from the finer firmware device-revision layer.

For the reviewed 376 `ipustack.sys` exact hash, the toolkit MAY expose the reviewed static mapping:

| revision | interpretation |
|---:|---|
| 1 | Strix A |
| 2 | Strix B |
| 3 | Krackan 1 |
| 4 | Krackan 2 |
| 5 | Strix Halo |
| 6 | Gorgon Point 1 |
| 7 | Gorgon Point 2 |
| 8 | Gorgon Point 3 |
| 9/other | unknown/fallback |

The reviewed `0x117` correlation SHALL be classified as exact-binary/static plus upstream semantic correlation. It SHALL NOT be treated as a published AMD Windows API contract unless such an AMD publication is separately reviewed.

Additional labels such as Medusa/Soundwave observed in a binary SHALL remain binary observations until exact processor/public-support evidence exists.

## 14. Hardware identity model

The toolkit SHALL keep the following identity layers distinct:

1. exact processor SKU;
2. processor codename/family;
3. broad NPU PCI VEN/DEV;
4. PCI `REV_XX`;
5. quicktest-style PCI-revision classification;
6. runtime XRT device label;
7. firmware version;
8. firmware device revision.

The toolkit SHALL NOT equate:

- `DEV_17F0` with Strix;
- `REV_10` with STXA/STXB;
- XRT firmware version with firmware device revision.

## 15. Processor catalog contract

`data/processor-catalog.json` SHALL be an exact-SKU catalog.

Unknown processor names SHALL NOT inherit NPU capability from:

- series prefix;
- approximate marketing family;
- core count/layout;
- iGPU family;
- presumed die/silicon similarity.

The catalog SHALL encode positive and negative NPU availability evidence where reviewed.

At 0.9.0-dev the reviewed catalog contains 112 exact SKUs, including 90 `AvailablePublished` and 22 negative-control/no-driver-required SKUs.

Unknown exact SKUs SHALL resolve to `ReviewRequired` in an automated deployment-consumption context.

## 16. Processor-driver applicability contract

### 16.1 Source and publication

The reviewed source relation SHALL be represented by:

```text
data/processor-driver-applicability.json
```

Generated publication SHALL include:

```text
public/catalog/processor-driver-applicability.json
public/catalog/processor-driver-applicability.md
```

### 16.2 Recommendation hierarchy

A recommendation SHALL be based on a relation equivalent to:

```text
exact CPU SKU
  -> NPU availability
  -> codename / expected NPU identity
  -> reviewed artifact rule
  -> HWID/static package applicability
  -> AMD published codename/family support
  -> Windows Server static profile result
  -> recommendation eligibility / visibility
  -> optional observed-runtime evidence
```

A broad INF/installer HWID match alone SHALL NOT authorize a recommendation.

### 16.3 Decision classes

The generated applicability layer SHALL distinguish at least:

- `SelectLatestPublishedStaticCandidate`;
- `ReviewRequired`;
- `NoNpuDriverRequired`.

`ReviewRequired` is a valid fail-closed result, not a generation failure.

### 16.4 Gorgon Point / Gorgon Halo boundary

The current reviewed 376 AMD publication states production support for Phoenix, Hawk Point, Strix, Strix Halo, and Krackan Point.

Therefore Gorgon Point SHALL remain `ReviewRequired` for the reviewed 376 recommendation set even when broad `DEV_17F0` and binary generation-recognition evidence exist.

Gorgon Halo SHALL remain `ReviewRequired` while exact reviewed NPU identity and reviewed artifact support are incomplete.

### 16.5 Private artifact exclusion

A private/restricted artifact SHALL never win the normal public recommendation ranking.

## 17. Version-namespace contract

AMD-published driver labels and embedded INF `DriverVer` values SHALL remain separate evidence dimensions.

Example for 376:

```text
Published driver label: 32.0.203.376
Embedded INF DriverVer: 32.00.20101.3760
```

The toolkit SHALL NOT rewrite one namespace into the other.

Artifact identity SHALL remain SHA-256 based regardless of version-string similarity.

## 18. Observed runtime evidence contract

Raw host evidence SHALL remain private/runtime/non-commit.

Only reviewed generalized observations MAY be promoted to `data/observed-runtime-evidence.json`.

For the reviewed Ryzen AI Z2 Extreme client observation, the repository MAY record the generalized relation:

```text
exact CPU SKU
+ DEV_17F0 / PCI REV_10
+ quicktest-style STX
+ XRT NPU Strix
+ exact public-376 component hashes
= ExactArtifactRuntimeObserved (Windows client)
```

The record SHALL explicitly keep Windows Server runtime proof false until separately tested.

STXA/STXB SHALL remain unresolved unless an explicit firmware device-revision source reports the required value.

## 19. Windows Server applicability semantics

The toolkit SHALL not treat all Server releases as one problem.

For the current reviewed corpus:

- Server 2016/2019/2022 are below the published INF build floor and the reviewed package lacks the lower-build WDF path referenced by the installer;
- Server 2025 satisfies the build floor and the reviewed installer routes build 26100 to MCDM.

The research output SHOULD therefore guide the later deployment project to test the unmodified WHQL package on Server 2025 before introducing a transformation.

No static result SHALL be promoted to Server runtime proof.

## 19.1 Reviewed source-data schema/version contract

Every reviewed JSON document under `data/**` SHALL have:

1. a registered expected `schemaVersion`;
2. a matching JSON Schema under `schemas/source-data/**`;
3. a schema-level `const` guard for that exact source `schemaVersion`; and
4. Test-stage registration so newly added `data/*.json` files fail closed until both schema and version contract are deliberately added.

Source-data schemas describe the camelCase hand-reviewed source shape and SHALL remain distinct from generated-public PascalCase schemas. External release qualification SHALL validate all reviewed source data against these schemas.

## 20. Publication contract

`public/**` SHALL be the generated commit surface.

Generated public files SHALL NOT be hand-edited.

Publication SHALL use candidate staging and validation before promotion.

Validation SHALL fail closed for at least:

- invalid JSON/schema shape;
- source/generated cross-dataset inconsistency;
- private/restricted artifact recommendation;
- leaked private/runtime identifiers/paths;
- invalid public Markdown byte contract;
- manifest hash/length mismatch;
- unexpected `HandEdited=true`;
- source-script identity mismatch where required.

See `PUBLICATION-POLICY.md` for the detailed byte/provenance rules.

## 21. Evidence/failure contract

Evidence establishment SHOULD occur before substantial runtime work so a later stage failure can be preserved.

Ordinary failures SHALL be represented through stage results and finalized Evidence where output remains writable.

Fatal bootstrap failure SHALL use the emergency evidence path rather than silently dropping the reason for failure.

Vendor payloads SHALL remain excluded from Evidence by default unless the operator explicitly requests otherwise.

## 22. Architecture convergence contract

Shared research infrastructure inherited from the merged Chipset/Graphics toolkits SHALL be protected by the machine-readable predecessor/architecture hash contracts.

NPU-specific adapters and research semantics MAY evolve without duplicating the generic runner/evidence/acquisition/extraction/publication kernels.

See `ARCHITECTURE-PARITY.md`.

## 23. Companion hardware collector boundary

The companion collector SHALL remain under:

```text
tools/amd-npu-driver-research/tools/Collect-AmdNpuHardwareIdentityEvidence.ps1
```

It SHALL be read-only with respect to driver installation/configuration.

Collector output SHALL remain private/runtime/non-commit.

Read-only XRT probing MAY use `xrt-smi --version` and `xrt-smi examine`. It SHALL NOT automatically run `validate`, `configure`, or quicktest inference.

Collector evidence SHALL not bypass the main toolkit's review/promotion boundary.

## 24. Deployment-consumption contract

A future `Deploy-AMDNpuDriverOnWindowsServer.ps1` integration SHOULD consume reviewed source/generated applicability data in a fail-closed manner.

The deployment script SHOULD:

1. resolve exact CPU SKU;
2. resolve whether an NPU is expected;
3. observe actual NPU HWID/revision;
4. verify CPU/NPU relation against reviewed catalog data;
5. filter to recommendation-eligible public artifacts;
6. require reviewed published-family support;
7. evaluate static Server/package gates;
8. stop on unknown/inconsistent evidence;
9. preserve original vendor artifact identity before transformation;
10. transform/re-sign only when the target deployment policy and runtime evidence justify it.

Unknown CPU/NPU combinations SHALL NOT be automatically installed.

## 25. Release qualification

Before v1.0.0, the accepted candidate SHALL satisfy the release gates in `TESTING.md`, including:

- source AST/static-analysis gate;
- built-in tests;
- Linux/PowerShell 7 static qualification;
- Windows PowerShell 5.1 full run;
- reviewed-artifact hash identity;
- deterministic cross-runtime `public/**` comparison;
- schema/dataset validation;
- publication privacy/manifest verification;
- external review/audit workflow used by the repository.

If v1.0.0 documentation claims the companion collector is real-device-qualified at v1.2.1, a v1.2.1 real Ryzen AI positive-control rerun SHALL also be retained as evidence.
