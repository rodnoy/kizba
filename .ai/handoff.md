# Kizba — Handoff

## Last completed action

Step **3.2 — DONE** (Log.swift consolidation + SourceGrepTests).

Promoted the minimal Phase-3.1 `Log.swift` to the canonical, fully
documented logging surface for the module and added the static
analysis tests demanded by Phase 3 (`.ai/plan.md` step 3.4 — pulled
forward into 3.2 as instructed).

### Behaviour

- `Kizba/Infrastructure/Logging/Log.swift`
  - Subsystem `app.kizba`. Five categorised `os.Logger` instances:
    `shell`, `pass`, `clipboard`, `discovery`, `ui`. All `nonisolated`
    so they can be invoked from any actor / detached context (notably
    the `Process` private dispatch queues used by
    `ProcessShellRunner`).
  - File header now codifies the durable privacy/redaction policy
    from `.ai/decisions.md`: never log captured `stdout`; always
    interpolate file paths, store locations, entry paths,
    environment values, and free-form error descriptions with
    `privacy: .private`; only shape-only metadata (exit codes, byte
    counts, argument counts, boolean flags) may be `.public`.
  - Added `Log.maxStderrExcerpt` (512-byte cap) and
    `Log.redact(_:max:)` — a length-bounded helper for the rare
    case a free-form string must be stored *outside* the live
    `os_log` stream (Phase 8 Diagnostics ring buffer). Stronger
    sanitisation (email / hex-id stripping) remains the job of
    `PassErrorMapper` (Phase 4.3).
  - No call-site changes — every category retains the same name and
    type, so `ProcessShellRunner`'s existing logging keeps working
    untouched.

- `KizbaTests/SourceGrepTests.swift` (new, 2 tests)
  - Anchors the repo root via `#filePath` and walks
    `Kizba/Infrastructure/Shell/` + `Kizba/Infrastructure/Pass/`
    with `FileManager.enumerator`.
  - `testNoRawPrintInInfraShellAndPass` — fails on any `print(`
    token. Regex guards `(?<![A-Za-z0-9_.])print\(` against false
    positives (`someThing.print(`, `imprint(`).
  - `testNoStdoutReferencesInInfraShellAndPass` — fails on
    `FileHandle.standardOutput`, the C `stdout` global
    (`Darwin.stdout`), and the C streaming functions
    (`fputs`/`fputc`/`puts`/`fwrite`). Internal symbol names
    (tuple labels, enum `case` associated values, local `let`
    bindings called `stdout`) are intentionally **not** banned —
    they document the data they carry, never leave these
    directories, and the static analyser would otherwise force
    semantically-meaningless renames. The decision is documented
    inline in the test source.

- `KizbaTests/LogWrapperTests.swift` (new, 5 tests)
  - `testSubsystemIdentifier` — pins `Log.subsystem == "app.kizba"`.
  - `testCategoryLoggersAreDistinct` — every category accepts the
    documented privacy interpolation
    (`exec=\(path, privacy: .private)
      argc=\(argc, privacy: .public)`). Compile-time verification
    that no category was accidentally typed as something other than
    `os.Logger`.
  - `testRedactPassesShortStringThrough` /
    `testRedactTruncatesLongString` /
    `testRedactDefaultCap` — pin `Log.redact` length-cap semantics
    (passthrough, truncation with ellipsis, default cap of
    `Log.maxStderrExcerpt + 1` after the appended `…`).

### Applied changes

- `Kizba/Infrastructure/Logging/Log.swift` — promoted from the
  minimal Phase-3.1 wrapper to the canonical surface. Added policy
  header, `maxStderrExcerpt`, `redact(_:max:)`. Surface preserved.
- `KizbaTests/SourceGrepTests.swift` (new).
- `KizbaTests/LogWrapperTests.swift` (new).
- `.ai/build-log.md` — appended step 3.2 verification block.
- `.ai/step.md` — bumped to `3.3`.
- `.ai/last-run.json` — refreshed.
- `Kizba.xcodeproj/project.pbxproj` — **not modified** (file-system
  synchronized root group picks up new sources/tests automatically).

### Verification (executed on this host)

```
xcodebuild -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' build
# => ** BUILD SUCCEEDED **

xcodebuild -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' test
# => ** TEST SUCCEEDED **
#    Executed 97 tests, with 0 failures (0 unexpected) in 2.500 (2.714) seconds
```

Build log: `.ai/build-log.md`.

### Commits

- `ceaf896` — `feat(logging): consolidate Log.swift wrapper with privacy policy and redact() helper`
- `73de4ea` — `test(ci): add SourceGrepTests to enforce no print/stdout-leak in Shell and Pass infra`
- (this handoff bump) — `chore(ai): record step 3.2 completion`

### Repo state at completion

- HEAD: handoff bump commit (recorded in this file once committed).
- `xcodeproj_created = true`,
  `xcode_instructions_path = .ai/xcode_instructions.md` (no new UI
  steps required — synchronized groups).
- `build_log_path = .ai/build-log.md`.

## Next action

Proceed to **Phase 3 — step 3.3** per `.ai/plan.md`:
`ProcessShellRunnerTests`. Note that step 3.1 already shipped the
five-test deterministic suite covering echo success, non-zero exit,
timeout, cancellation, and large-stdout drain. Step 3.3 should
either confirm that suite as the official Phase-3 acceptance set or
broaden it (e.g. environment composition, executable URL not on
PATH, working-directory honoured) before moving on. After 3.3,
Phase 3 wraps up — Phase 4 (`PassCLI` + parser + error mapper)
follows.

`.ai/step.md` is set to `3.3`.

## Constraints (must hold from day one)

- No third-party packages.
- No QtPass / GPL pass-client source consulted during implementation.
- No secrets in logs (no stdout logging in `Shell/`/`Pass/`).
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
