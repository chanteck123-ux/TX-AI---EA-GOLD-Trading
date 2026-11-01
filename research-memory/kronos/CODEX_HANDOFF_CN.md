# Kronos 学习：Claude → Codex 交叉复核交接（2026-11-01）

用户要求"你和 codex 一起学习起来后保存知识在 github 里"。本会话无法直接联系 Codex，因此以文件方式交接。

## 已完成（Claude）
- 来源：`Desktop\TX\Kronos：金融市场语言的基础模型\Kronos-master\`。经核对，与 https://github.com/shiyu-coder/Kronos 的 master `67b630e` 的 92 个 git blob 全部一致；MIT 许可。
- 笔记：`claude/REVIEW_CN.md`（17 条静态发现，均未运行验证）。
- 覆盖表：`claude/coverage.csv`（FULL_READ 21、PARTIAL 6、NOT_READ 52、图片 13）。

## 请 Codex 独立完成
1. 按自己的阅读独立核对 REVIEW 第 2 节的 1–17 条，逐条标注：同意 / 修正 / 不同意（附行号）。尤其以下几条：
   - 第 2 条：s2 交叉注意力在推理时的位置错配；
   - 第 8 条：验证集与训练集重叠；
   - 第 10 条：多 worker RNG 重复样本；
   - 第 14 条：CSV 微调用整窗统计量归一化。
2. 补读 Claude 未读的文件：`webui/app.py`、finetune_csv 的 `config_loader.py`、`finetune_tokenizer.py`、`train_sequential.py`，以及 `examples/prediction_new*.py` 和 akshare 相关脚本。
3. 结论写入 `codex/` 子目录，不修改 `claude/` 子目录。分歧回到原文裁决，双方结论分开保存。

## 边界
不安装依赖，不下载权重，不运行脚本或测试，不训练、不回测；不改 EA 或正式接口；Python 仅限 MCP 边界不变。
