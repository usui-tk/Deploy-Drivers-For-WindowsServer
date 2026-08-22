# AMD CPU/NPU Evaluation Matrix

> **Assessment status (corrected 2026-08-21):** this record describes the
> 2026-08-16 reviewed source set. Its `PreferredProductionCandidate-376` labels
> agree with AMD's authoritative Ryzen AI Software 1.8.0 installation page.
> See `NPU-LIVE-PUBLICATION-DRIFT-2026-08-21.md` for the REV65 source-check
> correction. Deployment qualification remains separate.

## Artifact

`AMD-CPU-NPU-Evaluation-Matrix-2026-08-16_rev2.xlsx`

This English workbook is an authored assessment artifact intended for future repository review and commit. It is not generated `public/**` output and is not part of the publication manifest.

## Purpose

The workbook evaluates CPU-first NPU identification: resolve an exact AMD processor SKU, determine whether an NPU is bundled, determine its NPU generation or platform family, and then assess the reviewed 280 and 376 driver lines. Windows-reported processor and device names are treated as observations requiring normalization and evidence-based mapping, not as exact AMD marketing-name matches.

The research corpus deliberately retains both public support lines. A downstream deployment/build workflow may eventually select one product, but only after exact-SKU, observed-HWID, AMD published-family, static OS/package, and runtime gates pass.

## Provenance

- Revision 2 translates and restructures the earlier Japanese assessment workbook into English.
- The AMD processor catalog snapshot contains 742 rows.
- The candidate assessment contains 145 NPU-related rows.
- AMD product specifications are the primary source for product presence and published specifications.
- Wikipedia processor tables are secondary discovery and cross-check sources; they do not override AMD evidence.
- Exact reviewed ZIP identities and extracted INF/binary observations are carried from this toolkit's reviewed evidence corpus.

## Decision semantics

- `PreferredProductionCandidate-376` applies to reviewed AMD-published 376 production families when the remaining deployment gates pass.
- `ReviewRequired-376BinaryRecognitionWithoutPublishedFamilySupport` applies to Gorgon rows: binary recognition is evidence, but it is not AMD published-family production support.
- `NoNpuDriverRequired` applies where the reviewed CPU record establishes no bundled NPU.
- All provisional, unknown, conflicting, or incomplete mappings fail closed as `ReviewRequired`.
- Neither 280 nor 376 research inclusion alone authorizes installation.

## Reviewed counts

| Measure | Count |
|---|---:|
| AMD catalog rows | 742 |
| NPU candidate rows | 145 |
| AMD-official NPU present | 89 |
| AMD-official NPU absent | 14 |
| XDNA candidates | 42 |
| XDNA 2 candidates | 49 |
| Preferred 376 production candidates | 62 |
| Gorgon rows requiring published-support review | 27 |
| Formula errors | 0 |

## Workbook structure

1. `README`
2. `Summary`
3. `Evaluation Matrix`
4. `NPU Candidates`
5. `Raw AMD Catalog`
6. `Sources`
7. `Rules & Exceptions`
8. `Driver Lines`

## Validation

Before commit, verify that the workbook opens, all eight worksheets are present, the counts above are unchanged, no formula errors are reported, all user-facing assessment content is English, and the reviewed 280/376 hashes match `README.md` and `SOURCES.md`.

## Principal sources

- https://www.amd.com/en/products/specifications/processors.html
- https://en.wikipedia.org/wiki/List_of_AMD_processors
- https://en.wikipedia.org/wiki/Table_of_AMD_processors
- https://en.wikipedia.org/wiki/List_of_AMD_Ryzen_processors
- https://ryzenai.docs.amd.com/en/1.8/inst.html (version-pinned Ryzen AI 1.8)
- https://ryzenai.docs.amd.com/en/latest/inst.html (moving alias)
