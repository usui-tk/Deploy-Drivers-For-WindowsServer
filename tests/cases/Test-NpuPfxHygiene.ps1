# psa-disable-file PSAP0002 -- test code is not a pipeline script: it declares no
# ScriptVersion / ScriptHash / ScriptShortTag because it ships no runtime identity.
# The five product scripts remain subject to the rule.
<#
.SYNOPSIS
    Gate G-07: NPU PFX hygiene (audit H-05R / W7) and the MSBthPan
    policy-id field rename.
.DESCRIPTION
    The W4 PFX contract reached the NPU script in W7. Windows-only
    cmdlets cannot run on the Linux harness, so - per the project's
    textual-contract discipline - this case pins the STRUCTURE:
      1. The fixed known-literal PFX export password is gone from the
         NPU script's string constants (AST scan; the "canon parity"
         comment usages are prose, not string constants, and stay).
      2. The export path is fail-closed on an empty password, applies
         the ACL helper immediately after export, and the Ctx injects
         the per-run random default.
      3. The PFX is deleted after a completed Install, and the Verify
         phases accept that state: V01 treats a missing PFX as legal,
         V02 falls back to the public CER when the PFX cannot be
         opened cross-run.
      4. MSBthPan: the boot-signing evidence field is named
         MsBthPanSuppPolicyId; the AMD-prefixed name is gone.
      5. Detector self-checks: synthetic mutated sources make the AST
         scan and the rename scan fire (the gate is proven able to
         fail before it is trusted to pass).
    Negative control (measured before landing): the pre-W7 tree fails
    the NPU string-constant scan, the wiring contracts and the rename.
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

$npuLeaf = 'Deploy-AMDNpuDriverOnWindowsServer.ps1'
$msbLeaf = 'Deploy-MSBthPanInboxOnWindowsServer.ps1'
$npuPath = Join-Path $RepoRoot $npuLeaf
$msbPath = Join-Path $RepoRoot $msbLeaf

# Retired literal, assembled so this file never matches its own scan.
$retiredLiteral = 'place' + 'holder'

function Get-G07StringConstantCount {
    param([string]$Path, [string]$Value)
    $t = $null; $e = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseFile((Resolve-Path $Path).Path, [ref]$t, [ref]$e)
    if (@($e).Count -gt 0) { throw ('{0}: parse error(s)' -f $Path) }
    return @($ast.FindAll({ param($n)
        $n -is [System.Management.Automation.Language.StringConstantExpressionAst] -and
        $n.Value -eq $Value }, $true)).Count
}

function Get-G07StringConstantCountFromText {
    param([string]$Text, [string]$Value)
    $t = $null; $e = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseInput($Text, [ref]$t, [ref]$e)
    if (@($e).Count -gt 0) { throw 'synthetic source: parse error(s)' }
    return @($ast.FindAll({ param($n)
        $n -is [System.Management.Automation.Language.StringConstantExpressionAst] -and
        $n.Value -eq $Value }, $true)).Count
}

Write-TestSection 'G-07: the known-literal PFX password is gone from NPU string constants'
Assert-Equal ('{0}: retired literal appears in 0 string constant(s)' -f $npuLeaf) 0 (Get-G07StringConstantCount -Path $npuPath -Value $retiredLiteral)

Write-TestSection 'G-07: detector self-check (synthetic mutated source fires)'
$syntheticBad = ('$pfxSecure = ConvertTo-SecureString -String ''{0}'' -AsPlainText -Force' -f $retiredLiteral)
Assert-Equal 'synthetic mutated source: retired literal detected once' 1 (Get-G07StringConstantCountFromText -Text $syntheticBad -Value $retiredLiteral)
$syntheticComment = ('# {0} for canon parity' -f $retiredLiteral)
Assert-Equal 'synthetic comment-only source: prose usage not flagged' 0 (Get-G07StringConstantCountFromText -Text $syntheticComment -Value $retiredLiteral)

Write-TestSection 'G-07: NPU export path is fail-closed and ACL-restricted; Ctx injects the random default'
$npuText = Get-Content -LiteralPath $npuPath -Raw
Assert-True ('{0}: empty PfxPassword throws at export (fail-closed)' -f $npuLeaf) ($npuText.Contains("throw 'PfxPassword must not be empty"))
Assert-True ('{0}: Set-PfxFileAcl called after Export-PfxCertificate' -f $npuLeaf) ($npuText -match '(?s)Export-PfxCertificate[^\r\n]*\r?\n\s*Set-PfxFileAcl -Path \$PfxPath')
Assert-True ('{0}: New-RandomPfxPassword wired into Ctx' -f $npuLeaf) ($npuText -match '(?m)PfxPassword\s+= if \(\[string\]::IsNullOrEmpty\(\$PfxPassword\)\) \{ New-RandomPfxPassword \}')
Assert-True ('{0}: P07 call site consumes $Ctx.PfxPassword' -f $npuLeaf) ($npuText.Contains('-PfxPassword $Ctx.PfxPassword `'))

Write-TestSection 'G-07: delete-after-Install and the Verify phases accept the deleted state'
Assert-True ('{0}: PFX deleted after a completed Install' -f $npuLeaf) ($npuText.Contains('PFX deleted after install (P1-G)'))
Assert-True ('{0}: V01 treats a missing PFX as a legal post-Install state' -f $npuLeaf) ($npuText.Contains('deleted after Install per P1-G'))
Assert-True ('{0}: V02 falls back to the public CER' -f $npuLeaf) ($npuText.Contains('inspecting the public CER instead'))
Assert-True ('{0}: V02 states where private-key possession was proven' -f $npuLeaf) ($npuText.Contains('proven when P09 signed the catalogs'))

Write-TestSection 'G-07: MSBthPan policy-id field rename'
$msbText = Get-Content -LiteralPath $msbPath -Raw
Assert-Equal ('{0}: AMD-prefixed field name appears 0 time(s)' -f $msbLeaf) 0 ([regex]::Matches($msbText, 'AmdSuppPolicyId')).Count
Assert-True ('{0}: MsBthPanSuppPolicyId field declared' -f $msbLeaf) ($msbText.Contains('-Name MsBthPanSuppPolicyId'))
Assert-True ('{0}: MsBthPanSuppPolicyId field assigned' -f $msbLeaf) ($msbText.Contains('$env.MsBthPanSuppPolicyId = $deployed.PolicyId'))

Write-TestSection 'G-07: rename-detector self-check'
$syntheticRename = '$env.' + 'AmdSuppPolicyId' + ' = $deployed.PolicyId'
Assert-Equal 'synthetic mutated source: AMD-prefixed name detected once' 1 ([regex]::Matches($syntheticRename, 'AmdSuppPolicyId')).Count

$result = Get-TestResult
Write-Host ''
Write-Host ('{0}: {1} passed, {2} failed' -f (Split-Path -Leaf $PSCommandPath), $result.Passed, $result.Failed) `
    -ForegroundColor $(if ($result.Failed -eq 0) { 'Green' } else { 'Red' })
exit $result.Failed
