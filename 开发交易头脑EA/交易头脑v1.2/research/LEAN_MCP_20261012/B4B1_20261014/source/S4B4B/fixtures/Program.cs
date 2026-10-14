using System.Text.Json;
using TradingBrain.C7;
using TradingBrain.S4B4A;
using O = TradingBrain.S4;      // frozen original S4Core (ee509e1d)
using F = TradingBrain.S4B4B;   // B4B1 fork + tracker

// B4B1 fixtures: (1) fork with hook = null and with latency 0 is equivalent to the frozen original core;
// (2) deadline boundary cases through the SAME call order as the LEAN algorithm (tracker -> quote -> core).
var argMap = new Dictionary<string, string>();
for (int i = 0; i + 1 < args.Length; i += 2) argMap[args[i]] = args[i + 1];
var passed = new List<string>(); var failed = new List<string>();
void Check(string name, bool ok, string detail = "") { if (ok) passed.Add(name); else failed.Add(name + (detail == "" ? "" : " :: " + detail)); }
bool Near(double a, double b) => Math.Abs(a - b) < 1e-9;
const long Offset = 10800000L;
const long T0 = 1785750000000L;   // 2026-08-03 09:40:00.000 server
int seq = 0;
Signal Sig(int dir, long nowMs, double reference, double stop, double atr)
{
    seq++; long trig = nowMs / 1000;
    var s = new Signal { StrategyId = 3, Direction = dir, Trigger = trig, Expires = trig + 300, Reference = reference, Stop = stop, Atr = atr, Structure = "S4_FIXTURE_" + seq + "_" + dir, Path = "FIXTURE" };
    s.Key = "S4|GOLD|" + dir + "|" + s.Structure + "|" + trig; return s;
}

// ---------------------------------------------------------------- 1. equivalence: hook null (latency 250) and latency 0 (hook set)
{
    // effective quotes per row (ms, bid, ask) and signals at given row indices (factory so each core gets its own instance)
    var rows = new List<(long ms, double bid, double ask)>();
    long t = T0;
    void Add(double bid, int stepMs = 100) { rows.Add((t, bid, bid + 0.20)); t += stepMs; }
    for (int i = 0; i < 5; i++) Add(3299.80);               // seed
    int sig1 = rows.Count; Add(3299.80);                     // long signal row
    for (int i = 0; i < 3; i++) Add(3300.40);               // fill after 250 ms at moved price -> may trigger overrun
    for (int i = 0; i < 50; i++) Add(3299.80 + i * 0.12);   // rally to 3305.68 -> >= 1.25R from the actual fill -> BE
    int sig2 = rows.Count; Add(3305.60);                     // short signal (second slot)
    for (int i = 0; i < 10; i++) Add(3305.60 - i * 0.05);
    int sig3 = rows.Count; Add(3305.10);                     // third signal -> slot full
    for (int i = 0; i < 70; i++) Add(3305.10 - i * 0.10);   // falls -> exits
    for (int i = 0; i < 20; i++) Add(3299.00 + i * 0.02);
    Dictionary<int, Func<Signal>> sigs(double unused = 0) => new()
    {
        [sig1] = () => Sig(1, rows[sig1].ms, rows[sig1].ask, rows[sig1].ask - 2.0, 2.0),
        [sig2] = () => Sig(-1, rows[sig2].ms, rows[sig2].bid, rows[sig2].bid + 2.0, 2.0),
        [sig3] = () => Sig(1, rows[sig3].ms, rows[sig3].ask, rows[sig3].ask - 2.0, 2.0),
    };
    List<string> RunOriginal(long latency)
    {
        var tr = new TraceO(); var core = new O.S4Core(new O.S4Config { LatencyMs = latency }, new BrokerO(), tr);
        seq = 0; var map = sigs();
        for (int i = 0; i < rows.Count; i++) { var r = rows[i]; var s = map.TryGetValue(i, out var fct) ? new[] { fct() } : Array.Empty<Signal>(); core.Step(r.ms, r.ms - Offset, r.bid, r.ask, () => s, _ => null, _ => { }); }
        core.End(); tr.Lines.Add("BALANCE " + core.Balance.ToString("R")); return tr.Lines;
    }
    List<string> RunFork(long latency, bool hookSet)
    {
        var tr = new TraceF(); var core = new F.S4Core(new F.S4Config { LatencyMs = latency }, new BrokerF(), tr);
        if (hookSet) core.EntryQuoteAtDeadline = _ => throw new InvalidOperationException("hook must not be used at latency 0");
        seq = 0; var map = sigs();
        for (int i = 0; i < rows.Count; i++) { var r = rows[i]; var s = map.TryGetValue(i, out var fct) ? new[] { fct() } : Array.Empty<Signal>(); core.Step(r.ms, r.ms - Offset, r.bid, r.ask, () => s, _ => null, _ => { }); }
        core.End(); tr.Lines.Add("BALANCE " + core.Balance.ToString("R")); return tr.Lines;
    }
    var o250 = RunOriginal(250); var f250 = RunFork(250, false);
    Check("equivalence_hook_null_latency250_trace_identical", o250.SequenceEqual(f250), $"orig={o250.Count} fork={f250.Count} firstDiff={FirstDiff(o250, f250)}");
    Check("equivalence_scenario_nontrivial", o250.Count(l => l.Contains("ENTRY_FILLED")) >= 2 && new[] { "ENTRY_RISK_OVERRUN_REQUESTED", "PROTECTION_REQUESTED", "TP_TRIGGERED", "EXIT_FILLED" }.All(k => o250.Any(l => l.Contains("\"" + k + "\""))), string.Join(",", o250.Select(l => System.Text.RegularExpressions.Regex.Match(l, "\"event\":\"([A-Z_]+)\"").Groups[1].Value).Where(x => x != "").Distinct()));
    var o0 = RunOriginal(0); var f0 = RunFork(0, true);
    Check("equivalence_latency0_with_hook_set_trace_identical", o0.SequenceEqual(f0), $"firstDiff={FirstDiff(o0, f0)}");
}

// ---------------------------------------------------------------- 2. deadline boundary cases (tracker -> QuoteFieldState -> fork core)
(F.S4Core core, F.DeadlineQuoteTracker tr, TraceF trace, QuoteFieldState q) Drive(List<(long ms, double bid, double ask, int flags)> rows, int signalRow, int dir, double stopDistance, double atr, bool end = true)
{
    var trace = new TraceF(); var core = new F.S4Core(new F.S4Config { LatencyMs = 250 }, new BrokerF(), trace);
    var tr = new F.DeadlineQuoteTracker(); core.EntryQuoteAtDeadline = tr.Hook;
    var q = new QuoteFieldState(); long sq = 0;
    for (int i = 0; i < rows.Count; i++)
    {
        var x = rows[i]; var row = new RawRow { File = "synthetic", Line = i + 2, Sequence = ++sq, Ms = x.ms, Bid = x.bid, Ask = x.ask, Flags = x.flags };
        tr.BeforeApply(row, q, core.PendingEntryDeadlineMs);
        var st = q.Apply(row); tr.AfterApply(row);
        if (st == QuoteStatus.NotReadyNoSeed) continue;
        double bid = q.Bid, ask = q.Ask; if (bid <= 0 || ask < bid) continue;
        tr.BeforeStep(row, bid, ask);
        var s = i == signalRow ? new[] { dir > 0 ? Sig(1, x.ms, ask, ask - stopDistance, atr) : Sig(-1, x.ms, bid, bid + stopDistance, atr) } : Array.Empty<Signal>();
        core.Step(x.ms, x.ms - Offset, bid, ask, () => s, _ => null, _ => { });
    }
    if (end) core.End();
    return (core, tr, trace, q);
}
long Rq = T0 + 1000;   // request row ms in synthetic cases; deadline = Rq + 250
var seedRows = new List<(long, double, double, int)> { (T0, 3299.80, 3300.00, 1030), (T0 + 500, 3299.80, 3300.00, 1030) };
List<(long ms, double bid, double ask, int flags)> Case(params (long, double, double, int)[] tail) { var l = new List<(long, double, double, int)>(seedRows); l.AddRange(tail); return l.Select(z => ((long, double, double, int))z).ToList(); }

{   // 2a. no deadline-ms row: snapshot = last row before crossing; crossing row's own price not used
    var c = Case((Rq, 3299.80, 3300.00, 1030), (Rq + 100, 3299.90, 3300.10, 1030), (Rq + 200, 3300.00, 3300.20, 1030), (Rq + 300, 3300.30, 3300.50, 1030), (Rq + 400, 3300.30, 3300.50, 1030));
    var (core, tr, trace, _) = Drive(c, 2, 1, 2.0, 2.0);
    var e = tr.Entries.Single(); var b = core.Books.Single();
    Check("no_deadline_row_fill_at_last_row_before_crossing", Near(b.EntryPrice, 3300.20) && e.DeadlineRows == 0 && e.CrossingRowMs == Rq + 300 && e.QuoteRowMs == Rq + 200, $"{b.EntryPrice} {e.DeadlineRows}");
    Check("crossing_row_price_not_used_and_change_vs_b4a_rule_flagged", e.PriceChangedVsB4ARule && Near(e.B4ARulePrice ?? 0, 3300.50) && !e.StartRowChangedVsB4ARule);
    Check("submit_on_crossing_row_when_valid_lag_and_wait", e.SubmitRowMs == Rq + 300 && e.ExtraWaitRows == 0 && e.EngineLagMs == 50);
    Check("model_times_trace_written", trace.Lines.Any(l => l.Contains("ENTRY_MODEL_TIMES") && l.Contains("\"model_deadline_msc\":" + (Rq + 250))));
}
{   // 2b. deadline-ms row included (unverified assumption); submission moves to the next row -> start-row change flagged
    var c = Case((Rq, 3299.80, 3300.00, 1030), (Rq + 250, 3300.10, 3300.30, 1030), (Rq + 260, 3300.40, 3300.60, 1030), (Rq + 400, 3300.40, 3300.60, 1030));
    var (core, tr, _, _) = Drive(c, 2, 1, 2.0, 2.0);
    var e = tr.Entries.Single(); var b = core.Books.Single();
    Check("deadline_ms_row_included_in_snapshot", Near(b.EntryPrice, 3300.30) && e.DeadlineRows == 1 && e.QuoteRowMs == Rq + 250, b.EntryPrice.ToString());
    Check("deadline_row_moves_start_row_flagged_separately_from_price", e.StartRowChangedVsB4ARule && !e.PriceChangedVsB4ARule && e.B4ARuleRowMs == Rq + 250 && e.SubmitRowMs == Rq + 260);
}
{   // 2c. several same-ms rows at the deadline: all applied in raw order; ordinal recorded
    var c = Case((Rq, 3299.80, 3300.00, 1030), (Rq + 250, 3300.70, 3300.90, 280), (Rq + 250, 3300.20, 3300.40, 1028), (Rq + 300, 3300.20, 3300.40, 1030));
    var (core, tr, _, _) = Drive(c, 2, 1, 2.0, 2.0);
    var e = tr.Entries.Single(); var b = core.Books.Single();
    Check("same_ms_deadline_rows_all_applied_in_order", Near(b.EntryPrice, 3300.40) && e.DeadlineRows == 2 && e.QuoteRowOrdinalInMs == 1, $"{b.EntryPrice} rows={e.DeadlineRows} ord={e.QuoteRowOrdinalInMs}");
}
{   // 2d. crossing row is invalid (crossed effective quote) -> snapshot still at first crossing; submitted on next valid row
    var c = Case((Rq, 3299.80, 3300.00, 1030), (Rq + 100, 3299.90, 3300.10, 1030), (Rq + 300, 3300.50, 3300.50, 1026), (Rq + 300, 3300.50, 3300.30, 1026), (Rq + 400, 3300.50, 3300.70, 1028), (Rq + 500, 3300.50, 3300.70, 1030));
    // row Rq+300 #2: bid-only 3300.50 > ask 3300.10 -> crossed -> skipped (first row is also bid-only, crossed)
    var (core, tr, _, _) = Drive(c, 2, 1, 2.0, 2.0);
    var e = tr.Entries.Single(); var b = core.Books.Single();
    Check("invalid_crossing_row_snapshot_from_first_crossing", Near(b.EntryPrice, 3300.10) && e.CrossingRowMs == Rq + 300 && e.QuoteRowMs == Rq + 100, b.EntryPrice.ToString());
    Check("submitted_on_first_valid_ready_row_extra_wait_and_lag_disclosed", e.SubmitRowMs == Rq + 400 && e.ExtraWaitRows == 2 && e.EngineLagMs == 150, $"wait={e.ExtraWaitRows} lag={e.EngineLagMs}");
}
{   // 2e. deadline state itself crossed -> model reject, structure not reused
    var c = Case((Rq, 3299.80, 3300.00, 1030), (Rq + 200, 3300.60, 3300.60, 1026), (Rq + 300, 3300.60, 3300.90, 1028), (Rq + 400, 3300.60, 3300.90, 1030));
    var (core, tr, trace, _) = Drive(c, 2, 1, 2.0, 2.0);
    var b = core.Books.Single();
    Check("invalid_deadline_state_rejected", b.Rejected && !b.Open && core.Events.GetValueOrDefault("ENTRY_REJECT_INVALID_QUOTE_AT_DEADLINE") == 1 && tr.Entries.Single().SnapshotValid == false);
    Check("invalid_deadline_reject_traced", trace.Lines.Any(l => l.Contains("INVALID_QUOTE_AT_DEADLINE")));
}
{   // 2f. no row after the deadline before the end -> cancelled at End, hook never used
    var c = Case((Rq, 3299.80, 3300.00, 1030), (Rq + 100, 3299.90, 3300.10, 1030));
    var (core, tr, trace, _) = Drive(c, 2, 1, 2.0, 2.0);
    Check("no_post_deadline_row_cancelled_at_end", tr.Entries.Count == 0 && core.Books.Single().Rejected && trace.Lines.Any(l => l.Contains("REQUEST_CANCELLED_END_OF_SAMPLE")));
}
{   // 2g. B3 slot1 real rows (2026-08-03 12:30): request on .077 (flag 280), deadline .327; .378 is a flag-280 row
    var real = new List<(long, double, double, int)>
    {
        (1785760199976, 4052.69, 4052.84, 1030), (1785760200077, 4052.89, 4053.04, 280), (1785760200077, 4052.89, 4053.04, 1030),
        (1785760200177, 4052.87, 4053.02, 280), (1785760200177, 4052.87, 4053.02, 1030), (1785760200278, 4052.88, 4053.03, 280),
        (1785760200279, 4052.88, 4053.03, 1030), (1785760200378, 4052.87, 4053.02, 280), (1785760200378, 4052.87, 4053.02, 1030),
        (1785760200478, 4052.81, 4052.96, 280), (1785760200478, 4052.81, 4052.96, 1030)
    };
    var (core, tr, _, _) = Drive(real.Select(z => ((long, double, double, int))z).ToList(), 1, -1, 4.2, 3.46);
    var e = tr.Entries.Single(); var b = core.Books.Single();
    Check("b3_slot1_request_uses_previous_quote_on_280_row", Near(b.PlannedEntry, 4052.69), b.PlannedEntry.ToString());
    Check("b3_slot1_fill_equals_native_4052_88", Near(b.EntryPrice, 4052.88) && e.QuoteRowMs == 1785760200279 && e.DeadlineMs == 1785760200327, b.EntryPrice.ToString());
    Check("b3_slot1_b4a_rule_coincides_because_378_is_flag_280", !e.PriceChangedVsB4ARule && Near(e.B4ARulePrice ?? 0, 4052.88));
    var variant = real.Select(z => ((long, double, double, int))z).ToList(); variant[7] = (1785760200378, 4052.87, 4053.02, 1030);   // make .378 first row a quote row
    var (core2, tr2, _, _) = Drive(variant, 1, -1, 4.2, 3.46);
    Check("b3_slot1_variant_quote_row_after_deadline_b4b1_differs_from_b4a_rule", Near(core2.Books.Single().EntryPrice, 4052.88) && tr2.Entries.Single().PriceChangedVsB4ARule && Near(tr2.Entries.Single().B4ARulePrice ?? 0, 4052.87));
}
{   // 2h. deadline crossing a server-day boundary: pure ms ordering
    long dayEnd = 1785801600000L; long r0 = dayEnd - 100;
    var c = new List<(long, double, double, int)> { (r0 - 600, 3299.80, 3300.00, 1030), (r0 - 300, 3299.80, 3300.00, 1030), (r0, 3299.80, 3300.00, 1030), (dayEnd + 50, 3299.90, 3300.10, 1030), (dayEnd + 200, 3300.20, 3300.40, 1030), (dayEnd + 300, 3300.20, 3300.40, 1030) };
    var (core, tr, _, _) = Drive(c.Select(z => ((long, double, double, int))z).ToList(), 2, 1, 2.0, 2.0);
    var e = tr.Entries.Single();
    Check("cross_day_deadline_snapshot_and_submit", Near(core.Books.Single().EntryPrice, 3300.10) && e.DeadlineMs == r0 + 250 && e.CrossingRowMs == dayEnd + 200, $"{core.Books.Single().EntryPrice}");
}
{   // 2i. initial not-ready rows before the seed are never delivered; a request cannot exist before readiness
    var c = new List<(long, double, double, int)> { (T0, 3299.80, 3300.00, 280), (T0 + 10, 3299.80, 3300.00, 1026), (T0 + 20, 3299.80, 3300.00, 1028), (Rq, 3299.80, 3300.00, 1030), (Rq + 300, 3299.90, 3300.10, 1030) };
    var (core, tr, _, q) = Drive(c.Select(z => ((long, double, double, int))z).ToList(), 3, 1, 2.0, 2.0);
    Check("initial_not_ready_rows_counted_and_entry_after_seed", q.NotReadyRows == 2 && tr.Entries.Single().SnapshotValid && Near(core.Books.Single().EntryPrice, 3300.00), $"notReady={q.NotReadyRows}");
}

var report = new { schema = "S4B4B1_FIXTURES_V1", status = failed.Count == 0 ? "PASS" : "FAIL", passed = passed.Count, failed, passed_names = passed, scope = "PURE_CSHARP_FORK_EQUIVALENCE_AND_DEADLINE_BOUNDARIES_NO_ENGINE" };
var json = JsonSerializer.Serialize(report, new JsonSerializerOptions { WriteIndented = true });
Console.WriteLine(json);
if (argMap.TryGetValue("--out", out var outPath)) File.WriteAllText(outPath, json);
return failed.Count == 0 ? 0 : 1;

static string FirstDiff(List<string> a, List<string> b) { for (int i = 0; i < Math.Min(a.Count, b.Count); i++) if (a[i] != b[i]) return i + ": " + a[i] + " <> " + b[i]; return a.Count == b.Count ? "none" : "length"; }

sealed class TraceO : O.IS4Trace { public readonly List<string> Lines = new(); public void Write(string stream, object record) => Lines.Add(stream + " " + JsonSerializer.Serialize(record)); }
sealed class TraceF : F.IS4Trace { public readonly List<string> Lines = new(); public void Write(string stream, object record) => Lines.Add(stream + " " + JsonSerializer.Serialize(record)); }
sealed class BrokerO : O.IS4Broker
{
    long id = 1; readonly O.S4Config c = new();
    public O.S4Fill Execute(O.S4Book book, double lots, double price, string tag) => new O.S4Fill { Filled = true, SignedLots = Math.Round(lots, 2), Price = price, Fee = O.S4Math.Commission(c, lots), OrderId = id++, Status = "Filled" };
}
sealed class BrokerF : F.IS4Broker
{
    long id = 1; readonly F.S4Config c = new();
    public F.S4Fill Execute(F.S4Book book, double lots, double price, string tag) => new F.S4Fill { Filled = true, SignedLots = Math.Round(lots, 2), Price = price, Fee = F.S4Math.Commission(c, lots), OrderId = id++, Status = "Filled" };
}
