# S4MT5Probe：S4 B3 测试器专用报价／订单探针（接口说明）

依据 `research/S4_B3_MT5_PROBE_SCOPE_CN.md`（事前登记）。由 Claude 编写；**Claude 没有编译，也没有运行 MT5**。编译、运行和复审由 Codex 负责。原 S4 和七套策略都没有改动。评分 N/A。

## 文件
| 文件 | 作用 |
|---|---|
| `S4MT5Probe.mq5` | 探针 EA（v1.01）。**只能在历史策略测试器中运行**：`MQL_TESTER` 为假时 OnInit 返回 INIT_FAILED；优化或可视化模式也拒绝运行；只接受 GOLD M5。 |
| `run_probe.ps1` | PowerShell 7 runner。改编自 `repair_research/native_runner.ps1`，原文件未改。 |
| `README_CN.md` | 本说明。 |

## EA 输入
| 输入 | 默认 | 说明 |
|---|---|---|
| `InpMode` | `PROBE_QUOTE_ONLY` (0) | 默认只记录报价，不下单 |
| `InpAllowTesterOrders` | false | 只有 `InpMode=PROBE_ORDER` 时才允许并要求为 true；两者不一致时 OnInit 返回 INIT_PARAMETERS_INCORRECT |
| `InpRunLabel` | UNSET | 唯一标签，只允许 `[A-Za-z0-9_-]`；输出目录为 `S4MT5Probe\<label>` |
| `InpDeclaredDelayMs` | -1 | **只是标签**；延迟以 tester.ini 中的 `ExecutionMode` 和测试器日志为证据 |

以下为源码中的固定常数（已登记，不开放为输入）：
- 下单时点：2026-08-03 服务器时间 11:20 和 12:30，各在时点之后第一个有效报价 tick 发起一次卖单；
- 手数：最小手；止损距离 8.0，目标距离 12.0；
- 风险检查：OrderCalcProfit 的止损亏损加 1 USD 预留，不得超过净值的 2%；不合规就跳过该时点，不放大手数，之后也不再补；
- 持仓：单仓；在入场 `DEAL_TIME_MSC`＋1 s 后的第一个 tick 尝试平仓。

## 每个 tick 都执行的干预顺序（逐项标注）
F0 `SymbolInfoTick`（对应原 S4 在 OnTick 开头的刷新，MQ5 第 3198 行）→ I1 `iTime(M5,0)` → F1 → I2 `CopyBuffer(iATR14 M5, shift 2)`（GSMScan4 的 `Val`）→ F2 → I3 `CopyRates(M5,0,7)`（`GSMNewBar`）→ F3。F1、F2、F3 的快照写在 quotes.csv 的 `interventions` 列。订单逻辑在这之后执行。

**观察型干预：**只在需要记录的 tick 上，并且在订单逻辑**之后**，调用 `CopyTicksRange` 读取同一毫秒的行和前 2 秒的最后一行。这一调用本身也是一次测试器干预。

边界：探针只是极简结构，即使它没有复现缓存效应，也**不能**据此否定完整 S4 EA 中存在这种问题。

## 输出（测试代理本地 `Files\S4MT5Probe\<label>\`，均为 CSV，自由文本字段按 RFC4180 转义）
| 文件 | 内容 |
|---|---|
| `meta.csv` | 版本、模式、标签、杠杆、合约规格、干预顺序与边界说明；OnDeinit 追加 `deinit_reason` 和 `on_tester_called_before_deinit` |
| `quotes.csv` | 记录范围：每根 M5 柱边界前后 ±2 s、两个时点前 90 s 到后 180 s、以及每次新柱。每次 OnTick 一行：序号、同毫秒内的序号、TimeCurrent、墙钟微秒、iTime 前后；**缓存报价**（上一次 OnTick 的结果）与 **F0 fresh 报价**分列；测试器自己的 CopyTicksRange 视图、记录原因、干预快照 |
| `orders.csv` | 每次订单事件一行，各时间与报价分开记录：缓存报价、OnTick 的 F0、请求前的 fresh 报价、`OrderSend` 返回后的 fresh 报价；request／result 字段、request_id、订单号、成交号、`DEAL_TIME`（秒）和 **`DEAL_TIME_MSC`**、成交价、position_id 与**通过 identifier＋magic＋symbol 解析出的 position_ticket**、风险／保证金／OrderCheck 结果、墙钟微秒 |
| `transactions.csv` | 每次 OnTradeTransaction 回调一行，按实际到达顺序记录，不预设事务顺序；含回调时的 fresh 报价和 deal 的 `DEAL_TIME_MSC` |
| `summary.csv` | **只由 OnTester 写入**（`on_tester_called=1`）：OnTick 次数、同毫秒重复调用次数、报价变化次数、各时点状态、OnTester 时仍持有的仓位、是否阻止了新单、是否有未知结果的平仓 |

**时间语义：**
- `GetMicrosecondCount` 是进程的墙钟，不是模拟市场时间；
- 缓存报价、请求前 fresh 报价、返回后 fresh 报价、`DEAL_TIME_MSC` 是四个不同的量，不能互相替代；
- 拿不到 `DEAL_TIME_MSC` 时，以“返回后报价时间”作为回退持仓基准，并在 `hold_basis` 中标明。

**订单状态处理：**
- 部分成交（DONE_PARTIAL）后会核实剩余持仓并继续管理，不会开新仓；
- 明确拒绝的平仓在 2 s 后可以重试；
- 结果未知的入场：停止一切新单；
- 结果未知的平仓：不重发，由测试器在结束时平仓；
- 已有持仓的管理不受“停止新单”影响。

## runner 用法（Codex 执行；PowerShell 7）
```
pwsh tools/S4MT5Probe/run_probe.ps1 -Action Status
pwsh tools/S4MT5Probe/run_probe.ps1 -Action Compile
pwsh tools/S4MT5Probe/run_probe.ps1 -Action Run -Variant QUOTE_D0 -BuildManifestPath <session>\private\builds\<token>\build.json
pwsh tools/S4MT5Probe/run_probe.ps1 -Action Run -Variant ORDER_D0 -BuildManifestPath ...
pwsh tools/S4MT5Probe/run_probe.ps1 -Action Run -Variant ORDER_D250 -BuildManifestPath ...
pwsh tools/S4MT5Probe/run_probe.ps1 -Action Resume
pwsh tools/S4MT5Probe/run_probe.ps1 -Action Run -Variant <V> -Diagnostic -DiagnosticReason "..." -BuildManifestPath ...
```
最后一条是诊断重跑：最多 2 次，并且必须先跑过同一变体的主运行。

- **会话目录**默认为 `lean_mcp_20261012/mt5_probe_b3`。`run_registry.json` 强制预算：3 个主变体各一次，诊断最多 2 次。
- **只用固定的 523FF 终端**：核对 origin.txt，用 `/portable` 启动，绝不新建数据目录。终端或 MetaEditor 在运行时一律只等待，不强制结束任何进程。与 `native_runner.ps1` 共用 `runner.lock` 和 `native_owner.json`，两者互斥。
- **编译：**先冻结源码副本，再用 MetaEditor 编译出新的 EX5，日志必须是 0 errors／0 warnings，且源码哈希在编译前后一致。Prepare 只接受与当前工具源码一致的冻结构建。
- **场景：**GOLD、M5、Model 4（真实 tick）、2026.08.03 至 2026.08.04、500 USD、1:1000；`ExecutionMode` 为 0 或 250（三个变体分别为 QUOTE_D0、ORDER_D0、ORDER_D250）。
- **Launch 前核对**冻结的 tester.ini、SET、已安装的 EX5，以及**已安装的 MQ5 与 source manifest**，防止源码与 EX5 身份混淆；同时备份 common.ini 和 terminal.ini。
- **Resume：**先按字节恢复两个 ini 并核对哈希。**恢复失败时返回 `RESTORE_FAILED`**：保留 checkpoint 和 owner，不归档，阻止之后的任何 launch；再次 Resume 会重新尝试恢复并核验。
- **完成判定，不只看进程是否退出。**以下全部通过才为 `COMPLETE_REVIEW_REQUIRED`，否则为 `COMPLETED_WITH_FAILED_CHECKS`：
  - 测试器状态：OnTester 已调用；正常结束（OnTester 在 OnDeinit 之前）；
  - 运行身份：标签与模式匹配；meta 中的测试器标记和 1:1000 杠杆；
  - 输出内容：有报价记录；只报价模式下没有订单和事务；OnTester 时没有遗留仓位，也没有结果未知的平仓；时间都在同一天内；
  - 日志：专家、日期、品种与登记一致；使用真实 tick 生成；Test passed；没有回退；
  - 配置：tester.ini 的 ExecutionMode 与变体一致；ini 已按字节恢复。
- **History Quality 只作诊断字段**：不作为通过条件，也不能证明实际的 tick 覆盖率。
- **延迟证据：**`delay_evidence` 列出 tester.ini 中请求的值和日志中提到 delay 的行，状态始终为 review required。不能凭输入参数的名字声称延迟已经生效。
- **产出：**`runs/<label>/` 下保存 compiled（MQ5、EX5、compile.log）、effective.set、tester.ini、scenario.json、launch_identity.json、probe_output/*.csv、report/、tester_journal.log、probe_result.json（含全部哈希）。

## 边界
- 只报价的探针不能证明 `OrderSend` 的延迟机制。
- 0／250 ms 订单探针产生的盈亏只是取证的副产品，不计入策略成绩。
- 不能因为一次吻合就宣称 B1 已经对等，也不能把事后得到的原生价格输入 LEAN 交易。
- 先核对数据完整性和时钟语义，再解释缓存和取价。
- 绝不用于模拟盘或实盘。
