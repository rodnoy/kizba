Phase: MVP6.B (COMPLETED)
Status: Phase B SHIPPED — Settings tabs + Save feedback + InfoTooltip

Next action: Run smart-planner to open Phase C (App-wide tooltips). Replace .ai/plan.md with operational Phase C plan.

Notes:
- B.4: Applied InfoTooltip to 10 controls across Settings tabs:
  * GeneralTab: clipboard delay, menu bar toggle, recents visibility toggle, recents limit (4)
  * SecurityTab: Touch ID per-reveal toggle (1)
  * GitTab: git operation timeout, store path override (2)
  * AdvancedTab: pass / gpg / pinentry binary overrides (3)
- Replaced inline `helpText` with `infoText` on these rows; B.1 priority rule (infoText suppresses helpText, errorText still wins) takes effect. 6 `helpText:"…"` literals removed across the four tab files; `Menu Bar` row, plus the three Advanced binary rows previously had no helpText and only gained `infoText`.
- `infoAccessibilityLabel:` was NOT specified for any row — the default "More information about <label>" from `FormFieldRow.defaultInfoAccessibilityLabel(for:)` is contextually adequate for all 10 controls.
- No changes to persistence, validation, Stepper bounds, Re-detect action, NSOpenPanel pickers, or footer behaviour.
- `rg infoText: Kizba/Presentation/Features/Settings/Tabs/` → exactly 10 matches. `rg 'helpText:.*"' Kizba/Presentation/Features/Settings/Tabs/` → 0 matches.
- DS-literal grep on Tabs/ (`Color.*`, numeric `cornerRadius:`, numeric `.opacity(0.x)`) → 0 hits. `as!` ban → 0 hits in Kizba/. `Logger.*stdin|print(.*stdin` → only the self-refs in SourceGrepTests.swift.
- Phase B acceptance criteria — ALL MET:
  * InfoTooltip DS component + FormFieldRow.infoText (B.1) ✓
  * SettingsModel dirty-tracking + async SaveState with flash (B.2) ✓
  * Save button disabled state + inline status text (B.2) ✓
  * TabView split 4 tabs + shared footer (B.3) ✓
  * Recents under General (B.3) ✓
  * ≥10 InfoTooltips applied (B.4) ✓
  * Touch ID behaviour unchanged (verbatim move, Phase D will rework) ✓
- Full suite: 1038 tests, 17 skipped, 0 failures. Build OK (Debug + Release prior in B.3). DS grep + bans clean.
- Commits this phase: 3476416 (B.1), a9d0953 (B.2), b1b25cb (B.3), <new B.4 — added after commit>.

Timestamp: 2026-05-17T16:53:00+02:00
