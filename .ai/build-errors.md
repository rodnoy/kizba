# Build errors — Step 3.1

## Command

```bash
xcodebuild test -scheme "Kizba" -destination 'platform=macOS' -only-testing:KizbaTests/KizbaNightContrastTests
```

## Failing output (portion)

```text
Test Suite 'KizbaNightContrastTests' started at 2026-05-24 20:46:08.157.
Test Case '-[KizbaTests.KizbaNightContrastTests testKizbaNight_highContrast_doesNotRegressAnyBodyContrast]' started.
/Users/kirillsimagin/dev/my/worldproject/kizba/KizbaTests/KizbaNightContrastTests.swift:122: error: -[KizbaTests.KizbaNightContrastTests testKizbaNight_highContrast_doesNotRegressAnyBodyContrast] : XCTAssertGreaterThanOrEqual failed: ("16.329003504397775") is less than ("16.68223524617962") - HC darkHighContrast regressed onSurface/surface: standard=16.68223524717962, hc=16.329003504397775
Test Case '-[KizbaTests.KizbaNightContrastTests testKizbaNight_highContrast_doesNotRegressAnyBodyContrast]' failed (4.854 seconds).

Test Suite 'KizbaNightContrastTests' failed at 2026-05-24 20:46:13.029.
	Executed 7 tests, with 1 failure (0 unexpected) in 4.865 (4.872) seconds
Test Suite 'KizbaTests.xctest' failed at 2026-05-24 20:46:13.030.
	Executed 7 tests, with 1 failure (0 unexpected) in 4.865 (4.873) seconds
Test Suite 'Selected tests' failed at 2026-05-24 20:46:13.030.
	Executed 7 tests, with 1 failure (0 unexpected) in 4.865 (4.874) seconds

Failing tests:
	KizbaNightContrastTests.testKizbaNight_highContrast_doesNotRegressAnyBodyContrast()

** TEST FAILED **
```
