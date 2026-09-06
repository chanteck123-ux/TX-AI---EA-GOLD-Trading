@echo off
setlocal EnableExtensions DisableDelayedExpansion
chcp 65001 >nul
rem Resolve a dragged or command-line path before changing the directory.
set "GSM_MANIFEST=%~f1"
cd /d "%~dp0"
if not defined GSM_MANIFEST set "GSM_MANIFEST=%~dp0input\manifest.json"
call "%~dp0_WINDOWS_RUN.bat" "%GSM_MANIFEST%" "%~dp0output\custom"
set "GSM_EXIT=%ERRORLEVEL%"
echo.
echo 本次运行结束。退出码：%GSM_EXIT%
pause
exit /b %GSM_EXIT%
