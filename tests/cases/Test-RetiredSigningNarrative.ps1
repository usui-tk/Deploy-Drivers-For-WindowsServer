# psa-disable-file PSAP0002 -- test code is not a pipeline script: it declares no
# ScriptVersion / ScriptHash / ScriptShortTag because it ships no runtime identity.
# The five product scripts remain subject to the rule.
<#
.SYNOPSIS
    Acceptance gate G-05: the retracted signing narrative stays out of the
    living source and normative documents.
.DESCRIPTION
    Audit v3 H-07 / plan v3 W6: the retracted model (a supplemental policy
    opening kernel-image loading for the project cert while Secure Boot stays
    ON) must not survive in operator-facing help, runtime strings, comments or
    normative docs, in any phrasing. This case scans normalized LOGICAL BLOCKS
    (contiguous comment runs / markdown paragraphs, markup stripped, whitespace
    collapsed) so line wrapping and markdown emphasis cannot split a phrase
    past a line-based scan. Historical release notes (the What's-new sections)
    are excluded; retraction/negation contexts are recognized and legal.
    Forbidden tokens are assembled by concatenation so this file never matches
    its own scan. Built-in synthetic positives keep the scanner honest
    (wrapped-line and markup-split variants must be caught); a mutated temp
    copy provides the file-level negative control.
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

# ---------------------------------------------------------------------------
# Forbidden vocabulary, assembled at run time (never literal in this file).
# ---------------------------------------------------------------------------
$kms      = 'kernel' + '-mode signer'
$reSbKeep = 'keeps? Secure Boot ' + '(ON|ENABLED)'
$reDwsp   = 'default WDAC ' + 'supplemental policy'
$reHvci   = ('rejects test' + '-signed kernel images') + '|' + ('test-signed kernel images ' + 'will not load')
$reDrop   = '(silently ' + 'dropped)|(being ' + 'dropped at boot)'
$reKmsA1  = 'cert\w* as (an? )?(allowed |additional )?' + $kms
$reKmsA2  = '(allowlists?|adds?|adding) (the |its |our |this )?[^.;]{0,60}' + $kms
$reJaKms  = 'kernel-mode ' + [char]0x7F72 + [char]0x540D + [char]0x8005   # 'kernel-mode <shomeisha>'
# Legal contexts: retraction records, negations, and the WHQL-subset truth.
$reLegal  = '(?i)retract|was wrong|superseded|removed|retired|does not (authorize|grant)|' +
            ('no ' + $kms) + '|' + ('needs no ' + $kms) + '|' + [char]0x64A4 + [char]0x56DE
$reSbCtx  = '(?i)supplemental|self-signed|certificate'
$reWhql   = '(?i)WHQL|SkipNonCosigned'
$reDropCtx = '(?i)testsigning|Secure Boot'

function Get-G05NormalizedText {
    [OutputType([string])]
    param([Parameter(Mandatory)] [AllowEmptyString()] [string]$Raw)
    $t = $Raw -replace '[`*]', ''
    $t = $t -replace '(?m)^\s*#+\s?', ' '
    return ($t -replace '\s+', ' ').Trim()
}

function Get-G05LogicalBlock {
    <# Blocks: for .ps1, contiguous comment runs are one block and every code
       line is its own block; for .md, blank-line-separated paragraphs are
       blocks, and the What's-new (release-history) section is skipped. #>
    [OutputType([object[]])]
    param(
        [Parameter(Mandatory)] [string]$Path,
        [Parameter(Mandatory)] [ValidateSet('ps1','md')] [string]$Kind
    )
    $lines  = [System.IO.File]::ReadAllLines((Resolve-Path -LiteralPath $Path).Path)
    $blocks = [System.Collections.ArrayList]::new()
    $buf    = [System.Text.StringBuilder]::new()
    $bufAt  = 0
    $skip   = $false
    $whatsNewEn = '## What' + "'" + 's new'
    $whatsNewJa = '## ' + [char]0x65B0 + [char]0x7740 + [char]0x60C5 + [char]0x5831
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $ln = $lines[$i]
        if ($Kind -eq 'md') {
            if ($ln.StartsWith('## ')) {
                $skip = ($ln.Trim() -eq $whatsNewEn) -or ($ln.Trim() -eq $whatsNewJa)
            }
            if ($skip) { continue }
            if ([string]::IsNullOrWhiteSpace($ln)) {
                if ($buf.Length -gt 0) {
                    [void]$blocks.Add([pscustomobject]@{ Line = $bufAt; Text = (Get-G05NormalizedText -Raw $buf.ToString()) })
                    [void]$buf.Clear()
                }
            } else {
                if ($buf.Length -eq 0) { $bufAt = $i + 1 }
                [void]$buf.Append($ln).Append(' ')
            }
        } else {
            $isComment = $ln.TrimStart().StartsWith('#')
            if ($isComment) {
                if ($buf.Length -eq 0) { $bufAt = $i + 1 }
                [void]$buf.Append($ln).Append(' ')
            } else {
                if ($buf.Length -gt 0) {
                    [void]$blocks.Add([pscustomobject]@{ Line = $bufAt; Text = (Get-G05NormalizedText -Raw $buf.ToString()) })
                    [void]$buf.Clear()
                }
                if (-not [string]::IsNullOrWhiteSpace($ln)) {
                    [void]$blocks.Add([pscustomobject]@{ Line = $i + 1; Text = (Get-G05NormalizedText -Raw $ln) })
                }
            }
        }
    }
    if ($buf.Length -gt 0) {
        [void]$blocks.Add([pscustomobject]@{ Line = $bufAt; Text = (Get-G05NormalizedText -Raw $buf.ToString()) })
    }
    return $blocks.ToArray()
}

function Get-G05BlockFamily {
    [OutputType([string[]])]
    param([Parameter(Mandatory)] [AllowEmptyString()] [string]$Text)
    $fams = [System.Collections.ArrayList]::new()
    $legal = $Text -match $reLegal # psa-disable-line PSA2003 -- pattern variables are non-null file-scope constants assigned unconditionally above
    if (-not $legal) {
        if (($Text -match $reSbKeep) -and ($Text -match $reSbCtx) -and ($Text -notmatch $reWhql)) { [void]$fams.Add('F1') } # psa-disable-line PSA2003 -- pattern variables are non-null file-scope constants assigned unconditionally above
        if (($Text -match $reKmsA1) -or ($Text -match $reKmsA2)) { [void]$fams.Add('F2') } # psa-disable-line PSA2003 -- pattern variables are non-null file-scope constants assigned unconditionally above
        if ($Text -match $reJaKms) { [void]$fams.Add('F2ja') } # psa-disable-line PSA2003 -- pattern variables are non-null file-scope constants assigned unconditionally above
        if (($Text -match $reDrop) -and ($Text -match $reDropCtx)) { [void]$fams.Add('F5') } # psa-disable-line PSA2003 -- pattern variables are non-null file-scope constants assigned unconditionally above
    }
    if ($Text -match ('(?i)' + $reDwsp)) { [void]$fams.Add('F3') }
    if ($Text -match $reHvci) { [void]$fams.Add('F4') } # psa-disable-line PSA2003 -- pattern variables are non-null file-scope constants assigned unconditionally above
    return $fams.ToArray()
}

function Get-G05Finding {
    [OutputType([string[]])]
    param(
        [Parameter(Mandatory)] [string]$Path,
        [Parameter(Mandatory)] [ValidateSet('ps1','md')] [string]$Kind
    )
    $out = [System.Collections.ArrayList]::new()
    foreach ($b in (Get-G05LogicalBlock -Path $Path -Kind $Kind)) {
        foreach ($f in (Get-G05BlockFamily -Text $b.Text)) {
            [void]$out.Add(('{0}:{1} {2}' -f (Split-Path -Leaf $Path), $b.Line, $f))
        }
    }
    return $out.ToArray()
}

# ---------------------------------------------------------------------------
# 1) The live tree is clean.
# ---------------------------------------------------------------------------
Write-TestSection 'G-05: living source and normative docs carry no retired narrative'
$scanSet = @(
    @{ P = 'Deploy-AMDChipsetDriverOnWindowsServer.ps1';  K = 'ps1' },
    @{ P = 'Deploy-AMDGraphicsDriverOnWindowsServer.ps1'; K = 'ps1' },
    @{ P = 'Deploy-AMDNpuDriverOnWindowsServer.ps1';      K = 'ps1' },
    @{ P = 'Deploy-MSBthPanInboxOnWindowsServer.ps1';     K = 'ps1' },
    @{ P = 'Collect-WindowsServerConfigurationEvidence.ps1'; K = 'ps1' },
    @{ P = 'README.md';       K = 'md' },
    @{ P = 'README.ja.md';    K = 'md' },
    @{ P = 'SPEC.md';         K = 'md' },
    @{ P = 'TESTING.md';      K = 'md' },
    @{ P = 'tests/README.md'; K = 'md' }
)
foreach ($s in $scanSet) {
    $findings = @(Get-G05Finding -Path (Join-Path $RepoRoot $s.P) -Kind $s.K)
    if ($findings.Count -gt 0) {
        Write-Host ('        findings: {0}' -f ($findings -join '; ')) -ForegroundColor Yellow
    }
    Assert-Equal ('no retired-narrative block in {0}' -f $s.P) 0 $findings.Count
}

# ---------------------------------------------------------------------------
# 2) Built-in synthetic controls: the scanner itself must catch wrapped and
#    markup-split phrasings, and must NOT flag the legal WHQL-subset truth.
# ---------------------------------------------------------------------------
Write-TestSection 'G-05: synthetic positives and negatives (scanner honesty)'
$tmpDir = Join-Path ([System.IO.Path]::GetTempPath()) ("g05-" + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $tmpDir | Out-Null
try {
    $synWrapped = Join-Path $tmpDir 'syn-wrapped.md'
    # the phrase is split across two source lines on purpose
    [System.IO.File]::WriteAllLines($synWrapped, @('I02 uses the default WDAC', ('supplemental' + ' policy path.')))
    Assert-True 'wrapped-line phrasing is caught (F3)' ((@(Get-G05Finding -Path $synWrapped -Kind 'md') -match 'F3').Count -gt 0)

    $synMarkup = Join-Path $tmpDir 'syn-markup.md'
    [System.IO.File]::WriteAllLines($synMarkup, @(('the **default** `WDAC` supplemental' + ' policy path')))
    Assert-True 'markup-split phrasing is caught (F3)' ((@(Get-G05Finding -Path $synMarkup -Kind 'md') -match 'F3').Count -gt 0)

    $synClaim = Join-Path $tmpDir 'syn-claim.md'
    [System.IO.File]::WriteAllLines($synClaim, @(
        ('the supplemental policy keeps Secure Boot ' + 'ON while our self-signed cert loads kernel drivers')))
    Assert-True 'a Secure-Boot-benefit claim is caught (F1)' ((@(Get-G05Finding -Path $synClaim -Kind 'md') -match 'F1').Count -gt 0)

    $synLegal = Join-Path $tmpDir 'syn-legal.md'
    [System.IO.File]::WriteAllLines($synLegal, @(
        ('pass -SkipNonCosignedDrivers to keep Secure Boot ' + 'ON and install only the WHQL co-signed subset')))
    Assert-Equal 'the WHQL-subset truth is NOT flagged' 0 @(Get-G05Finding -Path $synLegal -Kind 'md').Count

    $synRetract = Join-Path $tmpDir 'syn-retraction.md'
    [System.IO.File]::WriteAllLines($synRetract, @(
        ('the claim that the policy authorises the cert as a ' + $kms + ' was wrong, and it has been retracted')))
    Assert-Equal 'a retraction record is NOT flagged' 0 @(Get-G05Finding -Path $synRetract -Kind 'md').Count

    # File-level negative control: a mutated temp .ps1 with retired phrasing.
    $mut = Join-Path $tmpDir 'mut-retired.ps1'
    [System.IO.File]::WriteAllLines($mut, @(
        ('# The supplemental policy adds its self-signed cert as a ' + $kms + '.'),
        ("Write-Host 'testsigning is silently " + "dropped at next boot when Secure Boot is on.'"),
        ("Write-Host 'HVCI rejects test" + "-signed kernel images.'")
    ))
    $mutFindings = @(Get-G05Finding -Path $mut -Kind 'ps1')
    Assert-True 'mutated copy: F2 named' (($mutFindings -match 'F2').Count -gt 0)
    Assert-True 'mutated copy: F5 named' (($mutFindings -match 'F5').Count -gt 0)
    Assert-True 'mutated copy: F4 named' (($mutFindings -match 'F4').Count -gt 0)
} finally {
    Remove-Item -LiteralPath $tmpDir -Recurse -Force -ErrorAction SilentlyContinue
}

$result = Get-TestResult
Write-Host ''
Write-Host ('{0}: {1} passed, {2} failed' -f (Split-Path -Leaf $PSCommandPath), $result.Passed, $result.Failed) `
    -ForegroundColor $(if ($result.Failed -eq 0) { 'Green' } else { 'Red' })
exit $result.Failed
