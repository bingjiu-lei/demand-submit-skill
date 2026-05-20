@echo off
setlocal

set "DEMAND_SUBMIT_REF=v0.1.0"
rem v0.1.0 鐨?tag 閲岃繕娌℃湁 -Ref 瀹夎鑳藉姏锛屾墍浠ヨ繖閲屼娇鐢?main 涓婄殑鏂板畨瑁呭櫒鑳藉姏锛?rem 浣嗗疄闄?clone/checkout 鐨勯」鐩唬鐮佷粛鐒堕攣瀹氫负 v0.1.0銆?set "GITEE_BOOTSTRAP=https://gitee.com/bingjiu-lei/demand-submit-skill/raw/main/bootstrap.ps1"
set "GITHUB_BOOTSTRAP=https://raw.githubusercontent.com/bingjiu-lei/demand-submit-skill/main/bootstrap.ps1"

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
