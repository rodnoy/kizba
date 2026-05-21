Phase: Sidebar refresh on passManager changes (Task 1)
Status: COMPLETED

Completed work:
- Added SidebarModel change subscription to passManager.changes with cancellation support.
- Wired SidebarView to start SidebarModel.observeChanges() in a dedicated .task.
- Added SidebarModel unit test verifying nested-path insertion updates folderTree without restart.
- Ran full test suite successfully and updated .ai/build-log.md.

Modified files:
- Kizba/Presentation/Features/Sidebar/SidebarModel.swift
- Kizba/Presentation/Features/Sidebar/SidebarView.swift
- KizbaTests/SidebarModelTests.swift
- .ai/build-log.md
- .ai/handoff.md

Timestamp: 2026-05-21T22:23:00+0200
