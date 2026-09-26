# Homebrew Tap Roadmap

This repository is the supported Homebrew distribution channel for TunaOS
tools. Its success is measured by whether a supported upstream release becomes
installable and stays installable, not by the number of formula files added.

## Current state (measured 2026-09-24)

| Package | Tap has | Upstream has | Publisher | Blocker |
| --- | --- | --- | --- | --- |
| `corral-vm` | Formula at v0.6.0, built from the source tag | Tag v0.6.0 (no GitHub Release); latest Release v0.5.0; v0.7.0 in preparation ([corral#339](https://github.com/tuna-os/corral/issues/339)) | Manual. Both bumps in this repository's history were hand commits; corral's GoReleaser configuration has no Homebrew publisher | Every corral release needs a hand PR here until a publisher is added |
| `tavern` | Cask at v0.1.9 (released 2026-06-15) | v0.1.64 (2026-09-15), ten releases and 92 days newer, with the macOS zip, Linux AppImage and `SHA256SUMS` the cask needs | Automated in Tavern: `update-homebrew-tap.yml`, dispatched by `release.yml` on every release | `TAP_GITHUB_TOKEN` is unset in Tavern; all eight runs since 2026-06-02 failed at "Require the org tap credential" ([Tavern#191](https://github.com/tuna-os/Tavern/issues/191)) |
| `bluefin-cli` | No formula | v0.11.3 (2026-09-16), 17 assets; binaries since v0.10.6 | Automated in bluefin-cli: GoReleaser `brews` block targeting `Formula/` here | `HOMEBREW_TAP_TOKEN` is empty in bluefin-cli's release workflow, so `skip_upload` resolves to `true` and every release skips the formula without failing ([bluefin-cli#295](https://github.com/tuna-os/bluefin-cli/issues/295)) |

Two of the three packages already have a publisher in their own repository.
Both are blocked by the same missing credential: a token with `contents:write`
on this repository, stored as `TAP_GITHUB_TOKEN` in Tavern and
`HOMEBREW_TAP_TOKEN` in bluefin-cli. Neither producer can see the other's
failure, and this repository has had no record that its 48-hour objective
(below) has been missed by 92 days on Tavern and never met on bluefin-cli.
[#49](https://github.com/tuna-os/homebrew-tap/issues/49) records
the measurement.

The tap enforces per-file Ruby syntax, organization-owned download URLs and
pinned SHA-256 digests via `scripts/validate-tap.sh` in pre-merge CI.
Producer-to-consumer validation (install checks) is tracked in
[#7](https://github.com/tuna-os/homebrew-tap/issues/7); the validator's own
regression suite is disconnected from CI and red
([#48](https://github.com/tuna-os/homebrew-tap/issues/48)). Release-channel
ownership and freshness are tracked in
[#12](https://github.com/tuna-os/homebrew-tap/issues/12).

## Near term: define the supported channel

- [x] Pre-merge validation of every formula and cask: syntax, URL ownership,
  pinned digest (`scripts/validate-tap.sh`, #26, #31).
- [x] Tavern's authoritative version: its GitHub Releases are current again
  (v0.1.64 is both the newest tag and the newest Release), so the cask
  follows Releases and the question is closed.
- [ ] Provision the tap write credential (`contents:write` on this repository)
  and set it as `TAP_GITHUB_TOKEN` in Tavern and `HOMEBREW_TAP_TOKEN` in
  bluefin-cli. Needs an org admin; nothing in any tree is wrong
  ([Tavern#191](https://github.com/tuna-os/Tavern/issues/191),
  [bluefin-cli#295](https://github.com/tuna-os/bluefin-cli/issues/295)).
- [ ] Once the credential exists, re-dispatch Tavern's `Update Homebrew Tap`
  for v0.1.64 and re-run or wait for the next bluefin-cli release, then
  confirm `Casks/tavern.rb` and `Formula/bluefin-cli.rb` are current.
- [ ] Decide corral-vm's publisher: add a GoReleaser Homebrew block in corral,
  or keep manual bumps with a named owner. v0.7.0
  ([corral#339](https://github.com/tuna-os/corral/issues/339)) is the next
  release that will need one.
- [ ] Set a release-currency objective: update a supported formula or cask, or
  publish a visible exception, within 48 hours of an eligible upstream release.

Exit condition: every entry in the catalog has an authoritative upstream
release source, a working publisher (or a named owner for manual bumps), and
no entry is behind its upstream release without a visible exception.

## Mid term: make currency observable

- [ ] Add producer-consumer validation that checks URLs, checksums, and installs
  for proposed formula and cask changes (#7).
- [ ] Run a scheduled currency check that compares each tap entry with its
  authoritative upstream release and opens or updates one actionable alert.
- [ ] Exercise installs on the operating systems advertised by each entry;
  syntax-only validation is not an install signal.
- [ ] Record the release-to-tap delay and smoke-test result in pull requests.

Exit condition: the supported catalog passes scheduled install checks and no
entry exceeds the freshness objective without a visible exception.

## Longer term: grow through explicit admission

New packages should be admitted only when they have:

1. a stable, versioned upstream release with supported Homebrew assets or a
   reproducible source build;
2. an upstream owner and automated update path;
3. an install test on every advertised platform; and
4. a rollback or disable path for broken releases.

Review the catalog quarterly. Remove unsupported entries deliberately instead
of allowing them to become silent, stale installation paths.

## Health measures

| Measure | Target |
| --- | --- |
| Eligible release to tap update or exception | 48 hours or less (2026-09-24: Tavern 92 days behind, bluefin-cli never published, corral-vm current with v0.6.0 but v0.5.0 is the last Release) |
| Supported entries with a named upstream owner | 100% |
| Scheduled install checks passing | 100% |
| Advertised pending entries without an owner/tracker | 0 |
