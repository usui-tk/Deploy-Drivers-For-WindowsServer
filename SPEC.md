# Developer Specification (SPEC)

> **Purpose of this document**
>
> This file is the authoritative specification for building and extending the
> four PowerShell scripts in this repository
> (`Deploy-AMDChipsetDriverOnWindowsServer.ps1`,
> `Deploy-AMDGraphicsDriverOnWindowsServer.ps1`,
> `Deploy-AMDNpuDriverOnWindowsServer.ps1`, and
> `Deploy-MSBthPanInboxOnWindowsServer.ps1`). It is written to be picked up
> directly by a human contributor or an LLM (Claude) at the start of a new
> feature or sister-script project so that conventions do not have to be
> re-derived from scratch.
>
> **The single most important rule**: when a piece of behavior is described
> in **Part A (Common Spec)**, any new feature or sister script MUST reuse
> the existing implementation referenced there. Do not re-design phase
> headers, log markers, environment diagnostics, error JSONL formats, or the
> `psa.py` static analyzer. These have been hardened through many revisions
> and reflect real-world bug fixes; rewriting them invites regressions.
>
> Use **Part B** as the per-script reference for the unique platform
> detection, INF inventory filter, installer source resolution tier, and
> known platform quirks of each of the four scripts. **Part C** documents
> the quality gates (`psa.py`, `TESTING.md`) that any change must pass.
> **Part D** preserves the historical lessons that the current
> implementation already accounts for.

> **Documentation language policy**: This SPEC is maintained in English
> only. Japanese readers should refer to the English SPEC together with
> the Japanese `README.ja.md` for an orientation. See
> `README.md` "Documentation language policy" for the repository-wide
> bilingual policy.

---

## Table of Contents

- [Part A — Common Specification (reusable across all scripts)](#part-a--common-specification-reusable-across-all-scripts)
  - [A.1 Reference Assets](#a1-reference-assets)
  - [A.2 Source File Format](#a2-source-file-format)
  - [A.3 Banner & Version Identification](#a3-banner--version-identification)
  - [A.4 Phase Architecture (21 phases)](#a4-phase-architecture-21-phases)
  - [A.5 Logging Conventions](#a5-logging-conventions)
  - [A.6 Parameter Conventions](#a6-parameter-conventions)
  - [A.7 Path Handling Rules](#a7-path-handling-rules)
  - [A.8 Error & Diagnostic Conventions](#a8-error--diagnostic-conventions)
  - [A.9 CSV Column Conventions](#a9-csv-column-conventions)
  - [A.10 Environment Evaluation (Phase P00)](#a10-environment-evaluation-phase-p00)
  - [A.11 Static Analysis with psa.py](#a11-static-analysis-with-psapy)
  - [A.12 Documentation Language Policy](#a12-documentation-language-policy)
  - [A.13 Development Workflow](#a13-development-workflow)
  - [A.14 UEFI Secure Boot Baseline (cross-script feature)](#a14-uefi-secure-boot-baseline-cross-script-feature)
- [Part B — Script-specific Specifications](#part-b--script-specific-specifications)
  - [B.1 Chipset script (`Deploy-AMDChipsetDriverOnWindowsServer.ps1`)](#b1-chipset-script-deploy-amdchipsetdriveronwindowsserverps1)
  - [B.2 Graphics script (`Deploy-AMDGraphicsDriverOnWindowsServer.ps1`)](#b2-graphics-script-deploy-amdgraphicsdriveronwindowsserverps1)
  - [B.3 NPU script (`Deploy-AMDNpuDriverOnWindowsServer.ps1`)](#b3-npu-script-deploy-amdnpudriveronwindowsserverps1)
  - [B.4 BthPan script (`Deploy-MSBthPanInboxOnWindowsServer.ps1`)](#b4-bthpan-script-deploy-msbthpaninboxonwindowsserverps1)
- [Part C — Quality Gates & Validation Checklist](#part-c--quality-gates--validation-checklist)
- [Part D — Known Pitfalls & Lessons Learned](#part-d--known-pitfalls--lessons-learned)

---

# Part A — Common Specification (reusable across all scripts)

## A.1 Reference Assets

These are the canonical sources of truth. **Pull from these directly; do not re-implement.**

### A.1.1 Reference scripts (phase / banner / log patterns)

```
Deploy-AMDChipsetDriverOnWindowsServer.ps1   (the most mature implementation)
Deploy-AMDGraphicsDriverOnWindowsServer.ps1  (graphics-specific platform detection)
Deploy-AMDNpuDriverOnWindowsServer.ps1       (NPU script with 4-tier installer resolution)
Deploy-MSBthPanInboxOnWindowsServer.ps1      (Microsoft inbox Bluetooth PAN driver enablement)
```

These 21-phase deployment scripts are the canonical source for:

- `Write-PhaseHeader` / `Write-PhaseFooter` / `Format-Elapsed`
- `Write-Step` / `Write-Ok` / `Write-Warn2` / `Write-Fail` / `Write-Skip`
- `Write-Detail` (continuation-line helper; see §A.5)
- `Write-SubHeader` / `Write-SubHeader2` (Level-1 / Level-2 in-phase banners)
- Banner block layout (Magenta `=` × 72, script-tag line, phase entry / exit)
- `Show-PowerShellEnvironment` (P00 environment dump)
- `Show-OperatingSystemDetail` (OS profile / build / inf2cat `/os:` resolution)
- `Test-AdminPrivilege` (hard-fail check on non-elevated session)
- `Set-NetworkProtocol` (TLS hardening)
- `Show-RunSummary` (per-action summary with PhaseTimings + ScriptHash)
- `Resolve-PerDeviceDriverDecision` / `Resolve-PerInfInstallDecision` (category-priority override; see §D.15)

When extending these scripts, **copy these helpers verbatim** from the most recent revision rather than re-implementing them.

### A.1.2 Static analyzer

```
psa.py  (obtained from the canonical artifact repository — see A.11)
```

`psa.py` is a **pure Python** static analyzer (no PowerShell installation required) with a **46-rule** check set spanning `PSA1001`..`PSA9002` plus the project-convention family `PSAP0001`..`PSAP0005`. The repository policy is to validate against the **latest mainline** `psa.py` from the canonical repository (see §A.11 for the rationale and workflow). It is **not** bundled in this repository. It is maintained as a single canonical artifact at:

```
https://github.com/usui-tk/ai-generated-artifacts/tree/main/scripts/python/powershell-static-analyzer/psa.py
```

It must be:

- Reused as-is (do not fork or modify locally; contribute changes to the canonical repository instead)
- Obtained via `git clone` of `ai-generated-artifacts` **or** direct download of the single file (see A.11)
- Used as the gate before every commit

See A.11 for details.

### A.1.3 Companion specifications

- `README.md` / `README.ja.md` — end-user documentation (installation, quick start, troubleshooting). Both languages maintained.
- `TESTING.md` — physical-hardware validation results (English only)
- `CHANGELOG.md` — chronological per-release change log (English only)
- `CONTRIBUTING.md` — issue / PR conventions (English only)
- `SECURITY.md` — vulnerability reporting (English only)
- `CODE_OF_CONDUCT.md` — community behaviour (English only)

### A.1.4 Workspace path convention

Each script writes to a dedicated workspace path under `C:\Temp\Workspace_<vendor>-<short>\` to guarantee non-collision between scripts. All four workspaces are located under `C:\Temp\Workspace_*` (the script auto-creates `C:\Temp` on demand):

| Script    | Default workspace path                     | Pre-relocation path (deprecated) |
| --------- | ------------------------------------------ | -------------------------------- |
| Chipset   | `C:\Temp\Workspace_AMD-Chipset`            | `C:\AMD-Chipset-WS`              |
| Graphics  | `C:\Temp\Workspace_AMD-Graphics`           | `C:\AMD-Graphics-WS`             |
| NPU       | `C:\Temp\Workspace_AMD-NPU`                | `C:\AMD-NPU-WS`                  |
| BthPan    | `C:\Temp\Workspace_Microsoft-BthPan`       | `C:\MSBthPan-WS`                 |

If a 5th script is added (e.g. ROCm runtime, audio coprocessor), use `C:\Temp\Workspace_<vendor>-<short>\` with the same subdirectory layout (`download\`, `extracted\`, `patched\`, `cert\`, `logs\`, `.markers\`). The `Workspace_` prefix and `<vendor>-<short>` naming scheme keep all workspaces sorted contiguously when `C:\Temp` is listed.

---

## A.2 Source File Format

| Attribute        | Value                                                                              |
| ---------------- | ---------------------------------------------------------------------------------- |
| Encoding         | UTF-8 with BOM (`utf-8-bom`)                                                       |
| Line endings     | CRLF                                                                               |
| Tab style        | 4 spaces (no actual tab characters)                                                |
| PowerShell ver   | 5.1 minimum; 7.x supported                                                         |
| Required attrs   | `#Requires -Version 5.1` and `#Requires -RunAsAdministrator` at the top of each .ps1 |
| `param()` block  | Top-of-file `param()` with `[CmdletBinding()]`; mirror to `$Script:Foo` immediately |
| Static gate      | `psa.py` (see A.11) must pass with 0 errors                                        |

### File structure (top-to-bottom)

```
1.  Header comment block (.SYNOPSIS / .DESCRIPTION / .PARAMETER / .EXAMPLE / .NOTES)
2.  #Requires directives
3.  [CmdletBinding()] + param() block
4.  Mirror params to $Script:Foo
5.  Script-scope state ($Script:ScriptVersion, $Script:ScriptTag, $Script:ScriptHash, ...)
6.  $Script:PhaseRegistry = @( [pscustomobject]@{ Id=...; Name=...; Group=...; Func=... }, ... )
7.  $Script:DetectedPlatform = @{ ... } (populated in P00/P03)
8.  $Script:PhaseResults = @{}
9.  Output helpers (Format-Elapsed, _LogLine, Write-Step/Ok/Warn2/Fail/Skip, Write-SubHeader, Write-PhaseHeader/Footer)
10. Environment helpers (Show-PowerShellEnvironment, Show-OperatingSystemDetail, Test-AdminPrivilege, Set-NetworkProtocol)
11. Phase orchestrator (Invoke-PhaseRunner, Get-PhaseListByAction, Show-PhaseList)
12. Domain helpers (script-specific: AMD platform detection, INF parser, installer resolution, etc.)
13. Phase implementations: Invoke-PrepPhase00_Initialize ... Invoke-InstPhase04_PostInstallVerification
14. Cleanup action (Invoke-Cleanup)
15. Main entry point (Invoke-MainEntryPoint)
16. Top-level try/finally dispatcher that prints Show-RunSummary regardless of exit path
```

### A.2.1 Per-file-type encoding & line-ending contract (cross-repo overview)

Each file extension has a non-negotiable contract that is enforced by `.gitattributes` at commit / checkout time. Any tooling that produces files for this repository — manual edits, IDE saves, code-generation scripts, AI-agent edits — **must** emit bytes that already conform to this contract; relying on `.gitattributes` to silently fix things at commit time is a fragile workflow (see A.2.4 below).

| Extension | Encoding | Line endings | BOM | Enforced by | Reason |
| --- | --- | --- | --- | --- | --- |
| `*.ps1`, `*.psm1`, `*.psd1` | UTF-8 | **CRLF** | **required** | `PSA7001` + `.gitattributes` (`text working-tree-encoding=UTF-8 eol=crlf`) | Windows PowerShell 5.1 on ja-JP locale falls back to Shift-JIS when BOM is absent → ja-JP string literals corrupt at parse time. CRLF is required by signtool / pnputil and by the existing tooling baseline. |
| `*.md` | UTF-8 | **LF** | **forbidden** | `.gitattributes` (`text eol=lf`) | GitHub-native rendering convention. BOM breaks some Markdown renderers and shows as `` (mojibake) at file start. |
| `*.txt`, `*.yml`, `*.yaml`, `*.json`, `*.toml` | UTF-8 | LF | forbidden | `.gitattributes` (`text eol=lf`) | Cross-platform tool convention. JSON parsers in particular reject leading BOM in strict mode. |
| `*.py` | UTF-8 | LF | forbidden | `.gitattributes` (`text eol=lf`) | PEP 8 / PEP 263 convention. Python 3 accepts UTF-8 source by default; BOM is allowed but discouraged. |
| `*.cer`, `*.pfx`, `*.cat`, `*.zip`, `*.png`, etc. | binary | n/a | n/a | `.gitattributes` (`binary` or explicit `-text`) | Git must not touch line endings on binary blobs. |

> **PSA7001** is the static-analysis rule that enforces the `.ps1` contract; see A.11 for the full rule list and how `psa.py` reports violations.

### A.2.2 Tooling rules — programmatic edits MUST preserve the contract

When emitting `.ps1` content from any program (Python script, Bash heredoc, AI-agent file generation, etc.), the **default** behaviour of most language runtimes is the wrong one — they emit LF-only without BOM. The following rules prevent the most common defects:

**Rule 1 — Python scripts that emit `.ps1` content MUST explicitly normalize to CRLF and prepend the UTF-8 BOM.**

```python
# WRONG — produces LF-only without BOM
with open('Deploy-X.ps1', 'w', encoding='utf-8') as f:
    f.write(new_content)

# WRONG — encoding='utf-8-sig' adds BOM but newlines still default to LF
# on Linux/macOS (open() in text mode does NOT translate \n to \r\n on these platforms)
with open('Deploy-X.ps1', 'w', encoding='utf-8-sig') as f:
    f.write(new_content)

# CORRECT — explicit CRLF + BOM, works identically on every platform
with open('Deploy-X.ps1', 'wb') as f:
    f.write(b'\xef\xbb\xbf')                        # UTF-8 BOM
    f.write(new_content.replace('\n', '\r\n').encode('utf-8'))

# CORRECT (alternative) — newline parameter overrides platform default
with open('Deploy-X.ps1', 'w', encoding='utf-8-sig', newline='\r\n') as f:
    # Note: with newline='\r\n', Python does NOT add CR to existing \r\n,
    # so input must contain LF only (not CRLF) — round-trip-safe
    f.write(new_content.replace('\r\n', '\n'))
```

**Rule 2 — When inserting new lines into an existing `.ps1` file, the inserted content MUST match the existing line endings.**

The hardest-to-find defect is *mixed* line endings: most of the file is CRLF (correct), but one inserted function body is LF-only (broken). PowerShell's AST parser accepts both forms silently — meaning an `AST 0 errors` result does NOT prove the file is well-formed. Insertion tools must either:

- Read the surrounding context, identify its line ending, and emit the new lines with the same terminator.
- Or normalize the entire output to CRLF after insertion.

```python
# WRONG — Python's triple-quoted string literal has LF terminators
new_function = """
function Get-NewHelper {
    Write-Host 'hi'
}
"""
patched = before + new_function + after  # mixes CRLF (before/after) with LF (new_function)

# CORRECT — convert to CRLF before inserting
new_function = """
function Get-NewHelper {
    Write-Host 'hi'
}
""".replace('\n', '\r\n')
patched = before + new_function + after  # uniform CRLF throughout
```

**Rule 3 — When using `str_replace`-style in-place edits, the new content MUST match the line ending of the surrounding file.**

Most in-place edit tools (PowerShell's `-replace`, sed, perl `-i`, and most IDE refactoring tools) preserve the *surrounding* file's line endings but use the literal bytes of the replacement string. If the replacement string was authored on a system that emits LF (a Linux IDE, a webform, a chat-app paste) and is dropped into a CRLF file, the inserted region becomes LF-only — exactly the defect Rule 2 warns about.

**Rule 4 — Heredocs in shell scripts produce LF-only output. Pipe through `unix2dos` or equivalent before writing `.ps1`.**

```bash
# WRONG
cat > Deploy-X.ps1 << 'EOF'
#Requires -Version 5.1
function Get-Foo { 'hi' }
EOF

# CORRECT
cat > Deploy-X.ps1 << 'EOF' && unix2dos Deploy-X.ps1
#Requires -Version 5.1
function Get-Foo { 'hi' }
EOF
# (or use printf with explicit \r\n)
```

**Rule 5 — `.md` files are the inverse: never emit CRLF or BOM.** Editors that auto-detect "Windows line endings" or auto-insert BOM (notably older Notepad++ configurations and some VS Code extensions) must be configured to suppress those defaults when saving Markdown.

### A.2.3 Verification commands (run before committing)

`.gitattributes` will catch most defects at commit time but only by rewriting the file — which produces a confusing diff and may indicate other problems were also silently rewritten. Run these checks before `git add` so the working tree matches the canonical form ahead of time.

**PowerShell (Windows authoring environment):**

```powershell
# CR / LF byte counts. For .ps1 files these MUST be equal (every LF preceded by CR).
$path = 'Deploy-AMDChipsetDriverOnWindowsServer.ps1'
$bytes = [System.IO.File]::ReadAllBytes($path)
$cr = ($bytes | Where-Object { $_ -eq 13 }).Count
$lf = ($bytes | Where-Object { $_ -eq 10 }).Count
Write-Host ("CR: $cr / LF: $lf / mismatch: $($lf - $cr) LF-only line(s)")

# BOM check (must be EF BB BF for .ps1)
$first3 = ($bytes[0..2] | ForEach-Object { '{0:X2}' -f $_ }) -join ' '
Write-Host ("First 3 bytes: $first3 (expected: EF BB BF)")

# PowerShell AST parse — NOT a proof of correctness for encoding, but a necessary baseline
$errors = $null
$null = [System.Management.Automation.Language.Parser]::ParseFile($path, [ref]$null, [ref]$errors)
Write-Host ("AST parse errors: $($errors.Count)")
```

**Bash / WSL (Linux authoring environment):**

```bash
file Deploy-AMDChipsetDriverOnWindowsServer.ps1
# Expected output: "UTF-8 Unicode (with BOM) text, with CRLF line terminators"

# Equality check: LF byte count must equal CR byte count for .ps1
file=Deploy-AMDChipsetDriverOnWindowsServer.ps1
cr=$(tr -cd '\r' < "$file" | wc -c)
lf=$(tr -cd '\n' < "$file" | wc -c)
echo "CR=$cr LF=$lf LF-only=$((lf-cr))"
# LF-only MUST equal 0 for the file to be PSA7001-compliant

# Cross-file check for all .ps1 files in repo
for f in Deploy-*.ps1; do
    cr=$(tr -cd '\r' < "$f" | wc -c); lf=$(tr -cd '\n' < "$f" | wc -c)
    bom=$(head -c 3 "$f" | od -An -t x1 | tr -d ' ')
    printf "%-50s CR=%6d LF=%6d delta=%5d BOM=%s\n" "$f" "$cr" "$lf" "$((lf-cr))" "$bom"
done
# Every row must show delta=0 and BOM=efbbbf
```

### A.2.4 `.gitattributes` is a safety net, not a substitute for correct emission

The repository's `.gitattributes` rule `*.ps1 text working-tree-encoding=UTF-8 eol=crlf` will normalize line endings during `git add` (commit time) and during `git checkout` (working-tree projection). This catches the LF-only-line defect *for files that go through a normal git workflow*. It does NOT save you in the following scenarios:

- **Files shared outside git** — a `.ps1` file emailed, uploaded to a ZIP, or downloaded via the GitHub Raw URL bypasses `.gitattributes` normalization. The recipient sees whatever bytes the producer emitted.
- **Files inspected via `git show <commit>:<path>`** — this returns the *blob* form (BOM + LF), not the working-tree form (BOM + CRLF). Tooling that consumes blob content directly must apply CRLF normalization itself.
- **AST / `psa.py` analysis on the working tree at the moment of authoring** — if the file is locally LF-only and you run `psa.py` before `git add`, `psa.py` will (correctly) report `PSA7001` failure. The defect is real until commit normalization, not a phantom.
- **Editor tooling that re-reads the file mid-session** — if your editor reads a CRLF file, holds it in memory as LF-only (most editors do this), and writes back as LF-only, the disk file is now LF-only until `.gitattributes` next normalizes it.

**Bottom line**: emit correct bytes at the source. Treat `.gitattributes` as a defensive check, not as the source of truth.

For the detailed war story of how this exact defect was caught in this repository, see [SPEC §D.23](#d23-mixed-line-endings-in-programmatically-emitted-ps1-content-python-script-defect).

---

## A.3 Banner & Version Identification

### Version string format

```powershell
$Script:ScriptVersion = '<short-name>-YYYY.MM.DD-rNN'
$Script:ScriptTag     = '<short-kebab-tag-describing-the-revision>'
```

Format in production:

- ScriptVersion: `<vendor>-<yyyy.MM.dd>-r<NN>`
  (where `<vendor>` is one of `chipset`, `graphics`, `npu`, `msbthpan`)
- ScriptTag:     `<vendor>-<short-kebab-tag>-r<NN>`
  (kebab-cased summary of the revision's primary change)

### Self-fingerprint via SHA256

The script must hash its own file at startup and expose the first 12 hex chars. This appears in every phase header so logs are reproducible across script versions:

```powershell
$Script:ScriptHash = '(unknown)'
try {
    $scriptPath = $PSCommandPath
    if ([string]::IsNullOrEmpty($scriptPath)) { $scriptPath = $MyInvocation.MyCommand.Path }
    if ($scriptPath -and (Test-Path -LiteralPath $scriptPath)) {
        $hashFull = (Get-FileHash -LiteralPath $scriptPath -Algorithm SHA256).Hash
        $Script:ScriptHash = $hashFull.Substring(0, 12).ToLower()
    }
} catch {
    $Script:ScriptHash = '(hash-error)'
}
$Script:ScriptShortTag = ('{0}/{1}' -f $Script:ScriptVersion, $Script:ScriptHash)
```

### Main entry banner

```
========================================================================
 <Script Display Name>
 Version: <ScriptVersion>  [<ScriptTag>]  SHA256: <ScriptHash>
 Action : <Action>
 Repo   : <RepoUrl>
========================================================================
```

Color: Cyan border, DarkCyan version / repo lines, White Action line. Width: 72 chars.

### Phase header / footer banner

Emitted by the dispatcher (`Invoke-PhaseRunner`), **never** by phase functions:

```
========================================================================
 PHASE P00 - Initialize                 (Prep  )  start: 14:23:05
 script: npu-<yyyy.MM.dd>-r<NN>/<hash12>
========================================================================
... phase body output ...
 PHASE P00 -> DONE     elapsed: 0.45s
```

Color: Magenta border + entry line, DarkGray script-tag line. Status colors: Green=DONE, Red=FAILED, DarkGray=CACHED/SKIPPED.

---

## A.4 Phase Architecture (21 phases)

All four scripts share the same 21-phase model. Adding a 5th script means populating the same 21 phase functions; do NOT change phase count or IDs without a strong reason (and a SPEC.md revision).

### Numbering rules

```
P00 - P09   Prep phases   (10 phases, may extend if absolutely required)
V01 - V06   Verify phases (6 phases)
I00 - I04   Inst phases   (5 phases)
```

### Phase registry format (mandatory)

```powershell
$Script:PhaseRegistry = @(
    [pscustomobject]@{ Id='P00'; Name='Initialize';     Group='Prep';   Func='Invoke-PrepPhase00_Initialize' }
    [pscustomobject]@{ Id='P01'; Name='PrepareWorkspace'; Group='Prep'; Func='Invoke-PrepPhase01_PrepareWorkspace' }
    # ...
)
```

- **Type**: `[pscustomobject]@{...}` (plain `@{...}` hashtable is NOT acceptable — sister-script alignment).
- **Function naming**: `Invoke-{Prep|Verify|Inst}Phase{NN}_{Name}` (underscore, group-prefix style).
- **1:1 mapping**: each registry entry must have exactly one function definition; `psa.py` (see A.11) flags mismatches.

### Phase groups (semantic)

| Group  | Meaning                                                       |
| ------ | ------------------------------------------------------------- |
| Prep   | Acquisition & preparation of artifacts. No system-state change |
| Verify | Validation of artifacts + dry-run install plan. No system-state change |
| Inst   | Apply changes to host system (cert trust, WDAC policy, drivers) |

### Phase entry/exit contract

- The dispatcher renders `Write-PhaseHeader` before invoking the function and `Write-PhaseFooter` after.
- Phase functions never call `Write-PhaseHeader`/`Write-PhaseFooter` themselves.
- Phase functions may call `Write-SubHeader` (Cyan, Level-1) or `Write-SubHeader2` (DarkCyan, Level-2) for in-phase sectioning.

### Phase timing summary

Each phase result is recorded in `$Script:PhaseTimings` (`Add` of a `pscustomobject` with `Id`, `Status`, `Elapsed`, `EndedAt`). `Show-RunSummary` (run unconditionally in `finally`) prints the full table.

---

## A.5 Logging Conventions

### Markers (color-coded)

| Marker | Color    | Function       | Semantic            |
| ------ | -------- | -------------- | ------------------- |
| `[*]`  | Cyan     | `Write-Step`   | Action being taken  |
| `[+]`  | Green    | `Write-Ok`     | Success / positive  |
| `[!]`  | Yellow   | `Write-Warn2`  | Degraded / non-fatal|
| `[X]`  | Red      | `Write-Fail`   | Failure             |
| `[~]`  | DarkGray | `Write-Skip`   | No-op / cached      |

### Line format

```
[HH:mm:ss] [+X.XXs]   [marker] <message>
[HH:mm:ss]            [marker] <message>   ← when not inside a phase, no elapsed-tag
```

- `HH:mm:ss` is the current wall-clock time (host TZ).
- `[+X.XXs]` is the elapsed time since `$Script:CurrentPhaseStart` (reset on every phase entry).
- The marker / color combination is the only acceptable styling. Do not invent new markers (e.g. `[i]`, `[>]`, `[?]`); they break the visual scan pattern.

### Continuation / detail lines (Write-Detail)

Some output blocks (section-banner tables in `Show-PowerShellEnvironment`, `Show-OperatingSystemDetail`, `Show-SecureBootBaselineSnapshot`, P03 platform inventory, P05 INF inventory rows, V05 Dry-Run details, V06 hardware-impact rows, I00 review tables, etc.) emit lines that are visually subordinate to a preceding marker line or that fit naturally inside a `===` / `---` banner block. These lines do not need their own timestamp + marker prefix; doing so creates redundant noise and breaks the visual table layout.

For these cases use the dedicated helper:

| Helper          | Indent | Color (default) | Use                                                                                |
| --------------- | ------ | --------------- | ---------------------------------------------------------------------------------- |
| `Write-Detail`  | 4 sp.  | Gray            | Continuation row of a marker line, or interior row of a section-banner block       |

`Write-Detail` is the single sanctioned exception to the "every line has a marker" rule. It always prepends exactly 4 spaces and supports an optional `-Color <ConsoleColor>` parameter (defaulting to `Gray`) and a `-NoNewline` switch for label-then-value composition.

**Forbidden**: bare `Write-Host "    ..."` calls. All such call sites have been migrated to `Write-Detail`. Adding a new bare 4-space `Write-Host` is a SPEC violation and will be rejected in review.

### Banner helpers (Level-0 / Level-1 / Level-2)

| Helper             | Color     | Width     | Use                                                                |
| ------------------ | --------- | --------- | ------------------------------------------------------------------ |
| `Write-PhaseHeader`| Magenta   | `=` × 72  | Phase entry banner (dispatcher only)                               |
| `Write-PhaseFooter`| Status    | (1 line)  | Phase exit footer (dispatcher only)                                |
| `Write-SubHeader`  | Cyan      | `=` × 72  | Level-1 in-phase banner (major section within a phase)             |
| `Write-SubHeader2` | DarkCyan  | `-` × 72  | Level-2 in-phase banner (finer subsection)                         |

### Console encoding

P00 must enforce all THREE console encodings to UTF-8 so that:

1. **Japanese log strings** written via `Write-Host` render correctly on ja-JP Windows (otherwise the default code page is 932 / Shift-JIS and Japanese garbles).
2. **External tool stdout** captured via `& tool ... | Out-String` is decoded as UTF-8. CiTool.exe and modern signtool.exe write UTF-8 on Windows Server 2025, and without this setting their Japanese output renders as mojibake like `蜃ｦ逅・・謌仙粥縺励∪縺励◆` (the UTF-8 byte sequence of `処理が成功しました` interpreted as cp932).
3. **PowerShell-to-native stdin** pipes (`$json | tool.exe`) send UTF-8 bytes to the external tool.

The canonical implementation, defined as a dedicated helper `Set-ConsoleUtf8` and called from P00 immediately after `Set-Tls12` (chipset/graphics) or `Set-NetworkProtocol` (NPU):

```powershell
function Set-ConsoleUtf8 {
    try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch { }
    try { [Console]::InputEncoding  = [System.Text.Encoding]::UTF8 } catch { }
    try { Set-Variable -Name OutputEncoding -Scope Global -Value ([System.Text.Encoding]::UTF8) -ErrorAction SilentlyContinue } catch { }
}
```

The `try/catch` wrappers handle pinned-redirected console hosts (e.g. CI runners writing to a file with no real console) where the assignment may throw. See SPEC §D.16 for the root-cause analysis (CiTool.exe mojibake on ja-JP WS2025).

### TLS hardening

P00 must enable TLS 1.2 + 1.3 (and degrade gracefully on PS 5.1 without TLS 1.3):

```powershell
[Net.ServicePointManager]::SecurityProtocol = `
    [Net.SecurityProtocolType]::Tls12 -bor `
    [Net.SecurityProtocolType]::Tls13 -bor `
    [Net.SecurityProtocolType]::Tls11 -bor `
    [Net.SecurityProtocolType]::Tls
```

### Run log capture (`-LogFile`)

The four scripts expose a `-LogFile <path>` parameter that activates a script-internal `Start-Transcript` / `Stop-Transcript` pair. This is the canonical mechanism for retaining a run log; it supersedes the legacy `... *>&1 | Tee-Object -FilePath ...` idiom for two reasons:

1. **Coloring preservation.** `Tee-Object` on the outside of the pipeline captures the Write-Host output as the host stream is reduced to the pipeline value stream, which strips the `-ForegroundColor` decoration. `Start-Transcript` does not — the interactive console keeps its color, and the file gets every stream as plain text.
2. **Stream completeness.** `Start-Transcript` captures all of Output / Host / Error / Warning / Verbose / Debug. `Tee-Object` on `*>&1` captures the merged value stream, but does not preserve the per-stream metadata.

Canonical implementation pattern (mirror across all four sister scripts):

```powershell
# Param block (after -WorkRoot, before -PfxPassword)
[string]$LogFile       = '',

# Section 0.25, immediately after $Script:ScriptShortTag is set, before any
# Write-Host call that should be captured.
$Script:LogFileActive = $false
if (-not [string]::IsNullOrWhiteSpace($LogFile)) {
    try {
        $logDir = Split-Path -LiteralPath $LogFile -Parent
        if (-not [string]::IsNullOrWhiteSpace($logDir) -and -not (Test-Path -LiteralPath $logDir)) {
            New-Item -ItemType Directory -Path $logDir -Force -ErrorAction Stop | Out-Null
        }
        try { Stop-Transcript -ErrorAction SilentlyContinue | Out-Null } catch { }
        Start-Transcript -Path $LogFile -Append -Force -ErrorAction Stop | Out-Null
        $Script:LogFileActive = $true
        Register-EngineEvent -SourceIdentifier PowerShell.Exiting -SupportEvent -Action {
            try { Stop-Transcript -ErrorAction SilentlyContinue | Out-Null } catch { }
        } | Out-Null
        Write-Host ("[*] Transcript -> {0}" -f $LogFile) -ForegroundColor DarkGreen
    } catch {
        Write-Warning ("Failed to start transcript at '{0}': {1}" -f $LogFile, $_.Exception.Message)
        $Script:LogFileActive = $false
    }
}

# Top-level finally block (must also call this even if the script throws)
finally {
    if ($Script:LogFileActive) {
        try { Stop-Transcript -ErrorAction SilentlyContinue | Out-Null } catch { }
        $Script:LogFileActive = $false
    }
}
```

Required behaviour:

- **Parent directory auto-create**: the script creates the parent of `-LogFile` on demand (`New-Item -ItemType Directory -Force`). `C:\Temp\` is the canonical recommended parent and is auto-created if missing.
- **Append mode**: `Start-Transcript -Path $LogFile -Append -Force` so concurrent re-runs accumulate, not truncate. Operators that want a fresh file must include a timestamp in the filename (see filename convention below) or delete the file beforehand.
- **Defensive pre-stop**: call `Stop-Transcript -ErrorAction SilentlyContinue` before `Start-Transcript` to release any in-flight transcript from a previous run in the same PowerShell host (otherwise `Start-Transcript` fails with "transcription has already been started").
- **Two-tier cleanup**: register a `PowerShell.Exiting` engine event handler as a fallback, in addition to the top-level `finally` block. The handler catches the case where the script bails before reaching the `finally` (e.g. parameter validation error post-Start-Transcript).
- **Failure mode**: a `Start-Transcript` failure must NOT prevent the script from running. Emit a `Write-Warning` and continue with the transcript disabled (`$Script:LogFileActive = $false`).

Recommended filename convention:

```
C:\Temp\<scripttag>_<Action>_<yyyyMMdd-HHmmss>.log
```

Where `<scripttag>` is `amd-chipset` / `amd-graphics` / `amd-npu` / `ms-bthpan`. The timestamp suffix prevents same-Action re-runs from appending to the previous file when that is not desired.

Operators on a ja-JP host with the default cp932 console code page who pipe `-LogFile` output through a downstream tool must still set the consuming tool's file encoding to UTF-8 (the script's `Set-ConsoleUtf8` in P00 enforces UTF-8 for `[Console]::OutputEncoding`, but text editors / `Get-Content` on the captured file may default to cp932 / Shift-JIS).

---

## A.6 Parameter Conventions

### Common switches (use these names verbatim)

| Switch                       | Type     | Required | Description                                                       |
| ---------------------------- | -------- | -------- | ----------------------------------------------------------------- |
| `-Action`                    | string   | ✓        | `Prepare`/`Verify`/`PrepareVerify`/`Install`/`All`/`Cleanup`/`ListPhases` |
| `-OnlyPhases`                | string[] |          | Comma-separated phase IDs; overrides `-Action`-derived list       |
| `-CleanWorkRoot`             | switch   |          | Delete the workspace before starting                              |
| `-AllowWorkstationInstall`   | switch   |          | Permit Install on Workstation OS (default: blocked)               |
| `-UseTestSigning`            | switch   |          | Fall back to bcdedit testsigning (default: WDAC policy)           |
| `-WorkRoot`                  | string   |          | Workspace path override (default: `C:\Temp\Workspace_<vendor>-<short>`) |
| `-LogFile`                   | string   |          | Capture full console transcript via `Start-Transcript`. See §A.5 |
| `-PfxPassword`               | string   |          | Self-signed PFX password (lab default: empty)                     |
| `-CertValidityYears`         | int      |          | Self-signed cert validity (default: 5)                            |

### Action -> Phase mapping (sister-script aligned)

```
Prepare       : Prep only
Verify        : Verify only
PrepareVerify : Prep + Verify    (default; no system-state change)
Install       : Inst only        (assumes Prep + Verify already ran)
All           : Prep + Verify + Inst   (full pipeline)
Cleanup       : (short-circuit, runs Invoke-Cleanup)
ListPhases    : (short-circuit, runs Show-PhaseList)
```

### Mutual exclusion

- `-OnlyPhases` overrides `-Action`-derived phase list.
- `-UseTestSigning` is mutually exclusive with the default WDAC policy path; warn if both states attempt to apply.
- NPU script's `-OfflineZip` takes priority over `-InstallerUrl` for Tier 4 short-circuit.

---

## A.7 Path Handling Rules

### The wildcard-interpretation hazard

PowerShell's `*-Path` cmdlets interpret `[`, `]`, `?`, `*` in paths as wildcards by default. INF filenames sometimes contain `[` (e.g. `oem_[stx].inf`), and AMD installer ZIPs can extract into paths with brackets. Always use `-LiteralPath` on:

```powershell
Test-Path -LiteralPath $path
Get-Item -LiteralPath $path
Remove-Item -LiteralPath $path
Copy-Item -LiteralPath $src -Destination $dst
Move-Item -LiteralPath $src -Destination $dst
Get-FileHash -LiteralPath $path
[System.IO.File]::ReadAllLines($path)  ← .NET APIs ignore wildcards by definition
```

### Cmdlets that do NOT support `-LiteralPath`

- `Invoke-WebRequest -OutFile` (PowerShell 5.1) does NOT accept `-LiteralPath`; the path is wildcard-interpreted. Workaround: download to a wildcard-free temp path (e.g. `<dir>\.dl_<GUID>.part`), then `Move-Item -LiteralPath` to the real destination.
- `Export-PfxCertificate`, `Export-Certificate`: take `-FilePath` (wildcard-safe in practice; AMD-CodeSign filenames have no brackets, so this is acceptable).

### Sanitization of derived filenames

When generating filenames from INF Provider strings or driver versions, strip / replace these characters: `/ \ : * ? " < > | [ ]`. Use:

```powershell
$safe = $raw -replace '[\/\\:*?"<>\|\[\]]', '_'
```

---

## A.8 Error & Diagnostic Conventions

### Three-tier diagnostic output

1. **Console**: marker-prefixed lines via `Write-Step/Ok/Warn2/Fail/Skip` (see A.5).
2. **CSV**: per-phase machine-readable artefacts under workspace (see A.9).
3. **Run summary**: `Show-RunSummary` (always runs in `finally`) prints PhaseTimings + total elapsed + ScriptHash.

### Failure category classification

Phase results in `$Script:PhaseResults` are tagged with one of:

| Status  | Meaning                                                                            |
| ------- | ---------------------------------------------------------------------------------- |
| `OK`    | Phase completed successfully                                                       |
| `FAIL`  | Phase raised an exception (caught by `Invoke-PhaseRunner`)                         |
| `SKIP`  | Phase was not selected by `-Action` / `-OnlyPhases` (displayed only in summary)    |

When `-Action Install` (or `All`) reaches the top-level try/catch with `$Script:TopLevelException`, the dispatcher exits with code `1`; otherwise `0`.

### Stack trace surface

On top-level exception, render the `.ScriptStackTrace` via `Write-Skip` lines so the user can copy the trace for issue reporting:

```powershell
foreach ($line in ($_.ScriptStackTrace -split "`n")) {
    Write-Skip ("    {0}" -f $line.TrimEnd())
}
```

---

## A.9 CSV Column Conventions

### `inf_inventory.csv` (P05 output, all four scripts)

| Column                | Type   | Notes                                                          |
| --------------------- | ------ | -------------------------------------------------------------- |
| `FileName`            | string | Required                                                       |
| `FullPath`            | string | Required                                                       |
| `Provider`            | string | From `[Version]` Provider                                      |
| `DriverVer`           | string | From `[Version]` DriverVer                                     |
| `Class`               | string | Device class                                                   |
| `HwidCount`           | int    | Total HWIDs in the INF                                         |
| `MatchesTargetNpu`    | bool   | NPU script only                                                |
| `MatchedHwidCount`    | int    | NPU script only (count of HWIDs matching target platform)      |
| `HasServerDecoration` | bool   | INF already has `ProductType=3`                                |
| `WorkstationDecCount` | int    | Workstation decoration count                                   |
| `ServerDecCount`      | int    | Server decoration count                                        |
| `NeedsPatch`          | bool   | `WorkstationDecCount > 0 -and ServerDecCount == 0`             |
| `SelectedForPipeline` | bool   | Pipeline filter pass-through                                   |
| `HwidPreview`         | string | First 3 HWIDs joined for human readability                     |

### CSV encoding

- Encoding: UTF-8 (no BOM).
- Quoting: PowerShell's default `Export-Csv -NoTypeInformation` behavior.
- Delimiter: `,` (comma).
- Line ending: CRLF (PowerShell default on Windows).

---

## A.10 Environment Evaluation (Phase P00)

P00 runs unconditionally and gathers the inputs that all downstream phases depend on:

### Step 0: PowerShell environment

`Show-PowerShellEnvironment` dumps:

- `PSVersion`, `PSEdition`, `PSCompatibleVersions`
- `CLRVersion`, `BuildVersion`, `OS`, `Platform`

Then hard-fails if `<5.1` or if not 64-bit.

### Step 1: Administrator privileges

`Test-AdminPrivilege` throws if not running elevated.

### Step 2: TLS hardening

`Set-NetworkProtocol` enables TLS 1.2 + 1.3 (degrades to TLS 1.2 on PS 5.1).

### Step 3: OS profile resolution

`Show-OperatingSystemDetail` resolves OS build → inf2cat `/os:` switch:

| Build  | Profile         | inf2cat /os:       |
| ------ | --------------- | ------------------ |
| 26100  | WS2025          | Server2025_X64     |
| 22631  | WS2022-equiv    | ServerFE_X64       |
| 22000  | WS2022-equiv    | ServerFE_X64       |
| 20348  | WS2022          | ServerFE_X64       |
| 19041  | WS2019-equiv    | ServerRS5_X64      |
| 17763  | WS2019          | ServerRS5_X64      |
| 14393  | WS2016          | Server2016_X64     |

### Step 4: ProductType detection

`ProductType = 1` (Workstation) emits the "WS2025 PRE-MIGRATION PREVIEW MODE" banner on build 26100. `ProductType = 3` (Server) proceeds without it.

---

## A.11 Static Analysis with psa.py

### Version policy

The repository validates its PowerShell scripts against the **latest mainline** `psa.py` from the canonical repository. Pinning to a fixed SemVer (e.g. "I tested with `psa.py` 3.3.0") is **not supported** as a development or CI strategy:

- New `psa.py` releases may add opt-in rules (the `PSAPxxxx` family) that surface previously-hidden discipline violations.
- New `psa.py` releases may tighten heuristics for existing rules.
- A previously-clean codebase under an older `psa.py` is **not** evidence of correctness under the current `psa.py`. It must be re-validated.

This SPEC, `TESTING.md`, `CONTRIBUTING.md`, and `README.md` therefore avoid pinning `psa.py` to a specific version number in forward-looking text. References to a specific version are acceptable only in `CHANGELOG.md` (which is rNN/version-by-design and records *which* `psa.py` version produced *which* baseline) and in `psa.py`'s own `CHANGELOG.md`.

#### How to discover the current mainline version

The canonical source of truth for "what is the current `psa.py` version on mainline" is the `VERSION` file sitting next to `psa.py` in the canonical repository:

```
ai-generated-artifacts/scripts/python/powershell-static-analyzer/
├── psa.py        ← __version__ string inside
├── VERSION       ← single ASCII line, no leading 'v', terminating LF
├── SPEC.md
├── CHANGELOG.md
└── README.md
```

Three equivalent retrieval methods (any of them works; pick the one that fits your environment):

```bash
# Method 1 — remote HTTP GET, no clone, no Python (recommended for CI / one-off checks).
LATEST=$(curl -sSL https://raw.githubusercontent.com/usui-tk/ai-generated-artifacts/main/scripts/python/powershell-static-analyzer/VERSION)
echo "Latest psa.py on mainline: $LATEST"

# Method 2 — already cloned (e.g., sister repository checkout next to this one).
LATEST=$(cat /path/to/ai-generated-artifacts/scripts/python/powershell-static-analyzer/VERSION)

# Method 3 — invoke a local copy of psa.py (requires Python).
LATEST=$(python3 /path/to/psa.py --version | awk '{print $2}')
```

The three methods MUST agree: `psa.py` runs a startup self-check that compares its `__version__` against the sibling `VERSION` file and warns to stderr if they differ.

#### LLM / AI workflow for adopting a new version

When an LLM / AI maintainer (or a human) is about to make changes to **any** of the four PowerShell scripts in this repository, the very first step of the development cycle MUST be:

1. **Fetch the current mainline version**: run Method 1 above to get `LATEST`.
2. **Compare with the local copy actually being used**: read `__version__` from the local `psa.py`, or run `python3 /path/to/local/psa.py --version`. Call this `LOCAL`.
3. **If `LATEST != LOCAL`**:
   1. Replace `psa.py` AND its sibling `VERSION` file from mainline (both files MUST move together):
      ```bash
      curl -sSL https://raw.githubusercontent.com/usui-tk/ai-generated-artifacts/main/scripts/python/powershell-static-analyzer/psa.py -o psa.py
      curl -sSL https://raw.githubusercontent.com/usui-tk/ai-generated-artifacts/main/scripts/python/powershell-static-analyzer/VERSION -o VERSION
      ```
   2. Read the new entries in the canonical [`psa.py` `CHANGELOG.md`](https://github.com/usui-tk/ai-generated-artifacts/blob/main/scripts/python/powershell-static-analyzer/CHANGELOG.md) and the current canonical [`psa.py` `SPEC.md`](https://github.com/usui-tk/ai-generated-artifacts/blob/main/scripts/python/powershell-static-analyzer/SPEC.md) to understand what changed (new rules, tightened heuristics, schema changes).
   3. Re-evaluate this repository's `.psa.config.json` `enable` list against the latest `psa.py` `SPEC.md`. Newly-added opt-in rules that match the four pipeline scripts' discipline goals SHOULD be enabled (this repository currently opts in to all four PSAPxxxx rules).
   4. Re-run the full static-analysis pass for all four scripts under the new `psa.py`. Treat any new findings as regressions to be addressed in the same change set, not as findings to be deferred.
4. **If `LATEST == LOCAL`**: proceed with the planned change, but still re-run the analyzer on the modified scripts before declaring done.

This workflow makes the "latest mainline" rule machine-actionable: an LLM that has read this section can derive a deterministic sequence of `curl`, comparison, fetch, and re-test steps for any task that touches PowerShell code in this repository.

For the full policy rationale and additional context, see the [psa.py Versioning Policy](https://github.com/usui-tk/ai-generated-artifacts/blob/main/README.md#psapy-versioning-policy) section of the canonical repository's `README.md`.

### Canonical source

`psa.py` is **not bundled in this repository**. It is maintained as a single canonical artifact in a separate repository:

```
Repository : https://github.com/usui-tk/ai-generated-artifacts
Path       : scripts/python/powershell-static-analyzer/psa.py
Raw URL    : https://raw.githubusercontent.com/usui-tk/ai-generated-artifacts/main/scripts/python/powershell-static-analyzer/psa.py
```

Any change to `psa.py` (bug fix, new check, new auto-variable entry, etc.) must be made in that canonical repository. This repository (`Deploy-Drivers-For-WindowsServer`) is one of its **consumers**.

### Setup

Pick one of the two methods below. Both are equivalent in result; the choice is operator preference.

**Method 1 — Clone the canonical repository as a sibling directory** (recommended for ongoing development):

```bash
# From the parent directory of this repository
git clone https://github.com/usui-tk/ai-generated-artifacts.git

# Then, from this repository's root:
python3 ../ai-generated-artifacts/scripts/python/powershell-static-analyzer/psa.py Deploy-AMDChipsetDriverOnWindowsServer.ps1
python3 ../ai-generated-artifacts/scripts/python/powershell-static-analyzer/psa.py Deploy-AMDGraphicsDriverOnWindowsServer.ps1
python3 ../ai-generated-artifacts/scripts/python/powershell-static-analyzer/psa.py Deploy-AMDNpuDriverOnWindowsServer.ps1
python3 ../ai-generated-artifacts/scripts/python/powershell-static-analyzer/psa.py Deploy-MSBthPanInboxOnWindowsServer.ps1
```

**Method 2 — Download the single file** (recommended for one-shot CI runs):

```bash
# From the repository root (Linux / macOS)
curl -sSLO https://raw.githubusercontent.com/usui-tk/ai-generated-artifacts/main/scripts/python/powershell-static-analyzer/psa.py
python3 psa.py Deploy-AMDChipsetDriverOnWindowsServer.ps1
python3 psa.py Deploy-AMDGraphicsDriverOnWindowsServer.ps1
python3 psa.py Deploy-AMDNpuDriverOnWindowsServer.ps1
python3 psa.py Deploy-MSBthPanInboxOnWindowsServer.ps1
```

```powershell
# Or, from the repository root (Windows PowerShell)
Invoke-WebRequest `
    -Uri  "https://raw.githubusercontent.com/usui-tk/ai-generated-artifacts/main/scripts/python/powershell-static-analyzer/psa.py" `
    -OutFile psa.py
python3 psa.py Deploy-AMDChipsetDriverOnWindowsServer.ps1
python3 psa.py Deploy-AMDGraphicsDriverOnWindowsServer.ps1
python3 psa.py Deploy-AMDNpuDriverOnWindowsServer.ps1
python3 psa.py Deploy-MSBthPanInboxOnWindowsServer.ps1
```

The rest of this SPEC, and `TESTING.md` / `CONTRIBUTING.md`, write `python3 psa.py <script>.ps1` as shorthand. This assumes `psa.py` has been obtained via either method and is accessible on a path of your choice.

### Required gate

Every commit must pass with **0 errors**. Warnings and info entries are
allowed but must match the documented baseline in §A.11.5 below. Any new
warning that is not in the baseline must be triaged and either fixed, given
an inline suppression with a justification (`# psa-disable-line <CODE> -- <reason>`),
or — for genuinely new findings — be added to the baseline in this SPEC.

For automated gating, the recommended CI filter is `--severity error`:

```bash
python3 psa.py --severity error Deploy-AMDChipsetDriverOnWindowsServer.ps1
# Exit code 0 = no errors. Warnings and info do not gate the build.
```

### Rule coverage (46 rules)

`psa.py` ships with a **46-rule** check set grouped into **nine categories**. The PSA8xxx, PSA9xxx, and PSAPxxxx families were added in 3.2.0; PSAP0003 and PSAP0004 were added in 3.3.0; PSA2007 / PSA2008 were added in 3.6.0; PSA3005 was added in 3.2.0 and PSA3006 in 3.7.0; PSA7002 was added in 3.7.0; PSA2009 was added in 3.8.0; PSA2010 and PSA2011 were added in 3.9.0 (see §D.33.8 for the motivation); **PSAP0005 was added in 4.0.0 — the LLM-assisted maintenance guardrail companion of PSAP0003, see SPEC §A.13 "Enforcement matrix" and the upstream `psa.py` SPEC §4.37 for its detection rules and the relaxed-mode migration aid**. The older PSA1xxx–PSA7xxx families are otherwise unchanged in scope. (See the canonical [psa.py `CHANGELOG.md`](https://github.com/usui-tk/ai-generated-artifacts/blob/main/scripts/python/powershell-static-analyzer/CHANGELOG.md) for the full per-version history; this repository validates against the latest mainline — see the Version policy subsection above.)

| Category                                  | Code range            | Examples                                                                                                                                                                                                                                                              |
| ----------------------------------------- | --------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Syntax balance                            | `PSA1001`..`PSA1003`  | brace / paren / bracket balance                                                                                                                                                                                                                                       |
| Semantics                                 | `PSA2001`..`PSA2006`  | undefined variable, auto-variable shadowing, `-match` against bare variable, `$null` on the right of `-eq`/`-ne`, assignment / redirection inside conditional                                                                                                         |
| Coding pattern                            | `PSA3001`..`PSA3005`  | `Start-Process -ArgumentList`, trailing backtick before empty line, `-match` against empty string, empty `catch` block, `Start-Transcript -Path` should be `-LiteralPath`                                                                                            |
| Hygiene                                   | `PSA4001`..`PSA4004`  | unfinished markers, trailing whitespace, long line, trailing semicolon                                                                                                                                                                                                |
| Security                                  | `PSA5001`..`PSA5004`  | plain-text password parameter, `Invoke-Expression`, broken hash algorithm, hardcoded `ComputerName`                                                                                                                                                                   |
| Best practice                             | `PSA6001`..`PSA6006`  | non-approved verb, cmdlet alias, plural function noun, `$global:` definition, mandatory parameter with default, switch defaulting to `$true`                                                                                                                          |
| File format                               | `PSA7001`             | missing UTF-8 BOM on `.ps1` (Windows PowerShell 5.1 ja-JP falls back to Shift-JIS / cp932 without BOM)                                                                                                                                                                 |
| Cross-file consistency                    | `PSA8001`             | function body hash drift across files in the same scan — enforces that shared helper functions (`Format-Elapsed`, `Write-Detail`, `Start-DebugTrace` family, etc.) stay byte-for-byte synchronised across the four pipeline scripts                                   |
| Complexity metrics                        | `PSA9001`..`PSA9002`  | function-body length threshold (default off, tunable via `max_function_lines`), external-process invocation without `$LASTEXITCODE` check (default off)                                                                                                              |
| Project / pipeline conventions            | `PSAP0001`..`PSAP0004` | phase function naming convention (`Invoke-(Prep\|Verify\|Inst)PhaseNN_Name`), required script-identifier variables, **new in 3.3.0:** inline `# rNN:` revision-tag comments (`PSAP0003`), end-of-file `REVISION HISTORY` blocks (`PSAP0004`). **All PSAPxxxx rules are off by default**; opt in via `.psa.config.json`. This repository opts in to all four. |

For the authoritative specification of every rule (severity, examples,
suppression guidance), see
`https://github.com/usui-tk/ai-generated-artifacts/blob/main/scripts/python/powershell-static-analyzer/SPEC.md`
§4.

Exit codes: `0` = clean (or `--severity error` filter passing), `1` =
warnings/info present, `2` = errors. The default `--severity` floor is
`info`.

### Project-local `.psa.config.json` (canonical for this repository)

This repository ships its own `.psa.config.json` at the repository root. It is the **canonical configuration for the four pipeline scripts** and does the following:

1. **Opts in to `PSAP0001`, `PSAP0002`, `PSAP0003`, and `PSAP0004`** so that the 21-phase naming convention (`Invoke-(Prep|Verify|Inst)PhaseNN_DescriptiveName`), the script-identity trio (`$Script:ScriptVersion` / `$Script:ScriptHash` / `$Script:ScriptShortTag`), and the revision-discipline rules (no inline `# rNN:` revision-tag comments, no in-script `REVISION HISTORY` blocks — per-revision history lives exclusively in `CHANGELOG.md`) are all enforced.

2. **Configures `PSA8001` (cross-file function-body drift)** with `psa8001_ignore_functions`, listing roughly 45 function names that are intentionally per-script (phase functions matched via regex `^Invoke-(Prep|Verify|Inst)Phase\d{2}_`, plus per-driver-family helpers such as `Show-Help`, `Show-PhaseList`, `Find-KitTool`, `Expand-AmdInstaller`, etc.). Shared helpers NOT listed there MUST stay byte-for-byte identical across all four scripts.

3. **Disables `PSA4003` (long line)** because the pipeline scripts intentionally use multi-clause `-f` format strings (Show-PowerShellEnvironment table, per-device AS-IS / TO-BE analysis tables) that exceed 120 columns for readability of the resulting console output.

The canonical invocation is therefore:

```bash
python3 path/to/psa.py --config ./.psa.config.json \
    Deploy-AMDChipsetDriverOnWindowsServer.ps1 \
    Deploy-AMDGraphicsDriverOnWindowsServer.ps1 \
    Deploy-AMDNpuDriverOnWindowsServer.ps1 \
    Deploy-MSBthPanInboxOnWindowsServer.ps1
```

All four scripts MUST be passed in a single invocation for PSA8001 cross-file analysis to work. `psa.py` auto-discovers `.psa.config.json` in the current working directory, so when run from the repository root the `--config` flag may be omitted.

### A.11.5 Documented baseline (warnings and info)

This repository has the following **accepted** warning / info baseline
(see [CHANGELOG.md](./CHANGELOG.md) for the most recent verified counts).
Any deviation from these counts must be explained in the commit message
and either added here or fixed.

**Strict baseline** (all rules except `PSAP0005`):

| Script                                          | Errors | Warnings | Info | Total |
| ----------------------------------------------- | -----: | -------: | ---: | ----: |
| `Deploy-AMDChipsetDriverOnWindowsServer.ps1`    |  **0** |    **0** |  **0** |   **0** |
| `Deploy-AMDGraphicsDriverOnWindowsServer.ps1`   |  **0** |    **0** |  **0** |   **0** |
| `Deploy-AMDNpuDriverOnWindowsServer.ps1`        |  **0** |    **0** |  **0** |   **0** |
| `Deploy-MSBthPanInboxOnWindowsServer.ps1`       |  **0** |    **0** |  **0** |   **0** |

**`PSAP0005` migration baseline** (relaxed mode, `psap0005_relaxed_mode: true`, introduced at the r76 / r42 / r24 / r20 release):

| Script                                          | PSAP0005 (relaxed) | Note |
| ----------------------------------------------- | ------------------: | ----- |
| `Deploy-AMDChipsetDriverOnWindowsServer.ps1`    |              **22** | Migration target. See §A.13 "Migration roadmap". |
| `Deploy-AMDGraphicsDriverOnWindowsServer.ps1`   |              **24** | Migration target. Five `R9700` / `R1*` AMD hardware-platform-identifier sites are suppressed via `# psa-disable-line PSAP0005 -- AMD ... identifier`. |
| `Deploy-AMDNpuDriverOnWindowsServer.ps1`        |               **2** | Migration target. |
| `Deploy-MSBthPanInboxOnWindowsServer.ps1`       |              **16** | Migration target. |

The PSAP0005 totals shown above are the warning counts reported under
`psap0005_relaxed_mode: true`. They are accepted as the
**`psa-py-v4-llm-governance-baseline` migration baseline** for the
r76 / r42 / r24 / r20 release; the end-state goal is to drop them to
**0** by completing the four-step migration documented in §A.13. The
strict-mode baseline (i.e., `psap0005_relaxed_mode: false`) would be
significantly higher (the four relaxed-mode exemptions catch the
established prose patterns from SPEC §D.31 et al.); SPEC §A.13
"Allowed / disallowed prose examples" and "Migration roadmap"
describe the cleanup plan.

PSA8001 byte-identity of the affected cross-script helpers is
preserved throughout the migration (any cleanup that touches a
shared-helper line must be applied to all sister scripts atomically;
the suppression directives, where used, are inside per-script
comments only and do not affect any byte-identical helper body).

The 2026-05-18 release is the **first revision where the canonical static-analysis baseline is fully clean across all four scripts simultaneously** (with the canonical `.psa.config.json` as documented above). The subsequent 2026-05-20 cross-script consistency release (`debugtrace-helper-internal-cleanup`, Chipset r62 / Graphics r30 / NPU r13 / MSBthPan r12) **preserves this baseline unchanged at 0 / 0 / 0** on all four scripts. The release refines three shared helper functions (`_DebugTrace_WriteJsonlLine`, `Export-DebugTraceJson`, `Show-PowerShellEnvironment`) and is byte-for-byte synchronized across all four scripts per PSA8001 (see [CHANGELOG.md](./CHANGELOG.md) for the verified per-function SHA-256 hashes).

The follow-on 2026-05-20 release (`psa-py-v360-baseline-uplift`, Chipset r63 / Graphics r31 / NPU r14 / MSBthPan r13) **also preserves the 0 / 0 / 0 baseline** while adopting the upstream `psa.py` v3.6.0 rule expansion (PSA2007 / PSA2008 / PSA3006 / PSA6007 / PSA6008 added; PSA2002 risky-shadow set expanded from 8 to 38 entries). The uplift renames two auto-variable-shadowing locals (`$home` → `$winHomeLocation` in `Get-MachineRegion`; `$profile` → `$osProfile` in `Show-OperatingSystemDetail`) — both were true defects in the sense that they assigned to a PowerShell engine auto-variable — and adds `[OutputType([<type>])]` declarations to 27 functions across the four scripts. PSA8001 byte-for-byte parity on the shared helpers is preserved. See [CHANGELOG.md](./CHANGELOG.md) for the detailed function-by-function diff.

The 2026-05-23 release (`psa-py-v380-pscustomobject-rule`, Chipset r73 / Graphics r39 / NPU r18 / BthPan r21) introduces **PSA2009 — PSCustomObject property assigned without prior declaration** (warning, on by default). PSA2009 is the static-analysis counterpart of the runtime defect that surfaced in this release as `Chipset r72 P05 -> FAILED with "WhqlCoSignAnalysis" property-not-found exception` on a Japanese-locale Windows Server 2019 host. The rule models the PowerShell 5.1 `[pscustomobject]@{...}` sealed-object semantic: any `$obj.NewProp = value` assignment where `NewProp` was not in the initialiser AND was not added later via `Add-Member -MemberType NoteProperty -Name NewProp` is reported as a warning. False-positive prevention is engineered into the rule: a variable that is also assigned with a plain hashtable literal (`@{...}` / `[hashtable]@{...}` / `[ordered]@{...}`) anywhere in the same file is conservatively dropped from tracking, which addresses NPU's accumulator pattern where `$result` is sometimes `[pscustomobject]@{...}` (for the per-section parse result) and sometimes `@{...}` (for the per-patch outcome) in different functions of the same file. Running `psa.py --include PSA2009` against the four PowerShell scripts in this repository at the r72/r38/r18/r20 baseline reproduces two warnings on Chipset, two on BthPan, and zero on Graphics / NPU — corresponding exactly to the two assignment sites (happy path + `catch` fallback) per affected script. After the r73 / r39 / r21 fix landed in this release, all four scripts report zero PSA2009 findings. See **A.11.5c** below for the rule's detailed semantics.

How the previously-documented findings were resolved in this sync:

| Rule                                       | Prior totals (per script)       | Resolution applied                                                                                                                                                                                                                                                                            |
| ------------------------------------------ | -------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `PSA1001` (brace balance, error)           | 1 / 1 / 0 / 0                    | Resolved by the **psa.py 3.2.0 tokenizer fix** (PowerShell `""` double-quote-doubling escape and the `` `` `` double-backtick escape are now handled correctly). No script-side change was required.                                                                                          |
| `PSA2001` (undefined variable, error)      | 7 / 7 / 0 / 2                    | Resolved by **psa.py 3.2.0 scope-qualifier handling** (`$Script:`, `$global:`, `$local:`, `$private:` are now treated as runtime-deferred and never reported as undefined). No script-side change was required.                                                                              |
| `PSA4001` (TODO / FIXME marker, info)      | 1 / 1 / 0 / 1                    | Resolved by **psa.py 3.2.0 marker-matching tightening** (the analyzer now requires a colon or whitespace-then-letter after the marker, and ignores embedded string literals like `"XXX"` inside comments). No script-side change was required.                                                |
| `PSA2002` (unused parameter, w.)           | 0 / 0 / 0 / 3                    | Fixed in an earlier MSBthPan revision: three `$args` shadow assignments at L7556 / L7685 / L8863 (inf2cat / signtool / pnputil invocations) renamed to `$cmdArgs`.                                                                                                                                            |
| `PSA2003` (-match against bare variable)   | 6 / 7 / 4 / 4                    | Annotated inline with `# psa-disable-line PSA2003 -- pattern variable is initialized in the enclosing scope; $null impossible by construction`. Pattern variables are local constants, never `$null`.                                                                                          |
| `PSA3001` (Start-Process -ArgumentList)    | 4 / 3 / 0 / 9                    | Annotated inline with `# psa-disable-line PSA3001 -- Start-Process -ArgumentList is the canonical pattern for invoking signtool/inf2cat/pnputil with explicit args`.                                                                                                                          |
| `PSA3004` (empty `catch`, w.)              | 31 / 31 / 13 / 29                | Annotated inline with `# psa-disable-line PSA3004 -- intentional best-effort cleanup; no error to surface`.                                                                                                                                                                                   |
| `PSA3005` (Start-Transcript -Path, w.)     | 3 / 3 / 3 / 3 (new rule)         | Annotated inline with `# psa-disable-line PSA3005 -- deliberate cascade of -Path vs -LiteralPath variants for transcript-handle fallback`. The `logSetupForms` cascade in `Show-PowerShellEnvironment` legitimately tests both `-Path` and `-LiteralPath` forms.                              |
| `PSA4004` (trailing semicolon, info)       | 31 / 37 / 0 / 31                 | Auto-fixed by mechanical deletion of trailing `;` from end-of-line statements (outside strings / comments only). 98 deletions across the three affected scripts.                                                                                                                              |
| `PSA6003` (plural function noun, w.)       | 14 / 15 / 13 / 16                | Annotated inline with `# psa-disable-line PSA6003 -- compound noun (e.g., Policies, Drivers, Catalogs) is semantically plural for set-returning helpers`. Renaming would be a breaking API change against published pipeline phase names.                                                    |
| `PSA8001` (function-body drift, new)       | n/a (rule new in 3.2.0)          | All shared helper functions are now byte-for-byte identical across the four scripts. Per-script functions (phase functions, `Show-Help`, etc.) are listed in `psa8001_ignore_functions` in `.psa.config.json`. The `[CmdletBinding()] param()` declaration on AMDNpu's `Set-ConsoleUtf8` was removed to match the canonical body in the other three scripts. |
| `PSAP0001` (phase naming, new opt-in)      | n/a (rule new in 3.2.0)          | All 21 phase functions match `Invoke-(Prep\|Verify\|Inst)PhaseNN_DescriptiveName`. The single non-phase function with an `Invoke-` prefix (AMDNpu `Invoke-PhaseRunner`, the phase dispatcher) is annotated `# psa-disable-line PSAP0001 -- ... is the phase dispatcher, not a phase itself`.    |
| `PSAP0002` (script-identifier trio, new)   | n/a (rule new in 3.2.0)          | All four scripts assign `$Script:ScriptVersion`, `$Script:ScriptHash`, and `$Script:ScriptShortTag` early in the SECTION 0 (Constants / Identity) block; this requirement is met by the current mainline and survives the sync.                                                       |

**Note on PSA5001 (plaintext password, error)**: previously reported as 1 / 1 / 3 errors. As of the psa-baseline-sync revision these were all suppressed inline at the `param()` declaration site, because the value flows to `signtool.exe /p` and `X509Certificate2(.., String)` — both of which require a plaintext `String` at the API boundary. The inline justification comments explain the design intent at each site. The 2026-05-18 sync preserves these suppressions unchanged.

### A.11.5b Shared-helper contract (PSA8001-enforced)

Across all four pipeline scripts, **34 helper functions** are inherited verbatim from the canonical baseline. PSA8001 (cross-file function-body drift) actively enforces byte-for-byte identity on **30 of them**; the remaining **4 Secure Boot baseline diagnostic helpers** (listed in `.psa.config.json` `psa8001_ignore_functions`: `Format-SecureBootBaselineForReport`, `Get-SecureBootCertificateInventory`, `Get-MsSecureBootExampleScriptPath`, `Invoke-MsSecureBootDetectScript`) are still inherited verbatim so that any future PSA8001 uplift on those 4 sees a consistent baseline. The current contract surface (see [CHANGELOG.md](./CHANGELOG.md) for the verified baseline):

**Logging primitives (12 functions)**

`Format-Elapsed`, `_LogLine`, `Write-Step`, `Write-Ok`, `Write-Warn2`, `Write-Fail`, `Write-Skip`, `Write-Detail`, `Write-PhaseHeader`, `Write-PhaseFooter`, `Get-PhaseElapsedTag`, `Format-DebugFailure`

**DebugTrace framework (12 functions)**

`_DebugTrace_NextSeq`, `_DebugTrace_Now`, `_DebugTrace_WriteJsonlLine`, `_DebugTrace_RetireFrame`, `Start-DebugTrace`, `Stop-DebugTrace`, `Set-DebugStep`, `Write-DebugFailureReport`, `Enable-DebugTraceFileOutput`, `Disable-DebugTraceFileOutput`, `Get-DebugTraceFileOutputStatus`, `Enable-AutoExportOnPhaseFailure`

**Environment / preflight (5 functions)**

`Set-Tls12`, `Set-ConsoleUtf8`, `Assert-Admin`, `Assert-PowerShellCompatibility`, `Show-PowerShellEnvironment`

**Secure Boot baseline diagnostic helpers (5 functions; 1 PSA8001-enforced + 4 PSA8001-ignored-but-still-verbatim)**

`Format-SecureBootBaselineForReport` *(ignored)*, `Get-SecureBootCertificateInventory` *(ignored)*, `Get-MsSecureBootExampleScriptPath` *(ignored)*, `Invoke-MsSecureBootDetectScript` *(ignored)*, `Export-DebugTraceJson` *(enforced)*

**Verifying the contract locally**: run psa.py against all four scripts in a single invocation. Any drift in the **30 PSA8001-enforced functions** above will produce a PSA8001 error pointing at the function header. Drift in the **4 PSA8001-ignored Secure Boot baseline diagnostic helpers** will not be flagged by `psa.py` (those helpers are listed in `psa8001_ignore_functions` because their call sites reference `$Ctx`-shaped context indirectly and one variant exists across the four driver scripts), but is still a contract violation that maintainers MUST manually verify on touch — see SPEC §D.25 r03 status note for the rationale. Functions intentionally per-script (phase functions, `Show-Help`, `Show-PhaseList`, `Find-KitTool`, per-driver-family helpers) are also listed in `psa8001_ignore_functions` in `.psa.config.json`; functions identical in only 2-3 of the 4 scripts (e.g., AMD-family-only helpers, MSBthPan-only helpers) are not currently enforced because their absence in the 4th script is by design.

When adding a new shared helper that should remain in sync across all four scripts, add it to all four scripts with identical bodies and do NOT add it to `psa8001_ignore_functions`. PSA8001 will then enforce its sync invariant from that point onward.

**Documented per-driver-family exceptions to byte-identity**: One additional helper, `Build-PatchedInfHwidIndex`, appears in both Chipset and Graphics with intentionally divergent bodies and is listed in `psa8001_ignore_functions`. The Chipset variant integrates a phantom-file-reference filter (added in Chipset r65; see [§D.24](#d24-phantom-file-reference-detection--pipeline-wide-skip-chipset)) that calls the Chipset-only helpers `Get-IneligibleInfLookup` / `Test-InfIsIneligible` to exclude INFs flagged by P05 as ineligible from the V06 AS-IS / TO-BE comparison. The Graphics variant omits this filter by design: Adrenalin packaging (single-EXE WIX BURN bootstrapper) does not exhibit the layered NSIS → InstallShield SFX → nested-MSI structure that produced the Chipset `SECREPAIR Error: 3` cascade, and Graphics P05 has been validated (Adrenalin 26.5.2 Vega-Polaris Legacy on Renoir / WS2019) to produce 0 ineligible INFs in practice. Per SPEC §D.24 the port of the r65 phantom-file machinery to Graphics is deferred until the same defect is observed in a real Adrenalin package; until then, the `psa8001_ignore_functions` entry codifies this asymmetry so the CI baseline remains at 0 errors / 0 warnings.

### A.11.5c PSA2009 — PSCustomObject sealed-object semantic checks

**Rule code**: PSA2009.
**Severity**: warning.
**Default**: on.
**Introduced**: `psa.py` v3.8.0 (Chipset r73 / Graphics r39 / NPU r18 / BthPan r21 release).

#### Motivation

PowerShell 5.1's `[pscustomobject]@{...}` accelerator constructs a sealed object whose property surface is fixed at the moment the initialiser runs. Any subsequent `$obj.NewProp = value` assignment that targets a property NOT in the initialiser raises a terminating exception:

```
"<PropName>" の設定中に例外が発生しました: "このオブジェクトにプロパティ '<PropName>' が見つかりません。
プロパティが存在し、設定可能であることを確認してください。"

(English) Exception setting "<PropName>": "The property '<PropName>' cannot be
found on this object. Verify that the property exists and can be set."
```

This is *unlike* hashtable literals (`@{...}`, `[hashtable]@{...}`, `[ordered]@{...}`), which freely accept new keys at runtime, and *unlike* `New-Object PSObject` constructions, which can always be extended via `Add-Member`. The four pipeline scripts in this repository use the strictest form (`[pscustomobject]@{...}`) intentionally — it surfaces "you added a new feature in the script body but forgot to wire it into the `$Ctx` initialiser" defects loudly — but the defect surfaces as a runtime exception during the phase that first attempts the assignment, not at parse time or at script load. PSA2009 closes this loop at static-analysis time.

#### Detection

The rule walks the file in three passes:

1. **Initialiser pass**. Every top-level `$VarName = [pscustomobject]@{...}` initialiser is parsed brace-balanced (string-literal-aware), and the declared property names are harvested as the "declared" set for that variable name. Scope qualifiers (`$Script:`, `$Global:`, `$Local:`, `$Private:`) are stripped from the variable name so a `$Script:Foo = [pscustomobject]@{...}` initialiser and a later `$Foo.Bar = ...` assignment correlate correctly.

2. **`Add-Member` pass**. Two surface forms of `Add-Member -MemberType NoteProperty -Name <propname>` are recognised and the named property is *added* to the declared set for the target variable:
   - `$Var | Add-Member -MemberType NoteProperty -Name Foo -Value ...`
   - `Add-Member -InputObject $Var -MemberType NoteProperty -Name Foo -Value ...`
   This makes the rule compatible with the runtime-property-bag pattern used in `Get-BootSigningEnvironment` (where `$env` is initialised with the WDAC-related fields added via `Add-Member` later in the same function).

3. **Hashtable-form drop pass**. Any variable name that is *also* assigned somewhere in the file with a plain hashtable literal (e.g., `$result = @{...}` or `$tbl = [ordered]@{...}`) is conservatively *dropped* from tracking. This false-positive prevention is necessary because `psa.py` analysis is file-level rather than function-scope-aware, and the four scripts in this repository legitimately reuse local variable names like `$result` across multiple functions with different shapes. The rationale: if a variable name has *any* hashtable-form initialisation in the file, free runtime key addition is the dominant semantic and PSA2009 cannot reliably decide which assignment sites are sealed-object violations vs. legitimate hashtable extensions. Dropping the name is safer than warning.

4. **Assignment pass**. Every `$VarName.Property = ...` assignment site is checked against the declared set for `$VarName`. The rule fires when:
   - `$VarName` survived the hashtable-form drop pass (i.e., is exclusively a `[pscustomobject]` in this file), AND
   - The assignment operator is `=` (not `+=`, `-=`, `*=`, `/=`, or `==`), AND
   - `Property` is not in the declared set for `$VarName`.

The rule does *not* fire on:
- Well-known dynamic property bags: `$_`, `$Matches`, `$PSBoundParameters`, `$Host`, `$Error`, `$PSCmdlet`, `$MyInvocation`, `$args`, `$input`, `$this`. These are PowerShell engine-provided objects that legitimately accept dynamic property assignment patterns.
- Hashtable variables (per the drop pass).
- Variables that PSA2009 has never seen in a `[pscustomobject]@{...}` initialiser — those are typically parameters, pipeline output, or external object references where the surface contract is opaque to the analyzer.

#### Differences from related rules

- **PSA2001 (Undefined variable reference)** operates at the *variable* level: it flags a reference to `$Foo` when `$Foo` was never assigned. PSA2009 operates at the *property* level: it flags `.NewProp = value` when `NewProp` is not part of the variable's `[pscustomobject]` surface. The two rules are orthogonal — PSA2001 cannot detect the WhqlCoSignAnalysis bug because `$Ctx` is well-defined at every assignment site.
- **PSA2002 (Auto-variable shadowing)** operates at the variable level on PowerShell engine auto-variables. PSA2009 has nothing to do with auto-variables.
- **PSA8001 (Function-body drift)** operates at the cross-file function-body level. PSA2009 operates inside a single file.

#### Inline suppression

Suppress on the *assignment* line, not the initialiser:

```powershell
$Ctx.OptInPropertyForExperimentalFeature = $value  # psa-disable-line PSA2009
```

The recommended fix is almost always to add the missing `PropName = $null` declaration to the `[pscustomobject]@{...}` initialiser, not to suppress the warning. PSA2009 suppression should be reserved for cases where the assignment is to an inherited or extended object (e.g., a pscustomobject returned from another function which the author cannot easily annotate).

#### Reproducing the historical Chipset r72 P05 failure

To verify that PSA2009 catches the exact runtime defect reported on 2026-05-23:

```bash
# At the r72 / r38 / r18 / r20 baseline (before this release):
git checkout <commit-before-r73>
curl -sSL https://raw.githubusercontent.com/usui-tk/ai-generated-artifacts/main/scripts/python/powershell-static-analyzer/psa.py -o /tmp/psa-3.8.0.py
python3 /tmp/psa-3.8.0.py --include PSA2009 Deploy-AMDChipsetDriverOnWindowsServer.ps1
# Expected output: 2 warnings, at the happy-path assignment site and the catch-block fallback site.

# At the r73 / r39 / _ / r21 baseline (this release and forward):
python3 /tmp/psa-3.8.0.py --include PSA2009 Deploy-AMDChipsetDriverOnWindowsServer.ps1
# Expected output: 0 warnings.
```

### A.11.5d PSA2010 — Call to undefined function (added in `psa.py` v3.9.0)

**Rule code**: PSA2010.

**Severity**: error.

**Default**: enabled.

**Introduced**: `psa.py` v3.9.0 (Chipset r75 / Graphics r41 / NPU r19 / BthPan r23 release).

PSA2010 was added to close the static-analysis gap that allowed the `Find-Signtool` typo (documented in §D.32.2) to live undetected in the source through r71–r74. The rule walks the union of `function <Name>` definitions across every file in the scan set and flags any command-position Verb-Noun call whose name is neither in that union nor in `psa.py`'s built-in `KNOWN_CMDLETS` whitelist. The verb segment of the call name must be in `APPROVED_VERBS` for the call to be considered (false-positive defense against hyphenated domain-specific tokens like `Phantom-OK`, `Multi-OS`, `Chipset-Driver-CodeSign` that survive the string-stripping pass).

The `KNOWN_CMDLETS` whitelist ships with ≈200 entries covering Microsoft.PowerShell.Core / Management / Security / Utility / Diagnostics, CimCmdlets, PKI, PnpDevice, Defender, BitLocker, NetTCPIP / NetAdapter, SecureBoot, ScheduledTasks, Storage, Archive, WindowsCapability, ConfigCI, International, and WSMan. Consumers extend the whitelist via the new `.psa.config.json` field `psa2010_known_cmdlets` (a list of strings, an optional `Module\Name` prefix is permitted and stripped before lookup).

The four scripts in this repository pass PSA2010 at the r75 baseline with **0 findings**. Running `psa.py 3.9.0 --include PSA2010` against the four scripts at the r74 baseline reproduces 0 findings as well: the `Find-Signtool` typo had already been corrected in r74, so the only pre-existing PSA2010 target was already gone. PSA2010's value is forward-looking — it prevents the *next* `Find-Signtool`-class defect from shipping.

**Inline suppression**: `# psa-disable-line PSA2010 -- <reason>` on the call line. Use sparingly; the rule fires on real defects and most suppression sites should instead define the missing function or extend `psa2010_known_cmdlets`.

See the upstream [psa.py SPEC.md §4.9d](https://github.com/usui-tk/ai-generated-artifacts/blob/main/scripts/python/powershell-static-analyzer/SPEC.md#49d-psa2010--call-to-undefined-function) for the formal specification.

### A.11.5e PSA2011 — `Split-Path -LiteralPath ... -Parent` triggers AmbiguousParameterSet (added in `psa.py` v3.9.0)

**Rule code**: PSA2011.

**Severity**: error.

**Default**: enabled.

**Introduced**: `psa.py` v3.9.0 (Chipset r75 / Graphics r41 / NPU r19 / BthPan r23 release).

PSA2011 is the static-analysis counterpart of the runtime defect documented in §D.33.2 (Defect A). The rule walks each line (joining backtick continuations) and flags any `Split-Path` invocation containing BOTH the `-LiteralPath` switch AND the `-Parent` switch (in either order). On Windows PowerShell 5.1 ja-JP, this combination raises `AmbiguousParameterSet, Microsoft.PowerShell.Commands.SplitPathCommand` at runtime; the fix is to use `[System.IO.Path]::GetDirectoryName($path)` or `Split-Path -Path $path -Parent` (without `-LiteralPath`).

The four scripts in this repository pass PSA2011 at the r75 baseline with **0 findings**. Running `psa.py 3.9.0 --include PSA2011` against the same four scripts at the r74 baseline reproduces **3 findings** — one each on Chipset, Graphics, and BthPan, all at the `Split-Path -LiteralPath $InfPath -Parent` line at the head of `Get-InfDriverFileList` (the PSA8001-byte-identical sister site). NPU has 0 findings at both baselines because it does not define `Get-InfDriverFileList`. This reproduction is the gold-standard verification that PSA2011 catches the exact form of defect that surfaced in the 2026-05-25 bench cycle.

**Differences from PSA3005**: PSA3005 is the inverse pattern for `Start-Transcript -Path` (where `-Path` expands wildcards and breaks on special characters, so `-LiteralPath` is preferred at the cmdlet's own design level). PSA2011 is the opposite — for `Split-Path -Parent` on PS 5.1 ja-JP, `-LiteralPath` triggers the runtime parameter-binder bug, so `-Path` (or the .NET method) is preferred. The two rules apply to different cmdlets with different parameter-set ambiguities and are not contradictory.

**Inline suppression**: `# psa-disable-line PSA2011 -- <reason>` on the call line. Use sparingly; the rule fires on a real ja-JP runtime defect.

See the upstream [psa.py SPEC.md §4.9e](https://github.com/usui-tk/ai-generated-artifacts/blob/main/scripts/python/powershell-static-analyzer/SPEC.md#49e-psa2011--split-path--literalpath---parent) for the formal specification.

### A.11.6 Self-quality gates for `psa.py` (consumer-side usage)

Since `psa.py` 3.5.0 the canonical analyzer ships three built-in
**self-quality gates** that consumer repositories — including this one —
SHOULD exercise. The gates are runnable from the command line, exit
non-zero on any violation (suitable for CI), and require no third-party
dependencies beyond a Python 3 interpreter. See the upstream
[SPEC.md §12 "Self-quality gates"](https://github.com/usui-tk/ai-generated-artifacts/blob/main/scripts/python/powershell-static-analyzer/SPEC.md#12-self-quality-gates)
for the normative description; this subsection covers what this
repository, as a consumer, does with each gate.

#### Pillar 2: `--config-check` — validate `.psa.config.json`

Whenever this repository's `.psa.config.json` is edited (adding /
removing rule IDs, changing thresholds, adjusting the
`psa8001_ignore_functions` list, etc.) the editor MUST run:

```bash
python3 /path/to/psa.py --config-check .psa.config.json
```

Expected output on a clean configuration:

```
psa.py config-check report
  target : .psa.config.json
  issues : 0

  config is valid (0 issues found)
```

The check detects (and exits `2` on) every problem before any
PowerShell file is analyzed: unknown top-level keys, unknown rule IDs
in `enable` / `disable`, `enable` ↔ `disable` conflicts, malformed
JSONC, bad `severity` values, non-positive integer thresholds, and
uncompilable regex patterns in `psa8001_ignore_functions`. This is
strictly faster and clearer than discovering the same problem when a
later analyzer run silently ignores an unknown rule code.

#### Pillar 3: `--self-check` — verify `psa.py` is internally consistent

Whenever a new mainline `psa.py` is brought into the workflow per the
A.11 *Version policy* (after fetching the `VERSION` file and comparing
to the locally-used version), run:

```bash
python3 /path/to/psa.py --self-check
```

Expected output on an internally-consistent `psa.py`:

```
psa.py self-check report (SPEC.md ↔ RULES)
  SPEC.md  : /.../scripts/python/powershell-static-analyzer/SPEC.md
  rules    : 36 in RULES, 36 in SPEC.md §4
  SPEC.md and RULES are in sync (no drift detected)
```

A non-zero exit means the local copy of `psa.py` and its sibling
`SPEC.md` disagree on the rule set. The most common cause is having
fetched only `psa.py` (or only `SPEC.md`) instead of the whole
analyzer directory; refetch the entire
`scripts/python/powershell-static-analyzer/` tree from mainline as a
unit.

#### Pillar 1 — `test_psa_rules.py`: informative only

The upstream test suite covers every rule with positive / negative /
edge fixtures and runs unattended. This repository does **not** need
to run it directly: a passing upstream test suite is a precondition
of the upstream release, and the `--self-check` gate above will
detect any deserialization drift between that release and this
repository's view of it. Consumers MAY run
`python3 test_psa_rules.py` for diagnostic purposes (e.g., when
investigating a suspected analyzer bug), but it is not part of the
mandatory CI path for this repository.

#### Activation scenarios

The two consumer-relevant gates are invoked in the following
situations:

| Trigger | Gate to run | Why |
|:---|:---|:---|
| PR touches `.psa.config.json` | `--config-check` | Confirms the schema is still valid and no rule IDs were typoed. Fast (no PowerShell analysis runs). |
| PR refreshes a locally-cached `psa.py` | `--self-check` | Confirms the freshly-fetched `psa.py` and `SPEC.md` are from the same release (catches partial-fetch accidents). |
| Any PR touching PowerShell files | full `psa.py --config .psa.config.json *.ps1` | The normal static-analysis pass (unchanged by the introduction of the new gates). |
| Investigating a suspected `psa.py` false positive / negative | `test_psa_rules.py` (upstream) | Optional, diagnostic. |

These are additive: the existing "Required gate" (zero `errors` and
zero `warnings` across all four pipeline scripts under the canonical
`.psa.config.json`) remains the single hard requirement for landing a
PR. `--config-check` and `--self-check` are **cheap pre-flight
checks** that surface problems earlier than the full analysis pass
would.

### Inline suppression and project-local configuration

Two mechanisms are available for legitimate suppression:

1. **Inline (`# psa-disable-line <CODE> -- <reason>`)** — apply to a single
   line. The reason text is mandatory in this repository's coding style;
   suppressions without a reason will be rejected in code review.

2. **Project config (`.psa.config.json`)** — if a rule needs to be disabled
   for the whole project (for example, after a pre-existing plural-noun naming
   convention is grandfathered), drop a `.psa.config.json` next to the
   scripts:

   ```jsonc
   // .psa.config.json — rationale comments are mandatory
   {
     "disable": ["PSA6003"]
   }
   ```

   `psa.py` auto-discovers `.psa.config.json` in the current working
   directory. No such file is shipped in this repository as of this writing;
   the baseline above represents the unfiltered analyzer output.

### Common false positives and resolutions

| False positive | Resolution |
| -------------- | ---------- |
| `PSA2001` "undefined variable" for `$Script:Foo` set in a different function | Initialize at script load: `$Script:Foo = $null` |
| `PSA2003` "-match against bare `$variable`" where `$variable` is guaranteed non-null | Wrap with `[string]::IsNullOrEmpty($variable)` guard, or refactor to `[regex]::Match()` |
| `PSA3004` (empty `catch`) intentional silent failure | Add `# psa-disable-line PSA3004 -- <reason>` |
| `PSA5001` (plain-text password) where API requires plaintext (signtool / X509Certificate2) | `# psa-disable-line PSA5001 -- <reason>` at the `param()` line |
| `PSA6003` (plural function noun) for pre-existing function names | Disable at project level via `.psa.config.json`, or `# psa-disable-line PSA6003` at the function declaration |

If `psa.py` systematically misclassifies a pattern, raise an issue upstream
in the canonical repository
(`https://github.com/usui-tk/ai-generated-artifacts`) rather than
suppressing locally.

---

## A.12 Documentation Language Policy

### File set

| English      | Japanese       | Bilingual? | Content                                           |
| ------------ | -------------- | ---------- | ------------------------------------------------- |
| `README.md`  | `README.ja.md` | ✅ Yes     | End-user documentation                            |
| `TESTING.md` | (none)         | ❌ EN only | Cloud / physical regression testing               |
| `SPEC.md`    | (none)         | ❌ EN only | Developer specification (this document)           |
| `CHANGELOG.md` | (none)       | ❌ EN only | Chronological per-release change log              |
| `CONTRIBUTING.md` | (none)    | ❌ EN only | How to file issues, propose changes, run tests   |
| `SECURITY.md`     | (none)    | ❌ EN only | Vulnerability reporting and security guarantees   |
| `CODE_OF_CONDUCT.md` | (none) | ❌ EN only | Community behaviour expectations                  |

**Policy rationale**: Only `README.md` is duplicated into Japanese,
because it is the primary entry point for new readers. Specifications,
testing procedures, and release logs are maintained in English only
to avoid synchronization drift. Japanese readers are expected to use
the Japanese `README.ja.md` for orientation and then refer to the
English source-of-truth documents for technical detail.

This policy is applied repository-wide; the same pattern is used by
the sister repository
[`ai-generated-artifacts`](https://github.com/usui-tk/ai-generated-artifacts).

### Synchronization rule (README only)

Whenever `README.md` is updated, `README.ja.md` must be updated in the
same commit (or in an immediate follow-up commit referencing the
English commit hash). Maintain parity of:

- Section structure (same H2 / H3 headings)
- Tables (same columns)
- Code blocks (same content; Japanese files may use bilingual comments)
- Examples (same commands; localize the prose around them)

### Style for `README.ja.md`

- Technical terms in English are preserved in their English form (do not translate "phase", "decoration", "WDAC policy", "Workstation", "Server SKU", etc.)
- Particles use full-width forms: 「、」 「。」「・」 not "," "."
- Brackets: 「」 for emphasized terms, ` `` ` for code spans

### Mandatory disclaimer and license sections (both `README.md` and `README.ja.md`)

Each README must include:

1. A top-of-file ⚠️ Disclaimer block (USE AT YOUR OWN RISK, BitLocker warning, no warranty)
2. A bottom-of-file License section (MIT, with note that AMD's redistribution terms apply to AMD binaries downloaded at runtime, not to this repository)

---

## A.13 Development Workflow

### Iteration cycle

```
1. Write or modify code
2. python3 psa.py <script>.ps1            ← gate: 0 errors required
                                            (see A.11 for how to obtain psa.py)
3. Test on real AMD consumer hardware    ← per TESTING.md (chipset/graphics: physical
                                            Ryzen host with target devices; NPU script:
                                            physical Ryzen AI machine — see TESTING.md §3)
4. Update README.md + README.ja.md if behavior changed (per A.12, only the README
   is bilingual; other docs are English only). Update SPEC.md / TESTING.md /
   CHANGELOG.md (all English only) as appropriate.
5. Commit with revision number bump in $Script:ScriptVersion
```

> Because the pipeline targets AMD's consumer Ryzen / Radeon / NPU silicon, testing on non-target hardware (server-class EPYC, virtual machines without the target devices, etc.) cannot exercise the device-bind, driver-upgrade, or post-install verification paths. The Iteration cycle therefore mandates testing on real AMD consumer hardware.

### Revision discipline

Bump the revision number (e.g. `r<N>` → `r<N+1>`) on any commit that changes:

- Phase semantics (any of the 21 phases)
- Output format (CSV columns, log markers, banner layout)
- Parameter set (added / removed / renamed switches)

Cosmetic-only changes (typo fixes in messages, README rewording) do not require a revision bump.

### Where revision history lives

Per-revision change descriptions belong **exclusively** in
`CHANGELOG.md` at the repository root. The PowerShell script body
contains **only** current-behavior comments and current-rationale
references; it does NOT contain:

- End-of-file `REVISION HISTORY` comment blocks (enforced by
  `psa.py` `PSAP0004`).
- Inline `# rNN:` / `# rNN+:` / `# rNN-update:` revision-tag comments
  (enforced by `psa.py` `PSAP0003`).
- `# Before rNN` / `# From rNN on` / `# (rNN+) ...` revision-anchor
  prose. Use "Previously" / "Now" / no-anchor wording instead and
  refer the reader to `CHANGELOG.md` for the chronological context.

The architectural rationale behind each fix (root cause, fix design,
scope, upgrade impact) belongs in **Part D — Known Pitfalls & Lessons
Learned** of this SPEC. CHANGELOG.md cross-references back to Part D
where applicable.

This three-way split — script body for current behaviour, `CHANGELOG.md`
for chronological release log, `SPEC.md` Part D for architectural
rationale — keeps each document focused on a single responsibility
and avoids the "stale revision tag everywhere" problem that LLM-assisted
maintenance is especially vulnerable to.

#### Why this matters — LLM-assisted maintenance hazard

The three-way split is not aesthetic; it is a defensive design against
the failure mode most common in LLM-assisted maintenance of long-running
PowerShell scripts: the gradual accumulation of revision-anchor
commentary inside the script body. Each individual addition looks
helpful in isolation ("Added in the r71 release", "(r74) bug fix"),
but in aggregate they:

- duplicate information already authoritative in `CHANGELOG.md`,
- drift out of sync with `CHANGELOG.md` as the script evolves,
- encode a moving frame of reference (`rNN`) into a document
  (the script) that is supposed to describe the CURRENT state, and
- accumulate as untraceable "where did this come from" markers that
  readers cannot resolve without consulting Git history anyway.

`psa.py` `PSAP0003` / `PSAP0004` / `PSAP0005` are the automated
guardrail for these failures. Anything that escapes the guardrail
(by design, e.g. block comments `<# ... #>`, or by configuration,
e.g. relaxed-mode exemptions) is documented in the Enforcement
matrix below as residual human-review responsibility.

#### Enforcement matrix (introduced at the `psa-py-v4-llm-governance-baseline` r76/r42/r24/r20 release)

The mapping between policy items above and the rules that enforce
them is:

| Policy item | Example | Enforced by |
| --- | --- | --- |
| EOF `REVISION HISTORY` block | `# REVISION HISTORY` header + body | `PSAP0004` (opt-in, on for this repo) |
| Inline `# rNN:` tag | `# r42: bug fix in P05` | `PSAP0003` (opt-in, on for this repo) |
| Inline `# (rNN)` tag | `# NOTE (r42): description` | `PSAP0003` (opt-in, on for this repo) |
| Dash-decorated section tag | `# ---- r42: PHASE NAME ----` | `PSAP0003` (opt-in, on for this repo) |
| **`# Before rNN` / `# From rNN on` / etc.** | **`# Before r74, this used Find-Signtool.`** | **`PSAP0005` (opt-in, on for this repo, relaxed-mode migration baseline)** |
| **"Added in the rNN release" prose** | **`# (added with the r71 release)`** | **`PSAP0005` strict mode (currently exempted under relaxed mode; migration target)** |
| **"As of rNN, ..." prose** | **`# As of r74, V06 builds the lookup once.`** | **`PSAP0005` (fires even under relaxed mode)** |
| **SECTION header with rNN** | **`# SECTION r71: WHQL co-sign pre-detection`** | **`PSAP0005` strict mode (currently exempted under relaxed mode; migration target)** |
| **SPEC cross-reference with rNN** | **`# Phantom file (r65, SPEC §D.24): inspect`** | **`PSAP0005` strict mode (currently exempted under relaxed mode; migration target)** |
| Block comment `<# ... #>` containing rNN | (rare in this repo — `<#>` is used for `.SYNOPSIS` headers only) | **Residual human-review responsibility** (not scanned by PSAP0003/0004/0005, which are inline-comment scanners) |
| String literal containing rNN | `$Script:ScriptVersion = 'chipset-2026.05.25-r76'` | **Out of scope by design** (PSAP0002 governs the identifier-trio shape; `rNN` inside the string is correct here) |

#### Allowed / disallowed prose examples

The intent of the policy is to keep script-body comments **timeless**:
they should describe what the code does right now, without anchoring
the description to a specific historical release.

**Allowed (timeless wording — preferred)**:

- `# Build the OEM-name lookup set once. Threaded into every` ← describes current behaviour
- `# Earlier revisions called a non-existent Find-Signtool helper.` ← no rNN, narrative
- `# See SPEC §D.32 for the post-incident analysis (Find-KitTool fix).` ← points reader at the authoritative source
- `# Previously this function operated on an empty set; now it threads $ourInfSet through every call site.` ← "Previously / Now" anchor without rNN

**Allowed under relaxed mode (migration aid — currently in baseline, will be cleaned up release-by-release)**:

- `# SECTION r71: WHQL co-sign pre-detection` ← SECTION header (Exemption A)
- `# Phantom file reference detection (r65, SPEC D.24): inspect` ← SPEC cross-reference (Exemption B)
- `# Build the WHQL co-sign analysis (added with the r71 release)` ← Added-in-release phrasing (Exemption C)
- `# Earlier revisions called Find-Signtool, which was undefined before r74.` ← Earlier-revisions prose (Exemption D)

**Disallowed (fires `PSAP0003`)**:

- `# r74: build the lookup set once.` ← bare colon tag
- `# NOTE (r74): description.` ← parenthesised tag
- `# ---- r71: PHASE NAME ----` ← dash-decorated section tag

**Disallowed (fires `PSAP0005` even under relaxed mode)**:

- `# As of r74, V06 builds the lookup once.` ← forward-looking anchor, not exempt
- Any other `rNN` reference not matching one of the four
  relaxed-mode exemption patterns (SECTION header / SPEC cross-ref /
  Added-in-release / Earlier-revisions).

#### Migration roadmap (`PSAP0005` relaxed → strict)

The r76 / r42 / r24 / r20 release adopts `psa.py` 4.0.0's `PSAP0005`
with `psap0005_relaxed_mode: true`. This means the four exemption
patterns above are tolerated as the migration baseline. The
documented end-state is `psap0005_relaxed_mode: false` (strict), at
which point all `rNN` references in comment bodies are reported.

The migration is intentionally phased so that no single release has
to absorb the full ~60 prose rewrites at once. Each rewrite is
literal text editing that does not affect runtime behaviour, but
each one is also a PSA8001 byte-identity hazard if applied
inconsistently across sister scripts (Chipset / Graphics / BthPan).
Phasing the migration also lets each release CHANGELOG entry stay
small and reviewable.

Per-cycle migration steps:

1. **Pick one exemption category** (A / B / C / D) per cycle (the
   smallest-impact category is recommended first).
2. **Rewrite occurrences across all four scripts** with timeless
   wording, taking care to preserve byte-identity on any function
   listed in `psa8001_ignore_functions` exceptions and on
   cross-script-shared helpers.
3. **Re-run `psa.py --config .psa.config.json`** to confirm the
   per-script PSAP0005 count has dropped by the expected amount.
4. **Bump the per-script revision number** (Chipset → r77,
   Graphics → r43, etc.). The new release-line `ScriptTag` is the
   same `psa-py-v4-llm-governance-baseline` until the entire
   migration is complete; the migration-progress ScriptTag is
   reserved for the eventual strict-mode flip.
5. **CHANGELOG entry** lists exactly which exemption category was
   addressed in this cycle and the resulting PSAP0005 count.

The order of categories is at the maintainer's discretion. A
suggested order, easiest first:

1. **Exemption B (SPEC cross-reference)** — rewrite `(rNN, SPEC §D.YY)`
   into `(see SPEC §D.YY)`. The `rNN` is redundant: SPEC §D.YY
   itself is anchored to a single release.
2. **Exemption A (SECTION header)** — rewrite `# SECTION r71: ...`
   into `# SECTION: ...`. The `r71` is redundant: the SECTION block
   itself is anchored to the current line set of the file.
3. **Exemption D (Earlier-revisions prose)** — drop the `rNN`
   suffix from `... before r74` style sentences, leaving the
   "Earlier revisions" narrative intact.
4. **Exemption C (Added-in-release phrasing)** — most invasive,
   because the "added in the r71 release" phrasing often carries
   important rationale ("here is the design intent of this code
   block"). Rewrite to "This block was originally introduced to
   address ... See SPEC §D.NN for the design rationale." without
   the `rNN`.

Once all four categories have been cleaned up across all four
scripts, flip `psap0005_relaxed_mode` from `true` to `false` in
`.psa.config.json` and ship the strict-mode-baseline release.

### Reuse before invention

Before writing any new helper function:

1. Search the existing 4 scripts for an equivalent (`grep -rn 'function <NewName>' .`).
2. If found, copy verbatim from the most recent revision.
3. If not found, add it to the canonical helper section (under "Output helpers" or "Environment helpers" near the top of the file) so future scripts can reuse it.

---

## A.14 UEFI Secure Boot Baseline (cross-script feature)

A cross-cutting feature introduced to give operators consistent insight into the host's UEFI Secure Boot certificate rollout state. The feature is purely informational — UEFI-layer trust is independent of the OS-layer self-signing trust chain these scripts operate on — but it shares vocabulary and presentation across all four scripts so logs are correlatable.

### Function set (7 functions, 6 cross-script-identical + 1 per-script helper)

The first six functions are **byte-identical** across the chipset / graphics / NPU / BthPan scripts so they can be lifted verbatim from any sister and pasted into a new one:

| Function | Role |
|---|---|
| `Get-SecureBootCertificateInventory` | Enumerates db / KEK variables, reads `HKLM:\SYSTEM\CurrentControlSet\Control\SecureBoot\*` registry keys, queries the `Secure-Boot-Update` scheduled task via `Get-ScheduledTask` (locale-independent). |
| `Get-MsSecureBootExampleScriptPath` | Detects whether `%SystemRoot%\SecureBoot\ExampleRolloutScripts\Detect-SecureBootCertUpdateStatus.ps1` is present on this host. |
| `Invoke-MsSecureBootDetectScript` | Launches the MS sample script as a child PowerShell, captures stdout, falls back to in-stdout JSON extraction when the `-OutputPath` validator rejects absolute Windows paths. |
| `Get-SecureBootBaselineSnapshot` | Top-level entry point. Combines `.Embedded`, `.MsInfo` (with `.Data`, `.JsonPath`, `.ErrorMessage`), `.Health` (`Healthy` / `Warning` / `Critical` / `Unknown`), `.Reasons[]`. |
| `Show-SecureBootBaselineSnapshot` | Console renderer. Supports `-Compact` (one-line for P00 / V05 / I02) and full mode (V06). Callers control banners. |
| `Format-SecureBootBaselineForReport` | Plain-text formatter for the `inf_inventory_report.txt` appendix. |

The seventh function, `Get-OrEnsureSecureBootBaseline`, is **per-script** because state-management patterns differ:

| Script | State holder | Helper signature |
|---|---|---|
| Chipset | `$Ctx` (pscustomobject) | `param([Parameter(Mandatory)] $Ctx)` |
| Graphics | `$Ctx` (pscustomobject) | `param([Parameter(Mandatory)] $Ctx)` |
| NPU | `$Script:DetectedPlatform` (hashtable), `$Script:WorkRoot` | `param()` — accesses script scope directly |
| BthPan | `$Ctx` (pscustomobject) | `param([Parameter(Mandatory)] $Ctx)` (verbatim from chipset) |

The helper's contract is identical: return the cached snapshot when `(.MsInfo.JsonPath -is $null) -or (Test-Path -LiteralPath $JsonPath -and $JsonPath -like "$WorkRoot*")`; otherwise re-invoke into the current workspace. This handles three real-world cases:

1. First-ever run, no workspace exists at P00 time — `Get-SecureBootBaselineSnapshot` creates the workspace dir as a side effect via `New-Item -Force`.
2. `-CleanWorkRoot` specified, P01 wipes the workspace after P00 captured — P05 / V05 / V06 / I02 detect the missing diagnostic file and re-capture.
3. Subsequent run, workspace pre-existing with prior diagnostic file present — helper returns cached snapshot (fast path).

### Integration points (5 sites per script)

| Phase | Action | Trigger |
|---|---|---|
| **P00** | Initial capture + `Show-... -Compact` | Always (first call seeds `$Ctx.SecureBootBaseline` / `$Script:DetectedPlatform.SecureBootBaseline`) |
| **P05** | Re-capture if needed; pass snapshot to `Export-InfInventoryReport` (chipset / graphics) or inline writer (NPU); produce appendix in `inf_inventory_report.txt` | After CSV export, before phase footer |
| **V05** | Re-capture if needed; `Show-... -Compact`; surface `Warning` / `Critical` advisory | After dry-run plan summary |
| **V06** | Re-capture if needed; `Show-...` (full); displayed as Section 4 (chipset / graphics) or Section 5 (NPU, after the Ryzen AI reminder) | After existing sections |
| **I02** | Re-capture if needed; pre-check display; cross-reference with planned WDAC / testsigning path; advisory only (never blocks) | Between AS-IS state display and path decision |

### MS sample script integration

Microsoft's `Detect-SecureBootCertUpdateStatus.ps1` (delivered via KB5089549 on Windows 11, KB5087544 / KB5088863 on Windows 10, WS2025 equivalent since 2026-05-12) is launched as a child PowerShell. Two robustness measures:

- **`-OutputPath` validator bypass**: MS's regex `[<>:"|?*]` rejects every absolute Windows path (because `:` follows the drive letter). When validation fires, the MS script falls back to stdout JSON. Our `Invoke-MsSecureBootDetectScript` always tries the file path first, then extracts JSON from captured stdout (regex-anchored to known keys: `Hostname` / `UEFICA2023Status` / `SecureBootEnabled`).

- **Diagnostic file persistence**: raw stdout is saved to `<WorkRoot>\secureboot_ms_sample\detect_stdout.log`; the recovered JSON to `detect_stdout_extracted.json`.

### Health classification

| Class | Conditions |
|---|---|
| `Healthy` | Secure Boot ON; `UEFICA2023Status` = `Updated` or `Not Applicable`; no `UEFICA2023Error`; scheduled task `Ready` |
| `Warning` | Secure Boot ON; rollout in flight (`NotStarted` / `Started` / `Pending`); OR scheduled task disabled; OR MS sample reports rollout-event diagnostics |
| `Critical` | Secure Boot OFF; OR non-zero `UEFICA2023Error` |
| `Unknown` | None of the diagnostic sources were readable |

I02 surfaces the class but never blocks — UEFI-layer cert rollout is independent of OS-layer signing trust.

### Maintenance rule

When adding a fifth sister script, the 6 cross-script-identical functions are lifted verbatim. The per-script helper is rewritten to match the new script's state-holder pattern. See B.1 / B.2 / B.4 (chipset / graphics / BthPan use `$Ctx`) and B.3 (NPU uses script scope) for the two known patterns.

---

# Part B — Script-specific Specifications

## B.1 Chipset script (`Deploy-AMDChipsetDriverOnWindowsServer.ps1`)

### Identification

- **Current revision**: see [CHANGELOG.md](./CHANGELOG.md) (single source of truth)
- **Workspace**: `C:\Temp\Workspace_AMD-Chipset\`
- **Self-signed cert subject**: `CN=AMD Chipset Driver Self-Sign (WS2025 Lab, At Own Risk)`
- **Self-signed cert files**: `cert\AMD-Chipset-Driver-CodeSign.{pfx,cer}`
- **WDAC policy GUID**: fixed `503860EA-8837-4169-9BC4-19E5AEED721B`; overridable via `-WdacPolicyGuid`. Legacy deploys used a dynamically-generated PolicyId recorded in `cert\AmdSuppPolicyId.txt`.
- **WDAC SupplementsBasePolicyID**: `{A244370E-44C9-4C06-B551-F6016E563076}` (Windows-shipped default base CI policy); overridable via `-WdacBasePolicyGuid`

### Inputs

- AMD Chipset Software installer EXE (~75 MB), discovered via probe of <https://www.amd.com/en/support/category/chipsets>
- Optional: `-InstallerUrl <url>` to bypass URL discovery
- Optional: `-AmdLandingUrls` / `-AmdFallbackUrl` for URL discovery override (used when AMD reorganises their support pages)

### Platform-detection logic

`Get-AmdChipsetPlatform` heuristic translates CPU name (`Win32_Processor.Name`) to a platform codename:

| CPU pattern                       | Codename       | Family    |
| --------------------------------- | -------------- | --------- |
| `Ryzen.*4\d00U?\b`                | Renoir         | 4000      |
| `Ryzen.*5\d00U?\b`                | Cezanne        | 5000      |
| `Ryzen.*5\d25\b`                  | Barcelo        | 5000      |
| `Ryzen.*5\d35\b`                  | Barcelo-R      | 5000      |
| `Ryzen.*6\d00U?\b`                | Rembrandt      | 6000      |
| `Ryzen.*7\d40\b`                  | Phoenix        | 7000      |
| `Ryzen.*8\d40\b`                  | Hawk Point     | 8000      |
| `Ryzen AI 3\d0`                   | Strix Point    | AI 300    |
| `Ryzen AI Max 3\d0`               | Strix Halo     | AI Max 300|

### Phase quirks

- **P03 / P04**: Multi-strategy installer extraction with three fallback layers (see "AMD 8.x installer architecture" below for the architecture that drives this):
    - **Strategy 1/3**: 7-Zip auto-detect. Works for AMD 6.x and earlier self-extracting EXEs.
    - **Strategy 2/3**: InstallShield `/a` administrative install + recursive `msiexec /a`. Standard path for AMD 8.x+ installers (NSIS outer + InstallShield SFX inner). Emits a per-OS-variant INF-coverage diagnostic post-extraction.
    - **Strategy 3/3**: Launch installer with `/S`, watch `C:\AMD\` for the extraction directory, terminate before install runs. Fragile final fallback retained for unrecognised formats.
- **P05**: INFs are classified by source variant: `W11x64` (Win11) / `WTx64` (Workstation x64) / `WT6A_INF` / `WT64A`. Only the OS-matching variant is selected for the pipeline (per `Get-PreferredAmdSourceVariants`).
- **P06**: PSP driver (`amdpsp.inf`) is **never patched** without an explicit BitLocker warning — see Disclaimer §5.

### Known constraints

- 5-year cert validity (hard-coded in P07).
- Patched drivers retain their AMD-published `DriverDate`; comparing AS-IS vs TO-BE uses `.Date` truncation to avoid timezone false positives (see Part D D.1).

### AMD 8.x installer architecture

Starting with AMD Chipset Software 8.x (first observed in version 8.02.18.557, distributed early 2026), AMD switched the installer bootstrapper to a two-layer wrapper that defeats 7-Zip-based extraction. The script's multi-strategy extraction (introduced for AMD 8.x) is designed against this architecture; the layered structure is documented here so that extraction failures can be diagnosed.

#### Two-layer wrapper structure

The downloaded `amd_chipset_software_*.exe` (~78 MB) is an NSIS self-extracting shell wrapping an InstallShield SFX:

```
amd_chipset_software_8.02.18.557.exe   (~78 MB)
└── Outer layer: NSIS self-extracting EXE
    │   (7-Zip CAN extract this layer)
    │
    ├── AMD_Chipset_Drivers.exe        ← inner installer (~75 MB)
    │   └── Inner layer: InstallShield SFX (ISSetupStream format)
    │       │   (7-Zip CANNOT extract; only InstallShield can: /a switch)
    │       │
    │       ├── AMD_Chipset_Drivers.msi   (parent, ARPSYSTEMCOMPONENT=1)
    │       │
    │       └── Chipset_Software\
    │           ├── AMD-GPIO2-Driver.msi
    │           ├── AMD-PCI-Driver.msi
    │           ├── AMD-PSP-Driver.msi
    │           ├── AMD-SMBus-Driver.msi
    │           ├── ... (35 sub-MSIs total in 8.02.18.557)
    │           └── AMD-WBD-Driver.msi
    │
    └── (auxiliary support files)
```

#### After full extraction: OS-variant directory layout

Each sub-MSI, when expanded via `msiexec /a`, unpacks its driver binaries into three OS-variant subdirectories per driver:

```
<DestinationPath>\AMD\Chipset_Software\Binaries\<DriverName>\
    ├── W11x64\          ← Windows 11 / WS2022 / WS2025 (build >= 22000)
    │   ├── <driver>.inf
    │   ├── <driver>.sys
    │   ├── <driver>.cat
    │   └── ...
    ├── WTx64\           ← Windows 10 / WS2019 / WS2016 (build < 22000, 64-bit)
    │   └── (older driver versions for the same hardware)
    └── WTx86\           ← 32-bit Windows (never applicable to Server SKUs)
        └── (32-bit driver versions; included for completeness)
```

#### OS variant selection logic

`Get-PreferredAmdSourceVariants -OsContext $Ctx.Os` decides which variant subdirectory feeds the P05 / P06 / I03 pipeline. The decision is OS-build-driven, not heuristic:

| Host OS | Build | Base Windows | Preferred variant | Rationale |
| --- | --- | --- | --- | --- |
| Windows Server 2025 | 26100 | Windows 11 24H2 | `W11x64` | Kernel-equivalent to Win11 24H2; supports Pluton / PMF / USB4 / 3D V-Cache |
| Windows Server 2022 | 20348 | Iron-wave | `W11x64` | Closer to W11 ABI than W10 |
| Windows Server 2019 | 17763 | Redstone 5 | `WTx64` | Predates Win11; uses older driver ABI |
| Windows Server 2016 | 14393 | Threshold | `WTx64` | Threshold era = WTx64 by definition |

Other OS contexts fall back to `@('W11x64','WTx64')` (try both). The AMD 8.x extraction unpacks all three variants and lets the pipeline pick; this isolation keeps the extraction layer format-agnostic so future host-OS changes only need updates to `Get-PreferredAmdSourceVariants`.

#### AMD's actual driver registration logic (key finding)

Each sub-MSI's `CustomAction` table stores three OS-specific VBScript binaries as BLOBs in the `Binary` table (key `NewBinary20`):

- `Install_Driver_W11x64` (CustomAction type 7238 = VBScript in Binary)
- `Install_Driver_WTx64`
- `Install_Driver_WTx86`

A separate `GetOSBuildnum_22000` action (type 38, inline VBScript) queries `Win32_OperatingSystem.BuildNumber` and sets MSI property `W11BUILDNUM=1` when build >= 22000. The `InstallExecuteSequence` uses `W11BUILDNUM` to pick which of the three variant scripts to run.

The VBScript itself (extracted from the GPIO2 sub-MSI in 8.02.18.557) contains only:

```vbs
Function Install_Driver_W11x64()
    Set objShell = CreateObject("WScript.Shell")
    Dim StrDir : StrDir = objShell.ExpandEnvironmentStrings("%SYSTEMDRIVE%")
    Dim strcmd : strcmd = StrDir & "\Windows\System32\pnputil.exe" _
        & " /add-driver " _
        & chr(34) & StrDir & "\AMD\Chipset_Software\Binaries\GPIO2 Driver\W11x64\amdgpio2.inf" & chr(34) _
        & " /install"
    iLogMessage "Install_Driver_W11x64 : " & strcmd
    CreateObject("Wscript.Shell").Run strcmd, 0, True
End Function
```

In other words: AMD's chipset installer performs **no hardware detection at all**. It calls `pnputil /add-driver /install` for the OS-appropriate INF and lets the Windows kernel match each INF's `[Manufacturer]` Hardware IDs against the actual PnP device inventory. Devices that don't match remain unmatched; that is the expected behaviour, not a defect of either the AMD installer or this script.

The script's I03 phase reproduces this exact pattern (`pnputil /add-driver <patched.inf> /install`), with the addition of self-signature handling required for Windows Server SKUs.

#### Why 7-Zip fails on the inner layer

The InstallShield SFX wraps the parent MSI and sub-MSIs in an `ISSetupStream`-formatted stream. This format is proprietary to InstallShield and is not a standard archive format. 7-Zip's `PE` handler identifies the EXE wrapper and exits cleanly (exit 0), but extracts only the wrapper's resource section, leaving an empty result tree (no `.msi` / `.inf` files). The only known way to unpack `ISSetupStream` content is via InstallShield's own `/a` administrative-install switch.

7-Zip's failure mode is silent (exit 0 with no payload), which is why the script's `_HasPayload` success criterion guards each strategy with a presence check for `.inf` / `.msi` / `.cab` files rather than relying on the exit code alone.

#### Why /a admin install is safe (no drivers installed at extract time)

Both InstallShield `/a` and `msiexec /a` are designed to extract MSI contents WITHOUT running install-side CustomActions:

- `/a` runs `AdminExecuteSequence`, which is limited to `FileCost`, `InstallFiles`, and similar file-copy operations.
- `/a` does **not** run `InstallExecuteSequence`, where the driver-registration `CustomAction`s live (`Install_Driver_W11x64` etc.).

Empirical verification on AMD 8.02.18.557 (Renoir / WS2025):

- No driver entries appear in `Win32_PnPSignedDriver` after `/a`
- No `C:\AMD\` side-effects
- No sub-installer processes spawn
- Only files are written to `TARGETDIR`; nothing executes

#### 35 sub-MSIs in 8.02.18.557 (informational)

The sub-MSIs ship in the parent MSI's `ISChainPackage` table. Grouped by hardware applicability (Renoir = Zen 2 Mobile, 2020-era CPU; used here as the reference older platform):

| Category | Sub-MSI features (Feature.Name) | Renoir applicability |
| --- | --- | --- |
| Core chipset (always present) | `GPIO2`, `GPIO3` (Promontory), `PCI`, `PSP`, `SMBUS`, `RYZENPPKG`, `I2C`, `UART`, `INTERFACE`, `FILTERUSB` | High |
| Power Management Framework (newer-hw) | `RPMF6000` (6000-series), `PHPMF7040` (7040-series), `TPMF7736` (7736-series), `SPMF8000` (8000-series), `NAIPMF300` / `TAIPMF300` / `AIPMFMAX300` (AI 300 series) | None (Phoenix Point and later only) |
| Sensor Fusion Hub | `SFHDRVR`, `SFHI2C`, `SFH1.1` | Partial |
| Modern platform features | `USB4CM`, `CVAC` (3D V-Cache Optimizer), `MSFT1` / `MSFT2` (Pluton TPM), `HSMP`, `S0I3`, `MAIL` (Mailbox Drv), `UPEP` (Micro-PEP), `APPCOMPATDB`, `AS4ACPI`, `CIR`, `IOV_WT`, `OEMPF` (Provisioning), `PPM`, `WBD` | Low (mostly Phoenix Point and later) |

Older AMD platforms (Renoir, Cezanne) will produce fewer device-driver matches in I04 because most newer-platform sub-MSIs carry INFs whose Hardware IDs don't exist on those CPUs. **This is expected and not a script defect.** On X13 Gen 1 (Ryzen 5 PRO 4650U / Renoir), roughly 5-8 of the 35 driver packages typically match real devices; the remaining packages remain in the driver store but inactive.

---

## B.2 Graphics script (`Deploy-AMDGraphicsDriverOnWindowsServer.ps1`)

### Identification

- **Current revision**: see [CHANGELOG.md](./CHANGELOG.md) (single source of truth)
- **Workspace**: `C:\Temp\Workspace_AMD-Graphics\`
- **Self-signed cert subject**: `CN=AMD Graphics Driver Self-Sign (WS2025 Lab, At Own Risk)`
- **Self-signed cert files**: `cert\AMD-Graphics-Driver-CodeSign.{pfx,cer}`
- **WDAC policy GUID**: fixed `85336828-3080-41C5-81EC-FD587DC090D3`; overridable via `-WdacPolicyGuid`. Legacy deploys used a dynamically-generated PolicyId recorded in `cert\AmdSuppPolicyId.txt`.
- **WDAC SupplementsBasePolicyID**: `{A244370E-44C9-4C06-B551-F6016E563076}` (Windows-shipped default base CI policy); overridable via `-WdacBasePolicyGuid`. A legacy graphics revision used a non-standard `{B355481F-55DA-5D17-C662-07127F674187}` (see Part D D.8).

### Inputs

- AMD Adrenalin Edition installer EXE (~600 MB), discovered via probe of <https://www.amd.com/en/support/category/graphics>
- Two branches: Vega-Polaris Legacy (~19 INFs) and Main Adrenalin (~67 INFs for Phoenix+).
- Optional: `-InstallerUrl <url>` to bypass URL discovery
- Optional: `-AmdLandingUrls` / `-AmdFallbackUrl` for URL discovery override

### Platform-detection logic

`Get-AmdGraphicsPlatform` uses `Win32_VideoController` enumeration first, then CPU name (for integrated GPUs). Branch selection (Vega-Polaris Legacy vs Main Adrenalin) is based on the GPU PCI Device ID range.

### Phase quirks

- **P03**: AMD periodically reorganises their support pages; probe failures emit detailed candidate URL list and fall back to `-InstallerUrl`.
- **P05**: HD Audio (`hdaudio.inf`), Audio CoProcessor (`acp.inf`), USB-C UCSI (`ucsi.inf`), and Display (`display.inf`) INFs are all included by default; some are conditionally skipped based on Win32_VideoController vendor.

### Known constraints

- HDMI Audio (`hdaudio.inf`) provider names vary across Adrenalin branches; the INF inventory filter uses Class = `MEDIA` rather than provider name for stability.

---

## B.3 NPU script (`Deploy-AMDNpuDriverOnWindowsServer.ps1`)

### Identification

- **Current revision**: see [CHANGELOG.md](./CHANGELOG.md) (single source of truth)
- **Workspace**: `C:\Temp\Workspace_AMD-NPU\`
- **Self-signed cert subject**: `CN=AMD NPU Driver Self-Sign (WS2025 Lab, At Own Risk)`
- **Self-signed cert files**: `cert\AMD-NPU-Driver-CodeSign.{pfx,cer}`
- **WDAC policy name**: `AMD-NPU-Driver-SelfSign-Lab`
- **WDAC policy GUID**: fixed `8B2C4F12-1E9D-4D7B-A4F8-9C7E2B6A53D1` (per-script stable hardcoded value, used to identify the policy across runs for clean removal); overridable via `-WdacPolicyGuid`

### Inputs (4-tier resolution)

```
Tier 1 ★ : -InstallerUrl <url>                        explicit URL
Tier 2   : -AmdAccountUser/-AmdAccountPassword         account.amd.com auto-download (BEST-EFFORT, disabled by default)
Tier 3   : EULA-gated direct fetch probe               typically falls through
Tier 4 ★ : -OfflineZip <path>  OR  sibling NPU_RAI*_WHQL.zip  RECOMMENDED
```

Tier 4 (`-OfflineZip`) is the recommended pattern because account.amd.com is a JavaScript-driven SPA (verified 2026-05-10) and Tier 2 is unlikely to succeed without browser-based form interaction.

### NPU codename detection (PCI HWID + REV byte)

`Get-AmdNpuPlatform` uses `pnputil /enum-devices /bus PCI /deviceids` and matches against:

| Codename       | Short | PCI HWID                                   | CPU disambiguator      |
| -------------- | ----- | ------------------------------------------ | ---------------------- |
| Phoenix        | PHX   | `PCI\VEN_1022&DEV_1502&REV_00`             | Ryzen 7040 / `7\d40\b` |
| Hawk Point     | HPT   | `PCI\VEN_1022&DEV_1502&REV_00`             | Ryzen 8040 / `8\d40\b` |
| Strix Point    | STX   | `PCI\VEN_1022&DEV_17F0&REV_00/10/11`       | Ryzen AI 300 / AI Max 300 |
| Krackan Point  | KRK   | `PCI\VEN_1022&DEV_17F0&REV_20`             | Ryzen AI 200           |

Phoenix and Hawk Point share `DEV_1502&REV_00`; CPU name (`Win32_Processor.Name`) disambiguates them.

### Independent versioning axes (driver vs Ryzen AI Software)

NPU kernel driver versioning is **completely independent** from Ryzen AI Software versioning. AMD documents:

- **NPU drivers**: 32.0.203.280 (`NPU_RAI1.5_280_WHQL.zip`) or 32.0.203.314 (`NPU_RAI1.6.1_314_WHQL.zip`)
- **Ryzen AI Software**: 1.5 / 1.6.1 / 1.7 / 1.7.1 (latest)

Both NPU driver ZIPs work with current RAI 1.7.1. AMD recommends "always use the latest RAI Software" but does not couple the driver version.

The script exposes this as two independent parameters:

- `-NpuDriverPackage <NPU_RAI1.5_280 | NPU_RAI1.6.1_314 | latest>`
- `-RyzenAiSoftwareVersion <1.5 | 1.6.1 | 1.7 | 1.7.1 | latest>`

Compatibility evaluation is a **separate** axis (`Test-NpuDriverRaiCompatibility`) that asserts driver build >= minimum for the chosen RAI version (currently `32.0.203.280` for all RAI versions).

### Phase quirks

- **P00**: Emits NPU-specific OS support warning ("Ryzen AI Software is Windows-11-only per AMD docs").
- **P03**: Runs 4-tier installer resolution before NPU detection (because resolution determines the ZIP filename to download, which is independent of the host's NPU codename).
- **I00**: Requires explicit `I AGREE` confirmation for AMD Ryzen AI EULA (not optional).
- **I04**: Displays Ryzen AI Software guidance with installer download URL, prereqs, and verification steps (Miniforge + conda env + `quicktest.py`).

### Known constraints

- `account.amd.com` is a JavaScript-driven SPA; PowerShell form-POST authentication (Tier 2) is documented as best-effort and will likely fail. Always prefer Tier 4 (`-OfflineZip`).
- Ryzen AI Software (user-mode stack) is officially Windows-11-only; on Server 2025 the kernel driver loads but inference workloads may fail at the user-mode layer.

---

## B.4 BthPan script (`Deploy-MSBthPanInboxOnWindowsServer.ps1`)

### Identification

- **ScriptVersion**: see [CHANGELOG.md](./CHANGELOG.md) (single source of truth)
- **ScriptTag**: see [CHANGELOG.md](./CHANGELOG.md) (single source of truth)
- **Default workspace**: `C:\Temp\Workspace_Microsoft-BthPan`
- **Cert subject CN**: `Microsoft BthPan Driver Self-Sign (<OsCode> Lab, At Own Risk)` (where `<OsCode>` is `WS2016` / `WS2019` / `WS2022` / `WS2025` depending on the host)
- **Cert filename**: `MS-BthPan-Driver-CodeSign.{pfx,cer}`
- **WDAC supplemental policy XML/CIP filenames**: `MsBthPanSelfSignedSupplementalPolicy.{xml,cip}` (stored in `<workspace>\cert\`)
- **WDAC supplemental policy marker file**: `cert\MsBthPanSuppPolicyId.txt` (records the deployed PolicyId for Cleanup)
- **WDAC supplemental policy GUID** (default, fixed): `A6E72D4F-3B98-4C5A-9E1D-7F8B2A4C6E5D` — newly minted for this script, does not collide with the Chipset (`503860EA-…`), Graphics (`85336828-…`), or NPU (`8B2C4F12-…`) scripts.
- **WDAC supplemental policy name**: `MS-BthPan-Driver-SelfSign-Lab`

### Driver source — DriverStore, not download

Unlike the AMD sister scripts which fetch installers from `drivers.amd.com` or AMD account portals, the BthPan script's driver source is the host's own DriverStore staging directory:

```
C:\Windows\System32\DriverStore\FileRepository\bthpan.inf_amd64_<hash>\
├── bthpan.inf       Microsoft inbox INF (Workstation-decorated only)
├── bthpan.sys       Microsoft-signed binary
├── bthpan.PNF       precompiled INF cache
└── <localized MUI resources>
```

The `Get-BthPanDriverStoreSource` helper enumerates `bthpan.inf_amd64_*` directories under `FileRepository`, filters to those that contain both `bthpan.inf` AND `bthpan.sys` AND at least one `.cat`, and picks the most recently modified directory. On a typical host there is exactly one such directory; multiple copies can appear after a Windows feature update.

**The Microsoft-signed bthpan.sys is never modified.** Only the catalog is re-signed (because the INF has been patched, breaking the original catalog's INF-content hash attestation).

### The root cause this script addresses

Microsoft's inbox `bthpan.inf` declares only the Workstation decoration `NTamd64...1`:

```ini
[Manufacturer]
%MfgName% = Msft,NTamd64...1
```

The fifth segment (`1`) is the ProductType restriction (1 = Workstation, 2 = Domain Controller, 3 = Server). On a Windows Server SKU (ProductType=3), the PnP matcher discards every `Msft.NTamd64...1` entry during HWID resolution. As a result:

1. `bthpan.inf`'s `[BthPan.Install]` section (AddService, CopyFiles, AddReg) never runs.
2. `bthpan.sys` is never copied to `C:\Windows\System32\drivers`.
3. The `BthPan` service is never registered.
4. No Bluetooth PAN network adapter (Class=Net) is ever created.

### Phantom OK vs True Resolution

A particularly subtle failure mode: even on Server SKUs, `BTH\MS_BTHPAN` may show `Status=OK` in Device Manager. This is because the generic `bth.inf` proxy-matches the device. However, `bthpan.sys` is NOT actually loaded and the `BthPan` service is NOT actually running — PAN networking functionality is still completely broken.

V05 / V06 / I04 use `Get-PnpDeviceProperty` to read three DEVPKEY properties and classify the state:

| Property                       | Phantom OK             | True Resolution         | Unknown (code 28) |
| ------------------------------ | ---------------------- | ----------------------- | ----------------- |
| `DEVPKEY_Device_DriverInfPath` | `bth.inf`              | `oem<N>.inf`            | (empty)           |
| `DEVPKEY_Device_Class`         | `Bluetooth`            | `Net`                   | (empty)           |
| `DEVPKEY_Device_Service`       | (empty)                | `BthPan`                | (empty)           |
| Status                         | OK                     | OK                      | Error             |

The script ALSO checks three runtime artifacts (`Test-BthPanRuntimeArtifacts`):

- `C:\Windows\System32\drivers\bthpan.sys` exists
- `HKLM:\SYSTEM\CurrentControlSet\Services\BthPan` registry key exists
- A `NetAdapter` with `InterfaceDescription` matching `Bluetooth.*Personal Area Network` is enumerable via `Get-NetAdapter`

I04 declares `*** TRUE RESOLUTION ACHIEVED ***` only when **all** of the following hold:

1. Every `BTH\MS_BTHPAN*` device classifies as `True` (or device count is zero)
2. `bthpan.sys` is present in `System32\drivers`
3. `BthPan` service key is registered

### INF patching strategy

`Edit-InfForServer` (verbatim from the Chipset script) is used to mirror the Workstation decoration `NTamd64...1` with `NTamd64...3`:

```ini
; Before patching
[Manufacturer]
%MfgName% = Msft,NTamd64...1

; After Strategy A (default)
[Manufacturer]
%MfgName% = Msft,NTamd64...1,NTamd64...3
```

The `ConvertTo-ServerDecoration` helper parses `NTamd64...1` (`NT`+`amd64`+`.`+empty+`.`+empty+`.`+empty+`.`+`1`) into a 4-element array `['NTamd64','','','1']`, sets `parts[3]='3'`, and re-joins to produce `NTamd64...3`. This generates exactly one new server decoration entry which covers all Server SKUs (ProductType=3 is build-agnostic).

**Strategy B (optional)**: `Add-BthPanExplicitServerDecorations` additionally appends four build-explicit decorations:

```ini
[Manufacturer]
%MfgName% = Msft,NTamd64...1,NTamd64...3,NTamd64.10.0...14393,NTamd64.10.0...17763,NTamd64.10.0...20348,NTamd64.10.0...26100
```

This provides a deterministic PnP-ranking tie-break when multiple bthpan packages compete for the binding slot but requires manual update for any future Server SKU build that Microsoft ships.

### Catalog generation — four-SKU simultaneous targeting

P08 invokes `inf2cat` with `/os:Server2025_X64,ServerFE_X64,ServerRS5_X64,Server2016_X64` so that a single signed catalog covers all four Windows Server SKUs. The script first probes the installed `inf2cat.exe` for its supported `/os:` tokens via `Get-Inf2catSupportedOsValues` and intersects the desired list with what inf2cat actually understands. If the full 4-SKU list fails (rare; usually because `Server2016_X64` is not recognised by very old inf2cat builds), the script retries without `Server2016_X64`.

### Phase quirks (differences from sister scripts)

| Phase | BthPan-specific behaviour                                                                                |
| ----- | -------------------------------------------------------------------------------------------------------- |
| P02   | 7-Zip is NOT required (no archive extraction). Only SDK (signtool) + WDK (inf2cat) are needed.           |
| P03   | No network calls. Locates `bthpan.inf_amd64_*` in DriverStore via `Get-BthPanDriverStoreSource`.         |
| P04   | Simple file copy from DriverStore to `workspace\extracted\bthpan\`. No archive extraction.               |
| P05   | Single-row CSV (one INF: `bthpan.inf`). No source-variant disambiguation.                                |
| P06   | Strategy A by default (single `NTamd64...3` mirror); Strategy B optional via `-DecorationStrategy B`.    |
| P08   | Targets all four Server SKUs (`Server2025_X64,ServerFE_X64,ServerRS5_X64,Server2016_X64`) simultaneously.|
| V05   | Diagnoses every `BTH\MS_BTHPAN*` instance; classifies Phantom/True/Unknown.                              |
| V06   | Sections: device disposition, runtime artifacts, existing oem*.inf mappings, risk classification, UEFI Secure Boot baseline. No per-device "AS-IS / TO-BE" matrix (only one driver, one HWID). |
| I03   | After `pnputil /add-driver /install`, runs `pnputil /scan-devices` to force PnP re-evaluation and rebind from `bth.inf` proxy match to patched `oem*.inf`. |
| I04   | Verdict: `*** TRUE RESOLUTION ACHIEVED ***` requires per-device classification + runtime artifact checks. Phantom OK is explicitly flagged as a FAIL. |

### Parameters

The BthPan script intentionally does NOT expose:

- `-InstallerUrl`, `-AmdLandingUrls`, `-AmdFallbackUrl` (Chipset/Graphics-specific — there is no AMD installer to fetch)
- `-OfflineZip`, `-AmdAccountUser`, `-AmdAccountPassword`, `-ForceAmdAccountAuth` (NPU-specific)
- `-NpuOverride`, `-NpuDriverPackage`, `-RyzenAiSoftwareVersion`, `-AssumeIfMissing` (NPU-specific)
- `-CertValidityYears` (hard-coded per OS context: 3 years on WS2016, 5 years on WS2019+)

It DOES expose:

- All common parameters per A.6 (`-Action`, `-OnlyPhases`, `-CleanWorkRoot`, `-AllowWorkstationInstall`, `-UseTestSigning`, `-WorkRoot`, `-PfxPassword`, `-WdacPolicyGuid`, `-WdacBasePolicyGuid`)
- `-Help` / `-h` / `-?` (alias-bound switch)
- `-References` (curated Microsoft Learn link index)
- `-Force` (bypass cached Phase markers)
- `-TimestampUrl` (default `http://timestamp.digicert.com`)
- **`-DecorationStrategy A|B`** — BthPan-specific. A (default): `NTamd64...3` only; B: also adds `NTamd64.10.0...14393 / 17763 / 20348 / 26100` per-build entries.

### Known constraints

- Requires a bound Bluetooth host controller. If the host controller itself is unknown-device, the script's V05 / V06 will still run (and report no `BTH\MS_BTHPAN` device present), but `Install` will not produce a functional outcome until the host controller is bound first.
- `pnputil /scan-devices` after `/add-driver` *usually* triggers an immediate rebind from `bth.inf` to the patched `oem*.inf`. In some cases (observed on WS2025 build 26100.32860), a reboot is required for PnP to fully re-evaluate the device. I04 detects this case and reports `*** TRUE RESOLUTION NOT YET ACHIEVED ***`; re-running the same `-Action Install` command after reboot resolves the binding.
- The script does NOT cover Bluetooth host controller drivers (Intel AX2xx, Realtek RTL88xx, etc.). Vendor host controller drivers must be installed via their respective vendor channels first.
- The script does NOT remove inbox `bthpan.inf` from `C:\Windows\INF\`. The patched `oem*.inf` simply outranks the inbox INF in PnP ranking due to its newer effective decoration (`NTamd64...3` matches ProductType=3 exactly, while inbox `NTamd64...1` is filtered out entirely).

---

# Part C — Quality Gates & Validation Checklist

Every commit to `main` must satisfy the following gates.

## C.1 Static checks

> `psa.py` is not bundled in this repository; obtain it per A.11 before running these checks.

- [ ] `python3 psa.py Deploy-AMDChipsetDriverOnWindowsServer.ps1` → 0 errors
- [ ] `python3 psa.py Deploy-AMDGraphicsDriverOnWindowsServer.ps1` → 0 errors
- [ ] `python3 psa.py Deploy-AMDNpuDriverOnWindowsServer.ps1` → 0 errors
- [ ] `python3 psa.py Deploy-MSBthPanInboxOnWindowsServer.ps1` → 0 errors

## C.2 Functional checks (per affected script)

- [ ] `-Action ListPhases` produces the expected 21-phase table.
- [ ] `-Action PrepareVerify -CleanWorkRoot` on any non-target host (without the target AMD devices) completes without errors using `-AssumeIfMissing` (NPU script) / appropriate platform override (chipset / graphics). Note: this is a pipeline-soundness check only — it does not validate real driver behaviour.
- [ ] `-Action PrepareVerify -CleanWorkRoot` for the BthPan script completes on any Server SKU and produces a single-row `inf_inventory.csv`, even on hosts without a Bluetooth host controller (V05 / V06 will report "No BTH\MS_BTHPAN device on host" but the prepare phases still complete cleanly).
- [ ] `Show-RunSummary` is rendered regardless of exit path (success or failure).
- [ ] `Format-Elapsed` produces correct strings for `0.42s`, `1m2.3s`, `1h2m3s`.

## C.3 Documentation checks

- [ ] If a phase semantic changed: SPEC.md Part B is updated.
- [ ] If a parameter was added / removed / renamed: README.md and README.ja.md Parameters table is updated.
- [ ] If an output format changed: SPEC.md A.9 CSV columns and README.md Output files sections are updated.
- [ ] `README.ja.md` is in sync with `README.md` (see A.12 Documentation Language Policy).
- [ ] `CHANGELOG.md` has a new entry for the release (English only).

## C.4 Cross-script consistency checks

- [ ] All four scripts use `[pscustomobject]@{...}` in `$Script:PhaseRegistry` (not `@{...}`).
- [ ] All four scripts use sister-aligned function naming: `Invoke-{Group}Phase{NN}_{Name}`.
- [ ] All four scripts use the same `-Action` ValidateSet: `'Prepare','Verify','PrepareVerify','Install','All','Cleanup','ListPhases'`.
- [ ] All four scripts use the same marker semantics: `[*]` Cyan / `[+]` Green / `[!]` Yellow / `[X]` Red / `[~]` DarkGray.
- [ ] All four scripts use unique WDAC supplemental policy GUIDs that do NOT collide.

---

# Part D — Known Pitfalls & Lessons Learned

These are documented so that future revisions do not regress on already-fixed issues.

## D.1 Timezone-induced DriverDate false positives

**Symptom**: V05 dry-run plan reported `[UPGRADE]` action on identical drivers because `Win32_PnPSignedDriver.DriverDate` is stored as UTC midnight, but `Get-CimInstance` converts to local time, producing a day-offset on `[datetime]` comparison.

**Fix**: In `Compare-InfDriverVer`, use `.Date` truncation (year/month/day only) on both the current driver date and the patched INF date before comparing.

```powershell
$cdate = if ($CurrentDate) { $CurrentDate.Date } else { $null }
$pdate = if ($PatchedDate) { $PatchedDate.Date } else { $null }
```

Preserved verbatim across chipset / graphics / NPU scripts.

## D.2 Hypothetical filename `NPU_RAI1.7.1_380_WHQL.zip`

**Symptom**: Initial NPU script revisions used `NPU_RAI1.7.1_380_WHQL.zip` as the default filename, mapping it to RAI 1.7.1. However AMD's actual published filename for RAI 1.7.1 is **the same as for RAI 1.6.1**, namely `NPU_RAI1.6.1_314_WHQL.zip` (driver build 32.0.203.314).

**Fix**: NPU driver and Ryzen AI Software are versioned independently. The script now exposes them as two distinct parameters and the default `-NpuDriverPackage latest` resolves to `NPU_RAI1.6.1_314` (the newest documented). Verified against <https://ryzenai.docs.amd.com/en/latest/inst.html> 2026-04-19.

## D.3 `Show-PhaseHeader` vs `Write-PhaseHeader` naming drift (NPU)

**Symptom**: Early NPU revisions used `Show-PhaseHeader` (sister scripts used `Write-PhaseHeader`), and the phase entry banner color was Yellow `#`×78 (sister: Magenta `=`×72). This broke visual consistency across logs from multiple scripts run in sequence.

**Fix**: Sister-script alignment refactor renamed to `Write-PhaseHeader` and adopted Magenta `=`×72 + script-tag DarkGray line. Now identical across all three scripts.

## D.4 NPU — Action `'Install'` semantic drift

**Symptom**: An earlier NPU revision mapped `-Action Install` to "all 21 phases" (full pipeline), while sister scripts mapped it to "Inst phases only" (assumes Prep + Verify already ran).

**Fix**: Sister-script alignment refactor corrected `-Action Install` to Inst-only and added `-Action All` for the full pipeline. Workstation OS guard now fires on both `Install` and `All`.

## D.5 ja-JP console encoding (chcp 932)

**Symptom**: Japanese log strings garble on default ja-JP Windows console (code page 932, Shift-JIS), AND external tool output (CiTool.exe, modern signtool.exe) writing UTF-8 to stdout is mojibake when captured via `& tool | Out-String`.

**Fix**: P00 calls `Set-ConsoleUtf8` which enforces all three encodings ( `[Console]::OutputEncoding`, `[Console]::InputEncoding`, `$OutputEncoding`) to `[System.Text.Encoding]::UTF8`. Operators using `*>&1 | Tee-Object` must also set the file encoding explicitly. See §A.5 for the canonical implementation.

**Pre-fix history**: This SPEC entry was documented from the earliest revisions, but the implementation was missing. `Show-PowerShellEnvironment` displayed `Default Encoding: shift_jis (cp932)` / `Console OutputEnc.: shift_jis (cp932)` but no code path actually set them to UTF-8. The defect surfaced as `CiTool: 蜃ｦ逅・・謌仙粥縺励∪縺励◆` in I02 log output on ja-JP WS2025 hosts. See §D.16 for the full root-cause and verification trail.

## D.6 `-LiteralPath` not supported on `Invoke-WebRequest -OutFile` (PS 5.1)

**Symptom**: When downloading to a path containing `[` or `]`, `Invoke-WebRequest -OutFile` (PS 5.1) wildcard-interprets the path.

**Fix**: Download to a wildcard-free temp filename (`<dir>\.dl_<GUID>.part`), then `Move-Item -LiteralPath` to the real destination. Pattern preserved in NPU script's `Invoke-NpuZipDownload`.

## D.7 Code-signing certificate filename standardization

**Symptom**: Before the cross-script alignment commit, the three scripts used inconsistent code-signing certificate filenames:

| Script | Pre-fix filename | Reason for inconsistency |
| --- | --- | --- |
| Chipset | `cert\AMD-Driver-CodeSign.{pfx,cer}` | Original NPU-less repo where "AMD-Driver" was unambiguous |
| Graphics | `cert\AMD-Driver-CodeSign.{pfx,cer}` | Copy-pasted from chipset, same generic name |
| NPU | `cert\AMD-NPU-CodeSign.{pfx,cer}` | Authored later with a more specific name, but inconsistent with the older two |

This caused two operational problems:

1. **Side-by-side ambiguity**: A host running all three scripts had two `AMD-Driver-CodeSign.{pfx,cer}` files in different workspaces (`C:\AMD-Chipset-WS\cert\` and `C:\AMD-Graphics-WS\cert\`). Operators inspecting `Cert:\LocalMachine\Root` saw two unrelated certs with provider strings that didn't immediately reveal which script created them.
2. **Sister-script symmetry violation**: SPEC §A.1.4 mandates per-script `C:\AMD-<short>-WS\` workspace isolation. The cert filenames should follow the same per-script-prefix convention.

**Fix**: All three scripts standardised to `cert\AMD-{Chipset|Graphics|NPU}-Driver-CodeSign.{pfx,cer}`:

| Script | Post-fix filename | Path |
| --- | --- | --- |
| Chipset | `AMD-Chipset-Driver-CodeSign.{pfx,cer}` | `C:\AMD-Chipset-WS\cert\` |
| Graphics | `AMD-Graphics-Driver-CodeSign.{pfx,cer}` | `C:\AMD-Graphics-WS\cert\` |
| NPU | `AMD-NPU-Driver-CodeSign.{pfx,cer}` | `C:\AMD-NPU-WS\cert\` |

**Upgrade impact on existing deploys**:

- Old `cert\AMD-Driver-CodeSign.{pfx,cer}` files remain on disk untouched after upgrade (Cleanup removes the cert from trust stores by thumbprint, not by filename).
- Running `-Action Install` with the new script will generate a fresh PFX/CER under the new name; the old PFX/CER is then orphaned in the workspace.
- For a clean upgrade, run `-Action Cleanup` on the old script revision **before** upgrading.

## D.8 WDAC supplemental policy GUID standardisation

**Symptom 1 (Chipset / Graphics, before the fix)**: The supplemental policy `PolicyID` was generated dynamically with `Set-CIPolicyIdInfo -ResetPolicyID`, producing a new GUID on every deploy. The GUID was persisted to `<workspace>\cert\AmdSuppPolicyId.txt` so that `Cleanup` could find it later.

This had two downsides:
- A re-deploy did not replace the previous deploy's policy slot — it created a *new* slot with a new GUID, accumulating dormant `<oldGuid>.cip` files in `C:\Windows\System32\CodeIntegrity\CiPolicies\Active\`.
- If `<workspace>\cert\AmdSuppPolicyId.txt` was lost (e.g. workspace deleted manually), `Cleanup` could not locate the deployed policy.

**Symptom 2 (Graphics, before the fix)**: The script used `SupplementsBasePolicyID = '{B355481F-55DA-5D17-C662-07127F674187}'`, a non-standard GUID that does **not** correspond to any Microsoft-shipped CI base policy. Almost certainly a copy-paste artefact from earlier development. The chipset and NPU scripts both correctly used the Windows-default `{A244370E-44C9-4C06-B551-F6016E563076}`. The Graphics supplemental policy was therefore "supplementing" a non-existent base, which Windows may load with a warning or silently ignore.

**Fix**:

1. **Fixed default supplemental policy GUIDs** per script, unique per script so they coexist on a host with all three deployed:
   - Chipset: `503860EA-8837-4169-9BC4-19E5AEED721B`
   - Graphics: `85336828-3080-41C5-81EC-FD587DC090D3`
   - NPU: `8B2C4F12-1E9D-4D7B-A4F8-9C7E2B6A53D1` (pre-existing, unchanged)
2. **Operator override** via `-WdacPolicyGuid <GUID>`, accepted with or without braces. Two use cases:
   - **Legacy cleanup**: read the old PolicyId from `<workspace>\cert\AmdSuppPolicyId.txt` and pass it with `-Action Cleanup -WdacPolicyGuid <oldGuid>` to remove a legacy deploy. The new `Test-AmdWdacPolicyDeployed` also automatically falls back to reading the legacy marker file if the fixed GUID is not active, so unattended Cleanup on a legacy deploy still works without manual GUID lookup.
   - **Side-by-side**: deploy two copies of the same script with different GUIDs (rare).
3. **Graphics-only fix**: default `SupplementsBasePolicyID` corrected from `{B355481F-...}` to the Microsoft standard `{A244370E-...}`. Overridable via `-WdacBasePolicyGuid` for environments with custom base CI policies.
4. **Implementation detail**: PowerShell's `Set-CIPolicyIdInfo` has no `-PolicyId` switch; we patch the `<PolicyID>` element directly in the XML after `Set-CIPolicyIdInfo -SupplementsBasePolicyID …` (no longer pass `-ResetPolicyID`).

**Upgrade impact**: Same as D.7 — for a clean upgrade, run `-Action Cleanup` on the old script revision before deploying the new one. The new script's `Cleanup` action does detect legacy dynamic-GUID policies via the marker-file fallback, so an upgrade-then-cleanup also works (one extra cleanup cycle).

---

## D.9 UEFI Secure Boot baseline feature

**Summary**: A cross-cutting informational feature added to all three scripts that captures the host's UEFI Secure Boot certificate-rollout state and surfaces it at P00 / P05 (report appendix) / V05 (compact) / V06 (full section) / I02 (pre-check). See `A.14 UEFI Secure Boot Baseline` for the full design.

**Iteration history**:

| Phase | Change |
|---|---|
| Initial implementation | 6 core functions + per-script helper + 5 integration points |
| Validation fixes | Three corrective fixes applied before publishing: (a) `schtasks.exe /Query /FO CSV` returns localized headers on ja-JP hosts; replaced with `Get-ScheduledTask` for locale-independent state. (b) MS sample script's `[<>:"|?*]` regex rejects every absolute Windows path; added stdout-JSON fallback. (c) `Show-...` non-compact mode and V06 caller both printed `--- UEFI Secure Boot Baseline ---` banner; removed inner banner so V06 controls section numbering. |
| Polish patch | Removed `%TEMP%` fallback from P00 (diagnostic files always co-locate with `$Ctx.WorkRoot`); added `Get-OrEnsureSecureBootBaseline` helper that re-captures when the cached snapshot's diagnostic file is missing or outside the current workspace. |

**Cross-script symmetry**: The 6 core functions (Get-SecureBootCertificateInventory / Get-MsSecureBootExampleScriptPath / Invoke-MsSecureBootDetectScript / Get-SecureBootBaselineSnapshot / Show-SecureBootBaselineSnapshot / Format-SecureBootBaselineForReport) are byte-identical across the four scripts (chipset / graphics / NPU / BthPan); BthPan reuses the chipset variant verbatim. Only the seventh `Get-OrEnsureSecureBootBaseline` helper differs (chipset/graphics: `param($Ctx)`; NPU: `param()` with script-scope access).

---

## D.10 `Find-Inf2CatPath` x64-filter bug (NPU)

**Summary**: NPU's `Find-Inf2CatPath` delegated to `Find-ToolPath` which filters discovered files to `\x64\` or `\amd64\` directories only. inf2cat.exe ships **exclusively as an x86 binary** under the Windows SDK/WDK tree (Microsoft has never produced an x64 build of this tool), so the filter always returned `$null` and NPU P02 then tried to install the WDK via winget — which itself does not publish the WDK as a winget package. The result was a hard P02 FAILED on every host that had inf2cat installed in the standard location.

**Root cause**: Reuse of a generic `Find-ToolPath` helper whose architecture filter is correct for signtool (which has both x64 and x86 variants) but wrong for inf2cat (x86 only).

**Fix**: Replaced the body of `Find-Inf2CatPath` with an inline `Get-ChildItem ... -Recurse -Filter 'inf2cat.exe'` walk over the SDK bin roots, no architecture filter. Highest `FileVersion` wins. Matches the lookup logic implicit in the chipset / graphics scripts where inf2cat is also found correctly.

**Scope**: NPU-only; chipset and graphics scripts use a different inf2cat discovery path.

---

## D.11 `NpuOverride` `[ValidateSet]` excludes empty string (NPU)

**Summary**: At script load, PowerShell logged `値  は NpuOverride 変数の有効な値ではないため、変数を検証できません` (and English equivalent) from the line `$Script:NpuOverride = $NpuOverride`. The warning fired because `[ValidateSet('PHX','HPT','STX','KRK')]` on `[string]$NpuOverride` rejects the default empty string when the variable is re-evaluated at the script-scope assignment. The warning was non-fatal (the script continued past it) but noisy and confusing.

**Fix**: Added `''` to the ValidateSet: `[ValidateSet('','PHX','HPT','STX','KRK')]`. The empty value represents "no override; auto-detect via Get-AmdNpuPlatform", which matches the prior default behaviour.

**Scope**: NPU-only.

---

## D.12 InstallShield SFX extraction for AMD 8.x+ installers (Chipset)

**Summary**: Starting with AMD Chipset Software 8.x (8.02.18.557, observed May 2026), the installer bootstrapper changed to a two-layer wrapper: an outer NSIS SFX wrapping an inner InstallShield SFX (`ISSetupStream` format). 7-Zip can decode the outer layer but exits cleanly (exit 0) on the inner layer with no payload, so the script's earlier two-strategy extraction (7-Zip + launch-and-watch) silently produced an incomplete result.

**Observed symptom (X13 Gen 1 / Ryzen 5 PRO 4650U / WS2025, May 2026)**: After P04 ExtractInstaller succeeded, P05 AnalyzeInfs reported only 2 INFs in the extract tree (`AmsMailbox.inf` + `AmdAppCompat.inf`) instead of the expected ~32. I04 PostInstallVerify reported 42 unmatched AMD devices in Device Manager.

**Root cause**: The AMD 8.x inner installer is `ISSetupStream`-formatted. 7-Zip's `PE` handler matches the SFX EXE shell and returns exit 0, but only extracts the EXE's resource-section files — none of the 35 sub-MSIs reach the destination tree. Strategy 1's `_HasPayload` guard noticed this and triggered Strategy 2 (launch + watch), which is fragile: AMD's installer aggressively cleans up `C:\AMD\` after extraction, often before the watcher can grab the files.

**Fix**: New Strategy 2/3 inserted between the old 7-Zip and launch-watch strategies. The new strategy:

1. 7-Zips the outer NSIS shell to a staging directory (the outer layer remains 7-Zip-extractable).
2. Locates the inner `AMD_Chipset_Drivers.exe` (InstallShield SFX).
3. Invokes the InstallShield SFX with `/a /s /v"TARGETDIR=... GONOGO=PUBLICGO /qn"`, which extracts the parent MSI plus all 35 sub-MSIs into a staging tree without running any install-side CustomActions.
4. Runs `msiexec /a <sub.msi> TARGETDIR=<final dest>` on each sub-MSI to unpack its INF / SYS / CAT tree into the final destination.
5. Emits a per-OS-variant diagnostic showing INF coverage by `W11x64` / `WTx64` / `WTx86` subdirectory, marking the variant preferred for the host OS as `[PREFERRED]`.

After Strategy 2 succeeds, the existing P05 / P06 / I03 pipeline picks up the full INF tree and selects the OS-appropriate variant via `Get-PreferredAmdSourceVariants` (unchanged from earlier revisions).

**Scope**: Chipset only. Graphics and NPU installers use different formats (Graphics is a WIX BURN bootstrapper, NPU is a plain ZIP) and don't need this strategy.

**Renoir-specific note**: Even with the AMD 8.x fix, X13 Gen 1 will see ~27 of the 35 INF packages remain "no device" because their Hardware IDs target Phoenix Point and later CPUs. The ~5-8 packages that DO match real devices are the meaningful coverage improvement. This is expected and documented in B.1's "35 sub-MSIs" table.

---

## D.13 Workspace lock leaked across runs in the same PowerShell console (Chipset / Graphics)

> **Note**: The error message shown below references the pre-relocation workspace path (`C:\AMD-Chipset-WS`) because that is what an earlier chipset revision emitted at the time. Currently, the equivalent message shows `C:\Temp\Workspace_AMD-Chipset` instead. The mechanism described and the fix are unchanged.

**Symptom**: Running the chipset (or graphics) script with `-Action PrepareVerify` and then immediately re-running it (with the same or a different `-Action`) in the **same interactive PowerShell console** failed at P01 with:

```
*** Another instance of this script is already running in workspace C:\AMD-Chipset-WS ***
    PID         : 3088
    StartedAt   : 2026-05-16 23:38:05
    CommandLine : C:\WINDOWS\System32\WindowsPowerShell\v1.0\powershell.exe
```

The PID shown (3088) was the PID of the PowerShell host process itself, not of a second script invocation. The first invocation had already completed cleanly.

**Root cause**: The workspace lock file (`<WorkRoot>\.markers\RUN.lock`) was written by `Set-WorkspaceLock` in P01 with the current `$PID`. Cleanup relied solely on a `Register-EngineEvent -SourceIdentifier PowerShell.Exiting` action; this event only fires when the PowerShell **host process** terminates, not when a script returns. In an interactive console (where the host is reused for many script invocations) the lock therefore leaked. Run 2 then ran `Test-WorkspaceLockHeld`, found the leftover lock with PID=3088, called `Get-Process -Id 3088` (which returned the PowerShell host itself), and incorrectly concluded that "another instance is running".

The Graphics script had the same code pattern with the same defect. The NPU script does not have a workspace lock and is unaffected (it uses script scope rather than `$Ctx.Paths.Markers`).

**Fix**: Two complementary changes (defense-in-depth):

1. **Self-PID detection in `Test-WorkspaceLockHeld`** — if the recorded PID in the lock file equals the current `$PID`, the lock is classified as `Stale` with a new `SelfPid=$true` field. `Assert-NoConcurrentRun` then silently supersedes it with an informational `[+] Reusing workspace lock from earlier run in this PowerShell session` message instead of the loud "stale lock" warning intended for crashed prior runs.

2. **`try { ... } finally { Clear-WorkspaceLock ... }` around the main phase loop** — the existing top-level `foreach ($phase in $queue) { ... }` and the run summary block are now wrapped in `try { ... } finally { ... }`. The `finally` calls `Clear-WorkspaceLock -Ctx $Ctx` so the lock file is removed on every exit path (normal completion, phase throw, top-level error). The inner cleanup uses an intentionally empty `catch { }` annotated with `# psa-disable-line PSA3004 -- intentional best-effort cleanup in finally; a failure here must not mask the original exception`.

The two changes are complementary: `try/finally` prevents the lock from leaking on every exit path going forward; the self-PID detection handles the historic case where a legacy leftover lock is encountered, and any future case where a hard `Stop-Process`/`Ctrl-C` bypasses `finally` entirely.

**Scope**: Chipset and Graphics. The NPU script does not implement a workspace lock and is intentionally exempt — see SPEC §A.1.4 cross-script consistency check rules (the lock is not on the cross-script-mandatory list).

---

## D.14 Per-tool installer logs leaked to workspace root (Chipset)

> **Note**: The workspace paths shown in this section use the legacy layout (`C:\AMD-Chipset-WS\`) because that is the path the bug actually surfaced under originally. Currently, the workspace lives at `C:\Temp\Workspace_AMD-Chipset\` instead; the substring after the workspace root (`installshield-admin.log`, `msiexec-admin-*.log`) is unchanged. See SPEC §A.1.4 for the relocation.

**Symptom**: After running `-Action PrepareVerify` on a clean Windows Server 2025 host, the workspace root (`C:\AMD-Chipset-WS\`) contained the following loose log files alongside the documented subdirectory layout (`download\`, `extracted\`, `patched\`, `cert\`, `logs\`, `.markers\`):

```
C:\AMD-Chipset-WS\installshield-admin.log
C:\AMD-Chipset-WS\msiexec-admin-AMD-AS4-ACPI-Driver.log
C:\AMD-Chipset-WS\msiexec-admin-AMD-Consumer_Infrared-Driver.log
C:\AMD-Chipset-WS\msiexec-admin-AMD-GPIO2-Driver.log
C:\AMD-Chipset-WS\msiexec-admin-AMD-I2C-Driver.log
C:\AMD-Chipset-WS\msiexec-admin-AMD-IOV-WT-Driver.log
C:\AMD-Chipset-WS\msiexec-admin-AMD-PCI-Driver.log
C:\AMD-Chipset-WS\msiexec-admin-AMD-PMF-7736Series-Driver.log
C:\AMD-Chipset-WS\msiexec-admin-AMD-PMF-Ryzen-AI-300-Series-Driver.log
C:\AMD-Chipset-WS\msiexec-admin-AMD-PSP-Driver.log
C:\AMD-Chipset-WS\msiexec-admin-AMD-SBxxxSMBus-Driver.log
C:\AMD-Chipset-WS\msiexec-admin-AMD-UART-Driver.log
C:\AMD-Chipset-WS\msiexec-admin-AMD-USB_Filter-Driver.log
```

The workspace already had a `logs\` subdirectory used by P08 (inf2cat), P09 (signtool), V03 (signtool verify), and I03 (pnputil) — but the InstallShield admin install and the per-sub-MSI msiexec admin installs added for AMD 8.x did not route their logs there.

**Root cause**: `Expand-AmdInstaller_ViaInstallShield` (introduced for AMD 8.x) computed `$parentDir = Split-Path $DestinationPath -Parent`. Because the caller (`Invoke-PrepPhase04_ExtractInstaller`) passed `$Ctx.Paths.Extract` (= `<WorkRoot>\extracted`) as `$DestinationPath`, `$parentDir` resolved to `<WorkRoot>` itself. Both `$isLog` and the per-sub-MSI `$subLog` were then computed as `Join-Path $parentDir <filename>`, dropping every log file in the workspace root.

**Fix**: New optional `[string]$LogDir` parameter on `Expand-AmdInstaller` and `Expand-AmdInstaller_ViaInstallShield`. The downstream function resolves a `$logRoot` variable: if the caller passed a `$LogDir` (and the directory exists or can be created), `$logRoot` is set to `$LogDir`; otherwise `$logRoot` falls back to the legacy `$parentDir` for backwards compatibility. Both `$isLog` and `$subLog` are then computed against `$logRoot`. The caller (`Invoke-PrepPhase04_ExtractInstaller`) was updated to pass `-LogDir $Ctx.Paths.Logs`. Existing P08/P09/V03/I03 log files are unaffected (they already wrote to `$Ctx.Paths.Logs`).

**Effect on workspace layout**:

| File                                  | Pre-fix location | Post-fix location          |
| ------------------------------------- | ---------------- | -------------------------- |
| `installshield-admin.log`             | `<WorkRoot>\`    | `<WorkRoot>\logs\`         |
| `msiexec-admin-<sub-MSI>.log` (×12)   | `<WorkRoot>\`    | `<WorkRoot>\logs\`         |
| `inf2cat_<rel>.log` (existing)        | `<WorkRoot>\logs\` | unchanged                |
| `signtool_<rel>.log` (existing)       | `<WorkRoot>\logs\` | unchanged                |
| `verify_<basename>.log` (existing)    | `<WorkRoot>\logs\` | unchanged                |
| `pnputil_<basename>.log` (existing)   | `<WorkRoot>\logs\` | unchanged                |
| `inf_inventory.csv`                   | `<WorkRoot>\`    | unchanged (documented)     |
| `inf_inventory_report.txt`            | `<WorkRoot>\`    | unchanged (documented)     |
| `secureboot_ms_sample\*` (existing)   | `<WorkRoot>\secureboot_ms_sample\` | unchanged |

**Scope**: Chipset only. Graphics does not use the InstallShield admin install / `msiexec /a` chain (its installer is a WIX BURN bootstrapper which uses a single `msiexec /i` invocation). NPU does not use any installer-level logging at this layer.

---

## D.15 Driver-category priority override (BREAKING) + Write-Detail helper (Chipset / Graphics)

**Summary**: Two coupled changes shipped together in a single commit.

### 1. BREAKING: category-priority override in install decision

**Symptom (before the fix)**: On a clean-installed Windows Server 2025 host where Windows had bound its in-box generic drivers (`machine.inf`, `pci.inf`, `hdaudbus.inf`, `cpu.inf`, `display.inf`, etc.) to AMD hardware, V05 / V06 / I03 routinely classified the patched AMD drivers as `SKIP-newer` and refused to install them. The cause is fundamental: Microsoft generic drivers use **OS-build versioning** (e.g. `10.0.26100.1150`) which numerically dominates AMD's **semantic versioning** (e.g. `1.0.47.1`, `5.43.0.0`). Pure version comparison therefore *never* replaces a Microsoft generic with an AMD-vendor driver.

Reported example from a clean WS2025 install (Renoir / Ryzen 5 PRO 4650U):
- `標準電源管理コントローラー` (Standard Power Management Controller) was bound to MS `machine.inf v10.0.26100.1150`. The patched `AmdMicroPEP.inf v1.0.47.1` was correctly classified as `[C] Self-signed` and the device was in scope, but I03 logged `SKIPPED (current driver is same/newer; skipping to avoid downgrade)`.
- `マルチメディア コントローラー` (Multimedia Controller) had `[?] Unknown` driver and the patched `amdacpbus.inf` was likewise skipped because `Compare-InfDriverVer` returned 0 on the empty version string.

**Fix**: Replaced the pure-version comparison in `Resolve-PerDeviceDriverDecision` and `Resolve-PerInfInstallDecision` with a **category-priority override**:

```
Priority order (high -> low):
  [C] Self-signed (this script's output)   = highest
  [B] Hardware vendor / IHV                = middle
  [A] Microsoft (OS in-box)                = lowest
  [?] Unknown / unsigned                   = treated as lowest
```

Because the TO-BE driver produced by this pipeline is always `[C]` (the patched INFs are signed with the script's own certificate at P07/P09), the rule simplifies to:

- **AS-IS in `[A]` / `[B]` / `[?]`** → TO-BE `[C]` always WINS (install regardless of version comparison).
- **AS-IS in `[C]`** → fall back to version comparison (avoid pointless reinstall of an earlier run's self-signed driver).

This is implemented via `Get-DriverSourceCategory -Provider $cur.Provider -Signer $cur.Signer` called at the start of each decision function; the resulting `.Code` is checked against `'C'` before any `Compare-InfDriverVer` call.

**Why this is a BREAKING change**: Previously the pipeline preserved AMD's official `[B]` Vendor drivers when they were the same or newer than the patched `[C]` Self-signed counterpart. Under the current install-decision logic those `[B]` drivers are also replaced. The operator-facing implication:

- **Pro**: the documented behavior of "AMD self-signed drivers on AMD hardware" is now achievable on a clean Server 2025 install in a single `-Action All` run.
- **Con**: any AMD vendor driver previously installed via Windows Update / OEM site will be overwritten by the script's self-signed version of the *same* underlying driver binaries (only the signature publisher changes). If the operator wanted to preserve a vendor driver, they must run `-Action PrepareVerify` first, inspect V06 Section 2, and decide whether to proceed.

**Documentation implications**: the README's "Self-signed drivers are a LAST-RESORT gap-fill, NOT a primary install path" language continues to apply at the *recommendation* level (operators should still run Windows Update and OEM installers first), but the *script's decision logic* no longer enforces it via version comparison.

**Scope**: Chipset and Graphics. The NPU script does not implement install-decision logic at this layer (`-Action Install` on NPU is gated by EULA acknowledgement and runs `pnputil` directly without per-INF version comparison) and is therefore unaffected.

### 2. Write-Detail helper introduction (log-layout uniformity)

**Symptom**: An audit of the chipset script counted 165 occurrences of bare `Write-Host "    ..."` (4-space indented plain text) and the graphics script 154, used in `Show-PowerShellEnvironment`, `Show-SecureBootBaselineSnapshot`, P03 platform inventory, P04 nested-MSI listing, P05 INF inventory table, V05 Dry-Run output, V06 hardware-impact rows, and I00 review. Each call duplicated the indent string and had no central control over color or alignment, making future column-layout tweaks impossible without touching every call site.

**Fix**: Introduced `Write-Detail` immediately after `Write-Skip` in the output helper section:

```powershell
function Write-Detail {
    param(
        [Parameter(Position=0)][string]$Msg,
        [ConsoleColor]$Color = [ConsoleColor]::Gray,
        [switch]$NoNewline
    )
    if ($NoNewline) {
        Write-Host ("    {0}" -f $Msg) -ForegroundColor $Color -NoNewline
    } else {
        Write-Host ("    {0}" -f $Msg) -ForegroundColor $Color
    }
}
```

A one-off Python conversion script (`convert_writehost.py`) was used to mechanically rewrite the bulk of the call sites, with a handful of multi-line / backtick-continuation cases handled manually. The total per-file edits were ~165 line replacements for the chipset script and ~155 for the graphics script. After conversion, 0 bare 4-space `Write-Host` calls remain outside of `Write-Detail`'s own body.

**Documented as the sanctioned exception**: SPEC §A.5 was updated to list `Write-Detail` as the single approved continuation-line helper. Bare `Write-Host "    ..."` is now a SPEC violation.

**Scope**: Chipset and Graphics. The NPU script did not have the same accretion of bare `Write-Host` indentation patterns (audit count: 0) and was not modified at that revision; a later NPU revision introduces console UTF-8 enforcement and CiTool `--json` but does not change the Write-Host pattern profile.

### 3. psa.py baseline drift after the Write-Detail conversion

The mechanical conversion added ~1 trailing-semicolon info finding per file. Baseline at that point (re-measured later in §D.16 below):

| Script | Errors | Warnings | Info | Total |
| ------ | -----: | -------: | ---: | ----: |
| `Deploy-AMDChipsetDriverOnWindowsServer.ps1`  | **8** | 55 | 32 | 95 |
| `Deploy-AMDGraphicsDriverOnWindowsServer.ps1` | **8** | 56 | 38 | 102 |
| `Deploy-AMDNpuDriverOnWindowsServer.ps1`      | **0** | 30 |  0 | 30 |
| `Deploy-MSBthPanInboxOnWindowsServer.ps1`     | **2** | 61 | 32 | 95 |

---

## D.16 CiTool.exe interactive ENTER prompt + Console UTF-8 enforcement

**Symptom (reported on a clean Windows Server 2025 Datacenter / ja-JP)**: Running `-Action Install` on the chipset and graphics scripts produced a hang of roughly 60-75 seconds in I02 (AuthorizeDriverSigning) between the two log lines:

```
[04:32:43] [+1.17s]   [*] Converting XML to .cip binary and deploying to active CI policies...
[04:33:57] [+1m15.2s] [+] Deployed: C:\WINDOWS\System32\CodeIntegrity\CiPolicies\Active\{503860EA-...}.cip
```

Operators reported that pressing **ENTER** in the console caused immediate progression. Tee-Object log captures showed `CiTool: 蜃ｦ逅・・謌仙粥縺励∪縺励◆` (mojibake) at the boundary.

**Investigation (verification trail, 2026-05-17)**: Standalone `Measure-Command` calls on the cmdlets/tools inside `Install-AmdWdacPolicy` showed:

| Component | Solo elapsed | Prompts? |
|---|---|---|
| `ConvertFrom-CIPolicy -XmlFilePath ... -BinaryFilePath ...` | 0.28 s | NO |
| `& CiTool.exe --update-policy <cip>` | 5.6 s (with ENTER press) | **YES — prints "続行するには、Enter キーを押してください"** |
| `& CiTool.exe` (any subcommand) | varies | **YES — every CiTool invocation prints "Press Enter to Exit"** |

The CiTool.exe `--help` output documents an undocumented-in-MS-docs flag (verified ja-JP, WS2025 build 26100, 2026-05-17):

```
グローバル フラグ
  --json
     出力を json として書式設定し、入力を抑制する
     エイリアス: -j
```

I.e. `--json` (or `-j`) instructs CiTool to emit machine-readable JSON **and** suppress the interactive ENTER prompt. This is the canonical non-interactive mode on Windows 11 / Windows Server 2025.

**Two-part root cause**:

1. **CiTool.exe blocks on stdin without `--json`.** All `CiTool.exe --update-policy <cip>` and `CiTool.exe --remove-policy <id>` invocations in `Install-AmdWdacPolicy` / `Uninstall-AmdWdacPolicy` were missing the flag, so each one stalled until the operator pressed ENTER.
2. **Console encoding stayed at cp932.** SPEC §A.5 / §D.5 mandated `[Console]::OutputEncoding = UTF8` but the implementation only *displayed* the current encoding in `Show-PowerShellEnvironment` and never actually set it. The byproduct was that CiTool's UTF-8 stdout was decoded as cp932 (`処理が成功しました` → `蜃ｦ逅・・謌仙粥縺励∪縺励◆`).

**Fix**:

1. **CiTool `--json` flag applied at all 6 call sites** (3 update + 3 remove across Chipset / Graphics / NPU). Output is parsed with `ConvertFrom-Json`; the canonical status line (`OperationResult` / `Status` / `PolicyGUID`) is extracted for `Write-Detail` display, with a raw-stdout fallback when JSON parsing fails.

2. **`Set-ConsoleUtf8` helper added next to `Set-Tls12` (chipset/graphics) / `Set-NetworkProtocol` (NPU)** and called from P00 immediately after TLS setup. Wraps `[Console]::OutputEncoding` / `InputEncoding` / `$OutputEncoding` assignments in `try/catch` for redirected-host compatibility.

3. **I02 output migrated to `Write-Detail`** for the activation method and CiTool status lines (sweep miss from the prior Write-Detail conversion). Re-classified as a sub-fix under §A.5 compliance.

**Verification commands the operator can run to confirm the fix locally** (no script execution required):

```powershell
# (a) CiTool.exe should NOT print "Press Enter to Exit" when invoked with --json
& CiTool.exe --list-policies --json | Select-Object -First 3

# (b) CiTool.exe stdout should NOT garble (after Set-ConsoleUtf8 has run)
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$tmpXml = 'C:\Temp\Workspace_AMD-Chipset\cert\AmdSelfSignedSupplementalPolicy.xml'
$tmpCip = "$env:TEMP\verify_$(Get-Random).cip"
ConvertFrom-CIPolicy -XmlFilePath $tmpXml -BinaryFilePath $tmpCip | Out-Null
Copy-Item $tmpCip "$env:windir\System32\CodeIntegrity\CiPolicies\Active\verify_test.cip" -Force
& CiTool.exe --update-policy "$env:windir\System32\CodeIntegrity\CiPolicies\Active\verify_test.cip" --json
# Expected: clean JSON output, no "Press Enter" prompt, no mojibake
```

**Scope**: All three scripts. The same one-line `--json` addition applies to NPU's `Install-WdacPolicy` / `Remove-WdacPolicy` (parallel-named NPU functions; same intent).

**psa.py baseline impact**: The Set-ConsoleUtf8 + CiTool/JSON parse blocks add a small number of trailing-semicolon `PSA4004` info findings. Re-measure after merge:

| Script | Errors | Warnings | Info | Total | Delta vs prior baseline |
| ------ | -----: | -------: | ---: | ----: | --- |
| `Deploy-AMDChipsetDriverOnWindowsServer.ps1`  | **0** | TBD | TBD | TBD | TBD |
| `Deploy-AMDGraphicsDriverOnWindowsServer.ps1` | **0** | TBD | TBD | TBD | TBD |
| `Deploy-AMDNpuDriverOnWindowsServer.ps1`      | **0** | TBD | TBD | TBD | TBD |

The baseline numbers will be updated to specific values in the commit message of the next CI run that exercises `psa.py` against this revision; the **0 errors** invariant is the only gate.

---

## D.17 pnputil exit=259 reclassification (Chipset / Graphics)

**Symptom**: On a clean Windows Server 2025 install, the chipset script's I03 summary reported `52 ok (2 need reboot) / 3 failed`, but the I04 PostInstallVerification immediately afterwards reported `FAILED: 0` and listed the same three devices under `REBOOT_NEEDED`. The summary classification was inconsistent.

**Affected INFs (chipset only)**: `SMBUSamd.inf`, `AMDInterface.inf`, `AmdMicroPEP.inf`. Each had a sibling copy under a different source path (e.g. `Chipset_Software\SMBus Driver\W11x64\` vs `SMBus Driver\W11x64\` — see SPEC §B.1 "AMD 8.x installer architecture / OS variant selection logic"), so `pnputil.exe /add-driver` was invoked twice with effectively the same package contents. The first call returned `exit=0` (or `3010` for reboot-required) and queued the new driver. The second call returned `exit=259` because the driver store now already contained an equivalent package.

**Investigation (verification trail, 2026-05-17)**: The pnputil logs for the three exit=259 cases on WS2025 read:

```
Microsoft PnP ユーティリティ
ドライバー パッケージの追加:  SMBUSamd.inf
ドライバー パッケージが正常に追加されました。
公開名:         oem35.inf
デバイスのドライバー パッケージは最新の状態です:  PCI\VEN_1022&DEV_790B&SUBSYS_508217AA&REV_51\3&2411e6fe&0&A0
ドライバー パッケージの合計:  1
追加されたドライバー パッケージ:  0
```

I.e. pnputil reports the operation as **successful** (`正常に追加されました`) but did not register a *new* package (`追加されたドライバー パッケージ: 0`) because the device is already on the same-or-better driver. The exit code is `0x103` = `259` = `ERROR_NO_MORE_ITEMS`, used here as a "no-op completion" signal — analogous to `ERROR_ALREADY_EXISTS` in idempotent operations.

**Root cause**: The classification table in `Invoke-InstPhase03_InstallDrivers`:

```powershell
$rebootRequired = ($exit -eq 3010)
$isSuccess      = ($exit -eq 0 -or $exit -eq 3010)   # exit=259 fell into the failure branch
```

mapped exit=259 to `failed`. I04's PostInstallVerification reads the actual device state and correctly inferred `REBOOT_NEEDED` (because the first sibling-INF call had queued the binding), creating the I03/I04 divergence.

**Fix**: Reclassify exit=259 as a third success status:

```powershell
$rebootRequired = ($exit -eq 3010)
$isNoOp         = ($exit -eq 259)
$isSuccess      = ($exit -eq 0 -or $exit -eq 3010 -or $exit -eq 259)

$status = if ($isSuccess -and $rebootRequired) { 'reboot-required' }
          elseif ($isNoOp)                      { 'no-op (already present)' }
          elseif ($isSuccess)                   { 'installed' }
          else                                  { 'failed' }
```

Console output for the no-op branch uses `Write-Skip` (DarkGray, marker `[~]`) — SPEC §A.5 "Skip / cached" semantic — rather than `Write-Ok` to clearly distinguish "package was added to the store and bound" from "package was already in the store, nothing changed."

The I03 summary now reports four categories:

```
Driver install: {ok} ok ({reboot} need reboot, {noop} no-op) / {failed} failed / {skipped} skipped (current newer)
```

**I04 alignment**: PostInstallVerification was already correct (read live device state); no change required.

**Scope**: Chipset and Graphics. The NPU script's I03 path is intentionally simpler (single pnputil invocation per matched device, no sibling-INF iteration) and the exit=259 code path is not currently exercised. NPU is unaffected by this fix, but the same code pattern would apply if a future revision introduces multi-source INF iteration.

**Why exit=259 is NOT a real failure**:

| Exit code | Meaning | Should script treat as |
|---|---|---|
| `0` | Success, driver added & bound (or queued for binding) | Success |
| `3010` (`ERROR_SUCCESS_REBOOT_REQUIRED`) | Success, REBOOT required to bind | Success + REBOOT |
| `259` (`ERROR_NO_MORE_ITEMS`) | Driver package already present in store; no new package added | Success (no-op) |
| any other non-zero | Real failure (signature rejection, ACL, etc.) | Failure |

**Operator-facing implication**: Pre-fix logs that show "3 failed" on chipset Install runs are NOT actually failures — they are duplicate-INF no-ops. The current (post-fix) logs will report the same scenarios as `no-op (already present)` and the failure count will be 0.

---

## D.18 `Get-DriverSourceCategory` Step 0 — catalog-thumbprint primary path (Chipset / Graphics)

**Symptom**: On the very first WDAC-authorized Install run, the script logged `category=Vendor` for AMD INFs that the script had itself just self-signed using `$Ctx.CertThumbprint`. The decision matrix in SPEC D.15 ("Driver-category priority override") then preferred the Vendor candidate over the SelfSign candidate, which on a clean WS2025 install caused the wrong INF to be picked for binding.

**Investigation**: `Get-DriverSourceCategory`'s legacy classification path used `Win32_PnPSignedDriver.Signer` (a string field). On freshly-installed self-signed catalogs, even with the certificate present in `LocalMachine\Root` and authorized by an active WDAC supplemental policy, the `Signer` field returned **empty**. The script's string-match path therefore had nothing to compare against and fell through to `[B] Vendor` — because the patched INF's `Provider` field still reads `"Advanced Micro Devices, Inc"` per SPEC §B.1 INF patching strategy.

**Root cause**: `Signer` is populated only for catalogs in the Microsoft trust hierarchy. Self-signed catalogs outside that hierarchy return empty even when fully trusted by WDAC. The legacy code therefore had no way to recognize the script's own catalogs.

**Fix**: A new authoritative **Step 0** is prepended to the classification path:

```powershell
function Get-DriverSourceCategory {
    param(
        [string]$Provider,
        [string]$Signer,
        # Optional: when provided, enables Step 0 (catalog-thumbprint
        # primary path). InfName is the OEM-numbered short form (e.g.,
        # 'oem32.inf'); the matching catalog is C:\Windows\INF\oem32.cat.
        [string]$InfName = '',
        [string]$ExpectedSelfSignThumbprint = ''
    )
    # Step 0 (NEW): direct catalog-signer thumbprint match.
    # Highest-confidence path. Skipped silently if either parameter is
    # empty or if the .cat file is not readable; falls through to the
    # legacy Signer-string heuristic in that case.
    if ($InfName -and $ExpectedSelfSignThumbprint) {
        $catPath = Join-Path (Join-Path $env:windir 'INF') `
                              ([System.IO.Path]::ChangeExtension($InfName, '.cat'))
        if (Test-Path -LiteralPath $catPath) {
            try {
                $sig = Get-AuthenticodeSignature -LiteralPath $catPath -ErrorAction Stop
                if ($sig -and $sig.SignerCertificate -and
                    $sig.SignerCertificate.Thumbprint -eq $ExpectedSelfSignThumbprint) {
                    return @{
                        Code       = 'C'
                        ShortLabel = '[C]'
                        Label      = 'Self-Signed (this script, catalog thumbprint match)'
                        Color      = 'Magenta'
                    }
                }
            } catch {} # silent: fall through to Step 1
        }
    }

    # Decision order (post-Step-0):
    #   1. Signer string matches our self-sign markers      => [C]
    #   2. Provider is "Microsoft" / "Microsoft Windows"    => [A]
    #   3. Any other non-empty Provider                     => [B]
    #   4. No Provider                                      => [?]
    # ... unchanged ...
}
```

All six call sites in each of Chipset and Graphics were updated to pass `$Ctx.CertThumbprint` as `ExpectedSelfSignThumbprint`. The function body remains **byte-identical** between Chipset and Graphics (5011 bytes — PSA8001 enforcement preserved). The return-shape contract (hashtable with `Code` / `ShortLabel` / `Label` / `Color`) is unchanged from the legacy implementation; Step 0 returns the same shape with `Label = 'Self-Signed (this script, catalog thumbprint match)'` (vs. the legacy Step 1's `Label = 'Self-Signed (this script)'` without suffix) so the log line itself distinguishes which path produced the classification.

**Scope**: Chipset + Graphics only. The NPU script uses a different decision path (single source, no string-based Signer inspection) and is unaffected. The BthPan script does its own signature verification via `Get-BthPanNetChildBinding.IsSignedByUs` (see D.19).

**Verification**: After fix, Chipset I00 reports `category=SelfSign` for all script-signed AMD INFs on the second-pass classification (post-WDAC-policy activation), and the priority override in SPEC D.15 correctly selects the SelfSign candidate.

### D.18b Extension — Step 0b OEM-name set lookup + `Get-OurSignedOemInfSet` helper

**Symptom (follow-up observation)**: Even after Step 0 was introduced, the chipset/graphics I04 `[LOADED]` row sometimes showed `AFTER: [B] Vendor` for a device that had just been bound to our self-signed driver. The mismatch was visible on Japanese WS2022 (build 20348) after a successful `pnputil /add-driver u0201039.inf /install`: I03 reported `installed` and the device's `Win32_PnPSignedDriver.InfName` field read `u0201039.inf` (the original short name), but Step 0's path lookup `C:\Windows\INF\u0201039.cat` returned `Test-Path = $false` (the file is named `oem45.cat` there). Step 0 therefore silently fell through to Step 1, Step 1 had no signer string, Step 2 saw `Provider="Advanced Micro Devices, Inc"`, and the device was reported as `[B] Vendor`.

**Root cause**: WMI's `Win32_PnPSignedDriver.InfName` is *not* guaranteed to return the OEM-numbered short form (`oem<N>.inf`) on every Windows build. On some builds (notably Server 2022 ja-JP build 20348) it returns the original short name (the basename of the source `.inf` file at the time of `pnputil /add-driver`). Step 0's `C:\Windows\INF\<InfName>.cat` heuristic depends on the OEM-numbered form because that is how `pnputil` renames the catalog when publishing to the driver store. With the original short name, the path does not exist, the signer check is skipped, and the classification falls through.

**Fix**: A new **Step 0b** is added immediately after Step 0a, and a new helper `Get-OurSignedOemInfSet` builds an authoritative lookup table once per I04 invocation:

```powershell
function Get-OurSignedOemInfSet {
    param([Parameter(Mandatory)] [string]$ExpectedThumbprint)
    $set = @{}
    if ([string]::IsNullOrWhiteSpace($ExpectedThumbprint)) { return $set }

    # Pass 1: scan C:\Windows\INF\oem*.cat for our cert thumbprint.
    $infDir = Join-Path $env:windir 'INF'
    $matchedOemBases = @{}
    foreach ($cat in (Get-ChildItem -LiteralPath $infDir -Filter 'oem*.cat' -ErrorAction SilentlyContinue)) {
        try {
            $sig = Get-AuthenticodeSignature -LiteralPath $cat.FullName -ErrorAction Stop
            if ($sig.SignerCertificate.Thumbprint -eq $ExpectedThumbprint) {
                $oemBase = [System.IO.Path]::GetFileNameWithoutExtension($cat.Name).ToLowerInvariant()
                $matchedOemBases[$oemBase] = $true
                $set[$oemBase + '.inf'] = $true
                $set[$oemBase + '.cat'] = $true
            }
        } catch {}
    }

    # Pass 2: pnputil /enum-drivers alias mapping (Published Name -> Original Name).
    # Label regexes accept both English and Japanese variants:
    #   Published Name | 公開名 | 発行された名前
    #   Original Name  | 元の名前 | 元のファイル名 | 元のドライバー名
    # ... (full implementation in the .ps1 source) ...

    return $set
}

# Get-DriverSourceCategory param block extension:
param(
    ...,
    [hashtable]$KnownOurInfSet = $null
)
# After Step 0a:
if ($InfName -and $KnownOurInfSet -and $KnownOurInfSet.Count -gt 0) {
    if ($KnownOurInfSet.ContainsKey($InfName.ToLowerInvariant())) {
        return @{ Code='C'; ShortLabel='[C]'; Label='Self-Signed (this script, OEM-name set match)'; Color='Magenta' }
    }
}
```

`Invoke-InstPhase04_PostInstallVerification` builds `$ourInfSet` once before iterating devices, then passes `-KnownOurInfSet $ourInfSet` to every `Get-DriverSourceCategory` call. This both fixes the classification accuracy and amortises the catalog signature-verification I/O cost — Step 0a's per-device path lookup is preserved but the per-device `Get-AuthenticodeSignature` call is replaced by an O(1) hashtable lookup after the first device.

**Byte-identical scope**: Both `Get-OurSignedOemInfSet` (new helper) and `Get-DriverSourceCategory` (extended) remain byte-identical across Chipset + Graphics per PSA8001. Only `Invoke-InstPhase04_PostInstallVerification` (which is in the `psa8001_ignore_functions` regex `^Invoke-(Prep|Verify|Inst)Phase\d{2}_`) diverges per script as expected.

**Verification (operator log, post-fix, chipset)**: `Snapshot: 42 AMD device(s)` → `Known signed-by-us INF/CAT name(s): <N>` (where N matches the count of patched INFs that landed in the driver store from this run) → all `[LOADED]` rows report `AFTER: [C]` consistently for self-signed drivers.

---

## D.18c I04 disposition: new `LOADED-via-OS-binding` branch (Chipset / Graphics)

**Symptom**: After installing the chipset/graphics driver, I03 reported one INF as `installed (REBOOT REQUIRED)` and the rest as plain `installed` (no reboot). Yet I04 then classified **five** devices on the chipset script as `REBOOT_NEEDED`, and four on graphics — far more than I03's reboot-required count.

**Investigation**: The disposition decision in `Invoke-InstPhase04_PostInstallVerification` ran the following ladder for each device:

```
if ($candidates.Count -eq 0)                        -> UNCHANGED
elif pnpResult.Status -eq 'skipped-current-newer'   -> KEPT_CURRENT
elif pnpResult.Status -eq 'failed'                  -> FAILED
elif before.DriverVersion -ne after.DriverVersion   -> LOADED
elif pnpResult.RebootRequired                       -> REBOOT_NEEDED
else (conservative fallback)                        -> REBOOT_NEEDED
```

For devices where pnputil reported `no-op (already present)` (Status non-failure, RebootRequired false) AND the before/after DriverVersion strings were identical (because the driver store already had our package from a prior run), the device landed in the **conservative else fallback** even though the OS was already binding our driver. The fallback's "Treat as REBOOT_NEEDED to be conservative" rationale was originally written to catch cases where Windows had silently deferred a binding, but it over-counted devices that were genuinely already bound.

**Fix**: A new disposition branch is inserted between the `DriverVersion`-change branch and the `RebootRequired` branch:

```powershell
} elseif ($a -and $a.InfName -and $ourInfSet -and $ourInfSet.ContainsKey($a.InfName.ToLowerInvariant())) {
    # OS reports the device is currently bound to one of OUR signed INFs (per
    # the oem*.cat thumbprint scan in $ourInfSet). Treat as LOADED even when
    # before/after DriverVersion did not change. Narrows the conservative
    # REBOOT_NEEDED fallback to devices whose binding actually IS deferred.
    $disposition = 'LOADED'
}
```

The branch reuses the `$ourInfSet` built for D.18b (no extra I/O). It is intentionally placed AFTER the `DriverVersion`-change branch so a version-bump still classifies as `LOADED` via the legacy path (preserves the existing log distinction). The branch is BEFORE `RebootRequired` because `RebootRequired` from pnputil is the pre-rebind signal, not a post-binding observation; on cached runs the device may be bound while pnputil still reports `RebootRequired=true` from the cached I03 result.

**Verification (operator log, post-fix, chipset)**: `REBOOT_NEEDED: 5 device(s)` → `REBOOT_NEEDED: 1 device(s)` (matching I03's reboot count). LOADED count rises correspondingly.

---

## D.18d I04 REBOOT_NEEDED display: fallbacks for empty `DriverVersion` and null `Candidate`

**Symptom (cosmetic)**: The `[REBOOT_NEEDED]` section of I04's per-device output sometimes rendered nonsensical lines:

```
[REBOOT_NEEDED] - reboot Windows to activate the new driver:
    - AMD GPIO Controller
        Still on v, new INF queued: (none)
    - AMD I2C Controller
        Still on v, new INF queued: (none)
```

The empty `v` (no version) and `(none)` (no INF) gave no actionable information.

**Investigation**:
- Empty `v`: `$p.Before.DriverVersion` was the empty string (Microsoft inbox class drivers leave the field blank for ACPI-enumerated devices that have no traditional version). The legacy display code's check `if ($p.Before) { $p.Before.DriverVersion } else { '(unknown)' }` only fell back to `'(unknown)'` for the null-Before case, not the empty-string-Version case.
- `(none)` INF: `$p.Candidate` was null. This indicates `Build-PatchedInfHwidIndex` did not have a HWID-keyed entry for this device's `PNPDeviceID`. The OS was still binding the device to *some* driver (whose `InfName` we knew via `$a.After.InfName`), but the display code's `if ($p.Candidate) { $p.Candidate.InfName } else { '(none)' }` could not surface that fallback.

**Fix**: Both checks are tightened:

```powershell
$bv = if ($p.Before -and $p.Before.DriverVersion) { $p.Before.DriverVersion } else { '(unknown)' }
$infName = if ($p.Candidate) {
    $p.Candidate.InfName
} elseif ($p.After -and $p.After.InfName) {
    ('(OS-bound: {0})' -f $p.After.InfName)
} else {
    '(none)'
}
```

Post-fix the display now reads e.g. `Still on v(unknown), new INF queued: (OS-bound: oem18.inf)`, which the operator can immediately cross-reference against I03's install log.

**Scope**: Cosmetic-only. No classification counters change. Applied to both Chipset and Graphics; the BthPan I04 has a separate display function (different disposition model) and is unaffected.

---

## D.19 BthPan I04 false-negative on detached-shell topology + language-independent matching (MSBthPan)

**Symptom**: On Japanese WS2025 Datacenter (build 26100.32860), the script reported `I04 OverallResult = PartialOrPhantom` and requested a reboot, despite the fact that bthpan.sys was loaded, the BthPan service was running, and `Bluetooth デバイス (パーソナル エリア ネットワーク)` appeared in the Network Connections control panel. Manual testing confirmed PAN connectivity worked. The reboot was unnecessary.

**Investigation**: Two independent bugs combined to mask true resolution:

1. **Detached-shell topology**. On modern Windows builds, after the patched bthpan.inf binds successfully, the parent device `BTH\MS_BTHPAN\<uid>` does NOT flip its own `Class` and `Service` to `Net` / `BthPan`. Instead, bthpan.sys is loaded against a **separate** Net-class device instance, and the parent remains as a "detached shell" with empty `Class`, `Service`, and `DriverInfPath`. `Get-MsBthPanDeviceState` inspected only the parent and therefore concluded the device was in a phantom state.

2. **Localized-string regex on a Japanese SKU**. `Test-BthPanRuntimeArtifacts.HasNetAdapter` matched `InterfaceDescription` against the legacy regex `'Bluetooth デバイス \(個人.*\)'`. Microsoft changed the localized string from `個人ネットワーク` to `パーソナル エリア ネットワーク` years ago, so the regex silently missed every Japanese WS2025 install. (English systems matched against a separate `'Bluetooth.*Personal Area Network'` regex and were unaffected.)

**Root cause**: Both bugs share the same anti-pattern — relying on **localized display strings** or **single-device parent inspection**. Microsoft can (and does) reword localized strings between builds, and PnP topology can split a logical driver across multiple device nodes.

**Fix**: Three coordinated changes, all using stable, never-localized identifiers exclusively:

1. **`Test-BthPanRuntimeArtifacts`** rewrites the `HasNetAdapter` test to match on three language-independent fields, any of which alone is sufficient:

   ```powershell
   foreach ($a in Get-NetAdapter -ErrorAction SilentlyContinue) {
       $byDriver    = ($a.DriverFileName -ieq 'bthpan.sys')      # file name
       $byComponent = ($a.ComponentID    -ieq 'ms_bthpan')        # INF #define
       $byPnpId     = ($a.PnPDeviceID    -match '^BTH\\MS_BTHPAN(?:XFER)?\\')
       if ($byDriver -or $byComponent -or $byPnpId) {
           $hasNetAdapter = $true; break
       }
   }
   ```

2. **`Get-BthPanNetChildBinding`** (NEW helper) enumerates *all* Net-class adapters bound to bthpan, using the same triple-match. Each result is enriched with the catalog signature (`Get-AuthenticodeSignature` on `$env:windir\INF\<infName>.cat`) and `IsSignedByUs` is set when the thumbprint matches `$Ctx.CertThumbprint`. Return shape:

   ```
   [pscustomobject]@{
       InstanceId, DriverInfPath, ServiceName,
       IsSignedByUs, CatThumbprint, MatchedBy[]
   }
   ```

3. **`Get-MsBthPanDeviceState`** adds a Net-child fallback: when the parent classifies as `'Other'` AND the host is not in error state, the helper is consulted. If a Net-class binding is found, classification is promoted to `'True'` with description `"detached-shell parent + Net child binding"`. The `NetChildBinding` field is propagated through to `Invoke-InstPhase04` Section 1 display.

**Language-independence rule (NEW SPEC contract)**:

> When matching against PnP / Net device properties for classification purposes, **only** the following fields are admissible:
> - `DriverFileName` (file name)
> - `ComponentID` (INF `#define`)
> - `PnPDeviceID` / `InstanceId` (PnP enumerator path)
> - `DriverInfPath` (file path)
> - `Service` (service name registered in `HKLM\SYSTEM\CurrentControlSet\Services`)
> - `ClassGuid` (immutable GUID)
> - `HardwareIDs` / `CompatibleIDs` (immutable HWID strings)
>
> `InterfaceDescription`, `FriendlyName`, `Description`, `Name`, and `Caption` are **localized** by Windows and **MUST NOT** be used for matching. They may be returned in result objects for human-readable display only.

**Scope**: BthPan only. The other three scripts already match on language-independent fields (HWID + ClassGuid for Chipset / Graphics; PCI VEN/DEV/REV for NPU); no changes required there.

**Verification**: On the same Japanese WS2025 host that previously reported `PartialOrPhantom`, the script now reports `I04 OverallResult = TrueResolution` and the I05 ForceRebind phase (see D.22) short-circuits as no-op. No reboot is required.

---

## D.20 Graphics I00 TO-BE display + Risk Summary deduplication

**Symptom**: For a single Phoenix-class Graphics device, `Invoke-InstPhase00_PreInstallReview` (Graphics) printed ~1000 TO-BE candidate rows and a Risk Summary `[MEDIUM] 1069 item(s)` line. The output was dominated by visually-identical duplicates, making review of the actual install plan impractical.

**Investigation**: AMD's display INF `u0197843.inf` (Adrenalin release) declares **5046** distinct `PCI\VEN_*&DEV_*&SUBSYS_*&REV_*` HardwareID variants in a single `[Strings]`-driven `[Manufacturer]` block. The legacy per-device candidate loop iterated over every HWID variant:

```powershell
foreach ($m in $matched) {              # one entry per resolved device
    foreach ($c in $m.Candidates) {     # 5046 HWID variants per matched INF
        Write-Detail "  TO-BE: $($c.InfName) ($($c.HardwareId))"
    }
}
```

The Risk Summary `[MEDIUM]` counter incremented inside the same nested loop, so `1069` was 1069 HWID-variant impressions of (much fewer) actual replacement decisions.

**Root cause**: The user-facing display unit should be **one row per `(InfName, SrcSubDir)` pair**, not one row per HWID variant. The HWID-variant count is operationally interesting (it tells the operator how many PCI products this INF covers) but not as a primary row count.

**Fix**: Two coordinated changes in `Invoke-InstPhase00_PreInstallReview` (Graphics only):

1. **TO-BE display deduplication**:

   ```powershell
   $groups = $matched.Candidates | Group-Object {
       '{0}|{1}' -f $_.InfName, $_.SrcSubDir
   }
   foreach ($g in $groups) {
       $first = $g.Group[0]
       $count = $g.Count
       $suffix = if ($count -gt 1) { " [+$count HWID variants]" } else { '' }
       Write-Detail "  TO-BE: $($first.InfName) ($($first.SrcSubDir))$suffix"
   }
   ```

2. **Risk Summary deduplication** via `$seenPairs` hashtable keyed on `'{Device.InstanceId}|{InfName}|{SrcSubDir}'`. The `[MEDIUM]` counter increments only on first-seen keys.

**Scope**: Graphics only. Chipset's INFs declare modest HWID counts (typically &lt; 20 per INF) and Risk Summary noise was not a practical issue. NPU and BthPan match against a single canonical HWID per device and are structurally immune to this class of bug.

**Verification**: On the same Phoenix-class host as the symptom, `[MEDIUM]` count now reports ~5 items (one per actual device-INF replacement decision), with `[+5046 HWID variants]` annotation on the one INF that has that many. Reduction in row count is approximately 95% on AMD's Adrenalin release.

---

## D.21 Chipset P04 sub-MSI 1603 per-failure diagnostics

**Symptom**: On rare occasions (observed once on a WS2022 host, not reproducible on WS2025), the Chipset script's I04 `PostInstallVerification` reported one missing payload binding even though I03 reported all driver installs successful. Subsequent troubleshooting was blind because the relevant sub-MSI logs in `%TEMP%\MSI*.LOG` had already been rotated out by the time the operator started investigating.

**Investigation**: The Chipset script's P04 stage launches AMD's main installer EXE, which in turn fires a tree of sub-MSIs (`MSI*.MSI`). The script's **Nested loop** wraps the EXE invocation and retries on transient failures, so the parent EXE typically reports success on its second or third attempt. Individual sub-MSI failures are silently absorbed by the parent retry — which is the right behaviour for normal operation, but leaves no breadcrumb when the *final* device state still shows a missing payload after the Nested loop completes.

**Root cause**: P04's existing diagnostics captured the parent EXE exit code only. Sub-MSI exit codes and per-MSI log content were thrown away as part of the retry-and-forget pattern. The information needed for post-mortem (which MSI failed, what error pattern, what was in TARGETDIR at failure time) was discarded.

**Fix**: Per-failure diagnostic capture is added inside the Chipset P04 sub-MSI iteration loop (around line 5814). For each non-zero sub-MSI exit code:

1. **Log tail**: `Get-Content -Tail 100` on the matching `%TEMP%\MSI*.LOG`.
2. **Pattern classification** (regex on the tail):

   | Pattern | Classification |
   |---|---|
   | `Error 1304` | source media unreadable |
   | `Error 1335` | corrupt cabinet |
   | `Error 1612` | source not available |
   | `SEC(URE)?REPAIR:\s+.*Error:\s*3` | **1603 SECREPAIR missing source files (AMD MSI packaging defect; sub-MSI declares files in File table that are not packaged in its cabinet)** — added in r65, see §D.24 for the full investigation. |
   | `Error 1925` | elevation required |
   | `Error 1310` | file collision |
   | `CustomAction \w+ returned actual error code 1603` | CA crash |
   | `Return value 3` | generic install-script abort |
   | `disk full|out of disk space` | disk space |

3. **TARGETDIR snapshot** at failure time: `Exists`, `InfCount`, `FileCount`, `LastWriteHint`.
4. **Aggregation**: Per-MSI diagnostic blob is appended to `$subFailDiag`, then dumped to `$logRoot\submsi-failures-diag.txt` with a pattern-frequency summary header at the top.

**Important constraint**: This is a **diagnostics-only** change. The Nested-loop retry behaviour is preserved verbatim — sub-MSI failures are still silently recovered by retry, and the user-visible P04 status still reports success when the Nested loop ultimately succeeds. The diagnostic file `submsi-failures-diag.txt` is created only when at least one sub-MSI failed at some point during the run, even if the parent EXE ultimately succeeded.

**Scope**: Chipset only. Graphics uses a different installer architecture (single EXE, no nested MSIs), NPU uses pnputil directly (no MSI involvement), and BthPan has no installer phase at all. The pattern in this fix could be adapted to Graphics if AMD ever ships a Graphics MSI tree, but is not currently applicable.

**Verification**: On a deliberately-induced sub-MSI failure (renamed cab file mid-install to trigger 1335), `submsi-failures-diag.txt` contains the expected pattern classification and TARGETDIR snapshot. Normal runs (no sub-MSI failures) do not create the file at all.

---

## D.22 BthPan I05 ForceRebind phase + cross-script WS2019 CIM bridge (Multi-OS support)

**Symptom (BthPan)**: Even after D.19's true-resolution detection fix, certain stuck-driver states on previously-broken WS2025 hosts (e.g., after manual `pnputil /remove-device` cleanup followed by re-install) genuinely produced a phantom-OK condition that required a reboot to clear. The reboot was unavoidable on the legacy code path.

**Symptom (Chipset / Graphics / NPU)**: On WS2019, all WDAC-using scripts required a reboot to activate their supplemental policy, because `CiTool.exe` is absent on WS2019 (it was introduced in WS2022 / build 20348). The reboot was a regression compared to WS2022 / WS2025 (where `CiTool.exe --update-policy` activates immediately) and was a poor operational experience for WS2019 admins.

**Root cause**: Both symptoms reflect a **Multi-OS capability gap**:

- BthPan needed an in-script "force the driver to re-enumerate" sequence with graceful degradation across OS versions (because `Restart-PnpDevice` was introduced in WS2019 and is absent on WS2016).
- Chipset / Graphics / NPU / BthPan all needed an intermediate WDAC activation path for WS2019 (where `CiTool.exe` is absent but the WMI/CIM bridge `PS_UpdateAndCompareCIPolicy` IS present).

**Fix (E-1) — BthPan `Invoke-InstPhase05_ForceRebind` (new phase)**:

The phase activates **only** when `$Ctx.I04OverallResult -eq 'PartialOrPhantom'`. On `TrueResolution` or `NoDevice`, the phase is a no-op (with explicit `Write-Skip` log entry). When activated, it iterates over `$Ctx.I04PerDeviceResults` and runs the following cascade per stuck device, stopping at the first success and re-evaluating `Get-MsBthPanDeviceState` after each attempt:

| # | Tool | Available on |
|---|---|---|
| 1 | `Restart-PnpDevice -InstanceId <id> -Confirm:$false` | WS2019+ |
| 2 | `Disable-PnpDevice` → `Enable-PnpDevice` | WS2019+ |
| 3 | `pnputil.exe /remove-device <id>` → `pnputil.exe /scan-devices` | WS2016+ |
| 4 | `Stop-Service BthPan` → `Start-Service BthPan` | All WS |

Capability detection is centralized in `Get-RebindCapability`, which probes `Get-Command` for each cmdlet and returns a `[pscustomobject]` flag bag. Missing cmdlets on WS2016 cause the corresponding attempts to be skipped (not error out).

On success: `$Ctx.I04OverallResult` is **promoted** to `'TrueResolution'`, `$Ctx.I05OverallResult = 'Recovered'`, and `Clear-PendingRebootMarker` is called to suppress the spurious reboot request. On exhaustion: `$Ctx.I05OverallResult = 'StillFailing'` and the reboot request stands.

Phase registry entry (alphabetical with sibling I0n phases):

```powershell
[pscustomobject]@{ Id='I05'; Name='ForceRebind';
                   Group='Inst'; Func='Invoke-InstPhase05_ForceRebind' }
```

Workstation-install action gate regex updated from `^I0[0-4]$` to `^I0[0-5]$`. New Ctx fields initialized in `New-MsBthPanContext`: `I05OverallResult` (`'Recovered'` | `'StillFailing'` | `$null`) and `I05PerDeviceResults` (array of per-device cascade outcomes).

**Fix (E-2) — Cross-script WS2019 CIM bridge for WDAC policy activation**:

Between the existing `CiTool.exe --update-policy --json` path (WS2022+) and the reboot fallback, all four WDAC-deploying functions now attempt the WMI/CIM bridge:

```powershell
if (-not $immediate) {
    $cimBridgeTried = $true
    try {
        $cimResult = Invoke-CimMethod `
            -Namespace 'root\Microsoft\Windows\CI' `
            -ClassName 'PS_UpdateAndCompareCIPolicy' `
            -MethodName 'Update' `
            -Arguments @{ FilePath = $deployedPath } `
            -ErrorAction Stop
        if ([int]$cimResult.ReturnValue -eq 0) {
            $immediate = $true   # activated without reboot on WS2019
        }
    } catch {
        $cimBridgeError = $_.Exception.Message   # WS2016: class absent
    }
}
```

The CIM class `PS_UpdateAndCompareCIPolicy` is present on WS2019+ and hot-loads supplemental policies without reboot. On WS2016 the class does not exist; `Invoke-CimMethod` throws and the catch block silently records the error, allowing the existing reboot fallback to proceed.

Three new return fields are added to the result object: `CimBridgeTried`, `CimBridgeStdout`, `CimBridgeError`. The `ActivationMethod` label distinguishes the three paths:

- `'CiTool (immediate, no reboot)'` (WS2022+)
- `'CIM bridge (PS_UpdateAndCompareCIPolicy, no reboot)'` (WS2019)
- `'reboot'` (WS2016, or any failure on WS2019+ that did not produce an immediate-activate result)

**OS support matrix (cross-script, post-fix)**:

| Capability | WS2025 | WS2022 | WS2019 | WS2016 |
|---|---|---|---|---|
| WDAC activation: `CiTool.exe --json --update-policy` | ✓ | ✓ | absent | absent |
| WDAC activation: `PS_UpdateAndCompareCIPolicy` CIM bridge | (skipped) | (skipped) | ✓ | class absent |
| WDAC activation: reboot via `-UseTestSigning` switch | ✓ | ✓ | ✓ | ✓ |
| I05 Attempt 1: `Restart-PnpDevice` | ✓ | ✓ | ✓ | absent |
| I05 Attempt 2: `Disable/Enable-PnpDevice` | ✓ | ✓ | ✓ | absent |
| I05 Attempt 3: `pnputil /remove-device + /scan-devices` | ✓ | ✓ | ✓ | ✓ |
| I05 Attempt 4: `Stop/Start-Service BthPan` | ✓ | ✓ | ✓ | ✓ |

**Scope**:
- E-1 (`Invoke-InstPhase05_ForceRebind`): BthPan only. The other three scripts have no analogous phantom-driver state to recover from — their I04 verification reads HWID-bound device state, which cannot exhibit the detached-shell topology that motivates I05.
- E-2 (WS2019 CIM bridge): All four scripts. The implementation in each script is functionally identical; minor structural divergence (NPU has a slightly different control-flow shape due to its single-policy architecture) is permitted under PSA8001 because the affected functions (`Install-AmdWdacPolicy`, `Install-WdacPolicy`, `Install-MsBthPanWdacPolicy`) are listed in the per-script-divergence exclusion list.

**Verification**:
- On Japanese WS2025 (build 26100.32860) with the originally-broken bthpan state: D.19 fixes deliver TrueResolution; I05 short-circuits as no-op. ✓
- On a deliberately-broken WS2025 state (manual driver removal): D.19 detects phantom; I05 Attempt 1 (`Restart-PnpDevice`) recovers; `I04OverallResult` promoted to `'TrueResolution'`; no reboot. ✓
- WS2019 + WS2016: not yet verified on real hardware. The capability matrix above is derived from Microsoft documentation; field validation is pending. (Tracking in `TESTING.md` §multi-OS validation.)

### D.22b I05 phase-footer status: `'no-op'` → `'skipped'` (ValidateSet compliance)

**Symptom (operator log, Japanese WS2022 Datacenter, build 20348)**: I05 raised a hard PowerShell error on the early-return paths even though the user-facing `Write-Skip` line had logged correctly:

```
[I05] Skip: I04 result is TrueResolution - no rebind needed. I05 is a no-op.
Cannot validate argument on parameter 'Status'. The argument "no-op" does not
belong to the set "done,cached,skipped,failed" specified by the ValidateSet
attribute. Supply an argument that is in the set and then try the command again.
    + CategoryInfo          : InvalidData: (:) [Write-PhaseFooter], ParameterBindingValidationException
    + FullyQualifiedErrorId : ParameterArgumentValidationError,Write-PhaseFooter
```

**Investigation**: Two early-return paths in `Invoke-InstPhase05_ForceRebind` were calling `Write-PhaseFooter 'I05' 'no-op'`:
1. `$Ctx.I04OverallResult -in @('TrueResolution', 'NoDevice')` (rebind not needed because the prior phase already detected success)
2. `Get-MsBthPanDevice` returned an empty array (no `BTH\MS_BTHPAN` device on the host)

But the `Write-PhaseFooter` cmdlet's parameter contract is:

```powershell
function Write-PhaseFooter {
    param(
        [Parameter(Mandatory)] [string]$PhaseId,
        [Parameter(Mandatory)]
        [ValidateSet('done','cached','skipped','failed')]
        [string]$Status,
        ...
    )
    ...
}
```

`'no-op'` is not in the allowed set; the ValidateSet attribute throws `ParameterArgumentValidationError` before the function body executes.

**Root cause**: The string `'no-op'` was used as if it were a valid footer status, presumably copied from the user-facing `Write-Skip 'I05 is a no-op'` wording. The two concepts are independent:
- `Write-Skip` is a Write-Host wrapper that accepts free-form text for operator-facing logging.
- `Write-PhaseFooter`'s `$Status` is a *machine-readable* status token consumed by the dispatcher (`Invoke-PhaseRunner`), debug-trace JSONL emission, and the cached-marker logic (see SPEC §A.4). It must be one of the four enum values.

**Fix**: Both `'no-op'` literals are replaced with `'skipped'` (the most semantically appropriate enum member: the phase decided not to execute its primary logic, no error occurred). The user-facing `Write-Skip` lines that say "no-op" are preserved verbatim, so the operator's log experience is unchanged for the wording; only the machine-readable footer token is corrected.

The third `Write-PhaseFooter 'I05' 'done'` call on the successful-rebind branch is unaffected (`'done'` was already a valid enum member). The first early-return `Write-PhaseFooter 'I05' 'skipped'` (when `$Ctx.I04OverallResult` is null) was also already correct.

**Scope**: BthPan only (I05 is BthPan-specific per SPEC §A.4 phase registry). The "no-op" wording is preserved in the user-facing `Write-Skip` line for operator-visible continuity; only the footer-status token changes.

**Verification**:
- Pre-fix: pipeline returns non-zero exit code from I05 even when the user-visible log shows successful no-op handling.
- Post-fix: pipeline exits cleanly; debug-trace JSONL records `{"phase":"I05","status":"skipped","reason":"TrueResolution|NoDevice|no device"}` and the cached-marker is set as expected.

---

## D.23 Mixed line endings in programmatically emitted `.ps1` content (Python-script defect)

**Symptom**: A ZIP archive of the repository was prepared in a working directory, delivered, and committed to GitHub. After commit, `git pull` followed by a byte-level diff against the originally-delivered ZIP showed that exactly one of the four `.ps1` scripts had grown by **+105 bytes** for no visible content reason. PowerShell `AST 0 errors` and visual inspection both passed; the discrepancy did not surface until a byte-counting verification was run after the commit.

**Investigation (verification trail)**: The 105-byte delta was traced to a contiguous 105-line region (`Get-BthPanNetChildBinding` function body, lines 4675–4779 in `Deploy-MSBthPanInboxOnWindowsServer.ps1`). Counting CR and LF bytes directly (rather than relying on line counts):

```
Pre-commit (ZIP):        LF=10205   CR=10100   LF-only lines=105   size=507514
Post-commit (GitHub):    LF=10205   CR=10205   LF-only lines=  0   size=507619
                                                                   delta=+105
```

LF-byte count is identical, but CR-byte count grew by 105 — exactly the line count of the inserted function. The pre-commit file had 105 lines terminated by LF only (no CR), embedded in a file whose other 10100 lines were correctly CRLF-terminated. `git add` applied the `.gitattributes` rule `*.ps1 text working-tree-encoding=UTF-8 eol=crlf` and rewrote those 105 lines to CRLF at commit time, producing the byte delta after `git pull`.

The defective lines all came from a single source: a Python helper script used to insert the `Get-BthPanNetChildBinding` function into the BthPan `.ps1`. The Python script used a triple-quoted string literal for the function body — Python's string literals terminate lines with LF on every platform regardless of the source-file's own line endings. The script then concatenated this LF-only block between two CRLF regions of the original `.ps1`, producing a file with mixed line endings.

**Root cause**: Programmatic content generation that uses language defaults (Python `"""..."""`, Python `open()` text-mode write, Bash heredoc, JavaScript template literals, Go raw strings, etc.) emits LF-only output regardless of the destination file's line-ending convention. The defect is invisible to:

- **PowerShell's AST parser** — accepts mixed line endings as valid.
- **Visual diff tools** — display lines, not bytes; LF and CRLF render identically.
- **`grep`-based "line containing CR" counts** — count *matching lines*, not CR bytes; consecutive CRs on adjacent lines don't change the count meaningfully on inspection.
- **The static analyser `psa.py`** — at the time of the defect, `PSA7001` checked for BOM presence and "predominantly CRLF" but did not assert *all* lines are CRLF. (Subsequent rule strengthening is tracked separately.)

The defect surfaces only when:

- A byte-level diff runs against a committed (`.gitattributes`-normalised) copy.
- An equality check on CR-byte-count vs. LF-byte-count is performed explicitly.
- A `.ps1` script that has mixed line endings is loaded by a tool that strictly requires CRLF (signtool's catalog inspection on some older builds, certain MSI authoring tools).

**Fix (immediate)**: The committed GitHub copy is correct because `.gitattributes` normalised at commit time. No code change is required to recover from the specific occurrence. The structural fix is to prevent recurrence by:

1. **Update all repository-internal Python content-generation scripts** to emit CRLF + BOM bytes explicitly. The canonical pattern is binary-mode write with explicit BOM prefix and `\n` → `\r\n` substitution applied to the encoded text. See A.2.2 Rule 1 for the exact code.
2. **Add a pre-commit verification step** (manual or scripted) that runs the byte-count equality check in A.2.3. A failed check is a signal to investigate *before* `.gitattributes` silently rewrites the file.
3. **Document the contract** so future contributors (human or AI agent) emit conforming bytes at the source. The expanded A.2 section is the canonical reference.

**Why `.gitattributes` did not prevent the defect from reaching the ZIP**: The ZIP archive was generated from the working tree directly, without going through `git add` first. `git archive` would have applied the `eol=crlf` normalisation at archive time (because `git archive` honours `export-subst` and `text` attributes), but the ZIP in question was created with `zip -r` from the working tree — which copies bytes verbatim. Result: the ZIP carried the LF-only defect; the next `git add` (performed by the recipient when committing) normalised it.

**Lessons learned**:

- **AI-agent file generation is a high-risk source of this defect.** Tools that "write a file" via a programming-language abstraction (Python `open()`, Node's `fs.writeFile`, etc.) default to platform-native line endings on the host where the agent runs — Linux for most cloud-hosted agents. The output is LF-only regardless of the destination file's convention. Agents authoring `.ps1` content must apply A.2.2 Rule 1 every time.
- **Visual inspection and AST parsing are necessary but not sufficient** for `.ps1` correctness. The full verification surface is:
  - UTF-8 BOM present (first 3 bytes `EF BB BF`).
  - CR-byte count equals LF-byte count (every LF preceded by a CR).
  - AST parse 0 errors.
  - `psa.py` 0 errors.
- **A ZIP archive of working-tree files bypasses `.gitattributes` normalisation.** When packaging a repository for offline delivery, run the A.2.3 verification commands first; do not assume the committed-form bytes will be in the archive.
- **`git archive` is the safer alternative to `zip -r`** for repository snapshots, because it applies attributes at archive time. `git archive --format=zip HEAD -o snapshot.zip` produces normalised content; `zip -r snapshot.zip .` does not.

**Quick-reference checklist for any tool / agent emitting `.ps1` content**:

1. Open the destination in binary mode (or set `newline='\r\n'` on a text-mode stream).
2. Write `\xef\xbb\xbf` as the first three bytes if creating from scratch.
3. Convert every `\n` in the payload to `\r\n` before writing.
4. After writing, run `tr -cd '\r' < file | wc -c` and `tr -cd '\n' < file | wc -c`; they MUST be equal.
5. Run `head -c 3 file | od -An -t x1`; output MUST be `ef bb bf`.
6. Run PowerShell AST parse; expect 0 errors.
7. Run `psa.py` on the file; expect 0 errors.

Steps 4–7 are independent — passing one does not imply passing the others. The defect described in this entry passes steps 5–7 and fails step 4.

**Scope**: Affects any future contribution that programmatically produces `.ps1` content — Python helpers, Bash heredocs, AI-agent file-write actions. Documentation contributions (`.md` files) are subject to the inverse contract: LF-only without BOM (see A.2.1). The same class of defect — mixed line endings — could manifest in `.md` if a `\r\n`-producing tool writes into an LF-only file; the symptom would be GitHub rendering showing stray `^M` markers in code blocks or other formatting glitches.

**Cross-references**:
- A.2.1 — Per-file-type contract.
- A.2.2 — Tooling rules (the corrective patterns).
- A.2.3 — Verification commands.
- A.2.4 — Why `.gitattributes` is a safety net, not a contract.

---

## D.24 Phantom file reference detection + pipeline-wide skip (Chipset)

**Symptom**: On a clean-installed Windows Server 2019 host (build 17763) running `-Action PrepareVerify` against AMD Chipset Software `8.05.04.516`, P08 (`GenerateCatalogs`) reported `59 ok / 1 failed` with the following per-folder log entry for `Chipset_Software\CIR Driver\WTx64`:

```
22.9.1: amdcir.sys in [amdcir.files] of WTx64\amdcir.inf is missing
or cannot be decompressed from source media. Please verify all path
values specified in SourceDisksNames, SourceDisksFiles, and CopyFiles
sections resolve to the actual location of the file, and are
expressed in terms relative to the location of the inf.
```

P04 had separately reported `25 succeeded, 12 failed` at the `msiexec /a` sub-MSI stage, with all 12 failures classified as `unknown` in the resulting `submsi-failures-diag.txt`. The Nested-loop recovery subsequently reported all 37 sub-MSIs as `exit=0`, masking the original failure.

The script's r64 behaviour was to flag P08 as `1 failed` (correct) but to provide no actionable path forward: there was no diagnostic linking the catalog failure to the upstream sub-MSI failure, and no mechanism for the downstream pipeline (P09 sign / V03 verify / V05 dry-run / V06 hardware-impact / I03 install) to handle the affected INF cleanly.

**Investigation**:

The `CIR Driver\WTx64` directory contained only four files after P04 completed:

```
amdcir.cat        (10396 bytes, 2015-05-11 — AMD's original WHQL-signed catalog)
AMDCIR.inf        (2896 bytes,  2015-05-11)
AMDCIR64.sys      (81424 bytes, 2015-05-11 — 64-bit driver binary)
ReadMe.rtf
Release_Notes.txt
```

Inspection of `AMDCIR.inf` revealed a **dual-arch INF** that declares both a 32-bit binary (`AMDCIR.sys`) and a 64-bit binary (`AMDCIR64.sys`) in its `[SourceDisksFiles]` section. inf2cat scans **all** `CopyFiles` sections (`[AMDCIR.Files]` and `[AMDCIR64.Files]`) and requires every referenced file to exist on disk regardless of the host architecture. The 32-bit binary `AMDCIR.sys` was never produced because:

1. The AMD MSI `AMD-Consumer_Infrared-Driver.msi` declares a File table that references files across four OS variants (`W7x64`, `W7x86`, `WTx64`, `WTx86`).
2. The MSI cabinet, however, only physically packages the `WTx64` subset.
3. `msiexec /a` (administrative install with ACTION=ADMIN) reaches the `InstallAdminPackage` action, partially extracts the `WTx64` files, then fails when SECREPAIR attempts to hash the missing files for `W7x64` / `W7x86` / `WTx86`:

```
SECREPAIR: Failed to open the file:...\CIR Driver\W7x64\AMDCIR.cat ... Error:3
SECREPAIR: Failed to open the file:...\CIR Driver\W7x86\AMDCIR.cat ... Error:3
SECREPAIR: Failed to open the file:...\CIR Driver\WTx86\amdcir.cat ... Error:3
SECREPAIR: Failed to open the file:...\CIR Driver\W7x64\AMDCIR64.sys ... Error:3
...
```

`Error: 3` is `ERROR_PATH_NOT_FOUND`. The sub-MSI returns 1603 (`MainEngineThread is returning 1603`), but the WTx64 files that had been partially extracted remain on disk. Subsequent inf2cat invocation therefore sees `AMDCIR.inf` + `AMDCIR64.sys` present but `AMDCIR.sys` (the 32-bit binary referenced by the same INF) absent.

**Root cause**: An AMD MSI packaging defect specific to `AMD-Consumer_Infrared-Driver.msi` in Chipset Software `8.05.04.516` (the CIR Driver is from 2015 and targets very old AMD APUs with infrared remote receivers; the 32-bit binary was likely retired from the cabinet at some point but the File table entries were left intact). This is not a defect in the script's extraction, patching, or catalog-generation logic.

**Hardware impact on the observed environment**: The reporting host was a Lenovo X13 Gen 1 with Ryzen 5 PRO 4650U (Renoir, Zen 2 Mobile, 2020). CIR devices (HWID `*AMDC001` / `*AMDC002` / `*AMDC003`) are absent from this platform — V06's hardware-impact analysis listed 42 AMD entities, zero of them CIR. The catalog failure therefore had no install-time effect; it was a noise-in-the-pipeline issue rather than a functional regression.

**Fix scope (r65)**:

The fix takes a **detect-and-skip** approach. INF content is never rewritten beyond the existing ProductType=3 decoration scope (which is the script's stated mandate; see §A.6). An INF that declares files in `[SourceDisksFiles*]` that are not physically present on disk is **flagged as ineligible for catalog generation** and skipped at each downstream phase, while remaining physically present in `patched/` for diagnostic traceability.

The alternative approach of normalizing the INF — removing `[SourceDisksFiles]` entries for absent files, plus the related `[*.Files]` sections — was explicitly rejected. Stripping a 32-bit code path from a dual-arch INF to satisfy inf2cat would expand the script's responsibility from "decorate INFs for Server SKUs" to "selectively repair AMD packaging defects". The latter is out of scope and risks unanticipated side effects on INFs that may be more nuanced than CIR (e.g. INFs whose `[CopyFiles]` references differ from their `[SourceDisksFiles]` declarations, or INFs that intentionally co-package 32-bit and 64-bit binaries for cross-arch driver-store use).

**Implementation**:

1. **New helper `Get-InfReferencedFile`** (chipset script).

   Parses the INF's `[SourceDisksFiles]` and `[SourceDisksFiles.<arch>]` sections, returns a list of `{Name, Section, Present, Path}` objects. Files are searched only in the INF's own directory (flat lookup). `SourceDisksNames` subdir resolution is deliberately not implemented yet because the AMD chipset 8.x package keeps source files alongside the INF; future packages with multi-disk layouts may need extension here. The function returns an empty array when the INF directory does not exist or when the INF has no `[SourceDisksFiles*]` section (modern AMD INFs often omit it entirely and rely on relative paths via `[DestinationDirs]` / `CopyFiles=`; these are eligible by construction because absence of the manifest means no missing-file claim can be made).

2. **P05 (`AnalyzeInfs`) extension**.

   Three new columns are added to `inf_inventory.csv` and `$Ctx.InfInventoryDetail`:

   | Column | Type | Description |
   |---|---|---|
   | `ReferencedFilesCount` | int | Number of distinct files declared in `[SourceDisksFiles*]`. |
   | `MissingReferencedFiles` | string | `;`-joined list of filenames whose physical file is absent from the INF directory. Empty when all referenced files are present. |
   | `EligibleForCatalog` | bool | `true` when `MissingReferencedFiles` is empty, `false` otherwise. |

   The existing `NeedsPatch` column gains an additional conjunct: `… -and $eligibleForCatalog`. An ineligible INF is therefore never patched (decoration is not applied because the resulting catalog would be skipped anyway).

   When at least one SELECTED-variant INF is ineligible, P05 emits a console summary block:

   ```
   [!] INFs ineligible for catalog generation (phantom file references): N
     Cause   : AMD MSI packaging defect (declared source files not packaged in cabinet)
     Action  : P06 will skip-copy / P08 will skip inf2cat / P09 will skip sign / V03..V06 + I03 will skip
     Tracked : MissingReferencedFiles column in inf_inventory.csv

     - AMDCIR.inf                     variant=WTx64   missing: AMDCIR.sys
   ```

   The P05 phase marker gains a new `Ineligible=$N` metadata field.

3. **P06 (`PatchInfs`) notification**.

   Ineligible INFs naturally flow into the `copyOnly` bucket (because `NeedsPatch` is false) and are physically copied to `patched/`. P06 emits an informational log line listing each ineligible INF so operators understand that some INFs in `patched/` exist for traceability only and will be skipped downstream:

   ```
   Note: 1 INF(s) will be copied for traceability but skipped at P08 (phantom file references):
     - AMDCIR.inf                     missing: AMDCIR.sys
   ```

   No behavior change beyond the log line — the existing copy loop continues to copy as before.

4. **P08 (`GenerateCatalogs`) skip filter**.

   The inf2cat loop is rewritten to iterate `$infDirsToProcess` (= `$infDirs` minus directories whose INFs are ineligible). The summary line is extended to a tri-state form:

   ```
   [+] Catalog generation: 59 ok / 0 failed / 1 skipped (using /os:ServerRS5_X64)
   ```

   The legacy two-state form is preserved when `skipped = 0`. The "EVERYTHING failed" `throw` is updated to check `$infDirsToProcess.Count` (post-filter) rather than `$infDirs.Count` (pre-filter), so a workspace where all INFs are ineligible reports `0/0/N` rather than throwing. The P08 phase marker gains a `Skipped=$K` metadata field.

   **Fallback for standalone `-OnlyPhases P08` execution**: when `$Ctx.InfInventory` is unset (because P05 was not invoked in the same session), P08 attempts to load `inf_inventory.csv` from the workspace root. If the CSV is also absent (e.g. very old workspaces predating r65), the filter degrades to a no-op and the legacy "no filter" behavior is preserved.

   **Backwards compatibility with pre-r65 CSV files**: rows from a pre-r65 CSV lack the `EligibleForCatalog` column. The filter treats absence as "eligible" (preserving legacy behavior).

5. **P09 (`SignCatalogs`)**.

   No code change. P09 enumerates `.cat` files under `patched/`; since P08 produces no `.cat` for skipped directories, P09 naturally has nothing to sign for those INFs. The signing count therefore correctly excludes skipped INFs without any explicit branching in P09 itself.

6. **P04 sub-MSI pattern classifier extension** (§D.21 table).

   A new `elseif` branch is added to the regex-based pattern classifier in P04's per-failure diagnostic capture loop: `SEC(URE)?REPAIR:\s+.*Error:\s*3` → `1603: SECREPAIR missing source files (AMD MSI packaging defect; sub-MSI declares files in File table that are not packaged in its cabinet)`. This causes `submsi-failures-diag.txt`'s pattern-frequency summary to surface "12 x 1603: SECREPAIR ..." rather than "12 x unknown" on packages exhibiting the CIR-class defect, providing immediate forensic context for any future occurrence.

7. **Downstream verify + install phases (V03 / V04 / V05 / V06 / I03)** — pipeline-wide skip via shared helpers.

   Two new top-level helper functions consolidate the skip predicate so every downstream phase uses identical logic:

   - **`Get-IneligibleInfLookup -Ctx $Ctx`** returns a hashtable keyed by the patched-root-relative path of each ineligible INF (lowercased), with the inventory row as the value. Uses `$Ctx.InfInventory` when available; falls back to `Import-Csv` on `inf_inventory.csv` when running phases in isolation (`-OnlyPhases V0n` / `-OnlyPhases I03`). Returns an empty hashtable when the inventory is unavailable or predates r65 (no `EligibleForCatalog` column), preserving legacy behaviour.

   - **`Test-InfIsIneligible -Ctx $Ctx -InfFullName $path -Lookup $lookup`** performs the per-INF skip check by computing the patched-root-relative path and testing membership in `$Lookup`. Returns `$false` when the lookup is empty, which is how the no-data path degrades to legacy behaviour.

   Each phase's integration:

   | Phase | Integration point | What changes |
   |---|---|---|
   | V03 (`VerifyCatalogs`) | After enumerating `.cat` files | Adds a one-time `[~]` notice listing ineligible INFs. The `.cat` enumeration naturally excludes them (no `.cat` was produced at P08), so V03's per-catalog loop is unchanged. |
   | V04 (`VerifyInfs`) | Before the ProductType=3 decoration loop | Splits the enumerated INFs into `$infsToVerify` and `$skippedInfs`. The summary line becomes tri-state: `INF verification: N ok / M missing decoration / K skipped`. |
   | V05 (`DryRunInstall`) | Inside the I03 dry-run sub-section | Splits the enumerated INFs into `$infsToPlan` and `$infsToSkip`. The dry-run install plan iterates only `$infsToPlan`, with a dedicated `[~]  Excluding N INF(s) from dry-run plan ...` block listing the skipped INFs. |
   | V06 (`HardwareImpactAnalysis`) | Inside `Build-PatchedInfHwidIndex` plus a notice at the top of V06's output | Ineligible INFs are excluded from the HWID-to-INF index, so V06's AS-IS / TO-BE comparison does not propose them as TO-BE candidates for any matched device. V06 also surfaces the count up front via a `[~]` notice. |
   | I03 (`InstallDrivers`) | Right after the initial INF enumeration, before the resume-check | Splits enumerated INFs into `$infsToInstall` and `$infsToSkip`. The skipped INFs are listed with the explanation "no .cat exists; would have failed pnputil signature check". When the filter leaves zero INFs (wholly broken AMD package), I03 reports a success no-op rather than throwing. |

**Cross-phase invariants enforced by r65** (extended in r66 for `.cat` artifact hygiene):

- Every phase that walks `patched/` for INFs (P06 / P08 / V03 / V04 / V05 / V06 / I03) uses the same source-of-truth predicate (`EligibleForCatalog` via the shared lookup helpers).
- An INF that P05 marked ineligible never gets a `.cat`, never has its `[Manufacturer]` decoration verified, never appears in the dry-run install plan, never appears as a TO-BE candidate in V06's hardware impact, and never gets passed to `pnputil`. It does remain physically present in `patched/` for diagnostic traceability — operators can grep its INF / inspect it / re-inspect P05's CSV row at any time.
- **r66 extension**: any `.cat` file that P06 transitively copied alongside an ineligible INF (the original AMD-shipped catalog) is **deleted at P08's skip step** and additionally **filtered at P09's enumeration**. The directory ends up `.cat`-free, V01's `Catalog files: N` count matches P08/P09's `N ok`, and no orphan catalog gets re-signed with the self-signed cert. See "r66 orphan .cat cleanup" below.
- `submsi-failures-diag.txt` correctly classifies the original P04 sub-MSI failures (12 x SECREPAIR pattern) rather than reporting them as `unknown`.

**r66 orphan .cat cleanup (added 2026-05-22 after r65 real-machine validation)**:

The r65 implementation correctly skipped `inf2cat` at P08 for ineligible directories but left the original AMD-shipped `.cat` files in place (P06 had copied them as part of its wholesale directory copy for traceability). The downstream P09 then enumerated `Get-ChildItem -Recurse -Filter *.cat` and re-signed those orphans with the self-signed cert. Observable consequences on the 2026-05-22 Renoir run:

| Phase | r65 (defect) | r66 (fixed) |
|---|---|---|
| P08 summary | `55 ok / 0 failed / 5 skipped` | `55 ok / 0 failed / 5 skipped` |
| P08 console | (no cleanup line) | `Cleaned N orphan .cat file(s) from skipped directories` (when N > 0) |
| P09 signing count | **60** ok (5 orphans re-signed silently) | **55** ok (orphans filtered out; `+ 5 skipped` displayed when present) |
| V01 catalog count | **60** .cat files | **55** .cat files |
| V03 verification | 60 catalogs verified (5 of them orphans) | 55 catalogs verified |
| V03 notice text | `"no .cat exists"` (technically incorrect: .cat existed) | accurate (no .cat exists in skipped dirs) |
| I03 install | unaffected (filter is per-INF, not per-cat) | unaffected (same) |

Two cooperating defense layers (B + C):

- **Layer B — P08 cleanup**: inside the existing `if ($ineligibleDirs.Count -gt 0)` block, after reporting the skip, the script enumerates `.cat` files in each ineligible directory and deletes them. A summary line `Cleaned N orphan .cat file(s) ...` surfaces the operation. Failure to delete (e.g., file locked) emits a `[warn]` and continues — cleanup is best-effort and Layer C catches any survivor.
- **Layer C — P09 filter**: a sister helper `Get-IneligibleDirSet -Ctx $Ctx` returns a hashtable of patched-root-relative directories that contain ineligible INFs (keyed by `RelativeDir`, lowercased). Right after `Get-ChildItem -Recurse -Filter *.cat`, P09 partitions the result into `$catsKeep` (signed) and `$catsToSkip` (logged and excluded). A `[~]  Excluding N orphan .cat file(s) ...` block surfaces the operation. When the filter leaves zero `.cat` files (entirely defective AMD package), P09 reports a success no-op rather than throwing. The P09 phase marker gains a `Skipped` field for symmetry with P08.

The two layers together ensure that:

1. **Normal run (Prep* + Verify* in one invocation)**: P08 deletes orphans, P09 sees zero, no filter line printed (`catsToSkip.Count = 0`).
2. **Standalone P09 (`-OnlyPhases P09`)**: P08 didn't run in this session, P09's filter catches the orphans that P06 left behind.
3. **Recovered r65 workspace**: orphans inherited from a prior r65 run, P09's filter catches them.
4. **Future code-path regression**: even if some future P06/P07/P08 change re-creates orphans, P09's filter is a backstop.

**Scope (which sister scripts)** — confirmed by 2026-05-22 real-machine validation:

- **Chipset (this script)**: target environment. AMD Chipset Software 8.05.04.516 on Renoir / WS2019 reproduced 5 ineligible INFs (`AmdAppCompat.inf` ×2 paths, `AmdAS4.inf`, `AMDCIR.inf`, `usbfilter.inf`) due to phantom file references. r65 detect-and-skip + r66 orphan cleanup are both required and exercised.
- **Graphics**: validated on same host with Adrenalin 26.5.2 Vega-Polaris Legacy (623 MB EXE). P04 7-Zip auto-detect succeeded with **0 sub-MSI failures**; P05 found **0 ineligible INFs** (all 19 INFs pass the `Get-InfReferencedFile` check); P08 reported `Catalog generation: 19 ok / 0 failed`. Adrenalin's single-EXE WIX BURN bootstrapper does not exhibit the layered NSIS → InstallShield SFX → nested-MSI structure that produced the Chipset `SECREPAIR Error: 3` cascade. Port of the r65/r66 phantom-file machinery to the Graphics script remains deferred until such a defect is observed in a real Adrenalin package.
- **NPU**: uses `pnputil` directly against the AMD-published RAI ZIP; no `msiexec /a`, no `inf2cat`-per-directory loop, no cabinet-extraction path. Phantom file references are not a meaningful failure mode here.
- **BthPan**: validated on same host. P03 located the inbox `bthpan.inf_amd64_df4d6a507db770e7` in the host's DriverStore (single Microsoft inbox INF), P04 copied only `bthpan.inf` + `bthpan.sys` (no `.cat` carried along, so no orphan-`.cat` risk). P08 used the documented `inf2cat` → `makecat` fallback path because of redistribution rule 22.9.8. The `Get-IneligibleInfLookup` machinery has no surface to operate on. Port is not applicable.

The Chipset r66 design accommodates this asymmetry cleanly: all new code paths are guarded by `Lookup.Count -gt 0` / `ineligibleDirSet.Count -gt 0` / `catsToSkip.Count -gt 0`, so workspaces without phantom file references produce byte-identical output to r64.

**Verification status (as of r66)**:

- **WS2019 + Renoir (Ryzen 5 PRO 4650U) with Chipset 8.05.04.516**: r65 verification completed 2026-05-22 — P08 reported `55 ok / 0 failed / 5 skipped` against 5 detected ineligible INFs, but P09 was found to be re-signing the 5 orphan `.cat` files left in skipped directories (V01 reported `Catalog files: 60`, not 55). r66 closes that gap: post-fix expectations are P08 `55 ok / 0 failed / 5 skipped` + P08 cleanup line `Cleaned 5 orphan .cat file(s) ...`, P09 `Signing: 55 ok / 0 failed` (no `+ skipped` because P08 already cleaned), V01 `Catalog files: 55 .cat file(s)`. Re-verification with r66 against the same workspace is pending.
- **WS2022 / WS2025**: not yet verified for r65/r66. Functional behavior should be unchanged on hosts where no INF has phantom file references (all new code paths are guarded by `Lookup.Count -gt 0`).
- **Graphics / NPU / BthPan**: as documented under "Scope" above — r65/r66 machinery is intentionally Chipset-only.

---

---

## D.27 NPU refuses Install on legacy Windows Server (`r17`, Q-X1)

### D.27.0 Why this exists

The AMD NPU driver pipeline (`Deploy-AMDNpuDriverOnWindowsServer.ps1`) targets the kernel-mode XDNA driver for Ryzen AI 300 / AI Max 300 / 7040 / 8040 series NPUs. Its primary validated target is **Windows Server 2025** (build 26100) and — secondarily — WS2022 (build 20348), where the WDAC Multiple Policy Format (MPF) is available via `CiTool.exe`.

Running NPU `-Action Install` on **Windows Server 2019** (build 17763) or **Windows Server 2016** (build 14393) **has never been exercised on a physical NPU host**. The three production-validated driver scripts (Chipset / Graphics / BthPan) each have at least one real-bench cycle on legacy Server SKUs; the NPU script has zero. After the r70 Path C deprecation (see §D.30), the legacy-Server install path on the production scripts has also been formally removed in favour of operator-driven Path B (testsigning, requires Secure Boot off in firmware) — but the NPU script has no physical evidence that even Path B works for the XDNA driver stack on these OS versions.

The 2026-05-23 catastrophic field failure (see SPEC.md original §D.26 narrative, retained in §D.30) reinforced that "untested boot-policy interaction code" is the highest-impact failure category for this repository — far more so than "untested driver-store interactions", because the former can leave the host unbootable.

Rather than ship NPU with an unvalidated install path on legacy Server and hope the operator never hits it, **`r17` makes NPU refuse `-Action Install` and `-Action All` on legacy Windows Server**. The refusal is enforced in P00 Initialize, immediately after OS detection, so no destructive work is queued.

### D.27.1 Scope

- **Refused actions on WS2019 / WS2016**: `Install`, `All`. The refusal throws with an operator-facing message that explains why and what alternatives remain.
- **Retained actions on WS2019 / WS2016**: `PrepareVerify` (default), `Prepare`, `Verify`, `Cleanup`, `ListPhases`. These are non-destructive and do not touch the driver store. Operators can still inspect workspace state, run dry-runs, and clean up.
- **Unchanged on WS2022 / WS2025**: all actions remain available. The MPF path used by the NPU script on these SKUs has the same maturity level as on the Chipset / Graphics scripts.

### D.27.2 Implementation

`Invoke-PrepPhase00_Initialize` in `Deploy-AMDNpuDriverOnWindowsServer.ps1` contains an early-return guard immediately after `$os = Show-OperatingSystemDetail` and `$Script:DetectedPlatform.*` assignments:

```powershell
Set-DebugStep 'legacy Windows Server refuse check (Q-X1)'
if ($Script:Action -in @('Install','All') -and (Test-IsLegacyWindowsServerOs)) {
    Write-Fail (' NPU -Action {0} is NOT SUPPORTED on Windows Server 2019 / 2016.' -f $Script:Action)
    # ... operator-facing message block enumerating supported hosts and retained actions ...
    throw ('NPU -Action {0} refused on legacy Windows Server. See message above.' -f $Script:Action)
}
```

The guard fires for both `Install` (the primary destructive action) and `All` (which expands to all phases including I-phases). After r70 the `Test-IsLegacyWindowsServerOs` predicate is no longer shared via SECTION 1g (which was removed); the NPU script keeps its own minimal copy of the predicate (SECTION 1h) for this single call site. The predicate logic is unchanged: WS2019 (build 17763) and WS2016 (build 14393) return `$true`, everything else returns `$false`.

### D.27.3 How to enable NPU on WS2019/WS2016

The path is intentionally guarded but not permanently closed. To enable NPU on legacy Server, the project needs:

1. A physical NPU-bearing host (Ryzen AI 300 / AI Max 300 / 7040 / 8040) running WS2019 or WS2016.
2. A real test cycle covering at least: P00 OS detection, P05 INF analysis on the NPU INF, I02 boot-signing authorisation (Path B testsigning, since after r70 there is no in-script SPF path), I03 pnputil drive-store add, I04 disposition classification.
3. Documentation of any divergence from Chipset / Graphics observed during the test cycle.

Once that physical validation has been completed and reviewed, the guard in `Invoke-PrepPhase00_Initialize` can be removed in a future release and the legacy-Server path documented as production-validated for NPU.

Operators who need NPU on WS2019/2016 today should open a GitHub issue and commit to running the physical validation; the repository maintainer can then coordinate a per-bench bring-up.


## D.28 CRITICAL severity acknowledgement (QI-6, `r69/r35/r17`)

### D.28.0 Why this exists

The 2026-05-23 catastrophic field failure (originally documented in this SPEC's §D.26, retained as part of the r70 deprecation rationale in §D.30) was produced by stacking three Install actions on the same WS2019 + Renoir bench without rebooting between them. The I00 PreInstallReview phase displayed the install plan to the operator on each run, but its **HIGH-risk** label proved insufficient: the operator (correctly) interpreted HIGH as "this is a routine install on AMD/Server hosts; HIGH is the normal class for such installs" and proceeded.

`r69/r35/r17` introduces a **CRITICAL severity** above HIGH that fires only when the *combination* of host state and install plan crosses one of three specific tripwires (per Q6-A, as narrowed in r70). Each CRITICAL item requires the operator to acknowledge via an interactive `y/N` prompt before I01 begins. Acknowledgement is per-item, not blanket. The acknowledgement text is item-specific, and tells the operator exactly what risk is being acknowledged.

### D.28.1 Conditions evaluated

| ID | Condition | Detection pattern |
| --- | --- | --- |
| **C1** | Display driver replacement on single-display host | `@(Get-PnpDevice -Class Display -Status OK).Count -le 1` AND any candidate INF matches `(?i)^(display\.inf\|u020.*\.inf)$` |
| **C2** | BitLocker ON + AMD PSP driver replacement | `Get-BitLockerVolume -MountPoint $env:SystemDrive` reports `ProtectionStatus='On'` AND any candidate INF matches `(?i)psp` |
| **C5** | Host not rebooted in 24+ hours | `((Get-Date) - (Get-CimInstance Win32_OperatingSystem).LastBootUpTime).TotalHours -gt 24` |

(C4 — "System Restore disabled" — was originally proposed in Q6-A but is handled by QI-9 as a non-blocking informational warning per Q9-A=b, and was deliberately not promoted to CRITICAL: System Restore is OFF by default on Windows Server SKUs, so promoting C4 to CRITICAL would force every operator to acknowledge it on every install, which would condition them to acknowledge CRITICAL items reflexively. The whole point of CRITICAL is that it fires *rarely*.)

(**C3** — "same-session WDAC SPF cert stacking" — existed in r69 / r35 / r17 as a fourth CRITICAL condition that inspected `%ProgramData%\Deploy-Drivers-For-WindowsServer\wdac\manifest.json` for cross-script cert deployment evidence. C3 was **removed in r70** along with the rest of the Path C surface because the manifest file no longer exists in a r70-compliant deployment. The `C6` condition — "WHQL co-sign shortfall on a Secure-Boot-ON host" — was added in r71 to fill the same operator-protection role for the post-Path-C failure mode. See §D.30 for the r70 deprecation rationale and §D.31 for the r71 design contract.)

### D.28.2 Data contract for `Get-CriticalRiskItem`

The helper is invoked from each driver script's I00 PreInstallReview phase. Signature:

```powershell
function Get-CriticalRiskItem {
    param(
        [Parameter(Mandatory)] $Ctx,
        [Parameter(Mandatory)] [AllowEmptyCollection()] [object[]]$Matched
    )
    # returns [pscustomobject[]] @{ Id; Title; Detail; AckQuestion }
}
```

The `$Matched` parameter is the I00-internal `$matched[]` array which has the shape:

```powershell
[pscustomobject]@{
    Device     = <PnP device object>
    MatchKey   = <HWID match key>
    Current    = <current driver info from Get-DeviceCurrentDriver>
    Category   = <driver-source classification record>
    Candidates = <INF object[], each with .InfName>
}
```

**Important — BthPan adapter**: BthPan's I00 phase does not build a `$matched[]` array because BthPan deals with a single inbox `bthpan.inf` (no per-device candidate enumeration). The BthPan integration site passes `@()` (an empty array) to `Get-CriticalRiskItem`. C1 and C2 iterate over `$Matched[].Candidates[].InfName` and therefore yield nothing on BthPan, which is correct — BthPan never replaces `display.inf` or a PSP driver. C5 does not depend on `$Matched` and remains fully evaluated on BthPan.

This `$matched[]` shape was confirmed as the correct data contract by the operator on 2026-05-23 (decision B2, after the original r68 handoff proposed a `$V06Plan.PerDeviceTargets[].Candidate.InfName` shape that did not match the actual I00 phase data flow).

### D.28.3 Acknowledgement UX and `-ForceUnsafe`

`Invoke-CriticalAcknowledgementChecklist` is called from I00 with the items returned by `Get-CriticalRiskItem`. Behaviour:

- **Empty items**: returns `$true` immediately. I00 continues, I01 begins normally.
- **One or more items, `-ForceUnsafe` absent**: prints a CRITICAL header, then iterates each item and prompts `Read-Host` for `y/N`. On `y` / `yes`, the item is logged as acknowledged via `Set-DebugStep` and the next item is presented. On any other response, the function returns `$false` and the I00 integration site throws `'CRITICAL risk item(s) not acknowledged. Aborting before I01.'`
- **`-ForceUnsafe` present**: prints a CRITICAL header AND a `-ForceUnsafe is set; CRITICAL acknowledgement checklist is BYPASSED` warning, logs the bypass via `Set-DebugStep` with the full item-ID list, and returns `$true`. The bypass-with-item-list trace event is the audit anchor for compliance review.

The interactive `Read-Host` is intentionally not redirectable to a file — automation use cases must use `-ForceUnsafe` (which logs the bypass) rather than piping `y` into stdin. This is a deliberate ergonomic choice: it makes the bypass explicit in the script invocation rather than buried in a shell pipeline.

### D.28.4 Historical note — the original 2026-05-23 cumulative-stacking failure mode

The 2026-05-23 catastrophic field failure was caused by running `Chipset Install → Graphics Install → MSBthPan Install` on the same WS2019 host without reboots, under Path C. Each script's I02 phase ran the WDAC SPF orchestrator's `AddCert` action, which appended a new authorised cert to the orchestrator manifest. After Path C was deprecated in r70, this specific accumulation pattern can no longer occur in this repository — the orchestrator and its `manifest.json` are gone, the I02 phase no longer modifies host-wide boot-policy state, and a `Path C cumulative stack` is structurally impossible to construct using r70 driver scripts.

The narrower brick mechanism that the 2026-05-23 single-script bench observation also surfaced — kernel CI rejecting non-WHQL drivers at boot time regardless of any WDAC policy — is documented in §D.30 along with the operator-driven Path B response.

C3 is retained in this section as a historical record so future maintainers can understand why the QI-6 framework counts to C5 rather than C4. Re-introducing a `manifest.json`-based check, or any other "same-session cumulative stacking" check, would require first re-introducing a host-wide boot-policy artifact that r70 explicitly removed. That tradeoff is documented in §D.30.


## D.30 Path C deprecation: WDAC SPF orchestrator was net-negative (2026-05-23)

### D.30.1 Summary

In r70 the entire **Path C** code path was removed from the four driver scripts, and the `Deploy-WdacSinglePolicyFormatOnLegacyWindowsServer.ps1` orchestrator was deleted from the repository. Path C had been introduced in r67 (orchestrator r03 → r04) to provide a self-signed kernel-driver authorisation path on Windows Server 2019 / 2016 — OS versions that lack the WDAC Multiple Policy Format (MPF) machinery used by Path A on WS2022+. The implementation deployed a single WDAC SPF policy at `%windir%\System32\CodeIntegrity\SiPolicy.p7b` and tracked authorised certificates in a sidecar `manifest.json`.

Field validation on 2026-05-23 demonstrated that **Path C was net-negative**: it added a credible brick risk (host completely unable to boot, including Safe Mode) without solving any problem that an operator-driven Path B (`bcdedit /set TESTSIGNING ON` with Secure Boot Disabled in firmware) could not solve more safely. This section documents the evidence chain, the Microsoft design constraints that became visible in the same investigation, and the resulting decision to deprecate Path C entirely.

### D.30.2 Evidence base (F1 – F12)

The findings below are recorded as `F<n>` labels matching the r70 handover document. F1 – F8 come from physical-bench reproduction on a WS2019 + Ryzen 5 PRO 4650U (Renoir, Lenovo ThinkPad X13 Gen 1 AMD) host on 2026-05-23. F9 – F12 come from cross-referencing Microsoft Learn official documentation in the same session.

#### Bench-reproduced findings

| ID | Finding | Evidence |
|----|---------|----------|
| **F1** | Chipset r69 `-Action Install` alone (no Graphics, no MSBthPan) + Secure Boot ON + Path C leaves the host **unable to complete the next boot**, including Safe Mode. | 2026-05-23 14:48 bench run; host hung on Lenovo logo screen, F8 Safe Mode also hung. |
| **F2** | Disabling Secure Boot in firmware **after** F1 does NOT restore boot. Same hang. | BIOS Setup → Security → Secure Boot = Disabled, Save & Exit; identical hang. |
| **F3** | Deleting `C:\Windows\System32\CodeIntegrity\SiPolicy.p7b` from WinRE restores boot immediately. | USB Recovery → WinRE command prompt → `del`; subsequent boot succeeded. |
| **F4** | AMD `.sys` files are a **mix** of WHQL co-signed and non-WHQL: `AmdMicroPEP.sys` carries a Microsoft Windows Hardware Compatibility co-signature, `amdi2c.sys` and `amdsfhkmdf.sys` do not. ⚠️ **r74 amendment (2026-05-24)**: this finding was specific to chipset 8.04.x. The 8.05.04.516 build dropped WHQL co-signature from `AmdMicroPEP.sys` and every other chipset `.sys`; WHQL status must be re-verified per package release. See SPEC §D.32.3. | `signtool verify /v /pa` chain output (and r74-corrected `signtool verify /all /v /pa`). |
| **F5** | WHQL co-signed AMD drivers **load** on WS2019 even with no WDAC policy and Secure Boot OFF. | `AmdMicroPEP.sys` (driverDate 2025/12/17) showed `Status=OK` in Device Manager after the F3 cleanup. |
| **F6** | Non-WHQL AMD drivers are **rejected by kernel CI** regardless of whether the WDAC SPF policy is deployed. | `amdi2c.sys` (driverDate 2025/09/09) showed `Status=Error`, `ProblemCode=39` (`CM_PROB_DRIVER_FAILED_LOAD`), `ProblemStatus=0xC0000423` both before and after F3. |
| **F7** | Kernel-CI rejection of non-WHQL drivers is **not solvable** by deploying a WDAC SPF policy. (Derived from F4–F6.) | Path C's design premise — "authorise our self-signing cert via WDAC, and any driver signed with it will load" — is incorrect for boot-time kernel CI evaluation when the driver lacks a Microsoft co-signature. |
| **F8** | The brick risk was **previously believed to require the 3-script sequence** Chipset → Graphics → MSBthPan with no reboot between. F1 shows that **Chipset alone, with manual orchestrator interaction, is sufficient to brick the host**. | The 2026-05-23 bench did not run Graphics or MSBthPan at all. |

#### Microsoft-documented findings (cross-referenced 2026-05-23)

| ID | Finding | Source |
|----|---------|--------|
| **F9** | `bcdedit /set TESTSIGNING ON` **fails at command execution** when Secure Boot is ON. The boot loader does not silently drop it — `bcdedit` itself refuses with `The value is protected by Secure Boot policy and cannot be modified or deleted.` Operators must disable Secure Boot in firmware first. | [Microsoft Learn — "The TESTSIGNING boot configuration option"](https://learn.microsoft.com/en-us/windows-hardware/drivers/install/the-testsigning-boot-configuration-option). |
| **F10** | `bcdedit /set NOINTEGRITYCHECKS ON` is **silently ignored** on WS2008+ x64 Windows. Microsoft intentionally removed the effect in Vista-era updates to maintain the "OS commands cannot bypass kernel CI" property. | Microsoft Learn "Test Signing" page omits the flag; legacy forum posts (techjourney.net, AnandTech) report "doesn't work in the final version of Vista". |
| **F11** | `bcdedit /set LOADOPTIONS DISABLE_INTEGRITY_CHECKS` has the same status as F10: stored in boot configuration as ASCII, never consulted by the boot loader on WS2008+ x64. | Same Microsoft Learn family of pages as F10. |
| **F12** | Modifying Secure Boot state in firmware may force a BitLocker recovery prompt on next boot. Operators must have their recovery key in hand before changing Secure Boot. | [Microsoft Learn — "The TESTSIGNING boot configuration option"](https://learn.microsoft.com/en-us/windows-hardware/drivers/install/the-testsigning-boot-configuration-option). |

### D.30.3 Falsified design assumptions

Path C's design (recorded in the now-deleted §D.25 and §D.26 of this SPEC) was built on a set of assumptions that the F1 – F12 evidence has falsified:

| Original assumption | Refuting finding |
|--------------------|------------------|
| "WS2019 needs a WDAC SPF policy in order to load self-signed kernel drivers." | F5: WHQL co-signed drivers load without any WDAC policy. |
| "A WDAC SPF policy plus Secure Boot ON is a safe operating mode." | F1: This combination bricks the host. |
| "Option 10 (Boot Audit on Failure) protects boot-critical drivers from rejection." | F1: The host did brick, so Option 10 did not provide effective protection in practice. |
| "`runtime CI activation success does not prove boot-time acceptance` — surfacing this as a warning is sufficient." | F1: A warning at runtime cannot prevent an unbootable next boot. |
| "`BootLoadableCheck` (QI-10) provides structural validity assurance before reboot." | The check produced false-positive warnings (`SignatureInvalid`) while failing to predict the actual boot brick. |
| "`AddCert` → WMI CIM bridge `Update()` provides immediate activation, no reboot required." | The CIM Update succeeded; boot-time policy evaluation, which runs in a different layer, still bricked the host. |
| "`bcdedit /set NOINTEGRITYCHECKS` or `DISABLE_INTEGRITY_CHECKS` can bypass kernel CI from OS-level commands." | F10, F11: both flags are silently ignored on WS2008+ x64. |
| "`bcdedit /set TESTSIGNING ON` can be used with Secure Boot ON for self-signed driver loading." | F9: the `bcdedit` command itself fails when Secure Boot is ON. |

### D.30.4 Available paths on WS2019 / WS2016 after r70

With Path C removed, the supported paths on legacy Windows Server are:

| Path | Firmware requirement | OS-side action | WHQL co-signed driver | Non-WHQL driver | Brick risk |
|------|----------------------|----------------|----------------------|-----------------|------------|
| **A: Trust-store only** (cert import; no WDAC, no testsigning) | Secure Boot **may stay ON** | Import cert into Trusted Root + Trusted Publisher | ✅ loads | ❌ does NOT load (F6) | None |
| **B: `-UseTestSigning`** | Secure Boot **must be Disabled in firmware first** (F9) | `bcdedit /set TESTSIGNING ON` plus reboot | ✅ loads | ✅ loads | None |
| ~~C: WDAC SPF orchestrator~~ | (removed in r70) | (removed in r70) | ✅ would have loaded | ❌ never loaded (F6) | **High** (F1) |

Path A is sufficient when **all** drivers being installed are WHQL co-signed (e.g. AMD's `AmdMicroPEP.sys`, `amdgpio2.sys`, `amdpsp10.sys` in recent chipset releases). Path B is required when the install set includes **any** non-WHQL driver (e.g. `amdi2c.sys`, `amdsfhkmdf.sys` in current AMD chipset packages) **and** the operator wants those drivers to load.

### D.30.5 Operator workflow after r70

The r70 driver scripts on WS2019 / WS2016 no longer perform any orchestrator delegation. The intended operator workflow is:

1. **Determine the WHQL co-signing status of each driver in the install set.** Starting with r71, P05 (`AnalyzeInfs`) automatically inspects each candidate `.sys` file's signer chain and attaches the result to `$Ctx.WhqlCoSignAnalysis`; a summary is printed to the operator console. For releases earlier than r71, this can be done manually by running `signtool verify /v /pa /a <file>.sys` on each `.sys` and looking for the chain element `Microsoft Windows Hardware Compatibility ...`. See §D.31 for the r71 design contract.
2. **If all drivers are WHQL co-signed**: simply import the self-signing certificate into Trusted Root + Trusted Publisher (the script's I01 phase). Secure Boot may stay ON. The host should boot normally.
3. **If any driver is non-WHQL co-signed**:
   - To install everything: reboot, enter firmware setup, set Secure Boot = Disabled, save & exit. After the next Windows boot, re-run the driver script with `-UseTestSigning`. BitLocker recovery key must be available before changing Secure Boot (F12).
   - To skip non-WHQL drivers and keep Secure Boot ON: pass `-SkipNonCosignedDrivers` (added in r71). The flag trims `$Ctx.InfInventory` at P06 entry to only the WHQL-co-signed subset; downstream phases (P06 patch, P07 cert, P08 catalog, V03-V06 verify, I03 install) all read the trimmed inventory automatically. See §D.31.5.

The I02 phase falls through, in the worst case (non-WHQL driver + Secure Boot ON + no `-UseTestSigning`), to a Path B attempt and would historically fail with the Microsoft error documented in F9. Starting with r71, `Invoke-PathBPrerequisiteCheck` runs immediately after the Path B "already on?" cache check and ABORTS the phase with explicit firmware-change instructions before any driver-store modification is attempted. See §D.31.3.

### D.30.6 Migration guidance for existing deployments

Operators who deployed Path C with an earlier release (r67 – r69) and want to upgrade to r70 should:

1. Before upgrading, run the (still-present) orchestrator with `-Action GetStatus` to record current state, then `-Action Uninstall` to remove the deployed `SiPolicy.p7b` and `manifest.json`.
2. After upgrade, the four driver scripts will no longer reference the orchestrator. The `-ForceOverrideForeign`, `-AuditMode`, and `-StrictBootValidation` switches have been removed from the driver scripts' `param()` blocks; passing them will produce a parameter-binding error, which is the intended early-failure signal.
3. If the operator has lost a host to the post-r04 catastrophic field failure (or to the 2026-05-23 incident), the recovery procedure is the same: WinRE → delete `C:\Windows\System32\CodeIntegrity\SiPolicy.p7b` → reboot → run cleanup commands documented in README's "Recovery from unbootable state" section. The orchestrator itself is no longer needed for recovery; `del` from WinRE is sufficient.

### D.30.7 What was removed (file-level inventory)

The following deletions are part of r70 (see CHANGELOG.md entry for the precise byte-level diff):

- `Deploy-WdacSinglePolicyFormatOnLegacyWindowsServer.ps1` — entire file (orchestrator, ~4,096 lines).
- All four driver scripts: SECTION 1g (WDAC SPF orchestrator delegation helpers — `Get-CanonicalScriptHash`, `Test-IsLegacyWindowsServerOs`, `Resolve-WdacOrchestratorScript`, `Invoke-WdacOrchestrator`, `Invoke-LegacyWdacAuthorization`). NPU retains a minimal `Test-IsLegacyWindowsServerOs` predicate (SECTION 1h) for the Q-X1 refuse check; see §D.27.
- Chipset / Graphics / BthPan: SECTION (r69, QI-10) — `Invoke-BootLoadableCheck` and its translation table.
- Chipset / Graphics / BthPan: I02 Path C branch (~40 lines per script) and the post-I02 BootLoadableCheck dispatcher hook (~24 lines per script).
- All four driver scripts: `Test-LegacyWdacSpfAuthorizedForCert` function (~48 lines per script).
- Chipset / Graphics / BthPan: the C3 condition in `Get-CriticalRiskItem` (manifest.json-based "same-session WDAC SPF deploy stacking" check, ~34 lines per script). The Critical-Risk acknowledgement framework (QI-6) is preserved — only the C3 case is removed; C1, C2, C5 are unchanged.
- All four driver scripts: `param()` block switches `-ForceOverrideForeign`, `-AuditMode`, `-StrictBootValidation`, plus the associated `$Script:` scope assignments.
- SPEC.md: §D.25 (Path C design rationale), §D.26 (post-r04 quality programme), §D.29 (BootLoadableCheck errorCategory taxonomy).
- TESTING.md: §11 (WS2019 legacy WDAC SPF integration validation scenarios); the QI-10 subsection of §13 (QI-6, QI-9, Q-X1 entries retained).

The README's BRICK-LEVEL RISK disclaimer is **retained but rewritten** in r70 to integrate the 2026-05-23 single-script-brick observation alongside the earlier 3-script-cumulative observation, without referring to a Path C remediation that no longer exists.

### D.30.8 r71 (shipped)

r70 deliberately stopped at removal. r71 adds the operator-assistance features that Path C was supposed to provide but did not:

- WHQL co-sign pre-detection in P05 (`Test-WhqlCoSignature`, `$Ctx.WhqlCoSignAnalysis`).
- Path B prerequisite checking in I02 (`Invoke-PathBPrerequisiteCheck`), with explicit firmware-change instructions, BitLocker advisory text, and the verbatim Microsoft error message from F9.
- A `-SkipNonCosignedDrivers` switch for operators who want to keep Secure Boot ON and accept that non-WHQL drivers will not load.
- A `C6` CRITICAL acknowledgement condition (WHQL co-sign shortfall on a Secure-Boot-ON host).
- A new §D.31 in this SPEC documenting the r71 design contract.

r71 was intentionally split out of r70 because (a) it has a wider surface area than the deletion itself, (b) byte-identical helper changes across Chipset / Graphics / BthPan should be reviewable in isolation from the deletion diff, and (c) r70 needed an operator-visible release point so existing deployments could run `-Action Uninstall` on the orchestrator before the file disappeared.

See §D.31 for the full r71 design contract.



## D.31 WHQL co-sign pre-detection + Path B prerequisite check (`r71`)

### D.31.1 Background

§D.30 removed the Path C WDAC SPF orchestrator after field evidence (F1–F12) demonstrated that it added a credible host-brick risk without providing a workable alternative for non-WHQL drivers on UEFI Secure Boot-enabled hosts. The §D.30 deprecation deliberately stopped at removal so the diff could be reviewed in isolation. r71 lands the operator-assistance features Path C was supposed to provide but never did.

After r70, an operator running `Install` on a WS2019 / WS2016 host falls through I02 to Path B (`bcdedit /set TESTSIGNING ON`). When Secure Boot is enabled in firmware, `bcdedit` itself refuses the command (F9). The r70 driver scripts surface this only as the underlying `bcdedit` error, which is technically accurate but operationally insufficient: the operator does not learn ahead of time that the firmware-level setting blocks Path B, does not see the BitLocker advisory, and does not learn that a subset of the install plan (the WHQL-co-signed drivers) could load fine on Path A without any firmware change. r71 adds three mechanisms that together close this gap.

### D.31.2 Mechanism 1 — WHQL co-sign analysis in P05 (`Test-WhqlCoSignature`, `New-WhqlCoSignAnalysis`)

P05 (`AnalyzeInfs`) now performs a per-INF Authenticode chain inspection on each patch-eligible INF's accompanying `.sys` files, classifying them as WHQL co-signed or not. The result is attached to `$Ctx.WhqlCoSignAnalysis` as an array of records:

```powershell
[pscustomobject]@{
    InfName          = '<name>.inf'
    InfPath          = '<absolute path>'
    DriverFiles      = @('<sys>', '<sys>', ...)
    CoSignedFiles    = @(...)        # subset of DriverFiles
    NonCoSignedFiles = @(...)        # the rest
    IsFullyCoSigned  = <bool>        # true iff every .sys carries a WHQL co-signature
    HasMixedSigning  = <bool>        # true iff CoSignedFiles and NonCoSignedFiles are both non-empty
}
```

WHQL co-signing is detected by matching the case-insensitive regex `(?i)Microsoft Windows Hardware Compatibility` against signer subject CNs. This covers the historical CN variants `Microsoft Windows Hardware Compatibility`, `Microsoft Windows Hardware Compatibility Publisher`, and the older `Microsoft Windows Hardware Compatibility Authority`.

The implementation uses two probes:

1. **Primary signer via `Get-AuthenticodeSignature`** — PS 5.1 returns only the primary signer; this catches the case where WHQL is the primary signer (rare but possible for Microsoft-published drivers).
2. **Nested signers via `signtool verify /all /pa /v`** — when the Windows Kits SDK is installed and `Find-KitTool 'signtool.exe'` succeeds, signtool's stdout enumerates the full primary + nested signature chain. The parser extracts subject CNs from `Issued to:` lines and matches each against the WHQL regex. (Note: pre-r74 code used `Find-Signtool` here, which never existed as a function — see §D.32.2 for the post-incident analysis.)

When signtool is absent, the analysis falls back to a conservative `self-only` verdict on any non-WHQL primary signer. This means C6 may **over-report** on signtool-absent hosts (a co-signed driver might be reported as `self-only` because we cannot enumerate the chain) but will never **under-report**. Over-reporting is preferred because the cost is one extra acknowledgement prompt; under-reporting would allow a driver-store regression to ship.

The analysis runs only on the **patch-eligible subset** (`NeedsPatch=true` or, for BthPan, the single inbox `bthpan.inf`). INFs that are skipped earlier in the pipeline (wrong variant, missing referenced files via D.24, already universally co-signed) are not analysed because they cannot reach I03 in any case.

`Show-WhqlCoSignAnalysisReport` prints a three-line summary to the operator console:

```
--- WHQL co-signature analysis ---
  Fully WHQL co-signed INFs   : <N>
  Mixed-signing INFs (partial): <M>
  No WHQL co-signature        : <P>
```

When mixed-signing or non-co-signed INFs are present, the report enumerates the first 10 of each so the operator sees concrete filenames before reaching I00.

**Producer-site status table** (updated 2026-05-23 Chipset r73 / Graphics r39 / NPU r18 / BthPan r21 release):

| Script   | P05 producer site status | Source of `$Ctx.WhqlCoSignAnalysis` |
|----------|---------------------------|--------------------------------------|
| Chipset  | producer (r71 added, r73 hardened with `$Ctx.WhqlCoSignAnalysis = $null` pre-declaration) | Built from `$detailReport | Where-Object NeedsPatch` (multi-INF AMD chipset package) |
| Graphics | producer (r39 ported from Chipset r71 — *not present in r37 / r38*) | Built from `$detailReport | Where-Object NeedsPatch` (multi-INF Adrenalin package) |
| NPU      | implicit (no producer site needed) | NPU package is a single inbox-style INF; the C6 / `-SkipNonCosignedDrivers` mechanisms do not exercise this path |
| BthPan   | producer (r71 added, r21 hardened with `$Ctx.WhqlCoSignAnalysis = $null` pre-declaration) | Single-INF synthetic record `@([pscustomobject]@{ InfName='bthpan.inf'; InfPath=$infPath })` — the analysis always reports IsFullyCoSigned=true for the Microsoft inbox bthpan.inf |

The Graphics r39 backport was identified during the r73 fix work for the Chipset / BthPan `$Ctx` pre-declaration defect: psa.py v3.8.0's new PSA2009 rule flagged the Chipset and BthPan defects directly, and the broader audit triggered by the rule's addition revealed that Graphics r37 / r38 shipped the four consumer sites (I00 §D.31.4 C6, P06 §D.31.5 `-SkipNonCosignedDrivers` trim, I02 §D.31.11 r72 short-circuit, recap line in I00) but never the producer site. From r39 onward, Graphics conforms to the same producer / consumer contract as Chipset and BthPan.

### D.31.3 Mechanism 2 — Path B prerequisite check in I02 (`Invoke-PathBPrerequisiteCheck`, `Test-SecureBootEnabledFromFirmware`)

I02's Path B branch (`-UseTestSigning`) now calls `Invoke-PathBPrerequisiteCheck` immediately after the "BCD testsigning already ON?" cached-state check and BEFORE any `bcdedit` invocation or driver-store modification. The check returns one of three outcomes:

- **`ok` / reason `secure-boot-off`** — Firmware Secure Boot is OFF (`Confirm-SecureBootUEFI` returns `$false`). Path B will succeed. I02 continues.
- **`ok` / reason `secure-boot-unknown`** — `Confirm-SecureBootUEFI` threw (legacy BIOS host, constrained VM, insufficient privilege). I02 prints a warning that the firmware state could not be determined and continues. If `bcdedit` then refuses with the documented Secure Boot error, the operator already has the context to interpret it.
- **`abort` / reason `secure-boot-on`** — Firmware Secure Boot is ON. The check returns a multi-line guidance block that I02 prints in red and then throws with `I02: Path B prerequisite not met (reason=secure-boot-on). Aborting before bcdedit is invoked.` The thrown message is propagated by the phase dispatcher to the standard failure exit path; the host state is untouched.

The guidance block enumerates:

- The verbatim Microsoft error message from the Microsoft Learn article "The TESTSIGNING boot configuration option": *"The value is protected by Secure Boot policy and cannot be modified or deleted."*
- A five-step operator workflow (save BitLocker recovery key → reboot to firmware → set Secure Boot Disabled → reboot to Windows → re-run with `-UseTestSigning`).
- Two alternatives: (a) drop `-UseTestSigning` and run on Path A if all drivers are WHQL co-signed; (b) keep Secure Boot ON and add `-SkipNonCosignedDrivers` to install only the WHQL-co-signed subset.
- Cross-references to SPEC §D.30.4 (Microsoft Learn F9) and §D.31 (this section).

The `-Force` switch bypasses the prerequisite check, matching the existing convention for other I02 abort conditions (HVCI running, Secure Boot detected from OS view). `-Force` is intentionally less prominent in the guidance text because operators reading the abort message should be steered toward firmware setup rather than toward forcing past the check.

`Test-SecureBootEnabledFromFirmware` is a thin wrapper around `Confirm-SecureBootUEFI` that returns `[bool]$true` / `[bool]$false` / `$null`. The wrapper exists so the firmware-layer check and the OS-layer view (`$bootEnvBefore.SecureBootEnabled`) can be inspected independently — both should agree but their failure modes differ (the OS view caches an earlier read, the firmware view requires the call to succeed).

### D.31.4 Mechanism 3 — C6 CRITICAL acknowledgement in I00 (`Get-CriticalRiskItem` extension)

`Get-CriticalRiskItem` adds a sixth condition C6 — WHQL co-sign shortfall on a Secure-Boot-ON host. C6 fires when ALL of the following hold:

1. `$Ctx.WhqlCoSignAnalysis` is populated and contains at least one entry with `IsFullyCoSigned=false`.
2. `Test-SecureBootEnabledFromFirmware` returns `$true` (Secure Boot is ON in firmware).
3. `$Script:SkipNonCosignedDrivers` is `$false` (the operator did not opt into the trim-mode safe path).
4. `$Ctx.UseTestSigning` is `$false` (the operator did not opt into Path B).

When all four conditions hold, the install plan WILL produce devices that fail to load at boot regardless of any trust-store or WDAC state. The C6 acknowledgement is the gate the operator must clear to proceed with a knowingly-suboptimal install plan. The acknowledgement text lists up to 5 non-co-signed INF names and enumerates the three escape routes:

- (a) `-SkipNonCosignedDrivers` → install only the WHQL subset, keep Secure Boot ON;
- (b) Path B → disable Secure Boot in firmware, then `-UseTestSigning`;
- (c) Accept that non-WHQL drivers will fail with `ProblemCode=39 (CM_PROB_DRIVER_FAILED_LOAD)` and proceed anyway.

C6 is bypassable by `-ForceUnsafe` like every other CRITICAL item. The bypass is logged via `Set-DebugStep` with the item ID so an audit can reconstruct what was acknowledged.

C6 is added only to Chipset / Graphics / BthPan. NPU's Get-CriticalRiskItem is excluded by PSA8001 because NPU refuses Install on legacy Windows Server entirely (Q-X1, see §D.27), so C6 has no call site there. On WS2022+ / WS2025, where Secure Boot ON is the supported deployment mode and the WDAC MPF path takes care of self-signed cert authorisation, C6 still fires correctly when non-WHQL drivers are present — that case is rare on AMD chipset packages but documented for completeness.

### D.31.5 Mechanism 4 — `-SkipNonCosignedDrivers` switch (`Get-EligibleInfRecordList`)

A new top-level switch `-SkipNonCosignedDrivers` is added to Chipset / Graphics / BthPan. When set, P06 entry calls `Get-EligibleInfRecordList` against `$Ctx.InfInventory` and replaces it with the WHQL-co-signed subset. Because every downstream phase (P06 patch, P07 cert, P08 catalog, V03–V06 verify, I03 install) reads `$Ctx.InfInventory`, the trim at P06 propagates automatically. No per-phase integration is needed.

The trim message is:

```
--- r71: -SkipNonCosignedDrivers filter applied ---
  Inventory trimmed: <N> INF(s) eligible / <M> non-WHQL-co-signed INF(s) skipped (kept Secure Boot ON safe).
  Skipped INFs will not be patched, cataloged, signed, or installed by this run.
```

When the flag is set but the inventory is already fully WHQL co-signed, the message is `r71: -SkipNonCosignedDrivers set but inventory is already fully WHQL co-signed (no trim).` and the run continues unchanged.

BthPan has a single inbox INF (`bthpan.inf`) which is always Microsoft-signed and WHQL co-signed; the BthPan implementation acknowledges the flag in the run transcript but never actually trims. The flag is preserved on BthPan so cross-script automation can pass it uniformly without per-script branching.

The flag is intentionally **opt-in**. Defaulting to skip-non-cosigned would break the historical behaviour of installing all AMD chipset and graphics drivers and would silently change which devices come up on existing deployments. Operators who want the Secure-Boot-ON-only safe path must explicitly request it.

### D.31.6 Decision matrix for the operator

The three new mechanisms together encode the following decision matrix that the operator can reason about before running `Install`:

| Install plan composition | Firmware Secure Boot | Recommended invocation | What happens |
|---|---|---|---|
| All WHQL co-signed | ON | (default) | Path A; all drivers load. No prompts. |
| All WHQL co-signed | OFF | (default) | Path A; all drivers load. P05 still reports the analysis. |
| Mixed WHQL / non-WHQL | ON | `-SkipNonCosignedDrivers` | Path A on WHQL subset; non-WHQL skipped cleanly. No firmware change. C6 does not fire. |
| Mixed WHQL / non-WHQL | ON | `-UseTestSigning` | I02 Path B prerequisite check ABORTS with §D.31.3 guidance. Operator must disable Secure Boot first. |
| Mixed WHQL / non-WHQL | ON | (default, no Skip / TestSigning) | C6 fires. Operator acknowledges with full knowledge of `ProblemCode=39` outcome, or declines and switches strategy. |
| Mixed WHQL / non-WHQL | OFF | `-UseTestSigning` | Path B succeeds; all drivers load via testsigning. Test Mode watermark visible. |
| All non-WHQL (unusual) | ON | `-UseTestSigning` (after firmware change) | Same as the mixed case with `-UseTestSigning`. |

The matrix is reproduced in README.md "Self-signed driver authorisation paths" so operators can consult it without opening the SPEC.

### D.31.7 Implementation notes — PS 5.1 footguns

A handful of details deserve explicit recording because they tripped the implementation:

- **`(if ... else ...) -ForegroundColor` does not parse on PS 5.1.** The condition has to be pre-computed into a `$color` variable and passed in. The natural-feeling `Write-Host '...' -ForegroundColor (if ($x) {'Red'} else {'Green'})` parses on PS 7.1+ but raises `A positional parameter cannot be found that accepts argument 'else'.` on PS 5.1. The r71 helpers use the pre-computed form throughout.
- **`-match` against `$null` returns `$true`** when the right-hand side is a bare variable that happens to be null. `psa.py` flags this as PSA2003. The r71 helpers use `[regex]::Match` explicitly to avoid the trap, both for clarity and to silence the analyzer.
- **PSA6003 false positive on `-Os`, `-Status`, `-Firmware`, `-Signature`.** PowerShell's plural-noun rule rejects function names ending in `-s`, but several Latin-origin / mass-noun words pass through that filter. The r71 helpers carry `# psa-disable-line PSA6003 -- ...` comments documenting the false positive on `Test-SecureBootEnabledFromFirmware` and `Test-WhqlCoSignature`.
- **`# (r71)` and `# r71:` in inline comments trigger PSAP0003.** The repository's convention is to write release context into descriptive prose rather than as parenthesised or colon-prefixed tags; the r71 implementation uses the form "Added in the r71 release" or "Added with the r71 release" inside running comments and reserves the explicit tag for SECTION headers (`# SECTION r71: ...`) which the analyzer accepts.

### D.31.8 What r71 does NOT change

For clarity, r71 deliberately leaves these mechanisms unchanged:

- **The WDAC MPF supplemental policy path on WS2022+ / WS2025.** Path A on modern Server SKUs continues to work exactly as before r71. The WHQL analysis is informational on those hosts; the WDAC supplemental policy authorises the self-signing certificate regardless of WHQL co-signature state.
- **The behaviour of `-Force`.** `-Force` still bypasses I02 pre-checks including the new Path B prerequisite check. The audit trail (`Set-DebugStep`) records each bypass.
- **The `Get-CriticalRiskItem` conditions C1, C2, C5.** Display driver replacement on single-display host, BitLocker + PSP, and 24+ hour uptime continue to be evaluated unchanged. C6 is purely additive.
- **The NPU script.** NPU still refuses Install on legacy Windows Server (Q-X1). C6 is not added to NPU because the refuse check happens earlier than I00 and Get-CriticalRiskItem is not in NPU's source surface.
- **The orchestrator file.** The orchestrator was deleted in r70 and r71 does not reintroduce it. The two mechanisms (Path B prerequisite check + `-SkipNonCosignedDrivers`) operate entirely inside the four driver scripts.

### D.31.9 Validation strategy

The r71 helpers are not yet field-validated on the WS2019 + Renoir bench (the only legacy-Server physical host) because that bench is queued for OS reinstall. Code-review validation has been performed against the SPEC. The intended validation cycle is:

1. **TC14.1**: Run `-Action PrepareVerify` on WS2019. Expected: P05 emits the WHQL analysis. No I02 / C6 / Skip triggers because PrepareVerify does not run I-phases.
2. **TC14.2**: Run `-Action Install` on WS2019 with no flags, Secure Boot ON, mixed install plan. Expected: I00 fires C6, operator acknowledges, I02 falls through to Path B (`WdacToolsAvailable=$false` on WS2019 forces this), Path B prerequisite check ABORTS.
3. **TC14.3**: Same as TC14.2 plus `-SkipNonCosignedDrivers`. Expected (r72-onward): P06 trims `$Ctx.InfInventory` to the WHQL-co-signed subset, C6 does NOT fire (Skip flag is set), and I02 short-circuits cleanly (see §D.31.11) — no WDAC supplemental policy is deployed, no `bcdedit` is invoked, no firmware change is required. The WHQL drivers load on a Secure-Boot-ON host via their embedded Microsoft signatures; I01's trust-store import is sufficient for pnputil to accept the script-re-signed catalogs at I03. (Prior to r72, this scenario hit the Path B prerequisite ABORT and the operator was forced to either disable Secure Boot in firmware or use `-OnlyPhases` to skip I02 manually. r72 makes the natural invocation `-Action Install -SkipNonCosignedDrivers` work end-to-end on legacy Server with Secure Boot ON.)
4. **TC14.4**: Run on WS2022 with mixed install plan, Secure Boot ON. Expected: WDAC MPF works, all drivers load except non-WHQL on a SB-on Server host (kernel CI rejects non-WHQL regardless of WDAC). C6 fires; operator either accepts or adds `-SkipNonCosignedDrivers`.

These scenarios are recorded in TESTING.md §14 as `TC14.1` – `TC14.4` for replay when the WS2019 + Renoir bench is back online. The r72 short-circuit adds three further scenarios (TC14.9 – TC14.11) covering positive fire, cross-OS uniformity, and resume-after-reboot semantics; see §D.31.11.4.

### D.31.10 Release version contract

r71 bumped the driver scripts as follows:

- `Chipset r71`
- `Graphics r37`
- `BthPan r19`
- `NPU r18` (carried forward unchanged; no r71 changes apply to NPU)

r72 bumps them to:

- `Chipset r72`
- `Graphics r38`
- `BthPan r20`
- `NPU r18` (carried forward unchanged; no r72 changes apply to NPU — the r72 short-circuit predicates on `-SkipNonCosignedDrivers` which NPU does not carry)

r73 / r39 / r21 (`psa-py-v380-pscustomobject-rule`, 2026-05-23) bumps them to:

- `Chipset r73` (adds `WhqlCoSignAnalysis = $null` to `$Ctx` initialiser per §D.31.16)
- `Graphics r39` (adds the missing P05 producer site per §D.31.16)
- `BthPan r21` (same initialiser fix as Chipset)
- `NPU r18` (carried forward unchanged; NPU `$Ctx` shape does not exercise `WhqlCoSignAnalysis`)

r74 / r40 / r22 (`legacy-ws2019-runtime-correctness-fix`, 2026-05-24) bumps them to:

- `Chipset r74` (fixes the four r74 defects per §D.32: `Find-Signtool` → `Find-KitTool 'signtool.exe'`, `signtool verify /all /pa /v`, V06 `$ourInfSet` threading, I02→I03 halt)
- `Graphics r40` (same four fixes; same byte-identical helper change as Chipset for Test-WhqlCoSignature; same V06 fix; same I02→I03 halt)
- `BthPan r22` (defects 1, 2, 4 only — Defect 3 not applicable because BthPan V06 does not call Get-DriverSourceCategory)
- `NPU r18` (carried forward unchanged; NPU does not exercise Test-WhqlCoSignature, Get-DriverSourceCategory, or the RebootRequiredBeforeI03 flag)

The `WDAC SPF orchestrator` row that used to appear in this list is permanently absent; the orchestrator was deleted in r70.

Sister-script PSA8001 byte-identity is preserved across Chipset / Graphics / BthPan for the r71 helpers `Test-WhqlCoSignature`, `Get-InfDriverFileList`, `New-WhqlCoSignAnalysis`, `Show-WhqlCoSignAnalysisReport`, `Test-SecureBootEnabledFromFirmware`, `Invoke-PathBPrerequisiteCheck`, `Get-EligibleInfRecordList`. The I02 Path B prerequisite call site is byte-identical between Chipset and Graphics; BthPan's I02 has a slightly different surrounding structure (Set-DebugStep ordering, `Test-MsBthPanWdacPolicyDeployed` instead of `Test-AmdWdacPolicyDeployed`) and is documented in the BthPan-specific PSA8001 ignore list rather than as an in-script divergence.

The r74 `Test-WhqlCoSignature` `Find-KitTool` / `/all`-flag fix is byte-identical across Chipset r74 / Graphics r40 / BthPan r22. The r74 V06 `$ourInfSet` threading is byte-identical between Chipset r74 and Graphics r40 (BthPan does not have the construct). The r74 I02 / I03 / I04 halt block is byte-identical between Chipset r74 and Graphics r40; BthPan r22's variant inherits the pre-existing single-INF / `Get-MsBthPanDevice`-based I04 structure but uses the same halt logic body.

The r72 I02 short-circuit block follows the same convention: byte-identical between Chipset and Graphics; BthPan's variant inherits the pre-existing Set-DebugStep / cache-check ordering difference but uses the same short-circuit logic body.

### D.31.11 r72 follow-on: I02 short-circuit for all-WHQL trimmed plans

#### D.31.11.1 Motivation

The r71 implementation made `-SkipNonCosignedDrivers + Secure Boot ON` a credible workflow on WS2019 / WS2016 — P05 builds the WHQL analysis, P06 trims the install plan to the WHQL subset, and I01 imports the script's self-signing cert into the trust store. But r71 stopped short of completing the workflow at I02: because `WdacToolsAvailable=$false` on WS2019, I02 falls into Path B (testsigning) regardless of `-UseTestSigning`, and the r71 Path B prerequisite check correctly ABORTs on Secure Boot ON. The operator's natural invocation produced a phase-mid failure rather than a clean install.

r72 closes this gap. When the operator has explicitly trimmed the install plan to all-WHQL via `-SkipNonCosignedDrivers`, I02 short-circuits: it skips both Path A (WDAC supplemental policy deployment) and Path B (testsigning) and lets the WHQL drivers load via their embedded Microsoft co-signatures. No kernel-mode signer authorization is needed, no firmware change is needed, no `-UseTestSigning` is needed.

#### D.31.11.2 Firing conditions (four AND clauses)

The short-circuit runs immediately after `Test-InstallPhaseAlreadyDone -PhaseId 'I02'` returns false (i.e., the host does NOT already have a WDAC policy or testsigning state that I02 would normally produce). All four of the following must hold to short-circuit:

1. `-not $Ctx.UseTestSigning` — The operator did not explicitly opt into Path B. If `-UseTestSigning` is set, we honour the explicit choice and proceed to the standard Path B prerequisite check (which will ABORT on Secure Boot ON, which is the correct outcome — `-UseTestSigning` means "I want testsigning, and that requires Secure Boot OFF").
2. `$Script:SkipNonCosignedDrivers` — The operator explicitly opted into the WHQL-only trim path. Without this flag, the short-circuit does NOT fire even if the install plan happens to be fully WHQL co-signed. Rationale: silently skipping I02 on an unflag run would surprise admins who expect the WDAC supplemental policy file to exist for inspection by other tools; opt-in keeps the behaviour explicit.
3. `$Ctx.WhqlCoSignAnalysis` is populated and non-empty — P05 ran and produced a non-empty WHQL analysis. If P05 was bypassed (e.g. workspace stale, manual phase invocation), we fall through to the standard I02 logic to be conservative.
4. `$nonCoSignedAfterTrim.Count -eq 0` — Every analysed INF is fully WHQL co-signed. After P06's `-SkipNonCosignedDrivers` trim, this condition should hold by construction (the trim removed any `IsFullyCoSigned=$false` records). We re-verify at I02 entry as defense-in-depth: if a non-WHQL INF somehow survived the trim, the short-circuit refuses to fire and we fall through.

On any single condition failing, I02 proceeds with the standard Path A / Path B evaluation. The short-circuit is purely additive.

#### D.31.11.3 Observable effects on the host

When the short-circuit fires:

- **No WDAC supplemental policy is deployed.** `%SystemRoot%\System32\CodeIntegrity\CiPolicies\Active` is left unchanged.
- **No bcdedit testsigning flag is set.** `bcdedit /enum {current}` continues to show testsigning unchanged from its prior value.
- **The script's self-signing certificate is still in Trusted Root + Trusted Publisher** (from I01). This is the only OS-side state that I-phases write in the short-circuit case.
- **I02's phase marker is written** with `Metadata=@{ ShortCircuit=$true; Reason='all-whql-skip'; AnalysedInfCount=<N> }` so subsequent diagnostic queries can recognise the short-circuit path.
- **`Set-DebugStep` records** the conditions evaluated, so the run transcript carries the audit anchor.
- **I02's footer message reads** `Write-PhaseFooter 'I02' 'short-circuit'` to distinguish from `'done'` (normal Path A/B completion) and `'cached'` (Test-InstallPhaseAlreadyDone hit).

I03 then runs normally; pnputil accepts the script-re-signed catalogs because the script's cert is in Trusted Publisher (I01).

#### D.31.11.4 Resume-after-reboot semantics

The short-circuit is self-healing across re-runs by design:

- `Test-InstallPhaseAlreadyDone -PhaseId 'I02'` inspects HOST STATE (`Test-AmdWdacPolicyDeployed` for Path A, `bcdedit /enum {current}` value for Path B), not the phase marker. After a short-circuit, neither host-state predicate holds, so the cache check returns `$false` on every subsequent run.
- This means each re-run re-evaluates the short-circuit conditions from scratch. If the operator runs again with the same flags, the short-circuit fires again (idempotent no-op). If they drop `-SkipNonCosignedDrivers`, condition 2 fails and I02 proceeds with the standard Path A/B logic, producing a WDAC policy (or testsigning) as required. If they add a non-WHQL driver to the install plan and re-run, P06's trim still removes it (because `-SkipNonCosignedDrivers` is still set) and the short-circuit fires again unchanged.
- The phase marker's `ShortCircuit=$true` metadata is informational only — it does NOT participate in resume decisions. This is a deliberate design choice: if the metadata gated re-run behaviour, an operator who first ran with `-SkipNonCosignedDrivers` and then changed their mind could be silently trapped in the short-circuit on subsequent runs.

Test case TC14.11 in TESTING.md §14 verifies this: short-circuit → re-run without `-SkipNonCosignedDrivers` → I02 proceeds with the full Path A/B logic.

#### D.31.11.5 Interaction with the other r71 mechanisms

- **WHQL analysis (P05)**: Unchanged. P05 always builds the analysis; the short-circuit reads `$Ctx.WhqlCoSignAnalysis` and refuses to fire if it is empty.
- **Path B prerequisite check (I02)**: Unaffected by the short-circuit because the short-circuit runs *before* the Path B branch is entered. When the short-circuit does NOT fire (e.g. `-UseTestSigning` is set, or some non-WHQL INF survived the trim), the standard Path B prerequisite logic still runs.
- **C6 (I00)**: Independent of the short-circuit; C6 evaluation happens in I00 before I01, and the short-circuit happens in I02. C6 does not fire when `-SkipNonCosignedDrivers` is set (one of its AND conditions), so the typical r72 short-circuit run also has no C6 prompt.
- **`-SkipNonCosignedDrivers` trim at P06**: The short-circuit DEPENDS on this trim having happened. Per the firing-conditions section, the short-circuit re-verifies the trim's outcome at I02 entry (`$nonCoSignedAfterTrim.Count -eq 0`) to handle the edge case where P06 was bypassed manually.
- **`-Force`**: `-Force` does NOT bypass the short-circuit (because the short-circuit is a positive outcome, not an ABORT). `-Force` continues to bypass the legacy I02 OS-layer Secure Boot guard and HVCI guard in the Path A/B branches, but those branches are skipped entirely when the short-circuit fires.
- **NPU**: Unchanged. NPU does not carry `-SkipNonCosignedDrivers`, so condition 2 fails and the short-circuit cannot fire. NPU is also out of the WHQL analysis surface (its P05 is structurally different and BthPan-only `Test-MsBthPanWdacPolicyDeployed`-style helpers do not apply).

#### D.31.11.6 OS-version uniformity

The short-circuit fires on any supported host (WS2019, WS2016, WS2022, WS2025) when the four conditions hold. This is intentional: an all-WHQL install plan with explicit `-SkipNonCosignedDrivers` opt-in produces the same observable host state on all OS versions (no policy, no testsigning, cert in trust store). Special-casing the short-circuit to WS2019/2016 only would mean WS2022+ runs continue to deploy an unnecessary WDAC supplemental policy file on an all-WHQL install plan, which is overhead with no benefit.

On WS2022+ the short-circuit's user-visible effect is "WDAC supplemental policy file is not created." Operators who specifically want the policy file (e.g. as documentation of which cert is authorized) should run without `-SkipNonCosignedDrivers`; the short-circuit will not fire and Path A will deploy the policy normally.

#### D.31.11.7 What r72 does NOT change

For clarity, r72 leaves the following unchanged from r71:

- **The Path B prerequisite check itself.** When the short-circuit does not fire (e.g. `-UseTestSigning` is set), Path B still runs the firmware Secure Boot check exactly as in r71.
- **The C6 CRITICAL acknowledgement.** C6 evaluates in I00 and does not consult the new short-circuit state.
- **The `-SkipNonCosignedDrivers` trim at P06.** The trim runs unchanged; the short-circuit is purely a post-trim consumer.
- **The WHQL analysis itself.** `Test-WhqlCoSignature`, `New-WhqlCoSignAnalysis`, and `Show-WhqlCoSignAnalysisReport` are byte-identical to r71.
- **Documentation forward references.** All "see SPEC §D.31" references in the driver scripts continue to point at this section; §D.31.11 is an extension, not a replacement.

#### D.31.11.8 Implementation notes

- The short-circuit block is byte-identical between Chipset and Graphics. BthPan's variant differs only in the surrounding cache-check that uses `Test-MsBthPanWdacPolicyDeployed` instead of `Test-AmdWdacPolicyDeployed` (the same pre-existing divergence documented for r70 / r71).
- `$nonCoSignedAfterTrim` is computed inside the `if` branch rather than relying on a P06-side flag, so a future P06 refactor that changes the trim semantics will not silently desynchronise the short-circuit. The verification is local to I02 entry.
- The Set-PhaseMarker call passes a hashtable Metadata so future diagnostic tools can recognise short-circuited I02 phases (e.g., for a "what does this workspace tell me about kernel-mode signer authorization state?" query) without having to inspect the actual host state.
- The Write-Detail messages enumerate the two reasons the WHQL embedded signatures and trust-store import are sufficient (kernel CI + pnputil), so operators reading the transcript years later can reconstruct the design rationale without consulting the SPEC.

### D.31.16 `$Ctx` initialiser checklist for r71 producer rollout (lesson learned in r73 / r39 / r21)

Background. The Chipset r72 P05 phase failed at runtime on a clean-installed Windows Server 2019 host with the localised exception:

```
"WhqlCoSignAnalysis" の設定中に例外が発生しました: "このオブジェクトに
プロパティ 'WhqlCoSignAnalysis' が見つかりません。
プロパティが存在し、設定可能であることを確認してください。"
```

…thrown from the `$Ctx.WhqlCoSignAnalysis = @()` fallback line inside the `catch` block of the r71 P05 WHQL-analysis production site. The root cause was that the `[pscustomobject]@{...}` `$Ctx` initialiser at the top of the script did NOT include a `WhqlCoSignAnalysis = $null` line. In PowerShell 5.1 sealed-object semantics, any `$obj.NewProp = value` assignment that targets a property not declared in the initialiser raises a terminating exception (see SPEC §A.11.5c for the rule and §D.31.7 for the broader PS 5.1 footgun catalog).

The same defect was present in BthPan r20. Graphics r38 did not exhibit the defect, but for a different reason: Graphics had no P05 producer site at all (an unrelated functional gap fixed in r39).

#### D.31.16.1 Checklist for adding a new field to `$Ctx`

Any future revision that adds a new field to `$Ctx` (a) **MUST** add a corresponding `<NewField> = $null` (or appropriate empty-sentinel) line to the `[pscustomobject]@{...}` initialiser in the same revision, and (b) **SHOULD** add an explanatory comment naming the producer and consumer phases. The checklist:

1. **Decide on the sentinel value**. For collections, prefer `@()` over `$null` so consumers can use `.Count -eq 0` without a `$null` guard. For scalars, `$null` is correct. For complex pscustomobject sub-records (e.g., `SecureBootBaseline`), `$null` is correct and the consumer must check for `-not $null` before reading members.
2. **Add the initialiser line** in the same script revision that adds the producer phase. The initialiser line is byte-identical across Chipset, Graphics, and BthPan (NPU exempt — different `$Ctx` shape). Add it to all three scripts as a single revision.
3. **Add the explanatory comment** above the initialiser line. Format:
   ```powershell
   # <FieldName> — <one-line purpose>.
   # Pre-declared as <sentinel> so plain '.' assignment works on
   # the [pscustomobject] without requiring Add-Member.
   # Populated by <ProducerPhaseId>; consumed by <Consumer1>, <Consumer2>.
   # See SPEC §<section>.
   <FieldName> = <sentinel>
   ```
4. **Run `psa.py --include PSA2009`** against all four scripts before committing. The rule is the static-analysis gate that closes this loop. If PSA2009 reports zero findings, the integration is correctly wired.
5. **Add a TESTING.md test case** under "Static analysis acceptance tests" that asserts the assignment site exists and is reachable. Format: TC14.<N> ("`$Ctx.<FieldName>` property-declaration smoke test"). The Chipset r73 / Graphics r39 / BthPan r21 release introduces this convention with TC14.6.
6. **Bump all affected scripts together**. The `$Ctx` initialiser is part of the cross-script shared contract; bumping one script without the others creates a producer-consumer skew that PSA8001 cannot detect (because the affected function is not in the shared-helper drift set). Bump Chipset, Graphics, and BthPan together — and skip NPU explicitly if it does not exercise the new field (no empty revisions; cite the per-script applicability table in the CHANGELOG entry).

#### D.31.16.2 Producer-consumer wiring audit

Whenever a new field is added to `$Ctx`, audit the four scripts for producer-consumer skew:

- **Producer site present?** Find the phase that should populate the field (`grep -n '$Ctx\.<FieldName>\s*=' <script>.ps1`). If the producer is missing in any script, the field will remain at its sentinel value and every consumer will silently degrade to its fallback path. This is the defect that hid in Graphics r37 / r38 for two full revisions.
- **Consumer sites present?** Find every read site (`grep -n '$Ctx\.<FieldName>' <script>.ps1`). If a consumer is missing in any script, the field will be populated but the dependent feature will not run on that driver family. This is the defect that *would* have hidden in NPU if r71 had added the consumer sites without exempting NPU.
- **Producer-consumer order respected?** Phase IDs are lexicographically ordered (`P00 < P01 < ... < V01 < ... < I00 < ... < I05`). Any consumer at phase X must run after the producer at phase Y where Y < X. The producer must NOT run after the consumer.

#### D.31.16.3 Why PSA2009 is the right place for this rule

The defect could in principle be detected by other static-analysis approaches:

- **PSScriptAnalyzer (`Invoke-ScriptAnalyzer`)** does not have an equivalent rule. Its closest analogue is `PSAvoidAssignmentToAutomaticVariable`, which is about engine auto-variables, not user pscustomobjects.
- **AST-walking with `[System.Management.Automation.Language.Parser]`** could in theory model the sealed-object semantic, but the implementation would have to track variable identity across the entire script and decide which `$X.Y = value` assignments are sealed-object violations vs. legitimate hashtable extensions. This is essentially what PSA2009 does — but at the file level rather than the phase level, with the conservative hashtable-form drop pass that prevents false positives on accumulator patterns like NPU's `$result`.
- **Runtime detection (e.g., a `try/catch` at the assignment site)** would surface the defect only at the first execution, and only on the host that happens to traverse the affected phase. This is exactly what hid the Chipset r72 defect: the project's CI matrix did not include a `PrepareVerify` run on WS2019, and the defect surfaced only when a customer triggered the path on their own host.

PSA2009 is the right gate because it is (a) language-aware (models the PSv5 sealed-object semantic accurately), (b) file-level (no need to reason about phase ordering at static-analysis time), (c) conservative against false positives (the hashtable-form drop pass), and (d) zero-cost at runtime (purely a pre-commit / CI artifact). The Chipset r73 / Graphics r39 / BthPan r21 release upstreams the rule into `psa.py` v3.8.0 and codifies its use in the §A.11.5c rule documentation.



## D.32 Runtime correctness fixes from the 2026-05-24 WS2019 + Renoir bench cycle (`r74`)

### D.32.1 Summary

§D.31 landed the WHQL co-sign pre-detection, Path B prerequisite check, `-SkipNonCosignedDrivers`, and r72 I02 short-circuit. The intent was that a Renoir + WS2019 + Secure Boot OFF host should run `-Action Install` end-to-end and produce an honest install transcript with WHQL classification visible to the operator. The 2026-05-24 bench cycle — an `-Action PrepareVerify -CleanWorkRoot` followed by `-Action Install` followed by a reboot followed by `-OnlyPhases V06` on a clean-installed Windows Server 2019 Datacenter host with AMD Ryzen 5 PRO 4650U (Renoir, Lenovo ThinkPad X13 Gen 1 AMD) — surfaced three additional defects that survived the r73 release. r74 (chipset) / r40 (graphics) / r22 (bthpan) closes all three. NPU is unaffected (its helper surface does not exercise the affected code paths) and stays at r18.

This section is the post-incident analysis and design contract for the r74 release.

### D.32.2 Defect 1: `Test-WhqlCoSignature` called a non-existent `Find-Signtool` helper

**Symptom (operator-visible).** P05 emitted the localised warning pair `r71: WHQL co-sign analysis failed: 指定された名前のパラメーターを使用してパラメーター セットを解決できません。` followed by `r71: I00 C6 condition and -SkipNonCosignedDrivers will operate on an empty analysis.` The r73 catch-block fallback wrote `$Ctx.WhqlCoSignAnalysis = @()`, P05 completed cleanly, and the install proceeded — but every downstream consumer of the analysis (the `Show-WhqlCoSignAnalysisReport` banner, the C6 acknowledgement gate, the `-SkipNonCosignedDrivers` trim, and the r72 I02 short-circuit) silently degraded to its empty-analysis fallback. The operator never saw which drivers were WHQL co-signed and which were not, and the safer "Path A on the WHQL subset, keep Secure Boot ON" workflow was structurally unreachable.

**Root cause.** `Test-WhqlCoSignature` line 4776 (chipset r71-r73, equivalent positions in graphics / bthpan) read:

```powershell
$signtool = $null
try {
    $signtool = Find-Signtool
} catch {
    Set-DebugStep ('Test-WhqlCoSignature: Find-Signtool threw: {0}' -f $_.Exception.Message)
}
```

The helper named `Find-Signtool` does not exist in this repository. The actual Windows Kits resolver is `Find-KitTool` and the correct call is `Find-KitTool 'signtool.exe'`. Calling a non-existent command raises `[System.Management.Automation.CommandNotFoundException]`, which the surrounding `try/catch` caught silently. The conservative fallback at the `if (-not $signtool)` branch then returned `'self-only'` for every `.sys` file, even those carrying a WHQL co-signature. Because the inner `try/catch` then succeeded (returning the conservative verdict), the outer `New-WhqlCoSignAnalysis` finished without raising, the analysis array was populated with valid records, and P05 completed normally — *but every record reported `IsFullyCoSigned=$false`*.

This is why the symptom presented as "WHQL analysis fails with parameter-binding error" on the **r72** host but as "WHQL analysis succeeds with empty banner" on the **r73** host. r73 added the `$Ctx.WhqlCoSignAnalysis = $null` pre-declaration (per §D.31.16) which kept the catch-block fallback from raising a secondary exception, masking the inner defect more thoroughly.

The localised `指定された名前のパラメーターを使用してパラメーター セットを解決できません。` message in the 2026-05-23 transcript is consistent with `CommandNotFoundException` re-raised through a deeper PowerShell parameter-binding path in some PS 5.1 host configurations (the message format varies by host).

**Fix (r74).** Replace `Find-Signtool` with `Find-KitTool 'signtool.exe'`:

```powershell
$signtool = $null
try {
    $signtool = Find-KitTool 'signtool.exe'
} catch {
    Set-DebugStep ('Test-WhqlCoSignature: Find-KitTool ''signtool.exe'' threw: {0}' -f $_.Exception.Message)
}
```

The change is byte-identical across chipset r74 / graphics r40 / bthpan r22 (PSA8001-compliant).

**Why this defect went undetected for three revisions.** The Test-WhqlCoSignature helper was introduced in r71 and has been quietly returning `'self-only'` for every `.sys` file ever since on every host that lacked a pre-cached `signtool` resolution path. The r71 / r72 / r73 CI matrix included no end-to-end run that observed the `Show-WhqlCoSignAnalysisReport` banner output, so the silent degradation was invisible. The 2026-05-24 bench was the first run that explicitly diffed expected vs. actual WHQL classification (against `signtool verify /pa` output on the staged `.sys` files) and noticed every classification was wrong.

### D.32.3 Defect 2: `signtool verify` was invoked without the `/all` flag

**Symptom (operator-visible).** Even after Defect 1 was fixed, the WHQL classification of AMD chipset 8.05.04.516 drivers reported every `.sys` file as `IsFullyCoSigned=$false`. The signtool stdout block returned only the primary signer (AMD via Sectigo CA R36 chain) and never showed the Microsoft Windows Hardware Compatibility nested signature when the file carried one.

**Root cause.** The line `& $signtool verify /pa /v $Path 2>&1 | Out-String` retrieves the primary signature only. The `/all` flag is required to enumerate the primary signature AND every nested signature. AMD's kernel drivers historically embed the WHQL co-signature as a nested signature on top of AMD's own primary signature, so `signtool verify /pa /v` alone hides exactly the signature this function is looking for.

This is independent of Defect 1 — fixing Defect 1 alone yielded a correctly-invoked but still-wrong-result helper. Both fixes are needed.

**Fix (r74).** Add `/all` to the verify invocation:

```powershell
$stdOut = & $signtool verify /all /pa /v $Path 2>&1 | Out-String
```

The `/pa` flag retains the existing semantic (policy-aware / plug-and-play chain selection). The `/v` flag retains verbose output that emits the per-signer `Issued to:` lines this function parses. The output format is stable across signtool versions 6.0–10.0.x; the `Issued to:` line regex needs no change.

**Empirical finding from 2026-05-24 bench.** When Defect 1 + Defect 2 are both fixed and `signtool verify /all /pa /v` is invoked on the chipset 8.05.04.516 `.sys` files staged in `C:\Windows\System32\DriverStore\FileRepository\*`, the verdict per file is:

| `.sys` file | Number of Signatures | WHQL co-signature present |
|---|---|---|
| `AmdMicroPEP.sys` | 1 | **❌ No** |
| `amdi2c.sys` | 1 | ❌ No |
| `amdsfhkmdf.sys` | 1 | ❌ No |
| `amdgpio2.sys` | 1 | ❌ No |
| `amdgpio3.sys` | 1 | ❌ No (ASMedia primary) |
| `amdpsp.sys` (variant A) | 1 | ❌ No |
| `amdpsp.sys` (variant B) | 1 | ⚠️ Possibly (dual-signed; signtool primary differs from `Get-AuthenticodeSignature.SignerCertificate`) |
| `amduart.sys` | 1 | ❌ No |
| `SMBUSamd.sys` | 1 | ❌ No |
| `AMDInterface.sys` | 1 | ❌ No |

This **contradicts SPEC §D.30.2 F4** ("`AmdMicroPEP.sys` carries a Microsoft Windows Hardware Compatibility co-signature"), which was written against an older AMD chipset package (the 8.04.x branch). The 8.05.04.516 build dropped the Microsoft co-signature from the AmdMicroPEP, amdi2c, amdsfhkmdf, and related drivers — every chipset driver in the 2026-05-24 bench package is AMD-self-signed only (Sectigo CA R36 / 2026-Q1 issuer).

**Operational consequence.** On Renoir + WS2019 + chipset 8.05.04.516, the Path A WHQL-only install path (SPEC §D.30.4) is **structurally unreachable** — every patch-eligible INF requires Path B (testsigning) to load. The `-SkipNonCosignedDrivers` flag, when set on this package, would trim the install plan to zero INFs.

The §D.30.2 F4 line is updated in this revision to reflect that WHQL co-signature status is **package-version-specific** and cannot be assumed for any given AMD release. The §D.30.4 path-selection matrix is unchanged: it still correctly enumerates Path A and Path B as the only options on legacy Server SKUs.

### D.32.4 Defect 3: V06 misclassified script-installed drivers as `[B]` instead of `[C]`

**Symptom (operator-visible).** After a successful `-Action Install` followed by a reboot, `-OnlyPhases V06` reported:

```
  Driver-source distribution among AMD HARDWARE: [A]=36  [B]=5  [C]=0  [?]=1
```

The five `[B]` entries were the very drivers this script had just installed (AmdMicroPEP, AMDInterface, amdgpio2, amdi2c, amdpsp). The expected V06 report on a freshly-installed host is `[C]=5` for the script-installed devices, signalling that V06 recognises them as its own work and would not propose re-installing them on a subsequent run.

The downstream impact is that V06's Section 2 reported `2 device(s) WILL be replaced` even though the install had already happened. A re-run of `-Action Install` would attempt to "upgrade" the same drivers it had just staged, breaking idempotency.

**Root cause.** `Get-DriverSourceCategory`'s Step 0a (catalog-thumbprint match against `C:\Windows\INF\<oemNN>.cat`) and Step 0b (KnownOurInfSet lookup) are the only paths that can return `[C]` for a driver whose primary `.sys` signer is AMD/vendor and whose patched INF declares `Provider="Advanced Micro Devices"`. Step 1 (Signer-string heuristic) does not match because `Win32_PnPSignedDriver.Signer` is empty for self-signed catalogs on WS2019; Step 2 (Microsoft Provider) does not match; Step 3 (any other Provider) returns `[B]`.

I04 builds `$ourInfSet = Get-OurSignedOemInfSet -ExpectedThumbprint $Ctx.CertThumbprint` once at phase entry (line 13111, chipset r73) and threads it into every `Get-DriverSourceCategory` call. V06 did not — it called `Get-DriverSourceCategory` with `-InfName $cur.InfName -ExpectedSelfSignThumbprint $Ctx.CertThumbprint` only, omitting `-KnownOurInfSet`. Step 0a's `.cat`-path resolution was then the only chance at `[C]` classification, and that resolution fails when:

- The OEM-numbered InfName (e.g. `oem68.inf`) is not the same as the patched-INF basename, and `[System.IO.Path]::ChangeExtension($InfName, '.cat')` produces a path that exists but whose primary signature was overwritten by Windows' catalog-merging machinery during pnputil staging on certain WS2019 build variants.
- The catalog is co-signed by both the script's cert AND a Microsoft-derived intermediate, and Step 0a's `SignerCertificate.Thumbprint -eq $ExpectedSelfSignThumbprint` check returns the wrong cert.

Step 0b (KnownOurInfSet) handles both cases by walking `C:\Windows\INF\oem*.cat` directly and cross-referencing through `pnputil /enum-drivers`, but V06 never invoked the helper that builds the set.

**Fix (r74 / r40).** Build `$ourInfSet` once at the start of V06 Section 1 and pass it to every `Get-DriverSourceCategory` call in V06 Section 1 and Section 2. The change adds ~10 lines per call site and is functionally equivalent to the pre-existing I04 build site. BthPan's V06 does not exercise `Get-DriverSourceCategory` (it uses a different device-disposition probe specific to `BTH\MS_BTHPAN`), so the BthPan r22 release is not affected by this defect.

The build is gated on `$Ctx.CertThumbprint` being non-empty: PrepareVerify-only runs that never reach P07 / I01 leave the thumbprint unset, so V06 returns an empty hashtable in that case and the existing Step 0a / Step 1 / Step 2 / Step 3 cascade continues to work.

### D.32.5 Defect 4: I02 → I03 control flow ran I03 / I04 immediately after newly enabling testsigning

**Symptom (operator-visible).** When `-Action Install` was invoked on a host where I02 newly enabled BCD testsigning (i.e., I02 was not in its cached "already on" branch), the script printed:

```
*** A REBOOT IS REQUIRED FOR TESTSIGNING TO TAKE EFFECT ***
After reboot the desktop will display a "Test Mode" watermark.
Then run -Action Install AGAIN (same command). The script will
detect that I01/I02 are already done and continue with I03/I04.
PHASE I02 -> DONE     elapsed: 0.95s

========================================================================
 PHASE I03 - InstallDrivers
========================================================================
```

The message says "run AGAIN" but the script proceeded to I03 / I04 in the same execution. The drivers were staged in the driver store (this works because pnputil's signature check uses the trust store, which I01 already populated), but kernel CI cannot load self-signed drivers until the reboot activates testsigning. I04 then reported five devices in `REBOOT_NEEDED` and the functional-health probe could not run.

The result is a self-inconsistent transcript: the I02 footer announced an intermission that did not happen.

**Root cause.** I02 wrote the `PendingRebootMarker` to disk and printed the warning, but the phase dispatcher continued with the next phase in `Selected phases`. I03 did not check the marker because the marker is informational; it is not a halt signal.

**Fix (r74 / r40 / r22).** I02 now sets `$Ctx.RebootRequiredBeforeI03 = $true` whenever it newly enables testsigning (the flag is per-process, NOT persisted to disk). I03 and I04 read the flag at the top of their respective `param($Ctx)` blocks and short-circuit with a clear "halt for reboot" message when the flag is set. The footer reads `Write-PhaseFooter 'I03' 'halted-pending-reboot'` to distinguish from `'done'` or `'cached'`.

On the re-run after the reboot, `$Ctx.RebootRequiredBeforeI03` starts as `$false` (per-process flag, fresh `$Ctx` initialiser), I02 hits its cached "already on" branch, and I03 / I04 proceed normally.

Why the flag is per-process and not persisted: persisting it would require a `Clear-` call at the right moment after the reboot, which is fragile. The post-reboot re-run already does the right thing by design — I02 detects "testsigning already on", caches, and falls through — so no marker is needed.

### D.32.6 What r74 does NOT change

For clarity:

- **`Find-KitTool`** itself is unchanged. The fix is the call site in `Test-WhqlCoSignature`.
- **The Step 0a / 0b / 1 / 2 / 3 cascade** in `Get-DriverSourceCategory` is unchanged. The fix is to make V06 thread `$ourInfSet` into the call so Step 0b can fire.
- **The PendingRebootMarker mechanism** is unchanged. The fix adds a new per-process flag that runs alongside the existing marker.
- **The WHQL analysis surface in P05** is unchanged. It just now produces correct results.
- **The C6 acknowledgement gate** is unchanged. It now fires when it should (it previously could not fire on any host because the analysis was empty / all-self-only).
- **The r72 I02 short-circuit** is unchanged. It now can fire on hosts where the WHQL analysis correctly identifies an all-WHQL-coverable install plan.

### D.32.7 Release version contract for r74

| Script | Old | New | Reason for bump |
|---|---|---|---|
| Chipset | `chipset-2026.05.23-r73` | `chipset-2026.05.24-r74` | All four r74 defects above |
| Graphics | `graphics-2026.05.23-r39` | `graphics-2026.05.24-r40` | Defects 1, 2 (byte-identical helper); Defect 3 (V06); Defect 4 (I02→I03) |
| BthPan | `msbthpan-2026.05.23-r21` | `msbthpan-2026.05.24-r22` | Defects 1, 2 (byte-identical helper); Defect 4 (I02→I03). Defect 3 not applicable (BthPan V06 does not exercise Get-DriverSourceCategory). |
| NPU | `npu-2026.05.23-r18` | `npu-2026.05.23-r18` (unchanged) | NPU does not carry `Test-WhqlCoSignature`, `Get-DriverSourceCategory`, or `RebootRequiredBeforeI03`. Per SPEC §A.7 ("no empty revisions") NPU is NOT bumped. |
| `$Script:ScriptTag` (all three bumped) | `legacy-ws2019-wdac-spf-integration` | `legacy-ws2019-runtime-correctness-fix` | r74 release-line identity |

Sister-script PSA8001 byte-identity is preserved across chipset r74 / graphics r40 / bthpan r22 for `Test-WhqlCoSignature`. The V06 `$ourInfSet` build is byte-identical between chipset and graphics; bthpan does not have the construct. The I02 / I03 / I04 halt block is byte-identical between chipset and graphics; bthpan's variant inherits its single-INF / `Get-MsBthPanDevice`-based I04 structure and uses the same halt logic body with the BthPan-specific subheader.

### D.32.8 Test scenarios captured in TESTING.md §16

TC16.1 — `Test-WhqlCoSignature` returns `cosigned` for a known WHQL-co-signed file (e.g. a Windows-inbox `.sys` cherry-picked into `C:\Temp\`).
TC16.2 — `Test-WhqlCoSignature` returns `self-only` for AmdMicroPEP.sys from chipset 8.05.04.516 (negative case; confirms §D.32.3 finding).
TC16.3 — V06 on a host that has staged the script's drivers reports `[C]>0` for those devices.
TC16.4 — V06 on a re-run after a successful install reports `0 device(s) WILL be replaced` (idempotency).
TC16.5 — `-Action Install` on a host with `testsigning OFF` halts after I02 with `'halted-pending-reboot'` footer; no I03 / I04 entries written to the workspace markers.
TC16.6 — `-Action Install` on a re-run after the reboot of TC16.5 proceeds through I02 (cached) → I03 → I04 with `RebootRequiredBeforeI03=$false`.

See TESTING.md §16 for the full step-by-step procedures.

### D.32.9 Static analysis posture

The four defects above are not detectable by any rule in `psa.py` v3.8.0 because they are integration defects, not local-form defects. A new rule **PSA2010** (defined in `psa.py` v3.9.0, planned) would walk the AST and flag invocation of any function name that has zero `function <Name>` definition in any of the loaded scripts. PSA2010 would have caught Defect 1 at static-analysis time. The other three defects need integration-level detection (call-graph for Defect 3, control-flow for Defect 4, external-binary semantics for Defect 2) which is out of scope for `psa.py`.

Until PSA2010 lands, the project relies on the field-incident handover documents (this section, TESTING.md §16) to prevent regression by checklist rather than by static-analysis gate.


## D.33 Honest correction of D.32 and additional defects from the 2026-05-25 WS2019 + Renoir bench cycle (`r75`)

### D.33.1 Why this section exists

§D.32 was written as a post-incident analysis of the 2026-05-24 bench cycle and shipped with the r74 release. A subsequent diagnostic pass on 2026-05-25 — running a purpose-built `Diagnose-r40-Bench-Followup-v2.ps1` script against the same Renoir + WS2019 host, after a `-Action PrepareVerify -CleanWorkRoot` followed by `-Action Install` followed by the reboot followed by `-OnlyPhases V06` cycle — revealed two facts that contradict the r74 narrative:

1. **§D.32.2 misdiagnosed Defect 1.** The operator-visible Japanese `指定された名前のパラメーターを使用してパラメーター セットを解決できません。` warning was attributed in §D.32.2 to the typo `Find-Signtool` → should be `Find-KitTool 'signtool.exe'`. While that typo is real (the `Find-Signtool` helper does not exist) and fixing it is correct, **it is not the actual source of the runtime warning.** The v2 diagnostic Step 1.7 captured the `[System.Management.Automation.ParameterBindingException]` with `FullyQualifiedErrorId: AmbiguousParameterSet, Microsoft.PowerShell.Commands.SplitPathCommand` directly, against the `Split-Path -LiteralPath $InfPath -Parent` call site at the head of `Get-InfDriverFileList`. The r74 fix to `Test-WhqlCoSignature` (renaming `Find-Signtool` → `Find-KitTool`) silenced a *different* (and harmless on this host) latent defect, but did not address the warning the operator observed in the field. Both the typo and the `Split-Path` defect were present in r71–r74 simultaneously; the r74 fix happened to land on the typo because of a code-review heuristic ("does this function name exist?") rather than on the AmbiguousParameterSet because of a runtime-binder reading.

2. **A second defect (Defect B) was already partly mitigated but never fully fixed in r74.** The `Get-OurSignedOemInfSet` helper's Pass 1 scanned `C:\Windows\INF\oem*.cat` looking for catalog files signed with the script's self-signed cert. On WS2019 ja-JP, this directory contains 0 oem*.cat files; the catalogs land in `C:\Windows\System32\CatRoot\{F750E6C3-38EE-11D1-85E5-00C04FC295EE}\` (the Microsoft Code Verification Root catalog database, well-known fixed GUID across Windows XP through Server 2025) and additionally in the per-driver `C:\Windows\System32\DriverStore\FileRepository\<inf>_amd64_<hash>\` bundle. Pass 1 therefore returned 0 matches and triggered the early-exit at the `if ($matchedOemBases.Count -eq 0) { return $set }` line, skipping Pass 2 (the pnputil cross-reference that was correctly designed but never got the chance to run). V06's threading of `$ourInfSet` into `Get-DriverSourceCategory` — the r74 fix for Defect 3 — therefore continued to receive an empty hashtable on this build family, leaving the operator-visible `[B] 9 / [C] 0` misclassification intact even after the r74 release.

The r75 release closes both of these along with a third defect that surfaced during static analysis of the resulting `$ourInfSet` topology.

This section is the post-incident correction of §D.32 and the design contract for r75. §D.32 is preserved verbatim because the misdiagnosis itself is a lesson worth keeping in the record.

### D.33.2 Defect A: `Split-Path -LiteralPath ... -Parent` triggers AmbiguousParameterSet on PS 5.1 ja-JP

**Symptom (operator-visible).** Identical to §D.32.2: P05 emitted `r71: WHQL co-sign analysis failed: 指定された名前のパラメーターを使用してパラメーター セットを解決できません。` followed by `r71: I00 C6 condition and -SkipNonCosignedDrivers will operate on an empty analysis.` The downstream effect of an empty WHQL analysis is identical to what §D.32.2 described.

**Smoking-gun evidence from v2 diagnostic Step 1.7**.

```
Form 1: Split-Path -LiteralPath $p -Parent
[FAIL]   FAILED <-- proves the PS 5.1 ja-JP bug
   Exception type      : System.Management.Automation.ParameterBindingException
   Exception message   : 指定された名前のパラメーターを使用してパラメーター セットを解決できません。
   FullyQualifiedErrId : AmbiguousParameterSet,
                         Microsoft.PowerShell.Commands.SplitPathCommand
   Category            : InvalidArgument: (:) [Split-Path]、ParameterBindingException

Form 2: Split-Path -Path $p -Parent                  → [OK] result: C:\Windows\System32
Form 3: [System.IO.Path]::GetDirectoryName($p)       → [OK] result: C:\Windows\System32
```

The diagnostic ran against `C:\Windows\System32\notepad.exe` (a known-good path), so the failure cannot be attributed to file-not-found, permission, or wildcard-expansion issues. The exception's `FullyQualifiedErrorId` directly names the cmdlet and the failure mode (`AmbiguousParameterSet`, `SplitPathCommand`). The two alternative forms (`-Path` positional, `[System.IO.Path]::GetDirectoryName`) both succeed on the same host with the same input.

**Root cause.** On Windows PowerShell 5.1.17763.8755 ja-JP, the `Split-Path` cmdlet's parameter-set resolution table places `-LiteralPath` in the path-decomposition set and `-Parent` in the qualifier-projection set. The two sets are tagged as incompatible by the ja-JP help table for this build, and the binder cannot resolve the operator's intent when both switches are supplied. This is a locale- AND build-specific defect: the same code runs without error on PowerShell 7.x, on PowerShell 5.1 en-US, and on some other PS 5.1 ja-JP builds. The defect is documented in the same family as Microsoft's published `Start-Transcript -Path` quirks (which PSA3005 already covers), but at a different cmdlet and with the inverse remediation (`-Path` is preferred here, while `-LiteralPath` is preferred for `Start-Transcript`).

**Affected call sites.** A single canonical line:

```powershell
$infDir = Split-Path -LiteralPath $InfPath -Parent
```

at the head of `Get-InfDriverFileList`, byte-identical (PSA8001 contract) across `Deploy-AMDChipsetDriverOnWindowsServer.ps1`, `Deploy-AMDGraphicsDriverOnWindowsServer.ps1`, and `Deploy-MSBthPanInboxOnWindowsServer.ps1`. NPU does not define `Get-InfDriverFileList`; the NPU pipeline's INF surface is small enough that the per-INF helper was not factored out, so NPU is structurally immune.

**Fix (r75).** Replace with `[System.IO.Path]::GetDirectoryName($InfPath)`:

```powershell
$infDir = [System.IO.Path]::GetDirectoryName($InfPath)
```

The .NET method has no PowerShell-binder ambiguity and returns the same string as `Split-Path -Path $InfPath -Parent` (both functions return the canonical directory path without trailing separator). The change is byte-identical across the 3 affected scripts (PSA8001-compliant).

**Note on the r74 narrative.** The r74 fix to `Test-WhqlCoSignature` (renaming a non-existent `Find-Signtool` to `Find-KitTool 'signtool.exe'`) does not affect this defect's behaviour. Both the typo and the AmbiguousParameterSet bug were present together from r71 through r74; the operator-visible message was always the `Split-Path` `AmbiguousParameterSet` raised inside `Get-InfDriverFileList` (called from `New-WhqlCoSignAnalysis`, called from `Test-WhqlCoSignature`), which then propagated through the outer `try/catch` and surfaced via the `r71: WHQL co-sign analysis failed:` log line. The r74 release closed an unrelated latent typo but did not change this user-visible behaviour. r75 closes the actual cause.

### D.33.3 Defect B: `Get-OurSignedOemInfSet` Pass 1 scans the wrong directory

**Symptom (operator-visible).** Identical to §D.32.4: V06 reported every script-installed driver as `[B]` (vendor-signed) rather than `[C]` (self-signed), causing the "Match summary" line to report N>0 device(s) `WILL be replaced` on a post-install + post-reboot host where N should be 0 (idempotency). The r74 fix to V06 (threading `-KnownOurInfSet $ourInfSet` into `Get-DriverSourceCategory`) correctly addressed the consumer side; the producer side (`Get-OurSignedOemInfSet`) was the missing link.

**Smoking-gun evidence from v2 diagnostic Steps 2.8a/b/c.**

| Location | oem*.cat count signed by our cert |
|---|---|
| `C:\Windows\INF\oem*.cat` (what r74's Pass 1 scanned) | **0** |
| `C:\Windows\System32\CatRoot\{F750E6C3-38EE-11D1-85E5-00C04FC295EE}\oem*.cat` | **18 of 18 expected** |
| `C:\Windows\System32\DriverStore\FileRepository\<inf>_amd64_<hash>\*.cat` | **18 of 18 expected** |

The pre-reinstall snapshot taken after the MSBthPan installation additionally confirmed that BthPan's `oem115.cat` (signed with the **different** BthPan cert thumbprint `A0B563EAB490458B9CD4A920974C5EF27915E103`) was also resident in the same `{F750E6C3-...}\` folder, alongside the Graphics catalogs signed with `9FEB313999B8314D5B38744255A20C0A15648E2E`. This proves that the CatRoot location is the correct landing place for **any** self-signed catalog from this pipeline, regardless of which sister script staged it — a single code path covers both Graphics and BthPan.

**Root cause.** `C:\Windows\INF\` historically (Windows XP / Server 2003 era) was the OEM catalog directory, but in modern Windows the OEM catalog lifecycle moved into `C:\Windows\System32\CatRoot\{F750E6C3-38EE-11D1-85E5-00C04FC295EE}\` (the Microsoft Code Verification Root catalog database — the GUID is well-known and stable from Windows XP through Server 2025). The `C:\Windows\INF\` directory continues to host the per-driver `oem<N>.inf` files but the matching `oem<N>.cat` files live exclusively under `CatRoot`. On the 2026-05-25 bench host, `C:\Windows\INF\` had 0 oem*.cat files but the corresponding oem<N>.inf files were present, indicating that the Windows installer-side machinery had moved the catalogs to CatRoot at install time and either deleted or never created the INF-side copies.

The r74 `Get-OurSignedOemInfSet` Pass 1 logic was therefore correct in algorithm (enumerate, signature-check, harvest) but wrong in location (`$infDir = Join-Path $env:windir 'INF'`). The Pass 2 fallback (pnputil /enum-drivers cross-reference) was structured to map oem<N>.inf to Original Name names — useful — but never reached on this host because the `if ($matchedOemBases.Count -eq 0) { return $set }` early-exit ran first.

**Fix (r75).** Two layers, chosen for robustness against CatRoot itself being unreachable or empty:

1. **Pass 1a (primary): scan `C:\Windows\System32\CatRoot\{F750E6C3-38EE-11D1-85E5-00C04FC295EE}\oem*.cat`.** Same algorithm as the r74 Pass 1, only the directory changes. On the 2026-05-25 bench host this resolves all 18 Graphics + 1 BthPan catalogs correctly. The GUID is hard-coded in the script source because it is a well-known Microsoft constant — extracting it to a parameter would invite errors. (For documentation on the GUID's origin and stability, see the `CatRoot` shell-extension comments in `winbase.h`; the same value has been used since the original Windows XP release.)

2. **Pass 1b (fallback): pnputil `/enum-drivers` Signer Name match.** If Pass 1a finds 0 matches (e.g., the CatRoot directory is unreadable due to filesystem state, or the host is using a custom catalog store), look up the cert subject CN by thumbprint in `LocalMachine\Root` + `LocalMachine\TrustedPublisher`, then walk `pnputil /enum-drivers` output for entries whose Signer Name matches. The Published Name (`oem<N>.inf`) of each match becomes the seed for `$matchedOemBases`, after which Pass 2 (the existing OEM-name → Original-Name mapping) runs unchanged. This second layer protects against future CatRoot path changes without re-introducing the r74 silent-empty-set behaviour.

3. **Pass 2 (unchanged): pnputil OEM-name to Original-Name mapping.** This was already correctly designed in r74; the r75 fix just makes sure it actually runs by ensuring Pass 1a or 1b populates `$matchedOemBases`.

The change is byte-identical across `Deploy-AMDChipsetDriverOnWindowsServer.ps1` and `Deploy-AMDGraphicsDriverOnWindowsServer.ps1` (PSA8001-compliant). BthPan's V06 does not call `Get-DriverSourceCategory` (see §D.32.4's note) so its `Get-OurSignedOemInfSet` is structurally absent and not affected.

### D.33.4 Defect C: I00 references `$ourInfSet` without building it (latent since r74)

**Symptom (static-analysis).** When `psa.py` v3.9.0 (with the new PSA2001 cross-file lookup of definitions surveyed via the new PSA2010 rule's definition collection logic — see §A.11.6) was run against the r74 sources, both Chipset and Graphics emitted a single `PSA2001 — undefined variable $ourinfset in function Invoke-InstPhase00_PreInstallReview` error. The variable is referenced inside the `-KnownOurInfSet $ourInfSet` argument at the head of I00's "AMD HARDWARE on MS-generic" pre-install review section, but the binding is only created inside `Invoke-VerifyPhase06_HardwareImpactAnalysis` (function-scope local). PowerShell scope rules mean the I00 reference resolves to `$null`, which `Get-DriverSourceCategory` accepts but treats as "no fast-path lookup" — silently degrading the classification path back to Step 0a / 1 / 2 / 3 cascade for I00's display.

**Runtime impact.** Subtle and host-dependent. Before the Defect B fix, this had no observable effect because Step 0a / 1 / 2 / 3 cascade itself was returning the wrong classification on WS2019 ja-JP (the same misclassification that V06 also exhibited). With r75's Defect B fix in place, the Step 0a / 1 / 2 / 3 cascade does produce the correct `[C]` classification at I00, so the missing `-KnownOurInfSet` argument becomes a pure performance pessimisation rather than a correctness issue. But the PSA2001 error is real and the project's `0 errors` gate must hold.

**Root cause.** When r74 added the V06 `$ourInfSet` build (and the matching I04 build that was already in place pre-r74), the I00 phase was overlooked. The "Lessons learned 7" entry in TESTING.md §16.5 specifically calls out "V06 / I04 share the `Get-DriverSourceCategory` consumer surface" but does not mention I00, which has its own independent consumer surface in the AMD-hardware-on-MS-generic review loop.

**Fix (r75).** Mirror the V06 build pattern at the start of I00's per-device loop block:

```powershell
$infIndex = Build-PatchedInfHwidIndex -Ctx $Ctx
# SPEC §D.33.3 (Defect C): build $ourInfSet locally in I00.
# The V06 build at line ~11742 lives in a different function scope
# and is not visible here. The original r74 release threaded
# -KnownOurInfSet through Get-DriverSourceCategory without also
# rebuilding the set per-function, leaving an undefined-variable
# reference latent in this phase. Rebuilding it here matches
# V06's pattern exactly.
$ourInfSet = if ($Ctx.CertThumbprint) {
    Get-OurSignedOemInfSet -ExpectedThumbprint $Ctx.CertThumbprint
} else {
    @{}
}
$matched   = @()
```

This change is byte-identical across Chipset and Graphics. BthPan I00 does not have the AMD-hardware-on-MS-generic loop (single-INF / single-HWID flow) and is not affected.

### D.33.5 Defect 2 (signtool `/all`) and Defect 4 (I02→I03 halt) are unchanged

§D.32.3 and §D.32.5 are validated as correct by the 2026-05-25 bench:

- **§D.32.3 (signtool `/all` flag)**. The v2 diagnostic Step 1.5 ran `Test-WhqlCoSignature` against a known-WHQL-co-signed `AMDRyzenMasterDriver.sys` and returned `Reason='cosigned'`, `IsCoSigned=True`, `SignerCount=12` with the "Microsoft Windows Hardware Compatibility Publisher" signer present. The r74 fix (`signtool verify /all /pa /v`) works correctly. r75 inherits the fix unchanged.

- **§D.32.5 (I02→I03 halt with reboot)**. The 2026-05-25 BthPan Install run reported `I02 -> CACHED  elapsed: 0.50s` followed by `I03 -> DONE  elapsed: 2.29s` (no halt, no `halted-pending-reboot` footer). This is the expected post-reboot behaviour: I02 cached because testsigning was already ON from the prior Graphics install, so `$Ctx.RebootRequiredBeforeI03` stayed `$false`. The r74 fix works correctly. r75 inherits the fix unchanged.

### D.33.6 Release version contract for r75

| Script | Old | New | Reason for bump |
|---|---|---|---|
| Chipset | `chipset-2026.05.24-r74` | `chipset-2026.05.25-r75` | Defects A, B, C |
| Graphics | `graphics-2026.05.24-r40` | `graphics-2026.05.25-r41` | Defects A, B, C |
| BthPan | `msbthpan-2026.05.24-r22` | `msbthpan-2026.05.25-r23` | Defect A only (BthPan has no `Get-OurSignedOemInfSet`; I00 has no AMD-hardware loop) |
| NPU | `npu-2026.05.23-r18` | `npu-2026.05.25-r19` | **Cross-script ScriptTag alignment**, not a code-change bump. NPU's helper surface does not include `Get-InfDriverFileList`, `Get-OurSignedOemInfSet`, or the I00 / V06 `$ourInfSet` pattern, so no source-code change applies. This is a documented exception to SPEC §A.7 *no empty revisions* — see §D.33.10 below for the rationale. |
| `$Script:ScriptTag` (all four) | `legacy-ws2019-runtime-correctness-fix` (Chipset/Graphics/BthPan) / `legacy-ws2019-wdac-spf-integration` (NPU) | `legacy-ws2019-ps51-japp-correctness-fix` | r75 release-line identity reflecting the PS 5.1 ja-JP locus of both Defect A (Split-Path binder) and Defect B (CatRoot path stability across ja-JP / en-US WS2019 builds) |

Sister-script PSA8001 byte-identity is preserved across Chipset r75 / Graphics r41 / BthPan r23 for `Get-InfDriverFileList` (the Defect A fix site), and across Chipset r75 / Graphics r41 for `Get-OurSignedOemInfSet` (the Defect B fix site). The I00 `$ourInfSet` build (the Defect C fix) is byte-identical between Chipset and Graphics.

### D.33.7 Test scenarios captured in TESTING.md §17

TC17.1 — Defect A direct probe: `Split-Path -LiteralPath $p -Parent` fails on a clean WS2019 ja-JP host; `Split-Path -Path $p -Parent` and `[System.IO.Path]::GetDirectoryName($p)` succeed.
TC17.2 — Defect A consumer-side: `Get-InfDriverFileList` returns the expected `.sys` file list after the r75 fix (whereas r74 returned an empty array on the same host).
TC17.3 — Defect B Pass 1a: `Get-OurSignedOemInfSet` enumerates the expected `oem<N>.{inf,cat}` set from `C:\Windows\System32\CatRoot\{F750E6C3-...}\` on a clean WS2019 ja-JP host that has the script's drivers installed.
TC17.4 — Defect B Pass 1b: `Get-OurSignedOemInfSet` falls back to pnputil Signer Name when CatRoot is empty (simulated by symlinking the directory to a temp location). The fallback finds the same set via `pnputil /enum-drivers`.
TC17.5 — V06 idempotency: `-Action Install` followed by reboot followed by `-OnlyPhases V06` reports `0 device(s) WILL be replaced` for all script-installed drivers (the goal that r74's incomplete Defect B fix could not deliver).
TC17.6 — I00 PSA2001 regression: `psa.py 3.9.0 --severity error` against r75 sources reports 0 errors (specifically, no PSA2001 firing on the I00 `$ourInfSet` reference).
TC17.7 — psa.py PSA2010 sanity: a synthetic script containing `Find-Signtool` (undefined) plus `Find-KitTool` (defined) fires PSA2010 once on the typo and does NOT fire on the correct call. This is the static-analysis counterpart that r75 introduces for catching future typos of the §D.32.2 family.
TC17.8 — psa.py PSA2011 sanity: a synthetic script containing `Split-Path -LiteralPath $p -Parent` fires PSA2011 once; the same script with `[System.IO.Path]::GetDirectoryName($p)` or `Split-Path -Path $p -Parent` fires 0 times.
TC17.9 — NPU r19 no-op identity: NPU r19 differs from NPU r18 only in `$Script:ScriptVersion` and `$Script:ScriptTag`. All other bytes are identical (verified by SHA256 of the stripped-trio source). This documents the cross-script ScriptTag alignment rationale per §D.33.10.

See TESTING.md §17 for the full step-by-step procedures.

### D.33.8 Static analysis posture for r75

The r75 release lands **two new psa.py rules** (v3.9.0) that close the static-analysis gaps from r74:

- **PSA2010 (error)** — Call to function not defined in any scanned file or known cmdlet whitelist. Would have caught Defect 1's `Find-Signtool` typo from §D.32.2 directly. PSA2010 is dispatched at the cross-file level (like PSA8001); the union of `function <Name>` definitions across all scanned files becomes the "defined" set, against which every command-position Verb-Noun call is checked. False-positive defense: the verb must be in `APPROVED_VERBS`, the call site must be in command position, and known PowerShell built-in cmdlets are pre-whitelisted (≈200 entries covering Microsoft.PowerShell.Core / Management / Security / Utility / Diagnostics, CimCmdlets, PKI, PnpDevice, Defender, BitLocker, NetTCPIP / NetAdapter, SecureBoot, ScheduledTasks, Storage, Archive, WindowsCapability, ConfigCI, International, WSMan). Consumers extend the whitelist via the new `.psa.config.json` field `psa2010_known_cmdlets`.

- **PSA2011 (error)** — `Split-Path -LiteralPath ... -Parent` triggers AmbiguousParameterSet on PowerShell 5.1 ja-JP. Would have caught Defect A (§D.33.2) at static-analysis time. PSA2011 is file-local; it walks each line (joining backtick continuations) and flags any `Split-Path` invocation containing both `-LiteralPath` and `-Parent` (in either order). Suggested remediations: `[System.IO.Path]::GetDirectoryName($path)` (the .NET method has no PS-binder ambiguity) or `Split-Path -Path $path -Parent` (without `-LiteralPath`).

The four scripts under this repository pass `psa.py 3.9.0 --severity error` with **0 errors** under `.psa.config.json` opt-ins (PSAP0001..PSAP0004 enabled). At the r75 baseline, PSAP0003 reported 9 warnings (the r74-introduced inline-revision-tag references). The subsequent **r76 / r42 / r24 / r20** release adopts `psa.py` 4.0.0, cleans up those 9 PSAP0003 references in line with the SPEC §A.13 policy, and opts in to the new PSAP0005 rule with `psap0005_relaxed_mode: true` as the migration baseline. The strict baseline (everything except PSAP0005) is **0 / 0 / 0** on all four scripts; the PSAP0005 migration baseline is documented separately in §A.11.5 and the cleanup roadmap lives in §A.13. See TESTING.md §17 (TC17.6, TC17.7, TC17.8) for the r75 verification procedures and TESTING.md §18 (TC18.x) for the r76 PSAP0003/PSAP0005 verification additions.

### D.33.9 Lessons learned (additions to §15.5 and §16.5)

8. **A failing test's *reproduction transcript* is more authoritative than its *root-cause hypothesis*.** §D.32.2 read the operator's `指定された名前のパラメーターを使用してパラメーター セットを解決できません。` warning and pattern-matched to "must be a parameter-binding issue, look for typos in helper calls". The actual cmdlet that raised the exception was named in the `FullyQualifiedErrorId` field of the exception object (`AmbiguousParameterSet, Microsoft.PowerShell.Commands.SplitPathCommand`), which the §D.32.2 author did not capture or examine. The v2 diagnostic's Step 1.7 surfaced this directly. For future field-incident analysis, prefer capturing the exception object's `FullyQualifiedErrorId` over the exception message text — the latter is locale- and host-dependent, the former names the cmdlet and failure mode in a machine-grade way.

9. **Sister-script byte-identity is necessary but not sufficient.** PSA8001's coverage of `Get-InfDriverFileList` ensured that the Defect A `Split-Path` bug appeared in all 3 sister scripts simultaneously (and could not "drift" to fix or worsen in just one of them). This is a good property — it bounds the scope of the defect. But it also means a bug, once introduced, propagates across all sister scripts as a copy-paste replica. PSA2011 closes the gap by catching the *form* of the bug at static-analysis time, regardless of how many sisters carry it.

10. **A "no-op revision bump" can be the correct call when ScriptTag identity matters more than source-byte identity.** The r74 release explicitly chose not to bump NPU (per the "no empty revisions" wording in SPEC §A.7) because NPU had no source-code changes. r75 chooses to bump NPU r18 → r19 for the opposite reason: NPU's ScriptTag was at `legacy-ws2019-wdac-spf-integration` while the other three sisters were at `legacy-ws2019-runtime-correctness-fix`, and r75 aligns all four to the new `legacy-ws2019-ps51-japp-correctness-fix` tag in a single release. The trade-off is articulated in §D.33.10.

### D.33.10 Exception to SPEC §A.7 *no empty revisions*: cross-script ScriptTag alignment

SPEC §A.7 states that a script must not be bumped (rNN → rNN+1) unless its source code changes meaningfully. The r75 NPU bump (r18 → r19) is a documented exception to this rule:

- NPU's `Get-InfDriverFileList` does not exist (the NPU pipeline has a single INF and does not factor out the per-INF helper), so Defect A does not apply.
- NPU's `Get-OurSignedOemInfSet` does not exist (NPU uses a different post-install verification flow), so Defect B does not apply.
- NPU's I00 phase does not enumerate AMD hardware against the patched INF set in the same way Chipset / Graphics do, so Defect C does not apply.

Under the strict §A.7 reading, NPU should stay at r18. However, the release is also a ScriptTag-alignment release: the four sister scripts ship a coherent identity (`legacy-ws2019-ps51-japp-correctness-fix`) and the operator-visible banner of each script should read the same release line. Leaving NPU at r18 with the old ScriptTag (`legacy-ws2019-wdac-spf-integration`) would create a confusing "which release am I running?" experience.

The exception is therefore: **a cross-script ScriptTag alignment may bump a script's revision number even if its source code does not change**, provided that (a) the ScriptTag itself does change in the same release, (b) the per-script CHANGELOG.md entry explicitly identifies the bump as "ScriptTag alignment only, no source-code change", and (c) a one-byte version-string change accompanies the bump (so that `$Script:ScriptVersion` reflects the new release line).

The 2026-05-25 r75 release uses this exception. The previous instance was the 2026-05-23 r70 release (Path C deprecation; see §D.30) which used a similar argument; that release predated the explicit §A.7 wording.

If a fourth instance of this exception is needed in the future, the maintainer SHOULD propose tightening §A.7 to enumerate the permitted exception classes rather than relying on per-release narrative.


## Appendix: How to seed a new sister script from this SPEC

If you are creating a 5th script (e.g. `Deploy-AMDRocmRuntimeOnWindowsServer.ps1`):

1. **Choose a reference script.** Use one of the **production-validated** scripts: `Deploy-AMDChipsetDriverOnWindowsServer.ps1`, `Deploy-AMDGraphicsDriverOnWindowsServer.ps1`, or `Deploy-MSBthPanInboxOnWindowsServer.ps1`. **Do NOT use the NPU script as a starting template** — the NPU script is classified as "🆘 Experimental / research-grade — NOT production-ready" (see README.md "Risk classification of the four scripts"), has no physical-hardware validation runs, and its idioms have not been verified to be safe to copy. Among the three production-validated scripts, the Chipset script has the largest test surface (Phase coverage, INF patch logic, multi-OS detection) and the MSBthPan script has the cleanest single-INF / single-HWID flow — pick whichever is closer to your new script's domain. Copy that file as your starting template.
2. Replace `$Script:ScriptName`, `$Script:ScriptVersion`, `$Script:ScriptTag`, `$Script:CertSubjectCn`, `$Script:WdacPolicyName`, `$Script:WdacPolicyGuid`, `$Script:WorkRoot` with values specific to your new script.
3. Re-implement only the **domain helpers** section (platform detection, installer resolution, INF inventory filter). Reuse all other sections verbatim — especially the output helpers (`Write-Step`/`Write-Ok`/`Write-Warn2`/`Write-Fail`/`Write-Skip`/`Write-Detail`/`_LogLine`), timestamp idioms (`(Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ss.fffZ')`), CIM-with-WMI-fallback pattern, and the `Test-WdacToolsAvailable` / `Install-AmdWdacPolicy` / `Uninstall-AmdWdacPolicy` triplet which are PS 5.1-validated and handle multiple edge cases (CiTool absent on WS2019, WS2025 build 26100 schema variant in AllowAll.xml, CIM bridge fallback via PS_UpdateAndCompareCIPolicy). **Ground-up reimplementation of these helpers is strongly discouraged** — they encode validation history that is invisible in the code itself. Two concrete cases (originally documented in the now-removed §D.25 narrative; preserved here as Windows-PowerShell-5.1 footgun examples) illustrate why: (a) `Get-Date -AsUTC` is a PS 7.1+ parameter that fails at parameter binding on PS 5.1 with a non-obvious error message — a clean-room reimplementation typed this idiom and shipped a broken script; (b) `[string]$Script:CertThumbprint = ''` inside a `param()` block silently becomes a literally-named `Script:CertThumbprint` parameter rather than a script-scope assignment, which breaks the intended `-CertThumbprint` caller convention without raising any parse-time error. Both defects survived initial code review and only surfaced under end-to-end execution. Copying a validated sister-script idiom avoids both of these failure modes by construction.
4. Run `python3 psa.py <new-script>.ps1` (see A.11 for setup) until 0 errors.
5. Add B.5 section to this SPEC.md.
6. Add the new script to `README.md` "What's in the box" table, "Parameters" section, "Risk classification" table — and sync `README.ja.md`.
7. Add a physical-hardware validation scenario to `TESTING.md` covering the target AMD consumer devices for your new script.
8. Add a CHANGELOG.md entry for the new script's initial release.

The goal of the strict sister-script convention is exactly this: a new script should be ~80% boilerplate inheritance and ~20% novel logic. The 80% inheritance is not just style — it is the accumulated body of PS-5.1-validated, edge-case-handled, SPEC-documented behavior that cannot be reproduced by reading the SPEC alone.
