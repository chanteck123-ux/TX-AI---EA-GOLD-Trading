# GSM Gold Python Analyzer 1.0.0

> 公开源码说明：本分支仅含分析器代码、文档与明确合成示例。真实FxPro回测原件、SET、其分析输出及生成EA副本未上传；这些文件在提供给用户的完整交付包中。菜单2与6项真实附件测试需用户自行放入已授权资料，否则会提示缺项/跳过。其他功能可直接离线运行。

可运行的 MT5 黄金 EA 离线研发分析工具。读取本地报告、成交、日志和行情，生成中文 HTML 图表、CSV 与可追溯 JSON。无需付费 AI API、无需连接 MT5，也没有实盘下单接口。

本版交付的是分析器。**没有新策略回测成绩，没有通过 MT5 验证的候选，也不授予 Champion。** 原 EA、SET 和既有《EA交易报告重要注意》保持原样。

## Windows：先直接运行

1. 安装 Python 3.10 或以上，确保 `py -3` 或 `python` 可用。
2. 解压完整目录，双击 `START_WINDOWS.bat`。
3. 选择“合成演示”检查功能，或“FxPro 历史回测”分析包内真实旧版资料。成功后自动打开报告。

运行时只用 Python 标准库，不需要执行 `pip install`。`requirements.txt` 明确记录运行依赖；`pyproject.toml` 提供开发打包信息。以下命令在包含 `run.py` 的目录执行（仓库内为 `python_analyzer/`，ZIP内为解压后的项目根目录）。Linux/macOS 把 `py -3` 换成 `python3`：

```bat
py -3 run.py demo
py -3 run.py analyze --manifest examples\fxpro_v400\manifest.json --output output\fxpro_v400
py -3 run.py analyze --manifest input\manifest.json --output output\my_run --open-report
py -3 -m unittest discover -s tests -v
```

`RUN_ANALYZER.bat` 支持拖入自己的 manifest JSON；直接双击时读取 `input/manifest.json`。输入不存在时显示错误，不会偷偷改用示例数据。Windows BAT 已做静态检查；本次自动化测试实际运行于 Linux，未声称在 Windows 实机或 MetaEditor 中验证。

## 已读取的工程与资料

开发分支：`research/python/gsm-gold-analyzer-source-v1`，基于研究交付提交 `8326fbab6ee8beb2a0db77aa1f1663e08c4bff41`，源码版本属性 4.23。R-C01 仍是冻结工程基线；四组 Champion 记录均为 NONE。

| 引擎 | 已确认的工程边界 |
|---|---|
| Scalping | 独立 Magic；M5、区域、首次回踩、反转和 RSI/EMA。冻结 SL/TP 课程80/70，对应当前价格8/7；不添加保本、追踪或分批平仓。 |
| Intraday | 独立 Magic；当前有 M30 区域/方向路径。SET 的120/70不能被源码默认值覆盖；尾仓工程修复仍待重测。 |
| Swing | 独立 Magic；D1/H4、H4区域、现有M30确认以及原有保本/追踪。 |
| Combined | 同一次账户运行中的三引擎 OR 组合；不能把三份独立回测利润相加冒充组合成绩。 |

Intraday/Swing 的 M15 或 M5 进单是后续研究要求，不能表述为本次已实现。取消 Scalping EMA 的 S-C02 已有负面研究记录，分析器不会为了增单再次默认删除该过滤。

完整版本、SOP、SET、原生报告、代码行为和缺项见 [项目审计](docs/PROJECT_AUDIT_CN.md)。参考仓库已按固定提交审计，见 [参考实现问题复核](docs/REFERENCE_AUDIT_CN.md)：记录未来数据、追踪状态与指标口径问题，未复制其 MT4 桥接或收益结论，亦未发现可据以复制代码的许可证。

## 两套示例必须分开理解

| 目录 | 性质 | 用途 |
|---|---|---|
| `examples/synthetic` | 明确标记的合成行情、交易、日志、净值 | 验证导入、费用、图表、回撤和候选生成，不代表券商或 EA 收益。 |
| `examples/fxpro_v400` | 用户已有 V4.00 FxPro 历史 Combined 原件 | 复现旧报告与持仓审计口径，初始资金500USD、固定0.01手，与新2000USD风险标准化研究分开。 |

真实旧样本来自**同一次** `V400_C-C01_FULL_FxPro` 运行：

| 范围 | 完整持仓数 | 净利润 USD |
|---|---:|---:|
| Scalping | 20 | 64.39 |
| Intraday | 4 | 28.66 |
| Swing | 1 | 0.66 |
| Combined | 25 | 93.71 |

组合完整仓胜率80%，成本后完整仓 PF 约3.2537；原生报告 PF 3.21，两者分列保留。原生最大相对净值回撤9.48%、最大相对余额回撤1.72%。**没有权益时序，不能画出真实净值曲线。** 这只是旧回测原件的一致性核对，不是本次新候选的改善证据。

报告声明区间为2026-01-05至2026-08-26、真实报价质量100%；未取得原始 Tick，不能由此确认从2024-03开始的真实覆盖。原件名称含 `CHAMPION` 只用于追溯；当前统一标为历史待验证基准。源文件字节及SHA256记录在 `source_manifest.json`。

## 导入自己的资料

复制 `input/manifest.template.json` 为 `input/manifest.json`，填写真实运行信息与文件路径；没有取得的字段保留 `null` 或 `unknown`，不要填猜测值。一个 manifest 对应一次运行，文件路径相对 manifest 所在目录。

| 输入 kind | 首版支持 |
|---|---|
| `trades` | 标准完整持仓 CSV；现有 GSM `TRADE_REVIEW.csv` |
| `deals` | MT5 导出成交 CSV；`StudyEvidence.mqh` 的 `DEALS.csv` |
| `report` | 英文/中文 MT5 HTML 表格汇总与成交；`NATIVE_STATS.csv` |
| `events` / `funnel` | 标准事件 CSV；GSM `SIGNAL_AUDIT`、`SIGNAL_FUNNEL` |
| `log` | 专家日志中的结构化 `GSM_ANALYZER`、`STUDY_REQUEST` 记录及可识别已有审计记录 |
| `equity` | 带时间、明确账户/策略归属的余额/权益采样 CSV |
| `bars` / `ticks` | 标准 CSV、MT5 常见 `<DATE>/<TIME>` 行情导出；明确周期、时区、Bid/Ask |
| `evidence` | SET、INI、源码、依赖及EX5等的只读SHA256登记 |

所有映射、必填字段、费用符号和日志协议见 [数据格式](docs/DATA_SCHEMA_CN.md)。可用 `columns` 显式映射自定义列。Excel/XML/PDF报告、终端二进制Tick缓存、复杂INOUT反转和无法识别的自由文本不强行猜读，输出缺项或待适配记录。

建议在 `inputs` 中填每个源文件的 `sha256`。登记哈希不符的文件会隔离，其他独立输入继续分析。源文件不改写。缺少 PositionID 的原生 HTML 成交不会被按订单号猜成完整仓，需补 `DEALS.csv` 或已明确完整持仓的审计 CSV。分批平仓入出量未匹配的仓位不计作完整交易。

需提供服务器时区/实际UTC偏移；若存在夏令时，先按真实历史规则分段转换或导出带偏移时间。首版不猜 FxPro 服务器的 DST。`GOLD` 与 `XAUUSD` 的别名只有用户核实后才填；不得将期货 `GC=F` 或其他券商行情改名使用。

原始Tick多年的完整档案可能很大：第一版为标准库内存导入器，请按一次运行/冻结时间段导出需要的文件，保留原始档案。不要把大量无关数据混入最终样本文件。本版没有宣称完成大规模逐Tick策略重放。

## 报告与指标口径

每次输出 `report.html`、`analysis.json` 及10份 CSV：`metrics.csv`、`trade_analysis.csv`、`breakdowns.csv`、`signal_funnel.csv`、`findings.csv`、`candidates.csv`、`coverage.csv`、`data_issues.csv`、`provenance.csv`、`native_report_summary.csv`。HTML 的图表、样式与交互均内嵌，可离线打开；CSV 为UTF-8 BOM，文本做公式注入转义。HTML 表格有显示上限，完整记录保留在CSV/JSON。

- 按完整持仓成本后损益计算净利润、胜率、PF、均盈均亏、实际盈亏比、期望值和连续亏损；保本仓计入总仓数。无亏损时PF为未定义，不伪装成有限高PF。
- 多空、时段、持仓时长、行情代理状态分组；未知时区只显示记录时钟分段，不称伦敦/纽约时段。行情状态只使用进场前已收盘、已可用K线；ATR代理采用SMA(TR,14)，不等同于EA指标。
- 最大回撤金额与最大相对回撤分别遍历，可能出现在不同时间。余额、权益采样、原生摘要的来源分别列明；采样间的极端浮亏不可见。分策略贡献余额线也不是独立资金账户回测。
- 原生Recovery、净利润/余额DD金额、净利润/权益DD金额分列。终端观察与文档定义不一致时报告差异，不改写原生值。
- 净损益已包含费用时不再扣点差/滑点。佣金、swap、fee有证据才合计；缺数不填0。没有请求价格/成交价格、合约和币种转换依据时，不估造滑点金额。
- SL/ATR异常、ChaseEntry、ENTRY_TOO_LATE和MFE与净收益之差是待验证假设；不能仅凭这些标签证明入场位置导致亏损，或把MFE当作一定能够锁住的利润。

## 为什么不开单

报告保留已记录阶段、拒绝条件和次数，区分候选、过滤通过、请求接受、实际成交与完整平仓。累计漏斗使用每策略最新快照；EMA与RSI等计数可能重叠，不能相加成独立错失机会数，也不伪造漏斗转化率。

现有样本可看到 Scalping 1195次FirstTouches、205次HardSOPPassed、20次最终Gate/成交；Intraday 391次HardSOP、5次Confidence、4次成交；Swing 8次FirstTouches、5次HardSOP、1次成交。它们解释**记录到了什么**，不能证明未放行交易会盈利。

日志不足时，`tools/make_diagnostic_copy.py` 可为固定4.23源码生成独立诊断副本，两个观察开关默认关闭，记录过滤观察和账户采样。包内 `mql5/generated_v423/` 已包含实际生成的MQ5、六个依赖副本、观察头文件和哈希清单，状态为未编译、待验证。见 [诊断副本说明](docs/DIAGNOSTICS_CN.md)。它不覆盖原文件，不改变交易条件；生成后的MQ5仍须实际MetaEditor编译并做关闭/开启对照。尚未覆盖的早期return明确列为缺口，不以“没日志”解释“没拦截”。

## 三个候选与同条件验证

分析器依据当前输入最多提出三个单模块实验，并附具体发现ID。已有真实样本优先给出：

1. 风险计算与最小手数可执行性：核查初始SL、费用预算、向下步长和总风险预留，进出场保持冻结。
2. 进场定位或候选去重：先验证追价/晚进标签，在一个引擎中单独研究M15或M5触发；保持高周期SOP、风险和保护条件。
3. Intraday/Swing利润保护状态：验证成本保本、服务器确认、追踪状态与重启恢复；不触碰Scalping保护边界。

输入没有相应证据时，候选可能改为补日志/行情或少于三个；不会补造第三个收益结论。

```bat
py -3 run.py compare --baseline output\baseline\analysis.json --candidate output\candidate\analysis.json --output output\comparison
```

需要相同市场数据SHA256、券商/品种/时区、资金、风险、费用、合约、延迟/测试区间与分段；还需有效源码/SET哈希，以及 candidate 的 `experiment.changed_modules` 只有一个模块、指向基准源码/SET哈希。未知条件或不一致即 `NOT_COMPARABLE`。即使同条件，输出也只为 `CONDITIONS_MATCH_MT5_VERIFICATION_PENDING`，不是胜出或PASS。

开发、验证、最终段使用不重叠的 `[start,end)` 半开区间。跨边界仓位不拿来凑某段完整仓数。最终段默认锁定，冻结候选后才允许 `--allow-final`；要求未阅声明、冻结时间、源码/SET/市场指纹、预登记最终窗口，并在输入读取前保留曝光记录。同一窗口不得反复换参数评估；查看已有输出即可。

曝光账本是流程审计辅助，不是访问控制系统。**输入文件须事先按时间拆开，不能靠改manifest把已阅历史重新命名为未见OOS。** 实际读取后还会核查时间范围，无法撤销已经发生的文件读取。完整仓统计按整次运行展示，CSV另附分段；需要某段独立指标时使用对应冻结运行及独立manifest，不把开发/验证交易填进OOS样本。

## 下一次MT5真实回测

本环境没有 Windows MT5/MetaEditor，因此没有编译EX5、执行候选或伪造原生日志。已交付 `tools/make_mt5_test_configs.py`：基于用户实际提供的基准/候选SET与真实EX5，生成同条件INI、原参数副本和SHA256记录，**只生成配置**。详细可执行命令见 [MT5复测步骤](docs/MT5_TESTING_CN.md)。没有EX5时先实际编译，工具拒绝用占位文件顶替缺项。

按项目门槛分别补齐Scalping、Intraday、Swing、Combined控制；关闭新增模块应复现控制组。使用FxPro真实Tick，固定0/10/25/50ms与原生随机延迟分开，另做成本和参数邻域压力。原生随机延迟不是“随机10–50ms”。完整交易数、最大相对权益回撤、净权益恢复比以及预登记六个月OOS均须另行真实验证；Python测试通过只证明分析器的已测行为。

本轮缺项：2024-03起原始FxPro Tick及覆盖清单、完整权益时序、服务器时区/DST、实际合约与费用/延迟快照、最新FIX2及各控制的原始SET/INI/EX5/报告/DEALS/日志。现有功能不依赖这些资料也可运行；相应结论保留待验证。

## 交付检查

`sample_reports/` 提供随版本生成的合成报告和真实旧回测报告，重新运行可更新到 `output/`。源码、原始示例、测试、中文文档、诊断生成器及MT5配置生成器均随包提供。`SHA256SUMS.txt` 覆盖交付包内文件，用于核对交付内容；不等于EA行为验证。

本项目代码及报告仅处理用户明确导入的本地资料。上传新的资料或研究结果到GitHub前检查其中是否含账号、密码等凭据；默认 `input/` 与运行 `output/` 不纳入Git。原始仓库冻结版本保留，研究更改仅位于 `python_analyzer/`。
