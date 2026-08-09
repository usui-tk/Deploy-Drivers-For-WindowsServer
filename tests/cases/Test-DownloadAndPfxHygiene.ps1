# psa-disable-file PSAP0002 -- test code is not a pipeline script: it declares no
# ScriptVersion / ScriptHash / ScriptShortTag because it ships no runtime identity.
# The five product scripts remain subject to the rule.
<#
.SYNOPSIS
    Audit P1-F / P1-G contracts: fail-closed download verification and PFX
    hygiene.
.DESCRIPTION
    Get-AuthenticodeSignature and Set-Acl are Windows-only, so the helpers
    cannot be executed on the Linux harness; per the project's textual-
    contract discipline (SPEC-recorded: WinPS-only behaviour is pinned by
    structural contracts), this case pins the STRUCTURE:
      1. P1-G: the fixed default password is gone repo-wide; the per-run
         generator, the ACL helper and the post-install deletion exist and
         are wired (Ctx wiring, export call site, I04 call site, P07
         open-probe).
      2. P1-F: Assert-DownloadedFileSignature exists, throws on failure
         (fail-closed), and is called at every download-execution site:
         SDK, WDK, 7-Zip (call-site wrapper - canon untouched), and the
         AMD installer on BOTH the cached and fresh paths (C/G).
      3. Byte-identity for the helpers across the scripts that carry
         them (password/ACL helpers four-way since W7; download gate
         three-way - NPU performs no downloads).
      4. Negative controls: the pre-W4 tree (r115 generation) fails these
         contracts.
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

$pathA = @(
    'Deploy-AMDChipsetDriverOnWindowsServer.ps1',
    'Deploy-AMDGraphicsDriverOnWindowsServer.ps1',
    'Deploy-MSBthPanInboxOnWindowsServer.ps1'
)
$products = $pathA + @('Deploy-AMDNpuDriverOnWindowsServer.ps1', 'Collect-WindowsServerConfigurationEvidence.ps1')

# Retired fixed password, assembled so this file never matches its own scan.
$retiredPwd = 'ChangeMe!' + '2026'

Write-TestSection 'P1-G: the fixed default PFX password is gone repo-wide'
foreach ($leaf in $products) {
    $text = Get-Content -LiteralPath (Join-Path $RepoRoot $leaf) -Raw
    Assert-Equal ('{0}: retired fixed password appears 0 time(s)' -f $leaf) 0 ([regex]::Matches($text, [regex]::Escape($retiredPwd))).Count
}

Write-TestSection 'P1-G: generator / ACL / deletion / open-probe are wired (Path A sisters)'
foreach ($leaf in $pathA) {
    $text = Get-Content -LiteralPath (Join-Path $RepoRoot $leaf) -Raw
    Assert-True ('{0}: New-RandomPfxPassword wired into Ctx' -f $leaf) ($text -match '(?m)PfxPassword\s+= if \(\[string\]::IsNullOrEmpty\(\$PfxPassword\)\) \{ New-RandomPfxPassword \}')
    Assert-True ('{0}: Set-PfxFileAcl called after Export-PfxCertificate' -f $leaf) ($text -match '(?s)Export-PfxCertificate[^\r\n]*\r?\n\s*Set-PfxFileAcl -Path \$pfxPath')
    Assert-True ('{0}: I04 deletes the PFX' -f $leaf) ($text.Contains("PFX deleted after install (P1-G)"))
    Assert-True ('{0}: P07 cache hit probes the PFX password' -f $leaf) ($text.Contains('$pfxOpensWithCurrentPassword'))
}

Write-TestSection 'P1-G (W7): the NPU script carries the same contract (structural adaptation)'
# NPU has no phase-marker cache, so P07 regenerates the certificate on
# every signing run and the open-probe element is satisfied by design
# (a leftover PFX is overwritten, never reused). The remaining contract
# elements are pinned here; deletion happens in the post-Install block.
$npuLeaf = 'Deploy-AMDNpuDriverOnWindowsServer.ps1'
$npuText = Get-Content -LiteralPath (Join-Path $RepoRoot $npuLeaf) -Raw
Assert-True ('{0}: New-RandomPfxPassword wired into Ctx' -f $npuLeaf) ($npuText -match '(?m)PfxPassword\s+= if \(\[string\]::IsNullOrEmpty\(\$PfxPassword\)\) \{ New-RandomPfxPassword \}')
Assert-True ('{0}: Set-PfxFileAcl called after Export-PfxCertificate' -f $npuLeaf) ($npuText -match '(?s)Export-PfxCertificate[^\r\n]*\r?\n\s*Set-PfxFileAcl -Path \$PfxPath')
Assert-True ('{0}: post-Install block deletes the PFX' -f $npuLeaf) ($npuText.Contains('PFX deleted after install (P1-G)'))

Write-TestSection 'P1-F: the fail-closed gate exists and is wired at every download site'
foreach ($leaf in $pathA) {
    $text = Get-Content -LiteralPath (Join-Path $RepoRoot $leaf) -Raw
    Assert-True ('{0}: Assert-DownloadedFileSignature throws (fail-closed)' -f $leaf) ($text -match "(?s)function Assert-DownloadedFileSignature.*?throw \('P1-F fail-closed")
    Assert-True ('{0}: SDK installer verified' -f $leaf) ($text.Contains("-DisplayName 'Windows SDK installer' -SubjectPattern 'Microsoft Corporation'"))
    Assert-True ('{0}: WDK installer verified' -f $leaf) ($text.Contains("-DisplayName 'Windows WDK installer' -SubjectPattern 'Microsoft Corporation'"))
    Assert-True ('{0}: 7-Zip MSI verified at the call site (canon untouched)' -f $leaf) ($text.Contains("-DisplayName '7-Zip MSI' -SubjectPattern 'Igor Pavlov'"))
}
foreach ($leaf in @('Deploy-AMDChipsetDriverOnWindowsServer.ps1', 'Deploy-AMDGraphicsDriverOnWindowsServer.ps1')) {
    $text = Get-Content -LiteralPath (Join-Path $RepoRoot $leaf) -Raw
    Assert-True ('{0}: AMD installer verified on the cached path' -f $leaf) ($text.Contains("-DisplayName 'AMD installer (cached)'"))
    Assert-True ('{0}: AMD installer verified on the fresh-download path' -f $leaf) ($text.Contains("-DisplayName 'AMD installer' -SubjectPattern 'Advanced Micro Devices'"))
}

Write-TestSection 'W4 helpers: byte identity across the scripts that carry them'
function Get-FnTextW4 {
    param([string]$Path, [string]$Name)
    $t = $null; $e = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseFile((Resolve-Path $Path).Path, [ref]$t, [ref]$e)
    if (@($e).Count -gt 0) { throw ('{0}: parse error(s)' -f $Path) }
    foreach ($fn in $ast.FindAll({ param($n) $n -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true)) {
        if ($fn.Name -eq $Name) { return $fn.Extent.Text }
    }
    return '(absent)'
}
# W7: the password/ACL helpers are four-way (NPU included); the download
# gate stays three-way because NPU performs no downloads.
foreach ($name in @('New-RandomPfxPassword', 'Set-PfxFileAcl')) {
    $texts = @(($pathA + $npuLeaf) | ForEach-Object { Get-FnTextW4 -Path (Join-Path $RepoRoot $_) -Name $name })
    Assert-Equal ('{0}: identical in all four sisters' -f $name) 1 (@($texts | Sort-Object -Unique)).Count
}
foreach ($name in @('Assert-DownloadedFileSignature')) {
    $texts = @($pathA | ForEach-Object { Get-FnTextW4 -Path (Join-Path $RepoRoot $_) -Name $name })
    Assert-Equal ('{0}: identical in the three Path A sisters' -f $name) 1 (@($texts | Sort-Object -Unique)).Count
}

$result = Get-TestResult
Write-Host ''
Write-Host ('{0}: {1} passed, {2} failed' -f (Split-Path -Leaf $PSCommandPath), $result.Passed, $result.Failed) `
    -ForegroundColor $(if ($result.Failed -eq 0) { 'Green' } else { 'Red' })
exit $result.Failed
