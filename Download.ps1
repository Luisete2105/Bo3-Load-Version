# Download.ps1 - Downloads the latest release and extracts it in the current folder
$ErrorActionPreference = "Stop"

$repo = "Luisete2105/Bo3-Load-Version"
$apiUrl = "https://api.github.com/repos/$repo/releases/latest"

Write-Host "Fetching latest release information..." -ForegroundColor Cyan

try {
    $release = Invoke-RestMethod -Uri $apiUrl -Headers @{ "User-Agent" = "PowerShell" }
} catch {
    Write-Host "Error: Could not get the latest release. Check your internet connection." -ForegroundColor Red
    exit 1
}

$asset = $release.assets | Where-Object { $_.name -like "*.zip" } | Select-Object -First 1

if (-not $asset) {
    Write-Host "Error: No .zip file found in the latest release." -ForegroundColor Red
    exit 1
}

$zipName = $asset.name
$downloadUrl = $asset.browser_download_url
$tempZip = Join-Path $env:TEMP $zipName

Write-Host "Downloading: $zipName ..." -ForegroundColor Cyan
Invoke-WebRequest -Uri $downloadUrl -OutFile $tempZip -UseBasicParsing

Write-Host "Extracting files to the current folder..." -ForegroundColor Cyan

# Extract to a temporary folder first, then move everything to the current directory
$tempExtract = Join-Path $env:TEMP "Bo3-Load-Version-extract-$(Get-Random)"
New-Item -ItemType Directory -Path $tempExtract -Force | Out-Null

Expand-Archive -Path $tempZip -DestinationPath $tempExtract -Force

# Move all contents (files + folders) to the current directory
Get-ChildItem -Path $tempExtract | ForEach-Object {
    $destination = Join-Path (Get-Location) $_.Name
    if (Test-Path $destination) {
        Remove-Item $destination -Recurse -Force
    }
    Move-Item $_.FullName -Destination (Get-Location) -Force
}

# Cleanup
Remove-Item $tempZip -Force -ErrorAction SilentlyContinue
Remove-Item $tempExtract -Recurse -Force -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "Done! Files extracted successfully." -ForegroundColor Green
Write-Host "You can now use the .bat files to switch versions." -ForegroundColor Green
Write-Host ""
pause