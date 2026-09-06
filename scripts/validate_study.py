"""Capture actual Python/native test evidence and immutable source checks."""
import argparse
import hashlib
import json
import re
import subprocess
import sys
from datetime import datetime
from pathlib import Path
from summarize_runs import ROOT, read, sha, fields_of
from compare_sc01 import AUDIT_INPUTS

FROZEN={
 'src/GSM_FxPro_R_C00.mq5':'989F19C997F5B095A67727BF0C88492B3777F2CCF2682A02D954DBBE18CAE19A',
 'src/GSM_FxPro_R_C01.mq5':'CCED6620AAA43B8D30F2DC88208CBEB799F6F26EFDC14A8F6CD05873EE195F4E',
 'src/GSM_FxPro_S_C01.mq5':'1C851244DD2A321C2E44917DE8B9371F24E6A74E1E06E52AE36188245BE50F6E',
}


def main():
    parser=argparse.ArgumentParser();parser.add_argument('--final',action='store_true');args=parser.parse_args()
    for file,digest in FROZEN.items():
        if sha(ROOT/file)!=digest: raise ValueError('FROZEN_INTEGRITY_FAIL_'+file)
    workspace=ROOT.parents[1]
    protected=workspace/'work/baseline-audit-20260905'
    for file,digest in {
        protected/'repository/champion/current/GSM_GOLD_3SOP_EA_V4.00_CURRENT_CHAMPION.zip':'43AF3C393B6C226211115A1A1DBC70C88F0F07250FA332D22C04C3ED64EB80E2',
        protected/'package/CODE/GSM_Gold_3SOP_EA_CHAMPION.mq5':'AC9826E6EF4959562B9079A1FF9B8CBB35E5E8C2A913E431488CA5C900D1FF60',
    }.items():
        if sha(file)!=digest: raise ValueError('CURRENT_CHAMPION_INTEGRITY_FAIL')
    compile_paths=list((ROOT/'reports/compile').glob('GSM_FxPro_RESEARCH_*/COMPILE.json'))
    matches=[]
    for path in compile_paths:
        c=json.loads(read(path))
        if c.get('SourceSHA256')!=sha(ROOT/'src/GSM_FxPro_RESEARCH.mq5') or c.get('EX5SHA256')!=sha(ROOT/'src/GSM_FxPro_RESEARCH.ex5'): continue
        if all(sha(Path(file))==digest for file,digest in c['Dependencies'].items()): matches.append((path,c))
    if len(matches)!=1: raise ValueError('CURRENT_COMPILE_PROOF_AMBIGUOUS')
    path,compile_proof=matches[0]
    if compile_proof['Stage']!='COMPILE_PASS' or '0 errors, 0 warnings' not in compile_proof['Result']:
        raise ValueError('COMPILE_NOT_PASSED')
    if sha(path.parent/'MetaEditor.log')!=compile_proof['LogSHA256']: raise ValueError('COMPILER_LOG_DRIFT')
    prereg_path=ROOT/'research/OOS_PREREGISTRATION.json'
    prereg=json.loads(read(prereg_path))
    calendar_path=ROOT/'research/OOS_CALENDAR_CONFIRMATION.json'
    calendar=json.loads(read(calendar_path))
    if sha(prereg_path)!=calendar['OriginalPreregistrationSHA256']:
        raise ValueError('OOS_PREREGISTRATION_DRIFT')
    if any(prereg[key]!=compile_proof[key] for key in ('SourceSHA256','EX5SHA256','Dependencies')):
        raise ValueError('OOS_FROZEN_CODE_DRIFT')
    for profile in prereg['Profiles']:
        native=fields_of(ROOT/'reports/runs'/profile['DevelopmentRun']/(profile['DevelopmentRun']+'.htm'))[1]
        params={k:v for k,v in native.items() if k not in AUDIT_INPUTS}
        digest=hashlib.sha256(json.dumps(params,sort_keys=True,separators=(',',':')).encode()).hexdigest().upper()
        if params!=profile['Parameters'] or digest!=profile['ParametersSHA256']:
            raise ValueError('OOS_PARAMETER_DRIFT')
    if (calendar['OfficialStartInclusive']!='2026.09.08' or
            calendar['OfficialEndExclusive']!='2027.03.08' or
            calendar['CodeOrParametersChanged'] or calendar['FutureQuotesOrResultsViewed']):
        raise ValueError('OOS_CALENDAR_OR_FREEZE_INVALID')
    run=subprocess.run([sys.executable,'-m','unittest','discover','-s','tests','-v'],cwd=ROOT,capture_output=True,text=True,encoding='utf-8',errors='replace')
    log=run.stdout+run.stderr
    (ROOT/'reports/RESEARCH_PYTHON_TESTS.txt').write_text(log,encoding='utf-8')
    if run.returncode: raise ValueError('PYTHON_TEST_FAILURE')
    count=re.search(r'Ran (\d+) tests',log)
    if not count: raise ValueError('TEST_COUNT_MISSING')
    native=[]
    for prefix,marker in [('RUNNER_RULES_','RUNNER_RULES_SUMMARY'),('RUNNER_INTEGRATION_FIX2_','RUNNER_INTEGRATION_SUMMARY')]:
        folders=list((ROOT/'reports/runs').glob(prefix+'*'))
        if len(folders)!=1: raise ValueError('NATIVE_FIXTURE_EVIDENCE_AMBIGUOUS')
        folder=folders[0];record=json.loads(read(folder/'RUN.json'))
        if record['SourceSHA256']!=sha(ROOT/record['Source']): raise ValueError('FIXTURE_SOURCE_DRIFT')
        for dep,digest in record['CompileEvidence']['Dependencies'].items():
            if sha(Path(dep))!=digest: raise ValueError('FIXTURE_DEPENDENCY_DRIFT')
        logs='\n'.join(read(p) for p in folder.glob('*.log.txt'))
        match=re.search(marker+r'\|Checks=(\d+)\|Failures=(\d+)',logs)
        if not match or int(match[2]): raise ValueError('NATIVE_FIXTURE_FAILURE')
        native.append(dict(Run=record['Run'],Checks=int(match[1]),Failures=int(match[2]),
                           SourceSHA256=record['SourceSHA256'],EX5SHA256=record['EX5SHA256'],
                           Type='NATIVE_MQL_MOCK_SERVER_REAL_HEADER' if 'INTEGRATION' in marker else 'NATIVE_MQL_PURE_RULES'))
    rows=json.loads(read(ROOT/'reports/RESEARCH_RESULTS.json'))
    matrices=[]
    for name in ('TEST_MATRIX_CORE.json','TEST_MATRIX_STRESS.json'):
        matrix=json.loads(read(ROOT/'research'/name))
        completed=[];missing=[]
        for case in matrix['Cases']:
            candidates=[r for r in rows if r['CandidateID']==case['ID'] and r['Strategy']==case['Lane'] and
                        r['CapitalUSD']==case['Capital'] and r['DelayMs']==case['Delay'] and
                        r['EX5SHA256']==matrix['EX5SHA256'] and r['SourceSHA256']==matrix['SourceSHA256']]
            if len(candidates)==1:
                r=candidates[0]
                record=json.loads(read(ROOT/'reports/runs'/r['Run']/'RUN.json'))
                if record['InputOverrides']!=case['Inputs']: raise ValueError('MATRIX_INPUT_DRIFT')
                if not all(r['RealTickEvidence'][k] for k in ('Model4','NativeModelLog','Ticks')):
                    raise ValueError('NATIVE_TICK_EVIDENCE_MISSING')
                completed.append(r['Run'])
            else: missing.append(case)
        matrices.append(dict(File=name,SHA256=sha(ROOT/'research'/name),Completed=completed,Missing=missing))
    if args.final and any(m['Missing'] for m in matrices): raise ValueError('REQUIRED_RESEARCH_RUNS_INCOMPLETE')
    result=dict(Generated=datetime.now().astimezone().isoformat(),FrozenIntegrity='PASS',
                CompileEvidence=str(path.relative_to(ROOT)),CompileResult=compile_proof['Result'],
                SourceSHA256=compile_proof['SourceSHA256'],EX5SHA256=compile_proof['EX5SHA256'],
                PythonTests=int(count[1]),PythonFailures=0,PythonLogSHA256=sha(ROOT/'reports/RESEARCH_PYTHON_TESTS.txt'),
                NativeTests=native,Matrices=matrices,ResearchEvidenceCount=len(rows),
                OOS='FUTURE_PENDING',OOSPreregistrationSHA256=sha(prereg_path),
                OOSCalendarConfirmationSHA256=sha(calendar_path),
                OOSStartInclusive=calendar['OfficialStartInclusive'],
                OOSEndExclusive=calendar['OfficialEndExclusive'],Champions='NONE',LiveApproved=False,
                Remaining=['Future six-month untouched OOS and >100 complete positions per lane',
                           'OS-level terminal crash/restart and real broker partial/timeout faults',
                           'Native changed spread/commission cost rerun',
                           'Tick-level simultaneous portfolio risk/margin and per-engine combined equity'])
    (ROOT/'reports/RESEARCH_VALIDATION.json').write_text(json.dumps(result,ensure_ascii=False,indent=2),encoding='utf-8')
    print(json.dumps({k:v for k,v in result.items() if k not in ('Matrices',)},ensure_ascii=False))


if __name__=='__main__': main()
