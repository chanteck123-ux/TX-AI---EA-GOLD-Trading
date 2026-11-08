#!/usr/bin/env bash
# Print LEAN example/test source for reading (read-only):
# - drops the 14-line license header (only after confirming it has no code), blank lines and `using` lines;
# - drops the body of the ExpectedStatistics dictionary (regression-output template lines like {"Total Orders", "1"},)
#   and reports how many lines were dropped so the drop can be audited.
# Usage: print_example.sh file...
for f in "$@"; do
  hdr=$(head -14 "$f" | grep -vcE '^\s*(/?\*|\*/|$)|^\s*\*')
  total=$(wc -l < "$f")
  stats=$(awk '/ExpectedStatistics/{inb=1} inb && /^\s*\{"[^"]*", *"[^"]*"\},?\s*$/{c++} inb && /};/{inb=0} END{print c+0}' "$f")
  echo "===== $f  (lines=$total, header_code_lines=$hdr, expected_stats_lines_dropped=$stats)"
  awk 'NR<=14{next} /^\s*$/{next} /^using /{next}
       /ExpectedStatistics/{inb=1}
       inb && /^\s*\{"[^"]*", *"[^"]*"\},?\s*$/{next}
       inb && /};/{inb=0}
       {print NR": "$0}' "$f"
done
