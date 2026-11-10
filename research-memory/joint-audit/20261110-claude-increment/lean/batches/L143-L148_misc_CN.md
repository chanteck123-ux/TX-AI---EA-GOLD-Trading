# L143–L148 LEAN 小目录收尾（Claude，2026-11-09）

## 范围
- 代码批次 M1–M7（`misc_code.txt` 共 210 个 .cs/.py）：Api、Brokerages、Compression、Configuration、AlgorithmFactory、DownloaderDataProvider、Launcher、Logging、Messaging、Optimizer(.Launcher)、Queues、Report、Research、ToolBox、run_benchmarks.py、run_syntax_check.py。
  - 方法：`CAT_N_CODE_EXCL_LICENSE_BLANK_USINGS_XMLDOC`。
  - 批次：L143（M1、M2）、L144（M3、M4）、L145（M5）、L146（M6）、L147（M7）。
- 非代码文件 87 个（批次 L148）：
  - FULL_READ（方法 `CAT_N_FULL_TEXT`）包括：
    - csproj、sln、DotSettings；
    - CI workflow、.travis.yml、Dockerfile ×4、.devcontainer、.vscode、.vs；
    - 各 readme、CONTRIBUTING、LICENSE；
    - Launcher/config.json 及各 config.example.json；
    - Report 的 css 和 template.html；
    - Research 的 ipynb ×4、csx、docker.cfg；
    - blacklisted-tickers.txt、mypy.ini、.gitignore 等。
  - IMAGE_VIEWED：Documentation 下 7 张架构图和 logo。
  - DATA_AUDITED：AlgoSeek.US.Futures.PriceMultipliers.1.1.csv。共 264 行；262 行为 4 列，另有 1 行 3 列、1 行 5 列异常；GC 和 MGC 的乘数为 10。
  - 未打开：lean.ico 记为 UNREAD，方法 BINARY_METHOD_ONLY。
- **结果：除 Common、Tests、Data 三个目录外，LEAN 全部完成。UNREAD 3,484**（Common 1,972、Tests 859、Data 652，另有 lean.ico 1 个）。

## 凭据处理
- Launcher/config.json 中的全部 token、password、key 字段都为空字符串。用正则核对过，没有长度 ≥6 的非空值。
- CI 只引用 `${{ secrets.* }}` 变量名，不含实际值。
- 本笔记没有转录任何凭据。

## 发现（第 4 层，大多与 V1.2 执行无关）
1. **Optimizer**
   - 默认的 Euler 和 Grid 策略按 Target（示例为 Sharpe）择优；约束只做丢弃。
   - OptimizationModes 和 Slicing 分析都以 Sharpe 为唯一维度，k-means 种子固定为 42。
   - **V1.2 参数寻优若使用 LEAN Optimizer，不能只看 Sharpe**：须按 §11.1 和 §13.10 的评分口径另行排序。这一点也计入过拟合试验次数。
2. **Report**
   - PortfolioLooper 用订单价格重建组合：手续费为零，杠杆设为 10,000。因此 Report 中的杠杆和敞口图是近似值。
   - 年度和月度收益只在同一年（月）内用 TotalReturns 复利计算，跨期第一段收益不计入。
   - TradesPerDay 是订单数除以日历天数，不是成交笔数。
   - 实盘 Sharpe 和 PSR 取最近 180 天并排除周末。
   - Report 不能替代 §11.1 的成绩评估。
3. **QuantBook.GetPortfolioStatistics** 把权益曲线的 pct_change 当作 profitLoss 传入，所以 "Win Rate" 统计的是收益为正的时点比例，不是交易胜率。
4. **安全与供应链**
   - DockerfileJupyter 让 Jupyter 监听 0.0.0.0，token 为空，开启 `--allow-root`，并对工作目录执行 `chmod 777`；`.vscode/launch_research.sh` 也是无 token。端口一旦暴露，就是未经认证的代码执行入口。
   - DockerfileLeanFoundation 从 cdn.quantconnect.com 等地址下载多个 zip 和安装脚本，除 tini 外都没有校验和。
   - 本轮只阅读，未运行。
5. **ToolBox 小缺陷**（不影响 V1.2）
   - RandomDataGenerator 在每个 aggregator 的循环里都执行一次 `tick.Value /= FinalSplitFactor`，有多个 aggregator 时会重复相除。
   - `RandomValueGenerator.NextDate` 中 `_random.Next(0,1)` 恒为 0，所以总是取前一个星期几。
   - `DataProcessor.Zip` 对 Cfd/Forex 使用 TickConsolidator，即把报价 tick 当成交合成。
6. **JobQueue / Launcher**
   - 回测参数取自 config 的 `parameters`。
   - `close-automatically` 为 false 时会等待按键。
   - 研究端 QuantBook 的起始时间在纽约 9 点之前取前一日（可由 `qb-data-hour` 配置）。
7. **Report template**：模板含有 ReportKey 中未定义的 `{{$KPI-LIVE-*}}` 占位符，靠 CSS 隐藏；策略名、描述和参数没有经过 HTML 转义。

## 待汇总
新增 R48（见 Codex 复核请求的 L143–L148 补充）：Optimizer 和 Report 指标口径、QuantBook 胜率口径、Jupyter 容器无认证。
