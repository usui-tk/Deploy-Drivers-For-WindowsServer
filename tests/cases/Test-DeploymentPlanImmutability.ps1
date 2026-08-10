# psa-disable-file PSAP0002 -- test code is not a pipeline script: it declares no
# ScriptVersion / ScriptHash / ScriptShortTag because it ships no runtime identity.
<#
.SYNOPSIS
    Gate G-23: immutable DeploymentPlan (audit v5 R5-M03 / feedback 5B-5 /
    W14).
.DESCRIPTION
    1. Presence guard: the seven plan functions and the schema constant
       exist in C and G (named fail + standard footer early-exit on a
       pre-W14 tree).
    2. Byte identity of the seven plan functions across C/G.
    3. Pure builder fixtures: SelectionReason / ExpectedMutation / trim
       suffix derivation; chipset completeness honesty vs graphics
       Evaluated=false; co-sign observation lookup; legacy-CSV PlanNote;
       the degenerate empty document.
    4. Schema pins: document and row required fields verbatim; the plan
       builder output carries NO loadability-claim field (the forbidden
       names are assembled by concatenation so this gate does not trip
       its own scan).
    5. Structural pins: deployment-plan.json has exactly one writer
       (inside Save-DeploymentPlanJson); P06's loops iterate PLAN rows
       and the old inventory-filter-driven loops are gone; the P06
       marker chains the plan SHA; P08/I03 carry the report-only
       alignment call and the alignment function never throws.
    6. Round-trip + negative controls: save/restore equality; schema
       mismatch rehydrates to $null; a tampered plan is named by the
       alignment check against the marker-recorded SHA; an out-of-plan
       INF under patched/ is named; a synthetic loadability field is
       named by the schema validator.
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
$planSisters = @($chipsetPath, $graphicsPath)

$planFunctionNames = @(
    'New-DeploymentPlanRow',
    'New-DeploymentPlanDocument',
    'Get-DeploymentPlanPayloadFile',
    'Save-DeploymentPlanJson',
    'Save-DeploymentPlanExecutionJson',
    'Restore-DeploymentPlanFromJson',
    'Test-DeploymentPlanAlignment'
)
$requiredDocFields = @('PlanSchemaVersion', 'GeneratedAtUtc', 'ToolIdentity', 'SourceArtifactSha256',
    'InfManifestSha256', 'InventorySha256', 'SkipNonCosignedDrivers', 'DegeneratePlan',
    'ProjectPreference', 'Rows')
$requiredRowFields = @('Inf', 'SelectedSourceInfPath', 'SelectedSourceInfSha256', 'Devices',
    'SourceVariant', 'SelectionReason', 'ExpectedMutation', 'WdfDecision',
    'PackageCompletenessDecision', 'KernelTrustObservation', 'PayloadFiles', 'PlanNote')
# Forbidden loadability-claim field names, assembled so this file's own scan
# never trips (G-16/G-05 style).
$forbiddenFieldNames = @(('Can' + 'Load'), ('Load' + 'able'), ('Is' + 'Compat' + 'ible'), ('Compat' + 'ible'))

function Get-G23FunctionText {
    param([string]$Path, [string]$Name)
    $tokens = $null; $errors = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseFile((Resolve-Path $Path).Path, [ref]$tokens, [ref]$errors)
    foreach ($fn in $ast.FindAll({ param($node) $node -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true)) {
        if ($fn.Name -eq $Name) { return $fn.Extent.Text }
    }
    return ''
}

function Get-G23ThrowStatementCount {
    # AST-based (a text scan would trip on the function's own help text).
    [OutputType([int])]
    param([string]$Path, [string]$Name)
    $tokens = $null; $errors = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseFile((Resolve-Path $Path).Path, [ref]$tokens, [ref]$errors)
    foreach ($fn in $ast.FindAll({ param($node) $node -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true)) {
        if ($fn.Name -eq $Name) {
            return (@($fn.FindAll({ param($node) $node -is [System.Management.Automation.Language.ThrowStatementAst] }, $true))).Count
        }
    }
    return -1
}

function Get-G23TextHash {
    [OutputType([string])]
    param([string]$Text)
    if ([string]::IsNullOrEmpty($Text)) { return '(absent)' }
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try {
        return [System.BitConverter]::ToString($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($Text))).Replace('-', '').Substring(0, 16)
    }
    finally { $sha.Dispose() }
}

function Assert-G23PlanShape {
    # Names the first violation in a plan document, '' when sound.
    [OutputType([string])]
    param($Document, [string[]]$DocFields, [string[]]$RowFields, [string[]]$Forbidden)
    foreach ($field in $DocFields) {
        if (-not $Document.PSObject.Properties[$field]) { return ('doc-missing:' + $field) }
    }
    foreach ($row in @($Document.Rows)) {
        foreach ($field in $RowFields) {
            if (-not $row.PSObject.Properties[$field]) { return ('row-missing:' + $field) }
        }
        foreach ($name in @($row.PSObject.Properties.Name)) {
            foreach ($bad in $Forbidden) {
                if ($name -ieq $bad) { return ('loadability-field:' + $name) }
            }
        }
    }
    return ''
}

Write-TestSection 'G-23: presence guard (plan functions + schema constant in C/G)'
$presenceOk = $true
foreach ($path in $planSisters) {
    $leaf = Split-Path -Leaf $path
    foreach ($name in $planFunctionNames) {
        $present = (Get-G23FunctionText -Path $path -Name $name) -ne ''
        Assert-True ('{0}: {1} is defined' -f $leaf, $name) $present
        if (-not $present) { $presenceOk = $false }
    }
    $rawText = Get-Content -Path $path -Raw
    $constPresent = $rawText.Contains('$Script:DeploymentPlanSchemaVersion')
    Assert-True ('{0}: DeploymentPlanSchemaVersion constant exists' -f $leaf) $constPresent
    if (-not $constPresent) { $presenceOk = $false }
}
if (-not $presenceOk) {
    $result = Get-TestResult
    Write-Host ''
    Write-Host ('{0}: {1} passed, {2} failed' -f (Split-Path -Leaf $PSCommandPath), $result.Passed, $result.Failed) -ForegroundColor Red
    exit $result.Failed
}

Write-TestSection 'G-23: byte identity of the plan functions across C/G'
foreach ($name in $planFunctionNames) {
    $hashes = @($planSisters | ForEach-Object { Get-G23TextHash (Get-G23FunctionText -Path $_ -Name $name) })
    Assert-Equal ('{0}: identical in C/G' -f $name) 1 (@($hashes | Sort-Object -Unique)).Count
}

Write-TestSection 'G-23: structural pins (writer-once / plan-driven P06 / marker chain / downstream)'
foreach ($path in $planSisters) {
    $leaf = Split-Path -Leaf $path
    $rawText = Get-Content -Path $path -Raw
    $writerCount = ([regex]::Matches($rawText, [regex]::Escape('| Set-Content -Path $planPath'))).Count
    Assert-Equal ('{0}: deployment-plan.json has exactly one writer' -f $leaf) 1 $writerCount
    $saveCalls = ([regex]::Matches($rawText, [regex]::Escape('Save-DeploymentPlanJson -Ctx $Ctx -Document'))).Count
    Assert-Equal ('{0}: the single writer is called from the two P06 sites (main + degenerate)' -f $leaf) 2 $saveCalls
    $p06Text = Get-G23FunctionText -Path $path -Name 'Invoke-PrepPhase06_PatchInfs'
    Assert-True  ('{0}: P06 patch loop iterates plan rows' -f $leaf) ($p06Text.Contains('foreach ($row in $planPatchRows)'))
    Assert-True  ('{0}: P06 copy loop iterates plan rows' -f $leaf) ($p06Text.Contains('foreach ($row in $planCopyRows)'))
    Assert-False ('{0}: the inventory-filter-driven patch loop is gone' -f $leaf) ($p06Text.Contains('foreach ($row in $needsPatch)'))
    Assert-False ('{0}: the inventory-filter-driven copy loop is gone' -f $leaf) ($p06Text.Contains('foreach ($row in $copyOnly)'))
    Assert-True  ('{0}: P06 marker is fingerprinted' -f $leaf) ($p06Text.Contains('-ExpectedInputFields $p06Expected'))
    Assert-True  ('{0}: P06 marker chains the plan SHA' -f $leaf) ($p06Text.Contains('DeploymentPlanSha256'))
    Assert-True  ('{0}: P06 writes the execution evidence' -f $leaf) ($p06Text.Contains('Save-DeploymentPlanExecutionJson'))
    $p08Text = Get-G23FunctionText -Path $path -Name 'Invoke-PrepPhase08_GenerateCatalogs'
    Assert-True ('{0}: P08 carries the report-only alignment call' -f $leaf) ($p08Text.Contains("Test-DeploymentPlanAlignment -Ctx `$Ctx -PhaseLabel 'P08'"))
    $i03Text = Get-G23FunctionText -Path $path -Name 'Invoke-InstPhase03_InstallDrivers'
    Assert-True ('{0}: I03 carries the report-only alignment call' -f $leaf) ($i03Text.Contains("Test-DeploymentPlanAlignment -Ctx `$Ctx -PhaseLabel 'I03'"))
    Assert-Equal ('{0}: the alignment check never throws (report-only)' -f $leaf) 0 (Get-G23ThrowStatementCount -Path $path -Name 'Test-DeploymentPlanAlignment')
}

# Bring the functions into this session from the chipset copy, with the
# session-scope stand-ins the extracted bodies expect.
$Script:DeploymentPlanSchemaVersion = '1'
$Script:SkipNonCosignedDrivers = $false
$Script:ScriptVersion = 'g23-fixture'
# Session stand-ins via the function: drive (no function-definition AST, so
# the repo-wide body-drift scan does not mistake these fixtures for sisters).
Set-Item -Path function:Write-Caution -Value { param($Message) Write-Host ('CAUTION: ' + $Message) }
Set-Item -Path function:Write-Detail -Value { param($Message, $Color) Write-Host ('  ' + $Message) }
. (Get-ScriptFunctionBlock -Path $chipsetPath -Name ($planFunctionNames + @('Get-PhaseMarkerRecord')))

Write-TestSection 'G-23: pure builder fixtures'
$chipsetFlat = [pscustomobject]@{
    Inf = 'a.inf'; RelativePath = 'W11x64\a.inf'; SourceVariant = 'W11x64'; InfSha256 = 'aaa111'
    IsWdfDriver = $true; KmdfLibraryVersion = '1.33'; UmdfLibraryVersion = ''
    EligibleForCatalog = $true; MissingReferencedFiles = ''
}
$chipsetDetail = [pscustomobject]@{
    RelativePath = 'W11x64\a.inf'
    Devices = @([pscustomobject]@{ Description = 'Dev'; HardwareId = 'PCI\VEN_1022' })
    Wdf = [pscustomobject]@{
        KMDF = [pscustomobject]@{ Status = 'Declared' }
        UMDF = [pscustomobject]@{ Status = 'NotDeclared' }
    }
}
$coSignFixture = @([pscustomobject]@{ InfName = 'a.inf'; IsFullyCoSigned = $true })
$chipsetRow = New-DeploymentPlanRow -Record $chipsetFlat -DetailRecord $chipsetDetail -NeedsPatch $true -TrimApplied $true -CoSignAnalyses $coSignFixture -PayloadFiles @([pscustomobject]@{ Name = 'a.sys'; Present = $true; Sha256 = 'bbb' })
Assert-Equal 'trim survivor reason is derived' 'VariantSelected+NeedsPatch+CoSignTrimSurvivor' ([string]$chipsetRow.SelectionReason)
Assert-Equal 'patch mutation is derived' 'PatchManufacturerDecorations' ([string]$chipsetRow.ExpectedMutation)
Assert-Equal 'co-sign observation is looked up' 'CoSigned' ([string]$chipsetRow.KernelTrustObservation.CoSignObservation)
Assert-True 'the trust note declares observation-only' ($chipsetRow.KernelTrustObservation.Note.Contains('no loadability claim'))
Assert-True 'chipset completeness is evaluated' ([bool]$chipsetRow.PackageCompletenessDecision.Evaluated)
Assert-Equal 'devices ride from the rich detail' 1 (@($chipsetRow.Devices)).Count
Assert-Equal 'typed WDF observation is attached' 'Declared' ([string]$chipsetRow.WdfDecision.Observation.KmdfStatus)

$graphicsFlat = [pscustomobject]@{
    Inf = 'b.inf'; RelativePath = 'b.inf'; SourceVariant = 'root'; InfSha256 = 'ccc'
    IsWdfDriver = $false; KmdfLibraryVersion = ''; UmdfLibraryVersion = ''
}
$graphicsRow = New-DeploymentPlanRow -Record $graphicsFlat -DetailRecord $null -NeedsPatch $false -TrimApplied $false -CoSignAnalyses @() -PayloadFiles @()
Assert-Equal 'copy-only reason without trim suffix' 'VariantSelected+ServerCompatible' ([string]$graphicsRow.SelectionReason)
Assert-Equal 'copy-only mutation is derived' 'CopyOnly' ([string]$graphicsRow.ExpectedMutation)
Assert-Equal 'unanalysed co-sign stays NotAnalysed' 'NotAnalysed' ([string]$graphicsRow.KernelTrustObservation.CoSignObservation)
Assert-False 'graphics completeness honestly reports Evaluated=false' ([bool]$graphicsRow.PackageCompletenessDecision.Evaluated)
Assert-True 'legacy-CSV workspaces get a PlanNote' (-not [string]::IsNullOrEmpty($graphicsRow.PlanNote))

Write-TestSection 'G-23: schema pins + round-trip + negatives'
$tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ('g23-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path (Join-Path $tempRoot 'patched'), (Join-Path $tempRoot 'markers') -Force | Out-Null
try {
    $ctx = [pscustomobject]@{
        Paths = [pscustomobject]@{
            Root    = $tempRoot
            Patched = (Join-Path $tempRoot 'patched')
            Markers = (Join-Path $tempRoot 'markers')
        }
        ArtifactSha256    = 'art'
        InfManifestSha256 = 'man'
    }
    $document = New-DeploymentPlanDocument -Ctx $ctx -Rows @($chipsetRow, $graphicsRow) -InventorySha256 'inv123'
    Assert-Equal 'the document passes the shape validator' '' (Assert-G23PlanShape -Document $document -DocFields $requiredDocFields -RowFields $requiredRowFields -Forbidden $forbiddenFieldNames)
    Assert-True 'ProjectPreference is stated as policy, not a rank fact' ($document.ProjectPreference.Contains('not a rank fact'))

    $planSha = Save-DeploymentPlanJson -Ctx $ctx -Document $document
    Assert-Equal 'the writer returns a 64-char lowercase SHA' 64 $planSha.Length
    $planPath = Join-Path $tempRoot 'deployment-plan.json'
    $restored = Restore-DeploymentPlanFromJson -Path $planPath
    Assert-True 'round-trip returns a document' ($null -ne $restored)
    Assert-Equal 'round-trip row count' 2 (@($restored.Rows)).Count
    Assert-Equal 'round-trip preserves the payload identity' 'bbb' ([string]$restored.Rows[0].PayloadFiles[0].Sha256)
    Assert-Equal 'the restored document passes the shape validator' '' (Assert-G23PlanShape -Document $restored -DocFields $requiredDocFields -RowFields $requiredRowFields -Forbidden $forbiddenFieldNames)

    $degenerate = New-DeploymentPlanDocument -Ctx $ctx -Rows @() -InventorySha256 'inv123' -Degenerate
    Assert-True 'the degenerate document declares itself' ([bool]$degenerate.DegeneratePlan)
    Assert-Equal 'the degenerate document is planned-empty, not shapeless' '' (Assert-G23PlanShape -Document $degenerate -DocFields $requiredDocFields -RowFields $requiredRowFields -Forbidden $forbiddenFieldNames)

    # Schema mismatch rehydrates to $null.
    $mismatch = Get-Content -Path $planPath -Raw | ConvertFrom-Json
    $mismatch.PlanSchemaVersion = '99'
    $mismatch | ConvertTo-Json -Depth 8 | Set-Content -Path $planPath -Encoding UTF8
    Assert-True 'schema mismatch rehydrates to $null' ($null -eq (Restore-DeploymentPlanFromJson -Path $planPath))

    # Alignment against the marker-recorded SHA: write the good plan, record
    # its SHA in a marker fixture, then tamper the plan on disk.
    $document | ConvertTo-Json -Depth 8 | Set-Content -Path $planPath -Encoding UTF8
    $goodSha = (Get-FileHash -LiteralPath $planPath -Algorithm SHA256).Hash.ToLowerInvariant()
    $markerFixture = @{
        phase = 'P06'; schemaVersion = '2'; completedAt = 't'; meta = @{}
        input = @{ fields = @{}; fingerprint = 'f' }
        output = @{ fields = @{ DeploymentPlanSha256 = $goodSha }; fingerprint = 'g' }
    }
    $markerFixture | ConvertTo-Json -Depth 5 | Set-Content -Path (Join-Path $tempRoot 'markers/.P06.done') -Encoding UTF8
    'in-plan' | Set-Content -Path (Join-Path $tempRoot 'patched/a.inf')
    'in-plan' | Set-Content -Path (Join-Path $tempRoot 'patched/b.inf')
    Assert-True 'aligned workspace verifies clean' (Test-DeploymentPlanAlignment -Ctx $ctx -PhaseLabel 'G23')

    'rogue' | Set-Content -Path (Join-Path $tempRoot 'patched/rogue.inf')
    Assert-False 'an out-of-plan INF is named (report-only)' (Test-DeploymentPlanAlignment -Ctx $ctx -PhaseLabel 'G23')
    Remove-Item -Path (Join-Path $tempRoot 'patched/rogue.inf') -Force

    $tampered = (Get-Content -Path $planPath -Raw).Replace('inv123', 'inv999')
    $tampered | Set-Content -Path $planPath -Encoding UTF8
    Assert-False 'a tampered plan is named against the marker-recorded SHA' (Test-DeploymentPlanAlignment -Ctx $ctx -PhaseLabel 'G23')

    # Synthetic loadability field is named by the shape validator.
    $badRow = $chipsetRow | Select-Object -Property *
    $badRow | Add-Member -NotePropertyName ('Can' + 'Load') -NotePropertyValue $true
    $badDocument = New-DeploymentPlanDocument -Ctx $ctx -Rows @($badRow) -InventorySha256 'inv123'
    Assert-Equal 'a loadability-claim field is named' ('loadability-field:' + 'Can' + 'Load') (Assert-G23PlanShape -Document $badDocument -DocFields $requiredDocFields -RowFields $requiredRowFields -Forbidden $forbiddenFieldNames)
}
finally {
    Remove-Item -Path $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
}

$result = Get-TestResult
Write-Host ''
Write-Host ('{0}: {1} passed, {2} failed' -f (Split-Path -Leaf $PSCommandPath), $result.Passed, $result.Failed) `
    -ForegroundColor $(if ($result.Failed -eq 0) { 'Green' } else { 'Red' })
exit $result.Failed
