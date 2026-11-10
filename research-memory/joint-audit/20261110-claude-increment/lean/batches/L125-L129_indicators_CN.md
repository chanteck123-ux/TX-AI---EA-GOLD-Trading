# L125–L129 Indicators（第 1 段，80 / 233 个文件）— Claude 阅读笔记

- 日期：2026-11-09
- 方法：`tools/dump_batch.sh` 生成带行号的源码，跳过许可证头、BOM、空行、using、`///` 文档注释和 `[DocumentationAttribute]`；标记为 FULL_READ，方法名 `CAT_N_CODE_EXCL_LICENSE_BLANK_USINGS_XMLDOC`。
- 范围：清单 `ind_unread.txt` 的第 1–80 行（I1–I5）：
  - Indicators 根目录的 A–B 开头指标（AccelerationBands、AD、ADOSC、ADX、ADXR、ALMA、AO、APO、ARIMA、ArmsIndex、Aroon、ATR、BollingerBands 等）；
  - CandlestickPatterns 目录下的形态类，包括 CandleSettings、CandlestickPattern 基类，以及 AbandonedBaby 到 ThreeBlackCrows。
- 性质：只读审计，未编译、未运行。

## 与 V1.2 相关的发现（待汇总给 Codex 一次性复核）

### R42（新增候选）：ATR 默认平滑方式不一致
- `QCAlgorithm.ATR(...)` 便捷方法默认用 `MovingAverageType.Simple`，而直接 `new AverageTrueRange(period)` 默认用 Wilders。
- MT5 的 iATR 是简单移动平均；MQL 自写的 ATR 常用 Wilders。
- 影响：跨引擎核对 ATR、止损距离或仓位预算时，必须登记 ATR 的构造方式和平滑类型，不能只写"ATR(14)"。

### 其他指标口径（归入 R41 补充）
- **ADX**：+DI 与 −DI 之和为 0 时返回 50，平滑方式为 Wilders。
- **BollingerBands**：标准差为 0 时产生 MathError（除零保护），会影响 %B 和带宽的使用。
- **AccelerationBands** 是 IBaseDataBar 指标，可以接受 QuoteBar；**AD/ADOSC** 需要 TradeBar，在只有报价的 CFD 上不可用（与 R41 的类型不匹配推断一致，仍未运行验证）。
- **ARIMA** 使用 RollingWindow.ToArray()，顺序是最新在前，移植时注意方向。
- **ArmsIndex** 直接拿 `ADVRatio` 指标对象与 0 比较（隐式取 Current.Value）。

### K 线形态（CandlestickPatterns）
- **CandleSettings 是静态、可变的全局状态**，修改后会影响同一进程中所有形态实例。默认值：
  - BodyLong 10/1.0
  - BodyDoji HighLow 10/0.1
  - ShadowLong RealBody 0/1.0
  - Near 5/0.2，Far 5/0.6，Equal 5/0.05
- Close==Open 的 K 线计为 White（阳线）。如果 V1.2 的反转闭柱判定借用 LEAN 形态，需要登记这一点；MT5 侧常以 `close>open` 判阳线。
- Engulfing 以实体比较，使用严格不等号，Period 为 3。
- MatHold 与 RiseFallThreeMethods 的 `IsReady => Samples > Period`；其余多数形态是 `>=`。
- 复制粘贴式小错误，默认参数下周期相同，因此无害：
  - Hammer、HangingMan、InvertedHammer 的 `_bodyShortAveragePeriod` 取的是 BodyLong 的周期；
  - StalledPattern 的 shadowVeryShort 滚动总和减去的是 `window[_bodyShortAveragePeriod + 1]`；
  - IdenticalThreeCrows 在预热阶段把 Near 的 range 累加进 Equal 的总和。
- 这些小错误一旦改动 CandleSettings 就会显现，因此 V1.2 不建议直接依赖 LEAN 的形态类作为 S7 用户 Scalping 的反转闭柱定义。S7 应按用户 SOP 自行定义并在双引擎上对齐。
- StickSandwich 用 BodyLong range 累加 Equal 总和（预热段），与 IdenticalThreeCrows 同类。
- TasukiGap 在预热段用 Equal range 累加 Near 总和（同类复制滑移）。
- Takuri 和 ThreeBlackCrows 的逻辑与 TA-Lib 一致，未见其他问题。
- 形态类的工厂方法不会自动预热（R41 已记录）。

## 覆盖
- L125–L129 共 80 个文件 FULL_READ。
- 标记后 LEAN UNREAD 为 4,145。
