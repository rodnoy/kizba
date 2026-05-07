# Kizba — Handoff

## Last completed action

Step **7.4 — DONE** (Diagnostics: in-memory `InvocationLog` ring
buffer; sanitised invocation publishing from `ProcessShellRunner`;
minimal `DiagnosticsModel` + `DiagnosticsView`).

### Applied changes

- `Kizba/Infrastructure/Diagnostics/Invocation.swift` — **new**.
  Sendable value type recording one shell invocation: id, executable,
  sanitised args, exitCode, sanitised stderr excerpt, startedAt,
  duration. **stdout is intentionally excluded** from the struct and
  from every code path that produces it.
- `Kizba/Infrastructure/Diagnostics/InvocationLog.swift` — **new**.
  Concurrency-safe `actor` ring buffer (default 200, clamped to >= 1).
  `record(_:)` evicts FIFO; `recent()` returns a newest-first
  snapshot; `clear()` empties storage. An `InvocationLogging` protocol
  lets `ProcessShellRunner` accept the sink without a hard dependency
  on the concrete actor.
- `Kizba/Infrastructure/Shell/ProcessShellRunner.swift` — **modified**.
  Added a new `init(invocationLog:)` overload; the zero-arg `init()`
  is preserved so existing call sites are untouched. Every run path
  (success, spawn failure with sentinel exitCode `-1`, cancellation
  with `-2`, timeout with `-3`) constructs an `Invocation` with args
  and stderr passed through `PassErrorMapper.sanitize` and ships it
  to the sink via `Task.detached` so the runner's hot path is never
  blocked by the actor's mailbox. `Log.shell` emits a single
  shape-only debug line per invocation (`executable` `.private`;
  status / excerpt length `.public`).
- `Kizba/Presentation/Features/Diagnostics/DiagnosticsModel.swift` —
  **new**. `@MainActor` `@Observable` view-model exposing
  `recentInvocations` and async `refresh()` / `clear()` against an
  injected `InvocationLog`.
- `Kizba/Presentation/Features/Diagnostics/DiagnosticsView.swift` —
  **new**. Minimal SwiftUI `List` rendering timestamp, executable
  basename, joined args, exit code, and the (already-sanitised)
  stderr excerpt. Toolbar exposes Refresh / Clear. The view is
  **not** mounted in `KizbaApp` yet — Phase 8 wires it into the
  Settings/Diagnostics scene.
- `KizbaTests/InvocationLogTests.swift` — **new** (5 tests).
- `KizbaTests/DiagnosticsModelTests.swift` — **new** (2 tests).
- `KizbaTests/ProcessShellRunnerInvocationTests.swift` — **new**
  (3 tests: success / timeout / cancellation publishing).
- `.ai/build-log.md` — appended step 7.4 verification block.
- `.ai/step.md` — bumped to `7.5`.
- `.ai/handoff.md` — this file.
- `.ai/last-run.json` — refreshed.
- `Kizba.xcodeproj/project.pbxproj` — **not modified** (new files
  auto-picked by `PBXFileSystemSynchronizedRootGroup`).

### Scope notes

- The project's default actor isolation is `MainActor`, so
  `Invocation.init` is explicitly `nonisolated` (the runner constructs
  the value from a `nonisolated` static helper).
- `PassErrorMapper.sanitize` is reused for both stderr **and** every
  argument; sensitive content in args is redacted before storage.
- `stdout` never reaches `Invocation`. `SourceGrepTests` still passes:
  no raw `print`, no stdout references, no direct `Logger`
  instantiation outside `Log.swift`, `PassSecret` stays non-`Codable`.
- The new `InvocationLogging` protocol surface is minimal
  (`record(_:) async`) so future Diagnostics consumers can stub it
  cheaply.
- No call site of `ProcessShellRunner()` (production or tests) was
  modified — the zero-arg initialiser is the canonical opt-out from
  publishing.

### Verification (executed on this host)

```
xcodebuild -scheme Kizba -project Kizba.xcodeproj \
  -destination 'platform=macOS' test
=> ** TEST SUCCEEDED **
   Executed 188 tests, with 0 failures (0 unexpected) in 4.790s
```

Build log: `.ai/build-log.md`.

### Commits

- `feat(diagnostics): add InvocationLog and DiagnosticsModel/View`
- `chore(shell): publish invocation records from ProcessShellRunner`
- `test(diagnostics): add InvocationLog and DiagnosticsModel tests`
- `chore(ai): record step 7.4 completion`

### Repo state at completion

- `xcodeproj_created = true`,
  `xcodeproj_modified = false`,
  `xcode_instructions_path = .ai/xcode_instructions.md`
  (no new UI steps required).
- `build_log_path = .ai/build-log.md`.

## Next action

Proceed to **step 7.5** (per `.ai/plan.md`).

`.ai/step.md` is set to `7.5`.

Note: `.ai/plan.md` numbers Diagnostics under Phase 8 (8.4) but
`.ai/step.md` follows the working step counter (7.4 just completed,
next 7.5). The orchestrator approved running 7.4 against the Phase 8.4
scope — see `.ai/last-run.json` history. If the next step needs
clarification (Phase 8 / 7.5 alignment), surface that to the
orchestrator before starting.

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
- `Invocation` never carries stdout; args + stderr are sanitised at
  the publisher (`ProcessShellRunner`) via `PassErrorMapper.sanitize`.
- All chat with user in Russian; all code/comments/docs/commits in
  English.

## Machine-readable summary

See `.ai/last-run.json`.
