Commands run:

- xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' -only-testing:KizbaTests/AppRouterTests
- xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS'
- rg -n '\\bas!\\b' Kizba || true
- rg -n 'Logger.*stdin|print\\(.*stdin' Kizba || true

Summary:

- AppRouter focused tests: 3 passed, 0 failed.
 - Full test suite: 702 tests executed, 8 skipped, 20 failures (TEST FAILED).

Relevant artifacts:
 - Commit: 70e88f7 — feat(mvp3): add AppRouter scaffold + inject router into AppState (B.1)
 - Git HEAD: c741098
 - Date: 2026-05-10
