@echo off
setlocal EnableDelayedExpansion

:: ============================================================
::  KyuTools v1.1 - Account Recovery & Access Guide Module
::  File: modules\account_recovery.bat
::
::  Description:
::  Non-destructive diagnostics and supported recovery guidance
::  for Windows login issues, Microsoft Accounts, Windows Hello
::  PIN, local accounts, account lockouts, BitLocker keys,
::  offline installation detection, user data backup, and WinRE.
::
::  Security & Integrity:
::  - No password cracking, dumping, or hash manipulation.
::  - No authentication bypass or sticky-keys modification.
::  - Strictly read-only diagnostics and official recovery paths.
:: ============================================================

:RECOVERY_MENU
cls
mode con: cols=100 lines=45 >nul 2>&1
title KyuTools - Account Recovery and Access Guide
color 0A

echo.
echo   +------------------------------------------------------------------------------------------------+
echo   ^|                           Account Recovery and Access Guide                                    ^|
echo   +------------------------------------------------------------------------------------------------+
echo   ^|                                                                                                ^|
echo   ^|   [1]   Diagnose Login Problems                                                                ^|
echo   ^|   [2]   Microsoft Account Password Recovery                                                    ^|
echo   ^|   [3]   Windows Hello PIN Recovery                                                             ^|
echo   ^|   [4]   Local Account Recovery Guide                                                           ^|
echo   ^|   [5]   Account Lockout Diagnostics                                                            ^|
echo   ^|   [6]   BitLocker Recovery Assistant                                                           ^|
echo   ^|   [7]   Offline Windows Installation Detection                                                 ^|
echo   ^|   [8]   User Data Backup Assistant                                                             ^|
echo   ^|   [9]   Windows Recovery Environment Guide                                                     ^|
echo   ^|   [0]   Back to Main Menu                                                                      ^|
echo   ^|                                                                                                ^|
echo   +------------------------------------------------------------------------------------------------+
echo.
set "REC_CHOICE="
set /p "REC_CHOICE=    >> Select option: "

if "%REC_CHOICE%"=="1" goto DIAGNOSE_LOGIN
if "%REC_CHOICE%"=="2" goto MSA_RECOVERY
if "%REC_CHOICE%"=="3" goto PIN_RECOVERY
if "%REC_CHOICE%"=="4" goto LOCAL_RECOVERY
if "%REC_CHOICE%"=="5" goto LOCKOUT_DIAG
if "%REC_CHOICE%"=="6" goto BITLOCKER_ASSIST
if "%REC_CHOICE%"=="7" goto OFFLINE_DETECT
if "%REC_CHOICE%"=="8" goto DATA_BACKUP
if "%REC_CHOICE%"=="9" goto WINRE_GUIDE
if "%REC_CHOICE%"=="0" goto :EOF
goto RECOVERY_MENU


:: ============================================================
::  [1] DIAGNOSE LOGIN PROBLEMS
:: ============================================================
:DIAGNOSE_LOGIN
cls
echo.
echo   +------------------------------------------------------------------------------------------------+
echo   ^|   [1] Diagnose Login Problems - Symptom Triage                                                 ^|
echo   +------------------------------------------------------------------------------------------------+
echo   ^|                                                                                                ^|
echo   ^|   Select the symptom observed at the Windows sign-in screen:                                   ^|
echo   ^|                                                                                                ^|
echo   ^|   [1] "The password is incorrect. Try again."                                                  ^|
echo   ^|   [2] "Something went wrong and your PIN isn't available" (Windows Hello PIN failure)          ^|
echo   ^|   [3] "The referenced account is currently locked out"                                         ^|
echo   ^|   [4] "The User Profile Service failed the sign-in" / Temporary profile loaded                 ^|
echo   ^|   [5] System does not reach login screen (Blue screen, boot loop, automatic repair)            ^|
echo   ^|   [6] Keyboard, Caps Lock, or Language Layout mismatch                                         ^|
echo   ^|   [0] Back to Account Recovery Menu                                                            ^|
echo   ^|                                                                                                ^|
echo   +------------------------------------------------------------------------------------------------+
echo.
set "DIAG_CHOICE="
set /p "DIAG_CHOICE=    >> Select symptom: "

if "%DIAG_CHOICE%"=="1" goto DIAG_PWD
if "%DIAG_CHOICE%"=="2" goto DIAG_PIN
if "%DIAG_CHOICE%"=="3" goto DIAG_LOCK
if "%DIAG_CHOICE%"=="4" goto DIAG_PROF
if "%DIAG_CHOICE%"=="5" goto DIAG_BOOT
if "%DIAG_CHOICE%"=="6" goto DIAG_KBD
if "%DIAG_CHOICE%"=="0" goto RECOVERY_MENU
goto DIAGNOSE_LOGIN

:DIAG_PWD
cls
echo.
echo   +------------------------------------------------------------------------------------------------+
echo   ^|   Symptom Triage: Incorrect Password                                                           ^|
echo   +------------------------------------------------------------------------------------------------+
echo.
echo   [!] Diagnostic Analysis:
echo       Windows passwords fail for three primary reasons:
echo       1. The account is a Microsoft Account (@outlook, @hotmail, etc.) and was changed online,
echo          but this PC is offline or disconnected from Wi-Fi/Ethernet.
echo       2. The account is a local machine account with a forgotten password.
echo       3. Caps Lock is turned on or an unintended keyboard input language is selected.
echo.
echo   [*] Recommended Next Steps:
echo       - Check the bottom-right corner of the lock screen to verify internet connectivity.
echo       - If using a Microsoft Account: Proceed to Option [2] (MSA Password Recovery).
echo       - If using a Local Account: Proceed to Option [4] (Local Account Recovery Guide).
echo.
pause
goto DIAGNOSE_LOGIN

:DIAG_PIN
cls
echo.
echo   +------------------------------------------------------------------------------------------------+
echo   ^|   Symptom Triage: Windows Hello PIN Unavailable                                                ^|
echo   +------------------------------------------------------------------------------------------------+
echo.
echo   [!] Diagnostic Analysis:
echo       Windows Hello PIN is bound to the computer's TPM (Trusted Platform Module) chip and the
echo       cryptographic NGC container (%windir%\ServiceProfiles\LocalService\AppData\Local\Microsoft\Ngc).
echo.
echo       Common triggers:
echo       - A recent BIOS/UEFI firmware upgrade or TPM clear.
echo       - Antivirus or cleanup utility interfering with NGC service permissions.
echo       - Windows Update altering security providers.
echo.
echo   [*] Recommended Next Steps:
echo       - Click "Sign-in options" (key icon) on the sign-in screen to use your account password.
echo       - Click "I forgot my PIN" to re-authenticate with your primary Microsoft Account.
echo       - Proceed to Option [3] (Windows Hello PIN Recovery) for in-depth remediation.
echo.
pause
goto DIAGNOSE_LOGIN

:DIAG_LOCK
cls
echo.
echo   +------------------------------------------------------------------------------------------------+
echo   ^|   Symptom Triage: Account Locked Out                                                           ^|
echo   +------------------------------------------------------------------------------------------------+
echo.
echo   [!] Diagnostic Analysis:
echo       Account lockout occurs when an account security policy specifies a maximum number of failed
echo       attempts (e.g. 3 to 5 tries) within an observation window.
echo.
echo       Default Windows behavior:
echo       - Most local lockout policies automatically expire after 15 to 30 minutes.
echo       - If managed by Active Directory / Domain, contact your network administrator.
echo.
echo   [*] Recommended Next Steps:
echo       - Proceed to Option [5] (Account Lockout Diagnostics) to inspect your policy lockout window
echo         and verify the account's locked status.
echo.
pause
goto DIAGNOSE_LOGIN

:DIAG_PROF
cls
echo.
echo   +------------------------------------------------------------------------------------------------+
echo   ^|   Symptom Triage: Corrupted User Profile                                                       ^|
echo   +------------------------------------------------------------------------------------------------+
echo.
echo   [!] Diagnostic Analysis:
echo       "The User Profile Service failed the sign-in. User profile cannot be loaded."
echo       This indicates the user's NTUSER.DAT hive is locked, damaged, or marked with a .bak extension
echo       under HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList.
echo.
echo   [*] Recommended Recovery Procedure:
echo       1. Restart the PC in Safe Mode (Option [9] - WinRE Guide).
echo       2. Back up critical personal files first (Option [8] - User Data Backup Assistant).
echo       3. Inspect ProfileList registry keys to remove corrupt temporary profile flags.
echo       4. Run System File Checker (sfc /scannow) and DISM via Module [3].
echo.
pause
goto DIAGNOSE_LOGIN

:DIAG_BOOT
cls
echo.
echo   +------------------------------------------------------------------------------------------------+
echo   ^|   Symptom Triage: Windows Boot Failure                                                         ^|
echo   +------------------------------------------------------------------------------------------------+
echo.
echo   [!] Diagnostic Analysis:
echo       The workstation is unable to reach the interactive logon screen due to boot sector corruption,
echo       driver crash (BSOD), filesystem damage, or a corrupted update.
echo.
echo   [*] Recommended Next Steps:
echo       - Boot into the Windows Recovery Environment (WinRE) or use installation media.
echo       - Run Startup Repair to rebuild the BCD.
echo       - Roll back recent quality updates or use System Restore.
echo       - Proceed to Option [9] (Windows Recovery Environment Guide) for full instructions.
echo.
pause
goto DIAGNOSE_LOGIN

:DIAG_KBD
cls
echo.
echo   +------------------------------------------------------------------------------------------------+
echo   ^|   Symptom Triage: Hardware & Keyboard Layout Checks                                            ^|
echo   +------------------------------------------------------------------------------------------------+
echo.
echo   [!] Common Physical & Input Causes:
echo       1. Caps Lock: Check keyboard LED indicator. Passwords in Windows are strictly case-sensitive.
echo       2. Num Lock: On laptops with integrated numpads, Num Lock may map letters (M,J,K,L,U,I,O) to numbers.
echo       3. Layout Mismatch: Check the 3-letter language code in the bottom-right corner of the lock
echo          screen (e.g. ENG US vs ENG UK, QWERTY vs AZERTY). Press Win+Space to toggle layouts.
echo       4. Eye Icon: Click and hold the "eye" icon inside the password field to reveal typed characters.
echo.
pause
goto DIAGNOSE_LOGIN


:: ============================================================
::  [2] MICROSOFT ACCOUNT PASSWORD RECOVERY
:: ============================================================
:MSA_RECOVERY
cls
echo.
echo   +------------------------------------------------------------------------------------------------+
echo   ^|   [2] Microsoft Account Password Recovery                                                      ^|
echo   +------------------------------------------------------------------------------------------------+
echo.
echo   [!] Overview:
echo       Microsoft Accounts (@outlook.com, @hotmail.com, @live.com, or personal emails registered with
echo       Microsoft) authenticate against cloud servers. Windows caches credentials locally, but
echo       passwords CANNOT be reset by local SAM database tools.
echo.
echo   [*] Official Recovery Portals:
echo       1. Standard Password Reset:
echo          https://account.live.com/password/reset
echo          Use a mobile phone, tablet, or another computer to reset your password. You will need
echo          access to your recovery phone number, Authenticator app, or backup email address.
echo.
echo       2. Account Recovery Form (ACSR) (When 2FA or recovery options are inaccessible):
echo          https://account.live.com/acsr
echo          Submit an identity verification request with recent emails, passwords, and billing info.
echo.
echo       3. Work or School Accounts (Microsoft Entra ID / Microsoft 365):
echo          https://passwordreset.microsoftonline.com
echo          Self-Service Password Reset (SSPR) portal for corporate or school credentials.
echo.
echo   [!] CRITICAL: Network Synchronization Requirement
echo       After changing your Microsoft Account password online, your Windows PC MUST have an active
echo       internet connection at the sign-in screen to download the updated credential token!
echo       - Verify Ethernet cable is plugged in, OR
echo       - Click the Wi-Fi icon in the bottom-right corner of the sign-in screen and connect.
echo.
echo   --------------------------------------------------------------------------------------------------
echo   Available Actions:
echo     [1] Test network connectivity to Microsoft Authentication servers
echo     [2] Open Microsoft Account Password Reset in default web browser
echo     [0] Return to Menu
echo   --------------------------------------------------------------------------------------------------
echo.
set "MSA_ACT="
set /p "MSA_ACT=    >> Select action [0-2]: "

if "%MSA_ACT%"=="1" goto MSA_TEST_NET
if "%MSA_ACT%"=="2" goto MSA_OPEN_URL
if "%MSA_ACT%"=="0" goto RECOVERY_MENU
goto MSA_RECOVERY

:MSA_TEST_NET
echo.
echo   [*] Testing connection to internet and Microsoft authentication endpoints...
echo.
echo   --- Ping Gateway / DNS (1.1.1.1) ---
ping -n 2 1.1.1.1 >nul 2>&1
if %errorlevel% EQU 0 (
    echo   [+] Internet gateway connectivity: OK
) else (
    echo   [-] Internet gateway connectivity: FAILED (Check network cables / Wi-Fi)
)

echo   --- Ping Microsoft Account Servers (account.live.com) ---
ping -n 2 account.live.com >nul 2>&1
if %errorlevel% EQU 0 (
    echo   [+] Microsoft Account service reachable: OK
) else (
    echo   [-] Microsoft Account service unreachable. Check DNS or firewall settings.
)
echo.
pause
goto MSA_RECOVERY

:MSA_OPEN_URL
echo.
echo   [*] Launching official Microsoft Account recovery portal in default browser...
start https://account.live.com/password/reset
echo   [+] Browser launched. Follow on-screen instructions to reset your password.
echo.
pause
goto MSA_RECOVERY


:: ============================================================
::  [3] WINDOWS HELLO PIN RECOVERY
:: ============================================================
:PIN_RECOVERY
cls
echo.
echo   +------------------------------------------------------------------------------------------------+
echo   ^|   [3] Windows Hello PIN Recovery                                                               ^|
echo   +------------------------------------------------------------------------------------------------+
echo.
echo   [!] How Windows Hello PIN Operates:
echo       A PIN is tied to the local device hardware using the TPM (Trusted Platform Module). It is NOT
echo       transmitted over the network. If the TPM is cleared, the system board replaced, or the
echo       cryptographic container damaged, PIN authentication will fail.
echo.
echo   [*] Supported Recovery Methods:
echo.
echo       METHOD 1: Sign-In Options (Lock Screen)
echo       On the Windows sign-in screen, click "Sign-in options" below the input box.
echo       Click the Key / Password icon to log in using your account's full password instead of the PIN.
echo.
echo       METHOD 2: "I Forgot My PIN" Link
echo       If you know your Microsoft account password, click "I forgot my PIN" directly on the sign-in
echo       screen. Windows will prompt for your account password and 2FA, then guide you to create a
echo       new PIN immediately.
echo.
echo       METHOD 3: Windows Hello NGC Container Reset
echo       If the PIN service is corrupted (errors 0xd000a002, 0x80090027, 0x80280013):
echo       The container is located at:
echo         %SystemRoot%\ServiceProfiles\LocalService\AppData\Local\Microsoft\Ngc
echo       Renaming or clearing this folder forces Windows to recreate the cryptographic store.
echo       (Requires administrative privileges or Windows Recovery Environment command prompt).
echo.
echo   --------------------------------------------------------------------------------------------------
echo   Diagnostic Checks:
echo     [1] Check NGC Container Status (Read-Only)
echo     [2] Check Convenience PIN Group Policy Status
echo     [0] Return to Menu
echo   --------------------------------------------------------------------------------------------------
echo.
set "PIN_ACT="
set /p "PIN_ACT=    >> Select action [0-2]: "

if "%PIN_ACT%"=="1" goto PIN_CHECK_NGC
if "%PIN_ACT%"=="2" goto PIN_CHECK_GPO
if "%PIN_ACT%"=="0" goto RECOVERY_MENU
goto PIN_RECOVERY

:PIN_CHECK_NGC
echo.
echo   [*] Checking Windows Hello NGC Container directory...
set "NGC_PATH=%SystemRoot%\ServiceProfiles\LocalService\AppData\Local\Microsoft\Ngc"
if exist "%NGC_PATH%" (
    echo   [+] NGC folder detected at: %NGC_PATH%
    echo   [*] Querying directory access permissions...
    icacls "%NGC_PATH%" 2>nul | findstr /i "SYSTEM Administrators LocalService"
    if %errorlevel% NEQ 0 (
        echo   [i] Note: Default security restricts standard access to LocalService/SYSTEM.
    )
) else (
    echo   [-] NGC folder does not exist or has not been initialized yet.
)
echo.
pause
goto PIN_RECOVERY

:PIN_CHECK_GPO
echo.
echo   [*] Querying Windows Hello & PIN Policy Registry Settings...
reg query "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v AllowDomainPINLogon >nul 2>&1
if %errorlevel% EQU 0 (
    echo   [+] Found AllowDomainPINLogon policy:
    reg query "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v AllowDomainPINLogon
) else (
    echo   [i] No domain PIN restriction policy detected (Default Windows behavior active).
)
echo.
pause
goto PIN_RECOVERY


:: ============================================================
::  [4] LOCAL ACCOUNT RECOVERY GUIDE
:: ============================================================
:LOCAL_RECOVERY
cls
echo.
echo   +------------------------------------------------------------------------------------------------+
echo   ^|   [4] Local Account Recovery Guide                                                             ^|
echo   +------------------------------------------------------------------------------------------------+
echo.
echo   [!] Security Notice:
echo       In compliance with cybersecurity best practices and system integrity standards, KyuTools
echo       does not extract, crack, or bypass password hashes. All procedures below use supported,
echo       official Windows recovery pathways.
echo.
echo   [*] Supported Local Account Recovery Methods:
echo.
echo       METHOD 1: Windows Security Questions (Windows 10 / 11)
echo       If security questions were configured during local account creation:
echo       1. Enter an incorrect password at the sign-in screen.
echo       2. Click the "Reset password" link that appears below the password box.
echo       3. Answer the 3 security questions correctly to enter a new password.
echo.
echo       METHOD 2: Password Reset Disk (userkey.psw)
echo       If a USB Password Reset Disk was previously created for this account:
echo       1. Insert the USB flash drive into the computer.
echo       2. Click "Reset password" at the sign-in screen.
echo       3. Follow the Password Reset Wizard to assign a new password.
echo.
echo       METHOD 3: Secondary Administrator Account
echo       If another user on this machine has Administrator rights:
echo       1. Sign into the secondary administrator account.
echo       2. Open an elevated Command Prompt or Computer Management (lusrmgr.msc).
echo       3. Reset the forgotten user's password using: net user ^<username^> *
echo.
echo       METHOD 4: Data Backup & Fresh System Reset
echo       If no recovery questions, reset disks, or admin accounts exist:
echo       Use Option [8] (User Data Backup Assistant) to safeguard all personal documents,
echo       then perform a Windows Reset with the "Keep my files" option via Option [9].
echo.
echo   --------------------------------------------------------------------------------------------------
echo   Available Actions:
echo     [1] List Local User Accounts (net user)
echo     [2] Inspect Account Details (Read-Only)
echo     [0] Return to Menu
echo   --------------------------------------------------------------------------------------------------
echo.
set "LOC_ACT="
set /p "LOC_ACT=    >> Select action [0-2]: "

if "%LOC_ACT%"=="1" goto LOC_LIST
if "%LOC_ACT%"=="2" goto LOC_INSPECT
if "%LOC_ACT%"=="0" goto RECOVERY_MENU
goto LOCAL_RECOVERY

:LOC_LIST
cls
echo.
echo   +------------------------------------------------------------------------------------------------+
echo   ^|   Local User Accounts on this Workstation                                                      ^|
echo   +------------------------------------------------------------------------------------------------+
echo.
net user
echo.
pause
goto LOCAL_RECOVERY

:LOC_INSPECT
echo.
set "TARGET_USER="
set /p "TARGET_USER=    Enter exact username to inspect: "
if "%TARGET_USER%"=="" goto LOCAL_RECOVERY

cls
echo.
echo   +------------------------------------------------------------------------------------------------+
echo   ^|   Account Diagnostics: %TARGET_USER%
echo   +------------------------------------------------------------------------------------------------+
echo.
net user "%TARGET_USER%"
if %errorlevel% NEQ 0 (
    echo.
    echo   [-] Could not query account '%TARGET_USER%'. Verify spelling and privileges.
)
echo.
pause
goto LOCAL_RECOVERY


:: ============================================================
::  [5] ACCOUNT LOCKOUT DIAGNOSTICS
:: ============================================================
:LOCKOUT_DIAG
cls
echo.
echo   +------------------------------------------------------------------------------------------------+
echo   ^|   [5] Account Lockout Diagnostics                                                              ^|
echo   +------------------------------------------------------------------------------------------------+
echo.
echo   [*] Querying Local Machine Account Security & Lockout Policy...
echo.
net accounts
echo.
echo   [!] Key Parameters Explained:
echo       - Lockout threshold: Number of failed sign-in attempts before an account is locked.
echo         (A value of 'Never' means lockouts are disabled).
echo       - Lockout duration: Minutes the account remains locked before automatically unlocking.
echo       - Reset observation window: Time window after which the failed-attempt counter resets.
echo.
echo   --------------------------------------------------------------------------------------------------
echo   Available Actions:
echo     [1] Check if a specific account is currently locked out
echo     [2] View recent Account Lockout Events (Event ID 4740)
echo     [3] Unlock an authorized local account (Requires Administrator)
echo     [0] Return to Menu
echo   --------------------------------------------------------------------------------------------------
echo.
set "LOCK_ACT="
set /p "LOCK_ACT=    >> Select action [0-3]: "

if "%LOCK_ACT%"=="1" goto LOCK_CHECK_ACC
if "%LOCK_ACT%"=="2" goto LOCK_VIEW_EVENTS
if "%LOCK_ACT%"=="3" goto LOCK_UNLOCK_ACC
if "%LOCK_ACT%"=="0" goto RECOVERY_MENU
goto LOCKOUT_DIAG

:LOCK_CHECK_ACC
echo.
set "CHK_USER="
set /p "CHK_USER=    Enter username to check: "
if "%CHK_USER%"=="" goto LOCKOUT_DIAG

echo.
echo   [*] Checking status for '%CHK_USER%'...
net user "%CHK_USER%" 2>nul | findstr /i "Account.active"
if %errorlevel% NEQ 0 (
    echo   [-] User '%CHK_USER%' not found or access denied.
)
echo.
pause
goto LOCKOUT_DIAG

:LOCK_VIEW_EVENTS
echo.
echo   [*] Scanning Windows Security Event Log for Account Lockout Events (ID 4740)...
wevtutil qe Security "/q:*[System[(EventID=4740)]]" /c:5 /rd:true /f:text 2>nul
if %errorlevel% NEQ 0 (
    echo.
    echo   [!] Note: Reading Security Event Logs requires elevated Administrator privileges,
    echo       or Auditing for Account Lockout (Event 4740) is not enabled on this workstation.
)
echo.
pause
goto LOCKOUT_DIAG

:LOCK_UNLOCK_ACC
echo.
net session >nul 2>&1
if %errorlevel% NEQ 0 (
    echo   [!] Error: Administrator privileges are required to unlock accounts.
    echo.
    pause
    goto LOCKOUT_DIAG
)

set "UNL_USER="
set /p "UNL_USER=    Enter username of the locked account to unlock: "
if "%UNL_USER%"=="" goto LOCKOUT_DIAG

echo.
echo   [?] CONFIRMATION REQUIRED:
echo       Are you authorized to unlock account '%UNL_USER%'?
echo       (This operation only clears the lockout flag; it does NOT alter the user's password).
echo.
set "UNL_CONFIRM="
set /p "UNL_CONFIRM=    Type 'YES' to proceed with unlock: "
if /i not "%UNL_CONFIRM%"=="YES" (
    echo   [*] Unlock cancelled by user.
    pause
    goto LOCKOUT_DIAG
)

echo.
echo   [*] Unlocking account '%UNL_USER%'...
net user "%UNL_USER%" /active:yes
if %errorlevel% EQU 0 (
    echo   [+] Account '%UNL_USER%' unlocked successfully. The user may now attempt sign-in.
) else (
    echo   [-] Failed to unlock account '%UNL_USER%'. Verify the username exists.
)
echo.
pause
goto LOCKOUT_DIAG


:: ============================================================
::  [6] BITLOCKER RECOVERY ASSISTANT
:: ============================================================
:BITLOCKER_ASSIST
cls
echo.
echo   +------------------------------------------------------------------------------------------------+
echo   ^|   [6] BitLocker Recovery Assistant                                                             ^|
echo   +------------------------------------------------------------------------------------------------+
echo.
echo   [!] Security Notice:
echo       BitLocker Drive Encryption uses AES-XTS 128/256-bit full disk encryption.
echo       There is NO backdoor, bypass, or recovery without the official 48-digit recovery key!
echo.
echo   [*] Official Locations to Find Your 48-Digit Recovery Key:
echo.
echo       1. Personal Microsoft Account Cloud Vault (Most Common):
echo          https://account.microsoft.com/devices/recoverykey
echo          Log in with any Microsoft Account associated with this computer or used during setup.
echo.
echo       2. Work or School Microsoft 365 / Azure AD / Entra ID:
echo          https://myaccount.microsoft.com  -^> Devices -^> View BitLocker Keys
echo.
echo       3. Paper Printout or Saved Text File:
echo          A document created when BitLocker was initially configured, titled
echo          "BitLocker Recovery Key [Key-ID].txt".
echo.
echo       4. Active Directory Domain Services:
echo          For domain-joined corporate systems, your IT Helpdesk administrator can query the
echo          computer object in Active Directory Users and Computers (AD DS).
echo.
echo   [*] Matching the Key ID:
echo       The BitLocker recovery prompt displays a 32-character "Recovery Key ID" (first 8 chars
echo       visible). Ensure the Key ID on your screen matches the Key ID shown in your cloud vault!
echo.
echo   --------------------------------------------------------------------------------------------------
echo   Available Actions:
echo     [1] Check Drive Encryption & Protection Status (manage-bde -status)
echo     [2] View BitLocker Manual Unlock Command Syntax Guide
echo     [0] Return to Menu
echo   --------------------------------------------------------------------------------------------------
echo.
set "BIT_ACT="
set /p "BIT_ACT=    >> Select action [0-2]: "

if "%BIT_ACT%"=="1" goto BIT_STATUS
if "%BIT_ACT%"=="2" goto BIT_HELP
if "%BIT_ACT%"=="0" goto RECOVERY_MENU
goto BITLOCKER_ASSIST

:BIT_STATUS
cls
echo.
echo   +------------------------------------------------------------------------------------------------+
echo   ^|   BitLocker Drive Status Diagnostics                                                           ^|
echo   +------------------------------------------------------------------------------------------------+
echo.
manage-bde -status 2>nul
if %errorlevel% NEQ 0 (
    echo   [!] manage-bde command failed or is unavailable.
    echo       Possible reasons:
    echo       - Running on Windows Home Edition (which uses Device Encryption instead of BitLocker).
    echo       - BitLocker feature is disabled or administrative permissions are missing.
)
echo.
pause
goto BITLOCKER_ASSIST

:BIT_HELP
cls
echo.
echo   +------------------------------------------------------------------------------------------------+
echo   ^|   BitLocker Manual Unlock & Command Reference                                                  ^|
echo   +------------------------------------------------------------------------------------------------+
echo.
echo   If booting from Windows Recovery Command Prompt (WinRE), you can unlock a locked drive:
echo.
echo   1. Query status of drives:
echo      manage-bde -status
echo.
echo   2. Unlock drive using your 48-digit recovery password:
echo      manage-bde -unlock C: -RecoveryPassword XXXXXX-XXXXXX-XXXXXX-XXXXXX-XXXXXX-XXXXXX-XXXXXX-XXXXXX
echo.
echo   3. Temporarily disable protection (e.g. before BIOS / Firmware updates):
echo      manage-bde -protectors -disable C:
echo.
echo   4. Resume protection:
echo      manage-bde -protectors -enable C:
echo.
pause
goto BITLOCKER_ASSIST


:: ============================================================
::  [7] OFFLINE WINDOWS INSTALLATION DETECTION
:: ============================================================
:OFFLINE_DETECT
cls
echo.
echo   +------------------------------------------------------------------------------------------------+
echo   ^|   [7] Offline Windows Installation & Environment Detection                                     ^|
echo   +------------------------------------------------------------------------------------------------+
echo.
echo   [*] Detecting Running Execution Environment...
echo.

:: Detect WinPE via MiniNT registry key or SystemDrive X:
set "IS_WINPE=0"
reg query "HKLM\SYSTEM\CurrentControlSet\Control\MiniNT" >nul 2>&1
if %errorlevel% EQU 0 set "IS_WINPE=1"
if /i "%SystemDrive%"=="X:" set "IS_WINPE=1"

if "%IS_WINPE%"=="1" (
    echo   [!] Environment: WINDOWS PREINSTALLATION ENVIRONMENT (WinPE / WinRE)
    echo       - Running from RAMDisk: %SystemDrive%
    echo       - Note: Local drive letters (C:, D:, etc.) are often shifted in WinPE.
    echo       - Offline Windows registry hives are not loaded by default.
) else (
    echo   [+] Environment: NORMAL ACTIVE WINDOWS
    echo       - System Drive : %SystemDrive%
    echo       - Windows Dir  : %SystemRoot%
    echo       - Computer Name: %COMPUTERNAME%
)
echo.

echo   [*] Scanning all available drive letters for Windows installations...
echo.
set "FOUND_COUNT=0"
for %%D in (C D E F G H I J K L M N O P Q R S T U V W Y Z) do (
    if exist "%%D:\Windows\System32\ntoskrnl.exe" (
        set /a FOUND_COUNT+=1
        echo   [+] Found Windows installation on drive: %%D:\
        echo       Directory: %%D:\Windows
        if exist "%%D:\Windows\System32\config\SOFTWARE" (
            echo       Registry : %%D:\Windows\System32\config\SOFTWARE (Accessible)
        )
        echo.
    )
)

if "%FOUND_COUNT%"=="0" (
    echo   [-] No offline Windows installations found on tested drives.
    echo       (Drives may be locked by BitLocker or unpartitioned).
) else (
    echo   [*] Total detected Windows installations: %FOUND_COUNT%
)
echo.

echo   --------------------------------------------------------------------------------------------------
echo   Available Actions:
echo     [1] View Detailed Volume & Drive Breakdown
echo     [0] Return to Menu
echo   --------------------------------------------------------------------------------------------------
echo.
set "OFF_ACT="
set /p "OFF_ACT=    >> Select action [0-1]: "

if "%OFF_ACT%"=="1" goto OFF_VOLUMES
if "%OFF_ACT%"=="0" goto RECOVERY_MENU
goto OFFLINE_DETECT

:OFF_VOLUMES
echo.
echo   [*] Querying Logical Disks and Volumes...
echo.
powershell -NoProfile -Command "Get-CimInstance Win32_LogicalDisk | Format-Table DeviceID,VolumeName,FileSystem,@{N='Size(GB)';E={[math]::Round($_.Size/1GB,1)}},@{N='Free(GB)';E={[math]::Round($_.FreeSpace/1GB,1)}} -AutoSize" 2>nul
if %errorlevel% NEQ 0 (
    echo   [!] Falling back to native drive information:
    fsutil fsinfo drives 2>nul
)
echo.
pause
goto OFFLINE_DETECT


:: ============================================================
::  [8] USER DATA BACKUP ASSISTANT
:: ============================================================
:DATA_BACKUP
cls
echo.
echo   +------------------------------------------------------------------------------------------------+
echo   ^|   [8] User Data Backup Assistant                                                               ^|
echo   +------------------------------------------------------------------------------------------------+
echo.
echo   [!] Purpose:
echo       Safely back up personal documents, Desktop files, pictures, and downloads to an external
echo       drive or secondary partition BEFORE attempting OS resets or recovery operations.
echo.
echo   [*] Safety Guarantees:
echo       - Non-destructive: Reads files without deleting, moving, or altering source data.
echo       - Uses native robust robocopy with retry limits to prevent system hangs on locked files.
echo       - Skips recursive junction loops and transient AppData caches automatically.
echo.
echo   --------------------------------------------------------------------------------------------------
echo   Available Actions:
echo     [1] View Available Drive Letters & Volumes
echo     [2] Launch Interactive User Profile Backup Wizard
echo     [0] Return to Menu
echo   --------------------------------------------------------------------------------------------------
echo.
set "BAK_ACT="
set /p "BAK_ACT=    >> Select action [0-2]: "

if "%BAK_ACT%"=="1" goto BAK_LIST_DRIVES
if "%BAK_ACT%"=="2" goto BAK_WIZARD
if "%BAK_ACT%"=="0" goto RECOVERY_MENU
goto DATA_BACKUP

:BAK_LIST_DRIVES
echo.
echo   [*] Available Drive Letters:
fsutil fsinfo drives 2>nul
if %errorlevel% NEQ 0 (
    powershell -NoProfile -Command "Get-CimInstance Win32_LogicalDisk | Select-Object DeviceID, VolumeName, FreeSpace" 2>nul
)
echo.
pause
goto DATA_BACKUP

:BAK_WIZARD
echo.
echo   === STEP 1: Select Source User Directory ===
echo   Common locations:
if exist "C:\Users" (
    echo   Found user profiles on C:\Users:
    dir /b /ad "C:\Users" 2>nul | findstr /v /i "All.Users Default Default.User Public"
)
echo.
set "SRC_DIR="
set /p "SRC_DIR=    Enter full Source Directory path (e.g. C:\Users\Username): "
if "%SRC_DIR%"=="" goto DATA_BACKUP

if not exist "%SRC_DIR%" (
    echo.
    echo   [-] Error: Source directory does not exist: "%SRC_DIR%"
    pause
    goto DATA_BACKUP
)

echo.
echo   === STEP 2: Select Destination Backup Directory ===
echo   (Ensure target drive has adequate free storage space)
echo.
set "DST_DIR="
set /p "DST_DIR=    Enter full Destination path (e.g. E:\Backup_KyuTools): "
if "%DST_DIR%"=="" goto DATA_BACKUP

echo.
echo   === STEP 3: Select Backup Scope ===
echo   [1] User Libraries Only (Desktop, Documents, Downloads, Pictures, Music, Videos)
echo   [2] Entire Profile Directory (Excludes transient AppData caches)
echo.
set "SCOPE_CHOICE="
set /p "SCOPE_CHOICE=    Select scope [1-2]: "

echo.
echo   ==================================================================================================
echo   BACKUP SUMMARY & CONFIRMATION:
echo     Source     : "%SRC_DIR%"
echo     Destination: "%DST_DIR%"
echo     Mode       : Non-destructive Robocopy (Copy only, no source deletion)
echo   ==================================================================================================
echo.
set "BAK_CONFIRM="
set /p "BAK_CONFIRM=    Are you ready to proceed with backup? (Type 'YES' to start): "
if /i not "%BAK_CONFIRM%"=="YES" (
    echo   [*] Backup cancelled by user.
    pause
    goto DATA_BACKUP
)

echo.
echo   [*] Creating destination folder if needed...
if not exist "%DST_DIR%" mkdir "%DST_DIR%" >nul 2>&1

echo   [*] Starting safe copy process... Please wait.
echo.

if "%SCOPE_CHOICE%"=="1" (
    for %%F in (Desktop Documents Downloads Pictures Music Videos) do (
        if exist "%SRC_DIR%\%%F" (
            echo   [*] Copying %%F...
            robocopy "%SRC_DIR%\%%F" "%DST_DIR%\%%F" /E /R:1 /W:1 /COPY:DAT /XJ /NFL /NDL /NP
        )
    )
) else (
    echo   [*] Copying full profile data...
    robocopy "%SRC_DIR%" "%DST_DIR%" /E /R:1 /W:1 /COPY:DAT /XJ /XD "AppData\Local\Temp" "AppData\Local\Microsoft\Windows\INetCache" /NFL /NDL /NP
)

echo.
echo   [+] Backup operation completed! Check destination: "%DST_DIR%"
echo.
pause
goto DATA_BACKUP


:: ============================================================
::  [9] WINDOWS RECOVERY ENVIRONMENT GUIDE
:: ============================================================
:WINRE_GUIDE
cls
echo.
echo   +------------------------------------------------------------------------------------------------+
echo   ^|   [9] Windows Recovery Environment (WinRE) Guide                                               ^|
echo   +------------------------------------------------------------------------------------------------+
echo.
echo   [*] Checking Windows RE Status on this system...
reagentc /info 2>nul
if %errorlevel% NEQ 0 (
    echo   [!] reagentc command failed or requires Administrator privileges.
)
echo.
echo   [*] How to Access WinRE (Advanced Startup):
echo.
echo       METHOD 1: From Windows Sign-In Screen
echo       Hold down the 'Shift' key while clicking 'Restart' from the power menu in the bottom-right.
echo.
echo       METHOD 2: Hard Power Cycle Interrupt
echo       If Windows will not boot, turn on the PC and hold down the physical power button for 10
echo       seconds as soon as the Windows boot animation appears. Repeat twice; on the 3rd attempt,
echo       Windows will automatically boot into Windows Diagnostic / Automatic Repair.
echo.
echo       METHOD 3: Windows Installation USB
echo       Boot from any Windows 10/11 USB installation media. On the initial screen, click "Next",
echo       then click "Repair your computer" in the bottom-left corner.
echo.
echo   [*] Native Supported Tools Inside WinRE:
echo       - Startup Repair: Automatically corrects boot sector (BCD), partition, and registry corruption.
echo       - System Restore: Rolls back drivers and system files without affecting personal data.
echo       - Uninstall Updates: Removes recent Quality or Feature updates that prevent logon.
echo       - Command Prompt: Provides full offline access for chkdsk, sfc, robocopy, and manage-bde.
echo       - Reset This PC: Reinstalls Windows with option to "Keep my files".
echo.
echo   --------------------------------------------------------------------------------------------------
echo   Available Actions:
echo     [1] Restart Computer into WinRE Advanced Startup Now
echo     [0] Return to Menu
echo   --------------------------------------------------------------------------------------------------
echo.
set "RE_ACT="
set /p "RE_ACT=    >> Select action [0-1]: "

if "%RE_ACT%"=="1" goto WINRE_REBOOT
if "%RE_ACT%"=="0" goto RECOVERY_MENU
goto WINRE_GUIDE

:WINRE_REBOOT
echo.
echo   [!] WARNING: Your workstation will restart into the Advanced Startup menu in 10 seconds.
echo       Please ensure all open work is saved!
echo.
set "RE_CONFIRM="
set /p "RE_CONFIRM=    Type 'YES' to reboot now: "
if /i not "%RE_CONFIRM%"=="YES" (
    echo   [*] Reboot cancelled.
    pause
    goto WINRE_GUIDE
)

echo.
echo   [*] Triggering reboot to Advanced Startup...
shutdown /r /o /t 10
if %errorlevel% EQU 0 (
    echo   [+] Reboot scheduled. Type 'shutdown /a' in command prompt to cancel.
) else (
    echo   [-] Failed to trigger restart. Administrator privileges may be required.
)
echo.
pause
goto WINRE_GUIDE
