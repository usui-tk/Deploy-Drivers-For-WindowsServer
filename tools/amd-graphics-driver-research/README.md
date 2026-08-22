# AMD Graphics Driver Research Toolkit

## REV81 coordinated v3.0.0 documentation closeout

Claude closed Cycle B against REV80 with no open findings. The executable
remains `3.0.0`, byte-identical to the accepted REV77 source. The bounded
Windows Client Gate 2G and the exact REV77 Windows Server / Windows PowerShell
5.1 `PathSafety,Test` gate are accepted/no-repeat. The generated 69-file
`public/**` surface is the accepted v3.0.0 publication authority.

REV81 updates current-facing documentation only. It does not change the root
script, contracts, schemas, reviewed data, generated public output, canonical
path, or qualification evidence. No Windows rerun or multi-hour survey is
required. Historical revision sections remain evidence-bound records and are
not pending operator instructions unless a future changed contract explicitly
reactivates them.

## REV78 qualification status

The exact REV77 Graphics source now has accepted Windows Server 2025 / Windows
PowerShell 5.1 Evidence: 2/2 PASS, exit code `0`, exact 19/19 manifest, no
Warning/Error diagnostic event, and authoritative `run-context.json` Server
identity. This closes the earlier REV76 host-proof REVIEW. Graphics requires no
repeat because REV78 changes only an NPU-specific contract data file.

## REV77 execution-context evidence correction

The executable remains `3.0.0`. REV77 fixes the exact gap found in the REV76
Windows Server smoke: `run-context.json` now always records the actual host
`ExecutionContext` with Windows Client/Server classification, ProductType/role,
OS identity, evidence scopes, and typed collection status/source. The same
contract and self-test are present in Chipset and NPU. The accepted 69-file
Graphics `public/**` snapshot remains unchanged.

The REV76 Graphics run passed functionally but was held at REVIEW because its
self-contained Evidence could not independently prove the host was Windows
Server. The short REV77 command in `TESTING.md` subsequently closed that gap
and is accepted/no-repeat.

## REV76 previous status

The executable remains `3.0.0`. The exact REV75 bounded Windows Client Gate 2G
completed 10/10 stages with exit code `0`; its complete validated 69-file
`public/**` snapshot is incorporated byte-for-byte and the gate is
accepted/no-repeat. At REV76, the next platform action was the direct Windows
Server `PathSafety,Test` smoke in `TESTING.md`; the corrected exact REV77 source
subsequently passed that gate and is accepted/no-repeat. This did not authorize
the multi-hour all-track survey, installation, driver load or a GPU workload.
No release-included test launcher exists.

## REV75 bounded Cycle B Gate 2G

NPU Gate 2N is accepted. The next minimum-sufficient Graphics gate is one
Windows Client one-artifact E2E using the reviewed Ryzen AI 400 product group,
one major generation, one selected artifact and a 2 GiB ceiling. It includes
`PathSafety` and `Test`, exercises actual acquisition through publication and
must return one Evidence ZIP containing the complete validated
`snapshot/public/**`. It does not authorize the multi-hour all-track survey or
Windows Server.

## REV74 PowerShell 5.1 cardinality correction

The REV72 self-contained-public validator now protects its conditional
manifest-row result with `@(...)` before `.Count`. This is the same bounded
correction applied to NPU after the exact REV73 Windows PowerShell 5.1 Test
detected zero/one-item unrolling risk. Product/category selection, download,
extraction, certificate scope and generated-public semantics are unchanged.

## REV72 self-contained public Evidence correction

The executable version remains `3.0.0`. After a successful current-run
publication, the Evidence finalizer now copies the complete validated
`public/**` tree beneath `snapshot/public/**`. It verifies the live and
snapshotted path sets, every payload size and SHA-256 declared by
`publication-manifest.json`, and byte identity of the two trees before a normal
PASS Evidence ZIP can be created.

The Evidence ZIP is therefore the single review artifact for the generated
public surface. Operators do not create a separate public ZIP. Missing, extra
or changed snapshot files fail Evidence finalization closed and produce only
diagnostic emergency evidence. Product/category selection, acquisition,
extraction and certificate-analysis scope are unchanged.

## Current documentation and qualification status

- Executable version: `3.0.0`.
- Coordinated release state: Cycle B closed by Claude at `REV80`; `REV81`
  corrects documentation only before GitHub commit-candidate preparation.
- The prior `1.1.2-dev` source completed the accepted Windows Server smoke gate under
  Windows PowerShell `5.1.26100.33296`: `PathSafety,Test`, 2/2 stages PASS,
  final `Pass`, exit code `0`; that exact-source result is retained as a
  regression reference and does not qualify the changed `3.0.0` source.
- `3.0.0` explicitly requires Windows PowerShell 5.1 or later. The authorized
  REV75 bounded E2E includes the required `PathSafety,Test` checks and the
  self-contained-public finalization; no separate smoke is required.
- The previously accepted bounded Graphics short-E2E run remains separate
  evidence. The Windows Server smoke proves only environment/path safety,
  shared self-tests, Evidence finalization and summary behavior; it does not
  prove live product discovery, a full multi-hour survey, installation, kernel
  load or device operation.
- Ordinary research keeps bounded generation coverage, while certificate work
  is newest-generation-only per stable product-category/OS/package-family
  track. This is research coverage, not a host deployment recommendation.
- The qualification-only cross-tool launcher is excluded from the release.
  Any future included orchestrator requires a separately reviewed
  multi-scenario design.

Historical revision narratives belong in `CHANGELOG.md` and `authored/**`.
This README is the operator entry point; `SPEC.md` is normative, `TESTING.md`
defines gates, and `RESEARCH-NOTES.md` carries findings for downstream
build/sign/deployment work.

## Historical correction notes

## rev62 cumulative public-baseline correction

Graphics now verifies and, when required, migrates every imported historical
release JSON to the current Canonical JSON byte contract before cumulative
Build/publication. The runtime release tree replaces the staged release tree
as one authoritative set, so a same-key legacy public file cannot survive an
overlay. Publication failures now report privacy, Canonical JSON, dataset and
Markdown counts separately instead of describing every validation failure as
a privacy failure.

## rev60 public-null structure hardening

The recursive public converter now preserves explicit safe null properties and null array items instead of collapsing them with values rejected by privacy filtering. Nested private path fields remain removed. This is a preventive alignment prompted by the NPU Build failure and does not require repeating the accepted multi-hour Graphics survey.

## rev59 public-path audit hardening

Graphics publication now uses the same path-property classification and decoded-scalar privacy primitives as Chipset and NPU. Nested archive-path evidence is removed from the repository-public object graph before serialization, and the existing fail-closed audit remains the final guard.

## rev58 path-safety correction

Graphics retains its short `work\\x\\aNNNN\\cNNNN` extraction layout, now generated by the same common function used by Chipset and NPU. Extract and Signature fail closed if any selected extraction record is not `ExtractionComplete`; a partial tree cannot feed a vacuous downstream PASS.



## rev52 interruption and Evidence portability hardening

Graphics now uses the same fail-closed stage lifecycle as Chipset: a stage is
`RUNNING` until its body returns, and Ctrl+C/pipeline stop becomes
`INTERRUPTED` with exit code `130`. Private Evidence manifest paths use `/` on
all hosts. This change does not alter product selection, acquisition,
certificate scope, or the accepted 12-hour research result.

## rev51 common runtime/evidence hardening

Graphics now shares the accelerated embedded .NET Canonical JSON runtime,
immediate bootstrap output, per-check elapsed progress, Test-only baseline skip,
and verified emergency evidence ZIP fallback. Existing public data is not
rewritten. Emergency archives retain raw evidence and are diagnostic/non-PASS
artifacts.

## Canonical JSON contract (rev50)

Graphics now shares the Chipset/NPU Canonical JSON writer, parser, file writer,
file validator and SHA-256 self-test. The old compact-whitespace publication
rule is replaced for newly generated output by byte equality with the common
UTF-8-no-BOM/LF/two-space/insertion-order format. Existing accepted public
evidence is not reformatted in place; the next authorized publication replaces
it atomically using the new contract.

**Current source version: 3.0.0 coordinated Cycle B closed release candidate**

`Invoke-AmdGraphicsDriverResearch.ps1` is a PowerShell research tool for reconstructing AMD Windows graphics-driver publication identities, selecting a bounded set of representative installer artifacts, extracting those artifacts statically, parsing their INF/WDF metadata, and producing evidence-oriented Windows Server applicability data.

The toolkit is deliberately **research-only**. It does not execute AMD Setup, install drivers, patch INF files, generate catalogs, sign packages, or claim runtime compatibility. Its job is to make the vendor package structure and Windows selection semantics explicit enough that later deployment or self-signed-driver work can be designed from evidence rather than guesswork.

## Enhancement implementation status

Graphics `3.0.0` retains the approved G0–G4 certificate scope and the
Windows path-safety correction derived from the first Windows Client run. The existing
newest-three-major-generation research corpus remains unchanged, while deep
certificate analysis selects only the newest major generation independently
inside each stable product-group + OS + package-family track.

`Select` owns the deterministic target plan, `Acquire` resolves URL targets
against immutable outer-installer SHA-256 values, and `Signature` consumes
that resolved plan without ranking releases again. Multiple categories may
therefore reference one analyzed installer while every category and track
reference remains present as provenance.

The candidate also ports the reviewed device-neutral Chipset/NPU signature,
transport, diagnostic and PowerShell 5.1 cardinality primitives. The first
Windows Client run completed the 12-hour static analysis but exposed SignTool
`MAX_PATH` failures on existing 260–357 character extracted paths.
`3.0.0` blocks unsafe roots before AMD network access, uses short
acquisition/extraction paths, preflights 7-Zip entries, and verifies native
files through byte-identical `work\n\fNNNNNN.ext` aliases. It also adds the
`SignatureNative` stage so reviewed static analysis can be hash/set validated
and reused. The Windows Client correction, bounded short-E2E, and later Windows
Server smoke were reviewed as separate gates. None of them proves driver
installation, kernel load or device functionality. See
[`authored/GRAPHICS-SIGNATURE-AND-COMMON-HARDENING-PLAN-2026-08-17.md`](./authored/GRAPHICS-SIGNATURE-AND-COMMON-HARDENING-PLAN-2026-08-17.md).

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
PathSafety
  -> Test
  -> ProductDiscover
  -> ProductMetadata
  -> Select
  -> Acquire
  -> Extract
  -> Inspect
  -> Signature
  -> Build
```

`PathSafety` is always inserted first and has no bypass, including with
`-Force`. On Windows it enforces a 100-character tool-root limit, a conservative
240-character full-path limit, a 120-character AMD relative-path reserve,
tool-folder-only storage, non-UNC/non-reparse qualification roots, and real
filesystem, 7-Zip and (when required) SignTool probes. `LongPathsEnabled` is
diagnostic only.

For the purpose-specific correction run, keep the existing `inventory`,
`private` and `work` folders and run `PathSafety,Test,SignatureNative`; do not
repeat discovery, download, extraction, inspection or static CMS analysis.

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
8. Runtime data remains below the graphics tool folder; `%TEMP%`, external
   evidence roots, `subst`, junctions, 8.3-name workarounds and UNC
   qualification roots are not accepted path-safety substitutes.

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

The certificate plan does not change that corpus. It records only the newest
selected major generation per stable track, then de-duplicates execution first
by normalized AMD EXE URL and finally by acquired installer SHA-256. Older
selected generations are explicitly `ExcludedByPolicy` only from deep
certificate analysis.

## Certificate and signature analysis

The `Signature` stage performs static, non-mutating analysis of content-addressed
PE, CAT, CMS and certificate candidates. Static evidence includes PE
`WIN_CERTIFICATE`, CMS/PKCS#7 envelopes, nested signatures, timestamp tokens,
X.509 identities and Authenticode signed-content digest comparison.

On Windows, private evidence additionally records
`Get-AuthenticodeSignature`, Windows catalog enumeration/hash evidence,
locale-neutral SignTool profiles, SDK/WDK tool identity and catalog-bound
kernel checks. Installation, certificate-store mutation, kernel load and
device function remain `NotObserved`.

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

These artifacts established several important controls, including
multi-artifact release identity, `Display2` coverage, Server-native INF
targeting and AMD-published Server package comparisons. See
`RESEARCH-NOTES.md` and `authored/README.md`.

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

### Windows Client qualification boundary (1.1.1-dev)

`-RequireWindowsClientSignatureQualification` is intentionally narrower than an
ordinary research run. It accepts only the unfiltered product-driven corpus with
`-MajorGenerationCount 3`, then verifies certificates only for the newest selected
generation in every stable product-category/OS/package-family track. Seed-only
discovery, non-AMD download hosts, public export, embedded installers and local or
historical overrides are rejected. The persisted certificate plan is revalidated
again by the Signature stage, preventing a narrowed corpus from being reported as
a complete Windows Client qualification.

### Windows path-correction boundary (1.1.2-dev)

The first Client run is retained as diagnostic failure evidence. Its static
results are eligible for `SignatureNative` only after exact plan, installer and
file SHA-256 set validation. Native checks use `work\n` aliases and do not alter
the source extraction. This limited correction run cannot perform discovery,
download, extraction, inspection or public publication unless those stages are
separately selected; the authorized correction command selects none of them.
## Evidence output location (rev48 common contract)

By default, final evidence is stored only under `<tool-root>\private\evidence`. The file identified by `EVIDENCE ZIP TO SHARE` is the review artifact; its adjacent `.zip.sha256` file verifies integrity, and `LATEST-EVIDENCE.txt` points to the most recent successfully verified archive.

Raw collection uses a short path under `private\evidence\runs\r<UTC>-<8hex>`. The default `-EvidenceRetention ZipOnly` removes that directory only after ZIP integrity verification and SHA-256 generation. Use `-EvidenceRetention ZipAndDirectory` only when raw diagnostics must remain. `-EvidenceOutputRoot` is retained for compatibility but accepts only the canonical root or a descendant; external, UNC, SUBST-backed, and reparse-point paths are blocked before research starts.
## rev57 cross-tool common-core convergence

The previously accepted Graphics path-safety implementation is now parameterized as the shared Chipset/Graphics/NPU kernel. Graphics retains its `AMD-Gfx` relocation guidance and product/category-specific selection behavior.

`data/current-three-tool-common-core-contract.json` is the current parity authority. Test verifies the shared function hashes and ordinal ordering. Publication-manifest file enumeration now uses `System.StringComparer.Ordinal`; bootstrap-fatal failures use the shared emergency evidence session without weakening the unsafe-root no-write boundary.

Graphics has two intentionally distinct INF-topology schema families. The
per-artifact documents use `schemas/inf-topology.schema.json` and
`amd-inf-topology/1.1`; the aggregate reference collection uses
`schemas/inf-topology-collection.schema.json` and
`inf-topology-collection/2.0`. External validators must pair by the document's
`SchemaVersion`/schema `$id`, not by basename similarity.
