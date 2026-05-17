# Kizba

A native macOS GUI for the Unix [`pass`](https://www.passwordstore.org/) password manager.

> Pastel design. Native SwiftUI. Strict security. Zero third-party dependencies.

## What it does

MVP 2 ships a complete read + write surface over `pass(1)`:

- **Browse** entries in a three-column macOS layout (folder sidebar / entry list / detail).
- **Read** secrets via `pass show` with `pinentry-mac` integration.
- **Copy** any field with token-protected auto-clear (configurable delay, default 30s).
- **Create** new entries (⌘N) with optional generated password preview + re-roll.
- **Edit** existing entries (⌘E) — preserves metadata + notes via decrypt → form → reinsert.
- **Regenerate** passwords in-place (⌘⌥G) using `pass generate --in-place`.
- **Move / rename** entries (⌘⇧M).
- **Delete** entries (⌫) with confirmation dialog + 10-second Undo.
- **Diagnostics** (⌘⌥D) — sanitized invocation log; no secret content ever recorded.

- **FSEvents auto-refresh** — external changes to `~/.password-store` (e.g., from the CLI) are detected automatically via FSEvents; no manual ⌘R needed.
- **Touch ID gate** (opt-in) — require biometric authentication before revealing secrets. Disabled by default; enable in Settings. Requires a Mac with Touch ID or Apple Watch unlock.
- **Global ⌘K search overlay** — live-ranked, in-memory fuzzy search over all entries; Esc dismisses, Enter selects.
- **Favorites** — ⭐ toggle in the `EntryDetail` toolbar (⌘D shortcut); dedicated Favorites section in the sidebar.
- **Recent entries** — automatically recorded when an entry is viewed; dedicated Recents sidebar section (FIFO, capped at 20, newest first).
- **Menu-bar status item** — optional SwiftUI popover for quick search + copy, toggleable in Settings ("Show in menu bar").

### MVP 6 polish

- **Settings re-organised into Xcode-style tabs** — General / Security / Git / Advanced, with a shared footer (Save / Reset) across all tabs.
- **Save feedback** — Save button disabled when there are no changes; transient "Saving…" / "Saved" status flash on save.
- **Info tooltips** — `info.circle` buttons on key Settings controls open focused popovers with guidance (`infoText`).
- **App-wide hover tooltips** — every interactive control in Settings / Sidebar / Menu-bar / Git surfaces shows a `.help(...)` tooltip on hover.
- **Recents controls** — show/hide toggle in Settings; configurable limit (3–7); collapsible (fold/unfold) section in the sidebar with persisted expansion state.
- **Favorites controls** — show/hide toggle in Settings; collapsible (fold/unfold) section in the sidebar, symmetric with Recents.
- **Touch ID adapts to hardware** — toggle hidden on Macs without Touch ID hardware; disabling Touch ID requires a successful biometric prompt.
- **Help setup topics** — guided in-app topics covering pass + GPG install, syncing the store via Git remote, and configuring `pinentry-mac`.

## Git support
- Sidebar badge showing repository status (clean, local changes, ahead/behind, conflict) with an actions popover.
- Pull / Push via the "Git" menu (Refresh Status — ⌘⇧R; Pull; Push). Conflict banner shows merge conflicts and a quick "Open Terminal at Store" action.
- Settings: "Git operation timeout" stepper (10–300 seconds, default 60) controls network operation timeout.
- Opt-in integration tests: run `KIZBA_E2E=1 KIZBA_GIT_E2E=1 xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' -only-testing:KizbaTests/PassGitIntegrationTests`

## Visual identity

Five-color pastel palette (Pink Orchid · Pastel Petal · Blush Pop · Icy Blue · Sky Blue) used as
surfaces and accents. Body text uses a deep indigo for AAA contrast against pastel surfaces.
Light + Dark + High-Contrast variants. A two-tone focus ring satisfies AA against any backdrop.
Every semantic state pairs color with a fixed SF Symbol icon (color-blind safe).

## Requirements

- macOS 14.0 (Sonoma) or newer.
- Xcode 15.4 or newer (Swift 5.10, strict concurrency = complete).
- [`pass`](https://www.passwordstore.org/) **1.7.3** or newer (`brew install pass`).
- [GnuPG](https://gnupg.org/) (`brew install gnupg`).
- [`pinentry-mac`](https://github.com/GPGTools/pinentry-mac) (`brew install pinentry-mac`).
- A configured `~/.password-store` (or set a custom path in Settings).
- For `pinentry-mac` to be picked up, `~/.gnupg/gpg-agent.conf` should contain
  `pinentry-program /opt/homebrew/bin/pinentry-mac` (Apple Silicon) or
  `/usr/local/bin/pinentry-mac` (Intel).

## Build

```sh
xcodebuild -scheme Kizba -project Kizba.xcodeproj \
  -destination 'platform=macOS' build
```

For a release build:

```sh
xcodebuild -scheme Kizba -project Kizba.xcodeproj \
  -configuration Release -destination 'platform=macOS' build
```

The app uses Hardened Runtime + the `com.apple.security.cs.disable-library-validation`
entitlement (required so spawned `gpg` / `pinentry-mac` can load Homebrew libraries).
Distribution requires Developer ID signing + notarization (outside the App Store; not sandboxed
in MVP 2).

## Tests

Default suite (no external dependencies; uses fakes / fixtures):

```sh
xcodebuild test -scheme Kizba -project Kizba.xcodeproj \
  -destination 'platform=macOS'
```

Optional end-to-end suite that spins up an ephemeral GPG key + temporary password store:

```sh
TEST_RUNNER_KIZBA_E2E=1 xcodebuild test \
  -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' \
  -only-testing:KizbaTests/PassWriteIntegrationTests
```

The opt-in E2E suite requires `pass` and `gpg` on PATH. It creates a temp directory under
`/tmp/kizba-e2e-<id>/`, generates a passphraseless ECDSA + ECDH key pair (`Expire-Date: 1d`),
runs the full insert → show → edit → move → remove cycle, then cleans up.

Test count at MVP 2 release: **681** total; 8 skipped without `KIZBA_E2E` (1 documented
notes-look-like-metadata limitation + 7 PassWriteIntegrationTests); 0 failures. With
`TEST_RUNNER_KIZBA_E2E=1` the 7 E2E tests also run.

## Security model

What Kizba **does**:

- Calls the existing `pass(1)` binary as a subprocess; never re-implements GPG.
- Lets `gpg-agent` + `pinentry-mac` own all passphrase handling.
- Never writes any secret material to logs (`stdout` of `pass show` and `pass generate`, and
  the `stdin` of `pass insert`, are explicitly redacted; only `stdinByteCount` is recorded).
- Sanitizes any stderr surfaced in Diagnostics (emails and hex key IDs scrubbed).
- Auto-clears the clipboard after a configurable delay (default 30s), with a generation token
  + `NSPasteboard.changeCount` snapshot so a user-initiated copy isn't overwritten.
- Holds decrypted secrets only inside the in-flight detail / form models; releases on
  selection change or sheet dismissal.
- Uses a custom in-session 10-second `ActionHistory` for Undo on destructive operations;
  cleared on app quit.
- Resolves binary paths from an allow-list (`/opt/homebrew/bin`, `/usr/local/bin`, `/usr/bin`,
  sanitized PATH walk); inherited launchd PATH is not trusted.

What Kizba **does not**:

- Implement its own crypto.
- Cache decrypted secrets to disk or `UserDefaults`.
- Sync, back up, or transmit `~/.password-store` content anywhere.
- Embed any third-party Swift package (Foundation / SwiftUI / AppKit / `os` only).
- Support cloud accounts, browsers, or auto-fill.

## Known limitations

- **In-memory secrets are plain `String` / `Data`.** No `mlock`-based scrubbing buffer; secret
  values may persist in process memory until ARC reclaims them. A `ScrubbingString` wrapper is
  documented as a deferred MVP 3 candidate.
- **No FSEvents auto-refresh.** External writes to `~/.password-store` (e.g., from the CLI in
  another terminal) require a manual ⌘R to reflect.

Note: Both Touch ID per-reveal toggle and FSEvents auto-refresh are opt-in and testable via environment variables: `KIZBA_E2E` and `KIZBA_FSEVENTS_TEST`.
- **`pass insert` over piped stdin always overwrites silently** (`pass`'s `yesno()` returns 0
  when stdin is not a TTY). Kizba enforces collision-confirmation in the UI before passing
  `force: true`; the contract is verified at the unit-test level via stderr fixture mappings
  for `pass` 1.7.3 and 1.7.4.
- **Notes that begin with a `^[A-Za-z0-9_.-]+:\s` line cannot round-trip.** This is an inherent
  ambiguity of the informal `pass` body format — leading "key: value"-style lines in notes get
  parsed back as metadata. Documented and surfaced as a non-blocking warning by the
  form-time `MetadataValidator`.
- **Single store only.** Sub-stores via `PASSWORD_STORE_SUBDIR`, per-folder `.gpg-id`, and
  `pass` extensions are not specially supported (most still work transparently because we
  shell out to `pass`).
- **Not sandboxed.** Distributed via Developer ID + notarization, outside the App Store.

## What's deferred

- `pass git` integration (status, push, pull, conflicts). — Shipped in MVP 3.
- System `UndoManager` integration (current `ActionHistory` is in-session only).
- Touch ID / `LocalAuthentication` for unlock-before-reveal. — Shipped in MVP 3.
- FSEvents-based external-change detection. — Shipped in MVP 3.
- Menu-bar (status item) app surface. — Shipped in MVP 5.
- Quick-search overlay (⌘K). — Shipped in MVP 5.
- **Global hotkey for menu-bar popover** (e.g. system-wide ⌥Space). Deferred:
  `NSEvent.addGlobalMonitorForEvents` requires Accessibility permission and the
  prompt UX is intrusive; will revisit when there is concrete user demand.
- **Help menu deep-links** — opening a specific Help topic from the menu bar
  (e.g. Help → "Configure pinentry-mac"). Plumbing not in place; topics remain
  reachable via the Help app's sidebar.
- Spotlight indexing / external index file.
- App Sandbox + helper tool for sandboxed `Process` spawn.
- Snapshot tests.
- `ScrubbingString` secure-string buffer.

## Project structure

```
Kizba/
├── App/                         KizbaApp, AppEnvironment, AppState
├── Domain/
│   ├── Models/                  PassEntry, PassSecret, PassMetadata, PassError,
│   │                            MetadataPair, SecretDraft, StoreChange, UndoableAction, …
│   └── Protocols/               PassManaging, ShellCommandRunning + ShellInvocation,
│                                ClipboardServicing, BinaryLocating, SettingsStoring,
│                                PasswordGenerating
├── Infrastructure/
│   ├── Pass/                    PassCLI (+Write), PassErrorMapper, PassSecretSerializer,
│   │                            PassShowParser, PassGenerateParser, LivePassCLI,
│   │                            LivePassManager, LivePasswordGenerator,
│   │                            MockPassManager (DEBUG)
│   ├── Shell/                   ProcessShellRunner
│   ├── Store/                   PasswordStoreScanner, EntryPathConverter
│   ├── Clipboard/               ClipboardService
│   ├── Discovery/               BinaryDiscoveryService
│   ├── Settings/                UserDefaultsSettingsStore
│   ├── Diagnostics/             Invocation, InvocationLog
│   └── Logging/                 Log
└── Presentation/
    ├── Root/                    RootSplitView
    ├── DesignSystem/            Theme/, Components/, Modifiers/
    ├── Toast/                   Toast, ToastCenter
    ├── Undo/                    ActionHistory
    └── Features/                Sidebar/, EntryList/, EntryDetail/, EntryForm/,
                                 EntryMove/, Settings/, Diagnostics/
```

## Documentation

- [`.ai/plan.md`](.ai/plan.md) — implementation plan with all phases.
- [`.ai/decisions.md`](.ai/decisions.md) — durable architectural decisions (append-only).
- [`.ai/handoff.md`](.ai/handoff.md) — current state of the project.
- [`.ai/a11y-audit.md`](.ai/a11y-audit.md) — accessibility audit + manual checklist.
- [`.ai/sequoia-smoke.md`](.ai/sequoia-smoke.md) — macOS Sequoia smoke test checklist.
- [`.ai/xcode_instructions.md`](.ai/xcode_instructions.md) — manual Xcode project recreation
  steps + notarization workflow.

## License

TBD.
