# psa-disable-file PSAP0002 -- test code is not a pipeline script: it declares no
# ScriptVersion / ScriptHash / ScriptShortTag because it ships no runtime identity.
# The five product scripts remain subject to the rule.
<#
.SYNOPSIS
    Acceptance gate G-02: Windows Driver Policy evidence exists and is testable.
.DESCRIPTION
    Audit ruling (plan G-02, SPEC D.58.6): WS2025 evidence must include the
    Windows Driver Policy's availability, mode, and the 3076/3077 events.
    This case pins the collector's windows-driver-policy.json builder (schema
    keys, the two policy GUIDs, the read-only ESP ruling Q2) and
    fixture-tests the pure parsers (ruling Q3): ConvertFrom-CiToolPolicyList
    and ConvertTo-WindowsDriverPolicyMode.
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

$collector = Join-Path $RepoRoot 'Collect-WindowsServerConfigurationEvidence.ps1'

function Get-FunctionExtentText {
    [OutputType([string])]
    param([string]$Path, [string]$Name)
    $t = $null; $e = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseFile((Resolve-Path $Path).Path, [ref]$t, [ref]$e)
    foreach ($fn in $ast.FindAll({ param($n) $n -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true)) {
        if ($fn.Name -eq $Name) { return $fn.Extent.Text }
    }
    return ''
}

Write-TestSection 'The builder and both pure parsers exist'
$builderText = Get-FunctionExtentText -Path $collector -Name 'Get-WindowsDriverPolicyEvidence'
$listText    = Get-FunctionExtentText -Path $collector -Name 'ConvertFrom-CiToolPolicyList'
$modeText    = Get-FunctionExtentText -Path $collector -Name 'ConvertTo-WindowsDriverPolicyMode'
Assert-True 'Get-WindowsDriverPolicyEvidence exists' ($builderText.Length -gt 0)
Assert-True 'ConvertFrom-CiToolPolicyList exists' ($listText.Length -gt 0)
Assert-True 'ConvertTo-WindowsDriverPolicyMode exists' ($modeText.Length -gt 0)

Write-TestSection 'The evidence schema carries the adjudicated keys'
$requiredKeys = @('CollectedAtUtc', 'Applicable', 'OsBuildAndUpdate', 'AuditPolicyId',
                  'EnforcePolicyId', 'Detection', 'AuditPolicyPresent', 'EnforcePolicyPresent',
                  'Mode', 'EspProbe', 'Event3076Count', 'Event3077Count',
                  'ObservedDriverPaths', 'QueryError')
foreach ($k in $requiredKeys) {
    Assert-True ('builder emits key {0}' -f $k) ($builderText -match [regex]::Escape($k))
}
Assert-True 'builder pins the audit GUID'   ($builderText -match '784C4414-79F4-4C32-A6A5-F0FB42A51D0D')
Assert-True 'builder pins the enforce GUID' ($builderText -match '8F9CB695-5D48-48D6-A329-7202B44607E3')
Assert-True 'ESP is never mounted (ruling Q2: read-only contract)' (($builderText -match 'read-only-contract') -and ($builderText -notmatch 'mountvol'))

Write-TestSection 'ConvertFrom-CiToolPolicyList against fixtures (ruling Q3)'
if ($listText) {
    . (Get-ScriptFunctionBlock -Path $collector -Name @('ConvertFrom-CiToolPolicyList'))
    $enforceGuid = '8F9CB695-5D48-48D6-A329-7202B44607E3'
    $auditGuid   = '784C4414-79F4-4C32-A6A5-F0FB42A51D0D'

    $fixEnforce = '{"Policies":[{"PolicyID":"{' + $enforceGuid + '}","FriendlyName":"WDP"},{"PolicyID":"{AAAAAAAA-1111-2222-3333-444444444444}","FriendlyName":"Other"}]}'
    $r = ConvertFrom-CiToolPolicyList -Content $fixEnforce
    Assert-True  'enforce fixture: parse succeeds' $r.ParseSucceeded
    Assert-Equal 'enforce fixture: policy count' 2 $r.PolicyCount
    Assert-True  'enforce fixture: enforce GUID surfaced (braces stripped, upper)' (@($r.PolicyIds) -contains $enforceGuid)

    $fixAudit = '{"Policies":[{"PolicyID":"{' + $auditGuid.ToLower() + '}"}]}'
    $r = ConvertFrom-CiToolPolicyList -Content $fixAudit
    Assert-True 'audit fixture: lower-case input normalises to upper' (@($r.PolicyIds) -contains $auditGuid)

    $fixBanner = "Policy listing follows`r`n" + '{"Policies":[{"PolicyID":"{BBBBBBBB-1111-2222-3333-444444444444}"}]}'
    $r = ConvertFrom-CiToolPolicyList -Content $fixBanner
    Assert-True 'banner fixture: leading non-JSON text is tolerated' $r.ParseSucceeded

    $r = ConvertFrom-CiToolPolicyList -Content 'not json at all'
    Assert-False 'garbled fixture: parse fails closed' $r.ParseSucceeded
    Assert-True  'garbled fixture: error is recorded' (-not [string]::IsNullOrWhiteSpace($r.ParseError))

    $r = ConvertFrom-CiToolPolicyList -Content ''
    Assert-False 'empty fixture: parse fails closed' $r.ParseSucceeded
}

Write-TestSection 'ConvertTo-WindowsDriverPolicyMode against the adjudicated mapping'
if ($modeText) {
    . (Get-ScriptFunctionBlock -Path $collector -Name @('ConvertTo-WindowsDriverPolicyMode'))
    Assert-Equal 'enforce present -> enforce' 'enforce' (ConvertTo-WindowsDriverPolicyMode -ParseSucceeded $true -AuditPresent $true -EnforcePresent $true)
    Assert-Equal 'audit only -> audit' 'audit' (ConvertTo-WindowsDriverPolicyMode -ParseSucceeded $true -AuditPresent $true -EnforcePresent $false)
    Assert-Equal 'neither present, parse ok -> absent' 'absent' (ConvertTo-WindowsDriverPolicyMode -ParseSucceeded $true -AuditPresent $false -EnforcePresent $false)
    Assert-Equal 'parse failed -> unknown' 'unknown' (ConvertTo-WindowsDriverPolicyMode -ParseSucceeded $false -AuditPresent $false -EnforcePresent $false)
}

$result = Get-TestResult
Write-Host ''
Write-Host ('{0}: {1} passed, {2} failed' -f (Split-Path -Leaf $PSCommandPath), $result.Passed, $result.Failed) `
    -ForegroundColor $(if ($result.Failed -eq 0) { 'Green' } else { 'Red' })
exit $result.Failed
