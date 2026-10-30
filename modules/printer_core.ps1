. (Join-Path $PSScriptRoot 'common.ps1')

function Resolve-KyuPrinterTarget {
    param([string]$Text, [object[]]$Printers = @())
    $value = $Text.Trim()
    $number = 0
    if ([int]::TryParse($value,[ref]$number)) {
        if ($number -lt 1 -or $number -gt $Printers.Count) { throw 'Select a printer number from the displayed list.' }
        $value = $Printers[$number-1].Path
    } elseif ($value -notlike '\\*') {
        $found = @($Printers | Where-Object { $_.ShareName -ieq $value })
        if ($found.Count -ne 1) { throw 'Enter the full \\HOST\SHARE path; this share name is missing or ambiguous.' }
        $value = $found[0].Path
    }
    if ($value -notmatch '^\\\\([^\\]+)\\([^\\/:*?"<>|\x00-\x1f]+)$') { throw 'Use a printer path in the form \\HOST\SHARE.' }
    if (-not (Test-KyuHostName $matches[1]) -or $matches[2] -match '[ .]$') { throw 'Invalid printer host or share name.' }
    return $value
}
function Format-PrinterError {
    param([string]$RawError)
    $category='General'; $title='Printer operation failed'
    $advice='Review the detailed error and PrintService logs; verify the exact printer name, driver, host, and network.'
    # Decode Win32 HRESULTs before testing decimal codes. Never substring-match
    # decimal codes (1260 is a policy error, not missing module 126).
    $code = 0
    if ($RawError -match '(?i)0x((?:8007|0000)[0-9a-f]{4})\b' -or $RawError -match '(?i)0x([0-9a-f]{8})\b') {
        $unsigned = [Convert]::ToUInt32($matches[1],16)
        $code = [int]($unsigned -band 0xffff)
    } elseif ($RawError -match '(?i)\b(?:error|code|win32)\s*[:=]?\s*(\d+)\b') { $code=[int]$matches[1] }
    switch ($code) {
        5    { $category='Access'; $advice='Use an account on the host with permission to print. Install the signed driver as administrator; do not disable Point and Print protections.' }
        53   { $category='Network'; $advice='Check host name resolution and TCP 445; confirm the host is awake and sharing on a trusted network.' }
        67   { $category='Share'; $advice='Verify the exact share name on the host and that the printer is still shared.' }
        87   { $category='Driver'; $advice='Check driver model, architecture, parameters, and Windows version.' }
        126  { $category='Driver'; $advice='Install or repair the signed manufacturer driver matching this Windows architecture.' }
        283  { $category='RPC'; $advice='Update both host and client, restart their spoolers if appropriate, and check printer RPC/firewall configuration. Retain RPC authentication privacy.' }
        995  { $category='RPC'; $advice='Check PrintService events and both spoolers; a service interruption or cancelled operation can abort RPC.' }
        1219 { $category='CredentialsConflict'; $advice='Windows already has a connection to this host using different credentials. Review net use and Credential Manager; disconnect only the conflicting connection after saving work.' }
        1260 { $category='Policy'; $advice='A device or driver policy blocks the operation. Ask the administrator to approve a supported signed driver or printer; do not bypass organization policy.' }
        1272 { $category='Authentication'; $advice='Guest access is blocked. Use a host account and a signing-capable server; retain SMB signing.' }
        1326 { $category='Authentication'; $advice='Use valid HOST\username or domain credentials with the account password, not a Windows Hello PIN.' }
        1722 { $category='RPC'; $advice='Verify the host spooler, RPC endpoint mapper TCP 135, dynamic RPC/firewall rules, and network reachability. TCP 445 alone does not prove printing works.' }
        1726 { $category='Spooler'; $advice='Check local and host spoolers and PrintService errors; repair or update a crashing driver.' }
        1797 { $category='Driver'; $advice='The printer driver is unknown. Install the exact signed model driver as administrator before reconnecting.' }
        1801 { $category='Share'; $advice='Verify the full printer UNC path and current share name on the host.' }
        1930 { $category='Driver'; $advice='The driver is incompatible or blocked. Obtain a current signed package for this architecture.' }
        3001 { $category='DriverInUse'; $advice='The driver is currently in use. Close printer applications and inspect dependent queues before attempting removal. Do not delete the driver cache.' }
        3019 { $category='Driver'; $advice='A driver download or policy issue was reported. Install an approved signed driver as administrator on the client.' }
        default {
            if ($RawError -match '(?i)access.*denied') { $category='Access'; $advice='Check host account permissions and signed-driver installation rights.' }
            elseif ($RawError -match '(?i)driver|0x00000bcb') { $category='Driver'; $advice='Install an approved signed driver matching the printer model and client architecture.' }
            elseif ($RawError -match '(?i)guest|signing') { $category='Authentication'; $advice='Use authenticated sharing and a server supporting SMB signing.' }
        }
    }
    if ($category -ne 'General') { $title = "$category printer error" }
    return [pscustomobject]@{ Title=$title; Explanation=$advice; Category=$category; IsDriverError=($category -in @('Driver','DriverInUse')); Code=$code; Detail=$RawError }
}
function Get-NetworkSharedPrinters {
    param([string[]]$ComputerNames = @())
    $results = [Collections.Generic.List[object]]::new()
    $seen = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    foreach ($printer in @(Get-Printer -ErrorAction Stop | Where-Object { $_.Name -like '\\*' })) {
        if ($seen.Add($printer.Name)) {
            $parts=$printer.Name.TrimStart('\').Split('\')
            $results.Add([pscustomobject]@{ShareName=$parts[-1];PrinterName=$printer.DriverName;Host=$parts[0];Path=$printer.Name})
        }
    }
    # Neighbors are hints, not a complete network inventory. Manual host input
    # remains available when discovery is blocked or printers are on another VLAN.
    $neighbors = @(Get-NetNeighbor -AddressFamily IPv4 -ErrorAction SilentlyContinue | Where-Object { $_.State -notin @('Unreachable','Incomplete') } | Select-Object -ExpandProperty IPAddress)
    $candidates=$neighbors
    if ($ComputerNames.Count) { $candidates=$ComputerNames }
    $hosts = @($candidates | Where-Object { Test-KyuHostName $_ } | Select-Object -Unique | Select-Object -First 64)
    $protected = [Collections.Generic.List[string]]::new()
    $online = [Collections.Generic.List[string]]::new()
    foreach ($computer in $hosts) {
        if (-not (Test-KyuTcpPort -ComputerName $computer -Port 445 -TimeoutMs 600)) { continue }
        $online.Add($computer)
        $session=$null
        try {
            $option=New-CimSessionOption -Protocol Dcom
            $session=New-CimSession -ComputerName $computer -SessionOption $option -OperationTimeoutSec 3 -ErrorAction Stop
            foreach ($printer in @(Get-CimInstance -CimSession $session -ClassName Win32_Printer -Filter 'Shared=True' -OperationTimeoutSec 3 -ErrorAction Stop)) {
                $path="\\$computer\$($printer.ShareName)"
                if ($printer.ShareName -and $seen.Add($path)) { $results.Add([pscustomobject]@{ShareName=$printer.ShareName;PrinterName=$printer.Name;Host=$computer;Path=$path}) }
            }
        } catch { $protected.Add($computer) }
        finally { if ($session) { Remove-CimSession $session -ErrorAction SilentlyContinue } }
    }
    return [pscustomobject]@{Printers=$results.ToArray();OnlineHosts=$online.ToArray();ProtectedHosts=$protected.ToArray()}
}
function Connect-PrinterTarget {
    param([string]$TargetPath)
    $path=Resolve-KyuPrinterTarget -Text $TargetPath
    try {
        if (-not @(Get-Printer -ErrorAction Stop | Where-Object { $_.Name -ieq $path }).Count) {
            Add-Printer -ConnectionName $path -ErrorAction Stop
        }
        $found=@(Get-Printer -ErrorAction Stop | Where-Object { $_.Name -ieq $path -or ($_.ComputerName -and $_.ShareName -and "\\$($_.ComputerName.TrimStart('\'))\$($_.ShareName)" -ieq $path) })
        if (-not $found.Count) { throw 'Windows did not enumerate the requested connection after installation.' }
        Write-KyuLog 'Shared printer connection enumerated successfully.'
        return $null
    } catch {
        $detail=$_.Exception.Message
        if ($_.Exception.NativeErrorCode) { $detail="Win32 $($_.Exception.NativeErrorCode): $detail" }
        elseif ($_.Exception.HResult) { $detail=('0x{0:X8}: {1}' -f $_.Exception.HResult,$detail) }
        Write-KyuLog 'Shared printer connection failed.' 'ERROR'
        return $detail
    }
}
function Get-KyuStandardSpoolDirectory {
    $standard=Join-Path $env:SystemRoot 'System32\spool\PRINTERS'
    $key='HKLM:\SYSTEM\CurrentControlSet\Control\Print\Printers'
    $configuration=Get-ItemProperty -LiteralPath $key -ErrorAction Stop
    $declared=@($configuration.DefaultSpoolDirectory)
    foreach ($printerKey in @(Get-ChildItem -LiteralPath $key -ErrorAction Stop)) {
        $declared += (Get-ItemProperty -LiteralPath $printerKey.PSPath -ErrorAction Stop).SpoolDirectory
    }
    foreach ($directory in $declared) {
        if (-not [string]::IsNullOrWhiteSpace($directory)) {
            $expanded=[IO.Path]::GetFullPath([Environment]::ExpandEnvironmentVariables($directory)).TrimEnd('\')
            if (-not $expanded.Equals($standard.TrimEnd('\'),[StringComparison]::OrdinalIgnoreCase)) {
                throw "Custom spool directory detected: $expanded. No queue files were deleted. Inspect the affected printer/server configuration with its administrator."
            }
        }
    }
    return $standard
}
function Restart-KyuSpooler {
    param([switch]$ClearQueue)
    Assert-KyuAdministrator
    $service=Get-Service -Name Spooler -ErrorAction Stop
    if ($ClearQueue) {
        $root=Join-Path $env:SystemRoot 'System32\spool'
        $queue=Assert-KyuSafePath -Path (Get-KyuStandardSpoolDirectory) -AllowedRoot $root
        try {
            Stop-Service -Name Spooler -ErrorAction Stop
            (Get-Service Spooler).WaitForStatus('Stopped',[TimeSpan]::FromSeconds(20))
            foreach ($file in @(Get-ChildItem -LiteralPath $queue -File -Force -ErrorAction Stop)) {
                # Never recurse into directories or delete driver packages.
                if ($file.Extension -in @('.SPL','.SHD')) { Remove-Item -LiteralPath $file.FullName -Force -ErrorAction Stop }
            }
        } finally { [void](Start-KyuService -Name Spooler) }
    } else {
        if ($service.Status -eq 'Running') { Restart-Service -Name Spooler -ErrorAction Stop }
        [void](Start-KyuService -Name Spooler)
    }
    if ((Get-Service Spooler).Status -ne 'Running') { throw 'Spooler is not running after the operation.' }
    Write-KyuLog 'Spooler running after requested operation.'
}
function Get-KyuPrinterDiagnostics {
    param([string]$ComputerName)
    $report=[ordered]@{Computer=$env:COMPUTERNAME;User=[Environment]::UserName;Spooler=(Get-Service Spooler -ErrorAction Stop).Status.ToString();Printers=@(Get-Printer -ErrorAction Stop | Select-Object Name,DriverName,PortName,PrinterStatus,Shared,ShareName);Profiles=@(Get-NetConnectionProfile -ErrorAction SilentlyContinue | Select-Object InterfaceAlias,NetworkCategory);SMB=$null;Host=$null}
    try { $report.SMB=Get-SmbClientConfiguration -ErrorAction Stop | Select-Object RequireSecuritySignature,EnableInsecureGuestLogons } catch { $report.SMB='Unavailable: '+$_.Exception.Message }
    if ($ComputerName) {
        if (-not (Test-KyuHostName $ComputerName)) { throw 'Invalid host name.' }
        $report.Host=[pscustomobject]@{Name=$ComputerName;SMB445=(Test-KyuTcpPort $ComputerName 445);RPC135=(Test-KyuTcpPort $ComputerName 135)}
    }
    return [pscustomobject]$report
}
