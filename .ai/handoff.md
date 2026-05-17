Phase: MVP6.A (COMPLETED)
Status: Phase A SHIPPED — Recents controls (visibility + limit 3-7 + fold/unfold)

Next action: Run smart-planner to open Phase B (Settings tabs + Save feedback + InfoTooltip). Replace .ai/plan.md with operational Phase B plan.

Notes:
- A.4: SettingsModel exposes showRecents (Bool) + recentsLimit (Int, 3-7). SettingsView renders a new "Recents" FormSection between General and Binaries with Toggle("Show Recents in Sidebar") + Stepper("N entries", in: SettingsKeys.recentsLimitBounds, step: 1). save() persists both keys, re-reads the persisted (possibly clamped) recentsLimit into the in-memory model, then dispatches Task { await recentStore.setMaxCount(persistedLimit) } so observers see the updated cap without an app restart.
- SettingsModel.init extended to `(settings:, discovery:, recentStore:)` — recentStore is the new third parameter, matches the existing manual-DI pattern. Call-sites updated: KizbaApp.swift (passes environment.recentStore), SettingsView preview block (env.recentStore), SettingsViewTouchIDTests (FakeRecentEntriesStore()), SettingsModelTests (helper makeModel() defaults recentStore to a fresh FakeRecentEntriesStore so only the one propagation test holds a reference).
- FakeRecentEntriesStore now records every setMaxCount(_:) invocation in `setMaxCountCalls: [Int]` for assertion.
- AppEnvironment.InMemorySettingsStore (DEBUG-only): set<Value> now mirrors the production UserDefaultsSettingsStore clamp for SettingsKeys.recentsLimit (max(min..., min(max..., typed))). Tests and previews now see the same contract as live wiring; without this, a 99 written through the in-memory store round-tripped as 99 and the model contract would silently degrade in tests.
- Tests added in SettingsModelTests: 7 new — testShowRecents_defaultIsTrue, testShowRecents_persists, testRecentsLimit_defaultIsSeven, testRecentsLimit_persistsAndClampsHigh (99→7), testRecentsLimit_persistsAndClampsLow (1→3), testSave_callsSetMaxCountOnRecentStore (last call == 5, count == 1), testSave_propagatesClampedValueToRecentStore (last call == maxRecentsLimit when set 99). Helper waitForRecordedSetMaxCount() polls the actor up to 1 s to drain the Task hop from save().
- Phase A acceptance criteria — ALL MET:
  * SettingsKeys exposes showRecents / recentsLimit / defaultRecentsLimit (+ min/max/bounds/defaultShowRecents). ✓
  * `rg -n '\bmaxCount\s*=\s*20\b' Kizba/Infrastructure/Recents/` → 0 matches. ✓
  * setMaxCount actor API on RecentEntriesStoring; production + DEBUG implementations conform; persist-then-emit-once. ✓
  * SidebarView wraps Recents in DisclosureGroup, persists expansion via @AppStorage("kizba.sidebar.recentsExpanded"), elides the section when showRecents == false. ✓
  * Settings UI wires Toggle + Stepper; save persists both and propagates the limit to the actor store. ✓
  * Tests green; release clean; grep clean. ✓
- Full suite: 1019 tests, 17 skipped, 0 failures (1012 prior + 7 new). Targeted SettingsModelTests: 19/19 PASS. Release build: SUCCEEDED.
- Grep bans clean: `as!` 0 hits in Kizba/; `Logger.*stdin|print(.*stdin` only self-refs in SourceGrepTests (regex literals defining the ban); DS literal grep in Kizba/Presentation/Features/Settings/ → 0 matches.
- Commits this phase: 394a9da (A.1), a945b95 (A.2), 16c71e4 (A.3), dc6166e (A.4).

Timestamp: 2026-05-17T15:50:00+02:00
