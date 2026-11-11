#!/bin/bash
# usage: dump_batch.sh <base_dir> <listfile> <start_line> <count> <tag>
# Writes scratchpad b<tag>.txt (paths) and o<tag>.txt (code with license header, blank lines, usings, /// XML doc and [DocumentationAttribute] stripped). Read-only.
S="C:/Users/A/AppData/Local/Temp/claude/949fdc6dcf51bc77/6b0c02de-e90a-404a-8371-f274c0485b0a/scratchpad"
T="C:/Users/A/Documents/Codex/outputs/lean-full-review-20261101/claude/tools"
sed -n "$3,$(( $3 + $4 - 1 ))p" "$2" | sed 's/^\xef\xbb\xbf//; s/\r$//' > "$S/b$5.txt"
bash "$T/dump_src.sh" "$1" "$S/b$5.txt" "$S/o$5full.txt" >/dev/null
grep -v '^[0-9]*: *///' "$S/o$5full.txt" | grep -v '^[0-9]*: *\[DocumentationAttribute' > "$S/o$5.txt"
echo "files=$(grep -c '^=====' "$S/o$5.txt") lines=$(wc -l < "$S/o$5.txt")"
