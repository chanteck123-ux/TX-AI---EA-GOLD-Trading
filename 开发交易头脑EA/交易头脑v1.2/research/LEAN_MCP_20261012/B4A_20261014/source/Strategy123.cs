// I9: causal signal-layer port of retained S1/S2/S3. No orders or P/L model.
// SND/SNR formula provenance and limitations are recorded in S123_PORT_SPEC.json.
using System;
using System.Collections.Generic;
using System.Globalization;

namespace TradingBrain.C7
{
    public sealed partial class Engine
    {
        private sealed class CurrentCandidate123
        {
            public bool Active, Triggered, Retest;
            public int Dir, BreakIndex, RetestIndex;
            public long Born, Expires, SignalAt, RetestAt;
            public double High, Low, Atr, Level, Upper, Lower;
            public string Key = "";
        }
        private readonly CurrentCandidate123[] _currentS1 = { new CurrentCandidate123(), new CurrentCandidate123() };
        private readonly CurrentCandidate123[] _currentS3 = { new CurrentCandidate123(), new CurrentCandidate123() };
        private long _currentS1Clock15, _currentS1Clock5, _currentS2Clock15, _currentS2Clock5, _currentS3Clock15, _currentS3Clock5;
        private readonly HashSet<string> _invalid123 = new HashSet<string>();
        private readonly Dictionary<string, double> _s3Barriers = new Dictionary<string, double>();
        private readonly Dictionary<string, long> _s3Rearmed = new Dictionary<string, long>();
        private SndMachine[] _snd123;
        private SnrMachine _snr123;
        private readonly long[] _sndClock123 = { 0, 0 };
        private readonly bool[] _sndReady123 = { false, false };
        private readonly List<Zone123> _zones123 = new List<Zone123>();
        private readonly HashSet<string> _spentZones123 = new HashSet<string>();
        private readonly List<Bar> _observedM1 = new List<Bar>();
        private long _firstObserved123;
        private sealed class Zone123
        {
            public string Key = "";
            public int Dir, Slot, State;
            public long Known, Touched, Trigger, StagedAtMsc, Deadline;
            public double Low, High, Atr, QualificationAtr, T0Stop, T0Atr, T0Close;
        }
        private double Round123(double price, int direction) => (direction > 0 ? Math.Ceiling(price / _options.TickSize - 1e-9) : Math.Floor(price / _options.TickSize + 1e-9)) * _options.TickSize;
        private static string SignalIdentity123(Signal s) => s.StrategyId + "|" + s.Structure + "|" + s.Trigger;
        private bool Crossed123(Signal s) => s.Direction > 0 ? _tick.Bid <= Round123(s.Stop, -s.Direction) : _tick.Ask >= Round123(s.Stop, -s.Direction);
        private static bool IsNextProgress123(long t0, long t1, int dir, double close0, double close1) => t1 == t0 + 300 && dir * (close1 - close0) > 0;
        private void RejectGate123(Signal s, bool ready, string detail)
        {
            s.Key = "S" + (s.StrategyId + 1) + "|" + _options.Symbol + "|" + s.Direction + "|" + s.Structure + "|" + s.Trigger;
            if (_decisions.ContainsKey(s.Key)) return;
            if (_decisions.Count >= 65536) throw new InvalidOperationException("C7_CACHE_CAPACITY");
            _decisions.Add(s.Key, false); RawSignals++; RejectedSignals++; if (!ready) NotReadySignals++;
            Note(s.StrategyId, "C7_SETUP", s.Key, "ready=" + ready + ";pass=False;allow=False;trigger=" + s.Trigger + ";ref=" + N(s.Reference) + ";sl=" + N(s.Stop) + ";atr=" + N(s.Atr) + ";" + detail);
        }
        private void Cancel123(int sid, CurrentCandidate123 c, string why)
        { if (!c.Active) return; c.Active = false; CandidateCancellations++; Note(sid, "CANDIDATE_CANCEL", c.Key, why); }
        private int Trend123(int tf, bool slopeOnly = false)
        {
            if (!Value(tf, "EMA", 20, 1, out var fast) || !Value(tf, "EMA", 50, 1, out var slow) || !Value(tf, "EMA", 20, 4, out var past)) return 0;
            double close = _series[tf].At(1).Close;
            return (slopeOnly || fast > slow) && close > fast && fast > past ? 1 : (slopeOnly || fast < slow) && close < fast && fast < past ? -1 : 0;
        }
        private void OnStrategy123Tick()
        {
            ObserveM1_123();
            foreach (var s in _known.Values)
                if (s.StrategyId <= 2 && Now >= s.Trigger && Now < s.Expires && !Used(s.Structure) && Crossed123(s)) _invalid123.Add(SignalIdentity123(s));
            if (_options.EnableS1) ScanCurrentS1();
            if (_options.EnableS2) ScanCurrentS2();
            if (_options.EnableS3) ScanCurrentS3();
        }
        private void ObserveM1_123()
        {
            if (_firstObserved123 == 0) _firstObserved123 = Now;
            long time = Now / 60 * 60;
            if (_observedM1.Count == 0 || _observedM1[_observedM1.Count - 1].Time != time)
                _observedM1.Add(new Bar { Time = time, Open = _tick.Bid, High = _tick.Bid, Low = _tick.Bid, Close = _tick.Bid });
            else { var b = _observedM1[_observedM1.Count - 1]; b.High = Math.Max(b.High, _tick.Bid); b.Low = Math.Min(b.Low, _tick.Bid); b.Close = _tick.Bid; }
            // Only a source-current-bar adoption path is used; retain two days for H4.
            if (_observedM1.Count > 3000) _observedM1.RemoveRange(0, 1000);
        }
        private bool Unvisited123(long available, double low, double high, out string why)
        {
            why = "M1_ADOPTION_PATH_NOT_READY";
            int first = _observedM1.FindIndex(x => x.Time == available);
            if (first < 0 || _firstObserved123 > available) return false;
            for (int j = first; j < _observedM1.Count; j++)
                if (_observedM1[j].Low <= high && _observedM1[j].High >= low) { why = "CONTACT_BEFORE_ADOPTION"; return false; }
            why = "UNVISITED_OBSERVED_PATH"; return true;
        }
        private void ScanCurrentS1()
        {
            int trend = Trend();
            foreach (var c in _currentS1) if (c.Active)
            {
                if (Used(c.Key)) Cancel123(0, c, "SETUP_CONSUMED");
                else if (Now >= c.Expires + 300) Cancel123(0, c, "PULLBACK_EXPIRED");
                else if (trend != c.Dir) Cancel123(0, c, "H1_TREND_INVALID");
                else if (c.Dir > 0 ? _tick.Bid <= c.Low - Buffer(c.Atr) : _tick.Bid >= c.High + Buffer(c.Atr)) Cancel123(0, c, "STRUCTURE_SL_CROSSED");
            }
            if (Value(900, "EMA", 20, 1, out var ema) && Value(900, "ATR", 14, 2, out var atr) && NewBar(900, ref _currentS1Clock15, 4))
            {
                var b = _series[900].At(1);
                if (trend != 0 && b.Low <= ema + .25 * atr && b.High >= ema - .25 * atr && trend * (b.Close - ema) > 0)
                {
                    var c = new CurrentCandidate123 { Active = true, Dir = trend, Born = b.Time + 900, Expires = b.Time + 3600, High = b.High, Low = b.Low, Atr = atr, Level = ema, Key = "S1_PB_" + b.Time + "_" + trend };
                    if (!Used(c.Key) && c.Expires > Now) { int ix = trend > 0 ? 0 : 1; Cancel123(0, _currentS1[ix], "REPLACED_BY_NEW_PULLBACK"); _currentS1[ix] = c; Note(0, "PULLBACK_CONFIRMED", c.Key, "frozen_ema20=" + N(ema)); }
                }
            }
            if (!Value(300, "ATR", 14, 2, out var a5) || !NewBar(300, ref _currentS1Clock5, 3)) return;
            var bar = _series[300].At(1); long trigger = bar.Time + 300;
            foreach (var c in _currentS1)
            {
                if (!c.Active || (c.Triggered && trigger < c.SignalAt + 300) || trigger <= c.Born || trigger > c.Expires || Now >= trigger + 300 || !Confirm(bar, _series[300].At(2), c.Dir)) continue;
                double original = c.Dir > 0 ? Math.Min(c.Low, bar.Low) - Buffer(c.Atr) : Math.Max(c.High, bar.High) + Buffer(c.Atr);
                double tactical = c.Dir > 0 ? bar.Low - Buffer(a5) : bar.High + Buffer(a5);
                if (c.Dir * (Round123(tactical, -c.Dir) - Round123(original, -c.Dir)) <= 0) { Note(0, "S1_TRIGGER_SL_NOT_TIGHTER", c.Key, ""); continue; }
                if (!Finite(c.Level) || c.Dir * (bar.Close - c.Level) <= 0) { Note(0, "S1_TRIGGER_EMA_SIDE_LOST", c.Key, ""); continue; }
                c.Triggered = true; c.SignalAt = trigger;
                var s = new Signal { StrategyId = 0, Direction = c.Dir, Trigger = trigger, Expires = trigger + 300, Reference = bar.Close, Stop = tactical, Atr = a5, Structure = c.Key, Path = "H1_M15_M5" };
                if (Crossed123(s)) { _invalid123.Add(SignalIdentity123(s)); continue; }
                // Same original 3-bar recovery, plus the retained current-region gate.
                bool pass = Gate(s, out var ready, out var detail);
                double k = _series[300].K[_series[300].Count - 1];
                bool leftExtreme = Finite(k) && (c.Dir > 0 ? k > 20 : k < 80);
                s.GateDetail = detail + ";left_origin_extreme=" + leftExtreme + ";frozen_ema20=" + N(c.Level);
                if (_options.GateOn && (!ready || !pass || !leftExtreme)) { RejectGate123(s, ready, s.GateDetail); continue; }
                Emit(s, false);
            }
        }
        private void ZoneState123(Zone123 z, int state, string why)
        { if (z.State == state) return; z.State = state; if (state >= 1) _spentZones123.Add(z.Key); Note(1, "C7_S2_STATE", z.Key, "state=" + state + ";why=" + why); }
        private bool RefreshSnd123(int slot)
        {
            int tf = slot == 0 ? 3600 : 14400; var s = _series[tf];
            if (s.Current == null) return false;
            if (_sndClock123[slot] == s.Current.Time) return _sndReady123[slot];
            _sndReady123[slot] = false;
            if (s.Count < 1001 || !Value(tf, "ATR", 14, 1, out var atr)) return false;
            _snd123[slot].Update(); var row = _snd123[slot].Rows[s.Count - 1];
            if (row.Available > Now || row.Source + tf > Now) return false;
            double[] values = { row.DemandLow, row.DemandHigh, row.SupplyLow, row.SupplyHigh };
            foreach (var z in _zones123) if (z.Slot == slot && z.State == 0) { int ix = z.Dir > 0 ? 0 : 2; if (values[ix] != z.Low || values[ix + 1] != z.High) ZoneState123(z, 3, "NO_LONGER_SELECTED_FRESH"); }
            for (int d = 0; d < 2; d++)
            {
                int ix = d * 2, dir = d == 0 ? 1 : -1; if (!Finite(values[ix])) continue;
                string key = "C7S2_" + (slot == 0 ? 16385 : 16388) + "_" + dir + "_" + values[ix].ToString("F2", CultureInfo.InvariantCulture) + "_" + values[ix + 1].ToString("F2", CultureInfo.InvariantCulture);
                if (_zones123.Exists(z => z.Key == key) || _spentZones123.Contains(key) || Used(key)) continue;
                if (!Unvisited123(s.Current.Time, values[ix], values[ix + 1], out var why)) { if (why == "CONTACT_BEFORE_ADOPTION") _spentZones123.Add(key); Note(1, "C7_S2_ADOPTION_REJECT", key, why); continue; }
                if (_zones123.Count >= 4096) return false;
                _zones123.Add(new Zone123 { Key = key, Slot = slot, Dir = dir, Low = values[ix], High = values[ix + 1], Atr = atr, Known = Now });
                Note(1, "C7_S2_ADOPT", key, "known=" + Now + ";lo=" + N(values[ix]) + ";hi=" + N(values[ix + 1]));
            }
            _sndClock123[slot] = s.Current.Time; _sndReady123[slot] = true; return true;
        }
        private int BarsSince123(int tf, long time) { var s = _series[tf]; if (s.Current != null && time >= s.Current.Time) return 0; int i = s.FindAtOrBefore(time); return i < 0 ? -1 : s.Count - i; }
        private static bool Rejection123(Zone123 z, Bar b, double atr, out bool visitAlive)
        {
            visitAlive = b.Low <= z.High && b.High >= z.Low && z.Dir * (b.Close - (z.Dir > 0 ? z.High : z.Low)) <= .25 * atr;
            return visitAlive && z.Dir * (b.Close - b.Open) > 0 && z.Dir * (b.Close - (z.High + z.Low) * .5) > 0;
        }
        private void ScanCurrentS2()
        {
            if (_snd123 == null) _snd123 = new[] { new SndMachine(_series[3600], _options.TickSize), new SndMachine(_series[14400], _options.TickSize) };
            RefreshSnd123(0); RefreshSnd123(1);
            bool new15 = NewBar(900, ref _currentS2Clock15, 5), new5 = NewBar(300, ref _currentS2Clock5, 4);
            foreach (var z in _zones123)
            {
                if (z.State > 1) continue;
                if (z.State == 0 && !_sndReady123[z.Slot]) { ZoneState123(z, 3, "DATA_GAP_BEFORE_TOUCH"); continue; }
                if (Used(z.Key)) { ZoneState123(z, 2, "CONSUMED"); continue; }
                double stop = z.Dir > 0 ? z.Low - Buffer(z.Atr) : z.High + Buffer(z.Atr);
                if (z.Dir > 0 ? _tick.Bid <= stop : _tick.Ask >= stop) { ZoneState123(z, 4, "DISTAL_SL_CROSSED"); continue; }
                int tf = z.Slot == 0 ? 3600 : 14400;
                if (z.State == 0)
                {
                    if (_tick.Bid >= z.Low && _tick.Bid <= z.High && Now >= z.Known) { z.Touched = Now; ZoneState123(z, 1, "FIRST_OBSERVED_TOUCH"); if (Trend123(tf) != z.Dir) { ZoneState123(z, 2, "SOURCE_TF_EMA_NOT_ALIGNED"); continue; } }
                    else if (z.Dir > 0 ? _tick.Bid < z.Low : _tick.Bid > z.High) { ZoneState123(z, 2, "GAP_OVER_ZONE"); continue; }
                }
                if (z.State != 1) continue;
                if (_options.S2IndependentProgress) { ScanS2Progress123(z, new5); continue; }
                if (z.Trigger > 0 && Now >= z.Deadline) { ZoneState123(z, 2, "SIGNAL_EXPIRED"); continue; }
                if (z.Trigger == 0 && new15)
                {
                    var b = _series[900].At(1); long closed = b.Time + 900; if (closed <= z.Touched) continue;
                    int since = BarsSince123(900, z.Touched);
                    if (since < 0 || since > 3) { ZoneState123(z, 2, "THREE_M15_TIMEOUT"); continue; }
                    if (z.Dir > 0 ? b.Low > z.High : b.High < z.Low) { ZoneState123(z, 2, "VISIT_ENDED"); continue; }
                    bool confirms = z.Dir * (b.Close - b.Open) > 0 && z.Dir * (b.Close - (z.High + z.Low) * .5) > 0;
                    if (confirms)
                    {
                        if (Trend123(tf) != z.Dir) { ZoneState123(z, 2, "EMA_INVALID_AT_CONFIRM"); continue; }
                        if (!Value(900, "ATR", 14, 2, out var a)) continue;
                        z.Trigger = closed; z.Deadline = closed + 900; z.QualificationAtr = a; z.StagedAtMsc = _tick.TimeMsc;
                    }
                    else if (since >= 3) ZoneState123(z, 2, "NO_M15_CONFIRM");
                }
                if (z.State != 1 || z.Trigger == 0 || !new5 || !Value(300, "ATR", 14, 2, out var a5)) continue;
                var m5 = _series[300].At(1); long at = m5.Time + 300;
                if (at < z.Trigger || at >= z.Deadline || (at == z.Trigger && z.StagedAtMsc != _tick.TimeMsc) || Trend123(tf) != z.Dir) continue;
                bool reject = Rejection123(z, m5, z.QualificationAtr, out bool alive);
                if (!alive) { ZoneState123(z, 2, "M5_REJECTION_VISIT_ENDED_OR_DEPARTED_TOO_FAR"); continue; }
                if (!reject) continue;
                double tactical = z.Dir > 0 ? m5.Low - Buffer(a5) : m5.High + Buffer(a5);
                if (z.Dir * (Round123(tactical, -z.Dir) - Round123(stop, -z.Dir)) <= 0) continue;
                EmitS2_123(z, m5, a5, tactical, Math.Min(at + 300, z.Deadline), "_M15_CLOSED_M5_ZONE_REJECTION");
            }
        }
        private void ScanS2Progress123(Zone123 z, bool new5)
        {
            int tf = z.Slot == 0 ? 3600 : 14400;
            if (z.Trigger > 0)
            {
                if (Now >= z.Deadline) { ZoneState123(z, 2, "T1_WINDOW_EXPIRED"); return; }
                if (Trend123(tf) != z.Dir || (z.Dir > 0 ? _tick.Bid <= Round123(z.T0Stop, -z.Dir) : _tick.Ask >= Round123(z.T0Stop, -z.Dir))) { ZoneState123(z, 2, "T0_FROZEN_INVALIDATED"); return; }
                if (!new5) return;
                var next = _series[300].At(1); long at = next.Time + 300;
                if (at <= z.Trigger) return;
                if (at != z.Trigger + 300) { ZoneState123(z, 2, "T1_MISSING_OR_GAP"); return; }
                bool rejection = Rejection123(z, next, z.QualificationAtr, out bool alive);
                if (!alive || !rejection || !IsNextProgress123(z.Trigger, at, z.Dir, z.T0Close, next.Close)) { ZoneState123(z, 2, "T1_NO_INDEPENDENT_PROGRESS"); return; }
                EmitS2_123(z, next, z.T0Atr, z.T0Stop, z.Deadline, "_INDEPENDENT_NEXT_M5_PROGRESS");
                return;
            }
            if (!new5) return;
            var b = _series[300].At(1); long closed = b.Time + 300; if (closed <= z.Touched) return;
            int since = BarsSince123(300, z.Touched);
            if (since < 0 || since > 9) { ZoneState123(z, 2, "NINE_M5_FIRST_VISIT_TIMEOUT"); return; }
            if (Trend123(tf) != z.Dir) { ZoneState123(z, 2, "EMA_INVALID_AT_M5_CONFIRM"); return; }
            if (!Value(900, "ATR", 14, 1, out var atr) || _series[900].At(1).Time + 900 > closed || _series[900].Current.Time > closed || !Value(300, "ATR", 14, 2, out var a5)) { ZoneState123(z, 2, "M5_QUALIFICATION_ATR_NOT_READY"); return; }
            bool ok = Rejection123(z, b, atr, out bool visit);
            if (!visit) { ZoneState123(z, 2, "M5_FIRST_VISIT_ENDED_OR_TOO_FAR"); return; }
            if (!ok) { if (since >= 9) ZoneState123(z, 2, "NINE_M5_NO_REJECTION"); return; }
            double tactical = z.Dir > 0 ? b.Low - Buffer(a5) : b.High + Buffer(a5), zoneStop = z.Dir > 0 ? z.Low - Buffer(z.Atr) : z.High + Buffer(z.Atr);
            if (z.Dir * (Round123(tactical, -z.Dir) - Round123(zoneStop, -z.Dir)) <= 0) { ZoneState123(z, 2, "T0_SL_NOT_TIGHTER"); return; }
            if (z.Dir > 0 ? _tick.Bid <= Round123(tactical, -z.Dir) : _tick.Ask >= Round123(tactical, -z.Dir)) { ZoneState123(z, 2, "T0_FROZEN_SL_INVALIDATED"); return; }
            z.Trigger = closed; z.T0Close = b.Close; z.T0Stop = tactical; z.T0Atr = a5; z.QualificationAtr = atr;
            z.Deadline = Math.Min(closed + 600, (z.Touched / 300 * 300) + 10 * 300);
            Note(1, "S2_T0_PROGRESS_WAIT", z.Key, "t0=" + closed + ";t1=" + (closed + 300) + ";deadline=" + z.Deadline + ";frozen_stop=" + N(tactical));
        }
        private void EmitS2_123(Zone123 z, Bar b, double atr, double stop, long expires, string suffix)
        {
            var s = new Signal { StrategyId = 1, Direction = z.Dir, Trigger = b.Time + 300, Expires = expires, Reference = b.Close, Stop = stop, Atr = atr, Structure = z.Key, Path = (z.Slot == 0 ? "C7_H1_SND_FIRST_TOUCH" : "C7_H4_SND_FIRST_TOUCH") + suffix, GateDetail = "policy=SND_SELECTED_FRESH_SAME_TF_EMA" };
            if (Crossed123(s)) { _invalid123.Add(SignalIdentity123(s)); return; } Emit(s, false);
        }
        private void ScanCurrentS3()
        {
            if (_snr123 == null) _snr123 = new SnrMachine(_series[900], _options.TickSize);
            _snr123.Update();
            foreach (var c in _currentS3) if (c.Active)
            {
                if (Used(c.Key)) Cancel123(2, c, "SETUP_CONSUMED");
                else if (Now >= c.Expires + 300) Cancel123(2, c, "BREAKOUT_8_M15_EXPIRED");
                else if (c.Retest && (c.Dir > 0 ? _tick.Bid <= c.Low - Buffer(c.Atr) : _tick.Bid >= c.High + Buffer(c.Atr))) Cancel123(2, c, "RETEST_STRUCTURE_SL_CROSSED");
            }
            if (Value(900, "ATR", 14, 2, out var atr) && NewBar(900, ref _currentS3Clock15, 4))
            {
                var s15 = _series[900]; var bar = s15.At(1); int index = s15.Count - 1; long closed = bar.Time + 900;
                for (int i = 0; i < 2; i++)
                {
                    int dir = i == 0 ? 1 : -1; string prefix = dir + "|";
                    foreach (var barrierKey in new List<string>(_s3Barriers.Keys)) if (barrierKey.StartsWith(prefix, StringComparison.Ordinal) && _s3Barriers[barrierKey] > 0 && dir * (bar.Close - _s3Barriers[barrierKey]) <= 0) { _s3Barriers[barrierKey] = 0; _s3Rearmed[barrierKey] = closed; }
                    var c = _currentS3[i];
                    if (c.Active && closed > c.Born)
                    {
                        if (dir * (bar.Close - c.Level) < -.50 * c.Atr) Cancel123(2, c, "BREAKOUT_FAILED_FROZEN_LEVEL");
                        else if (!c.Retest && bar.Low <= c.Level + .25 * c.Atr && bar.High >= c.Level - .25 * c.Atr && dir * (bar.Close - c.Level) > 0)
                        { c.Retest = true; c.RetestAt = closed; c.RetestIndex = index; c.High = bar.High; c.Low = bar.Low; }
                    }
                    if (index < 3201 || index - 1 >= _snr123.Rows.Count) continue;
                    var anchor = _snr123.Rows[index - 1]; double upper = dir > 0 ? anchor.ResistanceUpper : anchor.SupportUpper, lower = dir > 0 ? anchor.ResistanceLower : anchor.SupportLower;
                    if (!Finite(upper) || !Finite(lower) || anchor.Available > bar.Time || anchor.Source + 900 > bar.Time) continue;
                    double level = dir > 0 ? upper : lower; string key = prefix + N(upper) + "|" + N(lower);
                    _s3Barriers.TryGetValue(key, out var barrier); _s3Rearmed.TryGetValue(key, out var rearmed);
                    bool broke = dir * (bar.Close - level) >= .15 * atr && dir * (s15.At(2).Close - level) <= 0;
                    if (!c.Active && barrier == 0 && rearmed != closed && broke)
                    {
                        var fresh = new CurrentCandidate123 { Active = true, Dir = dir, Born = closed, Expires = closed + 7200, Atr = atr, Level = level, Upper = upper, Lower = lower, BreakIndex = index, Key = "S3_BREAK_" + bar.Time + "_" + dir };
                        _s3Barriers[key] = level; if (!Used(fresh.Key) && fresh.Expires > Now) _currentS3[i] = fresh;
                    }
                }
            }
            if (!Value(300, "ATR", 14, 2, out var a5) || !NewBar(300, ref _currentS3Clock5, 3)) return;
            var b = _series[300].At(1); long trigger = b.Time + 300;
            foreach (var c in _currentS3)
            {
                if (!c.Active || !c.Retest || trigger <= c.RetestAt || trigger > c.Expires || Now >= trigger + 300 || (c.Triggered && trigger < c.SignalAt + 300) || !Confirm(b, _series[300].At(2), c.Dir)) continue;
                double original = c.Dir > 0 ? c.Low - Buffer(c.Atr) : c.High + Buffer(c.Atr), tactical = c.Dir > 0 ? b.Low - Buffer(a5) : b.High + Buffer(a5);
                if (c.Dir * (tactical - original) <= 0) continue;
                c.Triggered = true; c.SignalAt = trigger;
                var s = new Signal { StrategyId = 2, Direction = c.Dir, Trigger = trigger, Expires = trigger + 300, Reference = b.Close, Stop = tactical, Atr = a5, Structure = c.Key, Path = "FROZEN_BREAK_RETEST" };
                if (Crossed123(s)) { _invalid123.Add(SignalIdentity123(s)); continue; }
                bool pass = GateS3_123(c, out var why); int ix = _series[300].Count - 1;
                s.GateDetail = "policy=H1_SLOPE_PRICE_SNR_ROLE_SWAP_VFI;reason=" + why + ";breakout_at=" + c.Born + ";retest_at=" + c.RetestAt + ";anchor_upper=" + N(c.Upper) + ";anchor_lower=" + N(c.Lower) + ";level=" + N(c.Level) + ";vfi=" + N(_series[300].Vfi[ix]) + ";vfi_signal=" + N(_series[300].VfiSignal[ix]);
                if (_options.GateOn && !pass) { RejectGate123(s, !why.Contains("NOT_READY"), s.GateDetail); continue; } Emit(s, false);
            }
        }
        private bool GateS3_123(CurrentCandidate123 c, out string why)
        {
            why = "S3_RETEST_WINDOW_INVALID";
            if (c.RetestIndex <= c.BreakIndex || c.RetestIndex - c.BreakIndex > 8 || c.BreakIndex < 3201 || c.RetestIndex >= _snr123.Rows.Count) return false;
            if (Trend123(3600, true) != c.Dir) { why = "H1_EMA_NOT_ALIGNED"; return false; }
            long observed = 0; var previous = _snr123.Rows[c.BreakIndex - 1];
            for (int j = c.BreakIndex; j <= c.RetestIndex; j++)
            {
                var row = _snr123.Rows[j]; if (row.Available > c.RetestAt) { why = "SNR_FUTURE_AVAILABILITY"; return false; }
                bool before = SameSnr123(previous, -c.Dir, c.Upper, c.Lower), after = SameSnr123(row, c.Dir, c.Upper, c.Lower);
                bool crossed = c.Dir > 0 ? previous.Close <= c.Upper && row.Close > c.Upper : previous.Close >= c.Lower && row.Close < c.Lower;
                if (before && after && crossed && (row.Events & (c.Dir > 0 ? 4 : 8)) != 0) observed = row.Available;
                previous = row;
            }
            var retest = _snr123.Rows[c.RetestIndex]; var b = _series[900].Bars[c.RetestIndex];
            if (observed < c.Born || observed > c.RetestAt) { why = "NO_ASSOCIATED_CLOSED_ROLE_SWAP"; return false; }
            if (!SameSnr123(retest, c.Dir, c.Upper, c.Lower)) { why = "RETEST_SELECTED_DIFFERENT_REGION"; return false; }
            if ((c.Dir > 0 ? retest.SupportQuality : retest.ResistanceQuality) != 1) { why = "RETEST_REGION_NOT_GOOD"; return false; }
            if (b.Low > c.Upper || b.High < c.Lower) { why = "RETEST_NO_ZONE_OVERLAP"; return false; }
            if (c.Dir > 0 ? b.Close <= c.Upper : b.Close >= c.Lower) { why = "RETEST_CLOSE_NOT_OUTSIDE_ZONE"; return false; }
            var m5 = _series[300]; int ix = m5.Count - 1;
            if (ix < 511 || !Finite(m5.Vfi[ix]) || !Finite(m5.VfiSignal[ix])) { why = "VFI_NOT_READY"; return false; }
            if (c.Dir * (m5.Vfi[ix] - m5.VfiSignal[ix]) <= 0) { why = "VFI_OPPOSES_DIRECTION"; return false; }
            why = "EMA_ASSOCIATED_ROLE_SWAP_VFI_CONFIRMED"; return true;
        }
        private static bool SameSnr123(SnrRow row, int role, double upper, double lower) => role > 0 ? row.SupportUpper == upper && row.SupportLower == lower : row.ResistanceUpper == upper && row.ResistanceLower == lower;
        private bool ValidateStrategy123(Signal s, out string reason)
        {
            reason = "SIGNAL_STRUCTURE_INVALID";
            if (_invalid123.Contains(SignalIdentity123(s)) || Crossed123(s)) { _invalid123.Add(SignalIdentity123(s)); reason = "FROZEN_TRIGGER_SL_INVALIDATED"; return false; }
            if (s.StrategyId == 0)
            {
                var c = _currentS1[s.Direction > 0 ? 0 : 1];
                if (!c.Active || c.Key != s.Structure || s.Trigger > c.Expires || Trend() != s.Direction) return false;
                if (s.Direction * ((s.Direction > 0 ? _tick.Ask : _tick.Bid) - s.Reference) < -1e-8) { reason = "S1_CONFIRMATION_PRICE_LOST"; return false; }
            }
            else if (s.StrategyId == 1)
            {
                var z = _zones123.Find(x => x.Key == s.Structure && x.State == 1);
                if (z == null || z.Trigger == 0 || s.Trigger < z.Trigger || s.Trigger >= z.Deadline || Now >= z.Deadline || z.QualificationAtr <= 0) return false;
                if (_options.S2IndependentProgress && s.Trigger != z.Trigger + 300) return false;
                if (Trend123(z.Slot == 0 ? 3600 : 14400) != s.Direction) { reason = "C7_S2_EMA_CHANGED"; return false; }
                double exec = s.Direction > 0 ? _tick.Ask : _tick.Bid;
                if (s.Direction * (exec - (s.Direction > 0 ? z.High : z.Low)) > .25 * z.QualificationAtr) { reason = "FIRST_TOUCH_EXECUTION_OUTSIDE_ZONE_RANGE"; return false; }
            }
            else
            {
                var c = _currentS3[s.Direction > 0 ? 0 : 1];
                if (!c.Active || !c.Retest || c.Key != s.Structure || s.Trigger > c.Expires || s.Direction * (_series[900].At(1).Close - c.Level) < -.50 * c.Atr) return false;
            }
            reason = "VALID"; return true;
        }

        // Indicator state below is computed from bars, never from MT5 event/zone exports.
        private sealed class SndRow
        {
            public long Source, Available;
            public double DemandLow = double.NaN, DemandHigh = double.NaN, DemandReference = double.NaN, SupplyLow = double.NaN, SupplyHigh = double.NaN, SupplyReference = double.NaN;
        }
        private sealed class SndMachine
        {
            private sealed class Zone { public int Dir, State, Created, Kinds; public double Low, High, Reference, Departure; public bool Inside; }
            private readonly Series _s; private readonly double _point; private readonly int _maxAge, _history;
            private readonly List<Zone> _zones = new List<Zone>(); private readonly List<double> _atr = new List<double>();
            public readonly List<SndRow> Rows = new List<SndRow>();
            private int _start = -1, _runStart = -1, _runDir; private bool _runEmitted;
            public SndMachine(Series series, double point, int maxAge = 60, int initialHistory = 1000) { _s = series; _point = point; _maxAge = maxAge; _history = initialHistory; }
            public void Update()
            {
                if (_s.Current == null || _s.Count < 15) return;
                if (_start < 0) _start = Math.Max(14, _s.Count - _history);
                for (int i = Rows.Count; i < _s.Count; i++)
                {
                    var b = _s.Bars[i]; double tr = i == 0 ? b.High - b.Low : Math.Max(b.High, _s.Bars[i - 1].Close) - Math.Min(b.Low, _s.Bars[i - 1].Close);
                    double atr = double.NaN;
                    if (i == 13) { atr = 0; for (int j = 0; j <= 13; j++) { var q = _s.Bars[j]; atr += j == 0 ? q.High - q.Low : Math.Max(q.High, _s.Bars[j - 1].Close) - Math.Min(q.Low, _s.Bars[j - 1].Close); } atr /= 14; }
                    else if (i > 13) atr = (_atr[i - 1] * 13 + tr) / 14;
                    _atr.Add(atr);
                    var row = new SndRow { Source = b.Time, Available = i + 1 < _s.Count ? _s.Bars[i + 1].Time : _s.Current.Time };
                    if (i >= _start) { UpdateZones(i, b); Detect(i, b); Snapshot(b.Close, row); }
                    Rows.Add(row);
                }
            }
            private void UpdateZones(int i, Bar b)
            {
                foreach (var z in _zones)
                {
                    if (z.State >= 2) continue;
                    if (z.Dir > 0 ? b.Close < z.Low : b.Close > z.High) { z.State = 2; continue; }
                    if (i - z.Created > _maxAge) { z.State = 3; continue; }
                    if (z.State == -1) { if (z.Dir > 0 ? b.Close > z.High + z.Departure : b.Close < z.Low - z.Departure) z.State = 0; continue; }
                    bool overlap = b.High >= z.Low && b.Low <= z.High;
                    if (overlap && !z.Inside) z.State = 1;
                    z.Inside = b.Close >= z.Low && b.Close <= z.High;
                }
            }
            private void Add(int dir, int kind, double lo, double hi, int i, double close, double atr)
            {
                if (hi - lo < _point * .1) return;
                foreach (var z in _zones) if (z.Created == i && z.Dir == dir && Math.Abs(z.Low - lo) < _point * .01 && Math.Abs(z.High - hi) < _point * .01) { z.Kinds |= kind; return; }
                if (_zones.Count >= 200) { int ix = _zones.FindIndex(z => z.State >= 2); _zones.RemoveAt(ix < 0 ? 0 : ix); }
                _zones.Add(new Zone { Dir = dir, Kinds = kind, Low = lo, High = hi, Created = i, Departure = .05 * atr, Reference = hi - lo > 30 * _point ? (lo + hi) * .5 : dir > 0 ? hi : lo, State = (dir > 0 ? close > hi + .05 * atr : close < lo - .05 * atr) ? 0 : -1 });
            }
            private void Detect(int i, Bar b)
            {
                if (i < 1 || !Finite(_atr[i - 1]) || _atr[i - 1] <= 0) return;
                double atr = _atr[i - 1], range = b.High - b.Low, body = Math.Abs(b.Close - b.Open);
                if (range > 0)
                {
                    double upper = b.High - Math.Max(b.Open, b.Close), lower = Math.Min(b.Open, b.Close) - b.Low, required = 2 * Math.Max(body, _point);
                    if (upper >= .60 * range && upper >= required && upper >= .50 * atr) Add(-1, 1, b.High - upper, b.High, i, b.Close, atr);
                    if (lower >= .60 * range && lower >= required && lower >= .50 * atr) Add(1, 1, b.Low, b.Low + lower, i, b.Close, atr);
                }
                if (i >= 2 && body >= .80 * atr)
                {
                    double hi = double.MinValue, lo = double.MaxValue; int count = 0;
                    for (int j = i - 1; j >= 0 && count < 6; j--)
                    {
                        var q = _s.Bars[j]; double r = q.High - q.Low;
                        if (r <= 0 || r > .80 * atr || Math.Abs(q.Close - q.Open) > .50 * r) break;
                        double nh = Math.Max(hi, q.High), nl = Math.Min(lo, q.Low); if (nh - nl > 1.20 * atr) break;
                        hi = nh; lo = nl; count++;
                    }
                    if (count >= 2) { if (b.Close > b.Open && b.Close > hi + .05 * atr) Add(1, 2, lo, hi, i, b.Close, atr); if (b.Close < b.Open && b.Close < lo - .05 * atr) Add(-1, 2, lo, hi, i, b.Close, atr); }
                }
                int dir = b.Close > b.Open ? 1 : b.Close < b.Open ? -1 : 0;
                bool strong = range > 0 && body >= .60 * range && dir != 0;
                if (!strong) { _runStart = -1; _runDir = 0; _runEmitted = false; return; }
                if (_runStart < 0 || _runDir != dir || dir * (b.Close - _s.Bars[i - 1].Close) <= 0) { _runStart = i; _runDir = dir; _runEmitted = false; }
                int origin = _runStart - 1;
                if (!_runEmitted && i - _runStart + 1 >= 3 && origin >= 0 && Finite(_atr[origin]) && dir * (b.Close - _s.Bars[_runStart].Open) >= 2 * _atr[origin])
                { var q = _s.Bars[origin]; Add(dir, 4, q.Low, q.High, i, b.Close, _atr[origin]); _runEmitted = true; }
            }
            private void Snapshot(double close, SndRow row)
            {
                double demand = double.MaxValue, supply = double.MaxValue;
                foreach (var z in _zones) if (z.State == 0)
                {
                    double d = Math.Abs(close - (z.Dir > 0 ? z.High : z.Low));
                    if (z.Dir > 0 && d < demand) { demand = d; row.DemandLow = z.Low; row.DemandHigh = z.High; row.DemandReference = z.Reference; }
                    if (z.Dir < 0 && d < supply) { supply = d; row.SupplyLow = z.Low; row.SupplyHigh = z.High; row.SupplyReference = z.Reference; }
                }
            }
        }
        private sealed class SnrRow
        {
            public long Source, Available; public int Events, Arrival, Count; public double Close, Atr;
            public double SupportUpper = double.NaN, SupportLower = double.NaN, ResistanceUpper = double.NaN, ResistanceLower = double.NaN, SupportQuality = double.NaN, ResistanceQuality = double.NaN;
        }
        private sealed class SnrMachine
        {
            private sealed class Zone { public int Role, Touches, Created, LastPivot, Activated, Visit = -1, BreakBar = -1, BreakFrom; public double Upper, Lower, VisitAtr; public bool Active, Armed, Bad, Stalled; }
            private readonly Series _s; private readonly double _point; private readonly List<Zone> _zones = new List<Zone>(); private readonly List<double> _atr = new List<double>();
            public readonly List<SnrRow> Rows = new List<SnrRow>(); private int _start = -1;
            public SnrMachine(Series series, double point) { _s = series; _point = point; }
            public void Update()
            {
                if (_s.Current == null || _s.Count < 22) return;
                if (_start < 0) _start = Math.Max(17, _s.Count - 3000);
                for (int i = Rows.Count; i < _s.Count; i++)
                {
                    var b = _s.Bars[i]; double atr = double.NaN;
                    if (i == 14) { atr = 0; for (int j = 1; j <= 14; j++) atr += Tr(j); atr /= 14; }
                    else if (i > 14) atr = (_atr[i - 1] * 13 + Tr(i)) / 14;
                    _atr.Add(atr); var row = new SnrRow { Source = b.Time, Available = i + 1 < _s.Count ? _s.Bars[i + 1].Time : _s.Current.Time, Close = b.Close, Atr = atr };
                    if (i >= _start)
                    {
                        UpdateZones(i, row); int p = i - 3;
                        if (p >= Math.Max(3, _start))
                        {
                            bool high = true, low = true;
                            for (int j = p - 3; j <= i; j++) if (j != p) { if (_s.Bars[j].High >= _s.Bars[p].High) high = false; if (_s.Bars[j].Low <= _s.Bars[p].Low) low = false; }
                            if (high) Pivot(-1, p, i, row); if (low) Pivot(1, p, i, row);
                        }
                        Snapshot(row);
                    }
                    Rows.Add(row);
                }
            }
            private double Tr(int i) => Math.Max(_s.Bars[i].High, _s.Bars[i - 1].Close) - Math.Min(_s.Bars[i].Low, _s.Bars[i - 1].Close);
            private int Crossings(Zone z, int b)
            {
                int crosses = 0, last = 0;
                for (int j = Math.Max(z.Activated, b - 19); j <= b; j++) { double c = _s.Bars[j].Close; int side = c > z.Upper ? 1 : c < z.Lower ? -1 : 0; if (side == 0) continue; if (last != 0 && side != last) crosses++; last = side; }
                return crosses;
            }
            private void UpdateZones(int i, SnrRow row)
            {
                var b = _s.Bars[i];
                for (int q = _zones.Count - 1; q >= 0; q--)
                {
                    var z = _zones[q];
                    if (i - z.Created > 1500) { _zones.RemoveAt(q); continue; }
                    if (!z.Active) { if (z.Role > 0 ? b.Close < z.Lower : b.Close > z.Upper) _zones.RemoveAt(q); continue; }
                    if (z.BreakBar >= 0 && i - z.BreakBar > 3) { z.BreakBar = -1; z.BreakFrom = 0; }
                    bool recovered = z.BreakBar >= 0 && i > z.BreakBar && (z.BreakFrom > 0 ? b.Close >= z.Lower : b.Close <= z.Upper);
                    if (recovered) { z.Role = z.BreakFrom; z.Visit = -1; z.Armed = z.Role > 0 ? b.Low > z.Upper : b.High < z.Lower; z.Stalled = false; z.BreakBar = -1; z.BreakFrom = 0; }
                    bool flip = !recovered && (z.Role > 0 ? b.Close < z.Lower : b.Close > z.Upper);
                    if (flip) { z.BreakBar = i; z.BreakFrom = z.Role; z.Role = -z.Role; z.Visit = -1; z.Armed = true; z.Stalled = false; row.Events |= z.Role > 0 ? 4 : 8; }
                    z.Bad = z.Stalled || Crossings(z, i) >= 3;
                    if (recovered) { row.Events |= z.Role > 0 ? 256 : 512; continue; } if (flip) continue;
                    bool hit = b.High >= z.Lower && b.Low <= z.Upper;
                    if (z.Armed && hit) { z.Armed = false; z.Visit = i; z.VisitAtr = _atr[i - 1]; row.Events |= z.Role > 0 ? 16 : 32; if (!z.Bad) row.Arrival |= z.Role > 0 ? 1 : 2; }
                    bool fake = z.Role > 0 ? b.Low < z.Lower && b.Close >= z.Lower && _s.Bars[i - 1].Close >= z.Lower : b.High > z.Upper && b.Close <= z.Upper && _s.Bars[i - 1].Close <= z.Upper;
                    if (fake) row.Events |= z.Role > 0 ? 256 : 512;
                    if (z.Visit >= 0)
                    {
                        bool bounced = z.Role > 0 ? b.Close >= z.Upper + .50 * z.VisitAtr : b.Close <= z.Lower - .50 * z.VisitAtr;
                        if (bounced && i - z.Visit <= 6) { z.Touches++; z.Visit = -1; z.Stalled = false; z.Bad = Crossings(z, i) >= 3; row.Events |= z.Role > 0 ? 64 : 128; }
                        else if (i - z.Visit > 6) { z.Stalled = true; z.Bad = true; z.Visit = -1; }
                    }
                    if (!hit && z.Visit < 0 && (z.Role > 0 ? b.Low > z.Upper : b.High < z.Lower)) z.Armed = true;
                }
            }
            private void Pivot(int role, int p, int b, SnrRow row)
            {
                if (!Finite(_atr[p])) return; var pivot = _s.Bars[p]; double price = role > 0 ? pivot.Low : pivot.High, half = Math.Max(2 * _point, .15 * _atr[p]), lower = price - half, upper = price + half;
                double best = _s.Bars[p + 1].Close; for (int j = p + 1; j <= b; j++) best = role > 0 ? Math.Max(best, _s.Bars[j].Close) : Math.Min(best, _s.Bars[j].Close);
                if (role > 0 ? best < upper + .50 * _atr[p] : best > lower - .50 * _atr[p]) return;
                if (role > 0 ? row.Close < lower : row.Close > upper) return;
                Zone match = null; double dist = double.MaxValue;
                foreach (var z in _zones)
                {
                    if (z.Role != role || price < z.Lower || price > z.Upper) continue; if (z.Active) return;
                    double d = Math.Abs(price - (z.Upper + z.Lower) * .5); if (d < dist) { dist = d; match = z; }
                }
                if (match != null)
                {
                    if (p - match.LastPivot < 6) return; match.LastPivot = p; match.Touches++; match.Active = true; match.Activated = b; match.Armed = role > 0 ? _s.Bars[b].Low > match.Upper : _s.Bars[b].High < match.Lower; row.Events |= role > 0 ? 1 : 2; return;
                }
                if (_zones.Count >= 30) { int ix = _zones.FindIndex(z => !z.Active); _zones.RemoveAt(ix < 0 ? 0 : ix); }
                _zones.Add(new Zone { Role = role, Touches = 1, Created = b, LastPivot = p, Activated = b, Upper = upper, Lower = lower });
            }
            private void Snapshot(SnrRow row)
            {
                double sd = double.MaxValue, rd = double.MaxValue;
                foreach (var z in _zones)
                {
                    if (!z.Active) continue; row.Count++; if (z.Bad) continue;
                    if (z.Role > 0 && z.Lower <= row.Close) { double d = Math.Max(0, row.Close - z.Upper); if (d <= sd) { sd = d; row.SupportUpper = z.Upper; row.SupportLower = z.Lower; row.SupportQuality = 1; } }
                    if (z.Role < 0 && z.Upper >= row.Close) { double d = Math.Max(0, z.Lower - row.Close); if (d <= rd) { rd = d; row.ResistanceUpper = z.Upper; row.ResistanceLower = z.Lower; row.ResistanceQuality = 1; } }
                }
            }
        }
        public static IReadOnlyList<string> RunStrategy123SemanticTests()
        {
            var results = new List<string>(); Action<bool, string> check = (ok, name) => { if (!ok) throw new InvalidOperationException("S123_SEMANTIC_FAILED:" + name); results.Add(name); };
            var z = new Zone123 { Dir = 1, Low = 100, High = 102 };
            check(Rejection123(z, new Bar { Open = 100, High = 103, Low = 101, Close = 102.2 }, 2, out bool alive) && alive, "FIRST_VISIT_NEAR_PROXIMAL_REJECTION");
            check(!Rejection123(z, new Bar { Open = 102, High = 104, Low = 102.1, Close = 103 }, 2, out alive) && !alive, "DEPARTED_VISIT_CANNOT_REARM");
            var row = new SnrRow { SupportUpper = 102, SupportLower = 100, ResistanceUpper = double.NaN, ResistanceLower = double.NaN };
            check(SameSnr123(row, 1, 102, 100) && !SameSnr123(row, -1, 102, 100) && !SameSnr123(row, 1, 102.0000001, 100), "SNR_EXACT_GEOMETRY_AND_ROLE");
            var engine = new Engine(new EngineOptions { CurrentProfiles = true, EnableS1 = false, EnableS4 = false, UseCanonicalBars = true });
            engine.PushClosedBar(300, new Bar { Time = 300, Open = 100, High = 102, Low = 99, Close = 101 });
            bool rejected = false; try { engine.OnTick(new Tick { TimeMsc = 599000, Bid = 101, Ask = 101.01 }); } catch (ArgumentException) { rejected = true; }
            check(rejected, "FUTURE_CLOSED_BAR_REJECTED");
            long t0 = 1200;
            check(IsNextProgress123(t0, 1500, 1, 100, 101) && !IsNextProgress123(t0, t0, 1, 100, 101) && !IsNextProgress123(t0, 1800, 1, 100, 101), "UNIQUE_NEXT_M5_NOT_T0_OR_T2");
            check(!IsNextProgress123(t0, 1500, 1, 100, 100) && !IsNextProgress123(t0, 1500, 1, 100, 99) && IsNextProgress123(t0, 1500, -1, 100, 99), "INDEPENDENT_PROGRESS_DIRECTION_AND_EQUALITY");
            return results;
        }
    }
}
