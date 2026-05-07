# Kizba — Handoff

## Last completed action

Step **4.3 — DONE** (PassErrorMapper + sanitiser + unit tests).

`Kizba/Infrastructure/Pass/PassErrorMapper.swift` is a new, pure (no
shell, no FileManager, no logging) mapper that translates `pass` /
`gpg` stderr (with optional exit code) into a domain `PassError` plus
a sanitised excerpt suitable for UI / Diagnostics. Step 4.2 collapsed
into a no-op as flagged in the previous handoff: the existing 10-case
`PassShowParserTests` already cover the corpus enumerated in plan 4.2.

### Behaviour

Per `.ai/plan.md` Phase 4.3 and `.ai/decisions.md` (no stdout logging
in `Infrastructure/Pass/`, sanitised excerpts only):

1. **Mapping rules** (case-insensitive substring matches on stderr,
   exit code consulted for timeout):
   - `decryption failed`, `no secret key`, `bad session key`,
     `secret key not available` → `.decryptionFailed(stderrExcerpt:)`.
   - `no pinentry`, `pinentry`, `inappropriate ioctl for device`,
     `gpg-agent` → `.pinentryNotConfigured`.
   - `<path>: No such file or directory` → `.binaryNotFound(<basename>)`.
   - `<shell>: command not found: <name>` → `.binaryNotFound(<name>)`.
   - `command not found` / `could not find executable` (no name
     parseable) → `.binaryNotFound("")`.
   - `exitCode == PassErrorMapper.timeoutExitCode` (124) or stderr
     contains `timed out` / `operation timed out` → `.timedOut`.
   - Anything else → `.shellFailure(exitCode:, stderrExcerpt:)`.
2. **Sanitiser** (`sanitize(_:maxLength:)`):
   - Replaces emails (`\S+@\S+`) with `<redacted-email>`.
   - Replaces long hex runs (`(?i)\b[0-9a-f]{8,}\b`) with
     `<redacted-id>` — covers OpenPGP key IDs and fingerprints.
   - Collapses whitespace runs (incl. newlines) into a single space.
   - Trims and caps length, with the ellipsis included in the budget
     so the result is always `<= maxLength` characters and the second
     pass leaves the string untouched.
   - **Idempotent**: `sanitize(sanitize(x)) == sanitize(x)`, verified
     in tests both for the redaction pipeline and at the exact cap.
3. The mapper never throws; every input yields a deterministic
   `(PassError, String)` pair.

`PassError.swift` was **not modified** — every case required by the
mapping table (`binaryNotFound`, `pinentryNotConfigured`,
`decryptionFailed`, `timedOut`, `shellFailure`) was already declared
in Phase 1.1.

### Applied changes

- `Kizba/Infrastructure/Pass/PassErrorMapper.swift` — **new**.
- `KizbaTests/PassErrorMapperTests.swift` — **new** (14 tests).
- `.ai/build-log.md` — appended step 4.3 verification block.
- `.ai/step.md` — bumped to `4.4`.
- `.ai/handoff.md` — this file.
- `.ai/last-run.json` — refreshed.
- `Kizba.xcodeproj/project.pbxproj` — **not modified**; new files are
  picked up by the existing `PBXFileSystemSynchronizedRootGroup`
  entries for `Kizba/` and `KizbaTests/`.

### Verification (executed on this host)

```
xcodebuild -scheme Kizba -project Kizba.xcodeproj \
  -destination 'platform=macOS' \
  -only-testing:KizbaTests/PassErrorMapperTests test
# => ** TEST SUCCEEDED **
#    Executed 14 tests, with 0 failures (0 unexpected)

xcodebuild -scheme Kizba -project Kizba.xcodeproj \
  -destination 'platform=macOS' test
# => ** TEST SUCCEEDED **
#    Executed 129 tests, with 0 failures (0 unexpected) in 2.896s
```

Build log: `.ai/build-log.md`.

### Commits

- `feat(pass): add PassErrorMapper (sanitize + map stderr to PassError)`
- `test(pass): add PassErrorMapper unit tests`
- (pending) `chore(ai): record step 4.3 completion`

### Repo state at completion

- HEAD will be the handoff bump commit once recorded.
- `xcodeproj_created = true`,
  `xcodeproj_modified = false`,
  `xcode_instructions_path = .ai/xcode_instructions.md` (no new UI
  steps required).
- `build_log_path = .ai/build-log.md`.

## Next action

Proceed to **step 4.4** per `.ai/plan.md`. Plan step 4.4 reads
*"PassErrorMapperTests — every signature; sanitizer cases;
idempotent."* That spec is already satisfied by the 14 tests committed
in this step (decryption / pinentry / both binary-not-found shapes /
timeout via exit code and via stderr / shell-failure fallback /
redaction / length cap / short-string passthrough / idempotent
general / idempotent at exact cap / mapper-excerpt-equals-sanitised
invariant). Confirm with the user whether to mark 4.4 as a no-op and
jump to **4.5 — `PassCLI`** (compose `pass show <entry>` with 120s
timeout, build env (PATH prepend, optional `PASSWORD_STORE_DIR` /
`GNUPGHOME`), and route errors through `PassErrorMapper`).

`.ai/step.md` is set to `4.4`.

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
