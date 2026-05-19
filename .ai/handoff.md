Phase: MVP8 (COMPLETED — Release & Distribution scaffolded)
Status: SHIPPED — workflow + tap scaffold + LICENSE + instructions ready

Next action: Пользователь следует MVP8-RELEASE.md (push repo → extract tap → generate PAT → add secret → tag v1.0.0).

Notes:
- Pre-flight fixes in Kizba.xcodeproj/project.pbxproj (Release config of Kizba target): added CODE_SIGN_ENTITLEMENTS = Kizba/Kizba.entitlements; CODE_SIGN_IDENTITY = "-". Debug config untouched (Automatic + Apple Development preserved).
- LICENSE (MIT) added at repo root.
- .github/workflows/release.yml: full pipeline (resolve tag → select Xcode 15.4 → test → archive Release universal → ad-hoc codesign with entitlements → lipo verify → ditto zip → sha256 → GitHub Release → render & push cask to rodnoy/homebrew-kizba via HOMEBREW_TAP_TOKEN).
- homebrew-kizba/ scaffold (README.md, LICENSE, Casks/kizba.rb placeholder, .gitignore) ready to be extracted into separate repo git@github.com:rodnoy/homebrew-kizba.git.
- MVP8-RELEASE.md: step-by-step setup (push repo, extract tap, fine-grained PAT scope, secret, first tag, troubleshooting).
- Ad-hoc signed; no notarization (no Apple Developer account). Cask uses --no-quarantine; caveats document xattr fallback.
- Universal binary (arm64 + x86_64) via default ARCHS_STANDARD on generic/platform=macOS archive.
- Existing .github/workflows/release-audit.yml left as-is (independent trigger on v* tags — runs in parallel with new release workflow).
- Sanity Debug build: OK (xcodebuild -scheme Kizba -configuration Debug -destination 'platform=macOS' -quiet succeeded).
- Commit: <hash filled by git below>.

Timestamp: 2026-05-19T09:25:00+0200
