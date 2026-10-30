@echo off
setlocal EnableDelayedExpansion
:IT_MENU
cls
color 0A
echo.
echo   +-------------------------------------------------------------------------------------------------+
echo   ^|                           IT Helpdesk ^& Quick Fixes                                          ^|
echo   +-------------------------------------------------------------------------------------------------+
echo   ^|                                                                                                 ^|
echo   ^|   [1]  Reboot directly to BIOS / UEFI Settings                                                  ^|
echo   ^|   [2]  Fix Frozen Taskbar (Restart Windows Explorer)                                            ^|
echo   ^|   [3]  Fix Stuck Windows Updates (Clear Update Cache)                                           ^|
echo   ^|   [4]  Fix Corrupted Group Policy (Reset ^& Force Update)                                        ^|
echo   ^|   [5]  Reboot PC into Safe Mode (Next Restart)                                                  ^|
echo   ^|   [6]  Exit Safe Mode (Return to Normal Boot)                                                   ^|
echo   ^|   [7]  Fix Broken Start Menu / Windows Apps                                                     ^|
echo   ^|   [0]  Return to Main Menu                                                                      ^|
echo   ^|                                                                                                 ^|
echo   +-------------------------------------------------------------------------------------------------+
echo.
set IT_CHOICE=
set /p IT_CHOICE=    Select option: 

if "!IT_CHOICE!"=="1" goto BIOS
if "!IT_CHOICE!"=="2" goto EXPLORER
if "!IT_CHOICE!"=="3" goto WINUPDATE
if "!IT_CHOICE!"=="4" goto GPO
if "!IT_CHOICE!"=="5" goto SAFEMODE_ON
if "!IT_CHOICE!"=="6" goto SAFEMODE_OFF
if "!IT_CHOICE!"=="7" goto STARTMENU
if "!IT_CHOICE!"=="0" goto :EOF
goto IT_MENU

:BIOS
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0system_tools.ps1" -Action HelpBIOS
if errorlevel 1 echo   [-] Action failed. Review the error above before retrying.
pause
goto IT_MENU

:EXPLORER
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0system_tools.ps1" -Action HelpExplorer
if errorlevel 1 echo   [-] Action failed. Review the error above before retrying.
pause
goto IT_MENU

:WINUPDATE
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0system_tools.ps1" -Action RepairUpdates
if errorlevel 1 echo   [-] Action failed. Review the error above before retrying.
pause
goto IT_MENU

:GPO
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0system_tools.ps1" -Action HelpGPO
if errorlevel 1 echo   [-] Action failed. Review the error above before retrying.
pause
goto IT_MENU

:SAFEMODE_ON
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0system_tools.ps1" -Action HelpSafeOn
if errorlevel 1 echo   [-] Action failed. Review the error above before retrying.
pause
goto IT_MENU

:SAFEMODE_OFF
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0system_tools.ps1" -Action HelpSafeOff
if errorlevel 1 echo   [-] Action failed. Review the error above before retrying.
pause
goto IT_MENU

:STARTMENU
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0system_tools.ps1" -Action HelpApps
if errorlevel 1 echo   [-] Action failed. Review the error above before retrying.
pause
goto IT_MENU
