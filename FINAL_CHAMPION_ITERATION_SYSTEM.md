# GSM GOLD 3-SOP EA — Final Champion, Optimization, Dual-AI Research & Program Governance System

## Authority

本文件是 GSM GOLD 3-SOP EA 的最高层开发、优化、验证、AI Research、程序治理与 Champion 管理规范。

若旧文档的指标顺序、Candidate 命名、Combined 假设、Research 处理方式、AI 协作方式或程序流程与本文件冲突，以本文件为准。

当前运行假设：已经存在经过正式验证的 `REAL CURRENT CHAMPION`，包括：

```text
SCALPING M5 CHAMPION
INTRADAY M30 CHAMPION
SWING CHAMPION
3-SOP COMBINED CHAMPION
```

从此以后：

```text
CHAMPION = 唯一正式基准
Candidate VS Champion = 唯一晋级方式
```

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
RESEARCH LAB
  ├─ USER SOP OPTIMIZATION
  ├─ CODEX
  ├─ CLAUDE CODE
  ├─ CODEX + CLAUDE HYBRID
  └─ EXTERNAL / GITHUB RESEARCH
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
WALK FORWARD / STRESS TEST when required
        ↓
TRADE AUDIT + MISSED OPPORTUNITY AUDIT
        ↓
CHAMPION COMPARISON
        ↓
REJECT / KEEP CURRENT CHAMPION / RESEARCH FURTHER / NEW CHAMPION
```

GSM SOP 决定“什么是有效交易逻辑”。AI / GitHub / 外部 EA Research 只负责提供“值得测试的 Candidate Idea”。外部或 AI 逻辑未经独立验证不得直接写入 Champion。

---

## 2. Four Champion lines

1. `SCALPING_CHAMPION`：M5 Scalping 单独开启。
2. `INTRADAY_CHAMPION`：M30 Intraday 单独开启。
3. `SWING_CHAMPION`：D1/H4/M30 Swing 单独开启。
4. `COMBINED_CHAMPION`：三个已锁定单策略 Champion 重新组合后的完整 EA。

Combined 盈利不能证明三个策略都优秀；三个单策略盈利也不能证明 Combined 一定优秀。

任何时候都必须可以明确回答：

```text
Current Scalping Champion = ?
Current Intraday Champion = ?
Current Swing Champion = ?
Current Combined Champion = ?
```

禁止同一条 Champion Line 同时存在两个“正式 Champion”。

每个 Champion 必须可追踪：版本、源码 SHA256、SET SHA256、Broker、Symbol、Capital、Risk、Real Tick 区间、OOS 区间、指标和最终报告。

---

## 3. Candidate names and provenance

标准 Candidate ID：

| Lane | Candidate | Canonical Branch |
|---|---|---|
| Scalping | `S-C01` | `research/scalping/<origin>/<topic>` |
| Intraday | `I-C01` | `research/intraday/<origin>/<topic>` |
| Swing | `W-C01` | `research/swing/<origin>/<topic>` |
| Combined | `C-C01` | `research/combined/<origin>/<topic>` |

`origin` 建议使用：

```text
user
codex
claude
hybrid
external
```

Candidate 来源必须明确记录为以下之一：

```text
USER_SOP_OPTIMIZATION
CODEX
CLAUDE
CODEX_CLAUDE
EXTERNAL_RESEARCH
```

来源不改变判定标准。

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
- Same Slippage assumptions
- Same Risk Budget
- Same Position Sizing Rules
- Same Session Conditions
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

### Risk-normalized comparison

禁止：

```text
Candidate 用更高 Risk / Lot
Champion 用更低 Risk / Lot
然后只比较 Net Profit
```

如果风险不同，必须先做：

```text
RISK-NORMALIZED COMPARISON
```

并报告 Requested Risk 与 Actual Risk。

---

## 5. Strategy lanes

### Scalping M5

研究只影响 Scalping Engine，例如：Zone、Departure、First Touch、Retest、closed reversal candle、Spread、Slippage、Entry Distance、SL/TP、成本与风险。

核心流程：

```text
M5
↓
Find Current Nearest Valid S&D by CURRENT PRICE DISTANCE
↓
Fresh Zone
↓
Departure
↓
First Touch / Retest
↓
Reversal Confirmation
↓
Entry
↓
SL / TP
↓
Exit
```

不设人为每日硬上限；禁止为了增加 Trades 制造无效交易。

### Intraday M30

研究只影响 Intraday Engine，例如：Trend、S&D、Zone、Candlestick、MTF、BOS/CHoCH、ATR/Structure SL、Entry Quality、Session。

Base / Benchmark：

```text
M30 Market Direction
↓
Nearest Valid M30 Supply / Demand
↓
Define Zone
↓
Wait Price Enter Zone
↓
Entry
↓
SL
↓
TP
↓
Management
```

M15/M5 confirmation、Any 2 of 3、3 of 3、EMA、BOS、CHoCH、FVG、OB、Liquidity、ATR Stop、Structure Stop、Session、VWAP、Volume、AI Score 等都只能先作为 Optimization Candidate。

### Swing

研究只影响 Swing Engine，例如：D1 Framework、H4 Trend、S/R、S&D、Pullback、Candlestick、Structure、SMC、Trailing、Protection、ATR、Fibonacci。

Swing 正式 Base 以当前已验证 Champion Code / Authoritative SOP 为准；Research Lab 不凭空重写 Swing Base。

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
- Portfolio Interaction

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

- Relative Drawdown
- Average Win
- Average Loss
- Realized Average R:R
- Expected Payoff / Expectancy
- Recovery Factor
- Long Win Rate / Short Win Rate
- BUY Performance / SELL Performance
- Maximum Consecutive Losses
- Spread / Commission / Slippage sensitivity
- OOS Performance
- Walk Forward Stability
- Parameter Robustness
- Market Regime Performance

Win Rate 不得独立评价。高胜率但负 Expectancy、极差 Average R:R 或严重 Tail Risk 的 Candidate 不得成为 Champion。

### Test Pass is not New Champion

必须区分：

```text
TEST PASS
≠
BEAT CHAMPION
```

Candidate 自己赚钱，不等于可以替换 Champion。

若结果只是“差不多”：

```text
KEEP CURRENT CHAMPION
```

只有证据明确：

```text
Candidate > Current Champion
```

才允许：

```text
PROMOTE TO NEW CHAMPION
```

---

## 8. External EA / GitHub / AI Research boundary

外部 EA、GitHub 项目、截图参数、第三方模型解读、Codex/Claude 新想法全部属于 Research Layer。

它们不是 GSM SOP，也不是自动可用的 Champion Logic。

外部来源必须经过：

```text
Source / Screenshot / Repository / AI Hypothesis
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
Walk Forward / Stress Test if promising
        ↓
Candidate VS Current Champion
```

没有源码时，参数名称不能被脑补成内部状态机。例如 `30 points`、`50%`、`120/50/20` 等只能记录界面事实，不能直接解释为止损、爆仓线、锁仓顺序或恢复逻辑。

研究来源包括：

- `docs/EXTERNAL_EA_TEST_2_41_RESEARCH_CN.md`
- `docs/GSM_GOLD_AI_RESEARCH_LAB_CN.md`

---

## 9. External Research Module A — Fast Adverse Move Guard

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

Scalping、Intraday、Swing 的 `K`、时间窗、触发逻辑必须分别测试。

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

要求：状态尽量少、状态变化日志化、记录 trigger reason / timestamp / price / strategy / direction，并且 MT5 / VPS 重启后可根据持仓、订单与持久化状态重建。

---

## 11. External Research Module C — Direction Basket Risk

统一计算：

```text
BUY_Basket_Floating_PnL
SELL_Basket_Floating_PnL
BUY_Total_Open_Risk
SELL_Total_Open_Risk
BUY_Total_Lots
SELL_Total_Lots
```

一个方向达到风险上限时，可以研究只冻结/处理该方向；另一个方向仍必须经过 Portfolio Conflict Check。

该模块对 Combined Champion 尤其重要，因为 Scalping / Intraday / Swing 可能同时持有同向 Gold Exposure。

---

## 12. External Research Module D — Daily Account Circuit Breaker

Risk Engine 应支持账户级熔断 Candidate：

- `DailyProfitLimitUSD`
- `DailyLossLimitUSD`
- `DailyLossPercent`
- `DailyEquityDrawdownPercent`

金额和百分比必须可独立开关。

所有 Daily Circuit Breaker 必须明确：

- Balance 还是 Equity 基准
- Reset 时间和 Broker Server Time
- 是否只阻止 New Entry
- 是否继续管理 Existing Positions
- 触发后何时恢复

---

## 13. External Research Module E — Optional Evidence Voting

禁止把所有可选指标做成巨大 `AND` 条件导致长期不开单。

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

核心原则：**SOP 决定有没有交易资格；Optional Evidence 只衡量证据强弱。**

Evidence Voting 可以测试 Hard threshold、Weighted score、Soft risk multiplier、Rank only，但不得默认写入 Champion。

---

## 14. ADX + DI separation

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

候选定义：

```text
ValidFVG = FVG_Size >= ATR × MinFvgAtrRatio
```

与 GSM 结构组合测试：

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
SYMBOL_VOLUME_MAX
SYMBOL_VOLUME_STEP
SYMBOL_TRADE_STOPS_LEVEL
SYMBOL_TRADE_FREEZE_LEVEL
```

程序必须同时记录：

- Raw points
- Price distance
- Lot
- Requested Risk USD / %
- Actual Risk USD / %

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

先研究风险、状态与执行可靠性，再研究普通指标过滤。

---

## 18. Program flow with research hooks

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

Research Hooks 必须可单独关闭，以便永远可以重新跑纯 Current Champion Baseline。

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

- Scalping：Previous -> Candidate -> New Champion
- Intraday：Previous -> Candidate -> New Champion
- Swing：Previous -> Candidate -> New Champion
- Combined：Previous -> Candidate -> New Champion

旧 Champion 永不删除；晋级后进入 Previous Champion Archive。

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

外部 EA / AI Research 文档长期保留在 Research Knowledge Base，不混入 `gsm-sop/`。

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

## 24. Dual-AI Research Lab roles

Codex 与 Claude Code 都视为完整的：

```text
MQL5 Research Engineer
+
MQL5 Developer
+
Code Reviewer
+
Backtest Analyst
+
Strategy Researcher
```

禁止固定为：

```text
Codex 只开发
Claude 只审查
```

两边都可以：

- 阅读完整 `.mq5` / `.mqh`
- 独立分析 Champion
- 找错误进场
- 找漏掉机会
- 找不开单原因
- 修改 MQL5
- 建立新模块
- 修 BUG / 重构
- 分析 MT5 日志
- 分析 Strategy Tester
- 分析 BUY / SELL
- 分析市场状态
- 提出 Candidate
- 审查对方 Candidate
- 反驳对方研究结论

AI 没有最终裁决权；它们是 Research / Engineering Agents。

---

## 25. Independent dual-model research protocol

默认要求 Codex 与 Claude Code **先独立研究，再交换结论**，避免一开始相互锚定。

```text
CURRENT CHAMPION
        │
        ├───────────────┐
        │               │
        ▼               ▼
     CODEX            CLAUDE
   Independent       Independent
   Hypothesis A      Hypothesis B
        │               │
        ▼               ▼
 Candidate A        Candidate B
        │               │
        └──────┬────────┘
               ▼
          CROSS REVIEW
               │
               ├─ Keep A
               ├─ Keep B
               ├─ Reject both
               └─ Build Hybrid Candidate C
                       ↓
                 MetaEditor Compile
                       ↓
                 MT5 Real Tick
                       ↓
              Candidate VS Champion
                       ↓
                 OOS / Walk Forward
                       ↓
                    Stress Test
                       ↓
                 PASS? -> Promotion Review
```

Hybrid Candidate 也必须能说明各变化来自哪里，禁止把 A+B 所有想法一次性堆叠而失去归因能力。

---

## 26. Candidate promotion gate

真正“打赢 Champion”至少要求：

```text
1. Code correctness
2. No future data / look-ahead
3. No hidden risk increase
4. Valid Real Tick evidence
5. OOS does not collapse
6. Walk Forward acceptable when required
7. Stress test acceptable
8. Critical risk metrics not unacceptably worse
9. Overall evidence clearly better than Current Champion
```

如果只是：

```text
Candidate 自己盈利
```

只能说明 Candidate 可能有研究价值，不代表 New Champion。

---

## 27. Cross code review and quantitative audit

Codex 审 Claude，Claude 也审 Codex。

最低审查清单：

1. 是否重复进场
2. 是否漏单
3. 是否错误使用未收盘 K 线
4. 是否存在 look-ahead
5. `CopyBuffer` / `CopyRates` 是否正确
6. Timeframe 是否正确
7. Position / Order / Deal 是否混淆
8. Magic Number 是否隔离
9. Hedging / Netting 是否兼容
10. SL / TP normalization 是否正确
11. Stops Level / Freeze Level 是否满足 Broker 规格
12. Spread / Slippage 是否正确处理
13. Risk / Lot calculation 是否正确
14. Volume min / max / step 是否正确
15. 是否误改未研究 Engine
16. 是否改变 GSM Base SOP；若改变是否明确披露
17. 是否存在过拟合迹象
18. 是否为了利润偷偷增加风险
19. 是否改变测试条件美化结果
20. 是否存在无法解释的利润来源
21. 是否完整记录 Broker Reject / Retcode
22. 是否可重建 Freeze / Recovery 状态

任何 Critical Review Finding 未关闭前，不得晋级 Champion。

---

## 28. Automatic Reject rules

禁止为了打赢 Champion：

- 偷偷增加 Lot
- 扩大 Risk %
- 删除核心 SL
- 增加隐性 Martingale / Grid Tail Risk
- 增加未披露最大持仓
- 使用未来 K 线
- 使用未来数据
- 修改回测区间挑最好年份
- 删除亏损阶段
- 降低 Commission / Spread 来美化 Candidate
- 用不同测试条件比较 Champion
- 用巨大 Equity DD 换 Net Profit
- 针对单一历史区间过拟合
- 隐藏 Broker Reject / Execution Failure
- 在 OOS 结果出来后回调参数并继续把同一段称为 OOS

发现任何一项：

```text
AUTOMATIC REJECT
```

---

## 29. Experiment registry

每个实验必须保存：

```text
Experiment ID
Engine
Candidate Version
Candidate Origin
Current Champion Version
Strategy Source
Research Hypothesis
Modified Files
Modified Rules
是否改变 GSM SOP (YES/NO)
Risk Budget
Actual Risk
Test Protocol
Broker / Symbol / Date Range
Champion Metrics
Candidate Metrics
Delta Metrics
OOS Result
Walk Forward Result
Stress Test Result
Codex Review
Claude Review
Audit Result
Blocked / Trigger Reasons
Final Verdict
Promotion Decision
Reason
```

Final Verdict 只允许：

```text
REJECT
KEEP CURRENT CHAMPION
RESEARCH FURTHER
NEW ENGINE CHAMPION
NEW 3-SOP COMBINED CHAMPION
```

---

## 30. Git / version isolation

正式 Champion 与 Research 必须隔离。

推荐逻辑：

```text
main / production
└── current formal Champion reference

champion/
├── current/
└── history/

research/
├── scalping/<origin>/<topic>
├── intraday/<origin>/<topic>
├── swing/<origin>/<topic>
└── combined/<origin>/<topic>

research summaries / rejected results
└── Markdown / CSV only
```

旧 Champion 永不删除。

新 Champion 晋级：

```text
Old Current Champion
→ champion/history/

Winning Candidate
→ champion/current/
```

必须保留完整 lineage。

---

## 31. Final dual-AI Champion loop

```text
CURRENT CHAMPION
↓
Codex + Claude independent research
↓
Hypothesis A / B
↓
Candidate A / B
↓
Cross Review
↓
Optional Hybrid Candidate C
↓
MetaEditor Compile
↓
MT5 Real Tick
↓
Candidate VS Current Champion
↓
No clear win
→ REJECT / KEEP CURRENT CHAMPION / RESEARCH FURTHER

Clear win
↓
OOS
↓
Walk Forward
↓
Stress Test
↓
Risk + Portfolio Audit
↓
Still clearly better
↓
NEW ENGINE CHAMPION
↓
Rebuild 3-SOP Combined Candidate
↓
Full Combined Real Tick + OOS + Portfolio Audit
↓
Beat Current Combined Champion?
├─ NO  -> keep Current Combined Champion; retain new Engine Champion
└─ YES -> NEW 3-SOP COMBINED CHAMPION
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

## 32. Final decision authority

Codex、Claude Code、GitHub Research、外部 EA 都没有最终裁决权。

最终裁决来自：

```text
Code Correctness
+
Fair Candidate VS Champion
+
MT5 Real Tick
+
OOS
+
Walk Forward when required
+
Stress Test
+
Risk Audit
+
Portfolio Audit
+
Champion Evaluation Order
```

最终评价顺序仍然固定：

```text
#1 Net Profit USD
#2 Max Equity Drawdown
#3 Profit Factor
#4 Trade Count
#5 Win Rate
```

但任何自动拒绝、Look-ahead、风险偷加、不可接受 DD、OOS 崩溃或执行异常都可以否决晋级。

---

## 33. Final principle

GSM SOP 负责：**怎么交易**。

AI / External / GitHub Research 负责：**还有什么值得测试**。

Codex + Claude Code 负责：**独立研究、设计、编码、交叉审查、实验、审计、归因**。

MetaEditor 负责：**证明源码可正确编译**。

MT5 Real Tick + OOS + Dual Broker + Walk Forward / Stress Test 负责：**证明 Candidate 是否具有可重复统计优势与稳健性**。

Champion System 负责：**决定最后留下哪个版本**。

核心制度：

```text
研究可以无限继续。
Champion 不能随便改变。

不是：
新版本不错就替换。

而是：
只有在公平条件下真正打赢旧 Champion，才允许替换。
```

任何新模块、任何 AI Candidate、任何外部 Research Idea 都必须遵守同一规则：

**Research first -> Independent Hypothesis -> Candidate -> Cross Review -> Evidence -> Champion only if proven.**
