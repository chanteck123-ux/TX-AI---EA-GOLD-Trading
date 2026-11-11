#!/usr/bin/env bash
# Print LEAN Python example source for reading (read-only):
# - drops lines 1-12 only when they are all '#' comments (license header); reports header_code_lines otherwise;
# - drops blank lines and the 'from AlgorithmImports import *' line; everything else is printed with line numbers.
# Usage: print_example_py.sh file...
for f in "$@"; do
  hdr=$(head -12 "$f" | grep -vcE '^\s*(#.*)?$')
  total=$(wc -l < "$f")
  echo "===== $f  (lines=$total, header_code_lines=$hdr)"
  if [ "$hdr" -eq 0 ]; then skip=12; else skip=0; fi
  awk -v s=$skip 'NR<=s{next} /^\s*$/{next} /^from AlgorithmImports import \*\s*$/{next} {print NR": "$0}' "$f"
done
