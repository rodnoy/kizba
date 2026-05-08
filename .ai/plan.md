# Step 8.3 — SettingsView / SettingsModel: Wire Settings UI into the App

## Goal

Create `SettingsModel` (@MainActor, @Observable) and `SettingsView` (SwiftUI) that expose all user-configurable preferences: binary path overrides (pass, gpg, pinentry-mac), password store path override, clipboard clear delay stepper, and a "Re-detect binaries" button. Wire the Settings scene into `KizbaApp`. Provide well-known `SettingsKey` constants. Cover with unit tests using injected fakes.

## Constraints

- Swift 5.10, macOS 14, `SWIFT_STRICT_CONCURRENCY=complete`.
- Do NOT modify `project.pbxproj` (auto-sync picks up new files).
- `@MainActor` for `SettingsModel`; `@Observable` macro.
- Inject `SettingsStoring` and `BinaryLocating` for testability.
- `clipboardClearDelaySeconds` default = 30 (already registered in `UserDefaultsSettingsStore`).
- No secrets logged. Commit messages in English.
- `AppEnvironment.live()` must wire real `UserDefaultsSettingsStore` (replace `InMemorySettingsStore` / `UnavailableSettingsStore`).
- Keep `BinaryDiscoveryService` as `discovery` property on `AppEnvironment` so `SettingsModel` can call `reDetect()`.

## Tasks

### Task 1 — Well-known SettingsKey constants
- **Priority:** 1 (prerequisite for all other tasks)
- **Complexity:** small
- **Objective:** Add a `SettingsKeys` enum (caseless) with static typed `SettingsKey` constants for all 5 settings: `storePathOverride` (String), `passBinaryOverride` (String), `gpgBinaryOverride` (String), `pinentryBinaryOverride` (String), `clipboardClearDelaySeconds` (Int).
- **Files to modify:**
  - `Kizba/Domain/Protocols/SettingsStoring.swift` — append `SettingsKeys` enum at bottom.
- **Commit:** `feat(settings): add well-known SettingsKey constants`
- **Tests:** None (pure constants; exercised by Task 3 tests).
- **Verification:** `xcodebuild -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' build`

### Task 2 — SettingsModel
- **Priority:** 2
- **Complexity:** medium
- **Objective:** Create `@MainActor @Observable` class `SettingsModel` that reads/writes all 5 settings via injected `SettingsStoring`, exposes computed/stored properties for the view, and has an async `reDetectBinaries()` method that calls injected `BinaryLocating.reDetect()`.
- **Files to add:**
  - `Kizba/Presentation/Features/Settings/SettingsModel.swift`
- **Commit:** `feat(settings): add SettingsModel with injected dependencies`
- **Tests to add (Task 4):** `SettingsModelTests`
- **Verification:** build succeeds

### Task 3 — SettingsView + wire into KizbaApp Settings scene
- **Priority:** 3
- **Complexity:** medium
- **Objective:** Create `SettingsView` with: (a) General section — store path text field; (b) Binaries section — text fields for pass/gpg/pinentry-mac overrides + "Re-detect binaries" button; (c) Clipboard section — stepper for delay (range 5...300, step 5). Add `Settings { SettingsView(...) }` scene to `KizbaApp.body`. Add `discovery: any BinaryLocating` property to `AppEnvironment`. Wire `AppEnvironment.live()` to use real `UserDefaultsSettingsStore` instead of `InMemorySettingsStore`/`UnavailableSettingsStore`.
- **Files to add:**
  - `Kizba/Presentation/Features/Settings/SettingsView.swift`
- **Files to modify:**
  - `Kizba/App/KizbaApp.swift` — add `Settings` scene
  - `Kizba/App/AppEnvironment.swift` — add `discovery` property; wire real `UserDefaultsSettingsStore` in `live()`; update `init`, `preview()`
- **Commit:** `feat(settings): add SettingsView and wire Settings scene`
- **Tests:** None (UI; verified manually + by Task 4 model tests).
- **Verification:** `xcodebuild -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' build`

### Task 4 — SettingsModel unit tests
- **Priority:** 4
- **Complexity:** medium
- **Objective:** Test `SettingsModel` with injected `InMemorySettingsStore` (from AppEnvironment or extracted) and a `FakeBinaryLocating` stub. Verify reads, writes, defaults, and `reDetectBinaries()` calls through to the fake.
- **Files to add:**
  - `KizbaTests/SettingsModelTests.swift`
- **Test names:**
  - `testDefaultClipboardDelay` — model exposes 30 when store has no override
  - `testSetAndReadStorePathOverride` — round-trip string
  - `testSetAndReadBinaryOverrides` — round-trip pass/gpg/pinentry paths
  - `testSetClipboardDelay` — write persists to store
  - `testReDetectBinariesCallsDiscovery` — fake records `reDetect()` call
  - `testClearOverrideWritesNil` — setting empty string clears the key
- **Commit:** `test(settings): add SettingsModel unit tests`
- **Verification:** `xcodebuild -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' test -only-testing:KizbaTests/SettingsModelTests`

### Task 5 — Update existing test fakes for new AppEnvironment shape
- **Priority:** 3 (parallel with Task 3)
- **Complexity:** small
- **Objective:** If `AppEnvironment.init` gains a `discovery` parameter, update all existing test files that construct `AppEnvironment` to pass a fake/nil discovery. Ensure all 193+ existing tests still pass.
- **Files to modify:** any test files constructing `AppEnvironment` directly (grep for `AppEnvironment(` in `KizbaTests/`).
- **Commit:** `fix(tests): update AppEnvironment construction for discovery parameter`
- **Verification:** `xcodebuild -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' test`

## Acceptance Criteria

1. `xcodebuild test` passes all existing + new tests (≥199 tests, 0 failures).
2. `SettingsModelTests` — all 6 tests green.
3. App launches; ⌘, opens Settings window with General / Binaries / Clipboard sections.
4. Changing clipboard delay in Settings persists across quit/relaunch.
5. "Re-detect binaries" button triggers `reDetect()` on the discovery service.
6. `AppEnvironment.live()` uses real `UserDefaultsSettingsStore` (not in-memory).
7. No `project.pbxproj` modifications in the diff.
8. No secrets logged.

## Suggested current step

Start with **Task 1** (SettingsKey constants) — it's the smallest, has no dependencies, and unblocks all subsequent tasks.
