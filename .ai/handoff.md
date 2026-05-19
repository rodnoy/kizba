Phase: MVP8 (HOTFIX-2 — Xcode 26 / macos-15 CI compat)
Status: COMPLETED

Next action: User retries `git tag v1.0.0 && git push origin v1.0.0` after deleting old tag.

Notes:
- Root cause: user's Xcode 26.5 bumped pbxproj objectVersion to 77 (Xcode 26 format). macos-14 GitHub runner has max Xcode 16.4 which cannot read format 77.
- Fix: switched both workflows to runs-on: macos-15 (has Xcode 26.3 preinstalled).
- release.yml: pinned Xcode_26.3.app via xcode-select (was Xcode_16.4.app).
- release-audit.yml: switched runs-on from macos-latest to macos-15 + added xcode-select step pinning Xcode_26.3.app (was using default 16.4).
- Both workflows now also print `swift --version` after Xcode select for traceability.
- Previous Swift 6 fixes (@Sendable BannerAction, @preconcurrency TextFieldStyle) remain valid — Swift 6 in Xcode 26.3 is even stricter.
- macos-14 runner is deprecated by GitHub (deprecation starts July 6 2026, full removal Nov 2 2026). macos-15 is the path forward regardless.
- Commit: <pending — will fill after commit> on main.

User retry commands (delete old tag if it exists, then re-tag):
```
git tag -d v1.0.0
git push origin :refs/tags/v1.0.0
git tag v1.0.0
git push origin v1.0.0
```

Timestamp: 2026-05-19T11:09:53+0200
