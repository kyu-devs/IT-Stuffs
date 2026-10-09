@echo off

setlocal EnableDelayedExpansion
:: ============================================================
::  KyuTools - Performance Tweaks Module
:: ============================================================

:PERF_MENU
cls
mode con: cols=100 lines=45
title  KyuTools - Performance Tweaks
color 0A

echo.
echo   +------------------------------------------------------------------------------------------------+
echo   ^|                              Performance Tweaks                                               ^|
echo   +------------------------------------------------------------------------------------------------+
echo   ^|                                                                                                ^|
echo   ^|   [1]   Set Power Plan to High Performance                                                   ^|
echo   ^|   [2]   Enable Ultimate Performance Plan                                                     ^|
echo   ^|   [3]   Disable Visual Effects  (Faster UI)                                                  ^|
echo   ^|   [4]   Remove Startup Delay                                                                  ^|
echo   ^|   [5]   Optimize RAM  (Clear Standby Memory)                                                 ^|
echo   ^|   [6]   Disable Search Indexing                                                               ^|
echo   ^|   [7]   Disable SysMain / Superfetch                                                         ^|
echo   ^|   [8]   Disable Xbox Game Bar                                                                ^|
echo   ^|   [9]   Enable Game Mode                                                                      ^|
echo   ^|   [A]   Apply ALL Performance Tweaks  (Recommended)                                          ^|
echo   ^|   [0]   Back to Main Menu                                                                     ^|
echo   ^|                                                                                                ^|
echo   +------------------------------------------------------------------------------------------------+
echo.
set "PERF_CHOICE="
set /p "PERF_CHOICE=    >> Select option: "

if /i "%PERF_CHOICE%"=="1" goto PF_1
if /i "%PERF_CHOICE%"=="2" goto PF_2
if /i "%PERF_CHOICE%"=="3" goto PF_3
if /i "%PERF_CHOICE%"=="4" goto PF_4
if /i "%PERF_CHOICE%"=="5" goto PF_5
if /i "%PERF_CHOICE%"=="6" goto PF_6
if /i "%PERF_CHOICE%"=="7" goto PF_7
if /i "%PERF_CHOICE%"=="8" goto PF_8
if /i "%PERF_CHOICE%"=="9" goto PF_9
if /i "%PERF_CHOICE%"=="A" goto PF_A
if "%PERF_CHOICE%"=="0" goto :EOF
goto PERF_MENU

:PF_1
cls
echo.
echo   +------------------------------------------------------------------------------------------------+
echo   ^|   High Performance Power Plan                                                                 ^|
echo   +------------------------------------------------------------------------------------------------+
echo.
powercfg -setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c >nul 2>&1
echo   [+] High Performance power plan activated.
echo.
pause
goto PERF_MENU

:PF_2
cls
echo.
echo   +------------------------------------------------------------------------------------------------+
echo   ^|   Ultimate Performance Power Plan                                                             ^|
echo   +------------------------------------------------------------------------------------------------+
echo.
echo   [*] Enabling Ultimate Performance plan...
powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 >nul 2>&1
powercfg -setactive e9a42b02-d5df-448d-aa00-03f14749eb61 >nul 2>&1
echo   [+] Ultimate Performance plan activated.
echo.
pause
goto PERF_MENU

:PF_3
cls
echo.
echo   +------------------------------------------------------------------------------------------------+
echo   ^|   Disable Visual Effects                                                                      ^|
echo   +------------------------------------------------------------------------------------------------+
echo.
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" /v VisualFXSetting /t REG_DWORD /d 2 /f >nul
reg add "HKCU\Control Panel\Desktop\WindowMetrics" /v MinAnimate /t REG_SZ /d 0 /f >nul
reg add "HKCU\Software\Microsoft\Windows\DWM" /v EnableAeroPeek /t REG_DWORD /d 0 /f >nul
echo   [+] Visual effects minimized.
echo   [*] Log out and back in to apply fully.
echo.
pause
goto PERF_MENU

:PF_4
cls
echo.
echo   +------------------------------------------------------------------------------------------------+
echo   ^|   Remove Startup Delay                                                                        ^|
echo   +------------------------------------------------------------------------------------------------+
echo.
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Serialize" /v StartupDelayInMSec /t REG_DWORD /d 0 /f >nul
echo   [+] Startup delay removed.
echo.
pause
goto PERF_MENU

:PF_5
cls
echo.
echo   +------------------------------------------------------------------------------------------------+
echo   ^|   RAM Optimization                                                                            ^|
echo   +------------------------------------------------------------------------------------------------+
echo.
echo   [*] Clearing standby memory...
powershell -Command "[System.GC]::Collect(); [System.GC]::WaitForPendingFinalizers()"
echo.
echo   [ Memory Status ]
powershell -NoProfile -Command "Get-CimInstance Win32_OperatingSystem | Format-List FreePhysicalMemory,TotalVisibleMemorySize"
echo.
pause
goto PERF_MENU

:PF_6
cls
echo.
echo   +------------------------------------------------------------------------------------------------+
echo   ^|   Disable Search Indexing                                                                     ^|
echo   +------------------------------------------------------------------------------------------------+
echo.
sc config WSearch start= disabled >nul
net stop WSearch >nul 2>&1
echo   [+] Search indexing disabled.
echo.
pause
goto PERF_MENU

:PF_7
cls
echo.
echo   +------------------------------------------------------------------------------------------------+
echo   ^|   Disable SysMain / Superfetch                                                                ^|
echo   +------------------------------------------------------------------------------------------------+
echo.
sc config SysMain start= disabled >nul
net stop SysMain >nul 2>&1
echo   [+] SysMain / Superfetch disabled.
echo.
pause
goto PERF_MENU

:PF_8
cls
echo.
echo   +------------------------------------------------------------------------------------------------+
echo   ^|   Disable Xbox Game Bar                                                                       ^|
echo   +------------------------------------------------------------------------------------------------+
echo.
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR" /v AppCaptureEnabled /t REG_DWORD /d 0 /f >nul
reg add "HKCU\System\GameConfigStore" /v GameDVR_Enabled /t REG_DWORD /d 0 /f >nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\GameDVR" /v AllowGameDVR /t REG_DWORD /d 0 /f >nul
echo   [+] Xbox Game Bar disabled.
echo.
pause
goto PERF_MENU

:PF_9
cls
echo.
echo   +------------------------------------------------------------------------------------------------+
echo   ^|   Enable Game Mode                                                                            ^|
echo   +------------------------------------------------------------------------------------------------+
echo.
reg add "HKCU\Software\Microsoft\GameBar" /v AutoGameModeEnabled /t REG_DWORD /d 1 /f >nul
reg add "HKCU\System\GameConfigStore" /v GameDVR_FSEBehaviorMode /t REG_DWORD /d 2 /f >nul
reg add "HKCU\System\GameConfigStore" /v GameDVR_HonorUserFSEBehaviorMode /t REG_DWORD /d 1 /f >nul
echo   [+] Game Mode enabled.
echo.
pause
goto PERF_MENU

:PF_A
cls
echo.
echo   +------------------------------------------------------------------------------------------------+
echo   ^|   Apply ALL Performance Tweaks                                                                ^|
echo   +------------------------------------------------------------------------------------------------+
echo.
echo   [1/8] Ultimate Performance power plan...
powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 >nul 2>&1
powercfg -setactive e9a42b02-d5df-448d-aa00-03f14749eb61 >nul 2>&1
echo          Done.
echo   [2/8] Disabling visual effects...
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" /v VisualFXSetting /t REG_DWORD /d 2 /f >nul
echo          Done.
echo   [3/8] Removing startup delay...
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Serialize" /v StartupDelayInMSec /t REG_DWORD /d 0 /f >nul
echo          Done.
echo   [4/8] Disabling SysMain...
sc config SysMain start= disabled >nul & net stop SysMain >nul 2>&1
echo          Done.
echo   [5/8] Optimizing processor scheduling...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\PriorityControl" /v Win32PrioritySeparation /t REG_DWORD /d 38 /f >nul
echo          Done.
echo   [6/8] Disabling Xbox Game DVR...
reg add "HKCU\System\GameConfigStore" /v GameDVR_Enabled /t REG_DWORD /d 0 /f >nul
echo          Done.
echo   [7/8] Enabling Hardware GPU Scheduling...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" /v HwSchMode /t REG_DWORD /d 2 /f >nul
echo          Done.
echo   [8/8] Enabling Game Mode...
reg add "HKCU\Software\Microsoft\GameBar" /v AutoGameModeEnabled /t REG_DWORD /d 1 /f >nul
echo          Done.
echo.
echo   [+] All performance tweaks applied! Please RESTART your computer.
echo.
pause
goto PERF_MENU
