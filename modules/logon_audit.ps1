# ============================================================
# ONYX IT DEPARTMENT - TECH TOOLS - Logon & Intrusion Audit Engine
# All-green console output (color 0A)
# ============================================================

function Translate-LogonType {
    param([string]$TypeNum)
    switch ($TypeNum) {
        "2"  { return "Interactive (Console / Screen)" }
        "3"  { return "Network Share (SMB / Printer)" }
        "4"  { return "Batch / Scheduled Task" }
        "5"  { return "Windows Service" }
        "7"  { return "Unlock Screen" }
        "8"  { return "Network Cleartext" }
        "9"  { return "New Credentials" }
        "10" { return "Remote Desktop (RDP)" }
        "11" { return "Cached Interactive" }
        default { 
            if ($TypeNum) { return "Type $TypeNum" } else { return "Unknown" }
        }
    }
}

function Translate-FailureStatus {
    param([string]$Status, [string]$SubStatus)
    $hex = if ($SubStatus -and $SubStatus -ne "0x0" -and $SubStatus -ne "0") { $SubStatus } else { $Status }
    switch -Regex ($hex) {
        "0xC000006A|c000006a" { return "Incorrect Password" }
        "0xC0000064|c0000064" { return "User Does Not Exist" }
        "0xC0000234|c0000234" { return "Account Locked Out" }
        "0xC0000072|c0000072" { return "Account Disabled" }
        "0xC000006F|c000006f" { return "Logon Outside Allowed Hours" }
        "0xC0000070|c0000070" { return "Workstation Restriction" }
        "0xC0000193|c0000193" { return "Account Expired" }
        "0xC0000224|c0000224" { return "Password Must Change" }
        default { 
            if ($hex -and $hex -ne "0x0" -and $hex -ne "0") { return "Error $hex" } else { return "Authentication Failure" }
        }
    }
}

function Get-LogonAuditStatus {
    $out = cmd /c "auditpol /get /subcategory:`"Logon`" 2>&1" | Out-String
    $hasFailure = $out -match 'Failure|Success and Failure'
    $hasSuccess = $out -match 'Success|Success and Failure'
    return [PSCustomObject]@{
        Raw        = $out
        HasFailure = [bool]$hasFailure
        HasSuccess = [bool]$hasSuccess
    }
}

function Show-FailedLogons {
    Write-Output ""
    Write-Output "   +-------------------------------------------------------------------------------------------------+"
    Write-Output "   |                       Failed Logon Attempts (Event ID 4625)                                     |"
    Write-Output "   +-------------------------------------------------------------------------------------------------+"
    Write-Output "   Scanning Windows Security Event Log for unauthorized access attempts..."
    Write-Output ""

    $audit = Get-LogonAuditStatus
    if (-not $audit.HasFailure) {
        Write-Output "   [!] Notice: Windows Logon Failure Auditing is currently DISABLED on this PC."
        Write-Output "   [!] Failed logon attempts might not be recorded until auditing is enabled."
        Write-Output "   [!] Use Option [5] in the menu below to enable it."
        Write-Output ""
    }

    $events = $null
    try {
        $events = @(Get-WinEvent -FilterHashtable @{LogName='Security'; Id=4625} -MaxEvents 50 -ErrorAction Stop)
    } catch {
        if ($_.Exception.Message -match 'No events were found') {
            Write-Output "   [+] No failed logon attempts found in the Security log."
            Write-Output "   [+] Either no unauthorized logins have occurred, or auditing was recently cleared."
        } else {
            Write-Output "   [-] Could not query Security log: $($_.Exception.Message)"
        }
    }

    if ($events -and $events.Count -gt 0) {
        Write-Output "   Found $($events.Count) recent failed logon attempt(s):"
        Write-Output "   -------------------------------------------------------------------------------------------------"
        Write-Output ("   {0,-20} {1,-18} {2,-16} {3,-22} {4}" -f "Date / Time", "Target User", "Source IP", "Logon Type", "Reason")
        Write-Output "   -------------------------------------------------------------------------------------------------"

        foreach ($e in $events) {
            $timeStr = $e.TimeCreated.ToString("yyyy-MM-dd HH:mm:ss")
            $uName = "Unknown"
            $ipStr = "-"
            $wkStr = "-"
            $typeStr = "Unknown"
            $subStatus = ""
            $status = ""

            try {
                [xml]$xml = $e.ToXml()
                foreach ($d in $xml.Event.EventData.Data) {
                    switch ($d.Name) {
                        "TargetUserName"  { $uName = "$($d.'#text')".Trim() }
                        "IpAddress"       { $ipStr = "$($d.'#text')".Trim() }
                        "WorkstationName" { $wkStr = "$($d.'#text')".Trim() }
                        "LogonType"       { $typeStr = Translate-LogonType -TypeNum "$($d.'#text')".Trim() }
                        "Status"          { $status = "$($d.'#text')".Trim() }
                        "SubStatus"       { $subStatus = "$($d.'#text')".Trim() }
                    }
                }
            } catch {}

            if (-not $ipStr -or $ipStr -eq "-" -or $ipStr -eq "::1") {
                $ipStr = if ($wkStr -and $wkStr -ne "-") { $wkStr } else { "Local PC" }
            }

            $reason = Translate-FailureStatus -Status $status -SubStatus $subStatus
            Write-Output ("   {0,-20} {1,-18} {2,-16} {3,-22} {4}" -f $timeStr, $uName, $ipStr, $typeStr, $reason)
        }
        Write-Output "   -------------------------------------------------------------------------------------------------"
    }
}

function Show-ActiveSessions {
    Write-Output ""
    Write-Output "   +-------------------------------------------------------------------------------------------------+"
    Write-Output "   |                    Active Logged-In Users & Network Sessions                                    |"
    Write-Output "   +-------------------------------------------------------------------------------------------------+"
    Write-Output ""
    Write-Output "   [1] Interactive User Sessions (Physical Console & Remote Desktop):"
    Write-Output "   -------------------------------------------------------------------------------------------------"
    try {
        $qu = cmd /c "quser 2>&1" | Out-String
        if ($qu -match 'USERNAME') {
            $lines = $qu -split "`r?`n"
            foreach ($l in $lines) {
                if ($l.Trim()) { Write-Output "   $l" }
            }
        } else {
            Write-Output "   No active interactive sessions found."
        }
    } catch {
        Write-Output "   Unable to query user sessions."
    }

    Write-Output ""
    Write-Output "   [2] Remote Computers Connected via SMB / File & Printer Sharing (net session):"
    Write-Output "   -------------------------------------------------------------------------------------------------"
    try {
        $ns = cmd /c "net session 2>&1" | Out-String
        if ($ns -match '\\\\') {
            $lines = $ns -split "`r?`n"
            foreach ($l in $lines) {
                if ($l.Trim()) { Write-Output "   $l" }
            }
        } else {
            Write-Output "   [i] No remote computers currently have open SMB sessions to this PC."
        }
    } catch {}

    Write-Output ""
    Write-Output "   [3] Active Inbound Connections to RDP (Port 3389) and SMB (Port 445):"
    Write-Output "   -------------------------------------------------------------------------------------------------"
    try {
        $conns = @(Get-NetTCPConnection -State Established -ErrorAction SilentlyContinue | Where-Object { 
            $_.LocalPort -eq 3389 -or $_.LocalPort -eq 445 
        })
        if ($conns.Count -gt 0) {
            foreach ($c in $conns) {
                $service = if ($c.LocalPort -eq 3389) { "Remote Desktop (3389)" } else { "File/Printer Share (445)" }
                Write-Output ("   [ALERT] Connection from {0}:{1} on {2}" -f $c.RemoteAddress, $c.RemotePort, $service)
            }
        } else {
            Write-Output "   [i] No external connections currently established on Port 3389 or Port 445."
        }
    } catch {}
    Write-Output "   -------------------------------------------------------------------------------------------------"
}

function Show-SuccessfulLogons {
    Write-Output ""
    Write-Output "   +-------------------------------------------------------------------------------------------------+"
    Write-Output "   |                      Recent Successful User Logons (Event ID 4624)                              |"
    Write-Output "   +-------------------------------------------------------------------------------------------------+"
    Write-Output "   Filtering out Windows background system accounts (SYSTEM, LOCAL SERVICE)..."
    Write-Output ""

    $events = $null
    try {
        $events = @(Get-WinEvent -FilterHashtable @{LogName='Security'; Id=4624} -MaxEvents 150 -ErrorAction Stop)
    } catch {
        if ($_.Exception.Message -match 'No events were found') {
            Write-Output "   No logon events found in the Security log."
        } else {
            Write-Output "   [-] Could not query Security log: $($_.Exception.Message)"
        }
    }

    if ($events -and $events.Count -gt 0) {
        $userList = [System.Collections.Generic.List[PSCustomObject]]::new()
        foreach ($e in $events) {
            try {
                [xml]$xml = $e.ToXml()
                $map = @{}
                foreach ($d in $xml.Event.EventData.Data) {
                    if ($d.Name) { $map[$d.Name] = "$($d.'#text')".Trim() }
                }

                $u = $map['TargetUserName']
                $lType = $map['LogonType']

                # Filter out system service accounts and machine accounts
                if ($u -and $u -notmatch '^(SYSTEM|LOCAL SERVICE|NETWORK SERVICE|ANONYMOUS LOGON|DWM-\d+|UMFD-\d+|\$.*)$') {
                    $ip = $map['IpAddress']
                    $wk = $map['WorkstationName']
                    if (-not $ip -or $ip -eq "-" -or $ip -eq "::1") {
                        $ip = if ($wk -and $wk -ne "-") { $wk } else { "Local PC" }
                    }
                    $userList.Add([PSCustomObject]@{
                        Time = $e.TimeCreated.ToString("yyyy-MM-dd HH:mm:ss")
                        User = $u
                        Type = Translate-LogonType -TypeNum $lType
                        IP   = $ip
                    })
                }
            } catch {}
            if ($userList.Count -ge 20) { break }
        }

        if ($userList.Count -gt 0) {
            Write-Output "   Recent User Logons:"
            Write-Output "   -------------------------------------------------------------------------------------------------"
            Write-Output ("   {0,-20} {1,-24} {2,-30} {3}" -f "Date / Time", "User Account", "Logon Type", "Source IP / Device")
            Write-Output "   -------------------------------------------------------------------------------------------------"
            foreach ($item in $userList) {
                Write-Output ("   {0,-20} {1,-24} {2,-30} {3}" -f $item.Time, $item.User, $item.Type, $item.IP)
            }
            Write-Output "   -------------------------------------------------------------------------------------------------"
        } else {
            Write-Output "   [i] No interactive user logons found in recent events."
        }
    }
}

function Show-AccountLockouts {
    Write-Output ""
    Write-Output "   +-------------------------------------------------------------------------------------------------+"
    Write-Output "   |                       Account Lockout Events (Event ID 4740)                                    |"
    Write-Output "   +-------------------------------------------------------------------------------------------------+"
    Write-Output "   Checking for accounts locked out due to repeated incorrect password attempts..."
    Write-Output ""

    $events = $null
    try {
        $events = @(Get-WinEvent -FilterHashtable @{LogName='Security'; Id=4740} -MaxEvents 20 -ErrorAction Stop)
    } catch {
        if ($_.Exception.Message -match 'No events were found') {
            Write-Output "   [+] No account lockout events recorded. No accounts have been locked out."
        } else {
            Write-Output "   [-] Could not query Security log: $($_.Exception.Message)"
        }
    }

    if ($events -and $events.Count -gt 0) {
        Write-Output "   [ALERT] Found $($events.Count) account lockout event(s):"
        Write-Output "   -------------------------------------------------------------------------------------------------"
        Write-Output ("   {0,-20} {1,-24} {2}" -f "Date / Time", "Locked User Account", "Calling Computer")
        Write-Output "   -------------------------------------------------------------------------------------------------"
        foreach ($e in $events) {
            $u = "Unknown"
            $caller = "-"
            try {
                [xml]$xml = $e.ToXml()
                foreach ($d in $xml.Event.EventData.Data) {
                    if ($d.Name -eq "TargetUserName") { $u = "$($d.'#text')".Trim() }
                    if ($d.Name -eq "SubjectUserName") { $caller = "$($d.'#text')".Trim() }
                }
            } catch {}
            Write-Output ("   {0,-20} {1,-24} {2}" -f $e.TimeCreated.ToString("yyyy-MM-dd HH:mm:ss"), $u, $caller)
        }
        Write-Output "   -------------------------------------------------------------------------------------------------"
    }
}

function Enable-LogonAuditing {
    Write-Output ""
    Write-Output "   +-------------------------------------------------------------------------------------------------+"
    Write-Output "   |                       Configure Windows Logon Auditing Policies                                 |"
    Write-Output "   +-------------------------------------------------------------------------------------------------+"
    Write-Output "   Enabling Windows Security Auditing for Success and Failure events..."
    Write-Output ""

    try {
        cmd /c "auditpol /set /subcategory:`"Logon`" /success:enable /failure:enable" | Out-Null
        cmd /c "auditpol /set /subcategory:`"Account Lockout`" /success:enable /failure:enable" | Out-Null
        cmd /c "auditpol /set /subcategory:`"Special Logon`" /success:enable /failure:enable" | Out-Null
        cmd /c "auditpol /set /subcategory:`"Other Logon/Logoff Events`" /success:enable /failure:enable" | Out-Null
        cmd /c "auditpol /set /subcategory:`"Credential Validation`" /success:enable /failure:enable" | Out-Null

        Write-Output "   [+] Windows Audit Policy configured successfully:"
        Write-Output "       - Logon (Success & Failure)             : ENABLED"
        Write-Output "       - Account Lockout (Success & Failure)   : ENABLED"
        Write-Output "       - Credential Validation                 : ENABLED"
        Write-Output ""
        Write-Output "   Every login attempt (correct or wrong password, local or network) will now be logged!"
    } catch {
        Write-Output "   [-] Failed to configure audit policies: $($_.Exception.Message)"
    }
}

function Start-LiveLogonMonitor {
    Write-Output ""
    Write-Output "   +-------------------------------------------------------------------------------------------------+"
    Write-Output "   |                      Real-Time Live Logon & Intrusion Monitor                                   |"
    Write-Output "   +-------------------------------------------------------------------------------------------------+"
    Write-Output "   Monitoring Security log for new logon attempts..."
    Write-Output "   Press [Ctrl+C] to stop monitoring and return to menu."
    Write-Output ""

    $lastCheck = Get-Date

    while ($true) {
        Start-Sleep -Seconds 2
        try {
            $newEvents = @(Get-WinEvent -FilterHashtable @{
                LogName   = 'Security'
                Id        = @(4625, 4624, 4740)
                StartTime = $lastCheck
            } -ErrorAction SilentlyContinue)

            $lastCheck = Get-Date

            foreach ($e in $newEvents) {
                [xml]$xml = $e.ToXml()
                $map = @{}
                foreach ($d in $xml.Event.EventData.Data) {
                    if ($d.Name) { $map[$d.Name] = "$($d.'#text')".Trim() }
                }

                $timeStr = $e.TimeCreated.ToString("HH:mm:ss")
                $user = $map['TargetUserName']

                if ($e.Id -eq 4625) {
                    $ip = $map['IpAddress']
                    $type = Translate-LogonType -TypeNum $map['LogonType']
                    $reason = Translate-FailureStatus -Status $map['Status'] -SubStatus $map['SubStatus']
                    [console]::Beep(1000, 300)
                    Write-Output ("   [FAILED ATTEMPT] {0} | User: {1} | IP: {2} | Type: {3} | {4}" -f $timeStr, $user, $ip, $type, $reason)
                } elseif ($e.Id -eq 4740) {
                    [console]::Beep(1200, 400)
                    Write-Output ("   [ACCOUNT LOCKED] {0} | Account: {1} was LOCKED OUT due to failed attempts!" -f $timeStr, $user)
                } elseif ($e.Id -eq 4624) {
                    if ($user -and $user -notmatch '^(SYSTEM|LOCAL SERVICE|NETWORK SERVICE|ANONYMOUS LOGON|\$.*)$') {
                        $ip = $map['IpAddress']
                        $type = Translate-LogonType -TypeNum $map['LogonType']
                        Write-Output ("   [SUCCESS LOGON]  {0} | User: {1} | IP: {2} | Type: {3}" -f $timeStr, $user, $ip, $type)
                    }
                }
            }
        } catch {}
    }
}

# ------------------------------------------------------------
# Interactive Menu Flow
# ------------------------------------------------------------
function Show-LogonAuditMenu {
    while ($true) {
        Clear-Host
        Write-Output ""
        Write-Output "   +-------------------------------------------------------------------------------------------------+"
        Write-Output "   |                             Logon & Intrusion Audit Dashboard                                   |"
        Write-Output "   +-------------------------------------------------------------------------------------------------+"
        Write-Output "   |                                                                                                 |"
        Write-Output "   |   [1]  Check Failed Logon Attempts (Event ID 4625 - Wrong Passwords & Probes)                  |"
        Write-Output "   |   [2]  Check Active Logged-In Sessions (Who is on this PC right now - Console, RDP, SMB)       |"
        Write-Output "   |   [3]  Check Recent Successful User Logons (Event ID 4624 - Interactive & Network)              |"
        Write-Output "   |   [4]  Check Account Lockouts (Event ID 4740 - Repeated Failed Logins)                          |"
        Write-Output "   |   [5]  Check & Enable Windows Logon Auditing (Turn ON Failure Logging)                         |"
        Write-Output "   |   [6]  Launch Real-Time Live Logon Monitor (Watch for incoming login attempts)                 |"
        Write-Output "   |   [0]  Return to Security Menu                                                                  |"
        Write-Output "   |                                                                                                 |"
        Write-Output "   +-------------------------------------------------------------------------------------------------+"
        Write-Output ""

        $c = Read-Host "    Select option"

        switch ($c) {
            "1" { Show-FailedLogons; Read-Host "`n   Press Enter to continue" }
            "2" { Show-ActiveSessions; Read-Host "`n   Press Enter to continue" }
            "3" { Show-SuccessfulLogons; Read-Host "`n   Press Enter to continue" }
            "4" { Show-AccountLockouts; Read-Host "`n   Press Enter to continue" }
            "5" { Enable-LogonAuditing; Read-Host "`n   Press Enter to continue" }
            "6" { Start-LiveLogonMonitor }
            "0" { return }
            default { }
        }
    }
}

if ($MyInvocation.InvocationName -ne '.') {
    Show-LogonAuditMenu
}
