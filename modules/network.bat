@echo off

setlocal EnableDelayedExpansion
:: ============================================================
::  KyuTools - Network & Internet Optimizer Module
:: ============================================================

:NETWORK_MENU
cls
mode con: cols=100 lines=45
title  KyuTools - Network and Internet Optimizer
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
echo   ^|   [A]   Disable IPv6                                                                          ^|
echo   ^|   [B]   Enable IPv6                                                                           ^|
echo   ^|   [C]   View Active Connections  (netstat)                                                    ^|
echo   ^|   [D]   Internet Speed Test  (opens browser)                                                  ^|
echo   ^|   [0]   Back to Main Menu                                                                     ^|
echo   ^|                                                                                                ^|
echo   +------------------------------------------------------------------------------------------------+
echo.
set "NET_CHOICE="
set /p "NET_CHOICE=    >> Select option: "

if /i "%NET_CHOICE%"=="1" goto NET_1
if /i "%NET_CHOICE%"=="2" goto NET_2
if /i "%NET_CHOICE%"=="3" goto NET_3
if /i "%NET_CHOICE%"=="4" goto NET_4
if /i "%NET_CHOICE%"=="5" goto NET_5
if /i "%NET_CHOICE%"=="6" goto NET_6
if /i "%NET_CHOICE%"=="7" goto NET_7
if /i "%NET_CHOICE%"=="8" goto NET_8
if /i "%NET_CHOICE%"=="9" goto NET_9
if /i "%NET_CHOICE%"=="A" goto NET_A
if /i "%NET_CHOICE%"=="B" goto NET_B
if /i "%NET_CHOICE%"=="C" goto NET_C
if /i "%NET_CHOICE%"=="D" goto NET_D
if "%NET_CHOICE%"=="0" goto :EOF
goto NETWORK_MENU

:NET_1
cls
echo.
echo   +------------------------------------------------------------------------------------------------+
echo   ^|   Full Network Reset                                                                          ^|
echo   +------------------------------------------------------------------------------------------------+
echo.
echo   [!] This resets all network components. Internet will briefly disconnect.
echo.
set "CONFIRM="
set /p "CONFIRM=   >> Continue? (Y/N): "
if /i not "%CONFIRM%"=="Y" goto NETWORK_MENU
echo.
echo   [1/7]  Flushing DNS...
ipconfig /flushdns >nul & echo          Done.
echo   [2/7]  Releasing IP...
ipconfig /release >nul 2>&1 & echo          Done.
echo   [3/7]  Resetting Winsock...
netsh winsock reset >nul & echo          Done.
echo   [4/7]  Resetting TCP/IP...
netsh int ip reset >nul & echo          Done.
echo   [5/7]  Resetting IPv4 and IPv6...
netsh int ipv4 reset >nul & netsh int ipv6 reset >nul & echo          Done.
echo   [6/7]  Resetting firewall policies...
netsh advfirewall reset >nul 2>&1 & echo          Done.
echo   [7/7]  Renewing IP...
ipconfig /renew >nul 2>&1 & echo          Done.
echo.
echo   [+] Full Network Reset Complete! Please RESTART your computer.
echo.
pause
goto NETWORK_MENU

:NET_2
cls
echo.
echo   +------------------------------------------------------------------------------------------------+
echo   ^|   Flush DNS Cache                                                                             ^|
echo   +------------------------------------------------------------------------------------------------+
echo.
ipconfig /flushdns
ipconfig /registerdns >nul 2>&1
echo   [+] DNS flushed and re-registered.
echo.
pause
goto NETWORK_MENU

:NET_3
cls
echo.
echo   +------------------------------------------------------------------------------------------------+
echo   ^|   Reset Winsock                                                                               ^|
echo   +------------------------------------------------------------------------------------------------+
echo.
netsh winsock reset
echo.
echo   [+] Winsock reset complete. Restart required.
echo.
pause
goto NETWORK_MENU

:NET_4
cls
echo.
echo   +------------------------------------------------------------------------------------------------+
echo   ^|   Reset TCP/IP Stack                                                                          ^|
echo   +------------------------------------------------------------------------------------------------+
echo.
netsh int ip reset
netsh int ipv4 reset
netsh int ipv6 reset
echo.
echo   [+] TCP/IP stack reset. Restart required.
echo.
pause
goto NETWORK_MENU

:NET_5
cls
echo.
echo   +------------------------------------------------------------------------------------------------+
echo   ^|   Release and Renew IP Address                                                                ^|
echo   +------------------------------------------------------------------------------------------------+
echo.
echo   [*] Releasing IP...
ipconfig /release
echo.
echo   [*] Renewing IP from DHCP...
ipconfig /renew
echo.
echo   [ Current Connection ]
ipconfig | findstr /i "IPv4\|Gateway\|Subnet"
echo.
pause
goto NETWORK_MENU

:NET_6
cls
echo.
echo   +------------------------------------------------------------------------------------------------+
echo   ^|   Ping / Latency Test                                                                         ^|
echo   +------------------------------------------------------------------------------------------------+
echo.
echo   [1]  Google DNS  (8.8.8.8)
echo   [2]  Cloudflare  (1.1.1.1)
echo   [3]  Custom host or IP
echo.
set "PING_OPT="
set /p "PING_OPT=   >> Choose target: "
if "%PING_OPT%"=="1" set "PING_HOST=8.8.8.8"
if "%PING_OPT%"=="2" set "PING_HOST=1.1.1.1"
if "%PING_OPT%"=="3" (
    set "PING_HOST="
    set /p "PING_HOST=   >> Enter hostname or IP: "
)
if "%PING_HOST%"=="" goto NETWORK_MENU
echo.
echo   [*] Pinging %PING_HOST% with 10 packets...
echo.
ping -n 10 %PING_HOST%
echo.
pause
goto NETWORK_MENU

:NET_7
cls
echo.
echo   +------------------------------------------------------------------------------------------------+
echo   ^|   DNS Speed Benchmark                                                                         ^|
echo   +------------------------------------------------------------------------------------------------+
echo.
echo   Testing response times to popular DNS servers...
echo.
for %%S in (8.8.8.8 1.1.1.1 9.9.9.9 208.67.222.222 1.0.0.1) do (
    echo   Testing  %%S ...
    ping -n 4 %%S | findstr /i "average\|ms" | findstr /v "Pinging"
    echo.
)
echo   Reference:  8.8.8.8=Google   1.1.1.1=Cloudflare   9.9.9.9=Quad9   208.67.222.222=OpenDNS
echo.
pause
goto NETWORK_MENU

:NET_8
cls
echo.
echo   +------------------------------------------------------------------------------------------------+
echo   ^|   Change DNS Server                                                                           ^|
echo   +------------------------------------------------------------------------------------------------+
echo.
echo   [1]  Google       8.8.8.8  /  8.8.4.4
echo   [2]  Cloudflare   1.1.1.1  /  1.0.0.1
echo   [3]  Quad9        9.9.9.9  /  149.112.112.112
echo   [4]  OpenDNS      208.67.222.222  /  208.67.220.220
echo   [5]  Custom
echo   [0]  Cancel
echo.
set "DNS_CHOICE="
set /p "DNS_CHOICE=   >> Select DNS preset: "
if "%DNS_CHOICE%"=="0" goto NETWORK_MENU
if "%DNS_CHOICE%"=="1" ( set "DNS1=8.8.8.8"        & set "DNS2=8.8.4.4" )
if "%DNS_CHOICE%"=="2" ( set "DNS1=1.1.1.1"        & set "DNS2=1.0.0.1" )
if "%DNS_CHOICE%"=="3" ( set "DNS1=9.9.9.9"        & set "DNS2=149.112.112.112" )
if "%DNS_CHOICE%"=="4" ( set "DNS1=208.67.222.222" & set "DNS2=208.67.220.220" )
if "%DNS_CHOICE%"=="5" (
    set "DNS1=" & set "DNS2="
    set /p "DNS1=   >> Primary DNS:   "
    set /p "DNS2=   >> Secondary DNS: "
)
echo.
echo   [*] Detecting active adapter...
set "ADAPTER="
for /f "tokens=*" %%A in ('netsh interface show interface ^| findstr "Connected"') do (
    for /f "tokens=4*" %%B in ("%%A") do set "ADAPTER=%%B"
)
echo   [*] Applying to adapter: %ADAPTER%
netsh interface ipv4 set dns name="%ADAPTER%" static %DNS1% primary >nul 2>&1
netsh interface ipv4 add dns name="%ADAPTER%" %DNS2% index=2 >nul 2>&1
echo   [+] DNS set to %DNS1% / %DNS2%
ipconfig /flushdns >nul
echo   [+] DNS cache flushed.
echo.
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

:NET_A
cls
echo.
echo   +------------------------------------------------------------------------------------------------+
echo   ^|   Disable IPv6                                                                                ^|
echo   +------------------------------------------------------------------------------------------------+
echo.
netsh interface ipv6 set teredo disabled >nul
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters" /v DisabledComponents /t REG_DWORD /d 0xFF /f >nul
echo   [+] IPv6 disabled. Restart required.
echo.
pause
goto NETWORK_MENU

:NET_B
cls
echo.
echo   +------------------------------------------------------------------------------------------------+
echo   ^|   Enable IPv6                                                                                 ^|
echo   +------------------------------------------------------------------------------------------------+
echo.
netsh interface ipv6 set teredo default >nul
reg delete "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters" /v DisabledComponents /f >nul 2>&1
echo   [+] IPv6 enabled. Restart required.
echo.
pause
goto NETWORK_MENU

:NET_C
cls
echo.
echo   +------------------------------------------------------------------------------------------------+
echo   ^|   Active Network Connections                                                                  ^|
echo   +------------------------------------------------------------------------------------------------+
echo.
netstat -an | findstr "ESTABLISHED\|LISTENING"
echo.
pause
goto NETWORK_MENU

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
