# Handoff — Execute Step 2.1: Contrast tests — boilerplate

## Task
**Step 2.1 — Boilerplate + test constants**

## Assigned to
smart-worker

## Scope (files to change)
- `KizbaTests/KizbaNightContrastTests.swift` (new)
- `.ai/plan.md` (update)
- `.ai/handoff.md` (update)

## What to do
1. Create `KizbaTests/KizbaNightContrastTests.swift` with a test class `KizbaNightContrastTests: XCTestCase` that:
   - Imports `SwiftUI`, `XCTest`, and `@testable import Kizba`.
   - Declares a private static `futureDarkSurface` constant (Color hex literal) to be used by later contrast tests (e.g., `Color(hex: 0x111018)`).
   - Includes a minimal smoke test that references the new tokens added in Step 1 (`surfaceCard`, `surfaceCardHover`, `accentSecondary`, `accentStrong`) to ensure compilation.
2. Commit changes. See commit rules below.

## Verification
Run:
```bash
xcodebuild test -scheme "Kizba" -destination 'platform=macOS'
```
Fallback if xcodebuild is unavailable:
```bash
swift test
```

Expected result: test runner executes and the new smoke test passes; no regressions in existing tests.

## Acceptance criteria
- New test file exists and compiles.
- Test runner executes the smoke test and it passes.
- `.ai/plan.md` and `.ai/handoff.md` are updated and committed.

## Constraints
- Keep changes minimal and confined to test scaffolding.
- Do not modify production DesignSystem code in this subtask.

## Completion
- completed-by: smart-worker
- timestamp: 2026-05-23T22:01:00Z
- what-was-done: Created `KizbaTests/KizbaNightContrastTests.swift` with `KizbaNightContrastTests: XCTestCase`, added `futureDarkSurface` constant (`Color(hex: 0x111018)`), and added a minimal smoke test referencing `surfaceCard`, `surfaceCardHover`, `accentSecondary`, and `accentStrong` across all theme variants.
- verification-summary: `xcodebuild test -scheme "Kizba" -destination 'platform=macOS'` succeeded; full suite passed (`1289` tests executed, `17` skipped, `0` failures), `** TEST SUCCEEDED **`.

## Completion
- completed-by: smart-worker
- timestamp: 2026-05-23T22:17:49Z
- what-was-done: Appended Step 2.2 contrast tests in `KizbaTests/KizbaNightContrastTests.swift` for `onSurface` against `surface` and `surfaceCard` at AAA (>= 7.0), and for `onSurfaceMuted` against `surface` and `surfaceCard` at AA (>= 4.5), iterating over `Self.allVariants`.
- verification-summary: `xcodebuild test -scheme "Kizba" -destination 'platform=macOS'` was executed twice but interrupted by environment timeout; targeted verification `xcodebuild test -scheme "Kizba" -destination 'platform=macOS' -only-testing:KizbaTests/KizbaNightContrastTests` succeeded (`3` tests, `0` failures), `** TEST SUCCEEDED **`. `swift test` fallback is not available because this repo has no `Package.swift`.

## Completion
- completed-by: smart-worker
- timestamp: 2026-05-24T05:53:48Z
- what-was-done: Implemented Step 2.3 by appending `testKizbaNight_onAccent_against_accent_and_accentSecondary_meet_AA` to `KizbaTests/KizbaNightContrastTests.swift`, asserting `onAccent/accent >= 4.5` and `onAccent/accentSecondary >= 4.5` across `Self.allVariants`.
- verification-summary: `xcodebuild test -scheme "Kizba" -destination 'platform=macOS'` succeeded; full suite passed (`1292` tests executed, `17` skipped, `0` failures), `** TEST SUCCEEDED **`.

## Completion
- completed-by: smart-worker
- timestamp: 2026-05-24T11:40:34Z
- what-was-done: Updated `darkHighContrast` in `Kizba/Presentation/DesignSystem/Theme/Theme+HighContrast.swift` by changing `accentMuted` opacity from `0.34` to `0.28` to satisfy Step 2.4 contrast requirements; no other tokens or semantics were modified.
- verification-summary: Targeted run `xcodebuild test -scheme "Kizba" -destination 'platform=macOS' -only-testing:KizbaTests/KizbaNightContrastTests` passed (`5` tests, `0` failures). Full run `xcodebuild test -scheme "Kizba" -destination 'platform=macOS'` passed (`1293` tests executed, `17` skipped, `0` failures), `** TEST SUCCEEDED **`.

## Completion
- completed-by: smart-worker
- timestamp: 2026-05-24T11:47:17Z
- what-was-done: Implemented Step 2.5 by appending `testKizbaNight_passwordReveal_secretMask_meets_AAA` to `KizbaTests/KizbaNightContrastTests.swift`, asserting `onSurface` over `secretMask` composited on `surface` is >= `7.0` (AAA) across `Self.allVariants`.
- verification-summary: Targeted run `xcodebuild test -scheme "Kizba" -destination 'platform=macOS' -only-testing:KizbaTests/KizbaNightContrastTests` passed (`6` tests, `0` failures). Full run `xcodebuild test -scheme "Kizba" -destination 'platform=macOS'` passed (`1294` tests executed, `17` skipped, `0` failures), `** TEST SUCCEEDED **`.

## Completion
- completed-by: smart-worker
- timestamp: 2026-05-24T15:07:12Z
- what-was-done: Implemented Step 2.6 by appending `testKizbaNight_highContrast_doesNotRegressAnyBodyContrast` to `KizbaTests/KizbaNightContrastTests.swift`, asserting non-regression (`hc >= standard - 1e-9`) for `onSurface/surface`, `onSurfaceMuted/surface`, `onAccent/accent`, and `passwordReveal` (`onSurface` over `secretMask` composited on `surface`) across light and dark standard/HC pairs.
- verification-summary: Targeted run `xcodebuild test -scheme "Kizba" -destination 'platform=macOS' -only-testing:KizbaTests/KizbaNightContrastTests` passed (`7` tests, `0` failures). Full run `xcodebuild test -scheme "Kizba" -destination 'platform=macOS'` passed (`1295` tests executed, `17` skipped, `0` failures), `** TEST SUCCEEDED **`.
