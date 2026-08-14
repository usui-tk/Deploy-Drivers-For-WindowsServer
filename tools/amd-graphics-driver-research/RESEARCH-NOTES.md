# AMD Graphics Driver Research Notes

This document consolidates the durable reverse-engineering and engineering knowledge produced during development of the AMD Graphics Driver Research Toolkit. It replaces the need to read multiple top-level qualification/design notes to understand the project.

Historical qualification records remain under `authored/**` and provide the detailed evidence trail for individual development milestones. This file focuses on knowledge that should remain useful for future driver deployment, INF transformation and project-owned self-signed package work.

## 1. Research boundary

The toolkit is an evidence generator and static analyzer. It intentionally stops before deployment or package transformation.

The useful engineering bridge is:

```text
vendor publication
  -> immutable AMD installer artifact
     -> static package/INF research
        -> Windows Server candidate analysis
           -> future project-owned transformation/signing
              -> target Server runtime validation
```

Static research can identify a promising candidate or a clear selector mismatch. It cannot prove that the binary will load, initialize hardware correctly, survive servicing, or remain supported by AMD.

## 2. Start from the product group, not from a global release number

AMD publishes graphics drivers through product support hierarchies.

Discrete Radeon products generally appear under `Graphics`. Integrated Radeon graphics for Ryzen/APU products can appear under `Processors`. Professional Radeon products can publish multiple client/server tracks from one product page.

The practical research chain is:

```text
AMD ProductGroup
  -> representative official product page(s)
     -> OS/package-family track
        -> major release generation
           -> concrete AMD installer EXE
```

The normal research policy therefore selects the newest release from the newest three **available major generations** for each stable product-group / OS / package-family lineage.

This is intentionally bounded research, not an attempt to download every AMD graphics release.

### Deployment implication

A future deployment/build script should resolve the target GPU/APU product group and intended track before choosing an installer. Numerically newest global release text is not enough.

## 3. Product catalog scope is explicit and bounded

The current curated catalog is built from representative AMD support pages for explicit product groups.

It does not claim to enumerate every AMD product model.

Important scope lessons:

- graphics driver publication can originate from `Graphics` or `Processors` pages;
- a representative product page establishes the research entry point for a product group, not universal model coverage;
- one product group may publish multiple OS/package-family tracks;
- if required current/previous metadata cannot be resolved, metadata completeness should remain partial and acquisition should fail closed rather than silently building an incomplete historical baseline.

## 4. The AMD EXE is the canonical vendor artifact

Large AMD installers may be split into ZIP parts for transport into an analysis environment. Those user-created archives are not vendor artifacts.

Canonical vendor identity is based on the original AMD installer EXE:

```text
FileName
FileSize
SHA-256
ReleaseKey
ArtifactKey
published URL/provenance when available
```

Qualified modern Adrenalin/PRO installers are directly recognizable as 7z self-extracting archives. Multiple samples exposed an archive boundary at the same observed offset (`1,785,344` bytes), but that repetition is an observation rather than a format invariant that should be hard-coded as the only valid layout.

### Deployment/signing implication

Always retain the original AMD EXE hash. A later extracted, modified, catalog-rebuilt or project-signed package is a derived project artifact and requires its own provenance identity.

## 5. Stop extraction when the graphics driver surface is available

Modern packages expose driver payload under `Packages/Drivers/**`, including display, audio and other components.

Once the INF-bearing driver surface has been reached, recursively opening ordinary application MSI/helper executables creates noise and false extraction failures without improving INF analysis.

Recommended extraction boundary:

```text
outer AMD EXE
  -> bounded static extraction
     -> Packages/Drivers INF surface reached
        -> analyze driver payload
        -> do not recursively unpack unrelated application helpers
```

Legacy or unknown wrappers may still require deeper bounded static recursion when no driver surface has been reached.

## 6. `Config/InstallManifest.json` is valuable embedded evidence

Modern qualified installers contain `Config/InstallManifest.json`.

Useful observed information includes:

- external/release version and build identity;
- package descriptions and versions;
- package types such as DRIVER, MSI, SPECIAL and EXEC_CMD;
- payload paths;
- feature flags;
- AMD proprietary conditions such as `OSCheck`.

Manifest payload paths should be resolved using Windows-style case-insensitive semantics. Qualified packages have contained manifest/payload casing differences.

### Boundary

`InstallManifest.json` is **Embedded evidence**. Its AMD-specific condition strings are preserved, but they are not silently interpreted as equivalent to Microsoft INF TargetOSVersion rules.

### Deployment implication

Use the manifest to identify package components. Use INF topology and target hardware for PnP targeting decisions.

## 7. Release identity and artifact identity must remain separate

The canonical identity is:

```text
ReleaseKey  = PackageFamily | Branch | ReleaseVersion
ArtifactKey = ReleaseKey | FileName
```

A single public release version can publish multiple different installer EXEs.

PRO Edition 26.Q1 is a qualified example of a multi-artifact release: client RDNA, client Vega/Polaris and Windows Server Vega/Polaris sibling artifacts share a release family while remaining distinct concrete artifacts.

### Deployment implication

Cache, transform, sign and report by ArtifactKey/source EXE SHA-256. Never use release version alone as a unique package key.

## 8. Preserve the full INF topology

A flattened HWID list is not enough to reproduce Windows selection.

Canonical topology preserves:

```text
[Manufacturer]
  -> TargetOSVersion decoration
     -> exact referenced Models section
        -> model description
        -> DDInstall section
        -> identifier / compatible identifiers
```

Important lessons:

- Models sections must be reached from `[Manufacturer]`; scanning every `*.NT*` section can confuse DDInstall `.Services`, `.HW`, `.Wdf` and similar sections with Models sections.
- Empty Models sections are meaningful. They can express explicit selector exclusions/fallback behavior.
- Graphics packages contain more than PCI identifiers. Qualified content includes component/software identifiers such as `ACP\...`, `SOUNDWIRE\...`, `VIDEO\...` and GUID-based render/capture identifiers.
- Unknown identifiers should be preserved, not discarded or fabricated into PCI forms.

### Future INF transformation implication

A patcher must preserve the relationship between each identifier and the exact Models/DDInstall path. Editing a flat HWID list without topology can create a syntactically valid but semantically incorrect INF.

## 9. TargetOSVersion must be understood before changing ProductType

The toolkit treats TargetOSVersion dimensions independently:

```text
Architecture
OSMajorVersion
OSMinorVersion
ProductType
SuiteMask
BuildNumber
```

Relevant ProductType values are:

```text
1 = Workstation/client
2 = Domain Controller
3 = Server/member server
```

BuildNumber is evaluated as a minimum build in static selector simulation.

This leads to a critical distinction:

- a client INF may be blocked on Server solely because ProductType=1;
- a Server-targeted selector with a minimum build can also statically select a later Server build;
- neither result proves binary/runtime compatibility.

## 10. Keep AsPublished, ServerProjection and RuntimeCompatibility separate

The project uses three different meanings:

### AsPublished

What the AMD INF selects without modification.

### ServerProjection

A non-mutating simulation that evaluates client `ProductType=1` selectors as if projected to Server `ProductType=3`.

### RuntimeCompatibility

Actual driver load/functionality on a target Server OS. Static analysis leaves this as `NotEstablished` unless separate runtime evidence exists.

### Deployment implication

ProductType projection is useful for generating a candidate set for later engineering work. It is not sufficient justification to install or sign a package.

## 11. AMD's native Windows Server package is the strongest static control

The qualified PRO Edition 26.Q1 Windows Server 2022 Vega/Polaris artifact is especially valuable because AMD itself publishes Server-targeted INF sections.

Its primary display INF contains populated Server/DC selectors with a Windows Server 2022 build floor and native Server identifier coverage.

Static selector analysis can therefore compare:

```text
AMD client package
  -> client selectors / project-side ServerProjection

AMD native Server package
  -> AMD-published Server selectors
```

This is much stronger evidence than inferring expected Server structure from a client package alone.

### Important limit

If a later Server build satisfies the INF minimum build, that only establishes a static selector candidate. It does not prove AMD support for the later OS.

## 12. Same DriverVer does not mean same package or binary

Sibling artifacts can share release text or DriverVer while containing different INF sets, payload roles or binary coverage.

The 23.11.1 RDNA Combined qualification showed that a combined package could contain a common INF set plus additional `Display2` payload.

Therefore comparisons should use:

- source EXE SHA-256;
- ArtifactKey;
- INF relative path + INF SHA-256;
- referenced binary hashes when required;
- identifier/topology differences.

## 13. `Display2` is part of the graphics analysis surface

Early analysis that only considered one display directory could miss valid graphics payload.

Qualified packages established that `Display2/WT6A_INF` can contain additional display INFs and must be included in the graphics analysis surface where present.

This is one reason recursive file discovery should be topology-aware rather than hard-coded to a single display path.

## 14. HWID coverage can intentionally differ between client and Server artifacts

AMD's native Server control package demonstrates that Server packages may intentionally expose narrower identifier/model coverage than client packages.

Therefore a future self-signed Server package should not assume that "all client HWIDs should simply be enabled on Server".

A stronger design is:

1. identify the exact target GPU/APU hardware;
2. compare client and any AMD native Server sibling coverage;
3. understand which Models/DDInstall path is used;
4. project only the needed candidate topology;
5. validate the resulting derived package on the target Server version.

## 15. WDF evidence is necessary but conservative

The toolkit records KMDF/UMDF declarations and compares them with target Server profiles.

Where an INF does not establish a narrow component dependency, the analysis uses an INF-wide conservative scope.

WDF compatibility can disqualify a candidate, but a WDF pass cannot establish driver loadability by itself.

## 16. Preserve evidence layers instead of collapsing them

The project separates:

```text
Published
Embedded
PayloadObserved
Analysis
Runtime
```

Examples:

- AMD support page release/date/download relation -> Published
- `InstallManifest.json` -> Embedded
- INF file and binary hashes -> PayloadObserved
- parsed TargetOSVersion topology / ServerProjection -> Analysis
- actual Windows Server load/operation -> Runtime

### Future deployment implication

A deployment or signing workflow should keep those layers separate so a later reviewer can tell what AMD actually published, what the package contains, what the project inferred, what the project changed, and what Windows actually accepted.

## 17. Recommended future decision sequence

For a future Windows Server build/deployment pipeline:

```text
1. Identify target hardware and Windows Server version
2. Resolve AMD ProductGroup and intended driver track
3. Select exact qualified AMD installer ArtifactKey / SHA-256
4. Identify exact matching INF Models/DDInstall topology
5. Evaluate AsPublished targeting
6. Compare AMD native Server controls when available
7. Evaluate non-mutating ServerProjection
8. Evaluate WDF constraints
9. Decide whether a derived package is justified
10. Apply minimal, explicit INF/package transformation
11. Generate a new catalog for the derived package
12. Sign using project-owned certificate policy
13. Install/test on the target Server OS
14. Preserve runtime evidence and bind it to the derived package hash
```

A failure at an early evidence gate should stop the pipeline rather than being hidden by later signing/install automation.

## 18. Signing/repackaging provenance requirements

If the project later creates a self-signed derived package, provenance should include at minimum:

- original AMD EXE file name, size and SHA-256;
- source ReleaseKey / ArtifactKey;
- source INF relative path and SHA-256;
- exact target hardware identifiers;
- exact Server profile;
- transformation description or machine-readable patch;
- derived INF/package SHA-256;
- catalog generation tool/version;
- generated CAT SHA-256;
- signing certificate thumbprint/subject and signing-tool version;
- signed file/package hashes;
- target Server runtime evidence.

The project should never relabel a derived package as if it were byte-identical to the AMD original.

## 19. Static selection is not runtime acceptance

Several independent failure modes remain after a static selector says `NATIVE_CANDIDATE` or `PROJECTION_CANDIDATE`, including:

- missing/unsupported kernel APIs;
- driver signing/catalog problems;
- KMDF/UMDF mismatch not fully expressible by the selected INF evidence;
- companion services/components not represented by the display INF alone;
- firmware/hardware initialization assumptions;
- AMD installer/runtime policy beyond INF selection;
- target Server security-policy differences.

Therefore runtime testing is a mandatory downstream activity for actual deployment decisions.

## 20. Product-driven scaling lessons

The development full runs established several operational lessons:

- full global historical acquisition is unnecessarily large for routine research;
- selection should be bounded before download;
- deduplicate identical AMD EXE URLs globally;
- retain per-product provenance despite deduplication;
- use sharded per-artifact detail rather than one giant in-memory object;
- rebuild aggregate views from canonical retained records;
- keep runtime extraction/log data out of canonical public-bound objects;
- preserve fail-closed behavior when live metadata is partial.

These lessons are part of the toolkit's architecture, not merely performance optimizations.

## 21. Publication and reproducibility lessons

Release hardening exposed additional cross-platform/repository lessons:

### Compact canonical JSON

Deep PowerShell pretty-printed JSON can grow dramatically without adding information. Canonical JSON is therefore generated compact at Build time rather than being edited during publication.

### PowerShell 5.1 collection wrappers

Windows PowerShell 5.1 can serialize some collections as wrapper objects such as:

```json
{"value":[...],"Count":31}
```

The toolkit rehydrates this representation when reading generated JSON. The Raw JSON itself remains evidence and is not rewritten merely to hide the wrapper.

### Privacy scanning decoded values

A privacy scan that only searches raw JSON text can miss an absolute Windows path expressed with JSON escaping. Validation must inspect decoded scalar values.

### Multiline extraction logs

A local path may occur in the middle of a 7-Zip multiline log rather than at the start of a string. Run-specific extraction logs are therefore private Evidence, and canonical sanitization checks all relevant decoded scalars.

### Public Markdown line endings

Repository `.gitattributes` can rewrite CRLF Markdown and invalidate publication hashes. Public Markdown is therefore normalized by the generator to UTF-8 no-BOM/LF-only. JSON/CSV retain their byte-faithful runtime identity.

### SourceSha256 auditability

A published `SourceSha256` is useful only when the exact source artifact is available to the reviewer. Release Evidence therefore snapshots exact `inventory/**` and `reports/**` publication-source staging.

## 22. Qualified real-artifact observations

### Adrenalin 26.5.2 Polaris/Vega

Used as an early real-artifact control to validate modern extraction, display INF discovery and canonical package analysis.

### Adrenalin 26.7.1 Main

Used repeatedly as a modern regression artifact. Qualified observations include a modern 7z SFX layout, embedded `InstallManifest.json`, a broad driver/INF surface and WDF declarations. It remains useful as a local artifact regression because it exercises the extraction/Inspect/Build path without live web discovery.

### Adrenalin 23.11.1 RDNA Combined

Established that `RDNACombined` must remain distinct evidence and that an additional `Display2` analysis surface can extend a sibling package.

### PRO Edition 26.Q1 Windows 11 RDNA and Vega/Polaris

Established multi-artifact PRO release behavior and reinforced the need to separate ReleaseKey from ArtifactKey.

### PRO Edition 26.Q1 Windows Server 2022 Vega/Polaris

Provides the strongest qualified native Server control. It demonstrates AMD-published Server-targeted INF topology and permits direct comparison between project-side projection and vendor-native Server selection.

Historical detailed records are indexed in `authored/README.md`.

## 23. Shared lessons from the AMD Chipset research toolkit

Several semantics were deliberately synchronized with the sibling AMD Chipset research work:

- preserve identifier taxonomy rather than filtering unknown identifiers;
- retain canonical TargetOSVersion dimensions;
- expose consistent static-assessment vocabulary;
- keep WDF analysis conservative;
- treat publication identity/provenance as a first-class contract;
- generate compact canonical JSON rather than post-editing public data;
- make release Evidence sufficient to independently recompute source and published hashes.

Graphics-specific identity, product-driven selection, multi-artifact releases and native Server graphics controls remain separate contracts and were not replaced by chipset assumptions.

## 24. What remains intentionally unknown

The current research does not establish:

- complete AMD product-model coverage;
- complete historical release/branch coverage;
- runtime compatibility of every projection candidate on Server 2016/2019/2022/2025;
- whether AMD proprietary `OSCheck` conditions are equivalent to or stricter than INF selection;
- whether same-version client and Server binaries are interchangeable;
- the minimal safe INF transformation for every hardware family;
- the final project certificate/catalog/signing policy;
- long-term servicing behavior of derived self-signed packages.

These are future research/deployment questions and should remain explicit rather than being inferred from the static dataset.

## 25. Where to look for historical proof

Use `authored/README.md` as the index.

The most important historical categories are:

- real-artifact qualifications;
- product-driven discovery/selection qualification;
- Windows live/full-run hardening;
- shared INF semantic synchronization;
- specific PRO/native Server controls;
- publication/portability hardening.

The top-level documentation intentionally avoids replaying every development version so that the stable contract remains readable.
