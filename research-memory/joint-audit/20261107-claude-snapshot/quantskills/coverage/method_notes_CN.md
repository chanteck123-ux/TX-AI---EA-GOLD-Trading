# 覆盖方法补充说明（与 coverage.csv 配套）

coverage.csv 中，同一个包的所有文件都记为 FULL_READ。下列文件的阅读方式需要单独说明，以免被误读为"逐字阅读"：

| 包 | 文件 | 实际方法 | 说明 |
|---|---|---|---|
| P0029 | FILE 348 strategy_backtest_report.md 第 108、109、128 行 | 已读内容的前缀，经程序核验 | 这三行是 IS 段的 equity、drawdown 曲线，经 PowerShell 逐字节比较，确认分别是已逐字阅读的第 34、35、54 行的前缀；第 110 行月度数据逐项比较，只有 2025-12 一项不同（不完整月份）。 |
| P0044 | FILE 478 开发产物/SKILL.md（A42） | 与 FILE 474 diff | 197 行中只有第 2 行 name 不同，其余逐字相同；474 已逐字阅读。 |

除表中所列，其余文件都是逐行阅读。hash 完全相同的文件按 HASH_REUSE 记录（见 plan_main.csv 的 REUSE 行）。

## P0055–P0056 FILE 582（A56 requirements-lock.txt）
锁文件 102,514B。用 PowerShell 逐行分类：88 行非哈希内容（注释、`包==版本 \`、`# via` 来源）全部人工阅读；其余每行均以正则 `^\s+--hash=sha256:[0-9a-f]{64}( \)?$` 校验通过（0 例外）。哈希值本身不作语义阅读，记录为"结构全量核验+语义行全读"。

## P0119 FILE 1202（A108 skill/SKILL.md）
与 FILE 1197（根目录 SKILL.md，已逐字阅读）的 hash 不同。经 bash `diff` 逐行比较，179 行中只有第 2 行 frontmatter 的 `name` 不同（graham-netnet-screener 对 alpha-ncav-graham），其余逐字相同。记为"公共部分全文读 + 全部差异核查"。
