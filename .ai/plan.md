# Kizba — MVP 3 Implementation Plan

5 features across 6 phases. Baseline: HEAD `4cd0467`, 692 tests (8 skipped, 0 failures), release build green.

## Goal

Ship MVP 3: defense-in-depth grep rules, AppRouter + EntryFormBody refactor, FSEvents auto-refresh, a11y medium-priority fixes, Touch ID per-reveal gate, polish + final regression sweep.

## Constraints

- Zero third-party Swift packages.
- macOS 14.0 deployment target, Swift 5.10, strict concurrency = complete.
- Secret-bearing types NOT Codable / NOT CustomStringConvertible / NOT CustomDebugStringConvertible.
- No stdout logging in Infrastructure/Shell/ or Infrastructure/Pass/.
- Stdin never logged — only `stdinByteCount`.
- `as!` banned in `Kizba/` source.
- Inline styling banned in Presentation outside DesignSystem.
- All code/comments/commits in English.
- No `grep` in scripts — use `rg` (ripgrep).
- Snapshot tests remain out of scope.
- App Sandbox remains deferred.
- `pass git` integration deferred to MVP 4.
- Menu-bar / status item deferred to MVP 4.

## Verification commands (apply after every task)

```sh
# Full suite
xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS'

# SourceGrepTests only
xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' \
  -only-testing:KizbaTests/SourceGrepTests

# Release build
xcodebuild -scheme Kizba -project Kizba.xcodeproj -configuration Release -destination 'platform=macOS' build

# Repo hygiene
rg -n '\bas!' Kizba
rg -n 'Logger.*stdin|print\(.*stdin' Kizba
find . -name .DS_Store -not -path '*/.git/*'
```

---

## Phase A — Defense-in-depth & test hygiene

**Theme:** Harden the test suite with shared helpers and new grep rules; codify code-review checklist.

### A.1 — Extract AsyncTestHelpers ✅ COMPLETED

- **Objective:** Consolidate duplicated `waitUntil` and `startObservation` helpers from 4 test files into `KizbaTests/Fixtures/AsyncTestHelpers.swift`.
- **Files to create:** `KizbaTests/Fixtures/AsyncTestHelpers.swift`
- **Files to modify:** `EntryListReconciliationTests.swift`, `EntryDetailReconciliationTests.swift`, `ConcurrentWriteLockoutTests.swift`, `ActionHistoryTests.swift` — remove private duplicates, call shared versions.
- **Verification:** `rg 'func waitUntil\(' KizbaTests --count-matches` → only AsyncTestHelpers.swift:1; `rg 'func startObservation' KizbaTests --count-matches` → only AsyncTestHelpers.swift:1; full suite ≥ 692 tests, 0 failures.
- **DoD:** One definition of each helper; 4 consumer files updated; suite green.
- **Risks:** `startObservation` signature differences across files — generic closure approach handles this.
- **Commit:** `refactor(mvp3-a1): extract AsyncTestHelpers — consolidate waitUntil + startObservation`

### A.2 — @Observable grep rule ✅ COMPLETED

- **Objective:** Add `testPresentationModelsRequireObservable()` to `SourceGrepTests` ensuring every `Kizba/Presentation/**/*Model.swift` with `final class …Model` also contains `@Observable`. Allow-list via `// kizba:not-observable-model`.
- **Files to modify:** `KizbaTests/SourceGrepTests.swift`
- **Verification:** Run SourceGrepTests only; full suite green.
- **DoD:** New test method exists and passes; removing `@Observable` from any `*Model.swift` would fail the test.
- **Risks:** False positives on non-view-model files — mitigated by scoping to `Kizba/Presentation/` and requiring `final class` pattern.
- **Commit:** `test(mvp3-a2): SourceGrepTests — @Observable annotation rule for Presentation models`

### A.3 — Sheet model constructor grep rule

- **Objective:** Add `testNoModelConstructorInSheetBody()` to `SourceGrepTests` forbidding `*Model(` constructor calls inside `.sheet { }`, `.popover { }`, `.fullScreenCover { }` closure bodies. Allow-list via `// kizba:allow-sheet-init`.
- **Files to modify:** `KizbaTests/SourceGrepTests.swift`
- **Verification:** Run SourceGrepTests only; full suite green.
- **DoD:** New test method exists and passes on current codebase (no violations).
- **Risks:** Brace-depth tracking is heuristic; a line-proximity approach may be more robust.
- **Commit:** `test(mvp3-a3): SourceGrepTests — ban model constructors inside sheet/popover bodies`

### A.4 — Code review checklist + AGENTS.md cross-link

- **Objective:** Create `.ai/code-review-checklist.md` with ≥ 5 non-automatable review rules. Cross-link from `.ai/AGENTS.md`.
- **Files to create:** `.ai/code-review-checklist.md`
- **Files to modify:** `.ai/AGENTS.md` (or create minimal one with cross-link)
- **Checklist items:**
  1. `.onChange(of: enumWithAssociatedValue)` — use derived `stateID: Int` instead.
  2. `@State` sub-models in sheets — must be `@State private var` in PARENT view.
  3. Toast messages must never contain secret material.
  4. New secret-bearing types must NOT conform to Codable / CustomStringConvertible / CustomDebugStringConvertible.
  5. `LAContext` must be fresh per `authenticate()` call.
- **Verification:** `test -f .ai/code-review-checklist.md && echo OK`; `rg 'code-review-checklist' .ai/`
- **DoD:** File exists with ≥ 5 items; cross-link present.
- **Commit:** `docs(mvp3-a4): add code-review-checklist.md + AGENTS.md cross-link`

### A.5 — Phase A regression sweep

- **Objective:** Verify full suite, all grep bans, repo hygiene, release build after A.1–A.4.
- **Files to modify:** `.ai/handoff.md` (mark Phase A complete).
- **Verification:** All verification commands exit 0; suite ≥ 692 tests, 0 failures.
- **DoD:** Phase A complete; Phase B can begin.
- **Commit:** `chore(mvp3-a5): Phase A regression sweep — all green`

### Phase A DoD

- `KizbaTests/Fixtures/AsyncTestHelpers.swift` exists; `waitUntil` and `startObservation` have exactly one definition each.
- 2 new test methods in `SourceGrepTests`: `testPresentationModelsRequireObservable`, `testNoModelConstructorInSheetBody`.
- `.ai/code-review-checklist.md` exists with ≥ 5 items.
- Full suite ≥ 692 tests, 0 failures.
- Release build green.
- All existing + new grep bans clean.

---

## Phase B — AppRouter + EntryFormBody refactor

**Theme:** Extract navigation/presentation state into `AppRouter`; consolidate `NewEntrySheet` / `EditEntrySheet` into shared `EntryFormBody`.

### B.1 — Extract AppRouter

- **Objective:** Create `@Observable @MainActor final class AppRouter` owned by `AppState`. Move 5 `is*Presented` flags + `selectedFolder` + `selectedEntryID` from `AppState` into `AppRouter`. Expose imperative API: `presentNewEntry()`, `presentEditEntry()`, `presentMoveEntry()`, `presentDeleteConfirmation()`, `dismissAll()`, `selectEntry(_:)`, `selectFolder(_:)`.
- **Files to create:** `Kizba/Presentation/AppRouter.swift`
- **Files to modify:** `Kizba/Presentation/AppState.swift` — add `let router: AppRouter`; replace direct flag access with `router.*` proxy computed properties (temporary, removed in B.3). All view files and models referencing `appState.is*Presented` or `appState.selectedEntryID` — update to `appState.router.*`.
- **Verification:** Full suite green; release build green.
- **DoD:** `AppRouter` exists; `AppState.router` is the single owner; all presentation flags route through `AppRouter`.
- **Risks:** Large mechanical diff across many view files. Stage via proxy properties to reduce blast radius.
- **Commit:** `refactor(mvp3-b1): extract AppRouter from AppState`

### B.2 — Extract EntryFormBody

- **Objective:** Create `EntryFormBody<Header: View, Footer: View>` shared view component. `NewEntrySheet` and `EditEntrySheet` become thin wrappers providing header/footer slots and `pathFieldEnabled` parameter. Generate sub-sheet `@State` model lives in `EntryFormBody`.
- **Files to create:** `Kizba/Presentation/Entries/EntryFormBody.swift`
- **Files to modify:** `Kizba/Presentation/Entries/NewEntrySheet.swift`, `Kizba/Presentation/Entries/EditEntrySheet.swift` — reduce to thin wrappers.
- **Verification:** Full suite green; release build green; both sheets render correctly (manual check).
- **DoD:** `EntryFormBody` exists; `NewEntrySheet` and `EditEntrySheet` are ≤ 40 LOC each; Generate sub-sheet `@State` rule consolidated.
- **Risks:** Generic view with slots can be tricky for SwiftUI type inference. Keep slot types concrete if needed.
- **Commit:** `refactor(mvp3-b2): extract EntryFormBody — consolidate New/Edit sheet bodies`

### B.3 — Remove AppState proxy properties

- **Objective:** Remove temporary proxy computed properties from `AppState` that delegate to `AppRouter`. All call sites now use `appState.router.*` directly.
- **Files to modify:** `Kizba/Presentation/AppState.swift`, any remaining call sites.
- **Verification:** Full suite green; `rg 'appState\.is.*Presented' Kizba/Presentation` returns 0 hits (all routed through `appState.router`).
- **DoD:** No proxy properties remain; `AppState` is clean.
- **Commit:** `refactor(mvp3-b3): remove AppState proxy properties — AppRouter is canonical`

### B.4 — Phase B regression sweep

- **Objective:** Verify full suite, grep bans, release build after B.1–B.3.
- **Files to modify:** `.ai/handoff.md`
- **Verification:** All verification commands exit 0.
- **DoD:** Phase B complete; Phase C can begin.
- **Commit:** `chore(mvp3-b4): Phase B regression sweep — all green`

### Phase B DoD

- `AppRouter` owns all presentation flags and selection state.
- `EntryFormBody` consolidates shared form layout; `NewEntrySheet` and `EditEntrySheet` are thin wrappers.
- No proxy properties remain on `AppState`.
- Full suite green; release build green.

---

## Phase C — FSEvents auto-refresh

**Theme:** Watch the password store directory for external changes; emit `.bulk` events to trigger re-list.

### C.1 — StoreWatching protocol + FakeStoreWatcher

- **Objective:** Define `StoreWatching` protocol with `start(path:)`, `stop()`, `var events: AsyncStream<StoreWatchEvent>`. Create `FakeStoreWatcher` test double in `KizbaTests/Fixtures/`.
- **Files to create:** `Kizba/Domain/Protocols/StoreWatching.swift`, `KizbaTests/Fixtures/FakeStoreWatcher.swift`
- **Verification:** Compiles; existing suite green.
- **DoD:** Protocol defined; fake compiles and is usable in tests.
- **Risks:** None.
- **Commit:** `feat(mvp3-c1): StoreWatching protocol + FakeStoreWatcher`

### C.2 — FSEventsStoreWatcher implementation

- **Objective:** Implement `FSEventsStoreWatcher: StoreWatching` using CoreServices `FSEventStream` API. 350 ms trailing-edge debounce. Emits `.changed` events (no per-path delta — all events map to `.bulk` downstream). `@unchecked Sendable` with internal serial `DispatchQueue`.
- **Files to create:** `Kizba/Infrastructure/FSEvents/FSEventsStoreWatcher.swift`
- **Verification:** Opt-in test gated by `KIZBA_FSEVENTS_TEST=1` env var; manual verification by touching a `.gpg` file in the store.
- **DoD:** Watcher starts/stops cleanly; debounce works; events flow.
- **Risks:** FSEvents callback is C-function-pointer based; requires careful bridging. `FSEventStreamRef` is not Sendable.
- **Commit:** `feat(mvp3-c2): FSEventsStoreWatcher — CoreServices FSEventStream integration`

### C.3 — Wire StoreWatching into LivePassManager

- **Objective:** `LivePassManager` owns optional `StoreWatching`. On watcher events, call `scanner.invalidate(storeRoot:)` then emit `.bulk` to all `changes` subscribers. Wire in `AppEnvironment.live()`.
- **Files to modify:** `Kizba/Infrastructure/Pass/LivePassManager.swift`, `Kizba/Presentation/AppEnvironment.swift`
- **Verification:** Full suite green; manual test: `touch ~/.password-store/test.gpg` → list refreshes within ~500ms.
- **DoD:** External FS changes trigger automatic re-list in the UI.
- **Risks:** Debounce timing; ensure watcher stops on app termination.
- **Commit:** `feat(mvp3-c3): wire StoreWatching into LivePassManager — auto-refresh on FS changes`

### C.4 — FSEvents tests

- **Objective:** Unit tests for debounce logic (using `FakeStoreWatcher`); opt-in integration test for real FSEvents (gated by `KIZBA_FSEVENTS_TEST=1`).
- **Files to create:** `KizbaTests/FSEventsStoreWatcherTests.swift` (opt-in), `KizbaTests/LivePassManagerFSEventsTests.swift` (unit, using fake)
- **Verification:** Unit tests run in default suite; integration tests skipped without env var.
- **DoD:** ≥ 5 new tests covering start/stop/debounce/bulk-emission.
- **Commit:** `test(mvp3-c4): FSEvents unit + opt-in integration tests`

### C.5 — Phase C regression sweep

- **Objective:** Verify full suite, grep bans, release build after C.1–C.4.
- **Files to modify:** `.ai/handoff.md`
- **Verification:** All verification commands exit 0.
- **DoD:** Phase C complete; Phase D can begin.
- **Commit:** `chore(mvp3-c5): Phase C regression sweep — all green`

### Phase C DoD

- `StoreWatching` protocol + `FSEventsStoreWatcher` + `FakeStoreWatcher` exist.
- `LivePassManager` emits `.bulk` on FS changes with 350ms debounce.
- Opt-in FSEvents integration test passes locally.
- Full suite green; release build green.

---

## Phase D — Accessibility medium-priority fixes

**Theme:** Address the 5 medium-priority gaps from `.ai/a11y-audit.md`.

### D.1 — Audit and fix medium-priority a11y gaps

- **Objective:** Address the 5 medium-priority accessibility gaps documented in `.ai/a11y-audit.md`:
  1. VoiceOver labels for toolbar buttons (ensure all have `accessibilityLabel`).
  2. Focus management after sheet dismissal (return focus to trigger).
  3. Keyboard navigation in entry list (arrow keys + Enter to reveal).
  4. Reduce Motion compliance for any remaining animations.
  5. Dynamic Type support for custom text styles.
- **Files to modify:** Various view files in `Kizba/Presentation/`.
- **Verification:** Manual VoiceOver walkthrough; full suite green.
- **DoD:** All 5 medium-priority gaps addressed; `.ai/a11y-audit.md` updated with resolution notes.
- **Risks:** Some fixes may require SwiftUI workarounds on macOS 14.
- **Commit:** `fix(mvp3-d1): address medium-priority a11y gaps from audit`

### D.2 — A11y test coverage

- **Objective:** Add test assertions for accessibility labels, traits, and hints where programmatically verifiable.
- **Files to modify:** Existing test files or new `KizbaTests/AccessibilityTests.swift`.
- **Verification:** Full suite green; new tests pass.
- **DoD:** ≥ 5 new a11y-related test assertions.
- **Commit:** `test(mvp3-d2): accessibility test coverage for medium-priority fixes`

### D.3 — Phase D regression sweep

- **Objective:** Verify full suite, grep bans, release build after D.1–D.2.
- **Files to modify:** `.ai/handoff.md`
- **Verification:** All verification commands exit 0.
- **DoD:** Phase D complete; Phase E can begin.
- **Commit:** `chore(mvp3-d3): Phase D regression sweep — all green`

### Phase D DoD

- All 5 medium-priority a11y gaps addressed.
- `.ai/a11y-audit.md` updated.
- ≥ 5 new a11y test assertions.
- Full suite green; release build green.

---

## Phase E — Touch ID per-reveal gate

**Theme:** Optional biometric authentication before secret reveal. Default OFF; opt-in via Settings toggle.

### E.1 — BiometricAuthenticating protocol + FakeBiometricAuthenticator

- **Objective:** Define `BiometricAuthenticating` protocol in `Domain/Protocols/` with `func authenticate(reason: String) async throws -> Bool` and `var isAvailable: Bool { get }`. Protocol stays free of `LAError` — mapping happens inside the implementation. Create `FakeBiometricAuthenticator` in `KizbaTests/Fixtures/`.
- **Files to create:** `Kizba/Domain/Protocols/BiometricAuthenticating.swift`, `KizbaTests/Fixtures/FakeBiometricAuthenticator.swift`
- **Verification:** Compiles; existing suite green.
- **DoD:** Protocol defined; fake is configurable (success/failure/unavailable).
- **Commit:** `feat(mvp3-e1): BiometricAuthenticating protocol + FakeBiometricAuthenticator`

### E.2 — LocalAuthBiometricAuthenticator implementation

- **Objective:** Implement `LocalAuthBiometricAuthenticator: BiometricAuthenticating` using `LocalAuthentication` framework. Fresh `LAContext` per `authenticate()` call. `@unchecked Sendable` (fresh context ensures safety). Maps `LAError` to domain errors internally.
- **Files to create:** `Kizba/Infrastructure/Auth/LocalAuthBiometricAuthenticator.swift`
- **Verification:** Manual test on device with Touch ID; unit tests use fake.
- **DoD:** Implementation compiles; manual Touch ID prompt works.
- **Risks:** `LAContext` is not Sendable; `@unchecked Sendable` wrapper documented.
- **Commit:** `feat(mvp3-e2): LocalAuthBiometricAuthenticator — LAContext integration`

### E.3 — Wire Touch ID into EntryDetailModel

- **Objective:** Add `requireBiometricForReveal: Bool` setting to `SettingsStoring`. In `EntryDetailModel`, gate `revealSecret()` behind biometric check when setting is ON and biometric is available. Silent bypass when unavailable.
- **Files to modify:** `Kizba/Domain/Protocols/SettingsStoring.swift`, `Kizba/Infrastructure/Settings/UserDefaultsSettingsStore.swift`, `Kizba/Presentation/Entries/EntryDetailModel.swift`, `Kizba/Presentation/AppEnvironment.swift`
- **Verification:** Full suite green; manual test: enable Touch ID in Settings → reveal requires fingerprint.
- **DoD:** Setting wired end-to-end; reveal gated; silent bypass when unavailable.
- **Commit:** `feat(mvp3-e3): wire Touch ID gate into EntryDetailModel reveal flow`

### E.4 — Settings UI for Touch ID toggle

- **Objective:** Add Touch ID toggle to Settings view. Show availability status. Disable toggle when biometric hardware unavailable.
- **Files to modify:** `Kizba/Presentation/Settings/SettingsView.swift`, `Kizba/Presentation/Settings/SettingsModel.swift`
- **Verification:** Full suite green; manual verification in Settings.
- **DoD:** Toggle visible; respects hardware availability.
- **Commit:** `feat(mvp3-e4): Settings UI — Touch ID toggle with availability check`

### E.5 — Touch ID tests

- **Objective:** Unit tests for biometric gate in `EntryDetailModel` using `FakeBiometricAuthenticator`. Test cases: enabled+available+success → reveal; enabled+available+failure → no reveal; enabled+unavailable → silent bypass → reveal; disabled → reveal without prompt.
- **Files to create:** `KizbaTests/BiometricRevealTests.swift`
- **Verification:** Full suite green; ≥ 6 new tests.
- **DoD:** All biometric gate paths covered.
- **Commit:** `test(mvp3-e5): BiometricRevealTests — Touch ID gate unit tests`

### E.6 — Phase E regression sweep

- **Objective:** Verify full suite, grep bans, release build after E.1–E.5.
- **Files to modify:** `.ai/handoff.md`
- **Verification:** All verification commands exit 0.
- **DoD:** Phase E complete; Phase F can begin.
- **Commit:** `chore(mvp3-e6): Phase E regression sweep — all green`

### Phase E DoD

- `BiometricAuthenticating` protocol + `LocalAuthBiometricAuthenticator` + `FakeBiometricAuthenticator` exist.
- Touch ID gate wired into `EntryDetailModel.revealSecret()`.
- Settings toggle for Touch ID with availability check.
- ≥ 6 new biometric gate tests.
- Full suite green; release build green.

---

## Phase F — Polish & release

**Theme:** Final polish, documentation, regression sweep, release preparation.

### F.1 — README update for MVP 3

- **Objective:** Update `README.md` with MVP 3 feature list, updated known limitations, updated deferrals section.
- **Files to modify:** `README.md`
- **Verification:** File reads correctly; no broken links.
- **DoD:** README reflects MVP 3 state.
- **Commit:** `docs(mvp3-f1): README — MVP 3 feature list and updates`

### F.2 — Update .ai/a11y-audit.md

- **Objective:** Mark medium-priority items as resolved; document any new gaps discovered during MVP 3; update low-priority items for MVP 4 consideration.
- **Files to modify:** `.ai/a11y-audit.md`
- **Verification:** File is internally consistent.
- **DoD:** Audit reflects post-MVP 3 state.
- **Commit:** `docs(mvp3-f2): a11y-audit — mark MVP 3 resolutions`

### F.3 — Update .ai/sequoia-smoke.md

- **Objective:** Add FSEvents and Touch ID entries to the Sequoia smoke checklist.
- **Files to modify:** `.ai/sequoia-smoke.md`
- **Verification:** File updated.
- **DoD:** Checklist covers new MVP 3 surfaces.
- **Commit:** `docs(mvp3-f3): sequoia-smoke — add FSEvents + Touch ID entries`

### F.4 — Confirm decisions in .ai/decisions.md

- **Objective:** Add MVP 3 resolution entries confirming or amending the 20 planning decisions from `2026-05-10 — MVP 3 (planning locked)`.
- **Files to modify:** `.ai/decisions.md`
- **Verification:** Decisions log is append-only and internally consistent.
- **DoD:** All 20 planning decisions have resolution entries.
- **Commit:** `docs(mvp3-f4): decisions — MVP 3 resolution entries`

### F.5 — Opt-in E2E verification

- **Objective:** Run full E2E suite with `KIZBA_E2E=1` and `KIZBA_FSEVENTS_TEST=1`. Verify all pass.
- **Files to modify:** None (verification only).
- **Verification:** All opt-in tests pass locally.
- **DoD:** E2E green.
- **Commit:** (no commit — verification only)

### F.6 — Final regression sweep

- **Objective:** Full suite, all grep bans, repo hygiene, release build. Mark MVP 3 complete.
- **Files to modify:** `.ai/handoff.md`
- **Verification:**
  ```sh
  xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS'
  xcodebuild -scheme Kizba -project Kizba.xcodeproj -configuration Release -destination 'platform=macOS' build
  rg -n '\bas!' Kizba
  rg -n 'Logger.*stdin|print\(.*stdin' Kizba
  find . -name .DS_Store -not -path '*/.git/*'
  ```
- **DoD:** All commands exit 0; suite ≥ 742 tests, 0 failures; release build green; MVP 3 ships.
- **Commit:** `chore(mvp3-f6): final regression sweep — MVP 3 ships`

### Phase F DoD

- README, a11y-audit, sequoia-smoke, decisions all updated.
- E2E + FSEvents opt-in tests green.
- Full suite ≥ 742 tests, 0 failures.
- Release build green.
- MVP 3 complete.

---

## Cross-cutting workstreams

| Workstream | Applies to | Rule |
|---|---|---|
| Grep bans | Every task | `as!`, `Logger.*stdin`, `print(.*stdin` — 0 hits in `Kizba/` |
| SourceGrepTests | A.2, A.3, and any new grep rules | Run after every task touching `Kizba/` source |
| Security non-conformances | Any new types holding secrets | NOT Codable / NOT CustomStringConvertible / NOT CustomDebugStringConvertible |
| Code review checklist | Every PR | Review against `.ai/code-review-checklist.md` |
| Commit message format | Every commit | `type(mvp3-XX): description` |

## Test plan

| Phase | Expected new tests | Cumulative |
|---|---|---|
| A | +2 (grep rules) | ~694 |
| B | +0 (refactor, existing tests cover) | ~694 |
| C | +8 (FSEvents unit + integration) | ~702 |
| D | +5 (a11y assertions) | ~707 |
| E | +6 (biometric gate) | ~713 |
| F | +0 (docs + verification) | ~713 |

Note: Exact counts may vary; target is ≥ 742 total (692 baseline + ~50 net new per decisions.md).

## Manual verification matrix

| Surface | Verification |
|---|---|
| FSEvents auto-refresh | `touch ~/.password-store/test.gpg` → list refreshes within ~500ms |
| Touch ID reveal gate | Enable in Settings → reveal entry → Touch ID prompt appears |
| Touch ID unavailable bypass | Disable Touch ID in System Settings → reveal works without prompt |
| VoiceOver toolbar buttons | All toolbar buttons announce labels |
| Reduce Motion | Animations collapse to instant |
| New/Edit sheet focus | Focus returns to trigger after dismissal |
| AppRouter navigation | All sheets open/close correctly via router API |

## Suggested current step

**A.3 — Sheet model constructor grep rule.** A.1 and A.2 are completed. Proceed with A.3 → A.4 → A.5 to close Phase A, then Phase B.
