param()
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$script:passed = 0
$script:failed = 0
function Assert-Equal($Actual, $Expected) {
    if ($Actual -ne $Expected) { throw "Expected '$Expected', received '$Actual'." }
}
function Assert-Throws([scriptblock]$Action) {
    $thrown = $false
    try { & $Action | Out-Null } catch { $thrown = $true }
    if (-not $thrown) { throw 'Expected an exception.' }
}
function Test-Case([string]$Name, [scriptblock]$Action) {
    try { & $Action; $script:passed++; Write-Host "PASS $Name" -ForegroundColor Green }
    catch { $script:failed++; Write-Host "FAIL $Name : $($_.Exception.Message)" -ForegroundColor Red }
}
function Import-Function([string]$File, [string]$Name) {
    $tokens = $null; $issues = $null
    $ast = [Management.Automation.Language.Parser]::ParseFile((Join-Path $root $File), [ref]$tokens, [ref]$issues)
    $node = $ast.Find({ param($n) $n -is [Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -eq $Name }, $true)
    if (-not $node) { throw "Missing function: $Name" }
    . ([scriptblock]::Create($node.Extent.Text.Replace("function $Name", "function script:$Name")))
}

Test-Case 'Problem matcher recognizes a supported printer description' {
    Import-Function 'modules/troubleshoot.ps1' 'Find-Problem'
    $Problems = @(@{Keywords=@('printer');Title='Printer Not Working'})
    Assert-Equal (Find-Problem -ProblemText 'printer offline').Title 'Printer Not Working'
}
Test-Case 'Problem matcher chooses specific app crash before generic crash' {
    Import-Function 'modules/troubleshoot.ps1' 'Find-Problem'
    $Problems = @(@{Keywords=@('crash');Title='BSOD'}, @{Keywords=@('app crash');Title='Application'})
    Assert-Equal (Find-Problem -ProblemText 'app crash').Title 'Application'
}
Test-Case 'Printer policy error 1260 is not module error 126' {
    Import-Function 'modules/printer_core.ps1' 'Format-PrinterError'
    Assert-Equal (Format-PrinterError -RawError 'Error 1260: blocked by policy').Category 'Policy'
}
Test-Case 'Printer credentials conflict is actionable' {
    Import-Function 'modules/printer_core.ps1' 'Format-PrinterError'
    Assert-Equal (Format-PrinterError -RawError 'Error 1219: Multiple connections').Category 'CredentialsConflict'
}
Test-Case 'Printer HRESULT access denied is recognized' {
    Import-Function 'modules/printer_core.ps1' 'Format-PrinterError'
    Assert-Equal (Format-PrinterError -RawError '0x80070005').Category 'Access'
}
Test-Case 'Native helper rejects an actual failing process' {
    . (Join-Path $root 'modules/common.ps1')
    function Write-KyuLog { param($Message,$Level) }
    Assert-Throws { Invoke-KyuNative -FilePath $env:ComSpec -Arguments @('/d','/c','exit 7') }
}
Test-Case 'Native helper accepts explicitly allowed reboot status' {
    . (Join-Path $root 'modules/common.ps1')
    function Write-KyuLog { param($Message,$Level) }
    Assert-Equal (Invoke-KyuNative -FilePath $env:ComSpec -Arguments @('/d','/c','exit 3') -SuccessCodes @(0,3)).ExitCode 3
}
Test-Case 'Host validation rejects command injection and accepts DNS and IPv4' {
    . (Join-Path $root 'modules/common.ps1')
    Assert-Equal (Test-KyuHostName 'office-pc.example.local') $true
    Assert-Equal (Test-KyuHostName '192.168.1.10') $true
    foreach ($bad in @('pc&calc','pc;whoami','pc/queue','-server','999.999.1.1','')) {
        Assert-Equal (Test-KyuHostName $bad) $false
    }
}
Test-Case 'UNC resolver refuses ambiguous printer names' {
    . (Join-Path $root 'modules/printer_core.ps1')
    $printers=@([pscustomobject]@{ShareName='Office';Path='\\HOST1\Office'},[pscustomobject]@{ShareName='Office';Path='\\HOST2\Office'})
    Assert-Throws { Resolve-KyuPrinterTarget 'Office' $printers }
    Assert-Equal (Resolve-KyuPrinterTarget '2' $printers) '\\HOST2\Office'
    Assert-Equal (Resolve-KyuPrinterTarget '\\HOST1\Office' $printers) '\\HOST1\Office'
}
Test-Case 'UNC resolver rejects malformed and executable host input' {
    . (Join-Path $root 'modules/printer_core.ps1')
    foreach ($bad in @('\\pc&calc\office','\\pc\share\file','\\pc\share.','http://printer')) {
        Assert-Throws { Resolve-KyuPrinterTarget $bad }
    }
}
Test-Case 'Connection is not successful merely because Add-Printer returned' {
    . (Join-Path $root 'modules/printer_core.ps1')
    function Get-Printer { param($ErrorAction) return @() }
    function Add-Printer { param($ConnectionName,$ErrorAction) }
    function Write-KyuLog { param($Message,$Level) }
    if (-not (Connect-PrinterTarget '\\host\Office')) { throw 'Unverified connection reported success.' }
}
Test-Case 'Connection recognizes an existing exact printer without reinstalling' {
    . (Join-Path $root 'modules/printer_core.ps1')
    function Get-Printer { param($ErrorAction) [pscustomobject]@{Name='\\host\Office';ComputerName='host';ShareName='Office'} }
    function Add-Printer { throw 'Existing connection should not be installed again.' }
    function Write-KyuLog { param($Message,$Level) }
    Assert-Equal (Connect-PrinterTarget '\\host\Office') $null
}
Test-Case 'Spooler restart failure is surfaced to the caller' {
    . (Join-Path $root 'modules/printer_core.ps1')
    function Assert-KyuAdministrator {}
    function Get-Service { param($Name,$ErrorAction) [pscustomobject]@{Status='Running'} }
    function Restart-Service { param($Name,$Force,$ErrorAction) throw 'Service denied' }
    Assert-Throws { Restart-KyuSpooler }
}
Test-Case 'Office 2024 uses the documented volume product and channel' {
    Import-Function 'modules/system_tools.ps1' 'Get-KyuOfficeConfiguration'
    [xml]$xml=Get-KyuOfficeConfiguration -Edition '2024' -Architecture '64'
    Assert-Equal $xml.Configuration.Add.Channel 'PerpetualVL2024'
    Assert-Equal $xml.Configuration.Add.Product.ID 'ProPlus2024Volume'
    Assert-Equal $xml.Configuration.Add.OfficeClientEdition '64'
}
Test-Case 'Office configuration rejects unknown editions and architectures' {
    Import-Function 'modules/system_tools.ps1' 'Get-KyuOfficeConfiguration'
    Assert-Throws { Get-KyuOfficeConfiguration -Edition 'unknown' -Architecture '64' }
    Assert-Throws { Get-KyuOfficeConfiguration -Edition '2024' -Architecture '128' }
}
Test-Case 'Product key validation rejects malformed or executable values' {
    Import-Function 'modules/system_tools.ps1' 'Test-KyuProductKey'
    Assert-Equal (Test-KyuProductKey 'AAAAA-BBBBB-CCCCC-DDDDD-EEEEE') $true
    Assert-Equal (Test-KyuProductKey 'AAAAA-BBBBB-CCCCC-DDDDD-EEEEE & calc') $false
    Assert-Equal (Test-KyuProductKey '123') $false
}
Test-Case 'Missing executable cannot reuse a previous successful exit code' {
    . (Join-Path $root 'modules/common.ps1')
    function Write-KyuLog { param($Message,$Level) }
    $global:LASTEXITCODE=0
    Assert-Throws { Invoke-KyuNative 'KyuTools_missing_executable_972.exe' }
}
Test-Case 'Power plan activation uses the new GUID, not the template GUID' {
    Import-Function 'modules/system_tools.ps1' 'Set-KyuPowerPlan'
    function Invoke-KyuNative {
        param($FilePath,$Arguments)
        switch ($Arguments[0]) {
            '/duplicatescheme' { return [pscustomobject]@{Output='Power Scheme GUID: 11111111-2222-3333-4444-555555555555';ExitCode=0} }
            '/setactive' { if ($Arguments[1] -ne '11111111-2222-3333-4444-555555555555') { throw 'Wrong plan activated.' }; return [pscustomobject]@{Output='';ExitCode=0} }
            '/getactivescheme' { return [pscustomobject]@{Output='11111111-2222-3333-4444-555555555555';ExitCode=0} }
            default { throw 'Unexpected powercfg action.' }
        }
    }
    Set-KyuPowerPlan 'Ultimate'
}
Test-Case 'Backup rejects source/destination containment in both directions' {
    Import-Function 'modules/system_tools.ps1' 'Assert-KyuBackupPaths'
    Assert-Throws { Assert-KyuBackupPaths 'C:\Users\Alice' 'C:\Users\Alice\Backup' }
    Assert-Throws { Assert-KyuBackupPaths 'C:\Users\Alice\Documents' 'C:\Users\Alice' }
    Assert-Equal (Assert-KyuBackupPaths 'C:\Users\Alice' 'E:\Backup\Alice') $true
}
Test-Case 'Backup path guard rejects roots and directory traversal' {
    . (Join-Path $root 'modules/common.ps1')
    Assert-Throws { Assert-KyuSafePath $root $root }
    Assert-Throws { Assert-KyuSafePath (Join-Path $root '..\outside') $root }
    Assert-Equal (Assert-KyuSafePath (Join-Path $root 'tests\fixture') $root) (Join-Path $root 'tests\fixture')
}
Test-Case 'Subnet discovery honors a small subnet and excludes local IP' {
    . (Join-Path $root 'modules/common.ps1')
    $range=Get-KyuIPv4Targets '192.168.4.10' 29
    Assert-Equal ($range.Targets -join ',') '192.168.4.9,192.168.4.11,192.168.4.12,192.168.4.13,192.168.4.14'
    Assert-Equal $range.Limited $false
}
Test-Case 'Subnet discovery bounds large scans and says they are partial' {
    . (Join-Path $root 'modules/common.ps1')
    $range=Get-KyuIPv4Targets '10.20.30.10' 16
    Assert-Equal $range.Limited $true
    if ($range.Targets.Count -gt 254 -or $range.Targets -contains '10.20.30.10') { throw 'Unbounded or self-targeting scan.' }
}
Test-Case 'Problem solver reports a skipped action without executing it' {
    Import-Function 'modules/troubleshoot.ps1' 'Run-Step'
    function Ask-Confirm { return $false }; function Write-Skip { param($Msg) }; function Write-Step {param($Num,$Desc)}
    Assert-Equal (Run-Step -Num 1 -Desc 'test' -Action { throw 'must not run' }).Status 'Skipped'
}
Test-Case 'Problem solver reports terminating action failure honestly' {
    Import-Function 'modules/troubleshoot.ps1' 'Run-Step'
    function Ask-Confirm { return $true }; function Write-Step {param($Num,$Desc)}; function Write-Fail {param($Msg)}; function Write-KyuLog {param($Message,$Level)}
    Assert-Equal (Run-Step -Num 1 -Desc 'test' -Action { throw 'repair failed' }).Status 'Failed'
}
Test-Case 'Printer error decoder uses inner Win32 HRESULT before generic CLR HRESULT' {
    Import-Function 'modules/printer_core.ps1' 'Format-PrinterError'
    Assert-Equal (Format-PrinterError '0x80131500: failed with 0x80070005').Category 'Access'
}
Test-Case 'Discovery preserves identical share names on separate hosts' {
    . (Join-Path $root 'modules/printer_core.ps1')
    function Get-Printer { param($ErrorAction) @([pscustomobject]@{Name='\\ONE\Office';DriverName='Driver'},[pscustomobject]@{Name='\\TWO\Office';DriverName='Driver'}) }
    function Get-NetNeighbor { param($AddressFamily,$ErrorAction) @() }
    $result=Get-NetworkSharedPrinters
    Assert-Equal $result.Printers.Count 2
    Assert-Equal ($result.Printers.Path -join ',') '\\ONE\Office,\\TWO\Office'
}
Test-Case 'Queue cleanup restores spooler when a queue file cannot be removed' {
    . (Join-Path $root 'modules/printer_core.ps1')
    function Assert-KyuAdministrator {}
    function Assert-KyuSafePath { param($Path,$AllowedRoot) 'C:\KyuMock\PRINTERS' }
    function Get-KyuStandardSpoolDirectory { 'C:\KyuMock\PRINTERS' }
    function Get-Service { param($Name,$ErrorAction) $value=[pscustomobject]@{Status='Running'}; $value | Add-Member ScriptMethod WaitForStatus {param($Status,$Timeout)}; $value }
    function Stop-Service { param($Name,[switch]$Force,$ErrorAction) }
    function Get-ChildItem { param($LiteralPath,[switch]$File,[switch]$Force,$ErrorAction) [pscustomobject]@{Extension='.SPL';FullName='C:\KyuMock\PRINTERS\test.SPL'} }
    function Remove-Item { param($LiteralPath,[switch]$Force,$ErrorAction) throw 'Queue file locked' }
    $script:restored=$false
    function Start-KyuService { param($Name) $script:restored=$true; [pscustomobject]@{Status='Running'} }
    Assert-Throws { Restart-KyuSpooler -ClearQueue }
    Assert-Equal $script:restored $true
}
Test-Case 'TCP probe distinguishes open and refused loopback connections' {
    . (Join-Path $root 'modules/common.ps1')
    $listener=[Net.Sockets.TcpListener]::new([Net.IPAddress]::Loopback,0)
    $listener.Start()
    $port=$listener.LocalEndpoint.Port
    try { Assert-Equal (Test-KyuTcpPort '127.0.0.1' $port 500) $true }
    finally { $listener.Stop() }
    Assert-Equal (Test-KyuTcpPort '127.0.0.1' $port 500) $false
}
Test-Case 'Registry privacy settings retain per-setting structure' {
    Import-Function 'modules/system_tools.ps1' 'Get-KyuPrivacySettings'
    $single=@(Get-KyuPrivacySettings 1)
    Assert-Equal $single.Count 1
    Assert-Equal $single[0].Name 'AllowTelemetry'
    $all=@(Get-KyuPrivacySettings 8)
    Assert-Equal $all.Count 6
    Assert-Equal $all[4].Value 1
}
Test-Case 'Update cache failure still restores every originally running service' {
    . (Join-Path $root 'modules/system_tools.ps1')
    $script:restarted=@()
    function Get-Service { param($Name,$ErrorAction) $state=if($Name -eq 'bits'){'Stopped'}else{'Running'}; $item=[pscustomobject]@{Status=$state}; $item | Add-Member ScriptMethod WaitForStatus {param($Status,$Timeout)}; $item }
    function Stop-Service { param($Name,[switch]$Force,$ErrorAction) }
    function Start-KyuService { param($Name) $script:restarted+=$Name; [pscustomobject]@{Status='Running'} }
    function Assert-KyuSafePath { param($Path,$AllowedRoot) $Path }
    function Test-Path { param($LiteralPath) $true }
    function Rename-Item { param($LiteralPath,$NewName,$ErrorAction) throw 'Rename failed' }
    Assert-Throws { Reset-KyuUpdateCache }
    Assert-Equal ($script:restarted -join ',') 'wuauserv,cryptsvc'
}
Test-Case 'Direct IP driver failure removes only its newly created unused port' {
    . (Join-Path $root 'modules/printer_tools.ps1')
    function Assert-KyuAdministrator {}
    function Confirm-KyuAction { $true }
    function Test-KyuTcpPort {param($ComputerName,$Port) $true}
    $script:answers=[Collections.Generic.Queue[string]]::new()
    foreach ($answer in @('192.168.1.77','1','Office')) { $script:answers.Enqueue($answer) }
    function Read-Host { param($Prompt) $script:answers.Dequeue() }
    function Get-Printer {param($ErrorAction) @()}
    function Get-PrinterDriver {param($ErrorAction) [pscustomobject]@{Name='SignedDriver'}}
    function Get-PrinterPort {param($ErrorAction) @()}
    function Add-PrinterPort {param($Name,$PrinterHostAddress,$PortNumber,$ErrorAction)}
    function Add-Printer {param($Name,$DriverName,$PortName,$ErrorAction) throw 'Driver rejected'}
    $script:removedPort=$null
    function Remove-PrinterPort {param($Name,$ErrorAction) $script:removedPort=$Name}
    Assert-Throws { Add-KyuDirectPrinter }
    Assert-Equal $script:removedPort 'KyuTCP_192.168.1.77'
}
Test-Case 'Interactive native execution still rejects a nonzero exit' {
    . (Join-Path $root 'modules/common.ps1')
    function Write-KyuLog {param($Message,$Level)}
    Assert-Throws { Invoke-KyuNative $env:ComSpec @('/d','/c','exit 9') -Interactive }
}
Test-Case 'Backup safety rejects a junction above the immediate parent' {
    . (Join-Path $root 'modules/common.ps1')
    function Test-Path {param($LiteralPath) $true}
    function Get-Item {param($LiteralPath,[switch]$Force,$ErrorAction) $attributes=[IO.FileAttributes]::Directory; if ($LiteralPath -eq 'C:\Alias') { $attributes=$attributes -bor [IO.FileAttributes]::ReparsePoint }; [pscustomobject]@{Attributes=$attributes}}
    Assert-Throws { Assert-KyuSafePath 'C:\Alias\Nested\Backup' 'C:\Alias\Nested' }
}
Test-Case 'Custom global spool path is refused before cleanup' {
    Import-Function 'modules/printer_core.ps1' 'Get-KyuStandardSpoolDirectory'
    function Get-ItemProperty {param($LiteralPath,$ErrorAction) [pscustomobject]@{DefaultSpoolDirectory='D:\PrintQueue'}}
    function Get-ChildItem {param($LiteralPath,$ErrorAction) @()}
    Assert-Throws { Get-KyuStandardSpoolDirectory }
}
Test-Case 'Per-printer custom spool path is refused before cleanup' {
    Import-Function 'modules/printer_core.ps1' 'Get-KyuStandardSpoolDirectory'
    function Get-ItemProperty {param($LiteralPath,$ErrorAction) if ($LiteralPath -eq 'HKLM:\SYSTEM\CurrentControlSet\Control\Print\Printers\Office') { [pscustomobject]@{SpoolDirectory='D:\OfficeQueue'} } else { [pscustomobject]@{DefaultSpoolDirectory=$null} } }
    function Get-ChildItem {param($LiteralPath,$ErrorAction) [pscustomobject]@{PSPath='HKLM:\SYSTEM\CurrentControlSet\Control\Print\Printers\Office'}}
    Assert-Throws { Get-KyuStandardSpoolDirectory }
}
Test-Case 'Audio repair restores services in dependency order after stop failure' {
    Import-Function 'modules/system_tools.ps1' 'Restart-KyuAudioServices'
    function Get-Service {param($Name,$ErrorAction) $item=[pscustomobject]@{Status='Running'}; $item | Add-Member ScriptMethod WaitForStatus {param($Status,$Timeout)}; $item }
    function Stop-Service {param($Name,$ErrorAction) if ($Name -eq 'AudioEndpointBuilder') { throw 'Dependent service blocks stop' }}
    $script:audioStarts=@()
    function Start-KyuService {param($Name) $script:audioStarts+=$Name; [pscustomobject]@{Status='Running'}}
    Assert-Throws { Restart-KyuAudioServices }
    Assert-Equal ($script:audioStarts -join ',') 'AudioEndpointBuilder,Audiosrv'
}
Test-Case 'Scanner distinguishes a NetBIOS identity hint from an observed session' {
    Import-Function 'modules/network_scan.ps1' 'Format-KyuIdentityObservation'
    Assert-Equal (Format-KyuIdentityObservation 'alice' 'Get-ViaNBNS') 'alice (NBNS hint; unverified)'
    Assert-Equal (Format-KyuIdentityObservation 'alice' 'Get-ViaQUser') 'alice (quser report)'
    Assert-Equal (Format-KyuIdentityObservation '' '') 'Unavailable (not verified)'
}
Test-Case 'Changing one registry preference does not recreate an existing registry key' {
    . (Join-Path $root 'modules/system_tools.ps1')
    $script:preference=42
    function Get-Item {param($LiteralPath,$ErrorAction) $item=[pscustomobject]@{}; $item | Add-Member ScriptMethod GetValueNames { @('Preference') }; $item | Add-Member ScriptMethod GetValue {param($Name,$Default,$Options) $script:preference}; $item | Add-Member ScriptMethod GetValueKind {param($Name) [Microsoft.Win32.RegistryValueKind]::DWord}; $item }
    function Test-Path {param($LiteralPath) $true}
    function Get-KyuBackupDirectory { 'C:\MockBackup' }
    function Export-Clixml {param($LiteralPath,[Parameter(ValueFromPipeline=$true)]$InputObject)}
    function New-Item {param($Path,[switch]$Force,$ErrorAction) throw 'Existing key must not be recreated.'}
    function New-ItemProperty {param($LiteralPath,$Name,$Value,$PropertyType,[switch]$Force,$ErrorAction) $script:preference=$Value}
    function Get-ItemPropertyValue {param($LiteralPath,$Name,$ErrorAction) $script:preference}
    Set-KyuRegistryValues @([pscustomobject]@{Path='HKCU:\Mock';Name='Preference';Value=7;Kind='DWord'})
    Assert-Equal $script:preference 7
}
Write-Host ("Results: {0} passed, {1} failed" -f $script:passed,$script:failed)
if ($script:failed) { exit 1 }
