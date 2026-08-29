#!/usr/bin/env bash
set -euo pipefail

if command -v ruby >/dev/null 2>&1; then
    echo "Checking Ruby syntax for formulas and casks using ruby -c..."
    find Formula Casks -name "*.rb" -type f -exec ruby -c {} +
elif command -v brew >/dev/null 2>&1; then
    echo "Checking formulas and casks using brew readall..."
    brew readall --aliases
else
    echo "WARNING: Neither ruby nor brew found; skipping syntax check." >&2
    exit 0
fi

echo "All formulas and casks passed syntax validation."
