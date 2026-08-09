# psa-disable-file PSAP0002 -- test code is not a pipeline script: it declares no
# ScriptVersion / ScriptHash / ScriptShortTag because it ships no runtime identity.
# The five product scripts remain subject to the rule.
<#
.SYNOPSIS
    Acceptance gate G-01: Custom Kernel Signers support is never claimed for Server.
.DESCRIPTION
    Audit ruling (plan G-01, SPEC D.58.5): no Server SKU is ever recorded as
    supporting Custom Kernel Signers unless Microsoft's feature-specific
    supported-platforms table explicitly lists it - and today that table names
    Windows 11 version 24H2+ only. This case pins:
      1. No product script contains any CustomKernelSigners capability token
         at all (the strictest safe form; relax only with a ruling).
      2. SPEC D.58.5 carries the 24H2-only statement and the
         feature-specific-section-is-authoritative lesson.
      3. The scanner itself catches a violation (embedded negative control).
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

$products = @(
    'Deploy-AMDChipsetDriverOnWindowsServer.ps1',
    'Deploy-AMDGraphicsDriverOnWindowsServer.ps1',
    'Deploy-AMDNpuDriverOnWindowsServer.ps1',
    'Deploy-MSBthPanInboxOnWindowsServer.ps1',
    'Collect-WindowsServerConfigurationEvidence.ps1'
)

function Get-CksTokenHitCount {
    [OutputType([int])]
    param([Parameter()] [AllowEmptyString()] [string]$Text)
    return ([regex]::Matches([string]$Text, 'CustomKernelSigners')).Count
}

Write-TestSection 'No product script carries a CustomKernelSigners capability token'
foreach ($leaf in $products) {
    $text = Get-Content -LiteralPath (Join-Path $RepoRoot $leaf) -Raw
    Assert-Equal ('{0}: CustomKernelSigners token appears 0 time(s)' -f $leaf) 0 (Get-CksTokenHitCount -Text $text)
}

Write-TestSection 'SPEC D.58.5 pins the CKS scope'
$spec = Get-Content -LiteralPath (Join-Path $RepoRoot 'SPEC.md') -Raw
$d585 = [regex]::Match($spec, '(?s)### D\.58\.5.*?(?=### D\.58\.6)')
Assert-True 'SPEC D.58.5 section exists' $d585.Success
if ($d585.Success) {
    Assert-True 'D.58.5 names Windows 11 version 24H2 as the scope' ($d585.Value -match 'Windows 11 version 24H2')
    Assert-True 'D.58.5 states the feature-specific section is authoritative' ($d585.Value -match 'feature-specific\s+section\s+is\s+authoritative')
    Assert-True 'D.58.5 records gate G-01' ($d585.Value -match 'G-01')
}

Write-TestSection 'The scanner catches a violation (negative control)'
$bad = '$Script:CustomKernelSignersSupported = $true  # Server 2025'
Assert-True 'a synthetic violation line is detected' ((Get-CksTokenHitCount -Text $bad) -gt 0)

$result = Get-TestResult
Write-Host ''
Write-Host ('{0}: {1} passed, {2} failed' -f (Split-Path -Leaf $PSCommandPath), $result.Passed, $result.Failed) `
    -ForegroundColor $(if ($result.Failed -eq 0) { 'Green' } else { 'Red' })
exit $result.Failed
