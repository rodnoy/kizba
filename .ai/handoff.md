Phase: MVP6.B.2
Status: COMPLETED

Next action: Run smart-worker on Task B.3 (TabView split: General / Security / Git / Advanced + shared SettingsFooter)

Notes:
- SettingsModel: added private SettingsSnapshot (10 editable fields — clipboardClearDelaySeconds, touchIDPerRevealEnabled, gitOperationTimeoutSeconds, showInMenuBar, showRecents, recentsLimit, storePathOverride, passBinaryOverride, gpgBinaryOverride, pinentryBinaryOverride). Excludes transient state (isDetectingBinaries, saveState). initialSnapshot captured at end of init() and refreshed after save() / resetToDefaults().
- New computed: hasChanges (currentSnapshot != initialSnapshot). New state: SaveState enum (idle/saving/saved) + public var saveState. String? overrides keep `nil` vs `""` distinct on purpose (matches the user-visible distinction surfaced by bindingForOptional in SettingsView).
- save() converted to async; flow: guard hasChanges -> .saving -> sync settings.set(...) round-trip -> await recentStore.setMaxCount(persistedLimit) inline (we are async on MainActor, actor hop is one-shot, no deadlock) -> rebuild initialSnapshot -> .saved -> try? await Task.sleep(for: savedFlashDuration) -> race-safe `if saveState == .saved { saveState = .idle }`.
- init parameter savedFlashDuration: Duration = .milliseconds(1500); tests inject .milliseconds(10) via makeModel helper default.
- resetToDefaults() rebuilds initialSnapshot at the end so hasChanges == false immediately post-reset (drives Save button disabled binding).
- SettingsView: Save Button now `Button("Save") { Task { await model.save() } }`, disabled(!hasChanges || saveState == .saving), .help("Save settings"). Inline saveStatusLabel (@ViewBuilder) renders `EmptyView()` / "Saving…" (caption, onSurfaceMuted) / "Saved" (caption, success) adjacent to the action pair; collapses cleanly at rest. DS tokens only — no raw Color, no numeric corner radius, no numeric opacity.
- Call-sites of save(): only SettingsView.swift (production) and SettingsModelTests.swift (tests). Updated both. No legacy sync wrapper needed.
- Existing SettingsModelTests adapted to await model.save() (9 tests converted to async). Removed the now-unused waitForRecordedSetMaxCount() helper since await on save() lets the actor hop complete synchronously from the test's POV.
- Tests added in SettingsModelTests: 7 new — testHasChanges_isFalseAfterLoad, testHasChanges_becomesTrueAfterMutation, testHasChanges_falseAfterSave, testSaveState_transitions_idle_saving_saved_idle (uses .milliseconds(10) flash; asserts post-await state is .idle), testSave_isNoopWhenNoChanges (asserts saveState stays .idle AND recentStore receives zero setMaxCount calls), testReset_clearsHasChanges, testSnapshot_treatsNilAndEmptyOverrideAsDifferent. SettingsModelTests: 26/26 PASS in 0.56 s.
- Full suite: 1038 tests, 17 skipped, 0 failures (1031 prior + 7 new). Release build: SUCCEEDED.
- Grep bans clean: `as!` 0 hits in Kizba/; `Logger.*stdin|print(.*stdin` only self-refs in SourceGrepTests.swift (regex literals defining the ban); DS literals in Kizba/Presentation/Features/Settings/ → 0 hits.
- Commit: <hash> on main.

Timestamp: 2026-05-17T16:43:00+02:00
