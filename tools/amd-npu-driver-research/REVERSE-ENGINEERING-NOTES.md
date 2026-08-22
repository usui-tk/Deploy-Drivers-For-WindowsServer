# AMD NPU Driver Reverse-Engineering Notes

This document records the high-value technical findings behind the machine-readable NPU research data and the design constraints that should feed back into `Deploy-AMDNpuDriverOnWindowsServer.ps1`.

It is intentionally evidence-oriented. Vendor publication, artifact bytes, static disassembly, upstream Linux semantics, toolkit analysis, and observed Windows runtime evidence are kept separate.

The rev35 no-NPU Client failure added two implementation findings. First, a
clean Windows PowerShell 5.1 process cannot be assumed to have loaded the .NET
Framework `System.Security` assembly; `SignedCms` initialization must use a
complete assembly identity rather than depend on load order. Second, a caller-
supplied HardwareID is a fixture, not proof of the local host. Version 1.3.1-dev
therefore derives normal selection input from local `Win32_PnPEntity` evidence
and treats manual identity input as an explicit offline/test override.

The subsequent 1.3.1-dev no-NPU run passed both stages and returned
`NoNpuDriverRequired`, but review exposed an evidence-plane distinction: writing
a runtime JSON under `inventory/**` does not by itself place that JSON in the
Evidence ZIP. The NPU snapshot adapter must explicitly select every required
private runtime artifact before the generic manifest/finalizer runs. 1.3.2-dev
therefore treats the snapshot allowlist as an executable contract and persists
the `SignedCms` result separately from the human-readable stage summary.

The first detailed NPU-equipped snapshot exposed a Windows CIM serialization
edge case rather than a selection error. `Win32_PnPEntity.ConfigManagerErrorCode`
arrived as an enum whose name was written as the invalid unquoted token
`CM_PROB_NONE`. The manifest correctly hashed those bytes, demonstrating that
byte integrity and JSON validity are separate acceptance properties. 1.3.3-dev
therefore JSON-quotes enums, records this field as a string, executes an enum
round-trip self-test on every Test stage, and parses the two generated hardware
runtime JSON files before HardwareIdentity may pass.

## 1. Scope and safety

No AMD installer executable was run as part of package reverse engineering.

Reviewed AMD ZIP/EXE/SYS/INF/CAT contents were treated as immutable artifacts. Static 7-Zip extraction, text/INF parsing, PE/static string/disassembly inspection, and hash comparison were used.

Runtime evidence discussed here came from a separately collected Windows client positive-control system and is explicitly labeled as such.

### 1.1 Final selection boundary

The reverse-engineering evidence establishes more NPU detail than Windows driver
selection requires. Firmware device revision, Linux AIE topology, XRT labels,
CPUID and CPU/NPU combination data remain useful for diagnostics and research, but
they are not selection inputs.

The reviewed machine authority is `data/hardware-driver-selection.json`:

```text
complete PnP HardwareID/CompatibleID set for one NPU instance
  + reviewed INF model
  + target Windows build selector
  -> 376 / NoNpuDriverRequired / ReviewRequired
```

376 is the reviewed current AMD production-family track. 280 remains a research line
and is never selected or used as an automatic fallback by the current source.
AMD's live `latest` Ryzen AI Software 1.8.0 page checked on 2026-08-21 labels
376 as production for the reviewed five families. The two packages do not
expose proven mutually exclusive hardware lanes. CPU/NPU mapping artifacts
remain human-audit references only.

## 2. Reviewed artifact identities

| Artifact/component | SHA-256 |
|---|---|
| `NPU_RAI1.5_280_WHQL.zip` | `a278a2c92cdc47e0da4cab2cbdb5347a127eee67311927578f4e151618446ce4` |
| `NPU_RAI_280_WHQL.zip` | `803afe1e2d75b717f60a368453306ccbd4877cdd936b6531b946b95109a22144` |
| `NPU_RAI_376_WHQL.zip` | `aa836cbfcad5d0782c79b58f197aa50624af37e7cb8311c5f94d85b0dc3ccaad` |
| private `NPU_RAI1.6.1_314_WHQL.zip` | `023caa295d3b2fe4befccdba84db5867abb6428a5e057ac1acdbda03853cf0ac` |
| Ryzen AI 1.5 280 `npu_sw_installer.exe` | `70259d1d182d7e9413cfb3cb8608bcba16f8142c6aee96fac2df2feb99366016` |
| later 280 / 376 `npu_sw_installer.exe` | `96dc03e574e9dfb2c45543833d8a66d5bcecb9af48e9beac07ea72cccf3ce755` |
| 280 `kipudrv.inf` | `36f5b8c4274add4d886943ad2036c206132c85b3d2fbfb576c629439e2002b81` |
| 376 `kipudrv.inf` | `c2a448340a9e802faa81b7c03fda0009d52cbfe86be5e915134dac39ab9c8008` |
| 280 `ipustack.sys` | `e5d77c30128e02149a3c88bb66d16302d5569ff7030e859bfb73eada46953a4e` |
| 376 `ipustack.sys` | `24f8c7220b86ccb8246845c3dd25f55be4e64b2fac1aab1fbac1e1f8226d4a42` |
| later 280 `kipudrv.cat` | `68c2580e0b3887c0a4541da6c799c669953d062afc0cb93d508f67546254be3f` |
| 376 `kipudrv.cat` | `8c905237327bce2e029e5bd57a8cd0a4949dd62ec17f198ca29f31c0c3df2b2f` |

Artifact filename/version text alone is not sufficient identity. Every reviewed claim that depends on bytes is exact-SHA scoped.

## 3. Historical 1.5-280 versus later 280

This pair is useful because it separates installer/packaging evolution from the actual 280 driver payload.

Observed topology:

```text
historical 1.5-280 files  146
later 280 files           147
common files              146
common byte-identical     145
common changed              1
changed common file       npu_sw_installer.exe
later-only file            ryzen-ai-end-user-license-agreement-public.pdf
```

`kipudrv.inf` is byte-identical between the two 280 packages, as are the driver payload files represented by the reviewed comparison. The installer changed substantially enough to produce a different PE hash/size/section layout.

Lesson: a repeated INF `DriverVer` does not prove the whole AMD release artifact is identical.

## 4. INF findings

### 4.1 280 family

```text
DriverVer = 05/16/2025,32.00.0203.280
%ManufacturerName%=IpuMcdmDriver.Mfg,NTamd64.10.0...22000
PCI\VEN_1022&DEV_1502
PCI\VEN_1022&DEV_17F0
ServiceBinary = %13%\ipustack.sys
Include = machine.inf
Needs = PciD3ColdSupported.HW
```

### 4.2 314 private qualification artifact

Static qualification shows the same broad INF model family and build floor, with embedded:

```text
DriverVer = 10/10/2025,32.00.0203.314
PCI\VEN_1022&DEV_1502
PCI\VEN_1022&DEV_17F0
NTamd64.10.0...22000
```

The package also contains revision-specific assets such as `17F0_10`, `17F0_11`, and `17F0_20`. This is useful evolution evidence but does not make the restricted artifact eligible for public acquisition or recommendation.

### 4.3 376

```text
DriverVer = 04/04/2026,32.00.20101.3760
%ManufacturerName%=IpuMcdmDriver.Mfg,NTamd64.10.0...22000
PCI\VEN_1022&DEV_1502
PCI\VEN_1022&DEV_17F0
ServiceBinary = %13%\ipustack.sys
```

376 adds runner/XRT-oriented payloads such as:

```text
npu_mcdm_stack_prod/pyxrt.pyd
npu_mcdm_stack_prod/Runner/xrt_smi_phx.a
npu_mcdm_stack_prod/Runner/xrt_smi_strx.a
npu_mcdm_stack_prod/xclbinutil.exe
```

The reviewed INFs do not contain an explicit `KmdfLibraryVersion` or `UmdfLibraryVersion` directive.

### 4.4 Selection consequence

The current 280 and 376 INFs expose the same broad 1502/17F0 model set. Their INF
content therefore cannot prove mutually exclusive device lanes. Under the
user-adjudicated policy, a complete device-instance PnP identity matching the 376
INF and a target build satisfying `NTamd64.10.0...22000` resolves to the preferred
376 research track. No CPU, firmware or topology discriminator is added.

## 5. ProductType correction and Server build floor

A key early hypothesis was that the NPU driver might be blocked on Server by a ProductType=1 decoration, similar to common client-driver compatibility problems. The reviewed packages do not support that hypothesis.

The relevant selector is:

```text
NTamd64.10.0...22000
```

There is no explicit ProductType value in that decoration. Therefore:

- Server 2016/2019/2022 fail the reviewed published selector because their builds are below 22000;
- Server 2025 build 26100 passes the published INF build floor.

This distinction matters directly to the deployment project. A generic ProductType patch is not justified for Server 2025 merely because the package is a consumer NPU package.

## 6. Installer binary relationship

The later 280 and 376 packages contain the same installer bytes:

```text
96dc03e574e9dfb2c45543833d8a66d5bcecb9af48e9beac07ea72cccf3ce755
```

The Ryzen AI 1.5 280 installer is different:

```text
70259d1d182d7e9413cfb3cb8608bcba16f8142c6aee96fac2df2feb99366016
```

Static review of both exact hashes recovers the same relevant NPU platform matcher family and Windows route semantics. They are therefore modeled as separate exact hashes sharing a reviewed routing-semantic family, not as globally equivalent programs.

Recovered device matcher evidence includes:

```text
PCI\\VEN_1022&DEV_(1502|17F0)
```

No reviewed `REV_` term was found in that broad matcher. This only says that the recovered matcher is broad; it does not prove revision is never consulted elsewhere in the program/stack.

## 7. Recovered installer OS routing

Reviewed threshold constants/control flow establish:

```text
major == 10
build >= 26100                  -> MCDM
build >= 22621 and UBR >= 3527  -> MCDM
build >= 22621 and UBR < 3527   -> WDF/NULL
build >= 22000 and < 22621       -> WDF/NULL
lower build                      -> Windows 10 / WDF-NULL
```

Relevant strings reference:

```text
npu_mcdm_stack_prod\kipudrv.inf
npu_wdf_stack_prod\kipudrv\kipudrv.inf
```

All reviewed public ZIPs contain the MCDM path and omit the referenced WDF path.

This aligns structurally with AMD Ryzen AI documentation requiring Windows 11 build 22621.3527 for the current software stack, but the exact installer disassembly remains independent package evidence.

### Deployment meaning

For Server 2025, both the reviewed INF and reviewed installer route point toward MCDM.

For Server 2016/2019/2022, simply removing or changing an INF OS selector would not recreate the missing lower-build driver stack. That is a materially different reverse-engineering problem.

## 8. Broad hardware identities

AMD's `npu_check` research source and the reviewed installer establish two broad Windows NPU identities:

```text
PCI\VEN_1022&DEV_1502 -> AIE2
PCI\VEN_1022&DEV_17F0 -> AIE2P / NPU4 family
```

These are broad families, not sufficient exact-generation selectors for every modern CPU.

## 9. Identity namespaces: do not collapse them

The project encountered multiple values that look like “revision” or “version” but are not interchangeable.

| Evidence | Example | Namespace |
|---|---|---|
| PCI Hardware ID | `...&REV_10` | PCI revision byte |
| PCIe ExpressSpecVersion | `2` | PCIe property; **not** NPU generation revision |
| quicktest-style class | `STX` | AMD historical PCI-revision helper classification |
| XRT device | `NPU Strix` | runtime XRT label |
| XRT firmware | `1.1.2.64` | firmware version |
| firmware device revision | `1..9` | management-protocol generation refinement |

An earlier collector development step incorrectly treated `DEVPKEY_PciDevice_ExpressSpecVersion` as firmware revision evidence. Real Z2 Extreme evidence corrected this. The collector now preserves each layer separately.

## 10. AMD quicktest-style PCI revision evidence

Reviewed AMD-authored quicktest logic classified:

```text
DEV_1502 REV_00 -> PHX/HPT
DEV_17F0 REV_00 -> STX
DEV_17F0 REV_10 -> STX
DEV_17F0 REV_11 -> STX
DEV_17F0 REV_20 -> KRK
```

This remains useful as a historical/advisory evidence plane, but it is not a complete modern platform table and must not replace exact CPU SKU or firmware device revision.

The collector records this as `QuicktestStyleNpuClassification` rather than final hardware identity.

## 11. Linux amdxdna NPU4 refinement

Upstream `amdxdna` exposes a firmware-reported NPU4 device-revision table under the broad `17f0_10` firmware family:

| Revision symbol/value | Upstream VBNV label |
|---|---|
| STXA / 1 | `NPU Strix` |
| STXB / 2 | `NPU Strix` |
| KRK1 / 3 | `NPU Krackan 1` |
| KRK2 / 4 | `NPU Krackan 2` |
| HALO / 5 | `NPU Strix Halo` |
| GPT1 / 6 | `NPU Gorgon Point 1` |
| GPT2 / 7 | `NPU Gorgon Point 2` |
| GPT3 / 8 | `NPU Gorgon Point 3` |

The feature table enables `AIE2_GET_DEV_REVISION` from firmware 6.24 and all features for firmware major 7.

This is a stronger generation-refinement model than a broad PCI ID, but Windows applicability remains independently derived from Windows artifacts and AMD Windows publication evidence.

## 12. Windows 280 `ipustack.sys`

Reviewed 280 binary:

```text
SHA-256  e5d77c30128e02149a3c88bb66d16302d5569ff7030e859bfb73eada46953a4e
Version   32.00.0203.280
```

The reviewed display-selection path uses broad labels:

| Value | Label |
|---:|---|
| 0 | `NPU Phoenix` |
| 1 | `NPU Strix` |
| 2 | `NPU Strix` |
| 3 | `NPU Strix Halo` |
| 4 | `NPU Krackan` |
| other | `NPU` |

No reviewed second-stage 1..8 mapping equivalent to the 376 refinement was established for this exact 280 hash. A generic `0x117` comparison exists elsewhere, so the correct statement is deliberately narrow: the reviewed 280 display path does not prove the later fine-grained refinement behavior.

## 13. Windows 376 `ipustack.sys` firmware device-revision logic

Reviewed 376 binary:

```text
SHA-256  24f8c7220b86ccb8246845c3dd25f55be4e64b2fac1aab1fbac1e1f8226d4a42
Version   32.00.20101.3760
```

For broad platform types in the refined range, the binary calls a secondary management path, initializes the output value to 9, and maps the returned value:

| Value | Windows 376 label | Correlated generation |
|---:|---|---|
| 1 | `NPU Strix` | Strix A |
| 2 | `NPU Strix` | Strix B |
| 3 | `NPU Krackan` | Krackan 1 |
| 4 | `NPU Krackan2` | Krackan 2 |
| 5 | `NPU Strix Halo` | Strix Halo |
| 6 | `NPU GorgonPoint1` | Gorgon Point 1 |
| 7 | `NPU GorgonPoint2` | Gorgon Point 2 |
| 8 | `NPU GorgonPoint3` | Gorgon Point 3 |
| other | fallback | unresolved |

The same exact binary contains a dedicated `0x117` command primitive. The numeric ordering and unknown-default behavior strongly correlate with the upstream firmware device-revision model.

This is **StaticDisassemblyProven + upstream semantic correlation**. It is not runtime evidence by itself and not a published-support statement.

## 14. Additional future-looking binary labels

The reviewed 376 binary also contains broad labels for families such as:

```text
Medusa
Soundwave
Medusa PF/VF
Soundwave PF/VF
```

These are binary observations only. They are intentionally not promoted to exact processor catalog entries, NPU identities, or driver recommendations without independent product/publication evidence.

This is an important future-proofing lesson: a driver binary often knows about platforms beyond the set currently published as supported.

## 15. AMD 376 publication boundary and live-source verification correction

The reviewed AMD Ryzen AI Software 1.8.0 publication used by the current dataset states
that NPU driver `32.0.203.376` is production for:

```text
Phoenix
Hawk Point
Strix
Strix Halo
Krackan Point
```

AMD's live `latest` installation page checked on 2026-08-21 identifies Ryzen AI
Software `1.8.0` and labels `32.0.203.376` as production for the same families.
See `authored/NPU-LIVE-PUBLICATION-DRIFT-2026-08-21.md` for the correction of
REV65's stale search-index inference.

The 376 publication statement is a separate evidence plane from:

- the broad INF's `DEV_1502/17F0` match;
- the installer's broad 1502/17F0 matcher;
- the 376 binary's Gorgon Point recognition.

Therefore Gorgon Point remains `ReviewRequired` for the reviewed 376 recommendation set.

## 16. Version namespaces

The project has at least three useful version dimensions:

1. archive/research artifact identity (`filename + SHA-256`);
2. AMD-published driver label (for example `32.0.203.376`);
3. embedded INF/driver version (for example `32.00.20101.3760`).

They must not be normalized into one string.

The published label is useful for AMD Ryzen AI software compatibility statements. The embedded version and file hashes are useful for Windows PnP/component identity. SHA-256 remains the immutable artifact binding.

## 17. Exact-SKU processor catalog lesson

NPU availability cannot be inferred safely from a series name or apparent silicon similarity.

The strongest counterexample found in the reviewed handheld family is:

```text
AMD Ryzen AI Z2 Extreme -> AMD publishes Ryzen AI / NPU capability
AMD Ryzen Z2 Extreme    -> AMD publishes Ryzen AI not available
```

Closely related product naming/architecture therefore cannot replace exact-SKU evidence.

The 0.9.0-dev catalog uses exact AMD SKU tables/product pages and retains negative controls. Unknown names fail closed.

## 18. Ryzen AI Z2 Extreme client-runtime convergence

Reviewed private positive-control observations:

```text
CPU                 AMD Ryzen AI Z2 Extreme
Family/Model/Step   26 / 36 / 0
NPU                 PCI\VEN_1022&DEV_17F0&SUBSYS_20CF1043&REV_10
Class               ComputeAccelerator
Service             IpuMcdmDriver
Status              OK
Driver              32.0.20101.3760
XRT version         2.21.0
XRT device          NPU Strix
NPU firmware        1.1.2.64
```

Cross-source classification:

```text
PnP                 DEV_17F0 / REV_10
quicktest-style     STX
XRT                 NPU Strix
GPU INF hint        ati2mtag_Strix
```

The installed NPU INF, `ipustack.sys`, and `xrt-smi.exe` match the reviewed public 376 payload exactly.

This resolves the exact CPU's broad Strix relationship and proves that exact public 376 stack on that Windows client system.

It does **not** resolve STXA versus STXB because the collected sources did not expose the firmware device-revision value. It also does not prove Server runtime behavior.

## 19. XRT as a read-only identity plane

The NPU stack can expose `xrt-smi.exe`. The companion collector uses it only in read-only modes:

```text
xrt-smi --version
xrt-smi examine -f JSON -o <private path>
xrt-smi examine
```

It does not automatically run:

```text
xrt-smi validate
xrt-smi configure
quicktest inference
```

XRT is valuable because it can independently name the runtime NPU device and report firmware/version/state data. It remains a separate evidence plane; its firmware version is not the firmware device revision.

## 20. Gorgon Point and Gorgon Halo

### Gorgon Point

The project has three relevant facts:

1. AMD publishes exact Gorgon Point processors with NPU capability.
2. broad `DEV_17F0` / driver-binary logic is compatible with the NPU4 family and 376 recognizes Gorgon Point labels internally.
3. the reviewed AMD 376 production-family statement does not include Gorgon Point.

The correct result is `ReviewRequired`.

### Gorgon Halo

AMD publishes Ryzen AI Max PRO 400 Gorgon Halo SKUs with NPU capability, but the current reviewed source set does not yet establish the exact Windows NPU PCI identity and reviewed package support relation needed for automatic recommendation.

The correct result is also `ReviewRequired`.

These are examples of deliberate fail-closed completeness: the catalog may know a processor exists without claiming a deployable driver relation.

## 21. Windows Server implications

### Server 2025

Server 2025 build 26100 is structurally the strongest first runtime candidate because:

- it satisfies the reviewed INF build floor;
- the reviewed installer routes build 26100 to MCDM;
- the reviewed packages contain the MCDM INF/payload.

The next deployment-level question should be whether the original AMD WHQL package can install/start on supported hardware without any INF rewrite.

### Server 2016 / 2019 / 2022

These releases are below the reviewed INF build floor. The reviewed installer routes lower builds toward WDF/NULL logic, while the reviewed package corpus does not contain the referenced WDF driver path.

Therefore older Server support is not demonstrated by simply bypassing one selector. It may require a different historical payload/release or a deeper compatibility reconstruction.

## 22. Deployment-script design rules derived from the research

The later deployment implementation should treat these as design constraints:

1. **Exact CPU before inference.** Resolve an exact reviewed SKU; unknown CPU names stop automation.
2. **Expected NPU relation.** Verify that the actual NPU HWID is consistent with the reviewed processor relation.
3. **No broad 17F0 shortcut.** `DEV_17F0` alone does not identify one generation.
4. **Separate revisions.** PCI `REV_XX`, quicktest class, XRT firmware version, and firmware device revision remain separate.
5. **Published support is an independent gate.** INF or binary capability cannot replace it.
6. **Private artifacts cannot win selection.** The 314 package is qualification-only.
7. **Preserve version namespaces.** Do not rewrite `32.00.20101.3760` into `32.0.203.376` or vice versa.
8. **Preserve vendor hash identity.** Record original artifact SHA-256 before any transformation.
9. **Test Server 2025 unmodified first.** Do not apply a ProductType patch that the reviewed INF does not require unless runtime evidence shows another modification is necessary.
10. **Treat older Server separately.** Missing lower-build/WDF payload is a package-architecture issue, not just an INF-selection issue.
11. **Runtime proof is OS-specific.** Windows client success does not prove Windows Server success.
12. **Fail closed on future platforms.** Binary labels, new CPU names, or broad HWID matches become review inputs, not automatic deployment policy.

### Two-line research and possible one-product deployment

The public 280 and 376 lines remain useful research inputs. The reviewed and
live AMD Ryzen AI Software 1.8.0 evidence favors 376 for the recorded published
production families. Keeping both lines exposes package evolution, regressions and compatibility
boundaries; it does not mean both must remain production choices forever.

A future deployment/build workflow may use one product if the exact-SKU, hardware-identity, published-support, OS/package, and runtime gates consistently select it. That downstream convergence does not justify collapsing the research corpus or converting current evidence into a hard-coded 376-only assumption.

## 23. Remaining research questions

The major functional research model is complete, but these evidence questions remain intentionally open:

- direct STXA versus STXB observation on the Ryzen AI Z2 Extreme;
- stronger reviewed published/runtime support evidence for Gorgon Point before automatic recommendation;
- exact reviewed NPU identity/support relation for Gorgon Halo;
- Windows Server 2025 real NPU runtime behavior with the original AMD WHQL package;
- older Server feasibility given the absent lower-build WDF payload in the reviewed modern package corpus;
- collector v1.3.0 final real-device qualification for its compact local-PnP
  selection-input, structured runtime-driver observation and JSON/manifest/ZIP
  integrity gates. The planned built-driver Windows Server positive run may
  close this with one execution.

An unresolved research question is not a reason to invent a deployment result. `ReviewRequired` is the correct state until evidence improves.

## 24. Downstream build-script feedback contract

The production NPU build/sign/deployment path should use one reviewable
selection record per target host. That record should contain:

1. complete local NPU PnP enumeration status and the exact HardwareID/
   CompatibleID candidates;
2. the independently matched reviewed INF model for each candidate;
3. the selected package lane or the typed result `NoNpuDriverRequired` /
   `ReviewRequired`;
4. outer package, INF, catalog and driver-binary hashes without normalizing
   version namespaces;
5. published-support evidence separately from INF/binary capability evidence;
6. target build, as-published INF selection and exact-hash installer route;
7. any transformation delta and why unmodified-package behavior was
   insufficient;
8. regenerated catalog/signing identity and later target-host runtime results.

CPU SKU, marketing generation, PCI `REV_XX`, XRT firmware version and firmware
device revision are diagnostic/correlation fields, not substitutes for the
reviewed local PnP-to-INF boundary. Package `280` and `376` must not be globally
ranked. Server 2025 should test the reviewed unmodified WHQL path before a
ProductType rewrite is introduced. The accepted no-NPU-safe Windows Server
smoke does not close the deferred NPU-equipped, built/self-signed-driver
positive case.
