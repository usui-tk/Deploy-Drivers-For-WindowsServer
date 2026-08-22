# AMD Chipset Driver Research — Generated Output Publication Policy

This document defines the trust boundary between repository-safe generated research artifacts and private/runtime evidence.

## 1. Core rule

For generated research updates, **`public/**` is an allow-list**.

Only generated files below:

```text
tools/amd-chipset-driver-research/public/**
```

are intended for unattended repository commits. Do not infer publication safety from a `.json`, `.csv`, or `.md` extension outside this directory.

Generated public data is produced by `Invoke-AmdChipsetDriverResearch.ps1`. **Generated JSON/CSV/Markdown must not be repaired or normalized by hand after the run.** If a generated value is wrong, fix the generator, rerun the toolkit, and publish the regenerated output.

## 2. Classification matrix

| Location | Classification | Automatic generated-output commit? | Purpose |
|---|---|---:|---|
| `public/**` | Public repository artifact | **Yes** | Canonical per-release Raw JSON (including host-neutral static signature evidence), public indexes, reports, run summary, validation and manifest |
| `private/evidence/**` | Private/debug evidence | **No** | Host/runtime paths, environment, Windows-native signature/catalog/policy output, host security posture, transcripts, diagnostic logs, optional vendor binaries |
| `inventory/**` | Runtime staging | **No** | Current-run intermediate and aggregate JSON/CSV |
| `reports/**` | Runtime staging | **No** | Script-generated build-stage Markdown before publication normalization |
| `authored/**` | Authored records | **Yes** | Reviewed design/qualification narratives written by a person or a model |
| `work/**` | Runtime/vendor workspace | **No** | Extracted installer payload and temporary files |
| script/docs/schemas/data | Reviewed source | Explicit source change only | Tool implementation and normative documentation |

The old `evidence/**` location is deprecated; new default evidence is under `private/evidence/**`.

## 3. Canonical Raw JSON

The primary repository-verifiable dataset is:

```text
public/inventory/releases/<release>/amd-chipset-analysis-<release>.json
```

These files are generated during `Build` from analysis objects using compact JSON serialization and then copied **byte-for-byte** into the public staging surface. Compact generation removes indentation-only whitespace at the canonical source; publication does not reserialize or rewrite selector tokens, MSI values, XML tokens, device mappings, INF semantics, or other artifact-derived values.

Examples that must remain exact evidence values include:

```text
/SETFILTERUSB
/SETRYZENPPKG
/info.xml
/DevID.xml
C:\
```

Execution-host filesystem paths are made portable earlier, while the per-release analysis document is composed, and only for explicit path-bearing fields. A leading `/` by itself is not a filesystem-path discriminator.

### 3.1 Signature-evidence publication boundary

When the `Signature` stage analyzes a release, its **host-neutral static** evidence may be embedded into that release's canonical Raw JSON as `Release.SignatureAnalysis`. This static evidence is reconstructable from extracted vendor-artifact bytes and may include file hashes, PE certificate-table metadata, CMS/PKCS#7 envelope structure, nested/timestamp evidence, X.509 certificate metadata keyed by DER SHA-256, and signed/recomputed PE digest relationships.


For the Chipset toolkit, `Signature` is deliberately scoped to one release: the only selected release, or otherwise the newest release in the selected set. Historical releases outside that scope remain valid canonical research records without fabricated signature observations. `signature-analysis.json` records the selection policy and analyzed release explicitly.

An incomplete/interrupted/failed selected run SHALL NOT regenerate `public/**`. Publication is attempted only when the current core assessment is `Pass` or `PassWithNotes` **and the current run selected and successfully completed `Build`**. Test-only/analysis-only runs and runs without a current-run `Build=PASS` preserve the previous validated public baseline and record publication as not assessed/attempted.


The following are **not** automatic public generated data:

- `Get-AuthenticodeSignature` observations tied to the current Windows host;
- SignTool command output/results, including `/pa`, `/kp`, `/all`, and `/o` observations;
- native WinTrust catalog member/attribute enumeration observations;
- current certificate-store/chain-policy observations;
- Secure Boot, Device Guard/HVCI, TESTSIGNING, OS identity, or other host security posture;
- Target Server PnP/kernel-load/Code Integrity/device-runtime evidence.

Those belong to runtime/private evidence by default. A later reviewed, sanitized derivative MAY be designed for publication, but it SHALL have an explicit schema and generation/validation contract; the presence of a private observation does not make it repository-safe automatically.


Runtime absolute paths embedded inside otherwise useful free-text acquisition/error evidence SHALL be normalized to repository-neutral evidence markers before canonical public JSON is generated. The decoded-scalar privacy validator remains fail-closed; publication SHALL NOT weaken the validator merely to admit a runtime path.

## 4. Deterministic public derivatives

The publisher may deterministically derive lightweight indexes/aggregates from canonical per-release Raw JSON, including:

- `public/inventory/release-index.json`;
- `public/inventory/releases.json`;
- `public/inventory/release-metadata.json`;
- `public/inventory/acquisition.json`;
- `public/inventory/extraction.json`;
- `public/inventory/embedded-installer-metadata.json`;
- `public/inventory/amd-selector-static.json`.

Large monolithic driver-package aggregates are runtime staging, not required Git artifacts. They use compact runtime serialization to reduce memory/string and disk pressure. On a fresh checkout the runtime aggregate can be reconstructed from public per-release Raw JSON. Rehydration accepts the Windows PowerShell 5.1 `{ "value": [...], "Count": n }` wrapper as a collection at read time; the public Raw JSON is never rewritten to hide that source-runtime representation.

Tool-generated **public aggregate indexes** are a different layer from canonical per-release Raw JSON. When an aggregate is derived from per-release JSON, the generator recursively converts the Windows PowerShell 5.1 collection wrapper to a plain JSON array. This is a deterministic aggregate projection, not a repair of the canonical Raw JSON. Publication validation fails closed if a wrapper remains in a generated aggregate, and the selector aggregate receives an additional schema-oriented array-shape check.

Generated Markdown copied to `public/reports/**` is normalized by the script to UTF-8 without BOM and LF line endings. This transformation is declared in `publication-manifest.json`; it is not a manual packaging edit.

## 4.1 JSON privacy validation and repository path form

Public JSON privacy checks operate on parsed/decoded scalar values, not only serialized JSON text. This is required because Windows backslashes are escaped by JSON serialization. A private path that is `D:\...` at runtime must still be rejected after it appears as `D:\\...` in the file representation.

Repository-relative references in public indexes and manifests always use `/`, while native filesystem operations may use the host separator internally. Byte-copied and Markdown-normalized public artifacts record their runtime source path and SHA-256 in `publication-manifest.json`.

## 4.2 Declared canonical path transformations

The canonical per-release generator, not a later packaging step, may transform only explicit path-bearing fields. The current transformation families are:

- acquired-installer identity: `external-artifact/<leaf>` when a path-bearing value equals the acquired installer path;
- extraction workspace: `work/extracted/<release>/...`;
- extraction log evidence: `evidence/extraction-logs/...`;
- unrelated absolute paths in path-bearing fields: `external-path/<leaf>` as a last-resort portability marker.

These transformations are field-scoped. Selector/MSI/XML evidence values such as `/SETFILTERUSB`, `/SETRYZENPPKG`, `/info.xml`, `/DevID.xml`, and MSI property value `C:\` are not path-bearing merely because they look path-like.

Public Markdown copied from runtime reports is transformed only to UTF-8 no-BOM + LF. The current publisher does **not** insert a `Machine-readable source` annotation or any other report prose during publication.

`publication-manifest.json` repeats these transformation families so a reviewer can compare the declared contract with the generated files.

## 5. Private evidence boundary

Host/environment information remains private by default. Examples include:

- computer/user/host identity;
- `CPU.ProcessorId`;
- device instance IDs and peripheral identifiers;
- local absolute paths and tool-install paths;
- PowerShell/OS runtime diagnostics;
- Windows-native Authenticode/SignTool/catalog observations and host security posture;
- transcripts, exceptions and stack traces;
- cached HTML and extraction/download diagnostics;
- installer binaries.

These belong under `private/evidence/**` or an operator-provided `-EvidenceOutputRoot` and are not automatically publishable.

## 6. Publication transaction

The publisher is fail-closed:

```text
runtime staging
  -> public staging
  -> privacy/portability/token-integrity validation
  -> manifest generation
  -> atomic public/ replacement only on PASS
```

If validation fails:

- the previous `public/**` remains unchanged;
- invalid staging is discarded;
- validation errors are retained in private evidence;
- final assessment becomes `ReviewRequired`;
- automation must not commit generated output.

Partial runs seed staging from the previous validated public surface so unrelated public Raw JSON is not silently removed.

## 7. Manifest contract

`public/publication-manifest.json` records path, size, SHA-256, classification, generation mode, source-relative path/hash when applicable, and `HandEdited=false`. Manifest schema 1.1 also records `ManifestEntryCount`, `PublicFileCountIncludingManifest`, total manifested payload bytes, and largest manifested file metrics. The manifest does not hash itself, so those count fields intentionally distinguish payload entries from the manifest file.

The manifest also records the complete transformation policy. A reviewer can distinguish:

- `ByteCopyFromRuntimeCanonical`;
- `ByteCopyFromRuntime`;
- `MarkdownLfNoBomFromRuntime`;
- `ToolkitGenerated`.

## 8. GitHub automation contract

A generated-output workflow should:

```text
checkout
-> run toolkit
-> require acceptable final result
-> require public/publication-validation.json = Pass
-> independently verify public/publication-manifest.json
-> git add tools/amd-chipset-driver-research/public/
-> reject staged generated paths outside public/**
-> commit only if public diff exists
```

Do not use repository-wide `git add -A` as the generated-output publication mechanism.

Script/docs/schemas/data changes are a separate, explicitly reviewed source-code change class.

## 9. Operator switches

- `-PublicOutputRoot`: redirects repository-safe publication output.
- `-SkipPublicExport`: runs research/private evidence without replacing the retained public surface.
- `-EvidenceOutputRoot`: redirects private evidence only and never reclassifies it as public.
- `-SkipEvidenceArchive`: skips the private evidence ZIP only.
- `-IncludeInstallersInEvidence`: private binary preservation only; never auto-publish.

## 10. Required qualification

Before a release that changes publication behavior, verify:

- AST parse and built-in Test stage;
- `/SETFILTERUSB`, `/info.xml`, `/DevID.xml`, `C:\` preservation self-test;
- real Build -> public publication;
- no `external-path/SET*` regression;
- manifest hash/source-hash verification;
- fail-closed injection preserves the previous public surface;
- partial run preserves unrelated canonical Raw JSON;
- public Markdown is LF/no-BOM;
- private evidence remains outside the public surface;
- Windows full run regenerates public Raw JSON after any generator correction;
- a Signature-stage source change completes the Windows Client native-evidence qualification before public baseline promotion, followed by the separately scoped Windows Server qualification when Server-host behavior is part of the change.
## PassWithNotes and self-contained review evidence

A current run with `OverallStatus=PassWithNotes` is publishable when the note represents an explicitly preserved historical artifact availability gap and the newest discovered/current target artifact is available. `ReviewRequired`, `Interrupted`, and `FatalError` remain non-publishable. The public canonical data must retain the failed historical acquisition record rather than presenting the release as successfully analyzed.
Publication eligibility also requires a successful current-run `Build`; partial `Test`/analysis runs never synthesize or overwrite the public baseline.

After an atomic public promotion succeeds, private Evidence includes a byte-identical copy of the promoted public tree under `snapshot/public/**`. This is a handoff/review convenience only. The repository auto-commit allow-list remains exactly top-level `public/**`; `private/**` and evidence archives remain non-commit surfaces.


## Toolchain capability publication

`public/inventory/toolchain-capabilities.json` is a generated, host-portable capability summary and may be committed when the normal publication gate passes. It may contain tool binary SHA-256, versions, architecture, portable Windows Kit identity, help-output SHA-256/line counts, observed option/token names, verification-profile metadata, and the host-portable `LocalizationContext` needed to interpret native-tool observations. This includes culture/UI-language names and numeric console code pages but never changes the target host. Absolute executable paths, localized raw help stdout/stderr, environment-specific command output, and detailed trust-provider diagnostics remain private evidence under `private/evidence/**`. Native-tool correctness MUST NOT depend on published natural-language strings.
