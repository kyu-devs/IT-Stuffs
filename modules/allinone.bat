@echo off
setlocal EnableDelayedExpansion
:: ============================================================
::  ONYX IT DEPARTMENT TECH TOOLS - Windows All in One Utilities Module
:: ============================================================

:: == Admin check (if executed directly) =======================
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

:ALLINONE_MENU
cls
mode con: cols=100 lines=45
title  ONYX IT DEPARTMENT TECH TOOLS - Windows All in One Utilities
color 0A

echo.
echo   +------------------------------------------------------------------------------------------------+
echo   ^|                           Windows All in One Utilities                                         ^|
echo   +------------------------------------------------------------------------------------------------+
echo   ^|                                                                                                ^|
echo   ^|   [1]   Launch Chris Titus Tech Windows Utility (WinUtil)                                      ^|
echo   ^|   [0]   Back to Main Menu                                                                      ^|
echo   ^|                                                                                                ^|
echo   +------------------------------------------------------------------------------------------------+
echo.
set "AIO_CHOICE="
set /p "AIO_CHOICE=    >> Select option: "

if "!AIO_CHOICE!"=="1" goto LAUNCH_WINUTIL
if "!AIO_CHOICE!"=="0" goto :EOF
goto ALLINONE_MENU

:LAUNCH_WINUTIL
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0system_tools.ps1" -Action WinUtil
if errorlevel 1 echo   [-] Action failed. Review the error above before retrying.
pause
goto ALLINONE_MENU
