# ============================================================
# ONYX IT DEPARTMENT TECH TOOLS - Cloud Web Bootstrapper
# Enables: irm <URL> | iex
# ============================================================

$ErrorActionPreference = 'Stop'

Write-Host ""
Write-Host "   +---------------------------------------------------------+" -ForegroundColor Green
Write-Host "   |     O N Y X   I T   D E P A R T M E N T   C L O U D     |" -ForegroundColor Green
Write-Host "   |             Fetching latest toolkit...                  |" -ForegroundColor Green
Write-Host "   +---------------------------------------------------------+" -ForegroundColor Green
Write-Host ""

# Ensure TLS 1.2 is active for GitHub downloads
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Target GitHub repository archive URL
$RepoZip = "https://github.com/kyu-devs/IT-Stuffs/archive/refs/heads/main.zip"
$TempDir = Join-Path ([IO.Path]::GetTempPath()) ("KyuTools_Cloud_" + [guid]::NewGuid().ToString('N'))
$ZipFile = $TempDir + '.zip'

try {
    Write-Host "   [*] Downloading latest ONYX IT DEPARTMENT TECH TOOLS from GitHub..." -ForegroundColor Green
    Invoke-WebRequest -Uri $RepoZip -OutFile $ZipFile -UseBasicParsing

    Write-Host "   [*] Extracting files..." -ForegroundColor Green
    Expand-Archive -Path $ZipFile -DestinationPath $TempDir -Force
    Remove-Item -LiteralPath $ZipFile -Force -ErrorAction Stop

    # Find KyuTools.bat inside the extracted directory structure
    $Launcher = Get-ChildItem -Path $TempDir -Recurse -Filter "KyuTools.bat" | Select-Object -First 1

    if ($Launcher) {
        Write-Host "   Source: $RepoZip" -ForegroundColor Yellow
        Write-Host "   Extracted code: $TempDir" -ForegroundColor Yellow
        Write-Host "   Review this downloaded code before granting administrator access." -ForegroundColor Yellow
        if ((Read-Host "   Type YES to launch the downloaded toolkit") -cne 'YES') {
            Write-Host '   Launch cancelled. Downloaded files were retained for review.'
            return
        }
        Write-Host "   [*] Launching ONYX IT DEPARTMENT TECH TOOLS elevated..." -ForegroundColor Green
        Start-Process cmd -ArgumentList "/c `"$($Launcher.FullName)`"" -Verb RunAs
    } else {
        Write-Host "   [-] Error: KyuTools.bat was not found in the downloaded archive." -ForegroundColor Red
    }
} catch {
    Write-Host "   [-] Failed to launch ONYX IT DEPARTMENT TECH TOOLS: $($_.Exception.Message)" -ForegroundColor Red
    throw
}
