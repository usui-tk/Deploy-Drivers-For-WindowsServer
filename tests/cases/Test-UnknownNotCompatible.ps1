# psa-disable-file PSAP0002 -- test code is not a pipeline script: it declares no
# ScriptVersion / ScriptHash / ScriptShortTag because it ships no runtime identity.
<#
.SYNOPSIS
    Gate G-21: Unknown is never Compatible (audit v5 R5-M01 / W13).
.DESCRIPTION
    1. Presence guard: the observation vocabulary constant and
       Get-InfWdfEvidence exist in C and G.
    2. Vocabulary pin: the five-value set is verbatim, duplicate-free and
       identical across C/G; no sixth value exists.
    3. Evidence coupling: Get-InfWdfEvidence emits Declared if and only
       if at least one version was actually observed; empty, absent and
       malformed content all land on NotDeclared - never Declared, never
       an empty-string status.
    4. Observation sanity over all five states: a record in any
       non-Declared state carries no version claims and survives the
       flat projection with its status verbatim (no coercion toward a
       capability claim).
    5. Negative controls: a synthetic observation that claims Declared
       with no versions is named; an out-of-vocabulary status is named.
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

$chipsetPath  = Join-Path $RepoRoot 'Deploy-AMDChipsetDriverOnWindowsServer.ps1'
$graphicsPath = Join-Path $RepoRoot 'Deploy-AMDGraphicsDriverOnWindowsServer.ps1'
$vocabularySisters = @($chipsetPath, $graphicsPath)
$expectedVocabulary = @('Declared', 'NotDeclared', 'ParseFailed', 'NotInspected', 'ExtractionIncomplete')

function Get-G21FunctionText {
    param([string]$Path, [string]$Name)
    $tokens = $null; $errors = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseFile((Resolve-Path $Path).Path, [ref]$tokens, [ref]$errors)
    foreach ($fn in $ast.FindAll({ param($node) $node -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true)) {
        if ($fn.Name -eq $Name) { return $fn.Extent.Text }
    }
    return ''
}

function Get-G21VocabularyLiteral {
    # The declared value list of $Script:WdfObservationStatusSet, or @().
    [OutputType([string[]])]
    param([string]$Path)
    $rawText = Get-Content -Path $Path -Raw
    $match = [regex]::Match($rawText, '\$Script:WdfObservationStatusSet\s*=\s*@\(([^)]*)\)')
    if (-not $match.Success) { return @() }
    return @([regex]::Matches($match.Groups[1].Value, "'([^']+)'") | ForEach-Object { $_.Groups[1].Value })
}

function Assert-G21ObservationSane {
    # Names the violation in a { Status; Versions } observation, '' when sane.
    [OutputType([string])]
    param($Observation, [string[]]$Vocabulary)
    $status = [string]$Observation.Status
    if ([string]::IsNullOrEmpty($status)) { return 'empty-status' }
    if ($Vocabulary -cnotcontains $status) { return ('out-of-vocabulary:' + $status) }
    $versionCount = (@($Observation.Versions)).Count
    if (($status -ceq 'Declared') -and ($versionCount -eq 0)) { return 'declared-without-versions' }
    if (($status -ceq 'NotDeclared') -and ($versionCount -gt 0)) { return 'versions-without-declaration' }
    return ''
}

Write-TestSection 'G-21: presence guard (vocabulary constant + evidence function in C/G)'
$presenceOk = $true
foreach ($path in $vocabularySisters) {
    $leaf = Split-Path -Leaf $path
    $vocabularyPresent = (@(Get-G21VocabularyLiteral -Path $path)).Count -gt 0
    Assert-True ('{0}: WdfObservationStatusSet is declared' -f $leaf) $vocabularyPresent
    if (-not $vocabularyPresent) { $presenceOk = $false }
    $functionPresent = (Get-G21FunctionText -Path $path -Name 'Get-InfWdfEvidence') -ne ''
    Assert-True ('{0}: Get-InfWdfEvidence is defined' -f $leaf) $functionPresent
    if (-not $functionPresent) { $presenceOk = $false }
}
if (-not $presenceOk) {
    $result = Get-TestResult
    Write-Host ''
    Write-Host ('{0}: {1} passed, {2} failed' -f (Split-Path -Leaf $PSCommandPath), $result.Passed, $result.Failed) -ForegroundColor Red
    exit $result.Failed
}

Write-TestSection 'G-21: vocabulary pin'
foreach ($path in $vocabularySisters) {
    $leaf = Split-Path -Leaf $path
    $vocabulary = @(Get-G21VocabularyLiteral -Path $path)
    Assert-Equal ('{0}: exactly five observation states' -f $leaf) 5 $vocabulary.Count
    Assert-Equal ('{0}: the five values are verbatim' -f $leaf) ($expectedVocabulary -join '|') ($vocabulary -join '|')
    Assert-Equal ('{0}: no duplicate values' -f $leaf) 5 (@($vocabulary | Sort-Object -Unique)).Count
}

. (Get-ScriptFunctionBlock -Path $chipsetPath -Name @('Get-InfWdfEvidence', 'ConvertTo-InfInventoryFlatView'))

Write-TestSection 'G-21: evidence coupling (Declared iff observed)'
$declaredContent = "[Version]`r`n[Drv.Wdf]`r`nKmdfLibraryVersion = 1.33`r`nUmdfLibraryVersion = 2.33`r`n"
$declared = Get-InfWdfEvidence -Content $declaredContent
Assert-Equal 'KMDF with a directive is Declared' 'Declared' ([string]$declared.KMDF.Status)
Assert-Equal 'UMDF with a directive is Declared' 'Declared' ([string]$declared.UMDF.Status)
Assert-Equal 'declared observation is sane' '' (Assert-G21ObservationSane -Observation $declared.KMDF -Vocabulary $expectedVocabulary)
foreach ($fixture in @(
    @{ Name = 'empty content';        Content = '' },
    @{ Name = 'no WDF directives';    Content = "[Version]`r`nSignature=x`r`n" },
    @{ Name = 'malformed directive';  Content = "KmdfLibraryVersion = not-a-version`r`n" },
    @{ Name = 'commented-out lookalike'; Content = "; KmdfLibraryVersion = 1.33 disabled`r`n" }
)) {
    $observed = Get-InfWdfEvidence -Content $fixture.Content
    Assert-Equal ('{0}: KMDF is NotDeclared, never Declared' -f $fixture.Name) 'NotDeclared' ([string]$observed.KMDF.Status)
    Assert-Equal ('{0}: UMDF is NotDeclared, never Declared' -f $fixture.Name) 'NotDeclared' ([string]$observed.UMDF.Status)
    Assert-Equal ('{0}: observation is sane' -f $fixture.Name) '' (Assert-G21ObservationSane -Observation $observed.KMDF -Vocabulary $expectedVocabulary)
}
Assert-Equal 'evidence carries 1-based line numbers' 3 ([int](Get-InfWdfEvidence -Content $declaredContent).KMDF.Evidence[0].LineNumber)

Write-TestSection 'G-21: all five states survive without coercion'
foreach ($status in $expectedVocabulary) {
    $observationVersions = @()
    if ($status -ceq 'Declared') { $observationVersions = @('1.33') }
    $record = [pscustomobject]@{
        Inf = 'x.inf'; RelativePath = 'x.inf'; RelativeDir = ''; SourceVariant = 'root'
        VariantSelected = $false; Encoding = ''; HasMfg = $false; HasServerDeco = $false
        NeedsPatch = $false; Provider = ''; Class = ''; ClassGuid = ''; DriverVer = ''
        CatalogFile = ''; Manufacturer = ''; DeviceCount = 0; Devices = @()
        IsWdfDriver = ($status -ceq 'Declared'); KmdfLibraryVersion = ''
        UmdfLibraryVersion = ''; CoInstallerVersions = ''; WdfSectionCount = 0
        SourceArtifactSha256 = 's'; InfSha256 = 'h'; InspectionStatus = 'Inspected'
        InspectionError = $null
        Wdf = [pscustomobject]@{
            KMDF = [pscustomobject]@{ Status = $status; Versions = $observationVersions; Evidence = @() }
            UMDF = [pscustomobject]@{ Status = 'NotDeclared'; Versions = @(); Evidence = @() }
        }
    }
    $sanity = Assert-G21ObservationSane -Observation $record.Wdf.KMDF -Vocabulary $expectedVocabulary
    if ($status -ceq 'Declared') {
        Assert-Equal ('{0}: sane with an observed version' -f $status) '' $sanity
    }
    else {
        Assert-Equal ('{0}: sane with zero version claims' -f $status) '' $sanity
    }
    $flatRow = @(ConvertTo-InfInventoryFlatView -DetailRecords @($record))[0]
    Assert-False ('{0}: raw observation does not leak into the flat view' -f $status) ($flatRow.PSObject.Properties['Wdf'] -ne $null)
}

Write-TestSection 'G-21: negative controls'
$claimingUnknown = [pscustomobject]@{ Status = 'Declared'; Versions = @(); Evidence = @() }
Assert-Equal 'Declared-without-versions is named' 'declared-without-versions' (Assert-G21ObservationSane -Observation $claimingUnknown -Vocabulary $expectedVocabulary)
$outOfVocabulary = [pscustomobject]@{ Status = 'Compatible'; Versions = @(); Evidence = @() }
Assert-Equal 'an out-of-vocabulary capability claim is named' 'out-of-vocabulary:Compatible' (Assert-G21ObservationSane -Observation $outOfVocabulary -Vocabulary $expectedVocabulary)
$emptyStatus = [pscustomobject]@{ Status = ''; Versions = @(); Evidence = @() }
Assert-Equal 'an empty-string status is named' 'empty-status' (Assert-G21ObservationSane -Observation $emptyStatus -Vocabulary $expectedVocabulary)
$smuggledVersions = [pscustomobject]@{ Status = 'NotDeclared'; Versions = @('1.33'); Evidence = @() }
Assert-Equal 'versions smuggled past NotDeclared are named' 'versions-without-declaration' (Assert-G21ObservationSane -Observation $smuggledVersions -Vocabulary $expectedVocabulary)

$result = Get-TestResult
Write-Host ''
Write-Host ('{0}: {1} passed, {2} failed' -f (Split-Path -Leaf $PSCommandPath), $result.Passed, $result.Failed) `
    -ForegroundColor $(if ($result.Failed -eq 0) { 'Green' } else { 'Red' })
exit $result.Failed
