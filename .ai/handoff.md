Phase: MVP6.H.2 (HOTFIX-2 FINAL)
Status: COMPLETED — Recents fixture leak FINALLY closed via path validation against live pass-store

Next action: User restart app — Recents will be empty until they open real entries (paths that don't exist in `~/.password-store/` are dropped from the sidebar at load time, regardless of what's persisted in the plist).

Notes:
- H.1 (schema bump .v1 -> .v2) was INSUFFICIENT. Diagnostic confirmed fixture paths still in plist under `app.kizba.recents.entries.v2` after H.1 shipped — written by DEBUG / SwiftUI-preview builds AFTER H.1 (`MockPassManager.preview()` is wired in `AppEnvironment.preview()`, both DEBUG and Release share `UserDefaults.standard` via the same bundle id, so any preview render that touched the recents writer poisoned production storage again).
- H.2: Added `RecentEntriesValidating` protocol + `PassManagerRecentEntriesValidator` (actor) backed by `PassManaging.listEntries()`. `RecentsModel.load()` and its `recentsChanged` observation now route every store read through the validator before assigning `self.recents`; any path not physically present in the real pass-store is dropped (stable filter, preserves newest-first order).
- This permanently closes the leak class: even if some future regression writes fixture paths into UserDefaults, they will not surface in UI because the real store doesn't have them.
- Graceful degradation: if `listEntries()` throws (transient store failure), validator returns paths unchanged — better to show stale recents than wipe a valid list when the store is briefly unavailable. Documented in `RecentEntriesValidating` doc and `PassManagerRecentEntriesValidator` impl.
- Validator is optional in `RecentsModel.init` (default `nil`) so the dozens of existing test/preview call sites stayed untouched; the live wiring in `AppEnvironment.live()` is the only place that actually injects the production validator. Single `SidebarView` call site updated to forward `environment.recentsValidator`.
- Files added:
  * `Kizba/Domain/Protocols/RecentEntriesValidating.swift` (protocol, `public`, `Sendable`, single `validate([String]) async -> [String]` method).
  * `Kizba/Infrastructure/Recents/PassManagerRecentEntriesValidator.swift` (`public actor PassManagerRecentEntriesValidator: RecentEntriesValidating`).
  * `KizbaTests/Fixtures/FakeRecentEntriesValidator.swift` (`actor`, `validateCalls` counter, `validPaths` set).
- Files modified:
  * `Kizba/Presentation/Features/Sidebar/RecentsModel.swift` — added `validator:` init param + static `nonisolated` filter helper used by both `load()` and the observation task.
  * `Kizba/App/AppEnvironment.swift` — added optional `recentsValidator` field + plumbing through both designated and convenience initializers; `live()` wires `PassManagerRecentEntriesValidator(passManager: passManager)`. Preview/release placeholder branches default to `nil` (no behaviour change there).
  * `Kizba/Presentation/Features/Sidebar/SidebarView.swift` — `RecentsModel(store:validator:)` call now forwards `environment.recentsValidator`.
- Tests: added 4 in `KizbaTests/Presentation/Features/Sidebar/RecentsModelTests.swift`:
  * `testLoad_filtersOutInvalidPaths` — happy-path filter + asserts validator was invoked exactly once.
  * `testLoad_returnsAllPathsWhenAllValid` — degenerate-pass-through.
  * `testLoad_returnsEmptyWhenNothingValid` — exact symptom the user will see on first launch after H.2 ships against the polluted plist.
  * `testLoad_withoutValidator_passesPathsThrough` — pins the `nil`-validator legacy behaviour so preview/test wirings keep working.
  No existing RecentsModelTests required signature adaptation thanks to the optional `validator` default.
- Trade-off documented: a path which was open recently but later deleted/moved will disappear from Recents immediately. Acceptable — Recents is auto-collected ephemeral cache, surfacing a path the user cannot open is worse than the disappearance.
- H.1 schema bump (.v1 -> .v2) is RETAINED as defence-in-depth.
- Targeted: `KizbaTests/RecentsModelTests` — 8 tests passed (0.227s).
- Full suite: 1070 tests, 17 skipped, 0 failures (70.1s). Baseline was 1066 → +4 new. Release build SUCCEEDED.
- Grep bans:
  * `\bas!\b` in `Kizba/` — 0 matches.
  * `Logger.*stdin|print\(.*stdin` — only 2 self-references in `SourceGrepTests.swift` (lines 321 comment, 431 pattern literal). OK.
  * `RecentEntriesValidating` — protocol decl + 3 use sites in `Kizba/` + 1 in `KizbaTests/` (the fake). OK.
  * `PassManagerRecentEntriesValidator` — type decl + 2 mentions in `AppEnvironment.swift` (doc + `live()` wiring). OK.
- Commit: a8c8c70 on main.

Timestamp: 2026-05-17T23:48:30+02:00
