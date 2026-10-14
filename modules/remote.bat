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

if "%REM_CHOICE%"=="1" goto R_1
if "%REM_CHOICE%"=="2" goto R_2
if "%REM_CHOICE%"=="3" goto R_3
if "%REM_CHOICE%"=="4" goto R_4
if "%REM_CHOICE%"=="5" goto R_5
if "%REM_CHOICE%"=="6" goto R_6
if "%REM_CHOICE%"=="7" goto R_7
if "%REM_CHOICE%"=="8" goto R_8
if "%REM_CHOICE%"=="0" goto :EOF
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
cls
echo.
echo   +------------------------------------------------------------------------------------------------+
echo   ^|   Enable Remote Desktop on THIS PC                                                            ^|
echo   +------------------------------------------------------------------------------------------------+
echo.
echo   [*] Enabling RDP in Registry...
reg add "HKLM\System\CurrentControlSet\Control\Terminal Server" /v fDenyTSConnections /t REG_DWORD /d 0 /f >nul
echo   [*] Allowing RDP through Windows Firewall...
netsh advfirewall firewall set rule group="remote desktop" new enable=Yes >nul 2>&1
echo.
echo   [+] Remote Desktop is now ENABLED.
echo.
pause
goto REMOTE_MENU

:R_4
cls
echo.
echo   +------------------------------------------------------------------------------------------------+
echo   ^|   Ping Remote PC                                                                              ^|
echo   +------------------------------------------------------------------------------------------------+
echo.
set "TARGET="
set /p "TARGET=   >> Enter IP Address or PC Name: "
if "%TARGET%"=="" goto REMOTE_MENU
echo.
ping %TARGET%
echo.
pause
goto REMOTE_MENU

:R_5
cls
echo.
echo   +------------------------------------------------------------------------------------------------+
echo   ^|   Browse Remote C$ Drive                                                                      ^|
echo   +------------------------------------------------------------------------------------------------+
echo.
set "TARGET="
set /p "TARGET=   >> Enter IP Address or PC Name: "
if "%TARGET%"=="" goto REMOTE_MENU
echo.
echo   [*] Attempting to open \\%TARGET%\c$ ...
start \\%TARGET%\c$
goto REMOTE_MENU

:R_6
cls
echo.
echo   +------------------------------------------------------------------------------------------------+
echo   ^|   Remote Computer Management                                                                  ^|
echo   +------------------------------------------------------------------------------------------------+
echo.
set "TARGET="
set /p "TARGET=   >> Enter IP Address or PC Name: "
if "%TARGET%"=="" goto REMOTE_MENU
echo.
echo   [*] Launching compmgmt.msc for %TARGET%...
start compmgmt.msc /computer:\\%TARGET%
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
echo   ^|   Network IP Scanner (Active Devices)                                                         ^|
echo   +------------------------------------------------------------------------------------------------+
echo.
echo   [*] Scanning Local Network via ARP...
echo   [*] Resolving Hostnames and Logged-In Users (This may take a few minutes)...
echo.
powershell -NoProfile -Command "arp -a | Select-String 'dynamic' | ForEach-Object { $ip = $_.ToString().Trim() -replace '\s+.*',''; $hostName = ''; try { $hostName = [System.Net.Dns]::GetHostEntry($ip).HostName.Split('.')[0] } catch { }; if (-not $hostName) { $hostName = 'Unknown Device' }; $user = (quser /server:$ip 2>$null | Select-Object -Skip 1 | ForEach-Object { if ($_.Length -ge 22) { $u = $_.Substring(0, 22).Trim() -replace '^>', '' } else { $u = $_.Trim() -replace '^>', '' }; $fn = ''; try { $adsi = [adsi]\"WinNT://$ip/$u,user\"; if ($adsi.FullName) { $fn = $adsi.FullName.ToString() } } catch {}; if ($fn) { \"$fn ($u)\" } else { $u } }) -join ', '; if (-not $user) { $user = 'N/A' }; Write-Host \"   [+] $ip  -  $hostName  -  User: $user\" }"
echo.
echo   [*] Scan Complete.
echo.
:R_8_PING
set "PING_TARGET="
set /p "PING_TARGET=   >> Enter an IP Address from above to ping (or press Enter to exit): "
if "%PING_TARGET%"=="" goto REMOTE_MENU
echo.
ping %PING_TARGET%
echo.
goto R_8_PING
