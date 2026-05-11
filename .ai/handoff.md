# Kizba — Handoff

## Current state

Phase A — COMPLETED.
Phase B — COMPLETED.
Phase C — IN PROGRESS.

C.4 — COMPLETED.
C.5 — COMPLETED.
C.6 — COMPLETED.

## Next action

Delegate to smart-worker: implement C.7 Sidebar mount.

Task: Mount Git actions popover entrypoint in sidebar flow for C.7.

Verification commands for C.4:
```sh
xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' -only-testing:KizbaTests/AppEnvironmentGitWiringTests
xcodebuild build -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS'
rg -n '\bas!\b' Kizba
rg -n 'Logger.*stdin|print\(.*stdin' Kizba
```

Summary: Added `AppEnvironment` helpers to build and async-wire `LivePassGitManager` into `AppState.gitStatusModel` only when discovery succeeds and the store is a git repository. Added `AppEnvironmentGitWiringTests` (3 async tests) for no discovery, missing git, and repo success path. Wired startup via non-blocking `.task` in `KizbaApp`.

Expected commit message: `feat(app): wire LivePassGitManager startup integration`

Verification commands after C.2:
```sh
xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' -only-testing:KizbaTests/GitStatusModelObserveTests
xcodebuild build -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS'
rg -n '\bas!\b' Kizba
rg -n 'Logger.*stdin|print\(.*stdin' Kizba
```

Expected commit message: `feat(app): add optional gitStatusModel to AppState`

## Phase C progress

- C.1 — COMPLETED (GitStatusModel scaffold + tests)
- C.2 — COMPLETED (observe-changes hook)
- C.3 — COMPLETED (AppState extension)
- C.4 — COMPLETED (AppEnvironment wiring)
- C.5 — COMPLETED (GitStatusBadge view + sidebar mount)
- C.6 — COMPLETED (GitActionsPopover view)
- C.7 — next (Sidebar mount)
- C.8 — pending (Git menu commands)
- C.9 — pending (regression sweep)

## Phase B progress

- B.1–B.5 — all completed

## Phase A progress

- A.1–A.7 — all completed

## Verification commands

```sh
xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' -only-testing:KizbaTests/GitStatusModelTests
xcodebuild build -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS'
rg -n '\bas!\b' Kizba
rg -n 'Logger.*stdin|print\(.*stdin' Kizba
```

## Last completed step summary

- C.4 completed: `AppEnvironment` now provides `makeLivePassGitManager(...)` and `wireGitModelIfAvailable(into:usingShellRunner:)` helpers.
- `wireGitModelIfAvailable` performs best-effort probe and creates `GitStatusModel` only when `.git` + `.pass` are discoverable and `status.isGitRepository == true`; otherwise it is a no-op.
- `KizbaApp` now runs startup git wiring in a non-blocking `.task` after initial render.
- Added `KizbaTests/AppEnvironmentGitWiringTests.swift` with 3 async tests for nil discovery, missing git, and repo wiring success (`clean-with-upstream` fixture).
- Verification green: targeted tests passed, app build succeeded, grep bans clean.
