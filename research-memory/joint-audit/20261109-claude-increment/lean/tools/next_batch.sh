#!/usr/bin/env bash
# usage: next_batch.sh <start_line> <count> <tag>
# Prints the next <count> files from scratchpad/cs_unread_sorted.txt through read_batch.sh into scratchpad/o<tag>.txt
SP=/c/Users/A/AppData/Local/Temp/claude/949fdc6dcf51bc77/6b0c02de-e90a-404a-8371-f274c0485b0a/scratchpad
cd "/c/Users/A/Desktop/TX/QuantConnect/Lean-master QuantConnect的精简算法交易引擎（Python、C#）/Algorithm.CSharp" || exit 1
sed -n "$1,$(( $1 + $2 - 1 ))p" "$SP/cs_unread_sorted.txt" | tr -d '\r' | tr '\\\\' '/' | sed '1s/^\xEF\xBB\xBF//' > "$SP/b$3.txt"
bash /c/Users/A/Documents/Codex/outputs/lean-full-review-20261101/claude/tools/read_batch.sh $(cat "$SP/b$3.txt") > "$SP/o$3.txt"
echo "files=$(wc -l < "$SP/b$3.txt") lines=$(wc -l < "$SP/o$3.txt")"
# Files whose first 14 lines are not a pure license header: print those lines too, so nothing is skipped.
grep -oE '^===== [^ ]+  \(lines=[0-9]+, header_code_lines=([2-9]|[1-9][0-9])' "$SP/o$3.txt" | sed -E 's/^===== ([^ ]+) .*/\1/' | while read -r f; do
  echo "===== HEAD $f (lines 1-15, header was not a license)" >> "$SP/o$3.txt"
  sed -n '1,15p' "$f" | grep -vE '^\s*(using [A-Za-z.]+;)?\s*$' | nl -ba >> "$SP/o$3.txt"
done
