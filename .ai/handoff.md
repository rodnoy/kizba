Phase: MVP6.A.3
Status: COMPLETED

Next action: Run smart-worker on Task A.4 (SettingsModel + SettingsView wiring for showRecents toggle + recentsLimit Stepper)

Notes:
- SidebarView: Recents section wrapped in DisclosureGroup; expansion state persisted via @AppStorage("kizba.sidebar.recentsExpanded", default true).
- showRecents gating: section elided entirely when @AppStorage("app.kizba.settings.showRecents") == false. Namespace matches SettingsKeys.showRecents exactly (UserDefaultsSettingsStore.namespacePrefix "app.kizba.settings." + SettingsKeys.showRecents "showRecents"), so the Settings toggle in A.4 and this AppStorage will share one slot.
- The pre-existing `if !recentsModel.recents.isEmpty` guard is preserved AND-combined with `showRecents` to keep the empty-state behavior unchanged.
- First DisclosureGroup in the codebase; pattern established for future sidebar sections (Favorites, Folders). No extraction into SidebarRecentsSection.swift — diff was 18 lines and SidebarView remained well under 150 lines; extraction would have hurt locality without benefit.
- DS grep clean: no new `Color.<name>` (only the pre-existing `Color.clear` exception remains), no numeric `cornerRadius:`, no numeric `.opacity(0.x)` in Sidebar/. DisclosureGroup uses system chevron — no override needed.
- RecentsModelTests extended: `testCappedListReflectsSetMaxCount` records 7 entries, calls `store.setMaxCount(4)`, waits for propagation through `recentsChanged`, asserts truncated newest-first prefix `["g","f","e","d"]`. Validates A.2 mutator end-to-end through the model.
- Targeted: KizbaTests/RecentsModelTests — 4/4 PASS (1 new + 3 existing), 0 failures.
- Full suite: 1012 tests, 17 skipped, 0 failures (+1 from previous 1011 = the new test). Debug build clean.
- Grep bans clean: `as!` 0 hits in Kizba/; `Logger.*stdin|print(.*stdin` only self-refs in SourceGrepTests; DS grep clean in Kizba/Presentation/Features/Sidebar/.
- Commit: 3bc75c2 on main.

Timestamp: 2026-05-17T15:42:00+02:00
