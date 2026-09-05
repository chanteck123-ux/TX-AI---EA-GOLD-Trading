# GSM GOLD 3-SOP EA — Final Champion, Optimization, Single/Dual-AI Research & Program Governance System

## Authority

本文件是 GSM GOLD 3-SOP EA 的**最高层开发、优化、验证、AI Research、程序治理与 Champion 管理规范**。

若旧文档的指标顺序、Candidate 命名、Combined 假设、Research 处理方式、AI 协作方式或程序流程与本文件冲突，以本文件为准。

当前运行假设：已经存在经过正式验证的 `REAL CURRENT CHAMPION`：

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

```text
#1 Net Profit USD
#2 Max Equity Drawdown
#3 Profit Factor
#4 Trade Count
#5 Win Rate
```

`Reject` 目标必须为 0。Max Equity Drawdown 具有风险否决权，不能用更高 Net 自动覆盖不可接受的回撤。

---

# 1. Highest-level architecture

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
  ├─ SINGLE-AI MODE
  │    ├─ CODEX
  │    └─ CLAUDE CODE
  ├─ DUAL-AI MODE
  │    ├─ CODEX
  │    ├─ CLAUDE CODE
  │    └─ CODEX + CLAUDE HYBRID
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

GSM SOP 决定“什么是有效交易逻辑”。AI / GitHub / 外部 EA Research 只负责提供“值得测试的 Candidate Idea”。未经独立验证不得直接写入 Champion。

---

# 2. Four Champion lines

1. `SCALPING_CHAMPION`：M5 Scalping 单独开启。
2. `INTRADAY_CHAMPION`：M30 Intraday 单独开启。
3. `SWING_CHAMPION`：D1/H4/M30 Swing 单独开启。
4. `COMBINED_CHAMPION`：三个已锁定单策略 Champion 重新组合后的完整 EA。

任何时候都必须可以明确回答：

```text
Current Scalping Champion = ?
Current Intraday Champion = ?
Current Swing Champion = ?
Current Combined Champion = ?
```

禁止同一条 Champion Line 同时存在两个正式 Champion。

每个 Champion 必须可追踪：

- Version
- Source SHA256
- SET SHA256
- Broker
- Symbol
- Capital
- Risk Budget
- Actual Risk
- Real Tick Period
- OOS Period
- Metrics
- Final Report

Combined 盈利不能证明三个策略都优秀；三个单策略盈利也不能证明 Combined 一定优秀。

---

# 3. Candidate names and provenance

标准 Candidate ID：

| Lane | Candidate | Canonical Branch |
|---|---|---|
| Scalping | `S-C01` | `research/scalping/<origin>/<topic>` |
| Intraday | `I-C01` | `research/intraday/<origin>/<topic>` |
| Swing | `W-C01` | `research/swing/<origin>/<topic>` |
| Combined | `C-C01` | `research/combined/<origin>/<topic>` |

`origin`：

```text
user
codex
claude
single-ai
hybrid
external
```

Candidate 来源必须记录：

```text
USER_SOP_OPTIMIZATION
CODEX
CLAUDE
SINGLE_AI
CODEX_CLAUDE
EXTERNAL_RESEARCH
```

来源不改变判定标准。

Research ID 只代表 Idea / Research Record，不代表源码已实现或回测通过。

---

# 4. GSM SOP 与 Research 严格分离

GSM SOP 属于：

```text
AUTHORITATIVE STRATEGY FOUNDATION
```

Research 属于：

```text
EXPERIMENTAL / EXTERNAL RESEARCH SOURCE
```

AI 可以：

- 优化 GSM SOP 的程序实现
- 找 SOP 实现错误
- 建立 Candidate
- 提出新 Entry / Exit 假设
- 提出指标 / 风控 / 执行模块
- 找错单、漏单、不开单原因

但不能：

```text
Research Idea
→ 直接改正式 Champion
```

必须：

```text
Research Idea
↓
Candidate
↓
Candidate VS Champion
↓
严格验证
↓
只有真正胜出才晋级
```

若 Candidate 改变 GSM Base SOP，必须明确记录：

```text
GSM_BASE_SOP_CHANGED = YES / NO
```

---

# 5. Strategy lanes

## 5.1 SCALPING M5

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

BUY：

```text
Valid Demand
+
First Touch / Retest
+
Bullish Reversal
```

SELL：

```text
Valid Supply
+
First Touch / Retest
+
Bearish Reversal
```

可研究：

- Candle Quality
- Spread Cost Gate
- Entry Quality
- Real Tick Robustness
- Regime Filter
- ATR
- Market Structure
- Liquidity
- Execution Timing
- Cost-aware Exit

不设人为每日硬上限；禁止为了增加 Trades 制造无效交易。

## 5.2 INTRADAY M30

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

原则：积极寻找有效机会；一天 0 单允许；禁止为了每天 1 单强迫交易。

以下只能作为 Candidate：

- M15 Confirmation
- M5 Confirmation
- Any 2 of 3
- 3 of 3
- EMA
- BOS
- CHoCH
- FVG
- Order Block
- Liquidity
- Candlestick Confirmation
- ATR Stop
- Structure Stop
- Session Filter
- VWAP
- Volume
- AI Score

## 5.3 SWING

Swing 正式 Base 以当前已验证 Champion Code / Authoritative SOP 为准；Research Lab 不凭空重写 Swing Base。

研究范围可包括：

- D1 Framework
- H4 Trend
- S/R
- S&D
- Pullback
- Candlestick
- Structure
- SMC
- Trailing / Protection
- ATR
- Fibonacci

未被研究的两个 Strategy Champions 必须锁定；源码与参数不得顺手修改。

---

# 6. Fair Candidate VS Champion protocol

每个 Candidate 原则上只改变一个主要变量，且只开启对应策略。

Champion 与 Candidate 必须保持：

- Same Broker / Data Source
- Same Symbol
- Same Capital
- Same Leverage
- Same Real Tick Period
- Same Tester Model
- Same Spread / Commission
- Same Slippage assumptions
- Same Risk Budget
- Same Position Sizing Rules
- Same Session Conditions
- Same base execution settings

每个 Broker 固定输出：

| Version | Net USD | Max Equity DD | PF | Trades | Win Rate | Reject |
|---|---:|---:|---:|---:|---:|---:|

并输出：

- Delta Net
- Delta DD
- Delta PF
- Delta Trades
- Delta Win Rate

Training 用于选参数；OOS 只用于验证。读取 OOS 后不得回头调参并继续把同一段称为 OOS。

## Risk-normalized comparison

禁止：

```text
Candidate 用更高 Risk / Lot
Champion 用更低 Risk / Lot
然后只比较 Net Profit
```

若风险不同，必须先做：

```text
RISK-NORMALIZED COMPARISON
```

并报告 Requested Risk 与 Actual Risk。

---

# 7. Champion evaluation

正式优先级：

1. Net Profit USD
2. Max Equity Drawdown
3. Profit Factor
4. Trade Count
5. Win Rate

辅助读取：

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

Win Rate 不得独立评价。

```text
TEST PASS
≠
BEAT CHAMPION
```

Candidate 自己赚钱，不等于可以替换 Champion。

若结果只是接近：

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

# 8. Combined candidate

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

组合变差时：

- 新 Engine Champion 继续保留。
- Current Combined Champion 继续锁定。
- 只建立新的 `C-Cxx` 研究 Portfolio Risk。
- 不回写已锁定 Engine 逻辑。

---

# 9. External EA / GitHub / AI Research boundary

外部 EA、GitHub 项目、截图参数、第三方模型解读、Codex / Claude 新想法全部属于 Research Layer。

外部来源流程：

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

没有源码时，参数名不能被脑补成内部状态机。

研究来源包括：

- `docs/EXTERNAL_EA_TEST_2_41_RESEARCH_CN.md`
- `docs/GSM_GOLD_AI_RESEARCH_LAB_CN.md`
- `docs/GSM_GOLD_SINGLE_AI_RESEARCH_LAB_CN.md`

---

# 10. External Research Modules from EA 2.41

## A. Fast Adverse Move Guard

目标：处理“刚进场后很短时间内就迅速证明错误”的情况，而不是机械等待固定 SL。

禁止直接复制固定 `120秒 / 50点 / 20点`。

Candidate 示例：

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

Scalping、Intraday、Swing 参数必须分别测试。

## B. Recovery / Resume State Machine

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

状态尽量少；状态变化必须日志化；记录 trigger reason / timestamp / price / strategy / direction；MT5 / VPS 重启后必须可重建。

## C. Direction Basket Risk

统一计算：

```text
BUY_Basket_Floating_PnL
SELL_Basket_Floating_PnL
BUY_Total_Open_Risk
SELL_Total_Open_Risk
BUY_Total_Lots
SELL_Total_Lots
```

一个方向达到风险上限时，可以研究只冻结该方向；另一个方向仍需 Portfolio Conflict Check。

## D. Daily Account Circuit Breaker

支持 Candidate：

- DailyProfitLimitUSD
- DailyLossLimitUSD
- DailyLossPercent
- DailyEquityDrawdownPercent

必须明确 Balance / Equity 基准、Reset 时间、Broker Server Time、是否只阻止 New Entry、Existing Positions 是否继续管理、何时恢复。

## E. Optional Evidence Voting

禁止把所有指标做成巨大 AND。

```text
Core GSM SOP = Trade Eligibility

Optional Evidence = Quality Evidence
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
Pass / Reject / Risk Multiplier / Position Size Tier
```

核心原则：SOP 决定有没有交易资格；Optional Evidence 只衡量证据强弱。

## F. ADX + DI

- ADX = Trend Strength
- +DI / -DI = Directional Evidence

## G. ATR-normalized FVG Quality

```text
ValidFVG = FVG_Size >= ATR × MinFvgAtrRatio
```

FVG 永远属于 Optimization Layer；未经 Real Tick A/B 证明，不得替代 GSM Supply/Demand Base Zone。

---

# 11. Point / Pip / Price / Money conversion rule

禁止硬编码“100 points 永远等于 X 美元”。

必须读取：

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

程序必须记录：

- Raw points
- Price distance
- Lot
- Requested Risk USD / %
- Actual Risk USD / %

---

# 12. Program flow with research hooks

## OnInit

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

## OnTick

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

# 13. Trade Audit and Missed Opportunity Audit

所有新模块必须留下 Blocked Reason / Trigger Reason。

建议至少包括：

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

- NO VALID SETUP
- VALID SETUP BLOCKED BY RESEARCH MODULE
- PROGRAM MISSED VALID SETUP

否则无法判断 Candidate 是提高质量还是单纯减少交易。

---

# 14. AI Research operating modes

最高层规范支持两种合法 AI 研究模式：

```text
MODE A — SINGLE AI
MODE B — DUAL AI
```

两种模式的 Champion 判定标准完全相同。

不能因为使用两个 AI 就降低证据要求，也不能因为只使用一个 AI 就跳过审查。

---

# 15. SINGLE-AI MODE

单 AI 可以使用：

```text
Codex
或
Claude Code
```

架构不绑定品牌，统一角色：

```text
SINGLE AI RESEARCH ENGINEER
```

它同时承担：

- Strategy Researcher
- MQL5 Developer
- Code Reviewer
- Debugger
- Backtest Analyst
- Risk Reviewer
- Optimization Researcher

## Single-AI 最大风险

```text
自己开发
+
自己审查
+
自己宣布自己正确
```

因此单 AI **必须强制分阶段**，不得一次生成后直接 PASS。

```text
PHASE 1 — RESEARCHER
↓
PHASE 2 — DEVELOPER
↓
PHASE 3 — SELF CODE REVIEWER
↓
PHASE 4 — RED TEAM REVIEWER
↓
PHASE 5 — MT5 DATA ANALYST
↓
PHASE 6 — CHAMPION JUDGE
```

每个阶段必须重新读取事实、代码和测试结果，不得只继承上一阶段的主观结论。

---

# 16. Single-AI Research Phase

Research Phase 首先只研究，不改 Production。

必须输出：

```text
Research ID
AI Model
Engine
Current Champion
Observed Problem
Evidence
Hypothesis
Expected Benefit
Expected Risk
Files Likely Affected
SOP Impact
Experiment Plan
```

未经实验不得修改 Current Champion。

---

# 17. Single-AI Development Phase

研究假设批准进入实验后：

```text
Champion Snapshot
↓
Create Candidate Branch / Candidate File
↓
只修改实验需要内容
↓
保留所有其它测试条件
```

要求：

- 最小必要修改
- 修改原因可追踪
- 不偷偷改 Risk / Lot
- 不顺便重写无关逻辑
- 不覆盖 Current Champion

---

# 18. Single-AI Self Code Review

同一个 AI 写完代码后必须切换 Reviewer 身份重新检查。

至少检查：

1. 重复进场
2. 漏单
3. 未收盘 K 线
4. Look-ahead
5. CopyBuffer / CopyRates
6. Timeframe
7. Position / Order / Deal
8. Magic Number
9. Hedging / Netting
10. SL / TP normalization
11. Stops Level / Freeze Level
12. Spread / Slippage
13. Risk / Lot calculation
14. Volume min / max / step
15. 是否误改其它 Engine
16. 是否改变 GSM Base SOP
17. 是否加入隐藏风险
18. 是否存在明显 Overfitting 路径
19. 是否完整记录 Broker Reject / Retcode
20. Recovery / Freeze state 是否可重建

Review 结果只允许：

```text
PASS
或
FAIL + FIX LIST
```

Critical Finding 未关闭不得进入下一阶段。

---

# 19. Single-AI Red Team Review

Red Team 阶段必须假设：

```text
Candidate 可能是错的
```

目标不是证明 Candidate 好，而是**尽量把它推翻**。

必须主动检查：

- 利润是不是来自更高 Risk？
- Drawdown 是否恶化？
- 是否只适合某一年？
- 是否牺牲交易质量换 Trades？
- 是否只优化 BUY 或 SELL？
- 是否对 Spread 太敏感？
- 是否对 Slippage 太敏感？
- 参数轻微变化是否崩溃？
- 是否减少真实市场可执行性？
- 是否只是 Backtest Noise？
- 是否存在不可解释利润？
- 是否使用未来数据？

Red Team 推不翻，才进入数据验证阶段。

---

# 20. Single-AI Final Loop

```text
START
↓
Load Current Champion Registry
↓
Select Engine
↓
Read GSM Authoritative SOP
↓
Read Current Champion Code + Metrics
↓
RESEARCH PHASE
↓
Generate Hypothesis
↓
Create Candidate
↓
DEVELOPMENT PHASE
↓
Compile
↓
SELF CODE REVIEW
↓
RED TEAM REVIEW
↓
MT5 Real Tick
↓
Candidate VS Champion
↓
WIN?
├─ NO
│  ↓
│ REJECT / KEEP CURRENT CHAMPION / RESEARCH FURTHER
│
└─ YES
   ↓
   OOS
   ↓
   Walk Forward
   ↓
   Stress Test
   ↓
   Risk Audit
   ↓
   STILL WIN?
   ├─ NO → Current Champion unchanged
   └─ YES
      ↓
      NEW ENGINE CHAMPION
      ↓
      Rebuild 3-SOP Combined Candidate
      ↓
      Combined Candidate VS Current Combined Champion
      ↓
      WIN → NEW 3-SOP COMBINED CHAMPION
```

单 AI 模式下，`Self Review` 和 `Red Team` 都是强制关卡，不得省略。

---

# 21. DUAL-AI MODE roles

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

两边都可以独立研究、开发、修 BUG、重构、分析日志、提出 Candidate、审查对方和反驳对方结论。

AI 没有最终裁决权；它们是 Research / Engineering Agents。

---

# 22. Independent Dual-AI Research Protocol

默认要求 Codex 与 Claude Code **先独立研究，再交换结论**，避免互相锚定。

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
                 PASS? → Promotion Review
```

Hybrid Candidate 也必须能说明每个变化来自哪里，禁止把 A+B 所有想法一次性堆叠而失去归因能力。

---

# 23. Cross Code Review and Quantitative Audit

Dual-AI 模式：Codex 审 Claude，Claude 也审 Codex。

Single-AI 模式：同一 AI 通过 Self Review + Red Team 完成独立阶段审查。

统一最低审查清单：

1. 是否重复进场
2. 是否漏单
3. 是否错误使用未收盘 K 线
4. 是否 Look-ahead
5. CopyBuffer / CopyRates
6. Timeframe
7. Position / Order / Deal
8. Magic Number
9. Hedging / Netting
10. SL / TP normalization
11. Stops Level / Freeze Level
12. Spread / Slippage
13. Risk / Lot calculation
14. Volume min / max / step
15. 是否误改其它 Engine
16. 是否改变 GSM Base SOP；若改变是否披露
17. 是否存在 Overfitting
18. 是否为了利润偷偷提高风险
19. 是否改变测试条件美化结果
20. 是否存在无法解释利润
21. Broker Reject / Retcode 是否完整记录
22. Freeze / Recovery 状态是否可重建

任何 Critical Finding 未关闭前不得晋级 Champion。

---

# 24. Candidate Promotion Gate

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

Candidate 自己盈利只能说明有研究价值，不代表 New Champion。

---

# 25. Automatic Reject Rules

以下任一项成立：

- Future Data
- Look-ahead
- 偷偷增加 Lot
- 偷偷提高 Risk %
- 删除核心 SL
- 增加隐性 Martingale / Grid Tail Risk
- 增加未披露最大持仓
- 挑选回测区间美化结果
- 删除亏损阶段
- 降低 Commission / Spread 美化 Candidate
- 不同测试条件比较 Champion
- 用巨大 Equity DD 换 Net Profit
- 单一区间严重 Overfitting
- 隐藏 Broker Reject / Execution Failure
- OOS 后重新调参并继续称同一段为 OOS
- 无法解释的异常利润
- 核心验证数据缺失

统一：

```text
AUTOMATIC REJECT
```

---

# 26. Experiment Registry

每个实验必须保存：

```text
Experiment ID
Research Mode (SINGLE_AI / DUAL_AI / USER / EXTERNAL)
AI Model(s)
Engine
Candidate Version
Candidate Origin
Current Champion Version
Strategy Source
Research Hypothesis
Observed Evidence
Modified Files
Modified Rules
GSM Base SOP Changed (YES/NO)
Risk Budget
Actual Risk
Test Protocol
Broker / Symbol / Date Range
Champion Metrics
Candidate Metrics
Delta Metrics
Self Review Result
Red Team Result
Codex Review
Claude Review
OOS Result
Walk Forward Result
Stress Test Result
Audit Result
Blocked / Trigger Reasons
Final Verdict
Promotion Decision
Reason
```

不适用的 Review 字段写 `N/A`，不得伪造。

Final Verdict 只允许：

```text
REJECT
KEEP CURRENT CHAMPION
RESEARCH FURTHER
NEW ENGINE CHAMPION
NEW 3-SOP COMBINED CHAMPION
```

---

# 27. Champion Lock and History

每个 Strategy Champion 与 Combined Champion 都必须保留：版本、源码哈希、SET 哈希、测试条件和指标。

只有同条件 Candidate 真正打赢它，才能解除锁定。

历史链：

```text
Previous Champion
↓
Candidate
↓
New Champion
```

旧 Champion 永不删除。

---

# 28. Git / Version Isolation

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

失败 Candidate 不保存大型 ZIP，只保存 Markdown / CSV 摘要。

新 Champion 晋级：

```text
Old Current Champion
→ champion/history/

Winning Candidate
→ champion/current/
```

必须保留完整 lineage。

---

# 29. Delivery ZIP

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

FINAL_REPORT 首页依次显示 Best Scalping、Best Intraday、Best Swing、Best Combined：

```text
Net -> Max Equity DD -> PF -> Trades -> Win Rate -> Reject
```

用户收到的 ZIP 与 GitHub `champion/current/` 必须是同一文件；文件名、版本、SHA256 和报告指标完全一致。

---

# 30. Final Universal Champion Loop

研究入口可以来自 User、Single AI、Dual AI、External / GitHub。

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
SELECT RESEARCH MODE
↓
FORM TESTABLE HYPOTHESIS
↓
BUILD ONE CANDIDATE
↓
COMPILE
↓
REQUIRED REVIEW GATE
  ├─ SINGLE AI: SELF REVIEW + RED TEAM
  └─ DUAL AI: CROSS REVIEW
↓
MT5 REAL TICK
↓
TRAIN / OOS
↓
FXPRO / TRADONA
↓
WALK FORWARD / STRESS if required
↓
RISK + PORTFOLIO AUDIT
↓
COMPARE WITH CURRENT ENGINE CHAMPION
```

失败：

```text
REJECT / KEEP CURRENT CHAMPION / RESEARCH FURTHER
↓
SAVE RESEARCH SUMMARY
↓
DO NOT TOUCH CHAMPION
```

成功：

```text
NEW ENGINE CHAMPION
↓
LOCK IT
↓
REBUILD 3-SOP COMBINED CANDIDATE
↓
FULL COMBINED REAL TICK + OOS
↓
PORTFOLIO AUDIT
↓
COMPARE WITH CURRENT COMBINED CHAMPION
↓
IF BETTER → NEW 3-SOP COMBINED CHAMPION
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

# 31. Final Decision Authority

Codex、Claude Code、Single AI、Dual AI、GitHub Research、外部 EA 都没有最终裁决权。

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

任何 Automatic Reject、Look-ahead、风险偷加、不可接受 DD、OOS 崩溃或执行异常都可以否决晋级。

---

# 32. Final Principle

GSM SOP 负责：**怎么交易**。

AI / External / GitHub Research 负责：**还有什么值得测试**。

Single-AI 模式负责：**在只有一个 AI 时，用阶段隔离 + Self Review + Red Team 降低自我确认偏差**。

Dual-AI 模式负责：**独立研究 + 交叉审查 + 可选 Hybrid Candidate**。

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

所有 Research Mode、所有新模块、所有 AI Candidate 都遵守同一规则：

**Research first -> Testable Hypothesis -> Candidate -> Required Review -> Evidence -> Champion only if proven.**
