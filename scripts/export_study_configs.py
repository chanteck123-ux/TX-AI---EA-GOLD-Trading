"""Archive exact tested SET/INI files for the research branch, without credentials."""
import json
import shutil
from summarize_runs import ROOT,read,sha


def archive(source,target):
    if target.exists():
        if sha(source)!=sha(target): raise ValueError('EXISTING_CONFIG_HASH_CONFLICT')
        return
    target.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(source,target)
    if sha(source)!=sha(target): raise ValueError('CONFIG_COPY_MISMATCH')


def main():
    rows=json.loads(read(ROOT/'reports/RESEARCH_RESULTS.json'))
    wanted={'R_C01','S_C02','I_C01','W_C01'}
    for name in ('CORE','STRESS'):
        m=json.loads(read(ROOT/'research'/('TEST_MATRIX_'+name+'.json')))
        wanted.update(c['ID'] for c in m['Cases'])
    records=[]
    for row in rows:
        if row['CandidateID'] not in wanted: continue
        folder=ROOT/'reports/runs'/row['Run']
        paths={'.set':ROOT/'sets/FxPro/research-20260906'/(row['Run']+'.set'),
               '.ini':ROOT/'config/backtest/research-20260906'/(row['Run']+'.ini')}
        for ext,target in paths.items():
            source=folder/(row['Run']+ext)
            for line in read(source).splitlines():
                if '=' in line and line.split('=',1)[0].strip().lower() in ('login','password','investor','proxylogin','proxypassword'):
                    raise ValueError('CREDENTIAL_FIELD_BLOCKED')
            archive(source,target)
        records.append(dict(Run=row['Run'],SourceSHA256=row['SourceSHA256'],EX5SHA256=row['EX5SHA256'],
                            SET=str(paths['.set'].relative_to(ROOT)).replace('\\','/'),SETSHA256=row['SETSHA256'],
                            INI=str(paths['.ini'].relative_to(ROOT)).replace('\\','/'),
                            INISHA256=sha(paths['.ini']),NativeReportSHA256=row['ReportSHA256']))
    (ROOT/'reports/RESEARCH_CONFIG_INDEX.json').write_text(json.dumps(records,ensure_ascii=False,indent=2),encoding='utf-8')
    print('EXACT_TESTED_CONFIGS_EXPORTED',len(records))


if __name__=='__main__': main()
