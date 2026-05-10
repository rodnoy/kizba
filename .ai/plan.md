# Kizba — MVP 3 Implementation Plan

Native macOS SwiftUI client for `pass(1)`. MVP 1 (read-only) and MVP 2 (writes + design system + Undo + Toast + sanitized Diagnostics) shipped. MVP 3 scope is defense-in-depth, tech-debt cleanup, FSEvents auto-refresh, accessibility improvements, Touch ID per-reveal, and final polish.

This document is the full, authoritative MVP 3 plan. It is organized into phases (A–F). Each phase contains discrete tasks, verification steps, DoD (Definition of Done), and sequencing constraints.

## Goals & non-goals

**Goals**
- Phase A — Defense-in-depth: consolidate async test helpers, add SourceGrepTests rules, add code-review checklist.
- Phase B — AppRouter + EntryFormBody refactor: centralize presentation flags & selection, extract shared entry form body, consolidate generate sub-sheet wiring.
- Phase C — FSEvents external-change detection: StoreWatching protocol, FSEventsStoreWatcher implementation, LivePassManager integration, debounced bulk emits.
- Phase D — Accessibility medium gaps: 5 medium items (SecretRevealField accessibility value, KeyValueEditor row accessibility, SecureField for passwords, dynamic layout in FormFieldRow on large type, toolbar hints).
- Phase E — Touch ID per-reveal: BiometricAuthenticating protocol, LocalAuth implementation, opt-in setting, SecretRevealField gating.
- Phase F — Polish & release prep: a11y re-run, Sequoia smoke re-run, README updates, decisions/handoff update, final regression sweep.

**Non-goals (deferred to MVP 4+)**
- `pass git ...` integration (needs full conflict-resolution UX).
- Menu-bar / status item app surface (global hotkey + lifecycle complexity).
- App Sandbox + helper tool for sandboxed `Process` spawn.
- `ScrubbingString` secure-string buffer.
- System `UndoManager` integration.
- Snapshot tests.
- Quick-search / Spotlight indexing.
- Localization beyond English.
- Browser auto-fill / extension.
- Per-path FSEvents delta (MVP 3 ships `.bulk`-only).
- Touch ID password fallback (`.deviceOwnerAuthentication`); per-reveal only (NOT app-launch, NOT per-`pass show`).
- Any third-party Swift Package or framework.

## Baseline & constraints

- Swift 5.10, Xcode 15.4+, macOS deployment target 14.0.
- `SWIFT_STRICT_CONCURRENCY = complete`, warnings-as-errors for app target.
- Zero third-party dependencies (`LocalAuthentication`, `CoreServices` are system frameworks).
- Non-sandboxed; Developer ID + notarization; Hardened Runtime + `cs.disable-library-validation`.
- All code/comments/docs/commits in English. User chat in Russian.
- All Phase C.6 grep bans (no `as!`, no `Logger.*stdin`/`print(.*stdin)`, no inline styling outside DesignSystem) continue to apply.

## Phases overview

Order locked: A → B → C → D → E → F. A and D are independently reorderable but A is cheapest, lands first.

---

## Phase A — Defense-in-depth & test hygiene (~3 days, low risk)

- **A.1** Extract `KizbaTests/Fixtures/AsyncTestHelpers.swift`: `startObservation(of:)` (5× `Task.yield()` + 20 ms sleep) and `waitUntil(_:timeout:)` (poll-with-timeout) from 4 reconciliation test files (`EntryListReconciliationTests`, `EntryDetailReconciliationTests`, `ConcurrentWriteLockoutTests`, `ActionHistoryTests`). DoD: `rg 'func startObservation|func waitUntil' KizbaTests` returns one definition each; suite green.
- **A.2** New `SourceGrepTests` rule: every `Kizba/Presentation/**/*Model.swift` matching `final class \w+Model` MUST contain `@Observable` (allow-list comment `// kizba:not-observable-model` skips). DoD: rule-only test green; rule fires on a deliberate fixture (smoke check).
- **A.3** New `SourceGrepTests` rule: forbid `\w+Model\(` constructor inside `.sheet/.popover/.fullScreenCover { ... }` body (allow-list comment `// kizba:allow-sheet-init`). DoD: rule-only test green; rule fires on a deliberate fixture.
- **A.4** Add `.ai/code-review-checklist.md`. Codify the `.onChange(of: enumWithAssoc)` rule (manual-only, NOT a grep test) + cross-link from `AGENTS.md`. DoD: file exists; `AGENTS.md` references it.
- **A.5** Phase A regression sweep. DoD: `xcodebuild test`, all grep bans clean, ≥ 692 tests still green.

**Phase A DoD:** AsyncTestHelpers consolidated; 2 new grep rules in `SourceGrepTests`; checklist file in `.ai/`; full suite green.

---

## Phase B — AppRouter + EntryFormBody refactor (~5 days, medium risk)

### B.1 AppRouter scaffold
- **B.1.1** New `Kizba/App/AppRouter.swift`: `@Observable @MainActor final class AppRouter`. Stored: `isNewEntrySheetPresented`, `isEditEntrySheetPresented`, `isMoveEntrySheetPresented`, `isRegenerateInPlaceSheetPresented`, `isDeleteConfirmationPresented`, `selectedFolder: String?`, `selectedEntryID: String?`. Imperative API: `presentNewEntry()`, `presentEditEntry()`, `presentMove()`, `presentRegenerate()`, `presentDeleteConfirmation()`, `dismissAll()`, `selectFolder(_:)`, `selectEntry(_:)`. DoD: file compiles; `AppRouterTests` cover dismissAll + each present* + selection setters (≥ 10 methods).
- **B.1.2** Add `router: AppRouter` to `AppState.init` (designated init); proxy properties on `AppState` (`get { router.isXPresented } set { router.isXPresented = newValue }`) for all 7 fields. DEBUG-only `init()` constructs `AppRouter()` for existing tests. DoD: full suite green; no call-site updates yet.

### B.2 AppRouter call-site migration
- **B.2.1** Migrate `KizbaApp.swift` and all Commands to read/write `state.router.*` directly. DoD: file compiles; suite green.
- **B.2.2** Migrate `EntryListView` (sheet hosts: New, Edit, Move, Regenerate, Delete confirmation; folder/entry selection bindings) to `state.router.*`. DoD: file compiles; manual smoke: open each sheet, select rows.
- **B.2.3** Migrate `EntryDetailView`, `RootSplitView`, `SidebarView`, and any remaining call sites to `state.router.*`. DoD: `rg 'state\.(isNew|isEdit|isMove|isRegen|isDelete|selectedFolder|selectedEntryID)' Kizba/Presentation` returns 0.

### B.3 AppRouter proxy removal
- **B.3.1** Remove all 7 proxy properties from `AppState`. Update `AppState` doc to list remaining responsibilities (`searchQuery`, `isSidebarCollapsed`, `currentEntries`, `toastCenter`, `actionHistory`, `activeWriteOps`, `router`). DoD: file compiles; suite green; `AppState.swift` LOC delta is negative.

### B.4 EntryFormBody extraction
- **B.4.1** New `Kizba/Presentation/EntryForm/EntryFormBody.swift`: generic `EntryFormBody<Header: View, Footer: View>`. Body = 4 `FormSection` rows (Path / Password / Metadata / Notes) + `KeyValueEditor` ↔ `MetadataPair` bridging + inline validation rendering. Slots: `header`, `footer`. Parameter: `pathFieldEnabled: Bool`. DoD: file compiles; `EntryFormBodyTests` covers slot rendering + `pathFieldEnabled` toggling.
- **B.4.2** Move Generate sub-sheet wiring (currently in `NewEntrySheet`) into `EntryFormBody` (consolidates the `@State`-held sub-model rule). The Generate sub-sheet model is created once via `@State` inside `EntryFormBody` and exposed via a "Generate password…" button next to the password field. DoD: `NewEntrySheet` no longer references `GeneratePasswordModel` directly; sub-sheet still works.
- **B.4.3** Refactor `NewEntrySheet`: header = `BannerView(.warning)` collision banner (when `model.state == .failed(.entryAlreadyExists)`); body = `EntryFormBody(model:, pathFieldEnabled: true)`; footer = `saveCancelButtons`. DoD: New entry flow works end-to-end; file LOC drops measurably; suite green.
- **B.4.4** Refactor `EditEntrySheet` analogously: header = `EmptyView()`; body = `EntryFormBody(..., pathFieldEnabled: false)`; footer = `saveCancelButtons`. Loading skeleton handled by `EntryFormBody` reading `model.state`. DoD: Edit entry flow works end-to-end; `NewEntrySheet` + `EditEntrySheet` LOC delta combined ≥ −150 lines.

### B.5 Phase B regression
- **B.5.1** Full suite + manual smoke (open each sheet, save, dismiss, undo). DoD: ≥ 692 + new tests green; A.2/A.3 grep rules still pass.

**Phase B DoD:** `AppRouter` owns presentation flags + selection; `AppState` slimmed; `EntryFormBody` shared; Generate sub-sheet wiring lives in `EntryFormBody`; all sheets work; suite green.

---

## Phase C — FSEvents external-change detection (~5 days, medium risk)

- **C.1** New `Kizba/Domain/Protocols/StoreWatching.swift`: `protocol StoreWatching: Sendable { var events: AsyncStream<Void> { get }; func start(at storeRoot: URL) async; func stop() async }`. Foundation only. DoD: file compiles.
- **C.2** New `KizbaTests/Fixtures/FakeStoreWatcher.swift`: in-memory implementation with `simulateChange()` test affordance + start/stop call counters. DoD: file compiles; trivial unit test verifies start/stop/simulate.
- **C.3** New `Kizba/Infrastructure/Store/FSEventsStoreWatcher.swift`: `final class @unchecked Sendable`. Owns serial `DispatchQueue` ("kizba.fsevents"). `start(at:)` builds `FSEventStreamCreate` with `kFSEventStreamCreateFlagFileEvents | kFSEventStreamCreateFlagNoDefer`, schedules on serial queue, starts. Callback debounces via `DispatchSourceTimer` (350 ms trailing-edge); on fire, emits a single `Void` to a multi-subscriber `AsyncStream` (re-use the multi-subscriber pattern from `LivePassManager.changes`). `stop()` invalidates stream + cancels timer + drains continuations. DoD: file compiles; isolated `FSEventsStoreWatcherTests` (gated by `KIZBA_FSEVENTS_TEST=1`, real-FS, opt-in) verifies single emission within 700 ms after a write.
- **C.4** Optional `KizbaTests/Fixtures/TempStoreFixture.swift` extension: helper to mutate the temp store filesystem (touch / write / delete a file) for FSEvents tests. DoD: helper compiles; reused by C.3 opt-in tests.
- **C.5** `LivePassManager` integration: add `private var watcher: (any StoreWatching)?` (optional, lazy). On first subscriber registration: instantiate watcher (or accept injected one via init), call `watcher.start(at: storeLocation())`, spawn task draining `watcher.events` → `await self.emit(.bulk)`. On last subscriber removal: call `watcher.stop()` and tear down drain task. DoD: `LivePassManagerFSEventsTests` (uses `FakeStoreWatcher`) verifies: lazy start on 1st subscriber, no second start on 2nd subscriber, stop on last unsubscribe, `.bulk` emission on `simulateChange()`. ≥ 6 test methods.
- **C.6** `AppEnvironment.live()` injection: construct `FSEventsStoreWatcher()` once and pass to `LivePassManager.init(storeWatcher:)`. `preview()` and tests pass `FakeStoreWatcher()` or `nil`. DoD: app launches, sidebar refreshes within ~700 ms after editing a file in the password store via Finder.
- **C.7** Phase C regression: full suite + manual smoke (touch a file via Terminal → list re-renders within ~700 ms). DoD: suite green; manual check noted in `.ai/sequoia-smoke.md`.

**Phase C DoD:** External FS changes auto-refresh the UI via `.bulk`; no per-path delta; debounced; lazy lifecycle tied to subscriber count; `LivePassManagerFSEventsTests` green; opt-in `FSEventsStoreWatcherTests` green locally with `KIZBA_FSEVENTS_TEST=1`.

---

## Phase D — a11y medium gaps (~1 day, low risk)

- **D.1** `SecretRevealField`: add `.accessibilityValue(isRevealed ? "Revealed" : "Hidden")` to the toggle. DoD: VoiceOver announces state change; `SecretRevealFieldTests` augmented with one assertion.
- **D.2** `KeyValueEditor`: per-row `.accessibilityElement(children: .contain)` + `.accessibilityLabel("Field row \(index + 1)")`. DoD: VoiceOver groups each row coherently; manual check noted.
- **D.3** `EntryFormBody` (Phase B): replace cleartext password `TextField` with `SecureField` + reveal toggle (use existing `SecretRevealField`). DoD: New + Edit sheets show masked password by default; suite green.
- **D.4** `FormFieldRow`: read `@Environment(\.dynamicTypeSize)`. When `>= .accessibility1`, switch from `HStack(label, field)` to `VStack(alignment: .leading)`. DoD: manual check at AX1+ size; `FormFieldRowTests` add a Dynamic-Type assertion.
- **D.5** Toolbar write buttons: `.accessibilityHint("Keyboard shortcut: ⌘N")` (and ⌘E, ⌘⌥G, ⌘⇧M, ⌫) on each. DoD: VoiceOver reads the hint; manual check noted.
- **D.6** Update `.ai/a11y-audit.md`: tick the 5 medium boxes. DoD: file diff shows 5 transitions from open to closed.

**Phase D DoD:** All 5 medium a11y gaps closed; tests green.

---

## Phase E — Touch ID per-reveal gate (~4 days, medium risk)

### E.1 Domain protocol
- **E.1.1** New `Kizba/Domain/Protocols/BiometricAuthenticating.swift`: `protocol BiometricAuthenticating: Sendable { func isAvailable() -> BiometricAvailability; func authenticate(reason: String) async -> BiometricResult }`. Plus enums: `BiometricAvailability` (`.available`, `.unavailable(BiometricUnavailableReason)`), `BiometricUnavailableReason` (`.notEnrolled`, `.hardwareUnavailable`, `.passcodeNotSet`, `.userDisabled`, `.unknown`), `BiometricResult` (`.success`, `.cancelled`, `.failed(BiometricFailureReason)`), `BiometricFailureReason` (`.userFailed`, `.systemCancel`, `.appCancel`, `.invalidContext`, `.unknown`). All `Sendable, Equatable`. NO `LAError` leakage at the protocol level. DoD: file compiles; no `import LocalAuthentication`.

### E.2 Production impl
- **E.2.1** New `Kizba/Infrastructure/Auth/LocalAuthBiometricAuthenticator.swift`: `final class @unchecked Sendable`. `isAvailable()` constructs a fresh `LAContext`, calls `canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error:)`, maps `LAError.Code` → `BiometricUnavailableReason`. `authenticate(reason:)` constructs a fresh `LAContext` per call, wraps `evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, ...)` in `withCheckedContinuation`, maps `LAError.Code` → `BiometricResult`. **Note**: `.deviceOwnerAuthenticationWithBiometrics` (NOT `.deviceOwnerAuthentication` — no password fallback). DoD: file compiles; `LocalAuthBiometricAuthenticatorTests` covers the `LAError.Code` mapping table (≥ 8 cases).

### E.3 Settings + injection
- **E.3.1** Extend `Kizba/Infrastructure/Settings/SettingsKeys.swift`: add `requireBiometricBeforeReveal: Bool` (default OFF). Add to `SettingsStoring` allow-list. DoD: `UserDefaultsSettingsStoreTests` augmented with one round-trip + default assertion.
- **E.3.2** Extend `AppEnvironment`: add `biometricAuthenticator: any BiometricAuthenticating`. `live()` constructs `LocalAuthBiometricAuthenticator()`. `preview()` and tests pass `FakeBiometricAuthenticator(isAvailable: .available, result: .success)`. DoD: existing test files updated as needed; suite green.

### E.4 Test fake
- **E.4.1** New `KizbaTests/Fixtures/FakeBiometricAuthenticator.swift`: configurable `availability` + scripted `result(s)` queue + call counters. DoD: file compiles; trivial smoke test.

### E.5 Per-reveal gate wiring
- **E.5.1** Augment `SecretRevealField`: take `biometricAuthenticator: any BiometricAuthenticating` + `gateEnabled: Bool` parameters (settings-driven). When toggle pressed AND `gateEnabled == true` AND `isRevealed == false`: `await authenticator.authenticate(reason: "Reveal password")`; on `.success` → reveal; on `.cancelled` / `.failed(_)` → stay masked, no toast. Re-masking is NOT gated. DoD: `SecretRevealFieldTouchIDTests` covers: gate-off bypasses auth; gate-on .success reveals; gate-on .cancelled stays masked; gate-on .failed stays masked + no toast; re-mask never gates. ≥ 5 methods.
- **E.5.2** `EntryDetailView` (and any other `SecretRevealField` callers): plumb through `env.biometricAuthenticator` + `settings.requireBiometricBeforeReveal`. DoD: app compiles; manual smoke with toggle ON triggers Touch ID prompt on every reveal.

### E.6 Settings UI
- **E.6.1** `SettingsView`: add toggle "Require Touch ID before revealing passwords". When `biometricAuthenticator.isAvailable() != .available`: render disabled with explanatory hint text mapped from `BiometricUnavailableReason`. DoD: toggle disabled in simulator with no biometrics; enabled on a real Mac with Touch ID; `SettingsViewTouchIDTests` covers the `SettingsModel`-side disabled flag.

### E.7 Phase E regression
- **E.7.1** Full suite + manual smoke: toggle OFF (default) → no prompt; toggle ON → prompt before each reveal; cancel keeps masked silently. DoD: suite green; manual matrix check.

**Phase E DoD:** Touch ID gate works per-reveal; opt-in default OFF; settings disabled when unavailable; `LAError` never leaks past the impl; tests green.

---

## Phase F — Polish & release prep (~2 days, low risk)

- **F.1** Manual a11y re-run with VoiceOver + Increase Contrast + Dynamic Type + Reduce Motion + Color filters + Keyboard-only. Update checkboxes in `.ai/a11y-audit.md`. DoD: file reflects MVP 3 closures (5 medium) + remaining 4 low items annotated.
- **F.2** macOS Sequoia smoke re-run: cold-launch, read flow, write flow, concurrent-write lockout, Diagnostics, **new**: FSEvents auto-refresh row, Touch ID prompt row. Update `.ai/sequoia-smoke.md`. DoD: file diff includes 2 new rows; verification table filled.
- **F.3** README updates: Touch ID toggle docs (default OFF, requirement); FSEvents auto-refresh mention (replaces "⌘R only"); MVP 3 feature list; MVP 4 deferrals. DoD: README mentions both features explicitly.
- **F.4** Append `## 2026-XX-XX — MVP 3` section to `.ai/decisions.md` summarising the locked decisions from the architecture doc (one bullet each, terse). DoD: section exists.
- **F.5** Rewrite `.ai/handoff.md` for MVP 3 closure: commit ledger, suite size, deferrals, verification commands (add `KIZBA_FSEVENTS_TEST=1` recipe), constraints, MVP 4 backlog. DoD: file reflects new state.
- **F.6** Final regression sweep: `xcodebuild test`, `xcodebuild build` (Release), all grep bans (existing C.6 + new A.2/A.3) clean, `KIZBA_E2E=1` opt-in pass, `KIZBA_FSEVENTS_TEST=1` opt-in pass. DoD: all four checks green; suite ≥ 692 + Phase A/B/C/D/E additions.

**Phase F DoD:** Docs current; manual checks done; both opt-in suites green; full automated suite green; ready to tag MVP 3.

---

## Cross-cutting workstreams

- **Regression-prevention discipline:** A.2 / A.3 grep rules land before B (which extracts a new model + new view) so violations surface immediately. C.6's MVP 2 bans (`Logger.*stdin`, `print(.*stdin`, `as!`, inline styling) continue to apply repo-wide.
- **Fixture consolidation:** A.1 (`AsyncTestHelpers`) → C.2 (`FakeStoreWatcher`) → C.4 (`TempStoreFixture` extension) → E.4 (`FakeBiometricAuthenticator`). All in `KizbaTests/Fixtures/`.
- **Concurrency hygiene:** `FSEventsStoreWatcher` and `LocalAuthBiometricAuthenticator` are `final class @unchecked Sendable`. All other new types `Sendable` from the start. `LAContext` is fresh per `authenticate(_:)` call (no reuse).
- **Logging discipline:** Touch ID gate logs only outcomes (success/cancelled/failed) — NEVER reason strings, NEVER PII. FSEvents callback logs only event count, NEVER paths.
- **Security non-conformances:** No new types inherit Codable / CustomStringConvertible / CustomDebugStringConvertible. `BiometricResult` is `Equatable` only.
- **Manual smoke:** F.1 (a11y) + F.2 (Sequoia) re-run before tag. C.7 adds an inline FS-touch smoke during Phase C.

## Test plan (per-phase additions, approximate)

| Phase | New test files / fixtures | Approx. method count |
|---|---|---:|
| A | `AsyncTestHelpers.swift`; new tests in `SourceGrepTests` (2 rules + 2 smoke fixtures) | +4 |
| B | `AppRouterTests.swift`, `EntryFormBodyTests.swift` | ~+18 |
| C | `LivePassManagerFSEventsTests.swift` (FakeStoreWatcher), `FSEventsStoreWatcherTests.swift` (opt-in), `FakeStoreWatcher.swift` fixture | ~+9 |
| D | Augmented: `SecretRevealFieldTests` (+1), `KeyValueEditorTests` (+1), `FormFieldRowTests` (+1) | +3 |
| E | `LocalAuthBiometricAuthenticatorTests.swift`, `SecretRevealFieldTouchIDTests.swift`, `FakeBiometricAuthenticator.swift` fixture, `UserDefaultsSettingsStoreTests` (+1), `SettingsViewTouchIDTests.swift` | ~+16 |
| F | None (manual + docs) | 0 |

**Net suite delta:** ~ +50 tests (692 → ~742). All counts approximate.

**Opt-in env vars:** `KIZBA_E2E=1` (existing); `KIZBA_FSEVENTS_TEST=1` (new).

**Snapshot tests:** still OUT.

## Manual verification matrix

| Acceptance | Manual scenario | Automated coverage |
|---|---|---|
| AppRouter owns flags | Open + dismiss each sheet via menu and toolbar | `AppRouterTests` |
| EntryFormBody powers New + Edit | Create then immediately edit; same form layout | `EntryFormBodyTests` |
| Generate sub-sheet from EntryFormBody | New entry → "Generate password…" → Use → field updated | existing `GeneratePasswordModelTests` |
| FSEvents auto-refresh | `echo … > ~/.password-store/foo.gpg` → list updates within ~700 ms | `LivePassManagerFSEventsTests`, opt-in `FSEventsStoreWatcherTests` |
| FSEvents lazy lifecycle | Watcher idle until app opens; idle again after view tear-down | `LivePassManagerFSEventsTests` |
| FSEvents debounce | Rapid 10× write burst → ONE list refresh, not 10 | `LivePassManagerFSEventsTests` |
| SecretRevealField a11y value | VoiceOver reads "Revealed" / "Hidden" | `SecretRevealFieldTests` |
| KeyValueEditor a11y rows | VoiceOver groups each row | manual |
| Password is SecureField | New + Edit show masked field by default | manual |
| FormFieldRow Dynamic Type | At AX1+, label stacks above field | `FormFieldRowTests` |
| Toolbar shortcut hints | VoiceOver reads "Keyboard shortcut: ⌘N" etc. | manual |
| Touch ID OFF (default) | Reveal works without prompt | `SecretRevealFieldTouchIDTests` |
| Touch ID ON success | Reveal prompts → success → revealed | `SecretRevealFieldTouchIDTests`, manual |
| Touch ID ON cancel | Cancel → stays masked, no toast | `SecretRevealFieldTouchIDTests` |
| Touch ID ON fail | Wrong finger → stays masked, no toast | `SecretRevealFieldTouchIDTests` |
| Touch ID re-mask | Toggle off never prompts | `SecretRevealFieldTouchIDTests` |
| Touch ID unavailable | Settings toggle disabled with hint | `SettingsViewTouchIDTests`, manual |
| Touch ID per-reveal (NOT per-show) | Edit entry: ONE pinentry, then password masked → reveal prompts Touch ID separately | manual |
| All grep bans pass | — | `SourceGrepTests` (existing C.6 + new A.2 + A.3) |
| Tests stay green | — | `xcodebuild test` |

## Sequencing dependencies

**Hard gates:**
- A → B: A.2 / A.3 grep rules must land before B introduces `AppRouter` and `EntryFormBody`.
- B.1 → B.2 → B.3: proxy properties → call-site updates → proxy removal is a strict 3-step migration.
- B.4.1 → B.4.2 → B.4.3 → B.4.4: extract shell → consolidate Generate wiring → adapt New → adapt Edit.
- C.1 → C.2 → C.5: protocol → fake → consumer integration. C.3 (real impl) blocks C.6 (live wiring) but is parallelizable with C.5 (uses fake).
- D.3 (`EntryFormBody` SecureField) requires B.4 done.
- E.1 → E.2 → E.4 → E.5: protocol → impl → fake → wiring. E.3 (settings) parallelizable with E.2.
- E.5 requires B.4 (the password field rendering site is now `EntryFormBody`).

**Reorderable:**
- Phase A and Phase D are independent (D fixes don't depend on A). A first because A is cheaper and unblocks B's grep rules.
- C and E can run in parallel after A+B; ordering is purely scheduling preference. Plan picks C → D → E for risk-load balancing.

## Out of scope (do NOT implement in MVP 3)

`pass git`, menu-bar / status-item app surface, App Sandbox + helper tool, `ScrubbingString` secure buffer, system `UndoManager` integration, snapshot tests, localization beyond English, browser auto-fill, per-path FSEvents delta (only `.bulk` ships), Touch ID password fallback (`.deviceOwnerAuthentication`), Touch ID app-launch gate (per-reveal only), Touch ID per-`pass show` gate (per-reveal only). Any third-party Swift Package or framework.
