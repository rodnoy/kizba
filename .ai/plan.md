# MVP 5 — Search, Favorites & Quick Access

## Goal

Ship global quick-search (⌘F / ⌘K), favorites (⭐), recently-used entries, and a menu-bar status-item mode for fast password access without switching to the main window.

## Total effort estimate

~5–7 working days (40–56 hours).

## Durable constraints (from decisions.md)

- No third-party packages. Foundation / SwiftUI / AppKit / os only.
- SWIFT_STRICT_CONCURRENCY = complete. Warnings as errors.
- No `as!` in Sources/ (SourceGrepTests enforced).
- No stdout/stdin logging (`Logger.*stdin|print\(.*stdin` ban).
- `PassSecret` / `SecretDraft` / `MetadataPair` NOT Codable / NOT CustomStringConvertible.
- Manual DI via initializers. `@Observable` for models.
- All code/comments/commits in English.
- macOS 14.0 deployment target. Swift 5.10.

## DoD checklist (every phase)

- [ ] `xcodebuild build -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS'`
- [ ] `xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS'`
- [ ] `xcodebuild build -scheme Kizba -project Kizba.xcodeproj -configuration Release -destination 'platform=macOS'`
- [ ] `rg -n '\bas!\b' Kizba` → 0 matches
- [ ] `rg -n 'Logger.*stdin|print\(.*stdin' Kizba KizbaTests` → 0 matches
- [ ] No raw `print()` / `stdout` leaks in new code

---

## Phase A — Search infrastructure + UI (est. 1.5 days)

**Purpose:** Add in-memory fuzzy search over entry paths with a command-palette-style overlay (⌘K).

**Dependencies:** None (first phase).

### A.1 — SearchEngine domain service

- **Objective:** Pure, testable search over `[PassEntry]` by path substring (case-insensitive). Returns ranked results.
- **Files to create:**
  - `Kizba/Domain/Protocols/EntrySearching.swift` — protocol `EntrySearching` with `func search(query: String, in entries: [PassEntry]) -> [SearchResult]`
  - `Kizba/Domain/Models/SearchResult.swift` — `struct SearchResult: Sendable, Equatable, Identifiable` with `entry: PassEntry`, `score: Double`, `matchRanges: [Range<String.Index>]`
  - `Kizba/Infrastructure/Search/LiveSearchEngine.swift` — impl using `String.localizedStandardContains` + scoring by match position/length
- **Files to modify:**
  - `Kizba.xcodeproj/project.pbxproj` — add 3 new files
- **Tests to add:**
  - `KizbaTests/Infrastructure/Search/LiveSearchEngineTests.swift` (~12 tests): empty query returns all, exact match scores highest, substring match, case insensitivity, no results for gibberish, special characters, path component matching, ranking order
- **Verification:** build + tests green

### A.2 — SearchModel (presentation model)

- **Objective:** `@Observable @MainActor` model driving the search overlay. Debounced query (150ms), calls `EntrySearching`, exposes `results: [SearchResult]` and `selectedResultIndex: Int?`.
- **Files to create:**
  - `Kizba/Presentation/Features/Search/SearchModel.swift`
- **Files to modify:**
  - `Kizba.xcodeproj/project.pbxproj`
- **Tests to add:**
  - `KizbaTests/Presentation/Features/Search/SearchModelTests.swift` (~8 tests): initial state empty, query updates results, debounce behavior, clear resets, selection navigation (up/down/enter), empty query clears results
- **Verification:** build + tests green

### A.3 — SearchOverlayView (⌘K command palette)

- **Objective:** Floating overlay with text field + results list. ⌘K toggles. Enter selects entry (sets `appState.router.selectedEntryID`). Escape dismisses.
- **Files to create:**
  - `Kizba/Presentation/Features/Search/SearchOverlayView.swift`
- **Files to modify:**
  - `Kizba/App/AppRouter.swift` — add `isSearchOverlayPresented: Bool`, `presentSearch()`, `dismissSearch()`
  - `Kizba/Presentation/Root/RootSplitView.swift` — mount overlay
  - `Kizba/App/KizbaApp.swift` — add ⌘K keyboard shortcut in Commands
  - `Kizba.xcodeproj/project.pbxproj`
- **Tests:** Manual smoke (view layer). SearchModel tests cover logic.
- **Verification:** build green; ⌘K opens overlay in running app

### A.4 — Wire search into existing ⌘F sidebar filter

- **Objective:** Replace or augment the existing `searchQuery` on `AppState` to use `LiveSearchEngine` for the sidebar/entry-list filter too.
- **Files to modify:**
  - `Kizba/Presentation/Features/EntryList/EntryListModel.swift` — use `EntrySearching` for filtering when query non-empty
  - `Kizba/App/AppEnvironment.swift` — add `searchEngine: any EntrySearching`
- **Verification:** build + tests green; existing entry-list filter tests still pass

---

## Phase B — Favorites (est. 1.5 days)

**Purpose:** Let users star entries; persist favorites in UserDefaults; show a "Favorites" section at the top of the sidebar.

**Dependencies:** Phase A (search results can include favorite status).

### B.1 — FavoritesStore domain + persistence

- **Objective:** Protocol + UserDefaults-backed store for a `Set<String>` of favorited entry paths.
- **Files to create:**
  - `Kizba/Domain/Protocols/FavoritesStoring.swift` — `protocol FavoritesStoring: Sendable` with `func isFavorite(_: String) -> Bool`, `func toggleFavorite(_: String)`, `func allFavorites() -> Set<String>`, `var favoritesChanged: AsyncStream<Void>`
  - `Kizba/Infrastructure/Favorites/UserDefaultsFavoritesStore.swift` — impl using `UserDefaults.standard`, key `"kizba.favorites"`
- **Files to modify:**
  - `Kizba.xcodeproj/project.pbxproj`
- **Tests to add:**
  - `KizbaTests/Infrastructure/Favorites/UserDefaultsFavoritesStoreTests.swift` (~8 tests): add/remove/toggle, persistence across instances, empty initial state, duplicate add idempotent
  - `KizbaTests/Fixtures/FakeFavoritesStore.swift`
- **Verification:** build + tests green

### B.2 — FavoritesModel + sidebar section

- **Objective:** `@Observable @MainActor` model. Sidebar shows "★ Favorites" section above folders when non-empty.
- **Files to create:**
  - `Kizba/Presentation/Features/Sidebar/FavoritesModel.swift`
- **Files to modify:**
  - `Kizba/Presentation/Features/Sidebar/SidebarView.swift` — add favorites section
  - `Kizba/App/AppState.swift` — own `FavoritesModel`
  - `Kizba/App/AppEnvironment.swift` — add `favoritesStore: any FavoritesStoring`
  - `Kizba.xcodeproj/project.pbxproj`
- **Tests to add:**
  - `KizbaTests/Presentation/Features/Sidebar/FavoritesModelTests.swift` (~6 tests)
- **Verification:** build + tests green

### B.3 — Toggle favorite action in entry detail + context menu

- **Objective:** Star button in entry detail toolbar + right-click context menu on entry rows.
- **Files to modify:**
  - `Kizba/Presentation/Features/EntryDetail/EntryDetailView.swift` — add ⭐ toolbar button
  - `Kizba/Presentation/Features/EntryList/EntryRowView.swift` — context menu "Add to Favorites" / "Remove from Favorites"
  - `Kizba/App/KizbaApp.swift` — Entry menu: "Toggle Favorite" (⌘D)
- **Verification:** build green; manual smoke

### B.4 — Favorites cleanup on entry delete/move

- **Objective:** When an entry is deleted or moved, update favorites set accordingly.
- **Files to modify:**
  - `Kizba/Presentation/Features/EntryList/EntryListModel.swift` — on `.removed` event, remove from favorites; on `.moved`, update path
- **Tests to add:**
  - Add 2 tests to `EntryListReconciliationTests` — favorite cleaned on delete, favorite path updated on move
- **Verification:** build + tests green

---

## Phase C — Recently Used (est. 1 day)

**Purpose:** Track last-accessed entries; show "Recent" section in sidebar and in search results ranking.

**Dependencies:** Phase B (sidebar section pattern established).

### C.1 — RecentEntriesStore

- **Objective:** Protocol + UserDefaults impl. Stores last N (default 10) entry paths with timestamps. FIFO eviction.
- **Files to create:**
  - `Kizba/Domain/Protocols/RecentEntriesStoring.swift`
  - `Kizba/Infrastructure/Recents/UserDefaultsRecentEntriesStore.swift`
- **Files to modify:**
  - `Kizba.xcodeproj/project.pbxproj`
- **Tests to add:**
  - `KizbaTests/Infrastructure/Recents/UserDefaultsRecentEntriesStoreTests.swift` (~8 tests): record, eviction at capacity, duplicate bumps to front, clear, persistence
  - `KizbaTests/Fixtures/FakeRecentEntriesStore.swift`
- **Verification:** build + tests green

### C.2 — Wire recents into EntryDetailModel + sidebar

- **Objective:** Record access on successful `show()`. Show "Recent" section in sidebar below favorites.
- **Files to modify:**
  - `Kizba/Presentation/Features/EntryDetail/EntryDetailModel.swift` — call `recentStore.record(path)` on successful show
  - `Kizba/Presentation/Features/Sidebar/SidebarView.swift` — add "Recent" section
  - `Kizba/App/AppEnvironment.swift` — add `recentEntriesStore`
  - `Kizba/App/AppState.swift` — expose recents
- **Tests to add:**
  - 2 tests in `EntryDetailModelTests` — show records recent, failed show does not record
- **Verification:** build + tests green

### C.3 — Boost recents + favorites in search ranking

- **Objective:** `LiveSearchEngine` accepts optional favorites set + recents list; boosts score for matches.
- **Files to modify:**
  - `Kizba/Domain/Protocols/EntrySearching.swift` — add optional context param
  - `Kizba/Infrastructure/Search/LiveSearchEngine.swift` — boost logic
- **Tests to add:**
  - 3 tests in `LiveSearchEngineTests` — favorite boosted, recent boosted, both boosted
- **Verification:** build + tests green

---

## Phase D — Menu-bar status item (est. 1.5 days)

**Purpose:** Add an optional menu-bar icon that shows a popover with search + recent entries for quick copy-password without opening the main window.

**Dependencies:** Phases A, B, C (search + favorites + recents).

**Risks:** `NSStatusItem` + SwiftUI popover is tricky on macOS 14. Mitigation: use `NSHostingView` in `NSPopover` attached to status item; keep the popover simple (search field + list).

### D.1 — StatusItemController (AppKit bridge)

- **Objective:** `@MainActor final class` managing `NSStatusItem` lifecycle. Creates/removes status item based on Settings toggle.
- **Files to create:**
  - `Kizba/Infrastructure/StatusItem/StatusItemController.swift` — owns `NSStatusItem`, `NSPopover`, hosts SwiftUI view
- **Files to modify:**
  - `Kizba/App/AppEnvironment.swift` — add `statusItemController`
  - `Kizba/App/KizbaApp.swift` — wire lifecycle
  - `Kizba.xcodeproj/project.pbxproj`
- **Tests:** Limited (AppKit integration). Manual smoke.
- **Verification:** build green

### D.2 — MenuBarPopoverView

- **Objective:** Compact SwiftUI view: search field + recent entries list + favorites. Tap entry → copy password to clipboard (via existing `ClipboardServicing`) + auto-clear.
- **Files to create:**
  - `Kizba/Presentation/Features/MenuBar/MenuBarPopoverView.swift`
  - `Kizba/Presentation/Features/MenuBar/MenuBarModel.swift` — `@Observable @MainActor`, owns search + copy logic
- **Files to modify:**
  - `Kizba.xcodeproj/project.pbxproj`
- **Tests to add:**
  - `KizbaTests/Presentation/Features/MenuBar/MenuBarModelTests.swift` (~6 tests): search, select+copy, empty state
- **Verification:** build + tests green

### D.3 — Settings toggle for menu-bar mode

- **Objective:** "Show in menu bar" toggle in Settings. Persisted via `SettingsStoring`. Controls `StatusItemController` visibility.
- **Files to modify:**
  - `Kizba/Infrastructure/Settings/UserDefaultsSettingsStore.swift` — add `showInMenuBar: Bool` key
  - `Kizba/Presentation/Features/Settings/SettingsView.swift` — add toggle
  - `Kizba/Domain/Protocols/SettingsStoring.swift` — add property
- **Tests to add:**
  - 2 tests in settings store tests — default false, toggle persists
- **Verification:** build + tests green

### D.4 — Global hotkey (optional, lower priority)

- **Objective:** Optional global keyboard shortcut (e.g., ⌃⌥P) to show/hide the menu-bar popover. Uses `NSEvent.addGlobalMonitorForEvents`.
- **Files to modify:**
  - `Kizba/Infrastructure/StatusItem/StatusItemController.swift` — add global monitor
  - Settings UI — hotkey picker (stretch goal; can be hardcoded for MVP 5)
- **Risks:** Global hotkey conflicts. Mitigation: make it configurable or off by default.
- **Verification:** build green; manual test

---

## Phase E — Polish, docs & regression (est. 0.5 days)

**Purpose:** Final sweep, README update, decisions log, grep bans, full test suite.

**Dependencies:** All prior phases.

### E.1 — SourceGrepTests extensions

- **Objective:** Add grep rules for new domain types (`SearchResult` not Codable if it carries entry data).
- **Files to modify:**
  - `KizbaTests/SourceGrepTests.swift`
- **Verification:** `rg -n '\bas!\b' Kizba` → 0; all SourceGrepTests green

### E.2 — README + decisions.md + handoff.md update

- **Objective:** Document MVP 5 features, update project structure, append decisions entry.
- **Files to modify:**
  - `README.md`
  - `.ai/decisions.md`
  - `.ai/handoff.md`
  - `.ai/sequoia-smoke.md` — add menu-bar rows
  - `.ai/a11y-audit.md` — add search overlay + menu-bar a11y checklist
- **Verification:** docs updated; grep for new feature names

### E.3 — Final regression sweep

- **Commands:**
  ```sh
  xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS'
  xcodebuild build -scheme Kizba -project Kizba.xcodeproj -configuration Release -destination 'platform=macOS'
  rg -n '\bas!\b' Kizba
  rg -n 'Logger.*stdin|print\(.*stdin' Kizba KizbaTests
  ```
- **Verification:** 0 failures, 0 grep ban violations

---

## Risk mitigation & sequencing

1. **Land Phase A first.** Search is self-contained and unblocks B, C, D.
2. **Phase B before C.** Favorites pattern establishes the sidebar-section template that recents reuses.
3. **Phase D is highest risk** (AppKit bridge). If it slips, Phases A–C are independently shippable as MVP 5a.
4. **D.4 (global hotkey) is optional.** Mark as stretch goal; can ship without it.
5. **No new `PassManaging` methods needed.** All features compose over existing `show()` + `listEntries()`.

---

## First actionable work item (delegate now)

**Task:** Implement Phase A.1 — SearchEngine domain service.

**Files to create:**
- `Kizba/Domain/Protocols/EntrySearching.swift`
- `Kizba/Domain/Models/SearchResult.swift`
- `Kizba/Infrastructure/Search/LiveSearchEngine.swift`
- `KizbaTests/Infrastructure/Search/LiveSearchEngineTests.swift`

**Files to modify:**
- `Kizba.xcodeproj/project.pbxproj` (add 4 files)

**Description:**
1. Define `EntrySearching` protocol with `func search(query: String, in entries: [PassEntry]) -> [SearchResult]`.
2. Define `SearchResult` as `struct SearchResult: Sendable, Equatable, Identifiable` with `let id = UUID()`, `let entry: PassEntry`, `let score: Double`, `let matchRanges: [Range<String.Index>]`.
3. Implement `LiveSearchEngine: EntrySearching` using `String.localizedStandardContains` for matching. Score: exact match = 1.0, prefix match = 0.8, contains = 0.5. Sort descending by score, then alphabetically.
4. Write ~12 tests covering: empty query → returns all entries (score 1.0), exact path match, prefix match, substring match, case insensitivity, no results, special characters in query, path component matching, result ordering by score, empty entries array.
5. Add all 4 files to `project.pbxproj`.

**Acceptance criteria:**
- Build succeeds
- All new tests pass
- No `as!` in new code
- `SearchResult` is NOT Codable, NOT CustomStringConvertible
- Protocol is `Sendable`-safe

**Verification commands:**
```sh
xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS'
xcodebuild build -scheme Kizba -project Kizba.xcodeproj -configuration Release -destination 'platform=macOS'
rg -n '\bas!\b' Kizba
rg -n 'Logger.*stdin|print\(.*stdin' Kizba KizbaTests
```

---

## Handoff next-action

Delegate to smart-worker: implement MVP5 Phase A.1 — SearchEngine domain service (EntrySearching protocol + LiveSearchEngine + SearchResult + tests)
