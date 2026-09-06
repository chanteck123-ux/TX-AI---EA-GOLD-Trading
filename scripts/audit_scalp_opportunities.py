"""Reconcile observed events, without inventing P/L for rejected signals."""
import collections
import csv
import datetime as dt
import json
import re

from summarize_runs import ROOT, read, sha

RUN = 'R_C00_Scalping_USD1000_D0_20260906_203616'


def classify(row):
    reason = row['RejectReason']
    if row['RawCore'] == 'NO':
        return 'CORE_REVERSAL_FAILED'
    if reason.startswith('Scalping HTF Regime'):
        return 'HTF_REJECTED'
    if reason.startswith('EMA+RSI'):
        return 'EMA_'+('FAIL' if 'EMA FAIL' in reason else 'PASS')+'_RSI_'+('FAIL' if 'RSI FAIL' in reason else 'PASS')
    if row['Accepted'] == 'YES':
        return 'ACCEPTED_BEFORE_ORDER_RISK'
    return 'UNCLASSIFIED'


def audit():
    folder = ROOT/'reports/runs'/RUN
    signals = folder/(RUN+'_SIGNAL_AUDIT.csv')
    rows = list(csv.DictReader(read(signals).splitlines()))
    if len({(r['Time'],r['ZoneID'],r['Direction']) for r in rows}) != len(rows):
        raise ValueError('DUPLICATE_SIGNAL_EVENTS_REQUIRE_REVIEW')
    touches, broken = {}, collections.defaultdict(list)
    logs = sorted(folder.glob('*.log.txt'))
    for file in logs:
        for stamp, text in re.findall(r'\t(\d{4}\.\d{2}\.\d{2} \d{2}:\d{2}:\d{2})\s+([^\r\n]+)', read(file)):
            touch = re.search(r'First Touch原子锁定：Strategy=Scalping M5 ZoneID=(\S+) Time=([^\r\n]+?) Price=', text)
            event = re.search(r'区域BROKEN：ZoneID=(\S+)', text)
            if touch:
                if touch[1] in touches:
                    raise ValueError('REPEATED_FIRST_TOUCH_ZONE')
                touches[touch[1]] = touch[2]
            if event:
                broken[event[1]].append(stamp)
    evaluated = {r['ZoneID'] for r in rows}
    if evaluated-set(touches):
        raise ValueError('EVALUATED_ZONE_WITHOUT_TOUCH_PROOF')
    missing = []
    for zone in sorted(set(touches)-evaluated):
        first = dt.datetime.strptime(touches[zone], '%Y.%m.%d %H:%M:%S')
        expected = first.replace(minute=(first.minute//5)*5, second=0)+dt.timedelta(minutes=5)
        later = sorted(t for t in broken[zone] if t >= touches[zone])
        stamp = later[0] if later else None
        seconds = (dt.datetime.strptime(stamp, '%Y.%m.%d %H:%M:%S')-expected).total_seconds() if stamp else None
        missing.append(dict(ZoneID=zone, FirstTouch=touches[zone], BrokenAfterTouch=stamp,
                            SecondsAfterNominalM5Close=seconds))
    groups = collections.Counter(classify(r) for r in rows)
    baseline = json.loads(read(folder/'AUDIT.json'))
    funnel = next(f for f in baseline['Funnels'] if f['SOP'].startswith('Scalping'))
    if (len(touches) != int(funnel['FirstTouches']) or
            sum(r['RawCore'] == 'YES' for r in rows) != int(funnel['HardSOPPassed']) or groups['UNCLASSIFIED']):
        raise ValueError('FUNNEL_EVENT_RECONCILIATION_FAILED')
    result = dict(Run=RUN, SourceSHA256=baseline['SourceSHA256'], EX5SHA256=baseline['EX5SHA256'],
                  SignalFileSHA256=sha(signals), LogSHA256={p.name:sha(p) for p in logs},
                  FirstTouches=len(touches), EvaluatedUniqueZones=len(evaluated), Groups=dict(groups),
                  TouchesNotEvaluated=missing,
                  MissingWithBrokenAfterTouch=sum(p['BrokenAfterTouch'] is not None for p in missing),
                  MissingBrokenBeforeNominalClose=sum(p['SecondsAfterNominalM5Close'] is not None and
                                                     p['SecondsAfterNominalM5Close'] < 0 for p in missing),
                  NominalCloseLagDistribution=dict(collections.Counter(str(p['SecondsAfterNominalM5Close']) for p in missing)),
                  UntradedCounterfactualNet='NOT_MEASURED', MissedProfitableTrades='UNKNOWN',
                  Inference='EMA-only ablation may increase candidate opportunity count, not proven trading profit.',
                  NoEAOrParameterChange=True, NewChampion=False)
    (ROOT/'reports/SCALP_OPPORTUNITY_AUDIT.json').write_text(json.dumps(result, ensure_ascii=False, indent=2), encoding='utf-8')
    lines = ['# Scalping 机会审计', '', '这是日志核对，不是新 Candidate，也没有给被过滤的信号虚构盈亏。', '',
             f'控制组：{RUN}，FxPro GOLD，USD1000 / 1:100 / 0ms，2026.01.05–2026.08.26。', '',
             '| 项目 | 事件数 |', '|---|---:|', f'| 原生首次触区 | {len(touches)} |',
             f'| 进入收盘反转判断的独立区域 | {len(evaluated)} |']
    labels = {'CORE_REVERSAL_FAILED':'反转核心不合格', 'HTF_REJECTED':'核心合格但 H4 方向拒绝',
              'EMA_FAIL_RSI_FAIL':'EMA、RSI 同时拒绝', 'EMA_FAIL_RSI_PASS':'只有 EMA 拒绝',
              'EMA_PASS_RSI_FAIL':'只有 RSI 拒绝', 'ACCEPTED_BEFORE_ORDER_RISK':'通过信号过滤，进入订单风险判断'}
    lines += [f'| {labels[k]} | {v} |' for k,v in groups.items()]
    lines += ['', '## 不应混淆的地方', '',
              f'- {len(missing)} 次触区没有进入反转判断，其中 {result["MissingWithBrokenAfterTouch"]} 次在触区后有 BROKEN 记录。具体时间见 JSON；不能直接算成漏掉的盈利单。',
              '- OnTick 先运行区域有效性检查，再运行 Scalping 收盘信号；已破坏区域不应重新当成 Fresh。',
              '- EMA 拒绝 147 与 RSI 拒绝 88 有 74 次重叠，不能相加说成 235 个独立机会。',
              '- 只有 EMA 拒绝的 73 次，可作为下一轮单变量研究的观察对象。但未测后续盈亏、成交及资金路径，不代表关闭 EMA 就会多赚 73 单。',
              '- $500 下当前固定 SL 加费用仍超 1% 最小手数预算。提高资金带来的手数增大不算策略改善；不能偷偷放宽风险。',
              '- 外部 GitHub 只参考闭合事件、状态和单变量验证方法，未复制实现。',
              '- 优先判断真正可交易机会与风控承受能力；不为凑交易数放回已破坏区域，不增加 Scalping 利润保护。', '',
              '源码核对：RunScalpingM5、ExecuteScalpFirstTouch、UpdateZoneOnClosedBar、OnTick。',
              '完整日志哈希、事件分类与触区后破坏时间见 SCALP_OPPORTUNITY_AUDIT.json。', '']
    (ROOT/'reports/SCALP_OPPORTUNITY_AUDIT_CN.md').write_text('\n'.join(lines), encoding='utf-8')
    print(json.dumps({k:v for k,v in result.items() if k not in {'TouchesNotEvaluated','LogSHA256'}}, ensure_ascii=False))
    return result


if __name__ == '__main__':
    audit()
