# AMD Chipset Driver Research — 1.2.5-qt-dev Validation

Date: 2026-08-11 JST  
Scope: **AMD Chipset Software 7.11.26.2142 only as the new major**, with 8.07.16.1035 retained as the regression reference.

## Result

**PASS for the 7.x development/reverse-engineering gate.**  
This does not promote the historical `1.0.0` accepted baseline and does not constitute Windows PowerShell 5.1 GA qualification.

## Input identity

| Artifact | Size | SHA-256 | Result |
|---|---:|---|---|
| `AMD_Chipset_Software_7.11.26.2142.exe` | 78,301,768 | `1acd6dadcc3b4bca9451ff170d7a5a049309b827f74cf54b2a3684bf16a34856` | MATCH |
| `amd_software_8.07.16.1035.exe` | 81,490,200 | `1b55dd2dd661d19c5ea4d49bd53b673783e673db9e427b709d404bb1bae66bdb` | MATCH |
| prior 8.x qualification sample | 380,145 | `95756117c94bd24d765482a73160bcacceaf3061d08fed892469eecafeb975e7` | MATCH |

## Source/runtime checks

- PowerShell runtime used: 7.6.4 / Core / Linux x64.
- OS: Debian GNU/Linux 13.
- 7-Zip: user-provided Debian package, locally extracted for the analysis runtime.
- PowerShell AST parse: **0 errors**.
- `-Stages Test`: **PASS**.
- Compiled selector self-test: **PASS**, now covering two independently hash-scoped contracts (7.x and 8.x).

## 7.x pipeline

`Extract -> Inspect -> Selector -> Build`: **PASS**.

- extraction: 24 containers, 31 INF, one ISSetupStream chain, `ExtractionComplete`;
- INF parse failures: 0;
- KMDF declarations: 7;
- UMDF declarations: 1;
- DevID mappings: 38;
- Product records: 62;
- selector binary status: `CompiledSelectorContractMatched`;
- selector SHA-256: `7b3714b3ff5c6add70987e0aacb0c5b5a2d523ea13ddf39bf0ac02b5f79d2b1a`;
- MSI declarative status on Linux: `WindowsInstallerComUnavailableOnPlatform` (expected).

## 7.x compiled-selector proof

Independent static x86-64 disassembly proves the modeled scope:

- OS classifier at `0x140014c60`: internal family starts `-1`; Caption contains Windows 7/10/11 -> enum 0/1/2;
- Client `Info.xml` filter at `0x140015410`: enum 0/1/2 -> Win7/10/11 label; unknown enum -> no Client product appended;
- main hardware selector at `0x1400177b0`;
- `SETFILTERUSB`: `(DEV_790B OR DEV_780B) AND REV_16`, with silent erase on failure;
- `SETRYZENPPKG`: `DEV_790B` plus Family 23 / Model 160 special path or `REV_61`, `REV_59`, `REV_51` reaches the modeled candidate path.

The surrounding `AMDI0052` logic is retained as an explicit reverse-engineering boundary rather than broadened into an unsupported universal predicate.

## 8.x regression

1.2.5 re-ran 8.07.16.1035 through `Extract -> Inspect -> Selector -> Build`: **PASS**.

- 25 containers, 31 INF, 0 parse failures, 7 KMDF declarations, 1 UMDF declaration;
- 64 Product records, 41 DevID mappings;
- selector status `CompiledSelectorContractMatched`;
- the new-run 8.x `CompiledSelectorContract` object is **byte-for-byte semantically identical after JSON parsing** to the 1.2.4 qualification golden contract.

The retained three-host golden fixtures remain:

| Fixture | Final selector candidates | Compiled caption exclusions | Compiled-rule filters | Unknown AMD filters |
|---|---:|---:|---:|---:|
| Windows 11 build 26200 | 6 | 0 | 1 | 0 |
| Server 2022 build 20348 | 0 | 8 | 1 | 0 |
| Server 2025 build 26100 | 0 | 6 | 1 | 0 |

No 8.x dynamic evidence is attributed to 7.x.

## Schema and portability validation

- 7.x selector-static JSON: **0 schema errors**.
- 8.x selector-static JSON: **0 schema errors**.
- 7.x per-release analysis JSON: **0 schema errors**.
- 8.x per-release analysis JSON: **0 schema errors**.
- all retained Win11 / Server 2022 / Server 2025 host-inventory, selector-observation, MSI-observation and host-analysis fixture JSON: **0 schema errors**.
- canonical 7.x per-release JSON `/mnt/data` leakage: **0**.
- canonical 8.x per-release JSON `/mnt/data` leakage: **0**.

## Major-difference result

The exact 7.x and 8.x selector binaries are different but are the same observed Qt selector family for the modeled predicates. 8.x adds three DevID tags (`/SETSFH1.2`, `/SETUPMF`, `/SETXGBE`), extends `/SETUPEP` and `/SETINTERFACE`, adds two manifest Product identities, and imports `RstrtMgr.DLL` and `VERSION.dll` in addition to the 7.x import set.

See `amd-chipset-selector-major-version-comparison.md` and `qualification/major-comparison.json` for the full comparison.

## Remaining gates

- Windows PowerShell 5.1 live qualification remains pending before any GA/accepted-baseline promotion.
- No 7.x live-host `Device_ID.log` / MSI fixture has been supplied; 7.x dynamic qualification is therefore intentionally not claimed.
- `SETINTERFACE` PHX/latest and specialized PMF/SFH branches remain outside the normalized compiled contract unless separately proven.
- WDF scope remains `InfWideConservative`.
- **6.x is not analyzed in this validation.**
