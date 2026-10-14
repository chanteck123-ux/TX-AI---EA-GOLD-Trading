// C7R1 S1/S4 signal translation. No QuantConnect dependency, orders, or P/L replay.
// Source provenance and deliberate platform limits: C7Signals.README.md.
using System;
using System.Collections.Generic;
using System.Globalization;

namespace TradingBrain.C7
{
    public sealed class Bar
    {
        public long Time { get; set; }
        public double Open { get; set; }
        public double High { get; set; }
        public double Low { get; set; }
        public double Close { get; set; }
        public long TickVolume { get; set; }
        public Bar Clone() => (Bar)MemberwiseClone();
    }

    public sealed class Tick
    {
        public long TimeMsc { get; set; }
        public double Bid { get; set; }
        public double Ask { get; set; }
        public long VolumeIncrement { get; set; } = 1;
    }

    public sealed class Signal
    {
        // Native zero-based strategy IDs: S1=0, S4=3.
        public int StrategyId { get; internal set; }
        public int Direction { get; internal set; }
        public long Trigger { get; internal set; }
        public long Expires { get; internal set; }
        public double Reference { get; internal set; }
        public double Stop { get; internal set; }
        public double Atr { get; internal set; }
        public double Target { get; internal set; }
        public string Family { get; internal set; } = "";
        public string Detail { get; internal set; } = "";
        public bool ConsumeFamily { get; internal set; } = false;
        public int TimeframeSeconds { get; internal set; } = 300;
        public string Structure { get; internal set; } = "";
        public string Key { get; internal set; } = "";
        public string Path { get; internal set; } = "";
        public string GateDetail { get; internal set; } = "";
    }

    public sealed class Diagnostic
    {
        public long TimeMsc { get; internal set; }
        public int StrategyId { get; internal set; }
        public string Event { get; internal set; } = "";
        public string Key { get; internal set; } = "";
        public string Detail { get; internal set; } = "";
    }

    public sealed partial class EngineOptions
    {
        public bool CurrentProfiles { get; set; } = false; // Preserve legacy fixtures; I9 explicitly enables current profiles.
        public bool EnableS2 { get; set; } = false;
        public bool EnableS3 { get; set; } = false;
        public bool EnableS5 { get; set; } = false;
        public bool EnableS6 { get; set; } = false;
        public bool EnableScalping { get; set; } = false;
        public bool S2IndependentProgress { get; set; } = false;
        public bool EnableS1 { get; set; } = true;
        public bool EnableS4 { get; set; } = true;
        public bool GateOn { get; set; } = true;
        // CopyRates OHLC/tick-volume may differ from raw quote reconstruction.
        // When true, call PushClosedBar before OnTick at each disclosure time.
        public bool UseCanonicalBars { get; set; } = false;
        public string Symbol { get; set; } = "GOLD";
        public double TickSize { get; set; } = 0.01;
        public bool TimeMapConfirmed { get; set; } = true;
        public int ServerUtcMode { get; set; } = 2;
        public int ServerWinterOffsetHours { get; set; } = 2;
        public int ServerSummerOffsetHours { get; set; } = 3;
        public long TimeMapFrom { get; set; } = 1704067200L;
        public long TimeMapTo { get; set; } = 1798761600L;
        internal EngineOptions Clone() => (EngineOptions)MemberwiseClone();
    }

    public sealed partial class Engine
    {
        private readonly EngineOptions _options;
        private readonly Dictionary<int, Series> _series = new Dictionary<int, Series>
        {
            [300] = new Series(300), [900] = new Series(900), [3600] = new Series(3600), [14400] = new Series(14400), [86400] = new Series(86400)
        };
        private readonly Candidate[] _s1 = { new Candidate(), new Candidate() };
        private readonly HashSet<string> _consumed = new HashSet<string>(StringComparer.Ordinal);
        private readonly Dictionary<string, Signal> _known = new Dictionary<string, Signal>(StringComparer.Ordinal);
        private readonly Dictionary<string, bool> _decisions = new Dictionary<string, bool>(StringComparer.Ordinal);
        private readonly List<Signal> _newSignals = new List<Signal>();
        private readonly List<Tuple<int, Bar>> _pendingBars = new List<Tuple<int, Bar>>();
        private long _s1Clock15, _s1Clock5, _s4Clock5, _lastMsc = -1;
        private Tick _tick;
        public event Action<Diagnostic> Diagnosed;
        public long RawSignals { get; private set; }
        public long AllowedSignals { get; private set; }
        public long RejectedSignals { get; private set; }
        public long NotReadySignals { get; private set; }
        public long CandidateCancellations { get; private set; }

        private sealed class Candidate
        {
            public bool Active, Triggered;
            public int Direction;
            public long Born, Expires, SignalAt;
            public double High, Low, Atr;
            public string Key = "";
        }

        public Engine(EngineOptions options = null)
        {
            _options = (options ?? new EngineOptions()).Clone();
            if (!Finite(_options.TickSize) || _options.TickSize <= 0 || string.IsNullOrWhiteSpace(_options.Symbol))
                throw new ArgumentException("Positive TickSize and a symbol are required.");
        }

        // Load once, before the first tick. Dates are server-clock labels, not UTC.
        // First OnTick checks that every loaded bar is already closed at that tick.
        public void LoadHistory(int timeframeSeconds, IEnumerable<Bar> bars)
        {
            if (_lastMsc >= 0) throw new InvalidOperationException("History cannot change after live processing starts.");
            if (!_series.TryGetValue(timeframeSeconds, out var s)) throw new ArgumentException("Use 300, 900, 3600, or 14400 seconds.");
            if (s.Count != 0) throw new InvalidOperationException("History was already loaded for this timeframe.");
            if (bars == null) throw new ArgumentNullException(nameof(bars));
            foreach (var b in bars) s.AppendClosed(b);
        }

        // Stage, do not calculate, a native CopyRates closed bar. OnTick validates
        // disclosure against that arriving tick before any indicator is updated.
        // The adapter must provide each canonical bar exactly once, in time order
        // within its timeframe. Preloading future bars here is explicitly rejected.
        public void PushClosedBar(int timeframeSeconds, Bar bar)
        {
            if (!_options.UseCanonicalBars) throw new InvalidOperationException("Canonical bars are disabled.");
            if (!_series.ContainsKey(timeframeSeconds)) throw new ArgumentException("Use 300, 900, 3600, or 14400 seconds.");
            if (bar == null) throw new ArgumentNullException(nameof(bar));
            _pendingBars.Add(Tuple.Create(timeframeSeconds, bar.Clone()));
        }

        // The caller must deliver every observed quote in chronological order.
        // Gaps produce no synthetic candles. Histories are never replayed as setups.
        public IReadOnlyList<Signal> OnTick(Tick tick)
        {
            ValidateTick(tick);
            if (tick.TimeMsc < _lastMsc) throw new ArgumentException("Tick time moved backward.");
            bool first = _lastMsc < 0;
            if (first)
                foreach (var s in _series.Values)
                    if (s.Count > 0 && s.Last.Time + s.Seconds > tick.TimeMsc / 1000 / s.Seconds * s.Seconds)
                        throw new ArgumentException("Warmup includes an unclosed/future bar.");
            foreach (var pending in _pendingBars)
                if (pending.Item2.Time + pending.Item1 > tick.TimeMsc / 1000)
                    throw new ArgumentException("Canonical bar was disclosed before its close.");
            _tick = tick;
            _lastMsc = tick.TimeMsc;
            _newSignals.Clear();
            foreach (var pending in _pendingBars) _series[pending.Item1].AppendClosed(pending.Item2);
            _pendingBars.Clear();
            foreach (var s in _series.Values) if (s.Seconds < 14400 || _options.CurrentProfiles) s.Update(tick, _options.UseCanonicalBars);
            if (first)
            {
                if (_series[300].Count >= 2) _s1Clock5 = _s4Clock5 = _series[300].Current.Time;
                if (_series[900].Count >= 3) _s1Clock15 = _series[900].Current.Time;
                Note(-1, "WARMUP_NO_HISTORY_REPLAY", "", "first_tick_clocks_seeded");
            }
            if (_options.CurrentProfiles)
            {
                OnStrategy123Tick(); OnStrategy456Tick(); OnStrategyScalpingTick();
            }
            else { if (_options.EnableS1) Scan1(); if (_options.EnableS4) Scan4(); }
            return _newSignals.Count == 0 ? Array.Empty<Signal>() : _newSignals.ToArray();
        }

        // Check just before submission and again for delayed/retried submissions.
        // This is native Valid15, not the separate execution/risk/chase gateway.
        public bool IsValid(Signal s, Tick tick, out string reason)
        {
            reason = "SIGNAL_STRUCTURE_INVALID";
            ValidateTick(tick);
            if (_lastMsc != tick.TimeMsc) throw new InvalidOperationException("Call OnTick before IsValid for this tick.");
            long now = tick.TimeMsc / 1000;
            if (s == null || s.StrategyId < 0 || s.StrategyId > 6 || (!_options.CurrentProfiles && s.StrategyId != 0 && s.StrategyId != 3) || now < s.Trigger || now >= s.Expires)
            { reason = "SIGNAL_EXPIRED_OR_FUTURE"; return false; }
            if (Used(s.Structure)) { reason = "SETUP_CONSUMED"; return false; }
            if (s.Direction > 0 ? tick.Bid <= s.Stop : tick.Bid >= s.Stop)
            { reason = "STRUCTURE_SL_CROSSED"; return false; }
            if (_options.CurrentProfiles)
            {
                if (s.StrategyId <= 2) return ValidateStrategy123(s, out reason);
                if (s.StrategyId <= 5) return ValidateStrategy456(s, out reason);
                return ValidateStrategyScalping(s, out reason);
            }
            if (s.StrategyId == 0)
            {
                var c = _s1[s.Direction > 0 ? 0 : 1];
                if (!c.Active || c.Key != s.Structure || s.Trigger > c.Expires || Trend() != s.Direction) return false;
            }
            else if (!SessionOpen(now) || Momentum() != s.Direction) return false;
            reason = "VALID";
            return true;
        }

        // Mirrors native MarkUsed at durable request reservation (before OrderSend).
        // The execution adapter chooses the corresponding reservation point; a failed
        // reserved request must not silently reuse its structure. Do not consume just
        // because a signal exists. Either Signal.Key or its Structure is accepted.
        public void Consume(string key)
        {
            if (string.IsNullOrEmpty(key)) throw new ArgumentException("Missing setup key.");
            Signal known = null;
            if (_known.TryGetValue(key, out var signal)) known = signal;
            else foreach (var item in _known.Values) if (item.Structure == key) { known = item; break; }
            if (known == null) throw new ArgumentException("Unknown un-emitted setup key.");
            _consumed.Add(known.Structure);
            if (known.ConsumeFamily && !string.IsNullOrEmpty(known.Family)) _consumed.Add(known.Family);
            Note(known.StrategyId, "SETUP_CONSUMED", known.Structure, "execution_request_reserved");
        }

        public int ClosedBarCount(int timeframeSeconds) => _series[timeframeSeconds].Count;

        public Dictionary<string, double> IndicatorSnapshot(int timeframeSeconds, int shift = 1)
        {
            var s = _series[timeframeSeconds];
            int ix = s.Count - shift;
            if (shift < 1 || ix < 0) throw new ArgumentOutOfRangeException(nameof(shift));
            return new Dictionary<string, double>
            {
                ["EMA9"] = s.Ema9[ix], ["EMA20"] = s.Ema20[ix], ["EMA50"] = s.Ema50[ix],
                ["ATR14"] = s.Atr[ix], ["RSI14"] = s.Rsi[ix], ["StochK"] = s.K[ix],
                ["StochD"] = s.D[ix], ["VFI"] = s.Vfi[ix], ["VFISignal"] = s.VfiSignal[ix]
            };
        }

        private long Now => _tick.TimeMsc / 1000;
        private bool Used(string key) => _consumed.Contains(key);
        private double Buffer(double atr) => Math.Max(2 * _options.TickSize, 0.20 * atr);
        private void Note(int sid, string evt, string key, string detail)
        {
            if (Diagnosed != null) Diagnosed(new Diagnostic { TimeMsc = _tick?.TimeMsc ?? 0, StrategyId = sid, Event = evt, Key = key, Detail = detail });
        }
        private static string N(double value) => value.ToString("G17", CultureInfo.InvariantCulture);
        private static bool Finite(double x) => !double.IsNaN(x) && !double.IsInfinity(x) && x != double.MaxValue;
        private static void ValidateTick(Tick t)
        {
            if (t == null || t.TimeMsc <= 0 || !Finite(t.Bid) || !Finite(t.Ask) || t.Bid <= 0 || t.Ask < t.Bid || t.VolumeIncrement < 0)
                throw new ArgumentException("Invalid tick, bid/ask, time, or tick-volume increment.");
        }
        private bool Value(int tf, string kind, int period, int shift, out double value)
        {
            var s = _series[tf]; value = double.NaN;
            if (s.Current == null || shift < 1 || s.Count + 1 < period * 3 + shift + 5) return false;
            var values = kind == "ATR" ? s.Atr : period == 9 ? s.Ema9 : period == 20 ? s.Ema20 : s.Ema50;
            value = values[s.Count - shift];
            return Finite(value) && value > 0;
        }
        private bool NewBar(int tf, ref long clock, int needed)
        {
            var s = _series[tf];
            if (s.Current == null || s.Count + 1 < needed) return false;
            if (clock == 0) { clock = s.Current.Time; return false; }
            if (clock == s.Current.Time) return false;
            clock = s.Current.Time; return true;
        }
        private int Trend()
        {
            var s = _series[3600];
            if (s.Count < 4 || !Value(3600, "EMA", 20, 1, out var fast) || !Value(3600, "EMA", 50, 1, out var slow) || !Value(3600, "EMA", 20, 4, out var past)) return 0;
            var b = s.At(1);
            return fast > slow && b.Close > fast && fast > past ? 1 : fast < slow && b.Close < fast && fast < past ? -1 : 0;
        }
        private int Momentum()
        {
            if (!Value(900, "EMA", 9, 1, out var fast) || !Value(900, "EMA", 20, 1, out var slow) || !Value(900, "EMA", 9, 4, out var past)) return 0;
            return fast > slow && fast > past ? 1 : fast < slow && fast < past ? -1 : 0;
        }
        private void Cancel(Candidate c, string reason)
        {
            if (!c.Active) return;
            c.Active = false; CandidateCancellations++;
            Note(0, "CANDIDATE_CANCEL", c.Key, reason);
        }
        private static bool Confirm(Bar a, Bar previous, int direction) => direction > 0 ? a.Close > a.Open && a.Close > previous.High : a.Close < a.Open && a.Close < previous.Low;

        private void Scan1()
        {
            int trend = Trend();
            foreach (var c in _s1)
                if (c.Active)
                {
                    if (Used(c.Key)) Cancel(c, "SETUP_CONSUMED");
                    else if (Now >= c.Expires + 300) Cancel(c, "PULLBACK_EXPIRED");
                    else if (trend != c.Direction) Cancel(c, "H1_TREND_INVALID");
                    else if (c.Direction > 0 ? _tick.Bid <= c.Low - Buffer(c.Atr) : _tick.Bid >= c.High + Buffer(c.Atr)) Cancel(c, "STRUCTURE_SL_CROSSED");
                }
            if (Value(900, "EMA", 20, 1, out var ema) && Value(900, "ATR", 14, 2, out var atr) && NewBar(900, ref _s1Clock15, 4))
            {
                var b = _series[900].At(1);
                if (trend != 0 && b.Low <= ema + 0.25 * atr && b.High >= ema - 0.25 * atr && (trend > 0 ? b.Close > ema : b.Close < ema))
                {
                    var c = new Candidate { Active = true, Direction = trend, Born = b.Time + 900, Expires = b.Time + 3600, High = b.High, Low = b.Low, Atr = atr, Key = "S1_PB_" + b.Time + "_" + trend };
                    if (!Used(c.Key) && c.Expires > Now)
                    {
                        int ix = trend > 0 ? 0 : 1;
                        Cancel(_s1[ix], "REPLACED_BY_NEW_PULLBACK"); _s1[ix] = c;
                        Note(0, "PULLBACK_CONFIRMED", c.Key, "H1 trend and closed M15 pullback");
                    }
                }
            }
            if (Value(300, "ATR", 14, 2, out var a5) && NewBar(300, ref _s1Clock5, 3))
                foreach (var c in _s1)
                {
                    var b = _series[300].At(1); long trigger = b.Time + 300;
                    if (!c.Active || (c.Triggered && trigger < c.SignalAt + 300) || trigger <= c.Born || !Confirm(b, _series[300].At(2), c.Direction)) continue;
                    if (trigger > c.Expires || Now >= trigger + 300) continue;
                    c.Triggered = true; c.SignalAt = trigger;
                    Emit(new Signal { StrategyId = 0, Direction = c.Direction, Trigger = trigger, Expires = trigger + 300,
                        Reference = b.Close, Atr = a5, Stop = c.Direction > 0 ? Math.Min(c.Low, b.Low) - Buffer(c.Atr) : Math.Max(c.High, b.High) + Buffer(c.Atr),
                        Structure = c.Key, Path = "H1_M15_M5" });
                }
        }

        private void Scan4()
        {
            bool session = SessionOpen(Now);
            if (!Value(300, "ATR", 14, 2, out var atr) || !NewBar(300, ref _s4Clock5, 7)) return;
            var series = _series[300]; var b = series.At(1); long triggerTime = b.Time + 300;
            if (!session || !SessionOpen(triggerTime)) return;
            int direction = Momentum(); double range = b.High - b.Low;
            if (direction == 0 || range <= 0 || range > 2.50 * atr || Math.Abs(b.Close - b.Open) < 0.60 * atr) return;
            double hi = double.MinValue, lo = double.MaxValue;
            for (int j = 2; j <= 6; j++) { hi = Math.Max(hi, series.At(j).High); lo = Math.Min(lo, series.At(j).Low); }
            bool trigger = direction > 0 ? b.Close > b.Open && b.Close >= b.High - 0.25 * range && b.Close > hi : b.Close < b.Open && b.Close <= b.Low + 0.25 * range && b.Close < lo;
            if (!trigger) return;
            var signal = new Signal { StrategyId = 3, Direction = direction, Trigger = triggerTime, Expires = triggerTime + 300,
                Reference = b.Close, Atr = atr, Stop = direction > 0 ? b.Low - Buffer(atr) : b.High + Buffer(atr),
                Structure = "S4_MOMENTUM_" + b.Time + "_" + direction, Path = "LONDON_OR_NEWYORK" };
            if (!Used(signal.Structure) && Now < signal.Expires) Emit(signal);
        }

        private void Emit(Signal s, bool legacyGate = true)
        {
            if (s.Expires <= Now || Used(s.Structure)) return;
            s.Key = "S" + (s.StrategyId + 1) + "|" + _options.Symbol + "|" + s.Direction + "|" + s.Structure + "|" + s.Trigger;
            if (_decisions.ContainsKey(s.Key)) return; // FIRST_EMIT_IMMUTABLE, including unavailable/rejected snapshots.
            if (_decisions.Count >= 65536) throw new InvalidOperationException("C7_CACHE_CAPACITY");
            RawSignals++;
            bool ready = true, pass = true; string detail = "policy=ORIGINAL;why=GATE_OFF";
            if (_options.GateOn && legacyGate) pass = Gate(s, out ready, out detail);
            else if (!string.IsNullOrEmpty(s.GateDetail)) detail = s.GateDetail;
            bool allow = !_options.GateOn || ready && pass;
            _decisions.Add(s.Key, allow); s.GateDetail = detail;
            Note(s.StrategyId, "C7_SETUP", s.Key, "ready=" + ready + ";pass=" + pass + ";allow=" + allow + ";" + detail);
            if (!ready) NotReadySignals++;
            if (!allow) { RejectedSignals++; return; }
            AllowedSignals++; _known.Add(s.Key, s); _newSignals.Add(s);
            Note(s.StrategyId, "ARMED", s.Key, "trigger=" + s.Trigger + ";expires=" + s.Expires + ";ref=" + N(s.Reference) + ";sl=" + N(s.Stop) + ";atr=" + N(s.Atr));
        }

        private bool Gate(Signal s, out bool ready, out string detail)
        {
            ready = false; detail = "HISTORY_NOT_READY";
            var bars = _series[300]; int ix = bars.FindAtOrBefore(s.Trigger - 300);
            if (ix < 511 || bars.Current == null) return false;
            var source = bars.Bars[ix];
            long next = ix + 1 < bars.Count ? bars.Bars[ix + 1].Time : bars.Current.Time;
            if (source.Time <= 0 || source.Time + 300 > s.Trigger || next > s.Trigger || next <= source.Time || (s.StrategyId == 0 && next + 300 <= s.Trigger))
            { detail = "SOURCE_NOT_LATEST_CLOSED"; return false; }
            if (s.StrategyId == 0)
            {
                var k = new double[4]; var d = new double[4];
                for (int j = 0; j < 4; j++) { k[j] = bars.K[ix - j]; d[j] = bars.D[ix - j]; if (!ValidPercent(k[j]) || !ValidPercent(d[j])) { detail = "VALUE_NOT_READY"; return false; } }
                // A second rolling-window expression checks the translated Stoch buffer.
                // This is not claimed to be a native iRSI/CopyBuffer runtime check.
                var rsi = new double[21]; for (int j = 0; j < 21; j++) rsi[j] = bars.Rsi[ix - j];
                if (!StochReference(rsi, out var rk, out var rd)) { detail = "REFERENCE_NOT_READY"; return false; }
                for (int j = 0; j < 4; j++) if (Math.Abs(k[j] - rk[j]) > 1e-7 || Math.Abs(d[j] - rd[j]) > 1e-7) { detail = "REFERENCE_NUMERIC_MISMATCH"; return false; }
                ready = true; bool pass = StochPass(s.Direction, k, d, out int age);
                detail = "policy=S1_STOCH_RECOVERY_3_CLOSED_M5;source_bar=" + source.Time + ";cross_age=" + age;
                for (int j = 0; j < 4; j++) detail += ";k" + j + "=" + N(k[j]) + ";d" + j + "=" + N(d[j]);
                return pass;
            }
            double vfi = bars.Vfi[ix], ema = bars.VfiSignal[ix];
            if (!Finite(vfi) || !Finite(ema)) { detail = "BUFFER_OR_TIME_NOT_READY"; return false; }
            ready = true;
            detail = "policy=VFI_SIGNAL_DELTA;source_bar=" + source.Time + ";available_at=" + next + ";vfi=" + N(vfi) + ";signal=" + N(ema) + ";delta=" + N(vfi - ema) + ";volume_mode=TICK";
            return s.Direction * (vfi - ema) > 0;
        }

        public static bool StochPass(int direction, double[] k, double[] d, out int age)
        {
            age = -1;
            if ((direction != 1 && direction != -1) || k == null || d == null || k.Length < 4 || d.Length < 4) return false;
            for (int j = 0; j < 4; j++) if (!ValidPercent(k[j]) || !ValidPercent(d[j])) return false;
            if (direction * (k[0] - d[0]) <= 0) return false;
            for (int j = 0; j < 3; j++) if (direction * (k[j] - d[j]) > 0 && direction * (k[j + 1] - d[j + 1]) <= 0) { age = j; return true; }
            return false;
        }
        private static bool ValidPercent(double x) => Finite(x) && x >= 0 && x <= 100;
        public static bool StochReference(double[] rsi, out double[] k, out double[] d)
        {
            k = new double[4]; d = new double[4];
            if (rsi == null || rsi.Length < 21) return false;
            for (int j = 0; j < 21; j++) if (!ValidPercent(rsi[j])) return false;
            var raw = new double[8]; var sixK = new double[6];
            for (int j = 0; j < 8; j++)
            {
                double lo = rsi[j], hi = rsi[j];
                for (int q = 1; q < 14; q++) { lo = Math.Min(lo, rsi[j + q]); hi = Math.Max(hi, rsi[j + q]); }
                raw[j] = hi > lo ? Math.Max(0, Math.Min(100, 100 * (rsi[j] - lo) / (hi - lo))) : 0;
            }
            for (int j = 0; j < 6; j++) sixK[j] = (raw[j + 2] + raw[j + 1] + raw[j]) / 3;
            for (int j = 0; j < 4; j++) { k[j] = sixK[j]; d[j] = (sixK[j + 2] + sixK[j + 1] + sixK[j]) / 3; }
            return true;
        }

        public bool SessionOpen(long serverSeconds)
        {
            if (!TryServerUtc(serverSeconds, out long utc)) return false;
            var london = DateTimeOffset.FromUnixTimeSeconds(utc + (EuropeDst(utc) ? 3600 : 0));
            var ny = DateTimeOffset.FromUnixTimeSeconds(utc + (UsDst(utc) ? -4 : -5) * 3600);
            return IsWindow(london) || IsWindow(ny);
        }
        private static bool IsWindow(DateTimeOffset d) => d.DayOfWeek >= DayOfWeek.Monday && d.DayOfWeek <= DayOfWeek.Friday && d.Hour >= 8 && d.Hour < 11;
        public bool TryServerUtc(long server, out long utc)
        {
            utc = 0; var y = DateTimeOffset.FromUnixTimeSeconds(server).Year;
            if (!_options.TimeMapConfirmed || _options.ServerUtcMode < 1 || _options.ServerUtcMode > 3 || server < _options.TimeMapFrom || server > _options.TimeMapTo || y < 2007 || y > 2099 || Math.Abs(_options.ServerWinterOffsetHours) > 14 || Math.Abs(_options.ServerSummerOffsetHours) > 14) return false;
            long winter = server - _options.ServerWinterOffsetHours * 3600L;
            if (_options.ServerUtcMode == 1 || _options.ServerWinterOffsetHours == _options.ServerSummerOffsetHours) { utc = winter; return true; }
            long summer = server - _options.ServerSummerOffsetHours * 3600L;
            bool wd = _options.ServerUtcMode == 2 ? EuropeDst(winter) : UsDst(winter);
            bool sd = _options.ServerUtcMode == 2 ? EuropeDst(summer) : UsDst(summer);
            if ((!wd) == sd) return false;
            utc = !wd ? winter : summer; return true;
        }
        private static long Date(int year, int month, int day, int hour = 0) => new DateTimeOffset(year, month, day, hour, 0, 0, TimeSpan.Zero).ToUnixTimeSeconds();
        private static long LastSunday(int year, int month, int hour)
        {
            var last = new DateTimeOffset(year, month, DateTime.DaysInMonth(year, month), hour, 0, 0, TimeSpan.Zero);
            return last.AddDays(-(int)last.DayOfWeek).ToUnixTimeSeconds();
        }
        private static long NthSunday(int year, int month, int nth, int hour)
        {
            var first = new DateTimeOffset(year, month, 1, hour, 0, 0, TimeSpan.Zero);
            return first.AddDays((7 - (int)first.DayOfWeek) % 7 + 7 * (nth - 1)).ToUnixTimeSeconds();
        }
        private static bool EuropeDst(long utc) { int y = DateTimeOffset.FromUnixTimeSeconds(utc).Year; return utc >= LastSunday(y, 3, 1) && utc < LastSunday(y, 10, 1); }
        private static bool UsDst(long utc) { int y = DateTimeOffset.FromUnixTimeSeconds(utc).Year; return utc >= NthSunday(y, 3, 2, 7) && utc < NthSunday(y, 11, 1, 6); }

        // Append-only closed-bar indicators. No current-bar value enters a signal.
        private sealed class Series
        {
            public readonly int Seconds;
            public readonly List<Bar> Bars = new List<Bar>();
            public readonly List<double> Ema9 = new List<double>(), Ema20 = new List<double>(), Ema50 = new List<double>(), Atr = new List<double>(), Rsi = new List<double>(), K = new List<double>(), D = new List<double>(), Vfi = new List<double>(), VfiSignal = new List<double>();
            private readonly List<double> _tr = new List<double>(), _rawStoch = new List<double>(), _typical = new List<double>(), _log = new List<double>(), _volume = new List<double>(), _flow = new List<double>();
            private double _gain, _loss, _vfiEma = double.NaN;
            public Bar Current;
            public int Count => Bars.Count;
            public Bar Last => Bars[Bars.Count - 1];
            public Bar At(int shift) => shift == 0 ? Current : Bars[Bars.Count - shift];
            public Series(int seconds) { Seconds = seconds; }
            public void Update(Tick tick, bool canonical)
            {
                long time = tick.TimeMsc / 1000 / Seconds * Seconds;
                if (Current != null && time != Current.Time)
                {
                    if (!canonical) AppendClosed(Current);
                    else if (Count == 0 || Last.Time < Current.Time) throw new InvalidOperationException("CANONICAL_CLOSED_BAR_MISSING:" + Seconds + ":" + Current.Time);
                    Current = null;
                }
                if (Current == null) Current = new Bar { Time = time, Open = tick.Bid, High = tick.Bid, Low = tick.Bid, Close = tick.Bid, TickVolume = tick.VolumeIncrement };
                else { Current.High = Math.Max(Current.High, tick.Bid); Current.Low = Math.Min(Current.Low, tick.Bid); Current.Close = tick.Bid; Current.TickVolume += tick.VolumeIncrement; }
            }
            public void AppendClosed(Bar input)
            {
                if (input == null || input.Time <= 0 || input.Time % Seconds != 0 || !Finite(input.Open) || !Finite(input.High) || !Finite(input.Low) || !Finite(input.Close) || input.Low <= 0 || input.High < Math.Max(input.Open, input.Close) || input.Low > Math.Min(input.Open, input.Close) || input.TickVolume < 0 || (Count > 0 && input.Time <= Last.Time))
                    throw new ArgumentException("Invalid, unordered, or misaligned history bar.");
                Bar b = input.Clone(); int i = Count; double previous = i > 0 ? Last.Close : b.Close;
                Bars.Add(b);
                AddEma(Ema9, 9, b.Close); AddEma(Ema20, 20, b.Close); AddEma(Ema50, 50, b.Close);
                _tr.Add(i == 0 ? 0 : Math.Max(b.High, previous) - Math.Min(b.Low, previous));
                double atr = 0;
                if (i == 14) { for (int j = 1; j <= 14; j++) atr += _tr[j]; atr /= 14; }
                else if (i > 14) atr = Atr[i - 1] + (_tr[i] - _tr[i - 14]) / 14;
                Atr.Add(atr);
                double delta = b.Close - previous;
                if (i > 0 && i <= 14) { _gain += Math.Max(delta, 0); _loss += Math.Max(-delta, 0); if (i == 14) { _gain /= 14; _loss /= 14; } }
                else if (i > 14) { _gain = (_gain * 13 + Math.Max(delta, 0)) / 14; _loss = (_loss * 13 + Math.Max(-delta, 0)) / 14; }
                Rsi.Add(i < 14 ? double.NaN : _loss != 0 ? 100 - 100 / (1 + _gain / _loss) : _gain != 0 ? 100 : 50);
                double raw = double.NaN, k = double.NaN, d = double.NaN;
                if (i >= 27)
                {
                    double lo = Rsi[i], hi = lo;
                    for (int j = i - 13; j < i; j++) { lo = Math.Min(lo, Rsi[j]); hi = Math.Max(hi, Rsi[j]); }
                    raw = hi > lo ? Math.Max(0, Math.Min(100, 100 * (Rsi[i] - lo) / (hi - lo))) : 0;
                }
                _rawStoch.Add(raw);
                if (i >= 29) k = (_rawStoch[i - 2] + _rawStoch[i - 1] + _rawStoch[i]) / 3;
                K.Add(k);
                if (i >= 31) d = (K[i - 2] + K[i - 1] + K[i]) / 3;
                D.Add(d);
                AddVfi(b, i);
            }
            private static void AddEma(List<double> target, int period, double close)
            {
                double alpha = 2.0 / (period + 1);
                target.Add(target.Count == 0 ? close : close * alpha + target[target.Count - 1] * (1 - alpha));
            }
            private void AddVfi(Bar b, int i)
            {
                // Default VFI(130,0.2,2.5,EMA5,Smooth=false,TickVolume).
                double typical = (b.High + b.Low + b.Close) / 3;
                _typical.Add(typical); _volume.Add(b.TickVolume);
                _log.Add(i > 0 ? Math.Log(typical) - Math.Log(_typical[i - 1]) : double.NaN);
                double cutoff = double.NaN, prior = double.NaN, capped = double.NaN;
                if (i >= 30 && Sum(_log, i - 29, 30, out double logsum))
                {
                    double mean = logsum / 30, variance = 0;
                    for (int j = i - 29; j <= i; j++) { double d = _log[j] - mean; variance += d * d; }
                    cutoff = 0.2 * Math.Sqrt(variance / 30) * b.Close;
                }
                if (i >= 130 && Sum(_volume, i - 130, 130, out double volumeSum)) { prior = volumeSum / 130; capped = Math.Min(b.TickVolume, prior * 2.5); }
                double flow = double.NaN;
                if (i > 0 && Finite(cutoff) && Finite(capped)) { double movement = typical - _typical[i - 1]; flow = movement > cutoff ? capped : movement < -cutoff ? -capped : 0; }
                _flow.Add(flow);
                double vfi = double.NaN, signal = double.NaN;
                if (prior > 0 && i >= 129 && Sum(_flow, i - 129, 130, out double flowSum)) vfi = flowSum / prior;
                if (Finite(vfi)) { _vfiEma = Finite(_vfiEma) ? (2.0 / 6) * vfi + (1 - 2.0 / 6) * _vfiEma : vfi; signal = _vfiEma; }
                Vfi.Add(vfi); VfiSignal.Add(signal);
            }
            private static bool Sum(List<double> values, int from, int length, out double sum)
            {
                sum = 0; if (from < 0 || from + length > values.Count) return false;
                double correction = 0;
                for (int j = from; j < from + length; j++) { if (!Finite(values[j])) return false; double adjusted = values[j] - correction, next = sum + adjusted; correction = (next - sum) - adjusted; sum = next; }
                return Finite(sum);
            }
            public int FindAtOrBefore(long time)
            {
                int lo = 0, hi = Count - 1, found = -1;
                while (lo <= hi) { int mid = lo + (hi - lo) / 2; if (Bars[mid].Time <= time) { found = mid; lo = mid + 1; } else hi = mid - 1; }
                return found;
            }
        }

        // Pure semantic fixtures only: no artificial P/L or strategy performance.
        public static IReadOnlyList<string> RunSemanticSelfTests()
        {
            var passed = new List<string>();
            Action<bool, string> check = (ok, label) => { if (!ok) throw new InvalidOperationException("SEMANTIC_TEST_FAILED:" + label); passed.Add(label); };
            var r = new double[21]; for (int i = 0; i < r.Length; i++) r[i] = 50;
            check(StochReference(r, out var k, out var d) && k[0] == 0 && d[3] == 0, "flat_RSI_Stoch_is_zero");
            check(StochPass(1, new double[] { 60, 50, 40, 30 }, new double[] { 50, 50, 50, 50 }, out int age) && age == 0, "prior_equality_cross_allowed");
            check(!StochPass(1, new double[] { 50, 40, 30, 20 }, new double[] { 50, 50, 50, 50 }, out age), "current_equality_cross_rejected");
            check(StochPass(1, new double[] { 70, 60, 55, 50 }, new double[] { 50, 50, 50, 50 }, out age) && age == 2, "third_closed_cross_included");
            check(!StochPass(1, new double[] { 70, 60, 55, 51 }, new double[] { 50, 50, 50, 50 }, out age), "older_cross_rejected");
            check(!StochPass(-1, new double[] { double.NaN, 50, 60, 70 }, new double[] { 50, 50, 50, 50 }, out age), "missing_value_not_neutral");
            var series = new Series(300); long origin = Date(2026, 8, 3);
            for (int i = 0; i < 40; i++) series.AppendClosed(new Bar { Time = origin + i * 300, Open = 100, Close = 100, High = 100 + (i == 15 ? 15 : 1), Low = 99, TickVolume = 10 });
            check(Math.Abs(series.Atr[28] - 3) < 1e-12 && Math.Abs(series.Atr[29] - 2) < 1e-12, "ATR_shock_exits_after_14_bars_not_Wilder_decay");
            check(series.Rsi[39] == 50 && series.K[39] == 0 && series.D[39] == 0, "native_flat_RSI_50_and_Stoch_zero");
            var engine = new Engine(new EngineOptions { EnableS1 = false, EnableS4 = false });
            engine.LoadHistory(300, new[] { new Bar { Time = origin, Open = 100, High = 101, Low = 99, Close = 100, TickVolume = 5 } });
            check(engine.OnTick(new Tick { TimeMsc = (origin + 300) * 1000, Bid = 101, Ask = 101.1 }).Count == 0 && engine.RawSignals == 0, "warmup_no_signal_replay");
            engine.OnTick(new Tick { TimeMsc = (origin + 3600) * 1000, Bid = 102, Ask = 102.1 });
            check(engine.ClosedBarCount(300) == 2, "quote_gap_does_not_fill_forward_candles");
            bool threw = false; try { engine.LoadHistory(900, new Bar[0]); } catch (InvalidOperationException) { threw = true; }
            check(threw, "history_mutation_after_start_rejected");
            var future = new Engine(); future.LoadHistory(300, new[] { new Bar { Time = origin, Open = 100, High = 100, Low = 100, Close = 100 } });
            threw = false; try { future.OnTick(new Tick { TimeMsc = (origin + 100) * 1000, Bid = 100, Ask = 101 }); } catch (ArgumentException) { threw = true; }
            check(threw, "unclosed_warmup_bar_rejected");
            check(engine.SessionOpen(Date(2026, 8, 3, 10)), "London_0800_maps_to_server_1000_summer");
            check(!engine.SessionOpen(Date(2026, 8, 3, 13)), "London_1100_endpoint_excluded");
            check(!engine.TryServerUtc(Date(2026, 3, 29, 3) + 1800, out var ignored), "nonexistent_DST_server_hour_rejected");
            check(!engine.TryServerUtc(Date(2026, 10, 25, 3) + 1800, out ignored), "ambiguous_DST_server_hour_rejected");
            long start = Date(2026, 8, 3, 10);
            var lifecycle = new Engine(new EngineOptions { GateOn = false, EnableS4 = false });
            var warm5 = new List<Bar>(); var warm15 = new List<Bar>(); var warm60 = new List<Bar>();
            for (int j = 0; j < 600; j++) warm5.Add(new Bar { Time = start - (600 - j) * 300, Open = 100, High = 100.1, Low = 99.9, Close = 100, TickVolume = 10 });
            for (int j = 0; j < 200; j++)
            {
                warm15.Add(new Bar { Time = start - (200 - j) * 900, Open = 100, High = 100.2, Low = 99.8, Close = 100, TickVolume = 30 });
                double p = 90 + j * 0.05;
                warm60.Add(new Bar { Time = start - (200 - j) * 3600, Open = p, High = p + 0.2, Low = p - 0.2, Close = p, TickVolume = 120 });
            }
            lifecycle.LoadHistory(300, warm5); lifecycle.LoadHistory(900, warm15); lifecycle.LoadHistory(3600, warm60);
            Func<long, double, Tick> tickAt = (seconds, bid) => new Tick { TimeMsc = (start + seconds) * 1000, Bid = bid, Ask = bid + 0.02 };
            lifecycle.OnTick(tickAt(0, 100));
            lifecycle.OnTick(tickAt(899, 100.2));
            check(lifecycle.OnTick(tickAt(900, 100.2)).Count == 0, "S1_pullback_close_cannot_trigger_same_time");
            lifecycle.OnTick(tickAt(1199, 100.4));
            var firstSignal = lifecycle.OnTick(tickAt(1200, 100.4));
            check(firstSignal.Count == 1 && firstSignal[0].Trigger == start + 1200, "S1_later_closed_M5_confirmation_emits");
            check(lifecycle.IsValid(firstSignal[0], tickAt(1200, 100.4), out var why), "S1_pending_valid_without_consumption");
            lifecycle.OnTick(tickAt(1499, 100.6));
            var secondSignal = lifecycle.OnTick(tickAt(1500, 100.6));
            check(secondSignal.Count == 1 && firstSignal[0].Structure == secondSignal[0].Structure, "S1_unreserved_structure_gets_later_confirmation");
            check(!lifecycle.IsValid(firstSignal[0], tickAt(1500, 100.6), out why) && why == "SIGNAL_EXPIRED_OR_FUTURE", "signal_window_expiry_is_exclusive");
            lifecycle.Consume(secondSignal[0].Key);
            check(!lifecycle.IsValid(secondSignal[0], tickAt(1500, 100.6), out why) && why == "SETUP_CONSUMED", "execution_reservation_consumes_entire_structure");
            lifecycle.OnTick(tickAt(1501, 100.6));
            check(lifecycle.CandidateCancellations == 1, "consumption_cancels_candidate_on_next_tick");
            var canonical = new Engine(new EngineOptions { UseCanonicalBars = true, EnableS1 = false, EnableS4 = false });
            canonical.OnTick(tickAt(0, 100)); canonical.OnTick(tickAt(299, 101));
            canonical.PushClosedBar(300, new Bar { Time = start, Open = 100, High = 104, Low = 98, Close = 103, TickVolume = 7 });
            canonical.OnTick(tickAt(300, 101));
            check(canonical.ClosedBarCount(300) == 1 && canonical.IndicatorSnapshot(300)["EMA9"] == 103, "canonical_bar_uses_native_closed_price_not_raw_tick_close");
            check(canonical._series[300].At(1).TickVolume == 7, "canonical_volume_uses_native_tick_count");
            var early = new Engine(new EngineOptions { UseCanonicalBars = true });
            early.PushClosedBar(300, new Bar { Time = start, Open = 100, High = 100, Low = 100, Close = 100 });
            threw = false; try { early.OnTick(tickAt(299, 100)); } catch (ArgumentException) { threw = true; }
            check(threw && early.ClosedBarCount(300) == 0, "future_canonical_bar_rejected_before_calculation");
            var missing = new Engine(new EngineOptions { UseCanonicalBars = true, EnableS1 = false, EnableS4 = false });
            missing.OnTick(tickAt(0, 100));
            threw = false; try { missing.OnTick(tickAt(300, 100)); } catch (InvalidOperationException) { threw = true; }
            check(threw, "missing_canonical_bar_stops_instead_of_synthesizing");
            return passed;
        }
    }
}
