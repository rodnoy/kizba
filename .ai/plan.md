# MVP6 — Phase B: Settings Tabs + Save Feedback + InfoTooltip

## Status of prior phase

Phase A (Recents in Sidebar) — DONE. 4 commits landed on `main`. Test suite: 1019 tests, 0 failures. `SettingsModel.init` extended with `recentStore:`. Recents section appended to current `SettingsView` (ScrollView + VStack of `FormSection`s). `HelpModel.copiedBlockID` + `flashResetTask` established the 1500ms flash-feedback pattern that Phase B mirrors for Save state.

## Goal

Restructure Settings UX:
1. Introduce a reusable `InfoTooltip` DS component (greenfield — no `info.circle` popover exists yet).
2. Add dirty-tracking + Save state machine (`idle → saving → saved → idle`) to `SettingsModel`, with the Save button disabled when there are no changes.
3. Split the current monolithic Settings scroll into a `TabView` (General / Security / Git / Advanced) with a shared footer (Save / Reset / version) outside the tabs.
4. Roll out `InfoTooltip` to the key Settings controls, replacing inline `helpText` on those rows.

No behavioural changes to persistence, keychain, discovery, or recents. Touch ID is left as-is (full rework is Phase D).

## Constraints

- Swift 5.10, macOS 14, strict concurrency complete. `SettingsModel` stays `@MainActor @Observable`.
- DS-only styling: tokens from `theme.typography.*` / `theme.spacing.*` / `theme.colors.*` / `theme.radius.*`. No inline `Color.<name>`, numeric `cornerRadius:`, numeric `.opacity(0.x)` in `Kizba/Presentation/Features/**` outside DesignSystem.
- No new third-party deps. No localization layer — UI strings remain English literals.
- Existing `FormFieldRow` / `FormSection` APIs stay backwards-compatible (additive parameters only).
- Footer (Save / Reset + version) appears once, outside the `TabView`.
- Save flash duration injectable for tests (`savedFlashDuration: Duration = .milliseconds(1500)`).
- SourceGrepTests must stay green.

## Open decisions

- **ViewInspector availability** — check before B.3 tests; if vendored, add 4-tab smoke test; otherwise skip and rely on manual smoke.
- **Snapshot equality of binary-override `String?`** — treat `nil` and `""` as distinct (matches current persistence). Document in the snapshot struct.
- **`Reset` semantics** — Reset writes defaults via persistence and then rebuilds `initialSnapshot` (or calls `load()`) so `hasChanges == false` afterwards.
- **Tab order** — General / Security / Git / Advanced (matches user-facing frequency).

---

## Tasks

### B.1 — `InfoTooltip` DS component + `FormFieldRow` integration

**Description:** Add a reusable popover-based info tooltip and wire it into `FormFieldRow` via an additive `infoText:` parameter. When `infoText` is provided, render the `InfoTooltip` after the label and suppress the inline `helpText` for that row.

**Agent:** smart-worker

**Files:**
- NEW `Kizba/Presentation/DesignSystem/Components/InfoTooltip.swift`:
  - `struct InfoTooltip: View`
  - `init(text: String, accessibilityLabel: String, title: String? = nil)`
  - `@State private var isOpen = false`
  - Button with SF Symbol `info.circle` (DS-styled, `.buttonStyle(.plain)`, `.help(accessibilityLabel)`).
  - `.popover(isPresented: $isOpen, arrowEdge: .top) { ... }` body: optional bold `title` then `Text(text)` with `theme.typography.caption`, padded with `theme.spacing.*`, max width ~280pt.
  - `.accessibilityLabel(accessibilityLabel)` on the button.
- MOD `Kizba/Presentation/DesignSystem/Components/FormFieldRow.swift`:
  - Add `infoText: String?` (default `nil`) and optional `infoAccessibilityLabel: String?` to existing initializers.
  - When `infoText != nil`, render `InfoTooltip` next to the label and skip rendering `helpText`.

**Tests:**
- NEW `KizbaTests/Presentation/DesignSystem/InfoTooltipTests.swift`:
  - `testInfoTooltip_defaultsToClosed`
  - `testInfoTooltip_accessibilityLabelIsSet`
  - `testInfoTooltip_togglesOpenOnTap` (via bound state harness or `@State` inspection)
- Optional: extend `FormFieldRow` structure test if one exists to assert `helpText` is suppressed when `infoText` is set.

**Verification:**
```sh
xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' \
  -only-testing:KizbaTests/InfoTooltipTests
xcodebuild build -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS'
rg -n 'Color\.\w+|cornerRadius:\s*\d+|\.opacity\(0\.\d+\)' Kizba/Presentation/DesignSystem/Components/InfoTooltip.swift
```

**Branch:** `mvp6/b1-info-tooltip`
**Commit:** `feat(ds): add InfoTooltip component and FormFieldRow.infoText integration (MVP6.B.1)`
**Difficulty:** S
**Risks:** popover clipping inside `Form`/`TabView`. Mitigation: `.popover(attachmentAnchor: .point(.center), arrowEdge: .top)`.

---

### B.2 — `SettingsModel` dirty-tracking + `SaveState`

**Description:** Introduce a `SettingsSnapshot` value type capturing all editable fields, capture an `initialSnapshot` on `load()`, expose `var hasChanges: Bool`, and convert `save()` into an async method that drives a `SaveState` machine (`idle → saving → saved → idle`) with an injectable flash duration. `Reset` rebuilds the snapshot so `hasChanges` returns to `false`.

**Agent:** smart-worker

**Files:**
- MOD `Kizba/Presentation/Features/Settings/SettingsModel.swift`:
  - `private struct SettingsSnapshot: Equatable` containing every editable field currently in `SettingsModel` (clipboardClearDelaySeconds, touchIDPerRevealEnabled, gitOperationTimeoutSeconds, showInMenuBar, showRecents, recentsLimit, storePathOverride, passBinaryOverride, gpgBinaryOverride, pinentryBinaryOverride). Exclude transient fields (`isDetectingBinaries`, `saveState`).
  - `enum SaveState: Equatable { case idle, saving, saved }`.
  - `var saveState: SaveState = .idle`.
  - `private var initialSnapshot: SettingsSnapshot` rebuilt on `load()` and after successful `save()` / `reset()`.
  - `var hasChanges: Bool { currentSnapshot != initialSnapshot }`.
  - `private var currentSnapshot: SettingsSnapshot { ... }`.
  - Convert `func save()` → `func save() async`:
    1. Guard `hasChanges`; else return.
    2. `saveState = .saving`.
    3. Perform existing persistence work (including dispatch to `recentStore.setMaxCount`).
    4. Rebuild `initialSnapshot`.
    5. `saveState = .saved`.
    6. `try? await Task.sleep(for: savedFlashDuration)`; if still `.saved` → `.idle`.
  - Add init parameter `savedFlashDuration: Duration = .milliseconds(1500)`.
  - Ensure `reset()` rebuilds `initialSnapshot` so `hasChanges == false` afterwards.
- MOD `Kizba/Presentation/Features/Settings/SettingsView.swift` (light touch only — full split in B.3):
  - Save button: `disabled(!model.hasChanges || model.saveState == .saving)`.
  - Adjacent inline status mirroring `saveState` (`"Saving…"` / `"Saved"`) using DS typography; hidden when `.idle`.
  - Save action becomes `await model.save()` (wrap in `Task { ... }` if Button can't be async directly).

**Tests:**
- MOD `KizbaTests/Presentation/Features/Settings/SettingsModelTests.swift`:
  - `testHasChanges_isFalseAfterLoad`
  - `testHasChanges_becomesTrueAfterMutation_andFalseAfterSave`
  - `testSaveState_transitions_idle_saving_saved_idle` (use `savedFlashDuration: .milliseconds(10)`)
  - `testSave_isNoopWhenNoChanges` (state stays `.idle`)
  - `testReset_clearsHasChanges`
  - `testSnapshot_treatsNilAndEmptyOverrideAsDifferent`

**Verification:**
```sh
xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' \
  -only-testing:KizbaTests/SettingsModelTests
xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS'
```

**Branch:** `mvp6/b2-save-state`
**Commit:** `feat(settings): add dirty-tracking and async SaveState with flash feedback (MVP6.B.2)`
**Difficulty:** M
**Risks:**
- Snapshot drift if a future field is added without updating `SettingsSnapshot`. Mitigation: `// MARK: keep in sync with SettingsModel fields` comment.
- Async `save()` race: `hasChanges` guard + disabled binding prevent reentry; assert with a test.

---

### B.3 — `TabView` split (General / Security / Git / Advanced)

**Description:** Convert `SettingsView` into a thin host that owns the shared footer (Save / Reset / version) and embeds a `TabView` with four tabs. Each tab is its own file under `Tabs/`, takes `@Bindable var model: SettingsModel`, and renders the relevant `FormSection`s using existing DS components. Recents stays in **General**.

**Agent:** smart-worker

**Files:**
- MOD `Kizba/Presentation/Features/Settings/SettingsView.swift`:
  - Replace current `ScrollView { VStack { … } }` with:
    ```
    VStack(spacing: 0) {
        TabView {
            GeneralTab(model: model).tabItem { Label("General", systemImage: "gear") }
            SecurityTab(model: model).tabItem { Label("Security", systemImage: "lock") }
            GitTab(model: model).tabItem { Label("Git", systemImage: "arrow.triangle.branch") }
            AdvancedTab(model: model).tabItem { Label("Advanced", systemImage: "slider.horizontal.3") }
        }
        SettingsFooter(model: model, version: …)
    }
    .frame(minWidth: 520)
    ```
  - Remove existing `.safeAreaInset(.bottom)` footer; move content into new `SettingsFooter` subview rendered once below `TabView`.
- NEW `Kizba/Presentation/Features/Settings/Tabs/GeneralTab.swift` — Clipboard auto-clear delay, Show in menu bar, Show Recents toggle, Recents limit.
- NEW `Kizba/Presentation/Features/Settings/Tabs/SecurityTab.swift` — Touch ID per-reveal toggle (verbatim move; Phase D will rework).
- NEW `Kizba/Presentation/Features/Settings/Tabs/GitTab.swift` — Git timeout, Store path override.
- NEW `Kizba/Presentation/Features/Settings/Tabs/AdvancedTab.swift` — pass / gpg / pinentry overrides + Re-detect button.
- NEW (or inline in `SettingsView.swift`) `SettingsFooter` view with Save button, Reset button, save status text, app version.

**Tests:**
- If ViewInspector vendored: NEW smoke test in `KizbaTests/Presentation/Features/Settings/SettingsViewTests.swift` asserting four tab labels + footer renders Save + Reset once.
- If not: skip UI structure tests; rely on B.2 model tests + manual smoke.

**Verification:**
```sh
xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS'
xcodebuild build -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS'
```
Manual smoke: four tabs visible with SF Symbols; switching tabs preserves state; footer Save/Reset/version visible across tabs; Recents lives under General.

**Branch:** `mvp6/b3-settings-tabs`
**Commit:** `refactor(settings): split SettingsView into TabView with shared footer (MVP6.B.3)`
**Difficulty:** M
**Risks:**
- Window-sizing jitter when switching tabs of differing content height — set `minWidth: 520`, let SwiftUI manage height.
- Hidden coupling on `.safeAreaInset` removal — verify no other view depends on it.

---

### B.4 — `InfoTooltip` rollout in Settings

**Description:** Replace inline `helpText` with `InfoTooltip` on key controls across tabs. Texts short, single-sentence, English literals.

**Agent:** smart-worker

**Files:**
- MOD `Kizba/Presentation/Features/Settings/Tabs/GeneralTab.swift`:
  - Clipboard auto-clear delay → `infoText: "Secrets copied to the clipboard are cleared automatically after this delay."`
  - Show in menu bar → `infoText: "Show the Kizba icon in the macOS menu bar for quick access."`
  - Show Recents in Sidebar → `infoText: "Display recently used password entries at the top of the sidebar."`
  - Recents limit → `infoText: "How many recent entries to show in the sidebar (3–7)."`
- MOD `Kizba/Presentation/Features/Settings/Tabs/SecurityTab.swift`:
  - Touch ID → `infoText: "Require Touch ID authentication for every secret reveal."`
- MOD `Kizba/Presentation/Features/Settings/Tabs/GitTab.swift`:
  - Git timeout → `infoText: "Maximum seconds to wait for any git operation before aborting."`
  - Store path → `infoText: "Override the default password-store location (~/.password-store)."`
- MOD `Kizba/Presentation/Features/Settings/Tabs/AdvancedTab.swift`:
  - pass override → `infoText: "Absolute path to the pass binary. Leave empty for auto-detection."`
  - gpg override → `infoText: "Absolute path to the gpg binary. Leave empty for auto-detection."`
  - pinentry override → `infoText: "Absolute path to the pinentry binary. Leave empty for auto-detection."`
- For each affected row: pass `helpText: nil` (or remove the parameter) + `infoText:` + descriptive `infoAccessibilityLabel:`.

**Tests:** none (UI strings only).

**Verification:**
```sh
xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS'
rg -n 'infoText:' Kizba/Presentation/Features/Settings/Tabs   # expect ≥10
```

**Branch:** `mvp6/b4-info-tooltip-rollout`
**Commit:** `feat(settings): adopt InfoTooltip across Settings tabs (MVP6.B.4)`
**Difficulty:** S
**Risks:** tooltip text drift vs. behaviour — keep wording neutral and behavioural.

---

## Acceptance criteria — Phase B

- [ ] `InfoTooltip` exists as a DS component, uses theme tokens only, has tests covering default-closed, accessibility label, toggle behaviour.
- [ ] `FormFieldRow` accepts `infoText:` additively; existing call sites unchanged.
- [ ] `SettingsModel.hasChanges` is `false` immediately after `load()` and after `save()` / `reset()`; becomes `true` on any editable mutation.
- [ ] `SettingsModel.saveState` transitions `idle → saving → saved → idle` on a successful save, with the `.saved` flash duration injectable for tests.
- [ ] Save button is disabled when `!hasChanges || saveState == .saving`.
- [ ] `SettingsView` is a `TabView` with exactly four tabs (General / Security / Git / Advanced) and a single shared footer rendered once below the tabs.
- [ ] Recents controls live under General tab.
- [ ] At least the ten enumerated controls in B.4 use `InfoTooltip` instead of inline `helpText`.
- [ ] Test suite remains green; no regressions from the 1019-test Phase A baseline.
- [ ] DS grep guards remain green.
- [ ] Touch ID behaviour unchanged (verbatim move into `SecurityTab`).

## Verification commands (Phase B final)

```sh
xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS'
xcodebuild build -scheme Kizba -project Kizba.xcodeproj -configuration Release -destination 'platform=macOS'
rg -n '\bas!\b' Kizba/
rg -n 'Logger.*stdin|print\(.*stdin' Kizba/ KizbaTests/
rg -n 'safeAreaInset' Kizba/Presentation/Features/Settings
rg -n 'infoText:' Kizba/Presentation/Features/Settings/Tabs
```

## Suggested current step

Run **smart-worker** on **Task B.1** — Implement `InfoTooltip` DS component and extend `FormFieldRow` with `infoText:`. Smallest isolated change; unblocks B.4 entirely; independent of B.2 model refactor and B.3 view split.
