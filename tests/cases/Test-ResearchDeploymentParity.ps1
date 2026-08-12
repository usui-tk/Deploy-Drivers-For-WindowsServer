# psa-disable-file PSAP0002 -- test code is not a pipeline script: it declares no
# ScriptVersion / ScriptHash / ScriptShortTag because it ships no runtime identity.
# The five product scripts remain subject to the rule.
<#
.SYNOPSIS
    Gate G-20: research/deployment inventory parity tooling (audit
    R5-H05 / W11).
.DESCRIPTION
    Runs the reconciliation tool against the committed synthetic
    fixtures and pins:
      1. Tool presence and version line.
      2. Positive set: rc=0 and the classification counts, verbatim
         (Direct 3 / Variant 1 / NormalizedName 1 / ResearchOnly 1 /
         Unexplained 0); the variant row's evidence ends in .inf2,
         proving the suffix-versioned, UTF-16LE-no-BOM read path.
      3. Negative set (built-in negative control): rc=1 and the
         unexplained row is NAMED in the report.
      4. Allowlist set: rc returns to 0 and the same row is typed
         ExplainedDeploymentOnly carrying the operator Reason.
      5. Report schema fields (SchemaVersion / input SHA-256 pins /
         ExitCriterion block).
      6. Real-baseline smoke: the committed research CSV parses with
         more than 600 rows (no field data involved).
    The user-provided field evidence stays INPUT ONLY; every fixture
    here is synthetic and freshly authored.
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

$toolPath = Join-Path $RepoRoot 'tools/inventory-reconciliation/Compare-ResearchDeploymentInventory.ps1'
$fixDir   = Join-Path $RepoRoot 'tests/fixtures/inventory-reconciliation'
$research = Join-Path $fixDir 'research-mini.csv'
$depPos   = Join-Path $fixDir 'deployment-mini.csv'
$depNeg   = Join-Path $fixDir 'deployment-negative.csv'
$allow    = Join-Path $fixDir 'known-explanations-mini.json'
$extRoot  = Join-Path $fixDir 'extraction-mini'
$tmpDir   = Join-Path ([System.IO.Path]::GetTempPath()) ('g20-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $tmpDir -Force | Out-Null

function Invoke-G20Tool {
    param([string[]]$ToolArgs)
    & pwsh -NoProfile -File $toolPath @ToolArgs *> $null
    return $LASTEXITCODE
}

try {
    Write-TestSection 'G-20: tool presence and version'
    Assert-True 'reconciliation tool present' (Test-Path -LiteralPath $toolPath)
    $toolText = Get-Content -LiteralPath $toolPath -Raw
    Assert-True 'tool version 1.0.0 declared' ($toolText.Contains("`$Script:ToolVersion = '1.0.0'"))

    Write-TestSection 'G-20: positive fixtures - exit criterion satisfied, counts verbatim'
    $posReport = Join-Path $tmpDir 'pos.json'
    $rc = Invoke-G20Tool -ToolArgs @('-ResearchInventory', $research, '-DeploymentInventory', $depPos, '-ExtractionRoot', $extRoot, '-OutputPath', $posReport)
    Assert-Equal 'positive run rc' 0 $rc
    $pos = Get-Content -LiteralPath $posReport -Raw | ConvertFrom-Json
    Assert-Equal 'MatchedDirect count' 3 ([int]$pos.Counts.MatchedDirect)
    Assert-Equal 'MatchedVariant count' 1 ([int]$pos.Counts.MatchedVariant)
    Assert-Equal 'MatchedNormalizedName count' 1 ([int]$pos.Counts.MatchedNormalizedName)
    Assert-Equal 'ResearchOnly count' 1 ([int]$pos.Counts.ResearchOnly)
    Assert-Equal 'DeploymentOnly count' 0 ([int]$pos.Counts.DeploymentOnly)
    Assert-True 'ExitCriterion satisfied' ([bool]$pos.ExitCriterion.Satisfied)
    $variantRow = @($pos.DeploymentRows | Where-Object { $_.Classification -eq 'MatchedVariant' })
    Assert-Equal 'exactly one variant row' 1 $variantRow.Count
    Assert-True 'variant evidence is a suffix-versioned INF (.inf2)' ($variantRow[0].Evidence.EndsWith('.inf2'))

    Write-TestSection 'G-20: report schema'
    Assert-Equal 'SchemaVersion' '1.0' ([string]$pos.SchemaVersion)
    Assert-True 'research input SHA-256 pinned' (-not [string]::IsNullOrWhiteSpace([string]$pos.ResearchInventory.Sha256))
    Assert-True 'deployment input SHA-256 pinned' (-not [string]::IsNullOrWhiteSpace([string]$pos.DeploymentInventory.Sha256))
    Assert-Equal 'ExitCriterion name' 'UnexplainedDeploymentOnly' ([string]$pos.ExitCriterion.Name)

    Write-TestSection 'G-20: built-in negative control - unexplained row is named, rc=1'
    $negReport = Join-Path $tmpDir 'neg.json'
    $rc = Invoke-G20Tool -ToolArgs @('-ResearchInventory', $research, '-DeploymentInventory', $depNeg, '-ExtractionRoot', $extRoot, '-OutputPath', $negReport)
    Assert-Equal 'negative run rc' 1 $rc
    $neg = Get-Content -LiteralPath $negReport -Raw | ConvertFrom-Json
    Assert-Equal 'UnexplainedDeploymentOnly' 1 ([int]$neg.ExitCriterion.UnexplainedDeploymentOnly)
    $named = @($neg.DeploymentRows | Where-Object { $_.Classification -eq 'DeploymentOnly' })
    Assert-Equal 'exactly one DeploymentOnly row' 1 $named.Count
    Assert-Equal 'the unexplained row is named' 'zeta.inf' ([string]$named[0].InfName)

    Write-TestSection 'G-20: allowlist adjudication path'
    $allowReport = Join-Path $tmpDir 'allow.json'
    $rc = Invoke-G20Tool -ToolArgs @('-ResearchInventory', $research, '-DeploymentInventory', $depNeg, '-ExtractionRoot', $extRoot, '-KnownExplanations', $allow, '-OutputPath', $allowReport)
    Assert-Equal 'allowlist run rc' 0 $rc
    $adj = Get-Content -LiteralPath $allowReport -Raw | ConvertFrom-Json
    $explained = @($adj.DeploymentRows | Where-Object { $_.Classification -eq 'ExplainedDeploymentOnly' })
    Assert-Equal 'the row is now ExplainedDeploymentOnly' 1 $explained.Count
    Assert-True 'the adjudication Reason is carried as evidence' ($explained[0].Evidence.Contains('adjudicated'))

    Write-TestSection 'G-20: real-baseline smoke (published research inventory only)'
    $baseline = Join-Path $RepoRoot 'tools/amd-chipset-driver-research/public/inventory/amd-chipset-driver-inventory.csv'
    Assert-True 'published research inventory present' (Test-Path -LiteralPath $baseline)
    $rows = @(Import-Csv -LiteralPath $baseline)
    Assert-True ('published research inventory parses with more than 600 rows (measured: {0})' -f $rows.Count) ($rows.Count -gt 600)
} finally {
    Remove-Item -LiteralPath $tmpDir -Recurse -Force -ErrorAction SilentlyContinue
}

$result = Get-TestResult
Write-Host ''
Write-Host ('{0}: {1} passed, {2} failed' -f (Split-Path -Leaf $PSCommandPath), $result.Passed, $result.Failed) `
    -ForegroundColor $(if ($result.Failed -eq 0) { 'Green' } else { 'Red' })
exit $result.Failed
