# AMD Chipset Software 3.08.17.735 - Windows Server static analysis

> Static INF/WDF analysis only. `NativeCandidate` and `ProjectionCandidate` do not prove runtime compatibility.

## Release summary

| Windows Server | Native INF | Projection INF | WDF review | Review | Not applicable | Native devices | Projection devices |
|---|---:|---:|---:|---:|---:|---:|---:|
| Windows Server 2016 | 16 | 0 | 0 | 0 | 0 | 52 | 0 |
| Windows Server 2019 | 16 | 0 | 0 | 0 | 0 | 52 | 0 |
| Windows Server 2022 | 16 | 0 | 0 | 0 | 0 | 52 | 0 |
| Windows Server 2025 | 16 | 0 | 0 | 0 | 0 | 52 | 0 |

## Device-driver details

### `c0005\amdas4.inf`

- Driver version: `1.2.0.0046`; Class: `System`; KMDF: `NotDeclared`; UMDF: `NotDeclared`

| Device | Device identifier | Identifier type | Install section | WS2016 | WS2019 | WS2022 | WS2025 |
|---|---|---|---|---|---|---|---|
| AmdAS4 Device | `ACPI\AMDI0050` | ACPI-enumerated PnP hardware ID | `AmdAS4` | Native | Native | Native | Native |
| AmdAS4 Device | `ACPI\ASD0001` | ACPI-enumerated PnP hardware ID | `AmdAS4` | Native | Native | Native | Native |

### `c0005\amdcir.inf`

- Driver version: `3.2.4.0135`; Class: `HIDClass`; KMDF: `NotDeclared`; UMDF: `NotDeclared`

| Device | Device identifier | Identifier type | Install section | WS2016 | WS2019 | WS2022 | WS2025 |
|---|---|---|---|---|---|---|---|
| AMD CIR Driver | `*AMDC001` | Generic PnP hardware ID | `AMDCIR64` | Native | Native | Native | Native |
| AMD CIR Driver | `*AMDC002` | Generic PnP hardware ID | `AMDCIR64` | Native | Native | Native | Native |
| AMD CIR Driver | `*AMDC003` | Generic PnP hardware ID | `AMDCIR64` | Native | Native | Native | Native |

### `c0005\amdgpio2.inf`

- Driver version: `2.2.0.130`; Class: `System`; KMDF: `NotDeclared`; UMDF: `NotDeclared`

| Device | Device identifier | Identifier type | Install section | WS2016 | WS2019 | WS2022 | WS2025 |
|---|---|---|---|---|---|---|---|
| AMD GPIO Controller | `ACPI\AMD0030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native |
| AMD GPIO Controller | `ACPI\AMDI0030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native |
| AMD GPIO Controller | `ACPI\AMDI0031` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native |
| AMD GPIO Controller | `ACPI\GPIO0010` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native |

### `c0005\amdgpio3.inf`

- Driver version: `2.0.1.0000`; Class: `System`; KMDF: `NotDeclared`; UMDF: `NotDeclared`

| Device | Device identifier | Identifier type | Install section | WS2016 | WS2019 | WS2022 | WS2025 |
|---|---|---|---|---|---|---|---|
| AMD GPIO Controller | `ACPI\AMDF030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native |
| AMD GPIO Controller | `ACPI\AMDIF030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native |

### `c0005\amdi2c.inf`

- Driver version: `1.2.0.118`; Class: `System`; KMDF: `NotDeclared`; UMDF: `NotDeclared`

| Device | Device identifier | Identifier type | Install section | WS2016 | WS2019 | WS2022 | WS2025 |
|---|---|---|---|---|---|---|---|
| AMD I2C Controller | `ACPI\AMD0010` | ACPI-enumerated PnP hardware ID | `amdi2c_Device` | Native | Native | Native | Native |
| AMD I2C Controller | `ACPI\AMDI0010` | ACPI-enumerated PnP hardware ID | `amdi2c_Device` | Native | Native | Native | Native |

### `c0005\amdiov.inf`

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

### `c0005\amdmicropep.inf`

- Driver version: `1.0.29.0`; Class: `System`; KMDF: `1.11`; UMDF: `NotDeclared`

| Device | Device identifier | Identifier type | Install section | WS2016 | WS2019 | WS2022 | WS2025 |
|---|---|---|---|---|---|---|---|
| AMD Micro PEP Device | `ACPI\AMD0004` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native |
| AMD Micro PEP Device | `ACPI\AMD0005` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native |
| AMD Micro PEP Device | `ACPI\AMDI0005` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native |
| AMD Micro PEP Device | `ACPI\AMDI0006` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native |
| AMD Micro PEP Device | `ACPI\AMDI0007` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native |

### `c0005\amdpcidev.inf`

- Driver version: `1.0.0.83`; Class: `System`; KMDF: `NotDeclared`; UMDF: `NotDeclared`

| Device | Device identifier | Identifier type | Install section | WS2016 | WS2019 | WS2022 | WS2025 |
|---|---|---|---|---|---|---|---|
| AMD PCI | `PCI\VEN_1022&DEV_1455` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native |
| AMD PCI | `PCI\VEN_1022&DEV_145A` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native |
| AMD PCI | `PCI\VEN_1022&DEV_1485` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native |
| AMD PCI | `PCI\VEN_1022&DEV_148A` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native |

### `c0005\amdpsp.inf`

- Driver version: `5.17.0.0`; Class: `SecurityDevices`; KMDF: `1.11`; UMDF: `NotDeclared`

| Device | Device identifier | Identifier type | Install section | WS2016 | WS2019 | WS2022 | WS2025 |
|---|---|---|---|---|---|---|---|
| AMD PSP 1.0 Device | `PCI\VEN_1022&DEV_1537` | PCI-enumerated PnP hardware ID | `amdpsp_Device_10` | Native | Native | Native | Native |
| AMD PSP 10.0 Device | `PCI\VEN_1022&DEV_15DF` | PCI-enumerated PnP hardware ID | `amdpsp_Device_100` | Native | Native | Native | Native |
| AMD PSP 10.0 Device | `PCI\VEN_1022&DEV_1649` | PCI-enumerated PnP hardware ID | `amdpsp_Device_100` | Native | Native | Native | Native |
| AMD PSP 11.0 Device | `PCI\VEN_1022&DEV_1486` | PCI-enumerated PnP hardware ID | `amdpsp_Device_110` | Native | Native | Native | Native |
| AMD PSP 12.0 Device | `PCI\VEN_1022&DEV_13EC` | PCI-enumerated PnP hardware ID | `amdpsp_Device_120` | Native | Native | Native | Native |
| AMD PSP 2.0 Device | `PCI\VEN_1022&DEV_1578` | PCI-enumerated PnP hardware ID | `amdpsp_Device_20` | Native | Native | Native | Native |
| AMD PSP 3.0 Device | `PCI\VEN_1022&DEV_1456` | PCI-enumerated PnP hardware ID | `amdpsp_Device_30` | Native | Native | Native | Native |

### `c0005\amdsfhkmdf.inf`

- Driver version: `1.0.0.316`; Class: `System`; KMDF: `1.15`; UMDF: `NotDeclared`

| Device | Device identifier | Identifier type | Install section | WS2016 | WS2019 | WS2022 | WS2025 |
|---|---|---|---|---|---|---|---|
| AMD Sensor Fusion Hub | `PCI\VEN_1022&DEV_15E4` | PCI-enumerated PnP hardware ID | `amdsfhkmdf_Device` | Native | Native | Native | Native |

### `c0005\amdsfhkmdfi2c.inf`

- Driver version: `1.0.0.86`; Class: `System`; KMDF: `1.15`; UMDF: `NotDeclared`

| Device | Device identifier | Identifier type | Install section | WS2016 | WS2019 | WS2022 | WS2025 |
|---|---|---|---|---|---|---|---|
| AMD SFH KMDF I2C | `PCI\VEN_1022&DEV_15E6` | PCI-enumerated PnP hardware ID | `amdsfhkmdf_Device` | Native | Native | Native | Native |

### `c0005\amdsfhspbi2c.inf`

- Driver version: `1.0.0.86`; Class: `System`; KMDF: `NotDeclared`; UMDF: `NotDeclared`

| Device | Device identifier | Identifier type | Install section | WS2016 | WS2019 | WS2022 | WS2025 |
|---|---|---|---|---|---|---|---|
| AMD SFH I2C Controller | `ACPI\AMDI0011` | ACPI-enumerated PnP hardware ID | `amdsfhspbi2c_Device` | Native | Native | Native | Native |

### `c0005\amdsfhumdf.inf`

- Driver version: `1.0.0.316`; Class: `Sensor`; KMDF: `NotDeclared`; UMDF: `2.15.0`

| Device | Device identifier | Identifier type | Install section | WS2016 | WS2019 | WS2022 | WS2025 |
|---|---|---|---|---|---|---|---|
| AMD UMDF Sensor | `ACPI\AMDI0080` | ACPI-enumerated PnP hardware ID | `amdsfhumdf_Inst` | Native | Native | Native | Native |

### `c0005\amduart.inf`

- Driver version: `1.2.0.112`; Class: `System`; KMDF: `NotDeclared`; UMDF: `NotDeclared`

| Device | Device identifier | Identifier type | Install section | WS2016 | WS2019 | WS2022 | WS2025 |
|---|---|---|---|---|---|---|---|
| AMD UART Controller | `ACPI\AMD0020` | ACPI-enumerated PnP hardware ID | `amduart_Inst` | Native | Native | Native | Native |
| AMD UART Controller | `ACPI\AMDI0020` | ACPI-enumerated PnP hardware ID | `amduart_Inst` | Native | Native | Native | Native |
| AMD UART Controller | `ACPI\AMDI0022` | ACPI-enumerated PnP hardware ID | `amduart_Inst` | Native | Native | Native | Native |

### `c0005\smbusamd.inf`

- Driver version: `5.12.0.38`; Class: `System`; KMDF: `NotDeclared`; UMDF: `NotDeclared`

| Device | Device identifier | Identifier type | Install section | WS2016 | WS2019 | WS2022 | WS2025 |
|---|---|---|---|---|---|---|---|
| AMD SMBus | `PCI\VEN_1002&DEV_4353` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native |
| AMD SMBus | `PCI\VEN_1002&DEV_4363` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native |
| AMD SMBus | `PCI\VEN_1002&DEV_4372` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native |
| AMD SMBus | `PCI\VEN_1002&DEV_4385` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native |
| AMD SMBus | `PCI\VEN_1022&DEV_780B` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native |
| AMD SMBus | `PCI\VEN_1022&DEV_790B` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native |

### `c0005\usbfilter.inf`

- Driver version: `2.1.11.304`; Class: `USB`; KMDF: `NotDeclared`; UMDF: `NotDeclared`

| Device | Device identifier | Identifier type | Install section | WS2016 | WS2019 | WS2022 | WS2025 |
|---|---|---|---|---|---|---|---|
| AMD USB Filter Driver | `{36FC9E60-C465-11CF-8056-444553540000}\usbfilter` | Device-class-specific ID | `usbfilter` | Native | Native | Native | Native |

