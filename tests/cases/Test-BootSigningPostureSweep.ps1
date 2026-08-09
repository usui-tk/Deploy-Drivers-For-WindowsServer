# psa-disable-file PSAP0002 -- test code is not a pipeline script: it declares no
# ScriptVersion / ScriptHash / ScriptShortTag because it ships no runtime identity.
# The five product scripts remain subject to the rule.
<#
.SYNOPSIS
    Acceptance gate G-03 (repo-wide) + P1-D classification vocabulary pins.
.DESCRIPTION
    Audit ruling (plan G-03, design 4 / ruling Q6): kernel trust is never a
    boolean. After wave W2 this holds repo-wide, not just in the collector
    evidence builders. This case pins:
      1. The retired can-load boolean name appears 0 times in any product
         script (the token is assembled at run time so this file itself never
         contains it verbatim).
      2. No product script carries any CanLoad-named token at all.
      3. Every sister derives BootSigningPosture and carries all three enum
         literals ('testsigning-active' / 'supplemental-deployed-unverified' /
         'closed').
      4. Test-WhqlCoSignature (Chipset / Graphics / BthPan) emits the P1-D
         Classification vocabulary, and the AllowListed value is never
         assigned (ruling Q4: reserved until an allow-list proof mechanism
         exists).
      5. The scanners catch violations (embedded negative controls).
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

$sisters = @(
    'Deploy-AMDChipsetDriverOnWindowsServer.ps1',
    'Deploy-AMDGraphicsDriverOnWindowsServer.ps1',
    'Deploy-AMDNpuDriverOnWindowsServer.ps1',
    'Deploy-MSBthPanInboxOnWindowsServer.ps1'
)
$products = $sisters + @('Collect-WindowsServerConfigurationEvidence.ps1')

# The retired name, assembled so this test file never matches its own scan.
$retired = 'EffectiveCanLoad' + 'SelfSigned'

function Get-TokenHitCount {
    [OutputType([int])]
    param(
        [Parameter()] [AllowEmptyString()] [string]$Text,
        [Parameter(Mandatory)] [string]$Pattern
    )
    return ([regex]::Matches([string]$Text, $Pattern)).Count
}

Write-TestSection 'G-03 repo-wide: the retired can-load boolean is gone'
foreach ($leaf in $products) {
    $text = Get-Content -LiteralPath (Join-Path $RepoRoot $leaf) -Raw
    Assert-Equal ('{0}: retired boolean name appears 0 time(s)' -f $leaf) 0 (Get-TokenHitCount -Text $text -Pattern ([regex]::Escape($retired)))
}

Write-TestSection 'G-03 repo-wide: no CanLoad-named token in any product script'
foreach ($leaf in $products) {
    $text = Get-Content -LiteralPath (Join-Path $RepoRoot $leaf) -Raw
    Assert-Equal ('{0}: CanLoad token appears 0 time(s)' -f $leaf) 0 (Get-TokenHitCount -Text $text -Pattern ('Can' + 'Load'))
}

Write-TestSection 'Every sister derives BootSigningPosture with the three enum literals'
foreach ($leaf in $sisters) {
    $text = Get-Content -LiteralPath (Join-Path $RepoRoot $leaf) -Raw
    Assert-True ('{0}: assigns $env.BootSigningPosture' -f $leaf) ($text -match '\$env\.BootSigningPosture\s*=')
    foreach ($lit in @("'testsigning-active'", "'supplemental-deployed-unverified'", "'closed'")) {
        Assert-True ('{0}: carries the {1} literal' -f $leaf, $lit) ($text.Contains($lit))
    }
}

Write-TestSection 'P1-D: Test-WhqlCoSignature emits the Classification vocabulary'
$whqlSisters = @(
    'Deploy-AMDChipsetDriverOnWindowsServer.ps1',
    'Deploy-AMDGraphicsDriverOnWindowsServer.ps1',
    'Deploy-MSBthPanInboxOnWindowsServer.ps1'
)
foreach ($leaf in $whqlSisters) {
    $text = Get-Content -LiteralPath (Join-Path $RepoRoot $leaf) -Raw
    foreach ($v in @("'WhcpHdc'", "'LegacyCrossSignedNotProven'", "'PrivateOrTestSigned'", "'Unsigned'", "'Unknown'")) {
        Assert-True ('{0}: Classification value {1} present' -f $leaf, $v) ($text.Contains($v))
    }
    Assert-Equal ('{0}: the AllowListed value is never assigned (ruling Q4)' -f $leaf) 0 `
        (Get-TokenHitCount -Text $text -Pattern "Classification\s*=\s*'LegacyCrossSignedAllowListed'")
}

Write-TestSection 'The scanners catch violations (negative controls)'
$badBoolean = '$env.' + $retired + ' = ($path1Open -or $path2Open)'
Assert-True 'a synthetic retired-boolean line is detected' `
    ((Get-TokenHitCount -Text $badBoolean -Pattern ([regex]::Escape($retired))) -gt 0)
$badAssign = "`$result.Classification = 'LegacyCrossSignedAllowListed'"
Assert-True 'a synthetic AllowListed assignment is detected' `
    ((Get-TokenHitCount -Text $badAssign -Pattern "Classification\s*=\s*'LegacyCrossSignedAllowListed'") -gt 0)

$result = Get-TestResult
Write-Host ''
Write-Host ('{0}: {1} passed, {2} failed' -f (Split-Path -Leaf $PSCommandPath), $result.Passed, $result.Failed) `
    -ForegroundColor $(if ($result.Failed -eq 0) { 'Green' } else { 'Red' })
exit $result.Failed
