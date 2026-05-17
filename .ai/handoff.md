Phase: MVP6.G.1
Status: COMPLETED

Next action: Run smart-worker on Task G.2 (Sidebar tap routing fix: introduce entrySelection binding so Recents/Favorites taps land in selectedEntryID instead of selectedFolder).

Notes:
- Symmetric Favorites controls landed: SettingsKeys.showFavorites (Bool, default true) + SettingsKeys.defaultShowFavorites = true. UserDefaultsSettingsStore registers the default inside init() using the existing namespaced(_:) helper.
- SettingsModel: public var showFavorites: Bool; extended private SettingsSnapshot + currentSnapshot + initialSnapshot + init() loader + save() write. resetToDefaults() intentionally NOT changed — symmetric with showRecents, which is a user preference and is not part of the "reset overrides + clipboard delay" semantic.
- GeneralTab: new private favoritesSection placed above recentsSection (mirrors the sidebar order). Uses FormSection("Favorites") + FormFieldRow(label: "Visibility", infoText: "Display starred entries at the top of the sidebar.") wrapping Toggle("Show Favorites in Sidebar", isOn: $model.showFavorites). Same FormFieldRow(label:infoText:) API as the Recents Visibility row.
- SidebarView: added @AppStorage("app.kizba.settings.showFavorites") private var showFavorites: Bool = true plus @AppStorage("kizba.sidebar.favoritesExpanded") private var favoritesExpanded: Bool = true. Favorites section now reads "if showFavorites && !favoritesModel.favorites.isEmpty { Section { DisclosureGroup(isExpanded: $favoritesExpanded) { ForEach... } label: { Text("Favorites") } } }" — identical shape to the Phase A.3 Recents block.
- @AppStorage key string matches `UserDefaultsSettingsStore.namespaced(SettingsKeys.showFavorites)` exactly (`"app.kizba.settings.showFavorites"`). Comment in SidebarView calls this out to deter drift.
- Tests added: 5 total.
  * KizbaTests/UserDefaultsSettingsStoreTests.swift: testShowFavorites_defaultsTrue, testShowFavorites_roundTrip.
  * KizbaTests/SettingsModelTests.swift: testShowFavorites_defaultIsTrue, testShowFavorites_persists, testHasChanges_flipsWhenShowFavoritesMutated (regression test for the SettingsSnapshot extension).
- Full suite: 1044 tests, 17 skipped, 0 failures (1039 baseline + 5 new).
- Build (Debug, macOS): SUCCEEDED. Grep bans clean: `as!` 0 in Kizba/, stdin only self-references in SourceGrepTests.
- SourceGrepTests.testIconOnlyButtonsHaveHelp_inAuditedFeatures stays green — the SidebarView changes do not introduce new icon-only Buttons.
- Commit: e219afa on main.

Plan: .ai/plan.md has been rewritten to cover Phase G (G.1–G.3) + Phase D (D.1–D.3) with full task envelopes (Description / Files / Tests / Verification / Branch / Commit / Difficulty / Risks), sequencing rationale (G before D, by-risk inside G), acceptance criteria, final verification commands, open questions and suggested current step. G.1 is now marked complete in this handoff; the plan itself does not encode per-task done flags (consistent with prior plan.md files).

Timestamp: 2026-05-17T17:53:00+02:00
