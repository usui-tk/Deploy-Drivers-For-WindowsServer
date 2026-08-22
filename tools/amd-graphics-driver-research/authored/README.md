# AMD Graphics Driver Research — Authored Records Index

The top-level documentation describes the stable v1.0.0 contract. This directory
retains the authored development and qualification records that explain **how**
specific behaviors were discovered and validated.

This directory holds **authored** records: design and qualification narratives
written by a person or a model, reviewed, and committed. It exists so that the
authored/generated boundary is visible in the directory tree rather than
maintained as a list of file names in `.gitignore`.

The counterpart directories are:

| Directory | Written by | Committed |
| --- | --- | --- |
| `authored/**` | a person or a model | yes, after review |
| `public/**` | the toolkit | yes, per `PUBLICATION-POLICY.md` |
| `reports/**`, `inventory/**`, `work/**`, `private/**` | the toolkit at run time | no |


These reports are evidence/history, not the normative specification. Use:

- `../README.md` for the current entry point;
- `../SPEC.md` for normative behavior;
- `../TESTING.md` for current release gates;
- `../RESEARCH-NOTES.md` for consolidated engineering knowledge.

## Current report layout

### Active implementation plans

| Report | Topic |
|---|---|
| `GRAPHICS-SIGNATURE-AND-COMMON-HARDENING-PLAN-2026-08-17.md` | Cross-tool gap assessment, newest-generation-per-track certificate scope, installer de-duplication, G0–G4 implementation result and remaining Windows qualification gates |

### Versioned hardening reports

| Report | Topic |
|---|---|
| `0.7.1-WINDOWS-BUILD-OOM-HARDENING.md` | Memory-bounded Build hardening |
| `0.7.2-WINDOWS-FULL-RUN-HARDENING.md` | Windows full-run storage/integrity hardening |
| `0.7.3-WINDOWS-SUMMARY-HARDENING.md` | Final assessment / summary correction |
| `0.7.4-WINDOWS-FULL-RUN-HARDENING.md` | Artifact-chain qualification |
| `0.8.1-WINDOWS-METADATA-FETCH-HARDENING.md` | AMD product-page retry/fallback hardening |
| `0.8.2-WINDOWS-PUBLICATION-PORTABILITY-HARDENING.md` | Cross-platform publication manifest/portability |
| `1.1.2-WINDOWS-PATH-SAFETY-AND-NATIVE-REUSE-CORRECTION.md` | SignTool MAX_PATH evidence, fail-closed path gate, short aliases and limited native-only reuse correction |

### Real-artifact comparison

| Report | Topic |
|---|---|
| `PRO-26Q1-WIN11-vs-SERVER2022-VEGA-POLARIS.md` | Windows 11 versus AMD-native Server 2022 Vega/Polaris control comparison |

### `qualification-history/`

| Report | Topic |
|---|---|
| `REAL-ARTIFACT-QUALIFICATION.md` | Adrenalin/PRO real-artifact extraction and package observations |
| `PRODUCT-DRIVEN-QUALIFICATION.md` | Product-driven selection/parser qualification |
| `WINDOWS-LIVE-PRODUCT-DRIVEN-QUALIFICATION.md` | Windows live product-driven run review |
| `0.7.0-WINDOWS-RERUN-AND-PRODUCT-GROUP-HARDENING.md` | Curated product-group / rerun hardening |
| `SEMANTIC-SYNC-QUALIFICATION.md` | Shared INF semantic contract qualification |
| `PRO-26Q1-WIN11-VEGA-POLARIS-QUALIFICATION.md` | PRO 26.Q1 Windows 11 Vega/Polaris control |

### `design-history/`

| Report | Topic |
|---|---|
| `PRODUCT-DRIVEN-RESEARCH.md` | Original product-driven data model and selection design |
| `INF-ANALYSIS-SYNC.md` | Graphics/Chipset INF semantic synchronization note |
| `PUBLICATION-POLICY-HISTORY.md` | Earlier standalone publication-policy evolution |

## Consolidated duplicate

The former top-level files:

```text
CURATED-PRODUCT-GROUP-QUALIFICATION.md
WINDOWS-RERUN-HARDENING.md
```

were byte-for-byte identical (same SHA-256). They are retained once as:

```text
qualification-history/0.7.0-WINDOWS-RERUN-AND-PRODUCT-GROUP-HARDENING.md
```

No historical content was lost by removing the duplicate copy.

## Historical-report policy

Historical reports MAY retain development-version terminology, superseded file locations or context that was true at the time of qualification.

They SHOULD NOT be used as the current operational contract when they conflict with top-level v1.0.0 documentation.

New one-off qualification reports SHOULD normally be placed under `authored/**` rather than added to the tool top directory.
