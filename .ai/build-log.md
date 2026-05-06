# Kizba — Build Log

## 2026-05-06 — Step 1.1 (Domain types)

```
xcodebuild -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' build
=> ** BUILD SUCCEEDED **

xcodebuild -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' test
=> ** TEST SUCCEEDED **
   Executed 14 tests, with 0 failures (0 unexpected) in 4.744 (4.787) seconds
```

Test suites:

- KizbaTests (existing): 2 passed.
- PassEntryTests: 4 passed.
- PassMetadataTests: 3 passed.
- PassSecretSecurityTests: 3 passed (including Codable / CustomStringConvertible negative metatype checks).
- PassErrorTests: 2 passed.

Xcode 26.4.1 (17E202), macOS SDK 26.4, deployment target 14.0,
strict concurrency = complete.
