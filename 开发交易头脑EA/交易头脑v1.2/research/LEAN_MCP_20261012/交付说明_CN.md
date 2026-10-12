# 实时研发监控交付 — 2026-10-12

Python MCP v1.2.0由Claude写，Codex独立复审与验证。监控源码修改、编译日志、回测和优化阶段记录、项目MT5审计文件。Python不调度研究、不下单，MQL5自行执行风控。

已完成：31项测试中30通过、1项因符号链接创建权限跳过；目录联接拒绝已通过。真实stdio握手、六工具及异常54 checks全部通过。源码哈希与Claude TOOLS_READY逐项匹配。失败记录保留。

客户端：Codex全局配置和Claude项目.mcp.json已经写入。当前会话尚无监控工具，客户端加载仍待核验。保存工作后重新加载MCP／重启客户端，然后调用health；响应tb-lean-monitor v1.2.0才记录已连接。不要把SDK测试客户端视为Codex或Claude实际加载成功。

实时含义：AI工作期间按需调用取得当前状态、哈希及前后日志增长；没有后台自动写代码。优化阶段由执行方写research/STAGES.jsonl；无记录时报告NO_RECORD。文件存在不证明测试完成。

LEAN：实际引擎烟测启动失败，Windows应用控制0x800711C7阻止QuantConnect.Messaging.dll。未运行策略、未产生新LEAN成绩，也未改Windows安全政策。需获允许的运行环境或正式安全政策处理后才能继续引擎验证。

七策略迁移计划：S4保留版→Scalping S20→S1/S2/S3/S5/S6。七个参考源码哈希已核对，计划不等于完整迁移。原MT5恢复版本及Scalping核心规则保留。

完整程序在本包monitor；本机已安装依赖的实际入口为work/repair_research/lean_mcp_20261012/monitor/server.py，专用.venv未打包。配置样例中的路径对应本机，异机需调整并安装锁定依赖。

服务器测试证据：CODEX_FINAL_REVIEW.json、CODEX_UNIT_TEST_V1_2.log、CODEX_STDIO_V1_2.json。引擎失败证据：INTAKE_STATUS.json和lean_probe_01/console.log。评分N/A。
