@echo off
setlocal EnableExtensions DisableDelayedExpansion
chcp 65001 >nul
cd /d "%~dp0"

:menu
echo.
echo ============================================================
echo GSM Gold Python Analyzer - 离线研发分析
echo 不连接实盘、不下单、不使用付费 AI API
echo ============================================================
echo [1] 合成示例：只验证工具功能，不是真实 EA 回测成绩
echo [2] FxPro V4.00 历史证据：待验证基准，不是本次新回测
echo [3] 选择自己的 manifest.json 数据清单
echo [0] 退出
echo.
choice /c 1230 /n /m "请选择 1 / 2 / 3 / 0："
if errorlevel 255 exit /b 2
if errorlevel 4 exit /b 0
if errorlevel 3 goto custom
if errorlevel 2 goto historical
if errorlevel 1 goto synthetic
exit /b 2

:synthetic
call "%~dp0_WINDOWS_RUN.bat" "%~dp0examples\synthetic\manifest.json" "%~dp0output\demo"
set "GSM_EXIT=%ERRORLEVEL%"
goto finish

:historical
call "%~dp0_WINDOWS_RUN.bat" "%~dp0examples\fxpro_v400\manifest.json" "%~dp0output\fxpro_v400"
set "GSM_EXIT=%ERRORLEVEL%"
goto finish

:custom
set "GSM_MANIFEST="
echo 输入 manifest.json 完整路径；可以把文件拖入此窗口后按 Enter。
set /p "GSM_MANIFEST=清单路径："
if not defined GSM_MANIFEST goto menu
set "GSM_MANIFEST=%GSM_MANIFEST:"=%"
call "%~dp0_WINDOWS_RUN.bat" "%GSM_MANIFEST%" "%~dp0output\custom"
set "GSM_EXIT=%ERRORLEVEL%"
goto finish

:finish
echo.
echo 本次运行结束。退出码：%GSM_EXIT%
pause
exit /b %GSM_EXIT%
