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

## 2026-05-06 — Step 1.3 (Domain test refinement)

```
xcodebuild -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' test
=> ** TEST SUCCEEDED **
   Executed 49 tests, with 0 failures (0 unexpected) in 0.576 (0.624) seconds
```

New refinement test file (`KizbaTests/DomainModelsRefinementTests.swift`)
adds 21 deterministic edge-case tests on top of the 28 from steps 1.1
and 1.2:

- PassEntryRefinementTests: 6 passed (empty path, trailing slash,
  Unicode, hashable in `Set`, `id == path`, JSON shape pinned to
  single `path` key).
- PassMetadataRefinementTests: 4 passed (case-sensitive
  `firstValue`, duplicate-key + order Codable round-trip, empty notes
  vs nil distinction round-trip, `Field` hashability).
- PassSecretRefinementTests: 4 passed (verbatim whitespace/newline
  preservation, value-equality semantics, 4096-codepoint ω stress
  round-trip via Equatable, `Sendable` metatype check). NOT-Codable
  / NOT-CustomStringConvertible already pinned in 1.1 — not
  duplicated here.
- PassErrorRefinementTests: 4 passed (Hashable into `Set`, stderr
  excerpt is part of identity for both `decryptionFailed` and
  `shellFailure`, parameter-less cases distinct, `storeNotFound`
  carries path).
- DomainConcurrencyTests: 3 passed against an actor-backed
  in-memory `PassManaging` double — concurrent `add`s not lost
  (64 fan-out), concurrent `show` returns exact secret per entry
  (32 fan-out), concurrent `show` for unknown entries surfaces
  `decryptionFailed` (16 fan-out). Deterministic: fixed iteration
  counts, no timing assertions.

No production-code changes were required for step 1.3.

