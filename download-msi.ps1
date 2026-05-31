# ============================================================
# Download required MSI installers
# Run this first before build-exe.ps1 or install.ps1
# ============================================================

param(
    [string]$NodeVersion = "v24.16.0",
    [string]$CCSwitchVersion = "v3.16.0"
)

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Download required MSI installers" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# Node.js download URL (official mirror)
$nodeMsi = "node-$NodeVersion-x64.msi"
if (-not (Test-Path $nodeMsi)) {
    Write-Host ">>> Downloading Node.js $NodeVersion..." -ForegroundColor Yellow
    $nodeUrl = "https://nodejs.org/dist/$NodeVersion/$nodeMsi"
    Write-Host "  URL: $nodeUrl" -ForegroundColor Gray
    Invoke-WebRequest -Uri $nodeUrl -OutFile $nodeMsi -UseBasicParsing
    $size = [math]::Round((Get-Item $nodeMsi).Length / 1MB, 1)
    Write-Host "  [OK] Downloaded ($size MB)" -ForegroundColor Green
} else {
    $size = [math]::Round((Get-Item $nodeMsi).Length / 1MB, 1)
    Write-Host "  [SKIP] $nodeMsi already exists ($size MB)" -ForegroundColor Gray
}

# CC-Switch download
$ccMsi = "CC-Switch-$CCSwitchVersion-Windows.msi"
if (-not (Test-Path $ccMsi)) {
    Write-Host ">>> CC-Switch $CCSwitchVersion" -ForegroundColor Yellow
    Write-Host "  NOTE: Please download CC-Switch manually and place in this directory" -ForegroundColor Yellow
    Write-Host "  File: $ccMsi" -ForegroundColor Yellow
} else {
    $size = [math]::Round((Get-Item $ccMsi).Length / 1MB, 1)
    Write-Host "  [OK] $ccMsi found ($size MB)" -ForegroundColor Green
}

Write-Host ""
Write-Host "Done. Run build-exe.ps1 to create the installer EXE." -ForegroundColor Green
