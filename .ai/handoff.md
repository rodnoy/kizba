# Kizba — Handoff

## Last completed action

Step **7.1 — DONE** (production `ClipboardService` actor with
token + `changeCount` auto-clear; deterministic unit tests via a
file-private `FakeClipboard` `PasteboardAdapter` double).

### Applied changes

- `Kizba/Infrastructure/Clipboard/ClipboardService.swift` — **new**.
  Defines an internal `PasteboardAdapter` protocol (Sendable;
  `changeCount`/`write`/`clear`), an internal
  `SystemPasteboardAdapter` backed by `NSPasteboard.general` (guarded
  by `#if canImport(AppKit)`, hops to the main actor), and a public
  `actor ClipboardService: ClipboardServicing`. Behaviour of
  `copy(_:clearAfter:)`:
    1. Mint a fresh opaque token (`UUID().uuidString`).
    2. Cancel any previously pending clear-task (courtesy; correctness
       follows from the token gate).
    3. Write the value verbatim through the adapter — no `"key: value"`
       composition, ever.
    4. Snapshot the post-write `changeCount`; store token + snapshot
       on the actor.
    5. Spawn a detached `Task` that sleeps for the supplied `Duration`
       and then asks the actor to attempt a clear. The actor wipes
       the pasteboard only if BOTH `currentToken` matches the
       requesting token AND the adapter's live `changeCount` equals
       the snapshot.
  Public API: `init()` (no-arg, wires `SystemPasteboardAdapter` on
  macOS) and `init(adapter:)` (internal — for tests / advanced
  wiring).
- `KizbaTests/ClipboardServiceTests.swift` — **new**. Five
  deterministic XCTest cases covering the full timeline through a
  file-private `FakeClipboard` `PasteboardAdapter` double (no
  `NSPasteboard` access, ever):
    - `testCopyWritesVerbatim`
    - `testAutoClear_whenUnchanged`
    - `testNoClear_whenChangeCountDiffers`
    - `testMultipleCopies_onlyLatestClears`
    - `testCancellation_ofClearTask_onNewCopy`
  The local `FakeClipboard` is `private` (file-scope) so it does not
  collide with the unrelated `FakeClipboard` doubles already in
  `DomainProtocolsTests` and `EntryDetailModelRefinementTests`
  (which conform to `ClipboardServicing`, not `PasteboardAdapter`).
- `.ai/build-log.md` — appended step 7.1 verification block.
- `.ai/step.md` — bumped to `7.2`.
- `.ai/handoff.md` — this file.
- `.ai/last-run.json` — refreshed.
- `Kizba.xcodeproj/project.pbxproj` — **not modified** (new files
  picked up automatically by `PBXFileSystemSynchronizedRootGroup`).

### Scope notes

- No changes to `ClipboardServicing` protocol — its existing
  `Duration`-typed signature was honoured exactly.
- No changes to `AppEnvironment`. The preview/live wiring still
  injects `NoopClipboard`/`UnavailableClipboard`. Step 7.3 will swap
  the live wiring to `ClipboardService()` and wire Copy buttons in
  `EntryDetailView`.
- `Log.clipboard` is used to record only sanctioned shape-only
  metadata (copy occurred, clear performed/skipped). The copied
  value is never logged in any form. `os` is imported by
  `ClipboardService.swift` to access `Logger.info` under the project's
  `MemberImportVisibility` upcoming feature; this does not breach
  `SourceGrepTests` because no direct `Logger(subsystem:)` /
  `OSLog(` instantiation occurs outside `Log.swift`.
- All `PasteboardAdapter` calls on the production adapter hop to the
  main actor (`NSPasteboard` is `MainActor`-bound on macOS); the
  hops happen only on the user-driven copy / clear paths.

### Verification (executed on this host)

```
xcodebuild -scheme Kizba -project Kizba.xcodeproj \
  -destination 'platform=macOS' \
  -only-testing:KizbaTests/ClipboardServiceTests test
=> ** TEST SUCCEEDED **
   Executed 5 tests, with 0 failures (0 unexpected) in 1.341s

xcodebuild -scheme Kizba -project Kizba.xcodeproj \
  -destination 'platform=macOS' test
=> ** TEST SUCCEEDED **
   Executed 173 tests, with 0 failures (0 unexpected) in 4.999s
```

Build log: `.ai/build-log.md`.

### Commits

- `feat(clipboard): add ClipboardService with token+changeCount auto-clear`
- `test(clipboard): add ClipboardService unit tests (FakeClipboard)`
- `chore(ai): record step 7.1 completion`

(Hashes recorded by git log after commit.)

### Repo state at completion

- `xcodeproj_created = true`,
  `xcodeproj_modified = false`,
  `xcode_instructions_path = .ai/xcode_instructions.md`
  (no new UI steps required).
- `build_log_path = .ai/build-log.md`.

## Next action

Proceed to **step 7.2 / 7.3**: wire `ClipboardService()` into
`AppEnvironment.live()` and connect the Copy buttons in
`EntryDetailView` to `env.clipboard.copy(field, clearAfter:)` (the
`clearAfter` value will come from `SettingsStoring`'s
`clipboardClearDelaySeconds`, defaulting to 30 s — Phase 8 handles
the persistent setting; for now a hard-coded 30 s constant is
acceptable and called out as a TODO).

`.ai/step.md` is set to `7.2`.

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
- `ClipboardService` writes values verbatim — never `"key: value"` —
  and gates auto-clear on token + `changeCount`.
- All chat with user in Russian; all code/comments/docs/commits in
  English.

## Machine-readable summary

See `.ai/last-run.json`.
