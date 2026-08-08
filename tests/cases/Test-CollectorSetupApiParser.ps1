# psa-disable-file PSAP0002 -- test code is not a pipeline script: it declares no
# ScriptVersion / ScriptHash / ScriptShortTag because it ships no runtime identity.
# The five product scripts remain subject to the rule.
<#
.SYNOPSIS
    Collector: setupapi.dev.log failure extraction.
.DESCRIPTION
    This case exists because the shipped parser threw on its own first line.
    The section detector used the wildcard '>>>*[Device Install*', in which
    '[' opens a character class; unterminated, PowerShell rejects the whole
    pattern with WildcardPatternException. The collector aborted, took every
    later stage with it, and produced no evidence archive.

    A test that only checked the returned object would not have caught it.
    The first assertion here is simply that the function does not throw.
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
    'Get-SetupApiFailureEvidence', 'Get-ConfigManagerErrorName', 'Get-DriverLoadStatusName', 'Get-UtcTimestamp'))

$fixture = Join-Path (Join-Path (Split-Path -Parent $PSScriptRoot) 'fixtures') 'setupapi-failures.sample.log'

Write-TestSection 'The parser runs at all'
Assert-NoThrow 'parsing a log with [Device Install] section headers does not throw' {
    Get-SetupApiFailureEvidence -LogPath $fixture
}

$evidence = Get-SetupApiFailureEvidence -LogPath $fixture

Write-TestSection 'Section detection'
Assert-True  'log recognised as present' $evidence.LogPresent
Assert-Equal 'all three sections scanned' 3 $evidence.SectionsScanned
Assert-Equal 'only the two failing sections are reported' 2 @($evidence.FailureSections).Count

Write-TestSection 'Missing service binary extraction'
Assert-Equal 'one missing-binary line found' 1 @($evidence.MissingServiceBinaries).Count
Assert-Equal 'service name captured' 'vwifibus' @($evidence.MissingServiceBinaries)[0].ServiceName
Assert-Pattern 'binary path captured' 'vwifibus\.sys' @($evidence.MissingServiceBinaries)[0].ExpectedBinary

Write-TestSection 'Error codes and NT status'
$codes = [string](@($evidence.FailureSections | ForEach-Object { $_.SetupApiErrors }) -join ' ')
Assert-Pattern 'SetupAPI error 0xe0000217 captured' '0xe0000217' $codes
$withProblem = @($evidence.FailureSections | Where-Object { [string]$_.ConfigManagerErrorCode -ne '' })
Assert-Equal 'one section carries a CM problem code' 1 $withProblem.Count
if ($withProblem.Count -gt 0) {
    Assert-Equal 'problem 0x27 decoded to decimal 39' '39' $withProblem[0].ConfigManagerErrorCode
    Assert-Pattern 'CM code decoded to a name' 'FAILED_DRIVER_LOAD' $withProblem[0].ConfigManagerErrorName
    Assert-Equal 'NT status captured' '0xc0000263' $withProblem[0].DriverLoadStatus
    Assert-Pattern 'NT status classified as NOT a signature failure' 'NOT a signature' $withProblem[0].DriverLoadStatusName
}

Write-TestSection 'Absent log is handled, not thrown on'
Assert-NoThrow 'missing log path does not throw' { Get-SetupApiFailureEvidence -LogPath 'Z:\definitely\not\here.log' }
$absent = Get-SetupApiFailureEvidence -LogPath 'Z:\definitely\not\here.log'
Assert-False 'absent log reported as not present' $absent.LogPresent
Assert-Equal 'absent log yields no sections' 0 @($absent.FailureSections).Count

$result = Get-TestResult
Write-Host ''
Write-Host ('{0}: {1} passed, {2} failed' -f (Split-Path -Leaf $PSCommandPath), $result.Passed, $result.Failed) `
    -ForegroundColor $(if ($result.Failed -eq 0) { 'Green' } else { 'Red' })
exit $result.Failed
