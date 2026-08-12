# AMD Chipset / Graphics INF Semantic Sync Contract

Status: **Contract 1.0 synchronized on 2026-08-10.**

This note is intentionally present in both research-tool trees. The goal is semantic interoperability, not code-module sharing. Each research tool remains a single self-contained PowerShell script and retains the domain-specific identity model required by its installer family.

## 1. Shared contract versions

```text
INF semantic contract : amd-inf-semantic-contract/1.0
Identifier taxonomy   : amd-inf-identifier-taxonomy/1.0
INF topology           : amd-inf-topology/1.1 (newly generated topology)
```

Machine-readable shared vocabulary is defined by:

```text
schemas/inf-semantic-contract.schema.json
```

Historical records are not silently rewritten. Graphics 0.4.1 canonical artifacts retain their original `inf-topology/1.0` topology until a real-artifact regeneration is performed; its legacy schema is retained as `inf-topology-legacy-1.0.schema.json`.

## 2. Semantics synchronized in both tools

Both tools SHALL use equivalent meaning for:

1. quote-aware INF CSV splitting;
2. `[Strings]` token resolution;
3. multiple `[Manufacturer]` lines evaluated independently;
4. TargetOSVersion architecture / OS major / OS minor / ProductType / SuiteMask / minimum BuildNumber parsing;
5. Models sections reached only from the exact Manufacturer base/decorations, avoiding DDInstall/Services/Wdf wildcard false positives;
6. Device description + DDInstall + primary Models identifier + Compatible IDs as topology, not only a flattened HWID set;
7. empty selected Models sections as explicit exclusions;
8. `AsPublished` kept separate from analytical ProductType `1 -> 3` Server Projection;
9. Server 2016 / 2019 / 2022 / 2025 x64 ProductType=3 profiles;
10. WDF declarations kept separate from runtime compatibility claims;
11. `RuntimeCompatibilityProven=false` for static analysis;
12. host/vendor dynamic evidence never promoted into static vendor support claims.

## 3. Shared identifier taxonomy

A Models-section identifier is preserved exactly and classified without assuming PCI syntax.

Canonical `Identifier.Kind` values:

```text
MissingIdentifier
RootEnumeratedHardwareId
DeviceClassSpecificId
GenericHardwareId
EnumeratorHardwareId
NetworkSoftwareComponentId
NetworkComponentOrSoftwareId
InfModelIdentifier
UnclassifiedIdentifier
```

Examples handled by this contract include:

```text
PCI\VEN_1022&DEV_....
ACPI\AMDI....
ACP\DEVTYPE_....
ROOT\....
{class-guid}\component
bare NetService component IDs
```

Graphics previously used a known-prefix filter for its flattened `HardwareIds` convenience view. The synchronized line now preserves **all non-empty Models identifiers** in that view while `Identifier` remains the semantic source of truth. This avoids under-counting valid `ACP\...` and class-specific identifiers.

## 4. Shared Server profile fields

Canonical profile fields are:

```text
ProfileId
ShortName
Architecture
OSMajorVersion
OSMinorVersion
BuildNumber
ProductType
SuiteMask
DocumentedKMDF
ObservedKMDF
DocumentedUMDF
ObservedUMDF
WdfConfidence
```

For migration safety, tools MAY also emit existing aliases such as `OSMajor`, `OSMinor`, `Build`, and nested `Kmdf` / `Umdf` objects. The canonical fields above are the cross-tool contract.

## 5. Shared static-assessment vocabulary

Canonical machine-readable values:

```text
NativeCandidate
ProjectionCandidate
WdfRequirementReview
ReviewRequired
NotApplicable
Indeterminate
```

Graphics MAY retain its established presentation labels:

```text
NATIVE_CANDIDATE  -> NativeCandidate
PATCH_CANDIDATE   -> ProjectionCandidate
REVIEW_REQUIRED   -> ReviewRequired (or WdfRequirementReview when WDF is the reason)
NOT_APPLICABLE    -> NotApplicable
INDETERMINATE     -> Indeterminate
```

New Graphics records expose `CanonicalStaticAssessment` in addition to the legacy/presentation status. Chipset exposes the same canonical field.

## 6. WDF scope decision

**Decision for Contract 1.0: `InfWideConservative`.**

Both current qualified implementations calculate WDF at INF scope. The synchronized output now labels that scope explicitly.

`DDInstallScoped` is reserved in the shared schema for a future contract revision, but is **not implemented or claimed by this Sync**. A DDInstall-scoped resolver requires additional association logic and real-artifact regression before it can replace the conservative maximum.

## 7. Canonical unit intentionally remains different

This is a domain-model difference, not a Sync defect.

```text
Chipset  : CanonicalUnitKind = ReleaseVersion
Graphics : CanonicalUnitKind = ArtifactKey
```

Graphics can legitimately have multiple AMD installer artifacts under one release/version; collapsing it to version 1:1 would lose evidence. Chipset's accepted historical model remains release-version 1:1.

## 8. Host/vendor-selector evidence boundary

Chipset already implements host inventory and AMD chipset selector reverse engineering. Graphics does not yet implement an equivalent vendor-selector stage.

The synchronized contract covers only the generic envelope:

- actual host device identity and Hardware/Compatible IDs;
- exact versus compatible identifier match provenance;
- static declarative vs static binary inference vs dynamic observation;
- single-host vs multi-host evidence scope;
- `Emulated` / `EmulationConfirmed` distinction;
- unresolved vendor filtering as first-class evidence;
- host-specific evidence excluded from accepted static baselines by default.

Chipset-specific `/SETxxx`, `DevID.xml`, `Info.xml`, APS XML, and MSI feature semantics are **not** imposed on Graphics.

## 9. Bidirectional implementation lessons applied

Graphics -> Chipset:

- quote-aware CSV splitting is now used for Manufacturer and Models RHS parsing.
- the earlier Graphics finding that Models topology must be Manufacturer-reachable remains a shared invariant.

Chipset -> Graphics:

- semantic identifier taxonomy added;
- `ACP\...`, class-specific, root, generic, and software-component identifiers no longer depend on a PCI/ACPI/USB prefix allow-list;
- shared profile field aliases added;
- `CanonicalStaticAssessment` added;
- WDF scope explicitly labeled `InfWideConservative`.

## 10. Validation performed at this Sync

Source-level validation completed:

```text
Graphics 0.4.2-sync-dev : PowerShell 7.6.4 AST = 0 errors; -Stages Test = PASS
Chipset  1.2.3-sync-dev : PowerShell 7.6.4 AST = 0 errors; -Stages Test = PASS
```

The Graphics synthetic Server self-test includes an additional identifier-taxonomy case covering `ACP\...` and device-class-specific identifiers.

This Sync deliberately did **not**:

- analyze Graphics Set 3 PRO 26.Q1;
- rerun Graphics Set 1/2 real installer qualification;
- rerun the Chipset 25-release Windows PowerShell 5.1 acceptance;
- replace either tool's qualified/accepted baseline.

## 11. Gates before promotion

Before either synchronized line is promoted:

1. regenerate and validate Graphics real-artifact canonical records under 0.4.2-sync-dev;
2. run Graphics Windows PowerShell 5.1 real-artifact qualification;
3. run Chipset full 25-release Windows PowerShell 5.1 acceptance after all 1.2.x changes stabilize;
4. validate canonical JSON against the new shared contract/schema;
5. only then consider validated `public/**` promotion;
6. if DDInstall-scoped WDF is implemented later, revise the shared contract and requalify both tools.

## 12. Graphics Set 3 hard stop

This semantic Sync does not authorize or perform Set 3 analysis. The existing Graphics handoff stop condition remains in force: PRO Edition 26.Q1 Windows 11 RDNA Set 3 must not be CRC-validated, opened, extracted, or analyzed until the user explicitly authorizes that separate workflow.
