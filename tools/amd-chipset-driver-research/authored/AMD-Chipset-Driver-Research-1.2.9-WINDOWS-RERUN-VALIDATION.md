# AMD Chipset Driver Research Toolkit 1.2.9 Windows Rerun Validation

Date: 2026-08-11 JST

## Scope

This report reviews the user-provided Windows evidence archive:

`AmdChipsetDriverResearchEvidence_20260811-023713_Windows.zip`

SHA-256:

`502e5d40d4a5787c18099000b37acea6327b66e5dc6e846a497e6670d32bbd93`

The run used toolkit `1.2.8-qt-dev` with script SHA-256:

`43b574ad7356dc2bf645c63034e7c8f62efdac91b8c9280420976f82de1b39d2`

## Host and runtime

- Windows 11 Pro
- Build 26200
- Windows PowerShell 5.1.26100.8972 / Desktop edition
- CIM `OSArchitecture`: `64 ビット`
- normalized architecture: `x86_64`
- 7-Zip: available (`C:\Program Files\7-Zip\7z.exe`)
- archive capability probe: PASS

## 1.2.8 fixes confirmed by live rerun

All ten selected stages completed with PASS:

- Test
- Discover
- Metadata
- Acquire
- Extract
- Inspect
- Selector
- HostSurvey
- HostMatch
- Build

Final run status was `Pass`, exit code 0.

The run produced:

- 25 available installer artifacts;
- 25 releases with complete INF-bearing extraction;
- 643 INF package records;
- zero INF parse failures in the per-release console summaries.

The localized architecture fix is live-confirmed: Japanese `64 ビット` is normalized to `x86_64`. For 8.07.16.1035 the Windows 11 host analysis produced six selected selector candidates and `UnknownAmdFilterCount=0`, consistent with the intended 1.2.8 replay behavior.

## Remaining defect discovered

The Windows Installer COM repair in 1.2.8 is incomplete.

All 25 releases reported:

`MsiDeclarativeAnalysis.Status = ParseFailed`

The repeated runtime error is:

`Get-AmdMsiTableRows: property 'FieldCount' cannot be found`

The failure occurs after the earlier `_Tables.Name` projection issue was avoided. The new failure is specifically the direct access to `Record.FieldCount` in `Get-AmdMsiTableRows`.

Because the Selector stage still generated useful XML/binary selector evidence, the stage itself remained PASS. However, 1.2.8 final assessment did not inspect MSI declarative status, so the overall result remained `Pass` despite 25/25 MSI analyses failing. This is a second robustness issue: partial selector analysis failure was not surfaced in final assessment.

## 1.2.9 correction

The 1.2.9 development source removes the direct `Record.FieldCount` dependency.

The new MSI read path:

1. obtains `View.ColumnInfo`;
2. reads indexed `Record.StringData` fields sequentially;
3. stops at the end-of-fields signal;
4. uses a bounded 128-column safety limit;
5. provides reflection/IDispatch fallback paths for `Record.StringData`, `View.ColumnInfo`, and `View.Fetch` when normal PowerShell COM adaptation does not expose them consistently.

A new self-test, `MsiFieldCountIndependentColumnDiscoverySelfTest`, constructs a record with indexed `StringData` but intentionally no `FieldCount` property and verifies successful two-column discovery.

The final assessment is also hardened. When the Selector stage passes, `amd-selector-static.json` is inspected. If any release has `MsiDeclarativeAnalysis.Status=ParseFailed`, the assessment adds:

`MsiDeclarativeInspection = REVIEW`

and the final result becomes `ReviewRequired` instead of `Pass`.

MSI declarative inspection remains supplemental: a ParseFailed result does not erase otherwise valid Info.xml, DevID.xml, selector-binary, INF, or host evidence.

## Microsoft Windows Installer API basis

The implementation follows the Windows Installer Automation model documented by Microsoft:

- `Record.FieldCount` is a Record property, but 1.2.9 no longer requires PowerShell to expose it directly.
- `Record.StringData` is an indexed Record property used to retrieve a field's string value.
- `View.ColumnInfo` returns a Record containing one field per nonconstant result column and can return column names.

References:

- https://learn.microsoft.com/en-us/windows/win32/msi/record-fieldcount
- https://learn.microsoft.com/en-us/windows/win32/msi/record-stringdata
- https://learn.microsoft.com/en-us/windows/win32/msi/view-columninfo
- https://learn.microsoft.com/en-us/windows/win32/msi/about-the-automation-interface

## Validation completed in the development environment

- PowerShell 7.6.4 AST parse: 0 errors.
- Test stage: PASS.
- Compiled selector contract self-test: PASS.
- Host architecture normalization self-test: PASS.
- MSI table-name projection self-test: PASS.
- MSI FieldCount-independent column-discovery self-test: PASS.
- MSI declarative assessment self-test: PASS.
- Script remains UTF-8 BOM + CRLF.

## Remaining gate

Actual Windows Installer COM end-to-end validation of the new 1.2.9 path cannot be completed on the Linux development host. One Windows rerun with 7-Zip available is still required.

Success criteria for that rerun:

1. no `FieldCount` error in the transcript;
2. no PowerShell COM-member error from `StringData`, `ColumnInfo`, or `Fetch`;
3. recovered MSI releases report `MsiDeclarativeAnalysis.Status=Parsed` where the tables are readable;
4. `MsiDeclarativeInspection` is PASS;
5. final result remains Pass if no other review condition exists.

## Release status

`1.2.9-qt-dev` remains a development preview. The accepted baseline remains `1.0.0` and is not promoted by this work.
