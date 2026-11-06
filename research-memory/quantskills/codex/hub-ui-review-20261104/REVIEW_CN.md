# QuantSkills 页面与评分呈现静态审核

2026-11-04。全文读取site/app.mjs、index.html、styles.css以及evaluation-view.test.mjs，范围和哈希见coverage.json。未启动网站或执行测试。

1. 资产卡片使用createElement/textContent，资产链接由受限名称重新生成GitHub URL，未直接插入资产摘要HTML。这是实际代码防护，不能扩大为整站安全审计通过。
2. relationshipModel按profile名称推导上游/下游，不判断版本范围、适配器路径或时间语义。因此“Upstream providers / Downstream consumers”只是候选关系，不能当可直接运行的兼容性证明。
3. attachEvaluations保留current_commit、evaluated_commit_sha与source_publication，但renderAssetCard显示分数时没有展示这些字段，也不据current_commit=false取消recommended筛选。旧提交的高分可能在界面中缺少版本过期提示；这是源码链路结论，未统计当前数据有多少过期分数。
4. 前端“精选分类内前25%”是固定文本，筛选函数仅依赖evaluation.recommended，不重算排序政策。若绑定政策未来改变，展示说明需同步；当前未核对上游policy全文，不能断言现有说明已错误。
5. 页面加载仅检查snapshot_id格式，未重算快照内容哈希，也未调用完整schema验证；信任构建发布链，而非浏览器端完整性认证。build的静态摘要核验见前批。
6. pending接口隐藏端点；缺interface_status默认published，只有在可信构建契约下才应解释状态，不能对任意外部JSON直接当发布证明。
7. 查询参数和筛选状态可保存URL，runtime与platform有兼容别名；错误时显示加载失败，空结果有提示。HTML标签、焦点样式与响应式布局已静态读取，但未浏览器验收，不宣称可访问性测试通过。
8. 已读evaluation测试覆盖摘要/绑定/计数/精选过滤；这是测试代码内容，不是本次执行通过。用户EA评分仍遵循35/25/20/10/10，与上游Shadow Core独立。

本批新增4份。其余测试、长JSON语义、图片和完整README等缺口保持未完成；Claude独立记录另计。
