# tb-lean-monitor：LEAN 研究只读 MCP 监控（stdio）

Claude Code 编写，Codex 负责启动验证与客户端接入。**Python 只做监控**：不编译、不启动回测/优化、不写文件、不改配置、不发订单、不执行任何命令；MQL5 EA 的风控独立运行，不依赖本进程。

## 文件
| 文件 | 作用 |
|---|---|
| `server.py` | MCP stdio 服务器（官方 SDK `mcp` 1.x，FastMCP）。stdout 只走协议；诊断写 stderr（脱敏、单条≤2000字符、每进程≤512 KiB）。 |
| `monitor_core.py` | 纯读取逻辑（无 MCP 依赖，可单测）：路径策略、状态分类、源码 diff、日志尾读。 |
| `LEAN_MIGRATION_MAP.json` | 七策略 LEAN 迁移顺序与边界（S4 原保留版第一、Scalping S20 第二，再 S1/S2/S3/S5/S6）。 |
| `test_monitor.py` | unittest（路径/联接/凭据拒绝、脱敏、UTF‑16 尾读、LEAN/构建状态、源码哈希 diff、内部发现不绕过策略、原始 stdio 协议纯净性）。 |
| `verify_stdio_client.py` | 官方 SDK 客户端：握手、tools/list、每个工具正常与异常调用，保存原始记录。 |
| `requirements.in` / `requirements.lock.txt` | 直接依赖 `mcp>=1.30,<2`；锁定版本与 Codex 实装 `.venv` 一致（mcp 1.30.0）。 |
| `config_samples/` | Codex `config.toml` 与 Claude Code `.mcp.json` 样例（**未安装**）。 |

## 运行
```bash
monitor/.venv/Scripts/python.exe -m unittest -v test_monitor
```
```bash
monitor/.venv/Scripts/python.exe verify_stdio_client.py --label "Codex independent check"
```
服务器本身由 MCP 客户端以 stdio 启动：`.venv/Scripts/python.exe server.py`（可选 `--workspace <dir>`、`--mt5-common <dir>`、`--fresh-seconds N`，仅用于测试）。

Codex 接入：把 `config_samples/codex_config.toml` 的表加入 `~/.codex/config.toml` 或受信项目 `.codex/config.toml`（官方键：`command`、`args`、`cwd`、`env_vars`、`startup_timeout_sec`、`tool_timeout_sec`、`enabled_tools`）。Claude Code 接入：项目根 `.mcp.json`（样例同目录）或 `claude mcp add tb-lean-monitor --scope project -- <python.exe> <server.py>`。**服务器测试通过 ≠ 客户端已加载**，两者分别记录。

## 允许读取的范围
- `workspace`：`C:\Users\A\Documents\Codex\2026-09-10\v1-2-ea-mt5`。
- `mt5_common_files`：`%APPDATA%\MetaQuotes\Terminal\Common\Files` 下**名称以本项目前缀开头**的审计文件（`AUDIT_`、`SCALPI…`、`QC_` 等，见 `health`）。
- 一律拒绝：根外路径、`..`、NTFS 流语法（`file:stream`）、任何组件为符号链接/联接/重解析点、`private`/`backups`/`.git`/`.venv` 等目录、`common.ini`/`terminal.ini`/凭据/密钥/令牌/`.env`/`.lock` 文件。**内部发现（日志、summary、回执、STAGES、源码遍历）用同一策略**，不使用 `rglob`。
- `bounded_log_tail`：仅 `.log/.txt/.jsonl/.json/.csv/.md`；≤400 行、≤64 KiB，从文件尾读，UTF‑16（MT5 日志）/UTF‑8 自动识别，输出脱敏（口令/令牌/JSON 密钥字段/账户号/邮箱/API key）。

## 工具与状态语义
每次调用都重新读取当前文件，返回 `observed_utc`、平台、PID、文件路径、大小、mtime、稳定性探测与解析状态。
| 工具 | 内容 |
|---|---|
| `health` | 版本、SDK、根目录、只读政策与上限；声明“客户端是否加载”服务器无法知道。 |
| `research_status` | 迁移图、各策略 LEAN 源码/运行状态、`research/STAGES.jsonl` 记录的 code/compile/backtest/optimize 阶段、引擎探针（`lean_probe_*`）。无记录即 `NO_RECORD`/`NOT_STARTED`。 |
| `source_changes` | 首次调用建立本会话**含 SHA‑256 的基线**；之后按哈希报告 `ADDED`/`MODIFIED`（含前后哈希）/`DELETED_OR_NO_LONGER_ALLOWED`，只改 mtime 不改内容记为 `touched_content_unchanged`；`since_utc` 另按 mtime 过滤。 |
| `run_status` | LEAN 运行、dotnet 构建、MT5 公共审计文件；`include_historical=true` 才列旧 LEAN 与 I18 MT5（均标历史）。 |
| `bounded_log_tail` | 单个日志尾部（见上）。 |
| `latest_results` | 本项目最新 LEAN summary 与关键统计；历史 LEAN 与 I18 MT5 评估仅在 `include_historical=true` 时列出并标 `HISTORICAL_…`，**I18 成绩永不称为 LEAN 成绩**。 |

LEAN 运行状态：`FAILED`（含 `CODE_INTEGRITY_BLOCKED_DLL`、未处理异常、运行时/初始化错误）、`COMPLETED_RESULTS_PRESENT_REVIEW_REQUIRED`（须有退出标记**且**可解析含统计的 summary）、`COMPLETED_RESULT_BEING_WRITTEN`、`ENGINE_EXITED_WITHOUT_VALID_SUMMARY`、`IN_PROGRESS_LOG_GROWTH_OBSERVED`（本会话两次调用之间日志确实增长）、`RECENT_LOG_WRITE_LIVENESS_UNCONFIRMED`（只有近期写入，**不声称进程存活**）、`INTERRUPTED_OR_STALLED_NO_TERMINAL_MARKER`、`NOT_STARTED_OR_NO_LOG`。构建同理：`BUILD_FAILED`、`BUILD_SUCCEEDED_LOG`（DLL 哈希仍需运行记录绑定）、`BUILD_IN_PROGRESS_LOG_GROWTH_OBSERVED`、`BUILD_RECENT_LOG_WRITE_LIVENESS_UNCONFIRMED`、`BUILD_INCOMPLETE_OR_INTERRUPTED`。JSON：`OK`/`MISSING`/`DENIED`/`TOO_LARGE`/`PARSING_FILE_CHANGING`/`PARSE_ERROR`。服务器看不到进程，“存活”只能来自观察到的增长。

**截断一律明示**：源码遍历上限 5000 文件（`truncated_at_file_cap`、`capped_bases`）、各列表 `*_total` 与 `*_truncated_by_limit`、日志标记只扫描文件尾 256 KiB（`scan_window_truncated` 与 `scan_note`，窗口外的早期失败行不会被看到）、构建错误行最多 20 条（`error_lines_total`）、`STAGES.jsonl` 只读尾 64 KiB（`stage_record_scan.window_truncated`）。

**“实时”的含义**：每次调用即时读取当前文件；服务器没有后台任务、不在空闲时轮询、不改代码或配置。两次调用之间的增长只在同一服务器进程（同一客户端会话）内比较。

## 项目目录约定（LEAN 研究写入方，监控只读）
`lean/algorithms/<SID>/`（C# 源码，Claude 写）、`builds/<build_id>/*.log`（Codex 编译日志）、`runs/<run_id>/`（LEAN 输出与 `RUN_RECEIPT.json`）、`optimizations/<opt_id>/`、`research/STAGES.jsonl`（每行一个 `{stage, sid, id, status, utc, evidence}`，由阶段负责人追加）。

## 当前事实与边界
- LEAN 引擎探针 `lean_probe_01` 被 Windows 应用控制阻止加载 `QuantConnect.Messaging.dll`（0x800711C7），**没有算法执行**；监控把它报告为 `FAILED / CODE_INTEGRITY_BLOCKED_DLL`。不改安全政策、不移动/改名/重签 DLL。
- 旧 LEAN 工作只是信号层：quantconnect_20260920 与 lean_500_20260927（S1/S4 信号＋工程风控/成交模型）、mt5_iteration9 I9 SevenSignalsAlgorithm（七套信号层）；都不是完整成交/退出迁移。
- 评分 N/A（SCORE_TARGETS_UNSET）；工程烟测、C# 编译、LEAN 执行、MT5 测试、独立验证与实盘分别报告。
