@echo off

setlocal EnableDelayedExpansion
:: ============================================================
::  ONYX IT DEPARTMENT TECH TOOLS - System Information Module
:: ============================================================

:SYSINFO_MENU
cls
mode con: cols=100 lines=45
title  ONYX IT DEPARTMENT TECH TOOLS - System Information
color 0A

echo.
echo   +------------------------------------------------------------------------------------------------+
echo   ^|                           System Information Viewer                                           ^|
echo   +------------------------------------------------------------------------------------------------+
echo   ^|                                                                                                ^|
echo   ^|   [1]   Full System Overview                                                                  ^|
echo   ^|   [2]   CPU Information                                                                       ^|
echo   ^|   [3]   RAM / Memory Status                                                                   ^|
echo   ^|   [4]   GPU Information                                                                       ^|
echo   ^|   [5]   Disk Information                                                                      ^|
echo   ^|   [6]   Battery Report  (saved to Desktop)                                                   ^|
echo   ^|   [7]   Running Processes                                                                     ^|
echo   ^|   [8]   Startup Programs                                                                      ^|
echo   ^|   [9]   Environment Variables                                                                 ^|
echo   ^|   [10]  Export Full Report to Desktop                                                         ^|
echo   ^|   [0]   Back to Main Menu                                                                     ^|
echo   ^|                                                                                                ^|
echo   +------------------------------------------------------------------------------------------------+
echo.
set "SI_CHOICE="
set /p "SI_CHOICE=    >> Select option: "

if /i "%SI_CHOICE%"=="1" goto SI_1
if /i "%SI_CHOICE%"=="2" goto SI_2
if /i "%SI_CHOICE%"=="3" goto SI_3
if /i "%SI_CHOICE%"=="4" goto SI_4
if /i "%SI_CHOICE%"=="5" goto SI_5
if /i "%SI_CHOICE%"=="6" goto SI_6
if /i "%SI_CHOICE%"=="7" goto SI_7
if /i "%SI_CHOICE%"=="8" goto SI_8
if /i "%SI_CHOICE%"=="9" goto SI_9
if /i "%SI_CHOICE%"=="10" goto SI_10
if /i "%SI_CHOICE%"=="A" goto SI_10
if "%SI_CHOICE%"=="0" goto :EOF
goto SYSINFO_MENU

:SI_1
cls
echo.
echo   +------------------------------------------------------------------------------------------------+
echo   ^|   System Overview                                                                             ^|
echo   +------------------------------------------------------------------------------------------------+
echo.
systeminfo | findstr /i "Host\|OS\|Version\|Manufacturer\|Model\|Memory\|Processor\|Boot"
echo.
echo   [ Network ]
ipconfig | findstr /i "IPv4\|Gateway"
echo.
pause
goto SYSINFO_MENU

:SI_2
cls
echo.
echo   +------------------------------------------------------------------------------------------------+
echo   ^|   CPU Information                                                                             ^|
echo   +------------------------------------------------------------------------------------------------+
echo.
powershell -NoProfile -Command "Get-CimInstance Win32_Processor | Format-List Name,NumberOfCores,NumberOfLogicalProcessors,MaxClockSpeed,CurrentClockSpeed,LoadPercentage"
echo.
pause
goto SYSINFO_MENU

:SI_3
cls
echo.
echo   +------------------------------------------------------------------------------------------------+
echo   ^|   RAM / Memory Information                                                                    ^|
echo   +------------------------------------------------------------------------------------------------+
echo.
powershell -NoProfile -Command "Get-CimInstance Win32_PhysicalMemory | Format-List BankLabel,Capacity,Speed,Manufacturer"
echo.
echo   [ Summary ]
systeminfo | findstr /i "memory"
echo.
pause
goto SYSINFO_MENU

:SI_4
cls
echo.
echo   +------------------------------------------------------------------------------------------------+
echo   ^|   GPU Information                                                                             ^|
echo   +------------------------------------------------------------------------------------------------+
echo.
powershell -NoProfile -Command "Get-CimInstance Win32_VideoController | Format-List Name,AdapterRAM,DriverVersion,CurrentRefreshRate"
echo.
pause
goto SYSINFO_MENU

:SI_5
cls
echo.
echo   +------------------------------------------------------------------------------------------------+
echo   ^|   Disk Information                                                                            ^|
echo   +------------------------------------------------------------------------------------------------+
echo.
powershell -NoProfile -Command "Get-CimInstance Win32_DiskDrive | Format-List Model,Size,Status,InterfaceType"
echo.
echo   [ Logical Drives ]
powershell -NoProfile -Command "Get-CimInstance Win32_LogicalDisk | Format-List Caption,FileSystem,FreeSpace,Size,VolumeName"
echo.
pause
goto SYSINFO_MENU

:SI_6
cls
echo.
echo   +------------------------------------------------------------------------------------------------+
echo   ^|   Battery Status                                                                              ^|
echo   +------------------------------------------------------------------------------------------------+
echo.
powercfg /batteryreport /output "%USERPROFILE%\Desktop\BatteryReport.html" >nul 2>&1
if exist "%USERPROFILE%\Desktop\BatteryReport.html" (
    echo   [+] Battery report generated on your Desktop.
    start "" "%USERPROFILE%\Desktop\BatteryReport.html"
) else (
    echo   [!] No battery found or no sensor available.
)
powershell -NoProfile -Command "Get-CimInstance Win32_Battery -ErrorAction SilentlyContinue | Format-List Name,EstimatedChargeRemaining,BatteryStatus"
echo.
pause
goto SYSINFO_MENU

:SI_7
cls
echo.
echo   +------------------------------------------------------------------------------------------------+
echo   ^|   Running Processes                                                                           ^|
echo   +------------------------------------------------------------------------------------------------+
echo.
tasklist /fo table
echo.
pause
goto SYSINFO_MENU

:SI_8
cls
echo.
echo   +------------------------------------------------------------------------------------------------+
echo   ^|   Startup Programs                                                                            ^|
echo   +------------------------------------------------------------------------------------------------+
echo.
echo   [ Current User ]
reg query "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" 2>nul
echo.
echo   [ Local Machine ]
reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" 2>nul
echo.
pause
goto SYSINFO_MENU

:SI_9
cls
echo.
echo   +------------------------------------------------------------------------------------------------+
echo   ^|   Environment Variables                                                                       ^|
echo   +------------------------------------------------------------------------------------------------+
echo.
set
echo.
pause
goto SYSINFO_MENU

:SI_10
:SI_A
cls
echo.
echo   +------------------------------------------------------------------------------------------------+
echo   ^|   Export Full System Report to Desktop                                                        ^|
echo   +------------------------------------------------------------------------------------------------+
echo.
set "REPORT=%USERPROFILE%\Desktop\OnyxTools_Report.txt"
echo ONYX IT DEPARTMENT TECH TOOLS System Report            > "%REPORT%"
echo Generated: %date% %time%                         >> "%REPORT%"
echo =================================================  >> "%REPORT%"
systeminfo                                             >> "%REPORT%"
echo =[ CPU ]=========================================  >> "%REPORT%"
powershell -NoProfile -Command "Get-CimInstance Win32_Processor | Format-List Name,NumberOfCores,MaxClockSpeed" >> "%REPORT%"
echo =[ RAM ]=========================================  >> "%REPORT%"
powershell -NoProfile -Command "Get-CimInstance Win32_PhysicalMemory | Format-List BankLabel,Capacity,Speed" >> "%REPORT%"
echo =[ GPU ]=========================================  >> "%REPORT%"
powershell -NoProfile -Command "Get-CimInstance Win32_VideoController | Format-List Name,AdapterRAM" >> "%REPORT%"
echo =[ DISK ]========================================  >> "%REPORT%"
powershell -NoProfile -Command "Get-CimInstance Win32_DiskDrive | Format-List Model,Size,Status" >> "%REPORT%"
echo =[ NETWORK ]=====================================  >> "%REPORT%"
ipconfig /all                                          >> "%REPORT%"
echo.
echo   [+] Report saved to Desktop: OnyxTools_Report.txt
echo.
pause
goto SYSINFO_MENU
