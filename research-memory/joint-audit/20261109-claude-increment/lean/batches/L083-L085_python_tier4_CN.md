# L083–L085 第 4 层：Algorithm.Python 示例（续）（Claude，2026-11-08）

**方式**：同 L072–L082，只读，没有安装或运行 Python。

## 一、覆盖范围（FULL_READ 39 个）
- L083 14 个、L084 13 个、L085 12 个（`py_unread_sorted.txt` 第 247–285 行）。
- 主要内容：自定义数据历史、Security.data 动态数据、合成器内置滚动窗口、自定义购买力模型、期货期权小时线、G10 货币 universe、期货日线模板、Black-Litterman、指数期权蝶式价差、Python 自定义指标、期权数据过滤、不同复权模式的历史、RollingWindow、期权指派、Renko、分红与拆股挂单调整、Top3 粗选、扩展时段 MOC、自定义波动率模型、自定义信号导出、备兑/保护性期权策略、期权合成、Volume Renko、Bybit 自定义数据、universe 退市边界、指标扩展 SMA、自定义历史数据源、持久化自定义 universe、黄金期货期权合约月份、三倍杠杆 ETF 衰减 Alpha、期权持仓量、OnEndOfDay 回调、均线交叉、原始价格 universe、退市事件。

## 二、与 V1.2 有关的发现（静态阅读）
1. **合成器内置两根 K 线的滚动窗口**（ConsolidatorRollingWindowRegression）：`consolidator[0]`（current）是刚合成的 K 线，`consolidator[1]`（previous）是上一根，默认窗口大小为 2。S7"反转闭柱确认"若在 LEAN 研究端实现，可直接用此窗口取"上一根已收 K 线"，但须注意窗口只包含已完成的 K 线，不含当前未收的那根。
2. **自定义数据的时区转换**（BybitCustomDataCryptoRegression）：读取器把文件中的时间按 `config.data_time_zone` 解释，再用 `Extensions.convert_to` 转为 `exchange_time_zone`，并显式设置 `end_time = time + 1 分钟`。若 LEAN 研究导入从 FxPro MT5 导出的 XAUUSD 数据，必须先确认 MT5 服务器时区（含夏令时切换），再按此方式转换，并让 `end_time` 与 K 线周期一致，否则 K 线边界与信号时间会错位。
3. **购买力模型可被改为"总是足够、维持保证金为 0"**（CustomBuyingPowerModelAlgorithm）：示例为避免追加保证金单而覆盖 `get_maintenance_margin` 返回 0。与 L080–L082 第 3 条一样，研究配置中应禁止此类覆盖，以免保证金与强平约束失效。
4. **分红/拆股时挂单调整取决于券商模型**（DividendAlgorithm 注释）：使用 Tradier 模型时，正向拆股会调整挂单以保持订单价值，反向拆股则撤销挂单。CFD 无拆股；仅说明"挂单的被动变化"由券商模型决定，与 L061–L063 第 2 条（被动撤单）同类。
5. **波动率模型年化同样用 252**（CustomVolatilityModelAlgorithm）：示例按 `std × sqrt(252)` 年化日收益率标准差。与 R31 一致：XAUUSD 若每周交易约 5 天但含周日开盘的短时段，年化口径需单独登记。
6. **信号导出可向任意 HTTP 端点发送**（CustomSignalExportDemonstrationAlgorithm）：示例向 `http://localhost:5000/` POST 持仓目标。V1.2 中 LEAN 只做研究，不应配置任何对外信号导出；仅记录这一能力存在。
7. **示例代码问题（不影响引擎）**：
   - `IndexOptionPutButterflyAlgorithm`、`IndexOptionCallButterflyAlgorithm`：`atm_strike = min([abs(x - 标的价) ...])` 取的是"最小距离"而不是"最接近的行权价"，后续用它计算行权价是错误的。
   - `PersistentCustomDataUniverseRegressionAlgorithm` 使用旧式大写方法名（`Initialize`、`OnData`、`OnEndOfAlgorithm`）。
   - `DelistingEventsAlgorithm` 在 DELISTED 事件后故意下单以演示失败。
8. 其余为第 4 层内容，只记录已读。

## 三、进度
- Algorithm.Python：.py 剩余未读 185 个；下一批从 `py_unread_sorted.txt` 第 286 行开始。
