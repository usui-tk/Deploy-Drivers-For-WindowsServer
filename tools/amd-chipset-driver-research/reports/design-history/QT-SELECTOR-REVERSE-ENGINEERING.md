# AMD Chipset Qt Selector Reverse Engineering — 1.2.7-qt-dev

Date: 2026-08-11 JST  
Project: AMD-Driverプロジェクト  
Repository target: `tools/amd-chipset-driver-research/`  
Analyzed AMD release: **AMD Chipset Software 8.07.16.1035**

## 1. Purpose

This report records code-level reverse engineering of the AMD chipset installer front-end selector used by release 8.07.16.1035. The goal is to explain the vendor-side decision plane that exists in addition to Microsoft INF/PnP applicability.

The research is intentionally separated into evidence levels. Statements marked `AmdCompiledStaticProven` are scoped to one exact `Qt_Dependencies/Setup.exe` SHA-256. Dynamic observations from Windows 11, Windows Server 2022, and Windows Server 2025 are used as qualification fixtures, but dynamic behavior is not silently generalized to other AMD releases.

The research tool did **not execute AMD Setup.exe** while recovering the compiled predicates described here.

## 2. Artifact identity and extraction chain

The analyzed outer installer is:

```text
amd_software_8.07.16.1035.exe
SHA-256: 1b55dd2dd661d19c5ea4d49bd53b673783e673db9e427b709d404bb1bae66bdb
```

Static extraction reconstructs this chain:

```text
amd_software_8.07.16.1035.exe
│
├─ Qt_Dependencies/
│  ├─ Setup.exe
│  └─ DevID.xml
├─ QT_Dependencies/
│  └─ Info.xml
└─ AMD_Chipset_Drivers.exe
   └─ InstallShield ISSetupStream type 4
      └─ AMD_Chipset_Drivers.msi
         └─ Data1.cab
            └─ APS_7162026103425_2391.xml
```

Important identities:

| Object | SHA-256 |
|---|---|
| Qt `Setup.exe` | `9b8411b3f77312a770bdac35756081e77c74fb22b7c4c4f367db4f6e5ddf5462` |
| outer `Info.xml` | `8a9c31f6ef9874280baeb44e2488b4dc61cdeaa3d565775bd038ac6da2f4a65e` |
| `DevID.xml` | `8cdff0622888ef1efbebd629adab1497245c68dcf5044bd1c13ba3aad013886a` |
| `AMD_Chipset_Drivers.exe` | `9c9a58baf609ad3229286eca2c647c8765924acf3427d0d3442b7ef26373ae46` |
| `AMD_Chipset_Drivers.msi` | `80f51177b497fcabe2ba23e00ecbc110170a5e6483e9595ed4244f230593375b` |
| `Data1.cab` | `f8f372fbfc6db3a987654a6b388d79b46d509f4ef05ac277c71c6716e5091e1` |
| `APS_7162026103425_2391.xml` | `8a9c31f6ef9874280baeb44e2488b4dc61cdeaa3d565775bd038ac6da2f4a65e` |

The APS XML is byte-for-byte identical to the outer `Info.xml`. Therefore the product/component manifest visible to the Qt selector is also carried into the later MSI payload.

The recovered manifest has **64 Product records**. The observed OS labels are only:

```text
Windows 10(64-bit)
Windows 11(64-bit)
```

and the observed `Brand` value is only:

```text
Client
```

No Server-labelled product record exists in this manifest.

## 3. Compiled OS classification — Server exclusion no longer requires a ProductType hypothesis

### 3.1 Function and WMI data

The exact Qt selector contains the OS detection function at:

```text
0x140017130
```

Static disassembly shows it querying:

```text
WMI namespace : root\cimv2
Query         : Select * from Win32_OperatingSystem
Fields        : BuildNumber, Caption, Version
```

The selector's OS-family field at object offset `+0x224` is initialized to `-1` before this routine runs.

The code then performs case-insensitive substring classification against **Caption**:

```text
Caption contains "Windows 7"  -> enum 0
Caption contains "Windows 10" -> enum 1
Caption contains "Windows 11" -> enum 2
otherwise                      -> remains -1
```

This is `AmdCompiledStaticProven` for the exact selector SHA above.

### 3.2 Consequence for Windows Server

These real captions do not contain any of the three client substrings:

```text
Microsoft Windows Server 2022 Datacenter
Microsoft Windows Server 2025 Datacenter
```

Therefore they remain:

```text
OS-family enum = -1
```

This is materially stronger than the earlier working hypothesis that the selector might directly use `ProductType=3` as the primary Server block.

The identified classification path reads `BuildNumber`, `Caption`, and `Version`; it does not query WMI `ProductType`. Static string review also found no `ProductType` string in this exact binary. This does **not** prove that no other code path can ever inspect SKU, but the observed Server empty-list behavior no longer needs a ProductType hypothesis to explain it.

## 4. Compiled `Info.xml` product filtering

The relevant `Info.xml` processing function begins at:

```text
0x1400178e0
```

It parses `/info.xml` and consumes fields including:

```text
Version
OS
Installer
Brand
```

It also checks the machine architecture against:

```text
x86_64
```

and distinguishes `Embedded` products from the normal Client path.

For the non-Embedded/Client x64 path, the recovered mapping is:

```text
enum 0 -> Windows 7(64-bit)
enum 1 -> Windows 10(64-bit)
enum 2 -> Windows 11(64-bit)
other  -> no Client product appended
```

The relevant startup ordering also links the routines directly:

```text
OS WMI/classification function
          ↓
currentCpuArchitecture
          ↓
Info.xml filtering function
```

For the 8.07.16.1035 Client-only manifest, Server captions classify to `-1`; the Client filter has no branch for `-1`; therefore no Client Product entry is appended to the host-specific XML/product list.

This provides a compiled explanation for the otherwise puzzling dynamic log sequence:

```text
physical AMD hardware detected
→ SETxxx candidate created
→ "not present in xml list"
→ candidate removed
→ final SupportedDrivers empty
```

## 5. `SETFILTERUSB` silent removal — compiled predicate recovered

A second previously unresolved behavior was that `/SETFILTERUSB` could be created but disappear without a generic `Hence removing` log line.

The exact selector contains the relevant branch in the larger function beginning around:

```text
0x14001a090
```

Key locations:

```text
candidate lookup     : 0x14001b450
primary device token : DEV_790B
fallback device token: DEV_780B
required revision    : REV_16
removal path         : 0x14001b5c4
vector erase helper  : 0x140018e80
```

Recovered rule:

```text
same device context must match:
    (DEV_790B OR DEV_780B)
AND REV_16

otherwise:
    erase /SETFILTERUSB from candidate vector
```

The removal path calls the vector erase helper directly and does **not** build the generic `not present in xml list. Hence removing.` message. This explains the silent disappearance.

Dynamic qualification corroborates the rule:

| Host | Relevant device | Observed result |
|---|---|---|
| Windows 11 build 26200 | `DEV_790B`, `REV_61` | candidate appears, no explicit removal line, absent final |
| Server 2022 build 20348 | `DEV_790B`, `REV_51` | candidate appears, no explicit removal line, absent final |
| Server 2025 build 26100 | `DEV_790B`, `REV_51` | candidate appears, no explicit removal line, absent final |

The toolkit now reports these as:

```text
ObservedFilterExplainedByCompiledRule
```

rather than `UnknownAmdFilterSuspected`.

The implementation also requires device and revision tokens to occur in the **same host-device context**, avoiding a false match from an unrelated device carrying the same revision token.

## 6. `SETRYZENPPKG` candidate creation — compiled predicate recovered

Further analysis of the same selector function also resolved the previously empirical RyzenPPKG rule.

Key locations:

```text
DEV_790B lookup          : 0x14001aa33
CPU special comparisons : 0x14001aa7b onward
revision gate            : 0x14001ac09 onward
candidate creation       : 0x14001af0d
candidate                : /SETRYZENPPKG
```

Inside a `DEV_790B` device path, the selector contains:

```text
special accepted CPU path:
    Family 23
    Model 160

otherwise accepted revisions:
    REV_61
    REV_59
    REV_51
```

Therefore the exact-binary candidate rule can be represented as:

```text
DEV_790B
AND
(
    CPU Family 23 / Model 160 special path
    OR REV_61
    OR REV_59
    OR REV_51
)
→ create /SETRYZENPPKG candidate
```

Candidate creation and final selection remain different stages. The Server fixtures satisfy the device/revision gate (`DEV_790B + REV_51`) and therefore correctly create `SETRYZENPPKG`; they subsequently lose it because the Client `Info.xml` list is empty for OS enum `-1`.

Dynamic qualification:

| Host | Device/revision | Candidate | Final |
|---|---|---:|---:|
| Windows 11 | `DEV_790B + REV_61` | yes | selected |
| Server 2022 | `DEV_790B + REV_51` | yes | XML-list removed |
| Server 2025 | `DEV_790B + REV_51` | yes | XML-list removed |

The toolkit now labels this candidate rule `AmdCompiledStaticProven` for the exact selector SHA rather than `AmdDynamicObservedSingleHost`.

## 7. Three-host qualification results

### 7.1 Windows 11 positive fixture

```text
Caption      : Microsoft Windows 11 Pro
Build        : 26200
ProductType  : 1 (observed MSI)
Qt OS enum   : 2
Final AMD list:
  GPIO3,PCI,PSP,SMBUS,GPIO2,RYZENPPKG
MSI ADDLOCAL : same six components
```

HostMatch result:

```text
SelectorCandidateCount       = 6
CompiledCaptionExclusionCount= 0
FilteredByCompiledRuleCount  = 1   # SETFILTERUSB
UnknownAmdFilterCount        = 0
```

All six observed final selections are `EmulationConfirmed`.

### 7.2 Windows Server 2022 negative fixture

```text
Caption      : Microsoft Windows Server 2022 Datacenter
Build        : 20348
ProductType  : 3 (observed MSI)
Qt OS enum   : -1
Final AMD list: []
MSI mode     : AdministrativeExtraction
```

This host creates candidates including UPEP, I2C, Interface, PSP, SMBus, USB Filter, GPIO2, and RyzenPPKG. The Client manifest filter then excludes the relevant product entries. The final `Writing supported drivers to registry:` line is explicitly present and empty.

HostMatch result:

```text
SelectorCandidateCount       = 0 final selected
CompiledCaptionExclusionCount= 8
FilteredByCompiledRuleCount  = 1
UnknownAmdFilterCount        = 0
```

### 7.3 Windows Server 2025 negative fixture

```text
Caption      : Microsoft Windows Server 2025 Datacenter
Build        : 26100
ProductType  : 3 (observed MSI)
Qt OS enum   : -1
Final AMD list: []
MSI mode     : AdministrativeExtraction
```

This host has a different initial candidate set from Server 2022, including SATA, but reaches the same Client-manifest exclusion outcome.

HostMatch result:

```text
SelectorCandidateCount       = 0 final selected
CompiledCaptionExclusionCount= 6
FilteredByCompiledRuleCount  = 1
UnknownAmdFilterCount        = 0
```

The two Server fixtures therefore remain valuable because qualification checks their different decision traces rather than accepting a trivial `if Server then []` shortcut.

## 8. Microsoft INF/PnP plane remains independent

The Qt result is a vendor installer selection result, not a replacement for INF semantics.

The research tool continues to maintain two planes:

```text
Microsoft / INF / PnP plane
    actual Hardware/Compatible IDs
    Manufacturer / Models
    TargetOSVersion
    ProductType / BuildNumber / SuiteMask
    WDF static check

AMD selector plane
    actual device tokens
    DevID.xml
    compiled Qt selector predicates
    Info.xml filtered product list
    observed AMD logs
```

A device can be a Microsoft/PnP candidate while AMD's installer suppresses the corresponding component. That divergence is a primary research output rather than an error to normalize away.

## 9. Toolkit changes in 1.2.4-qt-dev

`Invoke-AmdChipsetDriverResearch.ps1` now includes:

- SHA-256-scoped `amd-chipset-compiled-selector-contract/1.0`;
- evidence level `AmdCompiledStaticProven`;
- printable UTF-16 selector string collection;
- exact Caption -> enum classification for the vetted binary;
- exact Client `Info.xml` enum -> OS-label filtering;
- same-device-context `SETFILTERUSB` revision gating;
- compiled `SETRYZENPPKG` candidate gating;
- `REV_..` host token extraction;
- compiled-contract self-tests;
- host analysis counters for compiled Caption exclusion and compiled device/revision filtering;
- schema revisions:
  - selector static `1.2`;
  - host analysis `1.3`;
  - per-release analysis `2.5`.

Canonical per-release JSON remains portable: the generated 8.07.16.1035 Raw JSON contains zero `/mnt/data` references.

## 10. What is still not proven

The following remain outside the current compiled contract or require more work:

1. **Other AMD releases:** no Qt predicate is generalized across versions without matching or separately reverse-engineering their selector binaries.
2. **Full `SETINTERFACE` PHX/latest predicate:** the supplied host's CPU removal is dynamically observed, but the complete CPU-generation decision tree has not yet been normalized into the compiled contract.
3. **All PMF/SFH/platform-special branches:** many specialized rules are visible in the selector binary but have not yet been fully modeled.
4. **Installed-state/upgrade behavior:** `DeployedFeatures`, prior product version, maintenance mode, and cleanup logic are separate axes from initial host component eligibility.
5. **Runtime compatibility:** successful selector emulation or INF matching does not establish successful installation, reboot stability, or vendor support.
6. **DDInstall-scoped WDF:** WDF analysis remains `InfWideConservative` under the shared INF contract.
7. **Windows live qualification:** Windows PowerShell 5.1 and PowerShell 7 runs now exist. 1.2.8 fixes issues exposed by them; the remaining Windows-specific gate is a rerun confirming Windows Installer COM table parsing after the `_Tables` projection repair.

## 11. Conclusion

The central Server-selection ambiguity for AMD Chipset Software 8.07.16.1035 is now substantially resolved.

The exact Qt selector does not need a direct `ProductType=3` block to explain the observations. It classifies `Win32_OperatingSystem.Caption` only into Windows 7/10/11 client enums; Server captions remain `-1`; the Client `Info.xml` filter has no branch for `-1`; and therefore Server 2022/2025 receive no Client product entries even though AMD hardware detection successfully created `SETxxx` candidates beforehand.

The same binary also explains the previously silent USB Filter removal and provides a code-level RyzenPPKG candidate-creation gate. Together with three real-host observation fixtures, this changes the 8.07.16.1035 selector model from primarily empirical emulation into a SHA-256-scoped compiled contract with dynamic corroboration.

The historical 1.0.0 accepted baseline is **not** replaced by this development work.

## 12. 7.11.26.2142 independent major reverse engineering (1.2.5-qt-dev)

The next older major was analyzed independently, per the reverse-chronological one-major-at-a-time policy. The canonical 7.x outer artifact is:

```text
AMD_Chipset_Software_7.11.26.2142.exe
Size: 78,301,768 bytes
SHA-256: 1acd6dadcc3b4bca9451ff170d7a5a049309b827f74cf54b2a3684bf16a34856
```

The recovered selector owner is again `Qt_Dependencies/Setup.exe`, but it is a different exact binary:

```text
Size: 1,391,880 bytes
SHA-256: 7b3714b3ff5c6add70987e0aacb0c5b5a2d523ea13ddf39bf0ac02b5f79d2b1a
ImageBase: 0x140000000
FileVersion/ProductVersion: 7.0.0.0
```

The 7.x topology contains `Info.xml`, `DevID.xml`, `AMD_Chipset_Drivers.exe`, `AMD_Chipset_Drivers.msi`, `Data1.cab`, and `APS_11262025214138_657.xml`. `Info.xml` and the APS XML have the same SHA-256 `45028b87c8bb4cb960d5782449fbc7b5f1554ed17d1b2d6e112744f8f0709e63`. `DevID.xml` SHA-256 is `1cbbee61c1900e94ee18349b215531648d255a9aa69d024d62d41632f75346b5`.

Independent 7.x disassembly proves:

- OS classifier function `0x140014c60`: object field `+0x224` initialized to `-1`; Caption substrings Windows 7/10/11 map to 0/1/2.
- Client `Info.xml` filter function `0x140015410`: enum 0/1/2 maps to Windows 7/10/11 labels; other values append no Client product.
- main hardware-selector function `0x1400177b0`.
- `SETFILTERUSB`: candidate lookup `0x140018b80`, `(DEV_790B OR DEV_780B) AND REV_16`, erase call at `0x140018d5b`, helper `0x1400165a0`.
- `SETRYZENPPKG`: DEV_790B lookup `0x140018143`, Family23/Model160 compare from `0x14001818b`, REV_61/59/51 gate from `0x140018324`, post-revision candidate path `0x140018625`.

The 7.x exact binary therefore receives its **own** hash-scoped compiled contract. The structural similarity to 8.x is a comparison result, not the basis for the 7.x evidence level.

7.x has 62 Product records and 38 DevID mappings; 8.x has 64 and 41. Both are Client-only Windows 10/11 x64 manifests. See `reports/amd-chipset-selector-major-version-comparison.md` for the complete 8.x-vs-7.x diff.

No 7.x live-host Device_ID/MSI fixture was supplied. Accordingly, 7.x is `AmdCompiledStaticProven` for the modeled predicates, while the three-host dynamic corroboration remains scoped to 8.07.16.1035.

**6.x and earlier remain unanalysed in this development step.**


## 13. 6.10.17.152 independent major reverse engineering (1.2.6-qt-dev)

### 13.1 Artifact and selector identity

Canonical outer artifact: `AMD_Chipset_Software_6.10.17.152.exe`, 66,897,080 bytes, SHA-256 `e5bb2e43218248103a0aa8841b906ae96c7391598de416e51373b255819554bf`. Static extraction recovers `Qt_Dependencies/Setup.exe`, proving that this representative 6.x release is Qt-based.

The exact selector is 1,631,440 bytes, SHA-256 `83d82a4775c0793ace86b1b07f98eadfc262f22d4c275fab2d74b9d86f19379a`, **PE32 x86**, ImageBase `0x00400000`, FileVersion/ProductVersion `6.0.0.0`, and imports Qt5. 7.x changes to x64 and Qt6, so binary continuity is not assumed.

### 13.2 XML topology

Outer `QT_Dependencies/Info.xml` has SHA-256 `dc9d761a4fbe7c938cfa57690e8dcda50e1f4449bbf4d64dbb92c8186526c9d4` and 53 Product records: 27 Windows 10 x64, 26 Windows 11 x64, all `Brand=Client`. Inner `aps_10172024015242_657.xml` is byte-identical. **No `DevID.xml` is recovered anywhere in the 6.x payload**, so the declarative mapping count is zero.

### 13.3 Compiled OS classifier and Client filter

The x86 classifier begins at `0x0040d8d0`. The OS-family field at object offset `0xac` is initialized to `3`. Recovered WMI evidence is `root\cimv2`, `Select * from Win32_OperatingSystem`, `BuildNumber`, `Caption`, and `Version`. Caption matches set Windows 7=`0`, Windows 10=`1`, Windows 11=`2`; an unmatched caption retains `3`. No `ProductType` literal is present in the exact selector.

The Info.xml parser/filter begins at `0x0040dd20`. Enum 0/1/2 maps to Windows 7/10/11 x64 labels respectively; enum 3 has no recovered Client product-append branch. Because the actual manifest is Win10/11 Client-only, an unmatched Windows Server caption contributes no matching Client product through this compiled path.

### 13.4 Hardware predicate boundary

`/SETFILTERUSB` and `/SETRYZENPPKG` literals exist, but the selector contains none of the 7.x/8.x `DEV_790B`, `DEV_780B`, `REV_16`, `REV_61`, `REV_59`, or `REV_51` tokens. Instead an older hardware-inspection region references `AMD SMBUS`, `790B`, `14EC`, and `14AC`; `/SETRYZENPPKG` is referenced from multiple x86 paths.

This proves that the later tokenized hardware contract cannot safely be projected backward, but it does not prove an exact equivalent 6.x `SETFILTERUSB` or `SETRYZENPPKG` rule. Both are therefore retained as `Unresolved`; only `HostOsDetection` and `InfoXmlFilter` are promoted to exact-binary `AmdCompiledStaticProven` scope.

### 13.5 6.x→7.x boundary

The representative transition is substantial: selector x86→x64, Qt5→Qt6, `DevID.xml` absent→38 mappings, Product records 53→62, plus six SET literals introduced in 7.x: `/SETAPPCOMPATDB`, `/SETFPMF400AI`, `/SETHSMP`, `/SETMSFT1`, `/SETMSFT2`, `/SETPMFAI300`.


## 14. 5.08.02.027 independent major reverse engineering (1.2.7-qt-dev)

Canonical outer artifact SHA-256 is `4bd9580842b8beb17cea3fdafa87b047117447656bbbeeb9a31a3f090d43cbeb`. The recovered selector `Qt_Dependencies/Setup.exe` is 1,623,448 bytes, PE32 x86, ImageBase `0x00400000`, Qt5, FileVersion/ProductVersion `3.0.0.0`, SHA-256 `8f4e0f27397786275db0a45282b05bf39da1f16ee9379712a75544fdb49460cf`.

Static disassembly identifies OS classifier `0x0040cfa0` and Client `Info.xml` filter `0x0040d3f0`. The OS-family field starts at `3`, maps Windows 7/10/11 captions to `0/1/2`, and leaves other captions at `3`. The recovered manifest has 47 Client products for Windows 10/11 x64, no `DevID.xml`, and one APS XML byte-identical to the preferred `Info.xml` (SHA-256 `6051a7aa6d2021e30a667041f5e8f1abe9049e97d64376595bacb6b93d9d736f`). Hardware predicates remain unresolved.

## 15. 4.08.09.2337 independent major reverse engineering (1.2.7-qt-dev)

Canonical outer SHA-256 is `833fa334cf50d91db0eece9d44636b7c598ae2f8178a8f21ddcc9a6f1cb964b0`. Selector size is 1,609,216 bytes, PE32 x86, Qt5, FileVersion/ProductVersion `3.0.0.0`, SHA-256 `95d0428ea90bee14704bf556a3ad6c91971e63d6d63c0807e9e7a8791d024160`. The classifier and Client-filter entry points remain `0x0040cfa0` and `0x0040d3f0`; the logical OS contract is the same as 5.x/6.x but remains independently hash-scoped. The manifest has 39 Client Win10/11 products, no `DevID.xml`, and byte-identical Info/APS XML SHA-256 `1b0630b099a15b2f9bcb7ca3e7bb8dd5c2ac13cb6ffa0bf76f6afa713bfc85ac`. Hardware predicates remain unresolved.

## 16. 3.10.08.506 independent major reverse engineering (1.2.7-qt-dev)

Canonical outer SHA-256 is `851c0364acd6ec91c54f260729f875de727541b2acb0f5e8930ab51227ce2f53`. Selector size is 1,605,120 bytes, PE32 x86, Qt5, FileVersion/ProductVersion `3.0.0.0`, SHA-256 `4a0cf13c66f873319ff44eba1867f9cc7dc865d0f422c007bcb25c6ced148ee9`. Static disassembly moves the corresponding entry points to OS classifier `0x0040d2b0` and Client filter `0x0040d720`, while preserving initial/unmatched enum `3` and Windows 7/10/11 -> `0/1/2`. The manifest has 27 Client Win10/11 products, no `DevID.xml`, and byte-identical Info/APS XML SHA-256 `ab1f1262e16764f5168c33bdf4f08da4d4562a8cc3000656a2228599d5372349`. Hardware predicates remain unresolved.

## 17. 3.x through 8.x generation boundary

The representative 3.x/4.x/5.x/6.x binaries form one broad selector generation: x86, Qt5, Client-only `Info.xml`, no recovered `DevID.xml`, unmatched OS enum `3`, and exact-binary partial contracts for OS/XML behavior. 7.x is the observed major boundary to x64 + Qt6 + `DevID.xml` and unmatched enum `-1`; 8.x extends the same newer generation. This is a topology statement, not permission to generalize hardware predicates across hashes.

The 1.2.7 checkpoint did not have a local 2.04.04.111 artifact for direct reverse engineering. Subsequent 1.2.8 Windows-live evidence recovered the canonical archive and static topology; see section 18. Compiled 2.x predicates remain unproven.


## 18. Windows-live hardening and 2.x static topology (1.2.8-qt-dev)

Three Windows evidence runs validated the broad static pipeline but exposed three implementation issues: localized Japanese `64 ビット` was not recognized by the selector architecture test; data-dependent stages could continue after Extract failed due to missing 7-Zip; and MSI `_Tables` enumeration assumed a `.Name` property not present in the returned COM row shape. 1.2.8 adds normalized architecture evidence, prerequisite-aware `BLOCKED` semantics, current-run producer checks, and defensive MSI table-name projection.

The corrected HostMatch replay restores the captured Windows 11 / 8.07.16.1035 positive feature set (`SMBUS`, `PCI`, `PSP`, `GPIO2`, `GPIO3`, `RYZENPPKG`). Server 2022 and Server 2025 replays remain negative through the expected compiled Caption-classification path rather than architecture mismatch.

The same Windows runs also demonstrated live acquisition of canonical 2.04.04.111. The expected ZIP (`d23a9cc4be06ab46c88918e523d11a96ca56b132f3b4646d2e8f9e17abf97185`, 52,428,763 bytes) was downloaded in all three runs, and the two hosts with 7-Zip recovered 24 INF files. Static selector evidence identifies the historical misspelled path `Qt_Dependancies/Setup.exe`, SHA-256 `24cd52cc5a1eff6e082b2408681e4e90d759ef3ddcc8fedd9077fb632cd8bd76`, with `/info.xml`, `/SETFILTERUSB`, `/SETRYZENPPKG`, `AMD SMBus Driver`, and `readXmlFile` strings. `Info.xml` contains 26 products for Windows 7/10, one APS XML is byte-identical, and no `DevID.xml` is recovered.

This changes 2.x from “artifact unavailable” to “canonical acquisition and static topology observed”, but **not** to `AmdCompiledStaticProven`: the shared evidence intentionally excludes the raw AMD selector binary, so code-level predicates remain unresolved.
