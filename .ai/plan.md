# D.1 — SecretRevealField Accessibility Value

## Goal

Add `.accessibilityValue(isRevealed ? "Revealed" : "Hidden")` to the reveal/hide toggle button in `SecretRevealField` so VoiceOver announces the current state. Add one test to `SecretRevealFieldTests` verifying the pure helper that drives the value.

## Constraints

- Zero third-party dependencies.
- No refactoring of unrelated code.
- Inline styling banned in Presentation outside DesignSystem (this change IS in DesignSystem — OK).
- All code/comments/commits in English.
- `SWIFT_STRICT_CONCURRENCY = complete`.

## Tasks

### Task 1 — Add `.accessibilityValue` to the toggle button

- **Objective:** VoiceOver announces "Revealed" or "Hidden" when the toggle button is focused.
- **Files to modify:** `Kizba/Presentation/DesignSystem/Components/SecretRevealField.swift`
- **Changes:**
  1. On the reveal/hide `Button` (lines 51–57), add `.accessibilityValue(isRevealed ? "Revealed" : "Hidden")` after the existing `.accessibilityLabel(...)` modifier (line 57).
- **Implementation notes:**
  - The button already has `.accessibilityLabel(isRevealed ? "Hide secret" : "Reveal secret")` — the label describes the ACTION; the new `.accessibilityValue` describes the current STATE. Both are needed for proper VoiceOver UX.
  - No new static helper needed — the ternary is trivial and directly in the view body.
- **Verification:** Project compiles. Existing `SecretRevealFieldTests` pass unchanged.
- **Risks:** None. Additive-only modifier.

### Task 2 — Add `accessibilityValueText` static helper + test

- **Objective:** Extract the accessibility value string into a testable static helper (same pattern as `displayText` and `maskedLength`) and add one test.
- **Files to modify:**
  - `Kizba/Presentation/DesignSystem/Components/SecretRevealField.swift`
  - `KizbaTests/SecretRevealFieldTests.swift`
- **Changes in `SecretRevealField.swift`:**
  1. Add a static helper in the `// MARK: - Pure helpers` section:
     ```swift
     static func accessibilityValueText(isRevealed: Bool) -> String {
         isRevealed ? "Revealed" : "Hidden"
     }
     ```
  2. Update the `.accessibilityValue(...)` modifier from Task 1 to call `SecretRevealField.accessibilityValueText(isRevealed: isRevealed)`.
- **Changes in `SecretRevealFieldTests.swift`:**
  1. Add one test method:
     ```swift
     func testSecretRevealField_accessibilityValueText_reflectsRevealState() {
         XCTAssertEqual(SecretRevealField.accessibilityValueText(isRevealed: true), "Revealed")
         XCTAssertEqual(SecretRevealField.accessibilityValueText(isRevealed: false), "Hidden")
     }
     ```
- **Verification:** `xcodebuild test -only-testing:KizbaTests/SecretRevealFieldTests` — all pass (existing + 1 new).
- **Risks:** None. Pure function, no concurrency.

### Task 3 — Verify no regressions

- **Objective:** Full suite green.
- **Files to modify:** None.
- **Verification:**
  - Focused: `xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' -only-testing:KizbaTests/SecretRevealFieldTests`
  - SourceGrepTests: `xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' -only-testing:KizbaTests/SourceGrepTests`
  - Full suite: `xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS'` — all pass, 0 failures
- **Success criteria:** Test count ≥ 715 (714 baseline + 1 new), 0 failures.
- **Risks:** None.

## Concurrency Notes

No concurrency concerns. `SecretRevealField` is a plain SwiftUI `View` struct. The new static helper is a pure function. The `@Binding var isRevealed` is already MainActor-isolated by SwiftUI's view lifecycle.

## Commit message

```
feat(mvp3): add accessibilityValue to SecretRevealField toggle (D.1)

Toggle button now announces "Revealed" / "Hidden" via
.accessibilityValue so VoiceOver users hear the current state.
Extracted accessibilityValueText(isRevealed:) static helper;
one new test in SecretRevealFieldTests.
```

## Suggested current step

Tasks 1 and 2 can be done together (single edit pass). Task 3 is verification only.
