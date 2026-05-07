# Kizba — Build Log

## 2026-05-06 — Step 1.1 (Domain types)

```
xcodebuild -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' build
=> ** BUILD SUCCEEDED **

xcodebuild -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' test
=> ** TEST SUCCEEDED **
   Executed 14 tests, with 0 failures (0 unexpected) in 4.744 (4.787) seconds
```

Test suites:

- KizbaTests (existing): 2 passed.
- PassEntryTests: 4 passed.
- PassMetadataTests: 3 passed.
- PassSecretSecurityTests: 3 passed (including Codable / CustomStringConvertible negative metatype checks).
- PassErrorTests: 2 passed.

Xcode 26.4.1 (17E202), macOS SDK 26.4, deployment target 14.0,
strict concurrency = complete.

## 2026-05-06 — Step 1.2 (Domain protocols)

```
xcodebuild -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' build
=> ** BUILD SUCCEEDED **

xcodebuild -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' test
=> ** TEST SUCCEEDED **
   Executed 28 tests, with 0 failures (0 unexpected) in 3.944 (3.992) seconds
```

New test suites (14 new tests, all passing):

- PassManagingTests: 4 passed (list, show round-trip, decryption-failure
  surfacing, storeLocation passthrough).
- ShellCommandRunningTests: 1 passed (argument/environment/timeout
  forwarding via recording double).
- ClipboardServicingTests: 2 passed (verbatim copy, ordered repeats).
- BinaryLocatingTests: 4 passed (locate hit, miss, reDetect cache
  invalidation, BinaryName raw values).
- SettingsStoringTests: 3 passed (round-trip, nil-removes, key isolation).

No production-code concrete implementations introduced — protocol
definitions only, per `.ai/decisions.md`.

## 2026-05-06 — Step 1.3 (Domain test refinement)

```
xcodebuild -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' test
=> ** TEST SUCCEEDED **
   Executed 49 tests, with 0 failures (0 unexpected) in 0.576 (0.624) seconds
```

New refinement test file (`KizbaTests/DomainModelsRefinementTests.swift`)
adds 21 deterministic edge-case tests on top of the 28 from steps 1.1
and 1.2:

- PassEntryRefinementTests: 6 passed (empty path, trailing slash,
  Unicode, hashable in `Set`, `id == path`, JSON shape pinned to
  single `path` key).
- PassMetadataRefinementTests: 4 passed (case-sensitive
  `firstValue`, duplicate-key + order Codable round-trip, empty notes
  vs nil distinction round-trip, `Field` hashability).
- PassSecretRefinementTests: 4 passed (verbatim whitespace/newline
  preservation, value-equality semantics, 4096-codepoint ω stress
  round-trip via Equatable, `Sendable` metatype check). NOT-Codable
  / NOT-CustomStringConvertible already pinned in 1.1 — not
  duplicated here.
- PassErrorRefinementTests: 4 passed (Hashable into `Set`, stderr
  excerpt is part of identity for both `decryptionFailed` and
  `shellFailure`, parameter-less cases distinct, `storeNotFound`
  carries path).
- DomainConcurrencyTests: 3 passed against an actor-backed
  in-memory `PassManaging` double — concurrent `add`s not lost
  (64 fan-out), concurrent `show` returns exact secret per entry
  (32 fan-out), concurrent `show` for unknown entries surfaces
  `decryptionFailed` (16 fan-out). Deterministic: fixed iteration
  counts, no timing assertions.

No production-code changes were required for step 1.3.


## 2026-05-06 — Step 2.1 (MockPassManager)

```
xcodebuild -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' test
=> ** TEST SUCCEEDED **
   Executed 59 tests, with 0 failures (0 unexpected) in 0.670 (0.808) seconds
```

Test suites added:

- MockPassManagerTests: 10 passed.
  - testMock_has20Fixtures — corpus pinned at 20 entries; first/last
    paths verified (`personal/email/gmail` / `archive/services/ftp`).
  - testFixtures_areDeterministicAcrossInstances — two independent
    `preview()` instances yield identical entry lists.
  - testFixtures_coverThreeFolders — top-level folders are exactly
    `{personal, work, archive}`.
  - testFixtures_includeEdgeCases — special-character entry name
    (`personal/email/jane+filter@example.com`) and empty trailing
    component (`personal/empty-name/`, `name == ""`) both present.
  - testShow_returnsExpectedEntry — `work/aws/root` round-trips
    password, metadata fields (user/url/mfa/created), and notes.
  - testShow_passwordOnlyEntry_hasEmptyMetadata — `personal/wifi/home`
    has no fields and `nil` notes.
  - testShow_unknownEntry_throwsDecryptionFailed — unknown path
    surfaces `PassError.decryptionFailed` (mirrors real "missing key"
    shape).
  - testStoreLocation_returnsFileURL — default URL is the stable
    `/tmp/kizba-mock-store` file URL.
  - testStoreLocation_honoursCustomURL — custom storeLocation echoed
    back unchanged.
  - testConcurrency_readers_consistentResults — 64 concurrent
    list+show calls all observe the baseline result. Deterministic;
    no timing assertions.

Production additions:

- `Kizba/Infrastructure/Pass/MockPassManager.swift` (new, gated by
  `#if DEBUG`). Actor-isolated `PassManaging` conformance with a
  20-entry deterministic fixture corpus across `personal/`, `work/`,
  `archive/`. `static let fixtures` and `static func preview()` for
  test/preview wiring (Phase 2.2 — `AppEnvironment.preview()`).
- No changes to `Kizba.xcodeproj/project.pbxproj` — file-system
  synchronized root group picks up new sources automatically.

## 2026-05-06 — Step 2.2 (AppEnvironment + AppState)

```
xcodebuild -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' test
=> ** TEST SUCCEEDED **
   Executed 67 tests, with 0 failures (0 unexpected) in 0.838 (0.980) seconds
```

New test suites:

- AppEnvironmentTests: 3 passed.
  - testPreview_passManagerExposesFixtureCorpus — 20-entry corpus,
    pinned first/last paths.
  - testPreview_passManagerShowReturnsKnownFixture — `work/aws/root`
    secret + `user` metadata field assertions.
  - testPreview_passManagerStoreLocationIsStable — fake
    `/tmp/kizba-mock-store` URL.
- AppStateTests: 5 passed.
  - testInit_defaultsAreEmpty
  - testInit_acceptsExplicitValues
  - testSelectedEntryID_isMutable
  - testSearchQuery_isMutable
  - testCurrentEntries_isMutable

Production additions:

- `Kizba/App/AppEnvironment.swift` — manual DI container. `live()` and
  `preview()` factories, `Sendable`. `preview()` wires
  `MockPassManager.preview()` plus tiny in-process fakes
  (`NoopClipboard`, `InMemorySettingsStore`) under `#if DEBUG`.
  Release builds compile via deterministic-failure placeholders
  (`UnavailablePassManager`, etc.).
- `Kizba/App/AppState.swift` — `@Observable @MainActor` root state
  with `selectedEntryID: PassEntry.ID?`, `searchQuery`,
  `isSidebarCollapsed`, `currentEntries`. No secret material.
- No changes to `Kizba.xcodeproj/project.pbxproj` — synchronized root
  group picks up new sources automatically.

## 2026-05-06 — Step 2.3 (RootSplitView + Sidebar)

```
xcodebuild -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' test
=> ** TEST SUCCEEDED **
   Executed 72 tests, with 0 failures (0 unexpected) in 9.965 (10.025) seconds
```

New test suite:

- SidebarModelTests: 5 passed (preview-environment folder derivation;
  pure helper determinism; top-level-without-slash skip; dedupe;
  initial empty state).

Total: 72 (67 prior + 5 new).

## 2026-05-06 — Step 2.4 (EntryListView + EntryListModel)

```
xcodebuild -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' test
=> ** TEST SUCCEEDED **
   Executed 76 tests, with 0 failures (0 unexpected) in 3.241 (3.323) seconds
```

New test suite:

- EntryListModelTests: 4 passed (initial unfiltered count = 20;
  folder filter for personal/work/archive; case-insensitive search
  filter combined with folder filter; `select(entryID:)` updates
  `AppState.selectedEntryID`).

Total: 76 (72 prior + 4 new).

## 2026-05-06 — Step 2.5 (EntryDetailView + EntryDetailModel)

```
xcodebuild -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' test
=> ** TEST SUCCEEDED **
   Executed 80 tests, with 0 failures (0 unexpected) in 1.249 (1.377) seconds
```

New test suite:

- EntryDetailModelTests: 4 passed (successful load → `.loaded`;
  rapid-selection cancellation drops the stale result and keeps only
  the last selection's secret; clearing selection mid-flight returns
  to `.idle`; `copy*` forwards verbatim values to clipboard with the
  requested `Duration` clear-after delay).

Total: 80 (76 prior + 4 new).

## 2026-05-06 — Step 2.6 (EntryDetailModel refinement tests)

```
xcodebuild -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' test
=> ** TEST SUCCEEDED **
   Executed 85 tests, with 0 failures (0 unexpected) in 1.755 (1.910) seconds
```

New file: `KizbaTests/EntryDetailModelRefinementTests.swift` — 5
deterministic tests harden the model invariants required by
`.ai/plan.md` step 2.6 and `.ai/decisions.md`:

- `testReveal_doesNotPersistSecret` — flipping `isPasswordRevealed`
  never moves the `PassSecret` out of `model.state.loaded(_:)`,
  never lands on `AppState` (Mirror-based runtime probe), and
  `PassSecret` stays non-`CustomStringConvertible` /
  non-`CustomDebugStringConvertible`. Clearing the selection releases
  the secret immediately.
- `testCopy_invokesClipboardWithDuration` — a `FakeClipboard` records
  every `(value, Duration)` pair; password and metadata copies arrive
  verbatim with the requested clear-after delay; no `"key: value"`
  composition.
- `testSelectionCancellation_races` — three rapid selection changes
  (a → b → c) against a 200 ms-delayed `ScriptedPassManager`
  converge on the last selection's secret; a 300 ms settle window
  asserts no stale task overwrites the loaded state.
- `testErrorMapping_setsFailedState` /
  `testErrorMapping_pinentryNotConfigured` — a `ScriptedPassManager`
  that throws a known `PassError` lands the model in
  `.failed(expected)` for both `decryptionFailed` and
  `pinentryNotConfigured`.

Test doubles (`ScriptedPassManager`, `FakeClipboard`,
`SilentClipboard`, `EphemeralSettingsStore`) are file-private — no
production code was modified.

Total: 85 (80 prior + 5 new).

## 2026-05-06 — Step 3.1 (ProcessShellRunner + Log.swift)

```
xcodebuild -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' build
=> ** BUILD SUCCEEDED **

xcodebuild -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' test
=> ** TEST SUCCEEDED **
   Executed 90 tests, with 0 failures (0 unexpected) in 7.019 (7.145) seconds
```

New production sources:

- `Kizba/Infrastructure/Logging/Log.swift` — minimal `os.Logger`
  wrapper with categories `shell`, `pass`, `clipboard`, `discovery`,
  `ui`. Subsystem `app.kizba`. All declarations `nonisolated` to be
  reachable from background drain handlers.
- `Kizba/Infrastructure/Shell/ProcessShellRunner.swift` —
  `ShellCommandRunning` implementation using `Foundation.Process`.
  Concurrent stdout/stderr drain via `readabilityHandler`; tail flush
  via `readToEnd()` in `terminationHandler`. Timeout via
  `Task.detached { Task.sleep(timeout) }` race + `terminate()`.
  Cancellation via `withTaskCancellationHandler` + `terminate()`.
  Spawn-time failure mapped to `PassError.shellFailure(-1, ...)`.
  Logs only sanitised metadata (executable path `.private`, argument
  count, exit code, stderr byte length); never logs stdout.

Minor domain change:

- `ShellResult.init` marked `nonisolated` so it can be constructed
  from the runner's background context under
  `default-isolation=MainActor`.

New tests in `KizbaTests/ProcessShellRunnerTests.swift` (5):

- `testEchoSuccess` — `/bin/echo hello` → exit 0, stdout "hello\n".
- `testNonZeroExit` — `/usr/bin/false` → non-zero exit, empty stdout.
- `testTimeoutTerminatesProcess` — `/bin/sleep 5` with 200 ms timeout
  → `PassError.timedOut` in < 2 s.
- `testCancellationPropagates` — `/bin/sleep 5`, task cancelled after
  100 ms → `PassError.cancelled` (or `CancellationError`) in < 2 s.
- `testLargeStdoutDrain` — `sh -c 'yes x | head -c 200000'` →
  exactly 200_000 bytes drained without deadlock.

Total: 90 (85 prior + 5 new).

## 2026-05-06 — Step 3.2 (Log.swift consolidation + SourceGrepTests)

```
xcodebuild -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' build
=> ** BUILD SUCCEEDED **

xcodebuild -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' test
=> ** TEST SUCCEEDED **
   Executed 97 tests, with 0 failures (0 unexpected) in 2.500 (2.714) seconds
```

Production change:

- `Kizba/Infrastructure/Logging/Log.swift` — promoted from the
  minimal Phase-3.1 wrapper to the canonical, fully-documented
  surface. Added an explicit privacy/redaction policy header,
  introduced `Log.maxStderrExcerpt` (512 byte cap) and
  `Log.redact(_:max:)` for the rare case a free-form string must be
  stored outside the live `os_log` stream (Phase 8 Diagnostics ring
  buffer). No call-site changes required — the existing five
  category loggers (`shell`, `pass`, `clipboard`, `discovery`, `ui`)
  retain the same names and types.

New tests (7):

- `KizbaTests/SourceGrepTests.swift` — 2 deterministic static
  analysis tests over `Kizba/Infrastructure/Shell/` and
  `Kizba/Infrastructure/Pass/`:
  - `testNoRawPrintInInfraShellAndPass` — fails on any
    `print(` token (regex guards against false positives like
    `someThing.print(` and `imprint(`).
  - `testNoStdoutReferencesInInfraShellAndPass` — fails on
    `FileHandle.standardOutput`, the Darwin C `stdout` global
    (`Darwin.stdout`), and the C streaming functions
    `fputs/fputc/puts/fwrite`. Internal symbol names (tuple
    labels, `case` associated values, local `let` bindings called
    `stdout`) are intentionally not banned — they document the
    data they carry and never leave these directories.
  Anchors the repo root via `#filePath` and walks `.swift` files
  with `FileManager.enumerator`.
- `KizbaTests/LogWrapperTests.swift` — 5 tests covering
  subsystem identity, that every category accepts the documented
  privacy interpolation (`exec=\(path, privacy: .private)
  argc=\(argc, privacy: .public)`), and `Log.redact` length-cap
  semantics (passthrough, truncation with ellipsis, default cap).

No `Kizba.xcodeproj/project.pbxproj` changes — file-system
synchronized root group picks up new sources/tests automatically.

Total: 97 (90 prior + 7 new).

---

## Step 3.3 — ProcessShellRunnerTests broadened (verified)

Date: 2026-05-06.
Host: macOS, Xcode 15.4+.

### Commands

```
xcodebuild -scheme Kizba -project Kizba.xcodeproj \
  -destination 'platform=macOS' \
  -only-testing:KizbaTests/ProcessShellRunnerTests test
# => ** TEST SUCCEEDED **
#    Executed 11 tests, with 0 failures (0 unexpected) in 0.406 (0.415) seconds

xcodebuild -scheme Kizba -project Kizba.xcodeproj \
  -destination 'platform=macOS' test
# => ** TEST SUCCEEDED **
#    Executed 103 tests, with 0 failures (0 unexpected) in 2.403 (2.596) seconds
```

### Added tests (KizbaTests/ProcessShellRunnerTests.swift, +6)

- `testEnvironmentVariablesAreForwardedToChild` — explicit env var
  reaches child verbatim via `printf %s "$VAR"`.
- `testEmptyEnvironmentIsNotInheritedFromParent` — when the runner is
  given `[:]`, parent env does NOT leak (verified with a marker
  `KIZBA_PARENT_LEAK` set via `setenv` before the call).
- `testArgumentsAreForwardedAsDiscreteArgvEntries` — `/bin/echo`
  receives discrete argv entries, no shell re-parsing.
- `testArgumentWithEmbeddedDoubleSpacesIsPreservedAsSingleArgv` —
  embedded multiple spaces survive the argv round-trip.
- `testSpawnFailureForMissingExecutable` — missing absolute path
  surfaces as `PassError.shellFailure(exitCode: -1,
  stderrExcerpt: "spawn failed")` per the documented contract.
- `testRelativeExecutableNotResolvedViaPATH` — bare-name URL is not
  looked up via PATH; same `shellFailure(-1, ...)` outcome.

No `project.pbxproj` changes — file-system synchronized root group
picks up the new test functions automatically (no new files were
added; the suite was extended in place).

Total: 103 (97 prior + 6 new).

## 2026-05-06 — Step 3.4 (SourceGrepTests finalisation)

```
xcodebuild -scheme Kizba -project Kizba.xcodeproj \
  -destination 'platform=macOS' \
  -only-testing:KizbaTests/SourceGrepTests test
=> ** TEST SUCCEEDED **
   Executed 4 tests, with 0 failures (0 unexpected) in 0.047 s

xcodebuild -scheme Kizba -project Kizba.xcodeproj \
  -destination 'platform=macOS' test
=> ** TEST SUCCEEDED **
   Executed 105 tests, with 0 failures (0 unexpected) in 2.630 s
```

`SourceGrepTests` was broadened from `Shell/`+`Pass/` to the entire
`Kizba/Infrastructure/` tree and now enforces four properties:

1. `testNoRawPrintInInfrastructure` — no raw `print(` calls (excluding
   the `Log` wrapper, whose docs legitimately mention the token).
2. `testNoStdoutReferencesInInfrastructure` — no
   `FileHandle.standardOutput`, `Darwin.stdout`, `fputs(`, `fputc(`,
   `puts(`, `printf(`, `fprintf(`, `fwrite(` (wrapper excluded).
3. `testNoDirectLoggerInstantiationOutsideWrapper` — no
   `Logger(subsystem:` / `OSLog(` outside
   `Kizba/Infrastructure/Logging/Log.swift`.
4. `testPassSecretIsNotCodable` — scans the whole `Kizba/` tree for
   any `struct PassSecret` / `extension PassSecret` declaration whose
   conformance list contains `Codable`/`Encodable`/`Decodable`.

Tests anchor the repo root via `#filePath` and skip `KizbaTests/` by
construction. No `project.pbxproj` changes — the test file was already
tracked (replaced in place).

Total: 105 (103 prior + 2 new SourceGrepTests cases; the 2 original
cases were renamed/rewritten into the broader engine).

## 2026-05-07 — Step 4.1 (PassShowParser)

```
xcodebuild -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' \
  -only-testing:KizbaTests/PassShowParserTests test
=> ** TEST SUCCEEDED **
   Executed 10 tests, with 0 failures (0 unexpected) in 0.013 s

xcodebuild -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' test
=> ** TEST SUCCEEDED **
   Executed 115 tests, with 0 failures (0 unexpected) in 6.487 s
```

New artefacts:

- `Kizba/Infrastructure/Pass/PassShowParser.swift` — pure parser
  (`PassShowParser.parse(_:) -> PassShowResult`) following the grammar
  in `.ai/plan.md` Phase 4.1. IO-free; no logging; preserves ordering
  and duplicate metadata keys; splits each metadata line on the first
  `:` only; treats any non-metadata line and the rest of the body as
  notes. Empty input throws `PassError.parsingFailed(reason:)`.
- `KizbaTests/PassShowParserTests.swift` — 10 cases covering
  password-only (with and without trailing newline), metadata block,
  duplicate keys, colon-in-value (`url: https://x.test:8443/path`),
  single-line and multi-line notes (newline-preserving), notes
  containing `key: value`-shaped lines, notes starting immediately
  after the password, and the empty-input throw.

`PassError.parsingFailed(reason:)` was already defined in Phase 1.1 —
no edits to `PassError.swift` were required. New files are picked up
automatically through the existing `PBXFileSystemSynchronizedRootGroup`
entries; `project.pbxproj` is unchanged.

Total: 115 (105 prior + 10 new `PassShowParserTests`).

## 2026-05-07 — Step 4.3 (PassErrorMapper)

```
xcodebuild -scheme Kizba -project Kizba.xcodeproj \
  -destination 'platform=macOS' \
  -only-testing:KizbaTests/PassErrorMapperTests test
=> ** TEST SUCCEEDED **
   Executed 14 tests, with 0 failures (0 unexpected) in ~0.08s

xcodebuild -scheme Kizba -project Kizba.xcodeproj \
  -destination 'platform=macOS' test
=> ** TEST SUCCEEDED **
   Executed 129 tests, with 0 failures (0 unexpected) in 2.896s
```

New artefacts:

- `Kizba/Infrastructure/Pass/PassErrorMapper.swift` — pure mapper
  (`PassErrorMapper.map(stderr:exitCode:) -> (PassError, String)`) plus
  `sanitize(_:maxLength:)`. Recognises decryption-failure / pinentry /
  missing-binary / timeout signatures; falls back to `.shellFailure`.
  The sanitiser redacts emails (`\S+@\S+`) and long hex IDs
  (`\b[0-9a-f]{8,}\b`, case-insensitive), collapses whitespace, trims,
  and caps length so the result is <= maxLength characters (ellipsis
  included in the budget — required for idempotency).
- `KizbaTests/PassErrorMapperTests.swift` — 14 cases covering each
  mapping branch, both binary-not-found shell shapes, timeout via exit
  code and via stderr text, sanitiser redaction + length cap +
  short-string passthrough, idempotency (general and at the exact cap),
  and the invariant that the excerpt embedded in the returned
  `PassError` equals the standalone excerpt returned alongside it.

No changes to `PassError.swift` (all required cases were declared in
Phase 1.1). New files picked up via `PBXFileSystemSynchronizedRootGroup`;
`project.pbxproj` unchanged.

Total: 129 (115 prior + 14 new `PassErrorMapperTests`).

## 2026-05-07 — Step 4.5 (PassCLI)

```
xcodebuild -scheme Kizba -project Kizba.xcodeproj \
  -destination 'platform=macOS' \
  -only-testing:KizbaTests/PassCLITests test
=> ** TEST SUCCEEDED **
   Executed 6 tests, with 0 failures (0 unexpected) in 0.074s

xcodebuild -scheme Kizba -project Kizba.xcodeproj \
  -destination 'platform=macOS' test
=> ** TEST SUCCEEDED **
   Executed 135 tests, with 0 failures (0 unexpected) in 7.197s
```

Test suites added in this step:

- PassCLITests: 6 passed
  - testShowSuccess_parsesPasswordAndMetadata
  - testDecryptionFailure_mapsToPassError
  - testTimeout_throwsTimedOut
  - testCancellation_propagatesCancellation
  - testEnvAndBinaryOverride_composition
  - testDefaultPATHIsExportedWhenNoOverridesSupplied

SourceGrepTests still green — no raw `print(`, no stdout reference,
no direct `Logger`/`OSLog` instantiation introduced; `PassSecret`
remains non-Codable. PassCLI logs only sanitised metadata
(executable .private, argc .public, status .public, stderrBytes
.public, sanitised excerpt .private).
