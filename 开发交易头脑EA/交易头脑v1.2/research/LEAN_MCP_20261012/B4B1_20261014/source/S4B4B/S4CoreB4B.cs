using System;
using System.Collections.Generic;
using System.Linq;
using TradingBrain.C7;

// S4 retained-version (TB500_S4_BE125) execution lifecycle, ported from the MQL5 source.
// Pure C#: no QuantConnect types, so the LEAN algorithm and the fixtures run the same code.
// Source: outputs/TradingBrain_I11_Seven_Strategies_20261004/MT5/S4/TB500_S4_BE125/TB500_S4_BE125.mq5
// SHA256 f6abe1abc8d9cfca27e6483f344aab03110b9df11b8d1b458e3fce432d63be47 (read-only reference).
// Line references below are to that file. Anything not in that file is labelled as an assumption.
// B4B1 FORK of frozen lean/algorithms/S4/S4Core.cs (ee509e1d...). Only differences (see S4CoreB4B.diff):
// namespace; EntryQuote; PendingEntryDeadlineMs; EntryQuoteAtDeadline hook; ProcessDue entry branch;
// ExecuteEntry takes the quote explicitly; an ENTRY_MODEL_TIMES trace record. Hook null == original semantics.
namespace TradingBrain.S4B4B
{
    public sealed class S4Config
    {
        // ---- MQ5 input defaults, confirmed one by one from the source ----
        public double InitialCapital = 500;          // user batch scope (tester deposit)
        public double RiskPct = 2.0;                 // InpRiskS4
        public double PortfolioRiskPct = 2.0;        // InpPortfolioRiskPct
        public double EquityRiskPct = 3.0;           // InpEquityRiskPct
        public double MarginPct = 25;                // InpMarginPct
        public double DayLossPct = 3.0;              // InpDayLossPct (mapped UTC day, not FxPro server day)
        public double EmergencyDDPct = 10.0;         // InpEmergencyDDPct
        public double MaxSpreadPrice = 0.50;         // InpMaxSpreadPrice
        public double MaxSpreadSLFraction = 0.15;    // InpMaxSpreadSLFraction
        public int SlippageReserveTicks = 2;         // InpSlippageReserveTicks
        public double RoundTurnCostPerLot = 10.0;    // InpRoundTurnCostPerLot (sizing allowance, not the fee ledger)
        public double HoldCostPerLot = 5.0;          // InpHoldCostPerLot (sizing allowance)
        public int MaxDailyTrades = 0;               // InpMaxDailyTrades (0 = off)
        public bool UseBreakEven = true;             // InpUseBreakEven
        public double BETriggerR = 1.25;             // InpBETriggerR
        public bool UseATRTrail = false;             // InpUseATRTrail (off; not ported)
        public bool UsePartial = false;              // InpUsePartial (off; not ported)
        public int ManagedEngine = 4;                // InpManagedEngine == sid+1 for S4 (sid 3)
        public int Slots = 2;                        // g_slots[3] (line 85)
        public double RewardRisk = 1.5;              // RiskGate rr = sid==3 ? 1.5 : 2.0 (line 2973)
        public double ChaseAtr = 0.25;               // directional adverse-only check for sid 3 (line 2967)
        public int LossStreakForCooldown = 3;        // RebuildStats (line 2798)
        public long CooldownSeconds = 3 * 300;       // 3 x PERIOD_M5 for sid 3
        public long MaxQuoteAgeSeconds = 10;         // InpMaxQuoteAgeSeconds (always satisfied by tick replay)

        // ---- Contract: mt5_iteration9 native_raw/contract.csv (captured 2026-10-04, snapshot_is_historical=0) ----
        public double TickSize = 0.01, Point = 0.01, ContractSize = 100, VolumeMin = 0.01, VolumeStep = 0.01, VolumeMax = 500;
        public int StopsLevelPoints = 0, FreezeLevelPoints = 0;

        // ---- Engineering assumptions (labelled; not broker parity) ----
        public double Leverage = 1000;               // nominal user leverage; margin = lots*100*price/1000 (ASSUMED model)
        public double StopOutLevelPct = 100;         // ASSUMED (account SO levels not exported); percent mode
        public double CommissionPerLotSide = 3.5;    // OBSERVED in MT5 tester deals (0.04/0.01 lot, 0.07/0.02 lot); not live-calibrated
        public long LatencyMs = 0;                   // request delay model; 0 = execute on the deciding quote
        public bool ProtectiveFillAtLevel = false;   // false = SL/TP fill at the triggering quote (ASSUMED tester semantics)
    }

    public sealed class S4Quote { public long ServerMs, UtcMs; public double Bid, Ask; public long Now => ServerMs / 1000; }

    public sealed class S4Fill { public bool Filled; public double SignedLots, Price, Fee; public long OrderId; public string Status = ""; }

    public interface IS4Broker { S4Fill Execute(S4Book book, double signedLots, double expectedPrice, string tag); }
    public interface IS4Trace { void Write(string stream, object record); }

    public sealed class S4Action { public int Kind; public double Volume, Sl; public string Tag = ""; public long DueMs; }

    // One MT5 hedging position (= one S4 slot). LEAN holds only the net quantity; this book is
    // the slot ledger, and every number in it comes from a real QC fill (price, quantity, fee).
    public sealed class S4Book
    {
        public int Id; public string Setup = "", Structure = ""; public int Direction;
        public double PlannedEntry, RequestSl, RequestTp, RequestVolume, RequestBudget, RequestRisk, RequestMargin;
        public long ReservedMs, DueMs;
        public bool Pending, Open, Closed, Rejected, EntryRiskVerified;
        public double EntryPrice, InitialSl, Sl, Tp, InitialVolume, Volume, ClosedVolume, InitialR;
        public double EntryCommission, ExitCommission, Gross, Swap;
        public long EntryMs, ExitMs; public string ExitReason = "";
        public S4Action PendingManage; public long ManageRetryUntil;
        public double Mae, Mfe; public int SlModifications; public List<long> OrderIds = new List<long>();
        public double Net => Gross - EntryCommission - ExitCommission + Swap;
        public double Budget => RequestVolume > 0 ? RequestBudget * InitialVolume / RequestVolume : 0; // SyncBook line 2755
    }

    public sealed class S4Plan { public double Entry, Sl, Tp, Volume, Risk, Budget, Margin, Unit, Distance, Spread; }

    // B4B1: the effective quote state as of the 250 ms deadline (all rows with ms <= deadline applied in raw order),
    // captured by the algorithm BEFORE applying the first row with ms > deadline. Provenance fields are evidence only.
    public sealed class EntryQuote
    {
        public double Bid, Ask; public bool Ready;
        public long DeadlineMs, QuoteRowMs, QuoteRowSequence, CrossingRowMs, CrossingRowSequence;
        public int QuoteRowOrdinalInMs, DeadlineRows;
        public bool Valid => Ready && Bid > 0 && Ask >= Bid;
    }

    public static class S4Math
    {
        public static double Profit(S4Config c, int dir, double lots, double entry, double exit) => dir * (exit - entry) * c.ContractSize * lots;
        // RoundPrice line 2646: direction>0 rounds up, otherwise down, to tick.
        public static double RoundPrice(S4Config c, double price, int direction)
        {
            double t = c.TickSize;
            double n = direction > 0 ? Math.Ceiling(price / t - 1e-9) : Math.Floor(price / t + 1e-9);
            return Math.Round(n * t, 2);
        }
        public static double FloorVolume(S4Config c, double v) => Math.Round(Math.Floor((v + 1e-12) / c.VolumeStep) * c.VolumeStep, 8);
        public static bool LegalVolume(S4Config c, double v) => c.VolumeStep > 0 && v >= c.VolumeMin - 1e-9 && v <= c.VolumeMax + 1e-9 && Math.Abs(v - FloorVolume(c, v)) < 1e-8;
        public static double PerLotCost(S4Config c) => c.RoundTurnCostPerLot + c.HoldCostPerLot;
        // InitialRisk line 2651: stressed entry +dir*slip, stop -dir*slip, plus per-lot allowance.
        public static double InitialRisk(S4Config c, int dir, double lots, double entry, double sl, bool stressEntry)
        {
            double t = c.TickSize * c.SlippageReserveTicks;
            double p = Profit(c, dir, lots, entry + (stressEntry ? dir * t : 0), sl - dir * t);
            return Math.Max(0.0, -p) + PerLotCost(c) * lots;
        }
        // StopsValid line 2670.
        public static bool StopsValid(S4Config c, int dir, double entry, double sl, double tp, double bid, double ask, bool modify)
        {
            double level = c.StopsLevelPoints * c.Point;
            if (modify) level = Math.Max(level, c.FreezeLevelPoints * c.Point);
            double market = dir > 0 ? bid : ask;
            if (sl <= 0 || tp <= 0 || entry <= 0 || (dir * (entry - sl) <= 0 && !modify)) return false;
            double min = Math.Max(level, c.TickSize) - 1e-8;
            return !(dir * (market - sl) < min || dir * (tp - market) < min);
        }
        public static double Margin(S4Config c, double lots, double price) => lots * c.ContractSize * price / c.Leverage; // ASSUMED model
        public static double Commission(S4Config c, double lots) => Math.Ceiling(Math.Round(Math.Abs(lots) * c.CommissionPerLotSide * 100, 6)) / 100;
    }

    // UpdateAccountGuard (line 2878) restricted to the tester path without cash flows.
    public sealed class S4AccountGuard
    {
        readonly S4Config c;
        public bool Emergency, DailyLock, BaselineKnown;
        public double Peak, PeakDDPct, DayBaseline, DayDDPct;
        public long DayId = -1; public int DailyLocks, DayStarts;
        double lastEquity; long lastEquityMs;
        public S4AccountGuard(S4Config config) { c = config; Peak = c.InitialCapital; } // equity.adjusted_peak seeded with initial equity
        public void Update(double equity, long serverMs, long utcMs, IS4Trace trace)
        {
            if (equity > Peak) Peak = equity;
            PeakDDPct = Peak > 0 ? Math.Max(0.0, (Peak - equity) / Peak * 100) : 0;
            if (PeakDDPct >= c.EmergencyDDPct && !Emergency)
            {
                Emergency = true; // persistent emergency.lock
                trace?.Write("protection", new { server_msc = serverMs, @event = "EMERGENCY_EQUITY_STOP", dd_pct = PeakDDPct, equity, peak = Peak });
            }
            long day = (long)Math.Floor(utcMs / 1000.0 / 86400.0);
            if (day != DayId)
            {
                bool first = DayId < 0;
                bool observed = !first && lastEquityMs > 0 && serverMs >= lastEquityMs; // PureCashTesterDayAnchor
                DayBaseline = first ? c.InitialCapital : (observed ? lastEquity : 0);
                DailyLock = false; DayId = day; DayStarts++;
                trace?.Write("protection", new { server_msc = serverMs, @event = DayBaseline > 0 ? "RISK_DAY_START" : "DAY_BASELINE_UNKNOWN", baseline = DayBaseline, utc_day = day });
            }
            BaselineKnown = DayBaseline > 0;
            DayDDPct = DayBaseline > 0 ? Math.Max(0.0, (DayBaseline - equity) / DayBaseline * 100) : 0;
            if (BaselineKnown && DayDDPct >= c.DayLossPct && !DailyLock)
            {
                DailyLock = true; DailyLocks++;
                trace?.Write("protection", new { server_msc = serverMs, @event = "DAILY_EQUITY_STOP", day_dd_pct = DayDDPct, baseline = DayBaseline, equity });
            }
            lastEquity = equity; lastEquityMs = serverMs;
        }
        public void Capture(double equity, long serverMs) { lastEquity = equity; lastEquityMs = serverMs; }
    }

    public sealed class S4Core
    {
        public const int Sid = 3;
        readonly S4Config c; readonly IS4Broker broker; readonly IS4Trace trace;
        public readonly List<S4Book> Books = new List<S4Book>();
        readonly List<Signal> queue = new List<Signal>();
        readonly HashSet<string> consumed = new HashSet<string>(StringComparer.Ordinal);
        readonly Dictionary<string, string> lastDecision = new Dictionary<string, string>(StringComparer.Ordinal);
        public readonly Dictionary<string, long> DecisionReasons = new Dictionary<string, long>(StringComparer.Ordinal);
        public readonly Dictionary<string, long> Events = new Dictionary<string, long>(StringComparer.Ordinal);
        S4Book request; int nextId = 1; int lossStreak;
        public int MaxLossStreak; public long CooldownUntil; public long Ticks, ArmedSignals;
        public S4Quote Q { get; private set; }
        public readonly S4AccountGuard Guard;
        // Invoked after a fill has been fully applied to the slot ledger (never between the
        // broker fill and the ledger update), so reconciliation sees a consistent state.
        public Action<string> AfterFillApplied;
        public double CurvePeak, MaxEquityDD, MaxEquityDDPct;

        public S4Core(S4Config config, IS4Broker broker, IS4Trace trace)
        { c = config; this.broker = broker; this.trace = trace; Guard = new S4AccountGuard(c); CurvePeak = c.InitialCapital; }

        public S4Config Config => c;
        void Count(string key) => Events[key] = Events.TryGetValue(key, out var n) ? n + 1 : 1;

        public double Balance => c.InitialCapital + Books.Sum(b => b.Gross + b.Swap - b.EntryCommission - b.ExitCommission);
        public double Floating(double bid, double ask) => Books.Where(b => b.Open).Sum(b => S4Math.Profit(c, b.Direction, b.Volume, b.EntryPrice, b.Direction > 0 ? bid : ask));
        public double Equity => Balance + Floating(Q.Bid, Q.Ask); // MT5 equity: long marked at bid, short at ask
        public double OpenSignedLots => Books.Where(b => b.Open).Sum(b => b.Direction * b.Volume);

        // Expected LEAN CFD portfolio value from the slot ledger, per LEAN source:
        // SecurityPortfolioManager adds Holdings.UnrealizedProfit for CFDs; UnrealizedProfit is
        // SecurityHolding.TotalCloseProfit(includeFees: true): the NET holding valued on one side
        // (net long at bid, net short at ask) minus the estimated market-order liquidation fee.
        // Hedged slots priced at that single side sum to the same unrealized value (linear).
        public (double netSidePrice, double ledgerAtNetSide, double liquidationFee, double expectedLeanValue) LeanCfdExpectation(double bid, double ask)
        {
            double net = Math.Round(OpenSignedLots, 8);
            if (net == 0) return (0, Balance + Floating(bid, bid), 0, Balance + Floating(bid, bid)); // not invested: no unrealized, no fee
            double side = net > 0 ? bid : ask, atSide = Balance + Floating(side, side), fee = S4Math.Commission(c, net);
            return (side, atSide, fee, atSide - fee);
        }
        public bool RequestActive => request != null;
        // B4B1: deadline of the pending entry request (null when none); the hook supplies the deadline quote.
        public long? PendingEntryDeadlineMs => request?.DueMs;
        public Func<S4Book, EntryQuote> EntryQuoteAtDeadline;

        // ------------------------------------------------------------------ tick
        // Native order: server-side SL/TP and delayed requests are resolved by the tester before
        // OnTick; OnTick = Reconcile, UpdateAccountGuard, PortfolioSnapshot, ManagePositions,
        // scanners, ExecuteQueue, CaptureEquity (lines 3197-3206). Management precedes new risk.
        public void Step(long serverMs, long utcMs, double bid, double ask,
                         Func<IReadOnlyList<Signal>> scan, Func<Signal, string> validate, Action<Signal> consume)
        {
            if (Q != null && serverMs < Q.ServerMs) throw new InvalidOperationException("Quote time moved backward.");
            Q = new S4Quote { ServerMs = serverMs, UtcMs = utcMs, Bid = bid, Ask = ask }; Ticks++;
            ProcessDue();
            ServerProtection();
            Guard.Update(Equity, serverMs, utcMs, trace);
            ManagePositions();
            foreach (var s in scan()) Arm(s);
            ExecuteQueue(validate, consume);
            CaptureEquity();
        }

        void Arm(Signal s)
        {
            if (s.StrategyId != Sid) throw new InvalidOperationException("S4 core received a non-S4 signal.");
            if (IsConsumed(s) || queue.Any(x => x.Key == s.Key)) return;
            queue.Add(s); ArmedSignals++;
            trace?.Write("signals", new { server_msc = Q.ServerMs, @event = "ARMED", key = s.Key, structure = s.Structure, direction = s.Direction, trigger = s.Trigger, expires = s.Expires, reference = s.Reference, sl = s.Stop, atr = s.Atr, gate = s.GateDetail, bid = Q.Bid, ask = Q.Ask });
        }

        bool IsConsumed(Signal s) => consumed.Contains(s.Structure) || (!string.IsNullOrEmpty(s.Family) && consumed.Contains(s.Family));

        // PortfolioSnapshot line 2914 (own positions + held request reservation).
        public (double initial, double equityRisk, int active, double reserved, double used) Snapshot()
        {
            double initial = 0, eqRisk = 0, reserved = 0, used = 0; int active = 0; double slip = c.TickSize * c.SlippageReserveTicks;
            foreach (var b in Books.Where(x => x.Open))
            {
                active++;
                double atsl = S4Math.Profit(c, b.Direction, b.Volume, b.EntryPrice, b.Sl - b.Direction * slip);
                double cur = S4Math.Profit(c, b.Direction, b.Volume, b.EntryPrice, b.Direction > 0 ? Q.Bid : Q.Ask);
                double costs = b.Volume * S4Math.PerLotCost(c);
                initial += Math.Max(0.0, -atsl) + costs; eqRisk += Math.Max(0.0, cur - atsl) + costs;
                used += S4Math.Margin(c, b.Volume, b.EntryPrice);
            }
            if (request != null) { active++; initial += request.RequestRisk; eqRisk += request.RequestRisk; reserved += request.RequestMargin; }
            return (initial, eqRisk, active, reserved, used);
        }

        public string AccountGate()
        {
            if (Guard.Emergency) return "EMERGENCY_EQUITY_STOP";
            if (Guard.DailyLock) return "DAILY_EQUITY_STOP";
            if (!Guard.BaselineKnown) return "DAY_BASELINE_UNKNOWN";
            return null;
        }

        // RiskGate lines 2956-3000 after Valid15.
        public string OrderGate(Signal s, out S4Plan plan)
        {
            plan = null; int dir = s.Direction;
            var snap = Snapshot();
            if (request != null) return "REQUEST_UNKNOWN";
            if (snap.active >= c.Slots) return "STRATEGY_SLOT_FULL";
            if (Q.Now < CooldownUntil) return "STRATEGY_COOLDOWN";
            if (c.MaxDailyTrades > 0) return "MAX_DAILY_TRADES_NOT_PORTED";
            double entry = dir > 0 ? Q.Ask : Q.Bid;
            if (s.Atr <= 0 || dir * (entry - s.Reference) > c.ChaseAtr * s.Atr) return "ENTRY_PRICE_DEVIATION";
            double sl = S4Math.RoundPrice(c, s.Stop, -dir), distance = dir * (entry - sl);
            if (distance <= 0) return "INVALID_STOPS";
            double spread = Q.Ask - Q.Bid;
            if (spread > c.MaxSpreadPrice) return "SPREAD_TOO_HIGH_ABSOLUTE";
            if (spread > c.MaxSpreadSLFraction * distance) return "SPREAD_TOO_HIGH_RELATIVE";
            double tp = s.Target > 0 ? S4Math.RoundPrice(c, s.Target, -dir) : S4Math.RoundPrice(c, entry + dir * c.RewardRisk * distance, dir);
            if (!S4Math.StopsValid(c, dir, entry, sl, tp, Q.Bid, Q.Ask, false)) return "INVALID_STOPS";
            double minvol = c.VolumeMin;
            double unit = S4Math.InitialRisk(c, dir, minvol, entry, sl, true);
            if (!S4Math.LegalVolume(c, minvol) || unit <= 0) return "RISK_CALC_FAILED";
            double balance = Balance, equity = Equity, capital = Math.Min(balance, equity);
            if (capital <= 0 || equity <= 0) return "EQUITY_INVALID";
            double budget = capital * c.RiskPct / 100;
            double remainingInitial = capital * c.PortfolioRiskPct / 100 - snap.initial, remainingEquity = equity * c.EquityRiskPct / 100 - snap.equityRisk;
            if (unit > budget + 1e-8) return "MIN_LOT_OVER_RISK";
            double available = Math.Min(budget, Math.Min(remainingInitial, remainingEquity));
            if (available < unit) return "ORDER_BLOCKED_BY_PORTFOLIO_RISK";
            double volume = S4Math.FloorVolume(c, available / (unit / minvol));
            volume = Math.Min(volume, S4Math.FloorVolume(c, c.VolumeMax)); // InpLotMode = AUTO_RISK: no lot cap
            if (!S4Math.LegalVolume(c, volume)) return "MIN_LOT_OVER_RISK";
            double risk = S4Math.InitialRisk(c, dir, volume, entry, sl, true);
            if (risk > budget + 1e-8) return "SINGLE_TRADE_RISK_EXCEEDED";
            if (risk > remainingInitial + 1e-8 || risk > remainingEquity + 1e-8) return "ORDER_BLOCKED_BY_PORTFOLIO_RISK";
            // OrderCalcMargin/OrderCheck: ASSUMED nominal-leverage model; ck.margin taken as total after the order (conservative).
            double margin = S4Math.Margin(c, volume, entry), ckMargin = snap.used + margin, freeMargin = equity - ckMargin;
            if (equity <= 0 || ckMargin + snap.reserved > equity * c.MarginPct / 100 || freeMargin < snap.reserved) return "MARGIN_INSUFFICIENT";
            if (ckMargin > 0 && equity / (ckMargin + snap.reserved) * 100 <= c.StopOutLevelPct) return "STOPOUT_BUFFER_INSUFFICIENT";
            plan = new S4Plan { Entry = entry, Sl = sl, Tp = tp, Volume = volume, Risk = risk, Budget = budget, Margin = margin, Unit = unit, Distance = distance, Spread = spread };
            return null;
        }

        // ExecuteQueue line 3002 (single strategy: order by trigger).
        void ExecuteQueue(Func<Signal, string> validate, Action<Signal> consume)
        {
            foreach (var s in queue.OrderBy(x => x.Trigger).ThenBy(x => x.Key, StringComparer.Ordinal).ToList())
            {
                if (Q.Now >= s.Expires || IsConsumed(s)) continue;
                string why = AccountGate();
                if (why == null && (Q.Now >= s.Expires || s.Trigger > Q.Now)) why = "SETUP_EXPIRED";
                if (why == null) why = validate(s);           // native Valid15 for sid 3 via the I9 engine
                S4Plan plan = null;
                if (why == null) why = OrderGate(s, out plan);
                if (why != null)
                {
                    if (!lastDecision.TryGetValue(s.Key, out var prev) || prev != why)
                    {
                        lastDecision[s.Key] = why; DecisionReasons[why] = DecisionReasons.TryGetValue(why, out var n) ? n + 1 : 1;
                        var snap = Snapshot();
                        trace?.Write("decisions", new { server_msc = Q.ServerMs, key = s.Key, reason = why, equity = Equity, balance = Balance, initial_risk = snap.initial, equity_risk = snap.equityRisk, active = snap.active, bid = Q.Bid, ask = Q.Ask });
                    }
                    continue;
                }
                Reserve(s, plan, consume);
            }
            queue.RemoveAll(s => Q.Now >= s.Expires || IsConsumed(s));
        }

        void Reserve(Signal s, S4Plan p, Action<Signal> consume)
        {
            var b = new S4Book
            {
                Id = nextId++, Setup = s.Key, Structure = s.Structure, Direction = s.Direction, PlannedEntry = p.Entry, RequestSl = p.Sl, RequestTp = p.Tp,
                RequestVolume = p.Volume, RequestBudget = p.Budget, RequestRisk = p.Risk, RequestMargin = p.Margin,
                ReservedMs = Q.ServerMs, DueMs = Q.ServerMs + c.LatencyMs, Pending = true
            };
            Books.Add(b); request = b;
            consumed.Add(s.Structure); if (!string.IsNullOrEmpty(s.Family)) consumed.Add(s.Family);
            consume?.Invoke(s); // MarkUsed at reservation, before OrderSend (line 3014)
            DecisionReasons["RESERVED"] = DecisionReasons.TryGetValue("RESERVED", out var n) ? n + 1 : 1;
            trace?.Write("orders", new { server_msc = Q.ServerMs, @event = "RESERVED", book = b.Id, key = s.Key, planned_price = p.Entry, volume = p.Volume, sl = p.Sl, tp = p.Tp, risk = p.Risk, budget = p.Budget, unit_risk_min_lot = p.Unit, distance = p.Distance, spread = p.Spread, margin_model = p.Margin, due_msc = b.DueMs });
            if (c.LatencyMs <= 0) ExecuteEntry(b, Q.Bid, Q.Ask, null);
        }

        void ExecuteEntry(S4Book b, double bid, double ask, EntryQuote dq)
        {
            request = null; b.Pending = false;
            if (dq != null && !dq.Valid)
            {
                b.Rejected = true; Count("ENTRY_REJECT_INVALID_QUOTE_AT_DEADLINE");
                trace?.Write("orders", new { server_msc = Q.ServerMs, @event = "BROKER_REJECT_MODEL", book = b.Id, reason = "INVALID_QUOTE_AT_DEADLINE", bid, ask, deadline_msc = dq.DeadlineMs });
                return;
            }
            int dir = b.Direction; double price = dir > 0 ? ask : bid;
            if (!S4Math.StopsValid(c, dir, price, b.RequestSl, b.RequestTp, bid, ask, false))
            {
                b.Rejected = true; Count("ENTRY_REJECT_INVALID_STOPS_AT_EXECUTION");
                trace?.Write("orders", new { server_msc = Q.ServerMs, @event = "BROKER_REJECT_MODEL", book = b.Id, reason = "INVALID_STOPS_AT_EXECUTION", bid, ask });
                return;
            }
            var f = broker.Execute(b, dir * b.RequestVolume, price, "S4_ENTRY");
            if (f.OrderId > 0) b.OrderIds.Add(f.OrderId);
            if (!f.Filled)
            {
                b.Rejected = true; Count("ENTRY_NOT_FILLED");
                trace?.Write("orders", new { server_msc = Q.ServerMs, @event = "BROKER_REJECT", book = b.Id, status = f.Status, order_id = f.OrderId });
                return;
            }
            b.EntryPrice = f.Price; b.InitialVolume = b.Volume = Math.Abs(f.SignedLots); b.EntryCommission = f.Fee;
            b.InitialSl = b.Sl = b.RequestSl; b.Tp = b.RequestTp; b.Open = true; b.EntryMs = Q.ServerMs;
            b.InitialR = S4Math.InitialRisk(c, dir, b.InitialVolume, b.EntryPrice, b.InitialSl, false);
            Count("ENTRY_FILLED");
            trace?.Write("orders", new { server_msc = Q.ServerMs, @event = "ENTRY_FILLED", book = b.Id, order_id = f.OrderId, direction = dir, lots = b.Volume, price = f.Price, planned_price = b.PlannedEntry, fee = f.Fee, sl = b.Sl, tp = b.Tp, initial_r = b.InitialR, budget = b.Budget, latency_ms = Q.ServerMs - b.ReservedMs });
            if (dq != null)
                trace?.Write("orders", new { server_msc = Q.ServerMs, @event = "ENTRY_MODEL_TIMES", book = b.Id, order_id = f.OrderId, model_request_msc = b.ReservedMs, model_deadline_msc = dq.DeadlineMs,
                    quote_row_msc = dq.QuoteRowMs, quote_row_sequence = dq.QuoteRowSequence, quote_row_ordinal_in_ms = dq.QuoteRowOrdinalInMs, deadline_rows = dq.DeadlineRows,
                    crossing_row_msc = dq.CrossingRowMs, crossing_row_sequence = dq.CrossingRowSequence, engine_submit_msc = Q.ServerMs, engine_lag_ms = Q.ServerMs - dq.DeadlineMs,
                    deadline_bid = bid, deadline_ask = ask, submit_row_bid = Q.Bid, submit_row_ask = Q.Ask });
            AfterFillApplied?.Invoke("ENTRY order=" + f.OrderId);
        }

        // Server-side SL/TP (tester): long closes at bid, short at ask.
        void ServerProtection()
        {
            foreach (var b in Books.Where(x => x.Open).ToList())
            {
                int dir = b.Direction; double close = dir > 0 ? Q.Bid : Q.Ask;
                bool slHit = dir > 0 ? Q.Bid <= b.Sl : Q.Ask >= b.Sl;
                bool tpHit = dir > 0 ? Q.Bid >= b.Tp : Q.Ask <= b.Tp;
                if (!slHit && !tpHit) continue;
                string tag = tpHit ? "TP" : (b.SlModifications > 0 ? "SL_AFTER_BE" : "SL");
                double price = c.ProtectiveFillAtLevel ? (tpHit ? b.Tp : b.Sl) : close;
                trace?.Write("protection", new { server_msc = Q.ServerMs, @event = tag + "_TRIGGERED", book = b.Id, sl = b.Sl, tp = b.Tp, bid = Q.Bid, ask = Q.Ask, fill_rule = c.ProtectiveFillAtLevel ? "LEVEL" : "TRIGGER_QUOTE" });
                CloseVolume(b, b.Volume, price, tag);
            }
        }

        // ManagePositions lines 3056-3105 (partial/trail disabled by S4 defaults).
        void ManagePositions()
        {
            foreach (var b in Books.Where(x => x.Open).ToList())
            {
                int dir = b.Direction;
                if (Guard.Emergency) { RequestManage(b, 2, b.Volume, 0, "EMERGENCY"); continue; }
                double budget = b.Budget;
                if (!b.EntryRiskVerified && budget > 0)
                {
                    double actual = S4Math.InitialRisk(c, dir, b.Volume, b.EntryPrice, b.InitialSl, false);
                    if (actual > budget + 1e-8)
                    {
                        double safe = S4Math.FloorVolume(c, b.Volume * budget / actual), reduce = S4Math.FloorVolume(c, b.Volume - safe);
                        Count("ENTRY_RISK_OVERRUN");
                        trace?.Write("protection", new { server_msc = Q.ServerMs, @event = "ENTRY_RISK_OVERRUN", book = b.Id, actual_risk = actual, budget });
                        if (!S4Math.LegalVolume(c, safe) || !S4Math.LegalVolume(c, reduce)) reduce = b.Volume;
                        RequestManage(b, 2, reduce, 0, "ENTRY_RISK_OVERRUN");
                        continue;
                    }
                    b.EntryRiskVerified = true;
                }
                if (c.ManagedEngine != Sid + 1) continue;
                double rprice = Math.Abs(b.EntryPrice - b.InitialSl), price = dir > 0 ? Q.Bid : Q.Ask;
                if (rprice <= 0) continue;
                double achieved = dir * (price - b.EntryPrice) / rprice;
                double proposed = b.Sl;
                if (c.UseBreakEven && achieved >= c.BETriggerR)
                {
                    double delta = S4Math.Profit(c, dir, b.Volume, b.EntryPrice, b.EntryPrice + dir * c.TickSize);
                    if (delta > 0)
                    {
                        // Entry commission allocated to remaining volume + estimated half round-turn + accrued negative swap.
                        double accrued = Math.Max(0.0, -b.Swap);
                        double money = b.EntryCommission * (b.Volume / Math.Max(b.Volume, b.InitialVolume)) + c.RoundTurnCostPerLot * 0.5 * b.Volume + accrued;
                        double be = S4Math.RoundPrice(c, b.EntryPrice + dir * (money / delta * c.TickSize + c.SlippageReserveTicks * c.TickSize), dir);
                        if (dir * (be - proposed) > 0) proposed = be;
                    }
                }
                if (dir * (proposed - b.Sl) >= 2 * c.TickSize - 1e-8 && S4Math.StopsValid(c, dir, b.EntryPrice, proposed, b.Tp, Q.Bid, Q.Ask, true))
                    RequestManage(b, 1, 0, proposed, "PROTECTION");
            }
        }

        // ManageRequest line 3025: one request at a time per position; failure retries after 2 s.
        void RequestManage(S4Book b, int kind, double volume, double sl, string tag)
        {
            if (b.PendingManage != null || Q.Now < b.ManageRetryUntil) return;
            int dir = b.Direction;
            if (kind == 1)
            {
                if (!S4Math.StopsValid(c, dir, b.EntryPrice, sl, b.Tp, Q.Bid, Q.Ask, true)) return;
                if (b.Sl > 0 && dir * (sl - b.Sl) < c.TickSize - 1e-8) return;
            }
            else
            {
                volume = S4Math.FloorVolume(c, Math.Min(volume, b.Volume));
                if (!S4Math.LegalVolume(c, volume)) return;
                if (volume < b.Volume - 1e-8 && !S4Math.LegalVolume(c, b.Volume - volume)) return;
            }
            var a = new S4Action { Kind = kind, Volume = volume, Sl = sl, Tag = tag, DueMs = Q.ServerMs + c.LatencyMs };
            trace?.Write("protection", new { server_msc = Q.ServerMs, @event = tag + "_REQUESTED", book = b.Id, kind, volume, sl, old_sl = b.Sl, due_msc = a.DueMs, bid = Q.Bid, ask = Q.Ask });
            if (c.LatencyMs <= 0) Apply(b, a); else b.PendingManage = a;
        }

        void Apply(S4Book b, S4Action a)
        {
            b.PendingManage = null;
            if (!b.Open) { trace?.Write("protection", new { server_msc = Q.ServerMs, @event = "MANAGEMENT_ENDED_POSITION_CLOSED", book = b.Id, kind = a.Kind }); return; }
            if (a.Kind == 1)
            {
                if (!S4Math.StopsValid(c, b.Direction, b.EntryPrice, a.Sl, b.Tp, Q.Bid, Q.Ask, true))
                {
                    b.ManageRetryUntil = Q.Now + 2; Count("MANAGEMENT_REJECT_MODEL");
                    trace?.Write("protection", new { server_msc = Q.ServerMs, @event = "MANAGEMENT_REJECT_MODEL", book = b.Id, kind = 1, sl = a.Sl, bid = Q.Bid, ask = Q.Ask });
                    return;
                }
                double old = b.Sl; b.Sl = a.Sl; b.SlModifications++; Count("SL_MODIFIED_" + a.Tag);
                trace?.Write("protection", new { server_msc = Q.ServerMs, @event = "SL_MODIFIED", tag = a.Tag, book = b.Id, old_sl = old, new_sl = a.Sl, entry = b.EntryPrice, initial_sl = b.InitialSl });
            }
            else CloseVolume(b, Math.Min(a.Volume, b.Volume), b.Direction > 0 ? Q.Bid : Q.Ask, a.Tag);
        }

        void ProcessDue()
        {
            if (EntryQuoteAtDeadline == null) { if (request != null && request.DueMs <= Q.ServerMs) ExecuteEntry(request, Q.Bid, Q.Ask, null); }
            else if (request != null && request.DueMs < Q.ServerMs)   // B4B1: strictly after the deadline; quote = deadline state
            {
                var dq = EntryQuoteAtDeadline(request) ?? throw new InvalidOperationException("B4B1: deadline crossed without a captured deadline quote");
                ExecuteEntry(request, dq.Bid, dq.Ask, dq);
            }
            foreach (var b in Books.Where(x => x.Open && x.PendingManage != null && x.PendingManage.DueMs <= Q.ServerMs).ToList()) Apply(b, b.PendingManage);
        }

        void CloseVolume(S4Book b, double lots, double price, string tag)
        {
            var f = broker.Execute(b, -b.Direction * lots, price, "S4_" + tag);
            if (f.OrderId > 0) b.OrderIds.Add(f.OrderId);
            if (!f.Filled)
            {
                b.ManageRetryUntil = Q.Now + 2; Count("EXIT_NOT_FILLED");
                trace?.Write("orders", new { server_msc = Q.ServerMs, @event = "EXIT_NOT_FILLED", book = b.Id, tag, status = f.Status });
                return;
            }
            double filled = Math.Abs(f.SignedLots), gross = S4Math.Profit(c, b.Direction, filled, b.EntryPrice, f.Price);
            b.Gross += gross; b.ExitCommission += f.Fee; b.Volume = Math.Round(b.Volume - filled, 8); b.ClosedVolume += filled;
            Count("EXIT_" + tag);
            trace?.Write("orders", new { server_msc = Q.ServerMs, @event = "EXIT_FILLED", tag, book = b.Id, order_id = f.OrderId, lots = filled, price = f.Price, gross, fee = f.Fee, remaining = b.Volume });
            if (b.Volume <= 1e-9) { b.Open = false; b.Closed = true; b.ExitMs = Q.ServerMs; b.ExitReason = tag; OnClosed(b); }
            AfterFillApplied?.Invoke("EXIT " + tag + " order=" + f.OrderId);
        }

        // RebuildStats line 2792: net < -eps counts a loss; 3 in a row -> cooldown exit + 3 x M5; net > eps resets.
        void OnClosed(S4Book b)
        {
            const double epsilon = 0.005;
            if (b.Net < -epsilon) { lossStreak++; MaxLossStreak = Math.Max(MaxLossStreak, lossStreak); if (lossStreak >= c.LossStreakForCooldown) CooldownUntil = Math.Max(CooldownUntil, b.ExitMs / 1000 + c.CooldownSeconds); }
            else if (b.Net > epsilon) lossStreak = 0;
            b.Mae = Math.Min(b.Mae, b.Net); b.Mfe = Math.Max(b.Mfe, b.Net);
            trace?.Write("trades", new
            {
                position_id = b.Id, setup = b.Setup, direction = b.Direction, entry_msc = b.EntryMs, exit_msc = b.ExitMs, volume = b.InitialVolume,
                entry = b.EntryPrice, initial_sl = b.InitialSl, final_sl = b.Sl, tp = b.Tp, initial_r = b.InitialR, budget = b.Budget,
                gross = b.Gross, commission = b.EntryCommission + b.ExitCommission, swap = b.Swap, net = b.Net, exit_reason = b.ExitReason,
                sl_modifications = b.SlModifications, mae = b.Mae, mfe = b.Mfe, loss_streak_after = lossStreak, cooldown_until = CooldownUntil, order_ids = b.OrderIds
            });
        }

        void CaptureEquity()
        {
            double eq = Equity;
            foreach (var b in Books.Where(x => x.Open))
            {
                double life = b.Net + S4Math.Profit(c, b.Direction, b.Volume, b.EntryPrice, b.Direction > 0 ? Q.Bid : Q.Ask);
                b.Mae = Math.Min(b.Mae, life); b.Mfe = Math.Max(b.Mfe, life);
            }
            CurvePeak = Math.Max(CurvePeak, eq);
            double dd = Math.Max(0.0, CurvePeak - eq);
            MaxEquityDD = Math.Max(MaxEquityDD, dd); MaxEquityDDPct = Math.Max(MaxEquityDDPct, CurvePeak > 0 ? dd / CurvePeak * 100 : 0);
            Guard.Capture(eq, Q.ServerMs);
        }

        // Tester end: pending request cancelled, open positions closed at the last quote.
        public void End()
        {
            if (Q == null) return;
            if (request != null) { request.Pending = false; request.Rejected = true; trace?.Write("orders", new { server_msc = Q.ServerMs, @event = "REQUEST_CANCELLED_END_OF_SAMPLE", book = request.Id }); request = null; }
            foreach (var b in Books.Where(x => x.Open).ToList()) CloseVolume(b, b.Volume, b.Direction > 0 ? Q.Bid : Q.Ask, "END_OF_SAMPLE");
        }

        public object Summary()
        {
            var done = Books.Where(b => b.Closed).ToList();
            double pos = done.Where(b => b.Net > 0).Sum(b => b.Net), neg = -done.Where(b => b.Net < 0).Sum(b => b.Net);
            double commission = Books.Sum(b => b.EntryCommission + b.ExitCommission), rtLots = done.Sum(b => b.InitialVolume);
            return new
            {
                complete_positions = done.Count,
                wins = done.Count(b => b.Net > 0), losses = done.Count(b => b.Net < 0), zero_net = done.Count(b => b.Net == 0),
                net_usd = Balance - c.InitialCapital, ending_balance = Balance,
                gross_profit_usd = pos, gross_loss_usd = neg, profit_factor = neg > 0 ? (double?)(pos / neg) : null,
                win_rate_pct = done.Count > 0 ? (double?)(done.Count(b => b.Net > 0) * 100.0 / done.Count) : null,
                avg_win_usd = done.Any(b => b.Net > 0) ? (double?)done.Where(b => b.Net > 0).Average(b => b.Net) : null,
                avg_loss_usd = done.Any(b => b.Net < 0) ? (double?)done.Where(b => b.Net < 0).Average(b => b.Net) : null,
                commission_usd = commission, swap_usd = Books.Sum(b => b.Swap), matched_round_trip_lots = rtLots,
                commission_usd_per_round_trip_lot = rtLots > 0 ? (double?)(done.Sum(b => b.EntryCommission + b.ExitCommission) / rtLots) : null,
                max_equity_dd_usd = MaxEquityDD, max_equity_dd_pct = MaxEquityDDPct, max_consecutive_losses = MaxLossStreak,
                exit_reasons = done.GroupBy(b => b.ExitReason).ToDictionary(g => g.Key, g => g.Count()),
                rejected_requests = Books.Count(b => b.Rejected), break_even_moves = Books.Sum(b => b.SlModifications),
                emergency_lock = Guard.Emergency, daily_locks = Guard.DailyLocks, utc_day_starts = Guard.DayStarts,
                armed_signals = ArmedSignals, decision_reasons = DecisionReasons, events = Events
            };
        }
    }
}
