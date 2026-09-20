@echo off
setlocal
cd /d "%~dp0"
chcp 65001 >nul
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$p=Join-Path '%~dp0' 'Run-GoldBacktest.ps1'; $t=$null; $e=$null; [void][System.Management.Automation.Language.Parser]::ParseFile($p,[ref]$t,[ref]$e); if($e.Count -gt 0){$e | ForEach-Object {Write-Host $_.Message}; exit 1}"
if errorlevel 1 goto failed
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Run-GoldBacktest.ps1"
if errorlevel 1 goto failed
echo.
echo Four gold backtests completed. Read completion_receipt.json and the Chinese report.
pause
exit /b 0
:failed
echo.
echo Incomplete. Keep the logs; do not assume the strategy passed.
pause
exit /b 1
