"""Publish a frozen, four-lane control audit; never infer a missing result."""
import csv
import html
import json
from pathlib import Path

from summarize_runs import ROOT, read, sha

LANES = ('Scalping', 'Intraday', 'Swing', 'Combined')
FROZEN_EX5 = 'BB77B5D947614A9D1796E02E2F3382945C1FCAFD5DF68EFF1FF8D387368957EB'
FROZEN_SOURCE = '989F19C997F5B095A67727BF0C88492B3777F2CCF2682A02D954DBBE18CAE19A'
CRITICAL = {'NATIVE_TEST_CONDITIONS_MISMATCH', 'BINARY_ARCHIVE_MISSING',
            'TERMINAL_VERSION_CHAIN_INCOMPLETE', 'SET_REPORT_MISMATCH',
            'TESTED_SOURCE_DEPENDENCY_SNAPSHOT_INCOMPLETE', 'REAL_TICK_COVERAGE_NOT_100'}
FIELDS = ['Strategy', 'NetProfitUSD', 'MaxEquityDDPct', 'ProfitFactor', 'Trades', 'WinRatePct', 'Reject']
FUNNEL_FIELDS = ['ZonesDetected', 'ZonesDeparted', 'FirstTouches', 'CandlePatternsDetected',
                 'ChartPatternsDetected', 'HardSOPPassed', 'ConfidencePassed', 'GlobalGatePassed',
                 'RiskRejected', 'OrdersRequested', 'OrdersFilled', 'OrdersRejected']


def select_results(rows):
    candidates = [r for r in rows if r['EX5SHA256'] == FROZEN_EX5
                  and r['SourceSHA256'] == FROZEN_SOURCE and r['DelayMs'] == 0]
    selected = []
    for lane in LANES:
        matches = [r for r in candidates if r['Strategy'] == lane and r['CapitalUSD'] == 500]
        if not matches:
            raise ValueError('BASELINE_MISSING_'+lane)
        result = max(matches, key=lambda r: r['Run'])
        if CRITICAL.intersection(result['Flags']):
            raise ValueError('BASELINE_EVIDENCE_FAIL_'+lane)
        selected.append(result)
    capacity = {}
    for row in candidates:
        if row['CapitalUSD'] == 500:
            continue
        key = (row['Strategy'], row['CapitalUSD'])
        if key not in capacity or row['Run'] > capacity[key]['Run']:
            capacity[key] = row
    return selected, sorted(capacity.values(), key=lambda r: (LANES.index(r['Strategy']), r['CapitalUSD']))


def fmt(value):
    if value is None:
        return '未定义'
    return f'{value:.2f}' if isinstance(value, float) else str(value)


def table(headers, rows):
    return '<div class="scroll"><table><thead><tr>'+''.join('<th>'+html.escape(h)+'</th>' for h in headers)+\
           '</tr></thead><tbody>'+''.join('<tr>'+''.join('<td>'+html.escape(fmt(c))+'</td>' for c in r)+
                                        '</tr>' for r in rows)+'</tbody></table></div>'


def evidence_links(row):
    run = row['Run']
    return ' '.join(f'<a href="runs/{run}/{html.escape(name, quote=True)}">{label}</a>'
                    for name, label in [(run+'.htm', 'MT5 原始报告'), (run+'.set', 'SET'),
                                        (run+'.ini', 'INI'), ('AUDIT.json', '审计'), ('RUN.json', '运行记录')])


def build():
    rows = json.loads(read(ROOT/'reports/R_C00_RESULTS.json'))
    baseline, capacity = select_results(rows)
    report = ROOT/'reports/R_C00_BASELINE_CN.html'
    inventory = dict(Status='BASELINE_AUDITED_NOT_CHAMPION', SourceSHA256=FROZEN_SOURCE,
                     EX5SHA256=FROZEN_EX5, CapitalUSD=500, Leverage=100, Broker='FxPro',
                     OOS='ALREADY_VIEWED_NOT_UNTOUCHED', DelayStress='NOT_EXECUTED',
                     StrategyChampions={lane: 'NONE' for lane in LANES},
                     Baseline=baseline, Capacity=capacity)
    (ROOT/'reports/R_C00_BASELINE_INVENTORY.json').write_text(
        json.dumps(inventory, ensure_ascii=False, indent=2), encoding='utf-8')
    with (ROOT/'reports/R_C00_BASELINE_SUMMARY.csv').open('w', newline='', encoding='utf-8-sig') as out:
        writer = csv.DictWriter(out, fieldnames=FIELDS+['CapitalUSD', 'RecoveryEquity', 'Run'], extrasaction='ignore')
        writer.writeheader()
        writer.writerows(baseline)
    overview = table(['策略', '净利润 USD', '最大净值回撤 %', 'PF', '完整交易数', '胜率 %', '券商拒单'],
                     [[r[k] for k in FIELDS] for r in baseline])
    sections = []
    for r in baseline:
        active = [f for f in r['Funnels'] if r['Strategy'] == 'Combined' or f['SOP'].startswith(r['Strategy'])]
        funnels = table(['策略']+FUNNEL_FIELDS,
                        [[f['SOP']]+[int(f[k]) for k in FUNNEL_FIELDS] for f in active])
        diagnoses = ''.join('<p>'+html.escape(f['SOP']+': '+f['ZeroTradeDiagnosis'])+'</p>' for f in active)
        sections.append(f'<section><h2>{r["Strategy"]} 基准</h2>{evidence_links(r)}{funnels}{diagnoses}'+
                        '<p>收益率 '+fmt(r['ReturnPct'])+'%；净值恢复因子 '+fmt(r['RecoveryEquity'])+
                        '；成本后每笔期望 '+fmt(r['ExpectedPayoff'])+' USD。</p><p>已观察到的最低技术资金门槛：'+
                        fmt(r['MinimumTechnicalEquityAtRejectedSetups'])+' USD。只是该次最小手数风险计算下界，'+
                        '不是建议入金，也不是通过绩效验证的最低资金。</p></section>')
    cap_table = table(['策略', '资金 USD', '净利润 USD', '最大净值回撤 %', 'PF', '交易数', '胜率 %', '拒单', '恢复因子'],
                      [[r['Strategy'], r['CapitalUSD']]+[r[k] for k in FIELDS[1:]]+[r['RecoveryEquity']] for r in capacity])
    cap_links = ''.join('<p>'+html.escape(r['Strategy']+' USD'+str(r['CapitalUSD']))+': '+evidence_links(r)+'</p>' for r in capacity)
    cost_rows = []
    for r in capacity:
        audit = r.get('CompleteTradeCostAudit', {})
        if audit.get('Status') != 'RECONCILED_COMPLETE_POSITIONS':
            continue
        s = audit['NetStats']
        cost_rows.append([r['Strategy'], r['CapitalUSD'], s['AverageWinUSD'], s['AverageLossUSD'],
                          s['RealizedRR'], s['ExpectancyNetUSD'], audit['CommissionUSD'],
                          audit['MaximumFeeShortfallUSD'], audit['MaximumStopAdversePrice']])
    costs = table(['策略', '资金 USD', '每笔净盈利', '每笔净亏损', '实际净盈亏比', '净期望 USD',
                   '总佣金 USD', '最大佣金估算差额 USD', '最大止损不利价差'], cost_rows)
    proof = table(['策略', '源码 SHA256', 'EX5 SHA256', 'SET SHA256', '报告 SHA256'],
                  [[r['Strategy']]+[r[k] for k in ('SourceSHA256','EX5SHA256','SETSHA256','ReportSHA256')] for r in baseline])
    text = '''<!doctype html><html lang="zh-CN"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1"><title>FxPro R-C00 基准审计</title>
<style>body{margin:0;color:#202124;background:#f5f6f7;font:15px/1.65 "Microsoft YaHei",sans-serif;letter-spacing:0}
main{max-width:1440px;margin:auto;padding:24px}header,section{padding:20px 0;border-bottom:1px solid #c9ced3}
h1{font-size:27px;margin:0 0 8px}h2{font-size:20px;margin:0 0 12px}p{margin:8px 0}.status{color:#a82929;font-weight:700}
.scroll{overflow-x:auto;margin:16px 0}table{border-collapse:collapse;width:100%;background:white}
th,td{padding:9px 12px;border:1px solid #d3d8dd;text-align:right;overflow-wrap:anywhere;min-width:74px}
th{background:#e8edef;color:#263d3b}td:first-child,th:first-child{text-align:left}a{color:#065da8;margin-right:12px}
code{overflow-wrap:anywhere}.muted{color:#50565b}@media(max-width:600px){main{padding:14px}h1{font-size:23px}}
</style></head><body><main><header><h1>FxPro 黄金 R-C00 基准审计</h1>
<p class="status">四条新 Champion 状态均为 NONE。研究基准，不是实盘批准。</p>
<p>FxPro Markets Ltd. / FxPro-MT5 Demo · GOLD · 500 USD · 1:100 · Build 6182</p>
<p>2026.01.05–2026.08.26（结束边界不含当天后续报价）；基于真实报价的每个 Tick；原始报告为 100% 真实报价；0ms。</p>
<p>排序固定：净利润 → 最大净值回撤 → PF → 完整交易数 → 胜率 → 拒单。</p></header>'''+overview+'''
<section><h2>如何解读</h2><p>每单计划止损风险上限为净值 1%，账户合计上限 3%；手数向下取整，最低 0.01 手超预算则跳过。
Scalping 只使用固定 SL/TP，未加入保本、追踪、分批或尾仓。Intraday 新尾仓模块尚未实现。</p>
<p>零成交的净利润与回撤可以为 0，但 PF、胜率及恢复因子没有统计意义。没有发送订单时，拒单 0 不是执行压力测试通过。</p>
<p>基准继续保留原版入场、过滤器及日内次数设置；风险标准化不等于已解决漏单。漏斗是各模块事件计数，不是逐级严格子集，也不是独立交易机会数。</p>
<p>V4.00 固定手数历史成绩独立保留。不能将提高资金/手数带来的绝对利润增长当作策略改进。</p>
<p>DD&gt;30% 否决，15–30% 人工复核；净值恢复因子须&gt;3；每策略及组合须&gt;100笔完整交易。
已查看的历史区间不是 untouched OOS；延迟、滑点、参数稳定性及原生执行场景测试仍待完成。</p></section>'''+''.join(sections)+\
        '<section><h2>资金容量研究</h2><p>只显示已实际完成的回测。未列出的资金/策略组合仍未执行，不填 0。</p>'+cap_table+cap_links+\
        '</section><section><h2>逐笔成本审计</h2>'+costs+'''
<p>此表只收录已经以原生成交记录复核的完整仓位，扣除进出场佣金及隔夜费用。其统计口径与 MT5 原生摘要可能略有差异，首页 PF 仍保留原生报告值。
费用估算少于实际时标记 FEE_ESTIMATE_UNDERSTATED；这项差异不会被悄悄改入当前冻结基准。1% 是计划风险上限，不保证跳空或滑点后的实际亏损仍不超过 1%。</p>
<p>当前逐笔核对器明确不支持将部分成交或多次分批退出简化为多笔完整交易；遇到这类情况会标记需要专项审计。</p>
</section><section><h2>文件一致性</h2>'''+proof+'''
<p><a href="R_C00_BASELINE_INVENTORY.json">完整基准清单</a><a href="R_C00_BASELINE_SUMMARY.csv">基准 CSV</a>
<a href="../research/RUNTIME_RECOVERY.md">运行环境恢复与来源</a><a href="../research/RESUME.md">续做检查点说明</a></p>
<p>最终比较仍须原生执行、保护隔离、风险压力和全套样本外证据；当前不生成 Champion ZIP。</p>
<p class="muted">本页已做数据、结构和本地链接检查；尚未完成浏览器视觉验收。</p></section></main></body></html>'''
    report.write_text(text, encoding='utf-8')
    public = [report, ROOT/'reports/R_C00_BASELINE_INVENTORY.json', ROOT/'reports/R_C00_BASELINE_SUMMARY.csv']
    (ROOT/'reports/R_C00_BASELINE_SHA256.txt').write_text(
        '\n'.join(sha(p)+'  '+p.name for p in public)+'\n', encoding='ascii')
    print(json.dumps(dict(Report=str(report), Lanes=len(baseline), CapacityRuns=len(capacity)), ensure_ascii=False))


if __name__ == '__main__':
    build()
