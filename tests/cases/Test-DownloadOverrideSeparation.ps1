# psa-disable-file PSAP0002 -- test code is not a pipeline script: it declares no
# ScriptVersion / ScriptHash / ScriptShortTag because it ships no runtime identity.
# The five product scripts remain subject to the rule.
<#
.SYNOPSIS
    Gate G-09: the download-verification override is separated from
    -Force (audit H-04R / W8) and SourceArtifact evidence is wired.
.DESCRIPTION
    Windows-only cmdlets cannot run on the Linux harness, so this case
    pins the STRUCTURE of the W8 contract:
      1. The retired downgrade phrasing ("Proceeding because -Force was
         supplied") is gone from all five products.
      2. The shared gate takes AllowUnverified and carries no $Force
         reference (AST); it returns a record and the attested
         vocabulary is present.
      3. Chipset/Graphics: the top-level -AllowUnverifiedDownload
         switch exists, is wired into the Ctx, and reaches exactly the
         AMD installer call sites.
      4. The asymmetry is machine-pinned: the Microsoft SDK/WDK and
         7-Zip call sites (all three download-capable sisters) pass NO
         override switch - they stay unconditionally fail-closed.
      5. Write-SourceArtifactEvidence exists in the three
         download-capable sisters with the R5-M02 field set, and every
         gate call site captures the record.
      6. Detector self-checks: a synthetic mutated source makes the
         retired-phrase scan fire.
    Negative control (measured before landing): the pre-W8 tree fails
    the retired-phrase scan, the param/wiring contracts and the
    evidence-function presence.
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
$downloadSisters = @(
    'Deploy-AMDChipsetDriverOnWindowsServer.ps1',
    'Deploy-AMDGraphicsDriverOnWindowsServer.ps1',
    'Deploy-MSBthPanInboxOnWindowsServer.ps1'
)
$amdSisters = @(
    'Deploy-AMDChipsetDriverOnWindowsServer.ps1',
    'Deploy-AMDGraphicsDriverOnWindowsServer.ps1'
)

# Retired phrase, assembled so this file never matches its own scan.
$retiredPhrase = 'Proceeding because ' + '-Force was supplied'

function Get-G09FunctionAst {
    param([string]$Path, [string]$Name)
    $t = $null; $e = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseFile((Resolve-Path $Path).Path, [ref]$t, [ref]$e)
    if (@($e).Count -gt 0) { throw ('{0}: parse error(s)' -f $Path) }
    return $ast.FindAll({ param($n)
        $n -is [System.Management.Automation.Language.FunctionDefinitionAst] -and
        $n.Name -eq $Name }, $true) | Select-Object -First 1
}

Write-TestSection 'G-09: the retired -Force downgrade phrasing is gone (all five products)'
foreach ($p in $products) {
    $text = Get-Content -LiteralPath (Join-Path $RepoRoot $p) -Raw
    Assert-Equal ('{0}: retired phrase appears 0 time(s)' -f $p) 0 ([regex]::Matches($text, [regex]::Escape($retiredPhrase))).Count
}

Write-TestSection 'G-09: retired-phrase detector self-check'
$syntheticBad = 'Write-Caution (''... ' + $retiredPhrase + ' ...'')'
Assert-Equal 'synthetic mutated source: retired phrase detected once' 1 ([regex]::Matches($syntheticBad, [regex]::Escape($retiredPhrase))).Count

Write-TestSection 'G-09: the shared gate carries AllowUnverified and no $Force reference (AST)'
foreach ($p in $downloadSisters) {
    $fn = Get-G09FunctionAst -Path (Join-Path $RepoRoot $p) -Name 'Assert-DownloadedFileSignature'
    Assert-True ('{0}: gate function present' -f $p) ($null -ne $fn)
    $fnText = $fn.Extent.Text
    Assert-True ('{0}: gate param is AllowUnverified' -f $p) ($fnText.Contains('[switch]$AllowUnverified'))
    $forceVars = @($fn.FindAll({ param($n)
        $n -is [System.Management.Automation.Language.VariableExpressionAst] -and
        $n.VariablePath.UserPath -eq 'Force' }, $true))
    Assert-Equal ('{0}: gate body references $Force 0 time(s)' -f $p) 0 $forceVars.Count
    Assert-True ('{0}: attested vocabulary present' -f $p) ($fnText.Contains('operator-attested-unverified'))
    Assert-True ('{0}: gate returns a record' -f $p) ($fnText.Contains('return $record'))
}

Write-TestSection 'G-09: chipset/graphics surface - switch, Ctx wiring, AMD sites'
foreach ($p in $amdSisters) {
    $text = Get-Content -LiteralPath (Join-Path $RepoRoot $p) -Raw
    Assert-True ('{0}: top-level -AllowUnverifiedDownload declared' -f $p) ($text.Contains('[switch]$AllowUnverifiedDownload'))
    Assert-True ('{0}: Ctx wiring present' -f $p) ($text.Contains('AllowUnverifiedDownload = $AllowUnverifiedDownload.IsPresent'))
    Assert-Equal ('{0}: AMD call sites wire the dedicated switch (2 sites)' -f $p) 2 ([regex]::Matches($text, [regex]::Escape('-AllowUnverified:$Ctx.AllowUnverifiedDownload'))).Count
    Assert-Equal ('{0}: no call site wires -Force into the gate' -f $p) 0 ([regex]::Matches($text, [regex]::Escape('Assert-DownloadedFileSignature') + '[^\r\n]*' + [regex]::Escape('-Force'))).Count
}

Write-TestSection 'G-09: NPU/BthPan carry no bypass surface'
foreach ($p in @('Deploy-AMDNpuDriverOnWindowsServer.ps1', 'Deploy-MSBthPanInboxOnWindowsServer.ps1')) {
    $text = Get-Content -LiteralPath (Join-Path $RepoRoot $p) -Raw
    Assert-Equal ('{0}: no top-level -AllowUnverifiedDownload' -f $p) 0 ([regex]::Matches($text, [regex]::Escape('[switch]$AllowUnverifiedDownload'))).Count
}

Write-TestSection 'G-09: Microsoft/7-Zip sites stay unconditionally fail-closed'
foreach ($p in $downloadSisters) {
    $text = Get-Content -LiteralPath (Join-Path $RepoRoot $p) -Raw
    foreach ($dn in @('Windows SDK installer', 'Windows WDK installer', '7-Zip MSI')) {
        $siteLines = @([regex]::Matches($text, '(?m)^[^\r\n]*Assert-DownloadedFileSignature[^\r\n]*' + [regex]::Escape($dn) + '[^\r\n]*'))
        Assert-Equal ('{0}: exactly one {1} site' -f $p, $dn) 1 $siteLines.Count
        Assert-True ('{0}: {1} site passes no override' -f $p, $dn) (-not $siteLines[0].Value.Contains('-AllowUnverified'))
        Assert-True ('{0}: {1} site captures the record' -f $p, $dn) ($siteLines[0].Value.TrimStart().StartsWith('$sigRecord = '))
    }
}

Write-TestSection 'G-09: SourceArtifact evidence function and field set'
foreach ($p in $downloadSisters) {
    $fn = Get-G09FunctionAst -Path (Join-Path $RepoRoot $p) -Name 'Write-SourceArtifactEvidence'
    Assert-True ('{0}: evidence function present' -f $p) ($null -ne $fn)
    $fnText = $fn.Extent.Text
    foreach ($field in @('SchemaVersion', 'RequestedUrl', 'ResolvedUrl', 'RetrievedAtUtc', 'ObservedAtUtc', 'SizeBytes', 'Sha256', 'FormatValidation', 'AuthenticodeStatus', 'SignerSubject', 'SignerThumbprint', 'FailReason', 'Attestation')) {
        Assert-True ('{0}: field {1} present' -f $p, $field) ($fnText.Contains($field))
    }
    $text = Get-Content -LiteralPath (Join-Path $RepoRoot $p) -Raw
    $gateCalls = ([regex]::Matches($text, '(?m)^\s*\$sigRecord = Assert-DownloadedFileSignature ')).Count
    $evCalls = ([regex]::Matches($text, '(?m)^\s*Write-SourceArtifactEvidence -Record \$sigRecord')).Count
    Assert-Equal ('{0}: every gate call is followed by an evidence write' -f $p) $gateCalls $evCalls
}

$result = Get-TestResult
Write-Host ''
Write-Host ('{0}: {1} passed, {2} failed' -f (Split-Path -Leaf $PSCommandPath), $result.Passed, $result.Failed) `
    -ForegroundColor $(if ($result.Failed -eq 0) { 'Green' } else { 'Red' })
exit $result.Failed
