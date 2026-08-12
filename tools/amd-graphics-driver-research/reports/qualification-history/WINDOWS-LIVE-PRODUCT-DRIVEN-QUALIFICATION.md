# AMD Graphics Driver Research Toolkit 0.6.1 — Windows Live Evidence Review

Date: 2026-08-11

## Reviewed evidence

- `AmdGraphicsDriverResearchEvidence_20260810-183455_Windows.zip`
- `AmdGraphicsDriverResearchEvidence_20260810-183524_Windows.zip`

Both runs used Toolkit 0.6.0 on Windows PowerShell 5.1.26100.8972 / Windows 10.0.26200.

## Preview run

Stages:

```text
ProductDiscover
ProductMetadata
Select
```

Result:

```text
PASS / exit 0
Elapsed: 1.45s
```

Observed live data:

```text
Products discovered: 3
Product groups: 3
Driver entries: 30
Unique driver URLs: 24
Track-generation selections: 14
Unique selected artifacts: 13
Estimated download: 11.80 GiB
```

Critical coverage observation:

- `https://www.amd.com/en.sitemap.xml` parsed but contributed **0** support product pages.
- `https://www.amd.com/sitemap.xml` returned HTML instead of XML.
- The resulting product catalog therefore consisted only of the three representative `seed-products.json` entries:
  - Radeon PRO W6400
  - Radeon RX 9070 XT
  - Ryzen 7 PRO 5755GE

The run was technically successful, but this is **not a complete AMD product catalog**.

## Full run

Stages:

```text
Test
ProductDiscover
ProductMetadata
Select
Acquire
Extract
Inspect
Build
```

Result:

```text
PASS / exit 0
Total elapsed: 31m32.6s
```

Stage timings:

```text
Test             0.555s
ProductDiscover  0.278s
ProductMetadata  0.207s
Select            0.045s
Acquire           27m23.747s
Extract           87.198s
Inspect           81.309s
Build             66.317s
```

Deep-analysis results:

```text
Downloaded artifacts: 13
INF-bearing extraction outputs: 13
INF package records: 230
```

The 13-artifact plan was operationally feasible on the test host, but it represents only the three seed product groups, not the full AMD graphics/iGPU product space.

## Defects / hardening requirements found

### P0 — Seed-only catalog could be mistaken for complete discovery

0.6.0 emitted `Completeness=BestEffortFromAmdSitemap` even though the sitemap contributed zero product pages.

0.6.1 changes this to explicit states:

```text
SitemapBackedBestEffort
SeedOnlyFallback
NoUsableProducts
```

When the catalog is `SeedOnlyFallback`, preview and selection may continue, but default `Acquire` fails closed unless the operator explicitly supplies additional product scope or uses `-AllowSeedOnlyProductDiscovery`.

### P0 — Windows Server OS track misclassification

The live mapping contained one concrete conflict:

```text
File:
amd-software-pro-edition-25.q3.1-winsvr2025-rdna.exe

Page-context track parsed by 0.6.0:
WindowsServer2016

Filename-implied track:
WindowsServer2025
```

0.6.1 adds filename-derived OS-track evidence for `winsvr2016/2019/2022/2025`, preserves both page and filename evidence, records conflicts, and uses the unambiguous server filename as the effective track.

### P1 — ProductName extraction was overly greedy

The Radeon PRO W6400 ProductName field captured large amounts of global AMD page-navigation text.

0.6.1 derives ProductName from the HTML `<title>` and strips the `Drivers and Downloads` suffix.

### P1 — Download-volume guard

0.6.0 had only an artifact-count guard. The live seed-backed selection was 13 artifacts / 11.80 GiB.

0.6.1 adds:

```text
-MaximumEstimatedDownloadGiB 32
```

with `0` meaning explicitly unlimited. This guard is evaluated before acquisition.

## Regression tests added

0.6.1 ProductDrivenSelectionSelfTest now covers:

- dGPU product URL classification;
- processor/iGPU product URL classification;
- Adrenalin product mapping;
- PRO Server mapping;
- Auto-Detect/minimal-setup exclusion;
- conflicting page-vs-filename Server OS evidence;
- product-name title parsing.

Final synthetic Test result:

```text
WindowsServerAnalysisSelfTest  PASS
InfIdentifierTaxonomySelfTest  PASS
GraphicsIdentitySelfTest       PASS
ProductDrivenSelectionSelfTest PASS
PowerShell AST errors          0
```

## Safety-guard qualification

Using the live 0.6.0 selection mapping as a fixture:

```text
MaximumEstimatedDownloadGiB=10
→ FAIL CLOSED before Acquire because estimate is 11.80 GiB

MaximumEstimatedDownloadGiB=32
→ PASS, 13 unique artifacts selected

SeedOnlyFallback + default Acquire
→ FAIL CLOSED before network download
```

## Final evaluation

The Windows PowerShell 5.1 run proves that the product-driven deep-analysis pipeline itself is operational: 13 artifacts were downloaded, statically extracted, inspected and built without INF parse failures terminating the run.

However, the live run also proves that AMD sitemap discovery cannot currently be treated as a complete product catalog source. Version 0.6.1 therefore changes the behavior from optimistic best-effort acquisition to explicit partial-catalog evidence plus fail-closed acquisition.

The remaining architectural task is a stronger AMD product-group discovery source (for example a stable AMD product-picker data source or a maintained product-group seed catalog). Until that is qualified, `SeedOnlyFallback` must not be described as complete AMD product coverage.
