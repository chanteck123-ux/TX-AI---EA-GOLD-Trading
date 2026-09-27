"""Compare preregistered, same-capital S-C01/control runs with strict SET/INI audit."""
import configparser
import csv
import json

from summarize_runs import ROOT, read, normalize, sha
from build_baseline_report import FROZEN_EX5, CRITICAL, FIELDS, table, evidence_links

CANDIDATE_EX5 = 'CB66003F414FE444F4F68B0CF1876F525D3BDFBBFDD717CAB34E2232E33EE44B'
AUDIT_INPUTS = {'InpAuditRunLabel', 'InpSignalFunnelFileName', 'InpTradeReviewFileName', 'InpSignalAuditFileName'}


def set_values(path):
    return {k: normalize(v) for line in read(path).splitlines() if '=' in line
            for k, v in [line.split('=', 1)] if k not in AUDIT_INPUTS}


def ini_values(path):
    cfg = configparser.ConfigParser(interpolation=None)
    cfg.read_string(read(path))
    return {(section, k): v for section in cfg.sections() for k, v in cfg[section].items()
            if (section, k) not in {('Tester', 'expert'), ('Tester', 'expertparameters'), ('Tester', 'report')}}


def fair(base, candidate):
    issues = []
    for key in ['Broker','Company','ServerHeader','Symbol','Period','CapitalUSD','Leverage',
                'HistoryQuality','Model','DelayMs','TerminalSHA256']:
        if base[key] != candidate[key]:
            issues.append(key)
    for r in (base, candidate):
        if CRITICAL.intersection(r['Flags']):
            issues.append('EVIDENCE_'+r['Run'])
    folders = [ROOT/'reports/runs'/r['Run'] for r in (base, candidate)]
    for ext, parser in [('.set', set_values), ('.ini', ini_values)]:
        if parser(folders[0]/(base['Run']+ext)) != parser(folders[1]/(candidate['Run']+ext)):
            issues.append(ext+'_CONDITIONS_CHANGED')
    if issues:
        raise ValueError('UNFAIR_COMPARISON: '+str(issues))
    return 'MATCH_EXCEPT_EXPERT_IDENTITY_AND_AUDIT_FILENAMES'


def trade_signature(row):
    path = ROOT/'reports/runs'/row['Run']/(row['Run']+'_TRADE_REVIEW.csv')
    if not path.exists() and row['Trades'] == 0 and row['CompleteTradeCostAudit']['Status'] == 'NO_TRADES':
        return []
    trades = list(csv.DictReader(read(path).splitlines()))
    keys = ('EntryTime','ExitTime','Direction','Entry','InitialSL','InitialTP','Volume','Profit','ExitReason','ZoneID')
    return [{key: t[key] for key in keys} for t in trades]


def main():
    rows = json.loads(read(ROOT/'reports/R_C00_RESULTS.json'))
    pairs = []
    for capital in (500, 1000):
        def select(digest):
            matches = [r for r in rows if r['Strategy'] == 'Scalping' and r['CapitalUSD'] == capital
                       and r['DelayMs'] == 0 and r['EX5SHA256'] == digest]
            if not matches:
                raise ValueError('EXPECTED_RUN_MISSING_'+str(capital)+'_'+digest)
            return max(matches, key=lambda r: r['Run'])
        base, candidate = select(FROZEN_EX5), select(CANDIDATE_EX5)
        condition = fair(base, candidate)
        delta = {k: candidate[k]-base[k] if candidate[k] is not None and base[k] is not None else None
                 for k in FIELDS[1:]}
        signatures_match = trade_signature(base) == trade_signature(candidate)
        pairs.append(dict(CapitalUSD=capital, FairConditions=condition, Control=base, Candidate=candidate,
                          Delta=delta, CompleteTradeSignaturesMatch=signatures_match))
    unchanged = all(p['CompleteTradeSignaturesMatch'] and all(v in (None, 0) for v in p['Delta'].values()) for p in pairs)
    verdict = 'REJECT_AS_CHAMPION_NO_OBSERVED_IMPROVEMENT' if unchanged else 'RESEARCH_FURTHER_NO_PROMOTION'
    output = dict(CandidateID='S-C01', Control='R-C00', Verdict=verdict, Comparisons=pairs,
                  OOS='NOT_UNTOUCHED', Stress='NOT_EXECUTED', NewChampions='NONE')
    (ROOT/'reports/S_C01_COMPARISON.json').write_text(json.dumps(output, ensure_ascii=False, indent=2), encoding='utf-8')
    content = []
    for p in pairs:
        data = [[name]+[r[k] for k in FIELDS[1:]] for name, r in [('R-C00',p['Control']),('S-C01',p['Candidate'])]]
        data.append(['Delta']+[p['Delta'][k] for k in FIELDS[1:]])
        detail = '<h2>'+str(p['CapitalUSD'])+' USD，同条件比较</h2>'+table(
            ['版本','净利润 USD','最大净值回撤 %','PF','完整交易数','胜率 %','拒单'],data)
        detail += '<p>原始文件：R-C00 '+evidence_links(p['Control'])+'</p><p>S-C01 '+evidence_links(p['Candidate'])+'</p>'
        detail += '<p>交易级别签名完全相同：'+str(p['CompleteTradeSignaturesMatch'])+'。核对时间、方向、区域、价格、SL/TP、手数、利润和退出原因。</p>'
        funnel = [[name]+[next(f for f in r['Funnels'] if f['SOP'].startswith('Scalping'))[k]
                         for k in ['ZonesDetected','ZonesDeparted','FirstTouches','HardSOPPassed','ConfidencePassed','GlobalGatePassed','RiskRejected','OrdersRequested','OrdersFilled']]
                  for name, r in [('R-C00',p['Control']),('S-C01',p['Candidate'])]]
        detail += table(['版本','区域','离开','首次触及','硬 SOP','评分/后续条件','总闸','风险跳过','下单请求','成交'],funnel)
        content.append('<section>'+detail+'</section>')
    explanation = ('S-C01 改变了一些区域事件，但两档资金的最终成交结果均未改善；保留控制版本，不升级 Champion。'
                   if unchanged else '结果有变化，但尚未通过全部样本、费用、样本外与压力门槛，不能升级 Champion。')
    page = '''<!doctype html><html lang="zh-CN"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>S-C01 距离排序实验</title><style>body{margin:0;background:#f5f6f7;color:#222;font:15px/1.7 "Microsoft YaHei",sans-serif;letter-spacing:0}
main{max-width:1400px;margin:auto;padding:24px}section{padding:20px 0;border-bottom:1px solid #ccd0d4}h1{font-size:26px}h2{font-size:20px}
table{border-collapse:collapse;width:100%;background:#fff}td,th{padding:8px;border:1px solid #ccd0d4;text-align:right;min-width:72px}
td:first-child,th:first-child{text-align:left}th{background:#e5eeeb}.scroll{overflow:auto;margin:16px 0}a{color:#075ca1;margin-right:12px}
.status{font-weight:700;color:#a22}@media(max-width:600px){main{padding:14px}h1{font-size:23px}}</style></head><body><main>
<h1>S-C01：Scalping 最近区域距离排序</h1><p class="status">'''+verdict+'</p><p>'+explanation+'''</p>
<p>FxPro GOLD，2026.01.05–2026.08.26，1:100，基于真实报价的每个 Tick，原始报告 100% 真实报价，0ms。</p>
<p>唯一策略变量是 Scalping 区域获取时的距离排序。固定 SL/TP、手数算法、风险预算和全部过滤参数不变；无保本、追踪或分批退出。</p>'''+''.join(content)+'''
<section><h2>审计结论与边界</h2><p>SET 和 INI 已逐项核对，仅排除 EA 文件身份、输出报告名称和审计文件名。源码、EX5、依赖和报告哈希见比较清单。</p>
<p>真实 MetaEditor 编译 0 错误、0 警告；10 项原生排序测试和 8,800 组比较检查通过；完整源码隔离测试通过。</p>
<p>既有区域固定和已用区域状态没有重写，因此不能声称完成了“持续选择当前最近可交易区域”的全部 SOP 修复。</p>
<p>0.01 手佣金估算比实测往返费用少 0.01 USD 的问题仍明确保留为待修正风险项。计划风险不是保证实际亏损上限。</p>
<p>目前样本不足。区间已被查看，不是 untouched OOS。延迟、成本及参数压力测试未执行。本实验不能晋级，无新 Champion ZIP。</p>
<p><a href="S_C01_COMPARISON.json">完整对比与哈希</a><a href="R_C00_BASELINE_CN.html">四组基准及八档资金测试</a>
<a href="../research/S-C01_PREREGISTRATION.md">事前登记</a><a href="../research/S-C01_REVIEW.md">代码与反方审查</a></p>
<p>数据、结构及本地链接检查不等于浏览器视觉验收；本页尚未完成视觉验收。</p></section></main></body></html>'''
    (ROOT/'reports/S_C01_REPORT_CN.html').write_text(page, encoding='utf-8')
    (ROOT/'reports/S_C01_SHA256.txt').write_text('\n'.join(
        sha(ROOT/path)+'  '+path for path in ['reports/S_C01_REPORT_CN.html', 'reports/S_C01_COMPARISON.json',
                                             'src/GSM_FxPro_S_C01.mq5', 'src/ZoneRank.mqh',
                                             'src/StrictRisk.mqh', 'src/RiskMath.mqh'])+'\n', encoding='ascii')
    print(json.dumps(dict(Verdict=verdict, Deltas=[p['Delta'] for p in pairs],
                         TradeSignaturesMatch=[p['CompleteTradeSignaturesMatch'] for p in pairs]),ensure_ascii=False))


if __name__ == '__main__':
    main()
