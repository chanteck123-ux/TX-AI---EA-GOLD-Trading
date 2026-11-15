# QuantSkills 全量审核：缺口、风险与未执行项（Claude，2026-11-06）

本文件只汇总审核中发现的问题和尚未覆盖的范围，各项细节见 `assets/A###.md` 与 `assets/HUB.md`。凡写"PLAUSIBLE"的项目，表示只从文档推断，尚未对照源码核实。第五点五节和第一节中的源码层内容是 2026-11-06 晚的更新，若与前文冲突，以源码层更正为准。

## 一、覆盖范围与未执行项
- 文档类（.md/.txt）全部已覆盖：
  - plan_main 中 FULL 类 2,103 个分段，全部读完；
  - HASH_REUSE 类 128 个，哈希与原件逐一核对，全部一致；
  - 两个因子库共 2,336 份文档，按 TEMPLATE_DIFF 方法覆盖，见 `coverage/template_diff/`。
  - 各文件的方法细分（DATA_AUDITED、DIFF_VERIFIED 等）见 `coverage/method_overrides_quantskills_CN.csv`。
- **源码层（2026-11-06 晚更新，逐文件清单 `coverage/qs_source_inventory.csv`，11,223 个文件）**：
  - FULL_READ 2,159；DIFF_VERIFIED 4,086；DATA_AUDITED 586；HASH_REUSE 152；PARTIAL 6；VENDORED_NOT_REVIEWED 1；**UNREAD 4,233**。
  - 文档层覆盖已按"路径加 SHA-256"映射进清单，4,521 条全部一致，没有 SHA 不匹配（`coverage/doc_sync_report.txt`）。
  - 源码批次 S001–S013 已完成：先核实 PLAUSIBLE 资产，即 A207、A198、A208、A211、A212、A203、A204、A210、A213、A195、A215；两个因子库共 1,168 个 .py 用模板比对完成；1,168 个 json/yaml 做了数据审计和模板比对。
  - **仍未审**：CODE 2,432 个（28.4 MB，主要在 agent-quantspace、agent-future-trading、skill-dl-tcn-shortterm 等），TEXT 1,473 个，DATA 160 个，BINARY 148 个（只记录检查方法，不计为已读），OTHER 20 个。
  - A194、A201 没有任何源码，A215 只有一个格式检查器，这三个资产的 PLAUSIBLE 项无法由源码核实，维持 PLAUSIBLE。
  - 全部示例、测试和脚本**都没有运行**。
- 外部事实没有联网核实，例如 A214 中 13D 申报时限是否已改为 5 个工作日、A199 中某 ADR 的上市日期。

## 二、凭证与传输安全（禁止执行，需要用户知悉）
| 资产 | 问题 |
|---|---|
| A140 | SKILL.md 中有**明文 PandaData 凭证**（未转录）。registry 的 secrets 正则检测不到这类格式（见 HUB） |
| A158 | SDK 把凭证持久化到 user.json；SKILL 提供明文 env 选项 |
| A170 | 通过 http 明文传输凭证 |
| A196、A197 | 由 Agent 收集俱乐部账号密码和 SIMNOW 密码，**明文写入** trading_config.py |
| A207 | 凭证可以通过命令行参数传入；base_url 是 http；v1.5 说明暗示此前版本曾随包分发凭证 |
| A217 | 借用本地已登录的浏览器，开放 CDP 调试端口抓取数据；RSS 采集有 `--allow-insecure` 选项；token 可以通过命令行传入 |
| A218 | 用户的图片和查询发往硬编码的第三方服务器；要求 Agent 隐藏 `System (untrusted)` 标签 |
| A210 | 文档对"默认是否调用外部 LLM 网关"说法矛盾，并称会写 `~/.claude/skills/...`。**源码核实（S008）：代码中没有外部 LLM 调用，也没有这类写入，属于文档描述未实现**。但用户提供的 `.py` 策略文件会被 `exec_module` 直接执行 |
| 多个资产 | 用手机号加密码作账号，用 `pip install --upgrade` 安装且不钉定版本，需要安装来源不明的 wheel（A209） |
| registry | 提供 `/plugin marketplace add quantskills/registry`，**可一键安装全部 218 个资产，不建议添加** |

## 三、个人信息与真实人物
- 以真实交易员、投资人或博主命名并复刻其方法的资产是一个成批生产的系列：A189、A217、registry 的 `<TRADER_NAME>` 免责模板、名字中带人名的 14 个资产。
- INDEX 和 llms.txt 中有一条简介**直接写出一位真实博主的昵称，并称其为"反向指标"**。
- 文档中出现的维护者 GitHub handle、本机路径、示例中的真实账户名，本审核**一律未转录**。

## 四、反复出现的方法学缺陷（V1.2 应作为反例写进测试和规则）
1. **PIT 和前视**：宏观数据不是 PIT（A158）；胜率以龙虎榜当天 T 日的收盘价为基准（A194）；以评估期末状态反推（A164）；确认窗口可能用到未来数据（A213）；当前行业分类、当前成分股、只取在市股票（A193、A201、A215）。
2. **复权和换月**：直接用未复权价格（A158 的 get_stock_daily，A163、A165、A182、A194、A207、A215）；主力连续合约不做调整（A160、A208）；用主力合约兜底标记价格（A210）。
3. **统计口径错误**：
   - 协整检验用普通 ADF 临界值，而不是 EG 临界值（A198、A208）；
   - 重叠收益让 Hurst 和 ICIR 虚高（A208，以及 A173 和 A174 的 ICIR 被放大约 7.1 倍）；
   - 年化时 252 个交易日配自然日数（A203）；
   - Sortino 的分母不是标准下行偏差（A203）；
   - Jaccard 换手代理系统性高估（A192）；
   - IS 五项分解重复计算了冲击和点差（A211）；
   - 线性和平方根冲击的大小关系说反了（A202）。
4. **挑选结果和多重检验**：
   - 回测端日决定 IC 的正负，选定端日后又声称"未挑窗口"（A207）；
   - 看过样本外结果之后再翻转因子方向（A207）；
   - 用已知结果调整阈值（A195）；
   - 584 个因子全部 pass，没有任何多重检验校正（A173、A174）；
   - 默认参数配合自动运行，导致试验数无法统计（A209）。
5. **"验证"造假或名不副实**：
   - V1 的 validate 和 backtest 用随机数生成"PASS"（A207）；
   - 自定义的 pass 门槛不透明（A175、A216）；
   - 对账检查是同义反复（A158、A203、A211）；
   - golden 测试把乱码当作期望输出固化（hub）；
   - health 检查 218/218 只验证格式（hub）。
6. **执行与风控（直接影响 RiskExecution 契约）**，均出自 A196：
   - 仓位计算结果被强制取至少 1 手，导致超出风险预算；
   - 取不到账户数据时风控层被跳过（fail-open），还用 50 万作为默认权益；
   - 保证金占用超过 70% 时并不真正阻止开仓；
   - 进程重启前不做对账；
   - 入场价错记成 next_bar_open 下单前的收盘价。

   另外，A210 在取不到标记价格时把浮盈亏记为 0。
7. **静默回退与默认值**：回退到样本或合成数据（A167、A204、A211）；短历史时静默回到 50 分位（A195）；用默认值把参数补齐后继续运行（A209）。
8. **文档自相矛盾**：A195（阶段数、质押口径）、A199（分数区间）、A200（两套阈值来源、样例计算错误）、A207（中英文 README 描述的模型不同，两份交接文档版本不同）、A215（时区依据错误）。

## 五、可直接借鉴的做法（仍须在 V1.2 中自行实现并测试）
- A172、A176：超时不等于拒单、幂等、故障安全、根据实际持仓生成交易；
- A177、A178：统计验证规范、证据登记；
- A193：只用形成期选样，FDR 多重检验校正，门控未通过时隐藏方向；
- A198：检查双向失败模式，t 值按持有期重叠折减；
- A199：一手数据新鲜度门禁，旧数据须经一次性显式授权，沉默不算授权；
- A205：缺失的退市收益不得填 0；
- A210：证据键必须可定位，LLM 不得改写数值；
- A212：成交前 as-of 对齐，不得超出观测范围外推；
- A214：每条记录有来源 ID，申报日与事件日分开；
- registry：只读最小权限，audit 与 enforce 分开，失败时保留上一份完整快照，合并须经用户明确同意。

## 五点五、源码层更正与新发现（S001–S013，细节见各 A### 的"源码批次"段）
- **撤回或更正文档层结论**：
  - A198 实际使用后复权（hfq），"未复权"一项撤回；
  - A212 总成本 = 滑点 + 佣金，不存在重复计算，撤回；
  - A211 样本回退由 `backend` 字段标出；
  - A204 文档层称其"下行偏差标准"，但代码只对负收益期取均值，**与 glossary 不一致**；
  - A210 不存在外部 LLM 调用，也不写 `~/.claude`；
  - A213 压力线方向和外推是正确的，**没有前视**，问题是信号条件比文档更严；
  - A173 和 A174 的 ICIR 倍数约为 7.0992957397，与 √(252/5) 一致；7.099 是三位小数的近似值。生成器没有取得，所以"按此年化"属于推断（2026-11-07 依据 Codex Q16 更正）。
- **源码新发现（CONFIRMED）**：
  - A203：**date 值完全相同**的多笔成交会导致 DataFrame 长度不一致，直接崩溃；同一天但日内时间戳不同的成交不一定触发（依据 Codex Q14 收窄）；
  - A204：回撤峰值日期取成 `index[-2]`；缺失日被删除后，跨缺口收益被当作一期；pandas 版本下限与 `ME/YE` 别名不符；
  - A210：regime 波动阈值的单位错误（0.30 对应的是百分数），机制上会过度判为 high_vol，实际频率未验证（PLAUSIBLE）；期货顺逆势拿股票大盘判断；基差绝对值与比率混用；按区间末日状态评判全部交易（后见之明）；全胜时 PF 为 None，被当作 1.0；未知期货品种乘数静默取 1；
  - A195：CogF 用 `shift(-2)`、ParF 用 `shift(-10)`，历史 score 曲线因此有前视；loop_type 由末行决定后套用到整段历史，历史 stage 序列也依赖末日（Codex Q13.6，已回源码确认）；显式 as_of 截断后，末行不会读取截止日之后的数据，但这只是局部边界，端到端 PIT 未得到证明；后复权价按行用不复权价兜底；质押数据缺失时记 0，按"不脆弱"放行（fail-open）；
  - A173、A174：584 个因子是 24 种 base × 8 种 transform × 3 种窗口的网格，另加 8 个；`**params` 被忽略；成交量类 base 一个也没用；validate.py 只做合成数据的结构检查。
- **对 V1.2 RiskExecution 的反例用例**：
  - 标记价格必须来自同一合约；
  - 未知合约乘数必须阻断；
  - 缺失的风险数据不能默认为安全值；
  - "评估用"的未来收益不能进入任何展示或回溯序列；
  - 同一时刻多笔成交必须能正确汇总。

## 六、待 Codex 交叉复核
- **2026-11-07：Codex 已完成 Q11–Q16 的静态复核**，结果在 `codex/recheck-20261106/`。Claude 的回执见 `CLAUDE_RECEIPT_Q11_Q16_CODEX_RECHECK_20261107_CN.md`：在各项限定下双方意见一致，但只限静态层面，未做运行验证，也未修复。**Q1–Q10 尚未复核，不关闭。**
- 本文件和各 A### 笔记中的新发现，须由 Codex 对照原文复核：特别是 A173 和 A174 的 ICIR 年化、A207 的 EP 公式、A211 的重复计算、hub 中 golden 乱码和 secrets 正则的覆盖范围。
- **在完成交叉复核之前，不得标为"双方完成"。**

## 七、2026-11-07 源码批次 S014–S016 摘要（agent-future-trading，详见 A010）
- **CONFIRMED 的问题**：
  - 授权一致性检查实际不起作用；
  - 两条执行路径对紧急状态的处理语义不一致；
  - 手续费、滑点、涨跌停检查和到期保护在缺数据时默认放行或按 0 计；
  - 强平回退价取的是当日收盘价，却标注为 T−1，存在前视风险；
  - 平今判定被持仓均价合并后的日期带偏；
  - 盘中权益不含浮动盈亏。
- **可借鉴的做法**：减仓优先、强平先于策略、新开仓需要授权、数据缺失时改为 HOLD、结算阶段幂等、防止混用合约。
- 以上只来自静态阅读，**等待 Codex 复核**。

## 八、2026-11-07 第 2 层数据核对 S-DATA1（按用户选定的"分层完成"标准）
- **范围**：QuantSkills 中全部状态为 UNREAD 的 `.csv` 和 `.jsonl`，共 160 个文件，**1,941,509 行**，全部记为 DATA_AUDITED（方法：STRUCTURAL_ALL_ROWS）。
- **方法**：使用工具 `lean-full-review-20261101/claude/tools/audit_text_data.ps1`，只读，逐行解析。CSV 统计行数、列数分布、空字段数、数值字段占比和第一列字典序；JSONL 逐行解析，结果是全部解析成功。明细见 `coverage/qs_data_audit.csv`，不转录数据内容（registry 中的 jsonl 可能含有个人信息，只记录统计数字）。
- **限制**：CSV 按逗号直接切分，**没有处理带引号的字段**。所以有 20 个文件的列数不一致，可能只是引号造成的假象，未逐一确认。另有 144 个文件第一列非递增，同样只作为结构信息，不作为错误结论。
- **这一层审计不代表数据的口径或来源已经验证**，例如有无前视、是否复权，这些仍以各资产 A### 笔记中的源码审核为准。

## 九、2026-11-07 源码批次 S018 摘要（agent-future-trading 结算与盘中执行，详见 A010）
- **CONFIRMED 的问题**：
  - 结算分多步写库，没有事务；中断后重跑会以当天已结算的持仓为基准，把同一批成交再记一次；
  - 读取成交出错时返回空列表，被当成"当天无成交"；
  - 三条账务恒等式在构造上必然成立，检查不起作用；
  - 保护性平仓可能因成交量过滤或行情异常而不执行；
  - 带时区的 valid_until 被直接去掉时区；
  - 坏的 invalidation_level 会被当成 0，导致空单被强制平仓。
- **PLAUSIBLE**：15 分钟信号 K 线如果用开始时间做时间戳，就会提前用到收盘价（需要确认数据商的约定）。
- **可借鉴的做法**：缺结算价或合约信息时直接中止；平仓超过持仓时报错；同一 ticker 下不允许混用多个合约；涨跌停审计。
- 以上只来自静态阅读，**等待 Codex 复核**。

## 十、2026-11-07 源码批次 S019 摘要（agent-future-trading PM 风险门，详见 A010）
- **CONFIRMED**：
  - 风险门自己产生的所有阻断原因都被归为软限制，最后一律改成 25% 仓位的试探单，日志里写的"blocked"和实际执行不一致；
  - 缺少分析师信号或市场确认时直接放行；
  - 只有新闻支持、或者没有任何分析师支持时，仍可开 50% 仓位，hard_failures 只写进 notes；
  - "受保护的品种方向"在样本不足时也生效，拒绝分支实际是死代码；
  - 无法识别的决策值默认放行。
- **可借鉴的做法**：风险门只作用于新开仓、加仓和反手，不挡减仓；原因分类有统一的 taxonomy；每次判断都留审计 payload。
- 以上只来自静态阅读，**等待 Codex 复核**。

## 十一、2026-11-07 源码批次 S020 摘要（trader.py 补完，详见 A010）
- **CONFIRMED**：
  - PM 合约与当前持仓不一致时一律 HOLD，连平仓也会被挡住；
  - 正常策略单不经过 Trader 的平仓策略和 EMERGENCY 清仓；
  - Auditor 未批准或缺执行基准价时，整条建议跳过，其中的减仓也一起跳过；
  - 原始动作路径把保证金比例当成名义金额比例使用。
- **PLAUSIBLE**：Phase2 失败后重跑以前一天的结算持仓为起点，不含当日已成交。
- **可借鉴的做法**：强平先于换月，换月先于策略；反手分两步执行，第二步按更新后的持仓重新翻译。
- 以上只来自静态阅读，**等待 Codex 复核**。

## 十二、2026-11-07 源码批次 S021 摘要（portfolio_manager.py 风险函数，PARTIAL，详见 A010）
- **CONFIRMED**：
  - 开仓两天内的冷静期会挡住主动减仓、平仓和反手，而亏损阈值只看当日相对结算价的变动；
  - 缺少初始资金配置时风险等级判为 SAFE；
  - DANGER 时仍允许在已有持仓上加仓；
  - 学习机制能抬高净敞口上限；
  - 风控相关的读库失败在放行和阻断之间处理不一致；
  - 价格合理性检查在缺参考价时照样放行。
- **可借鉴的做法**：回撤达到硬阈值后先冷却，再小仓试探，按连续盈利逐步恢复，试探亏损后递增冷却（与 V1.2 DR01 思路相近）。
- 这个文件只读了约 1,150 / 13,790 行，**其余部分仍未读**；以上结论等待 Codex 复核。

## 十三、2026-11-07 源码批次 S022 摘要（b11 止盈止损、b12 日内仓位，详见 A032/A033）
- **b11 CONFIRMED**：
  - 文档层的三条结论在源码中得到确认：坏数据时 hold、只在开盘价上判断止盈止损、超限时静默保留；
  - 批量运行时一条坏记录会让整批停下，未知乘数也会中断后续持仓的止损；
  - 交易日历是进程内单例，可能让后续持仓的持有天数算少；
  - 只支持多头。
- **b12 CONFIRMED**：
  - 任何一条记录不在交易时段，整批就会停下，夜盘一定报错；
  - 砍半和加仓规则不记状态，轮询时会反复触发；
  - 默认没有加仓上限；
  - 无法识别的品种浮亏也 hold。
- **可借鉴的做法**：合约乘数查不到时报错；日历文件原子写入；T+1 锁仓的处理；拒绝 NaN、inf 和 bool；结构化的 flags。
- 两个技能的 test.py 仍未读，属于第 3 层；以上结论**等待 Codex 复核**。

## 十四、2026-11-13 源码批次 S023 摘要（全仓小配置文件，只读，未运行）
- **范围**：全部 UNREAD 的 .gitignore（172）、.gitattributes（35）、.env.example（29）、pyproject 等 .toml（19）、.ini（3）、.python-version（4）、uv.lock（5），以及无扩展名文件（LICENSE 211、NOTICE 1、名为“1”的杂散文件 1），共 480 个。
- **方法**：
  - 按 SHA-256 去重后逐个全文读：首个副本标 FULL_READ（方法 SMALL_CONFIG_DEDUP_READ），其余同哈希副本标 HASH_REUSE；
  - 20 KB 以上的 GPLv3 全文共 190 份，与规范副本做空白归一比较，标 DIFF_VERIFIED（方法 LICENSE_NORMALIZED_COMPARE）；
  - 5 个 uv.lock 只审计结构，标 DATA_AUDITED（方法 LOCKFILE_STRUCTURE_AUDIT）：
    - 格式都是 lock v1 rev3；
    - 4 个只用 pypi.org；skill-futures-investment-council 用清华 PyPI 镜像（97 处），供应链来源与其余仓不同；
    - 包数分别为 193、23、44、58、46，都有 sha256 哈希；
    - 没有逐个核对包的版本。
- **LICENSE 异常**（法律效力不由本审核判定）：
  - skill-causal-alpha-discovery 少了约 604 词，即“entity transaction”一段；
  - skill-guarantee-risk-scan 缺 Corresponding Source 一句和 show w/c 一段；
  - skill-audit-opinion-scanner 文中写的是另一个程序名（b12-intraday-position-manager），属复制粘贴错误；
  - skill-quant-execution-microstructure 把 “obligate” 写成 “oblige”；
  - market-risk-radar 用了弯引号；factor-optimize 用了 http 链接；
  - 多个仓只放了简短的 GPL 声明或 SPDX 存根，没有全文。其中 skill-trade-review 自己注明发布前要换成完整文本，skill-llm-alpha-generator 只有一句话；
  - 声明为 MIT 的仓：earnings-surprise-hunter、agent-ssquant、dalio-all-weather、simons-pairs-trading、ml-purged-cv、hk-stock-dossier（只在 pyproject 中声明）、post-market-screener（只在 pyproject 中声明）；
  - factor-mining-pandaai 的 NOTICE 保留了上游 MIT 声明，整体按 GPL-3.0-only 发布。
- **凭证与传输**（未转录任何值）：
  - 所有 .env.example 只有占位符，没有发现真实密钥；
  - agent-future-trading 的 .env.example 把当前在用的 LLM 网关设为**明文 HTTP 加裸公网 IP**（地址未转录）；
  - 多个仓的 PandaData 地址是 http 明文，例如 factor-loop-evolve，账号密码随之明文传输；
  - simons-pairs-trading 与 dalio-all-weather 的 .env.example 明确拒绝 HTTP，并禁用 user.json 持久化，是正面做法；
  - northbound-margin-monitor 与 post-market-screener 的注释里有一个完整的示例手机号（未转录），属个人信息外露风险；
  - news-sentiment-analyst 要求在 .env 中保存手机号和密码。
- **其他**：
  - skill-backtest-assumption-check 有一个名为“1”的杂散文件；
  - b11 的 .gitignore 有重复行；
  - hk-us-consensus-revision-radar 的 .gitignore 有一行是未展开的 PowerShell 变量，脚本写坏后的残留；
  - northbound-margin-monitor 的 pyproject 用了不常见的 setuptools 后端 `setuptools.backends._legacy:_Backend`，能否构建未验证；
  - 依赖固定程度差别大：dalio、simons 精确固定版本，多数仓只写下限。
- **V1.2 关系**：只涉及供应链和凭证卫生，与交易逻辑无关；属第 4 层。以上结论**等待 Codex 复核**。

## 十五、2026-11-13 源码批次 S024 摘要（quantskills 目录站点与全部图片，只读，未运行）
- **范围**：
  - quantskills 目录仓的 33 个代码、工作流和测试文件：FULL_READ；
  - 2 个目录快照：DATA_AUDITED；
  - 全仓 78 张 png/jpg：逐张查看，标 IMAGE_VIEWED；
  - 4 个 svg：FULL_READ，未发现脚本。
  - 逐图观察见 `coverage/S024_image_observations_CN.txt`。
- **目录站点代码**：
  - 构建先暂存再提升，失败可回滚；快照用自哈希防篡改，评分只用于 Shadow 模式；前端只用 textContent，有 XSS 测试；做法规范。
  - daily-build 工作流的问题：
    - 把 dispatch 输入 `snapshot_url` 直接插进 shell，有触发权限的人可以注入命令；
    - 期望 ID 与下载地址由同一个调用者提供，没有独立的信任锚。
  - Actions 只固定到 tag，没有固定到 SHA；deploy-pages 检出 registry 时未固定版本。
- **目录数据**：
  - site/catalog.json 共 218 个资产，217 个是 pending-maintainer，**只有 1 个接口已发布**，兼容边为 0，可见接口契约体系实际几乎没有落地；
  - **所有资产一律标 GPL-3.0-only**，与多个仓库自己声明的 MIT 冲突；
  - Shadow 评分覆盖 212 个，推荐 28 个。
- **图片中的问题**：
  - 封面卡片是 AI 生成的宣传图，大量照抄模板：至少 7 张卡的右栏流程或主体内容属于别的技能；
  - **skill-quant-factor-skill-factory.png 的内容其实是 pandadata-api 的卡片**；
  - crowding 卡写着“GitHub Star 40K+”，无法核实且明显夸大；
  - factor-evaluate 卡上的评分公式权重合计 1.2；
  - 封面图不能用作功能说明。
- **数据质量与结果**：
  - skew 监控的 IV 被截在 100，所谓“Top IV”全是被截断的值，排名没有意义；
  - correlation-break 的打分把自相关（等于 1）也算进去了；
  - quantspace 的 4 张示例净值图：收益集中在 2024-09 单次行情；样本末端回撤持续扩大；XGBoost 三重障碍的交易极少；
  - buffett 的 V9.1 和 V9.4 两张图曲线一致；“2010 固定经典名单 8.5 倍”和“美股固定池 5.3 倍”是事后选出的名单，存在严重的幸存者/前视偏差，只能当诊断看；
  - backtesting-bias 示例图样本末端回撤约 -49%；
  - time-series 图的横轴误标为 close；IF 主力收益明显右偏，有跳跃。
- **隐私、版权与归属**：
  - agent-quantspace 提交了一张个人微信二维码，带照片、昵称和城市（未转录）；
  - xingtai-catcher 首页有一句**冠名真实政治人物的伪造或误植引语**，“细致分析”会生成交易计划，与“仅供研究”相矛盾；
  - factormad 的流程图疑似直接取自论文；
  - gaetano、serenity、gao-shanwen 使用真实机构或人物的姓名与风格，有署名与人设风险；
  - .github 的图标标志与第三方品牌相似（不作法律判定）。
- **ssquant-ai-trader** 要求把账户和密码明文写进 trading_config.py，并支持全自动运行加定时任务；目前在 SIMNOW 上运行，可以改成实盘。
- **可借鉴**：factor-grouped-wrapper 用验证 IC 选因子，冻结后再一次性跑 OOS，生成 `frozen_selection.json` 之前 OOS 保持封存；factor-debug 的“危险信号阈值”可作为泄漏告警。
- 第 3/4 层；以上结论**等待 Codex 复核**。

## 十六、2026-11-13 源码批次 S025 摘要（agents/cursor-rule.mdc 172 个 + agents/openai.yaml 190 个，只读）
- **方法**：
  - 文件中出现的仓库名统一替换成占位符后再比较；
  - 在 15 个以上文件中出现的公共行只读一次；
  - 每个文件独有的行逐行读完。
  - 因此这 362 个文件全部按 FULL_READ 计入，方法记为 COMMON_LINE_FACTORED_READ。
- **作用范围过宽**：quant-execution-microstructure、quant-portfolio-risk、quant-research 三个规则设了 `alwaysApply: true`，安装后会注入每一个 Cursor 会话。
- **凭证**：
  - cb-analyzer、northbound-margin-monitor、post-market-screener 三处的 MCP 示例把 Anthropic 兼容的 token、手机号格式的账号和密码占位符直接放在 env 里，示例值均为占位符；
  - material-contract-alpha 的 openai.yaml 把 PandaData 地址写成 http 明文，并输出 buy/sell/hold 信号；
  - csrc、guarantee、material 等多个技能要求用户名和密码放在环境变量里。
- **与“仅研究”定位矛盾的内容**：
  - investment-decision 输出 BUY/NEUTRAL/SELL 加“置信概率”，并声称所有字段都能填满（no N/A），实际是在鼓励编造；
  - oil-brief 包含交易计划和价格预测；
  - factor-loop-evolve 在没有目标时自己编 5–15 个因子并以 Sharpe 最大化为目标，过拟合风险高；
  - post-market-screener 对全市场约 5,189 只股票逐只做 LLM 分析。
- **口径不一致**：
  - factor-debug 的 IC 危险阈值在 cursor 文件里是 0.15，在 openai 文件里是 0.20；
  - “val/train IC ≥95% 几乎一定是未来函数”这个经验规则不成立，稳健因子的比值同样可能接近 1；
  - factor-evaluate 的权重合计为 1.2，与 S024 封面图一致，已确认是规则本身的问题，不只是图上写错。
- **模板残留与其他异常**：
  - templeton 的 name 仍是 `my-skill-name`；
  - buffett 的 default_prompt 引用了 `$build-Q44`，与技能名不一致；
  - fundamental-factor-analysis 的 openai.yaml 是意大利语写的；
  - alpha191 的显示名写着 Alpha158，与内容不符；
  - market-regime-analysis 写死了 gpt-4o，material 写死了 gpt-4；
  - feng-reverse 以一位真实微博博主的帖子为反向指标，有人设和名誉风险（未转录其名）。
- **可借鉴（统一的研究规范）**：
  - forward return 统一按 `open.shift(-1).pct_change(H).shift(-H)` 计算，即 T+1 开盘买、T+1+H 开盘卖，经核对正确；
  - IC_IR 用 √(252/h) 年化；
  - 合成因子不得使用测试段的 IC；
  - 正交化必须逐日截面回归，控制变量只能用 T 日已知信息；
  - 衰减分析用 block bootstrap 给出半衰期的置信区间；
  - transaction-cost-calibration 只使用成交时点及之前的报价，时间统一为 UTC；
  - futures-cta 给出了“中国商品期货 1–3 月动量 IC 为负（反转市场）、carry 方向相反”的实测反先验，提醒全球先验不能直接套用；对 GOLD 不直接适用，只作方法参考。
- 第 4 层；**等待 Codex 复核**。

## 十七、2026-11-13 源码批次 S026 摘要（大 JSON 20 个、HTML 38 个、数据/样例/夹具 JSON 229 个，均为 DATA_AUDITED）
- **方法**：
  - JSON 审计结构、规模、首条记录和关键指标，没有逐值核对；
  - HTML 检查外部资源、内联脚本中的危险模式和标题，正文没有逐段读。
- **结果与宣称明显矛盾的地方**：
  - **A3 连板接力**（skill-alpha-a3-streak-leader-relay）的“生产”回测：
    - 全样本年化 -99.8%，MDD -99.99%；样本内年化 -99.97%；
    - 但“样本外 + IC gate”一组报出年化 +421%，样本只有 62 个信号，且年化是用短窗口日均收益外推的；
    - 样本内外完全反转、样本极小，不能当作证据；分层收益全是 NaN，平均截面宽度只有 2.74 只。
  - **两个因子库**（directional 296 个、risk-pattern 288 个）：
    - ic_mean_5d 的中位数分别是 0.006 和 0.003，最大不超过 0.032，没有一个绝对值超过 0.05；
    - 状态却全部是 pass，说明“验证通过”只检查流程，不检查预测力，与以前的模板比对结论一致。
  - **material-contract-alpha**：IC -0.049、ICIR -1.22、buy 平均净收益 -0.13%、最大回撤 -29%，“发布结论”仍是“通过（流程验收）”，质量指标全写 100%。
  - **dl-transformer-multiasset 生产预测**：IC -0.012（p=0.41），没有预测力。
  - **ic-decay 示例**：mean IC 0.905、NW-t 609 被判为“strong”，没有触发任何泄漏告警（其他技能把 IC > 0.15 视为可疑）。
  - **hk-us-fundamental**：全部 18,733 行的 growth 因子都缺失，状态仍是 PASS。
- **数据新鲜度与 mock**：
  - 4 个盯盘 Agent 的 outputs/live 把不同时间窗拼在一起，例如 market 用 2025-01-02 到 01-10、options 用 2026-03-10，质量状态却写 pass；
  - guardian 的模拟回测 27 期、累计 +45.6%、MDD 为 0，结果过于干净；
  - macro-rotation 的 l4.html 在 fetch 失败时静默改用 mock 数据。
- **quantspace 4 个示例的指标**：年化 23–35%、Calmar 1.6–2.4、MDD 10–16%，样本 2024-01 到 2026-07；XGBoost 三重障碍只有 4% 的交易日有持仓。与 S024 图片的观察一致，收益集中在 2024–2025。
- **其他**：
  - registry 评测记录引用了名为 “gpt-6-sol” 的模型分组和名为 lan-signer 的签名 key ID；只是 attestation 摘要，没有私钥；
  - b7 的席位映射把 317 个具体营业部标注成“游资/量化/庄股”等标签，置信度 B/C，有名誉风险；
  - regulatory-risk-radar 的样例把真实公司名称与虚构事件（“某创投基金”解禁等）混在一起；
  - pair-correlation 的输出带有 long A / short B 的操作提示；
  - jq-to-panda 的“均线交叉”样例实际实现的是多头排列状态，不是交叉；
  - a3 和 munger 的报告从 CDN 加载 Chart.js，没有 SRI。
- **可借鉴**：
  - A06 的发布验收同时报告标准成本 0.3%、压力成本 0.5%、极端成本 1% 三档，以及 train/test rank IC；
  - capacity-tca 给出参与率分布、平方根与线性冲击两种模型和盈亏平衡 AUM；
  - ml-purged-cv 用故意泄漏的样例（intentional-leak）作为反例夹具。
- 第 3/4 层；**等待 Codex 复核**。

## 十八、2026-11-13 源码批次 S027 摘要（剩余 360 个非 .py 文件：配置、脚本、schema、CI、样例）
- **方法**：
  - 文件内容完全相同的合并处理；
  - 在 6 个及以上文件中出现的公共行只读一次，其余行逐行读，记为 COMMON_LINE_FACTORED_READ；
  - 读之前先做凭证扫描，命中的值全是 `your_*` 之类的占位符。
- 至此 QS 的非 .py 文件全部覆盖，**剩余 UNREAD 只有 .py 共 2,344 个**。
- **安全与供应链**：
  - agent-for-liangshuyuan-tasks 的 `.mpc.json`（文件名疑似拼错）用 `npx -y` 拉取未固定版本的 MCP 服务器包；
  - fundamental-alpha 和 minuteflow-alpha 的 operators.json 以字符串形式保存 `numpy_impl`，并说明 LLM 可以新增算子，存在执行模型生成代码的风险（要在 .py 中确认是否 eval/exec）；
  - 这两份 operators.json 约定输入是按 (date×symbol) 排列的一维数组，时间序列算子却直接对整列做 `pd.Series.rolling`，如果调用方没有按代码分组，滚动窗口会跨股票，造成数据串扰（要在 .py 中确认）；
  - x-trader-builder 的 collector 通过 CDP 驱动已登录的浏览器自动滚动、点击并抓取 X 帖子，默认对象是一个真实账号，有违反平台条款和隐私的风险；
  - skill-cb-analyzer、northbound-margin-monitor、post-market-screener、oil-brief 的 PandaData 地址都是 http 明文；
  - factor-loop-evolve 的 alpha_library.json 残留了作者本机的绝对路径，其中含用户名（未转录）；
  - 正面例子：dalio 和 simons 的 CI 把 Actions 固定到 SHA，并用 `--require-hashes`；tradability-auditor、disclosure-event-extractor、futures-cta 的 CI 带 publish-guard，阻止提交个人邮箱。
- **结果与宣称矛盾**：
  - hk-us-fundamental 的回测状态为 PASS，但港股、美股多空总收益分别是 -57% 和 -63%，MDD -55% 和 -64%；
  - 美股收盘价未复权，拆股会制造虚假动量；
  - A3 连板接力：
    - calibrated 曲线在 n=5–10 的高连板档上给出 ±1 的极端权重；
    - known_limitations 自己承认样本内 IC 约 0.008、样本外 IC 约 0.107，严重分化；
  - factor-loop-evolve：
    - 100 个因子都来自同一个 2024–2025 CSI300 窗口的 20 次运行，最好的 Sharpe 1.40 只是样本内；
    - 部分 Sharpe 为负的因子仍标 `worth_keeping: true`；
  - post-market-screener 用同一窗口（2025-11 到 2026-06）校准权重；
  - global-macro-trend 的示例 CAGR -3.9%，如实披露。
- **研究流程**：
  - dl-tcn-shortterm 有约 46 个版本（v1–v47），在同一套 ordinary validation 折上以 0.00015–0.003 的 RankIC 增量逐步微调，属于典型的多重比较和验证集过拟合；
  - 讽刺的是，它自带的 pilot-readiness 模板规定封存前最多迭代 10 次，并要求独立的封存保管人；
  - v36、v46 设了只能用一次、结果出来后禁止再调参的封存测试，这是好的做法。
- **人设与名誉**：
  - futures-investment-council 用 LLM 扮演一批真实交易员的“专家意见”；
  - klarman 的 evidence 模板把真实股票代码（如 000010.SZ）与虚构的“*ST / 破产重整已受理”事实放在一起，有误导和名誉风险，模板里还有算术自我纠正的残留；
  - stock-memory-analyzer 手工维护行业数据（DRAM 合约价 2026Q1 +95% 等），自称来源于 TrendForce 公开摘要，没有校验，capex 备注中的数字是错乱的。
- **其他**：
  - registry 的 frontmatter schema 把 license 写死为 `GPL-3.0-only` 常量，这正是目录把 MIT、Apache 仓也统一标成 GPL 的根源；news-sentiment 实际是 Apache-2.0；
  - 又发现 pandadata-warehouse 一条 `alwaysApply: true`；
  - cb-analyzer 的成本模型对可转债计入 0.05% 印花税，可转债实际不征印花税，偏保守；
  - minuteflow 有 3 个特征是常数占位（sector_lead_rank 恒为 0.5 等），gap_fill_ratio 是错误的代理变量；
  - corporate-governance-scanner 在数据缺失时给“行业中性默认分”75 或 78，审计意见在 0 条记录的情况下仍得 95 分，等于把缺失当作良好；
  - hk-us-consensus-revision-radar 的 evals 写得规范：要求说明日期来源、显式交代缺失。
- **可借鉴（V1.2）**：
  - agent-future-trading 按数据频率设置保守的发布滞后（周频 5 日、月频 22 日）和新鲜度阈值，可供 NR08 新闻/经济日历参考；
  - 它还设有 20% 总保证金上限，并区分“学习只调权重、不授予交易权限”，与 V1.2 的 Core↔RiskExecution 边界思路一致；
  - rl-portfolio-allocator 的研究门禁默认失败即停（fail-closed），发布前必须有一份 ≥3 折 ≥5 种子的批准记录，并原子发布；
  - signal-portfolio-optimize 修改默认参数时附了时间切分证据（t 值、样本数），但调参用 2024、验证用 2025–2026。
- 第 3/4 层；**等待 Codex 复核**。
