# AMD Graphics Driver Research Toolkit

**Current source version: 1.0.0 release candidate**

`Invoke-AmdGraphicsDriverResearch.ps1` is a PowerShell research tool for reconstructing AMD Windows graphics-driver publication identities, selecting a bounded set of representative installer artifacts, extracting those artifacts statically, parsing their INF/WDF metadata, and producing evidence-oriented Windows Server applicability data.

The toolkit is deliberately **research-only**. It does not execute AMD Setup, install drivers, patch INF files, generate catalogs, sign packages, or claim runtime compatibility. Its job is to make the vendor package structure and Windows selection semantics explicit enough that later deployment or self-signed-driver work can be designed from evidence rather than guesswork.

## What the toolkit answers

The normal research workflow is intended to answer questions such as:

- Which AMD support product groups publish which graphics-driver tracks?
- Which concrete AMD installer EXEs represent the newest releases in the newest three available major generations for each selected track?
- What is the immutable identity of each installer artifact?
- Which INF files and component packages are present after static extraction?
- Which `[Manufacturer] -> TargetOSVersion -> Models -> identifier` relationships are declared by those INFs?
- Which Windows Server 2016 / 2019 / 2022 / 2025 profiles are selected **as published**?
- Which additional candidates appear under a non-mutating client `ProductType=1` to Server `ProductType=3` projection?
- What KMDF/UMDF requirements are declared by the package?
- Which observations are vendor-published facts, embedded installer facts, payload observations, static analysis results, or runtime evidence?

The toolkit does **not** answer whether a projected package will actually load and operate correctly on Windows Server. Runtime acceptance is a separate test activity.

## Quick start

### Built-in self-tests

```powershell
.\Invoke-AmdGraphicsDriverResearch.ps1 -Stages Test
```

### Normal product-driven full run

```powershell
.\Invoke-AmdGraphicsDriverResearch.ps1 -Stages All
```

With no explicit historical filters, the normal stage sequence is:

```text
Test
  -> ProductDiscover
  -> ProductMetadata
  -> Select
  -> Acquire
  -> Extract
  -> Inspect
  -> Build
```

### Local installer qualification

Use this when validating a known AMD installer without live product discovery:

```powershell
.\Invoke-AmdGraphicsDriverResearch.ps1 `
  -LocalInstallerPath 'D:\Artifacts\amd-installer.exe'
```

The stage resolver selects the local research path automatically.

### Full historical research

Historical release-catalog research remains explicit opt-in because it can consume large amounts of network, disk and processing resources:

```powershell
.\Invoke-AmdGraphicsDriverResearch.ps1 -FullHistoricalResearch
```

See `SPEC.md` for the authoritative stage and selection contracts.

## Safety model

The toolkit follows these invariants:

1. AMD installer EXEs are treated as input artifacts and are **not executed**.
2. Extraction is static and bounded.
3. The original AMD EXE SHA-256 remains immutable source provenance.
4. Runtime/private data and repository-safe public data are separate surfaces.
5. Windows Server applicability is a static selector/WDF assessment, not an AMD support claim.
6. `ServerProjection` is a non-mutating analysis view. The research tool does not rewrite an INF.
7. A publication or privacy failure is fail-closed: an invalid run does not replace the last valid `public/**` surface.

## Runtime support

The script is designed for:

- Windows PowerShell 5.1 on Windows;
- PowerShell 7 on Windows;
- PowerShell 7 on Linux for static/offline qualification where the required extraction tooling is available.

The distributed script itself intentionally uses UTF-8 with BOM and CRLF line endings for Windows PowerShell compatibility.

Generated **public Markdown** follows a different repository contract: UTF-8 without BOM and LF-only line endings.

## Product-driven research model

AMD graphics-driver publication is product-driven rather than one global release stream. The toolkit therefore starts from explicit product groups under both AMD `Graphics` and `Processors` support hierarchies.

The normal lineage is:

```text
ProductGroup
  -> published product support page(s)
     -> OperatingSystemTrack + PackageFamily
        -> available release generations
           -> selected AMD installer artifacts
```

For each stable `SelectionTrackKey`, the normal policy keeps the newest release from the newest three available major generations. Identical AMD EXE URLs are globally deduplicated while every product-to-artifact relationship is preserved as provenance.

The curated product catalog is intentionally a **research-scope catalog**, not a claim that every AMD GPU/APU model is enumerated.

Detailed design rationale and real-artifact observations are consolidated in `RESEARCH-NOTES.md`.

## Release and artifact identity

Graphics release text is not sufficient to identify a concrete package.

The canonical model is:

```text
ReleaseKey  = PackageFamily | Branch | ReleaseVersion
ArtifactKey = ReleaseKey | FileName
```

This matters particularly for Radeon PRO and other multi-artifact releases where one release version can publish multiple different installer EXEs.

The original AMD EXE is the canonical vendor artifact. User-created split ZIP files used to transfer a large installer are only transport envelopes and are not used as AMD artifact identity.

## Static extraction model

Modern qualified Adrenalin and PRO installer samples expose a 7z self-extracting payload. The extractor proceeds only as deeply as necessary to reach the graphics driver analysis surface.

Once an INF-bearing `Packages/Drivers/**` surface is available, ordinary application MSI/helper executable recursion is not treated as necessary driver analysis. Legacy or unknown containers may still use bounded static recursion when no INF surface has been reached.

The embedded `Config/InstallManifest.json` is captured as **embedded evidence**. It is useful for package identity, payload paths and AMD condition strings, but it is not treated as the final authority for Windows PnP selection.

## INF and Windows Server analysis model

The canonical INF topology preserves:

```text
[Manufacturer]
  -> TargetOSVersion decoration
     -> referenced Models section
        -> model description
        -> DDInstall section
        -> identifiers / compatible identifiers
```

The toolkit does not reduce that topology to a PCI-only HWID list. Non-PCI component/software identifiers are preserved as evidence.

Static Windows Server analysis separates:

- **AsPublished** — what the vendor INF selects without modification;
- **ServerProjection** — a non-mutating simulation of client `ProductType=1` selectors projected to Server `ProductType=3`;
- **RuntimeCompatibility** — `NotEstablished` until target-OS execution testing exists.

A candidate result is not a support or runtime-compatibility statement.

## WDF analysis

KMDF/UMDF declarations are retained and compared with target Server profiles conservatively. WDF analysis is intentionally INF-wide where required; it does not invent a more precise component dependency when the INF does not establish one.

WDF success is necessary evidence for some packages, but it is not sufficient proof of loadability or functional correctness.

## Repository layout

The final tool directory is organized around a small set of stable documents and clearly separated generated surfaces:

```text
amd-graphics-driver-research/
  Invoke-AmdGraphicsDriverResearch.ps1
  README.md
  SPEC.md
  TESTING.md
  RESEARCH-NOTES.md
  CHANGELOG.md
  THIRD-PARTY-NOTICES.md
  data/                     # versioned curated/static research inputs
  schemas/                  # generated-artifact schemas
  public/                   # repository-safe generated outputs
  inventory/                # runtime staging; not a generated commit surface
  private/                  # private/debug evidence
  work/                     # extraction/download workspace
  authored/                 # authored qualification/hardening records (reviewed, committed)
  reports/                  # script-generated runtime reports (never committed)
```

### Documentation map

| Document | Purpose |
|---|---|
| `README.md` | Entry point, workflow, concepts and repository layout |
| `SPEC.md` | Normative behavioral, data, publication and evidence contracts |
| `TESTING.md` | Test matrix and release-acceptance procedure |
| `RESEARCH-NOTES.md` | Consolidated reverse-engineering knowledge and qualified real-artifact observations |
| `CHANGELOG.md` | Version-by-version implementation history |
| `THIRD-PARTY-NOTICES.md` | Third-party attribution |
| `authored/README.md` | Index of authored qualification/hardening records |

Historical development reports are intentionally kept out of the top-level documentation surface. They remain available under `authored/**` as evidence of how specific behaviors were qualified.

## Public repository outputs and private evidence

Generated repository-safe content lives only beneath:

```text
public/
```

Typical public content includes:

- product/group catalogs and mapping;
- selection plan;
- canonical per-artifact JSON;
- aggregate inventories and compatibility views;
- generated Markdown reports;
- repository-safe run summary;
- publication manifest and validation.

Detailed execution evidence lives beneath:

```text
private/evidence/
```

Private evidence may contain host/runtime information, transcripts, local paths, download/extraction diagnostics and other operator context.

For release auditability, private Evidence also snapshots the exact runtime publication sources under:

```text
snapshot/inventory/**
snapshot/reports/**
```

This allows every manifest `SourceSha256` to be independently recomputed without making the runtime staging surface public.

## Publication byte contract

The repository publication contract is intentionally explicit:

- canonical JSON is generated compact and is not parsed/reserialized during publication;
- JSON and CSV are published byte-faithfully from their declared runtime sources;
- public Markdown is normalized by the toolkit to **UTF-8 without BOM + LF-only**;
- the publication manifest records source identity, published identity and generation/transformation mode;
- privacy, manifest coverage, file size/hash, dataset consistency and Markdown format are validated before promotion;
- only a fully validated staging tree may atomically replace `public/**`.

This contract prevents Git line-ending normalization from silently invalidating publication hashes.

## Evidence layers

The research model keeps evidence provenance explicit rather than collapsing unlike facts:

1. **Published** — AMD support-page metadata and download relationships.
2. **Embedded** — metadata bundled in the installer, including `InstallManifest.json`.
3. **Payload-observed** — files and INF content reached by static extraction.
4. **Analysis** — toolkit-derived topology, selector and WDF interpretations.
5. **Runtime** — target OS execution observations collected outside static research.

A downstream deployment/build tool should preserve the same distinction.

## Current qualified reference artifacts

Development qualification has included representative AMD packages such as:

- Adrenalin 26.5.2 Polaris/Vega;
- Adrenalin 26.7.1 Main;
- Adrenalin 23.11.1 RDNA Combined;
- PRO Edition 26.Q1 Windows 11 RDNA;
- PRO Edition 26.Q1 Windows 11 Vega/Polaris;
- PRO Edition 26.Q1 Windows Server 2022 Vega/Polaris.

These artifacts established several important controls, including multi-artifact release identity, `Display2` coverage, Server-native INF targeting and AMD-published Server package comparisons. See `RESEARCH-NOTES.md` and `reports/README.md`.

## Relationship to deployment and self-signed driver work

The toolkit deliberately stops before transformation or installation.

A future project-owned pipeline can consume this research as:

```text
AMD source artifact
  -> research / provenance qualification
     -> target hardware + Server candidate decision
        -> derived INF/package transformation
           -> catalog regeneration
              -> project signing
                 -> target Windows Server runtime validation
```

The source AMD EXE hash, selected INF topology, transformation delta, derived package hash, catalog/signing identity and runtime evidence should remain linked throughout that pipeline.

`RESEARCH-NOTES.md` contains the detailed engineering lessons intended for that future work.

## Known boundaries

The toolkit intentionally does not claim:

- that the curated catalog enumerates every AMD product model;
- that every historical AMD release/branch has been qualified;
- that `ServerProjection` proves binary compatibility;
- that a later Server build is supported merely because an INF build floor selects it;
- that WDF compatibility proves the driver can load;
- that AMD proprietary installer condition strings are equivalent to INF selection semantics;
- that static research replaces target-OS runtime validation.

These unknowns are preserved as explicit research boundaries rather than silently inferred.

## Release qualification

The authoritative release checklist is in `TESTING.md`.

A release candidate is not accepted merely because all research stages pass. Source analysis, Windows PowerShell 5.1 full-run behavior, publication privacy, byte-format contracts, manifest provenance, dataset consistency and private Evidence integrity are independent gates.

If generated output is incorrect, fix the toolkit and regenerate it. **Do not hand-edit generated release artifacts.**
