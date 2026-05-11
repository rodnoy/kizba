Phase A.1 verification (GitStatus) and Phase A.2 implementation

Commands run:

- xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' -only-testing:KizbaTests/GitStatusTests
- xcodebuild build -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS'
- rg -n '\bas!\b' Kizba
- rg -n 'Logger.*stdin|print\(.*stdin' Kizba

Result: A.1 verification passed (GitStatusTests green, build succeeded, grep bans clean).

Phase A.2 changes applied: added 6 git-related PassError cases, OnboardingHint extensions, updated computed properties and temporary ErrorPresentation fallback. New tests added: KizbaTests/PassErrorGitCasesTests.swift.

Next: run A.2 focused tests and full DomainModels tests per plan.
