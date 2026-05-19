# MVP8 — Release Setup Instructions

This guide walks you through setting up the release pipeline for Kizba.
Follow steps in order.

## 1. Push the main repo to GitHub

```sh
cd /Users/kirillsimagin/dev/my/worldproject/kizba

# If no remote yet:
git remote add origin git@github.com:rodnoy/kizba.git

# Push
git push -u origin main
```

## 2. Set up the Homebrew tap repo

The `homebrew-kizba/` folder in the main project is a scaffold for the tap.
Move it out and push as a separate repo.

```sh
# From the kizba project root:
cp -R homebrew-kizba ~/dev/homebrew-kizba

# Remove the scaffold from main repo (it's not needed there)
git rm -r homebrew-kizba
git commit -m "chore: extract homebrew tap scaffold to separate repo"
git push

# Initialize the tap repo
cd ~/dev/homebrew-kizba
git init
git add .
git commit -m "Initial scaffold (placeholder cask)"
git branch -M main
git remote add origin git@github.com:rodnoy/homebrew-kizba.git
git push -u origin main
```

After this, `https://github.com/rodnoy/homebrew-kizba` should contain `README.md`, `LICENSE`, `Casks/kizba.rb` (placeholder), `.gitignore`.

## 3. Generate a fine-grained GitHub Personal Access Token (PAT)

The release workflow needs write access to the tap repo to push the updated cask
after each release. We use a fine-grained PAT with minimal scope.

### Steps

1. Go to **GitHub → Settings → Developer settings → Personal access tokens → Fine-grained tokens**.
   Direct URL: https://github.com/settings/tokens?type=beta

2. Click **Generate new token**.

3. Fill in:
   - **Token name**: `kizba-release-bot` (or anything memorable).
   - **Expiration**: choose **No expiration** (or set a long one like 1 year; you'll need to rotate manually).
   - **Resource owner**: `rodnoy`.
   - **Repository access**: **Only select repositories** → pick `rodnoy/homebrew-kizba`.
   - **Permissions**:
     - **Repository permissions** → **Contents**: **Read and write**.
     - **Repository permissions** → **Metadata**: **Read-only** (auto-selected).
     - All other permissions: leave as default (no access).

4. Click **Generate token**. **Copy the token immediately** — you won't see it again.

## 4. Add the PAT as a secret to the main repo

1. Go to `https://github.com/rodnoy/kizba/settings/secrets/actions`.
2. Click **New repository secret**.
3. Name: `HOMEBREW_TAP_TOKEN`.
4. Secret: paste the PAT.
5. Save.

## 5. (Optional) Verify the workflow setup

Push a test commit (no tag) to trigger the existing `release-audit.yml` and confirm it's green:

```sh
git commit --allow-empty -m "chore: ci smoke test"
git push
```

Check `https://github.com/rodnoy/kizba/actions`.

## 6. Cut your first release

```sh
git tag v1.0.0
git push origin v1.0.0
```

This will:
1. Trigger `.github/workflows/release.yml`.
2. Run tests.
3. Archive Kizba.app (universal binary, ad-hoc signed).
4. Zip and compute SHA256.
5. Create a GitHub Release at `https://github.com/rodnoy/kizba/releases/tag/v1.0.0`.
6. Update `Casks/kizba.rb` in `rodnoy/homebrew-kizba` with real version + sha256 + url.

Watch progress at `https://github.com/rodnoy/kizba/actions`.

Expected duration: 5-10 minutes (most time spent in test phase).

## 7. Test the install

Once the release is published:

```sh
brew tap rodnoy/kizba
brew install --cask --no-quarantine kizba
```

App should appear in `/Applications/Kizba.app` and launch without Gatekeeper warning.

### Troubleshooting

**Gatekeeper still blocks despite --no-quarantine**:
```sh
xattr -dr com.apple.quarantine /Applications/Kizba.app
```

**Workflow fails on Xcode version**:
The workflow pins to `Xcode_15.4.app`. If GitHub macos-14 runner ships a different version, update `.github/workflows/release.yml`:
```sh
ls /Applications/Xcode*.app   # see what's available on the runner via workflow logs
```
Then change the `sudo xcode-select -s /Applications/Xcode_X.Y.app` line.

**HOMEBREW_TAP_TOKEN missing**:
The workflow emits a warning and skips the tap update. The GitHub release is still created. Add the secret and re-run the workflow manually (`workflow_dispatch`).

## 8. Subsequent releases

For every new release:

```sh
git tag v1.0.1   # or v1.1.0, etc.
git push origin v1.0.1
```

Workflow auto-runs. Users get the update via `brew upgrade --cask kizba`.

## Architecture notes

- **Universal binary**: workflow archives for `generic/platform=macOS` which produces `arm64 + x86_64` together (default `$(ARCHS_STANDARD)`).
- **Ad-hoc signing**: no Apple Developer account; `codesign -s -` is used. Users must bypass Gatekeeper on first launch.
- **Notarization**: NOT performed. Requires Apple Developer Program ($99/year).
- **Hardened Runtime**: NOT enabled. Conflicts with ad-hoc signing (Hardened Runtime requires a Developer ID signing identity).
- **App Sandbox**: NOT enabled. Required because Kizba shells out to `pass`/`gpg`/`pinentry`.
- **Runtime dependencies**: `pass`, `gnupg`, `pinentry-mac` are NOT bundled; users install via Homebrew separately. The cask `caveats` reminds them.

## Future upgrades (if you get an Apple Developer account)

The workflow can be upgraded to:
1. Import a Developer ID Application certificate from a `.p12` secret.
2. Sign with the real identity (not ad-hoc).
3. Enable Hardened Runtime.
4. Notarize via `notarytool submit --wait`.
5. Staple the ticket.
6. Drop `--no-quarantine` from the cask install command.

That's a separate MVP.
