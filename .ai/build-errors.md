Cleared on 2026-05-16 22:29:38 — previous failing test output was stale and removed.

Verification performed:

- xcodebuild clean build -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS'
- xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS'

Result: All tests passed during the verification run.

Test summary: Executed 988 tests, Skipped 17, Failures 0.
