Commands run:

- rg -n "func startObservation|func waitUntil" || true
- xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' -only-testing:KizbaTests/AsyncTestHelpersTests
- rg -n '\bas!' Kizba
- rg -n 'Logger.*stdin|print\(.*stdin' Kizba
- rg -n 'func startObservation|func waitUntil' KizbaTests || true

Status:

- AsyncTestHelpersTests: PASS (2 tests)
- Repo grep bans: clean
- Single definitions of helpers: present in KizbaTests/Fixtures/AsyncTestHelpers.swift

Overall: A.1 completed successfully (tests green for new smoke tests).
