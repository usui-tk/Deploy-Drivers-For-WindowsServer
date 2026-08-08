# psa-disable-file PSAP0002 -- test code is not a pipeline script: it declares no
# ScriptVersion / ScriptHash / ScriptShortTag because it ships no runtime identity.
# The five product scripts remain subject to the rule.
<#
.SYNOPSIS
    Collector: service ImagePath resolution and problem-code decoding.
.DESCRIPTION
    Every case here traces to a shipped defect. Read the case names as a
    list of things that reached a production host.
#>
[CmdletBinding()]
[OutputType([int])]
param(
    [Parameter()] [string]$RepoRoot = (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
Import-Module (Join-Path (Split-Path -Parent $PSScriptRoot) 'lib/TestHarness.psm1') -Force
Reset-TestState

$collector = Join-Path $RepoRoot 'Collect-WindowsServerConfigurationEvidence.ps1'
. (Get-ScriptFunctionBlock -Path $collector -Name @(
    'Resolve-ServiceImagePath', 'Get-ConfigManagerErrorName', 'Get-DriverLoadStatusName'))

if ([string]::IsNullOrWhiteSpace($env:SystemRoot)) { $env:SystemRoot = 'C:\Windows' }
$root = ([string]$env:SystemRoot).TrimEnd('\')

Write-TestSection 'Resolve-ServiceImagePath: every ImagePath shape seen in the field'
Assert-Equal 'kernel driver \SystemRoot form' ($root + '\System32\drivers\vwifibus.sys') `
    (Resolve-ServiceImagePath -ImagePath '\SystemRoot\System32\drivers\vwifibus.sys')
Assert-Equal 'DriverStore path' ($root + '\System32\DriverStore\FileRepository\amdi2c.inf_amd64_x\amdi2c.sys') `
    (Resolve-ServiceImagePath -ImagePath '\SystemRoot\System32\DriverStore\FileRepository\amdi2c.inf_amd64_x\amdi2c.sys')
Assert-Equal 'NT object-manager prefix' 'C:\Program Files\Vendor\drv.sys' `
    (Resolve-ServiceImagePath -ImagePath '\??\C:\Program Files\Vendor\drv.sys')
Assert-Equal 'relative system32 form' ($root + '\system32\drivers\foo.sys') `
    (Resolve-ServiceImagePath -ImagePath 'system32\drivers\foo.sys')
Assert-Equal 'quoted exe with arguments' 'C:\Windows\system32\svchost.exe' `
    (Resolve-ServiceImagePath -ImagePath '"C:\Windows\system32\svchost.exe" -k netsvcs')
Assert-Equal 'unquoted exe with arguments' 'C:\Windows\system32\svchost.exe' `
    (Resolve-ServiceImagePath -ImagePath 'C:\Windows\system32\svchost.exe -k LocalService')
Assert-Equal 'absolute path passes through' 'C:\Windows\System32\drivers\x.sys' `
    (Resolve-ServiceImagePath -ImagePath 'C:\Windows\System32\drivers\x.sys')
Assert-Equal 'empty input' '' (Resolve-ServiceImagePath -ImagePath '')
Assert-Equal 'whitespace input' '' (Resolve-ServiceImagePath -ImagePath '   ')

Write-TestSection 'Regression: the resolver must not return its input unchanged'
# The shipped defect used the regex '^\SystemRoot' - \S is the
# non-whitespace class, so it never matched and the caller concluded that
# every driver binary was missing.
$out = Resolve-ServiceImagePath -ImagePath '\SystemRoot\System32\drivers\vwifibus.sys'
Assert-False 'result is not the unmodified input' ($out -eq '\SystemRoot\System32\drivers\vwifibus.sys')
Assert-False 'result contains no \SystemRoot remnant' ($out -like '*\SystemRoot*')

Write-TestSection 'ConfigManager problem codes decode to locale-stable names'
Assert-Pattern 'code 39' 'FAILED_DRIVER_LOAD' (Get-ConfigManagerErrorName -Code 39)
Assert-Pattern 'code 1'  'NOT_CONFIGURED'     (Get-ConfigManagerErrorName -Code 1)
Assert-Pattern 'code 28' 'FAILED_INSTALL'     (Get-ConfigManagerErrorName -Code 28)
Assert-Pattern 'code 51' 'WAITING_ON_DEPENDENCY' (Get-ConfigManagerErrorName -Code 51)
Assert-Equal 'null code returns empty' '' (Get-ConfigManagerErrorName -Code $null)

Write-TestSection 'NTSTATUS: signature failures are separated from look-alikes'
# This distinction decided a real post-mortem: both surface as code 39 in
# Device Manager and the remedies have nothing in common.
Assert-Pattern 'invalid image hash is a SIGNATURE failure' 'SIGNATURE:' (Get-DriverLoadStatusName -Status '0xC0000428')
Assert-Pattern 'cert revoked is a SIGNATURE failure'       'SIGNATURE:' (Get-DriverLoadStatusName -Status '0xC0000603')
Assert-Pattern 'entrypoint not found is NOT a signature failure' 'NOT a signature' (Get-DriverLoadStatusName -Status '0xC0000263')
Assert-Pattern 'ordinal not found is NOT a signature failure'    'NOT a signature' (Get-DriverLoadStatusName -Status '0xC0000262')
Assert-Equal 'empty status returns empty' '' (Get-DriverLoadStatusName -Status '')

$result = Get-TestResult
Write-Host ''
Write-Host ('{0}: {1} passed, {2} failed' -f (Split-Path -Leaf $PSCommandPath), $result.Passed, $result.Failed) `
    -ForegroundColor $(if ($result.Failed -eq 0) { 'Green' } else { 'Red' })
exit $result.Failed
