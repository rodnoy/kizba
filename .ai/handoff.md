# Kizba — Handoff

## Last completed action

Step **5.3 — DONE** (Wire `PassCLI` into `AppEnvironment.live()`).

`AppEnvironment.live()` now constructs the real production
collaborators that already exist:

- `ProcessShellRunner()` — Phase 3 production shell runner.
- `BinaryDiscoveryService()` — Phase 5.1 binary locator.
- `LivePassCLI(discovery:shellRunner:)` — new thin actor wrapper
  (this step) that lazily resolves the absolute path of `pass`
  through `BinaryLocating` at the first `show(entryPath:)` call
  rather than at composition-root construction time. This keeps
  `live()` synchronous.

`AppEnvironment` gained an optional `passCLI: LivePassCLI?` field.
`live()` always populates it; `preview()` leaves it `nil` so
SwiftUI previews and unit tests never reach for the real binary.
The remaining services (`passManager`, `clipboard`, `settings`)
keep their existing behaviour: in DEBUG they continue to use
`MockPassManager.preview()` / `NoopClipboard` / `InMemorySettingsStore`;
in RELEASE the deterministic-failing placeholders remain in place.
Phase 6.5 will replace `passManager` with a real wiring that uses
`passCLI` end-to-end.

### Why `LivePassCLI` exists

`PassCLI` requires an absolute executable URL at construction time,
and `BinaryDiscoveryService.locate(_:)` is `async`. Rather than
making `AppEnvironment.live()` itself `async` (which would propagate
through `KizbaApp` startup and break SwiftUI scene wiring), we wrap
`PassCLI` in a small `actor` that performs discovery on first use
and caches the resolved instance. `invalidate()` is exposed for the
Settings "Re-detect binaries" action scheduled in Phase 8.3.

### Minor `nonisolated` annotations on the pass-stack

The project compiles under `default-isolation=MainActor`, so by
default every type without an explicit isolation attribute is
treated as `@MainActor`. `LivePassCLI` is an `actor` and therefore
nonisolated; constructing and invoking `PassCLI` from inside it
required the following pure value-types to be marked `nonisolated`:

- `PassCLI` (struct)
- `PassErrorMapper` (struct)
- `PassShowParser` (struct)
- `PassShowResult` (struct)
- `kizbaPassShowDefaultTimeout` (top-level let)

These types are pure logic with no UI/AppKit dependencies, so the
annotation is semantically correct and matches the existing
`Sendable` conformance. No public API surface changed; existing
MainActor-isolated callers (e.g. `PassCLITests`) can still invoke
them transparently.

### Applied changes

- `Kizba/App/AppEnvironment.swift` — added optional `passCLI`
  field; `live()` constructs and threads through
  `ProcessShellRunner` + `BinaryDiscoveryService` + `LivePassCLI`.
- `Kizba/Infrastructure/Pass/LivePassCLI.swift` — **new**.
- `Kizba/Infrastructure/Pass/PassCLI.swift` — `nonisolated struct`
  + `nonisolated let kizbaPassShowDefaultTimeout`.
- `Kizba/Infrastructure/Pass/PassErrorMapper.swift` — `nonisolated`.
- `Kizba/Infrastructure/Pass/PassShowParser.swift` — `nonisolated`
  on both `PassShowResult` and `PassShowParser`.
- `KizbaTests/AppEnvironmentPassCLITests.swift` — **new** (4 tests).
- `.ai/build-log.md` — appended step 5.3 verification block.
- `.ai/step.md` — bumped to `5.4`.
- `.ai/handoff.md` — this file.
- `.ai/last-run.json` — refreshed.
- `Kizba.xcodeproj/project.pbxproj` — **not modified** (new files
  picked up by the existing `PBXFileSystemSynchronizedRootGroup`).

### Verification (executed on this host)

```
xcodebuild -scheme Kizba -project Kizba.xcodeproj \
  -destination 'platform=macOS' \
  -only-testing:KizbaTests/AppEnvironmentPassCLITests test
=> ** TEST SUCCEEDED **
   Executed 4 tests, with 0 failures (0 unexpected) in 0.005s

xcodebuild -scheme Kizba -project Kizba.xcodeproj \
  -destination 'platform=macOS' test
=> ** TEST SUCCEEDED **
   Executed 145 tests, with 0 failures (0 unexpected) in 2.964s

xcodebuild -scheme Kizba -project Kizba.xcodeproj \
  -destination 'platform=macOS' -configuration Release build
=> ** BUILD SUCCEEDED **
```

Build log: `.ai/build-log.md`.

### New test coverage

`AppEnvironmentPassCLITests`:

1. `testLive_includesPassCLI` — `live().passCLI` is non-nil.
2. `testPreview_doesNotIncludePassCLI` — `preview().passCLI` is nil.
3. `testLive_passCLIWiresBinaryDiscoveryService` — the wired
   discovery is a `BinaryDiscoveryService` instance.
4. `testLivePassCLI_throwsBinaryNotFoundWhenDiscoveryReturnsNil` —
   when discovery resolves to `nil`, `show(...)` throws
   `PassError.binaryNotFound("pass")` and the shell runner is
   never invoked.

### Manual end-to-end decrypt

Per the plan, real-decrypt verification on a host with `pass` +
`pinentry-mac` is part of step 5.3 DoD but cannot be executed in
the CI/sandbox environment. To exercise it manually on a developer
machine:

```
# AppEnvironment.live() is wired to real ProcessShellRunner +
# BinaryDiscoveryService + LivePassCLI. The DEBUG passManager is
# still MockPassManager; reach LivePassCLI directly:
let env = AppEnvironment.live()
let result = try await env.passCLI!.show(entryPath: "your/entry")
```

(Phase 6.5 will replace `passManager` with a real conformer that
calls into `passCLI` end-to-end so the UI exercises decrypt
through normal selection events.)

### Commits

- `feat(app): wire PassCLI into AppEnvironment.live()`
- `test(app): add AppEnvironment passCLI wiring tests`
- (pending) `chore(ai): record step 5.3 completion`

### Repo state at completion

- `xcodeproj_created = true`,
  `xcodeproj_modified = false`,
  `xcode_instructions_path = .ai/xcode_instructions.md`
  (no new UI steps required).
- `build_log_path = .ai/build-log.md`.

## Next action

Proceed to **step 5.4 / Phase 6.1** per `.ai/plan.md`.
Plan Phase 5 has no further numbered substeps after 5.3, so the
natural continuation is **6.1 — `EntryPathConverter` (pure URL →
entry path string)**.

`.ai/step.md` is set to `5.4`.

## Constraints (must hold from day one)

- No third-party packages.
- No QtPass / GPL pass-client source consulted during implementation.
- No secrets in logs (no stdout logging in `Infrastructure/`).
- `PassSecret` not Codable, not CustomStringConvertible.
- `PassSecret` lives only in the active `EntryDetailModel`, never in
  `AppState`.
- `PassManaging` MVP-1 surface stays read-only — no write/git methods.
- `MockPassManager` and its fixtures stay behind `#if DEBUG` so the
  release binary ships without them (re-checked in Phase 9.1).
- `AppEnvironment.live()` placeholders fail deterministically — any
  production wiring gap surfaces immediately at first call.
- All chat with user in Russian; all code/comments/docs/commits in
  English.

## Machine-readable summary

See `.ai/last-run.json`.
