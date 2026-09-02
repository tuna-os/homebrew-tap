#!/usr/bin/env bash
set -euo pipefail

if command -v ruby >/dev/null 2>&1; then
    echo "Checking Ruby syntax for formulas and casks using ruby -c..."
    # One ruby -c per file, deliberately. `ruby -c a.rb b.rb` does NOT check
    # both: ruby parses the first argument and passes the rest through as
    # ARGV, so it prints a single "Syntax OK" and exits 0 even when every
    # later file is malformed. Batching with `-exec ... +` therefore validated
    # only whichever file find happened to list first.
    status=0
    while IFS= read -r -d '' file; do
        if ruby -c "$file" >/dev/null; then
            echo "  ok: $file"
        else
            echo "  FAIL: $file" >&2
            status=1
        fi
    done < <(find Formula Casks -name "*.rb" -type f -print0)

    if [ "$status" -ne 0 ]; then
        echo "Syntax validation failed." >&2
        exit 1
    fi
elif command -v brew >/dev/null 2>&1; then
    echo "Checking formulas and casks using brew readall..."
    brew readall --aliases
else
    echo "WARNING: Neither ruby nor brew found; skipping syntax check." >&2
    exit 0
fi

echo "All formulas and casks passed syntax validation."
