"""Read-only monitoring core for the TradingBrain LEAN research workspace (no MCP imports; unit-testable).

Hard limits of this module (by construction, not by convention):
* nothing here writes files, starts processes, compiles, runs backtests, sends orders or changes configuration;
* every path - whether supplied by a caller OR discovered internally (logs, summaries, receipts, stage records, source walks) -
  passes the same policy (`allowed`/`resolve_safe`): allow-listed roots only, no `..`, no NTFS stream syntax, no symbolic links,
  junctions or other reparse points on any component, no private/tooling directories, no credential/configuration files;
* every text that leaves this module is size-bounded and passed through ``redact``;
* status is derived from file CONTENT plus observed growth; a file merely existing, or a recent mtime alone, never means
  "running", "alive" or "passed".
"""
from __future__ import annotations

import datetime as _dt
import hashlib
import json
import os
import platform
import re
import stat
import sys
import time
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any, Iterator

VERSION = "1.2.1"

# --------------------------------------------------------------------------------------------- configuration
DEFAULT_WORKSPACE = Path(r"C:\Users\A\Documents\Codex\2026-09-10\v1-2-ea-mt5")
PROJECT_REL = Path("work/repair_research/lean_mcp_20261012")
HISTORICAL_LEAN_REL = [Path("work/repair_research/quantconnect_20260920"), Path("work/repair_research/lean_500_20260927"), Path("work/repair_research/mt5_iteration9_20261004")]
I18_EXEC_REL = Path("work/repair_research/mt5_iteration18_20261011/Claude/exec")

# MT5 Common/Files: only this project's audit outputs (by name), never terminal/account configuration.
MT5_COMMON_ALLOWED = re.compile(
    r"^(AUDIT_|CAPACITY_|CONTROL_|SCALPI\d|SCALP20|QC_|QC20|I9_|GSM_|V400|V410|v3\.20|TB_|TradingBrain)", re.IGNORECASE)

DENY_DIR_NAMES = {".git", ".venv", "venv", "private", "backups", "__pycache__", "node_modules", ".codex", ".claude", "dotnet_home", "nuget"}
DENY_FILE_RE = re.compile(
    r"(?i)(^\.env$|\.env\.|password|passwd|secret|credential|token|apikey|api_key|\.pem$|\.key$|\.pfx$|\.p12$|\.kdbx$|id_rsa|id_ed25519|"
    r"^accounts\.dat$|^servers\.dat$|^common\.ini$|^terminal\.ini$|^config\.toml$|\.lock$)")
TEXT_EXT = {".log", ".txt", ".jsonl", ".json", ".csv", ".md"}
SOURCE_EXT = {".cs", ".csproj", ".sln", ".props", ".mq5", ".mqh", ".py", ".json", ".md"}
SOURCE_SKIP_DIRS = {"bin", "obj", "verification"}

MAX_TAIL_LINES = 400
MAX_TAIL_BYTES = 64 * 1024
MAX_HASH_BYTES = 32 * 1024 * 1024
MAX_JSON_BYTES = 8 * 1024 * 1024
MAX_LIST = 200
MAX_SOURCE_FILES = 5000
FRESH_SECONDS_DEFAULT = 120.0
STABLE_PROBE_SECONDS = 0.15
LOG_SCAN_BYTES = 256 * 1024


@dataclass
class MonitorConfig:
    workspace: Path = DEFAULT_WORKSPACE
    mt5_common_files: Path | None = None
    fresh_seconds: float = FRESH_SECONDS_DEFAULT
    roots: dict[str, Path] = field(default_factory=dict)

    def __post_init__(self) -> None:
        self.workspace = Path(self.workspace)
        if self.mt5_common_files is None:
            appdata = os.environ.get("APPDATA")
            self.mt5_common_files = Path(appdata) / "MetaQuotes" / "Terminal" / "Common" / "Files" if appdata else None
        self.roots = {"workspace": self.workspace}
        if self.mt5_common_files is not None:
            self.roots["mt5_common_files"] = Path(self.mt5_common_files)

    @property
    def project(self) -> Path:
        return self.workspace / PROJECT_REL


class AccessDenied(Exception):
    """Raised for any path outside the allow-list or matching the private/credential deny-list."""


# --------------------------------------------------------------------------------------------- small helpers
def utc_now() -> str:
    return _dt.datetime.now(_dt.timezone.utc).isoformat(timespec="seconds")


def iso(ts: float | None) -> str | None:
    return None if ts is None else _dt.datetime.fromtimestamp(ts, _dt.timezone.utc).isoformat(timespec="seconds")


def platform_info() -> dict[str, Any]:
    return {"os": platform.platform(), "python": sys.version.split()[0], "pid": os.getpid()}


_REDACTIONS = [
    (re.compile(r'(?i)"([^"\n]*(?:token|password|passwd|secret|api[_-]?key|credential|private[_-]?key)[^"\n]*)"\s*:\s*"[^"\n]*"'), r'"\1": "<redacted>"'),
    (re.compile(r"(?i)\b(password|passwd|pwd|secret|token|api[_-]?key|authorization|access[_-]?key)\b\s*[:=]\s*\S+"), r"\1=<redacted>"),
    (re.compile(r"(?i)\bbearer\s+[A-Za-z0-9._\-]{8,}"), "Bearer <redacted>"),
    (re.compile(r"(?i)\b(login|account|acct)\b(\s*(?:#|no\.?|number|id)?\s*[:=#]?\s*)\d{5,}"), r"\1\2<redacted>"),
    (re.compile(r"[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}"), "<email-redacted>"),
    (re.compile(r"(?i)\b(sk|pk|ghp|gho|xox[abp])[-_][A-Za-z0-9\-_]{16,}"), "<key-redacted>"),
]


def redact(text: str) -> str:
    for pattern, repl in _REDACTIONS:
        text = pattern.sub(repl, text)
    return text


def _is_reparse(p: Path) -> bool:
    try:
        st = os.lstat(p)
    except (FileNotFoundError, NotADirectoryError):
        return False
    except OSError:
        return True  # unreadable metadata is treated as unsafe
    if stat.S_ISLNK(st.st_mode):
        return True
    attrs = getattr(st, "st_file_attributes", 0)
    return bool(attrs & getattr(stat, "FILE_ATTRIBUTE_REPARSE_POINT", 0x400))


def _norm(p: Path | str) -> str:
    return os.path.normcase(os.path.normpath(str(p)))


def _within(child: Path, root: Path) -> bool:
    c, r = _norm(child), _norm(root)
    return c == r or c.startswith(r.rstrip("\\/") + os.sep)


# --------------------------------------------------------------------------------------------- path policy (single policy for callers and internal discovery)
def resolve_safe(cfg: MonitorConfig, user_path: str, *, must_exist: bool = False) -> tuple[str, Path]:
    """Map a path to (root_id, absolute path) or raise AccessDenied. Accepts 'root_id:relative', a relative path, or an absolute path under a root."""
    if not isinstance(user_path, str) or not user_path.strip() or "\x00" in user_path or len(user_path) > 1024:
        raise AccessDenied("INVALID_PATH")
    raw = user_path.strip()
    root_id, rel = None, raw
    m = re.match(r"^(workspace|mt5_common_files):(?![\\/])(.*)$", raw)
    if m:
        root_id, rel = m.group(1), m.group(2)
    drive_abs = re.match(r"^[A-Za-z]:[\\/]", rel) is not None
    if ":" in (rel[2:] if drive_abs else rel):
        raise AccessDenied("INVALID_PATH")  # NTFS alternate data streams / unknown root prefixes
    rel_path = Path(rel)
    if not rel_path.is_absolute() and ".." in Path(os.path.normpath(rel or ".")).parts:
        raise AccessDenied("PATH_ESCAPE")
    if root_id and not drive_abs and rel_path.is_absolute():
        raise AccessDenied("INVALID_PATH")
    candidates = [(root_id, cfg.roots[root_id])] if root_id else list(cfg.roots.items())
    for rid, root in candidates:
        target = Path(os.path.normpath(str(rel_path if rel_path.is_absolute() else root / rel_path)))
        if not _within(target, root):
            continue
        _check_components(cfg, rid, root, target)
        if must_exist and not target.exists():
            raise AccessDenied("NOT_FOUND")
        return rid, target
    raise AccessDenied("OUTSIDE_ALLOWED_ROOTS")


def _check_components(cfg: MonitorConfig, rid: str, root: Path, target: Path) -> None:
    if _is_reparse(root):
        raise AccessDenied("ROOT_IS_REPARSE_POINT")
    rel_parts = Path(os.path.relpath(target, root)).parts if _norm(target) != _norm(root) else ()
    cur = root
    for i, part in enumerate(rel_parts):
        if part in ("..", "."):
            raise AccessDenied("PATH_ESCAPE")
        cur = cur / part
        if part.lower() in DENY_DIR_NAMES:
            raise AccessDenied("PRIVATE_OR_TOOLING_DIRECTORY")
        if _is_reparse(cur):
            raise AccessDenied("REPARSE_POINT_OR_LINK")
        if i == len(rel_parts) - 1 and DENY_FILE_RE.search(part):
            raise AccessDenied("PRIVATE_OR_CREDENTIAL_FILE")
    if rid == "mt5_common_files":
        if not rel_parts or not MT5_COMMON_ALLOWED.match(rel_parts[0]):
            raise AccessDenied("MT5_COMMON_NOT_PROJECT_AUDIT")
    if target.exists():
        try:
            if not _within(Path(os.path.realpath(target)), Path(os.path.realpath(root))):
                raise AccessDenied("REALPATH_ESCAPE")
        except OSError as exc:  # pragma: no cover - defensive
            raise AccessDenied("REALPATH_ERROR") from exc


def allowed(cfg: MonitorConfig, p: Path) -> bool:
    """The same policy for internally discovered paths."""
    try:
        resolve_safe(cfg, str(p))
        return True
    except AccessDenied:
        return False


def safe_file(cfg: MonitorConfig, p: Path) -> Path | None:
    return p if p.is_file() and allowed(cfg, p) else None


def safe_glob(cfg: MonitorConfig, base: Path, pattern: str, *, dirs: bool = False) -> list[Path]:
    if not base.is_dir() or not allowed(cfg, base):
        return []
    out = []
    for x in base.glob(pattern):  # non-recursive patterns only
        if (x.is_dir() if dirs else x.is_file()) and allowed(cfg, x):
            out.append(x)
    return out


def safe_walk(cfg: MonitorConfig, base: Path, suffixes: set[str], skip_dirs: set[str] = frozenset(), cap: int = MAX_SOURCE_FILES, truncated: list | None = None) -> Iterator[Path]:
    """Recursive walk that never descends into a directory or yields a file the policy would refuse (no rglob). Appends base to `truncated` if the cap stops it."""
    if not base.is_dir() or not allowed(cfg, base):
        return
    count = 0
    for root, dirs, files in os.walk(base, followlinks=False):
        rp = Path(root)
        dirs[:] = sorted(d for d in dirs if d.lower() not in skip_dirs and allowed(cfg, rp / d))
        for name in sorted(files):
            p = rp / name
            if p.suffix.lower() in suffixes and allowed(cfg, p):
                count += 1
                if count > cap:
                    if truncated is not None:
                        truncated.append(str(base))
                    return
                yield p


def display_path(cfg: MonitorConfig, p: Path) -> str:
    for rid, root in cfg.roots.items():
        if _within(p, root):
            rel = os.path.relpath(p, root)
            return f"{rid}:{'' if rel == '.' else rel.replace(os.sep, '/')}"
    return "<outside-roots>"


# --------------------------------------------------------------------------------------------- file reading
def sha256_file(p: Path, cap: int = MAX_HASH_BYTES) -> str | None:
    try:
        if p.stat().st_size > cap:
            return None
        h = hashlib.sha256()
        with open(p, "rb") as f:
            for chunk in iter(lambda: f.read(1 << 20), b""):
                h.update(chunk)
        return h.hexdigest()
    except OSError:
        return None


def file_state(cfg: MonitorConfig, p: Path, *, hash_it: bool = False, probe_stability: bool = True) -> dict[str, Any]:
    out: dict[str, Any] = {"path": display_path(cfg, p)}
    try:
        st1 = p.stat()
    except FileNotFoundError:
        out.update(exists=False, state="MISSING")
        return out
    except OSError as exc:
        out.update(exists=None, state="UNREADABLE", error=type(exc).__name__)
        return out
    out.update(exists=True, size=st1.st_size, mtime_utc=iso(st1.st_mtime), age_seconds=round(time.time() - st1.st_mtime, 1))
    if probe_stability:
        time.sleep(STABLE_PROBE_SECONDS)
        try:
            st2 = p.stat()
            out["stable_during_probe"] = (st2.st_size, st2.st_mtime_ns) == (st1.st_size, st1.st_mtime_ns)
        except OSError:
            out["stable_during_probe"] = False
    if hash_it:
        digest = sha256_file(p)
        out["sha256"] = digest
        if digest is None:
            out["sha256_note"] = "NOT_HASHED_TOO_LARGE_OR_UNREADABLE"
    return out


def read_text_bounded(p: Path, max_bytes: int) -> tuple[str, dict[str, Any]]:
    """Read at most max_bytes from the END of a file, decode (UTF-16 with BOM or UTF-8), return text and metadata."""
    size = p.stat().st_size
    with open(p, "rb") as f:
        head = f.read(4)
        encoding = "utf-16-le" if head.startswith(b"\xff\xfe") else ("utf-8-sig" if head.startswith(b"\xef\xbb\xbf") else "utf-8")
        start = max(0, size - max_bytes)
        if encoding == "utf-16-le":
            start = max(2, start + (start % 2))
        f.seek(start)
        data = f.read(max_bytes)
    text = data.decode("utf-16-le" if encoding == "utf-16-le" else "utf-8", errors="replace")
    if encoding == "utf-8-sig" and start == 0:
        text = text.lstrip("\ufeff")
    return text, {"encoding": encoding, "bytes_read": len(data), "file_size": size, "truncated_from_start": start > (2 if encoding == "utf-16-le" else 0)}


def tail_lines(cfg: MonitorConfig, user_path: str, max_lines: int = 100, max_bytes: int = 32 * 1024) -> dict[str, Any]:
    rid, p = resolve_safe(cfg, user_path, must_exist=True)
    if not p.is_file():
        raise AccessDenied("NOT_A_FILE")
    if p.suffix.lower() not in TEXT_EXT:
        raise AccessDenied("NOT_A_TEXT_LOG_EXTENSION")
    max_lines = max(1, min(int(max_lines), MAX_TAIL_LINES))
    max_bytes = max(256, min(int(max_bytes), MAX_TAIL_BYTES))
    text, meta = read_text_bounded(p, max_bytes)
    lines = text.splitlines()
    if meta["truncated_from_start"] and lines:
        lines = lines[1:]  # first line may be partial
    dropped = max(0, len(lines) - max_lines)
    lines = [redact(line)[:2000] for line in lines[-max_lines:]]
    return {"file": file_state(cfg, p, hash_it=False), "root": rid, "lines": lines, "line_count": len(lines), "lines_dropped_by_limit": dropped, **meta,
            "redacted": True, "limits": {"max_lines": max_lines, "max_bytes": max_bytes}}


def load_json_bounded(cfg: MonitorConfig, p: Path) -> tuple[str, Any]:
    """Return (parse_state, value). parse_state: OK | MISSING | DENIED | TOO_LARGE | PARSING_FILE_CHANGING | PARSE_ERROR | UNREADABLE."""
    if not p.exists():
        return "MISSING", None
    if not allowed(cfg, p) or not p.is_file():
        return "DENIED", None
    try:
        st = p.stat()
    except OSError:
        return "UNREADABLE", None
    if st.st_size > MAX_JSON_BYTES:
        return "TOO_LARGE", None
    try:
        raw = p.read_bytes()
        txt = raw.decode("utf-16") if raw.startswith(b"\xff\xfe") else raw.decode("utf-8-sig")
        return "OK", json.loads(txt)
    except (ValueError, UnicodeDecodeError):
        try:
            st2 = p.stat()
            changing = (time.time() - st2.st_mtime) < 10 or st2.st_size != st.st_size
        except OSError:
            changing = False
        return ("PARSING_FILE_CHANGING" if changing else "PARSE_ERROR"), None
    except OSError:
        return "UNREADABLE", None


# --------------------------------------------------------------------------------------------- progress memory (per server process)
class ProgressMemory:
    """Remembers sizes/mtimes/hashes seen by earlier calls of THIS server process, so a later call can report real growth or change."""

    def __init__(self) -> None:
        self.logs: dict[str, tuple[int, float]] = {}
        self.sources: dict[str, dict[str, tuple[str, int, float, str | None]]] = {}

    def log_progress(self, key: str, size: int, mtime: float) -> dict[str, Any]:
        prev = self.logs.get(key)
        self.logs[key] = (size, mtime)
        if prev is None:
            return {"first_observation_this_session": True, "bytes_since_last_observation": None}
        return {"first_observation_this_session": False, "bytes_since_last_observation": size - prev[0], "mtime_changed": mtime != prev[1]}


def _growth(entries: list[dict[str, Any]]) -> bool:
    return any((e.get("bytes_since_last_observation") or 0) > 0 for e in entries)


LIVENESS_NOTE = ("A recent write time alone does not show that a process is alive; only growth observed between two calls of this "
                 "session is reported as progress. The monitor cannot see processes.")

# --------------------------------------------------------------------------------------------- classification
LEAN_FAIL = [
    (re.compile(r"0x800711C7|应用程序控制策略已阻止|application control policy", re.I), "CODE_INTEGRITY_BLOCKED_DLL"),
    (re.compile(r"Unhandled exception", re.I), "UNHANDLED_EXCEPTION"),
    (re.compile(r"Runtime Error|RuntimeError:|Engine\.Run\(\): Error|ERROR:: .*Exception", re.I), "RUNTIME_ERROR"),
    (re.compile(r"Algorithm\.Initialize\(\) Error|Initialize\(\): .*Error", re.I), "INITIALIZE_ERROR"),
]
LEAN_DONE = re.compile(r"Program\.Main\(\): Exiting Lean|Engine\.Run\(\): Exiting|Analysis Complete", re.I)
LEAN_STARTED = re.compile(r"Engine\.Main\(\): Started|Engine\.Main\(\): LEAN ALGORITHMIC TRADING ENGINE", re.I)
BUILD_OK = re.compile(r"Build succeeded|已成功生成|生成成功", re.I)
BUILD_ZERO_ERR = re.compile(r"\b0 Error\(s\)|0 个错误|\b0 errors?\b", re.I)
BUILD_FAIL = re.compile(r"Build FAILED|生成失败|: error [A-Z]+\d+|error CS\d+|error MSB\d+|\b[1-9]\d* Error\(s\)|[1-9]\d* 个错误", re.I)


def classify_lean_run(cfg: MonitorConfig, run_dir: Path, memory: ProgressMemory | None = None, *, historical: bool = False) -> dict[str, Any]:
    out: dict[str, Any] = {"run_dir": display_path(cfg, run_dir), "kind": "LEAN_BACKTEST", "origin": "HISTORICAL_LEAN_BEFORE_THIS_PROJECT" if historical else "PROJECT_LEAN",
                           "logs": [], "evidence": []}
    if not run_dir.is_dir() or not allowed(cfg, run_dir):
        out.update(status="DENIED_OR_MISSING_RUN_DIR")
        return out
    logs = [p for p in (safe_file(cfg, run_dir / n) for n in ("log.txt", "console.log")) if p]
    logs += sorted(safe_glob(cfg, run_dir, "*-log.txt"))
    summaries = sorted(safe_glob(cfg, run_dir, "*-summary.json"))
    if not logs:
        out.update(status="NOT_STARTED_OR_NO_LOG", note="Directory exists but no readable LEAN log: not running, not completed.")
        rstate, rval = load_json_bounded(cfg, run_dir / "RUN_RECEIPT.json")
        out["run_receipt"] = {"parse": rstate, "status": rval.get("status") if isinstance(rval, dict) else None}
        out["engine_status"] = out["status"]
        out["research_status"] = _receipt_research_status(rstate, rval)
        if out["research_status"] == "FAILED_BY_RUN_RECEIPT":  # e.g. build or data gate failed before the engine started
            err = rval.get("error") if isinstance(rval, dict) else None
            out["run_receipt"]["error"] = redact(str(err))[:400] if err else None
            out.update(status="FAILED", failure_reasons=["RUN_RECEIPT_FAILED"])
        return out
    newest = max(lg.stat().st_mtime for lg in logs)
    fail_reasons, done, started = [], False, False
    for lg in logs:
        text, scan = read_text_bounded(lg, LOG_SCAN_BYTES)
        st = lg.stat()
        entry = {"file": display_path(cfg, lg), "size": st.st_size, "mtime_utc": iso(st.st_mtime), "scanned_bytes": scan["bytes_read"],
                 "scan_window_truncated": scan["truncated_from_start"]}
        if memory is not None:
            entry.update(memory.log_progress(_norm(lg), st.st_size, st.st_mtime))
        out["logs"].append(entry)
        for rx, reason in LEAN_FAIL:
            m = rx.search(text)
            if m and reason not in fail_reasons:
                fail_reasons.append(reason)
                end = text.find("\n", m.end())
                line = text[text.rfind("\n", 0, m.start()) + 1: end if end > 0 else len(text)]
                out["evidence"].append({"file": display_path(cfg, lg), "reason": reason, "line": redact(line.strip())[:400]})
        done = done or bool(LEAN_DONE.search(text))
        started = started or bool(LEAN_STARTED.search(text))
    summary_states = []
    for s in summaries:
        state, val = load_json_bounded(cfg, s)
        summary_states.append({"file": display_path(cfg, s), "parse": state, "has_statistics": isinstance(val, dict) and isinstance(val.get("statistics"), dict)})
    out["summaries"] = summary_states
    rstate, rval = load_json_bounded(cfg, run_dir / "RUN_RECEIPT.json")
    out["run_receipt"] = {"parse": rstate, "status": rval.get("status") if isinstance(rval, dict) else None}
    age = time.time() - newest
    out["newest_log_age_seconds"] = round(age, 1)
    if any(e["scan_window_truncated"] for e in out["logs"]):
        out["scan_note"] = f"Only the last {LOG_SCAN_BYTES} bytes of at least one log were scanned for markers; earlier lines were not inspected."
    if fail_reasons:
        out["status"] = "FAILED"
        out["failure_reasons"] = fail_reasons
    elif done and any(x["parse"] == "OK" and x["has_statistics"] for x in summary_states):
        out["status"] = "COMPLETED_RESULTS_PRESENT_REVIEW_REQUIRED"
    elif done and any(x["parse"] == "PARSING_FILE_CHANGING" for x in summary_states):
        out["status"] = "COMPLETED_RESULT_BEING_WRITTEN"
    elif done:
        out["status"] = "ENGINE_EXITED_WITHOUT_VALID_SUMMARY"
    elif _growth(out["logs"]):
        out["status"] = "IN_PROGRESS_LOG_GROWTH_OBSERVED" if started else "STARTING_LOG_GROWTH_OBSERVED"
    elif age <= cfg.fresh_seconds:
        out["status"] = "RECENT_LOG_WRITE_LIVENESS_UNCONFIRMED"
        out["note"] = LIVENESS_NOTE + " Call again to observe growth."
    else:
        out["status"] = "INTERRUPTED_OR_STALLED_NO_TERMINAL_MARKER"
    # The engine log state and the research receipt are different facts: keep the engine view as
    # engine_status, and let an explicit FAILED research receipt take precedence for the run status
    # (a run can be "engine completed" yet failed by the runner's own gates, e.g. reconciliation).
    out["engine_status"] = out["status"]
    out["research_status"] = _receipt_research_status(rstate, rval)
    if out["research_status"] == "FAILED_BY_RUN_RECEIPT":
        err = rval.get("error") if isinstance(rval, dict) else None
        out["run_receipt"]["error"] = redact(str(err))[:400] if err else None
        out["status"] = "FAILED"
        out["failure_reasons"] = list(dict.fromkeys((out.get("failure_reasons") or []) + ["RUN_RECEIPT_FAILED"]))
    if historical and out["status"].startswith("COMPLETED"):
        out["note"] = "Historical run from an earlier project; not a result of this LEAN research."
    return out


def _receipt_research_status(state: str, val: Any) -> str:
    if state == "MISSING":
        return "NO_RUN_RECEIPT"
    if state != "OK" or not isinstance(val, dict):
        return "RUN_RECEIPT_" + str(state)
    status = str(val.get("status") or "")
    if status == "FAILED" or status.endswith("_FAILED"):
        return "FAILED_BY_RUN_RECEIPT"
    return "RUN_RECEIPT_" + (status or "NO_STATUS")


def classify_build(cfg: MonitorConfig, build_log: Path, memory: ProgressMemory | None = None) -> dict[str, Any]:
    out: dict[str, Any] = {"build_log": display_path(cfg, build_log), "kind": "DOTNET_BUILD"}
    if safe_file(cfg, build_log) is None:
        out["status"] = "DENIED_OR_MISSING"
        return out
    st = build_log.stat()
    text, scan = read_text_bounded(build_log, LOG_SCAN_BYTES)
    out.update(size=st.st_size, mtime_utc=iso(st.st_mtime), scanned_bytes=scan["bytes_read"], scan_window_truncated=scan["truncated_from_start"])
    prog: dict[str, Any] = {}
    if memory is not None:
        prog = memory.log_progress(_norm(build_log), st.st_size, st.st_mtime)
        out.update(prog)
    all_errors = [redact(line.strip())[:300] for line in text.splitlines() if BUILD_FAIL.search(line)]
    errors = all_errors[:20]
    out["error_lines_total"] = len(all_errors)
    out["error_lines_truncated"] = len(all_errors) > 20
    if errors:
        out.update(status="BUILD_FAILED", error_lines=errors)
    elif BUILD_OK.search(text) and BUILD_ZERO_ERR.search(text):
        out["status"] = "BUILD_SUCCEEDED_LOG"
        out["note"] = "Log says success; the output DLL hash must still be bound by the runner record."
    elif (prog.get("bytes_since_last_observation") or 0) > 0:
        out["status"] = "BUILD_IN_PROGRESS_LOG_GROWTH_OBSERVED"
    elif time.time() - st.st_mtime <= cfg.fresh_seconds:
        out["status"] = "BUILD_RECENT_LOG_WRITE_LIVENESS_UNCONFIRMED"
        out["note"] = LIVENESS_NOTE
    else:
        out["status"] = "BUILD_INCOMPLETE_OR_INTERRUPTED"
    return out


def classify_mt5_i18(cfg: MonitorConfig, arm_dir: Path) -> dict[str, Any]:
    out: dict[str, Any] = {"arm": display_path(cfg, arm_dir), "kind": "MT5_NATIVE_I18", "origin": "HISTORICAL_I18_MT5_NOT_LEAN"}
    nr_state, nr = load_json_bounded(cfg, arm_dir / "session" / "run" / "native_result.json")
    out["native_result"] = {"parse": nr_state, "status": nr.get("status") if isinstance(nr, dict) else None, "run_id": nr.get("run_id") if isinstance(nr, dict) else None}
    latest = sorted(safe_glob(cfg, arm_dir / "verification", "*", dirs=True))
    if latest:
        vs, vv = load_json_bounded(cfg, latest[-1] / "VERIFICATION.json")
        out["latest_verification"] = {"dir": display_path(cfg, latest[-1]), "parse": vs, "status": vv.get("status") if isinstance(vv, dict) else None}
    else:
        out["latest_verification"] = {"parse": "MISSING"}
    v = out["latest_verification"]
    if str(v.get("status") or "").startswith("PASS"):
        out["status"] = "VERIFIED_HISTORICAL"
    elif nr_state == "OK" and isinstance(nr, dict) and nr.get("status") == "COMPLETE":
        out["status"] = "NATIVE_COMPLETE_NOT_VERIFIED"
    elif nr_state == "MISSING":
        out["status"] = "NO_NATIVE_RESULT"
    else:
        out["status"] = "NATIVE_RESULT_" + nr_state
    return out


# --------------------------------------------------------------------------------------------- discovery
def _by_mtime(paths: list[Path]) -> list[Path]:
    return sorted(paths, key=lambda d: d.stat().st_mtime, reverse=True)


def discover_lean_runs(cfg: MonitorConfig, include_historical: bool) -> list[tuple[Path, bool]]:
    proj = cfg.project
    found = [(d, False) for d in _by_mtime(safe_glob(cfg, proj / "runs", "*", dirs=True) + safe_glob(cfg, proj, "lean_probe_*", dirs=True))]
    if include_historical:
        for rel in HISTORICAL_LEAN_REL:
            base = cfg.workspace / rel
            found += [(d, True) for d in _by_mtime(safe_glob(cfg, base / "lean_runs", "*", dirs=True) + safe_glob(cfg, base / "runs", "*", dirs=True))]
    return found


def discover_builds(cfg: MonitorConfig) -> list[Path]:
    logs: list[Path] = []
    for d in safe_glob(cfg, cfg.project / "builds", "*", dirs=True):
        logs += safe_glob(cfg, d, "*.log")
    return _by_mtime(logs)


def source_bases(cfg: MonitorConfig, scope: str) -> list[Path]:
    bases: list[Path] = []
    if scope in ("lean", "all"):
        bases += [cfg.project / "lean", cfg.project / "algorithms"]
    if scope in ("monitor", "all"):
        bases += [cfg.project / "monitor"]
    if scope in ("mt5_i18", "all"):
        bases += [cfg.workspace / "work/repair_research/mt5_iteration18_20261011/Claude/candidates_r1"]
    return bases


def source_changes(cfg: MonitorConfig, memory: ProgressMemory, scope: str = "lean", since_utc: str | None = None, limit: int = 100) -> dict[str, Any]:
    """Diff against this session's previous snapshot by SHA-256 (the baseline stores hashes); since_utc adds an mtime filter."""
    if scope not in ("lean", "monitor", "mt5_i18", "all"):
        raise AccessDenied("UNKNOWN_SCOPE")
    limit = max(1, min(int(limit), MAX_LIST))
    since_ts = None
    if since_utc:
        try:
            since_ts = _dt.datetime.fromisoformat(since_utc.replace("Z", "+00:00")).timestamp()
        except ValueError as exc:
            raise AccessDenied("BAD_SINCE_UTC") from exc
    prev = memory.sources.get(scope)
    current: dict[str, tuple[str, int, float, str | None]] = {}
    truncated = False
    walk_capped: list[str] = []
    for base in source_bases(cfg, scope):
        for p in safe_walk(cfg, base, SOURCE_EXT, SOURCE_SKIP_DIRS, truncated=walk_capped):
            if len(current) >= MAX_SOURCE_FILES:
                truncated = True
                break
            try:
                st = p.stat()
            except OSError:
                continue
            key = _norm(p)
            before = prev.get(key) if prev else None
            digest = before[3] if before and before[1] == st.st_size and before[2] == st.st_mtime else sha256_file(p)
            current[key] = (str(p), st.st_size, st.st_mtime, digest)
    changes, touched = [], []
    for key, (orig, size, mtime, digest) in current.items():
        p = Path(orig)
        before = prev.get(key) if prev is not None else None
        kind = None
        if prev is not None and before is None:
            kind = "ADDED"
        elif before is not None and (digest != before[3] or (digest is None and (size, mtime) != (before[1], before[2]))):
            kind = "MODIFIED"
        elif before is not None and mtime != before[2]:
            touched.append({"path": display_path(cfg, p), "mtime_utc": iso(mtime), "sha256": digest})
        elif since_ts is not None and mtime > since_ts:
            kind = "MODIFIED_SINCE_TIMESTAMP"
        if kind:
            changes.append({"path": display_path(cfg, p), "change": kind, "size": size, "mtime_utc": iso(mtime), "sha256": digest,
                            "previous_sha256": before[3] if before else None, "previous_size": before[1] if before else None})
    if prev is not None:
        for key, (orig, size, mtime, digest) in prev.items():
            if key not in current:
                changes.append({"path": display_path(cfg, Path(orig)), "change": "DELETED_OR_NO_LONGER_ALLOWED", "previous_sha256": digest, "previous_size": size})
    memory.sources[scope] = current
    changes.sort(key=lambda c: c.get("mtime_utc") or "", reverse=True)
    newest = sorted(((v[2], v[0], v[3]) for v in current.values()), reverse=True)[:10]
    truncated = truncated or bool(walk_capped)
    return {"scope": scope, "baseline_established_now": prev is None, "files_tracked": len(current), "truncated_at_file_cap": truncated,
            "file_cap": MAX_SOURCE_FILES, "capped_bases": [display_path(cfg, Path(b)) for b in walk_capped],
            "changes": changes[:limit], "changes_total": len(changes), "changes_truncated_by_limit": len(changes) > limit,
            "touched_content_unchanged": touched[:limit], "touched_total": len(touched), "touched_truncated_by_limit": len(touched) > limit,
            "note": "The first call of a session stores SHA-256 of every tracked file as the baseline (no change claimed unless since_utc is given); later calls diff by hash.",
            "newest_files": [{"path": display_path(cfg, Path(o)), "mtime_utc": iso(m), "sha256": h} for m, o, h in newest]}


def run_status(cfg: MonitorConfig, memory: ProgressMemory, kind: str = "all", include_historical: bool = False, limit: int = 20) -> dict[str, Any]:
    if kind not in ("lean", "build", "mt5_i18", "mt5_common", "all"):
        raise AccessDenied("UNKNOWN_KIND")
    limit = max(1, min(int(limit), 50))
    out: dict[str, Any] = {"kind": kind, "liveness_rule": LIVENESS_NOTE}
    if kind in ("lean", "all"):
        all_runs = discover_lean_runs(cfg, include_historical)
        runs = all_runs[:limit]
        out["lean_runs"] = [classify_lean_run(cfg, d, memory, historical=h) for d, h in runs]
        out["lean_runs_total"], out["lean_runs_truncated_by_limit"] = len(all_runs), len(all_runs) > limit
        if not runs:
            out["lean_runs_note"] = "No LEAN run directory found in this project (runs/ or lean_probe_*)."
    if kind in ("build", "all"):
        all_logs = discover_builds(cfg)
        logs = all_logs[:limit]
        out["builds"] = [classify_build(cfg, b, memory) for b in logs]
        out["builds_total"], out["builds_truncated_by_limit"] = len(all_logs), len(all_logs) > limit
        if not logs:
            out["builds_note"] = "No build log under builds/<id>/*.log in this project."
    if kind in ("mt5_i18", "all") and include_historical:
        base = cfg.workspace / I18_EXEC_REL
        all_arms = [d for d in _by_mtime(safe_glob(cfg, base, "*", dirs=True)) if re.match(r"^S[1-6]_(JUNE|AUG)_D(250|0)(_R\d)?$", d.name)]
        out["mt5_i18_arms"] = [classify_mt5_i18(cfg, d) for d in all_arms[:limit]]
        out["mt5_i18_arms_total"], out["mt5_i18_arms_truncated_by_limit"] = len(all_arms), len(all_arms) > limit
        out["mt5_i18_scalping"] = []
        for f in sorted(safe_glob(cfg, base / "Scalping", "VERIFICATION_S20_*.json")):
            st_, v = load_json_bounded(cfg, f)
            out["mt5_i18_scalping"].append({"file": display_path(cfg, f), "parse": st_, "status": v.get("status") if isinstance(v, dict) else None, "origin": "HISTORICAL_I18_MT5_NOT_LEAN"})
    elif kind == "mt5_i18":
        out["note"] = "I18 MT5 runs are historical; pass include_historical=true to list them."
    if kind in ("mt5_common", "all") and cfg.mt5_common_files is not None:
        out["mt5_common_files"] = mt5_common_recent(cfg, memory, limit)
    return out


def mt5_common_recent(cfg: MonitorConfig, memory: ProgressMemory, limit: int) -> dict[str, Any]:
    base = cfg.mt5_common_files
    if base is None or not base.is_dir() or _is_reparse(base):
        return {"state": "MISSING", "path": str(base) if base else None}
    items = []
    with os.scandir(base) as it:
        for e in it:
            p = base / e.name
            if e.is_file(follow_symlinks=False) and allowed(cfg, p):
                st = e.stat(follow_symlinks=False)
                items.append((st.st_mtime, e.name, st.st_size))
    items.sort(reverse=True)
    rows = []
    for mtime, name, size in items[:limit]:
        prog = memory.log_progress("mt5c:" + name, size, mtime)
        rows.append({"file": f"mt5_common_files:{name}", "size": size, "mtime_utc": iso(mtime), "age_seconds": round(time.time() - mtime, 1), **prog})
    return {"state": "OK", "project_audit_files": len(items), "newest": rows, "newest_truncated_by_limit": len(items) > limit, "growth_observed": _growth(rows),
            "note": "Mtime/growth of project audit files only; not proof that an EA or tester is running or healthy. " + LIVENESS_NOTE}


def _lean_stats(val: Any) -> dict[str, Any]:
    stats = val.get("statistics", {}) if isinstance(val, dict) else {}
    keys = ["Total Orders", "Net Profit", "Drawdown", "Sharpe Ratio", "Win Rate", "Profit-Loss Ratio", "Total Fees", "Start Equity", "End Equity", "Compounding Annual Return"]
    return {k: stats.get(k) for k in keys if k in stats}


def latest_results(cfg: MonitorConfig, include_historical: bool = False, limit: int = 5) -> dict[str, Any]:
    limit = max(1, min(int(limit), 20))
    rows = []
    for d, hist in discover_lean_runs(cfg, include_historical):
        for s in sorted(safe_glob(cfg, d, "*-summary.json")):
            st = s.stat()
            parse, val = load_json_bounded(cfg, s)
            rows.append({"file": display_path(cfg, s), "origin": "HISTORICAL_LEAN_BEFORE_THIS_PROJECT" if hist else "PROJECT_LEAN", "mtime_utc": iso(st.st_mtime), "age_seconds": round(time.time() - st.st_mtime, 1),
                         "parse": parse, "statistics": _lean_stats(val) if parse == "OK" else None, "_m": st.st_mtime})
    rows.sort(key=lambda r: r["_m"], reverse=True)
    for r in rows:
        r.pop("_m")
    out: dict[str, Any] = {"lean_results": rows[:limit], "lean_results_total": len(rows), "lean_results_truncated_by_limit": len(rows) > limit,
                           "note": "A summary file is a LEAN engine output, not an accepted research result. Cross-check with run_status (terminal marker, failures)."}
    if not rows:
        out["lean_results_state"] = "NO_PROJECT_LEAN_RESULT" if not include_historical else "NO_LEAN_RESULT_FOUND"
    if include_historical:
        ev = []
        for f in sorted(safe_glob(cfg, cfg.workspace / I18_EXEC_REL, "EVALUATION_*.json")):
            parse, val = load_json_bounded(cfg, f)
            ev.append({"file": display_path(cfg, f), "origin": "HISTORICAL_I18_MT5_NOT_LEAN", "parse": parse,
                       "sid": val.get("sid") if isinstance(val, dict) else None, "numeric_retention": val.get("numeric_retention") if isinstance(val, dict) else None})
        out["i18_mt5_evaluations"] = ev
        out["i18_note"] = "I18 MT5 evaluations are historical MT5 evidence and are never LEAN results of this project."
    return out


# --------------------------------------------------------------------------------------------- research status
STAGES = ("code", "compile", "backtest", "optimize")


def research_status(cfg: MonitorConfig, memory: ProgressMemory) -> dict[str, Any]:
    proj = cfg.project
    map_path = Path(__file__).with_name("LEAN_MIGRATION_MAP.json")
    mstate, mval = load_json_bounded(cfg, map_path) if _within(map_path, cfg.workspace) else ("OUTSIDE_WORKSPACE", None)
    if mstate == "OUTSIDE_WORKSPACE":  # tests run the module from the real monitor folder against a temporary workspace
        try:
            mval, mstate = json.loads(map_path.read_text(encoding="utf-8")), "OK_MODULE_FILE"
        except (OSError, ValueError):
            mval, mstate = None, "MISSING"
    stages: dict[str, Any] = {s: {"state": "NO_RECORD"} for s in STAGES}
    stage_file = safe_file(cfg, proj / "research" / "STAGES.jsonl")
    stage_scan: dict[str, Any] = {"file": "MISSING" if stage_file is None else display_path(cfg, stage_file)}
    if stage_file is not None:
        text, meta = read_text_bounded(stage_file, MAX_TAIL_BYTES)
        stage_scan.update(scanned_bytes=meta["bytes_read"], window_truncated=meta["truncated_from_start"])
        for line in text.splitlines():
            try:
                rec = json.loads(line)
            except ValueError:
                continue
            if isinstance(rec, dict) and rec.get("stage") in STAGES:
                stages[rec["stage"]] = {"state": "RECORDED", "last": {k: redact(str(v))[:300] for k, v in rec.items()}}
    strategies = []
    for item in (mval or {}).get("order", []) if isinstance(mval, dict) else []:
        sid = str(item.get("sid"))
        src_dir = proj / "lean" / "algorithms" / sid
        capped: list[str] = []
        files = list(safe_walk(cfg, src_dir, {".cs", ".csproj"}, SOURCE_SKIP_DIRS, cap=500, truncated=capped))
        runs = [d for d, _ in discover_lean_runs(cfg, False) if sid.lower() in d.name.lower()]
        strategies.append({"sid": sid, "priority": item.get("priority"), "reference": item.get("reference"), "lean_source_dir": display_path(cfg, src_dir), "source_files": len(files),
                           "source_state": "PRESENT" if files else "NOT_STARTED", "source_files_truncated_at_cap": bool(capped), "project_lean_runs": len(runs),
                           "latest_run_status": classify_lean_run(cfg, runs[0], memory)["status"] if runs else "NO_RUN"})
    probes = sorted(safe_glob(cfg, proj, "lean_probe_*", dirs=True))
    return {"project": display_path(cfg, proj), "project_exists": proj.is_dir(), "migration_map": {"parse": mstate, "status": (mval or {}).get("status") if isinstance(mval, dict) else None},
            "stages": stages, "stage_record_scan": stage_scan, "strategies": strategies, "engine_probes": [classify_lean_run(cfg, d, memory) for d in probes[-3:]],
            "engine_probes_total": len(probes), "engine_probes_truncated": len(probes) > 3,
            "rules": (mval or {}).get("rules", []) if isinstance(mval, dict) else [],
            "monitor_rules": ["Status is derived from file content and observed growth; a file existing or a recent mtime never means running or passed.",
                              "I18 MT5 results are never reported as LEAN results.", "Score N/A (SCORE_TARGETS_UNSET)."]}


def health(cfg: MonitorConfig, started: float) -> dict[str, Any]:
    roots = {rid: {"path": str(p), "exists": p.is_dir(), "reparse_point": _is_reparse(p)} for rid, p in cfg.roots.items()}
    try:
        from importlib.metadata import version
        sdk = version("mcp")
    except Exception:  # pragma: no cover
        sdk = None
    return {"server": "tb-lean-monitor", "version": VERSION, "mcp_sdk": sdk, "uptime_seconds": round(time.time() - started, 1), "roots": roots,
            "project": {"path": display_path(cfg, cfg.project), "exists": cfg.project.is_dir()},
            "policy": {"read_only": True, "executes_commands": False, "writes_files": False, "sends_orders": False, "changes_configuration": False,
                       "internal_discovery_uses_same_path_policy": True, "mt5_common_files_allowed_prefix_regex": MT5_COMMON_ALLOWED.pattern,
                       "denied_directories": sorted(DENY_DIR_NAMES), "max_tail_lines": MAX_TAIL_LINES, "max_tail_bytes": MAX_TAIL_BYTES, "fresh_seconds": cfg.fresh_seconds},
            "liveness_rule": LIVENESS_NOTE,
            "client_loading": "UNKNOWN_TO_SERVER: a successful call proves only this process answered; client configuration is verified separately."}
