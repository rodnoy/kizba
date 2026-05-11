# Kizba — Reconnaissance Context

## Project Summary
- **Language:** Swift 5.10, SwiftUI, macOS 14.0+
- **Platform:** Native macOS desktop app (Xcode project, not SwiftPM-only)
- **Purpose:** GUI client for the Unix `pass(1)` password manager
- **Dependencies:** Zero third-party Swift packages (Foundation / SwiftUI / AppKit / os only)
- **Concurrency:** `SWIFT_STRICT_CONCURRENCY = complete`, warnings-as-errors
- **Current state:** MVP 3 shipped (737 tests, 0 failures). MVP 4 plan approved but no code written yet.

## Key Directories and Files

### Source (`Kizba/`)
- `App/` — `KizbaApp.swift`, `AppEnvironment.swift`, `AppState.swift`, `AppRouter.swift`
- `Domain/Models/` — `PassEntry`, `PassSecret`, `PassError`, `StoreChange`, `UndoableAction`, etc. (10 files)
- `Domain/Protocols/` — `PassManaging`, `ShellCommandRunning`, `ShellInvocation`, `BinaryLocating`, `SettingsStoring`, `StoreWatching`, etc. (10 files)
- `Infrastructure/Pass/` — `PassCLI`, `PassCLI+Write`, `PassErrorMapper`, `LivePassManager`, `PassShowParser`, `PassGenerateParser`, `PassSecretSerializer`
- `Infrastructure/Shell/` — `ProcessShellRunner`
- `Infrastructure/Settings/` — `UserDefaultsSettingsStore`
- `Presentation/Features/` — `Sidebar/`, `EntryList/`, `EntryDetail/`, `EntryForm/`, `EntryMove/`, `Settings/`, `Diagnostics/`
- `Presentation/DesignSystem/` — `Theme/`, `Components/`, `Modifiers/`

### Tests (`KizbaTests/`)
- 89 test files + `Fixtures/` + `SourceGrepFixtures/`
- 737 tests at MVP 3 baseline

### Build
- `Kizba.xcodeproj` — single scheme `Kizba`, single app target, single test target `KizbaTests`

### AI State (`.ai/`)
- `handoff.md` — current execution state (MVP 4 Phase A next)
- `plan.md` — full 5-phase MVP 4 plan (336 lines, locked)
- `decisions.md` — 27+ durable architectural decisions across MVPs 1–3
- `step.md` — step counter (currently 2)
- `xcode_instructions.md`, `sequoia-smoke.md`, `a11y-audit.md`, `code-review-checklist.md`

## Build & Test Commands

```sh
# Default test suite (no external deps)
xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS'

# Release build
xcodebuild -scheme Kizba -project Kizba.xcodeproj -configuration Release -destination 'platform=macOS' build

# Opt-in E2E (requires pass + gpg)
TEST_RUNNER_KIZBA_E2E=1 xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' -only-testing:KizbaTests/PassWriteIntegrationTests

# Opt-in FSEvents
TEST_RUNNER_KIZBA_FSEVENTS_TEST=1 xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' -only-testing:KizbaTests/FSEventsStoreWatcherTests

# Grep bans (must be clean)
rg -n '\bas!\b' Kizba
rg -n 'Logger.*stdin|print\(.*stdin' Kizba
```

## Technical Constraints
- Zero third-party Swift packages
- No QtPass / GPL pass-client source consulted
- No secret content in logs (stdin/stdout/clipboard/metadata/notes)
- Security non-conformances enforced by `SourceGrepTests`: `PassSecret`, `MetadataPair`, `SecretDraft`, `UndoableAction` (and new `GitStatus`) must NOT be `Codable`/`CustomStringConvertible`/`CustomDebugStringConvertible`
- Inline styling banned in `Presentation/**` outside `DesignSystem/`
- `as!` banned repo-wide
- `@Observable` required on all `Presentation/**/*Model.swift` classes
- Model constructors banned inside `.sheet/.popover/.fullScreenCover` bodies

## MVP 4 Scope (Git Integration)
The plan is fully written in `.ai/plan.md`. Five phases:
1. **Phase A** (~1 day) — Domain types: `GitStatus`, 6 new `PassError` cases, `PassGitManaging` protocol, `FakePassGitManager`, SourceGrepTests extension
2. **Phase B** (~3 days) — CLI: `GitStatusParser`, `PassCLI+Git`, `PassGitErrorMapper`, `LivePassGitManager` actor
3. **Phase C** (~3 days) — UI: `GitStatusModel`, sidebar badge, popover, Git menu (⌘⇧R)
4. **Phase D** (~3 days) — Actions: Pull/Push with lockout, conflict banner, cancel, "Open Terminal"
5. **Phase E** (~2 days) — Polish: settings stepper, a11y, opt-in E2E, docs

## Files to Create/Modify in Phase A (Next Step)
- **New:** `Kizba/Domain/Models/GitStatus.swift`
- **Modify:** `Kizba/Domain/Models/PassError.swift` (6 git cases)
- **Modify:** `Kizba/Domain/Models/OnboardingHint.swift` (2 new hints — file may need to be located/created)
- **Modify:** `Kizba/Domain/ErrorPresentation.swift` (6 new mappings)
- **New:** `Kizba/Domain/Protocols/PassGitManaging.swift`
- **New:** `KizbaTests/Fixtures/FakePassGitManager.swift`
- **Modify:** `KizbaTests/SourceGrepTests.swift` (git non-conformance rule)
- **New tests:** `GitStatusTests.swift`, `PassErrorGitCasesTests.swift`, `FakePassGitManagerTests.swift`, etc.

## Risks / Unknowns
1. `OnboardingHint` location needs verification — may be in `Domain/Models/` or `Domain/` or `Presentation/`
2. `ErrorPresentation` location needs verification — listed as `Kizba/Domain/ErrorPresentation.swift` in plan
3. Phase A is low-risk (pure types, no IO); main risk is in Phase B (parser fixtures from real git versions) and Phase D (lockout/cancellation symmetry)
4. `writeFailed(reason:)` PassError case exists but is never mapped by `PassErrorMapper` — unclear if intentional
