# Kizba — Handoff

## Current state

**MVP 3 — Phase A in progress.** Micro-plan for Phase A (Defense-in-depth & test hygiene) written to `.ai/plan.md`. No MVP 3 code written yet.

Repository at HEAD `4cd0467`. MVP 2 shipped. Test suite: **692 tests, 8 skipped, 0 failures**. Release build green. All grep bans clean.

## Next immediate action

**A.1 — Extract AsyncTestHelpers.** — COMPLETED

`KizbaTests/Fixtures/AsyncTestHelpers.swift` created with shared `waitUntil` and `startObservation` helpers. Duplicates removed from `EntryListReconciliationTests`, `EntryDetailReconciliationTests`, `ConcurrentWriteLockoutTests`, `ActionHistoryTests`.

After A.1: proceed to A.2 → A.3 → A.4 → A.5 in strict order.

**A.2 — @Observable grep rule.** — COMPLETED

`KizbaTests/SourceGrepTests.swift` updated with `testPresentationModelsRequireObservable()`. Fixtures added under `Kizba/Presentation/SourceGrepFixtures/` to exercise the rule. Commit 67f2ca45 (2026-05-10).

Step bumped to 9.8 after completing Phase A.1 (AsyncTestHelpers) and A.2 (SourceGrepTests @Observable) — next action: A.3.

## Phase A task sequence

1. **A.1** Extract AsyncTestHelpers (refactor, ~−60 LOC net)
2. **A.2** @Observable grep rule in SourceGrepTests (+1 test method)
3. **A.3** Sheet model constructor grep rule in SourceGrepTests (+1 test method)
4. **A.4** `.ai/code-review-checklist.md` + AGENTS.md cross-link (docs only)
5. **A.5** Regression sweep (verification only)

## Phase A DoD

- `KizbaTests/Fixtures/AsyncTestHelpers.swift` exists; `waitUntil` and `startObservation` have exactly one definition each.
- 2 new test methods in `SourceGrepTests`: `testObservableAnnotationOnPresentationModels`, `testNoModelConstructorInSheetBody`.
- `.ai/code-review-checklist.md` exists with ≥ 5 items.
- Full suite ≥ 692 tests, 0 failures.
- Release build green.
- All existing + new grep bans clean.

## Verification commands

```sh
# Full suite
xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS'

# SourceGrepTests only
xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' \
  -only-testing:KizbaTests/SourceGrepTests

# Release build
xcodebuild -scheme Kizba -project Kizba.xcodeproj -configuration Release -destination 'platform=macOS' build

# Repo hygiene
rg -n '\bas!' Kizba
rg -n 'Logger.*stdin|print\(.*stdin' Kizba
find . -name .DS_Store -not -path '*/.git/*'
```

## Constraints (must hold throughout MVP 3)

- Zero third-party Swift Packages.
- No secret content in logs.
- Secret-bearing types not Codable/CustomStringConvertible.
- All code/comments/commits in English.
- Inline styling banned in Presentation outside DesignSystem.
- New grep rules: @Observable on Presentation models (A.2); no model constructors in sheet bodies (A.3).

## Recent activity

- A.3 — Sheet model constructor grep rule. — COMPLETED

- `KizbaTests/SourceGrepTests.swift` updated with `testNoModelConstructorInSheetBody()`. Fixtures added under `Kizba/Presentation/SourceGrepFixtures/` to exercise the rule. Commit 5aa5384 (2026-05-10).

Next immediate action: A.4 — Code-review checklist

## A.4 status

- A.4 — Code-review checklist — IN-PROGRESS

Commit: <COMMIT_HASH_PLACEHOLDER>
Date: 2026-05-10

Next immediate action after A.4: A.5 — Regression sweep
