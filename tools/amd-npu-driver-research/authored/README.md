# AMD NPU Driver Research — Authored Records Index

The top-level documentation describes the stable v1.0.0 contract. This
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
`REVERSE-ENGINEERING-NOTES.md`, `SOURCES.md`, `ARCHITECTURE-PARITY.md`) rather
than as separate one-off records, so this directory is currently empty apart
from this index.

New one-off qualification or reverse-engineering narratives SHOULD be placed
here rather than added to the tool top directory, and never under `reports/**`,
which is script-generated runtime staging and is ignored in its entirety.
