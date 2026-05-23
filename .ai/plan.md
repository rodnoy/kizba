# Kizba Night migration plan

This file captures the 11-step migration plan for the "Kizba Night" design-system migration. Step 1 is complete; Step 2 below is expanded into actionable subtasks.

1. Step 1 — Token foundation (completed)
   - Add surfaceCard, surfaceCardHover, accentSecondary, accentStrong to ColorTokens and supply day-1 aliases in all theme variants. (COMPLETED)

2. Step 2 — Contrast tests (expanded)
   - ID: step-2
   - Goal: Implement automated contrast tests that lock WCAG-based contracts for role tokens introduced in Step 1 and prevent regressions during later visual retune.
   - Priority: high
   - Estimated effort: 2-3 hours

   Subtasks:
   - 2.1 — Boilerplate + test constants
     - Files: `KizbaTests/KizbaNightContrastTests.swift` (new)
     - Work: Add test class scaffold, import helpers, define `futureDarkSurface` constant and minimal smoke test referencing the new tokens (surfaceCard, surfaceCardHover, accentSecondary, accentStrong). This ensures compilation and serves as a landing place for further tests.
     - Executor: smart-worker
     - Verification: `xcodebuild test -scheme "Kizba" -destination 'platform=macOS'` (or `swift test` fallback)
     - Acceptance: test file compiles and test runner executes; smoke test passes.

   - 2.2 — onSurface / onSurfaceMuted vs surface / surfaceCard
     - Files: `KizbaTests/KizbaNightContrastTests.swift` (append tests)
     - Work: Add tests asserting WCAG ratios: onSurface/surface >= 7.0, onSurfaceMuted/surface >= 4.5 for all variants.
     - Executor: smart-worker
     - Verification: test run
     - Acceptance: tests pass or fail intentionally to signal need for Step 3.

   - 2.3 — Accent contrast
     - Files: `KizbaTests/KizbaNightContrastTests.swift`
     - Work: Add tests asserting onAccent/accent and onAccent/accentSecondary >= 4.5.
     - Executor: smart-worker
     - Verification: test run
     - Acceptance: tests pass or fail intentionally to signal need for Step 3.

   - 2.4 — onAccent vs accentMuted
     - Files: same
     - Work: Add tests ensuring onAccent/accentMuted >= 4.5 where relevant.
     - Executor: smart-worker
     - Verification: test run
     - Acceptance: tests pass.

   - 2.5 — Password reveal (secretMask) vs future dark surface
     - Files: same
     - Work: Add test asserting that onSurface composited over secretMask over surface meets 7:1 for dark variant; if not, this failure is expected and indicates Step 3 adjustments.
     - Executor: smart-worker
     - Verification: test run
     - Acceptance: test run produces metrics; failures are actionable.

   - 2.6 — HighContrast non-regression
     - Files: same
     - Work: Ensure HC variants do not regress standard metrics; mirror assertions in existing `ThemeTokenTests`.
     - Executor: smart-worker
     - Verification: test run
     - Acceptance: HC metrics >= standard metrics.

   - 2.7 — Review & triage
     - Files: .ai/plan.md, .ai/handoff.md
     - Work: smart-reviewer reviews tests, triages failures, and recommends Step 3 adjustments (colors/opacity changes).
     - Executor: smart-reviewer
     - Verification: review notes
     - Acceptance: triage completed.

3. Step 3 — Dark retune (color adjustments) — deferred
4. Step 4 — Card variants
5. Step 5 — Button variants
6. Step 6 — Composites
7. Step 7 — Icons
8. Step 8 — EntryDetail rewrite
9. Step 9 — Sheets audit
10. Step 10 — Final pass & snapshots
11. Step 11 — Release & migration notes
