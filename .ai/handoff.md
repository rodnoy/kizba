# Kizba — Handoff

## Current state

MVP5 Phase A.1 — COMPLETED.
MVP5 Phase A.2 — COMPLETED.
MVP5 Phase A.3 — COMPLETED.
MVP5 Phase A.4 — COMPLETED.
MVP5 Phase B.1 — COMPLETED.

### Shipped in B.1

- Added `FavoritesStoring` protocol (`Kizba/Domain/Protocols/FavoritesStoring.swift`) with async favorite CRUD APIs and `favoritesChanged` stream.
- Added `UserDefaultsFavoritesStore` actor (`Kizba/Infrastructure/Favorites/UserDefaultsFavoritesStore.swift`) with namespaced persistence key `kizba.favorites`, in-memory `Set<String>` cache, and mutation fan-out stream.
- Added focused tests (`KizbaTests/Infrastructure/Favorites/UserDefaultsFavoritesStoreTests.swift`) for empty state, add/remove/toggle persistence across store instances, and idempotent duplicate add.
- Added optional test fixture `FakeFavoritesStore` (`KizbaTests/Fixtures/FakeFavoritesStore.swift`) implementing `FavoritesStoring` with in-memory state and async change stream.

## Next action

MVP5 Phase B.2 — READY.

Next action: Run smart-planner to create an executable .ai/plan.md for MVP5 B.2 (favorites wiring → FavoritesModel → SidebarView → tests)

Status: TESTS GREEN — READY to proceed with smart-planner. Marking B.2 as READY.

Hint: reproduce locally with:

  xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' -only-testing:KizbaTests/SourceGrepTests/testNoLiteralSwiftUIColor_inPresentationOutsideDS


### B.2 task checklist

- [ ] Task 1 — Add `favoritesStore` to AppEnvironment + `InMemoryFavoritesStore` (`#if DEBUG`)
- [ ] Task 2 — Create `FavoritesModel` (`@Observable @MainActor`)
- [ ] Task 3 — Add Favorites section to SidebarView
- [ ] Task 4 — Add FavoritesModel unit tests
- [ ] Task 5 — (Optional) SidebarView favorites integration test

### Files to touch

- `Kizba/App/AppEnvironment.swift` (modify — add `favoritesStore` property + wire in factories)
- `Kizba/Infrastructure/Favorites/InMemoryFavoritesStore.swift` (create — `#if DEBUG` in-memory impl for preview)
- `Kizba/Presentation/Features/Sidebar/FavoritesModel.swift` (create)
- `Kizba/Presentation/Features/Sidebar/SidebarView.swift` (modify — add Favorites section)
- `KizbaTests/Presentation/Features/Sidebar/FavoritesModelTests.swift` (create)
- `KizbaTests/Presentation/Features/Sidebar/SidebarViewFavoritesTests.swift` (create, optional)

### Verification commands

```sh
xcodebuild build -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS'
xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' \
  -only-testing:KizbaTests/Presentation/Features/Sidebar/FavoritesModelTests
rg -n '\bas!\b' Kizba/
rg -n 'Logger.*stdin|print\(.*stdin' Kizba/
```

### Commit message

```
feat(favorites): FavoritesModel + sidebar section + AppEnvironment wiring (MVP5.B.2)
```
