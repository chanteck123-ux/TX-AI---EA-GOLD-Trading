"""Audit the preregistered fee correction, never promote it as a strategy winner."""
import html
import json
import re
from pathlib import Path

from summarize_runs import ROOT, read, sha, summarize
from build_baseline_report import FROZEN_EX5, FROZEN_SOURCE, FIELDS, table, evidence_links
from compare_sc01 import fair, trade_signature

SOURCE = 'CCED6620AAA43B8D30F2DC88208CBEB799F6F26EFDC14A8F6CD05873EE195F4E'
EX5 = 'F1F26A995805B9CE963FAA03627A0923B9C6B7E30C9A83D37FC2A8C639A1EFAF'
MATRIX = [('Scalping', 500), ('Intraday', 500), ('Swing', 500), ('Combined', 500),
          ('Scalping', 1000), ('Scalping', 2000)]
KNOWN_LIMITS = {'RESEARCH_NOT_CHAMPION', 'NOT_UNTOUCHED_OOS', 'LOW_SAMPLE_SIZE',
                'NO_DELAY_ONLY', 'NO_FILLED_TRADES', 'RECOVERY_GATE_NOT_PASSED'}


def select(rows, lane, capital, source_hash, binary_hash):
    found = [r for r in rows if (r['Strategy'], r['CapitalUSD'], r['SourceSHA256'], r['EX5SHA256'],
                                 r['DelayMs']) == (lane, capital, source_hash, binary_hash, 0)]
    if not found:
        raise ValueError(f'MISSING_PREREGISTERED_RUN_{lane}_{capital}_{binary_hash}')
    return max(found, key=lambda r: r['Run'])


def compare(base, candidate):
    conditions = fair(base, candidate)
    for label, row in [('Control', base), ('Candidate', candidate)]:
        permitted = KNOWN_LIMITS | ({'FEE_ESTIMATE_UNDERSTATED'} if label == 'Control' else set())
        if set(row['Flags'])-permitted:
            raise ValueError('VALIDATION_EVIDENCE_FAIL_'+label+str(set(row['Flags'])-permitted))
        if row['Reject'] != 0:
            raise ValueError('BROKER_REJECT')
    costs = candidate['CompleteTradeCostAudit']
    fee = candidate['FeeModelEvidence']
    if candidate['Trades']:
        if (costs['Status'] != 'RECONCILED_COMPLETE_POSITIONS' or
                costs.get('MaximumFeeShortfallUSD', 1) > 1e-8 or
                fee['Model'] != 'PER_SIDE_CEILING' or fee['Flags'] or
                candidate['RiskPlanCount'] < candidate['Trades']):
            raise ValueError('ROUNDED_FEE_VALIDATION_INCOMPLETE')
    elif costs['Status'] != 'NO_TRADES':
        raise ValueError('ZERO_TRADE_EVIDENCE_INCOMPLETE')
    delta = {k: candidate[k]-base[k] if candidate[k] is not None and base[k] is not None else None
             for k in FIELDS[1:]+['MaxEquityDDUSD', 'RecoveryEquity', 'ReturnPct']}
    return dict(Strategy=base['Strategy'], CapitalUSD=base['CapitalUSD'], Control=base, Candidate=candidate,
                ParameterConditions=conditions,
                ExplicitCodeDifference='LINEAR_FEE_TO_PER_SIDE_CEILING_WITHIN_UNCHANGED_1PCT_3PCT_CAPS',
                Delta=delta, CompleteTradeSignaturesMatch=trade_signature(base) == trade_signature(candidate))


def proof():
    folder = ROOT/'reports/compile/GSM_FxPro_R_C01_20260906_213537'
    compile_record = json.loads(read(folder/'COMPILE.json'))
    if (compile_record['Stage'] != 'COMPILE_PASS' or compile_record['SourceSHA256'] != SOURCE or
            compile_record['EX5SHA256'] != EX5 or sha(folder/'GSM_FxPro_R_C01.ex5') != EX5 or
            sha(folder/'GSM_FxPro_R_C01.mq5') != SOURCE or
            sha(folder/'MetaEditor.log') != compile_record['LogSHA256']):
        raise ValueError('COMPILE_PROOF_MISMATCH')
    for path, digest in compile_record['Dependencies'].items():
        dependency = Path(path)
        if dependency.parent == ROOT/'src' and (sha(dependency) != digest or sha(folder/dependency.name) != digest):
            raise ValueError('COMPILED_HEADER_PROOF_MISMATCH')
    unit_folder = ROOT/'reports/runs/R_C01_UnitTests_USD500_D0_20260906_213344'
    unit_record = json.loads(read(unit_folder/'RUN.json'))
    if (unit_record['CompileEvidence']['Stage'] != 'COMPILE_PASS' or
            sha(ROOT/'tests/FeeRiskTests.mq5') != unit_record['SourceSHA256'] or
            sha(unit_folder/(unit_folder.name+'.htm')) != unit_record['ReportSHA256']):
        raise ValueError('NATIVE_UNIT_HASH_PROOF_MISMATCH')
    logs = '\n'.join(read(p) for p in unit_folder.glob('*.log.txt'))
    matches = re.findall(r'FEE_RISK_TEST_SUMMARY\|Tests=(\d+)\|Failures=(\d+)\|GridCases=(\d+)', logs)
    if not matches or any(m != ('25', '0', '25824') for m in matches):
        raise ValueError('NATIVE_UNIT_PROOF_MISSING_OR_FAILED')
    return dict(CompileResult=compile_record['Result'], CompileRecordSHA256=sha(folder/'COMPILE.json'),
                CompileLogSHA256=sha(folder/'MetaEditor.log'), SourceSHA256=SOURCE, EX5SHA256=EX5,
                NativeUnitTests=25, NativeUnitFailures=0, NativeGridCases=25824,
                UnitRun=unit_folder.name, UnitRecordSHA256=sha(unit_folder/'RUN.json'),
                ProtectionExecutionRestartIntegration='NOT_EXECUTED')


def main():
    rows = json.loads(read(ROOT/'reports/R_C00_RESULTS.json'))
    candidate_rows = [r for p in sorted((ROOT/'reports/runs').glob('R_C01_*/RUN.json'))
                      if (r := summarize(p))]
    rows = [r for r in rows if not r['Run'].startswith('R_C01_')]+candidate_rows
    comparisons = [compare(select(rows, lane, capital, FROZEN_SOURCE, FROZEN_EX5),
                           select(rows, lane, capital, SOURCE, EX5)) for lane, capital in MATRIX]
    unchanged = all(p['CompleteTradeSignaturesMatch'] and all(v in (0, None) for v in p['Delta'].values())
                    for p in comparisons)
    verdict = ('ENGINEERING_CORRECTION_VALIDATED_TESTED_CASES_NOT_CHAMPION' if unchanged
               else 'REGRESSION_OR_BEHAVIOR_CHANGE_REQUIRES_REVIEW_NO_PROMOTION')
    output = dict(CandidateID='R-C01', Control='R-C00', Verdict=verdict, Comparisons=comparisons,
                  ValidationProof=proof(), NewChampions={s: 'NONE' for s in ('Scalping','Intraday','Swing','Combined')},
                  OOS='ALREADY_VIEWED_NOT_UNTOUCHED', Stress='NOT_EXECUTED',
                  FeeModelScope='RESEARCH_ESTIMATE_NOT_UNIVERSAL_BROKER_TARIFF',
                  StrategyImprovement='NOT_DEMONSTRATED', LiveApproved=False)
    (ROOT/'reports/R_C01_COMPARISON.json').write_text(json.dumps(output, ensure_ascii=False, indent=2), encoding='utf-8')
    sections = []
    for p in comparisons:
        title = p['Strategy']+' / '+str(p['CapitalUSD'])+' USD'
        data = [[label]+[r[k] for k in FIELDS[1:]] for label, r in [('R-C00',p['Control']),('R-C01',p['Candidate'])]]
        data.append(['Delta']+[p['Delta'][k] for k in FIELDS[1:]])
        detail = table(['版本','净利润 USD','最大净值回撤 %','PF','完整交易数','胜率 %','拒单'], data)
        detail += '<p>成交签名一致：'+str(p['CompleteTradeSignaturesMatch'])+'。参数条件一致，费用预算算法的差异单独披露。</p>'
        detail += '<p>R-C00 '+evidence_links(p['Control'])+'</p><p>R-C01 '+evidence_links(p['Candidate'])+'</p>'
        audits = []
        for label, r in [('R-C00',p['Control']),('R-C01',p['Candidate'])]:
            a = r['CompleteTradeCostAudit']
            audits.append([label, r['ReturnPct'], r['MaxEquityDDUSD'], r['RecoveryEquity'],
                           r['MaximumPlannedRiskPct'], r['MaximumAggregatePlannedRiskPct'],
                           a['CommissionUSD'], a.get('MaximumFeeShortfallUSD'),
                           r['MinimumTechnicalEquityAtRejectedSetups']])
        detail += table(['版本','收益率 %','净值回撤 USD','净值恢复因子','最大单笔计划风险 %','最大合计计划风险 %',
                         '总佣金 USD','最大费用预算缺口 USD','观察到的技术资金下界 USD'], audits)
        cost = p['Candidate']['CompleteTradeCostAudit']
        if cost['Status'] == 'RECONCILED_COMPLETE_POSITIONS':
            detail += table(['方向','完整交易数','净利润 USD','净胜率 %','净 PF','平均净盈利','平均净亏损','实际净 R:R','净期望 USD'],
                            [[label]+[s[k] for k in ['Trades','NetUSD','WinRatePct','PF','AverageWinUSD','AverageLossUSD',
                                                     'RealizedRR','ExpectancyNetUSD']]
                             for label, s in [('全部',cost['NetStats']),('BUY',cost['BUY']),('SELL',cost['SELL'])]])
            detail += '<p>最大 SL 不利成交价差：'+str(cost['MaximumStopAdversePrice'])+'。主表保留 MT5 原生 PF；上表按双边佣金后的完整仓位重新统计，不混用两种口径。</p>'
        else:
            detail += '<p>零成交：未验证真实成交费用及下单压力。技术资金下界只描述已观察信号的最小手数计算，不是入金建议。</p>'
        sections.append('<section><h2>'+html.escape(title)+'</h2>'+detail+'</section>')
    page = '''<!doctype html><html lang="zh-CN"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>R-C01 费用预算修正报告</title><style>body{margin:0;background:#f5f6f7;color:#222;font:15px/1.7 "Microsoft YaHei",sans-serif;letter-spacing:0}
main{max-width:1400px;margin:auto;padding:24px}section{padding:20px 0;border-bottom:1px solid #c9ced3}h1{font-size:26px}h2{font-size:20px}
table{border-collapse:collapse;width:100%;background:#fff}th,td{padding:8px;border:1px solid #ccd0d4;text-align:right;min-width:72px}
th{background:#e5eeeb}td:first-child,th:first-child{text-align:left}.scroll{overflow:auto;margin:16px 0}a{color:#075ca1;margin-right:12px}
.status{color:#a22;font-weight:700;overflow-wrap:anywhere}@media(max-width:600px){main{padding:14px}h1{font-size:23px}}</style></head><body><main>
<h1>FxPro R-C01：费用预算修正</h1><p class="status">'''+verdict+'''</p>
<p>这是风险计算修正，不是新的盈利 Champion。三个策略进出场逻辑、固定参数及 1% / 3% 风险上限未改；Scalping 没有保本、追踪或分批退出。</p>
<p>FxPro GOLD，2026.01.05–2026.08.26，1:100，基于真实报价的每个 Tick，原生报告 100% 真实报价，0ms。
区间已查看，不是 untouched OOS。</p>
<p>R-C00 按 7 USD/手线性预留往返佣金；R-C01 对每一边按账户币种显示精度向上预留。0.01 手预算由 0.07 修正为 0.08 USD。
这只是已声明并由本次成交核对的研究模型，不是所有账户的通用费率规则，也没有修改测试器实际佣金。</p>'''+''.join(sections)+'''
<section><h2>结论与限制</h2><p>源码隔离检查和原生数学测试通过；真实 MetaEditor 编译 0 错误、0 警告。25 项原生测试及 25,824 组手数网格校验见证据清单。</p>
<p>持仓量较大不会自动产生更多有效信号。现有正收益样本仍只有 20 笔，不满足每策略与组合完整交易数大于 100 的标准。</p>
<p>本次修正不解决原策略过滤、First Touch、Intraday/Swing 低交易数；也未完成新尾仓逻辑、原生执行/重启/保护隔离、延迟与样本外验证。</p>
<p>初始风险预留不因保本而释放；跳空、滑点、变动佣金及任意分批成交费用仍可能超出计划。不能把计划风险当作实际亏损保证。</p>
<p>四条新 Champion 均为 NONE，不生成 Champion ZIP，不开启实盘。</p>
<p><a href="R_C01_COMPARISON.json">完整比较与编译证据</a><a href="R_C01_SHA256.txt">SHA256</a>
<a href="../research/R-C01_PREREGISTRATION.md">事前登记</a><a href="../research/R-C01_REVIEW.md">代码与反方审查</a>
<a href="R_C00_BASELINE_CN.html">冻结原基准</a></p>
<p>已核对报告数据及本地证据链接；尚未完成浏览器视觉验收。</p></section></main></body></html>'''
    (ROOT/'reports/R_C01_REPORT_CN.html').write_text(page, encoding='utf-8')
    paths = ['reports/R_C01_REPORT_CN.html', 'reports/R_C01_COMPARISON.json', 'src/GSM_FxPro_R_C01.mq5',
             'src/StrictRiskRounded.mqh', 'src/FeeRiskMath.mqh', 'src/RiskMath.mqh', 'tests/FeeRiskTests.mq5']
    (ROOT/'reports/R_C01_SHA256.txt').write_text('\n'.join(sha(ROOT/p)+'  '+p for p in paths)+'\n', encoding='ascii')
    print(json.dumps(dict(Verdict=verdict, Comparisons=len(comparisons),
                         Deltas=[p['Delta'] for p in comparisons]), ensure_ascii=False))


if __name__ == '__main__':
    main()
