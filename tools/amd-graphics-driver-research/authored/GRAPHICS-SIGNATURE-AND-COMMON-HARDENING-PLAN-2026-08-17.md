# AMD Graphics Driver Research — Signature and Common-Hardening Plan

## Status

The user authorized implementation on 2026-08-17. G0–G4 are implemented in
the Graphics `1.1.0-dev` candidate and the established behavior is reflected
in `README.md`, `SPEC.md`, `TESTING.md` and `CHANGELOG.md`.

This record remains the engineering rationale and gate plan. It does not claim
Windows Client or Windows Server qualification.

Baseline source:

- Graphics `1.0.0`;
- `Invoke-AmdGraphicsDriverResearch.ps1` SHA-256
  `7a604cbe33ab1f04c9ecfd28ac96f08e38254f26e7eb77fa19158239e7098cd8`;
- package context
  `Deploy-Drivers-For-WindowsServer-amd-driver-research-2.1.17_rev43.zip`.

## 1. User requirement

The existing product-driven Graphics survey must continue to research the
newest release in each of the newest three available major generations for
every stable selection track. Deep certificate/signature analysis must be
narrower:

1. retain all three selected generations for ordinary acquisition, extraction,
   INF/WDF and Server-applicability research;
2. select only the newest of those three generations for deep certificate
   analysis;
3. make that decision independently for each Graphics product/OS/package
   lineage;
4. avoid repeated certificate work when multiple product categories reference
   the same installer material;
5. retain every product/track reference as provenance after de-duplication.

This follows the same broad-research versus narrow-certificate principle used
by Chipset and NPU, while preserving Graphics-specific product-driven
selection.

## 2. Current three-tool assessment

| Capability | Chipset 2.1.17 | NPU 1.3.3-dev | Graphics 1.0.0 |
|---|---|---|---|
| Normal research scope | Complete selected release set | All three reviewed public artifacts | Newest release in newest three major generations per stable track |
| Deep certificate scope | Newest selected release only | Newest artifact in each current NPU package case | Not implemented |
| Explicit target plan | Release ranking in Signature | Metadata-owned `CertificateVerificationPlan` | Not implemented |
| CMS/X.509/Authenticode | Implemented | Ported from common engine | Not implemented |
| Windows CAT/SignTool | Implemented | Implemented | Not implemented |
| File-content de-duplication | SHA-256 within selected release | SHA-256 within each selected artifact | Not applicable yet |
| Installer de-duplication | Release-oriented | Artifact/package-case-oriented | Global direct AMD EXE URL de-duplication with provenance |
| Transfer integrity | Bounded retry, partial-content rejection, atomic completion | Shared acquisition kernel | Product-page retry exists; installer transfer lacks the full current common contract |
| Diagnostics | JSONL events and failure snapshots | Shared/hardened evidence path | Older evidence/transcript path |
| PowerShell 5.1 cardinality gate | Implemented | Ported and qualified | Dedicated source/self-test gate absent |

A source-level function-name inventory found 250 Chipset functions, 254 NPU
functions and 147 Graphics functions. Chipset and NPU share 123 names; 63 of
those shared names are absent from Graphics. The absent set is concentrated in
CMS/X.509/Authenticode, Windows catalog and SignTool processing, toolchain
identity, locale-neutral native result classification, PowerShell 5.1
cardinality checks and diagnostic events. Function-name equality is an
inventory aid, not proof that every body can be copied without adapter review.

## 3. Current Graphics selection facts

The rev43 generated Graphics selection plan records:

| Metric | Value |
|---|---:|
| Product groups | 21 |
| Stable `SelectionTrackKey` values | 38 |
| Selected track-generation rows across newest three generations | 95 |
| Unique selected AMD EXE URLs | 23 |
| Newest-generation references after narrowing per track | 38 |
| Unique newest-generation AMD EXE URLs | 9 |
| Newest URLs referenced by more than one product group | 8 of 9 |

All 23 retained installer artifacts have distinct outer-file SHA-256 values in
the current generated baseline. The currently observed cross-category sharing
is therefore already visible as repeated references to the same URL. A second
post-acquisition SHA-256 gate is still required for future URL aliases or CDN
changes.

The numeric age of the chosen release may differ between tracks. For example,
a Windows Server 2016 PRO track can legitimately have 22.Q4 as its newest
available generation while a Windows Client track has a 26.x release. A single
global Graphics version must never replace per-track selection.

## 4. Planned certificate target contract

### 4.1 Selection unit

The certificate selection unit shall be the existing stable
`SelectionTrackKey`:

```text
ProductGroupKey | OperatingSystemTrack | PackageFamily
```

`ProductGroupKey` alone is too coarse because it would collapse Client and
Server lines or Adrenalin and PRO Edition. `ArtifactRole` is evidence but does
not split a stable historical track; required sibling artifacts in the newest
selected release must remain eligible before content de-duplication.

### 4.2 Scope separation

The implementation shall keep three independent concepts:

1. full Graphics research corpus: newest release in newest three major
   generations per stable track;
2. certificate target references: only rows belonging to the newest selected
   major generation inside each stable track;
3. certificate execution artifacts: unique installer material after URL and
   acquired-byte de-duplication.

Older two selected generations remain intentionally researched. Their absence
from deep certificate output is `ExcludedByPolicy`, not `Fail`, not
`NotFound`, and not evidence that ordinary inspection was skipped.

### 4.3 Deterministic plan ownership

Graphics `Select` shall emit a planned certificate-target section because
product-driven ranking is complete only after `Select`. `Acquire` shall resolve
that plan against actual artifact SHA-256 values. `Signature` shall consume the
resolved plan and shall not independently rank releases.

The plan shall record at minimum:

- policy identifier and version;
- full research track and artifact counts;
- candidate and selected major generations per `SelectionTrackKey`;
- selected release, artifact and source URL;
- all product, selection-track and driver-track references;
- URL de-duplication decisions;
- acquired SHA-256 de-duplication decisions;
- analyzed artifact identities;
- explicitly excluded historical selections and reasons.

### 4.4 De-duplication authority

Use layered de-duplication:

1. normalized direct AMD EXE URL at Select time;
2. immutable outer installer SHA-256 after Acquire;
3. extracted candidate-file SHA-256 inside static signature analysis.

Do not de-duplicate by release string, filename, approximate package size,
similar INF set or similar extracted payload. Different outer hashes may carry
different signatures or timestamps, which is exactly evidence the Signature
stage is intended to preserve.

Static parsing of byte-identical extracted files may be cached globally by file
SHA-256. Catalog-to-kernel native verification remains artifact-contextual
because the catalog set and association evidence belong to a concrete package.

## 5. Planned Signature stage

The normal future pipeline is expected to become:

```text
Test
  -> ProductDiscover
  -> ProductMetadata
  -> Select
  -> Acquire
  -> Extract
  -> Inspect
  -> Signature
  -> Build
```

The common engine candidate includes:

- candidate discovery by file content/name contract;
- PE `WIN_CERTIFICATE` parsing;
- CMS/PKCS#7 envelope parsing;
- nested-signature and timestamp-token traversal;
- X.509 certificate inventory keyed by DER SHA-256;
- Authenticode signed-content digest versus computed PE digest;
- `Get-AuthenticodeSignature` observation on Windows;
- Windows catalog member enumeration and catalog hash calculation;
- content-addressed catalog-to-kernel association;
- locale-neutral SignTool result classification;
- separate ordinary Authenticode, kernel diagnostic, explicit-catalog kernel
  and target-OS profiles;
- Windows SDK/WDK toolchain identity and capability evidence;
- public host-neutral static evidence and private Windows-native evidence;
- explicit `NotObserved` semantics for installation, kernel load and device
  function.

No stage may execute AMD Setup, install a certificate, modify an INF/CAT,
install a driver, change boot policy or claim deployment approval.

## 6. Common hardening required before a user rerun

Graphics installer files are large. The implementation cycle should also
adopt the reviewed common transport and diagnostic contracts before requesting
another full real-environment run:

- maximum AMD HTTP concurrency `1` and a source-contract self-test;
- bounded retry taxonomy and exponential backoff with jitter;
- bounded `Retry-After` handling;
- fresh-session/cache-bypass retry behavior where applicable;
- `.partial` staging and atomic completion;
- HTTP status, `Content-Length`, `Content-Range` and received-byte conservation;
- AMD `Download-Incomplete`/partial response rejection;
- installer payload validation before cache promotion;
- structured per-attempt evidence;
- redacted JSONL diagnostic events and failure snapshots;
- PowerShell 5.1 zero/one/many cardinality self-test and source audit.

Graphics-specific product-page recovery and bounded extraction shall be
preserved. The NPU fixed-artifact catalog, Chipset release ranking, NPU
hardware resolver and Chipset selector/MSI semantics shall not be imported.

## 7. Work packages and hold points

### G0 — Baseline and contract freeze

- verify exact Graphics source and all relevant docs/data/schema hashes;
- record the current 21-group/38-track/95-selection/23-artifact fixture;
- define schemas before changing generated output;
- confirm no known unexcepted common defect remains at the reference source.

Exit: reviewable source inventory and approved implementation allowlist.

### G1 — Common primitive migration

- port only reviewed device-neutral signature, toolchain, transport,
  diagnostics and cardinality primitives;
- preserve Graphics adapters and product-driven acquisition/extraction;
- add AST/function contract checks where useful;
- do not change generated `public/**` yet.

Exit: parser and common primitive self-tests pass on the development host.

### G2 — Graphics certificate-plan adapter

- extend selection schema with a planned target map;
- select newest major generation independently per `SelectionTrackKey`;
- preserve sibling artifacts and many-to-one provenance;
- resolve actual artifacts by SHA-256 after acquisition;
- add positive, missing-target, ambiguous and duplicate-reference fixtures.

Exit: deterministic plan fixture produces 38 newest track references and 9
unique URL targets against the retained rev43 selection snapshot, without
hard-coding those counts as future live-web truth.

### G3 — Signature integration

- add `Signature` after `Inspect` and before `Build`;
- add static/native schemas and Evidence surfaces;
- consume the plan without re-ranking;
- attach static results only to analyzed artifacts;
- exclude older generations explicitly;
- enforce no-mutation and dependency semantics.

Exit: synthetic/static end-to-end fixture passes with zero unexpected CMS parse
failures and zero PE signed-digest mismatches.

### G4 — Offline and local qualification

- parse/encoding/line-ending checks;
- all Test-stage regressions;
- selected real-artifact replay from retained inputs where permitted;
- JSON/schema/publication/manifest validation;
- transport negative tests without AMD load;
- compare the unchanged three-generation research surface with the baseline.

Exit: zero known unexcepted common defects and a minimum-sufficient Windows
test proposal.

### G5 — Windows Client Gate A

This gate is not authorized by this plan. When separately authorized, its
hypothesis shall be that the exact candidate produces locale-neutral
Windows-native evidence for every planned unique current artifact while
preserving three-generation research and performing no mutation.

PASS evidence shall include:

- exact script SHA-256 and Evidence ZIP integrity;
- complete target-plan reconciliation;
- expected unique-target count derived from the pinned run;
- zero unexpected static parse/digest errors;
- SignTool/toolchain identity and per-kernel catalog-bound coverage;
- private/public separation and publication validation;
- all selected stages PASS and exit code `0`.

PASS enables evidence review only. It does not authorize Server execution,
driver application or release promotion.

### Platform hold

After Client Gate A, stop. ChatGPT/Claude must review and explicitly accept the
Evidence before any Windows Server gate is proposed.

### G6 — Windows Server gate, only if needed

A Server run is not automatically required merely because Graphics contains
Server-targeted packages. It requires a separate production-relevant
hypothesis, separate authorization and a minimum-sufficient scope. Client PASS
does not authorize Server execution.

### G7 — Documentation and coordinated-release preparation

- update normative README/SPEC/TESTING/CHANGELOG only after implementation
  behavior is established;
- perform final cross-tool common-logic alignment;
- regenerate clean evidence/public data as required;
- prepare independent review and coordinated release material separately.

## 8. Acceptance criteria

Implementation acceptance requires all of the following:

- existing newest-three-generation research selection remains intact;
- newest certificate generation is selected per stable track, never globally;
- same installer is analyzed once while all provenance references survive;
- acquired SHA-256 is the authoritative identical-material key;
- older generations are explicitly excluded only from deep certificate work;
- Signature consumes, rather than recreates, the plan;
- public static and private native evidence are schema-valid;
- no AMD installer, certificate or driver is executed/applied;
- AMD network concurrency remains `1`;
- transport completion is atomic and byte-conserving;
- PowerShell 5.1 cardinality and source-contract regressions pass;
- publication is fail-closed and does not overwrite the accepted baseline on a
  partial or failed run;
- no real-machine run is requested until common defects are resolved and the
  quality hypothesis/PASS evidence/PASS enablement are stated.

## 9. Remaining authorization boundary

The completed authorization covered source/schema/document implementation and
offline/local validation. It did not authorize:

- a live AMD download or user-machine test;
- historical deep-signature qualification;
- a global Graphics latest version;
- host GPU-to-package deployment recommendation;
- INF conversion, catalog regeneration, certificate installation, self-signing
  or driver application;
- workload/functionality qualification;
- GitHub mutation or stable promotion.

Each requires the appropriate later work authorization.

## 10. G0–G4 implementation result

Implemented in Graphics `1.1.0-dev`:

- deterministic newest-generation certificate planning per stable track;
- URL then outer-installer SHA-256 execution de-duplication;
- global extracted-file SHA-256 static parsing with retained provenance;
- `Signature` between `Inspect` and `Build`;
- common CMS/X.509/Authenticode, catalog, SignTool and toolchain primitives;
- sequential atomic installer transfer with retry/partial-response contracts;
- redacted diagnostic JSONL/failure snapshots;
- PowerShell 5.1 cardinality/source-contract gates;
- public static versus private native evidence separation.

Local PowerShell 7.6.5 validation passed:

| Gate | Result |
|---|---|
| Parser | PASS, zero parse errors |
| Built-in Test stage | PASS, exit 0 |
| Retained ordinary selection | 38 tracks / 95 track-generations / 23 URLs |
| Narrow certificate plan | 38 references / 9 URLs / 57 exclusions |
| Offline signed-PE Signature integration | PASS |
| Static parse/digest result | 0 unexpected parse failures / 0 mismatches |
| Signature schemas | PASS |
| Public privacy and manifest integrity | PASS |

G5 Windows Client Gate A remains the next platform gate. It is not authorized
or implied by these local results.
