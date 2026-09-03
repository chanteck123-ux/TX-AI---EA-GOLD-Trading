# GSM GOLD 3-SOP EA 单 AI 研究实验室

## Champion 制最终总体架构

> 目标：只使用一个 AI 模型，也能围绕 GSM GOLD 3-SOP EA 持续研究、开发、回测、审查和挑战当前 Champion。核心制度与双 AI 版本完全一致：**Candidate 只有真正打赢旧 Champion 才能替换。**

---

# 0. 当前状态假设

当前已经存在正式验证的：

```text
REAL CURRENT CHAMPION

├── SCALPING M5 CHAMPION
├── INTRADAY M30 CHAMPION
├── SWING CHAMPION
└── 3-SOP COMBINED CHAMPION
```

单 AI 系统启动后：

```text
Current Champion = 唯一正式基准
```

AI 不能因为新想法看起来更好就修改 Production。

所有研究必须：

```text
Candidate VS Champion
```

---

# 1. 单 AI 实验室适用模型

单 AI 可以选择：

```text
Codex
或
Claude Code
```

系统不把架构绑定到某一个品牌。

统一角色：

```text
SINGLE AI RESEARCH ENGINEER
```

同时承担：

- Strategy Researcher
- MQL5 Developer
- Code Reviewer
- Debugger
- Backtest Analyst
- Risk Reviewer
- Optimization Researcher

---

# 2. 五层系统架构

```text
LAYER 1
GSM SOP

LAYER 2
3 STRATEGY ENGINES

LAYER 3
OPTIONAL OPTIMIZATION MODULES

LAYER 4
RISK + EXECUTION + PORTFOLIO

LAYER 5
BACKTEST + AUDIT + CHAMPION SYSTEM
```

完整关系：

```text
GSM SOP
↓
SCALPING / INTRADAY / SWING
↓
Optional Optimization Modules
↓
Risk Engine
↓
Execution Engine
↓
Portfolio Manager
↓
MT5
↓
Real Tick
↓
Audit
↓
Candidate VS Champion
↓
REJECT / KEEP CHAMPION / NEW CHAMPION
```

---

# 3. GSM SOP 与 AI Research 分离

GSM SOP 属于：

```text
AUTHORITATIVE STRATEGY FOUNDATION
```

AI 研究属于：

```text
EXTERNAL RESEARCH / EXPERIMENTAL SOURCE
```

单 AI 可以：

- 优化 GSM SOP 的程序实现
- 找出 SOP 实现错误
- 建立新 Candidate
- 提出新指标 / 新模块
- 提出不同 Entry / Exit 假设

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
只有胜出才晋级
```

---

# 4. 三个 Strategy Engine

## ENGINE A — SCALPING M5

Base Framework：

```text
M5
↓
Find Current Nearest Valid S&D
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
SL
↓
TP
↓
Exit
```

关键：

```text
Nearest Zone = CURRENT PRICE DISTANCE
不是最新形成时间
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

所有修改：

```text
Scalping Candidate VS Scalping Champion
```

---

## ENGINE B — INTRADAY M30

Base：

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

原则：

```text
积极寻找有效机会
一天 0 单允许
禁止为了每天 1 单强迫交易
```

以下全部只能 A/B Test：

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

统一：

```text
Intraday Candidate VS Intraday Champion
```

---

## ENGINE C — SWING

当前已有：

```text
SWING CHAMPION
```

正式 Base 以当前 Authoritative SOP / 已验证代码为准。

单 AI 不得凭空改写。

所有新想法：

```text
Swing Candidate VS Swing Champion
```

---

# 5. 单 AI 最大风险：自己开发、自己说自己对

双 AI 有天然交叉审查。

单 AI 没有。

所以必须强制把同一个 AI 拆成不同阶段，不允许“一次生成后直接 PASS”。

结构：

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

每个阶段必须重新读取事实和测试结果，而不是直接继承上一阶段的主观结论。

---

# 6. 单 AI 开放研究循环

```text
CURRENT CHAMPION
↓
AI Research Phase
↓
找出问题 / 机会
↓
提出 Hypothesis
↓
建立 Candidate
↓
MQL5 Development
↓
Compile
↓
Self Code Review
↓
Red Team Review
↓
MT5 Real Tick
↓
Candidate VS Champion
↓
没有明确胜出
→ REJECT / KEEP CHAMPION

明确胜出
↓
OOS
↓
Walk Forward
↓
Stress Test
↓
Risk Audit
↓
仍然胜出
↓
NEW CHAMPION
```

---

# 7. Research Phase

AI 首先只做研究，不改代码。

必须输出：

```text
Research ID
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

研究阶段禁止：

```text
未经实验直接修改 Production
```

---

# 8. Development Phase

Research Hypothesis 批准进入实验后：

```text
Champion Snapshot
↓
Create Candidate Branch / Candidate File
↓
只修改实验需要的内容
↓
保留所有其他条件
```

开发阶段要求：

- 最小必要修改
- 修改原因可追踪
- 不偷偷改风险
- 不顺便重写无关逻辑
- 不覆盖 Current Champion

---

# 9. Self Code Review Phase

同一个 AI 写完代码后，必须重新以 Reviewer 身份检查。

至少检查：

1. 是否重复进场
2. 是否漏单
3. 是否错误读取未收盘 K 线
4. 是否存在 look-ahead
5. `CopyBuffer` / `CopyRates`
6. Timeframe
7. Position / Order / Deal
8. Magic Number
9. Hedging / Netting
10. SL / TP normalization
11. Stops Level / Freeze Level
12. Spread / Slippage
13. Risk / Lot calculation
14. Lot step / min / max
15. 是否误改其他 Engine
16. 是否改变 GSM Base SOP
17. 是否加入隐藏风险
18. 是否存在明显 overfitting 路径

Review 结果必须：

```text
PASS
或
FAIL + 修复清单
```

---

# 10. Red Team Phase

单 AI 系统必须再跑一次“反方审查”。

此阶段假设：

```text
Candidate 可能是错的。
```

必须主动尝试证明 Candidate 不应该晋级。

问题包括：

- 利润是不是来自更高风险？
- Drawdown 是否恶化？
- 是否只适合某一年？
- 是否牺牲交易质量换 Trades？
- 是否只优化 BUY 或 SELL？
- 是否对 Spread 太敏感？
- 是否对 Slippage 太敏感？
- 参数轻微变化是否崩溃？
- 是否减少真实市场可执行性？
- 是否只是 Backtest Noise？

Red Team 不是为了证明 Candidate 好。

而是：

```text
尽量把它推翻。
```

推不翻，才进入下一关。

---

# 11. Candidate VS Champion 公平测试

必须同条件：

- Symbol
- Broker / Data Source
- Real Tick
- Test Period
- Deposit
- Leverage
- Commission
- Spread
- Slippage
- Risk Budget
- Position sizing
- Session
- Tester Model

禁止不同风险直接比较净利润。

如果风险不同：

```text
先 Risk-Normalize
再比较
```

---

# 12. Champion 判定指标

必须整体比较：

- Net Profit
- Profit Factor
- Max Drawdown
- Relative Drawdown
- Recovery Factor
- Expected Payoff
- Win Rate
- Total Trades
- Average Win
- Average Loss
- Maximum Consecutive Losses
- BUY Performance
- SELL Performance
- OOS
- Walk Forward
- Spread Robustness
- Slippage Robustness
- Parameter Robustness
- Market Regime Robustness

核心：

```text
Net Profit 更高
≠
New Champion
```

如果只是接近：

```text
KEEP CURRENT CHAMPION
```

只有证据明确：

```text
Candidate > Champion
```

才晋级。

---

# 13. Engine Champion 与 Combined Champion 分开

```text
Scalping Candidate
只能挑战 Scalping Champion

Intraday Candidate
只能挑战 Intraday Champion

Swing Candidate
只能挑战 Swing Champion
```

某 Engine 晋级后：

```text
New Engine Champion
↓
重新组合 3-SOP
↓
Portfolio Test
↓
Candidate Combined VS Current Combined Champion
↓
真正胜出
↓
NEW 3-SOP COMBINED CHAMPION
```

不能自动把单策略胜利当作组合胜利。

---

# 14. Optional Optimization Module 规则

任何新模块默认：

```text
EXPERIMENTAL / OFF
```

例如：

- EMA
- ATR
- BOS
- CHoCH
- FVG
- Order Block
- Liquidity
- Session Filter
- VWAP
- Volume
- AI Score
- Candle Quality
- Cost Gate

测试：

```text
Champion Module OFF
vs
Candidate Module ON
```

未胜出：

```text
保持 OFF
```

---

# 15. 自动拒绝条件

任何 Candidate 出现以下之一：

- Future Data
- Look-ahead
- Risk 偷加
- Lot 偷增
- SL 被删除
- 隐性马丁风险增加
- 测试区间被挑选美化
- Commission / Spread 被降低
- 测试协议不公平
- 无法解释的异常利润
- 核心数据缺失

统一：

```text
AUTOMATIC REJECT
```

---

# 16. Git / Version 管理

推荐：

```text
main / production
└── Current Champion

champions/
├── scalping/
├── intraday/
├── swing/
└── combined/

research/single-ai-*

archive/rejected-*
archive/previous-champions-*
```

旧 Champion 不删除。

晋级过程：

```text
Winning Candidate
→ New Current Champion

Old Champion
→ Previous Champion Archive
```

---

# 17. 单 AI 每次实验必须记录

```text
Experiment ID
AI Model
Engine
Current Champion Version
Candidate Version
Research Hypothesis
Strategy Source
Modified Files
Modified Rules
SOP Impact
Risk Budget
Test Protocol
Champion Metrics
Candidate Metrics
Self Review Result
Red Team Result
OOS Result
Walk Forward Result
Stress Result
Final Audit
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

# 18. 单 AI 最终程序流

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
Research Phase
↓
Generate Hypothesis
↓
Create Candidate
↓
Modify MQL5
↓
Compile
↓
Self Review
↓
Red Team Review
↓
MT5 Real Tick
↓
Candidate VS Champion
↓
WIN?
├── NO
│   ↓
│ REJECT / ARCHIVE
│   ↓
│ Champion unchanged
│
└── YES
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
    ├── NO → Champion unchanged
    └── YES
          ↓
       Promote New Engine Champion
          ↓
       If needed: 3-SOP Combined Retest
          ↓
       Combined Candidate VS Combined Champion
          ↓
       WIN → New Combined Champion
```

---

# 19. 单 AI 核心原则

```text
一个 AI 可以持续研究。
但一个 AI 不能靠自己的主观判断给自己晋级。
```

最终决定来自：

```text
公平 Candidate VS Champion
+
代码 Audit
+
MT5 Real Tick
+
OOS
+
Walk Forward
+
Stress Test
+
Risk Audit
+
Portfolio Audit
```

最终目标：

> **即使只有一个 AI，也能持续开放研究；但 Champion 只有在 Candidate 真正、稳定、可重复地打赢旧版本时才替换。**
