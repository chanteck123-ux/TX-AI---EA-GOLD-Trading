# tb-lean-monitor 自查与复审（Claude，2026-10-12）

## 版本与证据
- 当前源码 **v1.2.0**（在 Codex 独立验证的 v1.1.0 基础上，只新增“截断明示”字段与 2 项单测，未改其他行为）。Codex 的 `CODEX_UNIT_TEST_FINAL.log`（29 项）与 `CODEX_STDIO_VERIFICATION.json`（54 checks）对应 v1.1.0 文件哈希，**需要 Codex 对 v1.2.0 重跑一次**才能把独立验证绑定到当前文件。
- 我的自查（v1.2.0）：`verification/CLAUDE_UNITTEST_3.txt` 31 项 OK、1 项 skip（本账户无符号链接权限；联接/重解析拒绝已实测）；`verification/CLAUDE_SELF_CHECK_STDIO_3.json` 官方 SDK 客户端对真实工作区 54 checks 全通过。保留一次失败证据 `CLAUDE_UNITTEST_1_RACE_FAILURE_kept.txt`：原始 stdio 测试一次性写入后关 stdin，服务器在回答第 3 个请求前退出（测试竞态，非服务器缺陷）；已改为逐条等待响应，连续 5 次通过。

## Codex 初审各项的处理
| 初审要求 | 处理 |
|---|---|
| `secret_root:x` / NTFS 流 | 相对部分出现 `:`（盘符除外）即 `INVALID_PATH`；`workspace:` 后接绝对路径也拒绝 |
| 显示名被 normcase 小写化 | 查找键与原始路径分开存储，显示原大小写 |
| 内部发现绕过策略 | 日志、summary、回执、STAGES、I18 验证、MT5 列表、源码遍历全部经同一 `allowed()`（逐级祖先检查、重解析点、私密目录、凭据名）；无 `rglob`，`os.walk(followlinks=False)` 且逐目录过滤 |
| 基线需哈希 | 首次调用即对全部跟踪文件存 SHA‑256；之后按哈希判 `MODIFIED`（含前后哈希），仅 mtime 变化为 `touched_content_unchanged` |
| 近期写入≠进程存活 | 只有同一会话两次调用间观察到增长才报 `…GROWTH_OBSERVED`；否则 `RECENT_LOG_WRITE_LIVENESS_UNCONFIRMED`，并在 `liveness_rule` 中说明服务器看不到进程 |
| I9 七套信号层 | 迁移图写明 quantconnect_20260920／lean_500_20260927 为 S1/S4 信号层，mt5_iteration9 I9 SevenSignalsAlgorithm 为七套信号层；均非完整成交／退出迁移 |
| 截断明示 | 见 README“截断一律明示”；日志标记扫描窗口外的早期失败不会被看到，以 `scan_note` 说明而不声称“无失败” |

## 已知限制与风险（复审时请重点看）
1. **日志扫描窗口**：标记只看每个日志尾部 256 KiB。很长的日志里早期出现的异常若后来没有重复，会被漏判；已用 `scan_window_truncated` 显式提示。
2. **MT5 Common/Files 前缀白名单**（`AUDIT_`、`SCALPI…`、`QC_`、`V400`、`v3.20` 等）按现有文件名归纳；若以后输出新前缀需加入，否则被拒（保守失败）。
3. **脱敏是规则匹配**：覆盖口令／令牌／JSON 密钥字段／账户号（≥5 位且前有 login/account）／邮箱／常见 API key 前缀，不能保证识别所有私密格式；因此另以目录/文件名拒绝凭据与终端配置。
4. **进度记忆只在单个服务器进程内**；客户端重启会重新建立基线。内存随跟踪文件数增长，上限由 5000 文件上限约束。
5. **哈希成本**：基线会对至多 5000 个文件（单文件 ≤32 MiB）计算 SHA‑256；`scope=all` 包含 I18 候选源码，目前规模很小。
6. 稳定性探测每个尾读增加约 0.15 s。
7. 服务器测试通过 ≠ 客户端已加载；Codex 的 `CLIENT_CONFIG_RECEIPT.json` 记录为 `CONFIGURED_CLIENT_LOAD_NOT_VERIFIED`，我未改任何客户端配置。

## 范围声明
LEAN 引擎仍被应用控制阻止（`lean_probe_01`，0x800711C7），没有任何 LEAN 算法执行；本目录只有监控与迁移计划，**不宣称任何 LEAN 迁移完成**。监控只在被调用时读取，没有后台或空闲时的自动改代码。评分 N/A。
