# Kizba — Handoff

## Current state

Phase A — COMPLETED.
Phase B — COMPLETED.
Phase C — IN PROGRESS.

## Next action

Delegate to smart-worker: implement C.3 AppState extension to hold `gitStatusModel`.

Task: Extend `Kizba/App/AppState.swift` with optional `gitStatusModel: GitStatusModel? = nil` and initializer plumbing (default nil), then add/adjust `KizbaTests/AppStateTests.swift` coverage for the default value. Keep changes additive and minimal.

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
- C.3 — next (AppState extension)
- C.4 — pending (AppEnvironment wiring)
- C.5 — pending (GitStatusBadge view)
- C.6 — pending (GitActionsPopover view)
- C.7 — pending (Sidebar mount)
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

- C.2 completed: `GitStatusModel` now stores `passManager`, subscribes to `passManager.changes` via `observeChanges()`, reloads via `await loadStatus()` per event, and exposes idempotent `stop()` cancellation seam.
- Added `KizbaTests/GitStatusModelObserveTests.swift` (4 async tests) covering event-triggered reload, stop cancellation, no-double-subscribe behavior, and cancellation during a slow load.
- Updated `GitStatusModelTests` constructor helper and Async test helper protocol conformance to include the new `passManager` dependency.
- Verification green: targeted observe tests passed, app build succeeded, grep bans clean.
