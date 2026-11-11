#!/usr/bin/env bash
# usage: next_batch_py.sh <start_line> <count> <tag>
SP=/c/Users/A/AppData/Local/Temp/claude/949fdc6dcf51bc77/6b0c02de-e90a-404a-8371-f274c0485b0a/scratchpad
cd "/c/Users/A/Desktop/TX/QuantConnect/Lean-master QuantConnect的精简算法交易引擎（Python、C#）/Algorithm.Python" || exit 1
sed -n "$1,$(( $1 + $2 - 1 ))p" "$SP/py_unread_sorted.txt" | tr -d '\r' | tr '\\' '/' | sed '1s/^\xEF\xBB\xBF//' > "$SP/b$3.txt"
bash /c/Users/A/Documents/Codex/outputs/lean-full-review-20261101/claude/tools/print_example_py.sh $(cat "$SP/b$3.txt") > "$SP/o$3.txt"
echo "files=$(wc -l < "$SP/b$3.txt") lines=$(wc -l < "$SP/o$3.txt")"
