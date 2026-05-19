# MVP8 — Release & Distribution

## Status

SHIPPED in single pass.

## What was done

### Pre-flight project fixes
- `Kizba.xcodeproj/project.pbxproj` Release config: added `CODE_SIGN_ENTITLEMENTS = Kizba/Kizba.entitlements` and `CODE_SIGN_IDENTITY = "-"` (ad-hoc) for `Kizba` target.
- No changes to Debug config (preserves local Automatic signing for dev).
- No `ENABLE_HARDENED_RUNTIME = YES` — conflicts with ad-hoc signing without Apple Developer account.

### LICENSE
- Added `LICENSE` (MIT) to project root.

### CI workflow
- New `.github/workflows/release.yml`:
  - Triggers on `push: tags: ['v*.*.*']` and `workflow_dispatch`.
  - Resolves version from tag (`v1.0.0` → `1.0.0`), build number from `git rev-list --count HEAD`.
  - Runs full test suite first.
  - `xcodebuild archive` for `generic/platform=macOS` (universal arm64+x86_64).
  - Ad-hoc signs via `codesign -s - --options runtime --entitlements Kizba/Kizba.entitlements`.
  - Verifies architecture via `lipo -info`.
  - Zips via `ditto`, computes SHA256.
  - Creates GitHub Release with install instructions in body.
  - Updates `rodnoy/homebrew-kizba` tap via `HOMEBREW_TAP_TOKEN` secret (rendered cask with real version + sha256).

### Homebrew tap scaffold
- New `homebrew-kizba/` folder in main project — meant to be extracted to a separate repo.
- Contains: `README.md`, `LICENSE` (MIT), `Casks/kizba.rb` (placeholder — first release workflow overwrites with real values), `.gitignore`.

### Documentation
- New `MVP8-RELEASE.md` with step-by-step instructions:
  1. Push main repo to GitHub.
  2. Extract `homebrew-kizba/` to separate repo + push.
  3. Generate fine-grained PAT for tap write access.
  4. Add `HOMEBREW_TAP_TOKEN` secret to main repo.
  5. Cut first release via `git tag v1.0.0 && git push origin v1.0.0`.
  6. Test install via `brew tap rodnoy/kizba && brew install --cask --no-quarantine kizba`.

## What's deferred

- **Apple Developer signing + notarization**: needs $99/year account. Future MVP can upgrade workflow to use real Developer ID + notarytool. Current ad-hoc + `--no-quarantine` works but degrades UX.
- **DMG distribution**: cask uses zip for simplicity. DMG requires `create-dmg` and design.
- **Auto-update mechanism inside the app** (Sparkle / etc.): not in scope.

## User next steps

Follow `MVP8-RELEASE.md` step-by-step.
