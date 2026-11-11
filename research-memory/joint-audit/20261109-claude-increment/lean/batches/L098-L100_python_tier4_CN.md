# L098–L100 第 4 层：Algorithm.Python 示例（续）（Claude，2026-11-08）

**方式**：同 L072–L097，只读，没有安装或运行 Python。

## 一、覆盖范围（FULL_READ 22 个）
- L098 8 个、L099 7 个、L100 7 个（`py_unread_sorted.txt` 第 399–420 行）。
- 主要内容：连续期货换月（Python 版）、Consolidate 按数量/Renko/Range、期权镜像指标、期货/指数期权到期（多份同构）、比特币自定义数据回归、Security.Session、ObjectStore 降序数据、按揭利率波动 Alpha、Collective2 信号、辅助数据历史、自定义数据属性、**条件单撤销**、TensorFlow、午间均值回归 Alpha、ETF 成分框架、NIFTY 自定义数据。

## 二、与 V1.2 有关的发现（静态阅读）
1. **撤销 OCO 组中的任何一张会撤销整组，包括止损**（ContingentOrderCancelRegressionAlgorithm）：
   - 撤销父单会撤销它将触发的全部子单，以及子单将再触发的订单，撤单消息为 "Contingent parent order … was canceled"。
   - 在括号单中撤销"等待触发的止盈单"，同组的止损单也一并撤销，消息为 "Contingent sibling order … was canceled"；父单（入场限价单）继续工作。
   - 在已持仓后的 OCO 组中撤销任一成员，其余成员一并撤销。
   - 对 V1.2：若 LEAN 研究用 OCO/括号单表示 SL/TP，任何"只想改止盈"的撤单操作都会让持仓失去止损保护，这与 V1.2"已有仓位保护先于其他操作、不能被阻断"的原则冲突。研究实现中修改止盈应使用改单（update），不能撤单重挂；该行为作为 R35 的补充证据一并记录。
2. **期货期权到期与清算时点**（FuturesAndFuturesOptionsExpiryTimeAndLiquidation）：退市警告在到期日、退市在次日；期货在退市时点或其前 1 分钟清算。CFD 不涉及，仅记录。
3. **凭据处理**：`CustomDataRegressionAlgorithm.py` 的数据源 URL 内嵌 api_key 参数，笔记中不转录其值。
4. **示例代码问题（不影响引擎）**：
   - `MortgageRateVolatilityAlpha`：第二个条件（偏离超过 0.5 倍标准差即发出上涨信号）包含了第一个条件（偏离超过 2 倍），因此高波动时下跌信号总被上涨信号覆盖，与注释"低波动才买"相反；且继承已废弃的 `QCAlgorithmFramework`。
   - `CustomDataNIFTYAlgorithm.py` 同样把 `nifty_sma` 注册在 rupee 上（与 C# 版一致）。
   - `IndexOptionPutOTMExpiryRegressionAlgorithm.py` 的类名写成 Call 版本的类名，注释也写成看涨期权。
5. 其余为第 4 层内容，只记录已读。

## 三、进度
- Algorithm.Python：.py 剩余未读 50 个；下一批从 `py_unread_sorted.txt` 第 421 行开始。
