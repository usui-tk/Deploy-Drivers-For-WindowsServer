<!--
Thank you for your contribution! Please complete the sections below.

Reminder: PowerShell scripts in this repository must pass `psa.py` with 0 errors
(see SPEC.md §A.11 and CONTRIBUTING.md "Before opening a PR").
English and Japanese documentation mirrors must be updated together (SPEC.md §A.12).
-->

## Summary

<!-- One or two sentences describing what this PR does. Reference the issue it closes (if any). -->

Closes #

## Type of change

<!-- Tick all that apply. -->

- [ ] 🐛 Bug fix (non-breaking change which fixes an issue)
- [ ] ✨ New feature (non-breaking change which adds functionality)
- [ ] 💥 Breaking change (fix or feature that would cause existing behaviour to change)
- [ ] 📖 Documentation update (`README.md` / `SPEC.md` / `TESTING.md` and/or Japanese mirrors)
- [ ] 🔧 Build / static-analyzer / CI tooling change
- [ ] 🧪 Test / validation report addition (`TESTING.md` §1 / §2 / §3 / §4)
- [ ] 🆕 New sister script (e.g. ROCm runtime — see `SPEC.md` Appendix)

## Affected scripts and phases

<!-- Tick which scripts change, and which phase IDs (P00–I04) are touched. Add a brief note if non-obvious. -->

- [ ] `Deploy-AMDChipsetDriverOnWindowsServer.ps1` — phases:
- [ ] `Deploy-AMDGraphicsDriverOnWindowsServer.ps1` — phases:
- [ ] `Deploy-AMDNpuDriverOnWindowsServer.ps1` — phases:
- [ ] `Deploy-MSBthPanInboxOnWindowsServer.ps1` — phases:
- [ ] Documentation only (no script change)
- [ ] Other (describe):

## Revision bump

<!-- Per SPEC.md §A.13 — required for any change to phase semantics, output format, parameter set, install-decision logic. Cosmetic-only changes do not require a bump. -->

- Old → new `$Script:ScriptVersion`:
- Old → new `$Script:ScriptTag`:
- N/A (cosmetic / documentation only):

## Pre-merge checklist

<!-- Per CONTRIBUTING.md "Before opening a PR" — tick every item before marking ready for review. -->

- [ ] **Static analyzer**: `python3 psa.py <script>.ps1` returns 0 errors on every changed script (see [`SPEC.md` §A.11](../blob/main/SPEC.md#a11-static-analysis-with-psapy) for setup). Warnings/info match the baseline in [§A.11.5](../blob/main/SPEC.md#a115-documented-baseline-warnings-and-info); any drift is justified below.
- [ ] **PrepareVerify smoke test**: `-Action PrepareVerify -CleanWorkRoot` completes without errors on a real Windows host with the target AMD consumer devices (or, for BthPan, a host with a bound Bluetooth controller). Log excerpt pasted below.
- [ ] **Bilingual documentation sync**: every English doc change has a corresponding Japanese change in the same PR (`README.md` ↔ `README.ja.md`, `SPEC.md` ↔ `SPEC.ja.md`, `TESTING.md` ↔ `TESTING.ja.md`).
- [ ] **`SPEC.md` Part D entry**: for behaviour-breaking or non-obvious changes, a new §D.* entry documents the symptom, root cause, and rationale.
- [ ] **PowerShell 5.1 compatibility**: no PS 7+ specific syntax (`??`, `?.`, ternary `?:`, etc.).
- [ ] **No new external dependencies**: changes do not introduce reliance on third-party tools beyond the existing list (PowerShell standard library + `winget` for SDK/WDK install).
- [ ] **No real secrets in diff**: no PFX passwords, BitLocker recovery keys, AMD account credentials, API tokens. Thumbprints and policy GUIDs are fine.

## Validation evidence

<!-- Paste 20-50 lines of log excerpts, screenshots of Device Manager / V06 output, or links to attached files.
For Install runs: I03 5-tuple summary line + I04 final verdict line.
For NPU script: the 4-tier source resolution decision used.
For BthPan: pre-install AS-IS classification (Unknown Device / Phantom OK / True Resolution) and the post-install I04 line. -->

```
[paste log excerpts here]
```

## Notes for the reviewer

<!-- Anything else the maintainer should know:
- Cross-script symmetry preserved? (Helpers verbatim-shared across sister scripts — see SPEC.md §A.1.1)
- Any deferred work (TODO comments, follow-up issues to file)?
- Backwards-incompatibility callouts (e.g. workspace path change, parameter rename) for the README.md Disclaimer section?
-->
