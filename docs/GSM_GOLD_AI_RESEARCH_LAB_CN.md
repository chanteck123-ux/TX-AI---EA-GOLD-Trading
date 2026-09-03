# GSM GOLD 3-SOP EA 双 AI 研究实验室

## Champion 制最终总体架构

> 核心目标：Codex + Claude Code 围绕同一个 GSM GOLD 3-SOP EA 持续开放研究，但**正式版本不持续被实验代码覆盖**。系统只持续寻找能够真正打赢当前 Champion 的 Candidate。只有通过完整验证并胜过旧 Champion，Candidate 才能晋级为 New Champion。

---

# 0. 当前状态假设

当前已经存在正式验证通过的：

```text
REAL CURRENT CHAMPION

├── SCALPING M5 CHAMPION
├── INTRADAY M30 CHAMPION
├── SWING CHAMPION
└── 3-SOP COMBINED CHAMPION
```

从现在开始：

```text
CHAMPION = 唯一正式基准
```

所有新开发统一遵守：

```text
Candidate VS Champion
```

不再采用：

```text
新版本做出来
→ 看起来不错
→ 直接覆盖正式版
```

只允许：

```text
旧 Champion
↓
Candidate
↓
同条件验证
↓
Candidate 真正胜出？
├── NO  → REJECT / ARCHIVE，Champion 不变
└── YES → NEW CHAMPION，旧 Champion 保留归档
```

---

# 1. 五层系统架构

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

# 2. GSM SOP 与 Research 必须严格分离

## GSM SOP

属于：

```text
AUTHORITATIVE STRATEGY FOUNDATION
```

GSM 核心知识体系：

1. Market Structure
2. Supply & Demand
3. Candlestick Pattern
4. Support & Resistance
5. Trendline
6. Chart Pattern
7. Market Structure Pt.2

## GitHub / AI Research

属于：

```text
EXTERNAL RESEARCH SOURCE
```

GitHub Research、Codex、Claude 提出的研究结论不能自动改写 GSM SOP。

关系必须是：

```text
GSM SOP = 权威基础
AI Research = 可验证的外部研究
```

如果 Research 想修改 SOP：

```text
提出假设
↓
建立 Candidate
↓
独立 A/B Test
↓
Candidate VS Champion
↓
只有真正胜出才允许进入新的 Champion 实现
```

即使 Candidate 胜出，也必须明确记录：

```text
是否改变 GSM Base SOP？
YES / NO
```

---

# 3. GSM 核心技术原则

## Supply & Demand

核心：

```text
ZONE，不是 LINE
```

形成方式重点研究：

- Long Wick
- Base Break
- Impulsive

Zone 状态：

- Fresh Zone
- First Touch
- Used Zone
- Broken Zone
- Zone Size

原则：

```text
Fresh Zone 优先
First Touch 价值最高
反复触碰后不能继续当 Fresh Zone
```

## Support & Resistance

核心同样是：

```text
ZONE，不是 LINE
```

研究：

- Two Touch
- Multiple Touch
- Role Reversal
- Major / Minor
- Good Zone
- Bad Zone
- False Breakout
- Wait for Zone

## Candlestick

Candlestick 不能脱离位置独立使用。

```text
Demand / Support 附近
→ Bullish Reversal

Supply / Resistance 附近
→ Bearish Reversal
```

重点包括：

- Hammer
- Bullish Engulfing
- Morning Star
- Shooting Star
- Bearish Engulfing
- Evening Star
- Strong Wick Rejection

Doji：

```text
主要代表犹豫
不能单独作为高质量 Entry
```

## Chart Pattern

包括：

- Bull Flag
- Bear Flag
- Double Bottom
- Double Top
- Inverse Head & Shoulders
- Head & Shoulders
- Rising Wedge
- Falling Wedge

定位：

```text
CONFIRMATION STRUCTURE
```

不是：

```text
看到形态 → 马上下单
```

必须结合：

```text
Trend
+
Structure
+
Zone
+
Confirmation
```

---

# 4. 三个独立交易引擎

## ENGINE A — SCALPING M5

目标：

- 快速交易
- 较多有效机会
- 短持仓周期

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

关键规则：

```text
Nearest Zone
必须按 CURRENT PRICE DISTANCE
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

可独立测试的 Scalping Research Modules：

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

原则：

```text
Research Module 不能直接破坏 GSM Base SOP
```

交易次数：

```text
不设人为每日硬上限
但禁止为了增加 Trades 制造无效交易
```

真正目标：

```text
增加“有效机会”，不是增加“无效交易数量”
```

---

## ENGINE B — INTRADAY M30

目标：

```text
正常市场积极寻找每天有效机会
一天 0 单允许
禁止为了达到 1 单强迫交易
```

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

GSM 原始 Base 继续作为 Benchmark / Champion Foundation。

以下全部只能作为 Optimization Candidate，不能自动成为 Base：

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

统一规则：

```text
全部 A/B TEST
全部 Candidate VS Champion
```

---

## ENGINE C — SWING

当前已有：

```text
SWING CHAMPION
```

Swing 的正式策略细节以当前已验证代码 / Authoritative SOP 为准。

本研究实验室不凭空重写 Swing Base。

任何 Swing 新模块：

```text
Research Idea
↓
Swing Candidate
↓
Candidate VS SWING CHAMPION
↓
只有真正胜出才替换
```

---

# 5. 双 AI 研究团队

Codex 与 Claude Code 都是完整的：

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

不固定：

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
- 修 BUG
- 重构
- 分析 MT5 日志
- 分析 Strategy Tester
- 分析 BUY / SELL
- 分析市场状态
- 提出 Candidate
- 审查对方 Candidate
- 反驳对方研究结论

---

# 6. 双模型开放研究流程

默认不先告诉对方答案。

```text
CURRENT CHAMPION
        │
        ├───────────────┐
        │               │
        ▼               ▼
     CODEX            CLAUDE
   独立研究            独立研究
        │               │
        ▼               ▼
 Hypothesis A       Hypothesis B
        │               │
        ▼               ▼
 Candidate A        Candidate B
        │               │
        └──────┬────────┘
               ▼
          交叉代码审查
               │
               ▼
      可建立 Combined Candidate C
               │
               ▼
         MetaEditor Compile
               │
               ▼
         MT5 Real Tick Test
               │
               ▼
       Candidate VS Champion
               │
        ┌──────┴──────┐
        ▼             ▼
      REJECT         WIN
        │             │
 Champion 不变    更严格验证
                      │
                      ▼
              OOS / Walk Forward
                      │
                      ▼
                 Stress Test
                      │
                ┌─────┴─────┐
                ▼           ▼
              FAIL         PASS
                │           │
          Champion 不变  NEW CHAMPION
```

---

# 7. Champion 核心制度

## 7.1 Champion 永远是基准，不是临时版本

任何时候必须能够明确回答：

```text
Current Scalping Champion = ?
Current Intraday Champion = ?
Current Swing Champion = ?
Current Combined Champion = ?
```

禁止存在两个“正式 Champion”。

---

## 7.2 Candidate 没有资格直接进入 Production

所有研究成果最初只能是：

```text
CANDIDATE
```

Candidate 可以来自：

```text
USER_SOP_OPTIMIZATION
CODEX
CLAUDE
CODEX_CLAUDE
EXTERNAL_RESEARCH
```

但来源不影响判定标准。

---

## 7.3 “PASS”不等于“New Champion”

必须区分：

```text
TEST PASS
≠
BEAT CHAMPION
```

例如 Candidate 自己赚钱，并不代表可以替换 Champion。

真正要求：

```text
Candidate
必须在同一测试协议下
与 Current Champion 正面对比
```

---

# 8. Candidate VS Champion 公平对比协议

Candidate 与 Champion 必须尽量使用相同：

- Symbol
- Broker / 数据源
- Real Tick 数据
- 测试起止时间
- Initial Deposit
- Leverage
- Commission
- Spread 条件
- Slippage 假设
- Risk Budget
- Position sizing 规则
- Session 条件
- Tester Model

禁止：

```text
Candidate 用更高风险
Champion 用较低风险
然后比较净利润
```

如果风险不同，必须先做 Risk-Normalized Comparison。

---

# 9. 真正“打赢 Champion”的判定逻辑

不能只看一个指标。

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
- OOS Performance
- Walk Forward Stability
- Spread Robustness
- Slippage Robustness
- Parameter Robustness
- 不同 Market Regime 表现

核心原则：

```text
单纯 Net Profit 更高
≠
真正打赢 Champion
```

必须同时满足：

```text
1. 代码正确
2. 没有未来数据 / Look-ahead
3. 风险没有偷加
4. Real Tick 有效
5. OOS 不崩
6. Walk Forward 不崩
7. 压力测试可接受
8. 关键风险指标没有不可接受恶化
9. 综合表现真正优于 Current Champion
```

若结果只是“差不多”：

```text
KEEP CURRENT CHAMPION
```

只有证据明确：

```text
Candidate > Champion
```

才允许：

```text
PROMOTE TO NEW CHAMPION
```

---

# 10. Engine Champion 与 Combined Champion 分开管理

这是强制规则。

例如 Scalping Candidate 打赢：

```text
SCALPING M5 CHAMPION
```

只能先晋级为：

```text
NEW SCALPING M5 CHAMPION
```

不能自动代表：

```text
NEW 3-SOP COMBINED CHAMPION
```

因为组合后可能产生：

- 风险叠加
- 同方向暴露
- 同时开仓
- Drawdown Correlation
- Margin Pressure
- Portfolio Interaction

因此：

```text
New Engine Champion
↓
重新组合 3-SOP
↓
完整 Portfolio Backtest
↓
Candidate Combined VS Current Combined Champion
↓
真正胜出
↓
NEW 3-SOP COMBINED CHAMPION
```

---

# 11. Optimization Module 规则

任何 Optimization Module 默认状态：

```text
OFF / EXPERIMENTAL
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

不能因为理论合理就打开。

必须：

```text
Module OFF = Current Champion
vs
Module ON = Candidate
```

若 Candidate 未真正胜出：

```text
Module 不进入 Champion
```

---

# 12. Code Review 与量化 Audit

Claude 审 Codex，Codex 也审 Claude。

至少检查：

1. 是否重复进场
2. 是否漏单
3. 是否错误使用未收盘 K 线
4. 是否存在 look-ahead
5. `CopyBuffer` / `CopyRates` 是否正确
6. timeframe 是否正确
7. Position / Order / Deal 是否混淆
8. Magic Number 是否隔离
9. Hedging / Netting 兼容性
10. SL / TP normalization
11. Stops Level / Freeze Level
12. Spread / Slippage
13. Risk / Lot calculation
14. lot step / min lot / max lot
15. 是否误改其他 Engine
16. 是否改变 GSM Base SOP
17. 是否产生过拟合
18. 是否为了利润偷偷增加风险
19. 是否改变测试条件美化结果
20. 是否有无法解释的利润来源

---

# 13. 严禁事项

禁止为了打赢 Champion：

- 偷偷增加 Lot
- 扩大 Risk %
- 删除核心 SL
- 增加隐性马丁风险
- 增加未披露最大持仓
- 使用未来 K 线
- 使用未来数据
- 修改回测区间挑最好年份
- 删除亏损阶段
- 降低 Commission / Spread
- 使用不同测试条件美化 Candidate
- 用巨大 Drawdown 换净利润
- 针对单一历史区间过拟合

发现任何一项：

```text
AUTOMATIC REJECT
```

---

# 14. Git / Version Champion 管理

推荐：

```text
main / production
└── 当前正式 Champion

champions/
├── scalping/
├── intraday/
├── swing/
└── combined/

research/codex-*
research/claude-*
research/hybrid-*

archive/rejected-*
archive/previous-champions-*
```

旧 Champion **绝对不删除**。

新 Champion 晋级后：

```text
Old Champion
→ Previous Champion Archive

Winning Candidate
→ Current Champion
```

必须保留完整 lineage：

```text
CHAMPION-001
↓ 被打赢
CHAMPION-002
↓ 被打赢
CHAMPION-003
```

---

# 15. 每个实验必须保存的记录

```text
Experiment ID
Engine
Candidate Version
Current Champion Version
Strategy Source
Research Hypothesis
Modified Files
Modified Rules
是否改变 GSM SOP
Risk Budget
Test Protocol
Champion Metrics
Candidate Metrics
OOS Result
Walk Forward Result
Stress Test Result
Codex Review
Claude Review
Audit Result
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

# 16. 最终双 AI Champion 循环

```text
CURRENT CHAMPION
↓
Codex + Claude 独立研究
↓
发现可改善问题
↓
提出 Hypothesis
↓
建立 Candidate A / B / C
↓
MQL5 开发
↓
交叉 Code Review
↓
MetaEditor Compile
↓
MT5 Real Tick
↓
Candidate VS Current Champion
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
Audit
↓
仍然胜出
↓
NEW CHAMPION
↓
旧 Champion 归档
↓
New Champion 成为下一轮唯一基准
↓
继续开放研究
```

---

# 17. 最终核心原则

```text
研究可以无限继续。
Champion 不能随便改变。

不是：
“新版本不错就替换。”

而是：
“只有真正打赢旧 Champion 才替换。”
```

Codex 和 Claude 没有最终裁决权。

最终裁决来自：

```text
代码正确性
+
公平 Candidate VS Champion
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

> **持续研究、持续挑战，但只让真正更强、更稳、更可靠的版本成为新的 Champion。**
