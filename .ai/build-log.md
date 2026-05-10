Build verification — Phase B.5 regression sweep

Date: 2026-05-10
Git HEAD: 7645f56

Commands executed:

- xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS'
- xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' -only-testing:KizbaTests/SourceGrepTests
- rg -n '\\bas!\\b' Kizba
- rg -n 'Logger.*stdin|print\\(.*stdin' Kizba
- rg -n 'kizba:not-observable-model|kizba:allow-sheet-init'
- xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' -only-testing:KizbaTests/EntryListReconciliationTests || true
- xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' -only-testing:KizbaTests/EntryDetailReconciliationTests || true

High-level results:

- Full test suite: PASSED — 704 tests executed, 8 skipped, 0 failures
- SourceGrepTests only: PASSED — 19 tests executed, 0 failures
- EntryListReconciliationTests (smoke): PASSED — 14 tests executed, 0 failures
- EntryDetailReconciliationTests (smoke): PASSED — 9 tests executed, 0 failures

Repo greps:

- No occurrences of `as!` in Kizba/ (rg found no matches)
- No Logger/stdin or print(...stdin) patterns found in Kizba/ (rg found no matches)
- Allow-list comments present where expected:
  - Kizba/Presentation/SourceGrepFixtures/ObservableModelAllowed.swift: `// kizba:not-observable-model`
  - Kizba/Presentation/SourceGrepFixtures/SheetInitAllowed.swift: `// kizba:allow-sheet-init`

Logs: full xcodebuild output saved to developer's DerivedData xcresult and local tool capture.

No build errors.
