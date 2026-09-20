# QuantConnect Python／C#：源码学习与黄金 EA 复用指南

日期：2026-09-20（Asia/Kuala_Lumpur）。性质：源码归档、定向代码阅读、知识整理；不是已经实现的新 EA。

## 1. 本次究竟保存了什么

四份用户上传 ZIP 的固定版本已经保存到本目录的 `snapshots/20260920/`。不是只复制说明，也不再局限于早期的四个 C# 文件。

| 来源 | 固定上游提交 | 保留文件 | 内容定位 |
| --- | --- | ---: | --- |
| Lean | `985ef30ad3ac774218c5ac516b4cb0aa2655730f` | 6,315 | 引擎、Python／C# 示例、Framework 模型、指标、测试、示例数据、优化与报告代码。 |
| lean-cli | `20e58aa65c3c504a6a585e1d4eb1b2e56b233c48` | 265 | 项目配置、本地研究、回测、优化、报告及相关命令实现。 |
| Research | `d89cf67bc37bc032f0de47089e16d825bcd8a65f` | 37 | 研究 Notebook、研究转生产示例及相关资料。 |
| Tutorials | `4a341890296f7e79e095508f06170c72ccaa629c` | 723 | Python 金融基础、算法教程、HTML 与 Notebook。 |

合计保留 7,340 个上游文件。其中按扩展名计有 4,357 个 `.cs`、773 个 `.py`、55 个 `.ipynb`；这些数字包含引擎、测试、工具等，不代表有同等数量的独立交易策略。Research 原包另有 10 个非交易字体文件没有分发，排除项全部登记。四仓库原始 LICENSE 和代码版权说明保留。

校验链：上传 ZIP 的提交注释与 SHA-256 → 按提交从官方取回 → 比较所有保留文件的路径、字节数与 SHA-256 → 检查 Git 暂存 blob 与原始字节一致 → 非强制推送。下载 ZIP 因根目录名等封装差异，可以有不同压缩包 SHA；逐文件内容必须一致。

证据：[导入回执](snapshots/20260920/_provenance/IMPORT_RECEIPT.json)，以及同目录四份 `*_FILES.json`。源码归档提交：`9292ff1685334f5995e04578bf7a0c606e53c92b`。GitHub Actions 运行 `35496488222` 已成功。

QuantConnect 组织本次检索得到 92 个仓库，完整名称目录见 [组织索引](ORGANIZATION_INDEX_20260920.json)。其中四个已归档，其余 88 个为索引与后续学习入口，没有声称把整个组织源码全部复制或逐行审完。具体已读函数／Notebook 单元见 [阅读状态](LEARNING_STATUS_20260920.json)。

## 2. 学习地图：先找信息用途，不堆策略

| 要解决的问题 | 先读哪里 | 可提取的知识 |
| --- | --- | --- |
| Python 与 C# 如何描述同一交易事件 | `Lean/Algorithm.Python/`、`Lean/Algorithm.CSharp/`，Framework 中对应 `.py`／`.cs` | 初始化、数据事件、指标更新、信号、目标持仓与订单的分工。 |
| 六策略如何独立扫描、统一审计 | `Lean/Algorithm/Alphas/CompositeAlphaModel.cs`、`Lean/Algorithm/QCAlgorithm.Framework.cs` | 调度多个模型、保留信号来源、把风险与执行分开；另做策略订单归属。 |
| 为什么指标已出现却没有交易 | `Lean/Algorithm.Framework/Alphas/`、`Lean/Common/Indicators/RollingWindow.cs` | 交叉事件与状态条件、预热、数据有效性、信号生命周期。 |
| 为什么仓位计算与可下单量不一致 | `Lean/Algorithm.Framework/Portfolio/`、`Lean/Common/Securities/`、`Lean/Algorithm/Execution/ImmediateExecutionModel.cs` | 目标数量、已有持仓／未成交订单、保证金与订单约束分别计算。 |
| 点差、成交与成本怎样影响结果 | `Lean/Common/Orders/`、`Lean/Algorithm.Framework/Execution/` | 成交、佣金、滑点、执行延迟分开建模；不能照搬别的券商参数。 |
| 止损与组合暂停怎样保持一致 | `Lean/Algorithm.Framework/Risk/` | 单持仓与账户风险的不同状态、触发、退出、恢复与重启边界。 |
| 如何重复实验而不丢源码 | `lean-cli/lean/commands/backtest.py`、`optimize.py`、`research.py` | 配置、运行身份、输出目录、源码副本、依赖／镜像版本与结果绑定。 |
| 趋势／震荡与跨市场信息 | `Research/Research2Production/`、`Research/Analysis/` | 均值回归、Kalman、协整、HMM、因子和机器学习的研究假设与验证方法。 |
| 新闻、经济日历与关联市场数据 | 组织索引中的 FRED、USTreasury、USInterestRate、BLS、USEnergy、BenzingaNews、EODHD 等来源 | 先核对接口、许可、发布时刻、修订与历史可得性；本轮只登记这些额外仓库，未接入数据。 |

上表路径相对于 `snapshots/20260920/`。对未具体阅读的模块，本表只是导航，不作实现正确或策略有效的结论。

## 3. 已核对的代码知识，以及不能直接照搬的地方

### 3.1 信号汇集不等于六策略订单独立

[CompositeAlphaModel.cs](snapshots/20260920/Lean/Algorithm/Alphas/CompositeAlphaModel.cs#L72-L88) 逐个调用模型并返回其 Insight；没有来源名时补 `SourceModel`。这里没有“全部指标同意才开单”的逻辑，也没有根据历史成绩自动选出最佳策略。

[QCAlgorithm.Framework.cs](snapshots/20260920/Lean/Algorithm/QCAlgorithm.Framework.cs#L176-L243) 先生成组合目标、再套风险覆盖、再执行；风险目标与原目标按 Symbol 去重。对六个策略共用 GOLD 的 EA，只复制组合调用方式不足以实现各自独立订单、独立 SL/TP 和盈亏归属。需要保留 StrategyID、Magic、SetupID、订单／成交关系，并结合实际净额或对冲账户核对实现。信号层独立不等于资金风险互不影响。

### 3.2 EMA 交叉事件与 EMA 方向状态不是一回事

[EmaCrossAlphaModel.cs](snapshots/20260920/Lean/Algorithm.Framework/Alphas/EmaCrossAlphaModel.cs#L67-L94) 与[对应 Python](snapshots/20260920/Lean/Algorithm.Framework/Alphas/EmaCrossAlphaModel.py#L36-L58) 都检查快慢 EMA 就绪，并结合前一次方向状态判断转向。长期快线在慢线上方不表示每次数据事件都会发一个新的向上交叉信号。

因此不能把这个模型直接替换为交易头脑已有 E1：E1 是冻结源柱上的 EMA20 三根差值方向门，不是 EMA12／26 交叉。参数、周期、触发事件、状态条件和用途变化要分别登记。Python／C# 两份示例存在，不等于两个独立盈利证明。

### 3.3 等权目标不是按初始止损预算的风险手数

[EqualWeightingPortfolioConstructionModel.cs](snapshots/20260920/Lean/Algorithm.Framework/Portfolio/EqualWeightingPortfolioConstructionModel.cs#L118-L131) 按符合方向条件的非 Flat Insight 数量计算 `1/count` 比例。它不是按“净值 × 单笔风险 ÷ 每手到初始 SL 的预计损失”计算仓位。

迁移黄金 EA 时仍须按实际合约、初始 SL、成本、最小手数、手数步长、组合已有风险和保证金计算。不能把一个信号的等权目标解释为允许满仓，也不能向上凑最小手数后继续声称风险预算不变。

### 3.4 点差执行门必须与紧急退出分开

[SpreadExecutionModel.cs](snapshots/20260920/Lean/Algorithm.Framework/Execution/SpreadExecutionModel.cs#L38-L96) 的默认参数 `0.005` 表示价格比例 0.5%，不是 0.005 个 MT5 Point。判断式是 `(Ask-Bid)/security.Price <= acceptingSpreadPercent`，另检查开市与正报价；分母不是擅自改成的 Bid／Ask 中间价。

该实现对非零待执行数量统一检查价格条件，没有在这个函数中显式给紧急减仓豁免。直接照搬可能把风险退出也留在等待点差的队列。EA 应按已登记政策区分新仓准入与紧急减仓／退出；测试积压目标是否过期、撤销、重复执行，不能等待一个已经失效的 Setup。

### 3.5 TrailingStopRiskManagementModel 不是券商服务器 SL

[TrailingStopRiskManagementModel.cs](snapshots/20260920/Lean/Algorithm.Framework/Risk/TrailingStopRiskManagementModel.cs#L46-L91) 跟踪绝对持仓价值：多单取高值、空单取低值，达到相对变化条件后取消 Insight 并输出零目标。它没有直接设置经纪商服务器保护性止损，也不是扣佣金／隔夜费后的净利润保本。

同向加减仓会改变持仓价值，本函数的显式重置条件是新持仓或方向变化，故分批退出／加仓移植必须单独核对参考值。不要把“持仓价值回撤百分比”混成固定价格差、浮盈回撤比例或账户净值回撤。

MQL5 的保护性止损需使用正确报价、只收紧、按实际服务器接受结果记录，并核算成本和执行失败。平台停止后不再计算新的追踪位置；不能借此模型声称利润已被保证。

### 3.6 组合回撤模型不自带永久停机锁

[MaximumDrawdownPercentPortfolio.cs](snapshots/20260920/Lean/Algorithm.Framework/Risk/MaximumDrawdownPercentPortfolio.cs#L39-L89) 默认非追踪，比较首次初始化组合价值；追踪模式才更新高值。当前实现只在回撤条件成立且 `targets.Length != 0` 时返回相关目标的清仓，并把 `_initialised` 置回 false。

类注释仍提及需要手动重启，但函数又包含重置供后续再平衡继续投资的行为。接入判断以固定版本实际代码和验证为准，不只读注释。它也没有在这里枚举整个账户的全部持仓。因此不能把它当作覆盖空目标、全账户平仓、持久化停机和提款调整的现成模块。

交易头脑需分别登记单策略／账户暂停、恢复、重启持久化、已有仓位管理和现金流调整。不得为了得到较平稳的曲线，清除原紧急锁或忽略停机期间。

### 3.7 成本模型的单位需要逐项核对

[ConstantFeeModel.cs](snapshots/20260920/Lean/Common/Orders/Fees/ConstantFeeModel.cs#L34-L48) 返回固定金额与货币，不是自动按往返标准手收费；[ConstantSlippageModel.cs](snapshots/20260920/Lean/Common/Orders/Slippage/ConstantSlippageModel.cs#L31-L48) 用参考价格乘滑点比例，不是固定点数。名字里的 Constant 不能代替公式、单位与方向检查。

项目净利润沿用实际成交和账单口径；成交价已经体现的点差不能再扣一次。报告列总费用 USD、费用范围与每往返标准手费用，缺失成本不填零。

### 3.8 预热完成、窗口满与信号有效要分开

[RollingWindow.cs](snapshots/20260920/Lean/Common/Indicators/RollingWindow.cs#L247-L265) 的就绪判断是样本计数达到容量。这不足以替 EA 证明时间戳正确、每个数值有效，或某个高周期柱已经收盘。

对 MQL5 指标接口，分别记录数据未就绪、有效零、中性、反向与风险否决；冻结决策当时的源柱时间。OFF 模块不因自身缺数据阻断原策略，ACTIVE 缺值处理只影响被该模块约束的新候选，持仓管理仍持续。

### 3.9 CLI 值得借鉴的是可重复实验，不是替换现有运行栈

[optimize.py](snapshots/20260920/lean-cli/lean/commands/optimize.py) 明确接收参数范围、目标和约束，创建带时间的输出目录，写配置、复制代码并运行指定镜像。读取范围登记于阅读状态。它说明了一种配置与结果绑定方式，不是对参数穷举或自动盈利的认可。

交易头脑保留现有 Node／PowerShell／MT5 研发闭环。Python 仅用于本项目 MCP 监控，C#／Python 上游源码存档不会自动成为 EA 的实时依赖。维护本资料库所用的临时归档脚本不属于 EA 交易或风控实现。

### 3.10 Notebook 先当研究例子，不把历史图当实时信号

本轮核对 Research 的三个 Notebook 代码单元：

- `Research2Production/Python/01 Mean Reversion.ipynb`：用历史价格、均值与标准差筛选资产。该单元输出筛选结果，不是黄金逐笔交易回测；其标准差是价格量纲，迁移到收益预测字段前需核对接口单位。
- `Research2Production/Python/07 Hidden Markov Models.ipynb`：以历史收益拟合双状态模型，再对历史序列进行状态预测和画图。不能把同段拟合后回标的颜色当作历史时刻已经知道的状态；状态编号本身也不是永远固定的牛／熊标签。迁移研究需过去数据训练、按时点推断、记录训练窗口与重新拟合时刻。
- `Research2Production/Python/04 Kalman Filters and Pairs Trading.ipynb`：保存逐步更新回归状态与对冲数量的例子；不能据此预设黄金与美元固定反向，或把股票对冲手数套进 XAUUSD 合约。

这里只进行静态阅读，没有安装 Notebook 依赖、执行其输出或验证模型成绩。部分历史教程 API 与当前版本有差异，后续运行前还需核对。

## 4. 给交易头脑的优先复用方向

先处理工程与可归因问题：信号来源与生命周期 → 已持仓／待执行数量对账 → 决策时点数据快照 → 成本和运行证据绑定。再依当前具体弱项选择一个策略／风险候选，例如趋势与震荡识别、执行门、退出或关联市场信息。

这只是知识使用顺序，不抢占交易头脑已有批次任务，也不要求先证明盈利才可接入候选。接口可靠且假设合理后，按已授权计划实际接入、编译、回测、对照、调整／替换／淘汰，再重新验证。不能长期停在 OBSERVE 或只写报告。

项目专用入口：[开发交易头脑EA／交易头脑v1.2](../../开发交易头脑EA/交易头脑v1.2/QUANTCONNECT_LEARNING_CN.md)。它与旧 GSM 三 SOP 总计划分开，不把两项目的风险参数、评分尺度或 Champion 混用。

## 5. 学习证据等级

`INDEXED`：只有目录；`ARCHIVED_VERIFIED`：原始字节已验证；`REVIEWED_SCOPE`：指定函数或单元已读；`PORT_CANDIDATE`：已有登记的派生候选；`COMPILED`：有对应编译证据；`BACKTESTED`：有对应原生回测；`VALIDATED_SCOPE`：仅在明确条件范围获验证。

本轮四份源码达到 ARCHIVED_VERIFIED；阅读状态列出的有限范围达到 REVIEWED_SCOPE。没有生成新的 MQL5、EX5、SET 或 EA 绩效。没有调整 Champion、SOP、风险上限或实盘。

## 6. 当前官方文档入口

以下官方页面于 2026-09-20 核对；网页会更新，不能当作固定源码版本的替代物。

- [Algorithm Framework 概览](https://www.quantconnect.com/docs/v2/writing-algorithms/algorithm-framework/overview)：模块分工、适用策略与默认组合模型的限制。
- [Reality Modeling](https://www.quantconnect.com/docs/v2/writing-algorithms/reality-modeling/key-concepts)：成交、滑点、费用与组合／品种模型。
- [Warm Up](https://www.quantconnect.com/docs/v2/writing-algorithms/historical-data/warm-up-periods)：预热数据与就绪；预热阶段不交易。
- [CLI Backtesting](https://www.quantconnect.com/docs/v2/lean-cli/backtesting/deployment)：本地／云端回测和 Docker。页面列有 CLI 的付费组织要求；开源代码不代表云平台、数据和全部工具服务均免费。本轮没有开通或购买服务。

保留上游许可、历史四文件副本和全部失败研究；以后按新的固定提交建立增量快照，不覆盖旧来源或改变旧证据身份。
