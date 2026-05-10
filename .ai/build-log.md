Commands run:

- xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' -only-testing:KizbaTests/SourceGrepTests
- rg -n '\\bas!' Kizba
- rg -n 'Logger.*stdin|print\\(.*stdin' Kizba
- rg -n 'kizba:not-observable-model' || true

High-level result:

- SourceGrepTests only: PASSED (17 tests, 0 failures) — new test testPresentationModelsRequireObservable executed and passed.
- Repo grep hygiene checks: no matches for force-cast or stdin-logging bans; opt-out comment found in fixture.

Commit: 67f2ca45b074fb77bf8f30e32f569846b433413d
Date: 2026-05-10
