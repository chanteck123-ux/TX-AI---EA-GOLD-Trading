# 三项知识审核：已完成部分 / Completed audit records

2026-11-03。仅保存已完成批次；三项整体及Claude独立全文审核仍未完成。静态阅读不是运行测试、EA实现、回测或盈利证明。

本目录 COMPLETED_EVIDENCE.json 保存13份报告/覆盖记录的原文与文件哈希。下文汇集报告，便于Claude Code与Codex直接读取；调用链待核验项保持待核验。

## 当前知识重点

- LEAN：有效配置、环境覆盖、启动/退出/算法完成需要分开核验；默认参数不是项目最佳值。
- Kronos：模型时间语义、训练/验证隔离、网页展示与评估对齐要分别检查。尚未执行模型测试。
- QuantSkills：A127、A094纠正记录独立保存，保留原审核历史。
- 剩余：LEAN其余源码与二进制内容、QuantSkills未读批次、Kronos示例与CSV证据补核及其他未读内容；Claude回执未确认。不能把文件盘点数量当全文完成数。

---

## lean-full-review-20261101/codex/inventory/REVIEW_CN.md

# LEAN Codex 独立清点及根文本全文审核

本次分工完成：清点6,522文件，全文读取根目录22份文本共2,603行。全仓全文审核尚未完成；5,792份文本、708份二进制未审核。未核对Claude完成度，不能宣称双方完成。QuantSkills与Kronos及其Claude报告不在本次实际阅读范围。

原件：C:/Users/A/Desktop/TX/QuantConnect/Lean-master QuantConnect的精简算法交易引擎（Python、C#）。本地快照共288,178,063字节，5,814文本、708二进制；文本共1,305,678行。这里只确认指定本地目录，不宣称它等于网上最新master，未验证上游commit。

manifest.json/manifest.csv含全部路径、字节、SHA256、分类、编码及行数。严格Unicode解码与控制字符检查作机械分类，解码失败归二进制，并不证明文件内容不可解读；二进制行数为null。CRLF/LF/CR均算换行，末尾换行不额外增加空行。隐藏文件也纳入，压缩包未解包、二进制未反编译，外链图片未查看。哈希和行数扫描不是全文阅读。

## 根文本阅读记录

| 文件 | 已读行范围 |
|---|---|
| .dockerignore | 1–6 |
| .editorconfig | 1–13 |
| .gitattributes | 1–66 |
| .gitignore | 1–283 |
| .travis.yml | 1–23 |
| ci_build_stubs.sh | 1–119 |
| compare_benchmarks.py | 1–36 |
| CONTRIBUTING.md | 1–151 |
| Dockerfile | 1–27 |
| DockerfileJupyter | 1–59 |
| DockerfileLeanFoundation | 1–419 |
| DockerfileLeanFoundationARM | 1–277 |
| find_datasource_repos.py | 1–245 |
| google9161359af9633398.html | 1–1 |
| LICENSE | 1–191 |
| mypy.ini | 1–7 |
| QuantConnect.Lean.sln | 1–162 |
| QuantConnect.Lean.sln.DotSettings | 1–42 |
| readme.md | 1–223 |
| rebase_organization_branches.sh | 1–26 |
| run_benchmarks.py | 1–68 |
| run_syntax_check.py | 1–159 |

## 发现（静态证据，未运行复现）

- F01 — readme.md:22–42：文档将LEAN描述为事件驱动及可插拔；这里只确认文档陈述，核心实现未读。
- F02 — .travis.yml:3–19：旧CI写dotnet 5/Python 3.6，与根README 144、162及Foundation 413–419的.NET 10不同；不可混用为同一已验证环境。
- F03 — DockerfileLeanFoundation:412–419：安装dotnet-sdk-10.0并标net10.0；仅静态配置证据，未安装或编译。
- F04 — DockerfileLeanFoundationARM:265–277：注释仍写dotnet 9，但实际安装通道10.0、标签net10.0，存在注释漂移。
- F05 — DockerfileJupyter:43–54：生成的启动命令绑定0.0.0.0并设空token、allow-root，且递归777；部署前须审查访问隔离。本次未执行。
- F06 — compare_benchmarks.py:13–28：比较average-dps并容许10%下降，是吞吐性能门槛，不是净利/PF/风险验收。
- F07 — run_benchmarks.py:41–61：子进程未检查返回码，静默输出后直接解析日志取均值；失败、旧日志或无匹配样本须另外处理，尚未复现。
- F08 — run_syntax_check.py:119–139：返回成功按过滤后文本判断，未检查mypy返回码；不以临时路径开头的错误可被过滤，存在误报成功的静态风险，未运行验证。
- F09 — run_syntax_check.py:151–159：总成功率99.1%即可退出0，不能解释为全部脚本通过；零匹配目标还存在除零路径。
- F10 — find_datasource_repos.py:125–129：递归Git树响应未检查truncated，返回文件清单可能不完整；待后续验证。
- F11 — find_datasource_repos.py:173–191：按类型同名文件匹配且跳过带点类型；不是所有类定义的完整源码验证。
- F12 — find_datasource_repos.py:217–241：多仓库候选按最近push选择；仍未匹配只记录日志且返回0，不能当数据源覆盖完整证据。
- F13 — ci_build_stubs.sh:43–70：生成器master/runtime main执行pull并运行生成器，未固定提交；后续复现需独立锁定依赖。
- F14 — rebase_organization_branches.sh:7–25：包含git clean、rebase、force-with-lease推送，是有副作用的维护脚本，本次只读。
- F15 — CONTRIBUTING.md:21–29：要求单元测试、Framework职责分离；并非本目录已通过测试的证明。
- F16 — QuantConnect.Lean.sln:6–58：解决方案列出Launcher/Engine/Common/Algorithm/Framework/Tests等项目，作为模块阅读入口，未深入csproj及实现。
- F17 — mypy.ini:3–7：禁用部分错误并跳过若干依赖导入，与syntax_check过滤共同限定类型检查覆盖。
- F18 — DockerfileLeanFoundation:388–392：此处chronos-forecasting是依赖名称；不能据此宣称已集成用户提供的Kronos仓库。

其余根文件已读：忽略/格式配置用于仓库维护；LICENSE是仓库授权文本；Google HTML仅站点验证；DotSettings为编辑器检查及格式设置；Dockerfile复制预编译产物后启动Launcher。这些文件均不证明策略、风控或运行状态。

## 模块分批计划及未读范围

batch_plan.json共200个待读批次，按模块及路径排序；每批最多12,000行/40片段，每片段最多2,000行，超长文件连续拆分，覆盖全部未读文本。批次仅计划，不计已读。下一批先读环境/构建配置，再配置与启动、Common/Engine/Algorithm、Framework/执行、指标/研究/报告、示例与Tests、Data及Documentation。实际阅读须按输出容量进一步拆小，截断必须补读。

| 模块 | 文本未读 | 二进制未审核 | 文本行数 | 计划批数 |
|---|---:|---:|---:|---:|
| .devcontainer | 2 | 0 | 52 | 1 |
| .github | 14 | 0 | 616 | 1 |
| .nuget | 1 | 0 | 10 | 1 |
| .vs | 1 | 0 | 73 | 1 |
| .vscode | 6 | 0 | 374 | 1 |
| LocalPackages | 1 | 0 | 15 | 1 |
| Configuration | 9 | 0 | 1042 | 1 |
| Launcher | 4 | 0 | 1115 | 1 |
| Common | 2052 | 0 | 301870 | 52 |
| Engine | 233 | 0 | 39681 | 6 |
| Algorithm | 59 | 0 | 21599 | 2 |
| AlgorithmFactory | 5 | 0 | 2004 | 1 |
| Algorithm.Framework | 86 | 0 | 11236 | 3 |
| Brokerages | 37 | 0 | 6162 | 1 |
| Indicators | 233 | 0 | 31497 | 6 |
| Research | 14 | 0 | 2590 | 1 |
| Optimizer | 18 | 0 | 2172 | 1 |
| Optimizer.Launcher | 5 | 0 | 423 | 1 |
| Report | 54 | 0 | 7380 | 2 |
| Api | 5 | 0 | 2177 | 1 |
| Queues | 3 | 0 | 367 | 1 |
| Messaging | 5 | 0 | 614 | 1 |
| Logging | 15 | 0 | 1360 | 1 |
| Compression | 4 | 0 | 1258 | 1 |
| DownloaderDataProvider | 9 | 0 | 840 | 1 |
| ToolBox | 57 | 0 | 7280 | 2 |
| Algorithm.CSharp | 899 | 1 | 134585 | 23 |
| Algorithm.Python | 477 | 0 | 35151 | 12 |
| Tests | 1029 | 7 | 380389 | 38 |
| Data | 454 | 691 | 309116 | 34 |
| Documentation | 1 | 8 | 27 | 1 |

另有根目录lean.ico未审核。unread.csv逐项列出所有6,500份未审核文件；coverage.json对每份文件记录实际状态、SHA256、行数、已读范围及发现行号。后续重点核对数据可用时点/时区/填充、订单及部分成交、费用滑点/保证金、风险与持仓维护、统计口径及测试覆盖；这些目前都是待审问题，不能预写实现结论。

每批双方各自读原文、独立保存范围与发现，再按同路径同哈希同范围对照；有变更重新审受影响范围。整份文件覆盖所有行才可标FULL_READ；全模块完成仍不等于编译、回测或交易验证。二进制保持单列，未来内容检查另行登记方法，不以哈希代替阅读。

旧coverage已保存coverage.previous.json；当前逐文件哈希与旧coverage比较差异0项（previous_comparison.json）。旧manifest在发现旧输出后重新生成，未单独留旧副本；本次阅读重新完成，没有继承旧已读声明。所有写入限本inventory目录；未改原件、Claude目录、EA或正式接口，未安装/运行第三方代码、训练、编译或回测。


---

## lean-full-review-20261101/codex/batch-L0001-L0006/REVIEW_CN.md

# LEAN L0001–L0006 全文静态审核
2026-11-02，Codex主审。25份文本、1140行全文读完；覆盖含.devcontainer/.github/.nuget/.vs/.vscode/LocalPackages。逐文件SHA256已与冻结批次核对。未运行工作流/安装/编译/测试/回测。不是Claude独立审核。

## 发现
1. .vs/readme.md本地安装仍写.NET9/Python3.11.11，.vscode/readme.md写.NET10/Python3.11.14。实际环境须以对应构建配置及验证为准。
2. .devcontainer/Dockerfile:2使用research:latest，stubs不锁版本；工作流多用foundation浮动标签。源码SHA不能固定依赖环境。
3. .devcontainer/devcontainer.json启用host网络；.vscode/launch_research.sh:15空token启动Jupyter并allow-root。仅静态记录，不部署、不声称网络已暴露。
4. gh-actions.yml主测试排除TravisExclude和ResearchRegressionTests，后者在独立workflow。API tests限push及特定类；单个CI成功不等于全部测试成功。
5. regression-tests.yml为4个shard复制输出目录、pipefail并汇总退出码，可借鉴输出隔离和传播失败；测试内部shard分配未读，不证明无重叠遗漏。
6. virtual-environments.yml三个后台函数依次调用多个dotnet test，内部未显式set -e或逐项累计退出码。需确认shell实际errexit在异步函数中的行为，才能判断中间失败是否被最后成功掩盖；此项待验证，不直接判必定误通过。
7. benchmarks.yml允许首次比较失败并同机重测，只在重复退化时失败；master参考artifact可能来自不同提交/机器。这是吞吐性能政策，不可照搬成EA反复测试挑通过。
8. .vscode/tasks.json的test带--no-build且无dependsOn build，单独执行可能测既有产物；launch.json的Run Tests有preLaunchTask build，两入口不同。
9. LocalPackages用于未发布依赖试用，文档要求核对restore源。本批未执行nuget。
10. PR/issue模板、资助和workflow均为上游资料；不当作本项目验收证据，不执行维护发布操作。

## 证据
逐文件两批全文输出均未截断，coverage.json记录路径/哈希/行段。初始inventory的PLANNED_UNREAD保持原快照含义，后续汇总按路径与哈希连接本批，不将计划自动改完成。


---

## lean-full-review-20261101/codex/batch-L0007/REVIEW_CN.md

# LEAN Configuration 全文静态审核 — L0007

审核日期：2026-11-03。Codex 独立审核，9份文件、1,042行，逐文件 SHA256 与固定批次清单一致。全文范围见 coverage.json。没有执行、编译或运行测试，不代表 EA 接口已实现。Claude 的独立审核状态另计。

## 配置来源与可复现性

1. Config.SetConfigurationFile 遇到不存在的文件会记录错误并保留原配置路径，不能仅凭调用发生就确认已切换配置。ConfigFactory 缺省配置包含 BasicTemplateAlgorithm、live-mode=false 和回测处理器；这不是“缺文件就自动实盘”。研究编排应核验最终生效路径与配置快照。
2. Reset 重新创建 Lazy 设置对象，但不重置 ConfigurationFileName；不能把它解释成完整恢复所有默认状态。
3. GetToken 的环境层级值可覆盖根层设置；命令行合并写入根层不意味着对选定环境拥有最高优先级。数组合并使用 Union，而非直接替换。实验记录应保存最终有效值，不能只保存命令行。
4. GetEnvironment 在选定子环境后立即读取其 environment 字段；不存在的环境可能触发空引用。Set 的环境路径分支创建 environments，却未保证指定子环境已存在。以上是源码路径风险，未做运行复现。

## 类型与输入语义

5. GetValue 的枚举及 IConvertible 转换不在后面的异常回退保护内；其他解析失败可能回退默认值。TryGetValue 调用 GetValue，因此返回 true 不足以证明键存在且显式输入已通过验证。
6. Flatten 将选定环境的值以 ToString 方式加入克隆，数值、布尔、数组等原始 JToken 类型可能变成字符串；是否影响具体消费者仍需调用链验证。
7. ApplicationParser 的 MultipleValue 解析以逗号、冒号分割，取 subKeys[1]，含额外冒号的值可能丢失后半部分；重复键覆盖前值。多次提供同一选项的行为还取决于 McMaster 库，未据此断言全部丢失。
8. PrintMessageAndExit 在退出前读取输入；无人值守流程需要验证 stdin 条件下是否等待。不能仅凭启动命令完成就判断任务完成。

## 研究意义与边界

force-exchange-always-open 是无值开关，出现即设置 true；这会表达改变交易时段的意图，但解析注册不证明下游实际如何执行。解析器本身不是财务风险验收模块，下游是否验证尚需继续阅读。

项目目标框架为 net10.0，依赖 McMaster.Extensions.CommandLineUtils 2.6.0 与 Newtonsoft.Json 13.0.2；应和启动环境核对。未安装依赖，也未运行外部代码。

本批可吸收的知识：研究运行必须记录配置来源、环境层级、有效配置及哈希；显式区分缺键、无效值与默认回退。不能直接把 LEAN 配置代码移植为已验证的 MT5 接口。

## 覆盖说明

Config.cs、ApplicationParser.cs、CommandLineOption.cs、LeanArgumentParser.cs、OptimizerArgumentParser.cs、ReportArgumentParser.cs、ToolboxArgumentParser.cs、Properties/AssemblyInfo.cs、QuantConnect.Configuration.csproj 已全文读取。首次组合输出中间被截断的三个参数解析器已分别完整重读。覆盖表仅记录本批；不改原始批次计划，不修改 Claude 目录。


---

## lean-full-review-20261101/codex/batch-L0008/REVIEW_CN.md

# LEAN Launcher 全文静态审核 — L0008

2026-11-03，Codex。4份文件、1,115行全文读取，全部 SHA256 与固定清单一致。没有编译、启动、连接券商或运行测试；Claude 独立覆盖另计。

## 启动与完成证据

Program.Main 在存在参数时调用 LeanArgumentParser 和配置合并，再初始化系统处理器、取任务、初始化算法处理器。取不到任务时退出码为1。代码注释提到任务版本，但当前此处分支条件只检查 job.Redelivered；不能据此声称已核验版本一致。

任务重新投递时发送 RuntimeError、确认队列任务，再调用 Exit；Exit 对非空任务再次 AcknowledgeJob。是否重复确认无害依赖队列实现，需继续追踪，当前不判定已造成数据丢失。

引擎运行外层 finally 根据 algorithmManager.State 是否 Completed 决定0或1。启动成功、进程结束、算法完成与盈利验证必须分别记录。初始化中的一些步骤发生在该 try/finally 之前，因此不能声称所有启动失败都经过相同退出清理。

CancelKeyPress 注册早于 algorithmManager 赋值；处理函数直接调用 algorithmManager.SetStatus，存在很短的空引用窗口，未动态复现。Exit 的 Python 关闭有10秒限制及异常记录；这不证明全部退出步骤都受同一超时保护。

## 配置边界

config.json 默认选择 backtesting，CSharp BasicTemplateFrameworkAlgorithm。live-paper 虽 live-mode=true，仍明确使用 PaperBrokerage 与 BacktestingTransactionHandler；其他券商环境指定 BrokerageTransactionHandler。不能只看 live-mode 一个字段判断是否真实成交。

多种券商地址、认证字段及数据处理器配置仅是模板，不证明连接可用。EMA10/20在文件中明确是参数示例，不得变成黄金EA最佳参数。force-exchange-always-open 默认false、missing-data日志默认false；研究需要记录实际生效配置及数据覆盖，关闭日志不证明没有缺失。

历史提供器同时存在数组与字符串形式，是否兼容需检查消费者，当前不直接定为缺陷。行情源与交易券商可分开，意味着时间、品种与执行条件仍需核对。

## 构建与归档

Launcher 目标net10.0，依赖多个项目，配置复制策略PreserveNewest。应核对运行目录实际配置与源码配置哈希，不能仅以源码更改推断运行配置已更新。程序集元数据已读取。无新增正式接口或策略实现。

覆盖：config.json 1–869；Program.cs 1–157；Properties/AssemblyInfo.cs 1–17；QuantConnect.Lean.Launcher.csproj 1–72。逐文件证据见coverage.json。


---

## kronos-learning-20261101/codex/core-review/REVIEW_CN.md

# Kronos 核心全文静态审核 — Codex

审核日期：2026-11-02（Asia/Kuala_Lumpur）。身份：Codex 独立分工；不是 Claude 审核的代签。结论只适用于本地文件快照。

## 结论与证据边界

已全文阅读 `model/`、`finetune/`、`tests/` 的全部 16 个文件：15 个非空文本及 1 个空文件，合计 5,403 行，包含全部 CSV 数据行。逐文件路径、SHA256、行数、实际阅读范围、发现行号见同目录 `coverage.json`。首次大段输出发生截断，已补读 `module.py:380–570` 和 `kronos.py:1–330`；没有把截断或文件清点计成全文阅读。

最重要的三个结论：

1. s2 不仅存在训练／单步推理的位置编码不一致；**整段验证时交叉注意力关闭因果遮罩**，使较早预测位置可以读取后面真实 token 的表示，验证损失不能当作严格因果预测成绩。
2. 日期范围确有重叠，但必须结合实际损失位置判断。训练与验证 predictor 都对全序列下一 token 计算损失，不只对 10 条预测段计算，因此“重叠只是回看缓冲”不能消除污染；不能仅凭日期断言 90 条回看后的预测段仍在训练期。
3. worker 私有 RNG 复制会重复随机流；Claude 所说“主进程每轮设种子不影响 worker”不适用于这里默认的非持久 worker 时序。训练种子含 rank，验证种子不含 rank；验证还存在跨 rank 重复抽样。

全部属于静态代码推导，未做数值复现。没有安装依赖、导入或执行原仓库代码、下载权重、训练、编译、测试或回测；没有修改 Claude 目录、原件、EA 或正式接口。仅用 PowerShell 读取／哈希／写审核资料，并只读查阅两页 PyTorch API 文档。未核实 Claude 所称上游提交、92 文件与远端逐一一致、模型规模或论文事实。

## 阅读后的系统理解

`model/__init__.py` 提供三个类的名称映射；Tokenizer 用因果 Transformer 编解码器、球面二进制量化和两级码；Kronos 用分层 embedding、时间 embedding、因果主干预测 s1，再用 s1 embedding 查询主干 context 得到 s2。Tokenizer 的重建头是无约束线性输出。推理以窗口归一化数据编码、逐步采样、滚动 token 缓冲，最后解码保留的尾部并平均 sample 维。

`finetune/` 先把 Qlib 每股票数据按日期切成 pickle，随机抽 101 条窗口（90+10+1），用前 90 条归一化。Tokenizer 全窗重建；predictor 全窗错位一条监督。两个训练脚本使用 NCCL/CUDA DDP，按验证损失保存 best。`qlib_test.py` 对测试窗口顺序推理，产生四类归一化价格差信号，再交给 Qlib TopkDropoutStrategy。

`tests/` 是固定权重 revision 的 CPU 数值回归和固定抽样 MSE 回归，以及生成期望输出的脚本与 CSV。它们不是交易盈利、数据独立性或因果性测试。

## 发现（均未运行）

### K01 · 高：验证 s2 可读后续真实输入

证据：`model/module.py:371–394,452–462`；`model/kronos.py:239–275`；`finetune/train_predictor.py:134–174`。

验证先 `model.eval()`，随后把长度 100 的真实 token 输入整段 forward；交叉注意力用 `is_causal_flag=self.training`，于是 eval 时关闭遮罩。位置 i 的 s2 query 可以读 context j>i；context i+1 的输入本身包含位置 i 所要预测的下一条真实 s1/s2 token。主干因果并不能阻止这条 cross-attention 旁路。最后一个位置没有后续 context，较早位置则存在泄漏通路，整体 s1/s2 平均损失据此选 checkpoint。

这是 Claude 第 2 点之外需要单独列出的验证缺陷；不能把单步推理只读历史 context 的合法性套到整段验证。静态上能确定可见性错误，不能断言模型利用了多少或分数改善多少。后续修复研究应将因果策略与 train/eval 模式解耦，并分别验证整段因果损失及逐步生成损失。

### K02 · 高：单步 s2 的 Q/K 都使用零位置旋转，残差被广播

证据：`model/module.py:293–308,371–397,452–462`；`model/kronos.py:310–328,436–442`。

RoPE 缓存长度只取 q 长度，再把同一 cos/sin 应用到 q 和 k。训练 Q=K=L，旋转位置为 0…L−1。推理 sample_pre 为 [B,1]，Q=1、K=L，缓存只有位置 0（cos=1、sin=0），广播到全部 key，**该层全部 key 也没有位置旋转**。因此不只是“query 在 0、key 仍在 0…L−1”。

交叉注意力输出 [B,1,D] 又与 [B,L,D] hidden_states 相加，广播后输出 [B,L,D]，调用者只取最后一项。最后 context 残差仍在，不能说推理完全没有历史信息；但 cross-attention 的相对位置关系与训练最后 query 不一致。影响幅度待实验。研究修正需明确 Q 在 L−1、K 在 0…L−1 的逻辑位置，并保持残差取末项语义，不能只把 is_causal 改 True（非方阵的左上角因果遮罩也不是所需末位置语义）。

### K03 · 高：时间重叠与全窗监督共同污染验证边界

证据：`finetune/config.py:20–38`；`finetune/qlib_data_preprocess.py:97–110`；`finetune/dataset.py:44–70,98–117`；`finetune/train_predictor.py:99–109,143–148`；`finetune/train_tokenizer.py:136–144,173–207`。

train 至 2022-12-31；val 自 2022-09-01 至 2024-06-30；test 自 2024-04-01；backtest 自 2024-07-01。切分没有额外的 target-date mask。predictor 的 token_out=序列[1:]，所有 100 个位置均进入交叉熵，包含验证窗口早期落在训练期的监督位置；tokenizer 的验证重建也覆盖整窗。

需要修正 Claude 第 8 点的推导：这里 90 是记录条数，日频股票中四个月通常不足 90 个交易日；不能只看起止日期就说“10 条预测段肯定落在训练期”。真正可确认的是**全窗训练／验证目标包含重叠段**。另外，归一化虽只用前 90 条，对这些较早的 next-token 目标而言仍使用其后数据的统计量；对第 90 条之后的预测目标，前 90 条归一化则是已知上下文。两种评价必须分开。

测试窗口需要 90+10 条数据，signal timestamp 是第 90 条日期。以 2024-04-01 为原始测试起点，并不自动保证 2024-07-01 已有信号；按日频通常要更晚。没有实际 Qlib 数据，不能给出精确第一信号日、遗漏天数或受污染样本比例。后续应按股票逐个记录 context、target、decision、execution 日期，并将选模损失限定到预登记验证目标期。

### K04 · 高：worker 重复随机流，验证跨 rank 重复；每轮种子仍可生效

证据：`finetune/dataset.py:29–31,77–96`；`finetune/train_predictor.py:42–56,87–95`；`finetune/train_tokenizer.py:45–69,117–126`；`finetune/utils/training_utils.py:41–59`。

__getitem__ 忽略 sampler 提供的 idx，改用实例 random.Random 抽全池。DataLoader 没有为这个实例设置 worker_init_fn；复制数据集时同 rank 的 worker 得到同一私有 RNG 状态，相同调用序号会抽到同一窗口。设置全局 random/torch 种子不能替代实例 RNG 的分流。DistributedSampler 只切分被忽略的 idx，不能保证实际窗口互斥。

当前没有 persistent_workers=True，每轮在迭代 loader 之前先 set_epoch_seed，因此新建 worker 可以取得该轮的新状态。**撤回“本代码主进程重设 epoch 种子无效”的笼统说法。**训练用 epoch*10000+rank，各 rank 的随机流不必相同，但仍可能有放回重叠；验证所有 rank 都 set_epoch_seed(0)，所以各 rank 与 worker 进一步重复序列。样本数／多 GPU 数不能等同独立窗口数。默认生命周期依据 [PyTorch DataLoader 文档](https://docs.pytorch.org/docs/2.15/data.html)，未验证本机安装版本或运行。

后续可研究让 idx 真正索引预登记窗口，或显式按 rank/worker/epoch 分流；验证宜用固定、唯一且可追溯的窗口清单。

### K05 · 中：padding mask 语义与 SDPA 契约冲突

证据：`model/module.py:339–350,381–394,494–505`。

loss 以 padding_mask==0 为有效；attention 直接传原 mask。若是 bool，SDPA True 表示允许参与，与此约定反向；若是 float 0/1，则会作为偏置相加，并非屏蔽。自注意力又同时指定非空 attn_mask 与 is_causal=True，不符合 [PyTorch SDPA 文档契约](https://docs.pytorch.org/docs/2.15/generated/torch.nn.functional.scaled_dot_product_attention.html)。Claude 的问题方向成立，但“任何版本和后端必然抛错”不是本次已复现事实。当前已读训练／回归入口均未传 padding mask。

### K06 · 中：推理长度、模式和时间输入缺少完整约束

证据：`model/kronos.py:389–469,472–558,562–658`。

- 最终只 decode max_context 尾部，再取 −pred_len；pred_len>max_context 时无法返回要求的全部未来条数，构建 DataFrame 会与正常长度的 y_timestamp 不匹配。pred_len=0 时 −0 也是全切片，不是空预测。没有正整数及上限检查。
- KronosPredictor 构造仅 .to(device)，没有 .eval()。测试和 Qlib load_models 显式 eval，受保护；其他调用方若给训练态模型，no_grad 不会关闭 dropout 或改变 cross-attention 的 self.training。不能据此断言官方测试随机失效。
- 单条 predict 未校验 x/x_timestamp、y_timestamp/pred_len 长度；batch 版本有长度检查，但两者都未检查单调性、重复、历史与未来的先后、空窗口、Inf 或采样温度合法性。
- calc_time_stamps 依赖 .dt，公开 batch docstring 虽写支持 DatetimeIndex，直接传 DatetimeIndex 不符合该访问方式。函数不统一时区，而是提取输入的本地日历字段；不是自动把有时区输入变成 UTC。最后一个未来 timestamp 不进入逐步主干输入（它属于尚未作为输入的最后生成 token），不能声称每个目标的时间编码都被直接条件化。

这些是接口边界及研究解释风险，不等于所有正常默认调用失败。

### K07 · 中：采样参数 None 分支与组合筛选

证据：`model/kronos.py:331–384`。

top_k=None 且 top_p 非 None 时会比较 None>0；top_k=0 且 top_p=None 时会比较 None<1.0；两者都 None 则不进过滤分支。top_k>0 时 filtering 提前 return，top_p 不再应用。与 Claude 第 7 点一致并补充第二种 None 情况。高层默认 0/0.9 不触发。温度≤0 和非法 sample_count 也无前置校验。

### K08 · 中：量化器非默认分支有明确静态错误

证据：`model/module.py:90–128,204–222`；`model/kronos.py:126–139`。

- soft_entropy=False 分支没有给 avg_prob 赋值，返回 metrics 却引用它，存在未绑定局部变量错误；BSQuantizer 当前构造默认 soft_entropy=True，不因此判当前默认编码失败。
- get_group_codebook_entry/get_codebook_entry 的 bchw 分支用 `h,w=int(...)`，对单个整数解包会失败；当前核心 encode/decode 未使用这些 helper。
- half=True 的 indices_to_bits 给两半都用 codebook_dim//2，而 encode 按 s1_bits/s2_bits 分开。若两半不同宽，会丢位／填多位，奇数总宽还会导致维数不匹配。当前测试权重实际配置未下载检查，不能宣称默认发布权重必然命中。

### K09 · 中：默认 analytical 熵分支覆盖了 group 概率

证据：`model/module.py:39–46,131–155`。

先算 group codebook 概率 [B,T,G,2^group_size]，analytical 分支又把 prob 改成每 bit 的 [B,T,D,2]；随后 `reduce(prob,'... g d -> g d','mean')` 和 codebook_entropy 对后者操作。结果是边际 bit 熵汇总，并非先前计算的联合 group codebook 熵。单 bit 均衡不代表组合码使用丰富。这是代码与 group 熵意图的差异，需核对作者目标／训练权重后做消融；本次不声称已证明模型坍塌。cb_entropy_compute 虽接受 group/nce，在这段函数没有据此分支。

### K10 · 中：梯度累积配置的含义不一致

证据：`finetune/config.py:61–67`；`finetune/train_tokenizer.py:91–110,129–154`；`finetune/train_predictor.py:65–80,111–116`。

Tokenizer 把一批 batch_size 切为 accumulation_steps 份，并非累积多个原批次；有效总 batch 仍是 batch_size×world_size，而日志多乘 accumulation_steps。不能整除时尾部样本被丢掉，steps>batch_size 时切出空子批。predictor 每批 zero_grad/step，根本没用 accumulation_steps。默认值 1 不触发差异；tokenizer AdamW 也没使用 Config 的 adam_beta1/2，而 predictor 使用了它们。

### K11 · 中：验证聚合与保存的边界

证据：`finetune/train_predictor.py:150–174`；`finetune/train_tokenizer.py:184–207`；`finetune/utils/training_utils.py:83–102`。

Predictor 按批次均值平均，尾部小批与完整批同权；tokenizer 按样本数加权。两者验证计数为 0 时返回 0，若流程走到此处，会将“无验证”当最佳损失保存。reduce_tensor 若指定 AVG 又除 world_size，确实多除一次；当前两个训练脚本直接 SUM 后自行除，未调用该 helper，不能把它当现有全部日志数值已错的证据。

### K12 · 中：Qlib 信号、可用日期与绩效口径不能混为收益

证据：`finetune/qlib_data_preprocess.py:73–80`；`finetune/qlib_test.py:44–89,120–160,174–199,255–281`。

信号是已截断／归一化 close 的预测差，不是收益率；max/min 是先平均多路径后沿未来时间求极值，不是预测分布分位数。amt 是 OHLC 均价×vol 的近似，未用已读取 vwap；其单位必须与真实成交量定义匹配。dropna 后滑窗按记录数推进，停牌／缺失会改变窗口实际日历跨度。

test dataset 要求未来 10 条记录存在，哪怕不读取未来价格，也会排除尾部无未来记录的窗口，并可能利用事后可知的个股可用日期；需要区分公开交易日历与事后缺失／停牌形成的日期序列。当前没有源数据，不能量化偏差。

四种信号都被回测画图，只能确认多方案比较；**没有自动选出赢家的代码，不能仅凭此声称已经发生测试集择优**。若根据这些曲线选策略，才是使用了测试期。图中 return 用 cumsum，是算术累计，不是复利净值。账户设为 100,000,000，币种由 Qlib 市场数据环境决定，不能写成 USD 盈利。deal_price=open、delay_execution=True、成本参数可确认；真实信号延迟、撮合及费用语义仍须另审 Qlib 对应版本。

### K13 · 证据限制：回归测试与数据本身

证据：`tests/test_kronos_regression.py:15–34,45–88,90–140`；`tests/data/generate_regression_output.py:14–23,35–91`；三个 CSV 全文。

权重 revision 已固定；CPU、seed=123、top_k=1、sample_count=1。两种 context 长度各检验 8 条输出，MSE 各用固定抽样 4 个窗口、预测 30 条，四价原价平方误差平均。期望输出由同一实现生成，能锁住行为，也可能锁住缺陷。未覆盖 padding、因果前缀不变性、worker 唯一性、时间边界、不同宽码字或超长预测。固定 seed 不代表跨任意软件／设备绝对一致。

输入 CSV 有 2,500 条记录，范围 2024-06-18 11:15 到 2024-08-29 11:30，日内 5 分钟并包含午休／隔夜／周末间隔；没有 symbol、时区、数据商、复权或量单位元数据。读取全部行不等于验证其市场真实性。两个期望 CSV 各 8 条预测：256 对应 2024-06-25 14:05–14:40，512 对应 2024-07-03 09:55–10:30；不是实测交易结果。

### K14 · 研究解释与配置缺口

证据：`model/kronos.py:56–57,389–467,528–547`；`finetune/config.py:75–107`；`finetune/train_predictor.py:199–218`。

Claude 第 3–6 点中，窗口归一化／截断、随机采样、路径均值、缺少 OHLC 结构约束均有代码依据。但均值运算本身不会破坏所有合法路径共同满足的线性 OHLC 不等式；风险源是输出本来无约束，不能写成“平均必然使 K 线非法”。均值也不必然在每个实例中低估波动，只是不能代表完整预测分布。

微调 tokenizer 后接预训练 predictor 确有分布／码字语义迁移风险，但不必然失去预训练价值，应比较冻结 tokenizer 与共同适配。配置模型路径与 Comet key/workspace 为占位符，训练脚本顶层无条件 import comet_ml；不能直接视为可开箱复现配置，也不能未经运行断言具体 Comet 失败方式。核心文件没有预训练数据截止证明；未读论文，既不能证明泄漏，也不能认证 OOS。

## 与 Claude 报告逐项对照

| Claude 编号 | Codex 结论 |
|---|---|
| 1 padding | 基本支持；区分 bool/float 与依赖版本契约，见 K05。 |
| 2 s2 | 支持并修正 Q/K 都零旋转；新增验证非因果旁路，见 K01–K02。 |
| 3 平均路径 | 支持均值不能表示分布；不把非法 OHLC 或低估波动归为平均的必然结果，见 K14。 |
| 4 归一化／截断 | 支持；补充全窗早期目标的归一化时间问题，见 K03。 |
| 5 时间戳 | 支持显式日历构造需求；“无时区”改为没有统一时区转换，见 K06。 |
| 6 seed | 支持随机性；回归另有 eval、revision、CPU 限定，见 K13。 |
| 7 None/top_k | 支持并补充 top_k=0/top_p=None，见 K07。 |
| 8 时间重叠 | 支持损失污染，修正仅凭日期推断未来 10 条目标的逻辑，见 K03。 |
| 9 预训练截止 | 当前范围不能证明；保留未知，不推断已泄漏。 |
| 10 worker RNG | 支持重复流；修正 epoch 种子生命周期，补充分布式验证重复，见 K04。 |
| 11 tokenizer 语义 | 合理风险假设，非确定失效，见 K14。 |
| 12 Qlib | 支持信号／成本配置；四线比较不等于已经择优，执行语义仍未核实，见 K12。 |
| 13 helper/Comet | AVG helper 问题成立但未调用；Comet 只确认占位配置及依赖，见 K11/K14。 |
| 14–15 CSV 微调 | 本分工未读 finetune_csv/，不签认或否定。 |
| 16–17 examples | 本分工未读 examples/，不签认或否定。 |
| 18 webui | 本分工未读 webui/，不签认或否定。 |

## 未读范围与后续验证边界

指定三个目录内：无未读文本、无部分阅读文件；空文件没有虚构 1–0 行。仓库其他 76 文件仅清点，逐一列在 coverage.json 的 unread_files：根 README/LICENSE/requirements/.gitignore、examples/、figures/、finetune_csv/、webui/。Claude REVIEW_CN.md 已全文作为交叉核对资料阅读，不代表独立读过它引用的外围文件；Claude coverage/handoff 未读。QuantSkills 和 LEAN 不属于这次 Kronos 子任务，未计入完成。

未来若另获运行授权，应优先验证 K01 因果前缀不变性、K02 末位置 Q/K 对齐、K03 目标日期边界、K04 worker/rank 样本唯一性，再做其他参数边界实验。这里只登记静态修正方向，没有修改或运行这些方案，也没有提出黄金 EA 接入授权。Python 研究执行权限、MQL5 独立执行、Scalping SOP 及正式评分政策仍按用户规定处理；本次没有任何 EA 成绩或晋级结论。


---

## kronos-learning-20261101/codex/web-review/REVIEW_CN.md

# Kronos 根文档与Web UI独立全文静态审核
日期：2026-11-02（Asia/Kuala_Lumpur）。阅读者：Codex主审。
范围：coverage.json列出的10份文本，全文分段读取；原件未修改。上游归属沿用Claude来源记录67b630e，当前逐文件SHA256已保存，未在本批重新核对全部上游blob。未运行、安装、训练或回测。其余文件及图片不在本批完成范围。

## 主要发现
1. **历史窗口被标成最新未来预测**：webui/app.py:468–471无start_date分支使用df.iloc[:lookback]和其后历史时间；571–577却从整份df最后时间生成输出时间。图表240–250从输入末端生成另一个时间轴。若文件长度超过lookback，JSON与模型实际预测目标错位。默认前端会传start_date，因此这个问题主要是API缺省路径，不能说每次UI调用均触发。
2. **不规则时段被强行连续化**：app.py:240–250、270–284、557–566用文件头两条时间差生成日期；actual_df绘图也使用重建轴而非自身时间。遇午休、隔夜、节假日、缺Bar会错标。模型输入y_timestamp在450–458仍来自真实后续行，显示轴不能反过来当模型真正输入。
3. **删除缺失行后标签索引被当位置索引**：app.py:118 dropna不reset_index；543用df[mask].index[0]传给212以后iloc切片。若选择开始前曾删行，图表历史窗口可能向后偏移，尽管模型输入本身用过滤后iloc。需区别模型缺陷与可视化缺陷。
4. **前端滑块按日历时间而非Bar位置映射**：index.html:912–947用520/总行数定宽，965–967、1060–1073却线性映射整个日历跨度。非连续交易时段无法保证滑块展示的520根与实际选取相同。1003–1008先调start再调end，后者未夹上界；520至577行附近的短数据可使end超过100%。
5. **时区语义丢失**：index.html:1073把toISOString的UTC结果截断去掉Z，后端parse成无时区。原始时间若为无时区本地时间，浏览器时区非UTC可能选错窗口；有时区源还可能与naive start_dt比较失败。不能默认所有数据都会错，要核对原始时间语义与浏览器时区。
6. **误差统计按数组位置配对**：index.html:1134–1159不核对timestamp，只取较短长度；无样本返回0；MAPE除以原始act.close而非绝对值且不拦零。缺失/错位/部分覆盖会被掩盖。误差为价格单位，不是EA净利或通过线。
7. **无原始时间时伪造历史**：app.py:103从2024-01-01每小时填时间，没有明确模拟时间标记；load_data_file没有排序/去重/时区/交易时段/OHLC一致性检查，且dropna涵盖无关列。资料可导入不等于交易数据有效。
8. **缺少模型与输入的可复现标识**：app.py:645–646 from_pretrained无固定revision；保存结果125–206、601–608未含权重/tokenizer哈希、数据哈希、种子或运行库锁文件。秒级文件名132–134同秒可能覆盖。保存失败只打印，仍返回预测success（592–621）；预测成功与证据保存成功必须分开。
9. **演示服务不适合直接作为正式接口**：app.py:25开放CORS，346/409接收请求文件路径，没有限定到data目录；708与run.py:82使用debug=True、0.0.0.0；未看到认证、任务隔离与资源上限。风险取决于网络可达性，未运行漏洞验证，不声称已被利用。
10. **文档与实际回退不一致**：缺模型时日志/UI说会使用模拟预测（app.py:22/706，run.py:60，index.html:684附近），但/api/predict的实际else返回400，未见模拟生成。这是提示失实，不是证明此Web UI悄悄生成假预测。
11. **质量推荐未提供证据**：webui/README.md的T1.2–1.5、sample_count2–3仅作者建议，正文没有对照实验；同意Claude对应保留意见。根README明确finetune是示范而非生产系统，AI注释可错，应以代码为准。
12. **依赖/启动检查不完整**：根requirements重复声明pandas但有固定2.2.2约束；numpy/torch未全锁。webui requirements没完整包含根模型依赖；run.py检查前端库成功并不代表模型可导入。README示例data路径不证明仓库提供了对应数据。只作静态可复现性问题，不臆测具体安装报错。

## 项目吸收
保留预测起点、每根真实交易时间、当时可得窗口、固定模型和数据哈希；配对后报告覆盖数及未配对原因。界面选择历史窗口不是未见样本；MAE改善不等于扣成本后盈利。本批没有把任何模块接入EA，不修改Scalping SOP、风险上限、正式接口或评分锚点。

## 未完成
本批未审核prediction_results JSON内容、图片、examples；核心和CSV分工独立进行。Claude尚未对这些新增发现回原文确认，因此不是双方审核完成。


---

## quantskills-learning-20261022/codex/reconciliation-20261102/A127_A094_CN.md

# A127 / A094 覆盖争议纠正
日期2026-11-02；Codex主审，独立核查本地现存记录及原文件哈希，未运行外部代码。

## A127：接受Claude纠正
claude-full-review/assets/A127.md实际存在，本轮全文读取。记录P0131/P0132、FILE1334–1345共12份文本。coverage/coverage.csv有12条FULL_READ，均part1/parts1；本轮逐条与quantskills-learning-repos中实际文件SHA256核对，12/12一致。
因此full-review/batch_06/REVIEW_CN.md第163行“当前claude-full-review/assets未找到对应A127”不能继续作当前事实。我之前没有准确定位该笔记，现予纠正；无法凭本轮检查还原当时为何漏查。
当前正确表述：Claude有A127的12份文本全文记录；Codex batch_06也记录12份全文。两方覆盖存在，但不能由此推导全部脚本、测试或所有结论交叉复核完成。

独立回原文核对：scripts/fundamentals.py:29–37对缺失披露日放行；scripts/pandadata_source.py:167–177的filter_as_of同样保留空日期，且完全无日期列时直接返回未过滤数据。同意Claude的点时过滤缺口；缺时间记录是否真实含未来数据尚未运行验证，不能声称已发生实际污染。fetch_index_universe:199–214确实选择<=as_of的最近date快照，但这只确认代码选择条件，不证明上游快照的历史可得性或无追溯修订。
本轮源码读取范围fundamentals.py:1–75、pandadata_source.py:146–215，是部分静态阅读，不标全文。

## A094：接受Claude HASH_REUSE说明
plan_main.csv的seq1034：kind=HASH_REUSE, pack=REUSE, relative=agents/portable-loader.md，指向skill-backtest-etf/agents/portable-loader.md。
两个实际文件SHA256均为B26DB4D9573D48551437F52A912E6D3CA57B3FB9F189686321E571ED391153ED（182字节）。coverage.csv中源文件seq437在P0040.txt记FULL_READ，part1/parts1。
因此正确表述是7份直接全文阅读＋1份同哈希内容复用＝8份清单覆盖，不是8份分别逐字重读。原batch_06第127行指出笔记没列portable-loader是当时记录缺口，不能据此否定已登记的复用。Claude A094于2026-11-01已有覆盖补注，本轮全文读到。

## 保存边界
本纠正单独成文，保留旧报告作为历史记录；Claude原目录未修改。未增加新原文FULL_READ数量；这次是覆盖核实和部分源码交叉检查。全项目仍IN_PROGRESS，未满足双方全部全文完成条件。
