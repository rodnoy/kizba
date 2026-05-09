# Kizba — Handoff

## Current state

**MVP 2 Phase G — COMPLETE.** All write operations end-to-end: edit, in-place regenerate, move/rename, delete. Single-step in-session Undo (~10s window) for delete / move / in-place generate. Toolbar lockout while any write is in flight.

Test suite: 660 tests, 8 skipped, 0 failures (default — `KIZBA_E2E` off). Release build green. All grep bans clean.

Committed phases: A+B+C+D (`ddcce10`), E (`db61d41`), F (`e569e7e`). Phase G uncommitted.

## Phase G summary (closed)

- **G.1 — `ActionHistory` (in-session undo, ~10s)** (601 tests, +18). New `UndoableAction` enum (Sendable; not Codable / not CustomStringConvertible) — same security posture as `PassSecret`. `ActionHistory` `@Observable @MainActor` owned by `AppState`. `record/undoLast/clear` API. 10s default expiry; failed undo also clears pending. `AppState.init` now takes `passManager: any PassManaging`; DEBUG-only convenience `init()` keeps existing tests untouched.
- **G.2 — `EntryFormModel(.edit)` + `EditEntrySheet` + ⌘E + toolbar `✎`** (612 tests, +11). `.edit(originalPath:)` mode loads via `passManager.show`, populates `draft` via `SecretDraft(from:)`. `save()` always uses `force: true` against the original path. Success toast "Changes saved"; selection NOT mutated (user already on the entry). `canEditPath` computed prop disables path field in edit mode. EditEntrySheet copy-and-adapted from NewEntrySheet (no collision banner; adds loading skeleton + load-failure body).
- **G.3 — `InPlaceGenerateSheet` + `RegenerateInPlaceModel` + ⌘⌥G + toolbar 🎲** (621 tests, +9). `PassManaging` extended with `generateInPlace(_:length:includeSymbols:)` (the existing `generate` is commit-new and clobbers metadata; `generateInPlace` maps to `pass generate --in-place` for atomic password rotation). Pre-`show` captures prior secret; CLI runs; `actionHistory.record(.inPlaceGenerate(path:previousSecret:))` + undoable toast. No client-side preview (unlike F.4 — the CLI's output IS the password).
- **G.4 — `MoveEntryModel` + `MoveEntrySheet` + ⌘⇧M + toolbar `↔`** (635 tests, +14). Compact sheet with `FolderPathPicker`; `pathError` includes "same path" rule on top of `EntryPathValidator`. On success: `appState.selectedEntryID` follows the moved entry; `.move(from:to:)` recorded for undo; success toast "Entry moved · Now at \<path>". Collision banner with "Replace" → `forceMove = true; save()`.
- **G.5 — Delete + two-step destructive confirmation + ⌫ + toolbar 🗑** (645 tests, +10). No new sheet — uses C.1's `destructiveConfirmation` modifier. `EntryListModel.deleteEntry(at:)` runs pre-`show` to capture secret (refuses to delete what it can't restore), then `passManager.remove`. On success: clear selection if it was on this path; `.delete(path:secret:)` recorded; undoable toast "Entry deleted". Re-entrancy guard via `deletionState == .idle`.
- **G.6 — Toolbar lockout when any model is `.saving`** (660 tests, +15). `ActiveWriteOp` enum (`.insertNew/.edit/.regenerate/.move/.delete`) + `AppState.activeWriteOps: Set` + `anyWriteInFlight: Bool` + `beginWrite/endWrite`. Every write model wires begin/end around its in-flight state (cancel/dismissal release synchronously; in-flight task uses cancelled flag to skip double-release). All 5 write toolbar buttons + 5 menu items add `anyWriteInFlight` to their disable conditions. Read-side buttons unaffected.

Phase G net: +77 tests across 6 sub-steps.

## Files added in Phase G

Production:
- `Kizba/Domain/Models/UndoableAction.swift` (new — G.1).
- `Kizba/Presentation/Undo/ActionHistory.swift` (new — G.1).
- `Kizba/Presentation/Features/EntryForm/EditEntrySheet.swift` (new — G.2).
- `Kizba/Presentation/Features/EntryDetail/RegenerateInPlaceModel.swift` (new — G.3).
- `Kizba/Presentation/Features/EntryDetail/InPlaceGenerateSheet.swift` (new — G.3).
- `Kizba/Presentation/Features/EntryMove/MoveEntryModel.swift` (new — G.4).
- `Kizba/Presentation/Features/EntryMove/MoveEntrySheet.swift` (new — G.4).
- `Kizba/App/AppState.swift` (modified throughout phases — passManager, ActionHistory, isEditEntrySheetPresented, isRegenerateSheetPresented, isMoveSheetPresented, isDeleteConfirmationPresented, ActiveWriteOp, activeWriteOps, anyWriteInFlight, beginWrite/endWrite).
- `Kizba/App/KizbaApp.swift` (modified — Entry menu items enabled + lockout).
- `Kizba/Domain/Protocols/PassManaging.swift` (modified — `generateInPlace` added).
- `Kizba/Infrastructure/Pass/LivePassManager.swift` (modified — `generateInPlace` impl + `.updated` event).
- `Kizba/Infrastructure/Pass/MockPassManager.swift` (modified — `generateInPlace` preserves metadata for undo testing).
- `Kizba/App/AppEnvironment.swift` (modified — `UnavailablePassManager.generateInPlace`).
- `Kizba/Presentation/Features/EntryForm/EntryFormModel.swift` (modified throughout — `.edit` mode + lockout wiring).
- `Kizba/Presentation/Features/EntryList/EntryListView.swift` (modified — toolbar `↔` + 🗑, sheets, destructive confirmation, lockout).
- `Kizba/Presentation/Features/EntryList/EntryListModel.swift` (modified — `deleteEntry`, `deletionState`, `canDelete`, lockout).
- `Kizba/Presentation/Features/EntryDetail/EntryDetailView.swift` (modified — toolbar `✎` + 🎲, sheets, lockout).

Tests:
- `KizbaTests/UndoableActionTests.swift` (new — 6 methods).
- `KizbaTests/ActionHistoryTests.swift` (new — 12 methods).
- `KizbaTests/EntryFormModelEditTests.swift` (new — 11 methods).
- `KizbaTests/RegenerateInPlaceModelTests.swift` (new — 9 methods).
- `KizbaTests/MoveEntryModelTests.swift` (new — 14 methods).
- `KizbaTests/EntryListDeleteTests.swift` (new — 10 methods).
- `KizbaTests/ConcurrentWriteLockoutTests.swift` (new — 15 methods).
- `KizbaTests/Fixtures/PassManagingTestDefaults.swift` (modified — `generateInPlace` default XCTFail).

## Next step

**Phase H — State reconciliation & cache invariants.** Centralize the per-event reconciliation rules. Currently F.5 wires "ANY change → re-list" + each write model imperatively sets selection. Phase H makes this systematic:

1. H.1 Centralize `StoreChange` consumer in `EntryListModel`:
   - `.inserted(path:)` from create → `appState.selectedEntryID = path` (preference-gated, default on).
   - `.inserted(path:)` from edit → no change (still on same entry).
   - `.updated(path:)` (in-place generate) → no change.
   - `.moved(from:to:)` → if selected was `from`, follow to `to`.
   - `.removed(path:)` → if selected was removed, clear selection.
   - `.bulk` → re-list, preserve selection if surviving.
   `EntryDetailModel` re-fetches on `.updated(currentPath)`; clears on `.removed(currentPath)`.
2. H.2 `EntryListReconciliationTests` + `EntryDetailReconciliationTests` cover all selection rules.
3. H.3 `ConcurrentWriteLockoutTests` already exists from G.6. Verify the centralized model doesn't regress lockout invariants.

DoD for Phase H: all 5 write outcomes have deterministic selection behavior covered by tests; detail auto-refreshes on update; full suite green.

## Verification commands

```sh
xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS'

TEST_RUNNER_KIZBA_E2E=1 xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' \
  -only-testing:KizbaTests/PassWriteIntegrationTests

xcodebuild -scheme Kizba -project Kizba.xcodeproj -configuration Release -destination 'platform=macOS' build

xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' \
  -only-testing:KizbaTests/SourceGrepTests

rg -n '\bas!\b' Kizba
rg -n 'showSettingsWindow' Kizba
find . -name .DS_Store -not -path '*/.git/*'
rg -n 'Logger.*stdin|print\(.*stdin' Kizba
```

## Open follow-ups (non-blocking)

- Untracked `.ai/decisions.md` and `.ai/handoff.md` updates from this Phase G sweep — should be `git add`ed when committing.
- `EntryFormModel` is shared between `.create` and `.edit` modes via a single class. The duplicated `EditEntrySheet` ↔ `NewEntrySheet` view layer is pragmatic; extract a shared `EntryFormBody` if maintenance pain grows.
- `AppState` has accumulated 4 `is*Presented: Bool` flags (NewEntry / EditEntry / Regenerate / Move) + `isDeleteConfirmationPresented`. Consider grouping into a `var presentedSheet: PresentedSheet?` enum if drift continues.
- `RegenerateInPlaceModel` returns a `PassSecret` with EMPTY metadata from `generateInPlace` (by design — avoids second pinentry). Phase H.1's `.updated`-event re-fetch via `EntryDetailModel.show` will naturally repopulate metadata in the detail view.
- `ActiveWriteOp` is `Set<>` rather than `Optional<>`; nothing currently runs two writes concurrently from the UI, but the typed enum is future-proof for batch ops.
- The Phase F.5 race-aware `startObservation` test helper is duplicated across files; consider promoting to `Fixtures/`.

## Constraints (must hold throughout MVP 2)

- Zero third-party Swift Packages.
- No QtPass / GPL pass-client source consulted.
- No secret content in logs (stdin / stdout / clipboard value / metadata values / notes).
- `PassSecret`, `MetadataPair`, `SecretDraft`, `UndoableAction` not Codable, not CustomStringConvertible/DebugStringConvertible.
- All chat with user in Russian; all code/comments/docs/commits in English.
- Inline styling banned in `Kizba/Presentation/**` outside `DesignSystem/` (Phase C.6 grep tests enforce).
- Repo-wide `as!` and `Logger/print`-stdin banned (Phase C.6 grep tests enforce).
