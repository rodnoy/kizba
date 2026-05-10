SecretRevealField accessibility change (D.1) verification

Summary:
- SecretRevealFieldAccessibilityTests: PASSED — 1 test, 0 failures
- SecretRevealFieldTests: PASSED — 13 tests, 0 failures
- SourceGrepTests (focused): PASSED — 19 tests, 0 failures
- Full test suite: PASSED — 715 tests executed, 9 skipped, 0 failures

Commands executed locally:
- xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' -only-testing:KizbaTests/SecretRevealFieldAccessibilityTests
- xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' -only-testing:KizbaTests/SourceGrepTests
- xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS'
- rg -n '\\bas!\\b' Kizba || true
- rg -n 'Logger.*stdin|print\\(.*stdin' Kizba || true

All checks passed locally. 

D.2 — KeyValueEditor accessibility

- Focused KeyValueEditorAccessibilityTests: NOT RUN in this environment (xcodebuild unavailable here)
