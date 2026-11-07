# Claude 分层完成计划（用户于 2026-11-07 选定"分层完成"）

**用户决定**：剩下的文件约 120 MB，不能一次读完，因此按分层标准完成。

**覆盖表规则**：
- "全文阅读""哈希复用""模板比对""数据核对""只记录检查方法""未读"分开记录，不能互相冒充；
- 与 V1.2 无关的模块放到最后处理，没读之前**仍然标为未读**，并注明原因。

## 第 1 层：与 V1.2 执行和风控直接相关，全文阅读
- **LEAN**：
  - `Common/Orders`、`Common/Securities` 中的核心类：保证金、持仓、现金、品种属性、交易时段；
  - `Engine` 中的交易、结果和统计部分；
  - `Brokerages` 中的 Backtesting、Paper；
  - `Common/Statistics`（绩效口径）。
- **QuantSkills**：
  - agent-future-trading 的执行、风控、结算链路；
  - 其他 agent 或 skill 中的下单、风控、对账代码（用 grep 定位后全文阅读）。
- **Kronos**：补读论文剩余的表格。

## 第 2 层：数据文件，用脚本逐行核对（DATA_AUDITED）
- LEAN 的 `Data` 目录：CSV、JSON 等文本数据，以及品种属性库、交易时段库。
- QuantSkills 中的 CSV、JSONL 和结果 JSON。
- 方法：只读解析，逐行统计列数、空值、单调性、范围，并找出与 V1.2 相关的条目，例如 XAUUSD 或 CFD 的品种属性和交易时段。

## 第 3 层：重复的示例和测试代码，先归组
- LEAN 的 Algorithm.CSharp、Algorithm.Python、Tests；QuantSkills 的 tests 目录。
- 方法：按"归一化后的哈希或结构"分组，每组全文读一份代表，其余做 diff 核对。无法归组的，按与 V1.2 的相关性排序后再全文阅读。

## 第 4 层：与 V1.2 无关的模块，最后处理
- 例如股票拆分与分红、期权行权、各加密交易所的手续费模型、指数期权等。
- 在被阅读之前一直标为 UNREAD，并注明"与 V1.2 无关，延后"。

## 进度依据
- 每一批都更新各自的覆盖表：`lean_inventory.csv`、`qs_source_inventory.csv`、Kronos 的 `coverage.csv`；
- 每一批都写批次笔记，并更新回执和断点；
- 只有全部覆盖完成、且 Codex 交叉复核完毕，才标为"双方完成"。
