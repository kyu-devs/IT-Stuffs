@echo off

setlocal EnableDelayedExpansion
:: ============================================================
::  ONYX IT DEPARTMENT TECH TOOLS - Privacy & Telemetry Control Module
:: ============================================================

:PRIVACY_MENU
cls
mode con: cols=100 lines=45
title  ONYX IT DEPARTMENT TECH TOOLS - Privacy and Telemetry Control
color 0A

echo.
echo   +------------------------------------------------------------------------------------------------+
echo   ^|                        Privacy and Telemetry Control                                          ^|
echo   +------------------------------------------------------------------------------------------------+
echo   ^|                                                                                                ^|
echo   ^|   [1]   Disable Windows Telemetry                                                             ^|
echo   ^|   [2]   Disable Cortana                                                                       ^|
echo   ^|   [3]   Disable Activity History                                                              ^|
echo   ^|   [4]   Disable Advertising ID                                                                ^|
echo   ^|   [5]   Disable Location Tracking                                                             ^|
echo   ^|   [6]   Disable App Diagnostics Sharing                                                       ^|
echo   ^|   [7]   Hosts File Privacy Guidance                                                           ^|
echo   ^|   [8]   Apply ALL Privacy Settings  (Recommended)                                            ^|
echo   ^|   [9]   Restore a Saved Registry Settings Backup                                              ^|
echo   ^|   [0]   Back to Main Menu                                                                     ^|
echo   ^|                                                                                                ^|
echo   +------------------------------------------------------------------------------------------------+
echo.
set "PRIV_CHOICE="
set /p "PRIV_CHOICE=    >> Select option: "

if "!PRIV_CHOICE!"=="1" goto P_1
if "!PRIV_CHOICE!"=="2" goto P_2
if "!PRIV_CHOICE!"=="3" goto P_3
if "!PRIV_CHOICE!"=="4" goto P_4
if "!PRIV_CHOICE!"=="5" goto P_5
if "!PRIV_CHOICE!"=="6" goto P_6
if "!PRIV_CHOICE!"=="7" goto P_7
if "!PRIV_CHOICE!"=="8" goto P_8
if "!PRIV_CHOICE!"=="9" goto P_9
if "!PRIV_CHOICE!"=="0" goto :EOF
goto PRIVACY_MENU

:P_1
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0system_tools.ps1" -Action Privacy1
if errorlevel 1 echo   [-] Action failed. Review the error above before retrying.
pause
goto PRIVACY_MENU

:P_2
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0system_tools.ps1" -Action Privacy2
if errorlevel 1 echo   [-] Action failed. Review the error above before retrying.
pause
goto PRIVACY_MENU

:P_3
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0system_tools.ps1" -Action Privacy3
if errorlevel 1 echo   [-] Action failed. Review the error above before retrying.
pause
goto PRIVACY_MENU

:P_4
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0system_tools.ps1" -Action Privacy4
if errorlevel 1 echo   [-] Action failed. Review the error above before retrying.
pause
goto PRIVACY_MENU

:P_5
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0system_tools.ps1" -Action Privacy5
if errorlevel 1 echo   [-] Action failed. Review the error above before retrying.
pause
goto PRIVACY_MENU

:P_6
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0system_tools.ps1" -Action Privacy6
if errorlevel 1 echo   [-] Action failed. Review the error above before retrying.
pause
goto PRIVACY_MENU

:P_7
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0system_tools.ps1" -Action PrivacyHosts
if errorlevel 1 echo   [-] Action failed. Review the error above before retrying.
pause
goto PRIVACY_MENU

:P_8
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0system_tools.ps1" -Action Privacy8
if errorlevel 1 echo   [-] Action failed. Review the error above before retrying.
pause
goto PRIVACY_MENU

:P_9
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0system_tools.ps1" -Action PrivacyRestore
if errorlevel 1 echo   [-] Action failed. Review the error above before retrying.
pause
goto PRIVACY_MENU
