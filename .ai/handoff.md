# Kizba — Handoff

## Last completed action

Step **1.2 — DONE** (Domain protocols).

Created the five MVP-1 read-only / collaborator protocols under
`Kizba/Domain/Protocols/`. Per `.ai/decisions.md`, `PassManaging`
exposes only `listEntries()` / `show(_:)` / `storeLocation()` — no
write or git surface is declared yet.

- `PassManaging.swift` — read-only domain surface (`async` list/show,
  sync `storeLocation()`). Threading contract documented; cancellation
  via cooperative `Task` cancellation; errors via `PassError`.
- `ShellCommandRunning.swift` — abstraction over `Foundation.Process`
  with explicit `executable: URL`, `arguments`, `environment`,
  `timeout: Duration`. Returns a new `ShellResult` value type
  (`exitCode`, `standardOutput: Data`, `standardError: Data`).
- `ClipboardServicing.swift` — verbatim `copy(_:clearAfter:)` async
  surface. Documents the verbatim / token-checked auto-clear
  invariants.
- `BinaryLocating.swift` — `locate(_:)` / `reDetect()` over a new
  `BinaryName` enum (`.pass`, `.gpg`, `.pinentryMac`). Documents the
  override → Homebrew(arm64) → Homebrew(x86) → /usr/bin → sanitised
  PATH order.
- `SettingsStoring.swift` — type-safe `SettingsKey<Value>` over an
  allow-listed `SettingsValue` marker (`String`, `URL`, `Int`,
  `Double`, `Bool`).

### Applied changes

- `Kizba/Domain/Protocols/PassManaging.swift` (new).
- `Kizba/Domain/Protocols/ShellCommandRunning.swift` (new).
- `Kizba/Domain/Protocols/ClipboardServicing.swift` (new).
- `Kizba/Domain/Protocols/BinaryLocating.swift` (new).
- `Kizba/Domain/Protocols/SettingsStoring.swift` (new).
- `Kizba/Domain/Protocols/.keep` deleted.
- `Kizba.xcodeproj/project.pbxproj`: dropped the `Domain/Protocols/.keep`
  entry from the `Kizba` target's
  `PBXFileSystemSynchronizedBuildFileExceptionSet`. No other pbxproj
  edits needed — file-system-synchronized root group picks up the new
  sources automatically.
- `KizbaTests/DomainProtocolsTests.swift` (new) — 14 tests across 5
  suites (`PassManagingTests`, `ShellCommandRunningTests`,
  `ClipboardServicingTests`, `BinaryLocatingTests`,
  `SettingsStoringTests`) using minimal in-test doubles
  (`StubPassManager` actor, `RecordingShellRunner`, `FakeClipboard`,
  `StubBinaryLocator` actor, `InMemorySettingsStore`).

### Verification (executed on this host)

```
xcodebuild -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' build
# => ** BUILD SUCCEEDED **

xcodebuild -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' test
# => ** TEST SUCCEEDED **
#    28 tests passed (14 from step 1.1 + 14 new for step 1.2).
```

Build log: `.ai/build-log.md`.

### Commits

- `51f5e71` — `feat(domain): add domain protocols (PassManaging, ShellCommandRunning, ClipboardServicing, BinaryLocating, SettingsStoring)`
- `d08cda9` — `test(domain): add unit tests for domain protocols`

### Repo state at completion

- HEAD: `d08cda9` (will advance after this handoff/log commit).
- `xcodeproj_created = true`,
  `xcode_instructions_path = .ai/xcode_instructions.md` (no new UI
  steps required this round — file-system-synchronized group handled
  the additions automatically).

## Next action

Proceed to **step 1.3** (Phase 1 — Domain unit tests round-out):

- Add any missing fixture coverage targeted by the plan
  (`PassEntryTests`, `PassMetadataTests`, `PassSecretSecurityTests`).
- Selection-cancellation fixtures land later in Phase 2 (P2).
- Verify: `xcodebuild test -only-testing:KizbaTests/Domain ...`.

After 1.3: Phase 2 — Mock `PassManaging` + vertical UI slice.

## Constraints (must hold from day one)

- No third-party packages.
- No QtPass / GPL pass-client source consulted during implementation.
- No secrets in logs (no stdout logging in `Shell/`/`Pass/`).
- `PassSecret` not Codable, not CustomStringConvertible.
- `PassManaging` MVP-1 surface stays read-only — no write/git methods.
- All chat with user in Russian; all code/comments/docs/commits in English.

## Machine-readable summary

See `.ai/last-run.json`.
