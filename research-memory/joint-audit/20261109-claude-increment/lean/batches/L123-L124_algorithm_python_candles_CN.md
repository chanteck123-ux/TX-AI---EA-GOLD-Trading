# L123–L124 Algorithm：Python 桥接、K 线形态工厂、成分股 universe（Claude，2026-11-09）

**方式**：同 L119–L122。可执行代码全部读完，`///` 文档注释没有逐行阅读。没有编译，也没有运行。

## 一、覆盖范围（FULL_READ 3 个，Algorithm 目录 UNREAD 0）
- L123：QCAlgorithm.Python.cs（2,148 行）。
- L124：CandlestickPatterns.cs（1,023 行）、ConstituentUniverseDefinitions.cs（777 行）。

## 二、与 V1.2 有关的发现
1. **K 线形态指标不会自动预热**（CandlestickPatterns.cs 全文）：
   - 60 余个形态工厂方法都直接调用 `RegisterIndicator`，没有经过 `InitializeIndicator`，因此即使 `Settings.AutomaticIndicatorWarmUp` 开启也不会预热。
   - 输入类型为 IBaseDataBar，可以接收 QuoteBar，不受 R41(b) 的类型问题影响。
   - 对 V1.2：用户 Scalping 的"反转闭柱确认"如果在 LEAN 中用 Engulfing、Hammer 等形态实现，回测开始后的前几根 bar 没有信号，研究端须手动预热或登记预热窗口。并入 R41。
2. **Python 桥接**（QCAlgorithm.Python.cs）：
   - Python 的 Consolidate 按订阅类型（TradeBar 或 QuoteBar）选择 handler 的类型，CFD 会得到 QuoteBar。
   - Python 版 Liquidate 的默认 tag 是 "Liquidated"。
   - Python 指标的包装对象按 `PyObject.Handle` 缓存在 `_pythonIndicators` 中。如果对象被回收后句柄被复用，理论上可能取回旧的包装对象（静态推断，未验证）。
   - V1.2 研究端使用 C#，只记录。
3. **ConstituentUniverseDefinitions**：都是美股成分股 universe 的工厂方法，属于第 4 层内容，只记录已读。

## 三、进度（里程碑）
- 全库：FULL_READ 1,648，DATA_AUDITED 643，HASH_REUSE 5，PARTIAL 5，UNREAD 4,221。
- Algorithm、Algorithm.CSharp、Algorithm.Python、Algorithm.Framework 四个目录 UNREAD 均为 0。
- 下一步：Indicators 233 个 → Engine 208 个 → Tests 859 个 → Common 1,972 个 → 其余目录。
