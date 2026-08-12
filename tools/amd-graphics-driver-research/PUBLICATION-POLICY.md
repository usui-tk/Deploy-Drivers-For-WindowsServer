# Generated Output Publication Policy

This document is the concise operator-facing publication policy for the AMD Graphics Driver Research Toolkit. Normative details are defined in `SPEC.md`; release verification is defined in `TESTING.md`.

## 1. Core rule

Generated repository updates SHALL treat `public/**` as an explicit allow-list.

The tool SHALL NOT publish runtime/debug data simply because it happens to be JSON, CSV or Markdown.

## 2. Surface classification

| Surface | Classification | Generated Git commit |
|---|---|---:|
| `public/**` | repository-safe generated artifacts | **Allowed** |
| `private/evidence/**` | private/debug/audit evidence | No |
| `inventory/**` | runtime publication source / analysis staging | No |
| `reports/**` | runtime report staging + historical reports | No automatic generated commit |
| `work/**` | download/extraction workspace | No |
| source / `data/**` / `schemas/**` / docs | static repository content | explicit source review only |

## 3. Public content

The validated public surface may contain:

- product and product-group metadata;
- product-to-driver mappings;
- selection plan;
- canonical per-artifact analysis JSON;
- aggregate inventory/compatibility views;
- generated release Markdown;
- repository-safe run summary;
- publication manifest;
- publication validation result.

## 4. Private content

Private Evidence may retain information that is intentionally excluded from repository publication, including:

- host/runtime details;
- local absolute paths;
- PowerShell/OS information;
- transcripts and exception/stack information;
- cached AMD pages;
- acquisition/extraction logs;
- evidence/archive locations;
- optional installer payloads when explicitly requested.

For auditability, private Evidence also contains exact publication-source staging beneath:

```text
snapshot/inventory/**
snapshot/reports/**
```

Those files exist so manifest `SourceSha256` values can be independently verified. Their presence in Evidence does not make them public repository output.

## 5. Publication transaction

Publication is fail-closed.

The publisher SHALL:

1. create a staging public tree;
2. preserve a prior validated baseline where partial-run semantics require it;
3. overlay current generated candidates;
4. apply the declared Markdown byte transformation;
5. generate publication metadata;
6. validate privacy, paths, file coverage, SHA-256/size, dataset consistency and format contracts;
7. replace the final `public/**` only after all required validation passes.

A failed staging surface SHALL NOT replace the previous valid public surface.

## 6. Markdown byte contract

Every public `.md` SHALL be:

```text
UTF-8 without BOM
LF-only
CR byte count = 0
```

Runtime-backed Markdown SHALL be transformed only by:

- removing a UTF-8 BOM if present;
- converting CRLF or lone CR to LF.

Text content SHALL otherwise remain unchanged.

Runtime-backed Markdown uses the generation mode:

```text
MarkdownLfNoBomFromRuntime
```

## 7. JSON / CSV byte contract

JSON and CSV SHALL remain byte-faithful to their declared runtime sources when their manifest mode declares byte-copy behavior.

Canonical JSON is generated compact at Build time. Publication SHALL NOT parse/reserialize canonical JSON merely to remove pretty-print whitespace or normalize line endings.

This differs intentionally from Markdown.

## 8. Publication manifest

`public/publication-manifest.json` SHALL cover every public payload file except the manifest itself and SHALL record enough information to verify:

- repository-relative path;
- public classification;
- generation/transformation mode;
- source relative path, size and SHA-256 when source-backed;
- published size and SHA-256;
- manifested entry count;
- total public file count including the manifest;
- no hand editing.

The manifest itself is bound into private Evidence through `snapshot/public-publication-reference.json`.

## 9. Privacy validation

Privacy validation SHALL examine decoded JSON scalar values, not only raw serialized text.

Machine-local paths appearing inside multiline logs or escaped JSON strings SHALL remain private.

A validation failure SHALL block publication.

## 10. Dataset consistency

Publication SHALL cross-check available primary artifacts rather than trusting a summary alone.

Depending on selected stages, this may include consistency among:

- selection plan;
- per-artifact canonical analysis;
- aggregate summary;
- INF topology;
- Windows Server applicability views;
- run summary.

A partial/local run SHALL not be required to provide unrelated product-selection artifacts it did not execute.

## 11. Repository integration

Repository automation SHOULD commit generated research changes only beneath:

```text
tools/amd-graphics-driver-research/public/**
```

The repository may require `.gitattributes` rules that preserve JSON/CSV bytes verbatim. Public Markdown already conforms to repository UTF-8/no-BOM/LF convention and SHALL not depend on Git rewriting its line endings.

## 12. Generated files are never repaired manually

If a generated public value, format, hash or privacy boundary is wrong:

1. fix the toolkit source;
2. regenerate the affected dataset;
3. re-run publication validation;
4. audit the newly generated artifacts.

Do not edit generated release output after execution.
