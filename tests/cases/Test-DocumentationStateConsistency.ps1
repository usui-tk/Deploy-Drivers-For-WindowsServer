# psa-disable-file PSAP0002 -- test code is not a pipeline script: it declares no
# ScriptVersion / ScriptHash / ScriptShortTag because it ships no runtime identity.
# The five product scripts remain subject to the rule.
<#
.SYNOPSIS
    Acceptance gates G-06 + G-10: the state-bearing documentation matches the
    repository it describes.
.DESCRIPTION
    Audit v3 H-08 (README described the pre-W2 state while What's-new recorded
    W5) and G-10 (maturity labels): documentation state drifts silently unless
    a gate compares it against the tree. This case pins, in both languages:
      1. The stale remediation-status marker is gone and the current-state
         marker is present (Current status reflects the landed waves).
      2. The retired I02 activation alias (inbox CiTool claimed on WS2022) is
         gone; the current activation vocabulary (RefreshPolicy.exe) is
         present.
      3. The -PfxPassword documentation states the per-run CSPRNG contract and
         flags the NPU open item (H-05R) - and the three sister scripts that
         claim it actually define the random-password helper (doc/code
         cross-check).
      4. tests/README's case table has exactly one row per case file on disk
         (measured, never arithmetic).
      5. G-10 maturity vocabulary: no bare 'Stable' maturity label; the
         historically-field-validated / pending-revalidation phrasing is
         present in both languages.
    Forbidden markers are assembled by concatenation so this file never
    matches its own scan. Mutated temp copies provide negative controls.
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

$readmeEn = Join-Path $RepoRoot 'README.md'
$readmeJa = Join-Path $RepoRoot 'README.ja.md'
$textEn   = [System.IO.File]::ReadAllText($readmeEn)
$textJa   = [System.IO.File]::ReadAllText($readmeJa)

# Assembled markers (never literal in this file).
$staleEn   = 'Only the first ' + 'remediation phase'
$staleJa   = ([string][char]0x5B8C + [char]0x4E86) + ([string][char]0x3057 + [char]0x3066) + ([string][char]0x3044 + [char]0x308B) + ([string][char]0x306E + [char]0x306F) + ([string][char]0x6700 + [char]0x521D)
$aliasEn   = '--json` on ' + 'WS2022+'
$aliasJa   = ([string][char]0x4EE5 + [char]0x964D) + ([string][char]0x3067 + [char]0x306F) + ' `' + 'CiTool'
$matStable = '| **' + 'Stable**'
$matStable2 = '| ' + 'Stable,'

function Get-G06MarkerCount {
    [OutputType([int])]
    param(
        [Parameter(Mandatory)] [AllowEmptyString()] [string]$Text,
        [Parameter(Mandatory)] [string]$Marker
    )
    $n = 0; $at = 0
    while (($at = $Text.IndexOf($Marker, $at, [System.StringComparison]::Ordinal)) -ge 0) { $n++; $at++ }
    return $n
}

# ---------------------------------------------------------------------------
Write-TestSection 'G-06: remediation-status markers (both languages)'
Assert-Equal 'stale status marker absent (en)' 0 (Get-G06MarkerCount -Text $textEn -Marker $staleEn)
Assert-Equal 'stale status marker absent (ja)' 0 (Get-G06MarkerCount -Text $textJa -Marker $staleJa)
Assert-True 'current-state marker present (en)' ($textEn.Contains('W1-W8 have landed'))
Assert-True 'current-state marker present (ja)' (($textJa.Contains(('W1' + [char]0x301C + 'W8'))) -and ($textJa.Contains(([string][char]0x7740 + [char]0x5730) + ([string][char]0x6E08 + [char]0x307F))))

Write-TestSection 'G-06: I02 activation vocabulary (both languages)'
Assert-Equal 'retired inbox-CiTool-on-WS2022 alias absent (en)' 0 (Get-G06MarkerCount -Text $textEn -Marker $aliasEn)
Assert-Equal 'retired inbox-CiTool-on-WS2022 alias absent (ja)' 0 (Get-G06MarkerCount -Text $textJa -Marker $aliasJa)
Assert-True 'current activation vocabulary present (en)' ($textEn.Contains('RefreshPolicy.exe'))
Assert-True 'current activation vocabulary present (ja)' ($textJa.Contains('RefreshPolicy.exe'))

Write-TestSection 'G-06: PFX documentation matches the code'
foreach ($pair in @(@{ L = 'en'; T = $textEn }, @{ L = 'ja'; T = $textJa })) {
    $pfxRow = @($pair.T -split "`n" | Where-Object { $_ -match ('^\| +`' + '-PfxPassword') } | Select-Object -First 1)
    Assert-True ('-PfxPassword row exists ({0})' -f $pair.L) ($pfxRow.Count -eq 1)
    if ($pair.L -eq 'en') {
        Assert-Pattern '-PfxPassword row states per-run CSPRNG (en)' 'CSPRNG' ([string]$pfxRow[0])
        Assert-Pattern '-PfxPassword row flags the NPU open item (en)' 'H-05R' ([string]$pfxRow[0])
    } else {
        Assert-Pattern '-PfxPassword row states per-run CSPRNG (ja)' 'CSPRNG' ([string]$pfxRow[0])
        Assert-Pattern '-PfxPassword row flags the NPU open item (ja)' 'H-05R' ([string]$pfxRow[0])
    }
}
foreach ($s in @('Deploy-AMDChipsetDriverOnWindowsServer.ps1',
                 'Deploy-AMDGraphicsDriverOnWindowsServer.ps1',
                 'Deploy-AMDNpuDriverOnWindowsServer.ps1',
                 'Deploy-MSBthPanInboxOnWindowsServer.ps1')) {
    $src = [System.IO.File]::ReadAllText((Join-Path $RepoRoot $s))
    Assert-True ('random-password helper defined in {0}' -f $s) ($src.Contains('function New-RandomPfxPassword'))
}

Write-TestSection 'G-06: tests/README case table matches the case files on disk'
$caseFiles = @(Get-ChildItem -LiteralPath (Join-Path $RepoRoot 'tests/cases') -Filter 'Test-*.ps1')
$tableRows = @([System.IO.File]::ReadAllLines((Join-Path $RepoRoot 'tests/README.md')) |
    Where-Object { $_ -match ('^\| `' + 'Test-') })
Assert-Equal 'one table row per case file' $caseFiles.Count $tableRows.Count
foreach ($cf in $caseFiles) {
    Assert-True ('table row present for {0}' -f $cf.Name) (@($tableRows | Where-Object { $_.Contains($cf.Name) }).Count -eq 1)
}

Write-TestSection 'G-10: maturity vocabulary'
Assert-Equal 'no bare Stable maturity label (en, bold)' 0 (Get-G06MarkerCount -Text $textEn -Marker $matStable)
Assert-Equal 'no bare Stable maturity label (en, plain)' 0 (Get-G06MarkerCount -Text $textEn -Marker $matStable2)
Assert-True 'uplift vocabulary present (en)' ($textEn.Contains('Historically field-validated'))
Assert-True 'revalidation-pending present (en)' ($textEn.Contains('pending revalidation'))
Assert-True 'uplift vocabulary present (ja)' ($textJa.Contains(([string][char]0x904E + [char]0x53BB) + ([string][char]0x5B9F + [char]0x6A5F) + ([string][char]0x691C + [char]0x8A3C) + ([string][char]0x6E08 + [char]0x307F)))
Assert-True 'revalidation-pending present (ja)' ($textJa.Contains(([string][char]0x518D + [char]0x691C) + ([string][char]0x8A3C + [char]0x5F85) + [string][char]0x3061))

# ---------------------------------------------------------------------------
Write-TestSection 'G-06: negative controls (mutated temp copies)'
$tmpDir = Join-Path ([System.IO.Path]::GetTempPath()) ("g06-" + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $tmpDir | Out-Null
try {
    $mutReadme = Join-Path $tmpDir 'mut-readme.md'
    [System.IO.File]::WriteAllText($mutReadme, $textEn + "`n" + $staleEn + ' has landed.' + "`n")
    Assert-True 'a re-inserted stale marker is detected' ((Get-G06MarkerCount -Text ([System.IO.File]::ReadAllText($mutReadme)) -Marker $staleEn) -gt 0)

    $mutRows = @('| `' + 'Test-OnlyOneRow.ps1` | placeholder |')
    Assert-False 'a short case table is detected' ($mutRows.Count -eq $caseFiles.Count)

    $mutMat = Join-Path $tmpDir 'mut-maturity.md'
    [System.IO.File]::WriteAllText($mutMat, ($matStable + ' - validated somewhere. |'))
    Assert-True 'a re-inserted bare Stable label is detected' ((Get-G06MarkerCount -Text ([System.IO.File]::ReadAllText($mutMat)) -Marker $matStable) -gt 0)
} finally {
    Remove-Item -LiteralPath $tmpDir -Recurse -Force -ErrorAction SilentlyContinue
}

$result = Get-TestResult
Write-Host ''
Write-Host ('{0}: {1} passed, {2} failed' -f (Split-Path -Leaf $PSCommandPath), $result.Passed, $result.Failed) `
    -ForegroundColor $(if ($result.Failed -eq 0) { 'Green' } else { 'Red' })
exit $result.Failed
