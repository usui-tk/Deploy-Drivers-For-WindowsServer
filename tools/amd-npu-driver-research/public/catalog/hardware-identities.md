# AMD NPU Hardware Identity Catalog

- Completeness: **ReviewedBroadIdentityRulesWithObservedRuntimeBindings**
- Unknown hardware policy: **ReviewRequired**
- Firmware device revision values are not PCI `REV_XX` values.

| Identity | PCI device | AMD label | Broad codenames |
|---|---|---|---|
| `amd-npu-aie2-1502` | `1022:1502` | AIE2 | Phoenix, Hawk Point |
| `amd-npu-aie2p-17f0` | `1022:17F0` | AIE2P | Strix Point, Krackan Point, Strix Halo, Gorgon Point |

## Observed runtime binding: `amd-npu-aie2p-17f0`

| Processor | PCI REV | XRT device | Firmware | Exact 376 stack |
|---|---|---|---|---|
| AMD Ryzen AI Z2 Extreme | `10` | NPU Strix | `1.1.2.64` | True |

## Firmware revision refinement: `amd-npu-aie2p-17f0`

| Value | Symbol | Linux label | Codename |
|---:|---|---|---|
| 1 | `STXA` | NPU Strix | Strix Point |
| 2 | `STXB` | NPU Strix | Strix Point |
| 3 | `KRK1` | NPU Krackan 1 | Krackan Point |
| 4 | `KRK2` | NPU Krackan 2 | Krackan Point |
| 5 | `HALO` | NPU Strix Halo | Strix Halo |
| 6 | `GPT1` | NPU Gorgon Point 1 | Gorgon Point |
| 7 | `GPT2` | NPU Gorgon Point 2 | Gorgon Point |
| 8 | `GPT3` | NPU Gorgon Point 3 | Gorgon Point |
