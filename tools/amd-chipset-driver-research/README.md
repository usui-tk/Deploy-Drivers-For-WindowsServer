# AMD Chipset Driver Research Toolkit

**Current toolkit version: 1.0.0**

PowerShell research tooling for reconstructing AMD Ryzen Chipset Driver history, acquiring original AMD installer artifacts, statically extracting their nested packages, inspecting INF files, and producing evidence-backed inventory data for KMDF/UMDF and related driver metadata.

The toolkit is intentionally a **research and evidence layer**, not a deployment-policy engine. It records what AMD published and what is observed inside the installer payload. A future resolver in `Deploy-Drivers-For-WindowsServer` may consume the resulting inventory, but this tool does not decide whether a given Windows Server release is compatible with a package.

## Goals

This tool exists to make AMD chipset-driver research repeatable even if AMD changes its website, download links, installer format, or package layout.

The core goals are:

- reconstruct release history from multiple AMD sources instead of relying on a single history page;
- preserve source URLs, timestamps, SHA-256 values, raw release-note evidence, extraction logs and parser evidence;
- download original AMD artifacts without executing them;
- extract modern EXE and historical ZIP delivery formats on Windows or Linux;
- recover nested InstallShield payloads without running AMD setup programs;
- inspect the actual INF payload for `KmdfLibraryVersion` and `UmdfLibraryVersion`;
- keep published metadata, embedded installer metadata and observed payload metadata separate;
- generate compact Evidence ZIP files suitable for repeated review with ChatGPT or another reviewer;
- remain usable from Windows PowerShell 5.1 and PowerShell 7.x;
- keep the PowerShell implementation aggregated into one `.ps1` file.

## Repository location and single-script policy

Canonical layout:

```text
Deploy-Drivers-For-WindowsServer/
└─ tools/
   └─ amd-chipset-driver-research/
      ├─ README.md
      ├─ SPEC.md
      ├─ THIRD-PARTY-NOTICES.md
      ├─ Invoke-AmdChipsetDriverResearch.ps1
      ├─ data/
      ├─ schemas/
      ├─ inventory/
      ├─ evidence/
      ├─ reports/
      └─ work/
```

The implementation intentionally uses **one PowerShell script**. Discovery, HTTP acquisition, extraction, InstallShield decoding, INF parsing, evidence collection, logging and inventory generation are internal functions of `Invoke-AmdChipsetDriverResearch.ps1`.

Future tools should follow the same repository convention when practical:

```text
tools/
├─ amd-chipset-driver-research/
├─ amd-graphics-driver-research/
└─ ...
```

## Runtime support

Supported execution environments:

- Windows PowerShell 5.1 on Windows
- PowerShell 7.x on Windows
- PowerShell 7.x on Linux

The script avoids PowerShell-7-only syntax in the shared implementation.

Encoding conventions:

- `.ps1`: UTF-8 with BOM + CRLF
- Markdown / canonical JSON: UTF-8 without BOM
- ZIP entry paths: normalized to `/` so Evidence ZIP files created on Windows can be consumed cleanly by Linux ZIP tools

## Safety model

The toolkit is designed for static research.

- Downloaded AMD EXEs are **never executed**.
- MSI packages are **never installed**.
- INF packages are **never installed**.
- `pnputil`, driver-store modification, catalog re-signing and certificate installation are outside scope.
- Outer containers are processed with 7-Zip.
- AMD InstallShield `ISSetupStream` payloads are decoded by the in-script static decoder.
- Recovered MSI/CAB/ZIP/7z containers are recursively inspected to a bounded depth.
- AMD installer binaries are excluded from the Evidence ZIP by default.

## Quick start

### Default: full research

No `-Stages` argument means the full workflow:

```powershell
cd .\tools\amd-chipset-driver-research
.\Invoke-AmdChipsetDriverResearch.ps1
```

Equivalent explicit form:

```powershell
.\Invoke-AmdChipsetDriverResearch.ps1 -Stages All
```

Environment check only:

```powershell
.\Invoke-AmdChipsetDriverResearch.ps1 -Stages Test
```

Metadata-only research:

```powershell
.\Invoke-AmdChipsetDriverResearch.ps1 `
    -Stages Discover,Metadata,Build
```

Specific release:

```powershell
.\Invoke-AmdChipsetDriverResearch.ps1 `
    -ReleaseVersion 8.07.16.1035
```

The explicit stage switch remains useful for troubleshooting:

```powershell
.\Invoke-AmdChipsetDriverResearch.ps1 `
    -Stages Acquire,Extract,Inspect,Build `
    -ReleaseVersion 7.11.26.2142
```

From Bash / POSIX shells, comma-separated stage values are accepted:

```bash
pwsh -File ./Invoke-AmdChipsetDriverResearch.ps1 -Stages Extract,Inspect,Build
```

## Stages

### Test

Records execution-environment evidence:

- platform family;
- OS and process architecture;
- PowerShell version and edition;
- 7-Zip path/command;
- Linux package-manager evidence when available;
- metadata-research readiness;
- full static-extraction readiness.

Output:

```text
inventory/environment.json
```

### Discover

Combines:

1. curated seed releases;
2. AMD sitemap discovery;
3. operator-provided release-note URLs.

AMD release-note URL is treated as provenance, not release identity. The release identity is the four-part chipset version.

The parser handles AMD URLs that contain more than one version token. For example AMD currently publishes the 7.02.13.148 page under a path containing both `6-10-17-152` and `7-02-13-148`; the leaf-side/final version token is used.

Multiple URLs for the same release version are normalized to one release record, with alternate URLs retained in `DiscoveryDiagnostics`.

Output:

```text
inventory/releases.json
```

### Metadata

For every discovered release, records:

- release-note URL;
- article number/title;
- retrieval timestamp;
- captured HTML SHA-256;
- candidate artifact URLs;
- parser/fetch diagnostics.

The candidate resolver uses both page links and known AMD historical naming patterns because old release-note pages may no longer expose a usable download link.

Output:

```text
inventory/release-metadata.json
evidence/release-notes/
```

### Acquire

Downloads the AMD artifact without executing it.

The implementation uses browser-like AMD request headers and verifies that the response is an actual binary artifact rather than AMD's `Download Not Complete` HTML page.

Observed delivery formats include:

- modern/normal EXE delivery;
- historical ZIP delivery containing an AMD outer installer EXE.

Output:

```text
inventory/acquisition.json
evidence/installers/
```

### Extract

Static extraction pipeline:

```text
AMD artifact
   │
   ├─ EXE (NSIS outer container)
   │
   └─ historical ZIP
          │
          └─ AMD outer EXE
                 │
                 ▼
        AMD_Chipset_Drivers.exe
                 │
                 │ InstallShield ISSetupStream
                 ▼
        AMD_Chipset_Drivers.msi
                 │
                 ▼
              Data1.cab
                 │
                 ▼
          INF / SYS / CAT / MSI
```

7-Zip handles normal archive/container layers. The single PowerShell script statically decodes the observed InstallShield `ISSetupStream` layer and feeds recovered containers back into recursive extraction.

`ExtractionComplete` requires INF discovery. Successfully opening only the outer archive with zero INF files is not considered a complete extraction.

Outputs:

```text
work/extracted/
inventory/extraction.json
evidence/extraction-logs/
```

### Inspect

Inspects embedded AMD metadata and every discovered INF.

INF evidence includes:

- INF path and SHA-256;
- `Provider`, `Class`, `ClassGuid`;
- `DriverVer`, driver date/version;
- `CatalogFile`;
- hardware IDs;
- referenced service binaries and hashes where resolvable;
- all `KmdfLibraryVersion` directives;
- all `UmdfLibraryVersion` directives;
- directive line number and raw source line.

No WDF version is inferred when the INF does not declare one.

Embedded metadata output:

```text
inventory/embedded-installer-metadata.json
```

Driver-package output:

```text
inventory/driver-packages.json
```

### Build

Builds canonical and human-readable views:

```text
inventory/amd-chipset-driver-inventory.json
inventory/amd-chipset-driver-inventory.csv
reports/amd-chipset-driver-history.md
```

## Evidence and iterative troubleshooting

Every invocation creates a run-scoped evidence session before stage execution.

Default layout:

```text
evidence/runs/
├─ AmdChipsetDriverResearchEvidence_<timestamp>_<platform>/
└─ AmdChipsetDriverResearchEvidence_<timestamp>_<platform>.zip
```

The Evidence ZIP contains compact review material:

```text
assessment.json
stage-results.json
run-context.json
run-summary.json
run-summary.txt
external-artifacts.json
evidence-manifest.json
archive-capability.json
logs/console-transcript.txt
errors/
snapshot/tool/
snapshot/inventory/
snapshot/reports/
snapshot/release-notes/
snapshot/extraction-logs/
```

The large `work/extracted` tree and AMD installer binaries are excluded by default.

Useful switches:

```powershell
# Label the review bundle.
.\Invoke-AmdChipsetDriverResearch.ps1 -EvidenceLabel 'server2019-check'

# Choose another evidence root.
.\Invoke-AmdChipsetDriverResearch.ps1 `
    -EvidenceOutputRoot 'D:\Evidence\AMD'

# Keep loose evidence only.
.\Invoke-AmdChipsetDriverResearch.ps1 -SkipEvidenceArchive

# Explicitly include downloaded AMD binaries.
.\Invoke-AmdChipsetDriverResearch.ps1 -IncludeInstallersInEvidence
```

Outcome contract:

- exit `0` = `Pass`
- exit `2` = `ReviewRequired`
- exit `1` = fatal top-level failure

A stage failure does not normally prevent final evidence packaging. If ZIP creation fails, the loose evidence directory is retained.

## Operator-facing logging

The console uses the same general operational style as the repository deployment scripts:

```text
[HH:mm:ss] [+elapsed] [*] progress
[HH:mm:ss] [+elapsed] [+] success
[HH:mm:ss] [+elapsed] [!] warning/review item
[HH:mm:ss] [+elapsed] [X] failure
[HH:mm:ss] [+elapsed] [~] expected fallback / informational skip
```

Long stages show `[current/total]`, release version, per-item outcome and elapsed time.

Each stage has a start/end banner, and finalization prints total elapsed time plus a per-stage timing table.

A representative Windows PowerShell 5.1 full run on 2026-08-09 took about 4 minutes 30 seconds, with most time spent in `Acquire` and `Extract`.

## Research findings from real AMD installers

The following findings were derived from real AMD artifacts and Evidence runs, not from filename guesses.

### 1. AMD chipset software is a bundle of independent drivers

The chipset installer is not one driver with one KMDF requirement. It contains many independent packages such as PCI, I2C, GPIO, PSP, SMBus, SFH, MicroPEP, USB4 CM, PMF, 3D V-Cache and other components.

Therefore the meaningful research unit is:

```text
AMD chipset installer release
    -> contained driver package / INF
        -> hardware/OS applicability
        -> declared WDF requirement
```

An installer-wide "KMDF version" is only an envelope over the contained packages and must not be interpreted as a requirement that applies to every target machine.

### 2. Historical delivery format changed, but static Linux analysis remains possible

Observed delivery formats:

- 2.04.04.111: ZIP wrapper
- 3.08.17.735: ZIP wrapper
- 3.09.01.140: ZIP wrapper
- 3.10.08.506 and later validated releases: EXE delivery

The historical ZIPs contain another AMD outer installer EXE. The tool recursively processes that EXE without executing it.

### 3. The inner installer architecture is stable across a long period

Validated real installers from 2.04 through 8.07 use an outer AMD package that ultimately exposes an InstallShield `ISSetupStream` payload.

Observed stream generations:

- 2.04 through 6.10: type 3
- 7.02 through 8.07: type 4

The pre-GA v0.4.3 Windows PowerShell 5.1 acceptance run, which is the functional acceptance baseline promoted to 1.0.0, directly confirmed 7.02.13.148 as `ISSetupStream` type 4 and recovered its MSI successfully.

This means Linux does not require Wine or Windows Installer execution for the validated generations.

### 4. Real INF WDF observations

The pre-GA v0.4.3 Windows PowerShell 5.1 acceptance run, which is the functional acceptance baseline promoted to 1.0.0, discovered **25 unique releases**, acquired **25/25 artifacts**, reached `ExtractionComplete` for **25/25 releases**, and inspected **643 INF files** with zero INF parse failures. The run recorded **158 KMDF declarations** and **25 UMDF declarations**.

| Release | AMD artifact | ISSetupStream | INF | KMDF versions declared by INF | UMDF versions declared by INF |
|---|---|---:|---:|---|---|
| 2.04.04.111 | ZIP | 3 | 24 | 1.11, 1.15 | 2.15.0 |
| 3.08.17.735 | ZIP | 3 | 16 | 1.11, 1.15 | 2.15.0 |
| 3.09.01.140 | ZIP | 3 | 16 | 1.11, 1.15 | 2.15.0 |
| 3.10.08.506 | EXE | 3 | 16 | 1.11, 1.15 | 2.15.0 |
| 4.03.03.431 | EXE | 3 | 16 | 1.11, 1.15 | 2.15.0 |
| 4.06.10.651 | EXE | 3 | 24 | 1.11, 1.15, 1.19 | 2.15.0 |
| 4.08.09.2337 | EXE | 3 | 24 | 1.11, 1.15, 1.19 | 2.15.0 |
| 4.09.23.507 | EXE | 3 | 24 | 1.11, 1.15, 1.19 | 2.15.0 |
| 4.11.15.342 | EXE | 3 | 24 | 1.11, 1.15, 1.19 | 2.15.0 |
| 5.02.19.2221 | EXE | 3 | 25 | 1.11, 1.15, 1.19 | 2.15.0 |
| 5.05.16.529 | EXE | 3 | 26 | 1.11, 1.15, 1.19 | 2.15.0 |
| 5.08.02.027 | EXE | 3 | 27 | 1.11, 1.15, 1.19 | 2.15.0 |
| 6.01.25.342 | EXE | 3 | 27 | 1.11, 1.15, 1.19 | 2.15.0 |
| 6.02.07.2300 | EXE | 3 | 27 | 1.11, 1.15, 1.19 | 2.15.0 |
| 6.05.28.016 | EXE | 3 | 28 | 1.11, 1.15, 1.19 | 2.15.0 |
| 6.07.22.037 | EXE | 3 | 28 | 1.11, 1.13, 1.15, 1.19 | 2.15.0 |
| 6.10.17.152 | EXE | 3 | 28 | 1.11, 1.13, 1.15, 1.19 | 2.15.0 |
| 7.02.13.148 | EXE | 4 | 30 | 1.11, 1.13, 1.15, 1.19 | 2.15.0 |
| 7.04.09.545 | EXE | 4 | 30 | 1.11, 1.13, 1.15, 1.19 | 2.15.0 |
| 7.06.02.123 | EXE | 4 | 30 | 1.11, 1.13, 1.15, 1.19 | 2.15.0 |
| 7.11.26.2142 | EXE | 4 | 31 | 1.13, 1.15, 1.19 | 2.15.0 |
| 8.01.20.513 | EXE | 4 | 29 | 1.13, 1.15, 1.19 | 2.15.0 |
| 8.02.18.557 | EXE | 4 | 31 | 1.13, 1.15, 1.19 | 2.15.0 |
| 8.05.04.516 | EXE | 4 | 31 | 1.13, 1.15, 1.19 | 2.15.0 |
| 8.07.16.1035 | EXE | 4 | 31 | 1.13, 1.15, 1.19 | 2.15.0 |

Important interpretation:

- no validated release in this 2.04 through 8.07 dataset declares KMDF newer than **1.19**;
- UMDF declarations observed in every validated release are **2.15.0**;
- 1.19 first appears in this validated history at 4.06.10.651, including `amdusb4cm.inf`;
- 1.13 first appears in the collected sequence at 6.07.22.037;
- 7.02.13.148 increases the number of KMDF-declaring INF packages to 8, but the highest declared KMDF remains 1.19;
- 7.11 and 8.x no longer contain the 1.11 declaration observed in earlier generations;
- PSP changed across generations and has been observed with KMDF 1.11 and later 1.13;
- SFH KMDF packages remain examples of KMDF 1.15 declarations;
- these are **per-INF declarations**, not blanket installer requirements.

This result does **not** prove that every component in a modern AMD installer is compatible with every old Windows release. WDF version is only one compatibility dimension. OS decorations, supported hardware IDs, component-selection rules, binary behavior, signing and other dependencies must also be evaluated by the deployment project.

### 5. The original "newest installer implies newest KMDF" hypothesis is too simple

The initial investigation was motivated by concern that newer AMD chipset installers might unconditionally require newer KMDF generations.

The observed INF history does not support that as a simple installer-version rule. Modern validated 7.x/8.x packages still contain WDF declarations such as KMDF 1.13, 1.15 and 1.19 rather than a monotonically increasing installer-wide requirement.

The deployment project should therefore avoid rules such as:

```text
AMD chipset installer 8.x -> KMDF 1.33 required
```

unless a specific package/INF/binary provides that evidence.

Instead, compatibility resolution should eventually use the actual package selected for the target hardware.

### 6. Published release notes and embedded installer metadata can differ

AMD's public release-note table and the installer's embedded `Qt_Dependencies/Info.xml` are distinct evidence layers.

For 8.07.16.1035, observed examples include:

- published PPM Provisioning File Driver: 8.0.0.62; embedded metadata: 8.0.0.64;
- published Windows 10 AMS Mailbox Driver: 5.1.0.1480; embedded metadata: 5.0.0.1075;
- published Windows 11 PMF-7040 Series Driver: 25.2.7.0; embedded metadata: 26.2.8.0;
- some embedded Windows 11 component records exist even where the public table says `Not Applicable`.

Therefore the toolkit keeps these layers separate:

```text
PublishedMetadata
EmbeddedInstallerMetadata
PayloadObservedMetadata
```

No layer silently overwrites another. Actual INF/SYS evidence remains independently inspectable.

### 7. AMD historical links can remain recoverable even when they are not obvious on the page

The Windows PowerShell 5.1 acceptance run automatically acquired 2.04.04.111 from:

```text
https://drivers.amd.com/drivers/amd_software_2.04.04.111.zip
```

even though the operator could not locate a working manual download link during earlier research.

This is why the acquisition logic combines captured page links with version-scoped historical filename synthesis and validates the resulting payload before accepting it.

### 8. AMD release-note URLs are not guaranteed to have a clean one-version path

AMD currently exposes 7.02.13.148 under:

```text
https://www.amd.com/en/resources/support-articles/release-notes/
RN-RYZEN-CHIPSET-6-10-17-152/RN-RYZEN-CHIPSET-7-02-13-148.html
```

A parser that takes the first version token incorrectly identifies this as 6.10.17.152.

1.0.0 uses the final/leaf-side four-part version token and normalizes alternate URLs to one record per release identity.

## Validated environments

### Windows

Validated with:

- Windows 11 build 26200
- Windows PowerShell 5.1.26100.8972
- 7-Zip 26.02

The 2026-08-09 pre-GA acceptance run (v0.4.3 code, promoted functionally unchanged to 1.0.0 except version metadata/document packaging) completed:

```text
StageExecution          PASS
ResearchEnvironment     PASS
Acquisition             PASS
ExtractionCompleteness  PASS
InfInspection           PASS
Overall                 Pass
Exit code               0
```

Acceptance-run totals:

```text
Unique releases         : 25
Artifacts acquired      : 25 / 25
ExtractionComplete      : 25 / 25
INF files inspected     : 643
KMDF declarations       : 158
UMDF declarations       : 25
INF parse failures      : 0
Total runtime           : 4m43.5s
```

Stage timings from that run:

```text
Test       0.17s
Discover   0.77s
Metadata   3.36s
Acquire    2m38.8s
Extract    1m29.4s
Inspect    28.55s
Build      1.24s
```

The corrected discovery logic independently identified and processed 7.02.13.148 rather than duplicating 6.10.17.152. Its installer was acquired from AMD, statically extracted, identified as `ISSetupStream` type 4, and produced 30 INF records.

The generated Evidence ZIP was also verified independently: all **588 manifest-tracked files** matched their recorded SHA-256 values with zero missing or mismatched entries.

### Linux

Validated with:

- Debian GNU/Linux 13.x
- PowerShell 7.6.4
- Debian 7-Zip package / native CLI

Real AMD 3.x through 8.x artifacts were previously validated through the full static extraction path. The same extraction design is used for historical ZIP wrappers.

The toolkit also recognizes the Debian packaging difference observed during testing:

- Debian 12 package: `7zz`
- Debian 13 package: `7z` / `7za` / `7zr`

Automatic discovery therefore checks `7zz`, then `7z`, then `7za`.


## Repository-committed accepted baseline

Version 1.0.0 ships a repository-friendly snapshot of the accepted 2026-08-09 research results under:

```text
inventory/accepted-baseline/
```

This directory is intentionally distinct from the normal runtime outputs written directly under `inventory/`. The accepted baseline contains parsed/normalized research data suitable for code review and historical comparison, with companion accepted reports under `reports/accepted-baseline/`. It excludes AMD installer binaries, raw extraction trees, console transcripts, and raw release-note HTML.

The baseline was generated by the fully accepted pre-GA v0.4.3 run on Windows PowerShell 5.1 and then promoted to 1.0.0 without changing the accepted extraction/inspection logic. Its JSON therefore retains `ToolkitVersion = 0.4.3` as provenance. `baseline-provenance.json` records the source Evidence ZIP SHA-256 and the path-normalization rules applied for repository portability. Its structure is described by `schemas/accepted-baseline.schema.json`.

Do not reinterpret the baseline as deployment policy. It is a research snapshot. Regenerate the inventory with the current script when AMD publishes new releases or changes package layout.

## Cross-platform evidence portability

Evidence bundles are expected to move between Windows test machines and Linux/ChatGPT analysis environments.

1.0.0 writes ZIP entry names with `/` separators. This avoids the warning/non-zero behavior that common Linux `unzip` tools can produce when a Windows-created ZIP stores entry names with backslashes.

## Related host-side WDF context

This toolkit intentionally inventories **driver-side declarations**. Host-side WDF capability must be measured separately and should not be guessed only from the Windows Server marketing version.

Separate project research in the same investigation observed:

- Windows Server 2019: on-disk `Wdf01000.sys` reported KMDF **1.27**, matching the published 1809-generation reference;
- Windows Server 2025: on-disk `Wdf01000.sys` reported KMDF **1.35**, newer than the Microsoft public WDF history reference used during the investigation;
- UMDF minor/API level should not be inferred from the PE `FileVersion` of `WUDFx02000.dll`, because that binary can use Windows component-style versions such as `10.0.x.y`.

The intended future integration model is therefore:

```text
Host-side observed WDF capability
        +
hardware-matched AMD INF declaration
        +
OS decoration / hardware ID / binary / signing constraints
        ↓
Deploy-Drivers-For-WindowsServer compatibility decision
```

The research toolkit supplies only the AMD package side of that decision.

## Data philosophy

### Observed facts, not compatibility policy

The canonical data model records observations and provenance. It does not encode a server compatibility matrix.

A future project resolver may compare, for example:

```text
Host KMDF
vs.
hardware-matched INF KmdfLibraryVersion
```

but that decision is downstream of this research toolkit.

### Unknown is not compatible

`NotDeclared`, `NotInspected`, `ParseFailed`, `FetchFailed`, and `ExtractionFailed` are distinct states.

A null WDF version must never be interpreted as "compatible".

### Provenance is first-class

Important observations retain enough evidence to reproduce or audit them:

- AMD source URL;
- captured page;
- retrieval time;
- artifact SHA-256;
- extraction log;
- INF SHA-256;
- line number;
- raw directive text;
- parser/toolkit version;
- execution environment.

## Canonical outputs

Primary machine-readable outputs:

```text
inventory/environment.json
inventory/releases.json
inventory/release-metadata.json
inventory/acquisition.json
inventory/extraction.json
inventory/embedded-installer-metadata.json
inventory/driver-packages.json
inventory/amd-chipset-driver-inventory.json
```

Derived human-oriented outputs:

```text
inventory/amd-chipset-driver-inventory.csv
reports/amd-chipset-driver-history.md
```

The canonical JSON should be treated as the integration boundary for future `Deploy-Drivers-For-WindowsServer` resolver logic.

## Known limitations and next research areas

- Historical discovery remains best-effort even though the 2026-08-09 acceptance run successfully reconstructed and processed 25 releases from 2.04.04.111 through 8.07.16.1035. AMD may remove or rename additional historical pages or artifacts in the future.
- INF-declared WDF versions do not alone establish complete Windows Server compatibility.
- Some driver packages may have important binary/runtime behavior not represented by `KmdfLibraryVersion` / `UmdfLibraryVersion`.
- Published AMD metadata may disagree with embedded installer metadata.
- Future AMD installers may replace NSIS, InstallShield, MSI or CAB with another packaging model; extractor detection must fail explicitly rather than treating zero-INF output as success.
- `msitools`, `cabextract`, Wine and similar tools are not currently mandatory because the validated pipeline can reach INF using PowerShell + 7-Zip + the in-script decoder.

## Third-party reference implementation

The static InstallShield decoder was informed by the MIT-licensed ISx project:

```text
https://github.com/lifenjoiner/ISx
```

Attribution and license information are preserved in `THIRD-PARTY-NOTICES.md`.

## Primary external references

AMD:

```text
https://www.amd.com/en/resources/support-articles/release-notes/
https://www.amd.com/en/support/downloads/previous-drivers.html/chipsets/
https://drivers.amd.com/
```

Microsoft WDF:

```text
https://learn.microsoft.com/en-us/windows-hardware/drivers/wdf/framework-library-versioning
https://learn.microsoft.com/en-us/windows-hardware/drivers/wdf/kmdf-version-history
https://learn.microsoft.com/en-us/windows-hardware/drivers/wdf/umdf-version-history
```

## Pre-GA hardening promoted into 1.0.0

The final pre-GA v0.4.3 cycle added two hardening fixes found during review of the Windows PowerShell 5.1 runs. Both are part of the 1.0.0 GA baseline:

1. **Release identity hardening**
   - uses the final four-part version token when an AMD URL contains multiple versions;
   - adds 7.02.13.148 to the curated seed set;
   - normalizes multiple release-note URLs to a single four-part release identity;
   - retains alternate URLs as discovery diagnostics.

2. **Cross-platform Evidence ZIP hardening**
   - writes ZIP entries explicitly using `/` separators;
   - avoids Windows-created backslash entry names that trigger warnings/non-zero status in common Linux `unzip` tooling.

The PowerShell implementation remains a single `.ps1` file and retains Windows PowerShell 5.1 / PowerShell 7.x compatibility requirements.

### 1.0.0 functional acceptance provenance

The subsequent Windows PowerShell 5.1 full run accepted both hardening changes. Version 1.0.0 promotes that functionally accepted code; the accepted dataset intentionally retains its original generating version for provenance:

- 7.02.13.148 was independently discovered and processed as its own release;
- all 25 releases reached `ExtractionComplete`;
- the run finished `Pass` with exit code 0;
- the Windows-created Evidence ZIP was portable to Linux ZIP tooling;
- all 588 manifest-tracked evidence files passed SHA-256 verification.

No additional functional script defect was identified in that acceptance evidence.
