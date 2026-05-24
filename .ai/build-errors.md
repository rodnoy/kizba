## Build/Test Failure Log

- Timestamp: 2026-05-24T08:20:24Z
- Command: `xcodebuild test -scheme "Kizba" -destination 'platform=macOS' -only-testing:KizbaTests/KizbaNightContrastTests`
- Result: `** TEST FAILED **`

### Failing portion

```text
Test Suite 'KizbaNightContrastTests' started at 2026-05-24 10:20:00.967.
Test Case '-[KizbaTests.KizbaNightContrastTests testKizbaNight_onSurface_against_accentMuted_composited_meet_AA]' started.
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/KizbaNightContrastTests.swift:86: error: -[KizbaTests.KizbaNightContrastTests testKizbaNight_onSurface_against_accentMuted_composited_meet_AA] : XCTAssertGreaterThanOrEqual failed: ("4.08353966303668") is less than ("4.5") - onSurface/accentMuted(over surface) for darkHighContrast below AA: 4.08353966303668
Test Case '-[KizbaTests.KizbaNightContrastTests testKizbaNight_onSurface_against_accentMuted_composited_meet_AA]' failed (5.219 seconds).
Test Suite 'KizbaNightContrastTests' failed at 2026-05-24 10:20:06.190.
	 Executed 5 tests, with 1 failure (0 unexpected) in 5.222 (5.223) seconds
Test Suite 'KizbaTests.xctest' failed at 2026-05-24 10:20:06.190.
	 Executed 5 tests, with 1 failure (0 unexpected) in 5.222 (5.224) seconds
Test Suite 'Selected tests' failed at 2026-05-24 10:20:06.190.
	 Executed 5 tests, with 1 failure (0 unexpected) in 5.222 (5.224) seconds

Failing tests:
	KizbaNightContrastTests.testKizbaNight_onSurface_against_accentMuted_composited_meet_AA()

** TEST FAILED **
```
