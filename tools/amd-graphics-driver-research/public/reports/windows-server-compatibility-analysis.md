# Windows Server Static Applicability Analysis

As-published INF selection and virtual Server projection are separate. Runtime compatibility is not established.

| Server | Native | Patch candidate | Review | Not applicable | Indeterminate |
|---|---:|---:|---:|---:|---:|
| Windows Server 2016 | 200 | 7 | 7 | 268 | 0 |
| Windows Server 2019 | 392 | 17 | 27 | 46 | 0 |
| Windows Server 2022 | 424 | 21 | 0 | 37 | 0 |
| Windows Server 2025 | 452 | 21 | 9 | 0 | 0 |

- NATIVE_CANDIDATE: selected as-published Models section is native to the Server profile and WDF is within documented references.
- PATCH_CANDIDATE: only the virtual ProductType=1→3 projection reaches a Models section; no file is modified.
- REVIEW_REQUIRED: SuiteMask, WDF reference, or another static condition requires review.
- NOT_APPLICABLE: target/build/product type/explicit empty-section evidence does not produce a candidate.
- Runtime validation remains mandatory.
