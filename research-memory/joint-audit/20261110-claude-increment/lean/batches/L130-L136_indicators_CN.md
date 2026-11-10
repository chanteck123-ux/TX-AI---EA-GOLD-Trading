# L130–L136 Indicators（第 2 段，至目录读完）— Claude 阅读笔记

- 日期：2026-11-09
- 方法：同 L125–L129（`dump_batch.sh` 生成带行号的源码；方法名 `CAT_N_CODE_EXCL_LICENSE_BLANK_USINGS_XMLDOC`）。
- 范围：清单 `ind_unread.txt` 第 81–233 行（I6–I12），另补读 4 个漏列的形态文件（I13：ThreeInside、ThreeLineStrike、ThreeOutside、ThreeStarsInSouth）。
- 完成情况：Indicators 目录 233 个文件全部 FULL_READ，**UNREAD 0**。
  - 其中 csproj 和 AssemblyInfo 为配置文件，同样逐行读过。
  - 标记后 LEAN UNREAD 为 3,988。
- 性质：只读审计，未编译、未运行。

## 新增待汇总条目（已写入 recheck request，等全部读完后一次性交给 Codex）

| 编号 | 内容 |
|---|---|
| R42 | ATR 的平滑方式随构造方式不同（QCAlgorithm.ATR 为 Simple，类默认 Wilders，Keltner 写死 Simple，NATR 先 SMA 后 Wilders） |
| R43 | EMA 和 Wilders 均以 SMA 起步，MT5 的 EMA 起点须核对 |
| R44 | Stochastic 慢线是比值的平均，MT5 slowing 的公式须核对；MAX/MIN 遇到相等值时取最新的 bar |
| R45 | IndicatorBase 不拦截 EndTime 相等的重复输入；MathError 时 Samples 增加但 Current 不更新；多品种指标须时间对齐，Correlation 用价格水平 |
| R46 | Pivot 确认延迟和 ZigZag 重绘；IntradayVwap 在 CFD 上永远不会就绪；SharpeRatio 指标单位不一致 |

## 其他阅读记录（未单列编号，供后续参考）

### 起点与预热
- 未就绪前，指标的返回值各不相同：
  - 返回 0：EMA、LWMA、TSF、DEMA；
  - 返回输入值：KAMA、LSMA、FRAMA；
  - 返回 Sum.Period：MassIndex；
  - 返回 50：UltimateOscillator；
  - 第一个值返回收盘价：PSAR。
- 研究端判断信号前必须检查 IsReady，不能拿未就绪的值与阈值比较。
- 就绪条件里，下列指标用 `Samples > Period`（比 Period 多一个样本）：Momentum、ROC、CMO、Delay、VIDYA、UltimateOscillator、NATR。

### 计算口径
- **Variance / StandardDeviation** 为总体方差（除以 n），BollingerBands 也用这个口径。MT5 iStdDev 同样是总体口径，但仍须实测核对。
- **RSI** 默认 Wilders。上涨或持平时 gain 记差值、loss 记 0；AverageLoss 四舍五入到 10 位小数后为 0 时返回 100。
- **CCI** 默认 SMA，常数为 0.015；平均绝对偏差为 0 时返回 0。
- **DonchianChannel** 的便捷构造函数名称写成 `DCH(lower,lower)`（显示名称有误，计算本身无误）。
- **HullMovingAverage** 的半周期取 `Math.Round(period/2)`，使用银行家舍入，奇数周期时可能与其他平台不同。
- **TriangularMovingAverage** 按奇偶分两段 SMA。
- **ZLEMA** 的延迟用 `Math.Round((period-1)/2.0)`。
- **HeikinAshi** 第一根的 Open 为 (O+C)/2；成交量只取 TradeBar 和 RenkoBar，QuoteBar 记为 0。
- **TrueRange** 第一根只用 H−L。ChoppinessIndex 在 TR 未就绪时也用 H−L。
- **KaufmanEfficiencyRatio** 在 `_sumRoc1 <= _periodRoc` 时返回 1。
- **MarketProfile / VolumeProfile** 按收盘价向上取整到 `priceRangeRoundOff`（默认 0.05）分桶。用于 XAUUSD 时，0.05 的价格粒度须单独评估。
- **TomDemarkSequential** 计算支撑或阻力价格时，用 `window.Skip(Count−9)`。窗口为最新在前，这会跳过当前 bar、包含 setup 之前的一根，疑为偏移一位（低优先级，V1.2 未使用）。
- **OptionIndicatorBase** 把输出取整到 7 位小数；期权与 V1.2 无关，属第 4 层。

### 数据类型限制
- 下列 TradeBar 指标在只有报价的 CFD 上无法直接使用：
  - CMF、EMV、ForceIndex、MFI、OBV、KVO、MassIndex；
  - VWAP、VWMA、MarketProfile、RelativeDailyVolume；
  - WilderSwingIndex 和 ASI、McClellan 系列。
  - 与 R41 (b) 的推断一致，仍未运行验证。
- 下列 BarIndicator 指标可以直接接受 QuoteBar：
  - ATR、ADX、Stochastic、PSAR、Donchian、Keltner、Ichimoku；
  - PivotPointsHighLow、ZigZag、HeikinAshi、SuperTrend、WilliamsR。

### 与 V1.2 用户 Scalping（S7）的关系
- LEAN 没有现成的"供需区"指标，最接近的是 PivotPointsHighLow 和 ZigZag，两者的确认语义见 R46 (a)。
- S7 的最近有效供需区回测和反转闭柱确认，仍按用户 SOP 自行定义，并在 LEAN 和 MT5 上用同一规则实现。
- 本笔记不改变 S7 的任何规则，也不启动研发。
