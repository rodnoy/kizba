# Kizba — Handoff

## Last completed action

Step **3.1 — DONE** (ProcessShellRunner + minimal Log.swift wrapper).

Implemented the production `ShellCommandRunning` conformance under
`Kizba/Infrastructure/Shell/ProcessShellRunner.swift` and the minimal
`os.Logger` wrapper under `Kizba/Infrastructure/Logging/Log.swift`.
Both files are fully `nonisolated` to interoperate with
`Foundation.Process`'s private dispatch queues under the project-wide
`default-isolation=MainActor` setting.

### Behaviour

- Concurrent stdout/stderr drain via `readabilityHandler` (one EOF
  signal per stream tears down its handler). Tail bytes are flushed
  via `FileHandle.readToEnd()` inside `terminationHandler` so no data
  is lost on rapid exit.
- Timeout: a `Task.detached { try await Task.sleep(for: timeout) }`
  fires `box.timeout()` which calls `process.terminate()`; the
  termination handler then resolves the continuation with
  `PassError.timedOut`. The timeout task is cancelled on normal exit.
- Cancellation: `withTaskCancellationHandler` calls `box.cancel()`
  which marks the box and terminates the child; outcome is mapped to
  `PassError.cancelled`. If cancellation arrives before `process.run()`,
  the runner terminates the freshly-started process synchronously.
- Spawn-time failures (binary missing / not executable) become
  `PassError.shellFailure(exitCode: -1, stderrExcerpt: "spawn failed")`.
- Logging discipline: only sanitised metadata (executable path with
  `.private`, argument count, exit code, stderr byte length) reaches
  `Log.shell`. Captured `stdout` is **never** logged.
- A `ProcessBox` actor-substitute (NSLock-protected, `@unchecked
  Sendable`) guarantees single-shot resolution across the
  exit/timeout/cancel race.

Minor domain change: `ShellResult.init` is now `nonisolated` so it
can be constructed from the runner's background context.

### Coverage added (step 3.1)

`KizbaTests/ProcessShellRunnerTests.swift` — 5 deterministic tests:

- `testEchoSuccess` — `/bin/echo hello` → exit 0, stdout `"hello\n"`,
  empty stderr.
- `testNonZeroExit` — `/usr/bin/false` → non-zero exit, empty stdout.
- `testTimeoutTerminatesProcess` — `/bin/sleep 5` with 200 ms timeout
  → `PassError.timedOut` resolved in < 2 s.
- `testCancellationPropagates` — `/bin/sleep 5`, task cancelled
  after 100 ms → `PassError.cancelled` (or `CancellationError`)
  resolved in < 2 s; the child is terminated.
- `testLargeStdoutDrain` — `sh -c 'yes x | head -c 200000'` →
  exactly 200_000 bytes drained with no deadlock.

### Applied changes

- `Kizba/Infrastructure/Shell/ProcessShellRunner.swift` (new).
- `Kizba/Infrastructure/Logging/Log.swift` (new).
- `Kizba/Domain/Protocols/ShellCommandRunning.swift` — `ShellResult.init`
  marked `nonisolated`.
- `KizbaTests/ProcessShellRunnerTests.swift` (new).
- `.ai/build-log.md` — appended step 3.1 verification block.
- `.ai/step.md` — bumped to `3.2`.
- `.ai/last-run.json` — refreshed machine-readable summary.
- `Kizba.xcodeproj/project.pbxproj` — **not modified** (file-system
  synchronized root group picks up new sources/tests automatically).

### Verification (executed on this host)

```
xcodebuild -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' build
# => ** BUILD SUCCEEDED **

xcodebuild -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' test
# => ** TEST SUCCEEDED **
#    Executed 90 tests, with 0 failures (0 unexpected) in 7.019 (7.145) seconds
```

Build log: `.ai/build-log.md`.

### Commits

- `85ae489` — `feat(shell): add ProcessShellRunner (cancellable, timeout, concurrent drain)`
- `747a55f` — `test(shell): add ProcessShellRunner unit tests`

### Repo state at completion

- HEAD: `747a55f` (before this handoff commit).
- `xcodeproj_created = true`,
  `xcode_instructions_path = .ai/xcode_instructions.md` (no new UI
  steps required this round — synchronized groups).
- `build_log_path = .ai/build-log.md`.

## Next action

Proceed to **Phase 3 — step 3.2** per `.ai/plan.md`: flesh out
`Log.swift` if additional helpers are needed (e.g. category-specific
sanitisation helpers, signposts) and ensure every category routes
through `os.Logger` with the right privacy markers. Note that the
minimal `Log.swift` introduced in 3.1 already satisfies the subsystem
/ category surface required by the plan; 3.2 should consolidate
documentation and add any missing convenience helpers without
regressing the no-stdout-logging discipline. After 3.2, step 3.3
already has its production-side coverage from this round; 3.4
(`SourceGrepTests`) remains.

`.ai/step.md` is set to `3.2`.

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
