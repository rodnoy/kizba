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

## 2026-05-06 — Step 1.2 (Domain protocols)

```
xcodebuild -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' build
=> ** BUILD SUCCEEDED **

xcodebuild -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' test
=> ** TEST SUCCEEDED **
   Executed 28 tests, with 0 failures (0 unexpected) in 3.944 (3.992) seconds
```

New test suites (14 new tests, all passing):

- PassManagingTests: 4 passed (list, show round-trip, decryption-failure
  surfacing, storeLocation passthrough).
- ShellCommandRunningTests: 1 passed (argument/environment/timeout
  forwarding via recording double).
- ClipboardServicingTests: 2 passed (verbatim copy, ordered repeats).
- BinaryLocatingTests: 4 passed (locate hit, miss, reDetect cache
  invalidation, BinaryName raw values).
- SettingsStoringTests: 3 passed (round-trip, nil-removes, key isolation).

No production-code concrete implementations introduced — protocol
definitions only, per `.ai/decisions.md`.
