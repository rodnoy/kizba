# E.3 — Settings + Injection for Touch ID Per-Reveal

## Goal

Add a persistent Bool setting `requireBiometricReveal` (default `false`), inject `BiometricAuthenticating` into `AppEnvironment`, and gate password reveal in `EntryDetailModel` behind biometric auth when the setting is enabled. Deterministic tests via `FakeBiometricAuthenticator`.

## Constraints

- Zero third-party dependencies.
- No `as!`, no stdin logging (existing grep bans).
- Code/comments/commits in English.
- Never call `LAContext.evaluatePolicy` in tests.
- Follow existing patterns: `SettingsKeys` constants, `AppEnvironment` manual DI, `InMemorySettingsStore` for tests.
- `SWIFT_STRICT_CONCURRENCY = complete`.

## Tasks

### Task 1 — Add `requireBiometricReveal` setting key + default

- **Objective:** Register the new Bool key in `SettingsKeys` with default `false`.
- **Files to modify:**
  - `Kizba/Domain/Protocols/SettingsStoring.swift` — add `public nonisolated static let requireBiometricReveal = "requireBiometricReveal"` and `public nonisolated static let defaultRequireBiometricReveal: Bool = false` to `SettingsKeys`.
  - `Kizba/Infrastructure/Settings/UserDefaultsSettingsStore.swift` — register the default in `init()` alongside the existing `clipboardClearDelaySeconds` registration.
- **Why minimal:** Two single-line additions to existing enum + one line in existing init.
- **Verification:** Project compiles. `rg 'requireBiometricReveal' Kizba/` shows exactly the expected files.
- **Commit:** `feat(mvp3): add requireBiometricReveal settings key (E.3.1)`

### Task 2 — Add `FakeBiometricAuthenticator` test fixture

- **Objective:** Shared test double for `BiometricAuthenticating` that returns configurable results without touching LocalAuthentication.
- **File to add:** `KizbaTests/Fixtures/FakeBiometricAuthenticator.swift`
- **Core shape:**
  ```swift
  // Deterministic BiometricAuthenticating double for unit tests.
  // Never calls LAContext — safe for CI.
  struct FakeBiometricAuthenticator: BiometricAuthenticating {
      var availability: BiometricAvailability = .available
      var authResult: BiometricResult = .success

      func isAvailable() -> BiometricAvailability { availability }
      func authenticate(reason: String) async -> BiometricResult { authResult }
  }
  ```
- **Why minimal:** Single file, no production code touched.
- **Verification:** Project compiles.
- **Commit:** `test: add FakeBiometricAuthenticator fixture (E.3.2)`

### Task 3 — Inject `BiometricAuthenticating` into `AppEnvironment`

- **Objective:** Add an optional `biometricAuth` property to `AppEnvironment`. Wire `LocalAuthBiometricAuthenticator()` in `live()`, `nil` in `preview()`.
- **File to modify:** `Kizba/App/AppEnvironment.swift`
- **Changes:**
  1. Add property: `let biometricAuth: (any BiometricAuthenticating)?`
  2. Add parameter to `init`: `biometricAuth: (any BiometricAuthenticating)? = nil` (default nil keeps all existing call sites compiling).
  3. In `live()`: pass `biometricAuth: LocalAuthBiometricAuthenticator()` to the constructor (add to the return statement).
  4. In `preview()`: omit (defaults to nil).
- **Why minimal:** One new stored property + one init parameter with default + one line in `live()`. All existing test/preview constructions compile unchanged due to default `nil`.
- **Verification:** Project compiles. `rg 'biometricAuth' Kizba/App/AppEnvironment.swift` shows the new wiring.
- **Commit:** `feat(mvp3): inject BiometricAuthenticating into AppEnvironment (E.3.3)`

### Task 4 — Gate password reveal in `EntryDetailModel`

- **Objective:** When `requireBiometricReveal` is `true` AND biometric auth is available, intercept the reveal toggle via a new async method `requestReveal()`. If auth succeeds, set `isPasswordRevealed = true`. If it fails/cancels, leave it `false`.
- **File to modify:** `Kizba/Presentation/Features/EntryDetail/EntryDetailModel.swift`
- **Changes:**
  1. Add method:
     ```swift
     /// Attempt to reveal the password, gated by the biometric
     /// setting. When the setting is off or biometrics unavailable,
     /// reveals immediately. Otherwise prompts for biometric auth
     /// and reveals only on success.
     func requestReveal() async {
         guard !isPasswordRevealed else { return }

         let requireBio = environment.settings
             .value(for: SettingsKey<Bool>(SettingsKeys.requireBiometricReveal))
             ?? SettingsKeys.defaultRequireBiometricReveal

         guard requireBio,
               let auth = environment.biometricAuth,
               auth.isAvailable() == .available
         else {
             isPasswordRevealed = true
             return
         }

         let result = await auth.authenticate(reason: "Reveal password")
         if result == .success {
             isPasswordRevealed = true
         }
     }
     ```
- **Why minimal:** One new method. Does NOT change `isPasswordRevealed` property visibility or `SecretRevealField`. The view layer will call this method instead of directly toggling the binding.
- **Verification:** Project compiles.
- **Commit:** `feat(mvp3): gate password reveal behind biometric auth (E.3.4)`

### Task 5 — Wire `requestReveal()` in `EntryDetailView`

- **Objective:** Replace the direct `$model.isPasswordRevealed` binding on the reveal toggle with a custom binding that calls `requestReveal()` on the true→reveal transition.
- **File to modify:** `Kizba/Presentation/Features/EntryDetail/EntryDetailView.swift`
- **Change:** Replace `isRevealed: $model.isPasswordRevealed` with a proxy `Binding<Bool>`:
  ```swift
  isRevealed: Binding(
      get: { model.isPasswordRevealed },
      set: { newValue in
          if newValue {
              Task { await model.requestReveal() }
          } else {
              model.isPasswordRevealed = false
          }
      }
  )
  ```
- **Why minimal:** ~6 lines changed in one call site. `SecretRevealField` is NOT modified. The hide direction (true→false) remains instant. `NewEntrySheet` and `EditEntrySheet` are NOT affected (they use local `@State` — no biometric gate needed for entries being created/edited).
- **Verification:** Project compiles.
- **Commit:** `feat(mvp3): wire biometric reveal gate in EntryDetailView (E.3.5)`

### Task 6 — Add `requireBiometricReveal` to `SettingsModel` + `SettingsView`

- **Objective:** Expose the toggle in the Settings UI so the user can enable/disable it.
- **Files to modify:**
  - `Kizba/Presentation/Features/Settings/SettingsModel.swift` — add `public var requireBiometricReveal: Bool` property, read in `init`, persist in `save()`, reset in `resetToDefaults()`.
  - `Kizba/Presentation/Features/Settings/SettingsView.swift` — add a `Toggle` row in the Security section (or create one if absent).
- **Why minimal:** Follows the exact pattern of `clipboardClearDelaySeconds` — read/save/reset cycle.
- **Verification:** Project compiles. Settings window shows the toggle.
- **Commit:** `feat(mvp3): add Touch ID per-reveal toggle to Settings (E.3.6)`

### Task 7 — Add deterministic tests

- **Objective:** Test `requestReveal()` logic without touching LocalAuthentication.
- **File to add:** `KizbaTests/EntryDetailModelBiometricTests.swift`
- **Test methods:**
  1. `testRequestReveal_settingOff_revealsImmediately` — setting `false`, call `requestReveal()`, assert `isPasswordRevealed == true`.
  2. `testRequestReveal_settingOn_biometricSuccess_reveals` — setting `true`, fake returns `.success`, assert revealed.
  3. `testRequestReveal_settingOn_biometricCancelled_staysHidden` — setting `true`, fake returns `.cancelled`, assert NOT revealed.
  4. `testRequestReveal_settingOn_biometricFailed_staysHidden` — setting `true`, fake returns `.failed(.userFailed)`, assert NOT revealed.
  5. `testRequestReveal_settingOn_biometricUnavailable_revealsImmediately` — setting `true`, fake returns `.unavailable(...)` from `isAvailable()`, assert revealed (graceful fallback).
  6. `testRequestReveal_settingOn_noBiometricInjected_revealsImmediately` — setting `true` but `biometricAuth` is `nil`, assert revealed.
  7. `testRequestReveal_alreadyRevealed_noop` — already `true`, call again, assert still `true` (no auth prompt).
- **Test setup pattern:**
  ```swift
  let settings = AppEnvironment.InMemorySettingsStore()
  let fake = FakeBiometricAuthenticator(availability: .available, authResult: .success)
  let env = AppEnvironment(
      passManager: MockPassManager.preview(),
      clipboard: ...,
      settings: settings,
      passwordGenerator: LivePasswordGenerator(),
      biometricAuth: fake
  )
  let state = AppState(passManager: env.passManager)
  let model = EntryDetailModel(environment: env, state: state)
  // load an entry first, then test requestReveal()
  ```
- **Verification:** `xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' -only-testing:KizbaTests/EntryDetailModelBiometricTests` — 7 tests, 0 failures.
- **Commit:** `test: deterministic biometric reveal gate tests (E.3.7)`

### Task 8 — Full regression verification

- **Objective:** Ensure no regressions.
- **Files to modify:** None.
- **Verification:**
  ```sh
  xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS'
  rg -n '\bas!' Kizba/
  rg -n 'Logger.*stdin|print\(.*stdin' Kizba/
  ```
- **Success criteria:** All tests pass, 0 failures, grep bans clean.
- **Commit:** None (verification only). Update `.ai/handoff.md` and `.ai/build-log.md`.

## Suggested current step

Tasks 1–3 first (settings key + fixture + DI wiring). Then Tasks 4–5 (model + view gate). Then Task 6 (Settings UI). Then Task 7 (tests). Task 8 is verification only.
