# AGENTS.md — agent guide for tuna-os/homebrew-tap

The **Homebrew tap** for TunaOS tools: what `brew tap tuna-os/tap` resolves
against. `Formula/` holds source-built formulae, `Casks/` packaged apps.

Human docs: [`README.md`](README.md), [`CONTRIBUTING.md`](CONTRIBUTING.md),
[`ROADMAP.md`](ROADMAP.md) (the admission and freshness contract).

## A green check means "it parses", not "it installs"

`scripts/validate-tap.sh` runs `ruby -c` and nothing else. It does not download
artifacts, verify a checksum, or install anything — so a formula pointing at a
404 URL or a wrong `sha256` passes CI and fails in the user's terminal.
Producer-to-consumer validation is tracked in
[#7](https://github.com/tuna-os/homebrew-tap/issues/7); until it exists, verify
URLs and digests by hand and say in the PR how you did it.

Two details of that script are load-bearing:

- **One `ruby -c` per file, deliberately.** `ruby -c a.rb b.rb` does *not*
  check both — ruby parses the first argument and passes the rest through as
  `ARGV`, printing a single `Syntax OK` and exiting 0 even when every later
  file is malformed. The earlier `find … -exec ruby -c {} +` therefore
  validated only whichever file `find` listed first. Do not re-batch it.
- **CI asserts `ruby --version` before running the script.** The script
  intentionally exits 0 with a warning when neither `ruby` nor `brew` is on
  `PATH` — right on a laptop, wrong in a gate, where it would report success
  without having checked anything.

## CI is path-filtered

`ci.yml` triggers only on `Formula/**`, `Casks/**`, `scripts/**` and itself. A
docs-only PR runs no jobs at all. That is fine as a cost decision and a trap as
a *required* check: a required check that never runs stays pending forever and
blocks the merge. If this workflow is ever marked required — for branch
protection or for agent auto-merge — add an aggregator job that runs
unconditionally and reports success when the real job is skipped.

`codecov.yml` sets a 45% project target, but nothing here produces or uploads
coverage (there is no test suite, only a bash syntax check). It is inert
configuration, not a gate.

## Ownership: upstream publishes, mostly

`corral-vm` is published by GoReleaser from `tuna-os/corral` — a hand edit to
its version or `sha256` is overwritten by the next release, so fix it upstream.
It is named `corral-vm` only to avoid clashing with homebrew/core's unrelated
`corral`; the installed command is still `corral`.

Tavern's pipeline updates only the cask version and checksums. Its
`TAP_GITHUB_TOKEN` is still missing (Tavern#299), so manual bumps remain
necessary. Cask structure and lifecycle changes belong in this repository.

## The tavern cask's IDs are pinned to the released binary, not to Tavern's tree

The v0.1.65 AppImage contains `org.tunaos.tavern.desktop` / `.svg`; the
macOS ZIP's `Info.plist` also identifies the app as `org.tunaos.tavern`.
The cask's artifacts and cleanup paths follow those inspected release
identities. Do not infer either platform's ID from the current source tree
or assume they always match: extract each new release before updating.

The `preflight` block also patches the extracted `AppRun`: it rewrites `$0`
path resolution (broken when AppRun is reached through a symlink in
`HOMEBREW_PREFIX/bin`) and exports `TAVERN_DATADIR`/`TAVERN_LOCALEDIR` so the
Python app finds its gresource and icons inside the AppDir instead of the
hardcoded meson prefix. Both patches require the inspected AppRun strings;
preflight refuses an unrecognized launcher rather than silently leaving it
unpatched. Both launchers need the declared Homebrew Python/GTK dependencies.

## Skill: bump-the-tavern-cask

1. Find the new release and its assets:
   `Tavern-macOS.zip` and `Tavern-Linux.AppImage` under
   `https://github.com/tuna-os/Tavern/releases/download/v<version>/`.
2. Download both and take real digests — do not copy a digest from release
   notes: `curl -sSfL -o - <url> | sha256sum`.
3. Update `version`, then **both** `sha256` values — they live in separate
   `on_macos` and `on_linux` blocks and it is easy to update one.
4. Extract the AppImage and inspect its application/icon paths, AppRun,
   wrapped executable and GTK hook. Inspect `Tavern.app/Contents/Info.plist`
   in the ZIP independently. Update platform-specific artifact, desktop,
   icon and cleanup paths only to match the corresponding released bytes.
5. Exercise the actual `preflight` block in an isolated staging directory
   and temporary HOME. Launch through a bin symlink, checking data/resource,
   typelib and library lookup. Never run cleanup against a real user HOME.
6. `bash scripts/validate-tap.sh`, then note in the PR how the digests were
   obtained.
