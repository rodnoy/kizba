# MVP6 Phase A — Recents settings + fold/unfold

## Status of prior milestone

- MVP5 shipped: Search ⌘K + Favorites + Recents + Menu-bar + Polish.
- Suite: 1000 tests, 0 failures. Release build clean. Grep bans clean.

## Goal Phase A

Give the user control over the Recents sidebar section: hide/show entirely, set the cap (range 3–7, default 7), collapse the section in place. Replace the hard-coded `maxCount = 20` default in stores with a settings-driven default.

## Constraints (durable)

- Swift 5.10, macOS 14, `SWIFT_STRICT_CONCURRENCY = complete`.
- No `as!`. No `Logger.*stdin|print\(.*stdin` patterns.
- No third-party dependencies.
- English in code, comments, commits, docs.
- `@Observable` + manual DI via initializers; actor-based stores.
- Design-system tokens in `Kizba/Presentation/Features/**` (no inline `Color.<name>`, numeric `cornerRadius`, numeric `.opacity()`).
- `SourceGrepTests` must remain green.

## Open decision (locked in A.1)

- `recentsLimit` range = `3...7`, default = `7`.
- Previous hard-coded cap of 20 in stores is removed; default flows from `SettingsKeys.defaultRecentsLimit`.

---

## Tasks

### A.1 — SettingsKeys + default migration

**Description:** Add two new settings keys and a single source of truth for the recents default; remove `20` literals from store constructors.

**Agent:** smart-worker

**Files to modify:**
- `Kizba/Infrastructure/Settings/SettingsKeys.swift`:
  - `static let showRecents = "kizba.settings.showRecents"`  (Bool, default `true`).
  - `static let recentsLimit = "kizba.settings.recentsLimit"` (Int, default `7`, bounds `3...7`).
  - `static let defaultRecentsLimit: Int = 7`.
- `Kizba/Domain/Protocols/SettingsStoring.swift` — add typed accessors for both keys.
- `Kizba/Infrastructure/Settings/UserDefaultsSettingsStore.swift`:
  - Implement get/set with `max(3, min(7, value))` clamp on write for `recentsLimit`.
  - Provide defaulted reads (`true` for `showRecents`, `defaultRecentsLimit` for `recentsLimit`).

**Tests:**
- `KizbaTests/Settings/SettingsKeysTests.swift`:
  - `testDefaults_present`
  - `testRecentsLimit_clampLow` (2 → 3)
  - `testRecentsLimit_clampHigh` (99 → 7)
- `KizbaTests/Settings/UserDefaultsSettingsStoreTests.swift`:
  - `testShowRecents_roundTrip`
  - `testRecentsLimit_roundTrip`

**Verification:**
```sh
xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' \
  -only-testing:KizbaTests/Settings/SettingsKeysTests \
  -only-testing:KizbaTests/Settings/UserDefaultsSettingsStoreTests
rg -n '\bmaxCount\s*=\s*20\b' Kizba/Infrastructure/Recents/
rg -n '\bas!\b' Kizba/
rg -n 'Logger.*stdin|print\(.*stdin' Kizba/ KizbaTests/
```

**Branch:** `mvp6/a1-settings-keys-recents`
**Commit:** `feat(settings): add showRecents + recentsLimit keys with clamp (MVP6.A.1)`
**Difficulty:** low
**Risks:** Hidden `20` literals elsewhere — grep before/after; if found, flag for A.2 instead of inline-fixing here.

---

### A.2 — Recents store: actor mutator + default replacement

**Description:** Replace `let maxCount` with mutable actor state; add `setMaxCount(_:)`; apply to production and DEBUG stores; emit a single `changes` event after persistence.

**Agent:** smart-worker

**Files to modify:**
- `Kizba/Domain/Protocols/RecentEntriesStoring.swift` — add `func setMaxCount(_ newValue: Int) async`.
- `Kizba/Infrastructure/Recents/UserDefaultsRecentEntriesStore.swift`:
  - `let maxCount` → `var maxCount`.
  - Default-initialised constructor reads `SettingsKeys.defaultRecentsLimit`.
  - `setMaxCount(_:)` clamps `3...7`, truncates `entries` to the new cap, persists, then yields exactly one `changes` event.
- `Kizba/Infrastructure/Recents/InMemoryRecentEntriesStore.swift` (`#if DEBUG`) — mirror behaviour; same `setMaxCount` semantics.

**Tests:**
- `KizbaTests/Recents/RecentEntriesStoreTests.swift` (extend existing):
  - `testSetMaxCount_truncatesAndEmitsOnce`
  - `testSetMaxCount_clampsLow` and `_clampsHigh`
  - `testInit_usesDefaultFromSettingsKey`
- Optional: assertion in `KizbaTests/SourceGrepTests.swift` that `InMemoryRecentEntriesStore` is only referenced inside `#if DEBUG` blocks (Release build cannot accidentally bind it).

**Verification:**
```sh
xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' \
  -only-testing:KizbaTests/Recents/RecentEntriesStoreTests
xcodebuild build -scheme Kizba -project Kizba.xcodeproj -configuration Release -destination 'platform=macOS'
```

**Branch:** `mvp6/a2-recents-store-mutator`
**Commit:** `refactor(recents): mutable maxCount + setMaxCount actor API (MVP6.A.2)`
**Difficulty:** medium
**Risks:**
- Emit-before-persist would leak stale data to observers — persist first, then yield.
- Strict-concurrency: ensure the protocol method is `async` (not `async throws` unless needed) and the actor isolation is preserved through generic constraints (`any RecentEntriesStoring`).

---

### A.3 — Sidebar: DisclosureGroup + showRecents gating

**Description:** Wrap the Recents section in a `DisclosureGroup`, persist expansion via `@AppStorage`, and elide the section entirely when `showRecents == false`.

**Agent:** smart-worker

**Files to modify:**
- `Kizba/Presentation/Features/Sidebar/SidebarView.swift`:
  - `@AppStorage("kizba.settings.showRecents") private var showRecents: Bool = true`
  - `@AppStorage("kizba.sidebar.recentsExpanded") private var recentsExpanded: Bool = true`
  - Wrap Recents in `if showRecents { DisclosureGroup(isExpanded: $recentsExpanded) { ... } label: { ... } }`, styled with DS tokens.
- If `SidebarView` becomes cluttered, extract `SidebarRecentsSection.swift` under the same folder.

**Tests:**
- `KizbaTests/Sidebar/RecentsModelTests.swift`:
  - `testCappedListReflectsSetMaxCount` — drive the model via a fake `RecentEntriesStoring`, call `setMaxCount(4)`, expect 4 items.
- If a sidebar-presentation helper exists, add `testRecentsSectionHiddenWhenShowRecentsFalse`. Otherwise mark as visual-smoke and rely on Phase F sequoia-smoke entry.

**Verification:**
```sh
xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' \
  -only-testing:KizbaTests/Sidebar
xcodebuild build -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS'
```

**Branch:** `mvp6/a3-sidebar-recents-disclosure`
**Commit:** `feat(sidebar): collapsible Recents section + showRecents gate (MVP6.A.3)`
**Difficulty:** low
**Risks:** `DisclosureGroup` chevron uses system colours by default — confirm DS grep tests still pass; if the chevron tinting needs override, do it via a DS modifier rather than inline `Color`.

---

### A.4 — SettingsView wiring (pre-tabs)

**Description:** Surface `showRecents` Toggle and `recentsLimit` Stepper in `SettingsView`; on Save, propagate the new limit to the actor store. This lands inside the current pre-tabs Settings layout; Phase B.3 will move it into `GeneralTab`.

**Agent:** smart-worker

**Files to modify:**
- `Kizba/Presentation/Features/Settings/SettingsModel.swift`:
  - Add `var showRecents: Bool`, `var recentsLimit: Int`.
  - Load both in `load()` via the injected `SettingsStoring`.
  - In `save()`: persist both, then `Task { await environment.recentStore.setMaxCount(self.recentsLimit) }`.
- `Kizba/Presentation/Features/Settings/SettingsView.swift`:
  - New `FormSection("Recents")` containing:
    - `Toggle("Show Recents in Sidebar", isOn: $model.showRecents)`
    - `Stepper("Recents limit: \(model.recentsLimit)", value: $model.recentsLimit, in: 3...7)`
  - Wire both via DS components (`FormFieldRow` where appropriate).

**Tests:**
- `KizbaTests/Settings/SettingsModelTests.swift`:
  - `testShowRecents_persists`
  - `testRecentsLimit_persistsAndClamps`
  - `testSave_callsSetMaxCountOnStore` — fake `RecentEntriesStoring` records calls.

**Verification:**
```sh
xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' \
  -only-testing:KizbaTests/Settings/SettingsModelTests
xcodebuild build -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS'
```

**Branch:** `mvp6/a4-settings-recents-wiring`
**Commit:** `feat(settings): recents toggle + limit stepper wired to store (MVP6.A.4)`
**Difficulty:** low
**Risks:** Double-write — confirm `setMaxCount` does not also write to `SettingsKeys.recentsLimit`; that key is owned by the settings store alone.

---

## Acceptance criteria (Phase A)

1. `SettingsKeys` exposes `showRecents`, `recentsLimit`, `defaultRecentsLimit`.
2. `rg -n '\bmaxCount\s*=\s*20\b' Kizba/Infrastructure/Recents/` → 0 matches.
3. `RecentEntriesStoring` exposes `setMaxCount(_:) async`; production + DEBUG implementations conform; truncation emits exactly one `changes` event after persistence.
4. `SidebarView` renders Recents inside a `DisclosureGroup` whose state persists via `@AppStorage("kizba.sidebar.recentsExpanded")`; the entire section is elided when `showRecents == false`.
5. Settings UI exposes the new Toggle + Stepper; Save persists both keys and propagates the limit to the store.
6. New tests pass; existing suite remains green (≥1000 tests).
7. Release build clean; grep bans clean; design-system grep rules green.

## Verification commands (Phase A final)

```sh
xcodebuild test  -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS'
xcodebuild build -scheme Kizba -project Kizba.xcodeproj -configuration Release -destination 'platform=macOS'
rg -n '\bas!\b' Kizba/
rg -n 'Logger.*stdin|print\(.*stdin' Kizba/ KizbaTests/
rg -n '\bmaxCount\s*=\s*20\b' Kizba/Infrastructure/Recents/
```

---

## Suggested current step

Run **smart-worker** on **Task A.1** (SettingsKeys + default migration).
