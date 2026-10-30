@echo off
setlocal DisableDelayedExpansion
:: All printer actions share the checked PowerShell workflow.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0printer_tools.ps1" -Action Menu
if errorlevel 1 (
    echo   [-] Printer tools stopped with an error. Review the output above.
    pause
)
exit /b
