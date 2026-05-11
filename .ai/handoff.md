# Kizba — Handoff

## Current state

Phase A — COMPLETED.
Phase B.1 — COMPLETED (GitStatusParser + fixtures + tests).
Phase B.3 — COMPLETED (PassGitErrorMapper + fixtures + tests).

## Next action

Delegate to smart-worker: implement **B.2 PassCLI+Git** (per locked order in `.ai/plan.md`: B.1 → B.3 → B.2 → B.4 → B.5).

Task scope:
- Create `Kizba/Infrastructure/Pass/PassCLI+Git.swift`
- Create `KizbaTests/PassCLIGitTests.swift`
- Create `KizbaTests/PassCLIGitEnvTests.swift`
- Add/verify `BinaryName.git`
- Verify git CLI tests + grep bans
- Commit with B.2 message from plan

## Phase B progress

- B.1 — completed
- B.2 — pending (next)
- B.3 — completed
- B.4 — not started
- B.5 — not started

## Phase A progress

- A.1–A.8 — all completed

## Verification commands

```sh
xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' -only-testing:KizbaTests/PassGitErrorMapperTests
xcodebuild build -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS'
rg -n '\bas!\b' Kizba
rg -n 'Logger.*stdin|print\(.*stdin' Kizba
```

## Last completed step summary

- Implemented `PassGitErrorMapper` as a pure synchronous mapper with ordered lowercase matching.
- Added conflict path extraction (`CONFLICT ... Merge conflict in <path>`) with 20-item cap.
- Added git stderr fixtures and `PassGitErrorMapperTests` (19 tests).
- Verified mapper tests, full app build, and grep bans.
