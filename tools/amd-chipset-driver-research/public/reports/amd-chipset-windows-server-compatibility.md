# AMD Chipset Driver - Windows Server static applicability

This report is generated from per-INF semantic analysis. It distinguishes AMD-published applicability from the analytical ProductType=1 -> ProductType=3 server projection used by the deployment project. It does **not** prove runtime compatibility.

Releases are listed newest first. The identifier column preserves the exact Models-section identifier from the source INF; `Identifier type` distinguishes bus/root PnP hardware IDs from class-specific IDs and software component IDs.

## AMD Chipset Software 8.08.12.551

| INF | Device | Device identifier | Identifier type | Install section | WS2016 | WS2019 | WS2022 | WS2025 | WDF |
|---|---|---|---|---|---|---|---|---|---|
| `c0004\amd3dvcache.inf` | AMD 3D V-Cache Performance Optimizer | `ACPI\AMDI0101` | ACPI-enumerated PnP hardware ID | `Amd3dvcache_Device` | No(Build) | No(Build) | Native | Native | KMDF 1.15 |
| `c0004\amdappcompat.inf` | AMD Application Compatibility Database | `ACPI\AMDI0204` | ACPI-enumerated PnP hardware ID | `AmdAppCompat_Device` | No(Build) | Native | Native | Native | KMDF 1.15 |
| `c0004\amdas4.inf` | AmdAS4 Device | `ACPI\AMDI0050` | ACPI-enumerated PnP hardware ID | `AmdAS4` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdas4.inf` | AmdAS4 Device | `ACPI\ASD0001` | ACPI-enumerated PnP hardware ID | `AmdAS4` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdcir.inf` | AMD CIR Driver | `*AMDC001` | Generic PnP hardware ID | `AMDCIR64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdcir.inf` | AMD CIR Driver | `*AMDC002` | Generic PnP hardware ID | `AMDCIR64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdcir.inf` | AMD CIR Driver | `*AMDC003` | Generic PnP hardware ID | `AMDCIR64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdgpio2.inf` | AMD GPIO Controller | `ACPI\AMD0030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | No(Build) | Native | Native | Native | NotDeclared |
| `c0004\amdgpio2.inf` | AMD GPIO Controller | `ACPI\AMDI0030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | No(Build) | Native | Native | Native | NotDeclared |
| `c0004\amdgpio2.inf` | AMD GPIO Controller | `ACPI\AMDI0031` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | No(Build) | Native | Native | Native | NotDeclared |
| `c0004\amdgpio2.inf` | AMD GPIO Controller | `ACPI\GPIO0010` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | No(Build) | Native | Native | Native | NotDeclared |
| `c0004\amdgpio3.inf` | AMD GPIO Controller | `ACPI\AMDF030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `c0004\amdgpio3.inf` | AMD GPIO Controller | `ACPI\AMDIF030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `c0004\amdgpio3.inf` | AMD GPIO Controller | `ACPI\AMDIF031` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `c0004\amdhsmpdriver.inf` | AMD Host System Management Port | `ACPI\AMDI0097` | ACPI-enumerated PnP hardware ID | `AmdHsmpDriver_Device` | No(Build) | No(Build) | Native | Native | NotDeclared |
| `c0004\amdi2c.inf` | AMD I2C Controller | `ACPI\AMD0010` | ACPI-enumerated PnP hardware ID | `amdi2c_Device` | No(Build) | Native | Native | Native | NotDeclared |
| `c0004\amdi2c.inf` | AMD I2C Controller | `ACPI\AMDI0010` | ACPI-enumerated PnP hardware ID | `amdi2c_Device` | No(Build) | Native | Native | Native | NotDeclared |
| `c0004\amdinterface.inf` | AMD PCI | `PCI\VEN_1002&DEV_145A` | PCI-enumerated PnP hardware ID | `AMDPCI64` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `c0004\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_1116` | PCI-enumerated PnP hardware ID | `AMDPCI64` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `c0004\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_1117` | PCI-enumerated PnP hardware ID | `AMDPCI64` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `c0004\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_1136` | PCI-enumerated PnP hardware ID | `AMDPCI64` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `c0004\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_1137` | PCI-enumerated PnP hardware ID | `AMDPCI64` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `c0004\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_1151` | PCI-enumerated PnP hardware ID | `AMDPCI64` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `c0004\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_1176` | PCI-enumerated PnP hardware ID | `AMDPCI64` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `c0004\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_11B0` | PCI-enumerated PnP hardware ID | `AMDPCI64` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `c0004\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_14AC` | PCI-enumerated PnP hardware ID | `AMDPCI64` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `c0004\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_14DC` | PCI-enumerated PnP hardware ID | `AMDPCI64` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `c0004\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_14DE` | PCI-enumerated PnP hardware ID | `AMDPCI64` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `c0004\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_14EC` | PCI-enumerated PnP hardware ID | `AMDPCI64` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `c0004\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_150D` | PCI-enumerated PnP hardware ID | `AMDPCI64` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `c0004\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_1556` | PCI-enumerated PnP hardware ID | `AMDPCI64` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `c0004\amdinterface.inf` | AMD PSP | `PCI\VEN_1022&DEV_1B16` | PCI-enumerated PnP hardware ID | `AMDPCI64` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `c0004\amdinterface.inf` | AMD PSP | `PCI\VEN_1022&DEV_1B26` | PCI-enumerated PnP hardware ID | `AMDPCI64` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `c0004\amdinterface.inf` | AMD SMBUS | `PCI\VEN_1022&DEV_790B` | PCI-enumerated PnP hardware ID | `AMDPCI64` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `c0004\amdinterface.inf` | AMD SPI Controller | `ACPI\AMDI0062` | ACPI-enumerated PnP hardware ID | `AMDPCI64` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `c0004\amdinterface.inf` | AMD WPS PCC Driver | `ACPI\PccIntAA` | ACPI-enumerated PnP hardware ID | `AMDPCI64` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1002&DEV_5A23` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_13E1` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1419` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1423` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1437` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1451` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1481` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1577` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_164F` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMD0004` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | No(Build) | Projection | Projection | Projection | NotDeclared |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMD0005` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | No(Build) | Projection | Projection | Projection | NotDeclared |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0005` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | No(Build) | Projection | Projection | Projection | NotDeclared |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0006` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | No(Build) | Projection | Projection | Projection | NotDeclared |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0007` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | No(Build) | Projection | Projection | Projection | NotDeclared |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0008` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | No(Build) | Projection | Projection | Projection | NotDeclared |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0009` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | No(Build) | Projection | Projection | Projection | NotDeclared |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI000A` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install.AMDI000A` | No(Build) | Projection | Projection | Projection | NotDeclared |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI000B` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | No(Build) | Projection | Projection | Projection | NotDeclared |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI000C` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | No(Build) | Projection | Projection | Projection | NotDeclared |
| `c0004\amdoemprov.inf` | AMD Provisioning for OEM | `ACPI\AMDI0053` | ACPI-enumerated PnP hardware ID | `AMDPPMPF_DEV` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `c0004\amdpcidev.inf` | AMD PCI | `PCI\VEN_1002&DEV_145A` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_1455` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_145A` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_1485` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_148A` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_14DE` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdpmf.inf` | AMD PMF | `ACPI\AMDI0102` | ACPI-enumerated PnP hardware ID | `AMDPMF_INSTALL.NTamd64.10.0...19041` | No(Build) | No(Build) | Native | Native | NotDeclared |
| `c0004\amdpmf.inf` | AMD PMF | `ACPI\AMDI0103` | ACPI-enumerated PnP hardware ID | `AMDPMF_INSTALL.NTamd64.10.0...19041` | No(Build) | No(Build) | Native | Native | NotDeclared |
| `c0004\amdpmf.inf` | AMD PMF | `ACPI\AMDI0105` | ACPI-enumerated PnP hardware ID | `AMDPMF_INSTALL.NTamd64.10.0...19041` | No(Build) | No(Build) | Native | Native | NotDeclared |
| `c0004\amdpmf.inf` | AMD PMF | `ACPI\AMDI0107` | ACPI-enumerated PnP hardware ID | `AMDPMF_INSTALL.NTamd64.10.0...19041` | No(Build) | No(Build) | Native | Native | NotDeclared |
| `c0004\amdpmf.inf` | AMD PMF | `ACPI\AMDI0108` | ACPI-enumerated PnP hardware ID | `AMDPMF_INSTALL.NTamd64.10.0...19041` | No(Build) | No(Build) | Native | Native | NotDeclared |
| `c0004\amdpmf.inf` | AMD PMF | `ACPI\AMDI0109` | ACPI-enumerated PnP hardware ID | `AMDPMF_INSTALL.NTamd64.10.0...19041` | No(Build) | No(Build) | Native | Native | NotDeclared |
| `c0004\amdpmf.inf` | AMD PMF | `ACPI\AMDI0112` | ACPI-enumerated PnP hardware ID | `AMDPMF_INSTALL.NTamd64.10.0...19041` | No(Build) | No(Build) | Native | Native | NotDeclared |
| `c0004\amdppkg.inf` | AMD Provisioning Packages | `ACPI\AMDI0052` | ACPI-enumerated PnP hardware ID | `InstallSection_Win10` | No(Build) | No(Build) | Native | No | NotDeclared |
| `c0004\amdppkg.inf` | AMD Provisioning Packages | `ACPI\AMDI0052` | ACPI-enumerated PnP hardware ID | `InstallSection_Win11_22H2` | No(Build) | No(Build) | No | Native | NotDeclared |
| `c0004\amdpsp.inf` | AMD PSP 10.0 Device | `PCI\VEN_1022&DEV_15DF` | PCI-enumerated PnP hardware ID | `amdpsp_Device_100` | Native | No | No | No | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP 10.0 Device | `PCI\VEN_1022&DEV_15DF` | PCI-enumerated PnP hardware ID | `amdpsp_Device_100_RS3` | No | Native | Native | Native | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_1134` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | No | No | No | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_1134` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110_RS3` | No | Native | Native | Native | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_115A` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110_RS3` | No | Native | Native | Native | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_115A` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | No | No | No | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_1486` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110_RS3` | No | Native | Native | Native | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_1486` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | No | No | No | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_14CA` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110_RS3` | No | Native | Native | Native | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_14CA` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | No | No | No | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_156E` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110_RS3` | No | Native | Native | Native | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_156E` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | No | No | No | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_15C7` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | No | No | No | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_15C7` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110_RS3` | No | Native | Native | Native | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_1649` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | No | No | No | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_1649` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110_RS3` | No | Native | Native | Native | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_17E0` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110_RS3` | No | Native | Native | Native | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_17E0` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | No | No | No | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_13EC` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | No | No | No | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_13EC` | PCI-enumerated PnP hardware ID | `amdpsp_Device_RS3` | No | Native | Native | Native | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_1456` | PCI-enumerated PnP hardware ID | `amdpsp_Device_RS3` | No | Native | Native | Native | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_1456` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | No | No | No | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_1537` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | No | No | No | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_1537` | PCI-enumerated PnP hardware ID | `amdpsp_Device_RS3` | No | Native | Native | Native | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_1578` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | No | No | No | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_1578` | PCI-enumerated PnP hardware ID | `amdpsp_Device_RS3` | No | Native | Native | Native | KMDF 1.13 |
| `c0004\amdsfhkmdf.inf` | AMD Sensor Fusion Hub | `PCI\VEN_1022&DEV_15E4` | PCI-enumerated PnP hardware ID | `amdsfhkmdf_Device` | Native | Native | Native | Native | KMDF 1.15 |
| `c0004\amdsfhkmdfi2c.inf` | AMD SFH KMDF I2C | `PCI\VEN_1022&DEV_15E6` | PCI-enumerated PnP hardware ID | `amdsfhkmdf_Device` | Native | Native | Native | Native | KMDF 1.15 |
| `c0004\amdsfhspbi2c.inf` | AMD SFH I2C Controller | `ACPI\AMDI0011` | ACPI-enumerated PnP hardware ID | `amdsfhspbi2c_Device` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdsfhumdf.inf` | AMD UMDF Sensor | `ACPI\AMDI0080` | ACPI-enumerated PnP hardware ID | `amdsfhumdf_Inst_Win10` | No(Build) | Native | Native | No | UMDF 2.15.0 |
| `c0004\amdsfhumdf.inf` | AMD UMDF Sensor | `ACPI\AMDI0080` | ACPI-enumerated PnP hardware ID | `amdsfhumdf_Inst_Win11` | No(Build) | No | No | Native | UMDF 2.15.0 |
| `c0004\amduart.inf` | AMD UART Controller | `ACPI\AMD0020` | ACPI-enumerated PnP hardware ID | `amduart_Inst` | No(Build) | Native | Native | Native | NotDeclared |
| `c0004\amduart.inf` | AMD UART Controller | `ACPI\AMDI0020` | ACPI-enumerated PnP hardware ID | `amduart_Inst` | No(Build) | Native | Native | Native | NotDeclared |
| `c0004\amduart.inf` | AMD UART Controller | `ACPI\AMDI0022` | ACPI-enumerated PnP hardware ID | `amduart_Inst` | No(Build) | Native | Native | Native | NotDeclared |
| `c0004\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_15C4` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `c0004\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_15C5` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `c0004\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_162E` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `c0004\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_162F` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `c0004\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_1668` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `c0004\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_1669` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `c0004\amdusb4net.inf` | AMD USB4NET | `{b85b7c50-6a01-11d2-b841-00c04fad5171}\AMDUSB4NET` | Device-class-specific ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdusb4net.inf` | AMD USB4NET | `{b85b7c50-6a01-11d2-b841-00c04fad5171}\Usb4Net` | Device-class-specific ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdusb4net.inf` | AMD USB4NET | `root\AMDUSB4NET_a` | Root-enumerated PnP hardware ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdusb4net.inf` | AMD USB4NET | `root\AMDUSB4NET_b` | Root-enumerated PnP hardware ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdusb4net.inf` | AMD USB4NET | `root\AMDUSB4NET_c` | Root-enumerated PnP hardware ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdusb4net.inf` | AMD USB4NET | `root\AMDUSB4NET_d` | Root-enumerated PnP hardware ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdusb4pcifilter.inf` | PCI Express Root Port | `PCI\VEN_1022&DEV_14CD&SUBSYS_14531022&REV_00` | PCI-enumerated PnP hardware ID | `amdusb4pcifilter` | Native | Native | Excluded | Excluded | NotDeclared |
| `c0004\amdusb4pcifilter.inf` | PCI Express Root Port | `PCI\VEN_1022&DEV_14EF&SUBSYS_14531022&REV_00` | PCI-enumerated PnP hardware ID | `amdusb4pcifilter` | Native | Native | Excluded | Excluded | NotDeclared |
| `c0004\amdusb4pcifilter.inf` | PCI Express Root Port | `PCI\VEN_1022&DEV_14EF&SUBSYS_14531022&REV_01` | PCI-enumerated PnP hardware ID | `amdusb4pcifilter` | Native | Native | Excluded | Excluded | NotDeclared |
| `c0004\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15C0&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Excluded | Excluded | NotDeclared |
| `c0004\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15C1&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Excluded | Excluded | NotDeclared |
| `c0004\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15C2&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Excluded | Excluded | NotDeclared |
| `c0004\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15C3&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Excluded | Excluded | NotDeclared |
| `c0004\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15D6&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Excluded | Excluded | NotDeclared |
| `c0004\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15D7&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Excluded | Excluded | NotDeclared |
| `c0004\amdwirelessbutton.inf` | AMD Wireless Button Driver | `ACPI\AMDI0051` | ACPI-enumerated PnP hardware ID | `amdwirelessbutton_Device` | No(Build) | Native | Native | No | KMDF 1.15 |
| `c0004\amdwirelessbutton.inf` | AMD Wireless Button Driver | `ACPI\AMDI0051` | ACPI-enumerated PnP hardware ID | `amdwirelessbutton_DeviceWin11` | No(Build) | No | No | Native | KMDF 1.15 |
| `c0004\ams_mailboxdrv.inf` | AMS-MailBoxDrv | `ACPI\AMDI0090` | ACPI-enumerated PnP hardware ID | `AMS-MailBoxDrv_Device` | Native | Native | Native | Native | NotDeclared |
| `c0004\plutonnull.inf` | AMD NULL Driver for Microsoft Pluton Security Processor | `ACPI\MSFT0200` | ACPI-enumerated PnP hardware ID | `Null_Pluton_Device` | Native | Native | Native | Excluded | NotDeclared |
| `c0004\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4353` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `c0004\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4363` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `c0004\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4372` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `c0004\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4385` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `c0004\smbusamd.inf` | AMD SMBus | `PCI\VEN_1022&DEV_780B` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `c0004\smbusamd.inf` | AMD SMBus | `PCI\VEN_1022&DEV_790B` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `c0004\usbfilter.inf` | AMD USB Filter Driver | `{36FC9E60-C465-11CF-8056-444553540000}\usbfilter` | Device-class-specific ID | `usbfilter` | Native | Native | Native | Native | NotDeclared |
| `c0004\zenpromnf.inf` | ZenProM S0i3 Network Filter | `ZenProMnf` | Network software component ID | `Install` | Native | Native | Native | Native | NotDeclared |

## AMD Chipset Software 8.07.16.1035

| INF | Device | Device identifier | Identifier type | Install section | WS2016 | WS2019 | WS2022 | WS2025 | WDF |
|---|---|---|---|---|---|---|---|---|---|
| `c0004\amd3dvcache.inf` | AMD 3D V-Cache Performance Optimizer | `ACPI\AMDI0101` | ACPI-enumerated PnP hardware ID | `Amd3dvcache_Device` | No(Build) | No(Build) | Native | Native | KMDF 1.15 |
| `c0004\amdappcompat.inf` | AMD Application Compatibility Database | `ACPI\AMDI0204` | ACPI-enumerated PnP hardware ID | `AmdAppCompat_Device` | No(Build) | Native | Native | Native | KMDF 1.15 |
| `c0004\amdas4.inf` | AmdAS4 Device | `ACPI\AMDI0050` | ACPI-enumerated PnP hardware ID | `AmdAS4` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdas4.inf` | AmdAS4 Device | `ACPI\ASD0001` | ACPI-enumerated PnP hardware ID | `AmdAS4` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdcir.inf` | AMD CIR Driver | `*AMDC001` | Generic PnP hardware ID | `AMDCIR64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdcir.inf` | AMD CIR Driver | `*AMDC002` | Generic PnP hardware ID | `AMDCIR64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdcir.inf` | AMD CIR Driver | `*AMDC003` | Generic PnP hardware ID | `AMDCIR64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdgpio2.inf` | AMD GPIO Controller | `ACPI\AMD0030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | No(Build) | Native | Native | Native | NotDeclared |
| `c0004\amdgpio2.inf` | AMD GPIO Controller | `ACPI\AMDI0030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | No(Build) | Native | Native | Native | NotDeclared |
| `c0004\amdgpio2.inf` | AMD GPIO Controller | `ACPI\AMDI0031` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | No(Build) | Native | Native | Native | NotDeclared |
| `c0004\amdgpio2.inf` | AMD GPIO Controller | `ACPI\GPIO0010` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | No(Build) | Native | Native | Native | NotDeclared |
| `c0004\amdgpio3.inf` | AMD GPIO Controller | `ACPI\AMDF030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `c0004\amdgpio3.inf` | AMD GPIO Controller | `ACPI\AMDIF030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `c0004\amdgpio3.inf` | AMD GPIO Controller | `ACPI\AMDIF031` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `c0004\amdhsmpdriver.inf` | AMD Host System Management Port | `ACPI\AMDI0097` | ACPI-enumerated PnP hardware ID | `AmdHsmpDriver_Device` | No(Build) | No(Build) | Native | Native | NotDeclared |
| `c0004\amdi2c.inf` | AMD I2C Controller | `ACPI\AMD0010` | ACPI-enumerated PnP hardware ID | `amdi2c_Device` | No(Build) | Native | Native | Native | NotDeclared |
| `c0004\amdi2c.inf` | AMD I2C Controller | `ACPI\AMDI0010` | ACPI-enumerated PnP hardware ID | `amdi2c_Device` | No(Build) | Native | Native | Native | NotDeclared |
| `c0004\amdinterface.inf` | AMD PCI | `PCI\VEN_1002&DEV_145A` | PCI-enumerated PnP hardware ID | `AMDPCI64` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `c0004\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_1116` | PCI-enumerated PnP hardware ID | `AMDPCI64` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `c0004\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_1117` | PCI-enumerated PnP hardware ID | `AMDPCI64` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `c0004\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_1136` | PCI-enumerated PnP hardware ID | `AMDPCI64` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `c0004\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_1137` | PCI-enumerated PnP hardware ID | `AMDPCI64` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `c0004\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_1151` | PCI-enumerated PnP hardware ID | `AMDPCI64` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `c0004\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_1176` | PCI-enumerated PnP hardware ID | `AMDPCI64` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `c0004\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_11B0` | PCI-enumerated PnP hardware ID | `AMDPCI64` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `c0004\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_14AC` | PCI-enumerated PnP hardware ID | `AMDPCI64` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `c0004\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_14DC` | PCI-enumerated PnP hardware ID | `AMDPCI64` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `c0004\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_14DE` | PCI-enumerated PnP hardware ID | `AMDPCI64` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `c0004\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_14EC` | PCI-enumerated PnP hardware ID | `AMDPCI64` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `c0004\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_150D` | PCI-enumerated PnP hardware ID | `AMDPCI64` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `c0004\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_1556` | PCI-enumerated PnP hardware ID | `AMDPCI64` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `c0004\amdinterface.inf` | AMD PSP | `PCI\VEN_1022&DEV_1B16` | PCI-enumerated PnP hardware ID | `AMDPCI64` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `c0004\amdinterface.inf` | AMD PSP | `PCI\VEN_1022&DEV_1B26` | PCI-enumerated PnP hardware ID | `AMDPCI64` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `c0004\amdinterface.inf` | AMD SMBUS | `PCI\VEN_1022&DEV_790B` | PCI-enumerated PnP hardware ID | `AMDPCI64` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `c0004\amdinterface.inf` | AMD SPI Controller | `ACPI\AMDI0062` | ACPI-enumerated PnP hardware ID | `AMDPCI64` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `c0004\amdinterface.inf` | AMD WPS PCC Driver | `ACPI\PccIntAA` | ACPI-enumerated PnP hardware ID | `AMDPCI64` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1002&DEV_5A23` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_13E1` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1419` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1423` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1437` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1451` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1481` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1577` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_164F` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMD0004` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | No(Build) | Projection | Projection | Projection | NotDeclared |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMD0005` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | No(Build) | Projection | Projection | Projection | NotDeclared |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0005` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | No(Build) | Projection | Projection | Projection | NotDeclared |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0006` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | No(Build) | Projection | Projection | Projection | NotDeclared |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0007` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | No(Build) | Projection | Projection | Projection | NotDeclared |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0008` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | No(Build) | Projection | Projection | Projection | NotDeclared |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0009` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | No(Build) | Projection | Projection | Projection | NotDeclared |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI000A` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install.AMDI000A` | No(Build) | Projection | Projection | Projection | NotDeclared |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI000B` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | No(Build) | Projection | Projection | Projection | NotDeclared |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI000C` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | No(Build) | Projection | Projection | Projection | NotDeclared |
| `c0004\amdoemprov.inf` | AMD Provisioning for OEM | `ACPI\AMDI0053` | ACPI-enumerated PnP hardware ID | `AMDPPMPF_DEV` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `c0004\amdpcidev.inf` | AMD PCI | `PCI\VEN_1002&DEV_145A` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_1455` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_145A` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_1485` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_148A` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_14DE` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdpmf.inf` | AMD PMF | `ACPI\AMDI0102` | ACPI-enumerated PnP hardware ID | `AMDPMF_INSTALL.NTamd64.10.0...19041` | No(Build) | No(Build) | Native | Native | NotDeclared |
| `c0004\amdpmf.inf` | AMD PMF | `ACPI\AMDI0103` | ACPI-enumerated PnP hardware ID | `AMDPMF_INSTALL.NTamd64.10.0...19041` | No(Build) | No(Build) | Native | Native | NotDeclared |
| `c0004\amdpmf.inf` | AMD PMF | `ACPI\AMDI0105` | ACPI-enumerated PnP hardware ID | `AMDPMF_INSTALL.NTamd64.10.0...19041` | No(Build) | No(Build) | Native | Native | NotDeclared |
| `c0004\amdpmf.inf` | AMD PMF | `ACPI\AMDI0107` | ACPI-enumerated PnP hardware ID | `AMDPMF_INSTALL.NTamd64.10.0...19041` | No(Build) | No(Build) | Native | Native | NotDeclared |
| `c0004\amdpmf.inf` | AMD PMF | `ACPI\AMDI0108` | ACPI-enumerated PnP hardware ID | `AMDPMF_INSTALL.NTamd64.10.0...19041` | No(Build) | No(Build) | Native | Native | NotDeclared |
| `c0004\amdpmf.inf` | AMD PMF | `ACPI\AMDI0109` | ACPI-enumerated PnP hardware ID | `AMDPMF_INSTALL.NTamd64.10.0...19041` | No(Build) | No(Build) | Native | Native | NotDeclared |
| `c0004\amdpmf.inf` | AMD PMF | `ACPI\AMDI0112` | ACPI-enumerated PnP hardware ID | `AMDPMF_INSTALL.NTamd64.10.0...19041` | No(Build) | No(Build) | Native | Native | NotDeclared |
| `c0004\amdppkg.inf` | AMD Provisioning Packages | `ACPI\AMDI0052` | ACPI-enumerated PnP hardware ID | `InstallSection_Win10` | No(Build) | No(Build) | Native | No | NotDeclared |
| `c0004\amdppkg.inf` | AMD Provisioning Packages | `ACPI\AMDI0052` | ACPI-enumerated PnP hardware ID | `InstallSection_Win11_22H2` | No(Build) | No(Build) | No | Native | NotDeclared |
| `c0004\amdpsp.inf` | AMD PSP 10.0 Device | `PCI\VEN_1022&DEV_15DF` | PCI-enumerated PnP hardware ID | `amdpsp_Device_100` | Native | No | No | No | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP 10.0 Device | `PCI\VEN_1022&DEV_15DF` | PCI-enumerated PnP hardware ID | `amdpsp_Device_100_RS3` | No | Native | Native | Native | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_1134` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | No | No | No | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_1134` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110_RS3` | No | Native | Native | Native | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_115A` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110_RS3` | No | Native | Native | Native | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_115A` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | No | No | No | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_1486` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110_RS3` | No | Native | Native | Native | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_1486` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | No | No | No | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_14CA` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110_RS3` | No | Native | Native | Native | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_14CA` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | No | No | No | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_156E` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110_RS3` | No | Native | Native | Native | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_156E` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | No | No | No | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_15C7` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | No | No | No | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_15C7` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110_RS3` | No | Native | Native | Native | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_1649` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | No | No | No | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_1649` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110_RS3` | No | Native | Native | Native | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_17E0` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110_RS3` | No | Native | Native | Native | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_17E0` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | No | No | No | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_13EC` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | No | No | No | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_13EC` | PCI-enumerated PnP hardware ID | `amdpsp_Device_RS3` | No | Native | Native | Native | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_1456` | PCI-enumerated PnP hardware ID | `amdpsp_Device_RS3` | No | Native | Native | Native | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_1456` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | No | No | No | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_1537` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | No | No | No | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_1537` | PCI-enumerated PnP hardware ID | `amdpsp_Device_RS3` | No | Native | Native | Native | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_1578` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | No | No | No | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_1578` | PCI-enumerated PnP hardware ID | `amdpsp_Device_RS3` | No | Native | Native | Native | KMDF 1.13 |
| `c0004\amdsfhkmdf.inf` | AMD Sensor Fusion Hub | `PCI\VEN_1022&DEV_15E4` | PCI-enumerated PnP hardware ID | `amdsfhkmdf_Device` | Native | Native | Native | Native | KMDF 1.15 |
| `c0004\amdsfhkmdfi2c.inf` | AMD SFH KMDF I2C | `PCI\VEN_1022&DEV_15E6` | PCI-enumerated PnP hardware ID | `amdsfhkmdf_Device` | Native | Native | Native | Native | KMDF 1.15 |
| `c0004\amdsfhspbi2c.inf` | AMD SFH I2C Controller | `ACPI\AMDI0011` | ACPI-enumerated PnP hardware ID | `amdsfhspbi2c_Device` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdsfhumdf.inf` | AMD UMDF Sensor | `ACPI\AMDI0080` | ACPI-enumerated PnP hardware ID | `amdsfhumdf_Inst_Win10` | No(Build) | Native | Native | No | UMDF 2.15.0 |
| `c0004\amdsfhumdf.inf` | AMD UMDF Sensor | `ACPI\AMDI0080` | ACPI-enumerated PnP hardware ID | `amdsfhumdf_Inst_Win11` | No(Build) | No | No | Native | UMDF 2.15.0 |
| `c0004\amduart.inf` | AMD UART Controller | `ACPI\AMD0020` | ACPI-enumerated PnP hardware ID | `amduart_Inst` | No(Build) | Native | Native | Native | NotDeclared |
| `c0004\amduart.inf` | AMD UART Controller | `ACPI\AMDI0020` | ACPI-enumerated PnP hardware ID | `amduart_Inst` | No(Build) | Native | Native | Native | NotDeclared |
| `c0004\amduart.inf` | AMD UART Controller | `ACPI\AMDI0022` | ACPI-enumerated PnP hardware ID | `amduart_Inst` | No(Build) | Native | Native | Native | NotDeclared |
| `c0004\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_15C4` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `c0004\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_15C5` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `c0004\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_162E` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `c0004\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_162F` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `c0004\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_1668` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `c0004\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_1669` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `c0004\amdusb4net.inf` | AMD USB4NET | `{b85b7c50-6a01-11d2-b841-00c04fad5171}\AMDUSB4NET` | Device-class-specific ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdusb4net.inf` | AMD USB4NET | `{b85b7c50-6a01-11d2-b841-00c04fad5171}\Usb4Net` | Device-class-specific ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdusb4net.inf` | AMD USB4NET | `root\AMDUSB4NET_a` | Root-enumerated PnP hardware ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdusb4net.inf` | AMD USB4NET | `root\AMDUSB4NET_b` | Root-enumerated PnP hardware ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdusb4net.inf` | AMD USB4NET | `root\AMDUSB4NET_c` | Root-enumerated PnP hardware ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdusb4net.inf` | AMD USB4NET | `root\AMDUSB4NET_d` | Root-enumerated PnP hardware ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdusb4pcifilter.inf` | PCI Express Root Port | `PCI\VEN_1022&DEV_14CD&SUBSYS_14531022&REV_00` | PCI-enumerated PnP hardware ID | `amdusb4pcifilter` | Native | Native | Excluded | Excluded | NotDeclared |
| `c0004\amdusb4pcifilter.inf` | PCI Express Root Port | `PCI\VEN_1022&DEV_14EF&SUBSYS_14531022&REV_00` | PCI-enumerated PnP hardware ID | `amdusb4pcifilter` | Native | Native | Excluded | Excluded | NotDeclared |
| `c0004\amdusb4pcifilter.inf` | PCI Express Root Port | `PCI\VEN_1022&DEV_14EF&SUBSYS_14531022&REV_01` | PCI-enumerated PnP hardware ID | `amdusb4pcifilter` | Native | Native | Excluded | Excluded | NotDeclared |
| `c0004\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15C0&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Excluded | Excluded | NotDeclared |
| `c0004\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15C1&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Excluded | Excluded | NotDeclared |
| `c0004\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15C2&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Excluded | Excluded | NotDeclared |
| `c0004\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15C3&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Excluded | Excluded | NotDeclared |
| `c0004\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15D6&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Excluded | Excluded | NotDeclared |
| `c0004\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15D7&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Excluded | Excluded | NotDeclared |
| `c0004\amdwirelessbutton.inf` | AMD Wireless Button Driver | `ACPI\AMDI0051` | ACPI-enumerated PnP hardware ID | `amdwirelessbutton_Device` | No(Build) | Native | Native | No | KMDF 1.15 |
| `c0004\amdwirelessbutton.inf` | AMD Wireless Button Driver | `ACPI\AMDI0051` | ACPI-enumerated PnP hardware ID | `amdwirelessbutton_DeviceWin11` | No(Build) | No | No | Native | KMDF 1.15 |
| `c0004\ams_mailboxdrv.inf` | AMS-MailBoxDrv | `ACPI\AMDI0090` | ACPI-enumerated PnP hardware ID | `AMS-MailBoxDrv_Device` | Native | Native | Native | Native | NotDeclared |
| `c0004\plutonnull.inf` | AMD NULL Driver for Microsoft Pluton Security Processor | `ACPI\MSFT0200` | ACPI-enumerated PnP hardware ID | `Null_Pluton_Device` | Native | Native | Native | Excluded | NotDeclared |
| `c0004\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4353` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `c0004\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4363` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `c0004\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4372` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `c0004\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4385` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `c0004\smbusamd.inf` | AMD SMBus | `PCI\VEN_1022&DEV_780B` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `c0004\smbusamd.inf` | AMD SMBus | `PCI\VEN_1022&DEV_790B` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `c0004\usbfilter.inf` | AMD USB Filter Driver | `{36FC9E60-C465-11CF-8056-444553540000}\usbfilter` | Device-class-specific ID | `usbfilter` | Native | Native | Native | Native | NotDeclared |
| `c0004\zenpromnf.inf` | ZenProM S0i3 Network Filter | `ZenProMnf` | Network software component ID | `Install` | Native | Native | Native | Native | NotDeclared |

## AMD Chipset Software 8.05.04.516

| INF | Device | Device identifier | Identifier type | Install section | WS2016 | WS2019 | WS2022 | WS2025 | WDF |
|---|---|---|---|---|---|---|---|---|---|
| `c0004\amd3dvcache.inf` | AMD 3D V-Cache Performance Optimizer | `ACPI\AMDI0101` | ACPI-enumerated PnP hardware ID | `Amd3dvcache_Device` | No(Build) | No(Build) | Native | Native | KMDF 1.15 |
| `c0004\amdappcompat.inf` | AMD Application Compatibility Database | `ACPI\AMDI0204` | ACPI-enumerated PnP hardware ID | `AmdAppCompat_Device` | No(Build) | Native | Native | Native | KMDF 1.15 |
| `c0004\amdas4.inf` | AmdAS4 Device | `ACPI\AMDI0050` | ACPI-enumerated PnP hardware ID | `AmdAS4` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdas4.inf` | AmdAS4 Device | `ACPI\ASD0001` | ACPI-enumerated PnP hardware ID | `AmdAS4` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdcir.inf` | AMD CIR Driver | `*AMDC001` | Generic PnP hardware ID | `AMDCIR64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdcir.inf` | AMD CIR Driver | `*AMDC002` | Generic PnP hardware ID | `AMDCIR64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdcir.inf` | AMD CIR Driver | `*AMDC003` | Generic PnP hardware ID | `AMDCIR64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdgpio2.inf` | AMD GPIO Controller | `ACPI\AMD0030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | No(Build) | Native | Native | Native | NotDeclared |
| `c0004\amdgpio2.inf` | AMD GPIO Controller | `ACPI\AMDI0030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | No(Build) | Native | Native | Native | NotDeclared |
| `c0004\amdgpio2.inf` | AMD GPIO Controller | `ACPI\AMDI0031` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | No(Build) | Native | Native | Native | NotDeclared |
| `c0004\amdgpio2.inf` | AMD GPIO Controller | `ACPI\GPIO0010` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | No(Build) | Native | Native | Native | NotDeclared |
| `c0004\amdgpio3.inf` | AMD GPIO Controller | `ACPI\AMDF030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `c0004\amdgpio3.inf` | AMD GPIO Controller | `ACPI\AMDIF030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `c0004\amdgpio3.inf` | AMD GPIO Controller | `ACPI\AMDIF031` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `c0004\amdhsmpdriver.inf` | AMD Host System Management Port | `ACPI\AMDI0097` | ACPI-enumerated PnP hardware ID | `AmdHsmpDriver_Device` | No(Build) | No(Build) | Native | Native | NotDeclared |
| `c0004\amdi2c.inf` | AMD I2C Controller | `ACPI\AMD0010` | ACPI-enumerated PnP hardware ID | `amdi2c_Device` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdi2c.inf` | AMD I2C Controller | `ACPI\AMDI0010` | ACPI-enumerated PnP hardware ID | `amdi2c_Device` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdinterface.inf` | AMD PCI | `PCI\VEN_1002&DEV_145A` | PCI-enumerated PnP hardware ID | `AMDPCI64` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `c0004\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_1116` | PCI-enumerated PnP hardware ID | `AMDPCI64` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `c0004\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_1117` | PCI-enumerated PnP hardware ID | `AMDPCI64` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `c0004\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_1136` | PCI-enumerated PnP hardware ID | `AMDPCI64` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `c0004\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_1137` | PCI-enumerated PnP hardware ID | `AMDPCI64` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `c0004\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_1151` | PCI-enumerated PnP hardware ID | `AMDPCI64` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `c0004\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_14AC` | PCI-enumerated PnP hardware ID | `AMDPCI64` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `c0004\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_14DC` | PCI-enumerated PnP hardware ID | `AMDPCI64` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `c0004\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_14DE` | PCI-enumerated PnP hardware ID | `AMDPCI64` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `c0004\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_14EC` | PCI-enumerated PnP hardware ID | `AMDPCI64` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `c0004\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_150D` | PCI-enumerated PnP hardware ID | `AMDPCI64` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `c0004\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_1556` | PCI-enumerated PnP hardware ID | `AMDPCI64` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `c0004\amdinterface.inf` | AMD SMBUS | `PCI\VEN_1022&DEV_790B` | PCI-enumerated PnP hardware ID | `AMDPCI64` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `c0004\amdinterface.inf` | AMD SPI Controller | `ACPI\AMDI0062` | ACPI-enumerated PnP hardware ID | `AMDPCI64` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1002&DEV_5A23` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_13E1` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1419` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1423` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1437` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1451` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1481` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1577` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_164F` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMD0004` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | No(Build) | Projection | Projection | Projection | NotDeclared |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMD0005` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | No(Build) | Projection | Projection | Projection | NotDeclared |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0005` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | No(Build) | Projection | Projection | Projection | NotDeclared |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0006` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | No(Build) | Projection | Projection | Projection | NotDeclared |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0007` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | No(Build) | Projection | Projection | Projection | NotDeclared |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0008` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | No(Build) | Projection | Projection | Projection | NotDeclared |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0009` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | No(Build) | Projection | Projection | Projection | NotDeclared |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI000A` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install.AMDI000A` | No(Build) | Projection | Projection | Projection | NotDeclared |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI000B` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | No(Build) | Projection | Projection | Projection | NotDeclared |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI000C` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | No(Build) | Projection | Projection | Projection | NotDeclared |
| `c0004\amdoemprov.inf` | AMD Provisioning for OEM | `ACPI\AMDI0053` | ACPI-enumerated PnP hardware ID | `AMDPPMPF_DEV` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `c0004\amdpcidev.inf` | AMD PCI | `PCI\VEN_1002&DEV_145A` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_1455` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_145A` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_1485` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_148A` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_14DE` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdpmf.inf` | AMD PMF | `ACPI\AMDI0100` | ACPI-enumerated PnP hardware ID | `AMDPMF_INSTALL.NTamd64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdpmf.inf` | AMD PMF | `ACPI\AMDI0102` | ACPI-enumerated PnP hardware ID | `AMDPMF_INSTALL.NTamd64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdppkg.inf` | AMD Provisioning Packages | `ACPI\AMDI0052` | ACPI-enumerated PnP hardware ID | `InstallSection_Win10` | No(Build) | No(Build) | Native | No | NotDeclared |
| `c0004\amdppkg.inf` | AMD Provisioning Packages | `ACPI\AMDI0052` | ACPI-enumerated PnP hardware ID | `InstallSection_Win11_22H2` | No(Build) | No(Build) | No | Native | NotDeclared |
| `c0004\amdpsp.inf` | AMD PSP 10.0 Device | `PCI\VEN_1022&DEV_15DF` | PCI-enumerated PnP hardware ID | `amdpsp_Device_100` | Native | No | No | No | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP 10.0 Device | `PCI\VEN_1022&DEV_15DF` | PCI-enumerated PnP hardware ID | `amdpsp_Device_100_RS3` | No | Native | Native | Native | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_1134` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | No | No | No | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_1134` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110_RS3` | No | Native | Native | Native | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_115A` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110_RS3` | No | Native | Native | Native | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_115A` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | No | No | No | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_1486` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110_RS3` | No | Native | Native | Native | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_1486` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | No | No | No | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_14CA` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110_RS3` | No | Native | Native | Native | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_14CA` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | No | No | No | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_156E` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110_RS3` | No | Native | Native | Native | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_156E` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | No | No | No | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_15C7` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | No | No | No | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_15C7` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110_RS3` | No | Native | Native | Native | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_1649` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | No | No | No | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_1649` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110_RS3` | No | Native | Native | Native | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_17E0` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110_RS3` | No | Native | Native | Native | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_17E0` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | No | No | No | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_13EC` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | No | No | No | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_13EC` | PCI-enumerated PnP hardware ID | `amdpsp_Device_RS3` | No | Native | Native | Native | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_1456` | PCI-enumerated PnP hardware ID | `amdpsp_Device_RS3` | No | Native | Native | Native | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_1456` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | No | No | No | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_1537` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | No | No | No | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_1537` | PCI-enumerated PnP hardware ID | `amdpsp_Device_RS3` | No | Native | Native | Native | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_1578` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | No | No | No | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_1578` | PCI-enumerated PnP hardware ID | `amdpsp_Device_RS3` | No | Native | Native | Native | KMDF 1.13 |
| `c0004\amdsfhkmdf.inf` | AMD Sensor Fusion Hub | `PCI\VEN_1022&DEV_15E4` | PCI-enumerated PnP hardware ID | `amdsfhkmdf_Device` | Native | Native | Native | Native | KMDF 1.15 |
| `c0004\amdsfhkmdfi2c.inf` | AMD SFH KMDF I2C | `PCI\VEN_1022&DEV_15E6` | PCI-enumerated PnP hardware ID | `amdsfhkmdf_Device` | Native | Native | Native | Native | KMDF 1.15 |
| `c0004\amdsfhspbi2c.inf` | AMD SFH I2C Controller | `ACPI\AMDI0011` | ACPI-enumerated PnP hardware ID | `amdsfhspbi2c_Device` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdsfhumdf.inf` | AMD UMDF Sensor | `ACPI\AMDI0080` | ACPI-enumerated PnP hardware ID | `amdsfhumdf_Inst_Win10` | No(Build) | Native | Native | No | UMDF 2.15.0 |
| `c0004\amdsfhumdf.inf` | AMD UMDF Sensor | `ACPI\AMDI0080` | ACPI-enumerated PnP hardware ID | `amdsfhumdf_Inst_Win11` | No(Build) | No | No | Native | UMDF 2.15.0 |
| `c0004\amduart.inf` | AMD UART Controller | `ACPI\AMD0020` | ACPI-enumerated PnP hardware ID | `amduart_Inst` | No(Build) | Native | Native | Native | NotDeclared |
| `c0004\amduart.inf` | AMD UART Controller | `ACPI\AMDI0020` | ACPI-enumerated PnP hardware ID | `amduart_Inst` | No(Build) | Native | Native | Native | NotDeclared |
| `c0004\amduart.inf` | AMD UART Controller | `ACPI\AMDI0022` | ACPI-enumerated PnP hardware ID | `amduart_Inst` | No(Build) | Native | Native | Native | NotDeclared |
| `c0004\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_15C4` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `c0004\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_15C5` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `c0004\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_162E` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `c0004\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_162F` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `c0004\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_1668` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `c0004\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_1669` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `c0004\amdusb4net.inf` | AMD USB4NET | `{b85b7c50-6a01-11d2-b841-00c04fad5171}\AMDUSB4NET` | Device-class-specific ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdusb4net.inf` | AMD USB4NET | `{b85b7c50-6a01-11d2-b841-00c04fad5171}\Usb4Net` | Device-class-specific ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdusb4net.inf` | AMD USB4NET | `root\AMDUSB4NET_a` | Root-enumerated PnP hardware ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdusb4net.inf` | AMD USB4NET | `root\AMDUSB4NET_b` | Root-enumerated PnP hardware ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdusb4net.inf` | AMD USB4NET | `root\AMDUSB4NET_c` | Root-enumerated PnP hardware ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdusb4net.inf` | AMD USB4NET | `root\AMDUSB4NET_d` | Root-enumerated PnP hardware ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdusb4pcifilter.inf` | PCI Express Root Port | `PCI\VEN_1022&DEV_14CD&SUBSYS_14531022&REV_00` | PCI-enumerated PnP hardware ID | `amdusb4pcifilter` | Native | Native | Excluded | Excluded | NotDeclared |
| `c0004\amdusb4pcifilter.inf` | PCI Express Root Port | `PCI\VEN_1022&DEV_14EF&SUBSYS_14531022&REV_00` | PCI-enumerated PnP hardware ID | `amdusb4pcifilter` | Native | Native | Excluded | Excluded | NotDeclared |
| `c0004\amdusb4pcifilter.inf` | PCI Express Root Port | `PCI\VEN_1022&DEV_14EF&SUBSYS_14531022&REV_01` | PCI-enumerated PnP hardware ID | `amdusb4pcifilter` | Native | Native | Excluded | Excluded | NotDeclared |
| `c0004\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15C0&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Excluded | Excluded | NotDeclared |
| `c0004\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15C1&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Excluded | Excluded | NotDeclared |
| `c0004\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15C2&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Excluded | Excluded | NotDeclared |
| `c0004\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15C3&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Excluded | Excluded | NotDeclared |
| `c0004\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15D6&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Excluded | Excluded | NotDeclared |
| `c0004\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15D7&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Excluded | Excluded | NotDeclared |
| `c0004\amdwirelessbutton.inf` | AMD Wireless Button Driver | `ACPI\AMDI0051` | ACPI-enumerated PnP hardware ID | `amdwirelessbutton_Device` | No(Build) | Native | Native | No | KMDF 1.15 |
| `c0004\amdwirelessbutton.inf` | AMD Wireless Button Driver | `ACPI\AMDI0051` | ACPI-enumerated PnP hardware ID | `amdwirelessbutton_DeviceWin11` | No(Build) | No | No | Native | KMDF 1.15 |
| `c0004\ams_mailboxdrv.inf` | AMS-MailBoxDrv | `ACPI\AMDI0090` | ACPI-enumerated PnP hardware ID | `AMS-MailBoxDrv_Device` | Native | Native | Native | Native | NotDeclared |
| `c0004\plutonnull.inf` | AMD NULL Driver for Microsoft Pluton Security Processor | `ACPI\MSFT0200` | ACPI-enumerated PnP hardware ID | `Null_Pluton_Device` | Native | Native | Native | Excluded | NotDeclared |
| `c0004\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4353` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `c0004\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4363` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `c0004\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4372` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `c0004\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4385` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `c0004\smbusamd.inf` | AMD SMBus | `PCI\VEN_1022&DEV_780B` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `c0004\smbusamd.inf` | AMD SMBus | `PCI\VEN_1022&DEV_790B` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `c0004\usbfilter.inf` | AMD USB Filter Driver | `{36FC9E60-C465-11CF-8056-444553540000}\usbfilter` | Device-class-specific ID | `usbfilter` | Native | Native | Native | Native | NotDeclared |
| `c0004\zenpromnf.inf` | ZenProM S0i3 Network Filter | `ZenProMnf` | Network software component ID | `Install` | Native | Native | Native | Native | NotDeclared |

## AMD Chipset Software 8.02.18.557

| INF | Device | Device identifier | Identifier type | Install section | WS2016 | WS2019 | WS2022 | WS2025 | WDF |
|---|---|---|---|---|---|---|---|---|---|
| `c0004\amd3dvcache.inf` | AMD 3D V-Cache Performance Optimizer | `ACPI\AMDI0101` | ACPI-enumerated PnP hardware ID | `Amd3dvcache_Device` | No(Build) | No(Build) | Native | Native | KMDF 1.15 |
| `c0004\amdappcompat.inf` | AMD Application Compatibility Database | `ACPI\AMDI0204` | ACPI-enumerated PnP hardware ID | `AmdAppCompat_Device` | No(Build) | Native | Native | Native | KMDF 1.15 |
| `c0004\amdas4.inf` | AmdAS4 Device | `ACPI\AMDI0050` | ACPI-enumerated PnP hardware ID | `AmdAS4` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdas4.inf` | AmdAS4 Device | `ACPI\ASD0001` | ACPI-enumerated PnP hardware ID | `AmdAS4` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdcir.inf` | AMD CIR Driver | `*AMDC001` | Generic PnP hardware ID | `AMDCIR64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdcir.inf` | AMD CIR Driver | `*AMDC002` | Generic PnP hardware ID | `AMDCIR64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdcir.inf` | AMD CIR Driver | `*AMDC003` | Generic PnP hardware ID | `AMDCIR64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdgpio2.inf` | AMD GPIO Controller | `ACPI\AMD0030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | No(Build) | Native | Native | Native | NotDeclared |
| `c0004\amdgpio2.inf` | AMD GPIO Controller | `ACPI\AMDI0030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | No(Build) | Native | Native | Native | NotDeclared |
| `c0004\amdgpio2.inf` | AMD GPIO Controller | `ACPI\AMDI0031` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | No(Build) | Native | Native | Native | NotDeclared |
| `c0004\amdgpio2.inf` | AMD GPIO Controller | `ACPI\GPIO0010` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | No(Build) | Native | Native | Native | NotDeclared |
| `c0004\amdgpio3.inf` | AMD GPIO Controller | `ACPI\AMDF030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `c0004\amdgpio3.inf` | AMD GPIO Controller | `ACPI\AMDIF030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `c0004\amdgpio3.inf` | AMD GPIO Controller | `ACPI\AMDIF031` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `c0004\amdhsmpdriver.inf` | AMD Host System Management Port | `ACPI\AMDI0097` | ACPI-enumerated PnP hardware ID | `AmdHsmpDriver_Device` | No(Build) | No(Build) | Native | Native | NotDeclared |
| `c0004\amdi2c.inf` | AMD I2C Controller | `ACPI\AMD0010` | ACPI-enumerated PnP hardware ID | `amdi2c_Device` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdi2c.inf` | AMD I2C Controller | `ACPI\AMDI0010` | ACPI-enumerated PnP hardware ID | `amdi2c_Device` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdinterface.inf` | AMD PCI | `PCI\VEN_1002&DEV_145A` | PCI-enumerated PnP hardware ID | `AMDPCI64` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `c0004\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_1116` | PCI-enumerated PnP hardware ID | `AMDPCI64` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `c0004\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_1117` | PCI-enumerated PnP hardware ID | `AMDPCI64` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `c0004\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_1136` | PCI-enumerated PnP hardware ID | `AMDPCI64` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `c0004\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_1137` | PCI-enumerated PnP hardware ID | `AMDPCI64` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `c0004\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_1151` | PCI-enumerated PnP hardware ID | `AMDPCI64` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `c0004\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_14AC` | PCI-enumerated PnP hardware ID | `AMDPCI64` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `c0004\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_14DC` | PCI-enumerated PnP hardware ID | `AMDPCI64` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `c0004\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_14DE` | PCI-enumerated PnP hardware ID | `AMDPCI64` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `c0004\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_14EC` | PCI-enumerated PnP hardware ID | `AMDPCI64` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `c0004\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_150D` | PCI-enumerated PnP hardware ID | `AMDPCI64` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `c0004\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_1556` | PCI-enumerated PnP hardware ID | `AMDPCI64` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `c0004\amdinterface.inf` | AMD SMBUS | `PCI\VEN_1022&DEV_790B` | PCI-enumerated PnP hardware ID | `AMDPCI64` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `c0004\amdinterface.inf` | AMD SPI Controller | `ACPI\AMDI0062` | ACPI-enumerated PnP hardware ID | `AMDPCI64` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1002&DEV_5A23` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_13E1` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1419` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1423` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1437` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1451` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1481` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1577` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_164F` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMD0004` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | No(Build) | Projection | Projection | Projection | NotDeclared |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMD0005` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | No(Build) | Projection | Projection | Projection | NotDeclared |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0005` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | No(Build) | Projection | Projection | Projection | NotDeclared |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0006` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | No(Build) | Projection | Projection | Projection | NotDeclared |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0007` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | No(Build) | Projection | Projection | Projection | NotDeclared |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0008` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | No(Build) | Projection | Projection | Projection | NotDeclared |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0009` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | No(Build) | Projection | Projection | Projection | NotDeclared |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI000A` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install.AMDI000A` | No(Build) | Projection | Projection | Projection | NotDeclared |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI000B` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | No(Build) | Projection | Projection | Projection | NotDeclared |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI000C` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | No(Build) | Projection | Projection | Projection | NotDeclared |
| `c0004\amdoemprov.inf` | AMD Provisioning for OEM | `ACPI\AMDI0053` | ACPI-enumerated PnP hardware ID | `AMDPPMPF_DEV` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `c0004\amdpcidev.inf` | AMD PCI | `PCI\VEN_1002&DEV_145A` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_1455` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_145A` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_1485` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_148A` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_14DE` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdpmf.inf` | AMD PMF | `ACPI\AMDI0100` | ACPI-enumerated PnP hardware ID | `AMDPMF_INSTALL.NTamd64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdpmf.inf` | AMD PMF | `ACPI\AMDI0102` | ACPI-enumerated PnP hardware ID | `AMDPMF_INSTALL.NTamd64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdppkg.inf` | AMD Provisioning Packages | `ACPI\AMDI0052` | ACPI-enumerated PnP hardware ID | `InstallSection_Win10` | No(Build) | No(Build) | Native | No | NotDeclared |
| `c0004\amdppkg.inf` | AMD Provisioning Packages | `ACPI\AMDI0052` | ACPI-enumerated PnP hardware ID | `InstallSection_Win11_22H2` | No(Build) | No(Build) | No | Native | NotDeclared |
| `c0004\amdpsp.inf` | AMD PSP 10.0 Device | `PCI\VEN_1022&DEV_15DF` | PCI-enumerated PnP hardware ID | `amdpsp_Device_100` | Native | No | No | No | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP 10.0 Device | `PCI\VEN_1022&DEV_15DF` | PCI-enumerated PnP hardware ID | `amdpsp_Device_100_RS3` | No | Native | Native | Native | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_1134` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | No | No | No | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_1134` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110_RS3` | No | Native | Native | Native | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_115A` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110_RS3` | No | Native | Native | Native | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_115A` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | No | No | No | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_1486` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110_RS3` | No | Native | Native | Native | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_1486` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | No | No | No | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_14CA` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110_RS3` | No | Native | Native | Native | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_14CA` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | No | No | No | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_156E` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110_RS3` | No | Native | Native | Native | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_156E` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | No | No | No | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_15C7` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | No | No | No | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_15C7` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110_RS3` | No | Native | Native | Native | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_1649` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | No | No | No | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_1649` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110_RS3` | No | Native | Native | Native | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_17E0` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110_RS3` | No | Native | Native | Native | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_17E0` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | No | No | No | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_13EC` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | No | No | No | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_13EC` | PCI-enumerated PnP hardware ID | `amdpsp_Device_RS3` | No | Native | Native | Native | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_1456` | PCI-enumerated PnP hardware ID | `amdpsp_Device_RS3` | No | Native | Native | Native | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_1456` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | No | No | No | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_1537` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | No | No | No | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_1537` | PCI-enumerated PnP hardware ID | `amdpsp_Device_RS3` | No | Native | Native | Native | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_1578` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | No | No | No | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_1578` | PCI-enumerated PnP hardware ID | `amdpsp_Device_RS3` | No | Native | Native | Native | KMDF 1.13 |
| `c0004\amdsfhkmdf.inf` | AMD Sensor Fusion Hub | `PCI\VEN_1022&DEV_15E4` | PCI-enumerated PnP hardware ID | `amdsfhkmdf_Device` | Native | Native | Native | Native | KMDF 1.15 |
| `c0004\amdsfhkmdfi2c.inf` | AMD SFH KMDF I2C | `PCI\VEN_1022&DEV_15E6` | PCI-enumerated PnP hardware ID | `amdsfhkmdf_Device` | Native | Native | Native | Native | KMDF 1.15 |
| `c0004\amdsfhspbi2c.inf` | AMD SFH I2C Controller | `ACPI\AMDI0011` | ACPI-enumerated PnP hardware ID | `amdsfhspbi2c_Device` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdsfhumdf.inf` | AMD UMDF Sensor | `ACPI\AMDI0080` | ACPI-enumerated PnP hardware ID | `amdsfhumdf_Inst_Win10` | No(Build) | Native | Native | No | UMDF 2.15.0 |
| `c0004\amdsfhumdf.inf` | AMD UMDF Sensor | `ACPI\AMDI0080` | ACPI-enumerated PnP hardware ID | `amdsfhumdf_Inst_Win11` | No(Build) | No | No | Native | UMDF 2.15.0 |
| `c0004\amduart.inf` | AMD UART Controller | `ACPI\AMD0020` | ACPI-enumerated PnP hardware ID | `amduart_Inst` | No(Build) | Native | Native | Native | NotDeclared |
| `c0004\amduart.inf` | AMD UART Controller | `ACPI\AMDI0020` | ACPI-enumerated PnP hardware ID | `amduart_Inst` | No(Build) | Native | Native | Native | NotDeclared |
| `c0004\amduart.inf` | AMD UART Controller | `ACPI\AMDI0022` | ACPI-enumerated PnP hardware ID | `amduart_Inst` | No(Build) | Native | Native | Native | NotDeclared |
| `c0004\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_15C4` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `c0004\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_15C5` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `c0004\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_162E` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `c0004\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_162F` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `c0004\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_1668` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `c0004\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_1669` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `c0004\amdusb4net.inf` | AMD USB4NET | `{b85b7c50-6a01-11d2-b841-00c04fad5171}\AMDUSB4NET` | Device-class-specific ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdusb4net.inf` | AMD USB4NET | `{b85b7c50-6a01-11d2-b841-00c04fad5171}\Usb4Net` | Device-class-specific ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdusb4net.inf` | AMD USB4NET | `root\AMDUSB4NET_a` | Root-enumerated PnP hardware ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdusb4net.inf` | AMD USB4NET | `root\AMDUSB4NET_b` | Root-enumerated PnP hardware ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdusb4net.inf` | AMD USB4NET | `root\AMDUSB4NET_c` | Root-enumerated PnP hardware ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdusb4net.inf` | AMD USB4NET | `root\AMDUSB4NET_d` | Root-enumerated PnP hardware ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdusb4pcifilter.inf` | PCI Express Root Port | `PCI\VEN_1022&DEV_14CD&SUBSYS_14531022&REV_00` | PCI-enumerated PnP hardware ID | `amdusb4pcifilter` | Native | Native | Excluded | Excluded | NotDeclared |
| `c0004\amdusb4pcifilter.inf` | PCI Express Root Port | `PCI\VEN_1022&DEV_14EF&SUBSYS_14531022&REV_00` | PCI-enumerated PnP hardware ID | `amdusb4pcifilter` | Native | Native | Excluded | Excluded | NotDeclared |
| `c0004\amdusb4pcifilter.inf` | PCI Express Root Port | `PCI\VEN_1022&DEV_14EF&SUBSYS_14531022&REV_01` | PCI-enumerated PnP hardware ID | `amdusb4pcifilter` | Native | Native | Excluded | Excluded | NotDeclared |
| `c0004\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15C0&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Excluded | Excluded | NotDeclared |
| `c0004\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15C1&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Excluded | Excluded | NotDeclared |
| `c0004\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15C2&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Excluded | Excluded | NotDeclared |
| `c0004\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15C3&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Excluded | Excluded | NotDeclared |
| `c0004\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15D6&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Excluded | Excluded | NotDeclared |
| `c0004\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15D7&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Excluded | Excluded | NotDeclared |
| `c0004\amdwirelessbutton.inf` | AMD Wireless Button Driver | `ACPI\AMDI0051` | ACPI-enumerated PnP hardware ID | `amdwirelessbutton_Device` | No(Build) | Native | Native | No | KMDF 1.15 |
| `c0004\amdwirelessbutton.inf` | AMD Wireless Button Driver | `ACPI\AMDI0051` | ACPI-enumerated PnP hardware ID | `amdwirelessbutton_DeviceWin11` | No(Build) | No | No | Native | KMDF 1.15 |
| `c0004\ams_mailboxdrv.inf` | AMS-MailBoxDrv | `ACPI\AMDI0090` | ACPI-enumerated PnP hardware ID | `AMS-MailBoxDrv_Device` | Native | Native | Native | Native | NotDeclared |
| `c0004\plutonnull.inf` | AMD NULL Driver for Microsoft Pluton Security Processor | `ACPI\MSFT0200` | ACPI-enumerated PnP hardware ID | `Null_Pluton_Device` | Native | Native | Native | Excluded | NotDeclared |
| `c0004\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4353` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `c0004\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4363` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `c0004\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4372` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `c0004\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4385` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `c0004\smbusamd.inf` | AMD SMBus | `PCI\VEN_1022&DEV_780B` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `c0004\smbusamd.inf` | AMD SMBus | `PCI\VEN_1022&DEV_790B` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `c0004\usbfilter.inf` | AMD USB Filter Driver | `{36FC9E60-C465-11CF-8056-444553540000}\usbfilter` | Device-class-specific ID | `usbfilter` | Native | Native | Native | Native | NotDeclared |
| `c0004\zenpromnf.inf` | ZenProM S0i3 Network Filter | `ZenProMnf` | Network software component ID | `Install` | Native | Native | Native | Native | NotDeclared |

## AMD Chipset Software 8.01.20.513

| INF | Device | Device identifier | Identifier type | Install section | WS2016 | WS2019 | WS2022 | WS2025 | WDF |
|---|---|---|---|---|---|---|---|---|---|
| `c0004\amd3dvcache.inf` | AMD 3D V-Cache Performance Optimizer | `ACPI\AMDI0101` | ACPI-enumerated PnP hardware ID | `Amd3dvcache_Device` | No(Build) | No(Build) | Native | Native | KMDF 1.15 |
| `c0004\amdappcompat.inf` | AMD Application Compatibility Database | `ACPI\AMDI0204` | ACPI-enumerated PnP hardware ID | `AmdAppCompat_Device` | No(Build) | Native | Native | Native | KMDF 1.15 |
| `c0004\amdas4.inf` | AmdAS4 Device | `ACPI\AMDI0050` | ACPI-enumerated PnP hardware ID | `AmdAS4` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdas4.inf` | AmdAS4 Device | `ACPI\ASD0001` | ACPI-enumerated PnP hardware ID | `AmdAS4` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdcir.inf` | AMD CIR Driver | `*AMDC001` | Generic PnP hardware ID | `AMDCIR64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdcir.inf` | AMD CIR Driver | `*AMDC002` | Generic PnP hardware ID | `AMDCIR64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdcir.inf` | AMD CIR Driver | `*AMDC003` | Generic PnP hardware ID | `AMDCIR64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdgpio2.inf` | AMD GPIO Controller | `ACPI\AMD0030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | No(Build) | Native | Native | Native | NotDeclared |
| `c0004\amdgpio2.inf` | AMD GPIO Controller | `ACPI\AMDI0030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | No(Build) | Native | Native | Native | NotDeclared |
| `c0004\amdgpio2.inf` | AMD GPIO Controller | `ACPI\AMDI0031` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | No(Build) | Native | Native | Native | NotDeclared |
| `c0004\amdgpio2.inf` | AMD GPIO Controller | `ACPI\GPIO0010` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | No(Build) | Native | Native | Native | NotDeclared |
| `c0004\amdgpio3.inf` | AMD GPIO Controller | `ACPI\AMDF030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `c0004\amdgpio3.inf` | AMD GPIO Controller | `ACPI\AMDIF030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `c0004\amdgpio3.inf` | AMD GPIO Controller | `ACPI\AMDIF031` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `c0004\amdhsmpdriver.inf` | AMD Host System Management Port | `ACPI\AMDI0097` | ACPI-enumerated PnP hardware ID | `AmdHsmpDriver_Device` | No(Build) | No(Build) | Native | Native | NotDeclared |
| `c0004\amdi2c.inf` | AMD I2C Controller | `ACPI\AMD0010` | ACPI-enumerated PnP hardware ID | `amdi2c_Device` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdi2c.inf` | AMD I2C Controller | `ACPI\AMDI0010` | ACPI-enumerated PnP hardware ID | `amdi2c_Device` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdinterface.inf` | AMD PCI | `PCI\VEN_1002&DEV_145A` | PCI-enumerated PnP hardware ID | `AMDPCI64` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `c0004\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_1116` | PCI-enumerated PnP hardware ID | `AMDPCI64` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `c0004\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_1117` | PCI-enumerated PnP hardware ID | `AMDPCI64` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `c0004\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_1136` | PCI-enumerated PnP hardware ID | `AMDPCI64` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `c0004\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_1137` | PCI-enumerated PnP hardware ID | `AMDPCI64` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `c0004\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_1151` | PCI-enumerated PnP hardware ID | `AMDPCI64` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `c0004\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_14AC` | PCI-enumerated PnP hardware ID | `AMDPCI64` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `c0004\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_14DC` | PCI-enumerated PnP hardware ID | `AMDPCI64` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `c0004\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_14DE` | PCI-enumerated PnP hardware ID | `AMDPCI64` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `c0004\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_14EC` | PCI-enumerated PnP hardware ID | `AMDPCI64` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `c0004\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_150D` | PCI-enumerated PnP hardware ID | `AMDPCI64` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `c0004\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_1556` | PCI-enumerated PnP hardware ID | `AMDPCI64` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `c0004\amdinterface.inf` | AMD SMBUS | `PCI\VEN_1022&DEV_790B` | PCI-enumerated PnP hardware ID | `AMDPCI64` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `c0004\amdinterface.inf` | AMD SPI Controller | `ACPI\AMDI0062` | ACPI-enumerated PnP hardware ID | `AMDPCI64` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1002&DEV_5A23` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_13E1` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1419` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1423` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1437` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1451` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1481` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1577` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_164F` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMD0004` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | No(Build) | Projection | Projection | Projection | NotDeclared |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMD0005` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | No(Build) | Projection | Projection | Projection | NotDeclared |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0005` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | No(Build) | Projection | Projection | Projection | NotDeclared |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0006` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | No(Build) | Projection | Projection | Projection | NotDeclared |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0007` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | No(Build) | Projection | Projection | Projection | NotDeclared |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0008` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | No(Build) | Projection | Projection | Projection | NotDeclared |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0009` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | No(Build) | Projection | Projection | Projection | NotDeclared |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI000A` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install.AMDI000A` | No(Build) | Projection | Projection | Projection | NotDeclared |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI000B` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | No(Build) | Projection | Projection | Projection | NotDeclared |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI000C` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | No(Build) | Projection | Projection | Projection | NotDeclared |
| `c0004\amdoemprov.inf` | AMD Provisioning for OEM | `ACPI\AMDI0053` | ACPI-enumerated PnP hardware ID | `AMDPPMPF_DEV` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `c0004\amdpcidev.inf` | AMD PCI | `PCI\VEN_1002&DEV_145A` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_1455` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_145A` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_1485` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_148A` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_14DE` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdpmf.inf` | AMD PMF | `ACPI\AMDI0100` | ACPI-enumerated PnP hardware ID | `AMDPMF_INSTALL.NTamd64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdpmf.inf` | AMD PMF | `ACPI\AMDI0102` | ACPI-enumerated PnP hardware ID | `AMDPMF_INSTALL.NTamd64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdppkg.inf` | AMD Provisioning Packages | `ACPI\AMDI0052` | ACPI-enumerated PnP hardware ID | `InstallSection_Win10` | No(Build) | No(Build) | Native | No | NotDeclared |
| `c0004\amdppkg.inf` | AMD Provisioning Packages | `ACPI\AMDI0052` | ACPI-enumerated PnP hardware ID | `InstallSection_Win11_22H2` | No(Build) | No(Build) | No | Native | NotDeclared |
| `c0004\amdpsp.inf` | AMD PSP 10.0 Device | `PCI\VEN_1022&DEV_15DF` | PCI-enumerated PnP hardware ID | `amdpsp_Device_100` | Native | No | No | No | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP 10.0 Device | `PCI\VEN_1022&DEV_15DF` | PCI-enumerated PnP hardware ID | `amdpsp_Device_100_RS3` | No | Native | Native | Native | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_1134` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | No | No | No | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_1134` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110_RS3` | No | Native | Native | Native | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_115A` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110_RS3` | No | Native | Native | Native | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_115A` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | No | No | No | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_1486` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110_RS3` | No | Native | Native | Native | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_1486` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | No | No | No | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_14CA` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110_RS3` | No | Native | Native | Native | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_14CA` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | No | No | No | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_156E` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110_RS3` | No | Native | Native | Native | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_156E` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | No | No | No | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_15C7` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | No | No | No | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_15C7` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110_RS3` | No | Native | Native | Native | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_1649` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | No | No | No | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_1649` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110_RS3` | No | Native | Native | Native | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_17E0` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110_RS3` | No | Native | Native | Native | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_17E0` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | No | No | No | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_13EC` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | No | No | No | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_13EC` | PCI-enumerated PnP hardware ID | `amdpsp_Device_RS3` | No | Native | Native | Native | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_1456` | PCI-enumerated PnP hardware ID | `amdpsp_Device_RS3` | No | Native | Native | Native | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_1456` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | No | No | No | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_1537` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | No | No | No | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_1537` | PCI-enumerated PnP hardware ID | `amdpsp_Device_RS3` | No | Native | Native | Native | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_1578` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | No | No | No | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_1578` | PCI-enumerated PnP hardware ID | `amdpsp_Device_RS3` | No | Native | Native | Native | KMDF 1.13 |
| `c0004\amdsfhkmdf.inf` | AMD Sensor Fusion Hub | `PCI\VEN_1022&DEV_15E4` | PCI-enumerated PnP hardware ID | `amdsfhkmdf_Device` | Native | Native | Native | Native | KMDF 1.15 |
| `c0004\amdsfhkmdfi2c.inf` | AMD SFH KMDF I2C | `PCI\VEN_1022&DEV_15E6` | PCI-enumerated PnP hardware ID | `amdsfhkmdf_Device` | Native | Native | Native | Native | KMDF 1.15 |
| `c0004\amdsfhspbi2c.inf` | AMD SFH I2C Controller | `ACPI\AMDI0011` | ACPI-enumerated PnP hardware ID | `amdsfhspbi2c_Device` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdsfhumdf.inf` | AMD UMDF Sensor | `ACPI\AMDI0080` | ACPI-enumerated PnP hardware ID | `amdsfhumdf_Inst_Win10` | No(Build) | Native | Native | No | UMDF 2.15.0 |
| `c0004\amdsfhumdf.inf` | AMD UMDF Sensor | `ACPI\AMDI0080` | ACPI-enumerated PnP hardware ID | `amdsfhumdf_Inst_Win11` | No(Build) | No | No | Native | UMDF 2.15.0 |
| `c0004\amduart.inf` | AMD UART Controller | `ACPI\AMD0020` | ACPI-enumerated PnP hardware ID | `amduart_Inst` | No(Build) | Native | Native | Native | NotDeclared |
| `c0004\amduart.inf` | AMD UART Controller | `ACPI\AMDI0020` | ACPI-enumerated PnP hardware ID | `amduart_Inst` | No(Build) | Native | Native | Native | NotDeclared |
| `c0004\amduart.inf` | AMD UART Controller | `ACPI\AMDI0022` | ACPI-enumerated PnP hardware ID | `amduart_Inst` | No(Build) | Native | Native | Native | NotDeclared |
| `c0004\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_15C4` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `c0004\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_15C5` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `c0004\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_162E` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `c0004\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_162F` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `c0004\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_1668` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `c0004\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_1669` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `c0004\amdusb4net.inf` | AMD USB4NET | `{b85b7c50-6a01-11d2-b841-00c04fad5171}\AMDUSB4NET` | Device-class-specific ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdusb4net.inf` | AMD USB4NET | `{b85b7c50-6a01-11d2-b841-00c04fad5171}\Usb4Net` | Device-class-specific ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdusb4net.inf` | AMD USB4NET | `root\AMDUSB4NET_a` | Root-enumerated PnP hardware ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdusb4net.inf` | AMD USB4NET | `root\AMDUSB4NET_b` | Root-enumerated PnP hardware ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdusb4net.inf` | AMD USB4NET | `root\AMDUSB4NET_c` | Root-enumerated PnP hardware ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdusb4net.inf` | AMD USB4NET | `root\AMDUSB4NET_d` | Root-enumerated PnP hardware ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdusb4pcifilter.inf` | PCI Express Root Port | `PCI\VEN_1022&DEV_14CD&SUBSYS_14531022&REV_00` | PCI-enumerated PnP hardware ID | `amdusb4pcifilter` | Native | Native | Excluded | Excluded | NotDeclared |
| `c0004\amdusb4pcifilter.inf` | PCI Express Root Port | `PCI\VEN_1022&DEV_14EF&SUBSYS_14531022&REV_00` | PCI-enumerated PnP hardware ID | `amdusb4pcifilter` | Native | Native | Excluded | Excluded | NotDeclared |
| `c0004\amdusb4pcifilter.inf` | PCI Express Root Port | `PCI\VEN_1022&DEV_14EF&SUBSYS_14531022&REV_01` | PCI-enumerated PnP hardware ID | `amdusb4pcifilter` | Native | Native | Excluded | Excluded | NotDeclared |
| `c0004\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15C0&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Excluded | Excluded | NotDeclared |
| `c0004\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15C1&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Excluded | Excluded | NotDeclared |
| `c0004\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15C2&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Excluded | Excluded | NotDeclared |
| `c0004\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15C3&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Excluded | Excluded | NotDeclared |
| `c0004\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15D6&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Excluded | Excluded | NotDeclared |
| `c0004\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15D7&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Excluded | Excluded | NotDeclared |
| `c0004\amdwirelessbutton.inf` | AMD Wireless Button Driver | `ACPI\AMDI0051` | ACPI-enumerated PnP hardware ID | `amdwirelessbutton_Device` | No(Build) | Native | Native | No | KMDF 1.15 |
| `c0004\amdwirelessbutton.inf` | AMD Wireless Button Driver | `ACPI\AMDI0051` | ACPI-enumerated PnP hardware ID | `amdwirelessbutton_DeviceWin11` | No(Build) | No | No | Native | KMDF 1.15 |
| `c0004\plutonnull.inf` | AMD NULL Driver for Microsoft Pluton Security Processor | `ACPI\MSFT0200` | ACPI-enumerated PnP hardware ID | `Null_Pluton_Device` | Native | Native | Native | Excluded | NotDeclared |
| `c0004\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4353` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `c0004\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4363` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `c0004\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4372` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `c0004\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4385` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `c0004\smbusamd.inf` | AMD SMBus | `PCI\VEN_1022&DEV_780B` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `c0004\smbusamd.inf` | AMD SMBus | `PCI\VEN_1022&DEV_790B` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `c0004\usbfilter.inf` | AMD USB Filter Driver | `{36FC9E60-C465-11CF-8056-444553540000}\usbfilter` | Device-class-specific ID | `usbfilter` | Native | Native | Native | Native | NotDeclared |

## AMD Chipset Software 7.11.26.2142

| INF | Device | Device identifier | Identifier type | Install section | WS2016 | WS2019 | WS2022 | WS2025 | WDF |
|---|---|---|---|---|---|---|---|---|---|
| `c0004\amd3dvcache.inf` | AMD 3D V-Cache Performance Optimizer | `ACPI\AMDI0101` | ACPI-enumerated PnP hardware ID | `Amd3dvcache_Device` | No(Build) | No(Build) | Native | Native | KMDF 1.15 |
| `c0004\amdappcompat.inf` | AMD Application Compatibility Database | `ACPI\AMDI0204` | ACPI-enumerated PnP hardware ID | `AmdAppCompat_Device` | No(Build) | Native | Native | Native | KMDF 1.15 |
| `c0004\amdas4.inf` | AmdAS4 Device | `ACPI\AMDI0050` | ACPI-enumerated PnP hardware ID | `AmdAS4` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdas4.inf` | AmdAS4 Device | `ACPI\ASD0001` | ACPI-enumerated PnP hardware ID | `AmdAS4` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdcir.inf` | AMD CIR Driver | `*AMDC001` | Generic PnP hardware ID | `AMDCIR64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdcir.inf` | AMD CIR Driver | `*AMDC002` | Generic PnP hardware ID | `AMDCIR64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdcir.inf` | AMD CIR Driver | `*AMDC003` | Generic PnP hardware ID | `AMDCIR64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdgpio2.inf` | AMD GPIO Controller | `ACPI\AMD0030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdgpio2.inf` | AMD GPIO Controller | `ACPI\AMDI0030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdgpio2.inf` | AMD GPIO Controller | `ACPI\AMDI0031` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdgpio2.inf` | AMD GPIO Controller | `ACPI\GPIO0010` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdgpio3.inf` | AMD GPIO Controller | `ACPI\AMDF030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdgpio3.inf` | AMD GPIO Controller | `ACPI\AMDIF030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdgpio3.inf` | AMD GPIO Controller | `ACPI\AMDIF031` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdhsmpdriver.inf` | AMD Host System Management Port | `ACPI\AMD0097` | ACPI-enumerated PnP hardware ID | `AmdHsmpDriver_Device` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdhsmpdriver.inf` | AMD Host System Management Port | `ACPI\AMDI0097` | ACPI-enumerated PnP hardware ID | `AmdHsmpDriver_Device` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdhsmpdriver.inf` | AMD Host System Management Port | `PCI\VEN_1022&DEV_14A4` | PCI-enumerated PnP hardware ID | `AmdHsmpDriver_Device` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdi2c.inf` | AMD I2C Controller | `ACPI\AMD0010` | ACPI-enumerated PnP hardware ID | `amdi2c_Device` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdi2c.inf` | AMD I2C Controller | `ACPI\AMDI0010` | ACPI-enumerated PnP hardware ID | `amdi2c_Device` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdinterface.inf` | AMD Hetero Driver | `ACPI\AMDI0104` | ACPI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdinterface.inf` | AMD PCI | `PCI\VEN_1002&DEV_145A` | PCI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_1116` | PCI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_1117` | PCI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_1136` | PCI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_1137` | PCI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_14AC` | PCI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_14DC` | PCI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_14DE` | PCI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_14EC` | PCI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_150D` | PCI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_1556` | PCI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdinterface.inf` | AMD SMBUS | `PCI\VEN_1022&DEV_790B` | PCI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1002&DEV_5A23` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_13E1` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1419` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1423` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1437` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1451` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1481` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1577` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_164F` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMD0004` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | No(Build) | Projection | Projection | Projection | NotDeclared |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMD0005` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | No(Build) | Projection | Projection | Projection | NotDeclared |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0005` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | No(Build) | Projection | Projection | Projection | NotDeclared |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0006` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | No(Build) | Projection | Projection | Projection | NotDeclared |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0007` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | No(Build) | Projection | Projection | Projection | NotDeclared |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0008` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | No(Build) | Projection | Projection | Projection | NotDeclared |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0009` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | No(Build) | Projection | Projection | Projection | NotDeclared |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI000A` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | No(Build) | Projection | Projection | Projection | NotDeclared |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI000B` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | No(Build) | Projection | Projection | Projection | NotDeclared |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI000C` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | No(Build) | Projection | Projection | Projection | NotDeclared |
| `c0004\amdoemprov.inf` | AMD Provisioning for OEM | `ACPI\AMDI0053` | ACPI-enumerated PnP hardware ID | `AMDPPMPF_DEV` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `c0004\amdpcidev.inf` | AMD PCI | `PCI\VEN_1002&DEV_145A` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_1455` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_145A` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_1485` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_148A` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_14DE` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdpmf.inf` | AMD PMF | `ACPI\AMDI0100` | ACPI-enumerated PnP hardware ID | `AMDPMF_INSTALL.NTamd64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdpmf.inf` | AMD PMF | `ACPI\AMDI0102` | ACPI-enumerated PnP hardware ID | `AMDPMF_INSTALL.NTamd64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdppkg.inf` | AMD Provisioning Packages | `ACPI\AMDI0052` | ACPI-enumerated PnP hardware ID | `InstallSection_Win10` | No(Build) | No(Build) | Native | No | NotDeclared |
| `c0004\amdppkg.inf` | AMD Provisioning Packages | `ACPI\AMDI0052` | ACPI-enumerated PnP hardware ID | `InstallSection_Win11_22H2` | No(Build) | No(Build) | No | Native | NotDeclared |
| `c0004\amdpsp.inf` | AMD PSP 10.0 Device | `PCI\VEN_1022&DEV_15DF` | PCI-enumerated PnP hardware ID | `amdpsp_Device_100` | Native | No | No | No | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP 10.0 Device | `PCI\VEN_1022&DEV_15DF` | PCI-enumerated PnP hardware ID | `amdpsp_Device_100_RS3` | No | Native | Native | Native | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_1134` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | No | No | No | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_1134` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110_RS3` | No | Native | Native | Native | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_115A` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110_RS3` | No | Native | Native | Native | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_115A` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | No | No | No | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_1486` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110_RS3` | No | Native | Native | Native | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_1486` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | No | No | No | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_14CA` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110_RS3` | No | Native | Native | Native | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_14CA` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | No | No | No | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_156E` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110_RS3` | No | Native | Native | Native | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_156E` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | No | No | No | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_15C7` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | No | No | No | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_15C7` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110_RS3` | No | Native | Native | Native | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_1649` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | No | No | No | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_1649` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110_RS3` | No | Native | Native | Native | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_17E0` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110_RS3` | No | Native | Native | Native | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_17E0` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | No | No | No | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_13EC` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | No | No | No | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_13EC` | PCI-enumerated PnP hardware ID | `amdpsp_Device_RS3` | No | Native | Native | Native | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_1456` | PCI-enumerated PnP hardware ID | `amdpsp_Device_RS3` | No | Native | Native | Native | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_1456` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | No | No | No | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_1537` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | No | No | No | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_1537` | PCI-enumerated PnP hardware ID | `amdpsp_Device_RS3` | No | Native | Native | Native | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_1578` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | No | No | No | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_1578` | PCI-enumerated PnP hardware ID | `amdpsp_Device_RS3` | No | Native | Native | Native | KMDF 1.13 |
| `c0004\amdsfhkmdf.inf` | AMD Sensor Fusion Hub | `PCI\VEN_1022&DEV_15E4` | PCI-enumerated PnP hardware ID | `amdsfhkmdf_Device` | Native | Native | Native | Native | KMDF 1.15 |
| `c0004\amdsfhkmdfi2c.inf` | AMD SFH KMDF I2C | `PCI\VEN_1022&DEV_15E6` | PCI-enumerated PnP hardware ID | `amdsfhkmdf_Device` | Native | Native | Native | Native | KMDF 1.15 |
| `c0004\amdsfhspbi2c.inf` | AMD SFH I2C Controller | `ACPI\AMDI0011` | ACPI-enumerated PnP hardware ID | `amdsfhspbi2c_Device` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdsfhumdf.inf` | AMD UMDF Sensor | `ACPI\AMDI0080` | ACPI-enumerated PnP hardware ID | `amdsfhumdf_Inst_Win10` | No(Build) | Native | Native | No | UMDF 2.15.0 |
| `c0004\amdsfhumdf.inf` | AMD UMDF Sensor | `ACPI\AMDI0080` | ACPI-enumerated PnP hardware ID | `amdsfhumdf_Inst_Win11` | No(Build) | No | No | Native | UMDF 2.15.0 |
| `c0004\amduart.inf` | AMD UART Controller | `ACPI\AMD0020` | ACPI-enumerated PnP hardware ID | `amduart_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amduart.inf` | AMD UART Controller | `ACPI\AMDI0020` | ACPI-enumerated PnP hardware ID | `amduart_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amduart.inf` | AMD UART Controller | `ACPI\AMDI0022` | ACPI-enumerated PnP hardware ID | `amduart_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_15C4` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `c0004\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_15C5` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `c0004\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_162E` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `c0004\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_162F` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `c0004\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_1668` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `c0004\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_1669` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `c0004\amdusb4net.inf` | AMD USB4NET | `{b85b7c50-6a01-11d2-b841-00c04fad5171}\AMDUSB4NET` | Device-class-specific ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdusb4net.inf` | AMD USB4NET | `{b85b7c50-6a01-11d2-b841-00c04fad5171}\Usb4Net` | Device-class-specific ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdusb4net.inf` | AMD USB4NET | `root\AMDUSB4NET_a` | Root-enumerated PnP hardware ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdusb4net.inf` | AMD USB4NET | `root\AMDUSB4NET_b` | Root-enumerated PnP hardware ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdusb4net.inf` | AMD USB4NET | `root\AMDUSB4NET_c` | Root-enumerated PnP hardware ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdusb4net.inf` | AMD USB4NET | `root\AMDUSB4NET_d` | Root-enumerated PnP hardware ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdusb4pcifilter.inf` | PCI Express Root Port | `PCI\VEN_1022&DEV_14CD&SUBSYS_14531022&REV_00` | PCI-enumerated PnP hardware ID | `amdusb4pcifilter` | Native | Native | Excluded | Excluded | NotDeclared |
| `c0004\amdusb4pcifilter.inf` | PCI Express Root Port | `PCI\VEN_1022&DEV_14EF&SUBSYS_14531022&REV_00` | PCI-enumerated PnP hardware ID | `amdusb4pcifilter` | Native | Native | Excluded | Excluded | NotDeclared |
| `c0004\amdusb4pcifilter.inf` | PCI Express Root Port | `PCI\VEN_1022&DEV_14EF&SUBSYS_14531022&REV_01` | PCI-enumerated PnP hardware ID | `amdusb4pcifilter` | Native | Native | Excluded | Excluded | NotDeclared |
| `c0004\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15C0&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Excluded | Excluded | NotDeclared |
| `c0004\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15C1&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Excluded | Excluded | NotDeclared |
| `c0004\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15C2&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Excluded | Excluded | NotDeclared |
| `c0004\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15C3&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Excluded | Excluded | NotDeclared |
| `c0004\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15D6&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Excluded | Excluded | NotDeclared |
| `c0004\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15D7&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Excluded | Excluded | NotDeclared |
| `c0004\amdwirelessbutton.inf` | AMD Wireless Button Driver | `ACPI\AMDI0051` | ACPI-enumerated PnP hardware ID | `amdwirelessbutton_Device` | No(Build) | Native | Native | No | KMDF 1.15 |
| `c0004\amdwirelessbutton.inf` | AMD Wireless Button Driver | `ACPI\AMDI0051` | ACPI-enumerated PnP hardware ID | `amdwirelessbutton_DeviceWin11` | No(Build) | No | No | Native | KMDF 1.15 |
| `c0004\ams_mailboxdrv.inf` | AMS-MailBoxDrv | `ACPI\AMDI0090` | ACPI-enumerated PnP hardware ID | `AMS-MailBoxDrv_Device` | Native | Native | Native | Native | NotDeclared |
| `c0004\plutonnull.inf` | AMD NULL Driver for Microsoft Pluton Security Processor | `ACPI\MSFT0200` | ACPI-enumerated PnP hardware ID | `Null_Pluton_Device` | Native | Native | Native | Excluded | NotDeclared |
| `c0004\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4353` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `c0004\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4363` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `c0004\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4372` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `c0004\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4385` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `c0004\smbusamd.inf` | AMD SMBus | `PCI\VEN_1022&DEV_780B` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `c0004\smbusamd.inf` | AMD SMBus | `PCI\VEN_1022&DEV_790B` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `c0004\usbfilter.inf` | AMD USB Filter Driver | `{36FC9E60-C465-11CF-8056-444553540000}\usbfilter` | Device-class-specific ID | `usbfilter` | Native | Native | Native | Native | NotDeclared |
| `c0004\zenpromnf.inf` | ZenProM S0i3 Network Filter | `ZenProMnf` | Network software component ID | `Install` | Native | Native | Native | Native | NotDeclared |

## AMD Chipset Software 7.06.02.123

| INF | Device | Device identifier | Identifier type | Install section | WS2016 | WS2019 | WS2022 | WS2025 | WDF |
|---|---|---|---|---|---|---|---|---|---|
| `c0004\amd3dvcache.inf` | AMD 3D V-Cache Performance Optimizer | `ACPI\AMDI0101` | ACPI-enumerated PnP hardware ID | `Amd3dvcache_Device` | No(Build) | No(Build) | Native | Native | KMDF 1.15 |
| `c0004\amdappcompat.inf` | AMD Application Compatibility Database | `ACPI\AMDI0204` | ACPI-enumerated PnP hardware ID | `AmdAppCompat_Device` | No(Build) | Native | Native | Native | KMDF 1.15 |
| `c0004\amdas4.inf` | AmdAS4 Device | `ACPI\AMDI0050` | ACPI-enumerated PnP hardware ID | `AmdAS4` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdas4.inf` | AmdAS4 Device | `ACPI\ASD0001` | ACPI-enumerated PnP hardware ID | `AmdAS4` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdcir.inf` | AMD CIR Driver | `*AMDC001` | Generic PnP hardware ID | `AMDCIR64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdcir.inf` | AMD CIR Driver | `*AMDC002` | Generic PnP hardware ID | `AMDCIR64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdcir.inf` | AMD CIR Driver | `*AMDC003` | Generic PnP hardware ID | `AMDCIR64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdgpio2.inf` | AMD GPIO Controller | `ACPI\AMD0030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdgpio2.inf` | AMD GPIO Controller | `ACPI\AMDI0030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdgpio2.inf` | AMD GPIO Controller | `ACPI\AMDI0031` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdgpio2.inf` | AMD GPIO Controller | `ACPI\GPIO0010` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdgpio3.inf` | AMD GPIO Controller | `ACPI\AMDF030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdgpio3.inf` | AMD GPIO Controller | `ACPI\AMDIF030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdgpio3.inf` | AMD GPIO Controller | `ACPI\AMDIF031` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdi2c.inf` | AMD I2C Controller | `ACPI\AMD0010` | ACPI-enumerated PnP hardware ID | `amdi2c_Device` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdi2c.inf` | AMD I2C Controller | `ACPI\AMDI0010` | ACPI-enumerated PnP hardware ID | `amdi2c_Device` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdinterface.inf` | AMD Hetero Driver | `ACPI\AMDI0104` | ACPI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdinterface.inf` | AMD PCI | `PCI\VEN_1002&DEV_145A` | PCI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_1116` | PCI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_1117` | PCI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_1136` | PCI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_1137` | PCI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_14AC` | PCI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_14DC` | PCI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_14DE` | PCI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_14EC` | PCI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_150D` | PCI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_1556` | PCI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdinterface.inf` | AMD SMBUS | `PCI\VEN_1022&DEV_790B` | PCI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1002&DEV_5A23` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_13E1` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1419` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1423` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1437` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1451` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1481` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1577` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_164F` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMD0004` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMD0005` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0005` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0006` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0007` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0008` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0009` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI000A` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI000B` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdoemprov.inf` | AMD Provisioning for OEM | `ACPI\AMDI0053` | ACPI-enumerated PnP hardware ID | `AMDPPMPF_DEV` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `c0004\amdpcidev.inf` | AMD PCI | `PCI\VEN_1002&DEV_145A` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_1455` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_145A` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_1485` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_148A` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_14DE` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdpmf.inf` | AMD PMF | `ACPI\AMDI0100` | ACPI-enumerated PnP hardware ID | `AMDPMF_INSTALL.NTamd64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdpmf.inf` | AMD PMF | `ACPI\AMDI0102` | ACPI-enumerated PnP hardware ID | `AMDPMF_INSTALL.NTamd64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdppkg.inf` | AMD Provisioning Packages | `ACPI\AMDI0052` | ACPI-enumerated PnP hardware ID | `InstallSection_Win10` | Native | Native | Native | No | NotDeclared |
| `c0004\amdppkg.inf` | AMD Provisioning Packages | `ACPI\AMDI0052` | ACPI-enumerated PnP hardware ID | `InstallSection_Win11_22H2` | No | No | No | Native | NotDeclared |
| `c0004\amdpsp.inf` | AMD PSP 10.0 Device | `PCI\VEN_1022&DEV_15DF` | PCI-enumerated PnP hardware ID | `amdpsp_Device_100` | Native | Native | Native | Native | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_1134` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | Native | Native | Native | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_1486` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | Native | Native | Native | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_14CA` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | Native | Native | Native | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_156E` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | Native | Native | Native | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_15C7` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | Native | Native | Native | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_1649` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | Native | Native | Native | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_17E0` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | Native | Native | Native | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_13EC` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | Native | Native | Native | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_1456` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | Native | Native | Native | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_1537` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | Native | Native | Native | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_1578` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | Native | Native | Native | KMDF 1.13 |
| `c0004\amdsfhkmdf.inf` | AMD Sensor Fusion Hub | `PCI\VEN_1022&DEV_15E4` | PCI-enumerated PnP hardware ID | `amdsfhkmdf_Device` | Native | Native | Native | Native | KMDF 1.15 |
| `c0004\amdsfhkmdfi2c.inf` | AMD SFH KMDF I2C | `PCI\VEN_1022&DEV_15E6` | PCI-enumerated PnP hardware ID | `amdsfhkmdf_Device` | Native | Native | Native | Native | KMDF 1.15 |
| `c0004\amdsfhspbi2c.inf` | AMD SFH I2C Controller | `ACPI\AMDI0011` | ACPI-enumerated PnP hardware ID | `amdsfhspbi2c_Device` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdsfhumdf.inf` | AMD UMDF Sensor | `ACPI\AMDI0080` | ACPI-enumerated PnP hardware ID | `amdsfhumdf_Inst_Win10` | No(Build) | Native | Native | No | UMDF 2.15.0 |
| `c0004\amdsfhumdf.inf` | AMD UMDF Sensor | `ACPI\AMDI0080` | ACPI-enumerated PnP hardware ID | `amdsfhumdf_Inst_Win11` | No(Build) | No | No | Native | UMDF 2.15.0 |
| `c0004\amduart.inf` | AMD UART Controller | `ACPI\AMD0020` | ACPI-enumerated PnP hardware ID | `amduart_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amduart.inf` | AMD UART Controller | `ACPI\AMDI0020` | ACPI-enumerated PnP hardware ID | `amduart_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amduart.inf` | AMD UART Controller | `ACPI\AMDI0022` | ACPI-enumerated PnP hardware ID | `amduart_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_15C4` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `c0004\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_15C5` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `c0004\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_162E` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `c0004\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_162F` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `c0004\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_1668` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `c0004\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_1669` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `c0004\amdusb4net.inf` | AMD USB4NET | `{b85b7c50-6a01-11d2-b841-00c04fad5171}\AMDUSB4NET` | Device-class-specific ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdusb4net.inf` | AMD USB4NET | `{b85b7c50-6a01-11d2-b841-00c04fad5171}\Usb4Net` | Device-class-specific ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdusb4net.inf` | AMD USB4NET | `root\AMDUSB4NET_a` | Root-enumerated PnP hardware ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdusb4net.inf` | AMD USB4NET | `root\AMDUSB4NET_b` | Root-enumerated PnP hardware ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdusb4net.inf` | AMD USB4NET | `root\AMDUSB4NET_c` | Root-enumerated PnP hardware ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdusb4net.inf` | AMD USB4NET | `root\AMDUSB4NET_d` | Root-enumerated PnP hardware ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdusb4pcifilter.inf` | PCI Express Root Port | `PCI\VEN_1022&DEV_14CD&SUBSYS_14531022&REV_00` | PCI-enumerated PnP hardware ID | `amdusb4pcifilter` | Native | Native | Excluded | Excluded | NotDeclared |
| `c0004\amdusb4pcifilter.inf` | PCI Express Root Port | `PCI\VEN_1022&DEV_14EF&SUBSYS_14531022&REV_00` | PCI-enumerated PnP hardware ID | `amdusb4pcifilter` | Native | Native | Excluded | Excluded | NotDeclared |
| `c0004\amdusb4pcifilter.inf` | PCI Express Root Port | `PCI\VEN_1022&DEV_14EF&SUBSYS_14531022&REV_01` | PCI-enumerated PnP hardware ID | `amdusb4pcifilter` | Native | Native | Excluded | Excluded | NotDeclared |
| `c0004\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15C0&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Excluded | Excluded | NotDeclared |
| `c0004\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15C1&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Excluded | Excluded | NotDeclared |
| `c0004\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15C2&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Excluded | Excluded | NotDeclared |
| `c0004\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15C3&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Excluded | Excluded | NotDeclared |
| `c0004\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15D6&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Excluded | Excluded | NotDeclared |
| `c0004\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15D7&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Excluded | Excluded | NotDeclared |
| `c0004\amdwirelessbutton.inf` | AMD Wireless Button Driver | `ACPI\AMDI0051` | ACPI-enumerated PnP hardware ID | `amdwirelessbutton_Device` | No(Build) | Native | Native | No | KMDF 1.15 |
| `c0004\amdwirelessbutton.inf` | AMD Wireless Button Driver | `ACPI\AMDI0051` | ACPI-enumerated PnP hardware ID | `amdwirelessbutton_DeviceWin11` | No(Build) | No | No | Native | KMDF 1.15 |
| `c0004\ams_mailboxdrv.inf` | AMS-MailBoxDrv | `ACPI\AMDI0090` | ACPI-enumerated PnP hardware ID | `AMS-MailBoxDrv_Device` | Native | Native | Native | Native | NotDeclared |
| `c0004\plutonnull.inf` | AMD NULL Driver for Microsoft Pluton Security Processor | `ACPI\MSFT0200` | ACPI-enumerated PnP hardware ID | `Null_Pluton_Device` | Native | Native | Native | Excluded | NotDeclared |
| `c0004\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4353` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `c0004\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4363` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `c0004\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4372` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `c0004\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4385` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `c0004\smbusamd.inf` | AMD SMBus | `PCI\VEN_1022&DEV_780B` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `c0004\smbusamd.inf` | AMD SMBus | `PCI\VEN_1022&DEV_790B` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `c0004\usbfilter.inf` | AMD USB Filter Driver | `{36FC9E60-C465-11CF-8056-444553540000}\usbfilter` | Device-class-specific ID | `usbfilter` | Native | Native | Native | Native | NotDeclared |
| `c0004\zenpromnf.inf` | ZenProM S0i3 Network Filter | `ZenProMnf` | Network software component ID | `Install` | Native | Native | Native | Native | NotDeclared |

## AMD Chipset Software 7.04.09.545

| INF | Device | Device identifier | Identifier type | Install section | WS2016 | WS2019 | WS2022 | WS2025 | WDF |
|---|---|---|---|---|---|---|---|---|---|
| `c0004\amd3dvcache.inf` | AMD 3D V-Cache Performance Optimizer | `ACPI\AMDI0101` | ACPI-enumerated PnP hardware ID | `Amd3dvcache_Device` | No(Build) | No(Build) | Native | Native | KMDF 1.15 |
| `c0004\amdappcompat.inf` | AMD Application Compatibility Database | `ACPI\AMDI0204` | ACPI-enumerated PnP hardware ID | `AmdAppCompat_Device` | No(Build) | Native | Native | Native | KMDF 1.15 |
| `c0004\amdas4.inf` | AmdAS4 Device | `ACPI\AMDI0050` | ACPI-enumerated PnP hardware ID | `AmdAS4` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdas4.inf` | AmdAS4 Device | `ACPI\ASD0001` | ACPI-enumerated PnP hardware ID | `AmdAS4` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdcir.inf` | AMD CIR Driver | `*AMDC001` | Generic PnP hardware ID | `AMDCIR64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdcir.inf` | AMD CIR Driver | `*AMDC002` | Generic PnP hardware ID | `AMDCIR64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdcir.inf` | AMD CIR Driver | `*AMDC003` | Generic PnP hardware ID | `AMDCIR64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdgpio2.inf` | AMD GPIO Controller | `ACPI\AMD0030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdgpio2.inf` | AMD GPIO Controller | `ACPI\AMDI0030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdgpio2.inf` | AMD GPIO Controller | `ACPI\AMDI0031` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdgpio2.inf` | AMD GPIO Controller | `ACPI\GPIO0010` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdgpio3.inf` | AMD GPIO Controller | `ACPI\AMDF030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdgpio3.inf` | AMD GPIO Controller | `ACPI\AMDIF030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdgpio3.inf` | AMD GPIO Controller | `ACPI\AMDIF031` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdi2c.inf` | AMD I2C Controller | `ACPI\AMD0010` | ACPI-enumerated PnP hardware ID | `amdi2c_Device` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdi2c.inf` | AMD I2C Controller | `ACPI\AMDI0010` | ACPI-enumerated PnP hardware ID | `amdi2c_Device` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdinterface.inf` | AMD Hetero Driver | `ACPI\AMDI0104` | ACPI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdinterface.inf` | AMD PCI | `PCI\VEN_1002&DEV_145A` | PCI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_1116` | PCI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_1117` | PCI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_1136` | PCI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_1137` | PCI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_14AC` | PCI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_14DC` | PCI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_14DE` | PCI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_14EC` | PCI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_150D` | PCI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_1556` | PCI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdinterface.inf` | AMD SMBUS | `PCI\VEN_1022&DEV_790B` | PCI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1002&DEV_5A23` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_13E1` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1419` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1423` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1437` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1451` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1481` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1577` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_164F` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMD0004` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMD0005` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0005` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0006` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0007` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0008` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0009` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI000A` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI000B` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdoemprov.inf` | AMD Provisioning for OEM | `ACPI\AMDI0053` | ACPI-enumerated PnP hardware ID | `AMDPPMPF_DEV` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `c0004\amdpcidev.inf` | AMD PCI | `PCI\VEN_1002&DEV_145A` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_1455` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_145A` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_1485` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_148A` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_14DE` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdpmf.inf` | AMD PMF | `ACPI\AMDI0100` | ACPI-enumerated PnP hardware ID | `AMDPMF_INSTALL.NTamd64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdpmf.inf` | AMD PMF | `ACPI\AMDI0102` | ACPI-enumerated PnP hardware ID | `AMDPMF_INSTALL.NTamd64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdppkg.inf` | AMD Provisioning Packages | `ACPI\AMDI0052` | ACPI-enumerated PnP hardware ID | `InstallSection_Win10` | Native | Native | Native | No | NotDeclared |
| `c0004\amdppkg.inf` | AMD Provisioning Packages | `ACPI\AMDI0052` | ACPI-enumerated PnP hardware ID | `InstallSection_Win11_22H2` | No | No | No | Native | NotDeclared |
| `c0004\amdpsp.inf` | AMD PSP 10.0 Device | `PCI\VEN_1022&DEV_15DF` | PCI-enumerated PnP hardware ID | `amdpsp_Device_100` | Native | Native | Native | Native | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_1134` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | Native | Native | Native | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_1486` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | Native | Native | Native | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_14CA` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | Native | Native | Native | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_156E` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | Native | Native | Native | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_15C7` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | Native | Native | Native | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_1649` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | Native | Native | Native | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_17E0` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | Native | Native | Native | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_13EC` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | Native | Native | Native | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_1456` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | Native | Native | Native | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_1537` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | Native | Native | Native | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_1578` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | Native | Native | Native | KMDF 1.13 |
| `c0004\amdsfhkmdf.inf` | AMD Sensor Fusion Hub | `PCI\VEN_1022&DEV_15E4` | PCI-enumerated PnP hardware ID | `amdsfhkmdf_Device` | Native | Native | Native | Native | KMDF 1.15 |
| `c0004\amdsfhkmdfi2c.inf` | AMD SFH KMDF I2C | `PCI\VEN_1022&DEV_15E6` | PCI-enumerated PnP hardware ID | `amdsfhkmdf_Device` | Native | Native | Native | Native | KMDF 1.15 |
| `c0004\amdsfhspbi2c.inf` | AMD SFH I2C Controller | `ACPI\AMDI0011` | ACPI-enumerated PnP hardware ID | `amdsfhspbi2c_Device` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdsfhumdf.inf` | AMD UMDF Sensor | `ACPI\AMDI0080` | ACPI-enumerated PnP hardware ID | `amdsfhumdf_Inst_Win10` | No(Build) | Native | Native | No | UMDF 2.15.0 |
| `c0004\amdsfhumdf.inf` | AMD UMDF Sensor | `ACPI\AMDI0080` | ACPI-enumerated PnP hardware ID | `amdsfhumdf_Inst_Win11` | No(Build) | No | No | Native | UMDF 2.15.0 |
| `c0004\amduart.inf` | AMD UART Controller | `ACPI\AMD0020` | ACPI-enumerated PnP hardware ID | `amduart_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amduart.inf` | AMD UART Controller | `ACPI\AMDI0020` | ACPI-enumerated PnP hardware ID | `amduart_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amduart.inf` | AMD UART Controller | `ACPI\AMDI0022` | ACPI-enumerated PnP hardware ID | `amduart_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_15C4` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `c0004\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_15C5` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `c0004\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_162E` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `c0004\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_162F` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `c0004\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_1668` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `c0004\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_1669` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `c0004\amdusb4net.inf` | AMD USB4NET | `{b85b7c50-6a01-11d2-b841-00c04fad5171}\AMDUSB4NET` | Device-class-specific ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdusb4net.inf` | AMD USB4NET | `{b85b7c50-6a01-11d2-b841-00c04fad5171}\Usb4Net` | Device-class-specific ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdusb4net.inf` | AMD USB4NET | `root\AMDUSB4NET_a` | Root-enumerated PnP hardware ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdusb4net.inf` | AMD USB4NET | `root\AMDUSB4NET_b` | Root-enumerated PnP hardware ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdusb4net.inf` | AMD USB4NET | `root\AMDUSB4NET_c` | Root-enumerated PnP hardware ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdusb4net.inf` | AMD USB4NET | `root\AMDUSB4NET_d` | Root-enumerated PnP hardware ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdusb4pcifilter.inf` | PCI Express Root Port | `PCI\VEN_1022&DEV_14CD&SUBSYS_14531022&REV_00` | PCI-enumerated PnP hardware ID | `amdusb4pcifilter` | Native | Native | Excluded | Excluded | NotDeclared |
| `c0004\amdusb4pcifilter.inf` | PCI Express Root Port | `PCI\VEN_1022&DEV_14EF&SUBSYS_14531022&REV_00` | PCI-enumerated PnP hardware ID | `amdusb4pcifilter` | Native | Native | Excluded | Excluded | NotDeclared |
| `c0004\amdusb4pcifilter.inf` | PCI Express Root Port | `PCI\VEN_1022&DEV_14EF&SUBSYS_14531022&REV_01` | PCI-enumerated PnP hardware ID | `amdusb4pcifilter` | Native | Native | Excluded | Excluded | NotDeclared |
| `c0004\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15C0&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Excluded | Excluded | NotDeclared |
| `c0004\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15C1&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Excluded | Excluded | NotDeclared |
| `c0004\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15C2&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Excluded | Excluded | NotDeclared |
| `c0004\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15C3&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Excluded | Excluded | NotDeclared |
| `c0004\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15D6&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Excluded | Excluded | NotDeclared |
| `c0004\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15D7&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Excluded | Excluded | NotDeclared |
| `c0004\amdwirelessbutton.inf` | AMD Wireless Button Driver | `ACPI\AMDI0051` | ACPI-enumerated PnP hardware ID | `amdwirelessbutton_Device` | No(Build) | Native | Native | No | KMDF 1.15 |
| `c0004\amdwirelessbutton.inf` | AMD Wireless Button Driver | `ACPI\AMDI0051` | ACPI-enumerated PnP hardware ID | `amdwirelessbutton_DeviceWin11` | No(Build) | No | No | Native | KMDF 1.15 |
| `c0004\ams_mailboxdrv.inf` | AMS-MailBoxDrv | `ACPI\AMDI0090` | ACPI-enumerated PnP hardware ID | `AMS-MailBoxDrv_Device` | Native | Native | Native | Native | NotDeclared |
| `c0004\plutonnull.inf` | AMD NULL Driver for Microsoft Pluton Security Processor | `ACPI\MSFT0200` | ACPI-enumerated PnP hardware ID | `Null_Pluton_Device` | Native | Native | Native | Excluded | NotDeclared |
| `c0004\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4353` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `c0004\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4363` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `c0004\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4372` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `c0004\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4385` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `c0004\smbusamd.inf` | AMD SMBus | `PCI\VEN_1022&DEV_780B` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `c0004\smbusamd.inf` | AMD SMBus | `PCI\VEN_1022&DEV_790B` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `c0004\usbfilter.inf` | AMD USB Filter Driver | `{36FC9E60-C465-11CF-8056-444553540000}\usbfilter` | Device-class-specific ID | `usbfilter` | Native | Native | Native | Native | NotDeclared |
| `c0004\zenpromnf.inf` | ZenProM S0i3 Network Filter | `ZenProMnf` | Network software component ID | `Install` | Native | Native | Native | Native | NotDeclared |

## AMD Chipset Software 7.02.13.148

| INF | Device | Device identifier | Identifier type | Install section | WS2016 | WS2019 | WS2022 | WS2025 | WDF |
|---|---|---|---|---|---|---|---|---|---|
| `c0004\amd3dvcache.inf` | AMD 3D V-Cache Performance Optimizer | `ACPI\AMDI0101` | ACPI-enumerated PnP hardware ID | `Amd3dvcache_Device` | No(Build) | No(Build) | Native | Native | KMDF 1.15 |
| `c0004\amdappcompat.inf` | AMD Application Compatibility Database | `ACPI\AMDI0204` | ACPI-enumerated PnP hardware ID | `AmdAppCompat_Device` | No(Build) | Native | Native | Native | KMDF 1.15 |
| `c0004\amdas4.inf` | AmdAS4 Device | `ACPI\AMDI0050` | ACPI-enumerated PnP hardware ID | `AmdAS4` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdas4.inf` | AmdAS4 Device | `ACPI\ASD0001` | ACPI-enumerated PnP hardware ID | `AmdAS4` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdcir.inf` | AMD CIR Driver | `*AMDC001` | Generic PnP hardware ID | `AMDCIR64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdcir.inf` | AMD CIR Driver | `*AMDC002` | Generic PnP hardware ID | `AMDCIR64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdcir.inf` | AMD CIR Driver | `*AMDC003` | Generic PnP hardware ID | `AMDCIR64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdgpio2.inf` | AMD GPIO Controller | `ACPI\AMD0030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdgpio2.inf` | AMD GPIO Controller | `ACPI\AMDI0030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdgpio2.inf` | AMD GPIO Controller | `ACPI\AMDI0031` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdgpio2.inf` | AMD GPIO Controller | `ACPI\GPIO0010` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdgpio3.inf` | AMD GPIO Controller | `ACPI\AMDF030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdgpio3.inf` | AMD GPIO Controller | `ACPI\AMDIF030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdgpio3.inf` | AMD GPIO Controller | `ACPI\AMDIF031` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdi2c.inf` | AMD I2C Controller | `ACPI\AMD0010` | ACPI-enumerated PnP hardware ID | `amdi2c_Device` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdi2c.inf` | AMD I2C Controller | `ACPI\AMDI0010` | ACPI-enumerated PnP hardware ID | `amdi2c_Device` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdinterface.inf` | AMD Hetero Driver | `ACPI\AMDI0104` | ACPI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdinterface.inf` | AMD PCI | `PCI\VEN_1002&DEV_145A` | PCI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_1116` | PCI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_1117` | PCI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_1136` | PCI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_14AC` | PCI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_14DC` | PCI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_14DE` | PCI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_14EC` | PCI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_150D` | PCI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_1556` | PCI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdinterface.inf` | AMD SMBUS | `PCI\VEN_1022&DEV_790B` | PCI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1002&DEV_5A23` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_13E1` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1419` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1423` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1437` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1451` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1481` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1577` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_164F` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMD0004` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMD0005` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0005` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0006` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0007` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0008` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0009` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI000A` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI000B` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdoemprov.inf` | AMD Provisioning for OEM | `ACPI\AMDI0053` | ACPI-enumerated PnP hardware ID | `AMDPPMPF_DEV` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `c0004\amdpcidev.inf` | AMD PCI | `PCI\VEN_1002&DEV_145A` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_1455` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_145A` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_1485` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_148A` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_14DE` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdpmf.inf` | AMD PMF | `ACPI\AMDI0100` | ACPI-enumerated PnP hardware ID | `AMDPMF_INSTALL.NTamd64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdpmf.inf` | AMD PMF | `ACPI\AMDI0102` | ACPI-enumerated PnP hardware ID | `AMDPMF_INSTALL.NTamd64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdppkg.inf` | AMD Provisioning Packages | `ACPI\AMDI0052` | ACPI-enumerated PnP hardware ID | `InstallSection_Win10` | Native | Native | Native | No | NotDeclared |
| `c0004\amdppkg.inf` | AMD Provisioning Packages | `ACPI\AMDI0052` | ACPI-enumerated PnP hardware ID | `InstallSection_Win11_22H2` | No | No | No | Native | NotDeclared |
| `c0004\amdpsp.inf` | AMD PSP 10.0 Device | `PCI\VEN_1022&DEV_15DF` | PCI-enumerated PnP hardware ID | `amdpsp_Device_100` | Native | Native | Native | Native | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_1134` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | Native | Native | Native | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_1486` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | Native | Native | Native | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_14CA` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | Native | Native | Native | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_156E` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | Native | Native | Native | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_15C7` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | Native | Native | Native | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_1649` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | Native | Native | Native | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_17E0` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | Native | Native | Native | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_13EC` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | Native | Native | Native | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_1456` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | Native | Native | Native | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_1537` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | Native | Native | Native | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_1578` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | Native | Native | Native | KMDF 1.13 |
| `c0004\amdsfhkmdf.inf` | AMD Sensor Fusion Hub | `PCI\VEN_1022&DEV_15E4` | PCI-enumerated PnP hardware ID | `amdsfhkmdf_Device` | Native | Native | Native | Native | KMDF 1.15 |
| `c0004\amdsfhkmdfi2c.inf` | AMD SFH KMDF I2C | `PCI\VEN_1022&DEV_15E6` | PCI-enumerated PnP hardware ID | `amdsfhkmdf_Device` | Native | Native | Native | Native | KMDF 1.15 |
| `c0004\amdsfhspbi2c.inf` | AMD SFH I2C Controller | `ACPI\AMDI0011` | ACPI-enumerated PnP hardware ID | `amdsfhspbi2c_Device` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdsfhumdf.inf` | AMD UMDF Sensor | `ACPI\AMDI0080` | ACPI-enumerated PnP hardware ID | `amdsfhumdf_Inst_Win10` | No(Build) | Native | Native | No | UMDF 2.15.0 |
| `c0004\amdsfhumdf.inf` | AMD UMDF Sensor | `ACPI\AMDI0080` | ACPI-enumerated PnP hardware ID | `amdsfhumdf_Inst_Win11` | No(Build) | No | No | Native | UMDF 2.15.0 |
| `c0004\amduart.inf` | AMD UART Controller | `ACPI\AMD0020` | ACPI-enumerated PnP hardware ID | `amduart_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amduart.inf` | AMD UART Controller | `ACPI\AMDI0020` | ACPI-enumerated PnP hardware ID | `amduart_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amduart.inf` | AMD UART Controller | `ACPI\AMDI0022` | ACPI-enumerated PnP hardware ID | `amduart_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_15C4` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `c0004\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_15C5` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `c0004\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_162E` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `c0004\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_162F` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `c0004\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_1668` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `c0004\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_1669` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `c0004\amdusb4net.inf` | AMD USB4NET | `{b85b7c50-6a01-11d2-b841-00c04fad5171}\AMDUSB4NET` | Device-class-specific ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdusb4net.inf` | AMD USB4NET | `{b85b7c50-6a01-11d2-b841-00c04fad5171}\Usb4Net` | Device-class-specific ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdusb4net.inf` | AMD USB4NET | `root\AMDUSB4NET_a` | Root-enumerated PnP hardware ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdusb4net.inf` | AMD USB4NET | `root\AMDUSB4NET_b` | Root-enumerated PnP hardware ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdusb4net.inf` | AMD USB4NET | `root\AMDUSB4NET_c` | Root-enumerated PnP hardware ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdusb4net.inf` | AMD USB4NET | `root\AMDUSB4NET_d` | Root-enumerated PnP hardware ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdusb4pcifilter.inf` | PCI Express Root Port | `PCI\VEN_1022&DEV_14CD&SUBSYS_14531022&REV_00` | PCI-enumerated PnP hardware ID | `amdusb4pcifilter` | Native | Native | Excluded | Excluded | NotDeclared |
| `c0004\amdusb4pcifilter.inf` | PCI Express Root Port | `PCI\VEN_1022&DEV_14EF&SUBSYS_14531022&REV_00` | PCI-enumerated PnP hardware ID | `amdusb4pcifilter` | Native | Native | Excluded | Excluded | NotDeclared |
| `c0004\amdusb4pcifilter.inf` | PCI Express Root Port | `PCI\VEN_1022&DEV_14EF&SUBSYS_14531022&REV_01` | PCI-enumerated PnP hardware ID | `amdusb4pcifilter` | Native | Native | Excluded | Excluded | NotDeclared |
| `c0004\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15C0&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Excluded | Excluded | NotDeclared |
| `c0004\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15C1&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Excluded | Excluded | NotDeclared |
| `c0004\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15C2&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Excluded | Excluded | NotDeclared |
| `c0004\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15C3&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Excluded | Excluded | NotDeclared |
| `c0004\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15D6&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Excluded | Excluded | NotDeclared |
| `c0004\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15D7&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Excluded | Excluded | NotDeclared |
| `c0004\amdwirelessbutton.inf` | AMD Wireless Button Driver | `ACPI\AMDI0051` | ACPI-enumerated PnP hardware ID | `amdwirelessbutton_Device` | No(Build) | Native | Native | No | KMDF 1.15 |
| `c0004\amdwirelessbutton.inf` | AMD Wireless Button Driver | `ACPI\AMDI0051` | ACPI-enumerated PnP hardware ID | `amdwirelessbutton_DeviceWin11` | No(Build) | No | No | Native | KMDF 1.15 |
| `c0004\ams_mailboxdrv.inf` | AMS-MailBoxDrv | `ACPI\AMDI0090` | ACPI-enumerated PnP hardware ID | `AMS-MailBoxDrv_Device` | Native | Native | Native | Native | NotDeclared |
| `c0004\plutonnull.inf` | AMD NULL Driver for Microsoft Pluton Security Processor | `ACPI\MSFT0200` | ACPI-enumerated PnP hardware ID | `Null_Pluton_Device` | Native | Native | Native | Excluded | NotDeclared |
| `c0004\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4353` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `c0004\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4363` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `c0004\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4372` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `c0004\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4385` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `c0004\smbusamd.inf` | AMD SMBus | `PCI\VEN_1022&DEV_780B` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `c0004\smbusamd.inf` | AMD SMBus | `PCI\VEN_1022&DEV_790B` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `c0004\usbfilter.inf` | AMD USB Filter Driver | `{36FC9E60-C465-11CF-8056-444553540000}\usbfilter` | Device-class-specific ID | `usbfilter` | Native | Native | Native | Native | NotDeclared |
| `c0004\zenpromnf.inf` | ZenProM S0i3 Network Filter | `ZenProMnf` | Network software component ID | `Install` | Native | Native | Native | Native | NotDeclared |

## AMD Chipset Software 6.10.17.152

| INF | Device | Device identifier | Identifier type | Install section | WS2016 | WS2019 | WS2022 | WS2025 | WDF |
|---|---|---|---|---|---|---|---|---|---|
| `c0004\amd3dvcache.inf` | AMD 3D V-Cache Performance Optimizer | `ACPI\AMDI0101` | ACPI-enumerated PnP hardware ID | `amd3dvcache_Device` | No(Build) | No(Build) | Native | Native | KMDF 1.15 |
| `c0004\amdas4.inf` | AmdAS4 Device | `ACPI\AMDI0050` | ACPI-enumerated PnP hardware ID | `AmdAS4` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdas4.inf` | AmdAS4 Device | `ACPI\ASD0001` | ACPI-enumerated PnP hardware ID | `AmdAS4` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdcir.inf` | AMD CIR Driver | `*AMDC001` | Generic PnP hardware ID | `AMDCIR64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdcir.inf` | AMD CIR Driver | `*AMDC002` | Generic PnP hardware ID | `AMDCIR64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdcir.inf` | AMD CIR Driver | `*AMDC003` | Generic PnP hardware ID | `AMDCIR64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdgpio2.inf` | AMD GPIO Controller | `ACPI\AMD0030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdgpio2.inf` | AMD GPIO Controller | `ACPI\AMDI0030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdgpio2.inf` | AMD GPIO Controller | `ACPI\AMDI0031` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdgpio2.inf` | AMD GPIO Controller | `ACPI\GPIO0010` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdgpio3.inf` | AMD GPIO Controller | `ACPI\AMDF030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdgpio3.inf` | AMD GPIO Controller | `ACPI\AMDIF030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdgpio3.inf` | AMD GPIO Controller | `ACPI\AMDIF031` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdi2c.inf` | AMD I2C Controller | `ACPI\AMD0010` | ACPI-enumerated PnP hardware ID | `amdi2c_Device` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdi2c.inf` | AMD I2C Controller | `ACPI\AMDI0010` | ACPI-enumerated PnP hardware ID | `amdi2c_Device` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdinterface.inf` | AMD Hetero Driver | `ACPI\AMDI0104` | ACPI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdinterface.inf` | AMD PCI | `PCI\VEN_1002&DEV_145A` | PCI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_1116` | PCI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_14AC` | PCI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_14DC` | PCI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_14DE` | PCI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_14EC` | PCI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_150D` | PCI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_1556` | PCI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdinterface.inf` | AMD SMBUS | `PCI\VEN_1022&DEV_790B` | PCI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1002&DEV_5A23` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_13E1` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1419` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1423` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1437` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1451` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1481` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1577` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_164F` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMD0004` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMD0005` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0005` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0006` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0007` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0008` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0009` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI000A` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI000B` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdoemprov.inf` | AMD Provisioning for OEM | `ACPI\AMDI0053` | ACPI-enumerated PnP hardware ID | `AMDPPMPF_DEV` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `c0004\amdpcidev.inf` | AMD PCI | `PCI\VEN_1002&DEV_145A` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_1455` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_145A` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_1485` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_148A` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_14DE` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdpmf.inf` | AMD PMF | `ACPI\AMDI0100` | ACPI-enumerated PnP hardware ID | `AMDPMF_INSTALL.NTamd64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdpmf.inf` | AMD PMF | `ACPI\AMDI0102` | ACPI-enumerated PnP hardware ID | `AMDPMF_INSTALL.NTamd64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdppkg.inf` | AMD Provisioning Packages | `ACPI\AMDI0052` | ACPI-enumerated PnP hardware ID | `InstallSection_Win10` | Native | Native | Native | No | NotDeclared |
| `c0004\amdppkg.inf` | AMD Provisioning Packages | `ACPI\AMDI0052` | ACPI-enumerated PnP hardware ID | `InstallSection_Win11` | No | No | No | Native | NotDeclared |
| `c0004\amdpsp.inf` | AMD PSP 10.0 Device | `PCI\VEN_1022&DEV_15DF` | PCI-enumerated PnP hardware ID | `amdpsp_Device_100` | Native | Native | Native | Native | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_1486` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | Native | Native | Native | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_14CA` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | Native | Native | Native | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_156E` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | Native | Native | Native | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_15C7` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | Native | Native | Native | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_1649` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | Native | Native | Native | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_17E0` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | Native | Native | Native | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_13EC` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | Native | Native | Native | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_1456` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | Native | Native | Native | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_1537` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | Native | Native | Native | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_1578` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | Native | Native | Native | KMDF 1.13 |
| `c0004\amdsfhkmdf.inf` | AMD Sensor Fusion Hub | `PCI\VEN_1022&DEV_15E4` | PCI-enumerated PnP hardware ID | `amdsfhkmdf_Device` | Native | Native | Native | Native | KMDF 1.15 |
| `c0004\amdsfhkmdfi2c.inf` | AMD SFH KMDF I2C | `PCI\VEN_1022&DEV_15E6` | PCI-enumerated PnP hardware ID | `amdsfhkmdf_Device` | Native | Native | Native | Native | KMDF 1.15 |
| `c0004\amdsfhspbi2c.inf` | AMD SFH I2C Controller | `ACPI\AMDI0011` | ACPI-enumerated PnP hardware ID | `amdsfhspbi2c_Device` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdsfhumdf.inf` | AMD UMDF Sensor | `ACPI\AMDI0080` | ACPI-enumerated PnP hardware ID | `amdsfhumdf_Inst_Win10` | No(Build) | Native | Native | No | UMDF 2.15.0 |
| `c0004\amdsfhumdf.inf` | AMD UMDF Sensor | `ACPI\AMDI0080` | ACPI-enumerated PnP hardware ID | `amdsfhumdf_Inst_Win11` | No(Build) | No | No | Native | UMDF 2.15.0 |
| `c0004\amduart.inf` | AMD UART Controller | `ACPI\AMD0020` | ACPI-enumerated PnP hardware ID | `amduart_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amduart.inf` | AMD UART Controller | `ACPI\AMDI0020` | ACPI-enumerated PnP hardware ID | `amduart_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amduart.inf` | AMD UART Controller | `ACPI\AMDI0022` | ACPI-enumerated PnP hardware ID | `amduart_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_15C4` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `c0004\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_15C5` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `c0004\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_162E` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `c0004\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_162F` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `c0004\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_1668` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `c0004\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_1669` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `c0004\amdusb4net.inf` | AMD USB4NET | `{b85b7c50-6a01-11d2-b841-00c04fad5171}\AMDUSB4NET` | Device-class-specific ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdusb4net.inf` | AMD USB4NET | `{b85b7c50-6a01-11d2-b841-00c04fad5171}\Usb4Net` | Device-class-specific ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdusb4net.inf` | AMD USB4NET | `root\AMDUSB4NET_a` | Root-enumerated PnP hardware ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdusb4net.inf` | AMD USB4NET | `root\AMDUSB4NET_b` | Root-enumerated PnP hardware ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdusb4net.inf` | AMD USB4NET | `root\AMDUSB4NET_c` | Root-enumerated PnP hardware ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdusb4net.inf` | AMD USB4NET | `root\AMDUSB4NET_d` | Root-enumerated PnP hardware ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdusb4pcifilter.inf` | PCI Express Root Port | `PCI\VEN_1022&DEV_14CD&SUBSYS_14531022&REV_00` | PCI-enumerated PnP hardware ID | `amdusb4pcifilter` | Native | Native | Excluded | Excluded | NotDeclared |
| `c0004\amdusb4pcifilter.inf` | PCI Express Root Port | `PCI\VEN_1022&DEV_14EF&SUBSYS_14531022&REV_00` | PCI-enumerated PnP hardware ID | `amdusb4pcifilter` | Native | Native | Excluded | Excluded | NotDeclared |
| `c0004\amdusb4pcifilter.inf` | PCI Express Root Port | `PCI\VEN_1022&DEV_14EF&SUBSYS_14531022&REV_01` | PCI-enumerated PnP hardware ID | `amdusb4pcifilter` | Native | Native | Excluded | Excluded | NotDeclared |
| `c0004\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15C0&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Excluded | Excluded | NotDeclared |
| `c0004\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15C1&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Excluded | Excluded | NotDeclared |
| `c0004\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15C2&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Excluded | Excluded | NotDeclared |
| `c0004\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15C3&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Excluded | Excluded | NotDeclared |
| `c0004\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15D6&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Excluded | Excluded | NotDeclared |
| `c0004\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15D7&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Excluded | Excluded | NotDeclared |
| `c0004\amdwirelessbutton.inf` | AMD Wireless Button Driver | `ACPI\AMDI0051` | ACPI-enumerated PnP hardware ID | `amdwirelessbutton_Device` | No(Build) | Native | Native | No | KMDF 1.15 |
| `c0004\amdwirelessbutton.inf` | AMD Wireless Button Driver | `ACPI\AMDI0051` | ACPI-enumerated PnP hardware ID | `amdwirelessbutton_DeviceWin11` | No(Build) | No | No | Native | KMDF 1.15 |
| `c0004\ams_mailboxdrv.inf` | AMS-MailBoxDrv | `ACPI\AMDI0090` | ACPI-enumerated PnP hardware ID | `AMS-MailBoxDrv_Device` | Native | Native | Native | Native | NotDeclared |
| `c0004\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4353` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `c0004\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4363` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `c0004\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4372` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `c0004\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4385` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `c0004\smbusamd.inf` | AMD SMBus | `PCI\VEN_1022&DEV_780B` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `c0004\smbusamd.inf` | AMD SMBus | `PCI\VEN_1022&DEV_790B` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `c0004\usbfilter.inf` | AMD USB Filter Driver | `{36FC9E60-C465-11CF-8056-444553540000}\usbfilter` | Device-class-specific ID | `usbfilter` | Native | Native | Native | Native | NotDeclared |
| `c0004\zenpromnf.inf` | ZenProM S0i3 Network Filter | `ZenProMnf` | Network software component ID | `Install` | Native | Native | Native | Native | NotDeclared |

## AMD Chipset Software 6.07.22.037

| INF | Device | Device identifier | Identifier type | Install section | WS2016 | WS2019 | WS2022 | WS2025 | WDF |
|---|---|---|---|---|---|---|---|---|---|
| `c0004\amd3dvcache.inf` | AMD 3D V-Cache Performance Optimizer | `ACPI\AMDI0101` | ACPI-enumerated PnP hardware ID | `amd3dvcache_Device` | No(Build) | No(Build) | Native | Native | KMDF 1.15 |
| `c0004\amdas4.inf` | AmdAS4 Device | `ACPI\AMDI0050` | ACPI-enumerated PnP hardware ID | `AmdAS4` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdas4.inf` | AmdAS4 Device | `ACPI\ASD0001` | ACPI-enumerated PnP hardware ID | `AmdAS4` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdcir.inf` | AMD CIR Driver | `*AMDC001` | Generic PnP hardware ID | `AMDCIR64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdcir.inf` | AMD CIR Driver | `*AMDC002` | Generic PnP hardware ID | `AMDCIR64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdcir.inf` | AMD CIR Driver | `*AMDC003` | Generic PnP hardware ID | `AMDCIR64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdgpio2.inf` | AMD GPIO Controller | `ACPI\AMD0030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdgpio2.inf` | AMD GPIO Controller | `ACPI\AMDI0030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdgpio2.inf` | AMD GPIO Controller | `ACPI\AMDI0031` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdgpio2.inf` | AMD GPIO Controller | `ACPI\GPIO0010` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdgpio3.inf` | AMD GPIO Controller | `ACPI\AMDF030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdgpio3.inf` | AMD GPIO Controller | `ACPI\AMDIF030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdgpio3.inf` | AMD GPIO Controller | `ACPI\AMDIF031` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdi2c.inf` | AMD I2C Controller | `ACPI\AMD0010` | ACPI-enumerated PnP hardware ID | `amdi2c_Device` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdi2c.inf` | AMD I2C Controller | `ACPI\AMDI0010` | ACPI-enumerated PnP hardware ID | `amdi2c_Device` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdinterface.inf` | AMD Hetero Driver | `ACPI\AMDI0104` | ACPI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_1116` | PCI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_14AC` | PCI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_14DC` | PCI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_14DE` | PCI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_14EC` | PCI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_150D` | PCI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_1556` | PCI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdinterface.inf` | AMD SMBUS | `PCI\VEN_1022&DEV_790B` | PCI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1002&DEV_5A23` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_13E1` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1419` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1423` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1437` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1451` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1481` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1577` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_164F` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMD0004` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMD0005` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0005` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0006` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0007` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0008` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0009` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI000A` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI000B` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdoemprov.inf` | AMD Provisioning for OEM | `ACPI\AMDI0053` | ACPI-enumerated PnP hardware ID | `AMDPPMPF_DEV` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `c0004\amdpcidev.inf` | AMD PCI | `PCI\VEN_1002&DEV_145A` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_1455` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_145A` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_1485` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_148A` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_14DE` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdpmf.inf` | AMD PMF | `ACPI\AMDI0100` | ACPI-enumerated PnP hardware ID | `AMDPMF_INSTALL.NTamd64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdpmf.inf` | AMD PMF | `ACPI\AMDI0102` | ACPI-enumerated PnP hardware ID | `AMDPMF_INSTALL.NTamd64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdppmpf.inf` | AMD PPM Provisioning File | `ACPI\AMDI0052` | ACPI-enumerated PnP hardware ID | `AMDPPMPF_DEV` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdpsp.inf` | AMD PSP 10.0 Device | `PCI\VEN_1022&DEV_15DF` | PCI-enumerated PnP hardware ID | `amdpsp_Device_100` | Native | Native | Native | Native | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_1486` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | Native | Native | Native | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_14CA` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | Native | Native | Native | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_156E` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | Native | Native | Native | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_15C7` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | Native | Native | Native | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_1649` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | Native | Native | Native | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_17E0` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | Native | Native | Native | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_13EC` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | Native | Native | Native | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_1456` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | Native | Native | Native | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_1537` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | Native | Native | Native | KMDF 1.13 |
| `c0004\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_1578` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | Native | Native | Native | KMDF 1.13 |
| `c0004\amdsfhkmdf.inf` | AMD Sensor Fusion Hub | `PCI\VEN_1022&DEV_15E4` | PCI-enumerated PnP hardware ID | `amdsfhkmdf_Device` | Native | Native | Native | Native | KMDF 1.15 |
| `c0004\amdsfhkmdfi2c.inf` | AMD SFH KMDF I2C | `PCI\VEN_1022&DEV_15E6` | PCI-enumerated PnP hardware ID | `amdsfhkmdf_Device` | Native | Native | Native | Native | KMDF 1.15 |
| `c0004\amdsfhspbi2c.inf` | AMD SFH I2C Controller | `ACPI\AMDI0011` | ACPI-enumerated PnP hardware ID | `amdsfhspbi2c_Device` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdsfhumdf.inf` | AMD UMDF Sensor | `ACPI\AMDI0080` | ACPI-enumerated PnP hardware ID | `amdsfhumdf_Inst_Win10` | No(Build) | Native | Native | No | UMDF 2.15.0 |
| `c0004\amdsfhumdf.inf` | AMD UMDF Sensor | `ACPI\AMDI0080` | ACPI-enumerated PnP hardware ID | `amdsfhumdf_Inst_Win11` | No(Build) | No | No | Native | UMDF 2.15.0 |
| `c0004\amduart.inf` | AMD UART Controller | `ACPI\AMD0020` | ACPI-enumerated PnP hardware ID | `amduart_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amduart.inf` | AMD UART Controller | `ACPI\AMDI0020` | ACPI-enumerated PnP hardware ID | `amduart_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amduart.inf` | AMD UART Controller | `ACPI\AMDI0022` | ACPI-enumerated PnP hardware ID | `amduart_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_15C4` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `c0004\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_15C5` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `c0004\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_162E` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `c0004\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_162F` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `c0004\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_1668` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `c0004\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_1669` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `c0004\amdusb4net.inf` | AMD USB4NET | `{b85b7c50-6a01-11d2-b841-00c04fad5171}\AMDUSB4NET` | Device-class-specific ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdusb4net.inf` | AMD USB4NET | `{b85b7c50-6a01-11d2-b841-00c04fad5171}\Usb4Net` | Device-class-specific ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdusb4net.inf` | AMD USB4NET | `root\AMDUSB4NET_a` | Root-enumerated PnP hardware ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdusb4net.inf` | AMD USB4NET | `root\AMDUSB4NET_b` | Root-enumerated PnP hardware ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdusb4net.inf` | AMD USB4NET | `root\AMDUSB4NET_c` | Root-enumerated PnP hardware ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdusb4net.inf` | AMD USB4NET | `root\AMDUSB4NET_d` | Root-enumerated PnP hardware ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdusb4pcifilter.inf` | PCI Express Root Port | `PCI\VEN_1022&DEV_14CD&SUBSYS_14531022&REV_00` | PCI-enumerated PnP hardware ID | `amdusb4pcifilter` | Native | Native | Excluded | Excluded | NotDeclared |
| `c0004\amdusb4pcifilter.inf` | PCI Express Root Port | `PCI\VEN_1022&DEV_14EF&SUBSYS_14531022&REV_00` | PCI-enumerated PnP hardware ID | `amdusb4pcifilter` | Native | Native | Excluded | Excluded | NotDeclared |
| `c0004\amdusb4pcifilter.inf` | PCI Express Root Port | `PCI\VEN_1022&DEV_14EF&SUBSYS_14531022&REV_01` | PCI-enumerated PnP hardware ID | `amdusb4pcifilter` | Native | Native | Excluded | Excluded | NotDeclared |
| `c0004\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15C0&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Excluded | Excluded | NotDeclared |
| `c0004\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15C1&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Excluded | Excluded | NotDeclared |
| `c0004\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15C2&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Excluded | Excluded | NotDeclared |
| `c0004\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15C3&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Excluded | Excluded | NotDeclared |
| `c0004\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15D6&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Excluded | Excluded | NotDeclared |
| `c0004\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15D7&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Excluded | Excluded | NotDeclared |
| `c0004\amdwirelessbutton.inf` | AMD Wireless Button Driver | `ACPI\AMDI0051` | ACPI-enumerated PnP hardware ID | `amdwirelessbutton_Device` | No(Build) | Native | Native | No | KMDF 1.15 |
| `c0004\amdwirelessbutton.inf` | AMD Wireless Button Driver | `ACPI\AMDI0051` | ACPI-enumerated PnP hardware ID | `amdwirelessbutton_DeviceWin11` | No(Build) | No | No | Native | KMDF 1.15 |
| `c0004\ams_mailboxdrv.inf` | AMS-MailBoxDrv | `ACPI\AMDI0090` | ACPI-enumerated PnP hardware ID | `AMS-MailBoxDrv_Device` | Native | Native | Native | Native | NotDeclared |
| `c0004\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4353` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `c0004\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4363` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `c0004\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4372` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `c0004\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4385` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `c0004\smbusamd.inf` | AMD SMBus | `PCI\VEN_1022&DEV_780B` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `c0004\smbusamd.inf` | AMD SMBus | `PCI\VEN_1022&DEV_790B` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `c0004\usbfilter.inf` | AMD USB Filter Driver | `{36FC9E60-C465-11CF-8056-444553540000}\usbfilter` | Device-class-specific ID | `usbfilter` | Native | Native | Native | Native | NotDeclared |
| `c0004\zenpromnf.inf` | ZenProM S0i3 Network Filter | `ZenProMnf` | Network software component ID | `Install` | Native | Native | Native | Native | NotDeclared |

## AMD Chipset Software 6.05.28.016

| INF | Device | Device identifier | Identifier type | Install section | WS2016 | WS2019 | WS2022 | WS2025 | WDF |
|---|---|---|---|---|---|---|---|---|---|
| `c0004\amd3dvcache.inf` | AMD 3D V-Cache Performance Optimizer | `ACPI\AMDI0101` | ACPI-enumerated PnP hardware ID | `amd3dvcache_Device` | No(Build) | No(Build) | Native | Native | KMDF 1.15 |
| `c0004\amdas4.inf` | AmdAS4 Device | `ACPI\AMDI0050` | ACPI-enumerated PnP hardware ID | `AmdAS4` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdas4.inf` | AmdAS4 Device | `ACPI\ASD0001` | ACPI-enumerated PnP hardware ID | `AmdAS4` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdcir.inf` | AMD CIR Driver | `*AMDC001` | Generic PnP hardware ID | `AMDCIR64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdcir.inf` | AMD CIR Driver | `*AMDC002` | Generic PnP hardware ID | `AMDCIR64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdcir.inf` | AMD CIR Driver | `*AMDC003` | Generic PnP hardware ID | `AMDCIR64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdgpio2.inf` | AMD GPIO Controller | `ACPI\AMD0030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdgpio2.inf` | AMD GPIO Controller | `ACPI\AMDI0030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdgpio2.inf` | AMD GPIO Controller | `ACPI\AMDI0031` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdgpio2.inf` | AMD GPIO Controller | `ACPI\GPIO0010` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdgpio3.inf` | AMD GPIO Controller | `ACPI\AMDF030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdgpio3.inf` | AMD GPIO Controller | `ACPI\AMDIF030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdgpio3.inf` | AMD GPIO Controller | `ACPI\AMDIF031` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdi2c.inf` | AMD I2C Controller | `ACPI\AMD0010` | ACPI-enumerated PnP hardware ID | `amdi2c_Device` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdi2c.inf` | AMD I2C Controller | `ACPI\AMDI0010` | ACPI-enumerated PnP hardware ID | `amdi2c_Device` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdinterface.inf` | AMD Hetero Driver | `ACPI\AMDI0104` | ACPI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_14AC` | PCI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_14DE` | PCI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_14EC` | PCI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_150D` | PCI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdinterface.inf` | AMD SMBUS | `PCI\VEN_1022&DEV_790B` | PCI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1002&DEV_5A23` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_13E1` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1419` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1423` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1437` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1451` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1481` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1577` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_164F` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMD0004` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMD0005` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0005` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0006` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0007` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0008` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0009` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI000A` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI000B` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdoemprov.inf` | AMD Provisioning for OEM | `ACPI\AMDI0053` | ACPI-enumerated PnP hardware ID | `AMDPPMPF_DEV` | No(Build) | No(Build) | No(Build) | Native | NotDeclared |
| `c0004\amdpcidev.inf` | AMD PCI | `PCI\VEN_1002&DEV_145A` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_1455` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_145A` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_1485` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_148A` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_14DE` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdpmf.inf` | AMD PMF | `ACPI\AMDI0100` | ACPI-enumerated PnP hardware ID | `AMDPMF_INSTALL.NTamd64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdpmf.inf` | AMD PMF | `ACPI\AMDI0102` | ACPI-enumerated PnP hardware ID | `AMDPMF_INSTALL.NTamd64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdppmpf.inf` | AMD PPM Provisioning File | `ACPI\AMDI0052` | ACPI-enumerated PnP hardware ID | `AMDPPMPF_DEV` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdpsp.inf` | AMD PSP 10.0 Device | `PCI\VEN_1022&DEV_15DF` | PCI-enumerated PnP hardware ID | `amdpsp_Device_100` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_1486` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_14CA` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_15C7` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_1649` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_17E0` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_13EC` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_1456` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_1537` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_1578` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdsfhkmdf.inf` | AMD Sensor Fusion Hub | `PCI\VEN_1022&DEV_15E4` | PCI-enumerated PnP hardware ID | `amdsfhkmdf_Device` | Native | Native | Native | Native | KMDF 1.15 |
| `c0004\amdsfhkmdfi2c.inf` | AMD SFH KMDF I2C | `PCI\VEN_1022&DEV_15E6` | PCI-enumerated PnP hardware ID | `amdsfhkmdf_Device` | Native | Native | Native | Native | KMDF 1.15 |
| `c0004\amdsfhspbi2c.inf` | AMD SFH I2C Controller | `ACPI\AMDI0011` | ACPI-enumerated PnP hardware ID | `amdsfhspbi2c_Device` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdsfhumdf.inf` | AMD UMDF Sensor | `ACPI\AMDI0080` | ACPI-enumerated PnP hardware ID | `amdsfhumdf_Inst_Win10` | No(Build) | Native | Native | No | UMDF 2.15.0 |
| `c0004\amdsfhumdf.inf` | AMD UMDF Sensor | `ACPI\AMDI0080` | ACPI-enumerated PnP hardware ID | `amdsfhumdf_Inst_Win11` | No(Build) | No | No | Native | UMDF 2.15.0 |
| `c0004\amduart.inf` | AMD UART Controller | `ACPI\AMD0020` | ACPI-enumerated PnP hardware ID | `amduart_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amduart.inf` | AMD UART Controller | `ACPI\AMDI0020` | ACPI-enumerated PnP hardware ID | `amduart_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amduart.inf` | AMD UART Controller | `ACPI\AMDI0022` | ACPI-enumerated PnP hardware ID | `amduart_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_15C4` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `c0004\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_15C5` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `c0004\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_162E` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `c0004\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_162F` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `c0004\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_1668` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `c0004\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_1669` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `c0004\amdusb4net.inf` | AMD USB4NET | `{b85b7c50-6a01-11d2-b841-00c04fad5171}\AMDUSB4NET` | Device-class-specific ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdusb4net.inf` | AMD USB4NET | `{b85b7c50-6a01-11d2-b841-00c04fad5171}\Usb4Net` | Device-class-specific ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdusb4net.inf` | AMD USB4NET | `root\AMDUSB4NET_a` | Root-enumerated PnP hardware ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdusb4net.inf` | AMD USB4NET | `root\AMDUSB4NET_b` | Root-enumerated PnP hardware ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdusb4net.inf` | AMD USB4NET | `root\AMDUSB4NET_c` | Root-enumerated PnP hardware ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdusb4net.inf` | AMD USB4NET | `root\AMDUSB4NET_d` | Root-enumerated PnP hardware ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdusb4pcifilter.inf` | PCI Express Root Port | `PCI\VEN_1022&DEV_14CD&SUBSYS_14531022&REV_00` | PCI-enumerated PnP hardware ID | `amdusb4pcifilter` | Native | Native | Excluded | Excluded | NotDeclared |
| `c0004\amdusb4pcifilter.inf` | PCI Express Root Port | `PCI\VEN_1022&DEV_14EF&SUBSYS_14531022&REV_00` | PCI-enumerated PnP hardware ID | `amdusb4pcifilter` | Native | Native | Excluded | Excluded | NotDeclared |
| `c0004\amdusb4pcifilter.inf` | PCI Express Root Port | `PCI\VEN_1022&DEV_14EF&SUBSYS_14531022&REV_01` | PCI-enumerated PnP hardware ID | `amdusb4pcifilter` | Native | Native | Excluded | Excluded | NotDeclared |
| `c0004\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15C0&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Excluded | Excluded | NotDeclared |
| `c0004\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15C1&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Excluded | Excluded | NotDeclared |
| `c0004\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15C2&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Excluded | Excluded | NotDeclared |
| `c0004\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15C3&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Excluded | Excluded | NotDeclared |
| `c0004\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15D6&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Excluded | Excluded | NotDeclared |
| `c0004\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15D7&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Excluded | Excluded | NotDeclared |
| `c0004\amdwirelessbutton.inf` | AMD Wireless Button Driver | `ACPI\AMDI0051` | ACPI-enumerated PnP hardware ID | `amdwirelessbutton_Device` | No(Build) | Native | Native | No | KMDF 1.15 |
| `c0004\amdwirelessbutton.inf` | AMD Wireless Button Driver | `ACPI\AMDI0051` | ACPI-enumerated PnP hardware ID | `amdwirelessbutton_DeviceWin11` | No(Build) | No | No | Native | KMDF 1.15 |
| `c0004\ams_mailboxdrv.inf` | AMS-MailBoxDrv | `ACPI\AMDI0090` | ACPI-enumerated PnP hardware ID | `AMS-MailBoxDrv_Device` | Native | Native | Native | Native | NotDeclared |
| `c0004\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4353` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `c0004\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4363` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `c0004\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4372` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `c0004\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4385` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `c0004\smbusamd.inf` | AMD SMBus | `PCI\VEN_1022&DEV_780B` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `c0004\smbusamd.inf` | AMD SMBus | `PCI\VEN_1022&DEV_790B` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `c0004\usbfilter.inf` | AMD USB Filter Driver | `{36FC9E60-C465-11CF-8056-444553540000}\usbfilter` | Device-class-specific ID | `usbfilter` | Native | Native | Native | Native | NotDeclared |
| `c0004\zenpromnf.inf` | ZenProM S0i3 Network Filter | `ZenProMnf` | Network software component ID | `Install` | Native | Native | Native | Native | NotDeclared |

## AMD Chipset Software 6.02.07.2300

| INF | Device | Device identifier | Identifier type | Install section | WS2016 | WS2019 | WS2022 | WS2025 | WDF |
|---|---|---|---|---|---|---|---|---|---|
| `c0004\amd3dvcache.inf` | AMD 3D V-Cache Performance Optimizer | `ACPI\AMDI0101` | ACPI-enumerated PnP hardware ID | `amd3dvcache_Device` | No(Build) | No(Build) | Native | Native | KMDF 1.15 |
| `c0004\amdas4.inf` | AmdAS4 Device | `ACPI\AMDI0050` | ACPI-enumerated PnP hardware ID | `AmdAS4` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdas4.inf` | AmdAS4 Device | `ACPI\ASD0001` | ACPI-enumerated PnP hardware ID | `AmdAS4` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdcir.inf` | AMD CIR Driver | `*AMDC001` | Generic PnP hardware ID | `AMDCIR64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdcir.inf` | AMD CIR Driver | `*AMDC002` | Generic PnP hardware ID | `AMDCIR64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdcir.inf` | AMD CIR Driver | `*AMDC003` | Generic PnP hardware ID | `AMDCIR64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdgpio2.inf` | AMD GPIO Controller | `ACPI\AMD0030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdgpio2.inf` | AMD GPIO Controller | `ACPI\AMDI0030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdgpio2.inf` | AMD GPIO Controller | `ACPI\AMDI0031` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdgpio2.inf` | AMD GPIO Controller | `ACPI\GPIO0010` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdgpio3.inf` | AMD GPIO Controller | `ACPI\AMDF030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdgpio3.inf` | AMD GPIO Controller | `ACPI\AMDIF030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdgpio3.inf` | AMD GPIO Controller | `ACPI\AMDIF031` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdi2c.inf` | AMD I2C Controller | `ACPI\AMD0010` | ACPI-enumerated PnP hardware ID | `amdi2c_Device` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdi2c.inf` | AMD I2C Controller | `ACPI\AMDI0010` | ACPI-enumerated PnP hardware ID | `amdi2c_Device` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdinterface.inf` | AMD Hetero Driver | `ACPI\AMDI0104` | ACPI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_14AC` | PCI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_14EC` | PCI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_150D` | PCI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdinterface.inf` | AMD SMBUS | `PCI\VEN_1022&DEV_790B` | PCI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1002&DEV_5A23` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_13E1` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1419` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1423` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1437` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1451` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1481` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1577` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_164F` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMD0004` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMD0005` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0005` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0006` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0007` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0008` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0009` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI000A` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdpcidev.inf` | AMD PCI | `PCI\VEN_1002&DEV_145A` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_1455` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_145A` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_1485` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_148A` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_14DE` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdpmf.inf` | AMD PMF | `ACPI\AMDI0100` | ACPI-enumerated PnP hardware ID | `AMDPMF_INSTALL.NTamd64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdpmf.inf` | AMD PMF | `ACPI\AMDI0102` | ACPI-enumerated PnP hardware ID | `AMDPMF_INSTALL.NTamd64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdppmpf.inf` | AMD PPM Provisioning File | `ACPI\AMDI0052` | ACPI-enumerated PnP hardware ID | `AMDPPMPF_DEV` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdpsp.inf` | AMD PSP 10.0 Device | `PCI\VEN_1022&DEV_15DF` | PCI-enumerated PnP hardware ID | `amdpsp_Device_100` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_1486` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_14CA` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_15C7` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_1649` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_17E0` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_13EC` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_1456` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_1537` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_1578` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdsfhkmdf.inf` | AMD Sensor Fusion Hub | `PCI\VEN_1022&DEV_15E4` | PCI-enumerated PnP hardware ID | `amdsfhkmdf_Device` | Native | Native | Native | Native | KMDF 1.15 |
| `c0004\amdsfhkmdfi2c.inf` | AMD SFH KMDF I2C | `PCI\VEN_1022&DEV_15E6` | PCI-enumerated PnP hardware ID | `amdsfhkmdf_Device` | Native | Native | Native | Native | KMDF 1.15 |
| `c0004\amdsfhspbi2c.inf` | AMD SFH I2C Controller | `ACPI\AMDI0011` | ACPI-enumerated PnP hardware ID | `amdsfhspbi2c_Device` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdsfhumdf.inf` | AMD UMDF Sensor | `ACPI\AMDI0080` | ACPI-enumerated PnP hardware ID | `amdsfhumdf_Inst` | Native | Native | Native | Native | UMDF 2.15.0 |
| `c0004\amduart.inf` | AMD UART Controller | `ACPI\AMD0020` | ACPI-enumerated PnP hardware ID | `amduart_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amduart.inf` | AMD UART Controller | `ACPI\AMDI0020` | ACPI-enumerated PnP hardware ID | `amduart_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amduart.inf` | AMD UART Controller | `ACPI\AMDI0022` | ACPI-enumerated PnP hardware ID | `amduart_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_15C4` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `c0004\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_15C5` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `c0004\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_162E` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `c0004\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_162F` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `c0004\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_1668` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `c0004\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_1669` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `c0004\amdusb4net.inf` | AMD USB4NET | `{b85b7c50-6a01-11d2-b841-00c04fad5171}\AMDUSB4NET` | Device-class-specific ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdusb4net.inf` | AMD USB4NET | `{b85b7c50-6a01-11d2-b841-00c04fad5171}\Usb4Net` | Device-class-specific ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdusb4net.inf` | AMD USB4NET | `root\AMDUSB4NET_a` | Root-enumerated PnP hardware ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdusb4net.inf` | AMD USB4NET | `root\AMDUSB4NET_b` | Root-enumerated PnP hardware ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdusb4net.inf` | AMD USB4NET | `root\AMDUSB4NET_c` | Root-enumerated PnP hardware ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdusb4net.inf` | AMD USB4NET | `root\AMDUSB4NET_d` | Root-enumerated PnP hardware ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdusb4pcifilter.inf` | PCI Express Root Port | `PCI\VEN_1022&DEV_14CD&SUBSYS_14531022&REV_00` | PCI-enumerated PnP hardware ID | `amdusb4pcifilter` | Native | Native | Excluded | Excluded | NotDeclared |
| `c0004\amdusb4pcifilter.inf` | PCI Express Root Port | `PCI\VEN_1022&DEV_14EF&SUBSYS_14531022&REV_00` | PCI-enumerated PnP hardware ID | `amdusb4pcifilter` | Native | Native | Excluded | Excluded | NotDeclared |
| `c0004\amdusb4pcifilter.inf` | PCI Express Root Port | `PCI\VEN_1022&DEV_14EF&SUBSYS_14531022&REV_01` | PCI-enumerated PnP hardware ID | `amdusb4pcifilter` | Native | Native | Excluded | Excluded | NotDeclared |
| `c0004\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15C0&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Excluded | Excluded | NotDeclared |
| `c0004\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15C1&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Excluded | Excluded | NotDeclared |
| `c0004\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15C2&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Excluded | Excluded | NotDeclared |
| `c0004\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15C3&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Excluded | Excluded | NotDeclared |
| `c0004\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15D6&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Excluded | Excluded | NotDeclared |
| `c0004\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15D7&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Excluded | Excluded | NotDeclared |
| `c0004\amdwirelessbutton.inf` | AMD Wireless Button Driver | `ACPI\AMDI0051` | ACPI-enumerated PnP hardware ID | `amdwirelessbutton_Device` | Native | Native | Native | Native | KMDF 1.15 |
| `c0004\ams_mailboxdrv.inf` | AMS-MailBoxDrv | `ACPI\AMDI0090` | ACPI-enumerated PnP hardware ID | `AMS-MailBoxDrv_Device` | Native | Native | Native | Native | NotDeclared |
| `c0004\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4353` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `c0004\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4363` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `c0004\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4372` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `c0004\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4385` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `c0004\smbusamd.inf` | AMD SMBus | `PCI\VEN_1022&DEV_780B` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `c0004\smbusamd.inf` | AMD SMBus | `PCI\VEN_1022&DEV_790B` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `c0004\usbfilter.inf` | AMD USB Filter Driver | `{36FC9E60-C465-11CF-8056-444553540000}\usbfilter` | Device-class-specific ID | `usbfilter` | Native | Native | Native | Native | NotDeclared |
| `c0004\zenpromnf.inf` | ZenProM S0i3 Network Filter | `ZenProMnf` | Network software component ID | `Install` | Native | Native | Native | Native | NotDeclared |

## AMD Chipset Software 6.01.25.342

| INF | Device | Device identifier | Identifier type | Install section | WS2016 | WS2019 | WS2022 | WS2025 | WDF |
|---|---|---|---|---|---|---|---|---|---|
| `c0004\amd3dvcache.inf` | AMD 3D V-Cache Performance Optimizer | `ACPI\AMDI0101` | ACPI-enumerated PnP hardware ID | `amd3dvcache_Device` | No(Build) | No(Build) | Native | Native | KMDF 1.15 |
| `c0004\amdas4.inf` | AmdAS4 Device | `ACPI\AMDI0050` | ACPI-enumerated PnP hardware ID | `AmdAS4` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdas4.inf` | AmdAS4 Device | `ACPI\ASD0001` | ACPI-enumerated PnP hardware ID | `AmdAS4` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdcir.inf` | AMD CIR Driver | `*AMDC001` | Generic PnP hardware ID | `AMDCIR64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdcir.inf` | AMD CIR Driver | `*AMDC002` | Generic PnP hardware ID | `AMDCIR64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdcir.inf` | AMD CIR Driver | `*AMDC003` | Generic PnP hardware ID | `AMDCIR64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdgpio2.inf` | AMD GPIO Controller | `ACPI\AMD0030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdgpio2.inf` | AMD GPIO Controller | `ACPI\AMDI0030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdgpio2.inf` | AMD GPIO Controller | `ACPI\AMDI0031` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdgpio2.inf` | AMD GPIO Controller | `ACPI\GPIO0010` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdgpio3.inf` | AMD GPIO Controller | `ACPI\AMDF030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdgpio3.inf` | AMD GPIO Controller | `ACPI\AMDIF030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdgpio3.inf` | AMD GPIO Controller | `ACPI\AMDIF031` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdi2c.inf` | AMD I2C Controller | `ACPI\AMD0010` | ACPI-enumerated PnP hardware ID | `amdi2c_Device` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdi2c.inf` | AMD I2C Controller | `ACPI\AMDI0010` | ACPI-enumerated PnP hardware ID | `amdi2c_Device` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdinterface.inf` | AMD Hetero Driver | `ACPI\AMDI0104` | ACPI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_14AC` | PCI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_14EC` | PCI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_150D` | PCI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdinterface.inf` | AMD SMBUS | `PCI\VEN_1022&DEV_790B` | PCI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1002&DEV_5A23` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_13E1` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1419` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1423` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1437` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1451` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1481` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1577` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_164F` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMD0004` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMD0005` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0005` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0006` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0007` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0008` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0009` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI000A` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdpcidev.inf` | AMD PCI | `PCI\VEN_1002&DEV_145A` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_1455` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_145A` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_1485` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_148A` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_14DE` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdpmf.inf` | AMD PMF | `ACPI\AMDI0100` | ACPI-enumerated PnP hardware ID | `AMDPMF_INSTALL.NTamd64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdpmf.inf` | AMD PMF | `ACPI\AMDI0102` | ACPI-enumerated PnP hardware ID | `AMDPMF_INSTALL.NTamd64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdppmpf.inf` | AMD PPM Provisioning File | `ACPI\AMDI0052` | ACPI-enumerated PnP hardware ID | `AMDPPMPF_DEV` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdpsp.inf` | AMD PSP 10.0 Device | `PCI\VEN_1022&DEV_15DF` | PCI-enumerated PnP hardware ID | `amdpsp_Device_100` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_1486` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_14CA` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_15C7` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_1649` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_17E0` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_13EC` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_1456` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_1537` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_1578` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdsfhkmdf.inf` | AMD Sensor Fusion Hub | `PCI\VEN_1022&DEV_15E4` | PCI-enumerated PnP hardware ID | `amdsfhkmdf_Device` | Native | Native | Native | Native | KMDF 1.15 |
| `c0004\amdsfhkmdfi2c.inf` | AMD SFH KMDF I2C | `PCI\VEN_1022&DEV_15E6` | PCI-enumerated PnP hardware ID | `amdsfhkmdf_Device` | Native | Native | Native | Native | KMDF 1.15 |
| `c0004\amdsfhspbi2c.inf` | AMD SFH I2C Controller | `ACPI\AMDI0011` | ACPI-enumerated PnP hardware ID | `amdsfhspbi2c_Device` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdsfhumdf.inf` | AMD UMDF Sensor | `ACPI\AMDI0080` | ACPI-enumerated PnP hardware ID | `amdsfhumdf_Inst` | Native | Native | Native | Native | UMDF 2.15.0 |
| `c0004\amduart.inf` | AMD UART Controller | `ACPI\AMD0020` | ACPI-enumerated PnP hardware ID | `amduart_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amduart.inf` | AMD UART Controller | `ACPI\AMDI0020` | ACPI-enumerated PnP hardware ID | `amduart_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amduart.inf` | AMD UART Controller | `ACPI\AMDI0022` | ACPI-enumerated PnP hardware ID | `amduart_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_15C4` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `c0004\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_15C5` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `c0004\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_162E` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `c0004\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_162F` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `c0004\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_1668` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `c0004\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_1669` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `c0004\amdusb4net.inf` | AMD USB4NET | `{b85b7c50-6a01-11d2-b841-00c04fad5171}\AMDUSB4NET` | Device-class-specific ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdusb4net.inf` | AMD USB4NET | `{b85b7c50-6a01-11d2-b841-00c04fad5171}\Usb4Net` | Device-class-specific ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdusb4net.inf` | AMD USB4NET | `root\AMDUSB4NET_a` | Root-enumerated PnP hardware ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdusb4net.inf` | AMD USB4NET | `root\AMDUSB4NET_b` | Root-enumerated PnP hardware ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdusb4net.inf` | AMD USB4NET | `root\AMDUSB4NET_c` | Root-enumerated PnP hardware ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdusb4net.inf` | AMD USB4NET | `root\AMDUSB4NET_d` | Root-enumerated PnP hardware ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdusb4pcifilter.inf` | PCI Express Root Port | `PCI\VEN_1022&DEV_14CD&SUBSYS_14531022&REV_00` | PCI-enumerated PnP hardware ID | `amdusb4pcifilter` | Native | Native | Excluded | Excluded | NotDeclared |
| `c0004\amdusb4pcifilter.inf` | PCI Express Root Port | `PCI\VEN_1022&DEV_14EF&SUBSYS_14531022&REV_00` | PCI-enumerated PnP hardware ID | `amdusb4pcifilter` | Native | Native | Excluded | Excluded | NotDeclared |
| `c0004\amdusb4pcifilter.inf` | PCI Express Root Port | `PCI\VEN_1022&DEV_14EF&SUBSYS_14531022&REV_01` | PCI-enumerated PnP hardware ID | `amdusb4pcifilter` | Native | Native | Excluded | Excluded | NotDeclared |
| `c0004\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15C0&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Excluded | Excluded | NotDeclared |
| `c0004\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15C1&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Excluded | Excluded | NotDeclared |
| `c0004\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15C2&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Excluded | Excluded | NotDeclared |
| `c0004\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15C3&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Excluded | Excluded | NotDeclared |
| `c0004\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15D6&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Excluded | Excluded | NotDeclared |
| `c0004\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15D7&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Excluded | Excluded | NotDeclared |
| `c0004\amdwirelessbutton.inf` | AMD Wireless Button Driver | `ACPI\AMDI0051` | ACPI-enumerated PnP hardware ID | `amdwirelessbutton_Device` | Native | Native | Native | Native | KMDF 1.15 |
| `c0004\ams_mailboxdrv.inf` | AMS-MailBoxDrv | `ACPI\AMDI0090` | ACPI-enumerated PnP hardware ID | `AMS-MailBoxDrv_Device` | Native | Native | Native | Native | NotDeclared |
| `c0004\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4353` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `c0004\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4363` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `c0004\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4372` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `c0004\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4385` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `c0004\smbusamd.inf` | AMD SMBus | `PCI\VEN_1022&DEV_780B` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `c0004\smbusamd.inf` | AMD SMBus | `PCI\VEN_1022&DEV_790B` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `c0004\usbfilter.inf` | AMD USB Filter Driver | `{36FC9E60-C465-11CF-8056-444553540000}\usbfilter` | Device-class-specific ID | `usbfilter` | Native | Native | Native | Native | NotDeclared |
| `c0004\zenpromnf.inf` | ZenProM S0i3 Network Filter | `ZenProMnf` | Network software component ID | `Install` | Native | Native | Native | Native | NotDeclared |

## AMD Chipset Software 5.08.02.027

| INF | Device | Device identifier | Identifier type | Install section | WS2016 | WS2019 | WS2022 | WS2025 | WDF |
|---|---|---|---|---|---|---|---|---|---|
| `c0004\amd3dvcache.inf` | AMD 3D V-Cache Performance Optimizer | `ACPI\AMDI0101` | ACPI-enumerated PnP hardware ID | `amd3dvcache_Device` | No(Build) | No(Build) | Native | Native | KMDF 1.15 |
| `c0004\amdas4.inf` | AmdAS4 Device | `ACPI\AMDI0050` | ACPI-enumerated PnP hardware ID | `AmdAS4` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdas4.inf` | AmdAS4 Device | `ACPI\ASD0001` | ACPI-enumerated PnP hardware ID | `AmdAS4` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdcir.inf` | AMD CIR Driver | `*AMDC001` | Generic PnP hardware ID | `AMDCIR64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdcir.inf` | AMD CIR Driver | `*AMDC002` | Generic PnP hardware ID | `AMDCIR64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdcir.inf` | AMD CIR Driver | `*AMDC003` | Generic PnP hardware ID | `AMDCIR64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdgpio2.inf` | AMD GPIO Controller | `ACPI\AMD0030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdgpio2.inf` | AMD GPIO Controller | `ACPI\AMDI0030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdgpio2.inf` | AMD GPIO Controller | `ACPI\AMDI0031` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdgpio2.inf` | AMD GPIO Controller | `ACPI\GPIO0010` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdgpio3.inf` | AMD GPIO Controller | `ACPI\AMDF030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdgpio3.inf` | AMD GPIO Controller | `ACPI\AMDIF030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdgpio3.inf` | AMD GPIO Controller | `ACPI\AMDIF031` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdi2c.inf` | AMD I2C Controller | `ACPI\AMD0010` | ACPI-enumerated PnP hardware ID | `amdi2c_Device` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdi2c.inf` | AMD I2C Controller | `ACPI\AMDI0010` | ACPI-enumerated PnP hardware ID | `amdi2c_Device` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdinterface.inf` | AMD Hetero Driver | `ACPI\AMDI0104` | ACPI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_14AC` | PCI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_14EC` | PCI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdinterface.inf` | AMD PCI | `PCI\VEN_1022&DEV_150D` | PCI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdinterface.inf` | AMD SMBUS | `PCI\VEN_1022&DEV_790B` | PCI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1002&DEV_5A23` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_13E1` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1419` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1423` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1437` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1451` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1481` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1577` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_164F` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMD0004` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMD0005` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0005` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0006` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0007` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0008` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0009` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdpcidev.inf` | AMD PCI | `PCI\VEN_1002&DEV_145A` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_1455` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_145A` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_1485` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_148A` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_14DE` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdpmf.inf` | AMD PMF | `ACPI\AMDI0100` | ACPI-enumerated PnP hardware ID | `AMDPMF_INSTALL.NTamd64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdpmf.inf` | AMD PMF | `ACPI\AMDI0102` | ACPI-enumerated PnP hardware ID | `AMDPMF_INSTALL.NTamd64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdppmpf.inf` | AMD PPM Provisioning File | `ACPI\AMDI0052` | ACPI-enumerated PnP hardware ID | `AMDPPMPF_DEV` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdpsp.inf` | AMD PSP 10.0 Device | `PCI\VEN_1022&DEV_15DF` | PCI-enumerated PnP hardware ID | `amdpsp_Device_100` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_1486` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_14CA` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_15C7` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_1649` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_13EC` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_1456` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_1537` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_1578` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdsfhkmdf.inf` | AMD Sensor Fusion Hub | `PCI\VEN_1022&DEV_15E4` | PCI-enumerated PnP hardware ID | `amdsfhkmdf_Device` | Native | Native | Native | Native | KMDF 1.15 |
| `c0004\amdsfhkmdfi2c.inf` | AMD SFH KMDF I2C | `PCI\VEN_1022&DEV_15E6` | PCI-enumerated PnP hardware ID | `amdsfhkmdf_Device` | Native | Native | Native | Native | KMDF 1.15 |
| `c0004\amdsfhspbi2c.inf` | AMD SFH I2C Controller | `ACPI\AMDI0011` | ACPI-enumerated PnP hardware ID | `amdsfhspbi2c_Device` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdsfhumdf.inf` | AMD UMDF Sensor | `ACPI\AMDI0080` | ACPI-enumerated PnP hardware ID | `amdsfhumdf_Inst` | Native | Native | Native | Native | UMDF 2.15.0 |
| `c0004\amduart.inf` | AMD UART Controller | `ACPI\AMD0020` | ACPI-enumerated PnP hardware ID | `amduart_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amduart.inf` | AMD UART Controller | `ACPI\AMDI0020` | ACPI-enumerated PnP hardware ID | `amduart_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amduart.inf` | AMD UART Controller | `ACPI\AMDI0022` | ACPI-enumerated PnP hardware ID | `amduart_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_15C4` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `c0004\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_15C5` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `c0004\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_162E` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `c0004\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_162F` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `c0004\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_1668` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `c0004\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_1669` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `c0004\amdusb4net.inf` | AMD USB4NET | `{b85b7c50-6a01-11d2-b841-00c04fad5171}\AMDUSB4NET` | Device-class-specific ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdusb4net.inf` | AMD USB4NET | `{b85b7c50-6a01-11d2-b841-00c04fad5171}\Usb4Net` | Device-class-specific ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdusb4net.inf` | AMD USB4NET | `root\AMDUSB4NET_a` | Root-enumerated PnP hardware ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdusb4net.inf` | AMD USB4NET | `root\AMDUSB4NET_b` | Root-enumerated PnP hardware ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdusb4net.inf` | AMD USB4NET | `root\AMDUSB4NET_c` | Root-enumerated PnP hardware ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdusb4net.inf` | AMD USB4NET | `root\AMDUSB4NET_d` | Root-enumerated PnP hardware ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdusb4pcifilter.inf` | PCI Express Root Port | `PCI\VEN_1022&DEV_14CD&SUBSYS_14531022&REV_00` | PCI-enumerated PnP hardware ID | `amdusb4pcifilter` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdusb4pcifilter.inf` | PCI Express Root Port | `PCI\VEN_1022&DEV_14EF&SUBSYS_14531022&REV_00` | PCI-enumerated PnP hardware ID | `amdusb4pcifilter` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdusb4pcifilter.inf` | PCI Express Root Port | `PCI\VEN_1022&DEV_14EF&SUBSYS_14531022&REV_01` | PCI-enumerated PnP hardware ID | `amdusb4pcifilter` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15C0&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15C1&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15C2&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15C3&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15D6&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15D7&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdwirelessbutton.inf` | AMD Wireless Button Driver | `ACPI\AMDI0051` | ACPI-enumerated PnP hardware ID | `amdwirelessbutton_Device` | Native | Native | Native | Native | KMDF 1.15 |
| `c0004\ams_mailboxdrv.inf` | AMS-MailBoxDrv | `ACPI\AMDI0090` | ACPI-enumerated PnP hardware ID | `AMS-MailBoxDrv_Device` | Native | Native | Native | Native | NotDeclared |
| `c0004\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4353` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `c0004\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4363` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `c0004\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4372` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `c0004\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4385` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `c0004\smbusamd.inf` | AMD SMBus | `PCI\VEN_1022&DEV_780B` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `c0004\smbusamd.inf` | AMD SMBus | `PCI\VEN_1022&DEV_790B` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `c0004\usbfilter.inf` | AMD USB Filter Driver | `{36FC9E60-C465-11CF-8056-444553540000}\usbfilter` | Device-class-specific ID | `usbfilter` | Native | Native | Native | Native | NotDeclared |
| `c0004\zenpromnf.inf` | ZenProM S0i3 Network Filter | `ZenProMnf` | Network software component ID | `Install` | Native | Native | Native | Native | NotDeclared |

## AMD Chipset Software 5.05.16.529

| INF | Device | Device identifier | Identifier type | Install section | WS2016 | WS2019 | WS2022 | WS2025 | WDF |
|---|---|---|---|---|---|---|---|---|---|
| `c0004\amd3dvcache.inf` | AMD 3D V-Cache Performance Optimizer | `ACPI\AMDI0101` | ACPI-enumerated PnP hardware ID | `amd3dvcache_Device` | No(Build) | No(Build) | Native | Native | KMDF 1.15 |
| `c0004\amdas4.inf` | AmdAS4 Device | `ACPI\AMDI0050` | ACPI-enumerated PnP hardware ID | `AmdAS4` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdas4.inf` | AmdAS4 Device | `ACPI\ASD0001` | ACPI-enumerated PnP hardware ID | `AmdAS4` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdcir.inf` | AMD CIR Driver | `*AMDC001` | Generic PnP hardware ID | `AMDCIR64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdcir.inf` | AMD CIR Driver | `*AMDC002` | Generic PnP hardware ID | `AMDCIR64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdcir.inf` | AMD CIR Driver | `*AMDC003` | Generic PnP hardware ID | `AMDCIR64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdgpio2.inf` | AMD GPIO Controller | `ACPI\AMD0030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdgpio2.inf` | AMD GPIO Controller | `ACPI\AMDI0030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdgpio2.inf` | AMD GPIO Controller | `ACPI\AMDI0031` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdgpio2.inf` | AMD GPIO Controller | `ACPI\GPIO0010` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdgpio3.inf` | AMD GPIO Controller | `ACPI\AMDF030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdgpio3.inf` | AMD GPIO Controller | `ACPI\AMDIF030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdgpio3.inf` | AMD GPIO Controller | `ACPI\AMDIF031` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdi2c.inf` | AMD I2C Controller | `ACPI\AMD0010` | ACPI-enumerated PnP hardware ID | `amdi2c_Device` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdi2c.inf` | AMD I2C Controller | `ACPI\AMDI0010` | ACPI-enumerated PnP hardware ID | `amdi2c_Device` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1002&DEV_5A23` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_13E1` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1419` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1423` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1437` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1451` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1481` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1577` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_164F` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMD0004` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMD0005` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0005` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0006` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0007` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0008` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0009` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdpcidev.inf` | AMD PCI | `PCI\VEN_1002&DEV_145A` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_1455` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_145A` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_1485` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_148A` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_14DE` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdpmf.inf` | AMD PMF | `ACPI\AMDI0100` | ACPI-enumerated PnP hardware ID | `AMDPMF_INSTALL.NTamd64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdpmf.inf` | AMD PMF | `ACPI\AMDI0102` | ACPI-enumerated PnP hardware ID | `AMDPMF_INSTALL.NTamd64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdppmpf.inf` | AMD PPM Provisioning File | `ACPI\AMDI0052` | ACPI-enumerated PnP hardware ID | `AMDPPMPF_DEV` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdpsp.inf` | AMD PSP 10.0 Device | `PCI\VEN_1022&DEV_15DF` | PCI-enumerated PnP hardware ID | `amdpsp_Device_100` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_1486` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_14CA` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_15C7` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_1649` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_13EC` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_1456` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_1537` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_1578` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdsfhkmdf.inf` | AMD Sensor Fusion Hub | `PCI\VEN_1022&DEV_15E4` | PCI-enumerated PnP hardware ID | `amdsfhkmdf_Device` | Native | Native | Native | Native | KMDF 1.15 |
| `c0004\amdsfhkmdfi2c.inf` | AMD SFH KMDF I2C | `PCI\VEN_1022&DEV_15E6` | PCI-enumerated PnP hardware ID | `amdsfhkmdf_Device` | Native | Native | Native | Native | KMDF 1.15 |
| `c0004\amdsfhspbi2c.inf` | AMD SFH I2C Controller | `ACPI\AMDI0011` | ACPI-enumerated PnP hardware ID | `amdsfhspbi2c_Device` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdsfhumdf.inf` | AMD UMDF Sensor | `ACPI\AMDI0080` | ACPI-enumerated PnP hardware ID | `amdsfhumdf_Inst` | Native | Native | Native | Native | UMDF 2.15.0 |
| `c0004\amduart.inf` | AMD UART Controller | `ACPI\AMD0020` | ACPI-enumerated PnP hardware ID | `amduart_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amduart.inf` | AMD UART Controller | `ACPI\AMDI0020` | ACPI-enumerated PnP hardware ID | `amduart_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amduart.inf` | AMD UART Controller | `ACPI\AMDI0022` | ACPI-enumerated PnP hardware ID | `amduart_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_15C4` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `c0004\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_15C5` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `c0004\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_162E` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `c0004\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_162F` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `c0004\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_1668` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `c0004\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_1669` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `c0004\amdusb4net.inf` | AMD USB4NET | `{b85b7c50-6a01-11d2-b841-00c04fad5171}\AMDUSB4NET` | Device-class-specific ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdusb4net.inf` | AMD USB4NET | `{b85b7c50-6a01-11d2-b841-00c04fad5171}\Usb4Net` | Device-class-specific ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdusb4net.inf` | AMD USB4NET | `root\AMDUSB4NET_a` | Root-enumerated PnP hardware ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdusb4net.inf` | AMD USB4NET | `root\AMDUSB4NET_b` | Root-enumerated PnP hardware ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdusb4net.inf` | AMD USB4NET | `root\AMDUSB4NET_c` | Root-enumerated PnP hardware ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdusb4net.inf` | AMD USB4NET | `root\AMDUSB4NET_d` | Root-enumerated PnP hardware ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdusb4pcifilter.inf` | PCI Express Root Port | `PCI\VEN_1022&DEV_14CD&SUBSYS_14531022&REV_00` | PCI-enumerated PnP hardware ID | `amdusb4pcifilter` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdusb4pcifilter.inf` | PCI Express Root Port | `PCI\VEN_1022&DEV_14EF&SUBSYS_14531022&REV_00` | PCI-enumerated PnP hardware ID | `amdusb4pcifilter` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdusb4pcifilter.inf` | PCI Express Root Port | `PCI\VEN_1022&DEV_14EF&SUBSYS_14531022&REV_01` | PCI-enumerated PnP hardware ID | `amdusb4pcifilter` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15C0&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15C1&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15C2&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15C3&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15D6&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15D7&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdwirelessbutton.inf` | AMD Wireless Button Driver | `ACPI\AMDI0051` | ACPI-enumerated PnP hardware ID | `amdwirelessbutton_Device` | Native | Native | Native | Native | KMDF 1.15 |
| `c0004\ams_mailboxdrv.inf` | AMS-MailBoxDrv | `ACPI\AMDI0090` | ACPI-enumerated PnP hardware ID | `AMS-MailBoxDrv_Device` | Native | Native | Native | Native | NotDeclared |
| `c0004\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4353` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `c0004\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4363` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `c0004\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4372` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `c0004\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4385` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `c0004\smbusamd.inf` | AMD SMBus | `PCI\VEN_1022&DEV_780B` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `c0004\smbusamd.inf` | AMD SMBus | `PCI\VEN_1022&DEV_790B` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `c0004\usbfilter.inf` | AMD USB Filter Driver | `{36FC9E60-C465-11CF-8056-444553540000}\usbfilter` | Device-class-specific ID | `usbfilter` | Native | Native | Native | Native | NotDeclared |
| `c0004\zenpromnf.inf` | ZenProM S0i3 Network Filter | `ZenProMnf` | Network software component ID | `Install` | Native | Native | Native | Native | NotDeclared |

## AMD Chipset Software 5.02.19.2221

| INF | Device | Device identifier | Identifier type | Install section | WS2016 | WS2019 | WS2022 | WS2025 | WDF |
|---|---|---|---|---|---|---|---|---|---|
| `c0004\amd3dvcache.inf` | AMD 3D V-Cache Performance Optimizer | `ACPI\AMDI0101` | ACPI-enumerated PnP hardware ID | `amd3dvcache_Device` | No(Build) | No(Build) | Native | Native | KMDF 1.15 |
| `c0004\amdas4.inf` | AmdAS4 Device | `ACPI\AMDI0050` | ACPI-enumerated PnP hardware ID | `AmdAS4` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdas4.inf` | AmdAS4 Device | `ACPI\ASD0001` | ACPI-enumerated PnP hardware ID | `AmdAS4` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdcir.inf` | AMD CIR Driver | `*AMDC001` | Generic PnP hardware ID | `AMDCIR64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdcir.inf` | AMD CIR Driver | `*AMDC002` | Generic PnP hardware ID | `AMDCIR64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdcir.inf` | AMD CIR Driver | `*AMDC003` | Generic PnP hardware ID | `AMDCIR64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdgpio2.inf` | AMD GPIO Controller | `ACPI\AMD0030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdgpio2.inf` | AMD GPIO Controller | `ACPI\AMDI0030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdgpio2.inf` | AMD GPIO Controller | `ACPI\AMDI0031` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdgpio2.inf` | AMD GPIO Controller | `ACPI\GPIO0010` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdgpio3.inf` | AMD GPIO Controller | `ACPI\AMDF030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdgpio3.inf` | AMD GPIO Controller | `ACPI\AMDIF030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdgpio3.inf` | AMD GPIO Controller | `ACPI\AMDIF031` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdi2c.inf` | AMD I2C Controller | `ACPI\AMD0010` | ACPI-enumerated PnP hardware ID | `amdi2c_Device` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdi2c.inf` | AMD I2C Controller | `ACPI\AMDI0010` | ACPI-enumerated PnP hardware ID | `amdi2c_Device` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1002&DEV_5A23` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_13E1` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1419` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1423` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1437` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1451` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1481` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1577` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_164F` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMD0004` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMD0005` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0005` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0006` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0007` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0008` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0009` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdpcidev.inf` | AMD PCI | `PCI\VEN_1002&DEV_145A` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_1455` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_145A` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_1485` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_148A` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_14DE` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdpmf.inf` | AMD PMF | `ACPI\AMDI0100` | ACPI-enumerated PnP hardware ID | `AMDPMF_INSTALL.NTamd64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdpmf.inf` | AMD PMF | `ACPI\AMDI0102` | ACPI-enumerated PnP hardware ID | `AMDPMF_INSTALL.NTamd64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdppmpf.inf` | AMD PPM Provisioning File | `ACPI\AMDI0052` | ACPI-enumerated PnP hardware ID | `AMDPPMPF_DEV` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdpsp.inf` | AMD PSP 10.0 Device | `PCI\VEN_1022&DEV_15DF` | PCI-enumerated PnP hardware ID | `amdpsp_Device_100` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdpsp.inf` | AMD PSP 10.0 Device | `PCI\VEN_1022&DEV_1649` | PCI-enumerated PnP hardware ID | `amdpsp_Device_100` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_1486` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_14CA` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_15C7` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_13EC` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_1456` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_1537` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_1578` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdsfhkmdf.inf` | AMD Sensor Fusion Hub | `PCI\VEN_1022&DEV_15E4` | PCI-enumerated PnP hardware ID | `amdsfhkmdf_Device` | Native | Native | Native | Native | KMDF 1.15 |
| `c0004\amdsfhkmdfi2c.inf` | AMD SFH KMDF I2C | `PCI\VEN_1022&DEV_15E6` | PCI-enumerated PnP hardware ID | `amdsfhkmdf_Device` | Native | Native | Native | Native | KMDF 1.15 |
| `c0004\amdsfhspbi2c.inf` | AMD SFH I2C Controller | `ACPI\AMDI0011` | ACPI-enumerated PnP hardware ID | `amdsfhspbi2c_Device` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdsfhumdf.inf` | AMD UMDF Sensor | `ACPI\AMDI0080` | ACPI-enumerated PnP hardware ID | `amdsfhumdf_Inst` | Native | Native | Native | Native | UMDF 2.15.0 |
| `c0004\amduart.inf` | AMD UART Controller | `ACPI\AMD0020` | ACPI-enumerated PnP hardware ID | `amduart_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amduart.inf` | AMD UART Controller | `ACPI\AMDI0020` | ACPI-enumerated PnP hardware ID | `amduart_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amduart.inf` | AMD UART Controller | `ACPI\AMDI0022` | ACPI-enumerated PnP hardware ID | `amduart_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_15C4` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `c0004\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_15C5` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `c0004\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_162E` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `c0004\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_162F` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `c0004\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_1668` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `c0004\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_1669` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `c0004\amdusb4pcifilter.inf` | PCI Express Root Port | `PCI\VEN_1022&DEV_14CD&SUBSYS_14531022&REV_00` | PCI-enumerated PnP hardware ID | `amdusb4pcifilter` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdusb4pcifilter.inf` | PCI Express Root Port | `PCI\VEN_1022&DEV_14EF&SUBSYS_14531022&REV_00` | PCI-enumerated PnP hardware ID | `amdusb4pcifilter` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdusb4pcifilter.inf` | PCI Express Root Port | `PCI\VEN_1022&DEV_14EF&SUBSYS_14531022&REV_01` | PCI-enumerated PnP hardware ID | `amdusb4pcifilter` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15C0&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15C1&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15C2&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15C3&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15D6&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15D7&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdwirelessbutton.inf` | AMD Wireless Button Driver | `ACPI\AMDI0051` | ACPI-enumerated PnP hardware ID | `amdwirelessbutton_Device` | Native | Native | Native | Native | KMDF 1.15 |
| `c0004\ams_mailboxdrv.inf` | AMS-MailBoxDrv | `ACPI\AMDI0090` | ACPI-enumerated PnP hardware ID | `AMS-MailBoxDrv_Device` | Native | Native | Native | Native | NotDeclared |
| `c0004\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4353` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `c0004\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4363` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `c0004\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4372` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `c0004\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4385` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `c0004\smbusamd.inf` | AMD SMBus | `PCI\VEN_1022&DEV_780B` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `c0004\smbusamd.inf` | AMD SMBus | `PCI\VEN_1022&DEV_790B` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `c0004\usbfilter.inf` | AMD USB Filter Driver | `{36FC9E60-C465-11CF-8056-444553540000}\usbfilter` | Device-class-specific ID | `usbfilter` | Native | Native | Native | Native | NotDeclared |
| `c0004\zenpromnf.inf` | ZenProM S0i3 Network Filter | `ZenProMnf` | Network software component ID | `Install` | Native | Native | Native | Native | NotDeclared |

## AMD Chipset Software 4.11.15.342

| INF | Device | Device identifier | Identifier type | Install section | WS2016 | WS2019 | WS2022 | WS2025 | WDF |
|---|---|---|---|---|---|---|---|---|---|
| `c0004\amdas4.inf` | AmdAS4 Device | `ACPI\AMDI0050` | ACPI-enumerated PnP hardware ID | `AmdAS4` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdas4.inf` | AmdAS4 Device | `ACPI\ASD0001` | ACPI-enumerated PnP hardware ID | `AmdAS4` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdcir.inf` | AMD CIR Driver | `*AMDC001` | Generic PnP hardware ID | `AMDCIR64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdcir.inf` | AMD CIR Driver | `*AMDC002` | Generic PnP hardware ID | `AMDCIR64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdcir.inf` | AMD CIR Driver | `*AMDC003` | Generic PnP hardware ID | `AMDCIR64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdgpio2.inf` | AMD GPIO Controller | `ACPI\AMD0030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdgpio2.inf` | AMD GPIO Controller | `ACPI\AMDI0030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdgpio2.inf` | AMD GPIO Controller | `ACPI\AMDI0031` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdgpio2.inf` | AMD GPIO Controller | `ACPI\GPIO0010` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdgpio3.inf` | AMD GPIO Controller | `ACPI\AMDF030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdgpio3.inf` | AMD GPIO Controller | `ACPI\AMDIF030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdgpio3.inf` | AMD GPIO Controller | `ACPI\AMDIF031` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdi2c.inf` | AMD I2C Controller | `ACPI\AMD0010` | ACPI-enumerated PnP hardware ID | `amdi2c_Device` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdi2c.inf` | AMD I2C Controller | `ACPI\AMDI0010` | ACPI-enumerated PnP hardware ID | `amdi2c_Device` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1002&DEV_5A23` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_13E1` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1419` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1423` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1437` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1451` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1481` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1577` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_164F` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMD0004` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMD0005` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0005` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0006` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0007` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0008` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0009` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdpcidev.inf` | AMD PCI | `PCI\VEN_1002&DEV_145A` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_1455` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_145A` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_1485` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_148A` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_14DE` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdpmf.inf` | AMD PMF | `ACPI\AMDI0100` | ACPI-enumerated PnP hardware ID | `AMDPMF_INSTALL.NTamd64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdpmf.inf` | AMD PMF | `ACPI\AMDI0102` | ACPI-enumerated PnP hardware ID | `AMDPMF_INSTALL.NTamd64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdppmpf.inf` | AMD PPM Provisioning File | `ACPI\AMDI0052` | ACPI-enumerated PnP hardware ID | `AMDPPMPF_DEV` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdpsp.inf` | AMD PSP 10.0 Device | `PCI\VEN_1022&DEV_15DF` | PCI-enumerated PnP hardware ID | `amdpsp_Device_100` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdpsp.inf` | AMD PSP 10.0 Device | `PCI\VEN_1022&DEV_1649` | PCI-enumerated PnP hardware ID | `amdpsp_Device_100` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_1486` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_14CA` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_15C7` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_13EC` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_1456` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_1537` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_1578` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdsfhkmdf.inf` | AMD Sensor Fusion Hub | `PCI\VEN_1022&DEV_15E4` | PCI-enumerated PnP hardware ID | `amdsfhkmdf_Device` | Native | Native | Native | Native | KMDF 1.15 |
| `c0004\amdsfhkmdfi2c.inf` | AMD SFH KMDF I2C | `PCI\VEN_1022&DEV_15E6` | PCI-enumerated PnP hardware ID | `amdsfhkmdf_Device` | Native | Native | Native | Native | KMDF 1.15 |
| `c0004\amdsfhspbi2c.inf` | AMD SFH I2C Controller | `ACPI\AMDI0011` | ACPI-enumerated PnP hardware ID | `amdsfhspbi2c_Device` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdsfhumdf.inf` | AMD UMDF Sensor | `ACPI\AMDI0080` | ACPI-enumerated PnP hardware ID | `amdsfhumdf_Inst` | Native | Native | Native | Native | UMDF 2.15.0 |
| `c0004\amduart.inf` | AMD UART Controller | `ACPI\AMD0020` | ACPI-enumerated PnP hardware ID | `amduart_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amduart.inf` | AMD UART Controller | `ACPI\AMDI0020` | ACPI-enumerated PnP hardware ID | `amduart_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amduart.inf` | AMD UART Controller | `ACPI\AMDI0022` | ACPI-enumerated PnP hardware ID | `amduart_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_162E` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `c0004\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_162F` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `c0004\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_1668` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `c0004\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_1669` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `c0004\amdusb4pcifilter.inf` | PCI Express Root Port | `PCI\VEN_1022&DEV_14CD&SUBSYS_14531022&REV_00` | PCI-enumerated PnP hardware ID | `amdusb4pcifilter` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdusb4pcifilter.inf` | PCI Express Root Port | `PCI\VEN_1022&DEV_14EF&SUBSYS_14531022&REV_00` | PCI-enumerated PnP hardware ID | `amdusb4pcifilter` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15C0&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15C1&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15D6&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15D7&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdwirelessbutton.inf` | AMD Wireless Button Driver | `ACPI\AMDI0051` | ACPI-enumerated PnP hardware ID | `amdwirelessbutton_Device` | Native | Native | Native | Native | KMDF 1.15 |
| `c0004\ams_mailboxdrv.inf` | AMS-MailBoxDrv | `ACPI\AMDI0090` | ACPI-enumerated PnP hardware ID | `AMS-MailBoxDrv_Device` | Native | Native | Native | Native | NotDeclared |
| `c0004\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4353` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `c0004\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4363` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `c0004\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4372` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `c0004\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4385` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `c0004\smbusamd.inf` | AMD SMBus | `PCI\VEN_1022&DEV_780B` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `c0004\smbusamd.inf` | AMD SMBus | `PCI\VEN_1022&DEV_790B` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `c0004\usbfilter.inf` | AMD USB Filter Driver | `{36FC9E60-C465-11CF-8056-444553540000}\usbfilter` | Device-class-specific ID | `usbfilter` | Native | Native | Native | Native | NotDeclared |
| `c0004\zenpromnf.inf` | ZenProM S0i3 Network Filter | `ZenProMnf` | Network software component ID | `Install` | Native | Native | Native | Native | NotDeclared |

## AMD Chipset Software 4.09.23.507

| INF | Device | Device identifier | Identifier type | Install section | WS2016 | WS2019 | WS2022 | WS2025 | WDF |
|---|---|---|---|---|---|---|---|---|---|
| `c0004\amdas4.inf` | AmdAS4 Device | `ACPI\AMDI0050` | ACPI-enumerated PnP hardware ID | `AmdAS4` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdas4.inf` | AmdAS4 Device | `ACPI\ASD0001` | ACPI-enumerated PnP hardware ID | `AmdAS4` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdcir.inf` | AMD CIR Driver | `*AMDC001` | Generic PnP hardware ID | `AMDCIR64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdcir.inf` | AMD CIR Driver | `*AMDC002` | Generic PnP hardware ID | `AMDCIR64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdcir.inf` | AMD CIR Driver | `*AMDC003` | Generic PnP hardware ID | `AMDCIR64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdgpio2.inf` | AMD GPIO Controller | `ACPI\AMD0030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdgpio2.inf` | AMD GPIO Controller | `ACPI\AMDI0030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdgpio2.inf` | AMD GPIO Controller | `ACPI\AMDI0031` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdgpio2.inf` | AMD GPIO Controller | `ACPI\GPIO0010` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdgpio3.inf` | AMD GPIO Controller | `ACPI\AMDF030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdgpio3.inf` | AMD GPIO Controller | `ACPI\AMDIF030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdgpio3.inf` | AMD GPIO Controller | `ACPI\AMDIF031` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdi2c.inf` | AMD I2C Controller | `ACPI\AMD0010` | ACPI-enumerated PnP hardware ID | `amdi2c_Device` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdi2c.inf` | AMD I2C Controller | `ACPI\AMDI0010` | ACPI-enumerated PnP hardware ID | `amdi2c_Device` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1002&DEV_5A23` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_13E1` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1419` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1423` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1437` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1451` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1481` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1577` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_164F` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMD0004` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMD0005` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0005` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0006` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0007` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0008` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdpcidev.inf` | AMD PCI | `PCI\VEN_1002&DEV_145A` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_1455` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_145A` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_1485` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_148A` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_14DE` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdpmf.inf` | AMD PMF | `ACPI\AMDI0100` | ACPI-enumerated PnP hardware ID | `AMDPMF_INSTALL.NTamd64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdpmf.inf` | AMD PMF | `ACPI\AMDI0102` | ACPI-enumerated PnP hardware ID | `AMDPMF_INSTALL.NTamd64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdppmpf.inf` | AMD PPM Provisioning File | `ACPI\AMDI0052` | ACPI-enumerated PnP hardware ID | `AMDPPMPF_DEV` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdpsp.inf` | AMD PSP 10.0 Device | `PCI\VEN_1022&DEV_15DF` | PCI-enumerated PnP hardware ID | `amdpsp_Device_100` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdpsp.inf` | AMD PSP 10.0 Device | `PCI\VEN_1022&DEV_1649` | PCI-enumerated PnP hardware ID | `amdpsp_Device_100` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_1486` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_13EC` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_1456` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_14CA` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_1537` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_1578` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdsfhkmdf.inf` | AMD Sensor Fusion Hub | `PCI\VEN_1022&DEV_15E4` | PCI-enumerated PnP hardware ID | `amdsfhkmdf_Device` | Native | Native | Native | Native | KMDF 1.15 |
| `c0004\amdsfhkmdfi2c.inf` | AMD SFH KMDF I2C | `PCI\VEN_1022&DEV_15E6` | PCI-enumerated PnP hardware ID | `amdsfhkmdf_Device` | Native | Native | Native | Native | KMDF 1.15 |
| `c0004\amdsfhspbi2c.inf` | AMD SFH I2C Controller | `ACPI\AMDI0011` | ACPI-enumerated PnP hardware ID | `amdsfhspbi2c_Device` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdsfhumdf.inf` | AMD UMDF Sensor | `ACPI\AMDI0080` | ACPI-enumerated PnP hardware ID | `amdsfhumdf_Inst` | Native | Native | Native | Native | UMDF 2.15.0 |
| `c0004\amduart.inf` | AMD UART Controller | `ACPI\AMD0020` | ACPI-enumerated PnP hardware ID | `amduart_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amduart.inf` | AMD UART Controller | `ACPI\AMDI0020` | ACPI-enumerated PnP hardware ID | `amduart_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amduart.inf` | AMD UART Controller | `ACPI\AMDI0022` | ACPI-enumerated PnP hardware ID | `amduart_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_162E` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `c0004\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_162F` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `c0004\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_1668` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `c0004\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_1669` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `c0004\amdusb4pcifilter.inf` | PCI Express Root Port | `PCI\VEN_1022&DEV_14CD&SUBSYS_14531022&REV_00` | PCI-enumerated PnP hardware ID | `amdusb4pcifilter` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdusb4pcifilter.inf` | PCI Express Root Port | `PCI\VEN_1022&DEV_14EF&SUBSYS_14531022&REV_00` | PCI-enumerated PnP hardware ID | `amdusb4pcifilter` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15C0&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15C1&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15D6&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15D7&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdwirelessbutton.inf` | AMD Wireless Button Driver | `ACPI\AMDI0051` | ACPI-enumerated PnP hardware ID | `amdwirelessbutton_Device` | Native | Native | Native | Native | KMDF 1.15 |
| `c0004\ams_mailboxdrv.inf` | AMS-MailBoxDrv | `ACPI\AMDI0090` | ACPI-enumerated PnP hardware ID | `AMS-MailBoxDrv_Device` | Native | Native | Native | Native | NotDeclared |
| `c0004\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4353` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `c0004\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4363` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `c0004\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4372` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `c0004\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4385` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `c0004\smbusamd.inf` | AMD SMBus | `PCI\VEN_1022&DEV_780B` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `c0004\smbusamd.inf` | AMD SMBus | `PCI\VEN_1022&DEV_790B` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `c0004\usbfilter.inf` | AMD USB Filter Driver | `{36FC9E60-C465-11CF-8056-444553540000}\usbfilter` | Device-class-specific ID | `usbfilter` | Native | Native | Native | Native | NotDeclared |
| `c0004\zenpromnf.inf` | ZenProM S0i3 Network Filter | `ZenProMnf` | Network software component ID | `Install` | Native | Native | Native | Native | NotDeclared |

## AMD Chipset Software 4.08.09.2337

| INF | Device | Device identifier | Identifier type | Install section | WS2016 | WS2019 | WS2022 | WS2025 | WDF |
|---|---|---|---|---|---|---|---|---|---|
| `c0004\amdas4.inf` | AmdAS4 Device | `ACPI\AMDI0050` | ACPI-enumerated PnP hardware ID | `AmdAS4` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdas4.inf` | AmdAS4 Device | `ACPI\ASD0001` | ACPI-enumerated PnP hardware ID | `AmdAS4` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdcir.inf` | AMD CIR Driver | `*AMDC001` | Generic PnP hardware ID | `AMDCIR64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdcir.inf` | AMD CIR Driver | `*AMDC002` | Generic PnP hardware ID | `AMDCIR64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdcir.inf` | AMD CIR Driver | `*AMDC003` | Generic PnP hardware ID | `AMDCIR64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdgpio2.inf` | AMD GPIO Controller | `ACPI\AMD0030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdgpio2.inf` | AMD GPIO Controller | `ACPI\AMDI0030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdgpio2.inf` | AMD GPIO Controller | `ACPI\AMDI0031` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdgpio2.inf` | AMD GPIO Controller | `ACPI\GPIO0010` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdgpio3.inf` | AMD GPIO Controller | `ACPI\AMDF030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdgpio3.inf` | AMD GPIO Controller | `ACPI\AMDIF030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdgpio3.inf` | AMD GPIO Controller | `ACPI\AMDIF031` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdi2c.inf` | AMD I2C Controller | `ACPI\AMD0010` | ACPI-enumerated PnP hardware ID | `amdi2c_Device` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdi2c.inf` | AMD I2C Controller | `ACPI\AMDI0010` | ACPI-enumerated PnP hardware ID | `amdi2c_Device` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1002&DEV_5A23` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_13E1` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1419` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1423` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1437` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1451` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1481` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1577` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_164F` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMD0004` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMD0005` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0005` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0006` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0007` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0008` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdpcidev.inf` | AMD PCI | `PCI\VEN_1002&DEV_145A` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_1455` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_145A` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_1485` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_148A` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_14DE` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdpmf.inf` | AMD PMF | `ACPI\AMDI0100` | ACPI-enumerated PnP hardware ID | `AMDPMF_INSTALL.NTamd64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdpmf.inf` | AMD PMF | `ACPI\AMDI0102` | ACPI-enumerated PnP hardware ID | `AMDPMF_INSTALL.NTamd64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdppmpf.inf` | AMD PPM Provisioning File | `ACPI\AMDI0052` | ACPI-enumerated PnP hardware ID | `AMDPPMPF_DEV` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdpsp.inf` | AMD PSP 10.0 Device | `PCI\VEN_1022&DEV_15DF` | PCI-enumerated PnP hardware ID | `amdpsp_Device_100` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdpsp.inf` | AMD PSP 10.0 Device | `PCI\VEN_1022&DEV_1649` | PCI-enumerated PnP hardware ID | `amdpsp_Device_100` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_1486` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_13EC` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_1456` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_14CA` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_1537` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_1578` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdsfhkmdf.inf` | AMD Sensor Fusion Hub | `PCI\VEN_1022&DEV_15E4` | PCI-enumerated PnP hardware ID | `amdsfhkmdf_Device` | Native | Native | Native | Native | KMDF 1.15 |
| `c0004\amdsfhkmdfi2c.inf` | AMD SFH KMDF I2C | `PCI\VEN_1022&DEV_15E6` | PCI-enumerated PnP hardware ID | `amdsfhkmdf_Device` | Native | Native | Native | Native | KMDF 1.15 |
| `c0004\amdsfhspbi2c.inf` | AMD SFH I2C Controller | `ACPI\AMDI0011` | ACPI-enumerated PnP hardware ID | `amdsfhspbi2c_Device` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdsfhumdf.inf` | AMD UMDF Sensor | `ACPI\AMDI0080` | ACPI-enumerated PnP hardware ID | `amdsfhumdf_Inst` | Native | Native | Native | Native | UMDF 2.15.0 |
| `c0004\amduart.inf` | AMD UART Controller | `ACPI\AMD0020` | ACPI-enumerated PnP hardware ID | `amduart_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amduart.inf` | AMD UART Controller | `ACPI\AMDI0020` | ACPI-enumerated PnP hardware ID | `amduart_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amduart.inf` | AMD UART Controller | `ACPI\AMDI0022` | ACPI-enumerated PnP hardware ID | `amduart_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_162E` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `c0004\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_162F` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `c0004\amdusb4pcifilter.inf` | PCI Express Root Port | `PCI\VEN_1022&DEV_14CD&SUBSYS_14531022&REV_00` | PCI-enumerated PnP hardware ID | `amdusb4pcifilter` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15D6&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15D7&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdwirelessbutton.inf` | AMD Wireless Button Driver | `ACPI\AMDI0051` | ACPI-enumerated PnP hardware ID | `amdwirelessbutton_Device` | Native | Native | Native | Native | KMDF 1.15 |
| `c0004\ams_mailboxdrv.inf` | AMS-MailBoxDrv | `ACPI\AMDI0090` | ACPI-enumerated PnP hardware ID | `AMS-MailBoxDrv_Device` | Native | Native | Native | Native | NotDeclared |
| `c0004\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4353` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `c0004\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4363` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `c0004\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4372` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `c0004\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4385` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `c0004\smbusamd.inf` | AMD SMBus | `PCI\VEN_1022&DEV_780B` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `c0004\smbusamd.inf` | AMD SMBus | `PCI\VEN_1022&DEV_790B` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `c0004\usbfilter.inf` | AMD USB Filter Driver | `{36FC9E60-C465-11CF-8056-444553540000}\usbfilter` | Device-class-specific ID | `usbfilter` | Native | Native | Native | Native | NotDeclared |
| `c0004\zenpromnf.inf` | ZenProM S0i3 Network Filter | `ZenProMnf` | Network software component ID | `Install` | Native | Native | Native | Native | NotDeclared |

## AMD Chipset Software 4.06.10.651

| INF | Device | Device identifier | Identifier type | Install section | WS2016 | WS2019 | WS2022 | WS2025 | WDF |
|---|---|---|---|---|---|---|---|---|---|
| `c0004\amdas4.inf` | AmdAS4 Device | `ACPI\AMDI0050` | ACPI-enumerated PnP hardware ID | `AmdAS4` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdas4.inf` | AmdAS4 Device | `ACPI\ASD0001` | ACPI-enumerated PnP hardware ID | `AmdAS4` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdcir.inf` | AMD CIR Driver | `*AMDC001` | Generic PnP hardware ID | `AMDCIR64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdcir.inf` | AMD CIR Driver | `*AMDC002` | Generic PnP hardware ID | `AMDCIR64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdcir.inf` | AMD CIR Driver | `*AMDC003` | Generic PnP hardware ID | `AMDCIR64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdgpio2.inf` | AMD GPIO Controller | `ACPI\AMD0030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdgpio2.inf` | AMD GPIO Controller | `ACPI\AMDI0030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdgpio2.inf` | AMD GPIO Controller | `ACPI\AMDI0031` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdgpio2.inf` | AMD GPIO Controller | `ACPI\GPIO0010` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdgpio3.inf` | AMD GPIO Controller | `ACPI\AMDF030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdgpio3.inf` | AMD GPIO Controller | `ACPI\AMDIF030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdgpio3.inf` | AMD GPIO Controller | `ACPI\AMDIF031` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdi2c.inf` | AMD I2C Controller | `ACPI\AMD0010` | ACPI-enumerated PnP hardware ID | `amdi2c_Device` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdi2c.inf` | AMD I2C Controller | `ACPI\AMDI0010` | ACPI-enumerated PnP hardware ID | `amdi2c_Device` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1002&DEV_5A23` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_13E1` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1419` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1423` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1437` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1451` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1481` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1577` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_164F` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMD0004` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMD0005` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0005` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0006` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0007` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0008` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdpcidev.inf` | AMD PCI | `PCI\VEN_1002&DEV_145A` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_1455` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_145A` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_1485` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_148A` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_14DE` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdpmf.inf` | AMD PMF | `ACPI\AMDI0100` | ACPI-enumerated PnP hardware ID | `AMDPMF_INSTALL.NTamd64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdpmf.inf` | AMD PMF | `ACPI\AMDI0102` | ACPI-enumerated PnP hardware ID | `AMDPMF_INSTALL.NTamd64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdppmpf.inf` | AMD PPM Provisioning File | `ACPI\AMDI0052` | ACPI-enumerated PnP hardware ID | `AMDPPMPF_DEV` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdpsp.inf` | AMD PSP 10.0 Device | `PCI\VEN_1022&DEV_15DF` | PCI-enumerated PnP hardware ID | `amdpsp_Device_100` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdpsp.inf` | AMD PSP 10.0 Device | `PCI\VEN_1022&DEV_1649` | PCI-enumerated PnP hardware ID | `amdpsp_Device_100` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_1486` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_13EC` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_1456` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_14CA` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_1537` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_1578` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdsfhkmdf.inf` | AMD Sensor Fusion Hub | `PCI\VEN_1022&DEV_15E4` | PCI-enumerated PnP hardware ID | `amdsfhkmdf_Device` | Native | Native | Native | Native | KMDF 1.15 |
| `c0004\amdsfhkmdfi2c.inf` | AMD SFH KMDF I2C | `PCI\VEN_1022&DEV_15E6` | PCI-enumerated PnP hardware ID | `amdsfhkmdf_Device` | Native | Native | Native | Native | KMDF 1.15 |
| `c0004\amdsfhspbi2c.inf` | AMD SFH I2C Controller | `ACPI\AMDI0011` | ACPI-enumerated PnP hardware ID | `amdsfhspbi2c_Device` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdsfhumdf.inf` | AMD UMDF Sensor | `ACPI\AMDI0080` | ACPI-enumerated PnP hardware ID | `amdsfhumdf_Inst` | Native | Native | Native | Native | UMDF 2.15.0 |
| `c0004\amduart.inf` | AMD UART Controller | `ACPI\AMD0020` | ACPI-enumerated PnP hardware ID | `amduart_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amduart.inf` | AMD UART Controller | `ACPI\AMDI0020` | ACPI-enumerated PnP hardware ID | `amduart_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amduart.inf` | AMD UART Controller | `ACPI\AMDI0022` | ACPI-enumerated PnP hardware ID | `amduart_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_162E` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `c0004\amdusb4cm.inf` | AMD USB4 Host Router | `PCI\VEN_1022&DEV_162F` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native | KMDF 1.19 |
| `c0004\amdusb4pcifilter.inf` | PCI Express Root Port | `PCI\VEN_1022&DEV_14CD&SUBSYS_14531022&REV_00` | PCI-enumerated PnP hardware ID | `amdusb4pcifilter` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15D6&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdusbhubfilter.inf` | USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15D7&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdwirelessbutton.inf` | AMD Wireless Button Driver | `ACPI\AMDI0051` | ACPI-enumerated PnP hardware ID | `amdwirelessbutton_Device` | Native | Native | Native | Native | KMDF 1.15 |
| `c0004\ams_mailboxdrv.inf` | AMS-MailBoxDrv | `ACPI\AMDI0090` | ACPI-enumerated PnP hardware ID | `AMS-MailBoxDrv_Device` | Native | Native | Native | Native | NotDeclared |
| `c0004\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4353` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `c0004\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4363` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `c0004\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4372` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `c0004\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4385` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `c0004\smbusamd.inf` | AMD SMBus | `PCI\VEN_1022&DEV_780B` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `c0004\smbusamd.inf` | AMD SMBus | `PCI\VEN_1022&DEV_790B` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `c0004\usbfilter.inf` | AMD USB Filter Driver | `{36FC9E60-C465-11CF-8056-444553540000}\usbfilter` | Device-class-specific ID | `usbfilter` | Native | Native | Native | Native | NotDeclared |
| `c0004\zenpromnf.inf` | ZenProM S0i3 Network Filter | `ZenProMnf` | Network software component ID | `Install` | Native | Native | Native | Native | NotDeclared |

## AMD Chipset Software 4.03.03.431

| INF | Device | Device identifier | Identifier type | Install section | WS2016 | WS2019 | WS2022 | WS2025 | WDF |
|---|---|---|---|---|---|---|---|---|---|
| `c0004\amdas4.inf` | AmdAS4 Device | `ACPI\AMDI0050` | ACPI-enumerated PnP hardware ID | `AmdAS4` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdas4.inf` | AmdAS4 Device | `ACPI\ASD0001` | ACPI-enumerated PnP hardware ID | `AmdAS4` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdcir.inf` | AMD CIR Driver | `*AMDC001` | Generic PnP hardware ID | `AMDCIR64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdcir.inf` | AMD CIR Driver | `*AMDC002` | Generic PnP hardware ID | `AMDCIR64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdcir.inf` | AMD CIR Driver | `*AMDC003` | Generic PnP hardware ID | `AMDCIR64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdgpio2.inf` | AMD GPIO Controller | `ACPI\AMD0030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdgpio2.inf` | AMD GPIO Controller | `ACPI\AMDI0030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdgpio2.inf` | AMD GPIO Controller | `ACPI\AMDI0031` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdgpio2.inf` | AMD GPIO Controller | `ACPI\GPIO0010` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdgpio3.inf` | AMD GPIO Controller | `ACPI\AMDF030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdgpio3.inf` | AMD GPIO Controller | `ACPI\AMDIF030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdgpio3.inf` | AMD GPIO Controller | `ACPI\AMDIF031` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdi2c.inf` | AMD I2C Controller | `ACPI\AMD0010` | ACPI-enumerated PnP hardware ID | `amdi2c_Device` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdi2c.inf` | AMD I2C Controller | `ACPI\AMDI0010` | ACPI-enumerated PnP hardware ID | `amdi2c_Device` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1002&DEV_5A23` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_13E1` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1419` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1423` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1437` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1451` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1481` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1577` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_164F` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMD0004` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMD0005` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0005` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0006` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0007` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0008` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_1455` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_145A` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_1485` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_148A` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdpsp.inf` | AMD PSP 10.0 Device | `PCI\VEN_1022&DEV_15DF` | PCI-enumerated PnP hardware ID | `amdpsp_Device_100` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdpsp.inf` | AMD PSP 10.0 Device | `PCI\VEN_1022&DEV_1649` | PCI-enumerated PnP hardware ID | `amdpsp_Device_100` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_1486` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_13EC` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_1456` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_14CA` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_1537` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdpsp.inf` | AMD PSP Device | `PCI\VEN_1022&DEV_1578` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdsfhkmdf.inf` | AMD Sensor Fusion Hub | `PCI\VEN_1022&DEV_15E4` | PCI-enumerated PnP hardware ID | `amdsfhkmdf_Device` | Native | Native | Native | Native | KMDF 1.15 |
| `c0004\amdsfhkmdfi2c.inf` | AMD SFH KMDF I2C | `PCI\VEN_1022&DEV_15E6` | PCI-enumerated PnP hardware ID | `amdsfhkmdf_Device` | Native | Native | Native | Native | KMDF 1.15 |
| `c0004\amdsfhspbi2c.inf` | AMD SFH I2C Controller | `ACPI\AMDI0011` | ACPI-enumerated PnP hardware ID | `amdsfhspbi2c_Device` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdsfhumdf.inf` | AMD UMDF Sensor | `ACPI\AMDI0080` | ACPI-enumerated PnP hardware ID | `amdsfhumdf_Inst` | Native | Native | Native | Native | UMDF 2.15.0 |
| `c0004\amduart.inf` | AMD UART Controller | `ACPI\AMD0020` | ACPI-enumerated PnP hardware ID | `amduart_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amduart.inf` | AMD UART Controller | `ACPI\AMDI0020` | ACPI-enumerated PnP hardware ID | `amduart_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amduart.inf` | AMD UART Controller | `ACPI\AMDI0022` | ACPI-enumerated PnP hardware ID | `amduart_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4353` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `c0004\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4363` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `c0004\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4372` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `c0004\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4385` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `c0004\smbusamd.inf` | AMD SMBus | `PCI\VEN_1022&DEV_780B` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `c0004\smbusamd.inf` | AMD SMBus | `PCI\VEN_1022&DEV_790B` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `c0004\usbfilter.inf` | AMD USB Filter Driver | `{36FC9E60-C465-11CF-8056-444553540000}\usbfilter` | Device-class-specific ID | `usbfilter` | Native | Native | Native | Native | NotDeclared |

## AMD Chipset Software 3.10.08.506

| INF | Device | Device identifier | Identifier type | Install section | WS2016 | WS2019 | WS2022 | WS2025 | WDF |
|---|---|---|---|---|---|---|---|---|---|
| `c0004\amdas4.inf` | AmdAS4 Device | `ACPI\AMDI0050` | ACPI-enumerated PnP hardware ID | `AmdAS4` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdas4.inf` | AmdAS4 Device | `ACPI\ASD0001` | ACPI-enumerated PnP hardware ID | `AmdAS4` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdcir.inf` | AMD CIR Driver | `*AMDC001` | Generic PnP hardware ID | `AMDCIR64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdcir.inf` | AMD CIR Driver | `*AMDC002` | Generic PnP hardware ID | `AMDCIR64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdcir.inf` | AMD CIR Driver | `*AMDC003` | Generic PnP hardware ID | `AMDCIR64` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdgpio2.inf` | AMD GPIO Controller | `ACPI\AMD0030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdgpio2.inf` | AMD GPIO Controller | `ACPI\AMDI0030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdgpio2.inf` | AMD GPIO Controller | `ACPI\AMDI0031` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdgpio2.inf` | AMD GPIO Controller | `ACPI\GPIO0010` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdgpio3.inf` | AMD GPIO Controller | `ACPI\AMDF030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdgpio3.inf` | AMD GPIO Controller | `ACPI\AMDIF030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdi2c.inf` | AMD I2C Controller | `ACPI\AMD0010` | ACPI-enumerated PnP hardware ID | `amdi2c_Device` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdi2c.inf` | AMD I2C Controller | `ACPI\AMDI0010` | ACPI-enumerated PnP hardware ID | `amdi2c_Device` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1002&DEV_5A23` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_13E1` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1419` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1423` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1437` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1451` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1481` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1577` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_164F` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMD0004` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMD0005` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0005` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0006` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0007` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_1455` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_145A` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_1485` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_148A` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdpsp.inf` | AMD PSP 1.0 Device | `PCI\VEN_1022&DEV_1537` | PCI-enumerated PnP hardware ID | `amdpsp_Device_10` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdpsp.inf` | AMD PSP 10.0 Device | `PCI\VEN_1022&DEV_15DF` | PCI-enumerated PnP hardware ID | `amdpsp_Device_100` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdpsp.inf` | AMD PSP 10.0 Device | `PCI\VEN_1022&DEV_1649` | PCI-enumerated PnP hardware ID | `amdpsp_Device_100` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_1486` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdpsp.inf` | AMD PSP 12.0 Device | `PCI\VEN_1022&DEV_13EC` | PCI-enumerated PnP hardware ID | `amdpsp_Device_120` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdpsp.inf` | AMD PSP 2.0 Device | `PCI\VEN_1022&DEV_1578` | PCI-enumerated PnP hardware ID | `amdpsp_Device_20` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdpsp.inf` | AMD PSP 3.0 Device | `PCI\VEN_1022&DEV_1456` | PCI-enumerated PnP hardware ID | `amdpsp_Device_30` | Native | Native | Native | Native | KMDF 1.11 |
| `c0004\amdsfhkmdf.inf` | AMD Sensor Fusion Hub | `PCI\VEN_1022&DEV_15E4` | PCI-enumerated PnP hardware ID | `amdsfhkmdf_Device` | Native | Native | Native | Native | KMDF 1.15 |
| `c0004\amdsfhkmdfi2c.inf` | AMD SFH KMDF I2C | `PCI\VEN_1022&DEV_15E6` | PCI-enumerated PnP hardware ID | `amdsfhkmdf_Device` | Native | Native | Native | Native | KMDF 1.15 |
| `c0004\amdsfhspbi2c.inf` | AMD SFH I2C Controller | `ACPI\AMDI0011` | ACPI-enumerated PnP hardware ID | `amdsfhspbi2c_Device` | Native | Native | Native | Native | NotDeclared |
| `c0004\amdsfhumdf.inf` | AMD UMDF Sensor | `ACPI\AMDI0080` | ACPI-enumerated PnP hardware ID | `amdsfhumdf_Inst` | Native | Native | Native | Native | UMDF 2.15.0 |
| `c0004\amduart.inf` | AMD UART Controller | `ACPI\AMD0020` | ACPI-enumerated PnP hardware ID | `amduart_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amduart.inf` | AMD UART Controller | `ACPI\AMDI0020` | ACPI-enumerated PnP hardware ID | `amduart_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\amduart.inf` | AMD UART Controller | `ACPI\AMDI0022` | ACPI-enumerated PnP hardware ID | `amduart_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0004\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4353` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `c0004\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4363` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `c0004\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4372` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `c0004\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4385` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `c0004\smbusamd.inf` | AMD SMBus | `PCI\VEN_1022&DEV_780B` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `c0004\smbusamd.inf` | AMD SMBus | `PCI\VEN_1022&DEV_790B` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `c0004\usbfilter.inf` | AMD USB Filter Driver | `{36FC9E60-C465-11CF-8056-444553540000}\usbfilter` | Device-class-specific ID | `usbfilter` | Native | Native | Native | Native | NotDeclared |

## AMD Chipset Software 3.09.01.140

| INF | Device | Device identifier | Identifier type | Install section | WS2016 | WS2019 | WS2022 | WS2025 | WDF |
|---|---|---|---|---|---|---|---|---|---|
| `c0005\amdas4.inf` | AmdAS4 Device | `ACPI\AMDI0050` | ACPI-enumerated PnP hardware ID | `AmdAS4` | Native | Native | Native | Native | NotDeclared |
| `c0005\amdas4.inf` | AmdAS4 Device | `ACPI\ASD0001` | ACPI-enumerated PnP hardware ID | `AmdAS4` | Native | Native | Native | Native | NotDeclared |
| `c0005\amdcir.inf` | AMD CIR Driver | `*AMDC001` | Generic PnP hardware ID | `AMDCIR64` | Native | Native | Native | Native | NotDeclared |
| `c0005\amdcir.inf` | AMD CIR Driver | `*AMDC002` | Generic PnP hardware ID | `AMDCIR64` | Native | Native | Native | Native | NotDeclared |
| `c0005\amdcir.inf` | AMD CIR Driver | `*AMDC003` | Generic PnP hardware ID | `AMDCIR64` | Native | Native | Native | Native | NotDeclared |
| `c0005\amdgpio2.inf` | AMD GPIO Controller | `ACPI\AMD0030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0005\amdgpio2.inf` | AMD GPIO Controller | `ACPI\AMDI0030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0005\amdgpio2.inf` | AMD GPIO Controller | `ACPI\AMDI0031` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0005\amdgpio2.inf` | AMD GPIO Controller | `ACPI\GPIO0010` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0005\amdgpio3.inf` | AMD GPIO Controller | `ACPI\AMDF030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0005\amdgpio3.inf` | AMD GPIO Controller | `ACPI\AMDIF030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0005\amdi2c.inf` | AMD I2C Controller | `ACPI\AMD0010` | ACPI-enumerated PnP hardware ID | `amdi2c_Device` | Native | Native | Native | Native | NotDeclared |
| `c0005\amdi2c.inf` | AMD I2C Controller | `ACPI\AMDI0010` | ACPI-enumerated PnP hardware ID | `amdi2c_Device` | Native | Native | Native | Native | NotDeclared |
| `c0005\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1002&DEV_5A23` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0005\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_13E1` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0005\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1419` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0005\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1423` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0005\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1437` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0005\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1451` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0005\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1481` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0005\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1577` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0005\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_164F` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0005\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMD0004` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `c0005\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMD0005` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `c0005\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0005` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `c0005\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0006` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `c0005\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0007` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `c0005\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_1455` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0005\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_145A` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0005\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_1485` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0005\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_148A` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0005\amdpsp.inf` | AMD PSP 1.0 Device | `PCI\VEN_1022&DEV_1537` | PCI-enumerated PnP hardware ID | `amdpsp_Device_10` | Native | Native | Native | Native | KMDF 1.11 |
| `c0005\amdpsp.inf` | AMD PSP 10.0 Device | `PCI\VEN_1022&DEV_15DF` | PCI-enumerated PnP hardware ID | `amdpsp_Device_100` | Native | Native | Native | Native | KMDF 1.11 |
| `c0005\amdpsp.inf` | AMD PSP 10.0 Device | `PCI\VEN_1022&DEV_1649` | PCI-enumerated PnP hardware ID | `amdpsp_Device_100` | Native | Native | Native | Native | KMDF 1.11 |
| `c0005\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_1486` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | Native | Native | Native | KMDF 1.11 |
| `c0005\amdpsp.inf` | AMD PSP 12.0 Device | `PCI\VEN_1022&DEV_13EC` | PCI-enumerated PnP hardware ID | `amdpsp_Device_120` | Native | Native | Native | Native | KMDF 1.11 |
| `c0005\amdpsp.inf` | AMD PSP 2.0 Device | `PCI\VEN_1022&DEV_1578` | PCI-enumerated PnP hardware ID | `amdpsp_Device_20` | Native | Native | Native | Native | KMDF 1.11 |
| `c0005\amdpsp.inf` | AMD PSP 3.0 Device | `PCI\VEN_1022&DEV_1456` | PCI-enumerated PnP hardware ID | `amdpsp_Device_30` | Native | Native | Native | Native | KMDF 1.11 |
| `c0005\amdsfhkmdf.inf` | AMD Sensor Fusion Hub | `PCI\VEN_1022&DEV_15E4` | PCI-enumerated PnP hardware ID | `amdsfhkmdf_Device` | Native | Native | Native | Native | KMDF 1.15 |
| `c0005\amdsfhkmdfi2c.inf` | AMD SFH KMDF I2C | `PCI\VEN_1022&DEV_15E6` | PCI-enumerated PnP hardware ID | `amdsfhkmdf_Device` | Native | Native | Native | Native | KMDF 1.15 |
| `c0005\amdsfhspbi2c.inf` | AMD SFH I2C Controller | `ACPI\AMDI0011` | ACPI-enumerated PnP hardware ID | `amdsfhspbi2c_Device` | Native | Native | Native | Native | NotDeclared |
| `c0005\amdsfhumdf.inf` | AMD UMDF Sensor | `ACPI\AMDI0080` | ACPI-enumerated PnP hardware ID | `amdsfhumdf_Inst` | Native | Native | Native | Native | UMDF 2.15.0 |
| `c0005\amduart.inf` | AMD UART Controller | `ACPI\AMD0020` | ACPI-enumerated PnP hardware ID | `amduart_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0005\amduart.inf` | AMD UART Controller | `ACPI\AMDI0020` | ACPI-enumerated PnP hardware ID | `amduart_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0005\amduart.inf` | AMD UART Controller | `ACPI\AMDI0022` | ACPI-enumerated PnP hardware ID | `amduart_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0005\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4353` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `c0005\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4363` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `c0005\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4372` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `c0005\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4385` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `c0005\smbusamd.inf` | AMD SMBus | `PCI\VEN_1022&DEV_780B` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `c0005\smbusamd.inf` | AMD SMBus | `PCI\VEN_1022&DEV_790B` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `c0005\usbfilter.inf` | AMD USB Filter Driver | `{36FC9E60-C465-11CF-8056-444553540000}\usbfilter` | Device-class-specific ID | `usbfilter` | Native | Native | Native | Native | NotDeclared |

## AMD Chipset Software 3.08.17.735

| INF | Device | Device identifier | Identifier type | Install section | WS2016 | WS2019 | WS2022 | WS2025 | WDF |
|---|---|---|---|---|---|---|---|---|---|
| `c0005\amdas4.inf` | AmdAS4 Device | `ACPI\AMDI0050` | ACPI-enumerated PnP hardware ID | `AmdAS4` | Native | Native | Native | Native | NotDeclared |
| `c0005\amdas4.inf` | AmdAS4 Device | `ACPI\ASD0001` | ACPI-enumerated PnP hardware ID | `AmdAS4` | Native | Native | Native | Native | NotDeclared |
| `c0005\amdcir.inf` | AMD CIR Driver | `*AMDC001` | Generic PnP hardware ID | `AMDCIR64` | Native | Native | Native | Native | NotDeclared |
| `c0005\amdcir.inf` | AMD CIR Driver | `*AMDC002` | Generic PnP hardware ID | `AMDCIR64` | Native | Native | Native | Native | NotDeclared |
| `c0005\amdcir.inf` | AMD CIR Driver | `*AMDC003` | Generic PnP hardware ID | `AMDCIR64` | Native | Native | Native | Native | NotDeclared |
| `c0005\amdgpio2.inf` | AMD GPIO Controller | `ACPI\AMD0030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0005\amdgpio2.inf` | AMD GPIO Controller | `ACPI\AMDI0030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0005\amdgpio2.inf` | AMD GPIO Controller | `ACPI\AMDI0031` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0005\amdgpio2.inf` | AMD GPIO Controller | `ACPI\GPIO0010` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0005\amdgpio3.inf` | AMD GPIO Controller | `ACPI\AMDF030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0005\amdgpio3.inf` | AMD GPIO Controller | `ACPI\AMDIF030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0005\amdi2c.inf` | AMD I2C Controller | `ACPI\AMD0010` | ACPI-enumerated PnP hardware ID | `amdi2c_Device` | Native | Native | Native | Native | NotDeclared |
| `c0005\amdi2c.inf` | AMD I2C Controller | `ACPI\AMDI0010` | ACPI-enumerated PnP hardware ID | `amdi2c_Device` | Native | Native | Native | Native | NotDeclared |
| `c0005\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1002&DEV_5A23` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0005\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_13E1` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0005\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1419` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0005\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1423` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0005\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1437` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0005\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1451` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0005\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1481` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0005\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1577` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0005\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_164F` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0005\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMD0004` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `c0005\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMD0005` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `c0005\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0005` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `c0005\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0006` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `c0005\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0007` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `c0005\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_1455` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0005\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_145A` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0005\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_1485` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0005\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_148A` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0005\amdpsp.inf` | AMD PSP 1.0 Device | `PCI\VEN_1022&DEV_1537` | PCI-enumerated PnP hardware ID | `amdpsp_Device_10` | Native | Native | Native | Native | KMDF 1.11 |
| `c0005\amdpsp.inf` | AMD PSP 10.0 Device | `PCI\VEN_1022&DEV_15DF` | PCI-enumerated PnP hardware ID | `amdpsp_Device_100` | Native | Native | Native | Native | KMDF 1.11 |
| `c0005\amdpsp.inf` | AMD PSP 10.0 Device | `PCI\VEN_1022&DEV_1649` | PCI-enumerated PnP hardware ID | `amdpsp_Device_100` | Native | Native | Native | Native | KMDF 1.11 |
| `c0005\amdpsp.inf` | AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_1486` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | Native | Native | Native | KMDF 1.11 |
| `c0005\amdpsp.inf` | AMD PSP 12.0 Device | `PCI\VEN_1022&DEV_13EC` | PCI-enumerated PnP hardware ID | `amdpsp_Device_120` | Native | Native | Native | Native | KMDF 1.11 |
| `c0005\amdpsp.inf` | AMD PSP 2.0 Device | `PCI\VEN_1022&DEV_1578` | PCI-enumerated PnP hardware ID | `amdpsp_Device_20` | Native | Native | Native | Native | KMDF 1.11 |
| `c0005\amdpsp.inf` | AMD PSP 3.0 Device | `PCI\VEN_1022&DEV_1456` | PCI-enumerated PnP hardware ID | `amdpsp_Device_30` | Native | Native | Native | Native | KMDF 1.11 |
| `c0005\amdsfhkmdf.inf` | AMD Sensor Fusion Hub | `PCI\VEN_1022&DEV_15E4` | PCI-enumerated PnP hardware ID | `amdsfhkmdf_Device` | Native | Native | Native | Native | KMDF 1.15 |
| `c0005\amdsfhkmdfi2c.inf` | AMD SFH KMDF I2C | `PCI\VEN_1022&DEV_15E6` | PCI-enumerated PnP hardware ID | `amdsfhkmdf_Device` | Native | Native | Native | Native | KMDF 1.15 |
| `c0005\amdsfhspbi2c.inf` | AMD SFH I2C Controller | `ACPI\AMDI0011` | ACPI-enumerated PnP hardware ID | `amdsfhspbi2c_Device` | Native | Native | Native | Native | NotDeclared |
| `c0005\amdsfhumdf.inf` | AMD UMDF Sensor | `ACPI\AMDI0080` | ACPI-enumerated PnP hardware ID | `amdsfhumdf_Inst` | Native | Native | Native | Native | UMDF 2.15.0 |
| `c0005\amduart.inf` | AMD UART Controller | `ACPI\AMD0020` | ACPI-enumerated PnP hardware ID | `amduart_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0005\amduart.inf` | AMD UART Controller | `ACPI\AMDI0020` | ACPI-enumerated PnP hardware ID | `amduart_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0005\amduart.inf` | AMD UART Controller | `ACPI\AMDI0022` | ACPI-enumerated PnP hardware ID | `amduart_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0005\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4353` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `c0005\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4363` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `c0005\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4372` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `c0005\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4385` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `c0005\smbusamd.inf` | AMD SMBus | `PCI\VEN_1022&DEV_780B` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `c0005\smbusamd.inf` | AMD SMBus | `PCI\VEN_1022&DEV_790B` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `c0005\usbfilter.inf` | AMD USB Filter Driver | `{36FC9E60-C465-11CF-8056-444553540000}\usbfilter` | Device-class-specific ID | `usbfilter` | Native | Native | Native | Native | NotDeclared |

## AMD Chipset Software 2.04.04.111

| INF | Device | Device identifier | Identifier type | Install section | WS2016 | WS2019 | WS2022 | WS2025 | WDF |
|---|---|---|---|---|---|---|---|---|---|
| `c0005\amd_sata.inf` | AMD SATA Controller | `PCI\VEN_1002&DEV_4391&CC_0106` | PCI-enumerated PnP hardware ID | `amd_sata_inst` | Native | Native | Native | Native | NotDeclared |
| `c0005\amd_sata.inf` | AMD SATA Controller | `PCI\VEN_1002&DEV_4394&CC_0106` | PCI-enumerated PnP hardware ID | `amd_sata_inst` | Native | Native | Native | Native | NotDeclared |
| `c0005\amd_sata.inf` | AMD SATA Controller | `PCI\VEN_1022&DEV_7801&CC_0106` | PCI-enumerated PnP hardware ID | `amd_sata_inst` | Native | Native | Native | Native | NotDeclared |
| `c0005\amd_sata.inf` | AMD SATA Controller | `PCI\VEN_1022&DEV_7804&CC_0106` | PCI-enumerated PnP hardware ID | `amd_sata_inst` | Native | Native | Native | Native | NotDeclared |
| `c0005\amd_sata.inf` | AMD SATA Controller | `PCI\VEN_1022&DEV_7901&CC_0106` | PCI-enumerated PnP hardware ID | `amd_sata_inst` | Native | Native | Native | Native | NotDeclared |
| `c0005\amd_sata.inf` | AMD SATA Controller | `PCI\VEN_1022&DEV_7904&CC_0106` | PCI-enumerated PnP hardware ID | `amd_sata_inst` | Native | Native | Native | Native | NotDeclared |
| `c0005\amdas4.inf` | AmdAS4 Device | `ACPI\AMDI0050` | ACPI-enumerated PnP hardware ID | `AmdAS4` | Native | Native | Native | Native | NotDeclared |
| `c0005\amdas4.inf` | AmdAS4 Device | `ACPI\ASD0001` | ACPI-enumerated PnP hardware ID | `AmdAS4` | Native | Native | Native | Native | NotDeclared |
| `c0005\amdcir.inf` | AMD CIR Driver | `*AMDC001` | Generic PnP hardware ID | `AMDCIR64` | Native | Native | Native | Native | NotDeclared |
| `c0005\amdcir.inf` | AMD CIR Driver | `*AMDC002` | Generic PnP hardware ID | `AMDCIR64` | Native | Native | Native | Native | NotDeclared |
| `c0005\amdcir.inf` | AMD CIR Driver | `*AMDC003` | Generic PnP hardware ID | `AMDCIR64` | Native | Native | Native | Native | NotDeclared |
| `c0005\amdgpio2.inf` | AMD GPIO Controller | `ACPI\AMD0030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0005\amdgpio2.inf` | AMD GPIO Controller | `ACPI\AMDI0030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0005\amdgpio2.inf` | AMD GPIO Controller | `ACPI\GPIO0010` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0005\amdgpio3.inf` | AMD GPIO Controller | `ACPI\AMDF030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0005\amdgpio3.inf` | AMD GPIO Controller | `ACPI\AMDIF030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0005\amdhub3.inf` | AMD Root Hub(xHCI) | `AMDUSB3\ROOT_HUB3` | AMDUSB3-enumerated PnP hardware ID | `AMDHUB3` | Native | Native | Native | Native | NotDeclared |
| `c0005\amdhub3.inf` | AMD USB 2.0 Hub | `AMDUSB3\CLASS_09&SUBCLASS_00&PROT_01` | AMDUSB3-enumerated PnP hardware ID | `AMDHUB3` | Native | Native | Native | Native | NotDeclared |
| `c0005\amdhub3.inf` | AMD USB 2.0 MTT Hub | `AMDUSB3\CLASS_09&SUBCLASS_00&PROT_02` | AMDUSB3-enumerated PnP hardware ID | `AMDHUB3` | Native | Native | Native | Native | NotDeclared |
| `c0005\amdhub3.inf` | AMD USB 3.0 Hub | `AMDUSB3\CLASS_09&SUBCLASS_00&PROT_03` | AMDUSB3-enumerated PnP hardware ID | `AMDHUB3` | Native | Native | Native | Native | NotDeclared |
| `c0005\amdhub3.inf` | AMD USB Hub | `AMDUSB3\CLASS_09&SUBCLASS_00&PROT_00` | AMDUSB3-enumerated PnP hardware ID | `AMDHUB3` | Native | Native | Native | Native | NotDeclared |
| `c0005\amdhub3.inf` | AMD USB Hub | `AMDUSB3\CLASS_09&SUBCLASS_01` | AMDUSB3-enumerated PnP hardware ID | `AMDHUB3` | Native | Native | Native | Native | NotDeclared |
| `c0005\amdhub30.inf` | AMD USB 2.0 Hub | `AMDUSB30\CLASS_09&SUBCLASS_00&PROT_01` | AMDUSB30-enumerated PnP hardware ID | `AMDHUB30` | Projection | Projection | Projection | Projection | NotDeclared |
| `c0005\amdhub30.inf` | AMD USB 2.0 MTT Hub | `AMDUSB30\CLASS_09&SUBCLASS_00&PROT_02` | AMDUSB30-enumerated PnP hardware ID | `AMDHUB30` | Projection | Projection | Projection | Projection | NotDeclared |
| `c0005\amdhub30.inf` | AMD USB 3.0 Hub | `AMDUSB30\CLASS_09&SUBCLASS_00&PROT_03` | AMDUSB30-enumerated PnP hardware ID | `AMDHUB30` | Projection | Projection | Projection | Projection | NotDeclared |
| `c0005\amdhub30.inf` | AMD USB 3.0 Root Hub | `AMDUSB30\ROOT_HUB30` | AMDUSB30-enumerated PnP hardware ID | `AMDHUB30` | Projection | Projection | Projection | Projection | NotDeclared |
| `c0005\amdhub30.inf` | AMD USB Hub | `AMDUSB30\CLASS_09&SUBCLASS_00&PROT_00` | AMDUSB30-enumerated PnP hardware ID | `AMDHUB30` | Projection | Projection | Projection | Projection | NotDeclared |
| `c0005\amdhub30.inf` | AMD USB Hub | `AMDUSB30\CLASS_09&SUBCLASS_01` | AMDUSB30-enumerated PnP hardware ID | `AMDHUB30` | Projection | Projection | Projection | Projection | NotDeclared |
| `c0005\amdhub31.inf` | AMD USB3.1 Root Hub | `USB\AMDROOT_HUB31&VID1022&PID43B9&VER0001000000050003` | USB-enumerated PnP hardware ID | `RootHub_Product1_Install` | Native | Native | Native | Native | NotDeclared |
| `c0005\amdhub31.inf` | AMD USB3.1 Root Hub | `USB\AMDROOT_HUB31&VID1022&PID43BA&VER0001000000050003` | USB-enumerated PnP hardware ID | `RootHub_Product2_Install` | Native | Native | Native | Native | NotDeclared |
| `c0005\amdhub31.inf` | AMD USB3.1 Root Hub | `USB\AMDROOT_HUB31&VID1022&PID43BB&VER0001000000050003` | USB-enumerated PnP hardware ID | `RootHub_Product3_Install` | Native | Native | Native | Native | NotDeclared |
| `c0005\amdhub31.inf` | AMD USB3.1 Root Hub | `USB\AMDROOT_HUB31&VID1022&PID43BC&VER0001000000050003` | USB-enumerated PnP hardware ID | `RootHub_Product4_Install` | Native | Native | Native | Native | NotDeclared |
| `c0005\amdhub31.inf` | AMD USB3.1 Root Hub | `USB\AMDROOT_HUB31&VID1022&PID43D0&VER0001000000050003` | USB-enumerated PnP hardware ID | `RootHub_Product5_Install` | Native | Native | Native | Native | NotDeclared |
| `c0005\amdhub31.inf` | AMD USB3.1 Root Hub | `USB\AMDROOT_HUB31&VID1022&PID43D1&VER0001000000050003` | USB-enumerated PnP hardware ID | `RootHub_Product6_Install` | Native | Native | Native | Native | NotDeclared |
| `c0005\amdhub31.inf` | AMD USB3.1 Root Hub | `USB\AMDROOT_HUB31&VID1022&PID43D2&VER0001000000050003` | USB-enumerated PnP hardware ID | `RootHub_Product7_Install` | Native | Native | Native | Native | NotDeclared |
| `c0005\amdhub31.inf` | AMD USB3.1 Root Hub | `USB\AMDROOT_HUB31&VID1022&PID43D3&VER0001000000050003` | USB-enumerated PnP hardware ID | `RootHub_Product8_Install` | Native | Native | Native | Native | NotDeclared |
| `c0005\amdhub31.inf` | AMD USB3.1 Root Hub | `USB\AMDROOT_HUB31&VID1022&PID43D4&VER0001000000050003` | USB-enumerated PnP hardware ID | `RootHub_Product9_Install` | Native | Native | Native | Native | NotDeclared |
| `c0005\amdhub31.inf` | AMD USB3.1 Root Hub | `USB\AMDROOT_HUB31&VID1022&PID43D5&VER0001000000050003` | USB-enumerated PnP hardware ID | `RootHub_Product10_Install` | Native | Native | Native | Native | NotDeclared |
| `c0005\amdhub31.inf` | AMD USB3.1 Root Hub | `USB\AMDROOT_HUB31&VID1022&PID43D6&VER0001000000050003` | USB-enumerated PnP hardware ID | `RootHub_Product11_Install` | Native | Native | Native | Native | NotDeclared |
| `c0005\amdhub31.inf` | AMD USB3.1 Root Hub | `USB\AMDROOT_HUB31&VID1022&PID43D7&VER0001000000050003` | USB-enumerated PnP hardware ID | `RootHub_Product12_Install` | Native | Native | Native | Native | NotDeclared |
| `c0005\amdhub31.inf` | AMD USB3.1 Root Hub | `USB\AMDROOT_HUB31&VID1022&PID43D8&VER0001000000050003` | USB-enumerated PnP hardware ID | `RootHub_Product13_Install` | Native | Native | Native | Native | NotDeclared |
| `c0005\amdhub31.inf` | AMD USB3.1 Root Hub | `USB\AMDROOT_HUB31&VID1022&PID43D9&VER0001000000050003` | USB-enumerated PnP hardware ID | `RootHub_Product14_Install` | Native | Native | Native | Native | NotDeclared |
| `c0005\amdhub31.inf` | AMD USB3.1 Root Hub | `USB\AMDROOT_HUB31&VID1022&PID43DA&VER0001000000050003` | USB-enumerated PnP hardware ID | `RootHub_Product15_Install` | Native | Native | Native | Native | NotDeclared |
| `c0005\amdhub31.inf` | AMD USB3.1 Root Hub | `USB\AMDROOT_HUB31&VID1022&PID43DB&VER0001000000050003` | USB-enumerated PnP hardware ID | `RootHub_Product16_Install` | Native | Native | Native | Native | NotDeclared |
| `c0005\amdhub31.inf` | AMD USB3.1 Root Hub | `USB\AMDROOT_HUB31&VID1022&PID43DC&VER0001000000050003` | USB-enumerated PnP hardware ID | `RootHub_Product17_Install` | Native | Native | Native | Native | NotDeclared |
| `c0005\amdhub31.inf` | AMD USB3.1 Root Hub | `USB\AMDROOT_HUB31&VID1022&PID43DD&VER0001000000050003` | USB-enumerated PnP hardware ID | `RootHub_Product18_Install` | Native | Native | Native | Native | NotDeclared |
| `c0005\amdhub31.inf` | AMD USB3.1 Root Hub | `USB\AMDROOT_HUB31&VID1022&PID43DE&VER0001000000050003` | USB-enumerated PnP hardware ID | `RootHub_Product19_Install` | Native | Native | Native | Native | NotDeclared |
| `c0005\amdhub31.inf` | AMD USB3.1 Root Hub | `USB\AMDROOT_HUB31&VID1022&PID43DF&VER0001000000050003` | USB-enumerated PnP hardware ID | `RootHub_Product20_Install` | Native | Native | Native | Native | NotDeclared |
| `c0005\amdhub31.inf` | Generic SuperSpeed USB Hub | `USB\AMD_HUB31SS` | USB-enumerated PnP hardware ID | `Hub_Product3_Install` | Native | Native | Native | Native | NotDeclared |
| `c0005\amdhub31.inf` | Generic USB Hub | `USB\AMD_HUB31` | USB-enumerated PnP hardware ID | `Hub_Product2_Install` | Native | Native | Native | Native | NotDeclared |
| `c0005\amdi2c.inf` | AMD I2C Controller | `ACPI\AMD0010` | ACPI-enumerated PnP hardware ID | `amdi2c_Device` | Native | Native | Native | Native | NotDeclared |
| `c0005\amdi2c.inf` | AMD I2C Controller | `ACPI\AMDI0010` | ACPI-enumerated PnP hardware ID | `amdi2c_Device` | Native | Native | Native | Native | NotDeclared |
| `c0005\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1002&DEV_5A23` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0005\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1419` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0005\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1423` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0005\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1437` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0005\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1449` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0005\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1451` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0005\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1481` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0005\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1577` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0005\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_15D1` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0005\amdiov.inf` | AMD IOMMU Device | `PCI\VEN_1022&DEV_1611` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native | NotDeclared |
| `c0005\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMD0004` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `c0005\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMD0005` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `c0005\amdmicropep.inf` | AMD Micro PEP Device | `ACPI\AMDI0005` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native | KMDF 1.11 |
| `c0005\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_1455` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0005\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_145A` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0005\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_1485` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0005\amdpcidev.inf` | AMD PCI | `PCI\VEN_1022&DEV_148A` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0005\amdpsp.inf` | AMD PSP 3.0 Device | `PCI\VEN_1022&DEV_1456` | PCI-enumerated PnP hardware ID | `amdpsp_Device_30` | Native | Native | Native | Native | NotDeclared |
| `c0005\amdpsp.inf` | AMD PSP 3.0 Device | `PCI\VEN_1022&DEV_1486` | PCI-enumerated PnP hardware ID | `amdpsp_Device_30` | Native | Native | Native | Native | NotDeclared |
| `c0005\amdpsp.inf` | AMD PSP 3.0 Device | `PCI\VEN_1022&DEV_15dF` | PCI-enumerated PnP hardware ID | `amdpsp_Device_30` | Native | Native | Native | Native | NotDeclared |
| `c0005\amdrhub3.inf` | AMD Root Hub(xHCI) | `AMDUSB3\ROOT_HUB31` | AMDUSB3-enumerated PnP hardware ID | `AMDHUB3` | Native | Native | Native | Native | NotDeclared |
| `c0005\amdrhub3.inf` | AMD USB 2.0 Hub | `AMDUSB3\CLASS_09&SUBCLASS_00&PROT_01` | AMDUSB3-enumerated PnP hardware ID | `AMDHUB3` | Native | Native | Native | Native | NotDeclared |
| `c0005\amdrhub3.inf` | AMD USB 2.0 MTT Hub | `AMDUSB3\CLASS_09&SUBCLASS_00&PROT_02` | AMDUSB3-enumerated PnP hardware ID | `AMDHUB3` | Native | Native | Native | Native | NotDeclared |
| `c0005\amdrhub3.inf` | AMD USB 3.1 Hub | `AMDUSB3\CLASS_09&SUBCLASS_00&PROT_03` | AMDUSB3-enumerated PnP hardware ID | `AMDHUB3` | Native | Native | Native | Native | NotDeclared |
| `c0005\amdrhub3.inf` | AMD USB Hub | `AMDUSB3\CLASS_09&SUBCLASS_00&PROT_00` | AMDUSB3-enumerated PnP hardware ID | `AMDHUB3` | Native | Native | Native | Native | NotDeclared |
| `c0005\amdrhub3.inf` | AMD USB Hub | `AMDUSB3\CLASS_09&SUBCLASS_01` | AMDUSB3-enumerated PnP hardware ID | `AMDHUB3` | Native | Native | Native | Native | NotDeclared |
| `c0005\amdrxhc.inf` | AMD Radeon USB3.1 Host Controller - 1.1 | `PCI\VEN_1002&DEV_7316` | PCI-enumerated PnP hardware ID | `AMDXHCI` | Native | Native | Native | Native | NotDeclared |
| `c0005\amdrxhc.inf` | AMD USB3.1 Host Controller - 1.1 | `PCI\VEN_1022&DEV_15E0` | PCI-enumerated PnP hardware ID | `AMDXHCI` | Native | Native | Native | Native | NotDeclared |
| `c0005\amdrxhc.inf` | AMD USB3.1 Host Controller - 1.1 | `PCI\VEN_1022&DEV_15E1` | PCI-enumerated PnP hardware ID | `AMDXHCI` | Native | Native | Native | Native | NotDeclared |
| `c0005\amdrxhc.inf` | AMD USB3.1 Host Controller - 1.1 | `PCI\VEN_1022&DEV_15E5` | PCI-enumerated PnP hardware ID | `AMDXHCI` | Native | Native | Native | Native | NotDeclared |
| `c0005\amdsfhkmdf.inf` | AMD Sensor Fusion Hub | `PCI\VEN_1022&DEV_15E4` | PCI-enumerated PnP hardware ID | `amdsfhkmdf_Device` | Native | Native | Native | Native | KMDF 1.15 |
| `c0005\amdsfhkmdfi2c.inf` | AMD SFH KMDF I2C | `PCI\VEN_1022&DEV_15E6` | PCI-enumerated PnP hardware ID | `amdsfhkmdf_Device` | Native | Native | Native | Native | KMDF 1.15 |
| `c0005\amdsfhspbi2c.inf` | AMD SFH I2C Controller | `ACPI\AMDI0011` | ACPI-enumerated PnP hardware ID | `amdsfhspbi2c_Device` | Native | Native | Native | Native | NotDeclared |
| `c0005\amdsfhumdf.inf` | AMD UMDF Sensor | `ACPI\AMDI0080` | ACPI-enumerated PnP hardware ID | `amdsfhumdf_Inst` | Native | Native | Native | Native | UMDF 2.15.0 |
| `c0005\amduart.inf` | AMD UART Controller | `ACPI\AMD0020` | ACPI-enumerated PnP hardware ID | `amduart_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0005\amduart.inf` | AMD UART Controller | `ACPI\AMDI0020` | ACPI-enumerated PnP hardware ID | `amduart_Inst` | Native | Native | Native | Native | NotDeclared |
| `c0005\amdxhc.inf` | AMD USB 3.0 Host Controller | `PCI\VEN_1022&DEV_7812` | PCI-enumerated PnP hardware ID | `AMDXHC` | Projection | Projection | Projection | Projection | NotDeclared |
| `c0005\amdxhc.inf` | AMD USB 3.0 Host Controller | `PCI\VEN_1022&DEV_7814` | PCI-enumerated PnP hardware ID | `AMDXHC` | Projection | Projection | Projection | Projection | NotDeclared |
| `c0005\amdxhc.inf` | AMD USB 3.0 Host Controller | `PCI\VEN_1022&DEV_7914` | PCI-enumerated PnP hardware ID | `AMDXHC` | Projection | Projection | Projection | Projection | NotDeclared |
| `c0005\amdxhc31.inf` | AMD USB3.1 eXtensible Host Controller | `PCI\VEN_1022&DEV_43B9` | PCI-enumerated PnP hardware ID | `AMD_Product1_Install` | Native | Native | Native | Native | NotDeclared |
| `c0005\amdxhc31.inf` | AMD USB3.1 eXtensible Host Controller | `PCI\VEN_1022&DEV_43BA` | PCI-enumerated PnP hardware ID | `AMD_Product2_Install` | Native | Native | Native | Native | NotDeclared |
| `c0005\amdxhc31.inf` | AMD USB3.1 eXtensible Host Controller | `PCI\VEN_1022&DEV_43BB` | PCI-enumerated PnP hardware ID | `AMD_Product3_Install` | Native | Native | Native | Native | NotDeclared |
| `c0005\amdxhc31.inf` | AMD USB3.1 eXtensible Host Controller | `PCI\VEN_1022&DEV_43BC` | PCI-enumerated PnP hardware ID | `AMD_Product4_Install` | Native | Native | Native | Native | NotDeclared |
| `c0005\amdxhc31.inf` | AMD USB3.1 eXtensible Host Controller | `PCI\VEN_1022&DEV_43D0` | PCI-enumerated PnP hardware ID | `AMD_Product5_Install` | Native | Native | Native | Native | NotDeclared |
| `c0005\amdxhc31.inf` | AMD USB3.1 eXtensible Host Controller | `PCI\VEN_1022&DEV_43D1` | PCI-enumerated PnP hardware ID | `AMD_Product6_Install` | Native | Native | Native | Native | NotDeclared |
| `c0005\amdxhc31.inf` | AMD USB3.1 eXtensible Host Controller | `PCI\VEN_1022&DEV_43D2` | PCI-enumerated PnP hardware ID | `AMD_Product7_Install` | Native | Native | Native | Native | NotDeclared |
| `c0005\amdxhc31.inf` | AMD USB3.1 eXtensible Host Controller | `PCI\VEN_1022&DEV_43D3` | PCI-enumerated PnP hardware ID | `AMD_Product8_Install` | Native | Native | Native | Native | NotDeclared |
| `c0005\amdxhc31.inf` | AMD USB3.1 eXtensible Host Controller | `PCI\VEN_1022&DEV_43D4` | PCI-enumerated PnP hardware ID | `AMD_Product9_Install` | Native | Native | Native | Native | NotDeclared |
| `c0005\amdxhc31.inf` | AMD USB3.1 eXtensible Host Controller | `PCI\VEN_1022&DEV_43D5` | PCI-enumerated PnP hardware ID | `AMD_Product10_Install` | Native | Native | Native | Native | NotDeclared |
| `c0005\amdxhc31.inf` | AMD USB3.1 eXtensible Host Controller | `PCI\VEN_1022&DEV_43D6` | PCI-enumerated PnP hardware ID | `AMD_Product11_Install` | Native | Native | Native | Native | NotDeclared |
| `c0005\amdxhc31.inf` | AMD USB3.1 eXtensible Host Controller | `PCI\VEN_1022&DEV_43D7` | PCI-enumerated PnP hardware ID | `AMD_Product12_Install` | Native | Native | Native | Native | NotDeclared |
| `c0005\amdxhc31.inf` | AMD USB3.1 eXtensible Host Controller | `PCI\VEN_1022&DEV_43D8` | PCI-enumerated PnP hardware ID | `AMD_Product13_Install` | Native | Native | Native | Native | NotDeclared |
| `c0005\amdxhc31.inf` | AMD USB3.1 eXtensible Host Controller | `PCI\VEN_1022&DEV_43D9` | PCI-enumerated PnP hardware ID | `AMD_Product14_Install` | Native | Native | Native | Native | NotDeclared |
| `c0005\amdxhc31.inf` | AMD USB3.1 eXtensible Host Controller | `PCI\VEN_1022&DEV_43DA` | PCI-enumerated PnP hardware ID | `AMD_Product15_Install` | Native | Native | Native | Native | NotDeclared |
| `c0005\amdxhc31.inf` | AMD USB3.1 eXtensible Host Controller | `PCI\VEN_1022&DEV_43DB` | PCI-enumerated PnP hardware ID | `AMD_Product16_Install` | Native | Native | Native | Native | NotDeclared |
| `c0005\amdxhc31.inf` | AMD USB3.1 eXtensible Host Controller | `PCI\VEN_1022&DEV_43DC` | PCI-enumerated PnP hardware ID | `AMD_Product17_Install` | Native | Native | Native | Native | NotDeclared |
| `c0005\amdxhc31.inf` | AMD USB3.1 eXtensible Host Controller | `PCI\VEN_1022&DEV_43DD` | PCI-enumerated PnP hardware ID | `AMD_Product18_Install` | Native | Native | Native | Native | NotDeclared |
| `c0005\amdxhc31.inf` | AMD USB3.1 eXtensible Host Controller | `PCI\VEN_1022&DEV_43DE` | PCI-enumerated PnP hardware ID | `AMD_Product19_Install` | Native | Native | Native | Native | NotDeclared |
| `c0005\amdxhc31.inf` | AMD USB3.1 eXtensible Host Controller | `PCI\VEN_1022&DEV_43DF` | PCI-enumerated PnP hardware ID | `AMD_Product20_Install` | Native | Native | Native | Native | NotDeclared |
| `c0005\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4353` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `c0005\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4363` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `c0005\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4372` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `c0005\smbusamd.inf` | AMD SMBus | `PCI\VEN_1002&DEV_4385` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `c0005\smbusamd.inf` | AMD SMBus | `PCI\VEN_1022&DEV_780B` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `c0005\smbusamd.inf` | AMD SMBus | `PCI\VEN_1022&DEV_790B` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native | NotDeclared |
| `c0005\usbfilter.inf` | AMD USB Filter Driver | `{36FC9E60-C465-11CF-8056-444553540000}\usbfilter` | Device-class-specific ID | `usbfilter` | Native | Native | Native | Native | NotDeclared |

