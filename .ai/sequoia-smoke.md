# macOS Sequoia (15.x) Smoke Test Notes

This document captures macOS Sequoia (15.x) compatibility notes and a manual smoke test checklist for Kizba. macOS 15 introduced changes around `Process` spawn permissions (TCC) and clipboard access that warrant verification.

## Smoke test matrix

Include the following rows in the verification table. Columns: Verified (Y/N), Notes, Tester, Date.

| Item | Verified (Y/N) | Notes | Tester | Date |
|---|---:|---|---|---|
| cold-launch | — | — | — | — |
| read flow | — | — | — | — |
| write flow | — | — | — | — |
| concurrent-write lockout | — | — | — | — |
| Diagnostics | — | — | — | — |
| FSEvents auto-refresh | — | Placeholder: verify auto-refresh without ⌘R | — | — |
| Touch ID prompt | — | Placeholder: verify Touch ID appears on reveal when enabled | — | — |
| Git status (clean) | — | Sidebar badge shows branch + clean dot for git-backed store | — | — |
| Git pull happy | — | Git > Pull succeeds; badge updates; success/info toast appears | — | — |
| Git push happy | — | Git > Push succeeds or shows "Already up to date" info toast | — | — |
| Git conflict banner | — | Pull conflict shows banner with "Open Terminal at Store" action | — | — |

Fill in the verification table as you run the checklist.

## How to run

```sh
# Build a signed local Release
xcodebuild -scheme Kizba -project Kizba.xcodeproj -configuration Release -destination 'platform=macOS' build

# For day-to-day smoke testing, a local Debug build is sufficient:
xcodebuild -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' build
open ~/Library/Developer/Xcode/DerivedData/Kizba-*/Build/Products/Debug/Kizba.app
```

## Notes

- FSEvents auto-refresh: external writes should appear within ~2s. Document observed debounce if longer.
- Touch ID prompt: depends on hardware; on non-Touch ID Macs, system password fallback may appear.
