@echo off
setlocal

set "GITEE_BOOTSTRAP=https://gitee.com/bingjiu-lei/demand-submit-skill/raw/main/bootstrap.ps1"
set "GITHUB_BOOTSTRAP=https://raw.githubusercontent.com/bingjiu-lei/demand-submit-skill/main/bootstrap.ps1"

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$ErrorActionPreference='Stop';" ^
  "try { $script = Invoke-RestMethod '%GITEE_BOOTSTRAP%' } catch { Write-Host 'Gitee bootstrap failed, falling back to GitHub...'; $script = Invoke-RestMethod '%GITHUB_BOOTSTRAP%' }" ^
  "Invoke-Expression $script"

if errorlevel 1 (
  echo.
  echo Installation failed.
  pause
  exit /b 1
)

echo.
echo Installation finished.
pause


