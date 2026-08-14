# AMD NPU Driver Research — Development Handover (v1.0.0 release qualification)

## Purpose

This is the current engineering handover for the AMD NPU research toolkit. Historical implementation chronology is kept in `CHANGELOG.md`; detailed technical findings are in `REVERSE-ENGINEERING-NOTES.md`.

## Current release-qualification baseline

Main toolkit:

```text
Version       1.0.0
Release state v1.0.0 release candidate; main-toolkit qualification complete; Audit #4 pending
Script SHA    2dc94306ed7f9838a05be21ae2d6f44494446aaeded9ad978d3ebde5be0c04cf
```

Version policy:

- the 0.x development line ended only after Audit #3 APPROVE;
- `1.0.0` is now intentionally the final stable version string and is not an interim/dev identifier;
- any change that would invalidate the current release candidate requires requalification of the affected v1.0.0 evidence before release.

The companion collector under `tools/` has its own independent utility version lineage and is currently 1.2.1.

## Functional state

The planned feature expansion and Audit #2 remediation are complete. Audit #3 approved 0.9.1-dev; the source is now intentionally at v1.0.0, and the main toolkit has completed its v1.0.0 Windows/Linux release-candidate qualification. Audit #4 remains pending.

Current reviewed/generated scope:

```text
Exact processor SKUs     112
Published NPU capable     90
Negative/no-NPU controls  22
Compatibility rows       336
Processor selections     112
Applicability rows       112
ReviewRequired            28
Generated public files    23
```

The main new relation is:

```text
exact CPU SKU
  -> NPU availability / codename
  -> broad NPU identity
  -> reviewed driver release capability
  -> AMD published family support
  -> INF/installer/binary static evidence
  -> Windows Server static applicability
  -> recommendation or ReviewRequired
```

Private driver 314 knowledge is static/private qualification only and cannot become an automatic acquisition or recommendation target.

## Qualification completed

### Linux / PowerShell 7 — v1.0.0

Evidence:

```text
AmdNpuDriverResearchEvidence_20260814-055908_Linux_v1.0.0-Linux-canonical-corpus-qualification.zip
9ff11c1ee761274fa9190102cdf908f073b45651b4cc627fdc05b080a2e3fdeb
```

Result:

```text
PowerShell 7.6.4 / Core
13/13 stages PASS
ExitCode 0
canonical reviewed public corpus
336 matrix rows
112 selections
112 applicability rows
28 ReviewRequired
ScriptSha256 2dc94306ed7f9838a05be21ae2d6f44494446aaeded9ad978d3ebde5be0c04cf
```

The Linux preparation environment could not complete live AMD CDN acquisition. This run therefore qualifies the exact v1.0.0 logic/publication path against the canonical reviewed public corpus.

### Windows / Windows PowerShell 5.1 — v1.0.0 fresh acquisition

User Evidence:

```text
AmdNpuDriverResearchEvidence_20260814-060553_Windows.zip
0fa97dfbdd4c86ca09bc003c1fb8e9cbf485e4b16f731cdac11fa656eba79392
```

Generated public ZIP:

```text
public(20260814-060739).zip
d415e2d7019bf234dc67b3eb072239f38f16ce692f6ad2ad895cf601d03ec91e
```

Result:

```text
PowerShell 5.1.26100.9168 / Desktop
13/13 stages PASS
ExitCode 0
PackagePath=[]
three reviewed public artifacts recorded as Downloaded
same reviewed artifact SHA-256 values
same 336 / 112 / 112 / 28 dataset counts
ScriptSha256 2dc94306ed7f9838a05be21ae2d6f44494446aaeded9ad978d3ebde5be0c04cf
```

### Cross-runtime publication — v1.0.0

Accepted Windows and Linux `public/**` trees:

```text
23 files vs 23 files
only-Windows 0
only-Linux 0
different 0
byte-identical 23/23
```

Compared with accepted 0.9.1-dev output, the v1.0.0 version/hash cascade changes 12 JSON files while all 11 generated Markdown files remain byte-identical. Dataset counts and source-data schema versions are unchanged.

## High-value findings that must survive future work

1. The reviewed NPU INF uses `NTamd64.10.0...22000`; it is not an explicit ProductType=1 selector.
2. Server 2016/2019/2022 are below that reviewed build floor; Server 2025 build 26100 is an as-published static candidate.
3. The reviewed installer has its own 26100 / 22621 / UBR 3527 / 22000 routing logic.
4. The modern reviewed packages contain the MCDM stack but omit the installer-referenced lower-build WDF path.
5. Broad NPU identities are `DEV_1502` and `DEV_17F0`; `DEV_17F0` is not a complete generation selector.
6. PCI `REV_XX`, XRT firmware version, and firmware device revision are different namespaces.
7. 376 `ipustack.sys` has fine-grained Strix/Krackan/Strix Halo/Gorgon Point firmware-device-revision recognition, but binary recognition does not equal AMD published support.
8. Current reviewed AMD 376 production-family support is Phoenix/Hawk Point/Strix/Strix Halo/Krackan Point; Gorgon Point therefore remains `ReviewRequired`.
9. Gorgon Halo remains `ReviewRequired` until exact reviewed NPU identity/artifact support is established.
10. Ryzen AI Z2 Extreme has exact public-376 **Windows client** runtime evidence; this does not prove Windows Server runtime behavior.
11. Unknown CPU/NPU combinations fail closed.
12. Generated `public/**` is never hand-edited.

## Documentation responsibility map

- `README.md` — project/operator overview plus deployment feedback.
- `SPEC.md` — normative behavior and recommendation/fail-closed contract.
- `TESTING.md` — release gates and actual v1.0.0 qualification evidence.
- `REVERSE-ENGINEERING-NOTES.md` — detailed package/installer/binary/hardware findings.
- `SOURCES.md` — public/upstream/runtime provenance.
- `PUBLICATION-POLICY.md` — repository publication boundary.
- `ARCHITECTURE-PARITY.md` — shared Chipset/Graphics research-runner architecture.
- `tools/**` — companion hardware evidence collector.

## Remaining release workflow

1. Build the final v1.0.0 commit-candidate ZIP excluding repository-root `.gitattributes` as instructed by Audit #3.
2. Build the final v1.0.0 audit/evidence ZIP containing both v1.0.0 qualification runs, Windows-generated `public/**`, vendor corpus, hardware evidence, prior audit documents, regression logs, and verification manifests.
3. Submit those artifacts plus the v1.0.0 Claude handover for Audit #4.
4. If Audit #4 requests any accepted code/data change, regenerate all affected v1.0.0 publication and qualification evidence from the changed exact script hash before release acceptance.
5. Re-run collector v1.2.1 on the Ryzen AI Z2 Extreme only if the release will claim that exact collector revision is real-device-qualified; otherwise retain the current disclaimer.

## Open research questions, not automatic blockers

These remain unresolved by design:

- STXA versus STXB on the observed Z2 Extreme;
- stronger AMD published/runtime support evidence for Gorgon Point;
- exact reviewed Windows NPU identity/support relation for Gorgon Halo;
- Windows Server 2025 real NPU runtime behavior;
- older Server feasibility given the absent modern WDF payload path.

The toolkit already handles these safely through `ReviewRequired` or explicit lack of Server runtime proof. Do not invent a value simply to eliminate an unresolved state.

## Independent audit #2 remediation

- A-01: fixed; missing prerequisites in partial stage selection now produce `BLOCKED` rather than vacuous PASS/raw exceptions.
- A-02: repository-root `.gitattributes` must contain `tools/amd-npu-driver-research/public/** -text`; Audit #3 assigns that integration to the repository side, so the v1.0.0 toolkit commit-candidate ZIP SHALL exclude `.gitattributes`.
- A-03: closed for the release candidate with 12/12 source-data schemas plus centralized source `schemaVersion` guards.

The v1.0.0 qualification boundary has been satisfied for the main toolkit: the exact v1.0.0 script was used for Windows fresh acquisition and Windows/Linux qualification. Any accepted post-qualification code/data change requires affected v1.0.0 evidence to be regenerated before release acceptance.
