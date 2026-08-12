# AMD Graphics Driver Research Toolkit 0.6.0 — Product-Driven Qualification

Date: 2026-08-11

## Qualification scope

This qualification validates the new product-driven selection layer without replacing the already-qualified 0.5.0 INF/Windows Server analysis model.

## 1. Source / syntax

```text
Toolkit version : 0.6.0
PowerShell AST errors : 0
Final script SHA-256 : 3170dc6ca9f3d632fff42c1d2571f3052b3c94f753da8e34bbaae6df5a64ee1b
Encoding             : UTF-8 BOM + CRLF
```

The final Test stage completed with:

```text
WindowsServerAnalysisSelfTest  : Pass
InfIdentifierTaxonomySelfTest  : Pass
GraphicsIdentitySelfTest       : Pass
ProductDrivenSelectionSelfTest : Pass
Final                          : Pass
Exit code                      : 0
```

Development runtime:

```text
Debian GNU/Linux 13
PowerShell 7.6.4
7-Zip 25.01
```

## 2. Product-driven synthetic parser tests

The in-script self-test covers:

- discrete Graphics support URL parsing;
- Processor/iGPU support URL parsing;
- full Adrenalin installer-card parsing;
- full PRO Windows Server installer-card parsing;
- Auto-Detect/minimal-setup exclusion.

Result: PASS.

Final Test evidence label:

```text
ProductDriven-0.6.0-ByteFinal-Test
```

## 3. Offline product mapping / selection fixture

Representative fixture products:

```text
Radeon RX 9000 Series / RX 9070 XT
Radeon PRO W6000 Series / W6400
Ryzen PRO 5000 Series / Ryzen 7 PRO 5755GE
```

Observed fixture result:

```text
Products                     : 3
Product groups               : 3
Driver entries               : 12
Track-generation selections  : 12
Unique selected AMD EXE URLs : 11
Estimated selected download  : 10.13 GiB
```

The 12-to-11 reduction confirms global many-product/track-to-one-EXE deduplication. A shared Adrenalin Main artifact referenced from more than one product group is selected once while retaining all referring groups/tracks in selection evidence.

Example selected major generations in the fixture:

```text
Ryzen PRO 5000 / Adrenalin PolarisVega:
  26 -> 26.5.2
  25 -> 25.8.1
  24 -> 24.12.1

Radeon PRO W6000 / PRO Server 2022:
  25 -> 25.Q3
  24 -> 24.Q4
  23 -> 23.Q4
```

The final byte-identical 0.6.0 script also replayed the cached fixture through `ProductMetadata,Select` with PASS / exit 0.

```text
Evidence label: ProductDriven-0.6.0-ByteFinal-OfflineFixture
```

The fixture is parser/selection qualification data only. It is not committed as an accepted AMD product baseline.

## 4. Schema validation

Fixture outputs validated against the new schemas:

```text
products.json                -> product-catalog.schema.json             PASS
product-driver-mapping.json  -> product-driver-mapping.schema.json      PASS
selection-plan.json          -> product-selection-plan.schema.json      PASS
```

## 5. Existing real-artifact regression

A retained real AMD artifact was used to verify that the new default selection layer does not regress local qualification:

```text
amd-software-pro-edition-26.q1-win11-vega-polaris.exe
```

0.6.0 final-byte local-only run:

```text
Evidence label: ProductDriven-0.6.0-ByteFinal-LocalRegression
```

0.6.0 local-only run:

```text
Test    PASS
Acquire PASS
Extract PASS
Inspect PASS
Build   PASS
Exit    0
```

Observed analysis remained:

```text
INF                : 14
INF parse failures : 0
KMDF-declaring INF : 4
UMDF-declaring INF : 0
```

This confirms the product-driven forward-port does not replace or bypass existing extraction / INF semantic / Windows Server analysis.

## 6. Live-web qualification status

The development container could not perform a live AMD end-to-end crawl because outbound access to AMD was unavailable.

Therefore:

```text
Official page structure research : completed separately against public AMD support pages
Synthetic parser/selection       : PASS
Existing real-artifact regression: PASS
Live ProductDiscover -> Acquire  : PENDING on network-enabled Windows/PowerShell environment
```

A Windows PowerShell 5.1 live product-driven run remains an important pre-GA gate.

## 7. Acceptance result

0.6.0 is suitable as the next **qualified development baseline** for product-driven selection, subject to live network qualification.

It is not yet GA / accepted historical baseline.


## Windows PowerShell 5.1 live qualification — 2026-08-11

Two user-supplied evidence runs were reviewed. The preview run (`ProductDiscover,ProductMetadata,Select`) passed in 1.45 seconds. The full run passed all eight stages in 31m32.6s, acquired 13 artifacts, reached INF-bearing extraction for all 13, and produced 230 INF package records.

The evidence also exposed two hardening requirements. First, AMD sitemap discovery contributed zero support product pages, so only three representative seeds were cataloged; 0.6.1 marks this as `SeedOnlyFallback` and blocks default Acquire unless explicitly overridden. Second, one server artifact named `amd-software-pro-edition-25.q3.1-winsvr2025-rdna.exe` was associated with the Windows Server 2016 page context by the HTML parser. 0.6.1 preserves both page and filename OS evidence and uses the unambiguous server filename as the effective track while recording the conflict.

The observed seed-backed selection contained 14 track-generation selections, 13 unique AMD EXEs, and an estimated published download size of 11.80 GiB. This remains a representative qualification set, not a complete AMD product catalog.
