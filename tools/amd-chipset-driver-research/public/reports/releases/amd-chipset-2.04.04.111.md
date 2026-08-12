# AMD Chipset Software 2.04.04.111 - Windows Server static analysis

> Static INF/WDF analysis only. `NativeCandidate` and `ProjectionCandidate` do not prove runtime compatibility.

## Release summary

| Windows Server | Native INF | Projection INF | WDF review | Review | Not applicable | Native devices | Projection devices |
|---|---:|---:|---:|---:|---:|---:|---:|
| Windows Server 2016 | 22 | 2 | 0 | 0 | 0 | 109 | 9 |
| Windows Server 2019 | 22 | 2 | 0 | 0 | 0 | 109 | 9 |
| Windows Server 2022 | 22 | 2 | 0 | 0 | 0 | 109 | 9 |
| Windows Server 2025 | 22 | 2 | 0 | 0 | 0 | 109 | 9 |

## Device-driver details

### `d4_Data1.cab_9ed7c73e0e1f\amdas4.inf`

- Driver version: `1.2.0.0046`; Class: `System`; KMDF: `NotDeclared`; UMDF: `NotDeclared`

| Device | Device identifier | Identifier type | Install section | WS2016 | WS2019 | WS2022 | WS2025 |
|---|---|---|---|---|---|---|---|
| AmdAS4 Device | `ACPI\AMDI0050` | ACPI-enumerated PnP hardware ID | `AmdAS4` | Native | Native | Native | Native |
| AmdAS4 Device | `ACPI\ASD0001` | ACPI-enumerated PnP hardware ID | `AmdAS4` | Native | Native | Native | Native |

### `d4_Data1.cab_9ed7c73e0e1f\amdcir.inf`

- Driver version: `3.2.4.0110`; Class: `HIDClass`; KMDF: `NotDeclared`; UMDF: `NotDeclared`

| Device | Device identifier | Identifier type | Install section | WS2016 | WS2019 | WS2022 | WS2025 |
|---|---|---|---|---|---|---|---|
| AMD CIR Driver | `*AMDC001` | Generic PnP hardware ID | `AMDCIR64` | Native | Native | Native | Native |
| AMD CIR Driver | `*AMDC002` | Generic PnP hardware ID | `AMDCIR64` | Native | Native | Native | Native |
| AMD CIR Driver | `*AMDC003` | Generic PnP hardware ID | `AMDCIR64` | Native | Native | Native | Native |

### `d4_Data1.cab_9ed7c73e0e1f\amdgpio2.inf`

- Driver version: `2.2.0.126`; Class: `System`; KMDF: `NotDeclared`; UMDF: `NotDeclared`

| Device | Device identifier | Identifier type | Install section | WS2016 | WS2019 | WS2022 | WS2025 |
|---|---|---|---|---|---|---|---|
| AMD GPIO Controller | `ACPI\AMD0030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native |
| AMD GPIO Controller | `ACPI\AMDI0030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native |
| AMD GPIO Controller | `ACPI\GPIO0010` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native |

### `d4_Data1.cab_9ed7c73e0e1f\amdgpio3.inf`

- Driver version: `2.0.1.0000`; Class: `System`; KMDF: `NotDeclared`; UMDF: `NotDeclared`

| Device | Device identifier | Identifier type | Install section | WS2016 | WS2019 | WS2022 | WS2025 |
|---|---|---|---|---|---|---|---|
| AMD GPIO Controller | `ACPI\AMDF030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native |
| AMD GPIO Controller | `ACPI\AMDIF030` | ACPI-enumerated PnP hardware ID | `GPIO_Inst` | Native | Native | Native | Native |

### `d4_Data1.cab_9ed7c73e0e1f\amdhub3.inf`

- Driver version: `2.0.0.0060`; Class: `USB`; KMDF: `NotDeclared`; UMDF: `NotDeclared`

| Device | Device identifier | Identifier type | Install section | WS2016 | WS2019 | WS2022 | WS2025 |
|---|---|---|---|---|---|---|---|
| AMD Root Hub(xHCI) | `AMDUSB3\ROOT_HUB3` | AMDUSB3-enumerated PnP hardware ID | `AMDHUB3` | Native | Native | Native | Native |
| AMD USB 2.0 Hub | `AMDUSB3\CLASS_09&SUBCLASS_00&PROT_01` | AMDUSB3-enumerated PnP hardware ID | `AMDHUB3` | Native | Native | Native | Native |
| AMD USB 2.0 MTT Hub | `AMDUSB3\CLASS_09&SUBCLASS_00&PROT_02` | AMDUSB3-enumerated PnP hardware ID | `AMDHUB3` | Native | Native | Native | Native |
| AMD USB 3.0 Hub | `AMDUSB3\CLASS_09&SUBCLASS_00&PROT_03` | AMDUSB3-enumerated PnP hardware ID | `AMDHUB3` | Native | Native | Native | Native |
| AMD USB Hub | `AMDUSB3\CLASS_09&SUBCLASS_00&PROT_00` | AMDUSB3-enumerated PnP hardware ID | `AMDHUB3` | Native | Native | Native | Native |
| AMD USB Hub | `AMDUSB3\CLASS_09&SUBCLASS_01` | AMDUSB3-enumerated PnP hardware ID | `AMDHUB3` | Native | Native | Native | Native |

### `d4_Data1.cab_9ed7c73e0e1f\amdhub30.inf`

- Driver version: `1.1.0.0276`; Class: `USB`; KMDF: `NotDeclared`; UMDF: `NotDeclared`

| Device | Device identifier | Identifier type | Install section | WS2016 | WS2019 | WS2022 | WS2025 |
|---|---|---|---|---|---|---|---|
| AMD USB 2.0 Hub | `AMDUSB30\CLASS_09&SUBCLASS_00&PROT_01` | AMDUSB30-enumerated PnP hardware ID | `AMDHUB30` | Projection | Projection | Projection | Projection |
| AMD USB 2.0 MTT Hub | `AMDUSB30\CLASS_09&SUBCLASS_00&PROT_02` | AMDUSB30-enumerated PnP hardware ID | `AMDHUB30` | Projection | Projection | Projection | Projection |
| AMD USB 3.0 Hub | `AMDUSB30\CLASS_09&SUBCLASS_00&PROT_03` | AMDUSB30-enumerated PnP hardware ID | `AMDHUB30` | Projection | Projection | Projection | Projection |
| AMD USB 3.0 Root Hub | `AMDUSB30\ROOT_HUB30` | AMDUSB30-enumerated PnP hardware ID | `AMDHUB30` | Projection | Projection | Projection | Projection |
| AMD USB Hub | `AMDUSB30\CLASS_09&SUBCLASS_00&PROT_00` | AMDUSB30-enumerated PnP hardware ID | `AMDHUB30` | Projection | Projection | Projection | Projection |
| AMD USB Hub | `AMDUSB30\CLASS_09&SUBCLASS_01` | AMDUSB30-enumerated PnP hardware ID | `AMDHUB30` | Projection | Projection | Projection | Projection |

### `d4_Data1.cab_9ed7c73e0e1f\amdhub31.inf`

- Driver version: `1.0.5.3`; Class: `USB`; KMDF: `NotDeclared`; UMDF: `NotDeclared`

| Device | Device identifier | Identifier type | Install section | WS2016 | WS2019 | WS2022 | WS2025 |
|---|---|---|---|---|---|---|---|
| AMD USB3.1 Root Hub | `USB\AMDROOT_HUB31&VID1022&PID43B9&VER0001000000050003` | USB-enumerated PnP hardware ID | `RootHub_Product1_Install` | Native | Native | Native | Native |
| AMD USB3.1 Root Hub | `USB\AMDROOT_HUB31&VID1022&PID43BA&VER0001000000050003` | USB-enumerated PnP hardware ID | `RootHub_Product2_Install` | Native | Native | Native | Native |
| AMD USB3.1 Root Hub | `USB\AMDROOT_HUB31&VID1022&PID43BB&VER0001000000050003` | USB-enumerated PnP hardware ID | `RootHub_Product3_Install` | Native | Native | Native | Native |
| AMD USB3.1 Root Hub | `USB\AMDROOT_HUB31&VID1022&PID43BC&VER0001000000050003` | USB-enumerated PnP hardware ID | `RootHub_Product4_Install` | Native | Native | Native | Native |
| AMD USB3.1 Root Hub | `USB\AMDROOT_HUB31&VID1022&PID43D0&VER0001000000050003` | USB-enumerated PnP hardware ID | `RootHub_Product5_Install` | Native | Native | Native | Native |
| AMD USB3.1 Root Hub | `USB\AMDROOT_HUB31&VID1022&PID43D1&VER0001000000050003` | USB-enumerated PnP hardware ID | `RootHub_Product6_Install` | Native | Native | Native | Native |
| AMD USB3.1 Root Hub | `USB\AMDROOT_HUB31&VID1022&PID43D2&VER0001000000050003` | USB-enumerated PnP hardware ID | `RootHub_Product7_Install` | Native | Native | Native | Native |
| AMD USB3.1 Root Hub | `USB\AMDROOT_HUB31&VID1022&PID43D3&VER0001000000050003` | USB-enumerated PnP hardware ID | `RootHub_Product8_Install` | Native | Native | Native | Native |
| AMD USB3.1 Root Hub | `USB\AMDROOT_HUB31&VID1022&PID43D4&VER0001000000050003` | USB-enumerated PnP hardware ID | `RootHub_Product9_Install` | Native | Native | Native | Native |
| AMD USB3.1 Root Hub | `USB\AMDROOT_HUB31&VID1022&PID43D5&VER0001000000050003` | USB-enumerated PnP hardware ID | `RootHub_Product10_Install` | Native | Native | Native | Native |
| AMD USB3.1 Root Hub | `USB\AMDROOT_HUB31&VID1022&PID43D6&VER0001000000050003` | USB-enumerated PnP hardware ID | `RootHub_Product11_Install` | Native | Native | Native | Native |
| AMD USB3.1 Root Hub | `USB\AMDROOT_HUB31&VID1022&PID43D7&VER0001000000050003` | USB-enumerated PnP hardware ID | `RootHub_Product12_Install` | Native | Native | Native | Native |
| AMD USB3.1 Root Hub | `USB\AMDROOT_HUB31&VID1022&PID43D8&VER0001000000050003` | USB-enumerated PnP hardware ID | `RootHub_Product13_Install` | Native | Native | Native | Native |
| AMD USB3.1 Root Hub | `USB\AMDROOT_HUB31&VID1022&PID43D9&VER0001000000050003` | USB-enumerated PnP hardware ID | `RootHub_Product14_Install` | Native | Native | Native | Native |
| AMD USB3.1 Root Hub | `USB\AMDROOT_HUB31&VID1022&PID43DA&VER0001000000050003` | USB-enumerated PnP hardware ID | `RootHub_Product15_Install` | Native | Native | Native | Native |
| AMD USB3.1 Root Hub | `USB\AMDROOT_HUB31&VID1022&PID43DB&VER0001000000050003` | USB-enumerated PnP hardware ID | `RootHub_Product16_Install` | Native | Native | Native | Native |
| AMD USB3.1 Root Hub | `USB\AMDROOT_HUB31&VID1022&PID43DC&VER0001000000050003` | USB-enumerated PnP hardware ID | `RootHub_Product17_Install` | Native | Native | Native | Native |
| AMD USB3.1 Root Hub | `USB\AMDROOT_HUB31&VID1022&PID43DD&VER0001000000050003` | USB-enumerated PnP hardware ID | `RootHub_Product18_Install` | Native | Native | Native | Native |
| AMD USB3.1 Root Hub | `USB\AMDROOT_HUB31&VID1022&PID43DE&VER0001000000050003` | USB-enumerated PnP hardware ID | `RootHub_Product19_Install` | Native | Native | Native | Native |
| AMD USB3.1 Root Hub | `USB\AMDROOT_HUB31&VID1022&PID43DF&VER0001000000050003` | USB-enumerated PnP hardware ID | `RootHub_Product20_Install` | Native | Native | Native | Native |
| Generic SuperSpeed USB Hub | `USB\AMD_HUB31SS` | USB-enumerated PnP hardware ID | `Hub_Product3_Install` | Native | Native | Native | Native |
| Generic USB Hub | `USB\AMD_HUB31` | USB-enumerated PnP hardware ID | `Hub_Product2_Install` | Native | Native | Native | Native |

### `d4_Data1.cab_9ed7c73e0e1f\amdi2c.inf`

- Driver version: `1.2.0.99`; Class: `System`; KMDF: `NotDeclared`; UMDF: `NotDeclared`

| Device | Device identifier | Identifier type | Install section | WS2016 | WS2019 | WS2022 | WS2025 |
|---|---|---|---|---|---|---|---|
| AMD I2C Controller | `ACPI\AMD0010` | ACPI-enumerated PnP hardware ID | `amdi2c_Device` | Native | Native | Native | Native |
| AMD I2C Controller | `ACPI\AMDI0010` | ACPI-enumerated PnP hardware ID | `amdi2c_Device` | Native | Native | Native | Native |

### `d4_Data1.cab_9ed7c73e0e1f\amdiov.inf`

- Driver version: `1.2.0.0043`; Class: `System`; KMDF: `NotDeclared`; UMDF: `NotDeclared`

| Device | Device identifier | Identifier type | Install section | WS2016 | WS2019 | WS2022 | WS2025 |
|---|---|---|---|---|---|---|---|
| AMD IOMMU Device | `PCI\VEN_1002&DEV_5A23` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native |
| AMD IOMMU Device | `PCI\VEN_1022&DEV_1419` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native |
| AMD IOMMU Device | `PCI\VEN_1022&DEV_1423` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native |
| AMD IOMMU Device | `PCI\VEN_1022&DEV_1437` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native |
| AMD IOMMU Device | `PCI\VEN_1022&DEV_1449` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native |
| AMD IOMMU Device | `PCI\VEN_1022&DEV_1451` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native |
| AMD IOMMU Device | `PCI\VEN_1022&DEV_1481` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native |
| AMD IOMMU Device | `PCI\VEN_1022&DEV_1577` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native |
| AMD IOMMU Device | `PCI\VEN_1022&DEV_15D1` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native |
| AMD IOMMU Device | `PCI\VEN_1022&DEV_1611` | PCI-enumerated PnP hardware ID | `NULL_DRIVER` | Native | Native | Native | Native |

### `d4_Data1.cab_9ed7c73e0e1f\amdmicropep.inf`

- Driver version: `1.0.25.0`; Class: `System`; KMDF: `1.11`; UMDF: `NotDeclared`

| Device | Device identifier | Identifier type | Install section | WS2016 | WS2019 | WS2022 | WS2025 |
|---|---|---|---|---|---|---|---|
| AMD Micro PEP Device | `ACPI\AMD0004` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native |
| AMD Micro PEP Device | `ACPI\AMD0005` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native |
| AMD Micro PEP Device | `ACPI\AMDI0005` | ACPI-enumerated PnP hardware ID | `AmdMicroPEP.Install` | Native | Native | Native | Native |

### `d4_Data1.cab_9ed7c73e0e1f\amdpcidev.inf`

- Driver version: `1.0.0.0067`; Class: `System`; KMDF: `NotDeclared`; UMDF: `NotDeclared`

| Device | Device identifier | Identifier type | Install section | WS2016 | WS2019 | WS2022 | WS2025 |
|---|---|---|---|---|---|---|---|
| AMD PCI | `PCI\VEN_1022&DEV_1455` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native |
| AMD PCI | `PCI\VEN_1022&DEV_145A` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native |
| AMD PCI | `PCI\VEN_1022&DEV_1485` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native |
| AMD PCI | `PCI\VEN_1022&DEV_148A` | PCI-enumerated PnP hardware ID | `AMDPCIDev_Inst` | Native | Native | Native | Native |

### `d4_Data1.cab_9ed7c73e0e1f\amdpsp.inf`

- Driver version: `4.10.0.1`; Class: `SecurityDevices`; KMDF: `NotDeclared`; UMDF: `NotDeclared`

| Device | Device identifier | Identifier type | Install section | WS2016 | WS2019 | WS2022 | WS2025 |
|---|---|---|---|---|---|---|---|
| AMD PSP 3.0 Device | `PCI\VEN_1022&DEV_1456` | PCI-enumerated PnP hardware ID | `amdpsp_Device_30` | Native | Native | Native | Native |
| AMD PSP 3.0 Device | `PCI\VEN_1022&DEV_1486` | PCI-enumerated PnP hardware ID | `amdpsp_Device_30` | Native | Native | Native | Native |
| AMD PSP 3.0 Device | `PCI\VEN_1022&DEV_15dF` | PCI-enumerated PnP hardware ID | `amdpsp_Device_30` | Native | Native | Native | Native |

### `d4_Data1.cab_9ed7c73e0e1f\amdrhub3.inf`

- Driver version: `1.0.0.0012`; Class: `USB`; KMDF: `NotDeclared`; UMDF: `NotDeclared`

| Device | Device identifier | Identifier type | Install section | WS2016 | WS2019 | WS2022 | WS2025 |
|---|---|---|---|---|---|---|---|
| AMD Root Hub(xHCI) | `AMDUSB3\ROOT_HUB31` | AMDUSB3-enumerated PnP hardware ID | `AMDHUB3` | Native | Native | Native | Native |
| AMD USB 2.0 Hub | `AMDUSB3\CLASS_09&SUBCLASS_00&PROT_01` | AMDUSB3-enumerated PnP hardware ID | `AMDHUB3` | Native | Native | Native | Native |
| AMD USB 2.0 MTT Hub | `AMDUSB3\CLASS_09&SUBCLASS_00&PROT_02` | AMDUSB3-enumerated PnP hardware ID | `AMDHUB3` | Native | Native | Native | Native |
| AMD USB 3.1 Hub | `AMDUSB3\CLASS_09&SUBCLASS_00&PROT_03` | AMDUSB3-enumerated PnP hardware ID | `AMDHUB3` | Native | Native | Native | Native |
| AMD USB Hub | `AMDUSB3\CLASS_09&SUBCLASS_00&PROT_00` | AMDUSB3-enumerated PnP hardware ID | `AMDHUB3` | Native | Native | Native | Native |
| AMD USB Hub | `AMDUSB3\CLASS_09&SUBCLASS_01` | AMDUSB3-enumerated PnP hardware ID | `AMDHUB3` | Native | Native | Native | Native |

### `d4_Data1.cab_9ed7c73e0e1f\amdrxhc.inf`

- Driver version: `1.0.0.0012`; Class: `USB`; KMDF: `NotDeclared`; UMDF: `NotDeclared`

| Device | Device identifier | Identifier type | Install section | WS2016 | WS2019 | WS2022 | WS2025 |
|---|---|---|---|---|---|---|---|
| AMD Radeon USB3.1 Host Controller - 1.1 | `PCI\VEN_1002&DEV_7316` | PCI-enumerated PnP hardware ID | `AMDXHCI` | Native | Native | Native | Native |
| AMD USB3.1 Host Controller - 1.1 | `PCI\VEN_1022&DEV_15E0` | PCI-enumerated PnP hardware ID | `AMDXHCI` | Native | Native | Native | Native |
| AMD USB3.1 Host Controller - 1.1 | `PCI\VEN_1022&DEV_15E1` | PCI-enumerated PnP hardware ID | `AMDXHCI` | Native | Native | Native | Native |
| AMD USB3.1 Host Controller - 1.1 | `PCI\VEN_1022&DEV_15E5` | PCI-enumerated PnP hardware ID | `AMDXHCI` | Native | Native | Native | Native |

### `d4_Data1.cab_9ed7c73e0e1f\amdsfhkmdf.inf`

- Driver version: `1.0.0.300`; Class: `System`; KMDF: `1.15`; UMDF: `NotDeclared`

| Device | Device identifier | Identifier type | Install section | WS2016 | WS2019 | WS2022 | WS2025 |
|---|---|---|---|---|---|---|---|
| AMD Sensor Fusion Hub | `PCI\VEN_1022&DEV_15E4` | PCI-enumerated PnP hardware ID | `amdsfhkmdf_Device` | Native | Native | Native | Native |

### `d4_Data1.cab_9ed7c73e0e1f\amdsfhkmdfi2c.inf`

- Driver version: `1.0.0.86`; Class: `System`; KMDF: `1.15`; UMDF: `NotDeclared`

| Device | Device identifier | Identifier type | Install section | WS2016 | WS2019 | WS2022 | WS2025 |
|---|---|---|---|---|---|---|---|
| AMD SFH KMDF I2C | `PCI\VEN_1022&DEV_15E6` | PCI-enumerated PnP hardware ID | `amdsfhkmdf_Device` | Native | Native | Native | Native |

### `d4_Data1.cab_9ed7c73e0e1f\amdsfhspbi2c.inf`

- Driver version: `1.0.0.86`; Class: `System`; KMDF: `NotDeclared`; UMDF: `NotDeclared`

| Device | Device identifier | Identifier type | Install section | WS2016 | WS2019 | WS2022 | WS2025 |
|---|---|---|---|---|---|---|---|
| AMD SFH I2C Controller | `ACPI\AMDI0011` | ACPI-enumerated PnP hardware ID | `amdsfhspbi2c_Device` | Native | Native | Native | Native |

### `d4_Data1.cab_9ed7c73e0e1f\amdsfhumdf.inf`

- Driver version: `1.0.0.300`; Class: `Sensor`; KMDF: `NotDeclared`; UMDF: `2.15.0`

| Device | Device identifier | Identifier type | Install section | WS2016 | WS2019 | WS2022 | WS2025 |
|---|---|---|---|---|---|---|---|
| AMD UMDF Sensor | `ACPI\AMDI0080` | ACPI-enumerated PnP hardware ID | `amdsfhumdf_Inst` | Native | Native | Native | Native |

### `d4_Data1.cab_9ed7c73e0e1f\amduart.inf`

- Driver version: `1.2.0.106`; Class: `System`; KMDF: `NotDeclared`; UMDF: `NotDeclared`

| Device | Device identifier | Identifier type | Install section | WS2016 | WS2019 | WS2022 | WS2025 |
|---|---|---|---|---|---|---|---|
| AMD UART Controller | `ACPI\AMD0020` | ACPI-enumerated PnP hardware ID | `amduart_Inst` | Native | Native | Native | Native |
| AMD UART Controller | `ACPI\AMDI0020` | ACPI-enumerated PnP hardware ID | `amduart_Inst` | Native | Native | Native | Native |

### `d4_Data1.cab_9ed7c73e0e1f\amdxhc.inf`

- Driver version: `1.1.0.0276`; Class: `USB`; KMDF: `NotDeclared`; UMDF: `NotDeclared`

| Device | Device identifier | Identifier type | Install section | WS2016 | WS2019 | WS2022 | WS2025 |
|---|---|---|---|---|---|---|---|
| AMD USB 3.0 Host Controller | `PCI\VEN_1022&DEV_7812` | PCI-enumerated PnP hardware ID | `AMDXHC` | Projection | Projection | Projection | Projection |
| AMD USB 3.0 Host Controller | `PCI\VEN_1022&DEV_7814` | PCI-enumerated PnP hardware ID | `AMDXHC` | Projection | Projection | Projection | Projection |
| AMD USB 3.0 Host Controller | `PCI\VEN_1022&DEV_7914` | PCI-enumerated PnP hardware ID | `AMDXHC` | Projection | Projection | Projection | Projection |

### `d4_Data1.cab_9ed7c73e0e1f\amdxhc31.inf`

- Driver version: `1.0.5.3`; Class: `USB`; KMDF: `NotDeclared`; UMDF: `NotDeclared`

| Device | Device identifier | Identifier type | Install section | WS2016 | WS2019 | WS2022 | WS2025 |
|---|---|---|---|---|---|---|---|
| AMD USB3.1 eXtensible Host Controller | `PCI\VEN_1022&DEV_43B9` | PCI-enumerated PnP hardware ID | `AMD_Product1_Install` | Native | Native | Native | Native |
| AMD USB3.1 eXtensible Host Controller | `PCI\VEN_1022&DEV_43BA` | PCI-enumerated PnP hardware ID | `AMD_Product2_Install` | Native | Native | Native | Native |
| AMD USB3.1 eXtensible Host Controller | `PCI\VEN_1022&DEV_43BB` | PCI-enumerated PnP hardware ID | `AMD_Product3_Install` | Native | Native | Native | Native |
| AMD USB3.1 eXtensible Host Controller | `PCI\VEN_1022&DEV_43BC` | PCI-enumerated PnP hardware ID | `AMD_Product4_Install` | Native | Native | Native | Native |
| AMD USB3.1 eXtensible Host Controller | `PCI\VEN_1022&DEV_43D0` | PCI-enumerated PnP hardware ID | `AMD_Product5_Install` | Native | Native | Native | Native |
| AMD USB3.1 eXtensible Host Controller | `PCI\VEN_1022&DEV_43D1` | PCI-enumerated PnP hardware ID | `AMD_Product6_Install` | Native | Native | Native | Native |
| AMD USB3.1 eXtensible Host Controller | `PCI\VEN_1022&DEV_43D2` | PCI-enumerated PnP hardware ID | `AMD_Product7_Install` | Native | Native | Native | Native |
| AMD USB3.1 eXtensible Host Controller | `PCI\VEN_1022&DEV_43D3` | PCI-enumerated PnP hardware ID | `AMD_Product8_Install` | Native | Native | Native | Native |
| AMD USB3.1 eXtensible Host Controller | `PCI\VEN_1022&DEV_43D4` | PCI-enumerated PnP hardware ID | `AMD_Product9_Install` | Native | Native | Native | Native |
| AMD USB3.1 eXtensible Host Controller | `PCI\VEN_1022&DEV_43D5` | PCI-enumerated PnP hardware ID | `AMD_Product10_Install` | Native | Native | Native | Native |
| AMD USB3.1 eXtensible Host Controller | `PCI\VEN_1022&DEV_43D6` | PCI-enumerated PnP hardware ID | `AMD_Product11_Install` | Native | Native | Native | Native |
| AMD USB3.1 eXtensible Host Controller | `PCI\VEN_1022&DEV_43D7` | PCI-enumerated PnP hardware ID | `AMD_Product12_Install` | Native | Native | Native | Native |
| AMD USB3.1 eXtensible Host Controller | `PCI\VEN_1022&DEV_43D8` | PCI-enumerated PnP hardware ID | `AMD_Product13_Install` | Native | Native | Native | Native |
| AMD USB3.1 eXtensible Host Controller | `PCI\VEN_1022&DEV_43D9` | PCI-enumerated PnP hardware ID | `AMD_Product14_Install` | Native | Native | Native | Native |
| AMD USB3.1 eXtensible Host Controller | `PCI\VEN_1022&DEV_43DA` | PCI-enumerated PnP hardware ID | `AMD_Product15_Install` | Native | Native | Native | Native |
| AMD USB3.1 eXtensible Host Controller | `PCI\VEN_1022&DEV_43DB` | PCI-enumerated PnP hardware ID | `AMD_Product16_Install` | Native | Native | Native | Native |
| AMD USB3.1 eXtensible Host Controller | `PCI\VEN_1022&DEV_43DC` | PCI-enumerated PnP hardware ID | `AMD_Product17_Install` | Native | Native | Native | Native |
| AMD USB3.1 eXtensible Host Controller | `PCI\VEN_1022&DEV_43DD` | PCI-enumerated PnP hardware ID | `AMD_Product18_Install` | Native | Native | Native | Native |
| AMD USB3.1 eXtensible Host Controller | `PCI\VEN_1022&DEV_43DE` | PCI-enumerated PnP hardware ID | `AMD_Product19_Install` | Native | Native | Native | Native |
| AMD USB3.1 eXtensible Host Controller | `PCI\VEN_1022&DEV_43DF` | PCI-enumerated PnP hardware ID | `AMD_Product20_Install` | Native | Native | Native | Native |

### `d4_Data1.cab_9ed7c73e0e1f\amd_sata.inf`

- Driver version: `1.2.001.0402`; Class: `HDC`; KMDF: `NotDeclared`; UMDF: `NotDeclared`

| Device | Device identifier | Identifier type | Install section | WS2016 | WS2019 | WS2022 | WS2025 |
|---|---|---|---|---|---|---|---|
| AMD SATA Controller | `PCI\VEN_1002&DEV_4391&CC_0106` | PCI-enumerated PnP hardware ID | `amd_sata_inst` | Native | Native | Native | Native |
| AMD SATA Controller | `PCI\VEN_1002&DEV_4394&CC_0106` | PCI-enumerated PnP hardware ID | `amd_sata_inst` | Native | Native | Native | Native |
| AMD SATA Controller | `PCI\VEN_1022&DEV_7801&CC_0106` | PCI-enumerated PnP hardware ID | `amd_sata_inst` | Native | Native | Native | Native |
| AMD SATA Controller | `PCI\VEN_1022&DEV_7804&CC_0106` | PCI-enumerated PnP hardware ID | `amd_sata_inst` | Native | Native | Native | Native |
| AMD SATA Controller | `PCI\VEN_1022&DEV_7901&CC_0106` | PCI-enumerated PnP hardware ID | `amd_sata_inst` | Native | Native | Native | Native |
| AMD SATA Controller | `PCI\VEN_1022&DEV_7904&CC_0106` | PCI-enumerated PnP hardware ID | `amd_sata_inst` | Native | Native | Native | Native |

### `d4_Data1.cab_9ed7c73e0e1f\smbusamd.inf`

- Driver version: `5.12.0.38`; Class: `System`; KMDF: `NotDeclared`; UMDF: `NotDeclared`

| Device | Device identifier | Identifier type | Install section | WS2016 | WS2019 | WS2022 | WS2025 |
|---|---|---|---|---|---|---|---|
| AMD SMBus | `PCI\VEN_1002&DEV_4353` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native |
| AMD SMBus | `PCI\VEN_1002&DEV_4363` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native |
| AMD SMBus | `PCI\VEN_1002&DEV_4372` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native |
| AMD SMBus | `PCI\VEN_1002&DEV_4385` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native |
| AMD SMBus | `PCI\VEN_1022&DEV_780B` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native |
| AMD SMBus | `PCI\VEN_1022&DEV_790B` | PCI-enumerated PnP hardware ID | `AMDSMBus64` | Native | Native | Native | Native |

### `d4_Data1.cab_9ed7c73e0e1f\usbfilter.inf`

- Driver version: `2.0.10.287`; Class: `USB`; KMDF: `NotDeclared`; UMDF: `NotDeclared`

| Device | Device identifier | Identifier type | Install section | WS2016 | WS2019 | WS2022 | WS2025 |
|---|---|---|---|---|---|---|---|
| AMD USB Filter Driver | `{36FC9E60-C465-11CF-8056-444553540000}\usbfilter` | Device-class-specific ID | `usbfilter` | Native | Native | Native | Native |

