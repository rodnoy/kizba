# Phase 8.5 — Wire PassError cases to UI

## Goal

Map every `PassError` case to its designated UI affordance per the architecture table in `PassError.swift` doc comments. Replace the current generic `FailedView` stub with case-specific views, wire navigation to Settings and Diagnostics, and add toast/banner infrastructure.

## Constraints

- Do not edit `project.pbxproj`.
- Injected dependencies for testability; `@MainActor` on UI models.
- No third-party packages.
- `PassSecret` never leaves `EntryDetailModel`.
- Commit messages in English.
- Minimal scoped changes; prefer small new files + targeted edits.

## Tasks

### Task 1 — ErrorPresentation helper enum + PassError UI mapping
- **Priority:** 1 (foundation for all other tasks)
- **Complexity:** Small
- **Objective:** Create a pure helper that maps each `PassError` case to a presentation descriptor (title, message, style enum: `emptyState | banner | inline | toast | silent`, action enum: `openSettings | openDiagnostics | openHelp | none`).
- **Files to add:**
  - `Kizba/Presentation/DesignSystem/ErrorPresentation.swift` — `struct ErrorPresentation` with `static func from(_ error: PassError) -> ErrorPresentation`. Style/action enums nested inside.
- **Files to modify:** None.
- **Commit:** `feat(ui): add ErrorPresentation mapping for PassError cases`
- **Tests to add:**
  - `KizbaTests/ErrorPresentationTests.swift` — one test per `PassError` case verifying correct style + action (8 tests: `testBinaryNotFound`, `testPinentryNotConfigured`, `testDecryptionFailed`, `testStoreNotFound`, `testTimedOut`, `testShellFailure`, `testParsingFailed`, `testCancelled`).
- **Verification:** `xcodebuild test -scheme Kizba -destination 'platform=macOS' -only-testing:KizbaTests/ErrorPresentationTests`

### Task 2 — Replace FailedView with case-specific error rendering
- **Priority:** 2
- **Complexity:** Medium
- **Objective:** Rewrite the private `FailedView` in `EntryDetailView.swift` to use `ErrorPresentation` and render case-specific UI: empty-state with "Open Settings" button for `binaryNotFound`; banner with help link for `pinentryNotConfigured`; inline error with working "View details" button for `decryptionFailed`/`parsingFailed`; toast-style for `timedOut`/`shellFailure`; nothing for `cancelled`.
- **Files to modify:**
  - `Kizba/Presentation/Features/EntryDetail/EntryDetailView.swift` — replace `FailedView` body with switch on `ErrorPresentation.style`; add `openSettings`/`openDiagnostics` action callbacks.
  - `Kizba/Presentation/Features/EntryDetail/EntryDetailModel.swift` — add `var showDiagnostics: Bool` observable property toggled by "View details" action. Suppress `.cancelled` from reaching `.failed` state (set `.idle` instead).
- **Commit:** `feat(ui): render case-specific error views in EntryDetailView`
- **Tests to add:**
  - `KizbaTests/EntryDetailModelErrorTests.swift` — `testCancelledDoesNotSetFailed`, `testDecryptionFailedSetsFailedState`, `testShowDiagnosticsToggle`.
- **Verification:** `xcodebuild test -scheme Kizba -destination 'platform=macOS' -only-testing:KizbaTests/EntryDetailModelErrorTests`

### Task 3 — SidebarModel error state for storeNotFound / binaryNotFound
- **Priority:** 3
- **Complexity:** Small
- **Objective:** Surface `PassError.storeNotFound` and `binaryNotFound` at the sidebar level (list-load failure) so the user sees an empty state with guidance instead of a blank sidebar.
- **Files to modify:**
  - `Kizba/Presentation/Features/Sidebar/SidebarModel.swift` — add `private(set) var loadError: PassError?` observable property; set it in the `catch` block of `load()` (cast to `PassError`, else wrap as `.shellFailure`); clear on successful load.
  - `Kizba/Presentation/Features/Sidebar/SidebarView.swift` — when `model.loadError != nil`, show `ContentUnavailableView` with case-appropriate message and "Open Settings" button for `binaryNotFound` / `storeNotFound`.
- **Commit:** `feat(ui): surface load errors in SidebarView with guidance`
- **Tests to add:**
  - `KizbaTests/SidebarModelErrorTests.swift` — `testLoadErrorSetOnStoreNotFound`, `testLoadErrorSetOnBinaryNotFound`, `testLoadErrorClearedOnSuccess`.
- **Verification:** `xcodebuild test -scheme Kizba -destination 'platform=macOS' -only-testing:KizbaTests/SidebarModelErrorTests`

### Task 4 — Toast overlay infrastructure + wiring for timedOut/shellFailure
- **Priority:** 4
- **Complexity:** Medium
- **Objective:** Add a lightweight toast overlay to `RootSplitView` driven by `AppState` so transient errors (timedOut, shellFailure) show a dismissible banner at the top with a "Diagnostics" button.
- **Files to modify:**
  - `Kizba/App/AppState.swift` — add `var toastError: PassError?` observable property (auto-dismissed after 5s or on tap).
  - `Kizba/Presentation/DesignSystem/ToastView.swift` — **new file**. Small overlay view: icon + message + optional action button + auto-dismiss timer.
  - `Kizba/Presentation/Root/RootSplitView.swift` — add `.overlay` with `ToastView` bound to `state.toastError`.
  - `Kizba/Presentation/Features/EntryDetail/EntryDetailModel.swift` — for `timedOut`/`shellFailure`, set `appState.toastError` in addition to (or instead of) `.failed`.
- **Commit:** `feat(ui): add toast overlay for transient PassError cases`
- **Tests to add:**
  - `KizbaTests/ToastIntegrationTests.swift` — `testToastSetOnTimeout`, `testToastSetOnShellFailure`, `testToastNotSetOnDecryptionFailed`.
- **Verification:** `xcodebuild test -scheme Kizba -destination 'platform=macOS' -only-testing:KizbaTests/ToastIntegrationTests`

### Task 5 — Diagnostics navigation from error views
- **Priority:** 5
- **Complexity:** Small
- **Objective:** Wire the "View details" / "Diagnostics" buttons to actually open the Diagnostics view. Use `NSApp.sendAction` to open Settings window + switch to Diagnostics tab, or use `@Environment(\.openWindow)` if Diagnostics is a separate window scene.
- **Files to modify:**
  - `Kizba/App/KizbaApp.swift` — add Diagnostics as a tab in Settings scene (or a separate `Window` scene with id `"diagnostics"`).
  - `Kizba/Presentation/Features/EntryDetail/EntryDetailView.swift` — wire "View details" button to open diagnostics.
  - `Kizba/Presentation/DesignSystem/ToastView.swift` — wire "Diagnostics" action button.
- **Commit:** `feat(ui): wire Diagnostics navigation from error views`
- **Tests to add:** None (navigation is UI-only; manual verification).
- **Verification:** Manual: trigger `decryptionFailed` → click "View details" → Diagnostics opens. Trigger `timedOut` → toast "Diagnostics" button → Diagnostics opens. Build: `xcodebuild build -scheme Kizba -destination 'platform=macOS'`

### Task 6 — Settings nudge + help link actions
- **Priority:** 6
- **Complexity:** Small
- **Objective:** Wire "Open Settings" buttons (from `binaryNotFound` empty state and `storeNotFound` onboarding) to open the macOS Settings window. Wire `pinentryNotConfigured` help link to open the pinentry-mac install guide URL.
- **Files to modify:**
  - `Kizba/Presentation/Features/EntryDetail/EntryDetailView.swift` — "Open Settings" button calls `NSApp.sendAction(Selector("showSettingsWindow:"), to: nil, from: nil)` (or `showPreferencesWindow:` for macOS 14).
  - `Kizba/Presentation/Features/Sidebar/SidebarView.swift` — same for sidebar empty state.
- **Commit:** `feat(ui): wire Settings nudge and pinentry help link actions`
- **Tests to add:** None (system actions; manual verification).
- **Verification:** Manual: remove `pass` from PATH → launch → sidebar shows "Open Settings"; click opens Settings. Build: `xcodebuild build -scheme Kizba -destination 'platform=macOS'`

## Acceptance Criteria

1. Every `PassError` case has a defined, tested UI mapping (`ErrorPresentationTests` green).
2. `cancelled` never shows any UI — model stays `.idle`.
3. `binaryNotFound` / `storeNotFound` show empty state with "Open Settings" button in both sidebar and detail.
4. `pinentryNotConfigured` shows banner with clickable help link.
5. `decryptionFailed` / `parsingFailed` show inline error with working "View details" → Diagnostics.
6. `timedOut` / `shellFailure` show dismissible toast with "Diagnostics" button.
7. All new and existing tests pass: `xcodebuild test -scheme Kizba -destination 'platform=macOS'`.
8. No `project.pbxproj` edits.

## Suggested current step

**Start with Task 1** (ErrorPresentation helper + tests). It is pure logic with no UI dependencies, provides the foundation for all subsequent tasks, and can be committed and verified independently.
