@echo off

setlocal EnableDelayedExpansion
:: ============================================================
::  KyuTools - System Maintenance & Diagnostics Module
:: ============================================================

:MAINT_MENU
cls
mode con: cols=100 lines=45
title  KyuTools - System Maintenance and Diagnostics
color 0A

echo.
echo   +------------------------------------------------------------------------------------------------+
echo   ^|                     System Maintenance and Diagnostics                                        ^|
echo   +------------------------------------------------------------------------------------------------+
echo   ^|                                                                                                ^|
echo   ^|   [1]   SFC Scan  (System File Checker)                                                      ^|
echo   ^|   [2]   DISM Health Check                                                                     ^|
echo   ^|   [3]   DISM Full Repair  (Online - needs internet)                                          ^|
echo   ^|   [4]   Full SFC + DISM Repair  (Recommended)                                               ^|
echo   ^|   [5]   Clean Temporary Files                                                                 ^|
echo   ^|   [6]   Empty Recycle Bin                                                                     ^|
echo   ^|   [7]   Clear Windows Update Cache                                                            ^|
echo   ^|   [8]   Disk Health Check  (SMART)                                                           ^|
echo   ^|   [9]   Check Disk  (CHKDSK) on C:                                                           ^|
echo   ^|   [A]   Memory Diagnostic  (schedule on restart)                                             ^|
echo   ^|   [B]   View Last 20 System Errors                                                           ^|
echo   ^|   [C]   Clear All Event Logs                                                                  ^|
echo   ^|   [D]   Open Windows Update Settings                                                          ^|
echo   ^|   [0]   Back to Main Menu                                                                     ^|
echo   ^|                                                                                                ^|
echo   +------------------------------------------------------------------------------------------------+
echo.
set "MAINT_CHOICE="
set /p "MAINT_CHOICE=    >> Select option: "

if /i "%MAINT_CHOICE%"=="1" goto M_1
if /i "%MAINT_CHOICE%"=="2" goto M_2
if /i "%MAINT_CHOICE%"=="3" goto M_3
if /i "%MAINT_CHOICE%"=="4" goto M_4
if /i "%MAINT_CHOICE%"=="5" goto M_5
if /i "%MAINT_CHOICE%"=="6" goto M_6
if /i "%MAINT_CHOICE%"=="7" goto M_7
if /i "%MAINT_CHOICE%"=="8" goto M_8
if /i "%MAINT_CHOICE%"=="9" goto M_9
if /i "%MAINT_CHOICE%"=="A" goto M_A
if /i "%MAINT_CHOICE%"=="B" goto M_B
if /i "%MAINT_CHOICE%"=="C" goto M_C
if /i "%MAINT_CHOICE%"=="D" goto M_D
if "%MAINT_CHOICE%"=="0" goto :EOF
goto MAINT_MENU

:M_1
cls
echo.
echo   +------------------------------------------------------------------------------------------------+
echo   ^|   SFC Scan  (System File Checker)                                                             ^|
echo   +------------------------------------------------------------------------------------------------+
echo.
echo   [!] This may take 10-20 minutes. Do not close this window.
echo.
sfc /scannow
echo.
echo   [+] SFC scan complete.
echo   [*] Log: %windir%\Logs\CBS\CBS.log
echo.
pause
goto MAINT_MENU

:M_2
cls
echo.
echo   +------------------------------------------------------------------------------------------------+
echo   ^|   DISM Health Check                                                                           ^|
echo   +------------------------------------------------------------------------------------------------+
echo.
echo   [*] Running CheckHealth...
DISM /Online /Cleanup-Image /CheckHealth
echo.
echo   [*] Running ScanHealth...
DISM /Online /Cleanup-Image /ScanHealth
echo.
echo   [+] DISM health scan complete.
echo.
pause
goto MAINT_MENU

:M_3
cls
echo.
echo   +------------------------------------------------------------------------------------------------+
echo   ^|   DISM Full Repair  (Online)                                                                  ^|
echo   +------------------------------------------------------------------------------------------------+
echo.
echo   [!] This may take 15-30 minutes. Requires internet.
echo.
DISM /Online /Cleanup-Image /RestoreHealth
echo.
echo   [+] DISM repair complete.
echo.
pause
goto MAINT_MENU

:M_4
cls
echo.
echo   +------------------------------------------------------------------------------------------------+
echo   ^|   Full System Repair  (DISM + SFC)                                                           ^|
echo   +------------------------------------------------------------------------------------------------+
echo.
echo   [!] This will take 20-45 minutes. Requires internet.
echo.
set "CONFIRM="
set /p "CONFIRM=   >> Proceed? (Y/N): "
if /i not "%CONFIRM%"=="Y" goto MAINT_MENU
echo.
echo   === Step 1: DISM CheckHealth ===
DISM /Online /Cleanup-Image /CheckHealth
echo.
echo   === Step 2: DISM ScanHealth ===
DISM /Online /Cleanup-Image /ScanHealth
echo.
echo   === Step 3: DISM RestoreHealth ===
DISM /Online /Cleanup-Image /RestoreHealth
echo.
echo   === Step 4: SFC Scan ===
sfc /scannow
echo.
echo   [+] Full repair complete! Please RESTART your computer.
echo.
pause
goto MAINT_MENU

:M_5
cls
echo.
echo   +------------------------------------------------------------------------------------------------+
echo   ^|   Clean Temporary Files                                                                       ^|
echo   +------------------------------------------------------------------------------------------------+
echo.
echo   [*] Clearing user temp folder...
del /f /s /q "%TEMP%\*" >nul 2>&1
for /d %%D in ("%TEMP%\*") do rd /s /q "%%D" >nul 2>&1
echo          Done.
echo   [*] Clearing system temp...
del /f /s /q "%windir%\Temp\*" >nul 2>&1
for /d %%D in ("%windir%\Temp\*") do rd /s /q "%%D" >nul 2>&1
echo          Done.
echo   [*] Clearing Prefetch...
del /f /s /q "%windir%\Prefetch\*" >nul 2>&1
echo          Done.
echo   [*] Clearing Recent list...
del /f /q "%APPDATA%\Microsoft\Windows\Recent\*" >nul 2>&1
echo          Done.
echo   [*] Clearing Chrome cache...
del /f /s /q "%LOCALAPPDATA%\Google\Chrome\User Data\Default\Cache\*" >nul 2>&1
echo          Done.
echo   [*] Clearing Edge cache...
del /f /s /q "%LOCALAPPDATA%\Microsoft\Edge\User Data\Default\Cache\*" >nul 2>&1
echo          Done.
echo.
echo   [+] Cleanup complete!
echo.
pause
goto MAINT_MENU

:M_6
cls
echo.
echo   +------------------------------------------------------------------------------------------------+
echo   ^|   Empty Recycle Bin                                                                           ^|
echo   +------------------------------------------------------------------------------------------------+
echo.
powershell -Command "Clear-RecycleBin -Confirm:$false -ErrorAction SilentlyContinue"
echo   [+] Recycle Bin emptied.
echo.
pause
goto MAINT_MENU

:M_7
cls
echo.
echo   +------------------------------------------------------------------------------------------------+
echo   ^|   Clear Windows Update Cache                                                                  ^|
echo   +------------------------------------------------------------------------------------------------+
echo.
echo   [*] Stopping services...
net stop wuauserv /y >nul 2>&1
net stop bits /y >nul 2>&1
net stop cryptsvc /y >nul 2>&1
echo          Done.
echo   [*] Deleting cache...
rd /s /q "%windir%\SoftwareDistribution\Download" >nul 2>&1
rd /s /q "%windir%\System32\catroot2" >nul 2>&1
echo          Done.
echo   [*] Restarting services...
net start wuauserv >nul 2>&1
net start bits >nul 2>&1
net start cryptsvc >nul 2>&1
echo          Done.
echo.
echo   [+] Windows Update cache cleared.
echo.
pause
goto MAINT_MENU

:M_8
cls
echo.
echo   +------------------------------------------------------------------------------------------------+
echo   ^|   Disk SMART Health Status                                                                    ^|
echo   +------------------------------------------------------------------------------------------------+
echo.
powershell -NoProfile -Command "Get-CimInstance Win32_DiskDrive | Format-List Caption,Status,Size,InterfaceType"
echo.
echo   [ Logical Drives ]
powershell -NoProfile -Command "Get-CimInstance Win32_LogicalDisk | Format-List Caption,FileSystem,FreeSpace,Size,VolumeName"
echo.
pause
goto MAINT_MENU

:M_9
cls
echo.
echo   +------------------------------------------------------------------------------------------------+
echo   ^|   Check Disk  (CHKDSK)                                                                       ^|
echo   +------------------------------------------------------------------------------------------------+
echo.
echo   [1]  Quick read-only check  (C: - no restart needed)
echo   [2]  Schedule full CHKDSK on next restart  (C:)
echo   [0]  Cancel
echo.
set "CHK_OPT="
set /p "CHK_OPT=   >> Option: "
if "%CHK_OPT%"=="1" (
    chkdsk C: /scan
    echo.
    echo   [+] Read-only scan complete.
)
if "%CHK_OPT%"=="2" (
    echo Y | chkdsk C: /f /r /x
    echo.
    echo   [+] CHKDSK scheduled for next restart.
)
echo.
pause
goto MAINT_MENU

:M_A
cls
echo.
echo   +------------------------------------------------------------------------------------------------+
echo   ^|   Windows Memory Diagnostic                                                                   ^|
echo   +------------------------------------------------------------------------------------------------+
echo.
echo   [!] This schedules a RAM test on next restart.
set "CONFIRM="
set /p "CONFIRM=   >> Schedule? (Y/N): "
if /i not "%CONFIRM%"=="Y" goto MAINT_MENU
mdsched
echo.
pause
goto MAINT_MENU

:M_B
cls
echo.
echo   +------------------------------------------------------------------------------------------------+
echo   ^|   Last 20 System Errors                                                                       ^|
echo   +------------------------------------------------------------------------------------------------+
echo.
powershell -Command "Get-EventLog -LogName System -EntryType Error -Newest 20 | Format-Table TimeGenerated,Source,Message -AutoSize -Wrap"
echo.
pause
goto MAINT_MENU

:M_C
cls
echo.
echo   +------------------------------------------------------------------------------------------------+
echo   ^|   Clear All Event Logs                                                                        ^|
echo   +------------------------------------------------------------------------------------------------+
echo.
echo   [!] WARNING: This will clear ALL Windows Event Logs.
set "CONFIRM="
set /p "CONFIRM=   >> Are you sure? (Y/N): "
if /i not "%CONFIRM%"=="Y" goto MAINT_MENU
echo.
echo   [*] Clearing logs...
for /f "tokens=*" %%L in ('wevtutil el') do wevtutil cl "%%L" >nul 2>&1
echo   [+] All event logs cleared.
echo.
pause
goto MAINT_MENU

:M_D
cls
echo.
echo   +------------------------------------------------------------------------------------------------+
echo   ^|   Windows Update                                                                              ^|
echo   +------------------------------------------------------------------------------------------------+
echo.
echo   [*] Opening Windows Update Settings...
start ms-settings:windowsupdate
echo   [+] Windows Update opened.
echo.
pause
goto MAINT_MENU
