@echo off
setlocal EnableDelayedExpansion

:: ============================================================
::  KyuTools v1.1 - Windows Utility Toolkit
::  Main Launcher
:: ============================================================

:: == Admin check ============================================
net session >nul 2>&1
if %errorLevel% NEQ 0 (
    cls
    echo.
    echo   [!] Administrator rights required.
    echo   [*] Relaunching as Administrator...
    timeout /t 2 /nobreak >nul
    powershell -Command "Start-Process cmd -ArgumentList '/c \"%~f0\"' -Verb RunAs"
    exit /b
)

:: == Window setup ===========================================
mode con: cols=100 lines=45
title KyuTools v1.1 - Windows Utility Toolkit
color 0A

:: ============================================================
::  PASSWORD GATE
:: ============================================================
:CHECK_PASS
cls
echo.
echo.
echo.
echo.
echo.
echo                                   SYSTEM INITIALIZATION... OK
echo                                   LOADING SECURITY PROTOCOL... OK
echo.
echo                   +---------------------------------------------------------+
echo                   ^|                                                         ^|
echo                   ^|                 K Y U T O O L S   v 1 . 1               ^|
echo                   ^|                 -------------------------               ^|
echo                   ^|                 AUTHORIZED PERSONNEL ONLY               ^|
echo                   ^|                                                         ^|
echo                   +---------------------------------------------------------+
echo.
echo.

:: Call external PS1 = no escaping issues with special characters
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0modules\pass.ps1"

if %errorlevel% NEQ 0 (
    echo.
    echo   [!] Wrong password. Access denied.
    echo.
    timeout /t 2 /nobreak >nul
    goto CHECK_PASS
)

:: ============================================================
::  MAIN MENU
:: ============================================================
:MAIN_MENU
cls
color 0A
echo.
echo   +-------------------------------------------------------------------------------------------------+
echo   ^|                                                                                                 ^|
echo   ^|                           K Y U T O O L S   v 1 . 1                                           ^|
echo   ^|                        Windows Utility Toolkit by Kyu                                          ^|
echo   ^|                                                                                                 ^|
echo   +------------------------------------------------+------------------------------------------------+
echo   ^|                                                ^|                                                ^|
echo   ^|   [1]   Windows Activation and License         ^|   HWID/KMS activation, key entry, errors      ^|
echo   ^|   [2]   Network and Internet Optimizer         ^|   DNS flush, reset, IP renew, DNS changer      ^|
echo   ^|   [3]   System Maintenance and Diagnostics    ^|   SFC, DISM, cleanup, disk health, CHKDSK      ^|
echo   ^|   [4]   System Information                    ^|   CPU, RAM, GPU, disk info, export report      ^|
echo   ^|   [5]   Privacy and Telemetry Control         ^|   Disable tracking, Cortana, ad ID             ^|
echo   ^|   [6]   Performance Tweaks                    ^|   Power plan, visual effects, game mode        ^|
echo   ^|   [7]   File and Disk Utilities               ^|   Large files, ownership, hash checker         ^|
echo   ^|   [8]   Printer and Device Sharing            ^|   Network printer, File sharing, Spooler       ^|
echo   ^|   [9]   IT Helpdesk ^& Quick Fixes             ^|   BIOS boot, Explorer fix, Safe Mode, etc      ^|
echo   ^|   [10]  Remote Management ^& Access            ^|   RDP, Quick Assist, Remote C$, Ping          ^|
echo   ^|   [11]  Security and Intrusion Audit          ^|   Network connections, logon history, threats  ^|
echo   ^|   [12]  Windows All in One Utilities          ^|   Chris Titus Tech WinUtil (Install/Tweaks)    ^|
echo   ^|   [13]  About KyuTools                        ^|                                                ^|
echo   ^|   [0]   Exit                                  ^|                                                ^|
echo   ^|                                                ^|                                                ^|
echo   +------------------------------------------------+------------------------------------------------+
echo.
set CHOICE=
set /p CHOICE=    Select option: 

if "%CHOICE%"=="1" goto LOAD_1
if "%CHOICE%"=="2" goto LOAD_2
if "%CHOICE%"=="3" goto LOAD_3
if "%CHOICE%"=="4" goto LOAD_4
if "%CHOICE%"=="5" goto LOAD_5
if "%CHOICE%"=="6" goto LOAD_6
if "%CHOICE%"=="7" goto LOAD_7
if "%CHOICE%"=="8" goto LOAD_8
if "%CHOICE%"=="9" goto LOAD_9
if "%CHOICE%"=="10" goto LOAD_10
if "%CHOICE%"=="11" goto LOAD_11
if "%CHOICE%"=="12" goto LOAD_12
if "%CHOICE%"=="13" goto ABOUT
if "%CHOICE%"=="0" goto BYE
goto MAIN_MENU

:LOAD_1
call "%~dp0modules\activation.bat"
color 0A
goto MAIN_MENU

:LOAD_2
call "%~dp0modules\network.bat"
color 0A
goto MAIN_MENU

:LOAD_3
call "%~dp0modules\maintenance.bat"
color 0A
goto MAIN_MENU

:LOAD_4
call "%~dp0modules\sysinfo.bat"
color 0A
goto MAIN_MENU

:LOAD_5
call "%~dp0modules\privacy.bat"
color 0A
goto MAIN_MENU

:LOAD_6
call "%~dp0modules\performance.bat"
color 0A
goto MAIN_MENU

:LOAD_7
call "%~dp0modules\diskutils.bat"
color 0A
goto MAIN_MENU

:LOAD_8
call "%~dp0modules\printer.bat"
color 0A
goto MAIN_MENU

:LOAD_9
call "%~dp0modules\ithelpdesk.bat"
color 0A
goto MAIN_MENU

:LOAD_10
call "%~dp0modules\remote.bat"
color 0A
goto MAIN_MENU

:LOAD_11
call "%~dp0modules\security.bat"
color 0A
goto MAIN_MENU

:LOAD_12
call "%~dp0modules\allinone.bat"
color 0A
goto MAIN_MENU

:ABOUT
cls
color 0A
echo.
echo   +-------------------------------------------------------------------------------------------------+
echo   ^|                               About KyuTools                                                   ^|
echo   +-------------------------------------------------------------------------------------------------+
echo   ^|                                                                                                 ^|
echo   ^|   KyuTools v1.1  -  Windows Utility Toolkit                                                   ^|
echo   ^|   A portable, password-protected, menu-driven CMD suite.                                       ^|
echo   ^|   Created by Kyu  ^|  Contributor: themarneilx                                                 ^|
echo   ^|                                                                                                 ^|
echo   ^|   Modules:                                                                                     ^|
echo   ^|     [1]  Windows Activation and License                                                       ^|
echo   ^|     [2]  Network and Internet Optimizer                                                        ^|
echo   ^|     [3]  System Maintenance and Diagnostics                                                   ^|
echo   ^|     [4]  System Information Viewer                                                            ^|
echo   ^|     [5]  Privacy and Telemetry Control                                                        ^|
echo   ^|     [6]  Performance Tweaks                                                                   ^|
echo   ^|     [7]  File and Disk Utilities                                                              ^|
echo   ^|     [8]  Printer and Device Sharing                                                           ^|
echo   ^|     [9]  IT Helpdesk ^& Quick Fixes                                                           ^|
echo   ^|     [10] Remote Management ^& Access                                                         ^|
echo   ^|     [11] Security and Intrusion Audit                                                         ^|
echo   ^|     [12] Windows All in One Utilities                                                         ^|
echo   ^|                                                                                                 ^|
echo   +-------------------------------------------------------------------------------------------------+
echo.
pause
goto MAIN_MENU

:BYE
cls
color 0A
echo.
echo   +-------------------------------------------------------------------------------------------------+
echo   ^|                    Thank you for using KyuTools.  Goodbye!                                    ^|
echo   +-------------------------------------------------------------------------------------------------+
echo.
timeout /t 2 /nobreak >nul
exit
