# Kizba — Handoff

## Current state

**MVP 2 Phase H — COMPLETE.** Centralized per-event `StoreChange` reconciliation. `EntryDetailModel` now subscribes to `pass.changes` and re-fetches / clears on relevant events. Test suite: 676 tests, 8 skipped, 0 failures (default — `KIZBA_E2E` off). Release build green. All grep bans clean.

Committed phases: A+B+C+D (`ddcce10`), E (`db61d41`), F (`e569e7e`), G (`49b6c51`). Phase H uncommitted.

## Phase H summary (closed)

- **H.1+H.2+H.3 — Centralized reconciliation + tests + lockout regression check** (676 tests, +16 from Phase G's 660).
  - **`EntryListModel.handle(_:)`** rewritten with per-event behavior (no longer "ANY change → refresh"):
    - `.inserted` → refresh; selection NOT touched (write model owns it).
    - `.updated` → refresh; selection NOT touched.
    - `.moved(from:to:)` → refresh; if selected was `from` → follow to `to`.
    - `.removed(path:)` → refresh; if selected was `path` → clear.
    - `.bulk` → refresh; clear selection if no longer in entries.
  - **`EntryDetailModel.observeChanges()`** new — re-fetches on `.updated(currentPath)`, clears on `.removed(currentPath)`, re-fetches under new path on `.moved(currentPath, to:)`. `.inserted`/`.bulk` are no-op for detail.
  - **Architectural decision (locked)**: `StoreChange` stays neutral (no UI-origin tags). Insert-vs-edit selection differentiation is imperative from the write model; the centralized reconciler is idempotent / "belt-and-suspenders" against future regressions.
  - **`MockPassManager.emitBulk()`** added (DEBUG-only) for testability of `.bulk` handler. `LivePassManager` doesn't currently emit `.bulk` — reserved for future MVP3 external-change detection (FSEvents).
  - **`ConcurrentWriteLockoutTests`** (15 from G.6) — verified no regression.

Files modified: `EntryListModel.swift`, `EntryDetailModel.swift`, `EntryDetailView.swift`, `MockPassManager.swift`. Tests: `EntryListReconciliationTests.swift` (extended 7 → 14), `EntryDetailReconciliationTests.swift` (new — 9 methods).

## Test count progression

MVP1 baseline 209 → A 216 → B 276 → C 330 → D 462 → E 538 → F 583 → G 660 → **H 676** (8 skipped: 1 D.3 known limitation + 7 PassWriteIntegrationTests when `KIZBA_E2E` off).

## Next step

**Phase I — Polish, a11y, release prep.** Final phase before MVP 2 ships.

1. I.1 Diagnostics menu finalization + full keyboard-shortcut audit (verify all 5 write shortcuts + ⌘R, ⌘⌥D, ⌘, render correctly across menus).
2. I.2 Color-blind icon+color audit. `BannerView` and `ToastView` must map each severity to a fixed SF Symbol (`exclamationmark.triangle`, `info.circle`, `checkmark.circle`, `xmark.octagon`). New `SemanticIconographyTests` asserts non-empty symbol per severity.
3. I.3 Manual a11y audit: VoiceOver navigation, toast announcement, Increase Contrast theme swap, Dynamic Type scaling, keyboard-only operation. Notes in `.ai/a11y-audit.md`.
4. I.4 macOS Sequoia smoke tests: `Process` spawn permissions, clipboard auto-clear behavior. Document gotchas.
5. I.5 `pass` version stderr fixtures parity (1.7.3 + 1.7.4) — `PassErrorMapperTests` and `PassGenerateParserTests` already cover both per E.4 / D.5.
6. I.6 README updates: min `pass` version (1.7.3), MVP 2 scope, MVP 3 deferrals (`pass git`, system UndoManager, Touch ID, menu-bar app, FSEvents, sandboxing, snapshot tests, ScrubbingString), `KIZBA_E2E=1` instructions, no-`ScrubbingString` limitation.
7. I.7 Opt-in E2E green pass — `TEST_RUNNER_KIZBA_E2E=1 xcodebuild test ...`.
8. I.8 Final regression sweep — full suite green; all grep bans pass; warnings-as-errors clean.

DoD for Phase I: a11y manual checks pass; color-blind audit done; Sequoia smoke pass; README updated; opt-in E2E green; full automated suite green.

## Verification commands

```sh
xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS'

TEST_RUNNER_KIZBA_E2E=1 xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' \
  -only-testing:KizbaTests/PassWriteIntegrationTests

xcodebuild -scheme Kizba -project Kizba.xcodeproj -configuration Release -destination 'platform=macOS' build

xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' \
  -only-testing:KizbaTests/SourceGrepTests

# Reconciliation + lockout regression bundle (Phase H + G.6):
xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' \
  -only-testing:KizbaTests/EntryListReconciliationTests \
  -only-testing:KizbaTests/EntryDetailReconciliationTests \
  -only-testing:KizbaTests/ConcurrentWriteLockoutTests

# Repo-wide hygiene
rg -n '\bas!\b' Kizba
rg -n 'showSettingsWindow' Kizba
find . -name .DS_Store -not -path '*/.git/*'
rg -n 'Logger.*stdin|print\(.*stdin' Kizba
```

## Open follow-ups (non-blocking)

- Untracked `.ai/decisions.md` and `.ai/handoff.md` updates from this Phase H sweep — should be `git add`ed when committing.
- Phase F.5's `startObservation` + `waitUntil` test helpers are now duplicated in BOTH reconciliation test files. Phase I (or earlier) should promote them to `KizbaTests/Fixtures/AsyncTestHelpers.swift`.
- `LivePassManager` doesn't emit `.bulk` today — `MockPassManager.emitBulk()` is the only producer. MVP3's FSEvents wiring will give `.bulk` a real source.
- `EntryDetailModel.handle(_:)` is synchronous (delegates to existing `handleSelectionChange` which spawns its own task). Pattern matches the existing model; if Phase I introduces snapshot tests that assert on transient state, this may need revisiting.
- The `AppState` accumulated `is*Presented` flags (`isNewEntrySheetPresented`, `isEditEntrySheetPresented`, `isRegenerateSheetPresented`, `isMoveSheetPresented`, `isDeleteConfirmationPresented`) plus `selectedEntryID`, `searchQuery`, `isSidebarCollapsed`, `currentEntries`, `selectedFolder`, `toastCenter`, `actionHistory`, `activeWriteOps`. Phase I might consider extracting an `AppRouter` for the presentation flags.

## Constraints (must hold throughout MVP 2)

- Zero third-party Swift Packages.
- No QtPass / GPL pass-client source consulted.
- No secret content in logs (stdin / stdout / clipboard value / metadata values / notes).
- `PassSecret`, `MetadataPair`, `SecretDraft`, `UndoableAction` not Codable, not CustomStringConvertible/DebugStringConvertible.
- All chat with user in Russian; all code/comments/docs/commits in English.
- Inline styling banned in `Kizba/Presentation/**` outside `DesignSystem/` (Phase C.6 grep tests enforce).
- Repo-wide `as!` and `Logger/print`-stdin banned (Phase C.6 grep tests enforce).
