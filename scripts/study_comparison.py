"""Compare effective native inputs, tester conditions and complete trade paths."""
import json
from compare_sc01 import AUDIT_INPUTS, ini_values, trade_signature
from summarize_runs import ROOT, read, fields_of, normalize
from build_study_report import choose, FIELDS

RUNNER_DEFAULTS = dict(InpIntradayRunner='false', InpRunnerBreakEvenR='0.5',
                       InpRunnerTrailStartR='2', InpRunnerATRMultiple='2',
                       InpRunnerATRPeriod='14', InpRunnerRestartProbe='false')


def input_delta(a, b):
    return {k: [a.get(k), b.get(k)] for k in a.keys() | b.keys()
            if k not in AUDIT_INPUTS and a.get(k) != b.get(k)}


def validate_changes(delta, allowed):
    unexpected = {k: v for k, v in delta.items() if k not in allowed}
    if unexpected:
        raise ValueError('UNDECLARED_INPUT_CHANGE: '+str(unexpected))


def compare(base, candidate, allowed, label, equivalent=False):
    for key in ('Broker','Company','ServerHeader','Symbol','Period','CapitalUSD','Leverage',
                'HistoryQuality','Model','DelayMs','TerminalSHA256'):
        if base[key] != candidate[key]:
            raise ValueError('UNFAIR_'+key)
    folders = [ROOT/'reports/runs'/r['Run'] for r in (base,candidate)]
    inputs = []
    for r, folder in zip((base,candidate),folders):
        native = fields_of(folder/(r['Run']+'.htm'))[1]
        inputs.append({k: normalize(v) for k,v in (RUNNER_DEFAULTS | native).items()})
    delta = input_delta(*inputs)
    validate_changes(delta, allowed)
    if ini_values(folders[0]/(base['Run']+'.ini')) != ini_values(folders[1]/(candidate['Run']+'.ini')):
        raise ValueError('UNFAIR_TESTER_INI')
    match = trade_signature(base) == trade_signature(candidate)
    if equivalent and not match:
        raise ValueError('CONTROL_REPRODUCTION_FAILED_'+label)
    return dict(Label=label, Base=base['Run'], Candidate=candidate['Run'],
                AllowedInputs=sorted(allowed), ActualInputChanges=delta,
                Conditions='VERIFIED_NATIVE_INPUTS_AND_INI', TradeSignatureMatch=match,
                Deltas={k: candidate[k]-base[k] if candidate[k] is not None and base[k] is not None else None
                        for k in FIELDS},
                Note='Native random-delay runs share mode, not a controllable identical random seed.'
                     if base['DelayMs']==-1 else 'Same broker/date/risk/capital/leverage/model/delay.')


def main():
    rows=json.loads(read(ROOT/'reports/RESEARCH_RESULTS.json'))
    pairs=[]
    def add(a,b,allowed,label,equivalent=False):
        if a and b:
            pairs.append(compare(a,b,set(allowed),label,equivalent))
    for lane in ('Scalping','Intraday','Swing','Combined'):
        caps=[]
        if lane in ('Intraday','Combined'): caps.append('InpIntradayMaxTradesPerDay')
        if lane in ('Swing','Combined'): caps.append('InpSwingMaxTradesPerDay')
        add(choose(rows,'R_C01',lane),choose(rows,'CONTROL_FINAL',lane),caps,'FINAL_OFF_'+lane,True)
    for ident,lane,allowed in [('S_C02','Scalping',['InpScalpUseEMAFilter']),
                               ('I_C01','Intraday',['InpIntradayMaxTradesPerDay']),
                               ('W_C01','Swing',['InpSwingMaxTradesPerDay'])]:
        add(choose(rows,'R_C01',lane),choose(rows,ident,lane),allowed,ident)
    add(choose(rows,'CONTROL_FINAL','Intraday'),choose(rows,'I_C02_FIX2','Intraday'),
        ['InpIntradayRunner'],'I_C02_RUNNER')
    add(choose(rows,'I_C02_FIX2','Intraday'),choose(rows,'I_C02_FIX2_RESTART','Intraday'),
        ['InpRunnerRestartProbe'],'MEMORY_RESTART_NOT_OS_RESTART',True)
    add(choose(rows,'CONTROL_CAPACITY','Intraday',5000),choose(rows,'I_C02_CAPACITY','Intraday',5000),
        ['InpIntradayRunner'],'USD5000_DIAGNOSTIC_ONLY')
    for delay in (0,10,25,50,-1):
        add(choose(rows,'CONTROL_FINAL','Combined',delay=delay),choose(rows,'C_C01','Combined',delay=delay),
            ['InpIntradayRunner'],'COMBINED_DELAY_'+str(delay))
    for ident in ('I_C02_NEIGHBOR_18','I_C02_NEIGHBOR_22'):
        add(choose(rows,'I_C02_FIX2','Intraday'),choose(rows,ident,'Intraday'),
            ['InpRunnerATRMultiple'],ident)
    (ROOT/'reports/RESEARCH_COMPARISONS.json').write_text(json.dumps(pairs,ensure_ascii=False,indent=2),encoding='utf-8')
    for p in pairs:
        print(p['Label'],p['Conditions'],'SAME_PATH',p['TradeSignatureMatch'],p['Deltas'])


if __name__=='__main__':
    main()
