@echo off
setlocal

set "REPO_DIR=%~dp0"
set "REPO_ROOT=%~dp0."
set "SOURCE_PS=%REPO_DIR%scripts\git-demand-skills-uninstall.ps1"
set "TEMP_PS=%TEMP%\git-demand-skills-uninstall-%RANDOM%-%RANDOM%.ps1"

if not exist "%SOURCE_PS%" (
  echo Cannot find uninstall script:
  echo   %SOURCE_PS%
  pause
  exit /b 1
)

copy /Y "%SOURCE_PS%" "%TEMP_PS%" >nul
if errorlevel 1 (
  echo Failed to prepare uninstall script.
  pause
  exit /b 1
)

start "git-demand-skills uninstall" /D "%TEMP%" powershell -NoProfile -ExecutionPolicy Bypass -File "%TEMP_PS%" -RepoRoot "%REPO_ROOT%"

echo Uninstall task started. Check the new PowerShell window for details.
exit /b 0
