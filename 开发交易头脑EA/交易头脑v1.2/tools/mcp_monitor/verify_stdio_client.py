"""MCP stdio verification client (official SDK, mcp 1.x API): spawns server.py over stdio, performs the handshake, lists tools,
calls every tool with normal and abnormal arguments, checks the answers and saves the raw exchange.

Usage:  .venv/Scripts/python.exe verify_stdio_client.py [--workspace <dir>] [--out <new json file>] [--label <text>]
Exit code 0 only if every check passed. The client never writes anything except the --out record (exclusive create).
"""
from __future__ import annotations

import argparse
import asyncio
import datetime as dt
import json
import sys
import time
from pathlib import Path
from typing import Any

from mcp import ClientSession, StdioServerParameters
from mcp.client.stdio import stdio_client

HERE = Path(__file__).resolve().parent
REQUIRED_TOOLS = {"health", "research_status", "source_changes", "run_status", "bounded_log_tail", "latest_results"}


def body_of(result: Any) -> dict[str, Any]:
    sc = getattr(result, "structuredContent", None)
    if isinstance(sc, dict):
        return sc.get("result", sc) if set(sc) == {"result"} else sc
    for c in result.content:
        if getattr(c, "type", None) == "text":
            return json.loads(c.text)
    raise AssertionError("no content")


async def run(args: argparse.Namespace) -> dict[str, Any]:
    server_args = [str(HERE / "server.py")]
    if args.workspace:
        server_args += ["--workspace", args.workspace]
    params = StdioServerParameters(command=sys.executable, args=server_args, cwd=str(HERE))
    record: dict[str, Any] = {"schema": "TB_MONITOR_STDIO_CHECK_V1", "label": args.label, "started_utc": dt.datetime.now(dt.timezone.utc).isoformat(timespec="seconds"),
                              "client_python": sys.version.split()[0], "server_command": [sys.executable, *server_args], "calls": [], "checks": []}

    def check(name: str, ok: bool, detail: Any = None) -> None:
        record["checks"].append({"check": name, "pass": bool(ok), "detail": detail})

    async with stdio_client(params) as (read, write):
        async with ClientSession(read, write) as session:
            init = await session.initialize()
            record["initialize"] = {"server": init.serverInfo.model_dump(), "protocol": init.protocolVersion}
            check("handshake_server_name", init.serverInfo.name == "tb-lean-monitor", init.serverInfo.name)
            tools = await session.list_tools()
            names = {t.name for t in tools.tools}
            record["tools"] = [{"name": t.name, "read_only_hint": getattr(t.annotations, "readOnlyHint", None) if t.annotations else None} for t in tools.tools]
            check("required_tools_listed", REQUIRED_TOOLS <= names, sorted(names))
            check("all_tools_read_only_annotated", all(x["read_only_hint"] is True for x in record["tools"]), record["tools"])

            async def call(tool: str, arguments: dict[str, Any], expect_ok: bool | None = True, expect_reason: str | None = None) -> dict[str, Any]:
                t0 = time.perf_counter()
                res = await session.call_tool(tool, arguments)
                ms = round((time.perf_counter() - t0) * 1000)
                body = body_of(res)
                record["calls"].append({"tool": tool, "arguments": arguments, "ms": ms, "is_error": res.isError, "response": body})
                label = f"{tool}({json.dumps(arguments, ensure_ascii=False)})"
                if expect_ok is not None:
                    check(label + " ok=" + str(expect_ok), body.get("ok") is expect_ok, {k: body.get(k) for k in ("ok", "error", "reason")})
                if expect_reason is not None:
                    check(label + " reason=" + expect_reason, body.get("reason") == expect_reason, body.get("reason"))
                if expect_ok:
                    check(label + " has observed_utc/platform", bool(body.get("observed_utc")) and "pid" in body.get("platform", {}), None)
                return body

            h = await call("health", {})
            check("health_policy_read_only", h["result"]["policy"]["read_only"] is True and h["result"]["policy"]["executes_commands"] is False, h["result"]["policy"])
            r = await call("research_status", {})
            sids = [s["sid"] for s in r["result"]["strategies"]]
            check("migration_order_S4_then_Scalping_seven_total", sids[:2] == ["S4", "Scalping"] and len(sids) == 7, sids)
            b1 = await call("source_changes", {"scope": "monitor"})
            check("source_baseline_first", b1["result"]["baseline_established_now"] is True and b1["result"]["changes"] == [], b1["result"]["files_tracked"])
            b2 = await call("source_changes", {"scope": "monitor"})
            check("source_second_call_diff_not_baseline", b2["result"]["baseline_established_now"] is False, b2["result"]["changes_total"])
            await call("source_changes", {"scope": "lean", "since_utc": "2000-01-01T00:00:00Z"})
            s1 = await call("run_status", {"kind": "all"})
            await call("run_status", {"kind": "all", "include_historical": True, "limit": 5})
            await call("latest_results", {})
            lr = await call("latest_results", {"include_historical": True, "limit": 3})
            check("i18_never_labelled_lean", all(e["origin"] == "HISTORICAL_I18_MT5_NOT_LEAN" for e in lr["result"].get("i18_mt5_evaluations", [])), None)
            probe = [x for x in s1["result"].get("lean_runs", []) if "lean_probe_01" in x["run_dir"]]
            if probe:
                check("lean_probe_01_reported_failed_code_integrity", probe[0]["status"] == "FAILED" and "CODE_INTEGRITY_BLOCKED_DLL" in probe[0].get("failure_reasons", []), probe[0].get("failure_reasons"))
            tail_target = "workspace:work/repair_research/lean_mcp_20261012/lean_probe_01/console.log"
            t = await call("bounded_log_tail", {"path": tail_target, "max_lines": 5, "max_bytes": 4096})
            if t.get("ok"):
                check("tail_bounded", t["result"]["line_count"] <= 5 and t["result"]["bytes_read"] <= 4096, t["result"]["line_count"])
            # ---- abnormal inputs
            await call("bounded_log_tail", {"path": "workspace:../outside.txt"}, False, "PATH_ESCAPE")
            await call("bounded_log_tail", {"path": "C:/Windows/win.ini"}, False, "OUTSIDE_ALLOWED_ROOTS")
            await call("bounded_log_tail", {"path": "workspace:work/x.log:stream"}, False, "INVALID_PATH")
            await call("bounded_log_tail", {"path": "workspace:work/a/terminal.ini"}, False, "PRIVATE_OR_CREDENTIAL_FILE")
            await call("bounded_log_tail", {"path": "workspace:work/repair_research/lean_mcp_20261012/monitor/.venv/pyvenv.cfg"}, False, "PRIVATE_OR_TOOLING_DIRECTORY")
            await call("bounded_log_tail", {"path": "mt5_common_files:not_project_file.csv"}, False, "MT5_COMMON_NOT_PROJECT_AUDIT")
            await call("bounded_log_tail", {"path": "workspace:work/does_not_exist.log"}, False, "NOT_FOUND")
            await call("bounded_log_tail", {"path": "workspace:work/repair_research/lean_mcp_20261012/monitor/server.py"}, False, "NOT_A_TEXT_LOG_EXTENSION")
            await call("source_changes", {"scope": "C:/"}, False, "UNKNOWN_SCOPE")
            await call("run_status", {"kind": "shell"}, False, "UNKNOWN_KIND")
            await call("source_changes", {"scope": "lean", "since_utc": "yesterday"}, False, "BAD_SINCE_UTC")
            big = await call("bounded_log_tail", {"path": tail_target, "max_lines": 10**9, "max_bytes": 10**9}, None)
            if big.get("ok"):
                check("limits_clamped", big["result"]["limits"] == {"max_lines": 400, "max_bytes": 65536}, big["result"]["limits"])
            try:
                res = await session.call_tool("no_such_tool", {})
                record["calls"].append({"tool": "no_such_tool", "is_error": res.isError})
                check("unknown_tool_is_error", res.isError is True, None)
            except Exception as exc:  # some SDK versions raise
                check("unknown_tool_is_error", True, type(exc).__name__)
    record["finished_utc"] = dt.datetime.now(dt.timezone.utc).isoformat(timespec="seconds")
    record["passed"] = all(c["pass"] for c in record["checks"])
    record["failed_checks"] = [c for c in record["checks"] if not c["pass"]]
    return record


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--workspace", default=None)
    ap.add_argument("--out", default=None)
    ap.add_argument("--label", default="")
    args = ap.parse_args()
    record = asyncio.run(run(args))
    out = Path(args.out) if args.out else HERE / "verification" / f"STDIO_CHECK_{dt.datetime.now(dt.timezone.utc).strftime('%Y%m%dT%H%M%SZ')}.json"
    out.parent.mkdir(parents=True, exist_ok=True)
    with open(out, "x", encoding="utf-8") as f:
        json.dump(record, f, ensure_ascii=False, indent=2)
    print(json.dumps({"passed": record["passed"], "checks": len(record["checks"]), "failed": record["failed_checks"], "out": str(out)}, ensure_ascii=False))
    return 0 if record["passed"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
