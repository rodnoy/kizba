# Kizba — MVP 3 Implementation Plan

Native macOS SwiftUI client for `pass(1)`. MVP 1 (read-only) and MVP 2 (writes + design system + Undo + Toast + sanitized Diagnostics) shipped. MVP 3 scope is defense-in-depth, tech-debt cleanup, FSEvents auto-refresh, accessibility improvements, Touch ID per-reveal, and final polish.

This document is the full, authoritative MVP 3 plan. It is organized into phases (A–F). Each phase contains discrete tasks, verification steps, DoD (Definition of Done), and sequencing constraints.

Goals & non-goals
- Goals
  - Phase A — Defense-in-depth: consolidate async test helpers, add SourceGrepTests rules, add code-review checklist.
  - Phase B — AppRouter + EntryFormBody refactor: centralize presentation flags & selection, extract shared entry form body, consolidate generate sub-sheet wiring.
  - Phase C — FSEvents external-change detection: StoreWatching protocol, FSEventsStoreWatcher implementation, LivePassManager integration, debounced bulk emits.
  - Phase D — Accessibility medium gaps: 5 medium items (SecretRevealField accessibility value, KeyValueEditor row accessibility, SecureField for passwords, dynamic layout in FormFieldRow on large type, toolbar hints).
  - Phase E — Touch ID per-reveal: BiometricAuthenticating protocol, LocalAuth implementation, opt-in setting, SecretRevealField gating.
  - Phase F — Polish & release prep: a11y re-run, Sequoia smoke re-run, README updates, decisions/handoff update, final regression sweep.

- Non-goals (deferred)
  - pass git integration, menu-bar/status item, App Sandbox helper, ScrubbingString, system UndoManager, snapshot tests, per-path FSEvents delta, browser auto-fill, localization beyond English, third-party Swift packages.

Baseline & constraints
- Swift 5.10, Xcode 15.4+, macOS target 14.0.
- Strict concurrency enforced; warnings-as-errors for app target.
- No third-party dependencies; use system frameworks only.
- All code, comments, docs, commits in English. User chat in Russian.
- Security & grep bans in .ai/decisions.md remain authoritative (no as!, no Logger.*stdin or print(...stdin), secret types not Codable/CustomStringConvertible, inline styling ban for Presentation outside DesignSystem).

Phases overview (ordered A → B → C → D → E → F). Hard gates are noted where relevant.

Phase A — Defense-in-depth & test hygiene (~3 days)
- A.1 Extract AsyncTestHelpers
  - Move common test helpers (startObservation, waitUntil) to KizbaTests/Fixtures/AsyncTestHelpers.swift.
  - Remove duplicates in test files.
  - Add AsyncTestHelpersTests smoke tests.
  - DoD: single definition for helpers; rg 'func startObservation|func waitUntil' KizbaTests returns one definition each; full suite green.

- A.2 SourceGrepTests: @Observable on Presentation models
  - New rule: every Kizba/Presentation/**/*Model.swift with `final class <Name>Model` must contain `@Observable`.
  - Allow-list via file comment `// kizba:not-observable-model`.
  - Add fixtures & test cases.
  - DoD: SourceGrepTests passes; rule fires on negative fixture.

- A.3 SourceGrepTests: forbid Model() constructors inside sheet/popover/fullScreenCover bodies
  - Rule forbids `\w+Model(` inside SwiftUI .sheet/.popover/.fullScreenCover closure bodies.
  - Allow-list via `// kizba:allow-sheet-init`.
  - DoD: SourceGrepTests passes; rule triggers on negative fixture.

- A.4 Code-review checklist
  - Add .ai/code-review-checklist.md: include rules such as avoid onChange(of: enumWithAssoc), LAError leakage, grep-bans, a11y rules.
  - Add link from AGENTS.md to the checklist.
  - DoD: file exists and AGENTS.md references it.

- A.5 Regression sweep
  - Full test run + grep checks.
  - DoD: xcodebuild test green; SourceGrepTests green; grep bans clean.

Phase B — AppRouter + EntryFormBody refactor

**Theme:** Extract navigation/presentation state into `AppRouter`; consolidate `NewEntrySheet` / `EditEntrySheet` into shared `EntryFormBody`.

This document continues with the full MVP 3 plan as previously specified in project planning artifacts.

(End of file)
