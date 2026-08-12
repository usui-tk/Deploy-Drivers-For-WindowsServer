# AMD Chipset Driver Research Toolkit

**Current toolkit version: 2.0.0**

`Invoke-AmdChipsetDriverResearch.ps1` is a PowerShell research toolkit for reconstructing AMD Ryzen Chipset Software release history, acquiring original AMD artifacts without executing them, statically extracting nested installer content, parsing INF/WDF semantics, reverse-engineering AMD component-selection behavior, and publishing a repository-safe evidence dataset for Windows Server research.

The toolkit is deliberately **research-only**. It does not install AMD chipset drivers, patch INF files, rebuild catalogs, install certificates, sign packages, or claim runtime compatibility. Its job is to expose enough vendor, INF/PnP, WDF, selector, MSI, and provenance evidence that downstream deployment or self-signed-driver work can be designed from measured facts instead of installer behavior guesses.

## What the toolkit answers

The normal research workflow is intended to answer questions such as:

- Which AMD Chipset Software releases are known and which vendor artifacts represent them?
- What SHA-256 identity belongs to each downloaded AMD artifact and recovered nested installer layer?
- Which INF packages are present after bounded static extraction?
- What `[Manufacturer] -> TargetOSVersion -> Models -> identifier -> DDInstall` relationships are declared by each INF?
- Which Windows Server 2016 / 2019 / 2022 / 2025 profiles are selected **as published** by Microsoft INF semantics?
- Which additional candidates appear under the toolkit's non-mutating Workstation `ProductType=1` to Server `ProductType=3` analytical projection?
- Which KMDF/UMDF versions are explicitly declared, and what conservative WDF decision follows for each target Server profile?
- What does AMD's own chipset selector expose through `Info.xml`, `DevID.xml`, MSI tables, binary strings, and exact-binary compiled predicates?
- Why can AMD Setup select no component on Windows Server even when an INF remains a static Server candidate?
- What is known, inferred, dynamically observed, or still unresolved for each selector rule?
- Can another reviewer reproduce the published summary from Raw JSON without trusting the Markdown report?

The toolkit does **not** answer whether a projected or statically applicable package will actually load and operate correctly after INF transformation and self-signing on Windows Server. Runtime acceptance remains a separate deployment/qualification activity.

## Quick start

### Built-in self-tests

```powershell
.\Invoke-AmdChipsetDriverResearch.ps1 -Stages Test
```

### Normal full research run

```powershell
.\Invoke-AmdChipsetDriverResearch.ps1 -Stages All
```

No `-Stages` argument also selects the normal full workflow.

On Windows, the normal stage sequence is:

```text
Test
  -> Discover
  -> Metadata
  -> Acquire
  -> Extract
  -> Inspect
  -> Selector
  -> HostSurvey
  -> HostMatch
  -> Build
```

### Static-only research

To avoid host-specific survey/matching while retaining static artifact analysis:

```powershell
.\Invoke-AmdChipsetDriverResearch.ps1 -SkipHostAnalysis
```

### Specific release research

```powershell
.\Invoke-AmdChipsetDriverResearch.ps1 `
  -ReleaseVersion 8.07.16.1035
```

Multiple release versions may be pinned explicitly for a controlled qualification run. Pinning is recommended for release audits so a new AMD release cannot silently change the dataset under review.

### Replay previously captured AMD installer observations

AMD installer logs may be compared with static emulation without executing AMD software from this toolkit:

```powershell
.\Invoke-AmdChipsetDriverResearch.ps1 `
  -Stages Selector,HostSurvey,HostMatch `
  -ObservedAmdDeviceIdLog 'C:\AMD\Chipset_Software\Logs\Device_ID.log' `
  -ObservedAmdMsiLog 'C:\AMD\Chipset_Software\Logs\AMD_Chipset_Software_Install.log'
```

Use `-ObservedAmdReleaseVersion` when the observed log does not carry an unambiguous release identity.

## Safety model

The toolkit follows these invariants:

1. Downloaded AMD EXEs/ZIPs are treated as input artifacts and are **not executed**.
2. Extraction is static and bounded.
3. Recovered MSI packages are not installed. On Windows, Windows Installer COM may open recovered MSI databases read-only for declarative-table inspection.
4. INF packages are not installed or staged into DriverStore.
5. `pnputil`, INF mutation, catalog regeneration, certificate installation, and package signing are outside this toolkit.
6. Host analysis is read-only and may query CIM/PnP state; host evidence stays private by default.
7. The original AMD artifact hash remains immutable vendor provenance.
8. A publication/privacy/schema failure is fail-closed and cannot replace the previous validated `public/**` baseline.
9. Generated repository artifacts are never repaired by hand. Fix the generator and rerun.

## Runtime support

The script is designed for:

- Windows PowerShell 5.1 on Windows;
- PowerShell 7 on Windows;
- PowerShell 7 on Linux for supported static/offline research paths.

The distributed `.ps1` intentionally uses UTF-8 with BOM and CRLF line endings for Windows PowerShell compatibility.

Generated **public Markdown** follows the repository publication contract: UTF-8 without BOM and LF-only line endings.

## Research model

Chipset research separates several decision planes that must not be collapsed into one another:

```text
AMD published metadata
        |
        v
embedded installer metadata / AMD selector rules
        |
        +-----------------------------+
        |                             |
        v                             v
Microsoft INF/PnP semantics      AMD installer selection
        |                             |
        v                             v
AsPublished / ServerProjection   candidate/filter/final list
        |                             |
        +-------------+---------------+
                      v
             research comparison
                      |
                      v
        downstream project policy
        (outside this toolkit)
```

A zero-component AMD selector result on Windows Server is **not** equivalent to “the contained INF cannot apply on Windows Server.” Likewise, an INF static candidate is **not** proof that the binary will load or function correctly.

Detailed design rationale and real-artifact observations are consolidated in [`RESEARCH-NOTES.md`](./RESEARCH-NOTES.md).

## Release and artifact identity

Release identity is the four-part AMD Chipset Software version. The concrete downloaded artifact and every recovered nested layer retain their own hashes.

The outer AMD artifact is immutable source provenance. User-created transfer ZIPs or split archives are transport envelopes only and do not replace the vendor artifact identity.

The public v2.0.0 dataset covers 25 releases from `2.04.04.111` through `8.07.16.1035` and preserves per-release Raw JSON as the primary independently reviewable unit.

## Static extraction model

Observed chipset installers require more than one container strategy. The canonical research model includes:

```text
AMD artifact
   |
   +-- modern EXE / historical ZIP
   |       |
   |       `-- AMD outer EXE
   |              |
   |              +-- Qt selector/XML assets
   |              |
   |              `-- AMD_Chipset_Drivers.exe
   |                     |
   |                     `-- InstallShield ISSetupStream
   |                            |
   |                            `-- AMD_Chipset_Drivers.msi
   |                                   |
   |                                   `-- Data1.cab
   |                                          |
   |                                          `-- INF / SYS / CAT / XML
```

7-Zip handles supported archive/container layers. The single PowerShell script includes a static `ISSetupStream` decoder informed by the ISx project; see `THIRD-PARTY-NOTICES.md`.

`ExtractionComplete` requires driver-analysis content such as INF files. Merely opening an outer archive is not a successful deep extraction.

## INF and Windows Server analysis model

The canonical INF topology preserves:

```text
[Manufacturer]
  -> TargetOSVersion decoration
     -> referenced Models section
        -> model description
        -> DDInstall section
        -> hardware / compatible identifiers
```

The parser does not reduce this topology to a fixed PCI-only identifier list.

Static Windows Server analysis separates:

- **AsPublished / Native** — what the original INF selects without modification;
- **ServerProjection** — a non-mutating simulation of client `ProductType=1` targeting projected to Server `ProductType=3`;
- **RuntimeCompatibility** — `NotEstablished` until target-OS installation/load/functional testing exists.

The current published dataset provides Raw JSON and aggregate views for Windows Server 2016, 2019, 2022, and 2025.

## AMD selector analysis model

AMD's setup selector is treated as an independent evidence plane. The toolkit may retain:

- `Info.xml` / APS XML product records;
- `DevID.xml` device/property mappings where present;
- printable selector-binary strings;
- exact selector-binary SHA-256;
- read-only MSI declarative tables;
- exact-binary compiled predicates where reverse engineering established them;
- observed AMD logs from external qualification runs.

Evidence levels are explicit. `AmdCompiledStaticProven` is always scoped to an exact selector binary hash. Rules are not generalized across releases merely because two installers use the same Qt generation.

The major-version findings and downstream engineering implications are summarized in `RESEARCH-NOTES.md`; the detailed historical reverse-engineering report is retained under `reports/design-history/`.

## WDF analysis

KMDF/UMDF declarations are retained with the INF/package that declared them and compared conservatively with target Server profiles.

Important rules:

- no WDF version is invented when an INF does not declare one;
- package-level/INF-level WDF decisions are preferred over “installer version implies WDF version” shortcuts;
- where DDInstall/component dependency scope cannot be proven, the toolkit retains conservative INF-wide WDF evidence;
- WDF compatibility is necessary evidence for some packages but is not sufficient proof of loadability or functional correctness.

The current 25-release/643-package dataset observed a maximum declared KMDF version of 1.19. That measurement replaced an earlier repository assumption that modern chipset packages necessarily require a KMDF newer than the Windows Server 2016 documented runtime.

## Repository layout

The top-level documentation surface intentionally matches the AMD Graphics Driver Research Toolkit:

```text
amd-chipset-driver-research/
  Invoke-AmdChipsetDriverResearch.ps1
  README.md
  SPEC.md
  TESTING.md
  RESEARCH-NOTES.md
  CHANGELOG.md
  PUBLICATION-POLICY.md
  THIRD-PARTY-NOTICES.md
  data/                     # versioned curated/static inputs
  schemas/                  # generated-artifact schemas
  public/                   # repository-safe generated outputs
  inventory/                # runtime staging; not a generated commit surface
  private/                  # private/debug evidence
  work/                     # extraction/download workspace
  reports/                  # generated reports + historical research/qualification records
```

### Documentation map

| Document | Purpose |
|---|---|
| `README.md` | Stable entry point, workflow, concepts and repository layout |
| `SPEC.md` | Normative behavioral, data, selector, publication and evidence contracts |
| `TESTING.md` | Test matrix and release-acceptance procedure |
| `RESEARCH-NOTES.md` | Consolidated reverse-engineering knowledge and downstream engineering feedback |
| `CHANGELOG.md` | Version-by-version implementation history |
| `PUBLICATION-POLICY.md` | Generated public/private boundary and publication transaction |
| `THIRD-PARTY-NOTICES.md` | Third-party attribution |
| `reports/README.md` | Index of historical qualification/design reports |

One-off reverse-engineering and qualification narratives are intentionally kept out of the tool top directory. They remain under `reports/**` as evidence of how a behavior was discovered or qualified.

## Public repository outputs and private evidence

Generated repository-safe content lives only beneath:

```text
public/
```

Typical public content includes:

- canonical per-release Raw JSON;
- release/acquisition/extraction/selector indexes;
- aggregate INF/Windows Server inventory views;
- generated Markdown reports;
- repository-safe run summary;
- publication manifest and validation.

Detailed execution evidence lives beneath:

```text
private/evidence/
```

Private evidence may include host/runtime information, transcripts, local paths, installer binaries when explicitly requested, and extraction/download diagnostics.

For release auditability, private Evidence snapshots the exact runtime sources referenced by public manifest `SourceRelativePath` / `SourceSha256` fields.

See `PUBLICATION-POLICY.md` for the normative generated-output trust boundary.

## Publication byte contract

The repository publication contract is explicit:

- canonical per-release JSON is generated compact and is not publication-time parsed/reserialized;
- canonical per-release Raw JSON remains the primary evidence representation even when PowerShell 5.1 serializes collection wrappers;
- tool-generated aggregates canonicalize recognized PowerShell 5.1 collection wrappers to plain arrays and fail publication if such wrappers survive;
- JSON/CSV publication is byte-faithful to declared runtime sources unless a schema-declared deterministic aggregate projection applies;
- public Markdown is normalized by the toolkit to UTF-8 without BOM + LF-only;
- publication manifest records source identity, published identity, generation mode, transformation policy, size, and SHA-256;
- privacy, schema/shape, token fidelity, manifest coverage, and dataset consistency are validated before atomic promotion;
- accepted generated files must record `HandEdited=false`.

Git repository attributes must preserve the generated `public/**` bytes verbatim so Git line-ending conversion cannot invalidate the manifest hashes.

## Evidence layers

The research model keeps provenance explicit:

1. **Published** — AMD support-page/download facts.
2. **Embedded** — metadata bundled in the installer.
3. **PayloadObserved** — files/INF/XML reached by static extraction.
4. **Analysis** — toolkit-derived INF selector, AMD selector, WDF, and comparison results.
5. **Runtime** — host/install observations collected by qualification activities.

Derived analysis must not overwrite the source evidence that produced it.

## Current qualified baseline

The current v2.0.0 public baseline contains:

- 25 AMD Chipset Software releases;
- 643 INF package records;
- 25 canonical per-release Raw JSON analyses;
- 25/25 recovered MSI databases parsed read-only during the Windows qualification run;
- 13,993 selected MSI declarative rows with zero all-null rows;
- four Windows Server applicability profiles per eligible package/selector row;
- exact selector-token fidelity checks and publication provenance.

These are static/research measurements, not AMD support claims and not runtime deployment acceptance.

## Relationship to deployment and self-signed driver work

The toolkit deliberately stops before transformation or installation.

A future or existing project-owned pipeline can consume the research as:

```text
AMD source artifact
  -> immutable source identity
     -> package / INF topology
        -> target hardware + Server candidate decision
           -> AMD selector evidence (independent audit signal)
              -> per-package WDF decision
                 -> explicit project deployment plan
                    -> derived INF/package transformation
                       -> catalog regeneration
                          -> project signing
                             -> target Windows Server runtime qualification
```

The source AMD artifact, selected INF/package set, transformation delta, derived hashes, signing identity, and target-host runtime evidence should remain linked throughout that pipeline.

`RESEARCH-NOTES.md` records the detailed engineering lessons intended for downstream chipset self-signed build/deployment work.

## Known boundaries

The toolkit intentionally does not claim:

- that every historical AMD chipset release is recoverable forever;
- that AMD's installer selector and Microsoft INF/PnP use equivalent rules;
- that a Server projection is vendor support;
- that a static candidate will load or operate correctly;
- that WDF compatibility proves driver loadability;
- that an AMD selector empty result proves the driver payload is incompatible;
- that same-generation Qt selectors share every compiled predicate;
- that unresolved old-major hardware predicates may be copied from newer releases;
- that static research replaces physical target-OS qualification.

Unknowns remain explicit instead of being silently promoted to compatibility claims.

## Release qualification

The authoritative release checklist is `TESTING.md`.

A release candidate is not accepted merely because all research stages pass. Source static analysis, Windows PowerShell 5.1 full-run behavior, canonical Raw JSON conservation, MSI evidence quality, publication privacy/schema/byte-format contracts, manifest/source provenance, Git byte identity, and private Evidence integrity are independent gates.

If generated output is incorrect, fix the toolkit and regenerate it. **Do not hand-edit generated release artifacts.**
