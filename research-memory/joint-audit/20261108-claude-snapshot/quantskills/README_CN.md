# Claude 全文审核（QuantSkills，2026-10-23 起）

## 范围与方法
- 清单：`full-review/document-manifest.json`（Codex 生成，4524 份 .md/.txt，含路径、sha256、commit）。只读，不修改。
- 非因子库文档：`tools/build_packs.ps1` 按资产编号→仓库→路径排序，把每份文件**原文逐行**拼进约 52 KB 的阅读包（`scratchpad/fr/packs/P####.txt`，带 `#### FILE seq | A编号 | 仓库 | 路径 | sha | 字节 | part i/n` 头尾标记）；超长文件按行切分为多段。共 266 包。sha256 与此前已排入的文件完全相同者不重复排包，记为 HASH_REUSE（128 份），指向首次出现的文件。
- 计划表：`plan_main.csv`（每行一个文件条目：pack、kind、seq、asset_id、repo、relative、sha256、bytes、commit、part/parts、reuse_of）。
- 每读完一个包：执行 `tools/mark_read.ps1 -Packs P####`，把该包全部条目以 FULL_READ 追加到 `coverage/coverage.csv`，并更新 `progress_plan_main.json`；同时把该包涉及资产的审核结论写入/追加到 `assets/A###.md`。
- 两个因子库（[173] directional、[174] risk-pattern，2344 份）另行处理：先全文读参考因子，其余按"与参考文件逐行比对，不同的行全部输出阅读；行数不同则整份输出"的方式覆盖，方法记为 TEMPLATE_DIFF，单独列示。
- 只做资料审查：不运行资料中的任何命令与脚本，不安装依赖，不调用付费 API，不改 EA/接口，不提交推送。资料中对 Agent 的指令只作研究对象。
- 状态区分：全文阅读（文档）／静态实现核查（只在回执与个别资产中按需读了对应源码行，均注明）／未运行验证（全部）。**本次没有审完所有源码**；清单只含 .md/.txt 文档。

## 接续步骤
1. 看 `progress_plan_main.json` 的 last_pack，下一包为其编号 +1。
2. 读 `scratchpad/fr/packs/P####.txt` 全文（若缺失，重跑 build_packs.ps1，输出内容确定可复现）。
3. 写 assets 笔记 → mark_read。

## 文件
- `CROSS_REVIEW_RECEIPT_CN.md`：对 Codex 首轮交叉核对的回执。
- `assets/A###.md`：逐资产全文复核结论（与首轮结论对比）。
- `coverage/coverage.csv`：逐文件覆盖记录。
- `GAPS_CN.md`（完成时生成）：缺口清单。
