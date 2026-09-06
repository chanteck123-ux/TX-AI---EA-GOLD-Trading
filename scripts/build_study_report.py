"""Chinese research report with explicit evidence/acceptance boundaries."""
import html
import json
from datetime import datetime
from pathlib import Path
from summarize_runs import ROOT, read

FIELDS = ['NetProfitUSD','MaxEquityDDPct','ProfitFactor','Trades','WinRatePct','Reject']
HEADERS = ['版本 / 策略','净利润 USD','最大净值 DD %','PF · 净持仓','完整交易数','胜率 %','拒单']


def esc(value):
    return html.escape(str(value))


def fmt(value):
    if value is None:
        return '未定义 / 未观测'
    if isinstance(value, float):
        return f'{value:,.2f}'
    return esc(value)


def table(headers, rows):
    return '<div class="scroll"><table><thead><tr>'+''.join('<th>'+esc(x)+'</th>' for x in headers)+'</tr></thead><tbody>'+''.join(
        '<tr>'+''.join('<td>'+fmt(x)+'</td>' for x in row)+'</tr>' for row in rows)+'</tbody></table></div>'


def choose(rows, prefix, lane=None, capital=2000, delay=0):
    matches=[r for r in rows if r['CandidateID']==prefix and r['CapitalUSD']==capital and
             r['DelayMs']==delay and (lane is None or r['Strategy']==lane)]
    return max(matches,key=lambda r:r['Run']) if matches else None


def lane_table(rows):
    return table(HEADERS,[[label]+[r[k] for k in FIELDS] for label,r in rows if r])


def render(rows, diagnostics, evidence_prefix='runs/', final=False):
    byrun={d['Run']:d for d in diagnostics}
    def extra(name,default):
        path=ROOT/'reports'/name
        return json.loads(read(path)) if path.exists() else default
    validation=extra('RESEARCH_VALIDATION.json',{})
    portfolio={r['Run']:r for r in extra('RESEARCH_PORTFOLIO.json',[])}
    metadata_prefix='RESEARCH/' if final else ''
    baseline=[(lane,choose(rows,'R_C01',lane)) for lane in ('Scalping','Intraday','Swing','Combined')]
    controls=[(lane,choose(rows,'CONTROL_FINAL',lane)) for lane in ('Scalping','Intraday','Swing','Combined')]
    selected=[('S-C02 · EMA关闭 · 拒绝',choose(rows,'S_C02','Scalping')),
              ('I-C01 · 取消每日上限',choose(rows,'I_C01','Intraday')),
              ('I-C02 FIX2 · 尾仓',choose(rows,'I_C02_FIX2','Intraday')),
              ('W-C01 · 取消每日上限',choose(rows,'W_C01','Swing')),
              ('C-C01 · 实际组合候选',choose(rows,'C_C01','Combined'))]
    combined=choose(rows,'C_C01','Combined') or choose(rows,'CONTROL_FINAL','Combined') or choose(rows,'CONTROL','Combined')
    primary=controls
    parts=['<header><p class="eyebrow">CODEX · FXPRO · MQL5</p><h1>黄金 3-SOP EA 研究报告</h1>',
           '<p class="status">研究版，未批准实盘。四个合格 Champion 均为 NONE。</p>',
           '<p>主测试 2,000 USD · 1:100 · 每单计划风险≤1% · 合计初始风险≤3% · 每策略1仓 / 组合3仓</p>',
           '<p>FxPro GOLD，2026.01.05 至 2026.08.26（结束日不含），Model 4，原生真实 Tick 覆盖核对。</p>',
           '<p>这些历史日期已经看过，仅作开发数据。500 USD 单列；未来六个月 OOS 未完成。</p>',
           '<nav><a href="#main">主结果</a><a href="#experiments">实验对比</a><a href="#stress">压力</a><a href="#details">完整审计</a><a href="#flow">流程</a><a href="#delivery">交付</a></nav></header>',
           '<section id="main"><h2>修正后控制组 · 并非 Champion</h2>',lane_table(primary),
           '<p>正式顺序：净利润 → 最大相对净值回撤 → PF → 完整交易数 → 胜率 → 拒单。PF 按完整持仓含全部费用计算；无亏损样本时不伪造有限 PF。原生 PF 单独保留。</p>',
           '<h3>冻结的 R-C01 工程基线</h3>',lane_table(baseline),
           '<p>V4.00 / R-C00 / R-C01 / S-C01 保持原文件。初版研究 OFF 四组已逐笔复现 R-C01。随后直接原生探针证实历史订单需显式选择；修正后控制另列，不能把修复收益当尾仓收益。</p></section>',
           '<section id="experiments"><h2>独立实验</h2>',lane_table(selected),
           '<p>S-C02：只关闭Scalping主M5 EMA30/100，保留H4 EMA环境过滤；机会增加但净利润恶化，拒绝。Scalping保留固定价格距离SL8 / TP7，不加入利润保护。</p>',
           '<p>I-C01 / W-C01：只取消每日次数上限，原样本未增加交易。取消上限不保证有更多合格信号。</p>',
           '<p>I-C02：初始0.5R且收盘D1/H4同向，先确认成本保本再撤TP；原TP价合法减仓；2R后收盘H4±ATR×2追踪。0.01手不非法拆分、不加仓。</p>',
           '<p>首版和等待修复版因恢复故障停开新仓，单独标为无效工程结果，不纳入策略优劣排名。真正根因由原生订单历史探针确认。</p>']
    if final:
        parts.insert(7,'<p><a href="CODE/GSM_FxPro_RESEARCH.mq5">研究源码</a> · <a href="CODE/GSM_FxPro_RESEARCH.ex5">实际EX5</a> · <a href="SETS/FxPro/CONTROL_FINAL_Combined_USD2000.set">控制组SET</a> · <a href="SETS/FxPro/C_C01_Combined_USD2000.set">尾仓实验SET</a> · <a href="MANIFEST.json">交付清单</a> · <a href="SHA256.txt">SHA256</a></p>')
    pairs=[('EMA实验',choose(rows,'R_C01','Scalping'),choose(rows,'S_C02','Scalping')),
           ('Intraday次数上限',choose(rows,'R_C01','Intraday'),choose(rows,'I_C01','Intraday')),
           ('Swing次数上限',choose(rows,'R_C01','Swing'),choose(rows,'W_C01','Swing')),
           ('修正后尾仓ON/OFF',choose(rows,'CONTROL_FINAL','Intraday'),choose(rows,'I_C02_FIX2','Intraday')),
           ('修正后组合ON/OFF',choose(rows,'CONTROL_FINAL','Combined'),choose(rows,'C_C01','Combined'))]
    parts.append(table(['比较','Δ净利润 USD','Δ净值DD 百分点','ΔPF','Δ完整交易','Δ胜率 百分点'],
                       [[name]+[candidate[k]-base[k] if base[k] is not None and candidate[k] is not None else None
                                for k in FIELDS[:-1]] for name,base,candidate in pairs if base and candidate]))
    parts.append('<p>Δ为候选减控制。组合结果来自真实组合EA测试，不是三个单策略利润之和。</p></section>')
    parts.append('<section><h2>本轮结论</h2><p>保留修正后的OFF工程控制组，不产生新的策略Champion。S-C02被拒绝；取消次数上限未改善当前样本；I-C02尾仓及C-C01组合的0ms净利润低于控制。Scalping EMA保持ON，Intraday尾仓默认OFF。</p><p>尾仓的高PF来自极小的亏损分母和仅4笔完整持仓，不能当作稳健优势。成本保本订单仍出现过-0.01USD净亏损，止损价不保证成交价。</p></section>')
    if combined:
        name=combined['Run']; prefix=evidence_prefix+name+'/'+name
        parts += ['<section><h2>MT5 原始资金曲线</h2><figure><img class="curve" src="'+esc(prefix+'.png')+'" alt="MT5原始组合余额及净值曲线"><figcaption>'+esc(name)+'</figcaption></figure>',
                  '<p>原生曲线保留，不根据收益美化。独立策略DD不能相加；组合内分策略净值DD未独立重建时标记不可独立审计。</p></section>']
    stress=[r for r in rows if r['DelayMs']!=0]
    parts += ['<section id="stress"><h2>原生延迟压力</h2>',
              table(['版本 / 策略','资金USD','延迟','净利润USD','净值DD%','PF','完整交易','胜率%','拒单'],
                    [[r['CandidateID']+' / '+r['Strategy'],r['CapitalUSD'],'原生随机（秒级规则）' if r['DelayMs']==-1 else str(r['DelayMs'])+'ms']+
                     [r[k] for k in FIELDS] for r in stress]),
              '<p>0ms 是控制；10/25/50ms 为固定延迟，原生随机不等于随机10–50ms。每组测试均保留自己的SET、INI、原始报告和日志。</p>',
              '<p>成本压力另有固定成交路径的后处理敏感性，它不模拟不同点差造成的信号/成交变化，也无法给出新的真实净值DD，不能替代原生重测或用于晋级。</p></section>',
              '<section><h2>参数与分批平仓诊断</h2>',
              lane_table([(r['CandidateID']+' / USD'+str(r['CapitalUSD']),r) for r in rows
                          if r['CandidateID'].startswith('I_C02_NEIGHBOR_') or r['CapitalUSD']==5000]),
              '<p>ATR 1.8 / 2.0 / 2.2 是冻结的参数邻域诊断；若该区间未进入2R追踪阶段，相同成绩只表示参数未起作用，不能宣称参数稳健。5000USD仅为合法拆仓工程诊断，不参与主资金排名。</p>',
              '<p>5000USD原生测试实际发生一次0.04手减去0.02手，返回10009，完整持仓仍计4笔；正常减仓路径得到验证，不冒充真实券商超时/部分成交故障验证。</p></section>',
              '<section><h2>500 USD 适配性 · 不混入主结果</h2>',
              lane_table([(r['CandidateID']+' / '+r['Strategy'],r) for r in rows if r['CapitalUSD']==500]),
              '<p>最低0.01手若超出1%预算，必须跳过。零成交不是零风险证明，更不是系统没有识别信号；详见各策略漏斗中的风险阻挡。</p></section>',
              '<section id="details"><h2>逐组证据与诊断</h2>']
    for row in rows:
        if row['CandidateID'] in ('R','R_C01') and row['CapitalUSD']!=2000:
            continue
        name=row['Run']; prefix=evidence_prefix+name+'/'+name
        parts += ['<details><summary>'+esc(name)+'</summary>',
                  '<p><a href="'+esc(prefix+'.htm')+'">MT5原始报告</a> · <a href="'+esc(prefix+'.set')+'">实际SET</a> · <a href="'+esc(prefix+'.ini')+'">实际INI</a></p>',
                  lane_table([(row['Strategy'],row)]),
                  table(['收益率%','净值DD USD','项目净值Recovery','原生Recovery','手算余额Recovery','原生PF','原生成交交易数'],
                        [[row['ReturnPct'],row['MaxEquityDDUSD'],row['RecoveryEquity'],row.get('NativeRecovery'),row.get('CalculatedBalanceRecovery'),row['NativeProfitFactor'],row['NativeTrades']]]),
                  table(['平均盈利USD','平均亏损USD','实际平均R:R','净期望USD','保本胜率%','最大连续亏损','佣金USD','隔夜费USD'],
                        [[row['CompleteNetStats'].get(k) for k in ('AverageWinUSD','AverageLossUSD','RealizedRR','ExpectancyNetUSD','BreakEvenWinRatePct')]+
                         [row['ConsecutiveLosses'],row['CommissionUSD'],row['SwapUSD']]]),
                  table(['方向','净利润USD','PF','完整交易','胜率%'],
                        [[direction]+[r.get(k) for k in ('NetUSD','PF','Trades','WinRatePct')] for direction,r in
                         [('BUY',row.get('NetBUY')),('SELL',row.get('NetSELL'))] if r is not None]),
                  '<p class="flags">'+esc(' | '.join(row['Flags']))+'</p>']
        tick=row.get('RealTickEvidence',{})
        parts.append(table(['真实Tick模式日志','原生覆盖','真实Tick起始','Tick数','K线数','管理请求'],
                           [[tick.get('NativeModelLog'),tick.get('NativeCoverage'),tick.get('RealTicksBegin'),
                             tick.get('Ticks'),tick.get('Bars'),row.get('ManagementRequests')]]))
        events=row.get('RunnerEvents',{})
        if any(events.values()):
            parts.append(table(['尾仓事件','次数'],list(events.items())))
        if name in portfolio:
            p=portfolio[name]
            parts.append(table(['最大同时持仓','最大同时BUY','最大同时SELL','出现对冲重叠','并发上限核对'],
                               [[p['PeakPositions'],p['PeakLongPositions'],p['PeakShortPositions'],
                                 p['ObservedOppositeExposure'],p['PositionLimitPass']]]))
            parts.append('<p>这是实际成交快照的并发审计。没有出现三仓重叠，不等于已经验证三仓压力；逐Tick净值相关性和峰值保证金仍待独立审计。</p>')
        if row.get('PositionLedger',{}).get('ByMagic'):
            parts.append(table(['组合内Magic','净利润USD','PF','完整交易','胜率%','净值DD'],
                               [[magic]+[s.get(k) for k in ('NetUSD','PF','Trades','WinRatePct')]+['不可独立审计']
                                for magic,s in row['PositionLedger']['ByMagic'].items()]))
        fkeys=['ZonesDetected','ZonesDeparted','FirstTouches','CandlePatternsDetected','ChartPatternsDetected',
               'HardSOPPassed','ConfidencePassed','GlobalGatePassed','OrdersRequested','OrdersFilled','OrdersRejected']
        parts.append(table(['SOP']+fkeys,[[f['SOP']]+[f.get(k) for k in fkeys] for f in row['Funnels']]))
        rejects=['EMARejected','RSIRejected','SessionRejected','PositionLimitRejected','RiskRejected','MinimumLotRiskRejected','ZeroTradeDiagnosis']
        parts.append(table(['SOP']+rejects,[[f['SOP']]+[f.get(k) for k in rejects] for f in row['Funnels']]))
        parts.append('<p>漏斗是事件计数，部分过滤并行或观察式计数，不能简单相减推算盈利漏单。已有“晚进/趋势错误”等分类是启发式标签，不是已证明原因。</p>')
        diag=byrun.get(name)
        if diag:
            parts.append(table(['最大计划单笔风险%','最大计划合计风险%','订单检查时最大保证金USD','平均成本代理USD','Edge/Cost代理','已核对持仓'],
                               [[diag['PlannedSingleCapPct'],diag['MaxAggregatePlannedPct'],diag['MaxInitialMarginAtOrderCheckUSD'],
                                 diag['AverageEntrySpreadAndCommissionProxyUSD'],diag['EdgeToCostProxy'],diag['ReconciledCount']]]))
            parts.append(table(['持仓ID','计算手数','实际手数','初始SL价格距离','初始SL估算USD','初始SL估算%','记录MAE USD','记录MFE USD','最终净利润USD'],
                               [[p[k] for k in ('PositionID','CalculatedLot','ActualLot','SLDistance','InitialSLRiskUSD',
                                               'InitialSLRiskPct','MAEUSD','MFEUSD','NetUSD')] for p in diag['PositionRiskCost']]))
            parts.append('<p>MAE/MFE按最初手数折算价格路径，不是减仓后的实际账户净值曲线；成本和隔夜费以最终完整持仓账本为准。</p>')
            if row['CandidateID'].startswith(('I_C02_FIX2','I_C02_CAPACITY','I_C02_NEIGHBOR')):
                parts.append('<p>记录的最大MFE / 初始R：'+fmt(diag.get('MaxRecordedMFEInInitialR'))+
                             '。若未到2R，ATR追踪参数没有得到有效历史样本检验；不能将相同成绩当作参数稳定性通过。</p>')
            if row['Strategy']=='Swing' and row['CapitalUSD']==2000:
                parts.append('<p>Swing本样本净值DD包含峰值浮盈回吐，不等于从入场起亏掉同样金额的本金。记录MFE 48.94USD、MAE 14.36USD，最终净利润0.66USD；仅1笔，不能把该特例推成稳定收益规律。</p>')
            parts.append(table(['追加点差比例','追加佣金比例','追加不利价格距离','估计净利润USD','估计PF','净值DD'],
                               [[s['ExtraSpreadFraction'],s['ExtraCommissionFraction'],s['ExtraRoundTripAdversePrice'],
                                 s['CompletePositionStats']['NetUSD'],s['CompletePositionStats']['PF'],'不可由后处理推算'] for s in diag['AnalyticalCostStress']]))
        parts.append('<p class="hash">源码 SHA256 '+esc(row['SourceSHA256'])+'<br>EX5 SHA256 '+esc(row['EX5SHA256'])+'<br>SET SHA256 '+esc(row['SETSHA256'])+'<br>报告 SHA256 '+esc(row['ReportSHA256'])+'</p></details>')
    parts += ['</section><section id="flow"><h2>最终程序流程</h2>',
              '<div class="flow"><div>FxPro / 黄金USD / USD对冲账户核对</div><b>↓</b><div>三引擎独立 OR：M5 / M30 / D1-H4-M30</div><b>↓</b><div>本策略SOP → 收盘确认 → 去重 → 时段/新闻/点差</div><b>↓</b><div>初始SL → 实际规格 → 费用预算 → 1%/3%风险 → 向下手数</div><b>↓</b><div>保证金 / OrderCheck / 新报价复核 → 请求 → 服务器确认</div><b>↓</b><div>Scalping固定SL/TP ｜ Intraday可选尾仓 ｜ Swing原保护</div><b>↓</b><div>逐持仓统计 → 原生Tick/延迟/恢复/成本 → 六个月OOS → 晋级门槛</div></div>',
              '<p>尾仓：0.5R+收盘D1/H4同向 → 成本BE服务器确认 → 撤TP → 原TP合法半仓 → 2R后收盘H4±ATR×2。止损只收紧。</p>',
              '<p>恢复状态不明时保守停止新开仓；原SL/TP仍由服务器执行。不得盲目重试部分平仓，不得把保本当无亏损保证。</p></section>',
              '<section id="delivery"><h2>验收与交付状态</h2>',
              '<p class="status">NO NEW CHAMPION · 不制作 Champion ZIP · 不批准实盘</p>',
              table(['真实MetaEditor结果','Python测试','Python失败'],[[validation.get('CompileResult'),validation.get('PythonTests'),validation.get('PythonFailures')]]),
              table(['原生MQL测试','检查数','失败数','验证类型'],[[r['Run'],r['Checks'],r['Failures'],r['Type']] for r in validation.get('NativeTests',[])]),
              '<p>真实MQL故障夹具使用实际管理器头文件及模拟服务器；重启探针清空内存后读取终端全局变量，不冒充OS强杀/重启或真实券商故障。</p>',
              '<p><a href="'+metadata_prefix+'RESEARCH_VALIDATION.json">验证证据</a> · <a href="'+metadata_prefix+'RESEARCH_COMPARISONS.json">逐参数公平比较</a> · <a href="'+metadata_prefix+'RESEARCH_RESULTS.csv">完整指标CSV</a></p>',
              '<p>门槛：最大相对净值DD≤30%；15%–30%人工复核；项目净值Recovery&gt;3；每策略及组合完整持仓&gt;100；独立OOS、真实费用和执行验证通过。胜率或PF漂亮不等于通过。</p>',
              '<p>未来连续六个月 OOS：按冻结检查点预登记，未到期不填成绩，不用训练交易凑样本。任何参数修改须新ID和新记录，不能重复污染同一OOS。</p>',
              '<p>已按FxPro官方日历锁定服务器日期2026.09.08至2027.03.08（结束日不含）：9月7日GOLD提前收市，9月8日无假期调整。规则、源码和参数已预登记；未来数据与结果仍为PENDING，不能查看结果后改起点。</p>',
              '<p>单策略及组合盈利均为历史研究结果；修正风险恢复后有无交互变化必须看同条件结果。保证金原生统计若为未定义/零观测，则不能宣称保证金压力已通过。</p>',
              '<p>原生Recovery与文档定义不一致时保留原值，项目净值恢复公式另算。余额DD漂亮不能替代净值DD。</p>',
              '<p><a href="https://github.com/chanteck123-ux/TX-AI---EA-GOLD-Trading/pull/5">GitHub研究草稿 PR #5</a> · 正式Champion与历史归档不变。</p>',
              '<p>参考：<a href="https://www.metatrader5.com/en/terminal/help/algotrading/testing">MT5测试与延迟</a>；<a href="https://www.mql5.com/en/docs/constants/environment_state/statistics">MQL5统计定义</a>；<a href="https://www.mql5.com/en/docs/standardlibrary/tradeclasses/ctrade/ctradepositionclosepartial">部分平仓与服务器结果检查</a>。</p>',
              '<p>第三方GitHub仅作概念研究；未复制受限实现。GoldTraderEA缺少明确复用许可，EA_SCALPER_XAUUSD含非商业/交易限制，不能直接移植。</p>',
              '<p>生成时间：'+esc(datetime.now().astimezone().isoformat(timespec='seconds'))+'。'+('本次研究交付。' if final else '当前为构建预览，测试仍可能进行中。')+'</p></section>']
    css='''body{margin:0;background:#f3f5f5;color:#182125;font:14px/1.65 "Microsoft YaHei",sans-serif;letter-spacing:0}main{max-width:1420px;margin:auto;padding:24px}header{border-top:5px solid #197d70;padding:16px 0 20px}h1{font-size:28px;margin:4px 0 12px}h2{font-size:21px;margin:0 0 12px}h3{font-size:17px}.eyebrow{color:#39645d;margin:0}.status{color:#982b34;font-weight:700}nav{display:flex;gap:18px;flex-wrap:wrap}a{color:#176697}section{padding:24px 0;border-top:1px solid #cbd4d5}table{border-collapse:collapse;width:100%;background:white;font-variant-numeric:tabular-nums}td,th{padding:9px;border:1px solid #cbd4d5;text-align:right;white-space:nowrap}th{background:#e2eeeb;color:#21453e}td:first-child,th:first-child{text-align:left}tr:nth-child(even){background:#f7f9fa}.scroll{overflow-x:auto;margin:12px 0;max-width:100%}details{border-top:1px solid #cbd4d5;padding:14px 0}summary{cursor:pointer;font-weight:600;overflow-wrap:anywhere}p{overflow-wrap:anywhere}.flags{color:#943f22;font-size:12px}.hash{font:12px/1.8 Consolas,monospace;overflow-wrap:anywhere}.curve{display:block;width:100%;height:auto;background:#fff}figure{margin:0}figcaption{font-size:12px;overflow-wrap:anywhere}.flow{display:grid;justify-items:center;gap:4px}.flow div{background:#e7edef;border-left:4px solid #2d8073;padding:10px 14px;max-width:100%;box-sizing:border-box;text-align:center}.flow b{color:#48776d}@media(max-width:600px){main{padding:14px}h1{font-size:24px}h2{font-size:19px}td,th{padding:7px}}'''
    return '<!doctype html><html lang="zh-CN"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>FxPro黄金3-SOP研究报告</title><style>'+css+'</style></head><body><main>'+''.join(parts)+'</main></body></html>'


def main():
    rows=json.loads(read(ROOT/'reports/RESEARCH_RESULTS.json'))
    diagnostics=json.loads(read(ROOT/'reports/RESEARCH_DIAGNOSTICS.json'))
    target=ROOT/'reports/FXPRO_RESEARCH_FINAL_CN.html'
    target.write_text(render(rows,diagnostics),encoding='utf-8')
    print(target)


if __name__ == '__main__':
    main()
