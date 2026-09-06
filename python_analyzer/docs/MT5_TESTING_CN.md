# MT5 配对回测配置生成与执行

`tools/make_mt5_test_configs.py` 是可运行的纯 Python 配置生成器，不依赖 MT5 Python 包，不启动终端，不连接账户、不下单、不调用付费 API。它读取用户实际提供的两份 SET 和两份 EX5，生成相同外部测试条件的基准/Candidate 配置包。**生成配置不是完成回测；全部结果仍待原生 MT5 验证。**

## 生成命令

在 `python_analyzer` 目录运行，路径替换成实际文件。Windows CMD 使用 `^` 续行：

```bat
py -3 tools\make_mt5_test_configs.py ^
  --baseline-set C:\EA\baseline.set ^
  --candidate-set C:\EA\candidate.set ^
  --baseline-ex5 C:\EA\baseline.ex5 ^
  --candidate-ex5 C:\EA\candidate.ex5 ^
  --baseline-source C:\EA\baseline.mq5 ^
  --candidate-source C:\EA\candidate.mq5 ^
  --run-label I_C01_DEV_D25_001 ^
  --symbol GOLD --period M30 --deposit 2000 --leverage 100 --delay-ms 25 ^
  --from-date 2026-01-05 --end-exclusive 2026-08-27 ^
  --server-timezone UNKNOWN ^
  --cost-assumptions "UNKNOWN_REQUIRES_FXPRO_TERMINAL_CHECK" ^
  --output-dir output\I_C01_DEV_D25_001
```

上例日期是已查看的开发区间示意，不是最终未触碰 OOS；资金和杠杆为研究配置，不是入金建议。请用终端实际支持的 FxPro 黄金/USD 名称，例如 `GOLD` 或 `XAUUSD`，不能拿其他合约替代。输入的 `period` 是测试主图周期，不会自动改变 SET 或源码内部的 M15/M5/M30 入场接口。

两个 `--*-source` 可省略，其余四个 SET/EX5 必须提供。缺失或空文件立即停止；不会创建假 EX5。现有文件的扩展名和 SHA256 只证明读取到这些字节，不能证明 EX5 由某份源码编译而来。实际 MetaEditor 编译日志、依赖哈希和 EX5 关联证据必须另行核实。

## 输出与不覆盖约束

- `baseline.ini`、`candidate.ini`：相同日期、品种、主图周期、资金、USD、杠杆、真实 Tick 模式和固定延迟；只区别专家文件、SET 文件、报告名称。
- `MQL5/Experts/GSMAnalyzer/<run_label>/baseline.ex5` 与 `candidate.ex5`：逐字复制实际提供的二进制，不修改。
- `MQL5/Profiles/Tester/GSMAnalyzer_<run_label>_baseline.set` 与 Candidate SET：逐字复制，包括原编码、换行、优化字段和其他参数。没有用默认值覆盖 SET。
- `test_manifest.json`：输入/输出 SHA256、共同条件、能解析的 SET 输入差异、数据/费用/风险/编译等未核实项目。
- `RUN_IN_MT5_CN.md`：该批次 Windows 手动执行说明。

输出目录必须全新且不存在。所有输入先读完、验证后才创建输出，并用独占写入防止覆盖。正式 EA 源码、参数、Champion 和终端都不会被生成器修改。

清单中的密码、令牌、许可证和账号标识类参数差异会遮盖值；SET 副本仍按要求逐字保留。因此如用户 SET 本身包含凭据，应仅本地测试，不上传或公开分享该测试包。

## 配置约束及实际执行

INI 字段沿用已核实的仓库 `scripts/Run-Candidate.ps1`：`Model=4`、`ExecutionMode=<固定毫秒数>`。固定延迟仅支持 `0 / 10 / 25 / 50 ms`，每种条件生成独立批次。配置含：

```ini
[Experts]
AllowLiveTrading=0
AllowDllImport=0
Enabled=0
[StartUp]
Expert=
Script=
[Tester]
Optimization=0
UseLocal=1
UseRemote=0
UseCloud=0
ReplaceReport=0
```

这些字段用于隔离研究运行，不是任意 EA/终端的全面权限沙箱。**必须使用专用 FxPro 研究终端，先确认没有实盘图表 EA、没有其他同终端测试进程，再执行配置。** 不修改真实账户参数、不上传凭据。生成器本身没有启动终端的代码。

执行顺序：

1. 在同一隔离 FxPro 测试终端核实黄金/USD 品种、USD、Hedging、合约大小、最小手数/步长、TickSize/TickValue、止损/冻结距离、保证金规则与实际杠杆。核实佣金、点差、隔夜费及执行设置，保留截图或原始导出和哈希。
2. 核实同数据、资金、实际风险预算和成本。两个 INI 相同不能保证两个 SET/EA 的风险相同，尤其固定手数、风险比例、最小手数强制上调、费用预算及旧资金阶梯。先审阅清单中的参数差异；若本轮不研究这些模块而它们不同，不得当作公平对比。不能靠生成器私改参数消除差异。
3. 核实 FxPro 真实 Tick 实际覆盖、缺口、原生下载/测试日志、建模质量及实际首尾时间。**配置写了 Model=4 不等于从 2024-03 起已有连续真实 Tick**，也不证明所需品种历史已存在。
4. 将生成包的四个 MQL5 文件按相对目录复制到研究终端数据目录。复制前检查四个目的文件均不存在，使用独立 run_label；禁止覆盖原工程、正式 EA、旧测试输出。`/portable` 模式的数据目录必须确认为该独立终端根目录。
5. 参照生成包的 PowerShell 命令手动执行 `baseline.ini`。等同一终端测试完全结束后，保存 HTML、原生日志、真实成交 CSV、净值数据及公共 Files 目录的 EA 导出，并记录终端版本/哈希、实际 EX5/SET/INI 哈希。
6. 完成基准归档后再执行 `candidate.ini`。**SET 内部的导出文件名和 RunLabel 未改，可能相同**，必须先归档基准文件，防止第二次运行覆盖第一份证据。报告文件名和 EX5/SET 副本路径已分开，但这不能保护 EA 自定义文件名。
7. 导入两次完整证据后才能比较；参数冻结、样本量、回撤、执行行为、费用和 OOS 门槛未通过时标记待验证。基准仅标为“待验证基准”，本生成器不认证 Champion。

## 半开日期、预热与样本边界

Analyzer 统一研究区间为 `[start_inclusive, end_exclusive)`。例如 `[2026-01-05, 2026-08-27)` 表示统计至服务器时间 8 月 26 日结束。日期不带已知服务器时区时，不能默认为 UTC。

生成器将两个日期按字面转为 `FromDate=2026.01.05`、`ToDate=2026.08.27`，不会盲目减一天或推断本机终端末日包含规则。必须用**当前终端 GUI、原生日志及实际首尾 Tick/成交**核实最终执行边界。若终端日期语义不同，先将两组配置同步修正、另存并重新记录哈希，再开始测试；不能只裁掉多余成交就假装终止时的持仓处理没有差异。

预热会读取区间之前的历史；这不算开发交易数、最终 OOS 样本或真实 Tick 覆盖的延伸。历史不足可能使测试器推迟开始时间，须据日志记录实际开始日。最终 OOS 必须预登记并冻结参数，不能用反复读取同一区间来调参。[MT5 策略测试说明](https://www.metatrader5.com/en/terminal/help/algotrading/testing)

## 原生随机延迟单独保存

原生 Random Delay 是秒级分布：90% 为 0–8 秒、10% 为 9–18 秒；**不是随机 10–50 ms**。本生成器不创建随机延迟 INI。请在同一终端 GUI 为基准与 Candidate 分别选择原生随机延迟，保存为新的独立配置，记录配置/SET/EX5 哈希、实际设置及重复运行差异；不能把固定延迟报告改标题冒充随机测试。[MT5 执行延迟定义](https://www.metatrader5.com/en/terminal/help/algotrading/testing)

无法访问真实终端、实际 EX5 或缺少 Tick/成本证据时，继续使用 Python 的数据检查与分析功能；MT5 验证状态保持“待验证”，没有任何 PASS 或收益结果由此生成器预先提供。
