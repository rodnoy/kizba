Cleared on 2026-05-16 21:58:17 — previous failing test output was stale and removed.

Verification performed:

- xcodebuild clean build -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS'
- xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS'

Result: All tests passed during the verification run.

Test summary: Executed 980 tests, Skipped 17, Failures 0.
