# AMD NPU Driver Artifact Research

- Artifact: `NPU_RAI_280_WHQL.zip`
- SHA-256: `803afe1e2d75b717f60a368453306ccbd4877cdd936b6531b946b95109a22144`
- Files: 147
- Driver version(s): 32.00.0203.280
- Hardware ID(s): PCI\VEN_1022&DEV_1502, PCI\VEN_1022&DEV_17F0
- Safety: static-only; AMD executables were not executed.

## INF analysis

### `npu_mcdm_stack_prod/kipudrv.inf`
- SHA-256: `36f5b8c4274add4d886943ad2036c206132c85b3d2fbfb576c629439e2002b81`
- Class: `ComputeAccelerator`
- DriverVer: `05/16/2025,32.00.0203.280`
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
- Published driver label: `32.0.203.280`
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
- SHA-256: `e5d77c30128e02149a3c88bb66d16302d5569ff7030e859bfb73eada46953a4e`
- Contract: **ExactHashMatched**
- Observed file version: `32.00.0203.280`
- Recovered identity semantic: `amd-npu-ipustack-broad-platform-v1`
- Firmware device-revision refinement observed: **False**
> Firmware-reported device revision is a separate identity layer from PCI `REV_XX`.
