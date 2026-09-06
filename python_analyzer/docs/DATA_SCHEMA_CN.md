# 数据格式与导入规则（第一版）

一个运行清单对应一次可追溯研究运行。导入器只读本地文件，不连接 MT5、不下单、不替换行情、不需要付费 AI API。每条记录有 `_source`（原文件绝对路径）、`_row`（CSV 行号或 HTML 起始行号）、`raw`（原始字段）。源文件有 SHA256，错误保留在 `issues`，缺数为 `null`，不自动填 0。

## 运行清单

UTF-8 JSON，`schema_version=1`。相对路径相对于清单所在目录。下例仅演示格式，**不是实际回测成绩、合约认证或资金建议**：

```json
{
  "schema_version": 1,
  "run_id": "MY_RESEARCH_RUN_001",
  "data_type": "backtest",
  "broker": "FxPro",
  "symbol": "GOLD",
  "symbol_aliases": ["XAUUSD"],
  "timezone": "unknown",
  "account_currency": "USD",
  "initial_capital": 2000,
  "ea_version": "待验证基准 R-C01",
  "ea_sha256": "填写实际源码的64位SHA256",
  "set_sha256": "填写实际SET的64位SHA256",
  "strategy_scope": ["Scalping", "Intraday", "Swing"],
  "magic_map": {"26082152": "Scalping", "26082102": "Intraday", "26082303": "Swing"},
  "contract": {"contract_size": null, "volume_min": null, "volume_step": null, "tick_size": null, "tick_value": null, "point": null},
  "costs": {"commission_model": "unknown", "swap_model": "unknown", "spread_model": "unknown", "slippage_model": "unknown"},
  "test": {"start": "2026-01-05T00:00:00", "end": "2026-08-26T00:00:00", "tick_model": "声明，待核实", "delay_ms": 0, "leverage": "1:100"},
  "segment": "development",
  "inputs": [
    {"kind": "deals", "path": "data/RUN_DEALS.csv"},
    {"kind": "trades", "path": "data/RUN_TRADE_REVIEW.csv", "adapter": "gsm_trade_review"},
    {"kind": "events", "path": "data/RUN_SIGNAL_AUDIT.csv"},
    {"kind": "funnel", "path": "data/RUN_SIGNAL_FUNNEL.csv"},
    {"kind": "report", "path": "data/RUN.htm"},
    {"kind": "report", "path": "data/RUN_NATIVE_STATS.csv", "adapter": "native_stats"},
    {"kind": "log", "path": "data/expert.log"},
    {"kind": "ticks", "path": "data/GOLD_ticks.csv"},
    {"kind": "bars", "path": "data/GOLD_M5.csv", "timeframe": "M5"},
    {"kind": "evidence", "path": "data/RUN.set"}
  ]
}
```

- `data_type` 必须区分 `backtest` 回测、`demo` 模拟账户、`live` 实盘历史、`synthetic` 合成演示、`unknown` 未确认。input 可单独声明，和清单不一致的文件隔离。
- `segment` 为 `development/validation/final`。最终区间未显式 `allow_final` 时，在读取输入前拒绝；开启后留下 `FINAL_SEGMENT_OPENED`。标记不能证明以前没人看过数据，首次使用仍需研究登记。
- `symbol_aliases` 只允许已核实同一合约的名称映射，不得把期货 GC、其他券商或合成数据冒充 FxPro 黄金。旧 GSM CSV 没有品种列时按清单归属并警告 `SYMBOL_DECLARED_ONLY`，不宣称逐行已核验。
- `magic_map` 应核对该次 SET，不直接照抄示例。行中明确 SOP 优先，其次使用 input 策略/Magic 映射。无法确认的归 `Unknown`。
- 合约字段须由实际规格证明。缺值时不凭“黄金通常一手100盎司”计算金额。
- input 可提供 `sha256`；不符时隔离。`evidence` 只登记文件哈希，不把 SET/源码当交易记录。

## CSV 与列映射

支持逗号、分号、Tab；识别 UTF-8/BOM、UTF-16 BOM。无 BOM UTF-16、旧中文编码仅推定，输出 `ENCODING_INFERRED`。可在 input 指定 `encoding`、`delimiter`（Tab 用 `"\t"`）。解码失败不阻塞其他文件。

`columns` 的方向为**统一字段名 → 原列名**：

```json
{"kind":"trades","path":"my.csv","strategy":"Intraday","columns":{"position_id":"仓位编号","time_open":"开仓时间","time_close":"平仓时间","net_profit":"含全部费用净损益"}}
```

金额用小数点，支持千位逗号/空格。小数逗号须先明确转换；不支持把 `1,23` 直接当 `1.23`。费用沿用成交记录的**带符号金额**，成本通常为负，返佣可为正；缺值为 null，只有来源明确为零才是 0。

| kind | 主要统一字段 | 语义 |
|---|---|---|
| trades | position_id, exit_deal, strategy, symbol, side, time_open, time_close, volume, entry_price, exit_price, initial_sl, initial_tp, gross_profit, commission, swap, fee, net_profit | 一条完整仓位，分批退出不能重复计数；通用 Profit 不默认净利润。 |
| deals | time, deal_id, position_id, order_id, entry, side, volume, price, profit, commission, swap, fee, magic, strategy, symbol | entry 为 in/out/inout/out_by；原生枚举0/1/2/3映射。不把 Order 当 PositionID。 |
| events | event_id, time, strategy, stage, reason, setup_id, decision, symbol | 一条源事件，保留 flags，不把多个过滤字段展开重计候选。 |
| funnel | time, strategy, run_id, counts, diagnosis | counts 保留原字段；累计快照不等于独立信号事件。 |
| equity | time, balance, equity, strategy | 余额/净值独立可空。组合账户曲线不能拆成各策略净值。 |
| bars | time, time_close, available_at, open, high, low, close, volume, timeframe, symbol, run_id | 支持 MT5 的 DATE/TIME 分列；不可提前使用尚未收盘 K 线。 |
| ticks | time, bid, ask, last, volume, symbol | 必须有合法 bid/ask，不能只拿期货 last 冒充报价。 |
| report | format, summary, raw_summary, strategy | 支持中英文 MT5 HTML 和 Metric/Value 原生统计；不从图片猜权益。 |

可选交易诊断字段：`mfe_money, mae_money, risk_pct, risk_money, setup_id, cluster_id, spread_money, slippage_money, spread_points, atr, regime, chase_entry, false_break, loss_classification, exit_reason, confidence`。点差/滑点已体现于成交价格时不能再从净利润重复扣除。行情状态定义需要来源，不能从盈亏反推。

## 当前源码适配及证据边界

**TRADE_REVIEW**：R-C01 的 `PositionLifetimeProfit` 汇总整个仓位 `Profit + Commission + Swap + Fee`；`gsm_trade_review` 适配器把其 Profit 映射为净利润。拆分费用没有导出仍为空。自动识别需同时含 `MFE_Money/ExitDeal/SOP`。其他来源不能盲目选择此适配器。

`MFE_Money/MAE_Money` 是原始手数价格浮动的毛金额，记录 `_mfe_basis=gross_price_excursion_original_volume`，不能与净利润硬当同口径比较。`ChaseEntry/LossClassification` 为源码启发式，标记 `_classification_basis=source_heuristic_not_proven_cause`，不是已证实亏损因果。

**SIGNAL_AUDIT**：保留 RawCore/IndicatorPassed/MACDPassed/BollingerPassed/ConfidencePassed/GatePassed/Accepted。Accepted=YES 不直接证明成交，须核对请求/DEALS。

**SIGNAL_FUNNEL**：保留 ZonesDetected/FirstTouches/HardSOPPassed/OrdersRequested/OrdersFilled/OrdersRejected 等累计值。图形扫描、触碰、过滤、拒单分母可能不同，不能相加或直接算统一转化率。禁用引擎也可能出现扫描计数，应对照 SET。

**StudyEvidence**：DEALS.csv 的 PositionID/Magic 是重建仓位的主要证据。NATIVE_STATS.csv 保留原生 NetProfitUSD/MaxEquityDDUSD/MaxEquityDDPct/NativeBalanceRecovery/NativeTrades/NativeDeals/MinMarginLevel/AllRequests/ManagementRequests/AllRequestRejects。Recovery 原生值直接保留，不因列名重新计算；项目净利/净值回撤比另算。HTM 金额最大回撤与相对最大百分比独立读取。

**GSM_ANALYZER 日志**：对转义字符解码一次，保留 EventID。FILTER_AUDIT 的 OBSERVED_PASS/OBSERVED_BLOCK 是观察，PRE_REQUEST_FILTER 不算成交。ACCOUNT_SAMPLE 导入权益并注明定时采样可能遗漏 Tick 内极值。STUDY_REQUEST 含管理请求，接受修改止损不等于新增仓位。自由文字没有结构化事件时明确无法统计拦截原因。

## 时间与数据质量

- 接受 MT5 日期与 ISO 8601。已知固定偏移 `UTC/UTC+02:00` 转 UTC；ISO 自带 offset 时优先它自身。未知时区保留无 offset 墙钟时间并警告，不猜券商夏令时。跨 DST 数据应拆分明确固定偏移输入，或提供带 offset ISO 时间。
- TimeMsc 默认按 MT5 服务器毫秒时钟处理；真正 UTC epoch 必须声明 input `time_unit="unix_ms_utc"` 或 `"unix_seconds_utc"`。
- 坏时间、反向开平仓、坏 OHLC、交叉 bid/ask、异品种留问题记录并隔离或保留空值；不插值编造交易。
- 相同业务记录去重。同一 DealID 的 HTM/CSV 已知字段一致时，仅补缺项并登记来源；已知值冲突则两份均隔离。一个毫秒的不同 Tick/不同 EventID 是合法多记录。
- Tick 首尾仅证明已提供记录范围，不证明连续性。缺口需结合交易日历、券商数据和原生日志；周末间隔不能直接叫数据丢失。
- 报告起点为 2024-03 或“100% 历史质量”不证明原始 Tick 完整覆盖。无有效原始 Tick 时标记 REAL_TICK_COVERAGE_UNVERIFIED。

## Python 接口

```python
from gsm_analyzer.ingest import load_dataset
result = load_dataset("manifest.json")
```

顶层字段：`manifest, provenance, issues, trades, deals, events, funnel, equity, bars, ticks, reports`。`reports[*].summary` 按实际来源提供 `net_profit, profit_factor, total_trades, win_rate, balance_drawdown_money, balance_drawdown_pct, equity_drawdown_money, equity_drawdown_pct, initial_capital, recovery_factor` 等。胜率为百分比（60 表示60%）。原生汇总与逐笔重算分别展示并核对差异，不相互冒充。

### K线可用时间及来源运行标识

`bars.time` 保留K线开时；`time_close`支持 BarEnd/BarEndTime/BarCloseTime/CloseTime/EndTime；`available_at`支持 AvailableAt/AvailableTime/IndicatorAvailableAt/DataAvailableAt。显式提供但无法解析的结束/可用时间会隔离该K线，不回退推定时间。分析层须检查可用时间不得早于开时加周期，并仅用进场前已可用的数据。

`deals/equity/bars/ticks` 均保留 `run_id`，识别 Run/RunID；源行缺失时可由 input.run_id显式声明，不凭文件名猜。去重标识包含run_id，不在导入时把不同运行相同时间/编号吞掉；分析层再核查不允许混运行。
