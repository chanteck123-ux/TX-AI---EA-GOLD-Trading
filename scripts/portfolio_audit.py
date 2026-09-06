"""Observed deal-level exposure; no invented tick equity or margin statistics."""
from collections import defaultdict
import csv
import json
from summarize_runs import ROOT, read


def exposure(rows):
    active={}
    per_magic=defaultdict(int)
    peak=peak_long=peak_short=0
    opposite=False
    simultaneous_pairs=set()
    for d in sorted(rows,key=lambda r:(int(r['TimeMsc']),int(r['Deal']))):
        key=d['PositionID']; volume=float(d['Volume'])
        if int(d['Entry'])==0:
            p=active.setdefault(key,dict(Magic=d['Magic'],Direction=int(d['Type']),Volume=0.0))
            p['Volume']+=volume
        elif int(d['Entry']) in (1,3):
            if key not in active: raise ValueError('EXIT_WITHOUT_POSITION')
            active[key]['Volume']-=volume
            if active[key]['Volume'] < -1e-8: raise ValueError('OVER_CLOSE')
            if active[key]['Volume']<=1e-8: del active[key]
        else: raise ValueError('NETTING_OR_REVERSAL_NOT_SUPPORTED')
        counts=defaultdict(int)
        for p in active.values(): counts[p['Magic']]+=1
        for magic,n in counts.items(): per_magic[magic]=max(per_magic[magic],n)
        longs=sum(p['Direction']==0 for p in active.values())
        shorts=len(active)-longs
        peak=max(peak,len(active)); peak_long=max(peak_long,longs); peak_short=max(peak_short,shorts)
        opposite=opposite or bool(longs and shorts)
        owners=sorted(counts)
        simultaneous_pairs.update((a,b) for i,a in enumerate(owners) for b in owners[i+1:])
    return dict(PeakPositions=peak,PeakLongPositions=peak_long,PeakShortPositions=peak_short,
                PeakPerMagic=dict(per_magic),ObservedOppositeExposure=opposite,
                SimultaneousMagicPairs=sorted(simultaneous_pairs),UnclosedPositions=len(active),
                PositionLimitPass=peak<=3 and all(n<=1 for n in per_magic.values()),
                EquityCorrelation=None,PerEngineCombinedEquityDD=None,PeakTickMargin=None,
                Limits='Deal snapshots verify concurrency, not tick equity, margin stress or independence.')


def main():
    rows=json.loads(read(ROOT/'reports/RESEARCH_RESULTS.json'))
    result=[]
    for row in rows:
        if row['Strategy']!='Combined': continue
        path=ROOT/'reports/runs'/row['Run']/(row['Run']+'_DEALS.csv')
        if not path.exists(): continue
        result.append(dict(Run=row['Run'],**exposure(list(csv.DictReader(read(path).splitlines())))))
    (ROOT/'reports/RESEARCH_PORTFOLIO.json').write_text(json.dumps(result,ensure_ascii=False,indent=2),encoding='utf-8')
    print(json.dumps(result,ensure_ascii=False))


if __name__=='__main__':
    main()
