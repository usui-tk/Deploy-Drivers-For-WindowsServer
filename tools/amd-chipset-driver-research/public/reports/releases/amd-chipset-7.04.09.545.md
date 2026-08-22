# AMD Chipset Software 7.04.09.545 - Windows Server static analysis

> Static INF/WDF analysis only. `NativeCandidate` and `ProjectionCandidate` do not prove runtime compatibility.

## Release summary

| Windows Server | Native INF | Projection INF | WDF review | Review | Not applicable | Native devices | Projection devices |
|---|---:|---:|---:|---:|---:|---:|---:|
| Windows Server 2016 | 25 | 0 | 0 | 0 | 5 | 103 | 0 |
| Windows Server 2019 | 28 | 0 | 0 | 0 | 2 | 106 | 0 |
| Windows Server 2022 | 27 | 0 | 0 | 0 | 3 | 98 | 0 |
| Windows Server 2025 | 27 | 0 | 0 | 0 | 3 | 98 | 0 |

## Device-driver details

### `c0004\amd3dvcache.inf`

- Driver version: `1.0.0.10`; Class: `System`; KMDF: `1.15`; UMDF: `NotDeclared`

| Device | Device identifier | Identifier type | Install section | WS2016 | WS2019 | WS2022 | WS2025 |
|---|---|---|---|---|---|---|---|
| AMD 3D V-Cache Performance Optimizer | `ACPI\AMDI0101` | ACPI-enumerated PnP hardware ID | `Amd3dvcache_Device` | No(Build) | No(Build) | Native | Native |

### `c0004\amdappcompat.inf`

- Driver version: `1.0.0.3`; Class: `System`; KMDF: `1.15`; UMDF: `NotDeclared`

| Device | Device identifier | Identifier type | Install section | WS2016 | WS2019 | WS2022 | WS2025 |
|---|---|---|---|---|---|---|---|
| AMD Application Compatibility Database | `ACPI\AMDI0204` | ACPI-enumerated PnP hardware ID | `AmdAppCompat_Device` | No(Build) | Native | Native | Native |

### `c0004\amdas4.inf`

- Driver version: `1.2.0.0046`; Class: `System`; KMDF: `NotDeclared`; UMDF: `NotDeclared`

| Device | Device identifier | Identifier type | Install section | WS2016 | WS2019 | WS2022 | WS2025 |
|---|---|---|---|---|---|---|---|
| AmdAS4 Device | `ACPI\AMDI0050` | ACPI-enumerated PnP hardware ID | `AmdAS4` | Native | Native | Native | Native |
| AmdAS4 Device | `ACPI\ASD0001` | ACPI-enumerated PnP hardware ID | `AmdAS4` | Native | Native | Native | Native |

### `c0004\amdcir.inf`

- Driver version: `3.2.4.0135`; Class: `HIDClass`; KMDF: `NotDeclared`; UMDF: `NotDeclared`

| Device | Device identifier | Identifier type | Install section | WS2016 | WS2019 | WS2022 | WS2025 |
|---|---|---|---|---|---|---|---|
| AMD CIR Driver | `*AMDC001` | Generic PnP hardware ID | `AMDCIR64` | Native | Native | Native | Native |
| AMD CIR Driver | `*AMDC002` | Generic PnP hardware ID | `AMDCIR64` | Native | Native | Native | Native |
| AMD CIR Driver | `*AMDC003` | Generic PnP hardware ID | `AMDCIR64` | Native | Native | Native | Native |

### `c0004\amdgpio2.inf`

- Driver version: `2.2.0.134`; Class: `System`; KMDF: `NotDeclared`; UMDF: `NotDeclared`

| Device | Device identifier | Identifier type | Install section | WS2016 | WS2019 | WS2022 | WS2025 |
|---|---|---|---|---|---|---|---|
| AMD GPIO Controller | `ACPI\AMD0030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native |
| AMD GPIO Controller | `ACPI\AMDI0030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native |
| AMD GPIO Controller | `ACPI\AMDI0031` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native |
| AMD GPIO Controller | `ACPI\GPIO0010` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native |

### `c0004\amdgpio3.inf`

- Driver version: `3.0.3.0000`; Class: `System`; KMDF: `NotDeclared`; UMDF: `NotDeclared`

| Device | Device identifier | Identifier type | Install section | WS2016 | WS2019 | WS2022 | WS2025 |
|---|---|---|---|---|---|---|---|
| AMD GPIO Controller | `ACPI\AMDF030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native |
| AMD GPIO Controller | `ACPI\AMDIF030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native |
| AMD GPIO Controller | `ACPI\AMDIF031` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native |

### `c0004\amdi2c.inf`

- Driver version: `1.2.0.126`; Class: `System`; KMDF: `NotDeclared`; UMDF: `NotDeclared`

| Device | Device identifier | Identifier type | Install section | WS2016 | WS2019 | WS2022 | WS2025 |
|---|---|---|---|---|---|---|---|
| AMD I2C Controller | `ACPI\AMD0010` | ACPI-enumerated PnP hardware ID | `amdi2c_Device` | Native | Native | Native | Native |
| AMD I2C Controller | `ACPI\AMDI0010` | ACPI-enumerated PnP hardware ID | `amdi2c_Device` | Native | Native | Native | Native |

### `c0004\amdinterface.inf`

- Driver version: `2.0.0.23`; Class: `System`; KMDF: `NotDeclared`; UMDF: `NotDeclared`

| Device | Device identifier | Identifier type | Install section | WS2016 | WS2019 | WS2022 | WS2025 |
|---|---|---|---|---|---|---|---|
| AMD Hetero Driver | `ACPI\AMDI0104` | ACPI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native |
| AMD PCI | `PCI\VEN_1002&DEV_145A` | PCI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native |
| AMD PCI | `PCI\VEN_1022&DEV_1116` | PCI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native |
| AMD PCI | `PCI\VEN_1022&DEV_1117` | PCI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native |
| AMD PCI | `PCI\VEN_1022&DEV_1136` | PCI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native |
| AMD PCI | `PCI\VEN_1022&DEV_1137` | PCI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native |
| AMD PCI | `PCI\VEN_1022&DEV_14AC` | PCI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native |
| AMD PCI | `PCI\VEN_1022&DEV_14DC` | PCI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native |
| AMD PCI | `PCI\VEN_1022&DEV_14DE` | PCI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native |
| AMD PCI | `PCI\VEN_1022&DEV_14EC` | PCI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native |
| AMD PCI | `PCI\VEN_1022&DEV_150D` | PCI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native |
| AMD PCI | `PCI\VEN_1022&DEV_1556` | PCI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native |
| AMD SMBUS | `PCI\VEN_1022&DEV_790B` | PCI-enumerated PnP hardware ID | `AMDPCI64` | Native | Native | Native | Native |

### `c0004\amdiov.inf`

- Driver version: `1.2.0.52`; Class: `System`; KMDF: `NotDeclared`; UMDF: `NotDeclared`

| Device | Device identifier | Identifier type | Install section | WS2016 | WS2019 | WS2022 | WS2025 |
|---|---|---|---|---|---|---|---|
| AMD IOMMU Device | `PCI\VEN_1002&DEV_5A23` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native |
| AMD IOMMU Device | `PCI\VEN_1022&DEV_13E1` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native |
| AMD IOMMU Device | `PCI\VEN_1022&DEV_1419` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native |
| AMD IOMMU Device | `PCI\VEN_1022&DEV_1423` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native |
| AMD IOMMU Device | `PCI\VEN_1022&DEV_1437` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native |
| AMD IOMMU Device | `PCI\VEN_1022&DEV_1451` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native |
| AMD IOMMU Device | `PCI\VEN_1022&DEV_1481` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native |
| AMD IOMMU Device | `PCI\VEN_1022&DEV_1577` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native |
| AMD IOMMU Device | `PCI\VEN_1022&DEV_164F` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native |

### `c0004\amdmicropep.inf`

- Driver version: `1.0.44.0`; Class: `System`; KMDF: `1.11`; UMDF: `NotDeclared`

| Device | Device identifier | Identifier type | Install section | WS2016 | WS2019 | WS2022 | WS2025 |
|---|---|---|---|---|---|---|---|
| AMD Micro PEP Device | `ACPI\AMD0004` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native |
| AMD Micro PEP Device | `ACPI\AMD0005` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native |
| AMD Micro PEP Device | `ACPI\AMDI0005` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native |
| AMD Micro PEP Device | `ACPI\AMDI0006` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native |
| AMD Micro PEP Device | `ACPI\AMDI0007` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native |
| AMD Micro PEP Device | `ACPI\AMDI0008` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native |
| AMD Micro PEP Device | `ACPI\AMDI0009` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native |
| AMD Micro PEP Device | `ACPI\AMDI000A` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native |
| AMD Micro PEP Device | `ACPI\AMDI000B` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native |

### `c0004\amdoemprov.inf`

- Driver version: `1.0.0.6`; Class: `System`; KMDF: `NotDeclared`; UMDF: `NotDeclared`

| Device | Device identifier | Identifier type | Install section | WS2016 | WS2019 | WS2022 | WS2025 |
|---|---|---|---|---|---|---|---|
| AMD Provisioning for OEM | `ACPI\AMDI0053` | ACPI-enumerated PnP hardware ID | `AMDPPMPF_DEV` | No(Build) | No(Build) | No(Build) | Native |

### `c0004\amdpcidev.inf`

- Driver version: `1.0.0.90`; Class: `System`; KMDF: `NotDeclared`; UMDF: `NotDeclared`

| Device | Device identifier | Identifier type | Install section | WS2016 | WS2019 | WS2022 | WS2025 |
|---|---|---|---|---|---|---|---|
| AMD PCI | `PCI\VEN_1002&DEV_145A` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native |
| AMD PCI | `PCI\VEN_1022&DEV_1455` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native |
| AMD PCI | `PCI\VEN_1022&DEV_145A` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native |
| AMD PCI | `PCI\VEN_1022&DEV_1485` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native |
| AMD PCI | `PCI\VEN_1022&DEV_148A` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native |
| AMD PCI | `PCI\VEN_1022&DEV_14DE` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native |

### `c0004\amdpmf.inf`

- Driver version: `24.0.5.0`; Class: `System`; KMDF: `NotDeclared`; UMDF: `NotDeclared`

| Device | Device identifier | Identifier type | Install section | WS2016 | WS2019 | WS2022 | WS2025 |
|---|---|---|---|---|---|---|---|
| AMD PMF | `ACPI\AMDI0100` | ACPI-enumerated PnP hardware ID | `AMDPMF_INSTALL.NTamd64` | Native | Native | Native | Native |
| AMD PMF | `ACPI\AMDI0102` | ACPI-enumerated PnP hardware ID | `AMDPMF_INSTALL.NTamd64` | Native | Native | Native | Native |

### `c0004\amdppkg.inf`

- Driver version: `8.0.0.52`; Class: `System`; KMDF: `NotDeclared`; UMDF: `NotDeclared`

| Device | Device identifier | Identifier type | Install section | WS2016 | WS2019 | WS2022 | WS2025 |
|---|---|---|---|---|---|---|---|
| AMD Provisioning Packages | `ACPI\AMDI0052` | ACPI-enumerated PnP hardware ID | `InstallSection_Win11_22H2` | No | No | No | Native |
| AMD Provisioning Packages | `ACPI\AMDI0052` | ACPI-enumerated PnP hardware ID | `InstallSection_Win10` | Native | Native | Native | No |

### `c0004\amdpsp.inf`

- Driver version: `5.39.0.0`; Class: `SecurityDevices`; KMDF: `1.13`; UMDF: `NotDeclared`

| Device | Device identifier | Identifier type | Install section | WS2016 | WS2019 | WS2022 | WS2025 |
|---|---|---|---|---|---|---|---|
| AMD PSP 10.0 Device | `PCI\VEN_1022&DEV_15DF` | PCI-enumerated PnP hardware ID | `amdpsp_Device_100` | Native | Native | Native | Native |
| AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_1134` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | Native | Native | Native |
| AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_1486` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | Native | Native | Native |
| AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_14CA` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | Native | Native | Native |
| AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_156E` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | Native | Native | Native |
| AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_15C7` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | Native | Native | Native |
| AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_1649` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | Native | Native | Native |
| AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_17E0` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | Native | Native | Native |
| AMD PSP Device | `PCI\VEN_1022&DEV_13EC` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | Native | Native | Native |
| AMD PSP Device | `PCI\VEN_1022&DEV_1456` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | Native | Native | Native |
| AMD PSP Device | `PCI\VEN_1022&DEV_1537` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | Native | Native | Native |
| AMD PSP Device | `PCI\VEN_1022&DEV_1578` | PCI-enumerated PnP hardware ID | `amdpsp_Device` | Native | Native | Native | Native |

### `c0004\amdsfhkmdf.inf`

- Driver version: `1.0.0.341`; Class: `System`; KMDF: `1.15`; UMDF: `NotDeclared`

| Device | Device identifier | Identifier type | Install section | WS2016 | WS2019 | WS2022 | WS2025 |
|---|---|---|---|---|---|---|---|
| AMD Sensor Fusion Hub | `PCI\VEN_1022&DEV_15E4` | PCI-enumerated PnP hardware ID | `amdsfhkmdf_Device` | Native | Native | Native | Native |

### `c0004\amdsfhkmdfi2c.inf`

- Driver version: `1.0.0.86`; Class: `System`; KMDF: `1.15`; UMDF: `NotDeclared`

| Device | Device identifier | Identifier type | Install section | WS2016 | WS2019 | WS2022 | WS2025 |
|---|---|---|---|---|---|---|---|
| AMD SFH KMDF I2C | `PCI\VEN_1022&DEV_15E6` | PCI-enumerated PnP hardware ID | `amdsfhkmdf_Device` | Native | Native | Native | Native |

### `c0004\amdsfhspbi2c.inf`

- Driver version: `1.0.0.86`; Class: `System`; KMDF: `NotDeclared`; UMDF: `NotDeclared`

| Device | Device identifier | Identifier type | Install section | WS2016 | WS2019 | WS2022 | WS2025 |
|---|---|---|---|---|---|---|---|
| AMD SFH I2C Controller | `ACPI\AMDI0011` | ACPI-enumerated PnP hardware ID | `amdsfhspbi2c_Device` | Native | Native | Native | Native |

### `c0004\amdsfhumdf.inf`

- Driver version: `1.0.0.341`; Class: `Sensor`; KMDF: `NotDeclared`; UMDF: `2.15.0`

| Device | Device identifier | Identifier type | Install section | WS2016 | WS2019 | WS2022 | WS2025 |
|---|---|---|---|---|---|---|---|
| AMD UMDF Sensor | `ACPI\AMDI0080` | ACPI-enumerated PnP hardware ID | `amdsfhumdf_Inst_Win11` | No(Build) | No | No | Native |
| AMD UMDF Sensor | `ACPI\AMDI0080` | ACPI-enumerated PnP hardware ID | `amdsfhumdf_Inst_Win10` | No(Build) | Native | Native | No |

### `c0004\amduart.inf`

- Driver version: `1.2.0.119`; Class: `System`; KMDF: `NotDeclared`; UMDF: `NotDeclared`

| Device | Device identifier | Identifier type | Install section | WS2016 | WS2019 | WS2022 | WS2025 |
|---|---|---|---|---|---|---|---|
| AMD UART Controller | `ACPI\AMD0020` | ACPI-enumerated PnP hardware ID | `amduart_Inst` | Native | Native | Native | Native |
| AMD UART Controller | `ACPI\AMDI0020` | ACPI-enumerated PnP hardware ID | `amduart_Inst` | Native | Native | Native | Native |
| AMD UART Controller | `ACPI\AMDI0022` | ACPI-enumerated PnP hardware ID | `amduart_Inst` | Native | Native | Native | Native |

### `c0004\amdusb4cm.inf`

- Driver version: `1.0.0.42`; Class: `System`; KMDF: `1.19`; UMDF: `NotDeclared`

| Device | Device identifier | Identifier type | Install section | WS2016 | WS2019 | WS2022 | WS2025 |
|---|---|---|---|---|---|---|---|
| AMD USB4 Host Router | `PCI\VEN_1022&DEV_15C4` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native |
| AMD USB4 Host Router | `PCI\VEN_1022&DEV_15C5` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native |
| AMD USB4 Host Router | `PCI\VEN_1022&DEV_162E` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native |
| AMD USB4 Host Router | `PCI\VEN_1022&DEV_162F` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native |
| AMD USB4 Host Router | `PCI\VEN_1022&DEV_1668` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native |
| AMD USB4 Host Router | `PCI\VEN_1022&DEV_1669` | PCI-enumerated PnP hardware ID | `amdusb4cm_Inst` | Native | Native | Native | Native |

### `c0004\amdusb4net.inf`

- Driver version: `1.0.0.6`; Class: `Net`; KMDF: `NotDeclared`; UMDF: `NotDeclared`

| Device | Device identifier | Identifier type | Install section | WS2016 | WS2019 | WS2022 | WS2025 |
|---|---|---|---|---|---|---|---|
| AMD USB4NET | `{b85b7c50-6a01-11d2-b841-00c04fad5171}\AMDUSB4NET` | Device-class-specific ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native |
| AMD USB4NET | `{b85b7c50-6a01-11d2-b841-00c04fad5171}\Usb4Net` | Device-class-specific ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native |
| AMD USB4NET | `root\AMDUSB4NET_a` | Root-enumerated PnP hardware ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native |
| AMD USB4NET | `root\AMDUSB4NET_b` | Root-enumerated PnP hardware ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native |
| AMD USB4NET | `root\AMDUSB4NET_c` | Root-enumerated PnP hardware ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native |
| AMD USB4NET | `root\AMDUSB4NET_d` | Root-enumerated PnP hardware ID | `AmdUsb4Net.ndi` | Native | Native | Native | Native |

### `c0004\amdusb4pcifilter.inf`

- Driver version: `1.0.0.10`; Class: `System`; KMDF: `NotDeclared`; UMDF: `NotDeclared`

| Device | Device identifier | Identifier type | Install section | WS2016 | WS2019 | WS2022 | WS2025 |
|---|---|---|---|---|---|---|---|
| PCI Express Root Port | `PCI\VEN_1022&DEV_14CD&SUBSYS_14531022&REV_00` | PCI-enumerated PnP hardware ID | `amdusb4pcifilter` | Native | Native | Excluded | Excluded |
| PCI Express Root Port | `PCI\VEN_1022&DEV_14EF&SUBSYS_14531022&REV_00` | PCI-enumerated PnP hardware ID | `amdusb4pcifilter` | Native | Native | Excluded | Excluded |
| PCI Express Root Port | `PCI\VEN_1022&DEV_14EF&SUBSYS_14531022&REV_01` | PCI-enumerated PnP hardware ID | `amdusb4pcifilter` | Native | Native | Excluded | Excluded |

### `c0004\amdusbhubfilter.inf`

- Driver version: `1.0.0.11`; Class: `USB`; KMDF: `NotDeclared`; UMDF: `NotDeclared`

| Device | Device identifier | Identifier type | Install section | WS2016 | WS2019 | WS2022 | WS2025 |
|---|---|---|---|---|---|---|---|
| USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15C0&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Excluded | Excluded |
| USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15C1&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Excluded | Excluded |
| USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15C2&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Excluded | Excluded |
| USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15C3&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Excluded | Excluded |
| USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15D6&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Excluded | Excluded |
| USB Root Hub (USB 3.0) | `USB\ROOT_HUB30&VID1022&PID15D7&REV0000` | USB-enumerated PnP hardware ID | `amdusbhubfilter_Inst` | Native | Native | Excluded | Excluded |

### `c0004\amdwirelessbutton.inf`

- Driver version: `1.0.0.6`; Class: `HIDClass`; KMDF: `1.15`; UMDF: `NotDeclared`

| Device | Device identifier | Identifier type | Install section | WS2016 | WS2019 | WS2022 | WS2025 |
|---|---|---|---|---|---|---|---|
| AMD Wireless Button Driver | `ACPI\AMDI0051` | ACPI-enumerated PnP hardware ID | `amdwirelessbutton_DeviceWin11` | No(Build) | No | No | Native |
| AMD Wireless Button Driver | `ACPI\AMDI0051` | ACPI-enumerated PnP hardware ID | `amdwirelessbutton_Device` | No(Build) | Native | Native | No |

### `c0004\ams_mailboxdrv.inf`

- Driver version: `4.5.0.1020`; Class: `System`; KMDF: `NotDeclared`; UMDF: `NotDeclared`

| Device | Device identifier | Identifier type | Install section | WS2016 | WS2019 | WS2022 | WS2025 |
|---|---|---|---|---|---|---|---|
| AMS-MailBoxDrv | `ACPI\AMDI0090` | ACPI-enumerated PnP hardware ID | `AMS-MailBoxDrv_Device` | Native | Native | Native | Native |

### `c0004\plutonnull.inf`

- Driver version: `1.0.0.0`; Class: `SecurityDevices`; KMDF: `NotDeclared`; UMDF: `NotDeclared`

| Device | Device identifier | Identifier type | Install section | WS2016 | WS2019 | WS2022 | WS2025 |
|---|---|---|---|---|---|---|---|
| AMD NULL Driver for Microsoft Pluton Security Processor | `ACPI\MSFT0200` | ACPI-enumerated PnP hardware ID | `Null_Pluton_Device` | Native | Native | Native | Excluded |

### `c0004\smbusamd.inf`

- Driver version: `5.12.0.44`; Class: `System`; KMDF: `NotDeclared`; UMDF: `NotDeclared`

| Device | Device identifier | Identifier type | Install section | WS2016 | WS2019 | WS2022 | WS2025 |
|---|---|---|---|---|---|---|---|
| AMD SMBus | `PCI\VEN_1002&DEV_4353` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native |
| AMD SMBus | `PCI\VEN_1002&DEV_4363` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native |
| AMD SMBus | `PCI\VEN_1002&DEV_4372` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native |
| AMD SMBus | `PCI\VEN_1002&DEV_4385` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native |
| AMD SMBus | `PCI\VEN_1022&DEV_780B` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native |
| AMD SMBus | `PCI\VEN_1022&DEV_790B` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native |

### `c0004\usbfilter.inf`

- Driver version: `2.1.11.304`; Class: `USB`; KMDF: `NotDeclared`; UMDF: `NotDeclared`

| Device | Device identifier | Identifier type | Install section | WS2016 | WS2019 | WS2022 | WS2025 |
|---|---|---|---|---|---|---|---|
| AMD USB Filter Driver | `{36FC9E60-C465-11CF-8056-444553540000}\usbfilter` | Device-class-specific ID | `usbfilter` | Native | Native | Native | Native |

### `c0004\zenpromnf.inf`

- Driver version: `1.1.0.3`; Class: `NetService`; KMDF: `NotDeclared`; UMDF: `NotDeclared`

| Device | Device identifier | Identifier type | Install section | WS2016 | WS2019 | WS2022 | WS2025 |
|---|---|---|---|---|---|---|---|
| ZenProM S0i3 Network Filter | `ZenProMnf` | Network software component ID | `Install` | Native | Native | Native | Native |

