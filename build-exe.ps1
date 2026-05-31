# Build script: Create one-click deployment EXE
# Requires: .NET Framework 4.x (csc.exe)

param(
    [string]$OutputExe = "output\Setup-VSCode-Claude-CC.exe",
    [switch]$NoCompress
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $ScriptDir

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Build: Setup-VSCode-Claude-CC.exe" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# Find C# compiler
$cscPaths = @(
    "$env:SystemRoot\Microsoft.NET\Framework64\v4.0.30319\csc.exe",
    "$env:SystemRoot\Microsoft.NET\Framework\v4.0.30319\csc.exe"
)
$csc = $null
foreach ($p in $cscPaths) {
    if (Test-Path $p) { $csc = $p; break }
}
if (-not $csc) {
    Write-Host "ERROR: csc.exe not found. Install .NET Framework 4.x SDK" -ForegroundColor Red
    exit 1
}
Write-Host "[OK] C# compiler: $csc" -ForegroundColor Green

# Create output directory
$outDir = "output"
if (-not (Test-Path $outDir)) {
    New-Item -ItemType Directory -Path $outDir -Force | Out-Null
}

if ($NoCompress) {
    # Development mode: lightweight EXE (reads files from same directory)
    Write-Host ">>> Compiling lightweight EXE (dev mode)..." -ForegroundColor Yellow
    & $csc /target:winexe /out:$OutputExe /reference:System.dll /reference:System.Windows.Forms.dll /reference:System.IO.Compression.dll /reference:System.IO.Compression.FileSystem.dll Bootstrap.cs 2>&1 | ForEach-Object { Write-Host $_ }
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Compilation failed!" -ForegroundColor Red
        exit 1
    }
    Write-Host "[OK] EXE compiled: $OutputExe" -ForegroundColor Green
    Write-Host "NOTE: EXE reads files from its own directory" -ForegroundColor Yellow
}
else {
    # Release mode: embed all resources into EXE
    Write-Host ">>> Step 1: Creating resource package..." -ForegroundColor Yellow

    $zipPath = "$outDir\resources.zip"
    if (Test-Path $zipPath) { Remove-Item $zipPath -Force }

    $filesToPack = @("install.ps1", "install.bat", "README.md")

    if (Test-Path "node-v24.16.0-x64.msi") {
        $filesToPack += "node-v24.16.0-x64.msi"
        $nodeSize = [math]::Round((Get-Item 'node-v24.16.0-x64.msi').Length / 1MB, 1)
        Write-Host "  + node-v24.16.0-x64.msi ($nodeSize MB)" -ForegroundColor Gray
    }
    if (Test-Path "CC-Switch-v3.16.0-Windows.msi") {
        $filesToPack += "CC-Switch-v3.16.0-Windows.msi"
        $ccSize = [math]::Round((Get-Item 'CC-Switch-v3.16.0-Windows.msi').Length / 1MB, 1)
        Write-Host "  + CC-Switch-v3.16.0-Windows.msi ($ccSize MB)" -ForegroundColor Gray
    }

    Compress-Archive -Path $filesToPack -DestinationPath $zipPath -CompressionLevel Optimal
    $zipSize = [math]::Round((Get-Item $zipPath).Length / 1MB, 1)
    Write-Host "[OK] Resource package created ($zipSize MB)" -ForegroundColor Green

    Write-Host ">>> Step 2: Compiling final EXE with embedded resources..." -ForegroundColor Yellow

    $zipFullPath = (Resolve-Path $zipPath).Path
    & $csc /target:winexe /out:$OutputExe /reference:System.dll /reference:System.Windows.Forms.dll /reference:System.IO.Compression.dll /reference:System.IO.Compression.FileSystem.dll /resource:"$zipFullPath,resources.zip" Bootstrap.cs 2>&1 | ForEach-Object { Write-Host $_ }

    if ($LASTEXITCODE -ne 0) {
        Write-Host "Compilation failed!" -ForegroundColor Red
        exit 1
    }

    # Cleanup
    Remove-Item $zipPath -Force -ErrorAction SilentlyContinue

    $exeSize = [math]::Round((Get-Item $OutputExe).Length / 1MB, 1)
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  Build Complete!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Output: $OutputExe ($exeSize MB)" -ForegroundColor White
    Write-Host ""
}
