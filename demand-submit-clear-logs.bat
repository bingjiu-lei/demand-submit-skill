@echo off
chcp 65001 >nul
setlocal

set "LOG_DIR=%~dp0demand-submit-logs"

echo demand-submit 闂傚倷绀侀幖顐﹀疮閵娾晛纾块弶鍫氭櫆瀹曟煡鏌￠崒婵撻獜闁逞屽墯鐢€崇暦閵娾晩鏁嶆繛鎴炃氶崑鎾绘倷閻戞鍘?echo.
echo 闂傚倷绀侀幉锟犮€冮崨鏉戠柈闁秆勵殕閸庡秹鏌曡箛瀣偓鏇犵矆閸℃稒鐓熸俊顖濆亹鐢盯鏌ｅ┑鍫濇灈闁哄矉绻濆畷姗€鏁冮埀顒勫礉濮樿京纾肩紓浣股戦ˉ鍫ユ煙椤栨艾顏い銏＄懇閹虫牠鍩￠崘鍐惧弮濮?echo   %LOG_DIR%
echo.

if not exist "%LOG_DIR%" (
  echo 闂佽崵鍠愮划搴㈡櫠濡ゅ懎绠伴柛娑橈攻濞呯娀鏌ｅΟ鑽ゃ偞闁哄矉绠撻弻宥夊煛娴ｅ憡娈茬紓浣哄У鐢繝寮诲☉妯锋瀻婵☆垵娅ｆ禒鈺呮⒑閹肩偛濡肩紓宥咃工椤繑绂掔€ｎ€囨煕閵夛絽濡块柡鍡欏█濮婃椽宕崟顐ｆ闂佺姘︽禍顒勫箲閵忋倕绫嶉柛顐ゅ枎閸擃喖顪冮妶鍡橆梿闁稿鍔楃划鏃堝锤濡や胶鍘?  pause
  exit /b 0
)

powershell -NoProfile -ExecutionPolicy Bypass -Command "Remove-Item -LiteralPath '%LOG_DIR%' -Recurse -Force"
if errorlevel 1 (
  echo 闂傚倷绀侀幖顐﹀疮閵娾晛纾块弶鍫氭櫆瀹曟煡鏌￠崒婵撻獜闁逞屽墯鐢€崇暦閵娾晩鏁嶆繛鎴炃氶崑鎾绘倷瀹割喚鍞甸梺璇″灡婢瑰棛鑺遍崸妤佸仭婵炲棙鐟ч悾闈涒攽?  pause
  exit /b 1
)

echo 闂傚倷绀侀幖顐﹀疮閵娾晛纾块弶鍫氭櫆瀹曟煡鏌￠崒婵撻獜闁逞屽墯鐢€崇暦閵娾晩鏁嶆繛鎴炃氶崑鎾绘倷閻戞ê鈧敻鏌ｉ悢鍝勵暭婵犫偓娴煎瓨鐓曢柕濠忕畱閸濆搫鈹?pause
