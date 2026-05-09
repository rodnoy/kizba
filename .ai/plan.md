# Kizba — MVP 2 Implementation Plan

Native macOS SwiftUI client for the Unix `pass` password manager. MVP 1 (read-only) shipped, 209 tests green. MVP 2 = write operations (create / edit / generate / move / delete) + custom pastel design system + tech-debt cleanup.

## Goals & Non-goals

**Goals (MVP 2)**
- Write operations on top of `pass`: create, edit, in-place regenerate, move/rename, delete — all via subprocess `pass`.
- Custom theme-driven design system (pastel palette: #cdb4db / #ffc8dd / #ffafcc / #bde0fe / #a2d2ff) with semantic tokens, light/dark/highContrast, AA contrast, color-blind safety.
- Migrate all MVP 1 views off vanilla SwiftUI onto the new design system; ban inline styling via `SourceGrepTests`.
- Close all 10 MVP 1 tech-debt items in one upfront phase.
- Robust write-side concurrency: `AsyncStream<StoreChange>` from `LivePassManager` drives selection reconciliation.
- In-session Undo (~10s window) for destructive ops via custom `ActionHistory` + Toast Undo button.
- Lock minimum supported `pass` version (1.7.3); fixture corpus for 1.7.3 + 1.7.4 stderr.

**Non-goals (deferred to MVP 3+)**
- `pass git ...` integration (status / sync / push / pull).
- System `UndoManager` (only in-session custom `ActionHistory`).
- Touch ID / LocalAuthentication.
- Menu-bar (status item) app surface.
- Quick-search / Spotlight indexing.
- FSEvents-based external-change detection.
- App Sandbox / hardened-runtime tightening.
- Snapshot tests for design system or views.
- `ScrubbingString` secure-string buffer (in-memory secrets remain plain `String`/`Data`; documented limitation).
- Any third-party Swift Package.

## Baseline (unchanged from MVP 1)

- Swift 5.10, Xcode 15.4+, macOS deployment target 14.0.
- `SWIFT_STRICT_CONCURRENCY = complete`, warnings-as-errors.
- `.xcodeproj` committed; zero third-party dependencies.
- Non-sandboxed; Developer ID + notarization; Hardened Runtime + `cs.disable-library-validation`.

## Brand palette → semantic tokens

### Light mode
- `surface` = `#FBF7FB`; `surfaceElevated` = `#FFFFFF`; `surfaceSunken` = `#F2EAF1`; `surfaceHover` = `#cdb4db @ 0.14`; `surfaceSelected` = `#bde0fe @ 0.45`.
- `onSurface` = `#1F1B2E` (AAA on surface); `onSurfaceMuted` = `#4A445E`; `onSurfaceFaint` = `#8A839E`.
- `accent` = `#7C5BC4` (deepened from `#cdb4db`, AA on white); `accentMuted` = `#cdb4db @ 0.28`; `onAccent` = `#FFFFFF`.
- `danger` = `#C2185B` (deepened pink for contrast); `dangerMuted` = `#ffc8dd @ 0.45`; `onDanger` = `#FFFFFF`.
- `success` = `#2E7D5B` (extended green, color-blind safe); `successMuted` = `#bde0fe @ 0.30`; `onSuccess` = `#FFFFFF`.
- `warning` = `#9A5A00` (extended amber); `warningMuted` = `#ffc8dd @ 0.35`; `onWarning` = `#FFFFFF`.
- `focusRing` = `#a2d2ff` outline + accent core.
- `divider` = `#1F1B2E @ 0.08`; `scrim` = `#1F1B2E @ 0.45`; `secretMask` = `#bde0fe @ 0.22`.

### Dark mode
- `surface` = `#15121C`; `surfaceElevated` = `#1E1A2A`; `surfaceSunken` = `#0F0D16`; `surfaceHover` = `#cdb4db @ 0.10`; `surfaceSelected` = `#a2d2ff @ 0.18`.
- `onSurface` = `#F4EFF7`; `onSurfaceMuted` = `#B8B0C8`; `onSurfaceFaint` = `#7B7390`.
- `accent` = `#cdb4db`; `accentMuted` = `#cdb4db @ 0.22`; `onAccent` = `#1F1B2E`.
- `danger` = `#ffafcc`; `dangerMuted` = `#ffafcc @ 0.18`; `onDanger` = `#1F1B2E`.
- `success` = `#7CD9A8`; `successMuted` = `#bde0fe @ 0.18`; `onSuccess` = `#0E1F18`.
- `warning` = `#FFB870`; `warningMuted` = `#ffc8dd @ 0.18`.
- `focusRing` / `divider` / `scrim` / `secretMask` per spec.

### Other tokens
- Spacing: `xs(4) / sm(8) / md(12) / lg(16) / xl(24) / xxl(32)`.
- Radius: `sm(6) / md(10) / lg(14) / pill(999)`.
- Typography: `display / title / headline / body / bodyEmphasized / callout / caption / mono / monoSmall`.
- Motion: `instant(0s) / quick(0.12s) / standard(0.2s) / emphasized(0.32s)`. Honors `accessibilityReduceMotion` (collapses to `instant`).

## Phases

Order locked: A → B → C → D → E → F → G → H → I.

### Phase A — MVP 1 tech debt + Diagnostics menu
- [ ] A.1 Repo hygiene: remove tracked `.DS_Store` files and `.ai/build-output.txt`; update `.gitignore`. Verify `find . -name .DS_Store -not -path './.git/*'` empty; `xcodebuild build` green.
- [ ] A.2 Consolidate test fakes into `KizbaTests/Fixtures/` — `FakeShellRunner`, `FakeClipboard`, `FakeFileExistenceChecker`. Remove duplicates from individual test files. Verify `rg 'class Fake(ShellRunner|Clipboard|FileExistenceChecker)' KizbaTests` shows one definition each.
- [ ] A.3 Tighten `SettingsStoring`: remove protocol-extension defaults (`removeValue`/`resetAll`/`registerDefaults`). Replace `as!` in `UserDefaultsSettingsStore` with `as?` + `assertionFailure` + safe default. Verify `rg 'as!' Kizba/Infrastructure/Settings` returns 0.
- [ ] A.4 Share `BinaryDiscoveryService` between `LivePassManager` and Settings; `redetect()` invalidates cached binary path used by `LivePassCLI`. Manual: change pass path in Settings → Diagnostics shows new path without restart.
- [ ] A.5 `LivePassManager` honors `SettingsKeys.storePathOverride` — exports `PASSWORD_STORE_DIR` env on every shell call when set. Add `LivePassManagerStoreOverrideTests`.
- [ ] A.6 `EntryDetailModel.copy(...)` reads `SettingsStoring.clipboardClearDelaySeconds`; remove hardcoded `clearAfterSeconds: Int = 30`. Inject `SettingsStoring` via `AppEnvironment`.
- [ ] A.7 Replace `NSApp.sendAction(Selector(("showSettingsWindow:")))` with `SettingsLink`. Verify `rg showSettingsWindow Kizba` returns 0.
- [ ] A.8 Add `Window > Diagnostics…` menu item with `⌘⌥D` shortcut.
- [ ] A.9 Regression sweep: full test suite green, ≥ 209 tests.

**DoD:** all 10 debt items closed; Diagnostics menu present; full suite green.

### Phase B — Design system foundation
- [ ] B.1 `Theme` value type + token namespaces (`ColorTokens`, `SpacingTokens`, `RadiusTokens`, `TypographyTokens`, `MotionTokens`); light + dark + highContrast variants as code constants.
- [ ] B.2 `EnvironmentValues.theme` + `ThemedRoot` wrapper observing `colorScheme` + `colorSchemeContrast`. Wire into `KizbaApp`.
- [ ] B.3 `ContrastChecker` test helper (WCAG luminance + ratio); `ThemeTokenTests` asserting non-nil tokens, AA body contrast, AAA on-surface, focus-ring contrast, theme equality.
- [ ] B.4 Atom components: `KizbaCard`, `KizbaButtonStyle (.primary/.secondary/.destructive/.ghost)`, `KizbaTextFieldStyle`.
- [ ] B.5 Atom tests: `KizbaButtonStyleTests`, `KizbaCardTests`.

**DoD:** Theme injected through `\.theme`; light/dark/highContrast compile and pass contrast tests; atoms exist; existing views untouched; suite green.

### Phase C — Migrate MVP 1 views to design system + grep bans
- [ ] C.1 Downstream DS components (presentational shells): `BannerView`, `ToastView`, `ToastOverlay`, `EmptyStateView`, `LoadingShimmer`, `SecretRevealField`, `FormSection`, `FormFieldRow`, `KeyValueEditor`, `FolderPathPicker`, `EntryRowView`. Modifiers: `DestructiveConfirmation`, `OverwriteConfirmation`.
- [ ] C.2 Component tests: `BannerViewTests`, `EmptyStateViewTests`, `SecretRevealFieldTests`, `DestructiveConfirmationTests`.
- [ ] C.3 Migrate `EntryListView`, `EntryRowView`, `RootSplitView` to `theme.*` tokens.
- [ ] C.4 Migrate `EntryDetailView`, Settings, Diagnostics, Onboarding views.
- [ ] C.5 Toolbar / menu / shortcut audit (read-side only); add `Entry` menu placeholder with disabled write actions.
- [ ] C.6 `SourceGrepTests` bans inside `Kizba/Presentation/**/*.swift` excluding `Kizba/Presentation/DesignSystem/**`:
  - `\.padding\(\s*\d` (numeric padding).
  - `\bColor\.[a-zA-Z]+` (literal SwiftUI color).
  - `\.foregroundColor\(\.[a-zA-Z]+\)`, `\.foregroundStyle\(\.[a-zA-Z]+\)`.
  - `\.font\(\.[a-zA-Z]+\)`.
  - `\.cornerRadius\(\s*\d`, `RoundedRectangle\(cornerRadius:\s*\d`.
  - `\.opacity\(\s*0\.\d`.
  - `\.animation\(\.[a-zA-Z]+`.
  - Plus repo-wide bans: `Logger.*stdin`, `print\(.*stdin`, `\bas!\b`.

**DoD:** all `Kizba/Presentation/**` (outside DS) on tokens; all bans pass; suite green.

### Phase D — Pure model layer
- [ ] D.1 `MetadataPair` + `SecretDraft` (final class; not Sendable, not Codable, not CustomStringConvertible/DebugStringConvertible). `snapshot()` returns immutable `PassSecret`.
- [ ] D.2 Tests: `SecretDraftTests` (snapshot round-trip, reference semantics). `EntryPathValidator` + `MetadataValidator` (pure) with their own test files.
- [ ] D.3 `PassSecretSerializer` (pure) — round-trip with `PassShowParser` enforced by property test against every `MockPassManager` fixture + edge cases (empty notes/meta, `:` in values, multi-line notes, trailing blank lines).
- [ ] D.4 `PasswordGenerating` protocol + `LivePasswordGenerator` (`SystemRandomNumberGenerator`, charsets matching `pass generate`, rejection sampling, throws on length ≤ 0). Tests: length, charsets, statistical bias smoke.
- [ ] D.5 `PassGenerateParser` (pure) — extracts new password from `pass generate` stdout; ANSI-strip; fixtures from 1.7.3 and 1.7.4 (with/without color).
- [ ] D.6 New `PassError` cases: `entryAlreadyExists(path:)`, `recipientNotFound(emailOrKeyId:)`, `invalidGpgId`, `sourceNotFound(path:)`, `writeFailed(reason:)`, `invalidLength`. Extend `ErrorPresentation` with `inlineRecoverable`, `onboardingHint`, `autoRefreshes`. Add `StoreChange` enum (`inserted/updated/removed/moved/bulk`). Tests: `ErrorPresentationTests` covers new cases.

**DoD:** all pure types compile and are unit-tested; only `Foundation` imports in `Domain/`; round-trip property test green; suite green.

### Phase E — Infrastructure / CLI
- [ ] E.1 `ShellInvocation` value type with `Stdin = .none | .data(Data) | .closeImmediately`. `ShellCommandRunning.run(_:)` becomes primary; old signature kept as compat extension delegating with `stdin: .none`.
- [ ] E.2 `ProcessShellRunner` stdin pipe: write Data + close on EOF; concurrent with stdout/stderr drain; cancellation terminates; logs only `stdinByteCount`. Tests: echo via `cat`, 10 MB no deadlock, `closeImmediately`, cancellation, logger capture asserts payload absence.
- [ ] E.3 Upgrade `FakeShellRunner` to capture `ShellInvocation` (incl. stdin Data). Update existing callers.
- [ ] E.4 `PassErrorMapper` new signatures (1.7.3 + 1.7.4 stderr fixtures): `already exists` / `Cowardly refusing` → `entryAlreadyExists`; `gpg: ... No public key` → `recipientNotFound`; `Error: ... is not in the password store` → `sourceNotFound` (or `invalidGpgId` during init); `pass-length` → `invalidLength`.
- [ ] E.5 `PassCLI` write methods:
  - `insert(path:, body:, force:)` → `["insert", "-m"] + (force ? ["-f"] : []) + [path]`, stdin = body, 15s.
  - `generate(path:, length:, noSymbols:, force:) -> String` → parses stdout via `PassGenerateParser`, 15s.
  - `generateInPlace(path:, length:, noSymbols:) -> String` → adds `--in-place`, 15s.
  - `remove(path:)` → `["rm", "-f", path]`, 10s.
  - `move(from:, to:, force:)` → `["mv"] + (force ? ["-f"] : []) + [from, to]`, 15s.
  Extend `PassManaging` with these + `var changes: AsyncStream<StoreChange> { get }`. Tests: `PassCLIWriteTests` (argv + stdin exact bytes, force toggles, env propagation).
- [ ] E.6 `LivePassManager` write methods + `AsyncStream<StoreChange>`: on success → invalidate scanner cache + emit `StoreChange`; errors mapped via `PassErrorMapper`. Tests: `LivePassManagerWriteTests` (events, cache invalidation, error path).
- [ ] E.7 `FakePasswordGenerator` fixture (deterministic outputs).
- [ ] E.8 Opt-in E2E suite `PassWriteIntegrationTests` (gated `KIZBA_E2E=1`): temp `GNUPGHOME` + ephemeral GPG key + `pass init`; full insert→show→edit→move→remove cycle; verify overwrite matrix; verify `pass insert -m` does not trigger pinentry decrypt.

**DoD:** all write CLI paths covered with exact argv + stdin; `LivePassManager` emits `StoreChange` and invalidates cache on every success; stdin grep ban green; opt-in E2E green locally; suite green; UI not yet touched.

### Phase F — New entry feature end-to-end
- [ ] F.1 `ToastCenter` (MVP shell): `@Observable @MainActor`; `Toast { id, severity, title, message?, action?, duration }`; dedup window 1s; default 4s, undoable 10s. Owned by `AppState`. `ToastOverlay` mounted at `RootSplitView`, bottom-trailing, `accessibilityNotification(.announcement)` on appear. Tests: post / dedup / auto-dismiss / manual dismiss.
- [ ] F.2 `EntryFormModel` (`.create` mode): `@Observable @MainActor`; states `idle | loadingExisting | editing | saving | saved | failed`; generation-counter; validation (path, password, metadata); `save()` cancellable; on dismissal cancel + drop draft. Tests: validation, success, collision (`entryAlreadyExists`), force retry, dismissal cancellation.
- [ ] F.3 `NewEntrySheet`: `FormSection` + `FolderPathPicker` + `SecretRevealField` + `KeyValueEditor` + notes; "Generate password…" sub-sheet button; primary `Save`, secondary `Cancel`. Inline `BannerView(.warning)` on collision with "Overwrite" → `forceOverwrite = true; save()`. Wire ⌘N + `+` toolbar in `EntryListView`.
- [ ] F.4 `GeneratePasswordSheet`: length stepper (default 25), symbols toggle, preview via `LivePasswordGenerator`, "Use this password" applies to draft.
- [ ] F.5 Selection reconciliation for `insert(new)`: `EntryFormModel` imperatively sets `appState.selectedEntryID = newEntry.id` after success (preference-gated, default on).
- [ ] F.6 Phase F regression sweep — manual + automated.

**DoD:** create-entry flow works end-to-end with real `pass`; ToastCenter posts success toast; collision → banner → overwrite verified; cancellation covered; suite green.

### Phase G — Other writes (Edit / In-place Generate / Move / Delete) + Undo
- [ ] G.1 `ActionHistory` (`@Observable @MainActor`): `record(_:expiresAfter:)`, `undoLast()`. Variants: `delete(path:, secret:)`, `move(from:, to:)`, `inPlaceGenerate(path:, previousSecret:)`. Cleared at quit. Tests: per-variant undo; expiry no-op.
- [ ] G.2 `EntryFormModel` (`.edit(originalPath:)` mode) + `EditEntrySheet`: pre-fetches via `pass.show`; save always `force: true` against `originalPath`; path field disabled. Wire ⌘E + `✎` toolbar in `EntryDetailView`. Tests: single `show` per edit; no double pinentry.
- [ ] G.3 `InPlaceGenerateSheet` (detail toolbar 🎲, ⌘⌥G): length + symbols + Regenerate → `EntryDetailModel.regenerateInPlace(...)` (pre-`show` for undo body, then `pass.generateInPlace`). On success: `actionHistory.record(.inPlaceGenerate(...))` + undoable toast (10s). Tests: happy path + error + ActionHistory record.
- [ ] G.4 `MoveEntrySheet` + `MoveEntryModel` (⌘⇧M): path picker, collision banner with Replace (`forceMove = true`). On success: `ActionHistory.move(from:to:)` + undoable toast. Wire `↔` toolbar in `EntryListView`. Tests: happy + collision + force retry + validation reuse.
- [ ] G.5 Delete (⌫): `destructiveConfirmation` (two-step). `EntryListModel.delete(path:)` does pre-`show` for undo body, then `pass.remove`. On success: `ActionHistory.delete(path:, secret:)` + undoable toast (Undo re-inserts via `pass.insert(force: true)`). Tests: two-step required, undoable toast, undo re-inserts, expired no-op.
- [ ] G.6 Toolbar lockout when any model is `.saving` (`appState.anyWriteInFlight`).

**DoD:** edit / in-place generate / move / delete work end-to-end; Undo restores prior state within 10s for delete/move/in-place-generate; toolbar lockout verified; suite green.

### Phase H — State reconciliation & cache
- [ ] H.1 Centralized `StoreChange` consumer in `EntryListModel` (single Task subscribed to `pass.changes`):
  - `.inserted(path:)` from create → select `path` (preference, default on).
  - `.inserted(path:)` from edit → no change.
  - `.updated(path:)` (in-place generate) → no change.
  - `.moved(from:to:)` → if selected was `from`, follow to `to`.
  - `.removed(path:)` → if selected was removed, clear selection.
  - `.bulk` → re-list, preserve selection if surviving.
  `EntryDetailModel` re-fetches on `.updated(currentPath)`; clears on `.removed(currentPath)`. Disambiguation insert(new) vs insert(edit) is imperative from `EntryFormModel` (no UI origin tag in `StoreChange`).
- [ ] H.2 `EntryListReconciliationTests` + `EntryDetailReconciliationTests` cover all selection rules.
- [ ] H.3 `ConcurrentWriteLockoutTests` — toolbar disabled while any model `.saving`; lockout released on `.saved`/`.failed`.

**DoD:** all five write outcomes have deterministic selection behavior covered by tests; detail auto-refreshes on update; concurrent writes prevented; suite green.

### Phase I — Polish, a11y, release prep
- [ ] I.1 Diagnostics menu finalization + full keyboard-shortcut audit (`Entry { New ⌘N, Edit ⌘E, Regenerate ⌘⌥G, Move ⌘⇧M, Delete ⌫ } Window { Diagnostics ⌘⌥D }`; Settings ⌘, via `SettingsLink`).
- [ ] I.2 Color-blind icon+color audit: `BannerView` and `ToastView` map each severity to a fixed SF Symbol (`exclamationmark.triangle`, `info.circle`, `checkmark.circle`, `xmark.octagon`). `SemanticIconographyTests` asserts non-empty symbol per severity.
- [ ] I.3 Manual a11y audit: VoiceOver navigation, toast announcement, increase-contrast theme swap, dynamic type scaling, keyboard-only operation. Notes in `.ai/a11y-audit.md`.
- [ ] I.4 macOS Sequoia smoke: `Process` spawn (no TCC prompt), clipboard auto-clear behavior. Document gotchas in README.
- [ ] I.5 `pass` version stderr fixtures parity (1.7.3 + 1.7.4) — both `PassErrorMapperTests` and `PassGenerateParserTests`.
- [ ] I.6 README updates: min `pass` version (1.7.3), MVP 2 scope, MVP 3 deferrals, `KIZBA_E2E=1` instructions, no-`ScrubbingString` limitation.
- [ ] I.7 Opt-in E2E green pass — `KIZBA_E2E=1 xcodebuild test ... -only-testing:KizbaTests/PassWriteIntegrationTests`.
- [ ] I.8 Final regression sweep — full suite green; all grep bans pass; warnings-as-errors clean.

**DoD:** a11y manual checks pass; color-blind audit done; Sequoia smoke pass; README updated; opt-in E2E green; full automated suite green.

## Cross-cutting workstreams

- **Logging discipline:** Phase A keeps baseline; E.2 stdin path logs only `stdinByteCount` (logger-capture test); E.5 `pass generate` stdout parsed but never logged; C.6 grep bans `Logger.*stdin`/`print(.*stdin` repo-wide; I.8 final sweep.
- **DS grep rules:** B has no bans; C.6 lands all DS bans together with full migration; F/G write code is C-compliant from day one.
- **Security checklist evolution:** A removes `as!` in Settings + audits consolidated fakes; D enforces `SecretDraft` non-conformances by tests; E enforces no stdin/payload logging; F asserts toasts never carry secret material (only entry path); G documents `ActionHistory` ≤10s in-memory limit; I documents `ScrubbingString` limitation.
- **Fixture corpus:** A.2 consolidates `Fakes`; B.3 `ContrastChecker`; D.5 `PassGenerateParser` fixtures (1.7.3, 1.7.4); E.3 `FakeShellRunner` upgraded; E.4 `PassErrorMapper` fixtures; E.7 `FakePasswordGenerator`; I.5 finalizes parity.
- **Manual a11y audit (I.3):** VoiceOver, toast announcement, contrast theme, dynamic type, keyboard-only, color-blind icon parity.

## Verification matrix (MVP 2 done?)

| Acceptance criterion | Manual scenario | Automated coverage |
|---|---|---|
| Create entry — happy path | ⌘N → fill → Save → toast → row selected | `EntryFormModelCreateTests`, `PassCLIWriteTests`, `LivePassManagerWriteTests`, `ToastCenterTests` |
| Create entry — overwrite | ⌘N → existing path → banner → Overwrite → success | `EntryFormModelCreateTests` (collision + force), `PassErrorMapperTests` |
| Edit entry — single pinentry | ⌘E → enter passphrase ONCE → modify → Save | `EntryFormModelEditTests`, `PassWriteIntegrationTests` |
| In-place regenerate — no second pinentry | Detail 🎲/⌘⌥G → regenerate without prompt | `EntryDetailRegenerateTests`, `PassWriteIntegrationTests` |
| Move — no collision | ⌘⇧M → new path → Save → selection follows | `MoveEntryModelTests`, `EntryListReconciliationTests` |
| Move — collision | ⌘⇧M → existing → banner → Replace → success | `MoveEntryModelTests` (collision + force) |
| Delete — two-step + undo | Select → ⌫ → confirm → toast → Undo → row reappears | `EntryListDeleteTests`, `DestructiveConfirmationTests`, `ActionHistoryTests` |
| Undo within 10s | Trigger destructive → Undo in window → restored | `ActionHistoryTests`, `EntryListDeleteTests` |
| Undo expired | Trigger → wait > 10s → Undo no-op | `ActionHistoryTests` |
| Path validation | Empty / `..` / `.gpg` suffix → inline error | `EntryPathValidatorTests`, `EntryFormModelCreateTests` |
| Metadata validation | Duplicate key / `:` in key → inline error | `MetadataValidatorTests` |
| Recipient errors → onboarding | Misconfigured `.gpg-id` → create → banner → Diagnostics | `ErrorPresentationTests`, `PassErrorMapperTests` |
| Source-not-found auto-refresh | External delete → next op → re-list | `ErrorPresentationTests`, reconciliation test |
| Concurrent-write lockout | Slow save → other toolbar disabled | `ConcurrentWriteLockoutTests`, manual |
| Theme swap | Light/dark/highContrast | `ThemeTokenTests`, manual |
| All DS tokens contrast pass | — | `ThemeTokenTests` (`ContrastChecker`) |
| Color-blind icon+color pairing | Banner + Toast severities show distinct icons | `SemanticIconographyTests`, `BannerViewTests`, manual |
| No inline styling in `Presentation/**` | — | `SourceGrepTests` (Phase C.6 bans) |
| No stdin logging | — | `SourceGrepTests` + `ProcessShellRunnerStdinTests` |
| No `as!` in `Sources/` | — | `SourceGrepTests` |
| Tests stay green (≥ 209) | — | `xcodebuild test -scheme Kizba ...` |

## Sequencing dependencies

- Phase A → B (clean base before DS).
- B → C (Theme + atoms before view migration).
- C → F, C → G (DS shells before write sheets).
- D → E (pure types before infra/CLI).
- E → F (`LivePassManager` writes + `AsyncStream<StoreChange>` before create flow).
- F → G (ToastCenter shell + `EntryFormModel` before edit/move/delete/regenerate).
- G → H (all writes before reconciliation centralization).
- H → I (deterministic reconciliation before polish).

Within phases:
- A.2 (consolidated fakes) before A.4–A.6.
- B.1 (Theme) → B.2 (env) → B.3 (token tests) → B.4 (atoms).
- C.1 (DS shells) → C.3/C.4 (view migration) → C.6 (grep bans) — bans land last to avoid flapping.
- D.6 (`StoreChange`, new `PassError`) → E.4 (`PassErrorMapper`) → E.6 (`LivePassManager` writes).
- E.1 (`ShellInvocation`) → E.2 (stdin pipe) → E.3 (`FakeShellRunner` upgrade) → E.5 (`PassCLI` writes).
- E.7 (`FakePasswordGenerator`) before F.4 (Generate sub-sheet).
- F.1 (`ToastCenter` shell) before F.2 and before G.1 (undoable toasts).
- G.1 (`ActionHistory`) before G.3/G.4/G.5.
- D.5 (`PassGenerateParser`) before E.5 (`PassCLI.generate*`).

## Out of scope (do NOT implement in MVP 2)

- `pass git ...` (status/sync/push/pull) — MVP 3.
- System `UndoManager`.
- Touch ID / LocalAuthentication.
- Menu-bar (status item) app surface.
- Quick-search / Spotlight indexing.
- FSEvents / external-change detection.
- App Sandbox / hardened-runtime tightening.
- Snapshot tests for design system or views.
- `ScrubbingString` secure-string buffer.
- Any third-party Swift Package or framework.
