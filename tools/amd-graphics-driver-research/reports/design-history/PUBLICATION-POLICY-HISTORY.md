# Generated Output Publication Policy

This document defines the trust boundary between repository-safe generated research artifacts and private/debug execution evidence.

## 1. Core rule

For generated research updates, **`public/**` is an allow-list**.

Only generated files below:

```text
tools/amd-graphics-driver-research/public/**
```

are intended for unattended GitHub Actions commits.

Do not infer safety from file extension or filename. A JSON/Markdown file outside `public/**` may still contain local paths, runtime identifiers or debugging context.

## 2. Classification matrix

| Location | Classification | Auto-commit generated output? | Notes |
|---|---|---:|---|
| `public/**` | Public repository artifact | **Yes** | Must pass publication validation and manifest generation |
| `private/evidence/**` | Private/debug evidence | **No** | May contain environment/path/transcript/debug information |
| `inventory/**` | Runtime staging | **No** | Reconstructable from public baseline plus a new run |
| `work/**` | Runtime/vendor workspace | **No** | Extracted installers and temporary data |
| runtime-generated `reports/**` | Staging/private by default | **No** | Publication copies safe generated reports to `public/reports/**` |
| `data/**`, `schemas/**`, script/docs | Static repository source | Explicit reviewed change only | Not part of an automatic generated-output commit |

## 3. Public / repository-safe contents

Typical public contents include:

- `public/inventory/releases/**` canonical per-artifact analysis JSON;
- product/group/driver mapping and three-generation selection data;
- aggregate INF and Windows Server analysis JSON/CSV;
- `public/reports/**` generated human-readable analysis;
- `public/run-summary.json` and `public/run-report.md`;
- `public/publication-validation.json`;
- `public/publication-manifest.json`.

Public output may contain AMD/public research facts such as AMD URLs, artifact names, hashes, sizes, INF-relative paths and static compatibility analysis.

Canonical public-bound records must also exclude run-specific extractor/transcript strings when a private runtime path occurs anywhere inside the string (for example after a 7-Zip banner or newline), not only when the string begins with a path.

Public output must not contain execution-environment/private fields such as:

- absolute local/user-profile paths;
- host/user/computer names;
- host OS and PowerShell environment details;
- private Evidence paths;
- console transcript text;
- exception or stack-trace details;
- cached AMD HTML;
- download/extraction diagnostics;
- installer binaries.

## 4. Private / debugging contents

`private/evidence/**` is intentionally **not** repository-publication content. It may retain the debugging context required to reproduce or diagnose a run, including local paths and host/runtime details.

`-EvidenceOutputRoot` redirects private Evidence. It does not reclassify Evidence as public.

`-IncludeInstallersInEvidence` is an explicit private-evidence option. Vendor installer inclusion never makes the resulting Evidence archive suitable for automated repository commits.

## 5. Publication transaction and fail-closed behavior


A run must be **research-valid before it is publication-eligible**. If the core run assessment is `ReviewRequired` or `FatalError`, the tool SHALL NOT replace or overlay `public/**`, even if the staged files would pass privacy scanning. The previous validated public baseline is preserved unchanged.

This includes transient product-metadata failures: a run with `MetadataCompleteness=Partial`, blocked Acquire, or downstream skipped stages is private/debug evidence only and must not become an automated GitHub commit candidate.


The tool builds publication output in staging first. It privacy/portability scans the staged surface, writes validation metadata, then atomically replaces the retained public baseline only after validation succeeds.

Canonical JSON is compact at generation time. Publication SHALL NOT pretty-print, minify, or parse/reserialize canonical per-artifact/aggregate JSON as a repair step; canonical runtime files declared as byte-copy sources are copied into staging unchanged. JSON privacy checks SHALL parse JSON and inspect decoded scalar strings so escaped Windows backslashes cannot hide a private path. When generated JSON from Windows PowerShell 5.1 is consumed, collection-wrapper compatibility normalization occurs only in memory and does not rewrite the Raw JSON.

If validation fails:

- the previous `public/**` baseline remains unchanged;
- invalid staging output is not promoted;
- final assessment reports `ReviewRequired`;
- automation should fail rather than commit the invalid result.

A partial stage run overlays its newly generated public files onto the previous public baseline before validating, so unrelated validated public artifacts are not silently deleted.

## 6. Manifest contract

`public/publication-manifest.json` records each public artifact with relative path, byte size, SHA-256 and `PublicRepositoryArtifact` classification.

The manifest also records `ManifestEntryCount`, `PublicFileCountIncludingManifest`, `ManifestedPayloadSizeBytes`, `LargestManifestedFileSizeBytes`, and `LargestManifestedFileRelativePath`. The manifest intentionally excludes its own hash entry, so the total file count is one greater than the manifested payload count. Source path/SHA-256 fields are retained when a public entry is a declared byte copy from a runtime canonical source.

Automation should independently verify the manifest before commit. `public/publication-validation.json` is the privacy/portability gate; the manifest is the content-integrity gate.

## 7. GitHub Actions generated-output contract

A safe workflow follows this pattern:

```text
checkout
→ run toolkit
→ require acceptable final result
→ require publication-validation = Pass
→ verify publication-manifest
→ git add tools/amd-graphics-driver-research/public/
→ reject any staged non-public generated path
→ commit only when the public diff is non-empty
```

Do **not** use repository-wide `git add -A` as the generated-output publication mechanism.

A source/documentation workflow or human-reviewed PR may separately update the script, schemas, curated data and documents. That is a different change class from generated research publication.

## 8. Runtime baseline restoration

The retained repository baseline lives under `public/inventory/**`. On a fresh checkout, the toolkit may seed an empty runtime `inventory/**` from that public baseline. Therefore runtime staging does not need to be tracked solely to make cumulative Build work in GitHub Actions.

A local-installer-only run is also valid without a historical public baseline. If the run does not execute `Select` and does not publish ProductSelection data, `selection-plan.json` is not a mandatory consistency input; all core aggregate/Server-count invariants still apply.

## 9. Operator switches

- `-PublicOutputRoot`: redirect repository-safe publication output/staging.
- `-SkipPublicExport`: perform a private/debug run without replacing the public surface.
- `-EvidenceOutputRoot`: redirect private Evidence only.
- `-SkipEvidenceArchive`: skip private Evidence ZIP creation; it does not affect the public classification contract.
- `-IncludeInstallersInEvidence`: private debug/binary preservation only; never auto-publish.

## 10. Testing

See `TESTING.md` for privacy scans, manifest verification, failure injection, partial-run preservation, fresh-checkout baseline seeding and GitHub Actions staged-path tests.

## Public Markdown byte contract (v1.0.0 release candidate)

All generated Markdown under `public/**` SHALL be UTF-8 without BOM and SHALL use LF-only line endings (`CR` count 0). Runtime reports are normalized only for BOM/newline representation; their textual content is otherwise unchanged. `publication-manifest.json` records runtime-backed Markdown with `GenerationMode=MarkdownLfNoBomFromRuntime`, the runtime `SourceRelativePath` and the pre-normalization `SourceSha256`, while `Sha256` identifies the normalized published bytes.

Canonical JSON and CSV are explicitly outside this Markdown normalization path and remain byte-faithful to their declared runtime sources. The toolkit validates the complete staged public Markdown surface before atomic promotion, including preserved baseline/toolkit-authored Markdown such as `README.md` and `run-report.md`.

Private Evidence SHALL include `snapshot/inventory/**` and `snapshot/reports/**` containing the exact runtime publication-source staging. These snapshots are private audit evidence, not repository-publication content, and allow a reviewer to recompute every declared source-backed `SourceSha256`.

## Cross-platform manifest path contract (0.8.2)

Manifest paths are repository paths and are therefore always POSIX-relative, for example `inventory/releases/26.7.1/example.json`, even when generated on Windows. GitHub Actions and external validators MUST NOT need to translate `\` to `/`. Publication is fail-closed if the staged file set and manifest differ, a path is unsafe/duplicated, or a size/SHA-256 mismatch is observed. The manifest intentionally excludes itself to avoid a self-hash cycle; `ManifestSelfIncluded=false` makes this explicit.
