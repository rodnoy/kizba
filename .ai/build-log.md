# Build Log — Phase B regression sweep

Date: 2026-05-11 16:20:18 +0200
Phase: B.5 regression sweep

## Commands and results

1. `xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS'`
   - Exit code: `0`
   - Result: `TEST SUCCEEDED`
   - Suite summary: `Executed 827 tests, with 9 tests skipped and 0 failures (0 unexpected)`
   - Last test header: `Test Suite 'KizbaTests.xctest' passed at 2026-05-11 16:19:53.166.`

2. `xcodebuild -scheme Kizba -project Kizba.xcodeproj -configuration Release -destination 'platform=macOS' build`
   - Exit code: `0`
   - Result: `BUILD SUCCEEDED`
   - Last build line: `** BUILD SUCCEEDED **`

3. `rg -n '\bas!\b' Kizba`
   - Result: no matches (grep ban clean)

4. `rg -n 'Logger.*stdin|print\(.*stdin' Kizba`
   - Result: no matches (grep ban clean)

## Verdict

Phase B regression sweep: ALL GREEN — tests passed, Release build succeeded, and grep bans are clean.

Timestamp: 2026-05-11 16:20:18 +0200

---

# Build Log — Phase B.3 PassGitErrorMapper

Date: 2026-05-11
Phase: B.3 mapper + tests

## Commands and results

1. `xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' -only-testing:KizbaTests/PassGitErrorMapperTests`
   - Exit code: `0`
   - Result: `TEST SUCCEEDED`
   - Suite summary: `Executed 19 tests, with 0 failures (0 unexpected)`
   - Full stdout/stderr: `/Users/kirillsimagin/.local/share/opencode/tool-output/tool_e1756cbb4001tYIsMllxM6QASW`

2. `xcodebuild build -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS'`
   - Exit code: `0`
   - Result: `BUILD SUCCEEDED`

3. `rg -n '\bas!\b' Kizba`
   - Exit code: `1`
   - Result: no matches

4. `rg -n 'Logger.*stdin|print\(.*stdin' Kizba`
   - Exit code: `1`
   - Result: no matches

## Verdict

Phase B.3 is green: PassGitErrorMapper and dedicated fixtures/tests pass, app build is green, grep bans are clean.

---

# Build Log — Phase B.2 PassCLI+Git

Date: 2026-05-11
Phase: B.2 CLI extension + git env

## Commands and results

1. `xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' -only-testing:KizbaTests/PassCLIGitTests`
   - Exit code: `0`
   - Result: `TEST SUCCEEDED`
   - Suite summary: `Executed 8 tests, with 0 failures (0 unexpected)`
   - Full stdout/stderr: `/Users/kirillsimagin/.local/share/opencode/tool-output/tool_e175e6392001GgumLLiuj8pDBa`

2. `xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' -only-testing:KizbaTests/PassCLIGitEnvTests`
   - Exit code: `0`
   - Result: `TEST SUCCEEDED`
   - Suite summary: `Executed 5 tests, with 0 failures (0 unexpected)`

3. `xcodebuild build -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS'`
   - Exit code: `0`
   - Result: `BUILD SUCCEEDED`

4. `rg -n '\bas!\b' Kizba`
   - Exit code: `1`
   - Result: no matches

5. `rg -n 'Logger.*stdin|print\(.*stdin' Kizba`
   - Exit code: `1`
   - Result: no matches

## Verdict

Phase B.2 is green: PassCLI git status/pull/push extension and env composition tests pass, app build is green, grep bans are clean.

---

# Build Log — Phase B.4 LivePassGitManager

Date: 2026-05-11
Phase: B.4 actor + tests

## Commands and results

1. `xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' -only-testing:KizbaTests/LivePassGitManagerTests`
   - Exit code: `0`
   - Result: `TEST SUCCEEDED`
   - Suite summary: `Executed 14 tests, with 0 failures (0 unexpected)`
   - Full stdout/stderr: `/Users/kirillsimagin/.local/share/opencode/tool-output/tool_e17647199001rKa4tYTevU6L1s`

2. `xcodebuild build -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS'`
   - Exit code: `0`
   - Result: `BUILD SUCCEEDED`

3. `rg -n '\bas!\b' Kizba`
   - Exit code: `1`
   - Result: no matches

4. `rg -n 'Logger.*stdin|print\(.*stdin' Kizba`
   - Exit code: `1`
   - Result: no matches

## Verdict

Phase B.4 is green: LivePassGitManager actor and dedicated tests pass, app build is green, grep bans are clean.

---

# Build Log — Phase C.1 GitStatusModel scaffold

Date: 2026-05-11
Phase: C.1 GitStatusModel scaffold

## Commands and results

1. `xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' -only-testing:KizbaTests/GitStatusModelTests`
   - Exit code: `0`
   - Result: `TEST SUCCEEDED`
   - Suite summary: `Executed 15 tests, with 1 test skipped and 0 failures (0 unexpected)`
   - Last test header: `Test Suite 'GitStatusModelTests' passed at 2026-05-11 16:39:39.844.`

2. `xcodebuild build -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS'`
   - Exit code: `0`
   - Result: `BUILD SUCCEEDED`
   - Last build line: `** BUILD SUCCEEDED **`

3. `rg -n '\bas!\b' Kizba`
   - Result: no matches (grep ban clean)

4. `rg -n 'Logger.*stdin|print\(.*stdin' Kizba`
   - Result: no matches (grep ban clean)

## Verdict

Phase C.1 is green: GitStatusModel scaffold and dedicated tests pass, app build is green, grep bans are clean.

---

# Build Log — Phase C.2 GitStatusModel observeChanges + stop

Date: 2026-05-11
Phase: C.2 observe-changes hook

## Commands and results

1. `xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' -only-testing:KizbaTests/GitStatusModelObserveTests`
   - Exit code: `0`
   - Result: `TEST SUCCEEDED`
   - Suite summary: `Executed 4 tests, with 0 failures (0 unexpected)`

2. `xcodebuild build -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS'`
   - Exit code: `0`
   - Result: `BUILD SUCCEEDED`

3. `rg -n '\bas!\b' Kizba`
   - Exit code: `1`
   - Result: no matches

4. `rg -n 'Logger.*stdin|print\(.*stdin' Kizba`
   - Exit code: `1`
   - Result: no matches

## Verdict

Phase C.2 is green: `GitStatusModel.observeChanges()` and `stop()` are covered by dedicated tests, app build is green, and grep bans are clean.

---

# Build Log — Phase C.3 AppState optional gitStatusModel

Date: 2026-05-11
Phase: C.3 AppState extension

## Commands and results

1. `xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' -only-testing:KizbaTests/AppStateTests`
   - Exit code: `0`
   - Result: `TEST SUCCEEDED`
   - Suite summary: `Executed 6 tests, with 0 failures (0 unexpected)`
   - Last test header: `Test Suite 'AppStateTests' passed at 2026-05-11 16:56:11.488.`

2. `xcodebuild build -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS'`
   - Exit code: `0`
   - Result: `BUILD SUCCEEDED`
   - Last build line: `** BUILD SUCCEEDED **`

3. `rg -n '\bas!\b' Kizba`
   - Exit code: `1`
   - Result: no matches

4. `rg -n 'Logger.*stdin|print\(.*stdin' Kizba`
   - Exit code: `1`
   - Result: no matches

## Verdict

Phase C.3 is green: `AppState` now has optional `gitStatusModel` with default nil, `AppStateTests` includes `testGitStatusModel_defaultNil`, build is green, and grep bans remain clean.

---

# Build Log — Phase C.4 AppEnvironment wiring

Date: 2026-05-11
Phase: C.4 AppEnvironment wiring

## Commands and results

1. `xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' -only-testing:KizbaTests/AppEnvironmentGitWiringTests`
   - Exit code: `0`
   - Result: `TEST SUCCEEDED`
   - Suite summary: `Executed 3 tests, with 0 failures (0 unexpected)`

2. `xcodebuild build -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS'`
   - Exit code: `0`
   - Result: `BUILD SUCCEEDED`

3. `rg -n '\bas!\b' Kizba`
   - Exit code: `1`
   - Result: no matches

4. `rg -n 'Logger.*stdin|print\(.*stdin' Kizba`
   - Exit code: `1`
   - Result: no matches

## Verdict

Phase C.4 is green: AppEnvironment startup git wiring landed with dedicated unit tests, app build is green, and grep bans are clean.

---

# Build Log — Phase C.5 GitStatusBadge + sidebar mount

Date: 2026-05-11
Phase: C.5 GitStatusBadge view + sidebar mount

## Commands and results

1. `xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' -only-testing:KizbaTests/GitStatusBadgeTests`
   - Exit code: `0`
   - Result: `TEST SUCCEEDED`
   - Suite summary: `Executed 10 tests, with 0 failures (0 unexpected)`

2. `xcodebuild build -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS'`
   - Exit code: `0`
   - Result: `BUILD SUCCEEDED`

3. `rg -n '\bas!\b' Kizba`
   - Exit code: `1`
   - Result: no matches

4. `rg -n 'Logger.*stdin|print\(.*stdin' Kizba`
   - Exit code: `1`
   - Result: no matches

## Verdict

Phase C.5 is green: `GitStatusBadge` was added and mounted in sidebar with `RootSplitView` wiring, dedicated badge tests pass, app build is green, and grep bans remain clean.
