# ============================================================
# VS Code + Claude Code + CC-Switch One-Click Deployment
# Platform: Windows 10/11 x64
# ============================================================

param(
    [switch]$Silent = $false,
    [switch]$SkipVSCode = $false,
    [switch]$SkipNode = $false,
    [switch]$SkipClaude = $false,
    [switch]$SkipCCSwitch = $false
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$LogFile = Join-Path $env:TEMP "cc_setup_log.txt"
$VsCodeInstaller = Join-Path $env:TEMP "VSCodeSetup.exe"
$TotalSteps = 0
$CurrentStep = 0

# Count enabled steps
if (-not $SkipNode) { $TotalSteps++ }
if (-not $SkipVSCode) { $TotalSteps++ }
if (-not $SkipClaude) { $TotalSteps++ }
if (-not $SkipCCSwitch) { $TotalSteps++ }

# ============================================================
# Helper Functions
# ============================================================

function Write-Log {
    param([string]$Message, [string]$Color = "White")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $line = "[$timestamp] $Message"
    Add-Content -Path $LogFile -Value $line -Encoding UTF8
    if (-not $Silent) {
        Write-Host $line -ForegroundColor $Color
    }
}

function Write-Step {
    param([string]$Name)
    $script:CurrentStep++
    Write-Host ""
    Write-Host (">>> [{0}/{1}] {2}" -f $script:CurrentStep, $script:TotalSteps, $Name) -ForegroundColor Cyan
    Write-Host ("-" * 40) -ForegroundColor DarkGray
}

function Test-Admin {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Install-MSI {
    param([string]$MsiPath, [string]$Name)
    Write-Log "Installing $Name ..." -Color Yellow
    if (-not (Test-Path $MsiPath)) {
        Write-Log "ERROR: Cannot find $MsiPath" -Color Red
        return $false
    }
    $logPath = Join-Path $env:TEMP "${Name}_install.log"
    $msiArgs = @("/i", $MsiPath, "/qn", "/norestart", "/L*V", $logPath)
    $process = Start-Process -FilePath "msiexec.exe" -ArgumentList $msiArgs -Wait -PassThru -NoNewWindow
    if ($process.ExitCode -eq 0 -or $process.ExitCode -eq 3010) {
        Write-Log "$Name installed successfully" -Color Green
        return $true
    }
    else {
        Write-Log "$Name installation failed (exit code: $($process.ExitCode))" -Color Red
        Write-Log "Check log: $logPath" -Color Yellow
        return $false
    }
}

function Update-SystemPath {
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
}

function Test-Command {
    param([string]$Cmd, [string]$Arguments = "--version")
    try {
        $output = & $Cmd $Arguments 2>&1 | Select-Object -First 1
        return $output
    }
    catch {
        return $null
    }
}

# ============================================================
# Main Installation
# ============================================================

Clear-Host
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  VS Code + Claude Code + CC-Switch Setup" -ForegroundColor Cyan
Write-Host "  Version: 1.0.0" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""
Write-Log "Setup started" -Color White
Write-Log "Script directory: $ScriptDir"

# Check admin privileges
if (-not (Test-Admin)) {
    Write-Log "Administrator privileges required. Requesting elevation..." -Color Yellow
    Start-Sleep -Seconds 1
    $argString = "-NoProfile -ExecutionPolicy Bypass -File `"$($MyInvocation.MyCommand.Path)`""
    if ($Silent) { $argString += " -Silent" }
    if ($SkipVSCode) { $argString += " -SkipVSCode" }
    if ($SkipNode) { $argString += " -SkipNode" }
    if ($SkipClaude) { $argString += " -SkipClaude" }
    if ($SkipCCSwitch) { $argString += " -SkipCCSwitch" }
    Start-Process -FilePath "powershell.exe" -Verb RunAs -ArgumentList $argString -Wait
    exit $LASTEXITCODE
}
Write-Log "Administrator privileges confirmed" -Color Green

# ============================================================
# 1. Node.js
# ============================================================
if (-not $SkipNode) {
    Write-Step "Install Node.js v24.16.0"
    $nodeMsi = Join-Path $ScriptDir "node-v24.16.0-x64.msi"
    $nodeAlreadyInstalled = $false

    $existingNode = Test-Command "node" "-v"
    if ($existingNode -eq "v24.16.0") {
        Write-Log "Node.js v24.16.0 is already installed, skipping" -Color Green
        $nodeAlreadyInstalled = $true
    }
    elseif ($existingNode) {
        Write-Log "Detected Node.js $existingNode, will upgrade to v24.16.0" -Color Yellow
    }

    if (-not $nodeAlreadyInstalled) {
        if (-not (Test-Path $nodeMsi)) {
            Write-Log "ERROR: Cannot find node-v24.16.0-x64.msi" -Color Red
            Write-Log "Please place the MSI file in the same directory as this script" -Color Red
            if (-not $Silent) { Read-Host "Press Enter to exit" }
            exit 1
        }
        if (Install-MSI $nodeMsi "Node.js") {
            Update-SystemPath
            Write-Log "Node.js installed: $(Test-Command 'node' '-v')" -Color Green
        }
        else {
            Write-Log "Node.js installation failed" -Color Red
            if (-not $Silent) { Read-Host "Press Enter to exit" }
            exit 1
        }
    }
}

# ============================================================
# 2. VS Code
# ============================================================
if (-not $SkipVSCode) {
    Write-Step "Install Visual Studio Code"
    $codeInstalled = $false

    if (Test-Command "code" "--version") {
        Write-Log "VS Code is already installed, skipping" -Color Green
        $codeInstalled = $true
    }

    if (-not $codeInstalled) {
        # Try winget first
        try {
            $null = & winget --version 2>$null
            Write-Log "Using winget to install VS Code..." -Color Yellow
            & winget install --id Microsoft.VisualStudioCode --silent --accept-package-agreements --accept-source-agreements
            if ($LASTEXITCODE -eq 0) {
                Write-Log "VS Code installed via winget" -Color Green
                $codeInstalled = $true
            }
        }
        catch { }

        if (-not $codeInstalled) {
            # Fallback: direct download
            Write-Log "Downloading VS Code installer..." -Color Yellow
            $vscodeUrl = "https://update.code.visualstudio.com/latest/win32-x64-user/stable"
            try {
                [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
                Invoke-WebRequest -Uri $vscodeUrl -OutFile $VsCodeInstaller -UseBasicParsing
                Write-Log "Download complete. Installing..." -Color Yellow
                Start-Process -FilePath $VsCodeInstaller -ArgumentList "/verysilent /norestart /mergetasks=!runcode,addcontextmenufiles,addcontextmenufolders,associatewithfiles,addtopath" -Wait
                Write-Log "VS Code installed" -Color Green
            }
            catch {
                Write-Log "VS Code download/install failed: $_" -Color Red
                Write-Log "Please install VS Code manually from https://code.visualstudio.com" -Color Yellow
            }
        }
    }
}

# ============================================================
# 3. Claude Code
# ============================================================
if (-not $SkipClaude) {
    Write-Step "Install Claude Code CLI"

    # Ensure npm is available
    Update-SystemPath
    try {
        $npmVer = & npm --version 2>$null
        if (-not $npmVer) { throw "npm not found" }
        Write-Log "npm v$npmVer detected" -Color Green
    }
    catch {
        Write-Log "ERROR: npm is not available. Please install Node.js first." -Color Red
        if (-not $Silent) { Read-Host "Press Enter to exit" }
        exit 1
    }

    Write-Log "Installing @anthropic-ai/claude-code (global)..." -Color Yellow
    $npmArgs = @("install", "-g", "@anthropic-ai/claude-code")
    $process = Start-Process -FilePath "npm" -ArgumentList $npmArgs -Wait -PassThru -NoNewWindow

    if ($process.ExitCode -eq 0) {
        Write-Log "Claude Code installed successfully" -Color Green
        $ccVer = Test-Command "claude" "--version"
        if ($ccVer) {
            Write-Log "Claude Code version: $ccVer" -Color Green
        }
        else {
            Write-Log "Note: Restart terminal to use 'claude' command" -Color Yellow
        }
    }
    else {
        Write-Log "Claude Code installation failed (exit code: $($process.ExitCode))" -Color Red
        Write-Log "Check network connection or try: npm install -g @anthropic-ai/claude-code" -Color Yellow
    }
}

# ============================================================
# 4. CC-Switch
# ============================================================
if (-not $SkipCCSwitch) {
    Write-Step "Install CC-Switch v3.16.0"

    $ccSwitchMsi = Join-Path $ScriptDir "CC-Switch-v3.16.0-Windows.msi"
    if (Test-Path $ccSwitchMsi) {
        if (-not (Install-MSI $ccSwitchMsi "CC-Switch")) {
            Write-Log "CC-Switch installation failed" -Color Red
        }
    }
    else {
        Write-Log "ERROR: Cannot find CC-Switch-v3.16.0-Windows.msi" -Color Red
    }
}

# ============================================================
# Installation Complete - Verification
# ============================================================
Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  Setup Complete!" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""
Write-Log "===== Installation Summary =====" -Color White

$results = @()

# Verify Node.js
$nodeVer = Test-Command "node" "-v"
if ($nodeVer) {
    Write-Log "  [PASS] Node.js: $nodeVer" -Color Green
    $results += "Node.js: OK"
}
else {
    Write-Log "  [FAIL] Node.js: not detected" -Color Red
    $results += "Node.js: FAIL"
}

# Verify npm
$npmVer = Test-Command "npm" "-v"
if ($npmVer) {
    Write-Log "  [PASS] npm: v$npmVer" -Color Green
}
else {
    Write-Log "  [FAIL] npm: not detected" -Color Red
}

# Verify VS Code
$codeVer = Test-Command "code" "--version"
if ($codeVer) {
    Write-Log "  [PASS] VS Code: $codeVer" -Color Green
    $results += "VS Code: OK"
}
else {
    Write-Log "  [WARN] VS Code: not in PATH (may need reboot)" -Color Yellow
    $results += "VS Code: check PATH"
}

# Verify Claude Code
$ccVer = Test-Command "claude" "--version"
if ($ccVer) {
    Write-Log "  [PASS] Claude Code: $ccVer" -Color Green
    $results += "Claude Code: OK"
}
else {
    Write-Log "  [WARN] Claude Code: not in PATH (may need reboot)" -Color Yellow
    $results += "Claude Code: check PATH"
}

# Verify CC-Switch
$ccSwitchDirs = @(
    "${env:ProgramFiles}\CC-Switch",
    "${env:ProgramFiles(x86)}\CC-Switch",
    "${env:LOCALAPPDATA}\CC-Switch"
)
$ccFound = $false
foreach ($dir in $ccSwitchDirs) {
    if (Test-Path $dir) {
        $ccFound = $true
        Write-Log "  [PASS] CC-Switch: $dir" -Color Green
        $results += "CC-Switch: OK"
        break
    }
}
if (-not $ccFound) {
    Write-Log "  [WARN] CC-Switch: please verify installation" -Color Yellow
    $results += "CC-Switch: check"
}

Write-Host ""
Write-Log "Log file: $LogFile" -Color White
Write-Host ""

if ($TotalSteps -gt 0) {
    Write-Host "Next steps:" -ForegroundColor Yellow
    Write-Host "  1. Restart terminal (or reboot) for PATH changes" -ForegroundColor White
    Write-Host "  2. Run 'claude' to initialize Claude Code" -ForegroundColor White
    Write-Host "  3. Use CC-Switch to manage API keys" -ForegroundColor White
    Write-Host ""
}

if (-not $Silent) {
    Read-Host "Press Enter to exit"
}
