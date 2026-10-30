# Shared helpers. Dot-sourcing this file performs no repairs or filesystem writes.
function Test-KyuAdministrator {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    return ([Security.Principal.WindowsPrincipal]::new($identity)).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}
function Assert-KyuAdministrator {
    if (-not (Test-KyuAdministrator)) { throw 'Run KyuTools as administrator to perform this action.' }
}
function Confirm-KyuAction {
    param([string]$Message)
    return ((Read-Host "$Message [type YES to proceed]") -ceq 'YES')
}
function Write-KyuLog {
    param([string]$Message, [string]$Level = 'INFO')
    try {
        $base = [Environment]::GetFolderPath('LocalApplicationData')
        if (-not $base) { $base = [IO.Path]::GetTempPath() }
        $directory = Join-Path $base 'KyuTools\Logs'
        [void][IO.Directory]::CreateDirectory($directory)
        $path = Join-Path $directory ((Get-Date -Format 'yyyy-MM-dd') + '.log')
        Add-Content -LiteralPath $path -Value ('{0:o} [{1}] {2}' -f (Get-Date),$Level,$Message) -Encoding UTF8 -ErrorAction Stop
    } catch { Write-Warning 'Could not write the operation log.' }
}
function Invoke-KyuNative {
    param(
        [Parameter(Mandatory=$true)][string]$FilePath,
        [string[]]$Arguments = @(),
        [int[]]$SuccessCodes = @(0),
        [switch]$Sensitive,
        [switch]$Interactive
    )
    [void](Get-Command -Name $FilePath -CommandType Application -ErrorAction Stop)
    $savedPreference = $ErrorActionPreference
    try {
        # PS 5.1 turns redirected native stderr into ErrorRecords. Capture them
        # and decide success using the process exit code, not stream selection.
        $ErrorActionPreference = 'Continue'
        $lines = [Collections.Generic.List[string]]::new()
        if ($Interactive) {
            & $FilePath @Arguments | Out-Host
        } else {
            & $FilePath @Arguments 2>&1 | ForEach-Object {
                $line="$_"
                $lines.Add($line)
                Write-Host $line
            }
        }
        $code = $LASTEXITCODE
    } finally { $ErrorActionPreference = $savedPreference }
    if ($null -eq $code) { throw "Could not obtain an exit code from $FilePath." }
    $content = $lines.ToArray() -join [Environment]::NewLine
    if (-not $Sensitive) { Write-KyuLog "Native $([IO.Path]::GetFileName($FilePath)): exit $code" }
    if ($code -notin $SuccessCodes) { throw "$([IO.Path]::GetFileName($FilePath)) exited with code $code. Review the output above." }
    return [pscustomobject]@{ ExitCode=$code; Output=$content; RebootRequired=($code -in @(3010,1641)) }
}
function Test-KyuHostName {
    param([AllowEmptyString()][string]$ComputerName)
    if ([string]::IsNullOrWhiteSpace($ComputerName) -or $ComputerName.Length -gt 253) { return $false }
    if ($ComputerName -match '^\d+(\.\d+){3}$') {
        $address = $null
        return [Net.IPAddress]::TryParse($ComputerName, [ref]$address)
    }
    return ($ComputerName -match '^(?=.{1,253}$)[A-Za-z0-9](?:[A-Za-z0-9-]*[A-Za-z0-9])?(?:\.[A-Za-z0-9](?:[A-Za-z0-9-]*[A-Za-z0-9])?)*$')
}
function Test-KyuTcpPort {
    param([string]$ComputerName, [int]$Port, [int]$TimeoutMs = 1200)
    if (-not (Test-KyuHostName $ComputerName)) { return $false }
    $client = [Net.Sockets.TcpClient]::new()
    $pending = $null
    try {
        $pending = $client.BeginConnect($ComputerName,$Port,$null,$null)
        if (-not $pending.AsyncWaitHandle.WaitOne($TimeoutMs)) { return $false }
        $client.EndConnect($pending)
        return $client.Connected
    } catch { return $false }
    finally {
        if ($pending) { $pending.AsyncWaitHandle.Close() }
        $client.Close()
    }
}
function Get-KyuDesktop {
    $desktop = [Environment]::GetFolderPath('DesktopDirectory')
    if (-not $desktop -or -not (Test-Path -LiteralPath $desktop -PathType Container)) { throw 'Desktop folder is unavailable. Check folder redirection or OneDrive sign-in.' }
    return $desktop
}
function Start-KyuService {
    param([string]$Name)
    $service = Get-Service -Name $Name -ErrorAction Stop
    if ($service.Status -ne 'Running') {
        Start-Service -Name $Name -ErrorAction Stop
        $service = Get-Service -Name $Name -ErrorAction Stop
        $service.WaitForStatus('Running',[TimeSpan]::FromSeconds(20))
    }
    return Get-Service -Name $Name -ErrorAction Stop
}
function Get-KyuBackupDirectory {
    $base = [Environment]::GetFolderPath('LocalApplicationData')
    if (-not $base) { throw 'LocalApplicationData is unavailable.' }
    $path = Join-Path $base ('KyuTools\Backups\' + (Get-Date -Format 'yyyyMMdd-HHmmss') + '-' + [guid]::NewGuid().ToString('N').Substring(0,8))
    [void][IO.Directory]::CreateDirectory($path)
    return $path
}
function Assert-KyuSafePath {
    param([string]$Path, [string]$AllowedRoot)
    $full = [IO.Path]::GetFullPath($Path).TrimEnd('\')
    $boundary = [IO.Path]::GetFullPath($AllowedRoot).TrimEnd('\')
    if (-not $full.StartsWith($boundary+'\',[StringComparison]::OrdinalIgnoreCase)) { throw 'The target must be strictly inside the permitted directory.' }
    $cursor = $full
    # A junction above AllowedRoot can alias a destination back into a source.
    # Inspect every ancestor, including those above the lexical boundary.
    while ($cursor) {
        if (Test-Path -LiteralPath $cursor) {
            if ((Get-Item -LiteralPath $cursor -Force -ErrorAction Stop).Attributes -band [IO.FileAttributes]::ReparsePoint) { throw 'Refusing to operate through a junction or symbolic link.' }
        }
        $parent = Split-Path $cursor -Parent
        if ($parent -eq $cursor) { break }
        $cursor = $parent
    }
    return $full
}
function Get-KyuIPv4Targets {
    param([string]$IPAddress,[ValidateRange(1,32)][int]$PrefixLength)
    $address=$null
    if (-not [Net.IPAddress]::TryParse($IPAddress,[ref]$address) -or $address.AddressFamily -ne [Net.Sockets.AddressFamily]::InterNetwork) { throw 'An IPv4 address is required.' }
    $bytes=$address.GetAddressBytes()
    $value=[long]$bytes[0]*16777216+[long]$bytes[1]*65536+[long]$bytes[2]*256+$bytes[3]
    $size=[long][math]::Pow(2,32-$PrefixLength)
    $network=[long]([math]::Floor($value/$size)*$size)
    $first=$network; $last=$network+$size-1
    if ($PrefixLength -lt 31) { $first++; $last-- }
    $limited=($size -gt 256)
    if ($limited) {
        # Large networks get a clearly labeled local /24 window, never a
        # silent assumption that the actual configured prefix is /24.
        $window=[long]([math]::Floor($value/256)*256)
        $first=[math]::Max($first,$window+1); $last=[math]::Min($last,$window+254)
    }
    $targets=@(for ($current=$first;$current -le $last;$current++) {
        if ($current -eq $value) { continue }
        '{0}.{1}.{2}.{3}' -f ([long][math]::Floor($current/16777216)%256),([long][math]::Floor($current/65536)%256),([long][math]::Floor($current/256)%256),($current%256)
    })
    return [pscustomobject]@{Targets=$targets;Limited=$limited;PrefixLength=$PrefixLength}
}
