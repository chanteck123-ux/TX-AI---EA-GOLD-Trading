# S4 B4B1 全月复审（Claude 只读独立复算，2026-10-14）

- **候选：** `TB500_S4_BE125_LEAN_B4B1`，基线为 B4A（`TB500_S4_BE125_LEAN_B4A`）。
- **复审人：** Claude，同时也是实现者。本文是只读复算，与 Codex 的比较器结果交叉核对，但**不能替代 Codex 的独立复审**。
- **未做的事：** 没有改代码、runner 或 fixture，没有运行 LEAN 或 MT5，没有改 Git。复算只用了 PowerShell/Bash 读文件，没有用 Python。
- **数据与评分：** 2026年8月是已用过的开发数据，不是 OOS。评分 N/A（SCORE_TARGETS_UNSET）。
- **结论边界：**
  - 本研究**没有带来收益改善**；
  - 真实截止边界仍未得到验证；
  - B4B2（同步阻塞／回调抑制）没有实现；
  - 没有 Champion、Demo 或实盘结论；
  - 不声称完整 parity 或七策略迁移。

## 1. 运行身份与构建复用

| 项 | 值 | 复算 |
|---|---|---|
| 全月运行 | `runs/S4B4B1_FULLAUGUST_D250_20261014T133218Z_f3df8aa4` | receipt 状态 `FULL_AUGUST_COMPLETE_REVIEW_REQUIRED`，end_date 2026-08-31 |
| 构建方式 | `REUSED_MATCHING_SMOKE_BUILD`，smoke 为 `S4B4B1_SMOKE_D250_20261014T133139Z_f80bcfbe` | 全月目录与 smoke 目录中的 `TradingBrain.S4B4B1.dll` 磁盘哈希都是 **941b83e6…**；`compile.log` 都是 **0edd302d…**；与两份 receipt 的记录一致 |
| RESULT | a5c1976e… | 磁盘复算与 receipt 一致 |
| 配置 | latency 250，protective QUOTE，佣金 3.5 | 与 smoke 相同 |
| source_hashes | 21 项（8 个自有文件 + 13 个冻结文件） | 磁盘复算 0 处不符；与 smoke receipt 的列表逐项相同；与 `S4_B4B1_TOOLS_READY.json` 一致 |
| bound copies | 9 份 | 磁盘复算 0 处不符 |

## 2. 结果复算（直接读运行文件）

**行覆盖：**
- 原始行 20513403 = 送达 core 20513402 + 未就绪 1 + 无效报价 0。
- `aligned=true`。

**交易（由 `trades.jsonl` 逐笔求和）：**
- 56 笔，28 胜 28 亏，0 笔零盈亏。
- 净利 **102.03 USD**，PF **1.464343**。
- 佣金 5.14 USD，swap 0，合计 0.67 手。
- 出场原因：TP 25 笔，SL 27 笔，SL_AFTER_BE 4 笔。
- 期末余额 602.03。

**对账：**
- 共 225 次检查，`max_tpv_gap_usd` 为 3e-12。
- 数量、清算费、缓存报价三项不一致都是 0，`passed=true`。
- 期末 LEAN TPV 与 ledger 都是 602.03。

**回撤（35.88 USD／6.071916%）：** 这是 RESULT 中 core 按 tick 维护的 MaxEquityDD，与 B4A 和原生 EA 自己的 `CaptureEquity` 值相同（见 `S4_B4A_FULL_REVIEW_CN.md`）。

**新观察（仅为线索，不是结论）：**
- 用每分钟一次的 `equity_curve.csv` 的 `equity_mt5` 列复算峰谷回撤，得到 **33.22 USD／5.590321%**。
- 这与 MT5 测试器的 `STAT_EQUITY_DD`（33.22／5.5903%）完全相同。B4A 全月复审时，这个数的来历还没有解释。
- 这提示两者差异可能来自采样点不同：分钟采样会漏掉逐 tick 的谷底。但本次没有证据说明测试器实际用什么采样，所以**不作为结论**。
- B4A 全月的 equity_curve 与本次逐字节相同，因此对 B4A 同样成立。

**曲线列的口径说明：**
- 曲线上 `equity_mt5` 与 `lean_tpv` 的最大差是 0.11 USD。原因是 `lean_tpv` 含净清算费，这是公式口径不同，不是对账差异；对账用的是含费公式。
- `peak_dd_pct` 列的最大值是 5.890484%，与上面两个数都不同。该列的峰值口径本次没有追查。

## 3. B4B1 截止计时（由 `b4b1_entries.jsonl` 和 `ENTRY_MODEL_TIMES` 复算）

| 项 | 复算值 |
|---|---|
| 截止记录 / ENTRY_MODEL_TIMES / 不同 book 数 | 56 / 56 / 56 |
| 快照有效 | 56；拒单 `INVALID_QUOTE_AT_DEADLINE` 为 0 |
| deadline_rows>0 | 0（“到期同毫秒行”假设本月没有被触发） |
| extra_wait_rows>0；提交行≠跨越行 | 0；0 |
| 与 B4A 规则相比的价格变化 / 起始行变化 | 0 / 0 |
| 到期 = 请求 + 250 ms | 56/56 |
| engine_lag 字段 = 提交 ms − 到期 ms | 56/56 |
| engine_lag | 最小 14，最大 **398**，平均 65 ms；超过 250 ms 的有 2 笔 |
| 快照行 ordinal>0 | 37 笔，即快照行是其毫秒内的第二行，属于常见的 280+1030 成对结构，不是到期同毫秒行 |
| ENTRY_FILLED 价格 = B4B1Price；成交 ms = SubmitRowMs | 56/56；56/56 |
| 提交行即被 SL/TP 平仓（exit_msc = entry_msc） | 0 |

**为什么本月无法区分两种规则（已用原始数据核对）：**
- 56 笔中，提交行自身的有效报价都与到期快照相同（deadline_bid/ask 等于 submit_row_bid/ask）。
- 在 `quantconnect_20260920/data/raw/ticks_202608*.csv` 中逐一查找每个跨越行 ms 的**第一条原始行**，56 条的 flags **全部是 280**（LAST/VOLUME 行，B4A adapter 规定这类行保留上一报价）。其中 26 个毫秒只有这一行，30 个毫秒还跟着一行。
- 因此 B4A 规则取的“第一个 ms≥到期的行”恰好沿用了到期前的报价。两种规则同价、同提交行，是**数据结构使然**，不能证明 B4B1 的截止语义更接近原生。
- 跨越行无效时的顺延、到期状态无效时的拒单、到期同毫秒行，这三个分支本月都没有发生，目前只有 fixture 证据。

## 4. 与 B4A 全月（3f926243）直接比对

| 文件 | 结果 |
|---|---|
| signals.jsonl（75 行）、decisions.jsonl（464 行）、trades.jsonl（56 行）、protection.jsonl（141 行） | 逐字节相同 |
| equity_curve.csv（28981 行）、lean_transactions.csv（112 行） | 逐字节相同 |
| orders.jsonl | B4B1 共 336 行，去掉 56 条 `ENTRY_MODEL_TIMES` 后剩 280 行，与 B4A 的 280 行逐行相同 |

关于 orders.jsonl 的字节差：首次比较出现字节差，原因是 Git Bash 的 `grep` 在过滤时去掉了 CR。两边都去掉 CR 后，SHA256 同为 **c756d752…**；长度差 280 字节，正好每行一个 CR。

结论与 Codex 的 `CODEX_S4_B4B1_FULL_CHECK.json`（31e73530）一致：逐字节相同 6 个文件，orders 逐行相同，timing_failures 0，lag 14–398 ms，21 项源码身份全部通过。

## 5. 与原生逐层对照

- Codex 的 `CODEX_S4_B4B1_LAYERED_COMPARISON.json`（faaf7508）读取原生 D4BF2385 的文件。这些文件的哈希与原生 RESULT 记录一致。逐层结果：
  - 信号 75/75；
  - gate 决策 34/34；
  - reservation 56/56；
  - 入场成交 56/56；
  - 交易与保护（第 5–6 层）56/56；
  - 以上各层都没有差异项，`first_divergence=null`。
- 账户层（第 7 层）：
  - 净利、PF、佣金、胜率、最长连亏 3、日净值止损 2 次（08-13、08-27），两边都相同。
  - 只有回撤口径不同：原生取测试器的 33.22／5.5903%，LEAN 取按 tick 计算的 35.88／6.0719%。这是第 2 节所述的定义差异，不是路径差异。
- 隔夜层（第 8 层）：原生与 LEAN 都没有跨服务器 00:00 的持仓，所以 LEAN 未建模 swap 这一缺口（G3）本月没有暴露。
- 保护请求方面，原生与 LEAN 都是请求 29 次、确认 28 次，未确认的同为一笔 `S4_MOMENTUM_1787766600`（请求后仓位先平）。
- **传递性核对：**B4B1 的 trades 与 B4A 逐字节相同；B4A 全月的 trades 已经由 Claude 的独立分层比对（`S4_B4A_CLAUDE_LAYERED_COMPARISON.json`，928369c5）证明与原生相同。因此 B4B1 的交易层与原生相同，这一点不只依赖 Codex 的比较器。
- 这只说明本月这 56 笔在所列各层与原生相同。不等于完整 parity，因为毫秒内的事件顺序、同步阻塞与回调、未触发的分支都没有验证。

## 6. 结论

1. **工程结论：** B4B1 全月运行有效。构建复用了 smoke DLL，源码哈希全部一致，对账通过，计时字段完整且自洽。
2. **研究结论：**
   - 在 2026年8月这份已用开发数据上，B4B1 与 B4A 的交易结果**完全相同**（净 102.03，PF 1.4643，DD 35.88／6.0719%）。**没有收益改善**，也没有恶化。
   - 截止语义的差别在本月**没有被检验到**，原因是 56 个跨越行都是 280 行。
   - 真实截止边界（到期同毫秒行、跨越行无效）仍是未验证假设。
3. **不声称：**
   - B4B1 比 B4A 更接近原生；
   - 首行精确执行；
   - B4B2 已实现；
   - OOS、Champion、Demo 或实盘就绪；
   - 七策略迁移。
4. **可选的后续方向（需要另行授权，本文不启动）：**
   - 用原生测试器探针，或在包含跨越行为报价行的样本上，寻找能区分 B4A 与 B4B1 规则的实际事件；
   - B4B2 回调与阻塞模型对照；
   - 解释 33.22 的采样口径（只读探针即可）。

## 7. 本次文档改动

- 新增本文件。
- 在 `research/STAGES.jsonl` 追加一条复审记录。
- 代码、runner、fixture、冻结文件和 READY 文件都没有改动。
