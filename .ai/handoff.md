# Kizba — Handoff

## Last completed action

Step **6.3 — DONE** (`PasswordStoreScanner` — FileManager-backed
filesystem enumerator).

Added a new domain protocol and an `actor` implementation:

- `Kizba/Domain/Protocols/PasswordStoreScanning.swift` — `Sendable`
  protocol with `listEntries(in:) async throws -> [String]`,
  `validateStoreRoot(_:) async -> Bool`,
  `invalidate(storeRoot:) async`.
- `Kizba/Infrastructure/Store/PasswordStoreScanner.swift` —
  `public actor PasswordStoreScanner: PasswordStoreScanning`. Walks
  the store with `FileManager.default.enumerator(at:...)` and the
  `[.skipsHiddenFiles]` option. Skips `.git` (and any configured
  directories) via `enumerator.skipDescendants()` plus a defensive
  pathComponents check. Skips `.gpg-id` markers. Includes only
  regular files whose final extension is `.gpg` (case-insensitive).
  Computes the relative entry path through the existing
  `EntryPathConverter` and sorts the result via
  `localizedStandardCompare`. Caches results per standardised store-
  root path; `invalidate(storeRoot:)` drops a single key. Logs only
  shape-only metadata via `Log.discovery` (count `.public`, store
  path `.private`).

### Applied changes

- `Kizba/Domain/Protocols/PasswordStoreScanning.swift` — **new**.
- `Kizba/Infrastructure/Store/PasswordStoreScanner.swift` — **new**.
- `KizbaTests/PasswordStoreScannerTests.swift` — **new** (9 tests).
- `.ai/build-log.md` — appended step 6.3 verification block.
- `.ai/plan.md` — 6.2 and 6.3 ticked.
- `.ai/step.md` — bumped to `6.4`.
- `.ai/handoff.md` — this file.
- `.ai/last-run.json` — refreshed.
- `Kizba.xcodeproj/project.pbxproj` — **not modified** (new files
  picked up by the existing `PBXFileSystemSynchronizedRootGroup`).

### Design note

`FileManager` is not `Sendable` and cannot be stored as an actor
property under strict concurrency without an `@unchecked Sendable`
wrapper. The scanner therefore deviates from the original "inject a
`FileManager`" instruction in the work order: it uses
`FileManager.default` directly. Tests exercise the real filesystem
through per-test temporary directories, which is sufficient and
avoids unsafe wrappers. `ignoreList` is still injectable.

### Verification (executed on this host)

```
xcodebuild -scheme Kizba -project Kizba.xcodeproj \
  -destination 'platform=macOS' \
  -only-testing:KizbaTests/PasswordStoreScannerTests test
=> ** TEST SUCCEEDED **
   Executed 9 tests, with 0 failures (0 unexpected) in 0.070s

xcodebuild -scheme Kizba -project Kizba.xcodeproj \
  -destination 'platform=macOS' test
=> ** TEST SUCCEEDED **
   Executed 162 tests, with 0 failures (0 unexpected) in 7.364s
```

Build log: `.ai/build-log.md`.

### Commits

- `feat(store): add PasswordStoreScanner (FileManager enumerator, ignores .git / .gpg-id)`
- `test(store): add PasswordStoreScanner unit tests`
- `chore(ai): record step 6.3 completion`

### Repo state at completion

- `xcodeproj_created = true`,
  `xcodeproj_modified = false`,
  `xcode_instructions_path = .ai/xcode_instructions.md`
  (no new UI steps required).
- `build_log_path = .ai/build-log.md`.

## Next action

Proceed to **step 6.4** per `.ai/plan.md` (`TempStoreFixture` +
`PasswordStoreScannerTests`). The scanner already has 9 deterministic
tests using inline per-test temp directories. Step 6.4 is expected to
extract that fixture into `KizbaTests/Support/TempStoreFixture` and
broaden coverage if needed.

`.ai/step.md` is set to `6.4`.

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
