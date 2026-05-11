# Kizba — Handoff

## Current state

Phase A — COMPLETED.
Phase B — COMPLETED.
Phase C — COMPLETED.
Phase D — IN PROGRESS.

D.1 — COMPLETED.

C.4 — COMPLETED.
C.5 — COMPLETED.
C.6 — COMPLETED.
C.8 — COMPLETED.

## Next action

Delegate to smart-worker: implement D.2 (AppRouter conflict banner state).

Note: C.9 regression sweep verification completed successfully — tests and Release build passed; grep bans clean.

See `.ai/plan.md` Phase C.8 section for full API signatures, test cases, and code shape.

Verification commands for C.8:
```sh
xcodebuild build -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS'
xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' -only-testing:KizbaTests/GitMenuCommandsTests
xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS'
rg -n '\bas!\b' Kizba
rg -n 'Logger.*stdin|print\(.*stdin' Kizba
```

Expected commit message: `feat(app): add Git menu commands (Refresh ⌘⇧R, Pull, Push, Open Terminal)`

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
- C.7 — COMPLETED (Sidebar mount — GitStatusBadge in SidebarView, RootSplitView passes gitStatusModel)
- C.8 — COMPLETED (Git menu commands)
- C.9 — next (regression sweep)

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
