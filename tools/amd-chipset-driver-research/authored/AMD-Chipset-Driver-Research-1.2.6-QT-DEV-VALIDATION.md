# AMD Chipset Driver Research — 1.2.6-qt-dev Validation

Validated: 2026-08-11 04:34 JST  
Scope: **6.10.17.152 new major analysis, with frozen 7.11.26.2142 and 8.07.16.1035 regression**.

## Result

The 6.x representative is suitable for a development checkpoint/freeze for the **proven scope**. Its OS classifier and Client manifest filter are proven from the exact selector binary. The hardware predicates for `/SETFILTERUSB` and `/SETRYZENPPKG` remain deliberately `Unresolved`; no 7.x/8.x predicate was projected backward.

The accepted historical baseline remains `1.0.0`. This validation does not promote `1.2.6-qt-dev` to GA.

## 6.x artifact identity

`AMD_Chipset_Software_6.10.17.152.exe`

- size: 66,897,080 bytes
- SHA-256: `e5bb2e43218248103a0aa8841b906ae96c7391598de416e51373b255819554bf`

Selector `Qt_Dependencies/Setup.exe`:

- size: 1,631,440 bytes
- SHA-256: `83d82a4775c0793ace86b1b07f98eadfc262f22d4c275fab2d74b9d86f19379a`
- PE architecture: x86
- ImageBase: `0x00400000`
- FileVersion/ProductVersion: `6.0.0.0`
- Qt generation: Qt5

## 6.x pipeline

Final one-release qualification:

- Test: PASS
- Extract: PASS
- Inspect: PASS
- Selector: PASS
- Build: PASS
- final assessment: PASS / exit 0
- INF files: 28
- INF parse failures: 0
- KMDF declarations: 7
- UMDF declarations: 1
- recovered containers: 23

Linux correctly reports `WindowsInstallerComUnavailableOnPlatform` for read-only MSI table inspection.

## Selector findings

Compiled OS classifier:

- function `0x0040d8d0`
- field offset `+0xac`
- initial/unmatched value `3`
- Windows 7 -> 0
- Windows 10 -> 1
- Windows 11 -> 2
- WMI: `root\cimv2`, `Select * from Win32_OperatingSystem`
- recovered fields: BuildNumber, Caption, Version

Client manifest filtering:

- function `0x0040dd20`
- enum 0/1/2 maps to Windows 7/10/11 x64 Client labels
- enum 3 has no recovered Client append branch
- actual manifest contains 53 Product records, Client only, Windows 10/11 x64 only
- Server-labelled records: 0

Hardware predicate boundary:

- exact 7.x/8.x `DEV_790B` / `DEV_780B` / `REV_16` and `REV_61/59/51` token vocabulary is absent
- older literals such as `AMD SMBUS`, `790B`, `14EC`, `14AC` are present
- `/SETFILTERUSB` exact 6.x survival/removal predicate: `Unresolved`
- `/SETRYZENPPKG` exact 6.x candidate predicate: `Unresolved`

## 6.x topology change from 7.x

The 6.x selector family is Qt-based but materially older:

- selector architecture: x86 -> x64 in 7.x
- Qt5 -> Qt6 in 7.x
- selector FileVersion 6.0.0.0 -> 7.0.0.0
- `DevID.xml`: absent in 6.x -> 38 mappings in 7.x
- Product records: 53 -> 62
- unmatched OS enum: 3 -> -1

6.x `Info.xml` and `aps_10172024015242_657.xml` are byte-identical, SHA-256 `dc9d761a4fbe7c938cfa57690e8dcda50e1f4449bbf4d64dbb92c8186526c9d4`.

## Regression / release-precheck

- PowerShell 7.6.4 AST: 0 errors
- compiled selector self-test: PASS for exact 6.x / 7.x / 8.x contracts
- 7.x pipeline regression: PASS
- 8.x pipeline regression: PASS
- 7.x compiled contract vs 1.2.5 golden: object-identical
- 8.x compiled contract vs 1.2.5 golden: object-identical
- 8.x Win11 / Server 2022 / Server 2025 fixture schema validation: 0 errors
- release/static/embedded/driver-package JSON schema validation: 0 errors
- canonical per-release `/mnt/data` leakage: 0

The release precheck found an existing `driver-packages.json` schema-version drift: generated output used `SchemaVersion=1.0` while `driver-package.schema.json` requires `2.0`. The 1.2.6 source now emits `2.0`; 6.x/7.x/8.x were regenerated/rechecked and all pass.

## Research boundary

No 6.x live-host fixture is supplied, so dynamic host behavior is not claimed. 8.x remains the multi-host dynamic reference. No 5.x-or-earlier artifact was analyzed for this checkpoint.
