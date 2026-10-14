using System.Globalization;
using System.Text.Json;
using QuantConnect;
using QuantConnect.Algorithm;
using QuantConnect.Data;
using QuantConnect.Securities;
using C7 = TradingBrain.C7;

namespace TradingBrain.I9;

// Engineering decision replay only. No orders, profit, risk/exit or brokerage claims.
public class SevenSignalsAlgorithm : QCAlgorithm
{
    readonly Dictionary<int, Queue<C7.Bar>> pending = new();
    readonly Dictionary<string, C7.Engine> engines = new();
    readonly Dictionary<string, long> counts = new(), diagnostics = new();
    readonly HashSet<string> diagnosticKeys = new(StringComparer.Ordinal);
    Symbol gold;
    string output;
    StreamWriter signals, trace, snapshots;
    long ticks, firstTime, lastTime, endServerExclusive, snapshotClock = -1;
    const long StartServer = 1785542400L;
    static readonly JsonSerializerOptions JsonOptions = new() { WriteIndented = true };
    static double Number(string x) => double.Parse(x, CultureInfo.InvariantCulture);
    public override void Initialize()
    {
        if (LiveMode) throw new InvalidOperationException("I9 is local backtest engineering only.");
        output = GetParameter("output-dir");
        var raw = GetParameter("raw-dir");
        var daily = GetParameter("daily-file");
        var end = DateTime.ParseExact(GetParameter("end-date"), "yyyy-MM-dd", CultureInfo.InvariantCulture);
        if (end < new DateTime(2026, 8, 3) || end > new DateTime(2026, 8, 31)) throw new ArgumentException("August development only.");
        endServerExclusive = new DateTimeOffset(DateTime.SpecifyKind(end.AddDays(1), DateTimeKind.Utc)).ToUnixTimeMilliseconds();
        Directory.CreateDirectory(output);
        signals = new(Path.Combine(output, "signals.jsonl"));
        trace = new(Path.Combine(output, "diagnostics_first_occurrence.jsonl"));
        snapshots = new(Path.Combine(output, "closed_snapshots.jsonl"));
        SetTimeZone(TimeZones.Utc); SetStartDate(2026, 8, 1); SetEndDate(end); SetCash(500m); SetBenchmark(_ => 500m);
        Market.Add("fxpro", 180);
        MarketHoursDatabase.SetEntry("fxpro", "GOLD", SecurityType.Cfd, SecurityExchangeHours.AlwaysOpen(TimeZones.Utc), TimeZones.Utc);
        SymbolPropertiesDatabase.SetEntry("fxpro", "GOLD", SecurityType.Cfd, new SymbolProperties("I9 frozen MT5 quote replay; no orders", "USD", 100m, .01m, .01m, "GOLD", .01m));
        gold = AddCfd("GOLD", Resolution.Tick, "fxpro", fillForward: false, leverage: 1000m).Symbol;
        Settings.AutomaticIndicatorWarmUp = false;
        engines["RETAINED_AND_USER_SCALP"] = new(new C7.EngineOptions { CurrentProfiles = true, UseCanonicalBars = true, EnableS1 = true, EnableS2 = true, EnableS3 = true, EnableS4 = true, EnableS5 = true, EnableS6 = true, EnableScalping = true });
        engines["S2_INDEPENDENT_PROGRESS"] = new(new C7.EngineOptions { CurrentProfiles = true, UseCanonicalBars = true, EnableS1 = false, EnableS4 = false, EnableS2 = true, S2IndependentProgress = true });
        foreach (var pair in engines)
        {
            var profile = pair.Key;
            pair.Value.Diagnosed += d => {
                var counter = profile + "/" + d.StrategyId + "/" + d.Event;
                diagnostics[counter] = diagnostics.GetValueOrDefault(counter) + 1;
                if (diagnosticKeys.Add(counter + "/" + d.Key)) trace.WriteLine(JsonSerializer.Serialize(new { profile, diagnostic = d }));
            };
        }
        foreach (var pair in new[] { (300, "M5"), (900, "M15"), (3600, "H1"), (14400, "H4"), (86400, "D1") })
        {
            var history = new List<C7.Bar>(); pending[pair.Item1] = new();
            var file = pair.Item1 == 86400 ? daily : Path.Combine(raw, "bars_" + pair.Item2 + ".csv");
            foreach (var line in File.ReadLines(file).Skip(1))
            {
                var v = line.Split(',');
                var b = new C7.Bar { Time = long.Parse(v[0], CultureInfo.InvariantCulture), Open = Number(v[1]), High = Number(v[2]), Low = Number(v[3]), Close = Number(v[4]), TickVolume = long.Parse(v[5], CultureInfo.InvariantCulture) };
                if (b.Time + pair.Item1 <= StartServer) history.Add(b); else pending[pair.Item1].Enqueue(b);
            }
            foreach (var e in engines.Values) e.LoadHistory(pair.Item1, history);
        }
    }
    public override void OnData(Slice slice)
    {
        if (!slice.Ticks.TryGetValue(gold, out var input)) return;
        foreach (var t in input)
        {
            long utc = new DateTimeOffset(DateTime.SpecifyKind(t.Time, DateTimeKind.Utc)).ToUnixTimeMilliseconds(), server = utc + 10800000L;
            if (server < StartServer * 1000 || server >= endServerExclusive) continue;
            if (server < lastTime) throw new InvalidOperationException("Regressing quote.");
            if (firstTime == 0) firstTime = server;
            lastTime = server; ticks++;
            foreach (var (tf, queue) in pending)
                while (queue.Count > 0 && queue.Peek().Time + tf <= server / 1000)
                {
                    var bar = queue.Dequeue(); foreach (var e in engines.Values) e.PushClosedBar(tf, bar);
                }
            var tick = new C7.Tick { TimeMsc = server, Bid = (double)t.BidPrice, Ask = (double)t.AskPrice, VolumeIncrement = 0 };
            foreach (var (profile, engine) in engines)
                foreach (var s in engine.OnTick(tick))
                {
                    var key = profile + "/" + (s.StrategyId + 1);
                    counts[key] = counts.GetValueOrDefault(key) + 1;
                    var valid = engine.IsValid(s, tick, out var reason);
                    signals.WriteLine(JsonSerializer.Serialize(new { profile, observed_server_msc = server, tick_index = ticks, bid = tick.Bid, ask = tick.Ask, valid_at_emission = valid, validity_reason = reason, signal = s }));
                }
            if (server / 300000 != snapshotClock)
            {
                snapshotClock = server / 300000;
                var e = engines["RETAINED_AND_USER_SCALP"];
                foreach (var tf in pending.Keys)
                    if (e.ClosedBarCount(tf) > 0)
                        snapshots.WriteLine(JsonSerializer.Serialize(new { observed_server_msc = server, tf, closed_count = e.ClosedBarCount(tf), indicators = e.IndicatorSnapshot(tf).ToDictionary(p => p.Key, p => double.IsFinite(p.Value) ? (double?)p.Value : null) }));
            }
        }
    }
    public override void OnEndOfAlgorithm()
    {
        signals?.Dispose(); trace?.Dispose(); snapshots?.Dispose();
        File.WriteAllText(Path.Combine(output, "RESULT.json"), JsonSerializer.Serialize(new {
            schema = "I9_SEVEN_DECISION_ENGINEERING_REPLAY_V1", status = "SIGNAL_REPLAY_FINISHED_REQUIRES_COMPARISON",
            ticks, first_server_msc = firstTime, last_server_msc = lastTime, end_server_exclusive_msc = endServerExclusive,
            signal_counts = counts, diagnostic_counts = diagnostics, orders_submitted = Transactions.GetOrders().Count(),
            economic_result = "N/A_NO_ORDERS_NO_RISK_EXIT_MODEL", data_role = "ALREADY_USED_DEVELOPMENT",
            consumed_setups = 0, consumption_policy = "RAW_SIGNAL_SPACE_NOT_EXECUTION_EQUIVALENT", daily_data = "NATIVE_COPYRATES_EXTENDED_WARMUP_OVERLAP_VERIFIED",
            strategies = new[] { "S1", "S2", "S3", "S4", "S5", "S6", "Scalping" }
        }, JsonOptions));
    }
}
