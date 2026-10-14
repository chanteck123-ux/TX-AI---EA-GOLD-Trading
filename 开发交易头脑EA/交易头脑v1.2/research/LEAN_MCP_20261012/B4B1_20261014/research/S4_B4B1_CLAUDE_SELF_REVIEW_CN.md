# S4 B4B1 入场到期取价候选：Claude 实现自审（2026-10-14）

- 候选：`TB500_S4_BE125_LEAN_B4B1`（基于 B4A `TB500_S4_BE125_LEAN_B4A`）
- 实现者：Claude；本文件是 Claude 自审，不等于 Codex 的独立复审。
- 依据：`research/S4_B4B_SCOPE_CN.md`、`research/S4_B4B_EVENT_DESIGN_CN.md`（6471f759），以及 Codex 的 `CODEX_S4_B4B_PREIMPLEMENTATION_REVIEW_CN.md` 最后一段。
- 本批只做 B4B1，B4B2（同步阻塞／回调抑制）不做。
- Claude 未编译 LEAN 算法，未启动 LEAN 或 MT5，未改 Git。只编译并运行了纯 C# fixture。
- 数据角色：2026年8月是已用过的开发数据，不是 OOS。评分 N/A（SCORE_TARGETS_UNSET）。
- 不声称完整 parity、策略改进、七策略迁移、Champion、Demo 或实盘就绪。

## 1. 唯一改动与登记的语义

| 项 | B4A（基线，冻结） | B4B1 |
|---|---|---|
| 延迟入场的成交价 | 第一个已送达行（ms ≥ 到期）的当前报价 | 到期报价状态：所有 ms ≤ 到期的原始行按原序应用后的有效 Bid/Ask |
| 快照时机 | — | 在**首次**遇到 ms > 到期的行、应用该行**之前**捕获；跨越行自身价格不使用 |
| 实际提交行 | ms ≥ 到期的首个已送达行 | ms > 到期后的首个 **valid + ready** 行（跨越行无效时顺延） |
| 到期同毫秒的多行 | 到期行即提交 | 全部计入快照，**登记为未验证假设**（SAME_MS_ROWS_AT_DEADLINE_INCLUDED），并记录 ordinal 和 deadline_rows |
| 到期状态无效 | — | 模型拒单 `INVALID_QUOTE_AT_DEADLINE`（计数 `ENTRY_REJECT_INVALID_QUOTE_AT_DEADLINE`），不改用后面行的价格 |
| 出场、管理、服务器 SL/TP、风险、手数、费用 | B4A 规则 | 不变（出场／管理仍是下一行规则，SL/TP 每行检查） |

关于 Codex 指出的冲突（到期后首行无效、OnData 跳过 Step 时，单靠 ProcessDue 钩子不会执行）：按用户的裁定处理。

- 提交发生在首个 valid ready 行；快照仍是首次跨越时捕获的那一份。
- 额外等待行数 `extra_wait_rows`（提交行序号减跨越行序号）与 `engine_lag_ms`（提交行 ms 减到期 ms）分别披露。
- 不用无效报价调用完整 Step，不伪造 LEAN 时间，也不称“首行精确执行”。
- 价格变化（`PriceChangedVsB4ARule`）与持仓起始行变化（`StartRowChangedVsB4ARule`）分两列记录。

源码默认延迟仍为 250 ms（runner 固定 `$LatencyMs=250`）。风险参数全部沿用 B4A。

## 2. 文件与最小 diff

都在 `lean/algorithms/S4B4B/` 下：

- **`S4CoreB4B.cs`**：冻结 S4Core（ee509e1d）的 fork。相对原文件删 7 行、增 38 行，见 `S4CoreB4B.diff`（已与当前文件重新生成比对，正文一致）。改动如下：
  - 命名空间改为 `TradingBrain.S4B4B`（类名仍为 `S4Core`）。
  - 新增 `EntryQuote`、`PendingEntryDeadlineMs` 和 `EntryQuoteAtDeadline` 钩子。
  - `ExecuteEntry` 改为显式传入 bid/ask。
  - ProcessDue 增加钩子分支：严格 `DueMs < ServerMs`。
  - 新增 `ENTRY_MODEL_TIMES` trace 记录。
  - **钩子为 null 时语义与原版完全相同**：仍是 `<=`，用当前 Q 报价。
- **`DeadlineQuoteTracker.cs`**：纯 C#，不依赖 QuantConnect。每行调用顺序是 `BeforeApply → quote.Apply → AfterApply → [仅 ready+valid 时] BeforeStep → core.Step`；fixture 驱动器与 LEAN 算法用同一顺序。
- **`S4B4B1Algorithm.cs`**：B4A 算法的副本，与 B4A 的完整 diff 存于 `builds/S4B4B_CLAUDE_FIXTURE_SELFCHECK_01/ALGORITHM_VS_B4A.diff`（共 67 行增删）。改动如下：
  - 命名空间和类名改为 B4B。
  - Fill/Fee 类改名为 `B4BQuoteFill` / `B4BCommissionFee`，语义不变。
  - 接入 tracker，三个调用点。
  - 新增 `b4b1_entries.jsonl` 和 RESULT 的 `b4b1_entry_timing` 段，schema 为 `S4_LEAN_B4B1_RESULT_V1`。
- **`TradingBrain.S4B4B1.csproj`**：独立程序集。链接冻结的 B4A `QuoteFieldAdapter.cs` 和 4 个 I9 源文件；不链接冻结 S4Core。
- **`run_s4b4b1.ps1`**：由 B4A runner 改写。
  - registry 为 `research/S4B4B1_RUN_REGISTRY.json`，ID 前缀 `S4B4B1_`。
  - 冻结哈希绑定 13 个文件：S4Core、B1 fixtures、B4A 全部 6 个文件、I9 4 个文件。
  - Fixtures 模式要求 B4B1 21、B4A 27、B1 90 的通过数精确匹配。
  - 预算：Smoke 1 次加 1 次带 `-CorrectionReason` 的修正；FullAugust 1 次，复用 smoke DLL。
  - 行数门槛：smoke 923807，full 20513403。
  - RESULT 必须带 `b4b1_entry_timing` 段，且 schema 匹配。
- **`fixtures/`**：`Program.cs` 和 `S4B4B.Fixtures.csproj`。该项目同时编译 fork 和冻结原版 S4Core（别名 O/F），用于等价比对。

冻结文件全部未改，哈希在 runner 的 `$frozen` 中逐一门控：B1、B4A、S4Core、I9、adapter。

## 3. Fixture 自检（仅纯 C#）

自检在 `builds/S4B4B_CLAUDE_FIXTURE_SELFCHECK_01/` 中完成，方式与 runner 相同：使用 `--artifacts-path`，源码树内不留 obj/bin（已核对）。

| 套件 | 结果 | 结果文件 SHA256 |
|---|---|---|
| B4B1 新 fixture | PASS 21/21 | f06e28ff… |
| B4A 原 fixture（冻结源码） | PASS 27/27 | cb2d4846… |
| B1 原 fixture（冻结源码） | PASS 90/90 | 5ab8fc08… |

B4B1 fixture 覆盖以下内容：

1. **hook-null 等价**：延迟 250 ms、钩子为 null 时，fork 与冻结原版在同一合成行情和信号下，逐行 trace JSON 和最终余额**完全相同**。场景含 ARMED、RESERVED、2 次 ENTRY_FILLED、ENTRY_RISK_OVERRUN 减仓、PROTECTION_REQUESTED、TP_TRIGGERED 和 EXIT_FILLED。
   - 说明：该场景在 TP 前未实际执行 SL_MODIFIED。所以 BE 修改的落地分支由 B1 90 项覆盖，而非本等价场景。
2. **延迟 0 等价**：延迟 0 且钩子已设置（钩子被调用就抛异常）时，与原版 trace 完全相同。这证明延迟 0 不走钩子。
3. **无到期同毫秒行**：快照取跨越前最后一行，跨越行价格不用；与 B4A 规则价格不同，`PriceChanged=true`；lag 50 ms，wait 0；`ENTRY_MODEL_TIMES` 已写出。
4. **有到期毫秒行**：该行计入快照（deadline_rows=1）；提交行后移，标记 `StartRowChanged`，`PriceChanged=false`，两者分列。
5. **同毫秒多行**（280 行后接 1028 行）：两行都按原序应用，ordinal=1，deadline_rows=2。
6. **跨越行无效**（交叉报价）：快照仍取首次跨越前的状态；在首个 valid 行提交，extra_wait_rows=2，lag=150 ms。
7. **到期状态无效**：拒单 `INVALID_QUOTE_AT_DEADLINE` 并有计数和 trace；记录 `SnapshotValid=false`。
8. **样本结束前无到期后行**：End 取消，钩子未被调用。
9. **B3 slot1 真实行**（2026-08-03 12:30）：
   - 请求行 .077 是 280 行，计划价沿用上一报价 4052.69；
   - 到期 .327，快照来自 .279 行，成交 **4052.88**，与原生一致；
   - B4A 规则同样是 4052.88，因为 .378 首行是 flag-280 行。
   - 变体：把 .378 首行改为报价行 4052.87 后，B4B1 仍为 4052.88，B4A 规则为 4052.87，标记 `PriceChanged`。
10. **跨服务器日的到期**：纯按 ms 排序，快照和提交都正确。
11. **种子前未就绪行**：不送达，计数为 2；就绪后才能入场。

## 4. 自审发现与未验证假设

- **F1（设计已披露，非缺陷）：持仓起始时间后移。** 到期同毫秒行存在时，B4A 在该行提交，B4B1 在下一行提交，因此持仓起始和首次 SL/TP 检查都晚一行。已用 `StartRowChangedVsB4ARule` 单列，不与价格变化混算。
- **F2：LEAN 订单时间戳是提交行的时间，不是到期时间。** 成交价用的是到期价，因为 `B4BQuoteFill` 使用 core 传入的价格；模型时间写在 `ENTRY_MODEL_TIMES` 和 `b4b1_entries` 中。对账基于提交行报价，与 B4A 同口径。
- **F3（2026-10-14 更正；原表述错误，Codex 在 `CODEX_S4_B4B_PREIMPLEMENTATION_REVIEW_CN.md` 已指出）：提交行上的 SL/TP 检查。**
  - **原文（错误）：**“服务器 SL/TP 从下一行开始检查……要到下一行才触发”。
  - **按源码核对的实际顺序：** `S4CoreB4B.cs` 的 `Step` 依次执行 `ProcessDue()` → `ServerProtection()` → `Guard.Update` → `ManagePositions()` → scan/`Arm` → `ExecuteQueue` → `CaptureEquity`。
  - **延迟入场（latency>0）：** 在提交行 Step 的 `ProcessDue` 中成交，紧接着 `ServerProtection` 遍历全部 `Open` 仓位，所以**新仓在同一提交行就按该行报价检查 SL/TP**，并非一概到下一行。随后同一 Step 的 `ManagePositions` 还会做入场风险核验（ENTRY_RISK_OVERRUN）和 BE 判断。这一点与 B4A 延迟入场相同。
  - **B4B1 新增的组合：** 成交价是到期状态价，而同一 Step 的 SL/TP 检查用的是提交行报价。两者不同时，可能出现“按到期价成交、按提交行价立即触发”。MT5 原生是否有同样的行为未验证。
  - **零延迟（latency=0）不同：** `Reserve` 在 scan 之后的 `ExecuteQueue` 里调用 `ExecuteEntry`，这时本行的 `ServerProtection` 已经执行过，所以新仓的首次 SL/TP 检查在下一行。
  - **覆盖情况：** 现有 fixture 没有单独覆盖“提交行即触发 SL/TP”。8月1–3日 smoke 也没有出现这种情况（见 `S4_B4B1_SMOKE_REVIEW_CN.md`）。本更正只改文档，不改代码。
- **F4：未验证假设。** 包括两项：
  - 到期同毫秒行全部计入（只有 B3 单日证据，MT5 同毫秒内部顺序未证实）；
  - 280/1028 等未知位行沿用 B4A adapter 的处理。
- **F5：8月预期。** 根据设计阶段的样本推断，多数到期后首行是 280 行，入场价可能大多不变。这只是预测，以 Codex 实际运行的 `entries_price_changed_vs_b4a_rule` 等计数为准。
- **F6：未覆盖的分支。** 等价场景没有覆盖 partial-fill／unknown broker status；B4A 本身也未触发这两条分支。
- **F7：S4CoreB4B 构造期的 `EntryQuoteAtDeadline` 是公共可写字段。** 算法只在创建后设置一次；若运行中被改为 null，ProcessDue 会退回 `<=` 原版语义。目前没有任何调用会这样做。

## 5. 交给 Codex 的执行顺序

```
pwsh lean/algorithms/S4B4B/run_s4b4b1.ps1 -Mode Fixtures      # B4B1 21 + B4A 27 + B1 90，数目精确匹配
pwsh lean/algorithms/S4B4B/run_s4b4b1.ps1 -Mode Build
pwsh lean/algorithms/S4B4B/run_s4b4b1.ps1 -Mode Smoke         # 8月1–3日，923807 行对齐
# 仅在 SMOKE_PASS_REVIEW_REQUIRED 之后：
pwsh lean/algorithms/S4B4B/run_s4b4b1.ps1 -Mode FullAugust -SmokeRunDir <dir>   # 复用 smoke DLL，20513403 行
```

Codex 复审建议重点看以下几处：

- `S4CoreB4B.diff`；
- `ALGORITHM_VS_B4A.diff` 中 tracker 三个调用点的位置，特别是 not-ready 和 invalid 的 `continue` 发生在 `AfterApply` 之后、`BeforeStep` 之前；
- 冻结哈希表。

Smoke 和 full 之后需要分层对比 B4A：信号、gate、reservation、入场价、交易。入场价变化逐笔对应 `b4b1_entries.jsonl`。
