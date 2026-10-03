# 第七轮复审补充

本轮10场原生测试完成，9场严格核验通过，S5八月1场审计无效。通过的是对应场次的工程与账务核验，不是策略晋级或实盘验收。详细数值见本轮报告。

源码检查确认：当前选定S1至S6的6份源码，都有同一段10036返回码处理：清除本地管理待处理状态，并记录MANAGEMENT_REJECT。S5另外保存进展退出订单号，完整函数并非六份逐字相同。此次10场只在S5八月遇到一笔对应的10036/send_return=0事件；其他场次通过不证明这个竞态不存在。Scalping没有纳入这项共用函数推断，原SOP保持。

S5八月仓22实际被服务器TP平仓。另一笔紧急平仓请求未完成，不能把它登记为平仓成功；应以请求身份、持仓身份和历史成交核实“已由其他原因平仓”的终态。0.42是入场到原TP的品种价格差；该场Point=0.01，因此对应42个MT5 Point，不是0.42 Point。官方[10036定义](https://www.mql5.com/en/docs/constants/errorswarnings/enum_trade_return_codes)是指定仓位已经关闭。冻结EA和严格验证器均未在本轮修改。

保证金边界也需保留：部分净值快照的ACCOUNT_MARGIN为0.01 USD，按原始字段计算会得到数百万百分比的保证金水平。例：S1六月1000ms的原始快照记录balance=493.93、equity=493.63、margin=0.01。该记录来自EA调用ACCOUNT_MARGIN，不能当作真实券商保证金已经校准或500美元足以承受实盘的证明。原值和原报告保留；券商实际保证金参数、Stop Out规则及成本还需另行核验，不据此提高仓位。

下一轮先处理已定位的管理请求终态对账问题，再研究S2确认质量。Claude已收到本轮设计及部分结果／失败摘要，并提出复审意见；它没有读取本地源码或原始日志，也没有交付本轮EA补丁。具体S2实现规格与S5源码修复交接已保存在本地，尚未作为实际代码任务提交。后续须交付源码及原始证据后，由Claude按已确认分工修改、双方复审、Codex编译及新测试；不把本地交接文件存在当成代码完成。

修复版使用新candidate_id、源码与EX5哈希，同版本配对250/1000ms；核对信号、入场、手数、初始SL/TP及管理时序是否变化。原失败不转正，六月／八月仍属已使用开发数据。冻结修复候选后，另行登记未用于选择的数据和成本／延迟验证。保留本轮及第六轮全部恢复版本，不热更新实盘。

对应依据：COMMON_MANAGEMENT_SCOPE_REVIEW.json、independent_review/S5_AUGUST_DELAY1000_STRICT_FAILURE_REVIEW.json、BASELINE_DATA_COMPARABILITY_REVIEW.json、CLAUDE_RESULT_RESPONSE_OBSERVATION.json。包内路径映射见PORTABLE_PATH_MAP.json。
