@echo off
setlocal EnableDelayedExpansion
:: ============================================================
::  ONYX IT DEPARTMENT - TECH TOOLS - File & Disk Utilities Module
:: ============================================================

:DISK_MENU
cls
mode con: cols=100 lines=45
title  ONYX IT DEPARTMENT TECH TOOLS - File and Disk Utilities
color 0A

echo.
echo   +------------------------------------------------------------------------------------------------+
echo   ^|                           File and Disk Utilities                                             ^|
echo   +------------------------------------------------------------------------------------------------+
echo   ^|                                                                                                ^|
echo   ^|   [1]   Show Disk Usage by Drive                                                              ^|
echo   ^|   [2]   Find Largest Files on a Drive                                                         ^|
echo   ^|   [3]   Run Disk Cleanup  (built-in)                                                         ^|
echo   ^|   [4]   Defragment / Optimize Drive                                                           ^|
echo   ^|   [5]   Take Ownership of File or Folder                                                      ^|
echo   ^|   [6]   Show Hidden Files in Explorer                                                         ^|
echo   ^|   [7]   Hide System Files  (reverse)                                                          ^|
echo   ^|   [8]   View SFC / CBS Log                                                                   ^|
echo   ^|   [9]   Open Disk Management                                                                  ^|
echo   ^|   [10]  Create Symbolic Link                                                                  ^|
echo   ^|   [11]  File Hash Checker (SHA256)                                                            ^|
echo   ^|   [12]  Find Hidden Files on a Drive                                                          ^|
echo   ^|   [0]   Back to Main Menu                                                                     ^|
echo   ^|                                                                                                ^|
echo   +------------------------------------------------------------------------------------------------+
echo.
set "DISK_CHOICE="
set /p "DISK_CHOICE=    >> Select option: "

if /i "!DISK_CHOICE!"=="1" goto D_1
if /i "!DISK_CHOICE!"=="2" goto D_2
if /i "!DISK_CHOICE!"=="3" goto D_3
if /i "!DISK_CHOICE!"=="4" goto D_4
if /i "!DISK_CHOICE!"=="5" goto D_5
if /i "!DISK_CHOICE!"=="6" goto D_6
if /i "!DISK_CHOICE!"=="7" goto D_7
if /i "!DISK_CHOICE!"=="8" goto D_8
if /i "!DISK_CHOICE!"=="9" goto D_9
if /i "!DISK_CHOICE!"=="10" goto D_10
if /i "!DISK_CHOICE!"=="11" goto D_11
if /i "!DISK_CHOICE!"=="12" goto D_12
if /i "!DISK_CHOICE!"=="A" goto D_10
if /i "!DISK_CHOICE!"=="B" goto D_11
if /i "!DISK_CHOICE!"=="C" goto D_12
if "!DISK_CHOICE!"=="0" goto :EOF
goto DISK_MENU

:D_1
cls
echo.
echo   +------------------------------------------------------------------------------------------------+
echo   ^|   Disk Space Usage by Drive                                                                   ^|
echo   +------------------------------------------------------------------------------------------------+
echo.
powershell -NoProfile -Command "Get-CimInstance Win32_LogicalDisk | Format-List Caption,FreeSpace,Size,VolumeName,FileSystem"
echo.
pause
goto DISK_MENU

:D_2
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0system_tools.ps1" -Action DiskLargest
if errorlevel 1 echo   [-] Action failed. Review the error above before retrying.
pause
goto DISK_MENU

:D_3
cls
echo.
echo   +------------------------------------------------------------------------------------------------+
echo   ^|   Windows Disk Cleanup                                                                        ^|
echo   +------------------------------------------------------------------------------------------------+
echo.
echo   [*] Launching Disk Cleanup for C:...
cleanmgr /d C:
echo.
pause
goto DISK_MENU

:D_4
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0system_tools.ps1" -Action DiskOptimize
if errorlevel 1 echo   [-] Action failed. Review the error above before retrying.
pause
goto DISK_MENU

:D_5
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0system_tools.ps1" -Action DiskOwnership
if errorlevel 1 echo   [-] Action failed. Review the error above before retrying.
pause
goto DISK_MENU

:D_6
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0system_tools.ps1" -Action DiskHidden
if errorlevel 1 echo   [-] Action failed. Review the error above before retrying.
pause
goto DISK_MENU

:D_7
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0system_tools.ps1" -Action DiskHide
if errorlevel 1 echo   [-] Action failed. Review the error above before retrying.
pause
goto DISK_MENU

:D_8
cls
echo.
echo   +------------------------------------------------------------------------------------------------+
echo   ^|   SFC / CBS Log Viewer  (last 50 lines)                                                      ^|
echo   +------------------------------------------------------------------------------------------------+
echo.
if exist "%windir%\Logs\CBS\CBS.log" (
    powershell -Command "Get-Content '%windir%\Logs\CBS\CBS.log' | Select-Object -Last 50"
) else (
    echo   [!] CBS.log not found.
    echo   [*] Run SFC scan first in the Maintenance module.
)
echo.
pause
goto DISK_MENU

:D_9
cls
echo.
echo   +------------------------------------------------------------------------------------------------+
echo   ^|   Disk Management                                                                             ^|
echo   +------------------------------------------------------------------------------------------------+
echo.
echo   [*] Opening Disk Management...
diskmgmt.msc
echo.
pause
goto DISK_MENU

:D_10
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0system_tools.ps1" -Action DiskLink
if errorlevel 1 echo   [-] Action failed. Review the error above before retrying.
pause
goto DISK_MENU

:D_A
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0system_tools.ps1" -Action DiskLink
if errorlevel 1 echo   [-] Action failed. Review the error above before retrying.
pause
goto DISK_MENU

:D_11
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0system_tools.ps1" -Action DiskHash
if errorlevel 1 echo   [-] Action failed. Review the error above before retrying.
pause
goto DISK_MENU

:D_B
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0system_tools.ps1" -Action DiskHash
if errorlevel 1 echo   [-] Action failed. Review the error above before retrying.
pause
goto DISK_MENU

:D_12
:D_C
cls
echo.
echo   +------------------------------------------------------------------------------------------------+
echo   ^|   Find Hidden Files on a Drive                                                                ^|
echo   +------------------------------------------------------------------------------------------------+
echo.
echo   [*] Attached Storage Drives (HDD/SSD/USB):
powershell -NoProfile -Command "Get-Volume | Where-Object DriveLetter | Format-Table DriveLetter, FileSystemLabel, DriveType -AutoSize | Out-String -Stream | Select-String -Pattern '\S'"
echo.
echo.
echo   [*] Scanning all available drives... This might take a while depending on drive size.
echo.
powershell -NoProfile -Command "Get-Volume | Where-Object DriveLetter | ForEach-Object { Write-Host ('`n--- Hidden Files on Drive ' + $_.DriveLetter + ' ---') -ForegroundColor Cyan; Get-ChildItem -Path ($_.DriveLetter + ':\') -Force -Recurse -ErrorAction SilentlyContinue | Where-Object { $_.Attributes -match 'Hidden' -and !$_.PSIsContainer } | Select-Object FullName | Format-Table -HideTableHeaders }"
echo.
echo   [+] Scan complete.
echo.
pause
goto DISK_MENU
