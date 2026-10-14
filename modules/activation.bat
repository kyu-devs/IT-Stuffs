@echo off
setlocal EnableDelayedExpansion
:: ============================================================
::  ONYX IT DEPARTMENT TECH TOOLS - Windows Activation & License Module
:: ============================================================

:ACTIVATION_MENU
cls
mode con: cols=100 lines=45
title  ONYX IT DEPARTMENT TECH TOOLS - Activation and License
color 0A

echo.
echo   +------------------------------------------------------------------------------------------------+
echo   ^|                       Windows Activation and License Tools                                    ^|
echo   +------------------------------------------------------------------------------------------------+
echo   ^|                                                                                                ^|
echo   ^|   [1]   Install Office (Word, Excel, PowerPoint, Outlook Only)                                 ^|
echo   ^|   [2]   Scrub Microsoft Office (Remove M365 / Clean Licenses)                                  ^|
echo   ^|   [3]   Check Activation Status                                                               ^|
echo   ^|   [4]   Check Windows License Type                                                            ^|
echo   ^|   [5]   Activate Office with Ohook (Permanent - MAS)                                         ^|
echo   ^|   [6]   Activate with Product Key (slmgr /ipk)                                                ^|
echo   ^|   [7]   Rearm Evaluation License (extend trial)                                               ^|
echo   ^|   [8]   View Full License Details (slmgr /dlv)                                                ^|
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
if "%ACT_CHOICE%"=="8" goto ACT_8
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

set "OFFICE_DIR=%TEMP%\OnyxTools_OfficeInstall"
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
    echo   [!] Office installation was interrupted or encountered an error.
    echo.
    echo   [*] Possible causes:
    echo       - Conflicting or corrupted previous Office / M365 installation
    echo       - Background Click-to-Run service blocked
    echo       - Internet connection dropped during setup
    echo.
    set "SCRUB_PROMPT="
    set /p "SCRUB_PROMPT=   >> Would you like ONYX IT DEPARTMENT TECH TOOLS to run the Office Scrubber to clean leftovers? (Y/N): "
    if defined SCRUB_PROMPT set "SCRUB_PROMPT=!SCRUB_PROMPT: =!"
    if /i "!SCRUB_PROMPT!"=="Y" (
        goto ACT_SCRUB_OFFICE
    )
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
set "STAT_OUT=%TEMP%\kyu_stat_out.txt"
if exist "!STAT_OUT!" del /f /q "!STAT_OUT!" >nul 2>&1
cscript //nologo "%windir%\System32\slmgr.vbs" /xpr > "!STAT_OUT!" 2>&1
type "!STAT_OUT!"
echo.
echo   [ License Summary ]
cscript //nologo "%windir%\System32\slmgr.vbs" /dli >> "!STAT_OUT!" 2>&1
cscript //nologo "%windir%\System32\slmgr.vbs" /dli
echo.

findstr /i "Notification Grace unlicense not\ activated error 0x" "!STAT_OUT!" >nul 2>&1
if %errorlevel% EQU 0 (
    echo   ================================================================================================
    echo   [!] NOTICE: Windows is not permanently activated (in grace period, trial, or unlicensed).
    echo   ================================================================================================
    echo.
    set "FIX_STAT="
    set /p "FIX_STAT=   >> Would you like ONYX IT DEPARTMENT TECH TOOLS to help resolve this activation status? (Y/N): "
    if defined FIX_STAT set "FIX_STAT=!FIX_STAT: =!"
    if /i "!FIX_STAT!"=="Y" (
        echo.
        echo   Select Resolution Option:
        echo     [1] Permanently Activate Windows (HWID - MAS Method)
        echo     [2] Enter a Product Key (slmgr /ipk)
        echo     [3] Reset Licensing Service (restart sppsvc ^& clear KMS cache)
        echo     [4] Rearm 30-Day Evaluation Period
        echo     [0] Cancel
        echo.
        set "RES_CHOICE="
        set /p "RES_CHOICE=   >> Select option [1-4]: "
        if defined RES_CHOICE set "RES_CHOICE=!RES_CHOICE: =!"
        if "!RES_CHOICE!"=="1" (
            if exist "!STAT_OUT!" del /f /q "!STAT_OUT!" >nul 2>&1
            goto ACT_HWID_MAS
        )
        if "!RES_CHOICE!"=="2" (
            if exist "!STAT_OUT!" del /f /q "!STAT_OUT!" >nul 2>&1
            goto ACT_3
        )
        if "!RES_CHOICE!"=="3" (
            echo.
            echo   [*] Restarting Software Protection Service...
            net stop sppsvc /y >nul 2>&1
            net start sppsvc >nul 2>&1
            cscript //nologo "%windir%\System32\slmgr.vbs" /ckms >nul 2>&1
            echo   [+] Licensing service reset.
            echo.
        )
        if "!RES_CHOICE!"=="4" (
            if exist "!STAT_OUT!" del /f /q "!STAT_OUT!" >nul 2>&1
            goto ACT_5
        )
    )
)
if exist "!STAT_OUT!" del /f /q "!STAT_OUT!" >nul 2>&1
pause
goto ACTIVATION_MENU

:: == [4] License Type =====================================
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

:: == [6] Activate with Product Key ========================
:ACT_3
cls
echo.
echo   +------------------------------------------------------------------------------------------------+
echo   ^|   Activate with Product Key                                                                   ^|
echo   +------------------------------------------------------------------------------------------------+
echo.
set "PKEY="
set /p "PKEY=   >> Enter Key (XXXXX-XXXXX-XXXXX-XXXXX-XXXXX): "
if defined PKEY set "PKEY=!PKEY: =!"
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
set "ACT_OUT_FILE=%TEMP%\kyu_act_out.txt"
if exist "!ACT_OUT_FILE!" del /f /q "!ACT_OUT_FILE!" >nul 2>&1
cscript //nologo "%windir%\System32\slmgr.vbs" /ato > "!ACT_OUT_FILE!" 2>&1
type "!ACT_OUT_FILE!"
echo.

findstr /i "error 0x failed denied" "!ACT_OUT_FILE!" >nul 2>&1
if %errorlevel% EQU 0 (
    call :ACT_HANDLE_ERROR "!ACT_OUT_FILE!"
) else (
    echo   [+] Product activation completed successfully!
    pause
)
if exist "!ACT_OUT_FILE!" del /f /q "!ACT_OUT_FILE!" >nul 2>&1
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

:: == [7] Rearm Evaluation =================================
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

:: == Windows HWID Activation (MAS) ========================
:ACT_HWID_MAS
cls
echo.
echo   +------------------------------------------------------------------------------------------------+
echo   ^|   Activate Windows Permanently (HWID - MAS Method)                                            ^|
echo   +------------------------------------------------------------------------------------------------+
echo.
echo   This uses Microsoft Activation Scripts (MAS) to permanently 
echo   activate Windows with a genuine Digital License (HWID).
echo.
echo   [!] Requires Internet Connection.
echo.
set "CONFIRM_HWID="
set /p "CONFIRM_HWID=   >> Proceed? (Y/N): "
if defined CONFIRM_HWID set "CONFIRM_HWID=!CONFIRM_HWID: =!"
if /i not "!CONFIRM_HWID!"=="Y" goto ACTIVATION_MENU

echo.
echo   [*] Launching MAS Activation Menu via PowerShell...
echo   [*] Please select option [1] "HWID" in the window that appears.
echo.
powershell -ExecutionPolicy Bypass -Command "irm https://get.activated.win | iex"
echo.
echo   [+] Finished. Please check your activation status.
echo.
pause
goto ACTIVATION_MENU

:: == Smart Activation Error Handler =======================
:ACT_HANDLE_ERROR
set "ERR_FILE=%~1"
set "DETECTED_ERR="
set "ERR_DESC="

findstr /i "0xC004F074" "!ERR_FILE!" >nul 2>&1 && (
    set "DETECTED_ERR=0xC004F074"
    set "ERR_DESC=KMS Server is unreachable or Software Protection service is out of sync."
)
findstr /i "0x8007007B" "!ERR_FILE!" >nul 2>&1 && (
    set "DETECTED_ERR=0x8007007B"
    set "ERR_DESC=The product key has an invalid format, or a generic KMS key is pointing to an invalid DNS host."
)
findstr /i "0xC004C003" "!ERR_FILE!" >nul 2>&1 && (
    set "DETECTED_ERR=0xC004C003"
    set "ERR_DESC=The activation server determined the specified product key has been blocked by Microsoft."
)
findstr /i "0xC004F050" "!ERR_FILE!" >nul 2>&1 && (
    set "DETECTED_ERR=0xC004F050"
    set "ERR_DESC=The product key is invalid for this edition of Windows."
)
findstr /i "0x80072EE7 0x80072F8F" "!ERR_FILE!" >nul 2>&1 && (
    set "DETECTED_ERR=Network/Clock Sync Error"
    set "ERR_DESC=Cannot communicate with activation servers or PC system clock is out of sync."
)

if not defined DETECTED_ERR (
    set "DETECTED_ERR=Activation Error"
    set "ERR_DESC=Windows licensing service encountered an issue attempting activation."
)

echo.
echo   ================================================================================================
echo   [!] ACTIVATION PROBLEM DETECTED: !DETECTED_ERR!
echo   [*] Details: !ERR_DESC!
echo   ================================================================================================
echo.
set "DO_FIX="
set /p "DO_FIX=   >> Would you like ONYX IT DEPARTMENT TECH TOOLS to attempt to fix this error? (Y/N): "
if defined DO_FIX set "DO_FIX=!DO_FIX: =!"
if /i not "!DO_FIX!"=="Y" (
    echo   [*] Fix cancelled by user.
    pause
    goto :EOF
)

echo.
echo   [*] Applying automated fix for !DETECTED_ERR!...

if "!DETECTED_ERR!"=="0xC004F074" (
    echo   [*] Step 1: Restarting Software Protection Service (sppsvc)...
    net stop sppsvc /y >nul 2>&1
    net start sppsvc >nul 2>&1
    echo   [*] Step 2: Clearing stale KMS server cache...
    cscript //nologo "%windir%\System32\slmgr.vbs" /ckms >nul 2>&1
    echo   [*] Step 3: Resynchronizing system clock...
    w32tm /resync >nul 2>&1
    echo   [*] Step 4: Retrying activation...
    echo.
    cscript //nologo "%windir%\System32\slmgr.vbs" /ato
    echo.
    echo   [+] Fix routine completed. Check above for activation result.
    pause
    goto :EOF
)

if "!DETECTED_ERR!"=="0x8007007B" (
    echo   [*] Step 1: Uninstalling corrupted product key...
    cscript //nologo "%windir%\System32\slmgr.vbs" /upk >nul 2>&1
    echo   [*] Step 2: Clearing key from registry...
    cscript //nologo "%windir%\System32\slmgr.vbs" /cpky >nul 2>&1
    echo   [*] Step 3: Restarting licensing service...
    net stop sppsvc /y >nul 2>&1
    net start sppsvc >nul 2>&1
    echo.
    echo   [+] Stale/invalid key cleared successfully!
    echo   [*] You can now cleanly re-enter your valid product key.
    pause
    goto :EOF
)

if "!DETECTED_ERR!"=="Network/Clock Sync Error" (
    echo   [*] Step 1: Flushing DNS cache...
    ipconfig /flushdns >nul 2>&1
    echo   [*] Step 2: Resynchronizing system time with time.windows.com...
    net start w32time >nul 2>&1
    w32tm /resync >nul 2>&1
    echo   [*] Step 3: Retrying activation...
    echo.
    cscript //nologo "%windir%\System32\slmgr.vbs" /ato
    echo.
    echo   [+] Fix routine completed.
    pause
    goto :EOF
)

:: General Fix Routine
echo   [*] Step 1: Restarting licensing service (sppsvc)...
net stop sppsvc /y >nul 2>&1
net start sppsvc >nul 2>&1
echo   [*] Step 2: Resetting KMS host cache...
cscript //nologo "%windir%\System32\slmgr.vbs" /ckms >nul 2>&1
echo   [*] Step 3: Retrying online activation...
echo.
cscript //nologo "%windir%\System32\slmgr.vbs" /ato
echo.
echo   [+] Fix routine completed.
pause
goto :EOF

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
