# Recovering from a bad Tavern cask release

This runbook covers how to identify, disable, and recover from a broken Tavern cask published to this tap.

## When to use this runbook

Use this when:
- A Tavern cask release is already published to `tuna-os/homebrew-tap` on `main`
- Users may have already installed it via `brew install --cask tavern`
- The release has a broken checksum, bad download URL, corrupt AppImage, or broken AppRun patches (see [Casks/tavern.rb](../Casks/tavern.rb) for the two patches applied at install time)
- You need to make it uninstallable or point to a known-good version

This is different from catching a problem *before* publishing — that happens in the pull request review phase. This runbook is for *after* it's already live.

## Step 1: Confirm the release is broken

Before rolling back, verify the actual failure so you don't revert a working release on false alarm.

### On macOS

```bash
# Try to install the current cask version
brew install --cask tavern

# Check the install exit code
echo $?

# If installation succeeded, try to run the app
open /Applications/Tavern.app
# Does it launch? Can you open a window? Does it crash?
```

### On Linux

```bash
# Try to install the current cask version (requires Homebrew on Linux)
brew install --cask tavern

# Check the install exit code
echo $?

# If installation succeeded, try to run the installed binary
~/.linuxbrew/bin/tavern --version
# or check ~/.local/bin/tavern if using a different Homebrew prefix
# Does it print a version? Does it segfault?
```

### Review the cask changes in the pull request or commit

Look at the version bump in [Casks/tavern.rb](../Casks/tavern.rb):
- Did the `sha256` digest change correctly from the new release artifact?
- Did the `url` field stay valid (no typos, no broken GitHub release link)?
- Are there new AppRun or AppImage patches that might conflict with the new release's structure?

The two patches in the cask are:
1. Fix AppRun's `$0`-based path resolution when symlinked
2. Set `TAVERN_DATADIR` and `TAVERN_LOCALEDIR` environment variables

If the new AppImage changed its directory structure or already includes these fixes, the patches may fail or cause undefined behavior.

## Step 2: Disable the broken version

### Option A: Revert the entire cask commit (safest if the problem is recent)

```bash
# Find the commit that published the broken version
git log -1 Casks/tavern.rb

# Revert it
git revert <commit-hash> -m1

# Push and open a PR
git push origin operations/tavern-cask-rollback-<version>
```

Create a PR from this branch with title: `[operations] Revert Tavern cask to known-good version — <broken-version> has <failure-mode>`

In the PR description, include:
- Steps taken to confirm the breakage
- Which platforms are affected (macOS, Linux, or both)
- The commits being reverted and why
- Evidence (install transcript, error message, crash log)

### Option B: Bump back to a specific known-good version (if a quick forward-fix is ready)

```bash
# Edit Casks/tavern.rb manually
# - Change version to the last known-good release (e.g., v0.1.8)
# - Update sha256 to match that release's artifact checksum
# - Update url if needed

# Verify the change locally if possible
ruby -c Casks/tavern.rb

# Commit with a clear message
git commit -s Casks/tavern.rb -m "chore: pin Tavern cask to v0.1.<N> — v0.1.<N+1> is broken"

# Push and open a PR
git push origin operations/tavern-cask-rollback-<known-good-version>
```

## Step 3: Notify downstream

### Homebrew Core cache

Homebrew Core (the default Homebrew formulae repository) mirrors and caches popular taps. If the broken version was already in their cache, they may serve it even after you revert here.

Check if Tavern is in Homebrew Core:
```bash
# This command will not work from this tap, but you can check the Homebrew Core repo manually
curl -s https://api.github.com/repos/homebrew/homebrew-core/contents/Casks/tavern.rb | grep '"sha"' | head -1
# If it exists, that's the Homebrew Core mirror
```

If it exists in Homebrew Core, open an issue or PR in [Homebrew Core](https://github.com/homebrew/homebrew-core) asking them to revert the broken version so their cache doesn't serve stale installs.

### Users who already installed

If the broken release was live for hours or days, users may have already installed it. There is no automatic way to notify them, but consider:
- A release note in the next good Tavern release (upstream in [tuna-os/Tavern](https://github.com/tuna-os/Tavern))
- A note in this tap's README if the breakage was severe or widespread

## Step 4: Prevention

After rollback, prevent a repeat:

1. **Automate version updates** (requires workflow changes, out of reach for this agent):
   - Add a GitHub Actions workflow to detect new Tavern releases and auto-open a PR within 24 hours
   - Gate the PR with install tests on both macOS and Linux before auto-merge
   - See [ROADMAP.md](../ROADMAP.md#mid-term-make-currency-observable) for the mid-term objective

2. **Review cask patches on every bump**:
   - The two patches in [Casks/tavern.rb](../Casks/tavern.rb) are applied at install time
   - On every version update, verify the new AppImage still needs these patches
   - If the new release already includes these fixes, remove the patches to avoid conflicts

3. **Document known-good versions**:
   - Keep a comment in the cask listing which versions are known to work
   - E.g., "Last verified working: v0.1.9 on macOS 14+, Linux AppImage"

## References

- [Homebrew Tap Roadmap](../ROADMAP.md) — mid-term health measures
- [Casks/tavern.rb](../Casks/tavern.rb) — AppRun and AppImage patches
- [tuna-os/Tavern](https://github.com/tuna-os/Tavern) — upstream release source
- Homebrew Cask documentation: https://docs.brew.sh/Cask-Cookbook
