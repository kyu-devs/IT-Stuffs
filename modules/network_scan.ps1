param([int]$InterfaceIndex=0)
. (Join-Path $PSScriptRoot 'common.ps1')

if (-not $InterfaceIndex) {
    $InterfaceIndex=(Get-NetIPConfiguration -ErrorAction Stop |
        Where-Object { $_.IPv4DefaultGateway } | Select-Object -First 1).InterfaceIndex
}
$configuration=Get-NetIPAddress -AddressFamily IPv4 -InterfaceIndex $InterfaceIndex -ErrorAction Stop |
    Where-Object { $_.IPAddress -notlike '169.254.*' -and $_.IPAddress -ne '127.0.0.1' } |
    Select-Object -First 1
if (-not $configuration) { throw 'No usable IPv4 interface. Select an InterfaceIndex explicitly.' }
$localIP=$configuration.IPAddress
$range=Get-KyuIPv4Targets -IPAddress $localIP -PrefixLength $configuration.PrefixLength
$targets=@($range.Targets)
Write-Host "Local address: $localIP/$($configuration.PrefixLength); interface $InterfaceIndex"
if ($range.Limited) { Write-Warning 'Large subnet: this scan covers only the local /24 window, not the entire configured network.' }
Write-Host 'Discovering neighbors; blocked ICMP or management queries can leave devices/identities unverified.'
$pool=[Management.Automation.Runspaces.RunspaceFactory]::CreateRunspacePool(1,24)
$jobs=@(); $responsive=@()
try {
    $pool.Open()
    foreach ($target in $targets) {
        $worker=[powershell]::Create(); $worker.RunspacePool=$pool
        [void]$worker.AddScript({
            param($address)
            $ping=[Net.NetworkInformation.Ping]::new()
            try { if ($ping.Send($address,500).Status -eq 'Success') { $address } }
            catch {} finally { $ping.Dispose() }
        }).AddArgument($target)
        $jobs += [pscustomobject]@{PS=$worker;Handle=$worker.BeginInvoke()}
    }
    foreach ($job in $jobs) {
        try { $responsive += @($job.PS.EndInvoke($job.Handle)) }
        finally { $job.PS.Dispose() }
    }
} finally {
    foreach ($job in $jobs) { $job.PS.Dispose() }
    $pool.Close(); $pool.Dispose()
}
$neighbors=@(Get-NetNeighbor -InterfaceIndex $InterfaceIndex -AddressFamily IPv4 -ErrorAction Stop |
    Where-Object { $_.State -notin @('Unreachable','Incomplete') -and $_.IPAddress -in $targets } |
    Select-Object -ExpandProperty IPAddress)
$ips=@($responsive+$neighbors | Where-Object { $_ -and $_ -ne $localIP } | Select-Object -Unique)
# Existing management-query implementations are retained below. Authentication
# and firewall restrictions can prevent identity resolution; no policy is bypassed.
function Get-ViaWMI($ip) {
    $r = @{ Name = $null; User = $null }
    try {
        $cs = Get-WmiObject -ComputerName $ip -Class Win32_ComputerSystem `
                            -ErrorAction Stop -WarningAction SilentlyContinue
        if ($cs.Name) { $r.Name = $cs.Name }
        if ($cs.UserName) { $r.User = $cs.UserName }
    } catch {}

    # explorer.exe owner = most reliable "who is logged in" via WMI
    if (-not $r.User) {
        try {
            $proc = Get-WmiObject Win32_Process -ComputerName $ip `
                                  -Filter "Name='explorer.exe'" `
                                  -ErrorAction Stop -WarningAction SilentlyContinue |
                    Select-Object -First 1
            if ($proc) {
                $o = $proc.GetOwner()
                if ($o.User) {
                    $r.User = if ($o.Domain -and $o.Domain -ne $o.User) {
                        "$($o.Domain)\$($o.User)"
                    } else { $o.User }
                }
            }
        } catch {}
    }
    return $r
}

# ============================================================
#  QUERY METHOD 2 — CIM via WinRM (port 5985)
# ============================================================
function Get-ViaCIM($ip) {
    $r = @{ Name = $null; User = $null }
    try {
        $c = Get-CimInstance -ComputerName $ip -ClassName Win32_ComputerSystem `
                             -OperationTimeoutSec 3 -ErrorAction Stop
        if ($c.Name)     { $r.Name = $c.Name }
        if ($c.UserName) { $r.User = $c.UserName }
    } catch {}
    return $r
}

# ============================================================
#  QUERY METHOD 3 — Remote Registry via SMB (port 445)
#  Works when DCOM/WMI is firewall-blocked but file sharing
#  is open (almost always the case on a LAN).
#  Gets: Computer Name + Currently Logged-In User (loaded profile SID)
# ============================================================
function Get-ViaRemoteRegistry($ip) {
    $r = @{ Name = $null; User = $null }
    try {
        $reg = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey(
            [Microsoft.Win32.RegistryHive]::LocalMachine, $ip,
            [Microsoft.Win32.RegistryView]::Default)

        # -- Computer Name
        try {
            $k = $reg.OpenSubKey('SYSTEM\CurrentControlSet\Control\ComputerName\ActiveComputerName')
            if ($k) { $r.Name = $k.GetValue('ComputerName'); $k.Close() }
        } catch {}

        # -- Currently logged-in user: find loaded profile (State & 0x100 = loaded)
        #    Each subkey is a SID; a loaded profile = active session = someone is logged in
        try {
            $profileList = $reg.OpenSubKey('SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList')
            if ($profileList) {
                foreach ($sid in $profileList.GetSubKeyNames()) {
                    # Skip system accounts (S-1-5-18, S-1-5-19, S-1-5-20)
                    if ($sid -match '^S-1-5-(18|19|20)$') { continue }
                    $pk = $profileList.OpenSubKey($sid)
                    if ($pk) {
                        $state = $pk.GetValue('State')
                        # Bit 8 (0x100) set = profile is loaded = user is logged in
                        if ($state -ne $null -and ($state -band 0x100)) {
                            try {
                                $sidObj = New-Object System.Security.Principal.SecurityIdentifier($sid)
                                $account = $sidObj.Translate([System.Security.Principal.NTAccount]).Value
                                if ($account) { $r.User = $account; $pk.Close(); break }
                            } catch {}
                        }
                        $pk.Close()
                    }
                }
                $profileList.Close()
            }
        } catch {}

        # -- Fallback user: LogonUI last logged on (if no loaded profile found)
        if (-not $r.User) {
            try {
                $k = $reg.OpenSubKey('SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI')
                if ($k) {
                    $u = $k.GetValue('LastLoggedOnSAMUser')
                    if (-not $u) { $u = $k.GetValue('LastLoggedOnUser') }
                    if ($u)      { $r.User = "$u (last login)" }
                    $k.Close()
                }
            } catch {}
        }

        $reg.Close()
    } catch {}
    return $r
}

# ============================================================
#  QUERY METHOD 4 — Direct NBNS UDP Packet (port 137)
#  Crafts a raw NetBIOS Name Service node-status request.
#  No authentication required. Works across most LAN setups.
#  Gets: Computer Name + Logged-In Username (type 0x03 UNIQUE)
# ============================================================
function Get-ViaNBNS($ip) {
    $r = @{ Name = $null; User = $null }
    try {
        $udp = New-Object System.Net.Sockets.UdpClient
        $udp.Client.ReceiveTimeout = 1500
        [void]$udp.Connect($ip, 137)

        # NBNS Node Status Request
        # Wildcard name "*" encoded: 0x43,0x4B + 14x(0x43,0x41) + 0x41,0x41
        $encodedWild = [byte[]](
            @(0x43,0x4B) +           # '*' encoded
            (@(0x43,0x41) * 14) +    # 14 spaces encoded
            @(0x41,0x41)             # type byte 0x00 encoded
        )
        $pkt = [byte[]](
            @(0xA4,0x81, 0x00,0x00, 0x00,0x01, 0x00,0x00, 0x00,0x00, 0x00,0x00) + # header
            @(0x20) + $encodedWild + @(0x00) +                                      # question name
            @(0x00,0x21, 0x00,0x01)                                                 # QTYPE NBSTAT, QCLASS IN
        )
        [void]$udp.Send($pkt, $pkt.Length)
        $ep   = New-Object System.Net.IPEndPoint([System.Net.IPAddress]::Any, 0)
        $resp = $udp.Receive([ref]$ep)
        $udp.Close()

        # Determine where RDATA begins (handle name compression or full name in response)
        $dataOffset = if ($resp[12] -eq 0xC0) { 12 + 2 + 10 } else { 12 + 34 + 10 }
        # dataOffset now points to RDLength; skip 2 bytes to reach the name count
        $numNames = $resp[$dataOffset + 2]
        $namesStart = $dataOffset + 3

        for ($i = 0; $i -lt $numNames; $i++) {
            $base     = $namesStart + ($i * 18)
            if ($base + 17 -ge $resp.Length) { break }

            $rawName  = [System.Text.Encoding]::ASCII.GetString($resp[$base..($base+14)]).TrimEnd(' ', [char]0x00)
            $nameType = $resp[$base + 15]
            $flags    = ($resp[$base+16] -shl 8) -bor $resp[$base+17]
            $isGroup  = ($flags -band 0x8000) -ne 0

            # Type 0x00 UNIQUE = workstation/computer name
            if ($nameType -eq 0x00 -and -not $isGroup -and $rawName -and -not $r.Name) {
                $r.Name = $rawName
            }
            # Type 0x03 UNIQUE = messenger service = unverified messenger-name hint
            if ($nameType -eq 0x03 -and -not $isGroup -and $rawName -and -not $r.User) {
                $r.User = $rawName
            }
        }
    } catch {}
    return $r
}

# ============================================================
#  QUERY METHOD 5 — nbtstat -A (NetBIOS over TCP, port 137)
# ============================================================
function Get-ViaNbtstat($ip) {
    $r = @{ Name = $null; User = $null }
    try {
        $lines = & nbtstat -A $ip 2>&1
        foreach ($line in $lines) {
            if ($line -match '^\s*([A-Za-z0-9_\-]+)\s+<00>\s+UNIQUE') {
                if (-not $r.Name) { $r.Name = $Matches[1].Trim() }
            }
            if ($line -match '^\s*([A-Za-z0-9_\-]+)\s+<03>\s+UNIQUE') {
                if (-not $r.User) { $r.User = $Matches[1].Trim() }
            }
        }
    } catch {}
    return $r
}

# ============================================================
#  QUERY METHOD 6 — DNS Reverse Lookup (computer name only)
# ============================================================
function Get-ViaDNS($ip) {
    try {
        $e = [System.Net.Dns]::GetHostEntry($ip)
        if ($e.HostName) { return $e.HostName.Split('.')[0] }
    } catch {}
    return $null
}

# ============================================================
#  QUERY METHOD 7 — quser /server (logged-in user only)
# ============================================================
function Get-ViaQUser($ip) {
    try {
        $lines = & quser /server:$ip 2>&1
        $data  = $lines | Select-Object -Skip 1 | Select-Object -First 1
        if ($data -and "$data" -notmatch 'error|No User') {
            $u = if ($data.Length -ge 22) {
                     $data.Substring(0,22).Trim() -replace '^>',''
                 } else { $data.Trim() -replace '^>','' }
            if ($u) { return $u }
        }
    } catch {}
    return $null
}

# ============================================================
function Format-KyuIdentityObservation {
    param([string]$User,[string]$Source)
    if (-not $User) { return 'Unavailable (not verified)' }
    switch ($Source) {
        'Get-ViaRemoteRegistry' { return "$User (registry hint; unverified)" }
        'Get-ViaNBNS' { return "$User (NBNS hint; unverified)" }
        'Get-ViaNbtstat' { return "$User (NetBIOS hint; unverified)" }
        'Get-ViaQUser' { return "$User (quser report)" }
        'Get-ViaWMI' { return "$User (WMI report)" }
        'Get-ViaCIM' { return "$User (CIM report)" }
        default { return "$User (unverified)" }
    }
}
#  MAIN SCAN LOOP — merge results from all layers
# ============================================================
$sep = '  ' + ('-' * 16) + '  ' + ('-' * 28) + '  ' + ('-' * 28)
$hdr = '  {0,-16}  {1,-28}  {2,-28}' -f 'IP Address', 'Computer Name', 'User observation / source'
Write-Host $hdr -ForegroundColor Cyan
Write-Host $sep -ForegroundColor DarkGray

foreach ($ip in $ips) {
    $pcName = $null
    $user   = $null
    $identitySource = $null

    # Run each layer; stop early if we already have both values
    foreach ($fn in @('Get-ViaWMI','Get-ViaCIM','Get-ViaRemoteRegistry','Get-ViaNBNS','Get-ViaNbtstat')) {
        if ($pcName -and $user) { break }
        try {
            $res = & $fn $ip
            if (-not $pcName -and $res.Name) { $pcName = $res.Name }
            if (-not $user   -and $res.User) { $user = $res.User; $identitySource = $fn }
        } catch {}
    }

    # Single-value layers (name only / user only)
    if (-not $pcName) { $pcName = Get-ViaDNS   $ip }
    if (-not $user -or $identitySource -in @('Get-ViaRemoteRegistry','Get-ViaNBNS','Get-ViaNbtstat')) {
        $sessionUser = Get-ViaQUser $ip
        if ($sessionUser) { $user = $sessionUser; $identitySource = 'Get-ViaQUser' }
    }

    # Final fallbacks
    if (-not $pcName) { $pcName = 'Unknown' }
    $user = Format-KyuIdentityObservation -User $user -Source $identitySource

    $row = '  {0,-16}  {1,-28}  {2,-28}' -f $ip, $pcName, $user
    Write-Host $row -ForegroundColor Green
}

Write-Host $sep -ForegroundColor DarkGray
Write-Host ("  [*] Found {0} observed device(s) near {1}; discovery may be incomplete" -f $ips.Count, $localIP) -ForegroundColor Yellow
Write-Host ""
