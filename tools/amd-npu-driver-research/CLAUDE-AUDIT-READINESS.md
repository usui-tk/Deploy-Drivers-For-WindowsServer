# Claude Audit Readiness — AMD NPU Driver Research v1.0.0

> **Superseded readiness snapshot.** This file preserves the v1.0.0 audit
> package and SHALL NOT be used to decide current `3.0.0` readiness. Current
> operator/specification/testing authority is `README.md`, `SPEC.md` and
> `TESTING.md`; coordinated qualification state is carried by the umbrella
> package management records. The correction of REV65's live-source inference
> is recorded under `authored/NPU-LIVE-PUBLICATION-DRIFT-2026-08-21.md`.

> Historical audit record. The current coordinated candidate is `3.0.0` and
> requires the Cycle B review defined by `TESTING.md`; the earlier bounded review covered
> `data/hardware-driver-selection.json`, its schemas, the hardware-only resolver,
> automatic local PnP enumeration, ten self-tests, the deterministic PS5.1
> `SignedCms` load, structured Test evidence, Evidence-snapshot allowlist,
> documentation boundaries, canonical JSON enum encoding, generated-runtime-JSON
> parse guards, and the accepted exact-source NPU-equipped Windows Client archive.
> Both the no-NPU negative-control archive and `1.3.3-dev` positive-control archive
> remain regression references; CPU/processor datasets remain audit references, not selection
> authority. Windows Server execution and deployment remain outside this acceptance.

> The external review input now also includes an accepted Windows Server 2025
> Datacenter no-NPU Gate B executed with PowerShell 7.6.5 Core. Treat it as
> Server negative-control and host-path evidence only. It is not a claim for
> Windows PowerShell 5.1 on Server or NPU-equipped Server runtime behavior.

## Review scope

The next review is Audit #4 and should evaluate the final v1.0.0 release material after fresh v1.0.0 acquisition/qualification evidence is complete.

This is broader than the earlier script-only static-analysis review.

Candidate main-script identity:

```text
Invoke-AmdNpuDriverResearch.ps1
SHA-256 2dc94306ed7f9838a05be21ae2d6f44494446aaeded9ad978d3ebde5be0c04cf
Version 1.0.0
```

## Review inputs expected

At minimum review together:

```text
Invoke-AmdNpuDriverResearch.ps1
README.md
SPEC.md
TESTING.md
CHANGELOG.md
REVERSE-ENGINEERING-NOTES.md
SOURCES.md
PUBLICATION-POLICY.md
ARCHITECTURE-PARITY.md
data/**
schemas/**
public/**
tools/Collect-AmdNpuHardwareIdentityEvidence.ps1
tools/README.md
tools/TESTING.md
```

Private AMD vendor packages and private host Evidence are not Git commit surfaces. They may be supplied separately only when an audit needs to recompute a specific artifact/runtime claim.

## Earlier source-review #1 findings already remediated

The earlier review identified two accepted blocking classes:

1. `-PublicOutputRoot` parameter/state collision;
2. unqualified top-level script-parameter reads through dynamic scope.

0.8.1-dev remediated both before the 0.9.0 feature work:

- resolved public-output state is separate from the caller parameter;
- explicit `-PublicOutputRoot` behavior has a regression probe;
- required values are passed explicitly through the NPU orchestration/stage call graph.

Known analyzer false positives called out by the earlier reviewer were intentionally not “fixed” by changing correct code solely to satisfy the analyzer.

## v1.0.0 release surfaces to review

### Exact processor catalog

- 112 reviewed exact SKUs;
- exact-SKU evidence only;
- negative controls retained;
- no series-prefix fallback;
- unknown processor -> fail closed.

### Processor-driver applicability

Review:

```text
data/processor-driver-applicability.json
schemas/processor-driver-applicability.schema.json
public/catalog/processor-driver-applicability.json
public/catalog/processor-driver-applicability.md
```

Required semantics:

- public reviewed artifacts can be recommendation candidates;
- private 314 cannot be recommended;
- broad HWID match is insufficient without reviewed published-family support;
- Gorgon Point remains `ReviewRequired` for the current reviewed 376 publication boundary;
- Gorgon Halo remains `ReviewRequired` while exact identity/artifact support is incomplete;
- Windows client observed runtime never sets Windows Server runtime proof.

### Identity model

Audit that code/data/docs do not collapse:

```text
exact CPU SKU
codename
PCI DEV
PCI REV_XX
quicktest-style classification
XRT device name
XRT firmware version
firmware device revision
```

### INF / Server model

Audit the correction that the reviewed NPU INF is `NTamd64.10.0...22000` without explicit ProductType=1.

Expected static profile state:

```text
Server 2016/2019/2022 -> below build floor
Server 2025           -> as-published selector candidate
```

No static result may be mislabeled Server runtime proof.

### Installer / binary contracts

Review exact-hash scoping and the separation of:

- installer route behavior;
- package path presence;
- driver-binary generation recognition;
- AMD published family support.

The 376 binary's Gorgon Point recognition must **not** automatically promote Gorgon Point to a 376 recommendation.

## Qualification already completed — v1.0.0

### Linux / PowerShell 7

```text
Evidence  AmdNpuDriverResearchEvidence_20260814-055908_Linux_v1.0.0-Linux-canonical-corpus-qualification.zip
SHA-256  9ff11c1ee761274fa9190102cdf908f073b45651b4cc627fdc05b080a2e3fdeb
Result    13/13 PASS, ExitCode 0
PS        7.6.4 / Core
Mode      canonical reviewed corpus replay
Script    2dc94306ed7f9838a05be21ae2d6f44494446aaeded9ad978d3ebde5be0c04cf
```

The Linux preparation environment could not complete live AMD CDN acquisition, so the successful Linux qualification used the canonical reviewed public corpus.

### Windows PowerShell 5.1 — fresh automatic acquisition

```text
Evidence  AmdNpuDriverResearchEvidence_20260814-060553_Windows.zip
SHA-256  0fa97dfbdd4c86ca09bc003c1fb8e9cbf485e4b16f731cdac11fa656eba79392
Public    public(20260814-060739).zip
Public SHA d415e2d7019bf234dc67b3eb072239f38f16ce692f6ad2ad895cf601d03ec91e
Result    13/13 PASS, ExitCode 0
PS        5.1.26100.9168 / Desktop
Acquisition PackagePath=[]; three reviewed public artifacts recorded as Downloaded
Script    2dc94306ed7f9838a05be21ae2d6f44494446aaeded9ad978d3ebde5be0c04cf
```

### Dataset/publication result

```text
Processor catalog       112
Compatibility rows      336
Selections              112
Applicability rows      112
Selected candidate       62
No NPU driver            22
ReviewRequired           28
Generated public files   23
```

Accepted v1.0.0 Windows versus Linux `public/**` comparison:

```text
23/23 byte-identical
only-Windows 0
only-Linux 0
different 0
```

Compared with accepted 0.9.1-dev `public/**`, exactly 12 JSON files changed and all 11 generated Markdown files remained byte-identical. No source-data `schemaVersion` changed.

The Windows Validate stage reported privacy/dataset/JSON/Markdown PASS. The Windows acquisition inventory independently demonstrates the final fresh-reacquisition boundary that the Linux environment could not satisfy.

## Publication audit focus

Generated `public/**` must be regenerated from reviewed source/generator logic and must not be hand-edited.

Review at minimum:

- source-script SHA binding;
- public file set vs manifest;
- per-file length/SHA-256;
- `HandEdited=false`;
- schema validity;
- cross-dataset referential consistency;
- deterministic canonical JSON;
- public Markdown LF/no-BOM;
- decoded-value privacy checks;
- private/runtime/vendor payload exclusion.

## Companion collector audit surface

Collector source:

```text
tools/Collect-AmdNpuHardwareIdentityEvidence.ps1
version 1.3.0
```

The collector is read-only and private-evidence oriented. It may use read-only `xrt-smi --version`/`examine`; it must not automatically run `validate`, `configure`, AMD installer programs, or quicktest inference.

Important review boundary:

- older Z2 Extreme runtime evidence is valid research input;
- collector v1.3.0 parser and fifteen-test hardware-independent self-test pass;
- the NPU-positive gate is dependency-blocked until production build-script redevelopment and separately authorized Server driver application are complete;
- custom/self-signed Server driver evidence does not require public-376 hash equality;
- therefore do not describe v1.3.0 itself as fully real-device-qualified until that single positive run and all JSON/manifest/ZIP integrity gates are reviewed.

No further collector source correction is currently identified. The minimum
remaining evidence is one exact-v1.3.0 NPU-positive observation, but it is
deferred and must not be requested before production build-script redevelopment,
review and separately authorized Server driver application. Do not request
duplicate Client or Server no-NPU runs. Review
must keep collector observation, driver deployment, workload success and stable
promotion as four distinct claims.

## What is intentionally unresolved

Do not treat the following as defects merely because they are unresolved:

- STXA versus STXB on the Z2 Extreme;
- Gorgon Point recommendation without stronger published support evidence;
- Gorgon Halo exact Windows NPU identity/support relation;
- Windows Server real NPU workload proof until the planned positive execution is reviewed.

The intended safe result is `ReviewRequired` or explicit runtime-proof=false until evidence exists.

## Release decision after review

The main toolkit source is the final version string 1.0.0 and has completed the intended Windows fresh-acquisition, Windows/Linux runtime qualification, and cross-runtime determinism checks. Audit #4 is the remaining independent release-readiness gate. Any accepted code/data change before release requires affected v1.0.0 qualification evidence to be regenerated from the changed exact script hash before Audit #4 acceptance.

## Audit report #2 remediation status

| Finding | v1.0.0 status |
|---|---|
| A-01 partial-stage dependency fail-open | Fixed; negative controls return `BLOCKED` / exit 2 |
| A-02 NPU public `.gitattributes` rule | Closed repository-side; the v1.0.0 toolkit commit candidate intentionally excludes `.gitattributes` per Audit #3 integration guidance |
| A-03 thin source schema/version coverage | Closed for release candidate: 12/12 source schemas and 12/12 explicit version contracts |

The 0.9.0-dev and 0.9.1-dev Windows evidence remain historical evidence only for their exact predecessor script hashes. Final release qualification now uses fresh Evidence produced by the actual v1.0.0 script; predecessor Evidence is not being renamed or carried forward as release qualification.
