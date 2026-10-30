@echo off

setlocal EnableDelayedExpansion
:: ============================================================
::  ONYX IT DEPARTMENT TECH TOOLS - Network & Internet Optimizer Module
:: ============================================================

:NETWORK_MENU
cls
mode con: cols=100 lines=45
title  ONYX IT DEPARTMENT TECH TOOLS - Network and Internet Optimizer
color 0A

echo.
echo   +------------------------------------------------------------------------------------------------+
echo   ^|                        Network and Internet Optimizer                                         ^|
echo   +------------------------------------------------------------------------------------------------+
echo   ^|                                                                                                ^|
echo   ^|   [1]   Full Network Reset  (All-in-One Fix)                                                 ^|
echo   ^|   [2]   Flush DNS Cache                                                                       ^|
echo   ^|   [3]   Reset Winsock                                                                         ^|
echo   ^|   [4]   Reset TCP/IP Stack                                                                    ^|
echo   ^|   [5]   Release and Renew IP  (DHCP)                                                         ^|
echo   ^|   [6]   Ping / Latency Test                                                                   ^|
echo   ^|   [7]   DNS Speed Benchmark                                                                   ^|
echo   ^|   [8]   Change DNS Server                                                                     ^|
echo   ^|   [9]   Show Network Adapters and IP Info                                                     ^|
echo   ^|   [10]  Disable IPv6                                                                          ^|
echo   ^|   [11]  Enable IPv6                                                                           ^|
echo   ^|   [12]  View Active Connections  (netstat)                                                    ^|
echo   ^|   [13]  Internet Speed Test  (opens browser)                                                  ^|
echo   ^|   [0]   Back to Main Menu                                                                     ^|
echo   ^|                                                                                                ^|
echo   +------------------------------------------------------------------------------------------------+
echo.
set "NET_CHOICE="
set /p "NET_CHOICE=    >> Select option: "

if /i "!NET_CHOICE!"=="1" goto NET_1
if /i "!NET_CHOICE!"=="2" goto NET_2
if /i "!NET_CHOICE!"=="3" goto NET_3
if /i "!NET_CHOICE!"=="4" goto NET_4
if /i "!NET_CHOICE!"=="5" goto NET_5
if /i "!NET_CHOICE!"=="6" goto NET_6
if /i "!NET_CHOICE!"=="7" goto NET_7
if /i "!NET_CHOICE!"=="8" goto NET_8
if /i "!NET_CHOICE!"=="9" goto NET_9
if /i "!NET_CHOICE!"=="10" goto NET_10
if /i "!NET_CHOICE!"=="11" goto NET_11
if /i "!NET_CHOICE!"=="12" goto NET_12
if /i "!NET_CHOICE!"=="13" goto NET_13
if /i "!NET_CHOICE!"=="A" goto NET_10
if /i "!NET_CHOICE!"=="B" goto NET_11
if /i "!NET_CHOICE!"=="C" goto NET_12
if /i "!NET_CHOICE!"=="D" goto NET_13
if "!NET_CHOICE!"=="0" goto :EOF
goto NETWORK_MENU

:NET_1
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0system_tools.ps1" -Action NetworkReset
if errorlevel 1 echo   [-] Action failed. Review the error above before retrying.
pause
goto NETWORK_MENU

:NET_2
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0system_tools.ps1" -Action NetworkFlush
if errorlevel 1 echo   [-] Action failed. Review the error above before retrying.
pause
goto NETWORK_MENU

:NET_3
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0system_tools.ps1" -Action NetworkWinsock
if errorlevel 1 echo   [-] Action failed. Review the error above before retrying.
pause
goto NETWORK_MENU

:NET_4
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0system_tools.ps1" -Action NetworkIP
if errorlevel 1 echo   [-] Action failed. Review the error above before retrying.
pause
goto NETWORK_MENU

:NET_5
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0system_tools.ps1" -Action NetworkRenew
if errorlevel 1 echo   [-] Action failed. Review the error above before retrying.
pause
goto NETWORK_MENU

:NET_6
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0system_tools.ps1" -Action NetworkPing
if errorlevel 1 echo   [-] Action failed. Review the error above before retrying.
pause
goto NETWORK_MENU

:NET_7
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0system_tools.ps1" -Action NetworkBenchmark
if errorlevel 1 echo   [-] Action failed. Review the error above before retrying.
pause
goto NETWORK_MENU

:NET_8
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0system_tools.ps1" -Action NetworkDNS
if errorlevel 1 echo   [-] Action failed. Review the error above before retrying.
pause
goto NETWORK_MENU

:NET_9
cls
echo.
echo   +------------------------------------------------------------------------------------------------+
echo   ^|   Network Adapter Information                                                                 ^|
echo   +------------------------------------------------------------------------------------------------+
echo.
ipconfig /all
echo.
pause
goto NETWORK_MENU

:NET_10
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0system_tools.ps1" -Action NetworkIPv6Off
if errorlevel 1 echo   [-] Action failed. Review the error above before retrying.
pause
goto NETWORK_MENU

:NET_A
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0system_tools.ps1" -Action NetworkIPv6Off
if errorlevel 1 echo   [-] Action failed. Review the error above before retrying.
pause
goto NETWORK_MENU

:NET_11
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0system_tools.ps1" -Action NetworkIPv6On
if errorlevel 1 echo   [-] Action failed. Review the error above before retrying.
pause
goto NETWORK_MENU

:NET_B
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0system_tools.ps1" -Action NetworkIPv6On
if errorlevel 1 echo   [-] Action failed. Review the error above before retrying.
pause
goto NETWORK_MENU

:NET_12
:NET_C
cls
echo.
echo   +------------------------------------------------------------------------------------------------+
echo   ^|   Active Network Connections                                                                  ^|
echo   +------------------------------------------------------------------------------------------------+
echo.
echo   Proto  Local Address          Foreign Address        State
echo   -----------------------------------------------------------------------------
netstat -an | findstr /i "ESTABLISHED LISTENING"
echo.
pause
goto NETWORK_MENU

:NET_13
:NET_D
cls
echo.
echo   +------------------------------------------------------------------------------------------------+
echo   ^|   Internet Speed Test                                                                         ^|
echo   +------------------------------------------------------------------------------------------------+
echo.
echo   [*] Opening Speedtest by Ookla (speedtest.net) in your default browser...
start https://www.speedtest.net
echo   [+] Opened: speedtest.net
echo.
echo   [ Quick Connectivity Check ]
ping -n 3 8.8.8.8 | findstr "time"
ping -n 3 1.1.1.1 | findstr "time"
echo.
pause
goto NETWORK_MENU
