Phase: MVP6.G (COMPLETED — all 3 critical UX bugs fixed)
Status: G.3 shipped; G.1+G.2+G.3 all merged

Next action: Run smart-worker on Task D.1 (Inject BiometricAuthenticating into SettingsModel + requestToggleBiometric API)

Notes:
- G.3: Persisted leak fix.
- Created Kizba/Infrastructure/Storage/StorageKeys.swift with namespaced keys (.v1 suffix) + legacy constants for migration paths only. Declared `public nonisolated static let` to mirror the SettingsKeys convention (default-isolation=MainActor would otherwise lock the constants behind the main actor and break the actor-isolated stores at compile time — caught on the first build).
- UserDefaultsRecentEntriesStore: storage key -> StorageKeys.recentsEntriesV1; best-effort cleanup of legacy "kizba.recentEntries" in init (no value migration — fresh start by design, prevents DEBUG fixture leakage). Private `Keys` enum removed.
- UserDefaultsFavoritesStore: storage key -> StorageKeys.favoritesEntriesV1; one-shot migration of legacy "kizba.favorites" before reading (idempotent — only when new key empty). On "both keys present" — new key wins, legacy left untouched (forensic preservation). Private `Keys` enum removed.
- SidebarView Recents empty-section gating verified (unchanged — Phase A.3 already correct: `if showRecents && !recentsModel.recents.isEmpty`).
- Tests added: 6 new — UserDefaultsRecentEntriesStoreTests (3: new-key read, legacy ignored+removed, record persists only to new), UserDefaultsFavoritesStoreTests (3: migration on empty new key, no overwrite when both present, idempotent second construction). All use isolated `UserDefaults(suiteName:)` per test + `removePersistentDomain` tear-down (reused existing helper pattern from each file).
- Decision documented in commit message: Recents = no migration; Favorites = one-shot migration. Reason: Recents is auto-collected ephemeral data, safer to drop polluted state; Favorites is curated user data, data loss unacceptable.
- Phase G ALL ACCEPTANCE CRITERIA MET:
  * G.1: Favorites toggle + DisclosureGroup symmetric with Recents ✓
  * G.2: Sidebar tap routes Recents/Favorites to selectedEntryID ✓
  * G.3: Namespaced storage keys + Favorites migration + Recents fresh start ✓
- Full suite: 1051 tests, 17 skipped, 0 failures (1045 baseline + 6 new). Release build clean. Grep bans clean (`as!` 0 in Kizba/; stdin matches only self-references in SourceGrepTests; legacy keys appear only in StorageKeys.legacy* declarations; new v1 keys appear only in StorageKeys + the two stores).
- Commits this phase: e219afa (G.1), e05b5ea (G.2), 455830d (G.3).

Plan: .ai/plan.md (Phase D + Phase G). Phase G is complete. Suggested next per plan: D.1 (BiometricAuthenticating injection into SettingsModel).

Timestamp: 2026-05-17T18:11:00+02:00
