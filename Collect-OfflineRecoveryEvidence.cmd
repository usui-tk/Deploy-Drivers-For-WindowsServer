@echo off
rem ===========================================================================
rem  Collect-OfflineRecoveryEvidence.cmd
rem
rem  Evidence collection for a Windows Server installation that will not boot.
rem
rem  WHY THIS IS A .cmd AND NOT PowerShell
rem  ------------------------------------
rem  The companion collector (Collect-WindowsServerConfigurationEvidence.ps1)
rem  needs a running Windows. When a host bugchecks in a reboot loop there is
rem  no running Windows to ask, and the Windows Recovery Environment does NOT
rem  include PowerShell - WinRE gives you cmd.exe and a handful of tools.
rem  Anything that assumes PowerShell is unusable in exactly the situation
rem  where the evidence matters most.
rem
rem  So this script uses only what WinRE guarantees: cmd, reg, dism, bcdedit,
rem  wmic (where present), xcopy, dir. It reads an OFFLINE Windows volume and
rem  never writes to it.
rem
rem  WHERE TO RUN IT
rem  ---------------
rem    1. Boot the installation media or press Shift while choosing Restart.
rem    2. Troubleshoot -> Command Prompt.
rem    3. Find the Windows volume: it is usually NOT C: in WinRE. Run
rem         diskpart  ->  list volume  ->  exit
rem       and look for the one holding \Windows.
rem    4. Run this script from removable media:
rem         E:\Collect-OfflineRecoveryEvidence.cmd D: E:\evidence
rem
rem  USAGE
rem    Collect-OfflineRecoveryEvidence.cmd <WindowsVolume> [OutputDirectory]
rem
rem      WindowsVolume    Drive letter of the offline Windows installation,
rem                       with or without a trailing backslash (e.g. D: or D:\)
rem      OutputDirectory  Where to write the evidence. Defaults to a folder
rem                       next to this script. MUST NOT be on the offline
rem                       volume - that volume may be the thing that is broken.
rem
rem  WHAT IT COLLECTS
rem    - Minidumps and MEMORY.DMP (copied - these are the primary artefact)
rem    - Crash configuration and recent driver state from the offline SYSTEM hive
rem    - Installed driver packages (dism /get-drivers)
rem    - Boot configuration (bcdedit against the offline store)
rem    - setupapi.dev.log and setupapi.setup.log
rem    - Driver framework binary inventory (KMDF/UMDF versions by file date/size)
rem    - Pending-operation markers that explain a loop
rem
rem  It does not attempt repair. Collection and repair are different
rem  activities and mixing them destroys the evidence for the second attempt.
rem ===========================================================================

setlocal enabledelayedexpansion

echo.
echo ============================================================
echo  Offline recovery evidence collection
echo ============================================================
echo.

rem ---- argument 1: the offline Windows volume --------------------------------
if "%~1"=="" (
    echo ERROR: no Windows volume specified.
    echo.
    echo   Usage: %~nx0 ^<WindowsVolume^> [OutputDirectory]
    echo   Example: %~nx0 D: E:\evidence
    echo.
    echo   In WinRE the Windows volume is usually NOT C:. To find it:
    echo     diskpart
    echo     list volume
    echo     exit
    echo.
    exit /b 2
)

set "WINVOL=%~1"
if "%WINVOL:~-1%"=="\" set "WINVOL=%WINVOL:~0,-1%"
set "WINDIR_OFF=%WINVOL%\Windows"

if not exist "%WINDIR_OFF%\System32\config\SYSTEM" (
    echo ERROR: %WINDIR_OFF% does not look like a Windows installation.
    echo        Expected to find System32\config\SYSTEM beneath it.
    echo.
    echo        Check the drive letter with diskpart / list volume.
    exit /b 3
)
echo   Offline Windows : %WINDIR_OFF%

rem ---- argument 2: output directory ------------------------------------------
if "%~2"=="" (
    set "OUTROOT=%~dp0offline-evidence"
) else (
    set "OUTROOT=%~2"
)

rem A timestamp without relying on locale-dependent %DATE%: read it from the
rem file system instead, which is stable everywhere this runs.
for /f "tokens=1-6 delims=/:. " %%a in ('echo %DATE% %TIME%') do set "STAMP=%%a%%b%%c-%%d%%e"
set "STAMP=%STAMP: =0%"
set "OUTDIR=%OUTROOT%\offline-%STAMP%"

echo   Output          : %OUTDIR%
echo.

rem Refuse to write onto the volume being examined: if that volume is failing,
rem writing to it can both lose the evidence and make the fault worse.
if /i "%OUTDIR:~0,2%"=="%WINVOL%" (
    echo ERROR: the output directory is on the offline Windows volume.
    echo        Write to removable media instead - that volume may be the
    echo        thing that is broken.
    exit /b 4
)

mkdir "%OUTDIR%" 2>nul
mkdir "%OUTDIR%\dumps" 2>nul
mkdir "%OUTDIR%\registry" 2>nul
mkdir "%OUTDIR%\logs" 2>nul
if not exist "%OUTDIR%" (
    echo ERROR: could not create %OUTDIR%
    exit /b 5
)

set "MANIFEST=%OUTDIR%\collection-manifest.txt"
echo Offline recovery evidence collection > "%MANIFEST%"
echo Collected      : %DATE% %TIME% >> "%MANIFEST%"
echo Offline volume : %WINDIR_OFF% >> "%MANIFEST%"
echo Collector host : %COMPUTERNAME% >> "%MANIFEST%"
echo. >> "%MANIFEST%"

rem ===========================================================================
rem  1. Crash dumps - the primary artefact
rem ===========================================================================
echo [1/8] Crash dumps...
echo [1] Crash dumps >> "%MANIFEST%"

set "DUMPCOUNT=0"
if exist "%WINDIR_OFF%\Minidump\*.dmp" (
    for %%f in ("%WINDIR_OFF%\Minidump\*.dmp") do set /a DUMPCOUNT+=1
    xcopy "%WINDIR_OFF%\Minidump\*.dmp" "%OUTDIR%\dumps\" /Y /Q >nul 2>&1
    dir "%WINDIR_OFF%\Minidump\*.dmp" >> "%MANIFEST%" 2>&1
    echo   minidumps copied: !DUMPCOUNT!
) else (
    echo   no minidumps found
    echo   NONE - check CrashDumpEnabled in the registry section below >> "%MANIFEST%"
)

if exist "%WINDIR_OFF%\MEMORY.DMP" (
    echo   MEMORY.DMP present - copying, this may take a while
    dir "%WINDIR_OFF%\MEMORY.DMP" >> "%MANIFEST%" 2>&1
    xcopy "%WINDIR_OFF%\MEMORY.DMP" "%OUTDIR%\dumps\" /Y /Q >nul 2>&1
) else (
    echo   no MEMORY.DMP
    echo   MEMORY.DMP: not present >> "%MANIFEST%"
)
echo. >> "%MANIFEST%"

rem ===========================================================================
rem  2. Offline SYSTEM hive
rem ===========================================================================
echo [2/8] Registry - SYSTEM hive...
echo [2] Registry >> "%MANIFEST%"

reg load HKLM\OFFSYS "%WINDIR_OFF%\System32\config\SYSTEM" >nul 2>&1
if errorlevel 1 (
    echo   WARNING: could not load the SYSTEM hive
    echo   SYSTEM hive load FAILED >> "%MANIFEST%"
    goto :skip_registry
)

rem ControlSet001 rather than CurrentControlSet: the Current alias only exists
rem in a running system, and an offline hive does not have it.
reg query "HKLM\OFFSYS\ControlSet001\Control\CrashControl" > "%OUTDIR%\registry\crashcontrol.txt" 2>&1
reg query "HKLM\OFFSYS\Select" > "%OUTDIR%\registry\select.txt" 2>&1
reg export "HKLM\OFFSYS\ControlSet001\Services" "%OUTDIR%\registry\services.reg" /y >nul 2>&1
reg query "HKLM\OFFSYS\ControlSet001\Services\Wdf01000" > "%OUTDIR%\registry\wdf01000.txt" 2>&1
reg query "HKLM\OFFSYS\ControlSet001\Control\Session Manager\PendingFileRenameOperations" > "%OUTDIR%\registry\pending-file-renames.txt" 2>&1
reg query "HKLM\OFFSYS\ControlSet001\Control\Session Manager" /v BootExecute > "%OUTDIR%\registry\bootexecute.txt" 2>&1
reg query "HKLM\OFFSYS\ControlSet001\Control\CI" > "%OUTDIR%\registry\codeintegrity.txt" 2>&1

rem Boot-start drivers are the ones that can bugcheck before anything can be
rem logged. Listing them narrows a boot-time WDF_VIOLATION considerably.
echo   enumerating boot-start drivers ^(this takes a moment^)
> "%OUTDIR%\registry\boot-start-drivers.txt" (
    echo Services with Start=0 ^(boot^) or Start=1 ^(system^)
    echo ------------------------------------------------------------
    for /f "tokens=*" %%s in ('reg query "HKLM\OFFSYS\ControlSet001\Services" 2^>nul') do (
        for /f "tokens=3" %%v in ('reg query "%%s" /v Start 2^>nul ^| find "Start"') do (
            if "%%v"=="0x0" echo BOOT   %%s
            if "%%v"=="0x1" echo SYSTEM %%s
        )
    )
)

echo   CrashControl and driver services exported
echo   SYSTEM hive: exported >> "%MANIFEST%"
type "%OUTDIR%\registry\crashcontrol.txt" >> "%MANIFEST%" 2>&1
reg unload HKLM\OFFSYS >nul 2>&1

:skip_registry
echo. >> "%MANIFEST%"

rem ===========================================================================
rem  3. Driver framework binaries
rem ===========================================================================
echo [3/8] Driver framework binaries...
echo [3] Driver framework >> "%MANIFEST%"
> "%OUTDIR%\driver-framework.txt" (
    echo KMDF / UMDF runtime binaries on the offline volume
    echo ------------------------------------------------------------
    echo A driver package requesting a KMDF version newer than the runtime
    echo present here cannot load, regardless of how it is signed.
    echo.
    dir "%WINDIR_OFF%\System32\drivers\Wdf01000.sys" 2>&1
    dir "%WINDIR_OFF%\System32\drivers\WudfPf.sys" 2>&1
    dir "%WINDIR_OFF%\System32\drivers\WUDFRd.sys" 2>&1
    dir "%WINDIR_OFF%\System32\WUDFHost.exe" 2>&1
    dir "%WINDIR_OFF%\System32\WdfCoInstaller*.dll" 2>&1
)
type "%OUTDIR%\driver-framework.txt" >> "%MANIFEST%" 2>&1
echo. >> "%MANIFEST%"

rem ===========================================================================
rem  4. Installed driver packages
rem ===========================================================================
echo [4/8] Driver packages (dism)...
echo [4] Driver packages >> "%MANIFEST%"
dism /image:"%WINVOL%\" /get-drivers /format:table > "%OUTDIR%\dism-drivers.txt" 2>&1
if errorlevel 1 (
    echo   dism reported an error - see dism-drivers.txt
    echo   dism /get-drivers FAILED >> "%MANIFEST%"
) else (
    echo   third-party driver packages listed
    echo   dism /get-drivers: OK >> "%MANIFEST%"
)
dism /image:"%WINVOL%\" /get-packages /format:table > "%OUTDIR%\dism-packages.txt" 2>&1
echo. >> "%MANIFEST%"

rem ===========================================================================
rem  5. Boot configuration
rem ===========================================================================
echo [5/8] Boot configuration...
echo [5] Boot configuration >> "%MANIFEST%"
bcdedit /store "%WINVOL%\Boot\BCD" /enum all > "%OUTDIR%\bcd-store.txt" 2>&1
bcdedit /enum all > "%OUTDIR%\bcd-active.txt" 2>&1
echo   BCD exported ^(testsigning / nointegritychecks are visible here^)
findstr /i "testsigning nointegritychecks recoveryenabled" "%OUTDIR%\bcd-store.txt" >> "%MANIFEST%" 2>&1
echo. >> "%MANIFEST%"

rem ===========================================================================
rem  6. Setup and servicing logs
rem ===========================================================================
echo [6/8] Setup logs...
echo [6] Setup logs >> "%MANIFEST%"
if exist "%WINDIR_OFF%\INF\setupapi.dev.log" (
    xcopy "%WINDIR_OFF%\INF\setupapi.dev.log" "%OUTDIR%\logs\" /Y /Q >nul 2>&1
    echo   setupapi.dev.log copied
    echo   setupapi.dev.log: copied >> "%MANIFEST%"
) else (
    echo   setupapi.dev.log not found
    echo   setupapi.dev.log: NOT FOUND >> "%MANIFEST%"
)
if exist "%WINDIR_OFF%\INF\setupapi.setup.log" xcopy "%WINDIR_OFF%\INF\setupapi.setup.log" "%OUTDIR%\logs\" /Y /Q >nul 2>&1
if exist "%WINDIR_OFF%\Logs\CBS\CBS.log" xcopy "%WINDIR_OFF%\Logs\CBS\CBS.log" "%OUTDIR%\logs\" /Y /Q >nul 2>&1
if exist "%WINDIR_OFF%\Panther\setupact.log" xcopy "%WINDIR_OFF%\Panther\setupact.log" "%OUTDIR%\logs\" /Y /Q >nul 2>&1
if exist "%WINDIR_OFF%\Panther\setuperr.log" xcopy "%WINDIR_OFF%\Panther\setuperr.log" "%OUTDIR%\logs\" /Y /Q >nul 2>&1
echo. >> "%MANIFEST%"

rem ===========================================================================
rem  7. Event logs
rem ===========================================================================
echo [7/8] Event logs...
echo [7] Event logs >> "%MANIFEST%"
if exist "%WINDIR_OFF%\System32\winevt\Logs\System.evtx" (
    xcopy "%WINDIR_OFF%\System32\winevt\Logs\System.evtx" "%OUTDIR%\logs\" /Y /Q >nul 2>&1
    echo   System.evtx copied ^(bugcheck parameters are in event 1001^)
    echo   System.evtx: copied >> "%MANIFEST%"
) else (
    echo   System.evtx not found
    echo   System.evtx: NOT FOUND >> "%MANIFEST%"
)
if exist "%WINDIR_OFF%\System32\winevt\Logs\Application.evtx" xcopy "%WINDIR_OFF%\System32\winevt\Logs\Application.evtx" "%OUTDIR%\logs\" /Y /Q >nul 2>&1
echo. >> "%MANIFEST%"

rem ===========================================================================
rem  8. Pending operations
rem ===========================================================================
echo [8/8] Pending operations...
echo [8] Pending operations >> "%MANIFEST%"
> "%OUTDIR%\pending-operations.txt" (
    echo Markers that explain a configuration-change reboot loop
    echo ------------------------------------------------------------
    if exist "%WINDIR_OFF%\WinSxS\pending.xml" (
        echo pending.xml: PRESENT - servicing operations were interrupted
        dir "%WINDIR_OFF%\WinSxS\pending.xml" 2>&1
    ) else (
        echo pending.xml: not present
    )
    if exist "%WINDIR_OFF%\WinSxS\reboot.xml" ( echo reboot.xml: PRESENT ) else ( echo reboot.xml: not present )
)
type "%OUTDIR%\pending-operations.txt" >> "%MANIFEST%" 2>&1

echo.
echo ============================================================
echo  Collection complete
echo ============================================================
echo   Output   : %OUTDIR%
echo   Manifest : %MANIFEST%
echo.
echo  Next: the bugcheck parameters are the fastest route to a cause.
echo  On a working machine, open the copied System.evtx and look for
echo  event ID 1001 from WER-SystemErrorReporting. For WDF_VIOLATION
echo  (0x10D) the FIRST parameter names the kind of framework contract
echo  that was violated, which decides where to look next.
echo.

endlocal
exit /b 0
