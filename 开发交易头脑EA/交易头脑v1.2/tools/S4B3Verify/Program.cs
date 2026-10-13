using System.Globalization;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using System.Text.Json.Nodes;

// S4 B3 read-only verifier: probe CSV evidence vs hash-verified raw ticks. Definitions frozen in
// research/S4_B3_VERIFY_PLAN.json before this ran. No MT5, no trading, no Python, no causal claim.
var a = new Dictionary<string, string>();
for (int i = 0; i + 1 < args.Length; i += 2) a[args[i]] = args[i + 1];
var inv = CultureInfo.InvariantCulture;
string Sha(string p) { using var s = File.OpenRead(p); return Convert.ToHexString(SHA256.HashData(s)).ToLowerInvariant(); }
const double Tol = 0.005;
bool Eq(double x, double y) => Math.Abs(x - y) < Tol;
string rawPath = a["--raw"], exportManifest = a["--export-manifest"], plan = a["--plan"], outPath = a["--out"];
var runs = new Dictionary<string, string> { ["QUOTE_D0"] = a["--quote"], ["ORDER_D0"] = a["--order-d0"], ["ORDER_D250"] = a["--order-d250"] };
var report = new JsonObject { ["schema"] = "S4_B3_VERIFY_RESULT_V1", ["generated_utc"] = DateTime.UtcNow.ToString("o"), ["plan_sha256"] = Sha(plan) };
var gate = new List<string>();

// ---- input gates
var em = JsonNode.Parse(File.ReadAllText(exportManifest))!;
string want = em["files"]!.AsArray().First(f => (string)f!["name"] == Path.GetFileName(rawPath))!["sha256"]!.ToString();
string rawSha = Sha(rawPath); if (rawSha != want) gate.Add("raw tick file hash differs from EXPORT_MANIFEST");
var runInfo = new JsonObject();
foreach (var (v, dir) in runs)
{
    var pr = JsonNode.Parse(File.ReadAllText(Path.Combine(dir, "probe_result.json")))!;
    if ((string)pr["status"] != "COMPLETE_REVIEW_REQUIRED") gate.Add(v + " probe_result status " + pr["status"]);
    int bad = 0, n = 0;
    foreach (var kv in pr["evidence_sha256"]!.AsObject()) { n++; var p = Path.Combine(dir, kv.Key.Replace('/', Path.DirectorySeparatorChar)); if (!File.Exists(p) || Sha(p) != (string)kv.Value) bad++; }
    if (bad > 0) gate.Add(v + " evidence hash mismatches: " + bad);
    runInfo[v] = new JsonObject { ["dir"] = dir, ["probe_result_sha256"] = Sha(Path.Combine(dir, "probe_result.json")), ["evidence_files_rehashed"] = n, ["mismatches"] = bad };
}
report["inputs"] = new JsonObject { ["raw"] = rawPath, ["raw_sha256"] = rawSha, ["raw_manifest_match"] = rawSha == want, ["runs"] = runInfo };
if (gate.Count > 0) { report["status"] = "NOT_RUN_GATE_FAILED"; report["gate_failures"] = new JsonArray(gate.Select(g => (JsonNode)JsonValue.Create(g)).ToArray()); Save(); return 2; }

// ---- raw rows (1-based data index)
var ms = new List<long> { 0 }; var bid = new List<double> { 0 }; var ask = new List<double> { 0 }; var flg = new List<int> { 0 }; var line = new List<long> { 0 };
long ln = 0;
foreach (var t in File.ReadLines(rawPath)) { ln++; if (ln == 1) continue; var c = t.Split(','); ms.Add(long.Parse(c[0], inv)); bid.Add(double.Parse(c[1], inv)); ask.Add(double.Parse(c[2], inv)); flg.Add(int.Parse(c[5], inv)); line.Add(ln); }
int rawN = ms.Count - 1;
report["raw_rows"] = rawN;

List<Dictionary<string, string>> Csv(string path)
{
    var rows = new List<Dictionary<string, string>>(); string[] head = null;
    foreach (var l in File.ReadLines(path))
    {
        var f = new List<string>(); var sb = new StringBuilder(); bool q = false;
        for (int i = 0; i < l.Length; i++) { char ch = l[i]; if (ch == '"') { if (q && i + 1 < l.Length && l[i + 1] == '"') { sb.Append('"'); i++; } else q = !q; } else if (ch == ',' && !q) { f.Add(sb.ToString()); sb.Clear(); } else sb.Append(ch); }
        f.Add(sb.ToString());
        if (head == null) { head = f.ToArray(); continue; }
        if (f.Count != head.Length) throw new InvalidDataException(path + " column count mismatch");
        var d = new Dictionary<string, string>(); for (int i = 0; i < head.Length; i++) d[head[i]] = f[i]; rows.Add(d);
    }
    return rows;
}
var summaries = new JsonObject();
foreach (var (v, dir) in runs) summaries[v] = new JsonObject(Csv(Path.Combine(dir, "probe_output", "summary.csv")).Select(r => KeyValuePair.Create(r["key"], (JsonNode)JsonValue.Create(r["value"]))));
report["summaries"] = summaries;
report["ontick_vs_raw_rows"] = new JsonObject(runs.Keys.Select(v => KeyValuePair.Create(v, (JsonNode)JsonValue.Create(long.Parse((string)summaries[v]!["ontick_calls"]!) - rawN))));

// ---- A/B/D for QUOTE_D0 and ORDER_D0 (one OnTick per raw row expected)
JsonObject Semantics(string v)
{
    var q = Csv(Path.Combine(runs[v], "probe_output", "quotes.csv"));
    int aligned = 0, mis = 0, intervDiff = 0; var tab = new Dictionary<string, int>();
    foreach (var r in q)
    {
        long seq = long.Parse(r["ontick_seq"]); long fm = long.Parse(r["fresh_time_msc"]);
        if (seq < 1 || seq > rawN || ms[(int)seq] != fm) { mis++; continue; }
        aligned++; int i = (int)seq; double fb = double.Parse(r["fresh_bid"], inv), fa = double.Parse(r["fresh_ask"], inv);
        bool cur = Eq(fb, bid[i]) && Eq(fa, ask[i]), prev = i > 1 && Eq(fb, bid[i - 1]) && Eq(fa, ask[i - 1]);
        string cls = cur && prev ? "BOTH" : cur ? "CURRENT_ROW" : prev ? "PREV_ROW" : "NEITHER";
        string key = cls + "|raw_flags=" + flg[i] + "|tester_flags=" + r["fresh_flags"] + "|first_in_ms=" + (r["same_ms_index"] == "0" ? 1 : 0) + "|new_bar=" + r["new_bar"];
        tab[key] = tab.GetValueOrDefault(key) + 1;
        foreach (var part in r["interventions"].Split('|'))
        {
            var snap = part[(part.LastIndexOf('>') + 1)..].Split(':');
            if (snap.Length < 3 || snap[0] == "FAIL" || long.Parse(snap[0]) != fm || !Eq(double.Parse(snap[1], inv), fb) || !Eq(double.Parse(snap[2], inv), fa)) { intervDiff++; break; }
        }
    }
    var byCls = tab.GroupBy(p => p.Key.Split('|')[0]).ToDictionary(g => g.Key, g => g.Sum(p => p.Value));
    return new JsonObject
    {
        ["logged_rows"] = q.Count, ["aligned_seq_to_raw_index"] = aligned, ["misaligned"] = mis, ["rows_where_F1_F2_F3_differ_from_F0"] = intervDiff,
        ["price_class_totals"] = new JsonObject(byCls.Select(p => KeyValuePair.Create(p.Key, (JsonNode)JsonValue.Create(p.Value)))),
        ["cross_tab"] = new JsonObject(tab.OrderByDescending(p => p.Value).Select(p => KeyValuePair.Create(p.Key, (JsonNode)JsonValue.Create(p.Value))))
    };
}
report["A_B_D_quote_d0"] = Semantics("QUOTE_D0");
report["A_B_D_order_d0"] = Semantics("ORDER_D0");

// ---- A for ORDER_D250: offset progression by matching (ms, same_ms_index)
{
    var q = Csv(Path.Combine(runs["ORDER_D250"], "probe_output", "quotes.csv"));
    var firstIdx = new Dictionary<long, int>(); for (int i = rawN; i >= 1; i--) firstIdx[ms[i]] = i;
    var prog = new JsonArray(); long lastOff = long.MinValue; int unmatched = 0, cur = 0, prevRow = 0;
    foreach (var r in q)
    {
        long seq = long.Parse(r["ontick_seq"]), fm = long.Parse(r["fresh_time_msc"]); int k = int.Parse(r["same_ms_index"]);
        if (!firstIdx.TryGetValue(fm, out var i0)) { unmatched++; continue; }
        int i = i0 + k; if (i > rawN || ms[i] != fm) { unmatched++; continue; }
        long off = i - seq;
        if (off != lastOff) { prog.Add(new JsonObject { ["ontick_seq"] = seq, ["fresh_time_msc"] = fm, ["offset_raw_minus_seq"] = off }); lastOff = off; }
        double fb = double.Parse(r["fresh_bid"], inv), fa = double.Parse(r["fresh_ask"], inv);
        if (Eq(fb, bid[i]) && Eq(fa, ask[i])) cur++; else if (i > 1 && Eq(fb, bid[i - 1]) && Eq(fa, ask[i - 1])) prevRow++;
    }
    report["A_order_d250_offsets"] = new JsonObject { ["logged_rows"] = q.Count, ["unmatched_rows"] = unmatched, ["offset_changes"] = prog, ["price_current_row"] = cur, ["price_prev_row_only"] = prevRow, ["note"] = "same_ms_index-based matching assumes rows inside a millisecond are not skipped; offsets are descriptive" };
}

// ---- C: new-bar rows and the two fixed events (QUOTE_D0)
{
    var q = Csv(Path.Combine(runs["QUOTE_D0"], "probe_output", "quotes.csv"));
    var nb = q.Where(r => r["new_bar"] == "1").ToList();
    var nbStats = new Dictionary<string, int>();
    foreach (var r in nb)
    {
        int i = int.Parse(r["ontick_seq"]); double fb = double.Parse(r["fresh_bid"], inv), fa = double.Parse(r["fresh_ask"], inv);
        bool cur = Eq(fb, bid[i]) && Eq(fa, ask[i]), prev = Eq(fb, bid[i - 1]) && Eq(fa, ask[i - 1]);
        string k = (cur && prev ? "BOTH" : cur ? "CURRENT_ROW" : prev ? "PREV_ROW" : "NEITHER") + "|raw_flags=" + flg[i] + "|first_in_ms=" + (r["same_ms_index"] == "0" ? 1 : 0);
        nbStats[k] = nbStats.GetValueOrDefault(k) + 1;
    }
    JsonObject Event(long slotMs)
    {
        var first = q.First(r => long.Parse(r["fresh_time_msc"]) >= slotMs); long m = long.Parse(first["fresh_time_msc"]);
        var rawRows = new JsonArray(); for (int i = 1; i <= rawN; i++) if (ms[i] == m) rawRows.Add(new JsonObject { ["raw_index"] = i, ["file_line"] = line[i], ["flags"] = flg[i], ["bid"] = bid[i], ["ask"] = ask[i] });
        int p = q.IndexOf(first); var prevRaw = (int)long.Parse(first["ontick_seq"]) - 1;
        var ticks = new JsonArray(q.Where(r => long.Parse(r["fresh_time_msc"]) == m).Select(r => (JsonNode)new JsonObject { ["ontick_seq"] = long.Parse(r["ontick_seq"]), ["same_ms_index"] = int.Parse(r["same_ms_index"]), ["tester_flags"] = r["fresh_flags"], ["bid"] = r["fresh_bid"], ["ask"] = r["fresh_ask"], ["new_bar"] = r["new_bar"], ["tester_rows_in_ms"] = r["tester_rows_in_ms"], ["tester_flags_in_ms"] = r["tester_flags_in_ms"], ["tester_last_in_ms_bid"] = r["tester_last_in_ms_bid"], ["interventions"] = r["interventions"] }).ToArray());
        return new JsonObject { ["event_ms"] = m, ["raw_rows_in_ms"] = rawRows, ["raw_previous_row"] = new JsonObject { ["raw_index"] = prevRaw, ["ms"] = ms[prevRaw], ["flags"] = flg[prevRaw], ["bid"] = bid[prevRaw], ["ask"] = ask[prevRaw] }, ["tester_ontick_rows_in_ms"] = ticks };
    }
    report["C_new_bars"] = new JsonObject { ["count"] = nb.Count, ["classes"] = new JsonObject(nbStats.OrderByDescending(p => p.Value).Select(p => KeyValuePair.Create(p.Key, (JsonNode)JsonValue.Create(p.Value)))) };
    report["C_event_1120"] = Event(1785756000000L);
    report["C_event_1230"] = Event(1785760200000L);
}

// ---- E: orders (D0 and D250)
{
    var arr = new JsonArray();
    foreach (var v in new[] { "ORDER_D0", "ORDER_D250" })
        foreach (var o in Csv(Path.Combine(runs[v], "probe_output", "orders.csv")).Where(o => o["event"] is "ENTRY_SENT" or "EXIT_DONE"))
        {
            long pre = long.Parse(o["pre_request_time_msc"]), post = long.Parse(o["post_return_time_msc"]), deal = long.Parse(o["deal_time_msc"]);
            bool sellSide = o["event"] == "ENTRY_SENT"; double dp = double.Parse(o["deal_price"], inv);
            double postSide = double.Parse(sellSide ? o["post_return_bid"] : o["post_return_ask"], inv);
            int lastLe = -1, firstGe = -1, skipped = 0;
            for (int i = 1; i <= rawN; i++) { if (ms[i] <= deal) lastLe = i; if (firstGe < 0 && ms[i] >= deal) firstGe = i; if (ms[i] > pre && ms[i] <= post) skipped++; }
            double Side(int i) => sellSide ? bid[i] : ask[i];
            arr.Add(new JsonObject
            {
                ["run"] = v, ["event"] = o["event"], ["slot"] = o["slot"], ["pre_request_msc"] = pre, ["post_return_msc"] = post, ["deal_time_msc"] = deal,
                ["deal_minus_pre_ms"] = deal - pre, ["post_return_before_deal"] = post < deal, ["deal_price"] = dp, ["deal_equals_post_return_side_price"] = Eq(dp, postSide),
                ["raw_last_row_le_deal"] = lastLe < 0 ? null : new JsonObject { ["ms"] = ms[lastLe], ["line"] = line[lastLe], ["flags"] = flg[lastLe], ["side_price"] = Side(lastLe), ["equals_deal"] = Eq(Side(lastLe), dp) },
                ["raw_first_row_ge_deal"] = firstGe < 0 ? null : new JsonObject { ["ms"] = ms[firstGe], ["line"] = line[firstGe], ["flags"] = flg[firstGe], ["side_price"] = Side(firstGe), ["equals_deal"] = Eq(Side(firstGe), dp) },
                ["raw_rows_pre_lt_ms_le_post"] = skipped, ["risk_usd_incl_reserve"] = o["risk_usd_incl_reserve"], ["risk_limit_usd"] = o["risk_limit_usd"], ["position_id"] = o["position_id"], ["position_ticket"] = o["position_ticket"]
            });
        }
    report["E_orders"] = arr;
}

// ---- F: tester's own CopyTicksRange view vs raw (QUOTE_D0)
{
    var q = Csv(Path.Combine(runs["QUOTE_D0"], "probe_output", "quotes.csv"));
    var cnt = new Dictionary<long, int>(); var lastIdx = new Dictionary<long, int>();
    for (int i = 1; i <= rawN; i++) { cnt[ms[i]] = cnt.GetValueOrDefault(ms[i]) + 1; lastIdx[ms[i]] = i; }
    int countEq = 0, countNe = 0, lastEq = 0, lastNe = 0;
    foreach (var r in q)
    {
        long m = long.Parse(r["fresh_time_msc"]); int tn = int.Parse(r["tester_rows_in_ms"]);
        if (tn == cnt.GetValueOrDefault(m)) countEq++; else countNe++;
        if (tn > 0) { int li = lastIdx[m]; if (Eq(double.Parse(r["tester_last_in_ms_bid"], inv), bid[li]) && Eq(double.Parse(r["tester_last_in_ms_ask"], inv), ask[li])) lastEq++; else lastNe++; }
    }
    report["F_tester_copyticks_view"] = new JsonObject { ["rows_count_equal_raw"] = countEq, ["rows_count_differs"] = countNe, ["last_row_price_equal_raw"] = lastEq, ["last_row_price_differs"] = lastNe, ["note"] = "CopyTicksRange is an observer intervention executed after order logic; a count difference may reflect rows not yet disclosed at that OnTick" };
}
report["status"] = "VERIFY_COMPLETE_REVIEW_REQUIRED";
report["not_claimed"] = new JsonArray("causal mechanism proven", "B1 parity", "strategy result", "probe P/L as performance");
Save(); Console.WriteLine("VERIFY_COMPLETE"); return 0;

void Save() => File.WriteAllText(outPath, report.ToJsonString(new JsonSerializerOptions { WriteIndented = true }));
