@echo off
setlocal EnableDelayedExpansion
:: ============================================================
::  KyuTools - Windows All in One Utilities Module
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
title  KyuTools - Windows All in One Utilities
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

if "%AIO_CHOICE%"=="1" goto LAUNCH_WINUTIL
if "%AIO_CHOICE%"=="0" goto :EOF
goto ALLINONE_MENU

:LAUNCH_WINUTIL
cls
echo.
echo   +------------------------------------------------------------------------------------------------+
echo   ^|   Chris Titus Tech Windows Utility (WinUtil)                                                   ^|
echo   +------------------------------------------------------------------------------------------------+
echo.
echo   This launches Chris Titus Tech's Windows Utility (CTT WinUtil) for tweaks,
echo   essential software installs, system configurations, and Windows update management.
echo.
echo   Command:
echo     irm https://christitus.com/win ^| iex
echo.
echo   [!] Requires an active Internet Connection and Administrator Rights.
echo.
set "CONFIRM="
set /p "CONFIRM=   >> Launch Windows All in One Utilities? (Y/N): "
if /i not "%CONFIRM%"=="Y" goto ALLINONE_MENU

echo.
echo   [*] Launching Windows All in One Utilities via PowerShell...
echo.
powershell -NoProfile -ExecutionPolicy Bypass -Command "irm https://christitus.com/win | iex"
echo.
echo   [+] Finished or closed Windows All in One Utilities.
echo.
pause
goto ALLINONE_MENU
