# LEAN 数据批次：zip 检查方法与 XAUUSD 示例数据审计（Claude，2026-11-07）

## 一、697 个 zip：只记录检查方法，不计为已读
- 方法：`tools/zip_manifest.ps1` 用 .NET ZipFile **只读打开中央目录**，不解压到磁盘，也不执行任何内容。逐个记录条目数、前 3 个条目名、声明的解压大小，以及可疑条目：路径穿越、绝对路径，或 exe/dll/ps1/bat/cmd/sh/py/cs 后缀。结果在 `coverage/zip_manifest.csv`。
- 结果：
  - 697 个全部能打开，**可疑条目为 0**，共 48,329 个条目。
  - 其中 43 个期权 zip 的每个条目声明大小都是 **4,294,967,295（0xFFFFFFFF）**，这是哨兵值，不是真实大小。所以表面上合计约 112 TB 的解压大小**不代表 zip 炸弹**。真实解压大小需要读 ZIP64 扩展字段或用流式计数确认，这一步未做。
  - 其余 654 个声明合计约 1,533 MB，单个最大 112.9 MB。
- 状态：这 697 行仍为 **UNREAD**，method 记为 BINARY_METHOD_ONLY。下面第二节审计过的 XAUUSD zip 除外。

## 二、XAUUSD（cfd/oanda）41 个 zip：DATA_AUDITED
- 方法：`tools/audit_xauusd_zips.ps1` 在内存中流式读取每个 CSV 条目，逐行解析。结果在 `coverage/xauusd_audit.csv`。
- 覆盖：
  - daily 1 个，2006-03-20 至 2019-02-25，3,949 行；
  - hour 1 个，同一区间，76,499 行；
  - minute、second、tick 各 13 天，都是 2014-05-01 至 2014-05-15；
  - **合计 2,472,580 行**。
- 结果（CONFIRMED）：
  - 时间键都**严格递增**（非递增 0 条）；
  - 非正价格 0 条；
  - bid 高于 ask（交叉报价）0 条。
- 格式：
  - daily 和 hour 是 `yyyyMMdd HH:mm` 加 bid OHLC、bid 量、ask OHLC、ask 量，共 11 列；
  - minute 和 second 的第一列是距当日 0 点的毫秒数，共 11 列；
  - **tick 只有 3 列**（毫秒、bid、ask），没有挂单量。
- 点差（ask 收盘价 − bid 收盘价，单位为美元/盎司）：
  - minute 数据最小 0.25，日均 0.27–0.51，最大 2.6；
  - hour 数据最大 10，daily 数据最大 5.5。
  - 本审计脚本按 5 列解析 tick，所以 **tick 点差没有统计**，这是未完成项。
- 时段：
  - 周日文件从 79,200,000 ms（22:00）开始，只有约 120 根分钟 bar；
  - 周五在 75,540,000 ms（20:59）左右结束；
  - 工作日约 1,257–1,390 根分钟 bar，少于 1,440，说明**有缺分钟**，缺口位置没有逐一列出。
  - 以上时间以数据文件的时区为准；按 LEAN 的 market-hours 数据库应为 Oanda 所用时区，本次未核对。
- **对 V1.2 的含义**：
  - 这是 2014 年 Oanda 的数据，点差和交易时段都**不能代表 FxPro**。
  - 只能用来验证 LEAN 流程，不能作为成本或延迟证据。
  - tick 没有挂单量，所以 VolumeShare 一类的滑点模型在这里只能退化为 0（见 L001）。

## 三、品种属性库与交易时段库（2026-11-07，第 2 层数据核对）
- **`Data/symbol-properties/symbol-properties-database.csv`**（SHA-256 前 16 位 53072f5a5ac4ff1b）：**DATA_AUDITED**，用 awk 逐行解析。
  - 共 10,824 条数据行、8 条注释行；按"市场 + 代码 + 类型"组成的键没有重复；乘数、最小变动价位、手数都没有 ≤ 0 的值。
  - 列数在 8 到 12 之间，因为尾部的可选列有时省略。
  - 类型分布：crypto 8,609、cryptofuture 1,681、future 219、cfd 182、forex 111，其余是少量其他类型。
  - **XAUUSD 的三条记录**（CONFIRMED）：

    | 市场 | 报价货币 | 合约乘数 | 最小变动价位 | 手数 |
    |---|---|---|---|---|
    | fxcm | USD | 1 | 0.001 | 1 |
    | oanda | USD | 1 | 0.001 | 1 |
    | interactivebrokers（London Gold） | USD | 1 | 0.01 | 1 |

    也就是说，LEAN 中 1 单位 XAUUSD 等于 1 盎司，最小下单量为 1 盎司。而 MT5 GOLD 通常按"手"计算，1 手约 100 盎司，最小 0.01 手。**这一点必须核实 FxPro 的实际合约规格**（未联网核实）。跨引擎核对时必须把单位换算写清楚，否则仓位和风险会相差 100 倍。
- **`Data/market-hours/market-hours-database.json`**：**PARTIAL**。只读解析了条目总数（552 个），以及与 XAUUSD 相关的 4 个条目。
  - **Oanda XAUUSD**：交易所时区为 America/New_York，数据时区为 UTC。周日 18:03 开市；周一到周四每天 16:58 收盘，18:03 重新开市；周五 16:58 收盘；周六休市。另有 1 个假日、1 个提前收盘。
  - Oanda CFD 的通配条目是 17:00 收盘、17:00 开市；FXCM XAUUSD 用 UTC，每天 22:00 至 23:00 休市，周五 21:45 收盘；IB XAUUSD 用 UTC，每天 21:00 至 22:00 休市。
  - **与数据审计交叉验证**：示例分钟数据中周日文件从 79,200,000 ms 开始，按 UTC 计是 22:00，在夏令时期间就是纽约时间 18:00，与交易时段库中的 18:03 开市大致吻合（CONFIRMED，二者一致）。
  - **对 V1.2 的含义**：每日休市时段、周末规则和服务器日的定义都随券商而不同。FxPro 的服务器时区和 GOLD 交易时段需要**单独核实**，这一点直接影响 Scalping"每日 6 盈 / 6 亏"按哪一天计数。
- `Data/symbol-properties/security-database.csv` 仍为 UNREAD。

## 四、批次 L-DATA3：Data 目录文本数据的结构审计，以及一次更正（2026-11-07）
- **方法**：用 `tools/audit_text_data.ps1` 对 `Data\` 下状态为 UNREAD 的文本数据只读地逐行解析。CSV 类文件统计行数、列数分布、空字段数、数值字段占比，以及第一列按字典序非递增的次数；JSON 文件只做解析，并记录顶层结构。结果在 `coverage/data_text_audit.csv`。
- **结果**：
  - 共 424 个 CSV 和 4 个 JSON 记为 DATA_AUDITED，合计 165,034 行；
  - 2 个 alphastreams 的 portfoliostate JSON 解析失败（疑似一行一个对象的格式），**仍为 UNREAD**；
  - 18 个文件的列数不一致。
- "第一列非递增"在 247 个文件中出现，多数位于 future 目录。第一列不一定是时间，所以这项统计**不作为错误结论**，只是结构信息。
- **⚠ 更正**：脚本把 14 个 `.md` 说明文档也按结构审计记为 DATA_AUDITED，这种方法不适用于文档。现已改回 UNREAD 并逐字读完：其中 9 个 FULL_READ，长行在截断后又单独补读了后半段；5 个期货保证金 readme 与 cbot 版本 SHA 相同，记为 HASH_REUSE。另有 8 个 `.keep` 是 0 字节的空文件，记为 FULL_READ（EMPTY_FILE）。
- **readme 中与 V1.2 有关的内容（CONFIRMED）**：
  - LEAN 的 CFD 数据只有 Oanda 的**报价数据，没有成交数据**；
  - 分钟线和秒线的第一列是"距午夜毫秒数"，readme 没有写明时区，时区以交易时段库为准（Oanda XAUUSD 的数据时区为 UTC，见第三节）；
  - tick 只有毫秒、Bid、Ask 三列，与第二节的审计一致；
  - 外汇数据来自 Oanda 和 FXCM。
