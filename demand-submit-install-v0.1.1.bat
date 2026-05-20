@echo off
setlocal

set "DEMAND_SUBMIT_REF=v0.1.1"
rem v0.1.1 闂?tag 闂備焦褰冮惌浣烘崲閺囩偐鏌﹂柍鈺佸暞缁?-Ref 闁诲海鎳撻ˇ鎶剿夋繝鍥ㄥ殑闁芥ê顦～鏃堟煥濞戞ɑ婀板褍绉电粋鎺楀Ψ閵娧咁啇闂備焦褰冩總鏃€绻涢崶顒佸仺?main 婵炴垶鎸搁敃锕€鈻撻幋锕€妫橀柡澶庢硶閺嗘棃鎮锋担鍛婂櫣婵炲懏甯￠幊妤呮寠婢跺娼濋梺?rem 婵炶揪绲藉Λ妤呮偪閸曨垱鈷?clone/checkout 闂佹眹鍔岀€氫即濡村澶嬪剮妞ゆ棁顕ч弫鈺呮煟椤旂粯顦风紒顔界洴閹偤宕奸弴鐔告殎闁诲氦顫夐惌顔炬嫻?v0.1.1闂?set "GITEE_BOOTSTRAP=https://gitee.com/bingjiu-lei/demand-submit-skill/raw/main/bootstrap.ps1"
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
