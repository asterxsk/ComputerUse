# ComputerUse CLI - Windows Installer
# One-liner install (PowerShell):
#   irm https://raw.githubusercontent.com/asterxsk/ComputerUse/main/install.ps1 | iex
#
# What this does:
#   1. Verifies Python 3.9+ is available (offers winget install if missing).
#   2. Downloads the repo into %LOCALAPPDATA%\ComputerUse.
#   3. Creates an isolated venv and installs requirements.
#   4. Writes a `computer-use.cmd` shim into %LOCALAPPDATA%\ComputerUse\bin
#      and adds that folder to the current user's PATH.
#   5. Verifies the install by running `computer-use --help`.
#
# After install, open a NEW terminal and run:
#   computer-use vision
#   computer-use mouse-move 500 400
#   computer-use keyboard-type "hello"
#   computer-use keyboard-shortcut alt_tab

[CmdletBinding()]
param(
    [string]$Repo       = "asterxsk/ComputerUse",
    [string]$Branch     = "main",
    [string]$InstallDir = "$env:LOCALAPPDATA\ComputerUse",
    [string]$SkillDir   = "$env:USERPROFILE\.agents\skills\ComputerUse",
    [switch]$Force
)

$ErrorActionPreference = "Stop"
$ProgressPreference    = "SilentlyContinue"

function Write-Step($msg)  { Write-Host "==> $msg" -ForegroundColor Cyan }
function Write-Ok($msg)    { Write-Host "    $msg"  -ForegroundColor Green }
function Write-Warn2($msg) { Write-Host "    $msg"  -ForegroundColor Yellow }
function Write-Err($msg)   { Write-Host "    $msg"  -ForegroundColor Red }

# -------------------------------------------------------------------
# 1. Check Python
# -------------------------------------------------------------------
Write-Step "Checking for Python 3.9+"

$pythonCmd = $null
foreach ($candidate in @("python", "py -3", "python3")) {
    try {
        $verOutput = & cmd /c "$candidate --version 2>&1"
        if ($LASTEXITCODE -eq 0 -and $verOutput -match "Python\s+(\d+)\.(\d+)") {
            $major = [int]$Matches[1]; $minor = [int]$Matches[2]
            if ($major -ge 3 -and $minor -ge 9) {
                $pythonCmd = $candidate
                Write-Ok "Found $verOutput ($candidate)"
                break
            }
        }
    } catch { }
}

if (-not $pythonCmd) {
    Write-Warn2 "Python 3.9+ not found."
    $install = Read-Host "Install Python 3.12 via winget now? (y/N)"
    if ($install -eq 'y') {
        winget install -e --id Python.Python.3.12 --accept-source-agreements --accept-package-agreements
        Write-Warn2 "Python installed. Please close and reopen PowerShell, then re-run this installer."
        exit 0
    } else {
        Write-Err "Aborting. Install Python 3.9+ from https://www.python.org/downloads/ and re-run."
        exit 1
    }
}

# -------------------------------------------------------------------
# 2. Prepare install directory
# -------------------------------------------------------------------
Write-Step "Preparing install directory: $InstallDir"

if (Test-Path $InstallDir) {
    if ($Force) {
        Write-Warn2 "Removing existing install (--Force)"
        Remove-Item -Recurse -Force $InstallDir
    } else {
        Write-Warn2 "Directory exists. Use -Force to reinstall. Updating in place."
    }
}
New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null

# -------------------------------------------------------------------
# 3. Fetch repo zip
# -------------------------------------------------------------------
Write-Step "Downloading repo $Repo@$Branch"

$zipUrl  = "https://codeload.github.com/$Repo/zip/refs/heads/$Branch"
$zipPath = Join-Path $env:TEMP "computer-use-$Branch.zip"

try {
    Invoke-WebRequest -Uri $zipUrl -OutFile $zipPath -UseBasicParsing
} catch {
    Write-Err "Failed to download $zipUrl"
    Write-Err $_.Exception.Message
    exit 1
}

$extractTemp = Join-Path $env:TEMP "computer-use-extract-$([guid]::NewGuid())"
New-Item -ItemType Directory -Force -Path $extractTemp | Out-Null
Expand-Archive -Path $zipPath -DestinationPath $extractTemp -Force
Remove-Item $zipPath -Force

$inner = Get-ChildItem $extractTemp -Directory | Select-Object -First 1
Copy-Item -Path (Join-Path $inner.FullName "*") -Destination $InstallDir -Recurse -Force
Remove-Item $extractTemp -Recurse -Force
Write-Ok "Source extracted to $InstallDir"

# -------------------------------------------------------------------
# 3b. Deploy agent skill
# -------------------------------------------------------------------
Write-Step "Deploying agent skill to $SkillDir"

$skillSrc = Join-Path $InstallDir "skill\SKILL.md"
if (Test-Path $skillSrc) {
    if (Test-Path $SkillDir) {
        if ($Force) {
            Remove-Item -Recurse -Force $SkillDir
        }
    }
    New-Item -ItemType Directory -Force -Path $SkillDir | Out-Null
    Copy-Item -Path $skillSrc -Destination (Join-Path $SkillDir "SKILL.md") -Force
    Write-Ok "Skill installed: $SkillDir\SKILL.md"
} else {
    Write-Warn2 "Skill source not found at $skillSrc - skipping skill deployment."
}

# -------------------------------------------------------------------
# 4. Create venv + install deps
# -------------------------------------------------------------------
Write-Step "Creating virtual environment"
$venvDir = Join-Path $InstallDir ".venv"
& cmd /c "$pythonCmd -m venv `"$venvDir`""
if ($LASTEXITCODE -ne 0) { Write-Err "venv creation failed"; exit 1 }

$venvPython = Join-Path $venvDir "Scripts\python.exe"
if (-not (Test-Path $venvPython)) { Write-Err "venv python missing"; exit 1 }

Write-Step "Installing dependencies"
& $venvPython -m pip install --upgrade pip | Out-Null
& $venvPython -m pip install -r (Join-Path $InstallDir "requirements.txt")
if ($LASTEXITCODE -ne 0) { Write-Err "pip install failed"; exit 1 }
Write-Ok "Dependencies installed"

# -------------------------------------------------------------------
# 5. Create bin shim
# -------------------------------------------------------------------
Write-Step "Creating launcher"

$binDir = Join-Path $InstallDir "bin"
New-Item -ItemType Directory -Force -Path $binDir | Out-Null

$shimPath = Join-Path $binDir "computer-use.cmd"
@"
@echo off
REM ComputerUse CLI launcher
"$venvPython" "$InstallDir\cli.py" %*
"@ | Set-Content -Path $shimPath -Encoding ASCII

Write-Ok "Launcher written: $shimPath"

# -------------------------------------------------------------------
# 6. Add bin to User PATH
# -------------------------------------------------------------------
Write-Step "Updating user PATH"

$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
if (-not $userPath) { $userPath = "" }
$pathParts = $userPath.Split(';') | Where-Object { $_ -ne "" }

if ($pathParts -notcontains $binDir) {
    $newPath = ($pathParts + $binDir) -join ';'
    [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
    Write-Ok "Added $binDir to User PATH"
    Write-Warn2 "Open a NEW terminal for PATH changes to take effect."
} else {
    Write-Ok "$binDir already on User PATH"
}

# Make it available for the rest of THIS session too
$env:Path = "$env:Path;$binDir"

# -------------------------------------------------------------------
# 7. Verify
# -------------------------------------------------------------------
Write-Step "Verifying install"
& $shimPath --help | Out-Null
if ($LASTEXITCODE -eq 0) {
    Write-Ok "computer-use is installed and working."
} else {
    Write-Err "Verification failed. Run manually: `"$shimPath`" --help"
    exit 1
}

Write-Host ""
Write-Host "ComputerUse CLI installed successfully." -ForegroundColor Green
Write-Host "Open a NEW PowerShell / CMD window, then try:" -ForegroundColor Green
Write-Host "  computer-use --help"
Write-Host "  computer-use vision"
Write-Host "  computer-use mouse-move 500 400"
Write-Host "  computer-use keyboard-shortcut alt_tab"
Write-Host ""
Write-Host "Install dir:  $InstallDir"
Write-Host "Launcher:     $shimPath"
Write-Host "Skill:        $SkillDir\SKILL.md"
Write-Host "Uninstall:    Remove $InstallDir, remove $SkillDir, and drop $binDir from User PATH."
