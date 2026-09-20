# 2026-09-20：QuantConnect 源码归档与交易头脑 v1.2 学习入口

用户要求：学习 QuantConnect 的 Python／C# 算法交易资料，保存到 `research-library/QuantConnect-LEAN`，并纳入开发交易头脑EA（交易头脑 v1.2）的资料。

## 已完成事实

四份上传包 Lean、lean-cli、Research、Tutorials 已按各自固定 commit 保存为静态源码快照，合计 7,340 个原始文件。Research 的 10 个非交易字体文件未分发，排除原因及哈希保存在回执。其他保留文件的路径、字节数与 SHA-256 均匹配上传包。原许可证、测试、数据示例和代码版权说明保留。

归档工作流提交 `710ecd16a6ba2d7f1ab59160948a0e03ad29d12f`；实际源码入库提交 `9292ff1685334f5995e04578bf7a0c606e53c92b`；Actions 运行 `35496488222` 成功，已读回 [IMPORT_RECEIPT](../research-library/QuantConnect-LEAN/snapshots/20260920/_provenance/IMPORT_RECEIPT.json)。工作流仅静态下载、校验和提交，没有执行上游交易代码，没有定时任务。

新增[学习指南](../research-library/QuantConnect-LEAN/LEARNING_GUIDE_CN_20260920.md)、[92 个组织仓库的名称索引](../research-library/QuantConnect-LEAN/ORGANIZATION_INDEX_20260920.json)、[指定代码范围阅读记录](../research-library/QuantConnect-LEAN/LEARNING_STATUS_20260920.json)，并建立[交易头脑 v1.2 专用入口](../开发交易头脑EA/交易头脑v1.2/QUANTCONNECT_LEARNING_CN.md)。其他 88 个仓库仅索引，不写成已下载或全量学习完成。

## 关键学习与接续边界

已核对多 Alpha 来源、组合／风险／执行流程、EMA 交叉与状态区别、等权目标与止损风险手数区别、点差门与紧急退出分流、持仓价值追踪与服务器 SL 区别、组合回撤重置、费用／滑点单位、预热与实验绑定，以及三个研究 Notebook 的指定代码单元。

特别记录：MaximumDrawdownPercentPortfolio 的当前函数包含非空目标条件和初始化重置，不能仅凭类注释当作永久停机锁；SpreadExecutionModel 不在其执行函数中区分紧急退出；Framework 的 Symbol 目标去重不能代替六策略的独立订单归属。

v1.2 本轮依据 2026-09-13 两份指标研究说明建立接续入口。原工作区和最新批次结果没有在本次连接定位，不能标记该工程已接入代码或回退其研究状态。继续开发须读原工作区状态、有效 SET、实验索引和回执，区别六策略项目与旧 GSM 三 SOP 计划。

本次没有编写新的 EA、编译、运行 MT5 回测、改变参数或部署；`champion/current/`、用户 SOP 和两份当前总计划未修改。现有历史四文件副本不删除；新来源不会覆盖已有证据。
