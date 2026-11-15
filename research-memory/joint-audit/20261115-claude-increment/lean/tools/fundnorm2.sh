#!/bin/bash
B="$1"; S="$2"; : > "$S/fundhash2.txt"; : > "$S/fundprefix.txt"
grep -F 'Generated' "$S/fund.txt" | tr -d '\r' | tr '\' '/' | while IFS= read -r q; do
  f="$B/$q"
  cls=$(grep -oE 'public (partial )?class [A-Za-z0-9_]+' "$f" | head -1 | awk '{print $NF}')
  # prefixes used (strip trailing _Period)
  np=$(grep -oE 'FundamentalProperty\.[A-Za-z0-9_]+' "$f" | sed -E 's/_(OneMonth|TwoMonths|ThreeMonths|SixMonths|NineMonths|TwelveMonths|OneYear|TwoYears|ThreeYears|FiveYears|TenYears)$//' | sort -u | wc -l)
  echo "$np $cls $q" >> "$S/fundprefix.txt"
  awk 'f||/^using /{f=1;print}' "$f" | grep -vE '^\s*///' | sed -E "s/\b${cls}\b/CLS/g; s/FundamentalProperty\.[A-Za-z0-9_]+/FP/g; s/\"[^\"]*\"/\"STR\"/g" > "$S/fundnorm/$cls.txt"
  h=$(md5sum "$S/fundnorm/$cls.txt" | cut -c1-12)
  echo "$h $cls $q" >> "$S/fundhash2.txt"
done
