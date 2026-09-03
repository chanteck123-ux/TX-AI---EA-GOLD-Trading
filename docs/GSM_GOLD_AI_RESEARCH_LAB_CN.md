# GSM 黄金 AI 双模型研究实验室

> 目标：让 Codex + Claude Code 围绕同一个 XAUUSD / MQL5 EA 进行开放研究、独立开发、交叉审查、实验验证和持续优化，并由 MT5 数据而不是 AI 主观判断决定结果。

## 一、总体架构

```text
                         ┌────────────────────────────┐
                         │   GSM 黄金 AI 研究实验室   │
                         │   Codex + Claude + MT5    │
                         └─────────────┬──────────────┘
                                       │
                                       ▼
                              ┌────────────────┐
                              │   EA 基准版本   │
                              │   Baseline EA  │
                              └────────┬───────┘
                                       │
                    ┌──────────────────┴──────────────────┐
                    │                                     │
                    ▼                                     ▼
          ┌──────────────────┐                  ┌──────────────────┐
          │      CODEX       │                  │      CLAUDE      │
          │   AI 研究工程师   │                  │   AI 研究工程师   │
          └────────┬─────────┘                  └────────┬─────────┘
                   │                                     │
          独立研究 / MQL5开发 / 数据分析        独立研究 / MQL5开发 / 数据分析
                   │                                     │
                   └──────────────────┬──────────────────┘
                                      ▼
                           ┌──────────────────────┐
                           │ 双 AI 共同讨论与反驳 │
                           └──────────┬───────────┘
                                      ▼
                           ┌──────────────────────┐
                           │    建立研究假设      │
                           └──────────┬───────────┘
                                      ▼
                    ┌─────────────────┴─────────────────┐
                    │                                   │
                    ▼                                   ▼
             Codex 实验方案 A                    Claude 实验方案 B
                    │                                   │
                    └─────────────────┬─────────────────┘
                                      ▼
                              交叉代码审查
                                      │
                                      ▼
                              MetaEditor 编译
                                      │
                                      ▼
                              MT5 Strategy Tester
                                      │
                                      ▼
                          XAUUSD Real Tick 回测
                                      │
                                      ▼
                     Baseline / A / B / 融合方案 C
                                      │
                                      ▼
                         OOS / Walk Forward / 压力测试
                                      │
                                      ▼
                                  数据裁判
                               ↙             ↘
                            FAIL             PASS
                              ↓                ↓
                           重新研究          保存候选版本
```

## 二、两个 AI 的定位

Codex 和 Claude Code 都是完整的 MQL5 研究工程师，同时也是代码审查员。系统不固定“一个只开发、一个只审查”。

两边都可以：

- 阅读完整 `.mq5` / `.mqh`
- 修改和重构代码
- 修复编译错误与逻辑 BUG
- 分析交易日志和 Strategy Tester 报告
- 分析错误进场、漏单、不开单原因
- 研究新策略和新指标
- 优化现有 SOP
- 分析 BUY / SELL 差异
- 研究不同周期和市场状态
- 互相审查代码
- 互相反驳研究结论
- 独立提出实验方案

### 推荐协作方式

```text
第 1 轮：Codex 主开发 → Claude 审查 → Codex 修正 → MT5 测试
第 2 轮：Claude 主开发 → Codex 审查 → Claude 修正 → MT5 测试
第 3 轮：双方各自独立方案 → 对比 → 融合候选 → MT5 测试
```

同一时间禁止两个 AI 直接修改同一个正式文件，避免覆盖和冲突。所有实验通过独立 Git 分支或独立候选文件进行。

## 三、研发模式选择

系统启动每一轮研究前，必须选择以下三种研发模式之一。

### ① 我的 SOP 模式

```text
MODE = USER_SOP
```

Codex 和 Claude 必须严格按照用户已经制定的 SOP 开发。

允许：

- 优化代码实现
- 修 BUG
- 优化执行速度
- 改善程序化定义
- 优化进场识别准确度
- 优化订单管理
- 修正错误进场与漏单
- 优化参数，但不得改变 SOP 本质

禁止 AI 擅自：

- 加入会改变策略本质的新指标
- 删除核心指标
- 改变核心进场/方向逻辑
- 改变既定周期职责
- 改变风险底线
- 建立完全不同的新策略并覆盖正式 SOP

如果 AI 认为 SOP 某条需要修改，只能建立独立实验，不得直接覆盖正式版本。

### ② AI 自主开发模式

```text
MODE = AI_RESEARCH
```

Codex 和 Claude 可以从零开始独立研究，包括：

- 新的入场 / 出场规则
- 新指标或删除无效指标
- 不同周期组合
- 趋势 / 突破 / 回踩 / 震荡策略
- Supply & Demand
- Momentum / Mean Reversion
- Scalping / Intraday
- BUY / SELL 分离模型
- 新的资金管理方案

AI 自主开发的策略禁止直接覆盖正式 SOP EA，必须独立保存和验证。

### ③ SOP + AI 混合研究模式【默认推荐】

```text
MODE = HYBRID
```

同时运行两条研发路线：

```text
                    GSM GOLD EA
                         │
             ┌───────────┴───────────┐
             │                       │
             ▼                       ▼
        我的 SOP 路线             AI 开放路线
             │                       │
      优化现有策略               自主开发新方案
             │                       │
        Codex + Claude            Codex + Claude
             │                       │
             ▼                       ▼
        SOP Candidate           AI Candidate
             │                       │
             └───────────┬───────────┘
                         ▼
                    MT5 对比测试
```

最终比较：

- Baseline 原始 EA
- SOP 优化版本
- Codex 自主策略
- Claude 自主策略
- Codex + Claude 融合策略

## 四、策略来源必须标记

每个实验必须记录来源：

```text
STRATEGY_SOURCE =
USER_SOP
CODEX
CLAUDE
CODEX_CLAUDE
HYBRID
```

示例：

```text
Experiment ID: EXP-021
来源: USER_SOP
修改: 优化 M5 First Touch 确认算法
是否改变 SOP: NO
```

或：

```text
Experiment ID: EXP-034
来源: CODEX_CLAUDE
类型: AI 自主开发
策略: H1 趋势 + M15 Supply/Demand + M5 Liquidity Sweep Trigger
是否属于原 SOP: NO
```

## 五、开放研究范围

AI 可以主动研究：

- Supply & Demand
- First Touch
- 支撑 / 阻力
- EMA 9 / 20 / 50 / 200
- Stochastic
- ATR
- MACD
- Bollinger Bands
- ADX
- RSI
- K 线形态
- 趋势结构
- Break of Structure
- CHOCH
- Liquidity Sweep
- Breakout
- Pullback
- Momentum
- Mean Reversion
- Scalping
- Intraday
- Session
- 波动率
- Spread / Slippage
- Trailing Stop
- Break Even
- Partial Close
- 动态 TP
- 结构 SL
- 风险模型
- 仓位模型

核心原则：

```text
研究 ≠ 自动加入正式 EA
```

所有新想法必须经过：

```text
提出假设
↓
独立实验
↓
编译
↓
Real Tick 回测
↓
与 Baseline 比较
↓
OOS
↓
Walk Forward
↓
压力测试
↓
PASS
↓
才能进入正式 EA
```

## 六、交叉代码审查

Claude 审 Codex，Codex 也审 Claude。至少检查：

1. 编译成功但逻辑是否错误
2. 是否重复进场
3. 是否漏单
4. 是否错误读取当前未收盘 K 线
5. 是否存在 look-ahead / 未来数据
6. `CopyBuffer` / `CopyRates` 是否正确
7. timeframe 是否正确
8. Position / Order / Deal 是否混淆
9. Magic Number 是否隔离
10. Hedging / Netting 是否兼容
11. SL / TP normalization
12. Stops Level / Freeze Level
13. Spread / Slippage
14. 风险与手数计算
15. lot step / min lot / max lot
16. 是否误改其他策略模式
17. 是否增加过拟合风险
18. 是否改变既定 SOP 本质

## 七、MT5 数据裁判

Codex 和 Claude 都没有最终决定权。

至少记录：

- Net Profit
- Profit Factor
- Win Rate
- Total Trades
- Max Drawdown
- Relative Drawdown
- Recovery Factor
- Expected Payoff
- Sharpe Ratio（如报告可用）
- Average Win / Average Loss
- 最大连续亏损
- BUY 表现
- SELL 表现

必须进行：

- Real Tick
- 样本内测试
- OOS 样本外测试
- Walk Forward 前向测试
- 不同点差压力测试
- 不同 Slippage 压力测试
- 参数轻微扰动测试
- 不同黄金市场阶段测试

即使 Codex 和 Claude 都认为 PASS，只要数据不达标，系统仍必须判定 FAIL。

## 八、AI 禁止事项

禁止为了美化回测：

- 偷偷增加手数
- 扩大风险比例
- 删除核心止损
- 无限加仓
- 偷偷增加最大持仓数
- 使用未来 K 线或未来数据
- 隐藏坏交易
- 只挑选表现好的历史区间
- 删除亏损年份
- 修改测试条件来美化结果
- 用高风险换取表面净利润

## 九、GSM Gold 研究目标

优先级：

1. 提高净利润
2. 控制最大回撤
3. 提高 Profit Factor
4. 提高胜率
5. 增加高质量交易机会
6. 减少错误进场
7. 减少漏掉好机会
8. 保持风险可控
9. 保持策略逻辑合理
10. 避免过拟合

目标不是单纯追求“最高净利润”，而是：

```text
利润
+
稳定性
+
风险控制
+
交易质量
+
长期可持续性
```

## 十、版本和实验保护

建议 Git 结构：

```text
main / production
    └── 只保存经过验证的正式版本

research/codex-*
    └── Codex 实验

research/claude-*
    └── Claude 实验

research/hybrid-*
    └── 双 AI 融合实验
```

推荐每次实验保存：

```text
Experiment ID
策略来源
修改原因
修改文件
修改规则
Baseline 数据
Candidate 数据
OOS 数据
Walk Forward 数据
风险变化
Codex Review
Claude Review
PASS / FAIL
最终原因
```

## 十一、最终循环

```text
选择研发模式
↓
读取 EA Baseline
↓
Codex 独立研究
↓
Claude 独立研究
↓
双方比较 / 反驳 / 补充
↓
建立研究假设
↓
建立独立实验分支
↓
MQL5 开发
↓
交叉 Code Review
↓
MetaEditor 编译
↓
MT5 Real Tick 回测
↓
Baseline 对比
↓
OOS
↓
Walk Forward
↓
压力测试
↓
PASS / FAIL
↓
PASS → 保存候选 → 更严格验证 → 合并 Production
FAIL → 分析失败原因 → 重新研究
```

## 十二、核心原则

```text
Codex 不能决定谁赢。
Claude 不能决定谁赢。

只有：
代码正确性
+
真实 Tick 数据
+
OOS
+
Walk Forward
+
风险数据

可以决定实验是否通过。
```

目标：让 **Codex + Claude Code** 成为两个真正合作、同时互相竞争和互相审查的 MQL5 / XAUUSD EA 研究工程师。
