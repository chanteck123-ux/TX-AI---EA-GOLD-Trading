# S4 B2 Codex独立复审（2026-10-13）

只读诊断已独立复现；报价和延迟成交机制仍未证明。没有新策略收益，没有改动B1交易代码，没有启动MT5测试或实盘。

## 独立核验

读过QuoteDiag.cs、Program.cs的读取/候选/核验/事件提取/统计逻辑及运行脚本。独立运行 `run_quotediag.ps1 -Label S4_B2_CODEX_VERIFY`，生成 `diagnostics/S4_B2_CODEX_VERIFY_20261013T142855Z`：新编译0警告0错误、工程自测12/12通过。

与Claude的R2 `S4_B2_QUOTEDIAG_20261013T142824Z`比较：events.csv及evidence_rows.csv的SHA逐字节相同，stats_all一致。4份工具源码哈希与该次运行回执一致。没有把已作废R1当最终报告。

## 当前发现

- 共55个共同预留，220个事件窗口；43组预留时间同毫秒，其中22组计划价不同。
- 这22组中，MT5计划价22/22吻合窗口内前一原始行，同毫秒首末行0/22；LEAN计划价则同毫秒行22/22吻合。
- 假设锚点“缓存报价时间+250ms”之前最后一行的价格吻合全部55个原生成交价；之后第一行只吻合20个。实际成交时间只有秒，且同价行多于一条，所以不能确定真实成交是哪一行。
- 新柱首批tick与后续tick的切分是看过结果后的发现，只能登记为下一轮假设，不能宣称独立验证通过。

## 数据绑定及时间限制

工具核对raw manifest链、所用原生CSV proof链、LEAN结果回执。工具自身对LEAN orders.jsonl只记录当前SHA，明确标CURRENT_FILE_HASH_ONLY。

Codex另查B2前已制作的B1交付包MANIFEST：orders.jsonl期待SHA为 `e9a0f29f452f7992296aeb9edab4defa59fdc03e07e2bd9478871c190a5c9e46`，与当前文件一致。交付ZIP SHA为 `dba9526f5ab9ffbd54f943742a301daa9b2d87fbaeb6ae074514e0cf8b75f928`。这是独立归档比对，不把工具本身描述成已有该拒绝门。

MQ5 Audit使用全局quote.time_msc；ORDER_SENT在同步OrderSend返回后记录，但之间没刷新quote。日志毫秒是缓存报价时间，不是独立测量的发送或成交时间。quote在其他入口也会刷新，不能概括为全EA仅CanExecute更新。窗口内最近行不等于无限历史最新行情。

下一步取证分两种：无交易探针核查SymbolInfoTick和新柱/OnTick时序；真实延迟成交取证需要另行登记历史测试器订单探针，记录DEAL_TIME_MSC及请求前后报价。虚拟发单无法验证真实OrderSend阻塞。当前两种探针均未运行。

评分N/A / SCORE_TARGETS_UNSET；八月仍是已使用开发数据，无OOS、Champion、模拟或实盘证明。S1–S6及Scalping原版本和恢复点保留。
