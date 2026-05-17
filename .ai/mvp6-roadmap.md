# MVP6 — UX backlog closure (Settings tabs, Recents controls, Tooltips, Biometric gating, Help setup, Polish)

## Status of prior milestone

- MVP5 shipped: Search ⌘K + Favorites + Recents + Menu-bar + Polish.
- Test suite: 1000 tests, 0 failures.
- Release build: clean, no warnings.
- Grep bans: clean.

## Goal

Close the 7-item user-facing UX backlog raised after MVP5 acceptance:
1. Recents: hide/show toggle + configurable limit + collapsible sidebar section.
2. Settings: re-organise into Xcode-style tabs, add Save feedback, add info tooltips.
3. App-wide `.help(...)` tooltips on all interactive controls.
4. Biometric toggle: hardware-gated visibility + biometric confirmation to disable.
5. Help: add three setup topics (pass/gpg install, git remote, pinentry).
6. Polish: docs sync (README, decisions, sequoia-smoke, a11y-audit) + final regression.

The deliverable is shipped UX, not new architecture. No new third-party deps, no new platform targets, no schema migrations.

## Total effort estimate

- Realistic range: **7–10 working days** for one focused worker.
  - Phase A (Recents settings + fold): ~1 day.
  - Phase B (Settings tabs + Save feedback + InfoTooltip DS): ~2 days.
  - Phase C (App-wide tooltips + advisory grep rule): ~1 day.
  - Phase D (Biometric availability + confirm-to-disable): ~1.5 days.
  - Phase E (Help setup topics + optional deep-links): ~1 day.
  - Phase F (Polish, docs, regression): ~0.5–1 day.
  - Buffer for review/rework: ~1–1.5 days.

## Durable constraints (apply to every task in every phase)

- Swift 5.10, macOS 14, `SWIFT_STRICT_CONCURRENCY = complete`.
- No `as!`. No third-party deps. No stdin/stdout logging (`Logger.*stdin|print\(.*stdin` banned).
- `@Observable` + manual DI via initializers; actor-based stores.
- Design-system tokens only in `Kizba/Presentation/Features/**` outside `Presentation/DesignSystem/`:
  - No inline `Color.<name>` (use `theme.colors.*`).
  - No numeric `cornerRadius:` (use `theme.radius.*`).
  - No numeric `.opacity(<literal>)` (use semantic tokens or `0` for hidden).
  - Use `FormSection`, `FormFieldRow`, `.kizba*` view modifiers.
- English-only in code, comments, commits, docs, UI strings.
- `SourceGrepTests` must remain green.
- No new product locales (no i18n infra; deferred to a future MVP).

## Definition of Done (MVP6)

1. All Phase A–F acceptance criteria met (per-phase below).
2. Full Debug test suite green; net new tests added in A/B/D/E.
3. Release build green, no warnings.
4. `rg -n '\bas!\b' Kizba/` → 0 matches.
5. `rg -n 'Logger.*stdin|print\(.*stdin' Kizba/ KizbaTests/` → 0 matches.
6. Design-system grep rules in `SourceGrepTests` green (incl. any new advisory rule from C).
7. `README.md`, `.ai/decisions.md`, `.ai/sequoia-smoke.md`, `.ai/a11y-audit.md` updated.
8. No new third-party dependencies; no new schema or settings migrations beyond the documented `recentsLimit` / `showRecents` / `sidebar.recentsExpanded` keys.
9. Settings keys defaulted such that an upgrading user sees: Recents visible, limit = previous behaviour-compatible (see A.1 decision), tabs default to "General".

---

## Phase A — Recents settings + fold/unfold  (priority: high)

### Goal

Give the user control over the Recents sidebar section: hide/show entirely, set the cap, and collapse the section in-place. Replace the hard-coded `maxCount = 20` default in stores with a settings-driven default.

### Open decision (resolve in A.1)

- **Recents limit range:** `3...7`, default = **7** (preserves "feels like before" relative to MVP5 ≤7 visible rows in typical use; 20 was an internal cap, not a presentation target). If product disagrees, change default to 5; range stays 3...7.
- The previous hard-coded cap of 20 in stores is removed in favour of the settings-driven default.

### Tasks

#### A.1 — SettingsKeys + default migration

**Description:** Introduce two new setting keys and centralise the recents default so stores no longer hard-code `20`.

**Files:**
- `Kizba/Infrastructure/Settings/SettingsKeys.swift` (or wherever keys live) — add:
  - `static let showRecents = "kizba.settings.showRecents"` (Bool, default `true`).
  - `static let recentsLimit = "kizba.settings.recentsLimit"` (Int, default `7`, bounds `3...7`).
  - `static let defaultRecentsLimit: Int = 7` (single source of truth used by stores when no settings store is available, e.g. tests).
- `Kizba/Domain/Protocols/SettingsStoring.swift` — add accessors for the two new keys (mirror existing pattern).
- `Kizba/Infrastructure/Settings/UserDefaultsSettingsStore.swift` — implement read/write with bounds clamping for `recentsLimit`.

**Tests:**
- `KizbaTests/Settings/SettingsKeysTests.swift` — defaults present, bounds clamped on write (2 → 3, 99 → 7).
- `KizbaTests/Settings/UserDefaultsSettingsStoreTests.swift` — round-trip both keys.

**Verification:**
```sh
xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' \
  -only-testing:KizbaTests/SettingsKeysTests \
  -only-testing:KizbaTests/UserDefaultsSettingsStoreTests
```

**Branch:** `mvp6/a1-settings-keys-recents`
**Commit:** `feat(settings): add showRecents + recentsLimit keys with clamp (MVP6.A.1)`
**Difficulty:** low
**Risks:** silent default drift if any other code reads `20` literally — `rg -n '\b20\b' Kizba/Infrastructure/Recents/` before/after to confirm.

#### A.2 — Recents store: actor mutator + default replacement

**Description:** Replace `let maxCount` with mutable state on the actor and expose `setMaxCount(_:) async` that truncates and emits a `recentsChanged` event. Apply to both production and DEBUG fake.

**Files:**
- `Kizba/Domain/Protocols/RecentEntriesStoring.swift` — add `func setMaxCount(_ newValue: Int) async` to the protocol.
- `Kizba/Infrastructure/Recents/UserDefaultsRecentEntriesStore.swift`:
  - Change `let maxCount` → `var maxCount`.
  - Constructor default: read `SettingsKeys.defaultRecentsLimit`.
  - `setMaxCount(_:)`: clamp to `3...7`, truncate `entries` if needed, persist, then yield to `changes` continuation.
- `Kizba/Infrastructure/Recents/InMemoryRecentEntriesStore.swift` (`#if DEBUG`) — mirror the change.

**Tests:**
- `KizbaTests/Recents/RecentEntriesStoreTests.swift`:
  - `testSetMaxCount_truncatesAndEmits` — populate 7 entries, set to 4, expect 4 newest retained and exactly one `changes` event.
  - `testSetMaxCount_clamps` — pass 1 → ends at 3; pass 99 → ends at 7.
  - `testInit_usesDefaultFromSettingsKey` — constructed without explicit max, count cap = `SettingsKeys.defaultRecentsLimit`.

**Verification:**
```sh
xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' \
  -only-testing:KizbaTests/RecentEntriesStoreTests
```

**Branch:** `mvp6/a2-recents-store-mutator`
**Commit:** `refactor(recents): mutable maxCount + setMaxCount actor API (MVP6.A.2)`
**Difficulty:** medium
**Risks:**
- Order of emission vs persistence — persist first, then emit, to avoid observers reading stale `UserDefaults`.
- `InMemoryRecentEntriesStore` is `#if DEBUG`, so Release builds cannot accidentally use it. Add a comment block calling this out explicitly and a Release-build advisory test (`#if !DEBUG XCTSkip` or compile-time check via `SourceGrepTests` ensuring `InMemoryRecentEntriesStore` only appears inside `#if DEBUG`).

#### A.3 — Sidebar: DisclosureGroup + showRecents gating

**Description:** Wrap Recents section in a `DisclosureGroup`, persist expansion via `@AppStorage("kizba.sidebar.recentsExpanded")` (default `true`). When `showRecents == false` the section is not rendered at all.

**Files:**
- `Kizba/Presentation/Features/Sidebar/SidebarView.swift`:
  - Read `@AppStorage("kizba.settings.showRecents") private var showRecents: Bool = true`.
  - `@AppStorage("kizba.sidebar.recentsExpanded") private var recentsExpanded: Bool = true`.
  - Replace existing Recents section header + body with `DisclosureGroup(isExpanded: $recentsExpanded) { ... } label: { ... }` styled via DS.
  - Wrap the whole block in `if showRecents { ... }`.
- Possibly extract a small `SidebarRecentsSection` view to keep `SidebarView` readable; place under `Presentation/Features/Sidebar/`.

**Tests:**
- `KizbaTests/Sidebar/RecentsModelTests.swift` — when store's `maxCount` shrinks, model's exposed list reflects the new cap on next refresh.
- Snapshot-like assertion (if existing snapshot infra) for sidebar with `showRecents = false` → no Recents header in dump. Otherwise: a unit test on a `SidebarPresenter`-style helper that returns whether the section is included.

**Verification:**
```sh
xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' \
  -only-testing:KizbaTests/Sidebar
```

**Branch:** `mvp6/a3-sidebar-recents-disclosure`
**Commit:** `feat(sidebar): collapsible Recents section + showRecents gate (MVP6.A.3)`
**Difficulty:** low
**Risks:** `DisclosureGroup` default chevron styling — verify it conforms to `.kizba*` design tokens; if not, wrap with a DS-styled label.

#### A.4 — SettingsView wiring (General tab placeholder)

**Description:** Surface `showRecents` Toggle and `recentsLimit` Stepper in Settings (still pre-tabs; will move into `GeneralTab` in Phase B). On Save, call `await environment.recentStore.setMaxCount(model.recentsLimit)`.

**Files:**
- `Kizba/Presentation/Features/Settings/SettingsModel.swift`:
  - Add `var showRecents: Bool`, `var recentsLimit: Int`.
  - Load from `SettingsStoring` on init; persist on `save()`.
  - After persisting `recentsLimit`, dispatch `Task { await environment.recentStore.setMaxCount(self.recentsLimit) }`.
- `Kizba/Presentation/Features/Settings/SettingsView.swift` — add a section "Recents" with Toggle + Stepper (range `3...7`).

**Tests:**
- `KizbaTests/Settings/SettingsModelTests.swift`:
  - `testShowRecents_persists`
  - `testRecentsLimit_persistsAndClamps`
  - `testSave_callsSetMaxCountOnStore` (with a fake `RecentEntriesStoring` capturing calls).

**Verification:**
```sh
xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' \
  -only-testing:KizbaTests/Settings/SettingsModelTests
```

**Branch:** `mvp6/a4-settings-recents-wiring`
**Commit:** `feat(settings): recents toggle + limit stepper wired to store (MVP6.A.4)`
**Difficulty:** low
**Risks:** Double-emission if `save()` writes both to defaults and triggers a store callback that also writes — confirm the store's `setMaxCount` only persists its own state (entries cap), not the settings key.

### Phase A acceptance criteria

- `SettingsKeys` exposes `showRecents`, `recentsLimit`, `defaultRecentsLimit`.
- No `maxCount = 20` literal remains in `Kizba/Infrastructure/Recents/**`.
- Sidebar Recents section is collapsible and disappears entirely when `showRecents == false`.
- Settings UI exposes both controls; Save propagates limit to the store; truncation observable in the sidebar within one event loop.
- All new tests pass; existing suite remains green.

---

## Phase B — Settings UI: tabs + Save feedback + info tooltips  (priority: high)

### Goal

Re-organise Settings into Xcode-style tabs (`General`, `Security`, `Git`, `Advanced`), add dirty-tracking + transient "Saved ✓" feedback, and introduce a reusable `InfoTooltip` design-system component used to replace verbose inline help text.

### Tasks

#### B.1 — InfoTooltip DS component

**Description:** New design-system component: a `info.circle` SF Symbol button that opens a `.popover` with the supplied text. Accessible label required.

**Files:**
- `Kizba/Presentation/DesignSystem/Components/InfoTooltip.swift` — new view:
  - Init: `text: String`, `accessibilityLabel: String`, optional `title: String?`.
  - Renders SF Symbol button styled via DS; `.popover(isPresented:)` with padded Text body using `theme.typography.caption` and `theme.spacing.*`.
- `Kizba/Presentation/DesignSystem/Components/FormFieldRow.swift` — add optional `infoText: String? = nil` initialiser parameter; when present, render an `InfoTooltip` trailing the label and suppress the existing helpText to avoid duplication.

**Tests:**
- `KizbaTests/DesignSystem/InfoTooltipTests.swift` — accessibility label set; popover state toggles; default closed.

**Verification:**
```sh
xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' \
  -only-testing:KizbaTests/DesignSystem/InfoTooltipTests
```

**Branch:** `mvp6/b1-info-tooltip-ds`
**Commit:** `feat(ds): InfoTooltip + FormFieldRow.infoText (MVP6.B.1)`
**Difficulty:** low
**Risks:** DS grep rules — make sure all colours/radii/spacing inside InfoTooltip use tokens.

#### B.2 — Settings dirty-tracking + saveState

**Description:** Add snapshot-based dirty tracking and a `saveState` enum.

**Files:**
- `Kizba/Presentation/Features/Settings/SettingsModel.swift`:
  - On `load()`, capture `initialSnapshot: SettingsSnapshot` (private struct of all editable fields).
  - Computed `var hasChanges: Bool { currentSnapshot != initialSnapshot }`.
  - `enum SaveState: Equatable { case idle, saving, saved }`; `var saveState: SaveState = .idle`.
  - `func save() async` flow: `saveState = .saving` → persist → refresh snapshot → `saveState = .saved` → `Task.sleep(1.5s)` → `saveState = .idle`.
  - Save button enablement: `hasChanges && saveState != .saving`.

**Tests:**
- `KizbaTests/Settings/SettingsModelTests.swift`:
  - `testHasChanges_falseAfterLoad`
  - `testHasChanges_trueAfterMutation_falseAfterSave`
  - `testSaveState_transitions_idle_saving_saved_idle`
  - `testReset_clearsHasChanges`

**Verification:**
```sh
xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' \
  -only-testing:KizbaTests/Settings/SettingsModelTests
```

**Branch:** `mvp6/b2-settings-dirty-savestate`
**Commit:** `feat(settings): dirty tracking + transient saveState (MVP6.B.2)`
**Difficulty:** medium
**Risks:** Time-based transition flakiness in tests — inject a clock or use `Task.sleep` with a parametrisable delay; tests pass a near-zero delay.

#### B.3 — TabView split into General / Security / Git / Advanced

**Description:** Replace `ScrollView { VStack { FormSection... } }` with `TabView`. One tab file per area for maintainability.

**Files:**
- `Kizba/Presentation/Features/Settings/SettingsView.swift` — becomes a thin host: `TabView { GeneralTab(...); SecurityTab(...); GitTab(...); AdvancedTab(...) }` + shared bottom footer (version + Save/Reset row) once, outside the TabView via `VStack`. Remove the previous `.safeAreaInset(.bottom)` per-tab pattern.
- New files under `Kizba/Presentation/Features/Settings/Tabs/`:
  - `GeneralTab.swift` — clipboard auto-clear, menu bar, Recents (from A.4 — moved here).
  - `SecurityTab.swift` — Touch ID (also touched in Phase D).
  - `GitTab.swift` — git timeout, store path.
  - `AdvancedTab.swift` — binaries (moved out of General/Security), re-detect button.
- Each tab takes the `SettingsModel` as `@Bindable` and uses `Form` (or `VStack { FormSection... }` — pick `Form` and apply DS theming for consistency with macOS Settings).

**Tests:**
- Existing `SettingsViewTests` (if any) updated to reflect new structure.
- Snapshot test (if infra exists) for each tab.

**Verification:**
```sh
xcodebuild build -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS'
xcodebuild test  -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' \
  -only-testing:KizbaTests/Settings
```

**Branch:** `mvp6/b3-settings-tabs`
**Commit:** `refactor(settings): TabView split General/Security/Git/Advanced (MVP6.B.3)`
**Difficulty:** medium
**Risks:**
- macOS Settings scenes have implicit sizing — verify each tab renders with stable height; consider `.frame(minWidth: 480)` at the host.
- The version footer must remain a single source; do not duplicate inside each tab.

#### B.4 — InfoTooltip rollout in Settings

**Description:** Replace verbose `helpText` strings with `InfoTooltip` for the controls listed below; keep short labels.

**Targets:**
- Clipboard auto-clear delay (General).
- Show in menu bar (General).
- Touch ID (Security).
- Git timeout (Git).
- Store path (Git).
- Binary overrides (Advanced).

**Files:**
- The four `*Tab.swift` files from B.3.

**Tests:** advisory — covered by InfoTooltip tests; no new behaviour tests.

**Verification:** visual + grep `helpText:` in the four tab files to ensure no duplicate inline help remains next to tooltip-equipped rows.

**Branch:** `mvp6/b4-info-tooltips-settings`
**Commit:** `feat(settings): InfoTooltip on key controls (MVP6.B.4)`
**Difficulty:** low
**Risks:** A11y regression — keep an accessible label on every tooltip.

### Phase B acceptance criteria

- Settings opens with a TabView (4 tabs); persisting current tab not required.
- Save button disabled when no changes; "Saved ✓" appears for ~1.5s post-save.
- InfoTooltip available in DS and applied to ≥ 6 controls.
- No new design-system grep violations.

---

## Phase C — App-wide tooltips  (priority: high)

### Goal

Every interactive control that is not self-explanatory gains `.help(...)`. Shortcuts surfaced inline in the help text ("Save (⌘S)").

### Tasks

#### C.1 — Tooltip audit + rollout

**Files (audit & edit):**
- `Kizba/Presentation/Features/Settings/SettingsView.swift` + new `*Tab.swift` files (Save, Reset, Re-detect binaries, browse-pickers, Toggle/Stepper rows).
- `Kizba/Presentation/Features/Sidebar/SidebarView.swift` (section headers' interactive elements if any; star/clear buttons).
- `Kizba/Presentation/Features/MenuBar/MenuBarPopoverView.swift` (result rows: tooltip = full entry path; copy buttons).
- `Kizba/Presentation/Features/Git/**.swift` — audit `GitStatusBadge` and `GitActionsPopover` for missing `.help`.

**Format:**
- With shortcut: `"Action (⌘X)"`.
- Without: short imperative ("Re-detect binary paths").

**Tests:** N/A (UI text).

**Branch:** `mvp6/c1-tooltips-rollout`
**Commit:** `feat(a11y): .help tooltips across Settings/Sidebar/MenuBar/Git (MVP6.C.1)`
**Difficulty:** low
**Risks:** Tooltip text drift vs. shortcut keys — keep shortcut literals in one place where possible.

#### C.2 — Advisory grep rule (optional)

**Description:** Add a `SourceGrepTests` rule: every `Button` whose only label is `Image(systemName:)` in `Kizba/Presentation/Features/{Settings,Sidebar,MenuBar,Git}/**` must have `.help(` invoked in the same file. Implement as **advisory** (XCTSkip if disabled by env `KIZBA_GREP_TOOLTIPS=0`) to avoid blocking unrelated work.

**Files:**
- `KizbaTests/SourceGrepTests.swift` — new `testIconOnlyButtonsHaveHelp_inFeatures`.

**Verification:**
```sh
xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' \
  -only-testing:KizbaTests/SourceGrepTests
```

**Branch:** `mvp6/c2-grep-tooltip-rule`
**Commit:** `test(grep): advisory rule — icon-only buttons must have .help (MVP6.C.2)`
**Difficulty:** medium
**Risks:** false positives (e.g. Buttons with label outside the closure) — keep heuristic conservative; document the rule in the test docstring.

### Phase C acceptance criteria

- Every interactive control in the audited files has `.help(...)`.
- Advisory grep rule passes (or is correctly skipped when disabled).

---

## Phase D — Biometric hardware gating + confirm-to-disable  (priority: high)

### Goal

Hide the Touch ID toggle when the machine has no biometric hardware; when present and enabled, disabling requires a successful biometric authentication.

### Tasks

#### D.1 — Inject `BiometricAuthenticating` into SettingsModel

**Files:**
- `Kizba/Presentation/Features/Settings/SettingsModel.swift`:
  - Extend `init` with `biometricAuth: (any BiometricAuthenticating)?`.
  - Store as `private let biometricAuth`.
  - Add `var biometricAvailability: BiometricAvailability` computed from `biometricAuth?.isAvailable() ?? .unavailable(.hardwareUnavailable)`.
  - Add `func requestToggleBiometric(_ desired: Bool) async -> Result<Void, BiometricError>`:
    - If `desired == false && currentlyEnabled`: call `auth.authenticate(reason: "Confirm to disable Touch ID protection")`. On success, persist `false`. On failure, do nothing and return error so UI can banner.
    - If `desired == true`: persist `true` (no auth required on enable in this MVP — see decision below).
  - Update `KizbaApp.swift` and `AppEnvironment` to pass `environment.biometricAuth` to the model.

**Decision (record in `.ai/decisions.md`):**
- Enabling does not require a biometric prompt in MVP6 (matches macOS pattern for FileVault/Touch ID screens). If a future audit demands confirmation on enable, add a second flow.

#### D.2 — SecurityTab UI gating

**Files:**
- `Kizba/Presentation/Features/Settings/Tabs/SecurityTab.swift`:
  - If `biometricAvailability == .available`: render Toggle.
  - Else: render a disabled placeholder row "Touch ID is not available on this Mac" with an `InfoTooltip` explaining `availability` reason. Do NOT render an interactive Toggle.
  - On Toggle change attempt → call `await model.requestToggleBiometric(newValue)`; if failure, surface a transient banner ("Authentication was cancelled.").

#### D.3 — Fake biometric authenticator + tests

**Files:**
- `KizbaTests/Fixtures/FakeBiometricAuthenticator.swift` (create if absent) — configurable `availability`, configurable `authenticateResult: Result<Void, BiometricError>`, recorded calls.
- `KizbaTests/Settings/SettingsModelTests.swift`:
  - `testToggleBiometricOff_requiresAuth_successPersists`
  - `testToggleBiometricOff_authCancelled_leavesEnabled`
  - `testToggleBiometricOn_persistsWithoutAuth`
  - `testBiometricAvailability_propagatesFromAuth`

**Verification:**
```sh
xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' \
  -only-testing:KizbaTests/Settings/SettingsModelTests
```

**Branch:** `mvp6/d-biometric-gating`
**Commit:** `feat(security): biometric availability gating + confirm-to-disable (MVP6.D)`
**Difficulty:** medium
**Risks:**
- LAContext threading — must call from `@MainActor` per Apple guidance.
- A user with an enabled-but-now-unavailable biometric (hardware change) — model should treat `unavailable` as "show disabled informational row" without auto-flipping the persisted value; document this in the decision log.

### Phase D acceptance criteria

- Touch ID Toggle hidden on hardware without biometric support; informational row + InfoTooltip shown.
- Disabling requires successful biometric auth; cancel/fail leaves state on.
- Enabling persists without prompt (documented).
- Tests cover the four scenarios above.

---

## Phase E — Help: setup topics  (priority: medium)

### Goal

Add three guided setup topics to `HelpCatalog` so users can bootstrap their environment from inside the app.

### Tasks

#### E.1 — HelpCatalog: three new topics

**Files:**
- `Kizba/Presentation/Features/Help/HelpCatalog.swift`:
  - Append (do NOT insert in the middle — IDs are positional in existing tests):
    1. **Install and configure pass-store, gpg**
       - Sections: install (`brew install pass gnupg`), generate GPG key (`gpg --full-generate-key`), init store (`pass init <gpg-id>`), verify (`pass ls`), troubleshoot (warning block for "no secret key" errors), external doc links (passwordstore.org, gnupg.org).
    2. **Setup git remote**
       - Sections: `pass git init`, `pass git remote add origin <url>`, `pass git push -u origin master`, multi-device pull (`pass git pull --rebase`), warning about branch name on hosted services.
    3. **Configure pinentry**
       - Sections: `brew install pinentry-mac`, edit `~/.gnupg/gpg-agent.conf` adding `pinentry-program /opt/homebrew/bin/pinentry-mac` (Intel path warning block), `gpgconf --kill gpg-agent`, smoke-test `echo "test" | gpg --clearsign`.
  - Each topic uses `HelpBlock.command(...)`, `.commandSequence(...)`, `.warning(...)`, `.paragraph(...)` only.
  - Add first-class accessors on `HelpCatalog`, e.g. `static var setupPassAndGPG: HelpTopic`, `static var setupGitRemote: HelpTopic`, `static var configurePinentry: HelpTopic` (mirror `aeadMDCCompatibility`).

#### E.2 — Optional: Help menu deep-links

**Files:**
- `Kizba/App/KizbaApp.swift` (HelpCommands): add three `Button` items invoking `openWindow(id: "help", value: topicID)` for the new topics.

**Decision:** if `openWindow(id:value:)` plumbing isn't already in place for individual topic deep-linking, defer E.2 to a follow-up; topics are still reachable from the Help sidebar.

**Tests:**
- `KizbaTests/Help/HelpCatalogTests.swift`:
  - `testCatalog_containsThreeNewSetupTopics`
  - `testSetupPassAndGPG_hasExpectedBlockKinds`
  - `testSetupGitRemote_hasExpectedBlockKinds`
  - `testConfigurePinentry_hasExpectedBlockKinds`
  - Existing positional ID tests untouched (new topics appended at end).

**Verification:**
```sh
xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' \
  -only-testing:KizbaTests/Help/HelpCatalogTests
```

**Branch:** `mvp6/e-help-setup-topics`
**Commit:** `feat(help): setup topics for pass/gpg, git remote, pinentry (MVP6.E)`
**Difficulty:** low
**Risks:**
- IDs collisions if anything reads by index assumes specific length — keep tests asserting new topics by ID, not index.
- Apple Silicon vs Intel pinentry path — warning block explicit.

### Phase E acceptance criteria

- Three topics present, render with the right block kinds, accessible via the Help sidebar.
- All existing Help tests still green.

---

## Phase F — Polish, docs, regression  (priority: low)

### Tasks

#### F.1 — README

- `README.md`: new bullets in "What it does":
  - Settings re-organised into tabs (General / Security / Git / Advanced).
  - Touch ID toggle adapts to hardware availability and requires biometric confirmation to disable.
  - Recents section configurable (show/hide, 3–7) and collapsible.
  - Help app now includes setup topics for pass/gpg, git remote, pinentry.

#### F.2 — decisions.md

Append `## 2026-05-XX — MVP 6`:
- `recentsLimit` range chosen as 3...7, default 7; previous internal cap of 20 retired.
- `setMaxCount` mutates actor state and emits a single `changes` event after persistence.
- Recents sidebar section uses `DisclosureGroup` + `@AppStorage("kizba.sidebar.recentsExpanded")`.
- Settings uses macOS-native `TabView` (4 tabs). Bottom footer shared across tabs.
- `SettingsModel` adopts snapshot-based dirty tracking and a 1.5s transient `.saved` flash.
- `InfoTooltip` is the canonical replacement for verbose `helpText` strings.
- Biometric Toggle hardware-gated; disabling requires `LAContext` confirmation; enabling does not.
- Help topics appended (never inserted) to keep positional ID tests stable.
- No new dependencies. No locales added (i18n deferred).

#### F.3 — sequoia-smoke.md

Append rows:
- Recents toggle hides the sidebar section.
- Recents limit Stepper takes effect immediately; truncates the list.
- DisclosureGroup state persists across app restarts.
- Settings tabs switch with a single click; bottom footer remains visible.
- Save flashes "Saved ✓" then returns to idle; Save disabled with no changes.
- Touch ID toggle absent on a Mac without biometric hardware; informational row visible.
- Disabling Touch ID prompts biometric; cancel leaves it on.
- Help → new topics render with command blocks and warnings.

#### F.4 — a11y-audit.md

Append:
- **InfoTooltip**: accessibilityLabel mandatory; popover focusable; dismiss via Esc.
- **TabView**: each tab labeled; keyboard nav (⌃Tab) works.
- **Help setup topics**: code blocks announced as "code"; copy buttons labeled "Copy command".

#### F.5 — Final regression

```sh
xcodebuild test  -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS'
xcodebuild build -scheme Kizba -project Kizba.xcodeproj -configuration Release -destination 'platform=macOS'
rg -n '\bas!\b' Kizba/
rg -n 'Logger.*stdin|print\(.*stdin' Kizba/ KizbaTests/
rg -n '\b20\b' Kizba/Infrastructure/Recents/   # advisory — should be 0
```

**Expected:** 0 test failures; Release build clean; all `rg` zero matches.

**On failure:** capture in `.ai/build-errors.md`; do NOT inline-patch.

**Branch:** `mvp6/f-polish-docs-regression`
**Commit:** `docs(mvp6): README + decisions + smoke + a11y + regression (MVP6.F)`
**Difficulty:** low
**Risks:** Release-only warnings under strict concurrency around the new `setMaxCount` actor path.

### Phase F acceptance criteria

- Docs updated as specified.
- Full regression matrix green.

---

## Risk mitigation & sequencing

- **A before B**: B.3 (TabView) moves controls A.4 introduced. Doing A first keeps the diff small and lets B focus on layout.
- **B before C**: tooltip rollout (C) covers Settings tabs created in B; doing B first prevents touching the same files twice.
- **B before D**: SecurityTab from B.3 is the natural host for D's hardware-gated row.
- **C alongside D acceptable**: C touches a different concern (`.help(...)`) and rarely collides with D's logic edits.
- **E independent**: can run in parallel with anything; only touches HelpCatalog + tests.
- **F last**: requires all prior phases shipped.
- **Strict-concurrency hot spots**: actor mutator in A.2; LAContext bridging in D. Mitigate by routing both through `@MainActor`-aware boundaries and re-running the suite per task.
- **DS grep regressions**: every new view (InfoTooltip, SecurityTab informational row) must use tokens. Add a `grep --` sanity pass per phase commit.
- **Test ID positional fragility**: only ever append to `HelpCatalog.all`.

## First actionable work item

**Phase A.1 — SettingsKeys + default migration.**

- Branch: `mvp6/a1-settings-keys-recents`.
- Files: `SettingsKeys.swift`, `SettingsStoring.swift`, `UserDefaultsSettingsStore.swift`, two new test files.
- Verification:
  ```sh
  xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' \
    -only-testing:KizbaTests/SettingsKeysTests \
    -only-testing:KizbaTests/UserDefaultsSettingsStoreTests
  ```

## Handoff — next action

Replace `.ai/plan.md` with the **Phase A** plan (this roadmap's Phase A expanded to operational detail) and dispatch **smart-worker** on **Task A.1**.
