@echo off

setlocal EnableDelayedExpansion
:: ============================================================
::  KyuTools - Privacy & Telemetry Control Module
:: ============================================================

:PRIVACY_MENU
cls
mode con: cols=100 lines=45
title  KyuTools - Privacy and Telemetry Control
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
echo   ^|   [7]   Block Telemetry via Hosts File                                                        ^|
echo   ^|   [8]   Apply ALL Privacy Settings  (Recommended)                                            ^|
echo   ^|   [9]   Restore Default Privacy Settings                                                      ^|
echo   ^|   [0]   Back to Main Menu                                                                     ^|
echo   ^|                                                                                                ^|
echo   +------------------------------------------------------------------------------------------------+
echo.
set "PRIV_CHOICE="
set /p "PRIV_CHOICE=    >> Select option: "

if "%PRIV_CHOICE%"=="1" goto P_1
if "%PRIV_CHOICE%"=="2" goto P_2
if "%PRIV_CHOICE%"=="3" goto P_3
if "%PRIV_CHOICE%"=="4" goto P_4
if "%PRIV_CHOICE%"=="5" goto P_5
if "%PRIV_CHOICE%"=="6" goto P_6
if "%PRIV_CHOICE%"=="7" goto P_7
if "%PRIV_CHOICE%"=="8" goto P_8
if "%PRIV_CHOICE%"=="9" goto P_9
if "%PRIV_CHOICE%"=="0" goto :EOF
goto PRIVACY_MENU

:P_1
cls
echo.
echo   +------------------------------------------------------------------------------------------------+
echo   ^|   Disable Windows Telemetry                                                                   ^|
echo   +------------------------------------------------------------------------------------------------+
echo.
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v AllowTelemetry /t REG_DWORD /d 0 /f >nul
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" /v AllowTelemetry /t REG_DWORD /d 0 /f >nul
sc config DiagTrack start= disabled >nul
sc stop DiagTrack >nul 2>&1
sc config dmwappushservice start= disabled >nul
sc stop dmwappushservice >nul 2>&1
echo   [+] Telemetry services disabled.
echo.
pause
goto PRIVACY_MENU

:P_2
cls
echo.
echo   +------------------------------------------------------------------------------------------------+
echo   ^|   Disable Cortana                                                                             ^|
echo   +------------------------------------------------------------------------------------------------+
echo.
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v AllowCortana /t REG_DWORD /d 0 /f >nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v DisableWebSearch /t REG_DWORD /d 1 /f >nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v ConnectedSearchUseWeb /t REG_DWORD /d 0 /f >nul
echo   [+] Cortana disabled.
echo.
pause
goto PRIVACY_MENU

:P_3
cls
echo.
echo   +------------------------------------------------------------------------------------------------+
echo   ^|   Disable Activity History                                                                    ^|
echo   +------------------------------------------------------------------------------------------------+
echo.
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v EnableActivityFeed /t REG_DWORD /d 0 /f >nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v PublishUserActivities /t REG_DWORD /d 0 /f >nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v UploadUserActivities /t REG_DWORD /d 0 /f >nul
echo   [+] Activity History disabled.
echo.
pause
goto PRIVACY_MENU

:P_4
cls
echo.
echo   +------------------------------------------------------------------------------------------------+
echo   ^|   Disable Advertising ID                                                                      ^|
echo   +------------------------------------------------------------------------------------------------+
echo.
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo" /v Enabled /t REG_DWORD /d 0 /f >nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo" /v DisabledByGroupPolicy /t REG_DWORD /d 1 /f >nul
echo   [+] Advertising ID disabled.
echo.
pause
goto PRIVACY_MENU

:P_5
cls
echo.
echo   +------------------------------------------------------------------------------------------------+
echo   ^|   Disable Location Tracking                                                                   ^|
echo   +------------------------------------------------------------------------------------------------+
echo.
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors" /v DisableLocation /t REG_DWORD /d 1 /f >nul
echo   [+] Location tracking disabled.
echo.
pause
goto PRIVACY_MENU

:P_6
cls
echo.
echo   +------------------------------------------------------------------------------------------------+
echo   ^|   Disable App Diagnostics Sharing                                                             ^|
echo   +------------------------------------------------------------------------------------------------+
echo.
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Privacy" /v TailoredExperiencesWithDiagnosticDataEnabled /t REG_DWORD /d 0 /f >nul
echo   [+] Diagnostic data sharing disabled.
echo.
pause
goto PRIVACY_MENU

:P_7
cls
echo.
echo   +------------------------------------------------------------------------------------------------+
echo   ^|   Block Telemetry via Hosts File                                                              ^|
echo   +------------------------------------------------------------------------------------------------+
echo.
echo   [!] Adding Microsoft telemetry domains to hosts file.
set "HOSTS=%windir%\System32\drivers\etc\hosts"
echo. >> "%HOSTS%"
echo # KyuTools - Telemetry Block >> "%HOSTS%"
(
  echo 0.0.0.0 vortex.data.microsoft.com
  echo 0.0.0.0 vortex-win.data.microsoft.com
  echo 0.0.0.0 telecommand.telemetry.microsoft.com
  echo 0.0.0.0 oca.telemetry.microsoft.com
  echo 0.0.0.0 sqm.telemetry.microsoft.com
  echo 0.0.0.0 watson.telemetry.microsoft.com
  echo 0.0.0.0 redir.metaservices.microsoft.com
  echo 0.0.0.0 df.telemetry.microsoft.com
  echo 0.0.0.0 telemetry.microsoft.com
  echo 0.0.0.0 settings-win.data.microsoft.com
) >> "%HOSTS%"
ipconfig /flushdns >nul
echo   [+] Telemetry domains blocked.
echo.
pause
goto PRIVACY_MENU

:P_8
cls
echo.
echo   +------------------------------------------------------------------------------------------------+
echo   ^|   Applying All Privacy Settings                                                               ^|
echo   +------------------------------------------------------------------------------------------------+
echo.
echo   [1/6] Disabling telemetry...
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v AllowTelemetry /t REG_DWORD /d 0 /f >nul
sc config DiagTrack start= disabled >nul & sc stop DiagTrack >nul 2>&1
echo          Done.
echo   [2/6] Disabling Cortana...
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v AllowCortana /t REG_DWORD /d 0 /f >nul
echo          Done.
echo   [3/6] Disabling Activity History...
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v EnableActivityFeed /t REG_DWORD /d 0 /f >nul
echo          Done.
echo   [4/6] Disabling Advertising ID...
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo" /v Enabled /t REG_DWORD /d 0 /f >nul
echo          Done.
echo   [5/6] Disabling Location Tracking...
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors" /v DisableLocation /t REG_DWORD /d 1 /f >nul
echo          Done.
echo   [6/6] Disabling Diagnostic sharing...
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Privacy" /v TailoredExperiencesWithDiagnosticDataEnabled /t REG_DWORD /d 0 /f >nul
echo          Done.
echo.
echo   [+] All privacy settings applied!
echo.
pause
goto PRIVACY_MENU

:P_9
cls
echo.
echo   +------------------------------------------------------------------------------------------------+
echo   ^|   Restore Default Privacy Settings                                                            ^|
echo   +------------------------------------------------------------------------------------------------+
echo.
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v AllowTelemetry /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v AllowCortana /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v EnableActivityFeed /f >nul 2>&1
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo" /v Enabled /t REG_DWORD /d 1 /f >nul
sc config DiagTrack start= auto >nul & net start DiagTrack >nul 2>&1
echo   [+] Default settings restored.
echo.
pause
goto PRIVACY_MENU
