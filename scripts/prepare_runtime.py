"""Stage verified MetaQuotes binaries with FxPro-only data, without services."""
import configparser
import hashlib
import json
import shutil
from datetime import datetime
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OLD = ROOT.parent/'backtest-v220/fxpro-terminal'
INSTALLED = Path.home()/'AppData/Roaming/Tradona Markets MT5 Terminal'
TARGET = ROOT/'runtime/fxpro-6182'
EXPECTED = {
    'terminal64.exe': '3DBB5F966441FC043D49BC637A5931686BE847E77DC89E295C944EDA6B9A08C7',
    'metatester64.exe': 'DC54AC9265F693B2E469F06DDD7CC7A083F0A44F00B4A1CE199B98DB3AA15E97',
    'MetaEditor64.exe': '197CA3DD8D1971831366F54CB57BF3F120B420700E573135509D406E4E23709E',
}


def digest(path):
    with path.open('rb') as handle:
        return hashlib.file_digest(handle, 'sha256').hexdigest().upper()


def read_config(path):
    raw = path.read_bytes()
    encoding = 'utf-16' if raw[:2] in (b'\xff\xfe', b'\xfe\xff') else 'utf-8-sig'
    cfg = configparser.ConfigParser(interpolation=None, strict=False)
    cfg.optionxform = str
    cfg.read_string(raw.decode(encoding))
    return cfg


def main():
    for name, expected in EXPECTED.items():
        assert digest(INSTALLED/name) == expected, 'SIGNED_RUNTIME_CHANGED'
    common = read_config(OLD/'Config/common.ini')
    server = common.get('Common', 'Server')
    login = common.get('Common', 'Login')
    assert server == 'FxPro-MT5 Demo' and login.isdigit(), 'FXPRO_DEMO_CONTEXT_REQUIRED'
    assert not TARGET.exists(), 'RUNTIME_EXISTS_RECONCILE_DO_NOT_OVERWRITE'
    TARGET.mkdir(parents=True)
    for name in EXPECTED:
        shutil.copy2(INSTALLED/name, TARGET/name)
        assert digest(TARGET/name) == EXPECTED[name]
    (TARGET/'Config').mkdir()
    # Reuse only the existing local MT5 account database; never expose its contents.
    for name in ['accounts.dat', 'servers.dat']:
        shutil.copy2(OLD/'Config'/name, TARGET/'Config'/name)
    clean = configparser.ConfigParser(interpolation=None)
    clean.optionxform = str
    clean.read_dict({'Common': {'Login': login, 'Server': server, 'NewsEnable': '0'},
                     'Experts': {'Enabled': '0', 'AllowLiveTrading': '0', 'AllowDllImport': '0'},
                     'StartUp': {'Expert': '', 'Script': ''}, 'Charts': {'ProfileLast': 'Empty'},
                     'Email': {'Enable': '0'}, 'Notification': {'Enable': '0'}})
    with (TARGET/'Config/common.ini').open('w', encoding='utf-16') as out:
        clean.write(out, space_around_delimiters=False)
    for directory in ['MQL5/Experts', 'MQL5/Profiles/Tester', 'MQL5/Profiles/Charts/Empty',
                      'Tester', 'logs']:
        (TARGET/directory).mkdir(parents=True, exist_ok=True)
    copies = []
    for directory in ['history', 'ticks', 'symbols']:
        source = OLD/'Bases'/server/directory
        dest = TARGET/'Bases'/server/directory
        shutil.copytree(source, dest)
        for file in sorted(source.rglob('*')):
            if file.is_file():
                relative = file.relative_to(source)
                original_hash = digest(file)
                assert digest(dest/relative) == original_hash, 'FXPRO_DATA_COPY_MISMATCH'
                copies.append({'File': f'{directory}/{relative.as_posix()}', 'SHA256': original_hash,
                               'Bytes': file.stat().st_size})
    record = dict(Created=datetime.now().astimezone().isoformat(), TerminalRoot=str(TARGET),
                  Build=6182, BrokerServer=server, RuntimeSource=str(INSTALLED),
                  RuntimeProvenance='Valid MetaQuotes signatures verified before staging; generic binaries only',
                  BinaryHashes=EXPECTED, DataSource=str(OLD/'Bases'/server), DataFiles=copies,
                  LiveTradingEnabled=False, ServiceChanges=False, OldRuntimeModified=False)
    (TARGET/'RUNTIME.json').write_text(json.dumps(record, indent=2), encoding='utf-8')
    (ROOT/'RUNTIME_CHECKPOINT.json').write_text(json.dumps(record, indent=2), encoding='utf-8')
    print(json.dumps({k: v for k,v in record.items() if k != 'DataFiles'}))
    print(f'FXPRO_DATA_FILES_BYTE_VERIFIED={len(copies)}')


if __name__ == '__main__':
    main()
