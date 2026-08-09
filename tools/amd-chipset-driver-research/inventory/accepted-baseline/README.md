# Accepted inventory baseline

This directory contains the repository-committed, reviewer-friendly snapshot derived from the successful Windows PowerShell 5.1 acceptance run on 2026-08-09.

## Scope

- 25 unique AMD chipset software releases
- range: 2.04.04.111 through 8.07.16.1035
- 25/25 AMD artifacts acquired
- 25/25 releases reached `ExtractionComplete`
- 643 INF package records
- 158 KMDF declarations
- 25 UMDF declarations
- 0 INF parse failures

## Why this is separate from runtime `inventory/`

Normal tool runs regenerate files directly under `inventory/` and may contain machine-local paths and environment-specific fields. The files here are an accepted research snapshot with only path normalization applied for repository portability.

The generating tool version remains `0.4.3` inside the generated JSON because that is the version that produced the accepted evidence. Toolkit `1.0.0` is the GitHub/GA promotion of that accepted implementation.

See `baseline-provenance.json` for the source Evidence ZIP SHA-256 and normalization rules.

## Intentionally excluded from Git

- downloaded AMD `.exe` / `.zip` installer binaries;
- raw extraction workspaces;
- raw AMD release-note HTML;
- console transcripts and run-scoped Evidence ZIPs;
- `extraction.json` and environment evidence whose primary value is run diagnostics rather than long-term canonical research data.

Those remain reproducible with `Invoke-AmdChipsetDriverResearch.ps1` and should be supplied as Evidence ZIPs when debugging or auditing a specific run.

Companion human-readable accepted reports are stored in `../../reports/accepted-baseline/`.
