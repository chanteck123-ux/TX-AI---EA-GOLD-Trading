# 可选 EA 诊断观察副本

生成器可运行。生成的 MQ5/MQH **未经过 MetaEditor 实际编译，也未经过 MT5 行为回归，状态为待验证**。Python 主分析工具读取文件即可使用，不需要生成或运行此副本。

## 使用范围

本工具只支持仓库提交 `8326fbab6ee8beb2a0db77aa1f1663e08c4bff41` 中的 `src/GSM_FxPro_RESEARCH.mq5`，版本属性为 `4.23`。已固定源文件完整 SHA256：

```
554b61976a0b04a152c22b33767d264d4b42925b02375702bf69608326946185
```

原 EA 是研究版，其属性明确禁止真实账户执行，不能称为 Champion。生成器复制六个经过完整 SHA256 校验的本地依赖：`StrictRiskResearch.mqh`、`IntradayRunner.mqh`、`StudyEvidence.mqh`、`FeeRiskMath.mqh`、`RunnerRules.mqh`、`RiskMath.mqh`。MT5 标准 `Trade/Trade.mqh` 由本机 MetaEditor 提供，实际编译时还需记录本机终端构建号及标准库版本。

生成器不会修改原源码、SET、交易判断、return、SL/TP 或交易请求，不会调用 MT5、连接账户、发单或启动网络连接。新 MQ5 中只增加一个 include，以及 `PrintFilterAudit` 和 `OnTick` 入口的观察函数调用。观察函数只维护自己的日志序号、采样时间等状态。

## Windows 生成步骤

在仓库根目录运行，Python 3.10 或以上即可，无额外依赖：

```bat
py -3 python_analyzer\tools\make_diagnostic_copy.py --output-dir python_analyzer\output\diagnostic_001
```

若交付包只包含 Python 工具，可明确指向该固定版本 EA 的源目录；六个本地依赖须与源文件同目录：

```bat
py -3 tools\make_diagnostic_copy.py --source C:\EA\src\GSM_FxPro_RESEARCH.mq5 --output-dir C:\EA\analyzer_diagnostic_001
```

输出目录必须不存在。缺依赖、完整源/依赖哈希不符、函数锚点不唯一、已注入过或目标已存在时，工具停止，不会覆盖。输出包含独立 MQ5、新诊断头文件、六个原依赖的逐字副本以及 `diagnostic_manifest.json`，其中记录原/新源码及所有输出代码的 SHA256。生成成功不代表 MQ5 已编译成功。

## 两个独立观察开关

| 输入 | 默认 | 用途 |
| --- | --- | --- |
| `InpAnalyzerDiagnostics` | `false` | 输出已有 `PrintFilterAudit` 决策的结构化观察日志 |
| `InpAnalyzerEquitySamples` | `false` | 在收到 Tick 时按服务器时间间隔输出账户余额/净值快照 |
| `InpAnalyzerSampleSeconds` | `60` | 最短采样间隔；小于等于零按 60 秒处理 |
| `InpAnalyzerRunLabel` | 空字符串 | 空时沿用原 `InpAuditRunLabel`；每次测试请提供独立 Run 标签 |

新诊断观察调用在原 `InpEnableFilterAuditLogs` 开关判断之前，因此即使原日志开关关闭，也能单独打开新观察。原 CSV 写出及原日志开关的行为保持原样。两种观察默认均关闭；开启时打印、格式化和读账户状态可能改变测试速度和执行时序，因此仍须核实原版与副本的关闭/开启结果。

## 日志协议及证据边界

每条记录以 `GSM_ANALYZER|` 开始，字段使用 `key=value`。字符串先把 `%` 转成 `%25`，再把 `|`、`=`、回车、换行分别转为 `%7C`、`%3D`、`%0D`、`%0A`。解析时先按 `|` 分字段，再按第一个 `=` 分键值，最后对值百分号解码一次。保留原始行供追溯。

以下仅为协议示意，非真实运行证据：

```
GSM_ANALYZER|Run=DEMO_SCHEMA_ONLY|Time=2026.01.05 09:00:00|SOP=Scalping|Stage=FILTER_AUDIT|Reason=示意原因|Decision=OBSERVED_BLOCK|ZoneID=EXAMPLE_ZONE|EventID=DEMO_SCHEMA_ONLY:boot:1|Side=BUY|RawCore=1|Indicator=0|MACD=1|Confidence=1|Gate=0|AcceptedObserved=0|DecisionMeaning=PRE_REQUEST_FILTER|DataMode=BACKTEST|TimeZone=SERVER_UNKNOWN
```

- `Time` 使用 `TimeCurrent()` 的服务器时间，**不擅自标注 UTC 或马来西亚时区**；缺少服务器偏移仍需补资料。`EventID` 是 Run、启动标识和观察序号组合，仅用于区分日志事件，不能视为订单号、成交号或统一候选编号。同一 Zone 多次观察不等于多个独立机会。
- `FILTER_AUDIT` 只覆盖源码已经调用 `PrintFilterAudit` 的位置。SOP 尚未形成、无区域、较早 return、新闻或其他未调用 Audit 的分支可能完全不在此日志中。禁止把“没有日志”解释为“没有拦截”或伪造完整漏斗分母。
- `RawCore/Indicator/MACD/Confidence/Gate/AcceptedObserved` 原样观察已有布尔参数。有些参数在早期拒绝处是固定占位值，不能自动当作每个关卡确实执行过。
- Scalping 的 `finalAccepted=true` 在下单请求之前，故 `Decision=OBSERVED_PASS`、`DecisionMeaning=PRE_REQUEST_FILTER` **仅表示当时过滤通过**。Intraday/Swing 的同一函数既有过滤拒绝调用，也有 `opened` 结果调用，标记 `FILTER_OR_ORDER_RESULT`。任何一条 Audit 通过都不单独证明成交。
- 原 `StudyEvidence.mqh` 已有 `STUDY_REQUEST` 回报，无需再添加交易请求日志。请求接受、订单成交及完整平仓分别以原回报、成交记录和持仓生命周期证据确认，不能混用计数。
- `ACCOUNT_SAMPLE` 包含 `Balance/Equity/Currency/Margin/FreeMargin/SampleSeconds`，为**整个测试账户**快照，不能按比例拆给三个策略。单策略独立回测时才可结合运行清单归属。
- 采样在收到 Tick 后才触发，没有 Tick 的间隙不会补造快照。采样净值回撤可能漏掉采样之间的峰谷，必须标记“采样净值回撤”，不能当作 MT5 真实 Tick 最大净值回撤；也不得以余额回撤替代净值回撤。
- `METADATA` 记录品种、账户币种、Point、TickSize、TickValue、ContractSize、VolumeMin、VolumeStep、采样配置及 `DataMode`。这些是测试环境观察值，不证明 Tick 历史覆盖。不会输出账号、姓名、服务器登录凭据、密码或令牌。

## 待执行的 MT5 验证

1. 保存原源码、依赖、实际控制组 SET/INI 的 SHA256；用真实 MetaEditor 编译原版和副本，记录构建号、编译日志及实际 EX5 哈希。编译错误或警告逐项处理，不能用 Python 检查冒充 MQL5 编译。
2. 用同一 FxPro 黄金品种、真实 Tick 区间、资金、杠杆、成本和延迟分别运行原版，以及两个新开关都关闭的副本；核对请求与成交序列、价格、手数、SL/TP、净利润和回撤。
3. 再分别开启决策日志、账户采样、两者同时开启，复用同一控制条件，检查开关未改变策略分支或交易序列，记录性能影响。原生随机延迟须独立记录随机设置及重复运行差异，不能据一次差异武断归因。
4. 将专家日志、原 `STUDY_REQUEST`、成交 CSV、测试报告和 SET/INI 一并导入 Analyzer，核查原始观察、请求、成交之间的证据边界。

这四步尚未在本交付环境中执行。若需要覆盖未调用 Audit 的其他早期分支，应先列明遗漏位置，再另立观察补丁并做同样回归，不应为了“增加交易”删除原保护。
