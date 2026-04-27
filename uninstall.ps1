# ComputerUse CLI - Windows Uninstaller
# One-liner uninstall (PowerShell):
#   irm https://raw.githubusercontent.com/asterxsk/ComputerUse/main/uninstall.ps1 | iex
#
# What this does:
#   1. Removes %LOCALAPPDATA%\ComputerUse (venv + source).
#   2. Removes %USERPROFILE%\.agents\skills\ComputerUse (agent skill).
#   3. Drops %LOCALAPPDATA%\ComputerUse\bin from the current user's PATH.
#
# Flags:
#   -InstallDir  Override install dir (default: %LOCALAPPDATA%\ComputerUse).
#   -SkillDir    Override skill dir   (default: %USERPROFILE%\.agents\skills\ComputerUse).
#   -KeepSkill   Leave the agent skill in place.
#   -Force       Skip confirmation prompt.

[CmdletBinding()]
param(
    [string]$InstallDir = "$env:LOCALAPPDATA\ComputerUse",
    [string]$SkillDir   = "$env:USERPROFILE\.agents\skills\ComputerUse",
    [switch]$KeepSkill,
    [switch]$Force
)

$ErrorActionPreference = "Stop"

function Write-Step($msg)  { Write-Host "==> $msg" -ForegroundColor Cyan }
function Write-Ok($msg)    { Write-Host "    $msg"  -ForegroundColor Green }
function Write-Warn2($msg) { Write-Host "    $msg"  -ForegroundColor Yellow }
function Write-Err($msg)   { Write-Host "    $msg"  -ForegroundColor Red }

$binDir = Join-Path $InstallDir "bin"

Write-Host "ComputerUse CLI uninstaller" -ForegroundColor Cyan
Write-Host "  Install dir: $InstallDir"
if (-not $KeepSkill) {
    Write-Host "  Skill dir:   $SkillDir"
}
Write-Host "  PATH entry:  $binDir"
Write-Host ""

if (-not $Force) {
    $confirm = Read-Host "Proceed with uninstall? (y/N)"
    if ($confirm -ne 'y') {
        Write-Warn2 "Cancelled."
        exit 0
    }
}

# -------------------------------------------------------------------
# 1. Remove install dir
# -------------------------------------------------------------------
Write-Step "Removing install directory"
if (Test-Path $InstallDir) {
    try {
        Remove-Item -Recurse -Force $InstallDir
        Write-Ok "Removed $InstallDir"
    } catch {
        Write-Err "Could not remove $InstallDir"
        Write-Err $_.Exception.Message
        Write-Warn2 "Close any shells or editors holding files inside it and retry."
    }
} else {
    Write-Warn2 "Not present: $InstallDir"
}

# -------------------------------------------------------------------
# 2. Remove skill dir
# -------------------------------------------------------------------
if (-not $KeepSkill) {
    Write-Step "Removing agent skill"
    if (Test-Path $SkillDir) {
        try {
            Remove-Item -Recurse -Force $SkillDir
            Write-Ok "Removed $SkillDir"
        } catch {
            Write-Err "Could not remove $SkillDir"
            Write-Err $_.Exception.Message
        }
    } else {
        Write-Warn2 "Not present: $SkillDir"
    }
} else {
    Write-Warn2 "Keeping skill dir: $SkillDir"
}

# -------------------------------------------------------------------
# 3. Clean User PATH
# -------------------------------------------------------------------
Write-Step "Cleaning User PATH"
$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
if (-not $userPath) { $userPath = "" }
$parts = $userPath.Split(';') | Where-Object { $_ -and ($_ -ne $binDir) }
$newPath = ($parts -join ';')

if ($newPath -ne $userPath) {
    [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
    Write-Ok "Removed $binDir from User PATH"
    Write-Warn2 "Open a NEW terminal for PATH changes to take effect."
} else {
    Write-Warn2 "$binDir was not on User PATH"
}

Write-Host ""
Write-Host "ComputerUse CLI uninstalled." -ForegroundColor Green
