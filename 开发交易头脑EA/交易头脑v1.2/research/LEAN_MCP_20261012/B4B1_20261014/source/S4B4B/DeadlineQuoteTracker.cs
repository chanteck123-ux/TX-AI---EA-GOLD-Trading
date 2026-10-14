using System;
using System.Collections.Generic;
using TradingBrain.S4B4A;

// B4B1 deadline quote tracker (pure C#, no QuantConnect). Call order per raw row, identical in the LEAN algorithm
// and the fixtures:  BeforeApply(row, quote, core.PendingEntryDeadlineMs) -> quote.Apply(row) -> AfterApply(row)
// -> [only if the row is ready and valid] BeforeStep(row, bid, ask) -> core.Step(...).
// The deadline snapshot is taken in BeforeApply of the FIRST row with ms > deadline, i.e. it contains only rows
// already consumed (all rows with ms <= deadline, in raw order). The crossing row's own price is never used.
namespace TradingBrain.S4B4B
{
    // Properties (not fields) so System.Text.Json serializes them in b4b1_entries.jsonl.
    public sealed class B4B1EntryRecord
    {
        public int Book { get; set; } public int Direction { get; set; }
        public long DeadlineMs { get; set; } public long QuoteRowMs { get; set; } public long QuoteRowSequence { get; set; }
        public long CrossingRowMs { get; set; } public long CrossingRowSequence { get; set; } public long SubmitRowMs { get; set; } public long SubmitRowSequence { get; set; }
        public int QuoteRowOrdinalInMs { get; set; } public int DeadlineRows { get; set; }
        public long ExtraWaitRows { get; set; } public long EngineLagMs { get; set; }
        public bool SnapshotValid { get; set; }
        public double B4B1Price { get; set; }
        public long? B4ARuleRowMs { get; set; } public double? B4ARulePrice { get; set; }   // diagnostic: first delivered row with ms >= deadline (B4A rule)
        public bool PriceChangedVsB4ARule { get; set; } public bool StartRowChangedVsB4ARule { get; set; }
    }

    public sealed class DeadlineQuoteTracker
    {
        long? tracked; EntryQuote snapshot; int deadlineRows;
        long lastMs = long.MinValue, lastSeq; int lastOrdinal = -1;
        bool ruleCaptured; long ruleMs; double ruleBid, ruleAsk;
        long currentSeq, currentMs;
        public readonly List<B4B1EntryRecord> Entries = new List<B4B1EntryRecord>();

        public void BeforeApply(RawRow row, QuoteFieldState quote, long? pendingDeadline)
        {
            if (pendingDeadline != tracked) { tracked = pendingDeadline; snapshot = null; deadlineRows = 0; ruleCaptured = false; }
            if (tracked.HasValue && snapshot == null && row.Ms > tracked.Value)
                snapshot = new EntryQuote
                {
                    Bid = quote.Bid, Ask = quote.Ask, Ready = quote.ReadyRows > 0, DeadlineMs = tracked.Value,
                    QuoteRowMs = lastMs, QuoteRowSequence = lastSeq, QuoteRowOrdinalInMs = lastOrdinal, DeadlineRows = deadlineRows,
                    CrossingRowMs = row.Ms, CrossingRowSequence = row.Sequence
                };
        }

        public void AfterApply(RawRow row)
        {
            lastOrdinal = row.Ms == lastMs ? lastOrdinal + 1 : 0;
            lastMs = row.Ms; lastSeq = row.Sequence;
            if (tracked.HasValue && row.Ms == tracked.Value) deadlineRows++;
        }

        // Delivered (ready + valid) rows only, immediately before core.Step for that row.
        public void BeforeStep(RawRow row, double bid, double ask)
        {
            currentSeq = row.Sequence; currentMs = row.Ms;
            if (tracked.HasValue && !ruleCaptured && row.Ms >= tracked.Value) { ruleCaptured = true; ruleMs = row.Ms; ruleBid = bid; ruleAsk = ask; }
        }

        // Hook for S4Core.EntryQuoteAtDeadline; called inside core.Step of the submit row.
        public EntryQuote Hook(S4Book b)
        {
            if (snapshot == null) throw new InvalidOperationException("B4B1: hook called without a deadline snapshot");
            if (!tracked.HasValue || b.DueMs != tracked.Value) throw new InvalidOperationException("B4B1: hook deadline does not match the tracked request");
            double price = b.Direction > 0 ? snapshot.Ask : snapshot.Bid;
            double? rulePrice = ruleCaptured ? (b.Direction > 0 ? ruleAsk : ruleBid) : (double?)null;
            Entries.Add(new B4B1EntryRecord
            {
                Book = b.Id, Direction = b.Direction, DeadlineMs = snapshot.DeadlineMs, QuoteRowMs = snapshot.QuoteRowMs, QuoteRowSequence = snapshot.QuoteRowSequence,
                QuoteRowOrdinalInMs = snapshot.QuoteRowOrdinalInMs, DeadlineRows = snapshot.DeadlineRows, CrossingRowMs = snapshot.CrossingRowMs, CrossingRowSequence = snapshot.CrossingRowSequence,
                SubmitRowMs = currentMs, SubmitRowSequence = currentSeq, ExtraWaitRows = currentSeq - snapshot.CrossingRowSequence, EngineLagMs = currentMs - snapshot.DeadlineMs,
                SnapshotValid = snapshot.Valid, B4B1Price = price, B4ARuleRowMs = ruleCaptured ? ruleMs : (long?)null, B4ARulePrice = rulePrice,
                PriceChangedVsB4ARule = rulePrice.HasValue && Math.Abs(rulePrice.Value - price) > 1e-9,
                StartRowChangedVsB4ARule = ruleCaptured && ruleMs != currentMs
            });
            return snapshot;
        }
    }
}
