# AMD NPU Driver Research Toolkit Specification

## REV81 current release authority

This specification governs the coordinated `3.0.0` release candidate after
Claude closed Cycle B at REV80. The exact REV74 NPU-equipped Windows Client
Gate 2N and exact REV78 Windows Server / Windows PowerShell 5.1
`PathSafety,Test` gate are accepted/no-repeat. The regenerated 23-file v3.0.0
public surface is current and the REV68 frozen-public exception is retired.
REV81 changes documentation only; the executable, both function contracts,
schemas, reviewed data, generated `public/**`, canonical path and accepted
Evidence remain unchanged. Historical revision requirements SHALL NOT be
interpreted as current pending gates.

## REV79 accepted architecture-contract gate

The exact REV78 Windows Server `PathSafety,Test` Evidence is accepted for the
unchanged NPU `3.0.0` source and regenerated architecture contract. Acceptance
requires and records 2/2 PASS, final `Pass`, exit `0`, authoritative Server
context, exact Evidence-manifest coverage, no Warning/Error diagnostics and
independent agreement for all 37 contract function hashes.

REV79 is a content-only final-review freeze. It SHALL NOT be interpreted as
positive NPU-equipped Windows Server installation, device-load, XRT or workload
qualification, and it SHALL NOT trigger an otherwise unchanged rerun.

## REV78 architecture-contract consistency requirement

The NPU `architecture-convergence-contract.json` SHALL be regenerated whenever
any of its 37 generic kernel function bodies changes. Packaging qualification
SHALL independently extract the exact PowerShell function extents, normalize
line endings to LF, recompute UTF-8 SHA-256, and reject every name/hash drift.
Updating the three-tool common-core contract alone is insufficient because the
NPU architecture contract is an additional NPU-specific invariant.

REV78 repins only `Start-AmdResearchEvidenceSession` and
`Start-AmdEmergencyEvidenceSession`. The NPU script and executable version
remain byte-identical to REV77 / `3.0.0`.

## REV77 private Evidence execution-context contract

Every normal and emergency Evidence `run-context.json` SHALL contain one
`ExecutionContext` object with the common Windows host fields and typed
collection state. Windows Client, Domain Controller, Server, other-Windows,
non-Windows, and unavailable-inventory behavior SHALL be covered by synthetic
self-tests. Absence of NPU hardware does not alter host OS classification.

The private Evidence schema advances to
`amd-npu-driver-research-evidence/1.3`; executable version stays `3.0.0` and
NPU selection/publication semantics remain unchanged.

## REV76 previous authority and release boundary

This specification governs executable version `3.0.0`. NPU Gate 2N is
accepted and its generated public surface is incorporated. REV76 leaves the
root script, schemas and common-core contract unchanged. The remaining
Windows Server `PathSafety,Test` gate validates only shared platform and
Evidence contracts; it SHALL NOT be cited as positive NPU selection,
installation/load, XRT or workload qualification.

## Current authority and release boundary

This specification governs executable version `3.0.0`. Umbrella revisions
such as `REV75` identify coordinated package/document evolution and do not
silently change the executable version, schemas, generated `public/**` data or
qualification scope.

The exact REV74 NPU Windows Client full run is accepted at 15/15 stages and
exit code `0`. Its self-contained 23-file public snapshot is the REV75
repository public authority. This acceptance is research/publication evidence;
it is not driver installation, kernel-load, workload or Windows Server proof.

The accepted Windows Server `PathSafety,Test` smoke establishes only the
environment, common self-test, Evidence-finalization and summary contracts for
the exact source. On a host without an NPU it is a valid negative-environment
smoke, not NPU-equipped Server runtime proof. `NotObserved` and
`NoNpuDriverRequired` SHALL NOT be rewritten as runtime failure.

The `280`, historical `RAI1.5-280`, and `376` artifacts SHALL remain independent
research records. Automatic resolution SHALL use reviewed local NPU device
identity and package INF boundaries, SHALL NOT rank the package versions
globally, and SHALL return `ReviewRequired` when the evidence is insufficient.

A qualification-only cross-tool launcher SHALL NOT be part of the release
surface. A future included orchestrator requires a separately reviewed,
data-driven multi-scenario contract with explicit safety and evidence scopes.

## rev74 cardinality and architecture-contract requirements

- A conditional expression assigned to a collection variable that is later
  consumed through `.Count` SHALL wrap the entire expression in `@(...)`.
- `Test-AmdEvidencePublicSnapshot` SHALL remain byte-identical between NPU and
  Graphics after the tool-specific files are parsed into function extents.
- The NPU-only architecture-convergence contract SHALL be regenerated from the
  exact source whenever a listed generic-kernel function changes.
- A stale architecture hash SHALL fail Test; correction SHALL update the source
  or regenerate the reviewed contract, never bypass the comparison.
- The canonical tool-local path policy SHALL remain unchanged.

## rev72 self-contained public Evidence requirements

- A current run that successfully completes Build, Validate and public
  promotion SHALL copy the complete validated `public/**` tree into the
  private Evidence ZIP at `snapshot/public/**`.
- `snapshot/public/publication-manifest.json` SHALL bind the exact executing
  script SHA-256 and SHALL cover every snapshotted public payload exactly once.
- Evidence finalization SHALL compare live-public and snapshot path sets,
  sizes and SHA-256 values and SHALL reject missing, extra or byte-different
  files.
- Evidence finalization SHALL independently compare every public payload with
  its publication-manifest size and SHA-256 declaration.
- A failed public snapshot or comparison SHALL fail closed, produce no normal
  PASS Evidence archive and preserve emergency diagnostic evidence.
- The operator SHALL NOT be required to create or return a separate public ZIP
  for release review. The Evidence ZIP is the self-contained review artifact.

## rev71 matrix schema-authority requirements

- `data/hardware-driver-selection.json` SHALL remain the reviewed runtime
  selection authority and its `authority.selectionKey` SHALL be
  `WindowsPnpHardwareIdsMatchedAgainstReviewedInfModels`.
- `schemas/driver-compatibility-matrix.schema.json` SHALL require the same
  value at `Scope.PackageSelectionKey`; `NpuIdentityId` SHALL NOT be restored
  as the runtime package-selection key.
- Test SHALL fail closed if the matrix schema version is not `1.3`, if the
  schema omits the selection-key `const`, or if that `const` differs from the
  reviewed hardware-selection authority.
- Validate SHALL compare the generated matrix schema version and selection key
  with the shipped schema and reviewed authority before public promotion.
- The schema remains `1.3` because the frozen repository public surface never
  promoted a `1.3` document; REV71 corrects the first Cycle B candidate before
  that schema is released.
- An independent standards-based JSON Schema replay remains a Cycle B release
  gate and is not replaced by these targeted in-tool semantic checks.

## rev61 public schema-version requirements

- Generated `catalog/processor-catalog.json` and `catalog/processor-driver-applicability.json` SHALL obtain `SchemaVersion` from the `const` in their corresponding public JSON Schema.
- Public dataset consistency validation SHALL compare those documents against the same schema-authoritative values and SHALL NOT retain an independent version literal.
- The Test stage SHALL fail closed when either public schema is missing, invalid, or declares a value other than the reviewed processor catalog `1.3` and processor-driver applicability `1.1` contracts.
- This correction SHALL NOT change the 165-function common core, runtime hardware-selection authority, package lanes or certificate target policy.

## rev60 public structure requirements

- Public sanitization SHALL preserve safe explicit null-valued object properties and null array elements so required JSON structure is not changed by privacy filtering.
- A null return produced by rejecting a forbidden string or private path SHALL remain distinct from an explicit source null; rejected private values SHALL NOT be reintroduced.
- `processor-catalog.json` SHALL retain the required `productIdTray` property for every processor, using JSON `null` when no reviewed tray identifier exists.
- Markdown generation SHALL accept the same sanitized object graph without a StrictMode missing-property failure.

## rev59 public-path requirements

- Build SHALL sanitize catalog, matrix, release-analysis and comparison objects before both JSON and Markdown publication.
- Every shared path-bearing property, including nested `ArchivePath`, SHALL be excluded from NPU public objects; runtime logs, errors, host identity and invocation details SHALL remain private evidence.
- Decoded-scalar validation SHALL remain fail closed and SHALL use the shared three-tool privacy primitives.
- NPU 280/376 lane, selection and certificate-target semantics SHALL remain unchanged.

## rev58 extraction path and downstream-gate requirements

NPU SHALL use the tool-local common short-path constructor for every artifact and nested container. Runtime extraction SHALL match the startup predictor. `ExtractedWithErrors` SHALL NOT be downstream-acceptable; Extract and Signature SHALL require every selected package to be `ExtractionComplete`.



## rev52 interruption and diagnostic lifecycle contract

Every tracked stage SHALL begin in `RUNNING` and SHALL become PASS only after
its body returns normally. Ctrl+C or pipeline stop SHALL be finalized as
`INTERRUPTED`, SHALL produce non-PASS assessment with exit code `130`, and SHALL
retain stage timing. Diagnostic JSONL SHALL include trace start/stop and stage
start/completion lifecycle events.

## rev51 common bootstrap/finalization contract

The tool SHALL print bootstrap identity before evidence initialization, SHALL
report the start and elapsed completion of each Test operation, and SHALL use
the common accelerated Canonical JSON runtime. A failure of normal evidence
finalization SHALL trigger verified emergency ZIP and SHA-256 creation without
deleting the raw evidence directory. Emergency evidence SHALL never be treated
as qualification PASS evidence.

## Canonical JSON normative requirements (rev50)

All toolkit-controlled JSON writes MUST route through `Save-CanonicalJsonFile`;
all toolkit-controlled JSON reads MUST use the matching recursive-descent
parser. Date-looking strings MUST remain strings. The canonical byte contract
is UTF-8 without BOM, LF, two-space indentation, insertion-order keys, literal
non-ASCII, explicit nulls and exactly one trailing LF.

This document defines the normative behavior of `Invoke-AmdNpuDriverResearch.ps1` for the current 3.0.0 Cycle B line. Historical release qualification evidence remains bound to its exact source SHA-256 and is not silently reused for changed source.

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
- Windows PnP HardwareID/CompatibleID and reviewed INF identity modeling;
- Windows Server static applicability analysis;
- hardware-only driver-track recommendation modeling;
- retained non-authoritative processor/NPU research and audit references;
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

The first stable repository release was `v1.0.0`. Its generated processor-oriented
publication remains historical evidence and SHALL NOT override the current reviewed
hardware-only selection contract.

The current coordinated release candidate is `3.0.0`. All three research
scripts already carry that stable version, the required minimum-sufficient
Windows Client and bounded Windows Server gates are accepted, and Claude has
closed Cycle B. Documentation-only package revision changes SHALL NOT alter the
executable version or invalidate accepted exact-source evidence.

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

The canonical JSON writer SHALL emit .NET enum values as JSON strings. It SHALL
NOT emit an enum name as an unquoted JSON token. The Test stage SHALL exercise an
enum serialize/parse round trip. Runtime local-PnP and hardware-selection JSON
SHALL be parsed successfully before HardwareIdentity can report PASS.

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

### 9.1.1 Full-research and certificate-verification scope separation

A normal no-argument/`All` run SHALL select every reviewed public artifact for
Acquire, Extract, Inspect, DriverBinary, Compare and Matrix processing. This
includes historical `NPU_RAI1.5_280_WHQL.zip`.

The following sets SHALL remain independent:

1. full research corpus;
2. recommendation-eligible device/package cases;
3. deep certificate-verification targets.

Historical inclusion in the full research corpus SHALL NOT make the artifact a
current recommendation. Default certificate verification SHALL select the
newest selected artifact inside each current NPU-type package case and SHALL
exclude historical RAI1.5. A single explicit `-ArtifactId` selection MAY verify
that exact artifact, including a historical fixture, matching the Chipset
`OnlySelectedRelease` contract.

The Metadata stage SHALL emit a deterministic certificate-verification target
plan. The Signature stage SHALL consume this plan rather than re-derive scope
from recommendation eligibility or global version ranking.

### 9.1.2 Signature-verification engine

The Signature stage SHALL run after Inspect and before Build. It SHALL analyze
candidate files by SHA-256 content groups so duplicate extracted paths do not
produce duplicate cryptographic identities.

The host-neutral evidence scope SHALL include:

- CMS/PKCS#7 envelope parsing and cryptographic diagnostic status;
- nested-signature and timestamp-token traversal;
- X.509 certificate inventory;
- PE WIN_CERTIFICATE parsing;
- Authenticode signed-content digest versus computed PE digest comparison.

On Windows, the native evidence scope SHALL additionally include
`Get-AuthenticodeSignature`, Windows catalog member enumeration, catalog hash
calculation, SignTool identity/capability evidence, catalog-to-kernel correlation
and catalog-bound verification. SignTool profiles SHALL remain distinct:

1. `/all /v /pa` for ordinary Authenticode policy observation;
2. `/all /v /kp` for kernel-policy diagnostic observation;
3. `/v /kp /c <catalog> <driver>` for required catalog-bound kernel policy;
4. `/v /c <catalog> /o 2:<build> <driver>` for target-OS catalog checks against
   Windows Server builds 14393, 17763, 20348 and 26100.

The target-OS profile SHALL NOT silently add `/kp` or `/pa`. Native tool result
classification SHALL use process launch state and exit code, not localized
console text. Failure to establish a catalog association SHALL be recorded as
`NotObservedCatalogAssociationUnavailable`; it is an evidence gap, not a
fabricated verification failure.

Static signature analysis MAY enter generated per-artifact public research
output. Raw SignTool output, native paths and host security posture SHALL remain
private Evidence. The stage SHALL be read-only: no package mutation, certificate
installation, driver installation or AMD vendor executable execution is allowed.

Windows Client and Windows Server executions SHALL remain different evidence
scopes. A successful Client-native check SHALL be reviewed before a Server test
is authorized and SHALL NOT by itself prove kernel load or NPU functionality on
Windows Server.

### 9.1.3 Fail-closed Windows Client qualification mode

`-RequireWindowsClientSignatureQualification` SHALL be valid only when the
resolved stage set contains Signature, the default reviewed artifact corpus is
used, and Evidence ZIP creation remains enabled. `-PackagePath`, `-ArtifactId`
and `-SkipEvidenceArchive` SHALL be rejected in this mode.

The qualification SHALL fail unless all of the following are true:

- execution class is exactly `WindowsClient`;
- SignTool is available;
- full research contains three reviewed public artifacts;
- certificate verification contains exactly two current NPU-type targets;
- both targets have static and Windows-native analysis;
- recursive CMS/Authenticode parse failures and PE digest mismatches are zero;
- at least one kernel binary is observed;
- every kernel binary has a verified explicit catalog-bound kernel-policy check
  and verified target-OS checks for Server 2016/2019/2022/2025;
- catalog-association gaps, per-kernel coverage gaps and required-profile
  non-zero SignTool results are zero;
- mutation remains false.

The result SHALL be embedded as `WindowsClientQualification` in private native
signature Evidence. PASS authorizes evidence review only; it SHALL NOT
automatically authorize Windows Server execution.

Operator-facing output SHALL distinguish the full research corpus from the deep
certificate target set by name, not by an unexplained fraction. A default run
SHALL state that the historical RAI1.5 package is acquired, extracted and
inspected but excluded only from default deep certificate verification. Shared
kernel implementation names and Chipset-only release-selection terminology
SHALL NOT be used as NPU package-scope descriptions. The final assessment and
timing summary SHALL be present in the archived console transcript.

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

### 9.4 Dual-line research retention and deployment boundary

The normal research corpus SHALL retain the reviewed later public 280 and 376 artifacts. The toolkit SHALL acquire, extract, and compare both lines and SHALL NOT remove 280 merely because a reviewed deployment decision currently prefers 376.

The historical Ryzen AI 1.5 280 artifact MAY remain as a regression fixture. Inclusion in the research corpus SHALL NOT imply production recommendation eligibility.

The current research source applies the reviewed AMD production-family preference for 376 when one
completely enumerated Windows NPU device instance matches the reviewed 376 INF
model and the target Windows build satisfies the as-published INF selector.
AMD's live Ryzen AI Software 1.8.0 installation page checked on 2026-08-21
agrees with the reviewed 376 production-family statement. This source behavior is not installation,
deployment, transformation, signing or runtime authorization. 280 SHALL remain
in the research corpus and SHALL NOT be silently introduced as an automatic
fallback by documentation alone.

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

## 14. Hardware identity and driver-track selection model

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

### 14.1 Normative selection authority

`data/hardware-driver-selection.json` SHALL be the reviewed machine authority for
driver-track selection. Its source schema SHALL be
`schemas/source-data/hardware-driver-selection.source.schema.json`.

The resolver SHALL use only:

1. locally enumerated Windows PnP instance identity and available HardwareID/CompatibleID values for each NPU candidate;
2. reviewed INF model HardwareIDs;
3. the locally observed Windows build and reviewed INF TargetOSVersion/build floor;
4. the reviewed current AMD production-family policy that 376 is the preferred track.

The resolver's current result is a research output. The 376 preference agrees
with current AMD publication authority, but downstream production policy SHALL
still require its normal independent deployment and runtime gates.

The resolver SHALL NOT use CPU SKU, CPUID, CPU marketing name, CPU/NPU combination,
NPU marketing name, firmware device revision, Linux AIE topology, XRT device label
or inferred codename. `SUBSYS` and PCI `REV` SHALL be preserved as evidence when
present but SHALL NOT synthesize an INF selector that the reviewed INF does not contain.

Each NPU device instance SHALL be resolved separately. Several instances SHALL NOT
be flattened into one identity set.

Normal `-ResolveHardwareSelection` SHALL enumerate the local Windows PnP inventory.
`NoNpuDriverRequired` SHALL require `EnumerationStatus=Complete` and zero NPU
candidates. Enumeration failure or an NPU-signaled AMD PCI instance outside the
reviewed INF identity set SHALL return `ReviewRequired`.

`-ObservedNpuHardwareId` SHALL require `-UseObservedNpuHardwareIdOverride` and
SHALL be labeled as a manual offline/test override. An empty manual override SHALL
be rejected and SHALL NOT produce `NoNpuDriverRequired`. If the build is not
explicitly supplied, the Windows build SHALL be obtained from
`Win32_OperatingSystem.BuildNumber` with an OS-version fallback.

The resolver decisions SHALL be:

| Condition | Decision |
|---|---|
| complete identity matches reviewed 376 INF and build satisfies selector | `376` |
| completed enumeration contains no NPU device instance | `NoNpuDriverRequired` |
| non-empty identity is unknown/incomplete or build is below selector | `ReviewRequired` |
| any automatic path to 280 | prohibited |

Every result SHALL state that installation is not authorized and Windows Server
runtime proof is false. A 376 decision SHALL state that automatic 280 fallback is disabled.

## 15. Processor catalog contract (non-selection reference)

`data/processor-catalog.json` SHALL be an exact-SKU catalog.

Unknown processor names SHALL NOT inherit NPU capability from:

- series prefix;
- approximate marketing family;
- core count/layout;
- iGPU family;
- presumed die/silicon similarity.

The catalog SHALL encode positive and negative NPU availability evidence where reviewed.

At 0.9.0-dev the reviewed catalog contains 112 exact SKUs, including 90 `AvailablePublished` and 22 negative-control/no-driver-required SKUs.

The processor catalog SHALL remain available for historical research, coverage,
provenance and human audit. It SHALL NOT be consulted by the hardware-only
driver-track resolver. Unknown CPU SKUs therefore SHALL NOT alter a decision made
from a completely enumerated NPU PnP identity; unknown NPU PnP identity still fails
closed as `ReviewRequired`.

## 16. Processor-driver applicability contract (retained audit output)

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

### 16.2 Historical hierarchy and non-authority boundary

The retained processor dataset MAY preserve a relation equivalent to:

```text
exact CPU SKU
  -> NPU availability
  -> codename / expected NPU identity
  -> exactly one resolved NPU device-type package lane
  -> reviewed artifact rule within that lane
  -> HWID/static package applicability
  -> AMD published codename/family support
  -> Windows Server static profile result
  -> recommendation eligibility / visibility
  -> optional observed-runtime evidence
```

This relation SHALL be labeled non-authoritative for runtime driver-track
selection. It SHALL NOT override `data/hardware-driver-selection.json`, and the
tool SHALL NOT promote the rev34 742-row Excel-derived mapping candidate into
runtime authority.

A loose DEV-only string search SHALL NOT authorize a recommendation. The
hardware-only resolver requires a complete device-instance PnP identity set,
reviewed INF model match and target-build selector. Even then, the `376` result
is a research recommendation and SHALL NOT authorize installation.

The two current NPU packages SHALL NOT be ranked as one global version stream.
Version comparison is permitted only inside one package lane already resolved by
reviewed NPU identity evidence. Historical packaging fixtures SHALL NOT enter
current recommendation ranking. An unresolved or multiply matched package lane
SHALL return `ReviewRequired`.

### 16.3 Decision classes

The generated applicability layer SHALL distinguish at least:

- `SelectLatestWithinResolvedNpuTypeLane`;
- `ReviewRequired`;
- `NoNpuDriverRequired`.

`ReviewRequired` is a valid fail-closed result, not a generation failure.

### 16.4 Gorgon Point / Gorgon Halo boundary

The reviewed AMD Ryzen AI Software 1.8.0 publication states 376 production
support for Phoenix, Hawk Point, Strix, Strix Halo, and Krackan Point. The live
`latest` installation page checked on 2026-08-21 agrees with that statement.

Therefore Gorgon Point MAY remain `ReviewRequired` in the retained historical
processor audit output even when broad `DEV_17F0` and binary generation-recognition
evidence exist. That CPU-family row SHALL NOT be consulted by the hardware-only resolver.

Gorgon Halo MAY likewise remain `ReviewRequired` in the retained processor audit
output. A future observed NPU device instance is resolved only from its PnP/INF
contract, without CPU-family inference.

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

The v1.0.0 `public/**` tree retained in the REV68 Cycle A correction candidate
was a frozen historical publication snapshot, not a current-valid
publication. Cycle B regenerated the complete surface from the reviewed v3.0.0
source/data/schema authorities. The resulting 23-file public tree validates
against the shipped current schemas and is the accepted publication authority.
The earlier processor-oriented v1.0.0 output remains historical audit evidence
and SHALL NOT be used as hardware-selection authority.

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

Reviewed binary assessment workbooks under `authored/**` are authored commit candidates, not generated `public/**` output. They SHALL be accompanied by a reviewable Markdown record and SHALL NOT be added to the publication manifest.

## 21. Evidence/failure contract

Evidence establishment SHOULD occur before substantial runtime work so a later stage failure can be preserved.

Ordinary failures SHALL be represented through stage results and finalized Evidence where output remains writable.

Fatal bootstrap failure SHALL use the emergency evidence path rather than silently dropping the reason for failure.

Vendor payloads SHALL remain excluded from Evidence by default unless the operator explicitly requests otherwise.

When the Test stage runs, the toolkit SHALL persist structured
`inventory/test-stage-evidence.json` containing `SignedCmsAvailable`, test counts,
and the Evidence-snapshot contract result. When hardware selection is requested,
the toolkit SHALL persist `inventory/local-npu-pnp-evidence.json` and
`inventory/hardware-selection-result.json`. Every generated file in this set
SHALL be copied beneath `snapshot/inventory/` before `evidence-manifest.json` is
created. A stage summary alone SHALL NOT replace these machine-readable runtime
artifacts.

Hash/length agreement alone SHALL NOT qualify a runtime JSON artifact. Required
runtime JSON SHALL also be syntactically parseable. A manifest that accurately
hashes invalid JSON preserves the invalid bytes but does not close an Evidence
gate.

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

Collector 1.3.0 SHALL emit `npu-hardware-selection-input.json` as an observation
contract. It SHALL preserve each device instance's complete HardwareID and
CompatibleID set, emit stable string error-code values, classify Client versus
Server from OS `ProductType`, and distinguish complete zero-candidate
enumeration from incomplete evidence.

The collector SHALL NOT perform the downstream 280/376 decision. CPU SKU,
CPU/NPU combinations, firmware revisions and XRT labels SHALL NOT be selection
inputs, and automatic 280 fallback SHALL remain disabled.

A Windows Server NPU-positive observation MAY retain a custom-built or
self-signed installed driver. Public-376 hash equality and XRT presence SHALL
NOT be required to record the Server runtime state. This observation does not
authorize deployment and does not prove application-level workload success.

Every generated JSON SHALL reparse before acceptance. The finalization path
SHALL verify the exact manifest file set/length/SHA-256 and reopen the ZIP to
verify portable paths, unique entries, count, length and SHA-256. A ZIP that is
created but fails any integrity gate SHALL not be reported as accepted evidence.

## 24. Deployment-consumption contract

A future `Deploy-AMDNpuDriverOnWindowsServer.ps1` integration SHOULD consume the
reviewed hardware-only selection contract in a fail-closed manner.

The deployment script SHOULD:

1. complete Windows PnP enumeration of NPU device instances;
2. resolve each instance independently from its HardwareID/CompatibleID set;
3. return `NoNpuDriverRequired` only for an explicitly completed empty enumeration;
4. match against reviewed 376 INF models and target-build selector;
5. return `ReviewRequired` for unknown, incomplete or selector-ineligible input;
6. preserve original vendor artifact identity before transformation;
7. treat `376` as a research recommendation only until a separate deployment gate authorizes action;
8. transform/re-sign only when target deployment policy and runtime evidence justify it;
9. never select or fall back to 280 automatically.

CPU SKU, CPUID and CPU/NPU combination SHALL NOT be deployment-selection inputs.
Selection of 376 SHALL NOT erase, bypass, or narrow the two-line research corpus.

## 25. Release qualification

The historical 1.3 finalization line required the exact source to satisfy the
release gates in `TESTING.md`. The coordinated 3.0.0 source has since satisfied
the applicable Client, publication, bounded Server and independent-review
gates. Future changed source SHALL re-run only the minimum gates affected by
that change, including as applicable:

- source AST/static-analysis gate;
- built-in tests;
- Linux/PowerShell 7 static qualification;
- Windows PowerShell 5.1 full run;
- reviewed-artifact hash identity;
- deterministic cross-runtime `public/**` comparison;
- schema/dataset validation;
- publication privacy/manifest verification;
- external review/audit workflow used by the repository.

If documentation claims the companion collector is real-device-qualified at
v1.3.0, one exact-source NPU-positive run SHALL be retained as evidence. The
future Windows Server positive run after production build-script redevelopment,
separate driver-build review and authorized application MAY serve as this single
gate; a redundant ceremonial Client rerun is not required.

## 26. Completion-state and remaining-work contract

The present main-runner hardware-selection contract SHALL be considered
functionally qualified by the accepted Client negative, Client positive and
Windows Server 2025 negative-control evidence. Those accepted gates SHALL NOT be
repeated solely for documentation, collector qualification or stable-promotion
planning.

The companion collector 1.3.0 SHALL remain classified as
`StaticAndSyntheticQualified_RealDevicePositiveDeferredDependencyBlocked` until
exactly one current-source NPU-positive Evidence package is reviewed. The gate
SHALL NOT be scheduled until the production NPU driver build script has been
redeveloped and reviewed, and a Server driver has been built and applied under a
separate explicit authorization. That future Windows Server observation MAY
satisfy the gate. A second Client positive run SHALL NOT be required when the
Server gate passes.

That collector gate SHALL verify the observation and archive contracts only:

1. `Host.ExecutionClass=WindowsServer` and OS `ProductType` is 2 or 3;
2. local PnP enumeration completed and produced at least one NPU candidate;
3. the candidate retains its complete HardwareID/CompatibleID identity set;
4. status, service and stable `ConfigManagerErrorCode` indicate a healthy
   observed device, and installed driver/INF/service-binary evidence is present;
5. `ServerPositiveCase.ObservationStatus=NpuRuntimeObservedHealthy`;
6. every JSON, manifest row and reopened ZIP entry passes its integrity gate.

Public-376 component equality and XRT presence SHALL remain optional evidence
for this Server observation. CPU identity, CPU/NPU combinations, firmware and
Linux topology SHALL remain non-inputs. The gate SHALL NOT authorize driver
build, application, deployment, INF conversion, signing or application-level
workload claims.

Independent review and stable promotion SHALL remain separate release decisions.
The main-runner release process MAY proceed while retaining the explicit
collector qualification disclaimer. The collector positive gate SHALL remain
deferred until its production-build dependency and authorization chain are
satisfied; it SHALL NOT be treated as the next task or requested as an immediate
user test.
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

- `PathSafety` SHALL be automatically prepended to every workflow and SHALL block unsafe Windows roots before AMD network activity.
- Recursive extraction SHALL list each container before extraction and reject rooted, parent-traversal, or over-limit paths.
- Text and file HTTP requests SHALL use the shared sequential bounded-retry policy and record sanitized attempt evidence.
- File downloads SHALL accept only complete byte-conserving responses whose PE/ZIP payload validation succeeds, and SHALL rename partial files atomically only after acceptance.
- `data/current-three-tool-common-core-contract.json` SHALL be the current three-tool parity authority. `predecessor-shared-core-contract.json` remains historical evidence only.
