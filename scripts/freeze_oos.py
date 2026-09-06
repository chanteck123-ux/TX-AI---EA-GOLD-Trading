"""One-time preregistration; calendar confirmation is deliberately not fabricated."""
import hashlib
import json
from datetime import datetime
from summarize_runs import ROOT, read, fields_of, sha
from build_study_report import choose
from compare_sc01 import AUDIT_INPUTS


def main():
    target=ROOT/'research/OOS_PREREGISTRATION.json'
    if target.exists():
        print('EXISTING_PREREGISTRATION_PRESERVED',sha(target));return
    validation=json.loads(read(ROOT/'reports/RESEARCH_VALIDATION.json'))
    compile_proof=json.loads(read(ROOT/validation['CompileEvidence']))
    rows=json.loads(read(ROOT/'reports/RESEARCH_RESULTS.json'))
    profiles=[]
    for ident,lane in [('CONTROL_FINAL',x) for x in ('Scalping','Intraday','Swing','Combined')]+[
        ('I_C02_FIX2','Intraday'),('C_C01','Combined')]:
        row=choose(rows,ident,lane)
        if not row: raise ValueError('OOS_PROFILE_MISSING_'+ident+lane)
        native=fields_of(ROOT/'reports/runs'/row['Run']/(row['Run']+'.htm'))[1]
        params={k:v for k,v in native.items() if k not in AUDIT_INPUTS}
        canonical=json.dumps(params,sort_keys=True,separators=(',',':')).encode()
        profiles.append(dict(ID=ident,Lane=lane,DevelopmentRun=row['Run'],
                             Parameters=params,ParametersSHA256=hashlib.sha256(canonical).hexdigest().upper()))
    record=dict(Registered=datetime.now().astimezone().isoformat(),
                Status='FROZEN_RULES_PENDING_BROKER_CALENDAR_CONFIRMATION',
                SourceSHA256=validation['SourceSHA256'],EX5SHA256=validation['EX5SHA256'],
                Dependencies=compile_proof['Dependencies'],
                StartRule='Next complete FxPro GOLD trading day after freeze; server date',
                EndRule='Exactly six calendar months after the confirmed start, exclusive',
                TentativeStart='2026.09.08',TentativeEndExclusive='2027.03.08',
                OfficialStart=None,OfficialEndExclusive=None,
                CalendarSource='https://www.fxpro.com/trading-tools/market-holidays',
                CalendarConfirmation='PENDING_NO_GOLD_DAY_DETAIL_VERIFIED',
                CapitalUSD=2000,Leverage=100,Model=4,FixedDelaysMs=[0,10,25,50],NativeRandom=True,
                RiskSinglePct=1,RiskAggregatePct=3,CompleteTradesPerLaneMustExceed=100,
                NoUnblinding=True,NoEarlyStop=True,NoParameterRetuning=True,
                AutomaticLiveTrading=False,Profiles=profiles)
    target.write_text(json.dumps(record,ensure_ascii=False,indent=2),encoding='utf-8')
    print('OOS_RULES_PREREGISTERED_CALENDAR_PENDING',sha(target))


if __name__=='__main__': main()
