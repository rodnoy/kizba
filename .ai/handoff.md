# Kizba — Handoff

## Current state

**Phase A — implementing.** Tasks A.1 and A.2 implemented (GitStatus value type and PassError git cases).

## Next action

Delegate to smart-worker: implement task A.3 (ErrorPresentation mappings for git cases) — replace temporary fallback in ErrorPresentation.present(for:) with explicit mappings per `.ai/plan.md`.
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
