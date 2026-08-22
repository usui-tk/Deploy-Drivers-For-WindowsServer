# AMD NPU Driver Research — Authored Records Index

The top-level documentation describes the current `3.0.0` research
contract while preserving the accepted v1.0.0 publication baseline. This
directory holds **authored** records: design and qualification narratives
written by a person or a model, reviewed, and committed. It exists so that the
authored/generated boundary is visible in the directory tree rather than
maintained as a list of file names in `.gitignore`.

The counterpart directories are:

| Directory | Written by | Committed |
| --- | --- | --- |
| `authored/**` | a person or a model | yes, after review |
| `public/**` | the toolkit | yes, per `PUBLICATION-POLICY.md` |
| `reports/**`, `inventory/**`, `work/**`, `private/**` | the toolkit at run time | no |

## Current contents

This toolkit reached v1.0.0 with its design and qualification narratives held in
the tool top directory (`README.md`, `SPEC.md`, `TESTING.md`,
`REVERSE-ENGINEERING-NOTES.md`, `SOURCES.md`, `ARCHITECTURE-PARITY.md`). The
directory now also contains the following reviewed assessment artifacts:

- `AMD-CPU-NPU-Evaluation-Matrix-2026-08-16_rev2.xlsx` — English CPU/NPU and driver-line evaluation workbook.
- `AMD-CPU-NPU-EVALUATION-MATRIX.md` — provenance, interpretation, and validation record for the workbook.
- `HARDWARE-ONLY-DRIVER-SELECTION-DECISION-2026-08-16.md` — user-adjudicated record that PnP/INF identity, not CPU or CPU/NPU mapping, is the driver-track authority; 376 is preferred and 280 has no automatic fallback.
- `NPU-LIVE-PUBLICATION-DRIFT-2026-08-21.md` — retains the REV65 link while
  recording its correction: AMD's authoritative `latest` page identifies
  Ryzen AI Software 1.8.0 and driver 376 as the production-family line.

New one-off qualification or reverse-engineering narratives SHOULD be placed
here rather than added to the tool top directory, and never under `reports/**`,
which is script-generated runtime staging and is ignored in its entirety.
