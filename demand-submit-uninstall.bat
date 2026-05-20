@echo off
chcp 65001 >nul
setlocal

set "DEMAND_SUBMIT_REPO_ROOT=%~dp0"
set "UNINSTALL_PS=%TEMP%\demand-submit-uninstall-%RANDOM%-%RANDOM%.ps1"

echo demand-submit 卸载器
echo.
echo 即将卸载 demand-submit，并删除以下内容：
echo(  1. 已安装的 demand-submit skill
echo(  2. 当前 demand-submit-skill 项目目录
echo(  3. 脚本自动生成的日志和提交保护记录
echo.

> "%UNINSTALL_PS%" echo $ErrorActionPreference = 'Continue'
>> "%UNINSTALL_PS%" echo [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
>> "%UNINSTALL_PS%" echo Start-Sleep -Seconds 1
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
>> "%UNINSTALL_PS%" echo Write-Host ('Removing project directory: ' + $repoRoot^)
>> "%UNINSTALL_PS%" echo Start-Sleep -Seconds 1
>> "%UNINSTALL_PS%" echo try {
>> "%UNINSTALL_PS%" echo   Remove-Item -LiteralPath $repoRoot -Recurse -Force -ErrorAction Stop
>> "%UNINSTALL_PS%" echo   Write-Host 'Uninstall finished.'
>> "%UNINSTALL_PS%" echo } catch {
>> "%UNINSTALL_PS%" echo   Write-Host ('Project directory removal failed: ' + $_.Exception.Message^)
>> "%UNINSTALL_PS%" echo   Write-Host 'Close editors or terminals opened inside the project directory, then delete it manually.'
>> "%UNINSTALL_PS%" echo }
>> "%UNINSTALL_PS%" echo Remove-Item -LiteralPath $PSCommandPath -Force -ErrorAction SilentlyContinue
>> "%UNINSTALL_PS%" echo Start-Sleep -Seconds 3

start "demand-submit uninstall" /D "%TEMP%" powershell -NoProfile -ExecutionPolicy Bypass -File "%UNINSTALL_PS%"

echo 卸载任务已启动，请在新打开的 PowerShell 窗口查看结果。
exit /b 0
