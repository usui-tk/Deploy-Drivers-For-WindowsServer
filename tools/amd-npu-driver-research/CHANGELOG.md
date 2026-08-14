# Changelog

## 1.0.0 — 2026-08-14

Stable-version release candidate prepared after independent Audit #3 APPROVE; main-toolkit v1.0.0 qualification is complete and Audit #4 is pending.

- Deliberately promoted the main research toolkit from `0.9.1-dev` to the final stable version string `1.0.0`; no `1.0.0-dev` or post-1.0 interim version is used.
- Added a Test-stage consistency guard requiring the `.NOTES` `Tool version:` declaration to match `$script:ToolVersion`.
- Corrected stale README/TESTING/CHANGELOG qualification text: 0.9.1-dev did complete Windows PowerShell 5.1 qualification on its exact shipped script hash.
- Regenerated `public/**` from the actual v1.0.0 source using the canonical reviewed public corpus; 13/13 Linux/PowerShell 7.6.4 stages PASS, exit 0.
- The v1.0.0 version-only regeneration preserves dataset invariants (112 processors / 336 matrix rows / 112 selections / 112 applicability rows / 62 selected / 22 no-driver / 28 `ReviewRequired`).
- Diff against 0.9.1-dev is the expected hash cascade: 12 JSON files change and all 11 generated Markdown files remain byte-identical.
- Completed fresh automatic AMD vendor re-acquisition on Windows PowerShell 5.1 using the exact v1.0.0 script: 13/13 stages PASS, exit 0, with all three reviewed public artifacts recorded as `Downloaded` and matching the reviewed hashes.
- Completed final v1.0.0 Windows/Linux publication comparison: 23/23 files byte-identical, with manifest/source binding preserved.
- Final independent Audit #4 remains pending before repository release acceptance.

## 0.9.1-dev — 2026-08-14

Independent-audit remediation before v1.0.0.

- Fixed stage dependency evaluation so prerequisites absent from a partial `-Stages` run are treated as unmet and dependent stages report `BLOCKED` instead of raw exceptions or vacuous PASS results (audit A-01).
- Added explicit source-data contracts for all 12 reviewed `data/*.json` files, with expected `schemaVersion` guards and matching Draft 2020-12 schemas under `schemas/source-data/**` (audit A-03).
- Test stage now rejects unregistered reviewed data files, missing source schemas, mismatched source schema versions, and schemas that do not guard their declared `schemaVersion`.
- Prepared and validated the repository-root `.gitattributes` NPU public-surface verbatim rule required by audit A-02. Audit #3 assigned the final one-line integration to the repository side; the v1.0.0 toolkit commit candidate therefore excludes `.gitattributes`.
- Linux / PowerShell 7.6.4 full replay after remediation: 13/13 PASS, exit 0; 336 matrix rows / 112 selections / 112 applicability rows / 28 `ReviewRequired`.
- Added partial-stage regression coverage for `Compare`, `DriverBinary`, `Matrix`, and `Build`; all now fail closed as `BLOCKED` / exit 2 when prerequisites were not selected.
- Windows PowerShell 5.1 qualification for the exact 0.9.1-dev script subsequently completed successfully (13/13 PASS, exit 0, exact script hash). That evidence remains pre-release-only; final v1.0.0 evidence must be reacquired/regenerated with the actual v1.0.0 source.

## 0.9.0-dev — 2026-08-14

Exact-SKU processor/NPU → driver applicability expansion.

- Expanded the reviewed processor catalog from 16 selections to 112 exact AMD processor SKUs using AMD exact-SKU product tables/configuration evidence; retained fail-closed matching and explicit negative controls.
- Added `data/processor-driver-applicability.json` and `schemas/processor-driver-applicability.schema.json`.
- Added generated `public/catalog/processor-driver-applicability.{json,md}` with exact CPU/NPU identity, per-release applicability, recommendation decision, provenance and explicit Windows Server runtime-proof state.
- Added private qualification knowledge for `NPU_RAI1.6.1_314_WHQL.zip` pinned by SHA-256. The restricted artifact remains manual/private only, is excluded from automatic acquisition, and can never be recommended.
- Expanded Ryzen AI 400 / PRO 400 Gorgon Point coverage while keeping those processors `ReviewRequired` for the current reviewed 376 support corpus. Added Ryzen AI Max PRO 400 / Gorgon Halo exact SKUs as `ReviewRequired` until the exact PCI NPU identity is reviewed.
- Extended public cross-dataset validation to bind applicability decisions back to compatibility-matrix selections and reject private recommendations, Server runtime-proof leakage, and malformed observed-evidence arrays.
- Fixed two feature-development regressions found by Full replay: scalar/empty-array handling under `Set-StrictMode`, and an accidental `$PID` automatic-variable collision in the new validator.
- Development Full replay on Linux/PowerShell 7 passes all 13 stages with 336 matrix rows / 112 selections / 112 applicability rows / 28 `ReviewRequired` selections.
- User Windows PowerShell 5.1 full live-acquisition qualification passes all 13 stages with exit code 0 using the same source SHA-256; generated dataset counts match Linux.
- Cross-runtime release check compares the accepted Windows and Linux `public/**` trees and finds 23/23 files byte-identical.
- Reorganized README/SPEC/TESTING/reverse-engineering/source/collector documentation so NPU identity layers, Server build-floor/installer findings, exact-SKU recommendation semantics, runtime-evidence boundaries, and deployment-script feedback are retained as first-class project knowledge.

## 0.8.1-dev — 2026-08-13

Static-analysis hardening after external source review #1.

- Fixed `-PublicOutputRoot` being silently discarded by separating the caller parameter from the resolved script-state variable (`ResolvedPublicOutputRoot`).
- Added a pure `Resolve-NpuPublicOutputRootPath` resolver and a Test-stage regression probe for explicit public-output paths.
- Removed dynamic-scope dependency on top-level script parameters from NPU stage/orchestration functions by passing all required values explicitly.
- Updated `Write-AmdAssessmentConsoleReport` to receive `SkipPublicExport` explicitly and refreshed its architecture-convergence hash contract.
- Preserved the reviewed PSA2011 false-positive sites and predecessor/shared helper conventions unchanged.
- Kept PowerShell source encoding at UTF-8 with BOM + CRLF.

## 0.8.0-dev — 2026-08-13

- Promoted reviewed Ryzen AI Z2 Extreme client-runtime observations into a new `data/observed-runtime-evidence.json` source layer; raw collector archives, transcripts, INF snapshots, and host-specific diagnostics remain private runtime/non-commit evidence.
- Resolved Ryzen AI Z2 Extreme from an unresolved NPU identity to reviewed Strix Point / `amd-npu-aie2p-17f0` using correlated evidence: CPU Family 26 / Model 36 / Stepping 0, `DEV_17F0 / REV_10`, AMD quicktest-style `STX`, XRT `NPU Strix`, and the Radeon 890M `ati2mtag_Strix` INF correlation.
- Recorded XRT firmware version `1.1.2.64` separately from the still-unresolved firmware device-revision namespace (STXA/STXB).
- Recorded exact public-376 component correlation for the observed client stack: installed NPU INF, `ipustack.sys`, and `xrt-smi.exe` hashes match the reviewed `NPU_RAI_376_WHQL.zip` components. This is client runtime evidence and MUST NOT be treated as Windows Server runtime proof.
- Added `schemas/observed-runtime-evidence.schema.json` and generated `public/catalog/observed-runtime-evidence.{json,md}`.
- Extended hardware identities, processor catalog, and driver compatibility matrix with observed-runtime references. Ryzen AI Z2 Extreme now selects `NPU_RAI_376_WHQL.zip` as the latest published static candidate with `ExactArtifactRuntimeObserved`; the current selection set has one remaining `ReviewRequired` processor (Gorgon Point).
- Collector advanced to 1.2.1: structured XRT normalization separates XRT host metadata, XRT build, NPU driver records, and NPU device records; installed-INF model-section evidence is correlated to PnP HWIDs; exact reviewed 376 stack correlation is emitted; raw XRT hostname presence is declared explicitly in private-evidence metadata.
- Development qualification: two full three-package 13-stage replays PASS and produce byte-identical `public/**`; standalone validation and schema checks PASS.

## 0.7.1-dev — 2026-08-13

- Qualified the 0.7.0-dev no-argument workflow on a real Japanese Windows PowerShell 5.1 host: all 13 stages PASS, all three reviewed AMD artifacts downloaded from the live AMD CDN, shared 7-Zip extraction PASS, publication PASS, exit 0, and a hash-valid Evidence ZIP was produced.
- Audited the Windows-generated `public/**` against the Linux/PowerShell 7 output and found two release-blocking cross-runtime determinism defects that the per-host validator could not detect: UTF-8 no-BOM reviewed JSON was decoded through the Windows ANSI code page, and JSON escaping / collection ordering depended on PowerShell runtime and culture.
- Replaced reviewed JSON loading paths that used `Get-Content` with explicit text readers so UTF-8 no-BOM source data is decoded consistently on Windows PowerShell 5.1 and PowerShell 7. This prevents the processor-catalog `™` token from becoming mojibake such as `邃｢`.
- Added a runtime-independent canonical JSON serializer for publication/evidence JSON. It emits required JSON escapes only, preserves valid Unicode, uses invariant numeric formatting, and no longer inherits PowerShell 5.1 `ConvertTo-Json` HTML escaping such as `\u0026` / `\u003e`.
- Added ordinal string sorting helpers and applied them to publication-visible file paths, INF-derived sets, comparison paths, discovery/acquisition sets, and deterministic tie-breaks. This removes OS/culture-dependent `Sort-Object` ordering from canonical public output.
- Expanded the executable architecture-convergence contract from 23 to 27 generic kernel functions so canonical JSON and ordinal ordering helpers are hash-pinned by the `Test` stage.
- Development regression after the fix: two 13-stage three-package Linux/PowerShell 7 full replays PASS and produce byte-identical `public/**`; standalone Validate PASS; all 10 schemas self-validate; 14/14 applicable documents validate against Draft 2020-12 schemas.
- Release gate added: the same exact 0.7.1 source and reviewed artifact corpus must be rerun on Windows PowerShell 5.1 and compared byte-for-byte with the Linux/PowerShell 7 `public/**` tree before release candidacy.

## 0.7.0-dev — 2026-08-13

- Replaced NPU-specific runner/evidence infrastructure with an architecture-converged generic kernel.
- Removed legacy `Start-NpuEvidenceSession`, `Invoke-NpuTrackedStage`, `Get-NpuRunAssessment`, `Finalize-NpuEvidenceSession` and related NPU infrastructure functions.
- Added generic stage runner, assessment/reporting, Evidence lifecycle, emergency Evidence bootstrap, publication validation/promotion, requested-stage parsing, acquisition kernel and extraction kernel.
- Reduced NPU-specific responsibilities to adapters and NPU research semantics.
- Added decoded-JSON privacy checks and compact-public-JSON validation modeled after the mature Graphics publication contract.
- Added `data/architecture-convergence-contract.json` plus Schema; the Test stage validates 23 generic-kernel hashes, forbids legacy NPU infrastructure, and requires the NPU adapter boundary.
- Retained all 41 exact-common predecessor functions and the reviewed Graphics 7-Zip probe/qualification contract.
- Development qualification: 13-stage three-package local replay PASS; second replay byte-identical under `public/**`; ordinary failure Evidence PASS; BootstrapFatal fallback Evidence PASS.


## 0.6.0-dev — 2026-08-13

- Re-audited the current chipset and graphics research scripts at implementation level rather than feature-list level. The two predecessors expose a real shared infrastructure core; NPU now imports 34 generic definitions unchanged after line-ending normalization for platform, TLS/HTTP, host validation, hashing, path, ZIP, archive-probe, logging, and related infrastructure.
- Added `ARCHITECTURE-PARITY.md`, `data/predecessor-shared-core-contract.json`, its schema, and an executable AST/function-hash `Test-NpuPredecessorParityContract` release gate.
- Reworked the default workflow into 13 explicit stages and added first-class `Metadata`, `Extract`, and `Inspect` stages. Legacy `Analyze` maps to `Extract` + `Inspect`.
- Added predecessor-style `-PublicOutputRoot`, canonical `-SkipPublicExport` (`-SkipPublic` alias), and canonical `-Force` (`-ForceDownload` alias).
- Reworked discovery to use the shared predecessor HTTP stack, multiple `-DocumentationUri` sources, and optional `-AdditionalDriverUrl`; reviewed artifacts remain available when live documentation fetch is unavailable.
- Added `inventory/release-metadata.json` so discovery and acquisition are explicitly separated.
- Reworked acquisition to use the shared HTTP/download primitives with `.partial` atomic download, retry, reviewed size/SHA-256 validation, and cache reuse.
- Moved evidence establishment ahead of work-root initialization; retained and tested NPU's emergency `BootstrapFatal` evidence path as additional hardening beyond the predecessor baseline.
- Added shared evidence archive capability probing and expanded evidence snapshots to include tool/data/schema inputs while keeping vendor packages excluded by default.
- Development qualification: 13-stage three-package replay PASS, controlled automatic download PASS, offline cache reuse PASS, `-Mode Validate` PASS, ordinary failure Evidence ZIP hash-valid, and synthetic bootstrap failure Evidence ZIP generated.


## 0.4.1-dev — 2026-08-13

- Fixed Windows PowerShell 5.1 startup failure when `System.Runtime.InteropServices.RuntimeInformation.OSArchitecture` is unavailable on the loaded .NET Framework runtime.
- Replaced direct optional `RuntimeInformation` static-property dereferences with reflection-based, fail-soft platform probing and fallbacks to processor environment variables, `Win32_OperatingSystem`, and `Environment.Is64BitOperatingSystem`.
- Added a platform-probe self-test that verifies a deliberately missing `RuntimeInformation` property is handled as `null` instead of raising a parser/runtime failure.
- Added emergency evidence bootstrap: if normal evidence-session initialization fails before an evidence context exists, the runner attempts a minimal `BootstrapFatal` evidence directory/ZIP and records the original fatal exception.
- Hardened PowerShell-edition discovery so runner bootstrap does not depend on direct optional-property access under `Set-StrictMode`.
- Added a release-blocking regression requirement that FatalError during runner bootstrap must still produce evidence whenever any configured/fallback evidence directory is writable.

## 0.4.0-dev — 2026-08-13
- Align process exit codes with predecessor runners: 0=Pass, 2=ReviewRequired, 1=FatalError/finalization failure.
- Finalize transcript before hashing evidence, then verify/archive `evidence-manifest.json`; failure runs retain diagnostic ZIPs.
- Add reviewed acquisition-catalog schema and download/cache/hash qualification.

- Reworked the NPU research entry point to match the staged execution/evidence contract already established by the chipset and graphics research tools.
- Changed the no-argument default from "require a pre-supplied ZIP" to automatic AMD publication discovery/acquisition followed by full static research.
- Added reviewed `data/published-driver-artifacts.json` for Ryzen AI 1.5 280, later 280, and 376 direct AMD ZIPs with exact SHA-256/size contracts.
- Added best-effort current AMD documentation discovery; newly observed unknown artifacts may be downloaded for research but cannot inherit known exact-hash support contracts.
- Added cache integrity checking, retry/timeout handling, default AMD-host allowlisting, `-ForceDownload`, and `-ArtifactId` selection.
- Added top-level evidence-session initialization, per-stage PASS/FAIL/BLOCKED tracking, transcript/error capture, final assessment, evidence manifest, and Evidence ZIP finalization from `finally`, including failure runs.
- Added run-scoped public staging and validate-before-promotion behavior so failed generation/validation preserves the prior `public/**` baseline.
- Restored the root `.ps1` source contract to UTF-8 with BOM + CRLF for Windows PowerShell 5.1 parity with the predecessor research tools; generated public files remain UTF-8 no-BOM/LF.
- Retained `-PackagePath` as an explicit local/offline replay path and retained legacy `-Mode` as a compatibility shim; `-Stages` is now canonical.
- Added `.gitignore` rules so downloaded `inventory/**`, `private/**` evidence, `work/**`, and runtime `reports/**` do not become accidental commit surface.


## 0.3.1-dev — 2026-08-13

- Fixed a Windows PowerShell 5.1 parser failure caused by literal non-ASCII Markdown glyphs (`U+2014` and `U+2192`) embedded in a UTF-8 no-BOM `.ps1` source file.
- Made the root research script source ASCII-only while preserving generated Markdown glyphs through runtime `[char]` construction.
- Added a source-byte compatibility gate so PowerShell 7/Linux qualification fails if future root-script edits reintroduce non-ASCII bytes that Windows PowerShell 5.1 could decode through the active ANSI code page.
- Added a regression requirement to emulate the Windows PowerShell 5.1 no-BOM decoding hazard during release qualification.
- Made package-input ordering deterministic by artifact filename before cross-release comparison generation, preventing comparison direction/filename churn from filesystem enumeration order.

## 0.3.0-dev — 2026-08-13

- Added exact-hash static contracts for `ipustack.sys` 280 and 376.
- Recovered 376 firmware device-revision refinement: STXA/STXB/KRK1/KRK2/HALO/GPT1/GPT2/GPT3 values 1..8, with unknown initialized to 9.
- Recorded the dedicated 376 `0x117` command primitive and its numeric/semantic correlation with upstream amdxdna `MSG_OP_GET_DEV_REVISION`.
- Added `DriverBinaryStaticAnalysis`, release `DriverBinaries`, and driver-binary comparison semantics.
- Added `DriverBinaryCodenameStatus` to the CPU/package compatibility matrix without weakening the independent AMD published-support gate.
- Preserved Gorgon Point as `ReviewRequired`: binary recognition is technical evidence, not vendor publication evidence.
- Wrapped top-level execution in `Invoke-AmdNpuResearchMain` and pinned publication provenance to `$PSCommandPath`; this removes an observed PowerShell startup/compilation performance pathology while preserving the single-file root tool.

## Unreleased — companion hardware-evidence tool

- Updated `Collect-AmdNpuHardwareIdentityEvidence.ps1` to tool version 1.2.0.
- Added best-effort discovery of AMD `xrt-smi.exe`, prioritizing `C:\Windows\System32\AMD`, and collect executable/runtime-directory hash/version/signature metadata.
- Added read-only `xrt-smi --version`, `xrt-smi examine -f JSON -o ...`, and plain `xrt-smi examine` probes with timeout/error isolation. The collector never invokes `validate` or `configure`.
- Added raw and normalized XRT evidence for firmware version, device name, BDF, driver/XRT version and readiness/status fields while preserving the distinction between firmware version and firmware-reported device revision.
- Added reviewed quicktest-style PCI revision classification recovered from AMD `quicktest.py`: `1502/REV_00 -> PHX/HPT`, `17F0/REV_00/10/11 -> STX`, `17F0/REV_20 -> KRK`. This remains a PCI-revision classification plane, not the `0x117` firmware device-revision namespace.
- Added `quicktest.py` discovery/hash and optional private snapshot; the collector never executes Python or inference.
- Added PnP quicktest-classification versus XRT device-name/firmware/BDF cross-source evidence.
- Classified collector output explicitly as private runtime/non-commit evidence and documented that PowerShell transcript headers may contain shell user/computer identity metadata.
- Replaced normal Evidence ZIP creation with a canonical `.NET ZipArchive` writer using forward-slash entry names; `Compress-Archive` is fallback only.

- Updated `Collect-AmdNpuHardwareIdentityEvidence.ps1` to tool version 1.1.1.
- Fixed Windows PowerShell 5.1 recursive evidence-manifest failure caused by attempting to cast the two-character string `\\` to `System.Char` while normalizing nested `driver-inf/` paths.
- Replaced the fragile `TrimStart([char[]]...)` expression with explicit separator-safe relative-path normalization.
- Added top-level collector exception handling, `collector-status.json`, transcript preservation, `errors/collector-error.txt`, fail-safe recursive manifest generation, and best-effort ZIP finalization.
- Added an independent `.NET System.IO.Compression.ZipFile` fallback if `Compress-Archive` fails, and retain the evidence directory on failed runs.
- Reviewed the failed Ryzen AI Z2 Extreme 1.1.0 run: platform collection itself reached the finalization phase and retained CPU/NPU/GPU/firmware/INF evidence; the observed failure was limited to manifest path normalization.

- Updated `Collect-AmdNpuHardwareIdentityEvidence.ps1` to tool version 1.1.0 and broadened its evidence model from CPU/NPU-only emphasis to whole AMD platform correlation for laptops and handheld PCs.
- Added AMD GPU / PCI `VEN_1002` coverage alongside `VEN_1022`, GPU evidence from `Win32_VideoController`, and role-tagged AMD platform PnP inventory.
- Added platform firmware-class PnP inventory, device parent/location topology, full non-sensitive PnP-property snapshots, installed INF snapshots with SHA-256 manifests, and service-driver binary metadata.
- Added broader SetupAPI platform slices while retaining the bounded NPU-specific filter and focused `pnputil` output for NPU/GPU candidates.
- Changed the evidence manifest to recurse into nested evidence directories such as `driver-inf/`.
- Added PnP property privacy filtering for serial/network-address property keys.
- Qualified collector 1.0.3 on the Ryzen AI Z2 Extreme positive-control host before this expansion: CPU Family 26 / Model 36 / Stepping 0 and NPU `VEN_1022&DEV_17F0&SUBSYS_20CF1043&REV_10` were observed, while firmware device revision remained unresolved through standard PnP properties.

- Updated `Collect-AmdNpuHardwareIdentityEvidence.ps1` to tool version 1.0.3.
- Corrected revision-layer classification after Ryzen AI Z2 Extreme positive-control evidence showed that `DEVPKEY_PciDevice_ExpressSpecVersion = 2` had been incorrectly treated as firmware-revision evidence.
- Added structured per-candidate `RevisionEvidence` that separates PCI `REV_XX`, PCIe specification version, explicit firmware/NPU device-revision properties, and unrelated revision/version properties.
- Added `npu-revision-evidence-summary.txt` to the evidence ZIP.
- Added architectural CPU Family/Model/Stepping extraction while preserving `Win32_Processor.Family` and `Revision` separately as WMI classification values.
- Recorded the Ryzen AI Z2 Extreme positive-control observation: CPU Family 26 / Model 36 / Stepping 0, NPU `VEN_1022&DEV_17F0&REV_10`, service `IpuMcdmDriver`, and installed AMD driver `32.0.20101.3760`; firmware device revision remains unresolved by standard collected PnP properties.

- Updated `Collect-AmdNpuHardwareIdentityEvidence.ps1` to tool version 1.0.2.
- Validated tool 1.0.1 on a real non-NPU AMD Ryzen 7 5700X Windows host: collection completed, 36 AMD PCI devices were retained, and NPU candidate count was correctly zero.
- Fixed SetupAPI false positives caused by broad `AMD.*NPU` / `AMD.*IPU` expressions matching `amd64_..._input...` / `xinput...` paths.
- Added processor-class PnP identity grouping so exact CPU name/service/hardware IDs/compatible IDs can become observed CPU-catalog evidence.
- Added read-only `amdppm.sys` file version, SHA-256, product metadata, and Authenticode signer/status collection.
- Preloaded PnP and signed-driver inventories once per run rather than issuing a full `Win32_PnPSignedDriver` scan for each AMD PCI device.
- Changed the firmware-revision result for hosts with no NPU candidate from `NotExposed...` to the more accurate `NoNpuCandidateObserved`.

- Updated `Collect-AmdNpuHardwareIdentityEvidence.ps1` to tool version 1.0.1.
- Fixed Windows PowerShell 5.1 runtime failure when CIM date properties such as `Win32_BIOS.ReleaseDate` are already returned as `System.DateTime` rather than DMTF text.
- Added defensive date normalization for BIOS and signed-driver dates; unexpected provider-specific values are retained as raw evidence instead of aborting collection.
- Added the repository-tracked companion tool `tools/amd-npu-driver-research/tools/Collect-AmdNpuHardwareIdentityEvidence.ps1` (tool version 1.0.0).
- Kept the main `amd-npu-driver-research` implementation at 0.2.1-dev and its primary entry point single-file by placing runtime hardware evidence collection under the toolkit-local `tools/` directory.
- Added a privacy-minimized, read-only Windows hardware probe for exact CPU identity, AMD PCI/NPU HWIDs, PCI `VEN/DEV/SUBSYS/REV`, PnP properties, installed driver/INF/signer metadata, `pnputil`, and relevant SetupAPI evidence.
- Added repository documentation that runtime evidence from Ryzen AI Z2 Extreme should be reviewed before resolving its current `ReviewRequired` hardware identity.

## 0.2.1-dev — 2026-08-13

- Added AMD Ryzen Z-series handheld processor catalog coverage.
- Added `npuAvailability` and reviewed negative-control semantics.
- Added AMD Ryzen AI Z2 Extreme as an NPU-positive exact SKU with unresolved NPU identity; automatic driver selection is intentionally blocked with `ReviewRequired`.
- Added Ryzen Z2 Extreme / Z2 explicit Ryzen AI negative controls and Z2 Go / Z2 A / Z1 Extreme / Z1 no-published-NPU controls.
- Expanded the three-package matrix from 27 to 48 rows and from 9 to 16 processor selections.
- Added `NotApplicableNoPublishedNpu` and `NoNpuDriverRequired` decisions so similar architecture cannot imply NPU applicability.

## 0.2.0-dev — 2026-08-13

Added machine-readable CPU/NPU identity and driver-selection research.

- Added reviewed `data/hardware-identities.json` with 1502/AIE2 and 17F0/AIE2P broad identities, AMD PCI-revision hints, and Linux `amdxdna` firmware-revision refinement for Strix/Krackan/Strix Halo/Gorgon Point.
- Added `data/processor-catalog.json`, an exact-SKU seed catalog with nine AMD processors spanning Phoenix, Hawk Point, Strix Point, Krackan Point, Strix Halo, and Gorgon Point. Unknown CPU names are `ReviewRequired`; broad series inference is prohibited.
- Added exact-artifact `data/driver-compatibility-rules.json` and separated AMD published driver labels from embedded INF `DriverVer` values.
- Added `HardwareIdentity`, `ProcessorCatalog`, and `DriverCompatibilityMatrix` stages.
- Added generated `public/catalog/` JSON/Markdown for hardware identities, processor catalog, and driver compatibility matrix.
- Added latest-static-candidate selection that only ranks rows already supported by reviewed AMD codename evidence and Server/static package gates.
- Current matrix selects 376 for reviewed Phoenix/Hawk Point/Strix Point/Krackan Point/Strix Halo SKUs and deliberately returns `ReviewRequired` for reviewed Gorgon Point.
- Added three JSON Schemas for the new public catalog/matrix outputs and extended the release schema with `PublishedCompatibility`.
- Added canonical-name resolver self-tests and reviewed-data referential-integrity checks.

## 0.1.1-dev — 2026-08-13

Expanded the historical release corpus and made installer routing semantics explicit across distinct binaries.

- Added `NPU_RAI1.5_280_WHQL.zip` as a reviewed historical analysis target.
- Added the historical installer exact-SHA contract for `70259d1d...66016`.
- Recorded that the historical and later installer binaries are different PE files but expose the same recovered device matcher and OS-routing thresholds.
- Added `InstallerRoutingRelationship` so cross-release reports distinguish byte identity from same recovered routing semantics.
- Added three-way release generation/comparison coverage for Ryzen AI 1.5 280, later 280, and 376.
- Documented the unusually strong payload relationship between the two 280 artifacts: 145/146 common files are byte-identical; only the installer differs, while the later 280 additionally contains the EULA PDF.

## 0.1.0-dev — 2026-08-13

Initial NPU research-tool preview.

- Added safe static ZIP extraction and full file SHA-256 inventory.
- Added INF section parsing, TargetOSVersion parser, HWID extraction, service/dependency extraction, and WDF-directive observation.
- Added Windows Server 2016/2019/2022/2025 static selector projection.
- Added exact-SHA installer contract for the byte-identical installer found in NPU_RAI_280_WHQL and NPU_RAI_376_WHQL.
- Added installer route/payload-presence analysis.
- Added combined INF + installer Windows Server assessment.
- Added release-to-release byte comparison.
- Added generated public JSON/Markdown and publication manifest.
- Added UTF-8 no-BOM/LF validation, JSON parsing checks, public allowlist/hash/length/source-hash verification, and `HandEdited=false` enforcement.
- Added release, comparison, and publication-manifest JSON schemas.
- Documented initial reverse engineering and the correction to the prior ProductType=1 hypothesis.
