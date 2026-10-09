@echo off
:PRINTER_MENU
cls
color 0A
echo.
echo   +-------------------------------------------------------------------------------------------------+
echo   ^|                           Printer ^& Device Sharing                                            ^|
echo   +-------------------------------------------------------------------------------------------------+
echo   ^|                                                                                                 ^|
echo   ^|   [1]  Enable File and Printer Sharing (Firewall ^& Network Discovery)                           ^|
echo   ^|   [2]  View Installed Printers                                                                  ^|
echo   ^|   [3]  Share an Installed Printer                                                               ^|
echo   ^|   [4]  Restart Print Spooler Service (Fixes stuck print jobs)                                   ^|
echo   ^|   [0]  Return to Main Menu                                                                      ^|
echo   ^|                                                                                                 ^|
echo   +-------------------------------------------------------------------------------------------------+
echo.
set P_CHOICE=
set /p P_CHOICE=    Select option: 

if "%P_CHOICE%"=="1" goto ENABLE_SHARING
if "%P_CHOICE%"=="2" goto VIEW_PRINTERS
if "%P_CHOICE%"=="3" goto SHARE_PRINTER
if "%P_CHOICE%"=="4" goto RESTART_SPOOLER
if "%P_CHOICE%"=="0" goto :EOF
goto PRINTER_MENU

:ENABLE_SHARING
echo.
echo   [*] Enabling Network Discovery...
netsh advfirewall firewall set rule group="Network Discovery" new enable=Yes >nul 2>&1
echo   [*] Enabling File and Printer Sharing...
netsh advfirewall firewall set rule group="File and Printer Sharing" new enable=Yes >nul 2>&1
echo   [+] File and Printer Sharing enabled successfully.
echo.
pause
goto PRINTER_MENU

:VIEW_PRINTERS
echo.
echo   [*] List of Installed Printers:
echo.
powershell -NoProfile -Command "Get-Printer | Format-Table Name, Shared, ShareName -AutoSize"
echo.
pause
goto PRINTER_MENU

:SHARE_PRINTER
echo.
echo   [*] List of Available Printers:
powershell -NoProfile -Command "Get-Printer | Select-Object -ExpandProperty Name"
echo.
set /p PRINTER_NAME=  Type the EXACT Name of the printer to share: 
if "%PRINTER_NAME%"=="" goto PRINTER_MENU
set /p SHARE_NAME=  Type a Share Name (e.g., OfficePrinter): 
if "%SHARE_NAME%"=="" goto PRINTER_MENU

echo.
echo   [*] Sharing printer "%PRINTER_NAME%" as "%SHARE_NAME%"...
powershell -NoProfile -Command "Set-Printer -Name '%PRINTER_NAME%' -Shared $true -ShareName '%SHARE_NAME%' -ErrorAction SilentlyContinue"
if %errorlevel% EQU 0 (
    echo   [+] Printer shared successfully!
) else (
    echo   [-] Failed to share printer. Please check the name and try again.
)
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
