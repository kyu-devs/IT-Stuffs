@echo off
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

if "%IT_CHOICE%"=="1" goto BIOS
if "%IT_CHOICE%"=="2" goto EXPLORER
if "%IT_CHOICE%"=="3" goto WINUPDATE
if "%IT_CHOICE%"=="4" goto GPO
if "%IT_CHOICE%"=="5" goto SAFEMODE_ON
if "%IT_CHOICE%"=="6" goto SAFEMODE_OFF
if "%IT_CHOICE%"=="7" goto STARTMENU
if "%IT_CHOICE%"=="0" goto :EOF
goto IT_MENU

:BIOS
echo.
echo   [*] Warning: Your PC will restart immediately into BIOS/UEFI.
echo   [*] Please save all your work before proceeding.
echo.
pause
shutdown /r /fw /t 0
if %errorlevel% NEQ 0 (
    echo   [-] Error: Firmware boot is not supported on this PC (Legacy BIOS instead of UEFI).
    echo.
    pause
)
goto IT_MENU

:EXPLORER
echo.
echo   [*] Restarting Windows Explorer...
taskkill /f /im explorer.exe >nul 2>&1
start explorer.exe
echo   [+] Taskbar and Desktop reloaded successfully.
echo.
pause
goto IT_MENU

:WINUPDATE
echo.
echo   [*] Stopping Windows Update services...
net stop wuauserv >nul 2>&1
net stop bits >nul 2>&1
net stop cryptSvc >nul 2>&1
net stop msiserver >nul 2>&1
echo   [*] Clearing Update Cache (SoftwareDistribution)...
if exist "C:\Windows\SoftwareDistribution" (
    ren C:\Windows\SoftwareDistribution SoftwareDistribution.old >nul 2>&1
)
if exist "C:\Windows\System32\catroot2" (
    ren C:\Windows\System32\catroot2 catroot2.old >nul 2>&1
)
echo   [*] Restarting Windows Update services...
net start wuauserv >nul 2>&1
net start bits >nul 2>&1
net start cryptSvc >nul 2>&1
net start msiserver >nul 2>&1
echo   [+] Windows Update cache cleared successfully!
echo.
pause
goto IT_MENU

:GPO
echo.
echo   [*] Deleting Group Policy folders...
rd /s /q "%windir%\System32\GroupPolicyUsers" >nul 2>&1
rd /s /q "%windir%\System32\GroupPolicy" >nul 2>&1
echo   [*] Forcing Group Policy update...
gpupdate /force
echo   [+] Group Policy reset complete.
echo.
pause
goto IT_MENU

:SAFEMODE_ON
echo.
echo   [*] Configuring PC to boot into Safe Mode on next restart...
bcdedit /set {current} safeboot minimal
echo   [+] Done. Please restart the PC to enter Safe Mode.
echo.
pause
goto IT_MENU

:SAFEMODE_OFF
echo.
echo   [*] Removing Safe Mode boot flag...
bcdedit /deletevalue {current} safeboot
echo   [+] Done. PC will boot normally on next restart.
echo.
pause
goto IT_MENU

:STARTMENU
echo.
echo   [*] Re-registering Windows Apps (This may take a minute)...
powershell -NoProfile -Command "Get-AppXPackage -AllUsers | Foreach {Add-AppxPackage -DisableDevelopmentMode -Register \"$($_.InstallLocation)\AppXManifest.xml\"}"
echo   [+] Start Menu and Windows Apps repaired.
echo.
pause
goto IT_MENU
