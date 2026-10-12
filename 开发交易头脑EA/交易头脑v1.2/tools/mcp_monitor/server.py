"""tb-lean-monitor: read-only MCP stdio server for the TradingBrain LEAN research workspace.

stdout carries ONLY the MCP protocol (FastMCP stdio transport). Diagnostics go to stderr through a redacting, size-capped
handler. The server never executes commands, compiles, runs backtests, writes files, sends orders or changes configuration;
MQL5 risk management inside the EAs is independent of this process and must not rely on it.

Run:  <monitor>/.venv/Scripts/python.exe server.py [--workspace <dir>] [--mt5-common <dir>] [--fresh-seconds N]
"""
from __future__ import annotations

import argparse
import logging
import sys
import time
import traceback
from pathlib import Path
from typing import Any

import monitor_core as core

STDERR_CAP_BYTES = 512 * 1024


class _RedactingCappedHandler(logging.StreamHandler):
    """stderr handler: every record redacted and truncated; total output capped per process."""

    def __init__(self) -> None:
        super().__init__(stream=sys.stderr)
        self.written = 0
        self.capped = False

    def emit(self, record: logging.LogRecord) -> None:
        if self.capped:
            return
        try:
            msg = core.redact(self.format(record))[:2000]
            if self.written + len(msg) > STDERR_CAP_BYTES:
                self.capped = True
                msg = "tb-lean-monitor: stderr log cap reached; further diagnostics suppressed"
            self.stream.write(msg + "\n")
            self.stream.flush()
            self.written += len(msg) + 1
        except Exception:  # pragma: no cover - never let logging break the protocol
            pass


def _configure_logging() -> logging.Logger:
    root = logging.getLogger()
    for h in list(root.handlers):
        root.removeHandler(h)
    handler = _RedactingCappedHandler()
    handler.setFormatter(logging.Formatter("%(asctime)s %(levelname)s %(name)s: %(message)s"))
    root.addHandler(handler)
    root.setLevel(logging.WARNING)
    return logging.getLogger("tb-lean-monitor")


def _parse_args(argv: list[str]) -> argparse.Namespace:
    ap = argparse.ArgumentParser(add_help=False)
    ap.add_argument("--workspace", default=None)
    ap.add_argument("--mt5-common", default=None)
    ap.add_argument("--fresh-seconds", type=float, default=core.FRESH_SECONDS_DEFAULT)
    ns, _unknown = ap.parse_known_args(argv)
    return ns


def build_server(cfg: core.MonitorConfig):
    from mcp.server.fastmcp import FastMCP
    from mcp.types import ToolAnnotations

    log = logging.getLogger("tb-lean-monitor")
    started = time.time()
    memory = core.ProgressMemory()
    mcp = FastMCP(
        "tb-lean-monitor",
        instructions=("Read-only monitor of the TradingBrain LEAN research workspace and project MT5 audit files. "
                      "Every call reads current file state. Statuses come from file content plus fresh activity; "
                      "a file existing never means running or passed. Historical I18 MT5 results are never LEAN results."),
        log_level="WARNING",
    )
    ro = ToolAnnotations(readOnlyHint=True, destructiveHint=False, idempotentHint=False, openWorldHint=False)

    def envelope(tool: str, fn) -> dict[str, Any]:
        base = {"tool": tool, "observed_utc": core.utc_now(), "platform": core.platform_info(), "server_version": core.VERSION}
        try:
            return {**base, "ok": True, "result": fn()}
        except core.AccessDenied as exc:
            log.warning("%s denied: %s", tool, exc)
            return {**base, "ok": False, "error": "ACCESS_DENIED", "reason": str(exc)}
        except Exception as exc:  # report the type only; details go to (redacted) stderr
            log.error("%s failed: %s\n%s", tool, type(exc).__name__, traceback.format_exc(limit=5))
            return {**base, "ok": False, "error": "INTERNAL_ERROR", "type": type(exc).__name__}

    @mcp.tool(annotations=ro)
    def health() -> dict[str, Any]:
        """Server identity, allowed roots, read-only policy and limits. Does not prove that a client has loaded this server."""
        return envelope("health", lambda: core.health(cfg, started))

    @mcp.tool(annotations=ro)
    def research_status() -> dict[str, Any]:
        """LEAN migration map (S4 retained version first, Scalping S20 second, then S1/S2/S3/S5/S6), per-strategy LEAN source/run state,
        recorded code/compile/backtest/optimize stages and LEAN engine probes. Missing evidence is reported as missing."""
        return envelope("research_status", lambda: core.research_status(cfg, memory))

    @mcp.tool(annotations=ro)
    def source_changes(scope: str = "lean", since_utc: str | None = None, limit: int = 100) -> dict[str, Any]:
        """Source files (C#/csproj/MQ5/MQH/py/json/md) added, modified or deleted since the previous call of this session (or since
        since_utc, ISO-8601), with size, mtime and SHA-256. scope: lean | monitor | mt5_i18 | all. The first call is a baseline."""
        return envelope("source_changes", lambda: core.source_changes(cfg, memory, scope, since_utc, limit))

    @mcp.tool(annotations=ro)
    def run_status(kind: str = "all", include_historical: bool = False, limit: int = 20) -> dict[str, Any]:
        """Builds (dotnet logs), LEAN runs (log markers, summaries, receipts) and MT5 audit activity. Distinguishes FAILED, COMPLETED
        (review required), IN_PROGRESS (recent log growth), INTERRUPTED/STALLED, NOT_STARTED, result being written and parse errors.
        kind: lean | build | mt5_i18 | mt5_common | all. Historical runs only when include_historical=true and always labelled."""
        return envelope("run_status", lambda: core.run_status(cfg, memory, kind, include_historical, limit))

    @mcp.tool(annotations=ro)
    def bounded_log_tail(path: str, max_lines: int = 100, max_bytes: int = 32768) -> dict[str, Any]:
        """Last lines of one text/log file inside the allowed roots ('workspace:<relative>' or 'mt5_common_files:<name>').
        Limits: 400 lines, 64 KiB. Output is redacted. Links/junctions, private and credential files are refused."""
        return envelope("bounded_log_tail", lambda: core.tail_lines(cfg, path, max_lines, max_bytes))

    @mcp.tool(annotations=ro)
    def latest_results(include_historical: bool = False, limit: int = 5) -> dict[str, Any]:
        """Newest LEAN summary files of this project with key statistics and age. Historical LEAN and I18 MT5 evaluations only with
        include_historical=true, labelled as historical and never as results of this LEAN research."""
        return envelope("latest_results", lambda: core.latest_results(cfg, include_historical, limit))

    return mcp


def main(argv: list[str] | None = None) -> None:
    log = _configure_logging()
    ns = _parse_args(sys.argv[1:] if argv is None else argv)
    workspace = Path(ns.workspace) if ns.workspace else core.DEFAULT_WORKSPACE
    if not workspace.is_dir():
        log.error("workspace root does not exist")
        raise SystemExit(2)
    cfg = core.MonitorConfig(workspace=workspace, mt5_common_files=Path(ns.mt5_common) if ns.mt5_common else None, fresh_seconds=ns.fresh_seconds)
    server = build_server(cfg)
    server.run(transport="stdio")


if __name__ == "__main__":
    main()
