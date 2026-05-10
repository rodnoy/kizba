# Kizba — MVP 3 Phase A Micro-Plan

Defense-in-depth & test hygiene. 5 tasks, strict order A.1 → A.5.

Baseline: HEAD `4cd0467`, 692 tests (8 skipped, 0 failures), all grep bans clean.

## Constraints

- Zero third-party packages.
- New grep rules go in `KizbaTests/SourceGrepTests.swift`.
- Test suite must stay green after every task.
- All code/comments/commits in English.
- No code implementation in this plan — worker agents execute.

---

## Task A.1 — Extract AsyncTestHelpers

- **Objective:** Consolidate duplicated `startObservation(of:)` and `waitUntil(_:timeout:)` helpers from 4 test files into a single shared fixture.
- **Files to create:**
  - `KizbaTests/Fixtures/AsyncTestHelpers.swift` — two `internal` free functions (or an `enum AsyncTestHelpers` namespace):
    - `func waitUntil(_ predicate: @MainActor () -> Bool, timeout: TimeInterval, message: String, file: StaticString, line: UInt) async` — polls every 10ms, XCTFail on timeout.
    - `func startObservation<M>(model: M, observe: @escaping (M) async -> Void) async -> Task<Void, Never>` — spawns task, yields 5×, sleeps 20ms. Generic over model type; callers pass a closure like `{ await $0.observeChanges() }`.
- **Files to modify:**
  - `KizbaTests/EntryListReconciliationTests.swift` — remove private `waitUntil` (line ~36) and `startObservation` (line ~80); call shared versions.
  - `KizbaTests/EntryDetailReconciliationTests.swift` — remove private `waitUntil` (line ~34) and `startObservation` (line ~62); call shared versions.
  - `KizbaTests/ConcurrentWriteLockoutTests.swift` — remove private `waitUntil` (line ~382); call shared version. Keep `waitUntilEditing` if it has custom logic beyond `waitUntil`.
  - `KizbaTests/ActionHistoryTests.swift` — remove private `waitUntil` (line ~237); call shared version.
- **Verification:**
  ```sh
  # Exactly one definition of each helper
  rg 'func waitUntil\(' KizbaTests --count-matches | grep -v ':0$'
  # Should show only AsyncTestHelpers.swift:1 (plus any specialized wrappers)
  
  rg 'func startObservation' KizbaTests --count-matches | grep -v ':0$'
  # Should show only AsyncTestHelpers.swift:1
  
  # Full suite green
  xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS'
  ```
- **DoD:** `rg 'func startObservation|func waitUntil' KizbaTests` returns one definition each (in AsyncTestHelpers.swift); all 4 consumer files import/call the shared version; suite ≥ 692 tests, 0 failures.
- **Estimated LOC:** +60 new, −120 removed across 4 files. Net: −60.
- **Risks:** `startObservation` signatures differ slightly across files (EntryListModel vs EntryDetailModel). The generic closure approach handles this. `waitUntilEditing` in ConcurrentWriteLockoutTests may need to stay as a thin wrapper.
- **Commit:** `refactor(mvp3-a1): extract AsyncTestHelpers — consolidate waitUntil + startObservation`

---

## Task A.2 — @Observable grep rule for *Model.swift

- **Objective:** Add a SourceGrepTests rule ensuring every `Kizba/Presentation/**/*Model.swift` file containing `final class …Model` also contains `@Observable`. Prevents the MVP 2 post-ship regression where a model class lost its `@Observable` annotation.
- **Files to modify:**
  - `KizbaTests/SourceGrepTests.swift` — add test method `testObservableAnnotationOnPresentationModels()`:
    1. Enumerate `*.swift` files under `Kizba/Presentation/` matching `*Model.swift` filename.
    2. For each file, check if it contains `final class \w+Model` (regex).
    3. If yes, assert the file also contains `@Observable` somewhere before or on the class declaration line.
    4. Allow-list escape: if the file contains `// kizba:not-observable-model`, skip it.
    5. Collect violations and `XCTFail` with file paths.
- **Files to create:** None.
- **Verification:**
  ```sh
  # Rule-only test
  xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' \
    -only-testing:KizbaTests/SourceGrepTests/testObservableAnnotationOnPresentationModels
  
  # Full suite still green
  xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS'
  ```
- **DoD:** New test method exists and passes; deliberately removing `@Observable` from any existing `*Model.swift` would cause the test to fail (verify mentally or via a temporary edit during development).
- **Estimated LOC:** +40–50 lines in SourceGrepTests.swift.
- **Risks:** False positives on non-view-model files named `*Model.swift` (e.g., domain model types). Mitigated by scoping to `Kizba/Presentation/` only and requiring `final class` pattern.
- **Commit:** `test(mvp3-a2): SourceGrepTests — @Observable annotation rule for Presentation models`

---

## Task A.3 — Sub-sheet model constructor grep rule

- **Objective:** Add a SourceGrepTests rule forbidding model constructor calls (`\w+Model(`) inside `.sheet { }`, `.popover { }`, or `.fullScreenCover { }` closure bodies. Prevents the MVP 2 post-ship regression where `GeneratePasswordModel` was recreated on every sheet re-render.
- **Files to modify:**
  - `KizbaTests/SourceGrepTests.swift` — add test method `testNoModelConstructorInSheetBody()`:
    1. Scan all `*.swift` files under `Kizba/Presentation/` (including DesignSystem — sheet hosts could be anywhere).
    2. Strategy: multi-line scan. Find `.sheet {`, `.popover {`, `.fullScreenCover {` openers. Track brace depth. Within the closure body, flag any `\w+Model(` pattern.
    3. Allow-list escape: lines containing `// kizba:allow-sheet-init` are skipped.
    4. Collect violations and `XCTFail`.
  - **Alternative simpler strategy** (recommended if multi-line brace tracking is fragile): line-by-line heuristic — flag any line in `Kizba/Presentation/**/*.swift` that contains BOTH a sheet/popover/fullScreenCover opener AND a `Model(` constructor on the same line or within a 5-line window. Document the heuristic limitation.
- **Files to create:** None.
- **Verification:**
  ```sh
  xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' \
    -only-testing:KizbaTests/SourceGrepTests/testNoModelConstructorInSheetBody
  
  xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS'
  ```
- **DoD:** New test method exists and passes on current codebase (no violations). The rule would catch `SomeModel(...)` inside a `.sheet { ... }` body.
- **Estimated LOC:** +50–80 lines in SourceGrepTests.swift.
- **Risks:** Brace-depth tracking in Swift source is inherently heuristic (strings, comments can contain braces). A simpler line-proximity heuristic may be more robust. The worker should choose the approach that reliably passes on the current codebase without false positives.
- **Commit:** `test(mvp3-a3): SourceGrepTests — ban model constructors inside sheet/popover bodies`

---

## Task A.4 — Code review checklist + AGENTS.md cross-link

- **Objective:** Create `.ai/code-review-checklist.md` codifying manual review rules that are NOT automatable as grep tests. Cross-link from project agent instructions.
- **Files to create:**
  - `.ai/code-review-checklist.md` — contents:
    1. `.onChange(of: enumWithAssociatedValue)` — use a derived `stateID: Int` instead (SwiftUI compares by identity, not equality, for enums with associated values; leads to missed or spurious firings).
    2. `@State` sub-models in sheets — must be `@State private var` in the PARENT view, not constructed inside the `.sheet { }` body (A.3 grep catches constructor-in-body; this rule covers the design intent).
    3. Toast messages must never contain secret material — only entry paths.
    4. New secret-bearing types must NOT conform to Codable / CustomStringConvertible / CustomDebugStringConvertible.
    5. `LAContext` must be fresh per `authenticate()` call — never reuse.
- **Files to modify:**
  - `.ai/AGENTS.md` or root `AGENTS.md` (if it exists) — add a line: `- Before merging, review against `.ai/code-review-checklist.md`.`
  - If no `AGENTS.md` exists in the repo, create a minimal one at `.ai/AGENTS.md` with the cross-link.
- **Verification:**
  ```sh
  # File exists
  test -f .ai/code-review-checklist.md && echo OK
  
  # Cross-link present
  rg 'code-review-checklist' .ai/
  ```
- **DoD:** `.ai/code-review-checklist.md` exists with ≥ 5 items; at least one `.ai/` file references it.
- **Estimated LOC:** +30–40 lines (checklist) + 1–3 lines (cross-link).
- **Risks:** None. Pure documentation.
- **Commit:** `docs(mvp3-a4): add code-review-checklist.md + AGENTS.md cross-link`

---

## Task A.5 — Phase A regression sweep

- **Objective:** Verify the full test suite, all grep bans, and repo hygiene after A.1–A.4.
- **Files to modify:** None (verification only). Update `.ai/handoff.md` to mark Phase A complete.
- **Verification:**
  ```sh
  # Full suite
  xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS'
  
  # SourceGrepTests specifically (includes new A.2 + A.3 rules)
  xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' \
    -only-testing:KizbaTests/SourceGrepTests
  
  # Repo-wide hygiene
  rg -n '\bas!' Kizba
  rg -n 'showSettingsWindow' Kizba
  find . -name .DS_Store -not -path '*/.git/*'
  rg -n 'Logger.*stdin|print\(.*stdin' Kizba
  
  # Release build
  xcodebuild -scheme Kizba -project Kizba.xcodeproj -configuration Release -destination 'platform=macOS' build
  ```
- **DoD:** All commands exit 0; suite ≥ 692 tests, 0 failures; no grep ban violations; release build green. Phase A is complete; Phase B can begin.
- **Estimated LOC:** 0 (verification + handoff update only).
- **Risks:** None.
- **Commit:** `chore(mvp3-a5): Phase A regression sweep — all green`

---

## Summary

| Task | Title | Net LOC | New test methods |
|------|-------|---------|-----------------|
| A.1 | Extract AsyncTestHelpers | −60 | 0 (refactor) |
| A.2 | @Observable grep rule | +45 | +1 |
| A.3 | Sheet model constructor grep rule | +65 | +1 |
| A.4 | Code review checklist | +35 | 0 |
| A.5 | Regression sweep | 0 | 0 |
| **Total** | | **+85** | **+2** |

Phase A DoD: AsyncTestHelpers consolidated; 2 new grep rules in SourceGrepTests; `.ai/code-review-checklist.md` exists; full suite green; Phase B can begin.
