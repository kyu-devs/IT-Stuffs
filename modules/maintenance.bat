@echo off

setlocal EnableDelayedExpansion
:: ============================================================
::  ONYX IT DEPARTMENT TECH TOOLS - System Maintenance & Diagnostics Module
:: ============================================================

:MAINT_MENU
cls
mode con: cols=100 lines=45
title  ONYX IT DEPARTMENT TECH TOOLS - System Maintenance and Diagnostics
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
echo   ^|   [10]  Memory Diagnostic  (schedule on restart)                                             ^|
echo   ^|   [11]  View Last 20 System Errors                                                           ^|
echo   ^|   [12]  Export and Clear Application/System Logs                                              ^|
echo   ^|   [13]  Open Windows Update Settings                                                          ^|
echo   ^|   [0]   Back to Main Menu                                                                     ^|
echo   ^|                                                                                                ^|
echo   +------------------------------------------------------------------------------------------------+
echo.
set "MAINT_CHOICE="
set /p "MAINT_CHOICE=    >> Select option: "

if /i "!MAINT_CHOICE!"=="1" goto M_1
if /i "!MAINT_CHOICE!"=="2" goto M_2
if /i "!MAINT_CHOICE!"=="3" goto M_3
if /i "!MAINT_CHOICE!"=="4" goto M_4
if /i "!MAINT_CHOICE!"=="5" goto M_5
if /i "!MAINT_CHOICE!"=="6" goto M_6
if /i "!MAINT_CHOICE!"=="7" goto M_7
if /i "!MAINT_CHOICE!"=="8" goto M_8
if /i "!MAINT_CHOICE!"=="9" goto M_9
if /i "!MAINT_CHOICE!"=="10" goto M_10
if /i "!MAINT_CHOICE!"=="11" goto M_11
if /i "!MAINT_CHOICE!"=="12" goto M_12
if /i "!MAINT_CHOICE!"=="13" goto M_13
if /i "!MAINT_CHOICE!"=="A" goto M_10
if /i "!MAINT_CHOICE!"=="B" goto M_11
if /i "!MAINT_CHOICE!"=="C" goto M_12
if /i "!MAINT_CHOICE!"=="D" goto M_13
if "!MAINT_CHOICE!"=="0" goto :EOF
goto MAINT_MENU

:M_1
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0system_tools.ps1" -Action RepairSFC
if errorlevel 1 echo   [-] Action failed. Review the error above before retrying.
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
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0system_tools.ps1" -Action RepairDISM
if errorlevel 1 echo   [-] Action failed. Review the error above before retrying.
pause
goto MAINT_MENU

:M_4
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0system_tools.ps1" -Action RepairCombined
if errorlevel 1 echo   [-] Action failed. Review the error above before retrying.
pause
goto MAINT_MENU

:M_5
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0system_tools.ps1" -Action TempClean
if errorlevel 1 echo   [-] Action failed. Review the error above before retrying.
pause
goto MAINT_MENU

:M_6
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0system_tools.ps1" -Action Recycle
if errorlevel 1 echo   [-] Action failed. Review the error above before retrying.
pause
goto MAINT_MENU

:M_7
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0system_tools.ps1" -Action RepairUpdates
if errorlevel 1 echo   [-] Action failed. Review the error above before retrying.
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
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0system_tools.ps1" -Action CheckDisk
if errorlevel 1 echo   [-] Action failed. Review the error above before retrying.
pause
goto MAINT_MENU

:M_10
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
if /i not "!CONFIRM!"=="Y" goto MAINT_MENU
mdsched
echo.
pause
goto MAINT_MENU

:M_11
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

:M_12
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0system_tools.ps1" -Action ClearLogs
if errorlevel 1 echo   [-] Action failed. Review the error above before retrying.
pause
goto MAINT_MENU

:M_C
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0system_tools.ps1" -Action ClearLogs
if errorlevel 1 echo   [-] Action failed. Review the error above before retrying.
pause
goto MAINT_MENU

:M_13
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
