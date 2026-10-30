param([ValidateSet('Menu','Diagnose','Inventory','EnableSharing','Share','Connect','Restart','ClearQueue','DirectIP','Default','TestPage','Logs','Restore')][string]$Action='Menu')
. (Join-Path $PSScriptRoot 'printer_core.ps1')

function Select-KyuPrinter {
    $printers=@(Get-Printer -ErrorAction Stop)
    if (-not $printers.Count) { throw 'No printers are installed. Install a signed driver and add the printer first.' }
    for ($i=0;$i -lt $printers.Count;$i++) { Write-Host ('[{0}] {1} ({2})' -f ($i+1),$printers[$i].Name,$printers[$i].PrinterStatus) }
    $choice=0
    if (-not [int]::TryParse((Read-Host 'Printer number (ENTER cancels)'),[ref]$choice)) { return $null }
    if ($choice -lt 1 -or $choice -gt $printers.Count) { throw 'Invalid printer number.' }
    return $printers[$choice-1]
}
function Enable-KyuPrinterSharing {
    Assert-KyuAdministrator
    $profiles=@(Get-NetConnectionProfile -ErrorAction Stop)
    if (-not $profiles.Count) { throw 'No connected network profile was found.' }
    $profiles | Format-Table InterfaceIndex,InterfaceAlias,NetworkCategory
    $index=0
    if (-not [int]::TryParse((Read-Host 'InterfaceIndex of the trusted LAN'),[ref]$index)) { throw 'Enter a displayed interface index.' }
    $selected=@($profiles | Where-Object InterfaceIndex -eq $index)
    if ($selected.Count -ne 1) { throw 'Select exactly one connected network.' }
    if (-not (Confirm-KyuAction 'Enable authenticated printer sharing on the trusted LAN? Public networks must not be selected')) { return }
    $rules=@(Get-NetFirewallRule -Name 'FPS-*','NETDIS-*' -ErrorAction Stop | Where-Object Direction -eq Inbound)
    $services=@(Get-CimInstance Win32_Service -Filter "Name='FDResPub' OR Name='fdPHost' OR Name='LanmanServer' OR Name='Spooler'" -ErrorAction Stop | Select-Object Name,StartMode,State)
    $backup=Join-Path (Get-KyuBackupDirectory) 'printer-sharing.clixml'
    [pscustomobject]@{Computer=$env:COMPUTERNAME;Profile=($selected | Select-Object InterfaceIndex,NetworkCategory);Rules=@($rules | Select-Object Name,Enabled,Profile);Services=$services} | Export-Clixml -LiteralPath $backup -ErrorAction Stop
    Write-Host "Configuration backup: $backup"
    try {
        if ($selected[0].NetworkCategory -eq 'Public') { Set-NetConnectionProfile -InterfaceIndex $index -NetworkCategory Private -ErrorAction Stop }
        foreach ($rule in $rules) { Set-NetFirewallRule -Name $rule.Name -Profile Private,Domain -Enabled True -ErrorAction Stop }
        foreach ($name in @('Spooler','LanmanServer','FDResPub','fdPHost')) {
            $definition=$services | Where-Object Name -eq $name
            if ($definition.StartMode -eq 'Disabled') { throw "$name is disabled. Review organization policy before enabling it; restore partial changes using the saved backup if needed." }
            [void](Start-KyuService $name)
        }
        Write-Host 'Sharing services are running. Firewall rules are enabled for Private/Domain profiles.'
        Write-Host 'Use a host account with a password and printer permission. Windows Hello PINs are not network passwords.'
        Write-KyuLog 'Authenticated printer-sharing configuration applied.'
    } catch { throw "Sharing setup stopped: $($_.Exception.Message) Restore configuration using $backup if necessary." }
}
function Restore-KyuPrinterSharing {
    Assert-KyuAdministrator
    $path=(Read-Host 'Full path to printer-sharing.clixml backup').Trim('"')
    $state=Import-Clixml -LiteralPath $path -ErrorAction Stop
    if ($state.Computer -ne $env:COMPUTERNAME -or -not $state.Profile -or -not $state.Rules) { throw 'This is not a printer-sharing backup for this PC.' }
    if (-not (Confirm-KyuAction 'Restore the saved network profile, firewall rules, and service running state?')) { return }
    foreach ($rule in $state.Rules) { Set-NetFirewallRule -Name $rule.Name -Enabled $rule.Enabled -Profile $rule.Profile -ErrorAction Stop }
    if ($state.Profile.NetworkCategory -ne 'DomainAuthenticated') { Set-NetConnectionProfile -InterfaceIndex $state.Profile.InterfaceIndex -NetworkCategory $state.Profile.NetworkCategory -ErrorAction Stop }
    foreach ($service in $state.Services) {
        if ($service.State -eq 'Running') { [void](Start-KyuService $service.Name) }
        elseif ((Get-Service $service.Name).Status -eq 'Running') { Stop-Service -Name $service.Name -ErrorAction Stop }
    }
    Write-Host 'Saved sharing configuration restored.'
}
function Show-KyuPrinterDiagnostics {
    $computer=(Read-Host 'Optional host PC name/IP (ENTER for local checks)').Trim()
    $report=Get-KyuPrinterDiagnostics -ComputerName $computer
    $report | Format-List Computer,User,Spooler
    $report.Profiles | Format-Table
    $report.Printers | Format-Table -AutoSize
    $report.SMB | Format-List
    if ($report.Host) { $report.Host | Format-List }
    Write-Host 'A blocked discovery query does not prove a printer is absent. Try its full \\HOST\SHARE path.'
    Write-Host 'Both PCs need compatible signed drivers and updates. A reachable port does not prove a print job will finish.'
    $file=Join-Path (Get-KyuDesktop) ('KyuTools_Printer_'+(Get-Date -Format 'yyyyMMdd-HHmmss')+'.json')
    $report | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $file -Encoding UTF8 -ErrorAction Stop
    Write-Host "Diagnostic report: $file"
}
function Connect-KyuPrinterInteractive {
    $computer=(Read-Host 'Host PC name/IP to query (ENTER uses cached neighbors)').Trim()
    if ($computer -and -not (Test-KyuHostName $computer)) { throw 'Invalid host name.' }
    Write-Host 'Looking for shared printers. Discovery can be restricted; manual UNC entry always remains available.'
    $names=@(); if ($computer) { $names=@($computer) }
    $discovery=Get-NetworkSharedPrinters -ComputerNames $names
    $printers=@($discovery.Printers)
    for ($i=0;$i -lt $printers.Count;$i++) { Write-Host ('[{0}] {1} ({2})' -f ($i+1),$printers[$i].Path,$printers[$i].PrinterName) }
    if ($discovery.ProtectedHosts.Count) { Write-Host ('Could not enumerate these hosts (credentials, RPC, or policy may block queries): '+($discovery.ProtectedHosts -join ', ')) }
    $text=(Read-Host 'Printer number or full \\HOST\SHARE path (ENTER cancels)').Trim()
    if (-not $text) { return }
    $path=Resolve-KyuPrinterTarget -Text $text -Printers $printers
    $targetHost=$path.TrimStart('\').Split('\')[0]
    if (-not (Test-KyuTcpPort $targetHost 445)) { Write-Warning 'TCP 445 was not reachable. Check host power, name resolution, network isolation, and sharing firewall rules.' }
    for ($attempt=0;$attempt -lt 2;$attempt++) {
        $problem=Connect-PrinterTarget $path
        if (-not $problem) {
            Write-Host "Windows enumerates $path for the current user. Physical printing is not yet verified."
            Write-Host 'If elevation used another administrator account, add the connection in the intended user session too.'
            return
        }
        $info=Format-PrinterError $problem
        Write-Host $info.Title -ForegroundColor Yellow
        Write-Host $info.Explanation
        Write-Host "Details: $problem"
        if ($attempt -eq 1) { throw 'Connection remains unresolved. Save the diagnostic report and check the host/driver with an administrator.' }
        if ($info.Category -in @('Authentication','Access','CredentialsConflict')) {
            Write-Host "Open \\$targetHost in File Explorer and authenticate with a host/domain account. No password is read by this toolkit."
            if (Confirm-KyuAction 'Open the host in File Explorer?') { Start-Process explorer.exe -ArgumentList "\\$targetHost" -ErrorAction Stop }
        } elseif ($info.IsDriverError) {
            Write-Host 'Install the approved signed driver matching the printer model and x64/x86/ARM64 architecture.'
            if (Confirm-KyuAction 'Open Print Server Properties to inspect drivers?') { Start-Process printui.exe -ArgumentList '/s /t2' -Wait -ErrorAction Stop }
        }
        if (-not (Confirm-KyuAction 'Retry the connection after addressing the reported cause?')) { return }
    }
}
function Add-KyuDirectPrinter {
    Assert-KyuAdministrator
    $computer=(Read-Host 'Printer IP address or DNS hostname').Trim()
    if (-not (Test-KyuHostName $computer)) { throw 'Invalid printer IP address or hostname.' }
    Write-Host 'Use this for a printer with its own network interface and RAW TCP 9100 support.'
    if (-not (Test-KyuTcpPort $computer 9100)) { throw 'TCP 9100 is unavailable. Verify the device address/protocol; use Windows Add Device for IPP or WSD printers.' }
    $drivers=@(Get-PrinterDriver -ErrorAction Stop | Sort-Object Name)
    for ($i=0;$i -lt $drivers.Count;$i++) { Write-Host ('[{0}] {1}' -f ($i+1),$drivers[$i].Name) }
    $number=0
    if (-not [int]::TryParse((Read-Host 'Number of the exact compatible driver'),[ref]$number) -or $number -lt 1 -or $number -gt $drivers.Count) { throw 'Install the correct signed driver before adding this printer.' }
    $name=(Read-Host 'New local printer name').Trim()
    if (-not $name -or $name -match '[\\\x00-\x1f]') { throw 'Invalid local printer name.' }
    if (@(Get-Printer -ErrorAction Stop | Where-Object Name -eq $name).Count) { throw 'That printer name already exists; inspect it instead of creating a duplicate.' }
    if (-not (Confirm-KyuAction "Add $name using the selected driver and $computer`:9100?")) { return }
    $port='KyuTCP_'+$computer; $created=$false
    try {
        $existing=@(Get-PrinterPort -ErrorAction Stop | Where-Object Name -eq $port)
        if ($existing.Count) {
            if ($existing[0].PrinterHostAddress -ne $computer -or $existing[0].PortNumber -ne 9100) { throw 'Existing port has different configuration; choose or repair it in Windows printer properties.' }
        } else { Add-PrinterPort -Name $port -PrinterHostAddress $computer -PortNumber 9100 -ErrorAction Stop; $created=$true }
        Add-Printer -Name $name -DriverName $drivers[$number-1].Name -PortName $port -ErrorAction Stop
        if (-not @(Get-Printer -ErrorAction Stop | Where-Object Name -eq $name).Count) { throw 'Printer was not enumerated after setup.' }
    } catch {
        if ($created -and -not @(Get-Printer -ErrorAction Stop | Where-Object PortName -eq $port).Count) { Remove-PrinterPort -Name $port -ErrorAction SilentlyContinue }
        throw
    }
    Write-Host 'Printer is installed. Use the optional test-page action to verify physical output.'
}
function Invoke-KyuPrinterAction {
    param([string]$SelectedAction)
    switch ($SelectedAction) {
        'Diagnose' { Show-KyuPrinterDiagnostics }
        'Inventory' {
            Get-Printer -ErrorAction Stop | Format-Table Name,Type,DriverName,PortName,PrinterStatus,Shared,ShareName -AutoSize
            Get-PrinterDriver -ErrorAction Stop | Format-Table Name,PrinterEnvironment,MajorVersion -AutoSize
            if (Confirm-KyuAction 'Open Windows printer settings to add an approved driver or IPP/WSD device?') { Start-Process 'ms-settings:printers' }
        }
        'EnableSharing' { Enable-KyuPrinterSharing }
        'Restore' { Restore-KyuPrinterSharing }
        'Share' {
            Assert-KyuAdministrator
            $printer=Select-KyuPrinter; if (-not $printer) { return }
            if ($printer.Type -eq 'Connection') { throw 'Share the printer on its actual host, not a client connection.' }
            $share=(Read-Host 'Share name (1-80 characters)').Trim()
            if (-not $share -or $share.Length -gt 80 -or $share -match '[\\/:*?"<>|\x00-\x1f]' -or $share -match '[ .]$') { throw 'Invalid printer share name.' }
            if (-not (Confirm-KyuAction "Share $($printer.Name) as $share for authenticated users?")) { return }
            Set-Printer -Name $printer.Name -Shared $true -ShareName $share -ErrorAction Stop
            $verified=Get-Printer -Name $printer.Name -ErrorAction Stop
            if (-not $verified.Shared -or $verified.ShareName -ne $share) { throw 'Sharing configuration was not verified.' }
            Write-Host "Share configured: \\$env:COMPUTERNAME\$share. Use Enable Sharing separately if network setup is needed."
        }
        'Connect' { Connect-KyuPrinterInteractive }
        'Restart' { if (Confirm-KyuAction 'Restart the local spooler? This interrupts printing; queued jobs are retained') { Restart-KyuSpooler; Write-Host 'Spooler is running.' } }
        'ClearQueue' { if (Confirm-KyuAction 'Delete ALL local pending .SPL/.SHD jobs and restart the spooler? Jobs must be resubmitted') { Restart-KyuSpooler -ClearQueue; Write-Host 'Queue files removed; spooler is running. Driver packages were retained.' } }
        'DirectIP' { Add-KyuDirectPrinter }
        'Default' {
            $printer=Select-KyuPrinter; if (-not $printer) { return }
            if (-not (Confirm-KyuAction "Set $($printer.Name) as the default for the current user?")) { return }
            (New-Object -ComObject WScript.Network).SetDefaultPrinter($printer.Name)
            $actual=@(Get-CimInstance Win32_Printer -ErrorAction Stop | Where-Object { $_.Name -eq $printer.Name -and $_.Default })
            if (-not $actual.Count) { throw 'Default printer was not verified. Check Let Windows manage my default printer in Settings.' }
            Write-Host 'Default printer verified for the current user.'
        }
        'TestPage' {
            $printer=Select-KyuPrinter; if (-not $printer) { return }
            if (-not (Confirm-KyuAction "Send a physical test page to $($printer.Name)? This uses paper/ink")) { return }
            $device=Get-CimInstance Win32_Printer -ErrorAction Stop | Where-Object Name -eq $printer.Name | Select-Object -First 1
            if (-not $device) { throw 'Printer was not found through Windows CIM.' }
            $result=Invoke-CimMethod -InputObject $device -MethodName PrintTestPage -ErrorAction Stop
            if ($result.ReturnValue -ne 0) { throw "Test-page submission failed: Win32 $($result.ReturnValue)" }
            Write-Host 'Test page submitted. Confirm output at the printer; submission does not prove delivery.'
        }
        'Logs' {
            foreach ($channel in @('Microsoft-Windows-PrintService/Admin','Microsoft-Windows-PrintService/Operational')) {
                Write-Host $channel
                try { Get-WinEvent -FilterHashtable @{LogName=$channel;StartTime=(Get-Date).AddDays(-3)} -MaxEvents 30 -ErrorAction Stop | Format-List TimeCreated,Id,LevelDisplayName,Message }
                catch { Write-Warning "No readable recent events: $($_.Exception.Message)" }
            }
        }
    }
}
if ($MyInvocation.InvocationName -ne '.') {
    $ErrorActionPreference='Stop'
    if ($Action -ne 'Menu') {
        try { Invoke-KyuPrinterAction $Action; exit 0 } catch { Write-Host $_.Exception.Message -ForegroundColor Red; Write-KyuLog "Printer action $Action failed." 'ERROR'; exit 1 }
    }
    $actions=@('Diagnose','EnableSharing','Inventory','Share','Connect','Restart','ClearQueue','DirectIP','Default','TestPage','Logs','Restore')
    while ($true) {
        Write-Host "`nPrinter and Device Sharing"
        Write-Host '[1] Diagnose and export report    [2] Enable authenticated sharing'
        Write-Host '[3] Printers, drivers and devices [4] Share a local printer'
        Write-Host '[5] Connect to a shared printer   [6] Restart spooler (retain jobs)'
        Write-Host '[7] Clear stuck local queue       [8] Add direct TCP/IP printer'
        Write-Host '[9] Set default printer           [10] Optional physical test page'
        Write-Host '[11] PrintService events          [12] Restore sharing backup'
        Write-Host '[0] Return'
        $choice=0; $text=Read-Host 'Select option'
        if ($text -eq '0' -or $text -eq '') { break }
        if ([int]::TryParse($text,[ref]$choice) -and $choice -ge 1 -and $choice -le $actions.Count) {
            try { Invoke-KyuPrinterAction $actions[$choice-1] } catch { Write-Host $_.Exception.Message -ForegroundColor Red; Write-KyuLog "Printer action failed: $($actions[$choice-1])" 'ERROR' }
            [void](Read-Host 'ENTER to continue')
        }
    }
}
