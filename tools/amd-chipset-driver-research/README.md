# AMD Chipset Driver Research Toolkit

## REV81 coordinated v3.0.0 documentation closeout

Claude closed Cycle B against REV80 with no open findings. The executable
remains `3.0.0`, byte-identical to the accepted REV77 source. Chipset Gate 2C
and the exact REV77 Windows Server / Windows PowerShell 5.1 `PathSafety,Test`
gate are accepted/no-repeat. The generated 68-file `public/**` surface is the
accepted v3.0.0 publication authority for this coordinated release.

REV81 updates current-facing documentation only. It does not change the root
script, contracts, schemas, reviewed data, generated public output, canonical
path, or qualification evidence. No Windows rerun is required. Historical
revision sections below remain evidence-bound records and are not pending
operator instructions unless a future source or contract change explicitly
reactivates them.

## REV78 qualification status

The exact REV77 source completed the Windows Server 2025 / Windows PowerShell
5.1 `PathSafety,Test` gate with 2/2 PASS, exit code `0`, an exact 52/52 Evidence
manifest, no Warning/Error diagnostic event, and authoritative
`run-context.json` Server identity. Chipset requires no repeat. REV78 changes
only an NPU-specific architecture-contract data file and related governance;
this Chipset script remains byte-identical to REV77 at `3.0.0`.

## REV77 execution-context evidence correction

The executable version remains `3.0.0`. REV77 adds the actual host execution
context to the private Evidence `run-context.json` for every run, including
`ExecutionClass`, `ProductType`, `ProductRole`, OS caption/version/build,
evidence scopes, and typed collection status/source. This is the same evidence
contract used by Graphics and NPU. The generated `public/**` research snapshot
is unchanged because the correction affects private run evidence only.

The accepted REV76 Windows PowerShell 5.1 Chipset smoke remains a regression
control, but it did not qualify the changed REV77 source. The short REV77
`PathSafety,Test` command in `TESTING.md` subsequently passed and is now
accepted/no-repeat; no acquisition, installation, load, or public regeneration
is required.

## Current documentation and qualification status

- Executable version: `3.0.0`.
- Coordinated release state: Cycle B closed by Claude at `REV80`; `REV81`
  corrects documentation only before GitHub commit-candidate preparation.
- The prior `2.1.17` source completed the accepted Windows Server smoke gate under
  Windows PowerShell `5.1.26100.33296`: `PathSafety,Test`, 2/2 stages PASS,
  final `Pass`, exit code `0`; that exact-source result is retained as a
  regression reference and does not qualify the changed `3.0.0` source.
- `3.0.0` explicitly requires Windows PowerShell 5.1 or later. Chipset Gate 2C
  is accepted/no-repeat and its generated `public/**` tree is incorporated.
  The exact REV77 Windows Server `PathSafety,Test` smoke is also
  accepted/no-repeat; no platform gate remains pending for this release.
- That smoke gate proves startup/path safety, shared self-tests, Evidence ZIP
  finalization and summary behavior on Windows Server. It does **not** prove a
  full network research run, public regeneration, driver installation, kernel
  load or device operation.
- The qualification-only cross-tool launcher is not part of the release tree.
  Run the documented per-tool commands directly. Any future included
  orchestrator requires a separately reviewed multi-scenario specification.

Historical revision narratives belong in `CHANGELOG.md` and `authored/**`.
This README is the operator entry point; `SPEC.md` is normative, `TESTING.md`
defines gates, and `RESEARCH-NOTES.md` carries the findings intended for the
downstream build/sign/deployment design.

## Historical correction notes

## rev59 public-path audit correction

The public generator now treats nested `PathSafety.ArchivePath` as a path-bearing field. Absolute installer/work paths are converted to repository-portable identities before per-release JSON and derived aggregate JSON are validated. The REV58 Windows run proved extraction, inspection, signature, selector, host analysis and Build all passed; only publication was blocked because this one nested field had escaped conversion.

## rev58 path-safety correction

Runtime extraction now uses the same short layout that startup PathSafety predicts: `work\\x\\aNNNN\\cNNNN`. Release versions and original container names remain evidence fields and no longer lengthen the filesystem path. A shared completeness assertion fails closed before inspection, signature, selector, or publication can accept an incomplete extraction. In particular, a zero-file signature scan over an `ExtractedWithErrors` release cannot be reported as PASS.



## rev56 release-note correlation: 8.08.12.551

The official page capture is represented in
`data/curated-release-notes.json` as structured, schema-backed evidence: 17
chipsets, 21 processor families and 37 component-package rows. The Selector
stage compares each public Windows 10/11 component value with exact-name
`Info.xml` records and retains version mismatches and public
`Not Applicable` boundaries as typed observations.

This prevents three unsafe inferences: an internal product row does not prove
public OS support; chipset-package processor support does not prove NPU driver
package support; and Windows 10/11 release-note support does not prove Windows
Server support. Ryzen AI 300 PMF Driver 1 and Driver 2 also have distinct
selector aliases, removing the earlier two-candidate ambiguity.

## rev55 current-latest baseline: 8.08.12.551

The curated current-latest release for this qualification cycle is AMD Ryzen
Chipset Software `8.08.12.551`. Exact-release acquisition prefers AMD's
observed `AMD_Chipset_Software_8.08.12.551.exe` filename and retains the
existing lowercase fallbacks for vendor-CDN resilience. The `Test` stage fails
closed if the curated seed no longer has this unique semantic newest record,
its release-note URL changes unexpectedly, or the exact installer URL is not
the first deterministic candidate.

Offline static qualification of the user-provided installer passed extraction,
INF inspection, signature inventory and selector analysis. The payload retains
31 INF packages; four INF versions changed from 8.07.16.1035 and no INF hardware
ID or WDF declaration changed. DevID.xml grows from 41 to 44 mappings with
`SETWIRELESSFILTER`, `SETVIRTUALSTORAGE`, and `SETSDXINULL`, while
`SETINTERFACE` adds `DEV_11B0`. Every selector rule now records whether it has
an Info.xml product correlation. `NoInfoProductCandidate` is deliberately
unresolved evidence—not proof of a missing payload or a separate driver.

The new Qt `Setup.exe` has a different SHA-256 and therefore does not inherit
the exact-binary 8.07.16.1035 compiled-selector contract. Static strings and
declarative XML remain reportable, but CPU/OS predicates and Windows host
behavior require separate exact-binary reverse engineering and platform gates.

## rev52 Windows PowerShell 5.1 acceptance

The submitted Windows PowerShell 5.1 Test-only evidence used the exact rev51
source SHA-256, completed in 6.20 seconds, passed the Canonical JSON fixed
vector, and produced an integrity-valid Evidence ZIP. Evidence-manifest paths
are now serialized with `/` on every host so Windows evidence can be verified
without path translation on Linux or other review systems.

## rev51 startup/performance recovery

rev51 supersedes the unqualified rev50 Canonical JSON migration. The canonical
byte contract is unchanged, but serialization and parsing now use an embedded,
single-script .NET runtime instead of character-by-character PowerShell. A
`Test`-only run never reconstructs `inventory/driver-packages.json`; that large
baseline is restored lazily only for a partial downstream run that needs it.

Bootstrap identity, requested stages, every self-test operation, and baseline
restore progress are printed with elapsed time. If normal evidence finalization
throws, an independent emergency path closes the transcript, records the
failure, creates and verifies the ZIP, writes its SHA-256 companion, and retains
the raw evidence directory. An emergency ZIP is diagnostic evidence, never a
PASS qualification artifact.

## Canonical JSON contract (rev50)

All JSON written through `Write-AmdJsonFile` now uses the shared hand-written
Canonical JSON serializer: UTF-8 without BOM, LF, two-space indentation,
literal non-ASCII, insertion-order properties and exactly one trailing LF.
`Read-AmdJsonFile` uses the matching parser so ISO-8601-looking strings remain
strings on both Windows PowerShell 5.1 and PowerShell 7. A Python-reference
SHA-256 self-test is part of the `Test` stage.

**Current toolkit version: 3.0.0 (coordinated Cycle B closed release candidate)**

`Invoke-AmdChipsetDriverResearch.ps1` is a PowerShell research toolkit for reconstructing AMD Ryzen Chipset Software release history, acquiring original AMD artifacts without executing them, statically extracting nested installer content, parsing INF/WDF semantics, reverse-engineering AMD component-selection behavior, collecting host-neutral Authenticode/catalog evidence, and publishing a repository-safe evidence dataset for Windows Server research.

The toolkit is deliberately **research-only**. It does not install AMD chipset drivers, patch INF files, rebuild catalogs, install certificates, sign packages, or claim runtime compatibility. Its job is to expose enough vendor, INF/PnP, WDF, selector, MSI, and provenance evidence that downstream deployment or self-signed-driver work can be designed from measured facts instead of installer behavior guesses.

## What the toolkit answers

The normal research workflow is intended to answer questions such as:

- Which AMD Chipset Software releases are known and which vendor artifacts represent them?
- What SHA-256 identity belongs to each downloaded AMD artifact and recovered nested installer layer?
- Which INF packages are present after bounded static extraction?
- What `[Manufacturer] -> TargetOSVersion -> Models -> identifier -> DDInstall` relationships are declared by each INF?
- Which Windows Server 2016 / 2019 / 2022 / 2025 profiles are selected **as published** by Microsoft INF semantics?
- Which additional candidates appear under the toolkit's non-mutating Workstation `ProductType=1` to Server `ProductType=3` analytical projection?
- Which KMDF/UMDF versions are explicitly declared, and what conservative WDF decision follows for each target Server profile?
- What does AMD's own chipset selector expose through `Info.xml`, `DevID.xml`, MSI tables, binary strings, and exact-binary compiled predicates?
- Why can AMD Setup select no component on Windows Server even when an INF remains a static Server candidate?
- What is known, inferred, dynamically observed, or still unresolved for each selector rule?
- Can another reviewer reproduce the published summary from Raw JSON without trusting the Markdown report?
- Which extracted SYS/CAT/DLL/EXE files carry embedded Authenticode envelopes, nested signatures, timestamps, and which exact X.509 certificates are present?
- On Windows, what do native Authenticode, catalog-enumeration, and SignTool policy probes observe without installing or loading a driver?
- Which evidence came from static bytes, which came from a Windows Client/Server trust observation, and which Server runtime claims remain explicitly unobserved?

The toolkit does **not** answer whether a projected or statically applicable package will actually load and operate correctly after INF transformation and self-signing on Windows Server. Runtime acceptance remains a separate deployment/qualification activity.


### Reference-quality diagnostic semantics

Before the common diagnostic primitive is propagated to NPU/Graphics, 2.1.16 tightens the Chipset reference implementation:

- structured secret redaction is key-specific and preserves public research fields such as `HasMzSignature`, `HasZipSignature`, and signature verification status;
- signed-URL credential fields such as `X-Amz-Signature` and credential-bearing query values remain redacted;
- expected optional assembly probes are captured as structured fallback evidence without emitting misleading Add-Type errors to the user-visible Error stream;
- built-in self-tests prove both the positive redaction contract and the quiet expected-fallback contract.

The project deliberately batches these common-primitive fixes before asking for the final real-environment propagation gates.


### Windows transcript hygiene and platform-boundary review

2.1.17 tightens the reference implementation after Windows PowerShell 5.1 showed that `Start-Transcript` can record **caught** terminating errors even when the PowerShell Error stream itself is clean.

The toolkit therefore:

- uses a managed no-throw assembly probe for expected SignedCms assembly fallback tests;
- no longer injects malformed Authenticode DER during the normal Test stage merely to prove parser rejection;
- requires expected negative/fallback self-tests to stay out of the user-visible transcript;
- preserves structured fallback/diagnostic evidence without synthetic `PS>終了エラー(...)` noise.

Windows Client and Windows Server are distinct qualification environments. A Windows Client PASS does not automatically authorize the Server run. Share the Windows Client evidence for review first; proceed to the Server gate only after explicit acceptance.

## Quick start

### Built-in self-tests

```powershell
.\Invoke-AmdChipsetDriverResearch.ps1 -Stages Test
```

### Normal full research run

```powershell
.\Invoke-AmdChipsetDriverResearch.ps1 -Stages All
```

No `-Stages` argument also selects the normal full workflow.

On Windows, the normal stage sequence is:

```text
Test
  -> Discover
  -> Metadata
  -> Acquire
  -> Extract
  -> Inspect
  -> Signature
  -> Selector
  -> HostSurvey
  -> HostMatch
  -> Build
```

### Static-only research

To avoid host-specific survey/matching while retaining static artifact analysis:

```powershell
.\Invoke-AmdChipsetDriverResearch.ps1 -SkipHostAnalysis
```

### Specific release research

```powershell
.\Invoke-AmdChipsetDriverResearch.ps1 `
  -ReleaseVersion 8.08.12.551
```

Multiple release versions may be pinned explicitly for a controlled qualification run. Pinning is recommended for release audits so a new AMD release cannot silently change the dataset under review.

### Replay previously captured AMD installer observations

AMD installer logs may be compared with static emulation without executing AMD software from this toolkit:

```powershell
.\Invoke-AmdChipsetDriverResearch.ps1 `
  -Stages Selector,HostSurvey,HostMatch `
  -ObservedAmdDeviceIdLog 'C:\AMD\Chipset_Software\Logs\Device_ID.log' `
  -ObservedAmdMsiLog 'C:\AMD\Chipset_Software\Logs\AMD_Chipset_Software_Install.log'
```

Use `-ObservedAmdReleaseVersion` when the observed log does not carry an unambiguous release identity.

## Safety model

The toolkit follows these invariants:

1. Downloaded AMD EXEs/ZIPs are treated as input artifacts and are **not executed**.
2. Extraction is static and bounded.
3. Recovered MSI packages are not installed. On Windows, Windows Installer COM may open recovered MSI databases read-only for declarative-table inspection.
4. INF packages are not installed or staged into DriverStore.
5. `pnputil`, INF mutation, catalog regeneration, certificate installation, and package signing are outside this toolkit.
6. Host analysis is read-only and may query CIM/PnP state; host evidence stays private by default.
7. The original AMD artifact hash remains immutable vendor provenance.
8. A publication/privacy/schema failure is fail-closed and cannot replace the previous validated `public/**` baseline.
9. Generated repository artifacts are never repaired by hand. Fix the generator and rerun.

## Runtime support

The script is designed for:

- Windows PowerShell 5.1 on Windows;
- PowerShell 7 on Windows;
- PowerShell 7 on Linux for supported static/offline research paths.

The distributed `.ps1` intentionally uses UTF-8 with BOM and CRLF line endings for Windows PowerShell compatibility.

Generated **public Markdown** follows the repository publication contract: UTF-8 without BOM and LF-only line endings.

## Research model

Chipset research separates several decision planes that must not be collapsed into one another:

```text
AMD published metadata
        |
        v
embedded installer metadata / AMD selector rules
        |
        +-----------------------------+
        |                             |
        v                             v
Microsoft INF/PnP semantics      AMD installer selection
        |                             |
        v                             v
AsPublished / ServerProjection   candidate/filter/final list
        |                             |
        +-------------+---------------+
                      v
             research comparison
                      |
                      v
        downstream project policy
        (outside this toolkit)
```

A zero-component AMD selector result on Windows Server is **not** equivalent to “the contained INF cannot apply on Windows Server.” Likewise, an INF static candidate is **not** proof that the binary will load or function correctly.

Detailed design rationale and real-artifact observations are consolidated in [`RESEARCH-NOTES.md`](./RESEARCH-NOTES.md).

## Release and artifact identity

Release identity is the four-part AMD Chipset Software version. The concrete downloaded artifact and every recovered nested layer retain their own hashes.

The outer AMD artifact is immutable source provenance. User-created transfer ZIPs or split archives are transport envelopes only and do not replace the vendor artifact identity.

The public v2.0.0 dataset covers 25 releases from `2.04.04.111` through `8.07.16.1035` and preserves per-release Raw JSON as the primary independently reviewable unit.

## Static extraction model

Observed chipset installers require more than one container strategy. The canonical research model includes:

```text
AMD artifact
   |
   +-- modern EXE / historical ZIP
   |       |
   |       `-- AMD outer EXE
   |              |
   |              +-- Qt selector/XML assets
   |              |
   |              `-- AMD_Chipset_Drivers.exe
   |                     |
   |                     `-- InstallShield ISSetupStream
   |                            |
   |                            `-- AMD_Chipset_Drivers.msi
   |                                   |
   |                                   `-- Data1.cab
   |                                          |
   |                                          `-- INF / SYS / CAT / XML
```

7-Zip handles supported archive/container layers. The single PowerShell script includes a static `ISSetupStream` decoder informed by the ISx project; see `THIRD-PARTY-NOTICES.md`.

`ExtractionComplete` requires driver-analysis content such as INF files. Merely opening an outer archive is not a successful deep extraction.

## INF and Windows Server analysis model

The canonical INF topology preserves:

```text
[Manufacturer]
  -> TargetOSVersion decoration
     -> referenced Models section
        -> model description
        -> DDInstall section
        -> hardware / compatible identifiers
```

The parser does not reduce this topology to a fixed PCI-only identifier list.

Static Windows Server analysis separates:

- **AsPublished / Native** — what the original INF selects without modification;
- **ServerProjection** — a non-mutating simulation of client `ProductType=1` targeting projected to Server `ProductType=3`;
- **RuntimeCompatibility** — `NotEstablished` until target-OS installation/load/functional testing exists.

The current published dataset provides Raw JSON and aggregate views for Windows Server 2016, 2019, 2022, and 2025.

## Signature evidence and execution-context model

Version 2.1.14 includes the current read-only `Signature` stage. The stage separates evidence by **where the claim comes from**, not by a single `Valid/Invalid` flag:

```text
Non-Windows
  -> Static

Windows Client (ProductType=1)
  -> Static
  -> WindowsNative

Windows Server / Domain Controller (ProductType=2 or 3)
  -> Static
  -> WindowsNative
  -> TargetServerHost
```

`Static` is host-neutral evidence derived from extracted bytes. It inventories unique PE/signature-bearing files (content-detected PE plus catalog/CMS/certificate artifact families) by SHA-256 while retaining every observed relative-path occurrence. For PE Authenticode content it records the PE certificate table, PKCS#7/CMS envelopes, primary signers, recursively discovered nested signatures, RFC 3161/countersignature evidence, certificates keyed by DER SHA-256, and the signed-versus-recomputed PE Authenticode digest relationship. SHA-1 is retained only as legacy/correlation evidence; SHA-256 is the canonical file/certificate identity.

`WindowsNative` is a runtime observation of the current Windows trust stack. Where available it may collect `Get-AuthenticodeSignature`, SignTool `/pa`, `/kp`, `/all`, target-build `/o` observations, and read-only WinTrust catalog-member/catalog-attribute enumeration. SignTool `/o` selects a target platform/version/build for policy verification; it does **not** emulate Windows Server `ProductType=3`, so a Client-host result is not labelled as a Target Server runtime result.

`TargetServerHost` is emitted only when the script is actually running on Windows Server/Domain Controller. It records read-only host security posture such as Secure Boot, Device Guard/HVCI observations, and TESTSIGNING state. The `Signature` stage does not install/stage a driver, start a device, or perform a runtime qualification. Therefore PnP install, kernel-load, Code Integrity runtime, and device-function claims remain `NotObserved` until a separate explicit qualification activity produces that evidence.

Windows-native and host-specific files remain private/runtime evidence by default. The host-neutral static signature analysis is embedded into the canonical per-release Raw JSON and may be published under the existing `public/**` fail-closed contract.

### Chipset signature-release scope

Chipset signature qualification is intentionally **not historical by default**. The expensive `Signature` stage analyzes exactly one release from the currently selected release set:

- when a single `-ReleaseVersion` is selected, that exact release is analyzed;
- when the normal all-release survey is selected, the highest semantic release version in that selected set is analyzed;
- if more than one release is explicitly selected, the newest of those selected releases is analyzed.

All other research stages may continue to process the full selected historical release set. This asymmetry is intentional: historical installer/INF comparison remains valuable, while repeated Windows-native certificate/kernel-policy verification of every historical chipset release adds high runtime cost without improving the current deployment-design decision. The signature JSON records `ReleaseSelectionPolicy`, `CandidateReleaseCount`, and `AnalyzedReleaseVersions` so the scope is explicit and reproducible.

Historical acquisition gaps are recorded without automatically invalidating an otherwise useful full-history run. When release discovery is automatic, the newest discovered release must be acquired successfully. If only older historical artifacts are currently unavailable, the final status is `PassWithNotes` / `PASS_WITH_NOTES`, the unavailable releases remain explicit in canonical evidence, and validated `public/**` publication is still permitted. If an explicitly requested release is unavailable, or the newest discovered release is unavailable, acquisition remains `REVIEW`.


### Exact-release discovery isolation (2.1.13+; metadata fallback hardened in 2.1.14)

When `-ReleaseVersion` pins one or more releases, Discover no longer depends on AMD global sitemap enumeration. The exact release set is resolved from operator/seed evidence when available and otherwise from the canonical AMD chipset release-note URL pattern, then filtered to only the requested versions. Metadata remains responsible for validating the release-note page before acquisition. This prevents a transient sitemap `403` or rate-limit response from collapsing a pinned qualification run to zero releases, and also avoids fetching metadata for unrelated releases during a pinned gate. A no-`ReleaseVersion` historical survey continues to use sitemap/seed discovery exactly as before.

Version 2.1.14 makes release-note metadata transport resilient: retryable connection/HTTP failures use bounded exponential backoff with jitter, `Retry-After` is honored within the policy bound, retries use cache bypass and a non-persistent connection, and every attempt is retained in `FetchAttempts`. AMD historical CMS migrations can expose a vendor-observed alias for a known release-note page (currently 7.02.13.148). Crucially, installer candidates derived from an exact version are generated even if release-note HTML cannot ultimately be fetched, so a transient metadata failure no longer collapses acquisition to `candidates=0`.

### AMD download transport integrity (2.1.11+, hardened in 2.1.12 and 2.1.14)

AMD download success is a **transport-integrity decision**, not merely a successful `GetResponse()` call. The downloader warms the release-note page in a fresh cookie session, sends the exact AMD release-note URL as the HTTP referrer, and uses a cache-bypass retry when the first attempt is rejected. Installer bytes are written to a private `.partial` file and are promoted atomically only after HTTP response completeness, response byte count, and installer-format checks pass.

Version 2.1.12 factors the post-transfer byte/payload decision into the same pure acceptance function used by the built-in Test stage. The self-test explicitly rejects the previously observed truncated-body shape, empty bodies, and full-length non-installer payloads so future transport refactoring cannot silently weaken byte conservation.

Before reuse, an existing cached installer is validated. An invalid cache entry is retained only as private diagnostic evidence, deleted from the canonical cache, and the same highest-priority candidate is retried over the network.

The transport rejects AMD `Download-Incomplete` redirects, unexpected response status, malformed or incomplete `Content-Range`, unsolicited partial HTTP 206 content that does not cover byte zero through EOF, and content-length/received-byte mismatches. The evidence records status, final response URI, `Content-Range`, `Content-Length`, content type/encoding, `Accept-Ranges`, warmup result, retry mode, byte count, classification, and any retained diagnostic payload. This contract was added after the 2.1.10 Windows evidence proved that a 54,199,901-byte object saved for 7.11.26.2142 was exactly the trailing suffix of the valid 78,301,768-byte AMD EXE rather than a complete installer.

Version 2.1.14 applies a shared retry taxonomy to both metadata and installer transfers. Connection closure, timeout/connect/send/receive failures, HTTP 408/425/429/5xx, AMD-side transient 403, partial-content/byte-count rejection, and `Download-Incomplete` responses are retryable. HTTP 400/401/404/405/410/422 are fail-fast. Up to four attempts are made with fresh-session/cache-bypass behavior after the first failure. Attempt evidence includes retryability, reason, `Retry-After`, WebException status, and delay before the next attempt.

Publication is additionally gated on a **successful current-run `Build` stage**. `Test`-only, analysis-only, failed-Build, or interrupted runs preserve the previous validated `public/**` baseline and report `PublicRepositorySurface=NOT_ASSESSED`; they never regenerate the repository-public surface from partial runtime state.

On Windows, catalog-bound SignTool checks are emitted only for kernel binaries that can be correlated to an extracted catalog. The toolkit computes the Windows catalog hash of the kernel file with `CryptCATAdminCalcHashFromFileHandle2` and matches that value to enumerated CAT member reference tags; raw file SHA-1/SHA-256 is not used as a substitute for the catalog/SIP hash. Version 2.1.11 deliberately separates two policy questions: `/kp /c <catalog> <driver>` records explicit catalog-bound kernel-mode policy without `/o`, while `/c <catalog> /o <target> <driver>` records an explicit target-OS Windows Driver Verification Policy observation with neither `/kp` nor `/pa`. This split replaces the rejected 2.1.10 `/kp /c /o` combination and keeps target-OS and kernel-policy claims independently reviewable. Catalog variants renamed by recursive extraction (for example `*.cat1`) are verified through a byte-identical temporary `.cat` alias so WinVerifyTrust does not produce a false extension-induced `HashMismatch`. The alias is runtime/private evidence only and never changes vendor bytes or public identity.

SignTool process health and trust-policy outcome are separate evidence. Native result classification is locale-neutral: process-launch failure is `ToolExecutionFailed`, exit code `0` is `Verified`, and any other successfully-launched result is `NonZeroExit`. Natural-language stdout/stderr is preserved for diagnostics but is **not** required for correctness and is never parsed as an English-only success/error contract.

Version 2.1.12 also applies catalog-bound coverage per kernel binary rather than relying only on aggregate counts. Every catalog-associated kernel must have at least one verified explicit `/kp /c` observation and at least one verified explicit-catalog `/o` observation for each WS2016/WS2019/WS2022/WS2025 target. The unbound `/all /kp <driver>` profile remains supplemental diagnostic evidence: a non-zero result there does not override a complete catalog-bound result and is labelled diagnostic-only in summaries. If target-OS probes produce no successful verification at all, the run remains `REVIEW` because CLI acceptance versus a legitimate policy-negative result cannot be distinguished safely without relying on localized prose.


CMS content-type routing is also explicit: only Authenticode `SpcIndirectDataContent` is parsed as SPC indirect data; RFC3161 timestamp TSTInfo and catalog CTL content are `NotApplicableContentType`, not malformed-SPC failures.

The `.NET SignedCms.CheckSignature()` result is retained as a parser/library diagnostic only. It is not treated as Windows Authenticode, catalog, kernel-policy, Secure Boot, or runtime trust truth; native Windows policy observations remain separate evidence.

## AMD selector analysis model

AMD's setup selector is treated as an independent evidence plane. The toolkit may retain:

- `Info.xml` / APS XML product records;
- `DevID.xml` device/property mappings where present;
- printable selector-binary strings;
- exact selector-binary SHA-256;
- read-only MSI declarative tables;
- exact-binary compiled predicates where reverse engineering established them;
- observed AMD logs from external qualification runs.

Evidence levels are explicit. `AmdCompiledStaticProven` is always scoped to an exact selector binary hash. Rules are not generalized across releases merely because two installers use the same Qt generation.

The major-version findings and downstream engineering implications are summarized in `RESEARCH-NOTES.md`; the detailed historical reverse-engineering report is retained under `authored/design-history/`.

## WDF analysis

KMDF/UMDF declarations are retained with the INF/package that declared them and compared conservatively with target Server profiles.

Important rules:

- no WDF version is invented when an INF does not declare one;
- package-level/INF-level WDF decisions are preferred over “installer version implies WDF version” shortcuts;
- where DDInstall/component dependency scope cannot be proven, the toolkit retains conservative INF-wide WDF evidence;
- WDF compatibility is necessary evidence for some packages but is not sufficient proof of loadability or functional correctness.

The current 25-release/643-package dataset observed a maximum declared KMDF version of 1.19. That measurement replaced an earlier repository assumption that modern chipset packages necessarily require a KMDF newer than the Windows Server 2016 documented runtime.

## Repository layout

The top-level documentation surface intentionally matches the AMD Graphics Driver Research Toolkit:

```text
amd-chipset-driver-research/
  Invoke-AmdChipsetDriverResearch.ps1
  README.md
  SPEC.md
  TESTING.md
  RESEARCH-NOTES.md
  CHANGELOG.md
  PUBLICATION-POLICY.md
  THIRD-PARTY-NOTICES.md
  data/                     # versioned curated/static inputs
  schemas/                  # generated-artifact schemas
  public/                   # repository-safe generated outputs
  inventory/                # runtime staging; not a generated commit surface
  private/                  # private/debug evidence
  work/                     # extraction/download workspace
  authored/                 # authored research/qualification records (reviewed, committed)
  reports/                  # script-generated runtime reports (never committed)
```

### Documentation map

| Document | Purpose |
|---|---|
| `README.md` | Stable entry point, workflow, concepts and repository layout |
| `SPEC.md` | Normative behavioral, data, selector, publication and evidence contracts |
| `TESTING.md` | Test matrix and release-acceptance procedure |
| `RESEARCH-NOTES.md` | Consolidated reverse-engineering knowledge and downstream engineering feedback |
| `CHANGELOG.md` | Version-by-version implementation history |
| `PUBLICATION-POLICY.md` | Generated public/private boundary and publication transaction |
| `THIRD-PARTY-NOTICES.md` | Third-party attribution |
| `authored/README.md` | Index of authored qualification/design records |

One-off reverse-engineering and qualification narratives are intentionally kept out of the tool top directory. They remain under `authored/**` as evidence of how a behavior was discovered or qualified.

## Public repository outputs and private evidence

Generated repository-safe content lives only beneath:

```text
public/
```

Typical public content includes:

- canonical per-release Raw JSON, including host-neutral static signature evidence when collected;
- release/acquisition/extraction/selector indexes;
- aggregate INF/Windows Server inventory views;
- generated Markdown reports;
- repository-safe run summary;
- publication manifest and validation.

Detailed execution evidence lives beneath:

```text
private/evidence/
```

Private evidence may include host/runtime information, Windows-native signature policy output, catalog enumeration observations tied to the execution host, host security posture, transcripts, local paths, installer binaries when explicitly requested, and extraction/download diagnostics.

For release auditability, private Evidence snapshots the exact runtime sources referenced by public manifest `SourceRelativePath` / `SourceSha256` fields.

When a publication succeeds, the private review ZIP also contains a byte-identical copy of the validated `public/**` tree under `snapshot/public/`. This duplication is intentional for self-contained ChatGPT/third-party handoff; it does not change the repository rule that only top-level `public/**` is a generated Git commit surface.

See `PUBLICATION-POLICY.md` for the normative generated-output trust boundary.

## Publication byte contract

The repository publication contract is explicit:

- canonical per-release JSON is generated compact and is not publication-time parsed/reserialized;
- canonical per-release Raw JSON remains the primary evidence representation even when PowerShell 5.1 serializes collection wrappers;
- tool-generated aggregates canonicalize recognized PowerShell 5.1 collection wrappers to plain arrays and fail publication if such wrappers survive;
- JSON/CSV publication is byte-faithful to declared runtime sources unless a schema-declared deterministic aggregate projection applies;
- public Markdown is normalized by the toolkit to UTF-8 without BOM + LF-only;
- publication manifest records source identity, published identity, generation mode, transformation policy, size, and SHA-256;
- privacy, schema/shape, token fidelity, manifest coverage, and dataset consistency are validated before atomic promotion;
- accepted generated files must record `HandEdited=false`.

Git repository attributes must preserve the generated `public/**` bytes verbatim so Git line-ending conversion cannot invalidate the manifest hashes.

## Evidence layers

The research model keeps provenance explicit:

1. **Published** — AMD support-page/download facts.
2. **Embedded** — metadata bundled in the installer.
3. **PayloadObserved** — files/INF/XML reached by static extraction.
4. **StaticSignature** — host-neutral PE/CMS/X.509/catalog-file evidence reconstructed from extracted bytes.
5. **Analysis** — toolkit-derived INF selector, AMD selector, WDF, signature classification inputs, and comparison results.
6. **WindowsNative** — current Windows trust/API/tool observations; this is not Target Server runtime proof.
7. **TargetServerHost** — read-only observations collected while actually executing on a Windows Server host.
8. **Runtime** — install/load/Code Integrity/device-function observations collected by a separate qualification activity.

Derived analysis must not overwrite the source evidence that produced it. `NotObserved` is not equivalent to `Fail`.

## Current qualified baseline

The current repository-qualified generated dataset is the accepted **v3.0.0**
Gate 2C publication incorporated during Cycle B. Its publication manifest
contains 67 payload rows and the public tree contains 68 files including the
manifest. It is retained byte-for-byte after incorporation and was not
hand-edited.

The earlier v2.0.0 publication remains historical qualification evidence. Its
measurements are retained below for audit comparison and do not override the
current v3.0.0 public authority:

- 25 AMD Chipset Software releases;
- 643 INF package records;
- 25 canonical per-release Raw JSON analyses;
- 25/25 recovered MSI databases parsed read-only during the Windows qualification run;
- 13,993 selected MSI declarative rows with zero all-null rows;
- four Windows Server applicability profiles per eligible package/selector row;
- exact selector-token fidelity checks and publication provenance.

These are static/research measurements, not AMD support claims and not runtime deployment acceptance.

The accepted 2.1.13 signature qualification target remains the exact
`8.07.16.1035` artifact and found 209 unique static signature artifacts after
replacing extension-only discovery with content/name-pattern discovery: 35
kernel binaries, 46 catalog variants, 102 libraries, 23 executables, and 3
additional PE files. All 35 kernel binaries and all 46 catalogs contain
Microsoft Windows Hardware Compatibility Publisher signer evidence in the
recursive static analysis. Windows-native policy checks for this pinned
qualification were accepted separately; neither the static nor native result
is driver-installation, kernel-load or device-function proof.

## Relationship to deployment and self-signed driver work

The toolkit deliberately stops before transformation or installation.

A future or existing project-owned pipeline can consume the research as:

```text
AMD source artifact
  -> immutable source identity
     -> package / INF topology
        -> target hardware + Server candidate decision
           -> AMD selector evidence (independent audit signal)
              -> per-package WDF decision
                 -> explicit project deployment plan
                    -> derived INF/package transformation
                       -> catalog regeneration
                          -> project signing
                             -> target Windows Server runtime qualification
```

The source AMD artifact, selected INF/package set, transformation delta, derived hashes, signing identity, and target-host runtime evidence should remain linked throughout that pipeline.

`RESEARCH-NOTES.md` records the detailed engineering lessons intended for downstream chipset self-signed build/deployment work.

## Known boundaries

The toolkit intentionally does not claim:

- that every historical AMD chipset release is recoverable forever;
- that AMD's installer selector and Microsoft INF/PnP use equivalent rules;
- that a Server projection is vendor support;
- that a static candidate will load or operate correctly;
- that WDF compatibility proves driver loadability;
- that an AMD selector empty result proves the driver payload is incompatible;
- that same-generation Qt selectors share every compiled predicate;
- that unresolved old-major hardware predicates may be copied from newer releases;
- that static research replaces physical target-OS qualification.

Unknowns remain explicit instead of being silently promoted to compatibility claims.

## Sequential AMD network and diagnostic-trace contract (2.1.15)

AMD-hosted metadata and driver artifacts are fetched **sequentially**. The toolkit does not use `Start-Job`, thread jobs, runspace pools, or `ForEach-Object -Parallel` for AMD network acquisition. The maximum intended AMD HTTP concurrency is `1`. This is a deliberate vendor-safety contract intended to reduce throttling, WAF and blocklist risk; it is also the default common-primitive policy planned for NPU, Graphics, and later production deployment/re-signing scripts.

The 2.1.14 retry/backoff transport remains the network core. Version 2.1.15 adds a device-family-neutral diagnostic layer around it:

- lightweight append-only `logs/diagnostic-events.jsonl` for stage/step/HTTP-attempt events;
- bounded in-memory recent-event history used only for failure snapshots;
- `errors/failure-snapshots/*.json` emitted automatically on stage/fatal failures;
- exception-chain, invocation and script-stack context;
- redacted HTTP response headers;
- bounded response-body preview for HTTP failures;
- structured retry/classification/delay details without duplicating the console transcript;
- best-effort diagnostics: trace failures must never become research failures.

Sensitive headers and obvious credential-bearing URL query parameters are redacted before structured diagnostic persistence. Response-body previews are bounded; raw unlimited HTML/error bodies are not added to the trace stream.

Diagnostic trace is Evidence, not a permanent product log. Under project Evidence governance it is normally E0 on a successful run, E1 while diagnosing a failure, and is compacted after durable root-cause knowledge and corrective qualification are established.

Built-in Test-stage regression checks require both `DiagnosticPrimitiveSelfTest : Pass` and `SequentialDownloadSourceContractSelfTest : Pass`.

## Release qualification

The authoritative release checklist is `TESTING.md`.

A release candidate is not accepted merely because all research stages pass. Version 2.1.14 additionally requires the Windows Client acquisition/signature qualification described in `TESTING.md`; Target Server host evidence is qualified separately and must not be inferred from a Client run. Source static analysis, Windows PowerShell 5.1 full-run behavior, canonical Raw JSON conservation, MSI evidence quality, publication privacy/schema/byte-format contracts, manifest/source provenance, Git byte identity, and private Evidence integrity are independent gates.

If generated output is incorrect, fix the toolkit and regenerate it. **Do not hand-edit generated release artifacts.**

## Toolchain capability and localization evidence (2.1.10)

Windows runs inventory the actual SignTool and Inf2Cat binaries used by the research environment before driver-signature qualification. The toolkit records a host-portable summary in `inventory/toolchain-capabilities.json` and raw help/path evidence in `inventory/host/toolchain-capabilities-private.json`.

The summary records binary SHA-256, size, file/product version, PE architecture, Windows Kit version/path class, help-output digests, observed command-line options, and an explicit verification-profile contract. Inf2Cat observations include the Server 2016/2019/2022/2025 target tokens when advertised by the installed tool. Missing Windows SDK/WDK tools are recorded as `NotFound`; they do not make static research unavailable. Raw help output and absolute executable paths remain private and are never part of `public/**`.

This evidence distinguishes **tool capability** from **host trust behavior** and from **target policy**. A help-advertised option is an observation, not proof that every option combination is valid. Actual SignTool qualification commands therefore retain a semantic `VerificationProfileId`, their exit code, result classification and output digest.

The toolkit also captures a `LocalizationContext` for every Windows toolchain snapshot: PowerShell culture/UI culture, Windows user/system locale and UI language, numeric console input/output code pages, console encodings, and any `LANG`/`LC_ALL`/`LC_MESSAGES` environment hints. These POSIX variables are informational only for Windows SDK/WDK tools; the toolkit does **not** claim that `LANG=C` can force SignTool or Inf2Cat into English. Help capability detection searches invariant command tokens such as `/kp`, `/o`, `/driver:` and `Server2025_X64` with ordinal case-insensitive matching. Raw localized output remains private evidence.


## PowerShell 5.1 collection-cardinality hardening (2.1.10)

Windows PowerShell 5.1 can collapse a zero-result statement-expression assignment to `$null` and a one-result assignment to a scalar. Under `Set-StrictMode -Version 2.0`, direct `.Count` access on those shapes is unsafe.

The toolkit therefore treats collection cardinality as an explicit shared contract: any 0/1/N result that will be counted is normalized before cardinality evaluation. Built-in Test-stage regression checks guard both runtime behavior and the specific source pattern that caused the 2.1.9 Windows failure.

This rule is part of the common primitive baseline that will later be propagated from Chipset to NPU and Graphics.
## Evidence output location (rev48 common contract)

By default, final evidence is stored only under `<tool-root>\private\evidence`. The file identified by `EVIDENCE ZIP TO SHARE` is the review artifact; its adjacent `.zip.sha256` file verifies integrity, and `LATEST-EVIDENCE.txt` points to the most recent successfully verified archive.

Raw collection uses a short path under `private\evidence\runs\r<UTC>-<8hex>`. The default `-EvidenceRetention ZipOnly` removes that directory only after ZIP integrity verification and SHA-256 generation. Use `-EvidenceRetention ZipAndDirectory` only when raw diagnostics must remain. `-EvidenceOutputRoot` is retained for compatibility but accepts only the canonical root or a descendant; external, UNC, SUBST-backed, and reparse-point paths are blocked before research starts.
## rev57 cross-tool common-core convergence

The runner now prepends `PathSafety` to every selected workflow. On Windows it blocks unsafe UNC, reparse/SUBST, excessive tool-root, and predicted extraction paths before AMD network access. Every 7-Zip container is listed with `7z l -slt`; rooted, parent-traversal, and over-limit entries are rejected before extraction.

`data/current-three-tool-common-core-contract.json` is the current parity authority for function bodies shared with Graphics and NPU. The Test stage verifies this contract, ordinal ordering, archive path safety, and the hardened Windows PowerShell 5.1 collection-cardinality audit. Chipset-specific release-note, MSI, selector, processor/chipset support, and host-match behavior remains separate.
