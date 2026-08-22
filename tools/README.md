# Repository tools

This directory contains standalone research, evidence, reconciliation, and
shared analysis assets that support `Deploy-Drivers-For-WindowsServer`. These
tools inform the deployment and driver-build design, but they are not part of
the production deployment pipeline unless a separate reviewed change explicitly
integrates them.

## Tool list

| Directory | Purpose | Current release relationship |
| --- | --- | --- |
| `amd-chipset-driver-research/` | Research AMD Ryzen chipset releases, installer/package structure, INF applicability, signatures, and Windows Server compatibility. | Coordinated research toolkit `3.0.0` |
| `amd-graphics-driver-research/` | Research AMD graphics product groups, driver packages, INF/device applicability, signatures, and Windows Server compatibility. | Coordinated research toolkit `3.0.0` |
| `amd-npu-driver-research/` | Research Ryzen AI/NPU packages, hardware-only selection, installer/binary contracts, and Windows Client/Server applicability. Includes a separate hardware-identity evidence collector under its nested `tools/` directory. | Coordinated research toolkit `3.0.0` |
| `inventory-reconciliation/` | Compare research-tool inventory with deployment-pipeline inventory without merging the two responsibilities. | Existing repository utility; maintained independently |
| `source-fragments/` | Hold reviewed source fragments shared by repository-side implementation work. | Existing repository asset; maintained independently |

Each independent tool family uses one second-level directory:

```text
tools/<tool-name>/
```

## Research-tool directory contract

The three AMD research toolkits follow the repository's authored/generated
separation:

- the tool top level, `authored/**`, `data/**`, and `schemas/**` are reviewed
  source content;
- `public/**` is the only toolkit-generated commit surface and must satisfy the
  toolkit's `PUBLICATION-POLICY.md` and publication manifest;
- `inventory/**`, `private/**`, `reports/**`, and `work/**` are runtime or
  evidence staging and are not committed beyond repository-maintained
  `.gitkeep` placeholders;
- vendor packages and private Evidence archives are not repository content.

Generated `public/**` files must not be hand-edited. Correct the generator or
reviewed source data, regenerate the complete public surface, and validate its
manifest before committing it.

PowerShell tools aggregate executable logic into a single root `.ps1` whenever
practical. A separately reviewed companion tool may live under the owning
toolkit's nested `tools/` directory.

## Candidate-application boundary

A toolkit candidate is applied as an explicit repository-relative patch set,
not as a mirror of the entire `tools/` directory. Files and directories absent
from a candidate are preserved unless an independently reviewed operation
manifest explicitly authorizes their deletion.

Dotfiles under `tools/`—including `.gitignore` and `.gitkeep`—are maintained on
the repository side and are not overwritten from a toolkit candidate. A needed
dotfile change must be raised and reviewed as a separate repository request.

`project-management/**` and `preview/**` in a review bundle are audit and
handover material. They are not GitHub commit surfaces for this repository.
