# TunaOS Homebrew Tap

Homebrew tap for TunaOS tooling. Upstream repos' release pipelines (e.g.
GoReleaser) publish the formulas and casks here.

## Currently available

| Formula/cask | Install |
|---------|---------|
| [corral-vm](https://github.com/tuna-os/corral) | `brew install corral-vm` |
| [tavern](https://github.com/tuna-os/Tavern) (cask, macOS + Linux) | `brew install --cask tavern` |

```sh
brew tap tuna-os/tap
brew install corral-vm
brew install --cask tavern
```

## Contributing

See [the contribution guide](CONTRIBUTING.md) for the repository layout,
local prerequisites, and the checks needed before a formula, cask, or
documentation change.

## Pending

Both pending integrations have a publisher already; both are blocked on the
same missing credential (a token with `contents:write` on this repository).
See [ROADMAP.md](ROADMAP.md) for the measured state.

- `bluefin-cli` (from [tuna-os/bluefin-cli](https://github.com/tuna-os/bluefin-cli))
  is not here yet. Releases ship binary assets since v0.10.6, and its
  GoReleaser configuration has a Homebrew publisher aimed at `Formula/` here,
  but the `HOMEBREW_TAP_TOKEN` secret is empty in that repository, so every
  release skips the formula without failing.
  [tuna-os/bluefin-cli#295](https://github.com/tuna-os/bluefin-cli/issues/295)
  tracks the credential.
- `tavern`'s cask is at v0.1.9 while Tavern's newest release is v0.1.64.
  Tavern's own pipeline (`update-homebrew-tap.yml`, run on every release)
  updates the cask here, but the `TAP_GITHUB_TOKEN` secret is unset in that
  repository and every run has failed since 2026-06-02.
  [tuna-os/Tavern#191](https://github.com/tuna-os/Tavern/issues/191) tracks
  the credential. Until it lands, version and checksum bumps need a manual PR
  here.
