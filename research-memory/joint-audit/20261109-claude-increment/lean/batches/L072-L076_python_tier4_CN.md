# L072–L076 第 4 层：Algorithm.Python 支持文件与示例（第一部分）（Claude，2026-11-08）

**方式**：只读，没有安装或运行 Python，也没有编译。示例用 `tools/print_example_py.sh` 打印：仅在第 1–12 行全部是 `#` 注释（许可证头）时跳过这 12 行，另外跳过空行和 `from AlgorithmImports import *`，其余每行带行号输出。清单 `scratchpad/py_unread_sorted.txt` 按文件大小升序排列（470 个 .py）。

## 一、覆盖范围（FULL_READ 137 个）
- L072：项目支持文件 7 个，用 `cat -n` 读全文：`Properties/AssemblyInfo.cs`、`PythonAlgorithm.cs`（占位项目）、`QuantConnect.Algorithm.Python.csproj`、`QuantConnect.Algorithm.PythonTools.pyproj`、`build.bat`、`build.sh`、`readme.md`。
- L073 40 个、L074 35 个、L075 30 个、L076 25 个 .py 示例（清单第 1–130 行）。内容多为 C# 示例的 Python 版本或子类化变体：异步下单变体、期货扩展时段、Range/Renko 合成器、框架 Alpha/风险模型回归、期权价格模型适用性、ETF 成分 universe、预热回调、Quit、Tick 历史、PEP8 风格 API 等。

## 二、与 V1.2 有关的发现（静态阅读）
1. **Python 版 LEAN 的环境要求**（readme.md）：Python 3.11.11、pandas 2.2.3、wrapt 1.16.0，经 QuantConnect.pythonnet 2.0.68 嵌入，并需设置 `PYTHONNET_PYDLL`。V1.2 的 LEAN 研究端用 C#，Python 只用于 MCP 监控，因此 Python 版 LEAN 不在研究路径上；此处只记录版本，未安装。
2. **build 脚本会编译整个上层目录并复制 .pyc**（build.bat/build.sh）：`compileall` 作用于 `..\..\`，并刻意吞掉错误（脚本注释写明退出码固定为 0）。若将来有人在本机构建 LEAN，Python 示例的语法错误不会使构建失败。仅记录，不执行。
3. **SecurityDataFilter 可在数据进入算法前丢弃数据**（CustomSecurityDataFilterRegression）：可用于过滤异常 tick；研究中若使用，过滤规则须登记，否则会改变成交与指标输入。
4. **风险管理模型叠加**：`CompositeRiskManagementModel`、`MaximumDrawdownPercentPortfolio(0.015, True)`（按盈利回撤）、`MaximumUnrealizedProfitPercentPerSecurity` 等可以组合。LEAN 框架的风险模型是"对目标仓位做调整"，与 V1.2 RiskExecution 的"新增风险门控 + 既有仓位保护"分层不同，仅作概念对照。
5. **示例代码问题（不影响引擎）**：
   - `FuncRiskFreeRateInterestRateModelWithPythonLambda`：`self.time.date == datetime(...)` 与 lambda 中 `dt.date != datetime(...)` 都把方法对象与 datetime 比较，结果恒为不相等，断言逻辑实际没有检验想检验的日期。
   - `BasicTemplateIndexAlgorithm`：`ema_slow` 周期为 80、`ema_fast` 周期为 200，名称与周期相反。
   - `IndexOptionBullPutSpreadAlgorithm`：变量名 `bull_call_spread` 实为 bull put spread。
   - `AddRiskManagementAlgorithm`：构造了 `risk_model` 却没有使用，随后另行设置。
   - `AutoRegressiveIntegratedMovingAverageRegression`：首次就绪时 `self._last` 仍为 None，若当根即满足差值条件会与 None 比较。
6. 其余为第 4 层内容，只记录已读。

## 三、进度
- Algorithm.Python：.py 剩余未读 340 个；下一批从 `py_unread_sorted.txt` 第 131 行开始（`next_batch_py.sh 131 <n> 077`）。
