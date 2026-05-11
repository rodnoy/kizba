# Kizba — Handoff

## Current state

Phase A — COMPLETED.
Phase B.1 — COMPLETED (GitStatusParser + fixtures + tests).
Phase B.2 — COMPLETED (PassCLI+Git extension + env + tests).
Phase B.3 — COMPLETED (PassGitErrorMapper + fixtures + tests).

## Next action

Delegate to smart-worker: implement **B.4 LivePassGitManager** (per locked order in `.ai/plan.md`: B.1 → B.3 → B.2 → B.4 → B.5).

Task scope:
- Create `Kizba/Infrastructure/Pass/LivePassGitManager.swift`
- Create `KizbaTests/LivePassGitManagerTests.swift`
- Wire LivePassGitManager error/cancellation handling per plan
- Verify targeted tests + grep bans
- Commit with B.4 message from plan

## Phase B progress

- B.1 — completed
- B.2 — completed
- B.3 — completed
- B.4 — pending (next)
- B.5 — not started

## Phase A progress

- A.1–A.8 — all completed

## Verification commands

```sh
xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' -only-testing:KizbaTests/PassCLIGitTests
xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' -only-testing:KizbaTests/PassCLIGitEnvTests
xcodebuild build -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS'
rg -n '\bas!\b' Kizba
rg -n 'Logger.*stdin|print\(.*stdin' Kizba
```

## Last completed step summary

- Implemented `PassCLI+Git.swift` with `gitStatus`, `gitPull`, `gitPush` and `composedGitEnvironment()`.
- Added targeted tests: `PassCLIGitTests` (8) and `PassCLIGitEnvTests` (5), plus `BinaryName.git`.
- Verified both test targets, app build, and grep bans.
