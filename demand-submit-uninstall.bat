@echo off
chcp 65001 >nul
setlocal

echo demand-submit 卸载器
echo.
echo 即将卸载 demand-submit。
echo.
echo 默认会删除：
echo   1. 已安装的 skill
echo   2. clone 下来的 demand-submit-skill 项目目录
echo.
echo 脚本自动生成的提交保护记录默认不会删除。
echo.

set "REMOVE_PROJECT=Y"
set /p "REMOVE_PROJECT=是否同时删除 clone 下来的项目目录？[Y/n] "
set "ARGS="
if /I not "%REMOVE_PROJECT%"=="N" set "ARGS=%ARGS% -RemoveProject"

set "REMOVE_BACKUPS=N"
set /p "REMOVE_BACKUPS=是否删除脚本自动生成的提交保护记录？[y/N] "
if /I "%REMOVE_BACKUPS%"=="Y" set "ARGS=%ARGS% -RemoveBackups"

pushd "%TEMP%"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0uninstall.ps1" %ARGS%
set "RESULT=%ERRORLEVEL%"
popd

echo.
if not "%RESULT%"=="0" (
  echo 卸载失败。
  pause
  exit /b %RESULT%
)

echo 卸载完成。
pause
