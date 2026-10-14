// I9 research translation: current S4 BE125, S5 I8 request-finality, S6 I6 distinct trigger.
// Signal/indicator semantics only. Native execution, risk, BE/progress exits and costs remain separate.
using System;
using System.Collections.Generic;

namespace TradingBrain.C7
{
    public sealed partial class Engine
    {
        private bool _456Started, _s5Seed;
        private long _s5Clock, _s6H4Clock, _s6M15Clock, _s6M5Clock;
        private readonly bool[] _s5Armed = new bool[2];
        private readonly Signal[] _s5Active = new Signal[2];
        private readonly HashSet<string> _456InvalidTactical = new HashSet<string>(StringComparer.Ordinal);
        private readonly List<Signal> _456TacticalActive = new List<Signal>();
        private readonly List<double> _s5Adx = new List<double>();
        private double _s5DiPlus, _s5DiMinus;
        private readonly List<Pattern456> _s6Patterns = new List<Pattern456>();
        private readonly Dictionary<string, List<Family456>> _s6Families = new Dictionary<string, List<Family456>>(StringComparer.Ordinal);
        private readonly Dictionary<int, Smc456> _s6Smc = new Dictionary<int, Smc456>();
        private Signal _s6H4Active;
        private sealed class Pattern456
        {
            public bool Active = true;
            public int Direction, Tf, Sources;
            public long First, Second, NeckAt, Available, Breakout, LastTrigger;
            public double P1, P2, Neck, FrozenAtr, ProtectAtr, Stop;
            public string Id = "", Family = "";
        }
        private sealed class Family456 { public double Neck; public int Sources; }
        private sealed class Pivot456 { public bool Valid, Broken; public double Price; }
        private sealed class Smc456
        {
            public int Next, InternalLeg, SwingLeg, Bias;
            public readonly Pivot456 IH = new Pivot456(), IL = new Pivot456(), SH = new Pivot456(), SL = new Pivot456();
            public readonly List<double> Biases = new List<double>(), Events = new List<double>();
        }

        private void OnStrategy456Tick()
        {
            // Always observe tactical invalidation before any missing-indicator/data return.
            for (int j = _456TacticalActive.Count - 1; j >= 0; j--)
            {
                var s = _456TacticalActive[j];
                if (Now >= s.Expires || Used(s.Structure)) { _456TacticalActive.RemoveAt(j); continue; }
                if (Now >= s.Trigger && Stop456(s)) _456InvalidTactical.Add(s.Key);
            }
            if (!_456Started)
            {
                _s5Clock = _series[300].Current.Time;
                _s6M5Clock = _series[300].Current.Time;
                _s6M15Clock = _series[900].Current.Time;
                _s6H4Clock = _series[14400].Current.Time;
                _456Started = true;
            }
            if (_options.EnableS4) Scan4(); // Current source retains this exact strong-bar + VFI signal.
            if (_options.EnableS5) Scan5Current456();
            if (_options.EnableS6) Scan6Current456();
        }

        private double Round456(double price, int direction)
        {
            double n = price / _options.TickSize;
            return (direction > 0 ? Math.Ceiling(n - 1e-9) : Math.Floor(n + 1e-9)) * _options.TickSize;
        }
        private bool Stop456(Signal s) => s.Direction > 0 ? _tick.Bid <= Round456(s.Stop, -1) : _tick.Ask >= Round456(s.Stop, 1);
        private bool BackgroundStop456(int dir, double stop) => dir > 0 ? _tick.Bid <= stop : _tick.Ask >= stop;
        private static string Tf456(int tf) => tf == 300 ? "PERIOD_M5" : tf == 900 ? "PERIOD_M15" : "PERIOD_H4";
        private bool BarsReady456(int tf, int closed) => _series[tf].Current != null && _series[tf].Count >= closed;

        // MT5 iADX(14), not iADXW: EMA of per-bar directional percentages, then EMA of DX.
        // Matches terminal Indicators/Examples/ADX.mq5. i=0 seeded to zero.
        private void UpdateAdx456()
        {
            var s = _series[900];
            for (int i = _s5Adx.Count; i < s.Count; i++)
            {
                if (i == 0) { _s5Adx.Add(0); continue; }
                var b = s.Bars[i]; var p = s.Bars[i - 1];
                double up = Math.Max(0, b.High - p.High), down = Math.Max(0, p.Low - b.Low);
                if (up > down) down = 0; else if (up < down) up = 0; else up = down = 0;
                double tr = Math.Max(b.High - b.Low, Math.Max(Math.Abs(b.High - p.Close), Math.Abs(b.Low - p.Close)));
                double alpha = 2.0 / 15;
                _s5DiPlus = (tr > 0 ? 100 * up / tr : 0) * alpha + (1 - alpha) * _s5DiPlus;
                _s5DiMinus = (tr > 0 ? 100 * down / tr : 0) * alpha + (1 - alpha) * _s5DiMinus;
                double dx = _s5DiPlus + _s5DiMinus > 0 ? 100 * Math.Abs((_s5DiPlus - _s5DiMinus) / (_s5DiPlus + _s5DiMinus)) : 0;
                _s5Adx.Add(dx * alpha + (1 - alpha) * _s5Adx[i - 1]);
            }
        }
        private bool Range5Current456()
        {
            UpdateAdx456();
            if (!Value(900, "EMA", 20, 1, out var ema) || !Value(900, "EMA", 20, 4, out var past) ||
                !Value(900, "ATR", 14, 1, out var atr) || _s5Adx.Count < 49) return false;
            return _s5Adx[_s5Adx.Count - 1] < 20 && Math.Abs(ema - past) <= .25 * atr;
        }
        private static bool Bands456(Series s, int shift, out double lower, out double upper, out double mid)
        {
            lower = upper = mid = double.NaN;
            int at = s.Count - shift;
            if (shift < 1 || at < 19) return false;
            mid = 0;
            for (int j = at - 19; j <= at; j++) mid += s.Bars[j].Close;
            mid /= 20;
            double variance = 0;
            for (int j = at - 19; j <= at; j++) { double d = s.Bars[j].Close - mid; variance += d * d; }
            double std = Math.Sqrt(variance / 20);
            lower = mid - 2 * std; upper = mid + 2 * std;
            return Finite(lower) && lower > 0 && lower <= mid && mid <= upper;
        }
        private bool BandsReady5Current456(out double lower, out double upper, out double mid)
        {
            lower = upper = mid = double.NaN;
            var s = _series[300];
            if (s.Count < 513 || s.Current.Time != s.Last.Time + 300 || s.Current.Time > Now) return false;
            if (!Bands456(s, 2, out lower, out upper, out _) || !Bands456(s, 1, out _, out _, out mid)) return false;
            return true;
        }
        private void Scan5Current456()
        {
            var bars = _series[300];
            if (!_s5Seed)
            {
                if (BandsReady5Current456(out var lo, out var hi, out _))
                {
                    _s5Armed[0] = bars.Last.Low > lo; _s5Armed[1] = bars.Last.High < hi;
                    _s5Clock = bars.Current.Time; _s5Seed = true;
                    Note(4, "M5_BAND_REARM_HISTORY_RECONSTRUCTED", "", "no_historical_signal_replay");
                }
                return;
            }
            bool range = Range5Current456();
            for (int i = 0; i < 2; i++)
                if (_s5Active[i] != null && (Used(_s5Active[i].Structure) || !range || Now >= _s5Active[i].Expires || Stop456(_s5Active[i])))
                    _s5Active[i] = null;
            if (!NewBar(300, ref _s5Clock, 4)) return;
            long trigger = bars.Last.Time + 300;
            if (!BandsReady5Current456(out var lower, out var upper, out var mid) || !Value(300, "ATR", 14, 1, out var atr))
            { Note(4, "M5_BAND_DATA_NOT_READY", trigger.ToString(), "closed_bars_required"); return; }
            var b = bars.Last;
            Note(4, "S5_M5_BAND_READ", trigger.ToString(), "bb_lower_prior=" + N(lower) + ";bb_upper_prior=" + N(upper) + ";bb_mid_closed=" + N(mid) + ";adx=" + N(_s5Adx[_s5Adx.Count - 1]));
            for (int i = 0; i < 2; i++)
            {
                int dir = i == 0 ? 1 : -1;
                bool armed = _s5Armed[i], touch = dir > 0 ? b.Low <= lower : b.High >= upper;
                if (!touch) { _s5Armed[i] = true; continue; }
                _s5Armed[i] = false;
                bool recovery = b.Close > lower && b.Close < upper;
                Note(4, "S5_M5_TOUCH_CHECK", b.Time + "_" + dir, "armed=" + armed + ";range=" + range + ";recovery=" + recovery);
                if (!armed || !range || !recovery) continue;
                double r0 = bars.Rsi[bars.Count - 1], r1 = bars.Rsi[bars.Count - 2], r2 = bars.Rsi[bars.Count - 3];
                bool turn = ValidPercent(r0) && ValidPercent(r1) && ValidPercent(r2) &&
                    (dir > 0 ? r0 > r1 && r1 <= r2 : r0 < r1 && r1 >= r2);
                string structure = "S5_BAND_" + b.Time + "_" + dir;
                _s5Active[i] = null; // A new qualified touch replaces the prior candidate even when RSI fails.
                Note(4, "S5_RSI_TURN_CHECK", structure, "rsi0=" + N(r0) + ";rsi1=" + N(r1) + ";rsi2=" + N(r2) + ";turn=" + turn);
                if (!turn || dir * (b.Close - b.Open) <= 0 || Used(structure) || Now >= trigger + 300) continue;
                double entry = dir > 0 ? _tick.Ask : _tick.Bid;
                if (dir * (mid - entry) <= 0) continue;
                var signal = new Signal { StrategyId = 4, Direction = dir, TimeframeSeconds = 300, Trigger = trigger, Expires = trigger + 300,
                    Reference = b.Close, Atr = atr, Stop = dir > 0 ? b.Low - Buffer(atr) : b.High + Buffer(atr), Target = mid,
                    Structure = structure, Path = "M15_RANGE_M5_BAND_RSI_RECOVERY",
                    Detail = "sl_policy=M5_BAND_RECOVERY_BAR_INVALIDATION;s5_progress_trigger_time=" + trigger + ";s5_progress_trigger_close=" + N(b.Close),
                    GateDetail = "policy=M5_BAND_REENTRY_RSI14_LOCAL_TURN_AND_DIRECTIONAL_BODY;source_bar=" + b.Time };
                if (Stop456(signal)) continue;
                _s5Active[i] = signal;
                Emit(signal, false);
                _456TacticalActive.Add(signal);
            }
        }

        private bool S6Background456(out int direction, out double atr, out double ema)
        {
            direction = 0; atr = ema = 0;
            if (!BarsReady456(14400, 120) || !Value(14400, "EMA", 20, 1, out ema) ||
                !Value(14400, "EMA", 50, 1, out var slow) || !Value(14400, "EMA", 20, 4, out var past) ||
                !Value(14400, "ATR", 14, 1, out atr)) return false;
            var b = _series[14400].Last;
            direction = ema > slow && b.Close > ema && ema > past ? 1 : ema < slow && b.Close < ema && ema < past ? -1 : 0;
            return true;
        }
        private static bool PivotAt456(Series s, int shift, int dir)
        {
            if (shift < 3 || shift + 2 > s.Count) return false;
            var b = s.At(shift);
            for (int j = 1; j <= 2; j++)
                if (dir > 0 ? b.Low >= s.At(shift - j).Low || b.Low >= s.At(shift + j).Low :
                    b.High <= s.At(shift - j).High || b.High <= s.At(shift + j).High) return false;
            return true;
        }
        private bool Protection456(int dir, out double pivot, out long time)
        {
            pivot = 0; time = 0; var h4 = _series[14400];
            for (int j = 3; j + 2 < 121 && j + 2 <= h4.Count; j++)
                if (PivotAt456(h4, j, dir)) { pivot = dir > 0 ? h4.At(j).Low : h4.At(j).High; time = h4.At(j).Time; return true; }
            return false;
        }
        private bool Target6456(int dir, double entry, double stop, double protectAtr, out double target)
        {
            target = 0;
            if (!BarsReady456(86400, 3) || !BarsReady456(14400, 120) || entry <= 0 || dir * (entry - stop) <= 0 || protectAtr <= 0) return false;
            var day = _series[86400]; var h4 = _series[14400];
            double high = double.MinValue, low = double.MaxValue;
            for (int j = 1; j <= 3; j++) { high = Math.Max(high, Math.Max(day.At(j).Open, day.At(j).Close)); low = Math.Min(low, Math.Min(day.At(j).Open, day.At(j).Close)); }
            double nearest = double.MaxValue;
            if (dir * (high - entry) > 0) nearest = Math.Min(nearest, dir * (high - entry));
            if (dir * (low - entry) > 0) nearest = Math.Min(nearest, dir * (low - entry));
            for (int j = 3; j + 2 < 121; j++)
                if (PivotAt456(h4, j, -dir)) { double distance = dir * ((dir > 0 ? h4.At(j).High : h4.At(j).Low) - entry); if (distance > 0) nearest = Math.Min(nearest, distance); }
            double risk = dir * (entry - stop), reward = nearest == double.MaxValue ? 2 * risk : nearest - Buffer(protectAtr);
            if (reward + _options.TickSize * .000001 < 2 * risk) return false;
            target = entry + dir * reward; return target > 0;
        }
        private static int BarsAfter456(Series s, long since)
        {
            int count = 0;
            for (int j = 1; j <= Math.Min(120, s.Count); j++) { if (s.At(j).Time + s.Seconds <= since) break; count++; }
            return count;
        }
        private bool Family6456(Pattern456 p)
        {
            if (!BarsReady456(900, 120) || !Value(900, "ATR", 14, 1, out var atr)) return false;
            var bars = _series[900]; long bucket = 0;
            for (int j = 0; j <= 120; j++) { var b = bars.At(j); if (b.Time <= p.Second && p.Second < b.Time + 900) { bucket = b.Time; break; } }
            if (bucket == 0) return false;
            string key = "S6F|" + _options.Symbol + "|" + p.Direction + "|" + bucket;
            if (!_s6Families.TryGetValue(key, out var families)) { families = new List<Family456>(); _s6Families.Add(key, families); }
            for (int j = 0; j < families.Count; j++)
                if (Math.Abs(families[j].Neck - p.Neck) <= .25 * atr) { p.Family = key + "|" + j; families[j].Sources |= p.Sources; return true; }
            if (families.Count >= 64) return false;
            p.Family = key + "|" + families.Count; families.Add(new Family456 { Neck = p.Neck, Sources = p.Sources }); return true;
        }
        private void Detect6456(int tf, int h4Direction, double h4Atr)
        {
            var s = _series[tf];
            if (!Value(tf, "ATR", 14, 4, out var frozen)) return;
            for (int dir = -1; dir <= 1; dir += 2)
            {
                if (!PivotAt456(s, 3, dir)) continue;
                for (int first = 8; first <= 43 && first + 2 < 121; first++)
                {
                    if (!PivotAt456(s, first, dir)) continue;
                    double p1 = dir > 0 ? s.At(first).Low : s.At(first).High, p2 = dir > 0 ? s.At(3).Low : s.At(3).High;
                    if (Math.Abs(p1 - p2) > .35 * frozen) continue;
                    double neck = dir > 0 ? s.At(4).High : s.At(4).Low; long neckAt = s.At(4).Time;
                    for (int j = 5; j < first; j++) { double value = dir > 0 ? s.At(j).High : s.At(j).Low; if (dir * (value - neck) > 0) { neck = value; neckAt = s.At(j).Time; } }
                    if ((dir > 0 ? neck - Math.Max(p1, p2) : Math.Min(p1, p2) - neck) < .50 * frozen) continue;
                    var p = new Pattern456 { Direction = dir, Tf = tf, Sources = tf == 900 ? 1 : 2, First = s.At(first).Time, Second = s.At(3).Time,
                        NeckAt = neckAt, Available = s.Last.Time + tf, P1 = p1, P2 = p2, Neck = neck, FrozenAtr = frozen, ProtectAtr = h4Atr };
                    p.Id = "S6MW|" + _options.Symbol + "|" + dir + "|" + Tf456(tf) + "|" + p.First + "|" + p.Second + "|" + neckAt;
                    if (dir != h4Direction || !Protection456(dir, out var pivot, out _)) break;
                    p.Stop = dir > 0 ? Math.Min(Math.Min(p1, p2), pivot) - Buffer(h4Atr) : Math.Max(Math.Max(p1, p2), pivot) + Buffer(h4Atr);
                    if (p.Stop <= 0 || BackgroundStop456(dir, p.Stop) || !Family6456(p) || Used(p.Id) || Used(p.Family)) break;
                    bool exists = false; foreach (var old in _s6Patterns) if (old.Id == p.Id) { exists = true; break; }
                    if (!exists)
                    {
                        int free = _s6Patterns.FindIndex(x => !x.Active);
                        if (free >= 0) _s6Patterns[free] = p; else if (_s6Patterns.Count < 128) _s6Patterns.Add(p); else break;
                        Note(5, "MW_CANDIDATE", p.Id, "family=" + p.Family + ";available_at=" + p.Available + ";neckline=" + N(p.Neck));
                    }
                    break;
                }
            }
        }
        private void Breakouts6456(int tf)
        {
            var s = _series[tf]; long closed = s.Last.Time + tf;
            foreach (var p in _s6Patterns)
            {
                if (!p.Active || p.Tf != tf || p.Breakout > 0) continue;
                if (BarsAfter456(s, p.Available) > 12) { p.Active = false; Note(5, "MW_EXPIRED_BEFORE_BREAKOUT", p.Id, ""); continue; }
                if (closed < p.Available) continue;
                double threshold = p.Neck + p.Direction * .10 * p.FrozenAtr;
                if (p.Direction * (s.Last.Close - threshold) > 0 && p.Direction * (s.At(2).Close - threshold) <= 0)
                { p.Breakout = closed; Note(5, "MW_NECKLINE_BREAKOUT", p.Id, "breakout=" + closed); }
            }
        }
        private Signal H4Signal6456(int dir, double atr, double ema)
        {
            _s6H4Active = null;
            if (dir == 0 || !Value(14400, "ATR", 14, 2, out var previous)) return null;
            var b = _series[14400].Last;
            if (!(b.Low <= ema + .25 * previous && b.High >= ema - .25 * previous && dir * (b.Close - b.Open) > 0 && dir * (b.Close - ema) > 0) ||
                !Protection456(dir, out var pivot, out var pivotAt)) return null;
            var s = new Signal { StrategyId = 5, Direction = dir, TimeframeSeconds = 14400, Trigger = b.Time + 14400, Expires = b.Time + 28800,
                Reference = b.Close, Atr = previous, Stop = dir > 0 ? Math.Min(b.Low, pivot) - Buffer(atr) : Math.Max(b.High, pivot) + Buffer(atr),
                Structure = "S6H4|" + _options.Symbol + "|" + dir + "|" + b.Time, Path = "H4_PULLBACK", Detail = "entry_style=H4_CLOSE;h4_pivot_time=" + pivotAt };
            if (Used(s.Structure) || Now >= s.Expires || BackgroundStop456(dir, s.Stop) ||
                !Target6456(dir, dir > 0 ? _tick.Ask : _tick.Bid, s.Stop, atr, out var target)) return null;
            s.Target = target; _s6H4Active = s; return s;
        }
        private void Triggers6456(List<Signal> ready)
        {
            var s = _series[300]; var b = s.Last; long closed = b.Time + 300;
            bool atrReady = Value(300, "ATR", 14, 2, out var atr);
            foreach (var p in _s6Patterns)
            {
                if (!p.Active || p.Breakout == 0) continue;
                if (BarsAfter456(s, p.Breakout) > 6) { p.Active = false; Note(5, "MW_EXPIRED_AFTER_BREAKOUT", p.Id, ""); continue; }
                if (closed <= p.Breakout) continue;
                int dir = p.Direction; double band = .25 * p.FrozenAtr;
                if (dir * (b.Close - p.Neck) < -band) { p.Active = false; Note(5, "MW_BREAKOUT_FAILED", p.Id, ""); continue; }
                if (!atrReady || closed == p.LastTrigger) continue;
                TriggerStyle6456(b, s.At(2), dir, p.Neck, band, out var confirm, out var retest);
                if (!confirm && !retest) continue;
                if (confirm && retest) { p.LastTrigger = closed; Note(5, "S6_HYBRID_TRIGGER_REJECTED", p.Id, "pattern_consumed=0"); continue; }
                var signal = new Signal { StrategyId = 5, Direction = dir, TimeframeSeconds = 300, Trigger = closed, Expires = closed + 300,
                    Reference = b.Close, Atr = atr, Stop = dir > 0 ? b.Low - Buffer(atr) : b.High + Buffer(atr),
                    Structure = p.Id, Family = p.Family, ConsumeFamily = true, Path = "TREND_MW" };
                if (dir * (Round456(signal.Stop, -dir) - Round456(p.Stop, -dir)) <= 0 || Now >= signal.Expires) continue;
                if (Stop456(signal)) { p.LastTrigger = closed; continue; }
                if (!Target6456(dir, dir > 0 ? _tick.Ask : _tick.Bid, signal.Stop, p.ProtectAtr, out var target)) continue;
                signal.Target = target;
                signal.Detail = "entry_style=" + (confirm ? "CONFIRM" : "RETEST") + ";pattern_tf=" + Tf456(p.Tf) + ";s6_report_path=" +
                    (p.Tf == 900 ? "M15_" : "M5_") + (dir > 0 ? "W" : "M") + ";available_at=" + p.Available + ";breakout_time=" + p.Breakout + ";original_h4_sl=" + N(p.Stop);
                p.LastTrigger = closed; ready.Add(signal);
            }
        }
        private int Priority6456(Signal s)
        {
            if (s.Path == "H4_PULLBACK") return 2;
            foreach (var p in _s6Patterns) if (p.Id == s.Structure) return p.Tf == 900 ? 0 : 1;
            return 3;
        }
        private void Scan6Current456()
        {
            UpdateSmc456(300); UpdateSmc456(900);
            if (!S6Background456(out var direction, out var atr, out var ema)) return;
            if (_s6H4Active != null && (direction != _s6H4Active.Direction || BackgroundStop456(_s6H4Active.Direction, _s6H4Active.Stop) || Now >= _s6H4Active.Expires || Used(_s6H4Active.Structure))) _s6H4Active = null;
            foreach (var p in _s6Patterns)
                if (p.Active && (Used(p.Id) || Used(p.Family) || direction != p.Direction || BackgroundStop456(p.Direction, p.Stop))) p.Active = false;
            var ready = new List<Signal>();
            if (NewBar(14400, ref _s6H4Clock, 121)) { var h4 = H4Signal6456(direction, atr, ema); if (h4 != null) ready.Add(h4); }
            bool new15 = NewBar(900, ref _s6M15Clock, 121), new5 = NewBar(300, ref _s6M5Clock, 121);
            if (new15) { Detect6456(900, direction, atr); Breakouts6456(900); }
            if (new5) { Detect6456(300, direction, atr); Breakouts6456(300); Triggers6456(ready); }
            if (ready.Count == 0) return;
            Signal chosen = ready[0];
            foreach (var s in ready) if (s.Trigger < chosen.Trigger || s.Trigger == chosen.Trigger && Priority6456(s) < Priority6456(chosen)) chosen = s;
            bool allow = Gate6456(chosen, out var detail);
            Note(5, "C7_S6_GATE", chosen.Structure, "pass=" + allow + ";" + detail);
            // Selection precedes C7 gating in the native source; never fall back to a lower-priority failed contender.
            if (allow)
            {
                chosen.GateDetail = detail; Emit(chosen, false);
                if (chosen.Path == "TREND_MW") _456TacticalActive.Add(chosen);
            }
        }

        private static void TriggerStyle6456(Bar b, Bar previous, int dir, double neck, double band, out bool confirm, out bool retest)
        {
            bool candle = dir * (b.Close - b.Open) > 0 && dir * (b.Close - neck) > 0;
            confirm = candle && (dir > 0 ? b.Close > previous.High : b.Close < previous.Low);
            retest = candle && b.Low <= neck + band && b.High >= neck - band;
        }

        private static void ConfirmSmc456(Series s, int index, int length, ref int leg, Pivot456 high, Pivot456 low)
        {
            if (index < length) return;
            int p = index - length, old = leg; bool newHigh = true, newLow = true;
            for (int j = p + 1; j <= index; j++) { if (s.Bars[p].High <= s.Bars[j].High) newHigh = false; if (s.Bars[p].Low >= s.Bars[j].Low) newLow = false; }
            if (newHigh) leg = 0; else if (newLow) leg = 1;
            if (leg == old) return;
            var target = leg - old == 1 ? low : high;
            target.Price = leg - old == 1 ? s.Bars[p].Low : s.Bars[p].High; target.Valid = true; target.Broken = false;
        }
        private void UpdateSmc456(int tf)
        {
            var s = _series[tf];
            if (!_s6Smc.TryGetValue(tf, out var smc))
            {
                smc = new Smc456 { Next = Math.Max(1, s.Count - 3000) };
                for (int j = 0; j < smc.Next; j++) { smc.Biases.Add(double.NaN); smc.Events.Add(double.NaN); }
                _s6Smc.Add(tf, smc);
            }
            for (int b = smc.Next; b < s.Count; b++)
            {
                double previousHigh = smc.IH.Valid ? smc.IH.Price : double.NaN, previousLow = smc.IL.Valid ? smc.IL.Price : double.NaN;
                ConfirmSmc456(s, b, 50, ref smc.SwingLeg, smc.SH, smc.SL);
                ConfirmSmc456(s, b, 5, ref smc.InternalLeg, smc.IH, smc.IL);
                int ev = 0;
                if (smc.IH.Valid && !smc.IH.Broken && Finite(previousHigh) && s.Bars[b].Close > smc.IH.Price && s.Bars[b - 1].Close <= previousHigh && smc.SH.Valid && smc.IH.Price != smc.SH.Price)
                { ev = smc.Bias < 0 ? 2 : 1; smc.Bias = 1; smc.IH.Broken = true; }
                if (smc.IL.Valid && !smc.IL.Broken && Finite(previousLow) && s.Bars[b].Close < smc.IL.Price && s.Bars[b - 1].Close >= previousLow && smc.SL.Valid && smc.IL.Price != smc.SL.Price)
                { ev = smc.Bias > 0 ? -2 : -1; smc.Bias = -1; smc.IL.Broken = true; }
                smc.Biases.Add(smc.Bias); smc.Events.Add(ev);
            }
            smc.Next = s.Count;
        }
        private bool ClosedIndex456(int tf, long at, out int ix)
        {
            var s = _series[tf]; ix = s.FindAtOrBefore(at - tf);
            if (ix < 0) return false;
            long next = ix + 1 < s.Count ? s.Bars[ix + 1].Time : s.Current.Time;
            return s.Bars[ix].Time + tf <= at && next > s.Bars[ix].Time && next <= at && next + tf > at;
        }
        private bool Gate6456(Signal signal, out string detail)
        {
            detail = "policy=PATTERN_TF_SMC_RECENT_CONFIRMED_EVENT";
            if (signal.Path == "H4_PULLBACK") { detail += ";smc_applied=0"; return true; }
            var p = _s6Patterns.Find(x => x.Id == signal.Structure);
            if (p == null || !p.Active || p.Available > signal.Trigger || !ClosedIndex456(p.Tf, signal.Trigger, out var ix) || ix < 3202 || !ClosedIndex456(14400, signal.Trigger, out var h4ix) || h4ix < 154)
            { detail += ";reason=HISTORY_OR_TIME_NOT_READY"; return false; }
            var h4 = _series[14400]; double fast = h4.Ema20[h4ix], slow = h4.Ema50[h4ix], past = h4.Ema20[h4ix - 3];
            int direction = fast > slow && h4.Bars[h4ix].Close > fast && fast > past ? 1 : fast < slow && h4.Bars[h4ix].Close < fast && fast < past ? -1 : 0;
            var smc = _s6Smc[p.Tf]; var bars = _series[p.Tf]; long selected = 0;
            for (int n = 0; n < 3; n++)
            {
                int at = ix - n; double bias = smc.Biases[at], ev = smc.Events[at];
                long available = at + 1 < bars.Count ? bars.Bars[at + 1].Time : bars.Current.Time;
                if (!Finite(bias) || !Finite(ev) || available < bars.Bars[at].Time + p.Tf || available > signal.Trigger || ev != 0 && ev * bias <= 0) return false;
                detail += ";smc_bar" + n + "=" + bars.Bars[at].Time + ";smc_bias" + n + "=" + N(bias) + ";smc_event" + n + "=" + N(ev) + ";smc_available" + n + "=" + available;
                if (selected == 0 && signal.Direction * ev > 0 && available >= p.Available) selected = available;
            }
            detail += ";smc_selected_event_at=" + selected + ";h4_direction=" + direction;
            return direction == signal.Direction && signal.Direction * smc.Biases[ix] > 0 && selected > 0;
        }

        private bool ValidateStrategy456(Signal signal, out string reason)
        {
            reason = "SIGNAL_STRUCTURE_INVALID";
            if (signal.StrategyId == 3)
            { if (!SessionOpen(Now) || Momentum() != signal.Direction) return false; reason = "VALID"; return true; }
            if (Stop456(signal) || _456InvalidTactical.Contains(signal.Key)) { reason = "TACTICAL_SL_INVALIDATED"; return false; }
            if (signal.StrategyId == 4)
            {
                var active = _s5Active[signal.Direction > 0 ? 0 : 1];
                if (active == null || active.Structure != signal.Structure || !Range5Current456()) return false;
                reason = "VALID"; return true;
            }
            if (!S6Background456(out var dir, out _, out _) || dir != signal.Direction) return false;
            double entry = signal.Direction > 0 ? _tick.Ask : _tick.Bid, risk = signal.Direction * (entry - signal.Stop);
            if (risk <= 0 || signal.Direction * (signal.Target - entry) + _options.TickSize * .000001 < 2 * risk) { reason = "S6_TARGET_SPACE_LT_2R"; return false; }
            if (signal.Path == "H4_PULLBACK")
            { if (_s6H4Active == null || _s6H4Active.Structure != signal.Structure) return false; reason = "VALID"; return true; }
            var p = _s6Patterns.Find(x => x.Id == signal.Structure);
            if (p == null || !p.Active || Used(p.Family) || p.Breakout == 0 || signal.Trigger <= p.Breakout || p.Breakout < p.Available) return false;
            if (!BarsReady456(300, 120) || BarsAfter456(_series[300], p.Breakout) > 6) return false;
            if (_series[300].Last.Time + 300 > p.Breakout && signal.Direction * (_series[300].Last.Close - p.Neck) < -.25 * p.FrozenAtr) return false;
            reason = "VALID"; return true;
        }

        public Dictionary<string, double> Strategy456IndicatorSnapshot(int tf, int shift = 1)
        {
            var values = new Dictionary<string, double>(); var bars = _series[tf]; int ix = bars.Count - shift;
            if (shift < 1 || ix < 0) throw new ArgumentOutOfRangeException(nameof(shift));
            if (tf == 900) { UpdateAdx456(); values["ADX14_MT5_EMA"] = _s5Adx[ix]; }
            if (tf == 300 && Bands456(bars, shift, out var lo, out var hi, out var mid)) { values["BB20_LOWER"] = lo; values["BB20_UPPER"] = hi; values["BB20_MID"] = mid; }
            if (_s6Smc.TryGetValue(tf, out var smc) && ix < smc.Biases.Count) { values["SMC_INTERNAL_BIAS"] = smc.Biases[ix]; values["SMC_INTERNAL_EVENT"] = smc.Events[ix]; }
            return values;
        }

        public static IReadOnlyList<string> RunStrategy456SemanticTests()
        {
            var results = new List<string>();
            Action<bool, string> check = (ok, name) => { if (!ok) throw new InvalidOperationException("I9_S456_SEMANTICS:" + name); results.Add(name); };
            var flat = new Series(300);
            for (int j = 1; j <= 540; j++) flat.AppendClosed(new Bar { Time = j * 300, Open = 100, High = 101, Low = 99, Close = 100, TickVolume = 10 });
            check(Bands456(flat, 1, out var lower, out var upper, out var mid) && lower == 100 && upper == 100 && mid == 100, "BB20_population_variance_flat");
            check(!Bands456(flat, 0, out _, out _, out _), "BB_current_bar_rejected");
            flat.Current = new Bar { Time = 541 * 300, Open = 999, High = 999, Low = 999, Close = 999 };
            check(Bands456(flat, 1, out _, out _, out var untouched) && untouched == 100, "BB_current_bar_does_not_enter_closed_buffer");
            var engine = new Engine(new EngineOptions { CurrentProfiles = true, EnableS1 = false, EnableS4 = false });
            for (int j = 1; j <= 200; j++) engine._series[900].AppendClosed(new Bar { Time = j * 900, Open = 100, High = 101, Low = 99, Close = 100 });
            engine.UpdateAdx456(); check(engine._s5Adx[199] == 0, "ADX14_MT5_flat_zero_not_Wilder_alias");
            var pivots = new Series(300);
            double[] lows = { 99, 99, 95, 99, 99 };
            for (int j = 0; j < lows.Length; j++) pivots.AppendClosed(new Bar { Time = (j + 1) * 300, Open = 100, High = 101, Low = lows[j], Close = 100 });
            check(PivotAt456(pivots, 3, 1), "S6_strict_pivot_requires_two_closed_right_bars");
            check(!PivotAt456(pivots, 2, 1), "S6_unconfirmed_pivot_rejected");
            var previous = new Bar { High = 101, Low = 99 };
            TriggerStyle6456(new Bar { Open = 100, High = 103, Low = 100, Close = 102 }, previous, 1, 100, .25, out var confirm, out var retest);
            check(confirm && retest, "S6_hybrid_price_fixture_requires_rejection");
            TriggerStyle6456(new Bar { Open = 101, High = 103, Low = 100.5, Close = 102 }, previous, 1, 100, .25, out confirm, out retest);
            check(confirm && !retest, "S6_pure_confirmation_price_fixture");
            TriggerStyle6456(new Bar { Open = 100, High = 101, Low = 100, Close = 100.5 }, previous, 1, 100, .25, out confirm, out retest);
            check(!confirm && retest, "S6_pure_retest_price_fixture");
            engine._tick = new Tick { TimeMsc = 1000000, Bid = 99.99, Ask = 100.02 };
            check(engine.Stop456(new Signal { Direction = -1, Stop = 100.01 }), "S5_S6_short_stop_uses_ask");
            return results;
        }
    }
}
