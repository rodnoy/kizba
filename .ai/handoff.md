# Kizba — Handoff

## Last completed action

Step **5.1 — DONE** (`BinaryDiscoveryService` — actor-isolated
implementation of `BinaryLocating`).

`Kizba/Infrastructure/Discovery/BinaryDiscoveryService.swift` is a
new, `Sendable` (actor), cache-backed service that:

- conforms to the pre-existing `BinaryLocating` protocol (already
  declared in Phase 1 with `BinaryName` enum and
  `locate(_:)` / `reDetect()` async methods);
- accepts an optional `[BinaryName: URL]` override map, an optional
  `pathOverride` string, an injected `@Sendable () -> [String: String]`
  environment reader, and an injected `FileExistenceChecking`
  (defaults to `DefaultFileExistenceChecker` wrapping
  `FileManager.default.isExecutableFile(atPath:)`);
- resolves in the documented order:
  1. explicit `overridePaths[name]` if it passes the executability
     check (a configured-but-missing override returns `nil` rather
     than silently falling back — by design, so the UI can show a
     Settings nudge);
  2. `/opt/homebrew/bin` → `/usr/local/bin` → `/usr/bin`;
  3. sanitised PATH walk — empty entries, relative paths, any
     entry containing a `..` component and duplicates are dropped;
     well-known directories already probed in step 2 are skipped;
  4. `nil`.
- caches results in `[BinaryName: URL?]`; `reDetect()` clears it;
- logs only sanctioned metadata via `Log.discovery`:
  * `name` `.public` (raw enum value),
  * resolved `path` `.private`,
  * `found` / cache-hit booleans `.public`;
- never logs raw PATH strings or environment values;
- no direct `Logger(subsystem:` instantiation; no `print(`; no
  reference to standard output (verified by `SourceGrepTests`).

A new public protocol `FileExistenceChecking` lives alongside the
service in the same file (it is implementation-detail of the
discovery subsystem; not in `Domain/Protocols/`).

### Applied changes

- `Kizba/Infrastructure/Discovery/BinaryDiscoveryService.swift` —
  **new**.
- `KizbaTests/BinaryDiscoveryServiceTests.swift` — **new** (6 tests
  + an embedded `FakeFileExistenceChecker` test double).
- `.ai/build-log.md` — appended step 5.1 verification block.
- `.ai/step.md` — bumped to `5.2`.
- `.ai/handoff.md` — this file.
- `.ai/last-run.json` — refreshed.
- `Kizba.xcodeproj/project.pbxproj` — **not modified**; the new
  `Infrastructure/Discovery/` directory is picked up by the existing
  `PBXFileSystemSynchronizedRootGroup` entries.

### Verification (executed on this host)

```
xcodebuild -scheme Kizba -project Kizba.xcodeproj \
  -destination 'platform=macOS' \
  -only-testing:KizbaTests/BinaryDiscoveryServiceTests test
# => ** TEST SUCCEEDED **
#    Executed 6 tests, with 0 failures (0 unexpected) in 0.009s

xcodebuild -scheme Kizba -project Kizba.xcodeproj \
  -destination 'platform=macOS' test
# => ** TEST SUCCEEDED **
#    Executed 141 tests, with 0 failures (0 unexpected) in 2.733s
```

Build log: `.ai/build-log.md`.

### Test coverage

`BinaryDiscoveryServiceTests`:

1. `testOverrideWins` — explicit override beats every system path.
2. `testHomebrewPreferredOverUsrLocal` — Apple-silicon Homebrew is
   probed before `/usr/bin`.
3. `testPathFallbackUsesSanitizedPathOrder` — relative entries,
   `..` components, empty entries and duplicates are dropped;
   sanitised order is preserved.
4. `testCachingAndReDetect` — first lookup caches; cache shields
   subsequent lookups from disk; `reDetect()` invalidates.
5. `testNoFalsePositives` — names whose probes all return false
   resolve to `nil`.
6. `testOverrideMisconfigurationDoesNotFallBack` — an override
   pointing at a non-existent file yields `nil` (no silent
   fallback).

### Step 4.6 disposition

As noted in the previous handoff, plan step 4.6
("FakeShellRunner + PassCLITests — success, decryption failure,
timeout, cancellation, arg/env composition") was already covered
inline by the 6 `PassCLITests` + embedded `FakeShellRunner`
committed in step 4.5. No separate 4.6 commit was made; the
orchestrator confirmed jumping straight to 5.1.

### Commits

- `feat(discovery): add BinaryDiscoveryService with caching and override support`
- `test(discovery): add BinaryDiscoveryService unit tests`
- (pending) `chore(ai): record step 5.1 completion`

### Repo state at completion

- `xcodeproj_created = true`,
  `xcodeproj_modified = false`,
  `xcode_instructions_path = .ai/xcode_instructions.md`
  (no new UI steps required).
- `build_log_path = .ai/build-log.md`.

## Next action

Proceed to **step 5.2** per `.ai/plan.md`. Plan step 5.2 reads
*"FakeFileExistenceChecker + BinaryDiscoveryServiceTests —
override wins; arm64 Homebrew first; fallback order; sanitized
PATH; cache; re-detect."* That spec is already satisfied inline
by the 6 tests + embedded `FakeFileExistenceChecker` committed
in this step. Confirm with the user whether to mark 5.2 as a
no-op and jump to **5.3 — wire `PassCLI` into
`AppEnvironment.live()`**.

`.ai/step.md` is set to `5.2`.

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
