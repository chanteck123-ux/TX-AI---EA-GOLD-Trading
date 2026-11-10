# L149 起 LEAN Tests 目录阅读笔记（Claude，2026-11-09 开始，持续追加）

## 方法与范围
- 清单为 scratchpad 中的 `tests_code.txt`，共 846 个 .cs/.py 文件，约 21.5 万行。
- 用 `dump_batch.sh` 生成 T 系列批次，逐个文件阅读，状态标为 FULL_READ。
- 测试只读，不运行；测试中的断言作为「上游自证的行为」证据，并非本轮实测。

## T1（L149）Tests/Algorithm 第 1–20 个文件
覆盖 AddData、AddSecurity、AddUniverse、Benchmark、Chains、Download、GetParameter、History（5,324 行）、Indicators、Initialize、LiveTrading、Naming、OrderFactory、Plotting、RegisterIndicator、ResolveConsolidator、SetBrokerage、SetHoldings、Settings、RemoveConsolidator。

### 与 V1.2 相关的测试证据

1. **CFD 订阅类型（支持 R41）**
   - `AddSecurity(Cfd)` 只产生 1 个 QuoteBar 订阅（AlgorithmAddDataTests 第 123–126 行）。
   - `ResolveConsolidator` 对 CFD 输出 QuoteBar（AlgorithmResolveConsolidatorTests 第 31 行）。

2. **杠杆与模型的优先次序（支持并细化 R40(b)）**，见 AlgorithmInitializeTests 全文矩阵：
   - `AddForex/AddCfd(..., leverage)` 显式传入的杠杆**永远优先**。
   - `SetSecurityInitializer` **只作用于之后添加的证券**。
   - 用户自定义初始化器设定的模型会覆盖券商模型；用户 initializer 在券商模型之后执行（AlgorithmAddSecurityTests 第 748–751 行）。
   - 先 AddForex、后设 initializer 再 SetBrokerageModel 时，原证券保持默认的 ConstantFeeModel 和 50 倍杠杆，不会切换成券商的费用模型。
   - Forex 默认杠杆为 50 倍。
   - **V1.2 的 1:1000 杠杆须在 Add 时显式传入，或确保 initializer 在 Add 之前设置，并在运行时打印 Leverage 留证。**

3. **History 默认填充（R47 补充）**
   - 历史请求默认 `fillForward=true`、`IncludeExtendedMarketHours=false`、`DataNormalizationMode=Adjusted`，且 FillForwardResolution 等于请求分辨率（AlgorithmHistoryTests 第 590–627、683–757 行）。
   - 按根数请求时，**数据缺失期间用填充 bar 补足根数**：SPY 数据只到 10-11，fillForward=true 时返回 780 根，false 时返回 390 根（第 1963–2147 行）。
   - 填充 bar 的 `IsFillForward=true`，时间只落在开市时段（第 4853–4893 行）。
   - **指标预热和 History(n) 拿到的 n 根中可能含复制出来的 bar**，研究端须登记或过滤。

4. **IndicatorHistory 的根数**：按根数请求时会额外加上预热期（例如 SMA(10) 请求 N 根，Samples 为 10+N−1）。

5. **选择器静默回退**：`Identity(symbol, Field.BidClose)` 收到 Tick 时会回退为默认的 Value，不报错（AlgorithmRegisterIndicatorTests 第 300–310 行）。若研究端按 bid/ask 取价，须核对实际输入类型。

6. **括号单（支持 R35）**
   - `BracketOrder` 的 TP（Limit）和 SL（StopMarket/StopLimit）在入场成交前都处于 `IsWaitingForTrigger`。
   - 休市时只有正在生效的父单转为 MOO，处于等待状态的子市价单保持 Market（AlgorithmOrderFactoryTests 第 349–361 行）。
   - 任一子单预检失败时，整组都不提交（第 414–431 行）。

7. **GetParameter 静默回退**：参数缺失或无法转成数字时**静默返回默认值**（AlgorithmGetParameterTests）。参数名拼错不会报错，研究端须把参数清单写入日志并做核对。

8. **年化交易日**：TradingDaysPerYear 默认 252，Default、Oanda、FXCM 券商均为 252（AlgorithmSettingsTest 第 82–115 行，与 R31 相关）。

9. **Liquidate**：LiquidateEnabled=false 时 Liquidate() 不发单（与 R39、R40 相关）。

### 其他（第 4 层）
- 括号单与 OCO 组合的 contingency 编号规则。
- 历史请求的「大请求」和「重叠请求」警告阈值。
- Benchmark 时区不一致时只在日线情况下给出警告。

## T2（L150）Tests/Algorithm 第 21–45 个文件（交易、预热、Framework Alpha/Execution/Portfolio）

### 与 V1.2 相关
1. **CalculateOrderQuantity 留缓冲并扣费**：按 `FreePortfolioValuePercentage`（默认 0.25%，即只用 99.75%）计算，并扣除预估手续费。LEAN 的目标仓位数量会略小于"权益×比例÷价格"，与 MT5 固定表/风险比例仓位对照时须登记该差额。
2. **Liquidate**：会扣除未成交市价单的剩余量并撤销挂着的限价单（补充 R39：Liquidate 会撤掉 SL/TP）。
3. **MOO/MOC 的 TIF**：GoodTilDate 被静默改为 GTC。
4. **SetWarmUp(n) 不指定分辨率**时，取已订阅品种中最小的分辨率（与 R41 预热相关）。
5. **Cash 账户模型下做空**：CalculateOrderQuantity 返回 0（V1.2 须用保证金账户）。
6. **ImmediateExecutionModel**：下单量 = 目标 − 持仓 − 未成交量；部分成交按已成交数计入持仓、剩余量计入未成交；数量按 LotSize 向零取整（1.5 手 → 1 手）。
7. **SpreadExecutionModel / StandardDeviationExecutionModel / VWAP**：价差超出阈值、价格未偏离或成交量不足时不下单，且**不报错**；休市时也不下单。V1.2 若参考这些模型，须记录"未执行"的次数和原因。
8. **Insight 时间语义**：`IsExpired` 为开区间、`IsActive` 为闭区间（CloseTime 当刻仍活跃）；`Cancel/Expire` 会把 Period 改为"至当前时刻减 1 秒"；ComputeCloseTime 跨休市只计开市时间。
9. **组合构建模型**：Accumulative 按每条 Insight 叠加 3%，Flat 每次撤销一层；权重类模型在 Insight 过期后自动发出 0 目标（即平仓）；价格为 0 时不产生目标；BlackLitterman 在 Magnitude 超出 Min/MaxAbsolutePortfolioTargetPercentage 时整组不产生目标。均为第 4 层，V1.2 不使用 Framework 组合构建。

### 其他（第 4 层）
- Insight JSON 序列化同时兼容 kebab-case 旧格式与 camelCase 新格式；EstimatedValue 和 Score 序列化时截断到 4 位小数。
- Python 继承包装：自定义 ExecutionModel 不必实现 on_order_event。

## T3（L151）Tests/Algorithm/Framework 第 46–70 个文件（Portfolio 组合构建、优化器、SignalExport、Risk）

### 与 V1.2 相关
1. **FreePortfolioValuePercentage 缓冲已由测试固定**：各权重模型的预期数量均为 `floor(权益 × 权重 × (1 − FreePortfolioValuePercentage) ÷ 价格)`（补充 T2 第 1 条）。另外设了 `FreePortfolioValue` 时（如 250），按固定金额预留。
2. **PortfolioTarget.Percent**：价格为 0，或购买力模型报错时，返回 **null**（静默不出目标，不抛异常）；目标比例超出 Min/MaxAbsolutePortfolioTargetPercentage 时也返回 null。V1.2 研究端若使用 Percent，须对 null 计数并留日志，不能把"未出目标"当作"已平仓"。
3. **Framework 风险模型（补充 R38）**：
   - `MaximumDrawdownPercentPerSecurity`：以 UnrealizedProfitPercent ≤ −阈值触发，**等号不触发**（−100/1000 = −10% 不平，−150 才平）。
   - `MaximumDrawdownPercentPortfolio`：以权益相对初始/高点的跌幅触发（−10001 才触发，−10000 不触发），触发后重置。
   - `TrailingStopRiskManagementModel`：多头 100→95 不平、94.99 才平；空头 50→55 不平、55.01 才平，同样是"严格大于阈值"。
   - 三者都只产生**数量 0 的目标**（交给执行模型市价平仓），不是挂在券商处的止损单；只在算法收到数据时检查。V1.2 的 SL/TP 须用 RiskExecution 的实际挂单，不能拿这些模型当止损。
4. **Delisted 证券**：被标为 delisted 后，Alpha 发出的 Insight 被丢弃（QCAlgorithmFrameworkTests）。

### 其他（第 4 层）
- Confidence/Insight 权重模型：权重为 null 时不出目标，为 0 时出 0 目标；Flat 不计入分配；SectorWeighting 忽略没有行业代码的证券。
- MeanReversion 与 RiskParity 模型禁止 Short 偏向（构造时抛异常）。
- 优化器：MaximumSharpe 和 MinimumVariance 在无解时**回退为等权**而不报错；单资产返回权重 1；RiskParity 变量数限制为 1–1000。
- 再平衡函数返回 null 表示不再平衡；DateRules 和 TimeSpan 两种写法都支持。
- SignalExport（Collective2、CrunchDAO、Numerai）：只读测试，不涉及 V1.2；构造参数中的 apiKey 均为空字符串，无凭据。Collective2 把外汇换算为 mini-lot（10,000 单位），不足 1 时返回 0，且同类警告只记一次。

## T4（L152）第 71–95 个文件（Framework Selection、UniverseDefinitions、AlgorithmFactory、AlgorithmRunner、Api、AssemblyInitialize）

### 凭据处理
- 本批 Api 测试中的券商凭据（IB、FXCM、Oanda、Tradier、Binance、Coinbase、Kraken、Bybit、Bitfinex、Polygon 等）**全部通过 `Config.Get(...)` 读取**，源码中没有字面值；默认 settings 的 user/password/account 都是空字符串。
- `ApiTests` 中有一条 AWS 签名格式的请求头样例，是官方文档公开的示例占位符，不是真实密钥；本笔记不转录。
- `AccessTokenMetaDataResponseTests` 只有 "abc" 占位。
- `ApiTestBase.ReloadConfiguration` 把所有 `QC_` 前缀的环境变量写入 Config，所以凭据经环境变量注入。**V1.2 若使用 LEAN CLI 或 Api，应采用同一方式，不得把凭据写进仓库。**

### 与 V1.2 相关
1. **回归测试的判定口径**（AlgorithmRunner）：逐项比较统计**字符串**是否完全相等（只把 "-0" 视为 "0"）；若期望状态为 Completed 却出现运行时错误，则直接判失败。日志复制到 `./passed/`。V1.2 的 LEAN 研究端若用回归方式锁定结果，同样须按字符串比对，并记录 LEAN 版本。
2. **History 请求的防护**：RegressionHistoryProviderWrapper 对 canonical 符号的历史请求直接抛异常（期权和期货除外），只在回归测试中生效。
3. **Api 分页上限**：订单和洞察每页 ≤100，回测日志 ≤200，实盘日志 ≤250，超出时抛 ArgumentException；只给 start 时取默认窗口。
4. **ParameterSet 反序列化**：兼容对象、key/value 数组、name/value 数组三种格式，**缺 key 的条目被静默丢弃**，Id 固定为 −1。与 T1 的 GetParameter 静默回退叠加：参数注入链路上有两处静默行为，V1.2 须记录实际生效的参数集。
5. **OptimizationBacktest**：统计以数字下标 0–24 序列化，旧格式只有 21 项（不含 Sortino、Start/End Equity、Drawdown Recovery）。读取历史优化结果时须核对版本，否则指标缺失会被误判为 0（补充 R48）。
6. **Optimizer 示例的目标仍是 Sharpe**，约束为 Sharpe ≥ 1（与 R48 一致）。

### 测试代码缺陷（第 4 层，`Explicit` 测试，不在 CI 中运行）
- `LiveTradingTests.RunLiveAlgorithmsFromPython`：账户前缀为 "DU"（IB 模拟账户）时把 environment 设为 `'live'`，**与 C# 写法相反**（C# 中 DU 对应 paper）。属于测试代码中的模式判断反转，手动运行时可能用错环境标志。
- `LiveAlgorithmSettings_CanBeCreated_Successfully`：Tradier 分支断言 environment == "life"，而设置的值是 "live"，该断言必然失败；IB 分支把键名写成 "acount"。
- 本轮只阅读，没有运行。

### 其他（第 4 层）
- ETF/Index 宇宙各种重载、OpenInterest 期货宇宙按持仓量降序排列（同值时按到期日）、QC500 每月 1 日选出粗选 1000 只和精选 500 只、Manual 宇宙排除 canonical 符号。
- Loader 可以对同一 Python 算法加载两个独立实例；AssemblyInitialize 预先初始化 Python decimal 和 PandasData，以避免 GIL 死锁。

## T5（L153）第 96–120 个文件（Tests/Brokerages 第一部分）

范围：Authentication、BrokerageConcurrentMessageHandler、BrokerageTests 基类、OrderCrossing、各类订单参数、OrderProvider、LevelOne、Exante/Kraken 费用与杠杆。凭据：只有 "first"/"second"/"token"/"123456" 一类测试占位符，没有转录。

### 与 V1.2 RiskExecution 相关（待汇总 R49）
1. **穿越零仓位的订单会被拆成两笔**（OrderCrossingBrokerageTests）：持有多头 10、卖出 15 时，券商层先平 10，再开空 5。
   - 正常情况下，事件序列为 Submitted → PartiallyFilled → Filled，中间有 OrderIdChanged（第二部分换成新的券商单号）。
   - 第一部分失败：PlaceOrder 返回 false，事件为 Invalid。
   - **第一部分成交、第二部分失败：事件序列为 Submitted → PartiallyFilled → Canceled**。结果是**只平了仓、没有反手**，订单显示"部分成交后取消"。
   - **V1.2 处理**：RiskExecution 不得依赖一笔订单完成"平仓+反手"，平仓与新开仓应分成两个独立意图，分别对账。另须确认 FxPro MT5 账户是对冲模式还是净额模式（对冲账户不存在"穿零"）。LEAN 研究端如果出现反手信号，成交统计会把它算成一笔订单两次成交，须与 MT5 的成交笔数口径对齐（与 R36 OrderEvent 数量口径相关）。
2. **下单与券商事件流的锁序**（BrokerageConcurrentMessageHandler）：
   - 下单在 `WithLockedStream` 内执行；锁定期间到达的券商消息被缓冲，解锁后**按到达顺序**、由最后释放锁的线程统一处理。
   - 缓冲满时，生产者等待；消费者或生产者抛出异常后，状态不被破坏。
   - 目的是防止"成交回报先于本地登记订单号到达"。**V1.2 的 MQL5 RiskExecution 同样须保证：先登记 ticket 和意图 ID，再处理 OnTradeTransaction**，或者把未知 ticket 的事件暂存后重放，而不是丢弃（与冻结契约中的对账条款对照）。
3. **或有订单（括号单）在券商侧的语义**（BrokerageTests.ContingentOrders*）：
   - 入场成交前，TP/SL 处于"等待触发"状态；撤销父单会连带撤销所有后代订单。
   - 重连后用 GetOpenOrders 重建时，须恢复 contingency 链接及等待触发状态，且所有成员共享同一个链接集合。
   - 平仓前须先撤销 TP/SL，因为部分券商会为挂着的离场单保留仓位；撤销一个可能连带撤销其兄弟单。
   - 补充 R35：V1.2 重启恢复时，必须从券商侧重建 SL/TP 与持仓的对应关系，不能只依赖本地状态文件。
4. **撤单的幂等性**（BrokerageTests.CancelOrders）：对已撤订单再次撤单，同步券商返回 false，且**不会再发 Canceled 事件**；异步券商返回 true。RiskExecution 的撤单重试不能把"返回 false"一律当作失败，须查询订单的实际状态。
5. **部分成交的均价**（OrderProviderTests）：4 手 @100 加 6 手 @101，OrderTicket 的平均成交价为 100.6（按数量加权），剩余数量随之更新。
6. **错误降级**（DowngradeErrorCodeToWarningBrokerageMessageHandler）：指定的错误码会被改写成 Warning 再转发。V1.2 若采用类似的过滤，须登记被降级的错误码清单，避免掩盖保证金或拒单类错误。
7. **IB 的模拟止损单**：BrokerageTests 指出 IB 模拟止损时**不会发出 Submitted 事件**。V1.2 不能以"收到 Submitted"作为止损单已挂出的唯一证据，须主动查询订单。

### 测试代码缺陷（第 4 层）
- `BaseOrderTestParameters.RoundPrice` 把 `GetDecimalPlaces()` 返回的**小数位数**（例如 0.01 对应 2）当作舍入单位，执行 `Math.Round(price / 2) * 2`，结果是**舍入到偶数整数**，而不是 0.01。只影响需要实盘券商的改价测试。
- `LevelOneMarketDataTests.UpdateQuoteShouldIgnoreZeroSizeUpdatesCorrectly` 的 else 分支把 bid 与 ask 的大小交叉比较，因为两者都是 0 所以能通过，断言实际上无效。
- `BrokerageTests.PartialFills` 为 Explicit，实际没有部分成交的自动化测试。

### 其他（第 4 层）
- LeanOAuthTokenHandler：令牌被拒时作废并重新获取，第二次请求使用新令牌；获取失败时抛异常并触发 AuthenticationFailed。
- 多 WebSocket 订阅管理：重连时取消进行中的重订阅，只保留最新一轮。
- GetOrderPosition：Buy 且持仓 <0 为 BuyToClose，Sell 且持仓 >0 为 SellToClose，持仓为 0 时为开仓。
- Kraken 杠杆为 1–5 倍；Exante 费用按 MarketUsaRate × 数量计算。

## T6（L154）第 121–145 个文件（Brokerages 第二部分、Common/Brokerages 前半）

### 与 V1.2 相关
1. **或有订单（括号单）的券商支持矩阵**（ContingentOrdersBrokerageModelTests，补充 R35 和 R49）：
   - 支持的模型**只有** Default、AlphaStreams、InteractiveBrokers、CharlesSchwab、TradeStation、Alpaca、Binance（现货、U 本位期货、币本位期货）。
   - **其余所有 DefaultBrokerageModel 子类（包括 Oanda、FXCM）都会拒绝括号单的每一个成员**，返回消息 "does not support contingent orders"。
   - 各家限制不同：IB 支持全部（但 FIX 模型不支持）；Schwab 不支持 OUO，且或有订单不能改价；TradeStation 不能链式触发，OUO 必须是同一品种并含止损；Alpaca 只支持股票、最多 3 单、只能是 TP 限价加止损的标准括号，且不能改数量；Binance 只支持现货，工作单必须是单个限价单，现货不支持 StopMarket。
   - **V1.2 影响**：LEAN 研究端如果为了使用 CFD 或外汇的默认保证金与费用而设置 `SetBrokerageModel(Oanda/FXCM)`，**括号单会被整组拒绝**，回测里等于没有 SL/TP。须选用 Default 模型、自定义券商模型，或者改用手动 OCO 管理，并在报告中登记实际的订单类型。MT5 端不受影响（服务器端 SL/TP）。
2. **Default 券商模型的成交模型**：Forex、Cfd、Crypto、Option、Index 都用 ImmediateFillModel，Equity 用 EquityFillModel，Future 用 FutureFillModel（与 L001 一致）。
3. **拆股时调整挂单**（DefaultBrokerageModel.ApplySplit）：1 拆 2 时数量 ×2，限价、止损、触发价 ×0.5；百分比追踪止损的 TrailingAmount 不调整。XAUUSD 和 CFD 不涉及。
4. **PaperBrokerage**：分红在预热期间不入账，且只入账一次；已退市证券的待结算资金照常结算后移除。CashSync 不会加入数量为 0 的币种（账户币种除外），无法换算的币种汇率记为 0 而不报错。
5. **MOO 的允许时段**因券商而异（TradeStation、Alpaca、IB 各不相同，包括周末）。V1.2 不使用 MOO/MOC。
6. **Python 自定义券商模型**：CanSubmitOrder/CanUpdateOrder 必须返回 `(bool, message)` 元组，否则抛 ArgumentException。

### 测试代码风险（第 4 层）
- `SymbolPropertiesDatabaseSymbolMapperTests.SymbolMapperRefreshesMappingsPeriodically` **直接向实际 Data 目录中的 symbol-properties-database.csv 追加一行，结束时再整体重写该文件**（用 `string.Join(NewLine)` 重写，可能改变末尾换行和换行符）。测试中途中断会污染共享数据文件。**V1.2 若在同一份 LEAN Data 目录上跑该测试，须先备份 SPDB，并在之后核对哈希。**本轮只阅读，未运行。
- 券商测试的 `RoundPrice` 问题见 T5 节。

### 其他（第 4 层）
- 各加密券商：Binance 现货保证金杠杆 3，Bybit 10，Bitfinex 3.3，Coinbase 只支持现金账户和加密币，不能改单，taker 费 0.3%、maker 费 0。
- BloombergFix、ClearStreet：不支持 Forex、Cfd、Crypto；ClearStreet 期权不能用止损单。
- BrokerageName 的枚举值固定（Default=0，IB=1，Oanda=3，FXCM=4，Coinbase=32）。

## T7（L155）第 146–170 个文件（Common/Brokerages 后半、Commands、Currencies、Auxiliary 因子文件）

### 与 V1.2 相关
1. **FXCM 券商模型对 CFD 和外汇的下单校验**（FxcmBrokerageModelTests）：
   - 不支持 StopLimit、MOO、MOC。
   - 外汇数量必须是 LotSize（1000）的整数倍，CFD 也有最小手数（0.5 被拒）。
   - **限价和止损价必须落在当前价的一定区间内**，例如 EURUSD 现价 1 时，买入限价须在 0.5–1、卖出限价须在 1–1.5，买入止损须在 1–1.5，卖出止损须在 0.5–1；超出就拒单。
   - 加上 T6 的结论（FXCM 不支持括号单），**V1.2 若在 LEAN 中用 FXCM 模型模拟 XAUUSD CFD，止损价校验与括号单限制都会改变回测里的订单行为**，与 MT5（FxPro 的 StopLevel/FreezeLevel 规则）不一致，须分开登记，不能互相代替。
2. **IB 模型**：CFD 现金账户杠杆 1、保证金账户 10；外汇有最小和最大下单量（例如 EURUSD 为 20,000 至 6,000,000），超出时返回 Warning "OrderSizeLimit"；外汇和 CFD 不支持 MOC；CFD 支持 MOO 和 MOC。
3. **OrderCommand（实盘命令下单）**：只有在预热结束、有价格、证券已添加且数量 >0 时才成功；默认 TIF 为 GTC。
4. **因子文件**：读到 `inf` 或指数记数时，从首个有效行之后起算 FactorFileMinimumDate；未知 DataMappingMode 的行被静默丢弃。只与股票、期货有关，XAUUSD 不涉及。

### 安全与测试副作用（第 4 层）
- **FileCommandHandler 用 `TypeNameHandling.All` 反序列化工作目录下的 `command*.json`**（FileCommandHandlerTests、CallbackCommandTests）。Json.NET 在 `TypeNameHandling.All` 下反序列化不可信输入，是已知的任意类型实例化风险。**V1.2 若在实盘机或研究机上使用 LEAN 本地命令文件机制，须保证工作目录只有受信进程可写**；本轮只阅读，未验证可利用性。待汇总 R48 安全部分（d）补充。
- `LocalZipFactorFileProviderTests` 把 factor_files 打包后写入**实际 Data 目录**，在 TearDown 时删除；与 T6 的 SPDB 改写一样，属于"测试写共享数据目录"，运行前须备份。
- CallbackCommand 回归测试会在工作目录写 `command-{i}.json`。

### 其他（第 4 层）
- Tradier：做空不能用 GTC，股价低于 5 美元不能卖空，数量须在 1–10,000,000 之间，盘前盘后只允许股票限价单。
- Webull、Public、QuantBridge、Tastytrade、FTX、Exante、Kraken 都不支持 Forex 和 Cfd（或对应的加密限制）。
- Currencies.Parse 支持千分位和科学计数，拒绝欧洲格式 "10.000,1"。

## T8（L156）第 171–195 个文件（Common/Data：合成器、MapFile、DataMonitor、DynamicData、Fundamental）

### 与 V1.2 相关（M5 合成与闭柱确认）
1. **合成器事件里的 `Consolidated` 是上一根，不是刚生成的这一根**（ConsolidatorBaseTests.HandlerSeesPreviousConsolidatedBarWhileReceivingTheNewOne）：
   - 在 DataConsolidated 回调**内部**读 `consolidator.Consolidated`，拿到的是**前一根**（第一根时为 null）；
   - 同一回调里 `consolidator[0]` 和 `Current` 已经是**新这一根**（WindowHoldsTheNewBarInsideTypedHandler）；
   - 回调返回后，`Consolidated` 才更新为新 bar。
   - **V1.2 影响**：S7 Scalping 的"反转闭柱确认"若在 LEAN 研究端用合成器回调实现，**必须用事件参数或 `Current`/`[0]`，不能在回调里读 `Consolidated`**，否则会差一根，信号整体延后或错位。属于 LEAN 与 MT5 跨引擎核对时容易出现的口径偏差，待汇总 R50。
2. **时间段模式的 bar 时间向下取整**：period=1 天时，首个 tick 在 00:00:45，产出的 bar `Time` 仍为当日 00:00（AggregatesPeriodInPeriodModeWithDailyDataAndRoundedTime）。M5 合成同理，bar 起点对齐到 5 分钟边界（按合成器所在时区，即交易所时区）。**MT5 的 M5 起点按服务器时间对齐，两端时区不同时，日内边界和周末首尾 bar 可能不一致**（与 R40 时区一节相关）。
3. **计数模式的 Period**：2 个小时 tick 合成一根时，Period 为最后一个与第一个的时间差（1 小时），不是 2 小时；EndTime 为最后一个数据点的 EndTime。
4. **乱序数据**：比窗口最新更早的数据会被忽略，不会清空窗口（OutOfOrderDataDoesNotClearWindow，是回归修复）。旧版本中乱序数据会重置整个滚动窗口，**LEAN 版本须锁定**。
5. **QuoteBar 合成**：Bid 和 Ask 的 OHLC 分别合成（Open 取首个、High 取最大、Low 取最小、Close 取最后）；TickQuoteBarConsolidator 用 tick 的 Bid/Ask 价。与 R32（QuoteBar 取中间价）一并核对：合成后的 `Close` 是中间价，止损触发若按 Bid/Ask，须分别取。
6. **BaseDataConsolidator** 不累计成交量（Volume 恒为 0）；TradeBarConsolidator 才累计。CFD 的 QuoteBar 没有成交量，依赖成交量的指标在 CFD 上无效（与 R46 IntradayVwap 一致）。
7. **ConsolidatorWrapper 的扫描时间**：最小步长 1 秒；按工作中 bar 的 EndTime 推进；对夏令时切换（±1、±24 小时）有专门测试。
8. **DataMonitor**：退出时写出 `failed-data-requests-*.txt` 并统计成功和失败请求数（失败的 universe 请求单独计数）；成功请求默认只计数，不列清单，须开启 `data-monitor-store-succeeded-requests` 才会写文件。**V1.2 研究报告的数据覆盖证据可直接引用该文件**，但须确认它在每次运行的结果目录中生成。
9. **DividendYieldProvider**：外汇等没有因子文件的品种恒返回 0。

### 其他（第 4 层）
- Renko、经典 Range、DollarVolumeRenko 的砖块规则；DynamicData 对属性名大小写不敏感，并支持 snake_case；MapFile 中未知的映射模式行被丢弃；Fundamental 缺值时 double 为 NaN、decimal 为 0、DateTime 为 MinValue。
- `LocalZipMapFileProviderTests` 同样会写入实际 Data 目录（与 T7 相同的副作用）。

## T9（L157，2026-11-10）：tests_code.txt 第 196–220 个，共 25 个文件，FULL_READ
范围：Common/Data 市场数据类型、合成器（QuoteBar、MarketHourAware、Identity、Period）、Slice、SubscriptionManager、InterestRateProvider、SubscriptionDataSource。

### 与 V1.2 相关
1. **QuoteBarConsolidator**：下一根 bar 的 Open 取上一根的 Close，跳空因此消失，与 MT5 的 M5 K 线开盘价口径不同 → R50(b)。
2. **MarketHourAwareConsolidator**：日内 bar 以开市时间为锚点，收市处最后一根被截短，休市时段的数据被忽略。
3. QuoteBar 行格式错误时静默解析为 0；`Bar.Update` 忽略 0，但接受负价格。
4. 时间段模式的合成器要等到下一次 Update 或 Scan 才发出已过期的 bar（闭柱确认有延迟）。
5. 数据周期长于合成器周期时，QuoteBarConsolidator 抛出异常。
6. CFD 和外汇只订阅 QuoteBar；Tick 的报价取中间价，只有一边时取那一边。
7. Slice 的股票索引器忽略报价；MergeSlice 取第一个非空值。
8. IdentityDataConsolidator 忽略时间戳相同的非 Tick 数据。
9. InterestRateProvider 向前填充。
10. SubscriptionManager.IsSubscriptionValidForConsolidator：CFD/外汇/加密的 Quote 订阅可接 Tick→QuoteBar、Renko；Trade 订阅不能接 QuoteBar 合成器。

### 其他（第 4 层）
- Python 包装的泛型合成器（`IdentityDataConsolidator[TradeBar]`）可正常添加和移除；ManuallyRemovedConsolidatorsAlgorithm 的回归统计为空交易。
- SubscriptionDataSource 测试中的请求头占位值未转录。

## T10（L158，2026-11-10）：tests_code.txt 第 221–245 个，共 25 个文件，FULL_READ
范围：Tick/TickQuoteBar/TradeBar/VolumeRenko 合成器、UniverseSelection、DataMonitorReport、Python 异常解释器。

### 与 V1.2 相关
1. **TickConsolidator 只处理 Trade 类型的 Tick**，Quote 和 OpenInterest 被忽略。CFD/外汇只有报价 Tick，必须用 TickQuoteBarConsolidator。
2. **TickQuoteBarConsolidator**：Bid 和 Ask 各自独立维护；只有一边报价的 Tick（另一边为 0）不更新另一边。下一根 bar 每一边的 Open 都取该边上一根的 Close（与 R50(b) 相同口径）。Trade 类 Tick 被忽略。
3. **时间段模式的边界是左闭右开**：bar 起点按周期向下取整，比如 10:00:03 的 Tick 归入 10:00 那根；要等下一个周期的数据到来或调用 Scan 才发出 bar。
4. **跳空与混合模式**：数据缺口时，下一根 bar 的 Time 是取整后的新周期起点（例如 10:08 的数据开启 10:08 那根，空缺的周期不会补出空 bar）。混合模式（计数加时间）出现缺口时，时间戳取新数据的时间。
5. 合成器周期小于数据周期时抛 ArgumentException，周期为 0 时也抛异常；周期与数据周期相同时，要调用 Scan 才发出。
6. 各合成器遇到不同品种的数据都会抛 InvalidOperationException。

### 其他（第 4 层）
- VolumeRenko：按成交量凑满砖块，不接受 QuoteBar。
- Coarse 数据只在实盘模式下回退到 `.backup` 文件，并按日缓存；周末向前填充至多一个交易日。Universe 的最短停留时间按四舍五入判断。ConstituentsUniverse 回测时次日才发出。
- UserDefinedUniverseTests 从后台线程调用 AddOptionContract 和 AddEquity，测试线程安全。
- DataMonitorReport 的失败百分比四舍五入为整数。
- 各 PythonExceptionInterpreter 只改写错误提示，不改变异常行为。

## T11（L159，2026-11-10）：tests_code.txt 第 246–270 个，共 25 个文件，FULL_READ
范围：Python 异常解释器（其余部分）、Exchange、Expiry、ExtendedDictionary、Holding、Isolator、Notifications、ContingentOrderProcessor/ContingentOrder、dYdX/ClearStreet/Coinbase 订单属性、AlpacaFeeModel。

### 与 V1.2 相关（RiskExecution）
1. **ContingentOrderProcessor（括号单语义）**：
   - 父单**部分成交时不触发子单**，要等全部成交。这段时间内已成交的部分没有 SL/TP 保护。
   - **OneCancelsOther：TP 只部分成交时，SL 立刻被整张撤销**，持仓的剩余部分因此没有止损（测试 `OneCancelsOtherFillCancelsSiblings(partialFill: true)`）。→ R49(h)
   - OneUpdatesOther：按比例缩减兄弟单数量，会计入兄弟单已成交的部分，并按 lot size 取整；完全成交后撤销兄弟单。
   - 父单 Canceled 或 Invalid 时撤销所有挂着的子单；一个兄弟单被撤销或无效时整组撤销，但父单不受影响。
   - **触发后的子单要等到触发时刻之后的新数据到来才开始工作**（同一时间步不撮合；市价子单除外）。这与 R35 的"子单延迟成交"一致。
   - 组合单（combo）作为父单时，要所有腿都成交才触发子单。
2. 括号单序列化时，等待触发状态的子单不写 triggered 字段；反序列化遇到无效 link 时跳过而不报错。V1.2 若参考此结构做状态持久化，须显式保存触发状态。
3. **Holding 的价格取整**：股票和期货的 MarketPrice/AveragePrice 按 2 位小数显示，外汇和加密保留原精度。结果包中的 Holding 不能当作精确的对账来源。
4. Isolator：超过 1 分钟时请求追加时间并发出用户警告；超过时间限制抛 TimeoutException。

### 其他（第 4 层）
- NotificationManager 只在实盘模式下排队消息。FTP 测试中的用户名和密码都是字面占位值，未转录也无须转录；Telegram 的 token 同为占位。
- ExtendedDictionary 对 null 键安全；Symbol 键可以用字符串索引（依赖 SymbolCache）。
- Exchange 代码映射；Expiry 的 EndOfWeek 是下周一。
- Alpaca 加密费用：买入以基础货币计，卖出以报价货币计。
