# AMD Chipset Driver Research 1.2.7 Qt Development Validation

Validation date: 2026-08-11 JST  
Development line: `1.2.7-qt-dev`  
Accepted historical baseline: `1.0.0` (unchanged)

## Scope

This checkpoint extends reverse-chronological selector analysis from the frozen 6.x/7.x/8.x results through representative 5.x, 4.x and 3.x releases. The representative set is:

- 3.10.08.506
- 4.08.09.2337
- 5.08.02.027
- 6.10.17.152
- 7.11.26.2142
- 8.07.16.1035

2.04.04.111 is not binary-reversed in this checkpoint because its canonical archive was not available in the supplied/recovered artifact set.

## Main findings

3.x through 6.x form the same broad selector generation: PE32 x86, Qt5, Client-only Win10/11 `Info.xml`, one byte-identical APS XML, no recovered `DevID.xml`, and an internal unmatched OS-family value of `3`. 7.x is the observed boundary to x64/Qt6/DevID.xml and unmatched enum `-1`.

Exact selector contracts were added for 3.x, 4.x and 5.x. They are intentionally partial: `HostOsDetection` and `InfoXmlFilter` are `AmdCompiledStaticProven`; `/SETFILTERUSB` and `/SETRYZENPPKG` remain `Unresolved`. No 7.x/8.x hardware predicate is projected backward.

The precheck also corrected a metadata/static-string representation defect: `root\\cimv2` in prior contract metadata is normalized to the actual WMI namespace literal `root\cimv2`. 6.x/7.x/8.x selector outputs are otherwise normalized-equal to the 1.2.6 golden data.

## Pipeline results

| Release | Test | Extract | Inspect | Selector | Build | INF | Parse failures |
|---|---|---|---|---|---|---:|---:|
| 3.10.08.506 | PASS | PASS | PASS | PASS | PASS | 16 | 0 |
| 4.08.09.2337 | PASS | PASS | PASS | PASS | PASS | 24 | 0 |
| 5.08.02.027 | PASS | PASS | PASS | PASS | PASS | 27 | 0 |
| 6.10.17.152 | PASS | PASS | PASS | PASS | PASS | 28 | 0 |
| 7.11.26.2142 | PASS | PASS | PASS | PASS | PASS | 31 | 0 |
| 8.07.16.1035 | PASS | PASS | PASS | PASS | PASS | 31 | 0 |

## Schema / contract validation

```text
AMD Chipset Driver Research 1.2.7 validation
3x_amd-selector-static.json_SCHEMA_ERRORS=0
3x_embedded-installer-metadata.json_SCHEMA_ERRORS=0
3x_driver-packages.json_SCHEMA_ERRORS=0
3x_RELEASE_SCHEMA_ERRORS=0
3x_CONTRACT_MATCH=True
3x_WMI_NAMESPACE='root\\cimv2'
3x_PARTIAL_BOUNDARY=True
4x_amd-selector-static.json_SCHEMA_ERRORS=0
4x_embedded-installer-metadata.json_SCHEMA_ERRORS=0
4x_driver-packages.json_SCHEMA_ERRORS=0
4x_RELEASE_SCHEMA_ERRORS=0
4x_CONTRACT_MATCH=True
4x_WMI_NAMESPACE='root\\cimv2'
4x_PARTIAL_BOUNDARY=True
5x_amd-selector-static.json_SCHEMA_ERRORS=0
5x_embedded-installer-metadata.json_SCHEMA_ERRORS=0
5x_driver-packages.json_SCHEMA_ERRORS=0
5x_RELEASE_SCHEMA_ERRORS=0
5x_CONTRACT_MATCH=True
5x_WMI_NAMESPACE='root\\cimv2'
5x_PARTIAL_BOUNDARY=True
6x_amd-selector-static.json_SCHEMA_ERRORS=0
6x_embedded-installer-metadata.json_SCHEMA_ERRORS=0
6x_driver-packages.json_SCHEMA_ERRORS=0
6x_RELEASE_SCHEMA_ERRORS=0
6x_CONTRACT_MATCH=True
6x_WMI_NAMESPACE='root\\cimv2'
6x_PARTIAL_BOUNDARY=True
7x_amd-selector-static.json_SCHEMA_ERRORS=0
7x_embedded-installer-metadata.json_SCHEMA_ERRORS=0
7x_driver-packages.json_SCHEMA_ERRORS=0
7x_RELEASE_SCHEMA_ERRORS=0
7x_CONTRACT_MATCH=True
7x_WMI_NAMESPACE='root\\cimv2'
7x_HARDWARE_RULES=True
8x_amd-selector-static.json_SCHEMA_ERRORS=0
8x_embedded-installer-metadata.json_SCHEMA_ERRORS=0
8x_driver-packages.json_SCHEMA_ERRORS=0
8x_RELEASE_SCHEMA_ERRORS=0
8x_CONTRACT_MATCH=True
8x_WMI_NAMESPACE='root\\cimv2'
8x_HARDWARE_RULES=True
8x_HOST_FIXTURE_SCHEMA_ERRORS=0
6x_126_NORMALIZED_REGRESSION_MATCH=True
7x_126_NORMALIZED_REGRESSION_MATCH=True
8x_126_NORMALIZED_REGRESSION_MATCH=True
CANONICAL_MNT_DATA_LEAKS=0
TOTAL_VALIDATION_ERRORS=0
```

## Evidence boundary

- 3.x-6.x: OS/XML compiled contract proven; hardware filter predicates unresolved.
- 7.x: OS/XML + known FILTERUSB/RYZENPPKG compiled predicates proven; no live-host fixture supplied.
- 8.x: same compiled predicate class plus existing Windows 11 / Server 2022 / Server 2025 dynamic fixtures.
- 2.x: unresolved; no binary topology claim.

## Release decision

`1.2.7-qt-dev` is suitable as a **development checkpoint / preview**, not as a GA promotion. The accepted `1.0.0` baseline remains unchanged. A future 2.x investigation must begin from the canonical artifact and may not infer topology from 3.x.
