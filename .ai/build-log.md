# Build Log — Phase A Regression Sweep

Date: 2026-05-11
Phase: A.7 / A.8 full regression

## Commands and results

1. `xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS'`
   - Exit code: `0`
   - Result: `TEST SUCCEEDED`
   - Suite summary: `Executed 763 tests, with 9 tests skipped and 0 failures (0 unexpected)`
   - Full stdout/stderr: `/Users/kirillsimagin/.local/share/opencode/tool-output/tool_e173ea6c2001KPM1O0a902L8pj`

2. `xcodebuild -scheme Kizba -project Kizba.xcodeproj -configuration Release -destination 'platform=macOS' build`
   - Exit code: `0`
   - Result: `BUILD SUCCEEDED`
   - Full stdout/stderr: `/Users/kirillsimagin/.local/share/opencode/tool-output/tool_e173f8244001N4xN8TzslIMFsD`

3. `rg -n '\bas!\b' Kizba || true`
   - Exit code: `0`
   - Result: no output (ban clean)

4. `rg -n 'Logger.*stdin|print\(.*stdin' Kizba || true`
   - Exit code: `0`
   - Result: no output (ban clean)

## Verdict

Phase A regression sweep is green: full test suite passed, Release build passed, grep bans are clean.

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
