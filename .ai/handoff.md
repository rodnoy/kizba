Phase: MVP9.5 (folder filter — immediate children)
Status: COMPLETED

Next action: Push main + tag v1.1.0 (или v1.1.1 если v1.1.0 уже отгружен).

Notes:
- EntryListModel.entries folder filter changed from MVP9.3 prefix-match to immediate-children-only semantics.
- New filter: entry.path == folder OR (entry.path has folder+"/" prefix AND suffix has no further "/").
- UX implication: tapping top-level "system" now shows only entries directly in system/* (e.g. 4pda, amazon), NOT entries in system/work/* — user drills into sidebar tree to see subfolder contents. Matches Finder.
- Sidebar tree (FolderTreeBuilder + FolderTreeRow + fold/unfold) untouched — still works correctly.
- Search query bypass preserved — search shows global matches regardless of selectedFolder.
- Tests: adapted 5 existing in EntryListModelTests.swift (top-level count expectations 7/8/5 → flipped to subfolder cases like work/aws → 2, personal/email → 2; topLevelPrefixIncludesAllSubfolders → inverted to topLevelExcludesNestedSubfolders asserting count == 0 and !contains personal/email/gmail; matchesEntryWithExactPath extended with system/foo immediate child + system/work/email grandchild exclusion); added 2 new (excludesGrandchildren for folder="a" excluding a/c/d & a/c/e/f; nestedSelectionExcludesDeeperNesting for folder="a/b" including a/b/c, a/b/d and excluding a/b/e/f).
- Full suite: 1285 tests, 17 skipped, 0 failures (was 1283 — net +2). Release build clean. Grep bans clean (no `as!`, no stdin-logging); old prefix-match comment grep returns 0 hits.
- Commit: 240e28f on main.

Timestamp: 2026-05-19T22:45:09+0200
