# Changelog

All notable changes to the four PowerShell scripts in the
**Deploy-Drivers-For-WindowsServer** repository are documented in this file.
This document is the canonical, authoritative log of revision-by-revision
changes; per-script PowerShell files no longer carry inline revision history.

The format is based on [Keep a Changelog 1.1.0](https://keepachangelog.com/en/1.1.0/).
This project does not follow strict [Semantic Versioning](https://semver.org/spec/v2.0.0.html)
because each script is bumped on its own revision counter (`rNN`); release
entries below are tagged `Chipset rNN / Graphics rNN / NPU rNN / BthPan rNN`.
Scripts may be bumped together (cross-script consistency releases) or
independently.

> **For design rationale behind individual fixes** (e.g., *why* the workspace
> lock uses `try/finally` + self-PID detection, *why* `inf2cat` is x86-only,
> *why* `[Console]::OutputEncoding` must be forced to UTF-8 in P00):
> see [`SPEC.md`](./SPEC.md) **Part D — Known Pitfalls & Lessons Learned**.
> This `CHANGELOG.md` captures *when* and *what*; SPEC Part D captures *why*.

---

## [2026-05-24] `legacy-ws2019-runtime-correctness-fix` — Chipset r74 / Graphics r40 / BthPan r22 / NPU r18 (unchanged)

This release closes four runtime defects surfaced during a clean-installed
Windows Server 2019 + AMD Ryzen 5 PRO 4650U (Renoir) bench cycle on
2026-05-24. The defects had been latent since r71 and were not caught by
any `psa.py` v3.8.0 rule because they are integration defects, not local-
form defects. Full post-incident analysis lives in
[SPEC §D.32](./SPEC.md#d32-runtime-correctness-fixes-from-the-2026-05-24-ws2019--renoir-bench-cycle-r74);
test scenarios live in [TESTING §16](./TESTING.md#16-r74--r40--r22-release-validation-2026-05-24-renoir--ws2019).

### Fixed

- **Defect 1 — `Test-WhqlCoSignature` called a non-existent `Find-Signtool` helper.** The actual Windows Kits resolver is `Find-KitTool 'signtool.exe'`. The mistyped call silently raised `CommandNotFoundException` inside a `try/catch`, forcing every WHQL classification into the conservative `'self-only'` fallback for the entire r71–r73 lifetime. The C6 acknowledgement gate, `-SkipNonCosignedDrivers` trim, and r72 I02 short-circuit all silently degraded as a result. (Chipset r74 / Graphics r40 / BthPan r22 — byte-identical helper fix.)
- **Defect 2 — `signtool verify /pa /v` did not emit nested signatures.** The `/all` flag was missing. AMD's kernel drivers historically embed WHQL co-signatures as nested signatures, so the missing flag hid exactly the data this function was looking for. Now invokes `signtool verify /all /pa /v`. (Chipset r74 / Graphics r40 / BthPan r22 — byte-identical helper fix.)
- **Defect 3 — V06 misclassified script-installed drivers as `[B]` instead of `[C]`.** V06 omitted the `-KnownOurInfSet` argument to `Get-DriverSourceCategory`, which forced classification to rely on Step 0a (`.cat` thumbprint match) alone. Step 0a fails on certain WS2019 catalog-merging paths; the I04 helper `Get-OurSignedOemInfSet` was already designed to handle the gap but V06 never invoked it. Now builds `$ourInfSet` once at V06 entry and threads it into Section 1 and Section 2. (Chipset r74 / Graphics r40 — BthPan V06 does not call Get-DriverSourceCategory.)
- **Defect 4 — I02 → I03 ran in the same execution despite "reboot then re-run" message.** When I02 newly enables BCD testsigning, the kernel CI cannot admit self-signed drivers until the reboot, so I03 would stage drivers that immediately fail to load. Now I02 sets a per-process `$Ctx.RebootRequiredBeforeI03 = $true` flag; I03 and I04 check the flag at entry and halt with a clear "reboot and re-run" message. (Chipset r74 / Graphics r40 / BthPan r22.)

### Changed

- **All three bumped scripts** now ship `$Script:ScriptTag = 'legacy-ws2019-runtime-correctness-fix'` (was `'legacy-ws2019-wdac-spf-integration'`).
- **`Deploy-AMDChipsetDriverOnWindowsServer.ps1` → `chipset-2026.05.24-r74`** (from `chipset-2026.05.23-r73`).
- **`Deploy-AMDGraphicsDriverOnWindowsServer.ps1` → `graphics-2026.05.24-r40`** (from `graphics-2026.05.23-r39`).
- **`Deploy-MSBthPanInboxOnWindowsServer.ps1` → `msbthpan-2026.05.24-r22`** (from `msbthpan-2026.05.23-r21`).
- **`Deploy-AMDNpuDriverOnWindowsServer.ps1`**: NOT bumped (per SPEC §A.7 "no empty revisions"). NPU does not exercise `Test-WhqlCoSignature`, `Get-DriverSourceCategory`, or the `RebootRequiredBeforeI03` flag — every r74 defect is structurally inapplicable to NPU.

### Documentation

- **`SPEC.md` §D.30.2**: Added an `r74 amendment (2026-05-24)` note on row F4 clarifying that the original WHQL co-signature observation was specific to chipset 8.04.x; the 8.05.04.516 build dropped WHQL co-signatures from AmdMicroPEP.sys and every other chipset `.sys`. WHQL status must be re-verified per package release.
- **`SPEC.md` §D.31.10**: Added the r74 / r40 / r22 release contract row.
- **`SPEC.md` §D.32** (new section): Post-incident analysis covering all four r74 defects, the empirical signtool-verify output table from the 2026-05-24 bench, the r74 release version contract, and a forward reference to PSA2010 (planned, `psa.py` v3.9.0).
- **`TESTING.md` §16** (new section): TC16.1–TC16.6 covering positive / negative WHQL classification, V06 [C]-classification correctness, idempotency on re-run, I02→I03 halt semantics, and re-run-after-reboot semantics.
- **`README.md` / `README.ja.md`**: Version references updated; "What's in the box" maturity table updated; SPEC §D.32 cross-reference added in the troubleshooting section.

### Known limitations

- **`Test-WhqlCoSignature` on signtool-absent hosts** continues to return conservative `'self-only'` for any `.sys` whose primary signer is not WHQL. This is intentional — over-reporting is preferred to under-reporting. Operators who want the strict WHQL classification on a WDK-less host should install the Windows 10/11 SDK (the script's P02 phase handles this for the Install action; PrepareVerify-only runs can fall back to the conservative verdict without issue).
- **No static-analysis gate yet catches Defect 1.** Until `psa.py` v3.9.0 introduces the PSA2010 rule (invocation of undefined function), a manual `grep -E '\bFind-[A-Z][a-zA-Z]+' *.ps1` cross-check against `grep -E '^function Find-[A-Z]'` is the recommended pre-commit guard.

---

## [Unreleased]

### Changed

- **`.psa.config.json`**: Added `Build-PatchedInfHwidIndex` to
  `psa8001_ignore_functions` to codify the intentional, SPEC §D.24-
  documented divergence between the Chipset and Graphics variants of
  this function. The Chipset variant integrates a phantom-file-
  reference filter (Chipset r65) that calls the Chipset-only helpers
  `Get-IneligibleInfLookup` / `Test-InfIsIneligible`; the Graphics
  variant omits the filter because Adrenalin packaging does not
  exhibit the SECREPAIR Error: 3 cascade and Graphics P05 has been
  validated to produce 0 ineligible INFs in practice (Adrenalin
  26.5.2 Vega-Polaris Legacy on Renoir / WS2019). Per SPEC §D.24 the
  port of the r65 phantom-file machinery to Graphics is deferred
  until the same defect is observed in a real Adrenalin package.
  This change removes the pre-existing PSA8001 cross-file drift
  warning.
- **`SPEC.md` §A.11.5b**: Added a "Documented per-driver-family
  exceptions to byte-identity" paragraph cross-referencing §D.24 and
  explaining the rationale for the `Build-PatchedInfHwidIndex`
  exception in `psa8001_ignore_functions`.
- **`Deploy-AMDChipsetDriverOnWindowsServer.ps1`**: Renamed the
  private helper function `Get-InfReferencedFiles` → `Get-InfReferencedFile`
  to comply with the PowerShell singular-noun naming convention
  (PSA6003: function-noun plural form). The function is Chipset-only
  (single call site at the SECREPAIR Error: 3 detection P05 phase,
  see SPEC §D.24) and carries no module-export surface; the rename
  is a pure internal refactoring with no behavioural change. The
  Chipset script's own canonical SHA256 changes as a result, but no
  other file embeds that value (driver scripts only embed the
  orchestrator's canonical SHA256), so no cascade update is needed.
- **Documentation forward-references updated**: `README.md`,
  `README.ja.md`, and `SPEC.md` §D.24 each had one or two backticked
  references to `Get-InfReferencedFiles` that are now updated to
  `Get-InfReferencedFile`. Historical CHANGELOG entries for r65
  (which describe what the function was named at release time) are
  preserved verbatim per Keep a Changelog 1.1.0 conventions.

CI baseline after these changes: **all five scripts report 0
errors / 0 warnings / 0 info** under `psa.py --config
.psa.config.json` — the first revision since project inception
where the entire codebase is fully clean across the canonical
analyzer baseline. The orchestrator canonical SHA256
(`f779bf50c41201a6564bf968d040cf39348433951cb83accd856245bebef7ced`,
i.e. the post-r04 value)
and all `$Script:ExpectedWdacScriptCanonicalSha256` embedded
constants in the four driver scripts remain unchanged (the rename
only affects the Chipset script's own canonical hash, which is not
embedded anywhere).

## [Chipset r73 / Graphics r39 / NPU r18 / BthPan r21] — 2026-05-23 — `$Ctx.WhqlCoSignAnalysis` pre-declaration fix + Graphics P05 WHQL producer port + `psa.py` PSA2009

### Fixed

- **Chipset r73 / BthPan r21 — P05 hard failure: `WhqlCoSignAnalysis` property not declared on `$Ctx`**. The `[pscustomobject]@{...}` initialiser added to both scripts in the r71 release did not pre-declare the new `WhqlCoSignAnalysis` field, but the P05 phase body unconditionally executed `$Ctx.WhqlCoSignAnalysis = New-WhqlCoSignAnalysis -InfRecords $whqlInfRecords` on its happy path AND `$Ctx.WhqlCoSignAnalysis = @()` in its `catch` fallback. Under PowerShell 5.1 `[pscustomobject]` semantics, a `.` -style assignment to a property that was not present in the initialiser raises `「<PropName>」 の設定中に例外が発生しました: 「このオブジェクトにプロパティ '<PropName>' が見つかりません。」` (English: `Exception setting "<PropName>": "The property '<PropName>' cannot be found on this object. Verify that the property exists and can be set."`). Because the same defective assignment exists on both the happy path and inside the `catch` block, the `catch` re-raises and P05 transitions to `FAILED`, aborting the entire `PrepareVerify` action. Repro recipe: clean-installed Windows Server 2019 ja-JP, run `Deploy-AMDChipsetDriverOnWindowsServer.ps1 -Action PrepareVerify -CleanWorkRoot`, observe `PHASE P05 -> FAILED` with the localised property-not-found exception at line `$Ctx.WhqlCoSignAnalysis = @()` inside the `catch` block (line 8470 in the r72 source). The fix is a one-line addition (`WhqlCoSignAnalysis = $null`) to the `[pscustomobject]@{...}` `$Ctx` initialiser, accompanied by an explanatory comment block cross-referencing SPEC SS D.31 and the new psa.py PSA2009 rule. No behavioural change to the WHQL analysis itself, the I00 C6 condition, the P06 `-SkipNonCosignedDrivers` trim, or the r72 I02 short-circuit — those subsystems were all *waiting* for `$Ctx.WhqlCoSignAnalysis` to be populated, and the r71 producer site (P05) simply never reached the populating assignment because the property didn't exist.
- **Graphics r39 — P05 silently missing the entire WHQL co-sign analysis producer block (regression scope: undiscovered r71→r38 functional gap)**. Graphics r37 / r38 shipped the `New-WhqlCoSignAnalysis` / `Show-WhqlCoSignAnalysisReport` / `Get-EligibleInfRecordList` helper functions AND the four CONSUMER sites (I00 §C6 condition, P06 `-SkipNonCosignedDrivers` trim, I02 r72 short-circuit, recap line in I00) but never the PRODUCER site in P05. The Graphics P05 phase body ended at `Set-PhaseMarker` without ever calling `New-WhqlCoSignAnalysis -InfRecords ...` or assigning a value to `$Ctx.WhqlCoSignAnalysis`. The downstream symptom on a Graphics-driven host was that I00 §C6 never fired (even on a Secure-Boot-ON host with non-WHQL-co-signed Adrenalin drivers), `-SkipNonCosignedDrivers` had no effect (because the trim filter saw an empty `$Ctx.WhqlCoSignAnalysis`), and the r72 I02 short-circuit was unreachable (its precondition was always false). The defect was structural rather than data-driven: there was no error message at all on the Graphics happy path — the WHQL summary banner simply never appeared between the inventory CSV/TXT writes and the phase footer. The fix ports the producer block from Chipset r71/r72 byte-identically (modulo the `r71`/`r72` revision-tag comments rephrased to `r39` to reflect the Graphics-side release that introduced the integration); the producer block is now adjacent to the existing `Set-PhaseMarker` call in P05. The function-body hash for `Invoke-PrepPhase05_AnalyzeInfs` consequently diverges between Chipset and Graphics by the size of the variant-aware inventory build that already differed between the two (display-only "Host OS / profile" branch in Graphics), which `psa8001_ignore_functions` already exempts.
- **`psa.py` v3.8.0 — new rule `PSA2009` (PSCustomObject property assigned without prior declaration)**. The two bugs above were not detectable under `psa.py` v3.7.0 (or any prior release): existing rules check brace balance, undefined variable references, auto-variable shadowing, etc., but none model the PSv5 `[pscustomobject]@{...}` sealed-object semantic. The new rule walks every `$VarName = [pscustomobject]@{...}` initialiser in the file, collects the declared property set (including properties added later via `Add-Member -MemberType NoteProperty -Name`), and then flags every `$VarName.Property = ...` assignment whose target was not in the declared set. Variables that are *also* assigned with a plain hashtable literal (`@{...}` / `[hashtable]@{...}` / `[ordered]@{...}`) anywhere in the same file are conservatively dropped from tracking (false-positive prevention; affects NPU's `$result` accumulator pattern). The rule is on by default at `warning` severity. Inline suppression via `# psa-disable-line PSA2009` works on the assignment line, not the initialiser. The canonical artifact at `https://github.com/usui-tk/ai-generated-artifacts/tree/main/scripts/python/powershell-static-analyzer/psa.py` is bumped from v3.7.0 to v3.8.0 along with its sibling `VERSION` file; consumers of this repository SHOULD re-fetch both files per the SPEC §A.11 versioning policy. Running `psa.py --include PSA2009` against this repository's four PowerShell scripts at the r72/r38/r18/r20 baseline reproduces the two bugs above exactly (two warnings on Chipset, two on BthPan, zero on NPU); after the r73/r39/_/r21 fix above all four scripts report zero PSA2009 findings.

### Added

- **`Deploy-AMDGraphicsDriverOnWindowsServer.ps1` P05 — WHQL co-signature analysis producer block** (~17 lines, ported from Chipset r71 with the producer revision-tag comments updated to `r39`). Runs immediately after the inventory CSV / report TXT are written and before `Set-PhaseMarker -PhaseId 'P05'`. Builds the `[pscustomobject]@{ InfName; InfPath }` record list from the patch-eligible subset (i.e., `$detailReport | Where-Object NeedsPatch`), invokes `New-WhqlCoSignAnalysis`, assigns the result to `$Ctx.WhqlCoSignAnalysis`, and calls `Show-WhqlCoSignAnalysisReport` to emit the operator-facing summary banner ("Fully WHQL co-signed INFs / Mixed-signing INFs / No WHQL co-signature"). On exception the block falls back to `$Ctx.WhqlCoSignAnalysis = @()` with a warning so downstream C6 / `-SkipNonCosignedDrivers` / I02 short-circuit consumers see the same "empty analysis" sentinel they would see on a signtool-absent host (best-effort contract per SPEC §D.31.3).
- **`Deploy-AMDChipsetDriverOnWindowsServer.ps1`, `Deploy-AMDGraphicsDriverOnWindowsServer.ps1`, `Deploy-MSBthPanInboxOnWindowsServer.ps1` — `$Ctx.WhqlCoSignAnalysis = $null` initialiser line + multi-line explanatory comment**. The comment cross-references SPEC SS D.31, names the producer (P05) and consumer (I00 / P06 / I02) sites, and explicitly calls out the PSA2009 rule that would have caught the omission at static-analysis time. The wording is consistent across the three scripts; NPU is unaffected because the NPU pipeline uses per-INF `Read-InfManufacturer` parsing rather than the multi-INF `New-WhqlCoSignAnalysis` analysis (the NPU package always installs a single inbox-style INF and the WHQL classification is implicit).

### Changed

- **`psa.py` v3.7.0 → v3.8.0** (canonical artifact at `usui-tk/ai-generated-artifacts`). Rule catalog grows from 36 to 37 rules. The new PSA2009 rule is `warning` severity, on by default, and detects the two bugs fixed in this release with 0 false positives across the four PowerShell scripts in this repository. The `VERSION` file is updated in lock-step per the SPEC §A.11 dual-file release contract.
- **`SPEC.md` §A.11 (Static Analysis with psa.py)**: rule catalog table updated to include PSA2009 (warning, on by default). Added a §A.11.5c subsection ("PSA2009 — PSCustomObject sealed-object semantic checks") explaining when the rule fires, how it differs from PSA2001 ("undefined variable reference") which operates at the variable level rather than the property level, and how `Add-Member` and hashtable-form re-initialisation interact with the rule.
- **`SPEC.md` §D.31 (WHQL co-signature analysis pipeline)**: D.31.2 ("P05 producer site") now explicitly enumerates all four scripts as required hosts of the producer block; the table at the end of D.31 ("Phase-by-phase WHQL analysis touchpoints") is corrected to mark Graphics P05 as "producer (r39)" rather than the previous "(unimplemented; r39 backport pending)" placeholder. D.31 gains a new subsection D.31.16 ("`$Ctx` initialiser checklist for r71 producer rollout") that captures the lesson learned and the PSA2009 cross-reference.
- **`TESTING.md`**: Added test case TC14.12 ("`$Ctx.WhqlCoSignAnalysis` property-declaration smoke test (PSA2009 static-analysis gate)") under "Static analysis acceptance tests". TC14.12 runs `python3 ../ai-generated-artifacts/scripts/python/powershell-static-analyzer/psa.py --include PSA2009` against each of the four scripts and asserts 0 findings; it also documents the r72/r38/r18/r20 regression-replay procedure that reproduces 2 warnings on Chipset, 2 on BthPan, 0 on Graphics/NPU. TC14.13 ("Graphics P05 emits the WHQL co-signature analysis summary banner — r39 producer-site smoke test") is added immediately after TC14.12 to verify the Graphics P05 banner is now present (closing the producer-side gap described in §D.31.16.5).
- **`README.md` / `README.ja.md` — psa.py version reference**: the example invocation in §"Static analysis" now references `psa.py 3.8.0` (the version that introduces PSA2009 and validates this release).

### Notes

- **Why r73 / r39 / r21 and not r73 / r39 / r19 / r21**: the NPU script (r18) is unchanged in this release. The NPU pipeline does not exercise `$Ctx.WhqlCoSignAnalysis` — its WHQL surface is the single Microsoft inbox-style INF that ships with the AMD NPU package, and the inbox-INF case is handled implicitly by I02's existing Path-A trust-store import rather than by the multi-INF `New-WhqlCoSignAnalysis` analysis. Bumping NPU to r19 would be a no-op revision and is therefore skipped per the SPEC §A.7 ("revision-counter discipline") policy of "no empty revisions".
- **PowerShell 5.1 sealed-object semantics — the broader lesson**: `[pscustomobject]@{...}` produces an object whose property surface is fixed at construction time. Any subsequent `$obj.NewProp = value` assignment that targets a property NOT in the initialiser raises a terminating exception. This is *unlike* hashtables (`@{...}` / `[hashtable]@{...}` / `[ordered]@{...}`) which freely accept new keys at runtime, and unlike `New-Object PSObject` constructions which can be extended via `Add-Member`. The pattern used across all four scripts is the strictest form (`[pscustomobject]@{...}`) intentionally — it surfaces "you added a feature but forgot to wire it into the context object" defects early — but the defect surfaces as a runtime exception during the phase that first attempts the assignment, not at parse time or at script load. PSA2009 is the static-analysis gate that closes this loop: the analyzer now catches the defect at authoring time, before the script is ever executed. See SPEC §D.31.16 for the broader rollout checklist applicable to any future `$Ctx.<NewField> = ...` integration.

## [Chipset r72 / Graphics r38 / NPU r18 / BthPan r20] — 2026-05-23 — I02 short-circuit for all-WHQL trimmed install plans

### Added

- **I02 short-circuit logic in Chipset / Graphics / BthPan** (~25 lines per script, byte-identical between Chipset and Graphics; BthPan inherits the pre-existing `Test-MsBthPanWdacPolicyDeployed` naming divergence from r71). The block runs immediately after the `Test-InstallPhaseAlreadyDone -PhaseId 'I02'` cache-check and before the AS-IS state capture. When the four-clause predicate `-not $Ctx.UseTestSigning` AND `$Script:SkipNonCosignedDrivers` AND `$Ctx.WhqlCoSignAnalysis` populated AND `$nonCoSignedAfterTrim.Count -eq 0` all hold, I02 emits a green "I02 short-circuit (r72): install plan is fully WHQL co-signed" banner and returns without deploying any WDAC supplemental policy or setting any `bcdedit` testsigning flag.
- **Phase-marker `Metadata` extension**: when the short-circuit fires, `Set-PhaseMarker -PhaseId 'I02'` is invoked with `-Metadata @{ ShortCircuit=$true; Reason='all-whql-skip'; AnalysedInfCount=<N> }`. The metadata is informational only and does not participate in resume-after-reboot decisions (see SPEC §D.31.11.4).
- **New `Write-PhaseFooter` completion label**: `'short-circuit'` joins the existing `'done'` and `'cached'` labels for I02.
- **`Set-DebugStep` audit anchors**: new debug-step strings `r72 short-circuit evaluation` and `I02 short-circuit: SkipNonCosignedDrivers={0} UseTestSigning={1} AnalysedInfCount={2} NonCoSignedAfterTrim={3}` appear in run transcripts when the short-circuit fires.
- **SPEC.md §D.31.11** (eight subsections D.31.11.1 – D.31.11.8) documenting the short-circuit's motivation, firing conditions, observable host effects, resume-after-reboot semantics, interaction with the other r71 mechanisms (P05 / Path B prereq / C6 / `-SkipNonCosignedDrivers` trim / `-Force` / NPU), OS-version uniformity rationale, what r72 does NOT change, and implementation notes.
- **TESTING.md §14 TC14.9, TC14.10, TC14.11**: positive fire on WS2019 + Secure Boot ON + all-WHQL trimmed plan; OS-version-agnostic fire on WS2022+; resume-after-reboot semantics verifying the short-circuit marker does NOT trap subsequent runs that drop `-SkipNonCosignedDrivers`.
- **`SECTION r71` header forward-reference** in Chipset / Graphics / BthPan: the closing line now reads "See SPEC §D.31 for the full r71 design contract; SPEC §D.31.11 documents the r72 follow-on I02 short-circuit that consumes the WHQL analysis produced here when `-SkipNonCosignedDrivers` is set."

### Changed

- **SPEC.md §D.31.9 TC14.3** description updated from "deferred follow-on refinement" to "implemented in r72" with a parenthetical noting the pre-r72 ABORT behaviour for historical context.
- **SPEC.md §D.31.10** extended to record the r72 version-bump targets and the byte-identity convention for the new short-circuit block.
- **TESTING.md §14 title and Scope** updated to include the r72 mechanism (the section is now titled "r71 WHQL co-sign pre-detection + Path B prerequisite check + C6 + `-SkipNonCosignedDrivers` + r72 I02 short-circuit").
- **TESTING.md §14 TC14.3** rewritten to describe the r72 short-circuit fire as the expected outcome of the canonical `-Action Install -SkipNonCosignedDrivers` invocation on WS2019 + Secure Boot ON (replacing the previous "Path A fallback" wording which described an unreachable code path).
- **TESTING.md §14 "Negative test — TC14.3 follow-on"** rewritten as a historical note pointing at the r72 closing of the gap.
- **README.md / README.ja.md** updated to reflect that `-SkipNonCosignedDrivers` now produces an end-to-end successful install on legacy Server + Secure Boot ON, with no firmware change required.
- **`$Script:ScriptVersion` bumped** across all four scripts:
  - Chipset: `chipset-2026.05.23-r69` → `chipset-2026.05.23-r72`
  - Graphics: `graphics-2026.05.23-r35` → `graphics-2026.05.23-r38`
  - NPU: `npu-2026.05.23-r17` → `npu-2026.05.23-r18`
  - BthPan: `msbthpan-2026.05.23-r17` → `msbthpan-2026.05.23-r20`

  Note: the multi-step bumps in Chipset / Graphics / BthPan catch up version strings that were not actually bumped during the r70 Path C deprecation or the r71 WHQL pre-detection releases. The SPEC §D.31.10 release contract has documented these target values since r71, so r72 is the first release whose actual `$Script:ScriptVersion` strings reflect SPEC's claim. The NPU single-step bump (r17 → r18) is the SPEC-documented release-tag synchronisation; NPU has no r70 / r71 / r72 functional code changes.

### Rationale

Pre-r72, the natural `-SkipNonCosignedDrivers + Secure Boot ON` workflow on legacy Server failed at I02 — the script gave the operator a flag to opt into WHQL-only installs, then refused to complete the install on a Secure-Boot-ON host because I02 fell into Path B (no CiTool on legacy Server) and the r71 Path B prerequisite check correctly ABORTed on Secure Boot ON. r72 closes that gap.

The short-circuit is technically sound:

- WHQL co-signed drivers carry embedded Microsoft Windows Hardware Compatibility signatures that kernel CI accepts on Secure Boot ON without any custom WDAC policy or testsigning. F5 of the 2026-05-23 bench observations confirms this empirically on WS2019 + Renoir.
- The script's self-signing certificate in `LocalMachine\Root + LocalMachine\TrustedPublisher` (installed by I01) is sufficient for `pnputil /add-driver` to accept the script-re-signed catalogs at I03.
- I02's normal job — authorising the self-signing cert as a kernel-mode signer via either Path A (WDAC supplemental policy) or Path B (testsigning) — is purely unnecessary for an all-WHQL install plan because the kernel-CI path for WHQL drivers uses the embedded signature, not the catalog signature.

Opt-in via `-SkipNonCosignedDrivers` (rather than auto-detecting an all-WHQL plan on a flag-less run) preserves predictability: admins inspecting their host with `Get-CIPolicy -Online` for the script-deployed WDAC policy file will still find it on flag-less runs.

OS-version uniformity (the short-circuit fires on any supported host when the conditions hold, not only on WS2019 / WS2016) keeps the behavioural contract uniform across the script family. Operators who want the WDAC supplemental policy file deployed on WS2022+ as documentation can simply not pass `-SkipNonCosignedDrivers`.

### Migration

- **No new switches.** `-SkipNonCosignedDrivers` continues to work as in r71; the only difference is that I02 no longer ABORTs at the Path B prerequisite check on Secure Boot ON when the flag is set and the install plan is fully WHQL co-signed.
- **Existing automation** that ran `-SkipNonCosignedDrivers` + Secure Boot ON on WS2019 against r71 (and hit the ABORT) will now complete successfully against r72. No automation changes are required.
- **Hosts that ran r71** with `-SkipNonCosignedDrivers` and have the I01 trust-store cert already imported can safely re-run r72 with the same flags; the short-circuit will fire and I03 will install the WHQL subset.
- **Phase-marker `Metadata` format extension** (`ShortCircuit` / `Reason` / `AnalysedInfCount`) is additive — no existing marker-reading code paths inspect these fields, so backward compatibility is preserved.
- **Resume-after-reboot semantics** are documented in §D.31.11.4 and verified by TC14.11: a short-circuited I02 does NOT trap subsequent runs that drop `-SkipNonCosignedDrivers`. The marker's `ShortCircuit=$true` metadata is informational only; `Test-InstallPhaseAlreadyDone` inspects HOST STATE (`Test-AmdWdacPolicyDeployed` and the BCD testsigning value) not the marker.

### Out of scope

- **The Path B prerequisite check** itself is unchanged. When the short-circuit does not fire (e.g. `-UseTestSigning` is explicitly passed, or some non-WHQL INF survived the P06 trim), the standard Path B prerequisite logic still runs.
- **The WHQL analysis (P05)** is unchanged. `Test-WhqlCoSignature`, `New-WhqlCoSignAnalysis`, and `Show-WhqlCoSignAnalysisReport` are byte-identical to r71.
- **The C6 CRITICAL acknowledgement** is unchanged.
- **The P06 `-SkipNonCosignedDrivers` trim** is unchanged.
- **NPU** is structurally excluded from this change. NPU does not carry `-SkipNonCosignedDrivers` (the trim mechanism is Chipset/Graphics/BthPan only), and Q-X1 refuses Install on legacy Server entirely. The short-circuit's firing conditions can never be met by NPU. NPU's version bump to r18 is a release-tag synchronisation only.
- **Cross-script consistency releases**: r72 does not introduce a new "consistency release" tier. The four scripts continue to be versioned independently with `$Script:ScriptVersion` reflecting their own revision history.

### Status

- **psa.py**: 0 errors / 0 warnings / 0 info across all 4 scripts under `python3 psa.py --config .psa.config.json Deploy-*.ps1`.
- **Sister-script PSA8001 byte-identity** preserved: the I02 short-circuit block is byte-identical between Chipset and Graphics; BthPan inherits the pre-existing `Test-MsBthPanWdacPolicyDeployed` naming divergence already documented in r71 (`psa8001_ignore_functions` covers the helper).
- **Encoding contract** honoured: `.ps1` files are UTF-8 BOM + CRLF; `.md` files are UTF-8 no BOM + LF. Verified by `file(1)` after all edits.
- **Field validation pending**: WS2019 + Renoir bench is queued for OS reinstall as of release time. TC14.9 / TC14.10 / TC14.11 in TESTING.md describe the replay procedure.

## [Chipset r71 / Graphics r37 / NPU r18 / BthPan r19] — 2026-05-23 — WHQL co-sign pre-detection + Path B prerequisite check

### Added

- **All driver scripts: new SECTION r71 block** (~452 lines per script,
  byte-identical across Chipset / Graphics / BthPan; NPU is excluded
  per the established Q-X1 refuse policy). The block introduces seven
  new helpers:
  - `Test-WhqlCoSignature` — Inspect a `.sys` file's Authenticode
    certificate chain and report whether it carries a Microsoft
    Windows Hardware Compatibility co-signature. Uses
    `Get-AuthenticodeSignature` for the primary signer and shells out
    to `signtool verify /pa /v` to enumerate nested signers when WDK
    is installed. Falls back to a conservative `self-only` verdict
    when signtool is absent (over-reports rather than under-reports).
  - `Get-InfDriverFileList` — Resolve the `.sys` file paths an INF
    declares via its `[SourceDisksFiles]` / `[CopyFiles]` sections.
    Probes both the INF's own directory and common arch subdirs
    (`amd64`, `x64`, `Win64`).
  - `New-WhqlCoSignAnalysis` — Build per-INF WHQL co-sign analysis
    records (InfName / InfPath / DriverFiles / CoSignedFiles /
    NonCoSignedFiles / IsFullyCoSigned / HasMixedSigning).
  - `Show-WhqlCoSignAnalysisReport` — Pretty-print the WHQL analysis
    to the operator console (Fully / Mixed / No co-signature counts
    plus first-10 enumeration of mixed and non-co-signed INFs).
  - `Test-SecureBootEnabledFromFirmware` — Thin wrapper around
    `Confirm-SecureBootUEFI` that returns `$true` / `$false` / `$null`
    for the firmware-layer Secure Boot state. Distinguished from
    `$bootEnvBefore.SecureBootEnabled` (OS-layer view) so the two
    can be inspected independently.
  - `Invoke-PathBPrerequisiteCheck` — I02 helper that verifies
    firmware Secure Boot is OFF before any `bcdedit` call. Returns
    `{Result; Reason; GuidanceLines}` with an `abort` outcome on
    Secure Boot ON. The guidance block enumerates the verbatim
    Microsoft Learn error message ("The value is protected by Secure
    Boot policy and cannot be modified or deleted"), a five-step
    firmware-change workflow, BitLocker recovery key advisory, and
    three alternative escape routes (Path A if all-WHQL,
    `-SkipNonCosignedDrivers` to trim, `-Force` to bypass).
  - `Get-EligibleInfRecordList` — Apply the `-SkipNonCosignedDrivers`
    filter to a candidate INF list using `$Ctx.WhqlCoSignAnalysis`.
    No-op when the switch is absent.

- **All driver scripts: `-SkipNonCosignedDrivers` param switch**
  (Chipset / Graphics / BthPan). When set, the install plan is
  trimmed at P06 entry to the WHQL-co-signed subset. Downstream
  phases (P06 patch, P07 cert, P08 catalog, V03–V06 verify, I03
  install) all read the trimmed `$Ctx.InfInventory` automatically;
  no per-phase integration changes were needed. The switch is
  opt-in by design — defaulting to skip would silently change which
  devices get drivers on existing deployments. NPU does not carry
  the switch because NPU refuses Install on legacy Server entirely
  (Q-X1, see SPEC §D.27); on WS2022+/WS2025 the switch would be a
  pure no-op and is omitted.

- **All driver scripts: `$Ctx.WhqlCoSignAnalysis` field** populated
  by P05 (`AnalyzeInfs`). Chipset and Graphics call
  `New-WhqlCoSignAnalysis` against the `NeedsPatch=true` subset of
  the inventory; BthPan calls it against the single inbox
  `bthpan.inf`. The analysis is best-effort: failures fall back to
  an empty array so I00 C6 and `-SkipNonCosignedDrivers` operate
  conservatively (C6 may not fire, Skip becomes a no-op).

- **All driver scripts: I02 Path B prerequisite call**
  (`Invoke-PathBPrerequisiteCheck`) immediately after the "BCD
  testsigning already ON?" cached-state check. On
  `Result=abort / Reason=secure-boot-on`, I02 prints the guidance
  block in red and throws before any `bcdedit` invocation, leaving
  the host state untouched. `-Force` bypasses the check, matching
  the convention for the other I02 abort conditions. BthPan's I02
  has a slightly different `Set-DebugStep` ordering versus
  Chipset/Graphics (the difference predates r71); the prerequisite
  call site is inserted at the equivalent semantic position in each.

- **Chipset / Graphics / BthPan: `Get-CriticalRiskItem` C6
  condition** — WHQL co-sign shortfall on a Secure-Boot-ON host.
  C6 fires when `$Ctx.WhqlCoSignAnalysis` contains at least one
  `IsFullyCoSigned=false` entry AND `Test-SecureBootEnabledFromFirmware`
  returns `$true` AND `$Script:SkipNonCosignedDrivers` is `$false`
  AND `$Ctx.UseTestSigning` is `$false`. The acknowledgement message
  enumerates up to 5 non-WHQL INF names and the three escape routes;
  the prompt text is `I understand non-WHQL drivers will be
  kernel-CI-rejected at boot and accept this outcome (y/N): `. C6 is
  bypassable by `-ForceUnsafe` with audit logging.

- **SPEC.md §D.31 (new section, ~162 lines)** — "WHQL co-sign
  pre-detection + Path B prerequisite check (r71)". Documents the
  background (why §D.30 stopped at removal), the four mechanisms
  (WHQL analysis / Path B prereq / C6 / Skip switch), the
  operator decision matrix, PS-5.1-specific implementation notes,
  what r71 does NOT change, the validation strategy, and the
  release version contract.

- **TESTING.md §14 (new section, ~95 lines)** — eight test cases
  covering r71 mechanisms: TC14.1 (WHQL analysis runs in P05),
  TC14.2 (Path B prereq ABORT on Secure Boot ON), TC14.3
  (`-SkipNonCosignedDrivers` trims at P06 entry, C6 does not fire),
  TC14.4 (C6 fires on Secure-Boot-ON mixed install plan), TC14.5
  (`secure-boot-unknown` continues with warning), TC14.6 (all-WHQL
  install plan: WHQL analysis reported but no special branches),
  TC14.7 (BthPan WHQL on the Microsoft inbox bthpan.inf), TC14.8
  (signtool-absent fallback is conservative). Plus the
  `-ForceUnsafe` C6 bypass negative test and the WS2019
  `-SkipNonCosignedDrivers` Path B follow-on note (a deferred
  refinement is recorded in SPEC §D.31.9).

### Changed

- **All driver scripts: P05 (`AnalyzeInfs`) phase** — Each
  `$detailReport` record now carries a `FullPath` field (Chipset /
  Graphics) so the WHQL analysis can locate the INFs without
  re-deriving the path. The Set-PhaseMarker P05 boundary now runs
  `New-WhqlCoSignAnalysis` before stamping the marker and attaches
  the result to `$Ctx.WhqlCoSignAnalysis`. BthPan's single-INF P05
  does the equivalent attachment for its inbox `bthpan.inf`. The
  P05 output gains the WHQL summary block as the last operator-
  facing section before the phase footer.

- **All driver scripts: I02 (`AuthorizeDriverSigning`) phase, Path B
  branch** — Immediately after the "BCD testsigning already ON?"
  cached-state check and before the existing OS-layer Secure Boot
  guard, I02 now calls `Invoke-PathBPrerequisiteCheck`. The
  pre-existing OS-layer guard is retained as defense-in-depth.

- **Chipset / Graphics / BthPan: I00 (`PreInstallReview`) C6 emission
  path** — `Get-CriticalRiskItem` evaluates C6 after C1/C2/C5 and
  appends to the items array on hit. `Invoke-CriticalAcknowledgementChecklist`
  is unchanged (the call site iterates whatever items the helper
  returned).

- **Chipset / Graphics: P06 (`PatchInfs`) phase entry** — A new
  `-SkipNonCosignedDrivers` filter step runs after the InfInventory
  load and before the patched-output cleanup. The step calls
  `Get-EligibleInfRecordList` and replaces `$Ctx.InfInventory` with
  the WHQL-co-signed subset when the switch is set. A diagnostic
  message is printed in either case (trim summary OR no-op
  acknowledgement). When the switch is absent, the step is a
  zero-cost early-exit.

- **BthPan: P06 phase entry** — Acknowledges the
  `-SkipNonCosignedDrivers` switch in the run transcript when set
  but never actually trims (the Microsoft inbox `bthpan.inf` is
  always WHQL co-signed by Microsoft). The acknowledgement is
  there so cross-script automation can pass the flag uniformly
  without per-script branching.

- **SPEC.md §D.27 (NPU refuses)** — Clarified that NPU's Q-X1
  refuse check is unchanged in r71; r71 does not extend NPU.

- **SPEC.md §D.28 (CRITICAL severity acknowledgement)** — Updated
  the C3 historical note: C6 is now described as "added in r71"
  rather than "planned for r71".

- **SPEC.md §D.30 (Path C deprecation)** — Updated forward
  references throughout §D.30.5 / §D.30.7 / §D.30.8 from "r71 will
  add" / "r71 (planned)" wording to "added in r71" / "r71 (shipped)"
  wording. §D.30.8 now cross-references §D.31 as the canonical r71
  contract.

- **README.md / README.ja.md "Operating systems in scope" table** —
  The WS2019 row's notes column is updated to describe
  `-SkipNonCosignedDrivers` as shipped in r71 rather than planned,
  and cross-references SPEC §D.31.

- **README.md / README.ja.md Parameters table** — The `-ForceUnsafe`
  row now lists C6 in the bypass scope (C1/C2/C5/C6) and cross-
  references SPEC §D.31.4. A new `-SkipNonCosignedDrivers` row is
  added immediately after `-ForceUnsafe`, marked `r71+`.

### Rationale

§D.30 removed the Path C WDAC SPF orchestrator after field evidence
(F1–F12) demonstrated it added a credible host-brick risk without
providing a workable alternative for non-WHQL drivers on UEFI
Secure Boot-enabled hosts. r70 stopped at removal so the deletion
diff could be reviewed in isolation; r71 lands the operator-
assistance features the orchestrator was supposed to provide but
never did.

The key operator-facing insight from §D.30 was that on legacy
Server hosts (WS2019/WS2016) with Secure Boot ON, the actual
behaviour of `bcdedit /set TESTSIGNING ON` is to be refused **at
command execution by the firmware** with an explicit error,
documented in the Microsoft Learn article "The TESTSIGNING boot
configuration option". The pre-r71 driver scripts surfaced this
only as the underlying bcdedit error; r71 catches the condition
before any host-state modification and presents a guided
firmware-change workflow plus three alternative escape routes.

The C6 acknowledgement (`Get-CriticalRiskItem` extension) closes
the same operator-protection gap that C3 used to fill in the
pre-r70 Path C era, but for the new failure mode: a mixed
WHQL / non-WHQL install plan running on a Secure-Boot-ON host
without Skip or TestSigning would silently produce devices that
fail to load (`ProblemCode=39`, `CM_PROB_DRIVER_FAILED_LOAD`) at
the next boot. C6 makes the operator acknowledge this outcome with
full knowledge of the three escape routes before I01 begins.

The `-SkipNonCosignedDrivers` switch is the only mechanism in r71
that actually changes which drivers get installed; the other three
(WHQL analysis, Path B prereq, C6) are operator-information surfaces
that do not alter the install plan unless the operator changes
their invocation in response. This split was intentional: r71 does
not silently change deployed behaviour, only the operator-visible
warnings and the new opt-in trim path.

### Migration

r71 is backward-compatible with all r70 invocations. No removed
switches, no removed phases, no removed `$Ctx` fields. Existing
automation that runs r70 invocations against r71 will see the new
WHQL summary block in P05 output and the new Path B prerequisite
check in I02; if the host has Secure Boot OFF, both are
informational and the run proceeds as before.

Operators wishing to keep Secure Boot ON on legacy Server hosts
should add `-SkipNonCosignedDrivers` to their invocation. This is
the recommended invocation pattern for r71+ on WS2019/WS2016.

Operators wishing to install non-WHQL drivers on Secure-Boot-ON
hosts must disable Secure Boot in firmware and add `-UseTestSigning`
per the guidance text printed by the Path B prerequisite check.
The BitLocker recovery key advisory in that guidance text is not
new in r71 — it has been documented in §D.30 since r70 — but r71
is the first release that surfaces it at the exact decision point
where it matters.

### Out of scope (deferred)

Two refinements identified during r71 implementation are
deliberately deferred:

- **I02 should detect "all-WHQL-after-Skip + Secure-Boot-ON +
  WS2019" and skip Path B entirely.** Today, `-SkipNonCosignedDrivers`
  trims the install plan to fully-WHQL, but I02 still attempts
  Path A (WDAC MPF, fails on CiTool absence on WS2019) and then
  Path B (prerequisite check ABORTs on Secure Boot ON). The
  operator workaround is to drop `-UseTestSigning` (which is the
  default) and rely on the trust-store-only path, but this is not
  obvious from the current messaging. A future release could add
  a "WS2019 + all-WHQL + Secure Boot ON → use trust-store only"
  short-circuit in I02. Recorded in SPEC §D.31.9.

- **PS 7+ idiom adoption**. The r71 helpers use only PS 5.1
  idioms because the driver scripts target PS 5.1 (Windows Server
  default). A future cross-cutting change could uplift the
  `(if/else) -ForegroundColor` and `-match` patterns to use the
  cleaner PS 7+ syntax once the scripts drop PS 5.1 support;
  documented in SPEC §D.31.7 as PS 5.1 footguns to be aware of.

### Status — psa.py validation

All four driver scripts continue to report **0 errors / 0 warnings
/ 0 info** under `psa.py --config .psa.config.json` after the r71
changes. PSA8001 cross-file drift detection does not fire — the
seven new helpers (`Test-WhqlCoSignature`, `Get-InfDriverFileList`,
`New-WhqlCoSignAnalysis`, `Show-WhqlCoSignAnalysisReport`,
`Test-SecureBootEnabledFromFirmware`, `Invoke-PathBPrerequisiteCheck`,
`Get-EligibleInfRecordList`) are byte-identical across Chipset /
Graphics / BthPan. The I02 Path B prerequisite call site is
byte-identical between Chipset and Graphics; BthPan's slight
structural difference at I02 entry predates r71 and is documented
in §D.31.10.


## [Chipset r70 / Graphics r36 / NPU r18 / BthPan r18] — 2026-05-23 — Path C deprecation

### Removed

- **`Deploy-WdacSinglePolicyFormatOnLegacyWindowsServer.ps1`** —
  entire file (4,096 lines). The orchestrator script that
  implemented WDAC Single Policy Format (SPF) deployment for
  Windows Server 2019 / 2016 is removed from the repository. The
  catastrophic field failure narrative previously documented in
  SPEC §D.26 plus the second 2026-05-23 single-script bench
  observation (where Chipset `Install` alone bricked WS2019 with
  Secure Boot ON, Path C present) collectively established that
  Path C added a credible host-brick risk without solving any
  problem an operator-driven Path B could not solve more safely.
  See SPEC §D.30 for the full F1–F12 evidence chain.
- **All four driver scripts: SECTION 1g** — WDAC SPF orchestrator
  delegation helpers (~190 lines per script). Specifically removed:
  `Get-CanonicalScriptHash`, `Resolve-WdacOrchestratorScript`,
  `Invoke-WdacOrchestrator`, `Invoke-LegacyWdacAuthorization`,
  the `$Script:WdacOrchestratorFileName` /
  `$Script:ExpectedWdacScriptCanonicalSha256` /
  `$Script:WdacOrchestratorRawGithubUrl` constants. NPU retains a
  minimal `Test-IsLegacyWindowsServerOs` predicate as SECTION 1h
  because the Q-X1 refuse check (see SPEC §D.27) still needs it;
  the other three scripts no longer reference it.
- **Chipset / Graphics / BthPan: SECTION (r69, QI-10)** —
  `Invoke-BootLoadableCheck` helper and its
  errorCategory-to-message translation table (~155 lines per
  script). The post-I02 dispatcher hook that invoked it (~24 lines
  per script) is also removed. BthPan's variant included a
  `(-not $phaseFailed)` guard tied to its Start-DebugTrace /
  Stop-DebugTrace wrapping; that wrapping is preserved, only the
  BootLoadableCheck call is removed.
- **All four driver scripts: I02 Path C branch** (~40 lines per
  script). The early-return block that delegated to
  `Invoke-LegacyWdacAuthorization` on WS2019 / WS2016 is removed
  from `Invoke-InstPhase02_AuthorizeDriverSigning`. I02 now falls
  through to Path A (WDAC MPF on WS2022+) or Path B (testsigning)
  on all OS versions.
- **All four driver scripts: `Test-LegacyWdacSpfAuthorizedForCert`
  function** (~48 lines per script). This predicate parsed the
  orchestrator's `manifest.json` to check whether the current
  script's cert was authorised; it has no purpose after Path C
  removal.
- **Chipset / Graphics / BthPan: `Get-CriticalRiskItems` →
  `Get-CriticalRiskItem` rename** (sister-script byte-identical
  helper). PowerShell singular-noun convention (PSA6003) cleanup
  applied at the same time as the C3 condition removal, since the
  function definition and both callers (the I00 PreInstallReview
  integration site) are byte-rewritten anyway. The rename
  preserves PSA8001 cross-file sync because all three scripts are
  updated in lockstep. Documentation cross-references in SPEC §D.28
  and TESTING §13 are updated to the new name; historical CHANGELOG
  entries (r69 and earlier) continue to use the pluralised name as
  per Keep a Changelog 1.1.0 conventions.
- **Chipset / Graphics / BthPan: `Get-CriticalRiskItem` C3
  condition** (~34 lines per script). The manifest.json-based
  "same-session WDAC SPF deploy stacking" check is removed because
  the manifest no longer exists in r70+ deployments. The QI-6
  CRITICAL acknowledgement framework is preserved; C1, C2, C5 are
  unchanged. The r71 planned `C6` condition (WHQL co-sign
  shortfall on Secure-Boot-ON host) is the planned replacement
  operator-protection mechanism for the new failure mode.
- **All four driver scripts: `param()` block switches** —
  `-ForceOverrideForeign`, `-AuditMode`, `-StrictBootValidation`.
  Plus the corresponding `$Script:` scope assignments. The cached
  `$Script:ForceUnsafe` is preserved. NPU did not carry
  `-StrictBootValidation` (no QI-10 in NPU); its removal of
  `-ForceOverrideForeign` and `-AuditMode` is unchanged in scope.
  Existing automation passing any of the removed switches will now
  fail at parameter binding, which is the intended early-failure
  signal.
- **Chipset / Graphics / BthPan: `Update-BootSigningEnvironmentForCtx`
  SPF fallback branch** (~17 lines per script). The fallback that
  consulted `Test-LegacyWdacSpfAuthorizedForCert` when
  `Test-AmdWdacPolicyDeployed` returned null is removed. The
  function's behaviour on legacy Server hosts after r70 is to
  return the boot-signing environment without any SPF-related
  state (because no SPF state exists to report).
- **Chipset / Graphics: WDAC SPF policy mention in LOAD_FAILED
  recovery message**. The post-install diagnostic line that
  pointed operators at "verify WDAC SPF policy is active via
  `-OnlyPhases V06`" is genericized to "verify the WDAC
  supplemental policy is active" — applicable to Path A on
  WS2022+, no Path C dependency. BthPan's LOAD_FAILED handling
  did not include the SPF-specific wording and is unchanged.
- **SPEC.md §D.25** ("Legacy Windows Server I02 abort on hosts
  with Secure Boot ON and CiTool absent") — entire section
  removed (~343 lines). The narrative is folded into SPEC §D.30
  Part 1 as historical context, but the original design rationale
  is no longer the canonical reference because the design itself
  has been withdrawn.
- **SPEC.md §D.26** ("Post-r04 catastrophic field failure and the
  resulting quality-improvement programme") — entire section
  removed (~186 lines). The 2025 cumulative-stacking incident
  narrative is folded into SPEC §D.30 Part 2 and into the
  rewritten README BRICK-LEVEL RISK warning.
- **SPEC.md §D.29** ("BootLoadableCheck errorCategory taxonomy
  (QI-10)") — entire section removed (~67 lines). The
  `BootLoadableCheck` action and its driver-side wrapper no
  longer exist, so the taxonomy has no referent.
- **TESTING.md §11** ("Validation Scenario 11: WS2019 Legacy
  WDAC SPF integration (r67 / WDAC SPF r03 → r04)") — entire
  section removed (~302 lines). The pilot validation scenarios
  for an orchestrator that no longer exists have no purpose.
- **TESTING.md §13 QI-10 subsection** — TC13.13 (BootLoadableCheck
  pass), TC13.14 (warn ManifestMissing without `-Strict`), TC13.15
  (fail ManifestMissing with `-StrictBootValidation`), TC13.16
  (signtool-absent pass), plus the "Negative test — orchestrator
  hash mismatch on disk" closing entry. TC13.10 (QI-6 C3 cert
  stacking) is also removed because C3 itself is removed. TC13.1
  – TC13.4 (Q-X1), TC13.5 – TC13.7 (QI-9), TC13.8, TC13.9, TC13.11,
  TC13.12 (QI-6 C1 / C2 / C5 / BthPan adapter) are retained.

### Added

- **SPEC.md §D.30** ("Path C deprecation: WDAC SPF orchestrator
  was net-negative (2026-05-23)") — new section (~135 lines).
  Records the F1–F12 evidence chain (eight bench-reproduced
  findings plus four Microsoft-Learn-cross-referenced findings),
  the falsified design assumptions, the post-r70 path matrix
  (Path A / Path B; Path C struck through), the operator
  workflow on WS2019 / WS2016 after r70, migration guidance for
  existing deployments, a file-level inventory of what was
  removed, and a forward reference to r71 (planned WHQL co-sign
  pre-detection plus Path B prerequisite checker).
- **NPU: SECTION 1h — Legacy Windows Server OS detection helper**.
  A minimal `Test-IsLegacyWindowsServerOs` predicate is retained
  in the NPU script so the Q-X1 refuse check (SPEC §D.27) can
  still gate on WS2019 / WS2016 detection. The function body is
  identical to the version that previously lived in SECTION 1g;
  only the surrounding banner and the helpers around it are
  removed.

### Changed

- **All four driver scripts: I02 phase behaviour on WS2019 / WS2016**.
  Previously, the legacy-Server path was Path C (orchestrator
  delegation). After r70, the script falls through to Path A
  (WDAC MPF) — which will fail on WS2019 / WS2016 because
  CiTool.exe is absent — and then to Path B (`bcdedit /set
  TESTSIGNING ON`), which will fail on a Secure-Boot-ON host
  because the firmware refuses the `bcdedit` command (see SPEC
  §D.30 F9). The operator-facing result on a "non-WHQL drivers
  + Secure Boot ON + no `-UseTestSigning`" host is a clear
  Path B failure with the verbatim Microsoft error message; the
  host remains bootable. r71 will surface this condition as an
  early ABORT in I02 with explicit firmware-change instructions
  before any driver-store modification is attempted.
- **SPEC.md §D.27** (NPU refuses Install on legacy Windows
  Server). The justification text is updated: previously it
  cited "untested SPF interaction code", now it cites simply
  "no physical-NPU validation on legacy Server SKUs". The
  underlying Q-X1 guard logic is unchanged. The §D.27.2
  implementation paragraph is updated to note that
  `Test-IsLegacyWindowsServerOs` is retained as the NPU
  script's own helper (SECTION 1h) rather than shared from
  SECTION 1g (which no longer exists).
- **SPEC.md §D.28** (CRITICAL severity acknowledgement). The
  C3 row in the conditions table is removed; the framework is
  described as evaluating C1 / C2 / C5 only. The original
  C3 description is preserved as a parenthetical historical
  note explaining why the framework counts to C5 rather than
  C4. The "Why C3 specifically targets the 2026-05-23 failure
  mode" subsection (§D.28.4) is rewritten as a historical note
  noting that the cumulative-stacking failure mode it targeted
  is structurally impossible to construct in r70+ releases.
- **TESTING.md §12** (Catastrophic field failure incident
  2026-05-23). A "2026-05-23 second incident — Chipset alone
  is enough to brick the host (drives r70)" subsection is
  appended documenting the single-script brick observation and
  cross-referencing SPEC §D.30 for the full investigation
  summary.
- **TESTING.md §13** (Validation Scenario 13). Section title
  updated from `QI-6 / QI-9 / QI-10 / Q-X1 (r69/r35/r17/r17/r05)`
  to `QI-6 / QI-9 / Q-X1 (r69/r35/r17/r17)`. Scope table now
  lists three families instead of four. A parenthetical note
  explains that the QI-10 test cases were removed in r70 along
  with the `Invoke-BootLoadableCheck` helper.
- **README.md / README.ja.md: BRICK-LEVEL RISK warning** rewritten
  to integrate the 2026-05-23 single-script observation alongside
  the original 2025 3-script-cumulative observation. The warning
  explicitly notes that the brick mechanism observed in both
  incidents is structurally impossible to trigger in r70+
  releases. The disclaimer's intensity is preserved.
- **README.md / README.ja.md: Operating systems in scope** table.
  The WS2019 / WS2016 rows are updated from "Path C (legacy WDAC
  SPF via external orchestrator)" to a Path A / Path B summary
  with notes on WHQL co-signed vs non-WHQL driver behaviour and
  a forward reference to r71's planned `-SkipNonCosignedDrivers`
  switch. The follow-on paragraph about "automatic delegation to
  the orchestrator" is rewritten to describe the operator-driven
  Path A / Path B workflow and cross-reference SPEC §D.30.
- **README.md / README.ja.md: Physical-machine deployment
  paragraph**. The parenthetical "the WDAC SPF policy this
  orchestrator deploys" is genericized to "the WDAC supplemental
  policy file the boot loader evaluates". The structural point
  (System Restore does not capture SiPolicy.p7b) is unchanged.
- **README.md / README.ja.md: "What about running everything in
  one pass?" warning**. The "WDAC SPF policy authorizing all
  three certs" wording is genericized to a self-signed-cert
  description. The sequencing recommendation is unchanged.
- **README.md / README.ja.md: Recovery sub-step 1.4**. The
  text is rewritten to clarify that the `del
  SiPolicy.p7b` command applies only to hosts upgraded from
  r69-or-earlier deployments that still have a legacy SPF policy
  file on disk; r70+ deployments do not deploy this file and the
  step is a no-op for them. The migration guidance (run
  orchestrator `-Action Uninstall` before upgrading) is in
  SPEC §D.30.6.
- **README.md / README.ja.md: NPU refuses warning**. The
  justification text is shortened to match SPEC §D.27 — no
  SPF references; "no physical-NPU validation on legacy
  Server" is the cited reason.
- **README.md / README.ja.md: Parameters table**. The
  `-StrictBootValidation` row is removed. The `-ForceUnsafe`
  row description is updated to list C1 / C2 / C5 only (C3 is
  no longer evaluated).
- **`Deploy-AMDNpuDriverOnWindowsServer.ps1`: Q-X1 refuse
  message wording**. The operator-facing reason is updated from
  "has not been validated on legacy Windows Server SKUs that
  require the WDAC Single Policy Format (SPF) path... would
  exercise unvalidated SPF interaction code" to "has no
  physical-hardware test coverage on these OS versions, so
  running Install (or All, which includes Install) on these
  hosts is refused as a safety measure".

### Rationale

The 2026-05-23 single-script bench observation (Chipset r69
`-Action Install` alone, Secure Boot ON, Path C present) bricked
WS2019, including Safe Mode. WinRE recovery via `del
SiPolicy.p7b` restored boot, after which the WHQL co-signed AMD
drivers loaded without any WDAC policy in place, while the
non-WHQL drivers remained kernel-CI-rejected regardless of
policy contents. Together with the previously-documented 2025
cumulative-stacking incident, this established that Path C was
the brick mechanism rather than merely a contributing factor,
and that it offered no value over operator-driven Path B for
non-WHQL drivers or trust-store-only Path A for WHQL co-signed
drivers. Microsoft Learn cross-references in the same
investigation established that `bcdedit /set TESTSIGNING ON`
under Secure Boot ON is refused at command execution (not
silently dropped by the boot loader), and that the alternative
flags `NOINTEGRITYCHECKS` / `LOADOPTIONS DISABLE_INTEGRITY_CHECKS`
are silently ignored on WS2008+ x64 — closing off any
hypothetical "bcdedit-only bypass" workaround.

### Migration

Hosts that previously deployed Path C (r67 / r68 / r69 / WDAC
SPF orchestrator r03 / r04 / r05) should, **before upgrading to
r70**:

1. Run `Deploy-WdacSinglePolicyFormatOnLegacyWindowsServer.ps1
   -Action GetStatus` to capture current state for the record.
2. Run `Deploy-WdacSinglePolicyFormatOnLegacyWindowsServer.ps1
   -Action Uninstall` to remove the deployed `SiPolicy.p7b` and
   the manifest. This avoids leaving a host-wide WDAC policy
   behind after the orchestrator is gone.

After upgrading to r70, automation that passed
`-ForceOverrideForeign`, `-AuditMode`, or `-StrictBootValidation`
to the driver scripts will fail at parameter binding. Removing
those flags from the invocation is the only required code
change. Operators who rely on the boot-time SPF policy
authorisation chain on WS2019 / WS2016 should consult SPEC
§D.30.4 / §D.30.5 to choose between Path A (trust-store only,
all-WHQL install set) and Path B (`-UseTestSigning` after
firmware Secure Boot disablement).

If recovery from a stuck post-Path-C state is required (a host
that won't boot because a Path C policy left it that way), the
recovery procedure is unchanged: WinRE → `del
C:\Windows\System32\CodeIntegrity\SiPolicy.p7b` → reboot. The
orchestrator script is no longer required for this recovery
because the policy file is the only host-state artifact and a
simple `del` accomplishes the same outcome the orchestrator's
`-Action Uninstall` did.

### Out of scope (deferred to r71)

The following operator-assistance features are **not** part of
r70. They are planned for r71 (separate release) so that the
deletion diff in r70 can be reviewed in isolation from new
functionality:

- WHQL co-sign pre-detection in P05 (`Test-WhqlCoSignature`,
  `$Ctx.WhqlCoSignAnalysis`).
- Path B prerequisite checking in I02
  (`Invoke-PathBPrerequisiteCheck`), with explicit firmware-
  change instructions, BitLocker advisory text, and the verbatim
  Microsoft error message from SPEC §D.30 F9.
- New `-SkipNonCosignedDrivers` switch for operators who want to
  keep Secure Boot ON and accept that non-WHQL drivers will not
  load.
- New `C6` CRITICAL acknowledgement condition (WHQL co-sign
  shortfall on a Secure-Boot-ON host).
- New SPEC §D.31 documenting the r71 design contract.

See SPEC §D.30.8 for the r71 plan summary.

## [Chipset r69 / Graphics r35 / NPU r17 / BthPan r17 / WDAC SPF r05] — 2026-05-23

### Context — implementing the planned improvements from r68 (QI-6 / QI-9 / QI-10 + Q-X1)

The post-r04 catastrophic field failure on 2026-05-23 (see the next release entry below and SPEC §D.26) produced a planned-improvements table (QI-1 through QI-14) for code-side mitigations. This release lands four of those items: **QI-6** (CRITICAL severity acknowledgement), **QI-9** (System Restore status warning), **QI-10** (BootLoadable WDAC SPF policy check), and a new pre-flight item **Q-X1** (NPU refuses Install on legacy Windows Server because the SPF interaction has not been validated on physical NPU hardware). The remaining QI items (QI-1 through QI-5, QI-7, QI-8, QI-11 through QI-14) remain open for subsequent releases.

No physical re-validation is possible in this release: the only WS2019 + Renoir bench is queued for OS reinstall. All changes have been verified via code review and PSA static analysis only; operators should treat r69 / r35 / r17 / r17 / r05 as "code-review validated, no bench replay" until a new physical host is available.

### Added

- **WDAC SPF orchestrator: new `-Action BootLoadableCheck` (QI-10).** Pre-flight structural sanity check for the deployed SPF policy. Verifies: (i) `ConfigCI` module is available; (ii) WDAC `AllowAll.xml` template is present under `%windir%\schemas\CodeIntegrity\ExamplePolicies\`; (iii) `SiPolicy.p7b` exists at `%windir%\System32\CodeIntegrity\`; (iv) `signtool verify /pa` against the deployed policy returns 0 (best-effort — signtool is not on stock Windows Server, in which case the check is reported as "skipped" rather than failed); (v) `manifest.json` exists and parses as JSON; (vi) authorized cert count is reported back. Each failure maps to one of a discrete `errorCategory` taxonomy (`NoPolicy` / `PolicyCorrupt` / `SignatureInvalid` / `ManifestMissing` / `ManifestCorrupt` / `ConfigCIMissing` / `AllowAllTemplateMissing` / `PermissionDenied` / `Other`) so driver scripts can print a tailored recovery message. See SPEC §D.29 for the full taxonomy.

- **WDAC SPF orchestrator: new `-Strict` switch.** When passed alongside `-Action BootLoadableCheck`, structural warnings (e.g. manifest missing on a fresh install, signtool absent) escalate to `result=fail` / `exitCode=6` instead of `result=warn` / `exitCode=5`. Without `-Strict` the BootLoadableCheck is informational; with `-Strict` it is gating.

- **WDAC SPF orchestrator: new `Find-Signtool` helper.** Locates `signtool.exe` by searching, in order: `PATH` (`Get-Command`), `$env:WindowsSdkDir`, then `${env:ProgramFiles(x86)}\Windows Kits\{10,8.1}\bin\*\x64\`. Returns the absolute path string, or `$null` if not found. Used by `BootLoadableCheck`; the absent-signtool case is handled gracefully as "signature check skipped".

- **WDAC SPF orchestrator: `Invoke-Main` switch dispatch and Help text updated to include the new Action.** Both the `Text` and `Json` output paths now list `BootLoadableCheck` in their action enumeration.

- **Driver scripts: `Invoke-BootLoadableCheck` helper (Chipset / Graphics / BthPan, byte-identical).** Driver-side wrapper around the orchestrator's new BootLoadableCheck action. On non-legacy hosts (WS2022 / WS2025, Path A/MPF) returns a synthetic `pass` with `skipped=$true`. On legacy hosts (Path C/SPF), calls `Resolve-WdacOrchestratorScript` → `Invoke-WdacOrchestrator -Action 'BootLoadableCheck'`, translates the orchestrator's `errorCategory` field into an operator-facing recovery message, and returns `[pscustomobject]@{ Result; ExitCode; Detail }`. Hooked into the phase dispatcher to run automatically after `I02 (AuthorizeDriverSigning)` succeeds and before `I03 (InstallDrivers)` starts. PSA8001-enforced byte-identical across the three scripts; region SHA256 = `a3366d00a01650ef60da3927fc2ba8910d469fe8e96e372bd2af17aa0311bd89`.

- **Driver scripts: new `-StrictBootValidation` switch (Chipset / Graphics / BthPan).** Opt-in switch that flows through to the orchestrator's `-Strict`. When set and `BootLoadableCheck` returns `fail`, the dispatcher hook throws before `I03` begins, aborting the install with the boot-policy regression risk explicitly surfaced.

- **Driver scripts: `Get-SystemRestorePointStatus` + `Show-SystemRestorePointWarning` helpers (Chipset / Graphics / BthPan, byte-identical, QI-9).** Operator-facing warning about System Restore state, called from `P01 (PrepareWorkspace)` after the workspace is created. Reports whether System Restore is enabled (`Get-ComputerRestorePoint`), how many recent restore points exist (last 30 days), and — critically — always prints the caveat that `SiPolicy.p7b` is **excluded from System Restore by design**, so rolling back a restore point cannot recover a WDAC boot-policy regression. Per Q9-A=b, System Restore is **not** automatically enabled; the helper is informational only. PSA8001-enforced byte-identical; region SHA256 = `4cf7b5d61532c591a320a46afdd61d822d09a244d024fa0c1fa311dd2e34fcb7`.

- **Driver scripts: `Get-CriticalRiskItems` + `Invoke-CriticalAcknowledgementChecklist` helpers (Chipset / Graphics / BthPan, byte-identical, QI-6).** Adds a CRITICAL severity level to the I00 PreInstallReview risk summary. Evaluates four conditions per Q6-A: **C1** display driver replacement on single-display host, **C2** BitLocker ON + AMD PSP driver replacement, **C3** another self-signed cert already authorized in the WDAC SPF manifest (= same-session stacking detected — the exact failure mode of the 2026-05-23 incident), **C5** host has not been rebooted in 24+ hours. When any item fires, the operator must acknowledge each via interactive `y/N` prompt before I01 begins. PSA8001-enforced byte-identical; region SHA256 = `34e074d2c3ead16a0ee2d63f3e7e728472bf50219fe4e971a12b4f61016411aa`.

- **Driver scripts: new `-ForceUnsafe` switch (Chipset / Graphics / BthPan).** Bypasses the CRITICAL acknowledgement checklist for CI/CD or controlled-lab automation. The bypass is recorded via `Set-DebugStep` so the audit transcript shows whether C1/C2/C3/C5 were ever surfaced. **NEVER use in production without out-of-band review** — the entire point of QI-6 is to force the operator to pause when the install plan crosses one of these tripwires.

### Changed

- **`Deploy-AMDNpuDriverOnWindowsServer.ps1` r16 → r17 (Q-X1): refuse `-Action Install` and `-Action All` on Windows Server 2019 / 2016.** The AMD NPU driver pipeline has not been validated on legacy Windows Server SKUs that require the WDAC Single Policy Format (SPF) path. Running NPU Install on these hosts would exercise unvalidated SPF interaction code with no physical-hardware test coverage. The P00 Initialize phase now early-throws if `Test-IsLegacyWindowsServerOs` returns `$true` AND `$Script:Action -in @('Install','All')`. Non-destructive actions (PrepareVerify, Verify, Prepare, Cleanup, ListPhases) remain functional on legacy hosts so operators can still inspect the workspace, run dry-runs, or clean up. See SPEC §D.27.

- **WDAC SPF orchestrator r04 → r05.** The orchestrator's canonical SHA256 changes accordingly: `f779bf50c41201a6564bf968d040cf39348433951cb83accd856245bebef7ced` (r04) → `7d61cf15ca0c3e244334d521c35f4dbf74333eaee823bc32fd8a5ba636b21dfb` (r05). All four driver scripts' `$Script:ExpectedWdacScriptCanonicalSha256` constants are updated in lock-step. The orchestrator's `ScriptTag` is updated from `'sister-script-seeded-from-chipset-r66'` to `'r05-bootloadable-check-and-strict-switch'` to reflect that r05 carries net-new functionality rather than just being a sister-script port.

- **Driver scripts: phase dispatcher modified to add a post-I02 hook (Chipset / Graphics / BthPan).** After I02 succeeds, the dispatcher invokes `Invoke-BootLoadableCheck -Strict:$Script:StrictBootValidation`. With `-StrictBootValidation`, a `Result='fail'` return is converted into a `throw` that aborts before I03; without `-StrictBootValidation`, the result is logged as a warning and I03 continues. BthPan's dispatcher uses an additional `(-not $phaseFailed)` guard because its loop body includes `Start-DebugTrace` / `Stop-DebugTrace` wrapping that needs to remain semantically intact.

- **Driver scripts: `P01 (PrepareWorkspace)` integration block (Chipset / Graphics / BthPan).** Calls `Get-SystemRestorePointStatus` and `Show-SystemRestorePointWarning` immediately before `Write-PhaseFooter 'P01' 'done'`. The integration block is byte-identical across the three scripts (729 bytes). **Note**: the original r68 handoff document referred to this insertion site as "P02 (PrepareWorkspace)" — that was a typographical error in the handoff itself; the actual phase function is `Invoke-PrepPhase01_PrepareWorkspace` (`P01`), as confirmed by the operator on 2026-05-23.

- **Driver scripts: `I00 (PreInstallReview)` integration block (Chipset / Graphics / BthPan).** Calls `Get-CriticalRiskItems -Ctx $Ctx -Matched <expr>` and `Invoke-CriticalAcknowledgementChecklist` immediately before `Write-PhaseFooter 'I00' 'done'`. Chipset and Graphics pass `$matched` (the per-device install plan built inside I00); BthPan passes `@()` because its I00 does not build a `$matched` array (single inbox `bthpan.inf` only) — C1/C2 cannot fire from an empty plan, while C3/C5 (which do not depend on `$Matched`) remain fully evaluated. The `Get-CriticalRiskItems` signature was redesigned during this release from the originally-proposed `$V06Plan.PerDeviceTargets[].Candidate.InfName` shape to the actual I00-internal `$matched[].Candidates[].InfName` shape (operator-confirmed B2 decision on 2026-05-23). See SPEC §D.28.

### Documentation

- **`SPEC.md` §D.27 (new).** NPU refuse on legacy Windows Server: rationale, refused action enumeration (Install, All), retained-functionality enumeration (PrepareVerify, Verify, Prepare, Cleanup, ListPhases), recovery path for operators who genuinely need NPU on WS2019/2016.

- **`SPEC.md` §D.28 (new).** CRITICAL severity judgement logic: data contract for `Get-CriticalRiskItems` (`$Matched` shape, BthPan `@()` adapter), each condition C1/C2/C3/C5 with detection pattern, acknowledgement UX, `-ForceUnsafe` bypass semantics and audit-trail requirements.

- **`SPEC.md` §D.29 (new).** `BootLoadableCheck` errorCategory taxonomy: per-category meaning, mapping to driver-side recovery messages, interaction with `-Strict` (orchestrator) and `-StrictBootValidation` (driver). Cross-references SPEC §D.26.3 QI-10.

- **`SPEC.md` §D.26.3 updated.** QI-6, QI-9, QI-10, and Q-X1 status changed from "planned" to "implemented (r69 / r35 / r17 / r17 / r05)" with forward links to §D.27, §D.28, §D.29.

- **`README.md` / `README.ja.md` parameter documentation updated.** New switches documented under each driver script: `-StrictBootValidation`, `-ForceUnsafe`. New action documented under the orchestrator: `-Action BootLoadableCheck` with `-Strict`. NPU-specific note added: legacy Windows Server hosts can only run non-destructive actions.

- **`TESTING.md` §13 (new).** Test cases TC13.1–TC13.16 for QI-6 / QI-9 / QI-10 / Q-X1. Includes mock fixtures for the `manifest.json` shapes that drive C3 detection, and recipes for triggering each `errorCategory` value on a controlled-lab host.

### Status

- **Behavioural status — Chipset r69 / Graphics r35 / BthPan r17 / NPU r17 / WDAC SPF r05**: code-review validated, no physical bench replay (the only WS2019 + Renoir bench is queued for OS reinstall). On a re-validation host, the expected delta from r68 / r34 / r16 / r16 / r04 is: (i) `P01` prints the System Restore status snapshot with the `SiPolicy.p7b` exclusion caveat; (ii) `I00` halts before I01 if any C1/C2/C3/C5 item fires and the operator does not acknowledge (or `-ForceUnsafe` is not passed); (iii) `BootLoadableCheck` runs automatically after I02 and either passes silently, prints a warning, or (with `-StrictBootValidation`) aborts before I03; (iv) NPU's `-Action Install` or `-Action All` immediately refuses on WS2019/2016 with a recovery message pointing to non-destructive actions.

- **Orchestrator canonical SHA256 propagation verified**: all four driver scripts (Chipset / Graphics / NPU / BthPan) embed `7d61cf15ca0c3e244334d521c35f4dbf74333eaee823bc32fd8a5ba636b21dfb`. The driver scripts will print a warning if the orchestrator on disk reports a different canonical hash; they will not refuse to proceed because the orchestrator may have been independently updated.

- **PSA8001 byte-identity verified** across Chipset / Graphics / BthPan for the three new helper regions (System Restore, BootLoadableCheck driver-side wrapper, CRITICAL acknowledgement). NPU is excluded from these regions because it refuses Install on legacy hosts (Q-X1) and therefore does not need the SPF-path machinery.

---

## [Chipset r68 / Graphics r34 / NPU r16 / BthPan r16 / WDAC SPF r04] — 2026-05-23

### Context — post-r04 catastrophic field failure

Hours after the WDAC SPF orchestrator r04 release (see the next entry) was validated in isolation, the operator ran `Chipset Install` → `Graphics Install` → `MSBthPan Install` back-to-back on the same WS2019 + Renoir + Secure Boot ON bench, **with no reboot between scripts**. All three Install actions reported successful completion of their phases (with some internal inconsistencies described below). The subsequent reboot left the host **unable to complete startup in normal mode, in any Safe Mode variant, or via WinRE offline repair**. The bench was added to the OS reinstall queue.

This release addresses every directly-attributable bug surfaced during that incident and prescribes — via the disclaimer, the quickstart, and a new SPEC section — the operational discipline whose violation produced the failure. Architectural improvements (interactive pause-between-phases, P00 recovery-USB / BitLocker-key readiness gate, `-DryRun` for I03, boot-time policy structural validation) are scoped for r69/r35/r17 and tracked in SPEC §D.26.3.

NPU script is **not** bumped in this release. Its simplified `Get-BootSigningEnvironment` / `Show-BootSigningEnvironment` helpers do not exhibit the SPF-blindness symptom (no MPF check to be blind in the first place), and the post-install I04 of NPU does not classify devices into the LOADED bucket the way Chipset and Graphics do — so neither bug A1 (SPF-aware boot signing) nor bug A2 (LOAD_FAILED gate) applies. NPU remains at r16 with its embedded `$Script:ExpectedWdacScriptCanonicalSha256` constant unchanged from the previous release.

### Fixed

- **A1 — `Update-BootSigningEnvironmentForCtx` is not SPF-aware (Chipset / Graphics / BthPan).** I04 (and any phase that emits the boot-signing table) printed `WDAC-AMD=off` / `WDAC-BthPan=off` and `Self-signed driver: BLOCKED` even moments after I02 reported successful SPF policy activation, because `Get-ActiveCodeIntegrityPolicies` only enumerates MPF policies (via `CiTool.exe` or `CiPolicies\Active\*.cip`) and the SPF policy at `C:\Windows\System32\CodeIntegrity\SiPolicy.p7b` is never inspected. **Fix**: a new helper `Test-LegacyWdacSpfAuthorizedForCert -Thumbprint <thumb>` is added to all three affected scripts (byte-identical body), which returns `$true` iff the deployed `SiPolicy.p7b` exists AND `%ProgramData%\Deploy-Drivers-For-WindowsServer\wdac\manifest.json` parses AND `authorizedCerts[]` contains a row matching the thumbprint. `Update-BootSigningEnvironmentForCtx` now consults this fallback when the MPF probe returns nothing, and on a hit sets `AmdSuppPolicyActive = true` / `MsBthPanSuppPolicyActive = true`, sets the policy-id field to a friendly marker pointing at the manifest, removes the `'No WDAC supplemental policy authorizes ...'` BlockReason, and recomputes `EffectiveCanLoadSelfSigned`. The misleading `BLOCKED` reading on SPF-active hosts is eliminated. See SPEC §D.26.1.A.

- **A2 — I04 `LOADED` disposition ignored PnP `ConfigManagerErrorCode` (Chipset / Graphics).** I04 Section 1 classified a device as LOADED based purely on `Win32_PnPSignedDriver` (driver version changed before vs after, or AFTER InfName is in our self-signed set), without consulting the PnP layer's actual binding outcome. On the failed bench, the AMD Audio CoProcessor and AMD High Definition Audio Controller appeared in `[LOADED]` while simultaneously appearing in `[FAIL]` in Section 2's functional probe with `CM_PROB_DRIVER_FAILED_LOAD` / `CM_PROB_NEED_RESTART` and the associated services Stopped. **Fix**: a new disposition `LOAD_FAILED` is introduced. After the existing LOADED classification, a post-gate queries `Get-PnpDevice -InstanceId $a.PNPDeviceID` and demotes LOADED → LOAD_FAILED whenever `ConfigManagerErrorCode != 0`. The summary section gains a LOAD_FAILED bucket with per-device output that quotes the ConfigManagerErrorCode and prints recovery hints. Section 1 and Section 2 of I04 now agree on the same devices. BthPan is not affected (it uses a driver-binding-state classification model that doesn't have a LOADED bucket). See SPEC §D.26.1.B.

- **A3 — BthPan I05 Attempt 3 `Start-Process` redirect-target validator failure.** `Invoke-BthPanPnputilRebind` (Attempt 3) used a `Start-Process` splat where both `RedirectStandardOutput` and `RedirectStandardError` pointed at the literal path `'NUL'`, which the validator (correctly) rejected with `RedirectStandardOutput と RedirectStandardError が同じであるため、実行できません` ("RedirectStandardOutput and RedirectStandardError are the same"). **Fix**: the helper now allocates four distinct `[System.IO.Path]::GetTempFileName()` paths (one stdout + one stderr per pnputil call), passes them to `Start-Process`, surfaces stderr content via `Write-Detail` on non-zero exit codes so operators can see WHY pnputil rejected the call without re-running with `-Verbose`, and cleans up the four temp files in a `finally` block. See SPEC §D.26.1.C.

- **A4 — BthPan I05 Attempt 4 service-start error visibility.** `Invoke-BthPanServiceRestart`'s `catch` block surfaced only the outer `$_.Exception.Message`, which on Windows Server is a recursively-self-referencing "Cannot start service ... due to the following error: Cannot start service ...". The actual Win32 / NTSTATUS code lives in `$_.Exception.InnerException.NativeErrorCode`. **Fix**: the `catch` block now logs the outer message AND `InnerException.Message`, `InnerException.NativeErrorCode` (hex-formatted), and `sc.exe queryex BthPan` output, making the failure mode (driver not loaded vs dependency stopped vs binary missing) immediately distinguishable. See SPEC §D.26.1.D.

### Added

- **`LOAD_FAILED` disposition class in Chipset / Graphics I04.** Sixth disposition alongside LOADED / REBOOT_NEEDED / KEPT_CURRENT / UNCHANGED / FAILED. Triggered by `Win32_PnPSignedDriver` reporting a fresh binding but `Get-PnpDevice` reporting `ConfigManagerErrorCode != 0`. Operator-visible in the disposition summary with per-device details and recovery hints. See SPEC §D.26.1.B.

- **`Test-LegacyWdacSpfAuthorizedForCert` helper in Chipset / Graphics / BthPan.** SPF-aware boot-signing probe. Parses `%ProgramData%\Deploy-Drivers-For-WindowsServer\wdac\manifest.json` and verifies the deployed `SiPolicy.p7b` exists. Byte-identical across the three scripts (PSA8001-compatible). See SPEC §D.26.1.A.

### Documentation

- **README.md / README.ja.md "Disclaimer" — brick-level risk callout + physical-machine deployment model callout.** Two adjacent callouts in the Disclaimer: (i) the "🆘 BRICK-LEVEL RISK" callout that describes the 2026-05-23 catastrophic field failure, and (ii) a NEW "🖥️ Physical-machine-only deployment model" callout that explicitly states this repository targets physical Windows Server hosts and not VMs, that physical machines have no native snapshot mechanism (no `Hyper-V Checkpoint`, no `Restore-VMSnapshot`), that Windows Server System Restore is OFF by default and even when enabled does not capture `SiPolicy.p7b`, and that the practical consequence is "a failed `-Action Install` on a physical machine has no fast-rollback path". The supported deployment model is restated as "a physical machine you are prepared to wipe and reinstall". Cross-references SPEC §D.26 and TESTING §12.

- **README.md / README.ja.md "Full installation" section rewritten with a physical-machine pre-flight Step 0.** Replaces the previous (incorrectly VM-shaped) "take a snapshot" Step 0 with a four-item pre-flight checklist appropriate to physical machines: (A) create a bootable Windows recovery USB on a SECOND machine using `RecoveryDrive.exe` or installation media, (B) record BitLocker recovery keys for C: to external storage if BitLocker is enabled, (C) strongly recommended (but optional) full disk image to external media via Macrium Reflect Free / Clonezilla / dd, (D) confirm OS install ISO + license key are on hand for last-resort reinstall. Each item explains the time / resource cost and what failure mode it protects against. Followed by the same one-at-a-time, reboot-between, V06-verify install sequence as before.

- **README.md / README.ja.md "Recovery from unbootable state" section reordered for physical-machine context.** Recovery options are now listed in the order operators should actually attempt them on a physical host (rather than in a VM-shaped "snapshot first" priority): (1) WinRE-based offline repair via the recovery USB created in Step 0A, with concrete `dism /image:C:\ /cleanup-image /revertpendingactions`, `dism /image:C:\ /remove-driver`, and last-resort `del SiPolicy.p7b` command sequences (which note the BitLocker recovery prompt that becomes the operator's blocker — hence Step 0B); (2) disk image rollback IF Step 0C was performed; (3) pull-the-disk-and-read-offline as a backup when the recovery USB itself won't boot the failed host; (4) OS reinstall as last resort. The previous "snapshot rollback is the only fully reliable option" framing was removed because it is not actionable on a physical machine without significant advance preparation.

- **SPEC.md §D.26 (new section).** Full incident narrative, bug catalogue (A1–A4 with root-cause analysis and fix detail), design defects (B1–B5 with planned-improvement entries for r69/r35/r17), planned-improvements summary table (QI-1 through QI-14), and **three** generally-applicable lessons (runtime CI activation does NOT prove boot-time acceptance; cumulative blast radius scales superlinearly; **the repository targets physical machines and physical machines have no OS-internal rollback path** — an explicit doc-process lesson learned from the post-r04 README/SPEC review when an earlier draft borrowed VM-shaped language that didn't survive contact with the physical-machine reality of the pilot environment). The §D.26.2.D "automatic snapshot creation in P02" planned improvement was withdrawn during this review (the `Checkpoint-Computer` mechanism it would have invoked does not capture `SiPolicy.p7b` and runs after the boot loader, so it does not mitigate the failure class it was supposed to address) and replaced with a "P00 recovery-USB / BitLocker-key readiness gate" planned improvement that is appropriate to physical-machine pre-flight.

- **TESTING.md §12 (new section).** Catastrophic field failure case study: bench description, action sequence, observed phase outputs (including the LOADED-vs-FAIL inconsistency and the BthPan I05 redirect failure), root-cause hypothesis with confidence ordering, test artifacts that would have caught each defect earlier, and the planned `Test-WdacPolicyBootLoadable` extension scope for r69/r35/r17.

- **CHANGELOG.md** — this entry.

### Status

- **Behavioural status — Chipset r68 / Graphics r34 / BthPan r16**: bug fixes A1–A4 verified in code review (no physical re-validation possible; the only WS2019 + Renoir bench is queued for reinstall). On a re-validation host, the expected delta from r67/r33/r15 is: (i) post-I02 boot-signing table no longer prints `BLOCKED` when SPF is active and the cert is authorized; (ii) I04 Section 1 LOADED bucket no longer contains devices that Section 2 reports as failing the functional probe; (iii) BthPan I05 Attempt 3 no longer fails with the redirect-target validator error; (iv) BthPan I05 Attempt 4 prints the Win32 error code on failure. Items (v)–(xiv) from the planned-improvements table remain open for r69/r35/r17.

- **Status — NPU**: unchanged. r16 carries forward verbatim. Its simplified boot-signing helpers do not have either bug A1 (SPF-aware) or A2 (LOAD_FAILED gate), and its physical-hardware validation status remains at the pre-r04 baseline (none).

- **Status — WDAC SPF orchestrator**: unchanged. r04 carries forward verbatim. The orchestrator's canonical SHA256 (`f779bf50c41201a6564bf968d040cf39348433951cb83accd856245bebef7ced`) is unchanged from the r04 entry; the four driver scripts' embedded `$Script:ExpectedWdacScriptCanonicalSha256` constants also carry forward verbatim, since none of the changes in this release touched the orchestrator file.

---

## [Chipset r67 / Graphics r33 / NPU r16 / BthPan r15 / WDAC SPF r04] — 2026-05-23

### Fixed

- **WDAC SPF orchestrator r03 → r04 — `Add-HistoryEntry` parameter
  scope-qualifier defect (PowerShell `param()` parse-time silent
  acceptance).** First-time pilot validation of the r03 orchestrator
  on the target bench (WS2019 build 17763 + Ryzen 5 PRO 4650U
  (Renoir) + Secure Boot ON, ConfigCI module present, AllowAll
  template present) **failed** at the chipset script's I02 phase
  with `Path C orchestrator returned exitCode=1. message=see
  orchestrator stderr` — emitted by `Invoke-WdacOrchestrator` after
  the orchestrator process had thrown. Running the orchestrator
  directly with `-Action AddCert -Verbose` surfaced the real error:

  ```
  [*] Deploying SiPolicy.p7b and activating via WMI CIM bridge...
  詳細: 操作 'CimMethod の呼び出し' が完了しました。
  [X] FAILED: パラメーター名 'CertThumbprint' に一致するパラメーターが
              見つかりません。
  ```

  The trace shows the failure point is **after** WMI activation
  (`PS_UpdateAndCompareCIPolicy.Update()` had already returned
  success and `SiPolicy.p7b` had already been deployed) but
  **before** `manifest.json` was written. Each subsequent run
  therefore found a deployed `SiPolicy.p7b` with no matching
  manifest and classified the state as `Foreign`, refusing
  `AddCert` without `-ForceOverrideForeign`. Even with the
  override, the same `Add-HistoryEntry` failure recurred, leaving
  the host in a stuck "Foreign loop". The directly-observed
  orchestrator JSON envelope showed
  `"result":"refused", "state":"Foreign", "exitCode": 0` (a
  separate cosmetic bug in `Set-JsonResult` that does not affect
  the OS process exit code; deferred for a future cleanup pass).

  **Root cause**: the `Add-HistoryEntry` helper's `param()` block
  declared `[string]$Script:CertThumbprint = ''`. Windows
  PowerShell's `param()` parser does **not** reject the
  scope-qualified form at parse time; instead it silently declares
  a literally-named parameter `Script:CertThumbprint` (colon
  included). All four call sites in the orchestrator pass
  `-CertThumbprint $thumb`, which then fails at the binding stage
  with `A parameter cannot be found that matches parameter name
  'CertThumbprint'`. Compounding the symptom: the function body
  referenced `$Script:CertThumbprint` (the script-scope variable,
  which on the `AddCert` path is always empty), so even if the
  binding had succeeded the recorded thumbprint would have been
  blank in `manifest.deploymentHistory[]`.

  **Why static analysis didn't catch this**: PSScriptAnalyzer's
  stock rule set does not flag `$Script:`-qualified parameter
  declarations, and `psa.py` did not yet have an equivalent
  repository-scoped rule, which is why `psa.py --config
  .psa.config.json` reported the r03 orchestrator as `0 errors /
  0 warnings / 0 info` despite the bug. A `PSAP0005`-class rule
  ("`param()` block must not contain scope-qualified parameter
  declarations") is now on the backlog — see SPEC §D.25 "Recommendation:
  scope-qualified parameter declarations in `param()` blocks".

  **Fix in r04** (`Deploy-WdacSinglePolicyFormatOnLegacyWindowsServer.ps1`,
  ~lines 2830-2853):

  - param block: `[string]$Script:CertThumbprint = ''` →
    `[string]$CertThumbprint = ''`.
  - function body: `certThumbprint = $Script:CertThumbprint` →
    `certThumbprint = $CertThumbprint` (use the parameter local,
    not the empty script-scope variable).
  - Prepend an in-file block comment to the function explaining
    the parse-time-silent-acceptance gotcha and cross-referencing
    SPEC §D.25 Status r04, to prevent regression in future
    sister-script refactors.

  Embedded canonical hash in all 4 driver scripts updated:
  - Was (r03):
    `0df3c8889fe80769ade52e8fa7f5518af184df6413f1bfd9c7596e0a185c82ff`
  - Now (r04):
    `f779bf50c41201a6564bf968d040cf39348433951cb83accd856245bebef7ced`

  No other code in the orchestrator or in the four driver scripts
  was touched. The 34 PSA8001-tracked shared helpers and the
  Test-WdacToolsAvailable / Install-AmdWdacPolicy /
  Uninstall-AmdWdacPolicy triplet are byte-identical to r03.

  **Files touched (r04)**:

  - `Deploy-WdacSinglePolicyFormatOnLegacyWindowsServer.ps1` — the
    two-line bug fix + comment block; `$Script:ScriptVersion`
    bumped `wdac-2026.05.23-r03` → `wdac-2026.05.23-r04`.
  - `Deploy-AMDChipsetDriverOnWindowsServer.ps1` — embedded hash
    constant only (no behavioural change).
  - `Deploy-AMDGraphicsDriverOnWindowsServer.ps1` — embedded hash
    constant only (no behavioural change).
  - `Deploy-AMDNpuDriverOnWindowsServer.ps1` — embedded hash
    constant only (no behavioural change).
  - `Deploy-MSBthPanInboxOnWindowsServer.ps1` — embedded hash
    constant only (no behavioural change).
  - `SPEC.md` — §D.25 "Status" gets a new r04 entry, the r03
    PENDING entry is upgraded to FAILED with full root-cause
    detail, and a new "Recommendation: scope-qualified parameter
    declarations in `param()` blocks" subsection is added next to
    the existing PS-version-compatibility audit; the manifest
    example reference is bumped `wdac-2026.05.23-r03` →
    `wdac-2026.05.23-r04`; the Appendix entry on "How to seed a new
    sister script" now lists both r02 (`-AsUTC`) and r04
    (`$Script:` param) as concrete cases of silently-accepted
    broken PowerShell constructs in scripts targeting PS 5.1.
  - `TESTING.md` — §11 header is retitled to "r67 / WDAC SPF
    r03 → r04" and gets a validation-history-at-a-glance table;
    TC11.1 banner / TC11.2 scriptVersion / TC11.3 canonical hash /
    TC11.4 orchestrator hash are all rebased to the r04 value;
    TC11.N4 is rewritten to match the actual non-blocking
    warn-and-continue behaviour described in SPEC §D.25 Decision 2
    (the previous "throws / I02 does NOT proceed" text was
    documentation-implementation drift).
  - `README.md` / `README.ja.md` — "What's in the box" orchestrator
    row and "Operating systems in scope" WS2019/WS2016 rows updated
    to reflect r04 pilot-validated status; the "pilot validation
    pending" caveat is removed.
  - `CHANGELOG.md` — this entry.

### Validated

- **r04 pilot validation result (2026-05-23, WS2019 + Renoir +
  Secure Boot ON)**: ✅ Pass. End-to-end run with the chipset
  driver script:
  - I02 (AuthorizeDriverSigning): `Path C` taken (legacy WDAC SPF);
    `State : None -> Ours-Healthy`; `Activation method: WMI-
    PS_UpdateAndCompareCIPolicy`; phase done in 3.57 s; **no
    reboot required**; `SiPolicy.p7b` deployed at
    `C:\Windows\System32\CodeIntegrity\`; `manifest.json` written
    cleanly under `C:\ProgramData\Deploy-Drivers-For-WindowsServer\
    wdac\`.
  - I03 (InstallDrivers): 55 INFs installed (1 reboot-required for
    the AMD PSP driver, 2 no-op when the driver store was already
    up to date, 0 failed); 5 ineligible INFs correctly excluded
    per SPEC §D.24.
  - I04 (PostInstallVerification): 42 AMD devices enumerated → 0
    LOADED / 5 REBOOT_NEEDED / 0 KEPT_CURRENT / 37 UNCHANGED / 0
    FAILED. Self-signed driver loading is currently BLOCKED
    (Secure Boot ON, no testsigning) — the operator must reboot
    to activate the new drivers; the I04 banner correctly warns
    about this and re-references the I00 instructions.
- Total elapsed: 3 min 19 s for the I02+I03+I04 phase set.

### Status

- **WS2022 / WS2025**: behaviour unchanged. Path A is still the
  active path; `Test-IsLegacyWindowsServerOs` returns false; the
  orchestrator is never invoked.
- **WS2016 (build 14393)**: pilot validation pending on physical
  hardware; structurally the same Path C as WS2019.
- **Workstation hosts**: orchestrator OS-guard refuses with
  `result=refused, exitCode=3`. Driver-script `Install` phases
  remain blocked on Workstation by default; pass
  `-AllowWorkstationInstall` to override (discouraged, see
  README.md "What's new").

---

## [Chipset r67 / Graphics r33 / NPU r16 / BthPan r15 / WDAC SPF r03] — 2026-05-23

### Added

- **NEW SCRIPT: `Deploy-WdacSinglePolicyFormatOnLegacyWindowsServer.ps1`**
  (3,863 lines). An external orchestrator that builds, deploys, and
  manages WDAC Single Policy Format (SPF) policies on **Windows Server
  2019 (build 17763) and Windows Server 2016 (build 14393)**, where
  the Multiple Policy Format (MPF) supplemental-policy infrastructure
  (CiTool.exe, `%WINDIR%\System32\CodeIntegrity\CiPolicies\Active\*.cip`)
  that WS2022+ uses is not available. Deploys to
  `%WINDIR%\System32\CodeIntegrity\SiPolicy.p7b` and activates via WMI
  `PS_UpdateAndCompareCIPolicy.Update()` (no reboot required when WDAC
  Rule Option 16 — "Update Policy No Reboot" — is set).
  - Eight Actions: `GetStatus`, `AddCert`, `RemoveCert`, `Verify`,
    `Uninstall`, `Repair`, `ComputeCanonicalHash`,
    `ComputeOwnCanonicalHash`, plus `Help`.
  - `-OutputFormat Text|Json` (default Text); driver-script callers
    use Json mode.
  - Granular exit codes: `0`=success, `1`=generic, `2`=state mismatch,
    `3`=invalid args, `4`=system error.
  - Project-reserved Policy GUID `{DDF8C2DA-A1B2-4D52-B551-446570577053}`.
  - Manifest at `%ProgramData%\Deploy-Drivers-For-WindowsServer\wdac\`
    (schema v1.0, schemaId `deploy-drivers-for-windowsserver/wdac-manifest/v1`),
    with atomic writes (temp + Move-Item rename), `deploymentHistory[]`
    capped at 50 entries, and per-thumbprint `.cer` file copies under
    `certs\{THUMBPRINT}.cer`.
  - Foreign-policy override (`-ForceOverrideForeign`) backs up the
    existing policy to `backups\{ISO-TS}-foreign-policy.p7b.bak`
    before replacement; restorable via `-Action Uninstall
    -RestoreForeignBackup`.
  - Six-state model: `None`, `Ours-Healthy`, `Ours-Stale`,
    `Ours-Tampered`, `Foreign`, `Inconsistent`. Full State × Action
    matrix and edge cases EC-1 through EC-7 documented in SPEC §D.25.
  - OS guard refuses execution on WS2022+ (build ≥ 20348) and on
    Workstation SKUs (ProductType=1) with `exitCode=3`.

- **All four driver scripts**: new parameters
  - `-ForceOverrideForeign` (no-op on WS2022+ and when
    `-UseTestSigning` in effect; required when WS2019/WS2016 legacy
    host has a Foreign WDAC SPF policy already deployed).
  - `-AuditMode` (no-op except on WS2019/WS2016 SPF path; deploys the
    SPF policy in audit mode via WDAC Rule Option 3).

- **All four driver scripts**: I02 Path C (legacy WS2019/2016 WDAC SPF).
  Before the existing Path A / Path B decision, I02 now detects the
  legacy OS via `Test-IsLegacyWindowsServerOs` and, when on a legacy
  host without `-UseTestSigning`, delegates authorization to the
  external orchestrator (Path C). The orchestrator is located locally
  (same directory as the driver script, then the current working
  directory); when absent from both locations, the driver script
  throws with a clear `Cannot locate ...` error that includes the
  canonical raw GitHub URL
  (`raw.githubusercontent.com/usui-tk/Deploy-Drivers-For-WindowsServer/main/Deploy-WdacSinglePolicyFormatOnLegacyWindowsServer.ps1`)
  so the operator can fetch the matching version manually. Automatic
  over-the-wire fetch is intentionally NOT implemented because legacy
  WS2019/WS2016 hosts are commonly in restricted networks where
  outbound HTTPS to `raw.githubusercontent.com` is blocked, and an
  explicit "place the orchestrator here" workflow is more predictable
  for change-controlled environments. The resolved orchestrator's
  canonical SHA256 is verified against the constant embedded in each
  driver script
  (`$Script:ExpectedWdacScriptCanonicalSha256 =
  '0df3c8889fe80769ade52e8fa7f5518af184df6413f1bfd9c7596e0a185c82ff'`);
  a mismatch produces a clearly logged warning (not a hard refusal),
  letting the operator decide whether to proceed.

### Changed

- **Chipset r66 → r67** — version tag changes from
  `phantom-file-reference-skip-cleanup` to
  `legacy-ws2019-wdac-spf-integration`. Integration block added (192 lines) before `Invoke-InstPhase02_AuthorizeDriverSigning`, providing
  helper functions `Get-CanonicalScriptHash`,
  `Test-IsLegacyWindowsServerOs`, `Resolve-WdacOrchestratorScript`,
  `Invoke-WdacOrchestrator`, `Invoke-LegacyWdacAuthorization`. I02
  modified to early-branch into Path C when running on WS2019/WS2016.
- **Graphics r32 → r33** — same pattern as Chipset, adapted to
  Graphics-specific `.cer` file naming (`AMD-Graphics-Driver-CodeSign.cer`).
- **NPU r15 → r16** — same pattern as Chipset, adapted to NPU's
  `$Script:`-mirrored parameter style. New parameters mirrored as
  `$Script:ForceOverrideForeign` and `$Script:AuditMode`.
- **BthPan r14 → r15** — same pattern as Chipset, adapted to
  BthPan-specific `.cer` file naming (`MS-BthPan-Driver-CodeSign.cer`).

### Conventions

- **Canonical hash function (5-copy invariant)** — the
  `Get-CanonicalScriptHash` function (SHA256 of file with UTF-8 BOM
  stripped and CRLF/LF normalized to `\n`) is now maintained in
  **five identical copies**: the four driver scripts and the new
  WDAC orchestrator. When changing the function, all five copies must
  be updated together. The orchestrator's `ComputeOwnCanonicalHash`
  Action is the authoritative dev helper to re-compute the value for
  embedding. See SPEC §D.25.
- **File-name pattern refinement** — `Deploy-{Subject}On{Target}.ps1`,
  with `Target` permitted to specialize as `LegacyWindowsServer` when
  the script is OS-specific. See SPEC §D.25.

### Fixed

- **WDAC SPF orchestrator r02 → r03 — full rebuild from Chipset r66
  verbatim per sister-script discipline (SPEC §A.13 "Reuse before
  invention").** The r01/r02 implementations were ground-up
  rewrites that diverged from the established 4-script discipline
  in two specific ways: (a) the 34 shared helper
  functions (logging primitives, Debug Trace framework,
  environment/preflight, Secure Boot baseline diagnostics) had
  subtle byte-level differences from the sister scripts, and
  (b) several helpers (`New-IsoTimestamp`, `Get-FileSha256Hex`,
  `Get-OsContext` equivalents) were independently re-implemented
  instead of inheriting verbatim from Chipset r66. r03 rebuilds
  the orchestrator by seeding from the production-validated
  Chipset r66 file and surgically:
  - removing all 21 phase functions and AMD-specific URL
    discovery / INF patching / driver-install logic (8,428 lines),
  - removing the $Ctx-dependent helpers that the orchestrator
    does not need (Section 1c boot-signing environment, most of
    Section 1d Secure Boot baseline, Section 0.25 transcript),
  - keeping the 34 shared helpers byte-for-byte verbatim
    from Chipset r66 — of those, PSA8001 actively enforces sync
    for 30 (the other 4 are Secure Boot baseline diagnostic helpers
    in `.psa.config.json` `psa8001_ignore_functions`, kept verbatim
    so any future enforcement uplift sees a consistent baseline).
    PSA8001 cross-file drift check now confirms zero divergence for
    the 30 actively-enforced helpers across all 5 scripts,
  - adding orchestrator-specific sections for the SPF policy build,
    manifest schema, state model, and action handlers (`AddCert`,
    `RemoveCert`, etc.).
  Embedded canonical hash in all 4 driver scripts updated:
  - Was (r02): `d13b6a8bc436a0d04355a1fe1df3cc5238f5cb3683bd263f196f431d0514b65c`
  - Now (r03): `0df3c8889fe80769ade52e8fa7f5518af184df6413f1bfd9c7596e0a185c82ff`
  The PS 5.1 parameter-binding fix from r02 (`Get-Date -AsUTC`,
  `Set-Content -AsByteStream`) is preserved in r03 because the
  Chipset r66 idioms it inherits never used those PS 7+ patterns
  in the first place.

- **WDAC SPF orchestrator r01 → r02 — Windows PowerShell 5.1
  parameter-binding compatibility fix.** Discovered immediately
  during r01 pilot validation on WS2019 + Renoir + Secure Boot ON
  (2026-05-22): `-Action GetStatus` failed at the first line with
  `パラメーター名 'AsUTC' に一致するパラメーターが見つかりません` /
  `A parameter cannot be found that matches parameter name 'AsUTC'`.
  Root cause: the script-level `$Script:JsonResult.timestamp`
  initializer called `Get-Date -AsUTC` with `-ErrorAction
  SilentlyContinue`. `-AsUTC` was added in PowerShell 7.1 and does
  not exist on Windows PowerShell 5.1 (the default and only PS
  version on WS2019/WS2016). `-ErrorAction SilentlyContinue` does
  NOT catch parameter-binding errors — those are terminating at the
  binding stage, before the cmdlet body runs. Fix: replace the call
  with `(Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')`,
  which works on both PS 5.1 and PS 7.x. The Uninstall path's
  `Set-Content -AsByteStream` (PS 6+) was also replaced with a
  direct `[System.IO.File]::WriteAllBytes()` .NET call for the same
  reason. Embedded canonical hash in all 4 driver scripts updated:
  - Was (r01): `e7489216db0e1dd8fb03e337e802145165305b1327149079b65c70011075f4a2`
  - Now (r02): `d13b6a8bc436a0d04355a1fe1df3cc5238f5cb3683bd263f196f431d0514b65c`

- **All four driver scripts on WS2019/WS2016 with Secure Boot ON** —
  prior to r67/r33/r16/r15, I02 aborted on these hosts because:
  1. `Test-WdacToolsAvailable` returned false (CiTool.exe absent;
     ConfigCI optional component frequently absent),
  2. Path B (testsigning) was selected as fallback,
  3. The Secure Boot pre-check correctly refused testsigning.
  The operator was left with no viable path. The r67 fix adds Path C
  (legacy WDAC SPF via external orchestrator) which keeps Secure Boot
  ON and does not require CiTool. Discovered during r66 real-machine
  validation on WS2019 + Ryzen 5 PRO 4650U (Renoir) + Chipset
  8.05.04.516 (2026-05-22). See SPEC §D.25 for the full design.

### Compatibility / Migration

- **No breaking changes**. WS2022 and WS2025 behaviour is unchanged
  (Path A still applies; `Test-IsLegacyWindowsServerOs` returns false
  on these hosts).
- **Operators upgrading from r66**: no action needed. On WS2022/2025
  the new code path is dormant. On WS2019/2016, simply re-running
  `-Action Install` triggers Path C automatically; no manual
  intervention required unless a foreign WDAC policy is already
  present (in which case the script prints a 3-option guidance
  message and exits with non-zero).
- **For self-managed deployments without internet access**, place
  `Deploy-WdacSinglePolicyFormatOnLegacyWindowsServer.ps1` next to the
  driver script(s) in the same directory before running. The local
  copy is preferred over the GitHub fetch.

### Status

- **r67 pilot validation**: PENDING. Target test bench: WS2019 build
  17763 + Ryzen 5 PRO 4650U (Renoir) + Chipset Software 8.05.04.516 +
  Secure Boot ON (same host that surfaced the r66 abort).
- **WS2022 / WS2025**: r67 behavior is functionally unchanged from
  r66. No re-verification required.
- **Workstation hosts (preview/PrepareVerify scenarios)**: the
  orchestrator's OS guard returns `result=refused, exitCode=3` with a
  clear "Server-only" message. Workstation `-Action PrepareVerify`
  does not reach I02 so Path C is never invoked.

---


### Fixed
- **Chipset r66 — `phantom-file-reference-skip-cleanup`.** Close a gap
  in r65's detect-and-skip pipeline: orphan `.cat` files left in
  skipped INF directories were being re-signed by P09. Discovered
  during r65 real-machine verification on WS2019 + Renoir +
  Chipset Software 8.05.04.516 (2026-05-22): P05 correctly flagged
  5 ineligible INFs (`AmdAppCompat.inf` ×2 paths, `AmdAS4.inf`,
  `AMDCIR.inf`, `usbfilter.inf`), P08 correctly skipped `inf2cat`
  for them (`55 ok / 0 failed / 5 skipped`), but P06 had copied
  the directories wholesale — including the original AMD-shipped
  `.cat` files — and P09 then enumerated `Get-ChildItem -Recurse
  -Filter *.cat` and re-signed all 60 of them. Net result: V01
  reported `Catalog files: 60` instead of 55, V03 verified 60
  catalogs (5 of them orphans), and the workspace ended up with 5
  catalogs that referenced hashes for files that did not exist
  on disk.

  **What was added (two cooperating defense layers, both gated on
  `Lookup.Count -gt 0` / `ineligibleDirSet.Count -gt 0`)**:

  - **Layer B — P08 orphan cleanup**: inside the existing
    `if ($ineligibleDirs.Count -gt 0)` block, after the skip-list
    is printed, P08 now enumerates `.cat` files in each ineligible
    directory and deletes them. A summary line `Cleaned N orphan
    .cat file(s) from skipped directories (would otherwise be
    picked up by P09).` is printed when N > 0. Delete failures
    (e.g., file locked) emit a `[warn]` and continue — cleanup is
    best-effort and Layer C is the safety net.
  - **Layer C — P09 ineligible-directory filter**: a new top-level
    helper function `Get-IneligibleDirSet -Ctx $Ctx` returns a
    hashtable keyed by patched-root-relative `RelativeDir`
    (lowercased) for INFs flagged ineligible. Right after the
    `.cat` enumeration, P09 partitions the result into `$catsKeep`
    (signed) and `$catsToSkip` (logged with `[~]  Excluding N
    orphan .cat file(s) from signing ...`). When the filter
    leaves zero `.cat` files (entirely defective AMD package),
    P09 reports a success no-op rather than throwing.
  - **P09 tri-state summary**: when `$catsToSkip.Count -gt 0`,
    P09's footer reports `Signing: N ok / M failed / K skipped`
    (matching P08's tri-state). The phase marker gains a `Skipped`
    field for symmetry with P08. The legacy two-state form
    `Signing: N ok / M failed` is preserved when K = 0.

  **Why two layers (defense in depth)**:
  - Normal full-pipeline runs (`-Action PrepareVerify` / `Install`)
    hit Layer B first, so P09 sees zero orphans and the filter
    block is silent.
  - Standalone P09 (`-OnlyPhases P09`) bypasses Layer B; Layer C
    catches the orphans that P06 left behind.
  - Workspaces recovered from a prior r65 run already contain the
    re-signed orphans; Layer C ignores them at the signing step
    (and Layer B would delete them if P08 were re-run).
  - Future P06/P07/P08 changes that resurrect orphans are
    contained by Layer C as a backstop.

  **Behavior on the observed Renoir + WS2019 case**:
  - r65 (defect): P08 `55 ok / 0 failed / 5 skipped` + P09
    `Signing: 60 ok / 0 failed` + V01 `Catalog files: 60` + V03
    "Verifying 60 catalog signature(s)" + V03 notice text
    `"no .cat exists"` was technically inaccurate (.cat existed).
  - r66 (fixed): P08 `55 ok / 0 failed / 5 skipped` + P08
    `Cleaned 5 orphan .cat file(s) ...` line + P09 `Signing: 55
    ok / 0 failed` (no `+ K skipped` because P08 already deleted
    the orphans) + V01 `Catalog files: 55` + V03 "Verifying 55
    catalog signature(s)" + V03 notice text now accurate.

  **Backwards compatibility**:
  - When no INFs are ineligible (clean Chipset packages, future
    AMD fix), all r66 code paths are silent and the pipeline
    output is byte-identical to r65 (which was already
    byte-identical to r64 on the no-defect path).
  - Pre-r65 `inf_inventory.csv` lacks the `EligibleForCatalog`
    column; `Get-IneligibleDirSet` returns an empty hashtable in
    that case, so Layer C never triggers (same legacy-preservation
    pattern as the r65 helpers).
  - The 5 unused but re-signed `.cat` files from an r65 run remain
    on disk as harmless artifacts when the workspace is re-used
    without `-CleanWorkRoot`. They are never referenced by I03
    (I03's per-INF skip filter excludes the corresponding INFs),
    but operators may wish to `-CleanWorkRoot` once on first r66
    run to start with a clean tree.

  **Scope (re-confirmed by 2026-05-22 real-machine validation
  across all three scripts)**: Chipset only.
  - Graphics (Adrenalin 26.5.2 Vega-Polaris Legacy, 19 INFs): P04
    7-Zip auto-detect succeeded with **0 sub-MSI failures**; P05
    found **0 ineligible INFs**; P08 reported `19 ok / 0 failed`.
    The single-EXE WIX BURN bootstrapper architecture does not
    exhibit the layered-MSI packaging defect.
  - BthPan (Microsoft inbox `bthpan.inf`, single INF): P03 located
    one inbox INF in the host's DriverStore, P04 copied only
    `bthpan.inf` + `bthpan.sys` (no `.cat` carried along, so no
    orphan-`.cat` topology exists). Phantom file references not
    applicable.
  - NPU: structurally inapplicable (uses `pnputil` directly, no
    `msiexec /a`, no `inf2cat`-per-directory loop).

  **Files touched**:
  - `Deploy-AMDChipsetDriverOnWindowsServer.ps1` (+131 / -4
    lines): `$Script:ScriptVersion` → `chipset-2026.05.22-r66`,
    `$Script:ScriptTag` → `phantom-file-reference-skip-cleanup`,
    one new top-level helper `Get-IneligibleDirSet`, P08 orphan
    cleanup block, P09 ineligible-directory filter + tri-state
    summary + Skipped marker field.
  - `SPEC.md`: §D.24 extended with "r66 orphan .cat cleanup"
    sub-section (Layer B / Layer C design + before/after
    behavior table), "Scope" paragraph rewritten as a 4-bullet
    list with 2026-05-22 cross-script validation outcomes,
    "Verification status" promoted to r66 with explicit
    pre-fix / post-fix expectations.
  - `CHANGELOG.md`: this entry.
  - `TESTING.md`: §10.5d sub-section added for r66 verification
    expectations.
  - `README.md` / `README.ja.md`: troubleshooting entry refined to
    reference Chipset r66+ rather than r65+.

  **Verification status**:
  - WS2019 + Renoir (Ryzen 5 PRO 4650U) with Chipset Software
    8.05.04.516: r66 re-verification against the 2026-05-22 r65
    workspace is pending. Expected: V01 reports `Catalog files:
    55`, P09 reports `Signing: 55 ok / 0 failed`, V03 verifies
    55 catalogs.
  - WS2022 / WS2025: not yet verified; on hosts where no INF is
    ineligible the r66 code paths are silent (no behavior delta
    from r65 / r64).

### Added
- **Chipset r65 — `phantom-file-reference-skip`.** Add detect-and-skip
  pipeline support for AMD INFs that declare files in
  `[SourceDisksFiles]` which are not physically packaged in the AMD
  MSI cabinet. Observed on `AMDCIR.inf` in Chipset Software
  `8.05.04.516`: the dual-arch INF declares both `AMDCIR.sys` (32-bit)
  and `AMDCIR64.sys` (64-bit) in `[SourceDisksFiles]`, but the MSI
  cabinet only ships the 64-bit binary. `msiexec /a` fails with exit
  `1603` (SECREPAIR `Error: 3`) and `inf2cat` subsequently fails with
  error `22.9.1` ("amdcir.sys is missing or cannot be decompressed").

  **What was added:**
  - **New `Get-InfReferencedFiles` helper function** (chipset script):
    parses an INF's `[SourceDisksFiles*]` sections and returns a list
    of declared filenames with a `Present` flag indicating whether
    each file physically exists in the INF's directory. Scope is
    deliberately narrow (no `[CopyFiles]` walk, no `SourceDisksNames`
    subdir resolution); the AMD chipset package's flat layout makes
    these unnecessary for now and the function can be extended later
    if needed.
  - **P05 (AnalyzeInfs) extension**: three new columns added to
    `inf_inventory.csv` and `$Ctx.InfInventoryDetail`:
    `ReferencedFilesCount` (count from `[SourceDisksFiles*]`),
    `MissingReferencedFiles` (`;`-joined list of names not on disk;
    empty when all present), and `EligibleForCatalog` (boolean). The
    existing `NeedsPatch` column now ANDs in `EligibleForCatalog` so
    an ineligible INF is never decorated unnecessarily.
  - **P05 console output**: when one or more SELECTED-variant INFs
    are ineligible, P05 emits a warning summary block listing each
    ineligible INF and its missing files, plus a one-line statement
    of which downstream phases will skip the INF.
  - **P05 phase marker**: `Ineligible=$N` metadata field added
    alongside the existing `Total` / `Selected` fields.
  - **P06 (PatchInfs) notification**: ineligible INFs still flow
    through the `copyOnly` path (preserving traceability per case
    alpha), but P06 now emits an informational log line listing them
    so operators understand which INFs in `patched/` are not
    candidates for catalog generation.
  - **P08 (GenerateCatalogs) skip filter**: the inf2cat loop now
    iterates `$infDirsToProcess` (= `$infDirs` minus the directories
    whose INFs are ineligible). The skip count is reported in the
    new tri-state summary line `Catalog generation: N ok / M failed /
    K skipped (using /os:...)` (the legacy two-state form is
    preserved when `K = 0`). The "EVERYTHING failed" throw now
    checks the post-filter count so a workspace where all INFs are
    ineligible reports `0/0/N` rather than throwing.
  - **P08 phase marker**: `Skipped=$K` metadata field added.
  - **V03 (`VerifyCatalogs`) informational notice**: when ineligible
    INFs exist, V03 emits a one-time `[~]` notice listing them; the
    enumeration of `.cat` files itself naturally excludes them (no
    `.cat` was produced by P08), so V03's per-catalog loop is
    unchanged.
  - **V04 (`VerifyInfs`) skip filter**: the ProductType=3 decoration
    check now iterates only eligible INFs. The summary line is
    extended to a tri-state form `INF verification: N ok / M missing
    decoration / K skipped` (the legacy two-state form is preserved
    when `K = 0`). Ineligible INFs are listed in a dedicated `[~]`
    block under the loop.
  - **V05 (`DryRunInstall`) skip filter**: the I03 dry-run
    sub-section excludes ineligible INFs from the install plan with
    a `[~]  Excluding N INF(s) from dry-run plan ...` block, so the
    dry-run output reflects exactly what I03 will actually do.
  - **V06 (`HardwareImpactAnalysis`) skip filter**: the
    `Build-PatchedInfHwidIndex` helper now excludes ineligible INFs
    from the HWID-to-INF lookup. V06's AS-IS / TO-BE comparison
    therefore does not propose ineligible INFs as TO-BE candidates
    for any matched device. V06 also emits a `[~]` notice at the
    top of its output so the operator understands the exclusion.
  - **I03 (`InstallDrivers`) skip filter**: ineligible INFs are
    filtered out at the enumeration stage, before pnputil is
    invoked. A `[~]  Excluding N ineligible INF(s) from install ...`
    block lists them with the explanation "no .cat exists; would
    have failed pnputil signature check". When the filter leaves
    zero INFs (e.g. wholly broken AMD package), I03 reports
    success-no-op rather than throwing.
  - **Two new top-level helper functions**: `Get-IneligibleInfLookup
    -Ctx $Ctx` builds a path-keyed hashtable of ineligible INFs
    from the inventory (with CSV fallback for standalone phase
    execution); `Test-InfIsIneligible -Ctx $Ctx -InfFullName $path
    -Lookup $lookup` is the per-INF skip-decision helper. Both are
    consumed by V03 / V04 / V05 / V06 / I03 to ensure a single
    source of truth for the skip predicate.

  **Behavior on the observed Renoir + WS2019 case**:
  - Before: `Catalog generation: 59 ok / 1 failed (using /os:ServerRS5_X64)` + V04 verifies all 60 INFs + V05/V06 list AMDCIR.inf in dry-run output + I03 attempts CIR install
  - After:  `Catalog generation: 59 ok / 0 failed / 1 skipped` + V04 verifies 59 INFs (1 skipped) + V05/V06 exclude AMDCIR.inf from dry-run / TO-BE + I03 excludes AMDCIR.inf from install loop

  **Backwards compatibility**:
  - Pre-r65 `inf_inventory.csv` files (loaded via P06's CSV fallback
    or P08's / V03's / V04's / V05's / V06's / I03's standalone-
    execution fallback) lack the `EligibleForCatalog` column. The
    filter treats this absence as "eligible" (legacy behavior
    preserved); the lookup is empty, and all per-phase loops execute
    exactly as in r64.
  - The `NeedsPatch=true && EligibleForCatalog=false` combination is
    impossible by construction; existing consumers that filter on
    `NeedsPatch` alone are unaffected.
  - All new code paths are guarded by `Lookup.Count -gt 0` so
    workspaces with no phantom-file-reference INFs produce
    byte-identical pipeline output to r64.

  **Also extends to a new P04 sub-MSI 1603 pattern classification**
  entry: `SEC(URE)?REPAIR:\s+.*Error:\s*3` → `1603: SECREPAIR
  missing source files (AMD MSI packaging defect; sub-MSI declares
  files in File table that are not packaged in its cabinet)`.
  Before this revision, the same 12 sub-MSI failures observed in
  Chipset 8.05.04.516 were all classified as `unknown` in
  `submsi-failures-diag.txt`'s pattern-frequency summary.

  **Files touched**:
  - `Deploy-AMDChipsetDriverOnWindowsServer.ps1` (+482 / -16 lines):
    `$Script:ScriptVersion` → `chipset-2026.05.22-r65`,
    `$Script:ScriptTag` → `phantom-file-reference-skip`,
    three new top-level helper functions (`Get-InfReferencedFiles`,
    `Get-IneligibleInfLookup`, `Test-InfIsIneligible`), one new
    elseif in the P04 sub-MSI pattern classifier, the P05 phantom
    file detection / display / phase-marker changes, P06 copy-only
    notification, P08 filter + tri-state summary, V03 informational
    notice, V04 / V05 / I03 skip filters with dedicated reporting,
    V06 inventory-aware index exclusion plus pre-section notice.
  - `SPEC.md`: new §D.24 (Phantom file reference detection +
    pipeline-wide skip), §D.21 pattern table extended with the
    SECREPAIR row.
  - `TESTING.md`: new §10.5d (Chipset phantom file reference
    detection + P08 skip) with both reproduction-on-defective-
    package and no-op-on-clean-package test plans.
  - `CHANGELOG.md`: this entry.

  **Verification status**:
  - WS2019 + Renoir (Ryzen 5 PRO 4650U) with AMD Chipset Software
    8.05.04.516: target environment for r65; verification pending
    against the same workspace that originally reported the CIR
    failure.
  - WS2022 / WS2025: not yet verified; functional behavior should
    be unchanged on hosts where no INF has phantom file references.

### Documentation
- **SPEC.md A.2 expansion + new D.23 lessons-learned entry — `encoding-and-line-endings-comprehensive`.**
  Documentation-only revision (no `.ps1` content change; revision counters
  not bumped). Captures the cross-file encoding / line-ending contract for
  this repository in a single canonical reference, and records the
  lessons learned from a defect caught in the `detection-accuracy-multi-os`
  release where a Python content-generation helper emitted LF-only line
  endings into a `.ps1` file. The defect was silently corrected by the
  repository's `.gitattributes` (`*.ps1 text working-tree-encoding=UTF-8
  eol=crlf`) during `git add`, but only after a byte-level diff against
  the committed copy surfaced a +105 byte delta with no visible content
  change.

  **What was added:**
  - **SPEC §A.2** gains four new subsections that promote the encoding
    contract from a two-row table to a normative spec:
    - **A.2.1** — Per-file-type encoding & line-ending contract (`.ps1`,
      `.md`, `.txt`, `.yml`, `.yaml`, `.json`, `.toml`, `.py`, binary
      blobs) with explicit rationale for each.
    - **A.2.2** — Five tooling rules with worked Python / Bash code
      examples showing the WRONG and CORRECT patterns for emitting
      `.ps1` content. Covers Python `open()` defaults, triple-quoted
      string literals, `str_replace`-style in-place edits, shell
      heredocs, and `.md` inverse defaults.
    - **A.2.3** — Pre-commit verification commands (PowerShell + Bash)
      that compare CR-byte count vs. LF-byte count, check for the
      UTF-8 BOM, and run the AST parser. The CR/LF equality check is
      the only one that catches the specific defect described in D.23.
    - **A.2.4** — Explicit statement that `.gitattributes` is a safety
      net, not a contract, with four scenarios where its normalization
      does NOT apply (raw downloads, `git show <blob>`, working-tree
      `psa.py` runs, mid-session editor re-reads).
  - **SPEC §D.23** — Full lessons-learned write-up of the mixed-line-
    ending defect: symptom, byte-level forensic trail, root cause
    (Python triple-quoted string literals terminate with LF on every
    host platform regardless of destination file convention), why the
    AST parser / `grep` / `psa.py` all failed to detect it, lessons
    learned (AI-agent file generation is the highest-risk vector, ZIP
    archives bypass `.gitattributes`), and a 7-step quick-reference
    checklist for any tool / agent emitting `.ps1` content.

  **Forensic data from the original defect** (preserved in D.23 for
  reference):
  - File: `Deploy-MSBthPanInboxOnWindowsServer.ps1`.
  - Region: `Get-BthPanNetChildBinding` function body, lines 4675–4779.
  - Pre-commit: LF=10205, CR=10100, LF-only=105 lines, size=507,514.
  - Post-commit: LF=10205, CR=10205, LF-only=0 lines, size=507,619.
  - Delta: +105 bytes, exactly the line count of the inserted function
    body. `.gitattributes` added one CR per LF-only line during commit
    normalization.
  - All four `.ps1` scripts pass full verification (CR/LF equality, BOM
    present, AST 0 errors, `psa.py` 0 errors) in the post-commit
    GitHub state.

  **Why this is a documentation-only release**:
  - No `.ps1` content change; the `Get-BthPanNetChildBinding` function
    is already correctly CRLF-terminated in the committed GitHub copy
    via `.gitattributes` normalization on the original `git add`.
  - No revision-counter bump on Chipset / Graphics / NPU / BthPan
    scripts.
  - Verification confirmed: AST 0 errors, CR=LF on all four scripts,
    BOM intact on all four scripts.

### Added
- **Chipset r64 / Graphics r32 / NPU r15 / BthPan r14 — Hardware-detection
  accuracy + Multi-OS resilience pass (`detection-accuracy-multi-os`).**
  Nine coordinated enhancements addressing real-machine failure modes
  observed on Japanese WS2025 Datacenter (build 26100.32860) and
  Japanese WS2022 Datacenter (build 20348):

  **[A] Driver-source classification: catalog thumbprint primary path**
   - `Get-DriverSourceCategory` (shared helper in Chipset + Graphics)
     gains a Step 0 that reads the on-disk catalog via
     `Get-AuthenticodeSignature` and compares `SignerCertificate.Thumbprint`
     against the caller-supplied `ExpectedSelfSignThumbprint` (typically
     `$Ctx.CertThumbprint`).
   - Root-cause: `Win32_PnPSignedDriver.Signer` returns empty for
     catalogs signed by certificates outside the Microsoft trust
     hierarchy, even AFTER the cert is in `LocalMachine\Root` and WDAC
     has authorized it. The legacy string-match path therefore missed
     legitimately self-signed drivers and they fell through to `[B]
     Vendor` because the patched INF retains `Provider="Advanced Micro
     Devices, Inc"`.
   - The new Step 0 is authoritative; the legacy string-match path
     remains as a fallback for callers that cannot resolve the .cat
     path.
   - Function body is byte-identical across Chipset + Graphics
     (PSA8001 compliance, 5011 bytes).

  **[B] BthPan I04: language-independent Net-class child detection**
   - New helper `Get-BthPanNetChildBinding` enumerates Net adapters
     bound to bthpan.sys / ms_bthpan using ONLY identifier fields that
     are never localized: `DriverFileName`, `ComponentID`, `PnPDeviceID`.
     `InterfaceDescription` / `FriendlyName` are display-only.
   - `Get-MsBthPanDeviceState` adds a fallback path: when the parent
     `BTH\MS_BTHPAN\<uid>` device shows the detached-shell topology
     (empty Class/Service after binding) but the host is not in error
     state, the helper is consulted; if a Net-class binding is found
     the device is correctly classified as `True`.
   - `Test-BthPanRuntimeArtifacts` rewrites the `HasNetAdapter` check
     to use the same language-independent identifiers, removing a
     pre-existing bug where the regex `'Bluetooth デバイス \(個人.*\)'`
     never matched modern Japanese WS2025 (which uses `パーソナル エリア
     ネットワーク`, not `個人ネットワーク`).
   - Invoke-InstPhase04 surfaces the Net-class child binding in
     Section 1 output when found.

  **[C] Graphics I00: TO-BE display + Risk Summary deduplication**
   - The per-device TO-BE candidate loop was emitting one row per
     HWID variant. AMD's `u0197843.inf` (Adrenalin display) declares
     ~5046 PCI VEN/DEV variants, producing nearly 1000 duplicate rows
     in I00's output for a single Graphics device.
   - Display: candidates are now grouped by `InfName|SrcSubDir` and
     the variant count is surfaced as `[+N HWID variants]`.
   - Risk Summary: a `seenPairs` hash deduplicates by
     `Device.InstanceId|InfName|SrcSubDir`, so the
     `[MEDIUM] N item(s)` count reflects actual replacement events,
     not HWID-variant noise. (Previously reported `[MEDIUM] 1069
     item(s)` collapses to `[MEDIUM] 5 item(s)` on Phoenix-class
     hosts.)

  **[D] Chipset P04: sub-MSI 1603 diagnostics**
   - Per-failure capture of the sub-MSI's last 100 log lines, with
     heuristic pattern classification (1304 lock, 1335 corrupt cab,
     1612 missing source, 1925 elevation, 1310 file collision, 1603
     CustomAction failure, generic `Return value 3`).
   - Target-directory state snapshot at failure time (Exists,
     InfCount, FileCount, LastWriteHint).
   - Aggregated dump to `$logRoot\submsi-failures-diag.txt` with
     pattern-frequency summary and per-MSI detail.
   - Note: sub-MSI failures are typically auto-recovered by the
     Nested-loop stage; this diagnostic only surfaces value when the
     parent pipeline reports payload-missing AFTER nested recovery.

  **[E-1] BthPan I05 ForceRebind (new phase)**
   - New install phase `Invoke-InstPhase05_ForceRebind` activates ONLY
     when I04 reported `PartialOrPhantom` (a real, post-[B]-detection
     failure). Skips immediately when I04 reported `TrueResolution`
     or `NoDevice`.
   - Escalating rebind cascade (idempotent, stops on first success):
     1. `Restart-PnpDevice` (WS2019+)
     2. `Disable-PnpDevice` + `Enable-PnpDevice` (WS2019+)
     3. `pnputil /remove-device` + `/scan-devices` (all WS)
     4. `Stop-Service BthPan` + `Start-Service BthPan` (all WS)
   - Capability detection (`Get-RebindCapability`) selects available
     attempts; missing cmdlets are gracefully skipped on WS2016.
   - On success, promotes `I04OverallResult` to `TrueResolution` and
     clears the pending-reboot marker via `Clear-PendingRebootMarker`.
   - Phase registry, workstation-install gate (`I0[0-4]` → `I0[0-5]`),
     and Ctx schema (`I05OverallResult`, `I05PerDeviceResults`) all
     updated.

  **[E-2] WS2019 CIM bridge for WDAC supplemental policy (all 4 scripts)**
   - `Install-AmdWdacPolicy` / `Install-MsBthPanWdacPolicy` /
     `Install-WdacPolicy` (NPU) gain an intermediate fallback layer
     between the CiTool path (WS2022+) and the reboot fallback:
     `Invoke-CimMethod -Namespace 'root\Microsoft\Windows\CI'
     -ClassName 'PS_UpdateAndCompareCIPolicy' -MethodName 'Update'
     -Arguments @{FilePath=$deployedPath}`.
   - WS2019 can now activate supplemental policies WITHOUT reboot
     (previously the script required reboot on WS2019 because CiTool
     is absent). WS2016 lacks `PS_UpdateAndCompareCIPolicy` and
     correctly falls through to the reboot path.
   - Return objects extended with `CimBridgeTried`, `CimBridgeStdout`,
     `CimBridgeError` so callers can diagnose which path was taken.
   - `ActivationMethod` label surfaces the chosen path:
     `CiTool (immediate, no reboot)` |
     `CIM bridge (PS_UpdateAndCompareCIPolicy, no reboot)` | `reboot`.

  **OS support matrix (clarified):**

  | Capability                              | WS2025 | WS2022 | WS2019 | WS2016 |
  |---|---|---|---|---|
  | CiTool.exe (immediate policy refresh)   | ✅    | ✅    | ❌    | ❌    |
  | PS_UpdateAndCompareCIPolicy CIM bridge  | ✅    | ✅    | ✅    | ❌    |
  | Restart-PnpDevice (I05 Attempt 1)       | ✅    | ✅    | ✅    | ⚠️   |
  | Disable/Enable-PnpDevice (I05 Attempt 2)| ✅    | ✅    | ✅    | ⚠️   |
  | pnputil /remove-device (I05 Attempt 3)  | ✅    | ✅    | ✅    | ✅    |
  | BCDEdit testsigning fallback             | ✅    | ✅    | ✅    | ✅    |

  **[F] I04 driver-source classification: OEM-name set lookup (Step 0b)**
   - `Get-DriverSourceCategory` (shared helper in Chipset + Graphics)
     gains a Step 0b that consults a pre-built `KnownOurInfSet`
     hashtable passed by the caller. When `Win32_PnPSignedDriver.InfName`
     returns the OEM-numbered short name (`oem45.inf`) on one build
     but the original short name (`u0201039.inf`) on another, Step 0a's
     `C:\Windows\INF\<InfName>.cat` path lookup misses on the
     latter — the catalog file there is named `oem45.cat`, not
     `u0201039.cat`. Step 0b removes this dependency on the WMI
     short-name encoding by using a name-set that already maps both
     forms to the same release.
   - New helper `Get-OurSignedOemInfSet` (also shared, byte-identical
     across Chipset + Graphics) builds the set once per I04 invocation:
     - **Pass 1**: scans `C:\Windows\INF\oem*.cat`, calls
       `Get-AuthenticodeSignature` on each, and adds matching
       `oem<N>.inf` / `oem<N>.cat` names to the set when the
       `SignerCertificate.Thumbprint` equals `$Ctx.CertThumbprint`.
     - **Pass 2**: runs `pnputil /enum-drivers`, parses the
       Published Name / Original Name pairs (English + Japanese
       label patterns: `Published Name` / `公開名` /
       `発行された名前`, `Original Name` / `元の名前` /
       `元のファイル名` / `元のドライバー名`), and aliases each
       matched OEM-numbered name to its original short name in the
       set.
   - Symptom this fixes (operator observation): Graphics I04
     `[LOADED]` row for `AMD Radeon(TM) Graphics` displayed
     `AFTER: [B] Vendor` instead of the correct `AFTER: [C]
     Self-Signed (this script)` after a successful install. After
     the fix it consistently reports `[C]`.
   - Function body of both shared helpers stays byte-identical
     across Chipset + Graphics (PSA8001 compliance verified by
     `diff`).

  **[G] I04 disposition: new `LOADED-via-OS-binding` branch**
   - The post-install disposition logic in
     `Invoke-InstPhase04_PostInstallVerification` (Chipset + Graphics)
     gains a new classification branch between
     `BeforeDriverVersion != AfterDriverVersion -> LOADED` and the
     conservative `else -> REBOOT_NEEDED` fallback.
   - When the OS reports the device is currently bound to one of OUR
     signed INFs (per the `$ourInfSet` built in [F] above), the
     device is classified as `LOADED` even when the BEFORE/AFTER
     `DriverVersion` comparison returned same-version. This is
     accurate: the device has already accepted our binding; the
     version field simply did not change because the binary content
     of our driver matched what was already in the store.
   - Symptom this fixes (operator observation): the I03 vs I04
     "reboot pending" counter discrepancy. I03 reported `1 INF
     installed (REBOOT REQUIRED)` but I04 reported `REBOOT_NEEDED:
     5 device(s)` on the chipset script (and `0` vs `4` on the
     graphics script). The conservative fallback was over-counting
     devices that were actually LOADED-but-version-unchanged.

  **[H] I04 REBOOT_NEEDED display: informative fallbacks for empty fields**
   - When `$p.Before.DriverVersion` is empty (Microsoft inbox class
     driver with no version field) the display now renders
     `Still on v(unknown)` instead of `Still on v` (no value).
   - When `$p.Candidate` is null (no HWID in our patched set
     matched this device's `PNPDeviceID` via
     `Build-PatchedInfHwidIndex`) the display falls back to the
     OS-reported `InfName` as `(OS-bound: <name>)` rather than the
     unhelpful `(none)`. This gives the operator an actionable hint
     about which driver Windows is currently binding even when our
     INF index does not have a corresponding entry.
   - Cosmetic-only change to the per-device output; no impact on
     classification counters.

  Verified outcomes per script:
   - All 4 scripts: AST 0 parse errors.
   - `Get-DriverSourceCategory`: byte-identical across Chipset + Graphics (PSA8001).
   - `Get-OurSignedOemInfSet` (new): byte-identical across Chipset + Graphics (PSA8001).
   - PSA8001 baseline: 49 pre-existing violations, 0 net change from this release.
   - Bilingual READMEs and SPEC.md updated to document the new I05
     phase, multi-OS fallback chain, language-independent detection
     design, and the [F]-[H] post-install verification improvements.

### Fixed
- **MSBthPan r14 — I05 `ParameterArgumentValidationError` on early-return paths.**
  `Invoke-InstPhase05_ForceRebind` called
  `Write-PhaseFooter 'I05' 'no-op'` on two early-return paths
  (I04 result is `TrueResolution` / `NoDevice`, and the
  `BTH\MS_BTHPAN` device is absent), but the `Write-PhaseFooter`
  cmdlet's `[Parameter()] [ValidateSet('done','cached','skipped','failed')]
  [string]$Status` validator rejects `'no-op'` as an invalid value
  and aborts the phase with a `ParameterArgumentValidationError`.
   - Symptom (operator log): `Cannot validate argument on parameter
     'Status'. The argument "no-op" does not belong to the set
     "done,cached,skipped,failed"` raised at `I05` after a clean,
     no-rebind-needed install (the `Write-Skip` line above the
     footer is logged correctly, but the phase exit code becomes
     non-zero).
   - Fix: both `'no-op'` literals are replaced with `'skipped'`
     (the user-visible `Write-Skip 'I05 is a no-op'` /
     `Write-Skip 'Nothing to rebind'` lines are preserved on stdout;
     only the footer-status token changes). The third
     `Write-PhaseFooter 'I05' 'done'` path on the successful-rebind
     branch is unaffected.
   - Per-revision compliance: `Set-PhaseMarker -Metadata @{
     Skipped=$true; Reason=$Ctx.I04OverallResult }` is retained, so
     the SPEC.md §D.22 "I05 is a no-op when I04 reports
     `TrueResolution`/`NoDevice`" contract is unchanged in behaviour
     and trace metadata; only the user-facing footer-status token
     is corrected.

### Changed
- **Chipset r63 / Graphics r31 / NPU r14 / MSBthPan r13 (cross-script consistency release — `psa-py-v360-baseline-uplift`).**
  Coordinated uplift to keep the static-analysis baseline clean
  against the upstream
  [`psa.py` v3.6.0](https://github.com/usui-tk/ai-generated-artifacts/tree/main/scripts/python/powershell-static-analyzer)
  release. Five new rules were added to `psa.py` (PSA2007, PSA2008,
  PSA3006, PSA6007, PSA6008) and the PSA2002 risky-shadow set was
  expanded from 8 to 38 entries — together they would have raised
  ~90 new findings across the four scripts if left unaddressed. The
  uplift below restores **0 errors / 0 warnings / 0 info on all four
  scripts** while preserving PSA8001 byte-for-byte parity on the
  shared helpers.

  **True defects fixed (auto-variable shadowing — would have
  malfunctioned at runtime in subtle ways):**
  - `$home = Get-WinHomeLocation ...` → `$winHomeLocation = ...`
    (in `Get-MachineRegion`, present in Chipset / Graphics /
    MSBthPan; NPU does not contain this function).
    `$HOME` is the engine's user-profile path; assigning to it
    inside a function pollutes the script scope and would have
    given misleading results to any subsequent `$HOME`-based path
    construction.
  - `$profile = 'WS2025'` (and 8 more lines in the same OS-profile
    mapping block) → `$osProfile = 'WS2025'` (in
    `Show-OperatingSystemDetail`, NPU only).
    `$PROFILE` is the engine's PowerShell-profile-script path;
    reassigning it inside a function would have masked the user's
    actual `$PROFILE` for the rest of the script execution.

  **Documentation / contract refinements (no runtime behaviour change):**
  - `[OutputType([<type>])]` declarations added to **27 functions**
    across the four scripts (5 common helpers in all four scripts:
    `Format-DebugFailure`, `Format-SecureBootBaselineForReport`,
    `Get-DebugTraceFileOutputStatus`,
    `Get-SecureBootCertificateInventory`,
    `Invoke-MsSecureBootDetectScript`; plus 22 script-specific
    helpers). The annotations make the function's return contract
    visible to `Get-Command -Syntax`, `Get-Help -Full`,
    IntelliSense, and downstream PSScriptAnalyzer type inference.
  - `Get-OrEnsureSecureBootBaseline` (per-script by design — already
    in `psa8001_ignore_functions`) gained the annotation in all
    four scripts.

  **Intentional WMI fallback paths now have inline suppression:**
  - 15 lines across the four scripts (5 in Chipset, 5 in Graphics,
    2 in NPU, 3 in MSBthPan) where `Get-WmiObject` is a deliberate
    fallback for CIM-constrained environments now carry the inline
    suppression marker
    `# psa-disable-line PSA3006 -- intentional fallback when CIM is constrained; PS 5.1 still supports WMI cmdlets`.
    These lines are unchanged behaviourally; only the comment was
    appended.

  **Verification (post-uplift):**
  - `python3 psa.py <script>` on all four scripts: 0/0/0
  - `python3 psa.py <all-four-scripts> --config .psa.config.json`
    (PSA8001 multi-file mode): clean
  - PSA8001 byte-for-byte parity of shared helpers preserved
    (verified by SHA-256 of each shared-helper body across the
    four scripts).

  `$Script:ScriptVersion` bumps:
  - `Deploy-AMDChipsetDriverOnWindowsServer.ps1`:
    `chipset-2026.05.20-r62` → `chipset-2026.05.20-r63`
  - `Deploy-AMDGraphicsDriverOnWindowsServer.ps1`:
    `graphics-2026.05.20-r30` → `graphics-2026.05.20-r31`
  - `Deploy-AMDNpuDriverOnWindowsServer.ps1`:
    `npu-2026.05.20-r13` → `npu-2026.05.20-r14`
  - `Deploy-MSBthPanInboxOnWindowsServer.ps1`:
    `msbthpan-2026.05.20-r12` → `msbthpan-2026.05.20-r13`

  All four `$Script:ScriptTag` values are set to
  `'psa-py-v360-baseline-uplift'`.

- **Chipset r62 / Graphics r30 / NPU r13 / MSBthPan r12 (cross-script consistency release — `debugtrace-helper-internal-cleanup`).**
  Backport from the sibling repository
  [`usui-tk/ai-generated-artifacts`](https://github.com/usui-tk/ai-generated-artifacts)
  (`scripts/powershell/download-speakerdeck-oracle4engineer/Download-SpeakerDeck.ps1`).
  Three internal-quality refinements to shared helper functions in the
  Debug Trace facility and the environment-display function. **All four
  scripts MUST be bumped together** because the affected functions are
  shared helpers governed by `psa.py` rule PSA8001 (function-body drift)
  — see [`SPEC.md`](./SPEC.md) §A.11.5b.
  - **`_DebugTrace_WriteJsonlLine` — rename parameter `$Event` to
    `$EventObject` to avoid shadowing the PowerShell automatic
    variable `$Event`.** `$Event` is populated by the engine inside
    event-subscriber action blocks (`Register-ObjectEvent`,
    `Register-WmiEvent`, etc.). The original parameter name would have
    silently misbehaved if this helper were ever called from inside
    such a block. PSScriptAnalyzer rule
    `PSAvoidAssignmentToAutomaticVariable` flags this as a Warning.
    A multi-line comment immediately above the `param()` block
    records the rationale verbatim so future maintainers do not
    "fix" the renamed parameter back to `$Event`. Call-site signature
    is unchanged (all current call sites pass the event object as a
    positional argument, e.g.,
    `_DebugTrace_WriteJsonlLine ([pscustomobject]@{ kind = ... })`),
    so no downstream code requires modification.
  - **`Export-DebugTraceJson` — add `[OutputType([string])]`
    attribute.** The function returns the resolved export path as a
    `[string]`. The explicit `OutputType` declaration documents this
    contract to PowerShell tooling (IntelliSense, `Get-Command -Syntax`,
    `Get-Help`) and to PSScriptAnalyzer (rule
    `PSUseOutputTypeCorrectly`, Information level). Pure annotation —
    no behavioural change.
  - **`Show-PowerShellEnvironment` — add explicit `param()` block plus
    `[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWMICmdlet')]`
    with rationale.** The function already implements an intentional
    `Get-WmiObject` fallback path (CIM is the primary path; WMI is
    the secondary path used only when CIM is constrained on Server Core
    or other restricted images). The `param()` block was previously
    omitted (PowerShell allows this for parameterless functions);
    adding the explicit `param()` is a precondition for attaching the
    suppression attribute. The `Justification` argument records the
    design intent verbatim so the suppression does not become a
    silent "ignore everything" gate. This change is preparatory for a
    future introduction of PSScriptAnalyzer in this repository's CI
    pipeline; today's `psa.py` baseline (0/0/0 on all four scripts)
    is unaffected.
  - PSA8001 (function-body drift) verification: after the change, the
    SHA-256 hashes of all three modified function bodies are identical
    across all four scripts (`_DebugTrace_WriteJsonlLine` hash prefix
    `be240309b6ef`, `Export-DebugTraceJson` `ec7c3a391fd5`,
    `Show-PowerShellEnvironment` `dfbdef374b4c`). Every script grew
    by exactly +913 bytes, confirming structural symmetry.
  - `Deploy-AMDChipsetDriverOnWindowsServer.ps1`: `$Script:ScriptVersion`
    bumped to `chipset-2026.05.20-r62`, `$Script:ScriptTag` set to
    `debugtrace-helper-internal-cleanup`.
  - `Deploy-AMDGraphicsDriverOnWindowsServer.ps1`:
    `$Script:ScriptVersion` bumped to `graphics-2026.05.20-r30`,
    `$Script:ScriptTag` set to `debugtrace-helper-internal-cleanup`.
  - `Deploy-AMDNpuDriverOnWindowsServer.ps1`: `$Script:ScriptVersion`
    bumped to `npu-2026.05.20-r13`, `$Script:ScriptTag` set to
    `debugtrace-helper-internal-cleanup`.
  - `Deploy-MSBthPanInboxOnWindowsServer.ps1`: `$Script:ScriptVersion`
    bumped to `msbthpan-2026.05.20-r12`, `$Script:ScriptTag` set to
    `debugtrace-helper-internal-cleanup`.

- **Chipset r61 / Graphics r29 (`.NOTES` header pattern alignment).** The
  Chipset and Graphics scripts' `.NOTES` headers have been restructured
  to follow the same sidebar pattern used by NPU r12 and MSBthPan r11,
  establishing structural symmetry across all four sibling scripts:
   - Added the sidebar info block at the top of `.NOTES`:
     `Repository` / `Sister scripts` / `License` / `Current version`.
   - The pre-existing operator caveats (`Run from an elevated PowerShell
     session`, `Lab / verification use only`, `Always perform Steps 1-2
     ... BEFORE using this script`) are preserved verbatim below the
     sidebar — these caveats remain important and were not displaced.
   - `Sister scripts` enumerates the three siblings explicitly:
     - Chipset: `Deploy-AMD{Graphics,Npu}DriverOnWindowsServer.ps1`,
       `Deploy-MSBthPanInboxOnWindowsServer.ps1`
     - Graphics: `Deploy-AMD{Chipset,Npu}DriverOnWindowsServer.ps1`,
       `Deploy-MSBthPanInboxOnWindowsServer.ps1`
   - No functional / behavioural changes; purely a docstring cleanup
     to bring Chipset and Graphics into structural parity with NPU r12
     and MSBthPan r11.
   - `Deploy-AMDChipsetDriverOnWindowsServer.ps1`: `$Script:ScriptVersion`
     bumped to `chipset-2026.05.18-r61`, `$Script:ScriptTag` set to
     `notes-header-pattern-alignment`.
   - `Deploy-AMDGraphicsDriverOnWindowsServer.ps1`:
     `$Script:ScriptVersion` bumped to `graphics-2026.05.18-r29`,
     `$Script:ScriptTag` set to `notes-header-pattern-alignment`.

- **NPU r12 (`.NOTES` header pattern alignment).** The NPU script's
  `.NOTES` header has been restructured to follow the same sidebar
  pattern used by `Deploy-MSBthPanInboxOnWindowsServer.ps1`:
   - The stale `Version: an earlier revision` placeholder line was
     removed; the canonical reference is now
     `Current version: see $Script:ScriptVersion below`, pointing
     to the single source of truth at runtime.
   - The redundant `Author` line was removed (the repository URL
     already identifies the contributor set).
   - The `Repo` line was renamed to `Repository` and the field
     widths were aligned with the MSBthPan header (`Repository`,
     `Sister scripts`, `License`, `Current version`).
   - `Sister scripts` now enumerates the three siblings explicitly
     (Chipset, Graphics, MSBthPan).
   - No functional / behavioural changes; purely a docstring cleanup.
   - `$Script:ScriptVersion` bumped to `npu-2026.05.18-r12`,
     `$Script:ScriptTag` set to `notes-header-pattern-alignment`.

- **NPU r11 / MSBthPan r11 (repo-name canonicalization + MSBthPan WDAC provider rename).**
  In-script references to the historical repository name
  `Deploy-AMD-Drivers-For-WindowsServer` have been replaced with the
  current canonical name `Deploy-Drivers-For-WindowsServer`. The
  historical name is no longer a valid GitHub repository; references
  to it would 404 if followed.
   - `Deploy-AMDNpuDriverOnWindowsServer.ps1` (r10 → r11): updated
     `.NOTES` header (`Author` / `Repo` lines) and `$Script:RepoUrl`.
     No WDAC-related strings were changed in this script
     (`$Script:CertSubjectCn` / `$Script:WdacPolicyName` were already
     canonical: `'AMD NPU Driver Self-Sign (WS2025 Lab, At Own Risk)'`
     and `'AMD-NPU-Driver-SelfSign-Lab'`).
   - `Deploy-MSBthPanInboxOnWindowsServer.ps1` (r10 → r11): the WDAC
     `$providerName` string (inserted into the INF `[strings]` section
     as `PROVIDER_NAME` and used as the certificate provider display
     string in catalog signing) was changed from
     `'Deploy-AMD-Drivers-For-WindowsServer Project'` to
     **`'MS BthPan Inbox Driver Self-Sign (Lab, At Own Risk)'`**.
     The new name (51 characters):
     - aligns with the NPU script's `$Script:CertSubjectCn` pattern
       (`<Driver Name> Self-Sign (<Context> Lab, At Own Risk)`),
     - removes the misleading "AMD" prefix (the MS BthPan inbox driver
       is unrelated to AMD silicon), and
     - explicitly signals the unofficial, self-signed, lab-only nature
       of the resigned driver to anyone inspecting Device Manager,
       `pnputil /enum-drivers`, or the WDAC policy report.
   - The corresponding `.PARAMETER ProviderName` doc example in
     `Set-InfProviderForResigning` was updated to the same string.
   - **Operator note on existing deployments:** environments that
     previously deployed catalogs signed under the old provider name
     will keep working — Windows uses the catalog signature, not the
     provider display string, for policy decisions. New deployments
     from r11 onward will carry the new provider name in INF
     `[strings]` and in the catalog metadata.
   - Chipset r60 and Graphics r28 are unaffected; they did not carry
     either the historical repository name or a WDAC provider string.
- `.psa.config.json` now opts in to the new opt-in revision-discipline
  rules `PSAP0003` (inline `# rNN:` revision-tag comments) and `PSAP0004`
  (end-of-file `REVISION HISTORY` comment blocks) introduced in
  `psa.py` 3.3.0. Both rules report 0 hits across all four scripts at
  the current baseline; the opt-in ensures that any future commit
  re-introducing inline revision tags or in-script history blocks will
  be flagged by the static-analysis gate.
- **Documentation: `psa.py` references aligned to the "latest mainline"
  policy.** Forward-looking text in `SPEC.md`, `README.md`,
  `README.ja.md`, `TESTING.md`, and `.psa.config.json` no longer pins
  `psa.py` to a specific SemVer (previously written as `v3.3.0`); they
  now describe `psa.py` as "latest mainline" and direct readers to the
  authoritative `VERSION` file in the canonical
  [ai-generated-artifacts](https://github.com/usui-tk/ai-generated-artifacts)
  repository.
   - `SPEC.md` §A.11 gained a new *Version policy* subsection that
     codifies the rationale (new opt-in rules may surface previously-
     hidden discipline violations; tightened heuristics may reclassify
     previously-clean code) and the canonical LLM / AI workflow for
     adopting a new `psa.py` version (fetch `VERSION` via `curl`,
     compare against local, replace `psa.py` + `VERSION` together if
     they differ, re-evaluate `.psa.config.json` against the new
     `psa.py` `SPEC.md`, re-run the full static-analysis pass).
   - `README.ja.md` was simultaneously brought back into sync with
     `README.md`'s rule coverage table: it previously documented the
     pre-3.3.0 state (34 rules, `PSAP0001`..`PSAP0002`) and is now
     updated to the current state (36 rules, `PSAP0001`..`PSAP0004`).
   - Version-specific references that record historical fact remain
     intact: which `psa.py` version introduced which rule (e.g.
     "`PSAP0003` / `PSAP0004` added in 3.3.0"), and which baseline was
     verified under which `psa.py` version, are still recorded
     verbatim in `CHANGELOG.md` and in the configuration's
     introductory comments.
   - No PowerShell script bodies were modified;
     `$Script:ScriptVersion` / `$Script:ScriptTag` are unchanged;
     `psa.py` (current mainline) baseline of 0 / 0 / 0 across all
     four scripts is preserved.
- **Documentation: consumer-side adoption of the `psa.py`
  self-quality gates.** Following the upstream introduction of the
  `--config-check` (Pillar 2) and `--self-check` (Pillar 3) gates in
  `psa.py` 3.5.0, this repository's documentation was updated to
  describe how, and when, consumers should run them:
   - `SPEC.md` gained a new §A.11.6 *Self-quality gates for `psa.py`
     (consumer-side usage)* that documents each gate's command-line
     usage, expected output on a clean tree, exit-code semantics,
     and an "activation matrix" mapping PR triggers (touching
     `.psa.config.json`, refreshing a locally-cached `psa.py`, any
     PR touching PowerShell files) to which gate to run when.
   - `CONTRIBUTING.md` *Before opening a PR* gained a sub-bullet
     under the existing static-analyzer step recommending
     `--config-check` for any PR that edits `.psa.config.json`,
     and `--self-check` for any PR that refreshes `psa.py` from
     mainline. The full PowerShell static-analysis pass remains the
     single hard PR gate; the new checks are cheap pre-flight aids,
     not additional mandatory gates.
   - `CONTRIBUTING.md` *Testing your change* smoke-test snippet
     gained two optional pre-steps (0a and 0b) showing the exact
     command line and expected output for each gate.
   - `TESTING.md` §0 NPU verification entry and §3 NPU Verification
     activity matrix now reference `--config-check` as a completed
     pre-flight check against `.psa.config.json`.
   - The four PowerShell scripts and `.psa.config.json` are
     unchanged; the canonical 0 / 0 / 0 baseline across all four
     scripts under `psa.py` latest mainline remains intact. The
     `--config-check` gate against the shipped `.psa.config.json`
     reports `issues : 0`.

### Removed

- **Documentation policy enforcement: `CHANGELOG.md` is the single
  source of truth for revision history.** Per the policy stated at
  the top of this file (which previously applied only to per-script
  PowerShell files), `README.md`, `README.ja.md`, `SPEC.md`, and
  `TESTING.md` no longer carry inline revision-number references for
  current state, feature-introduction timing, or in-text historical
  attribution. Users should treat the mainline tree as the latest
  version and consult `CHANGELOG.md` for revision-by-revision history.

  Specifics:
   - **Forward-looking references removed**: "Current release: Chipset
     r61 / Graphics r29 / NPU r12 / BthPan r11", "as of rXX baseline",
     per-script "Current revision" headers in SPEC.md Part B, etc.
   - **Feature-introduction-timing references removed**: "From Chipset
     r59 / Graphics r27 / NPU r9 / BthPan r9, ...", "(r58+ / r26+ /
     r8+ / r2+) ..." etc.
   - **Historical references abstracted (sections preserved)**: SPEC.md
     Part D's 17 Known Pitfalls sections retained for design knowledge;
     rNN attributions in section titles and body text replaced with
     phrases such as "in an earlier revision" or "before the fix".
   - **Log-output examples and ScriptVersion format examples
     placeholderised**: literal `npu-2026.05.17-r9` → `npu-<yyyy.MM.dd>-r<NN>`
     etc., preventing future drift.
   - One `> **Historical note**` block in SPEC.md §A.5 (referring to
     pre-fix encoding-enforcement state) was removed in full.
   - Approximately 102 individual rNN references across the four
     documents were touched; no PowerShell script bodies were
     modified; `$Script:ScriptVersion` / `$Script:ScriptTag` are
     unchanged; `psa.py` 3.3.0 baseline of 0 / 0 / 0 across all four
     scripts remains intact.

### Verified

The current baseline against `psa.py` 3.3.0 with this updated config:

| Script | Standard rules | + PSAP0003 / PSAP0004 |
|--------|----------------|----------------------|
| `Deploy-AMDChipsetDriverOnWindowsServer.ps1` (r61) | 0 / 0 / 0 | 0 / 0 / 0 |
| `Deploy-AMDGraphicsDriverOnWindowsServer.ps1` (r29) | 0 / 0 / 0 | 0 / 0 / 0 |
| `Deploy-AMDNpuDriverOnWindowsServer.ps1` (r12) | 0 / 0 / 0 | 0 / 0 / 0 |
| `Deploy-MSBthPanInboxOnWindowsServer.ps1` (r11) | 0 / 0 / 0 | 0 / 0 / 0 |

The four scripts are now at **r61** / **r29** / **r12** / **r11** revisions.

## [2026-05-18] — Chipset r60 / Graphics r28 / NPU r10 / BthPan r10

**Cross-script consistency pass + psa.py 3.2.0 integration.** No new
pipeline features were added; existing functionality is preserved
end-to-end.

### Added
- New `.psa.config.json` at the repository root that opts in to the
  project-pipeline rules (`PSAP0001` phase-naming, `PSAP0002`
  script-identifier presence) and configures `PSA8001`
  (cross-file function-body drift) to ignore the script-specific
  phase functions.

### Changed
- **AMDNpu helper-function parity**. The NPU script (r9 → r10) gained
  the helper functions that had remained un-ported from the BthPan r9
  work: `Write-Detail` (4-space indented continuation rows),
  `Assert-PowerShellCompatibility` (hard-fail pre-flight separated from
  `Show-PowerShellEnvironment` display), and a hash-matched canonical
  `Show-PowerShellEnvironment` (169 lines, the same body used by
  Chipset / Graphics / MSBthPan). The previous AMDNpu-specific
  `Test-AdminPrivilege` and `Set-NetworkProtocol` are renamed to
  `Assert-Admin` and `Set-Tls12` to match the sister scripts.
- **TLS posture (NPU)**. `Set-Tls12` adopts the canonical
  Chipset / Graphics / MSBthPan body (TLS 1.2 + TLS 1.3 when available;
  **TLS 1.0 / 1.1 are intentionally excluded** per RFC 8996). The
  previous AMDNpu body that enabled `Tls10` / `Tls11` has been
  removed as a security regression.
- **AMDNpu** now ships its own NPU-specific
  `Show-DriverInstallationOrderNotice`, plus simplified
  `Get-BootSigningEnvironment` / `Show-BootSigningEnvironment` stubs
  (Secure Boot + testsigning probe only; full WDAC enumeration remains
  in the Chipset / Graphics / MSBthPan family).
- **psa.py 3.2.0 baseline**. Every PowerShell script in the repository
  now passes `psa.py --config .psa.config.json` with
  **0 errors / 0 warnings / 0 info**. This is the first release where
  the canonical static-analysis baseline is fully clean across all four
  scripts simultaneously.
- **Sister-script consistency enforcement**. `PSA8001` (new in
  psa.py 3.2.0) now actively guards **34 shared helper functions**
  across all four scripts.

### Fixed
- `psa.py` 3.2.0 false-positive fixes (silent). Earlier `PSA1001`
  (brace imbalance) and `PSA2001` (undefined-variable) false positives
  in Chipset / Graphics were psa.py tokenizer bugs around PowerShell's
  `""` (double-quote-doubling) escape and `` `` `` (double-backtick)
  escape, plus mis-handling of `$Script:` scope qualifiers as
  references. Fixed in psa.py 3.2.0; no script-side change required.

---

## [2026-05-17] — Chipset r59 / Graphics r27 / NPU r9 / BthPan r9

**Debug Trace Facility + call-site instrumentation.** The four scripts
share a synchronised release. Each crossed an independent revision
counter, but the substantive changes are the same Debug-Trace-and-resume
bundle, lifted from BthPan's r2-through-r9 work and then ported into
each sister script.

### Added
- **Debug Trace Facility (SECTION 1b, ~882 lines per script)**.
  A reusable diagnostic helper with 14 functions
  (`Start-DebugTrace` / `Set-DebugStep` / `Stop-DebugTrace` /
  `Format-DebugFailure` / `Write-DebugFailureReport` /
  file-output / auto-export-on-failure / JSON snapshot). When a phase
  fails, you get a JSONL stream plus a self-contained snapshot JSON
  under `<WorkRoot>\logs\` showing the exact step that failed.
- **Call-site `Set-DebugStep` checkpoints** placed across every
  P/V/I phase function (~92 calls in Chipset / Graphics, 44 in NPU
  due to its smaller phase bodies, 113 in BthPan).
- **`-ExportTraceOnExit` switch** on the top-level param block of
  every script; writes a final JSON snapshot to `<WorkRoot>\logs\` at
  script exit regardless of success/failure.
- **`Resume-CtxFromWorkspace` rehydration helper**. Lets
  `-Action Verify` / `-Action Install -OnlyPhases ...` run against an
  existing populated workspace without first re-running P02-P09.
- **SECTION 0.25** — `-LogFile` auto-relocation under
  `<WorkRoot>\logs\` when the user provides a path outside the
  workspace, with transcript-verified activation.

### Fixed
- **PS 5.1 ja-JP `Split-Path -LiteralPath` AmbiguousParameterSet bug**.
  Every site uses `[System.IO.Path]::GetDirectoryName()` instead.
- **SECTION 1d numbering conflict** in Chipset / Graphics resolved by
  promoting WDAC → 1e and validators → 1f (Secure Boot baseline stays
  as 1d).
- **`logTag` switch-Wildcard unified**; `amd-` prefix stripped in log
  filename hints for cross-script naming consistency.

---

## [Earlier releases — per script]

The entries below track per-script revision history before the
synchronised 2026-05-17 release. Cross-script alignment commits
(where Chipset, Graphics, and NPU/BthPan crossed revisions together)
are marked **[cross-script]**.

### Deploy-AMDChipsetDriverOnWindowsServer.ps1

#### r58 — Workspace relocation **[cross-script: Graphics r26 / NPU r8 / BthPan r2]**
- Relocated workspace from `C:\AMD-Chipset-WS\` to
  `C:\Temp\Workspace_AMD-Chipset\`. The script auto-creates
  `C:\Temp\` on demand.

#### r57 / Graphics r25 / NPU r7 — CiTool non-interactive + UTF-8 console **[cross-script]**
- **Fixed**: `CiTool.exe --update-policy` blocks on
  `Press Enter to Exit` (60-75s wait). Added `--json` flag for
  non-interactive mode (Microsoft's documented behaviour). See
  [SPEC §D.16](./SPEC.md#d16-chipset-r59--graphics-r27--npu-r9--citoolexe-interactive-enter-prompt--console-utf-8-enforcement).
- **Fixed**: ja-JP console mojibake of CiTool UTF-8 output. P00 now
  calls `Set-ConsoleUtf8` which forces `[Console]::OutputEncoding`,
  `[Console]::InputEncoding`, and `$OutputEncoding` to UTF-8.
- **Fixed**: pnputil exit=259 misclassified as `failed`. New
  `no-op (already present)` status surfaced via `Write-Skip [~]`. See
  [SPEC §D.17](./SPEC.md#d17-chipset-r57--graphics-r25--pnputil-exit259-reclassification).
- **Migrated**: I02 bare `Write-Host '    Activation method: ...'`
  to `Write-Detail` for SPEC §A.5 compliance.

#### r56 / Graphics r24 — Driver-category priority override (BREAKING) **[cross-script]**
- **BREAKING**: At install-decision layer the script now ranks
  `[C] Self-signed` outranks `[B]/[A]` in certain device-category
  scenarios. See [SPEC §D.15](./SPEC.md#d15-chipset-r56--graphics-r24--driver-category-priority-override-breaking--write-detail-helper)
  for the full motivation and operator guidance.
- **Added**: `Write-Detail` helper for SPEC A.5 compliance.

#### r55 / Graphics r23 — Workspace lock + log directory fixes **[cross-script]**
- **Fixed**: Workspace lock leaked across runs in the same PowerShell
  console (the lock cleanup relied on `Register-EngineEvent PowerShell.Exiting`
  which never fires inside an interactive console). Fixed by
  (a) self-PID detection in `Test-WorkspaceLockHeld` and
  (b) wrapping the main phase loop in
  `try { ... } finally { Clear-WorkspaceLock ... }`. See
  [SPEC §D.13](./SPEC.md#d13-chipset-r55--graphics-r23--workspace-lock-leaked-across-runs-in-the-same-powershell-console).
- **Fixed (Chipset only)**: r54's `Expand-AmdInstaller_ViaInstallShield`
  dropped `installshield-admin.log` and 12 per-sub-MSI
  `msiexec-admin-*.log` files at the workspace root. Added optional
  `-LogDir` parameter. See
  [SPEC §D.14](./SPEC.md#d14-chipset-r55--per-tool-installer-logs-leaked-to-workspace-root).

#### r54 — AMD Chipset Software 8.x extraction
- **Added**: Two-layer installer architecture support for AMD Chipset
  Software 8.x (8.02.18.557 and later). The installer wraps an
  InstallShield SFX inside an NSIS shell that 7-Zip alone cannot fully
  unpack; r54 adds a dedicated `InstallShield /a + recursive msiexec /a`
  strategy. See
  [SPEC §D.12](./SPEC.md#d12-chipset-r54--installshield-sfx-extraction-for-amd-8x-installers).
- **Added**: Per-OS-variant INF coverage diagnostic
  (`W11x64\` for WS2025/2022; `WTx64\` for WS2019/2016).

#### r52 — Robocopy migration
- **Fixed**: PowerShell `Copy-Item` wildcard quirk in patched-INF
  staging. Replaced with `robocopy` for reliability.

#### r51 — WDAC XML FileRulesRef stripping
- **Fixed**: WDAC supplemental policy XML retained an empty
  `<FileRulesRef>` container after `New-CIPolicy` produced no file
  rules. Now strip the entire `<FileRulesRef>` container.

#### r50 / Graphics r19 / NPU r5 — UEFI Secure Boot baseline polish **[cross-script]**
- **Removed**: `%TEMP%` fallback from P00.
- **Added**: `Get-OrEnsureSecureBootBaseline` helper that re-captures
  when the cached snapshot's diagnostic file is missing.

#### r49 / Graphics r18 / NPU r4 — UEFI Secure Boot baseline (initial) **[cross-script]**
- **Added**: 6 core functions byte-identical across the three scripts
  plus a per-script `Get-OrEnsureSecureBootBaseline` helper and
  5 integration points (P00, P05, V05, V06, I02). See
  [SPEC §A.14](./SPEC.md#a14-uefi-secure-boot-baseline-cross-script-feature)
  and [SPEC §D.9](./SPEC.md#d9-uefi-secure-boot-baseline-feature-chipset-r49r50--graphics-r18r19--npu-r4r5).
- **Three corrective fixes applied during validation**:
  (a) `schtasks.exe /Query /FO CSV` ja-JP-localized headers replaced
  with `Get-ScheduledTask`. (b) MS sample script's `-OutputPath`
  validator regex rejects absolute Windows paths — added stdout-JSON
  fallback. (c) `Show-...` and V06 caller printed duplicate banners —
  removed inner banner.

#### r48 / Graphics r17 / NPU r3 — WDAC + cert standardisation **[cross-script]**
- **Changed**: Code-signing certificate filename standardised to
  `cert\AMD-{Chipset|Graphics|NPU}-Driver-CodeSign.{pfx,cer}`. See
  [SPEC §D.7](./SPEC.md#d7-code-signing-certificate-filename-standardization-chipset-r48--graphics-r17--npu-r3).
- **Changed**: WDAC supplemental policy `PolicyID` standardised to
  per-script fixed GUIDs (previously generated dynamically).
- **Fixed (Graphics only)**: `SupplementsBasePolicyID` corrected from
  non-standard `{B355481F-...}` to Microsoft's
  `{A244370E-44C9-4C06-B551-F6016E563076}`. See
  [SPEC §D.8](./SPEC.md#d8-wdac-supplemental-policy-guid-standardisation-chipset-r48--graphics-r17--npu-pre-existing).

#### r46 — DriverDate timezone fix
- **Fixed**: V05 dry-run plan reported `[UPGRADE]` action on identical
  drivers due to UTC midnight `DriverDate` converted to local time.
  Now compares `.Date` truncation only. See
  [SPEC §D.1](./SPEC.md#d1-chipset-r46--timezone-induced-driverdate-false-positives).
- **Changed**: P05 / P00 compatibility check now shows actual
  `Caption` plus mapped profile side by side.

#### r43 / Graphics r11 — INF Mfg parser sync **[cross-script]**
- **Fixed**: LHS character class in Mfg-section regex differed between
  chipset and graphics parsers; brought into sync.

#### r42 / Graphics r9-r10 — Multi-mfg INF collection **[cross-script]**
- **Fixed**: Collect ALL `[Manufacturer]` sections from a multi-mfg
  INF, not just the first. Diagnostic fields `ManufacturerEntries`
  and `ModelsSectionsScanned` exposed in the INF inventory.

#### r37 — Filter classification refinement
- **Changed**: `MFG_ONLY` bucket boundary refined to include drivers
  with explicit hardware-ID entries even when no Models section
  resolves.

#### r35 — Provider-trust BUGFIX
- **Fixed**: Function previously trusted `Signer` field for "AMD
  hardware running on a Microsoft generic driver" classification.
  Now trusts `Provider` field instead.
- **Added**: `mshdc.inf` to the generic IDE/AHCI host controller
  exclusion list.

#### r34 — Slash-separated header form
- **Changed**: Output header switched to slash-separated form per user
  request.

#### r33 — AMD hardware detection wording
- **Changed**: User-facing description refined to
  `"AMD hardware running on a Microsoft generic driver"`.

#### r32 — Version-aware skip + KEPT_CURRENT disposition
- **Added**: `KEPT_CURRENT` disposition for cases where the patched
  driver would be older than the installed driver. Version-aware
  skip preserves current driver intact.

#### r31 — HWID wildcard scoping
- **Fixed**: HWID lookup wildcard `$baseName.*` could match unrelated
  files. Tightened to literal HWID-string match.

#### r30 — Parameter rename + alias map
- **Changed**: `-EnableTestSigning` renamed to
  `-AuthorizeDriverSigning` (the previous name implied
  `bcdedit /set testsigning on` which is no longer the default
  posture on Windows Server 2022+; the actual posture is WDAC
  supplemental policy).
- **Added**: Alias map so older callers don't break.

### Deploy-AMDGraphicsDriverOnWindowsServer.ps1

Graphics-specific revisions (cross-script entries above also apply):

#### r16 / r47 (Graphics-only) — V05 dedup + version-comparison messaging
- **Fixed**: V05 "would upgrade 1067/1067 matched device(s)" inflation.
  `$matchedDevices` was being appended per INF HWID variant rather
  than per physical device. Fixed by deduplication on physical
  DeviceID.
- **Fixed**: Same-version, newer-date upgrade case formerly produced
  the nonsensical `patched newer (X) than current (X)` message. Now
  displays `patched same version (X) but newer date; PnP ranking
  prefers newer-dated driver`.

#### r14 → r16 — early validation iterations
- Early validation runs on ThinkPad X13 Gen 1 AMD (Win11 24H2 used
  as WS2025 preview).

### Deploy-AMDNpuDriverOnWindowsServer.ps1

#### r8 — Workspace relocation **[cross-script with Chipset r58]**
- Relocated workspace from `C:\AMD-NPU-WS\` to
  `C:\Temp\Workspace_AMD-NPU\`.

#### r5 — Find-Inf2CatPath + NpuOverride fixes
- **Fixed**: `Find-Inf2CatPath` delegated to `Find-ToolPath` which
  filters to `\x64\` or `\amd64\` directories. `inf2cat.exe` ships
  **exclusively as an x86 binary** under the Windows SDK/WDK tree.
  Replaced helper body with x86-aware tree walk. See
  [SPEC §D.10](./SPEC.md#d10-npu-r5--find-inf2catpath-x64-filter-bug).
- **Fixed**: `[ValidateSet]` on `-NpuOverride` rejected the default
  empty string, emitting a noisy warning. Added `''` to the set. See
  [SPEC §D.11](./SPEC.md#d11-npu-r5--npuoverride-validateset-excludes-empty-string).

#### r2 — Sister-script alignment refactor
- **Changed**: Renamed `Show-PhaseHeader` to `Write-PhaseHeader`,
  adopted Magenta `=`×72 + script-tag DarkGray line. Now identical
  across all three scripts. See
  [SPEC §D.3](./SPEC.md#d3-npu-r2--show-phaseheader-vs-write-phaseheader-naming-drift).
- **Changed**: `-Action Install` semantics corrected to Inst-phases
  only; added `-Action All` for the full pipeline. Workstation OS
  guard fires on both `Install` and `All`. See
  [SPEC §D.4](./SPEC.md#d4-npu--action-install-semantic-drift).

#### r1 — Initial NPU script
- **Added**: NPU (Ryzen AI XDNA) driver pipeline (PHX/HPT/STX/KRK
  platforms). Source: AMD Ryzen AI Software ZIP, ~250 MB,
  EULA-gated download. Kernel-mode driver only — does NOT install
  Ryzen AI Software user-mode stack.
- **Known issue carried forward**: Hypothetical filename
  `NPU_RAI1.7.1_380_WHQL.zip` mapping to RAI 1.7.1 was incorrect.
  Fixed in later revisions. See
  [SPEC §D.2](./SPEC.md#d2-npu-r1--hypothetical-filename-npu_rai171_380_whqlzip).

### Deploy-MSBthPanInboxOnWindowsServer.ps1

#### r9 — cosmetic logTag / log-filename fix
- **Fixed**: P00 Workstation-preview "RECOMMENDED USAGE" hint printed
  log filename suggestions of the form
  `C:\Temp\amd-<tag>-Win11-preview.log`. Replaced the binary
  graphics/chipset selector with a `switch -Wildcard` covering
  graphics-* / chipset-* / npu-* / msbthpan-* / default, and removed
  the `amd-` prefix.

#### r8 — validation-completed release
- **Added**: Debug Trace Facility (frame/step model with
  `Start-DebugTrace` / `Set-DebugStep` / `Stop-DebugTrace`,
  JSONL streaming, auto-export on phase failure, `-ExportTraceOnExit`
  final snapshot). This work was later ported into the AMD sister
  scripts in the 2026-05-17 release.
- **Added**: P01 `Resume-CtxFromWorkspace` rehydration helper.
- **Added**: SECTION 0.25 `-LogFile` auto-relocation guard.
- **Fixed**: 7 `$Ctx` properties pre-declared at object creation
  so PowerShell strict-mode property assignment does not raise
  "property does not exist".
- **Fixed**: PS 5.1 `Split-Path -LiteralPath -Parent`
  AmbiguousParameterSet workaround using
  `[System.IO.Path]::GetDirectoryName()`.
- **Fixed**: Ghost-call sweep — I-phase function calls systematically
  cross-checked against function param blocks. Fixed I00
  `Show-BootSigningEnvironment -Ctx → -BootEnv`, I01
  `Test-CertAlreadyTrusted -Thumbprint → -Ctx`, I03
  `Set-PendingRebootMarker -Phase → -Source`.

#### r7 — validation-first build
- **Added**: `InfVerif` integration + `Provider` rewrite (F1) +
  `CatalogFile` injection (F2) + `makecat` fallback (F3) for inbox
  driver re-cataloging.
- **Fixed**: PS 5.1 ja-JP build 26100.32860 `ArgumentException` for
  `@(List[object])` hashtable cast via `.ToArray()`.
- **Changed**: `-Mode` `[ValidateSet]` empty-string removed; not a
  documented InfVerif behaviour.

#### r6 — unblocked P00-P07
- **Fixed**: P00 through P07 unblocked; revealed `inf2cat`
  signability test conflicts (22.9.4 / 22.9.8), addressed in r7
  by `makecat` fallback.

#### r2-r5 — initial debug iterations
- **Fixed**: P03 driver discovery on `bthpan.inf_amd64_*` directory.
- **Fixed**: `$Ctx` property bugs during initial bring-up.
- **Fixed**: `Format-Elapsed` return type.
- **Fixed**: Transcript bind ordering.

#### r1 — Initial BthPan script
- **Added**: Microsoft inbox Bluetooth PAN driver (`bthpan.inf` /
  `bthpan.sys`) enablement pipeline. Source: the host's own
  `C:\Windows\System32\DriverStore\FileRepository\bthpan.inf_amd64_*`
  directory — no remote download required. Single INF, single HWID
  (`BTH\MS_BTHPAN`). Distinguishes Phantom OK (bth.inf proxy match)
  from true resolution (Class=Net, Service=BthPan) on Windows Server.

### Deploy-WdacSinglePolicyFormatOnLegacyWindowsServer.ps1

#### r04 — `Add-HistoryEntry` scope-qualified parameter fix
- **Fixed**: `param()` block declared `[string]$Script:CertThumbprint = ''`,
  which PowerShell silently accepts and turns into a literally-named
  parameter `Script:CertThumbprint` (colon included), so callers
  passing `-CertThumbprint` fail at the binding stage immediately
  after WMI activation and just before `manifest.json` write.
  Removed the `$Script:` scope qualifier from the parameter and
  updated the function body to use the parameter-local
  `$CertThumbprint`. Embedded canonical hash in all 4 driver scripts
  refreshed accordingly:
  `0df3c8889fe80769ade52e8fa7f5518af184df6413f1bfd9c7596e0a185c82ff`
  →
  `f779bf50c41201a6564bf968d040cf39348433951cb83accd856245bebef7ced`.
  See SPEC §D.25 Status r04 for full root cause / fix detail.

#### r03 — Full rebuild from Chipset r66 baseline
- **Changed**: r01/r02 were ground-up rewrites and silently violated
  the sister-script discipline. r03 seeds the orchestrator by
  copying `Deploy-AMDChipsetDriverOnWindowsServer.ps1` (r66 baseline)
  verbatim, removes phase functions and AMD-specific helpers, keeps
  the 34 shared helpers byte-for-byte, and adds orchestrator-specific
  sections (SPF policy build, manifest schema, state model, 9 action
  handlers). PSA8001 cross-file drift = 0 across all 5 scripts.
  Embedded canonical hash in all 4 driver scripts updated from
  `d13b6a8b...` (r02) to
  `0df3c8889fe80769ade52e8fa7f5518af184df6413f1bfd9c7596e0a185c82ff`
  (r03).

#### r02 — Windows PowerShell 5.1 parameter-binding compatibility fix
- **Fixed**: r01 used `Get-Date -AsUTC` (PS 7.1+ only) and
  `Set-Content -AsByteStream` (PS 6+ only); both caused parameter
  binding errors on the PS 5.1 that ships with WS2019/WS2016.
  Replaced with `(Get-Date).ToUniversalTime().ToString(...)` and
  byte-array `[System.IO.File]::WriteAllBytes(...)` respectively.
  Embedded canonical hash in all 4 driver scripts updated from
  `e7489216...` (r01) to `d13b6a8b...` (r02).

#### r01 — Initial WDAC SPF orchestrator
- **Added**: External orchestrator for WS2019 / WS2016 WDAC Single
  Policy Format (SPF) policy build / deploy / manage. Eight Actions
  (`GetStatus` / `AddCert` / `RemoveCert` / `Verify` / `Uninstall` /
  `Repair` / `ComputeCanonicalHash` / `ComputeOwnCanonicalHash`)
  plus `Help`. JSON output envelope, granular exit codes (0/1/2/3/4),
  project-reserved Policy GUID
  `{DDF8C2DA-A1B2-4D52-B551-446570577053}`, per-host state under
  `%ProgramData%\Deploy-Drivers-For-WindowsServer\wdac\`, atomic
  manifest writes via temp + `Move-Item`, six-state model
  (`None` / `Ours-Healthy` / `Ours-Stale` / `Ours-Tampered` /
  `Foreign` / `Inconsistent`), foreign-policy backup and restore.

---

## Cross-script consistency releases

The four scripts have crossed revision counters together during these
synchronised releases:

| Date | Chipset | Graphics | NPU | BthPan | Theme |
|---|---|---|---|---|---|
| 2026-05-18 | r60 | r28 | r10 | r10 | Cross-script consistency pass + psa.py 3.2.0 integration |
| 2026-05-17 | r59 | r27 | r9  | r9  | Debug Trace Facility + call-site instrumentation |
| (Earlier) | r58 | r26 | r8 | r2 | Workspace relocation under `C:\Temp\Workspace_*` |
| (Earlier) | r57 | r25 | r7 | —  | CiTool `--json` + Console UTF-8 enforcement |
| (Earlier) | r56 | r24 | —  | —  | Driver-category priority override (BREAKING) |
| (Earlier) | r55 | r23 | —  | —  | Workspace lock + log directory fixes |
| (Earlier) | r50 | r19 | r5 | —  | UEFI Secure Boot baseline polish |
| (Earlier) | r49 | r18 | r4 | —  | UEFI Secure Boot baseline (initial) |
| (Earlier) | r48 | r17 | r3 | —  | WDAC supplemental policy GUID + cert filename standardisation |
| (Earlier) | r43 | r11 | —  | —  | INF Mfg parser sync |
| (Earlier) | r42 | r9-r10 | — | — | Multi-mfg INF collection |

---

## Discovered bugs and fix history (validation-discovered)

These bugs were found in physical-hardware validation runs and tracked
back to specific revisions. Validation environments include
ThinkCentre M75q Tiny Gen 2 (WS2025) and ThinkPad X13 Gen 1 AMD
(Win11 LTSC 2024).

| Discovery environment | Found-in | Fixed-in | Summary |
|---|---|---|---|
| WS2019 + Renoir + Secure Boot ON (2026-05-23, **bench bricked**) | Chipset r67 / Graphics r33 / BthPan r15 (running with WDAC SPF orchestrator r04) | Chipset r68 / Graphics r34 / BthPan r16 (bug fixes only; architectural improvements deferred to r69/r35/r17) | Catastrophic boot failure after `Chipset Install` → `Graphics Install` → `MSBthPan Install` run back-to-back with no reboot between scripts; host non-bootable in all modes including Safe Mode and WinRE. Surfaced four script-level bugs: (A1) `Update-BootSigningEnvironmentForCtx` is not SPF-aware so I04 falsely reports BLOCKED on SPF-active hosts; (A2) I04 LOADED disposition disagrees with the functional probe because it doesn't consult `Get-PnpDevice.ConfigManagerErrorCode`; (A3) BthPan I05 Attempt 3 fails with PowerShell's "RedirectStandardOutput and RedirectStandardError are the same" validator error because both redirect to `'NUL'`; (A4) BthPan I05 Attempt 4 surfaces only a recursively-self-referencing service-start error, hiding the real Win32 code. The system-bricked outcome itself is attributed to cumulative kernel-mode driver replacement under Secure Boot enforcement and is NOT fixable in driver-script-level changes — the prescriptive response is the README sequencing rewrite, the brick-level disclaimer callout, and the SPEC §D.26 quality programme that lists ten architectural improvements scoped for r69/r35/r17. See SPEC §D.26 (full incident narrative + root-cause hypothesis), TESTING §12 (case study). |
| ThinkPad X13 Gen 1 (WS2019 + Renoir + Secure Boot ON, 2026-05-23) | WDAC SPF orchestrator r03 | WDAC SPF orchestrator r04 | `Add-HistoryEntry` `param()` block declared `[string]$Script:CertThumbprint = ''` — a scope-qualified parameter name that PowerShell's parser silently accepts as a literally-named parameter `Script:CertThumbprint` (colon included). All callers passing `-CertThumbprint $thumb` fail at the binding stage with "A parameter cannot be found that matches parameter name 'CertThumbprint'". The failure occurs **after** `SiPolicy.p7b` deployment and **after** the WMI `PS_UpdateAndCompareCIPolicy.Update()` activation, but **before** `manifest.json` is written, so each subsequent invocation finds the host in a "stuck Foreign" state. PSScriptAnalyzer's stock rules do not flag this construct. See SPEC §D.25 Status r04 and the new "Recommendation: scope-qualified parameter declarations in `param()` blocks" subsection. |
| ThinkPad X13 Gen 1 (Win11 24H2) | Chipset r45 | r46 | Timezone bug in `Compare-InfDriverVer` (UTC midnight `DriverDate` converted to local 09:00, causing same-version to report as "current newer than patched"). See SPEC §D.1. |
| ThinkPad X13 Gen 1 (Win11 24H2) | Chipset r45 / Graphics r14 | r46 / r15 | P05 / P00 displayed `Host OS: Windows Server 2025` even on Workstation hosts. Now shows actual `Caption` plus mapped profile side by side. |
| ThinkPad X13 Gen 1 (Win11 24H2) | Graphics r14 | r16 / r47 | V05 "would upgrade 1067/1067 matched device(s)" inflation. Fixed by deduplication on physical DeviceID. |
| ThinkPad X13 Gen 1 (Win11 24H2) | Graphics r14 | r16 / r47 | Same-version, newer-date upgrade case formerly produced `patched newer (X) than current (X)`. Now displays meaningful diagnostic. |
| Lab (WS2025, ja-JP) | Chipset r49 | r49 polish, r50 | Three corrections during initial Secure Boot baseline rollout: ja-JP-localized `schtasks.exe /FO CSV` headers, MS sample script absolute-path validator rejection, duplicate banner. |
| Lab (WS2025, ja-JP) | Chipset r49 / Graphics r18 / NPU r4 | r50 / r19 / r5 | Polish patch: P00 wrote diagnostic files to `%TEMP%` when the workspace had not been created yet. Replaced with workspace-co-located diagnostics. |
| Lab (WS2025, ja-JP) | NPU r4 | r5 | `Find-Inf2CatPath` filtered to `\x64\` / `\amd64\` directories, but inf2cat.exe is x86-only. P02 always failed. See SPEC §D.10. |
| Lab (WS2025, ja-JP) | NPU r4 | r5 | `[ValidateSet]` on `-NpuOverride` rejected the default empty string. See SPEC §D.11. |
| Clean WS2025 install (interactive console) | Chipset r54 / Graphics r19-r22 | Chipset r55 / Graphics r23 | Workspace lock leaked across runs in the same PowerShell host. See SPEC §D.13. |
| Clean WS2025 install | Chipset r54 | r55 | r54's `Expand-AmdInstaller_ViaInstallShield` dropped `installshield-admin.log` and 12 per-sub-MSI `msiexec-admin-*.log` files at the workspace root. See SPEC §D.14. |

---

## Conventions

- **Revision bump triggers** (per `SPEC.md` A.13 *Revision discipline*):
  changes to phase semantics, output format, or parameter set.
  Cosmetic-only changes (typo fixes, README rewording) do not require
  a bump.
- **Cross-script consistency requirement**: 34 shared helper functions
  must remain byte-identical across all four scripts. Enforced by
  `psa.py` PSA8001 (cross-file function-body drift detection).
- **Where to put what**:
  - **CHANGELOG.md** (this file) — chronological per-release entries
    ("when" and "what").
  - **SPEC.md Part D** — architectural rationale for individual fixes
    ("why" — root cause, fix design, scope, upgrade impact).
  - **PowerShell script comments** — current behaviour and current
    rationale only. Revision tags (`# r##:`, `# r##+: ...`,
    `REVISION HISTORY` blocks, etc.) belong in CHANGELOG.md, not in
    the script body. `PSAP0003` and `PSAP0004` enforce this in CI.
- **Where the historical record lives**: every concrete patch listed
  here can be retrieved from the Git commit history via
  `git log --grep='rNN' --follow <script>.ps1`. This CHANGELOG is the
  human-readable summary; Git is the authoritative byte-level record.
