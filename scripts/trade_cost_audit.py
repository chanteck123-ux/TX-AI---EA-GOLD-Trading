"""Reconcile complete one-entry/one-exit positions before reporting net trade stats.

Partial fills/exits are deliberately unsupported here, not counted as extra trades.
"""
import re


def native_deals(rows):
    header = None
    deals = []
    for row in rows:
        if {'时间', '成交', '趋势', '手续费', '库存费', '盈利'}.issubset(row):
            header = row
        elif header and len(row) == len(header) and re.fullmatch(r'\d{4}\.\d{2}\.\d{2} .*', row[0]):
            deals.append(dict(zip(header, row)))
    return deals


def num(value):
    return float(value.replace(' ', '').replace(',', ''))


def stats(rows):
    values = [r['NetUSD'] for r in rows]
    wins, losses = [x for x in values if x > 0], [x for x in values if x < 0]
    aw = sum(wins)/len(wins) if wins else None
    al = sum(losses)/len(losses) if losses else None
    return dict(Trades=len(values), NetUSD=round(sum(values), 8),
                PF=sum(wins)/abs(sum(losses)) if losses else None,
                WinRatePct=len(wins)/len(values)*100 if values else None,
                AverageWinUSD=aw, AverageLossUSD=al, RealizedRR=aw/abs(al) if aw is not None and al else None,
                ExpectancyNetUSD=sum(values)/len(values) if values else None,
                BreakEvenWinRatePct=abs(al)/(aw+abs(al))*100 if aw is not None and al else None)


def audit(rows, reviews, expected_count, expected_net, fee_estimate_per_lot):
    deals = [d for d in native_deals(rows) if d['类型'] in ('buy', 'sell')]
    entries, exits = [d for d in deals if d['趋势'] == 'in'], [d for d in deals if d['趋势'] == 'out']
    result = dict(Status='NOT_RECONCILED', Flags=[], Positions=[],
                  CommissionUSD=sum(num(d['手续费']) for d in deals),
                  SwapUSD=sum(num(d['库存费']) for d in deals),
                  NativeDealNetUSD=sum(num(d[k]) for d in deals for k in ('盈利', '手续费', '库存费')))
    if abs(result['NativeDealNetUSD']-expected_net) > 0.011:
        result['Flags'].append('NATIVE_DEAL_NET_MISMATCH')
    if not expected_count and not deals and not reviews:
        result['Status'] = 'NO_TRADES'
        return result
    if (len(entries) != expected_count or len(exits) != expected_count or len(reviews) != expected_count
            or len({t['PositionID'] for t in reviews}) != expected_count or len(deals) != 2*expected_count):
        result['Flags'].append('PARTIAL_OR_COMPLEX_POSITION_AUDIT_REQUIRED')
        return result
    for t in reviews:
        ins = [d for d in entries if d['订单'] == t['PositionID']]
        outs = [d for d in exits if d['成交'] == t['ExitDeal']]
        if len(ins) != 1 or len(outs) != 1:
            result['Flags'].append('POSITION_DEAL_LINK_MISSING')
            return result
        entry, close = ins[0], outs[0]
        if (entry['时间'] != t['EntryTime'] or close['时间'] != t['ExitTime']
                or entry['类型'].upper() != t['Direction']
                or close['类型'] == entry['类型']
                or abs(num(entry['交易量'])-num(close['交易量'])) > 1e-8
                or abs(num(entry['价位'])-num(t['Entry'])) > 0.006
                or abs(num(entry['交易量'])-num(t['Volume'])) > 1e-8):
            result['Flags'].append('POSITION_DEAL_DETAILS_MISMATCH')
            return result
        net = sum(num(d[k]) for d in (entry, close) for k in ('盈利','手续费','库存费'))
        if abs(net-num(t['Profit'])) > 0.011:
            result['Flags'].append('COMPLETE_POSITION_NET_MISMATCH')
            return result
        commission = -sum(num(d['手续费']) for d in (entry, close))
        estimated_fee = fee_estimate_per_lot*num(t['Volume'])
        side = 1 if t['Direction'] == 'BUY' else -1
        slippage_price = max(0.0, side*(num(t['InitialSL'])-num(close['价位']))) if t['ExitReason'] == 'DEAL_REASON_SL' else None
        result['Positions'].append(dict(PositionID=t['PositionID'], Direction=t['Direction'],
                                        NetUSD=round(net, 8), Volume=num(t['Volume']), CommissionUSD=commission,
                                        EstimatedFeeUSD=estimated_fee, FeeShortfallUSD=max(0.0,commission-estimated_fee),
                                        StopAdversePrice=slippage_price, InitialSLRiskUSD=num(t['ActualSLRiskMoney']),
                                        LossClassification=t['LossClassification'], ChaseEntry=t['ChaseEntry'],
                                        MFEUSD=num(t['MFE_Money']), MAEUSD=num(t['MAE_Money'])))
    if not result['Flags']:
        result['Status'] = 'RECONCILED_COMPLETE_POSITIONS'
    if any(p['FeeShortfallUSD'] > 1e-8 for p in result['Positions']):
        result['Flags'].append('FEE_ESTIMATE_UNDERSTATED')
    result['NetStats'] = stats(result['Positions'])
    result['BUY'] = stats([p for p in result['Positions'] if p['Direction'] == 'BUY'])
    result['SELL'] = stats([p for p in result['Positions'] if p['Direction'] == 'SELL'])
    result['MaximumStopAdversePrice'] = max((p['StopAdversePrice'] or 0 for p in result['Positions']), default=None)
    result['MaximumFeeShortfallUSD'] = max((p['FeeShortfallUSD'] for p in result['Positions']), default=None)
    return result
