# AMD NPU Driver Research — Development Handover (1.3.3 canonical-JSON enum correction)

> **Historical handover snapshot.** This file documents the transition into
> `1.3.3-dev`; it is not the current coordinated-package handover. Use
> `README.md`, `SPEC.md`, `TESTING.md` and the umbrella package-management
> handover for current status. The `Preferred 376` field below agrees with the
> AMD Ryzen AI Software 1.8.0 installation page checked on 2026-08-21, but it
> remains research guidance rather than deployment authorization.

## Purpose

This is the retained engineering handover for the canonical-JSON enum
correction. Historical implementation chronology is kept in `CHANGELOG.md`;
detailed technical findings are in `REVERSE-ENGINEERING-NOTES.md`.

## Current post-1.0 finalization state

```text
Version       1.3.3-dev
Selection     automatic local Windows PnP identity + reviewed INF + local build
CPU input     Not used
Firmware data Not required
Preferred     376
280 fallback  Disabled
Client gate  negative and positive hardware-selection Evidence accepted
Server gate  no-NPU negative control accepted on PowerShell 7.6.5 Core
```

`data/hardware-driver-selection.json` is the current machine authority. The
processor catalog, CPU/NPU workbook, applicability output and rev34 742-row map
candidate are retained as research/human-audit history and are not runtime
selection authority. The accepted v1.0.0 qualification below remains historical
evidence for that exact source; it is not silently reused for 1.3.3-dev.

## Historical v1.0.0 release-qualification baseline

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

The companion collector under `tools/` has its own independent utility version
lineage and is currently 1.3.0. It emits a compact local-PnP selection-input
observation, fails closed on incomplete enumeration, verifies JSON/manifest/ZIP
integrity, and supports a future Windows Server positive observation of a built
or self-signed installed NPU driver. Its parser and hardware-independent
self-test pass; one naturally occurring NPU-positive run remains before the
collector itself is called real-device-qualified.

That remaining collector gate is dependency-blocked. The user cannot perform it
until production NPU driver build-script redevelopment is complete and a Server
driver is later built/applied under separate authorization. It is not the next
task and does not reopen the accepted main-runner gates.

## Current completion boundary and next work

- Main-runner selection implementation: complete for the present contract.
- Accepted main-runner real-machine gates: Client no-NPU, Client NPU-positive,
  and Server 2025 no-NPU. Do not repeat them.
- Collector 1.3.0 implementation: complete; parser and 15/15 self-tests PASS.
- Collector 1.3.0 qualification: one current-source NPU-positive run remains.
  Status is `DeferredDependencyBlocked`; production build-script redevelopment,
  review and separately authorized Server application must occur first. The
  eventual Server run replaces, rather than supplements, a Client rerun.
- Server driver build/application, INF transformation, signing and deployment:
  separate work requiring explicit authorization.
- Server application/workload proof: separate from collector observation and
  required only if a future claim needs it.
- Independent audit and stable promotion: separate release decision.

No immediate collector execution should be requested. Main-runner audit or
promotion planning may continue if the collector remains explicitly described
as static/synthetic-qualified rather than real-device-qualified.

No CPU SKU, CPU-by-NPU map, Linux firmware/topology parity, firmware
device-revision or automatic 280 fallback work is required to close the current
Windows driver-selection specification.

## Historical v1.0.0 functional state

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
11. Current selection automatically enumerates local NPU PnP identity per device instance; CPU/NPU combinations are not consulted.
12. Generated `public/**` is never hand-edited.
13. 376 is the preferred research track after INF/build matching; 280 is retained for research with no automatic selection or fallback.
14. Firmware device revision and Linux AIE topology are diagnostic evidence, not Windows driver-track prerequisites.

## Documentation responsibility map

- `README.md` — project/operator overview plus deployment feedback.
- `SPEC.md` — normative behavior and recommendation/fail-closed contract.
- `TESTING.md` — release gates and actual v1.0.0 qualification evidence.
- `REVERSE-ENGINEERING-NOTES.md` — detailed package/installer/binary/hardware findings.
- `SOURCES.md` — public/upstream/runtime provenance.
- `PUBLICATION-POLICY.md` — repository publication boundary.
- `ARCHITECTURE-PARITY.md` — shared Chipset/Graphics research-runner architecture.
- `tools/**` — companion hardware evidence collector.

## Completed 1.3.3 Client finalization and remaining boundary

1. The v1.3.2-dev no-NPU Client Evidence archive is accepted; no repeat negative-control run is required.
2. The v1.3.2-dev NPU-equipped result is retained as functional proof but not archive closure because its detailed local-PnP JSON is invalid.
3. Local parser, enum round-trip, `Test,HardwareIdentity`, JSON, manifest and archive gates for exact v1.3.3-dev passed.
4. The minimum-sufficient v1.3.3-dev Client command in `TESTING.md` section 28 passed on Windows PowerShell 5.1.
5. Independent review accepted 59/59 JSON documents and 69/69 manifest rows; the positive Client Evidence gate is closed.
6. Stable-promotion and external/Claude review planning may proceed without another NPU machine run for this correction.
7. The Client/Server hold remains. Windows Server execution, installation and deployment are not authorized automatically.

The separately authorized Windows Server 2025 no-NPU Gate B is now accepted.
It confirms the PowerShell 7.6.5 Server host, automatic PnP, fail-closed
no-device decision and Evidence paths. It does not reopen the completed Client
gates, require a Windows PowerShell 5.1 Server rerun for current external-review
planning, or authorize an NPU-equipped Server run. A future release claim that
specifically promises Windows PowerShell 5.1 on Server requires separately
scoped evidence.

## Open research questions, not automatic blockers

These remain unresolved by design:

- STXA versus STXB on the observed Z2 Extreme (diagnostic only, not a selection blocker);
- stronger AMD published/runtime support evidence for Gorgon Point (research only, not CPU-selection input);
- exact reviewed Windows NPU identity/support relation for Gorgon Halo (research only, not CPU-selection input);
- Windows Server 2025 real NPU runtime behavior;
- older Server feasibility given the absent modern WDF payload path.

The toolkit already handles selection safely from PnP/INF identity and keeps the
remaining items in their proper research/runtime evidence planes. Do not invent a
value simply to eliminate an unresolved state.

## Independent audit #2 remediation

- A-01: fixed; missing prerequisites in partial stage selection now produce `BLOCKED` rather than vacuous PASS/raw exceptions.
- A-02: repository-root `.gitattributes` must contain `tools/amd-npu-driver-research/public/** -text`; Audit #3 assigns that integration to the repository side, so the v1.0.0 toolkit commit-candidate ZIP SHALL exclude `.gitattributes`.
- A-03: closed for v1.0.0 with 12/12 source-data schemas; 1.3.3-dev retains 13/13 reviewed source-data contracts and generated local-selection/Test-stage evidence schemas.

The v1.0.0 qualification boundary has been satisfied for the main toolkit: the exact v1.0.0 script was used for Windows fresh acquisition and Windows/Linux qualification. Any accepted post-qualification code/data change requires affected v1.0.0 evidence to be regenerated before release acceptance.
