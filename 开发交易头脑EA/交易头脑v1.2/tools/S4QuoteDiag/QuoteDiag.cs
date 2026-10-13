using System.Globalization;
using System.Text;

// S4 B2 read-only quote diagnostic core (no I/O policy, no LEAN, no MT5). Pre-registered in
// research/S4_B2_QUOTE_DIAGNOSTIC_SCOPE_CN.md. Raw rows keep file line numbers, duplicate
// milliseconds and flags. Candidates are fixed in advance; matches never imply causation.
namespace TradingBrain.S4B2
{
    public sealed class RawRow
    {
        public string File = ""; public long Line; public long Ms;
        public double Bid, Ask, Last, VolumeReal; public long Volume; public int Flags;
        public double Side(int dir) => dir > 0 ? Ask : Bid; // entry side: long buys at ask, short sells at bid
    }

    public static class Flags
    {
        // MQL5 TICK_FLAG_*: BID=2 ASK=4 LAST=8 VOLUME=16 BUY=32 SELL=64. Other bits kept as "other".
        public static string Decode(int f)
        {
            var parts = new List<string>();
            if ((f & 2) != 0) parts.Add("BID"); if ((f & 4) != 0) parts.Add("ASK"); if ((f & 8) != 0) parts.Add("LAST");
            if ((f & 16) != 0) parts.Add("VOLUME"); if ((f & 32) != 0) parts.Add("BUY"); if ((f & 64) != 0) parts.Add("SELL");
            int other = f & ~(2 | 4 | 8 | 16 | 32 | 64);
            if (other != 0) parts.Add("OTHER_" + other);
            return parts.Count == 0 ? "NONE" : string.Join("|", parts);
        }
        public static int SideBit(int dir) => dir > 0 ? 4 : 2;
    }

    public sealed class EventSpec
    {
        public string Key = ""; public int Dir; public string Kind = ""; public string TimeSemantics = "";
        public long AnchorMs; public double Observed; public long WindowFrom, WindowTo;
        public long? FillSecond; public long? SendMs; // native fill only
    }

    public sealed class CandidateResult { public string Name = ""; public bool Preregistered; public RawRow Row; public bool? Match; }

    public sealed class EventResult
    {
        public EventSpec Spec; public List<RawRow> Window = new(); public List<CandidateResult> Candidates = new();
        public string Status = ""; public int WindowMatches; public long? NearestMatchOffsetMs; public long? NearestMatchLine;
        public string FillSecondStatus = ""; public int FillSecondMatches; public string FillSecondLines = "";
    }

    public static class Diagnose
    {
        public const double PriceTol = 0.005;
        public static bool Same(double a, double b) => Math.Abs(a - b) < PriceTol;

        public static RawRow Parse(string file, long line, string text)
        {
            var c = text.Split(',');
            if (c.Length < 7) throw new FormatException($"{file}:{line} expected 7 columns");
            var inv = CultureInfo.InvariantCulture;
            return new RawRow { File = file, Line = line, Ms = long.Parse(c[0], inv), Bid = double.Parse(c[1], inv), Ask = double.Parse(c[2], inv), Last = double.Parse(c[3], inv),
                                Volume = long.Parse(c[4], inv), Flags = int.Parse(c[5], inv), VolumeReal = double.Parse(c[6], inv) };
        }

        // rows must be in original file order (chronological, duplicates preserved).
        public static EventResult Evaluate(EventSpec e, IReadOnlyList<RawRow> rows)
        {
            var r = new EventResult { Spec = e };
            r.Window = rows.Where(x => x.Ms >= e.WindowFrom && x.Ms <= e.WindowTo).ToList();
            var w = r.Window; long t = e.AnchorMs; int bit = Flags.SideBit(e.Dir);
            RawRow prev = w.LastOrDefault(x => x.Ms < t);
            var same = w.Where(x => x.Ms == t).ToList();
            RawRow sideFlag = w.LastOrDefault(x => x.Ms <= t && (x.Flags & bit) != 0);
            RawRow next = w.FirstOrDefault(x => x.Ms >= t);
            void Add(string name, bool pre, RawRow row) => r.Candidates.Add(new CandidateResult { Name = name, Preregistered = pre, Row = row, Match = row == null ? null : Same(row.Side(e.Dir), e.Observed) });
            Add("PREV_LAST_ROW_BEFORE", true, prev);
            Add("SAME_MS_FIRST_ROW", true, same.FirstOrDefault());
            Add("SAME_MS_LAST_ROW", true, same.LastOrDefault());
            Add("LAST_ROW_WITH_SIDE_FLAG_AT_OR_BEFORE", true, sideFlag);
            Add("SUPPLEMENTARY_FIRST_ROW_AT_OR_AFTER", false, next); // B1 LEAN delay rule; reported separately
            var pre = r.Candidates.Where(c => c.Preregistered).ToList();
            if (w.Count == 0) r.Status = "MISSING_NO_RAW_ROWS_IN_WINDOW";
            else if (pre.All(c => c.Row == null)) r.Status = "MISSING_NO_CANDIDATE_ROWS";
            else
            {
                var present = pre.Where(c => c.Row != null).ToList();
                int matched = present.Count(c => c.Match == true);
                var prices = present.Select(c => Math.Round(c.Row.Side(e.Dir), 2)).Distinct().Count();
                if (matched == 0) r.Status = "NO_PREREGISTERED_CANDIDATE_MATCHES";
                else if (prices == 1) r.Status = "MATCH_NON_DISCRIMINATING_ALL_CANDIDATES_SAME_PRICE";
                else if (matched == present.Count) r.Status = "MATCH_ALL_PRESENT";
                else
                {
                    var matchedRows = present.Where(c => c.Match == true).Select(c => c.Row).Distinct().Count();
                    r.Status = matchedRows == 1 ? "DISCRIMINATING_MATCH_SINGLE_ROW" : "DISCRIMINATING_MATCH_MULTIPLE_ROWS_AMBIGUOUS";
                }
            }
            var all = w.Where(x => Same(x.Side(e.Dir), e.Observed)).ToList();
            r.WindowMatches = all.Count;
            var near = all.OrderBy(x => Math.Abs(x.Ms - t)).ThenBy(x => x.Ms).FirstOrDefault();
            if (near != null) { r.NearestMatchOffsetMs = near.Ms - t; r.NearestMatchLine = near.Line; }
            if (e.Kind == "NATIVE_FILL")
            {
                if (e.FillSecond == null) r.FillSecondStatus = "MISSING_DEAL_TIME";
                else
                {
                    long from = Math.Max(e.FillSecond.Value * 1000, e.SendMs ?? long.MinValue), to = e.FillSecond.Value * 1000 + 999;
                    var cand = rows.Where(x => x.Ms >= from && x.Ms <= to && Same(x.Side(e.Dir), e.Observed)).ToList();
                    r.FillSecondMatches = cand.Count;
                    r.FillSecondLines = string.Join(" ", cand.Take(12).Select(x => x.Line + "@" + x.Ms));
                    r.FillSecondStatus = from > to ? "DEAL_SECOND_BEFORE_SEND" : cand.Count == 0 ? "NO_ROW_IN_DEAL_SECOND_MATCHES" : cand.Select(x => x.Ms).Distinct().Count() == 1 && cand.Count == 1 ? "UNIQUE_ROW" : "MULTIPLE_ROWS_AMBIGUOUS";
                }
            }
            return r;
        }

        public static string Csv(string s) => s.Contains(',') || s.Contains('"') ? "\"" + s.Replace("\"", "\"\"") + "\"" : s;
        public static string N(double v) => v.ToString("0.00######", CultureInfo.InvariantCulture);
    }
}
