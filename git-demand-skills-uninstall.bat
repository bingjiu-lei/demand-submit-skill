@echo off
chcp 65001 >nul
setlocal

set "DEMAND_SUBMIT_REPO_ROOT=%~dp0"
set "UNINSTALL_PS=%TEMP%\git-demand-skills-uninstall-%RANDOM%-%RANDOM%.ps1"

echo git-demand-skills 卸载器
echo.
echo 即将卸载并删除：
echo   1. 已安装的 demand-submit skill
echo   2. 已安装的 demand-merge skill
echo   3. 当前 git-demand-skills 项目目录
echo   4. 脚本自动生成的日志和旧版本遗留记录
echo.

> "%UNINSTALL_PS%" echo $ErrorActionPreference = 'Continue'
>> "%UNINSTALL_PS%" echo [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
>> "%UNINSTALL_PS%" echo Start-Sleep -Seconds 2
>> "%UNINSTALL_PS%" echo $repoRoot = (Resolve-Path $env:DEMAND_SUBMIT_REPO_ROOT^).Path.TrimEnd('\')
>> "%UNINSTALL_PS%" echo $codexHome = Join-Path $env:USERPROFILE '.codex'
>> "%UNINSTALL_PS%" echo $paths = @(
>> "%UNINSTALL_PS%" echo   (Join-Path $codexHome 'skills\demand-submit'^),
>> "%UNINSTALL_PS%" echo   (Join-Path $codexHome 'skills\demand-merge'^),
>> "%UNINSTALL_PS%" echo   (Join-Path $codexHome 'skills\demand-git'^),
>> "%UNINSTALL_PS%" echo   (Join-Path $repoRoot 'demand-skill-logs'^),
>> "%UNINSTALL_PS%" echo   (Join-Path $repoRoot 'demand-submit-logs'^),
>> "%UNINSTALL_PS%" echo   (Join-Path $codexHome 'demand-submit-backups'^),
>> "%UNINSTALL_PS%" echo   (Join-Path $codexHome 'demand-git-backups'^)
>> "%UNINSTALL_PS%" echo )
>> "%UNINSTALL_PS%" echo foreach ($path in $paths^) {
>> "%UNINSTALL_PS%" echo   if (Test-Path -LiteralPath $path^) {
>> "%UNINSTALL_PS%" echo     Remove-Item -LiteralPath $path -Recurse -Force
>> "%UNINSTALL_PS%" echo     Write-Host ('已删除: ' + $path^)
>> "%UNINSTALL_PS%" echo   }
>> "%UNINSTALL_PS%" echo }
>> "%UNINSTALL_PS%" echo Write-Host ('正在删除项目目录: ' + $repoRoot^)
>> "%UNINSTALL_PS%" echo try {
>> "%UNINSTALL_PS%" echo   Remove-Item -LiteralPath $repoRoot -Recurse -Force -ErrorAction Stop
>> "%UNINSTALL_PS%" echo   Write-Host '卸载完成。'
>> "%UNINSTALL_PS%" echo } catch {
>> "%UNINSTALL_PS%" echo   Write-Host ('项目目录删除失败: ' + $_.Exception.Message^)
>> "%UNINSTALL_PS%" echo   Write-Host '请关闭打开在项目目录里的编辑器、终端或资源管理器后，再重新执行卸载。'
>> "%UNINSTALL_PS%" echo }
>> "%UNINSTALL_PS%" echo Remove-Item -LiteralPath $PSCommandPath -Force -ErrorAction SilentlyContinue
>> "%UNINSTALL_PS%" echo Start-Sleep -Seconds 3

start "demand-submit uninstall" /D "%TEMP%" powershell -NoProfile -ExecutionPolicy Bypass -File "%UNINSTALL_PS%"

echo 卸载任务已启动，请在新打开的 PowerShell 窗口查看结果。
exit /b 0
