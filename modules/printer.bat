@echo off
setlocal EnableDelayedExpansion

:PRINTER_MENU
cls
color 0A
echo.
echo   +-------------------------------------------------------------------------------------------------+
echo   ^|                           Printer ^& Device Sharing                                            ^|
echo   +-------------------------------------------------------------------------------------------------+
echo   ^|                                                                                                 ^|
echo   ^|   [1]  Enable File and Printer Sharing (Firewall, Private Network ^& Discovery)                  ^|
echo   ^|   [2]  View Installed Printers ^& Drivers (Inspect, Clean ^& Install Drivers)                  ^|
echo   ^|   [3]  Share an Installed Printer  (Host PC - PC with printer connected directly)              ^|
echo   ^|   [4]  Connect to a Shared Printer  (Client PCs - Auto-detect ^& Connect)                      ^|
echo   ^|   [5]  Restart Print Spooler Service (Fixes stuck print jobs)                                   ^|
echo   ^|   [0]  Return to Main Menu                                                                      ^|
echo   ^|                                                                                                 ^|
echo   +-------------------------------------------------------------------------------------------------+
echo.
set P_CHOICE=
set /p P_CHOICE=    Select option: 

if "%P_CHOICE%"=="1" goto ENABLE_SHARING
if "%P_CHOICE%"=="2" goto VIEW_PRINTERS
if "%P_CHOICE%"=="3" goto SHARE_PRINTER
if "%P_CHOICE%"=="4" goto CONNECT_PRINTER
if "%P_CHOICE%"=="5" goto RESTART_SPOOLER
if "%P_CHOICE%"=="0" goto :EOF
goto PRINTER_MENU

:ENABLE_SHARING
echo.
echo   [*] Setting Network Profile to Private (Required for Printer Sharing)...
powershell -NoProfile -Command "Get-NetConnectionProfile | Set-NetConnectionProfile -NetworkCategory Private -ErrorAction SilentlyContinue"
echo   [*] Enabling Network Discovery...
netsh advfirewall firewall set rule group="Network Discovery" new enable=Yes >nul 2>&1
echo   [*] Enabling File and Printer Sharing...
netsh advfirewall firewall set rule group="File and Printer Sharing" new enable=Yes >nul 2>&1
echo   [*] Starting Discovery and Server services...
sc config FDResPub start= auto >nul 2>&1
net start FDResPub >nul 2>&1
sc config LanmanServer start= auto >nul 2>&1
net start LanmanServer >nul 2>&1
echo   [*] Configuring SMB signing and guest policies (Windows 11 fix)...
reg add "HKLM\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters" /v RequireSecuritySignature /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters" /v EnableSecuritySignature /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters" /v AllowInsecureGuestAuth /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\Software\Policies\Microsoft\Windows\LanmanWorkstation" /v RequireSecuritySignature /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\Software\Policies\Microsoft\Windows\LanmanWorkstation" /v AllowInsecureGuestAuth /t REG_DWORD /d 1 /f >nul 2>&1
powershell -NoProfile -Command "Set-SmbClientConfiguration -RequireSecuritySignature $false -EnableInsecureGuestLogons $true -Force -ErrorAction SilentlyContinue" >nul 2>&1
echo   [*] Disabling Password-Protected Sharing for Printers...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" /v everyoneincludesanonymous /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" /v LimitBlankPasswordUse /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" /v restrictnullsessaccess /t REG_DWORD /d 0 /f >nul 2>&1
net user Guest /active:yes >nul 2>&1
echo   [+] File and Printer Sharing enabled successfully.
echo.
pause
goto PRINTER_MENU

:VIEW_PRINTERS
cls
color 0A
echo.
echo   +-------------------------------------------------------------------------------------------------+
echo   ^|                           Installed Printers ^& Drivers                                           ^|
echo   +-------------------------------------------------------------------------------------------------+
echo.
echo   [*] Installed Printers on this PC:
powershell -NoProfile -Command "Get-Printer | Select-Object Name, @{Name='Sharing Status';Expression={if ($_.Shared) { 'Shared (Share Name: ' + $_.ShareName + ')' } else { 'Not Shared' }}}, PortName | Format-Table -AutoSize"
echo.
echo   [*] Installed Printer Drivers on this PC:
powershell -NoProfile -Command "Get-PrinterDriver | Select-Object Name, @{Name='Driver Architecture';Expression={'Type ' + $_.MajorVersion}}, Manufacturer | Format-Table -AutoSize"
echo.
echo   Driver Utilities:
echo   [1] Open Windows Add Driver Wizard (Install new driver via Windows Update / disk)
echo   [2] Clean Corrupted Driver Cache ^& Restart Print Spooler
echo   [3] Open Print Server Properties (Drivers Manager GUI)
echo   [0] Return to Printer Menu
echo.
set DRV_CHOICE=
set /p DRV_CHOICE=  Select action (or press Enter to return): 
if "%DRV_CHOICE%"=="1" (
    echo.
    echo   [*] Opening Windows Add Printer Driver Wizard...
    start /wait rundll32.exe printui.dll,PrintUIEntry /id
    goto VIEW_PRINTERS
)
if "%DRV_CHOICE%"=="2" (
    echo.
    echo   [*] Stopping Print Spooler...
    net stop spooler >nul 2>&1
    echo   [*] Purging stuck print jobs and Point ^& Print driver cache...
    del /q /f "%windir%\System32\spool\PRINTERS\*" >nul 2>&1
    del /q /f "%windir%\System32\spool\drivers\x64\PCC\*" >nul 2>&1
    echo   [*] Starting Print Spooler...
    net start spooler >nul 2>&1
    echo   [+] Driver cache cleaned and Spooler restarted successfully.
    echo.
    pause
    goto VIEW_PRINTERS
)
if "%DRV_CHOICE%"=="3" (
    start rundll32.exe printui.dll,PrintUIEntry /s /t2
    goto VIEW_PRINTERS
)
goto PRINTER_MENU

:SHARE_PRINTER
echo.
echo   +-------------------------------------------------------------------------------------------------+
echo   ^|   Share an Installed Printer (Host PC Mode)                                                     ^|
echo   +-------------------------------------------------------------------------------------------------+
echo   Use this on the PC that has the printer connected (USB or direct cable).
echo.
echo   [*] List of Installed Printers on this PC:
powershell -NoProfile -Command "Get-Printer | Select-Object Name, @{Name='Sharing Status';Expression={if ($_.Shared) { 'Shared (Share Name: ' + $_.ShareName + ')' } else { 'Not Shared' }}} | Format-Table -AutoSize"
echo.
set /p PRINTER_NAME=  Type the EXACT Name of the printer to share: 
if "%PRINTER_NAME%"=="" goto PRINTER_MENU
set /p SHARE_NAME=  Type a Share Name for other PCs (e.g., OfficePrinter): 
if "%SHARE_NAME%"=="" set "SHARE_NAME=%PRINTER_NAME%"

echo.
echo   [*] Ensuring Network Profile is Private and sharing firewall rules are open...
powershell -NoProfile -Command "Get-NetConnectionProfile | Set-NetConnectionProfile -NetworkCategory Private -ErrorAction SilentlyContinue"
netsh advfirewall firewall set rule group="File and Printer Sharing" new enable=Yes >nul 2>&1
netsh advfirewall firewall set rule group="Network Discovery" new enable=Yes >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" /v everyoneincludesanonymous /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" /v LimitBlankPasswordUse /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" /v restrictnullsessaccess /t REG_DWORD /d 0 /f >nul 2>&1
net user Guest /active:yes >nul 2>&1

echo   [*] Setting printer "%PRINTER_NAME%" to Shared...
powershell -NoProfile -Command ^
  "try {" ^
  "    Set-Printer -Name '%PRINTER_NAME%' -Shared $true -ShareName '%SHARE_NAME%' -ErrorAction Stop;" ^
  "    Write-Output '   [+] Printer shared successfully!';" ^
  "    Write-Output '   [+] Share Name : %SHARE_NAME%';" ^
  "    Write-Output '   [+] Network Path: \\%COMPUTERNAME%\%SHARE_NAME%';" ^
  "    Write-Output '   [!] Other PCs can now connect by opening ONYX IT DEPARTMENT TECH TOOLS -> Option [4] and typing: %SHARE_NAME%';" ^
  "} catch {" ^
  "    Write-Output ('   [-] Failed to share printer: ' + $_.Exception.Message);" ^
  "}"
echo.
pause
goto PRINTER_MENU

:CONNECT_PRINTER
reg add "HKLM\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters" /v RequireSecuritySignature /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters" /v AllowInsecureGuestAuth /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\Software\Policies\Microsoft\Windows\LanmanWorkstation" /v RequireSecuritySignature /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\Software\Policies\Microsoft\Windows\LanmanWorkstation" /v AllowInsecureGuestAuth /t REG_DWORD /d 1 /f >nul 2>&1
powershell -NoProfile -Command "Set-SmbClientConfiguration -RequireSecuritySignature $false -EnableInsecureGuestLogons $true -Force -ErrorAction SilentlyContinue" >nul 2>&1
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0connect_printer.ps1"
echo.
pause
goto PRINTER_MENU


:RESTART_SPOOLER
echo.
echo   [*] Stopping Print Spooler...
net stop spooler
echo   [*] Starting Print Spooler...
net start spooler
echo   [+] Print Spooler restarted successfully.
echo.
pause
goto PRINTER_MENU
