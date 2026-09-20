# LEAN 黄金独立研究回测 v1.0

本项目由用户于2026-09-20选择“LEAN 黄金策略回测”后建立。不是交易头脑 v1.2、GSM 三 SOP 或用户 Scalping SOP 的移植，不修改 MT5、原 EA、实盘或 Champion。

## 当前任务

实际编译独立 C# 候选，通过官方 LEAN 原生引擎运行 XAUUSD 小时级历史回测。默认利用用户已安装的官方固定版本：`985ef30ad3ac774218c5ac516b4cb0aa2655730f`。完成情况以 `completion_receipt.json`、原生结果及运行日志为准；本 README 不预先声称回测成功或策略盈利。

源码、研究参数和验证放在独立分支。默认参数是本次独立研究的起点，不继承其他项目的已确认风险或实盘设置。

## 四个事前登记实验

初始资金 **1000 USD**；每次入场按当时净值 **0.5%** 预算；模型杠杆 **1:20**；最多一笔持仓。根据入场至初始止损距离、模型费用、报价单位、数量步长和保证金向下计算数量，不强行凑最小手数。

H1 已收盘K线：EMA20 高于/低于 EMA50，EMA20 斜率同向，当根K线触及 EMA20 后收回趋势一侧且实体同向，建立多/空候选。初始保护止损为实际成交价外 **2×Wilder ATR14**，按最小价格变动向外取整。使用 LEAN 已有 EMA/ATR 和 CFD 接口，不加载 MQL5/EX5 指标。

A：H1 收盘有利移动达到初始价格风险的2倍后，市价退出。B：仅把2倍改为3倍。止盈不是挂在券商的限价单，也不是保证精确2R/3R成交。保护性止损使用原生 StopMarket 模型；不开保本、追踪、分批退出、马丁或加仓。

入场时间为纽约时间08:00（含）至15:00（不含），首次有数据的16:00或以后收盘退出。规则按算法的时区执行。缺报价可能延后退出，报告记录跨日持仓，不能假定永远无隔夜。

基础成本：原始 Bid/Ask 点差已包含在成交价；每数量单位每边佣金0.035 USD、每边固定价格滑点0.05 USD。这是研究模型，不是核实后的 FxPro/OANDA收费表。A与B各另跑一次佣金及滑点双倍压力，共4次完整回测。压力测试重新走决策和资金路径，不是事后简单扣费。

## 数据及证据范围

直接读取固定 LEAN 源码的 `Data/cfd/oanda/hour/xauusd.zip`；数据Git blob为 `2c0675003e21c8f1310914701053cc22157cc52d`。不用当前价格、模拟数据或股票SPY替代黄金数据。先核对数据哈希和时间顺序，再按覆盖范围选最后24个日历月，丢弃最后可能不完整的一日。日期在 `data_audit.json` 中，不假设是2024—2026年。

这是一份历史 H1 样本，不是 FxPro 真实 Tick、当前市场数据或交易所统一成交记录。按H1报价及成交事件采样的净值回撤，不等于真实Tick盘中最大回撤。原生即时成交模型没有验证券商延迟、流动性、部分成交或服务器止损。若出现跨日持仓，未计隔夜费是证据缺口，不能把未计费用当成免费。

本轮不称样本外；无黄金/美元关联、历史新闻/日历、动态风险状态和提款连续账户验证。这些没有被当成已实现。单批比较不能晋级实盘或证明资金安全。净额PF按完整往返交易扣佣金后的盈亏计算；与原生毛额PF口径分别保留。点差和已计入成交价的滑点不得再次从净利扣除。没有正式评分锚点，总分N/A。

## 在你的 Windows 电脑运行同版本

1. 解压整个包，双击 `START_GOLD_BACKTEST.cmd`。
2. 默认读取 `C:\Users\你的用户名\QuantConnect-LEAN-Local\Lean` 的已编译引擎；不会重装，不需要LE​​AN CLI、Docker、Python、付费账户或券商密钥。
3. 新结果保存在安装目录旁的 `gold-research-runs\日期_编号\`，不覆盖之前运行。只有 `ALL_FOUR_GOLD_BACKTESTS_COMPLETED` 才表示四次已实际完成并通过基本交易账本核对，**不是策略达标**。
4. 自定义安装目录可运行：

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Run-GoldBacktest.ps1 -LeanRoot "D:\QuantConnect-LEAN-Local\Lean"
```

上面只对本次PowerShell进程设置执行策略，不修改系统级设置。脚本遇到版本不同、源码改动、数据不匹配、编译失败或结果缺失时停止，保留日志。

## 证据目录

包含源码和DLL哈希、实际编译日志、事前登记、行情审计、每轮独立配置、引擎日志、LEAN原生JSON、逐笔往返CSV、H1净值CSV、指标JSON及中文比较表。源码和冻结最佳、最新候选分开，不因为参数改变就删除较早结果。

## 官方接口来源

- QuantConnect CFD数据：https://www.quantconnect.com/docs/v2/writing-algorithms/datasets/quantconnect/cfd-data
- CFD订阅/数量/杠杆：https://www.quantconnect.com/docs/v2/writing-algorithms/securities/asset-classes/cfd/requesting-data
- LEAN固定源码：https://github.com/QuantConnect/Lean/tree/985ef30ad3ac774218c5ac516b4cb0aa2655730f
- 引擎配置与启动器：上述固定源码的 `Launcher/config.json`、`Launcher/Program.cs`。

本项目源文件按Apache-2.0提供；LEAN引擎、官方样本和依赖保留各自原许可。本运行包不重新分发整个引擎、付费数据或任何字体文件。
