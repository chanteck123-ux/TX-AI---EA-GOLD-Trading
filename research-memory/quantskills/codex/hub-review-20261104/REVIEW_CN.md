# QuantSkills 导航脚本续审 — 2026-11-04

Codex：4份文件全文静态读取；site/catalog.json仅结构查询，不算全文语义审核。源码、测试均未执行。与20261103批次合并，scripts目录7份脚本已全部全文读取；测试与网站其余内容仍未完成。

## H09：合法空接口与元数据计划不兼容

build-github-metadata-plan.mjs的profileIds直接读取asset.interface.inputs/outputs。desired对每项资产调用它；buildMetadataPlan遍历全部snapshot.assets，没有跳过pending接口。snapshot-contract允许pending-maintainer且interface=null，而当前site/catalog.json结构查询得到218资产中217项为pending-maintainer且interface=null。若传入含此类资产的有效快照，并且前置仓库/HEAD检查通过，将到达空值属性访问异常。没有运行脚本或请求上游API。metadata-plan.test.mjs只使用fixture，未覆盖该空值案例。

应吸收：目录准入合法状态必须被后续消费者完整处理；不能只依赖全接口fixture。后续如获开发任务，应选择跳过缺接口的profile标签或显式说明不能生成，而不能暗改目录状态。

## H10：展示日期与快照身份不同

render-readme.mjs的snapshotDate先从snapshot_id找日期，再找model.built_at，最后使用当前UTC日期。标准snapshot_id是sha256哈希，buildCatalogModel没有传出built_at，因此通常走当前日期。相同快照跨天重建会改变README中的“快照更新”日期。构建跨UTC午夜也可能令verifyBuild重新渲染的内容不同；此为静态路径推断，未复现。

图片存在性也依赖本地assets目录，链接指向远端main；快照摘要不等于展示图片内容的固定版本。应保存实际构建时间、原始数据时间与图片版本，不用一个日期替代。

## H11：展示与来源约束

escape仅处理换行及表格竖线；不处理所有HTML/Markdown语法。是否构成安全影响取决于最终渲染平台及其清洗，不直接宣称已存在可利用脚本执行。metadata计划只读取GitHub并生成本地计划，不直接修改仓库；这与执行计划必须分开。

本批保留问题及定位，没有修改上游源码、用户EA、正式接口或Claude目录。项目整体全文审核仍未完成。
