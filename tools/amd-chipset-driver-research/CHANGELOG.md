## 3.0.0 REV81 coordinated documentation closeout — 2026-08-22

- Records Claude's REV80 Cycle B closure and removes stale current-facing
  REV69-REV77 candidate/pending language from README, SPEC and TESTING.
- Declares the accepted v3.0.0 Gate 2C public surface and exact REV77 Server
  smoke as the current no-repeat authorities while retaining earlier gates as
  historical evidence.
- Changes documentation only. The root script, contracts, schemas, reviewed
  data, generated public bytes, canonical path and accepted Evidence are
  unchanged; no Windows rerun is required.

## 3.0.0 REV78 coordinated qualification update — 2026-08-22

- Accepts the exact REV77 Windows Server / Windows PowerShell 5.1 Chipset smoke
  as 2/2 PASS with authoritative host identity and no-repeat status.
- Keeps the Chipset source, schemas, data, and generated public tree unchanged;
  REV78 corrects an NPU-only architecture-contract hash set.

## 3.0.0 REV77 execution-context Evidence correction — 2026-08-22

- Keeps the executable version at `3.0.0` and the canonical path unchanged.
- Adds a shared, typed actual-host `ExecutionContext` to normal and emergency
  private `run-context.json` evidence.
- Adds six synthetic classification/fallback cases to all three Test stages.
- Advances the Chipset private Evidence schema from `1.1` to `1.2`; generated
  public research data is unchanged.

## 3.0.0 REV76 qualification handoff — 2026-08-22

- Keeps the root script and executable version byte-identical to REV75.
- Records Chipset Gate 2C as accepted/no-repeat and defines the remaining direct
  Windows Server `PathSafety,Test` common-contract smoke.
- Adds no test launcher and makes no schema or generated-public change.

## 3.0.0 REV70 transcript-hygiene correction — 2026-08-21

- Keeps the released tool identity at `3.0.0`; no version increment is made.
- Adds a structured non-throwing result path to the shared extraction-completeness
  assertion for negative self-tests only. Normal downstream callers remain
  fail-closed and continue to throw on zero or incomplete extraction records.
- Stops `Test-AmdPathSafetyLogic` from injecting an expected caught terminating
  error into Windows PowerShell 5.1 transcripts.
- Clarifies hardware-present and hardware-absent qualification profiles in
  `TESTING.md`; package research is not represented as device installation or
  runtime qualification.

## REV65 documentation-authority refresh — 2026-08-21

- Updates README/SPEC/TESTING current status after the accepted REV63 Windows
  Server `PathSafety,Test` smoke and REV64 test-launcher exclusion.
- Corrects stale wording that described completed Windows-native qualification
  as pending and clarifies that later source qualification does not silently
  replace the retained v2.0.0 generated public corpus.
- Adds a downstream build-script feedback contract without changing the
  PowerShell source, schemas, data or generated `public/**`.

## rev59 public-path audit correction — 2026-08-20

- Corrects the Windows REV58 publication failure: nested `PathSafety.ArchivePath` is now included in portable path conversion before per-release Raw JSON is written.
- Confirms the submitted run completed all 12 research stages; the 1,076 publication errors were two reports of each of 538 unconverted archive-path scalars, not extraction or signature failures.
- Converges public forbidden-pattern detection, decoded JSON scalar traversal and path-property classification across Chipset, Graphics and NPU.
- Adds a regression assertion for nested archive paths and preserves vendor selector/MSI tokens that are not execution-host paths.

## rev58 cross-tool path-safety correction — 2026-08-20

- Replaces the version/filename/hash-derived extraction tree with the common short `work\\x\\aNNNN\\cNNNN` layout used by PathSafety prediction.
- Adds a shared extraction-completeness gate. Any zero, partial, failed, or path-blocked extraction set now terminates Extract and blocks downstream analysis; signature analysis cannot report PASS from a zero-file incomplete release.
- Adds stable artifact/container path identifiers while preserving original filenames and release identities in inventory evidence.
- The submitted Windows run remains defect evidence, not qualification evidence. Local PowerShell 7.6.5 `PathSafety,Test` passes; exact-source Windows PowerShell 5.1 correction qualification remains pending.

## rev56 release-note correlation and Ryzen AI PMF disambiguation — 2026-08-20

- Adds a schema-backed `data/curated-release-notes.json` record generated from the user-supplied AMD 8.08.12.551 page capture: 17 chipset rows, 21 processor rows, 37 package rows, two release highlights and three known issues.
- Correlates every public Windows 10/11 package version with exact-name `Info.xml` products while preserving typed differences instead of silently normalizing them. The 8.08 installer produces 59 version matches, 2 version mismatches, 3 internal-product/public-Not-Applicable observations and 10 Not-Applicable/no-product observations.
- Separates `SETNAIPMF300` and `SETTAIPMF300` into Ryzen AI 300 PMF Driver 1 and Driver 2. Each selector now correlates to exactly one distinct `Info.xml` product.
- Adds `CuratedReleaseNoteCorrelationSelfTest` and extends selector-product correlation regression coverage. PowerShell 7.6.5/Linux Test and the exact 8.08.12.551 Selector run pass.
- Keeps release-note processor support explicitly outside NPU package selection and Windows Server support authority. The supplied CPU/NPU matrix does not justify a change to the frozen NPU source.

## rev55 current-latest 8.08.12.551 data and selector-correlation hardening — 2026-08-20

- Adds AMD Ryzen Chipset Software 8.08.12.551 to the curated release seed and makes its exact AMD release-note URL the current-latest qualification identity.
- Prefers the exact vendor filename `AMD_Chipset_Software_<version>.exe` as the first deterministic major-4+ acquisition candidate while retaining the established lowercase fallback candidates.
- Updates exact-release URL self-tests from 8.07.16.1035 to 8.08.12.551 and adds a fail-closed curated-current-latest test covering seed uniqueness, semantic newest selection, release-note identity, and preferred installer URL.
- Adds selector aliases for `SETWIRELESSFILTER`, `SETVIRTUALSTORAGE`, and `SETSDXINULL` and records `ProductCorrelationStatus`/`ProductCorrelationNote` for every DevID.xml rule. A selector token without an Info.xml product match is now explicit unresolved evidence instead of a silent empty candidate list.
- Static offline qualification of the user-provided 8.08.12.551 installer passed Extract, Inspect, Signature, and Selector with 25 containers, 31 INF files, 209 unique signature artifacts, 35/35 embedded-signed kernel binaries, and 44 DevID.xml rules.
- The exact 8.08.12.551 Qt selector SHA-256 is new and therefore correctly has no compiled-selector contract. The toolkit does not generalize the 8.07.16.1035 exact-binary contract; deeper disassembly and any Windows host qualification remain separate gates.

## rev53 Windows PowerShell 5.1 empty native-output hardening — 2026-08-20

- Normalizes PS5.1's `$null` representation of an empty emitted byte array to
  a zero-byte payload before SHA-256 calculation.
- Adds the shared empty native-output hash regression assertion used by the
  Graphics `PathSafety` correction.

## rev52 Windows PS5.1 evidence acceptance and interruption hardening — 2026-08-19

- Accepts the submitted Windows PowerShell 5.1 Test-only evidence: exact rev51 source, Test PASS, Canonical JSON PASS, verified ZIP and internally complete manifest.
- Normalizes private Evidence manifest relative paths to ZIP-standard forward slashes for cross-platform review.
- Retains the rev51 fail-closed `RUNNING` to `INTERRUPTED` stage transition as the three-tool reference behavior.

## rev51 Canonical JSON performance and evidence recovery — 2026-08-19

- Replaces the slow PowerShell character parser/writer with the byte-compatible embedded .NET Canonical JSON runtime.
- Skips runtime-baseline restoration for `Test`-only execution and lazily reconstructs the monolithic driver aggregate only when required.
- Moves visible bootstrap/stage information ahead of long work and adds per-check/per-file elapsed progress.
- Accepts unresolved/empty stage state during finalization and records it as non-PASS.
- Adds verified emergency ZIP/SHA-256 creation with raw-directory retention when the normal finalizer fails.
- Adds clean-copy, large-corpus, bootstrap-failure and forced-finalizer-failure gates.

## rev50 Canonical JSON convergence — 2026-08-19

- Ports the cross-runtime Canonical JSON writer, parser, atomic file writer,
  byte validator and object SHA-256 helper.
- Routes all `Write-AmdJsonFile`/`Read-AmdJsonFile` calls through that contract.
- Adds a Python-reference fixed-vector test to the normal `Test` stage.

## 2.1.17 - development preview

- Fixes the remaining Windows PowerShell 5.1 transcript-noise defects discovered during 2.1.16 Gate A/B review.
- Replaces expected missing-assembly probing with a managed C# no-throw assembly probe. `Assembly.Load` exceptions are caught inside managed code and returned as structured data, preventing PowerShell `TerminatingError` transcript entries for expected fallback tests.
- Keeps `ExpectedFallbackProbeSelfTest`, but now validates the actual no-throw managed probe implementation.
- Adds `Test-AmdSpcIndirectDataContentType` and changes the content-type routing self-test to verify routing without deliberately injecting malformed Authenticode DER into the normal Test stage.
- Removes the synthetic `DER element offset is outside the input buffer` transcript line from routine self-test design while preserving real parser-failure behavior when malformed research data is actually encountered.
- Establishes an explicit platform-boundary quality gate: Windows 11 evidence must be reviewed before Windows Server 2025 execution is authorized.
- Avoids repeating the 7.02 HTTP regression fixture because 2.1.17 does not change the already-qualified transport path; one Windows 11 current-latest Full run is the minimum sufficient next test.

## 2.1.16 - development preview

- Adopts the pre-propagation quality rule that known portable/common diagnostic defects are fixed at the Chipset reference implementation before NPU/Graphics expansion.
- Narrows structured diagnostic key redaction from broad `signature` substring matching to explicit credential/session key semantics. Public research fields such as `HasMzSignature`, `HasZipSignature`, and signature status remain visible; signed-URL credential keys such as `X-Amz-Signature` remain redacted.
- Extends `DiagnosticPrimitiveSelfTest` with both positive secret-redaction and negative over-redaction regression cases.
- Adds `Invoke-AmdExpectedAssemblyLoadAttempt` and `ExpectedFallbackProbeSelfTest`. Optional SignedCms assembly probing now captures unavailable-assembly errors as structured fallback evidence without writing misleading expected errors to the user-visible PowerShell Error stream.
- Changes `Initialize-AmdSignedCmsRuntime` to use the quiet structured assembly-probe primitive and records `ExpectedAssemblyFallback` diagnostic events when a fallback is actually used.
- Removes the deliberately thrown invalid-version path from `RequestedReleaseDiscoverySelfTest`; negative validation no longer needs to pollute the transcript with a caught terminating error.
- Defines three minimum-sufficient Windows pre-propagation gates: 7.02 real network/diagnostic regression fixture, 8.07 Windows 11 current-latest qualification, and 8.07 Windows Server 2025 TargetServerHost qualification.
- No INF/selector/signature acceptance rule, historical model finding, or current-latest target identity is relaxed.

## 2.1.15 - development preview

- Standardizes AMD network acquisition as **sequential by default** with intended maximum HTTP concurrency `1`; no background-job, thread-job, runspace-pool, or `ForEach-Object -Parallel` acquisition is introduced. The policy is intended for later NPU/Graphics and production deployment/re-signing propagation.
- Retains the 2.1.14 bounded retry/backoff/`Retry-After`/fresh-transport logic as the transport authority; 2.1.15 does not replace it with a second retry implementation.
- Adds a lightweight structured diagnostic subsystem: append-only `logs/diagnostic-events.jsonl`, bounded recent-event history, stage/function/step context, and automatic JSON failure snapshots for tracked-stage and top-level failures.
- Adds HTTP failure diagnostics with redacted response-header capture and bounded response-body preview when available. Diagnostic writes are best-effort and cannot become a research failure cause.
- Adds sensitive diagnostic redaction for authorization/cookie/secret/token/API-key/signature-like fields and obvious credential-bearing URL query parameters.
- Adds `DiagnosticPrimitiveSelfTest` and `SequentialDownloadSourceContractSelfTest` covering redaction, bounded preview, concurrency=`1`, and absence of known PowerShell parallel-execution primitives in executable command AST.
- Records diagnostic trace path, failure-snapshot directory and HTTP maximum concurrency in run context/summary.
- Supersedes the unqualified 2.1.14 Windows test candidate; the active 7.02.13.148 E1 failure remains causal Evidence and Windows correction qualification proceeds directly with 2.1.15.

## 2.1.14 - development preview

- Fixes the 7.02.13.148 Windows 11 historical-boundary failure captured in `AmdChipsetDriverResearchEvidence_20260815-064314_Windows.zip`: the first AMD release-note GET ended with a transport `ConnectionClosed`, Metadata had no retry, installer-candidate generation was incorrectly gated on successful HTML, Acquire emitted `MissingUrl` with zero candidates, and Signature later failed only as a secondary consequence of zero extracted releases.
- Adds a shared HTTP retry taxonomy for metadata and installer transfer paths. Retryable cases include connection closure/timeouts/connect/send/receive failures, HTTP 408/425/429/500/502/503/504, conservative AMD-side transient 403 handling, and repairable download-integrity rejections. Permanent 400/401/404/405/410/422 responses fail fast.
- Adds bounded exponential backoff with jitter, parseable `Retry-After` handling, cache bypass and disabled keep-alive on retry attempts. Attempt evidence records retryability, reason, WebException status, delay and transport mode.
- Raises installer download attempts from 2 to 4 and applies the same retry-policy evidence to the existing partial-content/byte-conservation download contract.
- Decouples deterministic installer-candidate generation from release-note HTML success. Exact version-derived `drivers.amd.com` candidates remain available after metadata failure, preventing `candidates=0` for a transient page fetch.
- Adds vendor-observed historical release-note aliases for exact releases whose AMD CMS URL was migrated; 7.02.13.148 currently resolves under AMD's 6.10.17.152 legacy path while preserving the exact article/version identity.
- Fails an explicitly requested release at **Acquire** when all candidates/retries are exhausted, after writing `acquisition.json`; downstream extraction/signature/build stages are blocked instead of producing a misleading secondary Signature failure.
- Adds `HttpRetryPolicySelfTest` and `ReleaseNotesUrlCandidateSelfTest`. The existing current-latest qualification and historical research semantics are unchanged.

## 2.1.13 - development preview

- Fixes a pinned-release discovery failure exposed by the 2.1.12 Windows requalification: after Gate B, both AMD sitemap endpoints returned HTTP 403 during Gate C, Discover emitted zero releases, and Signature failed before any signature verification was attempted.
- Confirms by source comparison that `Invoke-AmdDiscoverStage` was byte-identical between 2.1.11 and 2.1.12; the failure was a latent dependency on global sitemap availability, not a regression in the 2.1.12 per-kernel signature-coverage evaluator.
- Adds exact-release discovery mode. When `-ReleaseVersion` is supplied, Discover resolves only the requested release(s), uses operator/seed evidence when present and otherwise a canonical AMD chipset release-note URL, skips global sitemap enumeration, and records the decision in discovery diagnostics.
- Filters pinned runs before Metadata so a one-release qualification does not re-fetch unrelated historical release notes. Metadata still validates the selected release-note page before acquisition.
- Adds `RequestedReleaseDiscoverySelfTest`, including canonical URL round-trip and invalid-version rejection.
- Retains the 2.1.12 payload-acceptance and per-kernel signature-coverage hardening unchanged.

## 2.1.12 - development preview

- Records successful Windows 11 / Windows PowerShell 5.1 qualification of 2.1.11: Test gate PASS, 7.11.26.2142 network acquisition PASS with the exact independently browser-downloaded SHA-256/size, and pinned 8.07.16.1035 full run PASS.
- Confirms the 2.1.11 SignTool profile correction on real Windows: 35/35 explicit catalog kernel-policy checks Verified and 140/140 explicit catalog WS2016/WS2019/WS2022/WS2025 target checks Verified, with no tool execution failures.
- Hardens AMD download regression protection by factoring post-transfer payload acceptance into a shared pure decision used by runtime and Test-stage self-test. The self-test now proves exact-length valid payload acceptance plus truncated-body `ByteCountMismatch`, empty-body rejection, and invalid-installer rejection.
- Hardens Signature assessment from aggregate counts to per-kernel catalog-bound coverage. Every catalog-associated kernel binary must have at least one verified explicit `/kp /c` check and verified target checks for all four Server profiles; any per-file coverage hole forces `SignatureAnalysis=REVIEW`.
- Clarifies that unbound `signtool verify /all /v /kp <driver>` is supplemental diagnostic evidence. The retained 2.1.11 qualification observed 33 non-zero results there, but each had already verified one or more signatures and all required explicit catalog-bound checks passed. The summary now labels this diagnostic-only to prevent false interpretation as a catalog-bound failure.
- Adds `KernelSignatureCoverageSelfTest` and extends `HttpDownloadTransportSelfTest` with payload-level acceptance cases.
- No schema version bump is required: the hardening changes assessment/self-test behavior and documentation without an incompatible generated-data shape change.

## 2.1.11 - development preview

- Qualifies the 2.1.10 Windows PowerShell 5.1 cardinality correction: the 2026-08-14/15 Windows 11 full run completed all 11 selected stages without terminating errors, proving the 2.1.9 StrictMode/cardinality blocker is resolved.
- Hardens AMD installer acquisition after the same Windows run reproduced the historical 7.11.26.2142 download defect. The invalid 54,199,901-byte payload is byte-for-byte the suffix of the browser-downloaded 78,301,768-byte vendor EXE beginning at offset 24,101,867, proving that the previous transport path accepted an incomplete object as though it were a complete file.
- Adds a browser-like AMD download session contract: release-note preflight, a fresh `CookieContainer`, the exact release-note HTTP referrer, cache-bypass retry, response URI/header evidence, explicit `Download-Incomplete` redirect rejection, `Content-Range`/HTTP 206 completeness checks, content-length/byte-count conservation, `.partial` staging, installer-format validation before atomic promotion, and diagnostic retention for invalid payloads.
- Adds `HttpDownloadTransportSelfTest`, including the observed partial-content shape, full-response and complete-range cases, unexpected `Content-Range`, and AMD `Download-Incomplete` redirect rejection.
- Corrects catalog-bound SignTool profiles after the 2.1.10 Windows 11 evidence showed all 140 `/kp /c <catalog> /o <target> <driver>` checks exited before trust verification with a SignTool option-compatibility error. The new design separates Microsoft-documented catalog-bound kernel-policy verification (`/kp /c`, no `/o`) from explicit target-OS Windows Driver Verification Policy checks (`/c /o`, intentionally no `/kp` and no `/pa`).
- Adds `SignToolVerificationProfileSelfTest` to prevent `/kp`+`/o` or `/pa` from reappearing in the target-OS profile and to preserve WS2016/2019/2022/2025 target versions.
- Stops treating non-SPC CMS content as malformed `SpcIndirectData`. RFC3161 timestamp TSTInfo and catalog CTL content now report `NotApplicableContentType` rather than repeated false `ParseFailed` observations; only Authenticode `SpcIndirectDataContent` is routed to the SPC digest parser.
- Adds `SignatureContentTypeRoutingSelfTest` for RFC3161, catalog, and Authenticode SPC content-type routing.
- Keeps native stdout/stderr locale-neutral and diagnostic-only. Windows-native requalification is required before any target-policy conclusion or generated-baseline promotion.

## 2.1.10 - development preview

- Fixes a Windows PowerShell 5.1 `StrictMode` cardinality failure in `NativeInteropTypeContractSelfTest`: assigning an `if (...) { ... }` statement expression directly to a variable can collapse an empty result to `$null` or a one-item result to a scalar, so direct `.Count` access is unsafe.
- Normalizes the entire conditional missing-method expression with `@(...)` for catalog, localization, and InstallShield native interop contracts.
- Adds `PowerShell51CollectionCardinalitySelfTest` covering zero-, one-, and multi-item cardinality, including the exact missing-static-method pattern that failed in 2.1.9.
- Adds `CollectionCardinalitySourceContractSelfTest`, which fails closed if the source reintroduces the specific unsafe `$x = if (...)` followed by `$x.Count` pattern.
- Audits the current Chipset source for the same failure family and records the collection-cardinality contract as a shared primitive requirement for later NPU/Graphics migration.
- Current `main` NPU and Graphics scripts were also checked for this exact `if`-assignment + `.Count` pattern; no same-function matches were found, so no sister-tool source change is required at this stage.
- Preserves the coordinated 3.0.0 release plan; Chipset remains the reference implementation before NPU then Graphics migration.

## 2.1.9 - development preview

- Fixes repeated-preview execution in the same Windows PowerShell process: in-process C# `Add-Type` helpers now use contract-versioned CLR type names instead of reusing older preview definitions.
- The 2.1.8 Windows 11 evidence proved the failure mode: all 35 kernel catalog-hash probes failed because an older already-loaded `AmdResearchCatalogNative` type lacked the newer `CalculateCatalogHashes` method even though the 2.1.8 source contained it.
- Adds `NativeInteropTypeContractSelfTest` to verify required static methods for catalog, localization, and InstallShield helper types before a full run continues.
- Strengthens native helper initialization to validate required method contracts rather than treating type-name existence alone as readiness.
- Renames publication suppression for `ReviewRequired` from misleading `NotAttemptedRunIncomplete` to `NotAttemptedAssessmentNotEligible`; a fully executed run blocked by research assessment is no longer described as incomplete.
- No driver-selection, INF-semantic, signing-policy, or publication-content rules are relaxed. Catalog-bound Server target verification remains fail-closed until Windows requalification succeeds.

## 2.1.8 - development preview

- Fixed Windows PowerShell 5.1 binding failure when a tool family intentionally defines an empty capability-token collection (for example SignTool `TargetTokens=@()`).
- `Get-AmdOptionObservationsFromText` now explicitly accepts empty token collections and returns an empty observation set.
- Added a regression self-test for the empty-token case to `NativeToolLocalizationSelfTest`.
- Interrupted runs now report unreached or interrupted Acquire/Extract/Inspect assessments as `NOT_ASSESSED` instead of `REVIEW`.
- No signing, publication, or deployment semantics changed in this revision.

## 2.1.7 - development preview

- Harden SignTool/Inf2Cat/native-tool handling against Windows localization differences. Canonical success/failure classification no longer parses English diagnostic sentences.
- Add shared `amd-native-tool-localization-context/1.0` evidence: PowerShell culture/UI culture, Windows user/system locale/UI language where observable, numeric console code pages, console encodings, and informational `LANG`/`LC_ALL`/`LC_MESSAGES` hints.
- Explicitly record that Windows SDK/WDK tool output language is not forced and that POSIX locale variables are not a supported Windows native-tool language contract.
- Change native process/result classification to locale-neutral signals: process launch, numeric exit code, invariant CLI-token capability observations, and result coverage. SignTool results are `Verified`, `NonZeroExit`, or `ToolExecutionFailed`.
- Add `NativeToolLocalizationSelfTest`, including Japanese localized diagnostic text, proving token parsing and result classification do not require English output.
- Bump toolchain capability summary to 1.1, environment evidence to 1.3, and Windows-native signature verification evidence to 1.2.
- Fail closed when catalog-bound target-OS checks are produced but none verify successfully; this avoids guessing whether all non-zero exits are policy negatives or command rejection from localized prose.

# Changelog

## 3.0.0 REV69 Cycle B candidate — 2026-08-21

- Synchronizes the three research-tool executable identities at `3.0.0`.
- Adds the explicit Windows PowerShell `#requires -Version 5.1` contract.
- Retains research behavior while invalidating exact-source qualification by
  changing the source identity; fresh Cycle B gates are therefore required.
- Requires generated `public/**` replacement from current authorities on a
  Windows Client. The retained REV68 public tree is input history only and is
  not hand-edited or presented as a current `3.0.0` output.

## 2.1.17 rev57 common-core convergence preview - 2026-08-20

- Adds the shared `PathSafety` bootstrap stage and fail-closed archive-entry/path-length preflight before 7-Zip extraction.
- Aligns 7-Zip executable probing, collection-cardinality source auditing, repository-relative path normalization, empty native argument handling, emergency bootstrap evidence, and ordinal ordering with the NPU/Graphics tools.
- Adds the current three-tool common-core hash contract and self-test; the frozen predecessor snapshot is no longer used as current parity authority.
- Preserves chipset-specific release-note, selector, MSI, host-survey, and support-correlation adapters.

## rev49 Windows PowerShell 5.1 SignedCms correction — 2026-08-19

- Corrects the rev48 Windows PowerShell 5.1 `SignaturePrimitives` failure. The
  fallback now loads the .NET Framework `System.Security` assembly by complete
  strong name instead of the unreliable partial name.
- Adds a source-contract assertion so a future partial-name backport is rejected
  by the short `Test` stage.
- The submitted rev48 failure Evidence ZIP was valid and integrity-tested; this
  correction changes the Test primitive, not the common evidence ZIP contract.

## 2.1.6 - development preview

- Add shared `ToolchainCapabilityEvidence` for SignTool and Inf2Cat.
- Record binary SHA-256, file/product versions, architecture, portable Windows Kit identity, help-output digests, observed options, and Inf2Cat Server target tokens.
- Preserve raw help output and absolute tool paths only in private evidence while publishing a host-portable summary.
- Add semantic verification-profile IDs to SignTool observations so CLI syntax can evolve without changing the meaning of the research claim.
- Add a non-mutating toolchain capability parser self-test.
- Publish `public/inventory/toolchain-capabilities.json` only through the existing fail-closed Build/publication gate.


## 2.1.5-signature-dev — 2026-08-15
- Fixes `public/**` publication failure observed in the Windows 11 2.1.4 qualification: runtime absolute paths embedded inside free-text error/detail fields are now normalized to repository-neutral evidence markers before canonical per-release JSON is written. The strict decoded-scalar privacy validator remains fail-closed.
- Adds a regression self-test for embedded runtime paths inside acquisition error text while preserving vendor selector tokens such as `/SETFILTERUSB`, `/info.xml`, and MSI values such as `C:\`.
- Corrects Windows-native target-OS verification design. `SignTool /o` checks no longer use `/a`; kernel binaries are correlated to catalogs by Windows catalog/SIP hashes (`CryptCATAdminCalcHashFromFileHandle2`) matched to enumerated CAT member reference tags, then verified with the documented explicit `/kp /c <catalog> /o <target> <driver>` relationship.
- Separates SignTool process health from trust-policy outcome. Native checks now record `ResultClass` (`Verified`, `MixedSignatureResult`, `VerificationFailed`, or `ToolInvocationError`), so a legitimate negative trust observation is research evidence while invalid command construction still forces `REVIEW`.
- Makes mixed multi-signature kernel results visible. A vendor-primary plus Microsoft-secondary file that verifies at least one signature but returns nonzero under `/all /kp` is retained as `MixedSignatureResult` rather than being confused with a tool invocation failure.
- Expands the Summary detail for Signature to show catalog-bound target verification counts and mixed multi-signature observations instead of reporting only total native-check count.
- Widens console status alignment so `[PASS_WITH_NOTES]` no longer runs directly into the assessment name.
- The Windows 11 2.1.4 run remains non-publication-qualified: its static Signature evidence is healthy, but its target-OS `/o` checks used an invalid `/a` combination and the staged public dataset failed strict privacy validation. Re-run with 2.1.5 is required.
- Coordinated final release target for Chipset/NPU/Graphics is `3.0.0`; 2.1.5 remains an internal Chipset stabilization preview.

## 2.1.4-signature-dev — 2026-08-14
- Blocks publication from Test-only/analysis-only runs; a current-run successful `Build` is now mandatory before `public/**` can be regenerated, preventing partial-state publication during qualification.

- Reclassifies automatic historical acquisition gaps: if the newest discovered release is available and only older vendor artifacts are currently unavailable, the run records `PASS_WITH_NOTES` / `PassWithNotes` with exit code 0 instead of `REVIEW`. Explicitly requested missing releases and a missing newest release remain `REVIEW`.
- Allows validated `public/**` publication for `PassWithNotes`, preserving unavailable historical releases as explicit canonical acquisition gaps rather than suppressing the entire public update.
- Makes private Evidence ZIPs self-contained by copying a successful validated public publication under `snapshot/public/**` while retaining `public/**` as the only generated Git commit surface.
- Backports cross-tool hardening from later Graphics/NPU research implementations into the Chipset reference implementation: ordinal string sorting primitive, Windows PowerShell 5.1 source byte-contract self-test, toolkit-version consistency self-test, and run-scoped Build output cleanup.
- Fixes Windows SignTool target-build probing: `/o` is now paired with `/a` and applied to kernel binaries only. The 2.1.3 Windows evidence proved every prior `/o` invocation failed at command-usage level because SignTool requires `/o` together with `/a`, `/ad`, `/ag`, `/as`, or `/c`.
- Adds byte-identical `.cat` aliases for recursively extracted collision names such as `*.cat1`, preventing extension-induced WinVerifyTrust `HashMismatch` from being mistaken for a damaged vendor catalog.
- Extends Signature assessment to distinguish legitimate negative verification observations from Windows-native tool invocation/configuration errors; the latter force `REVIEW`.
- Keeps the repository-qualified generated baseline at v2.0.0 until 2.1.4 completes Windows 11 and Windows Server 2025 qualification.

## 2.1.3-signature-dev — 2026-08-14

- Changes Chipset signature qualification scope: `Signature` now analyzes exactly one release from the selected set. A single `-ReleaseVersion` is honored exactly; otherwise the newest semantic release is selected. Discover/Metadata/Acquire/Extract/Inspect/Selector/Build retain their full historical scope.
- Records `ReleaseSelectionPolicy`, `CandidateReleaseCount`, and `AnalyzedReleaseVersions` in static and Windows-native signature evidence.
- Adds per-file-group Signature progress output so Windows-native SignTool/Catalog work does not appear hung during long checks.
- Distinguishes operator interruption from research failure. A stage that does not return because of Ctrl+C/pipeline stop is recorded as `INTERRUPTED`; downstream selected stages not reached because of the interruption are reported as `NOT_ASSESSED`, and the final result is `Interrupted` with exit code 130.
- Prevents public regeneration from incomplete runs. Publication is attempted only when the current core assessment is `Pass`; interrupted/failed/blocked runs preserve the prior validated `public/**` baseline.
- Corrects summary semantics observed in the Windows 11 2.1.2 qualification: a user-stopped Signature run is no longer presented as `Signature=FAIL`, `StageExecution=REVIEW`, or a successful current-run publication.
- The retained generated repository baseline remains v2.0.0 pending Windows 11 native qualification and subsequent Windows Server 2025 host-scope qualification.

## 2.1.2-signature-dev — 2026-08-14

- Fixed Windows PowerShell 5.1 native-process handling in the Signature stage: expected SignTool negative verification output on stderr is now captured as evidence instead of being promoted to a terminating PowerShell error by the toolkit-wide `ErrorActionPreference=Stop`.
- `Get-AmdByteArraySha256` now accepts the empty byte array, preserving the canonical SHA-256 of empty native-process output (`e3b0c442...b855`) instead of failing parameter binding.
- Strengthened `SignaturePrimitives` self-test with an empty-input SHA-256 known-answer and a native-process negative case that emits stderr and exits non-zero.
- Hardened tracked-stage evidence so a Ctrl+C / pipeline stop cannot leave a not-normally-completed stage recorded as `PASS`.
- Qualification evidence from Windows 11 / Windows PowerShell 5.1 confirmed the 2.1.1 SignedCms initialization fix (`Test=PASS`) and exposed these process-wrapper defects during `Signature`; no AMD/7-Zip prerequisite failure was involved.

## 2.1.1-signature-dev — 2026-08-14

- Fixes Windows PowerShell 5.1 startup compatibility for the new Signature primitive self-test. `System.Security.Cryptography.Pkcs.SignedCms` is now resolved through an explicit runtime initialization path that first uses the already-loaded type and then attempts the supported `System.Security.Cryptography.Pkcs` / .NET Framework `System.Security` assemblies.
- Records the SignedCms runtime/assembly resolution result inside `SignaturePrimitives` environment self-test evidence so a future failure distinguishes a missing runtime type from cryptographic parser failures.
- Uses the same runtime initializer in the recursive CMS parser; an unavailable PKCS runtime produces explicit `RuntimeUnavailable` evidence rather than an opaque constructor exception.
- This is a preview-qualification correction only. The retained generated repository baseline remains v2.0.0; Windows 11 native qualification is still required before publication/baseline promotion.

## 2.1.0-signature-dev — 2026-08-14

- Adds a read-only `Signature` stage after `Inspect` and bumps the per-release analysis contract to `amd-chipset-driver-release-analysis/2.6`.
- Adds host-neutral static signature inventory keyed by SHA-256 while retaining all relative-path occurrences and legacy SHA-1 correlation values. Candidate discovery is content/name based rather than extension-only: PE files are detected by `MZ`, and collision-renamed catalog/CMS/certificate families are recognized so extractor suffixes such as `.sys1`/`.cat1` do not hide distinct payload variants.
- Adds PE `WIN_CERTIFICATE`, CMS/PKCS#7, recursive nested Authenticode, RFC 3161/countersignature, X.509 certificate, and signed/recomputed PE Authenticode digest evidence.
- Treats `.NET SignedCms.CheckSignature()` only as parser/library diagnostic evidence; it is not used as a Windows trust-policy decision.
- Adds runtime execution classification: non-Windows=`Static`; Windows Client=`Static+WindowsNative`; Windows Server/DC=`Static+WindowsNative+TargetServerHost`.
- Adds read-only Windows-native probes for Authenticode, optional SignTool policy verification, native catalog/member/attribute enumeration, and common Windows host security posture. Host/native outputs remain private by default.
- Keeps Target Server PnP install, kernel load, Code Integrity runtime, and device runtime as explicit `NotObserved` fields because this research stage performs no deployment mutation.
- Embeds only host-neutral static signature evidence in canonical per-release public Raw JSON; publication remains fail-closed and Windows-native/host observations do not cross the public boundary automatically.
- Linux/PowerShell 7 development qualification against exact AMD Chipset Software 8.07.16.1035 reproduced 209 unique static signature artifacts (35 kernel binaries, 46 catalogs, 102 libraries, 23 executables, and 3 additional content-detected PE files); all 35 kernel binaries carried embedded signatures in the Linux/static parser result with zero PE signed-digest mismatches in the static parser path. Windows 11 native qualification is required before release/baseline promotion; Windows Server 2025 qualification follows afterward.

## Authored/generated separation — 2026-08-14 (documentation and repository layout only)

The name list in `.gitignore` had drifted: the toolkit writes
`reports/amd-chipset-host-analysis.md`, which the list did not cover, so that
generated report was committable. Directory separation removes the class.

- Separates authored records from script-generated output by directory. The
  authored design/qualification narratives move from `reports/` to a new
  `authored/` directory as a pure rename; no file content changes.
- Replaces the hand-maintained generated-file name list in `.gitignore` with a
  whole-directory rule. `reports/**` is now ignored in its entirety apart from
  its `.gitkeep`, so a newly generated report can no longer become committable
  by being absent from a list.
- Adopts the repository-wide `tools/` layer convention: `authored/**` and
  `public/**` are committed; `inventory/**`, `private/**`, `work/**` and
  `reports/**` are runtime staging carrying one tracked `.gitkeep` each.
- Updates the internal documentation references and the normative statements
  that previously directed new one-off narratives into `reports/**`.
- No PowerShell change, no toolkit version change, and no generated `public/**`
  byte changes.

## v2.0.0 documentation alignment — 2026-08-13 (documentation only)
- Reorganizes the AMD Chipset Driver Research Toolkit documentation without changing `Invoke-AmdChipsetDriverResearch.ps1`, toolkit version, schemas, static data, or generated `public/**` research artifacts.
- Aligns the tool-top Markdown surface with the AMD Graphics Driver Research Toolkit: `README.md`, `SPEC.md`, `TESTING.md`, `RESEARCH-NOTES.md`, `CHANGELOG.md`, `PUBLICATION-POLICY.md`, and `THIRD-PARTY-NOTICES.md`.
- Rewrites README as the stable current entry point, moves normative requirements into SPEC, expands TESTING into the current release/integration gate, and consolidates reverse-engineering plus downstream self-signed-driver engineering knowledge in `RESEARCH-NOTES.md`.
- Moves the former top-level `INF-ANALYSIS-SYNC.md` and `QT-SELECTOR-REVERSE-ENGINEERING.md` narratives to `reports/design-history/` and adds `reports/README.md`; no historical research content is discarded.
- Clarifies that historical reports are evidence/history, while top-level v2.0.0 documents define the current contract.
## 2.0.0 — pre-release aggregate-schema hardening — 2026-08-12

- Reviewed the first 2.0.0 Windows regeneration: research execution itself passed (10/10 stages, 25 releases, 643 INF package records, MSI 25/25 `ParsedReadOnly`, F-01 token corruption 0, public identity/privacy checks healthy).
- Found one release blocker in the generated public surface: `public/inventory/amd-selector-static.json` carried Windows PowerShell 5.1 `{ "value": [...], "Count": n }` serialization wrappers in schema-array fields, producing 131 Draft 2020-12 validation errors.
- Added recursive collection-wrapper canonicalization **only for tool-generated public aggregate indexes**. Canonical per-release Raw JSON remains byte-unchanged.
- Hardened wrapper detection so only an exact `value` + `Count` object with an enumerable `value` and matching count is treated as the PS5.1 collection artifact.
- Added fail-closed aggregate validation: generated aggregate JSON is rejected if a PS5.1 wrapper remains; `amd-selector-static.json` also receives a targeted array-shape check.
- Extended `PublicationContract` self-test with nested wrapper structures and verified `/SETFILTERUSB` remains byte-faithful.
- Declared aggregate collection canonicalization in `publication-manifest.json` `TransformationPolicy`.
- Regression against the first 2.0.0 Windows-generated dataset: 25/25 per-release Raw JSON SHA-256 unchanged; all generated aggregates wrapper-free; selector schema errors 131 -> 0; vendor token counts preserved.
- A new Windows full run with this corrected 2.0.0 source is required; generated files must not be hand-edited.

## 1.3.3-publication-dev — 2026-08-11

Windows full-run validation follow-up and final-publication hardening.

- Reviewed the user-provided 1.3.1 Windows 11 / Windows PowerShell 5.1 full run: 10/10 stages PASS, overall exit 0, 25/25 acquisition and extraction, 643 INF package records, MSI 25/25 `ParsedReadOnly`, zero all-null MSI rows, and `public/**` validation PASS.
- Confirmed the 1.3.1 public dataset contains 25 per-release Raw JSON files, 643 package records with exact CSV key-set equality, zero F-01 `external-path/SET*|info.xml|DevID.xml` regression, zero detected test-host path/ProcessorId leakage, and manifest/source-hash verification with zero mismatches.
- Changed canonical per-release Raw JSON generation to compact JSON **at Build time**. Publication remains a byte-for-byte copy of the canonical runtime file; no post-generation JSON editing or value transformation is introduced. This addresses indentation-only public-tree growth (the 1.3.1 public surface was ~527 MiB uncompressed).
- Changed large runtime-only `driver-packages.json` and `amd-chipset-driver-inventory.json` outputs to compact serialization to reduce disk/string-memory pressure.
- Added `Get-AmdCollectionItems` compatibility handling for the Windows PowerShell 5.1 `{ "value": [...], "Count": n }` wrapper when rehydrating generated public Raw JSON. The Raw JSON itself remains unchanged.
- Reproduced and fixed a fresh-checkout Build failure against real 8.07.16.1035 public Raw JSON; Build now passes with the realistic 31-INF structure. Rebuilt semantic content matches the 1.3.1 source after excluding expected toolkit-version/timestamp metadata.
- Bumped publication manifest to schema `amd-chipset-publication-manifest/1.1` with explicit payload-vs-manifest counts and repository size metrics.
- The final GitHub dataset still requires one fresh Windows full run with 1.3.3 because the script hash and canonical JSON serialization changed.

## 1.3.2-publication-dev — 2026-08-11

Claude revised-script review remediation and publication-contract hardening.

- Kept the F-01 field-scoped portable-path correction unchanged; Claude independently verified 10/10 exact normalization cases.
- Fixed the remaining PSA2001 merge blocker by changing the function-scope read of the script parameter to `$script:SkipPublicExport`.
- Made `Test-AmdPublicationContractSelfTest` independently callable after function-only dot-sourcing by lazily supplying/removing diagnostic script-scope root/version defaults when normal initialization has not run.
- Explicitly documented `external-artifact/<leaf>`, `work/extracted/<release>/...`, extraction-log portability, Markdown LF/no-BOM conversion, and no publication-time report annotation insertion in the generated publication manifest.
- Reverified the two Markdown files named in the withdrawn v2.0.0 F-03 finding are already UTF-8 no-BOM + LF in this development line.
- F-04 remains repository-side: parity/inventory consumers must be repointed when legacy `accepted-baseline` paths are removed.
- A fresh Windows full run remains required before renewed v2.0.0 candidacy; generated JSON must not be hand-edited.

## 1.3.1-publication-dev — 2026-08-11

- Diagnosed the 1.3.0 Windows full-run `ReviewRequired`: only Test failed, because `PublicationContract` did not detect a private Windows path after JSON backslash escaping. All research stages and public publication otherwise completed.
- Changed public JSON privacy validation to parse JSON and inspect decoded scalar strings, fixing the Windows escape blind spot instead of weakening the self-test.
- Added an explicit JSON-escaped `C:\Users\SensitiveUser\...` private-path self-test while preserving safe AMD/MSI evidence values such as `/SETFILTERUSB`, `/info.xml`, and `C:\`.
- Added a publication-time publication-contract gate so a broken contract cannot promote a new `public/**` surface even if Test was omitted or failed earlier.
- Canonicalized repository-relative paths in public indexes/manifests to `/` on all hosts.
- Fixed Windows manifest provenance matching so byte-copied Raw JSON/CSV and normalized Markdown record `SourceRelativePath` and `SourceSha256` instead of losing provenance because of `\` vs `/` matching.
- Independently validated the supplied 1.3.0 Windows public surface: 25 releases, 643 packages, MSI 25/25 `ParsedReadOnly`, zero all-null rows, zero F-01 token corruption, and no detected host-root/ProcessorId leakage.
- A fresh 1.3.1 Windows full run remains required before v2.0.0 candidacy. Generated JSON remains non-editable.


## 1.3.0-publication-dev — reproducible repository publication

- Rebuilt directly from `1.2.11-qt-dev`; the withdrawn v2.0.0 packaging candidate is not a source baseline.
- Fixed Claude F-01 in the generator: portable path conversion is now field-scoped, so `/SETFILTERUSB`, `/SETRYZENPPKG`, `/info.xml`, `/DevID.xml`, and MSI `C:\` values are not corrupted into `external-path/...`.
- Fixed the static-analysis scope issue by explicitly referencing `$script:SkipHostAnalysis` and `$script:ObservedAmdDeviceIdLog` in stage resolution.
- Added `public/**` as the only generated repository-publication allow-list and moved default private evidence to `private/evidence/**`.
- Added `-PublicOutputRoot` and `-SkipPublicExport`.
- Added fail-closed public staging/validation/atomic promotion, previous-public preservation, and partial-run preservation.
- Added canonical public per-release Raw JSON, deterministic release/selector/metadata indexes, repository-safe run summary, publication validation and publication manifest.
- Added source/public SHA-256 provenance and `HandEdited=false` to public manifest entries.
- Added deterministic LF/no-BOM normalization for generated public Markdown and declared the transformation in the manifest.
- Added runtime reconstruction of large `driver-packages.json` from public per-release Raw JSON for fresh-checkout workflows.
- Added portable-normalization and publication-contract self-tests; publication failures now force `ReviewRequired`.
- Added `PUBLICATION-POLICY.md`, `TESTING.md`, public surface README and publication JSON schemas.
- Future v2.0.0 Raw JSON must be regenerated by a corrected Windows full run; hand-edited publication JSON is explicitly prohibited.

## 1.2.11-qt-dev — 2026-08-11

Windows final qualification and MSI evidence-quality hardening.

- Live-qualified 1.2.10 on Windows 11 / Windows PowerShell 5.1: all 10 stages PASS, `OverallStatus=Pass`, and `ExitCode=0`.
- Confirmed final MSI gate closure: 25/25 releases are `ParsedReadOnly`; `ParsedCount=25`; `ParseFailed=0`; `ParsedWithErrors=0`; MSI analysis errors=0.
- Confirmed the 1.2.10 COM row-pipeline isolation fix against real Windows output: 13,993 selected MSI table rows and zero all-null rows.
- Preserved `SelfTestsReady=True`, all six internal self-tests PASS, Japanese `64 ビット -> x86_64` normalization, and the 8.07.16.1035 six-candidate / zero-unknown-filter host result.
- Added per-release MSI `Quality` evidence (`TableCount`, `TotalRowCount`, `AllNullRowCount`, `ErrorCount`).
- Hardened final assessment so all-null MSI rows force `REVIEW` even if a malformed or older analysis claims `Parsed` / `ParsedReadOnly`.
- Extended the MSI assessment self-test with a contaminated-success case that MUST become `REVIEW`.
- No AMD selector predicate, INF semantic, release-identity, or host-selection logic changed.

## 1.2.10-qt-dev — 2026-08-11

Windows Installer COM live confirmation and post-parse robustness hardening.

- Reviewed `AmdChipsetDriverResearchEvidence_20260811-034730_Windows.zip` from Windows 11 build 26200 / Windows PowerShell 5.1 with 7-Zip available.
- Confirmed all 10 stages PASS, overall exit 0, 25/25 acquisitions, 25/25 complete extractions, 643 INF records and zero INF parse failures.
- Live-confirmed the 1.2.9 Windows Installer COM repair: all 25 recovered MSI databases report `ParsedReadOnly`; no `FieldCount`, `ColumnInfo`, `StringData`, or `Fetch` runtime failure remains in selector processing.
- Fixed MSI final assessment so `ParsedReadOnly` is counted as a successful parse instead of producing the misleading `parsed=0` summary. `ParsedWithErrors`, `MsiNotRecovered`, unknown and missing analysis states now surface `REVIEW`.
- Fixed MSI table output contamination by explicitly discarding `View.Execute()` and `View.Close()` return values. The supplied evidence showed exactly two all-null synthetic rows in each of eight selected tables for every release (400 rows total).
- Added `MsiTableRowPipelineIsolationSelfTest` to catch COM/method return-value leakage into row output.
- Made all Test-stage self-tests readiness-gating; a failed self-test now fails Test after diagnostic evidence is persisted.
- Changed the FieldCount-independent self-test end marker so the normal Test transcript no longer contains an intentional caught terminating error.
- Preserved Windows 11 host matching: localized `64 ビット` normalizes to `x86_64`; 8.07.16.1035 still selects six expected candidates with `UnknownAmdFilterCount=0`.

## 1.2.9-qt-dev — 2026-08-11

Windows PowerShell 5.1 MSI COM hardening after the 1.2.8 live rerun.

- Reviewed `AmdChipsetDriverResearchEvidence_20260811-023713_Windows.zip` from Windows 11 build 26200 / Windows PowerShell 5.1 with 7-Zip available.
- Confirmed all 10 stages PASS, overall exit 0, 25/25 artifacts available, 25/25 extraction complete, 643 INF package records, and localized `64 ビット` architecture normalized to `x86_64`.
- Confirmed the 8.07.16.1035 Windows 11 host replay remains healthy: six selected candidates and zero unknown AMD-filter outcomes.
- Found the remaining MSI COM defect: all 25 releases reported `ParseFailed` because `Get-AmdMsiTableRows` accessed `Record.FieldCount`, which was not surfaced by the Windows PowerShell 5.1 COM adapter.
- Removed the `FieldCount` dependency and now discovers `View.ColumnInfo` names by sequential indexed `Record.StringData` reads.
- Added IDispatch/reflection fallbacks for indexed `Record.StringData`, `View.ColumnInfo`, and `View.Fetch` COM access.
- Added `MsiFieldCountIndependentColumnDiscoverySelfTest`, reproducing a usable record with no `FieldCount` property.
- Hardened final assessment with `MsiDeclarativeInspection`: any Windows MSI `ParseFailed` result now produces `ReviewRequired` rather than a silent overall `Pass`.
- Corrected generated host-analysis semantic text so 3.x-8.x exact-binary contracts are represented accurately; compiled hardware predicates remain limited to 7.x/8.x.
- Linux PowerShell 7.6.4 AST/Test qualification passes; live Windows Installer COM confirmation remains the next gate.

## 1.2.8-qt-dev — 2026-08-11

Windows-live qualification and robustness correction after three user-provided evidence runs.

- Reviewed Windows 11 build 26200 / Windows PowerShell 5.1, Windows Server 2025 build 26100 / PowerShell 7.6.3, and Windows Server 2022 build 20348 / Windows PowerShell 5.1 without 7-Zip.
- Fixed localized `OSArchitecture` handling: Japanese `64 ビット` no longer causes false `CompiledArchitectureNotMatched`; HostSurvey now preserves a normalized runtime architecture and selector matching uses the normalized value.
- Added architecture-normalization self-test. Captured Windows 11 replay now selects the expected 8.x six-feature set (SMBUS, PCI, PSP, GPIO2, GPIO3, RYZENPPKG); Server 2022/2025 remain negative through Caption classification.
- Added prerequisite-aware `BLOCKED` stage semantics. A failed Extract now blocks selected Inspect/Selector/Build dependencies rather than allowing PASS over empty/stale inventory.
- Hardened assessment so acquisition/extraction/INF inventories are evaluated only when the corresponding producer stage PASSed in the current run.
- Fixed fragile Windows Installer COM `_Tables` projection by accepting either `.Name` or the sole one-column property; added table-name projection self-test. Real Windows COM end-to-end rerun remains required.
- Updated 2.04.04.111 status from artifact-unavailable to canonical acquisition/static-topology observed: all three Windows runs downloaded the expected 52,428,763-byte ZIP with SHA-256 `d23a9cc4be06ab46c88918e523d11a96ca56b132f3b4646d2e8f9e17abf97185`; two 7-Zip-capable runs extracted 24 INF files.
- Recorded 2.x selector candidate `Qt_Dependancies/Setup.exe` SHA-256 `24cd52cc5a1eff6e082b2408681e4e90d759ef3ddcc8fedd9077fb632cd8bd76`, 26-product Windows 7/10 `Info.xml`, byte-identical APS XML, and no DevID.xml. No 2.x compiled contract is claimed without selector bytes/code-level reverse engineering.
- Added `reports/AMD-Chipset-Driver-Research-1.2.8-WINDOWS-LIVE-VALIDATION.md` and curated `qualification/1.2.8-qt-dev/` evidence/replays.

## 1.2.7-qt-dev — 2026-08-11

Reverse-chronological batch research for **5.x -> 4.x -> 3.x**, after 5.x was confirmed to share the same broad selector generation as frozen 6.x.

- Independently analyzed canonical 5.08.02.027, 4.08.09.2337 and 3.10.08.506 artifacts; all Test/Extract/Inspect/Selector/Build qualifications PASS with zero INF parse failures.
- Confirmed all three use NSIS outer packaging with `Qt_Dependencies/Setup.exe`, x86 Qt5, Client-only Win10/11 `Info.xml`, byte-identical APS XML, and no recovered `DevID.xml`.
- Added exact-release/SHA-256 partial compiled contracts for selector hashes `8f4e0f27...460cf` (5.x), `95d0428e...24160` (4.x), and `4a0cf13c...48ee9` (3.x).
- Proved the same logical Caption classifier for 3.x-6.x: initial/unmatched enum `3`; `Windows 7/10/11` map to `0/1/2`; only mapped Client labels are appended from `Info.xml`.
- Kept 3.x-6.x `/SETFILTERUSB` and `/SETRYZENPPKG` hardware predicates explicitly `Unresolved`; later 7.x/8.x `DEV_...` / `REV_...` predicates are not generalized backward.
- Recorded product growth 27 -> 39 -> 47 -> 53 across 3.x -> 4.x -> 5.x -> 6.x, followed by the previously proven 6.x -> 7.x architecture/Qt/DevID boundary.
- Requalified 6.x/7.x/8.x under 1.2.7; existing compiled predicates remain unchanged.
- Corrected metadata/static-string matching from the accidental doubled-backslash `root\\cimv2` representation to the actual WMI namespace literal `root\cimv2`; this is a metadata/evidence normalization, not a selector predicate change.
- Stopped before 2.x because no canonical 2.04.04.111 archive was available for binary verification; no 2.x topology is inferred.

## 1.2.6-qt-dev — 2026-08-11

Reverse-chronological major selector research: **6.x only**, using frozen 7.x/8.x results as regression references.

- Analyzed canonical `AMD_Chipset_Software_6.10.17.152.exe` (`e5bb2e43218248103a0aa8841b906ae96c7391598de416e51373b255819554bf`).
- Identified `Qt_Dependencies/Setup.exe` as a 1,631,440-byte PE32 x86 Qt5 selector, SHA-256 `83d82a4775c0793ace86b1b07f98eadfc262f22d4c275fab2d74b9d86f19379a`, FileVersion `6.0.0.0`.
- Added an exact-release/hash **partial** compiled contract proving the 6.x OS classifier and Client `Info.xml` filter. Unmatched Caption enum is `3`, not the 7.x/8.x `-1`.
- Fingerprinted 53 Product records, Client-only Win10/11 x64, byte-identical `Info.xml` / APS XML, and no recovered `DevID.xml` (zero declarative device mappings).
- Kept 6.x `SETFILTERUSB` and `SETRYZENPPKG` hardware predicates explicitly `Unresolved`; later `DEV_...` / `REV_...` contracts are not generalized backward.
- Established the 6.x→7.x boundary: Qt5→Qt6, x86→x64, DevID.xml absent→38 mappings, Product 53→62, and six additional SET properties in 7.x.
- 6.x Test/Extract/Inspect/Selector/Build requalification PASS; 7.x/8.x regressions remain PASS.
- Fixed generated `driver-packages.json` `SchemaVersion` to `2.0` so it matches the already-published `driver-package.schema.json` contract discovered by the release-precheck.

## 1.2.5-qt-dev — 2026-08-11

Reverse-chronological major selector research: **7.x only**, using 8.x as the frozen reference.

- Independently reverse-engineered AMD Chipset Software `7.11.26.2142`; canonical outer EXE SHA-256 `1acd6dadcc3b4bca9451ff170d7a5a049309b827f74cf54b2a3684bf16a34856`.
- Identified the 7.x selector owner as `Qt_Dependencies/Setup.exe`, size 1,391,880 bytes, SHA-256 `7b3714b3ff5c6add70987e0aacb0c5b5a2d523ea13ddf39bf0ac02b5f79d2b1a`, PE64 ImageBase `0x140000000`, resource FileVersion/ProductVersion `7.0.0.0`.
- Added an independent exact-release/exact-hash `AmdCompiledStaticProven` contract for 7.x. No rule is inherited merely because the binary is Qt-based.
- Proved the 7.x Caption classifier (`Windows 7/10/11 -> 0/1/2`, otherwise `-1`) and Client `Info.xml` filter (`0/1/2 -> Win7/10/11`, unknown enum -> no product appended).
- Proved 7.x `SETFILTERUSB` handling: same-device `(DEV_790B OR DEV_780B) AND REV_16`; failed candidates are erased silently.
- Proved the modeled 7.x `SETRYZENPPKG` path: `DEV_790B` plus Family 23 / Model 160 special path or revision `REV_61`, `REV_59`, or `REV_51`; surrounding `AMDI0052` logic remains explicitly bounded rather than over-generalized.
- Fingerprinted 7.x XML topology: 62 Product records, 38 DevID mappings, Client-only Windows 10/11 x64, and byte-identical `Info.xml` / `APS_11262025214138_657.xml`.
- Added `reports/amd-chipset-selector-major-version-comparison.md` and machine-readable comparison evidence. 8.x adds three DevID tags (`/SETSFH1.2`, `/SETUPMF`, `/SETXGBE`), two Product identities, and extends `/SETUPEP` and `/SETINTERFACE`.
- Preserved 8.07.16.1035 exact-binary contract and three-host qualification as regression references. 7.x has no live-host fixture, so 8.x dynamic evidence is not copied to 7.x.
- AST, Test self-test, 7.x static pipeline, and 8.x static regression pass under PowerShell 7.6.4 on Debian 13.
- The historical `1.0.0` accepted baseline remains unchanged. **6.x analysis is not started by this release.**


## 1.2.4-qt-dev — 2026-08-11

Qt selector code-level reverse engineering for AMD Chipset Software 8.07.16.1035.

- Added SHA-256-scoped `AmdCompiledStaticProven` selector evidence for the exact recovered `Qt_Dependencies/Setup.exe` (`9b8411b3f77312a770bdac35756081e77c74fb22b7c4c4f367db4f6e5ddf5462`).
- Recovered the WMI OS classifier at `0x140017130`: it reads `Win32_OperatingSystem` `BuildNumber`, `Caption`, and `Version`; the OS-family field is initialized to `-1` and only caption substrings Windows 7/10/11 set enum 0/1/2.
- Recovered the `Info.xml` filter at `0x1400178e0`: the x64 Client branch maps enum 0/1/2 to Windows 7/10/11 XML labels; unknown enum values append no Client product. This gives a compiled explanation for Server 2022/2025 empty XML lists without assuming a direct ProductType check.
- Resolved the former `SETFILTERUSB` implicit-removal mystery: the exact binary locates `/SETFILTERUSB`, requires DEV_790B (or DEV_780B fallback) with `REV_16`, and silently erases the candidate when the prerequisite is not met. The supplied Win11 REV_61 and Server REV_51 fixtures therefore become `ObservedFilterExplainedByCompiledRule`.
- Recovered the `SETRYZENPPKG` candidate-creation gate in the same selector function: after `DEV_790B` matching, CPU Family 23 / Model 160 is a special accepted path; otherwise `REV_61`, `REV_59`, or `REV_51` permits `/SETRYZENPPKG` creation. This explains candidate creation on the supplied Win11 REV_61 and Server REV_51 fixtures while preserving the later XML-list filter as a separate stage.
- Added UTF-16 selector string evidence, compiled-contract self-tests, `REV_..` host-token extraction, and compiled-rule-aware host matching.
- Bumped selector-static schema to 1.2, host-analysis schema to 1.3, and per-release analysis schema to 2.5.
- The code-level contract remains exact-binary scoped; no claim is made that other AMD releases use the same Qt predicates.
- Added `QT-SELECTOR-REVERSE-ENGINEERING.md` documenting the exact-binary Qt selector contract, three-host corroboration, and remaining reverse-engineering boundaries.
- Graphics artifacts remain reference-only in this Chipset session and are not modified by this release.

## 1.2.3-sync-dev — 2026-08-10

Chipset / Graphics INF semantic-contract synchronization.

- Added shared `amd-inf-semantic-contract/1.0` and `amd-inf-identifier-taxonomy/1.0` markers/schema.
- Imported Graphics' quote-aware INF CSV splitter for Manufacturer and Models parsing.
- Added shared Server-profile aliases while retaining the established Chipset canonical profile fields.
- Added `CanonicalStaticAssessment` as the cross-tool machine-readable status alias.
- Keeps WDF scope at the explicitly labeled `InfWideConservative`; DDInstall-scoped WDF is deferred.
- Keeps `CanonicalUnitKind=ReleaseVersion`, while Graphics deliberately uses `ArtifactKey`.
- Updated per-release analysis schema to 2.4 and topology contract metadata to the shared Contract 1.0.
- Source AST and `-Stages Test` pass under PowerShell 7.6.4. The 1.0.0 accepted baseline is not replaced and the 25-release PowerShell 5.1 acceptance has not yet been rerun.


## 1.2.2-dev

- Added Windows Server 2022 / build 20348 as a second independent negative Server fixture for AMD Chipset Software 8.07.16.1035.
- Added release-scoped `AmdDynamicObservedMultiHost` XML-list exclusion semantics for 8.07.16.1035 ProductType 3 hosts; this is explicitly not generalized to other releases and does not claim the exact compiled SKU predicate is proven.
- Qualification now preserves the different Server 2022 and Server 2025 candidate/removal traces rather than accepting a trivial `if Server then []` emulator shortcut.
- Kept `SETFILTERUSB` as `UnknownAmdFilterSuspected`: it is detected and implicitly removed on both Server fixtures without an explicit AMD removal message.
- Extended embedded metadata inspection to discover `APS_*.xml`, parse product records, and SHA-compare them with the preferred outer `Info.xml`.
- Added selector-binary static evidence collection from the recovered Qt `Setup.exe` (XML paths, selector strings, XML traversal symbols, OS/device API names) without executing the binary.
- For the analyzed 8.07.16.1035 artifact, confirmed `APS_7162026103425_2391.xml` is byte-identical to outer `Info.xml`; the XML exposes only Windows 10/11 Client product records.
- Fixed a StrictMode ordering bug in embedded `Info.xml`/`DevID.xml` parsing where the relative source path could be referenced before assignment.
- Bumped embedded metadata schema to 1.1, selector-static schema to 1.1, host-analysis schema to 1.2, and per-release analysis schema to 2.3.

## 1.2.1-dev

- Hardened AMD `Device_ID.log` observation parsing for an explicitly empty final `SupportedDrivers` list; `ObservedEmpty` is now distinct from `NotObserved`.
- Added implicit-removal evidence for `SETxxx` candidates that disappear before the final list without an explicit AMD `Hence removing` event; these remain `UnknownAmdFilterSuspected`.
- Added observed host build/ProductType provenance and fixed non-Windows replay so Windows Server logs are no longer hard-coded as ProductType 1.
- Added MSI observation transaction classification, including `ACTION=ADMIN` -> `AdministrativeExtraction`, and prevented administrative Feature `Request: Local` rows from being treated as install-selection evidence.
- Added `MsiNTProductType`, `AddLocalObserved`, transaction mode, and feature-selection interpretation to MSI observation evidence.
- Added Windows Server 2025 / build 26100 negative selector fixture semantics: AMD hardware detection can succeed while the final supported-driver list is explicitly empty after AMD-specific filtering.
- Fixed empty-set host/MSI consistency comparison so a zero-component Server observation no longer fails `HostMatch` through PowerShell `Compare-Object` null binding.
- Updated selector/MSI/host-analysis schemas to 1.1 while preserving the 1.0.0 accepted repository baseline as historical provenance.

## 1.2.0-dev

- Added release-static AMD selector analysis from `DevID.xml` / `Info.xml` and read-only Windows Installer MSI tables.
- Added `Selector`, `HostSurvey`, and `HostMatch` stages while keeping the implementation in the single PowerShell script.
- Added read-only live Windows PnP/CPU/OS inventory; no AMD EXE execution, driver staging, INF install, or registry modification.
- Added optional replay of real `Device_ID.log` and MSI verbose logs for selector qualification without executing AMD software.
- Added release binding for observed logs so one captured AMD result is never compared to unrelated historical releases.
- Added actual-host INF Models/TargetOSVersion matching and host-specific report/JSON outputs.
- Indexed host Hardware/Compatible IDs for matching so HostMatch does not perform a full device scan for every INF model row.
- Added AMD selector decision/evidence vocabulary including `EmulationConfirmed`, explicit observed filters, static-inference filters, and unresolved mismatches.
- Qualified 8.07.16.1035 using the supplied Windows 11 AMD logs: six final features reproduced (`GPIO3,PCI,PSP,SMBUS,GPIO2,RYZENPPKG`) and MSI `ADDLOCAL` consistency confirmed.
- Kept `SETRYZENPPKG` as a release/single-host empirical rule until its exact declarative predicate is recovered.
- Identified the Windows-10-only embedded USB Filter record as a static explanation candidate for the observed absence of `SETFILTERUSB` on the Windows-11 qualification host.
- Added host-OS filtering of embedded component candidates and tightened `SETGPIO2` product correlation to avoid conflating it with Promontory GPIO.
- Existing 1.0.0 accepted baseline remains unchanged; 1.2.0-dev requires Windows PowerShell 5.1 live-host qualification before GA/baseline promotion.

## 1.1.1-dev

- Grouped `amd-chipset-windows-server-compatibility.md` by release and sorted releases newest first.
- Changed compatibility tables from one row per Server profile to one row per device with WS2016/2019/2022/2025 columns.
- Added semantic identifier classification for bus PnP, root-enumerated, device-class-specific, generic, and network software component identifiers.
- Added `Identifier` and `CompatibleIdentifiers` to INF topology Raw JSON while retaining the original `HardwareId`/`CompatibleIds` fields.
- Added `IdentifierKind` / `IdentifierType` to compatibility CSV output and sorted CSV releases newest first.
- Bumped per-release analysis schema to 2.1 and INF topology schema to 1.1.

## 1.1.0 — development (2026-08-10)

INF semantic-analysis feature line.

- Preserves `[Manufacturer]`, TargetOSVersion decorations, reachable Models sections, device descriptions, DDInstall sections, HWIDs and compatible IDs as canonical topology.
- Simulates Microsoft INF Models selection for Windows Server 2016/2019/2022/2025.
- Keeps AMD-published applicability separate from an analytical ProductType=1 -> ProductType=3 Server projection.
- Adds conservative host WDF cross-checking with documented/observed references kept distinct.
- Adds one Raw JSON analysis file per AMD installer version plus per-release device/Server Markdown reports and cross-release CSV/Markdown matrices.
- Incorporates the Graphics-side hardening lesson that Models parsing must follow Manufacturer references rather than wildcard section prefixes.
- Initial Linux regression: real AMD installers 3.10.08.506, 4.08.09.2337, 5.08.02.027, 6.10.17.152, 7.11.26.2142 and 8.07.16.1035; 157 INF files, zero parse failures.
- The repository-committed accepted baseline remains the 1.0.0-era dataset until a new 25-release Windows PowerShell 5.1 acceptance run is performed.

## 1.0.0 — 2026-08-09

First GitHub commit candidate / GA research-tool baseline.

- Promotes the fully accepted v0.4.3 implementation to semantic version `1.0.0`.
- Keeps the single-PowerShell-script project policy.
- Supports Windows PowerShell 5.1 and PowerShell 7.x on Windows/Linux.
- Defaults to the complete Test → Discover → Metadata → Acquire → Extract → Inspect → Build workflow.
- Supports AMD historical ZIP wrappers, NSIS outer containers, InstallShield `ISSetupStream` type 3/4 recovery, MSI/CAB expansion, INF inspection, and KMDF/UMDF directive capture.
- Produces stage timing/progress logs and review-oriented Evidence ZIPs.
- Adds a repository-committed accepted baseline for 25 releases from 2.04.04.111 through 8.07.16.1035.
- The accepted Windows PowerShell 5.1 run completed all seven stages with `Pass / exit 0`, 25/25 acquisitions, 25/25 `ExtractionComplete`, 643 INF records, 158 KMDF declarations, 25 UMDF declarations, and zero INF parse failures.

### Provenance note

The accepted dataset was generated by pre-GA v0.4.3. Version 1.0.0 changes the toolkit version metadata and repository documentation/data packaging, not the accepted extraction or INF-analysis behavior. The checked-in dataset intentionally retains its original `ToolkitVersion` value.
## Rev48 common evidence-storage correction — 2026-08-19

- Unified Chipset, NPU, and Graphics final evidence under `private\evidence`.
- Added clear `EVIDENCE ZIP TO SHARE` output, SHA-256 companion files, and `LATEST-EVIDENCE.txt`.
- Added short raw run directories and `ZipOnly` / `ZipAndDirectory` retention.
- Blocked evidence destinations outside the canonical tool-local tree, including UNC, SUBST, and reparse-point routes.
- Removed the NPU TEMP emergency-evidence fallback.
- Corrected the Graphics empty-argument SUBST probe and made diagnostic failure fail-closed.
