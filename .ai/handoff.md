# Kizba — Handoff

## Current state

**Phase A plan ready.** `.ai/plan.md` Phase A section replaced with 7 executable tasks (A.1–A.7). No MVP 4 code written yet. Repository at HEAD `382b8ce`. Test suite: 737 tests, 9 skipped, 0 failures. Release build green.

## Next action

**Delegate to smart-worker: implement task A.1 (GitStatus value type).**

Task A.1 scope:
- Create `Kizba/Domain/Models/GitStatus.swift` — `struct GitStatus: Sendable, Hashable, Equatable` with 8 stored properties and `static let notARepository`.
- Create `KizbaTests/GitStatusTests.swift` — ~7 test methods covering defaults, equality, hashing, non-conformance checks.
- Add both files to the Xcode project.

## Verification commands (A.1)

```sh
# Targeted test
xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' -only-testing:KizbaTests/GitStatusTests

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
