# Kizba — Handoff

## Current state

Phase A — in progress.

A.1 (GitStatus value type) verified locally. A.2 (PassError git cases + OnboardingHint extensions) implemented and unit-tested.

## Next action

Delegate to smart-worker: implement task A.3 (ErrorPresentation mappings for git cases). Replace any temporary fallback in ErrorPresentation.present(for:) with explicit mappings per `.ai/plan.md`.

## Phase A progress

- A.1 — verified
- A.2 — completed (PassError git cases + OnboardingHint added; unit tests passing)

Next: A.3 (ErrorPresentation mappings for the 6 git PassError cases).

## Verification commands (A.2)

Run these locally to verify A.2 surface:

```sh
# PassError git-cases unit tests
xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' -only-testing:KizbaTests/PassErrorGitCasesTests

# Core domain model tests
xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' -only-testing:KizbaTests/DomainModelsTests

# Build check
xcodebuild build -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS'

# Grep bans (must produce no output)
rg -n '\bas!\b' Kizba
rg -n 'Logger.*stdin|print\(.*stdin' Kizba
```

## Constraints (must hold throughout MVP 4)

- Zero third-party Swift Packages
- No secret content in logs
- `GitStatus` NOT Codable, NOT CustomStringConvertible, NOT CustomDebugStringConvertible
- All code/comments/docs/commits in English
- All MVP 1–3 grep bans continue
- `SWIFT_STRICT_CONCURRENCY = complete`, warnings-as-errors

## References

- `.ai/plan.md` — full MVP 4 plan with executable Phase A tasks
- `.ai/decisions.md` — durable architectural decisions
- `.ai/context.md` — reconnaissance findings
