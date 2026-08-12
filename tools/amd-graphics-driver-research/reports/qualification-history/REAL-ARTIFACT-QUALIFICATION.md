# AMD Graphics Driver Real-Artifact Qualification — 2026-08-09

Toolkit: **0.2.0**

This report records static analysis of two user-supplied AMD Adrenalin installer artifacts. The AMD installer executables were **not executed**.

## Executive result

- `Test,Acquire,Extract,Inspect,Build`: **PASS**
- Final assessment: **Pass**
- Exit code: **0**
- INF records: **59**
- INF parse failures: **0**

## Container topology

| Release | Branch | EXE SHA-256 | Size | 7-Zip type | Archive offset | Driver INF | Display INF |
|---|---|---|---:|---|---:|---:|---:|
| 26.5.2 | PolarisVega | `2e8755b69ddea92305ac2399102088248c7e2c0f5c7b024a570797ebbbe50e77` | 653,644,328 | 7z | 1,785,344 | 19 | 8 |
| 26.7.1 | Main | `116c6269b7676c3e76f85a8cf0cac82d7df3e85051c0594e18b4b1ea41be9e3d` | 890,916,160 | 7z | 1,785,344 | 40 | 10 |

Both samples are direct **7z SFX** packages. One static extraction exposes `Packages/Drivers/Display/WT6A_INF`; recursive expansion of application MSI files or ordinary helper PE executables is unnecessary for INF inventory. This observation directly motivated the 0.2.0 extraction-stop policy.

## Embedded `Config/InstallManifest.json`

| Release | Embedded ExternalVersion | BuildVersion | featureLevel | Package entries | DRIVER | MSI | Other | Payload URL matches |
|---|---|---|---|---:|---:|---:|---:|---:|
| 26.5.2 | 26.5.2 | `23.19.25.01-260423a-201039C-AMD-Software-Adrenalin-Edition` | 2110 | 15 | 10 | 4 | 1 | 15/15 |
| 26.7.1 | 26.7.1 | `26.10.35.01-260716a-202643C-AMD-Software-Adrenalin-Edition` | 2520 | 29 | 25 | 3 | 1 | 29/29 |

On Linux, manifest URLs and archive path casing are not always byte-for-byte identical (for example `U0201039.INF` vs extracted `u0201039.inf`). The 0.2.0 parser therefore resolves manifest paths case-insensitively, matching Windows filesystem semantics. All package URLs in both samples resolved.

## Display payload

| Release | Main display INF | Driver version | HWID count | Display INF count |
|---|---|---|---:|---:|
| 26.5.2 | `u0201039.inf` | 31.0.21925.1001 | 5,081 | 8 |
| 26.7.1 | `u0202643.inf` | 32.0.31035.1003 | 5,356 | 10 |

26.7.1 additionally exposes `amdogl.inf` and `amdvlk.inf` under `WT6A_INF`, while the supplied 26.5.2 Polaris/Vega payload does not. The 26.7.1 payload also contains `AMDNPUMCDM` and `AMDISP` driver families that are absent from the 26.5.2 sample.

## WDF observations

| Release | KMDF-declaring INF | KMDF versions | UMDF-declaring INF | UMDF versions |
|---|---:|---|---:|---|
| 26.5.2 | 8 | 1.15 | 0 | none |
| 26.7.1 | 19 | 1.11, 1.15, 1.23.0, 1.31 | 2 | 2.23.0, 2.33.0 |

A real 26.7.1 INF (`Packages/Drivers/AMDISP/AMDISP/WT64A/amdisp.inf`) declares `KmdfLibraryVersion = %KMDF_VERSION%` and `UmdfLibraryVersion = %UMDF_VERSION%`; `[Strings]` resolves those tokens to **1.23.0** and **2.23.0**. Version 0.1.0 incorrectly retained the macro tokens as versions. Version 0.2.0 resolves them while preserving the raw directive, line number, resolution status and unresolved-token evidence.

## Package-family expansion in 26.7.1

Compared with the supplied 26.5.2 Polaris/Vega package, the 26.7.1 Main manifest/payload includes additional driver areas such as ACP BT LE audio, ACP BUS2, ACP USB audio, SoundWire, camera/sensor `AMDISP`, and `AMDNPUMCDM`. This is recorded as embedded/payload evidence only; it is not converted into a Windows Server compatibility verdict.

## Script changes derived from these artifacts

1. Added `-LocalInstallerPath` local-only acquisition with validation, SHA-256 and `Provided` status.
2. Added real filename family/branch classification.
3. Added 7-Zip archive probes and SFX topology evidence.
4. Added Graphics analysis-surface detection and stopped redundant nested MSI/helper-PE recursion after INF-bearing driver payload is exposed.
5. Removed filename-only nested EXE traversal.
6. Added semantic `InstallManifest.json` parsing and case-insensitive payload URL mapping.
7. Added INF `[Strings]` substitution for WDF directives.
8. Added `Packages/Drivers/<component>` classification to INF inventory.

## Remaining qualification gates

- Windows PowerShell 5.1 full real-artifact run.
- 23.11.1 split-era Main and Polaris/Vega samples.
- Older Unified Adrenalin sample.
- PRO Edition multi-artifact sample, including a Windows Server-specific artifact when available.

# 0.4.1 Qualification Addendum — Adrenalin 23.11.1 RDNA Combined

The supplied transfer ZIP was CRC-validated and restored to `whql-amd-software-adrenalin-edition-23.11.1-win10-win11-nov3-rdna-combined.exe`. The AMD executable was never launched.

- EXE size: `1,273,693,224` bytes
- EXE SHA-256: `dfc701c2580d14f8ccb729d62e88640e8ba661701d0ea270fb8e63d3f75a19e7`
- Container: direct 7z SFX, offset `1,785,344`, physical size `1,271,896,688`, tail `11,192`
- Payload files observed by 7-Zip: 576 files / 78 folders
- INF: 29 total, 29 parsed, 0 parse failures
- Graphics analysis surface: 16 Display/Display2 INF
- InstallManifest: version match `23.11.1`, featureLevel `2110`, 18 packages (13 DRIVER / 4 MSI / 1 SPECIAL), 18/18 payload paths resolved
- Display package A: `Display2/WT6A_INF/U0397033.INF`, driver `31.0.21905.1001`
- Display package B: `Display/WT6A_INF/U0397406.INF`, driver `31.0.22023.1014`
- WDF: KMDF `1.15`, `1.31`; no UMDF declaration observed

Direct Set 1 comparison found 21 common INF relative paths and all 21 common INF SHA-256 values identical. The Combined artifact adds exactly eight `Display2/WT6A_INF` INF records and removes none of the RDNA-only INF records.

The primary `Display/U0397406.INF` and secondary `Display2/U0397033.INF` are both not applicable as-published to member-server ProductType 3. Under the non-mutating ProductType 1→3 projection, both are `PATCH_CANDIDATE` for Server 2019 / 2022 / 2025 and `NOT_APPLICABLE` for Server 2016 because of build/section evidence. Runtime compatibility remains `NotEstablished`.

Final 0.4.1 evidence was produced as two stage-selected executions because the chat execution harness terminates a single command before the complete five-stage workflow can finalize: `Test,Acquire,Extract,Inspect` PASS / exit 0, followed by `Build` PASS / exit 0 against the same final script and current-run inventory. This is a harness-duration split, not a toolkit-stage failure.
# 0.4.2 Qualification Addendum — PRO Edition 26.Q1 Windows 11 RDNA

The supplied transfer ZIP was CRC-validated and restored to `amd-software-pro-edition-26.q1-win11-rdna.exe`. The AMD executable was never launched.

- EXE size: `987,896,072` bytes
- EXE SHA-256: `12482d7df129ebf40fb79c84e79e17f26dc9dac45f17961e6d18b5f8d39ae6d8`
- Container: direct 7z SFX, offset `1,785,344`, physical size `986,099,197`, tail `11,531`
- Payload observed by 7-Zip: 645 files / 110 folders
- INF: 39 total, 39 parsed, 0 parse failures
- Graphics analysis surface: 7 Display INF
- InstallManifest: version match `26.Q1`, featureLevel `2110`, 31 packages (27 DRIVER / 3 MSI / 1 EXEC_CMD), 31/31 payload paths resolved
- Primary Display: `Display/WT6A_INF/U0200269.INF`, driver `32.0.21041.1000`, 325 flat HWIDs / 321 unique topology HWIDs
- WDF: 17 KMDF-declaring INF (`1.15`, `1.23.0`, `1.31`); 2 UMDF-declaring INF (`2.23.0`, `2.33.0`)

The primary Display INF exposes a populated `NTamd64.10.0.1..19044` Models section and an empty generic `NTamd64.10.0.1` section. As-published it is not a member-server candidate. Under the non-mutating ProductType 1→3 projection it remains `NOT_APPLICABLE` for Server 2016/2019 and becomes `PATCH_CANDIDATE` for Server 2022/2025. Runtime compatibility remains `NotEstablished`.

Across all 39 INF records, the static assessments are:

| Server | Native | Patch candidate | Review | Not applicable |
|---|---:|---:|---:|---:|
| Server 2016 | 14 | 1 | 1 | 23 |
| Server 2019 | 30 | 1 | 3 | 5 |
| Server 2022 | 33 | 2 | 0 | 4 |
| Server 2025 | 36 | 2 | 1 | 0 |

Set 3 exposed a Build scalability issue rather than an INF/parser defect. 0.4.1 recursively normalized and serialized a run-scoped topology that was later overwritten by the cumulative canonical topology, and independently normalized the same Windows Server output twice for two alias JSON files. 0.4.2 removes the redundant topology pass and caches the portable Server object. The final Build then completes in `31.86s` with PASS / exit 0.

Because long combined commands are occasionally terminated by the chat execution harness, final 0.4.2 evidence is preserved as four finalized stage-selected runs: `Test,Acquire` PASS / exit 0; `Extract` PASS / exit 0; `Inspect` PASS / exit 0; and `Build` PASS / exit 0. Every Evidence ZIP snapshots the same final toolkit script SHA-256. The final script has zero PowerShell AST parse errors.


# 0.4.3 Qualification Addendum — PRO Edition 26.Q1 Windows Server 2022 Vega/Polaris

Artifact: `amd-software-pro-edition-26.q1-winsvr2022-vega-polaris.exe`

- Size: `612,792,696` bytes
- SHA-256: `08f5966167a77aa064ba609889362ead3daea5421908d4d475f7fddddc555f0a`
- PackageFamily / Branch / ArtifactRole: `ProEdition / MultiArtifact / WindowsServer-PolarisVega`
- ReleaseKey: `ProEdition|MultiArtifact|26.Q1`
- Direct 7z SFX archive offset: `1,785,344`
- INF files: `5`; parse failures: `0`
- InstallManifest packages: `3` (`1 DRIVER`, `2 MSI`); payload resolution `3/3`
- Primary display: `u2197744.inf`, driver `31.0.21924.61`, flat HWID count `348`, topology unique HWID count `314`
- Primary display INF As-Published: Server 2016/2019 explicitly excluded; Server 2022/2025 `NATIVE_CANDIDATE` under Microsoft INF selection semantics
- Embedded display description: `Display driver for Windows Server 2022`; raw OSCheck: `*-*-10.0.20348.0-Yes-*-Yes`
- KMDF: `1.15` declared by `amdfendr.inf`; UMDF: none
- Final stage-selected qualification: Test PASS, Acquire PASS, Extract PASS, Inspect PASS, Build PASS; all exit `0`

This artifact exposed and qualified a ReleaseKey bug: filename-first `vega-polaris` classification incorrectly split the PRO release as `ProEdition|PolarisVega|26.Q1`. Version 0.4.3 gives PRO family precedence so all 26.Q1 siblings remain under `ProEdition|MultiArtifact|26.Q1`; an identity self-test prevents recurrence.


# 0.5.0 Semantic Sync Regression Addendum

The shared INF semantic contract was forward-ported onto Graphics 0.4.3 and the four retained canonical artifacts were regenerated as new 0.5.0 canonical generations. No historical 0.4.3 evidence was rewritten.

- Shared contract: `amd-inf-semantic-contract/1.0`
- Identifier taxonomy: `amd-inf-identifier-taxonomy/1.0`
- New topology schema: `amd-inf-topology/1.1`
- Legacy topology schema retained for historical validation
- Fixed-prefix Models identifier filtering removed
- Legacy Windows Server `StaticAssessment` changes across the four real artifacts: **0**
- Newly retained topology identifiers relative to 0.4.3: Set1 **13**, Set2 **13**, Set3 **62**, Set4 **0**
- Native Server control (`u2197744.inf`): WS2016/2019 remain excluded; WS2022/2025 remain native INF-selection candidates
- `WdfScope=InfWideConservative`; DDInstall-scoped WDF is not claimed
- Runtime compatibility remains `NotEstablished`

# 0.5.0 Qualification Addendum — PRO Edition 26.Q1 Windows 11 Vega/Polaris

- Canonical artifact: `amd-software-pro-edition-26.q1-win11-vega-polaris.exe`
- SHA-256: `282c2cfa41e6257f6489c1891844217f86ebb614cf7ce9e133203ee6f994d11d`
- `ProEdition|MultiArtifact|26.Q1`, `ArtifactRole=PolarisVega`
- 14 INF / 0 parse failures
- InstallManifest: 10 packages (6 DRIVER / 3 MSI / 1 SPECIAL), 10/10 payload paths resolved
- Primary Display: `u0197745.inf`, `31.0.21924.61`, 343 topology HWIDs
- Primary Display static Server result: WS2016 `NOT_APPLICABLE`; WS2019/2022/2025 `PATCH_CANDIDATE` after non-mutating ProductType projection
- Direct Server sibling comparison: 314/314 Server Display HWIDs are contained in the Win11 343-ID set; 29 Win11 IDs are absent from the Server INF. Common `amdafd.inf`, `amdfendr.inf`, `amdocl.inf` are byte-identical. Primary Display INF and `amdkmdag.sys` hashes differ; Server additionally declares `amdgpuv.sys`.
- Toolkit code unchanged from semantic-sync-qualified 0.5.0.

The 26.Q1 static PRO sibling set now includes Windows 11 RDNA, Windows 11 Vega/Polaris, and Windows Server 2022 Vega/Polaris under the single `ProEdition|MultiArtifact|26.Q1` ReleaseKey.
