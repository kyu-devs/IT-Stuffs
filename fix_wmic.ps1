$activation = Get-Content -Raw .\modules\activation.bat
$activation = $activation.Replace("for /f `"tokens=2 delims==`" %%A in ('wmic os get Caption /value') do echo   Edition : %%A", "for /f `"tokens=* delims=`" %%A in ('powershell -NoProfile -Command `"(Get-CimInstance Win32_OperatingSystem).Caption`"') do echo   Edition : %%A")
$activation = $activation.Replace("for /f `"tokens=2 delims==`" %%A in ('wmic os get BuildNumber /value') do echo   Build   : %%A", "for /f `"tokens=* delims=`" %%A in ('powershell -NoProfile -Command `"(Get-CimInstance Win32_OperatingSystem).BuildNumber`"') do echo   Build   : %%A")
$activation = $activation.Replace("for /f `"tokens=2 delims==`" %%A in ('wmic os get SerialNumber /value') do echo   Serial  : %%A", "for /f `"tokens=* delims=`" %%A in ('powershell -NoProfile -Command `"(Get-CimInstance Win32_OperatingSystem).SerialNumber`"') do echo   Serial  : %%A")
$activation | Set-Content .\modules\activation.bat -NoNewline

$diskutils = Get-Content -Raw .\modules\diskutils.bat
$diskutils = $diskutils.Replace("wmic logicaldisk get Caption,FreeSpace,Size,VolumeName,FileSystem /format:list", "powershell -NoProfile -Command `"Get-CimInstance Win32_LogicalDisk | Format-List Caption,FreeSpace,Size,VolumeName,FileSystem`"")
$diskutils | Set-Content .\modules\diskutils.bat -NoNewline

$maint = Get-Content -Raw .\modules\maintenance.bat
$maint = $maint.Replace("wmic diskdrive get Caption,Status,Size,InterfaceType /format:list", "powershell -NoProfile -Command `"Get-CimInstance Win32_DiskDrive | Format-List Caption,Status,Size,InterfaceType`"")
$maint = $maint.Replace("wmic logicaldisk get Caption,FileSystem,FreeSpace,Size,VolumeName /format:list", "powershell -NoProfile -Command `"Get-CimInstance Win32_LogicalDisk | Format-List Caption,FileSystem,FreeSpace,Size,VolumeName`"")
$maint | Set-Content .\modules\maintenance.bat -NoNewline

$perf = Get-Content -Raw .\modules\performance.bat
$perf = $perf.Replace("wmic OS get FreePhysicalMemory,TotalVisibleMemorySize /format:list", "powershell -NoProfile -Command `"Get-CimInstance Win32_OperatingSystem | Format-List FreePhysicalMemory,TotalVisibleMemorySize`"")
$perf | Set-Content .\modules\performance.bat -NoNewline

$sys = Get-Content -Raw .\modules\sysinfo.bat
$sys = $sys.Replace("wmic cpu get Name,NumberOfCores,NumberOfLogicalProcessors,MaxClockSpeed,CurrentClockSpeed,LoadPercentage /format:list", "powershell -NoProfile -Command `"Get-CimInstance Win32_Processor | Format-List Name,NumberOfCores,NumberOfLogicalProcessors,MaxClockSpeed,CurrentClockSpeed,LoadPercentage`"")
$sys = $sys.Replace("wmic memorychip get BankLabel,Capacity,Speed,Manufacturer /format:list", "powershell -NoProfile -Command `"Get-CimInstance Win32_PhysicalMemory | Format-List BankLabel,Capacity,Speed,Manufacturer`"")
$sys = $sys.Replace("wmic path win32_VideoController get Name,AdapterRAM,DriverVersion,CurrentRefreshRate /format:list", "powershell -NoProfile -Command `"Get-CimInstance Win32_VideoController | Format-List Name,AdapterRAM,DriverVersion,CurrentRefreshRate`"")
$sys = $sys.Replace("wmic diskdrive get Model,Size,Status,InterfaceType /format:list", "powershell -NoProfile -Command `"Get-CimInstance Win32_DiskDrive | Format-List Model,Size,Status,InterfaceType`"")
$sys = $sys.Replace("wmic logicaldisk get Caption,FileSystem,FreeSpace,Size,VolumeName /format:list", "powershell -NoProfile -Command `"Get-CimInstance Win32_LogicalDisk | Format-List Caption,FileSystem,FreeSpace,Size,VolumeName`"")
$sys = $sys.Replace("wmic path Win32_Battery get Name,EstimatedChargeRemaining,BatteryStatus /format:list 2>nul", "powershell -NoProfile -Command `"Get-CimInstance Win32_Battery -ErrorAction SilentlyContinue | Format-List Name,EstimatedChargeRemaining,BatteryStatus`"")
$sys = $sys.Replace("wmic cpu get Name,NumberOfCores,MaxClockSpeed /format:list >> `"%REPORT%`"", "powershell -NoProfile -Command `"Get-CimInstance Win32_Processor | Format-List Name,NumberOfCores,MaxClockSpeed`" >> `"%REPORT%`"")
$sys = $sys.Replace("wmic memorychip get BankLabel,Capacity,Speed /format:list  >> `"%REPORT%`"", "powershell -NoProfile -Command `"Get-CimInstance Win32_PhysicalMemory | Format-List BankLabel,Capacity,Speed`" >> `"%REPORT%`"")
$sys = $sys.Replace("wmic path win32_VideoController get Name,AdapterRAM /format:list >> `"%REPORT%`"", "powershell -NoProfile -Command `"Get-CimInstance Win32_VideoController | Format-List Name,AdapterRAM`" >> `"%REPORT%`"")
$sys = $sys.Replace("wmic diskdrive get Model,Size,Status /format:list      >> `"%REPORT%`"", "powershell -NoProfile -Command `"Get-CimInstance Win32_DiskDrive | Format-List Model,Size,Status`" >> `"%REPORT%`"")
$sys | Set-Content .\modules\sysinfo.bat -NoNewline
