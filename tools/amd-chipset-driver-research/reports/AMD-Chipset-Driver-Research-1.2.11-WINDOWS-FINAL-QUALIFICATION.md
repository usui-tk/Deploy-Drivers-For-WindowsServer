# AMD Chipset Driver Research Toolkit 1.2.11 — Windows Final Qualification

Date: 2026-08-11 JST  
Development line: `1.2.11-qt-dev`  
Validated live input: `AmdChipsetDriverResearchEvidence_20260811-053408_Windows.zip`

## Result

The 1.2.10 Windows rerun closes the remaining Windows release-quality gate.

- Windows 11 Pro, build 26200
- Windows PowerShell 5.1.26100.8972
- 7-Zip 26.02 available
- Test / Discover / Metadata / Acquire / Extract / Inspect / Selector / HostSurvey / HostMatch / Build: PASS
- OverallStatus: `Pass`
- ExitCode: `0`
- Runtime: about 21 minutes

## MSI declarative analysis

All 25 recovered AMD chipset MSI databases report `ParsedReadOnly`.

- Parsed: 25 / 25
- ParseFailed: 0
- ParsedWithErrors: 0
- MSI errors: 0
- Selected table rows: 13,993
- All-null rows: 0

This live result confirms both the 1.2.9 COM adapter repair and the 1.2.10 row-pipeline isolation repair.

## Self-tests

`SelfTestsReady=True`.

All readiness tests PASS:

- CompiledSelectorContract
- HostArchitectureNormalization
- MsiTableNameProjection
- MsiFieldCountIndependentColumnDiscovery
- MsiTableRowPipelineIsolation
- MsiDeclarativeAssessment

The normal transcript contains no terminating-error marker.

## Host regression

The localized Windows architecture remains correctly normalized:

- CIM display value: `64 ビット`
- normalized architecture: `x86_64`

For 8.07.16.1035 the Windows 11 host analysis retains:

- selector candidates: 6
- `UnknownAmdFilterCount`: 0

No selector predicate or host-selection regression was detected.

## 1.2.11 hardening

No functional defect was found in the supplied 1.2.10 rerun. 1.2.11 therefore adds defense-in-depth only.

Each Windows MSI declarative result now records a `Quality` object:

- `TableCount`
- `TotalRowCount`
- `AllNullRowCount`
- `ErrorCount`

An all-null row is treated as evidence contamination. The parser records an error and changes the MSI status to `ParsedWithErrors`; final assessment also independently checks successful `Parsed` / `ParsedReadOnly` evidence and forces `REVIEW` if all-null rows exist.

The MSI assessment self-test now contains a deliberately contaminated success case and requires it to become `REVIEW`.

## Boundary

This checkpoint does not change:

- AMD release identity
- exact-binary compiled selector contracts
- 3.x–8.x predicate evidence
- 2.x evidence boundary
- INF semantic interpretation
- WDF scope
- host candidate-selection rules

`1.0.0` remains the accepted baseline. `1.2.11-qt-dev` remains a development preview pending GitHub pre-commit/release review.
