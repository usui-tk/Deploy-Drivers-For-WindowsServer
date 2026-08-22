# AMD NPU Driver Research Toolkit

## REV81 coordinated v3.0.0 documentation closeout

Claude closed Cycle B against REV80 with no open findings. The main executable
remains `3.0.0`, byte-identical to the accepted REV77 source. The exact REV74
NPU-equipped Windows Client Gate 2N and exact REV78 Windows Server / Windows
PowerShell 5.1 `PathSafety,Test` gate are accepted/no-repeat. The regenerated
23-file `public/**` surface is the accepted v3.0.0 publication authority; the
former REV68 frozen-public exception is retired.

REV81 updates current-facing documentation only. It does not change the root
script, either function contract, schemas, reviewed data, generated public
output, canonical path, or qualification evidence. No Windows rerun is
required. The NPU-equipped Windows Server positive case remains separately
deferred until the production build pipeline is redeveloped, reviewed and used
under explicit authorization; it does not block this research-tool release.

## REV79 Cycle B final-review freeze

The exact REV78 Windows Server `PathSafety,Test` rerun passed 2/2 stages,
final `Pass`, exit code `0`, with authoritative Server context, an exact 69-row
Evidence manifest and zero Warning/Error diagnostics. Independent recomputation
matched all 37 NPU architecture-contract functions, including the two hashes
corrected by REV78. The gate is accepted/no-repeat.

REV79 changed no executable, schema, generated public data, common contract or
canonical path. It froze the coordinated `3.0.0` candidate for Claude Cycle B
final review, which Claude subsequently closed against REV80. Positive
NPU-equipped Windows Server driver installation/load and workload qualification
remain deferred to the production build-pipeline phase.

## REV78 NPU architecture-contract correction

The exact REV77 NPU source correctly wrote complete Server execution context,
but Test rejected two stale hashes in the NPU-only
`data/architecture-convergence-contract.json`. REV78 regenerates the 37-function
contract from the unchanged exact source and adds packaging validation that
recomputes every listed function hash. The executable remains `3.0.0`; NPU
selection, public data, canonical paths, and the three-tool common contract are
unchanged.

At REV78, only one short NPU Windows Server `PathSafety,Test` rerun was required.
It passed and is accepted/no-repeat. Chipset and Graphics exact-source results
were already accepted and were not repeated.

## REV77 execution-context evidence correction

The executable remains `3.0.0`. REV77 writes the same actual-host
`ExecutionContext` into private `run-context.json` for NPU, Graphics, and
Chipset, including classification, ProductType/role, OS identity, scopes, and
typed collection state. The accepted 23-file NPU `public/**` snapshot and
automatic package-selection authority are unchanged.

The exact REV76 NPU Windows PowerShell 5.1 smoke is accepted as a regression
control, but all three root sources changed together to preserve the common
contract. The short REV77 `PathSafety,Test` retest in `TESTING.md` subsequently
passed; NPU hardware was not required for that gate.

## REV76 previous status

The executable remains `3.0.0`. NPU Gate 2N is accepted/no-repeat with complete
automatic package-376 selection and a validated 23-file generated `public/**`
snapshot already incorporated. The remaining Server action is only the direct
`PathSafety,Test` smoke in `TESTING.md`; NPU presence is not required for those
stages. The NPU-equipped Server driver-install/load case remains deferred until
the production build pipeline is redeveloped. No test launcher is included.

## Current documentation and qualification status

- Executable version: `3.0.0`.
- Coordinated release state: Cycle B closed by Claude at `REV80`; `REV81`
  corrects documentation only before GitHub commit-candidate preparation.
- The exact REV74 short gate passed 2/2 stages and the subsequent NPU-equipped
  Windows Client full run passed 15/15 stages with exit code `0`, automatically
  selected `376`, and produced one self-contained Evidence ZIP. Independent
  review verified its 104/104 Evidence rows, complete 23-file public snapshot,
  22/22 publication payload rows and 12 published schema documents. REV75
  incorporates that exact generated public tree; Gate 2N is accepted/no-repeat.
- The first exact REV73 NPU run used the unchanged canonical tool path and
  proved `PathSafety=PASS`, but Test correctly blocked two packaging-contract
  defects before network activity: one unsafe REV72 manifest-row conditional
  assignment and one stale NPU-only architecture hash. REV74 corrects both
  without changing the path policy or executable version.
- The REV70 NPU-equipped Windows Client identity gate passed and selected the
  reviewed `376` track from complete local PnP evidence. The subsequent full
  run completed 15/15 stages with exit code `0`, but independent validation of
  its generated public ZIP found one release-blocking schema-authority drift:
  the matrix correctly emitted the Windows PnP/INF selection key while the
  shipped matrix schema still required obsolete `NpuIdentityId`.
- REV71 corrected that NPU-only schema `const` and made both Test and Validate
  compare the schema, reviewed hardware-selection authority, and generated
  matrix fail-closed. The tool version remains `3.0.0`.
- The REV71 NPU-equipped Windows Client rerun completed 15/15 stages with exit
  code `0`, selected `376`, and validated the corrected generated public tree.
  Its Evidence ZIP exposed a packaging defect: only the public manifest was
  snapshotted, so independent review still required a separate manual public
  archive. REV72 removes that manual step and makes the Evidence ZIP
  self-contained by copying and byte-verifying validated `public/**` beneath
  `snapshot/public/**`.
- The prior `1.3.3-dev` source completed the accepted Windows Server smoke gate under
  Windows PowerShell `5.1.26100.33296`: `PathSafety,Test`, 2/2 stages PASS,
  final `Pass`, exit code `0`; that exact-source result is retained as a
  regression reference and does not qualify the changed `3.0.0` source.
- The REV68 frozen-public exception is closed by the accepted REV74 full run.
  NPU Client regeneration is complete; the separately bounded Graphics Gate 2G
  also subsequently passed and is accepted/no-repeat.
- This smoke is a no-NPU-safe environment/common-contract check. It does
  **not** establish NPU-equipped Windows Server runtime operation, driver load,
  device start or workload success.
- The reviewed `280`, historical `RAI1.5-280`, and `376` artifacts remain
  independent research records. Automatic package resolution must not rank
  them globally; unresolved or insufficient identity boundaries remain
  `ReviewRequired`.
- The qualification-only cross-tool launcher is excluded from the release.
  Any future included orchestrator requires a separately reviewed
  multi-scenario design.

Historical revision narratives belong in `CHANGELOG.md` and authored records.
This README is the operator entry point; `SPEC.md` is normative, `TESTING.md`
defines gates, and `REVERSE-ENGINEERING-NOTES.md` contains detailed findings
for downstream build/sign/deployment work.

## Historical correction notes

## rev74 PowerShell 5.1 cardinality and NPU contract correction

The self-contained-public validator now protects the entire manifest-row
conditional expression with `@(...)` before using `.Count`. The NPU-only
architecture contract is regenerated from the exact corrected script and no
longer compares REV74 finalization code with a stale REV72-era hash. The
canonical tool path is unchanged and remains valid.

## rev72 self-contained public Evidence correction

After a successful current-run Build, Validate and public promotion, the
Evidence finalizer copies the complete validated `public/**` tree beneath
`snapshot/public/**`. It verifies the source and snapshot path sets, every
payload size and SHA-256 against `publication-manifest.json`, and byte identity
between the live and snapshotted trees. Any missing, extra or changed file
fails Evidence finalization closed; a normal PASS archive is not emitted.

The Evidence ZIP is the only artifact the operator needs to return for this
gate. Post-run manual public ZIP creation is neither required nor accepted as
a substitute for the self-contained Evidence contract.

## rev71 NPU public schema-authority correction

`schemas/driver-compatibility-matrix.schema.json` now requires
`WindowsPnpHardwareIdsMatchedAgainstReviewedInfModels`, matching
`data/hardware-driver-selection.json` and the generated matrix. Test verifies
the schema/source authority contract before package processing, and Validate
checks matrix schema version plus the selection key across schema, reviewed
source and generated output. The REV70 generated public tree remains evidence;
it is not promoted because its manifest is bound to the superseded REV70
script hash. The resulting REV71 run passed its processing stages but exposed
the Evidence packaging gap corrected by REV72.

## rev61 public-schema authority correction

NPU publication now uses each public JSON Schema's `properties.SchemaVersion.const` as the single version authority for generation and consistency validation. This removes the stale `1.0` validator literal that rejected the valid generated processor-driver applicability `1.1` document. The Test stage checks both processor public-schema contracts before package processing.

## rev60 public-null structure correction

The repository-public sanitizer now distinguishes an explicit safe `null` from a rejected private value. Required catalog fields therefore remain present with JSON `null` when the reviewed source has no value. The submitted 112-processor fixture retains all 112 `productIdTray` properties, including 105 intentional nulls, while runtime paths remain excluded.

## rev59 public-path audit hardening

NPU now creates JSON and Markdown from a recursively sanitized public object graph rather than directly serializing runtime analyses. Shared path-bearing fields, logs and host errors are excluded; public relative identities and vendor evidence remain. The same forbidden-pattern, decoded-scalar and path-property primitives are used by all three research tools.

## rev58 path-safety correction

NPU extraction now uses the common short `work\\x\\aNNNN\\cNNNN` layout instead of a timestamped run/stem/hash tree. The shared completeness gate rejects zero, partial, failed, or path-blocked package sets before inspection or signature analysis. NPU identity, 280/376 lane separation and hardware-only selection authority are unchanged.



## rev52 Windows PowerShell 5.1 acceptance and diagnostics

The submitted Windows PowerShell 5.1 Test-only evidence used the exact rev51
source, completed in 5.48 seconds, passed Canonical JSON and all reviewed
contracts, and produced an integrity-valid Evidence ZIP. NPU diagnostic JSONL
now records the complete trace/stage lifecycle. Ctrl+C or pipeline stop is
persisted as `INTERRUPTED` and returns exit code `130`, never PASS.

## rev51 common runtime/evidence hardening

NPU now shares the accelerated embedded .NET Canonical JSON runtime, immediate
bootstrap output, per-check elapsed progress, and independent emergency
evidence ZIP fallback used by Chipset and Graphics. The canonical byte format is
unchanged. Emergency archives retain their raw evidence directory and are
diagnostic/non-PASS artifacts.

## Canonical JSON contract (rev50)

The former NPU-only compact serializer is now a compatibility adapter over the
same Canonical JSON implementation used by Chipset and Graphics. Persisted JSON
is UTF-8 without BOM, LF, two-space indented, insertion ordered and terminated
by exactly one LF. The matching parser preserves date-looking text as text
across Windows PowerShell 5.1 and PowerShell 7.

**Current source version: v3.0.0**  
**Release state: coordinated Cycle B closed release candidate; Client Gate 2N and bounded Server gate accepted/no-repeat**

> The committed `public/**` v1.0.0 processor recommendation dataset is retained as
> historical research output and is not a driver-selection authority. The reviewed
> machine authority is `data/hardware-driver-selection.json`: locally enumerated Windows
> NPU device instances are matched independently against reviewed INF models without CPU input.

> **REV68 frozen-public boundary — resolved:** the earlier v1.0.0 snapshot was
> retained temporarily as historical output and excluded from current-schema
> claims. Cycle B regenerated the complete NPU public surface from the reviewed
> v3.0.0 source/data/schema authorities. The accepted 23-file surface validates
> against the shipped schemas, was incorporated without hand editing, and is
> now the current publication authority. The historical v1.0.0 processor
> dataset remains audit evidence only and is not runtime-selection authority.

`Invoke-AmdNpuDriverResearch.ps1` is the research and evidence layer for AMD Ryzen AI NPU Windows driver work in `Deploy-Drivers-For-WindowsServer`.

The toolkit exists so that later changes to `Deploy-AMDNpuDriverOnWindowsServer.ps1` can be based on reproducible vendor/package/runtime evidence rather than assumptions about a CPU series name, CPU/NPU combination, marketing name, or Windows client installer.

The toolkit is deliberately **research-only and static-first**. It does not install AMD drivers, execute AMD installer EXEs, patch INF files, generate replacement catalogs, install certificates, or claim Windows Server runtime compatibility from static evidence.

## What the toolkit answers

The normal workflow is designed to answer these questions:

1. Which Windows PnP HardwareID/CompatibleID values are selected by each reviewed INF?
2. Does a completely enumerated NPU device instance match the reviewed preferred-production-track INF?
3. Which AMD NPU driver artifacts are publicly obtainable and immutably identified by SHA-256?
4. Which Windows builds are selected by the published INF **without modification**?
5. Does `npu_sw_installer.exe` impose OS routing beyond INF selection?
6. Does the driver binary contain diagnostic generation-identification logic beyond the INF/installer?
7. When must automation stop with `ReviewRequired` rather than infer from CPU, marketing name, firmware or Linux topology?
8. What evidence is client runtime proof, and what still requires Windows Server runtime qualification?

The exact-SKU processor catalog and CPU/NPU workbook remain available for coverage,
provenance and human audit. They are explicitly excluded from driver-track resolution.

The toolkit does **not** answer whether an NPU package will actually initialize, remain stable, and run workloads on Windows Server. That is a separate deployment/runtime test plane.

## Quick start

### Built-in/self-test path

```powershell
.\Invoke-AmdNpuDriverResearch.ps1 -Stages Test
```

### Hardware-only track resolution

Resolve the local Windows machine automatically. Do not supply a known NPU ID:

```powershell
.\Invoke-AmdNpuDriverResearch.ps1 `
  -Stages Test,HardwareIdentity `
  -ResolveHardwareSelection `
  -SkipPublicExport
```

The tool derives the Windows build, enumerates local AMD PCI/NPU candidates, and
writes `inventory/local-npu-pnp-evidence.json` plus
`inventory/hardware-selection-result.json`. A completed zero-candidate enumeration
returns `NoNpuDriverRequired`; unknown candidates or incomplete enumeration return
`ReviewRequired`. Manual IDs require `-UseObservedNpuHardwareIdOverride` and are
labeled offline/test input rather than local evidence.

The Test stage also writes `inventory/test-stage-evidence.json`, including the
structured `SignedCmsAvailable` result and the Evidence-snapshot contract result.
All three runtime JSON files are private inventory artifacts and are copied into
the Evidence ZIP when generated; they are not part of `public/**`.

### Normal full research run

No arguments means the complete research workflow:

```powershell
.\Invoke-AmdNpuDriverResearch.ps1
```

Equivalent explicit form:

```powershell
.\Invoke-AmdNpuDriverResearch.ps1 -Stages All
```

The normal stage order is:

```text
Test
  -> HardwareIdentity
  -> ProcessorCatalog
  -> Discover
  -> Metadata
  -> Acquire
  -> Extract
  -> Inspect
  -> Signature
  -> DriverBinary
  -> Compare
  -> Matrix
  -> Build
  -> Validate
```

The no-argument/`All` workflow acquires and evaluates every reviewed public
research artifact, including `NPU_RAI1.5_280_WHQL.zip`. Historical inclusion in
full research does not make an artifact recommendable.

### Local artifact replay / private qualification

Known local ZIP/EXE/MSI/CAB/7z artifacts can be supplied without changing the normal public acquisition catalog:

```powershell
.\Invoke-AmdNpuDriverResearch.ps1 `
  -PackagePath 'D:\Artifacts\NPU_RAI_376_WHQL.zip'
```

`-PackagePath` is the correct path for restricted/private qualification artifacts such as the reviewed 314 package. Supplying a private artifact does **not** make it public, recommendable, or automatically downloadable.

### Explicit public output root

```powershell
.\Invoke-AmdNpuDriverResearch.ps1 `
  -PublicOutputRoot 'D:\NpuResearchPublic'
```

`-PublicOutputRoot` is a caller-visible contract and is regression-tested after the 0.8.1-dev static-analysis correction.

### Windows Client native signature qualification

The exact v1.2.2-dev Gate A run completed with all seven selected stages PASS,
exit 0. It evaluated all three reviewed NPU packages and deeply verified the two
current NPU package cases. The v1.2.3-dev source changes only operator-facing
wording and archived transcript completeness; it does not change signature or
package-selection decisions. Do not rerun this approximately three-minute gate
solely for the presentation correction.

The v1.3.1-dev no-NPU Windows Client run confirmed the clean-process `SignedCms`
correction and automatic local PnP selection behavior. Review then found that
the Evidence snapshot omitted the generated local-PnP and selection-result JSON,
so that run is functionally accepted but does not close the archived-evidence
gate. v1.3.2-dev adds those files and structured Test-stage evidence to the
archive without changing hardware selection. A Client PASS does not authorize a
Windows Server run or the later NPU-equipped positive control without evidence review.

The returned v1.3.2-dev no-NPU archive passed independent JSON, manifest and
selection review and closes the negative-control Evidence gate. The subsequent
v1.3.2-dev NPU-equipped run correctly detected `DEV_17F0` through automatic
local PnP and resolved it to 376, but its detailed local-PnP artifact encoded the
Windows `ConfigManagerErrorCode` enum as an unquoted token. v1.3.3-dev quotes
every enum through the canonical JSON string encoder, normalizes that PnP field
to a string, adds an enum round-trip self-test, and refuses to pass
HardwareIdentity when its generated runtime JSON cannot be parsed.

The bounded v1.3.3-dev NPU-equipped Windows Client rerun is now accepted.
Automatic local PnP detected one reviewed `DEV_17F0` / `IpuMcdmDriver` device,
selected 376 without manual, CPU or firmware input, emitted
`ConfigManagerErrorCode` as the valid JSON string `CM_PROB_NONE`, parsed all
59 Evidence JSON files, and matched all 69 manifest rows. Neither the accepted
no-NPU negative control nor this positive control requires another run. This
acceptance enables stable-promotion and external-review planning; it does not
authorize Windows Server execution or deployment.

A separately reviewed Windows Server 2025 Datacenter no-NPU Gate B also passed
with PowerShell 7.6.5 Core. Automatic local PnP completed over 147 entities and
24 AMD PCI entities, found zero NPU candidates, and returned
`NoNpuDriverRequired`; 59/59 JSON files parsed and all 69 Evidence-manifest rows
matched. This is accepted Server negative-control and research-tool host-path
evidence. It is not PowerShell 5.1-on-Server evidence and does not prove an NPU
driver can load or operate on Windows Server.

The accepted Gate A command was:

```powershell
.\Invoke-AmdNpuDriverResearch.ps1 `
  -Stages Test,Discover,Metadata,Acquire,Extract,Inspect,Signature `
  -RequireWindowsClientSignatureQualification `
  -SkipPublicExport `
  -EvidenceLabel NPU-1.2.2-WindowsClient-Signature-Gate-A
```

This gate requires Windows Client execution, Windows SDK SignTool, the default
three-artifact reviewed research corpus, exactly two current-case certificate
targets, complete catalog-bound kernel coverage for all four Server target
profiles, zero required-profile non-zero exits, zero CMS parse failures and zero
PE signed-digest mismatches. It deliberately rejects `-PackagePath`,
`-ArtifactId` and `-SkipEvidenceArchive` so a partial or non-auditable run cannot
be mistaken for qualification. See
`WINDOWS-CLIENT-SIGNATURE-QUALIFICATION.md` before execution.

## Safety model

The following are invariants:

1. AMD installer executables are treated as untrusted research inputs and are **not executed**.
2. AMD driver payloads are not patched or modified.
3. INF files are parsed, not installed.
4. Static extraction is bounded and uses the shared 7-Zip research kernel.
5. ZIP/EXE/MSI/CAB/7z outer containers are supported as research inputs.
6. Vendor binary observations are exact-hash scoped. An unknown hash does not inherit a reviewed contract.
7. A broad INF/PnP match is not automatically an AMD published-support claim.
8. A driver-binary recognition path is not automatically an AMD published-support claim.
9. Windows client runtime evidence is not Windows Server runtime proof.
10. Unknown or incomplete NPU PnP identities fail closed; CPU identity is not consulted.
11. Invalid generated publication is not promoted over the previous valid `public/**` surface.
12. Generated `public/**` files are never repaired by hand; source/data/generator logic is fixed and regeneration is required.
13. 376 is the reviewed current AMD production-family track after an INF match;
    this publication statement is research authority, not deployment authorization.
14. 280 remains a research track and is never selected or used as an automatic fallback.
15. Historical `NPU_RAI1.5_*` artifacts are regression fixtures and cannot win current package selection.

## Full research, recommendation and certificate scopes

The toolkit keeps three independent artifact sets:

| Scope | Default behavior |
|---|---|
| Full research acquisition and analysis | All three reviewed public artifacts, including historical RAI1.5, are acquired, extracted and evaluated. |
| Hardware-only track recommendation | Complete PnP HardwareID/CompatibleID set for one device instance is matched against reviewed INF models. The current source applies the reviewed 376 production-family preference, and 280 has no automatic fallback path. |
| Deep certificate verification | The newest selected artifact inside each current NPU-type case; historical RAI1.5 is excluded by default. A single explicit `-ArtifactId` run analyzes that exact artifact, matching Chipset `OnlySelectedRelease` behavior. |

This is the same scope separation used by the Chipset research tool: broad
historical/package analysis is not reduced merely because expensive signature
qualification is release-scoped. The NPU Metadata stage emits a deterministic
`CertificateVerificationPlan`, and the `Signature` stage consumes that plan
without independently ranking package versions. The stage performs host-neutral
CMS/PKCS#7 parsing, nested and timestamp-signature traversal, X.509 extraction,
Authenticode PE digest comparison, and content-addressed catalog/binary
inventory. On Windows it also collects `Get-AuthenticodeSignature`, Windows
catalog-member/hash evidence and SignTool verification results. The
Windows-native path is implemented but is not accepted as qualified until it
passes the separately governed Windows Client evidence gate.

SignTool verification profiles are intentionally distinct:

- ordinary Authenticode observation: `/all /v /pa`;
- kernel-policy diagnostic observation: `/all /v /kp`;
- catalog-bound kernel verification: `/v /kp /c <catalog> <driver>`;
- target-OS catalog verification for Server 2016/2019/2022/2025: `/v /c
  <catalog> /o 2:<build> <driver>`.

Tool success/failure classification is based on launch state and exit code, not
localized console prose. Native raw output and host posture remain private
Evidence; static signature findings may be included in generated per-artifact
research output. No signature check installs a certificate, modifies a package,
or executes an AMD installer.

## Hardware-only package-selection model

The project retains 280 and 376 as research lines. The current source applies
the reviewed 376 preference, consistent with AMD's Ryzen AI Software 1.8.0
installation page checked on 2026-08-21. The choice is policy over reviewed Windows INF applicability, not a
claimed mutually exclusive device lane and not a CPU/NPU mapping.

```text
automatic local Windows PnP enumeration
  -> one identity set per AMD NPU candidate
  -> match reviewed 376 INF model
  -> verify locally observed Windows build satisfies the INF selector
  -> 376
```

No NPU instance after a completed local `Win32_PnPEntity` enumeration produces
`NoNpuDriverRequired`. Unknown identity, incomplete input or a build below the
published INF floor produces `ReviewRequired`. CPU SKU, CPUID, CPU/NPU
combination, NPU marketing name, firmware device revision and Linux AIE topology
are not resolver inputs. `SUBSYS` and `REV` are retained in evidence but do not
override INF matching. Multiple candidates are resolved independently. 280 is
never an automatic fallback.

`-ObservedNpuHardwareId` is not a local discovery mechanism. It is accepted only
with `-UseObservedNpuHardwareIdOverride` for explicit offline/self-test use. An
empty override is rejected because it cannot prove that local enumeration completed.

## Runtime and repository byte contracts

### Source-data schema contract

Every Git-tracked `data/*.json` document has a distinct camelCase source schema under `schemas/source-data/`. The Test stage maintains an explicit 13-file filename -> expected `schemaVersion` -> schema mapping and fails if a source file is unregistered, a schema is missing, or the guarded version differs. These source schemas are intentionally separate from the PascalCase generated-public schemas.


Supported runtime paths:

- Windows PowerShell 5.1 on Windows;
- PowerShell 7.x on Windows;
- PowerShell 7.x on Linux for static/offline research where 7-Zip is available.

Repository conventions:

- root `.ps1`: UTF-8 with BOM + CRLF;
- source Markdown/static JSON: UTF-8 without BOM + LF;
- generated public Markdown: UTF-8 without BOM + LF;
- generated public JSON: canonical deterministic JSON;
- Evidence/archive relative paths: `/` separators.

The retained generated `public/**` baseline remains v1.0.0, while the current
working source is v1.3.3-dev. This historical snapshot is integrity-valid
against its own publication manifest but is not current-schema-valid; see the
REV68 frozen-public boundary above. The earlier Windows Client signature Gate A remains
valid for the signature-analysis policy. The v1.3.2-dev no-NPU archive and the
bounded v1.3.3-dev NPU-equipped archive in `TESTING.md` section 28 are accepted.
Together they close the negative and positive Windows Client hardware-selection
Evidence gates for this exact finalization scope. The additional Windows Server
2025 no-NPU Gate B in `TESTING.md` section 29 is accepted for PowerShell 7.6.5.
NPU-equipped Server runtime, installation and deployment remain separate,
unauthorized planes.
The companion
hardware collector has an independent utility version lineage and is documented
under `tools/`.

## Current reviewed artifact corpus

The normal public/reviewed corpus is:

| Artifact | Role | SHA-256 |
|---|---|---|
| `NPU_RAI1.5_280_WHQL.zip` | historical public 280; default full-research input; not a default certificate/recommendation target | `a278a2c92cdc47e0da4cab2cbdb5347a127eee67311927578f4e151618446ce4` |
| `NPU_RAI_280_WHQL.zip` | later public 280 | `803afe1e2d75b717f60a368453306ccbd4877cdd936b6531b946b95109a22144` |
| `NPU_RAI_376_WHQL.zip` | public 376 | `aa836cbfcad5d0782c79b58f197aa50624af37e7cb8311c5f94d85b0dc3ccaad` |

Private qualification only:

| Artifact | Role | SHA-256 |
|---|---|---|
| `NPU_RAI1.6.1_314_WHQL.zip` | authenticated/restricted static comparison only | `023caa295d3b2fe4befccdba84db5867abb6428a5e057ac1acdbda03853cf0ac` |

The 314 artifact is intentionally excluded from the ordinary public acquisition catalog and has `RecommendationEligible=false` semantics.

### Research corpus versus deployment convergence

The research scope deliberately retains both public support lines: later 280
and 376. The historical Ryzen AI 1.5 280 package remains a regression fixture.
The reviewed project preference for 376 does not authorize removing 280 from
acquisition, extraction, comparison, or historical analysis. AMD's live
Ryzen AI Software 1.8 documentation (version-pinned
`https://ryzenai.docs.amd.com/en/1.8/inst.html`, with `latest` retained as a
moving alias) checked on 2026-08-21 labels 376 as the
production driver for the five reviewed families. See the REV65 source-check
correction in `authored/NPU-LIVE-PUBLICATION-DRIFT-2026-08-21.md`.

This boundary separates two questions:

- research compares 280 and 376 to explain package evolution, supported platform coverage, and compatibility evidence;
- a future deployment/build workflow may converge on one recommendation-eligible product only after exact-SKU, observed-HWID, AMD published-family, static OS/package, and runtime gates pass.

Single-product deployment is therefore a downstream hypothesis to validate, not a reason to narrow the research corpus.

## High-value research findings

### 1. The reviewed NPU INF is not blocked by ProductType=1

The reviewed 280/314/376 INF family uses the same broad model-selector shape:

```text
%ManufacturerName%=IpuMcdmDriver.Mfg,NTamd64.10.0...22000
PCI\VEN_1022&DEV_1502
PCI\VEN_1022&DEV_17F0
```

`NTamd64.10.0...22000` has a build floor but does not carry an explicit ProductType restriction.

Static consequence for the Server profiles currently modeled by the toolkit:

| Server | Build relation to 22000 | Published INF static state |
|---|---:|---|
| Windows Server 2016 | below | rejected by build floor |
| Windows Server 2019 | below | rejected by build floor |
| Windows Server 2022 | below | rejected by build floor |
| Windows Server 2025 | 26100, above | selector candidate |

This is one of the most important deployment-project corrections: the NPU path must not copy a generic assumption that AMD's client driver requires ProductType rewriting. Server 2025 first needs an **unmodified-package runtime test** before any INF modification is justified.

### 2. The AMD installer has a separate OS-routing layer

Static disassembly of the two reviewed exact installer hashes recovers the same relevant routing family:

```text
Windows major == 10
build >= 26100                  -> MCDM route
build >= 22621 and UBR >= 3527  -> MCDM route
build >= 22621 and UBR < 3527   -> WDF/NULL route
build >= 22000 and < 22621       -> WDF/NULL route
lower builds                     -> Windows 10 / WDF-NULL route
```

The reviewed packages contain the MCDM stack but do **not** contain the installer-referenced `npu_wdf_stack_prod\kipudrv\kipudrv.inf` payload.

This means Server 2016/2019/2022 are not merely an INF decoration problem. The reviewed current package corpus lacks the lower-build WDF payload referenced by the installer routing logic.

### 3. CPU/NPU identity is multi-layered diagnostic evidence, not selection authority

The toolkit keeps the following namespaces separate:

| Layer | Example | Meaning |
|---|---|---|
| exact CPU SKU | `AMD Ryzen AI Z2 Extreme` | product identity/published NPU capability |
| codename | Strix Point | reviewed product-family relation |
| broad PCI HWID | `PCI\VEN_1022&DEV_17F0` | broad Windows NPU identity |
| PCI revision | `REV_10` | PCI configuration-space revision byte |
| quicktest-style class | `STX` | AMD historical PCI-revision classification hint |
| XRT device label | `NPU Strix` | observed runtime identity label |
| firmware version | `1.1.2.64` | firmware version, not device revision |
| firmware device revision | STXA/STXB/KRK1/... | separate management-protocol refinement |

These values must not be collapsed into one field. In particular, PCI `REV_10`, XRT firmware version `1.1.2.64`, and firmware device revision `1/2/...` are different things. None of the CPU- or firmware-specific fields is required by the hardware-only driver-track resolver.

### 4. `DEV_17F0` is not synonymous with Strix

AMD `npu_check` and the reviewed installer use broad identities (`1502` and `17F0`). Linux `amdxdna` and the reviewed Windows 376 `ipustack.sys` expose a finer NPU4 refinement model under the broad 17F0 family.

The cross-source revision order is:

| Firmware device revision | Family label |
|---:|---|
| 1 | Strix A |
| 2 | Strix B |
| 3 | Krackan 1 |
| 4 | Krackan 2 |
| 5 | Strix Halo |
| 6 | Gorgon Point 1 |
| 7 | Gorgon Point 2 |
| 8 | Gorgon Point 3 |
| 9 / other | unknown/fallback |

The reviewed Windows 376 binary also contains a `0x117` management primitive and the same refinement order. This is strong exact-binary/static correlation, but it is not a license to infer vendor support for every recognized generation.

### 5. Published support and binary capability remain independent gates

The frozen reviewed Ryzen AI 1.8 capture used by the current dataset published
NPU driver `32.0.203.376` as production for:

- Phoenix;
- Hawk Point;
- Strix;
- Strix Halo;
- Krackan Point.

AMD's live `latest` Ryzen AI Software 1.8.0 page checked on 2026-08-21 also
labels 376 as the production driver for those five families. Driver 280 remains
a retained research line and minimum-driver context, not the preferred current
production-family track.

The reviewed 376 binary can internally recognize Gorgon Point revision labels,
but Gorgon Point is outside the reviewed AMD 376 production-family statement.
Therefore:

```text
broad HWID match
+ binary generation recognition
+ exact Gorgon Point CPU
- reviewed 376 published-family support
= ReviewRequired
```

The same principle applies to Gorgon Halo: published processor/NPU capability is not enough when exact reviewed NPU identity/artifact-support evidence is incomplete.

## Exact-SKU processor catalog and driver applicability (retained audit reference)

Version 0.9.0-dev expands the reviewed processor catalog to **112 exact AMD processor SKUs**:

- 90 with AMD-published NPU capability;
- 18 with AMD-published NPU unavailability;
- 4 retained as no-published-NPU-capability negative controls.

Coverage includes reviewed exact SKUs from:

- Ryzen 7040 / Ryzen PRO 7040;
- Ryzen 8040 / Ryzen PRO 8040;
- Ryzen 8000G / Ryzen PRO 8000;
- Ryzen 200 / Ryzen PRO 200;
- Ryzen AI 300 / Ryzen AI PRO 300;
- Ryzen AI Max 300 / Max PRO 300;
- Ryzen AI 400 / Ryzen AI PRO 400 mobile and desktop;
- Ryzen AI Max PRO 400;
- Ryzen Z handheld controls including Ryzen AI Z2 Extreme.

The catalog is exact-SKU driven but is retained only for research coverage and human audit. It is not machine authority for driver selection. Similar naming, series membership, CPU core layout, iGPU family, presumed silicon lineage, CPUID or CPU/NPU combination must not be used by the hardware-only resolver.

Generated applicability outputs:

```text
public/catalog/processor-driver-applicability.json
public/catalog/processor-driver-applicability.md
```

The current decision classes are:

- `SelectLatestPublishedStaticCandidate`;
- `ReviewRequired`;
- `NoNpuDriverRequired`.

The 0.9.0-dev dataset produces:

```text
Processor catalog       112
Compatibility rows      336
Processor selections    112
Applicability rows      112
ReviewRequired           28
```

The following historical relation explains the retained audit dataset; it is superseded for runtime selection:

```text
exact CPU SKU
  -> codename / NPU generation
  -> reviewed NPU identity
  -> reviewed artifact capability
  -> AMD published family support
  -> INF/installer/binary static evidence
  -> Windows Server static applicability
  -> observed runtime evidence, if any
  -> latest recommendation-eligible public artifact
```

Unknown processors do not affect hardware-only resolution. Unexpected or incomplete NPU PnP identity fails closed.

## Reviewed Ryzen AI Z2 Extreme runtime evidence

Private runtime evidence from a Ryzen AI Z2 Extreme positive-control system was reviewed and only generalized facts were promoted into repository source data.

Reviewed observations:

```text
CPU                    AMD Ryzen AI Z2 Extreme
CPU family/model/step  26 / 36 / 0
NPU PCI                VEN_1022 DEV_17F0 SUBSYS_20CF1043 REV_10
Service                IpuMcdmDriver
Installed driver       32.0.20101.3760
XRT device             NPU Strix
XRT firmware version   1.1.2.64
```

The installed NPU INF, `ipustack.sys`, and `xrt-smi.exe` matched the reviewed public 376 payload exactly. This provides **exact-artifact Windows client runtime evidence** for that SKU.

It does not prove:

- Windows Server runtime support;
- STXA versus STXB;
- that every `DEV_17F0&REV_10` platform is the same exact SKU;
- that future AMD releases preserve the same mapping.

## Windows Server research interpretation

The toolkit intentionally separates three operational questions:

1. **Does the package's INF select the observed NPU PnP identity and OS as published?**
2. **Does AMD's installer/binary contain a compatible route or recognition path?**
3. **Has the exact artifact actually run successfully on the target Windows Server?**

Only the third question is runtime proof.

For the current reviewed corpus:

- Server 2016/2019/2022 are below the INF build floor and the reviewed packages do not contain the lower-build WDF payload referenced by the installer;
- Server 2025 satisfies the INF build floor and enters the reviewed installer MCDM route, making it the correct first target for an unmodified-package runtime experiment;
- no reviewed Windows client runtime result may be copied into a Server-runtime field.

## Direct feedback for `Deploy-AMDNpuDriverOnWindowsServer.ps1`

The later deployment script should consume reviewed research data with a fail-closed decision model similar to:

```text
complete Windows NPU-device enumeration
  -> no NPU instance -> NoNpuDriverRequired
  -> one NPU instance at a time
  -> match its HardwareID / CompatibleID set against reviewed 376 INF models
       no  -> ReviewRequired / stop
       yes
  -> require target Windows build to satisfy the as-published INF selector
       no  -> ReviewRequired / stop
       yes -> reviewed 376 project policy; continue normal deployment qualification
  -> only patch/re-sign when runtime evidence proves a modification is actually necessary
```

Additional deployment rules derived from the research:

- do not use CPU SKU, CPUID, CPU series-prefix or CPU/NPU combination inference;
- use the full PnP identity set for an observed NPU instance; retain `SUBSYS`/`REV` without inventing selectors absent from the INF;
- do not replace published-support evidence with binary-string recognition;
- do not recommend private 314;
- do not rewrite the embedded INF version into AMD's published marketing/driver-label namespace;
- preserve exact vendor artifact SHA-256 before any transformation;
- for Server 2025, test the original WHQL package before applying a ProductType patch that the reviewed INF does not require;
- for Server 2016/2019/2022, treat the missing lower-build/WDF payload as a separate technical problem rather than assuming an INF-only fix;
- unknown or incomplete NPU PnP identity must stop automation;
- never select or fall back to 280 automatically.

See `REVERSE-ENGINEERING-NOTES.md` for the detailed evidence behind these rules and `SPEC.md` for the normative machine behavior.

## Evidence model

The toolkit keeps evidence planes separate:

| Level | Examples | Commit status |
|---|---|---|
| vendor artifact | AMD ZIP/EXE/MSI and contained binaries | runtime input, not committed |
| private host evidence | collector ZIP, PnP, XRT, SetupAPI, INF snapshots | private/runtime, not committed |
| reviewed source data | processor catalog, identity rules, contracts, generalized observations | Git-tracked |
| generated publication | `public/**` | generated commit surface |

Important evidence classes include `Published`, `Embedded`, `PayloadObserved`, `StaticDisassemblyProven`, `Analysis`, `ObservedClientRuntime`, and runtime/private evidence.

A stronger evidence class does not automatically replace a different evidence plane. For example, exact client-runtime evidence cannot satisfy a Server-runtime field.

## Repository surfaces

Canonical layout:

```text
Deploy-Drivers-For-WindowsServer/
└─ tools/
   └─ amd-npu-driver-research/
      ├─ Invoke-AmdNpuDriverResearch.ps1
      ├─ README.md
      ├─ SPEC.md
      ├─ TESTING.md
      ├─ CHANGELOG.md
      ├─ REVERSE-ENGINEERING-NOTES.md
      ├─ SOURCES.md
      ├─ PUBLICATION-POLICY.md
      ├─ ARCHITECTURE-PARITY.md
      ├─ data/
      ├─ schemas/
      ├─ authored/
      ├─ public/
      ├─ inventory/
      ├─ private/
      ├─ reports/
      ├─ work/
      └─ tools/
         ├─ Collect-AmdNpuHardwareIdentityEvidence.ps1
         ├─ README.md
         └─ TESTING.md
```

Surface policy:

- `data/**`, `schemas/**`, source/docs: reviewed Git source;
- `public/**`: generated commit surface;
- `inventory/**`: runtime staging;
- `private/**`: private evidence/runtime state;
- `work/**`: downloaded/extracted workspace;
- generated runtime reports are not hand-maintained source.

See `PUBLICATION-POLICY.md` for the exact publication contract.

## Companion hardware evidence collector

`tools/Collect-AmdNpuHardwareIdentityEvidence.ps1` is a separate read-only Windows collector used when static package evidence cannot resolve the actual platform.

It can collect CPU/NPU/GPU/platform PnP identity, installed INF/service-driver evidence, XRT/xrt-smi read-only observations, and quicktest-style classification evidence. It must not execute `xrt-smi validate`, `xrt-smi configure`, AMD installer programs, or quicktest inference workloads.

Collector output is private evidence and is not a Git commit surface. Only reviewed generalized facts may be promoted to `data/**`.

Collector v1.3.0 adds a compact local-PnP selection-input observation, explicit
Client/Server host classification, fail-closed enumeration semantics and
JSON/manifest/ZIP integrity gates. It also supports a future Windows Server
positive observation after a built or self-signed NPU driver is applied without
requiring exact public-376 equality. The parser and hardware-independent
self-test pass; one naturally occurring NPU-positive run remains before the
collector itself is described as real-device-qualified. See `tools/TESTING.md`.

That real-device run is now explicitly **dependency-blocked and deferred**. It
cannot be performed until the production NPU driver build script has been
redeveloped, reviewed, and used under a separate authorization to prepare and
apply a Server driver. It is not the next project task and no user execution is
currently requested.

## Completion state and remaining work

The current bounded driver-selection work is functionally complete. The main
runner has accepted Windows Client no-NPU and NPU-positive gates, plus a Windows
Server 2025 no-NPU gate. No repeat of those runs is required.

| Work plane | Current state | Remaining action |
|---|---|---|
| Main-runner hardware selection | Accepted | No functional change or real-machine rerun is required for the present contract. |
| Companion collector 1.3.0 static contract | Parser and 15/15 self-tests PASS | No implementation change is currently identified. |
| Companion collector 1.3.0 real-device qualification | Deferred; blocked by production build-script redevelopment | After that separate project completes and a Server driver is applied under separate authorization, one current-source positive observation may close the collector gate. Do not add a ceremonial Client rerun. |
| Production build-script redevelopment and Server driver application | Not part of the collector task and not yet complete | Must complete first under its own plan, review and authorization. |
| Server application/workload proof | Not collected by this utility | Add a separately scoped workload/runtime gate only if the project later needs that claim. |
| Coordinated v3.0.0 release review | Cycle B closed by Claude at REV80 | Prepare the documentation-corrected GitHub commit candidate and retain user approval as the commit/push gate. |

The deferred collector run is an **observation qualification**, not an
installation test. When the dependency chain is eventually satisfied, it may
record a custom or self-signed Server stack without
requiring equality with the reviewed public 376 payload or requiring XRT. A PASS
establishes that the collector correctly captures the already-installed Server
state; it does not prove deployment success, workload success, or production
support.

The main NPU research runner, its accepted selection gates, and any independent
review or stable-promotion planning that retains the collector disclaimer are
not blocked by this deferred collector run. Documentation must continue to call
collector 1.3.0 static/synthetic-qualified rather than real-device-qualified.

The following are intentionally not remaining prerequisites: CPU SKU mapping,
CPU-by-NPU combination evaluation, Linux firmware/topology parity, firmware
device-revision discovery, automatic 280 fallback, and repeated accepted Client
or Server no-NPU gates.

## Pre-release 0.9.1-dev qualification baseline

Current source SHA-256:

```text
22036b61d64af2d272d011dadb381e41b850719d5bbc3f4efc3450c9d94aee07
```

The audit-remediation source has completed:

- Linux / PowerShell 7.6.4 full local replay: 13/13 stages PASS, exit 0;
- source-data schema/version contracts: 12/12 registered; external Draft 2020-12 validation 12/12 PASS;
- partial-stage negative controls (`Compare`, `DriverBinary`, `Matrix`, `Build`): explicit `BLOCKED`, exit 2 when prerequisites are absent;
- dataset: 336 matrix rows / 112 selections / 112 applicability rows / 28 `ReviewRequired`;
- publication privacy/dataset/JSON/Markdown validation: PASS.

The 0.9.1-dev source was subsequently qualified on Windows PowerShell 5.1.26100.9168 with 13/13 stages PASS, exit code 0, and the exact shipped pre-release script hash `22036b61d64af2d272d011dadb381e41b850719d5bbc3f4efc3450c9d94aee07`. That evidence remains historical pre-release evidence only and is not the final v1.0.0 qualification evidence.

This qualification does not constitute Windows Server NPU runtime qualification.

## v1.0.0 release-qualification status

Audit #3 approved the 0.9.1-dev implementation and closed all prior blocking findings. The source was then deliberately bumped to `1.0.0`; `1.0.0` is not used as an interim development version.

The v1.0.0 source adds a Test-stage guard that requires the `.NOTES` `Tool version:` declaration to match `$script:ToolVersion`. Generated `public/**` is never hand-edited during the bump.

Current release-candidate Linux qualification using the canonical reviewed public corpus:

```text
Script SHA-256        2dc94306ed7f9838a05be21ae2d6f44494446aaeded9ad978d3ebde5be0c04cf
PowerShell            7.6.4 / Linux
Full replay           13 / 13 PASS
ExitCode              0
Source data contracts 12
Matrix rows           336
Selections            112
Applicability rows    112
Select candidate       62
No NPU driver          22
ReviewRequired         28
```

Compared with the accepted 0.9.1-dev `public/**`, exactly 12 JSON files change because the tool version/source hash changes, while all 11 Markdown files remain byte-identical. This is the expected version-bump-only pattern.

Final v1.0.0 release-candidate qualification is now complete for the main research toolkit. The exact v1.0.0 script completed a fresh automatic AMD vendor re-acquisition on Windows PowerShell 5.1.26100.9168 with 13/13 stages PASS and exit code 0. The acquisition inventory records all three public reviewed artifacts as `Downloaded`, with `PackagePath=[]` and the expected reviewed SHA-256 values. The Windows-generated `public/**` tree is 23/23 byte-identical to the Linux/PowerShell 7 v1.0.0 canonical-corpus qualification output. Audit #4 remains the final independent release-readiness review.

The Linux build environment used during preparation temporarily could not resolve `download.amd.com`, so the successful Linux qualification uses canonical reviewed packages pinned to the same SHA-256 values. That limitation is explicitly retained in the audit evidence; fresh vendor re-acquisition was instead proven by the Windows v1.0.0 qualification run.

## Documentation map

The canonical operator surface is `README.md`, `SPEC.md`, `TESTING.md`,
`PUBLICATION-POLICY.md`, `CHANGELOG.md`, and `THIRD-PARTY-NOTICES.md`.
Specialist NPU references remain at the tool root because the current
`3.0.0` Evidence-snapshot allowlist names them explicitly; moving them
would be a PowerShell source change and is intentionally outside this
documentation-only revision. Their current/historical status is explicit in
each file.

- `README.md` — purpose, operating model, major findings, deployment implications.
- `SPEC.md` — normative contracts and fail-closed semantics.
- `TESTING.md` — source, runtime, dataset, publication, and release qualification requirements/results.
- `REVERSE-ENGINEERING-NOTES.md` — detailed payload/installer/binary/identity findings.
- `SOURCES.md` — upstream and evidence provenance references.
- `PUBLICATION-POLICY.md` — generated/public/private boundary.
- `ARCHITECTURE-PARITY.md` — shared research-runner architecture inherited from Chipset/Graphics.
- `CHANGELOG.md` — development chronology.
- `CLAUDE-AUDIT-READINESS.md` — superseded v1.0.0 audit-readiness snapshot.
- `DEVELOPMENT-HANDOVER.md` — historical 1.3.3 transition handover.
- `WINDOWS-CLIENT-SIGNATURE-QUALIFICATION.md` — accepted historical 1.2.2 Client Gate A record.
- `authored/AMD-CPU-NPU-EVALUATION-MATRIX.md` — reviewable companion record for the English CPU/NPU evaluation workbook.
- `authored/NPU-LIVE-PUBLICATION-DRIFT-2026-08-21.md` — REV65 live-source verification correction and authoritative 1.8.0/376 disposition.
- `authored/AMD-CPU-NPU-Evaluation-Matrix-2026-08-16_rev2.xlsx` — English evaluation matrix for future repository review/commit.
- `tools/README.md` / `tools/TESTING.md` — companion real-hardware evidence collector.
## Evidence output location (rev48 common contract)

By default, final evidence is stored only under `<tool-root>\private\evidence`. The file identified by `EVIDENCE ZIP TO SHARE` is the review artifact; its adjacent `.zip.sha256` file verifies integrity, and `LATEST-EVIDENCE.txt` points to the most recent successfully verified archive.

Raw collection uses a short path under `private\evidence\runs\r<UTC>-<8hex>`. The default `-EvidenceRetention ZipOnly` removes that directory only after ZIP integrity verification and SHA-256 generation. Use `-EvidenceRetention ZipAndDirectory` only when raw diagnostics must remain. `-EvidenceOutputRoot` is retained for compatibility but accepts only the canonical root or a descendant; external, UNC, SUBST-backed, and reparse-point paths are blocked before research starts.
## rev57 cross-tool common-core convergence

NPU now uses the same HTTP and diagnostic infrastructure as Chipset and Graphics: sequential concurrency 1, bounded retries with exponential backoff/jitter and `Retry-After`, fresh transport after the first attempt, atomic partial-file completion, HTTP 206/content-range and byte-count checks, PE/ZIP payload validation, secret redaction, bounded response previews, trace history, and failure snapshots.

Every run prepends `PathSafety`; every recursive 7-Zip extraction is preflighted for rooted paths, `..` traversal, and excessive predicted Windows path length. `data/current-three-tool-common-core-contract.json` replaces the historical predecessor snapshot as the current parity authority. These changes do not alter the independent 280/376 lanes, hardware-only selection, CPU/NPU reference matrix, or certificate-target policy.
