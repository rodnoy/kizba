# Kizba — Handoff

## Last completed action

Step **3.4 — DONE** (SourceGrepTests finalisation/expansion — Phase 3
closed).

`KizbaTests/SourceGrepTests.swift` was rewritten in place: scope
broadened from `Infrastructure/Shell/`+`Infrastructure/Pass/` to the
entire `Kizba/Infrastructure/` tree, and the rule set was extended
to four deterministic properties. Production code untouched; no
violations found.

### Behaviour

`SourceGrepTests` now enforces, anchored via `#filePath`:

1. **No raw `print(`** anywhere under `Kizba/Infrastructure/`
   (`testNoRawPrintInInfrastructure`). Negative look-behind avoids
   `something.print(` and `imprint(`. The sanctioned wrapper
   `Kizba/Infrastructure/Logging/Log.swift` is excluded — its
   docstring legitimately mentions the forbidden token.
2. **No stdout-leaking references** (`testNoStdoutReferencesInInfrastructure`):
   `FileHandle.standardOutput`, `Darwin.stdout`, `fputs(`, `fputc(`,
   `puts(`, `printf(`, `fprintf(`, `fwrite(`. Wrapper excluded for
   the same documentation reason.
3. **No direct `Logger`/`OSLog` instantiation outside the wrapper**
   (`testNoDirectLoggerInstantiationOutsideWrapper`): `Logger(subsystem:`
   and `OSLog(` are forbidden everywhere except
   `Kizba/Infrastructure/Logging/Log.swift`.
4. **`PassSecret` not `Codable`** (`testPassSecretIsNotCodable`):
   scans the whole `Kizba/` tree for any `struct PassSecret` /
   `extension PassSecret` whose conformance list contains
   `Codable`/`Encodable`/`Decodable`. Reports file path, line and
   the offending snippet.

`KizbaTests/` is excluded from the scan by construction.

### Applied changes

- `KizbaTests/SourceGrepTests.swift` — rewritten (4 tests, +159 net
  lines vs. previous 2-test version).
- `.ai/build-log.md` — appended step 3.4 verification block.
- `.ai/step.md` — bumped to `3.5`.
- `.ai/last-run.json` — refreshed.
- `Kizba.xcodeproj/project.pbxproj` — **not modified** (file already
  tracked; replaced in place).
- No production source changed.

### Verification (executed on this host)

```
xcodebuild -scheme Kizba -project Kizba.xcodeproj \
  -destination 'platform=macOS' \
  -only-testing:KizbaTests/SourceGrepTests test
# => ** TEST SUCCEEDED **
#    Executed 4 tests, with 0 failures (0 unexpected) in 0.047 s

xcodebuild -scheme Kizba -project Kizba.xcodeproj \
  -destination 'platform=macOS' test
# => ** TEST SUCCEEDED **
#    Executed 105 tests, with 0 failures (0 unexpected) in 2.630 s
```

Build log: `.ai/build-log.md`.

### Commits

- `b24de56` — `test(ci): enforce logging discipline with SourceGrepTests`
- `019818c` — `chore(ai): record step 3.4 completion`

### Repo state at completion

- HEAD: handoff bump commit (recorded in this file once committed).
- `xcodeproj_created = true`,
  `xcode_instructions_path = .ai/xcode_instructions.md` (no new UI
  steps required — existing test file replaced in place).
- `build_log_path = .ai/build-log.md`.

## Next action

Phase 3 is closed. Proceed to **Phase 4 — step 3.5 / 4.1** per
`.ai/plan.md`: implement `PassShowParser` (pure parser for the body
of `pass show <entry>`).

`.ai/step.md` is set to `3.5`.

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
