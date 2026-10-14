@echo off
setlocal EnableDelayedExpansion
:: ============================================================
::  KyuTools - Windows Activation & License Module
:: ============================================================

:ACTIVATION_MENU
cls
mode con: cols=100 lines=45
title  KyuTools - Activation and License
color 0A

echo.
echo   +------------------------------------------------------------------------------------------------+
echo   ^|                       Windows Activation and License Tools                                    ^|
echo   +------------------------------------------------------------------------------------------------+
echo   ^|                                                                                                ^|
echo   ^|   [1]   Install Office (Word, Excel, PowerPoint, Outlook Only)                                 ^|
echo   ^|   [2]   Scrub Microsoft Office (Remove M365 / Clean Licenses)                                 ^|
echo   ^|   [3]   Check Activation Status                                                               ^|
echo   ^|   [4]   Check Windows License Type                                                            ^|
echo   ^|   [5]   Activate Office with Ohook (Permanent - MAS)                                         ^|
echo   ^|   [6]   Activate with Product Key (slmgr /ipk)                                                ^|
echo   ^|   [7]   Rearm Evaluation License (extend trial)                                              ^|
echo   ^|   [8]   Fix Activation Error 0xC004F074                                                      ^|
echo   ^|   [9]   Fix Activation Error 0x8007007B                                                      ^|
echo   ^|   [A]   View Full License Details (slmgr /dlv)                                                ^|
echo   ^|   [0]   Back to Main Menu                                                                     ^|
echo   ^|                                                                                                ^|
echo   +------------------------------------------------------------------------------------------------+
echo.
set "ACT_CHOICE="
set /p "ACT_CHOICE=    >> Select option: "
if defined ACT_CHOICE set "ACT_CHOICE=!ACT_CHOICE: =!"

if "%ACT_CHOICE%"=="1" goto ACT_INSTALL_OFFICE
if "%ACT_CHOICE%"=="2" goto ACT_SCRUB_OFFICE
if "%ACT_CHOICE%"=="3" goto ACT_1
if "%ACT_CHOICE%"=="4" goto ACT_2
if "%ACT_CHOICE%"=="5" goto ACT_4
if "%ACT_CHOICE%"=="6" goto ACT_3
if "%ACT_CHOICE%"=="7" goto ACT_5
if "%ACT_CHOICE%"=="8" goto ACT_6
if "%ACT_CHOICE%"=="9" goto ACT_7
if /i "%ACT_CHOICE%"=="A" goto ACT_8
if "%ACT_CHOICE%"=="0" goto :EOF
goto ACTIVATION_MENU

:: == [1] Install Office (Word, Excel, PowerPoint, Outlook Only) =
:ACT_INSTALL_OFFICE
cls
echo.
echo   +------------------------------------------------------------------------------------------------+
echo   ^|   Install Microsoft Office (Word, Excel, PowerPoint, Outlook Only)                             ^|
echo   +------------------------------------------------------------------------------------------------+
echo.
echo   This downloads and installs official Microsoft Office directly from Microsoft CDN.
echo   Configured to install ONLY the essential core apps:
echo     - Microsoft Word
echo     - Microsoft Excel
echo     - Microsoft PowerPoint
echo     - Microsoft Outlook
echo.
echo   Excluded apps: Access, Publisher, OneNote, Teams, OneDrive, Skype/Lync.
echo.
echo   [!] Requires an active Internet connection.
echo.
echo   Select Office Edition to install:
echo     [1] Office 2021 Professional Plus  (Recommended - Works with Ohook)
echo     [2] Office 2024 Professional Plus  (Latest LTS Release)
echo     [3] Microsoft 365 Apps for Enterprise
echo     [0] Cancel
echo.
set "ED_CHOICE="
set /p "ED_CHOICE=   >> Choose edition [Default=1]: "
if defined ED_CHOICE set "ED_CHOICE=!ED_CHOICE: =!"
if "%ED_CHOICE%"=="0" goto ACTIVATION_MENU
if "%ED_CHOICE%"=="" set "ED_CHOICE=1"

set "PROD_ID=ProPlus2021Retail"
set "PROD_NAME=Office 2021 Professional Plus"
if "%ED_CHOICE%"=="2" (
    set "PROD_ID=ProPlus2024Retail"
    set "PROD_NAME=Office 2024 Professional Plus"
)
if "%ED_CHOICE%"=="3" (
    set "PROD_ID=O365ProPlusRetail"
    set "PROD_NAME=Microsoft 365 Enterprise"
)

:: Auto-detect Architecture
if "%PROCESSOR_ARCHITECTURE%"=="AMD64" (
    set "OFFICE_ARCH=64"
) else (
    set "OFFICE_ARCH=32"
)

echo.
echo   [*] Target Edition : !PROD_NAME!
echo   [*] Architecture   : !OFFICE_ARCH!-bit (Auto-detected)
echo   [*] Included Apps  : Word, Excel, PowerPoint, Outlook
echo.
set "CONFIRM_INS="
set /p "CONFIRM_INS=   >> Begin installation now? (Y/N): "
if defined CONFIRM_INS set "CONFIRM_INS=!CONFIRM_INS: =!"
if /i not "%CONFIRM_INS%"=="Y" (
    echo   [!] Installation cancelled.
    ping 127.0.0.1 -n 3 >nul
    goto ACTIVATION_MENU
)

set "OFFICE_DIR=%TEMP%\KyuTools_OfficeInstall"
if exist "!OFFICE_DIR!" rd /s /q "!OFFICE_DIR!" >nul 2>&1
mkdir "!OFFICE_DIR!" >nul 2>&1

echo.
echo   [*] Generating deployment configuration...
(
echo ^<Configuration^>
echo   ^<Add OfficeClientEdition="!OFFICE_ARCH!" Channel="Current"^>
echo     ^<Product ID="!PROD_ID!"^>
echo       ^<Language ID="MatchOS" /^>
echo       ^<Language ID="en-us" /^>
echo       ^<ExcludeApp ID="Access" /^>
echo       ^<ExcludeApp ID="Bing" /^>
echo       ^<ExcludeApp ID="Groove" /^>
echo       ^<ExcludeApp ID="Lync" /^>
echo       ^<ExcludeApp ID="OneDrive" /^>
echo       ^<ExcludeApp ID="OneNote" /^>
echo       ^<ExcludeApp ID="Publisher" /^>
echo       ^<ExcludeApp ID="Teams" /^>
echo     ^</Product^>
echo   ^</Add^>
echo   ^<RemoveMSI /^>
echo   ^<Display Level="Full" AcceptEULA="TRUE" /^>
echo   ^<Property Name="AUTOACTIVATE" Value="0" /^>
echo ^</Configuration^>
) > "!OFFICE_DIR!\configuration.xml"

echo   [*] Downloading official Microsoft Office Deployment Tool from Microsoft CDN...
curl.exe -L -# -o "!OFFICE_DIR!\setup.exe" "https://officecdn.microsoft.com/pr/wsus/setup.exe"

if not exist "!OFFICE_DIR!\setup.exe" (
    echo.
    echo   [-] Failed to download setup.exe from Microsoft CDN.
    echo   [-] Please check your internet connection and try again.
    echo.
    pause
    goto ACTIVATION_MENU
)

echo.
echo   [*] Launching Microsoft Office Click-to-Run Installer...
echo   [*] The official Microsoft Office installation window will now appear.
echo   [*] Please wait until the installation finishes...
echo.

pushd "!OFFICE_DIR!"
start /wait "" setup.exe /configure configuration.xml
set "INSTALL_STATUS=%ERRORLEVEL%"
popd

:: Cleanup installer files
rd /s /q "!OFFICE_DIR!" >nul 2>&1

echo.
if %INSTALL_STATUS% EQU 0 (
    echo   [+] Microsoft Office installation finished successfully!
    echo   [+] Word, Excel, PowerPoint, and Outlook are ready in your Start Menu.
    echo.
    echo   [*] Tip: To permanently activate Office, choose Option [5] in this menu
    echo       (Activate Office with Ohook - MAS Method).
) else (
    echo   [!] Installer exited with code %INSTALL_STATUS%.
    echo   [!] If an installation was already in progress, restart your PC and retry.
)
echo.
pause
goto ACTIVATION_MENU

:: == [2] Scrub Microsoft Office (Remove M365 / Clean Licenses) ==
:ACT_SCRUB_OFFICE
cls
echo.
echo   +------------------------------------------------------------------------------------------------+
echo   ^|   Microsoft Office Scrubber ^& Deep Removal                                                    ^|
echo   +------------------------------------------------------------------------------------------------+
echo.
echo   Completely uninstalls Microsoft Office (M365, 2024, 2021, 2019, 2016) and removes conflicting
echo   licenses, residual tokens, background services, and registry leftovers.
echo.
echo   Recommended when:
echo     - Switching from Microsoft 365 to Office 2021 Pro Plus
echo     - Resolving "Subscription Expired" or "Product Notice" errors
echo     - Fixing corrupted or stuck Office installations
echo.
echo   Select Scrub Mode:
echo     [1] Full Office C2R Scrub (Uninstalls M365/Office + wipes all licenses ^& tokens)
echo     [2] Clean Licenses Only   (Cleans M365 vNext tokens ^& product keys, keeps apps)
echo     [3] Launch Official Office Scrubber Menu (Full interactive tool)
echo     [0] Back to Activation Menu
echo.
set "SCRUB_CHOICE="
set /p "SCRUB_CHOICE=   >> Select option [0-3]: "
if defined SCRUB_CHOICE set "SCRUB_CHOICE=!SCRUB_CHOICE: =!"
if "%SCRUB_CHOICE%"=="0" goto ACTIVATION_MENU
if "%SCRUB_CHOICE%"=="" goto ACTIVATION_MENU

set "SCRUB_TOOL=%~dp0..\bin\OfficeScrubber.cmd"
if not exist "!SCRUB_TOOL!" (
    echo.
    echo   [*] Office Scrubber not found locally. Downloading latest utility...
    if not exist "%~dp0..\bin" mkdir "%~dp0..\bin" >nul 2>&1
    curl.exe -L -# -o "!SCRUB_TOOL!" "https://raw.githubusercontent.com/abbodi1406/BatUtil/master/OfficeScrubber/OfficeScrubberAIO.cmd"
)

if not exist "!SCRUB_TOOL!" (
    echo.
    echo   [-] Failed to locate or download OfficeScrubber.cmd.
    echo   [-] Please check your internet connection or place OfficeScrubber.cmd into the 'bin' folder.
    echo.
    pause
    goto ACTIVATION_MENU
)

if "%SCRUB_CHOICE%"=="1" (
    echo.
    echo   [*] Closing background Office processes...
    taskkill /f /im winword.exe /im excel.exe /im powerpnt.exe /im outlook.exe /im msaccess.exe /im onenote.exe /im lync.exe /im teams.exe /im officeclicktorun.exe /im integrator.exe >nul 2>&1
    echo   [*] Starting Full Office Click-to-Run Scrub...
    call "!SCRUB_TOOL!" /C
    echo.
    echo   [+] Full Office Scrub completed!
    echo   [+] System is now ready for a clean installation of Office 2021 Pro Plus.
    echo   [+] Tip: Select Option [1] in the Activation Menu to install Office 2021.
    echo.
    pause
    goto ACTIVATION_MENU
)

if "%SCRUB_CHOICE%"=="2" (
    echo.
    echo   [*] Cleaning Office licenses and vNext subscription tokens...
    taskkill /f /im winword.exe /im excel.exe /im powerpnt.exe /im outlook.exe /im officeclicktorun.exe >nul 2>&1
    
    :: Remove vNext license files and caches
    attrib -R "%ProgramData%\Microsoft\Office\Licenses" >nul 2>&1
    attrib -R "%ProgramData%\Microsoft\Licenses" >nul 2>&1
    attrib -R "%LocalAppData%\Microsoft\Office\Licenses" >nul 2>&1
    attrib -R "%LocalAppData%\Microsoft\Office\16.0\Licensing" >nul 2>&1
    attrib -R "%LocalAppData%\Microsoft\IdentityCache" >nul 2>&1
    attrib -R "%LocalAppData%\Microsoft\OneAuth" >nul 2>&1
    rd /s /q "%ProgramData%\Microsoft\Office\Licenses" >nul 2>&1
    rd /s /q "%ProgramData%\Microsoft\Licenses" >nul 2>&1
    rd /s /q "%LocalAppData%\Microsoft\Office\Licenses" >nul 2>&1
    rd /s /q "%LocalAppData%\Microsoft\Office\16.0\Licensing" >nul 2>&1
    rd /s /q "%LocalAppData%\Microsoft\IdentityCache" >nul 2>&1
    rd /s /q "%LocalAppData%\Microsoft\OneAuth" >nul 2>&1
    
    :: Clean vNext and identity registry entries
    reg delete "HKCU\Software\Microsoft\Office\16.0\Common\Licensing" /f >nul 2>&1
    reg delete "HKCU\Software\Microsoft\Office\16.0\Common\Identity" /f >nul 2>&1
    reg delete "HKCU\Software\Microsoft\Office\16.0\Registration" /f >nul 2>&1
    reg delete "HKLM\SOFTWARE\Microsoft\Office\ClickToRun\Configuration" /f /v SharedComputerLicensing >nul 2>&1
    reg delete "HKLM\SOFTWARE\Microsoft\Office\ClickToRun\Configuration" /f /v productkeys >nul 2>&1

    :: Uninstall leftover product keys via ospp.vbs
    set "OSPP_PATH="
    if exist "%ProgramFiles%\Microsoft Office\Office16\ospp.vbs" set "OSPP_PATH=%ProgramFiles%\Microsoft Office\Office16\ospp.vbs"
    if exist "%ProgramFiles(x86)%\Microsoft Office\Office16\ospp.vbs" set "OSPP_PATH=%ProgramFiles(x86)%\Microsoft Office\Office16\ospp.vbs"
    if defined OSPP_PATH (
        echo   [*] Checking for installed partial product keys...
        for /f "tokens=3 delims= " %%k in ('cscript //nologo "!OSPP_PATH!" /dstatus 2^>nul ^| findstr /i "Last 5 characters of installed product key:"') do (
            echo   [*] Uninstalling leftover key: %%k
            cscript //nologo "!OSPP_PATH!" /unpkey:%%k >nul 2>&1
        )
    )
    echo.
    echo   [+] Leftover Office licenses and identity tokens cleaned!
    echo   [+] You can now activate Office using Option [5] (Ohook MAS).
    echo.
    pause
    goto ACTIVATION_MENU
)

if "%SCRUB_CHOICE%"=="3" (
    cls
    call "!SCRUB_TOOL!"
    goto ACTIVATION_MENU
)

goto ACTIVATION_MENU

:: == [3] Check Activation Status ==========================
:ACT_1
cls
echo.
echo   +------------------------------------------------------------------------------------------------+
echo   ^|   Activation Status                                                                           ^|
echo   +------------------------------------------------------------------------------------------------+
echo.
echo   [ Expiry / Grace Period ]
cscript //nologo "%windir%\System32\slmgr.vbs" /xpr
echo.
echo   [ License Summary ]
cscript //nologo "%windir%\System32\slmgr.vbs" /dli
echo.
pause
goto ACTIVATION_MENU

:: == [2] License Type =====================================
:ACT_2
cls
echo.
echo   +------------------------------------------------------------------------------------------------+
echo   ^|   Windows Edition and License                                                                 ^|
echo   +------------------------------------------------------------------------------------------------+
echo.
for /f "tokens=* delims=" %%A in ('powershell -NoProfile -Command "(Get-CimInstance Win32_OperatingSystem).Caption"') do echo   Edition : %%A
for /f "tokens=* delims=" %%A in ('powershell -NoProfile -Command "(Get-CimInstance Win32_OperatingSystem).BuildNumber"') do echo   Build   : %%A
for /f "tokens=* delims=" %%A in ('powershell -NoProfile -Command "(Get-CimInstance Win32_OperatingSystem).SerialNumber"') do echo   Serial  : %%A
echo.
echo   [ License Channel ]
cscript //nologo "%windir%\System32\slmgr.vbs" /dli | findstr /i "license\|channel\|partial"
echo.
pause
goto ACTIVATION_MENU

:: == [3] Activate with Product Key ========================
:ACT_3
cls
echo.
echo   +------------------------------------------------------------------------------------------------+
echo   ^|   Activate with Product Key                                                                   ^|
echo   +------------------------------------------------------------------------------------------------+
echo.
set "PKEY="
set /p "PKEY=   >> Enter Key (XXXXX-XXXXX-XXXXX-XXXXX-XXXXX): "
if "%PKEY%"=="" (
    echo   [!] No key entered. Cancelled.
    pause
    goto ACTIVATION_MENU
)
echo.
echo   [*] Installing product key...
cscript //nologo "%windir%\System32\slmgr.vbs" /ipk %PKEY%
echo.
echo   [*] Attempting online activation...
cscript //nologo "%windir%\System32\slmgr.vbs" /ato
echo.
pause
goto ACTIVATION_MENU

:: == [4] Office Ohook Activation ===========================
:ACT_4
cls
echo.
echo   +------------------------------------------------------------------------------------------------+
echo   ^|   Activate Office with Ohook (MAS Method)                                                     ^|
echo   +------------------------------------------------------------------------------------------------+
echo.
echo   This uses Microsoft Activation Scripts (MAS) to permanently 
echo   activate Microsoft Office (Word, Excel, PowerPoint) using Ohook.
echo.
echo   [!] Requires Internet Connection.
echo.
set "CONFIRM="
set /p "CONFIRM=   >> Proceed? (Y/N): "
if /i not "%CONFIRM%"=="Y" goto ACTIVATION_MENU

echo.
echo   [*] Launching Ohook Activation Menu via PowerShell...
echo   [*] Please select option [2] "Ohook" in the blue window that appears.
echo.
powershell -ExecutionPolicy Bypass -Command "irm https://get.activated.win | iex"
echo.
echo   [+] Finished. Office should now be permanently activated!
echo.
pause
goto ACTIVATION_MENU

:: == [5] Rearm Evaluation =================================
:ACT_5
cls
echo.
echo   +------------------------------------------------------------------------------------------------+
echo   ^|   Rearm Evaluation License                                                                    ^|
echo   +------------------------------------------------------------------------------------------------+
echo.
echo   Resets the 30-day evaluation timer (max 3 times).
echo.
cscript //nologo "%windir%\System32\slmgr.vbs" /rearm
if %errorlevel%==0 (
    echo.
    echo   [+] Rearm successful! Please restart your computer.
) else (
    echo.
    echo   [!] Rearm failed. You may have used all rearm attempts.
)
echo.
pause
goto ACTIVATION_MENU

:: == [6] Fix Error 0xC004F074 =============================
:ACT_6
cls
echo.
echo   +------------------------------------------------------------------------------------------------+
echo   ^|   Fix: Error 0xC004F074  (KMS unavailable)                                                   ^|
echo   +------------------------------------------------------------------------------------------------+
echo.
echo   [*] Restarting Software Protection service...
net stop sppsvc /y >nul 2>&1
net start sppsvc >nul 2>&1
echo   [+] sppsvc restarted.
echo.
echo   [*] Clearing KMS cache...
cscript //nologo "%windir%\System32\slmgr.vbs" /ckms
echo.
echo   [*] Retrying activation...
cscript //nologo "%windir%\System32\slmgr.vbs" /ato
echo.
pause
goto ACTIVATION_MENU

:: == [7] Fix Error 0x8007007B =============================
:ACT_7
cls
echo.
echo   +------------------------------------------------------------------------------------------------+
echo   ^|   Fix: Error 0x8007007B  (invalid key format)                                                ^|
echo   +------------------------------------------------------------------------------------------------+
echo.
echo   [*] Uninstalling current product key...
cscript //nologo "%windir%\System32\slmgr.vbs" /upk
echo.
echo   [*] Clearing key from registry...
cscript //nologo "%windir%\System32\slmgr.vbs" /cpky
echo.
echo   [*] Restarting licensing service...
net stop sppsvc /y >nul 2>&1
net start sppsvc >nul 2>&1
echo.
echo   [+] Done. Re-enter your product key using Option [6].
echo.
pause
goto ACTIVATION_MENU

:: == [8] View License Details =============================
:ACT_8
cls
echo.
echo   +------------------------------------------------------------------------------------------------+
echo   ^|   Full License Details  (slmgr /dlv)                                                         ^|
echo   +------------------------------------------------------------------------------------------------+
echo.
cscript //nologo "%windir%\System32\slmgr.vbs" /dlv
echo.
pause
goto ACTIVATION_MENU
