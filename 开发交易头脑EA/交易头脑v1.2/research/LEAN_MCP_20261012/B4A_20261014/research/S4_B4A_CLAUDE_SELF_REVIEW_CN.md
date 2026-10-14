# S4 B4A 报价字段候选：Claude 源码自审（2026-10-13）

依据 `S4_B4A_QUOTE_FIELDS_SCOPE_CN.md`。候选 ID：`TB500_S4_BE125_LEAN_B4A`。Claude 只做了纯 C# 的适配 fixture 编译和运行；**没有**编译 LEAN 算法，**没有**运行引擎，也**没有**启动 MT5。B1 的源码、证据和 run 均未改动。评分 N/A。2026 年 8 月是已在开发中使用过的数据，不是 OOS。

## 唯一主动改变
`lean/algorithms/S4B4A/QuoteFieldAdapter.cs` 中有两个类：
- **`RawFlagSidecar`**：按服务器日的真实流顺序打开 `ticks_YYYYMMDD.csv`。每个文件在读第一行之前，先用 EXPORT_MANIFEST 核对 SHA；EXPORT_MANIFEST 自己的 SHA 也由 runner 核对，并作为参数传给算法后再核对一次。每个 LEAN tick 只读取**下一行**原始行，并核对毫秒时间以及原始 bid/ask；不符就硬失败（`SIDECAR_MISMATCH`），原始行用尽也硬失败（`RAW_EXHAUSTED`）。不跳行，不向后预读。序号连续，保留行号和同毫秒内的顺序。
- **`QuoteFieldState`**：
  - 只有 `flags&2` 才更新 Bid，只有 `flags&4` 才更新 Ask；
  - LAST(8)、VOLUME(16) 以及没有报价位的行不改变报价；
  - 未知位（实际数据中有 256 和 1024）只计数，不推测含义；
  - Bid 和 Ask 两侧都由**各自所在的行**提供过初值之前，记为 `NotReadyNoSeed`，不会借用后面的行。

## LEAN 报价单一口径（按 Codex 要求，已读本机源码）
- `Security.SetMarketPrice(BaseData)` 会调用 `Cache.AddData`；对报价 tick，它设置 BidPrice、AskPrice，并把 Price 设为中价；随后经 `UpdateConsumersMarketPrice` 调用 `Holdings.UpdateMarketPrice(Price)`。
- `SecurityHolding.UnrealizedProfit` 就是 `TotalCloseProfit()`，读取缓存中的 BidPrice／AskPrice。
- `SecurityPortfolioManager.InvalidateTotalPortfolioValue()` 会让 TPV 重新计算。
- `new Tick(time, symbol, bid, ask)` 构造的是 TickType.Quote，Value 为中价。
- **做法：**每个就绪的 tick，在任何核心逻辑运行之前，先调用 `security.SetMarketPrice(new Tick(t.Time, gold, effBid, effAsk))`，其中只用当前 tick 自己的时间，再调用 `Portfolio.InvalidateTotalPortfolioValue()`。这样核心风控、QC 持仓、TPV 和对账都使用同一份修正后的报价。对账中还加了一项 `lean_cache_matches_corrected_quote`，不符就判对账失败。
- **残余：**每个 slice 开始前，LEAN 内部会先把缓存设为该 slice 最后一个原始 tick 的值，然后才进入 OnData，再被我们逐 tick 覆盖。这段时间里没有策略逻辑、订单或对账在运行，所以不影响结果，已在 RESULT 中写明。

## 不变部分
- `S4Core.cs` 链接的是 B1 R2 冻结版（ee509e1d），四个 I9 源码和 B1 的 90 项 fixture 源码也都按哈希绑定；runner 在每种模式下都先核对这些哈希，并把它们复制进运行目录参与编译。
- 以下沿用 B1：风险、入场、退出、两槽、1.5R、1.25R 保本、日锁、紧急锁；250 ms 的“到期后第一行”成交规则和 pending 逻辑；手续费、成交和保证金模型；对账公式与 0.05 容差，并逐单核对手续费。
- **已知并保留的差异：**250 ms 时仍按“到期后第一行”成交，而 B3 F5 观测到的是“到期前最后一个有效报价”，并且 B4A 没有模拟同步阻塞。这一点另行登记，本批**不改**。

## 行数核算（RESULT.quote_adapter）
- 恒等式：`lean_ticks_in_window = delivered_to_core + not_ready_rows_skipped + invalid_effective_quote_skipped`；
- 同时要求 `raw_rows_matched = lean_ticks_in_window`、`raw_rows_in_window_unmatched = 0`（运行结束时把剩余的、仍在窗口内的原始行全部读完并核对哈希），以及 `ready + not_ready = rows`。
- runner 还要求原始行总数等于期望值：smoke 为 923,807，全月为 20,513,403。
- RESULT 中另外输出 Bid／Ask 更新次数、没有报价位的行数、生效报价与原始行不同的次数、未知位，以及各 flag 的分布。

## fixture
- B4A 适配 fixture 23/23 通过（`builds/S4B4A_CLAUDE_FIXTURE_SELFCHECK_01`），覆盖：
  - 只更新一侧（Bid-only、Ask-only）；
  - 只有 LAST 的行；
  - 重复毫秒的先后顺序与连续序号；
  - 未知位；
  - B3 11:20 的真实形态（4057.82 → 4057.83）；
  - 起始没有报价时未就绪、单侧有初值仍未就绪；
  - 价格不符、时间不符、多出 LEAN tick 都会硬失败；
  - 跨日并经过一个只有表头的文件；
  - drain 只计入窗口内未匹配的行；
  - 文件被篡改时拒绝。
- runner 的 Fixtures 模式还会**原样**跑 B1 的 90 项 fixture，并要求结果正好是 90。

## 预算（runner 强制，登记表 `research/S4B4A_RUN_REGISTRY.json`）
- smoke：8 月 3 日一次；另有一次依据充分的修正 smoke，必须提供 `-CorrectionReason`。
- 全月：一次，而且只有在 smoke 通过之后才能运行，同时要求：
  - 源码和 DLL 与 smoke 相同；
  - 配置相同；
  - 回执中记录的 RESULT 哈希与文件一致；
  - smoke 的对账与 sidecar 对齐都通过。

## 请 Codex 重点复审
1. `SetMarketPrice` 加 `InvalidateTotalPortfolioValue` 的同步时点，以及 LEAN 的 slice 前更新是否会影响订单处理（订单是同步 MarketOrder，在我们覆盖缓存之后才发出）。
2. LEAN tick 与原始行逐一对应的前提：B1 全月的 tick 数等于原始行数，转换 manifest 也写明保留了原始顺序。sidecar 的硬失败会直接暴露任何不一致。
3. 生效报价出现交叉（ask < bid）时，按无效报价跳过并计数，与 B1 对原始报价的处理一致；这是否需要单列讨论。
4. 本批只改报价字段，即使结果更接近原生，也只说明模型对等程度提高，不是策略改进，也不代表七策略全部完成迁移。

## 第 2 版（按 Codex 初审修正，2026-10-13）
1. **全月不重新编译**：即使源码相同，B1 的 smoke 与全月两次编译出的 DLL 也不同（构建路径、PDB 不同），所以 `FullAugust` 直接复用已验证过的 smoke 构建。复用前核对：
   - smoke 回执的状态为 SMOKE_PASS 且 `build_mode=FRESH_COMPILE`；
   - RESULT 的哈希与回执一致；
   - 配置相同；
   - **全部源码哈希相同**；
   - smoke 磁盘上的 DLL 和 compile.log 与 smoke 回执一致。

   核对通过后复制 release 目录，再次核对 DLL 和 compile.log，并标记 `build_mode=REUSED_MATCHING_SMOKE_BUILD`。只要源码有任何变动就必须重新跑 smoke；哈希门**不放宽**。
2. **复制副本逐一核对**：runner 复制进运行目录的每一个文件（本候选的 3 个、S4Core、4 个 I9）都与回执中记录的哈希逐个对比，结果写入 `bound_source_hashes`。另外三次复核源码未变：编译后（同时复核这些副本）、fixture 结束时、引擎运行结束时；DLL 在运行前后也核对一致。
3. **延迟参数缺省值**：算法中 `latency-ms` 缺省时改为 250；风险仍由共享的 S4Config 决定，为 2%。runner 仍固定传入 250。
4. **原始行检查**：`RawFlagSidecar.Next` 先检查价格是否为有限数（原始和 LEAN 的 bid/ask 都查），否则报 `NON_FINITE_PRICE`。原因是 NaN 会让 `Math.Abs(...) > 容差` 的比较永远为假；比较本身也改成“`!(差值 <= 容差)` 即判失败”的写法，NaN 无法蒙混过关。然后检查原始时间不能倒退（跨文件也一样，drain 阶段同样检查），否则报 `RAW_TIME_REGRESSION`。被拒绝的检查只消耗当前这一行，不会多读下一行。
5. **新增 4 个 fixture**：时间倒序（即使 LEAN 侧也是同样的倒序）、原始 NaN、LEAN 侧 Infinity、拒绝后不前移。适配 fixture 共 **27/27 通过**（`builds/S4B4A_CLAUDE_FIXTURE_SELFCHECK_02`）。runner 已整体重写（第一次局部替换时误删了构建段落），PowerShell 解析 0 错误。缓存同步和单一对账公式（0.05）不变。

## 第 3 版：END 缓存修正（依据失败的 smoke `S4B4A_SMOKE_D250_20261013T154409Z_238a5484`，失败证据保留）
- **实际证据：**
  - 923,807 行全部一一匹配；1 行未就绪，923,806 行有效；
  - 数量、费用、清算费、现金都是 0 差，17 次核验的 TPV gap 最大为 0；
  - `reconciliation.jsonl` 中只有一条 END 记录：`lean_cache_matches_corrected_quote=false`，当时 lean_qty=0，gap=0。对账判失败**仅**因为这一项缓存检查。
- **根因（更正自审中的“只在 slice 之间”说法，那是错的）：**smoke 的 LEAN EndDate 为 UTC 8 月 3 日，LEAN 会继续推送 UTC 21:00–24:00 的 tick；这些 tick 对应服务器时间 8 月 4 日，在窗口之外。OnData 对它们 `continue`，不交易，也不重新同步缓存，于是进入 OnEndOfAlgorithm 时，缓存里是窗口之后的原始报价，而 `Reconcile("END")` 拿它与最后一个有效修正报价比较，结果不符。
- **修正：**
  - OnData 先识别窗口后的 tick，只计数并记录最后一个，不交易、不同步；
  - OnEndOfAlgorithm 在 `core.End()` 和 `Reconcile("END")` **之前**，把最后一个有效的窗口内修正报价，用它自己的 tickUtc 时间，通过 `SetMarketPrice` 写回缓存，再调用 `InvalidateTotalPortfolioValue`。这只用过去的值，不借用任何后续行。
  - RESULT 中新增 `quote_adapter.end_cache_restore`：恢复前的缓存（bid/ask，以及 GetLastData 的时间）、最后一个有效报价、恢复后的缓存、LEAN 推送的窗口外 tick 数和最后一个窗口外 tick，以及三个布尔值：恢复前缓存是否等于最后一个窗口外 tick（用于**验证根因**）、恢复前是否等于有效报价、恢复后是否等于有效报价。
- **不变部分：**缓存检查和 0.05 容差都没有放宽；S4Core、I9、手续费模型和策略都没改；风险 2%，延迟缺省 250。
- **建议 Codex：**先跑 `-Mode Build`（只编译，不占用 smoke 预算），再跑唯一一次修正 smoke `-Mode Smoke -CorrectionReason "<依据 238a5484 END 缓存根因>"`。本批**不跑全月**。
- **补充根因证据（Codex）：**
  - `SetEndDate(Aug 3)` 指 UTC 当日结束，而 core 的半开窗口结束于服务器 8 月 4 日 00:00，即 UTC 8 月 3 日 21:00；
  - LEAN 的 feed 仍会推送接下来 3 小时的数据，`Engine/AlgorithmManager.cs` 约第 271 行在 OnData **之前**对每个 slice 调用 `security.Update`；
  - console 末尾显示处理到 UTC 8 月 3 日 23:59:59，共 972,469 个数据点，其中窗口内 923,807 个。

  因此期末缓存是窗口外的数据，不是什么来源不明的 slice 之间刷新。
- **新增诊断（只记录，不改有效窗口逻辑）：**
  - 第一个和最后一个被丢弃的窗口外 tick 的 UTC 时间、服务器时间和报价，以及窗口外 tick 的数量；
  - 恢复前后缓存中 `GetLastData` 的时间与报价，以及最后一个有效 tick 的时间和报价；
  - 窗口外估值开始那一刻的实际持仓：ledger 的签名手数、LEAN 的数量、此前的订单数和费用，以及窗口外**新增的**订单数和费用。
- **residual 文字已改为引用源码，而且不再宣称**对引擎资产估值没有影响：持仓不为零时，LEAN 会在 OnEnd 之前用窗口外的原始报价对 TPV 和保证金估值。238a5484 smoke 中 4 笔持仓在窗口结束前都已平掉，到目前为止没有看到窗口外的持仓或费用影响；下一次 smoke 会把实际值记录下来。日期设置与 B1 相同；窗口外不会产生新单，也不运行核心管理。
