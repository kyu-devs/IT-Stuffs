@echo off
setlocal EnableDelayedExpansion
:: ============================================================
::  ONYX IT DEPARTMENT TECH TOOLS - Windows Activation & License Module
:: ============================================================

:ACTIVATION_MENU
cls
mode con: cols=100 lines=45
title  ONYX IT DEPARTMENT TECH TOOLS - Activation and License
color 0A

echo.
echo   +------------------------------------------------------------------------------------------------+
echo   ^|                       Windows Activation and License Tools                                    ^|
echo   +------------------------------------------------------------------------------------------------+
echo   ^|                                                                                                ^|
echo   ^|   [1]   Install Office (Word, Excel, PowerPoint, Outlook Only)                                 ^|
echo   ^|   [2]   Scrub Microsoft Office (Remove M365 / Clean Licenses)                                  ^|
echo   ^|   [3]   Check Activation Status                                                               ^|
echo   ^|   [4]   Check Windows License Type                                                            ^|
echo   ^|   [5]   Office License and Activation Help                                                   ^|
echo   ^|   [6]   Activate with Product Key (slmgr /ipk)                                                ^|
echo   ^|   [7]   Rearm Evaluation License (extend trial)                                               ^|
echo   ^|   [8]   View Full License Details (slmgr /dlv)                                                ^|
echo   ^|   [0]   Back to Main Menu                                                                     ^|
echo   ^|                                                                                                ^|
echo   +------------------------------------------------------------------------------------------------+
echo.
set "ACT_CHOICE="
set /p "ACT_CHOICE=    >> Select option: "
if defined ACT_CHOICE set "ACT_CHOICE=!ACT_CHOICE: =!"

if "!ACT_CHOICE!"=="1" goto ACT_INSTALL_OFFICE
if "!ACT_CHOICE!"=="2" goto ACT_SCRUB_OFFICE
if "!ACT_CHOICE!"=="3" goto ACT_1
if "!ACT_CHOICE!"=="4" goto ACT_2
if "!ACT_CHOICE!"=="5" goto ACT_4
if "!ACT_CHOICE!"=="6" goto ACT_3
if "!ACT_CHOICE!"=="7" goto ACT_5
if "!ACT_CHOICE!"=="8" goto ACT_8
if "!ACT_CHOICE!"=="0" goto :EOF
goto ACTIVATION_MENU

:: == [1] Install Office (Word, Excel, PowerPoint, Outlook Only) =
:ACT_INSTALL_OFFICE
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0system_tools.ps1" -Action OfficeInstall
if errorlevel 1 echo   [-] Action failed. Review the error above before retrying.
pause
goto ACTIVATION_MENU

:ACT_SCRUB_OFFICE
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0system_tools.ps1" -Action OfficeRemove
if errorlevel 1 echo   [-] Action failed. Review the error above before retrying.
pause
goto ACTIVATION_MENU

:ACT_1
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0system_tools.ps1" -Action WindowsStatus
if errorlevel 1 echo   [-] Action failed. Review the error above before retrying.
pause
goto ACTIVATION_MENU

:ACT_2
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0system_tools.ps1" -Action WindowsStatus
if errorlevel 1 echo   [-] Action failed. Review the error above before retrying.
pause
goto ACTIVATION_MENU

:ACT_3
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0system_tools.ps1" -Action WindowsActivate
if errorlevel 1 echo   [-] Action failed. Review the error above before retrying.
pause
goto ACTIVATION_MENU

:ACT_4
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0system_tools.ps1" -Action OfficeLicense
if errorlevel 1 echo   [-] Action failed. Review the error above before retrying.
pause
goto ACTIVATION_MENU

:ACT_5
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0system_tools.ps1" -Action WindowsRearm
if errorlevel 1 echo   [-] Action failed. Review the error above before retrying.
pause
goto ACTIVATION_MENU

:ACT_HWID_MAS
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0system_tools.ps1" -Action WindowsHelp
if errorlevel 1 echo   [-] Action failed. Review the error above before retrying.
pause
goto ACTIVATION_MENU

:ACT_HANDLE_ERROR
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0system_tools.ps1" -Action WindowsHelp
if errorlevel 1 echo   [-] Action failed. Review the error above before retrying.
pause
goto ACTIVATION_MENU

:ACT_8
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0system_tools.ps1" -Action WindowsFull
if errorlevel 1 echo   [-] Action failed. Review the error above before retrying.
pause
goto ACTIVATION_MENU
