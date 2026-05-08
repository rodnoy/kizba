# Phase 9 — Polish, Security Audit, Release Hygiene

## Goal

Harden the Kizba MVP for Developer ID distribution: expand security tests, add entitlements, verify release binary cleanliness, add version/build metadata, and document notarization workflow.

## Constraints

- No `project.pbxproj` manual edits (Xcode-managed or `PBXFileSystemSynchronizedRootGroup` auto-pick).
- `@MainActor` where appropriate; strict concurrency = complete.
- No secrets in logs; `PassSecret` non-Codable, non-StringConvertible.
- `MockPassManager` stays behind `#if DEBUG`.
- No third-party dependencies.
- Minimal scoped changes per task.

## Tasks

### Task 9.1 — SecurityChecklistTests: expand SourceGrepTests
- **Priority:** 1 (critical — blocks release confidence)
- **Complexity:** Small
- **Objective:** Add tests to `SourceGrepTests.swift` (or a new `SecurityChecklistTests.swift`) that enforce:
  1. `PassSecret` is not `CustomStringConvertible` or `CustomDebugStringConvertible` (regex scan like existing Codable test).
  2. No `print(` calls anywhere in `Kizba/` (not just `Infrastructure/`) — broadened scope.
  3. `Invocation` struct never stores stdout (grep for `stdout` field/property in `Invocation.swift`).
  4. `MockPassManager` is fully gated behind `#if DEBUG` (already true — test confirms it stays).
- **Files to modify:**
  - `KizbaTests/SourceGrepTests.swift` — add 3 new test methods: `testPassSecretIsNotStringConvertible`, `testNoRawPrintInKizbaSource`, `testMockPassManagerIsDebugOnly`.
- **Exact changes:**
  - `testPassSecretIsNotStringConvertible`: regex scan `Kizba/` for `PassSecret` conforming to `CustomStringConvertible|CustomDebugStringConvertible` (same pattern as `testPassSecretIsNotCodable` but different conformance names).
  - `testNoRawPrintInKizbaSource`: call `assertNoMatches(roots: ["Kizba"], patterns: [print pattern], ...)` excluding `Log.swift`.
  - `testMockPassManagerIsDebugOnly`: read `MockPassManager.swift`, assert first non-comment non-blank line is `#if DEBUG`, last non-blank line is `#endif`.
- **Commit:** `test(security): expand SourceGrepTests with StringConvertible, print, and DEBUG guards`
- **Tests:** `testPassSecretIsNotStringConvertible`, `testNoRawPrintInKizbaSource`, `testMockPassManagerIsDebugOnly`
- **Verification:** `xcodebuild test -scheme Kizba -destination 'platform=macOS' -only-testing:KizbaTests/SourceGrepTests`
- **Risks:** Broadening `print(` scan to all of `Kizba/` may catch legitimate UI code using `print` — need to verify no hits exist first.

### Task 9.2 — Entitlements: Hardened Runtime
- **Priority:** 2 (required for notarization)
- **Complexity:** Small
- **Objective:** Create `Kizba.entitlements` with Hardened Runtime keys. Enable `com.apple.security.cs.disable-library-validation` (needed for pinentry interaction). No App Sandbox per decisions.md.
- **Files to add:**
  - `Kizba/Kizba.entitlements` — plist with `com.apple.security.cs.disable-library-validation = true`.
- **Files to modify:** None (entitlements file is added via Xcode Signing & Capabilities UI — do NOT edit `project.pbxproj` manually).
- **Exact changes:** Create the entitlements plist file. Provide Xcode instructions in `.ai/xcode_instructions.md` for enabling Hardened Runtime and pointing to the entitlements file.
- **Commit:** `chore(release): add Kizba.entitlements with Hardened Runtime`
- **Tests:** None (build-time verification only).
- **Verification:** `xcodebuild build -scheme Kizba -destination 'platform=macOS' -configuration Release`
- **Risks:** Entitlements file must be wired in Xcode manually (Signing & Capabilities tab). Document in xcode_instructions.md.

### Task 9.3 — Release binary audit: no fixture passwords in strings
- **Priority:** 3 (release gate)
- **Complexity:** Small
- **Objective:** Add a test (or shell script) that builds Release config and runs `strings` on the binary to confirm no `MockPassManager` fixture passwords appear.
- **Files to add:**
  - `KizbaTests/ReleaseBinaryTests.swift` — `testDebugFixturesAbsentFromReleaseDescription` — a documentation-only test that asserts `MockPassManager` is behind `#if DEBUG` (compile-time proof; runtime `strings` check is a CI script concern).
- **Exact changes:** The test verifies at compile time that `MockPassManager` type does not exist in Release builds by checking the `#if DEBUG` guard (already covered by 9.1's `testMockPassManagerIsDebugOnly`). Add a shell verification step to `.ai/xcode_instructions.md` documenting the `strings` command for CI.
- **Commit:** `chore(release): document release binary fixture audit`
- **Tests:** Covered by Task 9.1's `testMockPassManagerIsDebugOnly`.
- **Verification:** Manual: `xcodebuild build -scheme Kizba -configuration Release -destination 'platform=macOS'` then `strings <binary> | grep -i "hunter2\|correcthorse\|fixture"` returns empty.
- **Risks:** None — this is documentation + verification, not code.

### Task 9.4 — App version and build metadata
- **Priority:** 4
- **Complexity:** Small
- **Objective:** Set marketing version to `1.0.0` and build number to `1` in the target. Add a small `AppInfo` helper exposing `Bundle.main` version strings for the About/Settings view.
- **Files to add:**
  - `Kizba/App/AppInfo.swift` — `enum AppInfo` with `static var version: String` and `static var build: String` reading from `Bundle.main.infoDictionary`.
- **Files to modify:**
  - `Kizba/Presentation/Features/Settings/SettingsView.swift` — add version label in footer using `AppInfo.version`.
- **Commit:** `feat(app): add AppInfo version helper and display in Settings`
- **Tests:**
  - `KizbaTests/AppInfoTests.swift` — `testVersionIsNotEmpty`, `testBuildIsNotEmpty`.
- **Verification:** `xcodebuild test -scheme Kizba -destination 'platform=macOS' -only-testing:KizbaTests/AppInfoTests`
- **Risks:** None.

### Task 9.5 — Notarization documentation
- **Priority:** 5
- **Complexity:** Small
- **Objective:** Document the notarization workflow (archive → export → `notarytool submit` → `stapler staple`) in a `RELEASE.md` or in `.ai/xcode_instructions.md`.
- **Files to modify:**
  - `.ai/xcode_instructions.md` — append "Release & Notarization" section with exact shell commands.
- **Commit:** `docs(release): add notarization workflow to xcode_instructions`
- **Tests:** None.
- **Verification:** Review only.
- **Risks:** None.

### Task 9.6 — Final full test suite pass + cleanup
- **Priority:** 6 (last task)
- **Complexity:** Small
- **Objective:** Run full test suite, fix any warnings, remove dead code, ensure all `.ai/` state files are updated.
- **Files to modify:**
  - `.ai/handoff.md` — update to reflect Phase 9 completion.
  - `.ai/step.md` — set to `9.6` (done).
  - `.ai/context.md` — update Phase 9 status.
- **Commit:** `chore(ai): record Phase 9 completion`
- **Tests:** Full suite.
- **Verification:** `xcodebuild test -scheme Kizba -destination 'platform=macOS'` — all tests pass, 0 failures.
- **Risks:** None.

## Acceptance Criteria

1. `SourceGrepTests` includes `PassSecret` non-StringConvertible check, broadened `print` scan, and `#if DEBUG` guard verification — all green.
2. `Kizba.entitlements` exists with Hardened Runtime + `disable-library-validation`.
3. Release build contains no fixture passwords (`strings` audit clean).
4. `AppInfo.version` displays `1.0.0` in Settings footer.
5. Notarization commands documented in `.ai/xcode_instructions.md`.
6. Full test suite passes with 0 failures.
7. No `project.pbxproj` manual edits.

## Suggested current step

**Start with Task 9.1** (SecurityChecklistTests). Pure test code, no production changes, independently verifiable.
