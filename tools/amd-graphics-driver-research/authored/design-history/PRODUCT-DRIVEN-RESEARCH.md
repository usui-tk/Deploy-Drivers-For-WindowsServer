# AMD Graphics Driver Research Toolkit 0.7.0 — Product-Driven Research Design

Date: 2026-08-11

## 1. Purpose

Version 0.7.0 retains the product-driven research model introduced in 0.6.0, but replaces the unusable sitemap-dependent default with a **versioned curated product-group research scope** based on AMD official support pages.

The motivating operational requirement is:

1. retain broad visibility into AMD's published graphics-driver history;
2. do not download and extract every historical release by default;
3. identify the driver installer artifacts AMD actually associates with a graphics product/product group;
4. retain distinct dGPU, professional-GPU and processor/iGPU publication paths;
5. deep-analyze only a bounded representative history: the newest release in each of the newest three available major generations per product-driver track;
6. download/analyze one EXE once even when many AMD product pages point to the same artifact.

The existing INF / Windows Server / WDF analysis model remains unchanged.

## 2. Official AMD support structure observed during design

Representative AMD support pages used to establish the product-driven model:

- AMD Drivers & Support entry:
  `https://www.amd.com/en/support/download/drivers.html`
- Radeon RX 9070 XT (discrete Graphics tree):
  `https://www.amd.com/en/support/downloads/drivers.html/graphics/radeon-rx/radeon-rx-9000-series/amd-radeon-rx-9070-xt.html`
- Radeon RX 9070 XT Previous Drivers:
  `https://www.amd.com/en/support/downloads/previous-drivers.html/graphics/radeon-rx/radeon-rx-9000-series/amd-radeon-rx-9070-xt.html`
- Radeon PRO W6400 (professional Graphics tree, multiple client/server tracks):
  `https://www.amd.com/en/support/downloads/drivers.html/graphics/radeon-pro/radeon-pro-w6000-series/amd-radeon-pro-w6400.html`
- Radeon PRO W6400 Previous Drivers:
  `https://www.amd.com/en/support/downloads/previous-drivers.html/graphics/radeon-pro/radeon-pro-w6000-series/amd-radeon-pro-w6400.html`
- Ryzen 7 PRO 5755GE (Processor tree exposing integrated Radeon graphics driver):
  `https://www.amd.com/en/support/downloads/drivers.html/processors/ryzen-pro/ryzen-pro-5000-series/amd-ryzen-7-pro-5755ge.html`
- Ryzen 7 PRO 5755GE Previous Drivers:
  `https://www.amd.com/en/support/downloads/previous-drivers.html/processors/ryzen-pro/ryzen-pro-5000-series/amd-ryzen-7-pro-5755ge.html`

The design therefore MUST NOT assume that graphics-driver products exist only below AMD's `Graphics` selector. Processor support pages can expose the relevant integrated Radeon graphics artifact.

The design also MUST NOT assume one product maps to one driver track. A professional product can expose different client and Windows Server tracks and can expose PRO Edition and Adrenalin packages on the same product page.

## 3. Data model

### 3.1 ProductKey

Derived from the AMD support URL hierarchy:

```text
RootCategory | ProductFamilySlug | ProductLineSlug | ProductModelSlug
```

Example:

```text
processors|ryzen-pro|ryzen-pro-5000-series|amd-ryzen-7-pro-5755ge
```

### 3.2 ProductGroupKey

```text
RootCategory | ProductFamilySlug | ProductLineSlug
```

Examples:

```text
graphics|radeon-rx|radeon-rx-9000-series
graphics|radeon-pro|radeon-pro-w6000-series
processors|ryzen-pro|ryzen-pro-5000-series
```

The ProductGroupKey is the user-facing grouping unit for bounded historical selection.

### 3.3 DriverTrackKey and SelectionTrackKey

Raw artifact provenance remains:

```text
DriverTrackKey = ProductGroupKey | OperatingSystemTrack | PackageFamily | ArtifactRole
```

Historical three-generation selection uses the more stable lineage:

```text
SelectionTrackKey = ProductGroupKey | OperatingSystemTrack | PackageFamily
```

Examples:

```text
graphics|radeon-rx|radeon-rx-9000-series|WindowsClient|Adrenalin|Main
processors|ryzen-pro|ryzen-pro-5000-series|WindowsClient|Adrenalin|PolarisVega
graphics|radeon-pro|radeon-pro-w6000-series|WindowsServer2022|ProEdition|WindowsServer-PolarisVega
```

A product group may expose multiple raw DriverTrackKey values. `ArtifactRole` remains canonical evidence, but does not split historical generation selection because AMD role labels can change between releases.

### 3.4 Artifact relation

Product mappings retain the direct AMD EXE URL. The relationship is many-to-one:

```text
Product A ----\
Product B -----+--> AMD EXE X
Product C ----/
```

The direct AMD EXE URL is used only as the **global selection deduplication key**. Product and track references are not discarded.

## 4. Major-generation selection

The normal selection rule is intentionally simple.

For each SelectionTrackKey:

1. parse each release into a numeric major generation;
2. sort available major generations newest-first;
3. keep the newest `MajorGenerationCount` generations (default `3`);
4. inside each retained major generation select the newest release using numeric release ordering;
5. if a generation is absent for a track, do not synthesize it from another track;
6. globally deduplicate the selected set by AMD EXE URL.

Examples:

```text
Adrenalin 26.7.1 -> major generation 26
Adrenalin 25.12.1 -> major generation 25
PRO 25.Q4 -> major generation 25
PRO 25.Q3.1 -> major generation 25
```

For PRO Edition, quarter/revision ordering is numeric. `25.Q4` is newer than `25.Q3.1` because quarter 4 is newer than quarter 3; within Q3, `25.Q3.1` is newer than `25.Q3`.

This model deliberately does not attempt compatibility-driven recursive fallback selection. Windows Server applicability is evaluated **after** bounded artifact selection by the existing static analysis layer.

## 5. Stage model

Default no-switch workflow:

```text
Test
  -> ProductDiscover
  -> ProductMetadata
  -> Select
  -> Acquire
  -> Extract
  -> Inspect
  -> Build
```

Legacy historical workflow remains explicitly available:

```text
-FullHistoricalResearch
```

or explicit release identity filters:

```text
-ReleaseVersion
-ReleaseKey
```

Local installer qualification remains independent of both discovery models.

## 6. ProductDiscover

Default source:

1. versioned `data/seed-products.json` curated product-group catalog;
2. `-AdditionalProductPageUrl` supplied by the operator.

The curated catalog uses one AMD official support page as a representative entry point for each explicitly declared product group. It is a **research-scope catalog**, not a claim that every AMD product model is enumerated. AMD sitemap product discovery remains only a legacy/custom-seed fallback because Windows qualification showed the sitemap contributing zero support-product pages.

Accepted canonical product support paths begin under:

```text
.../drivers.html/graphics/...
.../drivers.html/processors/...
```

The stage records product/group identity only. It does not acquire AMD installers.

Output:

```text
inventory/products.json
```

Schemas:

```text
amd-graphics-product-group-catalog/2.1   # versioned declared scope
amd-graphics-product-catalog/2.0         # run-time catalog output
```

## 7. ProductMetadata

For each product it preserves the current product support page and the corresponding Previous Drivers page where applicable.

Published fields remain separate evidence:

```text
PublishedOsLabel
DriverTitle
ReleaseVersion
ReleaseQuality
FileSizeText
ReleaseDateText
DownloadUrl
SourcePageKind
SourcePageUrl
```

This separation is important because page OS headings, textual descriptions and filenames can provide different or partially inconsistent wording.

The parser excludes artifacts that are not canonical full graphics-driver installers, including Auto-Detect/minimal-setup utilities and unrelated FSR preview packages.

Outputs:

```text
inventory/product-driver-mapping.json
inventory/product-groups.json
```

## 8. Select

Outputs:

```text
inventory/selection-plan.json
inventory/selected-release-metadata.json
```

The selection plan records:

- selected ProductGroup/SelectionTrack plus raw DriverTrack/ArtifactRole provenance;
- major generation;
- selected release version;
- reason (`LatestReleaseInMajorGeneration`);
- direct EXE URL;
- globally deduplicated artifact set;
- best-effort published download-size estimate.

Safety control:

```text
MaximumSelectedArtifactCount = 32 (default)
MaximumEstimatedDownloadGiB = 32 (default)
```

If the unique selected artifact count exceeds the cap, selection fails before Acquire. `0` explicitly disables the cap.

A zero-selection result also fails closed.

## 9. Existing research semantics retained

0.7.0 does not weaken the 0.5.0 semantic-analysis model or the qualified 0.6.x deep-analysis engine.

Still retained:

```text
ArtifactKey 1:1 canonical raw JSON
Manufacturer -> TargetOSVersion -> Models -> identifier topology
amd-inf-semantic-contract/1.0
amd-inf-identifier-taxonomy/1.0
amd-inf-topology/1.1
AsPublished vs ServerProjection
WdfScope = InfWideConservative
RuntimeCompatibility = NotEstablished
```

Product-driven selection only controls **which artifacts enter deep analysis**.

## 10. 0.7.0 curated product-group catalog and boundaries

The default product-driven workflow uses `data/seed-products.json` as a versioned curated research-scope catalog. The current catalog declares `CatalogKind=CuratedProductGroups`, `CatalogVersion=2026-08-11.1`, and `CoveragePolicy=RepresentativeProductPerProductGroup`. Each entry is one AMD official support page representing an explicitly declared product group.

The default scope contains 21 representative current/recent Radeon dGPU/professional and Ryzen/Ryzen PRO integrated-graphics product groups. Legacy Radeon R9/R7/R5, Radeon HD, FirePro, mobile-only professional groups and embedded graphics are excluded unless explicitly added. This scope can be expanded in later catalog versions without changing the selection algorithm.

Important boundaries:

- `CanClaimFullProductCatalog=false`: the catalog does not claim to enumerate every AMD product model.
- ProductMetadata must successfully evaluate each representative current page and Previous Drivers page; otherwise `MetadataCompleteness=Partial` and default Acquire is BLOCKED so a partial three-generation baseline is never silently accepted.
- Server-specific installer filenames (`winsvr2016/2019/2022/2025`) are high-confidence OS-track evidence when page-context parsing disagrees; both signals and the conflict remain evidence.
- A Processor product is not assumed to have usable graphics-driver history until ProductMetadata observes graphics-driver entries.
- Product-page publication proves AMD product-to-artifact association, not Windows Server runtime compatibility.
- The isolated development container cannot complete the final AMD live-web 0.7.0 qualification; the Windows PowerShell 5.1 preview rerun is the acceptance gate for current/previous-page reachability and selected artifact volume.
- Full historical release research remains explicit opt-in because it can consume very large network/storage resources.
