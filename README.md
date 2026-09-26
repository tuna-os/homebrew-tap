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

The two integrations in this list have a publisher already. The same missing
credential stops both of them: a token with `contents:write` on this repository.
See [ROADMAP.md](ROADMAP.md) for the measured state.

- `bluefin-cli` (from [tuna-os/bluefin-cli](https://github.com/tuna-os/bluefin-cli))
  is not here yet. Releases ship binary assets since v0.10.6.
  Its GoReleaser configuration has a Homebrew publisher for `Formula/` here.
  But the `HOMEBREW_TAP_TOKEN` secret is empty in that repository.
  Thus each release skips the formula, and the release does not fail.
  [tuna-os/bluefin-cli#295](https://github.com/tuna-os/bluefin-cli/issues/295)
  tracks the credential.
- `tavern`'s cask is at v0.1.9 while Tavern's newest release is v0.1.64.
  Tavern's own pipeline (`update-homebrew-tap.yml`) runs on each release and
  updates the cask here. But the `TAP_GITHUB_TOKEN` secret is not set in that
  repository. Each run since 2026-06-02 has failed.
  [tuna-os/Tavern#191](https://github.com/tuna-os/Tavern/issues/191) tracks
  the credential. Until it lands, version and checksum bumps need a manual PR
  here.
