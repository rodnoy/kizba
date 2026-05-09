# Kizba — Handoff

## Current state

**MVP 2 Phase D — COMPLETE.** Pure model layer for write features ready. Test suite: 462 tests, 1 skipped, 0 failures. Release build green.

MVP 1 (read-only) shipped. MVP 2 Phase A (tech debt + settings wiring + Diagnostics menu) closed. Phase B (design-system foundation) closed. Phase C (downstream DS components + view migration + grep bans) closed. Phase D adds the pure value types and transformations needed for Phase E (CLI writes) and Phase F (form models).

## Phase D summary (closed)

- D.1+D.2 `MetadataPair`, `SecretDraft` (final class, MainActor-bound by ownership), `EntryPathValidator`, `MetadataValidator`. Same security non-conformances as `PassSecret` (not Codable, not CustomStringConvertible/DebugStringConvertible). +55 tests.
- D.3 `PassSecretSerializer` — pure inverse of `PassShowParser`. **Format chosen to round-trip with the existing parser** (no blank-line separator before notes, no trailing `\n` appended). Round-trips 20/20 fixtures. Documented limitation: notes starting with a `key:` line cannot round-trip (XCTSkip with comment; Phase F validator will warn). +17 tests, 1 skipped.
- D.4 `PasswordGenerating` protocol + `LivePasswordGenerator` (CSPRNG via `Int.random(in:)`; charsets match `pass generate` defaults; throws on length ≤ 0). Statistical bias smoke test on 100 000 chars per mode. `FakePasswordGenerator` test fixture added. +12 tests.
- D.5 `PassGenerateParser` — strips ANSI SGR via pre-compiled `NSRegularExpression`, returns the LAST non-empty trimmed line. Fixtures from `pass` 1.7.3 + 1.7.4 (plain, colored, `--in-place`) + git-banner defensive case. +25 tests.
- D.6 6 new `PassError` cases (`entryAlreadyExists`, `recipientNotFound`, `invalidGpgId`, `sourceNotFound`, `writeFailed`, `invalidLength`). 3 computed properties on `PassError` (`inlineRecoverable`, `onboardingHint`, `autoRefreshes`). New `OnboardingHint` enum. `ErrorPresentation.present(for:)` extended (no new presentation cases — mapped onto existing 4). New `StoreChange` enum for Phase E `AsyncStream`. +21 tests.

Test count: MVP1 baseline 209 → A 216 → B 276 → C 330 → D 462 (1 skipped). Net Phase D: +132 tests.

## Side fix landed alongside Phase D

- `SidebarView` selection styling regression noticed during Phase C — sidebar showed system accent chrome instead of the new `surfaceSelected` token. Fixed by extending `EntryRowView.init` with optional `leadingIconName: String? = nil` (first param) and migrating sidebar rows to use `EntryRowView` + applying `.listStyle(.plain)`. +2 tests.

## Files added in Phase D

Production (`Kizba/Domain/Models/`, `Kizba/Domain/Protocols/`, `Kizba/Infrastructure/Pass/`):
- `MetadataPair.swift`, `SecretDraft.swift`, `EntryPathValidator.swift`, `MetadataValidator.swift`, `StoreChange.swift`.
- `PasswordGenerating.swift` (protocol + `PasswordGenerationError`).
- `PassSecretSerializer.swift`, `LivePasswordGenerator.swift`, `PassGenerateParser.swift`.

Tests:
- `MetadataPairTests.swift`, `SecretDraftTests.swift`, `EntryPathValidatorTests.swift`, `MetadataValidatorTests.swift`.
- `PassSecretSerializerTests.swift`, `LivePasswordGeneratorTests.swift`, `PassGenerateParserTests.swift`.
- `StoreChangeTests.swift`.
- `Fixtures/FakePasswordGenerator.swift`.
- Extended: `DomainModelsRefinementTests.swift`, `ErrorPresentationTests.swift`.

All Domain files import only `Foundation`. No SwiftUI / AppKit / os.

## Next step

**Phase E — Infrastructure / CLI.** Plumbing for write subprocess calls + `LivePassManager` wiring. Order:

1. E.1 `ShellInvocation` value type with `Stdin = .none | .data(Data) | .closeImmediately`. `ShellCommandRunning.run(_:)` becomes primary; old signature kept as compat extension delegating with `stdin: .none`.
2. E.2 `ProcessShellRunner` stdin pipe: write Data + close on EOF; concurrent with stdout/stderr drain; cancellation terminates. Logs only `stdinByteCount`. New `ProcessShellRunnerStdinTests`.
3. E.3 Upgrade `FakeShellRunner` to capture `ShellInvocation` (incl. stdin Data). Update existing callers.
4. E.4 `PassErrorMapper` new signatures (1.7.3 + 1.7.4 stderr fixtures): `entryAlreadyExists`, `recipientNotFound`, `invalidGpgId`/`sourceNotFound`, `invalidLength`.
5. E.5 `PassCLI` write methods (`insert -m [-f]`, `generate [-f] [-n] [--in-place]`, `rm -f`, `mv [-f]`). Extend `PassManaging` with the four methods + `var changes: AsyncStream<StoreChange>`. Tests: `PassCLIWriteTests` (argv + stdin exact bytes).
6. E.6 `LivePassManager` write methods + emit `StoreChange` after every success; invalidate scanner cache. Tests: `LivePassManagerWriteTests`.
7. E.7 `FakePasswordGenerator` already in place (D.4); confirm it's used as the test seam wherever needed.
8. E.8 Opt-in E2E suite `PassWriteIntegrationTests` (gated `KIZBA_E2E=1`): temp `GNUPGHOME` + ephemeral GPG key + `pass init`; full insert→show→edit→move→remove cycle.

DoD for Phase E: all write CLI paths covered with exact argv + stdin; `LivePassManager` emits `StoreChange` and invalidates cache on every success; stdin grep ban remains green; opt-in E2E green locally; full suite green; UI not yet touched.

## Verification commands

```sh
# Full suite (must stay green throughout MVP 2)
xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS'

# Release sanity (every phase)
xcodebuild -scheme Kizba -project Kizba.xcodeproj -configuration Release -destination 'platform=macOS' build

# Phase C grep bans (must stay green)
xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' \
  -only-testing:KizbaTests/SourceGrepTests

# Phase A acceptance (must stay clean)
rg -n 'as!' Kizba/Infrastructure/Settings
rg -n 'showSettingsWindow' Kizba
find . -name .DS_Store -not -path '*/.git/*'

# Phase C+D repo-wide hygiene
rg -n '\bas!\b' Kizba
rg -n 'Logger.*stdin|print\(.*stdin' Kizba

# Phase D Domain-only imports
rg -n '^import' Kizba/Domain/Models/*.swift Kizba/Domain/Protocols/*.swift
```

## Open follow-ups (non-blocking)

- Untracked `.ai/context.md`, `.ai/decisions.md`, `.ai/handoff.md`, `.ai/step.md` — should be `git add`ed when committing.
- `KizbaTests/Fixtures/FakeClipboard.swift` carries two types (`FakePasteboardAdapter` + `FakeClipboardServicing`); consider splitting later.
- `MetadataPair.String(describing:)` includes the value (because we don't conform to `CustomStringConvertible`, default reflection prints stored properties). Risk: a debugger `po pair` leaks values. Acceptable for now — secrets only live transiently inside `SecretDraft` which is reference-typed and prints only its type name.
- Notes-look-like-metadata round-trip is a documented `XCTSkip`; Phase F's `MetadataValidator` should surface a non-blocking warning to the user.
- Toast value type currently lives in `ToastOverlay.swift`; Phase F.1 will move it to its own file in `Kizba/Presentation/Toast/`.
- Settings UI is ScrollView-based (denser than native macOS Form); user feedback may prompt revisiting in Phase I.

## Constraints (must hold throughout MVP 2)

- Zero third-party Swift Packages.
- No QtPass / GPL pass-client source consulted.
- No secret content in logs (stdin / stdout / clipboard value / metadata values / notes).
- `PassSecret`, `MetadataPair`, `SecretDraft` not Codable, not CustomStringConvertible/DebugStringConvertible.
- All chat with user in Russian; all code/comments/docs/commits in English.
- Inline styling banned in `Kizba/Presentation/**` outside `DesignSystem/` (Phase C.6 grep tests enforce).
- Repo-wide `as!` and `Logger/print`-stdin banned (Phase C.6 grep tests enforce).
