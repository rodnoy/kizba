# Kizba — Handoff

## Current state

**MVP 3 — Phase A in progress.** Micro-plan for Phase A (Defense-in-depth & test hygiene) written to `.ai/plan.md`. No MVP 3 code written yet.

Repository at HEAD `c090b81`. MVP 2 shipped. Test suite: **699 tests, 8 skipped, 0 failures**. Release build green. All grep bans clean.

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

- A.4 — Code-review checklist — COMPLETED

Commit: 158e628e15c57bd3442be4378fbc402704efb5ff
Date: 2026-05-10

Next immediate action after A.4: A.5 — Regression sweep — COMPLETED

Recent verification: focused test and full test suite executed; all tests passed. Commit c090b81 (2026-05-10) updated CodeReviewChecklistTests to improve path discovery for .ai/code-review-checklist.md.

Next immediate action: B.1 — AppRouter scaffold — COMPLETED

Commit: 70e88f7
Date: 2026-05-10

Next immediate action after B.1: B.2 — AppRouter call-site migration

## B.2 — AppRouter call-site migration

- Status: COMPLETED
- Commits:
  - feat(mvp3): migrate presentation call-sites to AppRouter (B.2) — b7c80ce
  - fix(mvp3): make router-backed bindings mutable via Binding wrapper — c741098
- Date: 2026-05-10

Next immediate action after B.2: run focused verification tests and create/update .ai/build-log.md (and .ai/build-errors.md if needed).

## Phase B progress

- **B.4 — EntryFormBody extraction** — COMPLETED

- Commit: 7645f56
- Date: 2026-05-10

Next immediate action after B.4: B.5 — Phase B regression — COMPLETED

Verification run (this file updated after running tests):

- Focused AppRouter tests: PASSED — 3 tests executed, 0 failures.
- Full test suite: PASSED — 704 tests executed, 8 skipped, 0 failures.

Verification metadata:

- Git HEAD: 7645f56
- Date: 2026-05-10

Next immediate action: C.1 — StoreWatching protocol — IN PROGRESS

### C.1 — StoreWatching protocol — COMPLETED

- Commit: bc31866949a7d4107d91b52ced5095465e9c58ce
- Date: 2026-05-10

Next immediate action after C.1: C.2

### C.2 — Stabilize FakeStoreWatcher tests — COMPLETED

- Commit: 4bfb007
- Date: 2026-05-10

Short note: Stabilized FakeStoreWatcherTests by registering XCTestExpectation signals from subscriber Tasks to ensure continuations are present before simulateChange() is invoked. Tests now use async expectation helpers (`fulfillment(of:timeout:)`) and call start/stop appropriately.

### C.3 — FSEventsStoreWatcher — COMPLETED

- Commit: 9505f54
- Date: 2026-05-10

Added `Kizba/Infrastructure/Store/FSEventsStoreWatcher.swift` (actor-backed FSEvents watcher with DispatchQueue confinement, debounced emits) and opt-in test `KizbaTests/FSEventsStoreWatcherTests.swift` (skipped by default). Build verification passed: full suite 708 tests, 9 skipped, 0 failures.

### C.4 — TempStoreFixture — COMPLETED

- Added `KizbaTests/Fixtures/TempStoreFixture.swift`: test-only helper (instance + static API) for creating and mutating temporary stores used by FSEvents and scanner tests. Minimal Foundation-only implementation; includes write/touch/delete/remove helpers and legacy instance methods (`createStandardLayout`, `createEmptyStore`, `cleanup`) used by existing tests.

Next immediate action after C.4: C.5

### C.5 — LivePassManager integration with StoreWatching — COMPLETED

- Commit: feat(mvp3): integrate StoreWatching into LivePassManager (C.5)
- Date: 2026-05-10
- Notes: Added optional watcher injection, lazy start/stop on subscriber lifecycle, and tests using FakeStoreWatcher.

### C.6 — Wire real FSEventsStoreWatcher into AppEnvironment.live — COMPLETED

- Commit: 1480d37
- Date: 2026-05-10
- Notes: `AppEnvironment.live()` now instantiates `FSEventsStoreWatcher()` and passes it into `LivePassManager(..., storeWatcher:)`. Previews and tests that use `preview()` keep existing behaviour (no watcher injected).

Next immediate action: C.7 — Phase C regression (verification)

### C.7 — Phase C regression — COMPLETED

Completed verification: full suite PASSED — 714 tests executed, 9 skipped, 0 failures. Opt-in FSEvents test SKIPPED locally; manual smoke instructions in .ai/build-log.md.

Next immediate action: D.1 — Phase D (Accessibility medium gaps)

When Phase C regression completes: mark C.7 — COMPLETED and set next action to D.1.

D.1 — SecretRevealField Accessibility Value — COMPLETED

- Commit: feat(a11y): SecretRevealField accessibilityValue (D.1)
- Date: 2026-05-10
- Notes: Added accessibilityValue modifier to the reveal toggle and a pure helper
  SecretRevealField.accessibilityValueText(isRevealed:) with unit test.

D.2 — KeyValueEditor accessibility — COMPLETED

Next immediate action: D.3 — Accessibility smoke & review
 

D.3 — FormFieldRow Dynamic Type Vertical Layout — COMPLETED

Next immediate action: D.4 — Accessibility sweep review

### Phase D progress

D.4 — Accessibility sweep review — COMPLETED

D.5 — Toolbar accessibility hints — COMPLETED

D.6 — Audit doc updates — COMPLETED

**E.1 — Phase E (Touch ID per-reveal gate) — COMPLETED**

E.2 — LocalAuthBiometricAuthenticator — COMPLETED

Next immediate action: E.3 — Phase E (wiring into AppEnvironment)

### D.3 verification

- FormFieldRowAccessibilityTests: PASSED (2 tests, 0 failures)
- SourceGrepTests: PASSED (19 tests, 0 failures)
- Full suite: PASSED (718 tests, 9 skipped, 0 failures)
- Grep bans: clean (no 'as!' or stdin-logging patterns found)

Verification date: 2026-05-10
Git HEAD: c090b81

## E.3 status

- E.3 — Phase E (wiring into AppEnvironment) — COMPLETED — Verified via focused and full test runs on 2026-05-10

Next immediate action: E.4 — (see .ai/plan.md for next step) 
