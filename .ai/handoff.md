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
