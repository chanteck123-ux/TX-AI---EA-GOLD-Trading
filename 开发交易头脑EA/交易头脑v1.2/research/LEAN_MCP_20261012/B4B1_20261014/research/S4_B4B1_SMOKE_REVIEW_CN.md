# S4 B4B1 Smoke 复审（Claude，2026-10-14）

- 候选：`TB500_S4_BE125_LEAN_B4B1`，基线为 B4A。
- 复审人：Claude（实现者本人，不能替代 Codex 的独立复审）。
- 本次只读核对 Codex 的实际运行文件，不改代码，不运行 LEAN 或 MT5。
- Smoke 区间为 server 2026-08-01 至 08-03，属于已用过的开发数据，不是 OOS；评分 N/A（SCORE_TARGETS_UNSET）。
- 全月运行 `S4B4B1_FULLAUGUST_D250_20261014T133218Z_f3df8aa4` 已由 Codex 启动（registry 状态 STARTED），本文不涉及。全月完成后另做独立复审。

## 1. 核对的证据

| 项 | 路径 / ID | 核对结果 |
|---|---|---|
| Fixtures | `builds/S4B4B1_FIXTURES_D250_20261014T133103Z_24a6a32e` | `FIXTURES_PASS`：B4B1 21、B4A 27、B1 90。B4B1 结果文件（f06e28ff）和 B1 结果文件（5ab8fc08）与 Claude 自检**逐字节相同**。B4A 结果文件只差 `work` 路径一行。 |
| Build | `builds/S4B4B1_BUILD_D250_20261014T133115Z_73afadb8` | `COMPILED`，compile.log 为 0 警告、0 错误，DLL 04b04c97 |
| Smoke | `runs/S4B4B1_SMOKE_D250_20261014T133139Z_f80bcfbe` | 见下表 |

Smoke 运行文件与哈希：

| 项 | 内容 |
|---|---|
| receipt | 597371e4，状态 `SMOKE_PASS_REVIEW_REQUIRED` |
| build_mode | `FRESH_COMPILE` |
| RESULT | ab07adf8 |
| DLL | 941b83e6（磁盘文件已复算一致） |
| `b4b1_entries.jsonl` | 249fb4f0 |

- Smoke 与 Build 是两次独立编译，DLL 字节本来就不同（路径和 PDB），不影响结论。全月复用的是 smoke 这个 DLL（941b83e6）。
- receipt 的 `source_hashes` 与 `S4_B4B1_TOOLS_READY.json` 中 8 个自有文件、13 个冻结文件的哈希逐一相同。

## 2. Smoke 结果（实际文件）

**行覆盖：**
- 原始行 923807 = 送达 core 923806 + 未就绪 1 + 无效报价 0。
- 对齐通过，与 B4A smoke 完全相同。

**对账：**
- 共 17 次检查，`max_tpv_gap_usd` 为 0。
- 数量、清算费、缓存报价三项不一致都是 0，`passed=true`。
- 期末 LEAN TPV 511.53，ledger 余额 511.53。

**交易：**
- 4 笔，3 胜 1 亏，净 +11.53 USD，PF 2.5947。
- 最大净值回撤 15.13 USD（2.94%），佣金 0.32。

**B4B1 入场计时（`b4b1_entry_timing` 及逐笔记录）：**

| book | 到期 ms | 快照行 ms（ordinal） | 跨越行即提交行 | lag | 价格 |
|---|---|---|---|---|---|
| 1 | …000320 | …000272（1） | …000373 | 53 | 4057.94 |
| 2 | …200327 | …200279（0） | …200378 | 51 | 4052.88（即 B3 slot1） |
| 3 | …500337 | …500292（0） | …500625 | 288 | 4047.10 |
| 4 | …700273 | …700216（1） | …700316 | 43 | 4038.87 |

- 4 笔全部满足 deadline_rows 0、extra_wait 0、拒单 0。
- 与 B4A 规则相比，价格变化 0 笔，起始行变化 0 笔。

## 3. 与 B4A smoke（cdccb990）的独立逐文件比对

这一节没有只依赖 B4B1 内部的 `b4a_rule` 诊断列，而是直接比对两次运行的输出文件。

| 文件 | 结果 |
|---|---|
| signals / decisions / trades / protection | 逐字节相同 |
| equity_curve.csv、lean_transactions.csv | 相同 |
| orders.jsonl | 去掉 B4B1 新增的 4 条 `ENTRY_MODEL_TIMES` 后，在忽略换行符差异的前提下逐行相同；这包括全部 RESERVED、QC_ORDER、ENTRY_FILLED 和 EXIT_FILLED 的价格与时间 |
| RESULT.json | 去掉 ID 和 schema 字段后，只多了 `b4b1_entry_timing` 段和 assumptions 文本的更新；指标、对账、adapter 统计全部相同 |

## 4. 复审结论与局限

1. **工程链路通过。**
   - fork 接入后，smoke 交易层与 B4A 完全一致；
   - 对账为零差；
   - 计时字段如实输出；
   - 冻结源码哈希门控有效。
2. **本 smoke 不能区分 B4B1 与 B4A 规则。**
   - 4 笔中，每笔提交行自身的有效报价都与到期快照相同（`ENTRY_MODEL_TIMES` 中 deadline_bid/ask 等于 submit_row_bid/ask）。也就是说，跨越行没有改变有效报价。
   - 因此“同价、同提交行”是数据使然，不能证明 B4B1 规则正确，也不能证明它更接近原生。
   - book 2 的 4052.88 与 B3 原生一致，但 B4A 在该笔上同样是 4052.88。
3. **以下分支没有被 smoke 触发：**
   - 到期同毫秒行（未验证假设）；
   - 跨越行无效时的顺延提交；
   - 到期状态无效时的拒单。

   这些目前只有 fixture 证据。
4. **F3 更正：** 自审原 F3 表述错误，已更正，Codex 在 `CODEX_S4_B4B_PREIMPLEMENTATION_REVIEW_CN.md` 中已指出。
   - core 的 `Step` 顺序是 `ProcessDue` → `ServerProtection`，所以延迟入场的新仓在**同一提交行**就会按该行报价检查 SL/TP，并非一概到下一行。
   - 零延迟时，`Reserve` 在 scan 之后的 `ExecuteQueue` 中成交，首次检查才在下一行。
   - B4B1 新增了一种组合：按到期价成交，再按提交行价做同行保护检查。MT5 原生是否如此未验证。
   - Smoke 中 4 笔的出场都远离入场行，所以没有出现同行触发。
5. **不声称以下事项：** 完整 parity、策略改进、首行精确执行、OOS、Champion、Demo 或实盘就绪。
6. **下一步：** 等全月 f3df8aa4 完成后，独立复审全月结果。重点是：
   - `entries_price_changed_vs_b4a_rule` 和 `entries_start_row_changed_vs_b4a_rule` 的实际计数；
   - 分层比对 B4A 全月 3f926243 与原生（信号、gate、reservation、入场价、交易）；
   - 是否出现 deadline_rows、extra_wait 或提交行同行触发保护的情况。

## 5. 本次文档改动

- 新增本文件。
- `research/S4_B4B1_CLAUDE_SELF_REVIEW_CN.md`：只更正了 F3。该文件不在 runner 的 `source_hashes` 中，修改不影响全月运行的哈希门控。
- `S4_B4B1_TOOLS_READY.json` 保留原样，作为历史记录；其中记录的自审哈希 8987aae0 是更正前的版本。
- 代码、runner、fixture 和冻结文件都没有改动。
