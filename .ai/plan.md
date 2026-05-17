# MVP5 Phase E — Polish / Docs / Regression

## Status of prior phases

- Phase A (search overlay + LiveSearchEngine) — DONE, green.
- Phase B (favorites store + sidebar + EntryDetail star) — DONE, green.
- Phase C (recents store + sidebar section + search boost) — DONE, green.
- Phase D (menu-bar status item + popover + settings toggle) — DONE, green. D.4 (global hotkey) intentionally deferred (Accessibility permission UX).
- Current suite: 999 tests, 0 failures.

## Goal

Lock in MVP5 with three small, low-risk closing tasks:
1. Tighten source-grep policy for the new `SearchResult` type.
2. Bring user-facing and internal docs in sync with shipped features.
3. Run the final regression matrix (build + tests + grep bans, Debug and Release).

## Constraints (durable)

- Swift 5.10, macOS 14, `SWIFT_STRICT_CONCURRENCY = complete`.
- No `as!`. No `Logger.*stdin|print\(.*stdin` patterns.
- No third-party dependencies.
- English in code, comments, commits, docs.
- `@Observable` + manual DI via initializers; actor-based stores; design-system tokens (no inline `Color.<name>` / numeric `cornerRadius` / numeric `.opacity()` in `Kizba/Presentation/Features/` outside the design system).

---

## Tasks

### E.1 — SourceGrepTests extension for SearchResult

**Description:** Extend `SourceGrepTests` to forbid `Codable` and `CustomStringConvertible` conformances on the `SearchResult` type. Mirror the existing bans for `PassSecret`, `SecretDraft`, and `MetadataPair`.

**Agent:** smart-worker

**Files to modify:**
- `KizbaTests/SourceGrepTests.swift` — add a new test that scans `Kizba/` sources and fails if `SearchResult` appears with `: Codable`, `: Decodable`, `: Encodable`, or `: CustomStringConvertible` (including `extension SearchResult: ...`).

**Suggested test name:** `testNoCodableOrCustomStringConvertible_onSearchResult`

**Verification:**
```sh
xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' \
  -only-testing:KizbaTests/SourceGrepTests
rg -n '\bas!\b' Kizba/
rg -n 'Logger.*stdin|print\(.*stdin' Kizba/ KizbaTests/
```

**Branch:** `mvp5/e1-sourcegrep-search-result`
**Commit:** `test(grep): forbid Codable/CustomStringConvertible on SearchResult (MVP5.E.1)`

**Difficulty:** low
**Risks:** If `SearchResult` already conforms to `Codable`, the test will fail and the conformance must be removed first. Inspect before writing.

---

### E.2 — Documentation pass

**Description:** Bring `README.md`, `.ai/decisions.md`, `.ai/sequoia-smoke.md`, and `.ai/a11y-audit.md` up to date with MVP5-shipped behaviour.

**Agent:** smart-worker

**Files to modify:**

1. `README.md` — section "What it does":
   - Global ⌘K search overlay (live-ranked, in-memory).
   - Favorites (⭐ toggle in `EntryDetail` toolbar, ⌘D shortcut, sidebar section).
   - Recent entries (auto-recorded on view, sidebar section, FIFO max 20).
   - Menu-bar status item with SwiftUI popover for quick search + copy.
   - "What's deferred": remove quick-search / menu-bar; keep D.4 global hotkey with rationale (Accessibility permission UX).

2. `.ai/decisions.md` — append `## 2026-05-17 — MVP 5 (Search / Favorites / Recents / Menu-bar)`:
   - `LiveSearchEngine` — pure in-memory ranker, score 0.0–1.0, boost +0.05 favorites / +0.03 recents, summed and capped at 1.0.
   - `FavoritesStoring` — actor protocol, UserDefaults-backed (`kizba.favorites`), `AsyncStream<Void>` change notifications.
   - `RecentEntriesStoring` — actor protocol, UserDefaults-backed (`kizba.recentEntries`), FIFO max 20, dedup-move-to-front.
   - `StatusItemController` — `@MainActor`, owns `NSStatusItem` (.squareLength, SF Symbol `key.fill`) + `NSPopover` (.transient). SwiftUI via `NSHostingView`. Gated by `SettingsKeys.showInMenuBar` (default true), reactive to `UserDefaults.didChangeNotification`.
   - D.4 global hotkey — deferred. `NSEvent.addGlobalMonitorForEvents` requires Accessibility permission with poor UX.

3. `.ai/sequoia-smoke.md` — append rows:
   - Menu-bar icon visibility toggles live with Settings → "Show in menu bar".
   - Clicking the menu-bar icon opens the popover; outside-click dismisses (.transient).
   - In popover: typing → results; clicking copy → clipboard with auto-clear.
   - ⌘K opens SearchOverlay; Esc dismisses; Enter selects.
   - ⭐ toggle (and ⌘D) flips favorite; sidebar Favorites section updates immediately.
   - Viewing an entry adds it to the sidebar Recents section (newest first, capped 20).

4. `.ai/a11y-audit.md` — append two sections:
   - **SearchOverlay**: focus on appear; accessibilityLabel on TextField; Esc dismissal announced; results list keyboard-navigable (↑/↓) with per-row labels (entry path).
   - **MenuBarPopover**: NSStatusItem button accessibilityLabel; popover takes focus on open (search field first responder); copy triggers announcement ("Password copied"); Recents/Favorites sections expose section headers.

**Verification:**
```sh
xcodebuild build -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS'
rg -n '\bas!\b' Kizba/
rg -n 'Logger.*stdin|print\(.*stdin' Kizba/ KizbaTests/
```

**Branch:** `mvp5/e2-docs-mvp5`
**Commit:** `docs(mvp5): README + decisions + smoke + a11y for search/favorites/recents/menu-bar (MVP5.E.2)`

**Difficulty:** low
**Risks:** docs drift — re-read feature files before writing each section.

---

### E.3 — Final regression

**Description:** Run the full regression matrix.

**Agent:** smart-builder

**Commands:**

```sh
xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS'
xcodebuild build -scheme Kizba -project Kizba.xcodeproj -configuration Release -destination 'platform=macOS'
rg -n '\bas!\b' Kizba/
rg -n 'Logger.*stdin|print\(.*stdin' Kizba/ KizbaTests/
```

**Expected:** 0 test failures (≥999 tests, 1000 if E.1 added one); Release build clean, no warnings; both `rg` commands zero matches.

**On failure:** do NOT patch inline. Capture in `.ai/build-errors.md` and hand back to planner.

**Branch:** `mvp5/e3-final-regression` (only if a fix lands; otherwise verification-only).
**Commit:** none (verification). If trivial fix: `chore(mvp5): final regression fix (MVP5.E.3)`.

**Difficulty:** low
**Risks:** Release configuration may surface warnings hidden in Debug under strict concurrency.

---

## Acceptance criteria

1. `testNoCodableOrCustomStringConvertible_onSearchResult` exists and passes.
2. `README.md`, `.ai/decisions.md`, `.ai/sequoia-smoke.md`, `.ai/a11y-audit.md` updated as specified.
3. Full Debug test suite green (≥999 tests, 0 failures).
4. Release build green, no warnings.
5. Grep bans clean.
6. No new dependencies; no `as!`; strict concurrency unchanged.

## Verification commands (final)

```sh
xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS'
xcodebuild build -scheme Kizba -project Kizba.xcodeproj -configuration Release -destination 'platform=macOS'
rg -n '\bas!\b' Kizba/
rg -n 'Logger.*stdin|print\(.*stdin' Kizba/ KizbaTests/
```

---

## Suggested current step

Run **smart-worker** to implement **Task E.1** (SourceGrepTests extension for `SearchResult`).
