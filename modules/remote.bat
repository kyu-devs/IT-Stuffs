@echo off
setlocal EnableDelayedExpansion
:: ============================================================
::  ONYX IT DEPARTMENT TECH TOOLS - Remote Management Module
:: ============================================================

:REMOTE_MENU
cls
mode con: cols=100 lines=45
title  ONYX IT DEPARTMENT TECH TOOLS - Remote Management and Access
color 0A

echo.
echo   +------------------------------------------------------------------------------------------------+
echo   ^|                           Remote Management and Access                                        ^|
echo   +------------------------------------------------------------------------------------------------+
echo   ^|                                                                                                ^|
echo   ^|   [1]   Launch Remote Desktop Connection (RDP)                                                ^|
echo   ^|   [2]   Launch Windows Quick Assist (Help an end-user)                                        ^|
echo   ^|   [3]   Enable Remote Desktop on THIS PC                                                      ^|
echo   ^|   [4]   Ping / Check if a Remote PC is online                                                 ^|
echo   ^|   [5]   Browse Remote PC's hidden C$ Drive (Admin required)                                   ^|
echo   ^|   [6]   Open Remote Computer Management console                                               ^|
echo   ^|   [7]   Remote Restart / Shutdown Tool (GUI)                                                  ^|
echo   ^|   [8]   Scan Local Network for Active Devices (IP Scanner)                                    ^|
echo   ^|   [0]   Back to Main Menu                                                                     ^|
echo   ^|                                                                                                ^|
echo   +------------------------------------------------------------------------------------------------+
echo.
set "REM_CHOICE="
set /p "REM_CHOICE=    >> Select option: "

if "!REM_CHOICE!"=="1" goto R_1
if "!REM_CHOICE!"=="2" goto R_2
if "!REM_CHOICE!"=="3" goto R_3
if "!REM_CHOICE!"=="4" goto R_4
if "!REM_CHOICE!"=="5" goto R_5
if "!REM_CHOICE!"=="6" goto R_6
if "!REM_CHOICE!"=="7" goto R_7
if "!REM_CHOICE!"=="8" goto R_8
if "!REM_CHOICE!"=="0" goto :EOF
goto REMOTE_MENU

:R_1
echo.
echo   [*] Opening Remote Desktop Connection...
start mstsc.exe
goto REMOTE_MENU

:R_2
echo.
echo   [*] Opening Windows Quick Assist...
start quickassist.exe
goto REMOTE_MENU

:R_3
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0system_tools.ps1" -Action RemoteEnable
if errorlevel 1 echo   [-] Action failed. Review the error above before retrying.
pause
goto REMOTE_MENU

:R_4
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0system_tools.ps1" -Action RemotePing
if errorlevel 1 echo   [-] Action failed. Review the error above before retrying.
pause
goto REMOTE_MENU

:R_5
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0system_tools.ps1" -Action RemoteShare
if errorlevel 1 echo   [-] Action failed. Review the error above before retrying.
pause
goto REMOTE_MENU

:R_6
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0system_tools.ps1" -Action RemoteManage
if errorlevel 1 echo   [-] Action failed. Review the error above before retrying.
pause
goto REMOTE_MENU

:R_7
cls
echo.
echo   +------------------------------------------------------------------------------------------------+
echo   ^|   Remote Restart / Shutdown Tool                                                              ^|
echo   +------------------------------------------------------------------------------------------------+
echo.
echo   [*] Launching Remote Shutdown GUI...
start shutdown -i
goto REMOTE_MENU

:R_8
cls
echo.
echo   +------------------------------------------------------------------------------------------------+
echo   ^|   Network IP Scanner - Active Devices on Local Network                                        ^|
echo   +------------------------------------------------------------------------------------------------+
echo.
echo   [*] Detecting local subnet via ARP cache...
echo   [*] Resolving Computer Names and Logged-In Users per device...
echo   [*] This may take 1-3 minutes depending on network size.
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0network_scan.ps1"

echo.
:R_8_PING
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0system_tools.ps1" -Action RemotePing
if errorlevel 1 echo   [-] Action failed. Review the error above before retrying.
pause
goto REMOTE_MENU
