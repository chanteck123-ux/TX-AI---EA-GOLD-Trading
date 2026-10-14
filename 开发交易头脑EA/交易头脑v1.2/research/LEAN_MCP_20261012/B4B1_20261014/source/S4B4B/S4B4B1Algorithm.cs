using System.Globalization;
using System.Text.Json;
using QuantConnect;
using QuantConnect.Algorithm;
using QuantConnect.Data;
using QuantConnect.Data.Market;
using QuantConnect.Orders;
using QuantConnect.Orders.Fees;
using QuantConnect.Orders.Fills;
using QuantConnect.Securities;
using TradingBrain.S4B4A;   // frozen B4A QuoteFieldAdapter (RawFlagSidecar, QuoteFieldState) linked unchanged
using C7 = TradingBrain.C7;

namespace TradingBrain.S4B4B;

// S4 B4B1 candidate TB500_S4_BE125_LEAN_B4B1 (research/S4_B4B_SCOPE_CN.md, S4_B4B_EVENT_DESIGN_CN.md).
// Copy of the frozen B4A algorithm (quote fields, sidecar, cache sync, END restore unchanged) with ONE change:
// the 250 ms ENTRY is priced at the deadline quote state (all rows with ms <= T_req+250 applied in raw order),
// captured BEFORE applying the first row with ms > deadline. Registered limitation: the order is SUBMITTED on the
// first valid, ready row after the deadline (Step is never run on an invalid quote); extra waiting rows and the
// engine lag are disclosed separately and this is not called exact first-row execution. LEAN OrderEvent time is the
// real engine time; model times are recorded separately. Exits/management/server SL-TP keep B4A rules.
// Deadline-ms rows being included is an UNVERIFIED design assumption (B3 had none); they are counted.
public class S4B4B1Algorithm : QCAlgorithm, IS4Broker, IS4Trace
{
    const long StartServer = 1785542400L;            // 2026-08-01 00:00 server
    const long AugustServerOffsetMs = 10800000L;     // UTC+3, verified for August 2026 only
    readonly Dictionary<int, Queue<C7.Bar>> pending = new();
    readonly Dictionary<string, StreamWriter> streams = new(StringComparer.Ordinal);
    readonly Dictionary<long, decimal> expectedFees = new(), leanFees = new();
    readonly Dictionary<string, long> diagnostics = new(StringComparer.Ordinal);
    static readonly JsonSerializerOptions Line = new() { WriteIndented = false };
    C7.Engine engine; S4Core core; S4Config config; B4BQuoteFill fill; Symbol gold; Security security;   // S4Core = TradingBrain.S4B4B.S4Core (fork, S4CoreB4B.cs)
    C7.Tick tick; DateTime tickUtc;
    RawFlagSidecar sidecar; readonly QuoteFieldState quote = new();
    string output, candidateId, runId, endDate;
    long firstServer, lastServer, endServerExclusive, leanTicksInWindow, notReadySkipped, invalidEffectiveSkipped, ordersSent, fillPriceMismatches, quantityMismatches, liquidationFeeMismatches, equityChecks, lastCurveSec = -1;
    decimal maxTpvGap; bool fillsThisSlice;
    static double Number(string x) => double.Parse(x, CultureInfo.InvariantCulture);

    public override void Initialize()
    {
        if (LiveMode) throw new InvalidOperationException("S4 B4A LEAN candidate is local backtest research only.");
        output = GetParameter("output-dir"); candidateId = GetParameter("candidate-id"); runId = GetParameter("run-id");
        endDate = GetParameter("end-date");
        var end = DateTime.ParseExact(endDate, "yyyy-MM-dd", CultureInfo.InvariantCulture);
        if (end < new DateTime(2026, 8, 3) || end > new DateTime(2026, 8, 31)) throw new ArgumentException("August 2026 development data only (UTC+3 mapping verified for August).");
        endServerExclusive = new DateTimeOffset(DateTime.SpecifyKind(end.AddDays(1), DateTimeKind.Utc)).ToUnixTimeMilliseconds();
        config = new S4Config
        {
            LatencyMs = long.Parse(GetParameter("latency-ms", "250"), CultureInfo.InvariantCulture),   // B4A registered 250 ms default; risk stays S4Config 2%
            CommissionPerLotSide = Number(GetParameter("commission-per-lot-side", "3.5")),
            ProtectiveFillAtLevel = GetParameter("protective-fill", "QUOTE") == "LEVEL"
        };
        if (config.LatencyMs < 0 || config.LatencyMs > 1000) throw new ArgumentException("latency-ms outside 0..1000.");
        // ---- raw sidecar: export manifest must hash to the registered value; every raw file hash-checked on open
        string exportManifest = GetParameter("export-manifest"), exportManifestSha = GetParameter("export-manifest-sha256");
        if (RawFlagSidecar.Sha(exportManifest) != exportManifestSha) throw new InvalidDataException("EXPORT_MANIFEST.json hash differs from the registered value");
        var em = JsonDocument.Parse(File.ReadAllText(exportManifest)).RootElement;
        var expected = em.GetProperty("files").EnumerateArray().ToDictionary(f => f.GetProperty("name").GetString(), f => f.GetProperty("sha256").GetString(), StringComparer.Ordinal);
        var dayFiles = new List<string>();
        for (var d = new DateTime(2026, 8, 1); d <= end; d = d.AddDays(1)) dayFiles.Add("ticks_" + d.ToString("yyyyMMdd", CultureInfo.InvariantCulture) + ".csv"); // server days, real stream order
        sidecar = new RawFlagSidecar(GetParameter("raw-ticks-dir"), dayFiles, expected);

        Directory.CreateDirectory(output);
        foreach (var name in new[] { "signals", "decisions", "orders", "protection", "trades", "reconciliation", "diagnostics_first", "b4b1_entries" })
            streams[name] = new StreamWriter(Path.Combine(output, name + ".jsonl"));
        streams["equity_curve"] = new StreamWriter(Path.Combine(output, "equity_curve.csv"));
        streams["equity_curve"].WriteLine("server_msc,balance,equity_mt5,lean_tpv,open_lots_signed,peak_dd_pct,day_dd_pct");

        SetTimeZone(TimeZones.Utc); SetStartDate(2026, 8, 1); SetEndDate(end); SetCash((decimal)config.InitialCapital); SetBenchmark(_ => (decimal)config.InitialCapital);
        Market.Add("fxpro", 180);
        MarketHoursDatabase.SetEntry("fxpro", "GOLD", SecurityType.Cfd, SecurityExchangeHours.AlwaysOpen(TimeZones.Utc), TimeZones.Utc);
        SymbolPropertiesDatabase.SetEntry("fxpro", "GOLD", SecurityType.Cfd, new SymbolProperties("FxPro GOLD research contract (contract.csv)", "USD", 100m, .01m, .01m, "GOLD", .01m));
        security = AddCfd("GOLD", Resolution.Tick, "fxpro", fillForward: false, leverage: (decimal)config.Leverage);
        fill = new B4BQuoteFill();
        security.SetFillModel(fill);
        security.SetFeeModel(new B4BCommissionFee((decimal)config.CommissionPerLotSide));
        gold = security.Symbol;
        Settings.AutomaticIndicatorWarmUp = false;

        engine = new C7.Engine(new C7.EngineOptions { CurrentProfiles = true, UseCanonicalBars = true, EnableS1 = false, EnableS2 = false, EnableS3 = false, EnableS4 = true, EnableS5 = false, EnableS6 = false, EnableScalping = false });
        engine.Diagnosed += d =>
        {
            var k = d.StrategyId + "/" + d.Event;
            bool first = !diagnostics.ContainsKey(k);
            diagnostics[k] = diagnostics.GetValueOrDefault(k) + 1;
            if (first) Write("diagnostics_first", new { diagnostic = d });
        };
        var raw = GetParameter("raw-dir"); var daily = GetParameter("daily-file");
        foreach (var (tf, name) in new[] { (300, "M5"), (900, "M15"), (3600, "H1"), (14400, "H4"), (86400, "D1") })
        {
            var history = new List<C7.Bar>(); pending[tf] = new();
            var file = tf == 86400 ? daily : Path.Combine(raw, "bars_" + name + ".csv");
            foreach (var line in File.ReadLines(file).Skip(1))
            {
                var v = line.Split(',');
                var b = new C7.Bar { Time = long.Parse(v[0], CultureInfo.InvariantCulture), Open = Number(v[1]), High = Number(v[2]), Low = Number(v[3]), Close = Number(v[4]), TickVolume = long.Parse(v[5], CultureInfo.InvariantCulture) };
                if (b.Time + tf <= StartServer) history.Add(b); else pending[tf].Enqueue(b);
            }
            engine.LoadHistory(tf, history);
        }
        core = new S4Core(config, this, this);
        core.AfterFillApplied = where => Reconcile("AFTER_FILL_APPLIED " + where);
        core.EntryQuoteAtDeadline = deadlineTracker.Hook;   // B4B1: entry priced at the captured deadline state
    }
    readonly DeadlineQuoteTracker deadlineTracker = new();

    public override void OnData(Slice slice)
    {
        if (!slice.Ticks.TryGetValue(gold, out var input)) return;
        fillsThisSlice = false;
        foreach (var t in input)
        {
            long utc = new DateTimeOffset(DateTime.SpecifyKind(t.Time, DateTimeKind.Utc)).ToUnixTimeMilliseconds(), server = utc + AugustServerOffsetMs;
            if (server >= endServerExclusive)
            {
                // LEAN keeps delivering UTC-day ticks that map past the server-day window. They are not traded and the
                // cache is not re-synced for them; record them so the END cache state can be explained from evidence.
                if (afterWindowTicks == 0)
                {   // exposure at the moment LEAN starts valuing the portfolio with after-window raw quotes (diagnostic only)
                    openLotsAtWindowEnd = core.OpenSignedLots; leanQtyAtWindowEnd = Portfolio[gold].Quantity;
                    leanOrdersAtWindowEnd = Transactions.GetOrders().Count(); leanFeesAtWindowEnd = leanFees.Values.Sum(); firstAfterWindowUtc = t.Time;
                }
                afterWindowTicks++; lastAfterWindowServer = server; lastAfterWindowUtc = t.Time; lastAfterWindowBid = t.BidPrice; lastAfterWindowAsk = t.AskPrice;
                continue;
            }
            if (server < StartServer * 1000) continue;
            leanTicksInWindow++;
            // ---- B4A: the current raw row only (time, raw bid/ask, consecutive sequence verified), then flag-driven fields
            var row = sidecar.Next(server, (double)t.BidPrice, (double)t.AskPrice);
            deadlineTracker.BeforeApply(row, quote, core.PendingEntryDeadlineMs);   // B4B1: snapshot before the first row past the deadline
            var status = quote.Apply(row);
            deadlineTracker.AfterApply(row);
            if (status == QuoteStatus.NotReadyNoSeed) { notReadySkipped++; continue; } // never borrow a later row
            double bid = quote.Bid, ask = quote.Ask;
            if (bid <= 0 || ask < bid) { invalidEffectiveSkipped++; continue; } // native CanExecute QUOTE_INVALID on the effective quote
            deadlineTracker.BeforeStep(row, bid, ask);
            // One basis: corrected quote -> LEAN security cache/holdings (current tick time), TPV invalidated.
            security.SetMarketPrice(new Tick(t.Time, gold, (decimal)bid, (decimal)ask));
            Portfolio.InvalidateTotalPortfolioValue();
            if (firstServer == 0) firstServer = server;
            lastServer = server;
            foreach (var (tf, queue) in pending)
                while (queue.Count > 0 && queue.Peek().Time + tf <= server / 1000) engine.PushClosedBar(tf, queue.Dequeue());
            tick = new C7.Tick { TimeMsc = server, Bid = bid, Ask = ask, VolumeIncrement = 0 };
            tickUtc = t.Time;
            core.Step(server, utc, bid, ask,
                () => engine.OnTick(tick),
                s => engine.IsValid(s, tick, out var reason) ? null : reason,
                s => engine.Consume(s.Key));
            long sec = server / 1000;
            if (sec / 60 != lastCurveSec) { lastCurveSec = sec / 60; Curve(server); }
        }
        if (fillsThisSlice) Reconcile("SLICE_AFTER_FILLS");
    }

    // ---- IS4Broker: real QC orders (unchanged from B1) ----
    public S4Fill Execute(S4Book book, double signedLots, double expectedPrice, string tag)
    {
        decimal qty = Math.Round((decimal)signedLots, 2), price = Math.Round((decimal)expectedPrice, 2);
        fill.Price = price; fill.Utc = tickUtc;
        OrderTicket ticket;
        try { ticket = MarketOrder(gold, qty, asynchronous: false, tag: tag + " book=" + book.Id); }
        finally { fill.Price = null; }
        ordersSent++; fillsThisSlice = true;
        var result = new S4Fill { OrderId = ticket.OrderId, Status = ticket.Status.ToString() };
        if (ticket.Status == OrderStatus.Filled && ticket.QuantityFilled == qty)
        {
            decimal fee = B4BCommissionFee.Fee(qty, (decimal)config.CommissionPerLotSide);
            expectedFees[ticket.OrderId] = fee;
            if (ticket.AverageFillPrice != price) fillPriceMismatches++;
            result.Filled = true; result.SignedLots = (double)ticket.QuantityFilled; result.Price = (double)ticket.AverageFillPrice; result.Fee = (double)fee;
        }
        Write("orders", new { server_msc = tick.TimeMsc, @event = "QC_ORDER", book = book.Id, tag, order_id = ticket.OrderId, status = ticket.Status.ToString(), quantity = qty, quantity_filled = ticket.QuantityFilled, expected_price = price, fill_price = ticket.AverageFillPrice, lean_holding_after = Portfolio[gold].Quantity, lean_cache_bid = security.BidPrice, lean_cache_ask = security.AskPrice });
        return result;
    }

    public override void OnOrderEvent(OrderEvent e)
    {
        if (e.Status == OrderStatus.Filled || e.Status == OrderStatus.PartiallyFilled)
            leanFees[e.OrderId] = leanFees.GetValueOrDefault(e.OrderId) + e.OrderFee.Value.Amount;
    }

    // Same single formula as B1 R2: expected TPV = ledger at LEAN net-side quote - net liquidation fee; 0.05 USD.
    // With B4A the LEAN cache holds the corrected current quote, so both sides use the same quote.
    void Reconcile(string where)
    {
        equityChecks++;
        var holdings = Portfolio[gold];
        decimal leanQty = holdings.Quantity, ledgerQty = Math.Round((decimal)core.OpenSignedLots, 2);
        if (leanQty != ledgerQty) quantityMismatches++;
        var sec = Securities[gold];
        decimal tpv = Portfolio.TotalPortfolioValue;
        double bid = (double)sec.BidPrice, ask = (double)sec.AskPrice;
        var exp = core.LeanCfdExpectation(bid, ask);
        decimal leanLiquidationFee = holdings.Invested ? holdings.TotalCloseProfit(includeFees: false) - holdings.UnrealizedProfit : 0m;
        if (Math.Abs(leanLiquidationFee - (decimal)exp.liquidationFee) > 0.000001m) liquidationFeeMismatches++;
        decimal gap = Math.Abs(tpv - (decimal)exp.expectedLeanValue);
        if (gap > maxTpvGap) maxTpvGap = gap;
        double mt5CloseSide = core.Balance + core.Floating(bid, ask);
        bool cacheIsCorrected = tick == null || (Math.Abs(bid - tick.Bid) < 1e-9 && Math.Abs(ask - tick.Ask) < 1e-9);
        if (leanQty != ledgerQty || gap > 0.05m || Math.Abs(leanLiquidationFee - (decimal)exp.liquidationFee) > 0.000001m || !cacheIsCorrected)
            Write("reconciliation", new
            {
                server_msc = tick?.TimeMsc ?? 0, where, lean_qty = leanQty, ledger_qty = ledgerQty, lean_tpv = tpv, expected_lean_tpv = exp.expectedLeanValue, gap,
                net_side_price = exp.netSidePrice, ledger_at_net_side = exp.ledgerAtNetSide, liquidation_fee_model = exp.liquidationFee, liquidation_fee_lean = leanLiquidationFee,
                lean_cache_matches_corrected_quote = cacheIsCorrected,
                mt5_close_side_equity = mt5CloseSide, attribution_mt5_minus_lean = new { hedged_slot_side_vs_net_side = mt5CloseSide - exp.ledgerAtNetSide, lean_liquidation_fee = exp.liquidationFee }
            });
        if (!cacheIsCorrected) cacheMismatches++;
    }
    long cacheMismatches;

    void Curve(long server)
    {
        streams["equity_curve"].WriteLine(string.Join(",", server, core.Balance.ToString("R", CultureInfo.InvariantCulture), core.Equity.ToString("R", CultureInfo.InvariantCulture),
            Portfolio.TotalPortfolioValue.ToString(CultureInfo.InvariantCulture), core.OpenSignedLots.ToString("R", CultureInfo.InvariantCulture),
            core.Guard.PeakDDPct.ToString("R", CultureInfo.InvariantCulture), core.Guard.DayDDPct.ToString("R", CultureInfo.InvariantCulture)));
    }

    public void Write(string stream, object record) => streams[stream].WriteLine(JsonSerializer.Serialize(record, Line));

    long afterWindowTicks, lastAfterWindowServer; decimal lastAfterWindowBid, lastAfterWindowAsk; DateTime firstAfterWindowUtc, lastAfterWindowUtc;
    double openLotsAtWindowEnd; decimal leanQtyAtWindowEnd, leanFeesAtWindowEnd; int leanOrdersAtWindowEnd;
    object endCacheRestore;

    public override void OnEndOfAlgorithm()
    {
        if (tick != null)
        {
            // Restore the LAST VALID in-window corrected quote (a past value at its own time) into the LEAN cache before
            // closing and reconciling; the cache otherwise still holds an after-window raw tick. No later row is used.
            decimal beforeBid = security.BidPrice, beforeAsk = security.AskPrice;
            var beforeData = security.GetLastData();
            security.SetMarketPrice(new Tick(tickUtc, gold, (decimal)tick.Bid, (decimal)tick.Ask));
            Portfolio.InvalidateTotalPortfolioValue();
            var afterData = security.GetLastData();
            endCacheRestore = new
            {
                before_restore = new { bid = beforeBid, ask = beforeAsk, last_data_utc = beforeData?.Time.ToString("o") },
                last_valid_in_window = new { server_msc = tick.TimeMsc, utc = tickUtc.ToString("o"), bid = tick.Bid, ask = tick.Ask },
                after_restore = new { bid = security.BidPrice, ask = security.AskPrice, last_data_utc = afterData?.Time.ToString("o") },
                after_window_ticks_delivered_by_lean = afterWindowTicks,
                first_after_window_tick_utc = afterWindowTicks > 0 ? firstAfterWindowUtc.ToString("o") : null,
                last_after_window_tick = new { server_msc = lastAfterWindowServer, utc = afterWindowTicks > 0 ? lastAfterWindowUtc.ToString("o") : null, bid = lastAfterWindowBid, ask = lastAfterWindowAsk },
                exposure_when_after_window_valuation_began = afterWindowTicks == 0 ? null : (object)new
                {
                    ledger_open_lots_signed = openLotsAtWindowEnd, lean_quantity = leanQtyAtWindowEnd,
                    lean_orders_so_far = leanOrdersAtWindowEnd, lean_fees_so_far = leanFeesAtWindowEnd,
                    lean_orders_added_after_window = Transactions.GetOrders().Count() - leanOrdersAtWindowEnd,
                    lean_fees_added_after_window = leanFees.Values.Sum() - leanFeesAtWindowEnd,
                    note = "LEAN updates the security (AlgorithmManager security.Update before OnData) for after-window ticks; with a non-zero quantity the engine's TPV/margin would be valued at after-window raw quotes until OnEnd. No strategy logic, orders or management run on these ticks."
                },
                before_cache_equals_last_after_window_tick = afterWindowTicks > 0 && beforeBid == lastAfterWindowBid && beforeAsk == lastAfterWindowAsk,
                before_cache_equals_last_valid_quote = Math.Abs((double)beforeBid - tick.Bid) < 1e-9 && Math.Abs((double)beforeAsk - tick.Ask) < 1e-9,
                after_cache_equals_last_valid_quote = Math.Abs((double)security.BidPrice - tick.Bid) < 1e-9 && Math.Abs((double)security.AskPrice - tick.Ask) < 1e-9
            };
            core.End(); Reconcile("END"); Curve(tick.TimeMsc);
        }
        foreach (var e in deadlineTracker.Entries) Write("b4b1_entries", e);
        long unmatchedRaw = sidecar.DrainUnmatchedBefore(endServerExclusive); sidecar.Dispose();
        long rawInWindow = sidecar.RowsRead + unmatchedRaw;
        bool aligned = unmatchedRaw == 0 && sidecar.RowsRead == leanTicksInWindow && quote.Rows == leanTicksInWindow
                       && core.Ticks + notReadySkipped + invalidEffectiveSkipped == leanTicksInWindow && quote.ReadyRows + quote.NotReadyRows == quote.Rows;
        int feeMismatches = expectedFees.Count(p => leanFees.GetValueOrDefault(p.Key) != p.Value) + leanFees.Keys.Count(k => !expectedFees.ContainsKey(k));
        bool reconciled = quantityMismatches == 0 && feeMismatches == 0 && fillPriceMismatches == 0 && liquidationFeeMismatches == 0 && cacheMismatches == 0 && maxTpvGap <= 0.05m;
        var result = new
        {
            schema = "S4_LEAN_B4B1_RESULT_V1",
            candidate_id = candidateId, run_id = runId, strategy = "S4", source_mq5_sha256 = "f6abe1abc8d9cfca27e6483f344aab03110b9df11b8d1b458e3fce432d63be47",
            single_change = "ENTRY_PRICED_AT_250MS_DEADLINE_STATE (rows ms<=deadline in raw order; submitted on first valid ready row after deadline); everything else as B4A", base_candidate = "TB500_S4_BE125_LEAN_B4A",
            status = !aligned ? "ENGINE_RUN_FINISHED_SIDECAR_ALIGNMENT_FAILED" : reconciled ? "ENGINE_RUN_FINISHED_REVIEW_REQUIRED" : "ENGINE_RUN_FINISHED_RECONCILIATION_FAILED",
            data_role = "AUGUST_2026_ALREADY_USED_DEVELOPMENT_NOT_OOS", end_date = endDate,
            initial_capital_usd = config.InitialCapital, risk_pct = config.RiskPct, portfolio_risk_pct = config.PortfolioRiskPct, equity_risk_pct = config.EquityRiskPct,
            day_loss_pct = config.DayLossPct, emergency_dd_pct = config.EmergencyDDPct, slots = config.Slots, be_trigger_r = config.BETriggerR, reward_risk = config.RewardRisk,
            latency_ms = config.LatencyMs, protective_fill = config.ProtectiveFillAtLevel ? "LEVEL" : "TRIGGER_QUOTE", commission_per_lot_side = config.CommissionPerLotSide,
            ticks = core.Ticks, first_server_msc = firstServer, last_server_msc = lastServer, end_server_exclusive_msc = endServerExclusive,
            b4b1_entry_timing = new
            {
                entries_via_deadline = deadlineTracker.Entries.Count,
                rejected_invalid_quote_at_deadline = core.Events.GetValueOrDefault("ENTRY_REJECT_INVALID_QUOTE_AT_DEADLINE"),
                entries_with_deadline_ms_rows = deadlineTracker.Entries.Count(e => e.DeadlineRows > 0),
                entries_with_extra_wait_rows = deadlineTracker.Entries.Count(e => e.ExtraWaitRows > 0),
                max_extra_wait_rows = deadlineTracker.Entries.Count == 0 ? 0 : deadlineTracker.Entries.Max(e => e.ExtraWaitRows),
                max_engine_lag_ms = deadlineTracker.Entries.Count == 0 ? 0 : deadlineTracker.Entries.Max(e => e.EngineLagMs),
                entries_price_changed_vs_b4a_rule = deadlineTracker.Entries.Count(e => e.PriceChangedVsB4ARule),
                entries_start_row_changed_vs_b4a_rule = deadlineTracker.Entries.Count(e => e.StartRowChangedVsB4ARule),
                note = "Price change and position-start change are counted separately; neither alone explains P/L differences. b4a_rule fields are diagnostics (first delivered row with ms >= deadline), not trading inputs. Deadline-ms rows included = unverified assumption.",
                detail_file = "b4b1_entries.jsonl"
            },
            quote_adapter = new
            {
                aligned, lean_ticks_in_window = leanTicksInWindow, raw_rows_matched = sidecar.RowsRead, raw_rows_in_window_unmatched = unmatchedRaw, raw_rows_in_window_total = rawInWindow,
                ready_rows = quote.ReadyRows, not_ready_rows_skipped = notReadySkipped, invalid_effective_quote_skipped = invalidEffectiveSkipped, delivered_to_core = core.Ticks,
                identity = "lean_ticks_in_window = delivered_to_core + not_ready_rows_skipped + invalid_effective_quote_skipped",
                bid_updates = quote.BidUpdates, ask_updates = quote.AskUpdates, rows_without_bid_or_ask_bit = quote.NoQuoteBitRows,
                ready_rows_where_effective_differs_from_raw_row = quote.ReadyDifferFromRawRow, rows_with_unknown_bits = quote.UnknownBitRows,
                unknown_bits = quote.UnknownBits.ToDictionary(p => p.Key.ToString(CultureInfo.InvariantCulture), p => p.Value),
                flag_counts = quote.FlagCounts.ToDictionary(p => p.Key.ToString(CultureInfo.InvariantCulture), p => p.Value),
                files = sidecar.FilesVerified.Select(f => new { f.file, f.sha256, f.rows }).ToArray(),
                lean_cache_sync = "Security.SetMarketPrice(new Tick(currentTime, bid, ask)) + Portfolio.InvalidateTotalPortfolioValue before core logic each ready tick; at END the last valid in-window quote is restored before core.End/Reconcile",
                residual = "LEAN AlgorithmManager (Engine/AlgorithmManager.cs ~line 271) calls security.Update for every slice BEFORE OnData. In-window slices: OnData then re-syncs the corrected quote per tick before any logic. After the server-day window (SetEndDate is the UTC day end, B1-identical) LEAN still delivers UTC ticks that map past the window; they are not traded and not re-synced, so the engine values holdings/TPV/margin at after-window raw quotes until the END restore. Actual exposure is recorded in end_cache_restore.exposure_when_after_window_valuation_began; an engine valuation effect is NOT claimed to be impossible.",
                after_window_ticks_not_traded = afterWindowTicks,
                end_cache_restore = endCacheRestore
            },
            c7 = new { raw = engine.RawSignals, allowed = engine.AllowedSignals, rejected = engine.RejectedSignals, not_ready = engine.NotReadySignals },
            diagnostic_counts = diagnostics,
            lifecycle = core.Summary(),
            qc_orders = new { sent = ordersSent, lean_order_count = Transactions.GetOrders().Count(), fill_price_mismatches = fillPriceMismatches, fee_mismatches = feeMismatches, lean_fees_usd = leanFees.Values.Sum() },
            reconciliation = new { formula = "LEAN_CFD_TPV = ledger_at_net_side_quote - net_liquidation_fee (SecurityHolding.TotalCloseProfit includeFees=true)", tolerance_usd = 0.05m,
                checks = equityChecks, quantity_mismatches = quantityMismatches, liquidation_fee_mismatches = liquidationFeeMismatches, lean_cache_vs_corrected_quote_mismatches = cacheMismatches,
                max_tpv_gap_usd = maxTpvGap, lean_end_tpv = Portfolio.TotalPortfolioValue, lean_end_quantity = Portfolio[gold].Quantity, ledger_end_balance = core.Balance, passed = reconciled },
            assumptions = new[]
            {
                "MARGIN_NOMINAL_1000_LEVERAGE_MODEL_NOT_BROKER_PARITY", "STOPOUT_LEVEL_ASSUMED_100PCT", "COMMISSION_3_5_PER_LOT_SIDE_OBSERVED_IN_MT5_TESTER_NOT_LIVE_CALIBRATED",
                "SWAP_NOT_MODELED", "SL_TP_FILL_AT_TRIGGER_QUOTE_UNLESS_LEVEL", "SAME_TICK_ORDER_DUE_ACTIONS_THEN_SERVER_SLTP_THEN_EA", "STOPS_AND_FREEZE_LEVEL_0_FROM_2026_10_04_SNAPSHOT",
                "DEAL_PROFIT_NOT_ROUNDED_TO_CENTS", "NO_PARTIAL_FILLS", "CASH_LEDGER_TESTER_NO_DEPOSITS",
                "ENTRY_250MS_DEADLINE_STATE_PRICE; DEADLINE_MS_ROWS_INCLUDED_UNVERIFIED; SUBMITTED_ON_FIRST_VALID_READY_ROW_AFTER_DEADLINE (not exact first-row execution)", "EXITS_AND_MANAGEMENT_KEEP_B4A_NEXT_ROW_RULE; NO_SYNC_BLOCKING_OR_CALLBACK_SUPPRESSION (B4B2 not implemented)"
            },
            score = (double?)null, score_status = "SCORE_TARGETS_UNSET", verification_status = "LEAN_CANDIDATE_ENGINEERING_NOT_NATIVE_PARITY", champion = false, live_ready = false
        };
        foreach (var s in streams.Values) s.Dispose();
        File.WriteAllText(Path.Combine(output, "RESULT.json"), JsonSerializer.Serialize(result, new JsonSerializerOptions { WriteIndented = true }));
        Debug($"S4_B4B1_DONE ticks={core.Ticks} aligned={aligned} orders={ordersSent} reconciled={reconciled}");
    }
}

// Same semantics as B1 S4QuoteFill (own type so B1 files are not linked or modified).
public sealed class B4BQuoteFill : FillModel
{
    public decimal? Price; public DateTime Utc;
    public override OrderEvent MarketFill(Security asset, MarketOrder order)
    {
        if (Price is null || Price <= 0) throw new InvalidOperationException("S4 B4A fill requested without the deciding quote.");
        return new OrderEvent(order, Utc, OrderFee.Zero) { Status = OrderStatus.Filled, FillQuantity = order.Quantity, FillPrice = Price.Value };
    }
}

// Same semantics as B1 S4CommissionFee.
public sealed class B4BCommissionFee : FeeModel
{
    readonly decimal perLotSide;
    public B4BCommissionFee(decimal perLotSide) { this.perLotSide = perLotSide; }
    public static decimal Fee(decimal quantity, decimal perLotSide) => Math.Ceiling(Math.Round(Math.Abs(quantity) * perLotSide * 100m, 6)) / 100m;
    public override OrderFee GetOrderFee(OrderFeeParameters p) => new(new CashAmount(Fee(p.Order.Quantity, perLotSide), "USD"));
}
