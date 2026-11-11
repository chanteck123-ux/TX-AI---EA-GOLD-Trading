# L028–L030 第 4 层：其余 Algorithm.CSharp 示例（续）（Claude，2026-11-08）

**方式**：同 L025–L027（`tools/next_batch.sh` + `tools/mark_list.ps1`），只读，没有编译，也没有运行。

## 一、覆盖范围（FULL_READ 83 个）
- L028：30 个，L029：28 个，L030：25 个；清单以 coverage 表中 batch 列为准。
- 主要是期权组合筛选（OptionStrategyFilteringUniverse* 系列）、预热与 OnWarmupFinished、基础模板、框架 Alpha/组合构建（RiskParity、MeanReversion）、容量测试（CapacityTests）、自定义数据、拆股分红、Benchmarks。

## 二、与 V1.2 有关的少量发现（静态阅读）
1. **算法主循环有时间上限**（TrainingInitializeRegression）：`algorithm-manager-time-loop-maximum` 配置项限制单个时间步的耗时；示例用 `Train()` 睡眠超时，预期状态为 RuntimeError（另有"漏桶"额度）。对 V1.2：LEAN 研究中如果在 OnData 内做耗时的模型推理，可能被引擎直接终止。
2. **在 Initialize 之外调用 SetWarmUp 会报 RuntimeError**（WarmUpAfterInitializeRegression，GH 4939）。
3. **无效代码下单返回 Invalid，不抛异常**（StringToSymbolImplicitConversion：`MarketOrder("PEPE", 1)` 状态为 Invalid）。V1.2 跨引擎核对时，品种代码映射错误在 LEAN 中可能只表现为"没成交"，需要显式检查订单状态。
4. `SetCash("EUR"/"BTC"/"ETH", …)` 添加的非 USD 现金计入起始资金（GH 1859）。
5. 风控模型可以叠加：`AddRiskManagement(MaximumDrawdownPercentPortfolio(0.02))` 与 `MaximumUnrealizedProfitPercentPerSecurity(0.01)` 同时生效；另有按行业的最大暴露模型 `MaximumSectorExposureRiskManagementModel(0.1)`。V1.2 不使用框架，只作参考。
6. `CustomSignalExport` 示例把组合目标 POST 到 `http://localhost:5000/`，属于信号导出示例；V1.2 规定 Python 只做 MCP 监控，信号导出不在本项目范围内。
7. `ScheduledQueuingAlgorithm.cs` 文件里的类名是 `TachyonDynamicGearbox`，与文件名不一致（只是命名问题）。`EmptyEquityAndOptions400Benchmark` 的注释写"500 个股票"，类名写 400，列表约 400 个，属文字不一致。
8. 其余为第 4 层内容，只记录已读。

## 三、进度
- Algorithm.CSharp 剩余未读约 495 个（按大小排序，后面的文件更长）。
