#!/bin/bash
# usage: dump_src.sh <base_dir> <listfile(relative paths)> <outfile>
# Prints each file with line numbers, skipping the leading license/comment block, blank lines and using/import lines. Read-only.
base="$1"; list="$2"; out="$3"; : > "$out"
while IFS= read -r f; do
  f="${f%$'\r'}"; [ -z "$f" ] && continue
  p="$base/$f"
  echo "===== $f ($(wc -l < "$p") lines)" >> "$out"
  awk 'BEGIN{h=1} { if (NR==1) sub(/^\xef\xbb\xbf/,""); if(h && ($0 ~ /^[ \t]*(\/\*|\*|\/\/|#)/ || $0 ~ /^[ \t]*$/)) next; h=0; if ($0 ~ /^[ \t]*$/) next; if ($0 ~ /^using |^from AlgorithmImports/) next; print NR": "$0 }' "$p" >> "$out"
done < "$list"
echo "files=$(grep -c '^=====' "$out") lines=$(wc -l < "$out")"
