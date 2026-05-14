Cleared on 2026-05-14 12:04:06 — previous failing test output was stale and removed.

Verification performed:

- xcodebuild clean build -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS'
- xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS'

All tests passed during the verification run. See .ai/build-log.md for the success summary.
