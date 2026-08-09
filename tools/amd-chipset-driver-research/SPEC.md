# AMD Chipset Driver Research Toolkit Specification

**Specification baseline: toolkit 1.0.0**

## 1. Purpose

The toolkit SHALL provide a reproducible, PowerShell-based research workflow for AMD Ryzen Chipset Driver releases and their driver-package WDF requirements.

It SHALL remain logically independent from `Deploy-Drivers-For-WindowsServer` deployment policy.

Primary goals:

1. reconstruct AMD chipset release history;
2. retain release-note and installer provenance;
3. statically extract AMD packages without executing installers;
4. inspect INF declarations;
5. produce canonical machine-readable inventory data;
6. remain maintainable if AMD changes release-note URLs or installer container formats.

## 2. Repository placement

The canonical path SHALL be:

```text
tools/amd-chipset-driver-research/
```

New research families SHALL use sibling directories under `tools/`, for example `tools/amd-graphics-driver-research/`.

## 3. PowerShell aggregation policy

The toolkit SHALL expose **one PowerShell script**:

```text
Invoke-AmdChipsetDriverResearch.ps1
```

Stage-specific implementation SHALL be aggregated into internal functions in that script rather than separate `.ps1` files or a `.psm1` module.

The implementation MAY use internal function boundaries for maintainability, but those functions SHALL NOT create runtime dependencies on additional PowerShell source files.

Additional PowerShell files SHOULD NOT be introduced unless a future requirement cannot reasonably be met within the single-script model and the exception is explicitly documented.

Data files, JSON schemas, generated inventory, raw evidence and Markdown documentation are not subject to the single-PowerShell-file restriction.

## 4. Runtime compatibility

The single `.ps1` SHALL support:

- Windows PowerShell 5.1 on Windows
- PowerShell 7.x on Windows and Linux

It SHALL NOT use ternary operators, null-coalescing operators, pipeline-chain operators, `ForEach-Object -Parallel`, or PowerShell-7-only cmdlet parameters without a compatibility branch.

Web helpers SHALL remain compatible with Windows PowerShell 5.1 and PowerShell 7.x. Expected HTTP failures SHOULD be handled through a .NET request path that does not leak caught cmdlet error records into the console transcript. TLS 1.2 SHALL be enabled for Windows PowerShell 5.1 where supported.

The single script SHALL detect the host platform at runtime. Linux support SHALL NOT require a second `.ps1` implementation or a PowerShell module.

## 5. Encoding

Repository policy:

- `.ps1`: UTF-8 with BOM, CRLF working-tree form;
- `.md`: UTF-8 without BOM, LF;
- canonical JSON: UTF-8 without BOM, LF;
- derived CSV: UTF-8; BOM differences between engines are non-authoritative.

Canonical JSON SHALL be written through .NET `System.IO.File` with `UTF8Encoding(false)` rather than relying on version-dependent `Set-Content -Encoding UTF8` behavior.

## 6. Stage model

The single script SHALL expose selectable stages through `-Stages` while keeping a single source artifact.

Supported stages:

- `Test`
- `Discover`
- `Metadata`
- `Acquire`
- `Extract`
- `Inspect`
- `Build`
- `All` as an ordered shorthand for all stages.

When `-Stages` is omitted, the script SHALL behave as `-Stages All`. Explicit stage selections SHALL retain their existing meaning.

### D0 Environment test

The `Test` stage SHALL validate the supported PowerShell runtime, detect the host platform, and report 7-Zip availability. Missing 7-Zip does not prevent metadata research, but extraction readiness SHALL be reported separately.

The stage SHALL persist reproducibility evidence to `inventory/environment.json`, including platform family, OS description/architecture, PowerShell version/edition, selected 7-Zip command/path, Linux package-manager/package evidence when available, and readiness state.

On Windows, 7-Zip discovery SHOULD prefer `7z.exe` and standard 7-Zip installation locations. On Linux/macOS, discovery SHALL prefer the native `7zz` command, then accept `7z` and `7za` as compatibility fallbacks. `-SevenZipPath` SHALL override automatic discovery on all platforms. On Linux, package-manager queries SHOULD check common package names when `dpkg-query`, `rpm`, or `apk` is available, but package-manager installation SHALL NOT be required when a usable standalone binary is present.

### D1 Discovery

Inputs: AMD sitemap(s), curated seed URLs and operator-supplied URLs.

Output: release identities and release-note URLs.

Discovery SHALL preserve `DiscoverySource` and SHALL NOT assert completeness merely because no more sitemap records are found.

### D2 Metadata

Inputs: discovered release-note URLs.

Outputs: captured raw HTML evidence, page metadata and candidate AMD installer URLs.

Metadata SHALL preserve fetch errors per release. HTML decoding SHALL honor declared charset information and default safely to UTF-8 when an HTTP stack reports an ambiguous legacy encoding. Candidate URL parsing SHALL reject unrelated navigation links and URLs whose embedded release version does not match the release record. Known AMD historical artifact naming patterns MAY be synthesized to recover releases whose current release-note page no longer exposes a direct artifact URL.

### D3 Acquisition

Inputs: candidate installer URLs.

Outputs: local installer evidence, artifact format, SHA-256, size and source/referrer provenance.

Acquisition SHALL support both modern PE/EXE installer artifacts and historical ZIP delivery artifacts. It SHALL reject HTML/error pages even when the HTTP request returns success. Acquisition SHALL NOT execute downloaded files. By default it SHALL reject candidate download hosts outside `amd.com` and its subdomains unless the operator explicitly overrides that policy. Expected 404/retired-URL conditions SHALL be persisted as structured acquisition evidence without dumping raw PowerShell terminating-error records to the console.

### D4 Extraction

Inputs: downloaded installer artifacts.

The default extractor adapter SHALL be 7-Zip and SHALL use the same command-line extraction model on Windows and Linux. Extraction SHALL never execute installer EXEs or MSI packages, SHALL recurse only to a bounded depth, and SHALL record extraction failures rather than treating them as empty packages.

No additional Linux extractor SHALL be mandatory unless real package evidence demonstrates a format that the selected 7-Zip implementation cannot inspect. Optional future adapters such as `msitools` or `cabextract` MAY be introduced only with documented justification.

The internal implementation SHOULD make later replacement of the extraction mechanism possible without redesigning canonical inventory data.

### D5 Driver inspection

For each INF, the parser SHALL record path, SHA-256, `Provider`, `Class`, `ClassGuid`, `DriverVer`, `CatalogFile`, hardware IDs, service binary references, and all observed `KmdfLibraryVersion` / `UmdfLibraryVersion` directives.

Every WDF directive SHALL retain line number, raw line and normalized value. The parser SHALL NOT infer KMDF/UMDF from binary file versions.

### D6 Inventory build

Canonical output:

```text
inventory/amd-chipset-driver-inventory.json
```

Derived outputs:

```text
inventory/amd-chipset-driver-inventory.csv
reports/amd-chipset-driver-history.md
```

Compatibility against Windows Server versions SHALL NOT be hard-coded into the canonical research inventory.

## 7. State vocabulary

Network/artifact states SHOULD use explicit values such as `Discovered`, `Fetched`, `FetchFailed`, `Downloaded`, `DownloadFailed`, `Extracted`, `ExtractionFailed`, `Inspected`, `ParseFailed`, `NotDeclared`, and `NotInspected`.

`null` SHALL represent absence/unknown data only when paired with a status that describes why it is null.

## 8. WDF model

Canonical INF requirement representation SHALL preserve the declared framework, version and raw INF evidence. No server compatibility SHALL be inferred from `NotDeclared`.

## 9. Release identity

AMD release identity SHALL use the four-part chipset installer version string when available, e.g. `7.11.26.2142`.

The parser SHALL accept dot-separated and hyphen-separated forms when extracting a version from URLs/titles. Release-note URL is provenance, not identity.

If a URL contains multiple four-part version tokens, the parser SHALL prefer the final/leaf-side token. This is required for AMD URLs such as the currently published 7.02.13.148 release-note path that contains an older 6.10.17.152 version in a parent segment.

Discovery output SHALL normalize alternate URLs to one canonical record per four-part release identity. Alternate URLs and their discovery sources SHOULD remain available in diagnostics so deduplication does not discard provenance. Operator-supplied URLs SHOULD take precedence over curated seed URLs, which SHOULD take precedence over sitemap-discovered aliases.

## 10. Raw evidence retention

Raw AMD release-note HTML SHOULD be retained. Downloaded AMD installers MAY be retained locally as evidence but SHALL NOT be committed or redistributed unless licensing explicitly permits it.

The repository SHOULD commit metadata and inventory, not AMD binary payloads.

## 11. Reproducibility

Each canonical inventory SHALL contain schema version, toolkit version, generated UTC timestamp, input artifact SHA-256 values where available, source URLs, parser/extractor status, and SHOULD embed the most recent `inventory/environment.json` evidence when available.

A future parser SHALL be able to re-run against preserved evidence without requiring the original AMD page to remain online.

## 12. Failure policy

Individual release fetch/download/extraction failures SHALL be captured and processing SHOULD continue for other releases. Best-effort sitemap XML failures SHALL be summarized compactly; response bodies SHALL NOT be embedded verbatim in console exception text.

Fatal errors include unreadable canonical input files, invalid required schema structure, and output path collisions that would destroy unrelated data.

## 13. Security

The toolkit SHALL never invoke downloaded AMD EXEs, invoke MSI installation, call `pnputil`, import certificates, or modify driver store / Code Integrity policy.

Extraction is analysis, not installation.

## 14. Cross-platform invariants

Windows and Linux runs SHALL produce the same canonical research concepts for equivalent input artifacts. Platform-specific fields MAY differ only where the evidence itself is platform-specific, such as extractor path or PowerShell edition.

The canonical WDF requirements SHALL continue to come from INF declarations; running the parser on Linux SHALL NOT change KMDF/UMDF interpretation.

## 15. Future tools

Other research families SHOULD use the same repository placement rule:

```text
tools/<tool-name>/
```

Examples include AMD graphics and NPU driver research. Each tool SHOULD remain self-contained. Shared PowerShell modules SHOULD NOT be introduced merely for code reuse; the repository preference is aggregation. Shared non-PowerShell schemas or data conventions MAY be considered later if multiple tools demonstrate a stable need.

## Cross-platform stage argument contract

`-Stages` MUST accept both native PowerShell string arrays and comma-separated values passed through `pwsh -File` from POSIX shells. Omitting `-Stages` MUST resolve to the full pipeline.

## 16. Evidence-run contract

Every invocation SHALL initialize a run-scoped evidence session before resolving or executing requested stages. Evidence collection is part of the research workflow, not a separate helper script.

The evidence run SHALL record at minimum:

- toolkit version and evidence schema version;
- executing script path and SHA-256 when obtainable;
- invocation parameters and selected platform;
- console transcript when supported, with `TranscriptStarted` reflecting the post-attempt state;
- per-stage start/end time, duration, status and error details in `stage-results.json`;
- final assessment and exit code;
- snapshots of generated inventory and reports;
- extraction/download diagnostic logs;
- external artifact metadata including installer SHA-256 without requiring installer bytes in the ZIP;
- per-file SHA-256 manifest for the final evidence directory.

Evidence finalization SHALL be attempted from top-level `finally` processing so a stage exception does not normally prevent creation of a troubleshooting bundle. ZIP failure SHALL NOT delete the loose evidence directory or mask an earlier research error.

Default status contract:

- exit 0: successful/complete research outcome;
- exit 2: evidence exists but the run requires review because one or more selected stages/results are incomplete or failed;
- exit 1: fatal top-level error.

AMD installer binaries SHALL be excluded from the evidence ZIP by default. `-IncludeInstallersInEvidence` MAY opt in to copying them. Extracted working trees SHALL remain external and SHALL be represented through manifests/logs rather than copied wholesale.

## 17. Deep static extraction contract

Real AMD installers MAY contain executable container layers that 7-Zip alone cannot directly recurse into. The tool SHALL recognize supported static inner-container formats without executing them.

For observed AMD 3.x through 8.x packages, the implementation SHALL support InstallShield `ISSetupStream` types 3 and 4 sufficiently to recover embedded files such as `AMD_Chipset_Drivers.msi`. Recovered MSI/CAB/ZIP/7z containers SHALL re-enter the bounded 7-Zip recursion pipeline. Historical ZIP delivery artifacts MAY wrap a recognizable AMD outer installer EXE; such known AMD EXE containers SHALL also re-enter static 7-Zip recursion without execution so analysis can continue to the inner InstallShield/MSI/CAB/INF layers.

The implementation SHALL validate recovered MSI artifacts using the CFBF/OLE MSI signature before treating recovery as successful.

A release SHALL NOT be classified `ExtractionComplete` merely because the outer NSIS container was expanded. `ExtractionComplete` requires actual INF discovery. Zero-INF results SHALL be represented as an explicit partial/incomplete state unless absence of driver packages is independently proven.

The ISSetupStream decoder MAY be implemented in embedded C# compiled at runtime from the single PowerShell entry script. This does not violate the one-PowerShell-script rule. Third-party algorithms or source-informed implementations SHALL retain required attribution/license notices.

## 18. Embedded AMD metadata

The `Inspect` stage SHALL preserve structured metadata from embedded AMD XML sources when present.

`Info.xml` evidence SHOULD capture source path/SHA-256 and product records including component name, OS, component version, installer, brand and release flag.

`DevID.xml` evidence SHOULD capture source path/SHA-256, installer tag, raw device-ID string and normalized device-ID list.

When multiple copies exist, all source records SHALL remain available while one preferred source MAY be selected deterministically for canonical summary fields. Embedded metadata SHALL remain distinct from AMD published release-note metadata and actual INF/payload observations so later comparison can expose disagreement rather than overwrite it.

## 19. Evidence retention for iterative review

The evidence ZIP SHALL be designed to be uploaded to a reviewer or analysis system without requiring the entire extracted working tree. It SHOULD remain compact while retaining enough provenance to reproduce or diagnose each stage. The ZIP SHOULD include the exact executing tool snapshot and documentation snapshot so later review can identify the code revision that produced the evidence.

ZIP entry names SHALL use the ZIP-standard forward slash (`/`) separator regardless of the host OS. A Windows-generated evidence bundle SHALL be consumable by common Linux ZIP tools without backslash-path warnings or avoidable non-zero exit status.

## 20. Operator-facing logging and timing contract

The toolkit SHALL provide enough live progress information for an operator to understand what is being processed during long research runs without opening the generated JSON files.

Normal activity lines SHOULD use a stable shape containing local wall-clock time, elapsed time within the current stage, a compact severity/progress marker, and the message. The marker vocabulary SHALL distinguish at least normal progress, success, review/warning, failure, and informational fallback/skip conditions.

Every selected stage SHALL print a clear start header and completion footer. The completion footer SHALL include stage status and elapsed time. Long-running release-oriented stages SHALL report the release index/total, release version, and a concise per-release completion/failure message. Acquisition SHOULD include artifact size/candidate information; extraction and inspection SHOULD include useful result counts.

Evidence finalization SHALL emit a final timing summary containing total elapsed time plus a per-stage status/duration table. The console transcript SHALL contain this summary, and equivalent structured timing data SHALL be persisted in the run summary evidence.

Expected probe failures such as candidate HTTP 404 responses, retired URLs, or a sitemap endpoint returning HTML instead of XML SHALL be represented as controlled diagnostics/structured evidence. They SHALL NOT intentionally generate raw PowerShell terminating-error records merely as part of normal fallback probing, especially under Windows PowerShell 5.1 `Start-Transcript`.

## 20. Repository-committed accepted baseline

The repository MAY carry an accepted, reviewable inventory snapshot under `inventory/accepted-baseline/`.

The accepted baseline SHALL:

- preserve the original generating toolkit version and generation timestamp as provenance;
- record the source Evidence ZIP SHA-256;
- normalize machine-local absolute paths to repository-relative logical paths before commit;
- exclude AMD installer binaries, raw extraction trees, console transcripts, and raw release-note HTML;
- remain research data only and SHALL NOT encode Windows Server compatibility policy;
- be regenerated or superseded when a newer full acceptance run is intentionally adopted.
