#!/usr/bin/env bash
set -euo pipefail

echo "Checking Ruby syntax for formulas and casks..."
find Formula Casks -name "*.rb" -type f -exec ruby -c {} +
echo "All formulas and casks passed syntax validation."
