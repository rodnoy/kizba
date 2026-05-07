# Kizba — MVP 1 Implementation Plan

Native macOS SwiftUI GUI for the Unix `pass` password manager. Read-only first.

## Goal & Non-goals

**Goal (MVP 1)**
- Native macOS SwiftUI read-only client for `pass`.
- Three-column UI (folder sidebar / entry list / detail) with lazy decrypt via `pass show`.
- Per-field copy with token-checked auto-clear (default 30s).
- Settings + Diagnostics for missing `pass` / `gpg` / `pinentry-mac` and non-default store path.
- Strict concurrency, zero third-party deps, no secrets in logs/state beyond active detail view.

**Non-goals (MVP 1)**
- Writes (`insert`/`generate`/`edit`/`rm`/`mv`), `pass git ...`, menu-bar, global hotkey, quick-search panel.
- Touch ID/Keychain, TOTP, FSEvents auto-refresh, multi-store.
- App Sandbox, i18n beyond English, UI/snapshot tests.

## Baseline

- Swift 5.10, Xcode 15.4+, macOS deployment target 14.0.
- `SWIFT_STRICT_CONCURRENCY=complete` from day one.
- `.xcodeproj` committed (not SwiftPM-only).
- Zero third-party dependencies.
- Non-sandboxed for MVP 1 (Developer ID + notarization).

## Folder layout

```
Kizba/
├── Kizba.xcodeproj/
├── Kizba/
│   ├── App/                 KizbaApp.swift, AppEnvironment.swift, AppState.swift
│   ├── Domain/
│   │   ├── Models/          PassEntry, PassSecret, PassMetadata, PassError
│   │   └── Protocols/       PassManaging, ShellCommandRunning, ClipboardServicing, BinaryLocating, SettingsStoring
│   ├── Infrastructure/
│   │   ├── Shell/           ProcessShellRunner, ShellResult
│   │   ├── Pass/            PassCLI, PassShowParser, PassErrorMapper, MockPassManager (DEBUG)
│   │   ├── Store/           PasswordStoreScanner, EntryPathConverter
│   │   ├── Clipboard/       ClipboardService
│   │   ├── Discovery/       BinaryDiscoveryService
│   │   ├── Settings/        UserDefaultsSettingsStore
│   │   └── Logging/         Log.swift
│   ├── Presentation/
│   │   ├── Root/            RootSplitView
│   │   ├── Features/        Sidebar, EntryList, EntryDetail, Search, Settings, Diagnostics
│   │   └── DesignSystem/    Theme + Components
│   └── Resources/           Assets.xcassets, Localizable.strings (en)
└── KizbaTests/              Domain/, Infrastructure/, Presentation/, Support/, Fixtures/
```

## Phases

Each step is sized for a single focused implementation session. Verification commands assume macOS host with Xcode 15.4+.

### Phase 0 — Repo & project skeleton
- [ ] 0.1 Create `Kizba.xcodeproj` (Swift 5.10, macOS 14, strict concurrency complete, warnings-as-errors). Files: `Kizba.xcodeproj/`, `Kizba/App/KizbaApp.swift` (empty `WindowGroup { Text("Kizba") }`), `Kizba/Resources/Assets.xcassets/`, `KizbaTests/KizbaTests.swift`. Verify: `xcodebuild -scheme Kizba -destination 'platform=macOS' build` and `xcodebuild test -scheme Kizba -destination 'platform=macOS'`.
- [ ] 0.2 Add `.gitignore` (Xcode + DerivedData + xcuserdata), `README.md` stub.
- [ ] 0.3 Folder scaffolding (empty groups with `.keep` files) matching layout above. Verify: build still succeeds.

**DoD:** `xcodebuild build` and `xcodebuild test` pass; empty window launches; folders match architecture.

### Phase 1 — Domain types & protocols
- [ ] 1.1 Value types: `PassEntry`, `PassMetadata`, `PassSecret`, `PassError`. PassSecret is Sendable, NOT Codable, NOT CustomStringConvertible.
- [ ] 1.2 Protocols (MVP 1 surface only): `PassManaging` (`listEntries`, `show`, `storeLocation`), `ShellCommandRunning`, `ClipboardServicing`, `BinaryLocating`, `SettingsStoring`.
- [ ] 1.3 Domain unit tests: `PassEntryTests`, `PassMetadataTests`, `PassSecretSecurityTests`. Verify: `xcodebuild test -only-testing:KizbaTests/Domain`.

**DoD:** Domain compiles; domain tests green.

### Phase 2 — Mock `PassManaging` + vertical UI slice
- [ ] 2.1 `MockPassManager` with ~20 fixture entries across 3 folders (one with metadata + notes, one password-only).
- [ ] 2.2 `AppEnvironment` (`live()` and `preview()` factories) and `AppState` (`@Observable`, `@MainActor`).
- [ ] 2.3 `RootSplitView` + `SidebarView`/`SidebarModel`. Sidebar derives folders from `pass.listEntries()`.
- [ ] 2.4 `EntryListView`/`EntryListModel` with `.searchable` (⌘F focus, substring case-insensitive over full path).
- [ ] 2.5 `EntryDetailView`/`EntryDetailModel` with states `idle | loading | loaded(PassSecret) | failed(PassError)`. Cancel previous task on selection change. Copy buttons stubbed (placeholder logging).
- [ ] 2.6 `EntryDetailModelTests` — selection-change cancellation + final-state correctness.

**DoD:** App launches, three columns, mock data navigable; ⌘F filters; cancellation test green.

### Phase 3 — Real `ShellCommandRunning`
- [ ] 3.1 `ProcessShellRunner` — concurrent stdout/stderr drain via Pipe handlers; timeout via `Task.sleep` race + `terminate()`; cancellation via `withTaskCancellationHandler`. Logs only executable + arg shape + exit code + stderr length. Never logs stdout.
- [ ] 3.2 `Log.swift` — `os.Logger` wrappers; subsystem `app.kizba`; categories `shell`, `pass`, `clipboard`, `discovery`, `ui`. Paths/stderr always `.private`.
- [ ] 3.3 `ProcessShellRunnerTests` — echo success; non-zero exit; timeout on `/bin/sleep`; cancellation propagation; large stdout drain.
- [ ] 3.4 `SourceGrepTests` — assert no stdout-logging in `Shell/` and `Pass/`; no raw `print` in those dirs.

**DoD:** Real shell verified; cancellation/timeout proven; static log discipline test in place.

### Phase 4 — Real `PassCLI` + parser + error mapper
- [ ] 4.1 `PassShowParser` (pure). Line 1 = password (only trim trailing `\n`). Lines matching `^[A-Za-z0-9_.-]+:\s*` = metadata (preserve order, allow dups). First non-matching line + remainder = notes. Empty → `parsingFailed`.
- [ ] 4.2 `PassShowParserTests` — password-only; with metadata; with notes; duplicate keys; colon-in-value (`url: https://x.test:8443/path`); notes containing key:-like lines; empty throws.
- [ ] 4.3 `PassErrorMapper` — map known stderr signatures to `PassError`; sanitizer strips emails (`\S+@\S+`), hex IDs (`[A-F0-9]{8,}`), caps excerpt length.
- [ ] 4.4 `PassErrorMapperTests` — every signature; sanitizer cases; idempotent.
- [ ] 4.5 `PassCLI` — composes `pass show <entry>` with 120s timeout; builds env (PATH prepend, optional `PASSWORD_STORE_DIR`/`GNUPGHOME`); maps errors.
- [ ] 4.6 `FakeShellRunner` + `PassCLITests` — success, decryption failure, timeout, cancellation, arg/env composition.

**DoD:** `PassCLI` covered against fake shell; parser/mapper exhaustive.

### Phase 5 — `BinaryDiscoveryService` + wire real `PassCLI`
- [ ] 5.1 `BinaryDiscoveryService` — order: override → `/opt/homebrew/bin` → `/usr/local/bin` → `/usr/bin` → sanitized PATH walk. Cached; `reDetect()` invalidates.
- [ ] 5.2 `FakeFileExistenceChecker` + `BinaryDiscoveryServiceTests` — override wins; arm64 Homebrew first; fallback order; sanitized PATH; cache; re-detect.
- [ ] 5.3 Wire `PassCLI` into `AppEnvironment.live()`. Manual: real decrypt on a host with `pass` + `pinentry-mac`.

**DoD:** Real decrypt works end-to-end.

### Phase 6 — `PasswordStoreScanner` + `EntryPathConverter`
- [x] 6.1 `EntryPathConverter` — pure URL → entry path string.
- [x] 6.2 `EntryPathConverterTests` — nested, top-level, non-gpg, outside root, Unicode, spaces.
- [x] 6.3 `PasswordStoreScanner` — `FileManager.enumerator` with `[.skipsHiddenFiles]`; ignores `.git`, `.gpg-id`; only `.gpg`; sorted result.
- [x] 6.4 `TempStoreFixture` + `PasswordStoreScannerTests` — nested with `.git` ignored; `.gpg-id` ignored; non-gpg ignored; empty store; missing root throws; deterministic sort.
- [x] 6.5 Wire scanner into `PassCLI.listEntries`; ⌘R refresh action in toolbar.

**DoD:** Real list + real decrypt; ⌘R refreshes.

### Phase 7 — Clipboard service
- [ ] 7.1 `ClipboardService` — write verbatim; capture token + `changeCount`; clear after delay only if both still match.
- [ ] 7.2 `FakeClipboard` + `ClipboardServiceTests` — clears on changeCount match; no clear on diverge; no clear on token supersede; verbatim write (no `"key: value"`); concurrent copy convergence.
- [ ] 7.3 Wire Copy buttons in `EntryDetailView` to `env.clipboard.copy(field, clearAfter:)`.

**DoD:** Clipboard auto-clear works; verbatim write enforced.

### Phase 8 — Settings + Diagnostics
- [ ] 8.1 `UserDefaultsSettingsStore` — namespaced keys (`app.kizba.settings.*`); allow-list types `String, URL, Int, Double, Bool`; settings: `storePathOverride`, `passBinaryOverride`, `gpgBinaryOverride`, `pinentryBinaryOverride`, `clipboardClearDelaySeconds` (default 30).
- [ ] 8.2 `UserDefaultsSettingsStoreTests` — round-trip per type; defaults; clearing; namespacing isolation.
- [ ] 8.3 `SettingsView`/`SettingsModel` — wired into `Settings { ... }` scene; pickers for paths; clipboard delay stepper; "Re-detect binaries" button.
- [ ] 8.4 `DiagnosticsView`/`DiagnosticsModel` + `InvocationLog` (in-memory ring buffer of last N invocations: executable, sanitized args, exitCode, sanitized stderr — never stdout). Hook `ProcessShellRunner` to publish via injected sink.
- [ ] 8.5 Wire all `PassError` cases to UI per architecture mapping (binaryNotFound → empty state + Settings nudge; pinentryNotConfigured → banner + help link; decryptionFailed → inline + "View details" → Diagnostics; storeNotFound → onboarding; timedOut/shellFailure → toast + Diagnostics; cancelled → silent).

**DoD:** All error states have UI surface; Diagnostics shows sanitized log; Settings persists.

### Phase 9 — Polish, security audit, release hygiene
- [ ] 9.1 Gate `MockPassManager` behind `#if DEBUG`; release binary contains no fixture passwords (`strings` grep test).
- [ ] 9.2 `SecurityChecklistTests` — no `print(` in `Kizba/`; no Codable on `PassSecret`; no CustomStringConvertible on `PassSecret`; no `"\(key): \(value)"` in `Clipboard/`; SettingsStoring allow-list enforced.
- [ ] 9.3 `Kizba.entitlements` — Hardened Runtime; document `cs.disable-library-validation` if needed for pinentry. Document local sign + notarize commands in README.
- [ ] 9.4 Final manual QA pass against verification matrix.

**DoD:** Security checklist green; release build excludes mock data; signed local build runs; verification matrix passes.

## Cross-cutting workstreams

- **Logging discipline:** only sanctioned `Log.swift` helpers; grep tests enforce no stdout-logging in `Shell/`/`Pass/` and no raw `print`.
- **Error fixture corpus:** `KizbaTests/Fixtures/stderr/*.txt` — real-world sanitized samples; `PassErrorMapperTests` iterates.
- **Security checklist:** codified in `SecurityChecklistTests`; any failure is a release blocker.
- **CI prep:** `scripts/test.sh` wrapping `xcodebuild test ...` by Phase 3; actual GitHub Actions workflow deferred.
- **Concurrency hygiene:** strict-concurrency complete from Phase 0; warnings as errors.
- **Docs:** each phase appends to `README.md`; each public protocol gets `///` doc comment with threading contract.

## Verification matrix

Manual scenarios (host with `pass` + `pinentry-mac` + real `~/.password-store`):
1. Cold launch — three columns, sidebar populated.
2. ⌘F filter narrows list; clear restores.
3. Select entry — loading → masked password + metadata + notes.
4. Reveal/hide password.
5. Copy password; paste in another app; wait 30s → clipboard empty.
6. Copy field A then B before 30s — only B's clear is active.
7. Copy field, then copy externally — external value preserved past delay.
8. ⌘R refreshes after adding new `.gpg` via terminal.
9. With `pass` not in PATH — empty state with Settings nudge.
10. Change store path in Settings to empty dir → list empties; revert → list returns.
11. Decrypt failure → inline error → "View details" → Diagnostics shows sanitized record (no stdout, no email/key id).
12. Cancel slow decrypt by switching selection → silent.
13. Quit & relaunch → settings persisted.

Automated targets:
- All test files green via `xcodebuild test -scheme Kizba -destination 'platform=macOS'`.
- `SourceGrepTests` + `SecurityChecklistTests` zero exceptions.
- `xcodebuild -configuration Release build` succeeds; release binary contains no fixture strings.

## Sequencing dependencies

- Domain (P1) precedes everything.
- `MockPassManager` (P2) unblocks UI vertical slice.
- `ShellCommandRunning` (P3) precedes `PassCLI` (P4); `Log.swift` precedes first logging.
- `FakeShellRunner` precedes `PassCLITests`.
- `BinaryDiscoveryService` (P5) precedes wiring real `PassCLI` into `live()`.
- `EntryPathConverter` precedes `PasswordStoreScanner`.
- `TempStoreFixture` precedes scanner + opt-in E2E tests.
- `FakeClipboard` precedes clipboard tests; clipboard precedes Copy button wiring.
- `UserDefaultsSettingsStore` precedes Settings UI; discovery before Settings is acceptable (no override = nil).
- Static grep tests need stable source path convention — pick in P0 (env var or relative path from test bundle).
- Strict concurrency from P0 — adding later forces churn.

## Out of scope (do NOT implement in MVP 1)

- Writes (`pass insert`/`generate`/`edit`/`rm`/`mv`).
- `pass git ...` integration.
- Menu bar, global hotkey, quick-search panel.
- Touch ID, Keychain, passphrase caching.
- FSEvents auto-refresh.
- TOTP/OTP rendering.
- Multi-store, sub-store, per-dir `.gpg-id`, pass extensions.
- i18n beyond English.
- App Sandbox.
- UI/snapshot tests.
- Any third-party Swift package.
- Reading QtPass or any GPL pass-client source while implementing.
