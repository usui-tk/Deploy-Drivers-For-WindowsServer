# psa-disable-file PSAP0002 -- test code is not a pipeline script: it declares no
# ScriptVersion / ScriptHash / ScriptShortTag because it ships no runtime identity.
# The five product scripts remain subject to the rule.
<#
.SYNOPSIS
    Collector: driver framework versions, crash evidence, offline collector.
.DESCRIPTION
    The framework and crash stages answer questions that only matter when a
    host is misbehaving, which is exactly when nobody wants to discover the
    collection code has a fault. Every case here calls the function.

    The offline collector is a .cmd because the Windows Recovery Environment
    has no PowerShell. It cannot be executed here, so it is checked
    structurally for the properties a batch file must hold - matched
    reg load/unload, reachable goto targets, CRLF, no BOM, plain ASCII.
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
. (Get-ScriptFunctionBlock -Path $collector -Name @(
    'Get-UtcTimestamp', 'Get-PropertyValue', 'Get-RegistryKeySnapshot', 'Get-NamedRegistryValue',
    'Get-FileVersionInfoSafe', 'Get-DriverFrameworkEvidence', 'Get-CrashEvidence'))

Write-TestSection 'Get-FileVersionInfoSafe tolerates every input'
Assert-NoThrow 'empty path does not throw' { Get-FileVersionInfoSafe -Path '' }
Assert-False 'empty path reports not-exists' (Get-FileVersionInfoSafe -Path '').Exists
Assert-NoThrow 'missing file does not throw' { Get-FileVersionInfoSafe -Path 'Z:\nope\absent.sys' }
Assert-False 'missing file reports not-exists' (Get-FileVersionInfoSafe -Path 'Z:\nope\absent.sys').Exists
$self = Get-FileVersionInfoSafe -Path (Resolve-Path $collector).Path
Assert-True  'an existing file reports exists' $self.Exists
Assert-True  'an existing file reports a size' ($self.SizeBytes -gt 0)

Write-TestSection 'Driver framework evidence runs on any host'
# Regression guard: the first version built its paths with Join-Path, which
# throws on a null mandatory parameter when $env:SystemRoot is unset.
Assert-NoThrow 'framework collection does not throw' { Get-DriverFrameworkEvidence }
$fw = Get-DriverFrameworkEvidence
Assert-True 'a KMDF runtime record is always present' ($null -ne $fw.KmdfRuntime)
Assert-True 'a UMDF reflector record is always present' ($null -ne $fw.UmdfReflector)
Assert-True 'co-installer count is a number' ($fw.CoInstallerCount -ge 0)
$savedRoot = $env:SystemRoot
try {
    $env:SystemRoot = ''
    Assert-NoThrow 'empty SystemRoot does not throw' { Get-DriverFrameworkEvidence }
    $bare = Get-DriverFrameworkEvidence
    Assert-Equal 'empty SystemRoot yields an empty KMDF version, not an error' '' $bare.KmdfLibraryVersion
}
finally { $env:SystemRoot = $savedRoot }

Write-TestSection 'Crash evidence runs on any host'
Assert-NoThrow 'crash collection does not throw' { Get-CrashEvidence }
$crash = Get-CrashEvidence
Assert-True 'minidump count is a number' ($crash.MinidumpCount -ge 0)
Assert-True 'bugcheck event count is a number' ($crash.BugCheckEventCount -ge 0)
Assert-True 'a CrashControl record is always present' ($null -ne $crash.CrashControl)
# A host without Get-WinEvent must record why, not silently report zero
# events as though it had looked.
$savedRoot2 = $env:SystemRoot
try {
    $env:SystemRoot = ''
    Assert-NoThrow 'empty SystemRoot does not throw' { Get-CrashEvidence }
    $bare2 = Get-CrashEvidence
    Assert-False 'no memory dump claimed when no root is resolvable' $bare2.MemoryDumpPresent
}
finally { $env:SystemRoot = $savedRoot2 }

Write-TestSection 'Offline recovery collector is a well-formed batch file'
$offline = Join-Path $RepoRoot 'Collect-OfflineRecoveryEvidence.cmd'
Assert-True 'the offline collector exists' (Test-Path -LiteralPath $offline)
$bytes = [System.IO.File]::ReadAllBytes($offline)
Assert-False 'no UTF-8 BOM (cmd.exe treats it as part of the first command)' `
    ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF)
Assert-Equal 'plain ASCII only' 0 @($bytes | Where-Object { $_ -gt 127 }).Count
$text = [System.Text.Encoding]::ASCII.GetString($bytes)
Assert-True 'CRLF line endings' ($text.Contains("`r`n"))
Assert-False 'no bare LF' (($text -replace "`r`n", '').Contains("`n"))
Assert-True 'delayed expansion enabled before use' ($text.ToLower().Contains('setlocal enabledelayedexpansion'))

Write-TestSection 'Batch control flow resolves'
$cmdLines = @($text -split "`r`n")
$commandLines = @($cmdLines | Where-Object { $_.Trim() -and -not $_.Trim().ToLower().StartsWith('rem ') })
$labels = @([regex]::Matches($text, '(?m)^:(\w+)\s*$') | ForEach-Object { $_.Groups[1].Value })
foreach ($t in @([regex]::Matches($text, 'goto :(\w+)') | ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique)) {
    Assert-True ('goto :{0} has a label' -f $t) ($labels -contains $t)
}
foreach ($t in @([regex]::Matches($text, 'call :(\w+)') | ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique)) {
    Assert-True ('call :{0} has a label' -f $t) ($labels -contains $t)
}
# reg load counted as a COMMAND, not as text inside an echo. An unbalanced
# load leaves the hive mounted and holds a handle on the very volume under
# investigation.
# The unload is guarded by the mode test, so it no longer starts the line.
# Count both as commands anywhere on the line rather than anchored, or the
# guarded form reads as a missing unload.
# Count the COMMAND, not the word: an error message that mentions 'reg load'
# is not a second load. Strip anything from 'echo' onward before matching, so
# a guarded command still counts and a quoted mention does not.
$effective = @($commandLines | ForEach-Object { ($_ -split '\becho\b')[0] })
$loads = @($effective | Where-Object { $_ -match '\breg load\b' }).Count
$unloads = @($effective | Where-Object { $_ -match '\breg unload\b' }).Count
Assert-True  'at least one reg load is present' ($loads -ge 1)
Assert-Equal 'every reg load command has a matching reg unload' $loads $unloads
Assert-True  'the unload only runs in offline mode' `
    ($text.Contains('if /i "%COLLECTMODE%"=="offline" reg unload HKLM\OFFSYS'))
# Every subroutine exit must release its own setlocal, or the environment
# leaks across calls and MANIFEST / ERRLOG stop resolving.
foreach ($sub in @('copyone', 'copytree', 'copylarge')) {
    Assert-True ('subroutine :{0} exists' -f $sub) ($labels -contains $sub)
}
# Only exits INSIDE a subroutine need to release a setlocal. The argument
# validation at the top of the script exits before any subroutine is entered
# and correctly has no endlocal, so the check starts at the first subroutine
# label rather than counting indentation.
$firstSubLine = ($cmdLines | Select-String -Pattern '^:copyone\s*$').LineNumber
Assert-True 'subroutine section located' ($null -ne $firstSubLine)
$subSection = @($cmdLines[($firstSubLine - 1)..($cmdLines.Count - 1)])
$leakyExits = @($subSection | Where-Object { $_ -match 'exit /b' -and $_ -notmatch 'endlocal' }).Count
Assert-Equal 'every subroutine exit releases its setlocal' 0 $leakyExits

Write-TestSection 'Offline-hive and destination discipline'
Assert-True 'uses ControlSet001' ($text.Contains('ControlSet001'))
# CurrentControlSet may appear in a comment explaining why it is not used; it
# must never appear in an actual command, because the Current alias is
# synthesised by a running system and does not exist offline.
# CurrentControlSet is correct in ONLINE mode and wrong offline, so the rule
# is not "never" but "only where the live registry is being read". The single
# permitted use is the assignment that selects the online root; any other
# occurrence in a command would be an offline query against an alias that
# does not exist in a loaded hive.
$currentUses = @($commandLines | Where-Object { $_.Contains('CurrentControlSet') })
Assert-Equal 'CurrentControlSet appears in exactly one command' 1 $currentUses.Count
if ($currentUses.Count -eq 1) {
    Assert-True 'and that command is the online-root assignment' `
        ($currentUses[0].Trim() -eq 'set "RK=HKLM\SYSTEM\CurrentControlSet"')
}
Assert-Equal 'no reg query names CurrentControlSet directly' 0 `
    @($commandLines | Where-Object { $_ -match '^\s*reg query' -and $_.Contains('CurrentControlSet') }).Count
Assert-True 'refuses to write output onto the offline volume' `
    ($text.Contains('the destination is the offline Windows volume'))
Assert-True 'auto-detects the Windows volume' ($text.Contains('Searching for the offline Windows installation'))
Assert-True 'auto-detects a writable destination' ($text.Contains('Searching for a writable destination'))
Assert-True 'proves destination writability by writing' ($text.Contains('_offlinecollect_probe.tmp'))
Assert-True 'caps single-file copies' ($text.Contains('MAXCOPYMB'))
Assert-True 'records a skipped large file rather than failing' ($text.Contains('SKIPPED at'))
Assert-True 'writes an error log alongside the manifest' ($text.Contains('00-collection-errors.txt'))

Write-TestSection 'cmd.exe parser hazards'
# The first real run of this script stopped at stage 5 with
# ": の使い方が誤っています" because a label containing parentheses was
# expanded inside an if-block: cmd.exe substitutes the variable BEFORE
# parsing the block, so the ')' in "CBS (incl. CBS.persist.log)" closed the
# block early and the rest of the line was parsed as a command.
#
# Two properties are asserted, because either alone leaves a trap for the
# next edit: labels carry no shell metacharacters, AND the subroutines do not
# use parenthesised blocks at all.
# Match the LABEL DEFINITION at the start of a line, not the earlier
# 'call :copyone' sites - otherwise the search starts in the main body and
# every if-block there is miscounted as a subroutine block.
$defMatch = [regex]::Match($text, '(?m)^:copyone\s*$')
Assert-True 'subroutine section located' $defMatch.Success
$subStart = $defMatch.Index
$subText = $text.Substring($subStart)
$subLines = @($subText -split "`r`n" | Where-Object { $_.Trim() -and -not $_.Trim().ToLower().StartsWith('rem ') })
$blockOpeners = @($subLines | Where-Object { $_.TrimEnd().EndsWith('(') }).Count
Assert-Equal 'no subroutine opens a parenthesised block' 0 $blockOpeners

$labelsWithMeta = 0
foreach ($m in [regex]::Matches($text, 'call :(?:copyone|copytree|copylarge)([^
]*)')) {
    $quoted = @([regex]::Matches($m.Groups[1].Value, '"([^"]*)"') | ForEach-Object { $_.Groups[1].Value })
    if ($quoted.Count -gt 0) {
        $label = $quoted[-1]
        if ($label -match '[()&|<>]') { $labelsWithMeta++ }
    }
}
Assert-Equal 'no subroutine label carries a shell metacharacter' 0 $labelsWithMeta

# Every branch target introduced by the goto-based rewrite must resolve, or a
# subroutine falls through into the next one and reports the wrong outcome.
foreach ($t in @('copyone_absent', 'copyone_failed', 'copytree_absent', 'copylarge_absent', 'copylarge_skip', 'copylarge_failed')) {
    Assert-True ('branch target :{0} exists' -f $t) ($labels -contains $t)
}

Write-TestSection 'Online and offline collection modes'
# The script was written for WinRE and then run on a booted host as a
# rehearsal. Three groups failed for one reason: on a running system the
# kernel holds the registry hives open and DISM refuses /image: against its
# own live volume. Both modes are legitimate and each reaches evidence the
# other cannot, so the mode is detected rather than assumed.
Assert-True 'a collection mode is determined' ($text.Contains('set "COLLECTMODE=offline"'))
Assert-True 'mode is decided by comparing SystemRoot with the target' `
    ($text -match 'if /i "%SystemRoot%"=="%WINDIR_OFF%" set "COLLECTMODE=online"')
Assert-True 'the mode is reported to the operator' ($text.Contains('Collection mode :'))
Assert-True 'the mode is recorded in the manifest' ($text.Contains('Collection mode: %COLLECTMODE%'))

# Hives: copy offline, reg save online. A plain copy of a live hive fails
# with "the process cannot access the file", which says nothing about the
# machine.
Assert-True 'offline path copies the raw hives' ($text.Contains('config\SYSTEM" "%OUTDIR%\registry\SYSTEM"'))
Assert-True 'online path uses reg save' ($text.Contains('reg save HKLM\SYSTEM'))
Assert-True 'reg save output is confirmed to exist' ($text.Contains('call :notewrite'))

# Registry root: ControlSet001 offline, CurrentControlSet online. Each is
# correct only in its own mode - the Current alias is synthesised by the
# running kernel and does not exist in a loaded hive.
Assert-True 'offline queries use ControlSet001' ($text.Contains('set "RK=HKLM\OFFSYS\ControlSet001"'))
Assert-True 'online queries use the live CurrentControlSet' ($text.Contains('set "RK=HKLM\SYSTEM\CurrentControlSet"'))
Assert-True 'queries are written through the mode-selected root' ($text.Contains('reg query "%RK%\Control\CrashControl"'))
Assert-True 'the hive is only unloaded in offline mode' `
    ($text.Contains('if /i "%COLLECTMODE%"=="offline" reg unload HKLM\OFFSYS'))
# CrashDumpEnabled decides whether the NEXT bugcheck leaves anything behind,
# so it is surfaced on the console rather than only written to a file.
Assert-True 'CrashDumpEnabled is shown on the console' ($text.Contains('findstr /i "CrashDumpEnabled AutoReboot"'))

# DISM: /image: offline, /online online. The wrong one returns error 1639.
Assert-True 'offline path uses dism /image:' ($text.Contains('dism /image:"%WINVOL%\" /get-packages'))
Assert-True 'online path uses dism /online' ($text.Contains('dism /online /get-packages'))
# A variable holding a scope with nested quotes is a well-known way to
# produce a command that parses as something else; the branches are literal.
$quotedValues = @([regex]::Matches($text, '(?m)^\s*set "[A-Za-z_]\w*=(.*)"\s*$') |
                  Where-Object { $_.Groups[1].Value.Contains('"') }).Count
Assert-Equal 'no set assignment has a quote inside its value' 0 $quotedValues

# A file the kernel holds open reports size 0. Saying "0 MB" would be a claim
# about the file rather than about our ability to measure it.
Assert-True 'unmeasurable file size is reported as unknown' ($text.Contains('size not reportable'))
Assert-True 'an unmeasurable file is still attempted' ($text.Contains(':copylarge_do'))

Write-TestSection 'Argument modifiers inside subroutines'
# Inside a CALLed subroutine cmd.exe resolves argument modifiers BEFORE it
# decides a line is a comment, so a bare modifier - even in a rem line -
# aborts the script with "the following usage of the path operator is
# invalid". That shipped: a comment explaining the file-size modifier
# contained the modifier, and killed stage 12 on its first run.
#
# A modifier is only valid as %~<letters><digit> (an argument) or
# %%~<letters><var> (a FOR variable). Anything else in the subroutine
# section is a fault.
$subDef = [regex]::Match($text, '(?m)^:copyone\s*$')
Assert-True 'subroutine section located for modifier scan' $subDef.Success
$subBody = $text.Substring($subDef.Index)
$bareModifiers = @()
foreach ($m in [regex]::Matches($subBody, '(?<!%)%~[a-zA-Z]+')) {
    $tail = $subBody.Substring($m.Index + $m.Length, 1)
    if ($tail -notmatch '\d') { $bareModifiers += $m.Value + $tail }
}
Assert-Equal 'no bare argument modifier inside a subroutine' 0 $bareModifiers.Count
# The FOR-variable form is what the size lookup legitimately uses; assert it
# survived the fix rather than being removed along with the comment.
Assert-True 'the size lookup still uses the FOR-variable form' ($text -match '%%~zf')

Write-TestSection 'Microsoft no-boot requirement coverage'
# Each entry is an item Microsoft asks for when a no-boot case is reported.
# Dropping one silently would mean an incomplete submission, discovered only
# after the machine has been rebuilt and the evidence is gone.
$required = [ordered]@{
    'bcdedit /enum'            = 'bcdedit /enum >'
    'bcdedit /enum /v'         = 'bcdedit /enum /v'
    'bcdedit /enum all'        = 'bcdedit /enum all >'
    'bcdedit /enum all /v'     = 'bcdedit /enum all /v'
    'diskpart list disk'       = 'list disk | diskpart'
    'diskpart list volume'     = 'list volume | diskpart'
    'system drive dir listing' = 'dir /t:c /a /s /c /n'
    'all event logs'           = 'winevt\Logs\*.*'
    'setupapi logs'            = 'Setupapi*.log'
    'CBS logs'                 = 'Logs\CBS'
    'SrtTrail.txt'             = 'SrtTrail.txt'
    'WindowsUpdate logs'       = 'Logs\WindowsUpdate'
    'USOShared logs'           = 'USOShared\Logs'
    'DISM logs'                = 'Logs\DISM'
    'ReportingEvents.log'      = 'ReportingEvents.log'
    'SYSTEM hive'              = 'config\SYSTEM'
    'SOFTWARE hive'            = 'config\SOFTWARE'
    'RegBack SYSTEM'           = 'RegBack\SYSTEM'
    'RegBack SOFTWARE'         = 'RegBack\SOFTWARE'
    'dism /get-packages'       = '/get-packages'
    'pagefile.sys'             = 'pagefile.sys'
    'MEMORY.DMP'               = 'MEMORY.DMP'
}
foreach ($k in $required.Keys) {
    Assert-True ('collects: {0}' -f $k) ($text.Contains($required[$k]))
}

Write-TestSection 'This project''s own additions beyond the Microsoft list'
Assert-True 'COMPONENTS hive (pending component operations)' ($text.Contains('config\COMPONENTS'))
Assert-True 'dism /get-drivers' ($text.Contains('/get-drivers'))
Assert-True 'dism /get-features' ($text.Contains('/get-features'))
Assert-True 'Panther logs' ($text.Contains('Panther'))
Assert-True 'pending.xml / poqexec.log' ($text.Contains('pending.xml') -and $text.Contains('poqexec.log'))
Assert-True 'driver framework binaries' ($text.Contains('Wdf01000.sys'))
Assert-True 'boot-start driver enumeration' ($text.Contains('boot-start-drivers.txt'))
Assert-True 'minidump directory' ($text.Contains('Minidump'))

$result = Get-TestResult
Write-Host ''
Write-Host ('{0}: {1} passed, {2} failed' -f (Split-Path -Leaf $PSCommandPath), $result.Passed, $result.Failed) `
    -ForegroundColor $(if ($result.Failed -eq 0) { 'Green' } else { 'Red' })
exit $result.Failed
