# Compatibility entry point. Importing this script does not change system settings.
. (Join-Path $PSScriptRoot 'printer_tools.ps1')
if ($MyInvocation.InvocationName -ne '.') {
    $ErrorActionPreference='Stop'
    try { Connect-KyuPrinterInteractive; exit 0 }
    catch { Write-Host $_.Exception.Message -ForegroundColor Red; exit 1 }
}
