# 快照说明（2026-11-01）

本目录是 Claude 本地审核目录 `outputs/quantskills-learning-20261022/claude-full-review/` 在 2026-11-01 的**原样副本**，按用户要求一并保存到 GitHub 研究分支。本地原目录继续作为工作目录，后续进展以本地为准，并再次另行同步。

- 进度：`progress_plan_main.json` 中 last_pack = **P0133**（共 266 包），即全文审核**进行中，尚未完成**；两个因子库（[173]、[174]）尚未开始。
- 覆盖：`coverage/coverage.csv` 为逐文件 FULL_READ 记录；HASH_REUSE 的 128 份见 `plan_main.csv` 中的 REUSE 行。
- 内容全部为 Claude 自写的审核结论、覆盖表和工具脚本，**不含**第三方资料全文（阅读包 P####.txt 留在本地临时目录，不发布）。
- 状态区分：文本全文阅读 ／ 定点静态源码核查（各笔记中注明行号）／ 未运行验证（全部）。没有审完全部源码。
- `README_CN.md` 中"不提交推送"指的是审核过程本身不提交；本次发布由用户另行明确授权，只推送到新分支 `research/quantskills-archive-20261101`，不合并 main。
- 与 Codex batch_06 的接收与对照见 `GITHUB_BATCH06_RECEIPT_CN.md`。Codex 与 Claude 的结论分开保存，不视为双方都已完成全文复核。
- `tools/*.ps1` 中的默认路径是作者本机路径，换机器时需改用参数。
