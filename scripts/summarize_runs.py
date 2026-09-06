"""Parse native MT5 reports and preserve unknown metrics instead of inventing them."""
import csv
import hashlib
import html
import io
import json
import re
from html.parser import HTMLParser
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def read(path):
    raw = path.read_bytes()
    return raw.decode('utf-16' if raw[:2] in (b'\xff\xfe', b'\xfe\xff') else 'utf-8-sig')


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest().upper()


class TableParser(HTMLParser):
    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.rows, self.row, self.cell = [], None, None

    def handle_starttag(self, tag, attrs):
        if tag == 'tr':
            self.row = []
        elif tag in ('td', 'th') and self.row is not None:
            self.cell = []

    def handle_data(self, data):
        if self.cell is not None:
            self.cell.append(data)

    def handle_endtag(self, tag):
        if tag in ('td', 'th') and self.cell is not None:
            self.row.append(' '.join(''.join(self.cell).split()))
            self.cell = None
        elif tag == 'tr' and self.row is not None:
            self.rows.append(self.row)
            self.row = None


def number(value):
    return float(value.replace(' ', '').replace(',', '').removesuffix('%'))


def pair(value):
    match = re.fullmatch(r'([-\d .,]+)\s*\(([-\d .,]+)%?\)', value)
    if not match:
        raise ValueError(f'Unexpected pair: {value}')
    return number(match[1]), number(match[2])


def fields_of(report):
    parser = TableParser()
    parser.feed(read(report))
    fields, inputs = {}, {}
    for row in parser.rows:
        for i, cell in enumerate(row):
            if cell.startswith('Inp') and '=' in cell:
                key, value = cell.split('=', 1)
                inputs[key] = value
            elif cell.endswith(':') and i+1 < len(row):
                fields.setdefault(cell, row[i+1])
    return fields, inputs


def normalize(value):
    value = value.split('||')[0].strip().lower()
    try:
        return float(value)
    except ValueError:
        return value


def summarize(record_path):
    record = json.loads(read(record_path))
    if record['Lane'] == 'UnitTests' or record['Stage'] != 'REPORT_CREATED_PENDING_AUDIT':
        return None
    folder, name = record_path.parent, record['Run']
    report = folder / (name+'.htm')
    assert sha(report) == record['ReportSHA256'], 'REPORT_HASH_MISMATCH'
    assert sha(folder / (name+'.set')) == record['SETSHA256'], 'SET_HASH_MISMATCH'
    assert sha(folder / (name+'.ini')) == record['ConfigSHA256'], 'CONFIG_HASH_MISMATCH'
    f, inputs = fields_of(report)
    required = ['总净盈利:', '最大净值亏损:', '相对净值亏损:', '交易总计:', '初始入金:',
                '盈利交易 (% 全部):', '亏损交易 (% 全部):', '期间:', '质量历史:', '杠杆:']
    assert all(k in f for k in required), ('REPORT_FIELDS_MISSING', report)
    net = number(f['总净盈利:'])
    count = int(number(f['交易总计:']))
    dd_money, _ = pair(f['最大净值亏损:'])
    dd_pct = number(f['相对净值亏损:'].split('%')[0])
    wins, win_pct = pair(f['盈利交易 (% 全部):'])
    losses, _ = pair(f['亏损交易 (% 全部):'])
    flags = ['RESEARCH_NOT_CHAMPION', 'NOT_UNTOUCHED_OOS']
    archived = folder / Path(record['Source']).with_suffix('.ex5').name
    if not archived.exists() or sha(archived) != record['EX5SHA256']:
        flags.append('BINARY_ARCHIVE_MISSING')
    if record.get('TerminalSHA256') != record.get('TerminalEndSHA256') or not record.get('TerminalSHA256'):
        flags.append('TERMINAL_VERSION_CHAIN_INCOMPLETE')
    if count <= 100:
        flags.append('LOW_SAMPLE_SIZE')
    if dd_pct > 30:
        flags.append('EQUITY_DD_HARD_REJECT')
    elif dd_pct > 15:
        flags.append('HUMAN_REVIEW_REQUIRED')
    recovery = net/dd_money if dd_money else None
    if recovery is None or recovery <= 3:
        flags.append('RECOVERY_GATE_NOT_PASSED')
    if record['DelayMs'] == 0:
        flags.append('NO_DELAY_ONLY')
    funnel_path = folder / (name+'_SIGNAL_FUNNEL.csv')
    funnels = list(csv.DictReader(io.StringIO(read(funnel_path)))) if funnel_path.exists() else []
    rejected = sum(int(row['OrdersRejected']) for row in funnels) if funnels else None
    if rejected is None:
        flags.append('REJECT_EVIDENCE_MISSING')
    elif rejected:
        flags.append('BROKER_REJECT')
    trade_path = folder / (name+'_TRADE_REVIEW.csv')
    trades = list(csv.DictReader(io.StringIO(read(trade_path)))) if trade_path.exists() else []
    if count and len(trades) != count:
        flags.append('COMPLETE_TRADE_AUDIT_MISMATCH')
    if count == 0:
        flags.append('NO_FILLED_TRADES')
    gross_loss = number(f['毛损:'])
    avg_win = number(f['平均 获利交易:']) if wins else None
    avg_loss = number(f['平均 亏损交易:']) if losses else None
    expectancy = ((wins*(avg_win or 0)+losses*(avg_loss or 0))/count) if count else None
    configured = dict(line.split('=', 1) for line in read(folder / (name+'.set')).splitlines() if '=' in line)
    # Input declarations must come from the tested revision, not today's source.
    snapshots = [p for p in (ROOT/'reports/compile').glob('*/'+Path(record['Source']).name)
                 if sha(p) == record['SourceSHA256']]
    source_text = read(snapshots[0]) if snapshots else ''
    complete_declarations = False
    dependencies = record.get('CompileEvidence', {}).get('Dependencies', {})
    for snapshot in snapshots:
        own_headers = [p for p in snapshot.parent.glob('*.mqh')]
        expected = {Path(k).name: v for k, v in dependencies.items()
                    if Path(k).name in {'StrictRisk.mqh', 'RiskMath.mqh'}}
        if expected and all(any(p.name == name and sha(p) == digest for p in own_headers)
                            for name, digest in expected.items()):
            source_text = read(snapshot)+'\n'+'\n'.join(read(p) for p in own_headers)
            complete_declarations = True
            break
    if not complete_declarations:
        flags.append('TESTED_SOURCE_DEPENDENCY_SNAPSHOT_INCOMPLETE')
    declared = set(re.findall(r'(?m)^\s*input\s+\w+\s+(Inp\w+)\s*=', source_text))
    mismatches = {k: [v, inputs.get(k)] for k, v in configured.items()
                  if k in declared and normalize(v) != normalize(inputs.get(k, '<MISSING>'))}
    if mismatches:
        flags.append('SET_REPORT_MISMATCH')
    logs = '\n'.join(read(p) for p in folder.glob('*.log.txt'))
    risk_lines = re.findall(r'STRICT_RISK_PLAN\|[^\r\n]+', logs)
    plans = [dict(item.split('=', 1) for item in line.split('|')[1:] if '=' in item) for line in risk_lines]
    if count and not plans:
        flags.append('RISK_PLAN_EVIDENCE_MISSING')
    if any(float(p['PlannedPct']) > 1.0001 or float(p['TotalPct']) > 3.0001 for p in plans):
        flags.append('PLANNED_RISK_BREACH')
    if '真实报价' not in f['质量历史:'] or not f['质量历史:'].startswith('100%'):
        flags.append('REAL_TICK_COVERAGE_NOT_100')
    technical = [float(x) for x in re.findall(r'TechnicalMinEquity=([\d.]+)', logs)]
    result = dict(Run=name, Strategy=record['Lane'], CapitalUSD=record['Capital'],
                  NetProfitUSD=net, MaxEquityDDPct=dd_pct, ProfitFactor=number(f['盈利因子:']) if gross_loss else None,
                  Trades=count, WinRatePct=win_pct if count else None, Reject=rejected,
                  MaxEquityDDUSD=dd_money, ReturnPct=net/record['Capital']*100, RecoveryEquity=recovery,
                  AverageWin=avg_win, AverageLoss=avg_loss,
                  RealizedRR=avg_win/abs(avg_loss) if avg_win is not None and avg_loss else None,
                  ExpectancyRounded=expectancy, ExpectedPayoff=number(f['预期收益:']) if count else None,
                  BUY=pair(f['买入交易 (赢得 %):']), SELL=pair(f['卖出交易 (赢得 %):']),
                  ConsecutiveLosses=pair(f['最大值 连败 ($):'])[0],
                  MaximumActualSLRiskPct=max((float(t['ActualSLRiskPercent']) for t in trades), default=None),
                  MaximumPlannedRiskPct=max((float(p['PlannedPct']) for p in plans), default=None),
                  MaximumAggregatePlannedRiskPct=max((float(p['TotalPct']) for p in plans), default=None),
                  MinimumTechnicalEquityAtRejectedSetups=min(technical, default=None),
                  Broker=record['Broker'], Symbol=f['交易品种:'], Period=f['期间:'], Leverage=f['杠杆:'],
                  HistoryQuality=f['质量历史:'], Model=record['Model'], DelayMs=record['DelayMs'],
                  SourceSHA256=record['SourceSHA256'], EX5SHA256=record['EX5SHA256'],
                  SETSHA256=record['SETSHA256'], ReportSHA256=record['ReportSHA256'],
                  Flags=flags, SetReportMismatches=mismatches,
                  SetReportAuditStatus='COMPLETE' if complete_declarations else 'PARTIAL_DECLARATIONS_ONLY',
                  Funnels=funnels, RiskPlanCount=len(plans),
                  TerminalVersion=record.get('TerminalVersion'), TerminalSHA256=record.get('TerminalSHA256'),
                  Verdict='RESEARCH_FURTHER_NO_PROMOTION')
    (folder/'AUDIT.json').write_text(json.dumps(result, ensure_ascii=False, indent=2), encoding='utf-8')
    return result


def main():
    rows = [r for p in sorted((ROOT/'reports/runs').glob('*/RUN.json')) if (r := summarize(p))]
    (ROOT/'reports/R_C00_RESULTS.json').write_text(json.dumps(rows, ensure_ascii=False, indent=2), encoding='utf-8')
    columns = ['Strategy', 'CapitalUSD', 'NetProfitUSD', 'MaxEquityDDPct', 'ProfitFactor', 'Trades', 'WinRatePct',
               'Reject', 'RecoveryEquity', 'MaximumActualSLRiskPct', 'MaximumPlannedRiskPct', 'Period', 'HistoryQuality', 'DelayMs', 'Verdict', 'Run']
    with (ROOT/'reports/R_C00_RESULTS.csv').open('w', newline='', encoding='utf-8-sig') as file:
        writer = csv.DictWriter(file, fieldnames=columns, extrasaction='ignore')
        writer.writeheader()
        writer.writerows(rows)
    for row in rows:
        print(json.dumps({k: row[k] for k in columns}, ensure_ascii=False))


if __name__ == '__main__':
    main()
