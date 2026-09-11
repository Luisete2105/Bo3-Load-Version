# Download.ps1 - Downloads the latest release and extracts it in the script's folder
$ErrorActionPreference = "Stop"

$repo = "Luisete2105/Bo3-Load-Version"
$apiUrl = "https://api.github.com/repos/$repo/releases/latest"
$desiredZipName = "Bo3.Load.Version.zip"

# Force extraction in the same folder where this script is located
$scriptDir = $PSScriptRoot
if (-not $scriptDir) { $scriptDir = Get-Location }

Write-Host "Script location: $scriptDir" -ForegroundColor DarkGray
Write-Host "Fetching latest release information..." -ForegroundColor Cyan

try {
    $release = Invoke-RestMethod -Uri $apiUrl -Headers @{ "User-Agent" = "PowerShell" }
} catch {
    Write-Host "Error: Could not get the latest release. Check your internet connection." -ForegroundColor Red
    exit 1
}

$asset = $release.assets | Where-Object { $_.name -eq $desiredZipName } | Select-Object -First 1

if (-not $asset) {
    Write-Host "Error: '$desiredZipName' not found in the latest release." -ForegroundColor Red
    exit 1
}

$zipName = $asset.name
$downloadUrl = $asset.browser_download_url

# Possible locations where the zip might already exist
$localZip = Join-Path $scriptDir $zipName
$tempZip  = Join-Path $env:TEMP $zipName

$zipToUse = $null

# Check if the file already exists
if (Test-Path $localZip) {
    Write-Host "Found existing file in script folder. Skipping download." -ForegroundColor Green
    $zipToUse = $localZip
}
elseif (Test-Path $tempZip) {
    Write-Host "Found existing file in Temp. Skipping download." -ForegroundColor Green
    $zipToUse = $tempZip
}

# Download only if necessary
if (-not $zipToUse) {
    Write-Host "Downloading: $zipName ..." -ForegroundColor Cyan
    Write-Host "This may take a while (file is large)..." -ForegroundColor Yellow

    try {
        Invoke-WebRequest -Uri $downloadUrl -OutFile $tempZip -UseBasicParsing
        $zipToUse = $tempZip
    } catch {
        Write-Host "Error downloading the file." -ForegroundColor Red
        exit 1
    }
}

Write-Host "Extracting files to: $scriptDir" -ForegroundColor Cyan

# Extract to a temporary folder first
$tempExtract = Join-Path $env:TEMP "Bo3-Load-Version-extract-$(Get-Random)"
New-Item -ItemType Directory -Path $tempExtract -Force | Out-Null

Expand-Archive -Path $zipToUse -DestinationPath $tempExtract -Force

# Move everything to the script folder
Get-ChildItem -Path $tempExtract | ForEach-Object {
    $destination = Join-Path $scriptDir $_.Name
    if (Test-Path $destination) {
        Remove-Item $destination -Recurse -Force
    }
    Move-Item $_.FullName -Destination $scriptDir -Force
}

# Cleanup
Remove-Item $tempExtract -Recurse -Force -ErrorAction SilentlyContinue

# Optionally keep the zip in the script folder for future use
if ($zipToUse -eq $tempZip -and -not (Test-Path $localZip)) {
    Move-Item $tempZip -Destination $localZip -Force
    Write-Host "Zip saved in script folder for future runs." -ForegroundColor DarkGray
}

Write-Host ""
Write-Host "Done! Files extracted successfully." -ForegroundColor Green
Write-Host "You can now use the .bat files to switch versions." -ForegroundColor Green
Write-Host ""
pause