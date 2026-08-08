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
rem  WHAT IT COLLECTS
rem  ----------------
rem  The full set Microsoft asks for when reporting a no-boot case, plus this
rem  project's own driver-framework and boot-start-driver evidence:
rem
rem    bcdedit (4 forms)            diskpart disk + volume list
rem    full system-drive file list  all event logs (winevt\Logs\*.*)
rem    setupapi logs                CBS logs (incl. CBS.persist.log)
rem    SrtTrail.txt                 WindowsUpdate logs
rem    USOShared logs               DISM logs
rem    ReportingEvents.log          SYSTEM + SOFTWARE + COMPONENTS hives
rem    RegBack hives                dism get-packages/drivers/features
rem    pagefile.sys                 MEMORY.DMP + minidumps
rem    Panther logs                 pending.xml / poqexec.log
rem    driver framework binaries    boot-start driver enumeration
rem
rem  HOW TO RUN IT
rem  -------------
rem    1. Boot the installation media, or press Shift while choosing Restart.
rem    2. Troubleshoot -^> Command Prompt.
rem    3. Run it from the USB stick. With no arguments it finds the Windows
rem       volume and a writable destination, then asks you to confirm:
rem
rem         E:\Collect-OfflineRecoveryEvidence.cmd
rem
rem       Or state both explicitly:
rem
rem         E:\Collect-OfflineRecoveryEvidence.cmd D: E:
rem
rem  USAGE
rem    Collect-OfflineRecoveryEvidence.cmd [WindowsVolume] [OutputDrive] [/Y]
rem
rem      WindowsVolume  Drive letter of the offline Windows installation.
rem                     Auto-detected when omitted. In WinRE this is usually
rem                     NOT C:.
rem      OutputDrive    Where to write. Auto-detected when omitted, preferring
rem                     removable media. MUST NOT be the offline volume - that
rem                     volume may be the failing device.
rem      /Y             Skip the confirmation prompt.
rem
rem  It collects and does not repair. Mixing the two destroys the evidence for
rem  the second attempt, and a bugcheck loop usually gets more than one.
rem ===========================================================================

setlocal enabledelayedexpansion

rem Size guard for the two files that can be many GB. A skipped file with a
rem recorded size is worth more than a collection that dies half way through.
rem Raise this when the destination has room - on a 128 GB stick, 65536 is
rem reasonable.
set "MAXCOPYMB=16384"

echo.
echo ============================================================
echo  Offline recovery evidence collection
echo ============================================================
echo.

set "WINVOL="
set "OUTDRIVE="
set "ASSUMEYES="

:parseargs
if "%~1"=="" goto :argsdone
if /i "%~1"=="/Y" ( set "ASSUMEYES=1" & shift & goto :parseargs )
if /i "%~1"=="-Y" ( set "ASSUMEYES=1" & shift & goto :parseargs )
if not defined WINVOL (
    set "WINVOL=%~1"
) else (
    if not defined OUTDRIVE set "OUTDRIVE=%~1"
)
shift
goto :parseargs
:argsdone

rem ===========================================================================
rem  Locate the offline Windows volume
rem ===========================================================================
if defined WINVOL (
    if "!WINVOL:~-1!"=="\" set "WINVOL=!WINVOL:~0,-1!"
) else (
    echo Searching for the offline Windows installation...
    for %%d in (C D E F G H I J K L M N O P Q R S T U V W Y Z) do (
        if not defined WINVOL (
            rem The config hive is the marker: an installed Windows always has
            rem one. X: is WinRE's own RAM disk and is excluded by the list.
            if exist "%%d:\Windows\System32\config\SYSTEM" (
                set "WINVOL=%%d:"
                echo   found: %%d:\Windows
            )
        )
    )
)

if not defined WINVOL (
    echo ERROR: no Windows installation found on any drive letter.
    echo.
    echo   Check which volumes exist:
    echo     diskpart
    echo     list volume
    echo     exit
    echo   then re-run with the letter, for example: %~nx0 D: E:
    exit /b 2
)

set "WINDIR_OFF=%WINVOL%\Windows"

rem ---------------------------------------------------------------------------
rem  Online or offline?
rem
rem  If the volume we are about to read is the one this very cmd.exe booted
rem  from, the registry hives are held open by the kernel and DISM will refuse
rem  /image: against its own live installation. Both facts are properties of
rem  the situation, not failures, and each mode can reach evidence the other
rem  cannot - so the mode is detected and the commands chosen to match.
rem
rem  %SystemRoot% is set by the running Windows. In WinRE it points at the X:
rem  RAM disk, never at the volume under investigation, so the comparison is
rem  reliable in both directions.
rem ---------------------------------------------------------------------------
set "COLLECTMODE=offline"
if defined SystemRoot (
    if /i "%SystemRoot%"=="%WINDIR_OFF%" set "COLLECTMODE=online"
)
if not exist "%WINDIR_OFF%\System32\config\SYSTEM" (
    echo ERROR: %WINDIR_OFF% does not look like a Windows installation.
    echo        Expected System32\config\SYSTEM beneath it.
    exit /b 3
)

rem ===========================================================================
rem  Locate the destination
rem ===========================================================================
if defined OUTDRIVE (
    if "!OUTDRIVE:~-1!"=="\" set "OUTDRIVE=!OUTDRIVE:~0,-1!"
) else (
    echo Searching for a writable destination...
    rem From Z: downward: removable media tends to land on higher letters, and
    rem searching down avoids picking a second fixed disk ahead of the USB
    rem stick the operator booted from.
    for %%d in (Z Y W V U T S R Q P O N M L K J I H G F E D C) do (
        if not defined OUTDRIVE (
            if /i not "%%d:"=="%WINVOL%" (
                if exist "%%d:\" (
                    rem Writability is proved by writing, not assumed: WinRE
                    rem mounts some volumes read-only and boot media is often
                    rem among them.
                    break > "%%d:\_offlinecollect_probe.tmp" 2>nul
                    if exist "%%d:\_offlinecollect_probe.tmp" (
                        del "%%d:\_offlinecollect_probe.tmp" >nul 2>&1
                        set "OUTDRIVE=%%d:"
                        echo   found writable: %%d:
                    )
                )
            )
        )
    )
)

if not defined OUTDRIVE (
    echo ERROR: no writable destination drive found.
    echo        Attach a USB stick and re-run, or name the drive:
    echo          %~nx0 %WINVOL% E:
    exit /b 4
)

if /i "%OUTDRIVE%"=="%WINVOL%" (
    echo ERROR: the destination is the offline Windows volume.
    echo        That volume may be the thing that is broken - writing to it
    echo        can lose the evidence and worsen the fault. Use removable media.
    exit /b 5
)

rem A timestamp that does not depend on locale-specific DATE formatting.
set "STAMP=%DATE%%TIME%"
set "STAMP=%STAMP:/=%"
set "STAMP=%STAMP::=%"
set "STAMP=%STAMP:.=%"
set "STAMP=%STAMP: =0%"
set "STAMP=%STAMP:~0,14%"
set "OUTDIR=%OUTDRIVE%\MSLogs-%STAMP%"

echo.
echo   Offline Windows : %WINDIR_OFF%
echo   Destination     : %OUTDIR%
echo   Collection mode : %COLLECTMODE%
echo   Max single file : %MAXCOPYMB% MB
echo.

if not defined ASSUMEYES (
    echo   Press any key to start collection, or Ctrl+C to abort.
    pause >nul
)

mkdir "%OUTDIR%" 2>nul
for %%s in (EventLogs SetupAPI CBS WindowsUpdate USOShared DISM Panther registry dumps framework misc) do mkdir "%OUTDIR%\%%s" 2>nul
if not exist "%OUTDIR%" (
    echo ERROR: could not create %OUTDIR%
    exit /b 6
)

set "MANIFEST=%OUTDIR%\00-collection-manifest.txt"
set "ERRLOG=%OUTDIR%\00-collection-errors.txt"
> "%MANIFEST%" echo Recovery evidence collection
>> "%MANIFEST%" echo Collection mode: %COLLECTMODE%
>> "%MANIFEST%" echo Collected      : %DATE% %TIME%
>> "%MANIFEST%" echo Offline volume : %WINDIR_OFF%
>> "%MANIFEST%" echo Destination    : %OUTDIR%
>> "%MANIFEST%" echo Max single file: %MAXCOPYMB% MB
>> "%MANIFEST%" echo.
> "%ERRLOG%" echo Errors and skips. An empty list below means everything was collected.
>> "%ERRLOG%" echo.

rem ===========================================================================
rem  1. Boot configuration
rem ===========================================================================
echo [ 1/16] Boot configuration...
>> "%MANIFEST%" echo [1] Boot configuration
bcdedit /enum > "%OUTDIR%\bcdedit.txt" 2>&1
bcdedit /enum /v > "%OUTDIR%\bcdedit-v.txt" 2>&1
bcdedit /enum all > "%OUTDIR%\bcdeditAll.txt" 2>&1
bcdedit /enum all /v > "%OUTDIR%\bcdeditAll-v.txt" 2>&1
if exist "%WINVOL%\Boot\BCD" bcdedit /store "%WINVOL%\Boot\BCD" /enum all > "%OUTDIR%\bcd-offline-store.txt" 2>&1
rem  find, not findstr: findstr is absent from WinRE, and its absence
rem  stopped the first recovery-environment run outright. find takes one
rem  literal string per call and no regular expressions, so each flag is its
rem  own invocation. /i is case-insensitive on both.
for %%p in (testsigning nointegritychecks recoveryenabled safeboot) do (
    type "%OUTDIR%\bcdeditAll.txt" 2>nul | find /i "%%p" >> "%MANIFEST%" 2>nul
)
>> "%MANIFEST%" echo.

rem ===========================================================================
rem  2. Disk layout
rem ===========================================================================
echo [ 2/16] Disk layout...
>> "%MANIFEST%" echo [2] Disk layout
echo list disk | diskpart > "%OUTDIR%\diskpart.txt" 2>&1
echo list volume | diskpart >> "%OUTDIR%\diskpart.txt" 2>&1
type "%OUTDIR%\diskpart.txt" >> "%MANIFEST%" 2>&1
>> "%MANIFEST%" echo.

rem ===========================================================================
rem  3. System drive file listing
rem ===========================================================================
echo [ 3/16] System drive file listing ^(this takes a while^)...
>> "%MANIFEST%" echo [3] System drive listing
dir /t:c /a /s /c /n "%WINVOL%\" > "%OUTDIR%\dir-systemdrive.log" 2>&1
>> "%MANIFEST%" echo   dir-systemdrive.log written
>> "%MANIFEST%" echo.

rem ===========================================================================
rem  4. Event logs - all of them
rem ===========================================================================
echo [ 4/16] Event logs...
>> "%MANIFEST%" echo [4] Event logs
if exist "%WINDIR_OFF%\System32\winevt\Logs\" (
    xcopy "%WINDIR_OFF%\System32\winevt\Logs\*.*" "%OUTDIR%\EventLogs\" /Y /Q /H /E >nul 2>>"%ERRLOG%"
    >> "%MANIFEST%" echo   winevt\Logs: copied
    >> "%MANIFEST%" echo   bugcheck parameters are in System.evtx, event ID 1001
    echo   event logs copied
) else (
    echo   winevt\Logs not found
    >> "%ERRLOG%" echo [4] winevt\Logs NOT FOUND
)
>> "%MANIFEST%" echo.

rem ===========================================================================
rem  5. Setup, CBS, DISM, Windows Update logs
rem ===========================================================================
echo [ 5/16] Setup, CBS, DISM, Windows Update logs...
>> "%MANIFEST%" echo [5] Setup and servicing logs
call :copytree "%WINDIR_OFF%\inf" "Setupapi*.log" "%OUTDIR%\SetupAPI\" "SetupAPI"
call :copytree "%WINDIR_OFF%\Logs\CBS" "*.*" "%OUTDIR%\CBS\" "CBS logs including CBS.persist.log"
call :copytree "%WINDIR_OFF%\Logs\WindowsUpdate" "*.*" "%OUTDIR%\WindowsUpdate\" "WindowsUpdate"
call :copytree "%WINDIR_OFF%\Logs\DISM" "*.*" "%OUTDIR%\DISM\" "DISM"
call :copytree "%WINVOL%\ProgramData\USOShared\Logs" "*.*" "%OUTDIR%\USOShared\" "USOShared"
call :copytree "%WINDIR_OFF%\Panther" "*.*" "%OUTDIR%\Panther\" "Panther"
call :copyone "%WINDIR_OFF%\SoftwareDistribution\ReportingEvents.log" "%OUTDIR%\ReportingEvents.log" "ReportingEvents.log - update apply history"
call :copyone "%WINDIR_OFF%\System32\LogFiles\Srt\SrtTrail.txt" "%OUTDIR%\SrtTrail.txt" "SrtTrail.txt - startup repair result"
>> "%MANIFEST%" echo.

rem ===========================================================================
rem  6. Registry hives - raw copies
rem ===========================================================================
echo [ 6/16] Registry hives...
>> "%MANIFEST%" echo [6] Registry hives
if /i "%COLLECTMODE%"=="online" goto :hives_online
call :copyone "%WINDIR_OFF%\System32\config\SYSTEM" "%OUTDIR%\registry\SYSTEM" "SYSTEM hive"
call :copyone "%WINDIR_OFF%\System32\config\SOFTWARE" "%OUTDIR%\registry\SOFTWARE" "SOFTWARE hive"
call :copyone "%WINDIR_OFF%\System32\config\COMPONENTS" "%OUTDIR%\registry\COMPONENTS" "COMPONENTS hive - pending component operations"
call :copyone "%WINDIR_OFF%\System32\config\RegBack\SYSTEM" "%OUTDIR%\registry\RegBack-SYSTEM" "RegBack SYSTEM"
call :copyone "%WINDIR_OFF%\System32\config\RegBack\SOFTWARE" "%OUTDIR%\registry\RegBack-SOFTWARE" "RegBack SOFTWARE"
goto :hives_done
:hives_online
rem  reg save, not copy: the kernel holds the live hives open, and a plain
rem  copy fails with "the process cannot access the file". reg save asks the
rem  registry for a consistent snapshot instead, which is both possible and
rem  more correct than copying a file being written to.
echo   using reg save ^(hives are locked on a running system^)
reg save HKLM\SYSTEM "%OUTDIR%\registry\SYSTEM" /y >nul 2>>"%ERRLOG%"
call :notewrite "%OUTDIR%\registry\SYSTEM" "SYSTEM hive via reg save"
reg save HKLM\SOFTWARE "%OUTDIR%\registry\SOFTWARE" /y >nul 2>>"%ERRLOG%"
call :notewrite "%OUTDIR%\registry\SOFTWARE" "SOFTWARE hive via reg save"
call :copyone "%WINDIR_OFF%\System32\config\COMPONENTS" "%OUTDIR%\registry\COMPONENTS" "COMPONENTS hive - pending component operations"
call :copyone "%WINDIR_OFF%\System32\config\RegBack\SYSTEM" "%OUTDIR%\registry\RegBack-SYSTEM" "RegBack SYSTEM"
call :copyone "%WINDIR_OFF%\System32\config\RegBack\SOFTWARE" "%OUTDIR%\registry\RegBack-SOFTWARE" "RegBack SOFTWARE"
:hives_done
>> "%MANIFEST%" echo.

rem ===========================================================================
rem  7. Registry queries against the offline SYSTEM hive
rem ===========================================================================
echo [ 7/16] Registry queries...
>> "%MANIFEST%" echo [7] Registry queries
set "RK=HKLM\OFFSYS\ControlSet001"
if /i "%COLLECTMODE%"=="online" goto :query_online
set "RKLOADED="
reg load HKLM\OFFSYS "%WINDIR_OFF%\System32\config\SYSTEM" >nul 2>&1
if errorlevel 1 (
    echo   WARNING: could not load the SYSTEM hive for querying
    >> "%ERRLOG%" echo [7] reg load of SYSTEM hive FAILED - the raw copy is still in registry\
    goto :skip_registry
)
goto :query_ready
:query_online
rem  On a running system the live registry answers directly, and CurrentControlSet
rem  is the correct key here precisely because it exists - the Current alias is
rem  synthesised by the running kernel. Offline it does not exist, which is why
rem  the other branch uses ControlSet001.
echo   querying the live registry ^(no hive load needed^)
set "RK=HKLM\SYSTEM\CurrentControlSet"
:query_ready
if /i "%COLLECTMODE%"=="offline" set "RKLOADED=1"
rem ControlSet001, not CurrentControlSet: the Current alias is synthesised by
rem a running system and does not exist in an offline hive.
reg query "%RK%\Control\CrashControl" > "%OUTDIR%\registry\q-crashcontrol.txt" 2>&1
reg query "%RK%\Services\Wdf01000" > "%OUTDIR%\registry\q-wdf01000.txt" 2>&1
reg query "%RK%\Control\Session Manager" /v BootExecute > "%OUTDIR%\registry\q-bootexecute.txt" 2>&1
reg query "%RK%\Control\Session Manager" /v PendingFileRenameOperations > "%OUTDIR%\registry\q-pending-renames.txt" 2>&1
reg query "%RK%\Control\CI" /s > "%OUTDIR%\registry\q-codeintegrity.txt" 2>&1
if /i "%COLLECTMODE%"=="online" reg query "HKLM\SYSTEM\Select" > "%OUTDIR%\registry\q-select.txt" 2>&1
if /i "%COLLECTMODE%"=="offline" reg query "HKLM\OFFSYS\Select" > "%OUTDIR%\registry\q-select.txt" 2>&1
rem  CrashDumpEnabled decides whether the NEXT bugcheck leaves anything to
rem  analyse. Surfacing it on the console is worth the two lines: a value of 0
rem  is worth knowing before the reboot, not after.
echo   CrashControl:
type "%OUTDIR%\registry\q-crashcontrol.txt" 2>nul | find /i "CrashDumpEnabled"
type "%OUTDIR%\registry\q-crashcontrol.txt" 2>nul | find /i "AutoReboot"

echo   enumerating boot-start drivers...
> "%OUTDIR%\registry\boot-start-drivers.txt" (
    echo Services with Start=0 ^(boot^) or Start=1 ^(system^).
    echo These load before anything can be logged, so a boot-time bugcheck is
    echo almost always one of them.
    echo ------------------------------------------------------------
    for /f "tokens=*" %%s in ('reg query "%RK%\Services" 2^>nul') do (
        for /f "tokens=3" %%v in ('reg query "%%s" /v Start 2^>nul ^| find "Start"') do (
            if "%%v"=="0x0" echo BOOT   %%s
            if "%%v"=="0x1" echo SYSTEM %%s
        )
    )
)
type "%OUTDIR%\registry\q-crashcontrol.txt" >> "%MANIFEST%" 2>&1
if /i "%COLLECTMODE%"=="offline" reg unload HKLM\OFFSYS >nul 2>&1

:skip_registry
>> "%MANIFEST%" echo.

rem ===========================================================================
rem  8. Driver framework binaries
rem ===========================================================================
echo [ 8/16] Driver framework binaries...
>> "%MANIFEST%" echo [8] Driver framework
rem  dir reports size and date but NOT file version, and the KMDF version is
rem  the number every WS2016 compatibility question turns on:
rem
rem    Windows Server 2016 (14393) ships KMDF 1.19 / UMDF 2.19
rem    Windows Server 2019 (17763) ships KMDF 1.27 / UMDF 2.27
rem    Windows Server 2022 (20348) ships KMDF 1.33 / UMDF 2.33
rem
rem  A driver whose INF requests a newer KmdfLibraryVersion than the runtime
rem  present cannot load, and that is not a signing failure - no amount of
rem  re-signing moves it. wmic is tried first because it reports Version
rem  directly; dir is kept as the fallback that always works.
> "%OUTDIR%\framework\driver-framework.txt" 2>nul echo KMDF / UMDF runtime binaries on the offline volume
>> "%OUTDIR%\framework\driver-framework.txt" echo ------------------------------------------------------------
for %%f in (Wdf01000.sys WudfPf.sys WUDFRd.sys) do (
    dir "%WINDIR_OFF%\System32\drivers\%%f" >> "%OUTDIR%\framework\driver-framework.txt" 2>&1
)
dir "%WINDIR_OFF%\System32\WUDFHost.exe" >> "%OUTDIR%\framework\driver-framework.txt" 2>&1
dir "%WINDIR_OFF%\System32\WdfCoInstaller*.dll" >> "%OUTDIR%\framework\driver-framework.txt" 2>&1

>> "%OUTDIR%\framework\driver-framework.txt" echo.
>> "%OUTDIR%\framework\driver-framework.txt" echo ---- file versions ----
call :fileversion "%WINDIR_OFF%\System32\drivers\Wdf01000.sys" "KMDF runtime"
call :fileversion "%WINDIR_OFF%\System32\drivers\WUDFRd.sys" "UMDF reflector"
call :fileversion "%WINDIR_OFF%\System32\WUDFHost.exe" "UMDF host"

rem  Every co-installer present, with its embedded version number. A package
rem  carrying WdfCoInstaller01031.dll wants KMDF 1.31; seeing that on a host
rem  whose runtime is 1.19 is the mismatch stated plainly.
>> "%OUTDIR%\framework\driver-framework.txt" echo.
>> "%OUTDIR%\framework\driver-framework.txt" echo ---- WDF co-installers present ----
dir /b /s "%WINDIR_OFF%\System32\WdfCoInstaller*.dll" >> "%OUTDIR%\framework\driver-framework.txt" 2>&1
dir /b /s "%WINDIR_OFF%\System32\DriverStore\FileRepository\WdfCoInstaller*.dll" >> "%OUTDIR%\framework\driver-framework.txt" 2>&1

rem  WDF-based drivers are exactly those whose service depends on Wdf01000.
rem  On a WDF_VIOLATION this list is the suspect pool.
>> "%OUTDIR%\framework\driver-framework.txt" echo.
>> "%OUTDIR%\framework\driver-framework.txt" echo ---- services depending on Wdf01000 ----
if /i "%COLLECTMODE%"=="online" goto :wdfdeps_online
if not defined RKLOADED goto :wdfdeps_done
:wdfdeps_online
for /f "tokens=*" %%s in ('reg query "%RK%\Services" 2^>nul') do (
    reg query "%%s" /v DependOnService 2>nul | find /i "Wdf01000" >nul && echo %%s >> "%OUTDIR%\framework\driver-framework.txt"
)
:wdfdeps_done
type "%OUTDIR%\framework\driver-framework.txt" >> "%MANIFEST%" 2>&1
>> "%MANIFEST%" echo.

rem ===========================================================================
rem  9. Package, driver and feature inventory
rem ===========================================================================
echo [ 9/16] Package and driver inventory ^(dism^)...
>> "%MANIFEST%" echo [9] Package and driver inventory
rem  DISM refuses /image: against its own live installation with error 1639.
rem  /online is the correct form there, and it also reports package states the
rem  offline form cannot - which is the whole point of running this before a
rem  reboot.
rem  Two literal command sets rather than a variable holding the scope: an
rem  /image: argument needs its own quotes, and a variable containing nested
rem  quotes is a well-known way to produce a command that parses as something
rem  else entirely. Duplicating three short lines is cheaper than that risk.
if /i "%COLLECTMODE%"=="online" goto :dism_online
dism /image:"%WINVOL%\" /get-packages /format:table > "%OUTDIR%\Get-Packages.txt" 2>&1
if errorlevel 1 >> "%ERRLOG%" echo [9] dism /get-packages returned an error - see Get-Packages.txt
dism /image:"%WINVOL%\" /get-drivers /format:table > "%OUTDIR%\Get-Drivers.txt" 2>&1
dism /image:"%WINVOL%\" /get-features /format:table > "%OUTDIR%\Get-Features.txt" 2>&1
goto :dism_done
:dism_online
dism /online /get-packages /format:table > "%OUTDIR%\Get-Packages.txt" 2>&1
if errorlevel 1 >> "%ERRLOG%" echo [9] dism /online /get-packages returned an error - see Get-Packages.txt
dism /online /get-drivers /format:table > "%OUTDIR%\Get-Drivers.txt" 2>&1
dism /online /get-features /format:table > "%OUTDIR%\Get-Features.txt" 2>&1
:dism_done
call :notewrite "%OUTDIR%\Get-Packages.txt" "Get-Packages.txt - pending package states are here"
rem  find takes a literal string and the package state column is localised,
rem  so an English-only match misses on a Japanese host - which is where this
rem  runs. Rather than guess at translations the whole table is referenced;
rem  the manifest points at it instead of trying to summarise it. A .cmd must
rem  stay plain ASCII, so a localised literal is not an option here anyway.
type "%OUTDIR%\Get-Packages.txt" 2>nul | find /i "Pending" >> "%MANIFEST%" 2>nul
>> "%MANIFEST%" echo   full package table: Get-Packages.txt ^(state column is localised^)
>> "%MANIFEST%" echo.

rem ===========================================================================
rem  10. Pending servicing operations
rem ===========================================================================
echo [10/16] Pending servicing operations...
>> "%MANIFEST%" echo [10] Pending operations
> "%OUTDIR%\misc\pending-operations.txt" (
    echo Markers that explain a configuration-change reboot loop
    echo ------------------------------------------------------------
    if exist "%WINDIR_OFF%\WinSxS\pending.xml" (
        echo pending.xml: PRESENT - servicing operations were interrupted
    ) else (
        echo pending.xml: not present
    )
    if exist "%WINDIR_OFF%\WinSxS\reboot.xml" ( echo reboot.xml: PRESENT ) else ( echo reboot.xml: not present )
    if exist "%WINDIR_OFF%\WinSxS\poqexec.log" ( echo poqexec.log: PRESENT ) else ( echo poqexec.log: not present )
)
call :copyone "%WINDIR_OFF%\WinSxS\pending.xml" "%OUTDIR%\misc\pending.xml" "pending.xml"
call :copyone "%WINDIR_OFF%\WinSxS\poqexec.log" "%OUTDIR%\misc\poqexec.log" "poqexec.log"
type "%OUTDIR%\misc\pending-operations.txt" >> "%MANIFEST%" 2>&1
>> "%MANIFEST%" echo.

rem ===========================================================================
rem  11. Minidumps
rem ===========================================================================
echo [11/16] Minidumps...
>> "%MANIFEST%" echo [11] Minidumps
if exist "%WINDIR_OFF%\Minidump\*.dmp" (
    xcopy "%WINDIR_OFF%\Minidump\*.dmp" "%OUTDIR%\dumps\Minidump\" /Y /Q /H >nul 2>>"%ERRLOG%"
    dir "%WINDIR_OFF%\Minidump\*.dmp" >> "%MANIFEST%" 2>&1
    echo   minidumps copied
) else (
    echo   no minidumps - check registry\q-crashcontrol.txt
    >> "%MANIFEST%" echo   NONE. If CrashDumpEnabled is 0 no dump was ever written.
)
>> "%MANIFEST%" echo.

rem ===========================================================================
rem  12. Large files - MEMORY.DMP and the page file
rem ===========================================================================
echo [12/16] Kernel dump and page file ^(size-checked^)...
>> "%MANIFEST%" echo [12] Large files
call :copylarge "%WINDIR_OFF%\MEMORY.DMP" "%OUTDIR%\dumps\MEMORY.DMP" "MEMORY.DMP"
call :copylarge "%WINVOL%\pagefile.sys" "%OUTDIR%\dumps\pagefile.sys" "pagefile.sys"
call :copylarge "%WINVOL%\swapfile.sys" "%OUTDIR%\dumps\swapfile.sys" "swapfile.sys"
>> "%MANIFEST%" echo.

rem ===========================================================================
rem  13. Startup repair and recovery logs
rem ===========================================================================
echo [13/16] Startup repair and recovery logs...
>> "%MANIFEST%" echo [13] Startup repair and recovery
rem  SrtTrail.txt is collected in stage 5, but the rest of the Srt directory
rem  and the recovery environment's own configuration are not, and on a host
rem  that will not boot those are the records of what Windows already tried.
rem  A repair attempt that failed is as informative as the original fault.
call :copytree "%WINDIR_OFF%\System32\LogFiles\Srt" "*.*" "%OUTDIR%\misc\Srt\" "Srt logs"
call :copyone "%WINDIR_OFF%\System32\Recovery\ReAgent.xml" "%OUTDIR%\misc\ReAgent.xml" "ReAgent.xml - recovery environment configuration"
reagentc /info > "%OUTDIR%\misc\reagentc-info.txt" 2>&1
>> "%MANIFEST%" echo   reagentc-info.txt written
>> "%MANIFEST%" echo.

rem ===========================================================================
rem  14. Bugcheck parameters
rem ===========================================================================
echo [14/16] Bugcheck parameters...
>> "%MANIFEST%" echo [14] Bugcheck parameters
rem  WDF_VIOLATION (0x10D) parameter 1 names the kind of framework contract
rem  that was violated, and that is the difference between a power-operation
rem  timeout, a handle-type error and a PnP IRP collision - three unrelated
rem  investigations. The value lives in System event 1001, and offline there
rem  is no way to read an .evtx here, so the log is copied (stage 4 already
rem  did) and this stage records the decode table beside it so whoever opens
rem  the bundle does not have to look it up.
> "%OUTDIR%\misc\bugcheck-reference.txt" echo WDF_VIOLATION ^(0x0000010D^) parameter 1 decode
>> "%OUTDIR%\misc\bugcheck-reference.txt" echo Source: Microsoft bug check 0x10D reference
>> "%OUTDIR%\misc\bugcheck-reference.txt" echo ------------------------------------------------------------
>> "%OUTDIR%\misc\bugcheck-reference.txt" echo 0x1  Framework driver timed out during a power operation
>> "%OUTDIR%\misc\bugcheck-reference.txt" echo 0x2  Attempt to acquire a lock that is already held
>> "%OUTDIR%\misc\bugcheck-reference.txt" echo 0x3  WDF Verifier fatal error on a queued I/O request
>> "%OUTDIR%\misc\bugcheck-reference.txt" echo 0x4  NULL passed where a non-NULL value was required
>> "%OUTDIR%\misc\bugcheck-reference.txt" echo 0x5  Framework object handle of the wrong type passed to a method
>> "%OUTDIR%\misc\bugcheck-reference.txt" echo 0x6  See the Microsoft sub-table
>> "%OUTDIR%\misc\bugcheck-reference.txt" echo 0x7  Object deleted incorrectly via WdfObjectDereference
>> "%OUTDIR%\misc\bugcheck-reference.txt" echo 0x8  DMA transaction object operated on in the wrong state
>> "%OUTDIR%\misc\bugcheck-reference.txt" echo 0xA  Fatal error processing a request in the queue
>> "%OUTDIR%\misc\bugcheck-reference.txt" echo 0xB  See the Microsoft sub-table
>> "%OUTDIR%\misc\bugcheck-reference.txt" echo 0xC  New state-changing PnP IRP arrived during another
>> "%OUTDIR%\misc\bugcheck-reference.txt" echo 0xD  Power policy owner received an unrequested power IRP
>> "%OUTDIR%\misc\bugcheck-reference.txt" echo 0xE  Callback returned at a different IRQL than it was called
>> "%OUTDIR%\misc\bugcheck-reference.txt" echo 0xF  Callback entered a critical region and did not leave it
>> "%OUTDIR%\misc\bugcheck-reference.txt" echo.
>> "%OUTDIR%\misc\bugcheck-reference.txt" echo Read the value from EventLogs\System.evtx, event ID 1001,
>> "%OUTDIR%\misc\bugcheck-reference.txt" echo provider Microsoft-Windows-WER-SystemErrorReporting.
>> "%MANIFEST%" echo   bugcheck-reference.txt written

rem  Dump presence is stated explicitly. "No minidump" means one thing when
rem  CrashDumpEnabled is 0 and something quite different when it is 7.
> "%OUTDIR%\misc\dump-presence.txt" echo Dump artefacts on the offline volume
>> "%OUTDIR%\misc\dump-presence.txt" echo ------------------------------------------------------------
dir "%WINDIR_OFF%\Minidump" >> "%OUTDIR%\misc\dump-presence.txt" 2>&1
dir "%WINDIR_OFF%\MEMORY.DMP" >> "%OUTDIR%\misc\dump-presence.txt" 2>&1
dir "%WINVOL%\pagefile.sys" >> "%OUTDIR%\misc\dump-presence.txt" 2>&1
type "%OUTDIR%\misc\dump-presence.txt" >> "%MANIFEST%" 2>&1
>> "%MANIFEST%" echo.

rem ===========================================================================
rem  15. Tool census
rem ===========================================================================
echo [15/16] Tool census...
>> "%MANIFEST%" echo [15] Tool census
rem  Which commands exist in the recovery environment was, until the run that
rem  prompted this stage, something this project assumed. findstr turned out
rem  to be absent and took stages 8-13 with it. Recording what is actually
rem  present turns the next surprise of this kind into a recorded fact.
> "%OUTDIR%\misc\tool-census.txt" echo Commands available in this environment
>> "%OUTDIR%\misc\tool-census.txt" echo Collection mode: %COLLECTMODE%
>> "%OUTDIR%\misc\tool-census.txt" echo ------------------------------------------------------------
for %%t in (find.exe findstr.exe reg.exe dism.exe bcdedit.exe diskpart.exe xcopy.exe robocopy.exe wmic.exe powershell.exe sc.exe tasklist.exe wevtutil.exe chkdsk.exe more.exe sort.exe fc.exe attrib.exe icacls.exe takeown.exe) do (
    call :toolcheck %%t
)
>> "%OUTDIR%\misc\tool-census.txt" echo.
>> "%OUTDIR%\misc\tool-census.txt" echo ---- System32 listing of this environment ----
dir /b "%SystemRoot%\System32\*.exe" >> "%OUTDIR%\misc\tool-census.txt" 2>&1
type "%OUTDIR%\misc\tool-census.txt" >> "%MANIFEST%" 2>&1
>> "%MANIFEST%" echo.

rem ===========================================================================
rem  16. Summary
rem ===========================================================================
echo [16/16] Summary...
>> "%MANIFEST%" echo [16] Summary
dir /s "%OUTDIR%" > "%OUTDIR%\misc\output-listing.txt" 2>&1
>> "%MANIFEST%" echo   full output listing: misc\output-listing.txt

echo.
echo ============================================================
echo  Collection complete
echo ============================================================
echo   Output   : %OUTDIR%
echo   Manifest : %MANIFEST%
echo   Errors   : %ERRLOG%
echo.
echo  An error entry is not a failed collection. Microsoft's guidance is to
echo  send what was collected even when some commands failed.
echo.
echo  Fastest route to a cause: the bugcheck parameters. On a working machine
echo  open EventLogs\System.evtx and find event ID 1001 from
echo  WER-SystemErrorReporting. For WDF_VIOLATION ^(0x10D^) the FIRST parameter
echo  names the kind of framework contract that was violated.
echo.
echo  Then compress the output folder and send it.
echo.

endlocal
exit /b 0

rem ===========================================================================
rem  :copyone <source> <destination> <label>
rem  Copy a single file, recording presence or absence either way. An absent
rem  file is itself evidence - RegBack empty on a modern build, no SrtTrail
rem  because startup repair never ran - so it is reported, not ignored.
rem ===========================================================================
:copyone
rem  Branching with goto rather than a parenthesised if-block is deliberate.
rem  cmd.exe expands variables BEFORE parsing a ( ) block, so a label
rem  containing ')' closes the block early and the remainder of the line is
rem  parsed as a command. That is what stopped the first real run. Labels are
rem  also kept free of parentheses, but this structure means a future label
rem  containing '(' or '&' cannot re-create the fault.
setlocal
set "SRC=%~1"
set "DST=%~2"
set "LABEL=%~3"
if not exist "%SRC%" goto :copyone_absent
copy /y "%SRC%" "%DST%" >nul 2>>"%ERRLOG%"
if not exist "%DST%" goto :copyone_failed
>> "%MANIFEST%" echo   %LABEL%: copied
endlocal & exit /b 0
:copyone_absent
>> "%MANIFEST%" echo   %LABEL%: not present
>> "%ERRLOG%" echo   NOT FOUND: %SRC%
endlocal & exit /b 0
:copyone_failed
>> "%MANIFEST%" echo   %LABEL%: copy FAILED
>> "%ERRLOG%" echo   COPY FAILED: %SRC%
endlocal & exit /b 0

rem ===========================================================================
rem  :copytree <source dir> <pattern> <destination> <label>
rem ===========================================================================
:copytree
rem  goto-based branching, for the reason given at :copyone.
setlocal
set "SRCDIR=%~1"
set "PATTERN=%~2"
set "DST=%~3"
set "LABEL=%~4"
if not exist "%SRCDIR%\" goto :copytree_absent
xcopy "%SRCDIR%\%PATTERN%" "%DST%" /Y /Q /H /E >nul 2>>"%ERRLOG%"
>> "%MANIFEST%" echo   %LABEL%: copied
endlocal & exit /b 0
:copytree_absent
>> "%MANIFEST%" echo   %LABEL%: source directory not present
>> "%ERRLOG%" echo   NOT FOUND: %SRCDIR%
endlocal & exit /b 0

rem ===========================================================================
rem  :copylarge <source> <destination> <label>
rem
rem  Copy a file only when it is under the size cap. A multi-GB page file can
rem  fill the destination and abort the run, and a skipped file with a
rem  recorded size is more useful than a truncated collection - the skip goes
rem  to the manifest with the actual size, so the operator can decide whether
rem  to re-run with a larger MAXCOPYMB.
rem ===========================================================================
:copylarge
setlocal
set "SRC=%~1"
set "DST=%~2"
set "LABEL=%~3"
if not exist "%SRC%" goto :copylarge_absent
rem  The file-size modifier returns 0 for a file the kernel holds open -
rem  pagefile.sys on a running system is the case that matters here.
rem  Reporting "0 MB" would be a lie about the file rather than about our
rem  ability to measure it, so an unmeasurable size is said to be unknown and
rem  the copy is attempted anyway: the attempt is what establishes whether it
rem  can be read.
rem
rem  NOTE: this comment deliberately does not spell out the modifier as a
rem  percent sequence. Inside a CALLed subroutine cmd.exe resolves argument
rem  modifiers before it decides a line is a comment, so a bare modifier in a
rem  rem line aborts the script with "the following usage of the path
rem  operator is invalid". That is exactly how this comment broke the run it
rem  was written to explain.
for %%f in ("%SRC%") do set "SIZEB=%%~zf"
set "SIZEMB=0"
set "SIZEKNOWN=1"
if not defined SIZEB set "SIZEKNOWN=0"
if "%SIZEB%"=="0" set "SIZEKNOWN=0"
if "%SIZEKNOWN%"=="1" set /a SIZEMB=%SIZEB:~0,-3%/1024
if "%SIZEKNOWN%"=="0" goto :copylarge_unknown
if %SIZEMB% GTR %MAXCOPYMB% goto :copylarge_skip
echo   %LABEL%: copying %SIZEMB% MB...
goto :copylarge_do
:copylarge_unknown
echo   %LABEL%: size not reportable ^(file is open^) - attempting copy anyway
>> "%MANIFEST%" echo   %LABEL%: size not reportable, file held open
:copylarge_do
copy /y "%SRC%" "%DST%" >nul 2>>"%ERRLOG%"
if not exist "%DST%" goto :copylarge_failed
>> "%MANIFEST%" echo   %LABEL%: copied, %SIZEMB% MB
endlocal & exit /b 0
:copylarge_skip
echo   %LABEL%: SKIPPED - %SIZEMB% MB exceeds the %MAXCOPYMB% MB cap
>> "%MANIFEST%" echo   %LABEL%: SKIPPED at %SIZEMB% MB, cap %MAXCOPYMB% MB - source %SRC%
>> "%ERRLOG%" echo   SKIPPED %LABEL% at %SIZEMB% MB. Raise MAXCOPYMB at the top of this script and re-run to collect it.
endlocal & exit /b 0
:copylarge_failed
>> "%MANIFEST%" echo   %LABEL%: copy FAILED
>> "%ERRLOG%" echo   COPY FAILED: %SRC%
endlocal & exit /b 0
:copylarge_absent
echo   %LABEL%: not present
>> "%MANIFEST%" echo   %LABEL%: not present
endlocal & exit /b 0
:notewrite
setlocal
set "CHK=%~1"
set "LABEL=%~2"
if not exist "%CHK%" goto :notewrite_missing
>> "%MANIFEST%" echo   %LABEL%: written
endlocal & exit /b 0
:notewrite_missing
>> "%MANIFEST%" echo   %LABEL%: NOT produced
>> "%ERRLOG%" echo   NOT PRODUCED: %CHK%
endlocal & exit /b 0
:fileversion
rem  Report a file's version. wmic gives it directly and is present on a full
rem  Windows; WinRE may not have it, in which case the dir line already
rem  recorded above is what there is. Either way this never fails the run.
setlocal
set "FVPATH=%~1"
set "FVLABEL=%~2"
if not exist "%FVPATH%" goto :fileversion_absent
set "FVWMI=%FVPATH:\=\\%"
wmic datafile where "name='%FVWMI%'" get Version /value 2>nul | find "Version=" >> "%OUTDIR%\framework\driver-framework.txt" 2>nul
if errorlevel 1 goto :fileversion_nowmic
>> "%OUTDIR%\framework\driver-framework.txt" echo   ^(above is %FVLABEL%^)
endlocal & exit /b 0
:fileversion_nowmic
>> "%OUTDIR%\framework\driver-framework.txt" echo   %FVLABEL%: version not readable here ^(wmic unavailable^); see the dir line above
endlocal & exit /b 0
:fileversion_absent
>> "%OUTDIR%\framework\driver-framework.txt" echo   %FVLABEL%: file not present
endlocal & exit /b 0

:toolcheck
rem  Record whether one command exists. where.exe is itself not guaranteed,
rem  so the check is a harmless invocation whose failure mode is known.
setlocal
set "TC=%~1"
if exist "%SystemRoot%\System32\%TC%" goto :toolcheck_present
>> "%OUTDIR%\misc\tool-census.txt" echo   ABSENT  %TC%
endlocal & exit /b 0
:toolcheck_present
>> "%OUTDIR%\misc\tool-census.txt" echo   present %TC%
endlocal & exit /b 0
