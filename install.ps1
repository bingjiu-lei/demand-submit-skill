param(
    [string]$CodexHome = (Join-Path $env:USERPROFILE ".codex")
)

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$skillSource = Join-Path $repoRoot "skill\demand-submit"
$scriptPath = Join-Path $repoRoot "scripts\demand-submit.ps1"
$skillTarget = Join-Path $CodexHome "skills\demand-submit"
$oldSkillTarget = Join-Path $CodexHome "skills\demand-git"
$uninstallScript = Join-Path $repoRoot "uninstall.ps1"

if (-not (Test-Path -LiteralPath $scriptPath)) {
    throw "Cannot find demand-submit script: $scriptPath"
}
if (-not (Test-Path -LiteralPath $uninstallScript)) {
    throw "Cannot find demand-submit uninstall script: $uninstallScript"
}

New-Item -ItemType Directory -Force -Path (Split-Path -Parent $skillTarget) | Out-Null

if (Test-Path -LiteralPath $skillTarget) {
    Remove-Item -LiteralPath $skillTarget -Recurse -Force
}
if (Test-Path -LiteralPath $oldSkillTarget) {
    Remove-Item -LiteralPath $oldSkillTarget -Recurse -Force
}

Copy-Item -LiteralPath $skillSource -Destination $skillTarget -Recurse -Force

$installedSkill = Join-Path $skillTarget "SKILL.md"
$content = Get-Content -Raw -LiteralPath $installedSkill
$content = $content.Replace("{{DEMAND_SUBMIT_SCRIPT_PATH}}", $scriptPath)
Set-Content -LiteralPath $installedSkill -Value $content -Encoding UTF8

$installedUninstaller = Join-Path $skillTarget "demand-submit-uninstall.bat"
$uninstallBat = @"
@echo off
chcp 65001 >nul
setlocal

echo demand-submit uninstaller
echo.
echo This will remove the installed skill from:
echo   $skillTarget
echo.
echo It can also remove the cloned project directory:
echo   $repoRoot
echo.

set "REMOVE_PROJECT=Y"
set /p "REMOVE_PROJECT=Remove cloned project directory too? [Y/n] "
set "ARGS="
if /I not "%REMOVE_PROJECT%"=="N" set "ARGS=%ARGS% -RemoveProject"

set "REMOVE_BACKUPS=N"
set /p "REMOVE_BACKUPS=Remove script-generated safety records too? [y/N] "
if /I "%REMOVE_BACKUPS%"=="Y" set "ARGS=%ARGS% -RemoveBackups"

pushd "%TEMP%"
powershell -NoProfile -ExecutionPolicy Bypass -File "$uninstallScript" %ARGS%
set "RESULT=%ERRORLEVEL%"
popd

echo.
if not "%RESULT%"=="0" (
  echo Uninstall failed.
  pause
  exit /b %RESULT%
)

echo Uninstall finished.
pause
"@
Set-Content -LiteralPath $installedUninstaller -Value $uninstallBat -Encoding UTF8

Write-Host "Installed demand-submit skill to: $skillTarget"
Write-Host "Installed uninstaller to:"
Write-Host "  $installedUninstaller"
Write-Host "Codex does not need to be installed; this only writes files under:"
Write-Host "  $CodexHome\skills"
Write-Host "Any AI tool that scans .codex\skills can load it."
Write-Host "Configured script path:"
Write-Host "  $scriptPath"
Write-Host "Ask an AI agent:"
Write-Host '  Use demand-submit for demand 197462 with title "demand title".'
