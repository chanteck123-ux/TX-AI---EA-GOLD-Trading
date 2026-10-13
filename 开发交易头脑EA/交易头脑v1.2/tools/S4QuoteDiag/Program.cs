using System.Globalization;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using System.Text.Json.Nodes;
using TradingBrain.S4B2;

// S4 B2 read-only quote diagnostic driver. Modes:
//   --selftest <dir>                engineering cases on synthetic raw files
//   (default) --raw-dir --export-manifest --lean-tick-manifest --native-baseline --native-audit --lean-run --out-dir
// Never trades, never feeds native prices into a backtest, never claims causation or profit change.
var a = new Dictionary<string, string>();
for (int i = 0; i + 1 < args.Length; i += 2) a[args[i]] = args[i + 1];
var inv = CultureInfo.InvariantCulture;
string Sha(string p) => Convert.ToHexString(SHA256.HashData(File.ReadAllBytes(p))).ToLowerInvariant();
string ShaStream(string p) { using var s = File.OpenRead(p); return Convert.ToHexString(SHA256.HashData(s)).ToLowerInvariant(); }
string Day(long ms) => DateTimeOffset.FromUnixTimeMilliseconds(ms).UtcDateTime.ToString("yyyyMMdd", inv); // server-epoch label day

// Loads rows for the union of event windows, verifying each file hash against the manifest first.
Dictionary<string, List<RawRow>> LoadRows(string rawDir, IDictionary<string, string> expectedSha, IEnumerable<EventSpec> events, List<object> fileLog)
{
    var byFile = new Dictionary<string, List<(long from, long to)>>();
    foreach (var e in events)
        for (long d = e.WindowFrom / 86400000; d <= e.WindowTo / 86400000; d++)
        {
            string f = "ticks_" + Day(d * 86400000) + ".csv";
            if (!byFile.ContainsKey(f)) byFile[f] = new();
            byFile[f].Add((e.WindowFrom, e.WindowTo));
        }
    var result = new Dictionary<string, List<RawRow>>();
    foreach (var (f, ranges) in byFile.OrderBy(p => p.Key, StringComparer.Ordinal))
    {
        string path = Path.Combine(rawDir, f);
        if (!File.Exists(path)) { fileLog.Add(new { file = f, status = "MISSING_FILE" }); result[f] = new(); continue; }
        if (!expectedSha.TryGetValue(f, out var want)) throw new InvalidDataException("No manifest hash for " + f);
        string got = ShaStream(path);
        if (got != want) throw new InvalidDataException("Raw tick file hash mismatch (tampered or different export): " + f);
        var keep = new List<RawRow>(); long line = 0, total = 0, prevMs = long.MinValue; string header = null;
        var sorted = ranges.OrderBy(r => r.from).ToArray();
        foreach (var text in File.ReadLines(path))
        {
            line++;
            if (line == 1) { header = text; if (!text.StartsWith("server_time_msc,bid,ask,last,volume,flags,volume_real")) throw new InvalidDataException("Unexpected header in " + f); continue; }
            if (text.Length == 0) continue;
            total++;
            var row = Diagnose.Parse(f, line, text);
            if (row.Ms < prevMs) throw new InvalidDataException($"{f}:{line} time moved backward");
            prevMs = row.Ms;
            foreach (var (from, to) in sorted) { if (row.Ms < from) break; if (row.Ms <= to) { keep.Add(row); break; } }
        }
        fileLog.Add(new { file = f, status = "HASH_VERIFIED", sha256 = got, data_rows = total, rows_kept = keep.Count });
        result[f] = keep;
    }
    return result;
}

List<RawRow> RowsFor(EventSpec e, Dictionary<string, List<RawRow>> byFile)
{
    var rows = new List<RawRow>();
    for (long d = e.WindowFrom / 86400000; d <= e.WindowTo / 86400000; d++)
        if (byFile.TryGetValue("ticks_" + Day(d * 86400000) + ".csv", out var list)) rows.AddRange(list.Where(x => x.Ms >= e.WindowFrom && x.Ms <= e.WindowTo));
    return rows;
}

void WriteOutputs(string outDir, List<EventResult> results, Func<EventResult, string> subset)
{
    Directory.CreateDirectory(outDir);
    using (var w = new StreamWriter(Path.Combine(outDir, "evidence_rows.csv"), false, new UTF8Encoding(false)))
    {
        w.WriteLine("key,direction,event_kind,anchor_ms,file,line,row_ms,offset_ms,same_ms_as_anchor,dup_index_in_ms,dup_count_in_ms,bid,ask,last,volume,flags,flags_decoded,volume_real,side_price,side_matches_observed,candidate_roles");
        foreach (var r in results)
        {
            var e = r.Spec;
            var roles = r.Candidates.Where(c => c.Row != null).GroupBy(c => c.Row).ToDictionary(g => g.Key, g => string.Join("|", g.Select(c => c.Name)));
            foreach (var grp in r.Window.GroupBy(x => (x.File, x.Ms)))
            {
                int idx = 0, cnt = grp.Count();
                foreach (var x in grp)
                {
                    w.WriteLine(string.Join(",", Diagnose.Csv(e.Key), e.Dir, e.Kind, e.AnchorMs, x.File, x.Line, x.Ms, x.Ms - e.AnchorMs, x.Ms == e.AnchorMs ? 1 : 0, idx++, cnt,
                        Diagnose.N(x.Bid), Diagnose.N(x.Ask), Diagnose.N(x.Last), x.Volume, x.Flags, Flags.Decode(x.Flags), Diagnose.N(x.VolumeReal), Diagnose.N(x.Side(e.Dir)),
                        Diagnose.Same(x.Side(e.Dir), e.Observed) ? 1 : 0, roles.GetValueOrDefault(x, "")));
                }
            }
        }
    }
    using (var w = new StreamWriter(Path.Combine(outDir, "events.csv"), false, new UTF8Encoding(false)))
    {
        var names = results.FirstOrDefault()?.Candidates.Select(c => c.Name).ToList() ?? new List<string>();
        w.WriteLine("key,direction,event_kind,time_semantics,anchor_ms,observed_price,subset,status,window_rows,window_side_matches,nearest_match_offset_ms,nearest_match_line,fill_second,fill_second_status,fill_second_matches,fill_second_rows,"
            + string.Join(",", names.SelectMany(n => new[] { n + "_line", n + "_ms", n + "_price", n + "_match" })));
        foreach (var r in results)
        {
            var e = r.Spec;
            var cells = new List<string> { Diagnose.Csv(e.Key), e.Dir.ToString(), e.Kind, Diagnose.Csv(e.TimeSemantics), e.AnchorMs.ToString(), Diagnose.N(e.Observed), subset(r), r.Status, r.Window.Count.ToString(), r.WindowMatches.ToString(),
                r.NearestMatchOffsetMs?.ToString() ?? "", r.NearestMatchLine?.ToString() ?? "", e.FillSecond?.ToString() ?? "", r.FillSecondStatus, r.FillSecondMatches.ToString(), Diagnose.Csv(r.FillSecondLines) };
            foreach (var c in r.Candidates) cells.AddRange(new[] { c.Row?.Line.ToString() ?? "", c.Row?.Ms.ToString() ?? "", c.Row == null ? "" : Diagnose.N(c.Row.Side(e.Dir)), c.Match == null ? "MISSING" : (c.Match.Value ? "1" : "0") });
            w.WriteLine(string.Join(",", cells));
        }
    }
}

JsonObject Stats(IEnumerable<EventResult> rs)
{
    var o = new JsonObject();
    foreach (var g in rs.GroupBy(r => r.Spec.Kind).OrderBy(g => g.Key, StringComparer.Ordinal))
    {
        var list = g.ToList(); var k = new JsonObject { ["events"] = list.Count };
        var cand = new JsonObject();
        foreach (var name in list[0].Candidates.Select(c => c.Name))
        {
            var cs = list.Select(r => r.Candidates.First(c => c.Name == name)).ToList();
            cand[name] = new JsonObject { ["preregistered"] = cs[0].Preregistered, ["match"] = cs.Count(c => c.Match == true), ["no_match"] = cs.Count(c => c.Match == false), ["missing"] = cs.Count(c => c.Match == null) };
        }
        k["candidates"] = cand;
        k["status"] = new JsonObject(list.GroupBy(r => r.Status).OrderBy(x => x.Key).Select(x => KeyValuePair.Create(x.Key, (JsonNode)JsonValue.Create(x.Count()))));
        k["any_row_in_window_matches"] = list.Count(r => r.WindowMatches > 0);
        if (g.Key == "NATIVE_FILL") k["fill_second_status"] = new JsonObject(list.GroupBy(r => r.FillSecondStatus).OrderBy(x => x.Key).Select(x => KeyValuePair.Create(x.Key, (JsonNode)JsonValue.Create(x.Count()))));
        o[g.Key] = k;
    }
    return o;
}

// ============================================================ selftest (engineering cases)
if (a.ContainsKey("--selftest"))
{
    string dir = a["--selftest"]; Directory.CreateDirectory(dir);
    long d0 = 1785715200000L; // 2026-08-03 00:00 server label
    string f3 = Path.Combine(dir, "ticks_20260803.csv"), f4 = Path.Combine(dir, "ticks_20260804.csv"), hdr = "server_time_msc,bid,ask,last,volume,flags,volume_real";
    long t = d0 + 3600000; // 01:00:00.000
    File.WriteAllLines(f3, new[] { hdr,
        $"{t - 10},100.00,100.20,100.00,1,1030,1.0",       // BID|ASK|OTHER_1024
        $"{t},100.01,100.21,100.01,1,280,1.0",             // same ms first: LAST|VOLUME|OTHER_256 (prices carried)
        $"{t},100.02,100.22,100.02,1,6,1.0",               // same ms second: BID|ASK
        $"{t},100.03,100.23,100.03,1,2,1.0",               // same ms last: BID only
        $"{t + 300},100.10,100.30,100.10,1,6,1.0",
        $"{d0 + 86400000 - 5},101.00,101.20,101.00,1,6,1.0" }); // last row of day
    File.WriteAllLines(f4, new[] { hdr, $"{d0 + 86400000 + 3},101.50,101.70,101.50,1,6,1.0" }); // first row of next day
    var sha = new Dictionary<string, string> { ["ticks_20260803.csv"] = ShaStream(f3), ["ticks_20260804.csv"] = ShaStream(f4) };
    var checks = new List<(string name, bool ok, string detail)>();
    EventSpec E(string kind, int dir_, long anchor, double obs, long? sec = null, long? send = null) => new EventSpec { Key = "K_" + kind + "_" + anchor + "_" + obs, Dir = dir_, Kind = kind, AnchorMs = anchor, Observed = obs,
        WindowFrom = (send ?? anchor) - 2000, WindowTo = Math.Max(anchor + 2000, sec.HasValue ? sec.Value * 1000 + 999 : long.MinValue), FillSecond = sec, SendMs = send, TimeSemantics = "SELFTEST" };
    var evs = new List<EventSpec>
    {
        E("LEAN_RESERVE", -1, t, 100.03),            // bid side; same-ms LAST row matches, FIRST does not -> discriminating
        E("LEAN_RESERVE", 1, t, 100.22),             // ask side; matches SAME_MS second row only (not a fixed candidate) -> no prereg match but window match
        E("LEAN_RESERVE", -1, t, 100.00),            // matches PREV only
        E("LEAN_RESERVE", -1, d0 + 86400000 + 1, 101.00), // window crosses midnight; PREV is previous file's last row
        E("LEAN_RESERVE", -1, d0 + 5 * 3600000, 99.0),     // no rows in window -> missing
        E("NATIVE_FILL", 1, t + 250, 100.30, t / 1000, t), // deal second contains t+300 row only after... second = t/1000 -> rows t..t+999 with ask 100.30: one
        E("NATIVE_FILL", 1, t + 250, 100.30, null, t)     // missing deal time
    };
    var log = new List<object>();
    var rows = LoadRows(dir, sha, evs, log);
    var res = evs.Select(e => Diagnose.Evaluate(e, RowsFor(e, rows))).ToList();
    string C(EventResult r, string n) { var c = r.Candidates.First(x => x.Name == n); return c.Match == null ? "MISSING" : c.Match.Value ? "1" : "0"; }
    checks.Add(("same_ms_first_vs_last_discriminates", C(res[0], "SAME_MS_FIRST_ROW") == "0" && C(res[0], "SAME_MS_LAST_ROW") == "1" && res[0].Status.StartsWith("DISCRIMINATING"), res[0].Status));
    checks.Add(("duplicate_ms_rows_all_kept_with_lines", res[0].Window.Count(x => x.Ms == t) == 3 && res[0].Window.Where(x => x.Ms == t).Select(x => x.Line).SequenceEqual(new long[] { 3, 4, 5 }), ""));
    checks.Add(("side_flag_candidate_uses_ask_bit_for_long", res[1].Candidates.First(x => x.Name == "LAST_ROW_WITH_SIDE_FLAG_AT_OR_BEFORE").Row?.Line == 4, "line=" + res[1].Candidates.First(x => x.Name == "LAST_ROW_WITH_SIDE_FLAG_AT_OR_BEFORE").Row?.Line));
    checks.Add(("side_flag_candidate_uses_bid_bit_for_short", res[0].Candidates.First(x => x.Name == "LAST_ROW_WITH_SIDE_FLAG_AT_OR_BEFORE").Row?.Line == 5, ""));
    checks.Add(("middle_duplicate_match_found_in_window_not_forced_into_candidates", res[1].WindowMatches == 1 && res[1].NearestMatchLine == 4, res[1].Status));
    checks.Add(("prev_only_match", C(res[2], "PREV_LAST_ROW_BEFORE") == "1" && C(res[2], "SAME_MS_LAST_ROW") == "0", res[2].Status));
    checks.Add(("window_crosses_file_boundary", res[3].Candidates.First(x => x.Name == "PREV_LAST_ROW_BEFORE").Row?.File == "ticks_20260803.csv" && res[3].Window.Any(x => x.File == "ticks_20260804.csv"), ""));
    checks.Add(("missing_window_marked", res[4].Status == "MISSING_NO_RAW_ROWS_IN_WINDOW", res[4].Status));
    checks.Add(("native_fill_deal_second_unique", res[5].FillSecondStatus == "UNIQUE_ROW", res[5].FillSecondStatus));
    checks.Add(("native_fill_missing_deal_time_marked", res[6].FillSecondStatus == "MISSING_DEAL_TIME", res[6].FillSecondStatus));
    checks.Add(("flags_decoded_with_other_bits", Flags.Decode(280) == "LAST|VOLUME|OTHER_256" && Flags.Decode(1030) == "BID|ASK|OTHER_1024", Flags.Decode(280) + " " + Flags.Decode(1030)));
    bool tamperRefused = false;
    try { LoadRows(dir, new Dictionary<string, string>(sha) { ["ticks_20260803.csv"] = new string('0', 64) }, evs, new List<object>()); } catch (InvalidDataException) { tamperRefused = true; }
    checks.Add(("tampered_raw_file_refused", tamperRefused, ""));
    WriteOutputs(Path.Combine(dir, "out"), res, _ => "SELFTEST");
    var rep = new { schema = "S4_B2_QUOTE_DIAG_SELFTEST_V1", status = checks.All(c => c.ok) ? "PASS" : "FAIL", passed = checks.Count(c => c.ok), failed = checks.Where(c => !c.ok).Select(c => c.name + " :: " + c.detail).ToArray(), names = checks.Select(c => c.name).ToArray() };
    var json = JsonSerializer.Serialize(rep, new JsonSerializerOptions { WriteIndented = true });
    File.WriteAllText(Path.Combine(dir, "SELFTEST_RESULT.json"), json); Console.WriteLine(json);
    return checks.All(c => c.ok) ? 0 : 1;
}

// ============================================================ real diagnostic
string rawDir = a["--raw-dir"], exportManifest = a["--export-manifest"], leanTickManifest = a["--lean-tick-manifest"], baselinePath = a["--native-baseline"],
       nativeAudit = a["--native-audit"], leanRun = a["--lean-run"], outDir = a["--out-dir"];
var gate = new List<string>();
// ---- tick manifest chain: LEAN manifest names the export manifest by hash; export manifest names each raw file by hash.
var ltm = JsonNode.Parse(File.ReadAllText(leanTickManifest))!;
if ((string)ltm["sourceManifestSha256"] != Sha(exportManifest)) gate.Add("EXPORT_MANIFEST.json hash differs from LEAN_TICK_MANIFEST.sourceManifestSha256");
var em = JsonNode.Parse(File.ReadAllText(exportManifest))!;
if (!((string)em["status"] ?? "").StartsWith("COMPLETE")) gate.Add("export manifest not COMPLETE");
var rawSha = em["files"]!.AsArray().ToDictionary(f => (string)f!["name"]!, f => (string)f!["sha256"]!);
// ---- native proof chain: baseline proof -> native_receipt native_result.json -> evidence_sha256 for audit CSVs
var baseline = JsonNode.Parse(File.ReadAllText(baselinePath))!;
string proofPath = (string)baseline["proof"]!["path"]!, runId = (string)baseline["run_id"]!;
var nativeCsv = new[] { "orders_audit", "complete_trades" }.ToDictionary(n => n, n => Path.Combine(nativeAudit, runId + "_" + n + ".csv"));
if (!File.Exists(proofPath) || Sha(proofPath) != (string)baseline["proof"]!["sha256"]!) gate.Add("native proof hash mismatch");
else
{
    var rec = new List<JsonObject>();
    void Walk(JsonNode n) { if (n is JsonObject o) { if ((string)o["role"] == "native_receipt") rec.Add(o); foreach (var kv in o) if (kv.Value != null) Walk(kv.Value); } else if (n is JsonArray arr) foreach (var x in arr) if (x != null) Walk(x); }
    Walk(JsonNode.Parse(File.ReadAllText(proofPath))!);
    var pairs = rec.Select(o => ((string)o["path"], (string)o["sha256"])).Distinct().ToList();
    if (pairs.Count != 1 || !File.Exists(pairs[0].Item1) || Sha(pairs[0].Item1) != pairs[0].Item2) gate.Add("native_result.json missing or hash differs from proof");
    else
    {
        var ev = JsonNode.Parse(File.ReadAllText(pairs[0].Item1))!["evidence_sha256"];
        foreach (var (n, p) in nativeCsv) { var want = (string)ev?["audit/" + Path.GetFileName(p)]; if (want == null || !File.Exists(p) || Sha(p) != want) gate.Add("native CSV hash mismatch or missing: " + Path.GetFileName(p)); }
    }
}
// ---- LEAN run must be the complete, hash-matched full-August run
var receipt = JsonNode.Parse(File.ReadAllText(Path.Combine(leanRun, "RUN_RECEIPT.json")))!;
if ((string)receipt["status"] != "FULL_AUGUST_COMPLETE_REVIEW_REQUIRED") gate.Add("LEAN receipt status " + receipt["status"]);
if ((string)receipt["result_sha256"] != Sha(Path.Combine(leanRun, "RESULT.json"))) gate.Add("LEAN RESULT hash differs from receipt");
Directory.CreateDirectory(outDir);
var inputs = new JsonObject
{
    ["raw_dir"] = rawDir, ["export_manifest_sha256"] = Sha(exportManifest), ["lean_tick_manifest_sha256"] = Sha(leanTickManifest), ["native_baseline_sha256"] = Sha(baselinePath),
    ["native_csv_sha256"] = new JsonObject(nativeCsv.Where(p => File.Exists(p.Value)).Select(p => KeyValuePair.Create(p.Key, (JsonNode)JsonValue.Create(Sha(p.Value))))),
    ["lean_orders_binding"] = "CURRENT_FILE_HASH_ONLY: no frozen expected SHA for orders.jsonl exists in B1 artifacts (receipt binds RESULT.json only); this input is not covered by a complete anti-tamper chain", ["lean_run"] = leanRun, ["lean_receipt_sha256"] = Sha(Path.Combine(leanRun, "RUN_RECEIPT.json")), ["lean_orders_sha256"] = Sha(Path.Combine(leanRun, "orders.jsonl"))
};
if (gate.Count > 0)
{
    File.WriteAllText(Path.Combine(outDir, "SUMMARY.json"), new JsonObject { ["status"] = "NOT_RUN_GATE_FAILED", ["gate_failures"] = new JsonArray(gate.Select(g => (JsonNode)JsonValue.Create(g)).ToArray()), ["inputs"] = inputs }.ToJsonString(new JsonSerializerOptions { WriteIndented = true }));
    Console.WriteLine("NOT_RUN_GATE_FAILED"); return 2;
}

// ---- events (55 common reservations): native reserve, LEAN reserve, native fill (send time + hypothesis), LEAN actual fill
List<string[]> NativeRows(string path)
{
    var rows = new List<string[]>();
    foreach (var line in File.ReadLines(path).Skip(1))
    {
        var f = new List<string>(); var sb = new StringBuilder(); bool q = false;
        foreach (char ch in line) { if (ch == '"') q = !q; else if (ch == ',' && !q) { f.Add(sb.ToString()); sb.Clear(); } else sb.Append(ch); }
        f.Add(sb.ToString()); rows.Add(f.ToArray());
    }
    return rows;
}
Dictionary<string, string> Kv(string d) => d.Split(';').Select(x => x.Split('=', 2)).Where(x => x.Length == 2).GroupBy(x => x[0]).ToDictionary(g => g.Key, g => g.First()[1]);
var nOrders = NativeRows(nativeCsv["orders_audit"]).Where(r => r[8] == "S4").ToList();
var nRes = nOrders.Where(r => r[9] == "RESERVED").GroupBy(r => r[10]).ToDictionary(g => g.Key, g => g.First());
var nSent = nOrders.Where(r => r[9] == "ORDER_SENT").GroupBy(r => r[10]).ToDictionary(g => g.Key, g => g.First());
var nEntry = NativeRows(nativeCsv["complete_trades"]).Where(r => r[8] == "S4" && r[9] == "CLOSED").Select(r => Kv(r[11])).GroupBy(k => k["setup"]).ToDictionary(g => g.Key, g => g.First());
var lOrders = File.ReadLines(Path.Combine(leanRun, "orders.jsonl")).Where(l => l.Trim().Length > 0).Select(l => JsonNode.Parse(l)!).ToList();
var lRes = lOrders.Where(o => (string)o["event"] == "RESERVED").GroupBy(o => (string)o["key"]).ToDictionary(g => g.Key, g => g.First());
var bookKey = lRes.ToDictionary(p => (int)p.Value["book"]!, p => p.Key);
var lFill = lOrders.Where(o => (string)o["event"] == "ENTRY_FILLED").ToDictionary(o => bookKey[(int)o["book"]!], o => o);
var common = nRes.Keys.Intersect(lRes.Keys).OrderBy(k => k, StringComparer.Ordinal).ToList();
var events = new List<EventSpec>();
var subsetOf = new Dictionary<string, string>();
foreach (var k in common)
{
    int dir = int.Parse(k.Split('|')[2], inv);
    long nT = long.Parse(nRes[k][5], inv), lT = (long)lRes[k]["server_msc"]!;
    double nP = double.Parse(Kv(nRes[k][11])["planned_price"], inv), lP = (double)lRes[k]["planned_price"]!;
    subsetOf[k] = nT != lT ? "DIFFERENT_RESERVE_MS" : Math.Abs(nP - lP) < Diagnose.PriceTol ? "SAME_MS_SAME_PLANNED_PRICE" : "SAME_MS_DIFFERENT_PLANNED_PRICE";
    EventSpec E(string kind, string sem, long anchor, double obs) => new EventSpec { Key = k, Dir = dir, Kind = kind, TimeSemantics = sem, AnchorMs = anchor, Observed = obs, WindowFrom = anchor - 2000, WindowTo = anchor + 2000 };
    events.Add(E("NATIVE_RESERVE", "CACHED_QUOTE_TIMESTAMP: native Audit writes global quote.time_msc (MQ5 line 231); quote last refreshed by RiskGate->CanExecute SymbolInfoTick (line 2666); not an independently measured event time; observed=planned_price (entry side)", nT, nP));
    events.Add(E("LEAN_RESERVE", "LEAN RESERVED server_msc (quote row processed by S4Core); observed=planned_price", lT, lP));
    if (nSent.TryGetValue(k, out var sent))
    {
        long sendMs = long.Parse(sent[5], inv); double fp = double.Parse(Kv(sent[11])["price"], inv);
        long? sec = nEntry.TryGetValue(k, out var tr) && tr.TryGetValue("entry_time", out var et) ? long.Parse(et, inv) : null;
        var e = E("NATIVE_FILL", "CACHED_QUOTE_TIMESTAMP: ORDER_SENT Audit (line 3018, after synchronous OrderSend) writes the cached quote.time_msc with no quote refresh in between; it is NOT a measured send, receipt or fill time; anchor=cached+250 is a HYPOTHESIS ONLY; DEAL_TIME known only to the second (complete_trades.entry_time) = AMBIGUOUS; observed=ORDER_SENT result price", sendMs + 250, fp);
        e.SendMs = sendMs; e.FillSecond = sec; e.WindowFrom = sendMs - 2000; e.WindowTo = Math.Max(sendMs + 250 + 2000, sec.HasValue ? sec.Value * 1000 + 999 : long.MinValue);
        events.Add(e);
    }
    if (lFill.TryGetValue(k, out var lf))
        events.Add(E("LEAN_FILL", "LEAN ENTRY_FILLED server_msc = actual LEAN fill quote time (first row at/after reserve+250 ms in B1 R2)", (long)lf["server_msc"]!, (double)lf["price"]!));
}
var fileLog = new List<object>();
var byFile = LoadRows(rawDir, rawSha, events, fileLog);
var results = events.Select(e => Diagnose.Evaluate(e, RowsFor(e, byFile))).ToList();
WriteOutputs(outDir, results, r => subsetOf[r.Spec.Key]);

JsonArray PostHoc(IEnumerable<EventResult> rs)
{
    // Descriptive cross-tab only: subset x flags of rows in the anchor millisecond x which fixed candidates matched. Not a test, not a mechanism.
    var arr = new JsonArray();
    foreach (var g in rs.GroupBy(r => (subsetOf[r.Spec.Key], string.Join("/", r.Window.Where(x => x.Ms == r.Spec.AnchorMs).Select(x => x.Flags)),
        r.Candidates.First(c => c.Name == "PREV_LAST_ROW_BEFORE").Match == true, r.Candidates.First(c => c.Name == "SAME_MS_FIRST_ROW").Match == true)).OrderBy(g => g.Key.Item1).ThenBy(g => g.Key.Item2))
        arr.Add(new JsonObject { ["subset"] = g.Key.Item1, ["anchor_ms_row_flags"] = g.Key.Item2, ["prev_row_matches"] = g.Key.Item3, ["same_ms_first_row_matches"] = g.Key.Item4, ["events"] = g.Count() });
    return arr;
}
// ---- pairwise view for reservations in the same millisecond: which fixed candidate each side matches
var pair = new JsonArray();
foreach (var k in common.Where(k => subsetOf[k] != "DIFFERENT_RESERVE_MS"))
{
    var nr = results.First(r => r.Spec.Key == k && r.Spec.Kind == "NATIVE_RESERVE"); var lr = results.First(r => r.Spec.Key == k && r.Spec.Kind == "LEAN_RESERVE");
    string M(EventResult r) => string.Join("|", r.Candidates.Where(c => c.Preregistered && c.Match == true).Select(c => c.Name));
    pair.Add(new JsonObject { ["key"] = k, ["subset"] = subsetOf[k], ["native_matches"] = M(nr), ["lean_matches"] = M(lr), ["rows_in_ms"] = nr.Window.Count(x => x.Ms == nr.Spec.AnchorMs),
        ["native_status"] = nr.Status, ["lean_status"] = lr.Status });
}
var summary = new JsonObject
{
    ["schema"] = "S4_B2_QUOTE_DIAGNOSTIC_SUMMARY_V1", ["status"] = "DIAGNOSTIC_COMPLETE_REVIEW_REQUIRED", ["generated_utc"] = DateTime.UtcNow.ToString("o"),
    ["scope"] = "Read-only raw-tick evidence for 55 common reservations and entry fills; fixed candidates; no causation, no profit claim, no trading-code change",
    ["inputs"] = inputs, ["raw_files"] = JsonNode.Parse(JsonSerializer.Serialize(fileLog)),
    ["common_keys"] = common.Count,
    ["subsets"] = new JsonObject(common.GroupBy(k => subsetOf[k]).OrderBy(g => g.Key).Select(g => KeyValuePair.Create(g.Key, (JsonNode)JsonValue.Create(g.Count())))),
    ["stats_all"] = Stats(results),
    ["stats_same_ms_different_planned_price"] = Stats(results.Where(r => subsetOf[r.Spec.Key] == "SAME_MS_DIFFERENT_PLANNED_PRICE")),
    ["stats_same_ms_same_planned_price"] = Stats(results.Where(r => subsetOf[r.Spec.Key] == "SAME_MS_SAME_PLANNED_PRICE")),
    ["same_ms_reservation_pairs"] = pair,
    ["candidate_definitions"] = new JsonObject
    {
        ["PREV_LAST_ROW_BEFORE"] = "last raw row with time < anchor (preregistered)",
        ["SAME_MS_FIRST_ROW"] = "first raw row with time == anchor (preregistered)",
        ["SAME_MS_LAST_ROW"] = "last raw row with time == anchor (preregistered)",
        ["LAST_ROW_WITH_SIDE_FLAG_AT_OR_BEFORE"] = "last row with time <= anchor carrying TICK_FLAG_ASK (long) / TICK_FLAG_BID (short) (preregistered)",
        ["SUPPLEMENTARY_FIRST_ROW_AT_OR_AFTER"] = "first row with time >= anchor; the B1 R2 LEAN delay rule, NOT preregistered, reported separately"
    },
    ["price_tolerance"] = Diagnose.PriceTol,
    ["window_caveat"] = "All candidates (previous row, side-flag row, nearest match) are searched only within the +-2 s window (native fill: from cached-2 s to max(cached+2.25 s, end of deal second)); they are not the latest quote over unlimited history",
    ["post_hoc_descriptive_not_preregistered"] = PostHoc(results.Where(r => r.Spec.Kind == "NATIVE_RESERVE")),
    ["mechanisms_to_verify_not_established"] = new JsonArray("MT5 tester quote cache per millisecond", "OnTick merging of same-ms rows", "synchronous OrderSend blocking under 250 ms delay"),
    ["claims_not_made"] = new JsonArray("causation identified", "profit improvement", "native parity", "score", "Champion", "live readiness")
};
File.WriteAllText(Path.Combine(outDir, "SUMMARY.json"), summary.ToJsonString(new JsonSerializerOptions { WriteIndented = true }));
Console.WriteLine("DIAGNOSTIC_COMPLETE events=" + results.Count + " keys=" + common.Count);
return 0;
