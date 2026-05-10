Failed commands and tail output (up to 200 lines):

1) Focused tests (AppRouterTests)
- Command:
  xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' -only-testing:KizbaTests/AppRouterTests
- Result: PASSED — executed 3 tests, 0 failures.

2) Full test suite
- Command:
  xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS'
- Result: FAILED — executed 702 tests, 8 skipped, 20 failures.

Tail of failing test run (last ~200 lines):

... Test Suite 'UserDefaultsSettingsStoreTests' passed at 2026-05-10 11:59:24.782.
    Executed 5 tests, with 0 failures (0 unexpected) in 0.026 (0.029) seconds
Test Suite 'KizbaTests.xctest' failed at 2026-05-10 11:59:24.782.
    Executed 702 tests, with 8 tests skipped and 20 failures (0 unexpected) in 28.791 (30.749) seconds
Test Suite 'All tests' failed at 2026-05-10 11:59:24.798.
    Executed 702 tests, with 8 tests skipped and 20 failures (0 unexpected) in 28.791 (30.765) seconds

Exit: **TEST FAILED**

Notes:
- The focused AppRouter tests passed.
- The full suite contains 20 failing tests; full logs are available in the xcodebuild xcresult at: /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-efejvmfzdmoqdoewsmanttogshar/Logs/Test/Test-Kizba-2026.05.10_11-58-50-+0200.xcresult
