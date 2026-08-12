# Public generated research outputs

This directory is the **only generated surface intended for unattended repository commits**.

It is managed by `Invoke-AmdGraphicsDriverResearch.ps1`. Generated files under this directory should normally be treated as machine-produced views/canonical data rather than edited by hand.

## Contents

- `inventory/`: portable product mapping, selection data, canonical per-artifact JSON and aggregate analysis.
- `reports/`: generated human-readable release and Windows Server analysis reports.
- `run-summary.json` / `run-report.md`: repository-safe latest-run status.
- `publication-validation.json`: privacy/portability validation result.
- `publication-manifest.json`: path/size/SHA-256 manifest for published files.

## Privacy boundary

Detailed environment/debug evidence is written outside this directory, normally under `../private/evidence/`, and must not be auto-committed. Runtime `../inventory/`, generated `../reports/`, and `../work/` are staging/debug surfaces.

Public output intentionally excludes local absolute paths, user/host/runtime identity fields, transcripts, stack traces, cached HTML, extraction logs, download diagnostics, Evidence paths and installer binaries.

AMD/public research facts such as AMD URLs, artifact hashes/sizes and INF-relative paths are allowed when they are part of the research record rather than execution-environment context.

## Canonical JSON contract

Canonical generated JSON is compact when the toolkit writes it. Publication does not run a separate JSON minifier or parse/reserialize canonical per-artifact/aggregate JSON. JSON privacy validation operates on decoded scalar values so Windows paths remain detectable after JSON escaping. Generated JSON read back from Windows PowerShell 5.1 is consumed through the collection-wrapper compatibility helper without editing the canonical file.

The publication manifest distinguishes manifested payload entries from the total file count including the manifest itself, and records aggregate/largest payload size metrics in addition to per-file SHA-256 values.

## GitHub Actions

A generated-output workflow should:

1. run the toolkit;
2. require `publication-validation.json` to report `Pass`;
3. verify every file in `publication-manifest.json`;
4. stage **only** `tools/amd-graphics-driver-research/public/**`;
5. reject a generated-output commit if another path is staged.

Static source/docs/schemas/data are normal repository content and can be updated through a separate reviewed source change; they are not generated-public output.

See `../PUBLICATION-POLICY.md` and `../TESTING.md` for the full contract.

## Manifest portability

`publication-manifest.json` uses **POSIX-relative `/` paths on every operating system**, including Windows-generated runs. It intentionally excludes itself (`ManifestSelfIncluded=false`) and covers every other public file exactly once with byte size and SHA-256. This allows the same file to be verified directly by Windows runners, Linux GitHub Actions, and external repository tooling without path-separator translation.
