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

MVP5 Phase A.6 — COMPLETED.

### Shipped in A.6

- EntryDetailModel: live settings sampling for clipboard delay and copy behavior (EntryDetailModel copy behavior)
- SettingsModel: defaults, bounds, and save behavior for clipboardDelay and gitOperationTimeout
- UserDefaultsSettingsStore: defaults and save semantics for SettingsModel

Next action: MVP5 Phase A.7 per .ai/plan.md.

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
