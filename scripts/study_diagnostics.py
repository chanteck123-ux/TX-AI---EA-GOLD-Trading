"""Explicitly separate observed positions from analytical cost stress estimates."""
import csv
import json
import re
from collections import Counter
from audit_study import plans_of
from summarize_runs import ROOT, read
from trade_cost_audit import stats


def diagnose(row):
    folder = ROOT/'reports/runs'/row['Run']
    path = folder/(row['Run']+'_TRADE_REVIEW.csv')
    reviews = list(csv.DictReader(read(path).splitlines())) if path.exists() else []
    positions = row.get('PositionLedger', {}).get('Positions', row['CompleteTradeCostAudit'].get('Positions', []))
    review_by_id = {r['PositionID']: r for r in reviews}
    plans, logs = plans_of(folder)
    point_match = re.search(r'Digits=\d+ Point=([0-9.eE+-]+)', logs)
    point = float(point_match[1]) if point_match else None
    enriched = []
    for pos in positions:
        r = review_by_id.get(pos['PositionID'])
        if not r or point is None:
            continue
        distance = abs(float(r['Entry'])-float(r['InitialSL']))
        if distance <= 0:
            continue
        usd_per_price = float(r['ActualSLRiskMoney'])/distance
        spread = float(r['SpreadPoints'])*point*usd_per_price
        commission = abs(pos['CommissionUSD'])
        enriched.append(dict(PositionID=pos['PositionID'], NetUSD=pos['NetUSD'], EntrySpreadProxyUSD=spread,
                             CommissionUSD=commission, USDPerPrice=usd_per_price,
                             SLDistance=distance, InitialSLRiskUSD=float(r['ActualSLRiskMoney']),
                             InitialSLRiskPct=float(r['ActualSLRiskPercent']),
                             CalculatedLot=float(r['CalculatedVolume']), ActualLot=float(r['Volume']),
                             MAEUSD=float(r['MAE_Money']), MFEUSD=float(r['MFE_Money']),
                             HeuristicLossClassification=r['LossClassification'], ChaseEntry=r['ChaseEntry']))
    complete = len(enriched) == len(positions)
    scenarios = []
    if complete and positions:
        for spread_extra, fee_extra, slip_price in ((.5,.5,0),(1,1,0),(0,0,.1),(1,1,.3)):
            adjusted = [dict(NetUSD=p['NetUSD']-p['EntrySpreadProxyUSD']*spread_extra-
                             p['CommissionUSD']*fee_extra-p['USDPerPrice']*slip_price) for p in enriched]
            scenarios.append(dict(ExtraSpreadFraction=spread_extra, ExtraCommissionFraction=fee_extra,
                                  ExtraRoundTripAdversePrice=slip_price, CompletePositionStats=stats(adjusted),
                                  EquityDD=None, Method='ANALYTICAL_FIXED_TRADE_PATH_NOT_MT5_RERUN'))
    average_cost = sum(p['EntrySpreadProxyUSD']+p['CommissionUSD'] for p in enriched)/len(enriched) if enriched else None
    net_payoff = row['NetProfitUSD']/row['Trades'] if row['Trades'] else None
    return dict(Run=row['Run'], ReconciledCount=len(enriched), ExpectedCount=len(positions), Complete=complete,
                PositionRiskCost=enriched, AverageEntrySpreadAndCommissionProxyUSD=average_cost,
                EdgeToCostProxy=net_payoff/average_cost if average_cost else None,
                CostProxyLimit='Entry spread proxy is not measured round-trip spread or causal cost attribution.',
                AnalyticalCostStress=scenarios,
                PlannedSingleCapPct=max((float(p['SingleCapPct']) for p in plans),default=None),
                MaxAggregatePlannedPct=max((float(p['TotalPct']) for p in plans),default=None),
                MaxInitialMarginAtOrderCheckUSD=max((float(p['InitialMarginUsed']) for p in plans),default=None),
                MaxRecordedMAEUSD=max((p['MAEUSD'] for p in enriched),default=None),
                MaxRecordedMFEUSD=max((p['MFEUSD'] for p in enriched),default=None),
                MaxRecordedMFEInInitialR=max((p['MFEUSD']/p['InitialSLRiskUSD'] for p in enriched
                                             if p['InitialSLRiskUSD']>0),default=None),
                LossHeuristics=dict(Counter(p['HeuristicLossClassification'] for p in enriched if p['NetUSD']<0)),
                ChaseFlagCount=sum(p['ChaseEntry']=='YES' for p in enriched),
                RawRequestRiskFailures=logs.count('STRICT_ACCOUNT_RISK_BLOCK|'),
                Warnings=['Heuristic loss labels are not proven causes.',
                          'Maximum adverse price/SL risk is not guaranteed fill risk.',
                          'Analytical cost stress cannot validate changed signals, fills, or equity drawdown.'])


def main():
    rows=json.loads(read(ROOT/'reports/RESEARCH_RESULTS.json'))
    result=[diagnose(row) for row in rows]
    (ROOT/'reports/RESEARCH_DIAGNOSTICS.json').write_text(json.dumps(result,ensure_ascii=False,indent=2),encoding='utf-8')
    print('DIAGNOSTICS',len(result),'COST_PATH_COMPLETE',sum(r['Complete'] for r in result))


if __name__ == '__main__':
    main()
