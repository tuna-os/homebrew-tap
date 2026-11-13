# Contributing to the TunaOS Homebrew Tap

Thank you for your help with the TunaOS Homebrew channel.

<!-- hive-contribute-plea: donated-compute appeal, keep in sync across repos -->
## Contribute compute — no code needed

**[Donate time with your AI CLI](https://hub.tunaos.org/#contribute).**

Your machine runs one task at a time using your signed-in AI coding CLI.
The relay alternates between eligible **School** (OS) and **Reef** (apps)
hives after each task. If one hive has no work, the other can continue.

The guide covers prerequisites, verified `just` setup, credentials, provider
costs, and how to stop with Ctrl+C. Your subscription quota or API charges apply.
Never post account credentials or API keys in issues or pull requests.

## Repository layout

- `Formula/` contains source-built Homebrew formulae.
- `Casks/` contains packaged application casks.
- `scripts/validate-tap.sh` checks every formula and cask. It checks the Ruby
  syntax, the download URLs, and the `sha256` digests.
- `scripts/test-validate-tap.sh` is the regression suite for the validation
  script.
- `README.md` lists packages that are available now or not yet added.
- `ROADMAP.md` describes admission, ownership, freshness, and validation goals.

Each upstream project owns its own formula and cask releases. Before you
change a version, URL, checksum, or supported platform, check the matching
release in the upstream repository linked from the package definition.

## Local prerequisites

The repository's validation script needs:

- Bash
- Ruby, including the `ruby` executable on `PATH`

Homebrew is also needed for install or package-specific tests, but it is not
required by the syntax validation script.

## Making a change

1. Create a branch from the latest `main`.
2. Update the formula, cask, or documentation.
3. Run the local validation command from the repository root:

   ```sh
   ./scripts/validate-tap.sh
   ```

   If you change `scripts/validate-tap.sh`, also run its regression suite:

   ```sh
   bash scripts/test-validate-tap.sh
   ```

4. In the pull request, name the upstream release or issue that motivates
   the change. For a release update, state how you checked the download URL
   and the checksum.

The validation script runs `ruby -c` against every `.rb` file under `Formula/`
and `Casks/`. It also makes sure that each download URL is under
`https://github.com/tuna-os/` and that each download has a 64-character
`sha256` digest. It does not download artifacts or compare a digest with the
downloaded file.

CI (`.github/workflows/ci.yml`) runs the regression suite and the validation
script. It also runs `brew audit` and installs `corral-vm` and the `tavern`
cask on Linux. CI does not install `bluefin-cli`, and it does not install on
macOS. For these packages, examine the download URL and the checksum
yourself.

Run the script for documentation-only changes too, when Ruby is available, so
the pull request reports the repository's current validation state.
