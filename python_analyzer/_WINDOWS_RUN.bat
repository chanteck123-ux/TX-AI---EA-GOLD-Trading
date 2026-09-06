@echo off
setlocal EnableExtensions DisableDelayedExpansion
chcp 65001 >nul
set "GSM_MANIFEST=%~f1"
set "GSM_OUTPUT=%~f2"
cd /d "%~dp0"
set "PYTHONUTF8=1"
set "PYTHONIOENCODING=utf-8"

if not defined GSM_MANIFEST goto missing_manifest
if not exist "%GSM_MANIFEST%" goto missing_manifest
if not defined GSM_OUTPUT set "GSM_OUTPUT=%~dp0output\custom"

py -3 -c "import sys; raise SystemExit(0 if sys.version_info >= (3, 10) else 1)" >nul 2>&1
if not errorlevel 1 goto run_py
python -c "import sys; raise SystemExit(0 if sys.version_info >= (3, 10) else 1)" >nul 2>&1
if not errorlevel 1 goto run_python
echo [失败] 未找到可用的 Python 3.10 或更高版本。
echo 请安装 Python 3.10+ 并启用 Python Launcher 或将 python 加入 PATH。
echo 本项目只用 Python 标准库，不需要安装 pip 依赖或配置 AI API。
exit /b 10

:run_py
echo 使用 Python Launcher 分析清单："%GSM_MANIFEST%"
py -3 -m gsm_analyzer analyze --manifest "%GSM_MANIFEST%" --output "%GSM_OUTPUT%"
set "GSM_EXIT=%ERRORLEVEL%"
goto result

:run_python
echo 使用 Python 分析清单："%GSM_MANIFEST%"
python -m gsm_analyzer analyze --manifest "%GSM_MANIFEST%" --output "%GSM_OUTPUT%"
set "GSM_EXIT=%ERRORLEVEL%"
goto result

:result
if not "%GSM_EXIT%"=="0" goto failed
if not exist "%GSM_OUTPUT%\report.html" goto missing_report
echo.
echo [完成] 中文报告："%GSM_OUTPUT%\report.html"
echo 研究分析结果，不能代表 MT5 真实 Tick 验证通过或已批准实盘。
start "" "%GSM_OUTPUT%\report.html"
exit /b 0

:failed
echo.
echo [失败] 分析器退出码：%GSM_EXIT%。请查看上面的错误信息。
echo 本次不会打开可能残留的旧报告。
exit /b %GSM_EXIT%

:missing_manifest
echo [失败] 数据清单不存在："%GSM_MANIFEST%"
echo 请把清单放在 input\manifest.json，或拖入自己的 manifest.json。
echo 也可以双击 START_WINDOWS.bat 选择合成示例或 FxPro 历史资料。
exit /b 2

:missing_report
echo [失败] 分析器返回成功，但没有找到 report.html；请检查输出目录。
exit /b 3
