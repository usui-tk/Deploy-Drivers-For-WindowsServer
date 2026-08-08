# psa-disable-file PSAP0002 -- test code is not a pipeline script: it declares no
# ScriptVersion / ScriptHash / ScriptShortTag because it ships no runtime identity.
# The five product scripts remain subject to the rule.
<#
.SYNOPSIS
    Collector: WDF version assessment.
.DESCRIPTION
    The host this project is validating on bugchecks with WDF_VIOLATION, and
    until now no bundle carried the KMDF version - the number every driver
    compatibility question on that host turns on.

    Two failure modes hang off the framework version and only one is
    predictable from static data. A driver requesting a NEWER version than
    the runtime provides cannot load at all; that is not a signing failure
    and no amount of re-signing moves it. A driver that DOES load and then
    breaks the framework contract produces WDF_VIOLATION, which nothing here
    predicts - the assessment bounds the suspect pool instead.
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
    'Get-UtcTimestamp', 'Get-ExpectedWdfVersion', 'ConvertTo-WdfVersionNumber',
    'Get-WdfCoInstallerInventory', 'Get-WdfDependentServiceInventory', 'Get-WdfAssessment'))

Write-TestSection 'Version comparison orders by number, not by string'
# The trap this guards: as strings, '1.19' sorts BELOW '1.9', which would
# report a driver needing 1.19 as satisfied by a 1.9 runtime.
Assert-True 'string comparison really is wrong here' ('1.19' -lt '1.9')
Assert-True '1.19 ranks above 1.9 numerically' `
    ((ConvertTo-WdfVersionNumber '1.19') -gt (ConvertTo-WdfVersionNumber '1.9'))
Assert-True '1.33 ranks above 1.19' ((ConvertTo-WdfVersionNumber '1.33') -gt (ConvertTo-WdfVersionNumber '1.19'))
Assert-True '1.27 ranks above 1.19' ((ConvertTo-WdfVersionNumber '1.27') -gt (ConvertTo-WdfVersionNumber '1.19'))
Assert-Equal 'empty version is not a number' -1 (ConvertTo-WdfVersionNumber '')
Assert-Equal 'unparseable version is not a number' -1 (ConvertTo-WdfVersionNumber 'not-a-version')
Assert-NoThrow 'a null-ish version does not throw' { ConvertTo-WdfVersionNumber -Version '' }

Write-TestSection 'In-box framework versions per OS build'
# From Microsoft's KMDF/UMDF version history. An earlier revision of this
# project asserted 1.15 for Windows Server 2016 from memory; the documented
# value is 1.19, and that mistake is why these are asserted individually.
$ws2016 = Get-ExpectedWdfVersion -Build 14393
Assert-True  'WS2016 build matches exactly' $ws2016.ExactBuildMatch
Assert-Equal 'WS2016 ships KMDF 1.19' '1.19' $ws2016.ExpectedKmdfVersion
Assert-Equal 'WS2016 ships UMDF 2.19' '2.19' $ws2016.ExpectedUmdfVersion
Assert-Equal 'WS2019 ships KMDF 1.27' '1.27' (Get-ExpectedWdfVersion -Build 17763).ExpectedKmdfVersion
Assert-Equal 'WS2022 ships KMDF 1.33' '1.33' (Get-ExpectedWdfVersion -Build 20348).ExpectedKmdfVersion
# An unknown build falls back to the nearest lower entry and says so, rather
# than reporting a version it cannot support.
$unknown = Get-ExpectedWdfVersion -Build 99999
Assert-False 'an unknown build is not an exact match' $unknown.ExactBuildMatch
Assert-True  'an unknown build still yields a value' (-not [string]::IsNullOrWhiteSpace($unknown.ExpectedKmdfVersion))
$zero = Get-ExpectedWdfVersion -Build 0
Assert-Equal 'build 0 yields no version rather than a wrong one' '' $zero.ExpectedKmdfVersion

Write-TestSection 'Co-installer inventory runs anywhere'
Assert-NoThrow 'inventory does not throw' { Get-WdfCoInstallerInventory }
$co = Get-WdfCoInstallerInventory
Assert-True 'a count is always reported' ($co.CoInstallerCount -ge 0)
$savedRoot = $env:SystemRoot
try {
    $env:SystemRoot = ''
    Assert-NoThrow 'empty SystemRoot does not throw' { Get-WdfCoInstallerInventory }
}
finally { $env:SystemRoot = $savedRoot }

Write-TestSection 'Assessment compares host against installed packages'
$fw = [pscustomobject]@{ KmdfLibraryVersion = '1.19'; UmdfLibraryVersion = '2.19' }
$osc = [pscustomobject]@{ OsBuild = 14393 }
$coFake = [pscustomobject]@{
    CoInstallerCount = 2
    CoInstallers = @(
        [pscustomobject]@{ Name = 'WdfCoInstaller01011.dll'; KmdfVersion = '1.11'; KmdfVersionNumber = (ConvertTo-WdfVersionNumber '1.11'); FullName = 'a' },
        [pscustomobject]@{ Name = 'WdfCoInstaller01031.dll'; KmdfVersion = '1.31'; KmdfVersionNumber = (ConvertTo-WdfVersionNumber '1.31'); FullName = 'b' }
    )
}
$svcFake = [pscustomobject]@{ WdfServiceCount = 12; BootOrSystemStartCount = 3 }
Assert-NoThrow 'assessment does not throw' { Get-WdfAssessment -DriverFramework $fw -OsCapability $osc -CoInstallers $coFake -WdfServices $svcFake }
$a = Get-WdfAssessment -DriverFramework $fw -OsCapability $osc -CoInstallers $coFake -WdfServices $svcFake
Assert-Equal 'the OS is named' 'Windows Server 2016 / Windows 10 1607' $a.OsName
Assert-Equal 'expected version is reported' '1.19' $a.ExpectedKmdfVersion
Assert-True  'a runtime at the documented version meets expectation' $a.KmdfMeetsExpectation
# Only the co-installer ABOVE the host version is flagged. Flagging the older
# one too would bury the finding in noise - a package built for an older
# framework runs fine.
Assert-Equal 'exactly the newer co-installer is flagged' 1 $a.CoInstallersExceedingHostCount
Assert-Equal 'and it is the 1.31 one' 'WdfCoInstaller01031.dll' @($a.CoInstallersExceedingHost)[0].Name
Assert-Equal 'the requested version is carried' '1.31' @($a.CoInstallersExceedingHost)[0].RequestedKmdfVersion
Assert-Equal 'WDF service count is carried through' 12 $a.WdfBasedServiceCount
Assert-Equal 'boot-start WDF count is carried through' 3 $a.WdfBootOrSystemStartCount
# The note exists so a reader does not mistake this for a WDF_VIOLATION
# predictor. It is not one.
Assert-True 'the assessment states what it does not predict' ($a.Note -match 'does not predict WDF_VIOLATION')

Write-TestSection 'Assessment degrades rather than throwing'
Assert-NoThrow 'a missing framework record does not throw' { Get-WdfAssessment -DriverFramework $null -OsCapability $osc -CoInstallers $null -WdfServices $null }
$bare = Get-WdfAssessment -DriverFramework $null -OsCapability $null -CoInstallers $null -WdfServices $null
Assert-Equal 'no host version yields empty, not a guess' '' $bare.ActualKmdfVersion
Assert-Equal 'nothing is flagged when there is nothing to compare' 0 $bare.CoInstallersExceedingHostCount

Write-TestSection 'WDF-dependent service selection'
$svcEvidence = [pscustomobject]@{ Services = @(
    [pscustomobject]@{ Name='amdi2c'; DisplayName='AMD I2C'; State='Stopped'; StartTypeName='Manual'; StartTypeNumeric=3; ServiceTypeName='KernelDriver'; ImagePathResolved='x'; ImagePathExists=$true; DependsOnService=@('Wdf01000') },
    [pscustomobject]@{ Name='bootwdf'; DisplayName='Boot WDF'; State='Running'; StartTypeName='Boot'; StartTypeNumeric=0; ServiceTypeName='KernelDriver'; ImagePathResolved='y'; ImagePathExists=$true; DependsOnService=@('Wdf01000') },
    [pscustomobject]@{ Name='plain'; DisplayName='Not WDF'; State='Running'; StartTypeName='Automatic'; StartTypeNumeric=2; ServiceTypeName='Win32OwnProcess'; ImagePathResolved='z'; ImagePathExists=$true; DependsOnService=@('RpcSs') }
) }
$w = Get-WdfDependentServiceInventory -ServiceEvidence $svcEvidence
Assert-Equal 'only WDF-dependent services are selected' 2 $w.WdfServiceCount
# Boot-start WDF drivers can bugcheck before anything can be logged, so they
# are counted separately.
Assert-Equal 'boot/system-start ones are counted separately' 1 $w.BootOrSystemStartCount
Assert-Equal 'and named' 'bootwdf' @($w.BootOrSystemStartNames)[0]
Assert-NoThrow 'a null service evidence does not throw' { Get-WdfDependentServiceInventory -ServiceEvidence $null }

$result = Get-TestResult
Write-Host ''
Write-Host ('{0}: {1} passed, {2} failed' -f (Split-Path -Leaf $PSCommandPath), $result.Passed, $result.Failed) `
    -ForegroundColor $(if ($result.Failed -eq 0) { 'Green' } else { 'Red' })
exit $result.Failed
