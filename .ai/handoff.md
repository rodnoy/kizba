# Kizba — Handoff

## Current state

Phase A — COMPLETED.
Phase B — COMPLETED.
Phase C — IN PROGRESS.

## Next action

Delegate to smart-worker: implement C.2 GitStatusModel observe-changes hook.

Task: Extend `Kizba/Presentation/Features/Git/GitStatusModel.swift` with `observeChanges()` subscription to `PassManaging.changes`, add `stop()` cancellation seam and re-entrancy guard, and wire scenePhase `.active` reload in app-level composition. Add dedicated observe tests (new `KizbaTests/GitStatusModelObserveTests.swift`) using existing async helper patterns.

Verification commands after C.1:
```sh
xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' -only-testing:KizbaTests/GitStatusModelTests
xcodebuild build -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS'
rg -n '\bas!\b' Kizba
rg -n 'Logger.*stdin|print\(.*stdin' Kizba
```

Expected commit message: `feat(ui): add GitStatusModel observe-changes hook + scenePhase refresh`

## Phase C progress

- C.1 — COMPLETED (GitStatusModel scaffold + tests)
- C.2 — next (observe-changes hook)
- C.3 — pending (AppState extension)
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

- C.1 completed: added `GitStatusModel` scaffold (`@Observable @MainActor`) with generation-safe `loadStatus()`, computed badge/action-gating properties, `cancelCurrentLoad()`, and conflict-banner auto-dismiss helper.
- Added `KizbaTests/GitStatusModelTests.swift` (15 tests, 1 skipped) covering happy/failure/stale/cancel paths, computed states, and router conflict auto-dismiss behavior.
- Verification green: targeted tests passed, app build succeeded, grep bans clean.
