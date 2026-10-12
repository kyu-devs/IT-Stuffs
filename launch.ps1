# ============================================================
# KyuTools - Cloud Web Bootstrapper
# Enables: irm <URL> | iex
# ============================================================

$ErrorActionPreference = 'Stop'

Write-Host ""
Write-Host "   +---------------------------------------------------------+" -ForegroundColor Green
Write-Host "   |            K Y U T O O L S   C L O U D                  |" -ForegroundColor Green
Write-Host "   |             Fetching latest toolkit...                  |" -ForegroundColor Green
Write-Host "   +---------------------------------------------------------+" -ForegroundColor Green
Write-Host ""

# Ensure TLS 1.2 is active for GitHub downloads
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Target GitHub repository archive URL
$RepoZip = "https://github.com/mong-g/IT-Stuffs/archive/refs/heads/main.zip"
$TempDir = Join-Path $env:TEMP "KyuTools_Cloud"
$ZipFile = Join-Path $env:TEMP "KyuTools.zip"

try {
    Write-Host "   [*] Downloading latest KyuTools from GitHub..." -ForegroundColor Green
    Invoke-WebRequest -Uri $RepoZip -OutFile $ZipFile -UseBasicParsing

    Write-Host "   [*] Extracting files..." -ForegroundColor Green
    if (Test-Path $TempDir) { Remove-Item -Path $TempDir -Recurse -Force -ErrorAction SilentlyContinue }
    Expand-Archive -Path $ZipFile -DestinationPath $TempDir -Force
    Remove-Item -Path $ZipFile -Force -ErrorAction SilentlyContinue

    # Find KyuTools.bat inside the extracted directory structure
    $Launcher = Get-ChildItem -Path $TempDir -Recurse -Filter "KyuTools.bat" | Select-Object -First 1

    if ($Launcher) {
        Write-Host "   [*] Launching KyuTools elevated..." -ForegroundColor Green
        Start-Process cmd -ArgumentList "/c `"$($Launcher.FullName)`"" -Verb RunAs
    } else {
        Write-Host "   [-] Error: KyuTools.bat was not found in the downloaded archive." -ForegroundColor Red
    }
} catch {
    Write-Host "   [-] Failed to launch KyuTools: $($_.Exception.Message)" -ForegroundColor Red
}
