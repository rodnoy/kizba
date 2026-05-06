# Kizba — Technical Decisions

Append-only log of durable design decisions. Each entry: date, decision, rationale.

## 2026-05-06

- **Project name: Kizba.** Replaces the brief's working name "Passage". Root folder is `Kizba/`.
- **Layered architecture: Presentation → Domain → Infrastructure**, one-way dependencies. All protocols live in `Domain/Protocols/`; implementations in `Infrastructure/`.
- **Swift 5.10, macOS deployment target 14.0.** Required for `@Observable` macro, mature `NavigationSplitView`, `Duration`/`ContinuousClock`, `Logger` privacy markers. macOS 13 support not pursued — audience is technical and overwhelmingly current.
- **Strict concurrency = complete from day one.** Cheaper to enforce now than to retrofit. Warnings treated as errors for the app target.
- **State management: `@Observable` (Observation framework), not `ObservableObject`.** Per-property change tracking, no `@Published` boilerplate, plain initializer injection.
- **Manual DI via initializers.** No third-party DI framework. `EnvironmentObject` reserved for theme/locale, never for domain services.
- **`.xcodeproj` committed, not SwiftPM-only.** Smoother Settings scene, code signing, entitlements, notarization, SwiftUI previews on macOS today. Local SwiftPM module split deferred until module boundaries warrant it.
- **Zero third-party dependencies for MVP 1.** Foundation / AppKit / SwiftUI / os.log only. Minimizes security surface and supply chain.
- **Listing via `PasswordStoreScanner`, not `pass ls`.** Filesystem traversal is more reliable, parseable, and faster than parsing `pass ls` tree output.
- **`pass show` timeout = 120s with visible Cancel.** Pinentry can take arbitrary user time; default 20s is too aggressive.
- **`PassSecret` is NOT `Codable`, NOT `CustomStringConvertible`, NOT `CustomDebugStringConvertible`.** Enforced by unit test. Prevents accidental serialization or string-interpolation leaks.
- **`PassSecret` lives only in the active `EntryDetailModel`, never in `AppState`.** Released on selection change.
- **No stdout logging in `Infrastructure/Shell/` or `Infrastructure/Pass/`.** Enforced by static grep test (`SourceGrepTests`). Stderr only via sanitized excerpts; paths via `.private` Logger markers.
- **Clipboard auto-clear uses generation token + `changeCount` snapshot.** Avoids clobbering user's later clipboard content.
- **`ClipboardService` writes values verbatim.** Never composes `"key: value"` strings — eliminates accidental key-name leakage and cross-field contamination.
- **No GPG passphrase ever read or stored by Kizba.** `pinentry-mac` owns it. App refuses to operate if no pinentry is configured (warning, not crash).
- **Binary discovery resolves absolute paths only.** Order: explicit override → `/opt/homebrew/bin` → `/usr/local/bin` → `/usr/bin` → sanitized hard-coded PATH walk. Inherited launchd PATH is not trusted.
- **Non-sandboxed for MVP 1.** Distributed via Developer ID + notarization, outside the App Store. App Sandbox would require bundling `gpg`/`pass` or shipping a helper tool — out of scope. Hardened Runtime enabled; `cs.disable-library-validation` likely required for pinentry interaction (verify at first notarization).
- **No FSEvents auto-refresh in MVP 1.** ⌘R refresh only.
- **`PassManaging` MVP 1 surface is read-only:** `listEntries()`, `show(_:)`, `storeLocation()`. Write/git methods are explicitly deferred (not declared in the protocol yet) so accidental write paths cannot be wired in early.
- **Single Xcode project, single app target, single XCTest target for MVP 1.** Module split into local SwiftPM packages is a possible follow-up, not a precondition.
- **No QtPass / KeePassXC-pass / any GPL pass-client source consulted during implementation.** Hard rule to avoid GPL contamination.
- **All code, comments, docs, and commit messages in English.** User-facing chat in Russian; UI strings in English (en) only for MVP 1.
