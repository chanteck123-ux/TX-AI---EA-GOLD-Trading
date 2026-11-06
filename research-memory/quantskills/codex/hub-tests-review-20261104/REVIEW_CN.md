# QuantSkills 测试与发布工作流审核

2026-11-04。新增17份全文静态读取，逐文件SHA256与行范围见coverage.json。结合前三批，7份scripts与18份顶层test.mjs均已全文读取；并非测试已执行。累计34份不同文本，不包含长JSON全文或图片。

## 证据边界

build/no-fallback/site-filter/site-accessibility/workflow-policy等测试大量采用源码正则断言。出现关键词只能证明文本特征，不能证明确定性、分类拒绝、可访问性或权限行为完整正确。例如build测试的deterministic断言只查stageAndPromote与catalog.snapshot字样，未跨时间比较输出；前批已指出日期回退问题。

failure-injection修改资产后未重新计算snapshot_id，因此可能首先因哈希不符被拒绝，不能单独证明对应语义校验分支被覆盖。catalog-admission-security另有重算摘要的变异测试，应分开看。

site-security使用FakeNode验证文本/链接行为，有针对性但并非浏览器执行测试；无论源码测试多少，不能据此宣称生产安全或页面无障碍通过。fixture覆盖结构接口与自然语言模式，元数据计划的pending-null缺口仍存在。

## 工作流

daily-build实际是手动workflow_dispatch，不是定时。snapshot_url直接插入run命令文本；作为可控输入应通过环境变量传递并核对URL边界，不能把双引号包装视为完整shell隔离。这里仅记录静态构造风险，没有执行或构造攻击。

下载步骤先比较snapshot_id字段；随后build才执行完整快照内容摘要及结构检查。不能只以第一步标签称内容已验证。

两个workflow分别用Node22和Node24，registry checkout未固定提交，actions使用版本tag；重现需要登记实际解析版本与registry提交。Pages工作流构建的registry快照未必等于上一次仓库README已存快照；应核对最终发布工件身份。没有触发任何Actions。

中英文模板都明确目录元数据不构成质量/收益/生产保证，模板引用LICENSE，但当前根目录无该文件。应保留许可缺口，不自行假设开源授权。

## 尚未完成

完整中英README、长JSON及剩余文档、33份图片仍需内容审核；相关资产仓库4,524份是另一覆盖集合。Claude独立审核回执尚无确认。本次不改变EA接口或运行状态。
