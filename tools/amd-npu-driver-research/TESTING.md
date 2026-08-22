# AMD NPU Driver Research Toolkit Testing Guide

## REV81 release-state and no-rerun decision

Claude closed Cycle B at REV80. The exact REV74 NPU-equipped Windows Client
Gate 2N is accepted at 15/15 PASS with the complete 23-file public snapshot,
and the exact REV78 NPU source/data has an accepted Windows Server / Windows
PowerShell 5.1 `PathSafety,Test` result at 2/2 PASS, exit `0`, manifest 69/69
exact and architecture mismatch count 0. REV81 is documentation-only and
requires no Windows Client or Server rerun. The NPU-equipped Server positive
case remains dependency-blocked and deferred; it is not a release gate for the
research toolkit. Lower revision commands are historical reproducibility
records, not current operator actions.

## REV79 accepted gate and no-repeat decision

The exact REV78 command below completed on Windows Server 2025 under Windows
PowerShell 5.1: `PathSafety=PASS`, `Test=PASS`, final `Pass`, exit `0`.
Its 69-row Evidence manifest is exact, diagnostics contain Info only, and all
37 NPU architecture-contract hashes independently match the captured source.

This gate is accepted. Do not repeat Chipset, Graphics or NPU Server smokes for
REV79 because executable/data/schema/public bytes are unchanged. No further
real-machine run was required before Claude Cycle B final review, and Claude
subsequently closed Cycle B at REV80.

## REV78 single affected retest

Quality hypothesis: the unchanged REV77 NPU source and regenerated 37-function
architecture contract agree exactly, so the previous Test-only hash rejection
is eliminated while the already proven Server execution context remains intact.

```powershell
& "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe" `
  -NoProfile -ExecutionPolicy Bypass `
  -File 'D:\Temp_AMD-Tool\Deploy-Drivers-For-WindowsServer\tools\amd-npu-driver-research\Invoke-AmdNpuDriverResearch.ps1' `
  -Stages PathSafety,Test `
  -SkipPublicExport `
  -EvidenceLabel 'REV78-CycleB-WindowsServer-NPU-ArchitectureContract' `
  -EvidenceRetention ZipOnly
```

PASS requires 2/2 stages, final `Pass`, exit `0`, exact Evidence manifest, no
Warning/Error diagnostics, exact NPU source SHA-256
`dba9761d9dc69463e34207dd3fa039b1a0de712a47ebe8698da66435736d0dd1`,
and `run-context.json` Server identity with `CollectionStatus=Collected`.
Hardware presence is irrelevant because `HardwareIdentity` is not selected.
PASS closed the three-tool Windows Server common-contract gate and enabled the
candidate freeze and Claude Cycle B final review completed at REV80.

## REV77 exact-source retest

Use Windows PowerShell 5.1 explicitly and keep the canonical path unchanged:

```powershell
& "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe" `
  -NoProfile -ExecutionPolicy Bypass `
  -File 'D:\Temp_AMD-Tool\Deploy-Drivers-For-WindowsServer\tools\amd-npu-driver-research\Invoke-AmdNpuDriverResearch.ps1' `
  -Stages PathSafety,Test `
  -SkipPublicExport `
  -EvidenceLabel 'REV77-CycleB-WindowsServer-NPU-ExecutionContext' `
  -EvidenceRetention ZipOnly
```

PASS additionally requires `run-context.json` to report `PSEdition=Desktop`,
Windows PowerShell 5.1, `ExecutionContext.ExecutionClass=WindowsServer`,
`ProductType` 2 or 3, `CollectionStatus=Collected`, and
`CollectionSource=Win32_OperatingSystem`. NPU presence is not required because
`HardwareIdentity` is not selected; this is not positive Server device proof.

## REV76 previous release gate

NPU Gate 2N is accepted/no-repeat. Do not rerun the Windows Client full path.
The remaining minimum-sufficient Windows Server command is:

```powershell
Set-Location 'D:\Temp_AMD-Tool\Deploy-Drivers-For-WindowsServer\tools\amd-npu-driver-research'
.\Invoke-AmdNpuDriverResearch.ps1 `
  -Stages PathSafety,Test `
  -SkipPublicExport `
  -EvidenceLabel 'REV76-CycleB-WindowsServer-NPU-Smoke' `
  -EvidenceRetention ZipOnly
```

PASS requires 2/2 stages, exit code `0`, Windows PowerShell 5.1 on Windows
Server, an exact Evidence manifest, and zero Warning/Error diagnostic events.
The smoke is valid on an NPU-equipped or NPU-absent Server because
`HardwareIdentity` is not selected. It does not prove positive package
selection, installation/load, XRT or workload behavior. The built/self-signed
positive Server case remains deferred. No launcher is included.

## REV75 current accepted Client gate

The exact REV74 `PathSafety,Test` run passed 2/2 stages and the subsequent full
Windows Client run passed 15/15 stages, selected `376` automatically and
produced a complete independently verified self-contained public snapshot.
Gate 2N is accepted and no NPU Client rerun is pending. The historical commands
below remain regression records, not current operator actions.

## REV74 exact-path cardinality and contract gate

The first exact REV73 run ended after 4.13 seconds. `PathSafety` passed at the
unchanged canonical path; Test then correctly rejected an unsafe conditional
collection assignment and a stale NPU-only architecture hash. No network or
artifact-processing stage ran.

Run the short correction gate first from the user's existing path:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
Set-Location 'C:\Temp\Deploy-Drivers-For-WindowsServer\tools\amd-npu-driver-research'
.\Invoke-AmdNpuDriverResearch.ps1 `
  -Stages PathSafety,Test `
  -SkipPublicExport `
  -EvidenceLabel 'REV74-CycleB-NPU-CardinalityContract' `
  -EvidenceRetention ZipOnly
```

PASS requires 2/2 stages PASS, exit code `0`, no collection-cardinality issue,
no architecture-convergence mismatch, and an integrity-valid Evidence ZIP.
Return that ZIP and stop for review. Only an accepted PASS enables the full
REV74 NPU run; it does not authorize Graphics or Windows Server.

## REV72 self-contained public Evidence gate

REV71 runtime processing passed 15/15 stages and proved the corrected
schema-authority path, but its Evidence archive copied only the public manifest
and therefore could not support an independent review without manual artifact
collection. That archive is retained as execution evidence but is not a closed
qualification artifact.

REV72 changes only Evidence finalization/snapshot behavior and documentation;
the NPU selection, acquisition, extraction, analysis, publication and schema
semantics remain unchanged. Run one exact REV72 full NPU test on the same
NPU-equipped Windows Client:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
Set-Location D:\AMD-R72\n
.\Invoke-AmdNpuDriverResearch.ps1 `
  -ResolveHardwareSelection `
  -EvidenceLabel REV72-CycleB-NPU-SelfContainedEvidence `
  -EvidenceRetention ZipOnly
```

PASS requires final `Pass`, exit code `0`, 15/15 stages PASS, reviewed `376`
selection, and a single Evidence ZIP containing the complete generated public
tree under `snapshot/public/**`. `snapshot/public-publication-reference.json`
must report `PublicDatasetIncludedInEvidence=true` and
`SnapshotValidationStatus=Pass`. Independent review must reproduce the public
manifest path/size/SHA-256 checks and all public schema checks directly from
that Evidence ZIP. Return only the tool-generated Evidence ZIP; do not create a
second public archive.

## REV71 NPU schema-authority correction gate

The executable version remains `3.0.0`. REV70 already established the positive
NPU identity path and completed the NPU full research workflow, but independent
validation correctly rejected Gate 2N because the generated matrix selection
key did not satisfy the stale shipped schema `const`.

REV71 changes only NPU-specific schema/Test/Validate logic and the repinned
three-tool source-identity contract. Chipset Gate 2C remains accepted and must
not be repeated. Graphics remains held. The minimum-sufficient Windows Client
retest is one NPU full regeneration on the same NPU-equipped profile:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
Set-Location D:\AMD-R71\n
.\Invoke-AmdNpuDriverResearch.ps1 `
  -ResolveHardwareSelection `
  -EvidenceLabel REV71-CycleB-NPU-SchemaAuthority `
  -EvidenceRetention ZipOnly
```

PASS requires final `Pass`, exit code `0`, 15/15 stages PASS, complete automatic
PnP selection of the reviewed `376` track, and a new public tree whose manifest
binds the exact REV71 NPU script. Independently validate all public JSON against
the shipped schemas, all manifest sizes/hashes, canonical bytes, privacy and
cross-dataset consistency. REV71 historically required both the Evidence ZIP
and a byte-preserving public ZIP; REV72 supersedes that manual two-artifact
instruction with the single self-contained Evidence ZIP. Stop for review; this PASS
does not authorize Graphics, Windows Server, installation, deployment or
re-signing.

## REV70 hardware-aware scope and transcript-hygiene gate

The tool version remains `3.0.0`. REV70 changes only the shared negative
extraction-completeness self-test path: the ordinary runtime assertion still
throws and blocks incomplete extraction, while the deliberate negative fixture
returns a structured `Blocked` result so Windows PowerShell 5.1 does not record
an expected caught terminating error.

NPU presence is an explicit hardware-selection dimension:

| Windows Client profile | Required result from `-ResolveHardwareSelection` |
|---|---|
| NPU absent | complete PnP enumeration, zero candidates, `NoNpuDriverRequired`, null selected track/artifact, `InstallationAuthorized=false` |
| reviewed NPU present | complete PnP enumeration, at least one reviewed candidate, expected HWID such as `PCI\VEN_1022&DEV_17F0`, decision/track `376`, reviewed artifact/INF identity, `InstallationAuthorized=false` |
| NPU-signaled but unknown, conflicting or incomplete enumeration | `ReviewRequired`; stop and return Evidence |

`InstallationAuthorized` deliberately remains `false` even for decision `376`:
this is research selection evidence, not permission to install a driver. CPU
identity, firmware revision and automatic 280 fallback remain prohibited
selection inputs.

The REV69 no-NPU Evidence is accepted as the negative control and is not
repeated for this common self-test-only correction. The minimum-sufficient next
Windows run combines the common transcript regression with the positive NPU
identity gate on an NPU-equipped Windows Client:

```powershell
.\Invoke-AmdNpuDriverResearch.ps1 `
  -Stages Test,HardwareIdentity `
  -ResolveHardwareSelection `
  -SkipPublicExport `
  -EvidenceLabel REV70-CycleB-NPU-HardwareIdentity `
  -EvidenceRetention ZipOnly
```

PASS requires final `Pass`, exit code `0`, valid Evidence integrity, complete
automatic local PnP enumeration, the reviewed positive selection described
above, and no transcript terminating-error record for the deliberate
`ExtractedWithErrors` fixture. Stop for review before any full run or Server
execution. See
`project-management/CYCLE-B-HARDWARE-AWARE-TEST-MATRIX-REV70.md`.

## Current accepted gate and retest rule

The prior exact `1.3.3-dev` source has an accepted Windows Server 2025 / Windows
PowerShell `5.1.26100.33296` smoke result: `PathSafety,Test`, 2/2 PASS, final
`Pass`, exit code `0`, with an independently verified Evidence ZIP and manifest.
It is a regression reference, not qualification of the changed `3.0.0` source.

This is a no-NPU-safe environment/common-contract smoke. It does not qualify an
NPU-equipped Server, driver installation/load, device start, XRT operation or a
workload. The separate built/self-signed-driver positive Server case remains
deferred until the production build pipeline is available. Documentation-only
changes do not invalidate accepted executable evidence and SHALL NOT trigger a
ceremonial rerun. Historical revision gates below are retained regression
fixtures and are not automatically pending user actions.

For the historical REV69 `3.0.0` Cycle B candidate, the minimum direct smoke
command was:

```powershell
.\Invoke-AmdNpuDriverResearch.ps1 `
  -Stages PathSafety,Test `
  -SkipPublicExport
```

There is no release-included cross-tool test launcher.

## REV69 Cycle B qualification and regeneration gate

The exact `3.0.0` source SHALL parse without error, declare
`#requires -Version 5.1`, pass UTF-8 BOM + CRLF checks, and pass
`PathSafety,Test` with the repinned common-core contract. On an NPU-equipped,
short-path Windows Client workspace, first run the bounded identity gate:

```powershell
.\Invoke-AmdNpuDriverResearch.ps1 `
  -Stages Test,HardwareIdentity `
  -ResolveHardwareSelection `
  -SkipPublicExport `
  -EvidenceLabel REV69-CycleB-NPU-HardwareIdentity `
  -EvidenceRetention ZipOnly
```

After its Evidence is reviewed, run the full regeneration command:

```powershell
.\Invoke-AmdNpuDriverResearch.ps1 `
  -EvidenceLabel REV69-CycleB-NPU-WindowsClient `
  -EvidenceRetention ZipOnly
```

Omitting `-Stages` deliberately selects `All`. Do not add `-SkipPublicExport`.
Acceptance requires final `Pass`, exit code `0`, a verified Evidence ZIP and
manifest, and a complete new `public/**` tree that passes schema `1.3`/`1.1`, canonical-byte, privacy and
provenance validation. This run retires the REV68 frozen-public exception only
after independent review. Windows Server remains a separate, later gate.

## Rev61 public-schema authority regression gate

The submitted exact REV60 NPU evidence SHALL reproduce Build PASS followed by the sole Validate failure `processor-driver applicability public schema mismatch: 1.1`. Source and schema inspection SHALL establish that generation and `processor-driver-applicability.schema.json` agree on `1.1`, while only the old validator required `1.0`. The corrected `PathSafety,Test` run SHALL pass the new two-schema contract. A direct consistency replay against a complete generated public dataset SHALL accept applicability `1.1`. Chipset's submitted exact-source full run remains accepted; Graphics is unchanged because the stale literal is NPU-specific.

## Rev60 public-null structure regression gate

`PathSafety,Test` SHALL pass the sanitizer fixture proving that explicit null properties and null array items survive while `ArchivePath`, `OutputDirectory` and private error text remain absent. The submitted REV59 processor catalog SHALL replay with 112/112 `productIdTray` properties present, 105 intentional null values, successful Markdown generation and no change to the 165-function common contract. A finite exact-source Windows PowerShell 5.1 NPU full run is required to close Build/Validate publication behavior; Chipset is not repeated.

## Rev59 publication-path regression gate

`PathSafety,Test` SHALL pass the recursive publication-sanitizer fixture, updated architecture-convergence contract and 165-function common contract. The fixture SHALL remove nested `ArchivePath`, `OutputDirectory` and runtime error text while retaining public relative paths and `/SETFILTERUSB`. No NPU package download or lane retest is required for this publication-only local gate.

## Rev58 path-safety correction gate

At the historical REV58 gate, `PathSafety,Test` SHALL pass with the
162-function common contract and the updated architecture-convergence hash.
Source inspection SHALL prove removal of runtime `_containers`/stem/hash
directory construction and removal of `ExtractedWithErrors` from the accepted
downstream set. Its then-pending Windows PowerShell 5.1 prerequisite has since
been satisfied by the accepted later gates.



## Rev52 reviewed Windows PowerShell 5.1 gate

The exact rev51 source (`b0476ed91a70eb7e8e6b81900448441810deca55b86e9becb7e611cdd2f3b53c`)
passed Test on Windows PowerShell 5.1.26100.9168 in 4.77 seconds (5.48 seconds
total). The supplied ZIP passed archive integrity and all 68 manifest entries
matched their declared size and SHA-256. Rev52 local regression additionally
requires the five-event normal diagnostic lifecycle and an isolated Ctrl+C
probe that persists `INTERRUPTED`.

## Rev51 common regression gate

PS7.6.5 clean-copy execution completed all modified source, architecture,
Canonical JSON, signature and evidence self-tests. The development container
lacked 7-Zip, so the final NPU Test stage correctly remained REVIEW for that
dependency only. Forced normal-finalizer failure produced a verified emergency
ZIP/SHA-256 and retained raw evidence. Windows PowerShell 5.1 remains a separate
pending real-host gate.

## Rev50 Canonical JSON short gate

Run `-Stages Test -SkipPublicExport -EvidenceRetention ZipOnly`. The generated
test-stage evidence schema is `amd-npu-test-stage-evidence/1.1` and requires a
passing `CanonicalJsonCrossRuntimeContract`. No package acquisition, extraction
or full certificate scan is required.

This document defines how to verify the v1.0.0 source and stable contract in `SPEC.md`. Final release acceptance requires evidence generated by the exact v1.0.0 script, not a renamed or reused 0.x evidence package.

Testing is deliberately split into source/static gates, research correctness, Windows PowerShell 5.1 behavior, deterministic publication, private Evidence integrity, and separate real-device NPU runtime evidence.

## 1. Test principles

A valid main-tool release requires all of the following independent properties:

1. **Source correctness** — PowerShell parses and passes the repository static-analysis gate.
2. **Research correctness** — reviewed artifacts, PnP/INF hardware-only selection, INF/installer/binary analysis, and retained audit datasets behave as specified.
3. **Artifact-chain integrity** — immutable artifact hashes survive Acquire -> Extract -> Inspect -> Build.
4. **Fail-closed behavior** — unknown/incomplete NPU PnP identity or selector-ineligible builds become `ReviewRequired`; CPU identity is not consulted.
5. **Publication safety** — only repository-safe generated data reaches `public/**`.
6. **Publication byte correctness** — public JSON/Markdown are deterministic and meet their byte contracts.
7. **Evidence integrity** — a failed or successful run is auditable from Evidence whenever the evidence root remains writable.
8. **Cross-runtime reproducibility** — Windows PowerShell 5.1 and Linux/PowerShell 7 generate byte-identical public data for the same source/reviewed corpus.
9. **Runtime-evidence separation** — client runtime and Server runtime are never conflated.

A 13/13 stage PASS does not waive an independent repository PSA/audit gate.

## 2. Output classifications

| Surface | Purpose | Generated Git commit target |
|---|---|---:|
| `public/**` | validated repository-safe generated output | **Yes** |
| `data/**`, `schemas/**`, source/docs | reviewed static repository source | explicit source changes only |
| `private/**` | private execution/host evidence | No |
| `inventory/**` | runtime staging | No |
| `work/**` | downloads/extraction/temp data | No |
| generated runtime reports | local/Evidence review | No automatic commit |

## 3. Source preflight

### 3.1 PowerShell AST

Parse the exact candidate source.

Expected:

```text
AST parse errors = 0
```

### 3.2 Repository PSA/static analyzer

Run the repository-maintained analyzer with the two merged predecessor research tools in the same invocation when the cross-file rule requires peers.

Release gate:

```text
PSA blocking errors = 0
```

Known analyzer false positives SHALL be handled through the repository review/suppression process rather than introducing incorrect code purely to silence a diagnostic.

The 0.8.1-dev remediation specifically requires regression coverage for:

- explicit `-PublicOutputRoot` behavior;
- no dynamic-scope capture of the reviewed top-level parameter set inside NPU orchestration/stage functions.

### 3.3 Source encoding

Verify the root `.ps1`:

```text
UTF-8 BOM = present
CRLF throughout
```

Verify source Markdown:

```text
UTF-8 BOM = absent
CR byte count = 0
LF line endings
```

### 3.4 Built-in Test stage

```powershell
.\Invoke-AmdNpuDriverResearch.ps1 -Stages Test
```

Acceptance includes:

- predecessor shared-core contract healthy;
- architecture convergence contract healthy;
- 7-Zip qualification available for full extraction;
- all 13 reviewed source-data files have registered schema/version contracts and matching `schemas/source-data/**` schemas;
- explicit public-output-root resolver regression passes;
- publication/canonical JSON support tests pass.

## 4. Reviewed artifact corpus regression

The normal public corpus SHALL resolve to the following immutable identities:

```text
NPU_RAI1.5_280_WHQL.zip
a278a2c92cdc47e0da4cab2cbdb5347a127eee67311927578f4e151618446ce4

NPU_RAI_280_WHQL.zip
803afe1e2d75b717f60a368453306ccbd4877cdd936b6531b946b95109a22144

NPU_RAI_376_WHQL.zip
aa836cbfcad5d0782c79b58f197aa50624af37e7cb8311c5f94d85b0dc3ccaad
```

Acquisition SHALL reject a byte-different artifact when it is being treated as one of these reviewed identities.

The restricted/private 314 control is:

```text
NPU_RAI1.6.1_314_WHQL.zip
023caa295d3b2fe4befccdba84db5867abb6428a5e057ac1acdbda03853cf0ac
```

It SHALL remain manual/private and SHALL never become a recommendation winner.

### 4.1 Dual-line research-corpus regression

A normal full research run SHALL retain the later public 280 and 376 artifacts and produce comparison evidence for the two lines. The historical Ryzen AI 1.5 280 artifact remains a regression fixture.

It is valid for reviewed recommendation logic to prefer 376 while 280 remains in the research corpus. Removing 280 because 376 is the current recommendation winner is a regression failure.

## 5. Normal full-run qualification

Run:

```powershell
.\Invoke-AmdNpuDriverResearch.ps1
```

Expected stage set:

```text
Test
HardwareIdentity
ProcessorCatalog
Discover
Metadata
Acquire
Extract
Inspect
DriverBinary
Compare
Matrix
Build
Validate
```

For the current reviewed corpus and 0.9.0-dev source data, expected generated counts are:

```text
Processor catalog       112
Compatibility rows      336
Processor selections    112
Applicability rows      112
ReviewRequired           28
Public files              23
```

Counts are a regression aid, not a permanent v1.0.0 protocol constant. If reviewed source data changes intentionally, update the source and the expected test baseline together.

## 6. Hardware-only selection regression (current authority)

The Test stage SHALL validate `data/hardware-driver-selection.json` and execute
five deterministic resolver cases:

| Case | Input | Build | Expected |
|---|---|---:|---|
| Phoenix broad INF model | `PCI\VEN_1022&DEV_1502` | 26100 | `376` |
| full observed Strix-style PnP ID | `PCI\VEN_1022&DEV_17F0&SUBSYS_20CF1043&REV_10` | 26100 | `376` |
| unknown enumerated NPU ID | `PCI\VEN_1022&DEV_FFFF...` | 26100 | `ReviewRequired` |
| explicitly completed empty NPU enumeration | empty | 26100 | `NoNpuDriverRequired` |
| reviewed INF model below build floor | `PCI\VEN_1022&DEV_17F0` | 20348 | `ReviewRequired` |

Every case SHALL prove `CpuIdentityUsed=false`,
`FirmwareDeviceRevisionUsed=false`, `InstallationAuthorized=false`, and zero
automatic `280` decisions. The 376 case SHALL additionally prove
`Automatic280FallbackEnabled=false`.

The command-level positive control is:

```powershell
.\Invoke-AmdNpuDriverResearch.ps1 `
  -Stages Test,HardwareIdentity `
  -ResolveHardwareSelection `
  -ObservedNpuHardwareId 'PCI\VEN_1022&DEV_17F0&SUBSYS_20CF1043&REV_10' `
  -TargetWindowsBuild 26100 `
  -SkipPublicExport
```

Expected decision is `376`, with the reviewed artifact/INF hashes and no
installation or Server-runtime claim. The switch SHALL require the
`HardwareIdentity` stage and a positive target build. An empty input is meaningful
only when resolution is explicitly requested after completed enumeration.

Multiple NPU device instances SHALL be resolved separately.

## 6A. Exact-SKU / fail-closed dataset regression (retained audit output)

At minimum verify representative rows:

### 6A.1 Historical two-package device-selection boundary

The 280 and 376 packages SHALL continue to be evaluated as research inputs. The
processor rows below are retained regression/audit fixtures and SHALL NOT be used
by the hardware-only driver-track resolver.

Examples include:

- Ryzen 9 7940HS / Phoenix;
- Ryzen 7 8845HS / Hawk Point;
- Ryzen AI 9 HX 370 / Strix Point;
- Ryzen AI 7 350 / Krackan Point;
- Ryzen AI Max+ 395 / Strix Halo;
- Ryzen AI Z2 Extreme / reviewed Strix Point relation.

The historical processor dataset may continue to preserve its prior decision:

```text
ReviewRequired
```

The test SHALL also prove that the historical `NPU_RAI1.5_280_WHQL.zip` cannot
become a current recommendation and that no global 280-versus-376 maximum-version
comparison occurs.

The Test stage SHALL separately prove the full-research/certificate scope
contract:

1. the default full-scope acquisition set contains all three reviewed public
   artifacts, including historical RAI1.5;
2. the default certificate-verification plan excludes RAI1.5 and selects the
   newest artifact inside each current NPU-type case;
3. a single explicit historical `-ArtifactId` produces `OnlySelectedArtifact`,
   matching Chipset's explicit single-release behavior;
4. a numerically larger historical version cannot defeat a current-case
   certificate target;
5. recommendation eligibility remains independent of both scopes.

The Test stage also runs the signature-engine regression suite. It covers CMS
primitive parsing, content-type routing, PE/Authenticode digest handling,
toolchain parser behavior, SignTool profile construction, kernel catalog-bound
coverage classification, locale-neutral native-result classification, Windows
catalog/localization interop type contracts, schema bindings, and NPU execution-
plan consumption.

On a non-Windows qualification host these tests prove the static engine and the
native command/evidence contracts, but do not claim execution of Windows
Authenticode, catalog APIs, WinTrust or SignTool. An end-to-end synthetic local
NPU package test SHALL additionally exercise `Test -> Acquire -> Extract ->
Inspect -> Signature` with a real Authenticode-bearing PE and a CMS catalog
fixture.

The next native gate SHALL be one reviewed Windows Client run using the exact
candidate source and selected current NPU artifacts. Acceptance requires the
expected package-case target count, parse/digest integrity, catalog correlation,
all SignTool profile records, locale-independent process result classes, and an
unmodified-package assertion. Windows Server execution is a separate later gate
and SHALL NOT be requested automatically from successful Client evidence.

The gate SHALL use `-RequireWindowsClientSignatureQualification`. This switch
turns every acceptance condition above into an executable fail-closed result
rather than relying on a reviewer to infer success from a generic stage PASS.
The Test stage includes positive and negative qualification-assessment fixtures;
the negative fixture proves that an unavailable SignTool cannot pass.

### 6A.2 Gorgon Point audit row

A reviewed Gorgon Point exact SKU MAY match broad `DEV_17F0` and MAY have driver-binary generation-recognition evidence.

Without reviewed 376 published-family support, expected decision remains:

```text
ReviewRequired
```

### 6A.3 Gorgon Halo audit row

Published processor/NPU capability without reviewed exact NPU identity/artifact support SHALL remain:

```text
ReviewRequired
```

### 6A.4 Negative-control audit rows

Exact SKUs with reviewed NPU unavailability/no-published-NPU capability SHALL produce:

```text
NoNpuDriverRequired
```

The test SHALL prove that a similar product name or architecture does not synthesize NPU capability.

### 6A.5 Unknown processor audit row

A name not present in the reviewed exact-SKU catalog SHALL fail closed inside the
retained audit dataset. It SHALL NOT influence hardware-only track resolution.

## 7. Identity-layer regression

Tests/review SHALL keep these values distinct:

```text
PCI DEV
PCI REV_XX
quicktest-style class
XRT device name
XRT firmware version
firmware device revision
```

The Ryzen AI Z2 Extreme reviewed client observation is a useful positive control:

```text
DEV_17F0
PCI REV_10
quicktest-style STX
XRT NPU Strix
firmware version 1.1.2.64
firmware device revision unresolved
```

A regression that derives STXA/STXB directly from `REV_10` or from firmware version SHALL fail review.

## 8. INF and Server static applicability regression

For reviewed 280/314/376 INFs verify:

```text
NTamd64.10.0...22000
DEV_1502
DEV_17F0
```

Verify that the TargetOSVersion parser does **not** synthesize ProductType=1.

Expected static Server profile interpretation:

| Server | Expected published selector result |
|---|---|
| 2016 | build-floor rejected |
| 2019 | build-floor rejected |
| 2022 | build-floor rejected |
| 2025 | static candidate |

No row may claim Server runtime proof solely from this result.

## 9. Installer routing regression

For the reviewed exact installer contracts verify the recovered relevant thresholds remain bound to the exact hash contract:

```text
26100
22621
UBR 3527
22000
```

Verify route classification and package-content presence separately.

The current reviewed artifacts SHALL report the MCDM path present and the installer-referenced lower-build WDF path absent.

A future unknown installer hash SHALL NOT silently inherit the reviewed route contract.

## 10. Driver-binary refinement regression

For the reviewed 376 `ipustack.sys` exact hash verify the reviewed device-revision refinement semantics remain intact.

At minimum test:

```text
1/2 -> Strix
3/4 -> Krackan
5   -> Strix Halo
6/7/8 -> Gorgon Point
9/unknown -> fallback
```

Verify the data model labels this as firmware device-revision evidence and not PCI revision.

Binary recognition SHALL NOT satisfy the independent published-support gate.

## 11. Private 314 qualification regression

When the 314 artifact is supplied manually through `-PackagePath`:

- it may be statically extracted/analyzed;
- its INF/HWID/build-floor observations may be compared;
- it may appear in private/review-oriented applicability context where designed;
- it SHALL NOT be added to the public automatic acquisition catalog;
- it SHALL NOT become the recommended deployment artifact;
- no public unauthenticated URL SHALL be synthesized.

## 12. Publication/schema validation

Every final public JSON SHALL parse and validate against the matching schema where a schema is defined.

In addition, every one of the 13 reviewed `data/*.json` source files SHALL validate against its matching `schemas/source-data/*.source.schema.json` schema. The Test stage SHALL fail when a data file is unregistered, its schema is missing, or its `schemaVersion` differs from the explicit source-data contract.

The current 0.9.0-dev publication includes schema coverage for release/comparison/catalog/matrix/applicability/manifest documents.

Cross-dataset validation SHALL reject at least:

- applicability pointing to an unknown processor;
- recommendation inconsistent with the compatibility selection;
- private artifact recommendation;
- malformed observed-runtime evidence arrays;
- Server runtime proof leaking from a client-only observation.

### 12.1 Authored CPU/NPU workbook validation (human audit only)

The reviewed English workbook under `authored/**` SHALL:

- open successfully with eight named worksheets;
- retain 742 AMD catalog rows and 145 NPU candidate rows from the reviewed source snapshot;
- contain no spreadsheet formula errors;
- preserve the historical reviewed row split for human audit without promoting it into driver-selection authority;
- identify the exact reviewed 280 and 376 artifact hashes and roles;
- keep user-facing labels, guidance, and assessment text in English; and
- remain outside generated `public/**` and the publication manifest.

## 13. Public byte contract

Every final `.md` under `public/**` SHALL satisfy:

```text
UTF-8 BOM = absent
CR byte count = 0
LF only
```

Every generated public JSON SHALL use deterministic canonical serialization.

The same source/reviewed input corpus SHALL generate the same public bytes on supported runtimes.

## 14. Publication manifest verification

For each manifested public payload verify:

- file exists;
- relative path uses `/`;
- size matches;
- SHA-256 matches;
- source/generation classification is correct;
- `HandEdited` is false;
- expected file set matches the manifest/publication contract;
- source script hash binding matches the exact candidate where applicable.

Generated public files SHALL NOT be corrected manually after generation.

## 15. Privacy verification

Independent qualification SHOULD scan decoded JSON scalar values and public text for concrete private values taken from the Evidence/run environment.

Include at least:

- host work root;
- evidence root/run ID;
- user-profile path if present;
- local tool path where private;
- machine/device-instance identifiers present only in private evidence;
- credentials/key/token patterns.

Private host evidence may contain raw vendor output such as XRT hostname fields. That is acceptable only on the private side and SHALL be declared honestly in collector privacy metadata.

## 16. Evidence ZIP integrity

The Evidence archive SHOULD contain the exact source snapshot and run artifacts needed to reproduce/review the run without embedding vendor packages by default.

Verify `evidence-manifest.json` independently:

```text
missing files = 0
length mismatches = 0
SHA-256 mismatches = 0
```

Verify `run-summary.json` source SHA equals the candidate root script SHA.

Failure-path testing SHALL confirm an ordinary stage failure still attempts Evidence finalization and a fatal bootstrap error uses the emergency evidence path where the output root remains writable.

## 17. 0.9.0-dev Linux qualification result (historical pre-remediation baseline)

Accepted Linux development Evidence:

```text
File:
AmdNpuDriverResearchEvidence-0.9.0-dev-Linux-user-test-candidate.zip

SHA-256:
ec8b8923248ee5cadde662b9a17c95474cd2f66a13516d31b9164921ad90c391
```

Observed environment/result:

```text
PowerShell        7.6.4
Mode              local replay of 3 reviewed public artifacts
Stages            13 / 13 PASS
OverallStatus     Pass
ExitCode           0
Matrix             336 rows
Selections         112
Applicability      112
ReviewRequired      28
Script SHA-256      90856ed5342e74a766c6c0b90e0b57565fe91c571487629cfea77b2cba2b4317
```

This is static/offline qualification, not a Windows runtime test.

## 18. 0.9.0-dev Windows PowerShell 5.1 qualification result (historical pre-remediation baseline)

User-provided Windows Evidence:

```text
File:
AmdNpuDriverResearchEvidence_20260813-174435_Windows.zip

SHA-256:
b4c7d6438ecdb05ac09ee22019e22752a9abeaa4ed8fd7301a47899451d2cd45
```

User-provided generated public ZIP:

```text
File:
public(20260813-174602).zip

SHA-256:
69e2a8a558456605f1f9e896c18bc1c7d52abeeaa1e4e1ee492c37907a101f57
```

Observed environment/result from `run-summary.json`:

```text
PowerShell        5.1.26100.9168 / Desktop
Platform          Windows AMD64
Stages            13 / 13 PASS
OverallStatus     Pass
ExitCode           0
Duration           62.310 s
InputCount          3
Matrix             336 rows
Selections         112
Applicability      112
ReviewRequired      28
Public files         23
Script SHA-256      90856ed5342e74a766c6c0b90e0b57565fe91c571487629cfea77b2cba2b4317
```

The Windows run used the normal DownloadOrCache acquisition path and accepted the three reviewed public artifact hashes.

Safety summary:

```text
VendorExecutablesExecuted = false
VendorPayloadModified      = false
```

The run's Validate stage reported publication privacy/dataset/JSON/Markdown validation PASS.

## 19. Cross-runtime deterministic publication result (historical pre-remediation baseline)

For the accepted 0.9.0-dev candidate, the Windows PowerShell 5.1 generated public tree was compared with the Linux/PowerShell 7 generated public tree for the same source/reviewed corpus.

Result:

```text
Windows public files = 23
Linux public files   = 23
Only Windows         = 0
Only Linux           = 0
Different            = 0
Byte-identical       = 23 / 23
```

This is a release-quality result for deterministic publication, not NPU device runtime compatibility.

## 20. Companion collector testing

The companion hardware collector has its own test contract under `tools/TESTING.md`.

Main-tool release qualification SHALL NOT silently claim collector v1.3.0
real-device qualification unless one exact-source NPU-positive run has actually
been performed, reviewed and retained. That gate is dependency-blocked until
production NPU driver build-script redevelopment, review and separately
authorized Server driver application are complete. It is not a current
main-tool release test request.

Existing older Ryzen AI Z2 Extreme evidence remains valid research evidence; it
does not retroactively qualify the new v1.3.0 selection-input and integrity
contract.

## 21. 0.9.1-dev audit-remediation qualification

Linux / PowerShell 7.6.4 remediation qualification after independent audit report #2:

```text
Source SHA-256       22036b61d64af2d272d011dadb381e41b850719d5bbc3f4efc3450c9d94aee07
Full replay          13 / 13 PASS
ExitCode             0
Source data schemas  12 / 12 PASS (external Draft 2020-12 validation)
Matrix rows          336
Selections           112
Applicability rows   112
ReviewRequired       28
```

Partial-stage negative controls:

| Invocation | Expected/observed |
|---|---|
| `-Stages Compare` | `BLOCKED`, exit 2; missing `Inspect` prerequisite |
| `-Stages DriverBinary` | `BLOCKED`, exit 2; missing `Inspect` prerequisite |
| `-Stages Matrix` | `BLOCKED`, exit 2; missing `Inspect` prerequisite |
| `-Stages Build` | `BLOCKED`, exit 2; missing `Inspect` prerequisite |

Windows PowerShell 5.1 qualification for the 0.9.1-dev script hash subsequently completed successfully: PowerShell 5.1.26100.9168, 13/13 stages PASS, exit code 0, with `ScriptSha256=22036b61d64af2d272d011dadb381e41b850719d5bbc3f4efc3450c9d94aee07`. This remains pre-release evidence only; v1.0.0 requires a fresh run from the actual v1.0.0 source.

## 22. Historical v1.0.0 release acceptance checklist

Before stable v1.0.0, verify:

- [x] exact candidate source AST parse = 0 errors;
- [x] repository PSA/Claude static-analysis gate accepted through Audit #3;
- [x] built-in Test stage PASS;
- [x] 3 reviewed public artifact hashes match;
- [x] full Linux/PowerShell 7 qualification PASS;
- [x] full Windows PowerShell 5.1 qualification PASS on the exact v1.0.0 script;
- [x] expected processor/matrix/applicability invariants PASS;
- [x] Gorgon Point/Gorgon Halo remain fail-closed unless stronger evidence has been deliberately added;
- [x] private 314 remains non-public/non-recommendable;
- [x] schemas and cross-dataset validation PASS;
- [x] publication privacy PASS;
- [x] publication manifest hash/length/source checks PASS;
- [x] Windows/Linux `public/**` deterministic comparison PASS (23/23 byte-identical);
- [x] documentation matches the final data/contracts and v1.0.0 qualification evidence;
- [x] the exact v1.0.0 source was used to regenerate final publication/evidence; no 0.x evidence is being reused as v1.0.0 qualification;
- [ ] Audit #4 independent release-readiness acceptance;
- [ ] if collector v1.3.0 is later described as real-device qualified, complete and review one exact-source NPU-positive run first; until then retain the current disclaimer.


## 23. v1.0.0 release-qualification preparation status

Audit #3 approved 0.9.1-dev and closed A-01/A-02/A-03. The actual source version was then bumped to `1.0.0`.

The v1.0.0 Test stage additionally validates that the `.NOTES` `Tool version:` line matches `$script:ToolVersion`. A mismatch SHALL fail the Test stage.

Preparation qualification performed on the exact v1.0.0 source:

```text
Script SHA-256        2dc94306ed7f9838a05be21ae2d6f44494446aaeded9ad978d3ebde5be0c04cf
Linux PowerShell      7.6.4
Canonical corpus run  13 / 13 PASS
ExitCode              0
Matrix rows           336
Selections            112
Applicability rows    112
ReviewRequired         28
```

The canonical corpus used for this Linux preparation run is byte-identical to the reviewed public artifacts:

```text
NPU_RAI1.5_280_WHQL.zip  a278a2c92cdc47e0da4cab2cbdb5347a127eee67311927578f4e151618446ce4
NPU_RAI_280_WHQL.zip     803afe1e2d75b717f60a368453306ccbd4877cdd936b6531b946b95109a22144
NPU_RAI_376_WHQL.zip     aa836cbfcad5d0782c79b58f197aa50624af37e7cb8311c5f94d85b0dc3ccaad
```

The first clean automatic-acquisition attempt from the Linux preparation environment correctly failed closed because that environment temporarily could not resolve `download.amd.com`; Acquire failed and every dependent stage became `BLOCKED`. That failure is retained as release-preparation evidence but does not qualify vendor re-acquisition.

Final main-toolkit release-candidate qualification completed on the exact v1.0.0 script:

```text
Windows Evidence       AmdNpuDriverResearchEvidence_20260814-060553_Windows.zip
Windows PS             5.1.26100.9168 / Desktop
Windows result         13 / 13 PASS, ExitCode 0
Windows acquisition    PackagePath=[]; three reviewed artifacts recorded as Downloaded
Windows public ZIP     public(20260814-060739).zip
Linux Evidence         AmdNpuDriverResearchEvidence_20260814-055908_Linux_v1.0.0-Linux-canonical-corpus-qualification.zip
Linux PS               7.6.4 / Core
Linux result           13 / 13 PASS, ExitCode 0
Script SHA-256         2dc94306ed7f9838a05be21ae2d6f44494446aaeded9ad978d3ebde5be0c04cf
Cross-runtime public   23 / 23 byte-identical
```

The Linux preparation environment could not complete live AMD CDN acquisition, so its successful qualification used the canonical reviewed corpus. The Windows run supplies the required fresh automatic re-acquisition evidence. Both runs bind to the same v1.0.0 script SHA and produce byte-identical publication output.

Diff lever against 0.9.1-dev after canonical regeneration:

```text
public files total      23
changed JSON            12
unchanged Markdown      11 / 11
added/removed files      0 / 0
```

If any Markdown file changes during the final clean re-acquisition, document the data/source reason before release; do not attribute it to the version bump alone.

## 24. v1.2.2 Windows PowerShell 5.1 cardinality regression

The first v1.2.1-dev Windows Client Gate A attempt failed in `Test` at
`Get-NpuCertificateVerificationTargetPlan`. Windows PowerShell 5.1 enumerated
the result of `$selected = if (...) { ... }`; the explicit historical-only
scope fixture therefore became a scalar and StrictMode rejected
`$selected.Count`.

v1.2.2-dev requires all of the following before a second real-machine attempt:

- the complete conditional selection expression is protected with `@(...)`;
- the existing zero/one/many PowerShell 5.1 cardinality self-test is executed by
  the NPU Test stage;
- the source-contract audit is executed by the NPU Test stage and rejects a
  direct conditional assignment followed by `.Count` in the same function;
- the three research/certificate-scope cases still pass without changing the
  two-current-package-case selection policy;
- the synthetic `Test,Acquire,Extract,Inspect,Signature` fixture passes with
  zero CMS parse failures and zero PE digest mismatches.

The exact 1.2.2-dev source subsequently passed Gate A on Windows PowerShell 5.1
and its Evidence was reviewed and accepted. The 1.2.3-dev follow-up changes only
operator messages and transcript completeness. Its local Test includes an
operator-message regression that prohibits ambiguous `targets=2/3`,
`SharedAcquisition`, `SharedExtraction` and Chipset-only release terminology.
The staged synthetic signature fixture must also remain PASS with zero CMS parse
failures and zero PE digest mismatches.

## 25. v1.3.0-dev hardware-only finalization gate — failed and superseded

The signature engine is unchanged from the accepted Client gate, but the exact
source now contains new PowerShell 5.1 resolver code and Test-stage source-data
contracts. Stable promotion therefore requires one minimum-sufficient Windows
Client run; no Server execution is authorized by this gate.

Hypothesis:

> On Windows PowerShell 5.1, the exact v1.3.0-dev source validates all 13 reviewed
> source-data contracts and five hardware-only resolver cases, then resolves the
> Z2 positive-control PnP identity to 376 without CPU or firmware input and without
> enabling 280 fallback.

Command:

```powershell
.\Invoke-AmdNpuDriverResearch.ps1 `
  -Stages Test,HardwareIdentity `
  -ResolveHardwareSelection `
  -ObservedNpuHardwareId 'PCI\VEN_1022&DEV_17F0&SUBSYS_20CF1043&REV_10' `
  -TargetWindowsBuild 26100 `
  -SkipPublicExport `
  -EvidenceLabel NPU-1.3.0-Hardware-Only-Final-Gate-A
```

PASS evidence:

- both selected stages report PASS and final exit code is 0;
- source-data contract count is 13 and hardware-only self-test count is 5;
- `inventory/hardware-selection-result.json` reports `Decision=376`;
- selected artifact SHA-256 is
  `aa836cbfcad5d0782c79b58f197aa50624af37e7cb8311c5f94d85b0dc3ccaad`;
- selected INF SHA-256 is
  `c2a448340a9e802faa81b7c03fda0009d52cbfe86be5e915134dac39ab9c8008`;
- `CpuIdentityUsed=false`, `FirmwareDeviceRevisionUsed=false`,
  `Automatic280FallbackEnabled=false`, `InstallationAuthorized=false`, and
  `WindowsServerRuntimeProof=false`;
- an Evidence ZIP and SHA-256 are produced.

A no-NPU Windows Client ran this command and returned Evidence SHA-256
`34d30ab4d61d6153ac1b41c4ea795d10ae86c2f39e0bc598337a07d823507695`.
`Test` failed before `HardwareIdentity` because a clean Windows PowerShell 5.1
process did not already have `System.Security` loaded and the fallback used a
partial assembly name. The command also supplied a Z2 identity manually, so it
was not a valid local no-NPU test. This gate is rejected and superseded by section 26.

## 26. v1.3.1-dev automatic-PnP no-NPU Client gate

Hypothesis:

> On a Windows Client with no NPU, the exact v1.3.1-dev source resolves
> `SignedCms` in a clean Windows PowerShell 5.1 process, completes local PnP and
> Windows-build collection without a manual identity, passes 13 source-data
> contracts and ten hardware-only tests, and returns `NoNpuDriverRequired`.

Command:

```powershell
.\Invoke-AmdNpuDriverResearch.ps1 `
  -Stages Test,HardwareIdentity `
  -ResolveHardwareSelection `
  -SkipPublicExport `
  -EvidenceLabel NPU-1.3.1-Automatic-PnP-NoNpu-Gate-A
```

PASS evidence:

- both stages report PASS and final exit code is 0;
- source-data contract count is 13 and hardware-only test count is 10;
- the signature primitive self-test reports `SignedCmsAvailable=true`;
- `inventory/hardware-selection-result.json` reports
  `Decision=NoNpuDriverRequired`, `InputSource=LocalWindowsPnP`,
  `LocalEnumerationPerformed=true`, `ManualOverrideUsed=false`,
  `EnumerationStatus=Complete`, and `CandidateDeviceCount=0`;
- the result contains the automatically observed Windows build and source;
- CPU/firmware inputs, 280 fallback, installation authorization and Server
  runtime proof remain false;
- an Evidence ZIP and SHA-256 are produced.

A PASS enables review of the no-NPU negative control and, only after that review,
authorization of one separate NPU-equipped Client positive-control run. It does
not enable Windows Server execution, driver installation, deployment, INF
conversion, certificate work, re-signing, or removal of 280 from research.

Actual result:

- Evidence SHA-256:
  `c7cce5ac6af42174f2c8137dd0e6dd07b51f3e5700b5d423af90cfce1560b638`;
- Windows 11 Pro build 26200, Windows PowerShell 5.1.26100.9168;
- `Test` and `HardwareIdentity` PASS, exit code 0;
- automatic local PnP input, no manual override, zero candidates, and
  `NoNpuDriverRequired` were reported;
- the deterministic Test implementation proves `SignedCmsAvailable=true`
  because the signature primitive self-test cannot pass otherwise.

The functional negative-control behavior is accepted. Archive review found that
`Invoke-NpuEvidenceSnapshot` did not copy the generated local-PnP and selection
JSON, and the Test-stage SignedCms result was not independently serialized.
Therefore section 26 does not close the Evidence-archive gate and is superseded
for audit closure by section 27.

## 27. v1.3.2-dev Evidence-snapshot no-NPU Client gate

Hypothesis:

> On the same no-NPU Windows Client class, the exact v1.3.2-dev source preserves
> the already accepted automatic-PnP behavior while adding all three required
> machine-readable runtime artifacts to the hash-manifested Evidence ZIP.

Command:

```powershell
.\Invoke-AmdNpuDriverResearch.ps1 `
  -Stages Test,HardwareIdentity `
  -ResolveHardwareSelection `
  -SkipPublicExport `
  -EvidenceLabel NPU-1.3.2-Evidence-Snapshot-NoNpu-Gate-A
```

PASS evidence:

- both stages report PASS and final exit code is 0;
- source-data contract count is 13, hardware-only test count is 10, signature
  self-test count is 14, and Evidence-snapshot self-test count is 1;
- `snapshot/inventory/test-stage-evidence.json` reports `Status=Pass`,
  `SignedCmsAvailable=true`, `EvidenceSnapshotContract.Status=Pass`, and empty
  missing/duplicate lists;
- `snapshot/inventory/local-npu-pnp-evidence.json` reports
  `EnumerationStatus=Complete`, `InputSource=LocalWindowsPnP`, and zero candidate
  devices;
- `snapshot/inventory/hardware-selection-result.json` reports
  `Decision=NoNpuDriverRequired`, `LocalEnumerationPerformed=true`,
  `ManualOverrideUsed=false`, `EnumerationStatus=Complete`, and
  `CandidateDeviceCount=0`;
- the selection result keeps CPU/firmware inputs, automatic 280 fallback,
  installation authorization and Server runtime proof false;
- all three runtime artifacts appear in `evidence-manifest.json`, and independent
  length/SHA-256 verification reports zero mismatch.

A PASS closes only the no-NPU Client Evidence-archive gate. The returned ZIP
must be reviewed before one separate NPU-equipped Windows Client positive-control
run is authorized. It does not authorize Windows Server execution, driver
installation, deployment, INF conversion, certificate work, re-signing, or
automatic 280 selection/fallback.

Actual reviewed result:

- Evidence SHA-256:
  `11833ca68ceda6969db6ee15ab55bb3310b658852eedd77b08111c09820e5894`;
- exact script SHA-256:
  `6cb5d024178bf6c3ea56b343acd03608f8eda2a5694e3a5768aefee9dcddd775`;
- Test and HardwareIdentity PASS, exit 0;
- complete local PnP enumeration, zero candidates and
  `NoNpuDriverRequired`;
- all three required runtime JSON artifacts parsed successfully;
- Evidence manifest: 69/69 exact length and SHA-256 matches.

This closes the no-NPU Client Evidence gate. It is not rerun for the later
enum-only correction.

## 28. v1.3.3-dev canonical-JSON NPU-equipped Client gate

The first v1.3.2-dev NPU-equipped run is retained as functional evidence:
automatic local PnP detected one `DEV_17F0` / `IpuMcdmDriver` instance and
resolved it to 376 without CPU, firmware or manual-ID input. Its Evidence SHA-256
is `a29c570fc99492b174d965af3cf8544dbcc30fd5f08653bcd32c8696d84751d7`.
The gate is not accepted because `local-npu-pnp-evidence.json` emitted
`ConfigManagerErrorCode=CM_PROB_NONE` as an unquoted invalid JSON token.

Hypothesis:

> On the same NPU-equipped Windows Client class, the exact v1.3.3-dev source
> preserves automatic `DEV_17F0` to 376 resolution while emitting the detailed
> local-PnP enum as valid JSON and rejecting any generated runtime JSON that
> cannot be parsed.

Command:

```powershell
.\Invoke-AmdNpuDriverResearch.ps1 `
  -Stages Test,HardwareIdentity `
  -ResolveHardwareSelection `
  -SkipPublicExport `
  -EvidenceLabel NPU-1.3.3-Canonical-Json-Npu-Positive-Gate-A
```

Do not supply `-ObservedNpuHardwareId`, `-UseObservedNpuHardwareIdOverride`, or
`-TargetWindowsBuild`.

PASS evidence:

- Test and HardwareIdentity report PASS with exit 0;
- Test summary reports one canonical JSON enum self-test;
- `InputSource=LocalWindowsPnP`, `LocalEnumerationPerformed=true`,
  `ManualOverrideUsed=false`, and `EnumerationStatus=Complete`;
- at least one NPU candidate is present and every candidate resolves
  independently to 376;
- the reviewed Z2 positive control contains `DEV_17F0`, service
  `IpuMcdmDriver`, and matched pattern `PCI\VEN_1022&DEV_17F0`;
- `ConfigManagerErrorCode` is a quoted JSON string such as `CM_PROB_NONE`;
- `snapshot/inventory/test-stage-evidence.json`,
  `snapshot/inventory/local-npu-pnp-evidence.json`, and
  `snapshot/inventory/hardware-selection-result.json` all parse as JSON;
- all Evidence-manifest length/SHA-256 rows match;
- CPU/firmware use, automatic 280 fallback, installation authorization and
  Server runtime proof remain false.

A PASS closes only the NPU-equipped Windows Client positive-control gate and
enables stable-promotion planning plus external review. It does not authorize a
Windows Server run, driver installation, deployment, INF conversion,
certificate work, re-signing or automatic 280 selection/fallback.

Actual reviewed result:

- Evidence ZIP SHA-256:
  `990ae4f7a1682a3814078ee5583485966e154c64a4a4872ec28e359b7b1c2c1f`;
- exact script SHA-256:
  `832734e2661951f7ff06cf4c6e357f8aa7c2f1b5a36882503c0062c1b62c1e31`;
- Windows Client build 26200 and Windows PowerShell 5.1.26100.9168;
- Test and HardwareIdentity PASS, exit 0;
- automatic local PnP, no manual override, one `DEV_17F0` /
  `IpuMcdmDriver` candidate, and decision 376;
- selected 376 artifact SHA-256
  `aa836cbfcad5d0782c79b58f197aa50624af37e7cb8311c5f94d85b0dc3ccaad`
  and INF SHA-256
  `c2a448340a9e802faa81b7c03fda0009d52cbfe86be5e915134dac39ab9c8008`
  match the reviewed authority;
- `ConfigManagerErrorCode` is the quoted string `CM_PROB_NONE`;
- all 59 Evidence JSON files parse and all 69 manifest rows match exact length
  and SHA-256;
- CPU/firmware use, automatic 280 fallback, installation authorization and
  Server runtime proof remain false.

This result is accepted and closes the v1.3.3-dev NPU-equipped Windows Client
positive-control gate. No repeat NPU-equipped or no-NPU machine run is required
for this correction. Stable-promotion and external-review planning may proceed,
but Windows Server execution and deployment require separate authorization.

## 29. v1.3.3-dev Windows Server 2025 no-NPU Gate B

Purpose:

> Confirm that the exact v1.3.3-dev source can execute its bounded Test and
> HardwareIdentity paths on an NPU-free Windows Server 2025 host, complete local
> PnP/build collection, fail closed to `NoNpuDriverRequired`, and create a
> complete Evidence archive without installing or modifying a vendor payload.

Command:

```powershell
.\Invoke-AmdNpuDriverResearch.ps1 `
  -Stages Test,HardwareIdentity `
  -ResolveHardwareSelection `
  -SkipPublicExport `
  -EvidenceLabel NPU-1.3.3-WindowsServer-NoNpu-Gate-B
```

Do not supply manual hardware IDs, a target-build override, package stages or
deployment parameters.

Actual reviewed result:

- Evidence ZIP SHA-256:
  `ea640fa31f4fe8b85d29224c41f8efe0072405bf3a3feb3703e07d2b6636ebc1`;
- exact script SHA-256:
  `832734e2661951f7ff06cf4c6e357f8aa7c2f1b5a36882503c0062c1b62c1e31`;
- host evidence: Windows Server 2025 Datacenter, ProductType 3, build 26100;
- runtime: PowerShell 7.6.5 Core;
- Test and HardwareIdentity PASS, exit 0;
- automatic `LocalWindowsPnP`, complete enumeration, no manual override;
- 147 PnP entities and 24 AMD PCI entities scanned, zero NPU candidates;
- `Decision=NoNpuDriverRequired`, no selected track;
- all 59 Evidence JSON files parse and all 69 manifest rows match exact length
  and SHA-256;
- CPU/firmware use, automatic 280 fallback, installation authorization and
  Server NPU runtime proof remain false;
- no vendor executable was run and no vendor payload was modified.

Decision: **Accepted** for Windows Server 2025 plus PowerShell 7.6.5 no-NPU
negative-control and research-tool host-path coverage. The result does not claim
Windows PowerShell 5.1-on-Server coverage and does not prove an NPU driver can
load or operate on Windows Server. No repeat Server no-NPU run is required for
current stable-promotion and external-review planning.

## 30. Deferred collector qualification plan

No additional real-machine run is required for the main 1.3.3-dev
hardware-selection contract. Do not repeat the accepted Client no-NPU, Client
NPU-positive or Server no-NPU controls.

One real-device gate remains only for companion collector 1.3.0, but it is not
currently executable and is not the next task. It is blocked until all of the
following have occurred:

1. production NPU driver build-script redevelopment is complete;
2. that implementation and its evidence are reviewed;
3. Server driver build/sign/application is separately authorized and completed;
4. the intended NPU-positive Server state exists.

Only then may the collector be run once:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass `
  -File .\tools\Collect-AmdNpuHardwareIdentityEvidence.ps1 `
  -SkipXrtSmiProbe `
  -SkipQuicktestSnapshot
```

Windows PowerShell 5.1 is preferred for that future single run because the accepted
Server no-NPU main-runner evidence used PowerShell 7.6.5. This preference adds
useful runtime coverage without creating a second test; it is not permission to
change the applied driver or to retry installation.

Hypothesis:

> Collector 1.3.0 can observe an already-installed custom/self-signed NPU stack
> on Windows Server through machine-readable PnP, INF, service and binary
> evidence, while preserving fail-closed selection-input and package-integrity
> contracts without requiring public-376 equality or XRT.

PASS requires:

- `Host.ExecutionClass=WindowsServer`, ProductType 2 or 3;
- complete enumeration and one or more independently recorded NPU candidates;
- complete HardwareID/CompatibleID/IdentitySet values per candidate;
- service, healthy status, `CM_PROB_NONE`, installed INF/driver and service
  binary observations;
- `ServerPositiveCase.ObservationStatus=NpuRuntimeObservedHealthy`;
- all generated JSON reparses;
- exact manifest set/length/SHA-256 verification;
- ZIP reopen path/count/length/SHA-256 verification;
- no installer, `xrt-smi validate/configure`, or inference workload execution.

After that future run, stop for evidence review. A PASS permits documentation to call
collector 1.3.0 real-device-qualified. It does not authorize deployment,
production support, stable promotion or workload-success claims.

Until the dependency chain is satisfied, record the gate as
`DeferredDependencyBlocked`, request no Server-positive collector execution, and
retain the static/synthetic qualification disclaimer. Main-runner review or
promotion planning does not require this gate if that disclaimer remains.
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

Run only `-Stages Test` after the rev49 correction. Passing requires the Test
stage to pass, `Utf8JsonSyntaxContract.Status` to equal `Pass`, and creation of a
verified Evidence ZIP with its `.zip.sha256` companion and
`LATEST-EVIDENCE.txt`. A full acquisition/signature run is not required.
## rev57 common-core validation gate

Run `PathSafety,Test` before any live NPU acquisition. PASS requires the current three-tool common-core contract, ordinal ordering, shared diagnostic primitives, sequential-download source contract, HTTP retry policy, HTTP download transport, and both path-safety logic tests to pass.

Because the live NPU network transport changed, a later targeted NPU Client acquisition may be justified only after the Test evidence is reviewed. It must state the hypothesis that both independent 280/376 package lanes download atomically and validate completely. Stop after Windows 11 review; do not authorize Windows Server automatically. The deferred positive Server case remains deferred until the production build/re-signing redevelopment is ready.
