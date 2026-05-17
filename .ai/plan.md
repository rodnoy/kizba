# MVP6 — Phase D (Biometric availability) + Phase G (3 critical bugs)

## Status of prior phases

Phase A (Recents controls) — DONE. Phase B (Settings tabs + Save feedback + InfoTooltip) — DONE. Phase C (App-wide tooltips + advisory grep rule) — DONE. Baseline: **1039 tests, 17 skipped, 0 failures**. Release build clean.

## Goal

1. **Phase G** — close three regressions discovered after Phase C ship:
   - G.1 Favorites section has no visibility toggle and no collapse memory (asymmetric with Recents after Phase A).
   - G.2 Tapping a Recents/Favorites row in the sidebar writes the entry path into `state.router.selectedFolder`, never into `selectedEntryID`. Detail column does not open.
   - G.3 The Recents and Favorites persistence layers use bare keys (`"kizba.recentEntries"`, `"kizba.favorites"`) that collide with the DEBUG `MockPassManager` fixture corpus, so a Release build started after a DEBUG launch reads fixture paths it cannot resolve.
2. **Phase D** — finish the MVP6 roadmap item "Biometric availability + confirm-to-disable":
   - D.1 Inject `BiometricAuthenticating` into `SettingsModel`; add a guarded `requestToggleBiometric(_:)`.
   - D.2 Gate the SecurityTab toggle on `biometricAvailability` and surface auth failures.
   - D.3 Add `FakeBiometricAuthenticator` + four behaviour tests.

No new dependencies. No `as!`. English literals only. DS-tokens only in `Features/**`.

## Constraints (durable)

- Swift 5.10, macOS 14, strict concurrency complete.
- No `as!`, no third-party deps, no stdin/stdout logging.
- DS-only styling (tokens; no inline `Color.<name>`, numeric cornerRadius, numeric opacity in `Features/**`).
- English-only literals.
- `SourceGrepTests` must stay green (including `testIconOnlyButtonsHaveHelp_inAuditedFeatures` from C.2).
- Settings persistence allow-list (String / URL / Int / Double / Bool) — do not extend.

## Sequencing decision — G first, then D

G is sequenced before D for three reasons:

1. **G is user-visible breakage.** G.2 makes Recents and Favorites rows look interactive but produce nothing in the detail column — anyone who lands on the sidebar after Phase A.3 hits it immediately. G.3 silently leaks DEBUG fixture data into Release. Both block credible QA on D.
2. **G unblocks the D test plan.** Phase D adds biometric assertions that rely on a clean Settings tab and a stable sidebar — G.1 normalises the Favorites controls so the D.2 SecurityTab demo doesn't surface the asymmetric Favorites row right next to the new gated Touch ID toggle.
3. **G's risk profile rises with each task** (G.1 additive → G.2 API change → G.3 persistence + migration). Sequencing inside G is by risk; sequencing G before D keeps the high-risk persistence migration off the same branch as the new biometric injection.

Inside G: **G.1 → G.2 → G.3**. Inside D: **D.1 → D.2 → D.3**.

## Tasks

### G.1 — Favorites visibility toggle + collapsible section

**Description:** Mirror the Phase A Recents controls for Favorites. Add a `showFavorites` settings key (Bool, default `true`), surface a Toggle in `GeneralTab`, and gate the Favorites sidebar section through `@AppStorage` + wrap rows in a `DisclosureGroup` whose expansion persists across launches.

**Agent:** smart-worker

**Files:**
- MOD `Kizba/Domain/Protocols/SettingsStoring.swift` — add `SettingsKeys.showFavorites = "showFavorites"` and `defaultShowFavorites: Bool = true` next to their `showRecents` siblings.
- MOD `Kizba/Infrastructure/Settings/UserDefaultsSettingsStore.swift` — register default `true` for `showFavorites` inside `init`, reusing the existing `namespaced(_:)` helper.
- MOD `Kizba/Presentation/Features/Settings/SettingsModel.swift` — add `public var showFavorites: Bool`, extend `SettingsSnapshot` + `currentSnapshot` + `initialSnapshot`, load in `init`, persist in `save()`.
- MOD `Kizba/Presentation/Features/Settings/Tabs/GeneralTab.swift` — add a `FormFieldRow` with a `Toggle("Show Favorites in Sidebar", isOn: $model.showFavorites)` placed inside a `FormSection("Favorites")` above `recentsSection` (Favorites already render above Recents in the sidebar; keep order parallel).
- MOD `Kizba/Presentation/Features/Sidebar/SidebarView.swift` — add `@AppStorage("app.kizba.settings.showFavorites") private var showFavorites: Bool = true` and `@AppStorage("kizba.sidebar.favoritesExpanded") private var favoritesExpanded: Bool = true`. Gate the Favorites section via `if showFavorites && !favoritesModel.favorites.isEmpty`. Wrap the row `ForEach` inside `DisclosureGroup(isExpanded: $favoritesExpanded)` with a `Text("Favorites")` label.

**Tests:**
- `KizbaTests/UserDefaultsSettingsStoreTests.swift`:
  - `testShowFavorites_defaultsTrue`
  - `testShowFavorites_roundTrip`
- `KizbaTests/SettingsModelTests.swift`:
  - `testShowFavorites_defaultIsTrue`
  - `testShowFavorites_persists`
  - `testHasChanges_flipsWhenShowFavoritesMutated`

**Verification:**
```sh
xcodebuild build -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS'
xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' \
  -only-testing:KizbaTests/SettingsModelTests \
  -only-testing:KizbaTests/UserDefaultsSettingsStoreTests
xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS'
rg -n 'showFavorites' Kizba/ KizbaTests/
```

**Branch:** `mvp6/g1-favorites-toggle`
**Commit:** `feat(sidebar): Favorites visibility toggle + collapsible section (MVP6.G.1)`
**Difficulty:** S
**Risks:**
- `@AppStorage` key string must match the namespaced UserDefaults key produced by `UserDefaultsSettingsStore.namespaced(SettingsKeys.showFavorites)` exactly — drift means the toggle and the sidebar reference different slots.
- `SettingsSnapshot` is a private struct; forgetting to extend both `currentSnapshot` and `initialSnapshot` silently breaks `hasChanges`. Tests catch this.

---

### G.2 — Sidebar tap routing fix (Recents/Favorites)

**Description:** Today `SidebarView.selection` is bound to `state.router.selectedFolder`; Recents and Favorites rows write entry paths into it via `.onTapGesture { selection = entryPath }`, but `selectedFolder` is consumed by the middle column as a folder name, so the detail column never opens. Introduce a second binding for the entry selection and route Recents/Favorites taps through it. Folder rows continue to use the existing folder binding.

**Agent:** smart-worker

**Files:**
- MOD `Kizba/Presentation/Features/Sidebar/SidebarView.swift`:
  - Add `@Binding var entrySelection: String?`.
  - Extend `init` with a matching parameter.
  - Replace `.onTapGesture { selection = entryPath }` inside the Recents and Favorites `ForEach` bodies with `.onTapGesture { entrySelection = entryPath }`.
  - Update the `isSelected` checks for Recents/Favorites rows to compare against `entrySelection`.
  - Folder rows continue to bind to `selection`.
- MOD `Kizba/Presentation/Root/RootSplitView.swift` (or wherever `SidebarView(...)` is instantiated) — pass `entrySelection: Binding(get: { state.router.selectedEntryID }, set: { state.router.selectedEntryID = $0 })`.
- Optional: extract a file-private (or `internal` for testability) helper `applyEntrySelection(path:state:)` that owns the routing decision so it can be unit-tested without spinning up SwiftUI.

**Tests:**
- If the helper is extracted: `KizbaTests/Sidebar/SidebarEntryRoutingTests.swift` (or extend an existing Sidebar test file) — verify `selectedEntryID` is set and `selectedFolder` is left untouched.
- Otherwise: rely on the AppState round-trip in existing `AppRouterTests` plus a manual smoke noted in the commit message.

**Verification:**
```sh
xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' \
  -only-testing:KizbaTests/SidebarModelTests
xcodebuild build -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS'
xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS'
```

**Branch:** `mvp6/g2-sidebar-entry-selection`
**Commit:** `fix(sidebar): route Recents/Favorites taps to selectedEntryID (MVP6.G.2)`
**Difficulty:** S
**Risks:**
- `SidebarView.init` gains a new required parameter — every call site must be updated. The compiler surfaces the regression loudly; no behavioural fallback to mask it.
- Folder taps must keep their existing semantics (write `selectedFolder`, do not clear `selectedEntryID` unless that is the existing behaviour).

---

### G.3 — Persisted leak fix (namespace recents/favorites keys + migration)

**Description:** `UserDefaultsRecentEntriesStore` and `UserDefaultsFavoritesStore` write to bare keys (`"kizba.recentEntries"`, `"kizba.favorites"`) inside `UserDefaults.standard`. DEBUG builds wired with `MockPassManager` write fixture entry paths to those same slots, and a subsequent Release launch reads them back as if they were real entries. Fix by namespacing both keys to `app.kizba.<feature>.entries.v1`. Migrate **Favorites only** (user-curated data is worth preserving) and start Recents fresh (auto-collected; migrating risks promoting fixture noise into Release).

**Agent:** smart-worker

**Files:**
- ADD `Kizba/Infrastructure/Storage/StorageKeys.swift` (new file) — centralised constants:
  - `recentsEntriesV1 = "app.kizba.recents.entries.v1"`
  - `favoritesEntriesV1 = "app.kizba.favorites.entries.v1"`
  - `legacyRecentsEntries = "kizba.recentEntries"`
  - `legacyFavoritesEntries = "kizba.favorites"`
- MOD `Kizba/Infrastructure/Recents/UserDefaultsRecentEntriesStore.swift`:
  - Switch the persistence key to `StorageKeys.recentsEntriesV1`.
  - In `init`, best-effort `defaults.removeObject(forKey: StorageKeys.legacyRecentsEntries)` — no value migration.
- MOD `Kizba/Infrastructure/Favorites/UserDefaultsFavoritesStore.swift`:
  - Switch the persistence key to `StorageKeys.favoritesEntriesV1`.
  - In `init`, one-shot migration: if `object(forKey: new) == nil` and `array(forKey: legacy) != nil`, copy the array and then `removeObject(forKey: legacy)`. Idempotent on second construction.
- VERIFY (no edit) `Kizba/Presentation/Features/Sidebar/SidebarView.swift` — Recents section is already gated by `if showRecents && !recents.isEmpty` after Phase A.3.

**Tests:**
- `KizbaTests/Infrastructure/UserDefaultsRecentEntriesStoreTests.swift`:
  - `testInit_readsFromNewNamespacedKey`
  - `testInit_ignoresLegacyKey_andRemovesIt`
  - `testRecord_persistsToNewKey_only`
- `KizbaTests/Infrastructure/UserDefaultsFavoritesStoreTests.swift`:
  - `testInit_migratesLegacyFavorites_onceWhenNewKeyAbsent`
  - `testInit_doesNotOverwriteNewKey_whenBothPresent`
  - `testInit_idempotent_secondConstructionIsNoOp`
- Use isolated `UserDefaults(suiteName:)` per test; tear down via `removePersistentDomain(forName:)`.

**Verification:**
```sh
xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' \
  -only-testing:KizbaTests/UserDefaultsRecentEntriesStoreTests \
  -only-testing:KizbaTests/UserDefaultsFavoritesStoreTests
xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS'
rg -n '"kizba\.recentEntries"' Kizba/ KizbaTests/   # only StorageKeys.legacy* match
rg -n '"kizba\.favorites"'      Kizba/ KizbaTests/  # only StorageKeys.legacy* match
rg -n 'app\.kizba\.(recents|favorites)\.entries\.v1' Kizba/ KizbaTests/
```

**Branch:** `mvp6/g3-storage-key-namespace`
**Commit:** `fix(storage): namespace recents/favorites keys + migrate favorites (MVP6.G.3)`
**Difficulty:** M
**Risks:**
- Migration must be idempotent — second construction must not re-import legacy values once the new key is populated. The `testInit_idempotent_secondConstructionIsNoOp` test pins this.
- Existing pure-DEBUG users will see Recents reset to empty on first run after the fix. Intentional: better than promoting fixture entries.

---

### D.1 — Inject `BiometricAuthenticating` into `SettingsModel`

**Description:** `SettingsModel` currently flips `touchIDPerRevealEnabled` with no biometric pre-flight. Inject `BiometricAuthenticating` and add a guarded toggle method.

**Agent:** smart-worker

**Files:**
- MOD `Kizba/Presentation/Features/Settings/SettingsModel.swift`:
  - Extend `init` with `biometricAuth: (any BiometricAuthenticating)? = nil` (`nil` default keeps existing tests/previews compiling).
  - Store as `private let biometricAuth`.
  - Add `public var biometricAvailability: BiometricAvailability` computed off the injected service (or a cached `private(set) var` refreshed at init + after an explicit `refreshBiometricAvailability()`).
  - Add `public enum ToggleBiometricError: Error, Equatable { case cancelled; case unavailable; case failed(String) }`.
  - Add `public func requestToggleBiometric(_ desired: Bool) async -> Result<Void, ToggleBiometricError>`:
    - **Enable (`desired == true`):** persist immediately, no prompt. Matches Apple's FileVault / Touch-ID-for-Apple-Pay UX where enabling does not require a confirmation prompt — the *next protected action* will surface the system sheet anyway.
    - **Disable (`desired == false`):** call `await biometricAuth.authenticate(reason: "Confirm to disable Touch ID protection")`. On `.success`: persist. On `.cancelled`/`.failed`: return `.failure(...)` and DO NOT mutate the persisted flag.
    - **`biometricAuth == nil`:** permit disable without prompt (test/preview convenience).
- MOD `Kizba/App/KizbaApp.swift` (and any other call site that constructs `SettingsModel`) — thread `environment.biometricAuth` into the model.
- ADD entry to `.ai/decisions.md`: "Enabling Touch ID protection does not require a confirmation prompt; disabling does. A previously-enabled-but-now-unavailable setting is NOT auto-flipped to off — instead the SecurityTab renders an explanatory disabled row (D.2)."

**Tests:** covered in D.3.

**Verification:**
```sh
xcodebuild build -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS'
xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS'
```

**Branch:** `mvp6/d1-biometric-injection`
**Commit:** `feat(settings): inject BiometricAuthenticating + requestToggleBiometric (MVP6.D.1)`
**Difficulty:** M
**Risks:**
- Existing tests that build `SettingsModel` without a biometric service must continue to compile (default `nil`) — verify with a clean build before adding D.3 tests.

---

### D.2 — SecurityTab UI gating + auth-failure banner

**Description:** Branch the Touch ID toggle on `model.biometricAvailability`. Render an informational disabled row when unavailable; surface failed disable attempts through a toast (or an inline error if `ToastCenter` is not wired here).

**Agent:** smart-worker

**Files:**
- MOD `Kizba/Presentation/Features/Settings/Tabs/SecurityTab.swift`:
  - Branch on `model.biometricAvailability`:
    - **`.available`:** render a Toggle whose binding invokes `Task { _ = await model.requestToggleBiometric(newValue) }`. On `.failure`, surface via `ToastCenter` (see `RootSplitView.swift:52`). Fallback: if `ToastCenter` is not reachable here, render an inline `lastBiometricError: String?` field below the row (the field lives on `SettingsModel`).
    - **`.unavailable(let reason)`:** disabled `FormFieldRow(label: "Require Touch ID for reveal", infoText: "Touch ID is not available on this Mac: \(reasonText(reason)).")` with `Text("Unavailable")` as the value.
  - Add a file-private helper `func reasonText(_ reason: BiometricUnavailableReason) -> String` mapping cases to short user-facing phrases.
- DS-tokens only: `theme.colors.onSurfaceMuted`, `theme.typography.caption`, etc.

**Tests:** covered in D.3 (model layer) + manual smoke documented in commit message.

**Verification:**
```sh
xcodebuild build -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS'
xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS'
```

**Branch:** `mvp6/d2-security-tab-gating`
**Commit:** `feat(settings): SecurityTab biometric gating + failure toast (MVP6.D.2)`
**Difficulty:** S
**Risks:**
- DS-token compliance — `SourceGrepTests` catches numeric opacity / literal colours.
- `ToastCenter` availability — fall back to inline error if not present at this level.

---

### D.3 — `FakeBiometricAuthenticator` + 4 tests

**Description:** Add a recordable fake conforming to `BiometricAuthenticating`. Cover the four corners of the toggle behaviour matrix.

**Agent:** smart-worker

**Files:**
- ADD (or REUSE if it already exists) `KizbaTests/Fixtures/FakeBiometricAuthenticator.swift`:
  ```swift
  final class FakeBiometricAuthenticator: BiometricAuthenticating, @unchecked Sendable {
      private let lock = NSLock()
      private var _availability: BiometricAvailability
      private var _authenticateResult: AuthenticationResult
      private(set) var authenticateCalls: [String] = []
      // setters / getters guarded by `lock`
  }
  ```
- MOD `KizbaTests/SettingsModelTests.swift`:
  - `testToggleBiometricOff_requiresAuth_successPersists`
  - `testToggleBiometricOff_authCancelled_leavesEnabled`
  - `testToggleBiometricOn_persistsWithoutAuth`
  - `testBiometricAvailability_propagatesFromAuth`

**Verification:**
```sh
xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' \
  -only-testing:KizbaTests/SettingsModelTests
xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS'
```

**Branch:** `mvp6/d3-fake-biometric-tests`
**Commit:** `test(settings): biometric toggle behaviour matrix (MVP6.D.3)`
**Difficulty:** S
**Risks:** none beyond standard test-fixture upkeep.

---

## Acceptance criteria — Phase D + Phase G

- [ ] G.1: `showFavorites` toggle persists; Favorites section honours both the toggle and the disclosure state across launches.
- [ ] G.2: Tapping a Recents or Favorites row opens the corresponding entry in the detail column; folder taps still select the folder.
- [ ] G.3: No production code reads or writes the legacy `"kizba.recentEntries"` / `"kizba.favorites"` keys (only `StorageKeys.legacy*` declarations match the greps); Favorites survive the rename; Recents start empty after migration.
- [ ] D.1: `SettingsModel` exposes `biometricAvailability` + `requestToggleBiometric(_:)`; enable persists without prompt, disable requires successful auth.
- [ ] D.2: SecurityTab renders an `.unavailable` informational row when biometrics are missing; failure to disable surfaces through `ToastCenter` (or inline fallback).
- [ ] D.3: Four new behaviour tests green; `FakeBiometricAuthenticator` records call counts.
- [ ] Full suite green: ≥1045 tests (1039 baseline + ~6 from G.1 + ~6 from G.3 + ~4 from D.3, minus any subsumed cases), 0 failures.
- [ ] Release build clean.
- [ ] Grep bans clean.

## Verification commands (Phase D + Phase G final)

```sh
xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS'
xcodebuild build -scheme Kizba -project Kizba.xcodeproj -configuration Release -destination 'platform=macOS'
rg -n '\bas!\b' Kizba/
rg -n 'Logger.*stdin|print\(.*stdin' Kizba/ KizbaTests/
rg -n '"kizba\.recentEntries"' Kizba/ KizbaTests/   # only StorageKeys.legacy* match
rg -n '"kizba\.favorites"'      Kizba/ KizbaTests/  # only StorageKeys.legacy* match
rg -n 'app\.kizba\.(recents|favorites)\.entries\.v1' Kizba/ KizbaTests/   # new keys
```

## Open questions / assumptions

- `ToastCenter` is reachable from the SecurityTab call stack (per `RootSplitView.swift:52`). If not — fall back to an inline `lastBiometricError: String?` on `SettingsModel` rendered below the row.
- ViewInspector is NOT available in this project (consistent with B.3 / C.1). G.2 testability comes from extracting `applyEntrySelection(path:state:)`; the view body itself stays untested at the unit level.
- `StorageKeys` lives in a dedicated file `Kizba/Infrastructure/Storage/StorageKeys.swift` rather than inline inside the two stores, so a future Phase H can extend it without re-opening either store.
- `BiometricAvailability` and `BiometricUnavailableReason` already exist as part of `BiometricAuthenticating` (Phase B work). If not — D.1 must define them first; revisit the plan in that case.

## Suggested current step

Run **smart-worker** on **Task G.1** — additive, lowest risk, mirrors the proven Phase A pattern, and warms up the persistence / settings touch-points before the higher-risk G.2 (API change on `SidebarView.init`) and G.3 (persistence migration).
