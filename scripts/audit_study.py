"""Research evidence adapter. Keep frozen one-exit reports unchanged."""
import csv
import json
import math
import re
from decimal import Decimal, ROUND_CEILING, ROUND_FLOOR
from pathlib import Path

from summarize_runs import ROOT, read, summarize, fields_of, number, pair
from position_ledger import read_ledger
from trade_cost_audit import estimated_fee


def runner_fee(volume, rate, digits, minimum='.01', step='.01'):
    v, r, m, s = map(Decimal, (str(volume), str(rate), str(minimum), str(step)))
    if not all(x.is_finite() for x in (v, r, m, s)) or min(v, m, s) <= 0 or r < 0:
        raise ValueError('INVALID_RUNNER_FEE_INPUT')
    quantum = Decimal(1).scaleb(-digits)
    side = lambda x: (x*r/2).quantize(quantum, rounding=ROUND_CEILING)
    half = (v/2/s).to_integral_value(rounding=ROUND_FLOOR)*s
    return float(side(v)+(side(half)+side(v-half) if min(half, v-half) >= m else side(v)))


def plans_of(folder):
    logs = '\n'.join(read(p) for p in folder.glob('*.log.txt'))
    return [dict(t.split('=', 1) for t in line.split('|')[1:] if '=' in t)
            for line in re.findall(r'STRICT_RISK_PLAN\|[^\r\n]+', logs)], logs


def audit(path):
    row = summarize(path)
    if row is None:
        return None
    folder, name = path.parent, row['Run']
    record = json.loads(read(path))
    fields, inputs = fields_of(folder/(name+'.htm'))
    row['CandidateID'] = record.get('CandidateId', name.split('_')[0])
    row['NativeProfitFactor'] = row['ProfitFactor']
    row['NativeTrades'] = row['Trades']
    row['NativeWinRatePct'] = row['WinRatePct']
    row['NativeBalanceRecovery'] = number(fields['采收率:']) if '采收率:' in fields else None
    ledger_path = folder/(name+'_DEALS.csv')
    plans, logs = plans_of(folder)
    specs = re.findall(r'SYMBOL_SPEC\|[^\r\n]+', logs)
    row['SymbolSpecification'] = dict(t.split('=', 1) for t in specs[0].split('|')[1:] if '=' in t) if specs else {}
    row['RunnerEvents'] = {key: logs.count('RUNNER_'+key+'|') for key in
                           ('MODIFY', 'PARTIAL', 'RECOVER', 'RESTART_PROBE', 'RECOVERY_FAILED_CLOSED',
                            'RECOVERY_DEFERRED_HISTORY', 'PARTIAL_SKIPPED_MIN_LOT', 'PARTIAL_UNRESOLVED_NO_RETRY')}
    if row['RunnerEvents']['RECOVERY_FAILED_CLOSED']:
        row['Flags'].append('ENGINEERING_RECOVERY_FAILURE_NOT_STRATEGY_EVIDENCE')
    if ledger_path.exists():
        ledger = read_ledger(ledger_path, row['NetProfitUSD'])
        native = {r['Metric']: float(r['Value']) for r in csv.DictReader(read(folder/(name+'_NATIVE_STATS.csv')).splitlines())}
        if abs(native['NetProfitUSD']-row['NetProfitUSD']) > .011:
            raise ValueError('NATIVE_STATS_NET_MISMATCH')
        if abs(native['MaxEquityDDPct']-row['MaxEquityDDPct']) > .011:
            raise ValueError('NATIVE_STATS_EQUITY_DD_MISMATCH')
        row['PositionLedger'] = ledger
        row['Reject'] = int(native['AllRequestRejects'])
        row['ManagementRequests'] = int(native['ManagementRequests'])
        row['AllRequests'] = int(native['AllRequests'])
        row['NativeBalanceRecovery'] = native['NativeBalanceRecovery']
        row['MinimumMarginLevel'] = native['MinMarginLevel'] if native['MinMarginLevel'] < 1e100 else None
        row['MinimumMarginLevelStatus'] = 'NATIVE_VALUE' if row['MinimumMarginLevel'] else 'NATIVE_SENTINEL_UNAVAILABLE'
        row['CompleteNetStats'] = ledger['Complete']
        row['NetBUY'], row['NetSELL'] = ledger['BUY'], ledger['SELL']
        row['ConsecutiveLosses'] = ledger['MaxConsecutiveLosses']
        # Supersede only legacy limitations that the full deal ledger actually resolves.
        resolved = {'COMPLETE_TRADE_AUDIT_MISMATCH', 'PARTIAL_OR_COMPLEX_POSITION_AUDIT_REQUIRED',
                    'INVALID_FEE_MODEL_OR_PRECISION', 'FEE_PLAN_MODEL_NOT_VERIFIED'}
        row['LegacyAuditFlags'] = list(row['Flags'])
        row['Flags'] = [f for f in row['Flags'] if f not in resolved]
        for p in plans:
            model = p.get('FeeModel', '')
            if model == 'ENTRY_TWO_EXITS_CEILING':
                spec = row['SymbolSpecification']
                expected = runner_fee(p['Volume'], p['FeeEstimateUSDPerLot'], int(p['CurrencyDigits']),
                                      spec['VolumeMin'], spec['VolumeStep'])
            else:
                expected = estimated_fee(p['Volume'], p['FeeEstimateUSDPerLot'], model, int(p['CurrencyDigits']))
            if abs(expected-float(p['FeeBudgetUSD'])) > 1e-8:
                raise ValueError('RESEARCH_FEE_PLAN_MISMATCH')
        row['ResearchFeePlanAudit'] = 'VERIFIED' if plans else 'UNOBSERVED_NO_REQUESTS'
        row['CommissionUSD'] = sum(p['CommissionUSD'] for p in ledger['Positions']+ledger['OpenPositions'])
        row['SwapUSD'] = sum(p['SwapUSD'] for p in ledger['Positions']+ledger['OpenPositions'])
        if ledger['OpenPositions']:
            row['Flags'].append('OPEN_POSITION_EVIDENCE_REQUIRES_REVIEW')
    else:
        cost = row['CompleteTradeCostAudit']
        row['CompleteNetStats'] = cost.get('NetStats', {'Trades': 0, 'PF': None, 'WinRatePct': None})
        row['NetBUY'], row['NetSELL'] = cost.get('BUY'), cost.get('SELL')
        row['CommissionUSD'], row['SwapUSD'] = cost['CommissionUSD'], cost['SwapUSD']
    complete = row['CompleteNetStats']
    row['Trades'], row['ProfitFactor'], row['WinRatePct'] = complete['Trades'], complete['PF'], complete['WinRatePct']
    if row['Trades'] <= 100 and 'LOW_SAMPLE_SIZE' not in row['Flags']:
        row['Flags'].append('LOW_SAMPLE_SIZE')
    if row['Reject'] and 'BROKER_REJECT' not in row['Flags']:
        row['Flags'].append('BROKER_REJECT')
    row['Flags'] = sorted(set(row['Flags']))
    row['DelayMode'] = record.get('DelayMode', 'FIXED_MILLISECONDS')
    row['ExecutionStressStatus'] = 'OBSERVED' if row['DelayMs'] else 'ZERO_DELAY_CONTROL'
    row['MaxBalanceDDUSD'] = pair(fields['最大结余亏损:'])[0]
    row['CalculatedBalanceRecovery'] = (row['NetProfitUSD']/row['MaxBalanceDDUSD']
                                        if row['MaxBalanceDDUSD'] else None)
    row['NativeRecovery'] = row['NativeBalanceRecovery']
    if (row['CalculatedBalanceRecovery'] is not None and row['NativeRecovery'] is not None and
            abs(row['CalculatedBalanceRecovery']-row['NativeRecovery']) > .03):
        row['Flags'].append('NATIVE_RECOVERY_DEFINITION_MISMATCH')
    if row['MaxEquityDDUSD'] > max(10, row['MaxBalanceDDUSD']*3):
        row['Flags'].append('BALANCE_EQUITY_DIVERGENCE_REVIEW')
    row['MarginUsageAtOrderChecksUSD'] = [float(p['InitialMarginUsed']) for p in plans]
    if plans and max(row['MarginUsageAtOrderChecksUSD'], default=0) == 0:
        row['Flags'].append('ZERO_OBSERVED_MARGIN_NOT_A_STRESS_PROOF')
    row['Verdict'] = 'NO_PROMOTION_PENDING_GATES'
    (folder/'STUDY_AUDIT.json').write_text(json.dumps(row, ensure_ascii=False, indent=2), encoding='utf-8')
    return row


def main():
    records = []
    for path in sorted((ROOT/'reports/runs').glob('*/RUN.json')):
        meta = json.loads(read(path))
        if meta.get('CandidateId') or (path.parent.name.startswith('R_C01_') and
                                      meta.get('Capital') == 2000 and meta.get('DelayMs') == 0):
            if row := audit(path):
                records.append(row)
    (ROOT/'reports/RESEARCH_RESULTS.json').write_text(json.dumps(records, ensure_ascii=False, indent=2), encoding='utf-8')
    columns = ['Run', 'Strategy', 'CapitalUSD', 'NetProfitUSD', 'MaxEquityDDPct', 'ProfitFactor', 'Trades',
               'WinRatePct', 'Reject', 'RecoveryEquity', 'NativeProfitFactor', 'NativeBalanceRecovery', 'DelayMs']
    with (ROOT/'reports/RESEARCH_RESULTS.csv').open('w', encoding='utf-8-sig', newline='') as f:
        w = csv.DictWriter(f, fieldnames=columns, extrasaction='ignore'); w.writeheader(); w.writerows(records)
    for r in records:
        print(json.dumps({k:r[k] for k in columns}, ensure_ascii=False))


if __name__ == '__main__':
    main()
