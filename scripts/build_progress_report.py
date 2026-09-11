"""Evidence-derived progress report. Never turns missing runs into zero trades."""
import html
import json
from datetime import datetime
from pathlib import Path
from summarize_runs import read, sha

ROOT = Path(__file__).resolve().parents[1]
REPORTS = ROOT/'reports'


def esc(value):
    return html.escape(str(value))


def fmt(value, suffix=''):
    return '不适用' if value is None else f'{value:,.2f}{suffix}'


def main():
    results = json.loads(read(REPORTS/'R_C00_RESULTS.json'))
    by_lane = {r['Strategy']: r for r in results}
    build = json.loads(read(ROOT/'COMPILE_CHECKPOINT.json'))
    assert sha(ROOT/build['Source']) == build['SourceSHA256']
    assert sha(Path(build['BinaryArchive'])) == build['EX5SHA256']
    assert sha(Path(build['BinaryArchive']).parent/'MetaEditor.log') == build['LogSHA256']
    for path, digest in build['Dependencies'].items():
        assert sha(Path(path)) == digest, 'CURRENT_INCLUDE_HASH_MISMATCH'
    units = list((REPORTS/'runs').glob('*UnitTests*/*.log.txt'))
    assert any('RISK_TEST_SUMMARY|Tests=25|Failures=0|SweepCases=770' in read(p) for p in units)
    static = json.loads(read(REPORTS/'SOURCE_ISOLATION.json'))
    assert static['Failures'] == static['Errors'] == 0
    assert static['SourceSHA256'] == build['SourceSHA256']
    package = ROOT.parent/'baseline-audit-20260905/repository/champion/current/GSM_GOLD_3SOP_EA_V4.00_CURRENT_CHAMPION.zip'
    original = ROOT.parent/'baseline-audit-20260905/package/CODE/GSM_Gold_3SOP_EA_CHAMPION.mq5'
    assert sha(package) == '43AF3C393B6C226211115A1A1DBC70C88F0F07250FA332D22C04C3ED64EB80E2'
    assert sha(original) == 'AC9826E6EF4959562B9079A1FF9B8CBB35E5E8C2A913E431488CA5C900D1FF60'
    rows, details, funnels = [], [], []
    lanes = ['Scalping', 'Intraday', 'Swing', 'Combined']
    for lane in lanes:
        row = by_lane.get(lane)
        if row is None:
            rows.append(f'<tr><th>{lane}</th><td colspan="6">未完成：'+
                        ('终端更新阶段未启动测试' if lane == 'Swing' else '尚未运行')+'</td></tr>')
            continue
        rows.append('<tr><th>'+lane+'</th>'+''.join('<td>'+esc(value)+'</td>' for value in
                    [fmt(row['NetProfitUSD']), fmt(row['MaxEquityDDPct'], '%'), fmt(row['ProfitFactor']),
                     row['Trades'], fmt(row['WinRatePct'], '%'), row['Reject']])+'</tr>')
        funnel = next(f for f in row['Funnels'] if f['SOP'].startswith(lane))
        columns = ['ZonesDetected', 'ZonesDeparted', 'FirstTouches', 'CandlePatternsDetected',
                   'ChartPatternsDetected', 'HardSOPPassed', 'ConfidencePassed', 'GlobalGatePassed',
                   'RiskRejected', 'OrdersRequested', 'OrdersFilled', 'OrdersRejected']
        funnels.append('<h3>'+lane+'</h3><dl class="funnel">'+''.join(
            f'<div><dt>{key}</dt><dd>{esc(funnel[key])}</dd></div>' for key in columns)+'</dl>')
        name = row['Run']
        links = ' | '.join(f'<a href="runs/{name}/{name}{ext}">{label}</a>'
                           for ext, label in [('.htm', 'MT5 原始报告'), ('.set', '实际 SET'), ('.ini', '测试 INI')])
        details.append(f'<h3>{lane}：{esc(name)}</h3><p>{links}</p><dl>'+''.join(
            f'<dt>{key}</dt><dd><code>{esc(row[key])}</code></dd>' for key in
            ['SourceSHA256', 'EX5SHA256', 'SETSHA256', 'ReportSHA256'])+'</dl><p>证据限制：'+
            esc(', '.join(row['Flags']))+'</p>')
    evidence = dict(Updated=datetime.now().astimezone().isoformat(),
                    Stage='WAITING_MT5_UPDATE_BASELINE_INCOMPLETE', NewChampion={k:'NONE' for k in lanes},
                    SourceSHA256=build['SourceSHA256'], EX5SHA256=build['EX5SHA256'],
                    HeaderHashes={Path(k).name:v for k,v in build['Dependencies'].items()
                                  if Path(k).name in {'RiskMath.mqh','StrictRisk.mqh'}},
                    CompileResult=build['Result'], CompileLogSHA256=build['LogSHA256'],
                    LatestRevisionBacktest='NOT_COMPLETED', NativeRiskArithmeticChecks=25,
                    NativeArithmeticFailures=0, ArithmeticSweepCases=770, StaticSourceChecks=4,
                    ProfitProtectionIntegration='NOT_EXECUTED',
                    ReportVisualQA='NOT_EXECUTED_BROWSER_LOCAL_URL_POLICY_BLOCKED',
                    BaselineZIP=sha(package), BaselineMQ5=sha(original),
                    CompletedDiagnosticRuns=[r['Run'] for r in results],
                    Next='Verify MT5 update, freeze executable, rerun four lanes, capacity audit, then S-C01.')
    (REPORTS/'PROGRESS_EVIDENCE.json').write_text(json.dumps(evidence, ensure_ascii=False, indent=2), encoding='utf-8')
    content = '''<!doctype html><html lang="zh-CN"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1"><title>FxPro R-C00 研究进度与风险审计</title>
<style>
*{box-sizing:border-box}body{margin:0;color:#17201d;background:#f4f6f5;font:16px/1.65 "Microsoft YaHei",Arial,sans-serif;letter-spacing:0}
header{background:#143e35;color:#fff;border-bottom:5px solid #d4ac40;padding:30px 24px}header>div,main{max-width:1120px;margin:auto}
h1{font-size:28px;line-height:1.4;margin:0 0 8px}h2{font-size:21px;margin:0 0 16px}h3{font-size:17px;margin:22px 0 8px}
header p{margin:4px 0;color:#e0eee8}main{padding:0 24px 40px}section{padding:28px 0;border-bottom:1px solid #ccd6d1}
p,li,dd{overflow-wrap:anywhere}a{color:#075f8e}header a{color:#fff}.alert{border-left:5px solid #b44b35;padding:12px 16px;background:#fff2eb}
.scroll{overflow-x:auto}table{border-collapse:collapse;width:100%;background:#fff;white-space:nowrap}th,td{padding:12px;border-bottom:1px solid #dbe1de;text-align:right;font-variant-numeric:tabular-nums}th:first-child{text-align:left}thead{background:#e6eeea}
code{font:13px/1.6 Consolas,monospace;word-break:break-all}dt{font-weight:600}dd{margin:0 0 10px}.funnel{display:grid;grid-template-columns:repeat(3,minmax(0,1fr));gap:0 18px}.funnel div{border-bottom:1px solid #dbe1de;padding:8px 0}.funnel dt{font-size:13px;overflow-wrap:anywhere}.funnel dd{font-size:20px;margin:0}.muted{color:#53665d}
@media(max-width:650px){h1{font-size:23px}header{padding:22px 16px}main{padding:0 16px 32px}.funnel{grid-template-columns:repeat(2,minmax(0,1fr))}th,td{padding:10px}section{padding:22px 0}}
</style></head><body><header><div><h1>FxPro GOLD · R-C00 研究进度</h1>
<p>风险标准化基线审计｜500 USD · 1:100｜2026-09-06</p><p>研究未完成 · 不是新 Champion · 不可据此实盘</p></div></header><main>
<section><h2>当前结果</h2><p class="alert"><strong>后续回测等待 FxPro 更新恢复。</strong>最新审阅版本已实际编译：0 错误、0 警告；尚未完成该版本回测。下表属于此前同轮 R-C00 修订的真实诊断结果，不冒充最新 EX5 的测试证据。</p>
<div class="scroll"><table><thead><tr><th>策略</th><th>净利润 USD</th><th>最大净值回撤</th><th>PF</th><th>交易数</th><th>胜率</th><th>拒单</th></tr></thead><tbody>'''+''.join(rows)+'''</tbody></table></div>
<p>Scalping、Intraday：2026.01.05–2026.08.26（最后报价 08.25），FxPro GOLD，Every tick based on real ticks，报告显示 100% 真实报价，延迟 0ms。未使用 Tradona 回测。</p>
<p>没有成交时，PF、胜率、Recovery、平均盈亏、R:R、期望值与成本优势均不可评估。拒单 0 是因没有向券商发送订单，不能证明执行稳健。Swing 的启动失败不计为“0 交易”。四条新 Champion 均为 NONE。</p></section>
<section><h2>为什么有信号却不开仓</h2><p>500 USD × 1% = 每单 5 USD 计划风险预算。当前固定止损和最低 0.01 手，不能同时满足这个预算。</p>
<div class="scroll"><table><thead><tr><th>策略</th><th>预算 USD</th><th>最低手数计划风险 USD</th><th>风险拦截次数</th><th>技术资金下界 USD</th></tr></thead><tbody>
<tr><th>Scalping</th><td>5.00</td><td>8.37</td><td>20</td><td>837.00</td></tr><tr><th>Intraday</th><td>5.00</td><td>12.37</td><td>7</td><td>1,237.00</td></tr></tbody></table></div>
<p>上述风险含预设成交偏差缓冲和每标准手 7 USD 往返费用估算；没有调低测试器手续费。技术资金下界只对已记录设置成立，不是建议入金金额，更不是已验证的最低实盘资金。跳空、额外滑点和持仓费用可能令实际亏损超过计划。</p>
<p>这一步保留原 SL/TP、进场、区域评分、每日/并发限制。不能为了交易数而提高风险、强制最低手数或缩短止损。容量研究与策略优化会分开验证。</p></section>
<section><h2>已完成的工程检查</h2><ul><li>原 V4.00 ZIP 与 MQ5 SHA256 仍匹配，未覆盖正式文件。</li>
<li>风险基线：每单≤1%、合计≤3%，手数向下取整；未知持仓/止损/成交状态时停止新开仓。保本不释放初始风险占用。</li>
<li>Scalping 保护管理函数不执行修改：无保本、追踪、部分止盈或尾仓。固定 SL/TP 保留。</li>
<li>实际 MQL 风险算术测试：25 项通过，0 失败，另检查 770 个资金数值。</li>
<li>静态源码测试：4 项通过；10 个进场、区域、Intraday/Swing 管理函数与原版逐字一致。</li>
<li>上述算术与静态测试不等于服务器止损、部分成交、重启或利润保护的集成测试。</li></ul>
<p>新 Intraday 0.5R 保本／原 TP 平半／2R 跟踪方案尚未实现；Swing 新实验尚未开始。现有 Intraday、Swing 管理仍是待审计的旧逻辑。</p></section>
<section><h2>信号漏斗</h2><p>只展示对应已启用策略。计数代表程序事件，可能对同一区域重复统计，不能当成独立交易机会总数。</p>'''+''.join(funnels)+'''</section>
<section><h2>证据与修订边界</h2><p>历史 V4.00 固定手数成绩独立保留；其风险条件与 R-C00 不同，不能直接按净利润高低比较策略质量。原版报告交易数也不足以通过现在的晋级门槛。</p>
<p>首轮 Scalping EX5 未及时归档，两个已完成诊断的旧 include 快照不完整；SET 输入只能部分审计。Intraday EX5、测试器版本链、原始报告已保存。这些证据缺口不会被隐藏，新冻结版本必须完整重跑。</p>'''+''.join(details)+'''
<h3>最新编译版本（待回测）</h3><dl><dt>MQ5 SHA256</dt><dd><code>'''+build['SourceSHA256']+'''</code></dd><dt>EX5 SHA256</dt><dd><code>'''+build['EX5SHA256']+'''</code></dd></dl>
<p><a href="../src/GSM_FxPro_R_C00.mq5">研究源码</a> · <a href="../src/StrictRisk.mqh">StrictRisk.mqh</a> · <a href="../src/RiskMath.mqh">RiskMath.mqh</a> · <a href="'''+Path(build['BinaryArchive']).relative_to(REPORTS).as_posix()+'''">已编译 EX5</a> · <a href="PROGRESS_EVIDENCE.json">编译与检查证据</a> · <a href="R_C00_RESULTS.csv">诊断 CSV</a></p>
<p class="muted">编译需要两个自有 MQH 与源码同目录，以及 MetaQuotes 标准 MQL5 Include 库。本轮编译借用本机完整 SDK；这不是 Tradona 策略测试。源码/EX5 为研究用，不作为正式交付包。原始日志/报告/EX5 只保留本机，GitHub 保存摘要。浏览器安全策略不允许本次打开本地 HTML，未完成可视化复核。</p></section>
<section><h2>恢复后的顺序</h2><ol><li>确认 FxPro/MetaTester 更新完成，检查旧进程，再冻结终端版本。</li><li>最新修订重新跑 500 USD 四条基线，再进行资金容量诊断。</li><li>完成基线审计后开始 S-C01，只测试 Scalping 最近有效区域距离；其余引擎锁定。</li><li>独立研究 Intraday 尾仓、Swing，再实际重测 Combined，不直接相加利润。</li><li>补齐未污染 OOS、延迟与成本压力、参数稳定性、成交/重启/保护集成测试。</li></ol>
<p>正式排序：净利润 → 最大净值回撤 → PF → 完整交易数 → 胜率 → 拒单。DD&gt;30%否决，15%–30%人工复核，净值 Recovery&gt;3，每条策略及组合&gt;100笔完整交易。当前均未通过；不生成 Champion ZIP。</p>
<p>更新故障记录、源码和结果摘要仅保存研究分支。未停止或修改系统 MetaTester 服务；更新卡住的具体原因未确定。研究每小时检查续做条件，不在环境未变时重复启动同一个失败测试。</p></section>
</main></body></html>'''
    target = REPORTS/'FXPRO_R_C00_PROGRESS_CN.html'
    target.write_text(content, encoding='utf-8')
    print(target)


if __name__ == '__main__':
    main()
