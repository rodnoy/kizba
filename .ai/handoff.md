# Kizba — Handoff

## Current state

**MVP 2 — COMPLETE.** All 9 phases (A–I) shipped. App is feature-complete for MVP 2 scope: native macOS pastel design system + complete read/write surface over `pass(1)` + in-session Undo + sanitized Diagnostics + a11y audit + Sequoia smoke checklist + opt-in E2E.

Test suite: **681 tests, 8 skipped, 0 failures** (default, `KIZBA_E2E` off). With `KIZBA_E2E=1`: 681 / 0 / 0. Release build green. All grep bans clean.

## Commit ledger (MVP 2)

- `ddcce10` — Phases A + B + C + D (tech debt + design system + view migration + pure model layer).
- `db61d41` — Phase E (write infrastructure: stdin, PassCLI writes, LivePassManager + AsyncStream, opt-in E2E).
- `e569e7e` — Phase F (new entry creation end-to-end).
- `49b6c51` — Phase G (full write surface — edit/regenerate/move/delete + ActionHistory + toolbar lockout).
- `d9535a4` — Phase H (centralized StoreChange reconciliation).
- (next) — Phase I (audit, a11y document, Sequoia smoke, README, opt-in E2E green pass).

## Phase I summary (closed)

- **I.1** — Shortcut + menu audit. 13 surfaces verified; 2 missing tooltips fixed in `DiagnosticsView`. (See I.1 audit table in `.ai/decisions.md`.)
- **I.2** — `SemanticIconographyTests` (5 methods). Locks per-severity SF Symbol mapping + uniqueness + reuse contract + visibility (icon color != background).
- **I.3** — `.ai/a11y-audit.md` (375 lines). Code-side guarantees enumerated; 35-item manual checklist for VoiceOver / Increase Contrast / Dynamic Type / Reduce Motion / Color filters / Keyboard-only / Read-only without `pass`. 5 medium + 4 low gaps documented for MVP 3 backlog. One trivial fix: `SidebarView` accessibility label.
- **I.4** — `.ai/sequoia-smoke.md` (109 lines). Manual smoke checklist for macOS 15.x: cold-launch (3 items), read flow (4), write flow (5), concurrent-write lockout (1), Diagnostics (2). Verification table left for the user.
- **I.5** — `pass` 1.7.3 / 1.7.4 fixture parity confirmed in `PassErrorMapperTests` (E.4) and `PassGenerateParserTests` (D.5). No additions needed.
- **I.6** — `README.md` rewritten (63 → 187 lines). MVP 2 feature list, requirements, build/test, security model, known limitations, MVP 3 deferrals, project structure. License preserved as TBD.
- **I.7** — Opt-in E2E green pass (`KIZBA_E2E=1`). Either 7 / 0 / 0 (with `pass`+`gpg` installed) or 7 skipped (clean XCTSkipUnless gate).
- **I.8** — Final regression sweep. All checks clean.

Phase I net: +5 tests (`SemanticIconographyTests`). Total 676 → **681**.

## What's deferred to MVP 3 (recap)

- `pass git` integration (status / push / pull / conflicts).
- System `UndoManager` integration (current `ActionHistory` is in-session only, ~10s window).
- Touch ID / LocalAuthentication unlock-before-reveal.
- Menu-bar (status item) app surface.
- Quick-search / Spotlight indexing.
- FSEvents-based external-change detection.
- App Sandbox + helper tool for sandboxed `Process` spawn.
- `ScrubbingString` secure-string buffer.
- Snapshot tests.
- Localization beyond English.
- Browser auto-fill / extension.

## Verification commands

```sh
# Full suite (default)
xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS'

# Opt-in E2E (requires local pass + gpg)
TEST_RUNNER_KIZBA_E2E=1 xcodebuild test \
  -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' \
  -only-testing:KizbaTests/PassWriteIntegrationTests

# Release build
xcodebuild -scheme Kizba -project Kizba.xcodeproj -configuration Release -destination 'platform=macOS' build

# Grep / find acceptance
rg -n '\bas!\b' Kizba
rg -n 'showSettingsWindow' Kizba
find . -name .DS_Store -not -path '*/.git/*'
rg -n 'Logger.*stdin|print\(.*stdin' Kizba

# SourceGrepTests (the inline-styling + hygiene bans)
xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' \
  -only-testing:KizbaTests/SourceGrepTests
```

## Reference documents

- [`README.md`](../README.md) — public-facing project description.
- [`.ai/plan.md`](plan.md) — full implementation plan.
- [`.ai/decisions.md`](decisions.md) — durable architectural decisions (append-only ledger).
- [`.ai/a11y-audit.md`](a11y-audit.md) — accessibility audit + manual checklist.
- [`.ai/sequoia-smoke.md`](sequoia-smoke.md) — macOS Sequoia smoke test checklist.

## Open follow-ups (non-blocking, transferred to MVP 3 backlog)

- Untracked `.ai/decisions.md` and `.ai/handoff.md` updates from this Phase I sweep — should be `git add`ed when committing.
- Phase F.5's `startObservation` + `waitUntil` test helpers duplicated across reconciliation test files — promote to `KizbaTests/Fixtures/AsyncTestHelpers.swift`.
- 9 a11y gaps documented in `.ai/a11y-audit.md` (5 medium, 4 low). Review before MVP 3 release.
- `LivePassManager` doesn't emit `.bulk` (no FSEvents wiring); MVP 3 will give it a real source.
- `AppState` accumulated 5 `is*Presented` flags + selection + write-ops set + 2 services. Consider an `AppRouter` extraction in MVP 3.
- `EntryFormModel` shared between `.create` / `.edit` modes via single class with two view sheets. Consider `EntryFormBody` view extraction if maintenance pain grows.

## Constraints (must hold throughout MVP 3)

- Zero third-party Swift Packages.
- No QtPass / GPL pass-client source consulted.
- No secret content in logs.
- `PassSecret`, `MetadataPair`, `SecretDraft`, `UndoableAction` not Codable, not CustomStringConvertible/DebugStringConvertible.
- All chat with user in Russian; all code/comments/docs/commits in English.
- Inline styling banned in `Kizba/Presentation/**` outside `DesignSystem/` (Phase C.6 grep tests enforce).
- Repo-wide `as!` and `Logger/print`-stdin banned (Phase C.6 grep tests enforce).
