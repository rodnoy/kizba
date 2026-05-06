# Kizba — Handoff

## Last completed action

Step **3.3 — DONE** (ProcessShellRunnerTests broadened — Phase 3
acceptance suite finalised).

The deterministic five-test suite shipped in step 3.1 was retained
unchanged and broadened with six additional tests that pin
contractual properties relied on by upstream `PassCLI` (Phase 4):
environment composition (forwarding + non-inheritance), argv
discreteness (no shell re-parsing, embedded-whitespace preservation),
and spawn-time failure mapping (missing executable / non-absolute
path → `PassError.shellFailure(exitCode: -1, stderrExcerpt: "spawn
failed")`).

### Behaviour

- `KizbaTests/ProcessShellRunnerTests.swift` — extended in place
  (no new test file). Eleven tests total, eleven pass.

### Added tests

- `testEnvironmentVariablesAreForwardedToChild` — explicit env var
  reaches the child verbatim via `printf %s "$VAR"`.
- `testEmptyEnvironmentIsNotInheritedFromParent` — when the runner
  is given `[:]`, parent env does NOT leak. Verified with a marker
  set via `setenv` before the call and a `${VAR-unset}` shell
  default that resolves to literal `unset` in the child.
- `testArgumentsAreForwardedAsDiscreteArgvEntries` — `/bin/echo`
  receives discrete argv entries, no shell re-parsing.
- `testArgumentWithEmbeddedDoubleSpacesIsPreservedAsSingleArgv` —
  multiple embedded spaces survive the argv round-trip.
- `testSpawnFailureForMissingExecutable` — missing absolute path
  → `shellFailure(exitCode: -1, stderrExcerpt: "spawn failed")`.
- `testRelativeExecutableNotResolvedViaPATH` — runner does not
  consult PATH; bare-name URLs fail with the same sentinel.

### Applied changes

- `KizbaTests/ProcessShellRunnerTests.swift` — extended (+6 tests,
  +143 lines).
- `.ai/build-log.md` — appended step 3.3 verification block.
- `.ai/step.md` — bumped to `3.4`.
- `.ai/last-run.json` — refreshed.
- `Kizba.xcodeproj/project.pbxproj` — **not modified** (no new
  files; existing test class extended in place).
- No production source changed.

### Verification (executed on this host)

```
xcodebuild -scheme Kizba -project Kizba.xcodeproj \
  -destination 'platform=macOS' \
  -only-testing:KizbaTests/ProcessShellRunnerTests test
# => ** TEST SUCCEEDED **
#    Executed 11 tests, with 0 failures (0 unexpected) in 0.406 s

xcodebuild -scheme Kizba -project Kizba.xcodeproj \
  -destination 'platform=macOS' test
# => ** TEST SUCCEEDED **
#    Executed 103 tests, with 0 failures (0 unexpected) in 2.403 s
```

Build log: `.ai/build-log.md`.

### Commits

- `6dbcd99` — `test(shell): broaden ProcessShellRunnerTests with env/argv/spawn-failure coverage`
- (this handoff bump) — `chore(ai): record step 3.3 completion`

### Repo state at completion

- HEAD: handoff bump commit (recorded in this file once committed).
- `xcodeproj_created = true`,
  `xcode_instructions_path = .ai/xcode_instructions.md` (no new UI
  steps required — synchronized groups; tests added inline to an
  existing file).
- `build_log_path = .ai/build-log.md`.

## Next action

Proceed to **Phase 3 — step 3.4** per `.ai/plan.md`:
`SourceGrepTests`. Note that step 3.2 already shipped
`KizbaTests/SourceGrepTests.swift` with two tests covering the two
required properties (no raw `print(` and no `FileHandle.standardOutput`
/ `Darwin.stdout` / `fputs|fputc|puts|fwrite` tokens in
`Infrastructure/Shell/` and `Infrastructure/Pass/`). Step 3.4 should
either confirm that suite as the official Phase-3 deliverable
(closing Phase 3) or extend it (e.g. assert no `os_log` of the
`stdout:` label, no plaintext password-shaped tokens leaking through
debug helpers). After 3.4 closes, Phase 4 (`PassCLI` + parser +
error mapper) begins.

`.ai/step.md` is set to `3.4`.

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
