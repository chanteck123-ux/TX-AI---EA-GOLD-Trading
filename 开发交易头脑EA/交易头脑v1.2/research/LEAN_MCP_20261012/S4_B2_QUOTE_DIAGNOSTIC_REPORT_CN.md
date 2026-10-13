# S4 B2 报价与成交差异诊断报告（只读，Claude，2026-10-13）

按 `S4_B2_QUOTE_DIAGNOSTIC_SCOPE_CN.md` 的事前登记执行：只读离线 C# 诊断。本批**没有**运行策略引擎或 MT5，**没有**修改 B1 R2 的交易代码、配置或运行证据，**没有**使用 Python，也**没有**把原生订单价格输入任何回测。本报告**不识别因果**，**不宣称**盈利改善。评分 N/A（SCORE_TARGETS_UNSET）。2026 年 8 月数据此前已在开发中使用过，不是 OOS。等待 Codex 复审。

## 1. 运行与证据
- 正式运行：`diagnostics/S4_B2_QUOTEDIAG_20261013T142824Z`，回执 `RUN_RECEIPT.json`（48f1b849…），状态 `DIAGNOSTIC_COMPLETE_REVIEW_REQUIRED`。
  - 工具源码：`tools/S4QuoteDiag/`（QuoteDiag.cs c553a742、Program.cs 2d05d637、S4QuoteDiag.csproj 114ff284、run_quotediag.ps1 ca228058）。
  - DLL ab8e0bd4，工程自测 12/12 通过（selftest 05a10333）。
  - 输出：`out/SUMMARY.json`（8a3043d2）、`out/events.csv`（85aab5a2）、`out/evidence_rows.csv`（cbc1d2e6）。evidence_rows 保留每个窗口的全部原始行，含文件、行号、毫秒、同毫秒序号与行数、bid/ask/last/volume、flags 原值及解码。
  - 命令：见回执的 `command` 字段。
- 较早的一次运行 `S4_B2_QUOTEDIAG_20261013T142633Z` 已作废但保留，见其中的 `SUPERSEDED_NOTE.txt`。两次的计算逻辑相同，只有时间语义的标注被修正（见第 2 节）。
- **工程用例**（`--selftest`，合成数据）：
  - 同毫秒首行与末行能区分结果；同毫秒重复行全部保留，行号完整；
  - side-flag 候选：做多用 ASK 位，做空用 BID 位；
  - 窗口跨越日文件边界；无行情时标记缺失；
  - 成交秒内唯一匹配，以及成交时间缺失时的标记；
  - flags 其他位（256、1024）保留；被篡改的 raw 文件会被拒绝。

## 2. 输入核验与时间语义（已按 Codex 源码核对修正）
- **Tick 链：**先核对 `LEAN_TICK_MANIFEST.sourceManifestSha256` ＝ `EXPORT_MANIFEST.json`（9024018…），再逐个核对用到的 20 个 `ticks_YYYYMMDD.csv` 与 EXPORT_MANIFEST 中的 sha256，全部通过（行数见 SUMMARY 的 `raw_files`）。
- **原生链：**proof `VERIFICATION.json` → `native_result.json` → `evidence_sha256`，核对了 `orders_audit.csv` 和 `complete_trades.csv`。
- **LEAN 运行：**回执状态为 `FULL_AUGUST_COMPLETE_REVIEW_REQUIRED`，RESULT 的哈希与回执一致。`orders.jsonl` 要分两层说明（本次修正：原文“B1 任何产物中都没有冻结期望哈希”范围过大）：
  - **诊断工具本身：**只计算并记录当前文件的哈希（e9a0f29f…），工具内没有期望值门控，状态是 **CURRENT_FILE_HASH_ONLY**。工具运行输出（SUMMARY.json）中的 `lean_orders_binding` 文字写成“B1 产物中不存在冻结 SHA”，范围同样过大，以本报告为准；运行输出不重写。
  - **外部归档核对（Codex）：**Codex 在 B2 之前已经建立归档 `outputs/TradingBrain_S4_LEAN_B1_20261013/MANIFEST.json`（94fea769…），其中 `orders.jsonl` 的期望 SHA 为 e9a0f29f452f7992296aeb9edab4defa59fdc03e07e2bd9478871c190a5c9e46，与当前文件一致。归档 ZIP 的 SHA 为 dba9526f5ab9ffbd54f943742a301daa9b2d87fbaeb6ae074514e0cf8b75f928。Claude 已复核以上三个哈希。
  - 因此，orders 输入的防篡改依据来自外部归档比对，不是工具内置的门控。
- **原生时间字段只是缓存报价时间戳：**
  - MQ5 的 Audit（第 231 行）写入的是全局 `quote.time_msc`；`quote` 只在 RiskGate→CanExecute 中的 `SymbolInfoTick`（第 2666 行）刷新。
  - ORDER_SENT 的 Audit（第 3018 行）在同步 `OrderSend` 返回后才写入，两者之间没有刷新报价。
  - 所以 RESERVED、ORDER_SENT、DEAL 三类行的 time_msc 都是**最近一次缓存报价的时间戳**，不是独立测得的发送、回执或成交时间。EA 的真实发送时间未知。
  - 用“缓存时间＋250 ms”作锚点**只是假设**。实际 DEAL_TIME 只精确到秒（complete_trades.entry_time），一律标为歧义。
- **窗口限制：**所有候选（前一行、side-flag 行、最近匹配）都只在 ±2 秒窗口内查找（原生成交的窗口为“缓存时间−2 s”到“缓存时间＋2.25 s 与成交秒末两者中较晚者”）。窗口内的“最近”不等于无限历史中的最新报价。

## 3. 事前登记候选的结果（55 个共同 key，每个 key 4 类事件）
固定候选（事前登记）：
- PREV：锚点之前的最后一行；
- SAME_FIRST／SAME_LAST：与锚点同毫秒的首行和末行；
- SIDE_FLAG：锚点及之前，最后一个带本方向 Bid/Ask 标记的行。

另加一个补充候选，**不属于事前登记**，单列：AT_OR_AFTER，即锚点之后第一行，也就是 B1 R2 中 LEAN 的延迟规则。价格容差 0.005。

| 事件 | 时间语义 | PREV | SAME 首/末 | SIDE_FLAG | 补充 AT_OR_AFTER | 状态 |
|---|---|---|---|---|---|---|
| 原生预留（55） | 缓存报价时间戳 | 41 | 33/33 | 43 | 33 | 单行区分 20，多行歧义 16，候选同价不可区分 19 |
| LEAN 预留（55） | LEAN 处理的那一行 | 18 | 55/55 | 43 | 55 | 单行区分 12，多行歧义 25，候选同价不可区分 18 |
| 原生成交价（55） | 缓存时间＋250 ms（假设） | **55** | 锚点毫秒上没有行（缺失 55） | **55** | **20** | 事前登记候选 55 个全部同价、不可区分；成交秒内匹配行均多于一行，55 个都是歧义 |
| LEAN 成交（55） | LEAN 实际成交行 | 22 | 55/55 | 49 | 55 | — |

在“同毫秒预留、计划价不同”的 22 个子集中：原生预留 **PREV 22/22，同毫秒行 0/22**；LEAN 预留同毫秒行 22/22，PREV 0/22。在“同毫秒、同价”的 21 个子集中，两边的候选大多同价，无法区分。

## 4. 可以说的（描述性，不是机制）
1. **原生成交价：**55/55 都等于“缓存时间＋250 ms 之前的最后一行”（也是 SIDE_FLAG 行）。“之后第一行”（LEAN B1 的规则）只吻合 20/55。所以在本假设锚点下，原生与 LEAN 的成交取价规则表现不同。但实际成交时间只到秒，而且成交秒内有多行同价，具体是哪一行**无法唯一确定**。
2. **原生预留报价（事后观察，不是事前登记的检验）：**36 个能区分候选的原生预留事件，按缓存时间与信号 trigger 的距离可以完全分开：
   - 距离 6–382 ms（新 M5 柱开盘后的首批 tick）的 22 个，全部吻合 PREV；
   - 距离 3.8–254.6 s 的 14 个，全部吻合同毫秒行。
   - 按同毫秒行 flags 组合（280、280/1030、280/1026）分组则没有一致规律（见 SUMMARY 的 `post_hoc_descriptive_not_preregistered`）。
   - 这一切分是看过数据后才发现的，**不能**作为验证结论。
3. 第 3 节中两边的差异，与 B1 复审中“同毫秒内取到的报价不同、首个分歧出现在 8/3 第一笔”的现象一致，但本诊断只给出相关性。

## 5. 尚未确定（待验证的机制，均未确立）
- 原生在新柱首 tick 时，`SymbolInfoTick` 是否返回上一行的 bid/ask，同时时间戳却已经是新 tick（报价缓存与时间戳不同步）；
- 测试器是否把同毫秒的多行合并后才调用一次 OnTick，以及 LAST-only 行（flags 280）是否更新 bid/ask；
- 250 ms 延迟下，同步 `OrderSend` 用的是哪个时点的报价。

在这些机制核实之前，单笔价格吻合**不能**证明任何机制，也不足以修改 LEAN 成交模型。

## 6. 下一项有依据的取证方式（需要用户和 Codex 决定，本批不执行）
两类取证需要**分开登记**（修正：原文把“虚拟发单”写进不交易探针，这样无法检验真实的同步 `OrderSend`）：
1. **报价与 OnTick 探针（不交易）：**在 MT5 测试器中，以与原生基线相同的条件（真实 tick、同一时段）运行。在每次 OnTick 记录 `TimeCurrent`、`SymbolInfoTick` 的 time_msc／bid／ask／flags，以及新柱的检测时点，再与 raw 行号逐行对齐。它**只能**检验报价缓存、时间戳不同步和同毫秒 OnTick 合并这两项机制，**不能**检验真实同步 `OrderSend` 在 250 ms 延迟下的阻塞和取价。
2. **测试器订单探针（另行事前登记，只在历史测试器中运行，绝不用于模拟盘或实盘）：**在 250 ms 延迟下真实提交测试器订单，记录请求前后各自的 `SymbolInfoTick`、`DEAL_TIME_MSC`、成交价以及返回时点，用于检验延迟成交的取价规则。

本批**不启动**以上任何一项。只有在 Codex 复审并另行登记后，才决定是否进行；B2 成交模型候选也要等相应证据出来后才考虑，并须另行编译、跑 smoke 和同条件全月测试。

## 7. Codex 独立复核
`diagnostics/S4_B2_CODEX_VERIFY_20261013T142855Z`：重新编译，0 警告 0 错误；自测 12/12；events.csv 和 evidence_rows.csv 与正式运行逐字节一致（SHA 相同）；stats_all 一致。B2 到此结束。

## 8. 范围声明
本诊断只覆盖 S4 的 55 个共同预留和入场；其余六套策略不受影响。S4 迁移的结论不能代替七策略的成绩。不涉及 Champion、模拟盘或实盘。
