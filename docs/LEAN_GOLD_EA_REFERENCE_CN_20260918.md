# LEAN → MT5 黄金 EA：首批源码学习与双 AI 复用说明

核对日期：2026-09-18。上游：QuantConnect/Lean。

固定上游提交：`985ef30ad3ac774218c5ac516b4cb0aa2655730f`（读取时 master 返回的提交）。

**状态：完成首批阅读、4 个 C# 源码文件与 LICENSE 的精确副本、中文研究映射；未移植 MQL5，未编译 LEAN／EA，未运行上游测试或 MT5 回测，没有部署或实盘变更。** 这是参考资料交付，不是 EA 开发交付，也不是完整 LEAN 仓库。

## 1. 结论与适用边界

值得学习，尤其是模块接口、多信号来源管理、执行条件与风险动作的分离，以及针对边界情况的测试方法。LEAN 是事件驱动的量化交易引擎，主要使用 C#，并支持 Python 算法；并不是把文件改名为 `.mq5` 就可在 MT5 使用的黄金 EA。[S1]

建议采用“借鉴设计／按许可保存参考 → 对照现有工程 → 选取模块 → MQL5 候选实现 → 编译与真实测试”，不把整个引擎变成现有 EA 的在线依赖。

本资料不替换当前中英文 `FINAL_CHAMPION_ITERATION_SYSTEM`，不把旧外部索引中的历史门槛恢复成当前计划。用户原创 Scalping SOP、非原创策略优化权限、研究风险档位、评分锚点与实盘授权继续按当前项目执行。MQL5 独立负责交易与本地风控；Python 仅服务本项目 MCP 监控。

“可复制源码”与“适合直接接入”是两回事；本次复制的是学习参考，不是将其默认风险参数或策略规则装入 EA。

## 2. 本次实际读过与复制的范围

| 文件／资料 | 阅读范围 | 本包处理 |
| --- | --- | --- |
| `readme.md` | 全文 | 记录固定来源，未复制 README |
| `LICENSE` | 全文 | 原文精确副本，文件名 `LICENSE_LEAN.txt` |
| `Algorithm/Alphas/CompositeAlphaModel.cs` | 全文 | 原文精确副本 |
| `Algorithm.Framework/Risk/TrailingStopRiskManagementModel.cs` | 全文 | 原文精确副本 |
| `Algorithm.Framework/Risk/MaximumDrawdownPercentPortfolio.cs` | 全文 | 原文精确副本 |
| `Algorithm.Framework/Execution/SpreadExecutionModel.cs` | 全文 | 原文精确副本 |
| `Tests/Algorithm/Framework/Risk/TrailingStopRiskManagementModelTests.cs` | 第 1–220 行 | 只作测试思路参考，未复制完整测试文件，未运行 |
| 官方 Framework、Reality Modeling、Warm Up 文档 | 相关正文 | 只保存研究摘要与官方入口 |

四个源码文件放在 `upstream_reference/`，路径与上游一致。逐文件计算 Git blob SHA-1，与 GitHub 返回的 blob 值核对一致；另记录 SHA-256。副本未增删注释、未修改逻辑，也未包含依赖、二进制或行情数据。

GitHub 主仓库保存此中文知识条目与导航；源码副本在本次交付 ZIP 中，与生产源码分开。源码固定链接和 blob 在文末及 `SOURCE_MANIFEST.json` 中，可重新取得和核验。

## 3. 最有用的知识与移植方向

### 3.1 模块化：学职责分离，不强行照搬框架

官方 Framework 将选品种、信号、目标仓位、风险调整和执行分开。[S2]

对当前黄金 EA，建议对应为：品种／数据准备 → 各策略信号 → 初始止损与仓位预算 → 账户／策略风险检查 → 订单执行 → 订单反馈与审计。

这能让 Codex 与 Claude 分别研究一个模块，并在固定其他条件时比较变化。但初始止损与入场结构有依赖时应保留明确接口，不能为了“解耦”丢失 SOP 所需的信息。官方也说明技术进出场策略未必适合所有默认 Framework 模型，必要时使用自定义或混合设计。[S2]

**不照搬默认资产权重。** 目标资产权重不是“到初始止损的账户风险”。黄金手数仍按实际合约、净值、止损距离、成本、最小手数／步长及保证金计算，而不是按默认等权分配。

### 3.2 多策略：保留信号来源，不把独立扫描变成一致投票

`CompositeAlphaModel.Update` 遍历每个子模型，输出各自的 Insight，并在缺失时补 `SourceModel`。[S3]

可借鉴的设计是让每条信号带 `StrategyID`、`SignalID`、来源版本、形成时间、有效期和失效原因；各策略不必等其他策略同意才产生候选。这里的“组合”是逐个调用模型并合并输出，不代表多线程执行，也不自动提供 MT5 的独立订单账本。

拟移植时另外建立订单／成交／持仓归属与策略风险账本；核对账户实际净额或对冲模式，不默认一个模型就是一张独立仓位。同一品种的反向信号、目标冲突、旧信号失效、重启后归属，都需明确政策。策略独立扫描不等于免除组合风险限制。

### 3.3 风控：清仓目标与服务器止损要分开

`TrailingStopRiskManagementModel` 使用绝对持仓价值，按多空方向记录有利极值；超过阈值后取消该品种的 Insight，输出 `PortfolioTarget(symbol, 0)`。[S4]

它并非在这里下达或修改券商服务器 SL。其回撤分母也不是简单的“已赚浮盈金额”。因此不要把该类直接叫作“移动止损保证锁利”，也不要把默认 `0.05` 解释为黄金应采用的 5% 账户风险。

拟移植需分别研究：持仓价值／价格回撤触发的退出，与服务器 SL 只收紧的追踪。测试加仓、减仓、方向变化时极值是否需要调整；否则持仓数量变化可能被误当作价格变化。这是需要验证的移植边界，不是宣称已经发现上游在所有场景都出错。

### 3.4 账户回撤：不能只读注释

`MaximumDrawdownPercentPortfolio` 的类注释提到触发后需手动重启，但本次固定版本的实现会在触发时将 `_initialised` 设为 `false`；且触发分支要求 `targets.Length != 0`，只遍历传入的目标。[S5]

**不能据此推定它已经实现了覆盖所有持仓、跨重启持续锁定的账户熔断。** 后续要查实际调用链；移植到 EA 时，应显式区分账户／策略作用域、已持仓风险、新单暂停、紧急减仓、恢复条件和状态持久化。

提款还应区分现金流与交易损失：研究采用哪种回撤基准、提款怎样调整基准、提款后剩余资金如何继续运作，均要单独登记。不是简单复制上游总资产比值公式就完成提款研究。

### 3.5 点差与执行：新单门控不应默默拦住风险退出

`SpreadExecutionModel` 的条件是正价格、正 Bid/Ask、交易时段，以及 `(Ask-Bid)/Price <= acceptingSpreadPercent`；通过后提交剩余目标数量的市场单。[S6]

默认 `0.005` 是比例 0.5%，不是 0.005 个 MT5 Point，不是固定 5 点。该阈值不能直接当作黄金适用参数。

从本文件控制流可见，非零的待执行数量都会经过同一价格条件，没有在这里单列“紧急退出绕过入场点差过滤”。因此，**若把风控清仓目标交给这个模型，它可能也被点差门控延后**；这是基于源码的条件性推论，未在本轮运行复现。

拟移植时单独定义开仓、普通减仓、紧急退出的执行政策，保留重报价／拒单／部分成交／修改失败的确认与重试边界。不能以“价格不理想”无限阻止已登记的紧急处理。

### 3.6 回测质量：学习成本模型与边界测试

LEAN 官方把成交、滑点、费用、购买力等建模为可定制组件；默认现实模型也有适用假设。[S7] 可借鉴这种分项记录方法，但 LEAN 回测不自动等于 FxPro 黄金真实 Tick 验证，也不能替换 MT5 目标环境的测试。

Warm Up 文档区分预热状态与指标就绪，并说明数据缺失与供应商限制。[S8] 对当前 EA，研究中记录多周期数据时间、已收盘／未收盘状态、指标就绪与缺失值；预热结束不作为所有输入均正确的证明。

已读追踪风控测试包含多头、空头、未持仓、方向变化、首次调用和阈值边界，并在该测试中设置零费用。[S9] 这证明作者设计了这些功能断言，不证明黄金盈利，也不是成本压力测试，更不表示本轮已执行这些测试。

## 4. 给 Codex 与 Claude 的首批研究映射

以下是建议研究卡，不是已实现功能或本轮启动的实验。先查现有工程，已有能力优先补测试或修复，不重复重写。

| 参考卡 | Codex 可主负责 | Claude 可交叉负责 | 后续验收重点 |
| --- | --- | --- | --- |
| LEAN-REF-01 数据与信号契约 | 现有数据／指标接口与信号结构 | 时间边界、旧信号、归属冲突审查 | 无前视、来源可追溯、缺数据行为明确 |
| LEAN-REF-02 执行与成本 | 点差、成交回报、异常处理候选 | 成本口径与紧急退出反例 | 新单门控和紧急动作分离；成本不重扣 |
| LEAN-REF-03 回撤与恢复 | 风控状态、作用域和持久化 | 无目标／重启／提款／反复进出场反例 | 既有风险不漏计，恢复规则可验证 |
| LEAN-REF-04 退出对照 | MQL5 保本／追踪候选实现 | 参数单位、多空、加减仓及统计口径 | 固定基础条件比较退出方案 |
| LEAN-REF-05 双模型研究审计 | 任务、版本与产物关联 | 报告归因、重复试验和 OOS 曝光检查 | 提交／源码／EX5／SET／报告一一对应 |

负责人可对调，不预设某个 AI 必然更擅长策略或编码。同一任务一个代码主负责人，另一位独立检查；存在不同研究假设时再分别建立候选，不默认两位把所有代码各写一遍。

建议首轮优先排查“风险退出被入场过滤阻挡”和“风控基准／状态重置”；只有现有代码存在对应证据或明确研究需求，才进入候选开发。不要为了使用 LEAN 而强行新增模块。

后续明确启动相应开发任务后：

`问题证据 → 登记假设与改变范围 → MQL5 决策路径实际接入 → 编译 → 同条件 MT5 回测 → 双 AI 分析 → 调整／替换／淘汰 → 再测试 → 冻结后独立验证`

保留当前条件下有证据的最佳版本。开发区间可以反复改进；已用于调参的数据不再算未见过的 OOS。净利润 USD、最大净值回撤金额与最大相对净值回撤、PF、完整交易数、成本及提款后持续运作是主要结果；胜率、平均盈亏比与连续亏损用于辅助诊断。评分按当前计划，不自创满分锚点。

使用指标时优先检查 `chanteck123-ux/gsm-mt5-indicators` 当前 README、manifest、缓冲区及验证说明；本轮没有重新检查该库，也没有将 LEAN 指标覆盖进去。

## 5. 复制、改写与许可证

本次根 LICENSE 和四个源码文件的许可声明为 Apache-2.0。[S10] 该许可允许依条款复制、修改和分发，包括商业用途；分发时须附许可证、保留适用声明、在修改文件中标明改动，存在适用上游 NOTICE 时一并保留。商标不因此获得任意使用权。

本包保留原始文件内容与版权头，附 `LICENSE_LEAN.txt`。`THIRD_PARTY_NOTICES.md` 是本次编写的来源说明，不冒充上游 NOTICE。

未来逐项记录复用方式：`REFERENCE_ONLY`、`DIRECT_COPY`、`ADAPTED_PORT` 或 `INDEPENDENT_IMPLEMENTATION`。直接参考源码翻译到 MQL5 不应不加说明地声称是 clean-room 开发；适用许可与来源义务应保留。

本轮未分发依赖、数据集、网站全文或云服务；这几类资源的使用权不能从引擎许可证自动推定。完整依赖审计和正式产品分发审查不在本轮范围内。

## 6. 完成记录与尚未完成项

已完成：固定上游版本；读取上表范围；复制 4 个源码文件及 LICENSE；逐一核对 Git blob 并生成 SHA-256；保存中文研究卡、来源说明与状态。

未完成／未执行：完整仓库审计或整库复制；C#／Python 运行环境安装；完整依赖装配；上游编译和测试；MQL5 移植；EA 编译；真实 Tick／成本压力／OOS／提款测试；最佳策略评选；部署与实盘。

这份文件可作为两个 AI 的下一次任务入口，但“学习与保存”本身不启动其中的开发事项。

## 7. 来源与固定入口

- [S1] [LEAN README（固定提交）](https://github.com/QuantConnect/Lean/blob/985ef30ad3ac774218c5ac516b4cb0aa2655730f/readme.md)
- [S2] [Algorithm Framework 官方概览](https://www.quantconnect.com/docs/v2/writing-algorithms/algorithm-framework/overview)
- [S3] [CompositeAlphaModel.cs](https://github.com/QuantConnect/Lean/blob/985ef30ad3ac774218c5ac516b4cb0aa2655730f/Algorithm/Alphas/CompositeAlphaModel.cs)
- [S4] [TrailingStopRiskManagementModel.cs](https://github.com/QuantConnect/Lean/blob/985ef30ad3ac774218c5ac516b4cb0aa2655730f/Algorithm.Framework/Risk/TrailingStopRiskManagementModel.cs)
- [S5] [MaximumDrawdownPercentPortfolio.cs](https://github.com/QuantConnect/Lean/blob/985ef30ad3ac774218c5ac516b4cb0aa2655730f/Algorithm.Framework/Risk/MaximumDrawdownPercentPortfolio.cs)
- [S6] [SpreadExecutionModel.cs](https://github.com/QuantConnect/Lean/blob/985ef30ad3ac774218c5ac516b4cb0aa2655730f/Algorithm.Framework/Execution/SpreadExecutionModel.cs)
- [S7] [Reality Modeling 官方文档](https://www.quantconnect.com/docs/v2/writing-algorithms/reality-modeling/key-concepts)
- [S8] [Warm Up 官方文档](https://www.quantconnect.com/docs/v2/writing-algorithms/historical-data/warm-up-periods)
- [S9] [追踪风控测试文件（本轮只读第 1–220 行）](https://github.com/QuantConnect/Lean/blob/985ef30ad3ac774218c5ac516b4cb0aa2655730f/Tests/Algorithm/Framework/Risk/TrailingStopRiskManagementModelTests.cs#L1-L220)
- [S10] [上游 LICENSE](https://github.com/QuantConnect/Lean/blob/985ef30ad3ac774218c5ac516b4cb0aa2655730f/LICENSE)；[Apache 官方条款](https://www.apache.org/licenses/LICENSE-2.0)


## 8. 原始副本核验记录

| 上游路径 | Git blob SHA-1 | 本地 SHA-256 |
| --- | --- | --- |
| `Algorithm.Framework/Risk/TrailingStopRiskManagementModel.cs` | `abb6156048789046e1c7747690b86c90f533ec09` | `c27a91e290fe49533dc9b3df33744d1aa1106affeec506266cc85c841e28db52` |
| `Algorithm.Framework/Risk/MaximumDrawdownPercentPortfolio.cs` | `dcd658844d7087d240debb1508752c025a597428` | `db3ec2657d881394abc0b50fa41a27b0e7b72edfa66dd3d9bfff1fc76c268a9c` |
| `Algorithm/Alphas/CompositeAlphaModel.cs` | `068b6d2b5503554ad8c1386cbd76c7aa015feb47` | `1acd2264dfd9710a33e8fdb191f896e84329dd1c88ba81d8f6c775686c73b524` |
| `Algorithm.Framework/Execution/SpreadExecutionModel.cs` | `0d30fb89053e2ac47831afaf60d917ebe62a0d30` | `1d67da39182ee135bfda0459c22a88147f9988fef432fe9d11f5753a0d383b43` |
| `LICENSE` | `6faed93d21a1a9551b11434e87c9000a393d73f2` | `522cf0a716ce03f67d46f8fceb5bf78c5b84400ec5cd8d14bf9f02cddc1cb6ba` |
