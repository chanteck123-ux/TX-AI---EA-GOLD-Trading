# QuantConnect LEAN 原始源码参考库

入库日期：2026-09-19（Asia/Kuala_Lumpur）。用途：供 Codex 与 Claude 读取原始实现、检查边界并研究 MQL5 移植。

**本次已实际复制上次参考包中的 4 个完整 C# 源码文件及原始许可证，不再只有中文说明或外部链接。不是完整 LEAN 仓库，也不是可直接运行的 MT5 EA。**

## 来源与完整性

- 上游仓库：`QuantConnect/Lean`。
- 固定上游提交：`985ef30ad3ac774218c5ac516b4cb0aa2655730f`，沿用 2026-09-18 首批学习版本，不自动追踪 master。
- 代码位于 `upstream_reference/`，保留上游目录结构、文件名、版权头、全部内容和换行；未修改逻辑或默认参数。
- [原始许可证](LICENSE_LEAN.txt)：上游 `LICENSE` 的精确副本，Apache-2.0；Copyright 2014 QuantConnect Corporation。
- [来源与校验清单](SOURCE_MANIFEST.json)：记录逐文件固定来源、Git blob SHA-1、SHA-256、字节数及本仓库路径。
- 已重新读取上游 blob，计算本地副本校验值，并核对本仓库上传后的 blob 和字节数；5 个文件全部匹配。源码核验快照：`52954d2d0952b804fc849002d2967d75b6f9c902`。

本 README 是本项目编写的来源说明，不冒充上游 NOTICE 或 QuantConnect 官方背书。原作者版权与许可证保留；本项目的中文分析与原始代码分开。后续修改或派生实现应保留适用许可及来源说明，并记录具体改动，不把第三方代码标为用户原创。

## 已入库的四个源码文件

| 原始文件 | 研究用途 |
| --- | --- |
| [CompositeAlphaModel.cs](upstream_reference/Algorithm/Alphas/CompositeAlphaModel.cs) | 多模型信号汇集与来源标识；不等于策略一致投票或独立订单账本。 |
| [TrailingStopRiskManagementModel.cs](upstream_reference/Algorithm.Framework/Risk/TrailingStopRiskManagementModel.cs) | 跟踪持仓价值极值并输出退出目标；不是直接更新券商服务器 SL。 |
| [MaximumDrawdownPercentPortfolio.cs](upstream_reference/Algorithm.Framework/Risk/MaximumDrawdownPercentPortfolio.cs) | 组合回撤判定与目标清仓；需另审目标为空、重启、提款和恢复边界。 |
| [SpreadExecutionModel.cs](upstream_reference/Algorithm.Framework/Execution/SpreadExecutionModel.cs) | 点差条件与目标数量执行；研究时区分新开仓门控和紧急风险退出。 |

详细解释、默认参数单位与拟移植边界见 [2026-09-18 中文学习说明](../../docs/LEAN_GOLD_EA_REFERENCE_CN_20260918.md)。该历史文档中“源码副本仅在交付 ZIP”的描述对应首批交付；2026-09-19 已按用户追加要求把相同源码实际保存到本目录。

## 给 Codex 与 Claude 的读取入口

先读本仓库 `AGENTS.md`、当前研究状态和适用计划，再读本 README、清单与所需源码。保存参考代码本身不启动研发或实盘，也不替换本项目 SOP、风险档位、评分锚点和 Champion。

后续获授权开发时，按实际问题选择模块，对照已有实现和指标库，登记假设、接口及改变范围；将有依据的方案接入独立 MQL5 候选，完成真实编译、回测、比较与迭代。源码参考不能代替 EA 决策路径实际接入或盈利验证。两位 AI 的分工与交叉审查沿用当前计划。

保留这里的上游原件；MQL5 派生候选在研究分支维护，不直接改写参考原件或覆盖生产 EA。EA 继续由 MQL5 独立执行交易与本地风控；Python 仅服务本项目 MCP 监控。

## 本次完成状态

已完成：4 个完整原始源码文件入库、原始许可证入库、上游/本地/目标 blob 与字节数校验、来源清单和中文导航。

未包含：完整引擎、依赖包、行情数据、二进制和完整测试套件。四个文件不是独立可编译项目。

未执行：LEAN 或 EA 编译、上游测试、MQL5 移植、MT5 回测、部署及实盘变更。`champion/current/`、用户 SOP、交易参数与现有生产源码未因本次复制而更改。
