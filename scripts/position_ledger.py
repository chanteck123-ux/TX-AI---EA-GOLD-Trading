"""Fee-inclusive position statistics; partial deals never inflate trade count."""
import csv
from collections import defaultdict
from pathlib import Path
from trade_cost_audit import stats


def aggregate(rows, expected_net=None):
    grouped = defaultdict(list)
    seen = set()
    for row in rows:
        deal = row['Deal']
        if deal in seen:
            raise ValueError('DUPLICATE_DEAL')
        seen.add(deal)
        grouped[row['PositionID']].append(row)
    positions, open_positions = [], []
    for identifier, deals in grouped.items():
        owners = {(d['Magic'], d['Symbol']) for d in deals}
        if len(owners) != 1:
            raise ValueError('MIXED_POSITION_OWNER')
        entries = [d for d in deals if int(d['Entry']) == 0]
        exits = [d for d in deals if int(d['Entry']) in (1, 3)]
        if len(entries)+len(exits) != len(deals) or not entries:
            raise ValueError('UNSUPPORTED_POSITION_REVERSAL')
        directions = {int(d['Type']) for d in entries}
        if len(directions) != 1 or any(int(d['Type']) in directions for d in exits):
            raise ValueError('INCONSISTENT_DEAL_DIRECTION')
        vin = sum(float(d['Volume']) for d in entries)
        vout = sum(float(d['Volume']) for d in exits)
        if vout > vin+1e-8:
            raise ValueError('EXIT_VOLUME_EXCEEDS_ENTRY')
        result = dict(PositionID=identifier, Magic=entries[0]['Magic'],
                      Direction='BUY' if next(iter(directions)) == 0 else 'SELL',
                      NetUSD=sum(float(d[k]) for d in deals for k in ('Profit', 'Commission', 'Swap', 'Fee')),
                      Volume=vin, ExitVolume=vout, EntryDeals=len(entries), ExitDeals=len(exits),
                      CommissionUSD=sum(float(d['Commission']) for d in deals),
                      SwapUSD=sum(float(d['Swap']) for d in deals),
                      EntryTime=min(int(d['TimeMsc']) for d in entries),
                      ExitTime=max((int(d['TimeMsc']) for d in exits), default=None))
        (positions if abs(vin-vout) <= 1e-8 else open_positions).append(result)
    positions.sort(key=lambda p: (p['ExitTime'], int(p['PositionID'])))
    total = sum(p['NetUSD'] for p in positions+open_positions)
    if expected_net is not None and abs(total-expected_net) > .011:
        raise ValueError('LEDGER_NATIVE_NET_MISMATCH')
    run = maximum = 0
    for p in positions:
        run = run+1 if p['NetUSD'] < 0 else 0
        maximum = max(maximum, run)
    return dict(Positions=positions, OpenPositions=open_positions, NetUSD=total,
                Complete=stats(positions), BUY=stats([p for p in positions if p['Direction']=='BUY']),
                SELL=stats([p for p in positions if p['Direction']=='SELL']),
                MaxConsecutiveLosses=maximum,
                ByMagic={magic: stats([p for p in positions if p['Magic']==magic])
                         for magic in sorted({p['Magic'] for p in positions})})


def read_ledger(path: Path, expected_net=None):
    with path.open(encoding='utf-8-sig', newline='') as file:
        return aggregate(list(csv.DictReader(file)), expected_net)
