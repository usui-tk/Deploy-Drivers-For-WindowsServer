# AMD Graphics Driver Research Toolkit 0.5.0 — Semantic Sync Qualification

## Scope

This qualification forward-ports the shared INF semantic concepts from the Chipset research work onto the qualified Graphics 0.4.3 baseline. The Chipset toolkit and its artifacts are reference-only and are not modified by this work. Historical Graphics 0.4.3 evidence is also preserved unchanged.

## Forward-ported semantic contract

- `amd-inf-semantic-contract/1.0`
- `amd-inf-identifier-taxonomy/1.0`
- `amd-inf-topology/1.1` with legacy `inf-topology/1.0` validation schema retained
- all non-empty Models identifiers preserved; no fixed bus-prefix allow-list
- `Identifier` / `CompatibleIdentifiers` taxonomy objects while legacy identifier views remain
- canonical TargetOSVersion and Server-profile aliases
- `CanonicalStaticAssessment` alongside legacy display vocabulary
- explicit `WdfScope=InfWideConservative`
- `RuntimeCompatibilityProven=false`; runtime compatibility remains unproven

## Explicitly not ported

- Chipset-specific `DevID.xml`, `Info.xml`, APS XML, `/SETxxx`, MSI selector observation/emulation
- DDInstall-scoped WDF analysis
- any mutation of Chipset artifacts

## Regression result

| Artifact | INF | Static assessment changes | Newly retained topology identifiers |
|---|---:|---:|---:|
| `whql-amd-software-adrenalin-edition-23.11.1-win10-win11-nov3-rdna-combined.json` | 29 | 0 | 13 |
| `whql-amd-software-adrenalin-edition-23.11.1-win10-win11-nov3-rdna.json` | 21 | 0 | 13 |
| `amd-software-pro-edition-26.q1-win11-rdna.json` | 39 | 0 | 62 |
| `amd-software-pro-edition-26.q1-winsvr2022-vega-polaris.json` | 5 | 0 | 0 |

**Legacy Windows Server StaticAssessment changes: 0.**

Cumulative regenerated view: **4 artifacts / 94 INF topology records / 376 INF×Server rows / 21131 Device/HWID×Server rows**.

### Identifier preservation observed on real AMD packages

- `whql-amd-software-adrenalin-edition-23.11.1-win10-win11-nov3-rdna-combined.json`: 13 newly retained topology identifier occurrences (13 unique values). Examples: `ACP\DEVTYPE_0002&DEVREV_0000&VEN_1022&DEV_15E2`, `ACP\DEVTYPE_0002&DEVREV_0062&VEN_1022&DEV_15E2`, `ACP\DEVTYPE_0003&DEVREV_0000&VEN_1022&DEV_15E2`, `ACP\DEVTYPE_0004&DEVREV_0000&VEN_1022&DEV_15E2`, `ACP\DEVTYPE_0005&DEVREV_0000&VEN_1022&DEV_15E2`, `ACP\DEVTYPE_0006&DEVREV_0000&VEN_1022&DEV_15E2`
- `whql-amd-software-adrenalin-edition-23.11.1-win10-win11-nov3-rdna.json`: 13 newly retained topology identifier occurrences (13 unique values). Examples: `ACP\DEVTYPE_0002&DEVREV_0000&VEN_1022&DEV_15E2`, `ACP\DEVTYPE_0002&DEVREV_0062&VEN_1022&DEV_15E2`, `ACP\DEVTYPE_0003&DEVREV_0000&VEN_1022&DEV_15E2`, `ACP\DEVTYPE_0004&DEVREV_0000&VEN_1022&DEV_15E2`, `ACP\DEVTYPE_0005&DEVREV_0000&VEN_1022&DEV_15E2`, `ACP\DEVTYPE_0006&DEVREV_0000&VEN_1022&DEV_15E2`
- `amd-software-pro-edition-26.q1-win11-rdna.json`: 62 newly retained topology identifier occurrences (55 unique values). Examples: `ACP\DEVTYPE_0002&DEVREV_0000&VEN_1022&DEV_15E2&REV_60`, `ACP\DEVTYPE_0002&DEVREV_0000&VEN_1022&DEV_15E2&REV_63`, `ACP\DEVTYPE_0002&DEVREV_0000&VEN_1022&DEV_15E2&REV_6F`, `ACP\DEVTYPE_0002&DEVREV_0000&VEN_1022&DEV_15E2&REV_70`, `ACP\DEVTYPE_0002&DEVREV_0000&VEN_1022&DEV_15E2&REV_71`, `ACP\DEVTYPE_0002&DEVREV_0000&VEN_1022&DEV_15E2&REV_72`
- `amd-software-pro-edition-26.q1-winsvr2022-vega-polaris.json`: 0 newly retained topology identifier occurrences (0 unique values). Examples: (none)

These identifiers were already present in INF Models data; 0.4.x could omit them from the canonical flat topology view because of the fixed-prefix filter. 0.5.0 preserves them without fabricating PCI IDs.

### Native Server regression control

`u2197744.inf` from the AMD-published PRO 26.Q1 Windows Server 2022 Vega/Polaris package remains unchanged semantically:

| Server | Legacy status | Canonical status | As-published | WDF scope |
|---|---|---|---|---|
| windows-server-2016 | `NOT_APPLICABLE` | `NotApplicable` | `ExplicitlyExcluded` | `InfWideConservative` |
| windows-server-2019 | `NOT_APPLICABLE` | `NotApplicable` | `ExplicitlyExcluded` | `InfWideConservative` |
| windows-server-2022 | `NATIVE_CANDIDATE` | `NativeCandidate` | `NativeApplicable` | `InfWideConservative` |
| windows-server-2025 | `NATIVE_CANDIDATE` | `NativeCandidate` | `NativeApplicable` | `InfWideConservative` |
| windows-server-2016 | `NATIVE_CANDIDATE` | `NativeCandidate` | `NativeApplicable` | `InfWideConservative` |
| windows-server-2019 | `NATIVE_CANDIDATE` | `NativeCandidate` | `NativeApplicable` | `InfWideConservative` |
| windows-server-2022 | `NATIVE_CANDIDATE` | `NativeCandidate` | `NativeApplicable` | `InfWideConservative` |
| windows-server-2025 | `NATIVE_CANDIDATE` | `NativeCandidate` | `NativeApplicable` | `InfWideConservative` |

This preserves the 0.4.3 control: Server 2016/2019 are excluded while Server 2022/2025 are native INF-selection candidates. This does not establish runtime compatibility or AMD-published Server 2025 support.

## Qualification gates

- PowerShell AST parse errors: **0**
- Final semantic/identity synthetic tests: **PASS**
- All four canonical artifacts retained: **PASS**
- PRO sibling `ReleaseKey=ProEdition|MultiArtifact|26.Q1` preserved: **PASS**
- Legacy static assessment drift: **0 rows**
- Native Server control preserved: **PASS**
- Historical 0.4.3 evidence rewritten: **No**
- Chipset artifact modified: **No**
- WDF scope: **InfWideConservative**
- DDInstallScoped claimed: **No**
- Runtime compatibility proven: **No**

## Evidence note

The final script was validated with the synthetic Test stage and the native Server control artifact. Set 1–3 were regenerated during 0.5.0 development; subsequent changes were limited to Build/view performance and migration compatibility and did not change parser/selector semantics. The final regression JSON records the machine-checked old/new semantic comparison.

## Promotion decision

0.5.0 is suitable as the next **qualified development baseline** for Graphics semantic analysis. It is not yet GA/1.0.0; the remaining PRO Windows 11 Vega/Polaris artifact and Windows PowerShell 5.1 real-artifact gate remain open.
