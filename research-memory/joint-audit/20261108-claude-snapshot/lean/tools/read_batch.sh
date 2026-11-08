#!/usr/bin/env bash
# Wrapper: print_example.sh plus the regression-template/log/stat filters used since L018-L021 (read-only).
F='^\S*: *///\s*</?summary>|public bool CanRunLocally|public List<Language> Languages|public int AlgorithmHistoryDataPoints|/// This is used by the regression test system|/// Data Points count|/// Final status of the algorithm|public Dictionary<string, string> ExpectedStatistics|^\S*: *[{}]\)?;?$|^\S*: *};$|/// Initiali[sz]e the data and resolution|/// OnData event is the primary entry|/// <param name="(slice|data)">Slice object|/// End of algorithm run event handler|^\S*: *//\s*$|^\S*: *(Log|Debug)\(|^\S*: *\{ *"[^"]*", *"[^"]*" *\},?$|^\S*: *///\s*<meta name="tag"'
bash "$(dirname "$0")/print_example.sh" "$@" | grep -vE "$F"
