# ============================================================
# KyuTools - Connect to a Shared Printer & Auto-Fixer
# All-green console output (color 0A)
# ============================================================

# Ensure SMB client signing and guest restrictions do not block local shares
try {
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters" -Name "RequireSecuritySignature" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters" -Name "AllowInsecureGuestAuth" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
    Set-SmbClientConfiguration -RequireSecuritySignature $false -EnableInsecureGuestLogons $true -Force -ErrorAction SilentlyContinue
} catch {}

function Get-NetworkSharedPrinters {
    $results = [System.Collections.Generic.List[PSCustomObject]]::new()
    $seenShare = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)

    # 1. Printers already mapped/connected on this PC
    try {
        $connPrinters = @(Get-Printer -ErrorAction SilentlyContinue | Where-Object { $_.Type -eq 'Connection' -or $_.Name -like '\\*' })
        foreach ($c in $connPrinters) {
            $cPath = $c.Name
            $clean = $cPath.TrimStart('\')
            $parts = $clean -split '\\'
            $h = if ($parts.Count -ge 2) { $parts[0] } else { 'Network' }
            $s = if ($parts.Count -ge 2) { $parts[1] } else { $clean }
            if ($s -and $seenShare.Add($s)) {
                $results.Add([PSCustomObject]@{
                    ShareName    = $s
                    PrinterName  = if ($c.DriverName) { $c.DriverName } else { $s }
                    Host         = $h
                    Path         = $cPath
                })
            }
        }
    } catch {}

    # 2. Gather candidate network computers and WSD printers
    $candidates = [System.Collections.Generic.List[string]]::new()
    $seenHosts = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    [void]$seenHosts.Add($env:COMPUTERNAME)

    # From Network neighborhood
    try {
        $shell = New-Object -ComObject Shell.Application
        $net = $shell.Namespace(18)
        if ($net) {
            foreach ($item in $net.Items()) {
                $n = "$($item.Name)".Trim()
                $p = "$($item.Path)".Trim()
                if (-not $n) { continue }

                # Check if this item is a WSD Network Printer device
                if ($p -like '*Microsoft.Networking.WSD*' -or $n -match 'Series|Printer|DCP|L1\d+|L3\d+|DeskJet|LaserJet') {
                    if ($seenShare.Add($n)) {
                        $model = if ($n -match '\((.+?)\)') { $matches[1] } else { $n }
                        $results.Add([PSCustomObject]@{
                            ShareName    = $n
                            PrinterName  = $model
                            Host         = 'Network (WSD)'
                            Path         = if ($p.StartsWith('\\')) { $p } else { $n }
                        })
                    }
                } elseif ($seenHosts.Add($n)) {
                    $candidates.Add($n)
                }
            }
        }
    } catch {}

    # From NetBIOS cache
    try {
        $nbt = nbtstat -r 2>$null | Select-String '<\d+>' | ForEach-Object {
            $parts = $_.ToString().Trim() -split '\s+'
            if ($parts.Count -ge 1 -and $parts[0] -match '^[A-Za-z0-9\-_]+$') {
                $parts[0]
            }
        }
        foreach ($nbHost in $nbt) {
            if ($nbHost -and $seenHosts.Add($nbHost)) {
                $candidates.Add($nbHost)
            }
        }
    } catch {}

    # From ARP table
    try {
        $arpLines = @(arp -a | Select-String 'dynamic' | ForEach-Object {
            $p = $_.ToString().Trim() -split '\s+'
            if ($p.Count -ge 2 -and $p[0] -match '^\d+\.\d+\.\d+\.\d+$' -and $p[0] -notmatch '\.1$|\.255$') {
                $p[0]
            }
        })

        foreach ($ip in $arpLines) {
            if ($seenHosts.Add($ip)) {
                $candidates.Add($ip)
            }
        }
    } catch {}

    # 4. Probe candidate hosts for shared printers
    $activeOnlineHosts = [System.Collections.Generic.List[string]]::new()
    foreach ($h in $candidates) {
        if ($h -match 'router|gateway|archer' -or $h -match '\.1$') { continue }

        # Quick TCP port 445 check (50ms timeout)
        $isOpen = $false
        try {
            $tcp = New-Object System.Net.Sockets.TcpClient
            $async = $tcp.BeginConnect($h, 445, $null, $null)
            if ($async.AsyncWaitHandle.WaitOne(50)) { $isOpen = $true }
            $tcp.Close()
        } catch {}

        if (-not $isOpen) {
            # Try NetBIOS session port 139 (50ms timeout)
            try {
                $tcp139 = New-Object System.Net.Sockets.TcpClient
                $async139 = $tcp139.BeginConnect($h, 139, $null, $null)
                if ($async139.AsyncWaitHandle.WaitOne(50)) { $isOpen = $true }
                $tcp139.Close()
            } catch {}
        }

        if ($isOpen) {
            $activeOnlineHosts.Add($h)
        }
    }

    # Query shares on active online hosts
    $protectedHosts = [System.Collections.Generic.List[string]]::new()
    foreach ($h in $activeOnlineHosts) {
        try {
            $rawNv = (cmd /c "net view \\$h 2>&1") | Out-String

            # Check if host has password-protected sharing enabled
            if ($rawNv -match 'System error 5|Access is denied') {
                if (-not $protectedHosts.Contains($h)) {
                    $protectedHosts.Add($h)
                }
                continue
            }

            $foundHost = $h
            if ($rawNv -match 'Shared resources at \\\\([^\r\n\s]+)') {
                $foundHost = $matches[1].Trim()
            }

            $printLines = $rawNv -split '\r?\n' | Select-String '\s{2,}Print\s*'
            foreach ($line in $printLines) {
                $raw = $line.ToString().Trim()
                $splitParts = $raw -split '\s{2,}Print\s*'
                if ($splitParts.Count -ge 1) {
                    $sName = $splitParts[0].Trim()
                    $model = if ($splitParts.Count -ge 2 -and $splitParts[1].Trim()) { $splitParts[1].Trim() } else { $sName }
                    $key = "\\$foundHost\$sName"
                    if ($sName -and $seenShare.Add($sName)) {
                        $results.Add([PSCustomObject]@{
                            ShareName    = $sName
                            PrinterName  = $model
                            Host         = $foundHost
                            Path         = $key
                        })
                    }
                }
            }
        } catch {}
    }

    return [PSCustomObject]@{
        Printers       = @($results)
        OnlineHosts    = @($activeOnlineHosts)
        ProtectedHosts = @($protectedHosts)
    }
}

function Clear-DriverSpoolCache {
    Write-Output "   [*] Stopping Print Spooler service..."
    Stop-Service -Name "Spooler" -Force -ErrorAction SilentlyContinue

    $spoolPrinters = "$env:SystemRoot\System32\spool\PRINTERS"
    if (Test-Path $spoolPrinters) {
        Get-ChildItem -Path $spoolPrinters -Force -ErrorAction SilentlyContinue | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
    }

    $pcc = "$env:SystemRoot\System32\spool\drivers\x64\PCC"
    if (Test-Path $pcc) {
        Get-ChildItem -Path $pcc -Force -ErrorAction SilentlyContinue | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
    }

    Write-Output "   [*] Starting Print Spooler service..."
    Start-Service -Name "Spooler" -ErrorAction SilentlyContinue
    Write-Output "   [+] Print queue and Point & Print driver cache cleared successfully."
}

function Test-LocalPrinterDriver {
    param([string]$TargetName)

    $installed = @(Get-PrinterDriver -ErrorAction SilentlyContinue)
    if (-not $installed -or $installed.Count -eq 0) { return $null }

    # Clean target name to extract model
    $clean = $TargetName -replace '^\\\\.+?\\', ''

    # Check for direct match
    $exactMatch = $installed | Where-Object { $_.Name -like "*$clean*" } | Select-Object -First 1
    if ($exactMatch) { return $exactMatch }

    # Extract keywords (ignoring generic terms)
    $words = ($clean -split '[\s\-_]+') | Where-Object { 
        $_ -and $_.Length -ge 3 -and $_ -notmatch '^(Series|Printer|Color|Laser|Network|Shared|Print|Deskjet|Class)$' 
    }

    foreach ($w in $words) {
        $m = $installed | Where-Object { $_.Name -like "*$w*" } | Select-Object -First 1
        if ($m) { return $m }
    }

    return $null
}

function Show-DriverRepairAssistant {
    param([string]$TargetPath, [string]$PrinterName)

    Write-Output ""
    Write-Output "   +-------------------------------------------------------------------------------------------------+"
    Write-Output "   |                         Printer Driver Repair Assistant                                         |"
    Write-Output "   +-------------------------------------------------------------------------------------------------+"
    Write-Output "   Windows needs a driver for this printer to be installed or registered on this PC."
    Write-Output ""
    Write-Output "   [1] Open Windows Add Driver Wizard (Select driver from Windows Update / disk list)"
    Write-Output "   [2] Install Driver from an .INF file or folder (e.g., extracted driver package)"
    Write-Output "   [3] Clean & Reset Point & Print Driver Cache (Clears stuck files & restarts Spooler)"
    Write-Output "   [4] Open Print Server Properties (View & manage all installed drivers GUI)"
    Write-Output "   [0] Skip driver tools"
    Write-Output ""

    $drChoice = Read-Host "   Select driver action"

    if ($drChoice -eq '1') {
        Write-Output ""
        Write-Output "   [*] Launching Windows Add Printer Driver Wizard..."
        Write-Output "   [*] In the wizard: Select the Manufacturer and Printer Model (or click Windows Update)."
        Start-Process -FilePath "rundll32.exe" -ArgumentList "printui.dll,PrintUIEntry /id" -Wait
        Write-Output "   [+] Driver Wizard closed."
        return $true
    } elseif ($drChoice -eq '2') {
        Write-Output ""
        $infPath = Read-Host "   Enter path to driver .INF file or folder (e.g. C:\Drivers\Brother)"
        if (-not [string]::IsNullOrWhiteSpace($infPath)) {
            $resolved = $infPath.Trim().Trim('"')
            if (Test-Path $resolved) {
                Write-Output "   [*] Installing driver package via pnputil..."
                if ((Get-Item $resolved).PSIsContainer) {
                    cmd /c "pnputil /add-driver `"$resolved\*.inf`" /subdirs /install" | Out-Null
                } else {
                    cmd /c "pnputil /add-driver `"$resolved`" /install" | Out-Null
                }
                Write-Output "   [+] Driver package installation completed."
                return $true
            } else {
                Write-Output "   [-] Path '$resolved' not found."
            }
        }
    } elseif ($drChoice -eq '3') {
        Write-Output ""
        Clear-DriverSpoolCache
        return $true
    } elseif ($drChoice -eq '4') {
        Write-Output ""
        Write-Output "   [*] Opening Print Server Properties (Drivers tab)..."
        Start-Process -FilePath "rundll32.exe" -ArgumentList "printui.dll,PrintUIEntry /s /t2"
    }

    return $false
}

function Apply-PrinterFixes {
    # 1. Network Profile to Private
    try {
        Get-NetConnectionProfile | Set-NetConnectionProfile -NetworkCategory Private -ErrorAction SilentlyContinue
        Write-Output "   [1/6] Set network profile to Private."
    } catch {}

    # 2. Firewall rules
    try {
        netsh advfirewall firewall set rule group="File and Printer Sharing" new enable=Yes >$null 2>&1
        netsh advfirewall firewall set rule group="Network Discovery" new enable=Yes >$null 2>&1
        Write-Output "   [2/6] Enabled File and Printer Sharing in Windows Firewall."
    } catch {}

    # 3. RPC & Point and Print registry overrides (Unblocks remote driver download)
    try {
        Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Print" -Name "RpcAuthnLevelPrivacyEnabled" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue

        $pap = "HKLM:\Software\Policies\Microsoft\Windows NT\Printers\PointAndPrint"
        if (-not (Test-Path $pap)) { New-Item -Path $pap -Force | Out-Null }
        Set-ItemProperty -Path $pap -Name "RestrictDriverInstallationToAdministrators" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
        Set-ItemProperty -Path $pap -Name "UpdatePromptSettings" -Value 2 -Type DWord -Force -ErrorAction SilentlyContinue
        Set-ItemProperty -Path $pap -Name "Restricted" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
        Set-ItemProperty -Path $pap -Name "InForest" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
        Set-ItemProperty -Path $pap -Name "TrustedServers" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
        Set-ItemProperty -Path $pap -Name "PackageAwareNoWarn" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue

        $prnPol = "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Printers"
        if (-not (Test-Path $prnPol)) { New-Item -Path $prnPol -Force | Out-Null }
        Set-ItemProperty -Path $prnPol -Name "CopyFilesPolicy" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue

        $rpc = "HKLM:\Software\Policies\Microsoft\Windows NT\Printers\RPC"
        if (-not (Test-Path $rpc)) { New-Item -Path $rpc -Force | Out-Null }
        Set-ItemProperty -Path $rpc -Name "RpcUseNamedPipeProtocol" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
        Set-ItemProperty -Path $rpc -Name "RpcProtocols" -Value 7 -Type DWord -Force -ErrorAction SilentlyContinue
        Set-ItemProperty -Path $rpc -Name "ForceKerberosForRpc" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
        Write-Output "   [3/6] Applied Point-and-Print driver download and RPC security policies."
    } catch {}

    # 4. SMB Signing and Guest Authentication Policies (Windows 11 Fix)
    try {
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters" -Name "RequireSecuritySignature" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters" -Name "EnableSecuritySignature" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters" -Name "AllowInsecureGuestAuth" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue

        $lmPol = "HKLM:\Software\Policies\Microsoft\Windows\LanmanWorkstation"
        if (-not (Test-Path $lmPol)) { New-Item -Path $lmPol -Force | Out-Null }
        Set-ItemProperty -Path $lmPol -Name "RequireSecuritySignature" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
        Set-ItemProperty -Path $lmPol -Name "AllowInsecureGuestAuth" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue

        Set-SmbClientConfiguration -RequireSecuritySignature $false -EnableInsecureGuestLogons $true -Force -ErrorAction SilentlyContinue
        Write-Output "   [4/6] Configured SMB client signing & guest policies (Windows 11 fix)."
    } catch {}

    # 5. Services
    try {
        sc config FDResPub start= auto >$null 2>&1
        net start FDResPub >$null 2>&1
        sc config LanmanServer start= auto >$null 2>&1
        net start LanmanServer >$null 2>&1
        Write-Output "   [5/6] Started Discovery and Server services."
    } catch {}

    # 6. Spooler restart & cache clear
    try {
        Stop-Service -Name "Spooler" -Force -ErrorAction SilentlyContinue
        $spoolDir = "$env:SystemRoot\System32\spool\PRINTERS"
        if (Test-Path $spoolDir) {
            Get-ChildItem -Path $spoolDir -File -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
        }
        $pcc = "$env:SystemRoot\System32\spool\drivers\x64\PCC"
        if (Test-Path $pcc) {
            Get-ChildItem -Path $pcc -Force -ErrorAction SilentlyContinue | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
        }
        Start-Service -Name "Spooler" -ErrorAction SilentlyContinue
        Write-Output "   [6/6] Purged stuck print queue, cleaned driver cache, and restarted Print Spooler."
    } catch {}
}

function Format-PrinterError {
    param([string]$RawError)

    $cleanErr = [PSCustomObject]@{
        Title         = ""
        Explanation   = ""
        Category      = "General"
        IsDriverError = $false
    }

    if ($RawError -match '0x0000007E|0x8007007E|126|module could not be found') {
        $cleanErr.Title         = "Printer Driver Module Missing (Error 0x0000007E)"
        $cleanErr.Explanation   = "This PC does not have the required driver files installed, and Windows could not load the driver module."
        $cleanErr.Category      = "Driver"
        $cleanErr.IsDriverError = $true
    } elseif ($RawError -match '0x00000BCB|0x80070BCB|3019|Point and Print') {
        $cleanErr.Title         = "Point & Print Driver Download Blocked (Error 0x00000BCB)"
        $cleanErr.Explanation   = "Windows security policy (PrintNightmare) prevented downloading the printer driver from the Host PC."
        $cleanErr.Category      = "Driver"
        $cleanErr.IsDriverError = $true
    } elseif ($RawError -match '0x00000002|0x80070002|cannot find the file specified') {
        $cleanErr.Title         = "Printer Driver File Missing (Error 0x00000002)"
        $cleanErr.Explanation   = "A required printer driver file or configuration (.inf) is missing from the system driver store."
        $cleanErr.Category      = "Driver"
        $cleanErr.IsDriverError = $true
    } elseif ($RawError -match '0x00000057|0x80070057|parameter is incorrect') {
        $cleanErr.Title         = "Printer Driver Mismatch or Invalid Parameter (Error 0x00000057)"
        $cleanErr.Explanation   = "The driver provided by the Host PC does not match this PC's architecture (e.g., 64-bit vs 32-bit) or is incompatible."
        $cleanErr.Category      = "Driver"
        $cleanErr.IsDriverError = $true
    } elseif ($RawError -match '0x00000BB9|3001|0x000003E6|currently in use|invalid access to memory') {
        $cleanErr.Title         = "Printer Driver Cache Corrupted or Locked (Error 0x00000BB9)"
        $cleanErr.Explanation   = "The printer driver files are locked or corrupted in the Print Spooler cache from a previous attempt."
        $cleanErr.Category      = "Driver"
        $cleanErr.IsDriverError = $true
    } elseif ($RawError -match 'driver is required|no driver found|cannot find a driver|suitable driver|driver installation failed') {
        $cleanErr.Title         = "Printer Driver Required"
        $cleanErr.Explanation   = "Windows requires a driver for this printer model, but none was found locally or provided by the host."
        $cleanErr.Category      = "Driver"
        $cleanErr.IsDriverError = $true
    } elseif ($RawError -match '0x000003E3|995|Operation Aborted') {
        $cleanErr.Title         = "Print Spooler RPC Communication Failed (Error 0x000003E3)"
        $cleanErr.Explanation   = "Windows Print Spooler could not establish an RPC channel with the remote computer."
        $cleanErr.Category      = "RPC"
    } elseif ($RawError -match '0x0000011B|283') {
        $cleanErr.Title         = "RPC Authentication Level Mismatch (Error 0x0000011B)"
        $cleanErr.Explanation   = "Windows security update requires RPC authentication encryption between computers."
        $cleanErr.Category      = "RPC"
    } elseif ($RawError -match '0x00000709|1801|invalid printer name') {
        $cleanErr.Title         = "Invalid Printer Share Name (Error 0x00000709)"
        $cleanErr.Explanation   = "The printer share name was not recognized or the Print Spooler default binding failed."
        $cleanErr.Category      = "Share"
    } elseif ($RawError -match '0x80070005|Access is denied|AccessDenied') {
        $cleanErr.Title         = "Access Denied by Host Computer (Error 5)"
        $cleanErr.Explanation   = "The Host PC rejected the connection. Network sharing permissions or passwords are required."
        $cleanErr.Category      = "Access"
    } elseif ($RawError -match '0x8007052E|1326|logon failure|user name or password') {
        $cleanErr.Title         = "Network Authentication Required (Error 1326)"
        $cleanErr.Explanation   = "The Host PC has Password-Protected Sharing enabled and requires a Windows user account to connect."
        $cleanErr.Category      = "Auth"
    } elseif ($RawError -match '0x80070003|0x80070035|53|network path was not found|path not found') {
        $cleanErr.Title         = "Network Path Not Found (Error 53)"
        $cleanErr.Explanation   = "Unable to reach the Host PC over the network or SMB communication was blocked."
        $cleanErr.Category      = "Network"
    } elseif ($RawError -match '0x800706BA|1722|RPC server is unavailable') {
        $cleanErr.Title         = "RPC Server Unavailable (Error 1722)"
        $cleanErr.Explanation   = "The Print Spooler service on the Host PC is stopped or network ports are blocked by Windows Firewall."
        $cleanErr.Category      = "Network"
    } elseif ($RawError -match 'SMB signing|0xC05D0003|RequireSecuritySignature') {
        $cleanErr.Title         = "SMB Signing Policy Conflict"
        $cleanErr.Explanation   = "Windows 11 client SMB signing policy blocked communication with the Host PC."
        $cleanErr.Category      = "SMB"
    } elseif ($RawError -match '0x800706BE|1726|RPC failed') {
        $cleanErr.Title         = "Print Spooler Service Crashed or Stopped (Error 1726)"
        $cleanErr.Explanation   = "The local or remote Print Spooler terminated unexpectedly and needs to be restarted."
        $cleanErr.Category      = "Spooler"
    } else {
        $cleanErr.Title         = "Printer Connection Error"
        $cleanErr.Explanation   = $RawError
        if ($RawError -match 'driver') {
            $cleanErr.IsDriverError = $true
            $cleanErr.Category      = "Driver"
        }
    }

    return $cleanErr
}

function Connect-PrinterTarget {
    param([string]$TargetPath)

    $connected = $false
    $errResult = $null

    # Method 1: Add-Printer cmdlet
    try {
        Add-Printer -ConnectionName $TargetPath -ErrorAction Stop
        $connected = $true
    } catch {
        $errResult = $_.Exception.Message
    }

    # Method 2: WScript.Network COM object
    if (-not $connected) {
        try {
            $wshNet = New-Object -ComObject WScript.Network
            $wshNet.AddWindowsPrinterConnection($TargetPath)
            $connected = $true
            $errResult = $null
        } catch {
            $errResult = $_.Exception.Message
        }
    }

    # Method 3: rundll32 printui.dll (triggers native Point & Print driver download)
    if (-not $connected) {
        try {
            $proc = Start-Process -FilePath "rundll32.exe" -ArgumentList "printui.dll,PrintUIEntry /in /n`"$TargetPath`"" -Wait -PassThru
            Start-Sleep -Milliseconds 800
            $chk = Get-Printer -ErrorAction SilentlyContinue | Where-Object { $_.Name -eq $TargetPath -or $_.Name -like "*$TargetPath*" }
            if ($chk) {
                $connected = $true
                $errResult = $null
            }
        } catch {}
    }

    # Verify printer presence in Windows (NO physical paper test print)
    Start-Sleep -Milliseconds 400
    $prn = Get-Printer -ErrorAction SilentlyContinue | Where-Object { 
        $_.Name -eq $TargetPath -or $_.Name -like "*$TargetPath*" 
    } | Select-Object -First 1

    if ($prn) {
        # Successfully connected!
        return $null
    }

    if (-not $errResult) {
        $errResult = "Unable to connect to printer at '$TargetPath'."
    }

    return $errResult
}

# ------------------------------------------------------------
# Main Flow
# ------------------------------------------------------------
if ($MyInvocation.InvocationName -ne '.') {
    Write-Output ""
    Write-Output "   [*] Scanning for available shared printers on the network..."

    $discovery = Get-NetworkSharedPrinters
    $sharedList = @($discovery.Printers)
    $onlineHosts = @($discovery.OnlineHosts)
    $protectedHosts = @($discovery.ProtectedHosts)

    Write-Output ""
    if ($sharedList.Count -gt 0) {
        Write-Output "   Available Shared Printers on the Network:"
        Write-Output "   -------------------------------------------------------------------------------------------------"
        Write-Output ("   {0,-4} {1,-28} {2,-36} {3,-20}" -f "#", "Share Name", "Printer Name / Model", "Host PC")
        Write-Output "   -------------------------------------------------------------------------------------------------"
        for ($i = 0; $i -lt $sharedList.Count; $i++) {
            $item = $sharedList[$i]
            Write-Output ("   [{0}]  {1,-28} {2,-36} {3,-20}" -f ($i + 1), $item.ShareName, $item.PrinterName, $item.Host)
        }
        Write-Output "   -------------------------------------------------------------------------------------------------"
    } else {
        Write-Output "   [i] No open shared printers are currently broadcasting on the network."
    }

    if ($protectedHosts.Count -gt 0) {
        Write-Output ""
        Write-Output "   Online PCs with Protected Sharing Detected (Password Protection is ON):"
        foreach ($ph in $protectedHosts) {
            Write-Output "   - $ph"
        }
        Write-Output "   (Printers on these PCs require typing their Share Name or logging in)."
    }
    Write-Output ""

    $inputShare = Read-Host "   Type the Share Name (or # number) of the printer to connect"
    if ([string]::IsNullOrWhiteSpace($inputShare)) {
        exit 0
    }

    $trimmedInput = $inputShare.Trim()
    $targetPath = ""

    # Check if user typed a number [1], [2], etc.
    $num = 0
    if ([int]::TryParse($trimmedInput, [ref]$num) -and $num -ge 1 -and $num -le $sharedList.Count) {
        $targetPath = $sharedList[$num - 1].Path
    } else {
        # Check if user entered a full UNC path like \\Host\Share
        if ($trimmedInput -match '^\\\\([^\\]+)\\(.+)$') {
            $targetPath = $trimmedInput
        } else {
            # Match against discovered list
            $matched = $sharedList | Where-Object { $_.ShareName -ieq $trimmedInput } | Select-Object -First 1
            if ($matched) {
                $targetPath = $matched.Path
            } else {
                # Probe online hosts to check if this share exists
                Write-Output "   [*] Locating host PC for '$trimmedInput'..."
                foreach ($h in $onlineHosts) {
                    $checkNv = (cmd /c "net view \\$h 2>&1") | Out-String
                    if ($checkNv -like "*$trimmedInput*") {
                        $targetPath = "\\$h\$trimmedInput"
                        break
                    }
                }

                # If still ambiguous, prompt user for the Host PC
                if (-not $targetPath) {
                    Write-Output ""
                    $hostInput = Read-Host "   Type the Host PC name or IP where this printer is connected"
                    if (-not [string]::IsNullOrWhiteSpace($hostInput)) {
                        $targetPath = "\\$($hostInput.Trim())\$trimmedInput"
                    } else {
                        Write-Output "   [!] Connection cancelled."
                        exit 0
                    }
                }
            }
        }
    }

    # Driver Pre-Check on this client PC
    $localDrv = Test-LocalPrinterDriver -TargetName $targetPath
    if ($localDrv) {
        Write-Output "   [+] Local driver match detected: '$($localDrv.Name)'"
    } else {
        Write-Output "   [*] No local driver currently installed for this model."
        Write-Output "   [*] Windows will attempt automatic Point & Print driver download from host."
    }

    Write-Output "   [*] Connecting to '$targetPath'..."

    # Check if host requires credentials before connection
    if ($targetPath -match '^\\\\([^\\]+)\\') {
        $remoteHost = $matches[1]
        $testAccess = (cmd /c "net view \\$remoteHost 2>&1") | Out-String
        if ($testAccess -match 'System error 5|Access is denied') {
            Write-Output ""
            Write-Output "   [!] '$remoteHost' has Password Protected Sharing enabled."
            $u = Read-Host "   Enter Windows Username for $remoteHost (or press Enter if none)"
            if (-not [string]::IsNullOrWhiteSpace($u)) {
                $p = Read-Host "   Enter Windows Password for $remoteHost"
                cmd /c "net use \\$remoteHost /user:$u `"$p`" >nul 2>&1"
            }
        }
    }

    $errMessage = Connect-PrinterTarget -TargetPath $targetPath

    if (-not $errMessage) {
        Write-Output ""
        Write-Output "   [+] Successfully connected to '$targetPath'!"
        Write-Output "   [+] Ready to print without errors."
        Write-Output ""
        exit 0
    }

    # Error occurred: Display what the error is and suggest fix
    $parsedErr = Format-PrinterError -RawError $errMessage
    Write-Output ""
    Write-Output "   [-] Connection Error: $($parsedErr.Title)"
    Write-Output "   [-] Cause           : $($parsedErr.Explanation)"
    if ($errMessage -and $errMessage -ne $parsedErr.Title) {
        Write-Output "   [-] System Details  : $errMessage"
    }
    Write-Output ""
    Write-Output "   [*] Suggested Fix:"
    if ($parsedErr.IsDriverError) {
        Write-Output "       The printer driver is missing, corrupted, or blocked by Point & Print policies."
        Write-Output "       KyuTools can unblock driver policies, reset driver caches, or guide driver installation."
    } else {
        Write-Output "       KyuTools can automatically configure the required RPC policies,"
        Write-Output "       Point & Print rules, SMB signing, firewall, and restart the Print Spooler."
    }
    Write-Output ""
    $answer = Read-Host "   >> Do you want KyuTools to automatically fix this error now? (Y/N)"

    if ($answer -match '^[Yy]') {
        Write-Output ""
        Write-Output "   [*] Applying automatic repair..."
        Apply-PrinterFixes

        Write-Output "   [*] Retrying connection to '$targetPath'..."
        Start-Sleep -Milliseconds 800

        $retryErr = Connect-PrinterTarget -TargetPath $targetPath

        if (-not $retryErr) {
            Write-Output ""
            Write-Output "   [+] Error fixed automatically!"
            Write-Output "   [+] Successfully connected to '$targetPath'!"
            Write-Output "   [+] Printer is ready for use."
            Write-Output ""
            exit 0
        }

        $retryParsed = Format-PrinterError -RawError $retryErr
        Write-Output ""
        Write-Output "   [-] Retry Error: $($retryParsed.Title)"
        Write-Output "   [-] Cause      : $($retryParsed.Explanation)"

        # If it is a Driver Error, offer the Driver Repair Assistant
        if ($retryParsed.IsDriverError -or $parsedErr.IsDriverError) {
            $appliedDriver = Show-DriverRepairAssistant -TargetPath $targetPath -PrinterName $trimmedInput
            if ($appliedDriver) {
                Write-Output ""
                Write-Output "   [*] Re-attempting connection to '$targetPath' after driver action..."
                Start-Sleep -Milliseconds 800
                $finalErr = Connect-PrinterTarget -TargetPath $targetPath
                if (-not $finalErr) {
                    Write-Output ""
                    Write-Output "   [+] Successfully connected to '$targetPath'!"
                    Write-Output "   [+] Printer is ready for use."
                    Write-Output ""
                    exit 0
                } else {
                    $finalParsed = Format-PrinterError -RawError $finalErr
                    Write-Output ""
                    Write-Output "   [-] Still unable to connect: $($finalParsed.Title)"
                    Write-Output "   [-] Cause: $($finalParsed.Explanation)"
                }
            }
        } else {
            if ($targetPath -match '^\\\\([^\\]+)\\') {
                $rHost = $matches[1]
                Write-Output "   [-] Note: This PC has been repaired, but the Host PC ($rHost) may still be blocking sharing."
                Write-Output "   [!] Solution: Run KyuTools Option [1] on the Host PC ($rHost) to enable sharing."
            }
        }
        Write-Output ""
    } else {
        Write-Output "   [!] You can run Option [1] (Enable File and Printer Sharing) on the Host PC anytime."
        Write-Output ""
    }
}
