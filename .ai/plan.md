# MVP5 Phase C — Recents

## Goal

Add a "Recent Entries" feature: persist recently-viewed entry paths, display them in the sidebar (between Favorites and Folders), and boost recents/favorites in search ranking.

## Constraints

- No `as!` anywhere in Sources/.
- No `Logger.*stdin|print\(.*stdin` patterns.
- SWIFT_STRICT_CONCURRENCY = complete.
- `@Observable` + manual DI via initializers.
- macOS 14.0 deployment target, Swift 5.10.
- No third-party dependencies.
- `RecentEntriesStoring` follows the same actor-based protocol pattern as `FavoritesStoring`.
- Max 20 recent entries (FIFO eviction).

---

## Tasks

### C.1 — RecentEntriesStore protocol + UserDefaults implementation + fake

**Description:** Define the `RecentEntriesStoring` protocol, implement `UserDefaultsRecentEntriesStore` (production, UserDefaults-backed), and create `FakeRecentEntriesStore` test fixture.

**Agent:** smart-worker

**Files to create:**
- `Kizba/Domain/Protocols/RecentEntriesStoring.swift`
- `Kizba/Infrastructure/Recents/UserDefaultsRecentEntriesStore.swift`
- `KizbaTests/Fixtures/FakeRecentEntriesStore.swift`

**Signatures:**

```swift
// RecentEntriesStoring.swift
public protocol RecentEntriesStoring: Sendable {
    func record(_ path: String) async
    func recentPaths() async -> [String]
    func clear() async
    var recentsChanged: AsyncStream<Void> { get }
}

// UserDefaultsRecentEntriesStore.swift
public actor UserDefaultsRecentEntriesStore: RecentEntriesStoring {
    // Max 20 entries. FIFO: newest at index 0.
    // If path already exists, move to front (dedup).
    // UserDefaults key: "kizba.recentEntries"
    public init(defaults: UserDefaults = .standard, maxCount: Int = 20)
    public func record(_ path: String) async
    public func recentPaths() async -> [String]
    public func clear() async
    public nonisolated var recentsChanged: AsyncStream<Void> { get }
}

// FakeRecentEntriesStore.swift (in KizbaTests/Fixtures/)
actor FakeRecentEntriesStore: RecentEntriesStoring {
    // In-memory array, same contract. For tests.
    init()
    func record(_ path: String) async
    func recentPaths() async -> [String]
    func clear() async
    nonisolated var recentsChanged: AsyncStream<Void> { get }
}
```

**Tests to add:**
- `KizbaTests/Infrastructure/Recents/UserDefaultsRecentEntriesStoreTests.swift`
  - `testRecord_addsPath`
  - `testRecord_movesExistingToFront`
  - `testRecord_evictsOldestBeyondMax`
  - `testRecentPaths_returnsOrderedList`
  - `testClear_emptiesList`
  - `testRecentsChanged_emitsOnRecord`
  - `testRecentsChanged_emitsOnClear`

**Verification:**
```sh
xcodebuild build -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS'
xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' \
  -only-testing:KizbaTests/Infrastructure/Recents/UserDefaultsRecentEntriesStoreTests
rg -n '\bas!\b' Kizba/
rg -n 'Logger.*stdin|print\(.*stdin' Kizba/ KizbaTests/
```

**Branch:** `mvp5/c1-recent-entries-store`
**Commit:** `feat(recents): add RecentEntriesStoring protocol + UserDefaults impl (MVP5.C.1)`

**Difficulty:** low
**Risks:** UserDefaults suite isolation in tests — use a custom suite name to avoid cross-test pollution.

---

### C.2 — Wire recents into AppEnvironment, record on show, display in SidebarView

**Description:** Add `recentStore` to `AppEnvironment`, record entry path on successful `pass show` in `EntryDetailModel`, create `RecentsModel` for sidebar, and add Recents section to `SidebarView` between Favorites and Folders.

**Agent:** smart-worker

**Files to modify:**
- `Kizba/App/AppEnvironment.swift` — add `let recentStore: any RecentEntriesStoring` property; wire `UserDefaultsRecentEntriesStore()` in `live()`, `FakeRecentEntriesStore()` in `preview()` (guarded `#if DEBUG`); add `UnavailableRecentEntriesStore` private struct.
- `Kizba/App/AppState.swift` — no changes expected (recents are not app-state; they're sidebar-model concern).
- `Kizba/Presentation/Features/EntryDetail/EntryDetailModel.swift` — in `apply(_:generation:onlyIfCurrent:)` (line ~396), when `newState` is `.loaded`, call `Task { await environment.recentStore.record(entryPath) }` where `entryPath` is derived from the current selection. Alternative: record in `handleSelectionChange` after successful load completes (line 143, inside the `loadTask` closure, after `self?.apply(.loaded(secret), ...)`).
- `Kizba/Presentation/Features/Sidebar/SidebarView.swift` — add `@State private var recentsModel: RecentsModel`, init from `environment.recentStore`. Add "Recents" `Section` between Favorites and Folders (same row pattern as Favorites).

**Files to create:**
- `Kizba/Presentation/Features/Sidebar/RecentsModel.swift`

**Signatures:**

```swift
// RecentsModel.swift
@Observable
@MainActor
final class RecentsModel {
    private(set) var recents: [String] = []
    private let store: any RecentEntriesStoring

    init(store: any RecentEntriesStoring)
    func load() async
    func stop()
    // Internally: observeChanges task that listens to store.recentsChanged
}
```

**Wiring locations (exact):**
1. `EntryDetailModel.swift` line ~143: after `self?.apply(.loaded(secret), generation: myGeneration)`, add recording call. The entry path is available as `entry.path` (captured in the closure scope at line 134).
2. `SidebarView.swift` line ~58 (after Favorites section closing brace, before `Section("Folders")`): insert Recents section.
3. `AppEnvironment.swift` init parameters: add `recentStore: any RecentEntriesStoring = UserDefaultsRecentEntriesStore()` after `favoritesStore`.

**Tests to add:**
- `KizbaTests/Presentation/Features/Sidebar/RecentsModelTests.swift`
  - `testLoad_populatesRecents`
  - `testLoad_observesChanges`
  - `testStop_cancelsObservation`

**Verification:**
```sh
xcodebuild build -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS'
xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' \
  -only-testing:KizbaTests/Presentation/Features/Sidebar/RecentsModelTests
xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' \
  -only-testing:KizbaTests/SourceGrepTests
rg -n '\bas!\b' Kizba/
rg -n 'Logger.*stdin|print\(.*stdin' Kizba/ KizbaTests/
```

**Branch:** `mvp5/c2-recents-wiring-sidebar`
**Commit:** `feat(recents): wire RecentEntriesStore + RecentsModel + SidebarView section (MVP5.C.2)`

**Difficulty:** medium
**Risks:**
- Existing tests that construct `AppEnvironment` may need the new `recentStore` param — use a default value to avoid churn.
- `EntryDetailModel` tests may need `FakeRecentEntriesStore` in the environment — verify existing tests still pass.

---

### C.3 — Boost favorites and recents in search ranking

**Description:** Extend `EntrySearching` protocol with an optional `SearchContext` parameter carrying favorites and recents sets. Update `LiveSearchEngine` to apply a score boost (+0.05) for favorites and (+0.03) for recents. Add tests.

**Agent:** smart-worker

**Files to modify:**
- `Kizba/Domain/Protocols/EntrySearching.swift` — add `SearchContext` struct and extend `search` signature with default `nil` context.
- `Kizba/Infrastructure/Search/LiveSearchEngine.swift` — accept `SearchContext?`, apply boost in scoring.
- `Kizba/App/AppEnvironment.swift` — update `LiveSearchEngine` init in `live()` and `preview()` if needed (likely no change if context is per-call).
- `Kizba/Presentation/Features/Search/SearchModel.swift` or `Kizba/Presentation/Features/EntryList/EntryListModel.swift` — pass context when calling `search()`.

**Signatures:**

```swift
// EntrySearching.swift
public struct SearchContext: Sendable {
    public let favoritePaths: Set<String>
    public let recentPaths: Set<String>
    public init(favoritePaths: Set<String> = [], recentPaths: Set<String> = [])
}

public protocol EntrySearching: Sendable {
    func search(_ query: String) async throws -> [SearchResult]
    func search(_ query: String, context: SearchContext?) async throws -> [SearchResult]
}

// Default extension: search(_:) delegates to search(_:context: nil)

// LiveSearchEngine — in score(), after base score, add:
//   +0.05 if path in context.favoritePaths
//   +0.03 if path in context.recentPaths
//   (capped at 1.0)
```

**Tests to add:**
- `KizbaTests/Infrastructure/Search/LiveSearchEngineTests.swift`
  - `testSearch_returnsResultsForMatchingQuery`
  - `testSearch_emptyQueryReturnsEmpty`
  - `testSearch_exactMatchScoresHighest`
  - `testSearch_favoriteGetsBoost`
  - `testSearch_recentGetsBoost`
  - `testSearch_favoriteAndRecentBoostStack`
  - `testSearch_boostDoesNotExceedOne`
  - `testSearch_noContextSameAsBefore`

**Verification:**
```sh
xcodebuild build -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS'
xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' \
  -only-testing:KizbaTests/Infrastructure/Search/LiveSearchEngineTests
xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS'
rg -n '\bas!\b' Kizba/
rg -n 'Logger.*stdin|print\(.*stdin' Kizba/ KizbaTests/
```

**Branch:** `mvp5/c3-search-boost-recents-favorites`
**Commit:** `feat(search): boost favorites/recents in search ranking (MVP5.C.3)`

**Difficulty:** medium
**Risks:**
- Changing `EntrySearching` protocol signature affects all conformers (LiveSearchEngine, UnavailableSearchEngine, test fakes in SearchModelSelectionTests, SearchModelUITests). Use default extension to minimize churn.
- Existing search tests must remain green — the default `nil` context preserves old behavior.

---

## Acceptance criteria

1. Build succeeds with no warnings in strict concurrency mode.
2. `UserDefaultsRecentEntriesStoreTests` (7 tests) pass.
3. `RecentsModelTests` (3 tests) pass.
4. `LiveSearchEngineTests` (8 tests) pass.
5. All `SourceGrepTests` pass.
6. Full test suite green, 0 failures.
7. Grep bans clean (no `as!`, no stdin logging).
8. SidebarView shows "Recents" section between Favorites and Folders when recents exist; hidden when empty.
9. Viewing an entry records it in recents.
10. Search results boost favorites and recents.

## Verification commands (final)

```sh
# Build
xcodebuild build -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS'

# Phase C tests
xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' \
  -only-testing:KizbaTests/Infrastructure/Recents/UserDefaultsRecentEntriesStoreTests
xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' \
  -only-testing:KizbaTests/Presentation/Features/Sidebar/RecentsModelTests
xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' \
  -only-testing:KizbaTests/Infrastructure/Search/LiveSearchEngineTests

# SourceGrep
xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' \
  -only-testing:KizbaTests/SourceGrepTests

# Full suite
xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS'

# Grep bans
rg -n '\bas!\b' Kizba/
rg -n 'Logger.*stdin|print\(.*stdin' Kizba/ KizbaTests/
```

## Suggested current step

Run **smart-worker** to implement **Task C.1** (RecentEntriesStoring protocol + UserDefaultsRecentEntriesStore + FakeRecentEntriesStore + tests).

---
---

# MVP5 Phase D — Menu-bar Status Item

## Goal

Add a persistent macOS menu-bar status item (NSStatusItem) hosting a SwiftUI popover for quick search, copy, and recent/favorites access — without opening the main window.

## Constraints

- All constraints from Phase C apply (strict concurrency, no `as!`, no third-party deps, `@Observable` + manual DI, macOS 14+, design-system token policy).
- `NSStatusItem` + `NSPopover` pattern (AppKit host); SwiftUI content via `NSHostingView`.
- Status item visibility controlled by a user setting (`SettingsKeys.showInMenuBar`).
- Menu-bar popover is independent of the main window lifecycle.

---

## Tasks

### D.1 — StatusItemController

**Description:** Create `StatusItemController` that owns the `NSStatusItem` and `NSPopover`, hosts SwiftUI content, and exposes show/hide/toggle API.

**Agent:** smart-worker

**Files to create:**
- `Kizba/Infrastructure/MenuBar/StatusItemController.swift`

**Files to modify:**
- `Kizba/App/KizbaApp.swift` — instantiate `StatusItemController` in app init, call `show()`/`hide()` based on settings.

**Signatures:**

```swift
// StatusItemController.swift
import AppKit
import SwiftUI

@MainActor
final class StatusItemController {
    private var statusItem: NSStatusItem?
    private let popover: NSPopover
    private let environment: AppEnvironment
    private let model: MenuBarModel

    init(environment: AppEnvironment, model: MenuBarModel)

    func show()   // Creates NSStatusItem, configures button, wires popover
    func hide()   // Removes status item from system bar
    func toggle() // Toggles popover visibility
}
```

**Implementation notes:**
- `NSStatusItem` created via `NSStatusBar.system.statusItem(withLength: .squareLength)`.
- Button image: SF Symbol `key.fill` (or custom asset).
- Button action calls `toggle()`.
- `NSPopover` content: `NSHostingView(rootView: MenuBarPopoverView(model: model))`.
- Popover `behavior = .transient` (auto-dismiss on focus loss).
- `show()` is idempotent (no-op if already visible); `hide()` removes item from bar.

**Tests to add:**
- `KizbaTests/Infrastructure/MenuBar/StatusItemControllerTests.swift`
  - `testShow_createsStatusItem`
  - `testHide_removesStatusItem`
  - `testToggle_showsPopoverWhenHidden`
  - `testToggle_hidesPopoverWhenVisible`
  - `testShow_idempotent`

**Verification:**
```sh
xcodebuild build -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS'
xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' \
  -only-testing:KizbaTests/Infrastructure/MenuBar/StatusItemControllerTests
rg -n '\bas!\b' Kizba/
```

**Branch:** `mvp5/d1-status-item-controller`
**Commit:** `feat(menubar): add StatusItemController with NSStatusItem + NSPopover (MVP5.D.1)`

**Difficulty:** medium
**Risks:**
- `NSStatusItem` tests require the app to have a status bar context; tests may need to verify state rather than visual presence. Use property checks (`statusItem != nil`, `popover.isShown`).
- Thread safety: all access is `@MainActor`-isolated — safe.

---

### D.2 — MenuBarPopoverView + MenuBarModel

**Description:** Create the SwiftUI popover view and its backing observable model. The popover shows a search field, results list, and recent/favorites quick-access. Copy action copies password to clipboard.

**Agent:** smart-worker

**Files to create:**
- `Kizba/Presentation/Features/MenuBar/MenuBarPopoverView.swift`
- `Kizba/Presentation/Features/MenuBar/MenuBarModel.swift`

**Files to modify:**
- `Kizba/Infrastructure/MenuBar/StatusItemController.swift` — wire `MenuBarPopoverView` as popover content (if not done in D.1).

**Signatures:**

```swift
// MenuBarModel.swift
import Foundation

@Observable
@MainActor
final class MenuBarModel {
    private let searchEngine: any EntrySearching
    private let recentStore: any RecentEntriesStoring
    private let favoritesStore: any FavoritesStoring
    private let clipboard: any ClipboardServicing
    private let settings: any SettingsStoring

    var query: String = ""
    private(set) var results: [SearchResult] = []
    private(set) var recents: [String] = []
    private(set) var favorites: [String] = []
    private(set) var isCopying: Bool = false

    init(
        searchEngine: any EntrySearching,
        recentStore: any RecentEntriesStoring,
        favoritesStore: any FavoritesStoring,
        clipboard: any ClipboardServicing,
        settings: any SettingsStoring
    )

    func search() async
    func copy(index: Int) async   // Copy password at result index to clipboard
    func copyEntry(path: String) async  // Copy password for a given path
    func loadRecentsAndFavorites() async
}
```

```swift
// MenuBarPopoverView.swift
import SwiftUI

struct MenuBarPopoverView: View {
    @Bindable var model: MenuBarModel
    var body: some View { ... }
    // Layout: TextField for query, List of results with copy button,
    // Sections for Recents and Favorites when query is empty.
    // Frame: width ~320, height ~400.
}
```

**Tests to add:**
- `KizbaTests/Presentation/Features/MenuBar/MenuBarModelTests.swift`
  - `testSearch_populatesResults`
  - `testSearch_emptyQueryClearsResults`
  - `testCopyIndex_copiesToClipboard`
  - `testCopyEntry_copiesToClipboard`
  - `testLoadRecentsAndFavorites_populatesBoth`

**Verification:**
```sh
xcodebuild build -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS'
xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' \
  -only-testing:KizbaTests/Presentation/Features/MenuBar/MenuBarModelTests
xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' \
  -only-testing:KizbaTests/SourceGrepTests
rg -n '\bas!\b' Kizba/
```

**Branch:** `mvp5/d2-menubar-popover-model`
**Commit:** `feat(menubar): add MenuBarPopoverView + MenuBarModel (MVP5.D.2)`

**Difficulty:** medium
**Risks:**
- `passManager.show(entry)` triggers pinentry — the popover must not block. Use existing timeout + cancel pattern from `EntryDetailModel`.
- SourceGrep bans: use design-system tokens in the view (no inline colors/radii/opacity).

---

### D.3 — Settings toggle for menu-bar visibility

**Description:** Add a `showInMenuBar` setting key, persist via `SettingsStoring`, add a toggle in `SettingsView`, and wire it to `StatusItemController.show()/hide()`.

**Agent:** smart-worker

**Files to modify:**
- `Kizba/Domain/Protocols/SettingsStoring.swift` — add `SettingsKeys.showInMenuBar = "showInMenuBar"`.
- `Kizba/Presentation/Features/Settings/SettingsModel.swift` — add `var showInMenuBar: Bool` property, read/write via settings store.
- `Kizba/Presentation/Features/Settings/SettingsView.swift` — add Toggle in General section.
- `Kizba/App/KizbaApp.swift` — observe setting changes, call `statusItemController.show()/hide()` reactively.

**Signatures:**

```swift
// In SettingsKeys:
public nonisolated static let showInMenuBar = "showInMenuBar"
public nonisolated static let defaultShowInMenuBar: Bool = true
```

**Tests to add:**
- `KizbaTests/Presentation/Features/Settings/SettingsModelTests.swift` (extend existing)
  - `testShowInMenuBar_defaultsToTrue`
  - `testShowInMenuBar_persistsChange`
  - `testReset_restoresShowInMenuBarDefault`

**Verification:**
```sh
xcodebuild build -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS'
xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' \
  -only-testing:KizbaTests/Presentation/Features/Settings/SettingsModelTests
rg -n '\bas!\b' Kizba/
rg -n 'showInMenuBar' Kizba/
```

**Branch:** `mvp5/d3-settings-menubar-toggle`
**Commit:** `feat(settings): add showInMenuBar toggle + wire to StatusItemController (MVP5.D.3)`

**Difficulty:** low
**Risks:**
- Existing `SettingsModel` tests may need the new property in assertions — use default value to minimize churn.

---

### D.4 — Global hotkey (OPTIONAL)

**Description:** Register a global keyboard shortcut (e.g. ⌥⌘P) to toggle the menu-bar popover from anywhere. This is optional and may be deferred.

**Agent:** smart-worker

**Files to create (if implemented):**
- `Kizba/Infrastructure/MenuBar/GlobalHotkeyManager.swift`

**Files to modify:**
- `Kizba/Infrastructure/MenuBar/StatusItemController.swift` — integrate hotkey trigger.
- `Kizba/Domain/Protocols/SettingsStoring.swift` — add `SettingsKeys.globalHotkey` if configurable.

**Implementation notes:**
- Use `NSEvent.addGlobalMonitorForEvents(matching: .keyDown)` or `CGEvent` tap.
- `addGlobalMonitorForEvents` requires Accessibility permission (System Preferences > Privacy > Accessibility). App must handle the case where permission is not granted (fail silently, show guidance in Settings).
- Alternative: `MASShortcut`-style Carbon `RegisterEventHotKey` — but that's a third-party pattern. Stick with `NSEvent` monitor.
- Hardened Runtime: no additional entitlements needed for `addGlobalMonitorForEvents`, but Accessibility permission is runtime-granted.

**Tests:** Unit-testable only via mocking `NSEvent` monitor registration (limited value). Prefer manual QA.

**Verification:**
```sh
xcodebuild build -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS'
```

**Branch:** `mvp5/d4-global-hotkey`
**Commit:** `feat(menubar): add global hotkey to toggle popover (MVP5.D.4)`

**Difficulty:** high
**Risks:**
- Accessibility permission UX is poor (system dialog, requires restart sometimes).
- `addGlobalMonitorForEvents` does NOT receive events when the app itself is focused — need `addLocalMonitorForEvents` as well.
- Carbon `RegisterEventHotKey` is deprecated but more reliable; conflicts with system shortcuts possible.
- **Recommendation:** defer to a later MVP unless user demand is clear.

---

## Acceptance criteria

1. Build succeeds with strict concurrency, no warnings.
2. `StatusItemControllerTests` (5 tests) pass.
3. `MenuBarModelTests` (5 tests) pass.
4. `SettingsModelTests` new tests (3 tests) pass.
5. All `SourceGrepTests` pass.
6. Full test suite green.
7. Grep bans clean.
8. Menu-bar icon appears when `showInMenuBar` is true; disappears when false.
9. Clicking icon opens popover with search + recents/favorites.
10. Typing a query shows results; clicking copy copies password.

## Verification commands (final)

```sh
xcodebuild build -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS'
xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' \
  -only-testing:KizbaTests/Infrastructure/MenuBar/StatusItemControllerTests
xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' \
  -only-testing:KizbaTests/Presentation/Features/MenuBar/MenuBarModelTests
xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' \
  -only-testing:KizbaTests/Presentation/Features/Settings/SettingsModelTests
xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' \
  -only-testing:KizbaTests/SourceGrepTests
xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS'
rg -n '\bas!\b' Kizba/
rg -n 'Logger.*stdin|print\(.*stdin' Kizba/ KizbaTests/
```

## Suggested current step (Phase D)

Run **smart-worker** to implement **Task D.1** (StatusItemController).
