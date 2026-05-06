# Kizba — Handoff

## Last completed action

Step **2.3 — DONE** (RootSplitView + SidebarView/SidebarModel).

Implemented the Phase 2 vertical UI slice. `RootSplitView` is a
three-column `NavigationSplitView` (sidebar / entry-list placeholder /
detail placeholder), wired to dependencies via explicit initializer
injection (`AppEnvironment`, `AppState`). `SidebarModel` is an
`@Observable @MainActor` view model that calls
`passManager.listEntries()` and derives a deterministic, sorted list
of top-level folders (`SidebarFolder`). `SidebarView` renders that
list in a `List` and binds row selection to `AppState.selectedFolder`
(new non-secret property). `KizbaApp` now hosts `RootSplitView` wired
to `AppEnvironment.live()`. Total test count: **72 passing** (67 from
prior phases + 5 SidebarModel).

### Coverage added

- **`Kizba/Presentation/Root/RootSplitView.swift`** — three-column
  `NavigationSplitView`; sidebar from `SidebarView`, middle column is
  `EntryListPlaceholderView` (step 2.4 will replace), detail column
  is `EmptyDetailView` (step 2.5 will replace). `@MainActor`,
  `@Bindable` AppState.
- **`Kizba/Presentation/Features/Sidebar/SidebarModel.swift`** —
  `@Observable @MainActor` final class. Holds `[SidebarFolder]`;
  exposes `load()` (async) and a pure `topLevelFolders(from:)` helper.
- **`Kizba/Presentation/Features/Sidebar/SidebarView.swift`** — owns
  its `SidebarModel` via `@State`; renders folders in a `List` with
  `selection: $state.selectedFolder` binding, `Folders` section, task
  modifier triggering `model.load()`.
- **`Kizba/App/AppState.swift`** — added non-secret `selectedFolder:
  String?` property + initializer parameter.
- **`Kizba/App/KizbaApp.swift`** — replaces placeholder `Text("Kizba")`
  with `RootSplitView(environment:state:)`.
- **`KizbaTests/SidebarModelTests.swift`** — 5 tests:
  preview-environment load → `[archive, personal, work]`; pure helper
  determinism; top-level-without-slash skipped; deduplication; initial
  empty state.

### Applied changes

- `Kizba/Presentation/Root/RootSplitView.swift` (new).
- `Kizba/Presentation/Features/Sidebar/SidebarModel.swift` (new).
- `Kizba/Presentation/Features/Sidebar/SidebarView.swift` (new).
- `Kizba/App/AppState.swift` (added `selectedFolder`).
- `Kizba/App/KizbaApp.swift` (host `RootSplitView`).
- `KizbaTests/SidebarModelTests.swift` (new).
- `.ai/build-log.md` — appended step 2.3 verification block.
- `Kizba.xcodeproj/project.pbxproj` — **not modified** (file-system
  synchronized root group).

### Verification (executed on this host)

```
xcodebuild -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' test
# => ** TEST SUCCEEDED **
#    Executed 72 tests, with 0 failures (0 unexpected) in 9.965 (10.025) seconds
```

Build log: `.ai/build-log.md`.

### Commits

- `42c5f83` — `feat(ui): add RootSplitView and SidebarView/SidebarModel`
- `41999d5` — `test(ui): add SidebarModel tests`

### Repo state at completion

- HEAD: `41999d5` (will advance after this handoff/log commit).
- `xcodeproj_created = true`,
  `xcode_instructions_path = .ai/xcode_instructions.md` (no new UI
  steps required this round — synchronized groups).
- `build_log_path = .ai/build-log.md`.

## Next action

Proceed to **Phase 2 — step 2.4** per `.ai/plan.md`
(`EntryListView` / `EntryListModel` with `.searchable`).

## Constraints (must hold from day one)

- No third-party packages.
- No QtPass / GPL pass-client source consulted during implementation.
- No secrets in logs (no stdout logging in `Shell/`/`Pass/`).
- `PassSecret` not Codable, not CustomStringConvertible.
- `PassSecret` lives only in the active `EntryDetailModel`, never in
  `AppState`.
- `PassManaging` MVP-1 surface stays read-only — no write/git methods.
- `MockPassManager` and its fixtures stay behind `#if DEBUG` so the
  release binary ships without them (re-checked in Phase 9.1).
- `AppEnvironment.live()` placeholders fail deterministically — any
  production wiring gap surfaces immediately at first call.
- All chat with user in Russian; all code/comments/docs/commits in
  English.

## Machine-readable summary

See `.ai/last-run.json`.
