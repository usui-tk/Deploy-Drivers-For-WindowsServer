# psa-disable-file PSAP0002 -- standalone read-only analysis tool, not a
# deployment pipeline script: it carries no runtime identity trio and is
# versioned via the tool-local CHANGELOG. The five product scripts remain
# subject to the rule.
<#
.SYNOPSIS
    Research/deployment inventory reconciliation (audit R5-H05 / W11).
.DESCRIPTION
    Joins the published research inventory (25 AMD chipset
    releases) against a deployment run's inf_inventory.csv and classifies
    every deployment row:

        MatchedDirect          name+version found in the research baseline
        MatchedVariant         version found on a suffix-versioned CAB
                               entry (name.infN) under -ExtractionRoot
        MatchedNormalizedName  name matches only after separator
                               normalization ('-' vs '_'); version matches
        ExplainedDeploymentOnly listed in -KnownExplanations (requires an
                               operator adjudication Reason)
        DeploymentOnly         nothing explains the row

    Research rows with no deployment counterpart are reported as
    ResearchOnly (informational: a deployment run sees one release, the
    research baseline sees 25).

    Exit criterion (gate-friendly): rc=0 iff UnexplainedDeploymentOnly=0.
    Scope: METADATA-level parity (normalized name + DriverVer version
    component). Content-hash confirmation is an optional operator step
    documented in the tool README.

    Normalization rules codified from the 2026-08-09 reconciliation
    session: names are lowercased and '-'/'_' unified; suffix-versioned
    entries match '\.inf\d+$'; the version key is the version component
    of the composite DriverVer (segment after the last comma); INF reads
    under -ExtractionRoot tolerate UTF-16LE without BOM.
.NOTES
    Tool version 1.0.0 - see CHANGELOG.md next to this script.
#>
[CmdletBinding()]
[OutputType([int])]
param(
    [Parameter(Mandatory)] [string]$ResearchInventory,
    [Parameter(Mandatory)] [string]$DeploymentInventory,
    [Parameter()] [string]$ExtractionRoot = '',
    [Parameter(Mandatory)] [string]$OutputPath,
    [Parameter()] [string]$KnownExplanations = ''
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$Script:ToolVersion = '1.0.0'

function Get-NormalizedInfName {
    param([Parameter(Mandatory)] [string]$Name)
    $leaf = [System.IO.Path]::GetFileName($Name).ToLowerInvariant()
    # Fold suffix-versioned CAB entries (name.inf2, name.inf11, ...) onto
    # their base INF name and remember the variant index.
    $variantIndex = 0
    $m = [regex]::Match($leaf, '^(?<base>.+\.inf)(?<idx>\d+)$')
    if ($m.Success) {
        $leaf = $m.Groups['base'].Value
        $variantIndex = [int]$m.Groups['idx'].Value
    }
    [pscustomobject]@{
        RawLower     = $leaf
        Normalized   = ($leaf -replace '-', '_')
        VariantIndex = $variantIndex
    }
}

function Get-VersionKey {
    param([string]$DriverVer)
    if ([string]::IsNullOrWhiteSpace($DriverVer)) { return '' }
    $s = $DriverVer.Trim()
    $comma = $s.LastIndexOf(',')
    if ($comma -ge 0) { $s = $s.Substring($comma + 1) }
    return $s.Trim()
}

function Read-InfTextTolerant {
    # Reads an INF as text, tolerating UTF-16LE WITHOUT a BOM (observed in
    # real AMD Data1.cab payloads) alongside BOM-carrying and ASCII files.
    param([Parameter(Mandatory)] [string]$Path)
    $bytes = [System.IO.File]::ReadAllBytes($Path)
    if ($bytes.Length -ge 2 -and $bytes[0] -eq 0xFF -and $bytes[1] -eq 0xFE) {
        return [System.Text.Encoding]::Unicode.GetString($bytes, 2, $bytes.Length - 2)
    }
    if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
        return [System.Text.Encoding]::UTF8.GetString($bytes, 3, $bytes.Length - 3)
    }
    # Heuristic: a text file whose even positions are ASCII and odd
    # positions are NUL is UTF-16LE without BOM.
    $probe = [Math]::Min(64, $bytes.Length)
    $nulOdd = 0
    for ($i = 1; $i -lt $probe; $i += 2) { if ($bytes[$i] -eq 0) { $nulOdd++ } }
    if ($probe -ge 8 -and $nulOdd -ge (($probe / 2) - 2)) {
        return [System.Text.Encoding]::Unicode.GetString($bytes)
    }
    return [System.Text.Encoding]::UTF8.GetString($bytes)
}

function Get-InfDriverVer {
    param([Parameter(Mandatory)] [string]$Path)
    $text = Read-InfTextTolerant -Path $Path
    $m = [regex]::Match($text, '(?im)^\s*DriverVer\s*=\s*(?<v>[^\r\n;]+)')
    if ($m.Success) { return $m.Groups['v'].Value.Trim() }
    return ''
}

Write-Host ('Compare-ResearchDeploymentInventory {0}' -f $Script:ToolVersion)

# ---- load inputs ----------------------------------------------------------
foreach ($p in @($ResearchInventory, $DeploymentInventory)) {
    if (-not (Test-Path -LiteralPath $p)) { throw ('input not found: {0}' -f $p) }
}
$research = @(Import-Csv -LiteralPath $ResearchInventory)
$deploy   = @(Import-Csv -LiteralPath $DeploymentInventory)
if ($research.Count -eq 0) { throw 'research inventory is empty' }
if ($deploy.Count -eq 0) { throw 'deployment inventory is empty' }
foreach ($col in @('InfRelativePath', 'DriverVersion')) {
    if (-not ($research[0].PSObject.Properties.Name -contains $col)) {
        throw ('research inventory lacks column {0}' -f $col)
    }
}
foreach ($col in @('InfName', 'DriverVer')) {
    if (-not ($deploy[0].PSObject.Properties.Name -contains $col)) {
        throw ('deployment inventory lacks column {0}' -f $col)
    }
}

$explanations = @()
if ($KnownExplanations) {
    $explanations = @((Get-Content -LiteralPath $KnownExplanations -Raw | ConvertFrom-Json))
    foreach ($e in $explanations) {
        if ([string]::IsNullOrWhiteSpace([string]$e.Reason)) {
            throw 'every KnownExplanations entry requires an operator adjudication Reason'
        }
    }
}

# ---- research indexes -----------------------------------------------------
$rawIndex  = @{}   # rawLower|version  -> research row
$normIndex = @{}   # normalized|version -> research row
foreach ($r in $research) {
    $n = Get-NormalizedInfName -Name $r.InfRelativePath
    $v = Get-VersionKey -DriverVer $r.DriverVersion
    $rawIndex[($n.RawLower + '|' + $v)]    = $r
    $normIndex[($n.Normalized + '|' + $v)] = $r
}

# ---- variant index from the extraction tree -------------------------------
$variantIndexMap = @{}   # normalized|version -> variant file path
if ($ExtractionRoot) {
    if (-not (Test-Path -LiteralPath $ExtractionRoot)) {
        throw ('extraction root not found: {0}' -f $ExtractionRoot)
    }
    $variantFiles = @(Get-ChildItem -LiteralPath $ExtractionRoot -Recurse -File |
        Where-Object { $_.Name -match '\.inf\d+$' })
    foreach ($vf in $variantFiles) {
        $n = Get-NormalizedInfName -Name $vf.Name
        $dv = Get-InfDriverVer -Path $vf.FullName
        $v = Get-VersionKey -DriverVer $dv
        if ($v) { $variantIndexMap[($n.Normalized + '|' + $v)] = $vf.FullName }
    }
    Write-Host ('Variant scan: {0} suffix-versioned INF(s) under {1}' -f $variantFiles.Count, $ExtractionRoot)
}

# ---- classification -------------------------------------------------------
$rows = New-Object System.Collections.Generic.List[object]
$matchedResearchKeys = @{}
foreach ($d in $deploy) {
    $n = Get-NormalizedInfName -Name $d.InfName
    $v = Get-VersionKey -DriverVer $d.DriverVer
    $rawKey  = $n.RawLower + '|' + $v
    $normKey = $n.Normalized + '|' + $v
    $class = ''
    $evidence = ''
    if ($rawIndex.ContainsKey($rawKey)) {
        $class = 'MatchedDirect'
        $evidence = [string]$rawIndex[$rawKey].InfRelativePath
        $matchedResearchKeys[$rawKey] = $true
    } elseif ($variantIndexMap.ContainsKey($normKey)) {
        $class = 'MatchedVariant'
        $evidence = [string]$variantIndexMap[$normKey]
    } elseif ($normIndex.ContainsKey($normKey)) {
        $class = 'MatchedNormalizedName'
        $rrow = $normIndex[$normKey]
        $evidence = [string]$rrow.InfRelativePath
        $rn = Get-NormalizedInfName -Name $rrow.InfRelativePath
        $matchedResearchKeys[($rn.RawLower + '|' + $v)] = $true
    } else {
        $exp = $explanations | Where-Object {
            ((Get-NormalizedInfName -Name ([string]$_.InfName)).Normalized -eq $n.Normalized) -and
            ((Get-VersionKey -DriverVer ([string]$_.DriverVer)) -eq $v)
        } | Select-Object -First 1
        if ($exp) {
            $class = 'ExplainedDeploymentOnly'
            $evidence = [string]$exp.Reason
        } else {
            $class = 'DeploymentOnly'
        }
    }
    $rows.Add([pscustomobject]@{
        InfName        = [string]$d.InfName
        NormalizedName = $n.Normalized
        VersionKey     = $v
        Classification = $class
        Evidence       = $evidence
    })
}

$researchOnly = New-Object System.Collections.Generic.List[object]
foreach ($r in $research) {
    $n = Get-NormalizedInfName -Name $r.InfRelativePath
    $v = Get-VersionKey -DriverVer $r.DriverVersion
    if (-not $matchedResearchKeys.ContainsKey(($n.RawLower + '|' + $v))) {
        $researchOnly.Add([pscustomobject]@{
            InfRelativePath = [string]$r.InfRelativePath
            VersionKey      = $v
        })
    }
}

# ---- report ---------------------------------------------------------------
$counts = [ordered]@{}
foreach ($cls in @('MatchedDirect', 'MatchedVariant', 'MatchedNormalizedName', 'ExplainedDeploymentOnly', 'DeploymentOnly')) {
    $counts.Add($cls, @($rows | Where-Object { $_.Classification -eq $cls }).Count)
}
$counts.Add('ResearchOnly', $researchOnly.Count)
$unexplained = @($rows | Where-Object { $_.Classification -eq 'DeploymentOnly' }).Count

$report = [ordered]@{
    SchemaVersion       = '1.0'
    ToolVersion         = $Script:ToolVersion
    GeneratedAtUtc      = [DateTime]::UtcNow.ToString('o')
    ResearchInventory   = [ordered]@{
        Path   = (Resolve-Path -LiteralPath $ResearchInventory).Path
        Sha256 = (Get-FileHash -LiteralPath $ResearchInventory -Algorithm SHA256).Hash.ToLowerInvariant()
        Rows   = $research.Count
    }
    DeploymentInventory = [ordered]@{
        Path   = (Resolve-Path -LiteralPath $DeploymentInventory).Path
        Sha256 = (Get-FileHash -LiteralPath $DeploymentInventory -Algorithm SHA256).Hash.ToLowerInvariant()
        Rows   = $deploy.Count
    }
    Counts              = $counts
    # pwsh 7.4 quirk: wrapping a List[object] directly in @() throws
    # 'Argument types do not match'; .ToArray() is the reliable form.
    DeploymentRows      = $rows.ToArray()
    ResearchOnlyRows    = $researchOnly.ToArray()
    ExitCriterion       = [ordered]@{
        Name                      = 'UnexplainedDeploymentOnly'
        UnexplainedDeploymentOnly = $unexplained
        Satisfied                 = ($unexplained -eq 0)
    }
}
$report | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $OutputPath -Encoding UTF8

Write-Host ('Counts : ' + (($counts.Keys | ForEach-Object { '{0}={1}' -f $_, $counts[$_] }) -join ' '))
Write-Host ('Report : {0}' -f $OutputPath)
if ($unexplained -eq 0) {
    Write-Host 'Exit criterion satisfied: UnexplainedDeploymentOnly = 0'
    exit 0
}
Write-Host ('Exit criterion NOT satisfied: UnexplainedDeploymentOnly = {0}' -f $unexplained)
foreach ($bad in @($rows | Where-Object { $_.Classification -eq 'DeploymentOnly' })) {
    Write-Host ('  DeploymentOnly: {0} ({1})' -f $bad.InfName, $bad.VersionKey)
}
exit 1
