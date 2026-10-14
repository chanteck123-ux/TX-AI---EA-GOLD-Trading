using System;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using System.Security.Cryptography;

// S4 B4A single change (research/S4_B4A_QUOTE_FIELDS_SCOPE_CN.md): drive Bid/Ask from the CURRENT raw
// CopyTicksRange row's flags. TICK_FLAG_BID=2 updates bid, TICK_FLAG_ASK=4 updates ask; LAST=8 / VOLUME=16
// never overwrite the quote; other bits are counted, not interpreted. No future rows, no native orders.
// Pure C# (no QuantConnect types) so fixtures exercise the same code the LEAN algorithm runs.
namespace TradingBrain.S4B4A
{
    public sealed class RawRow
    {
        public string File = ""; public long Line; public long Sequence; public long Ms; public double Bid, Ask; public int Flags;
    }

    // Reads raw server-day files strictly in order, one row per LEAN tick. Each file's SHA256 must equal the
    // export manifest before any row is read. A LEAN tick must equal the next raw row (time, bid, ask);
    // anything else is a hard mismatch (no skipping, no look-ahead beyond the single current row).
    public sealed class RawFlagSidecar : IDisposable
    {
        readonly Queue<string> files; readonly IReadOnlyDictionary<string, string> expectedSha; readonly string dir;
        StreamReader reader; string currentFile = ""; long line, sequence, lastRawMs = long.MinValue; // raw time must be non-decreasing across all files
        public long RowsRead => sequence;
        public readonly List<(string file, string sha256, long rows)> FilesVerified = new List<(string, string, long)>();
        long rowsInFile;
        public RawFlagSidecar(string rawDir, IEnumerable<string> orderedFileNames, IReadOnlyDictionary<string, string> expectedSha256)
        { dir = rawDir; files = new Queue<string>(orderedFileNames); expectedSha = expectedSha256; }

        public static string Sha(string path) { using var s = System.IO.File.OpenRead(path); return Convert.ToHexString(SHA256.HashData(s)).ToLowerInvariant(); }

        bool OpenNext()
        {
            if (reader != null) { FilesVerified.Add((currentFile, expectedSha[currentFile], rowsInFile)); reader.Dispose(); reader = null; }
            if (files.Count == 0) return false;
            currentFile = files.Dequeue();
            string path = Path.Combine(dir, currentFile);
            if (!expectedSha.TryGetValue(currentFile, out var want)) throw new InvalidDataException("No manifest hash for " + currentFile);
            if (Sha(path) != want) throw new InvalidDataException("Raw file hash differs from export manifest: " + currentFile);
            reader = new StreamReader(path); line = 1; rowsInFile = 0;
            var header = reader.ReadLine();
            if (header == null || !header.StartsWith("server_time_msc,bid,ask,last,volume,flags", StringComparison.Ordinal)) throw new InvalidDataException("Unexpected raw header in " + currentFile);
            return true;
        }

        // Returns the raw row that must correspond to this LEAN tick, verified against it.
        public RawRow Next(long serverMs, double leanBid, double leanAsk)
        {
            while (true)
            {
                if (reader == null && !OpenNext()) throw new InvalidDataException("RAW_EXHAUSTED: LEAN tick at " + serverMs + " has no raw row");
                string text = reader.ReadLine();
                if (text == null) { if (!OpenNext()) throw new InvalidDataException("RAW_EXHAUSTED: LEAN tick at " + serverMs + " has no raw row"); continue; }
                line++;
                if (text.Length == 0) continue;
                var c = text.Split(',');
                if (c.Length < 6) throw new InvalidDataException(currentFile + ":" + line + " malformed raw row");
                var row = new RawRow { File = currentFile, Line = line, Sequence = ++sequence, Ms = long.Parse(c[0], CultureInfo.InvariantCulture),
                    Bid = double.Parse(c[1], CultureInfo.InvariantCulture), Ask = double.Parse(c[2], CultureInfo.InvariantCulture), Flags = int.Parse(c[5], CultureInfo.InvariantCulture) };
                rowsInFile++;
                // Finite-number check first: a NaN would make every Math.Abs(...) > tol comparison false.
                if (!double.IsFinite(row.Bid) || !double.IsFinite(row.Ask) || !double.IsFinite(leanBid) || !double.IsFinite(leanAsk))
                    throw new InvalidDataException($"NON_FINITE_PRICE {currentFile}:{line} raw=({row.Bid},{row.Ask}) lean=({leanBid},{leanAsk})");
                if (row.Ms < lastRawMs)
                    throw new InvalidDataException($"RAW_TIME_REGRESSION {currentFile}:{line} raw_ms={row.Ms} previous_raw_ms={lastRawMs}");
                lastRawMs = row.Ms;
                if (row.Ms != serverMs || !(Math.Abs(row.Bid - leanBid) <= 1e-9) || !(Math.Abs(row.Ask - leanAsk) <= 1e-9))
                    throw new InvalidDataException($"SIDECAR_MISMATCH {currentFile}:{line} raw=({row.Ms},{row.Bid},{row.Ask}) lean=({serverMs},{leanBid},{leanAsk})");
                return row;
            }
        }

        // After the last LEAN tick: count raw rows of the current file and every unopened file (hash-verified)
        // that lie inside the run window but were never matched to a LEAN tick. Must be 0 for alignment.
        public long DrainUnmatchedBefore(long serverMsExclusive)
        {
            long n = 0;
            while (true)
            {
                if (reader == null && !OpenNext()) break;
                string t;
                while ((t = reader.ReadLine()) != null)
                {
                    if (t.Length == 0) continue;
                    rowsInFile++;
                    long ms = long.Parse(t.Split(',')[0], CultureInfo.InvariantCulture);
                    if (ms < lastRawMs) throw new InvalidDataException($"RAW_TIME_REGRESSION {currentFile} during drain raw_ms={ms} previous_raw_ms={lastRawMs}");
                    lastRawMs = ms;
                    if (ms < serverMsExclusive) n++;
                }
                FilesVerified.Add((currentFile, expectedSha[currentFile], rowsInFile)); reader.Dispose(); reader = null;
            }
            return n;
        }
        public void Dispose() { reader?.Dispose(); }
    }

    public enum QuoteStatus { Ready, NotReadyNoSeed }

    // Effective quote state driven only by the current row's BID/ASK bits.
    public sealed class QuoteFieldState
    {
        public const int FlagBid = 2, FlagAsk = 4, FlagLast = 8, FlagVolume = 16, FlagBuy = 32, FlagSell = 64;
        const int Known = FlagBid | FlagAsk | FlagLast | FlagVolume | FlagBuy | FlagSell;
        bool haveBid, haveAsk;
        public double Bid { get; private set; }
        public double Ask { get; private set; }
        public long Rows, ReadyRows, NotReadyRows, BidUpdates, AskUpdates, NoQuoteBitRows, UnknownBitRows, ReadyDifferFromRawRow;
        public readonly Dictionary<int, long> UnknownBits = new Dictionary<int, long>();
        public readonly Dictionary<int, long> FlagCounts = new Dictionary<int, long>();

        public QuoteStatus Apply(RawRow r)
        {
            Rows++;
            FlagCounts[r.Flags] = FlagCounts.TryGetValue(r.Flags, out var fc) ? fc + 1 : 1;
            int unknown = r.Flags & ~Known;
            if (unknown != 0) { UnknownBitRows++; UnknownBits[unknown] = UnknownBits.TryGetValue(unknown, out var u) ? u + 1 : 1; }
            if ((r.Flags & FlagBid) != 0) { Bid = r.Bid; haveBid = true; BidUpdates++; }
            if ((r.Flags & FlagAsk) != 0) { Ask = r.Ask; haveAsk = true; AskUpdates++; }
            if ((r.Flags & (FlagBid | FlagAsk)) == 0) NoQuoteBitRows++;
            if (!haveBid || !haveAsk) { NotReadyRows++; return QuoteStatus.NotReadyNoSeed; } // never borrow a later row
            ReadyRows++;
            if (Math.Abs(Bid - r.Bid) > 1e-9 || Math.Abs(Ask - r.Ask) > 1e-9) ReadyDifferFromRawRow++;
            return QuoteStatus.Ready;
        }
    }
}
