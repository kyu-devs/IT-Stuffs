@echo off
setlocal EnableDelayedExpansion
:: ============================================================
::  KyuTools - File & Disk Utilities Module
:: ============================================================

:DISK_MENU
cls
mode con: cols=100 lines=45
title  KyuTools - File and Disk Utilities
color 0A

echo.
echo   +------------------------------------------------------------------------------------------------+
echo   ^|                           File and Disk Utilities                                             ^|
echo   +------------------------------------------------------------------------------------------------+
echo   ^|                                                                                                ^|
echo   ^|   [1]   Show Disk Usage by Drive                                                              ^|
echo   ^|   [2]   Find Largest Files on a Drive                                                         ^|
echo   ^|   [3]   Run Disk Cleanup  (built-in)                                                         ^|
echo   ^|   [4]   Defragment / Optimize Drive                                                           ^|
echo   ^|   [5]   Take Ownership of File or Folder                                                      ^|
echo   ^|   [6]   Show Hidden Files in Explorer                                                         ^|
echo   ^|   [7]   Hide System Files  (reverse)                                                          ^|
echo   ^|   [8]   View SFC / CBS Log                                                                   ^|
echo   ^|   [9]   Open Disk Management                                                                  ^|
echo   ^|   [A]   Create Symbolic Link                                                                  ^|
echo   ^|   [B]   File Hash Checker  (MD5 / SHA256 / SHA1)                                             ^|
echo   ^|   [C]   Find Hidden Files on a Drive                                                          ^|
echo   ^|   [0]   Back to Main Menu                                                                     ^|
echo   ^|                                                                                                ^|
echo   +------------------------------------------------------------------------------------------------+
echo.
set "DISK_CHOICE="
set /p "DISK_CHOICE=    >> Select option: "

if /i "%DISK_CHOICE%"=="1" goto D_1
if /i "%DISK_CHOICE%"=="2" goto D_2
if /i "%DISK_CHOICE%"=="3" goto D_3
if /i "%DISK_CHOICE%"=="4" goto D_4
if /i "%DISK_CHOICE%"=="5" goto D_5
if /i "%DISK_CHOICE%"=="6" goto D_6
if /i "%DISK_CHOICE%"=="7" goto D_7
if /i "%DISK_CHOICE%"=="8" goto D_8
if /i "%DISK_CHOICE%"=="9" goto D_9
if /i "%DISK_CHOICE%"=="A" goto D_A
if /i "%DISK_CHOICE%"=="B" goto D_B
if /i "%DISK_CHOICE%"=="C" goto D_C
if "%DISK_CHOICE%"=="0" goto :EOF
goto DISK_MENU

:D_1
cls
echo.
echo   +------------------------------------------------------------------------------------------------+
echo   ^|   Disk Space Usage by Drive                                                                   ^|
echo   +------------------------------------------------------------------------------------------------+
echo.
powershell -NoProfile -Command "Get-CimInstance Win32_LogicalDisk | Format-List Caption,FreeSpace,Size,VolumeName,FileSystem"
echo.
pause
goto DISK_MENU

:D_2
cls
echo.
echo   +------------------------------------------------------------------------------------------------+
echo   ^|   Find Largest Files                                                                          ^|
echo   +------------------------------------------------------------------------------------------------+
echo.
echo   [*] Attached Storage Drives (HDD/SSD/USB):
powershell -NoProfile -Command "Get-Volume | Where-Object DriveLetter | Format-Table DriveLetter, FileSystemLabel, DriveType -AutoSize | Out-String -Stream | Select-String -Pattern '\S'"
echo.
echo.
echo   [*] Scanning all available drives... this may take a moment.
echo.
powershell -NoProfile -Command "Get-Volume | Where-Object DriveLetter | ForEach-Object { Write-Host ('`n--- Largest Files on Drive ' + $_.DriveLetter + ' ---') -ForegroundColor Cyan; Get-ChildItem -Path ($_.DriveLetter + ':\') -Recurse -ErrorAction SilentlyContinue | Sort-Object Length -Descending | Select-Object -First 20 | Format-Table FullName,@{N='Size_MB';E={[math]::Round($_.Length/1MB,2)}} -AutoSize }"
echo.
pause
goto DISK_MENU

:D_3
cls
echo.
echo   +------------------------------------------------------------------------------------------------+
echo   ^|   Windows Disk Cleanup                                                                        ^|
echo   +------------------------------------------------------------------------------------------------+
echo.
echo   [*] Launching Disk Cleanup for C:...
cleanmgr /d C:
echo.
pause
goto DISK_MENU

:D_4
cls
echo.
echo   +------------------------------------------------------------------------------------------------+
echo   ^|   Defragment / Optimize Drive                                                                 ^|
echo   +------------------------------------------------------------------------------------------------+
echo.
set "DEFRAG_DRIVE="
set /p "DEFRAG_DRIVE=   >> Drive letter (Enter for C): "
if "%DEFRAG_DRIVE%"=="" set "DEFRAG_DRIVE=C"
echo.
echo   [*] Analyzing %DEFRAG_DRIVE%:...
defrag %DEFRAG_DRIVE%: /A /U /V
echo.
set "DO_DEFRAG="
set /p "DO_DEFRAG=   >> Run full optimization now? (Y/N): "
if /i "%DO_DEFRAG%"=="Y" defrag %DEFRAG_DRIVE%: /U /V
echo.
pause
goto DISK_MENU

:D_5
cls
echo.
echo   +------------------------------------------------------------------------------------------------+
echo   ^|   Take Ownership of File or Folder                                                            ^|
echo   +------------------------------------------------------------------------------------------------+
echo.
set "OWN_PATH="
set /p "OWN_PATH=   >> Enter full path: "
if "%OWN_PATH%"=="" goto DISK_MENU
takeown /f "%OWN_PATH%" /r /d Y >nul 2>&1
icacls "%OWN_PATH%" /grant %username%:F /t /c >nul 2>&1
echo   [+] Ownership granted to: %username%
echo       Path: %OWN_PATH%
echo.
pause
goto DISK_MENU

:D_6
cls
echo.
echo   +------------------------------------------------------------------------------------------------+
echo   ^|   Show Hidden Files in Explorer                                                               ^|
echo   +------------------------------------------------------------------------------------------------+
echo.
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v Hidden /t REG_DWORD /d 1 /f >nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v ShowSuperHidden /t REG_DWORD /d 1 /f >nul
echo   [+] Hidden files will now be visible.
set "RESTART="
set /p "RESTART=   >> Restart Explorer now? (Y/N): "
if /i "%RESTART%"=="Y" (
    taskkill /f /im explorer.exe >nul
    start explorer.exe
)
echo.
pause
goto DISK_MENU

:D_7
cls
echo.
echo   +------------------------------------------------------------------------------------------------+
echo   ^|   Hide System Files                                                                           ^|
echo   +------------------------------------------------------------------------------------------------+
echo.
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v Hidden /t REG_DWORD /d 2 /f >nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v ShowSuperHidden /t REG_DWORD /d 0 /f >nul
echo   [+] Hidden files concealed.
echo.
pause
goto DISK_MENU

:D_8
cls
echo.
echo   +------------------------------------------------------------------------------------------------+
echo   ^|   SFC / CBS Log Viewer  (last 50 lines)                                                      ^|
echo   +------------------------------------------------------------------------------------------------+
echo.
if exist "%windir%\Logs\CBS\CBS.log" (
    powershell -Command "Get-Content '%windir%\Logs\CBS\CBS.log' | Select-Object -Last 50"
) else (
    echo   [!] CBS.log not found.
    echo   [*] Run SFC scan first in the Maintenance module.
)
echo.
pause
goto DISK_MENU

:D_9
cls
echo.
echo   +------------------------------------------------------------------------------------------------+
echo   ^|   Disk Management                                                                             ^|
echo   +------------------------------------------------------------------------------------------------+
echo.
echo   [*] Opening Disk Management...
diskmgmt.msc
echo.
pause
goto DISK_MENU

:D_A
cls
echo.
echo   +------------------------------------------------------------------------------------------------+
echo   ^|   Create Symbolic Link                                                                        ^|
echo   +------------------------------------------------------------------------------------------------+
echo.
set "LINK_PATH="
set "TARGET_PATH="
set /p "LINK_PATH=   >> New link path  (e.g. C:\MyLink):  "
set /p "TARGET_PATH=   >> Target path   (e.g. D:\Folder):  "
if "%LINK_PATH%"=="" goto DISK_MENU
if "%TARGET_PATH%"=="" goto DISK_MENU
if exist "%TARGET_PATH%\" (
    mklink /D "%LINK_PATH%" "%TARGET_PATH%"
) else (
    mklink "%LINK_PATH%" "%TARGET_PATH%"
)
echo.
pause
goto DISK_MENU

:D_B
cls
echo.
echo   +------------------------------------------------------------------------------------------------+
echo   ^|   File Hash Checker                                                                           ^|
echo   +------------------------------------------------------------------------------------------------+
echo.
set "HASH_FILE="
set /p "HASH_FILE=   >> Enter file path: "
if "%HASH_FILE%"=="" goto DISK_MENU
if not exist "%HASH_FILE%" (
    echo   [!] File not found.
    pause
    goto DISK_MENU
)
echo.
echo   [ MD5 ]
certutil -hashfile "%HASH_FILE%" MD5 | findstr /v "hash\|CertUtil"
echo   [ SHA256 ]
certutil -hashfile "%HASH_FILE%" SHA256 | findstr /v "hash\|CertUtil"
echo   [ SHA1 ]
certutil -hashfile "%HASH_FILE%" SHA1 | findstr /v "hash\|CertUtil"
echo.
pause
goto DISK_MENU

:D_C
cls
echo.
echo   +------------------------------------------------------------------------------------------------+
echo   ^|   Find Hidden Files on a Drive                                                                ^|
echo   +------------------------------------------------------------------------------------------------+
echo.
echo   [*] Attached Storage Drives (HDD/SSD/USB):
powershell -NoProfile -Command "Get-Volume | Where-Object DriveLetter | Format-Table DriveLetter, FileSystemLabel, DriveType -AutoSize | Out-String -Stream | Select-String -Pattern '\S'"
echo.
echo.
echo   [*] Scanning all available drives... This might take a while depending on drive size.
echo.
powershell -NoProfile -Command "Get-Volume | Where-Object DriveLetter | ForEach-Object { Write-Host ('`n--- Hidden Files on Drive ' + $_.DriveLetter + ' ---') -ForegroundColor Cyan; Get-ChildItem -Path ($_.DriveLetter + ':\') -Force -Recurse -ErrorAction SilentlyContinue | Where-Object { $_.Attributes -match 'Hidden' -and !$_.PSIsContainer } | Select-Object FullName | Format-Table -HideTableHeaders }"
echo.
echo   [+] Scan complete.
echo.
pause
goto DISK_MENU
