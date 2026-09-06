# 放入自己的数据

把 `manifest.template.json` 复制为 `manifest.json`，按真实资料填写。相对文件路径从 manifest 所在目录开始计算。资料未取得时保留未知，不改用示例顶替。

双击上层 `RUN_ANALYZER.bat`，或运行：

```bat
py -3 run.py analyze --manifest input\manifest.json --output output\my_run
```

每份清单只对应一次运行。不要混合不同测试、账户性质、品种或独立策略成绩。最终段文件应在外部按冻结区间单独导出，并遵守主说明中的曝光登记流程。

本目录的个人输入默认不进入Git。完整字段映射见 `../docs/DATA_SCHEMA_CN.md`。
