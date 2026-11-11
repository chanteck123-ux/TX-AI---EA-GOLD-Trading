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

## T12（L160，2026-11-10）：tests_code.txt 第 271–295 个，共 25 个文件，FULL_READ
范围：Orders/Fees（AlphaStreams、Binance 系列、Bitfinex、Bybit 系列、Coinbase、FTX、IB、Public、Samco、Webull、OrderFees、向后兼容）以及 Orders/Fills（BackwardsCompatibility、EquityFillModel 及其 Limit/StopLimit/StopMarket 分部、FutureFillModel、FutureOptionFillModel、ImmediateFillModel）。

### 与 V1.2 相关（成交口径，CFD/外汇默认 ImmediateFillModel）
1. **陈旧数据规则（新）**：市价单只能取到比当前时间落后超过一个分辨率周期的数据时，**不成交，等新数据到来**，之后按新 bar 的收盘价成交（Equity 和 Future 模型有测试；BackwardsCompatibility 测试注释也说明 Immediate 系同样处理）。落后不足一个周期时，按旧价成交并附带 "Warning: fill at stale price"。这关系到周末开盘和数据缺口时的入场价，以及 MT5 跨引擎对齐。→ R51(a)
2. **ImmediateFillModel 的价格规则**：
   - 市价单按 security.Price 成交，外汇用 Tick 时买入取 Ask、卖出取 Bid。小时或日线 bar 在开始前已挂着的市价单，按 bar 的 Open 成交；bar 进行中下的单按 Close 成交。
   - 止损市价单：买入按 max(Price, Stop) 成交，卖出按 min(Price, Stop)（不利一侧）。
   - 限价单：买入按 min(Limit, High) 成交，卖出按 max(Limit, Low)。
   - 止损限价单：**触发那一根 bar 的价格区间不用于成交**，要从下一根 bar 起按限价单处理。
   - 追踪止损：按价格逐步更新止损价，触发后按不利一侧成交。
   - **Fill-forward 复制出来的 bar 和下单时刻之前的数据都不会触发成交**（Limit、Stop、StopLimit、Trailing 均如此）。
   → R51(b)
3. **EquityFillModel（仅股票）**：限价和止损单不接受 QuoteBar 或报价 Tick 来成交；有利跳空时限价单按 Open 成交，不利跳空时止损单按 Open 成交；MOO 和 MOC 依赖官方开盘、收盘成交标志，有 1 分钟超时。
4. **FutureFillModel**：不在扩展交易时段内时，止损单不成交。
5. **费用**：IB 的 CFD 费用为名义价值的 0.002%，按报价货币计，最低 1 USD（或 40 JPY、10 HKD）；AlphaStreams 的 CFD 费用为 0；IB 模型遇到加密资产抛异常。V1.2 用 FxPro 时须自定义费用模型，并在报告中登记（与 R37 相同）。

### 其他（第 4 层）
- 加密费用模型：maker/taker 费率与 PostOnly 的关系、各家计费币种（买入以基础货币计，卖出以报价货币计）、Coinbase 费率随日期变化、Public 和 Webull 的分级费用。
- FTX 测试注释中有交易所回报的 JSON 示例，只含公开字段，没有凭据。

## T13（L161，2026-11-10）：tests_code.txt 第 296–320 个，共 25 个文件，FULL_READ
范围：LatestPrice/PartialMarket 成交模型、Fix/QuantBridge/Group 订单属性、OrderEvent/Order 的 JSON 序列化、ReadOrdersResponse、OrderSizing、Order.GetValue、OrderTicket、Slippage（MarketImpact、Constant、VolumeShare、AlphaStreams）、TimeInForce、OrderTargetsByMarginImpact、Packets、Parameters、Parse、Protobuf、DateRules。

### 与 V1.2 相关
1. **PartialMarketFillModelTests 整组被标为 `[Ignore("TODO: fix me")]`**：LEAN 自带的部分成交测试处于停用状态。V1.2 RiskExecution 的部分成交逻辑不能以 LEAN 已有测试为依据，必须自行做故障注入。→ R49(i)
2. **滑点模型**：MarketImpactSlippageModel 对 CFD 和外汇**直接抛异常**；VolumeShare 和 AlphaStreams 模型对外汇/CFD 返回 0（成交量为 0）；ConstantSlippage 按 Price × 百分比计。所以 LEAN 研究端的 XAUUSD 滑点只能用常数或自定义模型，且须在报告中登记。→ R51(c)
3. **Day/GTD 有效期**：外汇订单在**纽约时间 17:00** 到期（17:00 之后下的单，次日 17:00 到期）；加密在 UTC 午夜到期；股票在收盘时到期。这与 FxPro 服务器日（V1.2 的 6 盈/6 亏换日口径）不同。
4. **OrderSizing.AdjustByLotSize**：0.98 取整为 0，0.9999999 取整为 1（有容差）。GetUnorderedQuantity 会扣除未完成订单中已成交和未成交的数量。
5. **Order.GetValue**：止损类订单按 max/min(Price, Stop) 估算价值；CFD 的价值为 数量 × 价格 × ContractMultiplier × 报价货币汇率。
6. 预热期间或在 Initialize 内下单会返回 Invalid（"not allowed in Initialize or during warm up"）。
7. OrderEvent 的时间按 double 序列化，有约 200 tick 的精度损失；OrderFee 为 0 时不序列化费用字段。V1.2 若用 LEAN 事件做对账，时间比较须设容差。

### 其他（第 4 层）
- OrderJsonConverter 兼容旧字段（Duration、DurationValue）、字符串状态和 null 时间，超出 decimal 范围的数值会被截到 Max/Min。ReadOrdersResponse 测试样本的 algorithmId 是测试用十六进制串，不是凭据。
- MOO 订单只允许在规定时段提交（16:00 之后至次日开盘前）。
- OrderTargetsByMarginImpact：先处理减仓目标，再按订单价值从大到小排；不足一手或没有数据的目标被忽略。
- BacktestNodePacket 的参数保留原始字符串；Notification 和 LiveNodePacket 测试中的邮箱、电话、网址都是占位值，未转录。
- DateRules：按品种取交易日，offset 越界时抛异常，可选是否计入扩展时段，可设置时区。

## T14（L162，2026-11-10）：tests_code.txt 第 321–345 个，共 25 个文件，FULL_READ
范围：Scheduling（ScheduledEvent、ScheduleManager、TimeRules）、Securities（结算模型、波动率、BrokerageModelSecurityInitializer、BuyingPower 比较器与模型、CashAmount/CashBook/Cash、CashBuyingPower、Cfd/Forex/Crypto、CryptoFuture 保证金、SecurityCurrencyConversion、DelayedSettlement、DynamicSecurityData、FakeOrderProcessor、FutureFilter、FutureMarginBuyingPower）。

### 与 V1.2 相关
1. **TimeRules 不带品种时的选取规则**：先在已订阅的品种中挑最早开盘、最晚收盘的一个，跳过 24/7 品种；一个都没有时回退到 SPY。测试显示 **XAUUSD（Oanda CFD）的日开盘为纽约 00:00（UTC 05:00），日收盘为次日 UTC 05:00**。也就是说，LEAN 中 XAUUSD 的"交易日"按纽约午夜切分，不是 FxPro 服务器日。V1.2 的 6 盈/6 亏换日和 DR01 日内风控在 LEAN 研究端必须自定义服务器日时区。→ R52(a)
2. **ScheduledEvent**：一次 Scan 会补触发所有已错过的事件；SkipEventsUntil 不跳过与指定时间相等的事件。周度事件的触发时刻随美国夏令时（DST）移动 1 小时（UTC 20:57 变为 19:57）。
3. **货币换算**：没有数据时 ConversionRate 为 0（两腿换算中任一腿缺数据也为 0）；XAU 现金会自动订阅 XAUUSD 的 Quote 数据来换算。回测开始阶段，若账户币种与 XAU 换算尚未有数据，持仓价值和盈亏换算可能为 0。→ R52(b)
4. **BuyingPowerModel.GetAmountToOrder**：按 lot size 取整，并保证结果保证金不超过目标；GetMaximumOrderQuantityForTargetBuyingPower 会计入费用和"价格缓冲"。最大可下数量不一定能通过 HasSufficientBuyingPower（目标大于 1 时）。
5. **DefaultBrokerageModel（Margin 账户）把股票杠杆设为 2；Cash 账户为 1**。BrokerageModelSecurityInitializer 用 GetLastKnownPrice 为新品种设初始价格；没有历史数据时价格为 0。
6. FuturesMargin：保证金依据维持保证金，不随价格变化；价格下跌后 TotalPortfolioValue 可以为负；收市临近或休市时日内保证金失效，订单会被拒。

### 其他（第 4 层）
- CashBuyingPower（加密 Cash 账户）：未成交挂单会占用可用资金，费用计入；GetMaximumOrderQuantity 不检查报价货币是否足够。
- CryptoFuture 保证金按 杠杆 25、BNFCR 共享抵押池计算；DelayedSettlement 为 T+3 08:00 结算；CashBook 不接受 NullCurrency；Cash.Symbol 会转成大写。
- FutureFilter 的到期筛选；保证金数据文件的完整性检查会读取实际 Data 目录（只读）。

## T15 / L163（2026-11-10）：tests_code.txt 第 346–370 个，25 个文件，7,067 行，全部 FULL_READ
- 范围：Tests/Common/Securities 下的 FuturesOptions 到期规则和映射、FutureOptionMargin、FutureSettlement、FuturesExpiry 及其工具、FuturesListings、IdentityCurrencyConverter、ImmediateSettlement、Index、IndexOption、IndicatorVolatility、LocalMarketHours、MarginCallModel、MarketHoursDatabase、OptionFilter、OptionMarginBuyingPower、OptionPriceModel、FedRateQL、OptionChainProvider、OptionChains、OptionFilterUniverse、OptionPortfolioModel、OptionSecurity、OptionStrategies。
- **与 V1.2 有关（待汇总，归入 R52）**：
  - (c) MarketHoursDatabase：配置项 `force-exchange-always-open` 会让所有市场视为全天开市。LEAN 研究运行须记录此项为 false，否则休市过滤、TIF 和填充都会失真。
  - (d) FXCM 外汇交易时段：周日 17:00 开、周五 17:00 收，数据时区 EasternStandard。与 FxPro 服务器时区（EET/EEST）不同，跨引擎对齐须换算。
  - (e) MarginCallModel：先发出 margin call 警告；只有组合总价值低于所需保证金时才生成平仓订单。与 MT5 Stop Out 按保证金水平比例触发的机制不同，不能互相替代。
  - (f) LocalMarketHours：时段开始时刻算开市，结束时刻算休市（左闭右开）。
  - (g) ImmediateSettlement：成交即结算，现金立即可用。CFD/外汇研究默认适用。
- **第 4 层**：期货和期权的到期规则、期权保证金、定价模型（QL）、期权链与筛选、期权组合策略构造（OptionStrategies 各腿方向与数量校验、行权价顺序和等距检查）。V1.2 不使用期权和期货。
- 密钥扫描：无命中。

## T16 / L164（2026-11-10）：tests_code.txt 第 371–395 个，25 个文件，9,103 行，全部 FULL_READ
- 范围：Options/OptionSymbol、StrategyMatcher（Option、OptionPositionCollection、OptionPosition、DefinitionMatch、Definition、LegDefinitionMatch、LegPredicate、Matcher）、OptionStrategyFilter、OptionStrategyPositionGroupBuyingPowerModel（3,643 行）、PatternDayTradingMarginBuyingPowerModel、Positions/PositionGroupCollection、PositionGroup、PriceVariationModels、ProcessVolatilityHistoryRequirements、RelativeStandardDeviationVolatilityModel、SecurityCacheProvider、SecurityCache、SecurityDatabaseKey、SecurityDefinitionSymbolResolver、SecurityDefinition、SecurityExchangeHours、SecurityHolding、SecurityIdentifier。
- **与 V1.2 有关（待汇总，归入 R52）**：
  - (h) SecurityHolding.UnrealizedProfit：多单按 bid、空单按 ask 计价，并预先扣除一笔平仓手续费估计。LEAN 的净值和回撤因此已含点差与平仓费，MT5 浮盈只用当前价、不预扣费用，两者口径不同，跨引擎核对净值回撤时须统一。
  - (i) MarginCallModel 下单量：保证金缺口 ÷ 价格 × 杠杆，四舍五入取远离零的方向（PDT 测试，开市 4 倍、休市 2 倍）。补充 R52(e)：单手组无法部分减仓时整组平掉。
  - (j) SecurityExchangeHours：
    - 区间 IsOpen(start,end) 中，bar 正好从收盘时刻开始算休市；与开盘或收盘重叠 1 tick 即算开市；
    - GetNextMarketOpen/Close 不含起点时刻；
    - 外汇 1 月 1 日 17:00 才晚开（12/31 17:00 早收），早收和晚开会把一天拆成多段。
  - (k) SecurityCache：
    - 默认 Tick（未设 TickType）按报价处理，Volume 为 0；
    - 美股 symbol 的 QuoteBar 不更新 OHLC/Price，CFD 需另核；
    - 同一时刻 QuoteBar 优先于 TradeBar 作为 GetData 结果。
  - (l) RelativeStandardDeviation 波动模型：周期未满不更新，价格为 0 不更新。
- **第 4 层**：期权组合匹配与目标函数（未覆盖空头数、裸卖保证金比较）、各策略的初始/维持保证金表（对照 IB 数值，容差 20%）、ATM 筛选、SID 编码、CUSIP/FIGI/ISIN 解析、PDT 杠杆。
- 测试会写入 `testing_data/symbol-properties/security-database.csv`，结束后删除（只在当前目录）。
- 密钥扫描：无命中。

## T17 / L165（2026-11-11）：tests_code.txt 第 396–420 个，25 个文件，10,772 行，全部 FULL_READ
- 范围：SecurityManager、SecurityMarginModel、SecurityPortfolioManager（3,066 行）、SecurityPortfolioModel、SecurityPositionGroupBuyingPowerModel、SecurityService、Security、SecurityTransactionManager、StandardDeviationOfReturnsVolatilityModel、SubscriptionDataConfig、SymbolPropertiesDatabase、TestAccountCurrencyProvider、TestDefaultMarginCallModel、TradingCalendar、UniverseManager、SeriesSampler、Series、Statistics/AnnualPerformance、DrawdownRecovery、PortfolioStatistics、ProbabilisticSharpeRatio、StatisticsBuilder、TrackingError、TradeBuilder（3,039 行）、TradeStatistics。
- **与 V1.2 有关（待汇总，新编 R53，归入评分和 RiskExecution 两组）**：
  - (a) SecurityMarginModel：
    - 已用保证金 = 持仓市值 ÷ 杠杆，并随价格实时变化；
    - CalculateOrderQuantity/SetHoldings 会乘 0.9975 缓冲（FreePortfolioValuePercentage 默认 0.25%）并预扣手续费；
    - requiredFreeBuyingPowerPercent 会再缩减可用资金。
    - LEAN 按目标比例算出的手数小于 MT5 按风险算出的手数，跨引擎对比时须登记。
  - (b) 反向或减仓时，可用购买力 = 剩余保证金 + 已用保证金 + 反向初始保证金。保证金剩余为负时，平到 0 的订单仍可通过，加仓和反手被拒。这与 V1.2 的"保护和平仓优先于新增风险门控"一致。LEAN 的这项行为只作参考，MT5 须另行验证。
  - (c) margin call：TPV 跌到 0 时下单量 = -全部持仓；剩余保证金很少（例如 1/901）时只警告、不下单。
  - (d) CFD 成交时不动现金，平仓时才按汇率把盈亏记入账户货币（DE30EUR 例：(10100-10000)×5×1.10 = 550 USD）。TotalSaleVolume 按名义价值×汇率计。
  - (e) Security 默认模型：ImmediateFill、InteractiveBrokersFee、NullSlippage、ImmediateSettlement、SecurityMarginModel。券商模型会覆盖这些默认值，每次运行必须记录实际生效的模型（呼应 R37）。只有 IBar 类数据会更新 High/Low/Close，Tick 只更新 Price。
  - (f) LastTradeProfit 不扣手续费，NetProfit = 盈亏 − 费用。按笔统计的口径须写明是毛利还是净利。
  - (g) Statistics.AnnualPerformance = (1 + 算术平均日收益)^年交易日 − 1，用的是算术平均而不是几何平均（补充 R31）。
  - (h) DrawdownRecovery 取最长的"峰值 → 回到峰值"天数；从未回到峰值时记 0。报告里恢复期为 0 可能意味着"一直没有恢复"，§11.9 的恢复时长须用原始权益曲线另行计算。
  - (i) PSR 和 Sharpe 现在会扣无风险利率，默认 InterestRateProvider 使用美国利率（补充 R31、R48）。VaR 样本少于 2 个时为 0。入金被当作收益时 Alpha 会封顶为 decimal.MaxValue。StatisticsBuilder 遇到不对齐的序列会抛异常。
  - (j) SeriesSampler：图表下采样时对相邻点取平均或插值，K 线的 Close 也是插值。不能用下采样后的图表计算回撤或权益（补充 R13、R48）。
  - (k) TradeBuilder：
    - 交易笔数取决于 FillGroupingMethod：FlatToFlat 下分批进出算 1 笔，FillToFill 算多笔，FlatToReduced 每次减仓算 1 笔；
    - FIFO 与 LIFO 改变每笔盈亏和手续费的分摊，FillToFill+LIFO 会出现手续费为 0 的笔；
    - 只有 FillToFill 计算 MAE/MFE，其余方式记 0；
    - Trade.ProfitLoss 不含手续费；
    - EndTradeDrawdown = 持仓期间有利极值 → 平仓价。
    - §13.10 的"完整交易数"必须登记分组方式，并与 MT5 的成交/持仓口径对齐。
  - (l) TradeStatistics：
    - ProfitFactor = 毛盈利 ÷ |毛亏损|，不含手续费（TotalFees 另列）。MT5 的 PF 包含佣金和隔夜利息，两者口径不同（呼应 §13.10 的费用同口径要求）；
    - 没有亏损笔时 PF 和 WinLossRatio 返回哨兵值 10，ProfitLossRatio 为 0；
    - 按笔 Sharpe = 平均每笔盈亏 ÷ 标准差，不年化；
    - 期权行权笔的 IsWin 标记会覆盖按盈亏正负判定的胜负。
- **第 4 层**：期权行权和指派的现金处理、拆股和股息、账户币种切换、SPDB 期货期权条目、外部 API 抓取（Explicit 测试会联网访问 Coinbase、Bitfinex，不运行）。
- 密钥扫描：无命中。

## T18 / L166（2026-11-11）：tests_code.txt 第 421–445 个，25 个文件，4,059 行，全部 FULL_READ
- 范围：Statistics/Trade（JSON）、Storage/LocalObjectStore（1,073 行）、StringExtensions、SymbolCache、SymbolJsonConverter、SymbolRepresentation、Symbol、TimeKeeper、Time、TimeZoneOffsetProvider、TimeZones、Util 下的 BaseDataExtensions、BusyBlockingCollection、CandlestickJsonConverter、CastingEnumerable、ColorJsonConverter、ComparisonOperator、Composer、ConcurrentSet、CurrencyPairUtil、DataDownloaderGetParameterExtensions、DateTimeJsonConverter、DecimalJsonConverter、DisposableExtensions、ExpressionBuilder。
- **与 V1.2 有关（待汇总，归入 R52、R53）**：
  - (R52-m) Time.EachTradeableDayInTimeZone：数据时区与交易所时区不同时，交易日列表会多一天或少一天。GetStartTimeForTradeBars 按日线回溯时，有午休的市场要到最后一次收盘后当天才计入；外汇日线的起点也随数据时区变化。LEAN 的日界与 FxPro 服务器日（EET/EEST 0 点）必须显式换算，不能直接按日期对齐。
  - (R52-n) TimeZoneOffsetProvider 在 DST 切换的那一刻生效（纽约 2015-03-08 02:00 当地时间）。Unix 时间戳保留到亚毫秒精度。
  - (R53-m) LocalObjectStore：默认存储上限为 10 GB/10,000 个文件，可以配置；按 PersistenceIntervalSeconds 周期落盘；拒绝 `../` 路径穿越；Research 模式超限时抛异常。V1.2 的 RiskExecution 状态持久化在 MQL5 端，不使用 LEAN ObjectStore，本项只作参考。
  - CurrencyPairUtil：XAUUSD、XAGUSD 一类 CFD 能拆出基础货币和计价货币；AU200AUD 这类 ticker 不以计价货币结尾，无法拆分。
- **第 4 层**：Symbol、SID 的序列化与映射（JSON 测试使用 TypeNameHandling.All，呼应 R48(e)，只在测试中出现）、OSI 期权代码、期货代码、组件组合（Composer）、各类 JSON 转换器。
- 测试会写入 `./LocalObjectStoreTests` 目录，结束后清理。
- 密钥扫描：无命中。测试中的 "token" 字符串只是初始化参数占位值，不是凭据。

## T19 / L167（Tests 清单第 446–470 项，共 25 个文件，均为 FULL_READ）
范围：Tests/Common/Util 下的 ExtensionsTests 后半部分，以及 FileExtension、FuncTextWriter、HistoryExtensions、JsonRoundingConverter、KeyStringSynchronizer、LeanDataPathComponents、LeanData、LinqExtensions、ListComparer、MarketHoursDatabaseJsonConverter、MemoizingEnumerable、ObjectActivator、ObjectToListJsonConverter、OptionPayoff、PythonUtil、RateGate、RateLimit/FixedIntervalRefill、LeakyBucket、ReaderWriterLockSlimExtensions、SeriesJsonConverter、StreamReaderEnumerable、StreamReaderExtensionsPerformance、StreamReaderExtensions、Validate。
- **与 V1.2 相关（R54）**
  - (a) Extensions 中的时间处理：
    - DST 跳时，即本地时间不存在的时刻，会被映射到 03:00。
    - ExchangeRoundDown 及其时区版本会跳过周末，跨 DST 时不会死循环。
    - SafeDecimalCast 把超出 decimal 范围的值截断到边界，遇到 NaN 或 Inf 时抛异常。
    - ToDecimal 把空字符串转为 0。
    - `"5e-5".ToDecimal()` 会被误解析为 10275，只有 ToDecimalAllowExponent 才正确。因此**导入 FxPro 或 MT5 导出的数值时必须先排除科学计数法**。
  - (b) DiscretelyRoundBy 按 quanta 舍入，从 0 起朝远离 0 的方向进位；quanta 大于值时结果为 0。例如 0.999 按 2 舍入得 0。手数步长的舍入应由 RiskExecution 自己实现并单测，不能照搬 LEAN 的这套语义。
  - (c) LeanData.GetConsolidatorStartTime 以 startTime（例如 09:30）为锚点，按 period 向下对齐。2h 周期下，08:30:01 对齐到 07:30。10 天周期以固定纪元对齐，13 日对齐到 11 日，7 日对齐到 1 日。**LEAN 与 MT5 的 M5/H1 起点是否一致，需要 Codex 在跨引擎核对中逐项确认**：MT5 按服务器时间 00:00 对齐。
  - (d) GetDailyCalendar 和 GetNextDailyEndTime 的日线起止取决于是否启用 extendedMarketHours；对 HSI 这类一天多段交易的品种，日线跨度会改变。XAUUSD 的 CFD 日线定义必须与 FxPro 服务器日（EET）显式对齐（呼应 R52-m）。
  - (e) LeanData 的路径与行格式：
    - forex 和 cfd 只有 Quote 数据。
    - minute、second、tick 级别的数据按日存放：`cfd/<market>/minute/<sym>/YYYYMMDD_quote.zip`，其中的条目名为 `YYYYMMDD_<sym>_minute_quote.csv`。
    - hour 和 daily 级别的数据每个品种只有一个 zip：`cfd/<market>/hour/<sym>.zip`。
    - forex/cfd 的分钟行为 `毫秒偏移,bidOHLC,bidSize,askOHLC,askSize`，共 11 列，价格不放大。equity 的价格按 ×10000 整数存放。
    - tick 行为 `毫秒,bid,ask`。
    - Codex 若把 FxPro GOLD 数据导入 LEAN，必须按这一格式生成。数据时区由 MHDB 条目的 dataTimeZone 决定。
  - (f) TryParsePath 能解析自定义前缀和混合分隔符的路径。hour/daily 路径中的日期为 DateTime.MinValue。
  - (g) AggregateTicks/QuoteBars/TradeBars 按 resolution 向下对齐；按日聚合时以 `.Date` 为起点。单个 tick 也会生成一根 bar。
  - (h) MHDB：
    - 具体条目的 earlyCloses 和 lateOpens 会覆盖通配条目 `[*]` 中同日期的值。
    - 市场级通配假日不会覆盖条目自身的 early close。BankHolidays 只影响到期规则。
    - HK33HKD 这类条目保留自己的假日。
    - 旧 CSV 格式支持 `UTC±x` 形式的固定偏移时区。
  - (i) RateGate、LeakyBucket、FixedIntervalRefill：按完整间隔补充额度（3.5 个间隔只补 3）；超时返回 false。MQL5 端的下单节流应独立实现，这些只作参考。
  - (j) KeyStringSynchronizer：同一个 key 设 singleExecution=true 时只执行一次，且可重入；设 false 时串行执行，异常不会阻塞后续调用。可借鉴为 RiskExecution "同一订单键只提交一次"的幂等设计思路，但 MQL5 端需要独立实现。
  - (k) StreamReaderExtensions 的手写解析器：空字段返回 0，`\r`、`\n`、`\r\n` 都视为行尾。**缺失值会被静默当作 0**。导入数据时需要另行校验缺失与零价。
  - (l) HistoryExtensions 和 MapFile 的拆分只适用于美股改名，不影响 XAUUSD CFD。
- **第 4 层**：
  - Python 对象与 C# 委托的互转（TryConvert/TryAs）。
  - Python 异常栈的行号偏移解析。
  - Windows 保留文件名（CON、NUL、COM0–9、LPT0–9）加前缀。
  - JSON 转换器（Series、Candlestick、SingleValueList、PortfolioStatistics 的 Min/Max 往返）。
  - 期权镜像与价内外判断、GCD、ToFinancialFigures、TryGetFromCsv、MemoizingEnumerable、ObjectActivator 克隆、ReaderWriterLock 扩展、StreamReaderEnumerable 的释放。
  - ValidateTests 中的示例邮箱是文档占位值，不转录。
- ExtensionsTests 中的 TryDownloadData 使用 Moq 模拟 HTTP 请求，不涉及真实网络。
- 密钥扫描：无命中。

## T20 / L168（Tests 清单第 471–495 项，共 25 个文件，均为 FULL_READ）
范围：
- Common/Util 的 WhoCalledMe；
- Compression、ZipStreamWriter；
- Configuration 下的 ApplicationParser、Config；
- DownloaderDataProvider 下的 DataDownloadConfig、DownloadHelper；
- Engine 下的 AlgorithmLog、AlgorithmManager、AlgorithmTimeLimitManager，以及 BrokerageTransactionHandlerTests 目录下的 Backtesting/Brokerage/Contingent/OrderRequestProcessingPool 四个文件（其中 BrokerageTransactionHandlerTests 共 3,719 行，全部读完）；
- CustomBrokerageMessageHandler、DataCacheProviders（基类及 Disk、SingleEntry、Zip 三种实现）；
- DataFeeds 下的 AggregationManager、AlgorithmStub、MapFileResolver、BacktestingFutureChainProvider、BaseDataCollectionAggregatorReader、BaseDataExchange。

- **与 V1.2 RiskExecution 高度相关（R55）。以下全部只作参考，MQL5 端必须独立实现并做故障注入测试。**
  - (a) **订单数量按 LotSize 向零截断**：1600 截为 1000，-1600 截为 -1000。截断后为 0 的订单（例如 600）会被置为 Invalid，**不会提交**，也不会出现在 open tickets 中。
    - 价格按 MinimumPriceVariation 舍入。TrailingAmount 若以百分比表示则不舍入。
    - 加密货币数量按 8 位小数截断。
    - **RiskExecution 应在提交前自行按 FxPro GOLD 的 volume_step 和 volume_min 截断。截断为 0 时明确拒单并留证，不能静默放大到最小手数**（呼应 R54(b)）。
  - (b) **重复 OrderId 会被拒**："order with id … already exists"。这是幂等提交的参考。
  - (c) 订单状态机：
    - 撤单路径为 Submitted → CancelPending → Canceled，会产生 3 个事件。
    - **同步撤单失败时，状态回到撤单前（Submitted），撤单请求记为 Error**。
    - **异步撤单期间若先到达成交事件，状态变为 Filled，随后的撤单请求以 InvalidOrderStatus 失败**。这就是撤单与成交的竞态。
    - 已经 Filled 或 Canceled 的订单，收到迟到的 Invalid 事件也不会改变状态、持仓或均价，即**终态不可被覆盖**。
    - 对 New 状态（尚未被券商确认）的订单，改单或撤单都会以 InvalidNewOrderStatus 失败。
    - 对 Filled 订单改数量失败，但仅改 Tag 可以成功。
    - 部分成交（PartiallyFilled）后仍可改单，状态变为 UpdateSubmitted。
    - **以上各条应写入 RiskExecution 的状态机单测与故障注入用例**，与冻结契约 v1.0 的 SL/TP、部分成交、对账条款逐项对照。
  - (d) 券商侧 order id 变更（BrokerageOrderIdChangedEvent）会更新 BrokerId 映射。同一个 BrokerId 可能对应多张 combo 订单，包括已成交的。**对账键必须同时保存本地 id 与券商 id，并允许券商 id 变化**（对应 MT5 的 order/deal/position ticket 三种标识）。
  - (e) 并发处理池：
    - 同一订单的 Submit、Update、Cancel 严格按到达顺序执行，即使线程池扩容也不乱序。不同订单可以并行。
    - 同一组 contingent 订单按组串行处理，不阻塞其他订单。
    - **Dispose 时，就绪队列中的请求只处理一次；排在卡死订单之后的 update 或 cancel 会被直接丢弃**；卡死的工作线程会被 interrupt。
    - **因此，进程退出或崩溃时可能丢失撤单请求。RiskExecution 重启后必须先与券商对账（持仓、挂单），再恢复新增风险门控**（对应 AGENTS"已有仓位保护与对账先于新增风险门控"）。
    - 同步模式下，Exit 后才排队的请求保持未处理状态，例如在 OnEndOfAlgorithm 中发出的改单。
  - (f) Bracket/OCO/OTO：
    - 子单在 entry 成交前保持 held（IsWaitingForTrigger），即使价格穿越子单价位也不会成交。
    - entry 成交后子单才进入工作状态，而且**需要下一笔新数据才能成交**；市价子单立即成交。
    - **同一根宽 bar 同时触及 TP 和 SL 时，按悲观假设判 SL 先成交**。
    - 一侧成交后，另一侧紧接着被取消，取消事件紧跟在成交事件之后。
    - 撤销父单会级联撤销所有子孙订单；撤销 OCO 的一侧会撤销整组。
    - **held 子单在触发前不检查购买力**，触发后才可能被置为 Invalid。**这对 V1.2 是风险点：SL 必须在入场时就按实际券商能力挂出或由 EA 保护，不能依赖"触发后才校验"**。
    - entry 购买力不足或被券商模型拒绝时，整组 Invalid。
    - GetOpenOrdersRemainingQuantity 的计算：普通单全额计入；OCO 组只计最大的一侧；held 子单不计入。**暴露计算应计入最坏情形**，即 SL 对应的反向数量；不能把 held 子单当成零风险。
    - 重启时从券商读回的挂单会保留 contingency 关系。
    - 呼应 R50/R51 中 MT5 的 SL/TP 为仓位属性，并非独立挂单：语义不同，需要 Codex 在跨引擎核对中标注。
  - (g) 现金同步（cash sync）：
    - 每日在固定时段执行一次（测试中为纽约时间早上 8 点前后）；成交后约 10 秒会再同步一次。
    - GetCashBalance 持续抛异常时，达到"maximum number of attempts"后整体抛错，不会无限循环。
    - 读取券商持仓失败的当天跳过期权持仓同步，次日再试。
    - **算法 Stopped 后，账户、订单更新、改 id 等事件全部被忽略**。
    - RiskExecution 的账户与持仓对账需要定义：失败重试上限、失败当日是否暂停新增风险，以及停止状态下的事件处理策略。
  - (h) 慢 OnOrderEvent 处理（会长时间占用锁）只警告一次。单步时长超过阈值时只警告不失败；超过 time-loop-maximum 才置为 RuntimeError。
  - (i) 券商侧新订单（例如手工单）由 BrokerageMessageHandler.HandleOrder 决定是否接管，接管后自动添加对应证券。**V1.2 需要明确手工单或其他 EA 的单不由本 EA 管理**，用 magic number 隔离，并在对账中报告。
  - (j) **实盘与 paper 模式下 PriceAdjustmentMode 强制为 Raw**，回测则沿用订阅的 normalization 设置。XAUUSD 不受影响。
  - (k) BaseDataExchange 的默认错误处理会吞掉 handleData 中的异常并继续运行；ZipDataCacheProvider 遇到损坏的 zip 时记录日志并返回 null，只有内存不足才会抛出。**两者都会造成静默的数据缺口**，LEAN 研究端需要统计缺口和异常。
  - (l) AggregationManager 不发出未闭合的 bar：100 秒只产生 1 根分钟 bar；3,599 秒产生 0 根小时 bar；100 个 tick 只产生 99 根秒 bar。**这与 M5 闭柱确认（S7）一致，最后一根未闭合的 bar 不得用于信号**。
- **第 4 层**：
  - Compression 的 zip 读写；ApplicationParser 的命令行参数（`force-exchange-always-open` 一类）；Config 的环境展开与类型转换。
  - DataDownloadConfig 的市场与合约解析（OSI、期货期权代码）；DownloadHelper 无数据时给出警告。
  - 期权到期、行权、指派与早期指派的事件，重复推送同一事件时不会重复记账；分红后退市不重复计算。
  - Locate 仅保留在开空单上；指数期权的动态最小价位。
  - MapFileResolver 的改名映射与连续期货映射；FutureChainProvider；BaseDataCollection 的聚合。
- 密钥扫描：无命中。DataDownloadConfig 只设置了 tickers、market 等配置，不含凭据。

## T21 / L169（Tests 清单第 496–520 项，共 25 个文件，均为 FULL_READ）
范围：Engine/DataFeeds 下的以下测试：
- CollectionSubscriptionDataSourceReader、CompositeTimeProvider、CustomLiveDataFeed、CustomMockedFileBaseData；
- DataDownloader 下的 CanonicalDecorator、Selector；
- DataManagerStub、DataManager、DataPermissionManager、DataQueueHandlerManager；
- DateChangeTimeKeeper、DownloaderDataProvider；
- Enumerators 下的 AuxiliaryData、BaseDataCollectionAggregator、Concat、Delisting、DividendEventProvider、Enqueueable；
- Factories 下的 BaseDataCollection、LiveCustomData；
- FastForward、**FillForward（2,655 行，全部读完）**、FrontierAware、LiveAuxiliaryData、LiveEquityDataSynchronizing。

- **与 V1.2 相关（R56）**
  - (a) **FillForward（填充前推）语义**：
    - 缺失的 bar 会以上一根的收盘价填充；IsFillForward=true，Volume=0，周期与数据分辨率相同。
    - 只在交易时段内填充；extendedMarketHours=false 时不填充盘前、盘后时段。
    - 支持 early close 和 late open：早收盘日的日线 bar 截止于早收盘时间；late open 等于收盘时间的日期不填充。
    - 可以按更细的分辨率填充，例如分钟数据按秒填充，日线数据按小时填充。
    - 不会生成与下一根真实 bar 重叠的填充 bar（GH #9092）。
    - 遇到 Delisted 后停止填充。
    - 订阅起点可以从 LastPointTracker 接续填充。
    - DST 切换时会跳过不存在的时刻，例如美东春季的周日凌晨 2 点。
  - (b) **XAUUSD M5 研究必须显式排除 IsFillForward 的 bar**，不能把它当作有效的"反转闭柱"或供需区回测的确认 bar。这一要求对应 S7 用户 SOP 中的"闭柱确认"。另外：
    - 在 LEAN 端订阅时应决定 fillForward 设为 false，或在信号层过滤；
    - 跨引擎核对时统计 FF bar 数量，与 MT5 的空缺 bar 对照：MT5 不生成无 tick 的 bar。
  - (c) forex 日线以纽约 17:00 为界（data tz=UTC 时 Time=20:00/19:00 UTC）；周日 17:00 开市，周日的 bar 计入。strictEndTimes 会改变日线的起止时间。**FxPro 服务器日（EET）与 LEAN 的 forex/cfd 日线定义不同**（呼应 R52-m、R54(d)），6 盈或 6 亏的日界线必须按 FxPro 服务器时间单独实现。
  - (d) DateChangeTimeKeeper：当交易所时区落后于数据时区时，第一个交易所日期会提前一天，各日期事件的顺序也随时区偏移变化。说明 LEAN 的"每日事件"依赖 dataTimeZone 与 exchangeTimeZone 的组合，导入 FxPro 数据时必须明确这两项设置。
  - (e) FrontierAware/FastForward：实盘中不会提前发出未来时间的数据；超过容忍窗口的旧数据会被快进跳过。ConcatEnumerator 可以按 EndTime 丢弃倒序的数据。
  - (f) 数据缺失时多处静默处理，都会造成静默的数据缺口，与 R55(k) 合并统计：
    - null source 或 Tiingo token 无效时，数据源返回空，不抛异常；
    - DataQueueHandler 中某个 handler 崩溃时会跳到下一个，只有全部失败才抛异常；
    - 远程或自定义数据按 30 分钟间隔限速刷新；
    - backup universe 文件只在开市附近才作为后备使用。
  - (g) DownloaderDataProvider 下载同一文件时会合并数据；分钟及以下分辨率按天下载，hour/daily 下载全部历史。若用 LEAN 的 downloader 获取 GOLD 数据，必须记录来源与范围，**不能把下载数据冒充为 FxPro 真实 tick**。
- **第 4 层**：
  - CustomLiveDataFeed 的周末自定义期货数据（测试源码中含一个公开测试 CSV 的 Dropbox URL，不是凭据）。
  - DataManager 的订阅配置复用、移除与重加；拒绝 ScaledRaw。
  - DataPermissionManager 拒绝配置时，算法不会启动。
  - 退市 Warning/Delisted 事件的时间点；分红事件在除息日次日发出，缺少参考价时抛异常。
  - EnqueueableEnumerator 的阻塞行为；BaseDataCollection 的聚合；期货的 canonical 日期调整；Live 映射与退市事件；同步 enumerator。
- 密钥扫描：无命中。CollectionSubscriptionDataSourceReaderTests 只验证"空或无效的 Tiingo token 不抛异常"，测试中没有 token 值。

## T22 / L170（Tests 清单第 521–545 项，共 25 个文件，均为 FULL_READ）
范围：Engine/DataFeeds 下的以下测试：
- Enumerators 下的 LiveFillForward、LiveSubscription、MappingEventProvider、PriceScaleFactor、QuoteBarFillForward、RateLimit、Refresh、Scannable、Scheduled、SubscriptionData、SynchronizingBaseData、SynchronizingSlice；
- FakeDataQueue、FileSystemDataFeed、FuncDataQueueHandler、FuncDataQueueHandlerUniverseProvider、IndexSubscriptionDataSourceReader、InternalSubscriptionManager、LiveCoarseUniverse；
- **LiveTradingDataFeed（4,631 行，全部读完）**；
- MockDataFeed、PendingRemovalsManager、PrecalculatedSubscriptionData、PredicateTimeProvider、RealTimeScheduleEventService。

- **与 V1.2 相关（R57）**
  - (a) **实盘填充前推（LiveFillForward）**：
    - 首个数据点立即发出。
    - 到点后若没有新数据，**要等 GetMaximumDataTimeout 超时才发出填充前推 bar**，期间返回 null。
    - 时钟一次跳跃很多时（例如从 warmup 切到 live），只补发最新一根预期的填充前推 bar，不回补整段缺口；收盘后最多补到上一交易段的收盘。
    - 填充前推 bar 不会越过下一根真实数据。
    - 数据时区带半小时偏移时（例如 Kolkata），补发的 bar 按数据时区对齐网格。
    - 结论：**实盘中"无新 tick ≠ 闭柱"**。MT5 端 S7 的 M5 闭柱确认应以 MT5 新 bar 的出现（iTime 变化）为准，不能模拟 LEAN 的"超时后填充前推"；LEAN 研究端遇到填充前推 bar 也必须排除（呼应 R56(b)）。
  - (b) **warmup 到 live 的数据衔接**：本地没有数据时，正式区间会全部用填充前推 bar 补齐（DataIsFillForwardedFromWarmupToNormalFeed）。**回测或研究区间缺数据时，LEAN 不报错，而是产出一串 IsFillForward 的 bar**，算法照样会"运行"。因此每次 LEAN 研究必须统计填充前推比例，比例过高即视为数据缺失，并在留证中注明（与 R55(k)、R56(f) 合并为"静默缺口"检查清单）。
  - (c) TickQuoteBarConsolidator 只聚合 Quote tick；ScannableEnumerator 需要扫描（时间推进）才会发出未满的 bar。
  - (d) 非 tick 分辨率会过滤 Suspicious tick，tick 分辨率则保留。导入 FxPro tick 时若标记可疑 tick，要注意分辨率不同会导致结果不一致。
  - (e) DataQueueHandler 抛异常时，算法置为 RuntimeError 并停止。实盘中分红不会直接计入组合，留给 cash sync；拆股会调整持仓，warmup 期间不调整。XAUUSD 不涉及分红和拆股，但"现金同步才是最终口径"这一点与 R55(g) 一致。
  - (f) 合并 bar（UsesFullPeriodDataForConsolidation，GH #8363）：第一根合并 bar 只用起点到下一个整倍数边界之间的数据，可能不满 N 根；之后每根各用 N 根。**LEAN 中 M5 合并的第一根可能不完整**，研究端应丢弃首根，或按 MT5 的服务器时间网格对齐（呼应 R54(c)）。
  - (g) EmitsForexDataWithRoundedUtcTimes：forex 实盘时间片按 UTC 整秒推进。
  - (h) PendingRemovalsManager：有挂单、持仓、目标仓位或未结算资金时，不移除证券，挂起到可以安全移除时再移除。这与"已有仓位保护和对账优先"的原则一致，可作为参考。
- **第 4 层**：
  - 期货、期权、指数期权链、ETF、粗选、自定义 universe 的立即选择和按计划选择；backup universe 文件在开市前约 30 分钟内才作为后备使用。
  - 期货连续合约映射与持仓（`LiveTradingResultHandler.GetHoldings`）；过期的期货和期权只在 warmup 期间取数据；fine/coarse 基本面数据；保证金利率数据。
  - PriceScaleFactor 与 ScaledRaw 的前瞻调整；MappingEventProvider（TFCFA→NWSA→FOXA）；Refresh/RateLimit/Scheduled 枚举器；同步枚举器；InternalSubscription 补充秒级内部订阅。
  - HandlesAllTypes 按品种统计 tick/bar 数量（CFD 按交易时段计算，例如 DE30EUR 的 Oanda 数据为 21 小时/天）；性能基准。
  - TestCustomData 的 REST source 指向一个 localhost 假地址，`RestCustomDataReturningNullDoesNotInfinitelyPoll` 验证 30 分钟内只轮询一次。
- 密钥扫描：无命中。

## T23 / L171（Tests 清单第 546–570 项，共 25 个文件，均为 FULL_READ）
范围：
- Engine/DataFeeds 下的 RestApiBaseData、SubscriptionCollection、SubscriptionDataReader、SubscriptionData、SubscriptionSynchronizer、Subscription、SubscriptionUtils、TextSubscriptionDataSourceReader、TimeSlice、Transport/RemoteFileSubscriptionStreamReader、UniverseSelection、ZipEntryNameSubscriptionFactory；
- DataProviders 下的 ApiDataProvider、DefaultDataProvider、ProcessedDataProvider；
- Engine 下的 DefaultBrokerageMessageHandler、DefaultOptionAssignmentModel；
- HistoricalData 下的 FakeHistoryProvider、HistoryProviderManager、SubscriptionDataReaderHistoryProvider；
- PartialFillModel、PerformanceBenchmarkAlgorithms、ProcessSplitSymbolsDuringWarmup；
- RealTime 下的 BacktestingRealTimeHandler、LiveTradingRealTimeHandler。

- **与 V1.2 相关（R58）**
  - (a) **SubscriptionDataReader 会丢弃按日存放的分钟数据中超出当日的行**：毫秒偏移超过一天（例如 99,900,000）的行在有下一日数据源时不会发出；日线文件不受影响。**导入 FxPro 分钟或 tick 数据时，每日 zip 中的毫秒偏移必须在 [0, 86,400,000) 之内，并按数据时区切分日期，否则会静默丢行**（与"静默缺口"清单合并）。
  - (b) **SubscriptionData.Create 会把带周期的数据的 Time 向下取整到周期网格**：08:09 的小时 bar 会变为 08:00–09:00。不带周期的数据不取整。错位的 bar 会被静默"对齐"，所以导入数据时要先校验 bar 起点是否落在网格上。
  - (c) 填充前推分辨率取所有非 tick、非内部订阅中最小的分辨率，默认为 1 分钟；移除订阅后会回退。tick 订阅与内部订阅不影响该分辨率。
  - (d) 读取缓存：非 ephemeral 的缓存提供者会缓存 daily 和 hour 数据，分钟及以下分辨率不缓存。因此**数据文件在运行中被更新时，可能仍读到旧缓存**。研究时应固定数据快照，并记录哈希。
  - (e) TimeSlice 会把 Suspicious tick 排除在合并器输入之外，tick 本身仍在 Slice 中。
  - (f) RemoteFileSubscriptionStreamReader：空响应会重试，最多 3 次；空下载不写入缓存；地址缺少协议头时抛 WebException。**该测试源码中有一个 Quandl 代理 URL，其查询参数里含有 key 值，按规定不转录**。这只是第三方测试用的固定字符串，与本项目无关，也不使用。
  - (g) ApiDataProvider 按文件的修改时间判断数据是否过期：daily 和 hour 级别的 cfd/oanda/xauusd 数据在若干天后被视为过期，需要重新下载；按日存放的分钟、秒、tick 文件不会过期。**如果研究端误用 ApiDataProvider，本地导入的 FxPro 数据可能被覆盖**。研究端应使用 DefaultDataProvider 或只读目录，并记录文件哈希。
  - (h) DefaultBrokerageMessageHandler：断线时若所有证券都已收市，不会置为 RuntimeError；在宽限期内重连会取消错误。**MT5 端 RiskExecution 应定义断线宽限期**：断线期间暂停新增风险，重连后先对账再恢复。
  - (i) **实盘会定期刷新 MHDB 和 SPDB**（DatabasesRefreshPeriod，默认 1 天），LotSize、MinimumPriceVariation、交易时段和假日可能在运行中改变，已经排好的事件也会按新规则触发。**RiskExecution 每次下单前都应重新读取 SYMBOL_VOLUME_STEP/MIN、TICK_SIZE、交易时段等属性，不能只在初始化时缓存**。
  - (j) BacktestingRealTimeHandler：同一时刻的事件按添加顺序触发；Setup 时会跳过早于开始时间的事件；没有实现 OnEndOfDay(symbol) 时不会添加日终事件。
  - (k) PartialFillModel（测试辅助类）：按比例分批部分成交，余量记录在字典中；成交数量用 (int) 截断。可作为 RiskExecution 部分成交故障注入的参考样式，MQL5 端需独立实现。
- **第 4 层**：
  - SubscriptionCollection 的并发增删和按证券类型排序；Subscription 的 universe 增减；SubscriptionUtils 的生产者线程，遇到异常或 null 时结束；价格缩放不更新填充前推 bar。
  - UniverseSelection：大 universe 告警、退市后待安全再移除、ETF 链式基本面使用前一日数据（GH #9793）、末尾没有交易日时不加入、重新加入时处理订阅分辨率。
  - ZipEntryName 读取期权合约列表；DefaultOptionAssignmentModel 的提前指派判断；历史提供者的 FOXA/NWSA、WM/WMI 映射与 DataPointCount；拆股 warning 处理不抛异常。
  - RestApiBaseData 的 REST 源指向 quantconnect.com 的测试端点，测试标记为 Ignore，不访问网络。
- 密钥扫描：正则无命中；人工发现 (f) 中 URL 的查询参数，已标注为不转录。

## T24 / L172（Tests 列表 571–595：Engine/Results 分析器与结果处理、Setup、Indicators 首批）FULL_READ

- 机密扫描：0 命中。
- **R59 (a–k)**：
  - a. BacktestingResultHandler 测试承认基准与策略样本错位（beta 0.876 vs 0.989）→ Beta/Alpha 不宜作评分项；与 §11.9 夏普仅辅助诊断一致。
  - b. LiveTradingResultHandler：StartingPortfolioValue 在 warmup 结束后重新捕获（warmup 时汇率未更新）→ V1.2 日内/账户风险基线必须在预热完成、报价有效后才锁定，不可用启动时快照。
  - c. 持仓变化后经 settle 延迟（holdings-changed-store-delay）才强制存储结果；无成交订单事件不触发 → 状态持久化应以"成交/持仓变化已稳定"为触发点，挂单/撤单另记。
  - d. 实盘图表裁剪：Return/Benchmark 保留 2 年日点，Equity 旧日聚合为日 OHLC，自定义图表只留 2 天 → LEAN 实时图表不是完整审计证据，原始成交/订单须另存。
  - e. RuntimeStatistic：编码值（base64/hex 形）被拒、数量封顶，只警告一次；DeploymentDetails 对算法只读、空键忽略、null 存为空。
  - f. ResultsAnalyzer：in-run 分析按 watermark 去重；订单事件窗口截断时被挤出的事件**会被漏分析**（测试明示）；时间限额截断后续分析；同一发现返回 3 次后静音（状态型清除后再失败仍静音）→ 分析器输出不能作为完整异常清单，V1.2 需自有全量对账。
  - g. FlatEquityCurve 只报最长 5 段；PortfolioValueIsNotPositive 在统计未就绪时不报；SingleTimeLoopTimeout/MOC 太晚等为 Tier 4 诊断。
  - h. BaseSetupHandler：minute 历史缺失时回退 daily 求汇率；运行期新增币种立即播种汇率（修复前为 0）→ XAUUSD 账户币 USD 无影响，但多币种时汇率为 0 风险需核。
  - i. BrokerageSetupHandler：加载券商已有持仓/挂单；零数量挂单忽略并单次警告；不支持的 Base/custom 符号持仓 → Setup 失败；GetAccountHoldings/GetOpenOrders 抛异常 → Setup 失败；总值为 0 只发 Debug 警告不失败；MaxAllocationLimit 超限失败；零余额币种不入 CashBook（账户币除外）；持仓以券商 MarketPrice 播种。→ 对应 V1.2 RiskExecution 重启对账：启动时券商状态读取失败应阻断新增风险但不阻断保护（与契约"保护/对账先于门控"一致，LEAN 直接整体失败，语义不同须记录）。
  - j. AlgorithmTime 在 PostInitialize 前设为 UtcNow（实盘）。
  - k. Indicators 首批（APO、AccelerationBands、AD、ADOSC、A/D Difference/Ratio/VolumeRatio）：外部 CSV 对照，容差 1e-4；A/D 系列任一成分缺失该周期即忽略（值保持）→ Tier 4，S1–S6 若引用需按 MQL5 版本另行对照。

## T25 / L173（Tests 列表 596–620：Indicators Alpha…ConstantIndicator，含 CommonIndicatorTests 基类）FULL_READ

- 机密扫描：0 命中。
- **R60 (a–i)**：
  - a. **CommonIndicatorTests 默认断言**：绝对容差 1e-3，另有 `relativeDifference <= 1`，注释写"less than 1% error rate"，但 1 实际是 100%；真正起作用的是绝对 1e-3。对价格量级较大的 XAUUSD（约 2000+），1e-3 绝对容差相当严格；对接近 0 的振荡器则较宽松。→ 若把 LEAN 指标测试当跨引擎一致性依据，需自定容差，不可沿用此注释。
  - b. 宽容差个案：ARIMA 绝对 10、ADXR 1.0、AugenPriceSpike 1、CCI 1e-2、BB 下轨 1e-3、ChandeKroll 1e-6 → LEAN 内"通过"不等于与 MT5 实现逐值一致。
  - c. TimeMovesForward：更早时间戳的输入被忽略（10 次倒序只记 1 个样本）；BB DoesNotUpdateWhenStale 显示同值同时间重复输入不触发 Updated → MQL5 端若重放/补数据，乱序 bar 处理需与 LEAN 语义一致，否则跨引擎核对差异。
  - d. WarmsUpProperly 统一要求恰好 WarmUpPeriod 个样本后 IsReady；WarmUpIndicatorProducesConsistentResults 验证 WarmUpIndicator 与手动 History 喂数一致 → 指标预热口径可在 LEAN 内复现，但 MT5 的 bars 预热需另核。
  - e. 蜡烛形态：以 TA-Lib 为外部基准，因 LEAN 用 decimal、TA-Lib 用 double，部分形态（HighWave、HikkakeMod、MorningStar@EURUSD、RickshawMan/ShortLine/SpinningTop@SPY、StickSandwich）只在特定数据文件上通过 → 用户 S7 反转闭柱若引用"形态识别"，不能假定与 MT5/TA-Lib 逐根一致，需自定义并单独验证。
  - f. Alpha/Beta：双符号对齐时间才计；Beta period 最小 2；不同时区（SPY vs BTCUSD）仍可算；无风险利率参数/模型可选 → 与 R59a 一致，Alpha/Beta 仅诊断。
  - g. A/D 族、ArmsIndex（TRIN）：多成分缺一则该周期保持旧值 → Tier 4。
  - h. ATR：默认 Wilder，ComparesAgainstExternalData 改用 Simple；TrueRange 需 2 次更新才 Ready → 若 V1.2 SL/仓位使用 ATR，需明确平滑类型并与 MQL5 iATR（SMA 初始化 + 平滑）逐值核对。
  - i. CMF 零成交量/High=Low 返回 0；CRSI 全 0 输入不抛异常；Composite 两侧都 Ready 才 Ready；Constant Reset 保留值 → Tier 4。

## T26 / L174（Tests 列表 621–645：Indicators Coppock…Ichimoku）FULL_READ

- 机密扫描：0 命中。
- **R61 (a–g)**：
  - a. **EMA 初始化**：EmaComputesCorrectly 明示 LEAN EMA 在第一个完整周期用 SMA 作种子，之后按 2/(N+1) 递推。MT5 iMA/MovingAverages.mqh 的 EMA 初始化口径（首值 vs SMA 种子）需逐值核对；早期 bar 会有偏差，跨引擎核对时应跳过预热区，或统一种子方式（未核验 MT5 实际行为，记为待核）。
  - b. 双符号指标（Correlation/Covariance/Beta/DualSymbol 基类）：两侧时间对齐才计样本；倒序输入被忽略；Correlation 周期最小 3、Covariance 最小 2；不同时区可算 → 若 NR07 黄金/美元关联使用相关性，需明确对齐口径（LEAN 按 bar EndTime 配对）。
  - c. 期权 Greeks（Delta/Gamma）：QuantLib 参考，容差 0.0017/0.0005；第三方数据集 2 注明"不确定平滑函数，不逆向"，容差 10000（实际不检验）→ Tier 4（V1.2 不交易期权）。
  - d. 容差：FRAMA 0.006、EMV 1、HeikinAshi/Hilbert/Ichimoku Tenkan 1e-3，Donchian/Ichimoku 其他分量精确相等；DerivativeOscillator 1e-9。
  - e. 测试可靠性：ForceIndex、ChoppinessIndex 的 VolumeRenko 测试注释为"取消注释会挂起"→ 已知测试缺口，记录即可。
  - f. Delay(N)：需 N+2 次更新才输出非初始点；FunctionalIndicator/FilteredIdentity（Python 过滤器）→ Tier 4。
  - g. Donchian 上/下轨与外部数据精确相等 → 若 S7 供需区或 S1–S6 使用通道高低，可作为 LEAN 侧参考实现，但 MT5 端仍需同 bar 序列逐值核。

## T27 / L175（Tests 列表 646–670：Indicators Identity…MESA，含 IndicatorTests/IndicatorExtensions/IndicatorResetContract）FULL_READ

- 机密扫描：0 命中。
- **R62 (a–i)**：
  - a. **IndicatorBase 通用规则**（IndicatorTests.PassesOnDuplicateTimes）：时间戳与上次相同的输入被忽略，配合 R60c 的"更早时间被忽略"→ LEAN 指标只接受严格递增时间。MQL5 若同一 bar 多次重算（tick 内反复 OnCalculate），语义不同；跨引擎核对应以"闭柱一次"口径比对。
  - b. 不 Ready 时的输出：LSMA 在未就绪前直接输出原始输入价（Expected 前 19 个 = 原价）；LogReturn 未满周期时以首个值为基准；Max/Min 从第一笔即输出 → 不能以 "Current.Value 非 0" 判断可用，必须检查 IsReady（与 S7 反转闭柱确认的就绪门控相关）。
  - c. 组合运算（Plus/Minus/Over/Times）：只有两侧都更新后才更新，单侧更新时组合值保持旧值；Over 遇除数 0 不发出更新 → 组合信号可能"沉默保持旧值"，需加新鲜度检查。
  - d. Window/Previous：默认值 (MinValue, 0)；Reset 保留窗口大小但清空 → Tier 4。
  - e. IndicatorResetContractTests：用反射遍历所有指标，构造失败、输入类型不支持或喂数抛异常时 Assert.Ignore（作者在注释中承认"未预热的用例什么都没断言，看起来却像通过"，并统计 Ready 比例）→ "全量 Reset 契约通过"不代表每个指标都被验证。
  - f. IndicatorExtensions：Of/WeightedBy/SMA/EMA/MAX/MIN 链式；Python 组合等价 → Tier 4。
  - g. IntradayVwap 按会话；Reset 后同会话不带入旧成交量 → XAUUSD 无真实成交量（tick volume），VWAP 类不宜直接移植。
  - h. LSMAWithReference：按时间配对，到达顺序不影响；不同时间不配对；参考价不变时回退为目标价 → Tier 4。
  - i. Keltner（EMA 中轨 + ATR）容差 1e-3；KVO/KST/MassIndex/MAD/McGinley/MAMA/McClellan（需人工设置 EMA 种子，容差 0.02）→ Tier 4。

## T28 / L176（Tests 列表 671–695：Indicators MidPoint…PythonIndicator）FULL_READ

- 机密扫描：0 命中。
- **R63 (a–h)**：
  - a. **PivotPointsHighLow**（与 S7"最近有效供需区"的摆动点识别相关）：默认 strict，相等的高/低点不算 pivot；relaxed 模式才接受；pivot 需要左右各 N 根 bar 才确认，也就是 pivot 在其后 N 根 bar 闭合时才可知。→ 供需区端点若参照此实现，确认时间点必须延后 N 根，否则在回测中会用到未来数据；strict 与 relaxed 的选择须写入 S7 研究登记（不改用户核心规则，只是实现细节）。附带发现：测试注释"middle bar low (50)"与数据 low=90 不符，属测试注释笔误。
  - b. 零成交量口径不一：MFI 返回 100，而 CMF/DeMarker 返回 0（R60i、R61）→ XAUUSD tick volume 若为 0 或缺失，各量价指标的回退值不同，组合使用前需统一处理。
  - c. Momentum 未就绪时输出原值（同 R62b）；Momersion 带 minPeriod 时提前输出 50 → 同样必须门控 IsReady。
  - d. MACD：fast<slow 才合法；Signal/Histogram 在 slow+signal-1 后才就绪，容差 1e-4 → 与 MT5 iMACD 的 signal 用 SMA（MT5 内置 MACD 的 signal 线为 SMA）还是 EMA 需核对；LEAN 默认 EMA（未在此测试中直接断言，记为待核）。
  - e. PSAR/SAREXT 容差 1e-4；PPO/NATR/OBV（科学计数 2 位有效数字比较，极宽）→ Tier 4。
  - f. NHNL 系列：至少 1 个跟踪资产才 Ready，移除最后一个即不 Ready；任一成分缺失则该周期忽略 → Tier 4。
  - g. OptionBaseIndicatorTests：误差容忍 max(errorRate×|expected|, 1e-4)；到期后 Greeks 归 0；无风险利率模型每次更新都被调用 → Tier 4。
  - h. PythonIndicator：Reset 递归防护、Python 抛异常时仍清空 C# 状态；未声明 WarmUpPeriod 默认 0；RegisterIndicator 会拒绝 consolidator 与证券数据类型不匹配（QuoteBar vs TradeBar）。V1.2 中 Python 仅用于 MCP，此项为 Tier 4。另：IsReadyAfterPeriodUpdates 连续 3 次使用 DateTime.UtcNow，依赖时钟分辨率区分时间戳，按 R62a 规则存在偶发失败的可能（测试脆弱性，不影响结论）。

## T29 / L177（Tests 列表 696–720：Indicators ROC…SwissArmyKnife，含 RollingWindow/Session）FULL_READ

- 机密扫描：0 命中。
- **R64 (a–j)**：
  - a. **更正 R62a**：IndicatorTests.PassesOnDuplicateTimes 两次传入的是同一个数据对象、同一个值，断言无法区分"被忽略"与"被重新计算"，属于空断言。而 SharpeRatioTests 连续 20 次使用同一个 `new DateTime()` 时间戳，结果仍非 0，说明至少 SharpeRatio 不会丢弃重复时间戳。已被测试证实的只有：比上次**更早**的时间戳被忽略（R60c TimeMovesForward）。"重复时间戳被忽略"降级为**未证实**，需在 Codex 复核时读 IndicatorBase.Update 源码确认（Indicators 目录已在 L125–L136 读过，复核时回查）。R62a 中关于 MQL5 同 bar 多次重算的建议仍成立：跨引擎比对一律以闭柱一次为口径。
  - b. **RollingWindow 静默默认值**：索引超出 Count 但在 Size 内时返回 default（数值为 0），超出 Size 时 getter 会**自动扩容**并返回 0，不抛异常；负索引超界才抛异常 → 策略代码若在未满窗口时读取 window[k] 会得到 0 而不是报错。S7"最近有效供需区"或反转闭柱回看若用 RollingWindow，必须先检查 Count 或 IsReady。
  - c. **StandardDeviation 为总体标准差**（除以 N，测试中以 Julia stdpop 验证）→ Bollinger 宽度与 MT5 iBands（MT5 内置同为除以 N，待核）需一致；若某一端用样本标准差（除以 N−1），带宽会系统性偏差。
  - d. RSI 默认 Wilder 平滑（外部列名 "RSI 14 Wilder"），可选 Simple → 与 MT5 iRSI 平滑方式需逐值核对（未核验）。
  - e. Session 指标：Scan 到新交易日时创建 OHLC 全为 0 的新会话 bar；下一交易日按交易所日历跳过假日 → session[0] 在新日首笔数据前为 0，不能当作当日开盘价；XAUUSD 的"日"边界须与 FxPro 服务器日一致（用户 Scalping 6 盈/6 亏换日为 00:00 服务器时间，R56b 已记录 LEAN 的 Forex 日边界为纽约 17:00）。
  - f. Stochastic：最高等于最低时返回 0；主输出为 FastStoch；StochK/StochD 容差 1e-3。
  - g. SharpeRatio/Sortino 指标：值不变或为 0 时返回 0（而非 NaN），可接入无风险利率模型；Sortino 与 CME 文献值 4.417 一致 → 这是滚动指标，不是绩效统计口径（后者见 L013/L016），二者不要混用。
  - h. RelativeDailyVolume：默认 WarmUpPeriod 为 0，WarmUpIndicator 会直接跳过；已修复日内缺口槽位回退的 bug（GH #9629）→ 依赖 tick volume，Tier 4。
  - i. RegressionChannel 上下轨 = LSMA ± k×总体标准差；SuperTrend 容差 0.05；RVI 信号线容差 0.06；STC 容差 1；SwissArmyKnife 0.01–0.043 → 宽容差个案，补充 R60b。
  - j. 已知挂起：SmoothedOnBalanceVolume 的 VolumeRenko 测试注释为"取消注释会无限挂起"（同 R61e）。

## T30 / L178（Tests 列表 721–745：Indicators T3…WilderSwingIndex，含 TestHelper）FULL_READ

- 机密扫描：0 命中。
- **R65 (a–h)**：
  - a. **再次佐证 R64a**：TestHelper.TestIndicatorReset 中的 IndicatorDataPoint 版本对整个文件的每一行都使用同一个时间 `DateTime.Today` 调用 Update，之后断言 IsReady；ValueAtRisk 的 DivisionByZero 测试同样以 252 次 `new DateTime()` 达到 IsReady。若重复时间戳会被丢弃，这些测试不可能通过 → 对 IndicatorDataPoint 路径，基类**不会**丢弃重复时间戳。R62a 原结论作废，只保留"更早时间戳被忽略"（R60c，仍待源码回查边界）。
  - b. TestHelper.TestIndicator 只在 IsReady 且外部列非空时才断言 → 所有"与外部数据一致"的测试**都不覆盖预热期输出**；与 R62b/R63c 一致，预热期行为只能靠专门测试。
  - c. GetTradeBar：CSV 缺少 volume 列时 Volume 记为 0；Renko 测试辅助会把 0 成交量改为 1 → 零成交量处理在测试辅助层被掩盖。
  - d. 测试数据质量：TomDemarkSequential 测试数据存在 High<Low 的不合法 bar（如 High 94/Low 95.5、High 91.8/Low 90.8），指标未校验 OHLC 合法性 → V1.2 数据入口需自行校验 OHLC 一致性（与 R54l 静默零值同类）。
  - e. VolumeProfile/TimeProfile：零成交量 bar 下 POC 可变为 0；价格按 1 单位分档（314.242→314.25）；值区域扩展已修复无限循环 → Tier 4（XAUUSD 无真实成交量）。
  - f. VWAP（滚动 50）在成交量恒定时等于 SMA；VWMA/Vortex/WaveTrend（容差 1e-4）/T3（2e-2）/TDD（1e-6）/VaR（1e-3，252 日，0 值时返回 0）→ Tier 4。
  - g. UltimateOscillator 价格恒为 0 时返回 50（而非 0）；TSI 的 signal 未就绪时跳过断言 → 各指标对退化输入的回退值不统一（补充 R63b）。
  - h. Theta 近到期误差率放宽到 0.6；Vega/Theta 第三方数据集 2 不检验 → Tier 4。

## T31 / L179（Tests 列表 746–770：Indicators 收尾、JobQueue、Logging、Messaging、Optimizer 全部、AssemblyInfo）FULL_READ

- 机密扫描：0 命中。
- **R66 (a–j)**：
  - a. **LEAN 优化器只是"选最佳"工具**：OptimizationAnalyzer 的 Best 是 Sharpe 的 argmax，另给出 Mode（局部峰值及邻居数）、Cluster（上限 ceil(√N)）、零订单失败汇总；LeanOptimizer 以单一 Target（如 Profit 最大化）加 Constraint（如 Drawdown≤0.15）选解。没有多重检验校正，没有样本外拆分，没有试验次数登记 → 与当前计划 §11.1/§11.9/§13.8–§13.10 的要求（试验次数、冻结后独立样本外验证、35/25/20/10/10 评分、夏普仅作辅助）**不等价**。LEAN 优化输出只能作为候选生成器，晋级必须走项目自己的评分与验证流程；argmax-Sharpe 的"Best"不可直接当 Champion。
  - b. **静默失败**：Constraint 遇到无法解析的值（如 "10.0%" 字符串）时返回"未满足"，不报错；Target 名拼错（"Sharp Ratio"）时返回 null，不报错；空 JSON 结果计为 Failed 后跳过 → 优化配置写错可能悄悄排除所有解或只按部分指标选解，需人工核对目标名与约束。
  - c. 网格边界：步长不能整除区间时最大值**不被包含**（ema-fast 3..6 步长 2 → 3、5；3..6.75 → 3、5）；Euler 搜索按 DefaultSegmentAmount 逐层细化到 MinStep，深度 = ceil(log_seg(step/minStep)) → 参数网格设计需显式包含端点。
  - d. 无步长时由 DefaultSegmentAmount 推导 step=(max−min)/seg、minStep=step/10；seg≤0 或缺设置即抛异常；min>max、步长≤0 抛异常。
  - e. 并发：MaximumConcurrentBacktests 限制同时运行数；全局 Config 存储非线程安全（测试作者用锁规避构造期读与写的竞态）→ 若用 LEAN 优化器并行跑，配置读写需串行（与项目"固定 MT5 测试串行"原则同向）。
  - f. StaticOptimizationParameter 原样保留字符串（日期、"1.10"、true、null）。
  - g. ConsoleLeanOptimizer：.dll 通过 `dotnet` 启动，可执行文件直接启动，工作目录为其所在目录 → Tier 4（V1.2 不运行 LEAN，仅只读审计）。
  - h. ZigZag 测试 10 次使用同一时间戳仍更新 LowPivot（再次与 R64a/R65a 一致）；WindowIdentity/ZLEMA（WarmUp=7，period 5）/Williams %R → Tier 4。
  - i. StreamingMessageHandlerTests 整类 `[Ignore]`（需要 TCP 端口）→ 未被 CI 覆盖；FileLogHandler 写文件；JobQueue 按扩展名判定语言，.jar 抛异常 → Tier 4。
  - j. Tests\Properties\AssemblyInfo.cs：仅程序集属性与 GUID，无逻辑。

## T32 / L180（Tests 列表 771–795：Tests/Python 全部：包装器、Pandas 转换、PythonData、PythonPackages、虚拟环境）FULL_READ

- 机密扫描：0 命中（PythonPackagesTests 中的公开数据集与模型 URL 不是凭据，按原则不转录）。
- 定位：V1.2 规定 Python 仅用于 MCP 监控、不参与交易，本批整体属 **Tier 4**；以下只记录与评估口径或测试可信度有关的项目。
- **R67 (a–h)**：
  - a. **统计异常值被固化为回归期望**：CustomBenchmarkRegressionAlgorithm 的期望 Information Ratio 为 −6.65×10²⁷，Tracking Error 为 11.906；其他回归期望中 PSR、Sharpe 在只有 1 至 15 笔交易时也给出 67%–94% 之类的数值 → 与 R59a、R66a 一致：LEAN 的比率类统计在样本极少或基准退化时数值无意义，只能作诊断；V1.2 评分按 §13.10 使用自有口径，并要求最低完整交易数。
  - b. **空断言与无效测试**：大量 Pandas 兼容测试用 Python `if data is 0:` 判断，这是对象身份比较，对 float、Series 实际上永远为假，"Data is zero" 断言不可能触发；BackwardsCompatibility 中 `functions.Concat(additionalFunctions)` 的返回值被丢弃，clip_lower/clip_upper 从未加入用例；SanityClrInstallation 全部包在 try/except 中，`walk(print(...))` 写法有误，测试必然通过 → 这些测试只能证明"不抛异常"，证明不了数值正确（与 R62e、R64a 同类）。
  - c. PandasConverter：同一时间戳的多笔 tick/OI 会分行保留，不合并；trade/quote/OI 混合时缺失列为 NaN；QuoteBar 的 close 等于买卖中价；动态属性缺失时为 NaN 而不是 0；default(DateTime) 的指标点会被过滤 → 若将来用 Python 做离线分析，需注意 NaN 与重复时间戳的处理（不影响 MQL5 执行）。
  - d. PythonPackagesTests（Category `TravisExclude`）：仅做导入和冒烟测试，部分在运行时访问外部网络（GitHub raw、S3 数据集、NumerAPI 排行榜、Hugging Face 模型），多项标为 Explicit 并注明"与其他测试并跑会挂起"；固定了版本号，如 quantstats 0.0.77、pyfolio 0.9.9、pandas_ta 0.3.14b0 → 与 QuantSkills/Kronos 审阅交叉时，可作为 LEAN 容器内 Python 包版本的参考，但这些测试本身不证明任何量化结果。按约束本审阅不安装、不运行。
  - e. AlgorithmPythonWrapper：用户 OnEndOfDay 出错只写入 RunTimeError、不抛出；OnMarginCall 返回 None 会抛异常；Python 自定义 MarginCallModel 可以返回任意订单（测试中返回 3 个相同订单）→ Tier 4。
  - f. BasePythonWrapper：Python 返回类型、out 参数个数或类型不符时抛 InvalidCastException/ArgumentException；字典返回 None 合法 → Tier 4。
  - g. PythonData：只设 Time 或只设 EndTime 时两者相等；实盘下 GetSource 返回 None 会作为 null 传给数据源 → Tier 4。
  - h. 内存泄漏测试允许 5% 噪声；虚拟环境测试在测试目录创建 `testenv` → Tier 4。

## T33 / L181（Tests 列表 796–820：Python 自定义模型收尾、RegressionAlgorithms/*.py、RegressionTestMessageHandler、RegressionTests、Report、Research/QuantBook、RegressionTemplates）FULL_READ（内嵌 JSON/notebook 期望输出按 DATA_AUDITED 方式审计）

- **机密扫描：1 处命中**——`Tests/RegressionTests.cs` 第 36 行以 `Config.Set("quandl-auth-token", "<明文>")` 硬编码了一个第三方数据服务认证令牌。原扫描正则只匹配 `key = "..."` 形式，漏掉了 `Config.Set(name, value)` 形式，已补充 `Config\.Set\("…(token|key|password|secret)…", "…")` 规则；对已导出的 T1–T33 全部回扫，只有这一处。**按约束不转录令牌值**；性质与此前 R-系列记录的 Quandl URL 内嵌 key 相同（上游公开仓库中的测试凭据，是否仍有效未知，不验证、不使用）。ResultDeserializationTests 的内嵌 JSON 仅含空 `password` 字段与公开示例 ID，无凭据。
- 内嵌数据说明：ResultDeserializationTests 的 BacktestResult/LiveResult JSON（44 行超长行）与三个 RegressionTemplates 的 notebook 期望输出（共 265 行字符串拼接）属于序列化测试数据，代码部分已全读，数据部分以结构查看和关键字扫描方式审计。notebook 期望输出中嵌有 .NET Interactive 生成的作者本机局域网 IP 探测地址（私网段）→ 属于上游作者环境元数据外泄，不是凭据，不转录具体地址。
- **R68 (a–i)**：
  - a. **回归"期望统计"是快照，不是独立推导**：RegressionTestMessageHandler 在 `regression-update-statistics=true` 时，会把实际运行产生的 Statistics、DataPoints、AlgorithmStatus **直接改写回** Algorithm.CSharp 源文件中的 ExpectedStatistics → LEAN 回归测试只能证明"与上次快照一致"（golden master），不能证明统计数值正确；结合 R67a 中异常值被固化（IR −6.65e27）的情况，回归通过不是正确性证据。DataPoints 为 −1 的用例跳过数据点核对（非确定性）。
  - b. RegressionTests：Category `TravisExclude`/`RegressionTests`；支持 shard 分片；每个用例前执行 Config.Reset → 依赖全局配置，并行时需注意（与 R66e 同类）。
  - c. **Report 重建组合忽略保证金**：PortfolioLooperAlgorithm 对 Equity/Forex/CFD（含 XAUUSD@Oanda）/Crypto 一律设杠杆 10000，Option/Future 为 1；只按订单回放持仓与市值，不检查保证金 → LEAN Report 中的暴露、持仓图不能用作保证金或杠杆合规证据（V1.2 的 1:1000 保证金须按 MT5 实际规则另核，计划 §6）。PortfolioLooper 只保留未平仓持仓和当次订单标的；无 LastFillTime 的 MOO/MOC 订单以克隆后的成交订单代替。
  - d. Report：DrawdownCollection 按权益序列计算回撤段（示例中最大 20%）；Rolling.Beta 容差 1e-3；PercentChange 遇 0 时产生 +∞（未过滤）→ 报告统计口径同样不作为评分依据。
  - e. **QuantBook 历史：fill-forward 和扩展时段会让 bar 数成倍变化**（期权 390 至 1920，期货 2700 至 8640）→ 与 R56/R57 一致：LEAN 研究端拉数时必须显式关闭 fill-forward 并固定时段口径，否则 M5 信号统计与 MT5 bar 数不可比。多证券历史中 EURUSD 日线时间戳为纽约 20:00（数据为 UTC 日切），与 SPY 的 16:00 不同 → 日线对齐口径需按品种确认（关联 R56b、R64e 的日边界问题）。
  - f. 日期规则：MonthEnd 选择返回 2014-03-29（星期六，即最后一个交易日 bar 的 EndTime 为次日 0 点），MonthStart 返回 4 月 1 日；Universe 历史以 EndTime 计时 → 时间戳语义为"bar 结束时间"，跨引擎对齐时需注意（MT5 bar 时间为开盘时间）。
  - g. Fundamental 数据以 EndTime 打时间戳（比交易日 +1 天）；请求不存在的数据或起始晚于结束时返回空 → Tier 4。
  - h. 自定义 Python 模型：BuyingPowerModel、SettlementModel 可由 Python 完全替换，缺少必要方法则抛 NotImplementedException；GetUnsettledCash 返回 None 时视为 default → Tier 4。
  - i. RegressionAlgorithms/*.py：Test_CustomDataAlgorithm 指向远程 Dropbox CSV（Research 版本已改为本地副本）；Test_PythonExceptionInterpreter 汇总了常见 Python 错误类型，供异常解释器测试 → Tier 4。

## T34 / L182（Tests 代码清单最后一批）
- 范围：BasicTemplateResearchPython（notebook fixture，结构＋关键字 DATA_AUDITED）、StartTests、ResearchRegressionTests、Symbols.cs、generate_reference_data_from_talib/talipp/tulip.py、TestExtensions/TestGlobals/TestProcess、CoarseUniverseGeneratorProgramTests、ToolBox/LeanDataReaderTests、LeanDataWriterTests、PsychSignalDataTests、RandomDataGenerator/*（11 文件）、ToolBoxTests；全部 FULL_READ。密钥扫描：无新命中。
- **R69**（Tier 4 为主，V1.2 相关处标注）：
  - a ResearchRegressionTests 亦为 golden-master 自动改写；html 与非确定 stdout 被跳过；`Zip` 按较短序列截断，缺失 cell 不会被发现。
  - b tulip 参考数据把前导缺失输出补 0；TA-Lib ATR/BBANDS 作参考值——对照时须排除 warmup 段。
  - c Symbols.cs 中 XAUUSD 为 Oanda CFD（非 FxPro GOLD 规格），V1.2 不可直接沿用其合约属性。【V1.2 相关】
  - d LeanDataWriter 默认写策略：<Hour 分辨率为 Overwrite（按日文件分批写入会覆盖前批），≥Hour 为 Merge；Merge 丢弃同时间戳重复点。研究数据导入须显式指定 WritePolicy。【V1.2 相关】
  - e LeanDataReaderTests 将分钟期货转日线用固定 24h TimeSpan consolidator，非交易时段感知；sumValue 用 double 精确相等比较 decimal 和。
  - f RandomDataGenerator：价格随机游走、Dense/Sparse 仅统计均值断言；DividendSplit 下界公式有测试；生成数据不可作策略验证证据。
  - g TestProcess 45 s 超时；PsychSignal 真实数据测试 Ignore。
