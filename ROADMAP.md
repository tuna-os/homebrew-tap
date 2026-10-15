# Homebrew Tap Roadmap

This repository is the supported Homebrew distribution channel for TunaOS
tools. Its success is measured by whether a supported upstream release becomes
installable and stays installable, not by the number of formula files added.

## Current state (October 2026)

| Package | Channel state | Upstream ownership | Blockers |
| --- | --- | --- | --- |
| `corral-vm` | Published at v0.6.0 | GoReleaser in `tuna-os/corral` | v0.7.0 tag/release not yet published upstream |
| `bluefin-cli` | Admitted; formula publisher wired but token-gated | GoReleaser in `tuna-os/bluefin-cli` | **URGENT:** missing `HOMEBREW_TAP_TOKEN` secret; silently failed 14+ releases |
| `tavern` | Hand-maintained cask at v0.1.9 | Manual; automation not assigned | No upstream automation; source tags undocumented |

The tap has syntax validation and producer-to-consumer validation tracking in [#7](https://github.com/tuna-os/homebrew-tap/issues/7). Release-channel ownership and freshness are tracked in [#12](https://github.com/tuna-os/homebrew-tap/issues/12).

## Near term: unblock and stabilize distribution (Q4 2026)

**BLOCKING ISSUE:** bluefin-cli formula publication silently fails because the Homebrew token is not provisioned. Related: [tuna-os/bluefin-cli#295](https://github.com/tuna-os/bluefin-cli/issues/295).

**Exit gates:**
- [ ] **URGENT (maintainer decision):** Provision `HOMEBREW_TAP_TOKEN` in `tuna-os/homebrew-tap` as a repository secret; test with the next `tuna-os/bluefin-cli` release
- [ ] Publish corral-vm v0.7.0 formula update after upstream tag/release lands
- [ ] Decide whether Tavern's authoritative version is its GitHub Release or newer source tags; document update path
- [ ] Name an owner in each upstream repository for tap entry maintenance

Exit condition: every admitted entry in the catalog publishes on a 48-hour or shorter window after an eligible upstream release. No stale version claims in the README.

## Mid term: make currency observable

- [ ] Extend producer-consumer validation (#7) to confirm every upstream release mentioned in documentation has a corresponding tap entry
- [ ] Run a scheduled currency check that compares each tap entry with its authoritative upstream release and opens or updates one actionable alert
- [ ] Exercise installs on the operating systems advertised by each entry; syntax-only validation is not an install signal
- [ ] Record the release-to-tap delay and smoke-test result in pull requests

Exit condition: the supported catalog passes scheduled install checks and no entry exceeds the 48-hour freshness objective without a visible exception.

## Longer term: grow through explicit admission

New packages should be admitted only when they have:

1. a stable, versioned upstream release with supported Homebrew assets or a reproducible source build;
2. an upstream owner and automated update path (or documented manual process with named owner);
3. an install test on every advertised platform; and
4. a rollback or disable path for broken releases.

Review the catalog quarterly. Remove unsupported entries deliberately instead of allowing them to become silent, stale installation paths.

## Health measures

| Measure | Target |
| --- | --- |
| Eligible release to tap update or exception | 48 hours or less |
| Supported entries with a named upstream owner | 100% |
| Scheduled install checks passing | 100% |
| Admitted entries without a token/credential provisioned | 0 |

## Roadmap Governance

This roadmap is maintained by the strategist agent. Updates are published after
major milestones or quarterly. Propose changes via PR to this file with an issue
reference.

---
*Updated October 15, 2026 by strategist agent (ACMM L6 — full mode)*
