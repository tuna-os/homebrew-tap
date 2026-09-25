#!/usr/bin/env bash
# Tests for validate-tap.sh's three branches (ruby, brew fallback, neither
# present) plus its per-file failure detection. Stubs ruby/brew as fake
# executables on PATH so the suite runs without either installed, and copies
# the real script into a scratch repo tree so Formula/Casks fixtures never
# touch the actual tap contents.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT="$REPO_ROOT/scripts/validate-tap.sh"
BASH_BIN="$(command -v bash)"

pass=0
fail=0

assert_exit() {
    local desc="$1" expected="$2" actual="$3"
    if [ "$actual" -eq "$expected" ]; then
        echo "  ok: $desc"
        pass=$((pass + 1))
    else
        echo "  FAIL: $desc (expected exit $expected, got $actual)" >&2
        fail=$((fail + 1))
    fi
}

assert_contains() {
    local desc="$1" needle="$2" haystack="$3"
    if [[ "$haystack" == *"$needle"* ]]; then
        echo "  ok: $desc"
        pass=$((pass + 1))
    else
        echo "  FAIL: $desc (expected output to contain: $needle)" >&2
        fail=$((fail + 1))
    fi
}

fake_bin_dir=""
setup_fake_bin() {
    fake_bin_dir="$(mktemp -d)"
}
teardown_fake_bin() {
    rm -rf "$fake_bin_dir"
    fake_bin_dir=""
}

# --- Case 1: all files valid under ruby -c ---------------------------------
setup_fake_bin
cat >"$fake_bin_dir/ruby" <<'EOF'
#!/usr/bin/env bash
[ "$1" = "-c" ] || exit 1
echo "Syntax OK"
exit 0
EOF
chmod +x "$fake_bin_dir/ruby"

scratch="$(mktemp -d)"
mkdir -p "$scratch/Formula" "$scratch/Casks"
cat >"$scratch/Formula/foo.rb" <<'EOF'
class Foo < Formula
  url "https://github.com/tuna-os/foo/archive/refs/tags/v1.0.0.tar.gz"
  sha256 "0000000000000000000000000000000000000000000000000000000000000000"
end
EOF
cat >"$scratch/Casks/bar.rb" <<'EOF'
cask "bar" do
  url "https://github.com/tuna-os/bar/releases/download/v1.0.0/bar.zip"
  sha256 "1111111111111111111111111111111111111111111111111111111111111111"
end
EOF
out="$(cd "$scratch" && PATH="$fake_bin_dir:$PATH" bash "$SCRIPT" 2>&1)"; code=$?
assert_exit "all-valid: exits 0" 0 "$code"
assert_contains "all-valid: reports success" "All formulas and casks passed syntax and download validation." "$out"
rm -rf "$scratch"
teardown_fake_bin

# --- Case 2: one malformed file among several fails the whole run ----------
# Regression guard for the batching bug the script's own comments describe:
# `ruby -c a.rb b.rb` only ever checks the first argument, so a naive rewrite
# back to batched invocation would silently stop catching this.
setup_fake_bin
cat >"$fake_bin_dir/ruby" <<'EOF'
#!/usr/bin/env bash
[ "$1" = "-c" ] || exit 1
file="$2"
if grep -q BROKEN "$file"; then
    echo "syntax error" >&2
    exit 1
fi
echo "Syntax OK"
exit 0
EOF
chmod +x "$fake_bin_dir/ruby"

scratch="$(mktemp -d)"
mkdir -p "$scratch/Formula" "$scratch/Casks"
echo 'class Foo; end' >"$scratch/Formula/foo.rb"
echo 'BROKEN(' >"$scratch/Casks/bar.rb"
out="$(cd "$scratch" && PATH="$fake_bin_dir:$PATH" bash "$SCRIPT" 2>&1)"; code=$?
assert_exit "one-broken: exits 1" 1 "$code"
assert_contains "one-broken: reports the failing file" "FAIL: Casks/bar.rb" "$out"
assert_contains "one-broken: still checks the good file" "ok: Formula/foo.rb" "$out"
rm -rf "$scratch"
teardown_fake_bin

# --- Case 3: no ruby, brew present -> falls back to brew readall -----------
setup_fake_bin
cat >"$fake_bin_dir/brew" <<'EOF'
#!/usr/bin/env bash
[ "$1" = "readall" ] && [ "$2" = "--aliases" ] || exit 1
echo "brew readall ran"
exit 0
EOF
chmod +x "$fake_bin_dir/brew"

scratch="$(mktemp -d)"
mkdir -p "$scratch/Formula" "$scratch/Casks"
out="$(cd "$scratch" && PATH="$fake_bin_dir:/usr/bin:/bin" bash -c '
    hash -r
    exec bash "'"$SCRIPT"'"
' 2>&1)"; code=$?
if command -v ruby >/dev/null 2>&1; then
    echo "  skip: brew-fallback case (real ruby present on PATH, cannot isolate)"
else
    assert_exit "brew-fallback: exits 0" 0 "$code"
    assert_contains "brew-fallback: uses brew readall" "brew readall ran" "$out"
fi
rm -rf "$scratch"
teardown_fake_bin

# --- Case 4: neither ruby nor brew -> warns and exits 0 ---------------------
if command -v ruby >/dev/null 2>&1 || command -v brew >/dev/null 2>&1; then
    echo "  skip: neither-present case (ruby or brew installed on this host, cannot isolate)"
else
    scratch="$(mktemp -d)"
    mkdir -p "$scratch/Formula" "$scratch/Casks"
    out="$(cd "$scratch" && PATH="/nonexistent" "$BASH_BIN" "$SCRIPT" 2>&1)"; code=$?
    assert_exit "neither-present: exits 0" 0 "$code"
    assert_contains "neither-present: warns" "WARNING: Neither ruby nor brew found" "$out"
    rm -rf "$scratch"
fi

echo
echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]
