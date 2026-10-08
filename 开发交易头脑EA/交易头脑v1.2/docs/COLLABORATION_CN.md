# Codex 与 Claude 协作

## Claude Code知识同步（2026-10-07）

用户明确本次接收端是 **Claude Code**，目标是接续交易头脑V1.2的全部项目知识。共用GitHub中的规则、计划、状态、研究经验与证据索引，不另写一套平行计划。聊天上下文、账号权限和私人记忆不会因此自动互通；“可访问”“已读取”“已复审”“已测试”分别记录。下方2026-10-03桌面聊天与第七轮记录保留历史身份，不当成Claude Code已读证据。

### 每次任务的同步流程

1. 确认工作区对应 `chanteck123-ux/TX-AI---EA-GOLD-Trading`。记录主库与指标库的分支、HEAD、origin/main及未提交改动；有网络时fetch。干净且可快进才fast-forward；存在并行改动或分叉时保留现场，用diff核对再合并，不reset、不强推、不覆盖他人工作。离线时明确本地提交及可能过期范围。
2. 根 `CLAUDE.md` 导入同一份 `AGENTS.md`。Claude Code会话中用 `/context` 查看实际加载的Memory files；文件存在只证明配置已保存，不证明模型已读取全部资料。启动已有会话后发生的变更须重新读取受影响文件。
3. 首次接手按下表读取知识入口和当前证据，形成已读／未读清单；后续按两个提交之间的变化增量读取。历史原文、Google AI资料和学习库是研究材料，采用规则以用户最新指令及适用项目计划为准。不要读取封存的未见样本成绩来完成“全部同步”。
4. 每次研发仍按本次用户选定的协作模式开展；本次知识同步仅做读取和交接。资料中提及的下一轮不是本次启动代码修改、编译、回测、Demo或实盘的指令。
5. 完成实际研究后由对应责任人更新已有 `research/CURRENT.json`、`research/EVIDENCE_INDEX.json`、本轮候选／结果／经验；规则改变才更新主计划。记录实现者、复审者、source/default/EX5/config/report哈希、失败原因和下一步。未验证想法单独标明，不改写旧失败或历史报告。
6. 提交前复核diff和依赖，非强制推送后核对远端提交。向另一端交接提交、改动路径、当前候选和未完成项；另一端实际读取后回报所读提交／文件。没有运行常驻同步服务，不保证正在进行的聊天自动刷新。

### 全部知识的入口与边界

下表路径以主仓库根为基准，指标库另列；是读取地图，不代表每项已逐字审阅或已经实现。

| 内容 | 权威入口 |
| --- | --- |
| 共同规则、沟通和授权 | `AGENTS.md`、`CLAUDE.md` |
| V1.2架构、七策略、Scalping权限、风险、指标、评分及迭代 | `开发交易头脑EA/交易头脑v1.2/docs/PLAN_CN.md`、项目`README.md` |
| 当前状态和可接续动作 | 项目`research/CURRENT.json`、`research/EVIDENCE_INDEX.json`及当前轮候选／报告 |
| I6至I11成果、失败及恢复 | 项目`research/evidence/`；先I11中文报告、RESULTS、DECISIONS、PROTOCOL、REVIEW、DELIVERY、SCORE_POLICY，再按依赖读取历史证据 |
| 通用交易知识与学习经验 | `docs/GSM_EA_RESEARCH_BRAIN_CN.md`、`research-memory/README_CN.md`、`STATE_CN.md`、`DECISIONS_CN.md` |
| 历史分支、原始材料和来源 | `research-memory/BRANCH_INDEX_CN.md`、`FILE_INDEX_CN.md`、`REPOSITORY_MANIFEST.json`、`GITHUB_RESEARCH_LIBRARY_INDEX.md`、`GITHUB_PRIORITY_SOURCES.md`；旧清单数量只代表其日期 |
| AI Alpha、机器学习、LEAN及反思资料 | `docs/`、`docs/reference/`、`research-library/`、项目`QUANTCONNECT_LEARNING_CN.md`及历史计划；具体采用状态从当前计划核对 |
| 旧GSM三SOP计划及用户原SOP | 根中英文`FINAL_CHAMPION_ITERATION_SYSTEM*`与`gsm-sop/`；通用公式可引用，旧项目验收不得自动套给V1.2 |
| 综合评估工具与用户建议值 | `tools/ea-evaluation/README_CN.md`、工作簿、manifest与验证记录；建议值、验收和评分锚点分别处理 |
| 13项指标、源码／EX5、缓冲区、量价研究 | 指标库当前`README.md`、`indicator_manifest.json`、`packages/`内接口和验证说明、`docs/INDICATOR_RESEARCH_PRINCIPLES_CN_20260927.md`、`docs/PVO_PRICE_VOLUME_INTERPRETATION_CN_20261003.md` |
| 实际EA源码、编译和原始成交证据 | 当前轮`DELIVERY`给出的本地交付路径、`EA_SELECTION.json`、`EA文件索引.md`、`MANIFEST.json`；先核哈希，不能把GitHub文档骨架当可编译完整源码 |

### 本次交接的定位快照

2026-10-07核对主库基线 `2513c19c820644230d82ea002b8e4c8eb7cf78fa`、指标库 `c1a0021f2a6db562f9e791e620c08352a743e6ca`。这是交接前的版本身份；以后应以新main及CURRENT为准，不把这两个值固定成永久最新版本。

- 最新实际研究仍为2026-10-04 I11：9场新MT5测试＋19条复用，3组新候选编译；历史任务为Codex-only，不能改称Claude已参与复审。
- 当前路线为C# LEAN离线研究＋MQL5独立执行。七个C#信号层编译不等于完整迁移；LEAN运行受Windows应用控制0x800711C7阻挡，完整风险／成交／退出和双端验收未完成。
- 用户Scalping保留M5、最近有效供需区回踩及方向反转闭柱核心，允许优化进出场细节；服务器日累计6盈OR6亏只锁该策略新增风险，保护已有仓位继续。固定表手数与风险比例是V1.2分别登记的研究候选；不把旧全局说明误当此项目新增权限的否定。
- 35/25/20/10/10评分权重有效；正式锚点未登记，仍N/A／SCORE_TARGETS_UNSET。PF1.3–1.8、DD≤15%、200–500笔、Recovery>3、净期望／成本3–5倍为计划8.1参考，不自动给满分。
- I11的S2推进2%＋1R保本是研究主候选：六月14.84、八月19.40 USD，但仅1／2笔。Scalping六月仍亏损。六月和八月都是已用开发数据；无独立OOS、组合连续账户、提款路径、Demo、Champion或实盘验证。
- I11交付ZIP SHA256：`aaaae4071d2837eb94b6db1aeeb2f04f8cd2378995e1f053bf6f5788c264e37b`；本次重新核对匹配。源码／EX5和原始报告维持本地范围，没有因知识同步公开上传。

本机可复用位置（跨电脑须重新定位，不存在就报告缺口）：

- 主仓库：`C:\Users\A\Documents\Codex\2026-09-10\new-chat\work\plan-replacement\repository`
- 指标库：`C:\Users\A\Documents\Codex\2026-09-08\created-by-user-chrismoody-updated-4\work\github-indicators-payload`
- EA工作区：`C:\Users\A\Documents\Codex\2026-09-10\v1-2-ea-mt5`
- 当前完整交付：上述工作区`outputs\TradingBrain_I11_Seven_Strategies_20261004`及同名ZIP。

Claude Code机制依据：[官方记忆说明](https://code.claude.com/docs/en/memory)。本节是项目同步约定，实际是否读取须以会话回执为证，不能单凭自动加载配置声称全部知识已学会。

### 实际读取回执核对（2026-10-08）

已在Claude Code本地会话“交易头脑EA知识同步”收到两批读取回执，所读主库提交为 `b4a91277aed898aaa805b79918b7d906ae4d4273`，指标库为 `c1a0021f2a6db562f9e791e620c08352a743e6ca`。第二批答复已结束；本次传递及读取核心知识完成，没有常驻同步服务。后续按上述流程增量读取共用文件，不重复把全部历史材料塞进每个会话。

Claude Code回报已读共用规则、完整项目计划／CURRENT／EVIDENCE_INDEX、I6–I11主要中文结论与失败身份、通用知识大脑、AI Alpha／LEAN等已保存学习说明、评估工具README，以及指标库主要buffer／规则说明；读了S2候选的主要入场／风险／管理逻辑和Scalping部分区域／反转／日对账源码，盘点当前交付清单并复算ZIP哈希。Codex已观察这些回执、核对其当前迭代／结果／权限理解，并独立核对知识入口、ZIP及指标库26个源码／EX5哈希；没有独立重放Claude的每个读取动作。

仍未逐份复审S1／S3／S4／S5／S6选定源码、DD15 MQH、指标源码及全部原始结果JSON／成交；大型历史库和分支保留索引按后续任务读取。指标manifest全文读取范围在回执中有前后不一致，因此不宣称13项全部字段均已读。`/context`加载列表未验证；实际文件读取与自动加载分别记录。知识交接不是源码独立复审、编译或回测，本次没有新EA测试、Champion晋级或部署。

回执解释校正：第一批“去掉回测”已在第二批纠正为“去掉回踩”；第二批经验段把S2保本结果写为I10，实际属于I11，依据本项目I11报告。指标库SND通用接口文档的“30 pt待确认”，不能覆盖V1.2计划4.1已确认手册单位。回执里的源码风险数值只描述所读版本，不是给所有策略新增统一默认值或上限。

原始UI文字回执保存在本机 `C:\Users\A\Documents\Codex\outputs\claude-code-knowledge-sync-20261007\claude-code-receipt-final-20261008.txt`；本仓仅保存范围摘要，后续变更以最新提交和CURRENT为准。

每次开始新的开发任务或接续研究前，先让用户选择：

1. **使用 Claude**：Codex 与 Claude 共同讨论和复审，Claude 写改代码，Codex 协调、编译、测试及整理证据。
2. **不用 Claude，只用 Codex**：Codex 负责分析、写改代码、编译、测试、复审和研究记录。

当前请求已明确选择时直接采用，不重复问；否则等待选择，不默认任何模式，也不启动该轮研发。已授权的文档维护和只读核对可以继续。选定后同一次任务内不在每个技术步骤重复询问；下一次新任务或用户另行发起接续时重新给选择。两种模式沿用相同的策略权限、风控、验证和恢复规则。

本次选择写入现有研究记录。只用 Codex 时无需 Claude 交接或复审，不声称 Claude 参与。使用 Claude 时不自行互换代码职责；Claude 不可用则继续可独立完成的分析、文档和验证，记录待交接事项，不静默切换模式。用户可以明确改选。使用 Claude 时的完整分工以根目录 AGENTS.md 为准。切换模式不切换交易引擎、验收标准或当前有证据的版本。

2026-10-03 补充核实：已通过 Claude 桌面版完成消息收发和协作流程讨论；随后已告知主仓库与指标库，Claude 界面显示 Added 2 memories 并列出 gsm-ea-gold-trading.md 与 preferences.md，回复确认保存了仓库用途、链接及分工；尚未实际读取仓库。Claude Code CLI 与后台自动协作仍未验证。未购买 API、启动后台服务或开展新 EA 研发。

## 共用规则和分工

仓库根目录的 [AGENTS.md](../../../AGENTS.md) 是共用规则；[CLAUDE.md](../../../CLAUDE.md) 只用 `@AGENTS.md` 导入。Claude Code 的导入方式见 [官方文档](https://code.claude.com/docs/en/memory)；启动后用 `/context` 核对实际加载情况，不能只凭文件存在就说已连接成功。

以下分工表及双方交接流程仅在本次选择使用 Claude 时适用；只用 Codex 时由 Codex 完成相应工作并记录实际复审范围。

| 环节 | 使用 Claude 时的负责人 | 交接与核验 |
| --- | --- | --- |
| 方案 | Codex 与 Claude | 共同讨论和完善，重要方案先独立分析再交叉检查 |
| 代码 | Claude | 编写、修改、自查，列明未验证假设和影响范围 |
| 复审 | Codex 与 Claude | 双方检查方案、需求、接口、受影响完整逻辑和原始证据 |
| 编译／测试 | Codex | 在已有环境与授权内执行，保留版本、哈希、原始日志与报告，双方核对结果 |
| 修正与复验 | Claude 修正；双方复审；Codex 验证 | 每次修改重做受影响验证，不把意见一致当作测试通过 |

同一文件同一时间只交给一位实现者。并行候选用独立分支或 worktree；合并前核对基线提交与冲突。两位 AI 意见一致不等于策略已通过验证；不同意见按证据解决，不用投票或高置信度替代回测。

当前架构为C# LEAN离线研究＋MQL5独立执行。所选代码责任人负责两端实现；Codex组织C#／MQL5编译、LEAN／MT5运行和跨引擎核对。具体按主计划第2.1节执行，不把单一平台通过记成两端通过。

## 每次交接只带一份记录

以 [candidate.template.json](../research/candidate.template.json) 为起点，每个实际候选独立保存。至少交接：任务目标、策略归属、允许改变与必须固定的项、父版本提交、候选和运行编号、两端源码/DLL/EX5/参数及运行时哈希、共同规范、分平台run_id、配对差异、已运行测试及失败原因、待解决问题和下一步。

本次已选择使用 Claude 并获授权交接时，可使用以下任务文字：

> 请先读取相对仓库根目录的 AGENTS.md、docs/GSM_EA_RESEARCH_BRAIN_CN.md、research-memory/README_CN.md 和 research-memory/STATE_CN.md；再以 开发交易头脑EA/交易头脑v1.2/ 为项目根目录，读取其 README.md、docs/PLAN_CN.md、research/CURRENT.json 和本轮候选记录。按用户指定分工共同讨论方案，C#研究端和MQL5执行端代码由 Claude 写改，双方复审，Codex 分平台编译／测试及差异核对并提供原始证据。先核对源码与证据哈希，检查工作树是否有他人修改；只推进已授权任务。保护用户 Scalping SOP，保持 MQL5 独立交易和风控，不把历史报告当本轮新成绩。结束时更新同一候选记录，写清完成项、未完成项及恢复点。

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

S5请求终态修复及S2下一根独立M5确认规格已保存在工作区；[S5待实现交接](../research/evidence/MT5_ITERATION7_S5_HANDOFF_20261003_CN.md)列明需要交付的源码与证据。尚未作为实际代码任务提交，未实现、未编译或复测。这是当轮留下的待办；后续开始前按用户本次选择确定实现者与复审方式，再运行新版本配对验证，旧失败保持无效。CLI、API和后台自动协作仍未验证，本轮没有新增持久记忆操作。
