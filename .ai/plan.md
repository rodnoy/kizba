# E.1 — BiometricAuthenticating Domain Protocol

## Goal

Add a pure domain protocol `BiometricAuthenticating` with associated enums (`BiometricAvailability`, `BiometricUnavailableReason`, `BiometricResult`, `BiometricFailureReason`) to `Kizba/Domain/Protocols/`. No `LocalAuthentication` import. All types `Sendable` and `Equatable`.

## Constraints

- Zero third-party dependencies.
- No `import LocalAuthentication` in the protocol file.
- No `LAError` or any LA type exposure.
- All enums and protocol: `Sendable, Equatable` (protocol inherits `Sendable`; enums conform to both).
- `SWIFT_STRICT_CONCURRENCY = complete`.
- All code/comments in English.
- Protocol lives in `Domain/Protocols/` per architecture decision.

## Tasks

### Task 1 — Create BiometricAuthenticating.swift

- **Objective:** Define the protocol and all 4 supporting enums in a single file.
- **File to add:** `Kizba/Domain/Protocols/BiometricAuthenticating.swift`
- **Public API:**
  ```swift
  // BiometricAuthenticating.swift
  // Kizba

  import Foundation

  // MARK: - Enums

  enum BiometricUnavailableReason: Sendable, Equatable {
      case notEnrolled
      case hardwareUnavailable
      case passcodeNotSet
      case userDisabled
      case unknown
  }

  enum BiometricAvailability: Sendable, Equatable {
      case available
      case unavailable(BiometricUnavailableReason)
  }

  enum BiometricFailureReason: Sendable, Equatable {
      case userFailed
      case systemCancel
      case appCancel
      case invalidContext
      case unknown
  }

  enum BiometricResult: Sendable, Equatable {
      case success
      case cancelled
      case failed(BiometricFailureReason)
  }

  // MARK: - Protocol

  protocol BiometricAuthenticating: Sendable {
      func isAvailable() -> BiometricAvailability
      func authenticate(reason: String) async -> BiometricResult
  }
  ```
- **Concurrency notes:**
  - Protocol inherits `Sendable` — conforming types must be actors or `Sendable` structs/classes.
  - `authenticate(reason:)` is `async` (not throwing) — errors mapped to `BiometricResult.failed(...)` by implementations.
  - `isAvailable()` is synchronous — implementations cache or query cheaply.
- **Verification:** Project compiles (`xcodebuild build`). No `LocalAuthentication` import in file.
- **Risks:** None. Additive file, no existing code touched.

### Task 2 — Add BiometricAuthenticatingTests.swift

- **Objective:** Compile-time and deterministic runtime tests proving enums are Equatable, protocol is conformable by a fake.
- **File to add:** `KizbaTests/BiometricAuthenticatingTests.swift`
- **Test class:** `BiometricAuthenticatingTests`
- **Test methods:**
  1. `testEnumsAreEquatable` — assert equality/inequality for each enum (e.g., `.available == .available`, `.unavailable(.notEnrolled) != .unavailable(.hardwareUnavailable)`, `.success != .cancelled`, `.failed(.userFailed) == .failed(.userFailed)`).
  2. `testFakeCanConformToProtocol` — define a private `FakeBiometricAuth: BiometricAuthenticating` struct inside the test, call both methods, assert expected return values.
  3. `testAllUnavailableReasonsDistinct` — put all 5 `BiometricUnavailableReason` cases in an array, assert `Set(array).count == 5` (requires Hashable — if not Hashable, use pairwise `!=` assertions instead; enums with no associated values auto-synthesize Hashable when Equatable, so Set works for the leaf enum).
- **Verification:** `xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' -only-testing:KizbaTests/BiometricAuthenticatingTests` — 3 tests, 0 failures.
- **Risks:** None. Pure value types, no concurrency in tests.

### Task 3 — Add SourceGrepTests rule for no LocalAuthentication import

- **Objective:** Prevent `import LocalAuthentication` from appearing in `Kizba/Domain/`.
- **File to modify:** `KizbaTests/SourceGrepTests.swift`
- **New test method:** `testNoLocalAuthenticationImportInDomain`
- **Logic:** Scan all `.swift` files under `Kizba/Domain/` for regex `import\s+LocalAuthentication`; assert zero matches.
- **Verification:** `xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' -only-testing:KizbaTests/SourceGrepTests/testNoLocalAuthenticationImportInDomain` — 1 test, 0 failures.
- **Risks:** None. Additive grep rule.

### Task 4 — Verify no regressions

- **Objective:** Full suite green.
- **Verification:**
  - Focused: `xcodebuild test ... -only-testing:KizbaTests/BiometricAuthenticatingTests`
  - SourceGrepTests: `xcodebuild test ... -only-testing:KizbaTests/SourceGrepTests`
  - Full suite: `xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS'` — 0 failures
- **Success criteria:** All existing tests pass + 4 new tests (3 biometric + 1 grep rule).
- **Risks:** None.

## Commit message

```
feat(mvp3): add BiometricAuthenticating domain protocol (E.1)

Introduce BiometricAuthenticating protocol and supporting enums
(BiometricAvailability, BiometricResult, BiometricUnavailableReason,
BiometricFailureReason) in Domain/Protocols/. All Sendable + Equatable.
No LocalAuthentication import — LA coupling stays in Infrastructure.
Three new tests + one SourceGrepTests rule.
```

## Suggested current step

Tasks 1–3 in a single pass. Task 4 is verification only.

---

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

---

# E.2 — LocalAuthBiometricAuthenticator

## Goal

Add the production `LocalAuthentication`-backed implementation of `BiometricAuthenticating`. The class lives in `Infrastructure/Auth/` and maps all `LAError` codes to the domain enums declared in E.1. No `LAError` or `LAContext` type leaks into the public API.

## Constraints

- Zero third-party dependencies.
- `import LocalAuthentication` only in the Infrastructure file, never in Domain.
- All `LAError` codes mapped to domain enums; no `LAError` in public API.
- `SWIFT_STRICT_CONCURRENCY = complete`.
- All code/comments in English.
- Protocol file in `Domain/Protocols/` is NOT modified.

## Tasks

### Task 1 — Create LocalAuthBiometricAuthenticator.swift

- **Objective:** Production implementation conforming to `BiometricAuthenticating`.
- **File to add:** `Kizba/Infrastructure/Auth/LocalAuthBiometricAuthenticator.swift`
- **Class declaration:**
  ```swift
  import Foundation
  import LocalAuthentication

  final class LocalAuthBiometricAuthenticator: BiometricAuthenticating, @unchecked Sendable {
      // No stored state. LAContext created per-call.
  }
  ```
- **`@unchecked Sendable` rationale:** The class has no mutable stored properties. `LAContext` is created fresh per method call (stack-local), never shared. The class is safe to use from any isolation domain.

- **Method: `isAvailable() -> BiometricAvailability`**
  1. Create a fresh `LAContext()`.
  2. Call `context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)`.
  3. If `true`, return `.available`.
  4. If `false`, map the `NSError` via a static helper `mapUnavailableReason(_:)` and return `.unavailable(reason)`.

- **Method: `authenticate(reason: String) async -> BiometricResult`**
  1. Create a fresh `LAContext()`.
  2. Use `withCheckedContinuation` to bridge `evaluatePolicy(_:localizedReason:reply:)`:
     ```swift
     let result = await withCheckedContinuation { continuation in
         context.evaluatePolicy(
             .deviceOwnerAuthenticationWithBiometrics,
             localizedReason: reason
         ) { success, error in
             if success {
                 continuation.resume(returning: BiometricResult.success)
             } else if let error = error as? LAError {
                 continuation.resume(returning: Self.mapAuthError(error))
             } else {
                 continuation.resume(returning: .failed(.unknown))
             }
         }
     }
     return result
     ```
  3. Return the result.

- **Static mapping helpers (internal visibility for testability):**

  1. `static func mapUnavailableReason(_ error: NSError?) -> BiometricUnavailableReason`
     - `nil` → `.unknown`
     - Cast to `LAError`, then switch on `.code`:
       - `.biometryNotEnrolled` → `.notEnrolled`
       - `.biometryNotAvailable` → `.hardwareUnavailable`
       - `.passcodeNotSet` → `.passcodeNotSet`
       - `.biometryLockout` → `.userDisabled`
       - `default` → `.unknown`

  2. `static func mapAuthError(_ error: LAError) -> BiometricResult`
     - Switch on `error.code`:
       - `.userCancel` → `.cancelled`
       - `.authenticationFailed` → `.failed(.userFailed)`
       - `.systemCancel` → `.failed(.systemCancel)`
       - `.appCancel` → `.failed(.appCancel)`
       - `.invalidContext` → `.failed(.invalidContext)`
       - `default` → `.failed(.unknown)`

- **Concurrency notes:**
  - `LAContext` is created on the stack per call. No shared mutable state.
  - `withCheckedContinuation` (not `withCheckedThrowingContinuation`) because the method is non-throwing; errors are mapped to `BiometricResult`.
  - The `reply` closure from `evaluatePolicy` is called on an arbitrary queue by LocalAuthentication; `withCheckedContinuation` handles the hop back.

- **Verification:** Project compiles. `rg 'LAError|LAContext' Kizba/Domain/` returns zero matches.
- **Risks:** None. Additive file, no existing code touched.

### Task 2 — Add LocalAuthBiometricAuthenticatorTests.swift

- **Objective:** Test the two static mapping helpers exhaustively using `NSError` construction. Do NOT test `isAvailable()` or `authenticate()` directly (they require a real Secure Enclave).
- **File to add:** `KizbaTests/LocalAuthBiometricAuthenticatorTests.swift`
- **Test class:** `LocalAuthBiometricAuthenticatorTests`
- **Test methods:**

  1. `testMapUnavailableReason_nil_returnsUnknown`
     - `XCTAssertEqual(LocalAuthBiometricAuthenticator.mapUnavailableReason(nil), .unknown)`

  2. `testMapUnavailableReason_biometryNotEnrolled_returnsNotEnrolled`
     - Construct `NSError(domain: LAError.errorDomain, code: LAError.Code.biometryNotEnrolled.rawValue)`
     - Assert `.notEnrolled`

  3. `testMapUnavailableReason_biometryNotAvailable_returnsHardwareUnavailable`
     - Code: `.biometryNotAvailable.rawValue` → `.hardwareUnavailable`

  4. `testMapUnavailableReason_passcodeNotSet_returnsPasscodeNotSet`
     - Code: `.passcodeNotSet.rawValue` → `.passcodeNotSet`

  5. `testMapUnavailableReason_biometryLockout_returnsUserDisabled`
     - Code: `.biometryLockout.rawValue` → `.userDisabled`

  6. `testMapUnavailableReason_unknownCode_returnsUnknown`
     - Code: `9999` → `.unknown`

  7. `testMapAuthError_userCancel_returnsCancelled`
     - `LAError(.userCancel)` → `.cancelled`

  8. `testMapAuthError_authenticationFailed_returnsFailedUserFailed`
     - `LAError(.authenticationFailed)` → `.failed(.userFailed)`

  9. `testMapAuthError_systemCancel_returnsFailedSystemCancel`
     - `LAError(.systemCancel)` → `.failed(.systemCancel)`

  10. `testMapAuthError_appCancel_returnsFailedAppCancel`
      - `LAError(.appCancel)` → `.failed(.appCancel)`

  11. `testMapAuthError_invalidContext_returnsFailedInvalidContext`
      - `LAError(.invalidContext)` → `.failed(.invalidContext)`

  12. `testMapAuthError_unknownCode_returnsFailedUnknown`
      - `LAError(.notInteractive)` (arbitrary non-mapped code) → `.failed(.unknown)`

- **NSError construction pattern for `mapUnavailableReason` tests:**
  ```swift
  let error = NSError(domain: LAError.errorDomain, code: LAError.Code.biometryNotEnrolled.rawValue)
  XCTAssertEqual(
      LocalAuthBiometricAuthenticator.mapUnavailableReason(error),
      .notEnrolled
  )
  ```

- **LAError construction pattern for `mapAuthError` tests:**
  ```swift
  XCTAssertEqual(
      LocalAuthBiometricAuthenticator.mapAuthError(LAError(.userCancel)),
      .cancelled
  )
  ```

- **Verification:** `xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' -only-testing:KizbaTests/LocalAuthBiometricAuthenticatorTests` — 12 tests, 0 failures.
- **Risks:** None. Pure function tests, no Secure Enclave interaction.

### Task 3 — Verify no regressions

- **Objective:** Full suite green, SourceGrepTests pass (including E.1's `testNoLocalAuthenticationImportInDomain`).
- **Verification:**
  - Focused: `xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' -only-testing:KizbaTests/LocalAuthBiometricAuthenticatorTests`
  - SourceGrepTests: `xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' -only-testing:KizbaTests/SourceGrepTests`
  - Full suite: `xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS'` — 0 failures
- **Success criteria:** All existing tests pass + 12 new tests. SourceGrepTests `testNoLocalAuthenticationImportInDomain` still green (import is in Infrastructure, not Domain).
- **Risks:** None.

## Concurrency & Ownership Notes

- **LAContext per-call:** Every call to `isAvailable()` and `authenticate(reason:)` creates a fresh `LAContext()`. No `LAContext` is stored as a property. This avoids invalidation issues (LAContext becomes invalid after use) and eliminates shared mutable state.
- **`@unchecked Sendable`:** Justified because the class has zero stored properties. If stored properties are ever added, this must be revisited.
- **`withCheckedContinuation`:** Used (not `withCheckedThrowingContinuation`) because the protocol method is non-throwing. The continuation is resumed exactly once in all code paths (success, LAError, unexpected error).
- **No `Task` spawning:** The `evaluatePolicy` callback-based API is bridged directly via continuation. No detached tasks needed.

## Commit message

```
feat(mvp3): add LocalAuthBiometricAuthenticator (E.2)

Production BiometricAuthenticating implementation using
LocalAuthentication framework. LAContext created per-call;
LAError codes mapped to domain enums via static helpers.
12 mapping tests covering all error code branches.
```

## Suggested current step

Tasks 1 and 2 in a single pass. Task 3 is verification only.

---

# D.3 — FormFieldRow Dynamic Type Vertical Layout

## Goal

When the user's Dynamic Type size is `.accessibility1` or larger, `FormFieldRow` switches from a horizontal layout (label | control) to a vertical layout (label above control) so content is not clipped or truncated. Extract a testable pure helper for the layout decision.

## Constraints

- Zero third-party dependencies.
- Inline styling banned in Presentation outside DesignSystem (this change IS in DesignSystem — OK).
- All code/comments/commits in English.
- `SWIFT_STRICT_CONCURRENCY = complete`.
- Follow D.1/D.2 pattern: extract a `static` pure helper; test the helper, not the view.
- Preserve existing behavior for all non-accessibility Dynamic Type sizes.

## Tasks

### Task 1 — Extract static helper + update body layout

- **Objective:** `FormFieldRow` reads `@Environment(\.dynamicTypeSize)` and uses a vertical `VStack(alignment: .leading)` layout (label on top, control below) when `dynamicTypeSize >= .accessibility1`. For smaller sizes, the existing `HStack` layout is preserved unchanged.
- **Files to modify:** `Kizba/Presentation/DesignSystem/Components/FormFieldRow.swift`
- **Changes:**
  1. Add `@Environment(\.dynamicTypeSize) private var dynamicTypeSize` to `FormFieldRow`.
  2. Add a `// MARK: - Pure helpers` section with:
     ```swift
     static func shouldUseVerticalLayout(_ size: DynamicTypeSize) -> Bool {
         size >= .accessibility1
     }
     ```
  3. In `body`, branch on `Self.shouldUseVerticalLayout(dynamicTypeSize)`:
     - **Vertical path** (`true`): Replace the `HStack` with a `VStack(alignment: .leading, spacing: theme.spacing.xs)` containing:
       - `Text(label)` — same font/color, but NO fixed width, alignment `.leading`, `accessibilityHidden(true)`.
       - `control()` — `frame(maxWidth: .infinity, alignment: .leading)`, `.accessibilityLabel(label)`.
     - **Horizontal path** (`false`): Existing `HStack` code unchanged.
  4. In `helperText(_:color:)`, when vertical layout is active, drop the leading `Spacer` (no label column to align with) — helper text starts at leading edge.
- **Implementation notes:**
  - `DynamicTypeSize` conforms to `Comparable` in SwiftUI (macOS 14+), so `>=` works directly.
  - The outer `VStack` wrapping error/help text stays as-is in both paths.
  - The `formFieldRowLabelWidth` private constant is still used in the horizontal path; no change needed.
- **Verification:** Project compiles. Existing tests pass. Visual check: in Xcode preview, set Dynamic Type to `.accessibility1` and confirm vertical layout.
- **Risks:** Low. Additive branching; horizontal path is byte-for-byte identical to current code.

### Task 2 — Add unit test for `shouldUseVerticalLayout`

- **Objective:** Deterministic test proving the helper returns `true` for accessibility sizes and `false` for standard sizes.
- **Files to add:** `KizbaTests/FormFieldRowAccessibilityTests.swift`
- **Test class:** `FormFieldRowAccessibilityTests`
- **Test methods:**
  1. `testShouldUseVerticalLayout_standardSizes_returnsFalse` — assert `false` for `.xSmall`, `.small`, `.medium`, `.large`, `.xLarge`, `.xxLarge`, `.xxxLarge`.
  2. `testShouldUseVerticalLayout_accessibilitySizes_returnsTrue` — assert `true` for `.accessibility1`, `.accessibility2`, `.accessibility3`, `.accessibility4`, `.accessibility5`.
- **Test body sketch:**
  ```swift
  import XCTest
  import SwiftUI
  @testable import Kizba

  final class FormFieldRowAccessibilityTests: XCTestCase {
      func testShouldUseVerticalLayout_standardSizes_returnsFalse() {
          let standard: [DynamicTypeSize] = [
              .xSmall, .small, .medium, .large,
              .xLarge, .xxLarge, .xxxLarge
          ]
          for size in standard {
              XCTAssertFalse(
                  FormFieldRow<EmptyView>.shouldUseVerticalLayout(size),
                  "\(size) should use horizontal layout"
              )
          }
      }

      func testShouldUseVerticalLayout_accessibilitySizes_returnsTrue() {
          let accessibility: [DynamicTypeSize] = [
              .accessibility1, .accessibility2, .accessibility3,
              .accessibility4, .accessibility5
          ]
          for size in accessibility {
              XCTAssertTrue(
                  FormFieldRow<EmptyView>.shouldUseVerticalLayout(size),
                  "\(size) should use vertical layout"
              )
          }
      }
  }
  ```
- **Verification:** `xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' -only-testing:KizbaTests/FormFieldRowAccessibilityTests` — 2 tests, 0 failures.
- **Risks:** None. Pure function, no concurrency, no UI dependencies. `FormFieldRow<EmptyView>` is the canonical way to reference the static method on a generic type.

### Task 3 — Verify no regressions

- **Objective:** Full suite green.
- **Files to modify:** None.
- **Verification:**
  - Focused: `xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' -only-testing:KizbaTests/FormFieldRowAccessibilityTests`
  - SourceGrepTests: `xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' -only-testing:KizbaTests/SourceGrepTests`
  - Full suite: `xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS'` — all pass, 0 failures
- **Success criteria:** Test count ≥ 718 (716 baseline from D.2 + 2 new), 0 failures.
- **Risks:** None.

## Concurrency Notes

No concurrency concerns. `FormFieldRow` is a plain SwiftUI `View` struct. The new static helper is a pure function. No actor boundaries crossed.

## Commit message

```
feat(a11y): FormFieldRow vertical layout for accessibility sizes (D.3)

When dynamicTypeSize >= .accessibility1, FormFieldRow switches from
HStack(label, control) to VStack(alignment: .leading) so content is
not clipped at large text sizes. Extracted shouldUseVerticalLayout(_:)
static helper; two new tests in FormFieldRowAccessibilityTests.
```

## Suggested current step

Tasks 1 and 2 can be done together (single edit pass). Task 3 is verification only.
