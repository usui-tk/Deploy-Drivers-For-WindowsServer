# AMD Graphics / Chipset INF Semantic Sync

**Graphics baseline: 0.5.0**

This document records the semantic contract forward-ported from the chipset research work without importing chipset-specific selector implementation.

## Shared contract

- `amd-inf-semantic-contract/1.0`
- `amd-inf-identifier-taxonomy/1.0`
- `amd-inf-topology/1.1`
- TargetOSVersion canonical fields: `Architecture`, `OSMajorVersion`, `OSMinorVersion`, `ProductType`, `SuiteMask`, `BuildNumber`.
- Models identifiers are source evidence and are preserved without fixed-prefix filtering.
- `Identifier` / `CompatibleIdentifiers` provide taxonomy while `HardwareId` / `CompatibleIds` remain compatibility aliases.
- Server profiles expose canonical fields and retain 0.4.x aliases.
- `CanonicalStaticAssessment` uses `NativeCandidate`, `ProjectionCandidate`, `WdfRequirementReview`, `ReviewRequired`, `NotApplicable`, `Indeterminate`.
- `WdfScope=InfWideConservative`; DDInstall-scoped WDF is not claimed.
- `RuntimeCompatibility=NotEstablished`; static selection is not runtime proof.

## Graphics-only contracts retained

- Canonical unit is `ArtifactKey`, not release version.
- PRO siblings share `ReleaseKey=ProEdition|MultiArtifact|<version>` and differ by `ArtifactRole`.
- `InstallManifest.json`, Graphics Analysis Surface, and graphics artifact-role classification remain Graphics-specific.

## Explicit non-port

Chipset-specific `DevID.xml`, `Info.xml`, APS XML, `/SETxxx`, MSI selector observation, and host selector emulation are not implemented in Graphics. Only generic evidence vocabulary and INF semantics are shared.

## Migration

Historical 0.4.3 canonical/evidence files remain historical evidence. New 0.5.0 regeneration uses topology 1.1. `schemas/inf-topology-legacy-1.0.schema.json` is retained for historical validation.
