# 外部 EA「测试版 2.41」研究分析（GOLD M15）

> 研究目的：只学习架构与可验证的模块设计，不复制外部源码，不把截图中的外部逻辑直接当作 GSM SOP。
>
> 证据等级：**截图参数观察 + 多模型交叉解读**。没有源码，因此所有内部执行逻辑都必须视为“待验证假设”。
>
> 安全说明：截图中的绑定 ID、口令、授权字符串等敏感字段不写入本研究文档。

## 1. 截图中可直接确认的参数事实

- EA：测试版 2.41
- 品种/周期：GOLD，M15
- 到期日期字段：`20260603`
- 交易方向：`BUYORSELL`
- 最大允许滑点：`30` 点
- 图表统计面板：开启
- 日统计截图/报表：开启
- EMA 趋势过滤：关闭；参数为 EMA 13 / 34
- ADX 过滤：关闭；ADX 周期 14，最低阈值 20
- DI 方向判断：关闭
- ATR 波动过滤：关闭；ATR 周期 14，最小阈值 15
- CCI 过滤：关闭；CCI 周期 14，阈值 +100 / -100
- FVG 过滤：关闭；回看 3 根 K，最小缺口比例相对 ATR 为 0.3
- 多信号一致性：最少同向信号数量为 1（截图说明范围 1–4）
- 快速止损/熔断模块：关闭；可见参数包括 120 秒、50 点、20 点
- 每日净利润/净亏损金额熔断：0，表示未启用
- 单方向浮亏金额止损：0，表示未启用
- 浮亏对冲/融合模块：关闭；可见比例参数 50%
- 每日运行时间：0–0，按界面说明为全天运行
- 价格区间限制：关闭

## 2. 重要纠错：不能把参数名脑补成策略逻辑

### 2.1 `30` 是最大允许滑点，不是“最大爆仓点数”

截图中的 30 位于“允许的最大滑点”参数。不能解释为固定止损、爆仓线或单边亏损阈值。

### 2.2 `50%` 不能直接解释为“账户亏损 50% 强平”

截图文字对应的是浮亏对冲/融合类模块的比例阈值。没有源码之前，不能确定其精确触发、平仓、锁仓或减仓行为。

### 2.3 `120 / 50 / 20` 属于快速止损/熔断模块参数，但内部状态机未知

从参数文字可以推测它与“短时间内不利移动 → 熔断 → 回撤后恢复”有关，但不能断言具体执行顺序。正式研究必须通过源码、日志或可复现实验验证。

### 2.4 FVG 是 Fair Value Gap

截图是 FVG（公允价值缺口），不是“PVG/价格成交量缺口”。

### 2.5 关闭全部过滤器不等于“裸开单”

有两种完全不同的可能：

1. 基础策略独立存在，EMA/ADX/ATR/CCI/FVG 只是可选过滤层；关闭后仍按基础策略交易。
2. 这些模块本身参与投票，而一致性最少需要 1 票；若关闭模块不计为通过，则可能造成没有信号。

没有源码不能判断是哪一种。

## 3. 三方解读的可用性

### DeepSeek

可取之处：识别到 EMA、ADX、ATR、CCI、FVG/缺口类过滤与多指标共振思路。

主要问题：把 30 误判为爆仓/止损线；把 120 误当硬止损；把 FVG 误解为自定义 PVG；对 50% 风控含义过度推断。

### Claude

可取之处：对截图文本总体读取较准确；正确识别多数保护和技术过滤当前均为 `false`。

主要问题：把 `BUYORSELL` 进一步推断为“双向网格对冲”仍需要源码证明；把“过滤器关闭”直接等同于“裸开单”证据不足。

### Gemini

可取之处：识别 GOLD M15、过滤器关闭与账户级保护模块的存在。

主要问题：到期日期读错为 6 月 1 日；把“100 点”等同于固定 10 美元不严谨；对网格/马丁和爆仓风险存在未经源码证明的推断。

## 4. 真正值得 GSM GOLD 3-SOP 学习的架构

重点不是复制 EMA13/34、ADX20 等普通参数，而是学习“独立模块 + 独立开关 + 可单独回测”的工程方式。

建议抽象为：

```text
Base SOP / Strategy Engine
        ↓
Optional Evidence Modules
  ├─ EMA
  ├─ ADX
  ├─ DI
  ├─ ATR Regime
  ├─ CCI
  ├─ FVG
  ├─ Candle Pattern
  ├─ Supply/Demand
  └─ Market Structure
        ↓
Confidence / Voting
        ↓
Fast Adverse Move Guard
        ↓
Risk Engine
  ├─ Per Trade Risk
  ├─ Direction Basket Risk
  ├─ Daily P/L Circuit Breaker
  └─ Portfolio Drawdown
        ↓
Execution Engine
        ↓
Recovery / Resume State
        ↓
MT5
```

## 5. 六个优先研究模块

### A. Fast Adverse Move Guard（快速不利移动保护）

目标：处理“刚进场就迅速证明错误”的情况，而不是等固定 SL 才反应。

不建议复制固定 `120秒 / 50点 / 20点`。应改成自适应：

```text
MAE = 入场后的最大不利价格移动

若：
MAE > K × ATR
且发生在短时间窗内
且反向动量仍增强
→ 冻结同方向新增仓位
→ 进入 FAST_ADVERSE_MOVE / FREEZE 状态
```

Candidate 参数应分别对 Scalping M5、Intraday M30、Swing 做独立优化。

### B. Recovery / Resume（熔断后恢复）

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

原则：状态少、日志可验证、服务器重启后状态可重建。

### C. Direction Basket Risk（BUY/SELL 方向独立篮子风险）

分别统计：

```text
BUY_Basket_Floating_PnL
SELL_Basket_Floating_PnL
BUY_Total_Risk
SELL_Total_Risk
```

若一个方向达到风险上限，可只处理该方向，不必无条件停止整个 EA。

### D. Daily Account Circuit Breaker（每日账户级熔断）

建议同时支持：

- DailyProfitLimitUSD
- DailyLossLimitUSD
- DailyLossPercent
- DailyEquityDrawdownPercent

金额与百分比应可独立开关，避免账户从 $500 增长到更高资金后仍使用失真的固定金额阈值。

### E. Optional Signal Voting（可选证据投票）

不要做成全部指标 `AND` 才交易。

更适合 GSM：

```text
Core GSM SOP = 必须满足

Optional Evidence = 加分/减分
EMA / ADX / DI / ATR / CCI / FVG / Candle / S&D / Structure

Confidence Score / Votes
        ↓
决定候选质量、风险档位或是否放行
```

核心原则：**SOP 决定有没有交易资格，指标负责衡量证据强度。**

### F. ATR-normalized FVG Quality（ATR 标准化 FVG）

截图的 `FVG Size / ATR >= 0.3` 思路值得测试。

建议：

```text
ValidFVG = FVG_Size >= ATR × MinFvgAtrRatio
```

再与 GSM 现有结构结合：

```text
Impulse
+ Fresh Supply/Demand Zone
+ First Touch
+ Structure
+ FVG Quality
```

FVG 是 Optimization Layer，不自动替代 GSM Supply/Demand Base Zone。

## 6. ADX + DI 的正确分工

- ADX：趋势强度，不提供方向。
- +DI / -DI：方向证据。

候选逻辑示例：

```text
BUY Evidence:
ADX > threshold
AND +DI > -DI

SELL Evidence:
ADX > threshold
AND -DI > +DI
```

该逻辑应作为可选证据/过滤候选，而不是默认硬编码进 Champion。

## 7. 不直接复制的参数

### EMA13/34

现有 GSM 已有自己的 EMA 体系。13/34 只能作为 Candidate，与 Champion 做 Real Tick A/B。

### 固定 100 / 50 / 20 points

必须先读取：

```text
SYMBOL_POINT
SYMBOL_DIGITS
SYMBOL_TRADE_TICK_SIZE
SYMBOL_TRADE_TICK_VALUE
```

再换算真实价格距离和真实货币风险。禁止假设“100 points 永远等于固定美元金额”。

### CCI14 ±100 / ADX20

这些是普通默认值，不因为外部 EA 使用就自动获得有效性。必须独立优化并做 OOS。

## 8. Champion / Candidate 规则

本研究中的任何模块都只属于 Research Candidate：

```text
External Idea
→ Clean-room specification
→ Single-module Candidate
→ Compile
→ Real Tick
→ Train / OOS
→ FxPro + Tradona
→ Candidate VS Current Champion
→ PASS 才允许进入 Champion
```

禁止一次同时开启多项新模块后直接宣布提升，因为无法归因是哪一个模块产生效果。

建议测试顺序：

1. Direction Basket Risk
2. Daily Circuit Breaker
3. Fast Adverse Move Guard
4. Recovery State
5. ADX + DI Evidence
6. ATR-normalized FVG Quality
7. CCI（低优先级）

## 9. 当前结论

这张外部 EA 参数截图最有研究价值的不是指标本身，而是以下工程思想：

1. 快速不利移动熔断
2. 熔断后恢复状态
3. BUY/SELL 独立篮子风险
4. 每日账户级盈利/亏损熔断
5. 多信号一致性/投票
6. FVG 相对 ATR 的自适应质量过滤

这些模块可以进入 GSM 研究池，但**绝不直接修改正式 Champion**。所有结果必须通过 Candidate VS Champion 的 Real Tick + OOS 验证。
