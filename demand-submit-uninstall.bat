@echo off
chcp 65001 >nul
setlocal

set "DEMAND_SUBMIT_REPO_ROOT=%~dp0"
set "UNINSTALL_PS=%TEMP%\demand-submit-uninstall-%RANDOM%-%RANDOM%.ps1"

echo demand-submit 卸载器
echo.
echo 即将卸载 demand-submit，并删除以下内容：
echo   1. 已安装的 demand-submit skill
echo   2. 当前 demand-submit-skill 项目目录
echo   3. 脚本自动生成的日志和提交保护记录
echo.

> "%UNINSTALL_PS%" echo $ErrorActionPreference = 'Stop'
>> "%UNINSTALL_PS%" echo [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
>> "%UNINSTALL_PS%" echo $repoRoot = (Resolve-Path $env:DEMAND_SUBMIT_REPO_ROOT^).Path.TrimEnd('\')
>> "%UNINSTALL_PS%" echo $codexHome = Join-Path $env:USERPROFILE '.codex'
>> "%UNINSTALL_PS%" echo $paths = @(
>> "%UNINSTALL_PS%" echo   (Join-Path $codexHome 'skills\demand-submit'^),
>> "%UNINSTALL_PS%" echo   (Join-Path $codexHome 'skills\demand-git'^),
>> "%UNINSTALL_PS%" echo   (Join-Path $repoRoot 'demand-submit-logs'^),
>> "%UNINSTALL_PS%" echo   (Join-Path $codexHome 'demand-submit-backups'^),
>> "%UNINSTALL_PS%" echo   (Join-Path $codexHome 'demand-git-backups'^)
>> "%UNINSTALL_PS%" echo )
>> "%UNINSTALL_PS%" echo foreach ($path in $paths^) {
>> "%UNINSTALL_PS%" echo   if (Test-Path -LiteralPath $path^) {
>> "%UNINSTALL_PS%" echo     Remove-Item -LiteralPath $path -Recurse -Force
>> "%UNINSTALL_PS%" echo     Write-Host ('Removed: ' + $path^)
>> "%UNINSTALL_PS%" echo   }
>> "%UNINSTALL_PS%" echo }
>> "%UNINSTALL_PS%" echo $quotedRepoRoot = "'" + $repoRoot.Replace("'", "''"^) + "'"
>> "%UNINSTALL_PS%" echo $deleteScript = 'Start-Sleep -Seconds 2; Remove-Item -LiteralPath ' + $quotedRepoRoot + ' -Recurse -Force'
>> "%UNINSTALL_PS%" echo Start-Process -FilePath powershell -ArgumentList @('-NoProfile','-ExecutionPolicy','Bypass','-Command',$deleteScript^) -WindowStyle Hidden
>> "%UNINSTALL_PS%" echo Write-Host ('Removing project directory: ' + $repoRoot^)

powershell -NoProfile -ExecutionPolicy Bypass -File "%UNINSTALL_PS%"
set "RESULT=%ERRORLEVEL%"
del "%UNINSTALL_PS%" >nul 2>nul

echo.
if not "%RESULT%"=="0" (
  echo 卸载失败。
  pause
  exit /b %RESULT%
)

echo 卸载完成。
pause
