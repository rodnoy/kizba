Phase: MVP6.B.3
Status: COMPLETED

Next action: Run smart-worker on Task B.4 (InfoTooltip rollout — apply to ≥10 controls across Settings tabs)

Notes:
- SettingsView restructured into a thin VStack host: `TabView` with four tabs (General / Security / Git / Advanced, SF Symbols `gear` / `lock` / `arrow.triangle.branch` / `slider.horizontal.3`) + shared `SettingsFooter` rendered once below the tabs. Host applies `.frame(minWidth: 520, minHeight: 420)`; previous `.safeAreaInset(.bottom)` is gone. `SettingsView.swift` collapsed from 358 → 86 LOC.
- Tabs extracted to `Kizba/Presentation/Features/Settings/Tabs/`:
  - `GeneralTab.swift` — Clipboard auto-clear delay (Stepper), Menu Bar visibility toggle, Recents visibility toggle + recents limit Stepper.
  - `SecurityTab.swift` — Touch ID per-reveal toggle, verbatim move (Phase D will rework).
  - `GitTab.swift` — Git operation timeout Stepper + Store path override TextField with NSOpenPanel picker.
  - `AdvancedTab.swift` — pass / gpg / pinentry binary overrides + Re-detect button (binds `model.isDetectingBinaries` + `ProgressView`).
- `SettingsFooter.swift` (separate file in `Tabs/`) hosts: app version (`AppInfo.version` + build, leading) → Spacer → inline `saveStatusLabel` (Saving… / Saved — same DS tokens as before) → Reset button (`.kizba(.destructive)` + `.destructiveConfirmation`) → Save button (`.kizba(.primary)`, `disabled(!hasChanges || saveState == .saving)`, `.keyboardShortcut(.defaultAction)`, `Task { await model.save() }`). Reset confirmation alert state is owned by the footer.
- Each tab wraps content in `ScrollView { VStack { FormSection... } }` (per fallback in the task) so variable-height content is safe inside `TabView`.
- `bindingForOptional` helper in `GitTab` / `AdvancedTab` switched from `WritableKeyPath` to `ReferenceWritableKeyPath<SettingsModel, String?>` because `@Bindable var model` is a computed accessor inside the View struct — `WritableKeyPath` requires a mutable subscript on `self`, which `View` does not have. `SettingsModel` is `final class`, so a reference key path is the natural fit.
- Preview block kept and updated for the new structure (same `AppEnvironment.preview()` + `PreviewDiscovery` plumbing).
- ViewInspector NOT vendored in the project (no `import ViewInspector` anywhere, not in Package.swift, not in xcodeproj). Per plan, UI-structure smoke tests were SKIPPED; reliance on B.2 model tests + manual smoke. No new test files added.
- Full suite: 1038 tests, 17 skipped, 0 failures (same baseline as B.2 — UI-only refactor adds no tests). Release build (`-configuration Release`): SUCCEEDED.
- Grep bans clean: `as!` 0 hits in Kizba/; `Logger.*stdin|print(.*stdin` only self-refs in SourceGrepTests.swift; DS literals in `Kizba/Presentation/Features/Settings/` (including new Tabs/) → 0 hits; `safeAreaInset` in Settings/ → 0 code hits (only doc-comment mentions in SettingsView.swift + SettingsFooter.swift describing the change).
- Xcodeproj uses `PBXFileSystemSynchronizedRootGroup` for `Kizba/`; new files under `Tabs/` are picked up automatically, no pbxproj edit required.
- Commit: <hash> on main.

Timestamp: 2026-05-17T16:50:00+02:00
