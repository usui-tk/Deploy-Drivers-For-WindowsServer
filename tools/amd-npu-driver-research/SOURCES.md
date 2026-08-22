# AMD NPU Research Sources

This file records upstream/public references and reviewed evidence inputs used by the toolkit. It does not replace immutable payload hashes or private Evidence archives.

Source classes are intentionally separated so later deployment work can distinguish vendor publication, Microsoft selector semantics, upstream architecture context, exact package evidence, and observed runtime evidence.

## 1. AMD Ryzen AI — live and frozen Windows publication evidence

- Version-pinned Ryzen AI 1.8 installation instructions: https://ryzenai.docs.amd.com/en/1.8/inst.html
- Moving latest installation alias: https://ryzenai.docs.amd.com/en/latest/inst.html
- Release notes / supported configurations: https://ryzenai.docs.amd.com/en/latest/relnotes.html
- Linux installation material: https://ryzenai.docs.amd.com/en/latest/linux.html
- RyzenAI-SW repository: https://github.com/amd/RyzenAI-SW
- AMD `npu_check` utility source: https://github.com/amd/RyzenAI-SW/blob/main/utilities/npu_check/npu_util.cpp

The AMD Ryzen AI 1.8 version-pinned installation page and its `latest` alias
were rechecked on 2026-08-21. The version-pinned URL is the frozen citation;
`latest` is retained only for live-drift checks because caches may serve older
content under the same alias.
It identifies Ryzen AI Software `1.8.0` and states:

- Windows 11 build `>= 22621.3527`;
- NPU driver `32.0.203.280` or newer as the minimum driver requirement;
- `32.0.203.376` as the production driver for Phoenix, Hawk Point, Strix,
  Strix Halo and Krackan Point.

REV65 incorrectly inferred `1.7.1`/`280` from stale search-index material instead
of the supplied authoritative page. The correction is recorded in
`authored/NPU-LIVE-PUBLICATION-DRIFT-2026-08-21.md`. The reviewed `376`
production-family statement agrees with current live AMD authority; it remains
research guidance and does not by itself authorize deployment.

Vendor publication facts remain separate from the
embedded INF `DriverVer` namespace.

For driver-track selection, the reviewed artifact INF is the machine applicability
authority. AMD product/CPU pages and Linux architecture sources remain research and
diagnostic provenance; they are not CPU/NPU mapping inputs to the Windows resolver.

## 2. Reviewed public NPU artifacts

- Historical Ryzen AI 1.5 driver 280: https://download.amd.com/opendownload/RyzenAI/Driver/NPU_RAI1.5_280_WHQL.zip
- Later driver 280: https://download.amd.com/opendownload/RyzenAI/Driver/NPU_RAI_280_WHQL.zip
- Driver 376: https://download.amd.com/opendownload/RyzenAI/Driver/NPU_RAI_376_WHQL.zip

Reviewed SHA-256 values:

```text
NPU_RAI1.5_280_WHQL.zip
a278a2c92cdc47e0da4cab2cbdb5347a127eee67311927578f4e151618446ce4

NPU_RAI_280_WHQL.zip
803afe1e2d75b717f60a368453306ccbd4877cdd936b6531b946b95109a22144

NPU_RAI_376_WHQL.zip
aa836cbfcad5d0782c79b58f197aa50624af37e7cb8311c5f94d85b0dc3ccaad
```

`data/published-driver-artifacts.json` is the machine-readable reviewed acquisition catalog.

A direct AMD URL discovered at runtime is acquisition provenance only until artifact bytes and semantics are reviewed.

## 3. Private qualification artifact

Reviewed manual/private artifact:

```text
NPU_RAI1.6.1_314_WHQL.zip
023caa295d3b2fe4befccdba84db5867abb6428a5e057ac1acdbda03853cf0ac
```

The artifact was supplied from an authenticated/restricted source. No unauthenticated source URL is published or inferred. It is used only for static evolution/qualification comparison and is not recommendation eligible.

## 4. Microsoft INF / Windows Server semantics

- INF Manufacturer section / TargetOSVersion: https://learn.microsoft.com/en-us/windows-hardware/drivers/install/inf-manufacturer-section
- Windows Server release/build information: https://learn.microsoft.com/en-us/windows/release-health/windows-server-release-info

The TargetOSVersion grammar is the normative reference for parsing:

```text
NTamd64.10.0...22000
```

Empty ProductType/SuiteMask values remain empty. They are not normalized into a workstation-only selector.

The resolver consumes the complete Windows HardwareID/CompatibleID set for one
enumerated NPU instance. PCI `SUBSYS` and `REV` are retained when present, but no
more-specific selector is invented when the reviewed INF model is only VEN/DEV.

## 5. AMD CPU/NPU exact-SKU evidence

### Phoenix / Ryzen 7040

- Ryzen 9 7940HS: https://www.amd.com/en/products/processors/laptop/ryzen/7000-series/amd-ryzen-9-7940hs.html
- Ryzen 7 7840U: https://www.amd.com/en/products/processors/laptop/ryzen/7000-series/amd-ryzen-7-7840u.html
- Ryzen AI 1.2 exact PHX/HPT configurations: https://ryzenai.docs.amd.com/en/1.2/inst.html
- Ryzen PRO 7040 exact table: https://www.amd.com/en/newsroom/press-releases/2023-6-13-amd-expands-world-class-commercial-portfolio-with-.html

### Hawk Point / Ryzen 8040 / Ryzen 200

- Ryzen 7 8845HS: https://www.amd.com/en/products/processors/laptop/ryzen/8000-series/amd-ryzen-7-8845hs.html
- Ryzen 5 8645HS: https://www.amd.com/en/products/processors/laptop/ryzen/8000-series/amd-ryzen-5-8645hs.html
- Ryzen 8040 launch exact NPU table: https://www.amd.com/en/newsroom/press-releases/2023-12-6-amd-extends-mobile-pc-leadership-with-amd-ryzen-8.html
- Ryzen PRO 8040 / PRO 8000 exact tables: https://www.amd.com/en/newsroom/press-releases/2024-4-16-amd-expands-commercial-ai-pc-portfolio-to-deliver-.html
- Ryzen 8000G launch: https://www.amd.com/en/newsroom/press-releases/2024-1-8-amd-reveals-next-gen-desktop-processors-for-extrem.html
- Ryzen 200/PRO 200 exact table: https://www.amd.com/en/newsroom/press-releases/2025-1-6-amd-announces-expanded-consumer-and-commercial-ai-.html

### Strix / Krackan / Strix Halo — Ryzen AI 300 family

- Ryzen AI 300 launch: https://www.amd.com/en/newsroom/press-releases/2024-6-2-amd-unveils-next-gen-zen-5-ryzen-processors-to-p.html
- Ryzen AI PRO 300 launch: https://www.amd.com/en/newsroom/press-releases/2024-10-10-amd-launches-new-ryzen-ai-pro-300-series-processo.html
- CES 2025 AI 300 / AI Max 300 tables: https://www.amd.com/en/newsroom/press-releases/2025-1-6-amd-announces-expanded-consumer-and-commercial-ai-.html
- Ryzen AI 9 HX 375: https://www.amd.com/en/products/processors/laptop/ryzen/ai-300-series/amd-ryzen-ai-9-hx-375.html
- Ryzen AI 7 345: https://www.amd.com/en/products/processors/laptop/ryzen/ai-300-series/amd-ryzen-ai-7-345.html
- Ryzen AI 5 330: https://www.amd.com/en/products/processors/laptop/ryzen/ai-300-series/amd-ryzen-ai-5-330.html

### Gorgon Point / Gorgon Halo — Ryzen AI 400 family

- Ryzen AI 400 / PRO 400 mobile exact table: https://www.amd.com/en/newsroom/press-releases/2026-1-5-amd-expands-ai-leadership-across-client-graphics-.html
- Ryzen AI 400 / PRO 400 desktop exact table: https://www.amd.com/en/newsroom/press-releases/2026-3-2-amd-gives-consumers-and-businesses-more-ai-pc-opti.html
- Ryzen AI Max PRO 400 exact table: https://www.amd.com/en/blogs/2026/amd-powers-next-generation-agent-computers-with-new-ryzen-ai-hal.html

The presence of an exact CPU/NPU capability in these product sources does not by itself establish a reviewed 376 driver recommendation.

## 6. Ryzen Z handheld exact-SKU controls

- Ryzen Z overview: https://www.amd.com/en/products/processors/handhelds/ryzen-z-series.html
- Ryzen AI Z2 Extreme: https://www.amd.com/en/products/processors/handhelds/ryzen-z-series/z2-series/ai-z2-extreme.html
- Ryzen Z2 Extreme: https://www.amd.com/en/products/processors/handhelds/ryzen-z-series/z2-series/z2-extreme.html
- Ryzen Z2: https://www.amd.com/en/products/processors/handhelds/ryzen-z-series/z2-series/z2.html
- Ryzen Z2 Go: https://www.amd.com/en/products/processors/handhelds/ryzen-z-series/z2-series/z2-go.html
- Ryzen Z2 A: https://www.amd.com/en/products/processors/handhelds/ryzen-z-series/z2-series/z2-a.html
- Ryzen Z1 Extreme: https://www.amd.com/en/products/processors/handhelds/ryzen-z-series/z1-series/z1-extreme.html
- Ryzen Z1: https://www.amd.com/en/products/processors/handhelds/ryzen-z-series/z1-series/z1.html

These sources are important negative controls: similar handheld naming/architecture is not enough to infer NPU presence.

## 7. AMD quicktest / historical Windows identity hint

- Historical Ryzen AI installation/quicktest context: https://ryzenai.docs.amd.com/en/1.7/inst.html

Reviewed AMD-authored quicktest source evidence produced the PCI revision hint mapping retained in `data/hardware-identities.json`:

```text
1502 REV_00 -> PHX/HPT
17F0 REV_00/10/11 -> STX
17F0 REV_20 -> KRK
```

This mapping is advisory/historical and not treated as the complete modern identity model.

## 8. Linux kernel / AMD XDNA architecture context

- AMD XDNA kernel documentation: https://docs.kernel.org/accel/amdxdna/amdnpu.html
- NPU4 registers/revision table: https://github.com/torvalds/linux/blob/master/drivers/accel/amdxdna/npu4_regs.c
- amdxdna message/protocol sources: https://github.com/torvalds/linux/tree/master/drivers/accel/amdxdna

The upstream NPU4 table maps firmware-reported revision symbols to Strix, Krackan, Strix Halo, and Gorgon Point labels and binds the NPU4 firmware path under `amdnpu/17f0_10/`.

The feature table exposes `AIE2_GET_DEV_REVISION` from firmware 6.24 and all features for firmware major 7.

Linux evidence is used for architectural/protocol correlation. It does not replace Windows package/publication/runtime evidence.

## 9. Exact Windows binary evidence

`data/known-installer-contracts.json` and `data/known-driver-binary-contracts.json` are source records for reviewed exact-hash static findings.

Important exact-hash observations include:

- historical 1.5-280 and later 280/376 installer hashes are different/same as documented in `REVERSE-ENGINEERING-NOTES.md`;
- both reviewed installer hashes recover the same relevant 26100 / 22621 / UBR 3527 / 22000 routing family;
- reviewed 376 `ipustack.sys` contains the finer device-revision label mapping and a `0x117` command primitive.

These are payload observations/static analysis, not AMD published Windows APIs.

## 10. Reviewed private runtime evidence

Reviewed generalized runtime record source archive:

```text
amd-npu-hardware-evidence-20260813-220709.zip
SHA-256 f10c70ef8a6d1621f36bd1e0ce1e91b915af3a684e7754cff26fb99308d4258e
```

The repository does not commit the raw host archive. Generalized reviewed facts are promoted into `data/observed-runtime-evidence.json`.

The evidence binds Ryzen AI Z2 Extreme to:

```text
DEV_17F0 / PCI REV_10
quicktest-style STX
XRT NPU Strix
XRT firmware 1.1.2.64
exact reviewed public-376 client stack
```

It does not establish Windows Server runtime proof or STXA/STXB.

## 11. Project references

The authored English evaluation workbook consolidating the reviewed catalog and driver-line assessment is indexed at `authored/AMD-CPU-NPU-EVALUATION-MATRIX.md`. Its source URLs, evidence tiers, exact artifact hashes, and row-level provenance are retained inside the workbook.

- Project root: https://github.com/usui-tk/Deploy-Drivers-For-WindowsServer
- NPU deployment script under research: https://github.com/usui-tk/Deploy-Drivers-For-WindowsServer/blob/main/Deploy-AMDNpuDriverOnWindowsServer.ps1
- Chipset research predecessor: https://github.com/usui-tk/Deploy-Drivers-For-WindowsServer/tree/main/tools/amd-chipset-driver-research
- Graphics research predecessor: https://github.com/usui-tk/Deploy-Drivers-For-WindowsServer/tree/main/tools/amd-graphics-driver-research

The predecessor tools are architecture/style references for research runner, evidence, publication, deterministic output, and documentation separation. NPU-specific applicability conclusions remain based on NPU evidence.
