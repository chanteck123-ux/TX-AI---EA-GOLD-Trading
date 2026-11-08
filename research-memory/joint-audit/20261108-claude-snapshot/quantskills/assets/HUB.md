# QuantSkills hub 文本（组织主页、join、navigation、registry）— Claude 全文审核（2026-11-05）

## P0253–P0255（FILE 2161 .github/profile/README.md 分 3 部分；FILES 2162–2167：.github/README、join 下的 COMMUNITY_RULES、README.en、README，以及 quantskills/docs 下的中英文 README 模板）
- **核验方法**：正文和规则逐行阅读（FULL_READ）。组织主页中的 466 行表格属于目录清单，按 DATA_AUDITED 处理：中文和英文两节各列出 **218 个** `skill-`/`agent-` 仓库，两节集合完全相同（`comm` 比对差集为空），与本次审核的 A001–A218 资产数一致；所有 442 个链接都指向 `github.com/quantskills/`。
- **组织规则与本次资产的实际情况对照（规则要求 → 实际做法）**：
  - 规则第 4 条：未经审核不得宣称官方、认证或已验证。→ 至少 A196、A197、A217 的元数据写着 `maintainer_type: official`，多个资产写着 `status: stable` 或 `validation_level: runnable`，而实际只有文档。
  - 规则第 7 条：公开仓库中不得出现手机号、邮箱、密码或 API key。→ A140 的 SKILL.md 中有明文 PandaData 凭证（已登记，未转录）；A193、A207 等多个资产要求用"手机号 + 密码"作账号；A207 曾随包分发凭证；多个仓库写着维护者 handle。
  - 规则第 8 条：量化项目必须说明数据、假设、参数、限制和风险边界。→ 只要求**披露**，不要求**验证**。L3 Verified 才要求"无未来函数检查加回测证据"，主页表格中可见的状态标签极少。
- 治理：成员仓库默认为 Community Project；组织所有者保留重命名、归档、转移和删除的权力。加入申请是公开的，明确禁止填写隐私信息，这一条做得好。
- 模板中维护者写的是一个组织前缀的 GitHub handle（未转录）。组织主页为 QuantStudio、官网和社群二维码导流，这是推广内容，不是证据。

### hub 小结（第一部分）
- 规则写得清楚，但只停在"披露层"，没有任何强制的方法学检查。本批多个资产违反了规则第 4 条和第 7 条，规则在执行层面基本失效。这说明本组织的"Listed、Runnable、Verified"标签不能当作质量证据。

## P0256（FULL_READ：FILE 2168 quantskills/docs/superpowers/specs/2026-08-10 目录、接口契约与迁移设计）
- 性质：这是一份**已批准的设计稿，不代表已实施或已获发布授权**（文档自己声明）。以 2026-08-10 的盘点为基线：162 个公开仓库，其中 158 个 Skill/Agent 资产；registry 有 103 条，23 条未分类；只有 41 个资产显式声明了结构化输入。组织主页的目录后来增长到 218 个，说明这些计数只是当时的快照，文档也要求不得写死。
- **治理设计质量高，可作为 V1.2 规则的参照**：
  - 权威来源单向排列：schema → 各仓根声明 → 生成的 registry.json → README、Pages 等展示镜像，**展示层不得反向覆盖声明**；
  - 爬取结果或语言模型的推断只能作为迁移建议，不能直接成为声明；
  - **故障安全**：任一目标失败、被限流或解析失败时，不得用成功的子集覆盖上一份完整快照；先写临时目录，校验计数、hash 和 snapshot_id 后再原子替换；
  - 兼容性有五种状态：compatible、adapter-required、incompatible、unknown、not-applicable，**证据不足时一律标 unknown，不乐观地标为兼容**；
  - 跨仓写入无法做到原子性时，改为预检、幂等计划、逐项审计、遇错即停；**部分写入不得报告为完成**；
  - 严禁用自动化手段删除、转移或破坏仓库。
- Envelope v1 和 8 个基础 Profile 的设计合理：`fundamental-pit` 带 available_at，`macro-series` 带 vintage_date，`futures-contract` 带换月映射，`event-record` 带发布时间，并要求 adapter 做保真测试，覆盖复权、PIT 可见时间和期货换月。这些正好对应本批资产中反复出现的缺陷（A158 宏观数据不是 PIT，A160 和 A208 连续合约未调整）。可惜这些都还是设计，本批资产几乎都没有按它实现。
- 风险：第 4 波的"核心链路"以 `skill-ssquant-ai-trader`（A196）结尾，而 A196 存在仓位强制取 1 手、风控 fail-open、重启不对账等问题。设计只要求"冻结数据加不下真实订单"的端到端测试，没有要求复核执行端的风险逻辑。
- 示例中出现维护者 handle（未转录）。示例 sha256 被明确标为示例值。

## P0257–P0261 前段（FILE 2169 quantskills/README.en 分 2 部分；FILE 2170 README.md 分 2 部分；FILES 2171 和 2172 tests/golden 下的中英文 README）
- **核验方法**：正文 FULL_READ，目录表格 DATA_AUDITED。
  - 中英文导航页使用同一个 catalog-snapshot（`sha256:5ee87e02…`，2026-10-22），都列出 **218** 个资产。三份清单（中文导航、英文导航、组织主页）的仓库集合两两比对，差集均为空。
  - 各一级分类计数相加：7+44+45+22+26+30+13+10+15+6 = **218**；53 个二级分类计数之和也是 218，与总数吻合。
  - **"接口状态"一列中 217/218 为"待维护者审核 / 无公开端点"，只有 1 个是"已发布"**。输入和输出几乎全为"—"，整页只有一处 `market-bar`。可见 2026-08-10 设计里的 Envelope 和 Profile 契约迁移，到 10-22 快照时基本还没有落地。
- **golden 测试固化了乱码（已从原件核实）**：`quantskills/tests/golden/README.md` 中 16 行 fixture 的中文摘要是**字面的问号**（例如 `??01????1`）。在原件上用 `od -c` 检查，确认是 ASCII 字符 `?`，不是显示问题。也就是说，golden 测试把编码丢失后的中文当作"期望输出"固化下来：渲染器修好后测试反而会失败，现在的测试也无法发现编码问题。中英文 golden 文件的 fixture 集合相同。
- 导航页中维护者写的是组织前缀的 handle（未转录）。

## P0261 后段（FULL_READ：FILES 2173–2181，包括 registry 的 AGENTS.md，docs 下的 CATALOG_CONTRACT 中英文版、CORE_LINEAGE_SMOKE、MAINTAINER_GUIDE、SECURITY_SETUP_zh、SITE_INTEGRATION_zh、templates/disclaimer_zh_en，以及 evaluations/README）
- **registry AGENTS.md 的维护约束与本项目的门禁规则高度一致，可直接参照**：
  - 默认只读；写入前先验证签名 manifest、snapshot digest 和 schema，失败就停止；
  - 不手工编辑生成物；
  - **只有 CI 通过且用户明确要求时才合并**；
  - 不删除、不 force push、不改历史；
  - **不执行候选代码、不做真实交易、不访问候选资产的网络**；
  - 报告中必须写明未执行的高风险动作。
- SECURITY_SETUP 采用最小权限：扫描用的 token 只给 Metadata 和 Contents 两项读权限，写权限只限 registry 仓库本身，配有逐项负向验证清单（例如用只读 token push 应失败）；health_items 和人工复核报告不进入公开 registry。设计合理。
- audit 和 enforce 两种模式分开：audit 的输出只用于诊断，不得提交；只有通过 enforce 的快照才能发布；采集或校验失败时保留上一份完整产物。CORE_LINEAGE_SMOKE 明确说明合成 fixture **不代表**兼容性或生产就绪。
- **问题**：
  1. `templates/disclaimer_zh_en.md` 是"trader-research 仓库"的标准免责声明，带 `<TRADER_NAME>` 占位符。这说明**以真实交易员命名并复刻其方法的仓库是一个成批生产的系列**（与 A189、A217 相关）。免责声明能处理"非官方、无隶属"，处理不了对真实个人做画像所带来的隐私问题。
  2. evaluations/README 提到"当前评分投影包含 217 个资产"，并按"分类内前四分之一给出 recommendations"，另有一个模型批次（名称照录为 GPT-6 Sol / medium，是否属实无法核实）被排除在排名之外。评分依据的门禁和阈值不在本批文本中，无法复核。用模型给资产打分并排名，不等于方法学验证。
  3. MAINTAINER_GUIDE 的示例写的是 `GITHUB_TOKEN=xxx python …`，用环境变量前缀传 token，会留在命令历史里。
  4. SITE_INTEGRATION 把 `validation_level` 作为网站卡片的徽章展示，但这个字段由各仓库**自行声明**（见第一部分：多个资产自称 runnable 或 official，实际不符）。
- 维护者 handle 未转录。

## P0262–P0266（FILE 2182 registry/health.md：DATA_AUDITED；FILE 2183 INDEX.md 分 2 部分、FILE 2184 llms.txt 分 2 部分：DATA_AUDITED；FILES 2185–2188：maintenance/catalog-review-20261009、README.en、README、requirements-dev，均为 FULL_READ）
- **health.md**（生成于 2026-10-22T05:07:56Z）：218 个条目全部可达、有声明、声明合法。唯一的问题类型是"未声明 qsh-form（可选增强）"，共 127 条，另有 91 条"无问题"（已逐行统计）。
- **INDEX.md 与 llms.txt**：两份文件的条目正文**完全相同**（diff 为空），都是 218 个仓库，集合与导航页、组织主页一致。
  - INDEX 中有 1 个 agent 的简介**直接写出一位真实微博博主的昵称，并给他贴上"著名反向指标"的标签**，而且通过 llms.txt 分发给所有 LLM。这是对真实个人的公开贬损性定性，涉及隐私和名誉风险，本笔记**不转录**昵称。
  - 按仓库名统计，有 14 个资产以知名投资人或个人命名，或属于"research-model"人物画像系列（只计数，不列名）。
- **health 检查形同虚设（已按原文核实）**：registry README 列出 8 项"确定性健康检查"，其中 `secrets` 一项**只用正则匹配 AWS Key、GitHub PAT、`sk-` 形式的密钥和 Slack token**。因此：
  - A140 SKILL.md 中的明文 PandaData 账号密码（手机号加密码，不属于以上几种格式）**不会被检出**；
  - 方法学错误（PIT、复权、协整临界值等）、虚构的接口、数据外传、给真实个人画像，都不在检查范围内。
  "218/218 声明合法"只说明格式合规，**不能作为任何质量或安全证据**。
- **marketplace 分发风险**：README 给出 `/plugin marketplace add quantskills/registry`，可以把这 218 个资产作为 Claude Code 插件市场整体添加，其中包括本次审核发现的：明文收集并写入凭证（A196、A197）、借用登录会话做 CDP 抓取（A217）、把查询发往第三方服务器（A218）、要求隐藏 untrusted 标签（A218）、默认调用外部 LLM 网关（A210 中前后矛盾的说法）。**本项目不应添加此 marketplace**；如需用到其中某个资产，应单独审核到具体 commit。
- catalog-review-20261009：19 项提案中新增 4 项、更新 9 项、暂缓 6 项，目录从 214 增至 218。记录中写明"不采用其自声明的 verified 身份"，以及某资产"测试中的模拟凭据未按真实泄漏处理"，又对 `skill-signal-portfolio-optimize`（A191）沿用一条已批准的"仿真误判例外"。审核本身只读、不执行候选代码，这一点可取；但例外的具体依据不在本批文本中，无法复核。
- requirements-dev 用的是版本区间（如 `>=6.0,<7`），而 MAINTAINER_GUIDE 称之为"pinned test dependencies"，与实际不符。

## hub 结论
- registry 的治理工程（单一来源、只读最小权限、audit 与 enforce 分开、故障时保留上一份完整产物、合并须经用户明确同意）设计规范，可作为本项目 GitHub 治理的参照。
- 但它的"验证"只覆盖格式，"Listed、Runnable、Verified"标签和 218/218 健康分都**不能作为采用依据**。marketplace 一键安装把未经内容审核的资产整体分发给 Agent，风险很高。
- 涉及真实个人的命名和描述（"research-model"系列、"反向指标"简介）系统性存在，必须在 GAPS_CN 中登记。
