# D.2 — KeyValueEditor Accessibility Improvements

## Goal

Add per-row accessibility grouping to `KeyValueEditor` so VoiceOver treats each key/value/remove-button row as a single coherent element. Add a testable pure helper for the row label string and a deterministic unit test.

## Constraints

- Zero third-party dependencies.
- No refactoring of unrelated code.
- Inline styling banned in Presentation outside DesignSystem (this change IS in DesignSystem — OK).
- All code/comments/commits in English.
- `SWIFT_STRICT_CONCURRENCY = complete`.
- Follow D.1 pattern: extract a `static` pure helper for testability; test the helper, not the view.

## Tasks

### Task 1 — Add accessibility modifiers to each row + extract static helper

- **Objective:** VoiceOver groups each metadata row (key field, value field, remove button) as one element and announces "Field row 1", "Field row 2", etc.
- **Files to modify:** `Kizba/Presentation/DesignSystem/Components/KeyValueEditor.swift`
- **Changes:**
  1. Change `ForEach(pairs)` to `ForEach(Array(pairs.enumerated()), id: \.element.id)` (or equivalent) to get the index.
  2. On the `HStack` returned by `row(for:)`, add:
     - `.accessibilityElement(children: .contain)`
     - `.accessibilityLabel(KeyValueEditor.rowAccessibilityLabel(index: index))`
  3. Update `row(for:)` signature to accept `index: Int` alongside `pair: Pair`.
  4. Add a static pure helper in a `// MARK: - Pure helpers` section:
     ```swift
     static func rowAccessibilityLabel(index: Int) -> String {
         "Field row \(index + 1)"
     }
     ```
- **Implementation notes:**
  - The `index` parameter to `rowAccessibilityLabel` is 0-based; the helper adds 1 for the human-readable label. This matches the plan's `\(index + 1)` spec.
  - `ForEach(Array(pairs.enumerated()), id: \.element.id)` is the idiomatic SwiftUI pattern for index+element iteration with stable identity. Alternative: `ForEach(pairs.indices, id: \.self)` with `pairs[index]` — but `.element.id` is safer for identity stability during reorder/delete.
  - No behavior change to existing functionality (add/remove/edit pairs).
- **Verification:** Project compiles. Existing tests pass.
- **Risks:** None. Additive-only modifiers. `enumerated()` + `Array` is a trivial O(n) copy; metadata lists are small (< 50 rows).

### Task 2 — Add unit test for `rowAccessibilityLabel`

- **Objective:** Deterministic test proving the label string is correct for representative indices.
- **Files to add:** `KizbaTests/KeyValueEditorAccessibilityTests.swift`
- **Test method:** `testRowAccessibilityLabel_returnsOneIndexedString`
- **Test body:**
  ```swift
  import XCTest
  @testable import Kizba

  final class KeyValueEditorAccessibilityTests: XCTestCase {
      func testRowAccessibilityLabel_returnsOneIndexedString() {
          XCTAssertEqual(KeyValueEditor.rowAccessibilityLabel(index: 0), "Field row 1")
          XCTAssertEqual(KeyValueEditor.rowAccessibilityLabel(index: 1), "Field row 2")
          XCTAssertEqual(KeyValueEditor.rowAccessibilityLabel(index: 9), "Field row 10")
      }
  }
  ```
- **Verification:** `xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' -only-testing:KizbaTests/KeyValueEditorAccessibilityTests` — 1 test, 0 failures.
- **Risks:** None. Pure function, no concurrency, no UI dependencies.

### Task 3 — Verify no regressions

- **Objective:** Full suite green.
- **Files to modify:** None.
- **Verification:**
  - Focused: `xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' -only-testing:KizbaTests/KeyValueEditorAccessibilityTests`
  - SourceGrepTests: `xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' -only-testing:KizbaTests/SourceGrepTests`
  - Full suite: `xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS'` — all pass, 0 failures
- **Success criteria:** Test count ≥ 716 (715 baseline + 1 new), 0 failures.
- **Risks:** None.

## Concurrency Notes

No concurrency concerns. `KeyValueEditor` is a plain SwiftUI `View` struct. The new static helper is a pure function. No actor boundaries crossed.

## Commit message

```
feat(a11y): KeyValueEditor per-row accessibility grouping (D.2)

Each metadata row is now an accessibility container with label
"Field row N" so VoiceOver groups key/value/remove coherently.
Extracted rowAccessibilityLabel(index:) static helper; one new
test in KeyValueEditorAccessibilityTests.
```

## Suggested current step

Tasks 1 and 2 can be done together (single edit pass). Task 3 is verification only.
