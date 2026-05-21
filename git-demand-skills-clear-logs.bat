@echo off
setlocal

set "REPO_ROOT=%~dp0."
set "SOURCE_PS=%REPO_ROOT%scripts\git-demand-skills-clear-logs.ps1"

if not exist "%SOURCE_PS%" (
  echo Cannot find log cleanup script:
  echo   %SOURCE_PS%
  pause
  exit /b 1
)

powershell -NoProfile -ExecutionPolicy Bypass -File "%SOURCE_PS%" -RepoRoot "%REPO_ROOT%"
if errorlevel 1 (
  echo Log cleanup failed.
  pause
  exit /b 1
)

pause
