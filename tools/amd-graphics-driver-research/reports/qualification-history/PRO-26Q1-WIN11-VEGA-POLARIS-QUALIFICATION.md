# AMD Graphics Driver Research Toolkit 0.5.0 — PRO Edition 26.Q1 Windows 11 Vega/Polaris Qualification

Date: 2026-08-11

## Result

The supplied `amd-software-pro-edition-26.q1-win11-vega-polaris.exe` was statically analyzed with the unchanged 0.5.0 semantic-sync qualified toolkit. The AMD installer executable was never launched.

- Test: PASS / exit 0
- Acquire: PASS / exit 0
- Extract: PASS / exit 0
- Inspect: PASS / exit 0
- Build: PASS / exit 0
- INF records: 14
- INF parse failures: 0
- Manifest payload resolution: 10/10
- Package identity: `ProEdition|MultiArtifact|26.Q1`, `ArtifactRole=PolarisVega`

## Canonical artifact

- File: `amd-software-pro-edition-26.q1-win11-vega-polaris.exe`
- Size: 676,208,616 bytes
- SHA-256: `282c2cfa41e6257f6489c1891844217f86ebb614cf7ce9e133203ee6f994d11d`
- 7z SFX offset: 1,785,344

## Embedded manifest

- BuildVersion: `23.19.24-251211a-197745C-AMD-Software-PRO-Edition`
- Packages: 10 (6 DRIVER / 3 MSI / 1 SPECIAL)
- Display package: `U0197745.INF` / `31.0.21924.61`
- Display description: `Display driver for Windows 10`
- Raw OSCheck: `['*-*-10.0-Yes-*-*']`

## Primary Display INF

- INF: `u0197745.inf`
- Driver version: `31.0.21924.61`
- INF SHA-256: `c0ef638b92af82492f647d183d0ef7a5fea84ba1b2c30c03d9efa2ca3ce96762`
- Flat HWID count: 380
- Topology HWID count: 343
- Populated client target: `NTamd64.10.0.1..16299` with 343 models/HWIDs
- Less-specific client sections are empty.

Static Server result for the primary Display INF:

| Server | As Published | Server Projection | Assessment |
|---|---|---|---|
| 2016 | NotApplicableByBuild | ExplicitlyExcluded | NOT_APPLICABLE |
| 2019 | NotApplicableByProductType | ProjectionCandidate | PATCH_CANDIDATE |
| 2022 | NotApplicableByProductType | ProjectionCandidate | PATCH_CANDIDATE |
| 2025 | NotApplicableByProductType | ProjectionCandidate | PATCH_CANDIDATE |

`PATCH_CANDIDATE` remains a static INF-selection result only. Runtime compatibility is not established.

## Direct comparison with AMD-published Windows Server 2022 Vega/Polaris

Both sibling artifacts use Display Driver version `31.0.21924.61`, but they are not the same driver package.

- Win11 primary INF: `u0197745.inf`, SHA-256 `c0ef638b92af82492f647d183d0ef7a5fea84ba1b2c30c03d9efa2ca3ce96762`
- Server primary INF: `u2197744.inf`, SHA-256 `d88f4b551db22ad12e20157edd3cc6b32514bcf69c2512e09a907a81d521a45d`
- Win11 topology: 343 HWIDs
- Server topology: 314 HWIDs
- All 314 Server HWIDs are contained in the Win11 set.
- Win11 contains 29 additional Display HWIDs; Server contains 0 unique HWIDs not present in Win11.
- Win11 targeting: ProductType 1, minimum build 16299.
- Server targeting: populated ProductType 2/3, minimum build 20348; less-specific Server/DC sections are empty.
- Common INF basenames: `amdafd.inf`, `amdfendr.inf`, `amdocl.inf`; all three are byte-identical by SHA-256 across the two artifacts.
- `amdkmdag.sys` is referenced by both primary Display INFs but its observed SHA-256 differs between the two artifacts.
- The Server INF additionally declares `amdgpuv` / `amdgpuv.sys` evidence.

This confirms that AMD's native Server package is not merely the Win11 INF with ProductType changed: it also narrows HWID coverage and carries a different core Display binary payload while retaining several byte-identical shared component INFs.

## Toolkit assessment

No parser, identity, schema, or selector defect was exposed by Set 5. Therefore the toolkit script remains version 0.5.0 with unchanged SHA-256. The qualified data package is updated to add Set 5, regenerate the five-artifact cumulative views, and correct the pre-existing Set 4 normalized `InfParseFailureCount` transcription from 5 to the evidence-supported value 0. Historical 0.4.3 evidence is not rewritten.

## Cumulative development dataset

- Canonical artifacts: 5
- INF topology records: 108
- INF × Server rows: 432
- Device/HWID × Server rows: 22,297

The remaining major GA gate is Windows PowerShell 5.1 real-artifact qualification plus broader historical/Unified coverage and runtime host validation.
