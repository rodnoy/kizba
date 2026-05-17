Phase: MVP5.E.2
Status: COMPLETED

Next action: Run smart-builder to run Task E.3 (final regression: full test suite + Release build + grep bans)

Notes:
- README updated with MVP5 features (⌘K search, favorites, recents, menu-bar); deferred section trimmed (D.4 hotkey retained as deferred).
- .ai/decisions.md: appended 2026-05-17 MVP 5 section with durable decisions (boost values verified against LiveSearchEngine; FIFO cap and UserDefaults keys verified against stores).
- .ai/sequoia-smoke.md: added 6 MVP5 smoke-check rows.
- .ai/a11y-audit.md: added SearchOverlay + MenuBarPopover sections.
- Build OK; grep bans clean (production code).
- Reality check vs plan: StatusItemController uses `NSStatusItem.variableLength`, NOT `.squareLength` as the plan note suggested — decisions.md reflects the actual code.

Timestamp: 2026-05-17T13:42:04+0200
