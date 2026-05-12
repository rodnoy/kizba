# Kizba — Reconnaissance Context

## Summary

Read `.ai/handoff.md`, `.ai/plan.md`, `.ai/decisions.md`, `.ai/context.md` (prior version).

## C.7 Sidebar Mount — Status

**Implemented: YES.**

- `SidebarView` accepts `gitStatusModel: GitStatusModel?` parameter (line 30, default nil)
- Renders `GitStatusBadge(model:)` at bottom of folder list, guarded by `if let gitStatusModel` (line 70–74)
- `RootSplitView` passes `state.gitStatusModel` to `SidebarView` (line 37)
- Only one call site of `SidebarView` exists (`RootSplitView.swift:31`)
- No `project.pbxproj` changes needed for C.7 (no new files created — only edits to existing `SidebarView.swift` and `RootSplitView.swift`)

## Tests

No dedicated C.7 tests exist. Per plan, C.7 DoD is "manual smoke (git store) shows badge; (non-git store) hides badge." This is by design — the plan does not require automated tests for the mount step.

## Files Retrieved

1. `Kizba/Presentation/Features/Sidebar/SidebarView.swift` — mount point, 81 lines, has GitStatusBadge conditional render
2. `Kizba/Presentation/Root/RootSplitView.swift` — sole caller of SidebarView, passes gitStatusModel

## Next Action

C.7 is done. Handoff should be updated to mark C.7 COMPLETED and delegate C.8 (Git menu commands) to smart-worker.

## Verification Commands (post-C.7)

```sh
xcodebuild build -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS'
rg -n '\bas!\b' Kizba
rg -n 'Logger.*stdin|print\(.*stdin' Kizba
```
