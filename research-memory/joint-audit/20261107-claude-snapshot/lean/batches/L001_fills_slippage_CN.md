# LEAN L001：成交模型与滑点模型（Claude，2026-11-06）

- **版本**：本地副本，6,522 个文件的 blob 与上游 `1383825` 一致（见回执）。只读，未编译，未运行。
- **FULL_READ（16 个）**：
  - `Common/Orders/Fills/` 下 FillModel.cs、FutureFillModel.cs、FutureOptionFillModel.cs、ImmediateFillModel.cs、LatestPriceFillModel.cs、IFillModel.cs、Fill.cs、FillModelParameters.cs、Prices.cs；
  - `Common/Orders/Slippage/` 下 ISlippageModel.cs、NullSlippageModel.cs、AlphaStreamsSlippageModel.cs、ConstantSlippageModel.cs、VolumeShareSlippageModel.cs、VolumeShareSlippageModel.py、MarketImpactSlippageModel.cs。
- **未读**：`EquityFillModel.cs`（52 KB）放入 L002。

## 一、与 V1.2 跨引擎核对直接相关的成交语义（CONFIRMED，读代码得出）
1. **价格来源按方向取 Bid 或 Ask**：`GetPrices` 优先用 Tick（卖用 Bid、买用 Ask），其次 QuoteBar（卖用 Bid bar、买用 Ask bar），最后 TradeBar。
   - 订阅了 QuoteBar 时，止损和限价都在**对应一侧的 OHLC** 上判定。卖出止损看 Bid 的 Low，与 MT5 多单止损按 Bid 触发一致。
   - **只订阅 TradeBar 时**，买卖都按成交价判定，点差被完全忽略。XAUUSD 必须使用 Quote 数据，否则 LEAN 与 MT5 的结果不可比。
2. **市价单**：
   - 按 `Current` 成交，即最后一根 bar 的 Close。
   - 只有当所有非内部订阅都是 Hour 或 Daily，且下单时间不晚于 bar 开始时间时，才用 Open 成交（`GetMarketFillPrice`）。
   - 默认**全量成交**，不考虑成交量。陈旧数据时：数据落后超过一个分辨率周期就等待新数据，否则按陈旧价成交并写入 `FilledAtStalePrice` 消息。
3. **止损市价单**：
   - 卖出止损在 `Low < Stop` 时触发，使用**严格小于**。追踪止损用 `<=`，两者的边界不一致。
   - 成交价为 `min(Stop, Current − slip)`。也就是说，如果 bar 内跌破止损后又收回到止损上方，成交价就是止损价本身，**滑点不起作用**。
   - 如果跳空低开，成交价用的是 Close 而不是 Open，可能比 Open 好，也可能比 Open 差。
   - MT5 的止损按触发后第一个可成交 tick 成交，两者在跳空和插针时**会出现系统性差异**。
   - FutureFillModel 的注释写"跳空时按开盘价成交"，**代码实际与基类相同，用的是 `Current`**，注释与代码不一致。
4. **限价单**：
   - 买入在 `Low < Limit` 时成交，**严格小于**，价格只触及限价时不成交。成交价为 `min(High, Limit)`。
   - 不加滑点，不模拟排队，全量成交。
5. **止损限价单**：触发后用 `Current` 与限价比较，成交价为 `min(High, Limit)`。触发 bar 内不使用最有利价格，注释说明原因是"无法确定极值出现在触发之前还是之后"。
6. **LimitIfTouched**：卖单用 Ask 与限价比较，买单用 Bid 与限价比较，方向与普通限价单相反，属于偏乐观的判定（PLAUSIBLE，需结合用例核实）。
7. **组合单**：任何一条腿没有成交，就返回空列表，即整组不成交。ComboLimit 中**每条腿**都用同一根 bar 的 Low 或 High 成交，属于乐观假设。
8. **交易时段**：`IsExchangeOpen` 对超过 1 小时的大 bar 放宽为"同一天即视为开盘"，日线回测中可能在收盘后成交。

## 二、滑点模型
- **默认**：FillModel 自身不带滑点，滑点由 `security.SlippageModel` 提供。`NullSlippageModel` 返回 0。
- **ConstantSlippageModel**：按参考价的固定百分比计算。MarketOnOpen 用 Open，其他订单用 `lastData.Value`。
- **AlphaStreamsSlippageModel**：只对 Equity 收 1 bp，**CFD 和 Forex 为 0**。
- **VolumeShareSlippageModel**（C# 与 py 版本一致）：
  - CFD、Forex、Crypto 没有成交量时**记录错误日志后返回 0 滑点**，因此 XAUUSD 用这个模型实际等于零滑点。
  - 对 QuoteBar，**买单取 `LastBidSize`，卖单取 `LastAskSize`**。买单消耗的是卖盘，按理应取 Ask 一侧，这里疑似方向写反（PLAUSIBLE，需上游确认是否有意为之）。
- **MarketImpactSlippageModel**：
  - 明确拒绝 Forex 和 CFD，直接抛出异常。
  - `_symbolData` 只在第一次调用时根据**第一个**资产初始化。同一个模型实例被多个资产共用时，后续资产会使用第一个资产的波动率和成交量（CONFIRMED，代码结构如此）。
  - 使用固定种子 50 的随机噪声；参数取自 2005 年的标定，注释也建议重新标定。

## 三、对 V1.2 的含义（只是登记，未执行任何测试）
- LEAN 中 XAUUSD 的默认成交是乐观的：全量成交，止损价在 bar 内恢复时没有滑点，CFD 的成交量滑点为 0。**LEAN 结果不能替代 MT5 Real Tick**，与 AGENTS.md 的规定一致。
- 跨引擎核对时，至少要固定以下几项：使用 Quote 数据；止损触发边界（`<` 还是 `<=`）；跳空时的成交价；滑点的来源。
- RiskExecution 的用例可以补充一条：同一根 bar 内先触发止损再收回时，两个引擎的成交价差异应能被记录和解释。
