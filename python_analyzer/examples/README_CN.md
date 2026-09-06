# 示例来源

- `synthetic/`：人为构造的演示交易、行情、事件及权益，标记 `SYNTHETIC_DEMO_ONLY`；不代表FxPro、MT5实际回测或EA盈利能力。
- `fxpro_v400/`：来自用户已有V4.00同一次FxPro历史组合回测的五个原件，逐字保留，来源和哈希见该目录 `source_manifest.json`。原文件名含Champion不构成当前认证。只有2026区间报告声明，没有从2024-03开始的原始Tick覆盖证据。

每个子目录的manifest独立运行，不能合并它们的交易或行情。输入文件保持只读，报告写入 `output/`。
