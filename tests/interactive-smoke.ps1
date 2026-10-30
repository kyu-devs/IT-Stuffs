# Optional manual smoke test. No system repairs, settings, or logs are written.
param([switch]$Child)
if ($Child) {
    Write-Host '[1] Visible choice before input'
    Write-Host '[2] Another visible choice'
    $answer=Read-Host 'Type OK'
    if ($answer -cne 'OK') { exit 1 }
    Write-Host 'Child input received.'
    exit 0
}
. (Join-Path (Split-Path $PSScriptRoot -Parent) 'modules\common.ps1')
function Write-KyuLog { param($Message,$Level) }
[void](Invoke-KyuNative powershell.exe @('-NoProfile','-ExecutionPolicy','Bypass','-File',$PSCommandPath,'-Child') -Interactive)
Write-Host 'Interactive execution succeeded.'
