# AMD Chipset Driver Research Toolkit Specification

## REV81 current release authority

This specification governs the coordinated `3.0.0` release candidate after
Claude closed Cycle B at REV80. Chipset Gate 2C and the exact REV77 Windows
Server / Windows PowerShell 5.1 `PathSafety,Test` gate are accepted/no-repeat.
REV81 changes documentation only; the executable, contracts, schemas, reviewed
data, generated `public/**`, canonical path and accepted Evidence remain
unchanged. Historical revision requirements below retain their original scope
but SHALL NOT be interpreted as current pending gates.

## REV77 private Evidence execution-context contract

Every normal and emergency Evidence `run-context.json` SHALL contain one
`ExecutionContext` object. On Windows it SHALL attempt read-only
`Win32_OperatingSystem` collection and record `ExecutionClass`, `ProductType`,
`ProductRole`, `Caption`, `Version`, `BuildNumber`, `EvidenceScopes`,
`CollectionStatus`, and `CollectionSource`. Windows inventory failure SHALL be
represented as typed `WindowsOther`/`Unavailable` evidence, not omitted. The
contract SHALL be identical across Chipset, Graphics, and NPU and SHALL be
covered by synthetic Client, Domain Controller, Server, other-Windows,
non-Windows, and unavailable-inventory self-tests.

This changes private Evidence schema to
`amd-chipset-driver-research-evidence/1.2`; executable version stays `3.0.0`.

## Current authority and release boundary

This specification governs executable version `3.0.0`. Umbrella revisions
such as `REV77` identify coordinated package/document evolution and do not
silently change the executable version, schemas, generated `public/**` data or
qualification scope.

The historical pre-3.0.0 Windows Server smoke is a regression reference. The
exact REV77 `3.0.0` `PathSafety,Test` smoke establishes the environment, common
self-test, Evidence-finalization and summary contracts for the current source
and is accepted/no-repeat. Neither result SHALL be cited as proof of live
acquisition, complete research/publication, driver installation, kernel load
or device function.

A qualification-only cross-tool launcher SHALL NOT be part of the release
surface. Any future included orchestrator requires a separately reviewed,
data-driven multi-scenario contract covering at least Smoke, bounded short E2E,
explicit full/target-host authorization, dry-run expansion, source/prerequisite
preflight, typed results and Evidence verification.

## rev59 public-path requirements

- `PathSafety.ArchivePath` SHALL be classified as a path-bearing property and converted before canonical per-release Raw JSON is written.
- Public validation SHALL inspect decoded JSON scalar values and SHALL fail closed if a toolkit, private-evidence, user-profile or temporary-directory root remains.
- The public aggregate SHALL be derived from already-portable per-release JSON; it SHALL NOT reintroduce runtime extraction paths.
- Vendor selector/MSI/XML values that are not execution-host paths SHALL remain byte-faithful.

## rev58 extraction path and downstream-gate requirements

- Every extraction adapter SHALL obtain artifact and container directories from `Get-AmdShortExtractionPath` and SHALL use `work\\x\\aNNNN\\cNNNN` for the runtime tree.
- Release versions, original filenames and hashes SHALL remain inventory metadata; they SHALL NOT be embedded in extraction directory names.
- Extract SHALL persist its diagnostic manifest and then fail closed unless every selected record is `ExtractionComplete`.
- Signature and other downstream analysis SHALL reject an empty or non-`ExtractionComplete` input set. Zero candidate files from an incomplete extraction SHALL NOT satisfy a PASS condition.



## rev55 current-latest and selector-correlation requirements

- The curated current-latest release SHALL be `8.08.12.551` for this frozen
  qualification cycle, with the exact AMD release-note URL recorded in
  `data/seed-releases.json`.
- For major-4-or-later releases, deterministic acquisition SHALL prefer the
  exact vendor filename form `AMD_Chipset_Software_<version>.exe` and SHALL
  retain the established lowercase fallback candidates.
- The Test stage SHALL fail closed on duplicate curated release versions, a
  different semantic newest seed record, an unexpected 8.08.12.551
  release-note identity, or loss of the preferred exact installer candidate.
- Every DevID.xml selector rule SHALL retain its device mapping even when no
  Info.xml product name/installer correlates. Such a rule SHALL be labeled
  `NoInfoProductCandidate`; it SHALL NOT be silently treated as a matched
  product, a missing payload, or an independent driver package.
- A compiled-selector contract SHALL remain release- and SHA-256-scoped. The
  8.07.16.1035 contract SHALL NOT be generalized to the distinct 8.08.12.551
  Qt `Setup.exe` binary without independent static reverse engineering.

## rev52 evidence portability requirement

Private Evidence manifest relative paths SHALL use `/` regardless of the host
OS. A user interruption SHALL remain `INTERRUPTED` with exit code `130`; it
SHALL NOT be converted into PASS evidence.

## rev51 bootstrap and evidence-finalization requirements

- Stage resolution SHALL complete before any large public-baseline parse.
- `Test`-only execution SHALL NOT restore or reconstruct the runtime research baseline.
- The monolithic driver-package aggregate SHALL be reconstructed only when a selected partial downstream stage consumes it and `Inspect` is not selected to regenerate it.
- Bootstrap and long-running per-file operations SHALL emit progress and elapsed time.
- Empty/unresolved stage state SHALL be valid input to evidence finalization and SHALL produce a non-PASS assessment.
- Failure of the normal finalizer SHALL invoke an independent emergency ZIP path. A verified emergency ZIP and SHA-256 SHALL be retained together with the raw evidence directory.
- The Canonical JSON byte contract SHALL remain runtime-independent, while its parser/writer implementation SHALL meet the real-corpus performance gate in `TESTING.md`.

## Canonical JSON normative requirements (rev50)

Repository-generated JSON MUST be serialized by `Save-CanonicalJsonFile` and
read by `ConvertFrom-CanonicalJson`. The byte contract is UTF-8 without BOM,
LF only, two-space indentation, `: ` separators, literal non-ASCII, insertion
order, explicit nulls and exactly one trailing LF. `-Compress` is retained only
as a call-site compatibility parameter and MUST NOT alter persisted bytes.

This document defines the normative behavior of `Invoke-AmdChipsetDriverResearch.ps1` for the v3.0.0 research/acquisition/signature/diagnostic/toolchain-evidence contract. The accepted Gate 2C v3.0.0 generated repository baseline is the current public authority. Historical implementation and qualification narratives are intentionally kept outside this specification under `reports/**`.

Normative terms **SHALL**, **SHALL NOT**, **SHOULD**, **SHOULD NOT**, and **MAY** are used in their ordinary specification sense.

## 1. Purpose and scope

The toolkit SHALL statically research AMD Ryzen Chipset Software publication, artifact structure, INF/WDF semantics, AMD selector behavior, and Windows Server applicability.

It SHALL support:

- release discovery and metadata provenance;
- immutable vendor-artifact identity;
- bounded static extraction;
- INF semantic/topology analysis;
- Windows Server static selector analysis;
- WDF evidence evaluation;
- AMD declarative/binary selector evidence;
- host-neutral Authenticode/CMS/X.509 signature evidence;
- optional read-only Windows-native trust/catalog observations;
- optional read-only host survey and observed-log comparison;
- private Evidence capture;
- repository-safe generated publication.

The toolkit SHALL NOT:

- execute AMD Setup as part of research;
- install or modify drivers;
- patch INF files;
- generate/re-sign catalog files;
- install trust certificates;
- claim AMD support for Windows Server;
- claim runtime compatibility based only on static analysis.

## 2. Repository placement and single-script policy

The runtime implementation SHALL remain a single PowerShell script:

```text
tools/amd-chipset-driver-research/Invoke-AmdChipsetDriverResearch.ps1
```

Static data, schemas, documentation, public generated data, and historical reports MAY exist as separate repository files.

The top-level Markdown contract SHALL consist of:

```text
README.md
SPEC.md
TESTING.md
RESEARCH-NOTES.md
CHANGELOG.md
PUBLICATION-POLICY.md
THIRD-PARTY-NOTICES.md
```

One-off design/qualification narratives SHOULD live under `authored/**`, not the tool top directory. `reports/**` is script-generated runtime staging and is never committed.

## 3. Runtime and source encoding

The Windows qualification path SHALL remain compatible with Windows PowerShell 5.1.

The distributed `.ps1` SHALL use:

- UTF-8 with BOM;
- CRLF line endings.

PowerShell 7 on Windows and Linux MAY be used for supported static/offline qualification paths.

Public generated Markdown SHALL use UTF-8 without BOM and LF-only line endings.

## 4. Safety invariants

Downloaded/local AMD artifacts SHALL be treated as untrusted input.

The toolkit SHALL NOT launch an AMD installer to obtain research data.

Static extraction SHALL be bounded by configured depth/guards and content-aware container probes.

Recovered MSI databases MAY be opened read-only through Windows Installer COM on Windows. The toolkit SHALL NOT install MSI packages.

INF inspection, host survey, and selector comparison SHALL be read-only.

The original AMD vendor artifact SHA-256 SHALL remain immutable source provenance.

Any transformed, patched, catalog-rebuilt, or self-signed package is outside this toolkit and SHALL be treated as a derived project artifact.

## 5. Stage model

### 5.1 Normal pipeline

The normal full Windows pipeline SHALL be:

```text
Test
Discover
Metadata
Acquire
Extract
Inspect
Signature
Selector
HostSurvey
HostMatch
Build
```

`-Stages All` and the default no-stage invocation SHALL resolve to the normal workflow, subject to platform/applicability rules.

### 5.2 Static-only execution

`-SkipHostAnalysis` SHALL omit host-specific survey/match behavior without changing artifact-level static analysis.

### 5.3 Explicit release selection

`-ReleaseVersion` MAY pin one or more releases. A release-audit run SHOULD pin the intended release set so vendor website changes cannot silently change the dataset.

### 5.4 Observed installer evidence

`-ObservedAmdDeviceIdLog`, `-ObservedAmdMsiLog`, and `-ObservedAmdReleaseVersion` MAY supply external qualification evidence. The toolkit SHALL NOT execute the AMD installer to obtain those logs.

### 5.5 Stage outcomes

Stage states SHALL distinguish at minimum:

- `PASS`;
- `PASS_WITH_NOTES` where a run is usable and publishable but an explicitly recorded non-current/historical gap remains;
- `REVIEW` / `FAIL` where a selected stage cannot meet its contract;
- `BLOCKED` when an upstream prerequisite failed or was not available;
- `SKIP` where a stage is intentionally not applicable/not selected.

A publication failure SHALL be able to change final assessment even when research stages pass.

## 6. Environment test contract

The Test stage SHALL record/validate enough information to determine research readiness, including:

- platform family;
- OS/process architecture;
- PowerShell version/edition;
- 7-Zip availability;
- metadata/acquisition readiness where applicable;
- extraction readiness;
- internal self-tests.

Internal self-tests SHALL include regression coverage for:

- exact compiled-selector contracts;
- localized architecture normalization;
- Windows Installer COM table/row projection behavior;
- MSI evidence-quality assessment;
- portable path normalization/token fidelity;
- publication privacy/manifest/path contracts;
- PowerShell 5.1 collection-wrapper handling;
- signature primitive known-answer coverage (DER/OID, hashing, and CMS availability).

A failed required self-test SHALL fail Test readiness.

## 7. Release discovery and metadata contract

### 7.1 Release identity

The canonical chipset release identity SHALL be the four-part AMD Chipset Software version.

Release-note URLs SHALL be provenance, not identity. If one AMD URL contains multiple version-like tokens, the parser SHALL retain enough diagnostics to explain which version became the release identity.

### 7.2 Discovery

When one or more `-ReleaseVersion` values are explicitly requested, Discover SHALL operate in **exact-release mode**. In exact-release mode, global sitemap enumeration SHALL NOT be required for correctness. The toolkit SHALL resolve only the requested release identities from operator/seed evidence when present, otherwise from the canonical AMD Ryzen chipset release-note URL pattern; Metadata SHALL subsequently validate the selected page before acquisition. The resulting `releases.json` SHALL contain only the requested release set and SHALL record that sitemap enumeration was skipped. This contract prevents transient sitemap blocking from turning a pinned run into a zero-release run.

For exact-release metadata, the toolkit SHALL tolerate AMD CMS path migration and transient transport failure. Metadata SHALL try the primary release-note URL plus any explicitly known vendor-observed alias for that exact release, SHALL apply the shared retry policy, and SHALL record per-attempt evidence. Failure to retrieve release-note HTML SHALL NOT suppress deterministic AMD installer candidates that can be derived from the exact four-part release version.

Without `-ReleaseVersion`, historical discovery MAY combine:

- curated seed releases;
- AMD site/sitemap evidence;
- explicit operator URLs.

Duplicate URLs/records referring to the same release SHALL be normalized without losing alternate-source provenance.

### 7.3 Metadata

Metadata SHALL retain AMD publication facts separately, including where available:

- release-note URL/title/article identity;
- retrieval timestamp;
- page/content SHA-256;
- candidate artifact URLs;
- parser/fetch diagnostics.

Published metadata SHALL NOT be silently overwritten by embedded/payload observations when they disagree.

## 8. Acquisition contract

For automatic historical discovery, acquisition SHALL distinguish a current/latest artifact failure from a historical availability gap. If the newest discovered release is available and only older historical release artifacts are unavailable, acquisition SHALL be `PASS_WITH_NOTES`; the gap SHALL remain explicit in acquisition evidence and canonical per-release output, and the run MAY remain publishable. If any explicitly requested `-ReleaseVersion` artifact is unavailable, or the newest discovered release artifact is unavailable, acquisition SHALL be `REVIEW`.

Acquire SHALL obtain/register the original AMD artifact without executing it.

For each release it SHALL retain enough provenance to identify:

- version;
- file name;
- file size;
- SHA-256;
- source URL/provenance;
- transfer/result diagnostics.

The implementation SHALL detect HTML/error responses masquerading as binary downloads where practical.

For AMD-protected installer downloads, a successful HTTP API call SHALL NOT by itself establish a successful artifact transfer. The downloader SHALL send the parsed release-note URL as the HTTP referrer and SHOULD establish a fresh browser-like session by requesting that release-note page before requesting the installer. A retry SHOULD use a fresh session and cache-bypass semantics.

Metadata and installer HTTP paths SHALL use a bounded shared retry taxonomy. Retryable conditions include transient connection closure/timeouts, connect/send/receive failures, HTTP 408/425/429/500/502/503/504, AMD-side transient 403, and integrity rejections that can plausibly be repaired by a fresh transfer. Known permanent client statuses such as 400/401/404/405/410/422 SHALL fail fast. Retry delay SHALL use bounded exponential backoff plus jitter and SHALL respect a parseable `Retry-After` value within the configured policy bound. Retry attempts after the first SHALL bypass caches and SHOULD disable connection persistence to avoid reusing a broken transport path.

A pre-existing cached installer SHALL be validated before reuse. If invalid, it SHALL be preserved only as private diagnostic evidence, removed from the canonical cache, and the same current candidate SHALL be retried over the network before moving to a lower-priority candidate.

For an explicitly requested release, if no installer artifact is available after all candidate/retry processing, Acquire SHALL fail at the acquisition stage after writing `acquisition.json`; later extraction/signature stages SHALL be blocked rather than emitting a misleading secondary signature failure.

The downloader SHALL stage bytes under a temporary/partial path and SHALL NOT expose them as the cached canonical artifact until all applicable transport checks pass. It SHALL record final response URI and transport metadata sufficient to distinguish full content, partial content, redirect/error content, and byte-count mismatch. An AMD `Download-Incomplete` redirect SHALL be rejected. An HTTP 206 response SHALL be accepted only when a parseable `Content-Range` proves that the response covers byte zero through the final byte of the complete object; other partial ranges SHALL be rejected and retried. When `Content-Length` or total range length is available, the received byte count SHALL be conserved exactly. A candidate payload SHALL also pass installer-format/size validation before atomic promotion to the canonical download path.

The implementation SHALL use a single post-transfer payload-acceptance decision for runtime and self-test coverage. The self-test SHALL include at least: exact byte-count match with valid installer payload, truncated-byte mismatch, empty response body, and invalid installer payload at the expected byte count.

A user-created transfer archive SHALL NOT replace the inner AMD artifact as canonical vendor identity.

## 9. Static extraction contract

Extraction SHALL be bounded and recursive only where static evidence justifies recursion.

Observed container families include:

- historical ZIP delivery;
- outer executable container;
- Qt selector/XML assets;
- InstallShield `ISSetupStream` inner installer payload;
- MSI;
- CAB;
- INF/SYS/CAT/XML payload.

The in-script static InstallShield decoder MAY be informed by third-party reference implementations only where attribution/licensing is preserved.

`ExtractionComplete` SHALL require driver-analysis content such as at least one INF.

Each recovered container/file SHALL retain enough relative-path/hash provenance to reconstruct the extraction chain.

Run-specific absolute filesystem paths SHALL NOT become public artifact identity.

## 10. Embedded AMD metadata contract

The toolkit SHALL preserve embedded AMD metadata separately from published support-page facts and payload observations.

Potential evidence includes:

- `Info.xml`;
- APS XML;
- `DevID.xml` where present;
- embedded product/component records;
- OS/Brand labels;
- nested installer metadata.

Byte identity between duplicated manifests SHALL be recorded where observed; similarity SHALL NOT be assumed without hash/content evidence.

## 11. Evidence-layer contract

The canonical evidence model SHALL distinguish:

- **Published** — AMD support-page/download facts;
- **Embedded** — metadata bundled in the AMD installer;
- **PayloadObserved** — files/INF/XML reached by static extraction;
- **MicrosoftDefined** — Windows INF/PnP/WDF semantics derived from Microsoft-defined formats/rules;
- **AmdDeclarativeProven** — AMD XML/MSI declarative evidence;
- **AmdCompiledStaticProven** — exact-binary compiled selector behavior proven by static reverse engineering;
- **AmdStaticInferred** — bounded inference not promoted to compiled proof;
- **AmdDynamicObservedSingleHost** / **AmdDynamicObservedMultiHost** — observed vendor behavior from qualification fixtures;
- **Unresolved** — evidence insufficient to establish a rule;
- **Runtime** — deployment/load/functional evidence produced outside this static toolkit.

Derived analysis SHALL NOT overwrite or relabel the source evidence that produced it.

## 12. Canonical INF topology

INF analysis SHALL preserve the relationship:

```text
Manufacturer
  -> TargetOSVersion
     -> ModelsSection
        -> Model
           -> DDInstall
           -> identifiers / compatible identifiers
```

The parser SHALL NOT treat every `*.NT*` section as a Models section.

Empty referenced Models sections SHALL be retained as evidence.

Identifiers SHALL NOT be limited to a fixed PCI prefix list. Unknown/component/software identifiers SHALL be preserved rather than discarded or fabricated.

## 13. TargetOSVersion and Server profiles

TargetOSVersion dimensions SHALL be represented independently when present:

- architecture;
- OS major/minor version;
- ProductType;
- SuiteMask;
- BuildNumber.

For this project:

```text
ProductType 1 = Workstation/client
ProductType 2 = Domain Controller
ProductType 3 = Server/member server
```

BuildNumber SHALL be evaluated as a minimum build in static selector simulation where Microsoft semantics require it.

Static target profiles SHALL include Windows Server 2016, 2019, 2022, and 2025 according to versioned profile data.

## 14. Windows Server analysis modes

The toolkit SHALL maintain distinct results for:

- `AsPublished` / native INF selection;
- `ServerProjection` — non-mutating client ProductType 1 -> Server ProductType 3 analytical simulation;
- `RuntimeCompatibility` — not established by static analysis.

A projected candidate SHALL NOT be represented as vendor-supported or runtime-compatible.

AMD installer selector exclusion SHALL NOT be collapsed into INF/PnP inapplicability.

## 14.1 Signature evidence and execution-scope contract

The `Signature` stage SHALL be read-only and SHALL NOT install/stage drivers, regenerate catalogs, install certificates, change boot/security policy, load a driver, or start a device.

The stage SHALL classify its evidence scope from the runtime host:

- non-Windows: `Static`;
- Windows Client (`Win32_OperatingSystem.ProductType=1`): `Static` + `WindowsNative`;
- Windows Domain Controller/member Server (`ProductType=2` or `3`): `Static` + `WindowsNative` + `TargetServerHost`;
- unknown Windows ProductType: `Static` + `WindowsNative`, with the role kept explicit rather than guessed.


The Chipset `Signature` stage SHALL analyze exactly one release from the selected release set. If the selected set contains one release, that release SHALL be analyzed. If it contains multiple releases, the release with the highest parseable semantic version SHALL be analyzed. Other stages MAY continue to analyze the complete selected historical set. Signature evidence SHALL record the release-selection policy, the candidate-release count, and the analyzed release version(s). Failure to analyze historical releases SHALL NOT be inferred from their intentional exclusion from the Signature scope.


### 14.1.1 Static signature evidence

Static analysis SHALL remain reconstructable from extracted artifact bytes and SHALL NOT depend on the execution host trust store. At minimum it SHALL:

- inventory unique extracted PE/signature-bearing files by SHA-256, detecting PE content by the `MZ` header rather than relying only on a conventional file extension and retain every observed relative-path occurrence;
- retain file size and SHA-1 only as legacy/correlation evidence;
- enumerate PE `WIN_CERTIFICATE` entries where present;
- parse PKCS#7/CMS Authenticode envelopes without stopping at only the first signer;
- recursively retain nested Authenticode signatures (`1.3.6.1.4.1.311.2.4.1`) and timestamp/countersignature evidence where present;
- identify X.509 certificates by SHA-256 of the DER certificate bytes and retain subject/issuer/serial/validity/algorithm/EKU/extension evidence;
- retain signed `SPC_INDIRECT_DATA_CONTENT` digest evidence and independently recompute the PE Authenticode digest where supported;
- preserve parse failures/unsupported algorithms explicitly instead of dropping the affected file/signature.

A `.NET SignedCms.CheckSignature(true)` result MAY be recorded as `CmsLibrarySignatureCheck`, but it SHALL be labelled diagnostic library behavior only. It SHALL NOT be treated as Windows Authenticode policy, kernel signing policy, Secure Boot acceptance, catalog trust, or runtime truth.

`SpcIndirectData` digest parsing SHALL be attempted only when the CMS content type is Authenticode `SpcIndirectDataContent` (`1.3.6.1.4.1.311.2.1.4`). RFC3161 timestamp TSTInfo and catalog CTL content types SHALL be recorded as not applicable to the SPC indirect-data parser rather than as parse failures.

### 14.1.2 Windows-native evidence

On Windows, the toolkit MAY collect additional read-only observations using platform facilities including:

- `Get-AuthenticodeSignature`;
- SignTool `/pa`, `/kp`, `/all`, `/v`, explicit catalog-bound kernel verification, and target-build `/o` probes where SignTool is available;
- WinTrust/Catalog APIs for catalog-level attributes, complete catalog-member enumeration, and member attributes;
- `CryptCATAdminCalcHashFromFileHandle2` catalog/SIP hashes for content-correct driver-to-catalog correlation; raw file SHA values SHALL NOT be treated as catalog member hashes;
- read-only certificate/trust observations required to explain those checks.

Tool unavailability SHALL be represented as `NotObservedToolUnavailable`/equivalent rather than a fabricated failure. Native command output and host-specific paths SHALL remain private by default.

SignTool `/o` SHALL be represented as a target platform/version/build policy observation only. It does not encode INF `ProductType` and SHALL NOT be described as Windows Server ProductType emulation or Target Server runtime verification.

Catalog-bound kernel-policy verification and target-OS verification SHALL use separate semantic profiles. The kernel-policy profile SHALL use `/kp /c <catalog> <driver>` without `/o`. The explicit target-OS profile SHALL use `/c <catalog> /o <target> <driver>` and SHALL intentionally omit both `/kp` and `/pa`, allowing SignTool's Windows Driver Verification Policy to remain the policy context while `/o` supplies the target OS version. The implementation SHALL NOT combine `/kp` and `/o` in the same catalog-bound target-OS profile unless a future separately-qualified SignTool contract proves that combination valid.

### 14.1.3 Target Server host evidence

`TargetServerHost` SHALL be emitted only when execution is actually on Windows Server/Domain Controller. It MAY record read-only host security posture such as Secure Boot support/state, Device Guard/HVCI observations, and TESTSIGNING boot-configuration observation.

Because the Signature stage performs no driver installation/load, Target Server PnP installation, kernel-load, Code Integrity runtime decision, and device runtime/function evidence SHALL remain `NotObserved` until a separate explicit qualification produces them. `NotObserved` SHALL NOT be converted to `Fail` or `Pass`.

### 14.1.4 Public/private boundary

Host-neutral static signature evidence MAY be embedded into canonical per-release Raw JSON and published under the existing fail-closed `public/**` contract. Windows-native trust/tool output, catalog enumeration tied to the runtime host, and Target Server host posture SHALL remain private/runtime evidence by default unless an explicitly reviewed publication artifact is later defined.

If recursive extraction renames a catalog to a non-`.cat` suffix such as `.cat1`, Windows-native verification SHALL use a byte-identical temporary `.cat` alias. The alias SHALL be private runtime material, SHALL be traceable to the canonical file SHA-256, and SHALL NOT alter the source/public artifact identity.

Canonical static evidence and native/runtime observations SHALL remain separate so later policy/parser changes can re-evaluate the same source facts without rewriting source evidence.

## 15. WDF evidence contract

KMDF/UMDF declarations SHALL remain attached to the INF/package that produced them.

Where dependency scope cannot be safely narrowed, the toolkit SHALL preserve conservative INF-wide WDF evidence rather than invent a DDInstall/component dependency.

No WDF requirement SHALL be invented for an INF that declares none.

WDF compatibility SHALL NOT be treated as sufficient runtime acceptance.

Installer release recency SHALL NOT be used as a substitute for package-level WDF evidence.

## 16. AMD selector static-analysis contract

AMD selector analysis SHALL remain independent from Microsoft INF/PnP analysis.

The toolkit MAY preserve:

- `Info.xml` / APS XML product lists;
- `DevID.xml` rules;
- selector binary path/hash/architecture/version;
- printable ASCII/Unicode string evidence;
- read-only MSI declarative tables;
- exact-binary compiled contracts;
- unresolved candidate/hardware predicates.

### 16.1 Exact-binary scope

`AmdCompiledStaticProven` rules SHALL be scoped to an exact selector SHA-256 and release context. Same Qt generation SHALL NOT imply same predicate.

### 16.2 Server classification

When a compiled selector's OS classifier is proven, the toolkit SHALL record the actual input and branch semantics rather than replacing them with a convenient SKU shortcut.

For qualified 7.x/8.x selectors, Client caption classification and Client-only manifest filtering explain observed Windows Server empty-list behavior. This evidence SHALL remain distinct from INF Server applicability.

### 16.3 Hardware predicates

A hardware candidate/filter predicate SHALL be promoted to `AmdCompiledStaticProven` only when code-level evidence supports the exact release/hash.

Older 3.x-6.x hardware predicates that were not proven SHALL remain `Unresolved` even if newer 7.x/8.x selectors contain a similar candidate name.

## 17. MSI declarative-analysis contract

Recovered top-level MSI databases MAY be opened read-only on Windows.

The toolkit SHALL distinguish at minimum:

- `ParsedReadOnly`;
- `ParsedWithErrors`;
- `ParseFailed`;
- `MsiNotRecovered`;
- platform-unavailable states where Windows Installer COM is not available.

Selected MSI tables MAY include `Property`, `Feature`, `Condition`, `LaunchCondition`, `CustomAction`, install sequences, and `Upgrade`.

COM method return values SHALL NOT leak into row data.

A successful parse containing all-null synthetic rows SHALL become a review condition.

`ACTION=ADMIN`/administrative extraction observations SHALL NOT be interpreted as feature installation selection.

## 18. Host survey and HostMatch contract

HostSurvey SHALL be read-only and MAY collect:

- OS caption/build/architecture;
- CPU information needed for selector qualification;
- PnP Hardware IDs / Compatible IDs;
- selected environment facts required for comparison.

Host-specific evidence SHALL remain private by default.

HostMatch SHALL compare host identifiers against analyzed INF/selector evidence without installing drivers.

Observed AMD final-list states SHALL distinguish:

- non-empty final list;
- explicitly observed empty final list;
- final list not observed.

An observed candidate that disappears without a proven explanation SHALL remain unknown/suspected rather than being explained by invention.

## 19. Canonical per-release Raw JSON

Each analyzed release SHALL have a 1:1 canonical Raw Analysis JSON representation. When the Signature stage has analyzed a release (normally only the newest selected Chipset release), that release record SHALL carry its host-neutral `Release.SignatureAnalysis` evidence; releases intentionally outside the Signature scope SHALL NOT be fabricated as analyzed. Windows-native/host observations SHALL NOT be embedded into that public canonical object:

```text
public/inventory/releases/<release>/amd-chipset-analysis-<release>.json
```

Canonical per-release JSON SHALL be generated compact.

Publication SHALL copy the canonical file byte-for-byte and SHALL NOT parse/reserialize it merely to change whitespace or collection shape.

Artifact-derived values such as selector tokens, MSI property values, XML paths/tokens, identifiers, and INF semantics SHALL remain byte-faithful except for explicitly defined path-bearing portability fields.

## 20. Portable-path normalization

Portable normalization SHALL be **field-scoped**, not based solely on string shape.

A string beginning with `/` SHALL NOT automatically be treated as a filesystem path.

Evidence values such as:

```text
/SETFILTERUSB
/SETRYZENPPKG
/info.xml
/DevID.xml
C:\
```

SHALL remain unchanged when they occur in non-path evidence fields.

Known execution-host path-bearing fields MAY be normalized to declared repository-portable families such as:

- `external-artifact/<leaf>`;
- `work/extracted/<release>/...`;
- `evidence/extraction-logs/...`;
- last-resort `external-path/<leaf>` for unrelated absolute paths in path-bearing fields.

The transformation policy SHALL be represented in publication metadata.

## 21. Aggregate and derived views

Aggregate indexes, CSVs, compatibility views, and generated reports SHALL be derived from canonical per-release records.

Adding or rebuilding one release SHALL NOT silently remove an unrelated retained canonical release during a partial run.

### 21.1 PowerShell 5.1 collection wrappers

Canonical per-release Raw JSON MAY retain a Windows PowerShell 5.1 serialization wrapper of the form:

```json
{ "value": [ ... ], "Count": n }
```

because the Raw JSON is primary evidence.

Tool-generated **aggregate** views SHALL project a recognized wrapper to a plain JSON array when:

- the object has the expected wrapper shape;
- `value` is enumerable/collection-like;
- the observed value count matches `Count`.

A normal domain object merely containing property names `value` and `Count` SHALL NOT be rewritten.

Publication SHALL fail closed if a recognized wrapper remains in a generated aggregate where the public schema requires an array.
Publication MAY proceed only when the core assessment is `Pass` or `PassWithNotes` **and the current run selected `Build` and completed that `Build` stage with `PASS`**. `Test`-only/analysis-only runs, `ReviewRequired`, `Interrupted`, `FatalError`, failed/blocked Build, or publication-contract failures SHALL preserve the previous validated public baseline. A `PassWithNotes` publication SHALL preserve the exact historical gap in canonical data rather than silently dropping the unavailable release.

## 22. Public/private output classification

### 22.1 Public surface

Repository-safe generated content SHALL live only beneath:

```text
public/**
```

The public surface MAY include canonical Raw JSON (including host-neutral static signature evidence), aggregates/CSVs, generated reports, run summary, publication validation, and publication manifest.

### 22.2 Private/debug/runtime surfaces

The following are not automatic generated-commit surfaces:

```text
private/**
inventory/**
reports/** script-generated runtime reports (never committed)
authored/** authored design/qualification records (committed)
work/**
evidence/** legacy location
```

Static source/docs/schemas/data remain normal explicitly reviewed source files, not unattended generated output.

### 22.3 Privacy boundary

Before publication, repository-public data SHALL be validated so host/runtime-private values do not cross into `public/**`.

Runtime absolute paths embedded inside free-text fields such as acquisition `Error`/`Detail` evidence SHALL be normalized to repository-neutral evidence markers before canonical public JSON is generated. The validator SHALL continue to inspect decoded JSON scalar values and SHALL remain fail-closed.

JSON privacy validation SHALL inspect **decoded scalar strings** so escaped Windows paths cannot bypass validation.

Host values such as ProcessorId/device instance IDs/local tool/work paths, Windows-native trust-tool output, Windows catalog enumeration observations, and host security posture SHALL remain private unless an explicit separate publication review approves a derived/sanitized publication artifact.

## 23. Public Markdown byte contract

Every generated `.md` under `public/**` SHALL be:

- UTF-8 without BOM;
- LF-only;
- CR byte count zero.

When a runtime Markdown report is published, the declared transformation SHALL be deterministic and SHALL NOT silently change report conclusions/content.

## 24. JSON and CSV publication contract

Canonical JSON and CSV SHALL remain byte-faithful to declared runtime publication sources unless an explicitly specified generated aggregate projection applies.

JSON/CSV SHALL NOT be line-ending-normalized merely to match Markdown convention.

Repository integration SHALL preserve generated `public/**` bytes verbatim so Git attributes do not invalidate manifest hashes.

## 25. Publication transaction

Publication SHALL use staging and fail closed.

The publisher SHALL:

1. seed from the last valid public baseline where partial-run preservation requires it;
2. overlay current generated public candidates;
3. apply only declared transformations;
4. build publication metadata;
5. validate privacy, path portability, selector-token fidelity, schema/shape, file coverage, size/hash, dataset consistency, and Markdown format;
6. promote staging atomically only on PASS.

A failed publication SHALL NOT replace the previous valid `public/**` surface.

## 26. Publication manifest contract

`public/publication-manifest.json` SHALL describe every public payload except itself.

It SHALL record at minimum:

- manifest entry count;
- total public file count including the manifest;
- relative path using `/` separators;
- classification;
- generation mode / transformation;
- source relative path when source-backed;
- source size/SHA-256 when source-backed;
- published size/SHA-256;
- `HandEdited` state;
- transformation policy;
- payload size/largest-file metrics required by the current schema.

`HandEdited=true` SHALL NOT occur in accepted generated output.

Manifest hashes SHALL be computed from the bytes actually staged for publication.

## 27. Private Evidence contract

A normal evidence run SHALL retain enough private evidence to audit execution without making that context public.

Evidence MAY include:

- transcript/logs;
- environment and host metadata;
- acquisition/extraction diagnostics;
- cached pages;
- optional vendor binaries only when explicitly requested;
- Windows-native signature/catalog verification and host security-posture observations.

For release provenance, Evidence SHALL snapshot the exact runtime source files referenced by publication manifest `SourceRelativePath` values under `snapshot/**`.

The Evidence manifest SHALL identify the exact script SHA-256 and run result.

## 28. Failure policy

The toolkit SHALL prefer `ReviewRequired`/non-zero release assessment to a silent inconsistent public baseline.

Examples requiring review/failure include:

- acquisition/extraction incompleteness;
- INF parse failures that violate the selected gate;
- unresolved current-stage producer data required by a downstream stage;
- MSI parse/quality failure on Windows where a recovered MSI is expected;
- publication privacy/path/schema/token/manifest failure;
- package conservation mismatch;
- required self-test failure.

Unknown evidence SHALL remain unknown rather than being converted to compatibility.

## 29. Exit-code contract

The toolkit SHALL distinguish successful completion, review-required/incomplete qualification, and fatal execution failure according to its current run-assessment implementation.

Release qualification SHALL require the expected success exit code recorded in `TESTING.md`.

## 30. Release acceptance contract

A repository release SHALL require all gates in `TESTING.md`, including:

- source/AST/static-analysis gates;
- internal self-tests;
- controlled Windows PowerShell 5.1 full run;
- Windows Client signature/native-evidence qualification for releases that change the Signature stage;
- intended release-set conservation;
- zero relevant parse failures;
- MSI quality;
- F-01 token-fidelity regression;
- per-release/CSV/aggregate consistency;
- public schema and privacy checks;
- manifest/source identity;
- private Evidence integrity;
- Git byte-identity validation;
- repository-side consumer/test updates when paths/contracts change.

Generated data SHALL NOT be accepted if it required post-run hand editing.

## 31. Relationship to downstream deployment

This toolkit SHALL remain evidence, not deployment policy.

A downstream self-signed build/deployment system SHOULD consume research evidence through an explicit decision record that links:

- AMD source release/hash;
- original INF/SYS/CAT identity and static signature evidence;
- target hardware identifiers;
- native INF applicability;
- analytical Server projection;
- AMD selector outcome/evidence level;
- WDF requirement/decision;
- package completeness/source payload set;
- transformation applied;
- derived INF/catalog/package hashes;
- signing identity;
- Windows-native trust-policy observations;
- target Server host posture;
- target Server install/load/runtime qualification.

The downstream system SHALL NOT treat an AMD Setup empty selection as proof that an INF is incompatible, and SHALL NOT treat a static INF candidate as proof of runtime compatibility.

## 32. Explicit non-goals and unknowns

The toolkit intentionally leaves these outside its claims:

- AMD support entitlement for Server SKUs;
- kernel-mode trust/loadability of a transformed package (static/native signature evidence alone is not that runtime claim);
- runtime device correctness/stability;
- unproven old-major hardware selector predicates;
- equivalence of AMD proprietary selector logic and Microsoft INF rules;
- guaranteed future availability of historical AMD artifacts;
- complete historical reverse engineering of every selector binary.

These boundaries SHALL remain explicit until new evidence changes them.

## Toolchain capability contract

`amd-driver-toolchain-capability-summary/1.1` is a shared, device-family-neutral contract intended for later Chipset/NPU/Graphics alignment. Windows execution MUST observe SignTool and Inf2Cat independently of driver-specific logic. The portable summary MUST NOT contain absolute host paths or raw localized help output. Private evidence MUST preserve the resolved executable path and verbatim help output.

For each available tool the portable evidence records binary identity (`SHA-256`, size, `FileVersion`, `ProductVersion`, PE architecture), portable Windows Kit path identity, candidate count, help probe digests, observed options/tokens, and the verification-profile contract. Capability observations use observed/not-observed semantics and MUST NOT be converted into unsupported/supported claims without an executed qualification command.

The initial shared verification profiles are `AuthenticodeDefault/1`, `KernelEmbeddedOrCatalog/1`, `KernelExplicitCatalogTargetOs/1`, and `DriverPackageSignabilityMatrix/1`. The Inf2Cat profile is explicitly mutating because a real signability qualification may generate catalogs; such a qualification MUST run only in a private disposable copy of a package and MUST NOT modify vendor source or canonical public evidence.

### Native-tool localization contract

Native Windows tool correctness MUST NOT depend on English stdout/stderr. The common localization contract is `amd-native-tool-localization-context/1.0`. Windows executions SHALL record PowerShell culture/UI culture, user/system locale and UI language where observable, numeric console input/output code pages, console encodings, and POSIX-style locale environment hints. `LANG`, `LC_ALL`, and `LC_MESSAGES` SHALL be treated as informational only for SignTool/Inf2Cat and SHALL NOT be claimed to force a Windows SDK/WDK tool language.

Capability discovery SHALL use invariant CLI tokens and ordinal comparisons, not localized explanatory prose. Native process classification SHALL use process-launch status and numeric exit code as primary signals. Natural-language output is diagnostic evidence only. A successfully launched SignTool check with exit code `0` is `Verified`; a successfully launched non-zero result is `NonZeroExit`; failure to start/invoke the process is `ToolExecutionFailed`. The toolkit MAY retain localized output for investigation but MUST NOT require English phrases such as `No signature found`, `Usage`, or `Number of signatures successfully Verified` for canonical classification.

Where command acceptance cannot be proven without localized prose, assessment SHALL fail closed. In particular, if catalog-bound target-OS verification checks are emitted but none succeed, the Signature assessment SHALL remain `REVIEW` rather than guessing that every non-zero exit represents a valid policy-negative result.


## PowerShell 5.1 collection-cardinality contract

Any value whose cardinality is consumed by `.Count` SHALL have a deterministic 0/1/N collection shape.

In particular, a value produced by a PowerShell statement expression such as `if (...) { ... }` MUST NOT be assigned directly and later dereferenced with `.Count`, because Windows PowerShell 5.1 may materialize zero results as `$null` and one result as a scalar under `StrictMode`.

Acceptable patterns include:

- wrapping the entire producing expression in `@(...)`;
- using a strongly typed list/array with a stable cardinality contract; or
- using a shared collection-normalization helper before cardinality evaluation.

The built-in `PowerShell51CollectionCardinalitySelfTest` and `CollectionCardinalitySourceContractSelfTest` are release gates for this failure family. This contract is part of the shared primitive baseline intended for later NPU and Graphics migration.
For every catalog-associated kernel binary, the assessment SHALL evaluate catalog-bound coverage per file rather than only from aggregate totals. A fully covered kernel SHALL have at least one `Verified` `KernelModeExplicitCatalog` observation and at least one `Verified` target observation for each of WS2016, WS2019, WS2022, and WS2025. Any missing or entirely unverified required profile for an associated kernel SHALL force `SignatureAnalysis=REVIEW`. `KernelModeEmbeddedOrCatalog` (`/all /kp` without explicit `/c`) SHALL remain supplemental diagnostic evidence and SHALL NOT substitute for explicit catalog-bound coverage.




## Sequential network and diagnostic-observability contract

The toolkit SHALL treat AMD network acquisition as a sequential operation with a maximum intended concurrent AMD HTTP request count of `1`.

The toolkit SHALL NOT introduce parallel AMD artifact acquisition by default through background jobs, thread jobs, runspace pools, or `ForEach-Object -Parallel`. A future device-family implementation MUST preserve the same conservative default unless project governance is explicitly revised.

The retry/backoff transport and the diagnostic/trace layer are separate contracts:

1. the transport layer decides retryability, bounded retry/backoff, `Retry-After`, referrer/session/cache behavior, payload conservation and atomic completion;
2. the diagnostic layer records bounded structured observations and MUST NOT change transport acceptance decisions.

For Evidence-enabled runs, the diagnostic layer SHALL provide a lightweight append-only JSONL event stream that can include stage boundaries, functional steps and HTTP attempts. The trace MUST remain best-effort; trace write failure SHALL NOT cause a research-stage failure.

On a stage or top-level fatal failure, the toolkit SHOULD emit a structured failure snapshot containing:

- current stage/function/step;
- exception and bounded inner-exception chain;
- PowerShell invocation/stack context;
- bounded recent diagnostic events;
- relevant additional structured context.

HTTP failure diagnostics SHOULD preserve redacted response-header evidence and a bounded response-body preview when available. Diagnostic persistence SHALL redact at least authorization, proxy authorization, cookie/set-cookie, password/secret/token/API-key/signature-like fields and obvious credential-bearing URL query parameters.

Diagnostic payload size SHALL be bounded. The default body preview limit is `2048` characters and recent-event history is bounded. Raw unlimited server error bodies SHALL NOT be copied into the structured trace merely for convenience.

The Evidence lifecycle for trace data is governed outside the repository source by project-management E0-E3 retention policy. Successful routine trace is normally transient; causal failure trace remains available while an E1 defect is active.

`DiagnosticPrimitiveSelfTest` and `SequentialDownloadSourceContractSelfTest` SHALL be included in Test-stage readiness. The latter SHALL fail if known PowerShell parallel-execution primitives are present in executable command AST or if the declared maximum HTTP concurrency is not `1`.


## Diagnostic propagation-quality contract

Before a diagnostic/transport primitive is propagated to another AMD research tool, the reference implementation SHALL have no known unexcepted common defect.

Structured diagnostic redaction SHALL distinguish credential-bearing keys from public technical signature evidence. A property name SHALL NOT be redacted solely because it contains the substring `signature`.

Expected optional runtime probes (for example SignedCms assembly fallback) SHALL NOT emit a misleading error into the user-visible PowerShell Error stream when the fallback succeeds. The failed probe SHALL remain available as structured diagnostic/runtime evidence.

The toolkit SHALL self-test:
- secret header/key redaction;
- preservation of non-secret signature evidence fields;
- signed-URL credential redaction;
- expected fallback error-stream silence;
- sequential AMD network concurrency contract.

Real-environment retest gates SHALL be impact-driven and SHALL follow the project-management quality/retest governance.


## Transcript-hygiene contract

The normal `Test` stage SHALL NOT intentionally generate caught terminating errors merely to prove a negative/fallback path when the same contract can be validated without exception injection.

Expected runtime fallbacks SHALL be represented as structured evidence and SHALL NOT create a synthetic user-visible `PS>終了エラー(...)` / `TerminatingError` transcript line.

SignedCms optional assembly probing SHALL use a no-throw managed probe path so that unavailable optional assemblies are data, not PowerShell ErrorRecords.

Signature content-type routing self-test SHALL prove Authenticode vs RFC3161/catalog routing without deliberately parsing malformed Authenticode DER during every normal Test run.

## Platform-boundary quality-gate contract

Windows Client and Windows Server qualification SHALL be treated as separate platform phases.

When a test plan crosses from Windows Client to Windows Server:
1. complete the required Client gate(s);
2. provide Evidence to ChatGPT/Claude review;
3. hold the Server execution;
4. proceed only after the Client platform checkpoint is explicitly accepted.

A Client PASS SHALL NOT be described as automatic permission to continue on a different platform.
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

- `PathSafety` SHALL be automatically prepended and SHALL complete before Test, discovery, acquisition, or extraction.
- Unsafe Windows roots and unsafe archive entries SHALL fail closed without starting an AMD network request or extracting the affected container.
- Common function bodies SHALL satisfy `data/current-three-tool-common-core-contract.json`.
- Publication-visible file enumeration SHALL use ordinal string ordering; version and numeric ordering remain explicitly typed and tool-specific.
- A bootstrap failure MAY create only the tool-local emergency evidence session after the path-safety policy permits the root.
