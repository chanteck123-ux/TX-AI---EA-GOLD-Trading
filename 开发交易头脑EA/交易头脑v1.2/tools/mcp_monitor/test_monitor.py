"""Unit tests for monitor_core and the server's stdio protocol purity. Run: .venv/Scripts/python.exe -m unittest -v test_monitor"""
from __future__ import annotations

import json
import os
import subprocess
import sys
import tempfile
import time
import unittest
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
import monitor_core as core  # noqa: E402


def write(p: Path, text: str, encoding: str = "utf-8", mtime: float | None = None) -> Path:
    p.parent.mkdir(parents=True, exist_ok=True)
    if encoding == "utf-16-le":
        p.write_bytes(b"\xff\xfe" + text.encode("utf-16-le"))
    else:
        p.write_text(text, encoding=encoding)
    if mtime is not None:
        os.utime(p, (mtime, mtime))
    return p


class Base(unittest.TestCase):
    def setUp(self) -> None:
        self.tmp = tempfile.TemporaryDirectory()
        self.ws = Path(self.tmp.name) / "ws"
        self.mt5 = Path(self.tmp.name) / "Common" / "Files"
        (self.ws / core.PROJECT_REL).mkdir(parents=True)
        self.mt5.mkdir(parents=True)
        self.cfg = core.MonitorConfig(workspace=self.ws, mt5_common_files=self.mt5, fresh_seconds=60)
        self.proj = self.cfg.project
        self.mem = core.ProgressMemory()

    def tearDown(self) -> None:
        self.tmp.cleanup()


class PathPolicy(Base):
    def test_relative_and_root_prefixed_paths_resolve(self):
        f = write(self.proj / "runs" / "r1" / "log.txt", "x\n")
        rid, p = core.resolve_safe(self.cfg, "workspace:" + str((core.PROJECT_REL / "runs/r1/log.txt").as_posix()), must_exist=True)
        self.assertEqual(rid, "workspace")
        self.assertEqual(os.path.normcase(str(p)), os.path.normcase(str(f)))

    def test_escape_absolute_outside_and_unknown_root_are_denied(self):
        for bad, code in [("workspace:../x.txt", "PATH_ESCAPE"), ("../../etc/passwd", "PATH_ESCAPE"), (str(Path(self.tmp.name) / "outside.txt"), "OUTSIDE_ALLOWED_ROOTS"),
                          ("secret_root:x", "INVALID_PATH"), ("work/log.txt:hidden_stream", "INVALID_PATH"), ("workspace:C:/Windows/win.ini", "OUTSIDE_ALLOWED_ROOTS"), ("", "INVALID_PATH"), ("a\x00b", "INVALID_PATH")]:
            with self.assertRaises(core.AccessDenied) as cm:
                core.resolve_safe(self.cfg, bad)
            self.assertEqual(str(cm.exception), code, bad)

    def test_private_credential_and_tooling_paths_are_denied(self):
        for rel, code in [("work/x/session/private/backups/common.ini", "PRIVATE_OR_TOOLING_DIRECTORY"), ("work/.git/config", "PRIVATE_OR_TOOLING_DIRECTORY"),
                          ("work/a/terminal.ini", "PRIVATE_OR_CREDENTIAL_FILE"), ("work/a/api_token.txt", "PRIVATE_OR_CREDENTIAL_FILE"), ("work/a/.env", "PRIVATE_OR_CREDENTIAL_FILE"),
                          ("work/a/client.pem", "PRIVATE_OR_CREDENTIAL_FILE"), ("work/lean_mcp/monitor/.venv/pyvenv.cfg", "PRIVATE_OR_TOOLING_DIRECTORY")]:
            with self.assertRaises(core.AccessDenied) as cm:
                core.resolve_safe(self.cfg, "workspace:" + rel)
            self.assertEqual(str(cm.exception), code, rel)

    def test_mt5_common_only_project_audit_names(self):
        write(self.mt5 / "SCALPI1820261011_S20_JUNE_TRADE_REVIEW.csv", "a\n")
        write(self.mt5 / "unrelated_broker_export.csv", "a\n")
        core.resolve_safe(self.cfg, "mt5_common_files:SCALPI1820261011_S20_JUNE_TRADE_REVIEW.csv", must_exist=True)
        with self.assertRaises(core.AccessDenied) as cm:
            core.resolve_safe(self.cfg, "mt5_common_files:unrelated_broker_export.csv")
        self.assertEqual(str(cm.exception), "MT5_COMMON_NOT_PROJECT_AUDIT")

    def test_junction_inside_root_is_denied(self):
        try:
            import _winapi
        except ImportError:
            self.skipTest("Windows junction API unavailable")
        target = Path(self.tmp.name) / "elsewhere"
        target.mkdir()
        write(target / "log.txt", "outside\n")
        link = self.ws / "work" / "jlink"
        link.parent.mkdir(parents=True, exist_ok=True)
        _winapi.CreateJunction(str(target), str(link))
        with self.assertRaises(core.AccessDenied) as cm:
            core.resolve_safe(self.cfg, "workspace:work/jlink/log.txt")
        self.assertEqual(str(cm.exception), "REPARSE_POINT_OR_LINK")

    def test_symlink_is_denied_when_creatable(self):
        target = write(Path(self.tmp.name) / "outside.txt", "x\n")
        link = self.ws / "work" / "slink.txt"
        link.parent.mkdir(parents=True, exist_ok=True)
        try:
            os.symlink(target, link)
        except OSError:
            self.skipTest("symlink creation not permitted on this account")
        with self.assertRaises(core.AccessDenied):
            core.resolve_safe(self.cfg, "workspace:work/slink.txt")


class Redaction(Base):
    def test_patterns(self):
        s = 'password=hunter2 token: abc.def "api-access-token": "XYZ123" login 12345678 mail a.b@example.com sk-ABCDEFGHIJKLMNOPQRST Bearer abcdefghijkl'
        r = core.redact(s)
        for leaked in ("hunter2", "XYZ123", "12345678", "a.b@example.com", "ABCDEFGHIJKLMNOPQRST", "abcdefghijkl"):
            self.assertNotIn(leaked, r)
        self.assertIn("sha256=", core.redact("sha256=" + "a" * 64))  # hashes stay


class Tail(Base):
    def test_utf8_bounded_and_redacted(self):
        p = write(self.proj / "runs" / "r" / "log.txt", "".join(f"line {i} password=pw{i}\n" for i in range(1000)))
        out = core.tail_lines(self.cfg, "workspace:" + (core.PROJECT_REL / "runs/r/log.txt").as_posix(), max_lines=5, max_bytes=4096)
        self.assertEqual(out["line_count"], 5)
        self.assertTrue(out["lines"][-1].startswith("line 999"))
        self.assertTrue(all("pw" not in x for x in out["lines"]))
        self.assertTrue(out["truncated_from_start"])
        self.assertLessEqual(out["bytes_read"], 4096)

    def test_utf16_mt5_journal(self):
        write(self.proj / "runs" / "r" / "journal.log", "".join(f"行 {i}\r\n" for i in range(300)), encoding="utf-16-le")
        out = core.tail_lines(self.cfg, "workspace:" + (core.PROJECT_REL / "runs/r/journal.log").as_posix(), max_lines=3, max_bytes=1001)
        self.assertEqual(out["encoding"], "utf-16-le")
        self.assertEqual(out["lines"][-1], "行 299")

    def test_limits_clamped_and_non_text_refused(self):
        write(self.proj / "runs" / "r" / "a.log", "x\n" * 10)
        out = core.tail_lines(self.cfg, "workspace:" + (core.PROJECT_REL / "runs/r/a.log").as_posix(), max_lines=10**9, max_bytes=10**9)
        self.assertEqual(out["limits"], {"max_lines": core.MAX_TAIL_LINES, "max_bytes": core.MAX_TAIL_BYTES})
        write(self.proj / "runs" / "r" / "x.dll", "MZ")
        with self.assertRaises(core.AccessDenied):
            core.tail_lines(self.cfg, "workspace:" + (core.PROJECT_REL / "runs/r/x.dll").as_posix())


class LeanClassification(Base):
    def run_dir(self, name: str) -> Path:
        d = self.proj / "runs" / name
        d.mkdir(parents=True)
        return d

    def test_code_integrity_block_is_failed(self):
        d = self.run_dir("probe")
        write(d / "console.log", "TRACE:: Engine.Main(): Started\nSkipping FileLoadException: QuantConnect.Messaging.dll 应用程序控制策略已阻止此文件。 (0x800711C7)\nUnhandled exception. System.ArgumentException\n")
        r = core.classify_lean_run(self.cfg, d, self.mem)
        self.assertEqual(r["status"], "FAILED")
        self.assertIn("CODE_INTEGRITY_BLOCKED_DLL", r["failure_reasons"])

    def test_completed_needs_terminal_marker_and_valid_summary(self):
        d = self.run_dir("done")
        write(d / "log.txt", "Engine.Main(): Started\n...\nProgram.Main(): Exiting Lean...\n")
        write(d / "X-summary.json", json.dumps({"statistics": {"Net Profit": "1%"}}))
        self.assertEqual(core.classify_lean_run(self.cfg, d)["status"], "COMPLETED_RESULTS_PRESENT_REVIEW_REQUIRED")

    def test_summary_without_terminal_marker_is_not_completed(self):
        d = self.run_dir("nomarker")
        old = time.time() - 3600
        write(d / "log.txt", "Engine.Main(): Started\n", mtime=old)
        write(d / "X-summary.json", json.dumps({"statistics": {}}), mtime=old)
        self.assertEqual(core.classify_lean_run(self.cfg, d)["status"], "INTERRUPTED_OR_STALLED_NO_TERMINAL_MARKER")

    def test_recent_activity_and_growth_between_calls(self):
        d = self.run_dir("live")
        p = write(d / "log.txt", "Engine.Main(): Started\n")
        r1 = core.classify_lean_run(self.cfg, d, self.mem)
        self.assertEqual(r1["status"], "RECENT_LOG_WRITE_LIVENESS_UNCONFIRMED")  # fresh mtime alone never claims a live process
        self.assertTrue(r1["logs"][0]["first_observation_this_session"])
        r1b = core.classify_lean_run(self.cfg, d, self.mem)
        self.assertEqual(r1b["status"], "RECENT_LOG_WRITE_LIVENESS_UNCONFIRMED")  # second call, no growth
        with open(p, "a", encoding="utf-8") as f:
            f.write("more progress\n")
        r2 = core.classify_lean_run(self.cfg, d, self.mem)
        self.assertGreater(r2["logs"][0]["bytes_since_last_observation"], 0)
        self.assertEqual(r2["status"], "IN_PROGRESS_LOG_GROWTH_OBSERVED")

    def test_exited_without_valid_summary_and_parse_states(self):
        d = self.run_dir("bad")
        old = time.time() - 3600
        write(d / "log.txt", "Engine.Main(): Started\nProgram.Main(): Exiting Lean...\n", mtime=old)
        write(d / "X-summary.json", "{not json", mtime=old)
        r = core.classify_lean_run(self.cfg, d)
        self.assertEqual(r["status"], "ENGINE_EXITED_WITHOUT_VALID_SUMMARY")
        self.assertEqual(r["summaries"][0]["parse"], "PARSE_ERROR")
        write(d / "X-summary.json", "{still writing")
        self.assertEqual(core.classify_lean_run(self.cfg, d)["status"], "COMPLETED_RESULT_BEING_WRITTEN")

    def test_no_log_is_not_running(self):
        d = self.run_dir("empty")
        write(d / "config.json", "{}")
        self.assertEqual(core.classify_lean_run(self.cfg, d)["status"], "NOT_STARTED_OR_NO_LOG")


class InternalDiscovery(Base):
    def test_junctioned_run_dir_and_log_are_not_read(self):
        try:
            import _winapi
        except ImportError:
            self.skipTest("Windows junction API unavailable")
        outside = Path(self.tmp.name) / "outside_run"
        write(outside / "log.txt", "Program.Main(): Exiting Lean...\n")
        write(outside / "X-summary.json", json.dumps({"statistics": {"Net Profit": "99%"}}))
        (self.proj / "runs").mkdir(parents=True, exist_ok=True)
        _winapi.CreateJunction(str(outside), str(self.proj / "runs" / "jrun"))
        s = core.run_status(self.cfg, self.mem, "lean")
        self.assertNotIn("jrun", json.dumps(s))
        r = core.latest_results(self.cfg)
        self.assertEqual(r["lean_results_total"], 0)
        # a junctioned file-parent inside a real run dir is refused too
        d = self.proj / "runs" / "real"
        write(d / "log.txt", "Engine.Main(): Started\n", mtime=time.time() - 3600)
        _winapi.CreateJunction(str(outside), str(d / "nested"))
        self.assertFalse(core.allowed(self.cfg, d / "nested" / "log.txt"))
        self.assertEqual(core.classify_lean_run(self.cfg, d)["summaries"], [])

    def test_stage_records_and_json_reads_respect_policy(self):
        write(self.proj / "research" / "STAGES.jsonl", json.dumps({"stage": "code", "sid": "S4", "status": "STARTED", "token": "abc"}) + "\nnot json\n")
        r = core.research_status(self.cfg, self.mem)
        self.assertEqual(r["stages"]["code"]["state"], "RECORDED")
        self.assertEqual(r["stages"]["compile"]["state"], "NO_RECORD")
        state, _ = core.load_json_bounded(self.cfg, self.ws / "work" / "x" / "session" / "private" / "VERIFICATION.json")
        self.assertEqual(state, "MISSING")
        write(self.ws / "work" / "x" / "session" / "private" / "VERIFICATION.json", "{}")
        state, _ = core.load_json_bounded(self.cfg, self.ws / "work" / "x" / "session" / "private" / "VERIFICATION.json")
        self.assertEqual(state, "DENIED")


class Truncation(Base):
    def test_caps_and_limits_are_reported(self):
        old_cap = core.MAX_SOURCE_FILES
        core.MAX_SOURCE_FILES = 3
        try:
            for i in range(6):
                write(self.proj / "lean" / f"f{i}.cs", "x")
            r = core.source_changes(self.cfg, self.mem, "lean")
            self.assertTrue(r["truncated_at_file_cap"])
            self.assertLessEqual(r["files_tracked"], 3)
        finally:
            core.MAX_SOURCE_FILES = old_cap
        for i in range(4):
            write(self.proj / "runs" / f"r{i}" / "log.txt", "Engine.Main(): Started\n", mtime=time.time() - 3600 - i)
        s = core.run_status(self.cfg, self.mem, "lean", limit=2)
        self.assertEqual((s["lean_runs_total"], s["lean_runs_truncated_by_limit"], len(s["lean_runs"])), (4, True, 2))
        r = core.source_changes(core.MonitorConfig(workspace=self.ws, mt5_common_files=self.mt5), core.ProgressMemory(), "lean", since_utc="2000-01-01T00:00:00Z", limit=1)
        self.assertTrue(r["changes_truncated_by_limit"])

    def test_log_scan_window_is_reported(self):
        d = self.proj / "runs" / "long"
        write(d / "log.txt", "Unhandled exception early\n" + "x" * (core.LOG_SCAN_BYTES + 10) + "\nEngine.Main(): Started\n", mtime=time.time() - 3600)
        r = core.classify_lean_run(self.cfg, d)
        self.assertTrue(r["logs"][0]["scan_window_truncated"])
        self.assertIn("scan_note", r)
        self.assertNotEqual(r["status"], "FAILED")  # the early failure is outside the window; the note says so instead of claiming none


class Builds(Base):
    def test_build_states(self):
        ok = write(self.proj / "builds" / "b1" / "build.log", "TradingBrain.Lean -> x.dll\n已成功生成。\n    0 个警告\n    0 个错误\n")
        bad = write(self.proj / "builds" / "b2" / "build.log", "x.cs(10,5): error CS1002: ; expected\nBuild FAILED.\n")
        stale = write(self.proj / "builds" / "b3" / "build.log", "Restoring...\n", mtime=time.time() - 3600)
        fresh = write(self.proj / "builds" / "b4" / "build.log", "Restoring...\n")
        self.assertEqual(core.classify_build(self.cfg, fresh, self.mem)["status"], "BUILD_RECENT_LOG_WRITE_LIVENESS_UNCONFIRMED")
        with open(fresh, "a", encoding="utf-8") as f:
            f.write("Compiling...\n")
        self.assertEqual(core.classify_build(self.cfg, fresh, self.mem)["status"], "BUILD_IN_PROGRESS_LOG_GROWTH_OBSERVED")
        self.assertEqual(core.classify_build(self.cfg, ok)["status"], "BUILD_SUCCEEDED_LOG")
        self.assertEqual(core.classify_build(self.cfg, bad)["status"], "BUILD_FAILED")
        self.assertEqual(core.classify_build(self.cfg, stale)["status"], "BUILD_INCOMPLETE_OR_INTERRUPTED")


class Sources(Base):
    def test_baseline_then_added_modified_deleted_with_hashes(self):
        a = write(self.proj / "lean" / "algorithms" / "S4" / "Algo.cs", "class A{}")
        b = write(self.proj / "lean" / "algorithms" / "S4" / "Old.cs", "class B{}")
        write(self.proj / "lean" / "algorithms" / "S4" / "bin" / "skip.cs", "ignored")
        first = core.source_changes(self.cfg, self.mem, "lean")
        self.assertTrue(first["baseline_established_now"])
        self.assertTrue(all(len(f["sha256"]) == 64 for f in first["newest_files"]))  # baseline keeps hashes
        self.assertEqual(first["changes"], [])
        self.assertEqual(first["files_tracked"], 2)
        time.sleep(0.02)
        write(a, "class A{int x;}")
        os.utime(a, (time.time() + 5, time.time() + 5))
        b.unlink()
        write(self.proj / "lean" / "algorithms" / "S4" / "New.cs", "class C{}")
        second = core.source_changes(self.cfg, self.mem, "lean")
        kinds = {Path(c["path"]).name: c["change"] for c in second["changes"]}
        self.assertEqual(kinds, {"Algo.cs": "MODIFIED", "Old.cs": "DELETED_OR_NO_LONGER_ALLOWED", "New.cs": "ADDED"})
        mod = next(c for c in second["changes"] if c["change"] == "MODIFIED")
        self.assertEqual(len(mod["sha256"]), 64)
        self.assertEqual(len(mod["previous_sha256"]), 64)
        self.assertNotEqual(mod["sha256"], mod["previous_sha256"])

    def test_touch_without_content_change_is_not_a_modification(self):
        a = write(self.proj / "lean" / "algorithms" / "S4" / "Algo.cs", "class A{}")
        core.source_changes(self.cfg, self.mem, "lean")
        os.utime(a, (time.time() + 50, time.time() + 50))
        r = core.source_changes(self.cfg, self.mem, "lean")
        self.assertEqual(r["changes"], [])
        self.assertEqual([Path(x["path"]).name for x in r["touched_content_unchanged"]], ["Algo.cs"])

    def test_source_walk_skips_junctioned_directory(self):
        try:
            import _winapi
        except ImportError:
            self.skipTest("Windows junction API unavailable")
        outside = Path(self.tmp.name) / "outside_src"
        write(outside / "Evil.cs", "class E{}")
        write(self.proj / "lean" / "algorithms" / "S4" / "Algo.cs", "class A{}")
        _winapi.CreateJunction(str(outside), str(self.proj / "lean" / "algorithms" / "S1"))
        r = core.source_changes(self.cfg, self.mem, "lean")
        self.assertEqual(r["files_tracked"], 1)
        self.assertNotIn("Evil.cs", json.dumps(r))

    def test_since_timestamp_and_bad_scope(self):
        write(self.proj / "lean" / "x.cs", "x")
        r = core.source_changes(self.cfg, self.mem, "lean", since_utc="2000-01-01T00:00:00Z")
        self.assertEqual(r["changes"][0]["change"], "MODIFIED_SINCE_TIMESTAMP")
        with self.assertRaises(core.AccessDenied):
            core.source_changes(self.cfg, self.mem, "c:/")


class ResultsAndStatus(Base):
    def test_latest_results_labels_and_empty_state(self):
        r = core.latest_results(self.cfg)
        self.assertEqual(r["lean_results_state"], "NO_PROJECT_LEAN_RESULT")
        d = self.proj / "runs" / "r1"
        write(d / "log.txt", "Program.Main(): Exiting Lean...\n")
        write(d / "A-summary.json", json.dumps({"statistics": {"Net Profit": "2%", "Total Orders": "4"}}))
        r = core.latest_results(self.cfg)
        self.assertEqual(r["lean_results"][0]["origin"], "PROJECT_LEAN")
        self.assertEqual(r["lean_results"][0]["statistics"]["Total Orders"], "4")

    def test_historical_i18_never_called_lean(self):
        ex = self.ws / core.I18_EXEC_REL
        write(ex / "EVALUATION_S4.json", json.dumps({"sid": "S4", "numeric_retention": "NUMERIC_RETENTION_RULE_NOT_MET"}))
        arm = ex / "S4_JUNE_D250"
        write(arm / "session" / "run" / "native_result.json", json.dumps({"status": "COMPLETE", "run_id": "X"}))
        write(arm / "verification" / "2026" / "VERIFICATION.json", json.dumps({"status": "PASS_X"}))
        r = core.latest_results(self.cfg, include_historical=True)
        self.assertEqual(r["i18_mt5_evaluations"][0]["origin"], "HISTORICAL_I18_MT5_NOT_LEAN")
        s = core.run_status(self.cfg, self.mem, "mt5_i18", include_historical=True)
        self.assertEqual(s["mt5_i18_arms"][0]["status"], "VERIFIED_HISTORICAL")
        self.assertEqual(s["mt5_i18_arms"][0]["origin"], "HISTORICAL_I18_MT5_NOT_LEAN")

    def test_mt5_common_listing_is_filtered_and_tracks_growth(self):
        f = write(self.mt5 / "SCALPI1820261011_X_TRADE_REVIEW.csv", "a\n")
        write(self.mt5 / "random.csv", "a\n")
        write(self.mt5 / "GSM12_EXECUTOR_x.lock", "")
        r1 = core.mt5_common_recent(self.cfg, self.mem, 10)
        self.assertEqual([x["file"] for x in r1["newest"]], ["mt5_common_files:SCALPI1820261011_X_TRADE_REVIEW.csv"])
        with open(f, "a") as h:
            h.write("b\n")
        r2 = core.mt5_common_recent(self.cfg, self.mem, 10)
        self.assertGreater(r2["newest"][0]["bytes_since_last_observation"], 0)

    def test_research_status_reports_missing_not_running(self):
        r = core.research_status(self.cfg, self.mem)
        self.assertTrue(all(v["state"] == "NO_RECORD" for v in r["stages"].values()))
        sids = [s["sid"] for s in r["strategies"]]
        self.assertEqual(sids[:2], ["S4", "Scalping"])
        self.assertEqual(sorted(sids), sorted(["S1", "S2", "S3", "S4", "S5", "S6", "Scalping"]))
        self.assertTrue(all(s["source_state"] == "NOT_STARTED" and s["latest_run_status"] == "NO_RUN" for s in r["strategies"]))

    def test_unknown_kind_denied(self):
        with self.assertRaises(core.AccessDenied):
            core.run_status(self.cfg, self.mem, "shell")


class StdioProtocol(unittest.TestCase):
    """Spawns the real server and checks that every stdout line is a JSON-RPC message (stdout = protocol only)."""

    def test_initialize_and_tools_list_over_raw_stdio(self):
        try:
            import mcp  # noqa: F401
        except ImportError:
            self.skipTest("mcp SDK not installed in this interpreter")
        with tempfile.TemporaryDirectory() as tmp:
            ws = Path(tmp)
            (ws / core.PROJECT_REL).mkdir(parents=True)
            proc = subprocess.Popen([sys.executable, str(HERE / "server.py"), "--workspace", str(ws), "--mt5-common", str(ws / "none")],
                                    stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE, cwd=str(HERE))
            msgs = [
                {"jsonrpc": "2.0", "id": 1, "method": "initialize", "params": {"protocolVersion": "2025-06-18", "capabilities": {}, "clientInfo": {"name": "raw-test", "version": "0"}}},
                {"jsonrpc": "2.0", "method": "notifications/initialized"},
                {"jsonrpc": "2.0", "id": 2, "method": "tools/list"},
                {"jsonrpc": "2.0", "id": 3, "method": "tools/call", "params": {"name": "bounded_log_tail", "arguments": {"path": "workspace:../escape.txt"}}},
            ]
            import threading
            watchdog = threading.Timer(90, proc.kill)
            watchdog.start()
            stdout_lines: list[str] = []
            try:
                for m in msgs:  # send one message, then wait for its response (requests only) before sending the next
                    proc.stdin.write((json.dumps(m) + "\n").encode())
                    proc.stdin.flush()
                    if "id" not in m:
                        continue
                    while True:
                        line = proc.stdout.readline()
                        if not line:
                            raise AssertionError("server closed stdout before answering id %s" % m["id"])
                        stdout_lines.append(line.decode("utf-8"))
                        if json.loads(line).get("id") == m["id"]:
                            break
                proc.stdin.close()
                rest, err = proc.communicate(timeout=30)
                stdout_lines += rest.decode("utf-8").splitlines()
            finally:
                watchdog.cancel()
                if proc.poll() is None:
                    proc.kill()
            out = "\n".join(stdout_lines).encode("utf-8")
            lines = [x for x in out.decode("utf-8").splitlines() if x.strip()]
            parsed = [json.loads(x) for x in lines]  # raises if anything non-JSON reached stdout
            self.assertTrue(all(m.get("jsonrpc") == "2.0" for m in parsed))
            by_id = {m.get("id"): m for m in parsed}
            tools = {t["name"] for t in by_id[2]["result"]["tools"]}
            self.assertTrue({"health", "research_status", "source_changes", "run_status", "bounded_log_tail", "latest_results"} <= tools)
            body = json.loads(by_id[3]["result"]["content"][0]["text"])
            self.assertEqual((body["ok"], body["error"], body["reason"]), (False, "ACCESS_DENIED", "PATH_ESCAPE"))
            self.assertLess(len(err), 512 * 1024 + 4096)


if __name__ == "__main__":
    unittest.main()
