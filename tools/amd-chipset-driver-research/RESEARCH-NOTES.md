# AMD Chipset Driver Research Notes

This document consolidates the durable reverse-engineering knowledge, real-artifact observations, and downstream engineering lessons learned while building AMD Chipset Driver Research Toolkit v2.0.0.

It is **not** the normative behavioral specification; use `SPEC.md` for that. It is also not a chronological implementation log; use `CHANGELOG.md` and `reports/**` for historical qualification narratives.

The purpose of this file is to preserve the facts and design lessons most useful when evolving the research toolkit or feeding its results into the project's self-signed Windows Server chipset-driver build/deployment pipeline.

## 1. Research questions that motivated the toolkit

The original project problem looked simple: AMD chipset installers target client Windows, while the deployment project wants to understand whether contained driver packages can be adapted for Windows Server.

Research showed that this is not one decision. At least four independent planes exist:

1. AMD web publication / release identity.
2. AMD installer selection logic.
3. Microsoft INF/PnP/WDF applicability semantics.
4. Actual transformed-package installation, kernel trust, load, and runtime behavior.

Collapsing these planes creates incorrect conclusions. The toolkit therefore preserves them independently.

## 2. Core evidence principle

A statement should be no stronger than its evidence.

The working evidence vocabulary is intentionally explicit:

- `MicrosoftDefined` — conclusion follows from Microsoft-defined INF/PnP/WDF semantics.
- `AmdDeclarativeProven` — AMD XML/MSI data directly expresses the condition/value.
- `AmdCompiledStaticProven` — exact selector binary disassembly/code evidence proves the predicate.
- `AmdStaticInferred` — bounded static inference, not code-level proof.
- `AmdDynamicObservedSingleHost` — observed in one external AMD installer run.
- `AmdDynamicObservedMultiHost` — corroborated across multiple external AMD runs.
- `Unresolved` — evidence is insufficient and must stay unresolved.

Two rules follow:

1. A later release cannot inherit an older/newer compiled rule merely because the property name is the same.
2. Dynamic observation cannot silently become static proof.

## 3. Release-generation map: 2.x through 8.x

The reverse-chronological major research established a useful selector-generation map.

| Major representative | Selector family | Architecture / Qt | `DevID.xml` | Key research status |
|---|---|---|---|---|
| 2.04.04.111 | Qt selector candidate under historical ZIP | old topology; exact compiled predicates not recovered | absent | canonical acquisition/static topology proven; compiled predicates unresolved |
| 3.10.08.506 | Qt selector | x86 / Qt5 | absent | OS/Client-filter exact-binary contract; hardware predicates unresolved |
| 4.08.09.2337 | Qt selector | x86 / Qt5 | absent | OS/Client-filter exact-binary contract; hardware predicates unresolved |
| 5.08.02.027 | Qt selector | x86 / Qt5 | absent | OS/Client-filter exact-binary contract; hardware predicates unresolved |
| 6.10.17.152 | Qt selector | x86 / Qt5 | absent | OS/Client-filter exact-binary contract; hardware predicates unresolved |
| 7.11.26.2142 | Qt selector | x64 / Qt6 | present | newer selector generation; exact-binary compiled rules available where proven |
| 8.07.16.1035 | Qt selector | x64 / Qt6 | present | deepest qualification/reference, including compiled hardware predicates |

The most important generation boundary is **6.x -> 7.x**:

- x86 -> x64 selector;
- Qt5 -> Qt6;
- `DevID.xml` absent -> present;
- unmatched OS enum behavior changes;
- product/mapping vocabulary expands.

This is a real implementation-generation boundary, not just a release-number difference.

Detailed historical code-level analysis is retained in `reports/design-history/QT-SELECTOR-REVERSE-ENGINEERING.md`.

## 4. Historical 2.x availability changed during Windows qualification

Early browser/manual attempts suggested `2.04.04.111` was no longer downloadable. Later Windows toolkit runs acquired the canonical AMD ZIP through the toolkit's HTTP path and matched the known expected size/hash.

This is a useful acquisition lesson: **manual browser availability is not the same as programmatic vendor-artifact recoverability**.

The recovered 2.x topology showed:

- historical ZIP delivery containing an AMD outer installer;
- `Info.xml` / APS XML;
- no `DevID.xml`;
- `Qt_Dependancies/Setup.exe` using the historical misspelling;
- 24 recovered INF files in qualified runs.

The selector bytes were not available in the evidence bundle used for code-level reverse engineering, so 2.x compiled predicates remain unresolved. That boundary must stay explicit.

## 5. AMD selector plane vs Microsoft INF/PnP plane

This is the most important architectural finding for downstream deployment work.

AMD Setup has a vendor-specific selection pipeline. Microsoft PnP independently evaluates INF topology.

Conceptually:

```text
physical hardware
   |
   +--> AMD selector candidate generation
   |       -> AMD XML/product filtering
   |       -> AMD final supported-driver list
   |
   `--> Microsoft PnP
           -> [Manufacturer]
           -> TargetOSVersion
           -> Models section
           -> HWID/Compatible ID
           -> DDInstall
```

These paths may disagree without either one being “wrong.”

Therefore:

> **AMD Setup selected zero components on Windows Server**
>
> does not mean
>
> **the contained INF has no static Windows Server candidate**.

Likewise, a static INF candidate does not prove binary/runtime compatibility.

## 6. 8.07.16.1035 compiled OS classification

The 8.07.16.1035 selector reference is particularly valuable because the exact Qt binary was recovered and disassembled.

Key reference identity:

```text
Qt_Dependencies/Setup.exe
SHA-256: 9b8411b3f77312a770bdac35756081e77c74fb22b7c4c4f367db4f6e5ddf5462
```

The selector queries `Win32_OperatingSystem` using `root\cimv2` and reads `BuildNumber`, `Caption`, and `Version`.

Its client-family mapping is based on Caption substrings:

```text
Windows 7  -> client enum 0
Windows 10 -> client enum 1
Windows 11 -> client enum 2
other      -> unmatched
```

Qualified Windows Server captions therefore fall outside the client mapping.

This was important because it replaced an earlier working hypothesis that a direct `ProductType=3` test was the primary Server block. The observed behavior is explainable from the actual Caption classifier and subsequent Client manifest filtering.

## 7. `Info.xml` filtering explains Server empty lists

For 8.07.16.1035, the recovered product manifest contains Client products for Windows 10/11 and no Server-labelled product records.

The compiled Client filtering logic maps recognized client enums to the corresponding x64 OS label. The unmatched Server enum contributes no Client product.

This explains the dynamic pattern:

```text
AMD hardware detected
-> component candidate created
-> candidate not represented in host-specific XML/product list
-> candidate removed
-> final SupportedDrivers empty
```

The key lesson is that candidate generation and final selection are separate phases.

## 8. `SETFILTERUSB` silent-removal rule

The 8.x exact selector resolved an otherwise confusing observation: `/SETFILTERUSB` could be created and then disappear without the generic XML-removal log.

The proven exact-binary rule requires the same device context to satisfy:

```text
(DEV_790B OR DEV_780B)
AND REV_16
```

Otherwise the candidate vector is erased through a silent path.

This is an example of why missing a final candidate cannot always be explained from `Info.xml` alone.

The rule is exact-binary scoped and must not be back-projected to old selector generations without independent proof.

## 9. `SETRYZENPPKG` candidate-generation rule

For the qualified 8.x selector, candidate creation occurs inside a `DEV_790B` device path when either:

- the special CPU Family 23 / Model 160 path matches; or
- revision is one of the proven accepted revisions (`REV_61`, `REV_59`, `REV_51`).

This creates `/SETRYZENPPKG`; it does not guarantee final selection. Server fixtures can satisfy candidate generation and later lose the component through Client manifest filtering.

Again, candidate generation and final installation eligibility must remain separate data.

## 10. 3.x-6.x: same broad generation, not proof of same hardware predicates

3.x through 6.x share a broad implementation pattern:

- x86 selector;
- Qt5;
- no `DevID.xml`;
- similar Client OS classification/filtering model.

However, the research did **not** recover enough code-level evidence to promote the old-generation `SETFILTERUSB` / `SETRYZENPPKG` hardware rules to the same status as 7.x/8.x.

Those predicates therefore remain unresolved.

This is deliberate restraint, not missing cleanup.

## 11. Exact-binary contracts are preferable to generation-wide shortcuts

The toolkit stores compiled selector contracts with selector SHA-256 scope.

Benefits:

- a future AMD release cannot accidentally reuse an old predicate solely because filenames/property names stayed stable;
- reviewers can trace every compiled claim to one immutable binary;
- differences between major generations remain measurable;
- unknown behavior remains visible instead of being hidden by broad fallback logic.

For future major releases, start by fingerprinting topology/selector ownership before assuming the latest known contract still applies.

## 12. INF semantic model produced materially different conclusions from filename/HWID search

Reliable Server applicability requires preserving the full Models-selection chain:

```text
[Manufacturer]
 -> decorated target reference
 -> Models section
 -> device row
 -> DDInstall
 -> identifiers
```

Simple “HWID appears anywhere in the INF” logic loses critical TargetOSVersion context.

Likewise, scanning every `*.NT*` section as a Models section creates false structure.

The shared Chipset/Graphics INF semantic contract was developed specifically to avoid these shortcuts. The historical synchronization note is retained under `reports/design-history/INF-ANALYSIS-SYNC.md`.

## 13. Native applicability and Server projection are different facts

The research dataset intentionally records two static views:

- what the AMD INF publishes as-is;
- what would become a candidate if a client ProductType restriction were projected to Server without mutating the source INF.

The projection exists to answer a research question, not to claim vendor support.

A downstream build system may choose to transform an INF, but that is a separate project policy decision and must preserve the transformation delta/provenance.

## 14. WDF findings: installer recency is not a package WDF requirement

One early hypothesis was that a modern chipset installer might be broadly unusable on older Server because the “latest driver” required a new KMDF.

The measured dataset disproved that simplification.

The current 25-release / 643-package baseline observes a maximum declared KMDF version of **1.19**, equal to the documented Windows Server 2016 included runtime referenced by the parent project.

The durable lesson is:

> Evaluate WDF at the INF/package being selected, not at the installer-version level.

Some packages declare WDF; others do not. Different components in one AMD installer can have different requirements.

## 15. Conservative WDF scope is preferable to invented precision

A `KmdfLibraryVersion` directive may exist in an INF without the research tool having proven the exact target DDInstall/package path that depends on it.

Until dependency scope is proven, treating the declaration conservatively at INF scope is safer than claiming DDInstall-scoped compatibility.

Downstream deployment code can become more precise only when it has additional semantic evidence.

## 16. Published, embedded, and payload metadata must remain separate

AMD release notes, embedded `Info.xml`/APS metadata, MSI metadata, and actual INF payload can disagree.

The toolkit therefore keeps them separate rather than selecting one “truth” and overwriting the rest.

This pattern should be retained downstream:

```text
Published metadata  !=  Embedded metadata  !=  Payload-observed metadata
```

Differences are often the evidence, not noise to normalize away.

## 17. MSI declarative analysis is useful but easy to misinterpret

Read-only MSI inspection provides useful evidence about Features, Properties, Conditions, LaunchConditions, CustomActions and install sequences.

Several implementation lessons matter:

- PowerShell's COM adapter may not expose Automation properties exactly as expected (`Name`, `FieldCount` issues were encountered).
- `Execute()`/`Close()` return values must be suppressed so they do not become synthetic rows.
- a successful parse still needs evidence-quality checks such as all-null-row count.
- `ACTION=ADMIN` means administrative extraction; `Request: Local` under that action is not proof AMD selected the feature for normal installation.

The v2.0.0 Windows qualification parsed all 25 recovered top-level MSI databases read-only and selected 13,993 rows with zero all-null rows.

## 18. Windows host analysis exposed localization and stage-dependency hazards

Real Windows testing caught issues that static Linux testing did not:

- Japanese `OSArchitecture = "64 ビット"` required normalization to the internal x64 architecture vocabulary.
- missing 7-Zip must block extraction-dependent stages rather than allow empty/stale data to produce apparent PASS states.
- Windows Installer COM behavior differs across PowerShell versions/adapters.

The durable lesson is that a cross-platform research tool needs both static/offline qualification and a final Windows PowerShell 5.1 live run.

## 19. Publication engineering became part of research correctness

The project rejected an earlier v2 candidate because generated JSON had been manually adjusted for repository publication. That broke reproducibility.

The resulting architecture is stronger:

```text
runtime canonical data
   -> deterministic public staging
   -> privacy / path / schema / token checks
   -> manifest
   -> atomic promotion
```

Generated data is never repaired after the run. A wrong value means the generator is wrong.

This principle should be applied to every future research tool.

## 20. Field-scoped path normalization is essential for byte-faithful vendor evidence

A previous generic normalizer treated strings beginning with `/` as filesystem paths. That corrupted AMD tokens such as:

```text
/SETFILTERUSB
/SETRYZENPPKG
/info.xml
/DevID.xml
```

into artificial `external-path/...` values.

The correct model is field-scoped path portability: only known path-bearing properties are normalized.

The same lesson applies to MSI values such as `C:\`, which may be vendor data rather than the execution host path.

## 21. Canonical Raw JSON and derived aggregates have different responsibilities

Windows PowerShell 5.1 can serialize collections as:

```json
{ "value": [ ... ], "Count": n }
```

The project chose to preserve canonical per-release Raw JSON as generated primary evidence while allowing **derived aggregates** to canonicalize recognized wrappers to ordinary arrays for schema/interoperability.

This creates a useful rule:

- primary Raw evidence prioritizes fidelity;
- derived aggregate views prioritize stable interoperability/schema shape.

Do not rewrite the primary evidence merely to make a consumer easier to implement.

## 22. Git itself can alter evidence bytes

Generated file hashes are only meaningful if repository checkout bytes remain identical to publication bytes.

During release integration, Git line-ending normalization was measured to change generated data unless the repository explicitly treated `public/**` as byte-preserved content.

Therefore publication correctness includes:

- generator bytes;
- manifest hash;
- Git attributes;
- staged blob;
- fresh-checkout bytes.

This is a general lesson for any repository that commits generated evidence with SHA-256 provenance.

## 23. Public allow-list is safer than extension-based publication

A `.json` or `.md` extension does not make a file repository-safe.

The toolkit therefore defines:

```text
public/**
```

as the only generated auto-commit surface.

Host/debug/runtime material remains outside that allow-list even if it is valid JSON.

This avoids publishing ProcessorId, device instance IDs, local paths, transcripts, or other host-specific evidence merely because they are structured data.

## 24. Private Evidence remains essential even when it is not public

Private Evidence provides the source side of the provenance chain:

```text
script SHA
 -> Windows execution
 -> runtime source snapshots
 -> public manifest SourceSha256
 -> published artifact SHA
```

Keeping private Evidence out of Git does not reduce auditability if the audit bundle carries it and the public manifest can be independently recomputed.

## 25. Summary reports are views; Raw JSON is the independently reviewable source

Human-readable Markdown is valuable for navigation and conclusions, but another reviewer should be able to recompute those conclusions from Raw JSON.

For the v2.0.0 baseline, the repository publishes 25 per-release canonical analyses and aggregate CSV/JSON views. The 643-package inventory and Windows Server summary figures can be recomputed without trusting report prose.

This is the preferred model for future research tools.

## 26. Downstream self-signed driver build: recommended decision flow

The research findings support a more disciplined downstream build pipeline:

```text
1. identify exact AMD source artifact + SHA-256
2. recover complete package/INF/source-file inventory
3. select target physical hardware identifiers
4. evaluate native INF applicability
5. evaluate non-mutating Server projection separately
6. attach AMD selector evidence as an independent audit signal
7. evaluate WDF per selected package
8. apply explicit project allow/exclude policy
9. freeze an immutable deployment/build plan
10. transform only planned INF/package artifacts
11. regenerate catalog
12. sign the derived package
13. record derived hashes + signing identity
14. install on target Server lab host
15. verify DriverStore / device binding / kernel trust / runtime behavior
```

The deployment pipeline should never infer step 8 from “AMD Setup selected it” alone.

## 27. Recommended per-package decision record

A future/self-signed build pipeline benefits from retaining a record similar to:

```text
SourceRelease
SourceArtifactSha256
OriginalInfSha256
OriginalSysSha256 / referenced payload hashes
HardwareIds / CompatibleIds
SelectedManufacturerModelsPath
TargetWindowsServerProfile
NativeInfApplicability
ServerProjectionApplicability
AmdSelectorEvidenceLevel
AmdSelectorOutcome
WdfRequirement
WdfDecision
PackageCompletenessDecision
TransformationApplied
DerivedInfSha256
DerivedCatalogSha256
SigningIdentity
InstallQualificationResult
KernelTrustObservation
RuntimeQualificationResult
Notes / unresolved evidence
```

This makes “why did we include/modify/install this driver?” answerable months later.

## 28. Preserve source and derived provenance separately

Once an AMD INF/package is modified and self-signed, it is no longer the original AMD-signed artifact.

A downstream pipeline should preserve lineage:

```text
AMD release/hash
 -> original INF/SYS/CAT hashes
 -> transformation description
 -> derived INF hash
 -> derived CAT/package hash
 -> project certificate/signature identity
 -> target-host qualification evidence
```

Do not relabel a transformed package as though AMD shipped those bytes.

## 29. Package completeness matters

INF transformation is not just editing one text file. A usable package depends on the source files referenced by the INF and sometimes by sibling package structure.

Downstream packaging should derive/carry an explicit payload set rather than copy files based on filename intuition.

The parent deployment project has independently moved toward immutable deployment plans and payload-hash provenance; chipset research data is a natural input to that model.

## 30. Important anti-patterns

Avoid these shortcuts:

### Anti-pattern: Server means reject every AMD chipset package

Wrong because AMD installer Client filtering and Microsoft INF applicability are independent planes.

### Anti-pattern: AMD Setup selected nothing, therefore the INF cannot work

Wrong for the same reason. It may only describe the vendor installer's selection policy.

### Anti-pattern: newest AMD release means newest KMDF is required everywhere

Wrong. WDF is package/INF evidence, not an installer-version property.

### Anti-pattern: HWID appears anywhere, therefore package applies

Wrong. Preserve the Manufacturer/TargetOSVersion/Models/DDInstall path.

### Anti-pattern: same Qt generation means same compiled rule

Wrong. Compiled rules remain hash scoped.

### Anti-pattern: unresolved old-major rule can inherit newer behavior

Wrong. `Unresolved` is an intentional evidence state.

### Anti-pattern: public JSON can be cleaned up after generation

Wrong. Fix the generator and regenerate.

### Anti-pattern: Markdown report is enough for third-party verification

Weak. Publish machine-readable evidence and schema so the report can be recomputed.

### Anti-pattern: static candidate proves runtime compatibility

Wrong. Installation, kernel image trust, device binding, reboot and runtime behavior are separate qualification layers.

## 31. Recommended feedback order into the deployment project

When feeding research into deployment code, the safer order is:

1. source/provenance identity;
2. semantic INF selection;
3. per-package WDF evidence;
4. package completeness/source payload identity;
5. AMD selector evidence as audit context;
6. explicit project policy/deployment plan;
7. transformation/catalog/signing;
8. target Server runtime qualification.

Do not begin by reimplementing every AMD proprietary selector predicate in the deployment script. The first engineering goal is **explainable, reproducible package selection**, not perfect reproduction of AMD Setup.

## 32. Open research boundaries

Useful future work includes:

- deeper proof of 2.x compiled selector behavior if exact bytes become independently available for RE;
- additional exact-binary old-major hardware predicates where evidence justifies the effort;
- narrower DDInstall-scoped WDF dependency analysis where INF structure permits proof;
- additional AMD installer generations when release topology changes;
- cross-checking research selector predictions against new physical hosts without broadening one-host observations;
- measuring which research decisions most directly improve the deployment project's immutable deployment plan.

These are research opportunities, not missing release requirements for the current v2.0.0 baseline.

## 33. Where to find detailed evidence

Use these layers:

- `public/inventory/releases/**` — canonical per-release Raw JSON;
- `public/inventory/**` — generated indexes/aggregate views;
- `public/reports/**` — generated current reports;
- `reports/design-history/QT-SELECTOR-REVERSE-ENGINEERING.md` — historical detailed selector RE narrative;
- `reports/design-history/INF-ANALYSIS-SYNC.md` — historical Chipset/Graphics semantic-sync narrative;
- `reports/README.md` — historical report index/policy;
- `CHANGELOG.md` — implementation chronology.

When a historical report conflicts with `SPEC.md`, the current normative specification wins. When report prose conflicts with public Raw JSON, investigate the generator/evidence chain rather than editing the generated data.
