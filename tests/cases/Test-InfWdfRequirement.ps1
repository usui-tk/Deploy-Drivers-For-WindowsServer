# psa-disable-file PSAP0002 -- test code is not a pipeline script: it declares no
# ScriptVersion / ScriptHash / ScriptShortTag because it ships no runtime identity.
# The five product scripts remain subject to the rule.
<#
.SYNOPSIS
    Sisters: INF-side WDF requirement extraction.
.DESCRIPTION
    The collector records what framework version the HOST provides. This is
    the other half: what each driver INF ASKS FOR. A package asking for more
    than the runtime provides cannot load, and no signing strategy moves it -
    inf2cat sets the catalog's target OS and does not lower a KMDF
    requirement, so the package catalogues and signs cleanly and then fails
    on the machine. Extracting the requirement lets that be listed before
    anything is installed rather than discovered afterwards.

    Two properties carry most of the risk and are pinned first: version
    ordering must be numeric, and a directive that cannot be found must not
    be reported as absence of WDF.
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
    'ConvertTo-WdfVersionNumber', 'Get-InfWdfRequirement'))

Write-TestSection 'Version ordering is numeric, and the string reading really is wrong'
# Pin the defect before pinning the fix. As strings '1.19' sorts BELOW '1.9',
# which reports a driver needing 1.19 as satisfied by a 1.9 runtime - wrong,
# and wrong in the direction that looks safe.
Assert-True 'string comparison really is wrong here' ('1.19' -lt '1.9')
Assert-True '1.19 ranks above 1.9 numerically' `
    ((ConvertTo-WdfVersionNumber -Version '1.19') -gt (ConvertTo-WdfVersionNumber -Version '1.9'))
Assert-Equal 'an absent version is below every real one' -1 (ConvertTo-WdfVersionNumber -Version '')

Write-TestSection 'A KMDF INF reports the version it declares'
$kmdfInf = @'
[Version]
Signature = "$WINDOWS NT$"
Class = System
[foo_Install.NT.Wdf]
KmdfService = FooSvc, foo_wdfsect
[foo_wdfsect]
KmdfLibraryVersion = 1.15
'@
$r = Get-InfWdfRequirement -Content $kmdfInf
Assert-True 'recognised as a WDF driver' $r.IsWdfDriver
Assert-Equal 'KMDF version extracted' '1.15' $r.KmdfLibraryVersion
Assert-Equal 'no UMDF version claimed' '' $r.UmdfLibraryVersion
Assert-Equal 'one Wdf section counted' 1 $r.WdfSectionCount
Assert-Equal 'no co-installers referenced' '' $r.CoInstallerVersions

Write-TestSection 'A UMDF INF reports independently of KMDF'
$umdfInf = @'
[Version]
Class = Bluetooth
[bar_Install.NT.Wdf]
UmdfLibraryVersion = 2.19
UmdfServiceOrder = WudfRd
'@
$r = Get-InfWdfRequirement -Content $umdfInf
Assert-True 'recognised as a WDF driver' $r.IsWdfDriver
Assert-Equal 'UMDF version extracted' '2.19' $r.UmdfLibraryVersion
Assert-Equal 'KMDF stays empty' '' $r.KmdfLibraryVersion

Write-TestSection 'The highest declared version wins, ordered numerically'
# The whole point: an INF declaring both 1.9 and 1.19 requires 1.19. A
# string-ordered maximum answers 1.9 and reports the package as loadable on
# a runtime that cannot carry it.
$multiInf = @'
[low_Install.NT.Wdf]
KmdfLibraryVersion = 1.9
UmdfLibraryVersion = 2.9
[high_Install.NT.Wdf]
KmdfLibraryVersion=1.19
UmdfLibraryVersion=2.19
'@
$r = Get-InfWdfRequirement -Content $multiInf
Assert-Equal 'KMDF maximum is 1.19, not 1.9' '1.19' $r.KmdfLibraryVersion
Assert-Equal 'UMDF maximum is 2.19, not 2.9' '2.19' $r.UmdfLibraryVersion
Assert-Equal 'both Wdf sections counted' 2 $r.WdfSectionCount

Write-TestSection 'Co-installer file names are decoded back to versions'
$coInf = @'
[Version]
Class = System
[SourceDisksFiles]
WdfCoInstaller01031.dll = 1
[foo_Install.NT.CoInstallers]
AddReg = foo_CoInstaller_AddReg
'@
$r = Get-InfWdfRequirement -Content $coInf
Assert-Equal 'WdfCoInstaller01031.dll decodes to 1.31' '1.31' $r.CoInstallerVersions
# The flag describes what the INF declares it needs from the framework. A
# co-installer names what the package was built against, which is a
# different statement, so it does not by itself set the flag.
Assert-False 'a co-installer alone does not make it a WDF driver' $r.IsWdfDriver

Write-TestSection 'Co-installer versions are de-duplicated and numerically ordered'
$coMultiInf = @'
[SourceDisksFiles]
WdfCoInstaller01031.dll = 1
WdfCoInstaller01009.dll = 1
WdfCoInstaller01031.dll = 1
WdfCoInstaller01011.dll = 1
'@
$r = Get-InfWdfRequirement -Content $coMultiInf
Assert-Equal 'ordered 1.9 < 1.11 < 1.31, duplicates removed' '1.9;1.11;1.31' $r.CoInstallerVersions

Write-TestSection 'A non-WDF INF is reported as such, with empty fields'
$plainInf = @'
[Version]
Signature = "$WINDOWS NT$"
Class = Display
Provider = %AMD%
[Manufacturer]
%AMD% = AMD.Mfg, NTamd64.10.0
'@
$r = Get-InfWdfRequirement -Content $plainInf
Assert-False 'not a WDF driver' $r.IsWdfDriver
Assert-Equal 'no KMDF version' '' $r.KmdfLibraryVersion
Assert-Equal 'no UMDF version' '' $r.UmdfLibraryVersion
Assert-Equal 'no co-installers' '' $r.CoInstallerVersions
Assert-Equal 'no Wdf sections' 0 $r.WdfSectionCount

Write-TestSection 'A version reachable only through a section reference is NOT invented'
# Deliberate limit, pinned so it stays deliberate. The directive is read by
# name; the KmdfService= reference is not followed. An INF that declares the
# section and omits the directive therefore reports a WDF driver with no
# version rather than a guessed one - visible as an empty column instead of
# a wrong number.
$refOnlyInf = @'
[Version]
Class = System
[baz_Install.NT.Wdf]
KmdfService = BazSvc, baz_wdfsect
'@
$r = Get-InfWdfRequirement -Content $refOnlyInf
Assert-True 'the Wdf section still marks it as a WDF driver' $r.IsWdfDriver
Assert-Equal 'and the version is reported as unknown, not guessed' '' $r.KmdfLibraryVersion

Write-TestSection 'Line endings do not change the reading'
# Real INFs are CRLF; a here-string in this file is whatever the checkout
# produced. Both are exercised explicitly so neither can regress silently.
$lines = @($multiInf -split '\r?\n')
$crlf = $lines -join "`r`n"
$lf = $lines -join "`n"
$rCrlf = Get-InfWdfRequirement -Content $crlf
$rLf = Get-InfWdfRequirement -Content $lf
Assert-Equal 'CRLF: KMDF maximum' '1.19' $rCrlf.KmdfLibraryVersion
Assert-Equal 'LF: KMDF maximum' '1.19' $rLf.KmdfLibraryVersion
Assert-Equal 'CRLF and LF agree on the Wdf section count' $rCrlf.WdfSectionCount $rLf.WdfSectionCount

Write-TestSection 'Degenerate input is answered, not thrown at'
Assert-NoThrow 'empty content does not throw' { Get-InfWdfRequirement -Content '' }
$r = Get-InfWdfRequirement -Content ''
Assert-False 'empty content is not a WDF driver' $r.IsWdfDriver
Assert-Equal 'empty content counts no sections' 0 $r.WdfSectionCount

Write-TestSection 'Directive matching is case- and whitespace-tolerant'
$oddInf = @'
[q_Install.nt.wdf]
   kmdflibraryversion   =   1.33
'@
$r = Get-InfWdfRequirement -Content $oddInf
Assert-Equal 'lower-case directive is matched' '1.33' $r.KmdfLibraryVersion
Assert-Equal 'lower-case section header is counted' 1 $r.WdfSectionCount

$result = Get-TestResult
Write-Host ''
Write-Host ('{0}: {1} passed, {2} failed' -f (Split-Path -Leaf $PSCommandPath), $result.Passed, $result.Failed) `
    -ForegroundColor $(if ($result.Failed -eq 0) { 'Green' } else { 'Red' })
exit $result.Failed
