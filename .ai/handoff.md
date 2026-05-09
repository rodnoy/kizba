# Kizba — Handoff

## Current state

**MVP 2 Phase E — COMPLETE.** Write infrastructure end-to-end: stdin pipe in `ProcessShellRunner`, full `PassCLI` write surface, `PassErrorMapper` write-time signatures, `LivePassManager` writes + `AsyncStream<StoreChange>` emission, opt-in E2E suite. Test suite: 538 tests, 8 skipped, 0 failures (default). With `KIZBA_E2E=1`: 538 / 0 / 0. Release build green.

MVP 1 (read-only) shipped. MVP 2 phases A (tech debt), B (DS foundation), C (DS components + view migration + grep bans), D (pure model layer for writes) all closed. Phase A+B+C+D committed as one (`ddcce10`); Phase E still uncommitted.

## Phase E summary (closed)

- **E.1+E.2+E.3 — Stdin support** (468 tests, +6 from Phase D's 462). New `ShellInvocation` value type with `Stdin = .none | .data(Data) | .closeImmediately`. `ProcessShellRunner` writes stdin via `Pipe()` in a detached `Task`, concurrent with stdout/stderr drains. Cancellation terminates the child cleanly. **Critical mid-flight fix**: `signal(SIGPIPE, SIG_IGN)` on first runner init prevents host-process kill when child exits early. `Invocation` diagnostic record gained `stdinByteCount: Int?` — count only, never content. `FakeShellRunner` upgraded to capture full `ShellInvocation` (incl. stdin Data) for write-side test assertions.
- **E.4 — `PassErrorMapper` write signatures** (486 tests, +18). New `CommandContext` enum (`.show / .list / .insert / .generate / .remove / .move / .initStore`) disambiguates ambiguous `"is not in the password store"` (mv/rm → `sourceNotFound`; show/init → `invalidGpgId`). Maps for: `entryAlreadyExists`, `recipientNotFound`, `invalidLength`, `invalidGpgId`. Path / email extraction lives in case payloads; sanitized excerpt remains redacted. Existing call sites unchanged via default-nil parameter.
- **E.5 — `PassCLI` writes + `PassManaging` extension** (518 tests, +32). Five `PassCLI` write extension methods (`insert`, `generate`, `generateInPlace`, `remove`, `move`) — exact argv composition + stdin contract per the locked plan. `PassManaging` extended with 4 user-facing methods + `var changes: AsyncStream<StoreChange>`. `MockPassManager` upgraded to mutable actor with multi-subscriber AsyncStream. `PassManagingTestDefaults.swift` fixture provides XCTFail-throwing write defaults so 8 read-only test fakes compile without per-fake updates.
- **E.6 — `LivePassManager` writes + `AsyncStream<StoreChange>`** (531 tests, +13). Wires `PassCLI` writes through `LivePassCLI`. `.inserted` vs `.updated` distinction via pre-call existence check (`scanner.contains(path:in:)` — cache-hit O(1), cache-miss one `FileManager.fileExists`). New `PasswordStoreScanning.contains(...)` protocol method. Multi-subscriber AsyncStream mirrors MockPassManager pattern (actor-stored continuations, `onTermination` cleans up). Ordering: `invalidate` → `emit` so subscribers re-listing in response see post-write state.
- **E.7+E.8 — Fixture audit + opt-in E2E** (538 tests, +7 skipped). `FakePasswordGenerator` audit — already matches needed shape (script + push + allCalls + fallback + length validation). New `PassWriteIntegrationTests.swift` (7 methods, gated by `KIZBA_E2E=1`): insert+show round-trip, force-overwrite, no-pinentry, generate+show, remove+listing+`changes`, move+`changes`, multi-event ordering. **Real-world quirk discovered**: `pass insert` over piped stdin silently overwrites without `-f` (`pass yesno()` returns 0 when stdin is not a TTY). Collision-throws contract verified at unit level via `PassErrorMapperTests` against 1.7.3/1.7.4 stderr fixtures.

Test count: MVP1 baseline 209 → A 216 → B 276 → C 330 → D 462 → E 538 (8 skipped). Net Phase E: +76 tests.

## Side fixes landed during Phase E

- **Sidebar double-selection bug** (user-reported): the previous `.listStyle(.plain)` alone wasn't enough — `List(selection:)` was still injecting per-row system fill. Added `.listRowBackground(Color.clear)` per row + `.scrollContentBackground(.hidden)` on the `List`. Applied symmetrically to `EntryListView` for consistency. `Color.clear` is whitelisted in the existing SourceGrepTests rule.

## Files added in Phase E

Production:
- `Kizba/Domain/Protocols/ShellInvocation.swift` (new value type + Stdin enum).
- `Kizba/Domain/Protocols/ShellCommandRunning.swift` (modified — primary `run(_:)` + compat extension).
- `Kizba/Domain/Protocols/PassManaging.swift` (modified — 4 write methods + `changes`).
- `Kizba/Domain/Protocols/PasswordStoreScanning.swift` (modified — `contains(path:in:)` with default `false`).
- `Kizba/Infrastructure/Shell/ProcessShellRunner.swift` (modified — stdin pipe, SIGPIPE handling).
- `Kizba/Infrastructure/Pass/PassCLI.swift` (modified — `composedEnvironment()` internal).
- `Kizba/Infrastructure/Pass/PassCLI+Write.swift` (new — 5 write methods).
- `Kizba/Infrastructure/Pass/PassErrorMapper.swift` (modified — `CommandContext`, write-time mappings).
- `Kizba/Infrastructure/Pass/MockPassManager.swift` (rewritten — mutable actor, multi-subscriber stream).
- `Kizba/Infrastructure/Pass/LivePassCLI.swift` (modified — 5 write delegating methods).
- `Kizba/Infrastructure/Pass/LivePassManager.swift` (rewritten — write methods + AsyncStream + existence check).
- `Kizba/Infrastructure/Store/PasswordStoreScanner.swift` (modified — `contains(...)` impl).
- `Kizba/Infrastructure/Diagnostics/Invocation.swift` (modified — `stdinByteCount` field).
- `Kizba/App/AppEnvironment.swift` (modified — `UnavailablePassManager` write stubs).

Tests + fixtures:
- `KizbaTests/Fixtures/FakeShellRunner.swift` (modified — captures `ShellInvocation`).
- `KizbaTests/Fixtures/PassManagingTestDefaults.swift` (new — XCTFail write stubs).
- `KizbaTests/ProcessShellRunnerStdinTests.swift` (new — 6 methods).
- `KizbaTests/PassCLIWriteTests.swift` (new — 25 methods).
- `KizbaTests/LivePassManagerWriteTests.swift` (new — 13 methods).
- `KizbaTests/PassWriteIntegrationTests.swift` (new — 7 opt-in E2E methods).
- `KizbaTests/MockPassManagerTests.swift` (extended — +6 write methods).
- `KizbaTests/PassErrorMapperTests.swift` (extended — +18 write signatures).
- `KizbaTests/AppEnvironmentPassCLITests.swift`, `KizbaTests/DomainProtocolsTests.swift` (modified — local stubs adapted to new ShellCommandRunning shape).

## Next step

**Phase F — New Entry feature end-to-end.** First user-visible write feature. Order:

1. F.1 `ToastCenter` (MVP shell): `@Observable @MainActor`, dedup window 1s, default 4s / undoable 10s. Owned by `AppState`; `ToastOverlay` mounted at `RootSplitView` bottom-trailing with `accessibilityNotification(.announcement)`. Tests: post / dedup / auto-dismiss / manual dismiss.
2. F.2 `EntryFormModel` (`.create` mode): `@Observable @MainActor`; states `idle | loadingExisting | editing | saving | saved | failed`; generation-counter; validation (path via `EntryPathValidator`, password via custom rules, metadata via `MetadataValidator`); `save()` cancellable; on dismissal cancel + drop draft. Tests: validation, success, collision (`entryAlreadyExists`), force retry, dismissal cancellation.
3. F.3 `NewEntrySheet`: `FormSection` + `FolderPathPicker` + `SecretRevealField` + `KeyValueEditor` + notes; "Generate password…" sub-sheet button; primary `Save`, secondary `Cancel`. Inline `BannerView(.warning)` on collision with "Overwrite" → `forceOverwrite = true; save()`. Wire ⌘N + `+` toolbar.
4. F.4 `GeneratePasswordSheet`: length stepper (default 25), symbols toggle, preview via `LivePasswordGenerator`, "Use this password" applies to draft.
5. F.5 Selection reconciliation for `insert(new)`: `EntryFormModel` imperatively sets `appState.selectedEntryID = newEntry.id` after success (preference-gated, default on).
6. F.6 Phase F regression sweep — manual + automated.

DoD for Phase F: create-entry flow works end-to-end with real `pass`; ToastCenter posts success toast; collision → banner → overwrite verified; cancellation covered; suite green.

## Verification commands

```sh
# Full suite (must stay green throughout MVP 2)
xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS'

# Opt-in E2E (requires local pass + gpg)
TEST_RUNNER_KIZBA_E2E=1 xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' \
  -only-testing:KizbaTests/PassWriteIntegrationTests

# Release sanity (every phase)
xcodebuild -scheme Kizba -project Kizba.xcodeproj -configuration Release -destination 'platform=macOS' build

# Phase C grep bans (must stay green)
xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' \
  -only-testing:KizbaTests/SourceGrepTests

# Phase A/C acceptance (must stay clean)
rg -n 'as!' Kizba
rg -n 'showSettingsWindow' Kizba
find . -name .DS_Store -not -path '*/.git/*'
rg -n 'Logger.*stdin|print\(.*stdin' Kizba
```

## Open follow-ups (non-blocking)

- Untracked `.ai/context.md`, `.ai/decisions.md`, `.ai/handoff.md`, `.ai/step.md` — should be `git add`ed when committing Phase E.
- The "Toast" seed value type currently lives in `Kizba/Presentation/DesignSystem/Components/ToastOverlay.swift`. Phase F.1 will move it to `Kizba/Presentation/Toast/Toast.swift` and add `ToastCenter`.
- `MetadataPair.String(describing:)` includes the value (default reflection of stored `var`s). Risk surface limited to debugger `po`. Documented since Phase D.
- `PasswordStoreScanning.contains(path:in:)` has a default `false` impl on the protocol — read-only test fakes inherit this and won't break. Real consumers (only `PasswordStoreScanner`) provide a real implementation.
- `pass yesno()` quirk: `pass insert` over a piped stdin silently overwrites regardless of `-f`. Collision-throwing is verified at the unit level via stderr fixtures, not E2E. Document in user-facing docs (Phase I) so users understand: writing to an existing entry from Kizba goes through a confirmation in the UI, not via the CLI's interactive prompt.

## Constraints (must hold throughout MVP 2)

- Zero third-party Swift Packages.
- No QtPass / GPL pass-client source consulted.
- No secret content in logs (stdin / stdout / clipboard value / metadata values / notes).
- `PassSecret`, `MetadataPair`, `SecretDraft` not Codable, not CustomStringConvertible/DebugStringConvertible.
- All chat with user in Russian; all code/comments/docs/commits in English.
- Inline styling banned in `Kizba/Presentation/**` outside `DesignSystem/` (Phase C.6 grep tests enforce).
- Repo-wide `as!` and `Logger/print`-stdin banned (Phase C.6 grep tests enforce).
