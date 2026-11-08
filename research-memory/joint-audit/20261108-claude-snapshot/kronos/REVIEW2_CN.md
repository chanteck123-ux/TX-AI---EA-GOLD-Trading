# Kronos 第二轮补读（Claude，2026-11-04）

全部是静态读代码，**没有运行**。行号指上游 `67b630e` 的同名文件。原件没有修改。

## A. webui（全文：app.py 1–708、templates/index.html 1–1238、run.py 1–89、start.sh 1–40、requirements.txt 1–7）

### 对照 Codex web-review 的 12 条
回原文核对后，以下各条成立：
- 1：468–471 与 571–577 两处时间不一致；
- 2：244–250、557–566 用前两行的时间差外推时间；
- 3：118 dropna 后没有 reset_index，543 拿标签当位置用；
- 4：index.html 912–967 与 1060–1073 按日历时间映射滑块；
- 5：1073 `toISOString().slice(0,16)` 丢掉了 Z；
- 6：1134–1159 按数组位置配对，MAPE 在 act.close 为 0 时会除零；
- 7：103 伪造从 2024-01-01 开始的逐小时时间；
- 8：645–646 没有固定 revision，133 文件名只到秒，594–621 保存失败仍返回 success；
- 9：25 CORS 全开，346/409 接受任意 file_path，708 与 run.py:82 用 debug + 0.0.0.0；
- 10：22/706 的提示说会用模拟数据，实际 492 返回 400；
- 11、12：成立。

### Claude 新增
- W-C1 `app.py:165–169`：`last_pred` 只在内层 if 里赋值，`prediction_results` 为空时会抛 NameError。这个异常被 205 行吞掉，保存失败只打一行日志。另外字段名写的是 `last_prediction`，实际取的却是**第一个**预测点（168 行），命名与内容不符。
- W-C2 `app.py:434–436`：只取 OHLC + volume，不取 amount，于是 KronosPredictor 用 `volume × OHLC 均值`合成 amount（kronos.py:531–532）。即使文件里有真实成交额也不会用到，与训练时用 amount 列的口径不一致。
- W-C3 `app.py:479–487`：前端无法传 top_k，因此固定为 0。
- W-C4 `index.html:7–8`：plotly 用 `plotly-latest`，axios 没写版本，都是未锁版本的外部 CDN 脚本，有可复现性和供应链风险。
- W-C5 `webui/requirements.txt`：缺少 einops、safetensors、tqdm 等模型依赖，`from model import …` 可能失败，进而导致 MODEL_AVAILABLE=False（推断，未运行）。
- W-C6 `index.html:1003–1008`：先调用 updateStartHandle(0.1)，再调用 updateEndHandle(0.1+520/N)。总行数接近 520 时，起点会被夹到 1−520/N，终点却不夹上界（与 Codex 第 4 条一致，补充复现条件）。

## B. finetune_csv（全文：config_loader.py 1–267、finetune_base_model.py 1–468、finetune_tokenizer.py 1–359、train_sequential.py 1–361）

第一轮的发现 14（整窗统计量归一化）和 15（9:1 切分、无间隔、无测试集）都已在全文中确认。新增：

- C-C1 **DDP 被绕过，梯度不在各卡间同步**：
  - finetune_base_model.py:291–292、326–327、finetune_tokenizer.py:201、243 都用 `(model.module if use_ddp else model)(...)` 直接调用内部模块做前向；
  - DDP 的梯度 all-reduce 依赖通过 DDP 包装对象做前向，绕过后各卡各自训练、互不同步；
  - 最后只有 rank 0 保存（finetune_base_model.py:356–359），丢弃了其他卡的训练结果。
  
  README 宣称"多卡 DDP 加速"，与实现不符（静态推导，未运行）。
- C-C2 **训练序列长度超出模型上下文**：yaml 设 lookback 512 + predict 48，样本窗口为 561（finetune_base_model.py:33），输入 560 个 token，超过推理时 max_context = 512。`max_context` 在训练中完全没有被使用。训练长度与预训练长度、推理截断长度三者不一致。
- C-C3 **训练样本起点公式不一定是双射**：`(idx*9973 + (epoch+1)*104729) % (max_start+1)`（finetune_base_model.py:113）。当 max_start+1 是 9973 的倍数时，会重复抽取或遗漏窗口。shuffle 只打乱 idx，不能修复这一点。
- C-C4 **验证同样受 K01 影响**：model.eval() 之后整段 forward（finetune_base_model.py:313–327），交叉注意力关闭因果遮罩，验证损失偏乐观，而最佳模型又是按这个损失挑选的。
- C-C5 **pre_trained_tokenizer=False 时，第二阶段用了一个新的随机 tokenizer**（train_sequential.py:172–197）：predictor 不使用第一阶段刚训练好的 tokenizer，而是重新随机初始化一个，等于浪费了第一阶段。
- C-C6 **两个阶段之间没有 barrier**（train_sequential.py:279–288）：多卡时只有 rank 0 保存 tokenizer，其他 rank 可能在保存完成前就读取 finetuned_tokenizer_path；文件不存在时 155 行会直接抛错。
- C-C7 杂项：
  - config_loader.py:105 的 `yaml.dump(...)` 没有指定输出流，返回字符串却没有打印，print_config 实际不输出内容；
  - finetune_tokenizer.py:263 的 "Total Training Time" 用的是本轮的 epoch_start_time，显示的是单轮耗时；
  - finetune_tokenizer.py:289 与 294 重复读取配置；
  - finetune_base_model.py:69 使用已弃用的 `fillna(method='ffill')`；
  - 日志中 "Distributed training: False" 是写死的（train_sequential.py:126）。

## 进度
本轮新增全文阅读 9 份：webui 5 份、finetune_csv 4 份（finetune_base_model.py 由部分阅读升为全文）。examples 与数据、图片的记录在后续批次进行。

## C. examples、结果数据与图片（2026-11-04 补读，全部为静态阅读，**未运行**）

### C.1 逐文件阅读方式
| 文件 | 方式 |
|---|---|
| prediction_example.py、prediction_wo_vol_example.py、prediction_batch_example.py、prediction_cn_markets_day.py | 全文 |
| run_backtest_kronos.py、yuce/historical_backtest.py | 全文（原为部分阅读） |
| prediction_new.py（1–1333） | 全文 |
| prediction_new_GUI.py | 1–550、990–1624 全文；551–989 与 prediction_new.py 逐行 diff，只差 `:cite[n]` 注释、交易日函数及一个价格参考函数，按 diff 核对记为全覆盖 |
| get_akshare_date_2024-2025_x.py | 全文 |
| get_date_new.py | 与上一文件逐行 diff，差异段落全部阅读（另回读 255–262、410–460、525–535） |
| prediction_akshare_2024-2025.py | 全文 |
| yuce/*.json（5 份） | 作为数据全文阅读 |
| webui/prediction_results/*.json（29 份） | 结构全读 1 份；29 份用 PowerShell 逐份统计参数、窗口、MAE、方向、OHLC 违例、预测哈希 |
| tests/data/*.csv、finetune_csv/data/*.csv | 表头、首尾行和逐行统计（awk） |
| 13 张 PNG | 逐张查看图像内容 |
| .gitignore | 全文 |

### C.2 examples 脚本发现
- E1 **`df.loc[-lookback:]` 实际上取的是全部历史**（prediction_new.py:1198–1199、1229、1243；GUI:1203–1204、1236、1258、1273；prediction_akshare:427–428、465）。df 在 prepare_stock_data 中已 `reset_index(drop=True)`，是从 0 开始的 RangeIndex；`.loc` 按标签切片，起点 −lookback 比任何标签都小，于是返回整张表。作者算出的 lookback 没有生效，输入长度等于历史条数；超过 512 时由 predictor 截断。
- E2 **静默使用合成数据**：
  - prediction_new / GUI 中 AKShare 失败时，`create_realistic_fallback_data` 用 seed 42 随机游走生成价格，并以真实文件名 `{code}_stock_data.csv` 落盘，之后 `get_stock_data` 一看到文件存在就直接使用；
  - get_akshare 的 `create_sample_data` 也一样，"模拟数据" 只存在 `df.attrs` 里，写入 CSV 后标记丢失；
  - 下游预测因此可能在用户不知情的情况下针对合成数据运行。
- E3 **人工"增强因子"直接乘到模型输出价格上**（prediction_new.py:702–823；GUI:1327–1407）：
  - 宏观分数 0.75、美联储"2025年9月降息25个基点"、"预计 2025 年再降 2 次"、板块动量和涨停数、个股基本面都是写死的；
  - 600580、300207 还有专门的特殊分支；
  - 因子先限制在 0.85–1.15（GUI 版为 0.9–1.1），prediction_new.py 再整列截到 ±10%；
  - 这一步与 Kronos 无关，图上的"增强预测"不是模型结果。
- E4 **GUI 版后处理（GUI:997–1136）**：
  - `validate_prediction_results` 对超限价格乘以 0.8–1.2 的**无种子随机系数**，可能反而放大偏离；
  - 它与 `apply_post_holiday_adjustment` 都用 `df.iloc[i][col] = …` 链式赋值，写进的是副本，调整实际不生效，而且 `warnings.filterwarnings('ignore')` 把相关警告也屏蔽了；
  - `smooth_prediction_results` 的居中滚动平均用到了路径中的后续点，整条路径还乘以 (1 + 近期趋势×0.3)；
  - 成交量乘以随机噪声后截在历史均值的 0.3–3 倍之间（下方 C.4 的图上可见平台状的截断）；
  - 另外，tkinter 的 messagebox 是在工作线程里调用的（GUI:306–313），而 Tk 不是线程安全的。
- E5 **节假日与日期**：
  - prediction_new.py 只排除周末；
  - GUI 版只写死 2025 年假期，akshare 版只写了 2025 年国庆；
  - GUI 列表中的端午和春节日期按 Claude 的知识与 2025 年实际安排不符，**需核实**；
  - 其他年份的节假日都会被当成交易日。
- E6 **数据获取脚本（get_akshare / get_date_new）**：
  - 三个来源的单位可能不同：按 Claude 的接口知识，东财和 AKShare 的成交量以"手"计，Baostock 以"股"计、成交额以"元"计，合成数据的成交额以"万元"计——**需核实**；它们却写进同一个文件名；
  - `parse_kline_data_directly` 用逗号拆完整串后又对单个字段 split，`len(items)>=6` 永远不成立，这个兜底是死代码（get_date_new 改用 `'","'` 分割后修好了）；
  - get_date_new 的 `create_sample_data_all_history` 在第一行（i=0）用到了未定义的 `year`（只在 `if i>0` 分支中赋值），会抛 UnboundLocalError，合成兜底必然失败；
  - get_date_new 输出 `{code}_all_history.csv`，与预测脚本读取的 `{code}_stock_data.csv` 不一致；
  - 导入失败时 main 会运行 `pip install`；东财接口用 http 明文；代码以 8/4 开头时默认算作上交所；
  - 源码里写死了东财的 `ut` 参数，属公开网页参数，本审核不转录。
- E7 **prediction_akshare_2024-2025.py**：
  - `pd.concat([历史, 预测], axis=1)` 之后，最后一行是预测日期，"历史数据" 列在那里是 NaN；
  - 因此 `close_df['历史数据'].iloc[-1]` 是 NaN：统计框被跳过，`generate_prediction_report` 直接返回"没有有效的预测数据"，价格变动柱全为 NaN；
  - 结论：报告与总结段实际不会输出。
- E8 prediction_batch / cn_markets_day / run_backtest / historical_backtest：结论同此前记录（硬编码路径、未入库数据、未复权、000001 名称错误、±10% 涨跌停误用、预测价成交、ffill 持仓无法平仓、空头收益符号错、Sharpe 以百分比显示、无成本、随机游走"预测"且与当日真实价相减）。本轮全文阅读确认。
- E9 所有中文 example 都是 `sample_count=1`、T=1.0、top_p=0.9，且不设种子：结果是单条随机路径，不可复现。

### C.3 结果 JSON（数据审计）
- yuce 的 5 份报告：宏观块完全相同且写死，adjustment_factor 分别为 1.04545、1.04545、1.0935、1.1、1.00776；holiday_effect 的 win_rate 0.8 没有来源。
- webui/prediction_results 的 29 份：
  - **数据范围**：全部为 BTC / BCH USDT 5 分钟期货（.feather，不在仓库中，路径是作者本机的绝对路径）；lookback 400，pred 120。
  - **窗口与参数**：只有 **10 个不同窗口**，同一窗口上反复更换 T（0.5–1.3）、top_p（0.8 / 0.9）和 sample_count（1 / 2 / 5），等于在对比区间上调参。
  - **平直与重复输出**：6 份预测收盘价全程只有一个值（平直路径）；有 3 组输出完全相同，其中 170831、171720（T 0.7）与 171913（T 0.5）的哈希一致，说明这几份输出没有随温度改变。
  - **OHLC 违例**：14 份出现 high < max(open, close) 或 low > min(open, close)，最多每根都违例，印证此前第 3 条"无 OHLC 约束"。
  - **方向与误差**：终点方向与实际一致 13 / 29，不一致 16 / 29（同一窗口不独立，不能当作准确率）；MAE 从 6.46（BCH）到 27,229（BTC，175135 的预测明显失真）。
  - **缺失字段**：actual 的 amount 全为 0，说明数据源没有成交额。

### C.4 CSV 数据与图片
- tests/data：输入 2,500 根 5 分钟 K 线（2024-06-18 至 2024-08-29），两份输出各 8 行，与回归测试的期望值相对应。
- finetune_csv/data（HK 09988 5 分钟）：
  - 规模：93,912 行，2019-11-26 至 2025-09-17，共 1,430 个交易日，每日 66 根（13 个半日只有上午）；
  - **列顺序为 open,close,high,low**（不是 OHLC 顺序），读取时按列名处理，不受影响；
  - 质量：OHLC 违例 0 行；amount 全为 0；有 169 根成交量为 0；价格带非整数小数，疑为复权价。
- 13 张图片：
  - **figures/backtest_result_example**：四种信号在 2024 年 7–8 月几乎不持仓；超额收益主要来自 2024 年 9 月底的单次大涨行情；min 信号最好——在测试期挑信号（呼应第 12 条）。
  - **figures/prediction_example**：只有前约 50 根贴近真实，之后预测涨到 11.3，真实约 10.92；这是单条样本路径。
  - **figures/overview、logo**：架构图与代码结构一致；logo 无内容。
  - **finetune_csv/examples 的 5 张**：日期为 2020-07-09、2020-07-30、2021-02-19、2022-05-19、2023-08-10。按 yaml 的 9:1 顺序切分（val 0.1、test 0），验证段约从 2025 年起，**5 张都在训练段内，是样本内展示**；2022-05-19 那张的预测还出现了比真实更大的跳空。
  - **yuce 的 4 张（GUI 输出）**：
    - 600580：当前价 48.42，预测起点 33.81、终点 20.83；
    - 000021：当前价 31.72，预测起点 25.88；
    - 300207：当前价 33.79，预测起点 29.70；
    - 002354：与当前价基本衔接；
    - 前三张的起点都在连续大涨之后低于现价 12–30%，可能原因是输入 z-score 截断在 ±5σ 时把大涨后的价格截低了（第 4 条），加上 E1 使用全部历史，**属推测，需实验验证**；
    - 预测成交量都出现平台状截断（E4）；"增强预测"高于"平滑预测"，是人工因子的效果（E3）。

### C.5 对 Codex Web 报告的补充
上述 E1、E2、E7 以及 get_date_new 的 UnboundLocalError 是 Codex web-review 1–12 条和 core-review K01–K14 中没有的新发现，留待 Codex 复核。

## 进度（更新）
Kronos 92 个文件已全部按上表方式覆盖：脚本全文或 diff 核对、数据统计审计、图片逐张查看。仍未做的是：论文原文未读；所有结论都未经运行验证。

## D. 论文原文（arXiv 2508.02739v1，2025-08-02）部分阅读（2026-11-07）
- **读取方式与范围**：
  - 通过联网抓取工具读取 arXiv HTML 全文 https://arxiv.org/html/2508.02739 。全文约 157,861 字符，**前约 78,850 字符为原文**，覆盖正文、附录 B 和附录 C 的前半部分。
  - 其余部分只拿到抓取工具生成的摘要，**不计为原文阅读**，包括：附录 C 后半至附录 H、表 6、表 8、表 13、图 4 的数值。
  - 没有读 PDF 和摘要页。
  - 状态记为 **PARTIAL**，以下标"[摘要]"的条目都未经原文核实。
- **原文可核实的内容**：
  - 输入为 OHLCVA 六维，按特征做 z-score 后截断到 [-5, 5]；
  - 量化方法为 BSQ，20 bit 拆成粗、细两个子 token，各 10 bit；
  - 主干是 decoder-only，使用 RoPE 和 RMSNorm，最大上下文长度 512；
  - 三个规模分别为 24.7M、102.3M、499.2M 参数；
  - 预训练数据为"超过 120 亿条 K 线"；
  - 回测：中国 A 股日频，数据来自 Qlib，只做多，按信号取 top-k，**每笔交易成本 0.15%**。
- **与代码交叉核对（CONFIRMED，已回源码）**：
  - `finetune/dataset.py` 第 107–117 行**只用 lookback 窗口**计算均值和标准差，再对整段做标准化和截断；
  - `finetune/qlib_test.py` 第 85–87 行用 context 窗口计算；
  - `finetune/config.py` 第 46 行设 `clip = 5.0`。
  - 结论：论文中的"z-score + clip ±5"在代码里是**按样本、按回看窗口**实现的，不使用未来数据。这补上了论文没写清的"窗口"一项。
- **论文自身的不一致（原文可见）**：
  1. 交易所数量：摘要和第 1 节写 45 个，附录 B 写"40 多个交易所、30 多个国家"。
  2. 频率数量：引言写"7 种时间粒度"，表 4 却列了 12 种频率设置。
- **需要继续核实（PLAUSIBLE，来自[摘要]）**：
  1. 预训练数据截至 2024-06，评估从 2024-07 开始，按时间切分，**不按资产切分**。
  2. XIDX、XKLS、XTAI 在评估中被标为分布外，但据摘要，表 13 的预训练语料中也包含这三个交易所。如果属实，"分布外"一说不成立。
  3. 回测的 AER 和 IR 是否已扣除 0.15% 成本，原文未见明确说明；回测日期、幸存者偏差的处理、复权口径都未见说明。
  4. 摘要中列出的基线只有 18 个，与原文所说"25 个基线"不符。
- **对 V1.2 的含义**：论文的评估指标是截面 IC 和 RankIC，以及 A 股做多组合，**都不是黄金 CFD 的执行级证据**。Kronos 作为信号源研究时，还需要单独做 XAUUSD 的时间切分外推验证，并扣除 FxPro 的实际成本（未执行）。

## D2. 论文后半部分原文阅读（2026-11-07 补读）
- **范围**：通过联网抓取补读了约第 78,850 字符至第二次抓取被截断处的原文，覆盖附录 C 后半至附录 F 的大部分内容、表 6–18、附录 H 的 Q1–Q3。
- **仍未读**（截至 2026-11-07）：表 18 后半、表 19–21、附录 G 的图注。**2026-11-08 已在 D3 中补读完毕。**
- **原文确认（CONFIRMED）**：
  1. **"分布外"一说不成立**：附录 D 把 XIDX、XKLS、XTAI 列为"分布外交易所"，但表 13 的预训练语料中**确实包含**这三个交易所，起始日期都是 2020/1/31，观测数分别约为 3,863 万、4,594 万、7,162 万条。论文没有把"分布外"定义为"预训练中未见过"。评估只按时间切分（2024 年 7 月起），不按资产切分。上一节 D 中的 PLAUSIBLE 第 2 条由此升级为 CONFIRMED，结论是：**"分布外"不能理解为"模型没见过的资产"**。
  2. **预训练数据截止时间只精确到月**：原文只说截至 2024 年 6 月，测试期从 2024 年 7 月开始。没有给出截止日、测试结束日或回测日期；表 13 只有起始日期，没有结束日期。
  3. **价格 IC 和收益 IC 的口径不同**：价格 IC/RankIC 是"每个样本内"预测序列与真实序列的相关性，再对 OHLC 四个通道取平均，**属于单序列相关，不是截面 IC**；收益 IC 才是在同一资产类别、同一频率的所有样本上汇总计算。所以价格 RankIC 与常见截面因子 IC（例如 QuantSkills A173/A174）**不能直接比较**。
  4. **预测期长度（表 8）**：5 分钟线回看 480、预测 96；1 小时线 80/12；日线 40/12。
  5. **回测设置**：A 股 Qlib 日线"未做额外处理"；CSI300 取 k=50、n=5，CSI800 取 k=200、n=10，等权，最少持有 5 天，每笔成本 0.15%。Kronos-large 的平均 AER 为 0.2084，IR 为 1.6491。**原文没有说明这些数字是否已扣除成本、是否复权、如何处理幸存者偏差，也没有给出回测区间和成分股取哪一天。**
  6. **基线数量与原文一致**：按论文表格逐列数，8 个全量训练模型 + 12 个零样本模型 + 2 个计量模型 + 3 个生成模型 = 25 个。这是我按表格清点得到的，论文本身没有给出这个分解。
  7. 附录 H 的 Q1–Q3 主要是定性论证，Q1 明确说相关讨论"超出本文范围"。论文**没有专门的局限性章节**。
- **对 V1.2 的含义**：论文没有证据表明它能在未见过的资产或时期上外推；回测结论也缺少扣费口径和时间区间。Kronos 只能作为待验证的信号候选，不能拿这些论文数字作为预期收益依据。

## D3. 论文剩余部分补读（2026-11-08，读完全部正文）
- **范围**：用内置浏览器打开 arXiv HTML 版，取页面纯文本（共 131,001 字符），补读第 117,220–131,001 字符，内容包括表 17 的说明、表 18–21 全部数值、附录 G 以及图 15–19 的图注。
- 加上 D 和 D2，**论文正文和全部表格已读完**。图 1–19 是图片，只读了图注，图片本身没有看。覆盖表 `coverage.csv` 已新增一行，状态为 FULL_READ，并注明了这一点。
- **版式说明**：HTML 版的表格标题放在表格**下方**，所以纯文本里"Table N:"后面紧跟的是第 N+1 张表的内容。下面已按正确对应关系整理。
- **原文要点**
  1. **表 18（波动率预测，Kronos 对比全量训练模型和计量模型）**：
     - 平均 R²：Kronos-large 0.2624、base 0.2470、small 0.2490；GARCH 0.2323，ARCH 0.2281。
     - 平均 MAE：Kronos-large 0.0370，GARCH 0.0405。
     - Kronos-large 有 11 项第一，GARCH 有 3 项。
     - 但在部分市场上 GARCH 更好：XNAS 的 R² 为 GARCH 0.2271、Kronos-large 0.0978；XHKG 为 GARCH 0.3295、Kronos-large 0.1824。
     - **Forex 一项**：Kronos-large 的 R² 为 0.1277，ARCH 0.1169，GARCH 0.1141，**优势很小**；MAE 为 0.0069 对 0.0185。
  2. **表 19（波动率预测，零样本模型）**：Kronos 以外各模型的平均 R² 在 0.09–0.15 之间，Forex 的 R² 普遍低于 0.12。
  3. **表 20（合成 K 线的判别分数，原文说"越高越好"）**：
     - Kronos-large 平均 0.3048，DiffusionTS 0.2504，TimeVAE 0.0308，TimeGAN 0.1993；
     - Forex 15 分钟线 Kronos-large 0.4688，日线 0.4152。
     - 判别分数通常是"越接近 0 越好"，常见定义是 |准确率 − 0.5|。论文在这里写"越高越好"，与常见定义相反，原文没有给出本文的定义。**PLAUSIBLE：这个口径需要核对**。
  4. **表 21（合成数据用于训练下游模型时的 IC 和 RankIC）**：
     - 平均 IC：Kronos-large 0.0301，DiffusionTS 0.0128，TimeVAE −0.0147，TimeGAN 0.0024。
     - **Forex 日线**：Kronos 三个规模的 IC 只有 0.0042–0.0069，**低于 TimeVAE 的 0.0140**。
     - Crypto 日线 IC 也只有 0.003–0.005。
  5. **附录 G 与图 15–19**：五个展示用例分别是 600977（5 分钟线）、09992（5 分钟线）、NVDA（1 小时线）、BTC/USDT 永续合约（15 分钟线）和 BMW（日线），都是作者挑选的代表性资产。正文只做定性描述，原文说预测"在视觉上也合理"。这类挑选出来的展示**不能作为证据**。
- **对 V1.2 的含义**：
  - 外汇类（与 XAUUSD 最接近的资产类别）的结果显示：波动率预测相对 GARCH 只有小幅优势，合成数据在日线上的预测作用接近 0。
  - 所以论文对黄金 CFD 的直接支持很弱，Kronos 仍只能作为待验证的候选。如果要用，需要先在 XAUUSD 上做时间外推验证，并与 GARCH 这类简单基线对照（未执行）。
- **待汇总的复核项**：
  - E8：表 20 判别分数"越高越好"的口径；
  - E9：表 18 中 Forex 一项相对 GARCH 的优势幅度。
  - 两项都留到最后统一交给 Codex 复核。
