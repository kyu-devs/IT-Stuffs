@echo off
setlocal EnableDelayedExpansion
:: ============================================================
::  KyuTools - Security and Intrusion Audit Module
:: ============================================================

:SEC_MENU
cls
mode con: cols=100 lines=45
title  KyuTools - Security and Intrusion Audit
color 0A

echo.
echo   +------------------------------------------------------------------------------------------------+
echo   ^|                           Security and Intrusion Audit                                        ^|
echo   +------------------------------------------------------------------------------------------------+
echo   ^|                                                                                                ^|
echo   ^|   [1]   View Active Network Connections (Netstat)                                             ^|
echo   ^|   [2]   Check Recent Successful Logons (Security Event 4624)                                  ^|
echo   ^|   [3]   View Recently Modified Executables (Last 24 Hours)                                    ^|
echo   ^|   [4]   View Connected USB Devices History                                                    ^|
echo   ^|   [5]   Check Suspicious Startup Programs (Run Keys)                                          ^|
echo   ^|   [6]   Check Remote Desktop (RDP) Logon History                                              ^|
echo   ^|   [7]   View Windows Defender Threat History                                                  ^|
echo   ^|   [0]   Back to Main Menu                                                                     ^|
echo   ^|                                                                                                ^|
echo   +------------------------------------------------------------------------------------------------+
echo.
set "SEC_CHOICE="
set /p "SEC_CHOICE=    >> Select option: "

if "%SEC_CHOICE%"=="1" goto S_1
if "%SEC_CHOICE%"=="2" goto S_2
if "%SEC_CHOICE%"=="3" goto S_3
if "%SEC_CHOICE%"=="4" goto S_4
if "%SEC_CHOICE%"=="5" goto S_5
if "%SEC_CHOICE%"=="6" goto S_6
if "%SEC_CHOICE%"=="7" goto S_7
if "%SEC_CHOICE%"=="0" goto :EOF
goto SEC_MENU

:S_1
cls
echo.
echo   +------------------------------------------------------------------------------------------------+
echo   ^|   Active Network Connections (Established ^& Listening)                                        ^|
echo   +------------------------------------------------------------------------------------------------+
echo.
echo   [*] Running Netstat...
netstat -anob | findstr /i "established listening"
echo.
pause
goto SEC_MENU

:S_2
cls
echo.
echo   +------------------------------------------------------------------------------------------------+
echo   ^|   Recent Successful Logons (Event ID 4624)                                                    ^|
echo   +------------------------------------------------------------------------------------------------+
echo.
echo   [*] Querying Security Event Log (Last 5 logons)...
powershell -NoProfile -Command "Get-WinEvent -FilterHashtable @{LogName='Security'; Id=4624} -MaxEvents 5 -ErrorAction SilentlyContinue | Format-List TimeCreated, Message"
echo.
pause
goto SEC_MENU

:S_3
cls
echo.
echo   +------------------------------------------------------------------------------------------------+
echo   ^|   Recently Modified Executables (Last 24 Hours)                                               ^|
echo   +------------------------------------------------------------------------------------------------+
echo.
echo   [*] Scanning C:\Users and C:\ProgramData...
powershell -NoProfile -Command "Get-ChildItem -Path C:\Users, C:\ProgramData -Recurse -Include *.exe, *.bat, *.ps1, *.vbs -ErrorAction SilentlyContinue | Where-Object { $_.LastWriteTime -gt (Get-Date).AddDays(-1) } | Select-Object LastWriteTime, FullName | Format-Table -AutoSize"
echo.
pause
goto SEC_MENU

:S_4
cls
echo.
echo   +------------------------------------------------------------------------------------------------+
echo   ^|   USB Device History                                                                          ^|
echo   +------------------------------------------------------------------------------------------------+
echo.
echo   [*] Querying Registry for previously connected USB storage devices...
powershell -NoProfile -Command "Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Enum\USBSTOR\*\*' -ErrorAction SilentlyContinue | Select-Object FriendlyName, Mfg | Format-Table -AutoSize"
echo.
pause
goto SEC_MENU

:S_5
cls
echo.
echo   +------------------------------------------------------------------------------------------------+
echo   ^|   Suspicious Startup Programs (Run Keys)                                                      ^|
echo   +------------------------------------------------------------------------------------------------+
echo.
echo   [ HKLM Run ]
reg query "HKLM\Software\Microsoft\Windows\CurrentVersion\Run" 2>nul
echo.
echo   [ HKCU Run ]
reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" 2>nul
echo.
pause
goto SEC_MENU

:S_6
cls
echo.
echo   +------------------------------------------------------------------------------------------------+
echo   ^|   Remote Desktop Logon History                                                                ^|
echo   +------------------------------------------------------------------------------------------------+
echo.
echo   [*] Querying TerminalServices-LocalSessionManager Log...
powershell -NoProfile -Command "Get-WinEvent -LogName 'Microsoft-Windows-TerminalServices-LocalSessionManager/Operational' -MaxEvents 10 -ErrorAction SilentlyContinue | Where-Object { $_.Id -eq 1149 } | Format-List TimeCreated, Message"
echo.
pause
goto SEC_MENU

:S_7
cls
echo.
echo   +------------------------------------------------------------------------------------------------+
echo   ^|   Windows Defender Threat History                                                             ^|
echo   +------------------------------------------------------------------------------------------------+
echo.
echo   [*] Querying Windows Defender Protection History...
powershell -NoProfile -Command "Get-MpThreatDetection -ErrorAction SilentlyContinue | Select-Object InitialDetectionTime, ThreatName, Resources | Format-Table -AutoSize"
echo.
pause
goto SEC_MENU
