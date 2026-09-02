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
fi

# Syntax is not the part of a tap that carries security weight: every url and
# sha256 here decides what a `brew install` downloads and runs. These checks
# need no ruby or brew, so they run even when the syntax check above was
# skipped.
echo "Checking download URLs and digests..."

ALLOWED_URL_PREFIX="https://github.com/tuna-os/"
download_status=0

fail() {
    echo "  FAIL: $1" >&2
    download_status=1
}

while IFS= read -r -d '' file; do
    file_status="$download_status"

    # url and head both name something Homebrew fetches. Keeping them inside
    # the org means a repointed download cannot pass review as a digest bump.
    while IFS= read -r entry; do
        line_number="${entry%%:*}"
        url="$(printf '%s' "${entry#*:}" | grep -oE '[a-z]+://[^"]+' | head -n 1)"
        case "$url" in
            "$ALLOWED_URL_PREFIX"*) ;;
            *) fail "$file:$line_number: download URL is not under $ALLOWED_URL_PREFIX: ${url:-<unparsed>}" ;;
        esac
    done < <(grep -nE '^[[:space:]]*(url|head)[[:space:]]+"' "$file" || true)

    # sha256 :no_check turns off download verification entirely.
    while IFS= read -r entry; do
        fail "$file:${entry%%:*}: sha256 :no_check disables download verification"
    done < <(grep -nE '^[[:space:]]*sha256[[:space:]]+:no_check' "$file" || true)

    while IFS= read -r entry; do
        digest="$(printf '%s' "${entry#*:}" | grep -oE '"[^"]*"' | head -n 1 | tr -d '"')"
        if ! printf '%s' "$digest" | grep -qE '^[0-9a-f]{64}$'; then
            fail "$file:${entry%%:*}: sha256 must be 64 lowercase hex characters: $digest"
        fi
    done < <(grep -nE '^[[:space:]]*sha256[[:space:]]+"' "$file" || true)

    if ! grep -qE '^[[:space:]]*sha256[[:space:]]+"' "$file"; then
        fail "$file: no pinned sha256 — every download must be digest-pinned"
    fi

    if [ "$download_status" -eq "$file_status" ]; then
        echo "  ok: $file"
    fi
done < <(find Formula Casks -name "*.rb" -type f -print0)

if [ "$download_status" -ne 0 ]; then
    echo "Download validation failed." >&2
    exit 1
fi

echo "All formulas and casks passed syntax and download validation."
