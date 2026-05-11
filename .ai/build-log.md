Build verification for Phase A (A.1 / A.2)

Summary:
- All targeted unit tests and project build passed locally.
- Grep bans produced no output.

Commands executed and results:

1) xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' -only-testing:KizbaTests/GitStatusTests
   - Result: TEST SUCCEEDED (7 tests, 0 failures)
   - xcresult: /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-*/Logs/Test/Test-Kizba-2026.05.11_14-43-13-+0200.xcresult

2) xcodebuild build -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS'
   - Result: BUILD SUCCEEDED

3) rg -n '\bas!\b' Kizba
   - Result: no matches (clean)

4) rg -n 'Logger.*stdin|print\(.*stdin' Kizba
   - Result: no matches (clean)

Additional A.2 verification commands run:

5) xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' -only-testing:KizbaTests/PassErrorGitCasesTests
   - Result: TEST SUCCEEDED (7 tests, 0 failures)
   - xcresult: /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-*/Logs/Test/Test-Kizba-2026.05.11_14-46-41-+0200.xcresult

6) xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' -only-testing:KizbaTests/DomainModelsTests
   - Result: TEST SUCCEEDED (0 tests selected for this run; build OK)
   - xcresult: /Users/kirillsimagin/Library/Developer/Xcode/DerivedData/Kizba-*/Logs/Test/Test-Kizba-2026.05.11_14-47-28-+0200.xcresult

Notes:
- The PassError git cases and onboarding hints are present in Kizba/Domain/Models/PassError.swift and covered by unit tests KizbaTests/PassErrorGitCasesTests.swift.
- No code changes were required during this step beyond updating the handoff file (.ai/handoff.md).

Next step:
- Phase A.3: implement ErrorPresentation.present(for:) explicit mappings for the 6 new git PassError cases (replace any temporary fallback if present).
