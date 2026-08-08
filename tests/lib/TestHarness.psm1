# psa-disable-file PSAP0002 -- test code is not a pipeline script: it declares no
# ScriptVersion / ScriptHash / ScriptShortTag because it ships no runtime identity.
# The five product scripts remain subject to the rule.
<#
.SYNOPSIS
    Minimal assertion and extraction library for the repository test suite.

.DESCRIPTION
    Deliberately dependency-free: no Pester, no modules to install, no
    network. The suite has to run on a maintainer's Linux box and on a
    Windows Server test host with nothing but the shipped PowerShell, and
    anything that needs installing is something a contributor will skip.

    Extraction, not duplication: tests pull the functions they exercise out
    of the real script by AST. A copied helper drifts from the original
    without anyone noticing, and a test that passes against a stale copy is
    worse than no test.
#>

$script:Passed = 0
$script:Failed = 0
$script:Failures = New-Object 'System.Collections.Generic.List[string]'

function Reset-TestState {
    [CmdletBinding()]
    [OutputType([void])]
    param()
    $script:Passed = 0
    $script:Failed = 0
    $script:Failures = New-Object 'System.Collections.Generic.List[string]'
}

function Get-ScriptFunctionBlock {
    <#
    .SYNOPSIS
        Extract named functions from a script as a dot-sourceable block.
    .DESCRIPTION
        The deploy scripts and the collector do work at load time, so they
        cannot simply be dot-sourced. This parses the file and returns the
        requested function definitions as a scriptblock. The CALLER must
        dot-source the result:

            . (Get-ScriptFunctionBlock -Path $collector -Name @('Foo'))

        Returning rather than defining is deliberate: a module function that
        dot-sources defines into the MODULE's scope, where the test file
        cannot see it. That mistake is invisible until the suite runs.

        Throws when a requested name is absent, so a renamed function breaks
        the test loudly instead of silently skipping it.
    #>
    [CmdletBinding()]
    [OutputType([scriptblock])]
    param(
        [Parameter(Mandatory = $true)] [ValidateNotNullOrEmpty()] [string]$Path,
        [Parameter(Mandatory = $true)] [ValidateNotNullOrEmpty()] [string[]]$Name
    )
    $tokens = $null
    $errors = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseFile(
        (Resolve-Path $Path).Path, [ref]$tokens, [ref]$errors)
    if (@($errors).Count -gt 0) {
        throw ('{0}: {1} parse error(s)' -f (Split-Path -Leaf $Path), @($errors).Count)
    }
    $found = @{}
    foreach ($fn in $ast.FindAll({ param($n) $n -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true)) {
        if ($Name -contains $fn.Name -and -not $found.ContainsKey($fn.Name)) {
            $found[$fn.Name] = $fn.Extent.Text
        }
    }
    $missing = @($Name | Where-Object { -not $found.ContainsKey($_) })
    if ($missing.Count -gt 0) {
        throw ('{0}: function(s) not found: {1}' -f (Split-Path -Leaf $Path), ($missing -join ', '))
    }
    return [scriptblock]::Create((($Name | ForEach-Object { $found[$_] }) -join "`n"))
}

function Assert-Equal {
    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory = $true)] [ValidateNotNullOrEmpty()] [string]$Case,
        [Parameter()] [AllowNull()] [object]$Expected,
        [Parameter()] [AllowNull()] [object]$Actual
    )
    if ([string]$Expected -eq [string]$Actual) {
        $script:Passed++
        Write-Host ('  PASS  {0}' -f $Case) -ForegroundColor Green
    }
    else {
        $script:Failed++
        $script:Failures.Add($Case) | Out-Null
        Write-Host ('  FAIL  {0}' -f $Case) -ForegroundColor Red
        Write-Host ('          expected: [{0}]' -f $Expected)
        Write-Host ('          actual  : [{0}]' -f $Actual)
    }
}

function Assert-True {
    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory = $true)] [ValidateNotNullOrEmpty()] [string]$Case,
        [Parameter()] [object]$Condition
    )
    Assert-Equal -Case $Case -Expected 'True' -Actual ([bool]$Condition).ToString()
}

function Assert-False {
    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory = $true)] [ValidateNotNullOrEmpty()] [string]$Case,
        [Parameter()] [object]$Condition
    )
    Assert-Equal -Case $Case -Expected 'False' -Actual ([bool]$Condition).ToString()
}

function Assert-Pattern {
    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory = $true)] [ValidateNotNullOrEmpty()] [string]$Case,
        [Parameter(Mandatory = $true)] [ValidateNotNullOrEmpty()] [string]$Pattern,
        [Parameter()] [AllowEmptyString()] [string]$Actual
    )
    if ([string]$Actual -match [string]$Pattern) { # psa-disable-line PSA2003 -- $Pattern is Mandatory + ValidateNotNullOrEmpty; $null is impossible by construction
        $script:Passed++
        Write-Host ('  PASS  {0}' -f $Case) -ForegroundColor Green
    }
    else {
        $script:Failed++
        $script:Failures.Add($Case) | Out-Null
        Write-Host ('  FAIL  {0}' -f $Case) -ForegroundColor Red
        Write-Host ('          pattern: {0}' -f $Pattern)
        Write-Host ('          actual : {0}' -f $Actual)
    }
}

function Assert-NoThrow {
    <#
    .SYNOPSIS
        Assert that a script block completes without throwing.
    .DESCRIPTION
        Present because two shipped defects were exceptions on the first
        call, not wrong answers: a parameter that did not exist, and a
        wildcard pattern containing an unterminated character class. Neither
        is detectable by checking a return value.
    #>
    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory = $true)] [ValidateNotNullOrEmpty()] [string]$Case,
        [Parameter(Mandatory = $true)] [ValidateNotNullOrEmpty()] [scriptblock]$Body
    )
    try {
        $null = & $Body
        $script:Passed++
        Write-Host ('  PASS  {0}' -f $Case) -ForegroundColor Green
    }
    catch {
        $script:Failed++
        $script:Failures.Add($Case) | Out-Null
        Write-Host ('  FAIL  {0}' -f $Case) -ForegroundColor Red
        Write-Host ('          threw: {0}' -f $_.Exception.Message)
    }
}

function Write-TestSection {
    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory = $true)] [ValidateNotNullOrEmpty()] [string]$Title
    )
    Write-Host ''
    Write-Host ('--- {0}' -f $Title) -ForegroundColor Cyan
}

function Get-TestResult {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()
    return [pscustomobject]@{
        Passed = $script:Passed
        Failed = $script:Failed
        Failures = @($script:Failures)
    }
}

Export-ModuleMember -Function Reset-TestState, Get-ScriptFunctionBlock, Assert-Equal, Assert-True,
    Assert-False, Assert-Pattern, Assert-NoThrow, Write-TestSection, Get-TestResult
