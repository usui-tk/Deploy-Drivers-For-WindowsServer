# AMD Chipset Driver Research Toolkit Testing Guide

## REV81 release-state and no-rerun decision

Claude closed Cycle B at REV80. The exact REV77 Chipset source is the current
`3.0.0` source and its Windows Server / Windows PowerShell 5.1
`PathSafety,Test` gate is accepted/no-repeat at 2/2 PASS, exit `0`, manifest
52/52 exact. Gate 2C and the generated 68-file public surface are also
accepted. REV81 is documentation-only and requires no Windows Client or Server
rerun. Lower revision commands are retained as historical reproducibility
records, not current operator actions.

## REV78 no-repeat decision

The exact REV77 Chipset Server smoke is accepted. Its source is byte-identical
in REV78, so another user run would be ceremonial and is not requested. Only
the NPU Test gate is affected by the REV78 contract-data correction.

## REV77 exact-source retest

Use Windows PowerShell 5.1 explicitly and keep the canonical path unchanged:

```powershell
& "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe" `
  -NoProfile -ExecutionPolicy Bypass `
  -File 'D:\Temp_AMD-Tool\Deploy-Drivers-For-WindowsServer\tools\amd-chipset-driver-research\Invoke-AmdChipsetDriverResearch.ps1' `
  -Stages PathSafety,Test `
  -SkipPublicExport `
  -EvidenceLabel 'REV77-CycleB-WindowsServer-Chipset-ExecutionContext' `
  -EvidenceRetention ZipOnly
```

In addition to the existing 2/2 PASS, exit `0`, manifest, and diagnostic
criteria, `run-context.json` must report `PSEdition=Desktop`, Windows PowerShell
5.1, `ExecutionContext.ExecutionClass=WindowsServer`, `ProductType` 2 or 3,
`CollectionStatus=Collected`, and `CollectionSource=Win32_OperatingSystem`.

## REV76 historical release gate

Chipset Gate 2C is accepted/no-repeat. The generated public tree and the exact
`3.0.0` root source are frozen. The remaining Windows Server gate is one direct
common-contract smoke from the existing canonical root:

```powershell
Set-Location 'D:\Temp_AMD-Tool\Deploy-Drivers-For-WindowsServer\tools\amd-chipset-driver-research'
.\Invoke-AmdChipsetDriverResearch.ps1 `
  -Stages PathSafety,Test `
  -SkipPublicExport `
  -EvidenceLabel 'REV76-CycleB-WindowsServer-Chipset-Smoke' `
  -EvidenceRetention ZipOnly
```

PASS requires 2/2 stages, exit code `0`, Windows PowerShell 5.1 on Windows
Server, an exact Evidence manifest, and zero Warning/Error diagnostic events.
AMD chipset presence is not required for these static/common stages. Absence
does not prove `NoChipsetDriverRequired`, and this gate does not exercise
acquisition, installation, load or post-install behavior. See the umbrella
REV76 Server gate document for the cross-tool boundary. No launcher is included.

## REV70 hardware-aware scope and transcript-hygiene gate

The tool version remains `3.0.0`. REV70 changes only the shared negative
extraction-completeness self-test path: the ordinary runtime assertion still
throws and blocks incomplete extraction, while the deliberate negative fixture
returns a structured `Blocked` result so Windows PowerShell 5.1 does not record
an expected caught terminating error.

Hardware presence has the following meaning for this tool:

- `PathSafety,Test` is valid on a Windows Client with or without an AMD chipset,
  AMD graphics adapter or AMD NPU.
- package discovery, download, extraction, INF/signature/selector analysis and
  public generation are static research operations; an installed AMD chipset is
  not required for those operations.
- on Windows, an `All` run includes `HostSurvey,HostMatch` unless
  `-SkipHostAnalysis` is specified. An AMD-chipset host gives positive local
  host-correlation evidence. A non-AMD host must not be described as proving
  `NoChipsetDriverRequired`; the toolkit has no such decision contract.
- no run installs a chipset package or proves a chipset device's post-install
  operation.

The minimum direct regression remains:

```powershell
.\Invoke-AmdChipsetDriverResearch.ps1 `
  -Stages PathSafety,Test `
  -SkipPublicExport `
  -EvidenceLabel REV70-Chipset-Common-Transcript `
  -EvidenceRetention ZipOnly
```

PASS requires 2/2 stages, exit code `0`, a valid Evidence ZIP/manifest, and no
transcript terminating-error record for the deliberate `ExtractedWithErrors`
path-safety fixture. This standalone run is not required before the Cycle B
full run when the same exact source's full run will execute `Test` and be
reviewed. See
`project-management/CYCLE-B-HARDWARE-AWARE-TEST-MATRIX-REV70.md` for the
cross-tool host profiles and execution order.

## Current accepted gate and retest rule

The prior exact `2.1.17` source has an accepted Windows Server 2025 / Windows
PowerShell `5.1.26100.33296` smoke result: `PathSafety,Test`, 2/2 PASS, final
`Pass`, exit code `0`, with an independently verified Evidence ZIP and manifest.
It is a regression reference, not qualification of the changed `3.0.0` source.

This is a smoke gate only. Full discovery, download, extraction, inspection,
signature analysis, selector analysis, Build/publication and deployment/runtime
behavior were not exercised by that run. Documentation-only changes do not
invalidate the accepted executable evidence and SHALL NOT trigger a ceremonial
rerun. Historical revision gates below are retained regression fixtures; they
become active only when impact analysis reaches the corresponding behavior.

For the historical REV69 `3.0.0` Cycle B candidate, the minimum direct smoke
command was:

```powershell
.\Invoke-AmdChipsetDriverResearch.ps1 `
  -Stages PathSafety,Test `
  -SkipPublicExport
```

There is no release-included cross-tool test launcher.

## REV69 Cycle B qualification and regeneration gate

The exact `3.0.0` source SHALL parse without error, declare
`#requires -Version 5.1`, pass UTF-8 BOM + CRLF checks, and pass
`PathSafety,Test` with the repinned common-core contract. On a short-path
Windows Client workspace, the full regeneration command is:

```powershell
.\Invoke-AmdChipsetDriverResearch.ps1 `
  -EvidenceLabel REV69-CycleB-Chipset-WindowsClient `
  -EvidenceRetention ZipOnly
```

Omitting `-Stages` deliberately selects `All`. Do not add `-SkipPublicExport`.
Acceptance requires final `Pass`, exit code `0`, a verified Evidence ZIP and
manifest, and a complete newly generated `public/**` tree that passes schema,
canonical-byte, privacy and provenance validation. Do not run a Windows Server
gate until the Windows Client evidence is reviewed and separately authorized.

## Rev59 publication-path regression gate

The REV58 Windows evidence is the causal fixture. It SHALL show 538 distinct runtime `ArchivePath` scalars reported once in per-release JSON and once in `inventory/extraction.json` for 1,076 total errors. The corrected converter SHALL process all 25 containers in release `8.08.12.551`, retain 25 portable archive identities, and leave zero forbidden runtime-root scalars. `PathSafety,Test` and the 165-function common contract SHALL pass before another Windows full run is requested.

## Rev58 path-safety correction gate

The common Test stage SHALL prove the short-path constructor and both positive and negative extraction-completeness cases. Chipset, Graphics and NPU SHALL each pass `PathSafety,Test`, the 162-function common contract, PowerShell AST parsing, UTF-8 BOM + CRLF source checks, and source-level adapter routing. The submitted Windows evidence is the negative regression fixture: 23/26 incomplete releases and a 261-character predicted vendor path must not be accepted as successful downstream analysis. Windows PowerShell 5.1 exact-source rerun remains a separate gate.



## rev55 8.08.12.551 qualification gates

The minimum development gate uses the attached/provided installer with
SHA-256 `04192323117317d212119d66476fe518d62eab17a6250f0cf5ab1b6c43ae138c`
and size `81,537,472` bytes. The installer is an external test input and SHALL
NOT be included in the repository or user-facing source ZIP.

Container/static PASS requires:

1. PowerShell AST parse success and UTF-8 BOM + CRLF source-byte compliance;
2. `Test` PASS, including `CuratedLatestRelease` and
   `SelectorProductCorrelation`;
3. exact-release Discover PASS with only `8.08.12.551` selected;
4. Extract PASS with one complete release, 25 containers and 31 INF files;
5. Inspect PASS with 31/31 INF files parsed and no WDF-regression delta from
   8.07.16.1035;
6. static Signature PASS with only 8.08.12.551 selected, 209 unique artifacts,
   35 kernel binaries and 35 embedded-signed kernel binaries; and
7. Selector PASS with 44 DevID.xml rules and explicit correlation status for
   unmatched new tokens.

This container gate does not qualify Windows-native SignTool/catalog policy,
Windows Client selector behavior, Windows Server behavior, or a compiled
contract for the new Qt selector hash. A future real-machine request must state
the hypothesis, exact PASS evidence and what the PASS enables. Windows Client
evidence must be reviewed before any Windows Server gate is authorized.

## Rev52 reviewed Windows PowerShell 5.1 gate

The exact rev51 source (`3c1a8b449f7960e39cd634b0741500e3fa56491581b7b4c2cccba272459ff2cc`)
passed Test on Windows PowerShell 5.1.26100.9168 in 5.32 seconds (6.20 seconds
total). The supplied ZIP passed archive integrity and all 51 manifest entries
matched their declared size and SHA-256. Rev52 additionally requires POSIX
relative paths in the private Evidence manifest and retains the interruption
probe as a local regression gate.

## Rev51 regression gates

Before requesting another Windows PowerShell 5.1 user run, qualification SHALL cover:

1. clean-copy `-Stages Test` without `inventory/driver-packages.json`;
2. proof that `Test` skips public-baseline reconstruction;
3. the fixed Canonical JSON SHA-256 vector;
4. the complete 25-file chipset public release corpus (45,980,206 input bytes);
5. invalid-stage bootstrap finalization with a verified ZIP and SHA-256;
6. forced normal-finalizer failure for all three tools, with a verified emergency ZIP and retained raw evidence;
7. UTF-8 BOM plus CRLF source-byte validation; and
8. an explicit record that Windows PowerShell 5.1 remains pending until its real-host gate is reviewed.

The PS7.6.5 clean-copy chipset Test stage completed in approximately 2.35 seconds
in the development container. The 25-file corpus parsed in 11.43 seconds and a
104,915,273-byte canonical aggregate serialized in 12.95 seconds. These are
regression observations, not Windows PowerShell 5.1 acceptance values.

## Rev50 Canonical JSON short gate

Run `-Stages Test -SkipPublicExport -EvidenceRetention ZipOnly`. PASS requires
`CanonicalJsonCrossRuntimeSelfTest=Pass` and the Python reference SHA-256
`85c339be2fbfe8488cce582d432999278506cf91b815940b428b2b9dc06fbdd0`.
No acquisition or full research rerun is required for this gate.

This document defines the current qualification and release-acceptance procedure for `Invoke-AmdChipsetDriverResearch.ps1`. Historical hardening narratives belong under `reports/**`; this file describes the gates that a current release must pass.

## 1. Qualification philosophy

Passing research stages is necessary but not sufficient for release acceptance.

The release gate treats these as independent controls:

1. source/static correctness;
2. built-in self-tests;
3. Windows PowerShell 5.1 full-run behavior;
4. release/package conservation;
5. INF/WDF/selector consistency;
6. MSI evidence quality;
7. publication privacy/schema/byte contracts;
8. manifest/source provenance;
9. private Evidence integrity;
10. Git/repository integration;
11. signature-evidence scope and Windows-native qualification when the Signature stage changes;
12. sequential-download and diagnostic-trace contracts when network/diagnostic primitives change.

Generated artifacts must be regenerated by the toolkit. **Do not repair generated JSON/CSV/Markdown by hand.**

## 2. Source gates

### 2.1 PowerShell AST

The current source must parse without AST errors on the intended PowerShell runtimes.

```powershell
.\Invoke-AmdChipsetDriverResearch.ps1 -Stages Test
```

### 2.2 Repository static analyzer

Run the repository-canonical PowerShell static analyzer with the repository configuration.

Release acceptance requires **zero static-analysis errors**. Warnings/info are reviewed according to repository policy.

### 2.3 Source encoding

The distributed script must remain:

- UTF-8 with BOM;
- CRLF-only;
- no bare LF.

Top-level/source Markdown should follow repository source-document convention; generated public Markdown has its separate public byte contract below.

## 3. Built-in Test stage

The Test stage must return the expected success result and report `SelfTestsReady=True`.

Required self-test families include:

- compiled selector contracts;
- localized architecture normalization;
- MSI table-name projection;
- FieldCount-independent MSI column discovery;
- MSI row-pipeline isolation;
- MSI declarative assessment;
- portable analysis normalization/token fidelity;
- publication contract;
- PowerShell 5.1 collection-wrapper rehydration/canonical aggregate behavior.

A release must not waive a failed self-test simply because later stages complete.

## 4. Controlled Windows full run

The authoritative release-generation run should use Windows PowerShell 5.1 on the qualified Windows test host and a known 7-Zip installation.

For a release audit, pin the intended release set explicitly. The v2.0.0 baseline uses 25 releases from `2.04.04.111` through `8.07.16.1035`.

Expected high-level outcome for the current baseline:

```text
10 / 10 selected stages : PASS
OverallStatus            : Pass
ExitCode                 : 0
Releases                 : 25
INF package records      : 643
INF parse failures       : 0
```

If AMD publishes a new release, expanding the pinned release set is a conscious product/research decision and requires a correspondingly broader data audit.

### 4.1 Version 2.1.14 Windows 11 metadata/acquisition correction qualification

The 2.1.14 correction is triggered by `AmdChipsetDriverResearchEvidence_20260815-064314_Windows.zip`. In that run, the first metadata GET for 7.02.13.148 ended with `ConnectionClosed`; 2.1.13 had no metadata retry and generated zero installer candidates because candidate derivation was incorrectly gated on successful HTML retrieval. Acquire therefore returned `MissingUrl` without attempting the deterministic vendor installer URL, and Signature later failed secondarily because no release was extracted.

Correction qualification SHALL use Windows 11 / Windows PowerShell 5.1 and the exact historical boundary probe `7.02.13.148`.

```powershell
# Gate A - source/self-test contract
.\Invoke-AmdChipsetDriverResearch.ps1 -Stages Test

# Gate B - focused metadata/acquisition correction
.\Invoke-AmdChipsetDriverResearch.ps1 `
  -Stages Test,Discover,Metadata,Acquire `
  -ReleaseVersion 7.02.13.148 `
  -SkipHostAnalysis `
  -Force

# Gate C - historical boundary probe after Gate B succeeds
.\Invoke-AmdChipsetDriverResearch.ps1 `
  -Stages All `
  -ReleaseVersion 7.02.13.148 `
  -SkipHostAnalysis `
  -Force
```

Stop at the first failed gate. Gate B SHALL prove that metadata `FetchAttempts` records retry policy evidence, that the current AMD vendor-observed 7.02 release-note alias can be selected when needed, and that `CandidateDownloadUrls` is non-empty even if release-note HTML retrieval ultimately fails. If acquisition still fails, Acquire itself SHALL be FAIL and later stages SHALL be BLOCKED.

A successful retry SHALL record `Retryable`, `RetryReason`, `DelayBeforeNextAttemptMilliseconds`, `NoCache`, `DisableKeepAlive`, and any `Retry-After`/WebException status. The self-test SHALL prove exponential delays 1000/2000/4000 ms with deterministic zero jitter, retryable `ConnectionClosed`, 403 and 429, and fail-fast 404.


### 4.2 Accepted 2.1.13 qualification history

Before a full Windows 11 qualification run, Windows PowerShell 5.1 SHALL run `-Stages Test`; `SelfTests.SignaturePrimitives.Status`, `SelfTests.SignatureContentTypeRouting.Status`, `SelfTests.HttpDownloadTransport.Status`, `SelfTests.SignToolVerificationProfile.Status`, and `SelfTests.KernelSignatureCoverage.Status` SHALL all be `Pass`. The evidence SHALL also retain the `SignedCmsRuntime` assembly-resolution observation. This specifically guards the .NET Framework `System.Security` loading path used by Windows PowerShell 5.1.

The current native qualification for the 2.1.13 exact-release discovery, acquisition, and Signature hardening SHALL be performed on Windows 11 before Target Server qualification. A controlled run SHOULD pin `8.07.16.1035` so vendor release discovery cannot change the qualification input unexpectedly.

Recommended gated workflow:

```powershell
# Gate A: PowerShell/runtime/source self-tests only
.\Invoke-AmdChipsetDriverResearch.ps1 -Stages Test

# Gate B: reproduce the formerly failing AMD download from the network.
# -Force is intentional so an old cached artifact cannot hide the transport path.
.\Invoke-AmdChipsetDriverResearch.ps1 `
  -Stages Test,Discover,Metadata,Acquire `
  -ReleaseVersion 7.11.26.2142 `
  -Force

# Gate C: requalify Windows-native signature profiles on the pinned newest artifact.
.\Invoke-AmdChipsetDriverResearch.ps1 `
  -Stages All `
  -ReleaseVersion 8.07.16.1035 `
  -SkipHostAnalysis
```

Stop at the first failed gate and return that gate's Evidence ZIP. Do not hide Gate B with a manually copied/cached 7.11.26.2142 EXE; the purpose of Gate B is to qualify the downloader itself.

After the pinned qualification is stable, a normal no-`ReleaseVersion` full historical survey SHALL still process all selected releases in Discover/Metadata/Acquire/Extract/Inspect/Selector/Build, while `Signature` SHALL automatically select only the newest release from that set. The console and JSON evidence SHALL identify that selection explicitly.


The run SHALL verify at minimum:

- `inventory/environment.json` reports `ExecutionContext.ExecutionClass = WindowsClient` and includes `Static` + `WindowsNative` scopes but not `TargetServerHost`;
- `inventory/signature-analysis.json` is produced from extracted bytes and remains host-neutral;
- the pinned 8.07.16.1035 qualification reproduces the expected extracted signature inventory before release acceptance: 209 unique static signature artifacts, including 35 kernel binaries and 46 catalog variants; this count includes 7-Zip collision-renamed forms such as `.sys1`/`.cat1` and content-detected PE files whose extracted names do not retain a normal PE extension;
- PE/CMS envelope parse failures and signed-versus-recomputed PE digest mismatches are investigated rather than silently discarded;
- `inventory/host/signature-native-verification.json` is produced;
- `inventory/host/windows-host-security-posture.json` is produced read-only;
- `inventory/host/target-server-host-evidence.json` is not created as a Windows Client claim;
- when SignTool is available, `/pa` and appropriate `/kp`/`/all` observations are captured; when absent, the result is an explicit tool-unavailable/NotObserved state rather than a fabricated Pass/Fail;
- all 46 catalog variants in the pinned 8.07.16.1035 signature inventory are attempted through the native catalog enumerator and any member/attribute enumeration failure is retained explicitly;
- SignTool `/o` results are treated as target-build policy observations, not Server ProductType/runtime proof;
- no driver is staged, installed, loaded, or started, and no boot/security configuration is changed.
- an operator Ctrl+C interruption SHALL be recorded as `INTERRUPTED`, not `FAIL`; downstream stages not reached because of that interruption SHALL be `NOT_ASSESSED`, and publication SHALL not be attempted from the incomplete run;
- `StageExecution=REVIEW` SHALL remain reserved for actual failed/blocked execution rather than an intentional operator interruption.

The current development host has qualified the new Static path on PowerShell 7/Linux against the exact AMD 8.07.16.1035 artifact. That does **not** replace this Windows 11 native qualification gate.


#### 4.1.1 Retained 2.1.11 Windows qualification evidence

The immediately preceding 2.1.11 Windows 11 qualification passed all three gates and is retained as regression evidence:

- Gate A Evidence: `AmdChipsetDriverResearchEvidence_20260815-024651_Windows.zip`
- Gate B Evidence: `AmdChipsetDriverResearchEvidence_20260815-024711_Windows.zip`
- Gate C Evidence: `AmdChipsetDriverResearchEvidence_20260815-024735_Windows.zip`
- Gate B downloaded 7.11.26.2142 as `78,301,768` bytes with SHA-256 `1acd6dadcc3b4bca9451ff170d7a5a049309b827f74cf54b2a3684bf16a34856`, exactly matching the independently browser-downloaded vendor EXE.
- Gate C recorded 35/35 verified explicit catalog kernel-policy checks and 140/140 verified WS2016/WS2019/WS2022/WS2025 target checks.
- An independent per-file review found 35/35 kernel binaries fully covered by the required catalog-bound profiles.

Because 2.1.13 changes source code, the successful 2.1.11 results and the 2.1.12 Gate A/B evidence are retained but do not waive re-running Gates A/B/C against 2.1.13.


#### 4.1.2 Retained 2.1.12 discovery regression evidence

The 2.1.12 requalification produced Gate A PASS and Gate B PASS, but Gate C failed before signature analysis because both AMD sitemap requests returned HTTP 403. `Discover` then emitted zero releases even though `-ReleaseVersion 8.07.16.1035` was explicitly pinned; Metadata/Acquire/Extract/Inspect processed zero items and Signature failed with `Extraction inventory contains no releases for signature analysis.` The Discover implementation was byte-for-byte unchanged from 2.1.11, so this was a latent exact-release/sitemap dependency exposed by transient vendor blocking rather than a failure in the new per-kernel signature evaluator. Version 2.1.13 is required to re-run the gates.

For 2.1.13 Gate B and Gate C, confirm `snapshot/inventory/releases.json` reports `Completeness=RequestedReleasePinned`, `ReleaseCount=1`, `ExactReleaseMode=true`, and `SitemapEnumerationSkipped=true`. Gate C must then proceed to real Signature analysis rather than a zero-release path.

### 4.2 Windows Server 2025 host-scope qualification

After the Windows 11 path is stable, run the same pinned workflow on Windows Server 2025. In addition to the Windows-native requirements above:

- `ExecutionContext.ExecutionClass` SHALL be `WindowsServer`;
- evidence scopes SHALL include `Static`, `WindowsNative`, and `TargetServerHost`;
- `inventory/host/target-server-host-evidence.json` SHALL exist;
- Secure Boot / Device Guard-HVCI / TESTSIGNING observations SHALL be read-only and explicit about unavailable APIs/states;
- PnP install, kernel-load, Code Integrity runtime, and device-runtime fields SHALL remain `NotObserved` in this research stage.

A later explicit driver qualification may add runtime evidence, but that is not part of the Signature-stage acceptance gate.


## 4.3 Version 2.1.16 pre-propagation quality gates

2.1.16 fixes common diagnostic semantics before NPU/Graphics propagation. These are **purpose-driven** gates, not ceremonial full reruns.

### Gate 1 — Windows 11 diagnostic/network regression fixture

Purpose:
- prove the new diagnostic redaction and expected-fallback self-tests on Windows;
- exercise the real AMD `ConnectionClosed` / bounded retry / historical alias path;
- verify sequential HTTP concurrency remains 1.

```powershell
.\Invoke-AmdChipsetDriverResearch.ps1 `
    -Stages Test,Discover,Metadata,Acquire `
    -ReleaseVersion 7.02.13.148 `
    -SkipHostAnalysis `
    -Force
```

PASS requires:
- Test stage PASS;
- `DiagnosticPrimitiveSelfTest=Pass`;
- `ExpectedFallbackProbeSelfTest=Pass`;
- `SequentialDownloadSourceContractSelfTest=Pass`;
- if ConnectionClosed recurs, bounded retry/backoff is structured and recovery succeeds;
- no misleading SignedCms Add-Type fallback ErrorRecord in the user-visible transcript;
- diagnostic JSONL preserves `HasMzSignature`/`HasZipSignature` when those fields are present, while signed-URL credentials remain redacted.

This is a regression fixture, not 7.02 production qualification.

### Gate 2 — Windows 11 current-latest production-oriented qualification

Purpose:
- prove the final reference source against the pinned current-latest Chipset artifact.

```powershell
.\Invoke-AmdChipsetDriverResearch.ps1 `
    -Stages All `
    -ReleaseVersion 8.07.16.1035 `
    -SkipHostAnalysis `
    -Force
```

PASS requires the current-latest full research/signature/publication baseline with no new common diagnostic defect.

### Gate 3 — Windows Server 2025 TargetServerHost qualification

Run only after Gates 1 and 2 PASS.

Purpose:
- prove the same source version under the production-relevant Server host evidence scope.

```powershell
.\Invoke-AmdChipsetDriverResearch.ps1 `
    -Stages All `
    -ReleaseVersion 8.07.16.1035 `
    -Force
```

PASS requires TargetServerHost evidence plus the normal current-latest full research/signature/publication result.

### Propagation decision

Only after Gates 1-3 PASS may the 2.1.16 common transport/diagnostic primitive be treated as the NPU migration baseline.

No additional 6.x/7.x historical full run is required unless a new production-relevant model question appears.


## 4.4 Version 2.1.17 platform-gated pre-propagation validation

2.1.16 Windows Gate A/B processing itself passed, but Windows PowerShell 5.1 `Start-Transcript` still exposed two synthetic Test-stage terminating-error lines. 2.1.17 removes those self-test noise sources.

The HTTP retry/alias transport path was already proven under 2.1.16 and is unchanged in 2.1.17. Do **not** repeat the 7.02 network fixture merely as ceremony.

### Windows 11 platform gate

Run one current-latest Full test:

```powershell
.\Invoke-AmdChipsetDriverResearch.ps1 `
    -Stages All `
    -ReleaseVersion 8.07.16.1035 `
    -SkipHostAnalysis `
    -Force
```

This single run is sufficient because it:
- executes the Test stage under Windows PowerShell 5.1;
- verifies the no-throw fallback/self-test hygiene;
- exercises SignedCms/signature processing on the current-latest artifact;
- re-establishes the current-latest Windows Client research/signature/publication authority for source 2.1.17.

PASS requires:
- Overall Pass / exit 0;
- no synthetic `PS>終了エラー(Add-Type)` from the expected fallback self-test;
- no synthetic `DER element offset is outside the input buffer` Test-stage error;
- `ExpectedFallbackProbeSelfTest=Pass`;
- `SignatureContentTypeRoutingSelfTest=Pass`;
- non-secret signature diagnostic fields remain visible;
- current-latest 8.07 full signature/publication baselines remain satisfied.

**STOP after this Windows 11 run and share the Evidence.**

Do not start Windows Server 2025 until the Windows 11 platform checkpoint is reviewed and explicitly accepted.

### Windows Server 2025 platform gate

This command is authorized only after review of the 2.1.17 Windows 11 Evidence:

```powershell
.\Invoke-AmdChipsetDriverResearch.ps1 `
    -Stages All `
    -ReleaseVersion 8.07.16.1035 `
    -Force
```

Purpose:
- establish TargetServerHost authority for the same source version;
- prove that the finalized reference primitive behaves correctly in the separate Server platform/environment.

Only after explicit acceptance of this Server evidence may 2.1.17 become the NPU common-primitive migration baseline.

## 5. Release-set and package conservation

From the 25 canonical per-release Raw JSON documents, recompute the set:

```text
(ReleaseVersion, InfRelativePath, InfSha256)
```

Compare it to `public/inventory/amd-chipset-driver-inventory.csv`.

Release acceptance requires:

- expected release-document count;
- expected package-record count;
- no duplicate keys;
- JSON-only key count = 0;
- CSV-only key count = 0.

For the v2.0.0 baseline the expected package count is 643.

## 6. INF semantic and Server-profile reconstruction

Schema-valid Raw JSON must be sufficient to independently recompute the published Windows Server applicability figures.

At minimum verify:

- `[Manufacturer]` / Models topology is structurally present;
- AsPublished/Native and ServerProjection results remain distinct;
- target Server profiles include WS2016/2019/2022/2025 as defined by the versioned profile data;
- aggregate summary figures reproduce from per-release Raw JSON without trusting Markdown.

A `ServerProjection` candidate must never be reinterpreted as runtime compatibility.

## 7. WDF consistency

Cross-check WDF declarations and aggregate summaries against the per-release Raw JSON.

No package may silently gain a KMDF/UMDF declaration that is absent from its source INF evidence.

Where conservative INF-wide WDF scope is used, the report/schema must identify that scope rather than imply a narrower DDInstall dependency.

For the current measured dataset the maximum declared KMDF version is 1.19; a change to this measured ceiling must be traceable to new/changed Raw evidence.

## 8. F-01 vendor-token fidelity regression

The following corrupted forms must occur zero times in the public surface:

```text
external-path/SET*
external-path/info.xml
external-path/DevID.xml
```

Expected artifact-derived values such as the following must remain byte-faithful where present:

```text
/SETFILTERUSB
/SETRYZENPPKG
/SETPCI
/info.xml
/DevID.xml
C:\
```

Aggregate selector fields must agree semantically with their corresponding per-release documents after recognized PowerShell 5.1 collection wrappers are read as collections.

## 9. AMD selector evidence-level gates

For every compiled selector contract:

- the release and selector SHA-256 scope must be present;
- `AmdCompiledStaticProven` must not be broadened to an adjacent release by name similarity;
- unresolved older-major hardware predicates must remain unresolved unless new code-level evidence was added;
- observed AMD logs must remain dynamic evidence, not silently promoted to compiled proof.

When a known compiled rule explains candidate removal, the HostMatch result may report the proven explanation; otherwise it must retain an unknown/unresolved state.

## 10. MSI declarative-analysis gate

On a qualified Windows run with recovered MSI databases, verify:

- every expected MSI reports `ParsedReadOnly`;
- `ParseFailed = 0`;
- `ParsedWithErrors = 0` unless explicitly reviewed/accepted;
- `AllNullRowCount = 0`;
- no PowerShell COM method-return sentinel leaks into row data.

For the v2.0.0 baseline:

```text
MSI ParsedReadOnly : 25 / 25
Selected rows       : 13,993
All-null rows       : 0
```

`ACTION=ADMIN` observations must remain classified as administrative extraction, not feature installation selection.

## 11. Publication surface gate

`public/**` is the only generated auto-commit surface.

A release-generation run must produce a passing:

```text
public/publication-validation.json
```

The public surface must contain only repository-safe generated artifacts defined by `PUBLICATION-POLICY.md`.

Private/runtime staging must remain outside automatic publication.

## 12. Public JSON/schema gate

All public JSON must parse.

Every public document with a defined schema must validate against that schema.

Generated aggregate indexes must not retain recognized PowerShell 5.1 `{ value, Count }` collection wrappers when their schemas require arrays.

Canonical per-release Raw JSON may preserve the source PowerShell 5.1 serialization representation; publication must not rewrite those primary evidence documents merely to alter collection shape.

## 13. Aggregate canonicalization gate

For every tool-generated aggregate:

- recognized PS5.1 collection wrappers expected to project to arrays must be absent after generation;
- scalar/domain objects that merely contain properties named `value` and `Count` must remain objects;
- selector aggregate array-shape self-tests must pass;
- aggregate semantic fields must remain equivalent to canonical per-release source records.

A surviving recognized wrapper in a schema-array field is a publication blocker.

## 14. Manifest verification

Verify `public/publication-manifest.json` independently.

Release acceptance requires:

- `ManifestEntryCount` equals the number of payload entries;
- `PublicFileCountIncludingManifest` equals actual public file count;
- every manifested file exists;
- every file size matches;
- every published SHA-256 matches;
- there are no unmanifested payload files;
- there are no duplicate/unsafe/non-POSIX repository paths;
- `HandEdited=true` count = 0.

For source-backed files, verify `SourceRelativePath` and `SourceSha256` against the private Evidence snapshot.

## 15. Evidence/public identity binding

The private Evidence run must record:

- ToolkitVersion;
- exact script SHA-256;
- run result/stages;
- public manifest SHA-256/reference;
- evidence manifest.

The public manifest SHA-256 referenced by Evidence must equal the exact manifest inside the transferred/public Git candidate.

The supplied/repository script SHA-256 must equal the script recorded in the Evidence snapshot.

## 16. Private Evidence integrity

Verify the private Evidence manifest independently:

- no missing files;
- no SHA-256 mismatch;
- no size mismatch.

Private host/runtime artifacts are audit inputs, not public repository artifacts.

## 17. Privacy boundary

Extract concrete private host identifiers from private Evidence and search the public surface for them.

At minimum include checks for:

- actual work/tool root;
- `Users\` paths;
- UNC paths;
- CPU `ProcessorId` value;
- PnP device instance IDs / distinctive host identifiers;
- credentials/private-key material.

Expected public matches = 0.

MSI vendor data such as `ROOTDRIVE = C:\` is not a host leak merely because it resembles a drive path.

Public JSON privacy checks must operate on decoded scalar strings so JSON backslash escaping cannot hide a private Windows path.

## 18. Public Markdown format

Every generated Markdown under `public/**` must be:

- UTF-8 without BOM;
- LF-only;
- CR count 0.

The publisher must not silently insert or edit report conclusions during publication.

## 19. Fail-closed injection

Qualification of publication behavior should intentionally inject a private/invalid public candidate.

Expected behavior:

- publication validation fails;
- final result becomes review/non-accept;
- the previous valid public manifest/tree remains byte-identical;
- invalid staging is not promoted.

## 20. Partial-run preservation

Run a partial workflow that updates only a subset of outputs.

Verify that unrelated previously validated per-release Raw JSON remains present and byte-identical in the resulting public surface.

A partial run must not silently shrink the canonical baseline.

## 21. Fresh-checkout reconstruction

From a clean tool state containing source/static files and the tracked `public/**` baseline but no runtime `inventory/**`/generated `reports/**`, run the supported Build/reconstruction path.

Expected behavior:

- runtime aggregate/index data is rehydrated from public canonical data;
- PowerShell 5.1 collection wrappers are handled on read;
- Build completes without rewriting the tracked primary Raw JSON merely to change shape;
- rebuilt aggregates/reports remain semantically consistent.

This gate should be repeated whenever public schemas or rehydration logic change.

## 22. Repository byte-identity gate

Because public JSON/CSV hashes are part of the publication contract, verify repository attributes do not rewrite the bytes after staging/checkout.

The repository must preserve:

```text
tools/amd-chipset-driver-research/public/**
```

as byte-identical generated evidence. A fresh checkout must reproduce the manifest SHA-256 values.

## 23. Repository integration gate

When public paths or baseline layout change, search repository-wide consumers before deleting/renaming the old path.

Required integration checks include:

- tests that hard-code the old inventory/report path;
- reconciliation tools;
- root README/SPEC/TESTING/CHANGELOG references;
- schema `$ref`/path dependencies;
- canonical drift scanners;
- `.gitignore` / `.gitattributes` behavior.

Use a negative control where useful: prove that the old consumer actually fails after the layout change, then prove the updated consumer passes.

## 24. Historical v2.0.0 acceptance baseline

The generated repository baseline at this historical gate was v2.0.0 while the
v2.1.13 exact-release discovery/download/signature hardening was in Windows
qualification. The current authority is the accepted v3.0.0 Gate 2C
publication described at the top of this guide.

The accepted v2.0.0 publication was qualified with:

```text
ToolkitVersion       : 2.0.0
Stages               : 10 / 10 PASS
OverallStatus        : Pass
Releases             : 25
INF packages         : 643
INF parse failures   : 0
MSI ParsedReadOnly   : 25 / 25
MSI all-null rows    : 0
Public files         : 65
Manifest payloads    : 64
HandEdited=true      : 0
```

The exact current values remain verifiable from `public/**`; this section is a release-acceptance reference, not a substitute for recomputation.

## 25. Documentation-only changes

A documentation-only reorganization does not require a toolkit version bump or new research dataset when:

- `Invoke-AmdChipsetDriverResearch.ps1` is byte-identical;
- schemas/data/public generated files are unchanged;
- only reviewed source Markdown and historical-document placement changes;
- links and repository paths are updated consistently.

Such a change should still verify top-level documentation layout, Markdown formatting, and repository links.
## 2.1.14 acquisition/discovery/publication/localization/signature regression gates

The Test stage must prove all of the following:

- all requested/current artifacts available => `PASS`;
- automatic historical discovery with newest available and an older gap => `PASS_WITH_NOTES`;
- newest discovered artifact unavailable => `REVIEW`;
- explicitly requested unavailable artifact => `REVIEW`;
- `PassWithNotes` has exit code 0 and is eligible for fail-closed public publication;
- a successful publication is copied into private evidence as `snapshot/public/**`;
- Build clears run-scoped `inventory/releases/**` and `reports/releases/**` before regeneration so stale release output cannot leak into the current run.
- a `-Stages Test` (or any run without a successful current-run `Build`) SHALL NOT publish or replace `public/**`; the previous validated baseline is preserved and `PublicRepositorySurface` is `NOT_ASSESSED`;

Windows acquisition qualification retains the previous 7.11.26.2142 transport-integrity baseline and additionally verifies the 2.1.14 retry/fallback contract. The historical 7.02.13.148 correction run must show non-empty deterministic candidates even when metadata HTML is unavailable, and exact-release unavailability must fail at Acquire rather than Signature. The prior baseline also verifies that 7.11.26.2142 is fetched from the network with `-Force`, the resulting artifact begins with a recognized installer signature, and `acquisition.json` preserves `DownloadAttempts` transport evidence. No successful attempt may be classified as `PartialContentRejected`, `ByteCountMismatch`, `AmdDownloadIncompleteRedirect`, or `InstallerPayloadValidationFailed`. The Test stage SHALL also prove the shared post-transfer payload decision rejects a truncated body, an empty body, and an invalid installer payload, while accepting an exact-length valid installer. If a retry occurs, the attempt evidence must show the original failure and the fresh-session/cache-bypass retry rather than silently discarding it.

Windows Client signature qualification must additionally verify that:

- catalog-bound SignTool observations use a Windows catalog/SIP hash computed with `CryptCATAdminCalcHashFromFileHandle2`, matched to an enumerated catalog member, never raw file SHA matching;
- the kernel-policy profile is exactly `/kp /c <catalog> <driver>` (plus verbosity) and contains neither `/o` nor `/pa`;
- each target-OS profile is exactly an explicit catalog relationship with `/c <catalog> /o <target> <driver>` (plus verbosity), contains neither `/kp` nor `/pa`, and reports `VerificationProfileId=WindowsDriverExplicitCatalogTargetOs/1`;
- no target-build observation reports `ToolExecutionFailed`; successfully-launched non-zero results remain `NonZeroExit` observations and are not reclassified from localized prose;
- `/o` target-build checks are generated for kernel binaries only;
- extracted renamed catalogs such as `*.cat1` are verified via a byte-identical `.cat` alias and do not produce extension-induced `HashMismatch`;
- native result classification is locale-neutral: exit `0` -> `Verified`, successfully-launched non-zero -> `NonZeroExit`, process-launch failure -> `ToolExecutionFailed`; no English message is required for canonical classification;
- if catalog-bound target-OS checks exist but **zero** checks verify successfully, `SignatureAnalysis=REVIEW` because CLI acceptance cannot be proven safely from localized error prose;
- every catalog-associated kernel binary has at least one verified explicit catalog kernel-policy check and verified WS2016/WS2019/WS2022/WS2025 target checks; any per-kernel coverage gap forces `SignatureAnalysis=REVIEW` even if aggregate totals contain successes;
- `KernelModeEmbeddedOrCatalog` (`/all /kp` without explicit `/c`) is treated as supplemental diagnostic evidence and its non-zero observations do not replace or negate complete explicit catalog-bound coverage;
- `signature-native-verification.json` records `FileType` and `VerificationPathKind` for traceability.
- RFC3161 timestamp and catalog CMS envelopes do not report false `SpcIndirectDataDigest.ParseFailed` results merely because their content type is not Authenticode SPC indirect data; they report `NotApplicableContentType`.


## Windows toolchain capability qualification

On Windows 11 and Windows Server qualification hosts, inspect both `inventory/toolchain-capabilities.json` and `inventory/host/toolchain-capabilities-private.json`. Confirm that SignTool and Inf2Cat binary SHA-256/file versions are recorded, help probes have output digests, and capability observations reflect the installed binaries. Confirm that `public/inventory/toolchain-capabilities.json` contains only the portable summary after a publishable Build run.

The first Windows 11 qualification MUST verify that `signtool.exe /?`, `signtool.exe verify /?`, and `Inf2Cat.exe /?` are captured without mutating the host or driver payload. Do not treat an observed help option as proof that a multi-option command is accepted; actual qualification results are authoritative for the executed verification profile.

The same qualification MUST inspect `LocalizationContext` and confirm that the toolkit records PowerShell culture/UI culture, Windows locale/UI-language observations, numeric console code pages, console encodings, and any `LANG`/`LC_ALL` hints. Repeat or inspect the run on a non-English Windows installation where available. Token capability detection and final status MUST remain unchanged by translated help/error prose. Raw localized output is evidence only; the self-test `NativeToolLocalizationSelfTest` MUST be `Pass`. No test may require setting `LANG=C`, changing the Windows display language, or changing system locale.


## Windows PowerShell 5.1 collection-cardinality regression gate

Before any full Windows qualification run:

```powershell
.\Invoke-AmdChipsetDriverResearch.ps1 -Stages Test
```

must report both:

- `PowerShell51CollectionCardinalitySelfTest : Pass`
- `CollectionCardinalitySourceContractSelfTest : Pass`

The regression gate covers the exact 2.1.9 failure class in which a conditional expression yielded zero missing native methods, assignment collapsed that output to `$null`, and `StrictMode` rejected `.Count`.

A Test-stage failure is a stop condition; do not continue the full survey merely to collect later-stage output.


## Diagnostic trace and sequential-download gate (2.1.15)

Before any Windows network correction/full run, execute:

```powershell
.\Invoke-AmdChipsetDriverResearch.ps1 -Stages Test
```

The Test result MUST include:

- `DiagnosticPrimitiveSelfTest : Pass`
- `SequentialDownloadSourceContractSelfTest : Pass`
- `HttpRetryPolicySelfTest : Pass`
- `HttpDownloadTransportSelfTest : Pass`

`SequentialDownloadSourceContractSelfTest` confirms that the AMD HTTP concurrency contract remains `1` and that known PowerShell parallel execution primitives are not used by executable command AST.

For an Evidence-enabled PASS run, inspect:

- `logs/diagnostic-events.jsonl`
- `run-summary.json` -> `DiagnosticTraceEnabled=true`
- `run-summary.json` -> `HttpMaximumConcurrency=1`

For an intentional or real FAIL, verify that `errors/failure-snapshots/*.json` is created when the failure passes through the tracked-stage or top-level runner catch path. A failure snapshot must contain stage/function/step context and bounded recent events. It must not contain unredacted Authorization/Cookie/token-like test values.

When testing an HTTP error response, inspect the relevant metadata/download attempt evidence and diagnostic event. Response headers must be structured/redacted and response-body preview must remain bounded. Do not require an unlimited raw server body.

The diagnostic subsystem is best-effort. A failure to persist diagnostics must not be allowed to convert an otherwise valid research operation into FAIL.

### Windows 11 correction gates for the active 7.02.13.148 defect

Because 2.1.14 was superseded before Windows qualification, qualify 2.1.15 directly.

Gate A:

```powershell
.\Invoke-AmdChipsetDriverResearch.ps1 -Stages Test
```

Gate B:

```powershell
.\Invoke-AmdChipsetDriverResearch.ps1 `
    -Stages Test,Discover,Metadata,Acquire `
    -ReleaseVersion 7.02.13.148 `
    -SkipHostAnalysis `
    -Force
```

Gate C only after A/B PASS:

```powershell
.\Invoke-AmdChipsetDriverResearch.ps1 `
    -Stages All `
    -ReleaseVersion 7.02.13.148 `
    -SkipHostAnalysis `
    -Force
```

Stop at the first FAIL and preserve the resulting E1 Evidence. On PASS, the structured trace is reviewed as routine E0/E2 support evidence and may later be compacted under project governance.
## Evidence-storage qualification (rev48)

A release candidate must pass the following short tests for all three tools; a full artifact research run is not required for this contract.

1. Parse the script with Windows PowerShell 5.1-compatible syntax.
2. Run the smallest local stage with default evidence settings.
3. Confirm the final ZIP, `.zip.sha256`, and `LATEST-EVIDENCE.txt` exist directly under `private\evidence`.
4. Confirm the hash companion matches the ZIP and every ZIP entry can be read.
5. Confirm the raw `runs\r...` directory is removed for `ZipOnly` and retained for `ZipAndDirectory`.
6. Supply an output root outside `private\evidence` and confirm the run blocks before creating that directory or starting a network request.
7. On Windows, qualify UNC, SUBST, and reparse-point rejection under PowerShell 5.1.
# rev49 minimum Windows PowerShell 5.1 regression gate

Run only `-Stages Test` after the rev49 correction. Passing requires
`SignaturePrimitiveSelfTest : Pass`, a verified Evidence ZIP, its `.zip.sha256`
companion, and `LATEST-EVIDENCE.txt`. A full acquisition/signature run is not
required for this correction.
## rev57 common-core validation gate

Run `PathSafety,Test` first. PASS requires both stages to pass, the three-tool common-core contract to verify every listed function, the ordinal-ordering test to pass, and both path-safety logic tests to pass. This source change does not reuse earlier Windows qualification as proof for rev57.

The minimum next Windows Client command is a Test-only gate; do not repeat historical HTTP fixtures or a full acquisition merely for ceremony. Stop for evidence review after Windows 11 PASS. Windows Server 2025 remains a separately authorized gate.
