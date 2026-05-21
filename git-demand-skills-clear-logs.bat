@echo off
chcp 65001 >nul
setlocal

set "LOG_DIR=%~dp0demand-skill-logs"
set "OLD_LOG_DIR=%~dp0demand-submit-logs"

echo git-demand-skills 日志清理器
echo.
echo 将删除脚本自动生成的日志目录：
echo   %LOG_DIR%
echo   %OLD_LOG_DIR%
echo.

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$paths = @('%LOG_DIR%', '%OLD_LOG_DIR%'); foreach ($path in $paths) { if (Test-Path -LiteralPath $path) { Remove-Item -LiteralPath $path -Recurse -Force; Write-Host ('已删除: ' + $path) } }; Write-Host '日志清理完成。'"

if errorlevel 1 (
  echo 日志清理失败，请关闭占用日志目录的程序后重试。
  pause
  exit /b 1
)

pause
