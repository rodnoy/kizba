# Kizba — Handoff

## Last completed action

Step **6.1 — DONE** (`EntryPathConverter` — pure URL → entry path string).

Added `Kizba/Infrastructure/Store/EntryPathConverter.swift`: a
`nonisolated` `Sendable` struct exposing one static method,

```swift
public static func entryPath(from fileURL: URL, storeRoot: URL) -> String?
```

The converter is strictly IO-free (no `FileManager`, no shell, no
logging) per the durable "no secrets in logs" decision and the
"pure logic" pattern already established by `PassShowParser`. It:

- Rejects URLs whose `pathExtension` (case-insensitive) is not `gpg`.
- Rejects URLs that are not strict descendants of `storeRoot` (compared
  via standardized `pathComponents`, so trailing slashes / `.` segments
  do not produce false negatives).
- Strips only the **final** `.gpg` extension from the basename; earlier
  dots in the filename (e.g. `foo.bar.baz.gpg` → `foo.bar.baz`) are
  preserved verbatim.
- Preserves Unicode and whitespace exactly (spaces, `☃`, CJK, etc.).
- Joins relative path components with `/`.
- Returns `nil` for the store root itself and for bare `.gpg` (empty
  basename).

### Applied changes

- `Kizba/Infrastructure/Store/EntryPathConverter.swift` — **new**.
- `KizbaTests/EntryPathConverterTests.swift` — **new** (8 tests:
  nested path, top-level, Unicode + spaces, multi-dot basename,
  non-gpg → nil, outside root → nil, store root itself → nil,
  bare `.gpg` → nil).
- `.ai/build-log.md` — appended step 6.1 verification block.
- `.ai/plan.md` — 6.1 ticked.
- `.ai/step.md` — bumped to `6.2`.
- `.ai/handoff.md` — this file.
- `.ai/last-run.json` — refreshed.
- `Kizba.xcodeproj/project.pbxproj` — **not modified** (new files
  picked up by the existing `PBXFileSystemSynchronizedRootGroup`).

### Verification (executed on this host)

```
xcodebuild -scheme Kizba -project Kizba.xcodeproj \
  -destination 'platform=macOS' \
  -only-testing:KizbaTests/EntryPathConverterTests test
=> ** TEST SUCCEEDED **
   Executed 8 tests, with 0 failures (0 unexpected) in 0.006s

xcodebuild -scheme Kizba -project Kizba.xcodeproj \
  -destination 'platform=macOS' test
=> ** TEST SUCCEEDED **
   Executed 153 tests, with 0 failures (0 unexpected) in 6.575s
```

Build log: `.ai/build-log.md`.

### Note on plan.md tick for 6.2

The new `EntryPathConverterTests.swift` already covers everything plan
item **6.2** asks for (nested, top-level, non-gpg, outside root,
Unicode, spaces — plus a couple of extra edge cases). The current
work order, however, instructed completion of **6.1 only** and a step
bump to `6.2`, so plan item 6.2 is left unchecked for the orchestrator
to tick once it has reviewed the tests. No additional test work is
expected at step 6.2.

### Commits

- `feat(store): add EntryPathConverter (pure URL -> entry path)`
- `test(store): add EntryPathConverter unit tests`
- `chore(ai): record step 6.1 completion`

### Repo state at completion

- `xcodeproj_created = true`,
  `xcodeproj_modified = false`,
  `xcode_instructions_path = .ai/xcode_instructions.md`
  (no new UI steps required).
- `build_log_path = .ai/build-log.md`.

## Next action

Proceed to **step 6.2** per `.ai/plan.md` (`EntryPathConverterTests`).
The tests have already been authored as part of step 6.1; the
orchestrator only needs to confirm coverage and tick the box, then
move on to **6.3 — `PasswordStoreScanner`**.

`.ai/step.md` is set to `6.2`.

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
