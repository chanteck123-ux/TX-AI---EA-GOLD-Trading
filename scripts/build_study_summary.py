"""Compact GitHub research summary; raw private terminal artifacts stay local."""
import json
from summarize_runs import ROOT,read
from build_study_report import choose,FIELDS


def value(v):
    if v is None: return 'N/A'
    return f'{v:.2f}' if isinstance(v,float) else str(v)


def table(items):
    return '\n'.join(['| 策略/版本 | 净利润 USD | 最大净值 DD % | PF(完整净持仓) | 完整交易数 | 胜率 % | 拒单 |',
                      '|---|---:|---:|---:|---:|---:|---:|']+
                     ['| '+name+' | '+' | '.join(value(row[k]) for k in FIELDS)+' |' for name,row in items if row])


def main():
    rows=json.loads(read(ROOT/'reports/RESEARCH_RESULTS.json'))
    validation=json.loads(read(ROOT/'reports/RESEARCH_VALIDATION.json'))
    parts=['# FxPro GOLD 3-SOP 本轮研究交付摘要',
           '**研究版，未批准实盘。Scalping / Intraday / Swing / Combined 合格Champion均为NONE。**',
           '仅Codex开发；研究分支，正式Champion及冻结V4.00/R-C00/R-C01/S-C01未改动。',
           '主条件：2000USD、1:100、计划风险1%/3%、FxPro GOLD、2026.01.05至2026.08.26（结束日不含），Model4，100%真实报价。已查看区间只是开发数据。',
           '## 修正后的OFF工程控制',
           table([(lane,choose(rows,'CONTROL_FINAL',lane)) for lane in ('Scalping','Intraday','Swing','Combined')]),
           '四组逐笔复现冻结R-C01。PF以完整持仓全部费用计算，原生PF单独留在CSV/HTML；没有亏损持仓时有限PF不成立。',
           '## 独立实验',
           table([(ident,choose(rows,ident,lane)) for ident,lane in [('S_C02','Scalping'),('I_C01','Intraday'),('I_C02_FIX2','Intraday'),('W_C01','Swing'),('C_C01','Combined')]]),
           'S-C02增加63笔却净利润降低183.74USD，拒绝。I-C01/W-C01取消每日上限未增加成交。尾仓主结果较控制少7.16USD；组合实际重测也低于控制。默认Scalping EMA ON、Intraday runner OFF。',
           'Swing单笔MFE48.94USD、MAE14.36USD，最终净利润0.66USD：净值DD包含浮盈回吐，不能误写为从入场起本金亏损47.62USD。',
           '## 配对原生延迟',
           table([(r['CandidateID']+' '+('NativeRandom' if r['DelayMs']==-1 else str(r['DelayMs'])+'ms'),r)
                  for r in rows if r['Strategy']=='Combined' and r['DelayMs']!=0]),
           '原生随机不是随机10-50ms，且两次原生随机回放没有可控制的同一路径种子。固定10/25/50ms与0ms控制单列。',
           '## 资金及参数诊断',
           table([(r['CandidateID']+' '+r['Strategy']+' USD'+str(r['CapitalUSD']),r) for r in rows
                  if r['CapitalUSD'] in (500,5000) or r['CandidateID'].startswith('I_C02_NEIGHBOR')]),
           '500USD只做最低手数适配；5000USD只做合法拆仓诊断，不混入主资金成绩。参数未进入有效追踪阶段时，相同结果不是稳健性证明。',
           '5000USD原生尾仓实际将0.04手减去0.02手，单次返回10009，按持仓ID归并后仍为4笔；净利润100.48低于同资金控制114.80。正常拆仓不等于券商故障测试已完成。',
           '## 真实验证',
           '- '+validation['CompileResult'],
           f"- Python单元/回归测试：{validation['PythonTests']}，失败{validation['PythonFailures']}。",
           '- 原生MQL规则20020项、真实管理器+模拟服务器24项，均0失败。',
           '- 修复前两次历史恢复故障记录保留为无效工程证据；原生探针证实需要显式HistoryOrderSelect。',
           '- 真实Tick恢复探针与控制逐笔相同；这是内存清空后持久状态恢复，不是OS强杀测试。',
           '- 成本压力是固定成交路径后处理，不冒充改变点差后的原生行情重测。',
           '- 按持仓ID合并全部费用及分批成交，分批出场不重复计交易数。',
           '## 未通过与续做',
           '样本不足、组合项目净值Recovery未超过3、未来OOS及真实执行/并发风险证据未完整。保留基线，不制作Champion ZIP。',
           'OOS已按FxPro日历预登记：服务器2026.09.08至2027.03.08（结束日不含），未来行情/成绩未查看，不早停、不调参、不拿训练交易凑数。',
           'NativeRecovery与文档分母存在原生观测差异，原值、手算余额Recovery、项目净值Recovery分开保留。',
           '逐Tick保证金、实际三仓重叠、分策略组合净值DD、OS故障恢复和真实券商部分成交故障仍须验证。',
           '## 文件与哈希',
           '- MQ5 SHA256: `'+validation['SourceSHA256']+'`',
           '- EX5 SHA256: `'+validation['EX5SHA256']+'`',
           '- `RESEARCH_CONFIG_INDEX.json` 索引精确SET/INI；`RESEARCH_COMPARISONS.json`记录公平比较。',
           '- `RESEARCH_VALIDATION.json`与本地交付SHA256清单记录完整依赖/报告证据。',
           '- 原始MT5报告、日志和EX5在本地研究交付目录；GitHub不上传账户凭据、运行缓存或失败ZIP。',
           '- [研究草稿PR #5](https://github.com/chanteck123-ux/TX-AI---EA-GOLD-Trading/pull/5)，未合并正式分支。']
    (ROOT/'reports/RESEARCH_SUMMARY_CN.md').write_text('\n\n'.join(parts)+'\n',encoding='utf-8')
    print('CHINESE_RESEARCH_SUMMARY_WRITTEN')


if __name__=='__main__': main()
