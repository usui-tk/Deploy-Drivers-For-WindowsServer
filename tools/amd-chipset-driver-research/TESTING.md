# AMD Chipset Driver Research Toolkit Testing Guide

This guide covers the `2.0.0` publication architecture derived from the qualified `1.3.3-publication-dev` code line. The first 2.0.0 Windows regeneration exposed an aggregate-only PowerShell 5.1 collection-wrapper/schema mismatch; the corrected 2.0.0 source requires one final Windows regeneration.

## 0. Pre-final Windows gates

Before the next Windows full run:

1. PowerShell AST parse must report zero errors.
2. The built-in Test stage must PASS with `SelfTestsReady=True`.
3. `Finalize-AmdResearchEvidenceSession` must reference the script-level publication switch as `$script:SkipPublicExport`.
4. `Test-AmdPublicationContractSelfTest` must PASS when invoked after loading function definitions only, with no normal top-level toolkit initialization.
5. Repository-public Markdown source files and generated public Markdown must be UTF-8 no-BOM with LF line endings.
6. `publication-manifest.json` must explicitly declare `external-artifact/<leaf>`, extraction/workspace portable-path families, Markdown LF/no-BOM conversion, and whether report annotations are inserted.
7. The repository canonical `psa.py` gate must be rerun by the repository/Claude integration environment; the expected merge condition is zero PSA errors.
8. Canonical per-release JSON must be compactly serialized by the Build generator; public copies must remain byte-identical to their runtime canonical source.
9. `publication-manifest.json` schema 1.1 must report `ManifestEntryCount`, `PublicFileCountIncludingManifest`, payload size and largest-file metrics consistently.
10. Fresh-checkout Build must tolerate PowerShell 5.1 collection wrappers in public Raw JSON.
11. Tool-generated public aggregate JSON must contain **zero** PowerShell 5.1 `{ "value": [...], "Count": n }` wrappers; the canonical per-release Raw JSON is not rewritten to achieve this.
12. `public/inventory/amd-selector-static.json` must validate against `schemas/amd-selector-static.schema.json`; the first 2.0.0 regeneration's 131 type errors are a mandatory regression case.

## 1. Built-in Test

```powershell
.\Invoke-AmdChipsetDriverResearch.ps1 -Stages Test -SkipPublicExport
```

Expected readiness self-tests include:

- compiled-selector contract;
- localized host-architecture normalization;
- Windows Installer COM projection/column/row isolation;
- MSI declarative assessment;
- portable-analysis normalization;
- publication contract.

`SelfTestsReady` must be `True`. `PublicationContract` must prove both decoded-JSON private-path rejection and repository-relative `/` separator canonicalization.

## 2. F-01 regression test

The portable-analysis self-test must prove simultaneously:

```text
/SETFILTERUSB -> /SETFILTERUSB
/info.xml     -> /info.xml
C:\           -> C:\
```

while an actual extraction path is converted to `work/extracted/...` and an unrelated absolute filesystem path in a path-bearing field is represented as `external-path/<leaf>`.

After a real Build, search public Raw JSON and require zero occurrences of:

```text
external-path/SET
external-path/info.xml
external-path/DevID.xml
```

## 3. Publication surface

A successful Build/publication must create:

```text
public/inventory/releases/**
public/inventory/release-index.json
public/inventory/amd-selector-static.json
public/reports/**
public/run-summary.json
public/run-report.md
public/publication-validation.json
public/publication-manifest.json
```

`publication-validation.json` must be `Pass`.

## 4. Manifest verification

For every manifest entry independently recalculate:

- file existence;
- `SizeBytes`;
- SHA-256;
- source SHA-256 where `SourceRelativePath` and `SourceSha256` are present;
- `HandEdited` must never be `true`.

## 5. Fail-closed injection

1. Hash the current `public/publication-manifest.json` and one representative per-release Raw JSON.
2. Inject a private marker such as `/mnt/data/SHOULD_NOT_PUBLISH` into runtime staging.
3. Run a publication-capable partial run.
4. Require `ReviewRequired / exit 2`.
5. Require the previous public manifest and representative Raw JSON hashes to be unchanged.
6. Restore runtime staging and rerun normally.

## 6. Partial-run preservation

A `-Stages Test` or other partial run may update run summary/validation but must not delete unrelated per-release Raw JSON from the previous validated public surface.

## 7. Fresh-checkout reconstruction

With runtime `inventory/**` absent and retained `public/inventory/releases/**` present, the tool may reconstruct runtime lightweight aggregates and `driver-packages.json` from canonical public per-release Raw JSON. The large monolithic aggregate is runtime-only. The rehydration path must accept Windows PowerShell 5.1 collection wrappers of the form `{ "value": [...], "Count": n }` without changing the public source file. A realistic 8.07.16.1035 / 31-INF fixture is used as the regression case.

## 8. Private evidence

Default private evidence is:

```text
private/evidence/runs/**
```

Verify it may contain host/runtime details and that such files are not copied to `public/**`. The private evidence snapshot records only a SHA-256 reference to the public publication manifest rather than duplicating the complete public dataset.

## 9. Markdown repository format

Static repository Markdown and generated `public/**/*.md` must be UTF-8 without BOM and LF-only. The publisher performs this conversion deterministically and records it as `MarkdownLfNoBomFromRuntime`.

## 10. Windows release gate

Because canonical serialization and rehydration logic changed after the successful 1.3.1 diagnostic run, `1.3.3-publication-dev` requires one final fresh Windows full run before v2.0.0 release candidacy. Do not hand-edit prior JSON. The Windows-generated `public/**` from the corrected script is the candidate dataset to audit and commit.

Review at minimum:

- all selected stages and final assessment;
- all 25 acquisition/extraction/INF records;
- MSI declarative status/quality;
- HostMatch behavior for the tested host;
- public validation/manifest;
- exact selector-token preservation in per-release JSON;
- absence of host/private values in public output.
