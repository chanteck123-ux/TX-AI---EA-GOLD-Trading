# GSM GOLD 3-SOP EA — 最终 Champion、优化制度、可选 AI 研究制度与程序治理总规范

## 0. 文件权威与当前假设

本文件是 GSM GOLD 3-SOP EA 的**最高层开发、优化、验证、研究、程序治理与 Champion 管理规范**。

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
#1 净利润 Net Profit USD
#2 最大净值回撤 Max Equity Drawdown
#3 盈利因子 Profit Factor
#4 交易数 Trade Count
#5 胜率 Win Rate
```

`Reject` 目标必须为 0。

`Max Equity Drawdown` 具有风险否决权：不能只因为 Net Profit 更高，就自动接受不可接受的回撤、保证金压力或爆仓风险。

---

# 1. 最高层系统架构

```text
GSM SOP 权威基础
        ↓
3 个独立策略引擎
  ├─ SCALPING M5
  ├─ INTRADAY M30
  └─ SWING D1/H4/M30
        ↓
可选优化 / 研究模块
        ↓
信号 / 证据 / 置信度
        ↓
风险引擎 Risk Engine
        ↓
组合管理 Portfolio Manager
        ↓
执行引擎 Execution Engine
        ↓
MT5
        ↓
真实 Tick Real Tick
        ↓
训练区间 TRAIN / 样本外 OOS
        ↓
FxPro / Tradona
        ↓
需要时：Walk Forward / Stress Test
        ↓
交易审计 + 漏单审计
        ↓
Candidate VS Champion
        ↓
REJECT / KEEP CURRENT CHAMPION / RESEARCH FURTHER / NEW CHAMPION
```

GSM SOP 决定“什么是有效交易逻辑”。

GitHub、外部 EA、AI 或其它 Research 只负责提供“值得测试的 Candidate Idea”。任何 Research 逻辑未经独立验证，不得直接进入 Champion。

---

# 2. 四条 Champion 主线

系统永久维护四条独立 Champion Line：

1. `SCALPING_CHAMPION`：M5 Scalping 单独开启。
2. `INTRADAY_CHAMPION`：M30 Intraday 单独开启。
3. `SWING_CHAMPION`：D1/H4/M30 Swing 单独开启。
4. `COMBINED_CHAMPION`：三个已锁定单策略 Champion 重新组合后的完整 3-SOP EA。

任何时候必须可以明确回答：

```text
Current Scalping Champion = ?
Current Intraday Champion = ?
Current Swing Champion = ?
Current Combined Champion = ?
```

同一条 Champion Line 禁止同时存在两个正式 Champion。

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

Combined 盈利不能证明三个 Engine 都优秀；三个 Engine 单独盈利也不能证明 Combined 一定优秀。

---

# 3. Candidate 命名与来源记录

标准 Candidate ID：

| 策略线 | Candidate | 建议 Branch |
|---|---|---|
| Scalping | `S-C01` | `research/scalping/<origin>/<topic>` |
| Intraday | `I-C01` | `research/intraday/<origin>/<topic>` |
| Swing | `W-C01` | `research/swing/<origin>/<topic>` |
| Combined | `C-C01` | `research/combined/<origin>/<topic>` |

`origin` 建议：

```text
user
standard
codex
claude
single-ai
hybrid
external
github
```

Candidate 来源必须记录，例如：

```text
USER_SOP_OPTIMIZATION
STANDARD_RESEARCH
CODEX
CLAUDE
SINGLE_AI
CODEX_CLAUDE
EXTERNAL_RESEARCH
GITHUB_RESEARCH
```

来源不改变判定标准。

Research ID 只代表研究记录，不代表源码已经实现、编译通过或回测通过。

---

# 4. GSM SOP 与 Research 必须严格分离

GSM SOP 属于：

```text
AUTHORITATIVE STRATEGY FOUNDATION
权威策略基础
```

Research 属于：

```text
EXPERIMENTAL / EXTERNAL RESEARCH SOURCE
实验 / 外部研究来源
```

Research 可以：

- 优化 GSM SOP 的程序实现
- 找出 SOP 实现错误
- 找错误进场
- 找漏单 / 不开单原因
- 建立 Candidate
- 提出新 Entry / Exit 假设
- 提出指标、风控、执行、Portfolio 模块

但不能：

```text
Research Idea
→ 直接修改正式 Champion
```

必须：

```text
Research Idea
↓
Candidate
↓
Candidate VS Champion
↓
公平验证
↓
真正胜出
↓
才允许晋级
```

如果 Candidate 改变 GSM Base SOP，必须明确记录：

```text
GSM_BASE_SOP_CHANGED = YES / NO
```

---

# 5. 三个策略引擎

## 5.1 SCALPING M5

核心流程：

```text
M5
↓
按 CURRENT PRICE DISTANCE 找当前最近有效 S&D
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

关键：

```text
Nearest Zone = 当前价格距离最近的有效 Zone
不是最近形成时间
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

---

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

以下全部只能先作为 Candidate：

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

全部必须 A/B Test，并与 Current Intraday Champion 公平比较。

---

## 5.3 SWING

Swing 正式 Base 以当前已验证 Champion Code / Authoritative SOP 为准；Research 不得凭空重写 Swing Base。

研究范围可以包括：

- D1 Framework
- H4 Trend
- Support / Resistance
- Supply / Demand
- Pullback
- Candlestick
- Market Structure
- SMC
- Trailing / Protection
- ATR
- Fibonacci

未被研究的另外两个 Strategy Champions 必须锁定；源码与参数不得顺手修改。

---

# 6. Candidate VS Champion 公平测试协议

每个 Candidate 原则上只改变一个主要变量，并且只开启对应 Engine。

Champion 与 Candidate 必须尽量保持：

- Same Broker / Data Source
- Same Symbol
- Same Capital
- Same Leverage
- Same Real Tick Period
- Same Tester Model
- Same Spread / Commission
- Same Slippage Assumption
- Same Risk Budget
- Same Position Sizing Rules
- Same Session Conditions
- Same Base Execution Settings

每个 Broker 固定输出：

| Version | Net USD | Max Equity DD | PF | Trades | Win Rate | Reject |
|---|---:|---:|---:|---:|---:|---:|

同时输出：

- Delta Net
- Delta DD
- Delta PF
- Delta Trades
- Delta Win Rate

Training 用于选参数；OOS 只用于验证。

读取 OOS 结果后，不得回头调参，再继续把同一段称为 OOS。

## 6.1 风险标准化比较

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

并报告：

- Requested Risk
- Actual Risk
- Lot
- SL Distance
- Margin Usage

---

# 7. Champion 核心评价制度

正式优先级固定：

```text
1. Net Profit USD
2. Max Equity Drawdown
3. Profit Factor
4. Trade Count
5. Win Rate
```

辅助必须读取：

- Return % on Initial Capital
- Max Equity Drawdown USD
- Max Equity Drawdown %
- Balance Drawdown（只作辅助背景）
- Relative Drawdown
- Average Win
- Average Loss
- Realized Average R:R
- Expected Payoff / Expectancy
- Break-even Win Rate
- Recovery Factor
- Long Win Rate / Short Win Rate
- BUY Performance / SELL Performance
- Maximum Consecutive Losses
- Spread / Commission / Slippage Sensitivity
- OOS Performance
- Walk Forward Stability
- Parameter Robustness
- Market Regime Performance

Win Rate 不得独立评价。

## 7.1 Net Profit 必须同时换算资金回报率

不能只看绝对 Net Profit。

每份报告必须计算：

```text
Return % = Net Profit USD / Initial Capital × 100
```

大资金账户赚到小金额，策略可能在统计上仍然为正，但商业意义可能很弱。因此必须同时报告 `Net Profit USD` 和 `Return %`。

这不会改变正式 Champion 排名。`Net Profit USD` 仍然是 #1，`Return %` 是强制解释指标。

## 7.2 Profit Factor 解释规则

Profit Factor 必须结合交易样本数、DD、OOS、成本和参数稳定性一起解释。

建议诊断参考区间：

```text
PF < 1.00      = 测试样本内亏损
PF 1.00-1.20   = 边际 / 偏弱
PF 1.20-1.50   = 可用，但必须继续验证稳健性
PF 1.50-2.00   = 若样本充足且 OOS 支持，属于较强
PF > 2.00      = 很强，但必须更认真检查样本数和过拟合
PF > 2.50-3.00 = 不自动判定无效，但进入高强度审查
```

高 PF **本身不能证明过拟合**。当它同时伴随以下情况时，才需要高度怀疑：

- 交易数非常少
- 只在某一段有利行情特别强
- OOS 明显崩溃
- 参数轻微变化就失效
- Spread / Commission / Slippage 设置不现实
- Future Data / Look-ahead
- BUY / SELL 严重单边依赖

需要时标记：

```text
PF_OVERFIT_SUSPECT
```

## 7.3 Max Equity Drawdown 是主要回撤指标

必须优先看 `Equity Drawdown`，不能只看 Balance Drawdown，因为浮亏是真实经济风险。

强制输出：

```text
Max Equity DD USD
Max Equity DD %
Max Balance DD USD / %（辅助）
```

建议诊断参考区间：

```text
<= 15%     = 理想 / 控制良好
15%-30%    = 警戒区
> 30%      = 高风险区
> 50%      = 严重资本风险区
```

这些是风险诊断区间，不是所有策略一刀切的固定 Pass/Fail，除非 Champion mandate 明确指定硬阈值。

`Max Equity DD` 继续拥有风险否决权。

如果 Balance 与 Equity 差距过大，必须标记：

```text
BALANCE_EQUITY_DIVERGENCE
HIDDEN_FLOATING_LOSS_RISK
```

## 7.4 Trade Count 必须按策略类型判断

禁止对所有策略统一硬性要求 `>100 trades`。

建议证据目标：

```text
Scalping：最好 > 200；能做到 300-1000+ 更好
Intraday：最好 > 100
Swing：不要机械要求 > 100；应延长年份和市场状态
```

样本不足必须标记：

```text
LOW_SAMPLE_SIZE
LOW_SAMPLE_WINRATE
```

样本越少，就越需要更长区间、更多 Regime、OOS、Walk Forward 和双 Broker 验证。

## 7.5 Recovery Factor

```text
Recovery Factor = Net Profit / Maximum Drawdown Amount
```

建议解释：

```text
< 1.0   = 弱
1.0-2.0 = 边际
2.0-3.0 = 良好
> 3.0   = 强
```

`Recovery Factor > 3` 是理想目标，但**不是所有策略统一硬门槛**。必须和 DD、样本数、OOS、策略类型一起判断。

## 7.6 Expected Payoff 与成本覆盖

Expected Payoff 必须为正，而且必须能承受真实交易成本。

特别是 Scalping，必须报告：

```text
Expected Payoff / Trade
Average Spread Cost / Trade
Average Commission / Trade
Estimated Slippage Cost / Trade
Total Estimated Cost / Trade
Edge-to-Cost Ratio
```

可行时：

```text
Edge-to-Cost Ratio = Expected Payoff / Estimated Total Cost per Trade
```

成本缓冲越大越好。对于成本敏感策略，可以把 3x-5x 成本缓冲作为强参考目标，但不能一刀切，因为 Broker、Symbol 和成本单位不同。

需要时标记：

```text
EXPECTED_PAYOFF_TOO_SMALL
SPREAD_COST_EDGE_TOO_SMALL
```

## 7.7 Balance 与 Equity 完整性检查

如果 Balance 曲线很漂亮，但 Equity 多次大幅跌到 Balance 下方，必须检查：

- 长时间扛大浮亏
- Grid
- Martingale
- 延迟实现亏损
- 只靠 Recovery 才退出
- 接近 Margin Call

Balance 数据漂亮但 Equity 压力严重的策略，在没有完整 Tail Risk 证据前不得通过 Champion 审核。

```text
TEST PASS
≠
BEAT CHAMPION
```

Candidate 自己赚钱，不等于可以替换 Champion。

如果结果只是接近：

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

# 8. Win Rate / Expectancy / 实际盈亏比验证标准

MT5 中的胜率通常显示为：

```text
Profit Trades (% of total)
```

Win Rate 是诊断指标，不是独立证明策略质量的指标。高胜率可以同时伴随负 Expectancy、差盈亏比、隐藏 Tail Risk，或严重单边市场依赖。

## 8.1 MT5 必须同时读取的指标

每个 Champion 与 Candidate 报告，Win Rate 至少必须和以下字段一起读取：

```text
Profit Trades (% of total)
Average profit trade
Average loss trade
Long Positions (won %)
Short Positions (won %)
Maximum consecutive losses
```

若报告提供，也应保留 Maximum consecutive wins、Gross Profit / Gross Loss，以及 BUY / SELL 各自交易数。

## 8.2 核心公式

```text
Expectancy =
(Win Rate × Average Win)
-
(Loss Rate × abs(Average Loss))
```

```text
Realized Average R:R =
Average Profit Trade
/
abs(Average Loss Trade)
```

定义：

```text
R = Average Win / abs(Average Loss)
```

理论 Break-even Win Rate：

```text
Break-even Win Rate = 1 / (1 + R)
```

例子：

```text
1:1 → 50.0%
2:1 → 33.3%
3:1 → 25.0%
```

理论 R:R 和实际平均 R:R 如果不同，必须分别报告。Champion 评价更重视真实成交后的 Realized R:R，而不是名义 SL/TP。

## 8.3 不同策略类型的胜率解释

以下只作诊断参考，不是统一硬性晋级阈值：

| 策略类型 | 常见胜率表现 | 常见收益结构 | 主要风险 |
|---|---:|---:|---|
| Trend / Breakout | 通常较低，例如 35%-45% | 常见 2:1、3:1 或更高 | 连亏、Regime 依赖 |
| Scalping / Range | 通常较高，例如 65%-80% | 常见接近 1:1 或更低 | 点差、手续费、滑点、延迟 |
| Grid / Martingale | 可能 85%-95%+ | 小赢很多次、偶尔一次大亏 | Tail Loss / Margin Failure |

非常高的胜率不等于好。90%+ 胜率但严重负偏态的系统，可能明显差于 40%-50% 胜率但 Realized R:R 和 Expectancy 健康的系统。

## 8.4 BUY / SELL 分方向审计

每个 Engine 报告应分别输出：

```text
BUY Trades
BUY Win Rate
BUY Net Profit
BUY Profit Factor
SELL Trades
SELL Win Rate
SELL Net Profit
SELL Profit Factor
```

BUY / SELL 差异过大时，先调查而不是自动否决。必须判断原因是否来自：

- Market Regime
- Sample 太少
- Strategy Logic 不对称
- Coding Defect
- 单边结构依赖

需要时标记：

```text
ONE_SIDE_DEPENDENCY
```

## 8.5 连续亏损压力测试

`Maximum Consecutive Losses` 必须与 `Max Equity DD` 和 Risk per Trade 一起看。

强制压力序列：

```text
Historical Max Consecutive Losses = N
Stress Case 1 = N + 2
Stress Case 2 = N + 4
```

检查：

- projected DD
- free margin
- margin level
- position sizing survival
- recovery requirement
- account ruin risk

标记：

```text
LOSS_STREAK_RISK
```

## 8.6 Win Rate 强制诊断 Flag

有证据时使用：

```text
HIGH_WINRATE_BAD_RR
NEGATIVE_EXPECTANCY
ONE_SIDE_DEPENDENCY
LOSS_STREAK_RISK
SPREAD_COST_EDGE_TOO_SMALL
LOW_SAMPLE_WINRATE
HIDDEN_TAIL_RISK
```

## 8.7 三个 Engine 的不同重点

```text
SCALPING
→ Win Rate + Realized R:R + Expected Payoff + Spread + Commission + Slippage + Delay

INTRADAY
→ 中等 Win Rate 可以接受，只要 Net + DD + PF + Expectancy 强

SWING
→ 低 Win Rate 可以接受，只要 Average Win 明显大于 Average Loss，且 DD 可控
```

## 8.8 Champion 详细报告强制字段

```text
Strategy
Net Profit USD
Return %
Max Equity DD USD
Max Equity DD %
Profit Factor
Recovery Factor
Trades
Win Rate
Average Win
Average Loss
Realized Average R:R
Break-even Win Rate
Expected Payoff / Expectancy per Trade
Maximum Consecutive Losses
Long Win Rate
Short Win Rate
BUY Net / PF
SELL Net / PF
Reject
Diagnostic Flags
```

最高层正式排名仍然不变：

```text
Net Profit USD
→ Max Equity Drawdown
→ Profit Factor
→ Trade Count
→ Win Rate
```

新增字段用于判断这个排名结果是否稳健、真实、具有经济意义。

## 8.9 MT5 Strategy Tester 稳健性测试规范

正式 Champion 验证必须使用：

```text
Every tick based on real ticks
```

除非某个测试明确标记为低精度诊断，否则不能用低精度模型冒充正式 Real Tick 证据。

Execution Robustness 必须测试现实交易摩擦。根据 Tester / Broker 能力，不能只用 `No Delay`，应加入多个 Delay / Slippage 场景。

参考 Delay 场景可以包括：

```text
10 ms
25 ms
50 ms
```

或者采用 Broker 实际更合理的随机延迟区间。这些只是压力情景，不是固定常数。

每个情景必须报告变化：

- Net Profit
- Max Equity DD
- PF
- Trades
- Win Rate
- Expected Payoff
- Reject / execution errors

需要时标记：

```text
DELAY_SLIPPAGE_FRAGILE
```

## 8.10 Train / OOS 规则

Training 数据只用于模型和参数选择。

OOS 数据只用于验证。

示例：

```text
Train: 较早区间
OOS: 后面完全未参与调参的区间
```

一旦读取 OOS 结果后再调参，就必须建立新实验；该已看过的区间不能继续被称为同一个 Candidate 的 untouched OOS。

需要时标记：

```text
OOS_COLLAPSE
OOS_CONTAMINATION
```

有潜力的 Candidate 还应根据需要继续做：Market Regime、Walk Forward、Cost Stress、Execution Stress、Parameter Neighborhood Stability，以及 Monte Carlo / Trade-order Randomization。

---

# 9. Combined Candidate 与 Portfolio 规则

任何 New Engine Champion 都必须触发新的 Combined Candidate。

Combined 必须重新编译并重新做双经纪商 Real Tick，不得把三个独立净利润相加，当作组合结果。

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
- 不回写已经锁定的 Engine 逻辑。

---

# 10. 外部 EA / GitHub / AI Research 边界

外部 EA、GitHub 项目、截图参数、第三方模型解读、AI 新想法全部属于 Research Layer。

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

# 11. 外部 EA 2.41 提炼出的研究模块

以下全部属于 Research Candidate，不是正式 GSM SOP，也不是默认 Champion 模块。

## 11.1 快速不利移动保护 Fast Adverse Move Guard

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

Scalping、Intraday、Swing 的参数必须分别测试。

## 11.2 熔断后恢复 Recovery / Resume State Machine

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

状态要求：

- 状态尽量少
- 状态变化必须日志化
- 记录 trigger reason / timestamp / price / strategy / direction
- MT5 / VPS 重启后必须可重建

## 11.3 方向篮子风险 Direction Basket Risk

统一计算：

```text
BUY_Basket_Floating_PnL
SELL_Basket_Floating_PnL
BUY_Total_Open_Risk
SELL_Total_Open_Risk
BUY_Total_Lots
SELL_Total_Lots
```

一个方向达到风险上限时，可以研究只冻结该方向；另一个方向仍需经过 Portfolio Conflict Check。

## 11.4 每日账户级熔断 Daily Account Circuit Breaker

可以研究：

- DailyProfitLimitUSD
- DailyLossLimitUSD
- DailyLossPercent
- DailyEquityDrawdownPercent

必须明确：

- Balance / Equity 基准
- Reset 时间
- Broker Server Time
- 是否只阻止 New Entry
- Existing Positions 是否继续管理
- 何时恢复

## 11.5 可选证据投票 Optional Evidence Voting

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

原则：

```text
SOP 决定有没有交易资格
Optional Evidence 只衡量证据强弱
```

## 11.6 ADX + DI 分工

- ADX = Trend Strength
- +DI / -DI = Directional Evidence

## 11.7 ATR 标准化 FVG Quality

```text
ValidFVG = FVG_Size >= ATR × MinFvgAtrRatio
```

FVG 永远属于 Optimization Layer；未经 Real Tick A/B 证明，不得替代 GSM Supply/Demand Base Zone。

---

# 12. Point / Pip / Price / Money 换算规则

禁止硬编码：

```text
100 points 永远 = 固定 X 美元
```

必须读取 Broker 实际规格：

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

- Raw Points
- Price Distance
- Lot
- Requested Risk USD / %
- Actual Risk USD / %

---

# 13. EA 程序主流程与 Research Hook

## 13.1 OnInit

```text
读取 Broker / Symbol / Account Mode
↓
读取 Contract Specs
↓
加载 Champion Inputs
↓
初始化 3 Strategy Engines
↓
初始化 Optional Evidence Modules
↓
初始化 Risk Engine
↓
初始化 Direction Basket Risk
↓
初始化 Daily Circuit Breaker
↓
恢复 Recovery / Freeze State
↓
初始化 Portfolio Manager
↓
初始化 Execution + Audit
```

## 13.2 OnTick

```text
更新市场数据
↓
更新 Account / Equity / Margin
↓
更新 BUY / SELL Basket Risk
↓
检查 Daily Account Circuit Breaker
↓
管理 Existing Positions
↓
检查 Fast Adverse Move Guard
↓
更新 Recovery / Freeze State
↓
运行 SCALPING ENGINE
↓
运行 INTRADAY ENGINE
↓
运行 SWING ENGINE
↓
收集 Core GSM Signals
↓
可选 Evidence Score / Votes
↓
处理 Signal Conflict
↓
Portfolio Risk Check
↓
Broker / Spread / Cost / Margin Check
↓
Execution
↓
记录 Order + State + Block Reason
↓
更新 Dashboard / Audit
```

所有 Research Hook 必须可以单独关闭，以便随时重新跑纯 Current Champion Baseline。

---

# 14. Trade Audit 与 Missed Opportunity Audit

所有新模块必须留下 `Blocked Reason / Trigger Reason`。

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
PF_OVERFIT_SUSPECT
BALANCE_EQUITY_DIVERGENCE
HIDDEN_FLOATING_LOSS_RISK
LOW_SAMPLE_SIZE
LOW_RECOVERY_FACTOR
EXPECTED_PAYOFF_TOO_SMALL
DELAY_SLIPPAGE_FRAGILE
OOS_COLLAPSE
OOS_CONTAMINATION
```

必须区分：

```text
NO VALID SETUP
VALID SETUP BLOCKED BY RESEARCH MODULE
PROGRAM MISSED VALID SETUP
```

否则无法判断 Candidate 是提高质量，还是单纯减少交易。

---

# 15. AI 研究制度是可选择的，不是强制流程

AI Research 不属于 GSM Base SOP，也不是 Champion 必须经过的固定流程。

正式参数：

```text
AI_RESEARCH_MODE = OFF
AI_RESEARCH_MODE = SINGLE_AI
AI_RESEARCH_MODE = DUAL_AI
```

无论选择哪一种模式，以下内容都不能改变：

- GSM SOP 权威地位
- Candidate VS Champion 制度
- Fair Test Protocol
- Real Tick
- Train / OOS
- FxPro / Tradona
- Risk Rules
- Portfolio Audit
- Champion Evaluation Order

AI 只决定：

```text
研究与审查由谁、用什么方式完成
```

AI 不决定最终 Champion。

---

# 16. AI_RESEARCH_MODE = OFF

不使用 Single-AI / Dual-AI Research Lab。

流程：

```text
GSM SOP
↓
Current Champion
↓
Trade Audit / Missed Audit
↓
Research Hypothesis
↓
Candidate
↓
Compile
↓
Standard Code Audit
↓
MT5 Real Tick
↓
Train / OOS
↓
FxPro / Tradona
↓
Candidate VS Champion
```

此模式不强制：

- Single-AI Self Review
- Single-AI Red Team
- Dual-AI Cross Review

但仍必须满足代码正确、公平测试、风险审计和 Champion 晋级标准。

---

# 17. AI_RESEARCH_MODE = SINGLE_AI

可以选择：

```text
Codex
或
Claude Code
```

架构不绑定品牌，统一角色：

```text
SINGLE AI RESEARCH ENGINEER
```

它可以同时承担：

- Strategy Researcher
- MQL5 Developer
- Code Reviewer
- Debugger
- Backtest Analyst
- Risk Reviewer
- Optimization Researcher

单 AI 最大风险：

```text
自己开发
+
自己审查
+
自己宣布自己正确
```

因此启用 `SINGLE_AI` 时，必须强制分阶段：

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

## 17.1 Single-AI Research Phase

首先只研究，不改 Production。

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

## 17.2 Single-AI Development Phase

```text
Champion Snapshot
↓
Create Candidate Branch / Candidate File
↓
只修改实验需要内容
↓
保留其它测试条件
```

要求：

- 最小必要修改
- 修改原因可追踪
- 不偷偷改 Risk / Lot
- 不顺便重写无关逻辑
- 不覆盖 Current Champion

## 17.3 Single-AI Self Code Review

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
19. Broker Reject / Retcode 是否完整记录
20. Recovery / Freeze State 是否可重建

Review 结果只允许：

```text
PASS
或
FAIL + FIX LIST
```

Critical Finding 未关闭不得进入下一阶段。

## 17.4 Single-AI Red Team

Red Team 必须假设：

```text
Candidate 可能是错的
```

主动检查：

- 利润是否来自更高 Risk
- DD 是否恶化
- 是否只适合某一年
- 是否牺牲质量换 Trades
- 是否只优化 BUY 或 SELL
- Spread 是否过度敏感
- Slippage 是否过度敏感
- 参数轻微变化是否崩溃
- 是否降低真实市场可执行性
- 是否只是 Backtest Noise
- 是否存在不可解释利润
- 是否使用未来数据

Red Team 不是证明 Candidate 好，而是尽量把它推翻。

---

# 18. AI_RESEARCH_MODE = DUAL_AI

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

默认协议：先独立研究，再交换结论，避免相互锚定。

```text
CURRENT CHAMPION
        │
        ├───────────────┐
        │               │
        ▼               ▼
     CODEX            CLAUDE
   独立研究            独立研究
 Hypothesis A       Hypothesis B
        │               │
        ▼               ▼
 Candidate A        Candidate B
        │               │
        └──────┬────────┘
               ▼
            交叉审查
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
```

Hybrid Candidate 必须说明每个变化来自哪里，禁止把 A+B 所有想法一次性堆叠，导致无法归因。

---

# 19. 统一 Code Review 与量化审计清单

不论 Research 来源，最低审查清单：

1. 是否重复进场
2. 是否漏单
3. 是否错误使用未收盘 K 线
4. 是否 Look-ahead
5. CopyBuffer / CopyRates 是否正确
6. Timeframe 是否正确
7. Position / Order / Deal 是否混淆
8. Magic Number 是否隔离
9. Hedging / Netting 是否兼容
10. SL / TP normalization 是否正确
11. Stops Level / Freeze Level 是否满足 Broker 规格
12. Spread / Slippage 是否正确处理
13. Risk / Lot calculation 是否正确
14. Volume min / max / step 是否正确
15. 是否误改其它 Engine
16. 是否改变 GSM Base SOP；若改变是否披露
17. 是否存在 Overfitting
18. 是否为了利润偷偷提高风险
19. 是否改变测试条件美化结果
20. 是否存在无法解释利润
21. Broker Reject / Retcode 是否完整记录
22. Freeze / Recovery 状态是否可重建
23. Real Tick Model 是否正确
24. Equity 与 Balance 是否异常分叉
25. 样本数是否适合该策略类型
26. 是否发生 OOS Contamination
27. Delay / Slippage 是否过度敏感
28. Expected Payoff 扣除成本后是否仍有优势

任何 Critical Finding 未关闭前，不得晋级 Champion。

---

# 20. Candidate 晋级门槛

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

Candidate 自己盈利，只能说明有研究价值，不代表 New Champion。

---

# 21. Automatic Reject 自动否决规则

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
- 使用不同测试条件比较 Champion
- 用巨大 Equity DD 换 Net Profit
- 单一区间严重 Overfitting
- 隐藏 Broker Reject / Execution Failure
- OOS 后重新调参并继续称同一段为 OOS
- 无法解释的异常利润
- 核心验证数据缺失
- 正式 Champion 证据没有使用 Real Ticks，却没有明确标记为低精度诊断测试

统一：

```text
AUTOMATIC REJECT
```

---

# 22. Experiment Registry 实验登记制度

每个实验必须保存：

```text
Experiment ID
AI Research Mode (OFF / SINGLE_AI / DUAL_AI)
Research Source
AI Model(s) if used
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
Initial Capital
Return %
Risk Budget
Actual Risk
Test Protocol
Broker / Symbol / Date Range
Tester Model
Real Tick Used (YES/NO)
Delay / Slippage Scenario
Champion Metrics
Candidate Metrics
Delta Metrics
Max Equity DD USD / %
Max Balance DD USD / %
Recovery Factor
Expected Payoff
Edge-to-Cost Ratio
Sample Size
Standard Review Result
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

不适用字段写：

```text
N/A
```

不得伪造 Review 或 Test 结果。

Final Verdict 只允许：

```text
REJECT
KEEP CURRENT CHAMPION
RESEARCH FURTHER
NEW ENGINE CHAMPION
NEW 3-SOP COMBINED CHAMPION
```

---

# 23. Champion Lock 与历史链

每个 Strategy Champion 与 Combined Champion 必须保留：

- Version
- Source Hash
- SET Hash
- Test Protocol
- Metrics
- Final Report

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

# 24. Git / Version 隔离制度

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

# 25. Champion ZIP 交付制度

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

FINAL_REPORT 首页依次显示：

```text
Best Scalping
Best Intraday
Best Swing
Best Combined
```

字段顺序固定：

```text
Net -> Max Equity DD -> PF -> Trades -> Win Rate -> Reject
```

详细页还必须输出 Return %、Equity DD USD/%、Recovery Factor、Expected Payoff、Realized R:R、BUY/SELL 分拆、连续亏损、成本敏感度和 Diagnostic Flags。

用户收到的 ZIP 与 GitHub `champion/current/` 必须是同一文件；文件名、版本、SHA256 和报告指标完全一致。

---

# 26. 最终通用 Champion 迭代循环

研究入口可以来自：

```text
USER
STANDARD RESEARCH
GITHUB
EXTERNAL EA
SINGLE AI
DUAL AI
```

统一流程：

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
SELECT RESEARCH SOURCE
↓
SELECT AI_RESEARCH_MODE = OFF / SINGLE_AI / DUAL_AI
↓
FORM TESTABLE HYPOTHESIS
↓
BUILD ONE CANDIDATE
↓
COMPILE
↓
REVIEW GATE
  ├─ OFF: STANDARD CODE AUDIT
  ├─ SINGLE_AI: SELF REVIEW + RED TEAM
  └─ DUAL_AI: CROSS REVIEW
↓
MT5 REAL TICK
↓
TRAIN / OOS
↓
FXPRO / TRADONA
↓
WALK FORWARD / STRESS TEST when required
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

# 27. 最终裁决权

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

最终评价顺序永久固定：

```text
#1 Net Profit USD
#2 Max Equity Drawdown
#3 Profit Factor
#4 Trade Count
#5 Win Rate
```

任何 Automatic Reject、Look-ahead、风险偷加、不可接受 DD、OOS 崩溃或执行异常，都可以否决晋级。

---

# 28. 最终原则

GSM SOP 负责：**怎么交易**。

Research 负责：**还有什么值得测试**。

AI Research 是：**可选择研究工具，不是强制 Champion 流程**。

当 `AI_RESEARCH_MODE = OFF`：

```text
不启用 AI Research Lab
仍然可以正常研究、开发、回测、验证、产生 Champion
```

当 `AI_RESEARCH_MODE = SINGLE_AI`：

```text
使用阶段隔离 + Self Review + Red Team
降低单模型自我确认偏差
```

当 `AI_RESEARCH_MODE = DUAL_AI`：

```text
使用独立研究 + Cross Review + 可选 Hybrid Candidate
```

MetaEditor 负责：**证明源码可以正确编译**。

MT5 Real Tick + OOS + Dual Broker + Walk Forward / Stress Test 负责：**提供 Candidate 的统计验证和稳健性证据**。

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

所有 Research Source、所有 AI Mode、所有新模块、所有 Candidate 都遵守同一规则：

```text
Research First
↓
Testable Hypothesis
↓
Candidate
↓
Required Review
↓
Evidence
↓
Candidate VS Champion
↓
Champion Only If Proven
```