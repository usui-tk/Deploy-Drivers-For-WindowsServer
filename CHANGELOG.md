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

## [Unreleased]

## [Chipset r67 / Graphics r33 / NPU r16 / BthPan r15 / WDAC SPF r01] — 2026-05-22

### Added

- **NEW SCRIPT: `Deploy-WdacSinglePolicyFormatOnLegacyWindowsServer.ps1`**
  (1,898 lines). An external orchestrator that builds, deploys, and
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
  external orchestrator (Path C). The orchestrator is located either
  locally (next to the driver script) or fetched from the GitHub
  `main` branch (`raw.githubusercontent.com/usui-tk/Deploy-Drivers-For-WindowsServer/main/`).
  In both cases the orchestrator's canonical SHA256 is verified
  against the constant embedded in each driver script
  (`$Script:ExpectedWdacScriptCanonicalSha256 =
  'e7489216db0e1dd8fb03e337e802145165305b1327149079b65c70011075f4a2'`).

### Changed

- **Chipset r66 → r67** — version tag changes from
  `phantom-file-reference-skip-cleanup` to
  `legacy-ws2019-wdac-spf-integration`. Integration block added (~300
  lines) before `Invoke-InstPhase02_AuthorizeDriverSigning`, providing
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
