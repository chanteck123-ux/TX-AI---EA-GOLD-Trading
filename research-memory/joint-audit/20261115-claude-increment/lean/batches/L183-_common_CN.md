# LEAN Common 逐文件阅读记录（L183 起）

阅读顺序：Common\Orders → Securities → Brokerages → Data → 其余（共 1,972 个；清单 scratchpad `common_code.txt`）。所有批次先做密钥扫描，凭据值不转录。V1.2 相关处标【V1.2】；其余为 Tier 3/4 记录。

## C01 / L183（第 1–30 个：Orders 前段与 Fees 前段）
- 范围：各券商 OrderProperties（Alpaca/Binance/Bitfinex/BloombergFix/Bybit/CharlesSchwab/ClearStreet/Coinbase/dYdX/Eze）、BrokerageOrderIdChangedEvent、CancelOrderRequest、Combo*Order、Contingency*（Link/Type/Cache/Extensions/Processor）、Fees（Alpaca/AlphaStreams/Axos/Binance*/Bitfinex/Bybit*）。全部 FULL_READ，密钥扫描 0 命中。
- **R70**（待汇总）：
  - a【V1.2】ContingentOrderProcessor（OCO/OTO/OUO）在**引擎侧模拟**：OCO 只要兄弟单有任何部分成交即撤其余；OUO 部分成交时按剩余比例缩减兄弟单数量，并用 `Math.Round(x/lot)*lot`（默认银行家舍入）对齐手数，缩减后数量可能与实际剩余持仓不一致（多或少一手）。若 RiskExecution 以 LEAN 结果推断 SL/TP 括号单的部分成交行为，须注明这不等于 MT5 实际行为（MT5 无原生 OCO，SL/TP 为持仓属性）。
  - b 子单触发时，若为 StopPrice=0 的 TrailingStop，以触发瞬间 `security.Price` 计算止损价（非成交价）。
  - c 父单撤销/无效 → 未触发子单全部撤销；组合单需所有腿 Filled 才触发子单。
  - d TryGetContingentOrders 在成员未到齐时返回 false 并缓存，依赖后续重试；无超时，缺失成员会让整组永久挂起（只记 Debug 日志）。
  - e 费用模型：AlphaStreams 对 CFD 费率 0、Forex 按名义 0.0002%；Binance/Bitfinex/Bybit 只用第一档费率、不建模 30 日成交量；Bybit 卖单以 BidPrice 估值、Binance 买入费以基础币计。对 V1.2 GOLD 成本无直接适用值，FxPro 成本须单独建模。
  - f ComboOrder 的 Quantity 由 GroupOrderManager 比例推导，更新请求改的是整组数量。

## C02 / L184（第 31–60 个：Fees 后段、EquityFillModel、Fix/FTX/GDAX/India 属性、GroupOrder*）
- 全部 FULL_READ，密钥扫描 0 命中。
- **R71**（待汇总）：
  - a（疑似缺陷，PLAUSIBLE）ExanteFeeModel 外汇费 = `0.25m × 订单名义值`，默认值无单位说明；若原意是 0.25%（或每百万 USD 的固定额），则实际高估约 100 倍。仅 Tier 4，V1.2 不使用。
  - b ExanteFeeModel 非美股按 `order.Price` 计费，市价单该值可能为 0。Coinbase/Kraken/Bybit 等只用第一档费率，按 Ask/Bid 估值。
  - c ModifiedFillQuantityOrderFee 直接从报价币现金扣 `费用×成交价×乘数`，绕过一般费用路径。
  - d EquityFillModel（仅 Equity；GOLD CFD 走默认 FillModel，已在 L001 读过）：市价单用最新 Ask/Bid ± 滑点，全部成交；数据过时超过一根 bar 则等待新数据，hour/daily 一律等待。StopMarket 跳空时以开盘价成交；Limit 跳空时以更优开盘价成交；StopLimit 买单按 `min(High, Limit)` 成交，偏保守。全部假设一次性全额成交（TODO：深度限制部分成交未实现）。【V1.2 参考】LEAN 默认不模拟部分成交，RiskExecution 的部分成交和对账逻辑不能用 LEAN 回测来验证。
  - e GetBestEffortAsk/Bid 优先级：报价 tick → QuoteBar → 成交 tick → TradeBar。只订阅 TradeBar 时，买卖都用 Close，等于点差为 0。【V1.2】LEAN 中 GOLD 必须订阅 QuoteBar／报价数据，否则点差成本消失。
  - f GroupOrder：组数量用各腿数量的最大公约数推导；成员未到齐时缓存并无限等待（同 R70d）。

## C03 / L185（第 61–90 个：Orders 订单类型、Contingency、Factory、JSON、OrderSizing 等）
- 全部 FULL_READ，密钥扫描 0 命中。
- **R72**（待汇总）：
  - a【V1.2】`OrderSizing.AdjustByLotSize` 向零截断到手数整数倍，只有差额小于 LotSize/10⁶ 时才进位，用来消除浮点误差。若 LotSize 为 0，`%` 会抛 DivideByZero。RiskExecution 的手数取整（MT5 volume_step 向下取整）可与之对照，但须以 FxPro GOLD 的 volume_min/step/max 为准，不用 LEAN SPDB 的值。
  - b【V1.2】`GetOrderSizeForPercentVolume` 用当前 bar 的 `security.Volume`。CFD/Forex 报价数据的 Volume 通常为 0，因此算出的手数为 0，静默不下单。
  - c `GetOrderSizeForMaximumValue` 的价格为 0 时返回 0，不报错。
  - d OrderJsonConverter：Status 为 null 时视为 Canceled；缺少 TimeInForce 时默认 GTC；缺少 market 时用 SPDB 或默认市场推断，可能映射到错误的市场。这些都是静默容错，日志或结果回读后作对账时需注意。
  - e OrderContingency：OCO/OUO 至少需要 2 个成员，OTO 只能有 1 个父单；合并两个集合时把 link id 平移；期权行权单不能加入。OrderFactory 的组合单要求各腿数量的最大公约数为 1。
  - f `MarketOnCloseOrder.SubmissionTimeBuffer` 是可写的全局静态值（默认 15.5 分钟）。KrakenOrderProperties 的 FeeInBase/FeeInQuote 设 false 时不生效，无法取消。
  - g 限价单估值：买单取 min(限价, 现价)，卖单取 max，这会影响保证金预检。

## C04 / L186（第 91–107 个：Orders 收尾——Serialization、Stop*/TrailingStop、SubmitOrderRequest、TimeInForceJsonConverter、Update*）
- 全部 FULL_READ，密钥扫描 0 命中。Common\Orders 未读部分已完成。
- **R73**（待汇总）：
  - a【V1.2，重要】`SubmitOrderRequest.Bracket()` 默认用 OCO 关联止盈限价单与止损单（父单成交后触发）。结合 R70a，OCO 在**任一兄弟单部分成交时就撤销其余单**：止盈部分成交会撤销止损，剩余持仓失去保护。若要按比例缩减，需显式传入 OneUpdatesOther。RiskExecution 设计（MT5 端 SL/TP 为持仓属性，部分平仓由 EA 处理）不应以 LEAN 的 Bracket 行为为依据；LEAN 研究端若使用 Bracket，应选 OUO，并在报告中注明。
  - b 止损单估值：买入止损取 min(Stop, 现价)，卖出止损取 max。止损买单实际在高于现价处成交，所以预检的订单价值偏低，保证金预检偏乐观。
  - c TrailingStop：只有在距离大于追踪幅度时才上调止损；百分比模式以 `现价×(1±幅度)` 计算；不考虑点差与 tick 取整。
  - d TimeInForceJsonConverter 读 JSON 里的 `$type`，用 `Type.GetType` 加反射无参构造实例化任意类型，再按名称写入属性。这是 JSON 反序列化面的类型注入风险，属 Tier 4，只在解析不可信 JSON 时相关；V1.2 不解析外部订单 JSON。
  - e `UpdateOrderRequest.IsAllowedForClosedOrder` 用了非短路的 `&`（结果正确，仅风格问题）。SerializedOrderEvent 的 Id 由 algorithmId、orderId、eventId 拼接；fee 币种为 NullCurrency 时不输出 fee 字段。

## C05 / L187（第 108–137 个：Securities 前段——结算、BuyingPower 扩展、CashBuyingPower、合约筛选、Crypto/CryptoFuture、货币换算）
- 全部 FULL_READ，密钥扫描 0 命中。
- **R74**（待汇总）：
  - a【V1.2】BrokerageModelSecurityInitializer 先设 BuyingPowerModel，再用 `brokerageModel.GetLeverage(security)` 设杠杆。LEAN 研究端若要模拟 1:1000，须在初始化器之后显式 SetLeverage，并核对所选 BrokerageModel 对 CFD 的默认杠杆（例如 Oanda 模型）；不能假设已经是 1:1000。这与 AGENTS.md 中"LEAN 保证金模型与 MT5 GOLD 保证金规则分别核验"的要求一致。
  - b【V1.2】SecurityCurrencyConversion 以各换算腿 `lastData.Price` 连乘（QuoteBar 为中间价，不区分买卖价）；任一腿缺数据时汇率为 0，所有以账户货币计的价值和保证金也随之为 0，且不报错。USD 账户交易 GOLD(USD) 时汇率为 1，不受影响；若账户货币不是 USD 则需注意。寻找换算路径时取第一个匹配的货币对（一腿或两腿）。
  - c `AboveMinimumOrderMarginPortfolioPercentage`：剩余保证金 ≤0 时一律放行，目的是让减仓单通过；但加仓单在这种情况下也会放行，最终依赖后续的保证金检查拦截。
  - d ConstantBuyingPowerModel 的初始保证金用带符号的 Quantity，维持保证金用绝对值；空单的初始保证金为负，是否出问题取决于调用方有没有取绝对值（PLAUSIBLE，Tier 4）。
  - e CashBuyingPowerModel（仅现货 crypto）：按 `% LotSize` 取整，LotSize 为 0 时除零；收敛循环每次至少减 1 个 LotSize，不收敛时抛异常；计算预留数量时，OCO 同组只计最大的一单。
  - f CryptoFuture：维持保证金等于初始保证金；资金费按 UTC 0/8/16 时结算，采用当时的资金费率；币本位与 U 本位的名义价值公式不同。Tier 4。

## C06 / L188（第 138–167 个：DelayedSettlement、DynamicSecurityData、Equity/*、Func*、Future/*（含 Futures 常量表 1,858 行、FuturesExpiryFunctions 3,639 行））
- 全部 FULL_READ，密钥扫描 0 命中。FuturesExpiryFunctions 是重复度很高的表：先用脚本核对每个条目内的 symbol/market/holiday 是否与键一致，再逐段读完全部内容（去掉空括号行后约 2,070 行）。
- **R75**（待汇总）：
  - a（确认缺陷，Tier 4）`FuturesListings` 中 `"ZN"` 的上市规则用的是 `_zt`（2 年期国债，ZT）的 Symbol，ZN 生成的合约代码会变成 ZT。
  - b（确认缺陷，Tier 4）`FuturesExpiryFunctions` 中 MicroSingaporeFuelOil380CSTPlatts 条目的 `var symbol` 是 MicroEuropeanThreePointFivePercentOilBargesFOBRdamPlatts（复制粘贴错误），因此用了另一合约的假日表。脚本核对全部 433 处引用，只发现这 1 处不一致。
  - c 到期时间写法不统一：多数条目附带时刻，UltraTenYear、MicroAUD、MicroCADUSD、FTSE100EMini 等只返回日期（00:00）。GC 黄金按"合约月倒数第 3 个营业日"计算，符合 COMEX 规则；MicroGold 限 GJMQVZ 月份。V1.2 交易 GOLD CFD，不受影响；NR07 若使用 GC 期货数据作参考，应按连续合约的换月规则处理。
  - d【V1.2 参考】FutureMarginModel：找不到保证金 CSV 时只写 Log.Error，并**按 0 保证金**继续；`_marginCurrentIndex` 只会向前移动，时间回退（历史/预热复用）时不会重新定位；静态缓存每天用 Task.Delay 递归清空。这些都是静默降级，属于"保证金为 0"类风险，研究端对照 MT5 时须核对保证金不为 0。
  - e FutureSettlementModel 每日按结算价进行逐日盯市，losers pay winners；FutureSymbol.IsStandard 出异常时归为标准合约（只写 Log.Error）；NthLastBusinessDay 内有重复的假日判断。
  - f DelayedSettlementModel：卖出所得在 T+N 交易日的指定时刻才计入已结算现金；买入立即扣款。ShortMarginInterestRateModel 按 /360 每日计息。Equity 默认 2 倍杠杆，使用 IB 费率模型。

## C07 / L189（第 168–197 个：MarginRequirementsEntry、FutureOption/*、BuyingPower 参数/结果类、I* 接口、MarginCallModel.Null）
- 全部 FULL_READ，密钥扫描 0 命中。
- **R76**（待汇总）：
  - a【V1.2 参考】MarginRequirementsEntry 解析失败时只写 Log.Trace，对应字段保持 0（日期为 MinValue），保证金静默变为 0。`decimal.TryParse` 没有指定 InvariantCulture，依赖进程区域设置；LEAN 通常在启动时设为 Invariant，但这里仍是潜在的区域设置风险（PLAUSIBLE）。日内保证金缺省为隔夜保证金的 40%。
  - b FuturesOptionsMarginModel 用指数曲线近似期权保证金（不是交易所 SPAN），结果截断为 int。标的价格为 0 时注释写"返回标的保证金"，代码实际返回 0，注释与代码不符，属静默的 0 保证金。
  - c `MarginCallModel.Null` 不产生任何追加保证金/强平单。【V1.2】研究端若使用 Null 模型，就没有 Stop Out 模拟；AGENTS.md 要求 Stop Out 另行核对，与此一致。
  - d FuturesOptionsUnderlyingMapper：GC 期权对应偶数月期货；找不到下一个合约时返回 null。FuturesOptionsExpiryFunctions 没有定义的品种回退到期货到期规则。CME 行权价缩放因子：SI 为 0.1，NG 为 5。
  - e `GetMaximumOrderQuantityResult(quantity, reason)` 只要 reason 非空就视为错误，提示性 reason 需要使用三参数构造函数。

## C08 / L190（第 198–227 个：ImmediateSettlement、Index/*、IndexOption/*、InitialMargin*、I* 接口、MaintenanceMargin*、MarginCallOrdersParameters）
- 全部 FULL_READ，密钥扫描 0 命中。
- **R77**（待汇总）：
  - a【V1.2 参考】各交易所类的 `TradingDaysPerYear` 不同：Equity 和 Future 为 252，Index 为 313（"365 减去周六"）。LEAN 用这个值做年化统计（Sharpe 等）。按 AGENTS.md / 计划 §11.1，计算 Sharpe 前须先核对频率和年化口径；CFD/Forex 的取值留待读 SecurityExchange 基类和 Cfd/Forex 类时确认。
  - b `SecuritySeeder.Null.SeedSecurity` 恒返回 true，即没有种子数据也报告"已播种"；`SecurityInitializer.Null` 不做任何初始化（不设置手续费、滑点、保证金模型）。
  - c Index 默认不可交易，使用 50 倍 SecurityMarginModel，手续费为 0；IndexOption 的最小价位随价格分档（≥3 时 0.1，否则 0.05；VIX/VIXW 另有规则）。
  - d `MaintenanceMarginParameters.ForQuantityAtCurrentPrice` 把持仓成本和持仓价值都设为当前市值。InitialMargin、MaintenanceMargin 与 decimal 之间可以隐式互转，代码里看不出单位。

## C09 / L191（第 228–257 个：MarketHoursState、NullBuyingPowerModel、Option/* 含 Option.cs 691 行、OptionFilterUniverse 1,522 行、OptionMarginModel、OptionPortfolioModel）
- 全部 FULL_READ，密钥扫描 0 命中。基本属 Tier 4（期权）。
- **R78**（待汇总）：
  - a【V1.2】`NullBuyingPowerModel`：维持保证金恒为 0，`HasSufficientBuyingPower` 恒为 Sufficient。研究端一旦误用，就完全没有保证金约束，回测结果无效。RiskExecution 对照时须确认 LEAN 端使用的保证金模型类型并留证。
  - b OptionMarginModel：多头只需付权利金（初始与维持保证金都为 0）；空头用近似公式（裸卖 10%，OTM 时权益类 20%、指数 15%）；任一价格为 0 时返回 0 保证金（静默）。期权不可设置杠杆。
  - c DefaultOptionAssignmentModel 只在到期前 4 天内、深度实值 >5% 并且估算套利盈利 >0 时模拟提前指派。FedRate 无风险利率在 slice 为空时取默认值。ConstantQLRiskFreeRate 默认 1%。
  - d OptionFilterUniverse 的策略筛选（价差、蝶式、铁鹰等）以"最接近 ATM 的行权价"为准，找不到时用 decimal.MaxValue 作哨兵值，最后靠"结果合约数 ≠ 预期"返回空集合。`Strikes()` 每日按二分查找重建行权价列表。`DefaultAtTheMoneyStrikeDistance` 是可写的全局静态值（2%）。
  - e 现金交割期权行权时，按标的 Close 计算内在价值入账（不是结算价）。

## C10 / L192（第 258–287 个：OptionPriceModel*、OptionStrategies 1,227 行、OptionStrategyPositionGroupBuyingPowerModel 682 行、OptionSymbol、QLOptionPriceModel、StrategyMatcher/* 共 19 个文件）
- 全部 FULL_READ，密钥扫描 0 命中。全部属 Tier 4（期权组合保证金与策略匹配）。
- **R79**（待汇总，均为 Tier 4）：
  - a（确认缺陷）`OptionStrategyDefinitionMatch.Equals` 用 `other.Legs` 建字典后又遍历 `other.Legs` 比较，实际上是 other 和自身比较，`this.Legs` 完全没有参与。因此只要 Definition 相同就判为相等。`Match(...).Distinct()` 先比较哈希，影响通常被掩盖，但哈希碰撞时会误删不同的匹配。
  - b（疑似缺陷，PLAUSIBLE）`OptionPositionCollection.Add`：合并后数量变为 0 时，从 `sides[position.Side]`（此时为 None）移除，而原先的 Long/Short 索引不会清除；多空翻转时也不会更新 sides 索引（exists=true 分支跳过）。结果是 sides 索引残留，`Validate()` 不检查 sides。
  - c `AbsoluteRiskOptionPositionCollectionEnumerator` 在末尾抛出 NotImplementedException（未完成的实现）。
  - d 组合保证金（IB 风格）大量使用硬编码的经验系数：CoveredCall 初始保证金为"期权价值×0.8 + 股票保证金"（注释说明这是由测试反推的）；ShortBoxSpread 按 0.65/合约且最低 1 美元×4 估算手续费。未实现的策略直接抛 NotImplementedException。
  - e QLOptionPriceModel：IV 求解失败时退回 Newton-Raphson（10 次迭代，不收敛返回 0）；任何异常都返回 `OptionPriceModelResult.None`（只写 Debug 日志）；希腊值计算失败时用 BlackCalculator 近似；使用 UnitedStates 日历和 Actual365Fixed；全局 QL `Settings.evaluationDate` 是进程级共享状态，存在并发风险。
  - f `OptionPriceModels.QuantLib.Create(name)` 在所有已加载程序集中，按类型全名后缀反射查找定价引擎，名称重复时取第一个匹配。

## C11 / L193（第 288–317 个：StrategyMatcher 收尾、OptionInitialMargin、PatternDayTradingMarginModel、Positions/* 前段）
- 全部 FULL_READ，密钥扫描 0 命中。
- **R80**（待汇总）：
  - a【V1.2 参考】`PositionGroupBuyingPowerModel.HasSufficientBuyingPowerForOrder` 是 LEAN 默认组合保证金检查的骨架，单一证券也走这条路径。流程是：先算拟议订单使"已预留保证金"增加多少（delta 按"拟议组的初始保证金减去当前组的维持保证金"计算）；**delta<0 时一律放行**（视为减仓）；否则要求 delta ≤ MarginRemaining。这与 MT5 的检查口径不同：MT5 按 Free Margin 和 margin level（Margin Call / Stop Out 百分比）判断。RiskExecution 不能把 LEAN 通过的保证金检查等同于 FxPro 可以下单，两边须分别核验，这一点 AGENTS.md 已有要求。
  - b `GetMaximumLotsForTargetBuyingPower` 用逐个单位步进的迭代求解（每步重算初始保证金和费用），不收敛时抛 ArgumentException；单位保证金为 0 时返回错误，原因是缺少价格。
  - c `PortfolioState.Create` 捕获所有异常后返回 null（只写 Log.Error），保证金图表因此静默缺一段。PortfolioMarginChart 只显示前 40 个系列，其余合并为 OTHERS。
  - d `PositionGroupCollection.Add`/`CombineWith` 直接修改调用方自身并返回 this（可变别名），而 `Empty` 每次新建，使用时须留意共享引用。
  - e PatternDayTradingMarginModel：开盘时用 4 倍杠杆，收盘或临近收盘时按 2 倍修正。OptionStrategyMatcher 先按腿数优先贪心匹配，再试"有保护的空头优先"，按未覆盖空头数量评分取较优的方案；`Covers` 允许多头行权价偏离空头行权价最多 10%。

## C12 / L194（第 318–347 个：Positions 后段（含 readme.md）、Security.cs 1,241 行、SecurityCache 666 行、SecurityCacheProvider、SecurityDatabaseKey、SecurityDefinition*、SecurityExchange 等）
- 全部 FULL_READ，密钥扫描 0 命中。readme.md 有超长行，已单独完整读过，未截断。
- **R81**（待汇总）：
  - a【V1.2】`SecurityExchange.TradingDaysPerYear` 基类默认 365，Equity/Future/Option 改为 252，Index 改为 313（续 R77a）。CFD/Forex 是否覆盖，留待读到 Cfd/Forex 类时确认。年化统计的口径取决于这个值。
  - b【V1.2】`Security.BidPrice/AskPrice` 在缓存值为 0 时回退为 `Price`（QuoteBar 的 Close 即中间价），因此点差静默为 0（同 R71e）。报价 tick 只在 Bid/Ask **非零**时更新对应一侧，只有一侧报价时另一侧会长期滞留旧值。
  - c【V1.2】SecurityCache：fill-forward 数据不进缓存，也不更新 Price；同一 EndTime 下 QuoteBar 优先于 TradeBar；OHLC 只用默认数据类型更新。因此在数据缺口或周末期间，Price 是最后一个真实数据点，持仓估值用的也是这个滞后价格。
  - d `Security.SetLeverage` 对期货和期权直接静默返回，不报错。`ClosingSoon` 固定为收盘前 10 分钟。股息调整时价格最低截断为 0。
  - e 默认（单证券）组的保证金检查：`SecurityPositionGroupBuyingPowerModel` 先委托给 `security.BuyingPowerModel.HasSufficientBuyingPowerForOrder`（只在全部是默认组时执行），再做组级别的 delta 检查（见 R80a），两道检查都通过才放行。
  - f Positions/readme.md 写着"期权解析器尚未实现"，但代码里 OptionStrategyPositionGroupResolver 已经实现，文档已过时。SecurityDefinitionSymbolResolver 读不到 security-database.csv 时只写 Log.Error，返回空列表（静默）。

## C13 / L195（第 348–377 个：SecurityManager、SecurityService、UniverseManager、Volatility/*、Brokerages 前段 Alpaca–Coinbase 及 BrokerageExtensions/Name/Message*）
- 全部 FULL_READ，密钥扫描 0 命中（Binance/BinanceUS 的 BaseApiEndpoint 是公开 API 地址，不是凭据）。Common\Securities 中未读的部分已全部读完。
- **R82**（待汇总）：
  - a【V1.2】SecurityService.CreateSecurity 的顺序是：初始化器 → 播种 → 若传入 `leverage` 参数则覆盖。若 CashBook 里还没有报价货币，就以汇率 0 加入，在有换算数据之前，以账户货币计的价值都是 0（续 R74b）。CFD 不建立基础货币现金；Forex 的报价货币取 Symbol 第 4 位起的子串。
  - b（疑似问题，PLAUSIBLE）`StandardDeviationOfReturnsVolatilityModel` 不论 resolution 是什么，一律用 `std × √252` 年化。分钟或小时收益率乘以 √252 并不是正确的年化，年化尺度会被低估约 √(每日 bar 数) 倍。默认窗口为：分钟 1,440 期，小时 720 期，日线 30 期。【V1.2】DR01 或波动率仓位若参考 LEAN 的 VolatilityModel，必须先核对频率与年化口径，与计划 §11.1 对 Sharpe 年化的要求同理。
  - c RelativeStandardDeviationVolatilityModel 返回的是变异系数（标准差/均值），不是收益率波动。窗口少于 2 个点时返回 0。
  - d BrokerageExtensions：MOO/MOC 订单跨零（反手）时被拒；`GetOrderPosition` 把持仓为 0 时的买单视为 BuyToOpen；`ValidateContingentOrder` 统一检查支持的类型、嵌套、跨品种和最大数量。AlphaStreams 模型给 Forex/CFD 的杠杆为 10。
  - e 各券商最小下单量判断不一致：Binance 用名义值 `>` MinimumOrderSize（严格大于），Bybit/Coinbase 用数量 `>=`。Coinbase 自 2019-03-23 起拒绝 StopMarket。属 Tier 4。

## C14 / L196（第 378–406 个：Brokerages 收尾——DefaultBrokerageMessageHandler、Downgrade*、IBrokerageModel（含 Create/GetBrokerageName）、FXCM/Kraken/Tradier/TradeStation 等 22 个券商模型）
- 全部 FULL_READ，密钥扫描 0 命中。Common\Brokerages 中未读的部分已全部读完。
- **R83**（待汇总）：
  - a【V1.2 参考】`DefaultBrokerageMessageHandler`：收到 Error 消息就 SetRuntimeError，算法停止；断线后若 5 分钟内有交易所开盘，等 15 分钟仍未重连就停止；若都休市，则在下次开盘前 5 分钟再检查。ActionRequired 也会直接停止。这是 LEAN 实盘端"断线即停机"的策略，与 V1.2 的 MT5 RiskExecution 要求不同：后者断线时必须先保持已有仓位保护和对账，再决定是否暂停新增风险，不能照搬 LEAN 的这套逻辑。`DowngradeErrorCodeToWarning` 可以把指定错误码降级为警告。
  - b【V1.2 参考】FxcmBrokerageModel（外汇/CFD）：数量必须是 LotSize 的整数倍；用 `security.Price`（中间价）校验限价/止损的方向（买入限价不得高于现价等）；最大挂单距离为 min(15,000 pips, 50% 价格)；只支持 GTC；CFD 使用账户货币即时结算。MT5 的检查口径不同，看的是 stops level / freeze level 和 Bid/Ask，RiskExecution 应以 FxPro 的实际限制为准。
  - c 部分券商模型的 CanSubmitOrder 在自身检查通过后直接 `return true`，**跳过** `base.CanSubmitOrder`（DefaultBrokerageModel 的通用检查）：dYdX、Samco、Zerodha、Tradier、FXCM、Exante、TradingTechnologies。属 Tier 4，但说明各券商模型的检查覆盖面不一致。
  - d Exante 的 SecurityType 检查重复列了两次 Index；`order.Price == 0` 时拒单。Kraken 按币种查表给杠杆（2–5 倍）。Tradier 遇到反向拆股会撤销全部挂单。Webull 的期权卖单只允许 Day。TradeStation 的 OUO 括号单要求有止损腿并且是同一品种。
  - e `BrokerageModel.GetBrokerageName` 依赖 switch 分支的顺序处理继承关系（子类必须排在父类前面），新增模型时容易出错。

## F01（Common\Data\Fundamental 中的 9 个手写文件）
- AssetClassificationHelper、FineFundamental、Fundamental、FundamentalInstanceProvider、FundamentalTimeDependentProperty、FundamentalUniverse、MultiPeriodField、Period：均已 FULL_READ。
- FundamentalProperty.cs（4,223 行）是纯 enum，共 4,195 个成员。已用脚本确认除命名空间、属性和 pragma 外每行都是单个成员，且没有重复成员（`uniq -d` 为空），记为 FULL_READ，方法为结构化核对加全量去重。
- 密钥扫描 0 命中。全部属 Tier 4（美股基本面），V1.2 的 GOLD CFD 不使用。
- **R84**（待汇总，Tier 4）：
  - a `MorningstarIndustryGroupCode` 与 `MorningstarIndustryCode` 中，Furnishings 和 FixturesAndAppliances 是**同一个值**（10220 和 10220010），属于别名重复，两者无法区分。
  - b FundamentalInstanceProvider 有一个按 SecurityIdentifier 建的静态缓存，永不清除；每个实例共用一个可变的 `_timeProvider.Time`，先改时间再返回同一个对象，多线程下取值非线程安全。
  - c `Fundamental.Reader` 与 `FundamentalUniverse.Reader` 捕获全部异常后返回 null，坏行被静默丢弃。基本面数据在 T 日的值要到 T+1 才可用（代码注释说明了这一点，防止前视偏差）。
  - d MultiPeriodField 的运算符把 double 转为 decimal，遇到 NaN 或 Infinity 会抛出异常。PeriodAsByte 用 121 表示 OneYear，以区别于 TwelveMonths 的 12。

## D01（Common\Data 非 Fundamental 部分第 1–30 个：Auxiliary/*（因子文件、映射文件、成交/报价条件 Flags）、BaseData、BaseDataRequest、Channel、Consolidators 前 3 个）
- 全部 FULL_READ，密钥扫描 0 命中。
- **R85**（待汇总）：
  - a（安全面，Tier 4）`BaseData.DeserializeMessage` 使用 `TypeNameHandling.All`。Newtonsoft 的这个设置在处理不可信 JSON 时是已知的类型注入面，与 R73d 同类。V1.2 不使用 LEAN 实时消息反序列化，但若将来接入外部数据推送需留意。
  - b CorporateFactorRow 解析时**静默跳过**含 "inf" 或 "e+" 的因子行，以及 PriceScaleFactor≤0 的行；SafeRead、MapFileZipHelper.SafeRead、MapFile.SafeMapFileRowRead 遇到异常都返回空文件（只写日志）。缺少因子文件时价格调整按 1，等同于未调整，也是静默的。
  - c `GetDividend/GetSplit` 的变量名是 previousTradingDay，实际调用的却是 `GetNextTradingDay`，命名与行为不一致（行为可能正确，但容易误读）。LocalZip* 提供器每天在辅助数据到期前 10 分钟清空缓存；回溯查找因子文件最多 7 天（超过就抛异常），映射文件最多 30 天。
  - d【V1.2 参考】BaseDataRequest 对 OpenInterest 改用全天开放的交易时段。`BaseData.IsSparseData` 默认只有自定义数据为 true。Calendar.Weekly 以 `Expiry.EndOfWeek - 7` 作为周起点，周线 K 线的切分取决于 EndOfWeek 的定义（留待读 Expiry 时确认）；如果 LEAN 端用 Calendar 周期聚合 GOLD，须与 MT5 的 W1 起点（FxPro 服务器时区）对齐。
  - e BaseTimelessConsolidator 默认用 TradeBar.Volume 或 Tick.Quantity 作成交量；QuoteBar 和 CFD 报价数据的成交量为 0，所以基于成交量的无时间轴 K 线（Volume/Renko 等）对 GOLD 报价数据不适用。

## D02（Common\Data 第 31–60 个：Consolidators 全部 23 个、ConsolidatorWrapper、Constant*Model、Custom/FxcmVolume、IndexedLinkedData*）
- 全部 FULL_READ，密钥扫描 0 命中。FxcmVolume 中的 `sid="quantconnect"` 是公开的接入标识，不是凭据。
- **R86**（待汇总，**V1.2 重点**）：
  - a【V1.2 · S7 相关】`QuoteBarConsolidator` 与 `TickQuoteBarConsolidator` 每开一根新 K 线，都先把**上一根 K 线的 Bid/Ask 收盘价**写入作为新 K 线的开盘价（注释说明：fill forward previous close）。合成 M5 QuoteBar 时，Open 等于上一根的 Close，不是本根第一个报价。MT5 的 M5 Open 是本根第一个 tick 的 Bid，跨缺口（开盘、跳空、周末）时两者差别明显。S7（反转收盘 K 线确认）和任何用到 Open 的形态判断，在 LEAN 与 MT5 之间会因此出现系统性差异。跨引擎核对必须逐根比对 OHLC，或者 LEAN 端改用 tick 直接聚合并自定义开盘规则。
  - b【V1.2】PeriodCountConsolidatorBase 的时间模式：起点用 `time.RoundDown(period)`，以数据所在时区计；M5 按整 5 分钟对齐。只要服务器时区偏移是整小时，就与 MT5 一致。如果输入数据周期大于目标周期（例如用 H1 合成 M5），会直接抛异常。一根 K 线只有在下一条数据到达、或 Scan 时间超过 period 时才发出；ConsolidatorWrapper 按 K 线跨度推进 Scan 时间，缺数据时也会推进。
  - c【V1.2】MarketHourAwareConsolidator 在非扩展时段时，**丢弃交易所关闭时段的数据**；日线是否严格收盘取决于 `LeanData.UseStrictEndTime`。GOLD CFD 的 LEAN 交易时段（MHDB）若与 FxPro 服务器时段不一致，日线和 H4 的切分就会不同（续 R64e、R68 的日期问题）。
  - d BaseDataConsolidator、TradeBarConsolidator 在新 K 线上直接用第一条数据的 Open，与 QuoteBarConsolidator 的行为**不一致**（a 中的回填只发生在 Quote 路径）。同一个策略改用 TradeBar 或 QuoteBar 输入，开盘价口径就会变。
  - e Renko/Range/VolumeRenko：首个 K 线的价位按 BarSize 或最小价位取整；VolumeRenko 只接受 TradeBar 或交易 tick（报价数据会抛异常或被忽略）；RangeConsolidator 跳空时会生成成交量为 0 的"幻影"K 线。SessionConsolidator 只累计开盘时段内的数据。
  - f（缺陷，Tier 4）FxcmVolume 的 `_baseUrl` 字符串开头多了一个空格，并且使用明文 http。

## D03（Common\Data 第 61–90 个：IconicTypes、Intrinio/*、Tiingo/*、NullData、DataHistory、DataMonitor、DataQueueHandlerSubscriptionManager、DiskDataCacheProvider、DividendYieldProvider、DownloaderExtensions、DynamicData、History*、IBaseData、IDataAggregator 等）
- 全部 FULL_READ。密钥扫描命中 1 处，经核实是**误报**：TiingoPrice 第 156 行的 URL 用变量插值 `token={Tiingo.AuthCode}`，不含字面凭据。
- **R87**（待汇总，均为 Tier 4）：
  - a（安全面）TiingoPrice 把 AuthCode 放在 **URL 查询串**（`&token=`）里；作为 RemoteFile 来源，URL 可能被 DataMonitor 或日志记录下来，造成凭据外泄。IntrinioConfig 把用户名和密码存放在**可公开读写的静态字段**里。
  - b（缺陷）IntrinioEconomicData 生成的认证头是 `Basic ({base64})`，Base64 外面**多了一对括号**，不符合 RFC 7617，服务端很可能拒绝认证。
  - c DynamicData：`HasProperty` 只查 `_storage`，没有查 snake_case 存储，与 `GetProperty` 不一致；`Clone` 只复制 `_storage`，snake 名称的存储会丢失。
  - d DividendYieldProvider：相邻两行因子中，PriceFactor 不同就判为分红，**否则一律判为拆股**（包括拆股因子为 1 的无事件行）；结果影响不大，但事件列表里会混入"空拆股"。另外用 350 天作为近一年的分红窗口；静态缓存每天清空。
  - e DataQueueHandlerSubscriptionManager 的引用计数用 TryGetValue 加 TryUpdate，不是原子操作，并发订阅时计数可能丢失；DiskDataCacheProvider 遇到损坏的 zip 只写日志并返回 null。HistoryRequest 对 Tick 不做 fill-forward；Hour 及以上周期不包含扩展时段。

## F02 / L201 (R88) Fundamental Generated 970 个文件 — DIFF_VERIFIED

- 方法：不是逐字 FULL_READ。先归一化（类名→CLS、FundamentalProperty.*→FP、字符串字面量→STR）得 82 个模板簇；基准模板 AmortizationSupplementalIncomeStatement 全读，其余簇逐一读与基准的差异（期间集合、已退役字段 `throw new NotSupportedException` 变体、DateTime/string/long 类型）。工具：tools/fundnorm2.sh、tools/fundsem.awk。
- 逐文件语义检查（全部 970）：属性名↔FP期间后缀；JsonProperty标签↔属性；元组标签↔属性；HasValue期间=DefaultPeriod；GetPeriodValue 的 Enum.Parse 前缀=文件前缀。
- **确认缺陷（3 个）**：CashFlowfromFinancingGrowth.cs、CashFlowfromInvestingGrowth.cs、DebttoAssets.cs 在 GetPeriodValue 中拼出 `OperationRatios_DebttoAssets` 等小写 t 形式，而 FundamentalProperty 枚举为 `..._DebtToAssets` 等；`Enum.Parse<T>` 区分大小写 → 调用即抛异常。属性直接访问不受影响。
- 899 个单前缀文件前缀↔类名一致；16 个合法缩写变体（如 BalanceSheetFileDate→BSFileDate）。
- 聚合类结构核对：BalanceSheet 322、IncomeStatement 223、CashFlowStatement 217、OperationRatios 110、EarningReports 39、FinancialStatements 37、EarningRatios 12 的属性/字段/类型一致，无重复 JSON 编码；ValuationRatios 164、CompanyProfile 36、CompanyReference 25、SecurityReference 26、AssetClassification 19 标量 FP 名一致。
- 249 个文件含退役字段，Obsolete 标记一致；完全退役字段 Value 抛 NotSupportedException；退役属性不出现在任何 GetPeriodValues 元组中。
- V1.2 关联：无（股票基本面；XAUUSD 不用）。Tier 4。

## D04 / L202 (R89) Common\Data 第 91–123 个（LeanDataWriter、Market\Bar…OptionChain.Filters）

- R89a（V1.2 跨引擎）：Bar.Update 忽略值为 0 的价格；Bar(open,…) 以 open!=0 判断 Open 是否已设。即 0 价不进入 OHLC。对 GOLD 无实际影响，但与 MT5 的柱口径不同，记录备查。
- R89b：LeanDataWriter 写入策略在 Hour 以下分辨率默认 Overwrite（与 T34 中的结论一致）；Write 只在日期变化时切换文件，要求输入按时间排序，否则抛异常；DownloadAndSave 直接修改 history 对象的 Time（从交易所时区转换为数据时区）；Append 模式不做去重。用 LEAN 生成或转换 GOLD 数据时，必须写明 WritePolicy 并检查时区（V1.2 数据流程）。
- R89c：FuturesContract 只要存在 universe 数据，Bid＝Ask＝LastPrice＝universe Close，价差为 0，且优先于更新的实时 bar/tick（会读到过期价格）；BidSize/AskSize 则不使用 universe 数据，口径不一致。Tier 4（期货）。
- R89d：BaseChain 的复制构造函数是浅拷贝，Ticks/TradeBars/QuoteBars/AuxiliaryData 为共享引用，过滤后的链与原链共享可变集合。Delisting.Clone 会丢失 Ticket。
- R89e：Greeks.ThetaPerDay 按 365 个日历日换算；IndicatorHistory 按名称去重时用 ToLowerInvariant，作为键时用 ToSnakeCase，两者口径略有不同（大小写名称冲突时以首个为准）。
- DataDictionary 的排序缓存在写入时清空，但非线程安全。MarginInterestRate 数据为 UTC。其余文件为接口、集合或过滤器的薄封装，未发现问题。

## D05 / L203 (R90) Common\Data 第 124–156 个（OptionChains…Tick、TradeBar、Slice、SubscriptionDataConfig/Manager、UniverseSelection 前 4 个）

- **R90a（V1.2 重点，跨引擎）SessionBar 的 Quote 口径**：报价数据源（FX/CFD 即 GOLD 属于此类）的新交易日 SessionBar 在 InitializeBar 中用上一交易日的 Bid/Ask Close 初始化，之后只更新 Close/High/Low，因此日内 Session 的 Open＝前一日 Close，High/Low 也包含前一日 Close。MT5 D1 的 Open 是当日首个 tick。与 R86a（QuoteBar 合成器的 Open）属同一口径差异，日线、会话级参考位必须单独核对。
- **R90b（V1.2 重点）Slice/PushThrough 只取最后一个 tick**：`Slice.Get<Tick>()` 每个 symbol 只返回最后一个 tick；`SliceExtensions.Get(...field)` 中对 `List<Tick>` 取 Last，代码注释明言 "known bug"；`PushThrough`／`PushThroughConsolidators` 在 Tick 类型及默认路径下每个 slice 每个 symbol 只推送最后一个 tick。用 tick 历史经这些扩展方法合成 M5 时，同一 slice 内的其他 tick 会丢失，High/Low 可能偏小。实际影响取决于同时间戳 tick 的分组，未实测，判定为 PLAUSIBLE。需直接遍历 `slice.Ticks[symbol]` 全量列表。
- R90c：TradeBar.Reader 解析失败时只记 Log.Error，然后返回 OHLC 全为 0 的默认 TradeBar（Symbol/Period 已设），而不是 null。下游是否过滤尚未在本批核对，列入待查（Engine 部分已读，Codex 汇总时一并确认）。Tick 构造函数的异常同样只记日志，返回半初始化对象。
- R90d：`Tick(Symbol, string line)` 构造函数先算 `Value=(BidPrice+AskPrice)/2`，再赋值 Bid/Ask，所以 Value 恒为 0，确认为缺陷；仓库内无调用者（遗留 API）。`Tick.IsValid()` 要求报价 tick 的 BidSize 或 AskSize 大于 0，而 FX/CFD tick 文件中无 size 字段，按此判定会全部无效；仓库内无调用者，外部 brokerage 插件可能调用，PLAUSIBLE。
- R90e：FX/CFD tick 格式为「毫秒,bid,ask」，无 size；TradeBar 格式中 CFD 与 Forex 相同（无成交量、不缩放）；`SetValue` 在一侧为 0 时 Value 取另一侧。`Clone(fillForward)` 会把成交量清零。
- R90f：`Slice.MergeSlice` 把本方数据追加到对方的 AllData 列表中，会修改传入的 slice；`UpdateCollection` 在本方为空时直接复用对方集合的引用（别名）。`OptionUniverseData` 中 Bid＝Ask＝Close。RangeBar 触发关闭时直接 return，该次 volume 未累加，且忽略跳空。
- R90g：SubscriptionManager.AddConsolidator 只挂到第一个类型匹配的订阅上；ScanPastConsolidators 扫描前会把 algorithm 时间设为扫描时间。DefaultDataTypes 中 CFD 只有 Quote（与 V1.2 GOLD 一致）。BaseFundamentalDataProvider.IsNone 把 decimal 0 视为缺失（Tier 4）。LocalDiskShortableProvider 缺少数据时视为可无限做空、费率为 0（Tier 4）。

## D06 / L204 (R91) Common\Data\UniverseSelection 第 157–189 个

- 总体为 Tier 4（V1.2 只交易单一 GOLD CFD，经 UserDefinedUniverse/AddCfd 加入，不使用选股型 universe）。
- R91a：CoarseFundamentalDataProvider.GetProperty 中 `HasFundamentalData` 分支固定返回 false，忽略了已解析的字段（PLAUSIBLE 缺陷）；按 `time==_date` 缓存（键为时间而非日期）；Read 解析失败时静默返回 null。
- R91b：OptionChainUniverse.AddMember 在发现同一 Security 对象已存在时按新 symbol 执行 TryRemove，但该键此前已确认不存在，移除为空操作，旧键留存，导致同一 Security 可能出现两个成员条目（PLAUSIBLE，期权调整场景，Tier 4）。
- R91c：ScheduledUniverse.SelectSymbols 把 UTC 时间改为 Unspecified 后传给选择器，即使构造时指定了非 UTC 时区，选择器拿到的仍是 UTC 数值（易误用）。ConstituentsUniverseData 在实盘时日期减 1；其 GetSource 用 MappedSymbol 的索引去截取 ID.Symbol（两者相同时才正确）。
- R91d：UserDefinedUniverse.GetTriggerTimes 的第一个触发点无论市场是否开盘都会发出；Remove 后保留 pending 配置，供同一时间步内重新添加时复用（订阅不中断）。Universe.CanRemoveMember 按 MinimumTimeInUniverse 取整判断；被摘牌的证券可随时移除。
- R91e：FutureUniverse/OptionUniverse 的符号缓存满 10 万／50 万条时整体清空；OptionUniverse 的 Theta 读取 ThetaPerDay 后乘 365。DerivativeUniverseData 已有报价价格时，TradeBar 只更新成交量（报价优先）。SecurityChanges 合并时，若某证券又被重新加入，则剔除其移除记录。

## C15 / L205 (R92) 其他 Common 第 1–24 个（Framework Alphas/Portfolio/SignalExports、AlgorithmConfiguration、AlgorithmImports.py）

- R92a（V1.2 参考）`PortfolioTarget.Percent`：先按 FreePortfolioValue 缓冲调整百分比，再除以杠杆，然后由 BuyingPowerModel 计算可达手数，结果为「手数×LotSize＋现有持仓」。超出 Max/MinAbsolutePortfolioTargetPercentage 或价格为 0 时只记 Error 并返回 null。V1.2 的固定表／风险比例仓位不走此路径（独立 RiskExecution），LEAN 研究端若使用 SetHoldings，其口径必须另行登记。`ClearFulfilled` 以 |目标−持仓|<LotSize 判定完成。
- R92b：SignalExports 只在实盘发送（回测直接返回 true 并打一次调试信息）。CrunchDAO 把 apiKey 放进 URL query（与 R87a 的 Tiingo 同类凭据暴露模式，未转录任何值）；Numerai 的 PUT 上传响应未检查状态码（PLAUSIBLE）；Collective2 的 `PrintErrors` 在 errors 为 null 时 `errors?.Count==0` 为 false，随后 foreach 抛 NRE（PLAUSIBLE）；每次发送都改写共享 HttpClient 的 DefaultRequestHeaders（非线程安全）；CFD 类型被静默跳过。VBase 的静态 RateGate 每次构造实例都会被重置。全部为 Tier 4（V1.2 不使用 LEAN 下单或信号外发）。
- R92c：InsightCollection 的索引器 getter 对不存在的键抛 KeyNotFound（`?.` 起不到保护作用）；setter 若赋 null，之后 GetEnumerator/GetNextExpiryTime 会 NRE（PLAUSIBLE）。Insight.Expire 将 CloseTime 设为当前时间减 1 秒；ComputeCloseTime 把 Hour 换算为 Minute 逐根推进。
- R92d：AlgorithmImports.py 会把自身目录加入 sys.path，并加载该目录下所有 QuantConnect.*.dll；`from System import *` 后恢复 builtins.Exception。AlgorithmConfiguration 的 TradingDaysPerYear 默认 252（与 R77、R82b 对照）。

## C16 / L206 (R93) 其他 Common 第 25–64 个（AlgorithmUtils、Api DTO、BaseSeries、Benchmarks、BinaryComparison）

- R93a（确认缺陷，仅影响性能）：BinaryComparisonExtensions 的两个 Filter 重载中，`breakAfterFailure = comparison == LessThanOrEqual || comparison == LessThanOrEqual` 重复写了同一条件，本意应包含 LessThan。只会让 LessThan 失去提前退出，结果仍正确。
- R93b：Api.Authentication.Link 把 `base64(userId:SHA256(token:timestamp))` 放进 URL query（带时间戳的散列，但仍会进入日志或代理记录）；PriceEntry 用服务器返回的字符串构造 Regex，且未设超时。ProductJsonConverter 的异常文本误写为 OrderJsonConverter（复制粘贴）。OptimizationBacktestJsonConverter 读取时，name/id/progress 缺失会 NRE；写出时统计值若 Currencies.TryParse 失败则静默丢弃。
- R93c：AlgorithmUtils.SeedSecurities 只给 Price==0 的证券补种价格；SeedCurrencyConversionRates 只处理 ConversionRate==0 的现金（与 R74b 的“无数据时汇率为 0”相关联）。
- R93d：BaseSeries.AddPoint 遇到与上一点时间相同的新点时直接覆盖（图表中同一时刻以最后一次为准）；SecurityBenchmark 的值＝Price×QuoteCurrency.ConversionRate。
- Api DTO（Account、Backtest、Project、Nodes、ObjectStore、Optimization 等）为纯数据模型，不含交易逻辑；其中 Account.Card 只含 last4 和到期日字段定义，没有任何实际数据。Tier 4。

## C17 / L207 (R94) 其他 Common 第 65–99 个（Candlestick/Chart、CapacityEstimate、Commands、Country、Currencies、部分 Exceptions）

- **R94a（安全，同 R85a 类）**：BaseCommandHandler.Settings 使用 `TypeNameHandling.All`；FileCommandHandler 读取当前工作目录下 `command*.json` 并按此设置反序列化。凡是能写入该目录的本地进程，都可指定任意 .NET 类型（反序列化 gadget 风险）。Acknowledge 用 command.Id 直接拼出结果文件名 `result-command-{Id}.json`，Id 来自文件内容，可含路径分隔符（本地路径穿越，PLAUSIBLE）。V1.2 中 LEAN 只做离线研究，不应开启命令通道；若使用，须把工作目录设为专用且仅本用户可写。
- R94b：OrderCommand 构造 SubmitOrderRequest 时使用 `DateTime.UtcNow`，而不是算法时间（回测中时间戳不一致）。CancelOrderCommand 以「CancelRequest 存在且状态不是 Invalid」判定成功，并不代表已撤单。命令执行异常只记 Error，返回 Success=false。
- R94c（确认缺陷，只影响统计）：CapacityEstimate 平滑公式 `0.33×新值＋0.66×旧值`，权重和为 0.99，每个快照都会使容量估计系统性下降约 1%。
- R94d：Currencies.TryParse 用正则 `^[^\d\s-+]+` 去掉前缀货币符号，开头的「.」也会被去掉，因此 ".5" 被解析为 5（PLAUSIBLE，用于优化统计值序列化）。Country 中 EuropeanUnion＝"EUR"，不是 ISO 3166 代码。XAU 的显示符号为 "Au"。
- R94e：Chart.AddSeries 的异常文本含多余的 `$`；CandlestickSeries.ConsolidateChartPoints 对 OHLC 求和（用于聚合）；Candlestick.Update 与 Bar 同样采用「首值设 Open」的规则。DataMonitorReport 的失败百分比取整。Exceptions 解释器只改写错误提示文本，不改变执行流程。

## C18 / L208 (R95) 其他 Common 第 100–139 个（Exceptions 余下部分、Exchange、Expiry、ExtendedDictionary、Field、Global、Globals、Indicators 核心、Interfaces 前部）

- **R95a（V1.2 相关）Field.Volume 对 QuoteBar 返回价格**：`_volume = DataTypePropertyOrValue<TradeBar>(Volume, tick→Quantity)` 没有 QuoteBar 分支，QuoteBar 会落到默认的 `data.Value`（中间价 Close）。GOLD CFD 只有 QuoteBar，因此 LEAN 中任何以 `Field.Volume` 为选择器的指标拿到的是价格而不是成交量（PLAUSIBLE，未实测）。同理，Field.Close/High/Low 对 QuoteBar 取中间价；MT5 GOLD 的 tick volume 不在 LEAN QuoteBar 中，量能类指标须在跨引擎核对中单列。
- **R95b（V1.2 相关）RollingWindow 读操作会改变窗口大小**：索引器 getter 遇到 `i > Size-1` 时，会释放读锁并调用 `Resize(i+1)`，然后返回 default。读取越界索引会静默扩大窗口，而 `IsReady = Samples >= Size` 随之重新变为 false。若策略代码用超出窗口的索引读取历史 bar，指标或信号的就绪状态会意外退回（确认的行为，是否属设计意图待 Codex 判断）。负索引按 `Count+i` 计算，超出可用范围时返回 default。
- R95c：FileExtension.FromNormalizedPath 会删除路径中所有保留前缀字符（默认 "@"），合法的 "@" 也会被去掉（PLAUSIBLE）。Globals.DataFolder 默认是相对路径 "../../../Data/"，cache-location 非空时优先使用缓存目录；Globals.UserToken 来自配置项 api-access-token（本审查未读取任何配置值）。
- R95d：Holding.ConversionRate 的 setter 忽略值 1（保持 null），反序列化时再补回 1；AveragePrice/MarketPrice 按 MinimumPriceVariation 的小数位取整（只用于展示）。Exchange 的相等比较把 null 和 UNKNOWN 视为等价。Expiry.EndOfWeek 指向下周一 00:00。
- R95e：InternalIndicatorValues.IndicatorPropertyValues 在属性值不是 IndicatorDataPoint 时，`point.EndTime` 会抛 NRE（PLAUSIBLE）；IndicatorDataPoint 的 Equals 比较 Time+Value，CompareTo 只比较 Value。IAlgorithm、IApi、IBrokerage 等为接口声明，本批核对了签名：IBrokerage.PlaceOrder 返回 bool，不代表已成交，与 V1.2「CTrade 返回成功不等于成交」的原则一致。

## C19 / L209 (R96) 其他 Common 第 140–189 个（Interfaces 余下部分、Isolator、LocalTimeKeeper、Market、Messages 第 1 部分）

- R96a：Isolator 的内存监控只看托管堆（GC.GetTotalMemory，不强制回收），并用 60 个样本的 EMA 从 0 起步，前期主要靠 2 倍 spike 上限拦截；超时或超内存时 Cancel 并抛 TimeoutException（日志前缀误写为 "Security.ExecuteWithTimeLimit"）。PrettyFormatRam 先做整数除法再取整。IsolatorLimitResultProvider.Null 永远在限额内。
- R96b：Market 的硬编码表里 GDAX 与 Coinbase 是同一字符串（"coinbase"），分别登记 12 和 38，正向表后写覆盖为 38，反向表 12 仍解码为 "coinbase"（遗留别名，无实际冲突）。Market.Add 用写时复制、不加锁，并发写入时可能丢失更新。V1.2 的 GOLD 研究需确认所用 market（如 oanda、fxcm 或自定义），以及 market hours 和 symbol properties 条目（参见 T34 中 Symbols.cs 的 XAUUSD 为 Oanda CFD）。
- R96c：ISecurityPrice、IHistoryProvider、IDataQueueHandler、IObjectStore（Initialize 接收 userToken）、ITradeBuilder 等只有接口签名，已核对；IBrokerage.PlaceOrder 等返回 bool（见 R95e）。
- R96d：Messages.* 只有字符串模板。AttributeError 的提示文本明确写出「只有报价数据时 data[symbol] 返回 QuoteBar（外汇、期货、加密货币常见）」，与 R90b、R95a 对 CFD/GOLD 走 QuoteBar 的结论一致。BinanceBrokerageModel 的消息含多余的 `$`。DefaultBrokerageMessageHandler 的消息文本与 R83a（断线停机）吻合。secret 扫描命中的是 "invalid token"、"FTP password is missing" 一类提示文本，不是凭据。

## C20 / L210 (R97) 其他 Common 第 190–229 个（Messages 第 2 部分、Notifications、Optimizer、OS、Packets 开头）

- R97a（凭据处理）：NotificationFtp 把 password、privateKey、passphrase，NotificationTelegram 把 bot token 作为 JSON 字段序列化进通知包（DefaultValueHandling.Ignore 只在值为空时省略）。凡记录或转发这些包的日志或消息通道都会接触到凭据。V1.2 的监控和通知不应通过 LEAN 通知对象传递任何凭据（未转录任何值）。另外，SFTP（secure=true，含私钥构造）与普通 FTP 共用 DefaultPort=21，SSH/SFTP 的常规端口是 22（PLAUSIBLE）；文件内容按 ASCII 编码，非 ASCII 字符会丢失。通知只在实盘入队。
- R97b（V1.2 评分口径参考）：OptimizationBacktestMetrics.ExtractFrom 在结果 JSON 解析失败或缺少统计时，SharpeRatio 取 0m，该回测仍作为有效样本参与优化分析；参数值无法解析为 decimal 的会被丢弃。若用 LEAN 优化分析辅助选参，失败的运行可能被当作 Sharpe 0 的正常样本（PLAUSIBLE）。V1.2 的计划已规定 Sharpe 只作辅助，并须核对频率与收益序列，本条可作为不要直接采用 LEAN 优化摘要的依据。
- R97c：Objective._targetTemplate 的正则 `"['(.+)']"` 是字符类，匹配任意一个 `' ( . + )` 字符，而不是字面量 `['…']`；统计名若含 "(" 或 "+"（如 "Drawdown (%)"）就不会被包裹，生成的 JSON 路径会出错（PLAUSIBLE）。Target.GetTokenInJsonBacktest 删除所有 `[`、`]`、`'` 后按 "." 拆分，名称中含 "." 的统计项无法定位。
- R97d：Messages.FillModel.MarketNeverCloses 用了 `nameof(orderType)`，输出的是字面量 "orderType" 而不是实际订单类型（确认的文本缺陷）；ExanteFeeModel 的消息有多余的 `$`。Messages.QuantConnect 用静态可变字段 `_algorithmLanguage` 决定提示的代码风格（进程级全局）。
- R97e：OS.CpuUsage 未除以核心数，多核时可能超过 100%；OS.IsWindows 等价于「非 Linux/Unix 平台号」。OptimizationStepParameter 拒绝非正的 step/minStep，并要求 step ≥ minStep。

## C21 / L211 (R98) 其他 Common 第 230–274 个（Packets、PandasMapper.py、ParameterAttribute、Parse、Properties、Python wrappers 第 1 部分）

- R98a（安全）：BacktestResultPacket(string json) 用 `TypeNameHandling.Auto` 反序列化，与 R85a、R94a 同类，可按 JSON 实例化类型。AlgorithmNodePacket.UserToken、ResearchNodePacket.ResearchToken、LiveNodePacket.BrokerageData（券商配置，通常含凭据）、NotificationTargets（见 R97a）都是序列化字段，作业包落盘或进日志就会暴露（未转录任何值）。
- R98b：Controls 默认值：MaximumRuntimeMinutes＝100 天，BacktestingMaxOrders＝int.MaxValue，RamAllocation 1024MB（实盘包为 512MB），StorageLimit 10GB，PersistenceIntervalSeconds＝5。BacktestNodePacket.DefaultId 为每个进程一个随机 Guid（本地多次回测若不另设 BacktestId，会共用同一 ID）。MarketHours 构造时把 24:00 的结束时间减 1 tick。
- R98c：PandasMapper.py 在导入时对 pandas 的全局类方法打猴子补丁（_LocationIndexer.__getitem__、Index.get_loc、DataFrame.__getitem__、Index.__contains__），进程内所有 pandas 使用都会先按 SymbolCache 映射键，失败再退回原键。这会改变同进程中其他 Python 代码的 pandas 行为。V1.2 规定 Python 仅用于 MCP 监控，若监控进程与 LEAN Python 运行时同进程会受影响，须隔离（Tier 3 提醒）。
- R98d：FeeModelPythonWrapper 调用扩展签名 GetOrderFee 时只要抛出一次 PythonException，就永久切换为旧签名 `GetOrderFee(security, order)`，并把返回值固定包装为 USD 现金。用户 Python 费用模型中的真实错误可能因此被吞掉、改走旧签名（PLAUSIBLE）。MarginCallModelPythonWrapper 中，只要返回的订单非空就视为发出警告。其余 wrapper 只做方法转发；BasePythonWrapper 在 C#/snake_case 两种属性名间按值比较决定用哪个。
- R98e：ParameterAttribute.ApplyAttributes 用 Public|NonPublic|Static|Instance 绑定标志，可按参数名写入私有字段或静态字段，空值跳过，只读属性抛异常。Parse 统一使用 InvariantCulture；Parse.DateTime 不带 DateTimeStyles（Kind 不确定）。Common 程序集对 Algorithm、Framework、Brokerages、Engine、Tests 开放 InternalsVisibleTo。

## C22 / L212 (R99) 其他 Common 第 275–314 个（Pandas 转换、Python wrappers 第 2 部分、PythonInitializer、csproj、Result、Scheduling 核心）

- **R99a（安全）PythonInitializer**：ConfigurePythonPaths 总会把 `Environment.CurrentDirectory` 加进 Python 路径；没有算法目录时插入位置为 0，当前工作目录里的同名模块（如 json.py）可遮蔽标准库，属模块劫持风险。AddPythonPaths 和去除 site-packages 的逻辑把路径直接拼进单引号的 Python 代码字符串（`sys.path.insert(i,'{s}')`、`sys.path.remove('{s}')`），路径含 `'` 时会出错，或被注入 Python 语句（路径来自配置，本地风险，PLAUSIBLE）。缺少 pyvenv.cfg 时默认包含系统包。V1.2 若运行 LEAN Python，须固定专用工作目录。
- **R99b（V1.2 相关）ScheduledEvent 补发**：Scan 会把时间已过的所有事件按顺序连续触发（"fire all skipped events back to back"），回调收到的是原计划时间，实际执行在当前时间。数据缺口、周末或时间跳跃后，多个计划事件会集中补发。若在 LEAN 研究端用计划事件实现服务器日 00:00 换日（6 盈/6 亏计数重置）或定时风控，必须考虑补发顺序和实际执行时刻。GetDatesDeferred 从 `UtcTime.Date−1 天`（UTC 日期）开始取日期。ScheduledEvent 的 Equals 用引用相等，GetHashCode 用 Name。
- R99c：BaseScheduleRules.GetSymbol 找不到字符串 ticker 时，会静默创建 USA 市场的 Equity Symbol 并写入 SymbolCache，只警告一次。若以字符串 "XAUUSD" 等调用调度规则，而缓存里没有，就会得到错误的股票 Symbol 和交易时段（PLAUSIBLE），应始终传入 Symbol 对象。GetMarketOpenCloseExchangeHours 会预置 SPY 的交易时段作为后备。
- R99d：PandasData 合并同一行的 TradeBar 与 QuoteBar 时，先写 QuoteBar，再用 TradeBar 覆盖 OHLC。CFD/GOLD 只有 QuoteBar，因此 DataFrame 的 OHLC 是中间价。全为 NaN/0 的列被过滤（Serie.ShouldFilter 把 0 当作无效值，全为 0 的合法列也会被删）。PandasData 的静态构造会导入 PandasMapper（见 R98c 的全局补丁）。
- R99e：Common csproj 目标框架为 net10.0；依赖 pythonnet 2.0.68、Newtonsoft.Json 13.0.2、NodaTime 3.0.5、protobuf-net 3.1.33、QLNet 1.13.1、MathNet 5.0.0 等（只记录，未安装、未运行）。Python.Runtime.dll.config 只含注释掉的占位路径。RealTimeSynchronizedTimer 是 `Sleep(1)` 忙等循环。PythonData 的索引器写入时把 double 转为 decimal；IsOfType 依据 "__typename"。

## C23 / L213 (R100) 其他 Common 第 315–356 个（TimeMonitor、TimeRules、SecurityIdentifier、Series/SeriesSampler、ObjectStore、Symbol*、Time*、TimeZones、TradingCalendar、Util 第 1 部分）

- **R100a（V1.2 重点，服务器日口径）**：TimeZones 只提供 Tzdb 命名时区（NewYork、Athens、Helsinki 等），TimeRules.At/Midnight 按所给 DateTimeZone 把「本地日期＋时刻」换算为 UTC，TimeZoneOffsetProvider 用 NodaTime 的区间不连续点处理夏令时。MT5 券商的服务器时间常按美国夏令时切换 UTC+2/UTC+3，与欧盟规则的 Tzdb 区（如 Europe/Athens）每年会有约 2–3 周对不上。FxPro 的实际服务器时区规则本审查未核实（须以 MT5 实测为准）。若 LEAN 研究端用某个 Tzdb 区模拟「FxPro 服务器日 00:00」（6 盈/6 亏换日、D1 边界），切换期间会错位一小时。须单独登记时区映射并做跨引擎核对（Codex 汇总时一并确认）。
- **R100b（确认缺陷）ConcurrentSet**：IsSubsetOf 检查的是「other 的每个元素都在本集合中」，然后返回 `_set.Keys.Count==0`，语义写反了：本集合非空时恒为 false，即使它确实是 other 的子集。IsProperSubsetOf 同样有误。另外 GetEnumerator 返回的是共享缓存列表 `_enumerator` 的枚举器，另一线程 Add/Remove 后再次调用 GetEnumerator 会清空并重建这个列表，前一个枚举器会抛「集合已修改」（PLAUSIBLE 竞态）。SubscriptionDataConfig.Consolidators 正是 ConcurrentSet。
- R100c：静默替换时间。Time.UnixTimeStampToDateTime(double)、UnixMillisecond…、UnixNanosecond… 出错时返回 `DateTime.Now`（本机本地时间）；Time.ParseDate 全部格式失败时返回 `DateTime.Now`；ParseFIXUtcTimestamp 失败时返回 `DateTime.UtcNow`。坏时间戳会被替换成「现在」，而不是报错（确认的行为，对回测数据有风险）。UnixTimeStampToDateTime(double) 截断取整，而毫秒版本用 Ceiling 取整以避免前视，两者口径不一致。Time.EndOfTime＝2050-12-31。
- R100d：可复现性。SecurityIdentifier.GetFirstTickerAndDate 在未指定日期时用 `DateTime.Today`（本机日期）解析映射文件；SymbolRepresentation.GetExpirationYear 用 `DateTime.UtcNow` 推断期货年份。同一回测在不同日期运行，股票或期货的 Symbol 映射可能不同（Tier 4，GOLD CFD 不涉及映射）。TradingCalendar 固定使用 QLNet 的 UnitedStates 节假日历，且 GetTradingDay 取 UTC 日期。
- R100e：Composer 会加载基目录（以及 plugin-directory）下的全部 *.dll（Assembly.Load，失败则 LoadFrom），并按配置中的类型名实例化（DLL 植入风险，与 R99a 同类，适用于本地运行环境）。ComparisonOperator 的 Greater/Less 用 `CompareTo==1/-1` 判断，对返回其他正负值的 IComparable 不成立（PLAUSIBLE）。SymbolCapacity 对 CFD 假定每分钟成交量 200，对外汇假定 2,500 万（只影响容量统计）。SeriesSampler 对图表线性插值。ObjectStore 的 ReadXml 使用 XmlSerializer（类型固定，风险较低）。TimeMonitor 每分钟向 Isolator 申请 1 分钟额外时间，并提示长时间运行的任务名。
- 已核对：SecurityIdentifier 的位域编码（安全类型 2 位、市场 3 位、行权价比例 2 位、行权价 6 位、期权风格 1 位、OA 日期 5 位、看涨/看跌 1 位），以及负行权价使用第 20 位标记；Symbol 相等只比较 SID；用字符串隐式转换的 Symbol 若未缓存，会生成 SecurityIdentifier(ticker, 0)。

## C24 / L214 (R101) 其他 Common 第 357–398 个（Util 第 2 部分：LeanData、RateGate/RateLimit、StreamReaderExtensions、Validate、WorkerThread 等）。本批后 Common 全部 1,972 个已处理完毕

- **R101a（V1.2 数据转换重点）StreamReaderExtensions 快速解析器不做校验**：GetDecimal 逐字符按 `value*10+(c-'0')` 累加到 long，遇到非数字字符（如科学计数法的 'E'、'+'）不报错，直接算出错误数值；超过 19 位时 long 静默溢出。GetInt32/GetInt64 同样不校验。CFD/外汇的 Tick 和 TradeBar 流式读取都走这条路径。若把 MT5 导出的 GOLD 数据转成 LEAN 格式，必须保证纯十进制、无指数表示、无千分位、无多余空格，并对转换结果抽样回读核对（未实测）。
- **R101b（V1.2 数据格式）LeanData**：CFD 分钟级路径为 `cfd/<market>/minute/<symbol>/YYYYMMDD_quote.zip`，zip 内条目为 `YYYYMMDD_<symbol>_minute_quote.csv`，行格式为「当日毫秒, bid OHLC, LastBidSize, ask OHLC, LastAskSize」（不缩放）；小时和日线为 `cfd/<market>/<res>/<symbol>.zip`，时间格式 "yyyyMMdd HH:mm"。tick 行为「毫秒,bid,ask」。UseStrictEndTime 对 Oanda 市场的 CFD 和所有 Forex 不启用日线严格起止时间；其他市场的 CFD 会按交易所时段改写日线 Time/EndTime。因此 market 的选择会改变日线边界（与 R100a 的服务器日问题一并核对）。GetConsolidatorStartTime 以当天 00:00 为锚点，7 天以上周期改为以月初为锚点。
- R101c：RateGate.IsRateLimited 是带副作用的 getter，内部调用 WaitToProceed(0)，未被限流时会实际占用一个名额（确认的行为）。LeakyBucket 每次 TryConsume 都写 Trace 日志。Validate.EmailAddress(null) 返回 true（PLAUSIBLE）。LeanData 中的 LinqExtensions.Median 对偶数个元素取偏上中位数，而不是两数平均。MemoizingEnumerable 在持锁状态下 yield return，多线程消费可能互相阻塞。PythonUtil.ConvertToSymbols 把字符串一律当作 USA 市场的 Equity（同 R99c）。
- R101d：MarketHoursDatabaseJsonConverter 合并市场级与具体证券的节假日：在市场级假日当天若有提前收盘或推迟开盘，就记作 bank holiday（当天可交易，但到期规则会跳过）。KeyStringSynchronizer 按路径字符串加锁，配合 LeanDataWriter 的文件写入。WorkerThread.Instance 是全局单例线程（Isolator Thread，最高优先级）。TypeChangeJsonConverter 允许调用非公开默认构造函数。
- 统计：Common 共 1,972 个，其中 FULL_READ 1,002 个，DIFF_VERIFIED 970 个（Fundamental Generated），UNREAD 0 个。

## C25 / L216 (R103) 补完早期 PARTIAL：QuoteBar.cs、DateRules.cs、BaseSetupHandler.cs、Extensions.cs（全读），market-hours-database.json（结构审计）

- **R103a（V1.2 重点，跨引擎）QuoteBar 的 OHLC 是中间价，且 High/Low 是「bid 极值与 ask 极值的平均」**：Open/High/Low/Close 都取 (Bid+Ask)/2，一侧为 0 时退回另一侧；mid-High＝(Bid.High+Ask.High)/2，两个极值可能出现在不同时刻，并不等于真实中间价序列的最高点。MT5 图表 K 线按 Bid 构建。S7 反转闭柱、最近供需区等以 K 线 OHLC 为输入的逻辑，在 LEAN 端应显式使用 `quoteBar.Bid` 的 OHLC 才能与 MT5 对齐（L051 已先行记录中间价问题，本条补全细节）。QuoteBar.Update 在 lastTrade 为 0 时把 Value 设为 askPrice 而非中间价，与 Close 口径不一致。Collapse() 生成成交量为 0 的中间价 TradeBar。解析时 bid 四个字段全为 0 或空则 Bid＝null；Reader 出错返回默认 QuoteBar（Bid/Ask 为全 0 的 Bar），属 R90c 的零价 bar 同类。
- **R103b（V1.2 重点）时区转换的歧义处理**：Extensions.ConvertTo/ConvertToUtc 使用 NodaTime 解析器：重复的本地时刻（夏令时回拨）取较晚一次（ReturnLater），不存在的本地时刻（夏令时前拨）取跳变后区间起点。若 GOLD 数据以带夏令时的时区存储，回拨的那一小时内两段真实时间会映射到同一个 UTC 时段，导致数据重叠或乱序。建议研究端 GOLD 数据一律按 UTC 存储（dataTimeZone=UTC），服务器日边界另行映射（见 R100a）。
- **R103c（V1.2 重点）MHDB 中 XAUUSD 的交易时段因 market 不同而不同**：oanda 用 America/New_York 时区，每日休市 16:58–18:03（随美国夏令时移动），周五 16:58 收盘、周日 18:03 开盘；fxcm 用 UTC 固定 22:00–23:00 休市（周五 21:45 收盘）；interactivebrokers 用 UTC 固定 21:00–22:00（周五 21:00 收盘）。后两者是固定 UTC，与随美国夏令时移动的实际 OTC 黄金休市时间每年约半年相差 1 小时。三者的节假日只有 2017-04-14 一天（PLAUSIBLE：其他节假日都被视为交易日）。FxPro MT5 的 GOLD 交易时段须以 MT5 合约规格实测为准，并据此选择或自定义 market/MHDB 条目（未核实）。全库 552 个条目中，4 个（Future-cme-LBS/LBR、IndexOption-usa-RUT/RUTW）缺少 sunday 键；CFD 有 184 个条目。
- R103d：string.ToDecimal()、ToInt32()、ToInt64() 是与 R101a 同类的快速解析器，不校验字符；ToInt32 无法处理负号（"-5" 得到 -25，确认的行为）。ToCsv 在首字段为空时第二字段会带上前导逗号（确认的边界缺陷，时间字段为首列时不会触发）。GetHash(orders) 计算哈希时会原地对订单价格做 SmartRounding，修改了订单对象（确认的副作用）。GreatestCommonDivisor(decimals) 先用 Convert.ToInt32 取整（0.01 之类的小数会变为 0）。IsOutOfDate 依据本机时间和文件修改时间。OrderTargetsByMarginImpact 在预热期返回空集。
- R103e：DateRules.YearIterator 的迭代区间用 `new DateTime(start.Year, start.Month, 1)` 至 end 所在月末，而不是整年（Month/Quarter 迭代器都覆盖完整周期）。当偏移把计划日拉进区间、但基准日（1 月 1 日或 12 月 31 日）落在区间外时，事件会漏掉（PLAUSIBLE 边界缺陷）。DateRules.On 的名称使用与文化相关的 ToShortDateString。BaseSetupHandler.SetBrokerageTradingDayPerYear：加密货币券商为 365，其他（含外汇/CFD 券商）为 252（与 R77、R82b 对照：GOLD 每周约 5 个交易日）。
- 至此 LEAN 清单：FULL_READ 4,236，DATA_AUDITED 645，DIFF_VERIFIED 970，HASH_REUSE 5，IMAGE_VIEWED 8，PARTIAL 0；UNREAD 658 个全部为 BINARY_METHOD_ONLY（Data zip 650 个、Tests zip/ods 7 个、lean.ico 1 个）。
