# LEAN L0009 全文静态审核

审核日期：2026-11-04。审核者：Codex。状态：FULL_TEXT_READ_STATIC_REVIEW_COMPLETE。

## 范围与证据

仅处理固定清单 `codex/inventory/batch_plan.json` 的 L0009（Common）：40 个 segments、40 个文件、6,299 行，全部逐行读取，包括注释、声明和空行。实际源码根目录为 `C:/Users/A/Desktop/TX/QuantConnect/Lean-master QuantConnect的精简算法交易引擎（Python、C#）`，中文文字是目录名的一部分。每个文件的 SHA256 与固定清单一致，实际行数与对应 segment 终点一致。逐文件完整哈希、起止行及读取状态见同目录 coverage.json。

阅读按清单顺序拼接为全局行号，分为 1–600、601–1200、1201–1800、1801–2400、2401–3000、3001–3600、3601–4200、4201–4800、4801–5400、5401–6000、6001–6299 共 11 次成功输出；这些源码输出均未截断。最初整份清单显示曾被截断，随后单独提取完整 L0009；最初误用不含中文的目录导致读取失败，失败输出不计阅读覆盖。后续正确路径读取覆盖全部范围。哈希核对脚本曾有一次管道语法错误，纠正后成功核对，失败命令不作验证证据。

本次没有运行或导入项目源码，没有编译、回测、测试、调用外部服务或修改源码；没有读取或写入 Claude 目录。结论来自静态控制流和数据流，不代表运行复现，也不宣称整个 LEAN、外部 API 或交易系统已通过验证。未审阅批外调用方和测试；下列外部响应场景均为条件分析，并非实际服务返回记录。

## 主要发现

以下路径均相对源码根目录。P1 表示触发时可能导致进程失败或重要状态不同步；P2 表示应修复的行为或输入边界问题。优先级不是实际事故记录。

### F01 / P1：目标集合 KeyValuePair 重载直接递归

证据：`Common/Algorithm/Framework/Portfolio/PortfolioTargetCollection.cs:125–128,225–228`。`Add(KeyValuePair<Symbol, IPortfolioTarget> target)` 内再次调用 `Add(target)`；`Contains(KeyValuePair<...> target)` 同样调用 `Contains(target)`，参数类型不变、没有退出条件。调用这两个重载会持续自调用，存在栈溢出及进程终止风险；普通 IPortfolioTarget 重载不受此特定问题影响。建议显式委托字典接口或正确的 value 重载，并定义键和值一致性。待验证：分别通过公开重载和 ICollection<KeyValuePair<...>> 调用；本次未执行。

### F02 / P2：Insight.Clone 并非声明的深拷贝

证据：`Common/Algorithm/Framework/Alphas/Insight.cs:319–336`，其中 `Score = Score`；`InsightScore.cs:77–105` 的 SetScore/Finalize 会修改对象。克隆和原对象共用可变评分，修改或终结任一对象的评分会影响另一个，可能污染快照、对照或评分状态。建议复制评分值、更新时间和终结状态，另核对 period specification 的克隆语义。待验证：修改 clone 的 Score 后原对象应不变。

### F03 / P2：InsightCollection 索引写入破坏集合一致性

证据：`Common/Algorithm/Framework/Alphas/InsightCollection.cs:162–177` 对字典和计数赋值，但不更新 `_insightsComplete`；与 Add 的 66–79 行及 GetInsights 的 362–370 行不一致。通过索引加入的新 insight 可被枚举和计数，却不在完整历史查询中。setter 还直接保留调用方 List 引用，外部随后增删会绕过锁和计数。建议统一写入路径并复制列表；明确替换是否进入历史，按契约统一行为。

### F04 / P2：InsightCollection setter 允许空值，读取路径不兼容

证据：同文件 166–176 行允许赋 null 并保留 key；187–195 行 TryGetValue 对找到的值直接 ToList，112–117 行 ContainsKey 直接访问 Count；241–251 行对每个列表调用 Min。赋 null 后上述路径可异常；赋空列表且另有非空列表时 GetNextExpiryTime 会对空列表 Min。建议 null/空列表表示删除，或让全部读取路径一致处理。

### F05 / P2：目标集合 Contains 与 Values 的公开语义不一致

证据：`PortfolioTargetCollection.cs:200–217` 注释承诺检查指定对象，实际仅检查 Symbol，故同 symbol、不同数量的另一个 target 也返回 true；Remove 在 309–315 行却检查 Equals。84–96 行还把内部枚举缓存 List 作为可变 ICollection 返回；调用 Values.Clear() 可令后续默认枚举为空，而 Count、索引和字典仍保留目标（384–394）。建议 Contains 比较实际对象，并返回不可变或独立 Values 快照。两个触发场景独立，应分别验证。

### F06 / P1：自动信号导出失败后丢失重试标记

证据：`Common/Algorithm/Framework/Portfolio/SignalExports/SignalExportManager.cs:238–273`。Flush 调用 SetTargetPortfolioFromPortfolio 时不检查 bool；无论返回 false 或抛出后被 catch，最后都将 `_initialOrderEventTimeUtc` 重设 EndOfTime。若临时网络失败且之后没有新成交，后续 Flush 不再尝试该持仓状态。193–196 行逐个发送，某个 provider 抛异常还会阻断后面的 provider。建议逐 provider 记录成功/失败，保留失败待处理状态，按明确退避和幂等策略重试；不把发送成功当成外部成交。

### F07 / P2：Numerai 未检查上传 PUT 结果

证据：`Common/Algorithm/Framework/Portfolio/SignalExports/NumeraiSignalExport.cs:225–263`。取得 putResponse 后不检查状态就提交 createSignalsSubmission，上传失败时仍继续后续流程。200、229、263 行取得的响应也没有 using/dispose。建议验证上传成功才提交，释放每个响应；对重试和最终 submission ID 单独记录。最终提交接口可能拒绝失败上传，不能由此推断一定会产生错误持仓或一定返回 true。

### F08 / P2：外部响应结构异常会绕过布尔失败路径

证据：`NumeraiSignalExport.cs:208–215,271–275` 对 `data` 直接链式索引；缺少 data 的错误 JSON 可在错误日志分支前抛异常。`Collective2SignalExport.cs:290–305` 先解析 JSON 再检查 HTTP 状态，错误非 JSON/空体会在状态处理前失败；`PrintErrors` 311–324 行以 `errors?.Count == 0` 判断，null 不会进入该分支，之后 foreach null。建议先处理 HTTP 和解析失败，再逐层验证字段；区分传输成功、业务成功和外部执行状态。

### F09 / P2：Collective2 过滤不支持目标后仍发送完整组合

证据：`BaseSignalExport.cs:37–48,90–101` 默认允许 Crypto/Cfd 等；Collective2 没有覆盖此集合，`Collective2SignalExport.cs:180–189,203–214,446–465` 遇不支持类型、过期品种或转换后零数量时跳过，最后仍返回 true。该文件 203–204 行明确说明省略持仓表示平仓；因此过滤后发送是不完整组合，按本地声明契约可能导致未预期的远端平仓。外部实际接口语义未联网核实，列为契约风险而非已发生事故。建议失败即停止整次发送，或由调用方明确批准部分组合；合法零目标与转换失败必须区分。

### F10 / P2：CrunchDAO 替换提交缺少失败保全

证据：`Common/Algorithm/Framework/Portfolio/SignalExports/CrunchDAOSignalExport.cs:121–130,246–267,275–287`。先删旧提交，再上传；删除成功但上传失败会失去旧提交。GetLastSubmissionId 还用同一 false 表示查询失败和确实无提交，Send 将两者都当可继续新上传。建议区分查询结果状态，优先使用服务支持的原子替换；若无此能力，明确保留恢复材料和失败状态。未核实外部服务是否提供原子替换，也未删除或上传任何内容。

### F11 / P2：Numerai 市场校验不完整

证据：`NumeraiSignalExport.cs:69–73,78–91,145–156`。仅允许 Equity，但映射表只有 USA/SGX，其他市场 Equity 能通过基类校验，随后字典索引抛 KeyNotFoundException。124–127 行按条目数检查“至少十个不同信号”，未检查 symbol 去重。建议先验证支持的市场和唯一标的数量，再开始网络请求。

### F12 / P2：vBase 每次构造重置共享限流器

证据：`Common/Algorithm/Framework/Portfolio/SignalExports/VBaseSignalExport.cs:62,77–102,116–118`。限流器是 static，但每次构造都重新 new RateGate(10, 5分钟)，已有实例也改用新配额；多实例初始化会重置限流历史，旧对象未在本类释放。建议一次初始化共享限流器，或按凭证定义独立限流器生命周期。外部真实配额未核实。

### F13 / P2：货币转换白名单路径跳过空对象保护

证据：`Common/AlgorithmUtils.cs:60–75`。未传白名单时过滤 CurrencyConversion != null；传入白名单时仅按 Symbol 过滤，之后直接访问 CurrencyConversion.ConversionRateSecurities。如果白名单包含尚未建立转换对象的 cash，可能空引用失败。建议两条路径共同检查转换对象，明确基础货币及未初始化 cash 的处理；批外 Cash 生命周期未核对，触发可达性仍待调用方验证。

### F14 / P2：Authentication payload 边界不完整

证据：`Common/Api/Authentication.cs:90–120`。顶层 payload value 为 null 时直接 GetType；非标量一律 JObject.Parse，因此顶层数组会被当对象解析而失败；数组元素为 null 时调用 ToString 也没有保护。标量 ToString 未统一 invariant culture，区域设置可影响 decimal/date 参数。建议规定并验证 payload schema，显式处理 null、数组和格式。当前批次没有调用点覆盖证据，不推断现有请求都受影响。

## 其他静态观察与接续检查

- Insight 有效性只看 CloseTimeUtc，等于关闭时刻仍 active；Expire 将关闭时间设为当前时间减一秒（Insight.cs:133–157），即时取消可能得到负 Period。这是需明确的边界语义，不直接当作交易错误。FuncPeriodSpecification（718–730）不像显式 CloseTime 版本（696–699）拒绝过去时间。
- Insight.Group（427–444）边遍历边赋组号；后续成员已分组时抛异常，前面的成员已被改动。若期望事务式分组，应先全量校验后提交。
- SerializedInsight（164–185）保存分数但没有 UpdatedTimeUtc；FromSerializedInsight（Insight.cs:482–499）以 CloseTimeUtc 恢复评分更新时间。不能把反序列化后的更新时间当作原评分实际计算时刻。
- InsightScore.SetScore（77–95）做 0–1 clamp，但构造器（64–69）直接赋值；NaN 也没有明确拒绝。这里的分数不是用户 EA 综合评分，不应映射为胜率或实盘许可。
- PortfolioTarget.Percent（135–192）核对目标比例、品种、价格及 buying-power 返回错误，并区分总数量/差额数量。163、166 行的总净值和杠杆除数未在本函数明确校验，需批外前置条件；SignalExportManager 的缓冲后净值除数（224）也需要边界核对。
- Collective2 限流器名/注释是 ten seconds，实际参数是 1000ms（100 行）；这里只确认注释与配置差异，不断言当前服务配额。其外汇转换（240–249）先转 int 再除以 10,000，存在截断和整数范围约束，应与单位契约一起验证。
- 多个 export 使用同步 `.Result` 和 WaitToProceed；Flush 同步调用 provider。外部延迟会阻塞此调用链，但本批未读取引擎调度，不声称已经阻断全部交易风控。直接调用 exporter 也没有 manager 的 LiveMode 门控；必须明确唯一出口。
- AlgorithmConfiguration 的参数构造器默认 TradingDaysPerYear=0（102–112），无参为252（124–127），Create 则用设置或252（149–150）；使用者需区分三种路径，当前批未验证统计消费端。
- AlgorithmImports.py 全文是 CLR 程序集加载和便捷导入，90–95 行吞掉科学库导入异常，102–105 行恢复 Python builtin Exception。本次只阅读，没有 import 或加载 DLL。
- AlgorithmSettings 默认值只是平台设置；MaxAbsolutePortfolioTargetPercentage=1,000,000,000（196）不是可套用的账户风险上限。StalePriceTimeSpan 注释不能替代批外 fill model 审核。
- Api/Data.cs 的 RegEx 缓存（108–124）不会随 RawRegEx 修改而失效；GetPrice（78–86）也依赖 Prices/RegEx 非空。应在 API 数据契约和初始化边界补验证。
- Backtest、Compile、LiveAlgorithm 等是响应 DTO：Completed、BuildSuccess、Environment 等字段定义不代表本次有任何运行证据。BacktestSummary.NetProfit 注释是百分比（258–260），不能当 USD 净利润。PSR 注释的业务含义需到生产端核对，当前不以名称或注释替代统计公式。

## 覆盖分组与未发现项

|范围|阅读内容与结论|
|---|---|
|12 个 Alphas 文件|manager、生成集合、评分接口/Python wrapper、Insight 生命周期、集合、枚举和序列化全部读取；发现见 F02–F04 和边界观察。简单接口/枚举未见额外明确缺陷。|
|3 个 Portfolio 文件|目标接口、比例换算、集合及枚举全部读取；发现见 F01、F05。|
|7 个 SignalExports 文件|基类、四家 provider、manager、参数 DTO 全部读取；发现见 F06–F12。未请求任何服务。|
|5 个 Common 顶层文件|配置、Python imports、设置、seed 工具、Analysis DTO 全部读取；发现见 F13 及其他观察。|
|13 个 Api 文件|Account、Authentication/Response、Backtest/Log/Report、BaseOptimization、Compile/State、Data、Estimate、InsightResponse、LiveAlgorithm 全部读取；发现见 F14 及数据契约观察。纯 DTO 未见额外可直接确认的执行缺陷。|

“未见额外缺陷”仅指该批静态阅读，不是正确性证明。全文阅读覆盖 100%，运行验证覆盖 0；后续可在另行允许执行的任务中优先验证 F01、F02、F05、F06，再使用 mock HTTP 验证响应、上传及重试路径。本次不修改源码、不新增或运行这些测试。

## 逐文件 SHA256 与读取行范围

SHA256 为整个源文件的字节哈希；以下范围全部已读。

|文件|已读行|SHA256|
|---|---|---|
|Common/Algorithm/Framework/Alphas/Analysis/InsightManager.cs|1–127|24b7b90c8d725aba5ffd1b7833d34e582bdcc081b8635e9219970b7a4336e89d|
|Common/Algorithm/Framework/Alphas/GeneratedInsightsCollection.cs|1–47|c85f394ee5595a4362f531761fa14eb999d41f2a9a10337947794b3a93a11242|
|Common/Algorithm/Framework/Alphas/IInsightScoreFunction.cs|1–31|041a45866c4823bcedeeaab7cafdceec4d0e81937dfc1c91c8e34c629cdad3eb|
|Common/Algorithm/Framework/Alphas/Insight.cs|1–747|94aa99875e86bfb2efffd8a7994738097be0afb930d6cf638c3cc1601624595f|
|Common/Algorithm/Framework/Alphas/InsightCollection.cs|1–395|ecbadf1b24380c4c24d6383bfaa30bc424669772ec34a4a83450f882c527b503|
|Common/Algorithm/Framework/Alphas/InsightDirection.cs|1–42|622a4302d0d7e0a81944beb421b23b99950b5e8426fa247ae74f03b64da8af2a|
|Common/Algorithm/Framework/Alphas/InsightScore.cs|1–136|bc439037b8f3007c530171dd819bdb5c2493a5b9f39ca3957f4125d19e864442|
|Common/Algorithm/Framework/Alphas/InsightScoreFunctionPythonWrapper.cs|1–45|9c7e428e20668083e0c9b9b0435279988cbf5545fb898af15be23e9aff3855cd|
|Common/Algorithm/Framework/Alphas/InsightScoreType.cs|1–38|03819e72cef2e8d16eb6e0ef95c50638dc825296420237085fecc83a28797ea8|
|Common/Algorithm/Framework/Alphas/InsightType.cs|1–37|2a7dc2693e6cd0083979a23a2af4840d0441de5807bc31c5414b9aca74b3314b|
|Common/Algorithm/Framework/Alphas/Serialization/InsightJsonConverter.cs|1–46|653e43186f387a25496029d281b8a3318f161c39c3d12d407ebe86acfd975a76|
|Common/Algorithm/Framework/Alphas/Serialization/SerializedInsight.cs|1–292|269596e83603b904b03b6fe6469a4d04444b9938ef29da2a9a63822a25fa641c|
|Common/Algorithm/Framework/Portfolio/IPortfolioTarget.cs|1–39|c3195ac184ed2ccda4d3007ee70f28574a2a2fd49903e25b3b3285ac8b01f197|
|Common/Algorithm/Framework/Portfolio/PortfolioTarget.cs|1–203|4c086d048f7da162e7ad1158c8527407c1286683ad3f35ce405b88213408687e|
|Common/Algorithm/Framework/Portfolio/PortfolioTargetCollection.cs|1–435|2a2d88c477bfd6fd2906ef97aeb8bcef9bcf122a5d742593d2a8787bb13594f6|
|Common/Algorithm/Framework/Portfolio/SignalExports/BaseSignalExport.cs|1–115|a50276a05af420ba3c64bce18785f5eaa4b8c9e3f91b4ec03e91716e85968f85|
|Common/Algorithm/Framework/Portfolio/SignalExports/Collective2SignalExport.cs|1–639|33108d31d9aa08b77b7d2835800d29952ef87fe94bd10c39872247d845051ae7|
|Common/Algorithm/Framework/Portfolio/SignalExports/CrunchDAOSignalExport.cs|1–290|bdf7d6914371022b29597dd1e8138ea920100ef6b88da00bf06fba6734414d90|
|Common/Algorithm/Framework/Portfolio/SignalExports/NumeraiSignalExport.cs|1–281|855e415d858ffb1e871f9620d42169805b19fa4f2719f79cb376c9c145061c29|
|Common/Algorithm/Framework/Portfolio/SignalExports/SignalExportManager.cs|1–276|6899cb179959f977fe2673d73cae8aa73d8ecdca2b2003b37f52e243a5308417|
|Common/Algorithm/Framework/Portfolio/SignalExports/SignalExportTargetParameters.cs|1–36|54d409cf45b560c2ff38526a455f2a6b22dd45db8e850708e9a2fb43d2e4477e|
|Common/Algorithm/Framework/Portfolio/SignalExports/VBaseSignalExport.cs|1–178|d8edd204a2de96b535fb0b0be44907b4b12af877fa24f941319dc99a61375be4|
|Common/AlgorithmConfiguration.cs|1–155|258732199cc690811144f80880fda6daea689b9b03620ad359aac843d45a8a6a|
|Common/AlgorithmImports.py|1–108|2dca131d98dec2894be51e870abc66422e81e24b01cb5369f2a9877e9772b371|
|Common/AlgorithmSettings.cs|1–203|76bce8783cdb8ca9d38e1b49c6d3c1ed1f6d990fc12eb5ec22ede8914dd12585|
|Common/AlgorithmUtils.cs|1–85|2de7abf4fbd29847f5c5699f26b83c3c0f67809d45ac58edaebf297e9e1b9718|
|Common/Analysis.cs|1–57|664119e1935d888a544c45fe8d86189fb9e4877e98a310c32ab364f280e74746|
|Common/Api/Account.cs|1–64|8be1db6b4a3458d12ba1d471ccd5269ff433035dbdec3a7fdeb72c0aff006c4d|
|Common/Api/Authentication.cs|1–126|a7b28ea60543bf18ad85cc3d34cf26e4f43185e210afbb8d0953df1573e64355|
|Common/Api/AuthenticationResponse.cs|1–24|cc5480cdc7197669d87a6fe594c8a87b7f299e0c536760330e0953726e0107fe|
|Common/Api/Backtest.cs|1–357|6522a07636388ad56b19a5cc564d63125731120e35ccabedc620b79b31baba39|
|Common/Api/BacktestLog.cs|1–35|8896030b6fec774fe47a161e3cb38cf87b9a43c052cca6f43b09c94cbe1ff33f|
|Common/Api/BacktestReport.cs|1–34|c363a5729642b6bbec18fcdb30f7fffd85aa33cd396cd5e87b9f997084e80a2e|
|Common/Api/BaseOptimization.cs|1–113|81ff1cafd1c0090f8d966fe6a0bdcdd4ad99889a84734b7c27f3f34fbe1ff4ef|
|Common/Api/Compile.cs|1–58|a3ed2594b1a2bf61de5e21fde7346946ede98f2a96602c7229e792665ad9c923|
|Common/Api/CompileState.cs|1–37|c4dbffb10441a3369f11d6dbc9f0e02e907e50f481f12d63c2a6f1e638ed5bb6|
|Common/Api/Data.cs|1–151|9dd3bd51e5b421eba027b3e8c26f432ef89a22cd7c75335ec48934c583dd6857|
|Common/Api/Estimate.cs|1–52|85f689b7cce57e373cd9b114e7347c0072fe524be174f35c92ee4b4f5307b89e|
|Common/Api/InsightResponse.cs|1–36|025e9d185970082df4037dca457c599b48305224fed6f4e397d51a0582b91854|
|Common/Api/LiveAlgorithm.cs|1–129|f1c236733b902244ce6482242063f01067a33f7bfeb7e29ef39b2a40b1e7fe1d|
