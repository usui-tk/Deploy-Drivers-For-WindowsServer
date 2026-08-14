# AMD Chipset Driver Research Toolkit 1.2.10 Windows MSI Live Validation

Date: 2026-08-11 JST

## Scope

This report reviews the user-provided Windows evidence archive:

`AmdChipsetDriverResearchEvidence_20260811-034730_Windows.zip`

Size: `31,719,835 bytes`

SHA-256:

`bb4758c2b3c88528db06cbf7e2a308fa4eac07e48f95da2fcf0dfcedef2c7c6e`

The run used toolkit `1.2.9-qt-dev` with script SHA-256:

`801eb53d833e8b838da597b1aeb5a8329e03d85e60db2e191e3f450494881db7`

## Host and runtime

- Windows 11 Pro
- Build 26200
- Windows PowerShell 5.1.26100.8972 / Desktop edition
- CIM `OSArchitecture`: `64 ビット`
- normalized architecture: `x86_64`
- 7-Zip: available (`C:\Program Files\7-Zip\7z.exe`)

## Run result

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

Final result: `Pass`, exit code `0`.

The run produced:

- 25/25 installer artifacts available;
- 25/25 INF-bearing extraction outputs complete;
- 643 INF package records;
- zero INF parse failures;
- Windows 11 architecture normalization remained correct;
- 8.07.16.1035 retained six selected selector candidates and `UnknownAmdFilterCount=0`.

## Windows Installer COM gate: passed

The primary 1.2.9 rerun gate is successful.

All 25 releases report:

`MsiDeclarativeAnalysis.Status = ParsedReadOnly`

and all 25 have zero MSI declarative-analysis errors.

No selector-stage runtime failure remains for the previously observed Windows Installer COM paths (`FieldCount`, `_Tables.Name`, `ColumnInfo`, `StringData`, or `Fetch`). The 1.2.9 FieldCount-independent MSI reading path is therefore live-confirmed on Windows PowerShell 5.1.

## Post-parse defect 1: successful status miscounted

The final 1.2.9 assessment still reported:

`parsed=0`

although all 25 releases were successfully `ParsedReadOnly`.

Cause: `Get-AmdMsiDeclarativeAssessmentFromReleases` counted only status `Parsed` as successful and did not include the implementation's actual successful status `ParsedReadOnly`.

This did not change the final PASS because there were no `ParseFailed` records, but the summary was semantically incorrect and could conceal future partial states.

### 1.2.10 correction

- `ParsedReadOnly` and legacy `Parsed` are successful parse states.
- `ParseFailed`, `ParsedWithErrors`, `MsiNotRecovered`, unknown status and missing analysis now produce `REVIEW`.
- A non-Windows run where every release explicitly reports `WindowsInstallerComUnavailableOnPlatform` remains a valid platform-limited PASS.
- The assessment self-test covers successful, platform-unavailable, parse-failed and partial/error cases.

With the supplied evidence replayed against the 1.2.10 assessment semantics, the expected result is:

- parsed: 25
- parse failed: 0
- parsed with errors: 0
- MSI not recovered: 0
- platform unavailable: 0
- status: PASS

## Post-parse defect 2: two synthetic null rows per MSI table

The live MSI output revealed a deterministic evidence-integrity defect.

For every release and every selected MSI table, exactly two all-null rows were present. Across the eight selected tables and 25 releases this produced 400 synthetic null rows.

Affected table groups:

- Property: 50 synthetic rows total
- Feature: 50
- Condition: 50
- LaunchCondition: 50
- CustomAction: 50
- InstallUISequence: 50
- InstallExecuteSequence: 50
- Upgrade: 50

Cause: `Get-AmdMsiTableRows` invoked `View.Execute()` and `View.Close()` without discarding their Automation return values. In PowerShell, method output can become function pipeline output, so these non-row method results contaminated the row array and serialized as null entries.

### 1.2.10 correction

The calls are now explicitly suppressed:

- `[void]$view.Execute()`
- `[void]$view.Close()`

A new `MsiTableRowPipelineIsolationSelfTest` uses sentinel-returning mock methods and requires exactly two real rows, zero null rows, and no Execute/Close sentinel leakage.

## Test-stage hardening

The supplied 1.2.9 transcript contains one caught terminating error during the FieldCount-independent self-test. It is intentional—the mock signaled end-of-fields by throwing—but it looks indistinguishable from an actual runtime problem in review transcripts.

1.2.10 changes the self-test mock to use a null end marker instead of throwing, so a healthy Test stage produces no intentional terminating-error line.

In addition, all internal self-tests are now readiness-gating. `environment.json` records `SelfTestsReady`, `FullResearchReady` requires it, and the Test stage throws after persisting diagnostics if any self-test fails. A displayed failed self-test can no longer coexist with a misleading Test PASS.

## 1.2.10 development validation

Development-host checks completed:

- PowerShell 7.6.4 AST parse: 0 errors.
- Test stage: PASS.
- `SelfTestsReady=True`.
- Compiled selector contract self-test: PASS.
- Host architecture normalization self-test: PASS.
- MSI table-name projection self-test: PASS.
- MSI FieldCount-independent column discovery self-test: PASS.
- MSI table-row pipeline isolation self-test: PASS.
- MSI declarative assessment self-test: PASS.
- Test output contains no intentional `Unable to read Windows Installer Record.StringData` terminating-error record.
- Supplied Windows evidence target schema files: 31; schema errors: 0.

Detailed replay evidence is retained as:

`qualification/1.2.10-qt-dev/windows-rerun-analysis.json`

## Remaining gate

The functional Windows Installer COM gate itself is complete because 1.2.9 parsed all 25 MSI databases successfully on Windows.

A Windows rerun of 1.2.10 is still recommended before GA/baseline promotion to live-confirm the two post-parse hardening changes:

1. `MsiDeclarativeInspection` should report `parsed=25` rather than `parsed=0`;
2. selected MSI table arrays should no longer contain the two synthetic null rows per table;
3. the Test transcript should contain no intentional self-test terminating error;
4. all self-tests should remain PASS and `SelfTestsReady=True`.

This is a release-quality confirmation gate, not a remaining MSI COM functional blocker.

## Release status

`1.2.10-qt-dev` remains a development preview. The accepted baseline remains `1.0.0` and is unchanged.
