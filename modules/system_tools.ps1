param([string]$Action)
. (Join-Path $PSScriptRoot 'common.ps1')

function Test-KyuProductKey {
    param([string]$Key)
    return ($Key -match '^[A-Z0-9]{5}(?:-[A-Z0-9]{5}){4}$')
}
function Get-KyuOfficeConfiguration {
    param([ValidateSet('2021','2024','365')][string]$Edition,[ValidateSet('32','64')][string]$Architecture)
    $product='O365ProPlusRetail'; $channel='Current'
    if ($Edition -eq '2021') { $product='ProPlus2021Volume'; $channel='PerpetualVL2021' }
    if ($Edition -eq '2024') { $product='ProPlus2024Volume'; $channel='PerpetualVL2024' }
    $exclusions=@('Access','Bing','Groove','Lync','OneDrive','OneNote','Publisher','Teams') | ForEach-Object { '<ExcludeApp ID="'+$_+'" />' }
    return '<Configuration><Add OfficeClientEdition="'+$Architecture+'" Channel="'+$channel+'"><Product ID="'+$product+'"><Language ID="en-us" />'+($exclusions -join '')+'</Product></Add><Display Level="Full" AcceptEULA="FALSE" /><Property Name="AUTOACTIVATE" Value="0" /></Configuration>'
}
function Get-KyuLicenseAdvice {
    param([string]$Detail)
    switch -Regex ($Detail) {
        '0xC004F074' { return 'Contact the organization licensing administrator: verify VPN/domain connectivity and the authorized KMS server. Preserve existing KMS configuration.' }
        '0x8007007B|0xC004F050' { return 'Verify the key format, license channel, and installed Windows edition. Enter a matching licensed key; do not uninstall the existing key automatically.' }
        '0xC004C003|0xC004C008' { return 'The key may be blocked or its activation limit reached. Contact the license seller or Microsoft support.' }
        '0x80072EE7|0x80072F8F' { return 'Check DNS, proxy, connectivity, date, time, and TLS. Do not clear license data.' }
        default { return 'Use Settings > System > Activation and its troubleshooter. A valid license or organizational entitlement is required.' }
    }
}
function Get-KyuWindowsLicense {
    return @(Get-CimInstance SoftwareLicensingProduct -Filter "ApplicationID='55c92734-d682-4d71-983e-d6ec3f16059f' AND PartialProductKey IS NOT NULL AND LicenseIsAddon=False" -ErrorAction Stop)
}
function Install-KyuOffice {
    Assert-KyuAdministrator
    Write-Host 'Choose your licensed product: 2021 or 2024 (LTSC Professional Plus volume license), or 365 (enterprise subscription).'
    $edition=(Read-Host 'Edition: 2021 / 2024 / 365 (ENTER cancels)').Trim()
    if (-not $edition) { return }
    $architecture=if ([Environment]::Is64BitOperatingSystem) { '64' } else { '32' }
    $existing=Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Office\ClickToRun\Configuration' -ErrorAction SilentlyContinue
    if ($existing.Platform -eq 'x86') { $architecture='32' }
    Write-Host "Architecture: $architecture-bit. Existing Click-to-Run: $($existing.ProductReleaseIds)"
    if ($env:PROCESSOR_ARCHITECTURE -eq 'ARM64' -or $env:PROCESSOR_ARCHITEW6432 -eq 'ARM64') { throw 'Use the official Microsoft Office installer for this ARM64 device; verify product and architecture compatibility first.' }
    $xml=Get-KyuOfficeConfiguration $edition $architecture
    Write-Host 'This installs Word, Excel, PowerPoint and Outlook using Microsoft deployment media. Existing MSI products are not automatically removed. Retail perpetual licenses require their matching installer.'
    if (-not (Confirm-KyuAction 'Download signed Microsoft setup and configure Office? Save and close Office apps first')) { return }
    $directory=Join-Path ([IO.Path]::GetTempPath()) ('KyuOffice-'+[guid]::NewGuid().ToString('N'))
    [void][IO.Directory]::CreateDirectory($directory)
    $setup=Join-Path $directory 'setup.exe'; $configuration=Join-Path $directory 'configuration.xml'
    [Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12
    Invoke-WebRequest -Uri 'https://officecdn.microsoft.com/pr/wsus/setup.exe' -OutFile $setup -UseBasicParsing -ErrorAction Stop
    $signature=Get-AuthenticodeSignature -LiteralPath $setup -ErrorAction Stop
    if ($signature.Status -ne 'Valid' -or $signature.SignerCertificate.Subject -notmatch 'O=Microsoft Corporation(?:,|$)') { throw 'Downloaded installer did not pass Microsoft signature validation. It was not executed.' }
    Set-Content -LiteralPath $configuration -Value $xml -Encoding UTF8 -ErrorAction Stop
    $result=Invoke-KyuNative $setup @('/configure',$configuration) -SuccessCodes @(0,3010)
    $installed=Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Office\ClickToRun\Configuration' -ErrorAction Stop
    [xml]$expected=$xml
    if ($installed.ProductReleaseIds -notmatch [regex]::Escape($expected.Configuration.Add.Product.ID)) { throw "Installer returned without the requested product being verified. Installer files retained at $directory" }
    Write-Host "Office product detected. Restart required: $($result.RebootRequired). Licensing must be verified separately. Installer files: $directory"
}
function Set-KyuPowerPlan {
    param([ValidateSet('High','Ultimate','Balanced')][string]$Plan)
    $guid='381b4222-f694-41f0-9685-ff5bb260df2e'
    if ($Plan -eq 'High') { $guid='8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c' }
    if ($Plan -eq 'Ultimate') {
        $created=Invoke-KyuNative powercfg.exe @('/duplicatescheme','e9a42b02-d5df-448d-aa00-03f14749eb61')
        if ($created.Output -notmatch '\b[0-9a-fA-F]{8}(?:-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}\b') { throw 'Could not identify the newly created power plan.' }
        $guid=$matches[0]
    }
    [void](Invoke-KyuNative powercfg.exe @('/setactive',$guid))
    $actual=Invoke-KyuNative powercfg.exe @('/getactivescheme')
    if ($actual.Output -notmatch [regex]::Escape($guid)) { throw 'Requested power plan was not verified. Some devices support only Balanced/Modern Standby plans.' }
}
function Set-KyuRegistryValues {
    param([object[]]$Settings)
    $states=@(foreach ($setting in $Settings) {
        $item=Get-Item -LiteralPath $setting.Path -ErrorAction SilentlyContinue
        $exists=$item -and ($item.GetValueNames() -contains $setting.Name)
        [pscustomobject]@{Path=$setting.Path;Name=$setting.Name;Exists=[bool]$exists;Value=$(if($exists){$item.GetValue($setting.Name,$null,'DoNotExpandEnvironmentNames')}else{$null});Kind=$(if($exists){$item.GetValueKind($setting.Name).ToString()}else{'DWord'})}
    })
    $backup=Join-Path (Get-KyuBackupDirectory) 'registry-settings.clixml'
    [pscustomobject]@{Computer=$env:COMPUTERNAME;Settings=$states} | Export-Clixml -LiteralPath $backup -ErrorAction Stop
    Write-Host "Registry backup: $backup"
    foreach ($setting in $Settings) {
        if (-not (Test-Path -LiteralPath $setting.Path)) { [void](New-Item -Path $setting.Path -Force -ErrorAction Stop) }
        [void](New-ItemProperty -LiteralPath $setting.Path -Name $setting.Name -Value $setting.Value -PropertyType $setting.Kind -Force -ErrorAction Stop)
        if ((Get-ItemPropertyValue -LiteralPath $setting.Path -Name $setting.Name -ErrorAction Stop) -ne $setting.Value) { throw "Registry write not verified: $($setting.Name)" }
    }
}
function Restore-KyuRegistryValues {
    $path=(Read-Host 'Full registry-settings.clixml backup path').Trim('"')
    $backup=Import-Clixml -LiteralPath $path -ErrorAction Stop
    if ($backup.Computer -ne $env:COMPUTERNAME -or -not $backup.Settings) { throw 'Select a settings backup created on this PC.' }
    if (-not (Confirm-KyuAction 'Restore the exact saved registry values?')) { return }
    foreach ($setting in $backup.Settings) {
        if ($setting.Exists) {
            if (-not (Test-Path -LiteralPath $setting.Path)) { [void](New-Item -Path $setting.Path -Force -ErrorAction Stop) }
            [void](New-ItemProperty -LiteralPath $setting.Path -Name $setting.Name -Value $setting.Value -PropertyType $setting.Kind -Force -ErrorAction Stop)
        } elseif (Test-Path -LiteralPath $setting.Path) { Remove-ItemProperty -LiteralPath $setting.Path -Name $setting.Name -ErrorAction Stop }
    }
    Write-Host 'Saved registry values restored. Sign out or restart if required by Windows.'
}
function Get-KyuPrivacySettings {
    param([int]$Selection=8)
    $items=@(
        @('HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection','AllowTelemetry',0),
        @('HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search','AllowCortana',0),
        @('HKLM:\SOFTWARE\Policies\Microsoft\Windows\System','EnableActivityFeed',0),
        @('HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo','Enabled',0),
        @('HKLM:\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors','DisableLocation',1),
        @('HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Privacy','TailoredExperiencesWithDiagnosticDataEnabled',0)
    )
    if ($Selection -ne 8) { $items=@(,$items[$Selection-1]) }
    return @($items | ForEach-Object { [pscustomobject]@{Path=$_[0];Name=$_[1];Value=$_[2];Kind='DWord'} })
}
function Reset-KyuUpdateCache {
    $names=@('wuauserv','bits','cryptsvc')
    $states=@{}; foreach ($name in $names) { $states[$name]=(Get-Service $name -ErrorAction Stop).Status.ToString() }
    $suffix='KyuBackup-'+(Get-Date -Format 'yyyyMMdd-HHmmss')+'-'+[guid]::NewGuid().ToString('N').Substring(0,6)
    try {
        foreach ($name in $names) {
            if ($states[$name] -eq 'Running') {
                Stop-Service $name -ErrorAction Stop
                (Get-Service $name).WaitForStatus('Stopped',[TimeSpan]::FromSeconds(30))
            }
        }
        foreach ($relative in @('SoftwareDistribution','System32\catroot2')) {
            $path=Assert-KyuSafePath (Join-Path $env:SystemRoot $relative) $env:SystemRoot
            if (Test-Path -LiteralPath $path) { Rename-Item -LiteralPath $path -NewName ((Split-Path $path -Leaf)+'.'+$suffix) -ErrorAction Stop }
        }
    } finally {
        $failures=@()
        foreach ($name in $names) {
            if ($states[$name] -eq 'Running') { try { [void](Start-KyuService $name) } catch { $failures+=$name } }
        }
        if ($failures.Count) { throw ('Could not restore running services: '+($failures -join ', ')) }
    }
    Write-Host "Update caches renamed with suffix $suffix. Previous data was retained and prior running services restored."
}
function Select-KyuAdapter {
    $adapters=@(Get-NetAdapter -ErrorAction Stop | Where-Object Status -eq 'Up')
    $adapters | Format-Table ifIndex,Name,InterfaceDescription
    $index=0
    if (-not [int]::TryParse((Read-Host 'Adapter ifIndex'),[ref]$index) -or $index -notin $adapters.ifIndex) { throw 'Select an active adapter from the list.' }
    return $index
}
function Unlock-KyuLocalAccount {
    param([string]$Name)
    if (-not $Name -or $Name -match '[\\/@\x00-\x1f]') { throw 'Enter a local account name, without a domain or path.' }
    $user=[ADSI]("WinNT://$env:COMPUTERNAME/$Name,user")
    if (-not $user.Name) { throw 'Local account was not found.' }
    if (-not [bool]$user.InvokeGet('IsAccountLocked')) { Write-Host 'Account is not locked. Disabled accounts and forgotten passwords require separate actions.'; return }
    $user.InvokeSet('IsAccountLocked',$false)
    $user.SetInfo(); $user.RefreshCache()
    if ([bool]$user.InvokeGet('IsAccountLocked')) { throw 'Account is still locked. Check repeated sign-in attempts and policy.' }
    Write-Host 'Local lockout flag cleared. Enabled/disabled state and password were retained.'
}
function Assert-KyuBackupPaths {
    param([string]$Source,[string]$Destination)
    $sourcePath=[IO.Path]::GetFullPath($Source).TrimEnd('\')
    $destinationPath=[IO.Path]::GetFullPath($Destination).TrimEnd('\')
    if ($sourcePath -eq $destinationPath -or $sourcePath.StartsWith($destinationPath+'\',[StringComparison]::OrdinalIgnoreCase) -or $destinationPath.StartsWith($sourcePath+'\',[StringComparison]::OrdinalIgnoreCase)) { throw 'Source and destination must be separate directories, without either containing the other.' }
    return $true
}
function Restart-KyuAudioServices {
    $names=@('Audiosrv','AudioEndpointBuilder')
    $running=@{}
    foreach ($name in $names) { $running[$name]=((Get-Service $name -ErrorAction Stop).Status -eq 'Running') }
    try {
        # Stop the audio service before its endpoint-builder dependency. Refuse
        # unexpected running dependents rather than force-stopping them.
        foreach ($name in $names) {
            if ($running[$name]) {
                Stop-Service -Name $name -ErrorAction Stop
                (Get-Service $name -ErrorAction Stop).WaitForStatus('Stopped',[TimeSpan]::FromSeconds(20))
            }
        }
    } finally {
        $failures=@()
        foreach ($name in @('AudioEndpointBuilder','Audiosrv')) {
            if ($running[$name]) { try { [void](Start-KyuService $name) } catch { $failures+=$name } }
        }
        if ($failures.Count) { throw ('Could not restore audio services: '+($failures -join ', ')) }
    }
    foreach ($name in @('AudioEndpointBuilder','Audiosrv')) { [void](Start-KyuService $name) }
    Write-Host 'Audio service running states verified. Test the selected output device.'
}
function Invoke-KyuSystemAction {
    param([string]$SelectedAction)
    switch -Regex ($SelectedAction) {
        '^OfficeInstall$' { Install-KyuOffice; break }
        '^AudioRepair$' { Restart-KyuAudioServices; break }
        '^OfficeLicense$' {
            Write-Host 'Microsoft 365: open Word > File > Account and sign in with the licensed account. Retail Office: use the account that redeemed the product at https://account.microsoft.com/services.'
            Write-Host 'Volume Office: connect to your organization/VPN and ask its licensing administrator to verify KMS/MAK entitlement. Installation alone does not grant a license.'
            if (Confirm-KyuAction 'Open the official Microsoft Office activation help?') { Start-Process 'https://support.microsoft.com/en-us/office/activate-office-5bd38f38-db92-448b-a982-ad170b1e187e' }
            break
        }
        '^OfficeRemove$' {
            Write-Host 'Back up Outlook data and close Office apps. Prefer Windows Installed Apps or Microsoft uninstall support before deep cleanup.'
            Write-Host 'The bundled third-party OfficeScrubber can remove Office products, licensing data, and settings.'
            if (Confirm-KyuAction 'Run the bundled OfficeScrubber interactively after reviewing its scope?') {
                $file=Join-Path (Split-Path $PSScriptRoot -Parent) 'bin\OfficeScrubber.cmd'
                if (-not (Test-Path -LiteralPath $file -PathType Leaf)) { throw 'Bundled OfficeScrubber is missing. No replacement was downloaded or executed.' }
                & $file
                if ($LASTEXITCODE -ne 0) { throw "OfficeScrubber exited with code $LASTEXITCODE." }
                Write-Host 'Scrubber exited. Verify Installed Apps and licensing state before reinstalling.'
            }; break
        }
        '^Windows(Status|Full|Activate|Rearm|Help)$' {
            $kind=$matches[1]
            Get-CimInstance Win32_OperatingSystem -ErrorAction Stop | Select-Object Caption,BuildNumber,OSArchitecture | Format-List
            if ($kind -eq 'Full') { [void](Invoke-KyuNative cscript.exe @('//nologo',"$env:SystemRoot\System32\slmgr.vbs",'/dlv')) }
            if ($kind -eq 'Help') { Write-Host (Get-KyuLicenseAdvice ''); Start-Process 'ms-settings:activation'; break }
            if ($kind -eq 'Activate') {
                $key=(Read-Host 'Licensed product key (ENTER retries current license)').Trim().ToUpperInvariant()
                if ($key -and -not (Test-KyuProductKey $key)) { throw 'Invalid key format; use XXXXX-XXXXX-XXXXX-XXXXX-XXXXX.' }
                if (-not (Confirm-KyuAction 'Install the supplied key, if any, and request activation from Microsoft/your configured licensing server?')) { return }
                if ($key) { [void](Invoke-KyuNative cscript.exe @('//nologo',"$env:SystemRoot\System32\slmgr.vbs",'/ipk',$key) -Sensitive) }
                $result=Invoke-KyuNative cscript.exe @('//nologo',"$env:SystemRoot\System32\slmgr.vbs",'/ato')
                Write-Host (Get-KyuLicenseAdvice $result.Output)
            }
            if ($kind -eq 'Rearm') {
                if (-not (Confirm-KyuAction 'Request a supported evaluation rearm? Limits vary by product; a restart may be needed')) { return }
                [void](Invoke-KyuNative cscript.exe @('//nologo',"$env:SystemRoot\System32\slmgr.vbs",'/rearm'))
                Write-Host 'Rearm request returned. Restart, then check the actual license status.'
            }
            $licenses=Get-KyuWindowsLicense
            $licenses | Select-Object Name,Description,LicenseStatus,GracePeriodRemaining | Format-Table -Wrap
            if ($kind -eq 'Activate' -and -not @($licenses | Where-Object LicenseStatus -eq 1).Count) { throw 'An activated Windows license was not verified. Review Settings > Activation and the licensing error.' }
            break
        }
        '^Network(Reset|Flush|Winsock|IP|Renew|DNS|Ping|Benchmark|IPv6Off|IPv6On)$' {
            $kind=$matches[1]
            if ($kind -eq 'Flush') { Clear-DnsClientCache -ErrorAction Stop; Write-Host 'DNS cache flush returned.'; break }
            if ($kind -eq 'Ping') {
                $computer=(Read-Host 'Host name or IP').Trim(); if (-not (Test-KyuHostName $computer)) { throw 'Invalid host name.' }
                [void](Invoke-KyuNative ping.exe @('-n','4',$computer)); break
            }
            if ($kind -eq 'Benchmark') {
                foreach ($server in @('8.8.8.8','1.1.1.1','9.9.9.9','208.67.222.222')) {
                    $watch=[Diagnostics.Stopwatch]::StartNew()
                    try { [void](Resolve-DnsName 'www.microsoft.com' -Server $server -DnsOnly -QuickTimeout -ErrorAction Stop); $watch.Stop(); Write-Host "$server DNS query: $($watch.ElapsedMilliseconds) ms" }
                    catch { Write-Warning "$server query failed: $($_.Exception.Message)" }
                }
                Write-Host 'Single uncached/cached queries are indicative only; use repeated measurements for comparison.'; break
            }
            if ($kind -eq 'DNS') {
                $index=Select-KyuAdapter
                $servers=(Read-Host 'DNS server IPs separated by commas (AUTO restores DHCP DNS)').Trim()
                if (-not $servers) { return }
                $parsed=@()
                if ($servers -ne 'AUTO') { foreach ($value in $servers.Split(',')) { $ip=$null; if (-not [Net.IPAddress]::TryParse($value.Trim(),[ref]$ip)) { throw 'Invalid DNS server IP address.' }; $parsed+=$ip.ToString() } }
                if (-not (Confirm-KyuAction 'Change DNS on the selected adapter? Organization/VPN DNS may be required')) { return }
                $backup=Join-Path (Get-KyuBackupDirectory) 'dns.clixml'
                Get-DnsClientServerAddress -InterfaceIndex $index | Export-Clixml -LiteralPath $backup
                Write-Host "Previous DNS addresses: $backup"
                if ($servers -eq 'AUTO') { Set-DnsClientServerAddress -InterfaceIndex $index -ResetServerAddresses -ErrorAction Stop }
                else { Set-DnsClientServerAddress -InterfaceIndex $index -ServerAddresses $parsed -ErrorAction Stop }
                Clear-DnsClientCache -ErrorAction Stop
                Get-DnsClientServerAddress -InterfaceIndex $index | Format-Table; break
            }
            if ($kind -in @('IPv6Off','IPv6On')) {
                Write-Host 'IPv6 is a Windows component dependency. Blanket disabling can break services; diagnose adapters first.'
                $index=Select-KyuAdapter; $adapter=Get-NetAdapter -InterfaceIndex $index -ErrorAction Stop
                $binding=Get-NetAdapterBinding -Name $adapter.Name -ComponentID ms_tcpip6 -ErrorAction Stop
                if (-not (Confirm-KyuAction "Change IPv6 binding on $($adapter.Name)? Current enabled: $($binding.Enabled)")) { return }
                if ($kind -eq 'IPv6Off') { Disable-NetAdapterBinding -Name $adapter.Name -ComponentID ms_tcpip6 -ErrorAction Stop }
                else { Enable-NetAdapterBinding -Name $adapter.Name -ComponentID ms_tcpip6 -ErrorAction Stop }
                Get-NetAdapterBinding -Name $adapter.Name -ComponentID ms_tcpip6 | Format-Table; break
            }
            if (-not (Confirm-KyuAction 'Reset the selected network components? Connections including remote support may disconnect; static IP/VPN configuration may need restoration')) { return }
            $backup=Join-Path (Get-KyuBackupDirectory) 'network.txt'
            Get-NetIPConfiguration | Format-List * | Out-File -LiteralPath $backup -Encoding UTF8
            Write-Host "Network configuration snapshot: $backup"
            if ($kind -in @('Reset','Winsock')) { [void](Invoke-KyuNative netsh.exe @('winsock','reset')) }
            if ($kind -in @('Reset','IP')) { [void](Invoke-KyuNative netsh.exe @('int','ip','reset')) }
            if ($kind -in @('Reset','Renew')) { [void](Invoke-KyuNative ipconfig.exe @('/renew')) }
            Clear-DnsClientCache -ErrorAction Stop
            Write-Host 'Requested commands completed. Firewall rules were retained. Restart if requested and retest connectivity.'; break
        }
        '^Repair(SFC|DISM|Combined|Updates)$' {
            $kind=$matches[1]
            if (-not (Confirm-KyuAction 'Run the selected system repair? Save work; servicing may take a long time')) { return }
            if ($kind -eq 'Updates') { Reset-KyuUpdateCache; break }
            if ($kind -in @('DISM','Combined')) { $result=Invoke-KyuNative dism.exe @('/Online','/Cleanup-Image','/RestoreHealth') -SuccessCodes @(0,3010); if ($result.RebootRequired) { Write-Warning 'DISM requires a restart.' } }
            if ($kind -in @('SFC','Combined')) { [void](Invoke-KyuNative sfc.exe @('/scannow')) }
            Write-Host 'Commands returned. Review their findings above; completed scans can still report unresolved corruption.'; break
        }
        '^CheckDisk$' {
            Write-Host 'Running an online volume scan. Review findings before scheduling an offline repair; /r is not a routine SSD optimization.'
            [void](Invoke-KyuNative chkdsk.exe @($env:SystemDrive,'/scan'))
            Write-Host 'If repairs are recommended, back up data and schedule them with the Windows disk tools.'; break
        }
        '^TempClean$' {
            if (-not (Confirm-KyuAction 'Delete files older than seven days directly inside user and Windows Temp? In-use files will be retained')) { return }
            $removed=0; $skipped=0
            foreach ($directory in @([IO.Path]::GetTempPath(),(Join-Path $env:SystemRoot 'Temp')) | Select-Object -Unique) {
                foreach ($file in @(Get-ChildItem -LiteralPath $directory -File -Force -ErrorAction Stop | Where-Object LastWriteTime -lt (Get-Date).AddDays(-7))) {
                    try { [void](Assert-KyuSafePath $file.FullName $directory); Remove-Item -LiteralPath $file.FullName -Force -ErrorAction Stop; $removed++ } catch { $skipped++ }
                }
            }
            Write-Host "Removed $removed files; retained $skipped locked/protected files. Subfolders, browser sessions, and Prefetch retained."; break
        }
        '^Recycle$' { if (Confirm-KyuAction 'Permanently empty the current user Recycle Bin?') { Clear-RecycleBin -Force -ErrorAction Stop; Write-Host 'Recycle Bin operation completed.' }; break }
        '^ClearLogs$' {
            Write-Host 'Event logs are diagnostic and audit evidence. Export them before clearing; organization retention policies may forbid clearing.'
            if (-not (Confirm-KyuAction 'Export and clear Windows Application and System logs only? Security and other audit channels are retained')) { return }
            $directory=Get-KyuBackupDirectory
            foreach ($channel in @('Application','System')) {
                [void](Invoke-KyuNative wevtutil.exe @('epl',$channel,(Join-Path $directory ($channel+'.evtx'))))
                [void](Invoke-KyuNative wevtutil.exe @('cl',$channel))
            }
            Write-Host "Event backups: $directory"; break
        }
        '^SystemReport$' {
            $report=Join-Path (Get-KyuDesktop) ('OnyxTools_Report_'+(Get-Date -Format 'yyyyMMdd-HHmmss')+'.txt')
            $sections=@(@('OS','Win32_OperatingSystem'),@('CPU','Win32_Processor'),@('RAM','Win32_PhysicalMemory'),@('GPU','Win32_VideoController'),@('DISK','Win32_DiskDrive'))
            "ONYX diagnostic report - $(Get-Date -Format o)" | Set-Content -LiteralPath $report -Encoding UTF8 -ErrorAction Stop
            foreach ($section in $sections) { Add-Content -LiteralPath $report -Value ("`r`n"+$section[0]); Get-CimInstance $section[1] -ErrorAction Stop | Format-List * | Out-File -LiteralPath $report -Append -Encoding UTF8 }
            Get-NetIPConfiguration | Format-List * | Out-File -LiteralPath $report -Append -Encoding UTF8
            Write-Host "Report written: $report. Review personal/device information before sharing."; break
        }
        '^BatteryReport$' { $report=Join-Path (Get-KyuDesktop) 'BatteryReport.html'; [void](Invoke-KyuNative powercfg.exe @('/batteryreport','/output',$report)); if (-not (Test-Path -LiteralPath $report)) { throw 'Battery report was not created.' }; Write-Host $report; break }
        '^Privacy([1-6]|8|Restore|Hosts)$' {
            $kind=$matches[1]
            if ($kind -eq 'Restore') { Restore-KyuRegistryValues; break }
            if ($kind -eq 'Hosts') { Write-Host 'Hosts-file endpoint blocking is not a reliable privacy repair and can interfere with services. Use the backed-up privacy policies instead; existing hosts entries were retained.'; break }
            if (-not (Confirm-KyuAction 'Apply the selected privacy registry policies after saving their exact prior values? Available policy behavior depends on Windows edition')) { return }
            Set-KyuRegistryValues (Get-KyuPrivacySettings ([int]$kind)); Write-Host 'Policy values verified. Sign out/restart if necessary. Services and hosts file were retained.'; break
        }
        '^Power(High|Ultimate)$' { $plan=$matches[1]; if (Confirm-KyuAction "Activate $plan power plan? This can increase heat and battery use") { Set-KyuPowerPlan $plan }; break }
        '^Memory$' { Get-CimInstance Win32_OperatingSystem | Select-Object @{N='FreeGB';E={[math]::Round($_.FreePhysicalMemory/1MB,2)}},@{N='TotalGB';E={[math]::Round($_.TotalVisibleMemorySize/1MB,2)}} | Format-Table; Get-Process | Sort-Object WorkingSet64 -Descending | Select-Object -First 10 Name,Id,@{N='WorkingSetMB';E={[math]::Round($_.WorkingSet64/1MB)}} | Format-Table; Write-Host 'Review high-memory apps and close them normally. Garbage collection does not clear system standby RAM.'; break }
        '^Performance(Visual|Startup|Search|SysMain|Xbox|Game|All)$' {
            $kind=$matches[1]
            if ($kind -in @('Search','SysMain')) {
                $name=if($kind -eq 'Search'){'WSearch'}else{'SysMain'}
                Write-Host "Temporarily stopping $name can reduce search/prefetch performance. Startup configuration will be retained."
                if (Confirm-KyuAction 'Temporarily stop this service for comparison? Restart Windows to resume its configured behavior') { Stop-Service $name -ErrorAction Stop; if ((Get-Service $name).Status -ne 'Stopped') { throw 'Service has not stopped.' } }; break
            }
            if (-not (Confirm-KyuAction 'Apply the selected UI/gaming preferences with an exact registry backup? No service, GPU scheduling, or CPU-priority changes are included')) { return }
            $settings=@()
            if ($kind -in @('Visual','All')) { $settings += [pscustomobject]@{Path='HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects';Name='VisualFXSetting';Value=2;Kind='DWord'} }
            if ($kind -in @('Startup','All')) { $settings += [pscustomobject]@{Path='HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Serialize';Name='StartupDelayInMSec';Value=0;Kind='DWord'} }
            if ($kind -in @('Xbox','All')) { $settings += [pscustomobject]@{Path='HKCU:\System\GameConfigStore';Name='GameDVR_Enabled';Value=0;Kind='DWord'} }
            if ($kind -in @('Game','All')) { $settings += [pscustomobject]@{Path='HKCU:\Software\Microsoft\GameBar';Name='AutoGameModeEnabled';Value=1;Kind='DWord'} }
            Set-KyuRegistryValues $settings; Write-Host 'Requested preference values verified. Log out or restart to apply.'; break
        }
        '^Disk(Hash|Ownership|Optimize|Largest|Link|Hidden|Hide)$' {
            $kind=$matches[1]
            if ($kind -eq 'Hash') { $path=(Read-Host 'Full file path').Trim('"'); Get-FileHash -LiteralPath $path -Algorithm SHA256 -ErrorAction Stop | Format-List; break }
            if ($kind -in @('Hidden','Hide')) {
                $value=if($kind -eq 'Hidden'){1}else{2}
                if (Confirm-KyuAction 'Change Explorer hidden-file visibility for the current user? Protected OS files remain hidden') { Set-KyuRegistryValues @([pscustomobject]@{Path='HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced';Name='Hidden';Value=$value;Kind='DWord'}) }; break
            }
            if ($kind -eq 'Largest') {
                $path=(Read-Host 'Folder to scan (use a specific folder, not every attached drive)').Trim('"')
                $item=Get-Item -LiteralPath $path -ErrorAction Stop
                if (-not $item.PSIsContainer -or $item.Attributes -band [IO.FileAttributes]::ReparsePoint) { throw 'Select an ordinary directory.' }
                Get-ChildItem -LiteralPath $path -File -Recurse -ErrorAction SilentlyContinue | Sort-Object Length -Descending | Select-Object -First 20 FullName,@{N='SizeMB';E={[math]::Round($_.Length/1MB,2)}} | Format-Table -Wrap
                Write-Host 'Results cover readable files only. Access-denied files may be absent.'; break
            }
            if ($kind -eq 'Optimize') {
                $letter=(Read-Host 'Drive letter').Trim().TrimEnd(':')
                if ($letter -notmatch '^[A-Za-z]$') { throw 'Enter one drive letter.' }
                [void](Invoke-KyuNative defrag.exe @(($letter+':'),'/A','/U','/V'))
                if (Confirm-KyuAction 'Let Windows select the appropriate media optimization (including SSD retrim)?') { [void](Invoke-KyuNative defrag.exe @(($letter+':'),'/O','/U','/V')) }; break
            }
            if ($kind -eq 'Link') {
                $target=(Get-Item -LiteralPath (Read-Host 'Existing target path').Trim('"') -ErrorAction Stop).FullName
                $link=[IO.Path]::GetFullPath((Read-Host 'New link path').Trim('"'))
                if (Test-Path -LiteralPath $link) { throw 'Link path already exists.' }
                if (Confirm-KyuAction 'Create the symbolic link?') { New-Item -ItemType SymbolicLink -Path $link -Target $target -ErrorAction Stop | Format-List }; break
            }
            $path=(Get-Item -LiteralPath (Read-Host 'Exact file/folder path to change ownership').Trim('"') -ErrorAction Stop).FullName
            [void](Assert-KyuSafePath $path (Split-Path $path -Parent))
            if ($path.TrimEnd('\') -eq [IO.Path]::GetPathRoot($path).TrimEnd('\') -or $path.StartsWith($env:SystemRoot,[StringComparison]::OrdinalIgnoreCase)) { throw 'Do not use this tool to change ownership of Windows or a drive root.' }
            if (-not (Confirm-KyuAction 'Change ownership of this object only (not its children) and grant the current account full control?')) { return }
            $backup=Join-Path (Get-KyuBackupDirectory) 'permissions.clixml'
            [pscustomobject]@{Path=$path;Sddl=(Get-Acl -LiteralPath $path -ErrorAction Stop).Sddl} | Export-Clixml -LiteralPath $backup
            [void](Invoke-KyuNative takeown.exe @('/f',$path))
            $sid=[Security.Principal.WindowsIdentity]::GetCurrent().User.Value
            [void](Invoke-KyuNative icacls.exe @($path,'/grant',("*$sid"+':F')))
            Write-Host "Ownership/permission commands completed for this object. Prior descriptor: $backup"; break
        }
        '^Help(BIOS|Explorer|GPO|SafeOn|SafeOff|Apps)$' {
            $kind=$matches[1]
            if ($kind -eq 'Explorer') { if (Confirm-KyuAction 'Restart Explorer for this session? File windows will close') { $session=(Get-Process -Id $PID).SessionId; Get-Process explorer -ErrorAction SilentlyContinue | Where-Object SessionId -eq $session | Stop-Process -ErrorAction Stop; Start-Process explorer.exe -ErrorAction Stop }; break }
            if ($kind -eq 'Apps') {
                Write-Host 'Use Settings > Apps > Installed apps > Advanced options > Repair for the affected app. Reset can erase app data.'
                Start-Process 'ms-settings:appsfeatures'; break
            }
            if ($kind -eq 'GPO') {
                if ((Get-CimInstance Win32_ComputerSystem -ErrorAction Stop).PartOfDomain) { throw 'This PC is domain joined. Ask the domain administrator to repair policy; local policy files were retained.' }
                if (Confirm-KyuAction 'Refresh policy without deleting its configuration?') { [void](Invoke-KyuNative gpupdate.exe @('/force')) }; break
            }
            if (-not (Confirm-KyuAction 'Change boot behavior? Save work and have the BitLocker recovery key and account password available')) { return }
            if ($kind -eq 'BIOS') { [void](Invoke-KyuNative shutdown.exe @('/r','/fw','/t','30')) }
            if ($kind -eq 'SafeOn') { [void](Invoke-KyuNative bcdedit.exe @('/set','{current}','safeboot','minimal')); Write-Host 'Safe Mode configured for next restart. Use Exit Safe Mode to restore normal boot.' }
            if ($kind -eq 'SafeOff') { [void](Invoke-KyuNative bcdedit.exe @('/deletevalue','{current}','safeboot')) }; break
        }
        '^Remote(Enable|Ping|Share|Manage)$' {
            $kind=$matches[1]
            if ($kind -eq 'Enable') {
                $edition=(Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -ErrorAction Stop).EditionID
                if ($edition -match '^Core|^Starter|Home') { throw 'This Windows edition does not include the supported incoming RDP host. Use Quick Assist instead.' }
                if (-not (Confirm-KyuAction 'Enable incoming Remote Desktop with Network Level Authentication on Private/Domain networks?')) { return }
                Set-KyuRegistryValues @([pscustomobject]@{Path='HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server';Name='fDenyTSConnections';Value=0;Kind='DWord'},[pscustomobject]@{Path='HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp';Name='UserAuthentication';Value=1;Kind='DWord'})
                Get-NetFirewallRule -Name 'RemoteDesktop-*' -ErrorAction Stop | Set-NetFirewallRule -Profile Private,Domain -Enabled True -ErrorAction Stop
                [void](Start-KyuService TermService)
                Write-Host 'RDP configuration applied. Verify authorized-user access, firewall policy, and network reachability from the client.'; break
            }
            $computer=(Read-Host 'Host name or IP').Trim(); if (-not (Test-KyuHostName $computer)) { throw 'Invalid host name.' }
            if ($kind -eq 'Ping') { [void](Invoke-KyuNative ping.exe @('-n','4',$computer)) }
            if ($kind -eq 'Share') { Start-Process explorer.exe -ArgumentList "\\$computer\c$" }
            if ($kind -eq 'Manage') { Start-Process compmgmt.msc -ArgumentList "/computer=\\$computer" }; break
        }
        '^RdpHistory$' { Get-WinEvent -FilterHashtable @{LogName='Microsoft-Windows-TerminalServices-RemoteConnectionManager/Operational';Id=1149} -MaxEvents 30 -ErrorAction Stop | Format-List TimeCreated,Id,Message; break }
        '^AccountUnlock$' { $name=(Read-Host 'Local username (domain accounts require the domain administrator)').Trim(); if (Confirm-KyuAction "Clear the local lockout flag for $name without changing its password or enabled state?") { Unlock-KyuLocalAccount $name }; break }
        '^DataBackup$' {
            $source=(Get-Item -LiteralPath (Read-Host 'Existing source directory').Trim('"') -ErrorAction Stop).FullName
            $destination=[IO.Path]::GetFullPath((Read-Host 'Destination backup directory').Trim('"'))
            [void](Assert-KyuBackupPaths $source $destination)
            if (-not (Get-Item -LiteralPath $source).PSIsContainer) { throw 'Source must be a directory.' }
            # Refuse root-level reparse targets; robocopy /XJ excludes junctions below them.
            [void](Assert-KyuSafePath $source (Split-Path $source -Parent))
            [void](Assert-KyuSafePath $destination (Split-Path $destination -Parent))
            Write-Host 'Copy mode retains the source and does not mirror deletions. EFS-encrypted files need their encryption certificate; cloud placeholders may need downloading first.'
            if (-not (Confirm-KyuAction "Copy $source to $destination? Existing destination files may be updated")) { return }
            [void](Invoke-KyuNative robocopy.exe @($source,$destination,'/E','/XJ','/R:1','/W:1','/COPY:DAT','/DCOPY:DAT') -SuccessCodes @(0,1,2,3,4,5,6,7))
            Write-Host 'Robocopy returned without a failure exit code. Review skipped/mismatched files and verify important backup data.'; break
        }
        '^WinUtil$' {
            Write-Host 'WinUtil is an external administrator utility. Review its downloaded source before execution.'
            if (-not (Confirm-KyuAction 'Download the Chris Titus WinUtil script to a local review file?')) { return }
            $directory=Get-KyuBackupDirectory; $file=Join-Path $directory 'WinUtil.ps1'
            [Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12
            Invoke-WebRequest 'https://christitus.com/win' -OutFile $file -UseBasicParsing -ErrorAction Stop
            $tokens=$null;$issues=$null;[void][Management.Automation.Language.Parser]::ParseFile($file,[ref]$tokens,[ref]$issues)
            if (@($issues).Count) { throw 'Downloaded content is not a parseable PowerShell script; it was not executed.' }
            Get-FileHash -LiteralPath $file | Format-List
            Start-Process notepad.exe -ArgumentList ('"'+$file+'"') -Wait
            if (Confirm-KyuAction 'Execute the reviewed external script as administrator? Its contents can change your PC') { & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $file; if ($LASTEXITCODE -ne 0) { throw "WinUtil process returned $LASTEXITCODE." } }; break
        }
        default { throw "Unknown toolkit action: $SelectedAction" }
    }
}
if ($MyInvocation.InvocationName -ne '.') {
    $ErrorActionPreference='Stop'
    try {
        Assert-KyuAdministrator
        Write-KyuLog "Starting action $Action"
        Invoke-KyuSystemAction $Action
        Write-KyuLog "Action $Action returned"
        exit 0
    } catch {
        Write-Host $_.Exception.Message -ForegroundColor Red
        Write-KyuLog "Action $Action failed; review console details." 'ERROR'
        exit 1
    }
}
