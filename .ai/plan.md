# Kizba — MVP 4 Implementation Plan

Native macOS SwiftUI client for `pass(1)`. MVP 1 (read-only), MVP 2 (writes + design system + Undo + Toast + Diagnostics) and MVP 3 (defense-in-depth + AppRouter + EntryFormBody + FSEvents + a11y + Touch ID) are shipped at HEAD `382b8ce`. MVP 4 adds `pass git` integration ONLY: status surface, Pull/Push, conflict UX, settings stepper, opt-in E2E.

This document is the authoritative MVP 4 plan. It is organized into phases (A–E). Each phase contains discrete tasks, verification steps, DoD (Definition of Done), and sequencing constraints.

## 1. MVP 4 scope

MVP 4 is a single-feature release: surface git status on the sidebar, expose Pull/Push via the menu bar + popover, route conflicts through a modal banner, and lock pull/push behind the existing write-op set. All other comfort features (Favorites, Recently used, OTP, menu-bar mode, global quick search, better metadata editing, browser auto-fill, keyboard-shortcut audit) remain deferred to MVP 5+.

**IN scope**
- `PassGitManaging` protocol + `LivePassGitManager` actor (CLI integration + parser + error mapper).
- `GitStatusModel` (@Observable @MainActor) + sidebar badge + popover + Git menu (⌘⇧R only).
- Pull / Push with lockout via `ActiveWriteOp.gitPull` / `.gitPush`; cancellation via `Task.cancel()`.
- Conflict banner sheet routed via `AppRouter`; "Open Terminal at store" via `NSWorkspace`.
- `gitOperationTimeoutSeconds` Settings stepper (range 10…300, default 60).
- Refresh on `StoreChange` events + scenePhase `.active` + manual button. NO polling.
- Opt-in E2E suite gated by `KIZBA_GIT_E2E=1`.

**OUT of scope (MVP 5+)**
- Auto-fetch / scheduled background fetch.
- `$TERMINAL` env support (Terminal.app only).
- Keyboard shortcuts for Pull/Push.
- Conflict auto-resolution / in-app merge tooling.
- "enableGitFeatures" toggle (auto-detected via `isGitRepository`).
- Per-path diff / commit log UI.
- All MVP 3-deferred items still deferred (App Sandbox, ScrubbingString, snapshot tests, localization, browser auto-fill, third-party packages).

## 2. Baseline & constraints

- Swift 5.10, Xcode 15.4+, macOS 14.0.
- `SWIFT_STRICT_CONCURRENCY = complete`; warnings-as-errors for app target.
- Zero third-party Swift Packages.
- All code/comments/docs/commits in English. User chat in Russian.
- All MVP 1–3 grep bans continue (`as!`, `Logger.*stdin|print\(.*stdin`, inline styling outside DesignSystem, @Observable on Presentation models, no model constructors in sheet bodies).
- New: SourceGrepTests rule extended for git domain types (no Codable / CustomStringConvertible / CustomDebugStringConvertible).

## 3. Phases overview

Order locked: A → B → C → D → E. Steps inside a phase are mostly sequential; reorderable bits called out under "Sequencing risks".

---

## Phase A — Domain types + protocol (~1 day, low risk)

### A.1 — GitStatus value type

- **Objective:** Create the `GitStatus` struct that represents the git state of the password store.
- **Files to create:**
  - `Kizba/Domain/Models/GitStatus.swift`
- **Implementation notes:**
  - `public struct GitStatus: Sendable, Hashable, Equatable`
  - Stored properties: `isGitRepository: Bool`, `branch: String?`, `hasLocalChanges: Bool`, `hasConflicts: Bool`, `aheadCount: Int`, `behindCount: Int`, `hasRemote: Bool`, `lastFetchAt: Date?`
  - Memberwise `init` with defaults: `isGitRepository = false`, `branch = nil`, `hasLocalChanges = false`, `hasConflicts = false`, `aheadCount = 0`, `behindCount = 0`, `hasRemote = false`, `lastFetchAt = nil`
  - `public static let notARepository = GitStatus()` (all defaults → `isGitRepository = false`)
  - `import Foundation` (needed for `Date`)
  - **MUST NOT** conform to `Codable`, `CustomStringConvertible`, `CustomDebugStringConvertible`
- **Tests to add:**
  - `KizbaTests/GitStatusTests.swift` (new file, ~6 methods):
    - `testNotARepository_hasExpectedDefaults` — all fields match defaults
    - `testEquality_identicalInstances` — two identical instances are equal
    - `testEquality_differentBranch` — different branch → not equal
    - `testHashing_identicalInstancesShareHash` — same hash for equal instances
    - `testCustomInit_allFieldsSet` — init with all non-default values, verify each
    - `testIsNotCodable` — `XCTAssertFalse((GitStatus.self as Any) is any Codable.Type)` (runtime check, mirrors existing pattern in `DomainModelsTests`)
    - `testIsNotCustomStringConvertible` — `XCTAssertFalse((GitStatus.self as Any) is CustomStringConvertible.Type)` + same for `CustomDebugStringConvertible.Type`
- **Verification:**
  ```sh
  xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' -only-testing:KizbaTests/GitStatusTests
  ```
- **Commit message:** `feat(domain): add GitStatus value type`
- **Estimated time:** 0.5h | **Difficulty:** low

---

### A.2 — PassError extension (6 git cases)

- **Objective:** Add 6 git-related error cases to `PassError` and extend the 3 computed properties.
- **Files to modify:**
  - `Kizba/Domain/Models/PassError.swift`
- **Implementation notes:**
  - Add a new `// MARK: - Git-side (MVP 4)` section after the write-side cases
  - 6 new cases:
    - `case gitNotInitialized`
    - `case gitNoRemote`
    - `case gitAuthFailed`
    - `case gitConflict(paths: [String]?)`
    - `case gitNetworkUnavailable`
    - `case gitRejected(reason: String)`
  - Extend `inlineRecoverable` switch: all 6 → `return false`
  - Extend `onboardingHint` switch: `gitNotInitialized` → `.configureGitRemote`, `gitNoRemote` → `.configureGitRemote`, other 4 → `nil`
  - Extend `autoRefreshes` switch: all 6 → `return false`
  - Add 2 new `OnboardingHint` cases (in the same file since `OnboardingHint` lives there): `.configureGitRemote`, `.openTerminalAtStore`
- **Tests to add:**
  - `KizbaTests/PassErrorGitCasesTests.swift` (new file, ~12 methods):
    - 6 equality tests (one per case, including associated values for `gitConflict` and `gitRejected`)
    - `testInlineRecoverable_gitCases_allFalse`
    - `testOnboardingHint_gitNotInitialized_configureGitRemote`
    - `testOnboardingHint_gitNoRemote_configureGitRemote`
    - `testOnboardingHint_gitAuthFailed_nil` (+ gitConflict, gitNetworkUnavailable, gitRejected → nil)
    - `testAutoRefreshes_gitCases_allFalse`
    - `testHashing_gitConflictWithPaths`
- **Verification:**
  ```sh
  xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' -only-testing:KizbaTests/PassErrorGitCasesTests
  xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' -only-testing:KizbaTests/DomainModelsTests
  xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' -only-testing:KizbaTests/PassErrorMapperTests
  ```
- **Risks:** Every existing `switch` on `PassError` must gain the 6 new cases or the build breaks. Known exhaustive switches: `inlineRecoverable`, `onboardingHint`, `autoRefreshes` (in PassError.swift), `present(for:)` (in ErrorPresentation.swift). ErrorPresentation is handled in A.4 — **A.2 will NOT compile in isolation if ErrorPresentation.swift has an exhaustive switch**. Mitigation: add a temporary `default` in ErrorPresentation or implement A.2 and A.4 together. Recommended: implement A.2 first with a `default: return .silent` fallback added to `ErrorPresentation.present(for:)`, then A.4 replaces it with explicit cases.
- **Commit message:** `feat(domain): add 6 git PassError cases + OnboardingHint extensions`
- **Estimated time:** 1h | **Difficulty:** medium

---

### A.3 — ErrorPresentation mappings for git cases

- **Objective:** Map the 6 new git `PassError` cases to existing `ErrorPresentation` cases.
- **Files to modify:**
  - `Kizba/Domain/ErrorPresentation.swift`
- **Implementation notes:**
  - Replace the temporary `default` (if added in A.2) or add 6 new cases to the `switch` in `present(for:)`:
    - `gitNotInitialized` → `.onboarding(message: "Git is not initialised in the password store. Run `pass git init` to enable git tracking.")`
    - `gitNoRemote` → `.onboarding(message: "No git remote configured. Add a remote to enable push and pull.")`
    - `gitAuthFailed` → `.toastWithDiagnostics(message: "Git authentication failed. Check your SSH keys or credentials.")`
    - `gitConflict` → `.silent` (conflict banner handles this via AppRouter)
    - `gitNetworkUnavailable` → `.toastWithDiagnostics(message: "Network unavailable. Check your connection and try again.")`
    - `gitRejected(let reason)` → `.toastWithDiagnostics(message: "Push rejected: \(reason)")`
  - No new `ErrorPresentation` cases — reuse existing ones only
- **Tests to modify:**
  - `KizbaTests/ErrorPresentationIntegrationTests.swift` — add 6 new test methods:
    - `testGitNotInitialized_mapsToOnboarding`
    - `testGitNoRemote_mapsToOnboarding`
    - `testGitAuthFailed_mapsToToastWithDiagnostics`
    - `testGitConflict_mapsToSilent`
    - `testGitNetworkUnavailable_mapsToToastWithDiagnostics`
    - `testGitRejected_mapsToToastWithDiagnostics`
- **Verification:**
  ```sh
  xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' -only-testing:KizbaTests/ErrorPresentationIntegrationTests
  xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' -only-testing:KizbaTests/ErrorPresentationTests
  ```
- **Commit message:** `feat(domain): map 6 git PassError cases in ErrorPresentation`
- **Estimated time:** 0.5h | **Difficulty:** low

---

### A.4 — PassGitManaging protocol + GitPushOutcome

- **Objective:** Define the protocol for git operations and the push outcome enum.
- **Files to create:**
  - `Kizba/Domain/Protocols/PassGitManaging.swift`
- **Implementation notes:**
  - `import Foundation` (for `Int` — actually no Foundation needed, but keep consistent with other protocols)
  - `public enum GitPushOutcome: Sendable, Equatable { case pushed; case alreadyUpToDate }`
  - `public protocol PassGitManaging: Sendable {`
    - `func gitStatus() async throws -> GitStatus`
    - `func gitPull(timeoutSeconds: Int) async throws`
    - `func gitPush(timeoutSeconds: Int) async throws -> GitPushOutcome`
  - `}`
  - Protocol must NOT inherit from `PassManaging` — independent protocol
  - No `import Foundation` unless needed (check if `Int` needs it — it doesn't, but `GitStatus` uses `Date` so the import may be transitive)
- **Tests:** No dedicated test file — protocol has no logic. Compilation is the verification.
- **Verification:**
  ```sh
  xcodebuild build -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS'
  ```
- **Commit message:** `feat(domain): add PassGitManaging protocol + GitPushOutcome`
- **Estimated time:** 0.25h | **Difficulty:** low

---

### A.5 — FakePassGitManager test fixture

- **Objective:** Create a configurable test double for `PassGitManaging`.
- **Files to create:**
  - `KizbaTests/Fixtures/FakePassGitManager.swift`
- **Implementation notes:**
  - `final class FakePassGitManager: PassGitManaging, @unchecked Sendable {` — NO, decisions.md says no new `@unchecked Sendable`. Use an actor instead: `actor FakePassGitManager: PassGitManaging {`
  - Wait — check decisions: "NO new `@unchecked Sendable` (no FSEvents-equivalent shared state)". But existing `FakeShellRunner` and `MockPassManager` patterns may use `@unchecked Sendable`. The fake needs mutable state for scripted results + call counters. An `actor` naturally satisfies `Sendable` and `PassGitManaging: Sendable`.
  - Properties:
    - `var nextStatus: Result<GitStatus, Error> = .success(.notARepository)`
    - `var pullResults: [Result<Void, Error>] = []` (consumed FIFO; empty → no-op success)
    - `var pushResults: [Result<GitPushOutcome, Error>] = []` (consumed FIFO; empty → `.success(.pushed)`)
    - `private(set) var statusCallCount = 0`
    - `private(set) var pullCallCount = 0`
    - `private(set) var pushCallCount = 0`
    - `var artificialDelay: Duration? = nil` (for cancellation tests)
  - `gitStatus()`: bump counter, sleep if delay, return/throw from `nextStatus`
  - `gitPull(timeoutSeconds:)`: bump counter, sleep if delay, consume first from `pullResults` or succeed
  - `gitPush(timeoutSeconds:)`: bump counter, sleep if delay, consume first from `pushResults` or return `.pushed`
- **Tests to add:**
  - `KizbaTests/FakePassGitManagerTests.swift` (new file, ~5 methods):
    - `testStatusCallCount_incrementsOnEachCall`
    - `testStatusReturnsConfiguredResult`
    - `testPullConsumesScriptedResults`
    - `testPushConsumesScriptedResults`
    - `testDefaultPushReturns_pushed`
- **Verification:**
  ```sh
  xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' -only-testing:KizbaTests/FakePassGitManagerTests
  ```
- **Commit message:** `test(fixtures): add FakePassGitManager test double`
- **Estimated time:** 0.75h | **Difficulty:** low

---

### A.6 — SourceGrepTests git non-conformance rule

- **Objective:** Extend `SourceGrepTests` to enforce that `GitStatus` never gains `Codable`/`CustomStringConvertible`/`CustomDebugStringConvertible`.
- **Files to modify:**
  - `KizbaTests/SourceGrepTests.swift`
- **Implementation notes:**
  - Add a new test method `testGitDomainTypesNonConformances()` following the pattern of `testPassSecretIsNotCodable()` (line ~119)
  - Scan `Kizba/Domain/Models/GitStatus.swift` for regex: `(?:struct|extension)\s+GitStatus\b[^:{]*:\s*([^{]*?\b(?:Codable|Encodable|Decodable|CustomStringConvertible|CustomDebugStringConvertible)\b[^{]*)`
  - Fail with descriptive message if any match found
  - Also add runtime checks: `XCTAssertFalse((GitStatus.self as Any) is any Codable.Type)`, same for `CustomStringConvertible.Type` and `CustomDebugStringConvertible.Type`
  - This task lands BEFORE Phase B so any future git types are covered from the start
- **Tests:** The test method itself IS the test. Verify it passes (GitStatus has no banned conformances) and would fail if one were added (verified by manual inspection or a smoke fixture — optional).
- **Verification:**
  ```sh
  xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' -only-testing:KizbaTests/SourceGrepTests/testGitDomainTypesNonConformances
  ```
- **Commit message:** `test(grep): add GitStatus non-conformance rule to SourceGrepTests`
- **Estimated time:** 0.5h | **Difficulty:** low

---

### A.7 — Phase A full regression sweep

- **Objective:** Verify all existing + new tests pass, grep bans clean, Release build green.
- **Files to modify:** None (verification only).
- **Verification commands (all must pass):**
  ```sh
  # Full test suite
  xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS'

  # Release build
  xcodebuild -scheme Kizba -project Kizba.xcodeproj -configuration Release -destination 'platform=macOS' build

  # Grep bans
  rg -n '\bas!\b' Kizba
  rg -n 'Logger.*stdin|print\(.*stdin' Kizba
  ```
- **DoD checklist:**
  - [ ] Full suite green: ≥ 737 + ~18 new tests, 0 failures
  - [ ] Release build green
  - [ ] `rg -n '\bas!\b' Kizba` — no output
  - [ ] `rg -n 'Logger.*stdin|print\(.*stdin' Kizba` — no output
  - [ ] New files added to Xcode project (GitStatus.swift, PassGitManaging.swift in app target; GitStatusTests.swift, PassErrorGitCasesTests.swift, FakePassGitManager.swift, FakePassGitManagerTests.swift in test target)
  - [ ] `OnboardingHint` has 4 cases: `checkRecipients`, `initializeStore`, `configureGitRemote`, `openTerminalAtStore`
  - [ ] `PassError` has 20 cases (14 existing + 6 git)
  - [ ] `ErrorPresentation.present(for:)` handles all 20 cases explicitly (no `default`)
  - [ ] `PassGitManaging` protocol exists and does NOT inherit from `PassManaging`
  - [ ] `FakePassGitManager` conforms to `PassGitManaging` and is `Sendable`
  - [ ] `SourceGrepTests.testGitDomainTypesNonConformances` passes
- **Commit message:** `chore: Phase A regression sweep — all green`
- **Estimated time:** 0.25h | **Difficulty:** low

---

**Phase A DoD:** Domain types + protocol + fake fixture + extended grep rule landed; suite green; no infrastructure or UI yet.

**Execution order:** A.1 → A.2 → A.3 → A.4 → A.5 → A.6 → A.7

**Notes:**
- A.1 is independent and must land first (A.2 references `OnboardingHint` which lives in the same file as `PassError`)
- A.2 adds cases to `PassError` which breaks `ErrorPresentation.present(for:)` — add a temporary `default: return .silent` to unblock compilation, then A.3 replaces it
- A.4 is independent of A.2/A.3 but must land before A.5
- A.6 depends on A.1 (needs `GitStatus.swift` to exist)

---

## Phase B — CLI integration + parser (~3 days, medium risk)

### B.1 GitStatusParser
- New `Kizba/Infrastructure/Pass/GitStatusParser.swift`: pure `enum` (static methods), `static func parse(_ stdout: String) -> GitStatus`. Handles `# branch.head <name>` / `# branch.upstream <name>` / `# branch.ab +N -M` headers and `1 …`, `2 …`, `u …`, `? …` change lines. Unknown header / change lines silently ignored (forward-compat).
- `lastFetchAt` is NOT set here (parser is shell-output only).
- DoD: `GitStatusParserTests.swift` ≥ 18 methods covering: empty input → not-a-repository; clean repo with upstream; clean repo no remote; ahead-only; behind-only; ahead+behind; modified; staged; renamed; untracked; conflict (`u`); detached HEAD; multi-section combinations; unknown line tolerance. Fixtures captured from real `git -C` runs against git 2.34 / 2.39 / 2.45 placed under `KizbaTests/Fixtures/GitStatusFixtures/`.

### B.2 PassCLI+Git
- New `Kizba/Infrastructure/Pass/PassCLI+Git.swift` (extension on existing `PassCLI`).
- `gitStatus(storePath:)` — invokes `git -C <storePath> status --porcelain=v2 --branch` directly via `BinaryLocating` lookup of `git` (not `pass`); 5s timeout; reads `.git/FETCH_HEAD` mtime via `FileManager` for `lastFetchAt`; merges parser output + mtime.
- `gitPull(storePath:timeoutSeconds:)` — invokes `pass git pull` (preserves pass-installed git hooks); composed env (see B.4); explicit `Duration.seconds(timeoutSeconds)` timeout.
- `gitPush(storePath:timeoutSeconds:)` — invokes `pass git push`; same env; on success, parses combined stdout/stderr for "Everything up-to-date" → returns `.alreadyUpToDate`, else `.pushed`.
- DoD: file compiles; `PassCLI+GitTests` (using `FakeShellRunner`) covers each method's `ShellInvocation` shape (executable, arguments, env keys, stdin = `.none`, timeout).

### B.3 PassGitErrorMapper
- New `Kizba/Infrastructure/Pass/PassGitErrorMapper.swift` (separate file; do NOT extend `PassErrorMapper` — already 483 LOC and the surfaces differ).
- `static func map(stderr: String, exitCode: Int32, operation: GitOperation) -> (error: PassError, excerpt: String)` where `enum GitOperation { case status, pull, push }`.
- Mapping signatures (ordered, lowercased): `"not a git repository"` → `.gitNotInitialized`; `"no configured push destination"` / `"does not appear to be a git repository"` (in pull/push context) → `.gitNoRemote`; `"authentication failed" | "permission denied" | "could not read username"` → `.gitAuthFailed`; `"conflict" | "merge conflict" | "automatic merge failed"` → `.gitConflict(paths:)` with path extraction (lines like `CONFLICT (content): Merge conflict in <path>`); `"could not resolve host" | "network is unreachable" | "operation timed out"` → `.gitNetworkUnavailable`; `"updates were rejected" | "non-fast-forward" | "fetch first"` → `.gitRejected(reason:)`.
- Reuse `PassErrorMapper.sanitize(_:)` for the excerpt (delegated, not duplicated).
- DoD: `PassGitErrorMapperTests.swift` ≥ 18 methods covering each signature for each operation, plus path extraction (single + multi conflict), plus sanitisation idempotency, plus fallback-to-`writeFailed(reason:)` when nothing matches. Fixtures captured under `KizbaTests/Fixtures/GitStderrFixtures/` from `pass` 1.7.3 + 1.7.4.

### B.4 Environment composition for git
- In `PassCLI+Git.swift`, document and centralise the env composition: `GIT_TERMINAL_PROMPT=0` (fast-fail credential prompts), `SSH_ASKPASS=/usr/bin/false` (block GUI askpass), pass-through `SSH_AUTH_SOCK` if present in process env (allow ssh-agent SSH remotes). Use existing `composedEnvironment()` style from `PassCLI`.
- DoD: a focused test (`PassCLI+GitEnvTests`) verifies the env dictionary built by each git method contains exactly the expected keys + propagated `SSH_AUTH_SOCK` when set.

### B.5 LivePassGitManager actor
- New `Kizba/Infrastructure/Pass/LivePassGitManager.swift`: `actor LivePassGitManager: PassGitManaging`. Injected: `passCLI: PassCLI`, `binaryLocating: any BinaryLocating`, `storeLocationProvider: @Sendable () async -> URL`, `parser: GitStatusParser.Type` (defaulted), `errorMapper: PassGitErrorMapper.Type` (defaulted).
- `gitStatus()` resolves store path → calls `passCLI.gitStatus(...)` → on stderr mapping uses `PassGitErrorMapper`. Returns `GitStatus.notARepository` if stderr is `not a git repository` (rather than throwing — status is read-only and "not a repo" is a normal state).
- `gitPull(timeoutSeconds:)` / `gitPush(timeoutSeconds:)` — translate any `try await` cancellation into rethrown `CancellationError`; catch `PassError` and rethrow; map non-`PassError` shell errors via `PassGitErrorMapper`.
- DoD: `LivePassGitManagerTests.swift` (using `FakeShellRunner` + a stub `BinaryLocating`) ≥ 14 methods covering: status happy path, status not-a-repo → `.notARepository`, status arbitrary error → throws mapped `PassError`, pull happy, pull conflict → `.gitConflict([paths])`, pull network → `.gitNetworkUnavailable`, push happy → `.pushed`, push up-to-date → `.alreadyUpToDate`, push rejected → `.gitRejected(reason)`, push auth → `.gitAuthFailed`, cancellation propagation.

### B.6 Phase B regression
- Run full suite + grep bans + Release build.
- DoD: full suite green (≥ A baseline + ~50 new tests); grep bans clean; Release build green.

**Phase B DoD:** Parser, CLI extensions, error mapper, and `LivePassGitManager` actor land with full unit coverage; no UI yet; opt-in E2E still off.

---

## Phase C — GitStatusModel + sidebar badge + Git menu (~3 days, medium risk)

### C.1 GitStatusModel scaffold
- New `Kizba/Presentation/Features/Git/GitStatusModel.swift`: `@Observable @MainActor final class GitStatusModel`. Stored: `status: GitStatus`, `loadState: LoadState`, `operationState: OperationState`, `lastError: PassError?`. Enums (mirror MVP 2 `EntryFormModel` patterns): `LoadState { idle, loading, loaded, failed }`, `OperationState { idle, pulling, pushing }`. Generation-counter `private var generation: UInt64`. Injected: `gitManager: any PassGitManaging`, `appState: AppState`, `router: AppRouter`, `toastCenter: ToastCenter`, `settingsStore: any SettingsStoring` (for timeout).
- `loadStatus()` async: bumps generation, transitions `.loading`, calls `gitManager.gitStatus()`, drops stale completions; on success → `.loaded` + status; on failure → `.failed` + lastError + danger toast routed via ErrorPresentation (only for non-silent presentations).
- Computed: `badgeText`, `badgeAccessibilityLabel`, `canPull` (= `status.isGitRepository && status.hasRemote && operationState == .idle && !appState.anyWriteInFlight`), `canPush` (same + `aheadCount > 0` OR allow always when `hasRemote`), `isFullyClean`.
- DoD: `GitStatusModelTests.swift` ≥ 14 methods cover load happy / load failure / generation cancellation / computed booleans across 6 representative status snapshots / canPull/canPush gating respecting `anyWriteInFlight`.

### C.2 GitStatusModel observe-changes hook
- Add `observeChanges() async` to `GitStatusModel` (mirrors F.5 + H.x patterns): subscribe to `passManager.changes`; on each `StoreChange` event call `await loadStatus()`. Re-entrancy guard. `stop()` test seam.
- `AppState.scenePhase` rebroadcast: extend `KizbaApp` to call `gitStatusModel?.loadStatus()` on `scenePhase == .active`.
- DoD: `GitStatusModelObserveTests.swift` ≥ 4 methods cover subscribe → bulk event triggers reload, re-entrancy idempotency, stop cancellation.

### C.3 AppState extension
- Extend `Kizba/App/AppState.swift` with `var gitStatusModel: GitStatusModel?` (nil for non-git stores). DEBUG-only convenience init still works (gitStatusModel defaults to nil).
- DoD: `AppStateTests` augmented with one assertion (default nil).

### C.4 AppEnvironment.live() startup wiring
- Extend `Kizba/App/AppEnvironment.swift` `live()`: after constructing `LivePassManager`, build a `LivePassGitManager`, perform a one-shot `await gitManager.gitStatus()` (best-effort, swallow errors → treat as not-a-repo); if `status.isGitRepository == true`, construct `GitStatusModel` and assign to `appState.gitStatusModel`. Otherwise both `gitManager` and `gitStatusModel` stay nil.
- `preview()` keeps both nil. Tests pass `FakePassGitManager` + manually constructed `GitStatusModel`.
- DoD: app launches against a non-git store with `gitStatusModel == nil` (no badge); against a git store, `gitStatusModel != nil` and badge renders.

### C.5 GitStatusBadge view
- New `Kizba/Presentation/Features/Git/GitStatusBadge.swift`: SF Symbol + tiny label; rendering rules per U3 (subtle dot when `isFullyClean`); tappable → opens `GitActionsPopover`. Full a11y label sourced from `GitStatusModel.badgeAccessibilityLabel`.
- All styling via `theme.colors` + `theme.typography` + `theme.spacing` — no inline styling.
- DoD: `GitStatusBadgeTests.swift` ≥ 6 methods cover render-by-status (clean dot, dirty, ahead, behind, conflict, no-remote) + a11y label content.

### C.6 GitActionsPopover view
- New `Kizba/Presentation/Features/Git/GitActionsPopover.swift`: Pull / Push / Refresh / Open Terminal buttons; spinner + Cancel during in-flight ops (driven by `model.operationState`). Cancel calls `model.cancelOperation()` (added in Phase D).
- "Open Terminal" button calls `model.openTerminalAtStore()` (added in Phase D).
- DoD: `GitActionsPopoverTests.swift` ≥ 5 methods cover button enable/disable matrix + spinner visibility + Cancel visibility.

### C.7 Sidebar mount
- Edit `Kizba/Presentation/Features/Sidebar/SidebarView.swift`: mount `GitStatusBadge(model:)` at the bottom of the folder list, hidden when `state.gitStatusModel == nil`. The badge anchors a `.popover(isPresented:)` for `GitActionsPopover`.
- DoD: manual smoke (git store) shows badge; (non-git store) hides badge.

### C.8 Git menu commands
- New `Kizba/App/GitMenuCommands.swift`: `Commands` builder adding a "Git" menu with items "Refresh Status" (⌘⇧R, the only shortcut per U4), "Pull", "Push", "Open Terminal at Store". All items disabled when `state.gitStatusModel == nil` or `state.anyWriteInFlight` (Pull/Push only).
- Conditionally added to `KizbaApp.commands` — present only when `state.gitStatusModel != nil`.
- DoD: manual smoke confirms menu appears only on git stores; ⌘⇧R triggers `loadStatus()`. `GitMenuCommandsTests` (lightweight) verifies disable conditions.

### C.9 Phase C regression
- Run full suite + grep bans + Release build + manual smoke (sidebar badge appears/hides, popover opens, ⌘⇧R refreshes, menu items present).
- DoD: full suite green (~+30 new tests); grep bans clean; manual smoke noted.

**Phase C DoD:** Read-only git status surface (badge + popover + menu) wired end-to-end on git stores; no Pull/Push/conflict logic yet (stubs ok); refresh on `StoreChange` + scenePhase + manual button works.

---

## Phase D — Pull / Push + lockout + conflict UX (~3 days, medium-high risk)

### D.1 ActiveWriteOp extension
- Extend `Kizba/App/AppState.swift` `enum ActiveWriteOp` with `.gitPull`, `.gitPush`. `Set<ActiveWriteOp>` semantics + `anyWriteInFlight` automatically include them.
- Verify all toolbar/menu disable conditions for the existing 5 write ops still gate correctly when a git op is in flight (zero new wiring expected).
- DoD: `AppStateLockoutTests` augmented (≥ 2 new assertions); manual smoke confirms entry-write toolbar buttons disable while pull/push runs.

### D.2 AppRouter conflict banner state
- Extend `Kizba/App/AppRouter.swift`: `var isGitConflictBannerPresented: Bool` (stored), `func presentGitConflictBanner()`, `func dismissGitConflictBanner()`.
- DoD: `AppRouterTests` +3 methods (default false; present sets true; dismiss sets false).

### D.3 GitStatusModel pull / push / cancel / openTerminal
- Add to `GitStatusModel`:
  - `pull()` async: pre-flight refuse if `appState.anyWriteInFlight` (no toast — silently no-op, button is already disabled in UI; defense-in-depth); call `appState.beginWrite(.gitPull)`; bump generation; transition `.pulling`; read `gitOperationTimeoutSeconds` from settings; call `gitManager.gitPull(timeoutSeconds:)`; on success → `.idle`, success toast `Toast(severity: .success, title: "Pulled", message: status.branch ?? "")`, then `await loadStatus()`; on `gitConflict(paths)` → `.idle`, no toast, call `router.presentGitConflictBanner()`; on other errors → `.idle`, route through ErrorPresentation; ALWAYS call `appState.endWrite(.gitPull)` in `defer` analogue.
  - `push()` async: same shape; on success `.pushed` → `Toast(severity: .success, title: "Pushed", message: status.branch ?? "")`; on success `.alreadyUpToDate` → per U5 `Toast(severity: .info, title: "Already up to date", message: "Nothing to push.")`; on `gitRejected(reason)` → `.idle`, danger toast with reason; on conflict (rare for push) → router banner.
  - `cancelOperation()`: cancels the current pull/push task (via stored `Task` handle); endWrite called by the task's catch path on `CancellationError`.
  - `openTerminalAtStore()`: per U2, `NSWorkspace.shared.open(URL(fileURLWithPath: storePath))`. Pure side effect; no state change.
  - `refreshConflictAutoDismiss()` helper: after each `loadStatus()` completion, if `router.isGitConflictBannerPresented && !status.hasConflicts` → call `router.dismissGitConflictBanner()`.
- DoD: 4 new test files, each ≥ 5 methods:
  - `GitStatusModelPullTests.swift` — happy / conflict / network / cancellation / lockout pre-flight.
  - `GitStatusModelPushTests.swift` — happy `.pushed` / happy `.alreadyUpToDate` (U5 toast assertion) / rejected / auth fail / cancellation.
  - `GitStatusModelLockoutTests.swift` — pull blocked while `.insertNew` is in flight; push blocked while `.gitPull` is in flight; entry write blocked while `.gitPush` is in flight.
  - `GitStatusModelOpenTerminalTests.swift` (lightweight; injects an `NSWorkspaceOpening` seam protocol) — verifies URL passed.

### D.4 GitConflictBanner view
- New `Kizba/Presentation/Features/Git/GitConflictBanner.swift`: modal sheet content. Per U1: title + body text "Merge conflict in `<store path>`. Some entries have conflicting changes. Kizba does not resolve them automatically." with `<store path>` rendered via `.font(theme.typography.mono)`, copy-able. Primary button "Open Terminal at Store" → `model.openTerminalAtStore()` then `router.dismissGitConflictBanner()`. Secondary button "Dismiss" → `router.dismissGitConflictBanner()`.
- Mounted in `KizbaApp` body via `.sheet(isPresented: $state.router.isGitConflictBannerPresented)`. Per the A.3 grep rule, the model is NOT constructed inside the sheet body — `GitStatusModel` already lives on `AppState`.
- DoD: `GitConflictBannerTests.swift` ≥ 4 methods cover render with sample path / button tap dispatches / a11y traits / auto-dismiss when subsequent status check shows `hasConflicts == false`.

### D.5 Phase D regression
- Run full suite + grep bans + Release build + manual smoke matrix (see §6).
- DoD: full suite green (~+25 new tests); grep bans clean; manual matrix run.

**Phase D DoD:** Pull, Push, conflict banner, lockout, terminal launch, U1/U2/U5 wired correctly; cancellation works; auto-dismiss of banner after fixed conflict works.

---

## Phase E — Polish, settings, a11y, opt-in E2E, docs (~2 days, low risk)

### E.1 Settings — gitOperationTimeoutSeconds (per U7)
- Extend `Kizba/Infrastructure/Settings/SettingsKeys.swift`: add `gitOperationTimeoutSeconds: Int = 60`. Update `SettingsStoring` allow-list.
- Extend `Kizba/Presentation/Features/Settings/SettingsModel.swift`: round-trip + clamp to 10…300.
- Extend `Kizba/Presentation/Features/Settings/SettingsView.swift`: visible `Stepper` "Git operation timeout" with seconds suffix, range 10…300, step 5. Section under "Git" or appended to existing "Advanced".
- DoD: `UserDefaultsSettingsStoreTests` +1 round-trip + 1 default; `SettingsModelTests` +1 clamp; manual: stepper visible and persists.

### E.2 Accessibility pass
- Audit Git surfaces:
  - `GitStatusBadge`: `.accessibilityLabel(model.badgeAccessibilityLabel)` + `.accessibilityValue(model.badgeAccessibilityValue)` (e.g. "1 ahead, 2 behind" / "clean").
  - `GitActionsPopover` buttons: `.accessibilityHint(...)` per button (e.g. "Pulls latest changes from the remote").
  - Git menu items: same hints.
  - `GitConflictBanner`: `.accessibilityAddTraits(.isModal)` + group via `.accessibilityElement(children: .contain)`.
- DoD: focused a11y test methods added across `GitStatusBadgeTests` / `GitActionsPopoverTests` / `GitConflictBannerTests` (~+6); manual VoiceOver pass noted.

### E.3 Opt-in E2E suite
- New `KizbaTests/PassGitIntegrationTests.swift` gated by `KIZBA_GIT_E2E=1` (`XCTSkipUnless` at top of each method). Inherits the existing `KIZBA_E2E=1` GPG-key bootstrap recipe (so running E2E git requires both env vars set; document in handoff).
- Setup per test: temp dir `/tmp/kizba-git-e2e-<id>/` with bare repo + working clone (`file://` remote), `pass init`, `git -C` config user.email/user.name. Tear-down: `rm -rf` (defer).
- Methods (≥ 7):
  - `testStatus_clean` — fresh clone returns `isGitRepository true`, branch known, no local changes, ahead=0, behind=0.
  - `testStatus_dirty` — after `pass insert -m`, status reports `hasLocalChanges == true`.
  - `testPull_happy` — push from another clone, pull picks it up, status updates.
  - `testPull_conflict` — same path edited differently in two clones; pull throws `gitConflict(paths:)`.
  - `testPush_happy` — local commit + push → success, status reports ahead=0.
  - `testPush_alreadyUpToDate` — second push immediately returns `.alreadyUpToDate`.
  - `testStatus_noRemote` — repo without remote returns `hasRemote == false`.
- DoD: all 7 pass locally with `KIZBA_GIT_E2E=1 KIZBA_E2E=1`; silently skipped otherwise.

### E.4 Docs — README, decisions, handoff, smoke, a11y audit
- `README.md`: add "Git support" section (status badge, pull/push, conflict workflow, settings stepper, SSH-agent expectation, E2E recipe `KIZBA_GIT_E2E=1`).
- `.ai/decisions.md`: append `## 2026-XX-XX — MVP 4` section summarising the 20 locked architectural decisions + 7 UX decisions (one terse bullet each).
- `.ai/sequoia-smoke.md`: 4 new rows — git status (clean), pull happy path, push happy path, conflict modal banner.
- `.ai/a11y-audit.md`: new "Git surfaces" subsection; tick badge / popover / menu / banner.
- `.ai/handoff.md`: full rewrite for MVP 4 closure.
- DoD: each file diff reflects the listed additions.

### E.5 Final regression sweep
- `xcodebuild test` (default, opt-ins off).
- `xcodebuild build` (Release).
- All grep bans clean (existing + new git non-conformance rule).
- `KIZBA_E2E=1` opt-in pass (MVP 2 E2E still green).
- `KIZBA_FSEVENTS_TEST=1` opt-in pass (MVP 3 still green).
- `KIZBA_GIT_E2E=1 KIZBA_E2E=1` opt-in pass (new).
- DoD: 6 checks green; suite ≥ 737 + ~110 new ≈ ~847.

**Phase E DoD:** Settings stepper visible; a11y pass done; opt-in E2E green; docs current; ready to tag MVP 4.

---

## 4. Cross-cutting workstreams

- **Regression-prevention discipline**: A.6 SourceGrepTests git non-conformance rule lands in Phase A so any new git domain type added through B–E is checked from the start. All MVP 1–3 grep bans (`as!`, `Logger.*stdin|print\(.*stdin`, inline styling, `@Observable` on Presentation models, no model constructors in sheet bodies) continue to apply repo-wide.
- **Fixture consolidation**: A.5 `FakePassGitManager` + B.1 `GitStatusFixtures/` + B.3 `GitStderrFixtures/` are all under `KizbaTests/Fixtures/`. No per-test ad-hoc fakes.
- **Concurrency hygiene**: `LivePassGitManager` is an `actor`; `GitStatusModel` is `@MainActor`; all new value/enum types `Sendable` from declaration. NO new `@unchecked Sendable` (no FSEvents-equivalent shared state).
- **Generation-counter pattern**: every `loadStatus() / pull() / push()` bumps its own counter; stale completions silently dropped. Consistent with MVP 2 `EntryFormModel` and MVP 3 patterns.
- **Cancellation**: `Task.cancel()` translates to SIGTERM via existing `ProcessShellRunner`. No new cancellation infrastructure.
- **Logging discipline**: git mapper logs only outcome class + sanitised excerpt — NEVER full stderr, NEVER paths beyond the conflict-paths array (which is user-facing data, not a log). Conflict path array stays short; if future stderr formats explode it, cap at first N entries before storing.
- **Manual smoke**: §6 matrix in Phase D regression + Phase E E.4 sequoia-smoke updates.

## 5. Test plan (per-phase additions, approximate)

| Phase | New test files / fixtures | Approx. method count |
|---|---|---:|
| A | `GitStatusTests.swift`, `PassErrorGitCasesTests.swift`, `FakePassGitManager.swift` + `FakePassGitManagerTests.swift`, `SourceGrepTests` +1 method, `ErrorPresentationIntegrationTests` +6 methods | ~+18 |
| B | `GitStatusParserTests.swift`, `PassCLI+GitTests.swift`, `PassCLI+GitEnvTests.swift`, `PassGitErrorMapperTests.swift`, `LivePassGitManagerTests.swift`; fixtures `GitStatusFixtures/`, `GitStderrFixtures/` | ~+50 |
| C | `GitStatusModelTests.swift`, `GitStatusModelObserveTests.swift`, `GitStatusBadgeTests.swift`, `GitActionsPopoverTests.swift`, `GitMenuCommandsTests.swift`, `AppStateTests` (+1) | ~+30 |
| D | `AppRouterTests` (+3), `AppStateLockoutTests` (+2), `GitStatusModelPullTests.swift`, `GitStatusModelPushTests.swift`, `GitStatusModelLockoutTests.swift`, `GitStatusModelOpenTerminalTests.swift`, `GitConflictBannerTests.swift` | ~+25 |
| E | `UserDefaultsSettingsStoreTests` (+2), `SettingsModelTests` (+1), a11y assertions across existing Git test files (+6), `PassGitIntegrationTests.swift` (opt-in, +7) | ~+16 |

**Net suite delta:** ~ +110 tests (737 → ~847).

**Opt-in env vars:** `KIZBA_E2E=1` (existing); `KIZBA_FSEVENTS_TEST=1` (existing); `KIZBA_GIT_E2E=1` (new — requires `KIZBA_E2E=1` for shared GPG bootstrap).

**Snapshot tests:** still OUT.

## 6. Manual verification matrix

| Acceptance | Manual scenario | Automated coverage |
|---|---|---|
| Non-git store hides badge | Launch against `~/.password-store` without `.git/` → no badge, no Git menu | `GitStatusModelTests` + manual |
| Git store shows badge | Launch against git-initialised store → badge visible at sidebar bottom | `GitStatusBadgeTests` + manual |
| Clean repo subtle dot (U3) | Clean working tree, no ahead/behind → tiny dot, no loud "✓ Clean" | `GitStatusBadgeTests` |
| Status refresh on FS change | Edit a file via Finder/CLI → badge updates within ~700 ms (FSEvents → StoreChange → loadStatus) | `GitStatusModelObserveTests` + manual |
| Status refresh on app foreground | Switch to another app, edit store, switch back → badge updates | manual |
| Manual refresh ⌘⇧R | Hit ⌘⇧R → spinner briefly, badge re-evaluates | `GitMenuCommandsTests` + manual |
| Pull happy path | Click Pull in popover → success toast "Pulled" → badge updates | `GitStatusModelPullTests` + manual |
| Push happy path | Local commit → click Push → success toast "Pushed" | `GitStatusModelPushTests` + manual |
| Push no-op (U5) | Push twice; second click → info toast "Already up to date — Nothing to push." | `GitStatusModelPushTests` (toast assertion) |
| Conflict banner (U1) | Two clones with conflicting edits → Pull → modal banner with monospaced store path | `GitConflictBannerTests` + manual |
| Open Terminal (U2) | Banner "Open Terminal at Store" → Terminal.app opens at store path | `GitStatusModelOpenTerminalTests` + manual |
| Conflict banner auto-dismiss | Resolve conflict in Terminal, hit Refresh → banner disappears | `GitConflictBannerTests` + manual |
| Lockout entry-write during git op | Start Pull → toolbar `+`/`✎`/🎲/`↔`/🗑 disabled until Pull completes | `GitStatusModelLockoutTests` + manual |
| Lockout git op during entry-write | Start New Entry save → Pull menu item disabled | `GitStatusModelLockoutTests` + manual |
| Cancellation | Start Pull on slow network → click Cancel → operation aborts within 1–2s | `LivePassGitManagerTests` + manual |
| Settings stepper (U7) | Settings → Git timeout stepper visible, range 10…300, persists | `UserDefaultsSettingsStoreTests` + manual |
| No keyboard shortcut for Pull/Push (U4) | Verify Git menu shows ⌘⇧R only on "Refresh Status" | manual |
| Git non-conformance | Add Codable to GitStatus locally → grep test fires | `SourceGrepTests` (testGitDomainTypesNonConformances) |
| All MVP 1–3 grep bans pass | — | `SourceGrepTests` (existing) |
| Suite stays green | — | `xcodebuild test` |

## 7. Sequencing risks

**Hard gates (cannot reorder):**
- A → B: parser + LivePassGitManager need `GitStatus`, `GitPushOutcome`, `PassError` git cases, `PassGitManaging`.
- B → C: `GitStatusModel` needs `PassGitManaging` and a real (or fake) implementation.
- C → D: pull/push call paths need `GitStatusModel` already wired and observing.
- C.4 (`AppEnvironment.live()`) gates real-app smoke for everything in C/D.
- D.2 (`AppRouter.isGitConflictBannerPresented`) gates D.3 conflict routing and D.4 banner mount.
- A.6 grep rule lands BEFORE B introduces git infrastructure types — same defensive pattern as MVP 3 A.2/A.3.

**Reorderable (within a phase):**
- A.1 / A.2 / A.4 are independent; A.3 depends on A.2; A.5 depends on A.4; A.6 independent (needs A.1).
- B.1 (parser) is independent from B.2/B.3/B.4 (CLI + env + mapper); they converge at B.5 (LivePassGitManager).
- C.5 (badge view) and C.8 (menu commands) can land in either order after C.1–C.3; C.7 (sidebar mount) requires C.5.
- D.1 (lockout enum) and D.2 (router state) can land in parallel; D.3 needs both.
- E.1 / E.2 / E.3 / E.4 are independent; E.5 is the final sweep.

**Risk hot-spots:**
- B.1 parser fixture capture: must be done against three real git versions — book that work early in Phase B.
- B.5 cancellation propagation: easy to leak `endWrite(_:)` calls if the actor's catch paths aren't symmetric. Mirror MVP 3 patterns carefully.
- D.3 lockout pre-flight refuse: must be silent (no toast, button is already disabled) — accidental toast spam during rapid double-clicks is a likely review nit.
- E.3 E2E `pass init` + ephemeral GPG key recipe must reuse MVP 2 E2E bootstrap exactly; divergence will cause flaky teardown.

## 8. Out of scope (do NOT implement in MVP 4)

`pass git` auto-fetch / scheduled polling, `$TERMINAL` env preference, keyboard shortcuts for Pull/Push, in-app conflict resolution / merge tooling, "enableGitFeatures" toggle (auto-detected), per-path diff / commit log UI, Favorites, Recently used, OTP, menu-bar mode, global quick search, better metadata editing, browser auto-fill, keyboard-shortcut audit. All MVP 1–3 deferrals still hold (App Sandbox + helper tool, `ScrubbingString`, system `UndoManager` integration, snapshot tests, localization beyond English, third-party Swift Packages, per-path FSEvents delta, Touch ID password fallback / app-launch / per-`pass show`).
