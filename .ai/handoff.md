# Kizba — Handoff

## Last completed action

Step **4.5 — DONE** (`PassCLI` — composes `pass show <entry>`, runs
through `ShellCommandRunning`, parses with `PassShowParser`, maps
errors via `PassErrorMapper`).

Step **4.4** was treated as a no-op as flagged in the previous
handoff: its DoD ("PassErrorMapperTests — every signature; sanitizer
cases; idempotent.") was already satisfied by the 14 tests committed
in Phase 4.3.

`Kizba/Infrastructure/Pass/PassCLI.swift` is a new, `Sendable`,
side-effect-free-except-for-logging composer that:

- takes a pre-resolved absolute `executable: URL` (PATH lookup is
  the job of `BinaryDiscoveryService`, Phase 5);
- accepts explicit overrides for `PASSWORD_STORE_DIR`, `GNUPGHOME`,
  `PATH`, `HOME`;
- forwards the parent's `HOME` when no override is supplied (needed
  by `gpg`/`pinentry-mac`); never forwards any other parent env;
- exports a sanitised default `PATH`
  (`/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin`) when no override
  is supplied — `ShellCommandRunning` does not inherit parent env;
- routes failures through `PassErrorMapper.map(stderr:exitCode:)`
  and re-throws domain `PassError`s from the runner verbatim
  (`.timedOut` / `.cancelled` / spawn-time `.shellFailure`);
- logs only sanctioned metadata via `Log.pass`
  (executable `.private`, argc `.public`, status `.public`,
  stderrBytes `.public`, sanitised excerpt `.private`);
- never logs decrypted stdout (enforced statically by
  `SourceGrepTests` and reviewed in this step).

### Behaviour

Per `.ai/plan.md` Phase 4.5 / 4.6 and `.ai/decisions.md`:

1. `show(entryPath:timeout:)` builds `argv = ["show", entryPath]`,
   composes the env (PATH + optional STORE / GNUPGHOME / HOME), and
   delegates to `shellRunner.run(...)`.
2. Default timeout = `.seconds(120)` (constant
   `kizbaPassShowDefaultTimeout`) per the decision log.
3. On exit code `0`: stdout is decoded as strict UTF-8 and parsed
   by `PassShowParser`. UTF-8 decode failure surfaces as
   `PassError.parsingFailed`.
4. On non-zero exit: `PassErrorMapper` produces a sanitised
   excerpt and a domain `PassError`; the excerpt is included in the
   log record under `.private` privacy and the mapped error is
   thrown.
5. `Foundation.Process` is not touched in this file — every spawn
   goes through the injected `ShellCommandRunning` so tests use a
   `FakeShellRunner` and the production binary uses
   `ProcessShellRunner`.

### Applied changes

- `Kizba/Infrastructure/Pass/PassCLI.swift` — **new**.
- `KizbaTests/PassCLITests.swift` — **new** (6 tests + an embedded
  `FakeShellRunner` test double satisfying `ShellCommandRunning`).
- `.ai/build-log.md` — appended step 4.5 verification block.
- `.ai/step.md` — bumped to `4.6` (4.4 collapsed; 4.5 is the just-
  completed step).
- `.ai/handoff.md` — this file.
- `.ai/last-run.json` — refreshed.
- `Kizba.xcodeproj/project.pbxproj` — **not modified**; the new files
  are picked up by the existing `PBXFileSystemSynchronizedRootGroup`
  entries for `Kizba/` and `KizbaTests/`.

### Verification (executed on this host)

```
xcodebuild -scheme Kizba -project Kizba.xcodeproj \
  -destination 'platform=macOS' \
  -only-testing:KizbaTests/PassCLITests test
# => ** TEST SUCCEEDED **
#    Executed 6 tests, with 0 failures (0 unexpected) in 0.074s

xcodebuild -scheme Kizba -project Kizba.xcodeproj \
  -destination 'platform=macOS' test
# => ** TEST SUCCEEDED **
#    Executed 135 tests, with 0 failures (0 unexpected) in 7.197s
```

Build log: `.ai/build-log.md`.

### Commits

- `feat(pass): add PassCLI (show via ProcessShellRunner, parse+map errors)`
- `test(pass): add PassCLITests (success, decryption, timeout, cancellation, env)`
- (pending) `chore(ai): record step 4.5 completion`

### Repo state at completion

- HEAD will be the handoff bump commit once recorded.
- `xcodeproj_created = true`,
  `xcodeproj_modified = false`,
  `xcode_instructions_path = .ai/xcode_instructions.md` (no new UI
  steps required).
- `build_log_path = .ai/build-log.md`.

### API note for downstream phases

`PassCLI.init` does **not** take a `SettingsStoring` parameter. The
plan calls for that wiring to land in Phase 8.1 (where the concrete
`SettingsKey<…>` constants for `passBinaryOverride` /
`storePathOverride` / etc. are first declared) and to be assembled in
`AppEnvironment.live()` (Phase 5.3). For 4.5 we kept the constructor
to explicit URL/string overrides — the only contract the runner's
absolute-URL requirement and the empty-env-no-inheritance contract
permit at this stage. Downstream callers compose:

```swift
PassCLI(
    executable: try await locator.locate(.pass),
    shellRunner: ProcessShellRunner(),
    passwordStoreDir: settings.value(for: .storePathOverride).map(URL.init(fileURLWithPath:)),
    gnupgHome: nil,
    pathOverride: nil,   // production uses defaultPATH
    homeOverride: nil
)
```

Adapter conforming `PassCLI` to `PassManaging` (combining a
`PasswordStoreScanner` for `listEntries()` with `PassCLI.show(...)`)
is Phase 6.5; not in scope for 4.5.

## Next action

Proceed to **step 4.6** per `.ai/plan.md`. Plan step 4.6 reads
*"FakeShellRunner + PassCLITests — success, decryption failure,
timeout, cancellation, arg/env composition."* That spec is largely
satisfied in-line by the 6 tests + embedded `FakeShellRunner`
committed in this step. Confirm with the user whether to mark 4.6 as
a no-op and jump to **5.1 — `BinaryDiscoveryService`**.

`.ai/step.md` is set to `4.6`.

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
