"""Build a research directory, never a Champion or Candidate ZIP."""
import argparse
import json
import os
import shutil
import subprocess
from datetime import datetime
from pathlib import Path
from html.parser import HTMLParser
from urllib.parse import unquote, urlsplit
from summarize_runs import ROOT, read, sha, fields_of
from build_study_report import render, choose


def copy(source, target):
    target.parent.mkdir(parents=True,exist_ok=True)
    def native(path):
        value=str(path.resolve())
        return '\\\\?\\'+value if os.name=='nt' and not value.startswith('\\\\?\\') else value
    shutil.copy2(native(source),native(target))
    if sha(source)!=sha(target): raise ValueError('COPY_HASH_MISMATCH')


def validate_links(root):
    class Links(HTMLParser):
        def __init__(self): super().__init__();self.links=[]
        def handle_starttag(self,tag,attrs):
            for k,v in attrs:
                if k in ('href','src') and v: self.links.append(v)
    count=0
    for file in [root/'FINAL_REPORT_CN.html']:
        parser=Links();parser.feed(read(file))
        for link in parser.links:
            parts=urlsplit(link)
            if parts.scheme or not parts.path: continue
            target=file.parent/unquote(parts.path)
            if not target.exists(): raise ValueError('BROKEN_LOCAL_LINK_'+str(target))
            count+=1
    return count


def verify(root):
    entries=[]
    for line in read(root/'SHA256.txt').splitlines():
        digest,name=line.split('  ',1)
        file=(root/name).resolve()
        if not file.is_relative_to(root.resolve()): raise ValueError('MANIFEST_PATH_ESCAPE')
        if sha(file)!=digest: raise ValueError('DELIVERY_HASH_MISMATCH_'+name)
        entries.append(name)
    files={p.relative_to(root).as_posix() for p in root.rglob('*') if p.is_file() and p!=root/'SHA256.txt'}
    if set(entries)!=files: raise ValueError('UNMANIFESTED_FILE_OR_DUPLICATE')
    if len(entries)!=len(set(entries)): raise ValueError('DUPLICATE_MANIFEST_ENTRY')
    print(json.dumps(dict(Delivery=str(root),Files=len(entries),LocalLinks=validate_links(root),
                          ManifestSHA256=sha(root/'SHA256.txt'),Status='RESEARCH_FILES_VERIFIED_NOT_TRADING_APPROVAL')))


def main():
    parser=argparse.ArgumentParser();parser.add_argument('--output',default='outputs/FXPRO_RESEARCH')
    parser.add_argument('--verify-only',action='store_true');args=parser.parse_args()
    target=(ROOT/args.output).resolve()
    if not target.is_relative_to((ROOT/'outputs').resolve()): raise ValueError('DELIVERY_OUTSIDE_OUTPUTS')
    if args.verify_only: verify(target);return
    validation=json.loads(read(ROOT/'reports/RESEARCH_VALIDATION.json'))
    if any(m['Missing'] for m in validation['Matrices']): raise ValueError('MATRIX_NOT_FINISHED')
    if validation['Champions']!='NONE' or validation['LiveApproved']: raise ValueError('RESEARCH_STATUS_REQUIRED')
    if sha(ROOT/'src/GSM_FxPro_RESEARCH.mq5')!=validation['SourceSHA256']: raise ValueError('SOURCE_DRIFT')
    if sha(ROOT/'src/GSM_FxPro_RESEARCH.ex5')!=validation['EX5SHA256']: raise ValueError('BINARY_DRIFT')
    if target.exists(): raise ValueError('DELIVERY_EXISTS_DO_NOT_OVERWRITE_USE_VERIFY_ONLY')
    rows=json.loads(read(ROOT/'reports/RESEARCH_RESULTS.json'))
    diagnostics=json.loads(read(ROOT/'reports/RESEARCH_DIAGNOSTICS.json'))
    target.mkdir(parents=True)
    compile_path=ROOT/validation['CompileEvidence']
    current_compile=json.loads(read(compile_path))
    copy(ROOT/'src/GSM_FxPro_RESEARCH.mq5',target/'CODE/GSM_FxPro_RESEARCH.mq5')
    copy(ROOT/'src/GSM_FxPro_RESEARCH.ex5',target/'CODE/GSM_FxPro_RESEARCH.ex5')
    for dep in current_compile['Dependencies']:
        file=Path(dep)
        if file.parent==ROOT/'src': copy(file,target/'CODE'/file.name)
    compile_dirs={compile_path.parent}
    evidence_rows=list(rows)
    for row in evidence_rows:
        folder=ROOT/'reports/runs'/row['Run'];record=json.loads(read(folder/'RUN.json'))
        for file in folder.iterdir():
            if file.is_file(): copy(file,target/'REPORTS'/folder.name/file.name)
        source=Path(record['Source']).name
        for cpath in (ROOT/'reports/compile').glob('*/COMPILE.json'):
            c=json.loads(read(cpath))
            if c.get('EX5SHA256')==record['EX5SHA256'] and c.get('SourceSHA256')==record['SourceSHA256']:
                compile_dirs.add(cpath.parent)
    for test in validation['NativeTests']:
        folder=ROOT/'reports/runs'/test['Run'];record=json.loads(read(folder/'RUN.json'))
        alias='INTEGRATION' if 'INTEGRATION' in test['Run'] else 'RULES'
        for file in folder.iterdir():
            if file.is_file(): copy(file,target/'EVIDENCE/TESTS'/alias/file.name)
        for cpath in (ROOT/'reports/compile').glob('*/COMPILE.json'):
            c=json.loads(read(cpath))
            if c.get('EX5SHA256')==record['EX5SHA256']: compile_dirs.add(cpath.parent)
        copy(ROOT/record['Source'],target/'EVIDENCE/TEST_SOURCE'/Path(record['Source']).name)
    for folder in compile_dirs:
        for file in folder.iterdir():
            if file.is_file(): copy(file,target/'EVIDENCE/COMPILE'/folder.name/file.name)
    for folder in (ROOT/'reports/runs').glob('HISTORY_PROBE_*'):
        for file in folder.iterdir():
            if file.is_file(): copy(file,target/'EVIDENCE/HISTORY_PROBE'/file.name)
    profiles=[]
    specifications=[('CONTROL_FINAL',lane,2000,0) for lane in ('Scalping','Intraday','Swing','Combined')]+[
        ('I_C02_FIX2','Intraday',2000,0),('C_C01','Combined',2000,0)]+[
        ('CAPACITY_500',lane,500,0) for lane in ('Scalping','Intraday','Swing','Combined')]
    for ident,lane,capital,delay in specifications:
        row=choose(rows,ident,lane,capital,delay)
        if not row: raise ValueError('DELIVERY_PROFILE_MISSING')
        folder=ROOT/'reports/runs'/row['Run']
        alias=f'{ident}_{lane}_USD{capital}'
        copy(folder/(row['Run']+'.set'),target/'SETS/FxPro'/(alias+'.set'))
        copy(folder/(row['Run']+'.ini'),target/'CONFIG'/row['Run']/(row['Run']+'.ini'))
        copy(folder/(row['Run']+'.set'),target/'CONFIG'/row['Run']/(row['Run']+'.set'))
        effective=fields_of(folder/(row['Run']+'.htm'))[1]
        (target/'CONFIG'/row['Run']/'EFFECTIVE_INPUTS.json').write_text(json.dumps(effective,ensure_ascii=False,indent=2),encoding='utf-8')
        profiles.append(dict(Name=alias,Run=row['Run'],SourceSHA256=row['SourceSHA256'],
                             EX5SHA256=row['EX5SHA256'],SETSHA256=row['SETSHA256'],ConfigSHA256=row['ConfigSHA256']))
    # UI-only preset is explicitly separate from the exact tester SET.
    base=choose(rows,'CONTROL_FINAL','Combined');file=ROOT/'reports/runs'/base['Run']/(base['Run']+'.set')
    ui=read(file)
    for key in ('InpDrawZones','InpShowPanel','InpEnableChartSwitches'):
        ui=ui.replace(key+'=false',key+'=true')
    (target/'SETS/FxPro/CONTROL_Combined_PANEL_ONLY_NOT_TESTED.set').write_text(ui,encoding='utf-8')
    for file in (ROOT/'reports').glob('RESEARCH_*'):
        if file.is_file(): copy(file,target/'RESEARCH'/file.name)
    for name in ('FXPRO_RESEARCH_DELIVERY_PROTOCOL.md','FXPRO_PROGRAM_FLOW_CN.md',
                 'I-C02_ENGINEERING_FAILURE.md','NATIVE_STATISTICS_DISCREPANCY.md',
                 'RESEARCH_RED_TEAM_CN.md','OOS_PREREGISTRATION_CN.md','OOS_PREREGISTRATION.json','OOS_CALENDAR_CONFIRMATION.json',
                 'TEST_MATRIX_CORE.json','TEST_MATRIX_STRESS.json'):
        copy(ROOT/'research'/name,target/'RESEARCH'/name)
    for name in ('EXTERNAL_GITHUB_GOLD_EA_SOURCE_RESEARCH_CN.md','EXTERNAL_GITHUB_GOLD_EA_SOURCE_RESEARCH_EN.md'):
        copy(ROOT/'docs'/name,target/'RESEARCH'/name)
    copy(ROOT/'README_RESEARCH_CN.md',target/'README_RESEARCH_CN.md')
    report=render(rows,diagnostics,evidence_prefix='REPORTS/',final=True)
    (target/'FINAL_REPORT_CN.html').write_text(report,encoding='utf-8')
    manifest=dict(Generated=datetime.now().astimezone().isoformat(),Kind='RESEARCH_NOT_CHAMPION',
                  Version='4.23 research build',CodeCommit='8326fbab6ee8beb2a0db77aa1f1663e08c4bff41',
                  Broker='FxPro',Symbol='GOLD',MainCapitalUSD=2000,Leverage=100,RealTradingEnabled=False,
                  SourceSHA256=validation['SourceSHA256'],EX5SHA256=validation['EX5SHA256'],
                  CompileResult=validation['CompileResult'],Dependencies=current_compile['Dependencies'],
                  Profiles=profiles,Default='CONTROL_FINAL_Combined_USD2000; runner OFF, Scalping EMA ON',
                  Acceptance='NO_NEW_CHAMPION_FUTURE_OOS_SAMPLE_AND_CRITICAL_GATES_PENDING',
                  GitHub='https://github.com/chanteck123-ux/TX-AI---EA-GOLD-Trading/pull/5',
                  UIOnlyPreset='Untested UI-only variant, not the exact benchmark SET',
                  StandardLibrary='Install MT5 standard MQL5/Include SDK; broker-independent compile dependency, not copied external strategy code')
    (target/'MANIFEST.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2),encoding='utf-8')
    files=sorted(p for p in target.rglob('*') if p.is_file())
    (target/'SHA256.txt').write_text('\n'.join(sha(p)+'  '+p.relative_to(target).as_posix() for p in files)+'\n',encoding='utf-8')
    verify(target)
    summary=dict(Delivery=str(target),SourceSHA256=validation['SourceSHA256'],EX5SHA256=validation['EX5SHA256'],
                 ManifestSHA256=sha(target/'SHA256.txt'),Manifest=manifest,Files=len(files),
                 TotalBytes=sum(p.stat().st_size for p in files),ReportSHA256=sha(target/'FINAL_REPORT_CN.html'))
    (ROOT/'reports/RESEARCH_DELIVERY.json').write_text(json.dumps(summary,ensure_ascii=False,indent=2),encoding='utf-8')


if __name__=='__main__': main()
