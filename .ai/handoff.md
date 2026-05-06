# Kizba — Handoff

## Current state

Repository is empty (only `.ai/*` planning files). No Xcode project yet.

Architecture proposal and full MVP 1 plan are approved and recorded in `.ai/plan.md`.
Durable technical decisions are recorded in `.ai/decisions.md`.

## Next step

**Phase 0 — Repo & project skeleton**, starting with step **0.1**: create `Kizba.xcodeproj`.

- Single Xcode project at repo root: `Kizba.xcodeproj`.
- App target name `Kizba`, test target `KizbaTests`.
- Swift 5.10, macOS deployment target 14.0.
- Build settings: `SWIFT_STRICT_CONCURRENCY = complete`, `SWIFT_TREAT_WARNINGS_AS_ERRORS = YES` (Kizba target).
- Zero third-party dependencies.
- Initial source files only: `Kizba/App/KizbaApp.swift` with an empty `WindowGroup { Text("Kizba") }`, `Kizba/Resources/Assets.xcassets/`, `KizbaTests/KizbaTests.swift` with one trivial `XCTAssertTrue(true)`.

## Verification commands

From repo root after step 0.1:

```sh
xcodebuild -scheme Kizba -destination 'platform=macOS' build
xcodebuild test -scheme Kizba -destination 'platform=macOS'
```

Both must succeed. Empty window must launch when running the app.

## Blockers / open items

- None. Implementation can begin once user gives explicit go-ahead.
- Xcode project creation is best done via Xcode UI (File → New → Project → macOS App, SwiftUI, Swift). Confirm whether the user prefers an Xcode-generated skeleton or a hand-rolled `.xcodeproj`.

## Constraints (must hold from day one)

- No third-party packages.
- No QtPass / GPL pass-client source consulted during implementation.
- No secrets in logs (no stdout logging in `Shell/`/`Pass/`).
- `PassSecret` not Codable, not CustomStringConvertible.
- All chat with user in Russian; all code/comments/docs/commits in English.
