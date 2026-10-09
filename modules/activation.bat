@echo off
setlocal EnableDelayedExpansion
:: ============================================================
::  KyuTools - Windows Activation & License Module
:: ============================================================

:ACTIVATION_MENU
cls
mode con: cols=100 lines=45
title  KyuTools - Activation and License
color 0A

echo.
echo   +------------------------------------------------------------------------------------------------+
echo   ^|                       Windows Activation and License Tools                                    ^|
echo   +------------------------------------------------------------------------------------------------+
echo   ^|                                                                                                ^|
echo   ^|   [1]   Check Activation Status                                                               ^|
echo   ^|   [2]   Check Windows License Type                                                            ^|
echo   ^|   [3]   Activate Office with Ohook (Permanent - MAS)                                         ^|
echo   ^|   [4]   Rearm Evaluation License (extend trial)                                              ^|
echo   ^|   [5]   Fix Activation Error 0xC004F074                                                      ^|
echo   ^|   [6]   Fix Activation Error 0x8007007B                                                      ^|
echo   ^|   [7]   View Full License Details (slmgr /dlv)                                               ^|
echo   ^|   [0]   Back to Main Menu                                                                     ^|
echo   ^|                                                                                                ^|
echo   +------------------------------------------------------------------------------------------------+
echo.
set "ACT_CHOICE="
set /p "ACT_CHOICE=    >> Select option: "

if "%ACT_CHOICE%"=="1" goto ACT_1
if "%ACT_CHOICE%"=="2" goto ACT_2
if "%ACT_CHOICE%"=="3" goto ACT_4
if "%ACT_CHOICE%"=="4" goto ACT_5
if "%ACT_CHOICE%"=="5" goto ACT_6
if "%ACT_CHOICE%"=="6" goto ACT_7
if "%ACT_CHOICE%"=="7" goto ACT_8
if "%ACT_CHOICE%"=="0" goto :EOF
goto ACTIVATION_MENU

:: == [1] Check Activation Status ==========================
:ACT_1
cls
echo.
echo   +------------------------------------------------------------------------------------------------+
echo   ^|   Activation Status                                                                           ^|
echo   +------------------------------------------------------------------------------------------------+
echo.
echo   [ Expiry / Grace Period ]
cscript //nologo "%windir%\System32\slmgr.vbs" /xpr
echo.
echo   [ License Summary ]
cscript //nologo "%windir%\System32\slmgr.vbs" /dli
echo.
pause
goto ACTIVATION_MENU

:: == [2] License Type =====================================
:ACT_2
cls
echo.
echo   +------------------------------------------------------------------------------------------------+
echo   ^|   Windows Edition and License                                                                 ^|
echo   +------------------------------------------------------------------------------------------------+
echo.
for /f "tokens=* delims=" %%A in ('powershell -NoProfile -Command "(Get-CimInstance Win32_OperatingSystem).Caption"') do echo   Edition : %%A
for /f "tokens=* delims=" %%A in ('powershell -NoProfile -Command "(Get-CimInstance Win32_OperatingSystem).BuildNumber"') do echo   Build   : %%A
for /f "tokens=* delims=" %%A in ('powershell -NoProfile -Command "(Get-CimInstance Win32_OperatingSystem).SerialNumber"') do echo   Serial  : %%A
echo.
echo   [ License Channel ]
cscript //nologo "%windir%\System32\slmgr.vbs" /dli | findstr /i "license\|channel\|partial"
echo.
pause
goto ACTIVATION_MENU

:: == [3] Activate with Product Key ========================
:ACT_3
cls
echo.
echo   +------------------------------------------------------------------------------------------------+
echo   ^|   Activate with Product Key                                                                   ^|
echo   +------------------------------------------------------------------------------------------------+
echo.
set "PKEY="
set /p "PKEY=   >> Enter Key (XXXXX-XXXXX-XXXXX-XXXXX-XXXXX): "
if "%PKEY%"=="" (
    echo   [!] No key entered. Cancelled.
    pause
    goto ACTIVATION_MENU
)
echo.
echo   [*] Installing product key...
cscript //nologo "%windir%\System32\slmgr.vbs" /ipk %PKEY%
echo.
echo   [*] Attempting online activation...
cscript //nologo "%windir%\System32\slmgr.vbs" /ato
echo.
pause
goto ACTIVATION_MENU

:: == [4] Office Ohook Activation ===========================
:ACT_4
cls
echo.
echo   +------------------------------------------------------------------------------------------------+
echo   ^|   Activate Office with Ohook (MAS Method)                                                     ^|
echo   +------------------------------------------------------------------------------------------------+
echo.
echo   This uses Microsoft Activation Scripts (MAS) to permanently 
echo   activate Microsoft Office (Word, Excel, PowerPoint) using Ohook.
echo.
echo   [!] Requires Internet Connection.
echo.
set "CONFIRM="
set /p "CONFIRM=   >> Proceed? (Y/N): "
if /i not "%CONFIRM%"=="Y" goto ACTIVATION_MENU

echo.
echo   [*] Launching Ohook Activation Menu via PowerShell...
echo   [*] Please select option [2] "Ohook" in the blue window that appears.
echo.
powershell -ExecutionPolicy Bypass -Command "irm https://get.activated.win | iex"
echo.
echo   [+] Finished. Office should now be permanently activated!
echo.
pause
goto ACTIVATION_MENU

:: == [5] Rearm Evaluation =================================
:ACT_5
cls
echo.
echo   +------------------------------------------------------------------------------------------------+
echo   ^|   Rearm Evaluation License                                                                    ^|
echo   +------------------------------------------------------------------------------------------------+
echo.
echo   Resets the 30-day evaluation timer (max 3 times).
echo.
cscript //nologo "%windir%\System32\slmgr.vbs" /rearm
if %errorlevel%==0 (
    echo.
    echo   [+] Rearm successful! Please restart your computer.
) else (
    echo.
    echo   [!] Rearm failed. You may have used all rearm attempts.
)
echo.
pause
goto ACTIVATION_MENU

:: == [6] Fix Error 0xC004F074 =============================
:ACT_6
cls
echo.
echo   +------------------------------------------------------------------------------------------------+
echo   ^|   Fix: Error 0xC004F074  (KMS unavailable)                                                   ^|
echo   +------------------------------------------------------------------------------------------------+
echo.
echo   [*] Restarting Software Protection service...
net stop sppsvc /y >nul 2>&1
net start sppsvc >nul 2>&1
echo   [+] sppsvc restarted.
echo.
echo   [*] Clearing KMS cache...
cscript //nologo "%windir%\System32\slmgr.vbs" /ckms
echo.
echo   [*] Retrying activation...
cscript //nologo "%windir%\System32\slmgr.vbs" /ato
echo.
pause
goto ACTIVATION_MENU

:: == [7] Fix Error 0x8007007B =============================
:ACT_7
cls
echo.
echo   +------------------------------------------------------------------------------------------------+
echo   ^|   Fix: Error 0x8007007B  (invalid key format)                                                ^|
echo   +------------------------------------------------------------------------------------------------+
echo.
echo   [*] Uninstalling current product key...
cscript //nologo "%windir%\System32\slmgr.vbs" /upk
echo.
echo   [*] Clearing key from registry...
cscript //nologo "%windir%\System32\slmgr.vbs" /cpky
echo.
echo   [*] Restarting licensing service...
net stop sppsvc /y >nul 2>&1
net start sppsvc >nul 2>&1
echo.
echo   [+] Done. Re-enter your product key using Option [3].
echo.
pause
goto ACTIVATION_MENU

:: == [8] View License Details =============================
:ACT_8
cls
echo.
echo   +------------------------------------------------------------------------------------------------+
echo   ^|   Full License Details  (slmgr /dlv)                                                         ^|
echo   +------------------------------------------------------------------------------------------------+
echo.
cscript //nologo "%windir%\System32\slmgr.vbs" /dlv
echo.
pause
goto ACTIVATION_MENU
