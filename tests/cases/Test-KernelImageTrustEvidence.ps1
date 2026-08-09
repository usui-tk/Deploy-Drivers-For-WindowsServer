# psa-disable-file PSAP0002 -- test code is not a pipeline script: it declares no
# ScriptVersion / ScriptHash / ScriptShortTag because it ships no runtime identity.
# The five product scripts remain subject to the rule.
<#
.SYNOPSIS
    Acceptance gate G-03: kernel trust is classified, never a boolean.
.DESCRIPTION
    Audit ruling (plan G-03, SPEC D.58.3): kernel image trust is recorded as a
    classification plus a trust source, never collapsed into a can-load
    boolean. This case pins the collector's kernel-image-trust.json builder
    (schema keys, no CanLoad token) and fixture-tests the pure classifier
    (ruling Q3), including that LegacyCrossSignedAllowListed is never emitted
    (ruling Q4: allow-list membership cannot be proven yet).
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

function Get-FunctionExtentText {
    [OutputType([string])]
    param([string]$Path, [string]$Name)
    $t = $null; $e = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseFile((Resolve-Path $Path).Path, [ref]$t, [ref]$e)
    foreach ($fn in $ast.FindAll({ param($n) $n -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true)) {
        if ($fn.Name -eq $Name) { return $fn.Extent.Text }
    }
    return ''
}

Write-TestSection 'The builder and the pure classifier exist'
$builderText    = Get-FunctionExtentText -Path $collector -Name 'Get-KernelImageTrustEvidence'
$classifierText = Get-FunctionExtentText -Path $collector -Name 'Get-KernelImageTrustClassification'
Assert-True 'Get-KernelImageTrustEvidence exists' ($builderText.Length -gt 0)
Assert-True 'Get-KernelImageTrustClassification exists' ($classifierText.Length -gt 0)

Write-TestSection 'The evidence schema carries the adjudicated keys and no boolean verdict'
$requiredKeys = @('Path', 'Sha256', 'AuthenticodeStatus', 'PrimarySignerSubject',
                  'EmbeddedSignerSubjects', 'CatalogSignerSubject', 'TrustClassification',
                  'TrustSource', 'ServiceName', 'ServiceState', 'StartType',
                  'LoadedImagePath', 'InDriverStore')
foreach ($k in $requiredKeys) {
    Assert-True ('builder emits key {0}' -f $k) ($builderText -match [regex]::Escape($k))
}
Assert-True 'builder carries no CanLoad-style boolean'    ($builderText.Length -gt 0 -and $builderText -notmatch 'CanLoad')
Assert-True 'classifier carries no CanLoad-style boolean' ($classifierText.Length -gt 0 -and $classifierText -notmatch 'CanLoad')

Write-TestSection 'Pure classifier against the adjudicated mapping (rulings Q3/Q4)'
if ($classifierText) {
    . (Get-ScriptFunctionBlock -Path $collector -Name @('Get-KernelImageTrustClassification'))
    $enum = @('WhcpHdc', 'LegacyCrossSignedAllowListed', 'LegacyCrossSignedNotProven',
              'PrivateOrTestSigned', 'Unsigned', 'Unknown')
    $outputs = @()

    $r = Get-KernelImageTrustClassification -AuthenticodeStatus 'NotSigned' -PrimarySignerSubject ''
    $outputs += $r
    Assert-Equal 'NotSigned -> Unsigned' 'Unsigned' $r.TrustClassification
    Assert-Equal 'NotSigned -> source none' 'none' $r.TrustSource

    $r = Get-KernelImageTrustClassification -AuthenticodeStatus 'Valid' -PrimarySignerSubject 'CN=AMD Chipset Lab' -MatchesProjectCertificate $true
    $outputs += $r
    Assert-Equal 'project cert -> PrivateOrTestSigned' 'PrivateOrTestSigned' $r.TrustClassification
    Assert-Equal 'project cert -> source catalog' 'catalog' $r.TrustSource

    $r = Get-KernelImageTrustClassification -AuthenticodeStatus 'Valid' -PrimarySignerSubject 'CN=Microsoft Windows Hardware Compatibility Publisher, O=Microsoft Corporation'
    $outputs += $r
    Assert-Equal 'WHQL publisher subject -> WhcpHdc' 'WhcpHdc' $r.TrustClassification
    Assert-Equal 'WHQL publisher subject -> source embedded-whql' 'embedded-whql' $r.TrustSource

    $r = Get-KernelImageTrustClassification -AuthenticodeStatus 'Valid' -PrimarySignerSubject 'CN=Contoso Devices' -NestedWhqlPresent $true
    $outputs += $r
    Assert-Equal 'nested WHQL flag -> WhcpHdc' 'WhcpHdc' $r.TrustClassification

    $r = Get-KernelImageTrustClassification -AuthenticodeStatus 'Valid' -PrimarySignerSubject 'CN=Microsoft Windows, O=Microsoft Corporation'
    $outputs += $r
    Assert-Equal 'inbox Microsoft production -> WhcpHdc' 'WhcpHdc' $r.TrustClassification
    Assert-Equal 'inbox Microsoft production -> source embedded-other' 'embedded-other' $r.TrustSource

    $r = Get-KernelImageTrustClassification -AuthenticodeStatus 'Valid' -PrimarySignerSubject 'CN=Contoso Devices' -ChainSubjects @('CN=Contoso Devices', 'CN=Microsoft Code Verification Root')
    $outputs += $r
    Assert-Equal 'cross-signed chain -> LegacyCrossSignedNotProven (never AllowListed)' 'LegacyCrossSignedNotProven' $r.TrustClassification

    $r = Get-KernelImageTrustClassification -AuthenticodeStatus 'Valid' -PrimarySignerSubject 'CN=Contoso Devices'
    $outputs += $r
    Assert-Equal 'plain vendor Authenticode -> PrivateOrTestSigned' 'PrivateOrTestSigned' $r.TrustClassification

    $r = Get-KernelImageTrustClassification -AuthenticodeStatus '' -PrimarySignerSubject ''
    $outputs += $r
    Assert-Equal 'no observation -> Unknown' 'Unknown' $r.TrustClassification

    Write-TestSection 'Ruling Q4 holds across every fixture, and outputs stay inside the enum'
    Assert-Equal 'LegacyCrossSignedAllowListed emitted 0 time(s)' 0 (@($outputs | Where-Object { $_.TrustClassification -eq 'LegacyCrossSignedAllowListed' }).Count)
    Assert-Equal 'every classification is a member of the adjudicated enum' 0 (@($outputs | Where-Object { $enum -notcontains $_.TrustClassification }).Count)
}

$result = Get-TestResult
Write-Host ''
Write-Host ('{0}: {1} passed, {2} failed' -f (Split-Path -Leaf $PSCommandPath), $result.Passed, $result.Failed) `
    -ForegroundColor $(if ($result.Failed -eq 0) { 'Green' } else { 'Red' })
exit $result.Failed
