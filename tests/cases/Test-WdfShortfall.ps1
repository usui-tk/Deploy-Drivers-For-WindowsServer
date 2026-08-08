# psa-disable-file PSAP0002 -- test code is not a pipeline script: it declares no
# ScriptVersion / ScriptHash / ScriptShortTag because it ships no runtime identity.
# The five product scripts remain subject to the rule.
<#
.SYNOPSIS
    Sisters: comparing an INF's WDF requirement against the host runtime.
.DESCRIPTION
    Get-InfWdfRequirement reads what a package asks for and Get-HostWdfRuntime
    reads what the machine provides. Get-WdfShortfallSummary is the comparison
    between them, and it is kept a pure function of its arguments precisely so
    it can be tested here - no Windows host, no INF on disk, no registry.

    The property that carries the risk is the ordering. A string comparison
    reports 1.19 as lower than 1.9, which turns "this package cannot load" into
    "this package is fine" - a silent false negative in the direction nobody
    checks. That is pinned first and from both sides.
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

$chipset = Join-Path $RepoRoot 'Deploy-AMDChipsetDriverOnWindowsServer.ps1'
. (Get-ScriptFunctionBlock -Path $chipset -Name @(
    'ConvertTo-WdfVersionNumber', 'Get-RecordFieldText', 'Get-WdfShortfallSummary'))

function New-InfRecord {
    param($Path, $Kmdf = '', $Umdf = '')
    return [pscustomobject]@{
        FullPath           = $Path
        KmdfLibraryVersion = $Kmdf
        UmdfLibraryVersion = $Umdf
    }
}

Write-TestSection 'A package within the host runtime is not flagged'
$within = @(
    (New-InfRecord -Path 'C:\pkg\amdgpio.inf' -Kmdf '1.15'),
    (New-InfRecord -Path 'C:\pkg\amdi2c.inf'  -Kmdf '1.19')
)
$r = Get-WdfShortfallSummary -InfRecord $within -HostKmdfVersion '1.19' -HostUmdfVersion '2.19'
Assert-True 'the host runtime was probed' $r.Probed
Assert-Equal 'both records evaluated' 2 $r.EvaluatedCount
Assert-Equal 'nothing exceeds the runtime' 0 $r.ExceedingCount
Assert-Equal 'and the name list is empty' 0 @($r.ExceedingNames).Count

Write-TestSection 'A package above the host runtime is flagged, and named'
$above = @(
    (New-InfRecord -Path 'C:\pkg\amdgpio.inf' -Kmdf '1.15'),
    (New-InfRecord -Path 'C:\pkg\amdpsp.inf'  -Kmdf '1.33')
)
$r = Get-WdfShortfallSummary -InfRecord $above -HostKmdfVersion '1.19' -HostUmdfVersion '2.19'
Assert-Equal 'one record exceeds' 1 $r.ExceedingCount
Assert-Equal 'the list carries that one entry' 1 @($r.ExceedingNames).Count
Assert-Pattern 'the entry names the leaf INF' 'amdpsp\.inf' (@($r.ExceedingNames)[0])
Assert-Pattern 'and states the requirement against the host' 'KMDF 1\.33 > 1\.19' (@($r.ExceedingNames)[0])

Write-TestSection 'Ordering is numeric, in both directions'
# 1.19 on a 1.9 host must be flagged; a string comparison calls 1.19 lower and
# stays silent. 1.9 on a 1.19 host must NOT be flagged; a string comparison
# calls 1.9 higher and raises a false alarm. Both directions, because a
# comparator can be wrong either way and only one of them is loud.
$r = Get-WdfShortfallSummary -InfRecord @((New-InfRecord -Path 'C:\p\a.inf' -Kmdf '1.19')) `
    -HostKmdfVersion '1.9' -HostUmdfVersion ''
Assert-Equal '1.19 required on a 1.9 host is flagged' 1 $r.ExceedingCount
$r = Get-WdfShortfallSummary -InfRecord @((New-InfRecord -Path 'C:\p\a.inf' -Kmdf '1.9')) `
    -HostKmdfVersion '1.19' -HostUmdfVersion ''
Assert-Equal '1.9 required on a 1.19 host is not flagged' 0 $r.ExceedingCount

Write-TestSection 'Equality is satisfied, not exceeded'
$r = Get-WdfShortfallSummary -InfRecord @((New-InfRecord -Path 'C:\p\a.inf' -Kmdf '1.19')) `
    -HostKmdfVersion '1.19' -HostUmdfVersion ''
Assert-Equal 'requiring exactly what the host has is fine' 0 $r.ExceedingCount

Write-TestSection 'KMDF and UMDF are judged independently'
$mixed = @((New-InfRecord -Path 'C:\p\umdfonly.inf' -Kmdf '' -Umdf '2.33'))
$r = Get-WdfShortfallSummary -InfRecord $mixed -HostKmdfVersion '1.33' -HostUmdfVersion '2.19'
Assert-Equal 'a UMDF-only shortfall is caught' 1 $r.ExceedingCount
Assert-Pattern 'and reported as UMDF' 'UMDF 2\.33 > 2\.19' (@($r.ExceedingNames)[0])
$both = @((New-InfRecord -Path 'C:\p\both.inf' -Kmdf '1.33' -Umdf '2.33'))
$r = Get-WdfShortfallSummary -InfRecord $both -HostKmdfVersion '1.19' -HostUmdfVersion '2.19'
Assert-Equal 'a record short on both is counted once' 1 $r.ExceedingCount
Assert-Pattern 'and both shortfalls are named' 'KMDF.*UMDF' (@($r.ExceedingNames)[0])

Write-TestSection 'An unknown host version judges nothing rather than guessing'
# Get-HostWdfRuntime returns empty strings when the binary cannot be read.
# Treating "unknown" as "zero" would flag every WDF driver on the machine.
$r = Get-WdfShortfallSummary -InfRecord @((New-InfRecord -Path 'C:\p\a.inf' -Kmdf '1.33')) `
    -HostKmdfVersion '' -HostUmdfVersion ''
Assert-False 'the summary reports it was not probed' $r.Probed
Assert-Equal 'and flags nothing' 0 $r.ExceedingCount

Write-TestSection 'A record with no requirement is evaluated and passes'
$r = Get-WdfShortfallSummary -InfRecord @((New-InfRecord -Path 'C:\p\plain.inf')) `
    -HostKmdfVersion '1.19' -HostUmdfVersion '2.19'
Assert-Equal 'counted as evaluated' 1 $r.EvaluatedCount
Assert-Equal 'not flagged' 0 $r.ExceedingCount

Write-TestSection 'The name list is complete, never truncated'
# A shortened list reads as the whole answer and nothing in the output says
# otherwise (SPEC O24). Enough entries here that a truncating implementation
# would have to show it.
$many = @(1..25 | ForEach-Object { New-InfRecord -Path ('C:\pkg\drv{0:d2}.inf' -f $_) -Kmdf '1.33' })
$r = Get-WdfShortfallSummary -InfRecord $many -HostKmdfVersion '1.19' -HostUmdfVersion '2.19'
Assert-Equal 'all 25 are counted' 25 $r.ExceedingCount
Assert-Equal 'and all 25 are listed' 25 @($r.ExceedingNames).Count
Assert-Pattern 'including the last one' 'drv25\.inf' (@($r.ExceedingNames)[-1])

Write-TestSection 'Records missing the expected properties do not throw'
# Inventory records arrive from a live phase and from Import-Csv, and the two
# do not carry the same property set.
$sparse = @([pscustomobject]@{ FullPath = 'C:\p\sparse.inf' })
Assert-NoThrow 'a record without the WDF columns is tolerated' {
    Get-WdfShortfallSummary -InfRecord $sparse -HostKmdfVersion '1.19' -HostUmdfVersion '2.19'
}
$r = Get-WdfShortfallSummary -InfRecord $sparse -HostKmdfVersion '1.19' -HostUmdfVersion '2.19'
Assert-Equal 'and is not flagged' 0 $r.ExceedingCount
Assert-NoThrow 'an empty record set is tolerated' {
    Get-WdfShortfallSummary -InfRecord @() -HostKmdfVersion '1.19' -HostUmdfVersion '2.19'
}
$r = Get-WdfShortfallSummary -InfRecord @() -HostKmdfVersion '1.19' -HostUmdfVersion '2.19'
Assert-Equal 'an empty set evaluates nothing' 0 $r.EvaluatedCount

Write-TestSection 'A record with no usable path still appears in the list'
$noPath = @([pscustomobject]@{ FullPath = ''; KmdfLibraryVersion = '1.33'; UmdfLibraryVersion = '' })
$r = Get-WdfShortfallSummary -InfRecord $noPath -HostKmdfVersion '1.19' -HostUmdfVersion '2.19'
Assert-Equal 'it is flagged' 1 $r.ExceedingCount
Assert-Pattern 'under an explicit placeholder rather than an empty name' 'unnamed INF' (@($r.ExceedingNames)[0])

$result = Get-TestResult
Write-Host ''
Write-Host ('{0}: {1} passed, {2} failed' -f (Split-Path -Leaf $PSCommandPath), $result.Passed, $result.Failed) `
    -ForegroundColor $(if ($result.Failed -eq 0) { 'Green' } else { 'Red' })
exit $result.Failed
