# Kizba — Handoff

## Current state

MVP5 Phase A.1 — COMPLETED.
MVP5 Phase A.2 — COMPLETED.
MVP5 Phase A.3 — COMPLETED.
MVP5 Phase A.4 — COMPLETED.

### Shipped in A.2

- Added `SearchModel` (`Kizba/Presentation/Features/Search/SearchModel.swift`) as `@Observable @MainActor` with query updates, task cancellation, optional 200ms debounce, and async search wiring to `EntrySearching`.
- Added `SearchView` (`Kizba/Presentation/Features/Search/SearchView.swift`) with query field, loading state, results list, row selection callback, and basic accessibility labels.
- Extended `AppRouter` (`Kizba/App/AppRouter.swift`) with `isSearchSheetPresented`, `presentSearch()`, and `dismissSearch()`.
- Wired Search sheet in `KizbaApp` (`Kizba/App/KizbaApp.swift`): app-level `SearchModel` is created in `init`, sheet is presented from router flag, result selection updates `selectedEntryID` and dismisses sheet.
- Added `Entry` menu action `Search…` with ⌘K shortcut in `EntryMenuCommands`.
- Added tests in `KizbaTests/SearchModelUITests.swift`:
  - `SearchModelTests.testSearchModel_updatesResultsOnQuery`
  - `SearchModelUITests.testSearchView_selectCallsOnSelect`

## Next action

MVP5 Phase B.1 — COMPLETED.

### Shipped in B.1

- Added `FavoritesStoring` protocol (`Kizba/Domain/Protocols/FavoritesStoring.swift`) with async favorite CRUD APIs and `favoritesChanged` stream.
- Added `UserDefaultsFavoritesStore` actor (`Kizba/Infrastructure/Favorites/UserDefaultsFavoritesStore.swift`) with namespaced persistence key `kizba.favorites`, in-memory `Set<String>` cache, and mutation fan-out stream.
- Added focused tests (`KizbaTests/Infrastructure/Favorites/UserDefaultsFavoritesStoreTests.swift`) for empty state, add/remove/toggle persistence across store instances, and idempotent duplicate add.
- Added optional test fixture `FakeFavoritesStore` (`KizbaTests/Fixtures/FakeFavoritesStore.swift`) implementing `FavoritesStoring` with in-memory state and async change stream.

Next action: MVP5 Phase B.2.

### A.3 task checklist

- [x] Task 1 — Add selection state to SearchModel
- [x] Task 2 — Create SearchOverlayView
- [x] Task 3 — Mount overlay in RootSplitView
- [x] Task 4 — Update KizbaApp (remove sheet, pass searchModel)
- [x] Task 5 — Add SearchModelSelectionTests

### Verification commands (run after all tasks)

```sh
xcodebuild build -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS'
xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' -only-testing:KizbaTests/Presentation/Features/Search/SearchModelSelectionTests
rg -n '\bas!\b' Kizba
rg -n 'Logger.*stdin|print\(.*stdin' Kizba
```

### Commit message

```
feat(search): add search overlay + keyboard-first interactions (MVP5.A.3)
```
