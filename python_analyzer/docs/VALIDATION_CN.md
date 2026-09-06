# 1.0.0 交付验证记录

环境：Linux、Python 3；运行依赖仅标准库。本次没有 Windows MT5/MetaEditor，没有连接实盘、发送订单或调用付费 AI API。

## 实际执行

- `python -m unittest discover -s tests -v`：126项通过，完整交付包原始记录见 `validation-unittest.txt`。公开源码不带真实用户附件，相应6项端到端测试显式跳过；其余120项仍执行。
- `python -m compileall -q gsm_analyzer tools tests`：Python语法编译完成；不代表MQ5编译。
- 合成示例和真实FxPro旧回测均实际生成离线HTML、10份CSV和JSON，位于 `sample_reports/`。
- 实际执行诊断副本生成器，源文件SHA256锁定为 `554b61976a0b04a152c22b33767d264d4b42925b02375702bf69608326946185`；生成源码与依赖位于 `mql5/generated_v423/`，仍为未编译、未验证。

## 测试覆盖的具体风险

完整仓与分批成交重建、费用缺项与重复扣费、方向/生命周期冲突、无PositionID不猜单、金额与百分比DD分别计算、缺权益时序不造曲线、重复及跨运行混合、样本与真实数据身份、SHA不符隔离、时间/时区及最终段越界、原生报告资金/品种矛盾、未来K线和过早可用时间、未知同条件不构成可比证据、最终段冻结/曝光记录、诊断副本锚点/原件保护、MT5配对配置与不覆盖、CSV/HTML安全转义、离线CLI与导出一致性。

真实FxPro回归锚点：Scalping20仓64.39USD、Intraday4仓28.66USD、Swing1仓0.66USD；同次Combined25仓93.71USD。原生净值DD57.69USD/9.48%，原生余额DD9.32USD/最大相对1.72%，不互相替代。完整仓PF与原生PF差异原样保留。

## 尚未执行或证据不足

- Windows BAT仅静态检查；未在Windows实机执行。
- 生成的诊断MQ5未做真实MetaEditor编译，未提供假EX5。
- 未运行MT5控制/候选、真实Tick压力或最终OOS，不宣布候选改善、PASS或Champion。
- 没有2024-03开始的原始FxPro Tick覆盖证明、完整权益时序、服务器DST和最新候选原始测试档案。
- HTML结构、SVG输出、导出和脚本转义已经自动测试；本环境没有安装浏览器进行像素截图验证。

原冻结EA和SET未改写。全部本次Git变更仅在 `python_analyzer/`，原件副本按SHA256保留。测试通过只说明这些已测分析器行为通过，不等同于交易策略获批。
