# ============================================================
# VS Code + Claude Code + CC-Switch One-Click Deployment
# Platform: Windows 10/11 x64
# ============================================================

param(
    [switch]$Silent = $false,
    [switch]$SkipGit = $false,
    [switch]$SkipNode = $false,
    [switch]$SkipVSCode = $false,
    [switch]$SkipClaude = $false,
    [switch]$SkipCCSwitch = $false
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$PackagesDir = Join-Path $ScriptDir "packages"
$LogFile = Join-Path $env:TEMP "cc_setup_log.txt"
$TotalSteps = 0
$CurrentStep = 0

# Count enabled steps
if (-not $SkipGit) { $TotalSteps++ }
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

function Install-EXE {
    param([string]$ExePath, [string]$Name, [string[]]$Arguments)
    Write-Log "Installing $Name ..." -Color Yellow
    if (-not (Test-Path $ExePath)) {
        Write-Log "ERROR: Cannot find $ExePath" -Color Red
        return $false
    }
    $process = Start-Process -FilePath $ExePath -ArgumentList $Arguments -Wait -PassThru -NoNewWindow
    if ($process.ExitCode -eq 0) {
        Write-Log "$Name installed successfully" -Color Green
        return $true
    }
    else {
        Write-Log "$Name installation failed (exit code: $($process.ExitCode))" -Color Red
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
Write-Host "  Version: 2.0.0" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""
Write-Log "Setup started" -Color White
Write-Log "Script directory: $ScriptDir"
Write-Log "Packages directory: $PackagesDir"

# Check admin privileges
if (-not (Test-Admin)) {
    Write-Log "Administrator privileges required. Requesting elevation..." -Color Yellow
    Start-Sleep -Seconds 1
    $argString = "-NoProfile -ExecutionPolicy Bypass -File `"$($MyInvocation.MyCommand.Path)`""
    if ($Silent) { $argString += " -Silent" }
    if ($SkipGit) { $argString += " -SkipGit" }
    if ($SkipNode) { $argString += " -SkipNode" }
    if ($SkipVSCode) { $argString += " -SkipVSCode" }
    if ($SkipClaude) { $argString += " -SkipClaude" }
    if ($SkipCCSwitch) { $argString += " -SkipCCSwitch" }
    Start-Process -FilePath "powershell.exe" -Verb RunAs -ArgumentList $argString -Wait
    exit $LASTEXITCODE
}
Write-Log "Administrator privileges confirmed" -Color Green

# ============================================================
# 1. Git
# ============================================================
if (-not $SkipGit) {
    Write-Step "Install Git"
    $gitExe = Join-Path $PackagesDir "Git-2.54.0-64-bit.exe"
    $gitAlreadyInstalled = $false

    $existingGit = Test-Command "git" "--version"
    if ($existingGit) {
        Write-Log "Git is already installed: $existingGit, skipping" -Color Green
        $gitAlreadyInstalled = $true
    }

    if (-not $gitAlreadyInstalled) {
        if (-not (Test-Path $gitExe)) {
            Write-Log "ERROR: Cannot find Git-2.54.0-64-bit.exe in packages/" -Color Red
            if (-not $Silent) { Read-Host "Press Enter to exit" }
            exit 1
        }
        if (Install-EXE $gitExe "Git" @("/VERYSILENT", "/NORESTART", "/SUPPRESSMSGBOXES", "/NOCANCEL", "/SP-", "/CLOSEAPPLICATIONS", "/RESTARTAPPLICATIONS", "/COMPONENTS=icons,ext,ext\shellhere,ext\cmdhere,gitlfs,assoc,assoc_sh")) {
            Update-SystemPath
            Write-Log "Git installed: $(Test-Command 'git' '--version')" -Color Green
        }
        else {
            Write-Log "Git installation failed" -Color Red
            if (-not $Silent) { Read-Host "Press Enter to exit" }
            exit 1
        }
    }
}

# ============================================================
# 2. Node.js
# ============================================================
if (-not $SkipNode) {
    Write-Step "Install Node.js v24.16.0"
    $nodeMsi = Join-Path $PackagesDir "node-v24.16.0-x64.msi"
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
            Write-Log "ERROR: Cannot find node-v24.16.0-x64.msi in packages/" -Color Red
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
# 3. VS Code (local installer)
# ============================================================
if (-not $SkipVSCode) {
    Write-Step "Install Visual Studio Code"
    $vscodeExe = Join-Path $PackagesDir "VSCodeUserSetup-x64-1.122.1.exe"
    $codeInstalled = $false

    if (Test-Command "code" "--version") {
        Write-Log "VS Code is already installed, skipping" -Color Green
        $codeInstalled = $true
    }

    if (-not $codeInstalled) {
        if (-not (Test-Path $vscodeExe)) {
            Write-Log "ERROR: Cannot find VSCodeUserSetup-x64-1.122.1.exe in packages/" -Color Red
            if (-not $Silent) { Read-Host "Press Enter to exit" }
            exit 1
        }
        if (Install-EXE $vscodeExe "VS Code" @("/VERYSILENT", "/NORESTART", "/MERGETASKS=!runcode,addcontextmenufiles,addcontextmenufolders,associatewithfiles,addtopath")) {
            Update-SystemPath
            Write-Log "VS Code installed" -Color Green
        }
        else {
            Write-Log "VS Code installation failed" -Color Red
            if (-not $Silent) { Read-Host "Press Enter to exit" }
            exit 1
        }
    }
}

# ============================================================
# 4. Claude Code CLI
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
        Write-Log "Claude Code CLI installed successfully" -Color Green
        $ccVer = Test-Command "claude" "--version"
        if ($ccVer) {
            Write-Log "Claude Code version: $ccVer" -Color Green
        }
        else {
            Write-Log "Note: Restart terminal to use 'claude' command" -Color Yellow
        }
    }
    else {
        Write-Log "Claude Code CLI installation failed (exit code: $($process.ExitCode))" -Color Red
        Write-Log "Check network connection or try: npm install -g @anthropic-ai/claude-code" -Color Yellow
    }

    # Install Claude Code VS Code extension
    Write-Log "Installing Claude Code extension for VS Code..." -Color Yellow
    Update-SystemPath
    $codeCmd = $null

    # Try 'code' from PATH
    try { $codeCmd = Get-Command "code" -ErrorAction Stop } catch {}

    # Fallback: try common VS Code install location
    if (-not $codeCmd) {
        $vscodePath = Join-Path $env:LOCALAPPDATA "Programs\Microsoft VS Code\bin\code.cmd"
        if (Test-Path $vscodePath) {
            $codeCmd = $vscodePath
        }
    }

    if ($codeCmd) {
        $extProcess = Start-Process -FilePath "code" -ArgumentList @("--install-extension", "anthropic.claude-code", "--force") -Wait -PassThru -NoNewWindow
        if ($extProcess.ExitCode -eq 0) {
            Write-Log "Claude Code VS Code extension installed" -Color Green
        }
        else {
            Write-Log "Claude Code VS Code extension installation failed (exit code: $($extProcess.ExitCode))" -Color Yellow
            Write-Log "You can install it manually: code --install-extension anthropic.claude-code" -Color Yellow
        }
    }
    else {
        Write-Log "VS Code 'code' command not found in PATH, skipping extension install" -Color Yellow
        Write-Log "After reboot, run: code --install-extension anthropic.claude-code" -Color Yellow
    }
}

# ============================================================
# 5. CC-Switch
# ============================================================
if (-not $SkipCCSwitch) {
    Write-Step "Install CC-Switch v3.16.0"

    $ccSwitchMsi = Join-Path $PackagesDir "CC-Switch-v3.16.0-Windows.msi"
    if (Test-Path $ccSwitchMsi) {
        if (-not (Install-MSI $ccSwitchMsi "CC-Switch")) {
            Write-Log "CC-Switch installation failed" -Color Red
        }
    }
    else {
        Write-Log "ERROR: Cannot find CC-Switch-v3.16.0-Windows.msi in packages/" -Color Red
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

# Verify Git
$gitVer = Test-Command "git" "--version"
if ($gitVer) {
    Write-Log "  [PASS] Git: $gitVer" -Color Green
}
else {
    Write-Log "  [FAIL] Git: not detected" -Color Red
}

# Verify Node.js
$nodeVer = Test-Command "node" "-v"
if ($nodeVer) {
    Write-Log "  [PASS] Node.js: $nodeVer" -Color Green
}
else {
    Write-Log "  [FAIL] Node.js: not detected" -Color Red
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
}
else {
    Write-Log "  [WARN] VS Code: not in PATH (may need reboot)" -Color Yellow
}

# Verify Claude Code
$ccVer = Test-Command "claude" "--version"
if ($ccVer) {
    Write-Log "  [PASS] Claude Code: $ccVer" -Color Green
}
else {
    Write-Log "  [WARN] Claude Code: not in PATH (may need reboot)" -Color Yellow
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
        break
    }
}
if (-not $ccFound) {
    Write-Log "  [WARN] CC-Switch: please verify installation" -Color Yellow
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
