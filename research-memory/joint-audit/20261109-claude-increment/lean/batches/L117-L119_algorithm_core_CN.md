# L117–L119 Algorithm 目录：框架模型基类、选股基类与 QCAlgorithm 主体（Claude，2026-11-08）

**方式**：用 `tools/dump_src.sh` 只读。QCAlgorithm.cs 共 3,976 行，可执行代码全部读完，`///` XML 文档注释和 `[DocumentationAttribute]` 行没有逐行阅读；方法标记为 `CAT_N_CODE_EXCL_LICENSE_BLANK_USINGS_XMLDOC`。没有编译，也没有运行。

## 一、覆盖范围（FULL_READ 48 个）
| 批次 | 内容 | 文件数 |
|---|---|---|
| L117 | Alphas、Execution、Portfolio 和 Risk 的基类、Null 实现、Composite 实现、Python 包装类；INotifiedSecurityChanges；AssemblyInfo | 31 |
| L118 | Selection 的基类、Manual、Custom、Composite、OptionChained、OptionContractUniverse；UniverseDefinitions；DollarVolume；csproj | 16 |
| L119 | QCAlgorithm.cs | 1 |

## 二、与 V1.2 有关的发现
1. **默认值**（QCAlgorithm 构造函数，第 178–259 行）：
   - 算法时区为 America/New_York。
   - 默认开始日期为 1998-01-01；结束日期取今天，SetEndDate 会被限制在昨天。
   - 默认券商模型为 DefaultBrokerageModel。
   - 默认执行模型为 ImmediateExecutionModel，Alpha、组合构建和风险模型均为 Null 实现。
   - TradeBuilder 为 FillToFill + FIFO。
   - UniverseSettings 为分钟线、NullLeverage、前向填充开启、扩展时段关闭、最短在册 1 天。
   - 对 V1.2：用户 Scalping 的"服务器日 6 盈或 6 亏"按 FxPro 服务器日（EET/EEST）计算，而 LEAN 的 `Time`、`OnEndOfDay` 和日线边界默认按纽约时区。研究端必须显式调用 SetTimeZone，或自行把时间换算到服务器日，否则日界会错开。TradeBuilder 的 FIFO 配对与 MT5 的持仓/净额计算方式也须分别核对。列入 R40。
2. **SetBrokerageModel 的调用顺序会影响结果**（第 1396–1444 行）：
   - 如果先添加证券、再调用 SetBrokerageModel，会用券商的 SecurityInitializer 重新初始化已有证券，替换费用、成交、保证金等模型，但保留 AddSecurity 时指定的杠杆。
   - 用户调用过 SetSecurityInitializer 之后，SetBrokerageModel 就不再替换初始化器。
   - 对 V1.2：研究端要用 1:1000 杠杆，必须登记初始化顺序，并在每次回测开始时记录 `security.Leverage` 与保证金模型的实际值，不能只看代码里设置了什么。列入 R40。
3. **AddCfd 和 AddForex 固定关闭扩展时段**（第 2632–2650 行）：`AddSecurity<Cfd>(…, extendedMarketHours: false)` 写死为 false。CFD 的可交易时段完全由交易时段数据库的常规时段决定。这与 R39(b) 相互印证：常规时段以外下的市价单会被改成 MOO。
4. **RemoveSecurity 会撤单并平仓**（第 2718–2790 行）：非预热期间先撤掉全部挂单，有持仓就调用 Liquidate，然后把证券标为不可交易。
5. **回测日志会合并连续重复的消息**（第 2931–3035 行）：非实盘模式下，`Debug` 和 `Error` 与上一条内容完全相同时会被丢弃，`Log` 不受影响。对 V1.2：如果用连续的 Error 计数来统计拒单次数，数字会偏少，证据统计应以订单事件为准。列入 R40。
6. **框架模型的行为**：
   - ImmediateExecutionModel 在订单保证金低于 `Settings.MinimumOrderMarginPortfolioPercentage` 时不下单，只发一次警告。在 500 USD 的小账户上，小手数的目标可能因此被静默跳过。列入 R40。默认值为 0.001，即组合价值的 0.1%（见 AlgorithmSettings.cs 第 194 行）。
   - PortfolioConstructionModel：insight 的 Magnitude 超出 Min/MaxAbsolutePortfolioTargetPercentage 时被跳过并调用 Error；过期的 insight 会生成 0 目标。
   - CompositeRiskManagementModel 依次调用各个风险模型，新目标覆盖旧目标。
7. **代码问题（不影响 V1.2 路径）**：
   - `CompositeRiskManagementModel.py`：`risk_management_models` 是 tuple，`add_risk_management` 调用 `.add` 会抛出 AttributeError。
   - `ManualUniverseSelectionModel.py`：生成的 universe symbol 没有加入哈希，同一市场和类型的两个 Python 实例会冲突；C# 版加入了哈希。
   - `UniverseDefinitions.Index(Symbol, UniverseSettings, Func)` 没有把 null 回退到 `_algorithm.UniverseSettings`（ETF 版有回退），通过 `Index(symbol, func)` 调用时会传入 null。
   - `UniverseDefinitions.Top` 创建的 `symbol` 变量没有被使用。
   - `NullAlphaModel.py` 的注释抄自 MACD 模型。

## 三、进度
- Algorithm 目录剩余 8 个：QCAlgorithm.History（96 KB）、Indicators（287 KB）、Plotting（25 KB）、Python（123 KB）、Universe（42 KB）、Framework.Python、CandlestickPatterns（64 KB）、ConstituentUniverseDefinitions（43 KB）。
