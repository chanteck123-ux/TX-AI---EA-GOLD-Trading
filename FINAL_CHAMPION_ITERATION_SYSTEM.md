# GSM GOLD 3-SOP EA — Final Champion, Optimization & Research System

## Authority

本文件是 GSM GOLD 3-SOP EA 的最高层开发、优化、验证与 Champion 管理规范。

若旧文档的指标顺序、Candidate 命名、Combined 假设、Research 处理方式或程序流程与本文件冲突，以本文件为准。

最终评价顺序固定为：

`Net Profit USD -> Max Equity Drawdown -> Profit Factor -> Trades -> Win Rate -> Reject`

Reject 目标必须为 0。Max Equity Drawdown 具有风险否决权，不能用更高 Net 自动覆盖不可接受的回撤。

---

## 1. Highest-level architecture

```text
GSM SOP FOUNDATION
        ↓
3 STRATEGY ENGINES
  ├─ SCALPING M5
  ├─ INTRADAY M30
  └─ SWING D1/H4/M30
        ↓
OPTIONAL OPTIMIZATION / RESEARCH MODULES
        ↓
SIGNAL / CONFIDENCE
        ↓
RISK ENGINE
        ↓
PORTFOLIO MANAGER
        ↓
EXECUTION ENGINE
        ↓
MT5
        ↓
REAL TICK
        ↓
TRAIN / OOS
        ↓
FXPRO / TRADONA
        ↓
TRADE AUDIT + MISSED OPPORTUNITY AUDIT
        ↓
CHAMPION COMPARISON
        ↓
REJECT / MORE TESTING / NEW CHAMPION
```

GSM SOP 决定“什么是有效交易逻辑”。GitHub / 外部 EA Research 只负责提供“值得测试的 Candidate Idea”。外部逻辑未经独立验证不得直接写入 Champion。

---

## 2. Four Champion lines

1. `SCALPING_CHAMPION`：M5 Scalping 单独开启。
2. `INTRADAY_CHAMPION`：M30 Intraday 单独开启。
3. `SWING_CHAMPION`：D1/H4/M30 Swing 单独开启。
4. `COMBINED_CHAMPION`：三个已锁定单策略 Champion 重新组合后的完整 EA。

Combined 盈利不能证明三个策略都优秀；三个单策略盈利也不能证明 Combined 一定优秀。

每个 Champion 必须可追踪：版本、源码 SHA256、SET SHA256、Broker、Symbol、Capital、Risk、Real Tick 区间、OOS 区间、指标和最终报告。

---

## 3. Candidate names

| Lane | Candidate | Branch |
|---|---|---|
| Scalping | `S-C01` | `research/scalping/<topic>` |
| Intraday | `I-C01` | `research/intraday/<topic>` |
| Swing | `W-C01` | `research/swing/<topic>` |
| Combined | `C-C01` | `research/combined/<topic>` |

`V3.21-GHxx` 或其它 Research ID 只代表 Idea / Research Record，不代表源码已经实现或回测通过。

---

## 4. Fair single-strategy test

每个 Candidate 原则上只改变一个主要变量，且只开启对应策略。

Champion 与 Candidate 必须保持：

- Same Broker
- Same Symbol
- Same Capital
- Same Leverage
- Same Real Tick Period
- Same Tester Model
- Same Spread / Commission assumptions
- Same Risk
- Same base execution settings

每个 Broker 固定输出：

| Version | Net USD | Max Equity DD | PF | Trades | Win Rate | Reject |
|---|---:|---:|---:|---:|---:|---:|

并输出：

- `Delta Net`
- `Delta DD`
- `Delta PF`
- `Delta Trades`
- `Delta Win Rate`

Training 用于选参数；OOS 只用于验证。读取 OOS 后不得回头调参并仍把该段称为 OOS。

---

## 5. Strategy lanes

### Scalping M5

研究只影响 Scalping Engine，例如：Zone、Departure、First Touch、Retest、closed reversal candle、Spread、Slippage、Entry Distance、SL/TP、成本与风险。

### Intraday M30

研究只影响 Intraday Engine，例如：Trend、S&D、Zone、Candlestick、MTF、BOS/CHoCH、ATR/Structure SL、Entry Quality、Session。

### Swing

研究只影响 Swing Engine，例如：D1 Framework、H4 Trend、S/R、S&D、Pullback、Candlestick、Structure、SMC、Trailing、Protection、ATR、Fibonacci。

未被研究的两个 Strategy Champions 必须锁定；源码与参数不得顺手修改。

---

## 6. Combined candidate

任何 New Strategy Champion 都触发新的 Combined Candidate。

Combined 必须重新编译并重新做双经纪商 Real Tick，不得把三个独立净利润相加当作组合结果。

Portfolio Audit 至少检查：

- Concurrent Positions
- Margin Usage
- Aggregate Risk
- Same-direction Exposure
- Opposite-signal Conflict
- Hedging / Netting
- Capital Allocation
- Position Sizing
- Drawdown Overlap
- Strategy Correlation

组合变差时，三个独立 Champion 继续保留；只建立 `C-Cxx` 研究 Portfolio Risk，不回写已锁定策略逻辑。

---

## 7. Champion evaluation

正式优先级：

1. **Net Profit USD**
2. **Max Equity Drawdown**
3. **Profit Factor**
4. **Trade Count**
5. **Win Rate**

辅助必须同时读取：

- Average Win
- Average Loss
- Realized Average R:R
- Expected Payoff / Expectancy
- Recovery Factor
- Long Win Rate / Short Win Rate
- Maximum Consecutive Losses
- Spread / Commission / Slippage sensitivity

Win Rate 不得独立评价。高胜率但负 Expectancy、极差 Average R:R 或严重 Tail Risk 的 Candidate 不得成为 Champion。

---

## 8. External EA Research boundary

外部 EA、GitHub 项目、截图参数和第三方模型解读全部属于：

`EXTERNAL RESEARCH`。

它们不是 GSM SOP，也不是自动可用的 Champion Logic。

外部来源必须经过：

```text
Source / Screenshot / Repository
        ↓
Evidence Classification
        ↓
Read License / Source if available
        ↓
Separate FACT from HYPOTHESIS
        ↓
Clean-room Specification
        ↓
Single-module Candidate
        ↓
Compile
        ↓
Real Tick
        ↓
Train / OOS
        ↓
FxPro + Tradona
        ↓
Candidate VS Current Champion
```

没有源码时，参数名称不能被脑补成内部状态机。例如 `30 points`、`50%`、`120/50/20` 等只能记录界面事实，不能直接解释为止损、爆仓线、锁仓顺序或恢复逻辑。

研究来源：`docs/EXTERNAL_EA_TEST_2_41_RESEARCH_CN.md`。

---

## 9. External Research Module A — Fast Adverse Move Guard

外部测试版 2.41 最值得研究的模块之一是“快速不利移动保护”。

目标：处理“刚进场后很短时间内就迅速证明错误”的情况，而不是机械等待固定 SL。

禁止直接复制外部固定 `120秒 / 50点 / 20点`。

Candidate 应采用自适应定义：

```text
MAE = 入场后的最大不利移动

IF
MAE > K × ATR
AND elapsed_time <= FastWindow
AND adverse_momentum_is_strengthening
THEN
    Freeze same-direction new entries
    Set state = FAST_ADVERSE_MOVE
```

Scalping、Intraday、Swing 的 `K`、时间窗、触发逻辑必须分别测试，不能共用一个未经验证参数。

此模块属于 Position/Risk Protection Candidate，不得直接改变 GSM Base Entry。

---

## 10. External Research Module B — Recovery / Resume State Machine

快速熔断后不能立即无条件恢复开仓。

推荐最小状态机：

```text
NORMAL
  ↓
FAST_ADVERSE_MOVE
  ↓
FREEZE
  ↓
RECOVERY_CONFIRM
  ↓
NORMAL
```

要求：

- 状态尽量少。
- 每次状态变化必须日志化。
- 必须记录 trigger reason / timestamp / price / strategy / direction。
- MT5 / VPS 重启后必须可以根据持仓、订单与持久化状态重建，而不是重启后错误回到 NORMAL。
- Recovery 条件必须独立 A/B 测试。

---

## 11. External Research Module C — Direction Basket Risk

风险不只看单笔，也要看同方向累计暴露。

统一计算：

```text
BUY_Basket_Floating_PnL
SELL_Basket_Floating_PnL
BUY_Total_Open_Risk
SELL_Total_Open_Risk
BUY_Total_Lots
SELL_Total_Lots
```

Candidate 可以研究：

- BUY 方向达到风险上限时，只冻结/处理 BUY。
- SELL 方向仍可保持独立资格，但必须经过 Portfolio Conflict Check。
- 不因为一个方向失控就必然关闭整个 EA，除非触发账户级 Circuit Breaker。

该模块对 Combined Champion 尤其重要，因为 Scalping / Intraday / Swing 可能同时持有同向 Gold Exposure。

---

## 12. External Research Module D — Daily Account Circuit Breaker

Risk Engine 应支持账户级熔断 Candidate：

- `DailyProfitLimitUSD`
- `DailyLossLimitUSD`
- `DailyLossPercent`
- `DailyEquityDrawdownPercent`

金额和百分比必须可独立开关。

原因：账户从 `$500` 增长到更高 Equity 后，固定 USD 阈值可能失真；而只使用百分比也可能与实际最小手数风险冲突。

所有 Daily Circuit Breaker 必须明确：

- 以 Balance 还是 Equity 为准。
- Reset 时间和 Broker Server Time。
- 是否只阻止 New Entry，还是管理 Existing Position。
- 触发后何时恢复。

---

## 13. External Research Module E — Optional Evidence Voting

禁止把所有可选指标做成巨大 `AND` 条件导致长期不开单。

正确层级：

```text
Core GSM SOP = Trade Eligibility

Optional Evidence Modules = Quality Evidence
  ├─ EMA
  ├─ ADX
  ├─ DI
  ├─ ATR Regime
  ├─ CCI
  ├─ FVG
  ├─ Candle
  ├─ S&D Quality
  └─ Market Structure

Evidence Score / Votes
        ↓
Candidate Quality
        ↓
Pass / Reject / Risk Multiplier / Position Size Tier
```

核心原则：

**SOP 决定有没有交易资格；Optional Evidence 只衡量证据强弱。**

Evidence Voting 可以测试：

- Hard threshold
- Weighted score
- Soft risk multiplier
- Rank only

但不得默认写入 Champion。

---

## 14. ADX + DI separation

如果测试 ADX / DI：

- ADX = trend strength。
- `+DI / -DI` = directional evidence。

候选示例：

```text
BUY evidence:
ADX > threshold
AND +DI > -DI

SELL evidence:
ADX > threshold
AND -DI > +DI
```

ADX20、CCI14 ±100、EMA13/34 等外部 EA 参数只能作为 Candidate 起点，不具有默认有效性。

---

## 15. External Research Module F — ATR-normalized FVG Quality

外部研究中的 `FVG Size / ATR` 思路可以进入 Optimization Pool。

候选定义：

```text
ValidFVG = FVG_Size >= ATR × MinFvgAtrRatio
```

然后与 GSM 结构组合测试：

```text
Impulse
+ Fresh Supply/Demand
+ First Touch
+ Structure
+ FVG Quality
```

FVG 永远属于 Optimization Layer；未经 Real Tick A/B 证明，不得替代 GSM Supply/Demand Base Zone。

---

## 16. Point / Pip / Price / Money conversion rule

任何外部参数写着 `20 / 50 / 100 points` 都不能直接假设等于固定美元价格或固定亏损。

必须由 Broker 实际规格计算：

```text
SYMBOL_POINT
SYMBOL_DIGITS
SYMBOL_TRADE_TICK_SIZE
SYMBOL_TRADE_TICK_VALUE
SYMBOL_TRADE_CONTRACT_SIZE
SYMBOL_VOLUME_MIN
SYMBOL_VOLUME_STEP
SYMBOL_TRADE_STOPS_LEVEL
```

程序必须同时记录：

- Raw points
- Price distance
- Lot
- Actual Risk USD
- Actual Risk %

禁止硬编码“100 points 永远等于 X 美元”。

---

## 17. External module research priority

对于测试版 2.41 提炼出的 Candidate，优先顺序：

1. `Direction Basket Risk`
2. `Daily Account Circuit Breaker`
3. `Fast Adverse Move Guard`
4. `Recovery / Resume State`
5. `ADX + DI Evidence`
6. `ATR-normalized FVG Quality`
7. `CCI Evidence`（低优先级）

原因：先研究风险、状态与执行可靠性，再研究普通指标过滤。

---

## 18. Program flow with new research hooks

### OnInit

```text
Read Broker / Symbol / Account Mode
↓
Read Contract Specs
↓
Load Champion Inputs
↓
Initialize 3 Strategy Engines
↓
Initialize Optional Evidence Modules
↓
Initialize Risk Engine
↓
Initialize Direction Basket Risk
↓
Initialize Daily Circuit Breaker
↓
Restore Recovery / Freeze State
↓
Initialize Portfolio Manager
↓
Initialize Execution + Audit
```

### OnTick

```text
UPDATE MARKET DATA
↓
UPDATE ACCOUNT / EQUITY / MARGIN
↓
UPDATE BUY / SELL BASKET RISK
↓
CHECK DAILY ACCOUNT CIRCUIT BREAKER
↓
MANAGE EXISTING POSITIONS
↓
CHECK FAST ADVERSE MOVE GUARD
↓
UPDATE RECOVERY / FREEZE STATE
↓
RUN SCALPING ENGINE
↓
RUN INTRADAY ENGINE
↓
RUN SWING ENGINE
↓
COLLECT CORE GSM SIGNALS
↓
OPTIONAL EVIDENCE SCORE / VOTES
↓
RESOLVE SIGNAL CONFLICT
↓
PORTFOLIO RISK CHECK
↓
BROKER / SPREAD / COST / MARGIN CHECK
↓
EXECUTION
↓
LOG ORDER + STATE + BLOCK REASON
↓
UPDATE DASHBOARD / AUDIT
```

外部 Research Hook 必须可单独关闭，以便永远可以重新跑纯 Champion Baseline。

---

## 19. Trade Audit and Missed Opportunity Audit

所有新模块必须留下 Blocked Reason / Trigger Reason。

建议扩展：

```text
FAST_ADVERSE_FREEZE
RECOVERY_NOT_CONFIRMED
BUY_BASKET_RISK
SELL_BASKET_RISK
DAILY_LOSS_CIRCUIT
DAILY_EQUITY_DD_CIRCUIT
EVIDENCE_SCORE_LOW
ADX_DI_REJECT
FVG_QUALITY_LOW
```

必须区分：

- `NO VALID SETUP`
- `VALID SETUP BLOCKED BY RESEARCH MODULE`
- `PROGRAM MISSED VALID SETUP`

否则无法判断 Candidate 是提高质量还是单纯减少交易。

---

## 20. Champion lock and history

每个 Strategy Champion 与 Combined Champion 都有版本、源码哈希、SET 哈希、报告指标和测试条件。

只有相同测试条件下的 Candidate 真正打赢它，才能解除锁定。

历史链分别记录：

- Scalping：Previous -> Candidate -> New Champion。
- Intraday：Previous -> Candidate -> New Champion。
- Swing：Previous -> Candidate -> New Champion。
- Combined：Previous -> Candidate -> New Champion。

---

## 21. Delivery ZIP

只有真正出现 New Combined Champion 才生成 Champion ZIP。

至少包含：

```text
CODE/
SETS/
CONFIG/
REPORTS/SCALPING/
REPORTS/INTRADAY/
REPORTS/SWING/
REPORTS/COMBINED/
REPORTS/OOS/
REPORTS/STRESS/
RESEARCH/CHAMPION_COMPARISON/
BEST_SCALPING/
BEST_INTRADAY/
BEST_SWING/
FINAL_REPORT_CN.html
CHAMPION_MANIFEST.txt
SHA256.txt
```

FINAL_REPORT 首页依次显示 Best Scalping、Best Intraday、Best Swing、Best Combined，字段顺序固定：

`Net -> Max Equity DD -> PF -> Trades -> Win Rate -> Reject`

用户收到的 ZIP 与 GitHub `champion/current/` 必须是同一文件；文件名、版本、SHA256 和报告指标完全一致。

---

## 22. GitHub assets

GitHub 分为两类长期资产：

1. **Champion Archive**：只保存 `champion/current/` 的当前 Champion ZIP 和 `champion/history/` 的旧 Champion ZIP。
2. **Research Knowledge Base**：保存来源、License、证据等级、算法、相关 SOP、目标问题、独立实现思路、测试摘要、KEEP/REJECT 和失败原因。

失败 Candidate 不保存大型 ZIP，只保存 Markdown / CSV 摘要，防止未来重复测试同一个失败 Idea。

外部 EA 研究文档，例如 `docs/EXTERNAL_EA_TEST_2_41_RESEARCH_CN.md`，长期保留在 Research Knowledge Base，不混入 `gsm-sop/`。

---

## 23. Final iteration loop

```text
CURRENT CHAMPION
↓
READ FINAL REPORT
↓
READ TRADE AUDIT
↓
READ MISSED OPPORTUNITY AUDIT
↓
IDENTIFY BIGGEST WEAKNESS
↓
SELECT GSM IMPROVEMENT OR RESEARCH IDEA
↓
FORM ONE TESTABLE HYPOTHESIS
↓
BUILD ONE CANDIDATE
↓
COMPILE
↓
REAL TICK
↓
TRAIN
↓
OOS
↓
FXPRO
↓
TRADONA
↓
AUDIT
↓
COMPARE WITH CURRENT STRATEGY CHAMPION
```

失败：

```text
REJECT
↓
SAVE RESEARCH SUMMARY
↓
DO NOT TOUCH CHAMPION
```

成功：

```text
NEW STRATEGY CHAMPION
↓
LOCK IT
↓
REBUILD COMBINED CANDIDATE
↓
FULL COMBINED REAL TICK
↓
PORTFOLIO AUDIT
↓
IF BETTER -> NEW COMBINED CHAMPION
↓
FINAL REPORT CN
↓
CHAMPION ZIP
↓
SHA256
↓
GITHUB ARCHIVE
```

---

## 24. Final principle

GSM SOP 负责：**怎么交易**。

External / GitHub Research 负责：**还有什么值得测试**。

Codex 负责：**设计、编码、实验、审计、归因**。

MetaEditor 负责：**证明源码可正确编译**。

MT5 Real Tick + OOS + Dual Broker 负责：**证明 Candidate 是否具有可重复统计优势**。

Champion System 负责：**决定最后留下哪个版本**。

任何新模块，包括 Fast Adverse Move Guard、Recovery State、Direction Basket Risk、Daily Circuit Breaker、Evidence Voting、ADX/DI、ATR-normalized FVG，都必须遵守同一规则：

**Research first -> Candidate -> Evidence -> Champion only if proven.**
