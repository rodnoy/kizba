LivePassManager FSEvents integration tests

Summary:
- Focused tests (LivePassManagerFSEventsTests): 6 passed, 0 failed
- SourceGrepTests only: 19 passed
- Full suite: 714 executed, 9 skipped, 0 failures

Command outputs saved in CI logs; local xcodebuild run performed.

Commands executed:
- xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS'  # full suite
- KIZBA_FSEVENTS_TEST=1 xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' -only-testing:KizbaTests/FSEventsStoreWatcherTests/testFSEventsEmitsOnRealFSChange  # opt-in real-FS (skipped)
- xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' -only-testing:KizbaTests/SourceGrepTests  # SourceGrepTests only

Results (condensed):
- Full suite: **PASSED** — 714 tests executed, 9 skipped, 0 failures
- FSEvents real-FS opt-in test: **SKIPPED** (opt-in / environment gated)
- SourceGrepTests: **PASSED** — 19 tests, 0 failures
