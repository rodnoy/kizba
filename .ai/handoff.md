# Kizba — Handoff

## Current state

**MVP 2 Phase F — COMPLETE.** First user-visible write feature: New Entry creation end-to-end. Toast plumbing, form model, sheet UI, password-generator sub-sheet, and entry-list auto-refresh all wired and tested.

Test suite: 583 tests, 8 skipped, 0 failures (default — `KIZBA_E2E` off). With `KIZBA_E2E=1`: 583 / 0 / 0 (locally with `pass` + `gpg`). Release build green. All grep bans clean.

MVP 1 (read-only) shipped. MVP 2 phases A (tech debt + Diagnostics menu), B (DS foundation), C (DS components + view migration + grep bans), D (pure model layer for writes), E (write infrastructure: stdin, PassCLI writes, LivePassManager + AsyncStream, opt-in E2E) all closed and committed (`ddcce10` + `db61d41`). Phase F is uncommitted.

## Phase F summary (closed)

- **F.1 — `ToastCenter` + `ToastOverlay` mounted at root** (552 tests, +14 from Phase E's 538). `Toast` value type moved to its own `Kizba/Presentation/Toast/Toast.swift`. `ToastCenter` is `@Observable @MainActor final class` owned by `AppState`. Dedup window 1s on `(severity, title, message)`. Default durations 4s / 10s actionable. At-most-one visible (pre-emption). VoiceOver announcement on appear. `ToastOverlay` mounted once at `RootSplitView` bottom-trailing.
- **F.2 — `EntryFormModel` (.create) + tests** (566 tests, +14). `@Observable @MainActor`; mode `.create` (today) and `.edit(originalPath:)` (deferred to G.2). State `idle | loadingExisting | editing | saving | saved(path:) | failed(PassError)`. Generation-counter for cancellation safety. Validation via `EntryPathValidator` + `MetadataValidator` + non-empty password (gates `canSave`). `save()` cancels prior, spawns task, on success sets `appState.selectedEntryID` imperatively + posts success toast + resets `forceOverwrite`. On `entryAlreadyExists` → `.failed` + NO toast (form's inline banner). On other errors → `.failed` + error toast. `cancel()` and `handleDismissal()` for in-flight task and draft cleanup.
- **F.3 — `NewEntrySheet` view + ⌘N + toolbar `+`** (566 tests, view-only). `FormSection × 4` (Path, Password, Metadata, Notes) + `KizbaButtonStyle` Save/Cancel + inline `BannerView(.warning)` for collision with "Overwrite" action. `KeyValueEditor.Pair ↔ MetadataPair` bridging via proxy Binding. `isNewEntrySheetPresented` on `AppState` so toolbar `+` AND `Entry → New Entry…` menu both trigger. ⌘N via `EntryMenuCommands`. All inline styling banned — clean.
- **F.4 — `GeneratePasswordSheet` sub-sheet** (576 tests, +10). `PasswordGenerating` injected via `AppEnvironment.passwordGenerator`. `GeneratePasswordModel` (separate from EntryFormModel, sub-sheet-bounded): `length: 25`, `includeSymbols: true`, bounds `8...128`. Live preview via `regenerate()`; `.onChange` triggers re-roll. "Use this password" applies via `onApply` callback (no direct mutation of parent draft).
- **F.5 — Selection reconciliation + auto-refresh on insert** (583 tests, +7). `EntryListModel.observeChanges()` subscribes to `passManager.changes`; ANY `StoreChange` triggers `refresh()`. Per-event reconciliation rules deferred to Phase H. Started via view's `.task { ... }`. Race-aware tests use a `startObservation` helper (5× `Task.yield()` + 20ms sleep) to deal with `MockPassManager`'s actor-detached continuation registration. End-to-end test verifies form → manager → stream → list refresh + selection set + toast.

Phase F net: +45 tests across 5 sub-steps.

## Files added in Phase F

Production:
- `Kizba/Presentation/Toast/Toast.swift` (new — moved from `ToastOverlay.swift`).
- `Kizba/Presentation/Toast/ToastCenter.swift` (new).
- `Kizba/Presentation/Features/EntryForm/EntryFormModel.swift` (new).
- `Kizba/Presentation/Features/EntryForm/NewEntrySheet.swift` (new).
- `Kizba/Presentation/Features/EntryForm/GeneratePasswordModel.swift` (new).
- `Kizba/Presentation/Features/EntryForm/GeneratePasswordSheet.swift` (new).
- `Kizba/Presentation/Features/EntryList/EntryListModel.swift` (modified — `observeChanges`, `stop`).
- `Kizba/Presentation/Features/EntryList/EntryListView.swift` (modified — toolbar `+`, sheet host, observe-changes `.task`).
- `Kizba/Presentation/Root/RootSplitView.swift` (modified — `ToastOverlay` overlay).
- `Kizba/App/AppState.swift` (modified — `toastCenter`, `isNewEntrySheetPresented`).
- `Kizba/App/AppEnvironment.swift` (modified — `passwordGenerator` parameter).
- `Kizba/App/KizbaApp.swift` (modified — `Entry > New Entry…` enabled, ⌘N).
- `Kizba/Presentation/DesignSystem/Components/ToastOverlay.swift` (modified — seed `Toast` removed; `accessibilityNotification` on appear).

Tests:
- `KizbaTests/ToastCenterTests.swift` (new — 14 methods).
- `KizbaTests/EntryFormModelCreateTests.swift` (new — 14 methods, includes a private `ScriptedFailingPassManager` actor for non-recoverable error scenarios).
- `KizbaTests/GeneratePasswordModelTests.swift` (new — 10 methods).
- `KizbaTests/EntryListReconciliationTests.swift` (new — 7 methods, includes `waitUntil` and `startObservation` helpers).
- `KizbaTests/EntryDetailModelTests.swift`, `EntryDetailModelCopyTests.swift`, `EntryDetailModelRefinementTests.swift`, `EntryListModelRefreshTests.swift`, `ErrorPresentationIntegrationTests.swift` (modified — pass `passwordGenerator` parameter to `AppEnvironment` constructions).

## Next step

**Phase G — Edit / In-place Generate / Move / Delete + Undo (`ActionHistory`)**.

1. G.1 `ActionHistory` (in-session undo, ~10s window) — new `@Observable @MainActor` actor-like class. Records last destructive op + reverse function; toast Undo button calls into it.
2. G.2 `EntryFormModel(.edit)` mode + `EditEntrySheet` view. Pre-fetches via `pass.show`; save is `force: true` against `originalPath` (path field disabled). Toolbar `✎` button + ⌘E.
3. G.3 `InPlaceGenerateSheet` (Detail toolbar `🎲`, ⌘⌥G). Length + symbols + Regenerate via `pass.generateInPlace`. Records to `ActionHistory` (re-insert the prior secret) + posts undoable toast (10s).
4. G.4 `MoveEntrySheet` + `MoveEntryModel` (⌘⇧M). Path picker, collision banner with "Replace" → `forceMove = true`. On success records to `ActionHistory` (move back) + undoable toast.
5. G.5 Delete (⌫) — `destructiveConfirmation` (two-step). `EntryListModel.delete(path:)` does pre-`show` for undo body, then `pass.remove`. On success records to `ActionHistory` (re-insert via `pass.insert(force: true)`) + undoable toast.
6. G.6 Toolbar lockout when any model is `.saving`.

DoD for Phase G: edit + in-place generate + move + delete work end-to-end; Undo restores prior state within 10s for delete/move/in-place-generate; toolbar lockout verified; suite green.

## Verification commands

```sh
# Full suite (must stay green throughout MVP 2)
xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS'

# Opt-in E2E (requires local pass + gpg)
TEST_RUNNER_KIZBA_E2E=1 xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' \
  -only-testing:KizbaTests/PassWriteIntegrationTests

# Release sanity (every phase)
xcodebuild -scheme Kizba -project Kizba.xcodeproj -configuration Release -destination 'platform=macOS' build

# All grep bans (must stay green)
xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' \
  -only-testing:KizbaTests/SourceGrepTests

# Repo-wide hygiene
rg -n '\bas!\b' Kizba
rg -n 'showSettingsWindow' Kizba
find . -name .DS_Store -not -path '*/.git/*'
rg -n 'Logger.*stdin|print\(.*stdin' Kizba
```

## Open follow-ups (non-blocking)

- Untracked `.ai/decisions.md`, `.ai/handoff.md` updates from this Phase F sweep — should be `git add`ed when committing.
- `MockPassManager` actor-detached continuation registration race: production-safe but test-flaky without a `startObservation` helper. Consider promoting the helper to `KizbaTests/Fixtures/` if Phase G/H tests need it too.
- `ToastCenter` clock injection deferred — real-clock waits in tests work but make tests slower (~1.2s per dedup-expiry case). Consider `init(clock: any Clock<Duration>)` for Phase H if test runtime grows.
- The `Toast` seed type still ships from `Kizba/Presentation/Toast/Toast.swift`. Phase G's undoable toasts will EXTEND it (toasts may need richer action types — verify whether the existing `BannerView.BannerAction` shape is sufficient or needs an `ActionHistoryRef` wrapper).

## Constraints (must hold throughout MVP 2)

- Zero third-party Swift Packages.
- No QtPass / GPL pass-client source consulted.
- No secret content in logs (stdin / stdout / clipboard value / metadata values / notes).
- `PassSecret`, `MetadataPair`, `SecretDraft` not Codable, not CustomStringConvertible/DebugStringConvertible.
- All chat with user in Russian; all code/comments/docs/commits in English.
- Inline styling banned in `Kizba/Presentation/**` outside `DesignSystem/` (Phase C.6 grep tests enforce).
- Repo-wide `as!` and `Logger/print`-stdin banned (Phase C.6 grep tests enforce).
