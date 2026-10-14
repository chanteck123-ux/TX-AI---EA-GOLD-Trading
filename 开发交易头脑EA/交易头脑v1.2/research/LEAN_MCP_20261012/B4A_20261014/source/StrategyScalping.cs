// I9 USER_SCALP handbook candidate. Signal calculation only; no simulated fills/P&L.
using System;
using System.Collections.Generic;
using System.Linq;

namespace TradingBrain.C7
{
    public sealed partial class Engine
    {
        private sealed class ScalpZone
        {
            public int Direction;
            public long Born, TouchBar;
            public double Top, Bottom;
            public bool Touched, Retired;
            public string Key = "";
        }
        private long _scalpClock;
        private readonly ScalpZone[] _scalpZones = new ScalpZone[2];
        private readonly HashSet<string> _scalpArmed = new HashSet<string>(StringComparer.Ordinal);

        private static double ScalpDistance(double price, double bottom, double top)
            => price < bottom ? bottom - price : price > top ? price - top : 0;
        private static double ScalpWickWidth(Bar b, int direction)
            => Math.Min(3.0, direction > 0 ? Math.Min(b.Open, b.Close) - b.Low : b.High - Math.Max(b.Open, b.Close));
        private static bool ScalpReversal(Bar b, Bar previous, int direction, double tickSize)
        {
            double range = b.High - b.Low, body = Math.Max(Math.Abs(b.Close - b.Open), tickSize);
            if (range <= tickSize || direction * (b.Close - b.Open) <= 0) return false;
            bool engulf = direction > 0
                ? previous.Close < previous.Open && b.Open <= previous.Close && b.Close >= previous.Open
                : previous.Close > previous.Open && b.Open >= previous.Close && b.Close <= previous.Open;
            double wick = direction > 0 ? Math.Min(b.Open, b.Close) - b.Low : b.High - Math.Max(b.Open, b.Close);
            double closeLocation = (b.Close - b.Low) / range;
            bool rejection = wick >= body * 2.0 && wick >= range * .55 &&
                (direction > 0 ? closeLocation >= .55 : closeLocation <= .45);
            return engulf || rejection;
        }
        private double ScalpAtr(int shift)
        {
            var s = _series[300]; if (s.Count < shift + 14) return 0;
            double sum = 0;
            for (int j = shift; j < shift + 14; j++)
            {
                var b = s.At(j); var p = s.At(j + 1);
                sum += Math.Max(b.High - b.Low, Math.Max(Math.Abs(b.High - p.Close), Math.Abs(b.Low - p.Close)));
            }
            return sum / 14.0; // old MQL CalcATR: arithmetic mean of true ranges, not Wilder ATR
        }
        private ScalpZone ScalpFind(int direction)
        {
            var s = _series[300]; if (s.Count + 1 < 214) return null;
            ScalpZone best = null; double distance = double.MaxValue, mid = (_tick.Bid + _tick.Ask) / 2;
            for (int i = 3; i <= 180; i++)
            {
                var b = s.At(i); double atr = ScalpAtr(i), range = b.High - b.Low;
                if (atr <= 0 || range < 1.2 * atr || range <= 0 || Math.Abs(b.Close - b.Open) / range < .45 || direction * (b.Close - b.Open) <= 0) continue;
                double width = ScalpWickWidth(b, direction); if (width < _options.TickSize) continue;
                var z = new ScalpZone { Direction = direction, Born = b.Time,
                    Bottom = direction > 0 ? b.Low : b.High - width,
                    Top = direction > 0 ? b.Low + width : b.High,
                    Key = "SCALP_" + _options.Symbol + "_" + direction + "_" + b.Time };
                if (_scalpArmed.Contains(z.Key) || (direction > 0 ? b.Close <= z.Top : b.Close >= z.Bottom)) continue;
                bool departure = false, touched = false;
                // Departure remains 1.50 price from the capped zone edge (old max-zone rule).
                for (int j = i - 1; j >= Math.Max(2, i - 8); j--)
                    if (direction > 0 ? s.At(j).High >= z.Top + 1.5 : s.At(j).Low <= z.Bottom - 1.5) departure = true;
                if (!departure) continue;
                for (int j = i - 3; j >= 2; j--) if (s.At(j).High >= z.Bottom && s.At(j).Low <= z.Top) { touched = true; break; }
                if (touched) continue;
                double d = ScalpDistance(mid, z.Bottom, z.Top);
                if (best == null || d < distance) { best = z; distance = d; } // equal acquisition distance: newest first
            }
            return best;
        }
        private void ScalpRefresh(int slot)
        {
            var s = _series[300]; var z = _scalpZones[slot]; int direction = slot == 0 ? 1 : -1;
            if (z != null && !z.Retired)
            {
                int age = s.Bars.FindLastIndex(b => b.Time == z.Born);
                if ((direction > 0 ? s.At(1).Close < z.Bottom - .5 : s.At(1).Close > z.Top + .5) || age < 0 || s.Count - age > 500)
                { z.Retired = true; Note(6, "SCALP_ZONE_INVALIDATED", z.Key, "closed_distal_or_expiry"); }
                else if (z.Touched) return;
            }
            var next = ScalpFind(direction); if (next == null) return;
            double mid = (_tick.Bid + _tick.Ask) / 2;
            if (z != null && !z.Retired && ScalpDistance(mid, next.Bottom, next.Top) >= ScalpDistance(mid, z.Bottom, z.Top)) return;
            _scalpArmed.Add(next.Key); _scalpZones[slot] = next;
            Note(6, "SCALP_ZONE_ARMED", next.Key, "nearest_valid;bottom=" + N(next.Bottom) + ";top=" + N(next.Top));
        }
        private void OnStrategyScalpingTick()
        {
            if (!_options.EnableScalping) return;
            var s = _series[300]; if (s.Current == null || s.Count < 213) return;
            // MT5 starts acquiring on the first arriving tick, using already-closed history only.
            bool newBar = _scalpClock != s.Current.Time;
            if (newBar) { _scalpClock = s.Current.Time; ScalpRefresh(0); ScalpRefresh(1); }
            double mid = (_tick.Bid + _tick.Ask) / 2;
            foreach (var z in _scalpZones)
                if (z != null && !z.Retired && !z.Touched && mid >= z.Bottom && mid <= z.Top)
                { z.Touched = true; z.TouchBar = s.Current.Time; Note(6, "SCALP_FIRST_TOUCH", z.Key, "mid_quote;bar=" + z.TouchBar); }
            if (!newBar) return;
            ScalpZone selected = null;
            foreach (var z in _scalpZones)
                if (z != null && !z.Retired && z.Touched && z.TouchBar == s.At(1).Time &&
                    (selected == null || ScalpDistance(mid, z.Bottom, z.Top) < ScalpDistance(mid, selected.Bottom, selected.Top))) selected = z;
            if (selected == null) return;
            selected.Retired = true; // same native consume-on-first-closed-decision, even if rejected
            if (!ScalpReversal(s.At(1), s.At(2), selected.Direction, _options.TickSize))
            { Note(6, "SCALP_REVERSAL_REJECT", selected.Key, "closed_directional_engulf_or_wick"); return; }
            double entry = selected.Direction > 0 ? _tick.Ask : _tick.Bid;
            Emit(new Signal { StrategyId = 6, Direction = selected.Direction, Trigger = Now,
                Expires = s.Current.Time + 300, Reference = entry, Stop = entry - selected.Direction * 5.0,
                Target = entry + selected.Direction * 5.0, Atr = ScalpAtr(1), Structure = selected.Key,
                Key = selected.Key + "_" + s.At(1).Time, Path = "USER_SCALP_M5_WICK_ZONE", Family = selected.Key,
                TimeframeSeconds = 300, Detail = "signal_only;daily_6_6_requires_complete_net_trade_ledger;fixed_price_SLTP=5.00" }, false);
        }
        private bool ValidateStrategyScalping(Signal s, out string reason)
        {
            reason = "SCALP_SIGNAL_IDENTITY_INVALID";
            if (!_options.EnableScalping || s.StrategyId != 6 || !_known.ContainsKey(s.Key) ||
                !s.Structure.StartsWith("SCALP_", StringComparison.Ordinal) || !Finite(s.Target)) return false;
            reason = "VALID_SIGNAL_ONLY_EXECUTION_GATES_SEPARATE"; return true;
        }

        // Deliberately order-independent complete-trade ledger specification. It does not
        // pretend that a signal generator has actual fills or fees. Native EA independently
        // reconstructs the same invariants from MT5 history before each request.
        public sealed class ScalpLedgerDeal
        {
            public string DealId, PositionId, SetupId;
            public long CloseServerDay;
            public double InVolume, OutVolume, Cash;
            public bool Owned = true, FeesKnown = true, PositionLive;
            public bool EntryOrderFinal = true;
            public double EntryOrderInitialVolume = .01, EntryOrderRemainingVolume;
        }
        public sealed class ScalpLedgerResult { public int Wins, Losses, Zero; public bool Valid = true, Locked; public string Reason = ""; }
        public static ScalpLedgerResult EvaluateScalpLedger(IEnumerable<ScalpLedgerDeal> deals, long serverDay, bool stickyDailyLock = false)
        {
            var result = new ScalpLedgerResult { Locked = stickyDailyLock };
            var unique = new Dictionary<string, ScalpLedgerDeal>();
            foreach (var d in deals)
            {
                if (string.IsNullOrEmpty(d.DealId) || string.IsNullOrEmpty(d.PositionId) || string.IsNullOrEmpty(d.SetupId) || !d.Owned || !d.FeesKnown || !Finite(d.Cash) || !Finite(d.InVolume) || !Finite(d.OutVolume) || d.InVolume < 0 || d.OutVolume < 0)
                { result.Valid = false; result.Reason = "OWNERSHIP_OR_COST_UNRESOLVED"; return result; }
                if (unique.TryGetValue(d.DealId, out var p))
                {
                    if (p.PositionId != d.PositionId || p.SetupId != d.SetupId || p.CloseServerDay != d.CloseServerDay || p.InVolume != d.InVolume || p.OutVolume != d.OutVolume || p.Cash != d.Cash || p.PositionLive != d.PositionLive || p.EntryOrderFinal != d.EntryOrderFinal || p.EntryOrderInitialVolume != d.EntryOrderInitialVolume || p.EntryOrderRemainingVolume != d.EntryOrderRemainingVolume)
                    { result.Valid = false; result.Reason = "CONFLICTING_DUPLICATE"; return result; }
                }
                else unique.Add(d.DealId, d);
            }
            foreach (var setup in unique.Values.GroupBy(d => d.SetupId))
            {
                var order = setup.First();
                if (setup.Any(d => !d.EntryOrderFinal || d.EntryOrderInitialVolume != order.EntryOrderInitialVolume || d.EntryOrderRemainingVolume != order.EntryOrderRemainingVolume) ||
                    !Finite(order.EntryOrderInitialVolume) || !Finite(order.EntryOrderRemainingVolume) || order.EntryOrderInitialVolume <= 0 || order.EntryOrderRemainingVolume < 0 ||
                    Math.Abs(order.EntryOrderInitialVolume - order.EntryOrderRemainingVolume - setup.Sum(d => d.InVolume)) > 1e-8)
                { result.Valid = false; result.Reason = "ORIGINAL_ORDER_NOT_TERMINAL_OR_QUANTITY_INCOMPLETE"; return result; }
                bool complete = true;
                foreach (var position in setup.GroupBy(d => d.PositionId))
                {
                    double vin = position.Sum(d => d.InVolume), vout = position.Sum(d => d.OutVolume);
                    if (vin <= 0 || vout > vin + 1e-8) { result.Valid = false; result.Reason = "INCOMPLETE_OWNERSHIP_HISTORY"; return result; }
                    if (position.Any(d => d.PositionLive) || Math.Abs(vin - vout) > 1e-8) complete = false;
                }
                if (!complete || setup.Max(d => d.CloseServerDay) != serverDay) continue;
                double net = setup.Sum(d => d.Cash);
                if (net > 0.0000001) result.Wins++; else if (net < -0.0000001) result.Losses++; else result.Zero++;
            }
            result.Locked |= result.Wins >= 6 || result.Losses >= 6; return result;
        }
        public static IReadOnlyList<string> RunScalpingSemanticTests()
        {
            var passed = new List<string>(); Action<bool,string> check = (ok,name) => { if (!ok) throw new Exception("Scalping fixture: " + name); passed.Add(name); };
            var b = new Bar { Open = 103, Close = 106, Low = 102, High = 107 };
            check(ScalpWickWidth(b,1) == 1, "wick_shorter_than_3_uses_whole_wick");
            b.Low=97; check(ScalpWickWidth(b,1)==3, "wick_caps_at_3_price");
            b.Low=103; check(ScalpWickWidth(b,1)==0, "zero_wick_has_no_zone");
            check(ScalpDistance(10,9,11)==0 && ScalpDistance(8,9,11)==1, "nearest_is_interval_distance");
            var p = new Bar { Open=103, Close=102, Low=101, High=104 };
            var e = new Bar { Open=102, Close=103, Low=101, High=104 };
            check(ScalpReversal(e,p,1,.01), "closed_bull_engulf");
            check(!ScalpReversal(p,e,1,.01), "wrong_direction_rejected");
            Func<int,double,long,List<ScalpLedgerDeal>> trade = (id,net,day) => new List<ScalpLedgerDeal> {
                new ScalpLedgerDeal { DealId="i"+id,PositionId="p"+id,SetupId="s"+id,InVolume=.01,Cash=-.04,CloseServerDay=day-86400 },
                new ScalpLedgerDeal { DealId="o"+id,PositionId="p"+id,SetupId="s"+id,OutVolume=.01,Cash=net+.04,CloseServerDay=day } };
            long day=864000; var rows=new List<ScalpLedgerDeal>();
            for(int i=0;i<6;i++) rows.AddRange(trade(i,i%2==0?1:-1,day));
            var r=EvaluateScalpLedger(rows,day); check(r.Wins==3&&r.Losses==3&&!r.Locked,"three_wins_three_losses_not_lock");
            for(int i=6;i<9;i++) rows.AddRange(trade(i,1,day));
            r=EvaluateScalpLedger(rows,day); check(r.Wins==6&&r.Losses==3&&r.Locked,"cumulative_six_wins_not_streak");
            check(!EvaluateScalpLedger(rows,day+86400).Locked,"next_server_day_rebuild_resets_day_only");
            check(EvaluateScalpLedger(rows,day,true).Locked,"restart_sticky_lock");
            rows=new List<ScalpLedgerDeal>(); for(int i=0;i<6;i++) rows.AddRange(trade(i,-1,day));
            check(EvaluateScalpLedger(rows,day).Locked,"six_losses_lock");
            check(EvaluateScalpLedger(trade(1,0,day),day).Zero==1,"net_zero_not_win_or_loss");
            check(EvaluateScalpLedger(trade(1,-.01,day),day).Losses==1,"entry_and_exit_costs_can_flip_price_win");
            rows=trade(1,1,day); rows[1].OutVolume=.005;
            check(EvaluateScalpLedger(rows,day).Wins==0,"partial_close_not_complete");
            rows.Add(new ScalpLedgerDeal {DealId="o2",PositionId="p1",SetupId="s1",OutVolume=.005,Cash=0,CloseServerDay=day+86400});
            check(EvaluateScalpLedger(rows,day).Wins==0&&EvaluateScalpLedger(rows,day+86400).Wins==1,"cross_day_last_partial_owns_count");
            rows=trade(1,1,day); rows.Add(rows[1]); check(EvaluateScalpLedger(rows,day).Wins==1,"duplicate_callback_idempotent");
            rows[0].FeesKnown=false; check(!EvaluateScalpLedger(rows,day).Valid,"unknown_cost_blocks_new_scalp_risk");
            rows=trade(1,1,day); rows.RemoveAt(0); check(!EvaluateScalpLedger(rows,day).Valid,"exit_without_entry_never_counted");
            rows=trade(1,1,day); rows[1].PositionLive=true; check(EvaluateScalpLedger(rows,day).Wins==0,"live_remainder_never_complete");
            rows=trade(1,1,day); foreach(var d in rows) { d.EntryOrderFinal=false;d.EntryOrderInitialVolume=.02;d.EntryOrderRemainingVolume=.01; }
            check(!EvaluateScalpLedger(rows,day).Valid&&EvaluateScalpLedger(rows,day).Wins==0,"first_closed_partial_of_active_original_order_never_counts");
            rows=trade(1,1,day); foreach(var d in rows)d.EntryOrderInitialVolume=.02;
            check(!EvaluateScalpLedger(rows,day).Valid,"terminal_order_missing_late_entry_deal_refused");
            var tail=trade(2,-2,day);foreach(var d in tail) {d.SetupId="s1";d.EntryOrderInitialVolume=.02;}rows.AddRange(tail);
            var grouped=EvaluateScalpLedger(rows,day);check(grouped.Valid&&grouped.Wins==0&&grouped.Losses==1,"one_original_order_multiple_positions_net_grouped_once");
            rows=trade(1,1,day);foreach(var d in rows){d.EntryOrderInitialVolume=.02;d.EntryOrderRemainingVolume=.01;}
            check(EvaluateScalpLedger(rows,day).Wins==1,"terminal_cancelled_remainder_counts_only_actual_fills");
            rows=trade(1,1,day);rows[0].InVolume=double.NaN;check(!EvaluateScalpLedger(rows,day).Valid,"nonfinite_volume_refused");
            return passed;
        }
    }
}
