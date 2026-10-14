using System.Text.Json;
using TradingBrain.S4B4A;

// B4A quote-adapter fixtures on small synthetic raw CSVs (written under --work). Pure C#; no LEAN, no MT5.
var argMap = new Dictionary<string, string>();
for (int i = 0; i + 1 < args.Length; i += 2) argMap[args[i]] = args[i + 1];
string work = argMap.GetValueOrDefault("--work", Path.Combine(Path.GetTempPath(), "s4b4a_fixtures_" + Guid.NewGuid().ToString("N")));
Directory.CreateDirectory(work);
var passed = new List<string>(); var failed = new List<string>();
void Check(string name, bool ok, string detail = "") { if (ok) passed.Add(name); else failed.Add(name + (detail == "" ? "" : " :: " + detail)); }
bool Near(double a, double b) => Math.Abs(a - b) < 1e-9;
const string Header = "server_time_msc,bid,ask,last,volume,flags,volume_real";
long D3 = 1785715200000L, D4 = D3 + 86400000L;   // 2026-08-03 / 08-04 00:00 server labels

string Write(string name, params string[] rows) { var p = Path.Combine(work, name); File.WriteAllLines(p, new[] { Header }.Concat(rows)); return p; }
Dictionary<string, string> Hashes(params string[] names) => names.ToDictionary(n => n, n => RawFlagSidecar.Sha(Path.Combine(work, n)));
string R(long ms, double bid, double ask, int flags) => $"{ms},{bid:0.00},{ask:0.00},{bid:0.00},1,{flags},1.0";

// ---- 1. single-side updates, LAST-only, duplicate ms, unknown bits (one file)
{
    long t = D3 + 3600000;
    Write("ticks_20260803.csv",
        R(t, 100.00, 100.20, 1030),        // BID|ASK|1024 seed
        R(t + 10, 100.05, 100.25, 1026),   // BID only -> ask stays 100.20
        R(t + 20, 100.06, 100.30, 1028),   // ASK only -> bid stays 100.05
        R(t + 30, 101.00, 101.20, 280),    // LAST|VOLUME|256 -> no quote change
        R(t + 40, 101.00, 101.20, 280),    // duplicate ms below: first row LAST-only
        R(t + 40, 101.00, 101.20, 1030));  // same ms, quote row -> updates
    using var sc = new RawFlagSidecar(work, new[] { "ticks_20260803.csv" }, Hashes("ticks_20260803.csv"));
    var q = new QuoteFieldState();
    var r1 = sc.Next(t, 100.00, 100.20); var s1 = q.Apply(r1);
    Check("seed_row_ready", s1 == QuoteStatus.Ready && Near(q.Bid, 100.00) && Near(q.Ask, 100.20));
    q.Apply(sc.Next(t + 10, 100.05, 100.25));
    Check("bid_only_updates_bid_not_ask", Near(q.Bid, 100.05) && Near(q.Ask, 100.20), q.Bid + "/" + q.Ask);
    q.Apply(sc.Next(t + 20, 100.06, 100.30));
    Check("ask_only_updates_ask_not_bid", Near(q.Bid, 100.05) && Near(q.Ask, 100.30), q.Bid + "/" + q.Ask);
    q.Apply(sc.Next(t + 30, 101.00, 101.20));
    Check("last_only_row_does_not_overwrite_quote", Near(q.Bid, 100.05) && Near(q.Ask, 100.30) && q.NoQuoteBitRows == 1);
    var d1 = sc.Next(t + 40, 101.00, 101.20); q.Apply(d1);
    Check("duplicate_ms_first_row_last_only_keeps_previous", Near(q.Bid, 100.05) && Near(q.Ask, 100.30));
    var d2 = sc.Next(t + 40, 101.00, 101.20); q.Apply(d2);
    Check("duplicate_ms_second_row_quote_updates", Near(q.Bid, 101.00) && Near(q.Ask, 101.20));
    Check("duplicate_ms_order_and_consecutive_sequence", d1.Line == 6 && d2.Line == 7 && d2.Sequence == d1.Sequence + 1 && d1.Ms == d2.Ms);
    Check("unknown_bits_counted_not_interpreted", q.UnknownBits.GetValueOrDefault(1024) == 4 && q.UnknownBits.GetValueOrDefault(256) == 2 && q.UnknownBitRows == 6,
          string.Join(";", q.UnknownBits.Select(p => p.Key + "=" + p.Value)));
    Check("effective_differs_from_raw_counted", q.ReadyDifferFromRawRow == 4, q.ReadyDifferFromRawRow.ToString()); // rows 2,3,4,5
    Check("row_identity_ready_plus_notready", q.Rows == 6 && q.ReadyRows + q.NotReadyRows == q.Rows && q.NotReadyRows == 0);
}

// ---- 2. B3 11:20 case: LAST-only row at the new ms keeps 4057.82/4057.97, the same-ms quote row gives 4057.83/4057.98
{
    long t = 1785755999969L;
    Write("ticks_20260806.csv", R(t - 100, 4057.82, 4057.97, 1030), R(t, 4057.82, 4057.97, 280), R(1785756000070L, 4057.83, 4057.98, 280), R(1785756000070L, 4057.83, 4057.98, 1030));
    using var sc = new RawFlagSidecar(work, new[] { "ticks_20260806.csv" }, Hashes("ticks_20260806.csv"));
    var q = new QuoteFieldState();
    q.Apply(sc.Next(t - 100, 4057.82, 4057.97)); q.Apply(sc.Next(t, 4057.82, 4057.97));
    q.Apply(sc.Next(1785756000070L, 4057.83, 4057.98));
    Check("b3_1120_first_row_of_ms_uses_previous_quote", Near(q.Bid, 4057.82) && Near(q.Ask, 4057.97), q.Bid + "/" + q.Ask);
    q.Apply(sc.Next(1785756000070L, 4057.83, 4057.98));
    Check("b3_1120_second_row_of_ms_updates", Near(q.Bid, 4057.83) && Near(q.Ask, 4057.98));
}

// ---- 3. start without quote: not ready, never borrow a later row
{
    long t = D3 + 7200000;
    Write("ticks_20260807.csv", R(t, 200.00, 200.20, 280), R(t + 1, 200.01, 200.21, 1026), R(t + 2, 200.02, 200.22, 1028), R(t + 3, 200.03, 200.23, 280));
    using var sc = new RawFlagSidecar(work, new[] { "ticks_20260807.csv" }, Hashes("ticks_20260807.csv"));
    var q = new QuoteFieldState();
    var s1 = q.Apply(sc.Next(t, 200.00, 200.20));
    Check("first_row_without_quote_bits_not_ready", s1 == QuoteStatus.NotReadyNoSeed && q.Bid == 0 && q.Ask == 0);
    var s2 = q.Apply(sc.Next(t + 1, 200.01, 200.21));
    Check("bid_seed_only_still_not_ready", s2 == QuoteStatus.NotReadyNoSeed && Near(q.Bid, 200.01) && q.Ask == 0);
    var s3 = q.Apply(sc.Next(t + 2, 200.02, 200.22));
    Check("ready_after_both_sides_seeded_from_own_rows", s3 == QuoteStatus.Ready && Near(q.Bid, 200.01) && Near(q.Ask, 200.22));
    q.Apply(sc.Next(t + 3, 200.03, 200.23));
    Check("not_ready_counts_add_up", q.Rows == 4 && q.NotReadyRows == 2 && q.ReadyRows == 2);
}

// ---- 4. mismatches are hard failures
{
    long t = D3 + 10800000;
    Write("ticks_20260810.csv", R(t, 300.00, 300.20, 1030), R(t + 5, 300.10, 300.30, 1030));
    using var sc = new RawFlagSidecar(work, new[] { "ticks_20260810.csv" }, Hashes("ticks_20260810.csv"));
    bool priceRefused = false, timeRefused = false;
    try { sc.Next(t, 300.00, 300.21); } catch (InvalidDataException e) { priceRefused = e.Message.StartsWith("SIDECAR_MISMATCH"); }
    Check("price_mismatch_refused", priceRefused);
    using var sc2 = new RawFlagSidecar(work, new[] { "ticks_20260810.csv" }, Hashes("ticks_20260810.csv"));
    sc2.Next(t, 300.00, 300.20);
    try { sc2.Next(t + 6, 300.10, 300.30); } catch (InvalidDataException e) { timeRefused = e.Message.StartsWith("SIDECAR_MISMATCH"); }
    Check("time_mismatch_refused_no_skip_ahead", timeRefused);
    bool exhausted = false;
    using var sc3 = new RawFlagSidecar(work, new[] { "ticks_20260810.csv" }, Hashes("ticks_20260810.csv"));
    sc3.Next(t, 300.00, 300.20); sc3.Next(t + 5, 300.10, 300.30);
    try { sc3.Next(t + 9, 300.10, 300.30); } catch (InvalidDataException e) { exhausted = e.Message.StartsWith("RAW_EXHAUSTED"); }
    Check("extra_lean_tick_without_raw_row_refused", exhausted);
}

// ---- 5. cross-day files (incl. a header-only weekend file) consumed in real stream order; drain counts unmatched rows
{
    long late = D4 - 50, early = D4 + 3000;
    Write("ticks_20260811.csv", R(late - 10, 400.00, 400.20, 1030), R(late, 400.01, 400.21, 1030));
    Write("ticks_20260812.csv");                                             // header only
    Write("ticks_20260813.csv", R(early, 400.05, 400.25, 280), R(early + 10, 400.06, 400.26, 1030), R(early + 20, 400.07, 400.27, 1030));
    var names = new[] { "ticks_20260811.csv", "ticks_20260812.csv", "ticks_20260813.csv" };
    using var sc = new RawFlagSidecar(work, names, Hashes(names));
    var q = new QuoteFieldState();
    q.Apply(sc.Next(late - 10, 400.00, 400.20)); q.Apply(sc.Next(late, 400.01, 400.21));
    var x = sc.Next(early, 400.05, 400.25); q.Apply(x);
    Check("cross_day_continues_in_next_file_after_empty_file", x.File == "ticks_20260813.csv" && x.Line == 2 && x.Sequence == 3 && Near(q.Bid, 400.01));
    long unmatched = sc.DrainUnmatchedBefore(early + 15);
    Check("drain_counts_only_in_window_unmatched_rows", unmatched == 1, unmatched.ToString());
    Check("files_verified_with_row_counts", sc.FilesVerified.Count == 3 && sc.FilesVerified[0].rows == 2 && sc.FilesVerified[1].rows == 0 && sc.FilesVerified[2].rows == 3,
          string.Join(";", sc.FilesVerified.Select(f => f.file + "=" + f.rows)));
}

// ---- 5b. raw time regression and non-finite prices are hard failures
{
    long t = D3 + 14400000;
    Write("ticks_20260814.csv", R(t, 500.00, 500.20, 1030), R(t - 1, 500.01, 500.21, 1030));   // descending time
    using var sc = new RawFlagSidecar(work, new[] { "ticks_20260814.csv" }, Hashes("ticks_20260814.csv"));
    sc.Next(t, 500.00, 500.20);
    bool regression = false;
    try { sc.Next(t - 1, 500.01, 500.21); } catch (InvalidDataException e) { regression = e.Message.StartsWith("RAW_TIME_REGRESSION"); }
    Check("raw_time_regression_refused_even_if_lean_matches", regression);
    var p = Path.Combine(work, "ticks_20260817.csv");
    File.WriteAllLines(p, new[] { Header, $"{t},NaN,500.20,500.00,1,1030,1.0" });
    using var sc2 = new RawFlagSidecar(work, new[] { "ticks_20260817.csv" }, Hashes("ticks_20260817.csv"));
    bool nonFinite = false;
    try { sc2.Next(t, double.NaN, 500.20); } catch (InvalidDataException e) { nonFinite = e.Message.StartsWith("NON_FINITE_PRICE"); }
    Check("nan_raw_and_lean_price_refused_not_silently_equal", nonFinite);
    Write("ticks_20260818.csv", R(t, 500.00, 500.20, 1030));
    using var sc3 = new RawFlagSidecar(work, new[] { "ticks_20260818.csv" }, Hashes("ticks_20260818.csv"));
    bool leanNan = false;
    try { sc3.Next(t, 500.00, double.PositiveInfinity); } catch (InvalidDataException e) { leanNan = e.Message.StartsWith("NON_FINITE_PRICE"); }
    Check("non_finite_lean_price_refused", leanNan);
    Check("refused_rows_do_not_advance_past_current_row", sc3.RowsRead == 1);
}

// ---- 6. tampered raw file is refused before any row is read
{
    var h = Hashes("ticks_20260803.csv"); File.AppendAllText(Path.Combine(work, "ticks_20260803.csv"), "\n");
    bool refused = false;
    try { using var sc = new RawFlagSidecar(work, new[] { "ticks_20260803.csv" }, h); sc.Next(D3 + 3600000, 100.00, 100.20); } catch (InvalidDataException e) { refused = e.Message.Contains("hash differs"); }
    Check("tampered_raw_file_refused", refused);
}

var report = new { schema = "S4B4A_ADAPTER_FIXTURES_V1", status = failed.Count == 0 ? "PASS" : "FAIL", passed = passed.Count, failed, passed_names = passed, work, scope = "SYNTHETIC_CSV_ADAPTER_ONLY_NO_ENGINE" };
var json = JsonSerializer.Serialize(report, new JsonSerializerOptions { WriteIndented = true });
Console.WriteLine(json);
if (argMap.TryGetValue("--out", out var outPath)) File.WriteAllText(outPath, json);
return failed.Count == 0 ? 0 : 1;
