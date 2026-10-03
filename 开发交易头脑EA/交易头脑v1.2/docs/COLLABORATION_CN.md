# Codex 与 Claude 协作

当前用户指定 Codex 与 Claude 共同讨论方案、双方复审；代码由 Claude 负责，Codex 负责协调、编译／测试与证据整理。完整分工以根目录 AGENTS.md 为准，不默认互换代码职责。切换工具不切换交易引擎、验收标准或当前有证据的版本。

2026-10-03 补充核实：已通过 Claude 桌面版完成消息收发和协作流程讨论；随后已告知主仓库与指标库，Claude 界面显示 Added 2 memories 并列出 gsm-ea-gold-trading.md 与 preferences.md，回复确认保存了仓库用途、链接及分工；尚未实际读取仓库。Claude Code CLI 与后台自动协作仍未验证。未购买 API、启动后台服务或开展新 EA 研发。

## 共用规则和分工

仓库根目录的 [AGENTS.md](../../../AGENTS.md) 是共用规则；[CLAUDE.md](../../../CLAUDE.md) 只用 `@AGENTS.md` 导入。Claude Code 的导入方式见 [官方文档](https://code.claude.com/docs/en/memory)；启动后用 `/context` 核对实际加载情况，不能只凭文件存在就说已连接成功。

| 环节 | 当前负责人 | 交接与核验 |
| --- | --- | --- |
| 方案 | Codex 与 Claude | 共同讨论和完善，重要方案先独立分析再交叉检查 |
| 代码 | Claude | 编写、修改、自查，列明未验证假设和影响范围 |
| 复审 | Codex 与 Claude | 双方检查方案、需求、接口、受影响完整逻辑和原始证据 |
| 编译／测试 | Codex | 在已有环境与授权内执行，保留版本、哈希、原始日志与报告，双方核对结果 |
| 修正与复验 | Claude 修正；双方复审；Codex 验证 | 每次修改重做受影响验证，不把意见一致当作测试通过 |

同一文件同一时间只交给一位实现者。并行候选用独立分支或 worktree；合并前核对基线提交与冲突。两位 AI 意见一致不等于策略已通过验证；不同意见按证据解决，不用投票或高置信度替代回测。

## 每次交接只带一份记录

以 [candidate.template.json](../research/candidate.template.json) 为起点，每个实际候选独立保存。至少交接：任务目标、策略归属、允许改变与必须固定的项、父版本提交、候选和运行编号、源码/EX5/参数哈希、已运行测试及失败原因、待解决问题和下一步。

可直接给另一位 AI 的任务文字：

> 请先读取相对仓库根目录的 AGENTS.md、docs/GSM_EA_RESEARCH_BRAIN_CN.md、research-memory/README_CN.md 和 research-memory/STATE_CN.md；再以 开发交易头脑EA/交易头脑v1.2/ 为项目根目录，读取其 README.md、docs/PLAN_CN.md、research/CURRENT.json 和本轮候选记录。按用户指定分工共同讨论方案，代码由 Claude 写改，双方复审，Codex 编译／测试并提供原始证据。先核对源码与证据哈希，检查工作树是否有他人修改；只推进已授权任务。保护用户 Scalping SOP，保持 MQL5 独立交易和风控，不把历史报告当本轮新成绩。结束时更新同一候选记录，写清完成项、未完成项及恢复点。

知识大脑位于本仓库 [docs/GSM_EA_RESEARCH_BRAIN_CN.md](../../../docs/GSM_EA_RESEARCH_BRAIN_CN.md)，长期资料入口为 [research-memory/README_CN.md](../../../research-memory/README_CN.md) 和 [STATE_CN.md](../../../research-memory/STATE_CN.md)。用户指标库为 [gsm-mt5-indicators](https://github.com/chanteck123-ux/gsm-mt5-indicators)，优先读取其 README.md、indicator_manifest.json 及对应接口／验证说明。要求 Claude 记住两个仓库的用途和这些入口，每次实际任务仍核对最新内容；无法访问时报告具体缺口，不声称已读取。

GitHub 记录不自动共享聊天、账户权限、API key 或本地路径，也不自动创建 Claude 产品的跨聊天记忆。Claude 云端若无法访问 Windows 编译器和固定 MT5，只能如实提交代码/审查；编译与原生测试由 Codex 在可用且获授权的环境执行；环境不可用时记录未执行项，不冒充验证完成。

## 固定终端只允许一个测试任务

MetaEditor 编译、MT5 Tester 和安装由当轮单一执行者串行操作。研究登记写明 `terminal_owner` 与开始/结束时间；执行前检查终端进程、在途测试和输出路径。发现另一个任务占用就等待或交接，不能另建数据目录绕开冲突。此为当前协作约定，**尚未实现自动锁服务**。

固定目录：`C:\Users\A\AppData\Roaming\MetaQuotes\Terminal\523FF71FCA93BC15AC28868379E0D478`，沿用 `/portable`。配置、报告与日志按唯一 `candidate_id/run_id` 绑定，不覆盖上一轮。

## 可选工具

| 工具 | 允许角色 | 2026-10-03 本次核对 |
| --- | --- | --- |
| GitHub | 代码版本、计划、任务与证据索引 | 已读取现有两仓库，本次整理主仓库 |
| Data | 研究上下文与报告核对 | 本次用于证据和定义梳理，无新绩效计算 |
| Remote Desktop Commander | 未来操作 Windows 研究环境 | 未发现已连接设备；本次使用现有本地文件工具 |
| Railway | 未来可选监控或报告展示 | 未发现项目；未部署 |
| Claude 桌面版 | 共同讨论与复审，承担代码任务 | 已验证消息收发、流程讨论及两条持久记忆更新；仓库读取未验证，本轮未下发代码开发任务 |
| Claude Code | 可用时按相同分工承担代码与复审 | CLI 安装／账号连接未验证；CLAUDE.md 导入不等于桌面版自动加载 |

这些状态只描述本次检查，后续使用前重新核对。MQL5 的已有仓位保护、对账和风控不能等待任何 AI、MCP、远程桌面或云服务。

## 第七轮实际协作范围（2026-10-03）

本轮通过Claude桌面聊天实际交换了设计和结果／失败摘要，收到了处置复审意见；Claude明确没有读取本地源码、日志或原始文件，没有独立核实指标和事件顺序，也没有提供EA代码。Codex完成原始证据核验和10次串行原生测试，其中9次严格通过、S5八月1次审计无效。此处不声称双方已完成原始证据独立复审。

S5请求终态修复及S2下一根独立M5确认规格已保存在工作区；[S5待实现交接](../research/evidence/MT5_ITERATION7_S5_HANDOFF_20261003_CN.md)列明需要交付的源码与证据。尚未作为实际代码任务提交，未实现、未编译或复测。后续由Claude改候选、双方复审、Codex运行新版本配对验证；旧失败保持无效。CLI、API和后台自动协作仍未验证，本轮没有新增持久记忆操作。
