@echo off

setlocal EnableDelayedExpansion
:: ============================================================
::  ONYX IT DEPARTMENT TECH TOOLS - Performance Tweaks Module
:: ============================================================

:PERF_MENU
cls
mode con: cols=100 lines=45
title  ONYX IT DEPARTMENT TECH TOOLS - Performance Tweaks
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
echo   ^|   [5]   Inspect Memory Pressure and Large Processes                                           ^|
echo   ^|   [6]   Temporarily Stop Search Indexing                                                      ^|
echo   ^|   [7]   Temporarily Stop SysMain / Superfetch                                                  ^|
echo   ^|   [8]   Disable Xbox Game Bar                                                                ^|
echo   ^|   [9]   Enable Game Mode                                                                      ^|
echo   ^|   [10]  Apply UI and Gaming Preferences (Backed Up)                                           ^|
echo   ^|   [11]  Restore a Saved Registry Settings Backup                                              ^|
echo   ^|   [0]   Back to Main Menu                                                                     ^|
echo   ^|                                                                                                ^|
echo   +------------------------------------------------------------------------------------------------+
echo.
set "PERF_CHOICE="
set /p "PERF_CHOICE=    >> Select option: "

if /i "!PERF_CHOICE!"=="1" goto PF_1
if /i "!PERF_CHOICE!"=="2" goto PF_2
if /i "!PERF_CHOICE!"=="3" goto PF_3
if /i "!PERF_CHOICE!"=="4" goto PF_4
if /i "!PERF_CHOICE!"=="5" goto PF_5
if /i "!PERF_CHOICE!"=="6" goto PF_6
if /i "!PERF_CHOICE!"=="7" goto PF_7
if /i "!PERF_CHOICE!"=="8" goto PF_8
if /i "!PERF_CHOICE!"=="9" goto PF_9
if /i "!PERF_CHOICE!"=="10" goto PF_10
if /i "!PERF_CHOICE!"=="11" goto PF_RESTORE
if /i "!PERF_CHOICE!"=="A" goto PF_10
if "!PERF_CHOICE!"=="0" goto :EOF
goto PERF_MENU

:PF_1
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0system_tools.ps1" -Action PowerHigh
if errorlevel 1 echo   [-] Action failed. Review the error above before retrying.
pause
goto PERF_MENU

:PF_2
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0system_tools.ps1" -Action PowerUltimate
if errorlevel 1 echo   [-] Action failed. Review the error above before retrying.
pause
goto PERF_MENU

:PF_3
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0system_tools.ps1" -Action PerformanceVisual
if errorlevel 1 echo   [-] Action failed. Review the error above before retrying.
pause
goto PERF_MENU

:PF_4
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0system_tools.ps1" -Action PerformanceStartup
if errorlevel 1 echo   [-] Action failed. Review the error above before retrying.
pause
goto PERF_MENU

:PF_5
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0system_tools.ps1" -Action Memory
if errorlevel 1 echo   [-] Action failed. Review the error above before retrying.
pause
goto PERF_MENU

:PF_6
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0system_tools.ps1" -Action PerformanceSearch
if errorlevel 1 echo   [-] Action failed. Review the error above before retrying.
pause
goto PERF_MENU

:PF_7
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0system_tools.ps1" -Action PerformanceSysMain
if errorlevel 1 echo   [-] Action failed. Review the error above before retrying.
pause
goto PERF_MENU

:PF_8
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0system_tools.ps1" -Action PerformanceXbox
if errorlevel 1 echo   [-] Action failed. Review the error above before retrying.
pause
goto PERF_MENU

:PF_9
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0system_tools.ps1" -Action PerformanceGame
if errorlevel 1 echo   [-] Action failed. Review the error above before retrying.
pause
goto PERF_MENU

:PF_10
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0system_tools.ps1" -Action PerformanceAll
if errorlevel 1 echo   [-] Action failed. Review the error above before retrying.
pause
goto PERF_MENU

:PF_A
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0system_tools.ps1" -Action PerformanceAll
if errorlevel 1 echo   [-] Action failed. Review the error above before retrying.
pause
goto PERF_MENU

:PF_RESTORE
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0system_tools.ps1" -Action PrivacyRestore
if errorlevel 1 echo   [-] Restore failed. Review the error above.
pause
goto PERF_MENU
