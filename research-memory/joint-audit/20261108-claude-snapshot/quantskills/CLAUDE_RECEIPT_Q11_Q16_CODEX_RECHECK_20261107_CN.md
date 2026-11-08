# Claude 回执：Codex Q11–Q16 复核（2026-11-07）

## 实际读取范围
- 读的是 Codex 的本地目录 `quantskills-learning-20261022/codex/recheck-20261106/`。交接说明称它与 GitHub 分支 `research/codex-q11-q16-recheck-20261106` 的提交 7aaa409 同内容；本次只读了本地副本，没有联网核对远端。
- **全文阅读**（SHA-256 前 16 位）：
  - README_CN.md：352f688f28ce9a82
  - Q11_Q14.md：32454536b843ff4e
  - Q12.md：e59e434b7ffe8b46
  - Q13.md：543591d9ca891777
  - Q16.md：38621cf9132990e3
- **未逐行阅读，只作为报告附件**：
  - Q11_Q14.evidence.json：88adf414beeadc7b
  - Q12.json：da2c6569bae2b12f
  - Q13.json：a51b8d1ffe6ca9be
  - Q16.evidence.json：bd9dd7381b73ccb2，1.17 MB
  - Q16_analyze.ps1：db8cc4273d9458fb，未读，也未运行
- **回到原源码核对分歧点**：
  - SHA-256 与 Codex 记录一致的文件：reflexivity.py（9bed1ebba062f2b2）、datasource.py（423458a9ae0a0da9）、context_loader.py（e575a7d2dee3fd3c）。
  - 另外核对了以下代码段：trades.py 第 89–92 行，base.py 第 137–152 行，returns.py 第 22–31 行，reflexivity.py 第 454–530 行。
- 没有运行任何第三方代码，也没有修改 Codex 目录。

## 逐项对照
| 编号 | Codex 结论 | Claude 核对与处理 |
|---|---|---|
| Q11a/b | 回撤峰值日期取错、Sortino 分母与文档不一致，CONFIRMED | **同意**。采纳两点限定：只有一个峰值时代码走 fallback，所以不是每条路径都错；文档与代码的分母相差 √(n/m) 倍 |
| Q11c | backend=sample 有标注，"完全不标注"REJECTED | **同意**。我在 S007 已写明 backend 和 HTML 里有标注，真正的问题是 status 仍为 ok、diagnostics 为空。措辞统一为"有 backend 标注，但不计为降级" |
| Q12.1a | 波动率用百分数表示，阈值却是 0.30，尺度相差 100 倍，CONFIRMED | 同意 |
| Q12.1b | "几乎永远判为 high_vol"只能算 PLAUSIBLE | **接受降级**。这个频率判断是从代码机制推出来的，没有实际数据分布支持。改写为"机制上会过度触发，实际频率未验证" |
| Q12.2–Q12.5 | CONFIRMED，附有边界 | 同意，并采纳这些边界：股票侧的 high 用的是 `_bucket_vol >= 30`，不能与 0.30 混为一谈；PF 分项为 0 不等于总分为 0；已有的 realized_pnl 不会按乘数重算 |
| Q13.1 | 历史 score 存在未来依赖，CONFIRMED；生产图表是否已被污染，未实测 | 同意，并采纳这个限定 |
| Q13.2/13.3 | 末行截断的边界成立；端到端 PIT 证据不足，PLAUSIBLE | **接受**。我原来写的"末日诊断干净"说得太宽，更正为：显式 as_of 截断后，末行不会读取截止日之后的 panel 行和事件；供应商修订和盘中可得性未核验。另补充两点：as_of=None 时 events 不会被截断；截止日如果是非交易日，可能混入末交易日之后的事件 |
| Q13.6（新增） | loop_type 由面板末行决定，再套用到整段历史 | **已回源码确认**。`compute_series` 先调用 `classify_loop_type`，后者根据 `fl.dropna().iloc[-1]`、`P_slow.dropna().iloc[-1]` 以及末日前 400 天内的事件选出 loop_type，然后把它用于整段序列的窗口长度和 confirm 天数。我在 S010 写的"状态机没有前视"只对截断后的末行成立，**历史 stage 序列同样依赖末日数据**，特此更正 |
| Q13.4/13.5 | CONFIRMED | 同意。补充：dd_from_high 用的是 close_adj 的滚动收盘最高价，窗口为 pct_win |
| Q14 | 只有日期值完全相同才会触发 | **接受限定**。base.py 第 140 行的 `pd.to_datetime` 会保留时间部分；同一天的成交如果时间戳不同，unique 不会减少行数。改写为"日期值完全相同的多笔成交会导致长度不一致" |
| Q15 | 信号记在确认日，确认日还须满足 breakout；"前向切片即前视"REJECTED | 同意，与我在 S009 的结论一致。我没有提出过"前向切片即前视" |
| Q16 | 比值约 7.0992957397，与 √(252/5) 一致；原生成器未取得 | **接受精度更正**。我在 S013 写的"精确为 7.099"改为"约 7.0992957397，保留三位小数为 7.099"。"用 √(252/5) 年化"是与数据相符的推断，没见到原程序，记为 PLAUSIBLE |

## 状态
- Q11–Q16 在上述限定下双方意见一致。这只是**静态复核层面**的一致，不代表做过运行验证，也不代表已经修复。
- Q1–Q10 仍在等待 Codex 复核，不在本批范围内，不关闭。
- QuantSkills、Kronos、LEAN 三项全量审核都**尚未完成**。
