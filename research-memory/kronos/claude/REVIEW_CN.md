# Kronos（金融 K 线基础模型）学习与审核笔记 — Claude，2026-11-01

## 0. 来源与范围
- 本地：`Desktop\TX\Kronos：金融市场语言的基础模型\Kronos-master\`，共 92 个文件、16,778,881 字节；另有 `Kronos-master.zip`，9,451,071 字节，SHA-256 `92FC5551…20FF`。
- 上游：https://github.com/shiyu-coder/Kronos ，master 提交 `67b630e67f6a18c9e9be918d9b4337c960db1e9a`（2026-04-13），**MIT 许可**。
- 一致性：本地 92 个文件的 git blob 哈希与上游该提交**逐一相同**，没有本地改动、多出或缺失的文件。因此 examples/ 中的 akshare、yuce、GUI 等脚本属于上游仓库本身。
- 论文：arXiv 2508.02739（README 称已被 AAAI 2026 接收）。论文原文**未读**，外部事实未核实。
- 阅读状态（逐文件见 `coverage.csv`）：
  - 全文阅读 21 份：README、LICENSE、requirements、`model/` 全部、tests、`finetune/` 全部、finetune_csv 的两份 README 与 yaml、webui README、`examples/prediction_example.py`；
  - 部分阅读 6 份（注明行号）；
  - 未读 52 份：主要是 29 份 webui 预测结果 JSON、`webui/app.py`、`index.html`、较大的 examples 脚本、finetune_csv 的其余训练脚本；
  - 图片 13 份未审。
- **没有安装任何依赖，没有下载模型权重，没有运行任何代码或测试。** 下文的"静态发现"都是读代码推导出来的，未经运行验证。

## 1. Kronos 是什么（按代码核对）
- 两阶段结构：
  1. **Tokenizer**：编码器 Transformer 把 OHLCV + amount（6 维）映射到 s1 + s2 位的 Binary Spherical Quantization 码。粗码 s1 与细码 s2 构成分层离散 token；解码器重建 K 线。
  2. **Predictor**：decoder-only 自回归 Transformer（RoPE、RMSNorm、SwiGLU）。先预测 s1，再经 DependencyAwareLayer（交叉注意力）在 s1 条件下预测 s2。
- 时间特征：minute、hour、weekday、day、month 五个嵌入，相加后进入模型。
- 推理（`KronosPredictor.predict`）：
  - 按**本次输入回看窗口**计算 z-score 归一化，并 clip 到 ±5σ；
  - 自回归采样（温度 T、top_k / top_p）；
  - sample_count 条路径**取平均**后反归一化；
  - 输出未来 pred_len 根 K 线的 OHLCV。
- 模型规模：mini 4.1M（上下文 2048）、small 24.7M、base 102.3M（上下文 512）；large 499.2M 不开源。

## 2. 静态发现（代码推导，均**未运行**）

### 2.1 模型与推理
1. **padding mask 路径不可用**（`module.py:339–350`）：
   - 同时传入 `attn_mask` 和 `is_causal=True`，PyTorch 的 SDPA 会拒绝这种组合；
   - mask 的布尔语义也与 `compute_loss` 中 `valid=(padding_mask==0)` 相反（SDPA 的 True 表示"参与注意力"）；
   - 官方训练和推理都传 None，因此当前路径不受影响；但任何自行加 padding 的改造都会出错。
2. **s2 交叉注意力在训练与推理时不一致**（`module.py:387`、`kronos.py:440`）：
   - 训练时 `is_causal=self.training=True`，query 与 key 等长，位置对齐；
   - 推理时 `decode_s2(context, sample_pre)` 的 query 长度为 1，RoPE 位置为 0，却非因果地注意到长度为 L 的整个 context，相对位置与训练时不同；
   - 是否影响精度需要实验验证；官方回归测试只锁定了输出数值，不证明这一点没有问题。
3. **多路径取平均得到的是"平均路径"**：结果不是预测分布，也不保证每根 K 线满足 high ≥ max(open, close) ≥ min(open, close) ≥ low，模型本身没有施加 OHLC 约束。把均值当作价格目标会低估波动；需要的是分布或分位数，而不是单条平均路径。
4. **±5σ 截断与窗口内归一化**：极端行情（跳空、新闻冲击）在输入端被截掉；预测量级受回看窗口波动率支配。
5. **对时间戳的要求**：
   - 预测必须提供未来时间戳 `y_timestamp`；
   - 时间特征使用无时区的原始时间值。若是 24/5 市场，就需要正确构造周末跳空和每日休市后的未来 K 线时间戳；
   - 券商服务器时区与训练数据的交易所本地时区不同，同一时刻的 hour 编码会不同。
6. 采样有随机性，不设种子就不可复现。官方测试用 seed = 123 且 top_k = 1，才得到固定输出。
7. `sample_from_logits`：当 top_k 为 None 而 top_p 有值时，会执行 `None > 0`，抛出 TypeError（Predictor 默认 top_k = 0，所以没有触发）。另外 top_k 与 top_p 同时生效时只执行 top_k 分支（提前返回）。

### 2.2 官方 Qlib 微调与回测（`finetune/`）
8. **验证集与训练集在时间上重叠**：
   - 训练集至 2022-12-31，验证集从 2022-09-01 开始；
   - 验证样本是任意窗口，包括目标落在训练期内的窗口；
   - 而 best checkpoint 是按验证损失选出的，选模数据与训练数据重叠。
   
   同样，测试集从 2024-04-01 开始，与验证集的 2024-06-30 重叠；但回测从 2024-07-01 开始，只要只计这之后的信号，影响较小。
9. **预训练数据的截止日期未知**：
   - 公开模型使用了 45 家以上交易所的数据预训练，截止时间在代码中查不到；
   - 若预训练已经覆盖 2024–2025 年的 A 股，那么微调回测期可能已经被基础模型"见过"（前视），需要查论文核实。
10. **DataLoader 多 worker 重复样本**：
    - `QlibDataset.__getitem__` 忽略 idx，用实例内的 `py_rng` 随机抽样；
    - `num_workers=2` 时，各 worker 复制了同一个 RNG 状态，会产生相同的样本序列，有效样本多样性下降；
    - `set_epoch_seed` 在主进程调用，不影响已经复制出去的 worker。
11. **先微调 tokenizer 再微调 predictor 的语义问题**：predictor 从预训练权重开始，但改用**微调后**的 tokenizer，码字与预训练 predictor 学到的 token 含义不再对应。这是否会抵消预训练的价值，需要实验验证。
12. **qlib_test 的信号单位与选择问题**：
    - 信号 = 预测收盘（归一化单位）− 窗口最后收盘（归一化单位），即"以本股回看标准差为单位的变化"，不是预期收益率，不同波动的股票被放在同一尺度上排序；
    - 同时生成 last、mean、max、min 四种信号，在同一回测期上比较，属于在测试期上选择；
    - 成本假设：买 0.1%、卖 0.15%、最低 5 元、涨跌停 9.5%、开盘价成交；
    - 信号日 t 对应哪一天成交依赖 qlib 的执行语义，**未核实**。
13. `reduce_tensor` 用 AVG 之后又除以 world_size（未被调用）。`use_comet` 默认 True，但 API key 是占位符，直接运行会失败。

### 2.3 CSV 微调（`finetune_csv/`）
14. **训练归一化使用了未来数据**（`finetune_base_model.py` 的 `__getitem__`）：
    - 均值和标准差在整个窗口（lookback + predict）上计算，包含待预测部分；
    - 官方 Qlib 版本只用回看段（注释明确写了要防泄漏），推理时也只用回看段；
    - 因此 CSV 版本既有前视，也与推理不一致。
15. 按比例 9 : 1 顺序切分训练/验证，两段之间没有间隔，`test_ratio = 0`。README 里的"训练结果"图片标注为 historical，没有独立测试集的证据。缺失值用 ffill 补齐，示例数据的 amount 全为 0。

### 2.4 examples 中的回测脚本（作者附带，非核心）
16. `examples/run_backtest_kronos.py`，**严重缺陷，不能作为任何绩效证据**：
    - 没有未来预测时，回退为使用全部预测（与历史重叠）；
    - 价格缺失时用预测价当成交价，等于虚构成交；
    - 对 position 做 ffill，使信号无法回到 0，平仓分支几乎不会执行；
    - 平仓时用 `capital = position * price` 覆盖现金，空头会算出负资本；
    - 不计成本；
    - Sharpe 用复合年化收益除以波动。
17. `examples/yuce/historical_backtest.py` **根本没有调用 Kronos**，"预测"是正态随机游走（`simple_prediction`）。yuce 报告 JSON 中的宏观与板块描述是写死的叙述，例如"2025年9月降息25个基点"、板块动量 0.85，不是数据计算结果。
18. webui 建议温度取 1.2–1.5、样本数取 2–3 来"提高质量"，没有给出证据。

## 3. 对本项目（黄金 EA）的意义与边界
- **可研究的用途**：只限 LEAN（C#）研究端之外的离线研究假设，例如把 Kronos 的 XAUUSD M5 未来分布作为候选特征或情景生成器。必须先满足：
  1. 固定模型与 tokenizer 的 revision（像官方测试那样钉住哈希）；
  2. 用 FxPro 实际 Tick 或 M5 数据，在**预训练截止日期之后**的样本外区间评估；
  3. 时间戳与时区按服务器时间构造，并处理周末与每日休市；
  4. 使用多路径分位数，不用平均路径；
  5. 扣除成本与延迟（0–250 ms）后，再与简单基线比较。
- **不适用于直接集成**：
  - 本项目规定 MQL5 EA 独立执行，Python 只做 MCP 监控；Kronos 依赖 PyTorch、GPU 推理，不能进入 MT5 执行端；
  - 不能改变用户 Scalping SOP（M5、供需区回测、反转闭柱、日 6 盈 / 6 亏）；
  - 预测输出不是 TradeIntent，也不能绕过 RiskExecution。
- **评估纪律**：README 中的图片与示例回测都不是证据。作者自己也声明 finetune 流程是 demo、非生产，并说明部分注释由 AI 生成、可能不准。
- 本次只是学习与记录，**没有**启动研发、训练、回测或任何接口变更。

## 4. 待办与交叉核对
- 已建 `../CODEX_HANDOFF_CN.md`，请 Codex 独立复核发现 1–17。两边的结论分开保存。
- 还需要：
  - 补读 `webui/app.py`、finetune_csv 的其余三个脚本、`examples/prediction_new*.py` 与 akshare 脚本；
  - 阅读论文，核实预训练数据范围与评测协议。
