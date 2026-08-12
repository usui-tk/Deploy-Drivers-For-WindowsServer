# AMD Chipset Driver - Windows Server static applicability

This report is generated from per-INF semantic analysis. It distinguishes AMD-published applicability from the analytical ProductType=1 -> ProductType=3 server projection used by the deployment project. It does **not** prove runtime compatibility.

Releases are listed newest first. The identifier column preserves the exact Models-section identifier from the source INF; `Identifier type` distinguishes bus/root PnP hardware IDs from class-specific IDs and software component IDs.

## AMD Chipset Software 8.07.16.1035

| INF | Device | Device identifier | Identifier type | Install section | WS2016 | WS2019 | WS2022 | WS2025 | WDF |
|---|---|---|---|---|---|---|---|---|---|
| `d3_Data1.cab_f8f372fbfc6d\amd3dvcache.inf` | AMD 3D V-Cache Performance Optimizer | `ACPI\AMDI0101` | ACPI-enumerated PnP hardware ID | `Amd3dvcache_Device` | No(Build) | No(Build) | Native | Native | KMDF 1.15 |
| `d3_Data1.cab_f8f372fbfc6d\amdappcompat.inf` | AMD Application Compatibility Database | `ACPI\AMDI0204` | ACPI-enumerated PnP hardware ID | `AmdAppCompat_Device` | No(Build) | Native | Native | Native | KMDF 1.15 |
| `d3_Data1.cab_f8f372fbfc6d\amdas4.inf` | AmdAS4 Device | `ACPI\AMDI0050` | ACPI-enumerated PnP hardware ID | `AmdAS4` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_f8f372fbfc6d\amdas4.inf` | AmdAS4 Device | `ACPI\ASD0001` | ACPI-enumerated PnP hardware ID | `AmdAS4` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_f8f372fbfc6d\amdcir.inf` | AMD CIR Driver | `*AMDC001` | Generic PnP hardware ID | `AMDCIR64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_f8f372fbfc6d\amdcir.inf` | AMD CIR Driver | `*AMDC002` | Generic PnP hardware ID | `AMDCIR64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_f8f372fbfc6d\amdcir.inf` | AMD CIR Driver | `*AMDC003` | Generic PnP hardware ID | `AMDCIR64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_f8f372fbfc6d\amdgpio2.inf` | AMD GPIO Controller | `ACPI\AMD0030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | No(Build) | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_f8f372fbfc6d\amdgpio2.inf` | AMD GPIO Controller | `ACPI\AMDI0030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | No(Build) | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_f8f372fbfc6d\amdgpio2.inf` | AMD GPIO Controller | `ACPI\AMDI0031` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | No(Build) | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_f8f372fbfc6d\amdgpio2.inf` | AMD GPIO Controller | `ACPI\GPIO0010` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | No(Build) | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_f8f372fbfc6d\amdgpio3.inf` | AMD GPIO Controller | `ACPI\AMDF030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `d3_Data1.cab_f8f372fbfc6d\amdgpio3.inf` | AMD GPIO Controller | `ACPI\AMDIF030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `d3_Data1.cab_f8f372fbfc6d\amdgpio3.inf` | AMD GPIO Controller | `ACPI\AMDIF031` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `d3_Data1.cab_f8f372fbfc6d\amdhsmpdriver.inf` | AMD Host System Management Port | `ACPI\AMDI0097` | ACPI-enumerated PnP hardware ID | `AmdHsmpDriver_Device` | No(Build) | No(Build) | Native | Native | NotDeclared |
| `d3_Data1.cab_f8f372fbfc6d\amdi2c.inf` | AMD I2C Controller | `ACPI\AMD0010` | ACPI-enumerated PnP hardware ID | `amdi2c_Device` | No(Build) | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_f8f372fbfc6d\amdi2c.inf` | AMD I2C Controller | `ACPI\AMDI0010` | ACPI-enumerated PnP hardware ID | `amdi2c_Device` | No(Build) | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_f8f372fbfc6d\amdinterface.inf` | AMD PCI | `PCI\VEN_1002&DEV_145A` | PCI-enumerated PnP hardware ID | `AMDPCI64` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `d3_Data1.cab_f8f372fbfc6d\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_1116` | PCI-enumerated PnP hardware ID | `AMDPCI64` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `d3_Data1.cab_f8f372fbfc6d\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_1117` | PCI-enumerated PnP hardware ID | `AMDPCI64` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `d3_Data1.cab_f8f372fbfc6d\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_1136` | PCI-enumerated PnP hardware ID | `AMDPCI64` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `d3_Data1.cab_f8f372fbfc6d\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_1137` | PCI-enumerated PnP hardware ID | `AMDPCI64` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `d3_Data1.cab_f8f372fbfc6d\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_1151` | PCI-enumerated PnP hardware ID | `AMDPCI64` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `d3_Data1.cab_f8f372fbfc6d\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_1176` | PCI-enumerated PnP hardware ID | `AMDPCI64` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `d3_Data1.cab_f8f372fbfc6d\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_11B0` | PCI-enumerated PnP hardware ID | `AMDPCI64` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `d3_Data1.cab_f8f372fbfc6d\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_14AC` | PCI-enumerated PnP hardware ID | `AMDPCI64` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `d3_Data1.cab_f8f372fbfc6d\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_14DC` | PCI-enumerated PnP hardware ID | `AMDPCI64` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `d3_Data1.cab_f8f372fbfc6d\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_14DE` | PCI-enumerated PnP hardware ID | `AMDPCI64` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `d3_Data1.cab_f8f372fbfc6d\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_14EC` | PCI-enumerated PnP hardware ID | `AMDPCI64` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `d3_Data1.cab_f8f372fbfc6d\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_150D` | PCI-enumerated PnP hardware ID | `AMDPCI64` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `d3_Data1.cab_f8f372fbfc6d\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_1556` | PCI-enumerated PnP hardware ID | `AMDPCI64` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `d3_Data1.cab_f8f372fbfc6d\amdinterface.inf` | AMD PSP | `PCI\VEN_1022&DEV_1B16` | PCI-enumerated PnP hardware ID | `AMDPCI64` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `d3_Data1.cab_f8f372fbfc6d\amdinterface.inf` | AMD PSP | `PCI\VEN_1022&DEV_1B26` | PCI-enumerated PnP hardware ID | `AMDPCI64` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `d3_Data1.cab_f8f372fbfc6d\amdinterface.inf` | AMD SMBUS | `PCI\VEN_1022&DEV_790B` | PCI-enumerated PnP hardware ID | `AMDPCI64` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `d3_Data1.cab_f8f372fbfc6d\amdinterface.inf` | AMD SPI Controller | `ACPI\AMDI0062` | ACPI-enumerated PnP hardware ID | `AMDPCI64` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `d3_Data1.cab_f8f372fbfc6d\amdinterface.inf` | AMD WPS PCC Driver | `ACPI\PccIntAA` | ACPI-enumerated PnP hardware ID | `AMDPCI64` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `d3_Data1.cab_f8f372fbfc6d\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1002&DEV_5A23` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_f8f372fbfc6d\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_13E1` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_f8f372fbfc6d\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1419` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_f8f372fbfc6d\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1423` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_f8f372fbfc6d\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1437` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_f8f372fbfc6d\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1451` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_f8f372fbfc6d\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1481` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_f8f372fbfc6d\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1577` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_f8f372fbfc6d\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_164F` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_f8f372fbfc6d\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMD0004` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | No(Build) | Projection | Projection | Projection | NotDeclared |
| `d3_Data1.cab_f8f372fbfc6d\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMD0005` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | No(Build) | Projection | Projection | Projection | NotDeclared |
| `d3_Data1.cab_f8f372fbfc6d\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0005` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | No(Build) | Projection | Projection | Projection | NotDeclared |
| `d3_Data1.cab_f8f372fbfc6d\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0006` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | No(Build) | Projection | Projection | Projection | NotDeclared |
| `d3_Data1.cab_f8f372fbfc6d\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0007` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | No(Build) | Projection | Projection | Projection | NotDeclared |
| `d3_Data1.cab_f8f372fbfc6d\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0008` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | No(Build) | Projection | Projection | Projection | NotDeclared |
| `d3_Data1.cab_f8f372fbfc6d\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0009` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | No(Build) | Projection | Projection | Projection | NotDeclared |
| `d3_Data1.cab_f8f372fbfc6d\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI000A` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install.AMDI000A` | No(Build) | Projection | Projection | Projection | NotDeclared |
| `d3_Data1.cab_f8f372fbfc6d\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI000B` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | No(Build) | Projection | Projection | Projection | NotDeclared |
| `d3_Data1.cab_f8f372fbfc6d\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI000C` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | No(Build) | Projection | Projection | Projection | NotDeclared |
| `d3_Data1.cab_f8f372fbfc6d\amdoemprov.inf` | AMD Provisioning for OEM | `ACPI\AMDI0053` | ACPI-enumerated PnP hardware ID | `AMDPPMPF_DEV` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `d3_Data1.cab_f8f372fbfc6d\amdpcidev.inf` | AMD PCI | `PCI\VEN_1002&DEV_145A` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_f8f372fbfc6d\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_1455` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_f8f372fbfc6d\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_145A` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_f8f372fbfc6d\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_1485` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_f8f372fbfc6d\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_148A` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_f8f372fbfc6d\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_14DE` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_f8f372fbfc6d\amdpmf.inf` | AMD PMF | `ACPI\AMDI0102` | ACPI-enumerated PnP hardware ID | `AMDPMF_INSTALL.NTamd64.10.0...19041` | No(Build) | No(Build) | Native | Native | NotDeclared |
| `d3_Data1.cab_f8f372fbfc6d\amdpmf.inf` | AMD PMF | `ACPI\AMDI0103` | ACPI-enumerated PnP hardware ID | `AMDPMF_INSTALL.NTamd64.10.0...19041` | No(Build) | No(Build) | Native | Native | NotDeclared |
| `d3_Data1.cab_f8f372fbfc6d\amdpmf.inf` | AMD PMF | `ACPI\AMDI0105` | ACPI-enumerated PnP hardware ID | `AMDPMF_INSTALL.NTamd64.10.0...19041` | No(Build) | No(Build) | Native | Native | NotDeclared |
| `d3_Data1.cab_f8f372fbfc6d\amdpmf.inf` | AMD PMF | `ACPI\AMDI0107` | ACPI-enumerated PnP hardware ID | `AMDPMF_INSTALL.NTamd64.10.0...19041` | No(Build) | No(Build) | Native | Native | NotDeclared |
| `d3_Data1.cab_f8f372fbfc6d\amdpmf.inf` | AMD PMF | `ACPI\AMDI0108` | ACPI-enumerated PnP hardware ID | `AMDPMF_INSTALL.NTamd64.10.0...19041` | No(Build) | No(Build) | Native | Native | NotDeclared |
| `d3_Data1.cab_f8f372fbfc6d\amdpmf.inf` | AMD PMF | `ACPI\AMDI0109` | ACPI-enumerated PnP hardware ID | `AMDPMF_INSTALL.NTamd64.10.0...19041` | No(Build) | No(Build) | Native | Native | NotDeclared |
| `d3_Data1.cab_f8f372fbfc6d\amdpmf.inf` | AMD PMF | `ACPI\AMDI0112` | ACPI-enumerated PnP hardware ID | `AMDPMF_INSTALL.NTamd64.10.0...19041` | No(Build) | No(Build) | Native | Native | NotDeclared |
| `d3_Data1.cab_f8f372fbfc6d\amdppkg.inf` | AMD Provisioning Packages | `ACPI\AMDI0052` | ACPI-enumerated PnP hardware ID | `InstallSection_Win10` | No(Build) | No(Build) | Native | No | NotDeclared |
| `d3_Data1.cab_f8f372fbfc6d\amdppkg.inf` | AMD Provisioning Packages | `ACPI\AMDI0052` | ACPI-enumerated PnP hardware ID | `InstallSection_Win11_22H2` | No(Build) | No(Build) | No | Native | NotDeclared |
| `d3_Data1.cab_f8f372fbfc6d\amdpsp.inf` | AMD PSP 10.0 Device | `PCI\VEN_1022&DEV_15DF` | PCI-enumerated PnP hardware ID | `amdpsp_Device_100` | Native | No | No | No | KMDF 1.13 |
| `d3_Data1.cab_f8f372fbfc6d\amdpsp.inf` | AMD PSP 10.0 Device | `PCI\VEN_1022&DEV_15DF` | PCI-enumerated PnP hardware ID | `amdpsp_Device_100_RS3` | No | Native | Native | Native | KMDF 1.13 |
| `d3_Data1.cab_f8f372fbfc6d\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_1134` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | No | No | No | KMDF 1.13 |
| `d3_Data1.cab_f8f372fbfc6d\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_1134` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110_RS3` | No | Native | Native | Native | KMDF 1.13 |
| `d3_Data1.cab_f8f372fbfc6d\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_115A` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110_RS3` | No | Native | Native | Native | KMDF 1.13 |
| `d3_Data1.cab_f8f372fbfc6d\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_115A` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | No | No | No | KMDF 1.13 |
| `d3_Data1.cab_f8f372fbfc6d\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_1486` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110_RS3` | No | Native | Native | Native | KMDF 1.13 |
| `d3_Data1.cab_f8f372fbfc6d\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_1486` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | No | No | No | KMDF 1.13 |
| `d3_Data1.cab_f8f372fbfc6d\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_14CA` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110_RS3` | No | Native | Native | Native | KMDF 1.13 |
| `d3_Data1.cab_f8f372fbfc6d\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_14CA` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | No | No | No | KMDF 1.13 |
| `d3_Data1.cab_f8f372fbfc6d\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_156E` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110_RS3` | No | Native | Native | Native | KMDF 1.13 |
| `d3_Data1.cab_f8f372fbfc6d\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_156E` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | No | No | No | KMDF 1.13 |
| `d3_Data1.cab_f8f372fbfc6d\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_15C7` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | No | No | No | KMDF 1.13 |
| `d3_Data1.cab_f8f372fbfc6d\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_15C7` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110_RS3` | No | Native | Native | Native | KMDF 1.13 |
| `d3_Data1.cab_f8f372fbfc6d\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_1649` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | No | No | No | KMDF 1.13 |
| `d3_Data1.cab_f8f372fbfc6d\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_1649` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110_RS3` | No | Native | Native | Native | KMDF 1.13 |
| `d3_Data1.cab_f8f372fbfc6d\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_17E0` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110_RS3` | No | Native | Native | Native | KMDF 1.13 |
| `d3_Data1.cab_f8f372fbfc6d\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_17E0` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | No | No | No | KMDF 1.13 |
| `d3_Data1.cab_f8f372fbfc6d\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_13EC` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | No | No | No | KMDF 1.13 |
| `d3_Data1.cab_f8f372fbfc6d\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_13EC` | PCI-enumerated PnP hardware ID | `amdpsp_Device_RS3` | No | Native | Native | Native | KMDF 1.13 |
| `d3_Data1.cab_f8f372fbfc6d\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_1456` | PCI-enumerated PnP hardware ID | `amdpsp_Device_RS3` | No | Native | Native | Native | KMDF 1.13 |
| `d3_Data1.cab_f8f372fbfc6d\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_1456` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | No | No | No | KMDF 1.13 |
| `d3_Data1.cab_f8f372fbfc6d\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_1537` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | No | No | No | KMDF 1.13 |
| `d3_Data1.cab_f8f372fbfc6d\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_1537` | PCI-enumerated PnP hardware ID | `amdpsp_Device_RS3` | No | Native | Native | Native | KMDF 1.13 |
| `d3_Data1.cab_f8f372fbfc6d\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_1578` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | No | No | No | KMDF 1.13 |
| `d3_Data1.cab_f8f372fbfc6d\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_1578` | PCI-enumerated PnP hardware ID | `amdpsp_Device_RS3` | No | Native | Native | Native | KMDF 1.13 |
| `d3_Data1.cab_f8f372fbfc6d\amdsfhkmdf.inf` | AMD Sensor Fusion Hub | `PCI\VEN_1022&DEV_15E4` | PCI-enumerated PnP hardware ID | `amdsfhkmdf_Device` | Native | Native | Native | Native | KMDF 1.15 |
| `d3_Data1.cab_f8f372fbfc6d\amdsfhkmdfi2c.inf` | AMD SFH KMDF I2C | `PCI\VEN_1022&DEV_15E6` | PCI-enumerated PnP hardware ID | `amdsfhkmdf_Device` | Native | Native | Native | Native | KMDF 1.15 |
| `d3_Data1.cab_f8f372fbfc6d\amdsfhspbi2c.inf` | AMD SFH I2C Controller | `ACPI\AMDI0011` | ACPI-enumerated PnP hardware ID | `amdsfhspbi2c_Device` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_f8f372fbfc6d\amdsfhumdf.inf` | AMD UMDF Sensor | `ACPI\AMDI0080` | ACPI-enumerated PnP hardware ID | `amdsfhumdf_Inst_Win10` | No(Build) | Native | Native | No | UMDF 2.15.0 |
| `d3_Data1.cab_f8f372fbfc6d\amdsfhumdf.inf` | AMD UMDF Sensor | `ACPI\AMDI0080` | ACPI-enumerated PnP hardware ID | `amdsfhumdf_Inst_Win11` | No(Build) | No | No | Native | UMDF 2.15.0 |
| `d3_Data1.cab_f8f372fbfc6d\amduart.inf` | AMD UART Controller | `ACPI\AMD0020` | ACPI-enumerated PnP hardware ID | `amduart_Inst` | No(Build) | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_f8f372fbfc6d\amduart.inf` | AMD UART Controller | `ACPI\AMDI0020` | ACPI-enumerated PnP hardware ID | `amduart_Inst` | No(Build) | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_f8f372fbfc6d\amduart.inf` | AMD UART Controller | `ACPI\AMDI0022` | ACPI-enumerated PnP hardware ID | `amduart_Inst` | No(Build) | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_f8f372fbfc6d\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_15C4` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `d3_Data1.cab_f8f372fbfc6d\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_15C5` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `d3_Data1.cab_f8f372fbfc6d\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_162E` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `d3_Data1.cab_f8f372fbfc6d\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_162F` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `d3_Data1.cab_f8f372fbfc6d\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_1668` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `d3_Data1.cab_f8f372fbfc6d\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_1669` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `d3_Data1.cab_f8f372fbfc6d\amdusb4net.inf` | AMD USB4NET | `{b85b7c50-6a01-11d2-b841-00c04fad5171}\AMDUSB4NET` | Device-class-specific ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_f8f372fbfc6d\amdusb4net.inf` | AMD USB4NET | `{b85b7c50-6a01-11d2-b841-00c04fad5171}\Usb4Net` | Device-class-specific ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_f8f372fbfc6d\amdusb4net.inf` | AMD USB4NET | `root\AMDUSB4NET_a` | Root-enumerated PnP hardware ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_f8f372fbfc6d\amdusb4net.inf` | AMD USB4NET | `root\AMDUSB4NET_b` | Root-enumerated PnP hardware ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_f8f372fbfc6d\amdusb4net.inf` | AMD USB4NET | `root\AMDUSB4NET_c` | Root-enumerated PnP hardware ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_f8f372fbfc6d\amdusb4net.inf` | AMD USB4NET | `root\AMDUSB4NET_d` | Root-enumerated PnP hardware ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_f8f372fbfc6d\amdusb4pcifilter.inf` | PCI Express Root Port | `PCI\VEN_1022&DEV_14CD&SUBSYS_14531022&REV_00` | PCI-enumerated PnP hardware ID | `amdusb4pcifilter` | Native | Native | Excluded | Excluded | NotDeclared |
| `d3_Data1.cab_f8f372fbfc6d\amdusb4pcifilter.inf` | PCI Express Root Port | `PCI\VEN_1022&DEV_14EF&SUBSYS_14531022&REV_00` | PCI-enumerated PnP hardware ID | `amdusb4pcifilter` | Native | Native | Excluded | Excluded | NotDeclared |
| `d3_Data1.cab_f8f372fbfc6d\amdusb4pcifilter.inf` | PCI Express Root Port | `PCI\VEN_1022&DEV_14EF&SUBSYS_14531022&REV_01` | PCI-enumerated PnP hardware ID | `amdusb4pcifilter` | Native | Native | Excluded | Excluded | NotDeclared |
| `d3_Data1.cab_f8f372fbfc6d\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15C0&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Excluded | Excluded | NotDeclared |
| `d3_Data1.cab_f8f372fbfc6d\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15C1&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Excluded | Excluded | NotDeclared |
| `d3_Data1.cab_f8f372fbfc6d\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15C2&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Excluded | Excluded | NotDeclared |
| `d3_Data1.cab_f8f372fbfc6d\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15C3&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Excluded | Excluded | NotDeclared |
| `d3_Data1.cab_f8f372fbfc6d\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15D6&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Excluded | Excluded | NotDeclared |
| `d3_Data1.cab_f8f372fbfc6d\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15D7&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Excluded | Excluded | NotDeclared |
| `d3_Data1.cab_f8f372fbfc6d\amdwirelessbutton.inf` | AMD Wireless Button Driver | `ACPI\AMDI0051` | ACPI-enumerated PnP hardware ID | `amdwirelessbutton_Device` | No(Build) | Native | Native | No | KMDF 1.15 |
| `d3_Data1.cab_f8f372fbfc6d\amdwirelessbutton.inf` | AMD Wireless Button Driver | `ACPI\AMDI0051` | ACPI-enumerated PnP hardware ID | `amdwirelessbutton_DeviceWin11` | No(Build) | No | No | Native | KMDF 1.15 |
| `d3_Data1.cab_f8f372fbfc6d\ams_mailboxdrv.inf` | AMS-MailBoxDrv | `ACPI\AMDI0090` | ACPI-enumerated PnP hardware ID | `AMS-MailBoxDrv_Device` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_f8f372fbfc6d\plutonnull.inf` | AMD NULL Driver for Microsoft Pluton Security Processor | `ACPI\MSFT0200` | ACPI-enumerated PnP hardware ID | `Null_Pluton_Device` | Native | Native | Native | Excluded | NotDeclared |
| `d3_Data1.cab_f8f372fbfc6d\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4353` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_f8f372fbfc6d\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4363` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_f8f372fbfc6d\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4372` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_f8f372fbfc6d\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4385` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_f8f372fbfc6d\smbusamd.inf` | AMD SMBus | `PCI\VEN_1022&DEV_780B` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_f8f372fbfc6d\smbusamd.inf` | AMD SMBus | `PCI\VEN_1022&DEV_790B` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_f8f372fbfc6d\usbfilter.inf` | AMD USB Filter Driver | `{36FC9E60-C465-11CF-8056-444553540000}\usbfilter` | Device-class-specific ID | `usbfilter` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_f8f372fbfc6d\zenpromnf.inf` | ZenProM S0i3 Network Filter | `ZenProMnf` | Network software component ID | `Install` | Native | Native | Native | Native | NotDeclared |

## AMD Chipset Software 8.05.04.516

| INF | Device | Device identifier | Identifier type | Install section | WS2016 | WS2019 | WS2022 | WS2025 | WDF |
|---|---|---|---|---|---|---|---|---|---|
| `d3_Data1.cab_22cefad0ba7d\amd3dvcache.inf` | AMD 3D V-Cache Performance Optimizer | `ACPI\AMDI0101` | ACPI-enumerated PnP hardware ID | `Amd3dvcache_Device` | No(Build) | No(Build) | Native | Native | KMDF 1.15 |
| `d3_Data1.cab_22cefad0ba7d\amdappcompat.inf` | AMD Application Compatibility Database | `ACPI\AMDI0204` | ACPI-enumerated PnP hardware ID | `AmdAppCompat_Device` | No(Build) | Native | Native | Native | KMDF 1.15 |
| `d3_Data1.cab_22cefad0ba7d\amdas4.inf` | AmdAS4 Device | `ACPI\AMDI0050` | ACPI-enumerated PnP hardware ID | `AmdAS4` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_22cefad0ba7d\amdas4.inf` | AmdAS4 Device | `ACPI\ASD0001` | ACPI-enumerated PnP hardware ID | `AmdAS4` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_22cefad0ba7d\amdcir.inf` | AMD CIR Driver | `*AMDC001` | Generic PnP hardware ID | `AMDCIR64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_22cefad0ba7d\amdcir.inf` | AMD CIR Driver | `*AMDC002` | Generic PnP hardware ID | `AMDCIR64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_22cefad0ba7d\amdcir.inf` | AMD CIR Driver | `*AMDC003` | Generic PnP hardware ID | `AMDCIR64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_22cefad0ba7d\amdgpio2.inf` | AMD GPIO Controller | `ACPI\AMD0030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | No(Build) | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_22cefad0ba7d\amdgpio2.inf` | AMD GPIO Controller | `ACPI\AMDI0030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | No(Build) | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_22cefad0ba7d\amdgpio2.inf` | AMD GPIO Controller | `ACPI\AMDI0031` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | No(Build) | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_22cefad0ba7d\amdgpio2.inf` | AMD GPIO Controller | `ACPI\GPIO0010` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | No(Build) | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_22cefad0ba7d\amdgpio3.inf` | AMD GPIO Controller | `ACPI\AMDF030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `d3_Data1.cab_22cefad0ba7d\amdgpio3.inf` | AMD GPIO Controller | `ACPI\AMDIF030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `d3_Data1.cab_22cefad0ba7d\amdgpio3.inf` | AMD GPIO Controller | `ACPI\AMDIF031` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `d3_Data1.cab_22cefad0ba7d\amdhsmpdriver.inf` | AMD Host System Management Port | `ACPI\AMDI0097` | ACPI-enumerated PnP hardware ID | `AmdHsmpDriver_Device` | No(Build) | No(Build) | Native | Native | NotDeclared |
| `d3_Data1.cab_22cefad0ba7d\amdi2c.inf` | AMD I2C Controller | `ACPI\AMD0010` | ACPI-enumerated PnP hardware ID | `amdi2c_Device` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_22cefad0ba7d\amdi2c.inf` | AMD I2C Controller | `ACPI\AMDI0010` | ACPI-enumerated PnP hardware ID | `amdi2c_Device` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_22cefad0ba7d\amdinterface.inf` | AMD PCI | `PCI\VEN_1002&DEV_145A` | PCI-enumerated PnP hardware ID | `AMDPCI64` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `d3_Data1.cab_22cefad0ba7d\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_1116` | PCI-enumerated PnP hardware ID | `AMDPCI64` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `d3_Data1.cab_22cefad0ba7d\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_1117` | PCI-enumerated PnP hardware ID | `AMDPCI64` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `d3_Data1.cab_22cefad0ba7d\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_1136` | PCI-enumerated PnP hardware ID | `AMDPCI64` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `d3_Data1.cab_22cefad0ba7d\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_1137` | PCI-enumerated PnP hardware ID | `AMDPCI64` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `d3_Data1.cab_22cefad0ba7d\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_1151` | PCI-enumerated PnP hardware ID | `AMDPCI64` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `d3_Data1.cab_22cefad0ba7d\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_14AC` | PCI-enumerated PnP hardware ID | `AMDPCI64` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `d3_Data1.cab_22cefad0ba7d\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_14DC` | PCI-enumerated PnP hardware ID | `AMDPCI64` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `d3_Data1.cab_22cefad0ba7d\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_14DE` | PCI-enumerated PnP hardware ID | `AMDPCI64` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `d3_Data1.cab_22cefad0ba7d\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_14EC` | PCI-enumerated PnP hardware ID | `AMDPCI64` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `d3_Data1.cab_22cefad0ba7d\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_150D` | PCI-enumerated PnP hardware ID | `AMDPCI64` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `d3_Data1.cab_22cefad0ba7d\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_1556` | PCI-enumerated PnP hardware ID | `AMDPCI64` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `d3_Data1.cab_22cefad0ba7d\amdinterface.inf` | AMD SMBUS | `PCI\VEN_1022&DEV_790B` | PCI-enumerated PnP hardware ID | `AMDPCI64` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `d3_Data1.cab_22cefad0ba7d\amdinterface.inf` | AMD SPI Controller | `ACPI\AMDI0062` | ACPI-enumerated PnP hardware ID | `AMDPCI64` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `d3_Data1.cab_22cefad0ba7d\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1002&DEV_5A23` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_22cefad0ba7d\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_13E1` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_22cefad0ba7d\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1419` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_22cefad0ba7d\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1423` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_22cefad0ba7d\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1437` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_22cefad0ba7d\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1451` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_22cefad0ba7d\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1481` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_22cefad0ba7d\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1577` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_22cefad0ba7d\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_164F` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_22cefad0ba7d\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMD0004` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | No(Build) | Projection | Projection | Projection | NotDeclared |
| `d3_Data1.cab_22cefad0ba7d\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMD0005` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | No(Build) | Projection | Projection | Projection | NotDeclared |
| `d3_Data1.cab_22cefad0ba7d\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0005` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | No(Build) | Projection | Projection | Projection | NotDeclared |
| `d3_Data1.cab_22cefad0ba7d\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0006` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | No(Build) | Projection | Projection | Projection | NotDeclared |
| `d3_Data1.cab_22cefad0ba7d\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0007` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | No(Build) | Projection | Projection | Projection | NotDeclared |
| `d3_Data1.cab_22cefad0ba7d\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0008` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | No(Build) | Projection | Projection | Projection | NotDeclared |
| `d3_Data1.cab_22cefad0ba7d\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0009` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | No(Build) | Projection | Projection | Projection | NotDeclared |
| `d3_Data1.cab_22cefad0ba7d\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI000A` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install.AMDI000A` | No(Build) | Projection | Projection | Projection | NotDeclared |
| `d3_Data1.cab_22cefad0ba7d\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI000B` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | No(Build) | Projection | Projection | Projection | NotDeclared |
| `d3_Data1.cab_22cefad0ba7d\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI000C` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | No(Build) | Projection | Projection | Projection | NotDeclared |
| `d3_Data1.cab_22cefad0ba7d\amdoemprov.inf` | AMD Provisioning for OEM | `ACPI\AMDI0053` | ACPI-enumerated PnP hardware ID | `AMDPPMPF_DEV` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `d3_Data1.cab_22cefad0ba7d\amdpcidev.inf` | AMD PCI | `PCI\VEN_1002&DEV_145A` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_22cefad0ba7d\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_1455` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_22cefad0ba7d\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_145A` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_22cefad0ba7d\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_1485` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_22cefad0ba7d\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_148A` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_22cefad0ba7d\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_14DE` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_22cefad0ba7d\amdpmf.inf` | AMD PMF | `ACPI\AMDI0100` | ACPI-enumerated PnP hardware ID | `AMDPMF_INSTALL.NTamd64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_22cefad0ba7d\amdpmf.inf` | AMD PMF | `ACPI\AMDI0102` | ACPI-enumerated PnP hardware ID | `AMDPMF_INSTALL.NTamd64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_22cefad0ba7d\amdppkg.inf` | AMD Provisioning Packages | `ACPI\AMDI0052` | ACPI-enumerated PnP hardware ID | `InstallSection_Win10` | No(Build) | No(Build) | Native | No | NotDeclared |
| `d3_Data1.cab_22cefad0ba7d\amdppkg.inf` | AMD Provisioning Packages | `ACPI\AMDI0052` | ACPI-enumerated PnP hardware ID | `InstallSection_Win11_22H2` | No(Build) | No(Build) | No | Native | NotDeclared |
| `d3_Data1.cab_22cefad0ba7d\amdpsp.inf` | AMD PSP 10.0 Device | `PCI\VEN_1022&DEV_15DF` | PCI-enumerated PnP hardware ID | `amdpsp_Device_100` | Native | No | No | No | KMDF 1.13 |
| `d3_Data1.cab_22cefad0ba7d\amdpsp.inf` | AMD PSP 10.0 Device | `PCI\VEN_1022&DEV_15DF` | PCI-enumerated PnP hardware ID | `amdpsp_Device_100_RS3` | No | Native | Native | Native | KMDF 1.13 |
| `d3_Data1.cab_22cefad0ba7d\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_1134` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | No | No | No | KMDF 1.13 |
| `d3_Data1.cab_22cefad0ba7d\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_1134` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110_RS3` | No | Native | Native | Native | KMDF 1.13 |
| `d3_Data1.cab_22cefad0ba7d\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_115A` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110_RS3` | No | Native | Native | Native | KMDF 1.13 |
| `d3_Data1.cab_22cefad0ba7d\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_115A` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | No | No | No | KMDF 1.13 |
| `d3_Data1.cab_22cefad0ba7d\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_1486` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110_RS3` | No | Native | Native | Native | KMDF 1.13 |
| `d3_Data1.cab_22cefad0ba7d\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_1486` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | No | No | No | KMDF 1.13 |
| `d3_Data1.cab_22cefad0ba7d\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_14CA` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110_RS3` | No | Native | Native | Native | KMDF 1.13 |
| `d3_Data1.cab_22cefad0ba7d\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_14CA` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | No | No | No | KMDF 1.13 |
| `d3_Data1.cab_22cefad0ba7d\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_156E` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110_RS3` | No | Native | Native | Native | KMDF 1.13 |
| `d3_Data1.cab_22cefad0ba7d\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_156E` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | No | No | No | KMDF 1.13 |
| `d3_Data1.cab_22cefad0ba7d\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_15C7` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | No | No | No | KMDF 1.13 |
| `d3_Data1.cab_22cefad0ba7d\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_15C7` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110_RS3` | No | Native | Native | Native | KMDF 1.13 |
| `d3_Data1.cab_22cefad0ba7d\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_1649` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | No | No | No | KMDF 1.13 |
| `d3_Data1.cab_22cefad0ba7d\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_1649` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110_RS3` | No | Native | Native | Native | KMDF 1.13 |
| `d3_Data1.cab_22cefad0ba7d\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_17E0` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110_RS3` | No | Native | Native | Native | KMDF 1.13 |
| `d3_Data1.cab_22cefad0ba7d\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_17E0` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | No | No | No | KMDF 1.13 |
| `d3_Data1.cab_22cefad0ba7d\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_13EC` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | No | No | No | KMDF 1.13 |
| `d3_Data1.cab_22cefad0ba7d\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_13EC` | PCI-enumerated PnP hardware ID | `amdpsp_Device_RS3` | No | Native | Native | Native | KMDF 1.13 |
| `d3_Data1.cab_22cefad0ba7d\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_1456` | PCI-enumerated PnP hardware ID | `amdpsp_Device_RS3` | No | Native | Native | Native | KMDF 1.13 |
| `d3_Data1.cab_22cefad0ba7d\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_1456` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | No | No | No | KMDF 1.13 |
| `d3_Data1.cab_22cefad0ba7d\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_1537` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | No | No | No | KMDF 1.13 |
| `d3_Data1.cab_22cefad0ba7d\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_1537` | PCI-enumerated PnP hardware ID | `amdpsp_Device_RS3` | No | Native | Native | Native | KMDF 1.13 |
| `d3_Data1.cab_22cefad0ba7d\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_1578` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | No | No | No | KMDF 1.13 |
| `d3_Data1.cab_22cefad0ba7d\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_1578` | PCI-enumerated PnP hardware ID | `amdpsp_Device_RS3` | No | Native | Native | Native | KMDF 1.13 |
| `d3_Data1.cab_22cefad0ba7d\amdsfhkmdf.inf` | AMD Sensor Fusion Hub | `PCI\VEN_1022&DEV_15E4` | PCI-enumerated PnP hardware ID | `amdsfhkmdf_Device` | Native | Native | Native | Native | KMDF 1.15 |
| `d3_Data1.cab_22cefad0ba7d\amdsfhkmdfi2c.inf` | AMD SFH KMDF I2C | `PCI\VEN_1022&DEV_15E6` | PCI-enumerated PnP hardware ID | `amdsfhkmdf_Device` | Native | Native | Native | Native | KMDF 1.15 |
| `d3_Data1.cab_22cefad0ba7d\amdsfhspbi2c.inf` | AMD SFH I2C Controller | `ACPI\AMDI0011` | ACPI-enumerated PnP hardware ID | `amdsfhspbi2c_Device` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_22cefad0ba7d\amdsfhumdf.inf` | AMD UMDF Sensor | `ACPI\AMDI0080` | ACPI-enumerated PnP hardware ID | `amdsfhumdf_Inst_Win10` | No(Build) | Native | Native | No | UMDF 2.15.0 |
| `d3_Data1.cab_22cefad0ba7d\amdsfhumdf.inf` | AMD UMDF Sensor | `ACPI\AMDI0080` | ACPI-enumerated PnP hardware ID | `amdsfhumdf_Inst_Win11` | No(Build) | No | No | Native | UMDF 2.15.0 |
| `d3_Data1.cab_22cefad0ba7d\amduart.inf` | AMD UART Controller | `ACPI\AMD0020` | ACPI-enumerated PnP hardware ID | `amduart_Inst` | No(Build) | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_22cefad0ba7d\amduart.inf` | AMD UART Controller | `ACPI\AMDI0020` | ACPI-enumerated PnP hardware ID | `amduart_Inst` | No(Build) | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_22cefad0ba7d\amduart.inf` | AMD UART Controller | `ACPI\AMDI0022` | ACPI-enumerated PnP hardware ID | `amduart_Inst` | No(Build) | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_22cefad0ba7d\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_15C4` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `d3_Data1.cab_22cefad0ba7d\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_15C5` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `d3_Data1.cab_22cefad0ba7d\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_162E` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `d3_Data1.cab_22cefad0ba7d\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_162F` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `d3_Data1.cab_22cefad0ba7d\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_1668` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `d3_Data1.cab_22cefad0ba7d\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_1669` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `d3_Data1.cab_22cefad0ba7d\amdusb4net.inf` | AMD USB4NET | `{b85b7c50-6a01-11d2-b841-00c04fad5171}\AMDUSB4NET` | Device-class-specific ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_22cefad0ba7d\amdusb4net.inf` | AMD USB4NET | `{b85b7c50-6a01-11d2-b841-00c04fad5171}\Usb4Net` | Device-class-specific ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_22cefad0ba7d\amdusb4net.inf` | AMD USB4NET | `root\AMDUSB4NET_a` | Root-enumerated PnP hardware ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_22cefad0ba7d\amdusb4net.inf` | AMD USB4NET | `root\AMDUSB4NET_b` | Root-enumerated PnP hardware ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_22cefad0ba7d\amdusb4net.inf` | AMD USB4NET | `root\AMDUSB4NET_c` | Root-enumerated PnP hardware ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_22cefad0ba7d\amdusb4net.inf` | AMD USB4NET | `root\AMDUSB4NET_d` | Root-enumerated PnP hardware ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_22cefad0ba7d\amdusb4pcifilter.inf` | PCI Express Root Port | `PCI\VEN_1022&DEV_14CD&SUBSYS_14531022&REV_00` | PCI-enumerated PnP hardware ID | `amdusb4pcifilter` | Native | Native | Excluded | Excluded | NotDeclared |
| `d3_Data1.cab_22cefad0ba7d\amdusb4pcifilter.inf` | PCI Express Root Port | `PCI\VEN_1022&DEV_14EF&SUBSYS_14531022&REV_00` | PCI-enumerated PnP hardware ID | `amdusb4pcifilter` | Native | Native | Excluded | Excluded | NotDeclared |
| `d3_Data1.cab_22cefad0ba7d\amdusb4pcifilter.inf` | PCI Express Root Port | `PCI\VEN_1022&DEV_14EF&SUBSYS_14531022&REV_01` | PCI-enumerated PnP hardware ID | `amdusb4pcifilter` | Native | Native | Excluded | Excluded | NotDeclared |
| `d3_Data1.cab_22cefad0ba7d\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15C0&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Excluded | Excluded | NotDeclared |
| `d3_Data1.cab_22cefad0ba7d\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15C1&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Excluded | Excluded | NotDeclared |
| `d3_Data1.cab_22cefad0ba7d\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15C2&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Excluded | Excluded | NotDeclared |
| `d3_Data1.cab_22cefad0ba7d\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15C3&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Excluded | Excluded | NotDeclared |
| `d3_Data1.cab_22cefad0ba7d\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15D6&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Excluded | Excluded | NotDeclared |
| `d3_Data1.cab_22cefad0ba7d\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15D7&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Excluded | Excluded | NotDeclared |
| `d3_Data1.cab_22cefad0ba7d\amdwirelessbutton.inf` | AMD Wireless Button Driver | `ACPI\AMDI0051` | ACPI-enumerated PnP hardware ID | `amdwirelessbutton_Device` | No(Build) | Native | Native | No | KMDF 1.15 |
| `d3_Data1.cab_22cefad0ba7d\amdwirelessbutton.inf` | AMD Wireless Button Driver | `ACPI\AMDI0051` | ACPI-enumerated PnP hardware ID | `amdwirelessbutton_DeviceWin11` | No(Build) | No | No | Native | KMDF 1.15 |
| `d3_Data1.cab_22cefad0ba7d\ams_mailboxdrv.inf` | AMS-MailBoxDrv | `ACPI\AMDI0090` | ACPI-enumerated PnP hardware ID | `AMS-MailBoxDrv_Device` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_22cefad0ba7d\plutonnull.inf` | AMD NULL Driver for Microsoft Pluton Security Processor | `ACPI\MSFT0200` | ACPI-enumerated PnP hardware ID | `Null_Pluton_Device` | Native | Native | Native | Excluded | NotDeclared |
| `d3_Data1.cab_22cefad0ba7d\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4353` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_22cefad0ba7d\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4363` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_22cefad0ba7d\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4372` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_22cefad0ba7d\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4385` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_22cefad0ba7d\smbusamd.inf` | AMD SMBus | `PCI\VEN_1022&DEV_780B` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_22cefad0ba7d\smbusamd.inf` | AMD SMBus | `PCI\VEN_1022&DEV_790B` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_22cefad0ba7d\usbfilter.inf` | AMD USB Filter Driver | `{36FC9E60-C465-11CF-8056-444553540000}\usbfilter` | Device-class-specific ID | `usbfilter` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_22cefad0ba7d\zenpromnf.inf` | ZenProM S0i3 Network Filter | `ZenProMnf` | Network software component ID | `Install` | Native | Native | Native | Native | NotDeclared |

## AMD Chipset Software 8.02.18.557

| INF | Device | Device identifier | Identifier type | Install section | WS2016 | WS2019 | WS2022 | WS2025 | WDF |
|---|---|---|---|---|---|---|---|---|---|
| `d3_Data1.cab_89c286305368\amd3dvcache.inf` | AMD 3D V-Cache Performance Optimizer | `ACPI\AMDI0101` | ACPI-enumerated PnP hardware ID | `Amd3dvcache_Device` | No(Build) | No(Build) | Native | Native | KMDF 1.15 |
| `d3_Data1.cab_89c286305368\amdappcompat.inf` | AMD Application Compatibility Database | `ACPI\AMDI0204` | ACPI-enumerated PnP hardware ID | `AmdAppCompat_Device` | No(Build) | Native | Native | Native | KMDF 1.15 |
| `d3_Data1.cab_89c286305368\amdas4.inf` | AmdAS4 Device | `ACPI\AMDI0050` | ACPI-enumerated PnP hardware ID | `AmdAS4` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_89c286305368\amdas4.inf` | AmdAS4 Device | `ACPI\ASD0001` | ACPI-enumerated PnP hardware ID | `AmdAS4` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_89c286305368\amdcir.inf` | AMD CIR Driver | `*AMDC001` | Generic PnP hardware ID | `AMDCIR64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_89c286305368\amdcir.inf` | AMD CIR Driver | `*AMDC002` | Generic PnP hardware ID | `AMDCIR64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_89c286305368\amdcir.inf` | AMD CIR Driver | `*AMDC003` | Generic PnP hardware ID | `AMDCIR64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_89c286305368\amdgpio2.inf` | AMD GPIO Controller | `ACPI\AMD0030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | No(Build) | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_89c286305368\amdgpio2.inf` | AMD GPIO Controller | `ACPI\AMDI0030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | No(Build) | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_89c286305368\amdgpio2.inf` | AMD GPIO Controller | `ACPI\AMDI0031` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | No(Build) | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_89c286305368\amdgpio2.inf` | AMD GPIO Controller | `ACPI\GPIO0010` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | No(Build) | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_89c286305368\amdgpio3.inf` | AMD GPIO Controller | `ACPI\AMDF030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `d3_Data1.cab_89c286305368\amdgpio3.inf` | AMD GPIO Controller | `ACPI\AMDIF030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `d3_Data1.cab_89c286305368\amdgpio3.inf` | AMD GPIO Controller | `ACPI\AMDIF031` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `d3_Data1.cab_89c286305368\amdhsmpdriver.inf` | AMD Host System Management Port | `ACPI\AMDI0097` | ACPI-enumerated PnP hardware ID | `AmdHsmpDriver_Device` | No(Build) | No(Build) | Native | Native | NotDeclared |
| `d3_Data1.cab_89c286305368\amdi2c.inf` | AMD I2C Controller | `ACPI\AMD0010` | ACPI-enumerated PnP hardware ID | `amdi2c_Device` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_89c286305368\amdi2c.inf` | AMD I2C Controller | `ACPI\AMDI0010` | ACPI-enumerated PnP hardware ID | `amdi2c_Device` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_89c286305368\amdinterface.inf` | AMD PCI | `PCI\VEN_1002&DEV_145A` | PCI-enumerated PnP hardware ID | `AMDPCI64` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `d3_Data1.cab_89c286305368\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_1116` | PCI-enumerated PnP hardware ID | `AMDPCI64` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `d3_Data1.cab_89c286305368\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_1117` | PCI-enumerated PnP hardware ID | `AMDPCI64` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `d3_Data1.cab_89c286305368\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_1136` | PCI-enumerated PnP hardware ID | `AMDPCI64` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `d3_Data1.cab_89c286305368\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_1137` | PCI-enumerated PnP hardware ID | `AMDPCI64` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `d3_Data1.cab_89c286305368\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_1151` | PCI-enumerated PnP hardware ID | `AMDPCI64` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `d3_Data1.cab_89c286305368\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_14AC` | PCI-enumerated PnP hardware ID | `AMDPCI64` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `d3_Data1.cab_89c286305368\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_14DC` | PCI-enumerated PnP hardware ID | `AMDPCI64` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `d3_Data1.cab_89c286305368\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_14DE` | PCI-enumerated PnP hardware ID | `AMDPCI64` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `d3_Data1.cab_89c286305368\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_14EC` | PCI-enumerated PnP hardware ID | `AMDPCI64` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `d3_Data1.cab_89c286305368\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_150D` | PCI-enumerated PnP hardware ID | `AMDPCI64` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `d3_Data1.cab_89c286305368\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_1556` | PCI-enumerated PnP hardware ID | `AMDPCI64` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `d3_Data1.cab_89c286305368\amdinterface.inf` | AMD SMBUS | `PCI\VEN_1022&DEV_790B` | PCI-enumerated PnP hardware ID | `AMDPCI64` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `d3_Data1.cab_89c286305368\amdinterface.inf` | AMD SPI Controller | `ACPI\AMDI0062` | ACPI-enumerated PnP hardware ID | `AMDPCI64` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `d3_Data1.cab_89c286305368\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1002&DEV_5A23` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_89c286305368\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_13E1` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_89c286305368\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1419` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_89c286305368\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1423` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_89c286305368\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1437` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_89c286305368\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1451` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_89c286305368\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1481` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_89c286305368\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1577` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_89c286305368\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_164F` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_89c286305368\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMD0004` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | No(Build) | Projection | Projection | Projection | NotDeclared |
| `d3_Data1.cab_89c286305368\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMD0005` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | No(Build) | Projection | Projection | Projection | NotDeclared |
| `d3_Data1.cab_89c286305368\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0005` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | No(Build) | Projection | Projection | Projection | NotDeclared |
| `d3_Data1.cab_89c286305368\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0006` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | No(Build) | Projection | Projection | Projection | NotDeclared |
| `d3_Data1.cab_89c286305368\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0007` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | No(Build) | Projection | Projection | Projection | NotDeclared |
| `d3_Data1.cab_89c286305368\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0008` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | No(Build) | Projection | Projection | Projection | NotDeclared |
| `d3_Data1.cab_89c286305368\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0009` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | No(Build) | Projection | Projection | Projection | NotDeclared |
| `d3_Data1.cab_89c286305368\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI000A` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install.AMDI000A` | No(Build) | Projection | Projection | Projection | NotDeclared |
| `d3_Data1.cab_89c286305368\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI000B` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | No(Build) | Projection | Projection | Projection | NotDeclared |
| `d3_Data1.cab_89c286305368\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI000C` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | No(Build) | Projection | Projection | Projection | NotDeclared |
| `d3_Data1.cab_89c286305368\amdoemprov.inf` | AMD Provisioning for OEM | `ACPI\AMDI0053` | ACPI-enumerated PnP hardware ID | `AMDPPMPF_DEV` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `d3_Data1.cab_89c286305368\amdpcidev.inf` | AMD PCI | `PCI\VEN_1002&DEV_145A` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_89c286305368\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_1455` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_89c286305368\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_145A` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_89c286305368\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_1485` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_89c286305368\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_148A` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_89c286305368\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_14DE` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_89c286305368\amdpmf.inf` | AMD PMF | `ACPI\AMDI0100` | ACPI-enumerated PnP hardware ID | `AMDPMF_INSTALL.NTamd64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_89c286305368\amdpmf.inf` | AMD PMF | `ACPI\AMDI0102` | ACPI-enumerated PnP hardware ID | `AMDPMF_INSTALL.NTamd64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_89c286305368\amdppkg.inf` | AMD Provisioning Packages | `ACPI\AMDI0052` | ACPI-enumerated PnP hardware ID | `InstallSection_Win10` | No(Build) | No(Build) | Native | No | NotDeclared |
| `d3_Data1.cab_89c286305368\amdppkg.inf` | AMD Provisioning Packages | `ACPI\AMDI0052` | ACPI-enumerated PnP hardware ID | `InstallSection_Win11_22H2` | No(Build) | No(Build) | No | Native | NotDeclared |
| `d3_Data1.cab_89c286305368\amdpsp.inf` | AMD PSP 10.0 Device | `PCI\VEN_1022&DEV_15DF` | PCI-enumerated PnP hardware ID | `amdpsp_Device_100` | Native | No | No | No | KMDF 1.13 |
| `d3_Data1.cab_89c286305368\amdpsp.inf` | AMD PSP 10.0 Device | `PCI\VEN_1022&DEV_15DF` | PCI-enumerated PnP hardware ID | `amdpsp_Device_100_RS3` | No | Native | Native | Native | KMDF 1.13 |
| `d3_Data1.cab_89c286305368\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_1134` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | No | No | No | KMDF 1.13 |
| `d3_Data1.cab_89c286305368\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_1134` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110_RS3` | No | Native | Native | Native | KMDF 1.13 |
| `d3_Data1.cab_89c286305368\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_115A` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110_RS3` | No | Native | Native | Native | KMDF 1.13 |
| `d3_Data1.cab_89c286305368\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_115A` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | No | No | No | KMDF 1.13 |
| `d3_Data1.cab_89c286305368\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_1486` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110_RS3` | No | Native | Native | Native | KMDF 1.13 |
| `d3_Data1.cab_89c286305368\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_1486` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | No | No | No | KMDF 1.13 |
| `d3_Data1.cab_89c286305368\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_14CA` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110_RS3` | No | Native | Native | Native | KMDF 1.13 |
| `d3_Data1.cab_89c286305368\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_14CA` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | No | No | No | KMDF 1.13 |
| `d3_Data1.cab_89c286305368\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_156E` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110_RS3` | No | Native | Native | Native | KMDF 1.13 |
| `d3_Data1.cab_89c286305368\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_156E` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | No | No | No | KMDF 1.13 |
| `d3_Data1.cab_89c286305368\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_15C7` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | No | No | No | KMDF 1.13 |
| `d3_Data1.cab_89c286305368\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_15C7` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110_RS3` | No | Native | Native | Native | KMDF 1.13 |
| `d3_Data1.cab_89c286305368\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_1649` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | No | No | No | KMDF 1.13 |
| `d3_Data1.cab_89c286305368\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_1649` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110_RS3` | No | Native | Native | Native | KMDF 1.13 |
| `d3_Data1.cab_89c286305368\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_17E0` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110_RS3` | No | Native | Native | Native | KMDF 1.13 |
| `d3_Data1.cab_89c286305368\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_17E0` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | No | No | No | KMDF 1.13 |
| `d3_Data1.cab_89c286305368\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_13EC` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | No | No | No | KMDF 1.13 |
| `d3_Data1.cab_89c286305368\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_13EC` | PCI-enumerated PnP hardware ID | `amdpsp_Device_RS3` | No | Native | Native | Native | KMDF 1.13 |
| `d3_Data1.cab_89c286305368\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_1456` | PCI-enumerated PnP hardware ID | `amdpsp_Device_RS3` | No | Native | Native | Native | KMDF 1.13 |
| `d3_Data1.cab_89c286305368\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_1456` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | No | No | No | KMDF 1.13 |
| `d3_Data1.cab_89c286305368\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_1537` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | No | No | No | KMDF 1.13 |
| `d3_Data1.cab_89c286305368\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_1537` | PCI-enumerated PnP hardware ID | `amdpsp_Device_RS3` | No | Native | Native | Native | KMDF 1.13 |
| `d3_Data1.cab_89c286305368\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_1578` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | No | No | No | KMDF 1.13 |
| `d3_Data1.cab_89c286305368\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_1578` | PCI-enumerated PnP hardware ID | `amdpsp_Device_RS3` | No | Native | Native | Native | KMDF 1.13 |
| `d3_Data1.cab_89c286305368\amdsfhkmdf.inf` | AMD Sensor Fusion Hub | `PCI\VEN_1022&DEV_15E4` | PCI-enumerated PnP hardware ID | `amdsfhkmdf_Device` | Native | Native | Native | Native | KMDF 1.15 |
| `d3_Data1.cab_89c286305368\amdsfhkmdfi2c.inf` | AMD SFH KMDF I2C | `PCI\VEN_1022&DEV_15E6` | PCI-enumerated PnP hardware ID | `amdsfhkmdf_Device` | Native | Native | Native | Native | KMDF 1.15 |
| `d3_Data1.cab_89c286305368\amdsfhspbi2c.inf` | AMD SFH I2C Controller | `ACPI\AMDI0011` | ACPI-enumerated PnP hardware ID | `amdsfhspbi2c_Device` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_89c286305368\amdsfhumdf.inf` | AMD UMDF Sensor | `ACPI\AMDI0080` | ACPI-enumerated PnP hardware ID | `amdsfhumdf_Inst_Win10` | No(Build) | Native | Native | No | UMDF 2.15.0 |
| `d3_Data1.cab_89c286305368\amdsfhumdf.inf` | AMD UMDF Sensor | `ACPI\AMDI0080` | ACPI-enumerated PnP hardware ID | `amdsfhumdf_Inst_Win11` | No(Build) | No | No | Native | UMDF 2.15.0 |
| `d3_Data1.cab_89c286305368\amduart.inf` | AMD UART Controller | `ACPI\AMD0020` | ACPI-enumerated PnP hardware ID | `amduart_Inst` | No(Build) | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_89c286305368\amduart.inf` | AMD UART Controller | `ACPI\AMDI0020` | ACPI-enumerated PnP hardware ID | `amduart_Inst` | No(Build) | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_89c286305368\amduart.inf` | AMD UART Controller | `ACPI\AMDI0022` | ACPI-enumerated PnP hardware ID | `amduart_Inst` | No(Build) | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_89c286305368\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_15C4` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `d3_Data1.cab_89c286305368\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_15C5` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `d3_Data1.cab_89c286305368\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_162E` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `d3_Data1.cab_89c286305368\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_162F` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `d3_Data1.cab_89c286305368\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_1668` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `d3_Data1.cab_89c286305368\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_1669` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `d3_Data1.cab_89c286305368\amdusb4net.inf` | AMD USB4NET | `{b85b7c50-6a01-11d2-b841-00c04fad5171}\AMDUSB4NET` | Device-class-specific ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_89c286305368\amdusb4net.inf` | AMD USB4NET | `{b85b7c50-6a01-11d2-b841-00c04fad5171}\Usb4Net` | Device-class-specific ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_89c286305368\amdusb4net.inf` | AMD USB4NET | `root\AMDUSB4NET_a` | Root-enumerated PnP hardware ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_89c286305368\amdusb4net.inf` | AMD USB4NET | `root\AMDUSB4NET_b` | Root-enumerated PnP hardware ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_89c286305368\amdusb4net.inf` | AMD USB4NET | `root\AMDUSB4NET_c` | Root-enumerated PnP hardware ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_89c286305368\amdusb4net.inf` | AMD USB4NET | `root\AMDUSB4NET_d` | Root-enumerated PnP hardware ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_89c286305368\amdusb4pcifilter.inf` | PCI Express Root Port | `PCI\VEN_1022&DEV_14CD&SUBSYS_14531022&REV_00` | PCI-enumerated PnP hardware ID | `amdusb4pcifilter` | Native | Native | Excluded | Excluded | NotDeclared |
| `d3_Data1.cab_89c286305368\amdusb4pcifilter.inf` | PCI Express Root Port | `PCI\VEN_1022&DEV_14EF&SUBSYS_14531022&REV_00` | PCI-enumerated PnP hardware ID | `amdusb4pcifilter` | Native | Native | Excluded | Excluded | NotDeclared |
| `d3_Data1.cab_89c286305368\amdusb4pcifilter.inf` | PCI Express Root Port | `PCI\VEN_1022&DEV_14EF&SUBSYS_14531022&REV_01` | PCI-enumerated PnP hardware ID | `amdusb4pcifilter` | Native | Native | Excluded | Excluded | NotDeclared |
| `d3_Data1.cab_89c286305368\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15C0&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Excluded | Excluded | NotDeclared |
| `d3_Data1.cab_89c286305368\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15C1&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Excluded | Excluded | NotDeclared |
| `d3_Data1.cab_89c286305368\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15C2&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Excluded | Excluded | NotDeclared |
| `d3_Data1.cab_89c286305368\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15C3&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Excluded | Excluded | NotDeclared |
| `d3_Data1.cab_89c286305368\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15D6&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Excluded | Excluded | NotDeclared |
| `d3_Data1.cab_89c286305368\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15D7&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Excluded | Excluded | NotDeclared |
| `d3_Data1.cab_89c286305368\amdwirelessbutton.inf` | AMD Wireless Button Driver | `ACPI\AMDI0051` | ACPI-enumerated PnP hardware ID | `amdwirelessbutton_Device` | No(Build) | Native | Native | No | KMDF 1.15 |
| `d3_Data1.cab_89c286305368\amdwirelessbutton.inf` | AMD Wireless Button Driver | `ACPI\AMDI0051` | ACPI-enumerated PnP hardware ID | `amdwirelessbutton_DeviceWin11` | No(Build) | No | No | Native | KMDF 1.15 |
| `d3_Data1.cab_89c286305368\ams_mailboxdrv.inf` | AMS-MailBoxDrv | `ACPI\AMDI0090` | ACPI-enumerated PnP hardware ID | `AMS-MailBoxDrv_Device` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_89c286305368\plutonnull.inf` | AMD NULL Driver for Microsoft Pluton Security Processor | `ACPI\MSFT0200` | ACPI-enumerated PnP hardware ID | `Null_Pluton_Device` | Native | Native | Native | Excluded | NotDeclared |
| `d3_Data1.cab_89c286305368\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4353` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_89c286305368\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4363` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_89c286305368\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4372` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_89c286305368\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4385` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_89c286305368\smbusamd.inf` | AMD SMBus | `PCI\VEN_1022&DEV_780B` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_89c286305368\smbusamd.inf` | AMD SMBus | `PCI\VEN_1022&DEV_790B` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_89c286305368\usbfilter.inf` | AMD USB Filter Driver | `{36FC9E60-C465-11CF-8056-444553540000}\usbfilter` | Device-class-specific ID | `usbfilter` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_89c286305368\zenpromnf.inf` | ZenProM S0i3 Network Filter | `ZenProMnf` | Network software component ID | `Install` | Native | Native | Native | Native | NotDeclared |

## AMD Chipset Software 8.01.20.513

| INF | Device | Device identifier | Identifier type | Install section | WS2016 | WS2019 | WS2022 | WS2025 | WDF |
|---|---|---|---|---|---|---|---|---|---|
| `d3_Data1.cab_c9ea7860c4bb\amd3dvcache.inf` | AMD 3D V-Cache Performance Optimizer | `ACPI\AMDI0101` | ACPI-enumerated PnP hardware ID | `Amd3dvcache_Device` | No(Build) | No(Build) | Native | Native | KMDF 1.15 |
| `d3_Data1.cab_c9ea7860c4bb\amdappcompat.inf` | AMD Application Compatibility Database | `ACPI\AMDI0204` | ACPI-enumerated PnP hardware ID | `AmdAppCompat_Device` | No(Build) | Native | Native | Native | KMDF 1.15 |
| `d3_Data1.cab_c9ea7860c4bb\amdas4.inf` | AmdAS4 Device | `ACPI\AMDI0050` | ACPI-enumerated PnP hardware ID | `AmdAS4` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_c9ea7860c4bb\amdas4.inf` | AmdAS4 Device | `ACPI\ASD0001` | ACPI-enumerated PnP hardware ID | `AmdAS4` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_c9ea7860c4bb\amdcir.inf` | AMD CIR Driver | `*AMDC001` | Generic PnP hardware ID | `AMDCIR64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_c9ea7860c4bb\amdcir.inf` | AMD CIR Driver | `*AMDC002` | Generic PnP hardware ID | `AMDCIR64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_c9ea7860c4bb\amdcir.inf` | AMD CIR Driver | `*AMDC003` | Generic PnP hardware ID | `AMDCIR64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_c9ea7860c4bb\amdgpio2.inf` | AMD GPIO Controller | `ACPI\AMD0030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | No(Build) | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_c9ea7860c4bb\amdgpio2.inf` | AMD GPIO Controller | `ACPI\AMDI0030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | No(Build) | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_c9ea7860c4bb\amdgpio2.inf` | AMD GPIO Controller | `ACPI\AMDI0031` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | No(Build) | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_c9ea7860c4bb\amdgpio2.inf` | AMD GPIO Controller | `ACPI\GPIO0010` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | No(Build) | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_c9ea7860c4bb\amdgpio3.inf` | AMD GPIO Controller | `ACPI\AMDF030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `d3_Data1.cab_c9ea7860c4bb\amdgpio3.inf` | AMD GPIO Controller | `ACPI\AMDIF030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `d3_Data1.cab_c9ea7860c4bb\amdgpio3.inf` | AMD GPIO Controller | `ACPI\AMDIF031` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `d3_Data1.cab_c9ea7860c4bb\amdhsmpdriver.inf` | AMD Host System Management Port | `ACPI\AMDI0097` | ACPI-enumerated PnP hardware ID | `AmdHsmpDriver_Device` | No(Build) | No(Build) | Native | Native | NotDeclared |
| `d3_Data1.cab_c9ea7860c4bb\amdi2c.inf` | AMD I2C Controller | `ACPI\AMD0010` | ACPI-enumerated PnP hardware ID | `amdi2c_Device` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_c9ea7860c4bb\amdi2c.inf` | AMD I2C Controller | `ACPI\AMDI0010` | ACPI-enumerated PnP hardware ID | `amdi2c_Device` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_c9ea7860c4bb\amdinterface.inf` | AMD PCI | `PCI\VEN_1002&DEV_145A` | PCI-enumerated PnP hardware ID | `AMDPCI64` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `d3_Data1.cab_c9ea7860c4bb\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_1116` | PCI-enumerated PnP hardware ID | `AMDPCI64` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `d3_Data1.cab_c9ea7860c4bb\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_1117` | PCI-enumerated PnP hardware ID | `AMDPCI64` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `d3_Data1.cab_c9ea7860c4bb\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_1136` | PCI-enumerated PnP hardware ID | `AMDPCI64` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `d3_Data1.cab_c9ea7860c4bb\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_1137` | PCI-enumerated PnP hardware ID | `AMDPCI64` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `d3_Data1.cab_c9ea7860c4bb\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_1151` | PCI-enumerated PnP hardware ID | `AMDPCI64` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `d3_Data1.cab_c9ea7860c4bb\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_14AC` | PCI-enumerated PnP hardware ID | `AMDPCI64` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `d3_Data1.cab_c9ea7860c4bb\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_14DC` | PCI-enumerated PnP hardware ID | `AMDPCI64` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `d3_Data1.cab_c9ea7860c4bb\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_14DE` | PCI-enumerated PnP hardware ID | `AMDPCI64` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `d3_Data1.cab_c9ea7860c4bb\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_14EC` | PCI-enumerated PnP hardware ID | `AMDPCI64` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `d3_Data1.cab_c9ea7860c4bb\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_150D` | PCI-enumerated PnP hardware ID | `AMDPCI64` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `d3_Data1.cab_c9ea7860c4bb\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_1556` | PCI-enumerated PnP hardware ID | `AMDPCI64` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `d3_Data1.cab_c9ea7860c4bb\amdinterface.inf` | AMD SMBUS | `PCI\VEN_1022&DEV_790B` | PCI-enumerated PnP hardware ID | `AMDPCI64` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `d3_Data1.cab_c9ea7860c4bb\amdinterface.inf` | AMD SPI Controller | `ACPI\AMDI0062` | ACPI-enumerated PnP hardware ID | `AMDPCI64` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `d3_Data1.cab_c9ea7860c4bb\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1002&DEV_5A23` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_c9ea7860c4bb\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_13E1` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_c9ea7860c4bb\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1419` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_c9ea7860c4bb\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1423` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_c9ea7860c4bb\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1437` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_c9ea7860c4bb\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1451` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_c9ea7860c4bb\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1481` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_c9ea7860c4bb\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1577` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_c9ea7860c4bb\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_164F` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_c9ea7860c4bb\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMD0004` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | No(Build) | Projection | Projection | Projection | NotDeclared |
| `d3_Data1.cab_c9ea7860c4bb\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMD0005` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | No(Build) | Projection | Projection | Projection | NotDeclared |
| `d3_Data1.cab_c9ea7860c4bb\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0005` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | No(Build) | Projection | Projection | Projection | NotDeclared |
| `d3_Data1.cab_c9ea7860c4bb\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0006` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | No(Build) | Projection | Projection | Projection | NotDeclared |
| `d3_Data1.cab_c9ea7860c4bb\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0007` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | No(Build) | Projection | Projection | Projection | NotDeclared |
| `d3_Data1.cab_c9ea7860c4bb\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0008` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | No(Build) | Projection | Projection | Projection | NotDeclared |
| `d3_Data1.cab_c9ea7860c4bb\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0009` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | No(Build) | Projection | Projection | Projection | NotDeclared |
| `d3_Data1.cab_c9ea7860c4bb\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI000A` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install.AMDI000A` | No(Build) | Projection | Projection | Projection | NotDeclared |
| `d3_Data1.cab_c9ea7860c4bb\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI000B` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | No(Build) | Projection | Projection | Projection | NotDeclared |
| `d3_Data1.cab_c9ea7860c4bb\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI000C` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | No(Build) | Projection | Projection | Projection | NotDeclared |
| `d3_Data1.cab_c9ea7860c4bb\amdoemprov.inf` | AMD Provisioning for OEM | `ACPI\AMDI0053` | ACPI-enumerated PnP hardware ID | `AMDPPMPF_DEV` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `d3_Data1.cab_c9ea7860c4bb\amdpcidev.inf` | AMD PCI | `PCI\VEN_1002&DEV_145A` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_c9ea7860c4bb\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_1455` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_c9ea7860c4bb\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_145A` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_c9ea7860c4bb\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_1485` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_c9ea7860c4bb\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_148A` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_c9ea7860c4bb\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_14DE` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_c9ea7860c4bb\amdpmf.inf` | AMD PMF | `ACPI\AMDI0100` | ACPI-enumerated PnP hardware ID | `AMDPMF_INSTALL.NTamd64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_c9ea7860c4bb\amdpmf.inf` | AMD PMF | `ACPI\AMDI0102` | ACPI-enumerated PnP hardware ID | `AMDPMF_INSTALL.NTamd64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_c9ea7860c4bb\amdppkg.inf` | AMD Provisioning Packages | `ACPI\AMDI0052` | ACPI-enumerated PnP hardware ID | `InstallSection_Win10` | No(Build) | No(Build) | Native | No | NotDeclared |
| `d3_Data1.cab_c9ea7860c4bb\amdppkg.inf` | AMD Provisioning Packages | `ACPI\AMDI0052` | ACPI-enumerated PnP hardware ID | `InstallSection_Win11_22H2` | No(Build) | No(Build) | No | Native | NotDeclared |
| `d3_Data1.cab_c9ea7860c4bb\amdpsp.inf` | AMD PSP 10.0 Device | `PCI\VEN_1022&DEV_15DF` | PCI-enumerated PnP hardware ID | `amdpsp_Device_100` | Native | No | No | No | KMDF 1.13 |
| `d3_Data1.cab_c9ea7860c4bb\amdpsp.inf` | AMD PSP 10.0 Device | `PCI\VEN_1022&DEV_15DF` | PCI-enumerated PnP hardware ID | `amdpsp_Device_100_RS3` | No | Native | Native | Native | KMDF 1.13 |
| `d3_Data1.cab_c9ea7860c4bb\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_1134` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | No | No | No | KMDF 1.13 |
| `d3_Data1.cab_c9ea7860c4bb\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_1134` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110_RS3` | No | Native | Native | Native | KMDF 1.13 |
| `d3_Data1.cab_c9ea7860c4bb\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_115A` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110_RS3` | No | Native | Native | Native | KMDF 1.13 |
| `d3_Data1.cab_c9ea7860c4bb\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_115A` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | No | No | No | KMDF 1.13 |
| `d3_Data1.cab_c9ea7860c4bb\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_1486` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110_RS3` | No | Native | Native | Native | KMDF 1.13 |
| `d3_Data1.cab_c9ea7860c4bb\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_1486` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | No | No | No | KMDF 1.13 |
| `d3_Data1.cab_c9ea7860c4bb\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_14CA` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110_RS3` | No | Native | Native | Native | KMDF 1.13 |
| `d3_Data1.cab_c9ea7860c4bb\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_14CA` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | No | No | No | KMDF 1.13 |
| `d3_Data1.cab_c9ea7860c4bb\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_156E` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110_RS3` | No | Native | Native | Native | KMDF 1.13 |
| `d3_Data1.cab_c9ea7860c4bb\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_156E` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | No | No | No | KMDF 1.13 |
| `d3_Data1.cab_c9ea7860c4bb\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_15C7` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | No | No | No | KMDF 1.13 |
| `d3_Data1.cab_c9ea7860c4bb\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_15C7` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110_RS3` | No | Native | Native | Native | KMDF 1.13 |
| `d3_Data1.cab_c9ea7860c4bb\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_1649` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | No | No | No | KMDF 1.13 |
| `d3_Data1.cab_c9ea7860c4bb\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_1649` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110_RS3` | No | Native | Native | Native | KMDF 1.13 |
| `d3_Data1.cab_c9ea7860c4bb\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_17E0` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110_RS3` | No | Native | Native | Native | KMDF 1.13 |
| `d3_Data1.cab_c9ea7860c4bb\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_17E0` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | No | No | No | KMDF 1.13 |
| `d3_Data1.cab_c9ea7860c4bb\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_13EC` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | No | No | No | KMDF 1.13 |
| `d3_Data1.cab_c9ea7860c4bb\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_13EC` | PCI-enumerated PnP hardware ID | `amdpsp_Device_RS3` | No | Native | Native | Native | KMDF 1.13 |
| `d3_Data1.cab_c9ea7860c4bb\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_1456` | PCI-enumerated PnP hardware ID | `amdpsp_Device_RS3` | No | Native | Native | Native | KMDF 1.13 |
| `d3_Data1.cab_c9ea7860c4bb\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_1456` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | No | No | No | KMDF 1.13 |
| `d3_Data1.cab_c9ea7860c4bb\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_1537` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | No | No | No | KMDF 1.13 |
| `d3_Data1.cab_c9ea7860c4bb\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_1537` | PCI-enumerated PnP hardware ID | `amdpsp_Device_RS3` | No | Native | Native | Native | KMDF 1.13 |
| `d3_Data1.cab_c9ea7860c4bb\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_1578` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | No | No | No | KMDF 1.13 |
| `d3_Data1.cab_c9ea7860c4bb\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_1578` | PCI-enumerated PnP hardware ID | `amdpsp_Device_RS3` | No | Native | Native | Native | KMDF 1.13 |
| `d3_Data1.cab_c9ea7860c4bb\amdsfhkmdf.inf` | AMD Sensor Fusion Hub | `PCI\VEN_1022&DEV_15E4` | PCI-enumerated PnP hardware ID | `amdsfhkmdf_Device` | Native | Native | Native | Native | KMDF 1.15 |
| `d3_Data1.cab_c9ea7860c4bb\amdsfhkmdfi2c.inf` | AMD SFH KMDF I2C | `PCI\VEN_1022&DEV_15E6` | PCI-enumerated PnP hardware ID | `amdsfhkmdf_Device` | Native | Native | Native | Native | KMDF 1.15 |
| `d3_Data1.cab_c9ea7860c4bb\amdsfhspbi2c.inf` | AMD SFH I2C Controller | `ACPI\AMDI0011` | ACPI-enumerated PnP hardware ID | `amdsfhspbi2c_Device` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_c9ea7860c4bb\amdsfhumdf.inf` | AMD UMDF Sensor | `ACPI\AMDI0080` | ACPI-enumerated PnP hardware ID | `amdsfhumdf_Inst_Win10` | No(Build) | Native | Native | No | UMDF 2.15.0 |
| `d3_Data1.cab_c9ea7860c4bb\amdsfhumdf.inf` | AMD UMDF Sensor | `ACPI\AMDI0080` | ACPI-enumerated PnP hardware ID | `amdsfhumdf_Inst_Win11` | No(Build) | No | No | Native | UMDF 2.15.0 |
| `d3_Data1.cab_c9ea7860c4bb\amduart.inf` | AMD UART Controller | `ACPI\AMD0020` | ACPI-enumerated PnP hardware ID | `amduart_Inst` | No(Build) | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_c9ea7860c4bb\amduart.inf` | AMD UART Controller | `ACPI\AMDI0020` | ACPI-enumerated PnP hardware ID | `amduart_Inst` | No(Build) | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_c9ea7860c4bb\amduart.inf` | AMD UART Controller | `ACPI\AMDI0022` | ACPI-enumerated PnP hardware ID | `amduart_Inst` | No(Build) | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_c9ea7860c4bb\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_15C4` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `d3_Data1.cab_c9ea7860c4bb\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_15C5` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `d3_Data1.cab_c9ea7860c4bb\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_162E` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `d3_Data1.cab_c9ea7860c4bb\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_162F` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `d3_Data1.cab_c9ea7860c4bb\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_1668` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `d3_Data1.cab_c9ea7860c4bb\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_1669` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `d3_Data1.cab_c9ea7860c4bb\amdusb4net.inf` | AMD USB4NET | `{b85b7c50-6a01-11d2-b841-00c04fad5171}\AMDUSB4NET` | Device-class-specific ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_c9ea7860c4bb\amdusb4net.inf` | AMD USB4NET | `{b85b7c50-6a01-11d2-b841-00c04fad5171}\Usb4Net` | Device-class-specific ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_c9ea7860c4bb\amdusb4net.inf` | AMD USB4NET | `root\AMDUSB4NET_a` | Root-enumerated PnP hardware ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_c9ea7860c4bb\amdusb4net.inf` | AMD USB4NET | `root\AMDUSB4NET_b` | Root-enumerated PnP hardware ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_c9ea7860c4bb\amdusb4net.inf` | AMD USB4NET | `root\AMDUSB4NET_c` | Root-enumerated PnP hardware ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_c9ea7860c4bb\amdusb4net.inf` | AMD USB4NET | `root\AMDUSB4NET_d` | Root-enumerated PnP hardware ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_c9ea7860c4bb\amdusb4pcifilter.inf` | PCI Express Root Port | `PCI\VEN_1022&DEV_14CD&SUBSYS_14531022&REV_00` | PCI-enumerated PnP hardware ID | `amdusb4pcifilter` | Native | Native | Excluded | Excluded | NotDeclared |
| `d3_Data1.cab_c9ea7860c4bb\amdusb4pcifilter.inf` | PCI Express Root Port | `PCI\VEN_1022&DEV_14EF&SUBSYS_14531022&REV_00` | PCI-enumerated PnP hardware ID | `amdusb4pcifilter` | Native | Native | Excluded | Excluded | NotDeclared |
| `d3_Data1.cab_c9ea7860c4bb\amdusb4pcifilter.inf` | PCI Express Root Port | `PCI\VEN_1022&DEV_14EF&SUBSYS_14531022&REV_01` | PCI-enumerated PnP hardware ID | `amdusb4pcifilter` | Native | Native | Excluded | Excluded | NotDeclared |
| `d3_Data1.cab_c9ea7860c4bb\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15C0&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Excluded | Excluded | NotDeclared |
| `d3_Data1.cab_c9ea7860c4bb\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15C1&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Excluded | Excluded | NotDeclared |
| `d3_Data1.cab_c9ea7860c4bb\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15C2&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Excluded | Excluded | NotDeclared |
| `d3_Data1.cab_c9ea7860c4bb\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15C3&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Excluded | Excluded | NotDeclared |
| `d3_Data1.cab_c9ea7860c4bb\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15D6&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Excluded | Excluded | NotDeclared |
| `d3_Data1.cab_c9ea7860c4bb\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15D7&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Excluded | Excluded | NotDeclared |
| `d3_Data1.cab_c9ea7860c4bb\amdwirelessbutton.inf` | AMD Wireless Button Driver | `ACPI\AMDI0051` | ACPI-enumerated PnP hardware ID | `amdwirelessbutton_Device` | No(Build) | Native | Native | No | KMDF 1.15 |
| `d3_Data1.cab_c9ea7860c4bb\amdwirelessbutton.inf` | AMD Wireless Button Driver | `ACPI\AMDI0051` | ACPI-enumerated PnP hardware ID | `amdwirelessbutton_DeviceWin11` | No(Build) | No | No | Native | KMDF 1.15 |
| `d3_Data1.cab_c9ea7860c4bb\plutonnull.inf` | AMD NULL Driver for Microsoft Pluton Security Processor | `ACPI\MSFT0200` | ACPI-enumerated PnP hardware ID | `Null_Pluton_Device` | Native | Native | Native | Excluded | NotDeclared |
| `d3_Data1.cab_c9ea7860c4bb\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4353` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_c9ea7860c4bb\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4363` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_c9ea7860c4bb\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4372` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_c9ea7860c4bb\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4385` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_c9ea7860c4bb\smbusamd.inf` | AMD SMBus | `PCI\VEN_1022&DEV_780B` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_c9ea7860c4bb\smbusamd.inf` | AMD SMBus | `PCI\VEN_1022&DEV_790B` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_c9ea7860c4bb\usbfilter.inf` | AMD USB Filter Driver | `{36FC9E60-C465-11CF-8056-444553540000}\usbfilter` | Device-class-specific ID | `usbfilter` | Native | Native | Native | Native | NotDeclared |

## AMD Chipset Software 7.11.26.2142

| INF | Device | Device identifier | Identifier type | Install section | WS2016 | WS2019 | WS2022 | WS2025 | WDF |
|---|---|---|---|---|---|---|---|---|---|
| `d3_Data1.cab_f0536bbb6064\amd3dvcache.inf` | AMD 3D V-Cache Performance Optimizer | `ACPI\AMDI0101` | ACPI-enumerated PnP hardware ID | `Amd3dvcache_Device` | No(Build) | No(Build) | Native | Native | KMDF 1.15 |
| `d3_Data1.cab_f0536bbb6064\amdappcompat.inf` | AMD Application Compatibility Database | `ACPI\AMDI0204` | ACPI-enumerated PnP hardware ID | `AmdAppCompat_Device` | No(Build) | Native | Native | Native | KMDF 1.15 |
| `d3_Data1.cab_f0536bbb6064\amdas4.inf` | AmdAS4 Device | `ACPI\AMDI0050` | ACPI-enumerated PnP hardware ID | `AmdAS4` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_f0536bbb6064\amdas4.inf` | AmdAS4 Device | `ACPI\ASD0001` | ACPI-enumerated PnP hardware ID | `AmdAS4` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_f0536bbb6064\amdcir.inf` | AMD CIR Driver | `*AMDC001` | Generic PnP hardware ID | `AMDCIR64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_f0536bbb6064\amdcir.inf` | AMD CIR Driver | `*AMDC002` | Generic PnP hardware ID | `AMDCIR64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_f0536bbb6064\amdcir.inf` | AMD CIR Driver | `*AMDC003` | Generic PnP hardware ID | `AMDCIR64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_f0536bbb6064\amdgpio2.inf` | AMD GPIO Controller | `ACPI\AMD0030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_f0536bbb6064\amdgpio2.inf` | AMD GPIO Controller | `ACPI\AMDI0030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_f0536bbb6064\amdgpio2.inf` | AMD GPIO Controller | `ACPI\AMDI0031` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_f0536bbb6064\amdgpio2.inf` | AMD GPIO Controller | `ACPI\GPIO0010` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_f0536bbb6064\amdgpio3.inf` | AMD GPIO Controller | `ACPI\AMDF030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_f0536bbb6064\amdgpio3.inf` | AMD GPIO Controller | `ACPI\AMDIF030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_f0536bbb6064\amdgpio3.inf` | AMD GPIO Controller | `ACPI\AMDIF031` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_f0536bbb6064\amdhsmpdriver.inf` | AMD Host System Management Port | `ACPI\AMD0097` | ACPI-enumerated PnP hardware ID | `AmdHsmpDriver_Device` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_f0536bbb6064\amdhsmpdriver.inf` | AMD Host System Management Port | `ACPI\AMDI0097` | ACPI-enumerated PnP hardware ID | `AmdHsmpDriver_Device` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_f0536bbb6064\amdhsmpdriver.inf` | AMD Host System Management Port | `PCI\VEN_1022&DEV_14A4` | PCI-enumerated PnP hardware ID | `AmdHsmpDriver_Device` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_f0536bbb6064\amdi2c.inf` | AMD I2C Controller | `ACPI\AMD0010` | ACPI-enumerated PnP hardware ID | `amdi2c_Device` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_f0536bbb6064\amdi2c.inf` | AMD I2C Controller | `ACPI\AMDI0010` | ACPI-enumerated PnP hardware ID | `amdi2c_Device` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_f0536bbb6064\amdinterface.inf` | AMD Hetero Driver | `ACPI\AMDI0104` | ACPI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_f0536bbb6064\amdinterface.inf` | AMD PCI | `PCI\VEN_1002&DEV_145A` | PCI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_f0536bbb6064\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_1116` | PCI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_f0536bbb6064\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_1117` | PCI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_f0536bbb6064\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_1136` | PCI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_f0536bbb6064\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_1137` | PCI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_f0536bbb6064\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_14AC` | PCI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_f0536bbb6064\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_14DC` | PCI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_f0536bbb6064\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_14DE` | PCI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_f0536bbb6064\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_14EC` | PCI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_f0536bbb6064\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_150D` | PCI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_f0536bbb6064\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_1556` | PCI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_f0536bbb6064\amdinterface.inf` | AMD SMBUS | `PCI\VEN_1022&DEV_790B` | PCI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_f0536bbb6064\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1002&DEV_5A23` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_f0536bbb6064\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_13E1` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_f0536bbb6064\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1419` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_f0536bbb6064\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1423` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_f0536bbb6064\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1437` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_f0536bbb6064\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1451` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_f0536bbb6064\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1481` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_f0536bbb6064\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1577` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_f0536bbb6064\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_164F` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_f0536bbb6064\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMD0004` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | No(Build) | Projection | Projection | Projection | NotDeclared |
| `d3_Data1.cab_f0536bbb6064\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMD0005` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | No(Build) | Projection | Projection | Projection | NotDeclared |
| `d3_Data1.cab_f0536bbb6064\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0005` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | No(Build) | Projection | Projection | Projection | NotDeclared |
| `d3_Data1.cab_f0536bbb6064\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0006` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | No(Build) | Projection | Projection | Projection | NotDeclared |
| `d3_Data1.cab_f0536bbb6064\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0007` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | No(Build) | Projection | Projection | Projection | NotDeclared |
| `d3_Data1.cab_f0536bbb6064\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0008` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | No(Build) | Projection | Projection | Projection | NotDeclared |
| `d3_Data1.cab_f0536bbb6064\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0009` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | No(Build) | Projection | Projection | Projection | NotDeclared |
| `d3_Data1.cab_f0536bbb6064\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI000A` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | No(Build) | Projection | Projection | Projection | NotDeclared |
| `d3_Data1.cab_f0536bbb6064\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI000B` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | No(Build) | Projection | Projection | Projection | NotDeclared |
| `d3_Data1.cab_f0536bbb6064\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI000C` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | No(Build) | Projection | Projection | Projection | NotDeclared |
| `d3_Data1.cab_f0536bbb6064\amdoemprov.inf` | AMD Provisioning for OEM | `ACPI\AMDI0053` | ACPI-enumerated PnP hardware ID | `AMDPPMPF_DEV` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `d3_Data1.cab_f0536bbb6064\amdpcidev.inf` | AMD PCI | `PCI\VEN_1002&DEV_145A` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_f0536bbb6064\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_1455` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_f0536bbb6064\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_145A` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_f0536bbb6064\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_1485` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_f0536bbb6064\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_148A` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_f0536bbb6064\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_14DE` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_f0536bbb6064\amdpmf.inf` | AMD PMF | `ACPI\AMDI0100` | ACPI-enumerated PnP hardware ID | `AMDPMF_INSTALL.NTamd64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_f0536bbb6064\amdpmf.inf` | AMD PMF | `ACPI\AMDI0102` | ACPI-enumerated PnP hardware ID | `AMDPMF_INSTALL.NTamd64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_f0536bbb6064\amdppkg.inf` | AMD Provisioning Packages | `ACPI\AMDI0052` | ACPI-enumerated PnP hardware ID | `InstallSection_Win10` | No(Build) | No(Build) | Native | No | NotDeclared |
| `d3_Data1.cab_f0536bbb6064\amdppkg.inf` | AMD Provisioning Packages | `ACPI\AMDI0052` | ACPI-enumerated PnP hardware ID | `InstallSection_Win11_22H2` | No(Build) | No(Build) | No | Native | NotDeclared |
| `d3_Data1.cab_f0536bbb6064\amdpsp.inf` | AMD PSP 10.0 Device | `PCI\VEN_1022&DEV_15DF` | PCI-enumerated PnP hardware ID | `amdpsp_Device_100` | Native | No | No | No | KMDF 1.13 |
| `d3_Data1.cab_f0536bbb6064\amdpsp.inf` | AMD PSP 10.0 Device | `PCI\VEN_1022&DEV_15DF` | PCI-enumerated PnP hardware ID | `amdpsp_Device_100_RS3` | No | Native | Native | Native | KMDF 1.13 |
| `d3_Data1.cab_f0536bbb6064\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_1134` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | No | No | No | KMDF 1.13 |
| `d3_Data1.cab_f0536bbb6064\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_1134` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110_RS3` | No | Native | Native | Native | KMDF 1.13 |
| `d3_Data1.cab_f0536bbb6064\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_115A` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110_RS3` | No | Native | Native | Native | KMDF 1.13 |
| `d3_Data1.cab_f0536bbb6064\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_115A` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | No | No | No | KMDF 1.13 |
| `d3_Data1.cab_f0536bbb6064\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_1486` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110_RS3` | No | Native | Native | Native | KMDF 1.13 |
| `d3_Data1.cab_f0536bbb6064\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_1486` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | No | No | No | KMDF 1.13 |
| `d3_Data1.cab_f0536bbb6064\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_14CA` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110_RS3` | No | Native | Native | Native | KMDF 1.13 |
| `d3_Data1.cab_f0536bbb6064\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_14CA` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | No | No | No | KMDF 1.13 |
| `d3_Data1.cab_f0536bbb6064\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_156E` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110_RS3` | No | Native | Native | Native | KMDF 1.13 |
| `d3_Data1.cab_f0536bbb6064\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_156E` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | No | No | No | KMDF 1.13 |
| `d3_Data1.cab_f0536bbb6064\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_15C7` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | No | No | No | KMDF 1.13 |
| `d3_Data1.cab_f0536bbb6064\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_15C7` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110_RS3` | No | Native | Native | Native | KMDF 1.13 |
| `d3_Data1.cab_f0536bbb6064\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_1649` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | No | No | No | KMDF 1.13 |
| `d3_Data1.cab_f0536bbb6064\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_1649` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110_RS3` | No | Native | Native | Native | KMDF 1.13 |
| `d3_Data1.cab_f0536bbb6064\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_17E0` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110_RS3` | No | Native | Native | Native | KMDF 1.13 |
| `d3_Data1.cab_f0536bbb6064\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_17E0` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | No | No | No | KMDF 1.13 |
| `d3_Data1.cab_f0536bbb6064\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_13EC` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | No | No | No | KMDF 1.13 |
| `d3_Data1.cab_f0536bbb6064\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_13EC` | PCI-enumerated PnP hardware ID | `amdpsp_Device_RS3` | No | Native | Native | Native | KMDF 1.13 |
| `d3_Data1.cab_f0536bbb6064\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_1456` | PCI-enumerated PnP hardware ID | `amdpsp_Device_RS3` | No | Native | Native | Native | KMDF 1.13 |
| `d3_Data1.cab_f0536bbb6064\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_1456` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | No | No | No | KMDF 1.13 |
| `d3_Data1.cab_f0536bbb6064\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_1537` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | No | No | No | KMDF 1.13 |
| `d3_Data1.cab_f0536bbb6064\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_1537` | PCI-enumerated PnP hardware ID | `amdpsp_Device_RS3` | No | Native | Native | Native | KMDF 1.13 |
| `d3_Data1.cab_f0536bbb6064\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_1578` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | No | No | No | KMDF 1.13 |
| `d3_Data1.cab_f0536bbb6064\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_1578` | PCI-enumerated PnP hardware ID | `amdpsp_Device_RS3` | No | Native | Native | Native | KMDF 1.13 |
| `d3_Data1.cab_f0536bbb6064\amdsfhkmdf.inf` | AMD Sensor Fusion Hub | `PCI\VEN_1022&DEV_15E4` | PCI-enumerated PnP hardware ID | `amdsfhkmdf_Device` | Native | Native | Native | Native | KMDF 1.15 |
| `d3_Data1.cab_f0536bbb6064\amdsfhkmdfi2c.inf` | AMD SFH KMDF I2C | `PCI\VEN_1022&DEV_15E6` | PCI-enumerated PnP hardware ID | `amdsfhkmdf_Device` | Native | Native | Native | Native | KMDF 1.15 |
| `d3_Data1.cab_f0536bbb6064\amdsfhspbi2c.inf` | AMD SFH I2C Controller | `ACPI\AMDI0011` | ACPI-enumerated PnP hardware ID | `amdsfhspbi2c_Device` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_f0536bbb6064\amdsfhumdf.inf` | AMD UMDF Sensor | `ACPI\AMDI0080` | ACPI-enumerated PnP hardware ID | `amdsfhumdf_Inst_Win10` | No(Build) | Native | Native | No | UMDF 2.15.0 |
| `d3_Data1.cab_f0536bbb6064\amdsfhumdf.inf` | AMD UMDF Sensor | `ACPI\AMDI0080` | ACPI-enumerated PnP hardware ID | `amdsfhumdf_Inst_Win11` | No(Build) | No | No | Native | UMDF 2.15.0 |
| `d3_Data1.cab_f0536bbb6064\amduart.inf` | AMD UART Controller | `ACPI\AMD0020` | ACPI-enumerated PnP hardware ID | `amduart_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_f0536bbb6064\amduart.inf` | AMD UART Controller | `ACPI\AMDI0020` | ACPI-enumerated PnP hardware ID | `amduart_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_f0536bbb6064\amduart.inf` | AMD UART Controller | `ACPI\AMDI0022` | ACPI-enumerated PnP hardware ID | `amduart_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_f0536bbb6064\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_15C4` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `d3_Data1.cab_f0536bbb6064\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_15C5` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `d3_Data1.cab_f0536bbb6064\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_162E` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `d3_Data1.cab_f0536bbb6064\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_162F` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `d3_Data1.cab_f0536bbb6064\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_1668` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `d3_Data1.cab_f0536bbb6064\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_1669` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `d3_Data1.cab_f0536bbb6064\amdusb4net.inf` | AMD USB4NET | `{b85b7c50-6a01-11d2-b841-00c04fad5171}\AMDUSB4NET` | Device-class-specific ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_f0536bbb6064\amdusb4net.inf` | AMD USB4NET | `{b85b7c50-6a01-11d2-b841-00c04fad5171}\Usb4Net` | Device-class-specific ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_f0536bbb6064\amdusb4net.inf` | AMD USB4NET | `root\AMDUSB4NET_a` | Root-enumerated PnP hardware ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_f0536bbb6064\amdusb4net.inf` | AMD USB4NET | `root\AMDUSB4NET_b` | Root-enumerated PnP hardware ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_f0536bbb6064\amdusb4net.inf` | AMD USB4NET | `root\AMDUSB4NET_c` | Root-enumerated PnP hardware ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_f0536bbb6064\amdusb4net.inf` | AMD USB4NET | `root\AMDUSB4NET_d` | Root-enumerated PnP hardware ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_f0536bbb6064\amdusb4pcifilter.inf` | PCI Express Root Port | `PCI\VEN_1022&DEV_14CD&SUBSYS_14531022&REV_00` | PCI-enumerated PnP hardware ID | `amdusb4pcifilter` | Native | Native | Excluded | Excluded | NotDeclared |
| `d3_Data1.cab_f0536bbb6064\amdusb4pcifilter.inf` | PCI Express Root Port | `PCI\VEN_1022&DEV_14EF&SUBSYS_14531022&REV_00` | PCI-enumerated PnP hardware ID | `amdusb4pcifilter` | Native | Native | Excluded | Excluded | NotDeclared |
| `d3_Data1.cab_f0536bbb6064\amdusb4pcifilter.inf` | PCI Express Root Port | `PCI\VEN_1022&DEV_14EF&SUBSYS_14531022&REV_01` | PCI-enumerated PnP hardware ID | `amdusb4pcifilter` | Native | Native | Excluded | Excluded | NotDeclared |
| `d3_Data1.cab_f0536bbb6064\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15C0&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Excluded | Excluded | NotDeclared |
| `d3_Data1.cab_f0536bbb6064\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15C1&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Excluded | Excluded | NotDeclared |
| `d3_Data1.cab_f0536bbb6064\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15C2&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Excluded | Excluded | NotDeclared |
| `d3_Data1.cab_f0536bbb6064\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15C3&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Excluded | Excluded | NotDeclared |
| `d3_Data1.cab_f0536bbb6064\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15D6&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Excluded | Excluded | NotDeclared |
| `d3_Data1.cab_f0536bbb6064\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15D7&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Excluded | Excluded | NotDeclared |
| `d3_Data1.cab_f0536bbb6064\amdwirelessbutton.inf` | AMD Wireless Button Driver | `ACPI\AMDI0051` | ACPI-enumerated PnP hardware ID | `amdwirelessbutton_Device` | No(Build) | Native | Native | No | KMDF 1.15 |
| `d3_Data1.cab_f0536bbb6064\amdwirelessbutton.inf` | AMD Wireless Button Driver | `ACPI\AMDI0051` | ACPI-enumerated PnP hardware ID | `amdwirelessbutton_DeviceWin11` | No(Build) | No | No | Native | KMDF 1.15 |
| `d3_Data1.cab_f0536bbb6064\ams_mailboxdrv.inf` | AMS-MailBoxDrv | `ACPI\AMDI0090` | ACPI-enumerated PnP hardware ID | `AMS-MailBoxDrv_Device` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_f0536bbb6064\plutonnull.inf` | AMD NULL Driver for Microsoft Pluton Security Processor | `ACPI\MSFT0200` | ACPI-enumerated PnP hardware ID | `Null_Pluton_Device` | Native | Native | Native | Excluded | NotDeclared |
| `d3_Data1.cab_f0536bbb6064\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4353` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_f0536bbb6064\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4363` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_f0536bbb6064\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4372` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_f0536bbb6064\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4385` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_f0536bbb6064\smbusamd.inf` | AMD SMBus | `PCI\VEN_1022&DEV_780B` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_f0536bbb6064\smbusamd.inf` | AMD SMBus | `PCI\VEN_1022&DEV_790B` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_f0536bbb6064\usbfilter.inf` | AMD USB Filter Driver | `{36FC9E60-C465-11CF-8056-444553540000}\usbfilter` | Device-class-specific ID | `usbfilter` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_f0536bbb6064\zenpromnf.inf` | ZenProM S0i3 Network Filter | `ZenProMnf` | Network software component ID | `Install` | Native | Native | Native | Native | NotDeclared |

## AMD Chipset Software 7.06.02.123

| INF | Device | Device identifier | Identifier type | Install section | WS2016 | WS2019 | WS2022 | WS2025 | WDF |
|---|---|---|---|---|---|---|---|---|---|
| `d3_Data1.cab_b76aed3733d3\amd3dvcache.inf` | AMD 3D V-Cache Performance Optimizer | `ACPI\AMDI0101` | ACPI-enumerated PnP hardware ID | `Amd3dvcache_Device` | No(Build) | No(Build) | Native | Native | KMDF 1.15 |
| `d3_Data1.cab_b76aed3733d3\amdappcompat.inf` | AMD Application Compatibility Database | `ACPI\AMDI0204` | ACPI-enumerated PnP hardware ID | `AmdAppCompat_Device` | No(Build) | Native | Native | Native | KMDF 1.15 |
| `d3_Data1.cab_b76aed3733d3\amdas4.inf` | AmdAS4 Device | `ACPI\AMDI0050` | ACPI-enumerated PnP hardware ID | `AmdAS4` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_b76aed3733d3\amdas4.inf` | AmdAS4 Device | `ACPI\ASD0001` | ACPI-enumerated PnP hardware ID | `AmdAS4` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_b76aed3733d3\amdcir.inf` | AMD CIR Driver | `*AMDC001` | Generic PnP hardware ID | `AMDCIR64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_b76aed3733d3\amdcir.inf` | AMD CIR Driver | `*AMDC002` | Generic PnP hardware ID | `AMDCIR64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_b76aed3733d3\amdcir.inf` | AMD CIR Driver | `*AMDC003` | Generic PnP hardware ID | `AMDCIR64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_b76aed3733d3\amdgpio2.inf` | AMD GPIO Controller | `ACPI\AMD0030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_b76aed3733d3\amdgpio2.inf` | AMD GPIO Controller | `ACPI\AMDI0030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_b76aed3733d3\amdgpio2.inf` | AMD GPIO Controller | `ACPI\AMDI0031` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_b76aed3733d3\amdgpio2.inf` | AMD GPIO Controller | `ACPI\GPIO0010` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_b76aed3733d3\amdgpio3.inf` | AMD GPIO Controller | `ACPI\AMDF030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_b76aed3733d3\amdgpio3.inf` | AMD GPIO Controller | `ACPI\AMDIF030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_b76aed3733d3\amdgpio3.inf` | AMD GPIO Controller | `ACPI\AMDIF031` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_b76aed3733d3\amdi2c.inf` | AMD I2C Controller | `ACPI\AMD0010` | ACPI-enumerated PnP hardware ID | `amdi2c_Device` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_b76aed3733d3\amdi2c.inf` | AMD I2C Controller | `ACPI\AMDI0010` | ACPI-enumerated PnP hardware ID | `amdi2c_Device` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_b76aed3733d3\amdinterface.inf` | AMD Hetero Driver | `ACPI\AMDI0104` | ACPI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_b76aed3733d3\amdinterface.inf` | AMD PCI | `PCI\VEN_1002&DEV_145A` | PCI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_b76aed3733d3\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_1116` | PCI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_b76aed3733d3\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_1117` | PCI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_b76aed3733d3\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_1136` | PCI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_b76aed3733d3\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_1137` | PCI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_b76aed3733d3\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_14AC` | PCI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_b76aed3733d3\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_14DC` | PCI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_b76aed3733d3\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_14DE` | PCI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_b76aed3733d3\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_14EC` | PCI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_b76aed3733d3\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_150D` | PCI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_b76aed3733d3\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_1556` | PCI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_b76aed3733d3\amdinterface.inf` | AMD SMBUS | `PCI\VEN_1022&DEV_790B` | PCI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_b76aed3733d3\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1002&DEV_5A23` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_b76aed3733d3\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_13E1` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_b76aed3733d3\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1419` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_b76aed3733d3\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1423` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_b76aed3733d3\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1437` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_b76aed3733d3\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1451` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_b76aed3733d3\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1481` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_b76aed3733d3\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1577` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_b76aed3733d3\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_164F` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_b76aed3733d3\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMD0004` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_b76aed3733d3\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMD0005` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_b76aed3733d3\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0005` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_b76aed3733d3\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0006` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_b76aed3733d3\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0007` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_b76aed3733d3\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0008` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_b76aed3733d3\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0009` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_b76aed3733d3\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI000A` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_b76aed3733d3\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI000B` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_b76aed3733d3\amdoemprov.inf` | AMD Provisioning for OEM | `ACPI\AMDI0053` | ACPI-enumerated PnP hardware ID | `AMDPPMPF_DEV` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `d3_Data1.cab_b76aed3733d3\amdpcidev.inf` | AMD PCI | `PCI\VEN_1002&DEV_145A` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_b76aed3733d3\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_1455` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_b76aed3733d3\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_145A` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_b76aed3733d3\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_1485` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_b76aed3733d3\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_148A` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_b76aed3733d3\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_14DE` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_b76aed3733d3\amdpmf.inf` | AMD PMF | `ACPI\AMDI0100` | ACPI-enumerated PnP hardware ID | `AMDPMF_INSTALL.NTamd64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_b76aed3733d3\amdpmf.inf` | AMD PMF | `ACPI\AMDI0102` | ACPI-enumerated PnP hardware ID | `AMDPMF_INSTALL.NTamd64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_b76aed3733d3\amdppkg.inf` | AMD Provisioning Packages | `ACPI\AMDI0052` | ACPI-enumerated PnP hardware ID | `InstallSection_Win10` | Native | Native | Native | No | NotDeclared |
| `d3_Data1.cab_b76aed3733d3\amdppkg.inf` | AMD Provisioning Packages | `ACPI\AMDI0052` | ACPI-enumerated PnP hardware ID | `InstallSection_Win11_22H2` | No | No | No | Native | NotDeclared |
| `d3_Data1.cab_b76aed3733d3\amdpsp.inf` | AMD PSP 10.0 Device | `PCI\VEN_1022&DEV_15DF` | PCI-enumerated PnP hardware ID | `amdpsp_Device_100` | Native | Native | Native | Native | KMDF 1.13 |
| `d3_Data1.cab_b76aed3733d3\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_1134` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | Native | Native | Native | KMDF 1.13 |
| `d3_Data1.cab_b76aed3733d3\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_1486` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | Native | Native | Native | KMDF 1.13 |
| `d3_Data1.cab_b76aed3733d3\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_14CA` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | Native | Native | Native | KMDF 1.13 |
| `d3_Data1.cab_b76aed3733d3\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_156E` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | Native | Native | Native | KMDF 1.13 |
| `d3_Data1.cab_b76aed3733d3\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_15C7` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | Native | Native | Native | KMDF 1.13 |
| `d3_Data1.cab_b76aed3733d3\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_1649` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | Native | Native | Native | KMDF 1.13 |
| `d3_Data1.cab_b76aed3733d3\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_17E0` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | Native | Native | Native | KMDF 1.13 |
| `d3_Data1.cab_b76aed3733d3\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_13EC` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | Native | Native | Native | KMDF 1.13 |
| `d3_Data1.cab_b76aed3733d3\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_1456` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | Native | Native | Native | KMDF 1.13 |
| `d3_Data1.cab_b76aed3733d3\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_1537` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | Native | Native | Native | KMDF 1.13 |
| `d3_Data1.cab_b76aed3733d3\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_1578` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | Native | Native | Native | KMDF 1.13 |
| `d3_Data1.cab_b76aed3733d3\amdsfhkmdf.inf` | AMD Sensor Fusion Hub | `PCI\VEN_1022&DEV_15E4` | PCI-enumerated PnP hardware ID | `amdsfhkmdf_Device` | Native | Native | Native | Native | KMDF 1.15 |
| `d3_Data1.cab_b76aed3733d3\amdsfhkmdfi2c.inf` | AMD SFH KMDF I2C | `PCI\VEN_1022&DEV_15E6` | PCI-enumerated PnP hardware ID | `amdsfhkmdf_Device` | Native | Native | Native | Native | KMDF 1.15 |
| `d3_Data1.cab_b76aed3733d3\amdsfhspbi2c.inf` | AMD SFH I2C Controller | `ACPI\AMDI0011` | ACPI-enumerated PnP hardware ID | `amdsfhspbi2c_Device` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_b76aed3733d3\amdsfhumdf.inf` | AMD UMDF Sensor | `ACPI\AMDI0080` | ACPI-enumerated PnP hardware ID | `amdsfhumdf_Inst_Win10` | No(Build) | Native | Native | No | UMDF 2.15.0 |
| `d3_Data1.cab_b76aed3733d3\amdsfhumdf.inf` | AMD UMDF Sensor | `ACPI\AMDI0080` | ACPI-enumerated PnP hardware ID | `amdsfhumdf_Inst_Win11` | No(Build) | No | No | Native | UMDF 2.15.0 |
| `d3_Data1.cab_b76aed3733d3\amduart.inf` | AMD UART Controller | `ACPI\AMD0020` | ACPI-enumerated PnP hardware ID | `amduart_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_b76aed3733d3\amduart.inf` | AMD UART Controller | `ACPI\AMDI0020` | ACPI-enumerated PnP hardware ID | `amduart_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_b76aed3733d3\amduart.inf` | AMD UART Controller | `ACPI\AMDI0022` | ACPI-enumerated PnP hardware ID | `amduart_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_b76aed3733d3\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_15C4` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `d3_Data1.cab_b76aed3733d3\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_15C5` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `d3_Data1.cab_b76aed3733d3\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_162E` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `d3_Data1.cab_b76aed3733d3\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_162F` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `d3_Data1.cab_b76aed3733d3\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_1668` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `d3_Data1.cab_b76aed3733d3\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_1669` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `d3_Data1.cab_b76aed3733d3\amdusb4net.inf` | AMD USB4NET | `{b85b7c50-6a01-11d2-b841-00c04fad5171}\AMDUSB4NET` | Device-class-specific ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_b76aed3733d3\amdusb4net.inf` | AMD USB4NET | `{b85b7c50-6a01-11d2-b841-00c04fad5171}\Usb4Net` | Device-class-specific ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_b76aed3733d3\amdusb4net.inf` | AMD USB4NET | `root\AMDUSB4NET_a` | Root-enumerated PnP hardware ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_b76aed3733d3\amdusb4net.inf` | AMD USB4NET | `root\AMDUSB4NET_b` | Root-enumerated PnP hardware ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_b76aed3733d3\amdusb4net.inf` | AMD USB4NET | `root\AMDUSB4NET_c` | Root-enumerated PnP hardware ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_b76aed3733d3\amdusb4net.inf` | AMD USB4NET | `root\AMDUSB4NET_d` | Root-enumerated PnP hardware ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_b76aed3733d3\amdusb4pcifilter.inf` | PCI Express Root Port | `PCI\VEN_1022&DEV_14CD&SUBSYS_14531022&REV_00` | PCI-enumerated PnP hardware ID | `amdusb4pcifilter` | Native | Native | Excluded | Excluded | NotDeclared |
| `d3_Data1.cab_b76aed3733d3\amdusb4pcifilter.inf` | PCI Express Root Port | `PCI\VEN_1022&DEV_14EF&SUBSYS_14531022&REV_00` | PCI-enumerated PnP hardware ID | `amdusb4pcifilter` | Native | Native | Excluded | Excluded | NotDeclared |
| `d3_Data1.cab_b76aed3733d3\amdusb4pcifilter.inf` | PCI Express Root Port | `PCI\VEN_1022&DEV_14EF&SUBSYS_14531022&REV_01` | PCI-enumerated PnP hardware ID | `amdusb4pcifilter` | Native | Native | Excluded | Excluded | NotDeclared |
| `d3_Data1.cab_b76aed3733d3\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15C0&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Excluded | Excluded | NotDeclared |
| `d3_Data1.cab_b76aed3733d3\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15C1&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Excluded | Excluded | NotDeclared |
| `d3_Data1.cab_b76aed3733d3\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15C2&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Excluded | Excluded | NotDeclared |
| `d3_Data1.cab_b76aed3733d3\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15C3&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Excluded | Excluded | NotDeclared |
| `d3_Data1.cab_b76aed3733d3\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15D6&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Excluded | Excluded | NotDeclared |
| `d3_Data1.cab_b76aed3733d3\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15D7&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Excluded | Excluded | NotDeclared |
| `d3_Data1.cab_b76aed3733d3\amdwirelessbutton.inf` | AMD Wireless Button Driver | `ACPI\AMDI0051` | ACPI-enumerated PnP hardware ID | `amdwirelessbutton_Device` | No(Build) | Native | Native | No | KMDF 1.15 |
| `d3_Data1.cab_b76aed3733d3\amdwirelessbutton.inf` | AMD Wireless Button Driver | `ACPI\AMDI0051` | ACPI-enumerated PnP hardware ID | `amdwirelessbutton_DeviceWin11` | No(Build) | No | No | Native | KMDF 1.15 |
| `d3_Data1.cab_b76aed3733d3\ams_mailboxdrv.inf` | AMS-MailBoxDrv | `ACPI\AMDI0090` | ACPI-enumerated PnP hardware ID | `AMS-MailBoxDrv_Device` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_b76aed3733d3\plutonnull.inf` | AMD NULL Driver for Microsoft Pluton Security Processor | `ACPI\MSFT0200` | ACPI-enumerated PnP hardware ID | `Null_Pluton_Device` | Native | Native | Native | Excluded | NotDeclared |
| `d3_Data1.cab_b76aed3733d3\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4353` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_b76aed3733d3\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4363` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_b76aed3733d3\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4372` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_b76aed3733d3\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4385` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_b76aed3733d3\smbusamd.inf` | AMD SMBus | `PCI\VEN_1022&DEV_780B` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_b76aed3733d3\smbusamd.inf` | AMD SMBus | `PCI\VEN_1022&DEV_790B` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_b76aed3733d3\usbfilter.inf` | AMD USB Filter Driver | `{36FC9E60-C465-11CF-8056-444553540000}\usbfilter` | Device-class-specific ID | `usbfilter` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_b76aed3733d3\zenpromnf.inf` | ZenProM S0i3 Network Filter | `ZenProMnf` | Network software component ID | `Install` | Native | Native | Native | Native | NotDeclared |

## AMD Chipset Software 7.04.09.545

| INF | Device | Device identifier | Identifier type | Install section | WS2016 | WS2019 | WS2022 | WS2025 | WDF |
|---|---|---|---|---|---|---|---|---|---|
| `d3_Data1.cab_f374c3c209f6\amd3dvcache.inf` | AMD 3D V-Cache Performance Optimizer | `ACPI\AMDI0101` | ACPI-enumerated PnP hardware ID | `Amd3dvcache_Device` | No(Build) | No(Build) | Native | Native | KMDF 1.15 |
| `d3_Data1.cab_f374c3c209f6\amdappcompat.inf` | AMD Application Compatibility Database | `ACPI\AMDI0204` | ACPI-enumerated PnP hardware ID | `AmdAppCompat_Device` | No(Build) | Native | Native | Native | KMDF 1.15 |
| `d3_Data1.cab_f374c3c209f6\amdas4.inf` | AmdAS4 Device | `ACPI\AMDI0050` | ACPI-enumerated PnP hardware ID | `AmdAS4` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_f374c3c209f6\amdas4.inf` | AmdAS4 Device | `ACPI\ASD0001` | ACPI-enumerated PnP hardware ID | `AmdAS4` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_f374c3c209f6\amdcir.inf` | AMD CIR Driver | `*AMDC001` | Generic PnP hardware ID | `AMDCIR64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_f374c3c209f6\amdcir.inf` | AMD CIR Driver | `*AMDC002` | Generic PnP hardware ID | `AMDCIR64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_f374c3c209f6\amdcir.inf` | AMD CIR Driver | `*AMDC003` | Generic PnP hardware ID | `AMDCIR64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_f374c3c209f6\amdgpio2.inf` | AMD GPIO Controller | `ACPI\AMD0030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_f374c3c209f6\amdgpio2.inf` | AMD GPIO Controller | `ACPI\AMDI0030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_f374c3c209f6\amdgpio2.inf` | AMD GPIO Controller | `ACPI\AMDI0031` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_f374c3c209f6\amdgpio2.inf` | AMD GPIO Controller | `ACPI\GPIO0010` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_f374c3c209f6\amdgpio3.inf` | AMD GPIO Controller | `ACPI\AMDF030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_f374c3c209f6\amdgpio3.inf` | AMD GPIO Controller | `ACPI\AMDIF030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_f374c3c209f6\amdgpio3.inf` | AMD GPIO Controller | `ACPI\AMDIF031` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_f374c3c209f6\amdi2c.inf` | AMD I2C Controller | `ACPI\AMD0010` | ACPI-enumerated PnP hardware ID | `amdi2c_Device` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_f374c3c209f6\amdi2c.inf` | AMD I2C Controller | `ACPI\AMDI0010` | ACPI-enumerated PnP hardware ID | `amdi2c_Device` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_f374c3c209f6\amdinterface.inf` | AMD Hetero Driver | `ACPI\AMDI0104` | ACPI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_f374c3c209f6\amdinterface.inf` | AMD PCI | `PCI\VEN_1002&DEV_145A` | PCI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_f374c3c209f6\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_1116` | PCI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_f374c3c209f6\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_1117` | PCI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_f374c3c209f6\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_1136` | PCI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_f374c3c209f6\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_1137` | PCI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_f374c3c209f6\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_14AC` | PCI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_f374c3c209f6\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_14DC` | PCI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_f374c3c209f6\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_14DE` | PCI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_f374c3c209f6\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_14EC` | PCI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_f374c3c209f6\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_150D` | PCI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_f374c3c209f6\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_1556` | PCI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_f374c3c209f6\amdinterface.inf` | AMD SMBUS | `PCI\VEN_1022&DEV_790B` | PCI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_f374c3c209f6\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1002&DEV_5A23` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_f374c3c209f6\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_13E1` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_f374c3c209f6\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1419` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_f374c3c209f6\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1423` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_f374c3c209f6\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1437` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_f374c3c209f6\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1451` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_f374c3c209f6\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1481` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_f374c3c209f6\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1577` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_f374c3c209f6\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_164F` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_f374c3c209f6\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMD0004` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_f374c3c209f6\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMD0005` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_f374c3c209f6\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0005` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_f374c3c209f6\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0006` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_f374c3c209f6\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0007` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_f374c3c209f6\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0008` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_f374c3c209f6\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0009` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_f374c3c209f6\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI000A` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_f374c3c209f6\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI000B` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_f374c3c209f6\amdoemprov.inf` | AMD Provisioning for OEM | `ACPI\AMDI0053` | ACPI-enumerated PnP hardware ID | `AMDPPMPF_DEV` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `d3_Data1.cab_f374c3c209f6\amdpcidev.inf` | AMD PCI | `PCI\VEN_1002&DEV_145A` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_f374c3c209f6\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_1455` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_f374c3c209f6\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_145A` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_f374c3c209f6\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_1485` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_f374c3c209f6\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_148A` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_f374c3c209f6\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_14DE` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_f374c3c209f6\amdpmf.inf` | AMD PMF | `ACPI\AMDI0100` | ACPI-enumerated PnP hardware ID | `AMDPMF_INSTALL.NTamd64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_f374c3c209f6\amdpmf.inf` | AMD PMF | `ACPI\AMDI0102` | ACPI-enumerated PnP hardware ID | `AMDPMF_INSTALL.NTamd64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_f374c3c209f6\amdppkg.inf` | AMD Provisioning Packages | `ACPI\AMDI0052` | ACPI-enumerated PnP hardware ID | `InstallSection_Win10` | Native | Native | Native | No | NotDeclared |
| `d3_Data1.cab_f374c3c209f6\amdppkg.inf` | AMD Provisioning Packages | `ACPI\AMDI0052` | ACPI-enumerated PnP hardware ID | `InstallSection_Win11_22H2` | No | No | No | Native | NotDeclared |
| `d3_Data1.cab_f374c3c209f6\amdpsp.inf` | AMD PSP 10.0 Device | `PCI\VEN_1022&DEV_15DF` | PCI-enumerated PnP hardware ID | `amdpsp_Device_100` | Native | Native | Native | Native | KMDF 1.13 |
| `d3_Data1.cab_f374c3c209f6\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_1134` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | Native | Native | Native | KMDF 1.13 |
| `d3_Data1.cab_f374c3c209f6\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_1486` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | Native | Native | Native | KMDF 1.13 |
| `d3_Data1.cab_f374c3c209f6\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_14CA` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | Native | Native | Native | KMDF 1.13 |
| `d3_Data1.cab_f374c3c209f6\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_156E` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | Native | Native | Native | KMDF 1.13 |
| `d3_Data1.cab_f374c3c209f6\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_15C7` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | Native | Native | Native | KMDF 1.13 |
| `d3_Data1.cab_f374c3c209f6\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_1649` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | Native | Native | Native | KMDF 1.13 |
| `d3_Data1.cab_f374c3c209f6\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_17E0` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | Native | Native | Native | KMDF 1.13 |
| `d3_Data1.cab_f374c3c209f6\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_13EC` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | Native | Native | Native | KMDF 1.13 |
| `d3_Data1.cab_f374c3c209f6\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_1456` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | Native | Native | Native | KMDF 1.13 |
| `d3_Data1.cab_f374c3c209f6\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_1537` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | Native | Native | Native | KMDF 1.13 |
| `d3_Data1.cab_f374c3c209f6\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_1578` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | Native | Native | Native | KMDF 1.13 |
| `d3_Data1.cab_f374c3c209f6\amdsfhkmdf.inf` | AMD Sensor Fusion Hub | `PCI\VEN_1022&DEV_15E4` | PCI-enumerated PnP hardware ID | `amdsfhkmdf_Device` | Native | Native | Native | Native | KMDF 1.15 |
| `d3_Data1.cab_f374c3c209f6\amdsfhkmdfi2c.inf` | AMD SFH KMDF I2C | `PCI\VEN_1022&DEV_15E6` | PCI-enumerated PnP hardware ID | `amdsfhkmdf_Device` | Native | Native | Native | Native | KMDF 1.15 |
| `d3_Data1.cab_f374c3c209f6\amdsfhspbi2c.inf` | AMD SFH I2C Controller | `ACPI\AMDI0011` | ACPI-enumerated PnP hardware ID | `amdsfhspbi2c_Device` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_f374c3c209f6\amdsfhumdf.inf` | AMD UMDF Sensor | `ACPI\AMDI0080` | ACPI-enumerated PnP hardware ID | `amdsfhumdf_Inst_Win10` | No(Build) | Native | Native | No | UMDF 2.15.0 |
| `d3_Data1.cab_f374c3c209f6\amdsfhumdf.inf` | AMD UMDF Sensor | `ACPI\AMDI0080` | ACPI-enumerated PnP hardware ID | `amdsfhumdf_Inst_Win11` | No(Build) | No | No | Native | UMDF 2.15.0 |
| `d3_Data1.cab_f374c3c209f6\amduart.inf` | AMD UART Controller | `ACPI\AMD0020` | ACPI-enumerated PnP hardware ID | `amduart_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_f374c3c209f6\amduart.inf` | AMD UART Controller | `ACPI\AMDI0020` | ACPI-enumerated PnP hardware ID | `amduart_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_f374c3c209f6\amduart.inf` | AMD UART Controller | `ACPI\AMDI0022` | ACPI-enumerated PnP hardware ID | `amduart_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_f374c3c209f6\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_15C4` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `d3_Data1.cab_f374c3c209f6\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_15C5` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `d3_Data1.cab_f374c3c209f6\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_162E` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `d3_Data1.cab_f374c3c209f6\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_162F` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `d3_Data1.cab_f374c3c209f6\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_1668` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `d3_Data1.cab_f374c3c209f6\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_1669` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `d3_Data1.cab_f374c3c209f6\amdusb4net.inf` | AMD USB4NET | `{b85b7c50-6a01-11d2-b841-00c04fad5171}\AMDUSB4NET` | Device-class-specific ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_f374c3c209f6\amdusb4net.inf` | AMD USB4NET | `{b85b7c50-6a01-11d2-b841-00c04fad5171}\Usb4Net` | Device-class-specific ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_f374c3c209f6\amdusb4net.inf` | AMD USB4NET | `root\AMDUSB4NET_a` | Root-enumerated PnP hardware ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_f374c3c209f6\amdusb4net.inf` | AMD USB4NET | `root\AMDUSB4NET_b` | Root-enumerated PnP hardware ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_f374c3c209f6\amdusb4net.inf` | AMD USB4NET | `root\AMDUSB4NET_c` | Root-enumerated PnP hardware ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_f374c3c209f6\amdusb4net.inf` | AMD USB4NET | `root\AMDUSB4NET_d` | Root-enumerated PnP hardware ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_f374c3c209f6\amdusb4pcifilter.inf` | PCI Express Root Port | `PCI\VEN_1022&DEV_14CD&SUBSYS_14531022&REV_00` | PCI-enumerated PnP hardware ID | `amdusb4pcifilter` | Native | Native | Excluded | Excluded | NotDeclared |
| `d3_Data1.cab_f374c3c209f6\amdusb4pcifilter.inf` | PCI Express Root Port | `PCI\VEN_1022&DEV_14EF&SUBSYS_14531022&REV_00` | PCI-enumerated PnP hardware ID | `amdusb4pcifilter` | Native | Native | Excluded | Excluded | NotDeclared |
| `d3_Data1.cab_f374c3c209f6\amdusb4pcifilter.inf` | PCI Express Root Port | `PCI\VEN_1022&DEV_14EF&SUBSYS_14531022&REV_01` | PCI-enumerated PnP hardware ID | `amdusb4pcifilter` | Native | Native | Excluded | Excluded | NotDeclared |
| `d3_Data1.cab_f374c3c209f6\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15C0&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Excluded | Excluded | NotDeclared |
| `d3_Data1.cab_f374c3c209f6\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15C1&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Excluded | Excluded | NotDeclared |
| `d3_Data1.cab_f374c3c209f6\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15C2&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Excluded | Excluded | NotDeclared |
| `d3_Data1.cab_f374c3c209f6\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15C3&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Excluded | Excluded | NotDeclared |
| `d3_Data1.cab_f374c3c209f6\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15D6&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Excluded | Excluded | NotDeclared |
| `d3_Data1.cab_f374c3c209f6\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15D7&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Excluded | Excluded | NotDeclared |
| `d3_Data1.cab_f374c3c209f6\amdwirelessbutton.inf` | AMD Wireless Button Driver | `ACPI\AMDI0051` | ACPI-enumerated PnP hardware ID | `amdwirelessbutton_Device` | No(Build) | Native | Native | No | KMDF 1.15 |
| `d3_Data1.cab_f374c3c209f6\amdwirelessbutton.inf` | AMD Wireless Button Driver | `ACPI\AMDI0051` | ACPI-enumerated PnP hardware ID | `amdwirelessbutton_DeviceWin11` | No(Build) | No | No | Native | KMDF 1.15 |
| `d3_Data1.cab_f374c3c209f6\ams_mailboxdrv.inf` | AMS-MailBoxDrv | `ACPI\AMDI0090` | ACPI-enumerated PnP hardware ID | `AMS-MailBoxDrv_Device` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_f374c3c209f6\plutonnull.inf` | AMD NULL Driver for Microsoft Pluton Security Processor | `ACPI\MSFT0200` | ACPI-enumerated PnP hardware ID | `Null_Pluton_Device` | Native | Native | Native | Excluded | NotDeclared |
| `d3_Data1.cab_f374c3c209f6\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4353` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_f374c3c209f6\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4363` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_f374c3c209f6\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4372` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_f374c3c209f6\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4385` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_f374c3c209f6\smbusamd.inf` | AMD SMBus | `PCI\VEN_1022&DEV_780B` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_f374c3c209f6\smbusamd.inf` | AMD SMBus | `PCI\VEN_1022&DEV_790B` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_f374c3c209f6\usbfilter.inf` | AMD USB Filter Driver | `{36FC9E60-C465-11CF-8056-444553540000}\usbfilter` | Device-class-specific ID | `usbfilter` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_f374c3c209f6\zenpromnf.inf` | ZenProM S0i3 Network Filter | `ZenProMnf` | Network software component ID | `Install` | Native | Native | Native | Native | NotDeclared |

## AMD Chipset Software 7.02.13.148

| INF | Device | Device identifier | Identifier type | Install section | WS2016 | WS2019 | WS2022 | WS2025 | WDF |
|---|---|---|---|---|---|---|---|---|---|
| `d3_Data1.cab_5122568ba8e8\amd3dvcache.inf` | AMD 3D V-Cache Performance Optimizer | `ACPI\AMDI0101` | ACPI-enumerated PnP hardware ID | `Amd3dvcache_Device` | No(Build) | No(Build) | Native | Native | KMDF 1.15 |
| `d3_Data1.cab_5122568ba8e8\amdappcompat.inf` | AMD Application Compatibility Database | `ACPI\AMDI0204` | ACPI-enumerated PnP hardware ID | `AmdAppCompat_Device` | No(Build) | Native | Native | Native | KMDF 1.15 |
| `d3_Data1.cab_5122568ba8e8\amdas4.inf` | AmdAS4 Device | `ACPI\AMDI0050` | ACPI-enumerated PnP hardware ID | `AmdAS4` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_5122568ba8e8\amdas4.inf` | AmdAS4 Device | `ACPI\ASD0001` | ACPI-enumerated PnP hardware ID | `AmdAS4` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_5122568ba8e8\amdcir.inf` | AMD CIR Driver | `*AMDC001` | Generic PnP hardware ID | `AMDCIR64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_5122568ba8e8\amdcir.inf` | AMD CIR Driver | `*AMDC002` | Generic PnP hardware ID | `AMDCIR64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_5122568ba8e8\amdcir.inf` | AMD CIR Driver | `*AMDC003` | Generic PnP hardware ID | `AMDCIR64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_5122568ba8e8\amdgpio2.inf` | AMD GPIO Controller | `ACPI\AMD0030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_5122568ba8e8\amdgpio2.inf` | AMD GPIO Controller | `ACPI\AMDI0030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_5122568ba8e8\amdgpio2.inf` | AMD GPIO Controller | `ACPI\AMDI0031` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_5122568ba8e8\amdgpio2.inf` | AMD GPIO Controller | `ACPI\GPIO0010` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_5122568ba8e8\amdgpio3.inf` | AMD GPIO Controller | `ACPI\AMDF030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_5122568ba8e8\amdgpio3.inf` | AMD GPIO Controller | `ACPI\AMDIF030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_5122568ba8e8\amdgpio3.inf` | AMD GPIO Controller | `ACPI\AMDIF031` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_5122568ba8e8\amdi2c.inf` | AMD I2C Controller | `ACPI\AMD0010` | ACPI-enumerated PnP hardware ID | `amdi2c_Device` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_5122568ba8e8\amdi2c.inf` | AMD I2C Controller | `ACPI\AMDI0010` | ACPI-enumerated PnP hardware ID | `amdi2c_Device` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_5122568ba8e8\amdinterface.inf` | AMD Hetero Driver | `ACPI\AMDI0104` | ACPI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_5122568ba8e8\amdinterface.inf` | AMD PCI | `PCI\VEN_1002&DEV_145A` | PCI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_5122568ba8e8\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_1116` | PCI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_5122568ba8e8\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_1117` | PCI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_5122568ba8e8\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_1136` | PCI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_5122568ba8e8\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_14AC` | PCI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_5122568ba8e8\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_14DC` | PCI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_5122568ba8e8\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_14DE` | PCI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_5122568ba8e8\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_14EC` | PCI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_5122568ba8e8\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_150D` | PCI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_5122568ba8e8\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_1556` | PCI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_5122568ba8e8\amdinterface.inf` | AMD SMBUS | `PCI\VEN_1022&DEV_790B` | PCI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_5122568ba8e8\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1002&DEV_5A23` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_5122568ba8e8\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_13E1` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_5122568ba8e8\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1419` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_5122568ba8e8\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1423` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_5122568ba8e8\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1437` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_5122568ba8e8\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1451` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_5122568ba8e8\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1481` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_5122568ba8e8\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1577` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_5122568ba8e8\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_164F` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_5122568ba8e8\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMD0004` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_5122568ba8e8\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMD0005` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_5122568ba8e8\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0005` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_5122568ba8e8\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0006` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_5122568ba8e8\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0007` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_5122568ba8e8\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0008` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_5122568ba8e8\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0009` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_5122568ba8e8\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI000A` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_5122568ba8e8\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI000B` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_5122568ba8e8\amdoemprov.inf` | AMD Provisioning for OEM | `ACPI\AMDI0053` | ACPI-enumerated PnP hardware ID | `AMDPPMPF_DEV` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `d3_Data1.cab_5122568ba8e8\amdpcidev.inf` | AMD PCI | `PCI\VEN_1002&DEV_145A` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_5122568ba8e8\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_1455` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_5122568ba8e8\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_145A` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_5122568ba8e8\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_1485` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_5122568ba8e8\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_148A` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_5122568ba8e8\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_14DE` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_5122568ba8e8\amdpmf.inf` | AMD PMF | `ACPI\AMDI0100` | ACPI-enumerated PnP hardware ID | `AMDPMF_INSTALL.NTamd64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_5122568ba8e8\amdpmf.inf` | AMD PMF | `ACPI\AMDI0102` | ACPI-enumerated PnP hardware ID | `AMDPMF_INSTALL.NTamd64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_5122568ba8e8\amdppkg.inf` | AMD Provisioning Packages | `ACPI\AMDI0052` | ACPI-enumerated PnP hardware ID | `InstallSection_Win10` | Native | Native | Native | No | NotDeclared |
| `d3_Data1.cab_5122568ba8e8\amdppkg.inf` | AMD Provisioning Packages | `ACPI\AMDI0052` | ACPI-enumerated PnP hardware ID | `InstallSection_Win11_22H2` | No | No | No | Native | NotDeclared |
| `d3_Data1.cab_5122568ba8e8\amdpsp.inf` | AMD PSP 10.0 Device | `PCI\VEN_1022&DEV_15DF` | PCI-enumerated PnP hardware ID | `amdpsp_Device_100` | Native | Native | Native | Native | KMDF 1.13 |
| `d3_Data1.cab_5122568ba8e8\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_1134` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | Native | Native | Native | KMDF 1.13 |
| `d3_Data1.cab_5122568ba8e8\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_1486` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | Native | Native | Native | KMDF 1.13 |
| `d3_Data1.cab_5122568ba8e8\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_14CA` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | Native | Native | Native | KMDF 1.13 |
| `d3_Data1.cab_5122568ba8e8\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_156E` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | Native | Native | Native | KMDF 1.13 |
| `d3_Data1.cab_5122568ba8e8\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_15C7` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | Native | Native | Native | KMDF 1.13 |
| `d3_Data1.cab_5122568ba8e8\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_1649` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | Native | Native | Native | KMDF 1.13 |
| `d3_Data1.cab_5122568ba8e8\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_17E0` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | Native | Native | Native | KMDF 1.13 |
| `d3_Data1.cab_5122568ba8e8\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_13EC` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | Native | Native | Native | KMDF 1.13 |
| `d3_Data1.cab_5122568ba8e8\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_1456` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | Native | Native | Native | KMDF 1.13 |
| `d3_Data1.cab_5122568ba8e8\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_1537` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | Native | Native | Native | KMDF 1.13 |
| `d3_Data1.cab_5122568ba8e8\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_1578` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | Native | Native | Native | KMDF 1.13 |
| `d3_Data1.cab_5122568ba8e8\amdsfhkmdf.inf` | AMD Sensor Fusion Hub | `PCI\VEN_1022&DEV_15E4` | PCI-enumerated PnP hardware ID | `amdsfhkmdf_Device` | Native | Native | Native | Native | KMDF 1.15 |
| `d3_Data1.cab_5122568ba8e8\amdsfhkmdfi2c.inf` | AMD SFH KMDF I2C | `PCI\VEN_1022&DEV_15E6` | PCI-enumerated PnP hardware ID | `amdsfhkmdf_Device` | Native | Native | Native | Native | KMDF 1.15 |
| `d3_Data1.cab_5122568ba8e8\amdsfhspbi2c.inf` | AMD SFH I2C Controller | `ACPI\AMDI0011` | ACPI-enumerated PnP hardware ID | `amdsfhspbi2c_Device` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_5122568ba8e8\amdsfhumdf.inf` | AMD UMDF Sensor | `ACPI\AMDI0080` | ACPI-enumerated PnP hardware ID | `amdsfhumdf_Inst_Win10` | No(Build) | Native | Native | No | UMDF 2.15.0 |
| `d3_Data1.cab_5122568ba8e8\amdsfhumdf.inf` | AMD UMDF Sensor | `ACPI\AMDI0080` | ACPI-enumerated PnP hardware ID | `amdsfhumdf_Inst_Win11` | No(Build) | No | No | Native | UMDF 2.15.0 |
| `d3_Data1.cab_5122568ba8e8\amduart.inf` | AMD UART Controller | `ACPI\AMD0020` | ACPI-enumerated PnP hardware ID | `amduart_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_5122568ba8e8\amduart.inf` | AMD UART Controller | `ACPI\AMDI0020` | ACPI-enumerated PnP hardware ID | `amduart_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_5122568ba8e8\amduart.inf` | AMD UART Controller | `ACPI\AMDI0022` | ACPI-enumerated PnP hardware ID | `amduart_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_5122568ba8e8\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_15C4` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `d3_Data1.cab_5122568ba8e8\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_15C5` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `d3_Data1.cab_5122568ba8e8\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_162E` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `d3_Data1.cab_5122568ba8e8\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_162F` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `d3_Data1.cab_5122568ba8e8\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_1668` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `d3_Data1.cab_5122568ba8e8\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_1669` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `d3_Data1.cab_5122568ba8e8\amdusb4net.inf` | AMD USB4NET | `{b85b7c50-6a01-11d2-b841-00c04fad5171}\AMDUSB4NET` | Device-class-specific ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_5122568ba8e8\amdusb4net.inf` | AMD USB4NET | `{b85b7c50-6a01-11d2-b841-00c04fad5171}\Usb4Net` | Device-class-specific ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_5122568ba8e8\amdusb4net.inf` | AMD USB4NET | `root\AMDUSB4NET_a` | Root-enumerated PnP hardware ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_5122568ba8e8\amdusb4net.inf` | AMD USB4NET | `root\AMDUSB4NET_b` | Root-enumerated PnP hardware ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_5122568ba8e8\amdusb4net.inf` | AMD USB4NET | `root\AMDUSB4NET_c` | Root-enumerated PnP hardware ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_5122568ba8e8\amdusb4net.inf` | AMD USB4NET | `root\AMDUSB4NET_d` | Root-enumerated PnP hardware ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_5122568ba8e8\amdusb4pcifilter.inf` | PCI Express Root Port | `PCI\VEN_1022&DEV_14CD&SUBSYS_14531022&REV_00` | PCI-enumerated PnP hardware ID | `amdusb4pcifilter` | Native | Native | Excluded | Excluded | NotDeclared |
| `d3_Data1.cab_5122568ba8e8\amdusb4pcifilter.inf` | PCI Express Root Port | `PCI\VEN_1022&DEV_14EF&SUBSYS_14531022&REV_00` | PCI-enumerated PnP hardware ID | `amdusb4pcifilter` | Native | Native | Excluded | Excluded | NotDeclared |
| `d3_Data1.cab_5122568ba8e8\amdusb4pcifilter.inf` | PCI Express Root Port | `PCI\VEN_1022&DEV_14EF&SUBSYS_14531022&REV_01` | PCI-enumerated PnP hardware ID | `amdusb4pcifilter` | Native | Native | Excluded | Excluded | NotDeclared |
| `d3_Data1.cab_5122568ba8e8\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15C0&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Excluded | Excluded | NotDeclared |
| `d3_Data1.cab_5122568ba8e8\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15C1&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Excluded | Excluded | NotDeclared |
| `d3_Data1.cab_5122568ba8e8\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15C2&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Excluded | Excluded | NotDeclared |
| `d3_Data1.cab_5122568ba8e8\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15C3&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Excluded | Excluded | NotDeclared |
| `d3_Data1.cab_5122568ba8e8\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15D6&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Excluded | Excluded | NotDeclared |
| `d3_Data1.cab_5122568ba8e8\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15D7&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Excluded | Excluded | NotDeclared |
| `d3_Data1.cab_5122568ba8e8\amdwirelessbutton.inf` | AMD Wireless Button Driver | `ACPI\AMDI0051` | ACPI-enumerated PnP hardware ID | `amdwirelessbutton_Device` | No(Build) | Native | Native | No | KMDF 1.15 |
| `d3_Data1.cab_5122568ba8e8\amdwirelessbutton.inf` | AMD Wireless Button Driver | `ACPI\AMDI0051` | ACPI-enumerated PnP hardware ID | `amdwirelessbutton_DeviceWin11` | No(Build) | No | No | Native | KMDF 1.15 |
| `d3_Data1.cab_5122568ba8e8\ams_mailboxdrv.inf` | AMS-MailBoxDrv | `ACPI\AMDI0090` | ACPI-enumerated PnP hardware ID | `AMS-MailBoxDrv_Device` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_5122568ba8e8\plutonnull.inf` | AMD NULL Driver for Microsoft Pluton Security Processor | `ACPI\MSFT0200` | ACPI-enumerated PnP hardware ID | `Null_Pluton_Device` | Native | Native | Native | Excluded | NotDeclared |
| `d3_Data1.cab_5122568ba8e8\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4353` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_5122568ba8e8\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4363` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_5122568ba8e8\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4372` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_5122568ba8e8\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4385` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_5122568ba8e8\smbusamd.inf` | AMD SMBus | `PCI\VEN_1022&DEV_780B` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_5122568ba8e8\smbusamd.inf` | AMD SMBus | `PCI\VEN_1022&DEV_790B` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_5122568ba8e8\usbfilter.inf` | AMD USB Filter Driver | `{36FC9E60-C465-11CF-8056-444553540000}\usbfilter` | Device-class-specific ID | `usbfilter` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_5122568ba8e8\zenpromnf.inf` | ZenProM S0i3 Network Filter | `ZenProMnf` | Network software component ID | `Install` | Native | Native | Native | Native | NotDeclared |

## AMD Chipset Software 6.10.17.152

| INF | Device | Device identifier | Identifier type | Install section | WS2016 | WS2019 | WS2022 | WS2025 | WDF |
|---|---|---|---|---|---|---|---|---|---|
| `d3_Data1.cab_ade74ab63b6e\amd3dvcache.inf` | AMD 3D V-Cache Performance Optimizer | `ACPI\AMDI0101` | ACPI-enumerated PnP hardware ID | `amd3dvcache_Device` | No(Build) | No(Build) | Native | Native | KMDF 1.15 |
| `d3_Data1.cab_ade74ab63b6e\amdas4.inf` | AmdAS4 Device | `ACPI\AMDI0050` | ACPI-enumerated PnP hardware ID | `AmdAS4` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_ade74ab63b6e\amdas4.inf` | AmdAS4 Device | `ACPI\ASD0001` | ACPI-enumerated PnP hardware ID | `AmdAS4` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_ade74ab63b6e\amdcir.inf` | AMD CIR Driver | `*AMDC001` | Generic PnP hardware ID | `AMDCIR64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_ade74ab63b6e\amdcir.inf` | AMD CIR Driver | `*AMDC002` | Generic PnP hardware ID | `AMDCIR64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_ade74ab63b6e\amdcir.inf` | AMD CIR Driver | `*AMDC003` | Generic PnP hardware ID | `AMDCIR64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_ade74ab63b6e\amdgpio2.inf` | AMD GPIO Controller | `ACPI\AMD0030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_ade74ab63b6e\amdgpio2.inf` | AMD GPIO Controller | `ACPI\AMDI0030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_ade74ab63b6e\amdgpio2.inf` | AMD GPIO Controller | `ACPI\AMDI0031` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_ade74ab63b6e\amdgpio2.inf` | AMD GPIO Controller | `ACPI\GPIO0010` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_ade74ab63b6e\amdgpio3.inf` | AMD GPIO Controller | `ACPI\AMDF030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_ade74ab63b6e\amdgpio3.inf` | AMD GPIO Controller | `ACPI\AMDIF030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_ade74ab63b6e\amdgpio3.inf` | AMD GPIO Controller | `ACPI\AMDIF031` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_ade74ab63b6e\amdi2c.inf` | AMD I2C Controller | `ACPI\AMD0010` | ACPI-enumerated PnP hardware ID | `amdi2c_Device` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_ade74ab63b6e\amdi2c.inf` | AMD I2C Controller | `ACPI\AMDI0010` | ACPI-enumerated PnP hardware ID | `amdi2c_Device` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_ade74ab63b6e\amdinterface.inf` | AMD Hetero Driver | `ACPI\AMDI0104` | ACPI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_ade74ab63b6e\amdinterface.inf` | AMD PCI | `PCI\VEN_1002&DEV_145A` | PCI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_ade74ab63b6e\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_1116` | PCI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_ade74ab63b6e\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_14AC` | PCI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_ade74ab63b6e\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_14DC` | PCI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_ade74ab63b6e\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_14DE` | PCI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_ade74ab63b6e\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_14EC` | PCI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_ade74ab63b6e\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_150D` | PCI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_ade74ab63b6e\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_1556` | PCI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_ade74ab63b6e\amdinterface.inf` | AMD SMBUS | `PCI\VEN_1022&DEV_790B` | PCI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_ade74ab63b6e\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1002&DEV_5A23` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_ade74ab63b6e\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_13E1` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_ade74ab63b6e\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1419` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_ade74ab63b6e\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1423` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_ade74ab63b6e\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1437` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_ade74ab63b6e\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1451` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_ade74ab63b6e\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1481` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_ade74ab63b6e\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1577` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_ade74ab63b6e\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_164F` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_ade74ab63b6e\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMD0004` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_ade74ab63b6e\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMD0005` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_ade74ab63b6e\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0005` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_ade74ab63b6e\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0006` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_ade74ab63b6e\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0007` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_ade74ab63b6e\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0008` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_ade74ab63b6e\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0009` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_ade74ab63b6e\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI000A` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_ade74ab63b6e\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI000B` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_ade74ab63b6e\amdoemprov.inf` | AMD Provisioning for OEM | `ACPI\AMDI0053` | ACPI-enumerated PnP hardware ID | `AMDPPMPF_DEV` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `d3_Data1.cab_ade74ab63b6e\amdpcidev.inf` | AMD PCI | `PCI\VEN_1002&DEV_145A` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_ade74ab63b6e\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_1455` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_ade74ab63b6e\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_145A` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_ade74ab63b6e\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_1485` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_ade74ab63b6e\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_148A` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_ade74ab63b6e\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_14DE` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_ade74ab63b6e\amdpmf.inf` | AMD PMF | `ACPI\AMDI0100` | ACPI-enumerated PnP hardware ID | `AMDPMF_INSTALL.NTamd64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_ade74ab63b6e\amdpmf.inf` | AMD PMF | `ACPI\AMDI0102` | ACPI-enumerated PnP hardware ID | `AMDPMF_INSTALL.NTamd64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_ade74ab63b6e\amdppkg.inf` | AMD Provisioning Packages | `ACPI\AMDI0052` | ACPI-enumerated PnP hardware ID | `InstallSection_Win10` | Native | Native | Native | No | NotDeclared |
| `d3_Data1.cab_ade74ab63b6e\amdppkg.inf` | AMD Provisioning Packages | `ACPI\AMDI0052` | ACPI-enumerated PnP hardware ID | `InstallSection_Win11` | No | No | No | Native | NotDeclared |
| `d3_Data1.cab_ade74ab63b6e\amdpsp.inf` | AMD PSP 10.0 Device | `PCI\VEN_1022&DEV_15DF` | PCI-enumerated PnP hardware ID | `amdpsp_Device_100` | Native | Native | Native | Native | KMDF 1.13 |
| `d3_Data1.cab_ade74ab63b6e\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_1486` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | Native | Native | Native | KMDF 1.13 |
| `d3_Data1.cab_ade74ab63b6e\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_14CA` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | Native | Native | Native | KMDF 1.13 |
| `d3_Data1.cab_ade74ab63b6e\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_156E` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | Native | Native | Native | KMDF 1.13 |
| `d3_Data1.cab_ade74ab63b6e\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_15C7` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | Native | Native | Native | KMDF 1.13 |
| `d3_Data1.cab_ade74ab63b6e\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_1649` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | Native | Native | Native | KMDF 1.13 |
| `d3_Data1.cab_ade74ab63b6e\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_17E0` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | Native | Native | Native | KMDF 1.13 |
| `d3_Data1.cab_ade74ab63b6e\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_13EC` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | Native | Native | Native | KMDF 1.13 |
| `d3_Data1.cab_ade74ab63b6e\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_1456` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | Native | Native | Native | KMDF 1.13 |
| `d3_Data1.cab_ade74ab63b6e\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_1537` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | Native | Native | Native | KMDF 1.13 |
| `d3_Data1.cab_ade74ab63b6e\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_1578` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | Native | Native | Native | KMDF 1.13 |
| `d3_Data1.cab_ade74ab63b6e\amdsfhkmdf.inf` | AMD Sensor Fusion Hub | `PCI\VEN_1022&DEV_15E4` | PCI-enumerated PnP hardware ID | `amdsfhkmdf_Device` | Native | Native | Native | Native | KMDF 1.15 |
| `d3_Data1.cab_ade74ab63b6e\amdsfhkmdfi2c.inf` | AMD SFH KMDF I2C | `PCI\VEN_1022&DEV_15E6` | PCI-enumerated PnP hardware ID | `amdsfhkmdf_Device` | Native | Native | Native | Native | KMDF 1.15 |
| `d3_Data1.cab_ade74ab63b6e\amdsfhspbi2c.inf` | AMD SFH I2C Controller | `ACPI\AMDI0011` | ACPI-enumerated PnP hardware ID | `amdsfhspbi2c_Device` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_ade74ab63b6e\amdsfhumdf.inf` | AMD UMDF Sensor | `ACPI\AMDI0080` | ACPI-enumerated PnP hardware ID | `amdsfhumdf_Inst_Win10` | No(Build) | Native | Native | No | UMDF 2.15.0 |
| `d3_Data1.cab_ade74ab63b6e\amdsfhumdf.inf` | AMD UMDF Sensor | `ACPI\AMDI0080` | ACPI-enumerated PnP hardware ID | `amdsfhumdf_Inst_Win11` | No(Build) | No | No | Native | UMDF 2.15.0 |
| `d3_Data1.cab_ade74ab63b6e\amduart.inf` | AMD UART Controller | `ACPI\AMD0020` | ACPI-enumerated PnP hardware ID | `amduart_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_ade74ab63b6e\amduart.inf` | AMD UART Controller | `ACPI\AMDI0020` | ACPI-enumerated PnP hardware ID | `amduart_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_ade74ab63b6e\amduart.inf` | AMD UART Controller | `ACPI\AMDI0022` | ACPI-enumerated PnP hardware ID | `amduart_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_ade74ab63b6e\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_15C4` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `d3_Data1.cab_ade74ab63b6e\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_15C5` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `d3_Data1.cab_ade74ab63b6e\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_162E` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `d3_Data1.cab_ade74ab63b6e\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_162F` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `d3_Data1.cab_ade74ab63b6e\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_1668` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `d3_Data1.cab_ade74ab63b6e\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_1669` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `d3_Data1.cab_ade74ab63b6e\amdusb4net.inf` | AMD USB4NET | `{b85b7c50-6a01-11d2-b841-00c04fad5171}\AMDUSB4NET` | Device-class-specific ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_ade74ab63b6e\amdusb4net.inf` | AMD USB4NET | `{b85b7c50-6a01-11d2-b841-00c04fad5171}\Usb4Net` | Device-class-specific ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_ade74ab63b6e\amdusb4net.inf` | AMD USB4NET | `root\AMDUSB4NET_a` | Root-enumerated PnP hardware ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_ade74ab63b6e\amdusb4net.inf` | AMD USB4NET | `root\AMDUSB4NET_b` | Root-enumerated PnP hardware ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_ade74ab63b6e\amdusb4net.inf` | AMD USB4NET | `root\AMDUSB4NET_c` | Root-enumerated PnP hardware ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_ade74ab63b6e\amdusb4net.inf` | AMD USB4NET | `root\AMDUSB4NET_d` | Root-enumerated PnP hardware ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_ade74ab63b6e\amdusb4pcifilter.inf` | PCI Express Root Port | `PCI\VEN_1022&DEV_14CD&SUBSYS_14531022&REV_00` | PCI-enumerated PnP hardware ID | `amdusb4pcifilter` | Native | Native | Excluded | Excluded | NotDeclared |
| `d3_Data1.cab_ade74ab63b6e\amdusb4pcifilter.inf` | PCI Express Root Port | `PCI\VEN_1022&DEV_14EF&SUBSYS_14531022&REV_00` | PCI-enumerated PnP hardware ID | `amdusb4pcifilter` | Native | Native | Excluded | Excluded | NotDeclared |
| `d3_Data1.cab_ade74ab63b6e\amdusb4pcifilter.inf` | PCI Express Root Port | `PCI\VEN_1022&DEV_14EF&SUBSYS_14531022&REV_01` | PCI-enumerated PnP hardware ID | `amdusb4pcifilter` | Native | Native | Excluded | Excluded | NotDeclared |
| `d3_Data1.cab_ade74ab63b6e\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15C0&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Excluded | Excluded | NotDeclared |
| `d3_Data1.cab_ade74ab63b6e\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15C1&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Excluded | Excluded | NotDeclared |
| `d3_Data1.cab_ade74ab63b6e\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15C2&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Excluded | Excluded | NotDeclared |
| `d3_Data1.cab_ade74ab63b6e\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15C3&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Excluded | Excluded | NotDeclared |
| `d3_Data1.cab_ade74ab63b6e\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15D6&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Excluded | Excluded | NotDeclared |
| `d3_Data1.cab_ade74ab63b6e\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15D7&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Excluded | Excluded | NotDeclared |
| `d3_Data1.cab_ade74ab63b6e\amdwirelessbutton.inf` | AMD Wireless Button Driver | `ACPI\AMDI0051` | ACPI-enumerated PnP hardware ID | `amdwirelessbutton_Device` | No(Build) | Native | Native | No | KMDF 1.15 |
| `d3_Data1.cab_ade74ab63b6e\amdwirelessbutton.inf` | AMD Wireless Button Driver | `ACPI\AMDI0051` | ACPI-enumerated PnP hardware ID | `amdwirelessbutton_DeviceWin11` | No(Build) | No | No | Native | KMDF 1.15 |
| `d3_Data1.cab_ade74ab63b6e\ams_mailboxdrv.inf` | AMS-MailBoxDrv | `ACPI\AMDI0090` | ACPI-enumerated PnP hardware ID | `AMS-MailBoxDrv_Device` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_ade74ab63b6e\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4353` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_ade74ab63b6e\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4363` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_ade74ab63b6e\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4372` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_ade74ab63b6e\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4385` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_ade74ab63b6e\smbusamd.inf` | AMD SMBus | `PCI\VEN_1022&DEV_780B` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_ade74ab63b6e\smbusamd.inf` | AMD SMBus | `PCI\VEN_1022&DEV_790B` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_ade74ab63b6e\usbfilter.inf` | AMD USB Filter Driver | `{36FC9E60-C465-11CF-8056-444553540000}\usbfilter` | Device-class-specific ID | `usbfilter` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_ade74ab63b6e\zenpromnf.inf` | ZenProM S0i3 Network Filter | `ZenProMnf` | Network software component ID | `Install` | Native | Native | Native | Native | NotDeclared |

## AMD Chipset Software 6.07.22.037

| INF | Device | Device identifier | Identifier type | Install section | WS2016 | WS2019 | WS2022 | WS2025 | WDF |
|---|---|---|---|---|---|---|---|---|---|
| `d3_Data1.cab_c83e731d9acc\amd3dvcache.inf` | AMD 3D V-Cache Performance Optimizer | `ACPI\AMDI0101` | ACPI-enumerated PnP hardware ID | `amd3dvcache_Device` | No(Build) | No(Build) | Native | Native | KMDF 1.15 |
| `d3_Data1.cab_c83e731d9acc\amdas4.inf` | AmdAS4 Device | `ACPI\AMDI0050` | ACPI-enumerated PnP hardware ID | `AmdAS4` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_c83e731d9acc\amdas4.inf` | AmdAS4 Device | `ACPI\ASD0001` | ACPI-enumerated PnP hardware ID | `AmdAS4` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_c83e731d9acc\amdcir.inf` | AMD CIR Driver | `*AMDC001` | Generic PnP hardware ID | `AMDCIR64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_c83e731d9acc\amdcir.inf` | AMD CIR Driver | `*AMDC002` | Generic PnP hardware ID | `AMDCIR64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_c83e731d9acc\amdcir.inf` | AMD CIR Driver | `*AMDC003` | Generic PnP hardware ID | `AMDCIR64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_c83e731d9acc\amdgpio2.inf` | AMD GPIO Controller | `ACPI\AMD0030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_c83e731d9acc\amdgpio2.inf` | AMD GPIO Controller | `ACPI\AMDI0030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_c83e731d9acc\amdgpio2.inf` | AMD GPIO Controller | `ACPI\AMDI0031` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_c83e731d9acc\amdgpio2.inf` | AMD GPIO Controller | `ACPI\GPIO0010` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_c83e731d9acc\amdgpio3.inf` | AMD GPIO Controller | `ACPI\AMDF030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_c83e731d9acc\amdgpio3.inf` | AMD GPIO Controller | `ACPI\AMDIF030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_c83e731d9acc\amdgpio3.inf` | AMD GPIO Controller | `ACPI\AMDIF031` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_c83e731d9acc\amdi2c.inf` | AMD I2C Controller | `ACPI\AMD0010` | ACPI-enumerated PnP hardware ID | `amdi2c_Device` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_c83e731d9acc\amdi2c.inf` | AMD I2C Controller | `ACPI\AMDI0010` | ACPI-enumerated PnP hardware ID | `amdi2c_Device` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_c83e731d9acc\amdinterface.inf` | AMD Hetero Driver | `ACPI\AMDI0104` | ACPI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_c83e731d9acc\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_1116` | PCI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_c83e731d9acc\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_14AC` | PCI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_c83e731d9acc\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_14DC` | PCI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_c83e731d9acc\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_14DE` | PCI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_c83e731d9acc\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_14EC` | PCI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_c83e731d9acc\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_150D` | PCI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_c83e731d9acc\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_1556` | PCI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_c83e731d9acc\amdinterface.inf` | AMD SMBUS | `PCI\VEN_1022&DEV_790B` | PCI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_c83e731d9acc\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1002&DEV_5A23` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_c83e731d9acc\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_13E1` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_c83e731d9acc\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1419` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_c83e731d9acc\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1423` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_c83e731d9acc\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1437` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_c83e731d9acc\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1451` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_c83e731d9acc\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1481` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_c83e731d9acc\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1577` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_c83e731d9acc\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_164F` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_c83e731d9acc\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMD0004` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_c83e731d9acc\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMD0005` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_c83e731d9acc\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0005` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_c83e731d9acc\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0006` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_c83e731d9acc\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0007` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_c83e731d9acc\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0008` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_c83e731d9acc\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0009` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_c83e731d9acc\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI000A` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_c83e731d9acc\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI000B` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_c83e731d9acc\amdoemprov.inf` | AMD Provisioning for OEM | `ACPI\AMDI0053` | ACPI-enumerated PnP hardware ID | `AMDPPMPF_DEV` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `d3_Data1.cab_c83e731d9acc\amdpcidev.inf` | AMD PCI | `PCI\VEN_1002&DEV_145A` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_c83e731d9acc\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_1455` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_c83e731d9acc\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_145A` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_c83e731d9acc\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_1485` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_c83e731d9acc\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_148A` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_c83e731d9acc\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_14DE` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_c83e731d9acc\amdpmf.inf` | AMD PMF | `ACPI\AMDI0100` | ACPI-enumerated PnP hardware ID | `AMDPMF_INSTALL.NTamd64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_c83e731d9acc\amdpmf.inf` | AMD PMF | `ACPI\AMDI0102` | ACPI-enumerated PnP hardware ID | `AMDPMF_INSTALL.NTamd64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_c83e731d9acc\amdppmpf.inf` | AMD PPM Provisioning File | `ACPI\AMDI0052` | ACPI-enumerated PnP hardware ID | `AMDPPMPF_DEV` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_c83e731d9acc\amdpsp.inf` | AMD PSP 10.0 Device | `PCI\VEN_1022&DEV_15DF` | PCI-enumerated PnP hardware ID | `amdpsp_Device_100` | Native | Native | Native | Native | KMDF 1.13 |
| `d3_Data1.cab_c83e731d9acc\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_1486` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | Native | Native | Native | KMDF 1.13 |
| `d3_Data1.cab_c83e731d9acc\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_14CA` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | Native | Native | Native | KMDF 1.13 |
| `d3_Data1.cab_c83e731d9acc\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_156E` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | Native | Native | Native | KMDF 1.13 |
| `d3_Data1.cab_c83e731d9acc\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_15C7` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | Native | Native | Native | KMDF 1.13 |
| `d3_Data1.cab_c83e731d9acc\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_1649` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | Native | Native | Native | KMDF 1.13 |
| `d3_Data1.cab_c83e731d9acc\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_17E0` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | Native | Native | Native | KMDF 1.13 |
| `d3_Data1.cab_c83e731d9acc\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_13EC` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | Native | Native | Native | KMDF 1.13 |
| `d3_Data1.cab_c83e731d9acc\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_1456` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | Native | Native | Native | KMDF 1.13 |
| `d3_Data1.cab_c83e731d9acc\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_1537` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | Native | Native | Native | KMDF 1.13 |
| `d3_Data1.cab_c83e731d9acc\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_1578` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | Native | Native | Native | KMDF 1.13 |
| `d3_Data1.cab_c83e731d9acc\amdsfhkmdf.inf` | AMD Sensor Fusion Hub | `PCI\VEN_1022&DEV_15E4` | PCI-enumerated PnP hardware ID | `amdsfhkmdf_Device` | Native | Native | Native | Native | KMDF 1.15 |
| `d3_Data1.cab_c83e731d9acc\amdsfhkmdfi2c.inf` | AMD SFH KMDF I2C | `PCI\VEN_1022&DEV_15E6` | PCI-enumerated PnP hardware ID | `amdsfhkmdf_Device` | Native | Native | Native | Native | KMDF 1.15 |
| `d3_Data1.cab_c83e731d9acc\amdsfhspbi2c.inf` | AMD SFH I2C Controller | `ACPI\AMDI0011` | ACPI-enumerated PnP hardware ID | `amdsfhspbi2c_Device` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_c83e731d9acc\amdsfhumdf.inf` | AMD UMDF Sensor | `ACPI\AMDI0080` | ACPI-enumerated PnP hardware ID | `amdsfhumdf_Inst_Win10` | No(Build) | Native | Native | No | UMDF 2.15.0 |
| `d3_Data1.cab_c83e731d9acc\amdsfhumdf.inf` | AMD UMDF Sensor | `ACPI\AMDI0080` | ACPI-enumerated PnP hardware ID | `amdsfhumdf_Inst_Win11` | No(Build) | No | No | Native | UMDF 2.15.0 |
| `d3_Data1.cab_c83e731d9acc\amduart.inf` | AMD UART Controller | `ACPI\AMD0020` | ACPI-enumerated PnP hardware ID | `amduart_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_c83e731d9acc\amduart.inf` | AMD UART Controller | `ACPI\AMDI0020` | ACPI-enumerated PnP hardware ID | `amduart_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_c83e731d9acc\amduart.inf` | AMD UART Controller | `ACPI\AMDI0022` | ACPI-enumerated PnP hardware ID | `amduart_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_c83e731d9acc\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_15C4` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `d3_Data1.cab_c83e731d9acc\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_15C5` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `d3_Data1.cab_c83e731d9acc\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_162E` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `d3_Data1.cab_c83e731d9acc\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_162F` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `d3_Data1.cab_c83e731d9acc\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_1668` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `d3_Data1.cab_c83e731d9acc\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_1669` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `d3_Data1.cab_c83e731d9acc\amdusb4net.inf` | AMD USB4NET | `{b85b7c50-6a01-11d2-b841-00c04fad5171}\AMDUSB4NET` | Device-class-specific ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_c83e731d9acc\amdusb4net.inf` | AMD USB4NET | `{b85b7c50-6a01-11d2-b841-00c04fad5171}\Usb4Net` | Device-class-specific ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_c83e731d9acc\amdusb4net.inf` | AMD USB4NET | `root\AMDUSB4NET_a` | Root-enumerated PnP hardware ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_c83e731d9acc\amdusb4net.inf` | AMD USB4NET | `root\AMDUSB4NET_b` | Root-enumerated PnP hardware ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_c83e731d9acc\amdusb4net.inf` | AMD USB4NET | `root\AMDUSB4NET_c` | Root-enumerated PnP hardware ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_c83e731d9acc\amdusb4net.inf` | AMD USB4NET | `root\AMDUSB4NET_d` | Root-enumerated PnP hardware ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_c83e731d9acc\amdusb4pcifilter.inf` | PCI Express Root Port | `PCI\VEN_1022&DEV_14CD&SUBSYS_14531022&REV_00` | PCI-enumerated PnP hardware ID | `amdusb4pcifilter` | Native | Native | Excluded | Excluded | NotDeclared |
| `d3_Data1.cab_c83e731d9acc\amdusb4pcifilter.inf` | PCI Express Root Port | `PCI\VEN_1022&DEV_14EF&SUBSYS_14531022&REV_00` | PCI-enumerated PnP hardware ID | `amdusb4pcifilter` | Native | Native | Excluded | Excluded | NotDeclared |
| `d3_Data1.cab_c83e731d9acc\amdusb4pcifilter.inf` | PCI Express Root Port | `PCI\VEN_1022&DEV_14EF&SUBSYS_14531022&REV_01` | PCI-enumerated PnP hardware ID | `amdusb4pcifilter` | Native | Native | Excluded | Excluded | NotDeclared |
| `d3_Data1.cab_c83e731d9acc\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15C0&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Excluded | Excluded | NotDeclared |
| `d3_Data1.cab_c83e731d9acc\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15C1&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Excluded | Excluded | NotDeclared |
| `d3_Data1.cab_c83e731d9acc\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15C2&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Excluded | Excluded | NotDeclared |
| `d3_Data1.cab_c83e731d9acc\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15C3&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Excluded | Excluded | NotDeclared |
| `d3_Data1.cab_c83e731d9acc\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15D6&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Excluded | Excluded | NotDeclared |
| `d3_Data1.cab_c83e731d9acc\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15D7&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Excluded | Excluded | NotDeclared |
| `d3_Data1.cab_c83e731d9acc\amdwirelessbutton.inf` | AMD Wireless Button Driver | `ACPI\AMDI0051` | ACPI-enumerated PnP hardware ID | `amdwirelessbutton_Device` | No(Build) | Native | Native | No | KMDF 1.15 |
| `d3_Data1.cab_c83e731d9acc\amdwirelessbutton.inf` | AMD Wireless Button Driver | `ACPI\AMDI0051` | ACPI-enumerated PnP hardware ID | `amdwirelessbutton_DeviceWin11` | No(Build) | No | No | Native | KMDF 1.15 |
| `d3_Data1.cab_c83e731d9acc\ams_mailboxdrv.inf` | AMS-MailBoxDrv | `ACPI\AMDI0090` | ACPI-enumerated PnP hardware ID | `AMS-MailBoxDrv_Device` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_c83e731d9acc\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4353` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_c83e731d9acc\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4363` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_c83e731d9acc\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4372` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_c83e731d9acc\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4385` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_c83e731d9acc\smbusamd.inf` | AMD SMBus | `PCI\VEN_1022&DEV_780B` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_c83e731d9acc\smbusamd.inf` | AMD SMBus | `PCI\VEN_1022&DEV_790B` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_c83e731d9acc\usbfilter.inf` | AMD USB Filter Driver | `{36FC9E60-C465-11CF-8056-444553540000}\usbfilter` | Device-class-specific ID | `usbfilter` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_c83e731d9acc\zenpromnf.inf` | ZenProM S0i3 Network Filter | `ZenProMnf` | Network software component ID | `Install` | Native | Native | Native | Native | NotDeclared |

## AMD Chipset Software 6.05.28.016

| INF | Device | Device identifier | Identifier type | Install section | WS2016 | WS2019 | WS2022 | WS2025 | WDF |
|---|---|---|---|---|---|---|---|---|---|
| `d3_Data1.cab_a0f54bf860e1\amd3dvcache.inf` | AMD 3D V-Cache Performance Optimizer | `ACPI\AMDI0101` | ACPI-enumerated PnP hardware ID | `amd3dvcache_Device` | No(Build) | No(Build) | Native | Native | KMDF 1.15 |
| `d3_Data1.cab_a0f54bf860e1\amdas4.inf` | AmdAS4 Device | `ACPI\AMDI0050` | ACPI-enumerated PnP hardware ID | `AmdAS4` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_a0f54bf860e1\amdas4.inf` | AmdAS4 Device | `ACPI\ASD0001` | ACPI-enumerated PnP hardware ID | `AmdAS4` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_a0f54bf860e1\amdcir.inf` | AMD CIR Driver | `*AMDC001` | Generic PnP hardware ID | `AMDCIR64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_a0f54bf860e1\amdcir.inf` | AMD CIR Driver | `*AMDC002` | Generic PnP hardware ID | `AMDCIR64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_a0f54bf860e1\amdcir.inf` | AMD CIR Driver | `*AMDC003` | Generic PnP hardware ID | `AMDCIR64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_a0f54bf860e1\amdgpio2.inf` | AMD GPIO Controller | `ACPI\AMD0030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_a0f54bf860e1\amdgpio2.inf` | AMD GPIO Controller | `ACPI\AMDI0030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_a0f54bf860e1\amdgpio2.inf` | AMD GPIO Controller | `ACPI\AMDI0031` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_a0f54bf860e1\amdgpio2.inf` | AMD GPIO Controller | `ACPI\GPIO0010` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_a0f54bf860e1\amdgpio3.inf` | AMD GPIO Controller | `ACPI\AMDF030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_a0f54bf860e1\amdgpio3.inf` | AMD GPIO Controller | `ACPI\AMDIF030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_a0f54bf860e1\amdgpio3.inf` | AMD GPIO Controller | `ACPI\AMDIF031` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_a0f54bf860e1\amdi2c.inf` | AMD I2C Controller | `ACPI\AMD0010` | ACPI-enumerated PnP hardware ID | `amdi2c_Device` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_a0f54bf860e1\amdi2c.inf` | AMD I2C Controller | `ACPI\AMDI0010` | ACPI-enumerated PnP hardware ID | `amdi2c_Device` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_a0f54bf860e1\amdinterface.inf` | AMD Hetero Driver | `ACPI\AMDI0104` | ACPI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_a0f54bf860e1\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_14AC` | PCI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_a0f54bf860e1\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_14DE` | PCI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_a0f54bf860e1\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_14EC` | PCI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_a0f54bf860e1\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_150D` | PCI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_a0f54bf860e1\amdinterface.inf` | AMD SMBUS | `PCI\VEN_1022&DEV_790B` | PCI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_a0f54bf860e1\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1002&DEV_5A23` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_a0f54bf860e1\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_13E1` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_a0f54bf860e1\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1419` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_a0f54bf860e1\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1423` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_a0f54bf860e1\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1437` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_a0f54bf860e1\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1451` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_a0f54bf860e1\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1481` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_a0f54bf860e1\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1577` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_a0f54bf860e1\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_164F` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_a0f54bf860e1\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMD0004` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_a0f54bf860e1\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMD0005` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_a0f54bf860e1\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0005` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_a0f54bf860e1\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0006` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_a0f54bf860e1\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0007` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_a0f54bf860e1\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0008` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_a0f54bf860e1\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0009` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_a0f54bf860e1\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI000A` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_a0f54bf860e1\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI000B` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_a0f54bf860e1\amdoemprov.inf` | AMD Provisioning for OEM | `ACPI\AMDI0053` | ACPI-enumerated PnP hardware ID | `AMDPPMPF_DEV` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `d3_Data1.cab_a0f54bf860e1\amdpcidev.inf` | AMD PCI | `PCI\VEN_1002&DEV_145A` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_a0f54bf860e1\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_1455` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_a0f54bf860e1\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_145A` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_a0f54bf860e1\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_1485` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_a0f54bf860e1\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_148A` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_a0f54bf860e1\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_14DE` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_a0f54bf860e1\amdpmf.inf` | AMD PMF | `ACPI\AMDI0100` | ACPI-enumerated PnP hardware ID | `AMDPMF_INSTALL.NTamd64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_a0f54bf860e1\amdpmf.inf` | AMD PMF | `ACPI\AMDI0102` | ACPI-enumerated PnP hardware ID | `AMDPMF_INSTALL.NTamd64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_a0f54bf860e1\amdppmpf.inf` | AMD PPM Provisioning File | `ACPI\AMDI0052` | ACPI-enumerated PnP hardware ID | `AMDPPMPF_DEV` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_a0f54bf860e1\amdpsp.inf` | AMD PSP 10.0 Device | `PCI\VEN_1022&DEV_15DF` | PCI-enumerated PnP hardware ID | `amdpsp_Device_100` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_a0f54bf860e1\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_1486` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_a0f54bf860e1\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_14CA` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_a0f54bf860e1\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_15C7` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_a0f54bf860e1\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_1649` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_a0f54bf860e1\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_17E0` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_a0f54bf860e1\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_13EC` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_a0f54bf860e1\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_1456` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_a0f54bf860e1\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_1537` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_a0f54bf860e1\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_1578` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_a0f54bf860e1\amdsfhkmdf.inf` | AMD Sensor Fusion Hub | `PCI\VEN_1022&DEV_15E4` | PCI-enumerated PnP hardware ID | `amdsfhkmdf_Device` | Native | Native | Native | Native | KMDF 1.15 |
| `d3_Data1.cab_a0f54bf860e1\amdsfhkmdfi2c.inf` | AMD SFH KMDF I2C | `PCI\VEN_1022&DEV_15E6` | PCI-enumerated PnP hardware ID | `amdsfhkmdf_Device` | Native | Native | Native | Native | KMDF 1.15 |
| `d3_Data1.cab_a0f54bf860e1\amdsfhspbi2c.inf` | AMD SFH I2C Controller | `ACPI\AMDI0011` | ACPI-enumerated PnP hardware ID | `amdsfhspbi2c_Device` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_a0f54bf860e1\amdsfhumdf.inf` | AMD UMDF Sensor | `ACPI\AMDI0080` | ACPI-enumerated PnP hardware ID | `amdsfhumdf_Inst_Win10` | No(Build) | Native | Native | No | UMDF 2.15.0 |
| `d3_Data1.cab_a0f54bf860e1\amdsfhumdf.inf` | AMD UMDF Sensor | `ACPI\AMDI0080` | ACPI-enumerated PnP hardware ID | `amdsfhumdf_Inst_Win11` | No(Build) | No | No | Native | UMDF 2.15.0 |
| `d3_Data1.cab_a0f54bf860e1\amduart.inf` | AMD UART Controller | `ACPI\AMD0020` | ACPI-enumerated PnP hardware ID | `amduart_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_a0f54bf860e1\amduart.inf` | AMD UART Controller | `ACPI\AMDI0020` | ACPI-enumerated PnP hardware ID | `amduart_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_a0f54bf860e1\amduart.inf` | AMD UART Controller | `ACPI\AMDI0022` | ACPI-enumerated PnP hardware ID | `amduart_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_a0f54bf860e1\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_15C4` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `d3_Data1.cab_a0f54bf860e1\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_15C5` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `d3_Data1.cab_a0f54bf860e1\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_162E` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `d3_Data1.cab_a0f54bf860e1\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_162F` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `d3_Data1.cab_a0f54bf860e1\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_1668` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `d3_Data1.cab_a0f54bf860e1\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_1669` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `d3_Data1.cab_a0f54bf860e1\amdusb4net.inf` | AMD USB4NET | `{b85b7c50-6a01-11d2-b841-00c04fad5171}\AMDUSB4NET` | Device-class-specific ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_a0f54bf860e1\amdusb4net.inf` | AMD USB4NET | `{b85b7c50-6a01-11d2-b841-00c04fad5171}\Usb4Net` | Device-class-specific ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_a0f54bf860e1\amdusb4net.inf` | AMD USB4NET | `root\AMDUSB4NET_a` | Root-enumerated PnP hardware ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_a0f54bf860e1\amdusb4net.inf` | AMD USB4NET | `root\AMDUSB4NET_b` | Root-enumerated PnP hardware ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_a0f54bf860e1\amdusb4net.inf` | AMD USB4NET | `root\AMDUSB4NET_c` | Root-enumerated PnP hardware ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_a0f54bf860e1\amdusb4net.inf` | AMD USB4NET | `root\AMDUSB4NET_d` | Root-enumerated PnP hardware ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_a0f54bf860e1\amdusb4pcifilter.inf` | PCI Express Root Port | `PCI\VEN_1022&DEV_14CD&SUBSYS_14531022&REV_00` | PCI-enumerated PnP hardware ID | `amdusb4pcifilter` | Native | Native | Excluded | Excluded | NotDeclared |
| `d3_Data1.cab_a0f54bf860e1\amdusb4pcifilter.inf` | PCI Express Root Port | `PCI\VEN_1022&DEV_14EF&SUBSYS_14531022&REV_00` | PCI-enumerated PnP hardware ID | `amdusb4pcifilter` | Native | Native | Excluded | Excluded | NotDeclared |
| `d3_Data1.cab_a0f54bf860e1\amdusb4pcifilter.inf` | PCI Express Root Port | `PCI\VEN_1022&DEV_14EF&SUBSYS_14531022&REV_01` | PCI-enumerated PnP hardware ID | `amdusb4pcifilter` | Native | Native | Excluded | Excluded | NotDeclared |
| `d3_Data1.cab_a0f54bf860e1\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15C0&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Excluded | Excluded | NotDeclared |
| `d3_Data1.cab_a0f54bf860e1\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15C1&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Excluded | Excluded | NotDeclared |
| `d3_Data1.cab_a0f54bf860e1\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15C2&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Excluded | Excluded | NotDeclared |
| `d3_Data1.cab_a0f54bf860e1\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15C3&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Excluded | Excluded | NotDeclared |
| `d3_Data1.cab_a0f54bf860e1\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15D6&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Excluded | Excluded | NotDeclared |
| `d3_Data1.cab_a0f54bf860e1\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15D7&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Excluded | Excluded | NotDeclared |
| `d3_Data1.cab_a0f54bf860e1\amdwirelessbutton.inf` | AMD Wireless Button Driver | `ACPI\AMDI0051` | ACPI-enumerated PnP hardware ID | `amdwirelessbutton_Device` | No(Build) | Native | Native | No | KMDF 1.15 |
| `d3_Data1.cab_a0f54bf860e1\amdwirelessbutton.inf` | AMD Wireless Button Driver | `ACPI\AMDI0051` | ACPI-enumerated PnP hardware ID | `amdwirelessbutton_DeviceWin11` | No(Build) | No | No | Native | KMDF 1.15 |
| `d3_Data1.cab_a0f54bf860e1\ams_mailboxdrv.inf` | AMS-MailBoxDrv | `ACPI\AMDI0090` | ACPI-enumerated PnP hardware ID | `AMS-MailBoxDrv_Device` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_a0f54bf860e1\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4353` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_a0f54bf860e1\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4363` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_a0f54bf860e1\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4372` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_a0f54bf860e1\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4385` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_a0f54bf860e1\smbusamd.inf` | AMD SMBus | `PCI\VEN_1022&DEV_780B` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_a0f54bf860e1\smbusamd.inf` | AMD SMBus | `PCI\VEN_1022&DEV_790B` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_a0f54bf860e1\usbfilter.inf` | AMD USB Filter Driver | `{36FC9E60-C465-11CF-8056-444553540000}\usbfilter` | Device-class-specific ID | `usbfilter` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_a0f54bf860e1\zenpromnf.inf` | ZenProM S0i3 Network Filter | `ZenProMnf` | Network software component ID | `Install` | Native | Native | Native | Native | NotDeclared |

## AMD Chipset Software 6.02.07.2300

| INF | Device | Device identifier | Identifier type | Install section | WS2016 | WS2019 | WS2022 | WS2025 | WDF |
|---|---|---|---|---|---|---|---|---|---|
| `d3_Data1.cab_4332c77f57b6\amd3dvcache.inf` | AMD 3D V-Cache Performance Optimizer | `ACPI\AMDI0101` | ACPI-enumerated PnP hardware ID | `amd3dvcache_Device` | No(Build) | No(Build) | Native | Native | KMDF 1.15 |
| `d3_Data1.cab_4332c77f57b6\amdas4.inf` | AmdAS4 Device | `ACPI\AMDI0050` | ACPI-enumerated PnP hardware ID | `AmdAS4` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_4332c77f57b6\amdas4.inf` | AmdAS4 Device | `ACPI\ASD0001` | ACPI-enumerated PnP hardware ID | `AmdAS4` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_4332c77f57b6\amdcir.inf` | AMD CIR Driver | `*AMDC001` | Generic PnP hardware ID | `AMDCIR64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_4332c77f57b6\amdcir.inf` | AMD CIR Driver | `*AMDC002` | Generic PnP hardware ID | `AMDCIR64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_4332c77f57b6\amdcir.inf` | AMD CIR Driver | `*AMDC003` | Generic PnP hardware ID | `AMDCIR64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_4332c77f57b6\amdgpio2.inf` | AMD GPIO Controller | `ACPI\AMD0030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_4332c77f57b6\amdgpio2.inf` | AMD GPIO Controller | `ACPI\AMDI0030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_4332c77f57b6\amdgpio2.inf` | AMD GPIO Controller | `ACPI\AMDI0031` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_4332c77f57b6\amdgpio2.inf` | AMD GPIO Controller | `ACPI\GPIO0010` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_4332c77f57b6\amdgpio3.inf` | AMD GPIO Controller | `ACPI\AMDF030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_4332c77f57b6\amdgpio3.inf` | AMD GPIO Controller | `ACPI\AMDIF030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_4332c77f57b6\amdgpio3.inf` | AMD GPIO Controller | `ACPI\AMDIF031` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_4332c77f57b6\amdi2c.inf` | AMD I2C Controller | `ACPI\AMD0010` | ACPI-enumerated PnP hardware ID | `amdi2c_Device` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_4332c77f57b6\amdi2c.inf` | AMD I2C Controller | `ACPI\AMDI0010` | ACPI-enumerated PnP hardware ID | `amdi2c_Device` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_4332c77f57b6\amdinterface.inf` | AMD Hetero Driver | `ACPI\AMDI0104` | ACPI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_4332c77f57b6\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_14AC` | PCI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_4332c77f57b6\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_14EC` | PCI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_4332c77f57b6\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_150D` | PCI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_4332c77f57b6\amdinterface.inf` | AMD SMBUS | `PCI\VEN_1022&DEV_790B` | PCI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_4332c77f57b6\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1002&DEV_5A23` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_4332c77f57b6\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_13E1` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_4332c77f57b6\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1419` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_4332c77f57b6\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1423` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_4332c77f57b6\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1437` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_4332c77f57b6\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1451` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_4332c77f57b6\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1481` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_4332c77f57b6\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1577` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_4332c77f57b6\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_164F` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_4332c77f57b6\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMD0004` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_4332c77f57b6\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMD0005` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_4332c77f57b6\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0005` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_4332c77f57b6\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0006` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_4332c77f57b6\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0007` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_4332c77f57b6\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0008` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_4332c77f57b6\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0009` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_4332c77f57b6\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI000A` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_4332c77f57b6\amdpcidev.inf` | AMD PCI | `PCI\VEN_1002&DEV_145A` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_4332c77f57b6\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_1455` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_4332c77f57b6\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_145A` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_4332c77f57b6\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_1485` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_4332c77f57b6\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_148A` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_4332c77f57b6\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_14DE` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_4332c77f57b6\amdpmf.inf` | AMD PMF | `ACPI\AMDI0100` | ACPI-enumerated PnP hardware ID | `AMDPMF_INSTALL.NTamd64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_4332c77f57b6\amdpmf.inf` | AMD PMF | `ACPI\AMDI0102` | ACPI-enumerated PnP hardware ID | `AMDPMF_INSTALL.NTamd64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_4332c77f57b6\amdppmpf.inf` | AMD PPM Provisioning File | `ACPI\AMDI0052` | ACPI-enumerated PnP hardware ID | `AMDPPMPF_DEV` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_4332c77f57b6\amdpsp.inf` | AMD PSP 10.0 Device | `PCI\VEN_1022&DEV_15DF` | PCI-enumerated PnP hardware ID | `amdpsp_Device_100` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_4332c77f57b6\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_1486` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_4332c77f57b6\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_14CA` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_4332c77f57b6\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_15C7` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_4332c77f57b6\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_1649` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_4332c77f57b6\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_17E0` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_4332c77f57b6\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_13EC` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_4332c77f57b6\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_1456` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_4332c77f57b6\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_1537` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_4332c77f57b6\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_1578` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_4332c77f57b6\amdsfhkmdf.inf` | AMD Sensor Fusion Hub | `PCI\VEN_1022&DEV_15E4` | PCI-enumerated PnP hardware ID | `amdsfhkmdf_Device` | Native | Native | Native | Native | KMDF 1.15 |
| `d3_Data1.cab_4332c77f57b6\amdsfhkmdfi2c.inf` | AMD SFH KMDF I2C | `PCI\VEN_1022&DEV_15E6` | PCI-enumerated PnP hardware ID | `amdsfhkmdf_Device` | Native | Native | Native | Native | KMDF 1.15 |
| `d3_Data1.cab_4332c77f57b6\amdsfhspbi2c.inf` | AMD SFH I2C Controller | `ACPI\AMDI0011` | ACPI-enumerated PnP hardware ID | `amdsfhspbi2c_Device` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_4332c77f57b6\amdsfhumdf.inf` | AMD UMDF Sensor | `ACPI\AMDI0080` | ACPI-enumerated PnP hardware ID | `amdsfhumdf_Inst` | Native | Native | Native | Native | UMDF 2.15.0 |
| `d3_Data1.cab_4332c77f57b6\amduart.inf` | AMD UART Controller | `ACPI\AMD0020` | ACPI-enumerated PnP hardware ID | `amduart_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_4332c77f57b6\amduart.inf` | AMD UART Controller | `ACPI\AMDI0020` | ACPI-enumerated PnP hardware ID | `amduart_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_4332c77f57b6\amduart.inf` | AMD UART Controller | `ACPI\AMDI0022` | ACPI-enumerated PnP hardware ID | `amduart_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_4332c77f57b6\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_15C4` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `d3_Data1.cab_4332c77f57b6\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_15C5` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `d3_Data1.cab_4332c77f57b6\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_162E` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `d3_Data1.cab_4332c77f57b6\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_162F` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `d3_Data1.cab_4332c77f57b6\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_1668` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `d3_Data1.cab_4332c77f57b6\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_1669` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `d3_Data1.cab_4332c77f57b6\amdusb4net.inf` | AMD USB4NET | `{b85b7c50-6a01-11d2-b841-00c04fad5171}\AMDUSB4NET` | Device-class-specific ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_4332c77f57b6\amdusb4net.inf` | AMD USB4NET | `{b85b7c50-6a01-11d2-b841-00c04fad5171}\Usb4Net` | Device-class-specific ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_4332c77f57b6\amdusb4net.inf` | AMD USB4NET | `root\AMDUSB4NET_a` | Root-enumerated PnP hardware ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_4332c77f57b6\amdusb4net.inf` | AMD USB4NET | `root\AMDUSB4NET_b` | Root-enumerated PnP hardware ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_4332c77f57b6\amdusb4net.inf` | AMD USB4NET | `root\AMDUSB4NET_c` | Root-enumerated PnP hardware ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_4332c77f57b6\amdusb4net.inf` | AMD USB4NET | `root\AMDUSB4NET_d` | Root-enumerated PnP hardware ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_4332c77f57b6\amdusb4pcifilter.inf` | PCI Express Root Port | `PCI\VEN_1022&DEV_14CD&SUBSYS_14531022&REV_00` | PCI-enumerated PnP hardware ID | `amdusb4pcifilter` | Native | Native | Excluded | Excluded | NotDeclared |
| `d3_Data1.cab_4332c77f57b6\amdusb4pcifilter.inf` | PCI Express Root Port | `PCI\VEN_1022&DEV_14EF&SUBSYS_14531022&REV_00` | PCI-enumerated PnP hardware ID | `amdusb4pcifilter` | Native | Native | Excluded | Excluded | NotDeclared |
| `d3_Data1.cab_4332c77f57b6\amdusb4pcifilter.inf` | PCI Express Root Port | `PCI\VEN_1022&DEV_14EF&SUBSYS_14531022&REV_01` | PCI-enumerated PnP hardware ID | `amdusb4pcifilter` | Native | Native | Excluded | Excluded | NotDeclared |
| `d3_Data1.cab_4332c77f57b6\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15C0&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Excluded | Excluded | NotDeclared |
| `d3_Data1.cab_4332c77f57b6\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15C1&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Excluded | Excluded | NotDeclared |
| `d3_Data1.cab_4332c77f57b6\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15C2&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Excluded | Excluded | NotDeclared |
| `d3_Data1.cab_4332c77f57b6\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15C3&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Excluded | Excluded | NotDeclared |
| `d3_Data1.cab_4332c77f57b6\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15D6&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Excluded | Excluded | NotDeclared |
| `d3_Data1.cab_4332c77f57b6\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15D7&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Excluded | Excluded | NotDeclared |
| `d3_Data1.cab_4332c77f57b6\amdwirelessbutton.inf` | AMD Wireless Button Driver | `ACPI\AMDI0051` | ACPI-enumerated PnP hardware ID | `amdwirelessbutton_Device` | Native | Native | Native | Native | KMDF 1.15 |
| `d3_Data1.cab_4332c77f57b6\ams_mailboxdrv.inf` | AMS-MailBoxDrv | `ACPI\AMDI0090` | ACPI-enumerated PnP hardware ID | `AMS-MailBoxDrv_Device` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_4332c77f57b6\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4353` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_4332c77f57b6\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4363` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_4332c77f57b6\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4372` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_4332c77f57b6\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4385` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_4332c77f57b6\smbusamd.inf` | AMD SMBus | `PCI\VEN_1022&DEV_780B` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_4332c77f57b6\smbusamd.inf` | AMD SMBus | `PCI\VEN_1022&DEV_790B` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_4332c77f57b6\usbfilter.inf` | AMD USB Filter Driver | `{36FC9E60-C465-11CF-8056-444553540000}\usbfilter` | Device-class-specific ID | `usbfilter` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_4332c77f57b6\zenpromnf.inf` | ZenProM S0i3 Network Filter | `ZenProMnf` | Network software component ID | `Install` | Native | Native | Native | Native | NotDeclared |

## AMD Chipset Software 6.01.25.342

| INF | Device | Device identifier | Identifier type | Install section | WS2016 | WS2019 | WS2022 | WS2025 | WDF |
|---|---|---|---|---|---|---|---|---|---|
| `d3_Data1.cab_e92b9a61ee8d\amd3dvcache.inf` | AMD 3D V-Cache Performance Optimizer | `ACPI\AMDI0101` | ACPI-enumerated PnP hardware ID | `amd3dvcache_Device` | No(Build) | No(Build) | Native | Native | KMDF 1.15 |
| `d3_Data1.cab_e92b9a61ee8d\amdas4.inf` | AmdAS4 Device | `ACPI\AMDI0050` | ACPI-enumerated PnP hardware ID | `AmdAS4` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_e92b9a61ee8d\amdas4.inf` | AmdAS4 Device | `ACPI\ASD0001` | ACPI-enumerated PnP hardware ID | `AmdAS4` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_e92b9a61ee8d\amdcir.inf` | AMD CIR Driver | `*AMDC001` | Generic PnP hardware ID | `AMDCIR64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_e92b9a61ee8d\amdcir.inf` | AMD CIR Driver | `*AMDC002` | Generic PnP hardware ID | `AMDCIR64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_e92b9a61ee8d\amdcir.inf` | AMD CIR Driver | `*AMDC003` | Generic PnP hardware ID | `AMDCIR64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_e92b9a61ee8d\amdgpio2.inf` | AMD GPIO Controller | `ACPI\AMD0030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_e92b9a61ee8d\amdgpio2.inf` | AMD GPIO Controller | `ACPI\AMDI0030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_e92b9a61ee8d\amdgpio2.inf` | AMD GPIO Controller | `ACPI\AMDI0031` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_e92b9a61ee8d\amdgpio2.inf` | AMD GPIO Controller | `ACPI\GPIO0010` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_e92b9a61ee8d\amdgpio3.inf` | AMD GPIO Controller | `ACPI\AMDF030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_e92b9a61ee8d\amdgpio3.inf` | AMD GPIO Controller | `ACPI\AMDIF030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_e92b9a61ee8d\amdgpio3.inf` | AMD GPIO Controller | `ACPI\AMDIF031` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_e92b9a61ee8d\amdi2c.inf` | AMD I2C Controller | `ACPI\AMD0010` | ACPI-enumerated PnP hardware ID | `amdi2c_Device` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_e92b9a61ee8d\amdi2c.inf` | AMD I2C Controller | `ACPI\AMDI0010` | ACPI-enumerated PnP hardware ID | `amdi2c_Device` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_e92b9a61ee8d\amdinterface.inf` | AMD Hetero Driver | `ACPI\AMDI0104` | ACPI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_e92b9a61ee8d\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_14AC` | PCI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_e92b9a61ee8d\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_14EC` | PCI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_e92b9a61ee8d\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_150D` | PCI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_e92b9a61ee8d\amdinterface.inf` | AMD SMBUS | `PCI\VEN_1022&DEV_790B` | PCI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_e92b9a61ee8d\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1002&DEV_5A23` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_e92b9a61ee8d\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_13E1` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_e92b9a61ee8d\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1419` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_e92b9a61ee8d\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1423` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_e92b9a61ee8d\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1437` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_e92b9a61ee8d\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1451` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_e92b9a61ee8d\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1481` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_e92b9a61ee8d\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1577` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_e92b9a61ee8d\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_164F` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_e92b9a61ee8d\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMD0004` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_e92b9a61ee8d\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMD0005` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_e92b9a61ee8d\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0005` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_e92b9a61ee8d\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0006` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_e92b9a61ee8d\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0007` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_e92b9a61ee8d\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0008` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_e92b9a61ee8d\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0009` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_e92b9a61ee8d\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI000A` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_e92b9a61ee8d\amdpcidev.inf` | AMD PCI | `PCI\VEN_1002&DEV_145A` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_e92b9a61ee8d\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_1455` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_e92b9a61ee8d\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_145A` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_e92b9a61ee8d\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_1485` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_e92b9a61ee8d\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_148A` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_e92b9a61ee8d\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_14DE` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_e92b9a61ee8d\amdpmf.inf` | AMD PMF | `ACPI\AMDI0100` | ACPI-enumerated PnP hardware ID | `AMDPMF_INSTALL.NTamd64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_e92b9a61ee8d\amdpmf.inf` | AMD PMF | `ACPI\AMDI0102` | ACPI-enumerated PnP hardware ID | `AMDPMF_INSTALL.NTamd64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_e92b9a61ee8d\amdppmpf.inf` | AMD PPM Provisioning File | `ACPI\AMDI0052` | ACPI-enumerated PnP hardware ID | `AMDPPMPF_DEV` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_e92b9a61ee8d\amdpsp.inf` | AMD PSP 10.0 Device | `PCI\VEN_1022&DEV_15DF` | PCI-enumerated PnP hardware ID | `amdpsp_Device_100` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_e92b9a61ee8d\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_1486` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_e92b9a61ee8d\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_14CA` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_e92b9a61ee8d\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_15C7` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_e92b9a61ee8d\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_1649` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_e92b9a61ee8d\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_17E0` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_e92b9a61ee8d\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_13EC` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_e92b9a61ee8d\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_1456` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_e92b9a61ee8d\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_1537` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_e92b9a61ee8d\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_1578` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_e92b9a61ee8d\amdsfhkmdf.inf` | AMD Sensor Fusion Hub | `PCI\VEN_1022&DEV_15E4` | PCI-enumerated PnP hardware ID | `amdsfhkmdf_Device` | Native | Native | Native | Native | KMDF 1.15 |
| `d3_Data1.cab_e92b9a61ee8d\amdsfhkmdfi2c.inf` | AMD SFH KMDF I2C | `PCI\VEN_1022&DEV_15E6` | PCI-enumerated PnP hardware ID | `amdsfhkmdf_Device` | Native | Native | Native | Native | KMDF 1.15 |
| `d3_Data1.cab_e92b9a61ee8d\amdsfhspbi2c.inf` | AMD SFH I2C Controller | `ACPI\AMDI0011` | ACPI-enumerated PnP hardware ID | `amdsfhspbi2c_Device` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_e92b9a61ee8d\amdsfhumdf.inf` | AMD UMDF Sensor | `ACPI\AMDI0080` | ACPI-enumerated PnP hardware ID | `amdsfhumdf_Inst` | Native | Native | Native | Native | UMDF 2.15.0 |
| `d3_Data1.cab_e92b9a61ee8d\amduart.inf` | AMD UART Controller | `ACPI\AMD0020` | ACPI-enumerated PnP hardware ID | `amduart_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_e92b9a61ee8d\amduart.inf` | AMD UART Controller | `ACPI\AMDI0020` | ACPI-enumerated PnP hardware ID | `amduart_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_e92b9a61ee8d\amduart.inf` | AMD UART Controller | `ACPI\AMDI0022` | ACPI-enumerated PnP hardware ID | `amduart_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_e92b9a61ee8d\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_15C4` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `d3_Data1.cab_e92b9a61ee8d\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_15C5` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `d3_Data1.cab_e92b9a61ee8d\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_162E` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `d3_Data1.cab_e92b9a61ee8d\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_162F` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `d3_Data1.cab_e92b9a61ee8d\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_1668` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `d3_Data1.cab_e92b9a61ee8d\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_1669` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `d3_Data1.cab_e92b9a61ee8d\amdusb4net.inf` | AMD USB4NET | `{b85b7c50-6a01-11d2-b841-00c04fad5171}\AMDUSB4NET` | Device-class-specific ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_e92b9a61ee8d\amdusb4net.inf` | AMD USB4NET | `{b85b7c50-6a01-11d2-b841-00c04fad5171}\Usb4Net` | Device-class-specific ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_e92b9a61ee8d\amdusb4net.inf` | AMD USB4NET | `root\AMDUSB4NET_a` | Root-enumerated PnP hardware ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_e92b9a61ee8d\amdusb4net.inf` | AMD USB4NET | `root\AMDUSB4NET_b` | Root-enumerated PnP hardware ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_e92b9a61ee8d\amdusb4net.inf` | AMD USB4NET | `root\AMDUSB4NET_c` | Root-enumerated PnP hardware ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_e92b9a61ee8d\amdusb4net.inf` | AMD USB4NET | `root\AMDUSB4NET_d` | Root-enumerated PnP hardware ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_e92b9a61ee8d\amdusb4pcifilter.inf` | PCI Express Root Port | `PCI\VEN_1022&DEV_14CD&SUBSYS_14531022&REV_00` | PCI-enumerated PnP hardware ID | `amdusb4pcifilter` | Native | Native | Excluded | Excluded | NotDeclared |
| `d3_Data1.cab_e92b9a61ee8d\amdusb4pcifilter.inf` | PCI Express Root Port | `PCI\VEN_1022&DEV_14EF&SUBSYS_14531022&REV_00` | PCI-enumerated PnP hardware ID | `amdusb4pcifilter` | Native | Native | Excluded | Excluded | NotDeclared |
| `d3_Data1.cab_e92b9a61ee8d\amdusb4pcifilter.inf` | PCI Express Root Port | `PCI\VEN_1022&DEV_14EF&SUBSYS_14531022&REV_01` | PCI-enumerated PnP hardware ID | `amdusb4pcifilter` | Native | Native | Excluded | Excluded | NotDeclared |
| `d3_Data1.cab_e92b9a61ee8d\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15C0&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Excluded | Excluded | NotDeclared |
| `d3_Data1.cab_e92b9a61ee8d\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15C1&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Excluded | Excluded | NotDeclared |
| `d3_Data1.cab_e92b9a61ee8d\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15C2&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Excluded | Excluded | NotDeclared |
| `d3_Data1.cab_e92b9a61ee8d\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15C3&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Excluded | Excluded | NotDeclared |
| `d3_Data1.cab_e92b9a61ee8d\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15D6&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Excluded | Excluded | NotDeclared |
| `d3_Data1.cab_e92b9a61ee8d\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15D7&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Excluded | Excluded | NotDeclared |
| `d3_Data1.cab_e92b9a61ee8d\amdwirelessbutton.inf` | AMD Wireless Button Driver | `ACPI\AMDI0051` | ACPI-enumerated PnP hardware ID | `amdwirelessbutton_Device` | Native | Native | Native | Native | KMDF 1.15 |
| `d3_Data1.cab_e92b9a61ee8d\ams_mailboxdrv.inf` | AMS-MailBoxDrv | `ACPI\AMDI0090` | ACPI-enumerated PnP hardware ID | `AMS-MailBoxDrv_Device` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_e92b9a61ee8d\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4353` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_e92b9a61ee8d\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4363` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_e92b9a61ee8d\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4372` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_e92b9a61ee8d\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4385` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_e92b9a61ee8d\smbusamd.inf` | AMD SMBus | `PCI\VEN_1022&DEV_780B` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_e92b9a61ee8d\smbusamd.inf` | AMD SMBus | `PCI\VEN_1022&DEV_790B` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_e92b9a61ee8d\usbfilter.inf` | AMD USB Filter Driver | `{36FC9E60-C465-11CF-8056-444553540000}\usbfilter` | Device-class-specific ID | `usbfilter` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_e92b9a61ee8d\zenpromnf.inf` | ZenProM S0i3 Network Filter | `ZenProMnf` | Network software component ID | `Install` | Native | Native | Native | Native | NotDeclared |

## AMD Chipset Software 5.08.02.027

| INF | Device | Device identifier | Identifier type | Install section | WS2016 | WS2019 | WS2022 | WS2025 | WDF |
|---|---|---|---|---|---|---|---|---|---|
| `d3_Data1.cab_9788b8e54bc5\amd3dvcache.inf` | AMD 3D V-Cache Performance Optimizer | `ACPI\AMDI0101` | ACPI-enumerated PnP hardware ID | `amd3dvcache_Device` | No(Build) | No(Build) | Native | Native | KMDF 1.15 |
| `d3_Data1.cab_9788b8e54bc5\amdas4.inf` | AmdAS4 Device | `ACPI\AMDI0050` | ACPI-enumerated PnP hardware ID | `AmdAS4` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_9788b8e54bc5\amdas4.inf` | AmdAS4 Device | `ACPI\ASD0001` | ACPI-enumerated PnP hardware ID | `AmdAS4` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_9788b8e54bc5\amdcir.inf` | AMD CIR Driver | `*AMDC001` | Generic PnP hardware ID | `AMDCIR64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_9788b8e54bc5\amdcir.inf` | AMD CIR Driver | `*AMDC002` | Generic PnP hardware ID | `AMDCIR64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_9788b8e54bc5\amdcir.inf` | AMD CIR Driver | `*AMDC003` | Generic PnP hardware ID | `AMDCIR64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_9788b8e54bc5\amdgpio2.inf` | AMD GPIO Controller | `ACPI\AMD0030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_9788b8e54bc5\amdgpio2.inf` | AMD GPIO Controller | `ACPI\AMDI0030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_9788b8e54bc5\amdgpio2.inf` | AMD GPIO Controller | `ACPI\AMDI0031` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_9788b8e54bc5\amdgpio2.inf` | AMD GPIO Controller | `ACPI\GPIO0010` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_9788b8e54bc5\amdgpio3.inf` | AMD GPIO Controller | `ACPI\AMDF030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_9788b8e54bc5\amdgpio3.inf` | AMD GPIO Controller | `ACPI\AMDIF030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_9788b8e54bc5\amdgpio3.inf` | AMD GPIO Controller | `ACPI\AMDIF031` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_9788b8e54bc5\amdi2c.inf` | AMD I2C Controller | `ACPI\AMD0010` | ACPI-enumerated PnP hardware ID | `amdi2c_Device` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_9788b8e54bc5\amdi2c.inf` | AMD I2C Controller | `ACPI\AMDI0010` | ACPI-enumerated PnP hardware ID | `amdi2c_Device` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_9788b8e54bc5\amdinterface.inf` | AMD Hetero Driver | `ACPI\AMDI0104` | ACPI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_9788b8e54bc5\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_14AC` | PCI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_9788b8e54bc5\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_14EC` | PCI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_9788b8e54bc5\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_150D` | PCI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_9788b8e54bc5\amdinterface.inf` | AMD SMBUS | `PCI\VEN_1022&DEV_790B` | PCI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_9788b8e54bc5\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1002&DEV_5A23` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_9788b8e54bc5\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_13E1` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_9788b8e54bc5\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1419` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_9788b8e54bc5\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1423` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_9788b8e54bc5\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1437` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_9788b8e54bc5\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1451` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_9788b8e54bc5\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1481` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_9788b8e54bc5\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1577` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_9788b8e54bc5\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_164F` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_9788b8e54bc5\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMD0004` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_9788b8e54bc5\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMD0005` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_9788b8e54bc5\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0005` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_9788b8e54bc5\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0006` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_9788b8e54bc5\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0007` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_9788b8e54bc5\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0008` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_9788b8e54bc5\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0009` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_9788b8e54bc5\amdpcidev.inf` | AMD PCI | `PCI\VEN_1002&DEV_145A` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_9788b8e54bc5\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_1455` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_9788b8e54bc5\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_145A` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_9788b8e54bc5\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_1485` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_9788b8e54bc5\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_148A` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_9788b8e54bc5\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_14DE` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_9788b8e54bc5\amdpmf.inf` | AMD PMF | `ACPI\AMDI0100` | ACPI-enumerated PnP hardware ID | `AMDPMF_INSTALL.NTamd64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_9788b8e54bc5\amdpmf.inf` | AMD PMF | `ACPI\AMDI0102` | ACPI-enumerated PnP hardware ID | `AMDPMF_INSTALL.NTamd64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_9788b8e54bc5\amdppmpf.inf` | AMD PPM Provisioning File | `ACPI\AMDI0052` | ACPI-enumerated PnP hardware ID | `AMDPPMPF_DEV` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_9788b8e54bc5\amdpsp.inf` | AMD PSP 10.0 Device | `PCI\VEN_1022&DEV_15DF` | PCI-enumerated PnP hardware ID | `amdpsp_Device_100` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_9788b8e54bc5\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_1486` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_9788b8e54bc5\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_14CA` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_9788b8e54bc5\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_15C7` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_9788b8e54bc5\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_1649` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_9788b8e54bc5\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_13EC` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_9788b8e54bc5\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_1456` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_9788b8e54bc5\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_1537` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_9788b8e54bc5\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_1578` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_9788b8e54bc5\amdsfhkmdf.inf` | AMD Sensor Fusion Hub | `PCI\VEN_1022&DEV_15E4` | PCI-enumerated PnP hardware ID | `amdsfhkmdf_Device` | Native | Native | Native | Native | KMDF 1.15 |
| `d3_Data1.cab_9788b8e54bc5\amdsfhkmdfi2c.inf` | AMD SFH KMDF I2C | `PCI\VEN_1022&DEV_15E6` | PCI-enumerated PnP hardware ID | `amdsfhkmdf_Device` | Native | Native | Native | Native | KMDF 1.15 |
| `d3_Data1.cab_9788b8e54bc5\amdsfhspbi2c.inf` | AMD SFH I2C Controller | `ACPI\AMDI0011` | ACPI-enumerated PnP hardware ID | `amdsfhspbi2c_Device` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_9788b8e54bc5\amdsfhumdf.inf` | AMD UMDF Sensor | `ACPI\AMDI0080` | ACPI-enumerated PnP hardware ID | `amdsfhumdf_Inst` | Native | Native | Native | Native | UMDF 2.15.0 |
| `d3_Data1.cab_9788b8e54bc5\amduart.inf` | AMD UART Controller | `ACPI\AMD0020` | ACPI-enumerated PnP hardware ID | `amduart_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_9788b8e54bc5\amduart.inf` | AMD UART Controller | `ACPI\AMDI0020` | ACPI-enumerated PnP hardware ID | `amduart_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_9788b8e54bc5\amduart.inf` | AMD UART Controller | `ACPI\AMDI0022` | ACPI-enumerated PnP hardware ID | `amduart_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_9788b8e54bc5\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_15C4` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `d3_Data1.cab_9788b8e54bc5\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_15C5` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `d3_Data1.cab_9788b8e54bc5\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_162E` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `d3_Data1.cab_9788b8e54bc5\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_162F` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `d3_Data1.cab_9788b8e54bc5\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_1668` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `d3_Data1.cab_9788b8e54bc5\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_1669` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `d3_Data1.cab_9788b8e54bc5\amdusb4net.inf` | AMD USB4NET | `{b85b7c50-6a01-11d2-b841-00c04fad5171}\AMDUSB4NET` | Device-class-specific ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_9788b8e54bc5\amdusb4net.inf` | AMD USB4NET | `{b85b7c50-6a01-11d2-b841-00c04fad5171}\Usb4Net` | Device-class-specific ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_9788b8e54bc5\amdusb4net.inf` | AMD USB4NET | `root\AMDUSB4NET_a` | Root-enumerated PnP hardware ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_9788b8e54bc5\amdusb4net.inf` | AMD USB4NET | `root\AMDUSB4NET_b` | Root-enumerated PnP hardware ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_9788b8e54bc5\amdusb4net.inf` | AMD USB4NET | `root\AMDUSB4NET_c` | Root-enumerated PnP hardware ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_9788b8e54bc5\amdusb4net.inf` | AMD USB4NET | `root\AMDUSB4NET_d` | Root-enumerated PnP hardware ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_9788b8e54bc5\amdusb4pcifilter.inf` | PCI Express Root Port | `PCI\VEN_1022&DEV_14CD&SUBSYS_14531022&REV_00` | PCI-enumerated PnP hardware ID | `amdusb4pcifilter` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_9788b8e54bc5\amdusb4pcifilter.inf` | PCI Express Root Port | `PCI\VEN_1022&DEV_14EF&SUBSYS_14531022&REV_00` | PCI-enumerated PnP hardware ID | `amdusb4pcifilter` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_9788b8e54bc5\amdusb4pcifilter.inf` | PCI Express Root Port | `PCI\VEN_1022&DEV_14EF&SUBSYS_14531022&REV_01` | PCI-enumerated PnP hardware ID | `amdusb4pcifilter` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_9788b8e54bc5\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15C0&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_9788b8e54bc5\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15C1&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_9788b8e54bc5\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15C2&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_9788b8e54bc5\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15C3&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_9788b8e54bc5\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15D6&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_9788b8e54bc5\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15D7&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_9788b8e54bc5\amdwirelessbutton.inf` | AMD Wireless Button Driver | `ACPI\AMDI0051` | ACPI-enumerated PnP hardware ID | `amdwirelessbutton_Device` | Native | Native | Native | Native | KMDF 1.15 |
| `d3_Data1.cab_9788b8e54bc5\ams_mailboxdrv.inf` | AMS-MailBoxDrv | `ACPI\AMDI0090` | ACPI-enumerated PnP hardware ID | `AMS-MailBoxDrv_Device` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_9788b8e54bc5\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4353` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_9788b8e54bc5\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4363` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_9788b8e54bc5\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4372` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_9788b8e54bc5\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4385` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_9788b8e54bc5\smbusamd.inf` | AMD SMBus | `PCI\VEN_1022&DEV_780B` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_9788b8e54bc5\smbusamd.inf` | AMD SMBus | `PCI\VEN_1022&DEV_790B` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_9788b8e54bc5\usbfilter.inf` | AMD USB Filter Driver | `{36FC9E60-C465-11CF-8056-444553540000}\usbfilter` | Device-class-specific ID | `usbfilter` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_9788b8e54bc5\zenpromnf.inf` | ZenProM S0i3 Network Filter | `ZenProMnf` | Network software component ID | `Install` | Native | Native | Native | Native | NotDeclared |

## AMD Chipset Software 5.05.16.529

| INF | Device | Device identifier | Identifier type | Install section | WS2016 | WS2019 | WS2022 | WS2025 | WDF |
|---|---|---|---|---|---|---|---|---|---|
| `d3_Data1.cab_3ee12ba1daa3\amd3dvcache.inf` | AMD 3D V-Cache Performance Optimizer | `ACPI\AMDI0101` | ACPI-enumerated PnP hardware ID | `amd3dvcache_Device` | No(Build) | No(Build) | Native | Native | KMDF 1.15 |
| `d3_Data1.cab_3ee12ba1daa3\amdas4.inf` | AmdAS4 Device | `ACPI\AMDI0050` | ACPI-enumerated PnP hardware ID | `AmdAS4` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_3ee12ba1daa3\amdas4.inf` | AmdAS4 Device | `ACPI\ASD0001` | ACPI-enumerated PnP hardware ID | `AmdAS4` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_3ee12ba1daa3\amdcir.inf` | AMD CIR Driver | `*AMDC001` | Generic PnP hardware ID | `AMDCIR64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_3ee12ba1daa3\amdcir.inf` | AMD CIR Driver | `*AMDC002` | Generic PnP hardware ID | `AMDCIR64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_3ee12ba1daa3\amdcir.inf` | AMD CIR Driver | `*AMDC003` | Generic PnP hardware ID | `AMDCIR64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_3ee12ba1daa3\amdgpio2.inf` | AMD GPIO Controller | `ACPI\AMD0030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_3ee12ba1daa3\amdgpio2.inf` | AMD GPIO Controller | `ACPI\AMDI0030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_3ee12ba1daa3\amdgpio2.inf` | AMD GPIO Controller | `ACPI\AMDI0031` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_3ee12ba1daa3\amdgpio2.inf` | AMD GPIO Controller | `ACPI\GPIO0010` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_3ee12ba1daa3\amdgpio3.inf` | AMD GPIO Controller | `ACPI\AMDF030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_3ee12ba1daa3\amdgpio3.inf` | AMD GPIO Controller | `ACPI\AMDIF030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_3ee12ba1daa3\amdgpio3.inf` | AMD GPIO Controller | `ACPI\AMDIF031` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_3ee12ba1daa3\amdi2c.inf` | AMD I2C Controller | `ACPI\AMD0010` | ACPI-enumerated PnP hardware ID | `amdi2c_Device` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_3ee12ba1daa3\amdi2c.inf` | AMD I2C Controller | `ACPI\AMDI0010` | ACPI-enumerated PnP hardware ID | `amdi2c_Device` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_3ee12ba1daa3\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1002&DEV_5A23` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_3ee12ba1daa3\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_13E1` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_3ee12ba1daa3\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1419` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_3ee12ba1daa3\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1423` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_3ee12ba1daa3\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1437` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_3ee12ba1daa3\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1451` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_3ee12ba1daa3\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1481` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_3ee12ba1daa3\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1577` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_3ee12ba1daa3\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_164F` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_3ee12ba1daa3\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMD0004` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_3ee12ba1daa3\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMD0005` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_3ee12ba1daa3\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0005` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_3ee12ba1daa3\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0006` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_3ee12ba1daa3\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0007` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_3ee12ba1daa3\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0008` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_3ee12ba1daa3\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0009` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_3ee12ba1daa3\amdpcidev.inf` | AMD PCI | `PCI\VEN_1002&DEV_145A` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_3ee12ba1daa3\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_1455` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_3ee12ba1daa3\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_145A` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_3ee12ba1daa3\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_1485` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_3ee12ba1daa3\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_148A` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_3ee12ba1daa3\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_14DE` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_3ee12ba1daa3\amdpmf.inf` | AMD PMF | `ACPI\AMDI0100` | ACPI-enumerated PnP hardware ID | `AMDPMF_INSTALL.NTamd64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_3ee12ba1daa3\amdpmf.inf` | AMD PMF | `ACPI\AMDI0102` | ACPI-enumerated PnP hardware ID | `AMDPMF_INSTALL.NTamd64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_3ee12ba1daa3\amdppmpf.inf` | AMD PPM Provisioning File | `ACPI\AMDI0052` | ACPI-enumerated PnP hardware ID | `AMDPPMPF_DEV` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_3ee12ba1daa3\amdpsp.inf` | AMD PSP 10.0 Device | `PCI\VEN_1022&DEV_15DF` | PCI-enumerated PnP hardware ID | `amdpsp_Device_100` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_3ee12ba1daa3\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_1486` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_3ee12ba1daa3\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_14CA` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_3ee12ba1daa3\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_15C7` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_3ee12ba1daa3\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_1649` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_3ee12ba1daa3\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_13EC` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_3ee12ba1daa3\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_1456` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_3ee12ba1daa3\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_1537` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_3ee12ba1daa3\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_1578` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_3ee12ba1daa3\amdsfhkmdf.inf` | AMD Sensor Fusion Hub | `PCI\VEN_1022&DEV_15E4` | PCI-enumerated PnP hardware ID | `amdsfhkmdf_Device` | Native | Native | Native | Native | KMDF 1.15 |
| `d3_Data1.cab_3ee12ba1daa3\amdsfhkmdfi2c.inf` | AMD SFH KMDF I2C | `PCI\VEN_1022&DEV_15E6` | PCI-enumerated PnP hardware ID | `amdsfhkmdf_Device` | Native | Native | Native | Native | KMDF 1.15 |
| `d3_Data1.cab_3ee12ba1daa3\amdsfhspbi2c.inf` | AMD SFH I2C Controller | `ACPI\AMDI0011` | ACPI-enumerated PnP hardware ID | `amdsfhspbi2c_Device` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_3ee12ba1daa3\amdsfhumdf.inf` | AMD UMDF Sensor | `ACPI\AMDI0080` | ACPI-enumerated PnP hardware ID | `amdsfhumdf_Inst` | Native | Native | Native | Native | UMDF 2.15.0 |
| `d3_Data1.cab_3ee12ba1daa3\amduart.inf` | AMD UART Controller | `ACPI\AMD0020` | ACPI-enumerated PnP hardware ID | `amduart_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_3ee12ba1daa3\amduart.inf` | AMD UART Controller | `ACPI\AMDI0020` | ACPI-enumerated PnP hardware ID | `amduart_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_3ee12ba1daa3\amduart.inf` | AMD UART Controller | `ACPI\AMDI0022` | ACPI-enumerated PnP hardware ID | `amduart_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_3ee12ba1daa3\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_15C4` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `d3_Data1.cab_3ee12ba1daa3\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_15C5` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `d3_Data1.cab_3ee12ba1daa3\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_162E` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `d3_Data1.cab_3ee12ba1daa3\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_162F` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `d3_Data1.cab_3ee12ba1daa3\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_1668` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `d3_Data1.cab_3ee12ba1daa3\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_1669` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `d3_Data1.cab_3ee12ba1daa3\amdusb4net.inf` | AMD USB4NET | `{b85b7c50-6a01-11d2-b841-00c04fad5171}\AMDUSB4NET` | Device-class-specific ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_3ee12ba1daa3\amdusb4net.inf` | AMD USB4NET | `{b85b7c50-6a01-11d2-b841-00c04fad5171}\Usb4Net` | Device-class-specific ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_3ee12ba1daa3\amdusb4net.inf` | AMD USB4NET | `root\AMDUSB4NET_a` | Root-enumerated PnP hardware ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_3ee12ba1daa3\amdusb4net.inf` | AMD USB4NET | `root\AMDUSB4NET_b` | Root-enumerated PnP hardware ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_3ee12ba1daa3\amdusb4net.inf` | AMD USB4NET | `root\AMDUSB4NET_c` | Root-enumerated PnP hardware ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_3ee12ba1daa3\amdusb4net.inf` | AMD USB4NET | `root\AMDUSB4NET_d` | Root-enumerated PnP hardware ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_3ee12ba1daa3\amdusb4pcifilter.inf` | PCI Express Root Port | `PCI\VEN_1022&DEV_14CD&SUBSYS_14531022&REV_00` | PCI-enumerated PnP hardware ID | `amdusb4pcifilter` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_3ee12ba1daa3\amdusb4pcifilter.inf` | PCI Express Root Port | `PCI\VEN_1022&DEV_14EF&SUBSYS_14531022&REV_00` | PCI-enumerated PnP hardware ID | `amdusb4pcifilter` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_3ee12ba1daa3\amdusb4pcifilter.inf` | PCI Express Root Port | `PCI\VEN_1022&DEV_14EF&SUBSYS_14531022&REV_01` | PCI-enumerated PnP hardware ID | `amdusb4pcifilter` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_3ee12ba1daa3\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15C0&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_3ee12ba1daa3\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15C1&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_3ee12ba1daa3\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15C2&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_3ee12ba1daa3\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15C3&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_3ee12ba1daa3\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15D6&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_3ee12ba1daa3\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15D7&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_3ee12ba1daa3\amdwirelessbutton.inf` | AMD Wireless Button Driver | `ACPI\AMDI0051` | ACPI-enumerated PnP hardware ID | `amdwirelessbutton_Device` | Native | Native | Native | Native | KMDF 1.15 |
| `d3_Data1.cab_3ee12ba1daa3\ams_mailboxdrv.inf` | AMS-MailBoxDrv | `ACPI\AMDI0090` | ACPI-enumerated PnP hardware ID | `AMS-MailBoxDrv_Device` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_3ee12ba1daa3\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4353` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_3ee12ba1daa3\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4363` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_3ee12ba1daa3\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4372` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_3ee12ba1daa3\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4385` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_3ee12ba1daa3\smbusamd.inf` | AMD SMBus | `PCI\VEN_1022&DEV_780B` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_3ee12ba1daa3\smbusamd.inf` | AMD SMBus | `PCI\VEN_1022&DEV_790B` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_3ee12ba1daa3\usbfilter.inf` | AMD USB Filter Driver | `{36FC9E60-C465-11CF-8056-444553540000}\usbfilter` | Device-class-specific ID | `usbfilter` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_3ee12ba1daa3\zenpromnf.inf` | ZenProM S0i3 Network Filter | `ZenProMnf` | Network software component ID | `Install` | Native | Native | Native | Native | NotDeclared |

## AMD Chipset Software 5.02.19.2221

| INF | Device | Device identifier | Identifier type | Install section | WS2016 | WS2019 | WS2022 | WS2025 | WDF |
|---|---|---|---|---|---|---|---|---|---|
| `d3_Data1.cab_03637523efe2\amd3dvcache.inf` | AMD 3D V-Cache Performance Optimizer | `ACPI\AMDI0101` | ACPI-enumerated PnP hardware ID | `amd3dvcache_Device` | No(Build) | No(Build) | Native | Native | KMDF 1.15 |
| `d3_Data1.cab_03637523efe2\amdas4.inf` | AmdAS4 Device | `ACPI\AMDI0050` | ACPI-enumerated PnP hardware ID | `AmdAS4` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_03637523efe2\amdas4.inf` | AmdAS4 Device | `ACPI\ASD0001` | ACPI-enumerated PnP hardware ID | `AmdAS4` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_03637523efe2\amdcir.inf` | AMD CIR Driver | `*AMDC001` | Generic PnP hardware ID | `AMDCIR64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_03637523efe2\amdcir.inf` | AMD CIR Driver | `*AMDC002` | Generic PnP hardware ID | `AMDCIR64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_03637523efe2\amdcir.inf` | AMD CIR Driver | `*AMDC003` | Generic PnP hardware ID | `AMDCIR64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_03637523efe2\amdgpio2.inf` | AMD GPIO Controller | `ACPI\AMD0030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_03637523efe2\amdgpio2.inf` | AMD GPIO Controller | `ACPI\AMDI0030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_03637523efe2\amdgpio2.inf` | AMD GPIO Controller | `ACPI\AMDI0031` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_03637523efe2\amdgpio2.inf` | AMD GPIO Controller | `ACPI\GPIO0010` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_03637523efe2\amdgpio3.inf` | AMD GPIO Controller | `ACPI\AMDF030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_03637523efe2\amdgpio3.inf` | AMD GPIO Controller | `ACPI\AMDIF030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_03637523efe2\amdgpio3.inf` | AMD GPIO Controller | `ACPI\AMDIF031` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_03637523efe2\amdi2c.inf` | AMD I2C Controller | `ACPI\AMD0010` | ACPI-enumerated PnP hardware ID | `amdi2c_Device` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_03637523efe2\amdi2c.inf` | AMD I2C Controller | `ACPI\AMDI0010` | ACPI-enumerated PnP hardware ID | `amdi2c_Device` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_03637523efe2\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1002&DEV_5A23` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_03637523efe2\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_13E1` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_03637523efe2\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1419` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_03637523efe2\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1423` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_03637523efe2\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1437` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_03637523efe2\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1451` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_03637523efe2\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1481` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_03637523efe2\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1577` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_03637523efe2\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_164F` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_03637523efe2\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMD0004` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_03637523efe2\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMD0005` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_03637523efe2\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0005` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_03637523efe2\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0006` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_03637523efe2\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0007` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_03637523efe2\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0008` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_03637523efe2\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0009` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_03637523efe2\amdpcidev.inf` | AMD PCI | `PCI\VEN_1002&DEV_145A` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_03637523efe2\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_1455` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_03637523efe2\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_145A` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_03637523efe2\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_1485` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_03637523efe2\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_148A` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_03637523efe2\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_14DE` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_03637523efe2\amdpmf.inf` | AMD PMF | `ACPI\AMDI0100` | ACPI-enumerated PnP hardware ID | `AMDPMF_INSTALL.NTamd64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_03637523efe2\amdpmf.inf` | AMD PMF | `ACPI\AMDI0102` | ACPI-enumerated PnP hardware ID | `AMDPMF_INSTALL.NTamd64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_03637523efe2\amdppmpf.inf` | AMD PPM Provisioning File | `ACPI\AMDI0052` | ACPI-enumerated PnP hardware ID | `AMDPPMPF_DEV` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_03637523efe2\amdpsp.inf` | AMD PSP 10.0 Device | `PCI\VEN_1022&DEV_15DF` | PCI-enumerated PnP hardware ID | `amdpsp_Device_100` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_03637523efe2\amdpsp.inf` | AMD PSP 10.0 Device | `PCI\VEN_1022&DEV_1649` | PCI-enumerated PnP hardware ID | `amdpsp_Device_100` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_03637523efe2\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_1486` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_03637523efe2\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_14CA` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_03637523efe2\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_15C7` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_03637523efe2\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_13EC` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_03637523efe2\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_1456` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_03637523efe2\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_1537` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_03637523efe2\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_1578` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_03637523efe2\amdsfhkmdf.inf` | AMD Sensor Fusion Hub | `PCI\VEN_1022&DEV_15E4` | PCI-enumerated PnP hardware ID | `amdsfhkmdf_Device` | Native | Native | Native | Native | KMDF 1.15 |
| `d3_Data1.cab_03637523efe2\amdsfhkmdfi2c.inf` | AMD SFH KMDF I2C | `PCI\VEN_1022&DEV_15E6` | PCI-enumerated PnP hardware ID | `amdsfhkmdf_Device` | Native | Native | Native | Native | KMDF 1.15 |
| `d3_Data1.cab_03637523efe2\amdsfhspbi2c.inf` | AMD SFH I2C Controller | `ACPI\AMDI0011` | ACPI-enumerated PnP hardware ID | `amdsfhspbi2c_Device` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_03637523efe2\amdsfhumdf.inf` | AMD UMDF Sensor | `ACPI\AMDI0080` | ACPI-enumerated PnP hardware ID | `amdsfhumdf_Inst` | Native | Native | Native | Native | UMDF 2.15.0 |
| `d3_Data1.cab_03637523efe2\amduart.inf` | AMD UART Controller | `ACPI\AMD0020` | ACPI-enumerated PnP hardware ID | `amduart_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_03637523efe2\amduart.inf` | AMD UART Controller | `ACPI\AMDI0020` | ACPI-enumerated PnP hardware ID | `amduart_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_03637523efe2\amduart.inf` | AMD UART Controller | `ACPI\AMDI0022` | ACPI-enumerated PnP hardware ID | `amduart_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_03637523efe2\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_15C4` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `d3_Data1.cab_03637523efe2\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_15C5` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `d3_Data1.cab_03637523efe2\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_162E` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `d3_Data1.cab_03637523efe2\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_162F` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `d3_Data1.cab_03637523efe2\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_1668` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `d3_Data1.cab_03637523efe2\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_1669` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `d3_Data1.cab_03637523efe2\amdusb4pcifilter.inf` | PCI Express Root Port | `PCI\VEN_1022&DEV_14CD&SUBSYS_14531022&REV_00` | PCI-enumerated PnP hardware ID | `amdusb4pcifilter` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_03637523efe2\amdusb4pcifilter.inf` | PCI Express Root Port | `PCI\VEN_1022&DEV_14EF&SUBSYS_14531022&REV_00` | PCI-enumerated PnP hardware ID | `amdusb4pcifilter` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_03637523efe2\amdusb4pcifilter.inf` | PCI Express Root Port | `PCI\VEN_1022&DEV_14EF&SUBSYS_14531022&REV_01` | PCI-enumerated PnP hardware ID | `amdusb4pcifilter` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_03637523efe2\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15C0&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_03637523efe2\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15C1&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_03637523efe2\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15C2&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_03637523efe2\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15C3&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_03637523efe2\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15D6&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_03637523efe2\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15D7&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_03637523efe2\amdwirelessbutton.inf` | AMD Wireless Button Driver | `ACPI\AMDI0051` | ACPI-enumerated PnP hardware ID | `amdwirelessbutton_Device` | Native | Native | Native | Native | KMDF 1.15 |
| `d3_Data1.cab_03637523efe2\ams_mailboxdrv.inf` | AMS-MailBoxDrv | `ACPI\AMDI0090` | ACPI-enumerated PnP hardware ID | `AMS-MailBoxDrv_Device` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_03637523efe2\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4353` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_03637523efe2\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4363` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_03637523efe2\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4372` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_03637523efe2\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4385` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_03637523efe2\smbusamd.inf` | AMD SMBus | `PCI\VEN_1022&DEV_780B` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_03637523efe2\smbusamd.inf` | AMD SMBus | `PCI\VEN_1022&DEV_790B` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_03637523efe2\usbfilter.inf` | AMD USB Filter Driver | `{36FC9E60-C465-11CF-8056-444553540000}\usbfilter` | Device-class-specific ID | `usbfilter` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_03637523efe2\zenpromnf.inf` | ZenProM S0i3 Network Filter | `ZenProMnf` | Network software component ID | `Install` | Native | Native | Native | Native | NotDeclared |

## AMD Chipset Software 4.11.15.342

| INF | Device | Device identifier | Identifier type | Install section | WS2016 | WS2019 | WS2022 | WS2025 | WDF |
|---|---|---|---|---|---|---|---|---|---|
| `d3_Data1.cab_1447e121998f\amdas4.inf` | AmdAS4 Device | `ACPI\AMDI0050` | ACPI-enumerated PnP hardware ID | `AmdAS4` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_1447e121998f\amdas4.inf` | AmdAS4 Device | `ACPI\ASD0001` | ACPI-enumerated PnP hardware ID | `AmdAS4` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_1447e121998f\amdcir.inf` | AMD CIR Driver | `*AMDC001` | Generic PnP hardware ID | `AMDCIR64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_1447e121998f\amdcir.inf` | AMD CIR Driver | `*AMDC002` | Generic PnP hardware ID | `AMDCIR64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_1447e121998f\amdcir.inf` | AMD CIR Driver | `*AMDC003` | Generic PnP hardware ID | `AMDCIR64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_1447e121998f\amdgpio2.inf` | AMD GPIO Controller | `ACPI\AMD0030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_1447e121998f\amdgpio2.inf` | AMD GPIO Controller | `ACPI\AMDI0030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_1447e121998f\amdgpio2.inf` | AMD GPIO Controller | `ACPI\AMDI0031` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_1447e121998f\amdgpio2.inf` | AMD GPIO Controller | `ACPI\GPIO0010` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_1447e121998f\amdgpio3.inf` | AMD GPIO Controller | `ACPI\AMDF030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_1447e121998f\amdgpio3.inf` | AMD GPIO Controller | `ACPI\AMDIF030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_1447e121998f\amdgpio3.inf` | AMD GPIO Controller | `ACPI\AMDIF031` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_1447e121998f\amdi2c.inf` | AMD I2C Controller | `ACPI\AMD0010` | ACPI-enumerated PnP hardware ID | `amdi2c_Device` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_1447e121998f\amdi2c.inf` | AMD I2C Controller | `ACPI\AMDI0010` | ACPI-enumerated PnP hardware ID | `amdi2c_Device` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_1447e121998f\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1002&DEV_5A23` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_1447e121998f\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_13E1` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_1447e121998f\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1419` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_1447e121998f\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1423` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_1447e121998f\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1437` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_1447e121998f\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1451` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_1447e121998f\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1481` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_1447e121998f\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1577` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_1447e121998f\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_164F` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_1447e121998f\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMD0004` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_1447e121998f\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMD0005` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_1447e121998f\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0005` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_1447e121998f\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0006` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_1447e121998f\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0007` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_1447e121998f\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0008` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_1447e121998f\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0009` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_1447e121998f\amdpcidev.inf` | AMD PCI | `PCI\VEN_1002&DEV_145A` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_1447e121998f\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_1455` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_1447e121998f\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_145A` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_1447e121998f\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_1485` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_1447e121998f\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_148A` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_1447e121998f\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_14DE` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_1447e121998f\amdpmf.inf` | AMD PMF | `ACPI\AMDI0100` | ACPI-enumerated PnP hardware ID | `AMDPMF_INSTALL.NTamd64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_1447e121998f\amdpmf.inf` | AMD PMF | `ACPI\AMDI0102` | ACPI-enumerated PnP hardware ID | `AMDPMF_INSTALL.NTamd64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_1447e121998f\amdppmpf.inf` | AMD PPM Provisioning File | `ACPI\AMDI0052` | ACPI-enumerated PnP hardware ID | `AMDPPMPF_DEV` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_1447e121998f\amdpsp.inf` | AMD PSP 10.0 Device | `PCI\VEN_1022&DEV_15DF` | PCI-enumerated PnP hardware ID | `amdpsp_Device_100` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_1447e121998f\amdpsp.inf` | AMD PSP 10.0 Device | `PCI\VEN_1022&DEV_1649` | PCI-enumerated PnP hardware ID | `amdpsp_Device_100` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_1447e121998f\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_1486` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_1447e121998f\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_14CA` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_1447e121998f\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_15C7` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_1447e121998f\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_13EC` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_1447e121998f\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_1456` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_1447e121998f\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_1537` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_1447e121998f\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_1578` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_1447e121998f\amdsfhkmdf.inf` | AMD Sensor Fusion Hub | `PCI\VEN_1022&DEV_15E4` | PCI-enumerated PnP hardware ID | `amdsfhkmdf_Device` | Native | Native | Native | Native | KMDF 1.15 |
| `d3_Data1.cab_1447e121998f\amdsfhkmdfi2c.inf` | AMD SFH KMDF I2C | `PCI\VEN_1022&DEV_15E6` | PCI-enumerated PnP hardware ID | `amdsfhkmdf_Device` | Native | Native | Native | Native | KMDF 1.15 |
| `d3_Data1.cab_1447e121998f\amdsfhspbi2c.inf` | AMD SFH I2C Controller | `ACPI\AMDI0011` | ACPI-enumerated PnP hardware ID | `amdsfhspbi2c_Device` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_1447e121998f\amdsfhumdf.inf` | AMD UMDF Sensor | `ACPI\AMDI0080` | ACPI-enumerated PnP hardware ID | `amdsfhumdf_Inst` | Native | Native | Native | Native | UMDF 2.15.0 |
| `d3_Data1.cab_1447e121998f\amduart.inf` | AMD UART Controller | `ACPI\AMD0020` | ACPI-enumerated PnP hardware ID | `amduart_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_1447e121998f\amduart.inf` | AMD UART Controller | `ACPI\AMDI0020` | ACPI-enumerated PnP hardware ID | `amduart_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_1447e121998f\amduart.inf` | AMD UART Controller | `ACPI\AMDI0022` | ACPI-enumerated PnP hardware ID | `amduart_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_1447e121998f\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_162E` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `d3_Data1.cab_1447e121998f\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_162F` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `d3_Data1.cab_1447e121998f\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_1668` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `d3_Data1.cab_1447e121998f\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_1669` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `d3_Data1.cab_1447e121998f\amdusb4pcifilter.inf` | PCI Express Root Port | `PCI\VEN_1022&DEV_14CD&SUBSYS_14531022&REV_00` | PCI-enumerated PnP hardware ID | `amdusb4pcifilter` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_1447e121998f\amdusb4pcifilter.inf` | PCI Express Root Port | `PCI\VEN_1022&DEV_14EF&SUBSYS_14531022&REV_00` | PCI-enumerated PnP hardware ID | `amdusb4pcifilter` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_1447e121998f\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15C0&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_1447e121998f\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15C1&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_1447e121998f\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15D6&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_1447e121998f\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15D7&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_1447e121998f\amdwirelessbutton.inf` | AMD Wireless Button Driver | `ACPI\AMDI0051` | ACPI-enumerated PnP hardware ID | `amdwirelessbutton_Device` | Native | Native | Native | Native | KMDF 1.15 |
| `d3_Data1.cab_1447e121998f\ams_mailboxdrv.inf` | AMS-MailBoxDrv | `ACPI\AMDI0090` | ACPI-enumerated PnP hardware ID | `AMS-MailBoxDrv_Device` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_1447e121998f\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4353` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_1447e121998f\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4363` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_1447e121998f\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4372` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_1447e121998f\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4385` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_1447e121998f\smbusamd.inf` | AMD SMBus | `PCI\VEN_1022&DEV_780B` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_1447e121998f\smbusamd.inf` | AMD SMBus | `PCI\VEN_1022&DEV_790B` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_1447e121998f\usbfilter.inf` | AMD USB Filter Driver | `{36FC9E60-C465-11CF-8056-444553540000}\usbfilter` | Device-class-specific ID | `usbfilter` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_1447e121998f\zenpromnf.inf` | ZenProM S0i3 Network Filter | `ZenProMnf` | Network software component ID | `Install` | Native | Native | Native | Native | NotDeclared |

## AMD Chipset Software 4.09.23.507

| INF | Device | Device identifier | Identifier type | Install section | WS2016 | WS2019 | WS2022 | WS2025 | WDF |
|---|---|---|---|---|---|---|---|---|---|
| `d3_Data1.cab_805a7fef6dd0\amdas4.inf` | AmdAS4 Device | `ACPI\AMDI0050` | ACPI-enumerated PnP hardware ID | `AmdAS4` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_805a7fef6dd0\amdas4.inf` | AmdAS4 Device | `ACPI\ASD0001` | ACPI-enumerated PnP hardware ID | `AmdAS4` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_805a7fef6dd0\amdcir.inf` | AMD CIR Driver | `*AMDC001` | Generic PnP hardware ID | `AMDCIR64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_805a7fef6dd0\amdcir.inf` | AMD CIR Driver | `*AMDC002` | Generic PnP hardware ID | `AMDCIR64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_805a7fef6dd0\amdcir.inf` | AMD CIR Driver | `*AMDC003` | Generic PnP hardware ID | `AMDCIR64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_805a7fef6dd0\amdgpio2.inf` | AMD GPIO Controller | `ACPI\AMD0030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_805a7fef6dd0\amdgpio2.inf` | AMD GPIO Controller | `ACPI\AMDI0030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_805a7fef6dd0\amdgpio2.inf` | AMD GPIO Controller | `ACPI\AMDI0031` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_805a7fef6dd0\amdgpio2.inf` | AMD GPIO Controller | `ACPI\GPIO0010` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_805a7fef6dd0\amdgpio3.inf` | AMD GPIO Controller | `ACPI\AMDF030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_805a7fef6dd0\amdgpio3.inf` | AMD GPIO Controller | `ACPI\AMDIF030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_805a7fef6dd0\amdgpio3.inf` | AMD GPIO Controller | `ACPI\AMDIF031` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_805a7fef6dd0\amdi2c.inf` | AMD I2C Controller | `ACPI\AMD0010` | ACPI-enumerated PnP hardware ID | `amdi2c_Device` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_805a7fef6dd0\amdi2c.inf` | AMD I2C Controller | `ACPI\AMDI0010` | ACPI-enumerated PnP hardware ID | `amdi2c_Device` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_805a7fef6dd0\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1002&DEV_5A23` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_805a7fef6dd0\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_13E1` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_805a7fef6dd0\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1419` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_805a7fef6dd0\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1423` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_805a7fef6dd0\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1437` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_805a7fef6dd0\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1451` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_805a7fef6dd0\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1481` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_805a7fef6dd0\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1577` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_805a7fef6dd0\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_164F` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_805a7fef6dd0\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMD0004` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_805a7fef6dd0\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMD0005` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_805a7fef6dd0\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0005` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_805a7fef6dd0\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0006` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_805a7fef6dd0\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0007` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_805a7fef6dd0\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0008` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_805a7fef6dd0\amdpcidev.inf` | AMD PCI | `PCI\VEN_1002&DEV_145A` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_805a7fef6dd0\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_1455` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_805a7fef6dd0\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_145A` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_805a7fef6dd0\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_1485` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_805a7fef6dd0\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_148A` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_805a7fef6dd0\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_14DE` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_805a7fef6dd0\amdpmf.inf` | AMD PMF | `ACPI\AMDI0100` | ACPI-enumerated PnP hardware ID | `AMDPMF_INSTALL.NTamd64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_805a7fef6dd0\amdpmf.inf` | AMD PMF | `ACPI\AMDI0102` | ACPI-enumerated PnP hardware ID | `AMDPMF_INSTALL.NTamd64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_805a7fef6dd0\amdppmpf.inf` | AMD PPM Provisioning File | `ACPI\AMDI0052` | ACPI-enumerated PnP hardware ID | `AMDPPMPF_DEV` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_805a7fef6dd0\amdpsp.inf` | AMD PSP 10.0 Device | `PCI\VEN_1022&DEV_15DF` | PCI-enumerated PnP hardware ID | `amdpsp_Device_100` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_805a7fef6dd0\amdpsp.inf` | AMD PSP 10.0 Device | `PCI\VEN_1022&DEV_1649` | PCI-enumerated PnP hardware ID | `amdpsp_Device_100` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_805a7fef6dd0\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_1486` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_805a7fef6dd0\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_13EC` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_805a7fef6dd0\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_1456` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_805a7fef6dd0\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_14CA` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_805a7fef6dd0\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_1537` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_805a7fef6dd0\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_1578` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_805a7fef6dd0\amdsfhkmdf.inf` | AMD Sensor Fusion Hub | `PCI\VEN_1022&DEV_15E4` | PCI-enumerated PnP hardware ID | `amdsfhkmdf_Device` | Native | Native | Native | Native | KMDF 1.15 |
| `d3_Data1.cab_805a7fef6dd0\amdsfhkmdfi2c.inf` | AMD SFH KMDF I2C | `PCI\VEN_1022&DEV_15E6` | PCI-enumerated PnP hardware ID | `amdsfhkmdf_Device` | Native | Native | Native | Native | KMDF 1.15 |
| `d3_Data1.cab_805a7fef6dd0\amdsfhspbi2c.inf` | AMD SFH I2C Controller | `ACPI\AMDI0011` | ACPI-enumerated PnP hardware ID | `amdsfhspbi2c_Device` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_805a7fef6dd0\amdsfhumdf.inf` | AMD UMDF Sensor | `ACPI\AMDI0080` | ACPI-enumerated PnP hardware ID | `amdsfhumdf_Inst` | Native | Native | Native | Native | UMDF 2.15.0 |
| `d3_Data1.cab_805a7fef6dd0\amduart.inf` | AMD UART Controller | `ACPI\AMD0020` | ACPI-enumerated PnP hardware ID | `amduart_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_805a7fef6dd0\amduart.inf` | AMD UART Controller | `ACPI\AMDI0020` | ACPI-enumerated PnP hardware ID | `amduart_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_805a7fef6dd0\amduart.inf` | AMD UART Controller | `ACPI\AMDI0022` | ACPI-enumerated PnP hardware ID | `amduart_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_805a7fef6dd0\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_162E` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `d3_Data1.cab_805a7fef6dd0\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_162F` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `d3_Data1.cab_805a7fef6dd0\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_1668` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `d3_Data1.cab_805a7fef6dd0\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_1669` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `d3_Data1.cab_805a7fef6dd0\amdusb4pcifilter.inf` | PCI Express Root Port | `PCI\VEN_1022&DEV_14CD&SUBSYS_14531022&REV_00` | PCI-enumerated PnP hardware ID | `amdusb4pcifilter` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_805a7fef6dd0\amdusb4pcifilter.inf` | PCI Express Root Port | `PCI\VEN_1022&DEV_14EF&SUBSYS_14531022&REV_00` | PCI-enumerated PnP hardware ID | `amdusb4pcifilter` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_805a7fef6dd0\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15C0&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_805a7fef6dd0\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15C1&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_805a7fef6dd0\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15D6&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_805a7fef6dd0\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15D7&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_805a7fef6dd0\amdwirelessbutton.inf` | AMD Wireless Button Driver | `ACPI\AMDI0051` | ACPI-enumerated PnP hardware ID | `amdwirelessbutton_Device` | Native | Native | Native | Native | KMDF 1.15 |
| `d3_Data1.cab_805a7fef6dd0\ams_mailboxdrv.inf` | AMS-MailBoxDrv | `ACPI\AMDI0090` | ACPI-enumerated PnP hardware ID | `AMS-MailBoxDrv_Device` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_805a7fef6dd0\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4353` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_805a7fef6dd0\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4363` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_805a7fef6dd0\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4372` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_805a7fef6dd0\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4385` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_805a7fef6dd0\smbusamd.inf` | AMD SMBus | `PCI\VEN_1022&DEV_780B` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_805a7fef6dd0\smbusamd.inf` | AMD SMBus | `PCI\VEN_1022&DEV_790B` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_805a7fef6dd0\usbfilter.inf` | AMD USB Filter Driver | `{36FC9E60-C465-11CF-8056-444553540000}\usbfilter` | Device-class-specific ID | `usbfilter` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_805a7fef6dd0\zenpromnf.inf` | ZenProM S0i3 Network Filter | `ZenProMnf` | Network software component ID | `Install` | Native | Native | Native | Native | NotDeclared |

## AMD Chipset Software 4.08.09.2337

| INF | Device | Device identifier | Identifier type | Install section | WS2016 | WS2019 | WS2022 | WS2025 | WDF |
|---|---|---|---|---|---|---|---|---|---|
| `d3_Data1.cab_0be573d4febe\amdas4.inf` | AmdAS4 Device | `ACPI\AMDI0050` | ACPI-enumerated PnP hardware ID | `AmdAS4` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_0be573d4febe\amdas4.inf` | AmdAS4 Device | `ACPI\ASD0001` | ACPI-enumerated PnP hardware ID | `AmdAS4` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_0be573d4febe\amdcir.inf` | AMD CIR Driver | `*AMDC001` | Generic PnP hardware ID | `AMDCIR64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_0be573d4febe\amdcir.inf` | AMD CIR Driver | `*AMDC002` | Generic PnP hardware ID | `AMDCIR64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_0be573d4febe\amdcir.inf` | AMD CIR Driver | `*AMDC003` | Generic PnP hardware ID | `AMDCIR64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_0be573d4febe\amdgpio2.inf` | AMD GPIO Controller | `ACPI\AMD0030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_0be573d4febe\amdgpio2.inf` | AMD GPIO Controller | `ACPI\AMDI0030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_0be573d4febe\amdgpio2.inf` | AMD GPIO Controller | `ACPI\AMDI0031` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_0be573d4febe\amdgpio2.inf` | AMD GPIO Controller | `ACPI\GPIO0010` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_0be573d4febe\amdgpio3.inf` | AMD GPIO Controller | `ACPI\AMDF030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_0be573d4febe\amdgpio3.inf` | AMD GPIO Controller | `ACPI\AMDIF030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_0be573d4febe\amdgpio3.inf` | AMD GPIO Controller | `ACPI\AMDIF031` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_0be573d4febe\amdi2c.inf` | AMD I2C Controller | `ACPI\AMD0010` | ACPI-enumerated PnP hardware ID | `amdi2c_Device` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_0be573d4febe\amdi2c.inf` | AMD I2C Controller | `ACPI\AMDI0010` | ACPI-enumerated PnP hardware ID | `amdi2c_Device` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_0be573d4febe\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1002&DEV_5A23` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_0be573d4febe\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_13E1` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_0be573d4febe\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1419` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_0be573d4febe\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1423` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_0be573d4febe\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1437` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_0be573d4febe\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1451` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_0be573d4febe\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1481` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_0be573d4febe\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1577` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_0be573d4febe\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_164F` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_0be573d4febe\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMD0004` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_0be573d4febe\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMD0005` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_0be573d4febe\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0005` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_0be573d4febe\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0006` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_0be573d4febe\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0007` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_0be573d4febe\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0008` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_0be573d4febe\amdpcidev.inf` | AMD PCI | `PCI\VEN_1002&DEV_145A` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_0be573d4febe\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_1455` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_0be573d4febe\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_145A` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_0be573d4febe\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_1485` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_0be573d4febe\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_148A` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_0be573d4febe\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_14DE` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_0be573d4febe\amdpmf.inf` | AMD PMF | `ACPI\AMDI0100` | ACPI-enumerated PnP hardware ID | `AMDPMF_INSTALL.NTamd64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_0be573d4febe\amdpmf.inf` | AMD PMF | `ACPI\AMDI0102` | ACPI-enumerated PnP hardware ID | `AMDPMF_INSTALL.NTamd64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_0be573d4febe\amdppmpf.inf` | AMD PPM Provisioning File | `ACPI\AMDI0052` | ACPI-enumerated PnP hardware ID | `AMDPPMPF_DEV` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_0be573d4febe\amdpsp.inf` | AMD PSP 10.0 Device | `PCI\VEN_1022&DEV_15DF` | PCI-enumerated PnP hardware ID | `amdpsp_Device_100` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_0be573d4febe\amdpsp.inf` | AMD PSP 10.0 Device | `PCI\VEN_1022&DEV_1649` | PCI-enumerated PnP hardware ID | `amdpsp_Device_100` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_0be573d4febe\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_1486` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_0be573d4febe\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_13EC` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_0be573d4febe\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_1456` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_0be573d4febe\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_14CA` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_0be573d4febe\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_1537` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_0be573d4febe\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_1578` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_0be573d4febe\amdsfhkmdf.inf` | AMD Sensor Fusion Hub | `PCI\VEN_1022&DEV_15E4` | PCI-enumerated PnP hardware ID | `amdsfhkmdf_Device` | Native | Native | Native | Native | KMDF 1.15 |
| `d3_Data1.cab_0be573d4febe\amdsfhkmdfi2c.inf` | AMD SFH KMDF I2C | `PCI\VEN_1022&DEV_15E6` | PCI-enumerated PnP hardware ID | `amdsfhkmdf_Device` | Native | Native | Native | Native | KMDF 1.15 |
| `d3_Data1.cab_0be573d4febe\amdsfhspbi2c.inf` | AMD SFH I2C Controller | `ACPI\AMDI0011` | ACPI-enumerated PnP hardware ID | `amdsfhspbi2c_Device` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_0be573d4febe\amdsfhumdf.inf` | AMD UMDF Sensor | `ACPI\AMDI0080` | ACPI-enumerated PnP hardware ID | `amdsfhumdf_Inst` | Native | Native | Native | Native | UMDF 2.15.0 |
| `d3_Data1.cab_0be573d4febe\amduart.inf` | AMD UART Controller | `ACPI\AMD0020` | ACPI-enumerated PnP hardware ID | `amduart_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_0be573d4febe\amduart.inf` | AMD UART Controller | `ACPI\AMDI0020` | ACPI-enumerated PnP hardware ID | `amduart_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_0be573d4febe\amduart.inf` | AMD UART Controller | `ACPI\AMDI0022` | ACPI-enumerated PnP hardware ID | `amduart_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_0be573d4febe\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_162E` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `d3_Data1.cab_0be573d4febe\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_162F` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `d3_Data1.cab_0be573d4febe\amdusb4pcifilter.inf` | PCI Express Root Port | `PCI\VEN_1022&DEV_14CD&SUBSYS_14531022&REV_00` | PCI-enumerated PnP hardware ID | `amdusb4pcifilter` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_0be573d4febe\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15D6&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_0be573d4febe\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15D7&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_0be573d4febe\amdwirelessbutton.inf` | AMD Wireless Button Driver | `ACPI\AMDI0051` | ACPI-enumerated PnP hardware ID | `amdwirelessbutton_Device` | Native | Native | Native | Native | KMDF 1.15 |
| `d3_Data1.cab_0be573d4febe\ams_mailboxdrv.inf` | AMS-MailBoxDrv | `ACPI\AMDI0090` | ACPI-enumerated PnP hardware ID | `AMS-MailBoxDrv_Device` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_0be573d4febe\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4353` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_0be573d4febe\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4363` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_0be573d4febe\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4372` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_0be573d4febe\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4385` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_0be573d4febe\smbusamd.inf` | AMD SMBus | `PCI\VEN_1022&DEV_780B` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_0be573d4febe\smbusamd.inf` | AMD SMBus | `PCI\VEN_1022&DEV_790B` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_0be573d4febe\usbfilter.inf` | AMD USB Filter Driver | `{36FC9E60-C465-11CF-8056-444553540000}\usbfilter` | Device-class-specific ID | `usbfilter` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_0be573d4febe\zenpromnf.inf` | ZenProM S0i3 Network Filter | `ZenProMnf` | Network software component ID | `Install` | Native | Native | Native | Native | NotDeclared |

## AMD Chipset Software 4.06.10.651

| INF | Device | Device identifier | Identifier type | Install section | WS2016 | WS2019 | WS2022 | WS2025 | WDF |
|---|---|---|---|---|---|---|---|---|---|
| `d3_Data1.cab_6064c00ba69a\amdas4.inf` | AmdAS4 Device | `ACPI\AMDI0050` | ACPI-enumerated PnP hardware ID | `AmdAS4` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_6064c00ba69a\amdas4.inf` | AmdAS4 Device | `ACPI\ASD0001` | ACPI-enumerated PnP hardware ID | `AmdAS4` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_6064c00ba69a\amdcir.inf` | AMD CIR Driver | `*AMDC001` | Generic PnP hardware ID | `AMDCIR64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_6064c00ba69a\amdcir.inf` | AMD CIR Driver | `*AMDC002` | Generic PnP hardware ID | `AMDCIR64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_6064c00ba69a\amdcir.inf` | AMD CIR Driver | `*AMDC003` | Generic PnP hardware ID | `AMDCIR64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_6064c00ba69a\amdgpio2.inf` | AMD GPIO Controller | `ACPI\AMD0030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_6064c00ba69a\amdgpio2.inf` | AMD GPIO Controller | `ACPI\AMDI0030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_6064c00ba69a\amdgpio2.inf` | AMD GPIO Controller | `ACPI\AMDI0031` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_6064c00ba69a\amdgpio2.inf` | AMD GPIO Controller | `ACPI\GPIO0010` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_6064c00ba69a\amdgpio3.inf` | AMD GPIO Controller | `ACPI\AMDF030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_6064c00ba69a\amdgpio3.inf` | AMD GPIO Controller | `ACPI\AMDIF030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_6064c00ba69a\amdgpio3.inf` | AMD GPIO Controller | `ACPI\AMDIF031` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_6064c00ba69a\amdi2c.inf` | AMD I2C Controller | `ACPI\AMD0010` | ACPI-enumerated PnP hardware ID | `amdi2c_Device` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_6064c00ba69a\amdi2c.inf` | AMD I2C Controller | `ACPI\AMDI0010` | ACPI-enumerated PnP hardware ID | `amdi2c_Device` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_6064c00ba69a\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1002&DEV_5A23` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_6064c00ba69a\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_13E1` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_6064c00ba69a\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1419` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_6064c00ba69a\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1423` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_6064c00ba69a\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1437` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_6064c00ba69a\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1451` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_6064c00ba69a\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1481` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_6064c00ba69a\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1577` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_6064c00ba69a\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_164F` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_6064c00ba69a\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMD0004` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_6064c00ba69a\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMD0005` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_6064c00ba69a\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0005` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_6064c00ba69a\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0006` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_6064c00ba69a\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0007` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_6064c00ba69a\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0008` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_6064c00ba69a\amdpcidev.inf` | AMD PCI | `PCI\VEN_1002&DEV_145A` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_6064c00ba69a\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_1455` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_6064c00ba69a\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_145A` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_6064c00ba69a\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_1485` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_6064c00ba69a\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_148A` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_6064c00ba69a\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_14DE` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_6064c00ba69a\amdpmf.inf` | AMD PMF | `ACPI\AMDI0100` | ACPI-enumerated PnP hardware ID | `AMDPMF_INSTALL.NTamd64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_6064c00ba69a\amdpmf.inf` | AMD PMF | `ACPI\AMDI0102` | ACPI-enumerated PnP hardware ID | `AMDPMF_INSTALL.NTamd64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_6064c00ba69a\amdppmpf.inf` | AMD PPM Provisioning File | `ACPI\AMDI0052` | ACPI-enumerated PnP hardware ID | `AMDPPMPF_DEV` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_6064c00ba69a\amdpsp.inf` | AMD PSP 10.0 Device | `PCI\VEN_1022&DEV_15DF` | PCI-enumerated PnP hardware ID | `amdpsp_Device_100` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_6064c00ba69a\amdpsp.inf` | AMD PSP 10.0 Device | `PCI\VEN_1022&DEV_1649` | PCI-enumerated PnP hardware ID | `amdpsp_Device_100` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_6064c00ba69a\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_1486` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_6064c00ba69a\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_13EC` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_6064c00ba69a\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_1456` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_6064c00ba69a\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_14CA` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_6064c00ba69a\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_1537` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_6064c00ba69a\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_1578` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_6064c00ba69a\amdsfhkmdf.inf` | AMD Sensor Fusion Hub | `PCI\VEN_1022&DEV_15E4` | PCI-enumerated PnP hardware ID | `amdsfhkmdf_Device` | Native | Native | Native | Native | KMDF 1.15 |
| `d3_Data1.cab_6064c00ba69a\amdsfhkmdfi2c.inf` | AMD SFH KMDF I2C | `PCI\VEN_1022&DEV_15E6` | PCI-enumerated PnP hardware ID | `amdsfhkmdf_Device` | Native | Native | Native | Native | KMDF 1.15 |
| `d3_Data1.cab_6064c00ba69a\amdsfhspbi2c.inf` | AMD SFH I2C Controller | `ACPI\AMDI0011` | ACPI-enumerated PnP hardware ID | `amdsfhspbi2c_Device` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_6064c00ba69a\amdsfhumdf.inf` | AMD UMDF Sensor | `ACPI\AMDI0080` | ACPI-enumerated PnP hardware ID | `amdsfhumdf_Inst` | Native | Native | Native | Native | UMDF 2.15.0 |
| `d3_Data1.cab_6064c00ba69a\amduart.inf` | AMD UART Controller | `ACPI\AMD0020` | ACPI-enumerated PnP hardware ID | `amduart_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_6064c00ba69a\amduart.inf` | AMD UART Controller | `ACPI\AMDI0020` | ACPI-enumerated PnP hardware ID | `amduart_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_6064c00ba69a\amduart.inf` | AMD UART Controller | `ACPI\AMDI0022` | ACPI-enumerated PnP hardware ID | `amduart_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_6064c00ba69a\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_162E` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `d3_Data1.cab_6064c00ba69a\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_162F` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `d3_Data1.cab_6064c00ba69a\amdusb4pcifilter.inf` | PCI Express Root Port | `PCI\VEN_1022&DEV_14CD&SUBSYS_14531022&REV_00` | PCI-enumerated PnP hardware ID | `amdusb4pcifilter` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_6064c00ba69a\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15D6&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_6064c00ba69a\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15D7&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_6064c00ba69a\amdwirelessbutton.inf` | AMD Wireless Button Driver | `ACPI\AMDI0051` | ACPI-enumerated PnP hardware ID | `amdwirelessbutton_Device` | Native | Native | Native | Native | KMDF 1.15 |
| `d3_Data1.cab_6064c00ba69a\ams_mailboxdrv.inf` | AMS-MailBoxDrv | `ACPI\AMDI0090` | ACPI-enumerated PnP hardware ID | `AMS-MailBoxDrv_Device` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_6064c00ba69a\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4353` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_6064c00ba69a\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4363` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_6064c00ba69a\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4372` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_6064c00ba69a\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4385` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_6064c00ba69a\smbusamd.inf` | AMD SMBus | `PCI\VEN_1022&DEV_780B` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_6064c00ba69a\smbusamd.inf` | AMD SMBus | `PCI\VEN_1022&DEV_790B` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_6064c00ba69a\usbfilter.inf` | AMD USB Filter Driver | `{36FC9E60-C465-11CF-8056-444553540000}\usbfilter` | Device-class-specific ID | `usbfilter` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_6064c00ba69a\zenpromnf.inf` | ZenProM S0i3 Network Filter | `ZenProMnf` | Network software component ID | `Install` | Native | Native | Native | Native | NotDeclared |

## AMD Chipset Software 4.03.03.431

| INF | Device | Device identifier | Identifier type | Install section | WS2016 | WS2019 | WS2022 | WS2025 | WDF |
|---|---|---|---|---|---|---|---|---|---|
| `d3_Data1.cab_e2f59b723e67\amdas4.inf` | AmdAS4 Device | `ACPI\AMDI0050` | ACPI-enumerated PnP hardware ID | `AmdAS4` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_e2f59b723e67\amdas4.inf` | AmdAS4 Device | `ACPI\ASD0001` | ACPI-enumerated PnP hardware ID | `AmdAS4` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_e2f59b723e67\amdcir.inf` | AMD CIR Driver | `*AMDC001` | Generic PnP hardware ID | `AMDCIR64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_e2f59b723e67\amdcir.inf` | AMD CIR Driver | `*AMDC002` | Generic PnP hardware ID | `AMDCIR64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_e2f59b723e67\amdcir.inf` | AMD CIR Driver | `*AMDC003` | Generic PnP hardware ID | `AMDCIR64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_e2f59b723e67\amdgpio2.inf` | AMD GPIO Controller | `ACPI\AMD0030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_e2f59b723e67\amdgpio2.inf` | AMD GPIO Controller | `ACPI\AMDI0030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_e2f59b723e67\amdgpio2.inf` | AMD GPIO Controller | `ACPI\AMDI0031` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_e2f59b723e67\amdgpio2.inf` | AMD GPIO Controller | `ACPI\GPIO0010` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_e2f59b723e67\amdgpio3.inf` | AMD GPIO Controller | `ACPI\AMDF030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_e2f59b723e67\amdgpio3.inf` | AMD GPIO Controller | `ACPI\AMDIF030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_e2f59b723e67\amdgpio3.inf` | AMD GPIO Controller | `ACPI\AMDIF031` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_e2f59b723e67\amdi2c.inf` | AMD I2C Controller | `ACPI\AMD0010` | ACPI-enumerated PnP hardware ID | `amdi2c_Device` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_e2f59b723e67\amdi2c.inf` | AMD I2C Controller | `ACPI\AMDI0010` | ACPI-enumerated PnP hardware ID | `amdi2c_Device` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_e2f59b723e67\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1002&DEV_5A23` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_e2f59b723e67\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_13E1` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_e2f59b723e67\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1419` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_e2f59b723e67\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1423` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_e2f59b723e67\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1437` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_e2f59b723e67\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1451` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_e2f59b723e67\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1481` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_e2f59b723e67\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1577` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_e2f59b723e67\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_164F` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_e2f59b723e67\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMD0004` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_e2f59b723e67\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMD0005` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_e2f59b723e67\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0005` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_e2f59b723e67\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0006` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_e2f59b723e67\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0007` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_e2f59b723e67\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0008` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_e2f59b723e67\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_1455` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_e2f59b723e67\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_145A` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_e2f59b723e67\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_1485` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_e2f59b723e67\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_148A` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_e2f59b723e67\amdpsp.inf` | AMD PSP 10.0 Device | `PCI\VEN_1022&DEV_15DF` | PCI-enumerated PnP hardware ID | `amdpsp_Device_100` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_e2f59b723e67\amdpsp.inf` | AMD PSP 10.0 Device | `PCI\VEN_1022&DEV_1649` | PCI-enumerated PnP hardware ID | `amdpsp_Device_100` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_e2f59b723e67\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_1486` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_e2f59b723e67\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_13EC` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_e2f59b723e67\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_1456` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_e2f59b723e67\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_14CA` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_e2f59b723e67\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_1537` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_e2f59b723e67\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_1578` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_e2f59b723e67\amdsfhkmdf.inf` | AMD Sensor Fusion Hub | `PCI\VEN_1022&DEV_15E4` | PCI-enumerated PnP hardware ID | `amdsfhkmdf_Device` | Native | Native | Native | Native | KMDF 1.15 |
| `d3_Data1.cab_e2f59b723e67\amdsfhkmdfi2c.inf` | AMD SFH KMDF I2C | `PCI\VEN_1022&DEV_15E6` | PCI-enumerated PnP hardware ID | `amdsfhkmdf_Device` | Native | Native | Native | Native | KMDF 1.15 |
| `d3_Data1.cab_e2f59b723e67\amdsfhspbi2c.inf` | AMD SFH I2C Controller | `ACPI\AMDI0011` | ACPI-enumerated PnP hardware ID | `amdsfhspbi2c_Device` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_e2f59b723e67\amdsfhumdf.inf` | AMD UMDF Sensor | `ACPI\AMDI0080` | ACPI-enumerated PnP hardware ID | `amdsfhumdf_Inst` | Native | Native | Native | Native | UMDF 2.15.0 |
| `d3_Data1.cab_e2f59b723e67\amduart.inf` | AMD UART Controller | `ACPI\AMD0020` | ACPI-enumerated PnP hardware ID | `amduart_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_e2f59b723e67\amduart.inf` | AMD UART Controller | `ACPI\AMDI0020` | ACPI-enumerated PnP hardware ID | `amduart_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_e2f59b723e67\amduart.inf` | AMD UART Controller | `ACPI\AMDI0022` | ACPI-enumerated PnP hardware ID | `amduart_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_e2f59b723e67\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4353` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_e2f59b723e67\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4363` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_e2f59b723e67\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4372` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_e2f59b723e67\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4385` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_e2f59b723e67\smbusamd.inf` | AMD SMBus | `PCI\VEN_1022&DEV_780B` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_e2f59b723e67\smbusamd.inf` | AMD SMBus | `PCI\VEN_1022&DEV_790B` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_e2f59b723e67\usbfilter.inf` | AMD USB Filter Driver | `{36FC9E60-C465-11CF-8056-444553540000}\usbfilter` | Device-class-specific ID | `usbfilter` | Native | Native | Native | Native | NotDeclared |

## AMD Chipset Software 3.10.08.506

| INF | Device | Device identifier | Identifier type | Install section | WS2016 | WS2019 | WS2022 | WS2025 | WDF |
|---|---|---|---|---|---|---|---|---|---|
| `d3_Data1.cab_d3ffa5f6368f\amdas4.inf` | AmdAS4 Device | `ACPI\AMDI0050` | ACPI-enumerated PnP hardware ID | `AmdAS4` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_d3ffa5f6368f\amdas4.inf` | AmdAS4 Device | `ACPI\ASD0001` | ACPI-enumerated PnP hardware ID | `AmdAS4` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_d3ffa5f6368f\amdcir.inf` | AMD CIR Driver | `*AMDC001` | Generic PnP hardware ID | `AMDCIR64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_d3ffa5f6368f\amdcir.inf` | AMD CIR Driver | `*AMDC002` | Generic PnP hardware ID | `AMDCIR64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_d3ffa5f6368f\amdcir.inf` | AMD CIR Driver | `*AMDC003` | Generic PnP hardware ID | `AMDCIR64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_d3ffa5f6368f\amdgpio2.inf` | AMD GPIO Controller | `ACPI\AMD0030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_d3ffa5f6368f\amdgpio2.inf` | AMD GPIO Controller | `ACPI\AMDI0030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_d3ffa5f6368f\amdgpio2.inf` | AMD GPIO Controller | `ACPI\AMDI0031` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_d3ffa5f6368f\amdgpio2.inf` | AMD GPIO Controller | `ACPI\GPIO0010` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_d3ffa5f6368f\amdgpio3.inf` | AMD GPIO Controller | `ACPI\AMDF030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_d3ffa5f6368f\amdgpio3.inf` | AMD GPIO Controller | `ACPI\AMDIF030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_d3ffa5f6368f\amdi2c.inf` | AMD I2C Controller | `ACPI\AMD0010` | ACPI-enumerated PnP hardware ID | `amdi2c_Device` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_d3ffa5f6368f\amdi2c.inf` | AMD I2C Controller | `ACPI\AMDI0010` | ACPI-enumerated PnP hardware ID | `amdi2c_Device` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_d3ffa5f6368f\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1002&DEV_5A23` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_d3ffa5f6368f\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_13E1` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_d3ffa5f6368f\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1419` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_d3ffa5f6368f\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1423` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_d3ffa5f6368f\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1437` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_d3ffa5f6368f\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1451` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_d3ffa5f6368f\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1481` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_d3ffa5f6368f\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1577` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_d3ffa5f6368f\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_164F` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_d3ffa5f6368f\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMD0004` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_d3ffa5f6368f\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMD0005` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_d3ffa5f6368f\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0005` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_d3ffa5f6368f\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0006` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_d3ffa5f6368f\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0007` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_d3ffa5f6368f\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_1455` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_d3ffa5f6368f\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_145A` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_d3ffa5f6368f\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_1485` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_d3ffa5f6368f\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_148A` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_d3ffa5f6368f\amdpsp.inf` | AMD PSP 1.0 Device | `PCI\VEN_1022&DEV_1537` | PCI-enumerated PnP hardware ID | `amdpsp_Device_10` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_d3ffa5f6368f\amdpsp.inf` | AMD PSP 10.0 Device | `PCI\VEN_1022&DEV_15DF` | PCI-enumerated PnP hardware ID | `amdpsp_Device_100` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_d3ffa5f6368f\amdpsp.inf` | AMD PSP 10.0 Device | `PCI\VEN_1022&DEV_1649` | PCI-enumerated PnP hardware ID | `amdpsp_Device_100` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_d3ffa5f6368f\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_1486` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_d3ffa5f6368f\amdpsp.inf` | AMD PSP 12.0 Device | `PCI\VEN_1022&DEV_13EC` | PCI-enumerated PnP hardware ID | `amdpsp_Device_120` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_d3ffa5f6368f\amdpsp.inf` | AMD PSP 2.0 Device | `PCI\VEN_1022&DEV_1578` | PCI-enumerated PnP hardware ID | `amdpsp_Device_20` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_d3ffa5f6368f\amdpsp.inf` | AMD PSP 3.0 Device | `PCI\VEN_1022&DEV_1456` | PCI-enumerated PnP hardware ID | `amdpsp_Device_30` | Native | Native | Native | Native | KMDF 1.11 |
| `d3_Data1.cab_d3ffa5f6368f\amdsfhkmdf.inf` | AMD Sensor Fusion Hub | `PCI\VEN_1022&DEV_15E4` | PCI-enumerated PnP hardware ID | `amdsfhkmdf_Device` | Native | Native | Native | Native | KMDF 1.15 |
| `d3_Data1.cab_d3ffa5f6368f\amdsfhkmdfi2c.inf` | AMD SFH KMDF I2C | `PCI\VEN_1022&DEV_15E6` | PCI-enumerated PnP hardware ID | `amdsfhkmdf_Device` | Native | Native | Native | Native | KMDF 1.15 |
| `d3_Data1.cab_d3ffa5f6368f\amdsfhspbi2c.inf` | AMD SFH I2C Controller | `ACPI\AMDI0011` | ACPI-enumerated PnP hardware ID | `amdsfhspbi2c_Device` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_d3ffa5f6368f\amdsfhumdf.inf` | AMD UMDF Sensor | `ACPI\AMDI0080` | ACPI-enumerated PnP hardware ID | `amdsfhumdf_Inst` | Native | Native | Native | Native | UMDF 2.15.0 |
| `d3_Data1.cab_d3ffa5f6368f\amduart.inf` | AMD UART Controller | `ACPI\AMD0020` | ACPI-enumerated PnP hardware ID | `amduart_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_d3ffa5f6368f\amduart.inf` | AMD UART Controller | `ACPI\AMDI0020` | ACPI-enumerated PnP hardware ID | `amduart_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_d3ffa5f6368f\amduart.inf` | AMD UART Controller | `ACPI\AMDI0022` | ACPI-enumerated PnP hardware ID | `amduart_Inst` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_d3ffa5f6368f\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4353` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_d3ffa5f6368f\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4363` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_d3ffa5f6368f\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4372` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_d3ffa5f6368f\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4385` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_d3ffa5f6368f\smbusamd.inf` | AMD SMBus | `PCI\VEN_1022&DEV_780B` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_d3ffa5f6368f\smbusamd.inf` | AMD SMBus | `PCI\VEN_1022&DEV_790B` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `d3_Data1.cab_d3ffa5f6368f\usbfilter.inf` | AMD USB Filter Driver | `{36FC9E60-C465-11CF-8056-444553540000}\usbfilter` | Device-class-specific ID | `usbfilter` | Native | Native | Native | Native | NotDeclared |

## AMD Chipset Software 3.09.01.140

| INF | Device | Device identifier | Identifier type | Install section | WS2016 | WS2019 | WS2022 | WS2025 | WDF |
|---|---|---|---|---|---|---|---|---|---|
| `d4_Data1.cab_d405da9406d9\amdas4.inf` | AmdAS4 Device | `ACPI\AMDI0050` | ACPI-enumerated PnP hardware ID | `AmdAS4` | Native | Native | Native | Native | NotDeclared |
| `d4_Data1.cab_d405da9406d9\amdas4.inf` | AmdAS4 Device | `ACPI\ASD0001` | ACPI-enumerated PnP hardware ID | `AmdAS4` | Native | Native | Native | Native | NotDeclared |
| `d4_Data1.cab_d405da9406d9\amdcir.inf` | AMD CIR Driver | `*AMDC001` | Generic PnP hardware ID | `AMDCIR64` | Native | Native | Native | Native | NotDeclared |
| `d4_Data1.cab_d405da9406d9\amdcir.inf` | AMD CIR Driver | `*AMDC002` | Generic PnP hardware ID | `AMDCIR64` | Native | Native | Native | Native | NotDeclared |
| `d4_Data1.cab_d405da9406d9\amdcir.inf` | AMD CIR Driver | `*AMDC003` | Generic PnP hardware ID | `AMDCIR64` | Native | Native | Native | Native | NotDeclared |
| `d4_Data1.cab_d405da9406d9\amdgpio2.inf` | AMD GPIO Controller | `ACPI\AMD0030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `d4_Data1.cab_d405da9406d9\amdgpio2.inf` | AMD GPIO Controller | `ACPI\AMDI0030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `d4_Data1.cab_d405da9406d9\amdgpio2.inf` | AMD GPIO Controller | `ACPI\AMDI0031` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `d4_Data1.cab_d405da9406d9\amdgpio2.inf` | AMD GPIO Controller | `ACPI\GPIO0010` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `d4_Data1.cab_d405da9406d9\amdgpio3.inf` | AMD GPIO Controller | `ACPI\AMDF030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `d4_Data1.cab_d405da9406d9\amdgpio3.inf` | AMD GPIO Controller | `ACPI\AMDIF030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `d4_Data1.cab_d405da9406d9\amdi2c.inf` | AMD I2C Controller | `ACPI\AMD0010` | ACPI-enumerated PnP hardware ID | `amdi2c_Device` | Native | Native | Native | Native | NotDeclared |
| `d4_Data1.cab_d405da9406d9\amdi2c.inf` | AMD I2C Controller | `ACPI\AMDI0010` | ACPI-enumerated PnP hardware ID | `amdi2c_Device` | Native | Native | Native | Native | NotDeclared |
| `d4_Data1.cab_d405da9406d9\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1002&DEV_5A23` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d4_Data1.cab_d405da9406d9\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_13E1` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d4_Data1.cab_d405da9406d9\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1419` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d4_Data1.cab_d405da9406d9\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1423` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d4_Data1.cab_d405da9406d9\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1437` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d4_Data1.cab_d405da9406d9\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1451` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d4_Data1.cab_d405da9406d9\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1481` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d4_Data1.cab_d405da9406d9\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1577` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d4_Data1.cab_d405da9406d9\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_164F` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d4_Data1.cab_d405da9406d9\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMD0004` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `d4_Data1.cab_d405da9406d9\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMD0005` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `d4_Data1.cab_d405da9406d9\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0005` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `d4_Data1.cab_d405da9406d9\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0006` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `d4_Data1.cab_d405da9406d9\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0007` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `d4_Data1.cab_d405da9406d9\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_1455` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `d4_Data1.cab_d405da9406d9\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_145A` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `d4_Data1.cab_d405da9406d9\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_1485` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `d4_Data1.cab_d405da9406d9\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_148A` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `d4_Data1.cab_d405da9406d9\amdpsp.inf` | AMD PSP 1.0 Device | `PCI\VEN_1022&DEV_1537` | PCI-enumerated PnP hardware ID | `amdpsp_Device_10` | Native | Native | Native | Native | KMDF 1.11 |
| `d4_Data1.cab_d405da9406d9\amdpsp.inf` | AMD PSP 10.0 Device | `PCI\VEN_1022&DEV_15DF` | PCI-enumerated PnP hardware ID | `amdpsp_Device_100` | Native | Native | Native | Native | KMDF 1.11 |
| `d4_Data1.cab_d405da9406d9\amdpsp.inf` | AMD PSP 10.0 Device | `PCI\VEN_1022&DEV_1649` | PCI-enumerated PnP hardware ID | `amdpsp_Device_100` | Native | Native | Native | Native | KMDF 1.11 |
| `d4_Data1.cab_d405da9406d9\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_1486` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | Native | Native | Native | KMDF 1.11 |
| `d4_Data1.cab_d405da9406d9\amdpsp.inf` | AMD PSP 12.0 Device | `PCI\VEN_1022&DEV_13EC` | PCI-enumerated PnP hardware ID | `amdpsp_Device_120` | Native | Native | Native | Native | KMDF 1.11 |
| `d4_Data1.cab_d405da9406d9\amdpsp.inf` | AMD PSP 2.0 Device | `PCI\VEN_1022&DEV_1578` | PCI-enumerated PnP hardware ID | `amdpsp_Device_20` | Native | Native | Native | Native | KMDF 1.11 |
| `d4_Data1.cab_d405da9406d9\amdpsp.inf` | AMD PSP 3.0 Device | `PCI\VEN_1022&DEV_1456` | PCI-enumerated PnP hardware ID | `amdpsp_Device_30` | Native | Native | Native | Native | KMDF 1.11 |
| `d4_Data1.cab_d405da9406d9\amdsfhkmdf.inf` | AMD Sensor Fusion Hub | `PCI\VEN_1022&DEV_15E4` | PCI-enumerated PnP hardware ID | `amdsfhkmdf_Device` | Native | Native | Native | Native | KMDF 1.15 |
| `d4_Data1.cab_d405da9406d9\amdsfhkmdfi2c.inf` | AMD SFH KMDF I2C | `PCI\VEN_1022&DEV_15E6` | PCI-enumerated PnP hardware ID | `amdsfhkmdf_Device` | Native | Native | Native | Native | KMDF 1.15 |
| `d4_Data1.cab_d405da9406d9\amdsfhspbi2c.inf` | AMD SFH I2C Controller | `ACPI\AMDI0011` | ACPI-enumerated PnP hardware ID | `amdsfhspbi2c_Device` | Native | Native | Native | Native | NotDeclared |
| `d4_Data1.cab_d405da9406d9\amdsfhumdf.inf` | AMD UMDF Sensor | `ACPI\AMDI0080` | ACPI-enumerated PnP hardware ID | `amdsfhumdf_Inst` | Native | Native | Native | Native | UMDF 2.15.0 |
| `d4_Data1.cab_d405da9406d9\amduart.inf` | AMD UART Controller | `ACPI\AMD0020` | ACPI-enumerated PnP hardware ID | `amduart_Inst` | Native | Native | Native | Native | NotDeclared |
| `d4_Data1.cab_d405da9406d9\amduart.inf` | AMD UART Controller | `ACPI\AMDI0020` | ACPI-enumerated PnP hardware ID | `amduart_Inst` | Native | Native | Native | Native | NotDeclared |
| `d4_Data1.cab_d405da9406d9\amduart.inf` | AMD UART Controller | `ACPI\AMDI0022` | ACPI-enumerated PnP hardware ID | `amduart_Inst` | Native | Native | Native | Native | NotDeclared |
| `d4_Data1.cab_d405da9406d9\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4353` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `d4_Data1.cab_d405da9406d9\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4363` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `d4_Data1.cab_d405da9406d9\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4372` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `d4_Data1.cab_d405da9406d9\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4385` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `d4_Data1.cab_d405da9406d9\smbusamd.inf` | AMD SMBus | `PCI\VEN_1022&DEV_780B` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `d4_Data1.cab_d405da9406d9\smbusamd.inf` | AMD SMBus | `PCI\VEN_1022&DEV_790B` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `d4_Data1.cab_d405da9406d9\usbfilter.inf` | AMD USB Filter Driver | `{36FC9E60-C465-11CF-8056-444553540000}\usbfilter` | Device-class-specific ID | `usbfilter` | Native | Native | Native | Native | NotDeclared |

## AMD Chipset Software 3.08.17.735

| INF | Device | Device identifier | Identifier type | Install section | WS2016 | WS2019 | WS2022 | WS2025 | WDF |
|---|---|---|---|---|---|---|---|---|---|
| `d4_Data1.cab_56997d5ae0ea\amdas4.inf` | AmdAS4 Device | `ACPI\AMDI0050` | ACPI-enumerated PnP hardware ID | `AmdAS4` | Native | Native | Native | Native | NotDeclared |
| `d4_Data1.cab_56997d5ae0ea\amdas4.inf` | AmdAS4 Device | `ACPI\ASD0001` | ACPI-enumerated PnP hardware ID | `AmdAS4` | Native | Native | Native | Native | NotDeclared |
| `d4_Data1.cab_56997d5ae0ea\amdcir.inf` | AMD CIR Driver | `*AMDC001` | Generic PnP hardware ID | `AMDCIR64` | Native | Native | Native | Native | NotDeclared |
| `d4_Data1.cab_56997d5ae0ea\amdcir.inf` | AMD CIR Driver | `*AMDC002` | Generic PnP hardware ID | `AMDCIR64` | Native | Native | Native | Native | NotDeclared |
| `d4_Data1.cab_56997d5ae0ea\amdcir.inf` | AMD CIR Driver | `*AMDC003` | Generic PnP hardware ID | `AMDCIR64` | Native | Native | Native | Native | NotDeclared |
| `d4_Data1.cab_56997d5ae0ea\amdgpio2.inf` | AMD GPIO Controller | `ACPI\AMD0030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `d4_Data1.cab_56997d5ae0ea\amdgpio2.inf` | AMD GPIO Controller | `ACPI\AMDI0030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `d4_Data1.cab_56997d5ae0ea\amdgpio2.inf` | AMD GPIO Controller | `ACPI\AMDI0031` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `d4_Data1.cab_56997d5ae0ea\amdgpio2.inf` | AMD GPIO Controller | `ACPI\GPIO0010` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `d4_Data1.cab_56997d5ae0ea\amdgpio3.inf` | AMD GPIO Controller | `ACPI\AMDF030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `d4_Data1.cab_56997d5ae0ea\amdgpio3.inf` | AMD GPIO Controller | `ACPI\AMDIF030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `d4_Data1.cab_56997d5ae0ea\amdi2c.inf` | AMD I2C Controller | `ACPI\AMD0010` | ACPI-enumerated PnP hardware ID | `amdi2c_Device` | Native | Native | Native | Native | NotDeclared |
| `d4_Data1.cab_56997d5ae0ea\amdi2c.inf` | AMD I2C Controller | `ACPI\AMDI0010` | ACPI-enumerated PnP hardware ID | `amdi2c_Device` | Native | Native | Native | Native | NotDeclared |
| `d4_Data1.cab_56997d5ae0ea\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1002&DEV_5A23` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d4_Data1.cab_56997d5ae0ea\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_13E1` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d4_Data1.cab_56997d5ae0ea\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1419` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d4_Data1.cab_56997d5ae0ea\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1423` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d4_Data1.cab_56997d5ae0ea\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1437` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d4_Data1.cab_56997d5ae0ea\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1451` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d4_Data1.cab_56997d5ae0ea\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1481` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d4_Data1.cab_56997d5ae0ea\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1577` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d4_Data1.cab_56997d5ae0ea\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_164F` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d4_Data1.cab_56997d5ae0ea\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMD0004` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `d4_Data1.cab_56997d5ae0ea\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMD0005` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `d4_Data1.cab_56997d5ae0ea\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0005` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `d4_Data1.cab_56997d5ae0ea\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0006` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `d4_Data1.cab_56997d5ae0ea\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0007` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `d4_Data1.cab_56997d5ae0ea\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_1455` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `d4_Data1.cab_56997d5ae0ea\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_145A` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `d4_Data1.cab_56997d5ae0ea\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_1485` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `d4_Data1.cab_56997d5ae0ea\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_148A` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `d4_Data1.cab_56997d5ae0ea\amdpsp.inf` | AMD PSP 1.0 Device | `PCI\VEN_1022&DEV_1537` | PCI-enumerated PnP hardware ID | `amdpsp_Device_10` | Native | Native | Native | Native | KMDF 1.11 |
| `d4_Data1.cab_56997d5ae0ea\amdpsp.inf` | AMD PSP 10.0 Device | `PCI\VEN_1022&DEV_15DF` | PCI-enumerated PnP hardware ID | `amdpsp_Device_100` | Native | Native | Native | Native | KMDF 1.11 |
| `d4_Data1.cab_56997d5ae0ea\amdpsp.inf` | AMD PSP 10.0 Device | `PCI\VEN_1022&DEV_1649` | PCI-enumerated PnP hardware ID | `amdpsp_Device_100` | Native | Native | Native | Native | KMDF 1.11 |
| `d4_Data1.cab_56997d5ae0ea\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_1486` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | Native | Native | Native | KMDF 1.11 |
| `d4_Data1.cab_56997d5ae0ea\amdpsp.inf` | AMD PSP 12.0 Device | `PCI\VEN_1022&DEV_13EC` | PCI-enumerated PnP hardware ID | `amdpsp_Device_120` | Native | Native | Native | Native | KMDF 1.11 |
| `d4_Data1.cab_56997d5ae0ea\amdpsp.inf` | AMD PSP 2.0 Device | `PCI\VEN_1022&DEV_1578` | PCI-enumerated PnP hardware ID | `amdpsp_Device_20` | Native | Native | Native | Native | KMDF 1.11 |
| `d4_Data1.cab_56997d5ae0ea\amdpsp.inf` | AMD PSP 3.0 Device | `PCI\VEN_1022&DEV_1456` | PCI-enumerated PnP hardware ID | `amdpsp_Device_30` | Native | Native | Native | Native | KMDF 1.11 |
| `d4_Data1.cab_56997d5ae0ea\amdsfhkmdf.inf` | AMD Sensor Fusion Hub | `PCI\VEN_1022&DEV_15E4` | PCI-enumerated PnP hardware ID | `amdsfhkmdf_Device` | Native | Native | Native | Native | KMDF 1.15 |
| `d4_Data1.cab_56997d5ae0ea\amdsfhkmdfi2c.inf` | AMD SFH KMDF I2C | `PCI\VEN_1022&DEV_15E6` | PCI-enumerated PnP hardware ID | `amdsfhkmdf_Device` | Native | Native | Native | Native | KMDF 1.15 |
| `d4_Data1.cab_56997d5ae0ea\amdsfhspbi2c.inf` | AMD SFH I2C Controller | `ACPI\AMDI0011` | ACPI-enumerated PnP hardware ID | `amdsfhspbi2c_Device` | Native | Native | Native | Native | NotDeclared |
| `d4_Data1.cab_56997d5ae0ea\amdsfhumdf.inf` | AMD UMDF Sensor | `ACPI\AMDI0080` | ACPI-enumerated PnP hardware ID | `amdsfhumdf_Inst` | Native | Native | Native | Native | UMDF 2.15.0 |
| `d4_Data1.cab_56997d5ae0ea\amduart.inf` | AMD UART Controller | `ACPI\AMD0020` | ACPI-enumerated PnP hardware ID | `amduart_Inst` | Native | Native | Native | Native | NotDeclared |
| `d4_Data1.cab_56997d5ae0ea\amduart.inf` | AMD UART Controller | `ACPI\AMDI0020` | ACPI-enumerated PnP hardware ID | `amduart_Inst` | Native | Native | Native | Native | NotDeclared |
| `d4_Data1.cab_56997d5ae0ea\amduart.inf` | AMD UART Controller | `ACPI\AMDI0022` | ACPI-enumerated PnP hardware ID | `amduart_Inst` | Native | Native | Native | Native | NotDeclared |
| `d4_Data1.cab_56997d5ae0ea\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4353` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `d4_Data1.cab_56997d5ae0ea\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4363` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `d4_Data1.cab_56997d5ae0ea\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4372` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `d4_Data1.cab_56997d5ae0ea\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4385` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `d4_Data1.cab_56997d5ae0ea\smbusamd.inf` | AMD SMBus | `PCI\VEN_1022&DEV_780B` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `d4_Data1.cab_56997d5ae0ea\smbusamd.inf` | AMD SMBus | `PCI\VEN_1022&DEV_790B` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `d4_Data1.cab_56997d5ae0ea\usbfilter.inf` | AMD USB Filter Driver | `{36FC9E60-C465-11CF-8056-444553540000}\usbfilter` | Device-class-specific ID | `usbfilter` | Native | Native | Native | Native | NotDeclared |

## AMD Chipset Software 2.04.04.111

| INF | Device | Device identifier | Identifier type | Install section | WS2016 | WS2019 | WS2022 | WS2025 | WDF |
|---|---|---|---|---|---|---|---|---|---|
| `d4_Data1.cab_9ed7c73e0e1f\amd_sata.inf` | AMD SATA Controller | `PCI\VEN_1002&DEV_4391&CC_0106` | PCI-enumerated PnP hardware ID | `amd_sata_inst` | Native | Native | Native | Native | NotDeclared |
| `d4_Data1.cab_9ed7c73e0e1f\amd_sata.inf` | AMD SATA Controller | `PCI\VEN_1002&DEV_4394&CC_0106` | PCI-enumerated PnP hardware ID | `amd_sata_inst` | Native | Native | Native | Native | NotDeclared |
| `d4_Data1.cab_9ed7c73e0e1f\amd_sata.inf` | AMD SATA Controller | `PCI\VEN_1022&DEV_7801&CC_0106` | PCI-enumerated PnP hardware ID | `amd_sata_inst` | Native | Native | Native | Native | NotDeclared |
| `d4_Data1.cab_9ed7c73e0e1f\amd_sata.inf` | AMD SATA Controller | `PCI\VEN_1022&DEV_7804&CC_0106` | PCI-enumerated PnP hardware ID | `amd_sata_inst` | Native | Native | Native | Native | NotDeclared |
| `d4_Data1.cab_9ed7c73e0e1f\amd_sata.inf` | AMD SATA Controller | `PCI\VEN_1022&DEV_7901&CC_0106` | PCI-enumerated PnP hardware ID | `amd_sata_inst` | Native | Native | Native | Native | NotDeclared |
| `d4_Data1.cab_9ed7c73e0e1f\amd_sata.inf` | AMD SATA Controller | `PCI\VEN_1022&DEV_7904&CC_0106` | PCI-enumerated PnP hardware ID | `amd_sata_inst` | Native | Native | Native | Native | NotDeclared |
| `d4_Data1.cab_9ed7c73e0e1f\amdas4.inf` | AmdAS4 Device | `ACPI\AMDI0050` | ACPI-enumerated PnP hardware ID | `AmdAS4` | Native | Native | Native | Native | NotDeclared |
| `d4_Data1.cab_9ed7c73e0e1f\amdas4.inf` | AmdAS4 Device | `ACPI\ASD0001` | ACPI-enumerated PnP hardware ID | `AmdAS4` | Native | Native | Native | Native | NotDeclared |
| `d4_Data1.cab_9ed7c73e0e1f\amdcir.inf` | AMD CIR Driver | `*AMDC001` | Generic PnP hardware ID | `AMDCIR64` | Native | Native | Native | Native | NotDeclared |
| `d4_Data1.cab_9ed7c73e0e1f\amdcir.inf` | AMD CIR Driver | `*AMDC002` | Generic PnP hardware ID | `AMDCIR64` | Native | Native | Native | Native | NotDeclared |
| `d4_Data1.cab_9ed7c73e0e1f\amdcir.inf` | AMD CIR Driver | `*AMDC003` | Generic PnP hardware ID | `AMDCIR64` | Native | Native | Native | Native | NotDeclared |
| `d4_Data1.cab_9ed7c73e0e1f\amdgpio2.inf` | AMD GPIO Controller | `ACPI\AMD0030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `d4_Data1.cab_9ed7c73e0e1f\amdgpio2.inf` | AMD GPIO Controller | `ACPI\AMDI0030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `d4_Data1.cab_9ed7c73e0e1f\amdgpio2.inf` | AMD GPIO Controller | `ACPI\GPIO0010` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `d4_Data1.cab_9ed7c73e0e1f\amdgpio3.inf` | AMD GPIO Controller | `ACPI\AMDF030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `d4_Data1.cab_9ed7c73e0e1f\amdgpio3.inf` | AMD GPIO Controller | `ACPI\AMDIF030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `d4_Data1.cab_9ed7c73e0e1f\amdhub3.inf` | AMD Root Hub(xHCI) | `AMDUSB3\ROOT_HUB3` | AMDUSB3-enumerated PnP hardware ID | `AMDHUB3` | Native | Native | Native | Native | NotDeclared |
| `d4_Data1.cab_9ed7c73e0e1f\amdhub3.inf` | AMD USB 2.0 Hub | `AMDUSB3\CLASS_09&SUBCLASS_00&PROT_01` | AMDUSB3-enumerated PnP hardware ID | `AMDHUB3` | Native | Native | Native | Native | NotDeclared |
| `d4_Data1.cab_9ed7c73e0e1f\amdhub3.inf` | AMD USB 2.0 MTT Hub | `AMDUSB3\CLASS_09&SUBCLASS_00&PROT_02` | AMDUSB3-enumerated PnP hardware ID | `AMDHUB3` | Native | Native | Native | Native | NotDeclared |
| `d4_Data1.cab_9ed7c73e0e1f\amdhub3.inf` | AMD USB 3.0 Hub | `AMDUSB3\CLASS_09&SUBCLASS_00&PROT_03` | AMDUSB3-enumerated PnP hardware ID | `AMDHUB3` | Native | Native | Native | Native | NotDeclared |
| `d4_Data1.cab_9ed7c73e0e1f\amdhub3.inf` | AMD USB Hub | `AMDUSB3\CLASS_09&SUBCLASS_00&PROT_00` | AMDUSB3-enumerated PnP hardware ID | `AMDHUB3` | Native | Native | Native | Native | NotDeclared |
| `d4_Data1.cab_9ed7c73e0e1f\amdhub3.inf` | AMD USB Hub | `AMDUSB3\CLASS_09&SUBCLASS_01` | AMDUSB3-enumerated PnP hardware ID | `AMDHUB3` | Native | Native | Native | Native | NotDeclared |
| `d4_Data1.cab_9ed7c73e0e1f\amdhub30.inf` | AMD USB 2.0 Hub | `AMDUSB30\CLASS_09&SUBCLASS_00&PROT_01` | AMDUSB30-enumerated PnP hardware ID | `AMDHUB30` | Projection | Projection | Projection | Projection | NotDeclared |
| `d4_Data1.cab_9ed7c73e0e1f\amdhub30.inf` | AMD USB 2.0 MTT Hub | `AMDUSB30\CLASS_09&SUBCLASS_00&PROT_02` | AMDUSB30-enumerated PnP hardware ID | `AMDHUB30` | Projection | Projection | Projection | Projection | NotDeclared |
| `d4_Data1.cab_9ed7c73e0e1f\amdhub30.inf` | AMD USB 3.0 Hub | `AMDUSB30\CLASS_09&SUBCLASS_00&PROT_03` | AMDUSB30-enumerated PnP hardware ID | `AMDHUB30` | Projection | Projection | Projection | Projection | NotDeclared |
| `d4_Data1.cab_9ed7c73e0e1f\amdhub30.inf` | AMD USB 3.0 Root Hub | `AMDUSB30\ROOT_HUB30` | AMDUSB30-enumerated PnP hardware ID | `AMDHUB30` | Projection | Projection | Projection | Projection | NotDeclared |
| `d4_Data1.cab_9ed7c73e0e1f\amdhub30.inf` | AMD USB Hub | `AMDUSB30\CLASS_09&SUBCLASS_00&PROT_00` | AMDUSB30-enumerated PnP hardware ID | `AMDHUB30` | Projection | Projection | Projection | Projection | NotDeclared |
| `d4_Data1.cab_9ed7c73e0e1f\amdhub30.inf` | AMD USB Hub | `AMDUSB30\CLASS_09&SUBCLASS_01` | AMDUSB30-enumerated PnP hardware ID | `AMDHUB30` | Projection | Projection | Projection | Projection | NotDeclared |
| `d4_Data1.cab_9ed7c73e0e1f\amdhub31.inf` | AMD USB3.1 Root Hub | `USB\AMDROOT_HUB31&VID1022&PID43B9&VER0001000000050003` | USB-enumerated PnP hardware ID | `RootHub_Product1_Install` | Native | Native | Native | Native | NotDeclared |
| `d4_Data1.cab_9ed7c73e0e1f\amdhub31.inf` | AMD USB3.1 Root Hub | `USB\AMDROOT_HUB31&VID1022&PID43BA&VER0001000000050003` | USB-enumerated PnP hardware ID | `RootHub_Product2_Install` | Native | Native | Native | Native | NotDeclared |
| `d4_Data1.cab_9ed7c73e0e1f\amdhub31.inf` | AMD USB3.1 Root Hub | `USB\AMDROOT_HUB31&VID1022&PID43BB&VER0001000000050003` | USB-enumerated PnP hardware ID | `RootHub_Product3_Install` | Native | Native | Native | Native | NotDeclared |
| `d4_Data1.cab_9ed7c73e0e1f\amdhub31.inf` | AMD USB3.1 Root Hub | `USB\AMDROOT_HUB31&VID1022&PID43BC&VER0001000000050003` | USB-enumerated PnP hardware ID | `RootHub_Product4_Install` | Native | Native | Native | Native | NotDeclared |
| `d4_Data1.cab_9ed7c73e0e1f\amdhub31.inf` | AMD USB3.1 Root Hub | `USB\AMDROOT_HUB31&VID1022&PID43D0&VER0001000000050003` | USB-enumerated PnP hardware ID | `RootHub_Product5_Install` | Native | Native | Native | Native | NotDeclared |
| `d4_Data1.cab_9ed7c73e0e1f\amdhub31.inf` | AMD USB3.1 Root Hub | `USB\AMDROOT_HUB31&VID1022&PID43D1&VER0001000000050003` | USB-enumerated PnP hardware ID | `RootHub_Product6_Install` | Native | Native | Native | Native | NotDeclared |
| `d4_Data1.cab_9ed7c73e0e1f\amdhub31.inf` | AMD USB3.1 Root Hub | `USB\AMDROOT_HUB31&VID1022&PID43D2&VER0001000000050003` | USB-enumerated PnP hardware ID | `RootHub_Product7_Install` | Native | Native | Native | Native | NotDeclared |
| `d4_Data1.cab_9ed7c73e0e1f\amdhub31.inf` | AMD USB3.1 Root Hub | `USB\AMDROOT_HUB31&VID1022&PID43D3&VER0001000000050003` | USB-enumerated PnP hardware ID | `RootHub_Product8_Install` | Native | Native | Native | Native | NotDeclared |
| `d4_Data1.cab_9ed7c73e0e1f\amdhub31.inf` | AMD USB3.1 Root Hub | `USB\AMDROOT_HUB31&VID1022&PID43D4&VER0001000000050003` | USB-enumerated PnP hardware ID | `RootHub_Product9_Install` | Native | Native | Native | Native | NotDeclared |
| `d4_Data1.cab_9ed7c73e0e1f\amdhub31.inf` | AMD USB3.1 Root Hub | `USB\AMDROOT_HUB31&VID1022&PID43D5&VER0001000000050003` | USB-enumerated PnP hardware ID | `RootHub_Product10_Install` | Native | Native | Native | Native | NotDeclared |
| `d4_Data1.cab_9ed7c73e0e1f\amdhub31.inf` | AMD USB3.1 Root Hub | `USB\AMDROOT_HUB31&VID1022&PID43D6&VER0001000000050003` | USB-enumerated PnP hardware ID | `RootHub_Product11_Install` | Native | Native | Native | Native | NotDeclared |
| `d4_Data1.cab_9ed7c73e0e1f\amdhub31.inf` | AMD USB3.1 Root Hub | `USB\AMDROOT_HUB31&VID1022&PID43D7&VER0001000000050003` | USB-enumerated PnP hardware ID | `RootHub_Product12_Install` | Native | Native | Native | Native | NotDeclared |
| `d4_Data1.cab_9ed7c73e0e1f\amdhub31.inf` | AMD USB3.1 Root Hub | `USB\AMDROOT_HUB31&VID1022&PID43D8&VER0001000000050003` | USB-enumerated PnP hardware ID | `RootHub_Product13_Install` | Native | Native | Native | Native | NotDeclared |
| `d4_Data1.cab_9ed7c73e0e1f\amdhub31.inf` | AMD USB3.1 Root Hub | `USB\AMDROOT_HUB31&VID1022&PID43D9&VER0001000000050003` | USB-enumerated PnP hardware ID | `RootHub_Product14_Install` | Native | Native | Native | Native | NotDeclared |
| `d4_Data1.cab_9ed7c73e0e1f\amdhub31.inf` | AMD USB3.1 Root Hub | `USB\AMDROOT_HUB31&VID1022&PID43DA&VER0001000000050003` | USB-enumerated PnP hardware ID | `RootHub_Product15_Install` | Native | Native | Native | Native | NotDeclared |
| `d4_Data1.cab_9ed7c73e0e1f\amdhub31.inf` | AMD USB3.1 Root Hub | `USB\AMDROOT_HUB31&VID1022&PID43DB&VER0001000000050003` | USB-enumerated PnP hardware ID | `RootHub_Product16_Install` | Native | Native | Native | Native | NotDeclared |
| `d4_Data1.cab_9ed7c73e0e1f\amdhub31.inf` | AMD USB3.1 Root Hub | `USB\AMDROOT_HUB31&VID1022&PID43DC&VER0001000000050003` | USB-enumerated PnP hardware ID | `RootHub_Product17_Install` | Native | Native | Native | Native | NotDeclared |
| `d4_Data1.cab_9ed7c73e0e1f\amdhub31.inf` | AMD USB3.1 Root Hub | `USB\AMDROOT_HUB31&VID1022&PID43DD&VER0001000000050003` | USB-enumerated PnP hardware ID | `RootHub_Product18_Install` | Native | Native | Native | Native | NotDeclared |
| `d4_Data1.cab_9ed7c73e0e1f\amdhub31.inf` | AMD USB3.1 Root Hub | `USB\AMDROOT_HUB31&VID1022&PID43DE&VER0001000000050003` | USB-enumerated PnP hardware ID | `RootHub_Product19_Install` | Native | Native | Native | Native | NotDeclared |
| `d4_Data1.cab_9ed7c73e0e1f\amdhub31.inf` | AMD USB3.1 Root Hub | `USB\AMDROOT_HUB31&VID1022&PID43DF&VER0001000000050003` | USB-enumerated PnP hardware ID | `RootHub_Product20_Install` | Native | Native | Native | Native | NotDeclared |
| `d4_Data1.cab_9ed7c73e0e1f\amdhub31.inf` | Generic SuperSpeed USB Hub | `USB\AMD_HUB31SS` | USB-enumerated PnP hardware ID | `Hub_Product3_Install` | Native | Native | Native | Native | NotDeclared |
| `d4_Data1.cab_9ed7c73e0e1f\amdhub31.inf` | Generic USB Hub | `USB\AMD_HUB31` | USB-enumerated PnP hardware ID | `Hub_Product2_Install` | Native | Native | Native | Native | NotDeclared |
| `d4_Data1.cab_9ed7c73e0e1f\amdi2c.inf` | AMD I2C Controller | `ACPI\AMD0010` | ACPI-enumerated PnP hardware ID | `amdi2c_Device` | Native | Native | Native | Native | NotDeclared |
| `d4_Data1.cab_9ed7c73e0e1f\amdi2c.inf` | AMD I2C Controller | `ACPI\AMDI0010` | ACPI-enumerated PnP hardware ID | `amdi2c_Device` | Native | Native | Native | Native | NotDeclared |
| `d4_Data1.cab_9ed7c73e0e1f\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1002&DEV_5A23` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d4_Data1.cab_9ed7c73e0e1f\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1419` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d4_Data1.cab_9ed7c73e0e1f\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1423` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d4_Data1.cab_9ed7c73e0e1f\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1437` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d4_Data1.cab_9ed7c73e0e1f\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1449` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d4_Data1.cab_9ed7c73e0e1f\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1451` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d4_Data1.cab_9ed7c73e0e1f\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1481` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d4_Data1.cab_9ed7c73e0e1f\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1577` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d4_Data1.cab_9ed7c73e0e1f\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_15D1` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d4_Data1.cab_9ed7c73e0e1f\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1611` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `d4_Data1.cab_9ed7c73e0e1f\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMD0004` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `d4_Data1.cab_9ed7c73e0e1f\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMD0005` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `d4_Data1.cab_9ed7c73e0e1f\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0005` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `d4_Data1.cab_9ed7c73e0e1f\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_1455` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `d4_Data1.cab_9ed7c73e0e1f\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_145A` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `d4_Data1.cab_9ed7c73e0e1f\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_1485` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `d4_Data1.cab_9ed7c73e0e1f\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_148A` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `d4_Data1.cab_9ed7c73e0e1f\amdpsp.inf` | AMD PSP 3.0 Device | `PCI\VEN_1022&DEV_1456` | PCI-enumerated PnP hardware ID | `amdpsp_Device_30` | Native | Native | Native | Native | NotDeclared |
| `d4_Data1.cab_9ed7c73e0e1f\amdpsp.inf` | AMD PSP 3.0 Device | `PCI\VEN_1022&DEV_1486` | PCI-enumerated PnP hardware ID | `amdpsp_Device_30` | Native | Native | Native | Native | NotDeclared |
| `d4_Data1.cab_9ed7c73e0e1f\amdpsp.inf` | AMD PSP 3.0 Device | `PCI\VEN_1022&DEV_15dF` | PCI-enumerated PnP hardware ID | `amdpsp_Device_30` | Native | Native | Native | Native | NotDeclared |
| `d4_Data1.cab_9ed7c73e0e1f\amdrhub3.inf` | AMD Root Hub(xHCI) | `AMDUSB3\ROOT_HUB31` | AMDUSB3-enumerated PnP hardware ID | `AMDHUB3` | Native | Native | Native | Native | NotDeclared |
| `d4_Data1.cab_9ed7c73e0e1f\amdrhub3.inf` | AMD USB 2.0 Hub | `AMDUSB3\CLASS_09&SUBCLASS_00&PROT_01` | AMDUSB3-enumerated PnP hardware ID | `AMDHUB3` | Native | Native | Native | Native | NotDeclared |
| `d4_Data1.cab_9ed7c73e0e1f\amdrhub3.inf` | AMD USB 2.0 MTT Hub | `AMDUSB3\CLASS_09&SUBCLASS_00&PROT_02` | AMDUSB3-enumerated PnP hardware ID | `AMDHUB3` | Native | Native | Native | Native | NotDeclared |
| `d4_Data1.cab_9ed7c73e0e1f\amdrhub3.inf` | AMD USB 3.1 Hub | `AMDUSB3\CLASS_09&SUBCLASS_00&PROT_03` | AMDUSB3-enumerated PnP hardware ID | `AMDHUB3` | Native | Native | Native | Native | NotDeclared |
| `d4_Data1.cab_9ed7c73e0e1f\amdrhub3.inf` | AMD USB Hub | `AMDUSB3\CLASS_09&SUBCLASS_00&PROT_00` | AMDUSB3-enumerated PnP hardware ID | `AMDHUB3` | Native | Native | Native | Native | NotDeclared |
| `d4_Data1.cab_9ed7c73e0e1f\amdrhub3.inf` | AMD USB Hub | `AMDUSB3\CLASS_09&SUBCLASS_01` | AMDUSB3-enumerated PnP hardware ID | `AMDHUB3` | Native | Native | Native | Native | NotDeclared |
| `d4_Data1.cab_9ed7c73e0e1f\amdrxhc.inf` | AMD Radeon USB3.1 Host Controller - 1.1 | `PCI\VEN_1002&DEV_7316` | PCI-enumerated PnP hardware ID | `AMDXHCI` | Native | Native | Native | Native | NotDeclared |
| `d4_Data1.cab_9ed7c73e0e1f\amdrxhc.inf` | AMD USB3.1 Host Controller - 1.1 | `PCI\VEN_1022&DEV_15E0` | PCI-enumerated PnP hardware ID | `AMDXHCI` | Native | Native | Native | Native | NotDeclared |
| `d4_Data1.cab_9ed7c73e0e1f\amdrxhc.inf` | AMD USB3.1 Host Controller - 1.1 | `PCI\VEN_1022&DEV_15E1` | PCI-enumerated PnP hardware ID | `AMDXHCI` | Native | Native | Native | Native | NotDeclared |
| `d4_Data1.cab_9ed7c73e0e1f\amdrxhc.inf` | AMD USB3.1 Host Controller - 1.1 | `PCI\VEN_1022&DEV_15E5` | PCI-enumerated PnP hardware ID | `AMDXHCI` | Native | Native | Native | Native | NotDeclared |
| `d4_Data1.cab_9ed7c73e0e1f\amdsfhkmdf.inf` | AMD Sensor Fusion Hub | `PCI\VEN_1022&DEV_15E4` | PCI-enumerated PnP hardware ID | `amdsfhkmdf_Device` | Native | Native | Native | Native | KMDF 1.15 |
| `d4_Data1.cab_9ed7c73e0e1f\amdsfhkmdfi2c.inf` | AMD SFH KMDF I2C | `PCI\VEN_1022&DEV_15E6` | PCI-enumerated PnP hardware ID | `amdsfhkmdf_Device` | Native | Native | Native | Native | KMDF 1.15 |
| `d4_Data1.cab_9ed7c73e0e1f\amdsfhspbi2c.inf` | AMD SFH I2C Controller | `ACPI\AMDI0011` | ACPI-enumerated PnP hardware ID | `amdsfhspbi2c_Device` | Native | Native | Native | Native | NotDeclared |
| `d4_Data1.cab_9ed7c73e0e1f\amdsfhumdf.inf` | AMD UMDF Sensor | `ACPI\AMDI0080` | ACPI-enumerated PnP hardware ID | `amdsfhumdf_Inst` | Native | Native | Native | Native | UMDF 2.15.0 |
| `d4_Data1.cab_9ed7c73e0e1f\amduart.inf` | AMD UART Controller | `ACPI\AMD0020` | ACPI-enumerated PnP hardware ID | `amduart_Inst` | Native | Native | Native | Native | NotDeclared |
| `d4_Data1.cab_9ed7c73e0e1f\amduart.inf` | AMD UART Controller | `ACPI\AMDI0020` | ACPI-enumerated PnP hardware ID | `amduart_Inst` | Native | Native | Native | Native | NotDeclared |
| `d4_Data1.cab_9ed7c73e0e1f\amdxhc.inf` | AMD USB 3.0 Host Controller | `PCI\VEN_1022&DEV_7812` | PCI-enumerated PnP hardware ID | `AMDXHC` | Projection | Projection | Projection | Projection | NotDeclared |
| `d4_Data1.cab_9ed7c73e0e1f\amdxhc.inf` | AMD USB 3.0 Host Controller | `PCI\VEN_1022&DEV_7814` | PCI-enumerated PnP hardware ID | `AMDXHC` | Projection | Projection | Projection | Projection | NotDeclared |
| `d4_Data1.cab_9ed7c73e0e1f\amdxhc.inf` | AMD USB 3.0 Host Controller | `PCI\VEN_1022&DEV_7914` | PCI-enumerated PnP hardware ID | `AMDXHC` | Projection | Projection | Projection | Projection | NotDeclared |
| `d4_Data1.cab_9ed7c73e0e1f\amdxhc31.inf` | AMD USB3.1 eXtensible Host Controller | `PCI\VEN_1022&DEV_43B9` | PCI-enumerated PnP hardware ID | `AMD_Product1_Install` | Native | Native | Native | Native | NotDeclared |
| `d4_Data1.cab_9ed7c73e0e1f\amdxhc31.inf` | AMD USB3.1 eXtensible Host Controller | `PCI\VEN_1022&DEV_43BA` | PCI-enumerated PnP hardware ID | `AMD_Product2_Install` | Native | Native | Native | Native | NotDeclared |
| `d4_Data1.cab_9ed7c73e0e1f\amdxhc31.inf` | AMD USB3.1 eXtensible Host Controller | `PCI\VEN_1022&DEV_43BB` | PCI-enumerated PnP hardware ID | `AMD_Product3_Install` | Native | Native | Native | Native | NotDeclared |
| `d4_Data1.cab_9ed7c73e0e1f\amdxhc31.inf` | AMD USB3.1 eXtensible Host Controller | `PCI\VEN_1022&DEV_43BC` | PCI-enumerated PnP hardware ID | `AMD_Product4_Install` | Native | Native | Native | Native | NotDeclared |
| `d4_Data1.cab_9ed7c73e0e1f\amdxhc31.inf` | AMD USB3.1 eXtensible Host Controller | `PCI\VEN_1022&DEV_43D0` | PCI-enumerated PnP hardware ID | `AMD_Product5_Install` | Native | Native | Native | Native | NotDeclared |
| `d4_Data1.cab_9ed7c73e0e1f\amdxhc31.inf` | AMD USB3.1 eXtensible Host Controller | `PCI\VEN_1022&DEV_43D1` | PCI-enumerated PnP hardware ID | `AMD_Product6_Install` | Native | Native | Native | Native | NotDeclared |
| `d4_Data1.cab_9ed7c73e0e1f\amdxhc31.inf` | AMD USB3.1 eXtensible Host Controller | `PCI\VEN_1022&DEV_43D2` | PCI-enumerated PnP hardware ID | `AMD_Product7_Install` | Native | Native | Native | Native | NotDeclared |
| `d4_Data1.cab_9ed7c73e0e1f\amdxhc31.inf` | AMD USB3.1 eXtensible Host Controller | `PCI\VEN_1022&DEV_43D3` | PCI-enumerated PnP hardware ID | `AMD_Product8_Install` | Native | Native | Native | Native | NotDeclared |
| `d4_Data1.cab_9ed7c73e0e1f\amdxhc31.inf` | AMD USB3.1 eXtensible Host Controller | `PCI\VEN_1022&DEV_43D4` | PCI-enumerated PnP hardware ID | `AMD_Product9_Install` | Native | Native | Native | Native | NotDeclared |
| `d4_Data1.cab_9ed7c73e0e1f\amdxhc31.inf` | AMD USB3.1 eXtensible Host Controller | `PCI\VEN_1022&DEV_43D5` | PCI-enumerated PnP hardware ID | `AMD_Product10_Install` | Native | Native | Native | Native | NotDeclared |
| `d4_Data1.cab_9ed7c73e0e1f\amdxhc31.inf` | AMD USB3.1 eXtensible Host Controller | `PCI\VEN_1022&DEV_43D6` | PCI-enumerated PnP hardware ID | `AMD_Product11_Install` | Native | Native | Native | Native | NotDeclared |
| `d4_Data1.cab_9ed7c73e0e1f\amdxhc31.inf` | AMD USB3.1 eXtensible Host Controller | `PCI\VEN_1022&DEV_43D7` | PCI-enumerated PnP hardware ID | `AMD_Product12_Install` | Native | Native | Native | Native | NotDeclared |
| `d4_Data1.cab_9ed7c73e0e1f\amdxhc31.inf` | AMD USB3.1 eXtensible Host Controller | `PCI\VEN_1022&DEV_43D8` | PCI-enumerated PnP hardware ID | `AMD_Product13_Install` | Native | Native | Native | Native | NotDeclared |
| `d4_Data1.cab_9ed7c73e0e1f\amdxhc31.inf` | AMD USB3.1 eXtensible Host Controller | `PCI\VEN_1022&DEV_43D9` | PCI-enumerated PnP hardware ID | `AMD_Product14_Install` | Native | Native | Native | Native | NotDeclared |
| `d4_Data1.cab_9ed7c73e0e1f\amdxhc31.inf` | AMD USB3.1 eXtensible Host Controller | `PCI\VEN_1022&DEV_43DA` | PCI-enumerated PnP hardware ID | `AMD_Product15_Install` | Native | Native | Native | Native | NotDeclared |
| `d4_Data1.cab_9ed7c73e0e1f\amdxhc31.inf` | AMD USB3.1 eXtensible Host Controller | `PCI\VEN_1022&DEV_43DB` | PCI-enumerated PnP hardware ID | `AMD_Product16_Install` | Native | Native | Native | Native | NotDeclared |
| `d4_Data1.cab_9ed7c73e0e1f\amdxhc31.inf` | AMD USB3.1 eXtensible Host Controller | `PCI\VEN_1022&DEV_43DC` | PCI-enumerated PnP hardware ID | `AMD_Product17_Install` | Native | Native | Native | Native | NotDeclared |
| `d4_Data1.cab_9ed7c73e0e1f\amdxhc31.inf` | AMD USB3.1 eXtensible Host Controller | `PCI\VEN_1022&DEV_43DD` | PCI-enumerated PnP hardware ID | `AMD_Product18_Install` | Native | Native | Native | Native | NotDeclared |
| `d4_Data1.cab_9ed7c73e0e1f\amdxhc31.inf` | AMD USB3.1 eXtensible Host Controller | `PCI\VEN_1022&DEV_43DE` | PCI-enumerated PnP hardware ID | `AMD_Product19_Install` | Native | Native | Native | Native | NotDeclared |
| `d4_Data1.cab_9ed7c73e0e1f\amdxhc31.inf` | AMD USB3.1 eXtensible Host Controller | `PCI\VEN_1022&DEV_43DF` | PCI-enumerated PnP hardware ID | `AMD_Product20_Install` | Native | Native | Native | Native | NotDeclared |
| `d4_Data1.cab_9ed7c73e0e1f\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4353` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `d4_Data1.cab_9ed7c73e0e1f\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4363` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `d4_Data1.cab_9ed7c73e0e1f\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4372` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `d4_Data1.cab_9ed7c73e0e1f\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4385` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `d4_Data1.cab_9ed7c73e0e1f\smbusamd.inf` | AMD SMBus | `PCI\VEN_1022&DEV_780B` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `d4_Data1.cab_9ed7c73e0e1f\smbusamd.inf` | AMD SMBus | `PCI\VEN_1022&DEV_790B` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `d4_Data1.cab_9ed7c73e0e1f\usbfilter.inf` | AMD USB Filter Driver | `{36FC9E60-C465-11CF-8056-444553540000}\usbfilter` | Device-class-specific ID | `usbfilter` | Native | Native | Native | Native | NotDeclared |

