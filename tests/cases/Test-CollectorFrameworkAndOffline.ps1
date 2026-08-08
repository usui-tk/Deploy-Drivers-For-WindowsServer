# psa-disable-file PSAP0002 -- test code is not a pipeline script: it declares no
# ScriptVersion / ScriptHash / ScriptShortTag because it ships no runtime identity.
# The five product scripts remain subject to the rule.
<#
.SYNOPSIS
    Collector: driver framework versions, crash evidence, offline collector.
.DESCRIPTION
    The framework and crash stages answer questions that only matter when a
    host is misbehaving, which is exactly when nobody wants to discover the
    collection code has a fault. Every case here calls the function.

    The offline collector is a .cmd because the Windows Recovery Environment
    has no PowerShell. It cannot be executed here, so it is checked
    structurally for the properties a batch file must hold - matched
    reg load/unload, reachable goto targets, CRLF, no BOM, plain ASCII.
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
    'Get-UtcTimestamp', 'Get-PropertyValue', 'Get-RegistryKeySnapshot', 'Get-NamedRegistryValue',
    'Get-FileVersionInfoSafe', 'Get-DriverFrameworkEvidence', 'Get-CrashEvidence'))

Write-TestSection 'Get-FileVersionInfoSafe tolerates every input'
Assert-NoThrow 'empty path does not throw' { Get-FileVersionInfoSafe -Path '' }
Assert-False 'empty path reports not-exists' (Get-FileVersionInfoSafe -Path '').Exists
Assert-NoThrow 'missing file does not throw' { Get-FileVersionInfoSafe -Path 'Z:\nope\absent.sys' }
Assert-False 'missing file reports not-exists' (Get-FileVersionInfoSafe -Path 'Z:\nope\absent.sys').Exists
$self = Get-FileVersionInfoSafe -Path (Resolve-Path $collector).Path
Assert-True  'an existing file reports exists' $self.Exists
Assert-True  'an existing file reports a size' ($self.SizeBytes -gt 0)

Write-TestSection 'Driver framework evidence runs on any host'
# Regression guard: the first version built its paths with Join-Path, which
# throws on a null mandatory parameter when $env:SystemRoot is unset.
Assert-NoThrow 'framework collection does not throw' { Get-DriverFrameworkEvidence }
$fw = Get-DriverFrameworkEvidence
Assert-True 'a KMDF runtime record is always present' ($null -ne $fw.KmdfRuntime)
Assert-True 'a UMDF reflector record is always present' ($null -ne $fw.UmdfReflector)
Assert-True 'co-installer count is a number' ($fw.CoInstallerCount -ge 0)
$savedRoot = $env:SystemRoot
try {
    $env:SystemRoot = ''
    Assert-NoThrow 'empty SystemRoot does not throw' { Get-DriverFrameworkEvidence }
    $bare = Get-DriverFrameworkEvidence
    Assert-Equal 'empty SystemRoot yields an empty KMDF version, not an error' '' $bare.KmdfLibraryVersion
}
finally { $env:SystemRoot = $savedRoot }

Write-TestSection 'Crash evidence runs on any host'
Assert-NoThrow 'crash collection does not throw' { Get-CrashEvidence }
$crash = Get-CrashEvidence
Assert-True 'minidump count is a number' ($crash.MinidumpCount -ge 0)
Assert-True 'bugcheck event count is a number' ($crash.BugCheckEventCount -ge 0)
Assert-True 'a CrashControl record is always present' ($null -ne $crash.CrashControl)
# A host without Get-WinEvent must record why, not silently report zero
# events as though it had looked.
$savedRoot2 = $env:SystemRoot
try {
    $env:SystemRoot = ''
    Assert-NoThrow 'empty SystemRoot does not throw' { Get-CrashEvidence }
    $bare2 = Get-CrashEvidence
    Assert-False 'no memory dump claimed when no root is resolvable' $bare2.MemoryDumpPresent
}
finally { $env:SystemRoot = $savedRoot2 }

Write-TestSection 'Offline recovery collector is a well-formed batch file'
$offline = Join-Path $RepoRoot 'Collect-OfflineRecoveryEvidence.cmd'
Assert-True 'the offline collector exists' (Test-Path -LiteralPath $offline)
$bytes = [System.IO.File]::ReadAllBytes($offline)
Assert-False 'no UTF-8 BOM (cmd.exe treats it as part of the first command)' `
    ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF)
$nonAscii = @($bytes | Where-Object { $_ -gt 127 }).Count
Assert-Equal 'plain ASCII only' 0 $nonAscii
$text = [System.Text.Encoding]::ASCII.GetString($bytes)
Assert-True 'CRLF line endings' ($text.Contains("`r`n"))
Assert-False 'no bare LF' ($text -replace "`r`n", '').Contains("`n")
Assert-True  'delayed expansion is enabled before it is used' `
    ($text.ToLower().Contains('setlocal enabledelayedexpansion'))
Assert-True  'endlocal present' ($text.ToLower().Contains('endlocal'))
# An unbalanced reg load leaves the hive mounted, which blocks the next run
# and can hold a file handle on the volume under investigation.
$loads = ([regex]::Matches($text, 'reg load')).Count
$unloads = ([regex]::Matches($text, 'reg unload')).Count
Assert-Equal 'every reg load has a matching reg unload' $loads $unloads
$gotoTargets = @([regex]::Matches($text, 'goto :(\w+)') | ForEach-Object { $_.Groups[1].Value })
$labels = @([regex]::Matches($text, '(?m)^:(\w+)') | ForEach-Object { $_.Groups[1].Value })
foreach ($g in $gotoTargets) {
    Assert-True ('goto target :{0} has a label' -f $g) ($labels -contains $g)
}
# The offline volume may be the failing device; writing evidence onto it can
# lose the evidence and worsen the fault.
Assert-True 'refuses to write output onto the offline volume' ($text.Contains('output directory is on the offline Windows volume'))
Assert-True 'uses ControlSet001, not CurrentControlSet (no Current alias offline)' `
    ($text.Contains('ControlSet001') -and -not $text.Contains('OFFSYS\CurrentControlSet'))

$result = Get-TestResult
Write-Host ''
Write-Host ('{0}: {1} passed, {2} failed' -f (Split-Path -Leaf $PSCommandPath), $result.Passed, $result.Failed) `
    -ForegroundColor $(if ($result.Failed -eq 0) { 'Green' } else { 'Red' })
exit $result.Failed
