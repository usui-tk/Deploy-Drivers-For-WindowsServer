# Test suite

Executable checks for the five scripts in this repository. Every case here
traces to something that reached a production host: this suite is a record
of defects, not an exercise in coverage.

## Running it

```powershell
# everything
./tests/Invoke-TestSuite.ps1

# one case, by wildcard on the file name
./tests/Invoke-TestSuite.ps1 -Name '*Collector*'
```

Exit code is the number of failing cases, so CI and shell scripts can branch
on it directly.

No dependencies. Windows PowerShell 5.1 or PowerShell 7.x, Windows or Linux,
nothing to install. A suite that needs setting up is a suite contributors
skip.

**Nothing here executes a deploy script or touches driver state.** Cases pull
the functions they exercise out of the real files by AST and run them against
fixtures. Physical-hardware validation is a different activity and lives in
[`TESTING.md`](../TESTING.md).

## Layout

```
tests/
  Invoke-TestSuite.ps1        runner: discovers cases/Test-*.ps1
  lib/TestHarness.psm1        assertions + AST function extraction
  cases/Test-*.ps1            one file per subject area
  fixtures/                   sample inputs (synthetic, no host data)
```

## Cases

| Case | Covers |
|---|---|
| `Test-CollectorPathResolution.ps1` | `Resolve-ServiceImagePath` across every `ImagePath` shape seen in the field; CM_PROB and NTSTATUS decoding, including the separation of signature failures from look-alike API mismatches |
| `Test-CollectorSetupApiParser.ps1` | `setupapi.dev.log` failure-section extraction: section detection, missing service binaries, SetupAPI error codes, CM problem codes with NT status, absent-log handling |
| `Test-SisterConsistency.ps1` | Shared-helper byte identity across the sisters; ValidateSet call-site conformance; `@( )` never applied to a `List[object]`; every script parses and declares a version |
| `Test-SupplementalPolicyGate.ps1` | The WDAC supplemental path never assumes a base policy (SPEC D.58.8): the assumed GUID is gone from code string constants, `WdacBasePolicyGuidDefault` is gone repo-wide, all four sisters carry a byte-identical admissibility helper, every builder refuses an empty `BasePolicyId`, and the phase gate's refusal branch returns |

## Why these checks and not others

Three defect classes shipped despite a green static gate battery, and each
one is now a case:

- **A string literal that was well-formed but wrong.** `psa.py` and
  `Parser::ParseFile` verify that a literal parses. Neither can know what it
  was meant to contain. A registry path lost its trailing separator and a
  regex used `\S` where a literal backslash was meant; the diagnostic that
  depended on both reported PASS while doing nothing.
- **An exception on the first call.** A parameter that did not exist on the
  target function, and a wildcard pattern containing an unterminated
  character class. Neither is visible in a return value, which is why
  `Assert-NoThrow` exists and why the first assertion in the setupapi case is
  simply that the function runs.
- **A drift between sisters.** The four deploy scripts share helpers by
  byte-identical duplication, not by import. Nothing enforces that at
  runtime, so a fix applied to one and forgotten on the others stays
  invisible until a field run.

## Adding a case

1. Create `cases/Test-<Subject>.ps1`. Accept `-RepoRoot` and default it to
   two levels up from `$PSScriptRoot`.
2. Import the harness, call `Reset-TestState`, and dot-source what you need:

   ```powershell
   Import-Module (Join-Path (Split-Path -Parent $PSScriptRoot) 'lib/TestHarness.psm1') -Force
   Reset-TestState
   . (Get-ScriptFunctionBlock -Path $target -Name @('Some-Function'))
   ```

   Extract by AST; never copy a function into a test. A copy drifts from the
   original silently, and a test passing against a stale copy is worse than
   no test.
3. Assert with `Assert-Equal` / `Assert-True` / `Assert-False` /
   `Assert-Pattern` / `Assert-NoThrow`, grouped by `Write-TestSection`.
4. End with `Get-TestResult` and `exit $result.Failed`.
5. Fixtures go in `fixtures/`. Keep them synthetic — no host identifiers, no
   captured customer data.

**Write the case so it fails against the defective version first.** A check
that has never failed has not been shown to be capable of failing. Where a
case guards a specific past defect, say which one in the case's comment
header, so a later reader can tell whether it is still earning its place.
