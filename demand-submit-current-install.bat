@echo off
setlocal

set "DEMAND_SUBMIT_REF=main"
set "GITEE_BOOTSTRAP=https://gitee.com/bingjiu-lei/demand-submit-skill/raw/%DEMAND_SUBMIT_REF%/bootstrap.ps1"
set "GITHUB_BOOTSTRAP=https://raw.githubusercontent.com/bingjiu-lei/demand-submit-skill/%DEMAND_SUBMIT_REF%/bootstrap.ps1"

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$ErrorActionPreference='Stop';" ^
  "$bootstrap = Join-Path $env:TEMP 'demand-submit-bootstrap.ps1';" ^
  "try { Invoke-WebRequest '%GITEE_BOOTSTRAP%' -OutFile $bootstrap } catch { Write-Host 'Gitee bootstrap failed, falling back to GitHub...'; Invoke-WebRequest '%GITHUB_BOOTSTRAP%' -OutFile $bootstrap };" ^
  "& powershell -NoProfile -ExecutionPolicy Bypass -File $bootstrap -Ref '%DEMAND_SUBMIT_REF%'"

if errorlevel 1 (
  echo.
  echo Installation failed.
  pause
  exit /b 1
)

echo.
echo Installation finished.
pause
