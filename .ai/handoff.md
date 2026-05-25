# Handoff — Execute Step 4.1 + 4.2: Switch KizbaCard to surfaceCard token

## Task
**Step 4.1 + 4.2 — Switch KizbaCard background from `surfaceElevated` to `surfaceCard` and update test**

## Assigned to
smart-worker

## Scope (files to change)
- `Kizba/Presentation/DesignSystem/Components/KizbaCard.swift`
- `KizbaTests/KizbaCardTests.swift`

## What to do
1. In `KizbaCard.swift`, method `backgroundColor(in:)`, change:
   ```swift
   theme.colors.surfaceElevated
   ```
   to:
   ```swift
   theme.colors.surfaceCard
   ```

2. In `KizbaCardTests.swift`, rename `testBackgroundColor_isSurfaceElevatedInEveryTheme` to `testBackgroundColor_isSurfaceCardInEveryTheme` and change the assertion:
   ```swift
   theme.colors.surfaceElevated
   ```
   to:
   ```swift
   theme.colors.surfaceCard
   ```

## Verification
```bash
xcodebuild test -scheme "Kizba" -destination 'platform=macOS' -only-testing:KizbaTests/KizbaCardTests
```

Expected: All 5 tests pass (0 failures).

## Acceptance criteria
- `KizbaCard.backgroundColor(in:)` returns `theme.colors.surfaceCard`.
- Test asserts against `surfaceCard` (not `surfaceElevated`).
- All 5 `KizbaCardTests` pass.
- No visual change (tokens are aliased to same value).
- No other files modified.

## Constraints
- These two changes must be committed together (test fails without the code change and vice versa).
- Do not add card styles yet (that is Step 4.3).

## Completion
- completed-by: smart-worker
- timestamp: 2026-05-24T21:08:21Z
- what-was-done:
  - Verified `ColorTokens.swift` already contains `surfaceCard` and `surfaceCardHover` with initializer wiring.
  - Verified token alias wiring in `Theme+Dark.swift`, `Theme+Light.swift`, and `Theme+HighContrast.swift` is already explicit and matches Day-1 alias contract:
    - `surfaceCard` uses the same RHS expression as `surfaceElevated`.
    - `surfaceCardHover` uses the same RHS expression as `surfaceHover`.
  - No token value changes were required.
- verification-summary:
  - `xcodebuild test -scheme "Kizba" -destination 'platform=macOS' -only-testing:KizbaTests/KizbaNightContrastTests` — PASS (7 tests, 0 failures).
  - `xcodebuild test -scheme "Kizba" -destination 'platform=macOS'` — PASS (1295 tests, 17 skipped, 0 failures).

## Completion
- completed-by: smart-worker
- timestamp: 2026-05-24T21:13:10Z
- what-was-done:
  - Added `surfaceCardFlat` and `surfaceCardFlatHover` to `ColorTokens` surfaces and wired both through the public initializer directly after `surfaceCardHover`.
  - Added Day-1 alias arguments for `surfaceCardFlat` and `surfaceCardFlatHover` in `Theme+Dark.swift`, `Theme+Light.swift`, and both high-contrast variants in `Theme+HighContrast.swift`.
  - Kept aliases identical to existing `surfaceCard` / `surfaceCardHover` RHS expressions in each theme variant (no new hex values, no visual changes).
- verification-summary:
  - `xcodebuild test -scheme "Kizba" -destination 'platform=macOS' -only-testing:KizbaTests/KizbaNightContrastTests` — PASS (7 tests, 0 failures).
  - `xcodebuild test -scheme "Kizba" -destination 'platform=macOS'` — PASS (1295 tests, 17 skipped, 0 failures).

## Completion
- completed-by: smart-worker
- timestamp: 2026-05-24T21:17:38Z
- what-was-done:
  - Added additive `surfaceCardInteractive` and `surfaceCardInteractiveHover` tokens to `ColorTokens` in the Surfaces group immediately after `surfaceCardFlatHover`.
  - Extended `ColorTokens` public initializer with `surfaceCardInteractive` and `surfaceCardInteractiveHover` parameters in matching order and wired assignments in the initializer body.
  - Added Day-1 alias arguments in `Theme+Dark.swift`, `Theme+Light.swift`, and both `lightHighContrast` / `darkHighContrast` variants in `Theme+HighContrast.swift`.
  - Kept alias RHS expressions identical to existing per-file `surfaceElevated` and `surfaceHover` expressions (no new hex values, no visual changes).
- verification-summary:
  - `xcodebuild test -scheme "Kizba" -destination 'platform=macOS' -only-testing:KizbaTests/KizbaNightContrastTests` — PASS (7 tests, 0 failures).
  - `xcodebuild test -scheme "Kizba" -destination 'platform=macOS'` — PASS (1295 tests, 17 skipped, 0 failures).

## Completion
- completed-by: smart-worker
- timestamp: 2026-05-25T06:45:59Z
- what-was-done:
  - Added `KizbaTests/CardVariantTests.swift` with alias-contract assertions for card tokens across all theme variants.
  - Added contrast-contract assertions for `onSurface` (AAA >= 7.0) and `onSurfaceMuted` (AA >= 4.5) against `surfaceCard`, `surfaceCardFlat`, and `surfaceCardInteractive` across all theme variants.
  - Kept implementation scope test-only; no production code changes.
- verification-summary:
  - `xcodebuild test -scheme "Kizba" -destination 'platform=macOS' -only-testing:KizbaTests/CardVariantTests` — PASS (3 tests, 0 failures).
  - `xcodebuild test -scheme "Kizba" -destination 'platform=macOS'` — PASS (1298 tests, 17 skipped, 0 failures).
