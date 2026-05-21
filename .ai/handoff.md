Phase: Git refresh fetch-before-status (Task 2)
Status: COMPLETED

Completed work:
- Added `gitFetch(timeoutSeconds:)` to `PassGitManaging` and all conformers.
- Added live `git fetch` execution path in `PassCLI+Git` and `LivePassGitManager`.
- Updated Git refresh flow to call `fetchAndReloadStatus()` before local status load.
- Added unit tests covering fetch success and fetch-failure fallback behavior.
- Ran full test suite successfully and updated `.ai/build-log.md`.

Modified files:
- Kizba/Domain/Protocols/PassGitManaging.swift
- Kizba/Infrastructure/Pass/PassCLI+Git.swift
- Kizba/Infrastructure/Pass/PassGitErrorMapper.swift
- Kizba/Infrastructure/Pass/LivePassGitManager.swift
- Kizba/Presentation/Features/Git/GitStatusModel.swift
- Kizba/Presentation/Features/Git/GitStatusBadge.swift
- KizbaTests/Fixtures/FakePassGitManager.swift
- KizbaTests/GitStatusModelTests.swift
- .ai/build-log.md
- .ai/handoff.md

Timestamp: 2026-05-21T22:31:00+0200
