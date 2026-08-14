# AMD NPU Driver Artifact Research

- Artifact: `NPU_RAI_376_WHQL.zip`
- SHA-256: `aa836cbfcad5d0782c79b58f197aa50624af37e7cb8311c5f94d85b0dc3ccaad`
- Files: 102
- Driver version(s): 32.00.20101.3760
- Hardware ID(s): PCI\VEN_1022&DEV_1502, PCI\VEN_1022&DEV_17F0
- Safety: static-only; AMD executables were not executed.

## INF analysis

### `npu_mcdm_stack_prod/kipudrv.inf`
- SHA-256: `c2a448340a9e802faa81b7c03fda0009d52cbfe86be5e915134dac39ab9c8008`
- Class: `ComputeAccelerator`
- DriverVer: `04/04/2026,32.00.20101.3760`
- Catalog: `kipudrv.cat`
- Explicit ProductType assignment observed: **False**

| TargetOSVersion | Server | Build | Static selector result |
|---|---:|---:|---|
| `NTamd64.10.0...22000` | Windows Server 2016 | 14393 | RejectedBuildFloor |
| `NTamd64.10.0...22000` | Windows Server 2019 | 17763 | RejectedBuildFloor |
| `NTamd64.10.0...22000` | Windows Server 2022 | 20348 | RejectedBuildFloor |
| `NTamd64.10.0...22000` | Windows Server 2025 | 26100 | Candidate |

> Static selector projection is not runtime installation proof. Installer policy, signatures, dependencies, firmware, and hardware still require separate evidence.

## AMD published compatibility evidence

- Rule status: **ExactArtifactMatched**
- Published driver label: `32.0.203.376`
- Published supported codenames: Phoenix, Hawk Point, Strix Point, Strix Halo, Krackan Point
- Evidence binding: **AmdProductionDriverPublished**
> Published driver label and embedded INF `DriverVer` are separate evidence dimensions and are never normalized into one value.

## Combined Windows Server static assessment

| Server | INF selector | Installer route | Route payload present | Assessment |
|---|---|---|---|---|
| Windows Server 2016 | RejectedBuildFloor | Windows10/WDF-NULL | False | **NotApplicableAsPublished** |
| Windows Server 2019 | RejectedBuildFloor | Windows10/WDF-NULL | False | **NotApplicableAsPublished** |
| Windows Server 2022 | RejectedBuildFloor | Windows10/WDF-NULL | False | **NotApplicableAsPublished** |
| Windows Server 2025 | Candidate | MCDM | True | **StaticCandidateAsPublished** |

> `StaticCandidateAsPublished` is deliberately weaker than installation support. It must be confirmed on real hardware and a clean Windows Server host.

## Installer analysis

- Path: `npu_sw_installer.exe`
- SHA-256: `96dc03e574e9dfb2c45543833d8a66d5bcecb9af48e9beac07ea72cccf3ce755`
- Contract: **ExactHashMatched**
- Exact-hash static contract OS gates:
  - `major != 10` → **Other/unknown path** (High)
  - `major == 10 and build >= 26100` → **Install MCDM driver** (High)
  - `major == 10 and 22621 <= build < 26100 and UBR >= 3527` → **Install MCDM driver** (High)
  - `major == 10 and 22621 <= build < 26100 and UBR < 3527` → **Install WDF/NULL driver** (High)
  - `major == 10 and 22000 <= build < 22621` → **Install WDF/NULL driver** (High)
  - `major == 10 and build < 22000` → **Windows 10 path / WDF-NULL path** (Medium)
- Device matcher: `PCI\\VEN_1022&DEV_(1502|17F0)`
- Revision discriminator observed: **False**

## Driver binary identity analysis

- Path: `npu_mcdm_stack_prod/ipustack.sys`
- SHA-256: `24f8c7220b86ccb8246845c3dd25f55be4e64b2fac1aab1fbac1e1f8226d4a42`
- Contract: **ExactHashMatched**
- Observed file version: `32.00.20101.3760`
- Recovered identity semantic: `amd-npu-ipustack-firmware-revision-v2`
- Firmware device-revision refinement observed: **True**
- Firmware message opcode correlation: `0x117`
- Unknown/default revision value: `9`

| Revision | Symbol | Windows label | Codename |
|---:|---|---|---|
| 1 | `STXA` | NPU Strix | Strix Point |
| 2 | `STXB` | NPU Strix | Strix Point |
| 3 | `KRK1` | NPU Krackan | Krackan Point |
| 4 | `KRK2` | NPU Krackan2 | Krackan Point |
| 5 | `HALO` | NPU Strix Halo | Strix Halo |
| 6 | `GPT1` | NPU GorgonPoint1 | Gorgon Point |
| 7 | `GPT2` | NPU GorgonPoint2 | Gorgon Point |
| 8 | `GPT3` | NPU GorgonPoint3 | Gorgon Point |
> Firmware-reported device revision is a separate identity layer from PCI `REV_XX`.
