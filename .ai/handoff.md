# Kizba — Handoff

## Last completed action

Step **4.1 — DONE** (PassShowParser pure parser + unit tests).

`Kizba/Infrastructure/Pass/PassShowParser.swift` is a new, IO-free
parser for the body produced by `pass show <entry>`. It exposes
`PassShowParser.parse(_: String) throws -> PassShowResult`, where
`PassShowResult` carries the password, an ordered `[(String,String)]`
metadata list, and an optional notes string.

### Behaviour

Per `.ai/plan.md` Phase 4.1:

1. **Password.** Line 1 of the raw stdout, verbatim — only the
   trailing newline that splits it from the rest of the body is
   consumed by the splitter.
2. **Metadata block.** Contiguous run of lines matching
   `^[A-Za-z0-9_.-]+:` immediately after the password. Each line is
   split on the **first** `:` only, so values containing additional
   colons (`url: https://x.test:8443/path`, `ratio: 1:2:3`) survive
   intact. Ordering and duplicate keys are preserved.
3. **Notes.** The first non-metadata line and everything after it,
   joined verbatim by `\n`. Newlines inside the notes section are
   preserved exactly. Once the metadata block ends, any
   `key: value`-shaped line that follows is notes — not metadata.
4. **Empty input.** Throws `PassError.parsingFailed(reason:)`.

The parser performs no shell calls, no `FileManager` work, no
logging — its input is secret material.

`PassError.parsingFailed(reason:)` was already declared in Phase 1.1,
so no edits to `Kizba/Domain/Models/PassError.swift` were required.

### Applied changes

- `Kizba/Infrastructure/Pass/PassShowParser.swift` — **new** (139 lines).
- `KizbaTests/PassShowParserTests.swift` — **new** (10 tests, 166 lines).
- `.ai/build-log.md` — appended step 4.1 verification block.
- `.ai/step.md` — bumped to `4.2`.
- `.ai/last-run.json` — refreshed.
- `Kizba.xcodeproj/project.pbxproj` — **not modified**; new files are
  picked up by the existing `PBXFileSystemSynchronizedRootGroup`
  entries for `Kizba/` and `KizbaTests/`.

### Verification (executed on this host)

```
xcodebuild -scheme Kizba -project Kizba.xcodeproj \
  -destination 'platform=macOS' \
  -only-testing:KizbaTests/PassShowParserTests test
# => ** TEST SUCCEEDED **
#    Executed 10 tests, with 0 failures (0 unexpected) in 0.013 s

xcodebuild -scheme Kizba -project Kizba.xcodeproj \
  -destination 'platform=macOS' test
# => ** TEST SUCCEEDED **
#    Executed 115 tests, with 0 failures (0 unexpected) in 6.487 s
```

Build log: `.ai/build-log.md`.

### Commits

- `9af612b` — `feat(pass): add PassShowParser (pure)`
- `1adbb38` — `test(pass): add PassShowParser unit tests`
- (pending) `chore(ai): record step 4.1 completion`

### Repo state at completion

- HEAD will be the handoff bump commit once recorded.
- `xcodeproj_created = true`,
  `xcode_instructions_path = .ai/xcode_instructions.md` (no new UI
  steps required).
- `build_log_path = .ai/build-log.md`.

## Next action

Proceed to **step 4.2** per `.ai/plan.md`: extend
`PassShowParserTests` against a fixture corpus if needed, then begin
**4.3 — `PassErrorMapper`** (map known `pass`/`gpg` stderr signatures
to `PassError`, with a sanitiser that strips emails and hex IDs and
caps excerpt length).

Note: the Phase 4.1 test set in this commit already covers every
case enumerated in plan step 4.2 (password-only, metadata, notes,
duplicate keys, colon-in-value, notes containing key-like lines,
empty throws). Step 4.2 may collapse into a no-op or a small fixture
corpus addition — confirm with the user before adding test churn.

`.ai/step.md` is set to `4.2`.

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
