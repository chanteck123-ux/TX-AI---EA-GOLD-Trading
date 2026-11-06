# QuantConnect LEAN 固定源码快照（2026-11-01）

来源：用户桌面提供的 LEAN 解压目录。经核对，它与 **QuantConnect/Lean master 提交 `1383825685849e32e0074f34c3be85b627e0f50f`（2026-10-30）** 完全一致：6,522 个文件的 git blob 全部等于上游，没有多出、缺失或改动的文件。许可证为 Apache-2.0，原样保留。

- 保存方式与 `../20260920/` 相同：完整保留源码、测试、示例数据（含 `Data/` 下的 697 个 zip）、配置与 `.github`。嵌套的 `.github` 工作流只作存档，不在本仓库中执行。
- 导入时绕过了 LEAN 自带的 `.gitignore` 和 `.gitattributes`（以 `--no-filters` 写入对象），所以字节不被换行规范化，被忽略的路径也保留。仓库中该目录树与上游提交的树逐项相同。
- 逐文件路径、字节数、SHA-256：`_provenance/Lean_FILES.json`；导入证据：`_provenance/IMPORT_RECEIPT.json`。

## 与 2026-09-20 快照（`985ef30`）的差异
与上一版相比：相同 5,588、修改 724、新增 210、删除 3，明细见 `_provenance/Lean_CHANGES_vs_985ef30.tsv`。

- 修改或新增的文件中，615 个位于 `Common/Data/Fundamental`（基本面数据类），与黄金无关。
- 与本项目相关、经 diff 确认的变化（只读 diff，**未编译、未运行**）：
  - **新增条件（contingent）订单支持**，即 OCO/OUO 一类联动订单：涉及 `BacktestingBrokerage`、`BrokerageTransactionHandler`、`CashBuyingPowerModel`。条件单在等待父单期间不占购买力，同组兄弟单只按其中最大的一张预留。
  - `OandaBrokerageModel` 与 `FxcmBrokerageModel` 新增 `ValidateContingentOrdersNotSupported`，这两个外汇/CFD 券商模型会**拒绝**条件单。
  - `MarketHoursDatabaseJsonConverter`：在市场整体休市日如果该品种有提前收盘或推迟开盘，改记为"银行假日"类日期，不再当作完全休市。
  - 新增 `QuantBridgeBrokerageModel`，删除 `TerminalLinkBrokerageModel` 的测试等。
- 对项目的提示：
  - LEAN 研究端若用 OCO 模拟 SL/TP，其语义与 MT5 服务器端 SL/TP 不同；选用 Oanda/FXCM 模型时，条件单会被直接拒绝。跨引擎核对需要按 PLAN §2.1 分别记录。
  - 交易时段、节假日口径的变化可能改变黄金/CFD 的可交易时段计算，升级引擎前需要用同一数据对比。

## 边界
本快照用于可追溯研究，**不代表**项目的 LEAN 研究工作区已经升级到此版本，也不代表已编译、测试或回测。研究端实际使用的引擎版本以 V1.2 的 research 记录为准。旧快照 `20260920` 原样保留。
