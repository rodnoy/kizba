# Kizba — Technical Decisions

Append-only log of durable design decisions. Each entry: date, decision, rationale.

## 2026-05-06 — MVP 1

- **Project name: Kizba.** Replaces the brief's working name "Passage". Root folder is `Kizba/`.
- **Layered architecture: Presentation → Domain → Infrastructure**, one-way dependencies. All protocols live in `Domain/Protocols/`; implementations in `Infrastructure/`.
- **Swift 5.10, macOS deployment target 14.0.** Required for `@Observable` macro, mature `NavigationSplitView`, `Duration`/`ContinuousClock`, `Logger` privacy markers. macOS 13 support not pursued.
- **Strict concurrency = complete from day one.** Cheaper to enforce now than retrofit. Warnings treated as errors for the app target.
- **State management: `@Observable` (Observation framework), not `ObservableObject`.** Per-property change tracking; no `@Published` boilerplate; plain initializer injection.
- **Manual DI via initializers.** No third-party DI framework. `EnvironmentObject` reserved for theme/locale, never for domain services.
- **`.xcodeproj` committed, not SwiftPM-only.** Smoother Settings scene, signing, entitlements, notarization, SwiftUI previews on macOS today.
- **Zero third-party dependencies.** Foundation / AppKit / SwiftUI / os.log only.
- **Listing via `PasswordStoreScanner`, not `pass ls`.** Filesystem traversal is more reliable, parseable, faster.
- **`pass show` timeout = 120s with visible Cancel.** Pinentry can take arbitrary user time.
- **`PassSecret` is NOT `Codable`, NOT `CustomStringConvertible`, NOT `CustomDebugStringConvertible`.** Enforced by `SourceGrepTests`.
- **`PassSecret` lives only in the active `EntryDetailModel`, never in `AppState`.** Released on selection change.
- **No stdout logging in `Infrastructure/Shell/` or `Infrastructure/Pass/`.** Enforced by `SourceGrepTests`. Stderr only via sanitized excerpts; paths via `.private` Logger markers.
- **Clipboard auto-clear uses generation token + `changeCount` snapshot.**
- **`ClipboardService` writes values verbatim.** Never composes `"key: value"` strings.
- **No GPG passphrase ever read or stored by Kizba.** `pinentry-mac` owns it.
- **Binary discovery resolves absolute paths only.** Order: explicit override → `/opt/homebrew/bin` → `/usr/local/bin` → `/usr/bin` → sanitized hard-coded PATH walk. Inherited launchd PATH not trusted.
- **Non-sandboxed for MVP 1.** Developer ID + notarization, outside the App Store. Hardened Runtime enabled; `cs.disable-library-validation` for pinentry interaction.
- **No FSEvents auto-refresh.** ⌘R refresh only.
- **`PassManaging` MVP 1 surface is read-only:** `listEntries()`, `show(_:)`, `storeLocation()`. Write/git methods explicitly deferred.
- **Single Xcode project, single app target, single XCTest target.** Module split into local SwiftPM packages is a possible follow-up.
- **No QtPass / KeePassXC-pass / any GPL pass-client source consulted.** Hard rule to avoid GPL contamination.
- **All code, comments, docs, and commit messages in English.** User-facing chat in Russian; UI strings in English (en) only for MVP 1.

## 2026-05-08 — MVP 2

### Scope & strategy
- **Edit strategy: decrypt-edit-reinsert via `pass insert -m -f`.** `pass edit` (which spawns `$EDITOR`) is a poor fit for a GUI: no terminal surface, secret hits disk, depends on shell env we don't control. Decrypt → edit in our form → reinsert keeps the secret in our process memory only and gives us cancellation control.
- **`pass git ...` integration deferred to MVP 3.** Write ops are already a large attack/UX surface; conflating with VCS workflows (push, pull, conflicts, remote auth) explodes scope.
- **Always use `pass insert -m`, never the two-prompt interactive form.** Single read-until-EOF unifies the write path and the multiline format.
- **No separate `edit` method on `PassManaging`.** Edit is composed in `EntryFormModel` as `show + insert(force: true)`. Keeps protocol minimal and matches the actual `pass` verb surface.
- **Min supported `pass` version: 1.7.3.** Documented in README; stderr fixtures shipped for 1.7.3 and 1.7.4.

### Design system
- **Theme = code constants, not asset catalog.** Code branching is already needed for `Theme` snapshots (light/dark/highContrast); asset catalog buys nothing and costs testability.
- **Token model = single `Theme` value type with nested namespaces** (`Colors`, `Spacing`, `Radius`, `Typography`, `Motion`); injected via `EnvironmentValues.theme` (the only sanctioned environment use beyond locale).
- **Brand pastels (`#cdb4db / #ffc8dd / #ffafcc / #bde0fe / #a2d2ff`) used as surfaces + accents only; body text uses deep indigo `onSurface` (`#1F1B2E` light, `#F4EFF7` dark).** Pure pastels fail body-text contrast.
- **`danger`, `success`, `warning` use deepened or extended hues for contrast** (`#C2185B`, `#2E7D5B`, `#9A5A00` light; `#ffafcc`, `#7CD9A8`, `#FFB870` dark). Color-blind safety: every semantic state pairs color with a fixed SF Symbol icon (`exclamationmark.triangle`, `info.circle`, `checkmark.circle`, `xmark.octagon`); no state communicated by color alone.
- **Contrast policy:** body text AA (4.5:1), targeting AAA (7:1); password reveal AAA; focus ring 3:1 minimum (two-tone ring guarantees this regardless of background); honors `Increase Contrast` system setting via a `highContrast` theme variant.
- **Motion tokens collapse to `instant` when `accessibilityReduceMotion`.**
- **Migration to design system happens in one PR before any write feature** (Phase C). Inline-styling bans land at the end of that PR.

### Infrastructure / writes
- **Introduce `ShellInvocation` value type** (`{ executable, arguments, environment, stdin, timeout }`); `ShellCommandRunning.run(_:)` becomes primary; old signature kept as compat extension delegating with `stdin: .none`.
- **Stdin in `ProcessShellRunner`:** assigned `Pipe`; detached `Task` writes Data and closes pipe (EOF); concurrent with stdout/stderr drains; cancellation terminates process; logs only `stdinByteCount`. **No manual `Data` zeroing in MVP 2** (documented limitation; same trust level as `PassSecret.password`).
- **Cache invalidation = `AsyncStream<StoreChange>` from `LivePassManager`.** On every successful write: `scanner.invalidate(...)` + emit `.inserted/.updated/.removed/.moved`. Subscribers: `EntryListModel` (selection rules), `EntryDetailModel` (re-fetch / clear).
- **`StoreChange` is UI-origin neutral.** Disambiguating insert(new) vs insert(edit) is done imperatively from `EntryFormModel` setting `selectedEntryID` after success.

### Generation
- **New entry generation = pure Swift `LivePasswordGenerator`** (`SystemRandomNumberGenerator` = arc4random-backed CSPRNG; charsets match `pass generate` defaults; rejection sampling against modulo bias). Allows preview + re-roll before commit.
- **In-place regenerate = `pass generate --in-place`** (atomic preservation of metadata; no TOCTOU window). The two paths share a consistent UX, backed by different mechanisms.

### UI patterns
- **Two-step destructive confirmation, not "type-to-confirm".** Native macOS pattern; combined with Undo (10s) it's the right friction.
- **`ToastCenter` injected via `AppState`** (not a global singleton). At-most-one visible; new posts dismiss the previous (no stacking — macOS pattern). `accessibilityNotification(.announcement)` on appear.
- **Undo = custom in-session `ActionHistory`, ~10s window via toast.** Covers delete, move, in-place regenerate. System `UndoManager` deferred to MVP 3 (synchronous-undoable model is awkward for our async/failable ops; secret-history audit needs explicit threat model).
- **Concurrent writes prevented in UI:** toolbar buttons disabled while any model is `.saving`. `LivePassManager` does not serialize internally.

### Security
- **`SecretDraft` and `MetadataPair` get the same security non-conformances as `PassSecret`** (not Codable, not CustomStringConvertible, not CustomDebugStringConvertible). Asserted by `SourceGrepTests`.
- **Stdin never logged anywhere** — grep ban `Logger.*stdin` / `print\(.*stdin` repo-wide.
- **`pass generate` stdout (the new password line) is parsed but never logged.** Existing "no stdout logging" rule already prohibits this; reaffirmed.
- **`ToastCenter` toasts never carry secret material** — only entry path. Documented as code-review checkpoint (typed boundary makes accidental misuse hard).
- **`as!` banned in `Sources/`** — `SourceGrepTests` enforces.
- **No `ScrubbingString` in MVP 2.** True scrubbing requires `mlock` + non-pageable memory + intercepting Swift's copy-on-write; not justified at current trust level. Documented limitation; revisit when adopting a dedicated secret-string library or buffer-based input.

### Tech debt
- **All 10 MVP 1 tech-debt items land in MVP 2 Phase A** (none deferred). Items: clipboard delay wiring, shared `BinaryDiscoveryService` + redetect propagation, `LivePassManager` storePathOverride, `BinaryDiscoveryService` overrides from settings, `SettingsLink` replacing stringly-typed selector, `SettingsStoring` extension defaults removed, `UserDefaultsSettingsStore` `as!` removed, fakes consolidated to `Tests/Fixtures/`, repo hygiene, Diagnostics menu entry.

### Baseline (no change from MVP 1)
- **Stay on Swift 5.10 / macOS 14.** No 15-only API materially benefits MVP 2; `SettingsLink` is 14+. Strict concurrency = complete remains the baseline; Swift 6 migration deferred to MVP 3 review.

## 2026-05-09 — MVP 2 Phase B (resolution)

### Focus ring — split into two tokens
- **Focus ring is two-tone.** Dropped the single `focusRing` token; introduced `focusRingOuter` + `focusRingInner` in `ColorTokens`. Outer satisfies ≥ 3:1 vs `surface`; inner satisfies ≥ 3:1 vs both the outer and `accent`. A single-color focus ring on the pastel palette could not satisfy both background constraints (vs surface AND vs accent) without abandoning brand identity.
- **Implementation contract for components (Phase C):** every focusable component renders two concentric strokes — outer 2pt with `theme.colors.focusRingOuter`, inner 1pt inset with `theme.colors.focusRingInner`. A shared `KizbaFocusRing` view modifier consolidates this; `KizbaButtonStyle`, `KizbaTextFieldStyle`, `KizbaCard`, and `SecretRevealField` consume it. A `SourceGrepTests` rule (Phase C.6) bans direct reads of `focusRingOuter`/`focusRingInner` outside that modifier.
- **HC focus-ring family stays sky-blue** (azure outer + neutral inner) rather than collapsing into a deepened/brightened accent. Consistent visual semantics across standard and HC modes.

### Password reveal AAA preserved by lowering secretMask opacity
- **`passwordReveal` keeps AAA (≥ 7:1)** in all four variants. Achieved counterintuitively by *lowering* `secretMask` opacity in dark variants: a fainter mask preserves more of `onSurface`'s native ~16:1 contrast against the underlying `surface`. Final values: dark `secretMask = #A2D2FF @ 0.06` (was 0.14), darkHC = `#A2D2FF @ 0.04` (was 0.22), lightHC = `#BDE0FE @ 0.18` (was 0.30); light unchanged.

### HighContrast non-regression policy refined
- **HC non-regression rule applies to body text and `passwordReveal` numerically** (HC ratio ≥ standard ratio).
- **For focus-ring tokens, HC must independently satisfy the three ring assertions** (outer/surface ≥ 3:1; inner/outer ≥ 3:1; inner/accent ≥ 3:1) — not a numeric non-regression. The outer hue may differ across modes by design.

### Measured contrast outcomes (verified by ContrastChecker)
| variant   | passwordReveal | focusRingOuter/surface | focusRingInner/focusRingOuter | focusRingInner/accent |
|---|---:|---:|---:|---:|
| light     | 14.91 | 7.22  | 7.66  | 5.06  |
| dark      | 14.63 | 11.63 | 11.63 | 9.82  |
| lightHC   | 15.07 | 12.64 | 13.41 | 7.88  |
| darkHC    | 15.23 | 13.44 | 13.44 | 13.07 |

All cells exceed thresholds with margin. Body AAA, action-fill AA, and color-identity assertions all unchanged and passing.

### Ghost button pressed-state — luminance-away surface swap

- **Ghost button `pressed` state uses a luminance-away opaque surface variant**, not a neutral overlay. Light themes (`light`, `lightHighContrast`) press fill = `theme.colors.surfaceElevated`; dark themes (`dark`, `darkHighContrast`) press fill = `theme.colors.surfaceSunken`. Foreground stays `accent`. No new token introduced; the briefly-considered `surfacePressed` token was reverted.
- **Why a neutral overlay failed**: a darker overlay on light surface (or lighter overlay on dark surface) drags the composited background TOWARD the foreground luminance, *reducing* contrast as opacity grows — the opposite of intuition. Bumping opacity made it worse. With opaque surface variants in the away direction (lighter-than-surface for light themes, darker-than-surface for dark themes), `accent` foreground regains AA on all four variants without compositing math.
- **Measured ratios after fix:** light 5.06, dark 10.23, lightHC 7.88, darkHC 13.61. All comfortably ≥ 4.5 (AA).
- **Press affordance** is carried by (a) the surface-tone delta (visible because hue is accent vs. surface variants) and (b) the existing `KizbaButtonStyle` press scale animation. Hover/selected states stay distinct via their own tokens (`surfaceHover`, `surfaceSelected`).
- **Implementation note**: `KizbaButtonStyle.backgroundColor(for:in:isPressed:)` dispatches the press fill by `theme.id`. Avoid generalizing this to other variants — `.primary`, `.secondary`, `.destructive` have their own contracts (opaque accent fills, etc.) that already pass AA without this swap.

### Banner contrast — graphical-object threshold (SC 1.4.11) + darkHC muted alpha reduction

- **Banner severity icons measured at 3:1 (WCAG SC 1.4.11 Non-text Contrast), not 4.5:1.** SF Symbol glyphs are graphical objects, not text; severity is reinforced by background tone + fixed symbol shape (color-blind safe). Body text in the banner continues to be asserted at 4.5:1 (SC 1.4.3) against the same composited background. Smoke test split into two assertions (icon ≥3:1 and body text ≥4.5:1) covering all 4 themes × 4 severities = 32 cells.
- **darkHC `successMuted` / `warningMuted` / `dangerMuted` opacity lowered 0.28 → 0.10** to fix simultaneous body-text AA failure (3.64 / 3.79 / 4.36 → 7.28 / 7.48 / 8.25) AND icon SC 1.4.11 failure (2.43 / 2.52 / 2.88 → 4.85 / 4.98 / 5.45). Counterintuitively (same family of mistake as `secretMask` and ghost-pressed): on a near-black surface, a *fainter* light-pastel overlay keeps the composite closer to `surface`, raising contrast for both light text and light pastel icons. One lever, both contracts.
- **No icon-deepening applied.** A briefly considered "deepen the darkHC icons" path was directionally wrong (brightening pastel icons against a light composite reduced contrast: warning 2.52 → 2.12, danger 2.88 → 1.90 measured). Original spec hexes (`success #7CD9A8`, `warning #FFB870`, `danger #FFAFCC`) retained.
- **light, dark, lightHC severity tokens unchanged.** Edits scoped strictly to darkHC.
- **Heuristic recorded for future contrast work**: when foreground and background land in the same lightness half (both light or both dark), bumping foreground saturation/lightness usually moves contrast in the wrong direction. Lowering background overlay opacity is often the correct lever when the underlying surface is on the opposite end of the lightness scale.

### Sidebar selection styling — list style + EntryRowView extension

- **`SidebarView` now uses `EntryRowView` for folder rows** with `leadingIconName: "folder"` (new optional first parameter on `EntryRowView.init`, default nil keeps existing call sites working). Selection highlight uses `theme.colors.surfaceSelected` consistent with the entry list.
- **`.listStyle(.plain)` on `SidebarView`'s `List(selection:)`** suppresses the system selection chrome (`.sidebar` style was rejected — visual language must stay consistent across the two columns).

## 2026-05-09 — MVP 2 Phase D (resolution)

### Pure model layer pinned

- **`MetadataPair`** is `Sendable, Hashable, Identifiable` (UUID id), but **not Codable, not CustomStringConvertible/DebugStringConvertible** — same security non-conformance contract as `PassSecret`. Mutable `var` props for use inside `SecretDraft.metadata`.
- **`SecretDraft`** is a `final class` (reference semantics for SwiftUI form binding), `MainActor`-bound by ownership (no `Sendable`). `init(from secret:)` and `snapshot()` are inverses; mutating the draft after `snapshot()` does NOT affect the snapshot (verified by tests). Same security non-conformances as `MetadataPair`/`PassSecret`.
- **`MetadataPair.String(describing:)` does not assert "no value substring"** — that test would force adding `CustomStringConvertible` to mask the value, which violates the non-conformance rule. Instead `testRuntimeIsNotEncodable` checks the non-conformance directly. For `SecretDraft` (reference type) the default `String(describing:)` is just the type name and does pass the no-leak assertion.
- **`EntryPathValidator`** rejects: empty, leading/trailing slash, `..`/`.` components, `.gpg` suffix, whitespace-only components (including leading/trailing whitespace on the whole string). Allows whitespace inside components (entry names with spaces are valid in `pass`). Returns `Result<String, ValidationError>` with cases for each failure mode.
- **`MetadataValidator`** rejects keys that are empty, contain `:`, or contain `\n`. Rejects case-sensitive duplicate keys. Does NOT validate values (pass body allows any string in values). Returns the FIRST violation by lowest index.

### Serializer ↔ Parser format contract

- **`PassSecretSerializer` emits** `<password>\n<key>: <value>\n…<notes-verbatim>` — no blank-line separator before notes, no trailing `\n` appended after notes. The `.ai/plan.md` "blank line as separator" idea was dropped because `PassShowParser` does not consume blank lines (a literal blank line lands inside notes); the chosen format round-trips 20/20 fixtures (including a "diary" fixture with embedded blank line). Symmetry preserved with `pass`'s real-world `insert -m` stdin behavior.
- **Round-trip contract is value-level, not bytewise:** `PassShowParser.parse(PassSecretSerializer.serialize(s)).asPassSecret == s` for every PassSecret whose `notes` does not begin with `^[A-Za-z0-9_.-]+:\s`.
- **Known limitation:** notes beginning with a `key: value`-style line cannot round-trip — the leading line is indistinguishable from metadata on re-parse. Inherited from the informal `pass` body format. The corresponding test is `XCTSkip`-ped with an explanatory comment. `MetadataValidator` will surface this as a Phase F form-time warning (NOT blocking).
- **No parser changes.** Parser stays as-is.

### Password generator and parser

- **`LivePasswordGenerator`** uses `Int.random(in:)` (which on Darwin is backed by `SystemRandomNumberGenerator` = `arc4random_uniform`-style rejection sampling). No manual rejection sampling — relying on stdlib correctness. Charsets: always `[A-Za-z0-9]` (62); when `includeSymbols` true, plus `pass`'s default symbol set `!"#$%&'()*+,-./:;<=>?@[\\]^_`{|}~` (28). Throws `PasswordGenerationError.invalidLength(_)` for length ≤ 0. **No upper bound** — that's a `EntryFormModel` concern (Settings UI uses 8–128).
- **Statistical bias smoke test**: 100 000 chars per mode (alnum and alnum+symbols) with ±20% / ±25% bounds — ~7σ headroom against natural CSPRNG variance, no flakiness expected.
- **`PassGenerateParser`** strategy: strip ANSI SGR (`\u{001B}\[[0-9;]*m`) via pre-compiled `NSRegularExpression`, take the LAST non-empty trimmed line. Works for `pass` 1.7.3 and 1.7.4, plain and colored, plus `--in-place`, plus defensive case with git-style banner noise. Throws `ParsingError.emptyOutput` for empty/whitespace-only input.

### Error model + presentation hints

- **6 new `PassError` cases**: `entryAlreadyExists(path:)`, `recipientNotFound(emailOrKeyId:)`, `invalidGpgId`, `sourceNotFound(path:)`, `writeFailed(reason:)`, `invalidLength`. All `Sendable, Hashable, Equatable`.
- **3 new computed properties on `PassError`** (NOT on `ErrorPresentation`): `inlineRecoverable: Bool` (true for `entryAlreadyExists`), `onboardingHint: OnboardingHint?` (`.checkRecipients` for `recipientNotFound`, `.initializeStore` for `invalidGpgId`), `autoRefreshes: Bool` (true for `sourceNotFound`). Placed on `PassError` because the properties are inherent to the error, and `ErrorPresentation` does not currently carry the original error in its case payloads — extending `ErrorPresentation` would have forced a wider refactor.
- **New `OnboardingHint` enum** (`Sendable, Hashable, Equatable`): `.checkRecipients`, `.initializeStore`.
- **`ErrorPresentation.present(for:)` extended** for the 6 new errors. No new presentation cases — all 6 mapped onto the existing 4 (`silent`, `banner`, `onboarding`, `toastWithDiagnostics`). `entryAlreadyExists` and `invalidLength` map to `.silent` (form handles inline UI via `inlineRecoverable` and field-level validation respectively).

### `StoreChange` enum

- **New `Kizba/Domain/Models/StoreChange.swift`**: `.inserted(path:)`, `.updated(path:)`, `.removed(path:)`, `.moved(from:, to:)`, `.bulk`. `Sendable, Equatable, Hashable`. Foundation only. Phase E will wire emission via `LivePassManager`'s `AsyncStream<StoreChange>`.

## 2026-05-09 — MVP 2 Phase E.1 + E.2 + E.3 (resolution)

### `ShellInvocation` value type

- **New `Kizba/Domain/Protocols/ShellInvocation.swift`**: `executable: URL`, `arguments: [String] = []`, `environment: [String: String] = [:]`, `stdin: Stdin = .none`, `timeout: Duration` (no default). `Sendable, Equatable`. Computed `stdinByteCount: Int` reads the byte count for `.data(_)` and `0` for `.none` / `.closeImmediately` — safe to log.
- **`Stdin` is a nested enum** (`Sendable, Equatable`): `.none` keeps the existing `/dev/null` behaviour; `.data(Data)` writes bytes then closes; `.closeImmediately` opens-then-closes the pipe without writing (some CLIs distinguish "no input" from "stdin closed").
- **`environment` is non-optional `[String: String]`** — matches the existing protocol signature; empty dict ⇒ child gets an empty environment (callers compose explicitly via `PassCLI.composedEnvironment()`).
- **Timeout type stays `Duration`** (NOT `TimeInterval`) — preserves the existing protocol contract; the upstream task brief suggested `TimeInterval` but that would have churned every read-side caller for no benefit.

### `ShellCommandRunning` reshaped without churn

- **New primary method**: `func run(_ invocation: ShellInvocation) async throws -> ShellResult`.
- **Old parameter-list signature kept as a default-implemented compat extension** delegating with `stdin: .none`. Every existing read-side call site (`PassCLI.show`, scanner, discovery) compiles unchanged. Only test doubles that conformed to the protocol with the OLD method (two were found: `NeverCalledShellRunner`, `RecordingShellRunner`) had to be re-pointed at the new method — minimal mechanical edit.

### `ProcessShellRunner` stdin pipe (E.2)

- **Stdin is fed on a `Task.detached`** spawned *after* `process.run()` so it never contends with the stdout/stderr drain (the classic `Foundation.Process` deadlock when both ends of a pipe are saturated by one task). Verified by a 10 MB `cat` round-trip test.
- **`pipe.fileHandleForWriting.close()` is unconditional via `defer { try? close() }`**; `try writer.write(contentsOf: data)` errors (broken pipe — child died early) are swallowed and logged at `.debug` with `bytesIn=N` only. Never crashes, never logs payload.
- **`SIGPIPE` is globally ignored once on the first `ProcessShellRunner.init`** (via a small `OnceToken` + `signal(SIGPIPE, SIG_IGN)`). Without this, writing to a pipe whose reader has closed (timeout/cancel/early-exit child) terminates the host process before the `EPIPE` exception can be caught — fatal in tests and in the GUI. Ignoring `SIGPIPE` lets the kernel surface `EPIPE` via `write(2)` ⇒ caught by the `do/catch` around `FileHandle.write(contentsOf:)`. Standard practice for any code that writes to pipes; aligns with NSURLSession / Foundation defaults on macOS.
- **`.closeImmediately` reuses the same path** with empty `data` — the writer skips `write` but still closes the pipe.
- **Logging discipline**: `Log.shell.debug("... bytesIn=N ...")` instead of any string with the substring `stdin` near `Logger`/`print(`. The existing `SourceGrepTests.testNoStdinLogging_inKizbaSource` ban (`Logger.*stdin|print\(.*stdin`) still passes — `Log.shell` is not `Logger.*`, and the field name `stdinByteCount` is only used in code, not in log format strings.

### `Invocation` diagnostic record gains `stdinByteCount: Int?`

- **New optional field**, default `nil` (nil ⇒ "no stdin attached"; `0` ⇒ `.closeImmediately`; positive ⇒ `.data` byte count). Existing fixtures and tests stay green because the synthesised init defaults the parameter.
- **Synthesised `Equatable` picks up the new field** automatically. `ErrorPresentationIntegrationTests` and `InvocationLogTests` that build `Invocation` directly omit `stdinByteCount` ⇒ all become `nil` ⇒ no behaviour change.

### `FakeShellRunner` upgrade (E.3)

- **Internal storage migrated from a bespoke `Invocation` struct to `[ShellInvocation]`**. Source-compatible because the field set the assertions used (`executable`, `arguments`, `environment`, `timeout`) is a strict subset of `ShellInvocation`'s stored properties. Every existing `PassCLITests` / `LivePassManagerTests` / `LivePassManagerStoreOverrideTests` assertion compiles and passes unchanged.
- **`run(_:)` is now the only protocol-conforming method** the fake implements; the old parameter-list signature is satisfied automatically by the protocol extension and routes through the same capture path.
- **No new behaviour surface added** — capture upgrade only.

## 2026-05-09 — MVP 2 Phase E (resolution)

### Subprocess stdin pipe + SIGPIPE handling (E.1+E.2+E.3)

- **`ShellInvocation` value type** introduced in `Domain/Protocols/`. `Stdin` enum has three cases: `.none`, `.data(Data)`, `.closeImmediately`. Old `ShellCommandRunning.run(executable:arguments:environment:timeout:)` retained as a default extension method delegating with `stdin: .none` — every existing call site compiles unchanged.
- **`ProcessShellRunner` ignores `SIGPIPE`** via a one-time `signal(SIGPIPE, SIG_IGN)` set in `init` (guarded by an `OnceToken`). This is critical for stdin-write reliability: when the host cancels or times out the child process, the detached writer would otherwise receive `SIGPIPE` (default action: kill the host process). Now `write(2)` returns `EPIPE`, caught by the existing `do/catch`. Standard practice for any code writing to pipes; documented inline.
- **`Invocation` diagnostic record** gained a `stdinByteCount: Int?` field. NEVER stores stdin payload — only the byte count. Backed by `SourceGrepTests.testNoStdinLogging_inKizbaSource` (repo-wide ban: `Logger.*stdin|print\(.*stdin`).
- **No manual `Data` zeroing in MVP 2** — same trust level as `PassSecret.password`; documented as known limitation.

### Error mapping disambiguation (E.4)

- **`PassErrorMapper.map(stderr:exitCode:)` extended with optional `commandContext: CommandContext?`** (`.show / .list / .insert / .generate / .remove / .move / .initStore`, all `Sendable, Equatable`). Disambiguates the ambiguous string `"is not in the password store"`:
  - `.move` or `.remove` → `.sourceNotFound(path:)`
  - other / nil → `.invalidGpgId` (preserves prior MVP1 behavior).
- **All other write-time mappings**: `Cowardly refusing` / `mv: refusing to overwrite` / `already exists` → `.entryAlreadyExists(path:)`; `No public key` → `.recipientNotFound(emailOrKeyId:)`; `pass-length must be a positive integer` → `.invalidLength`; `password store is empty` / `You must run "pass init"` → `.invalidGpgId`. Path / email extraction extracts CONTEXTUAL data into the error case payload BEFORE the sanitizer runs; the user-facing `sanitizedExcerpt` (returned tuple element) keeps emails / hex IDs redacted.
- **Backward compat**: existing call sites passing `commandContext: nil` get identical behavior to MVP1.

### `PassCLI` write methods + `PassManaging` extension (E.5)

- **`PassCLI` write methods** (extension in `PassCLI+Write.swift`):
  - `insert(path:body:force:timeout:=15s)` — `["insert", "-m"] + (force ? ["-f"] : []) + [path]`, stdin = body bytes.
  - `generate(path:length:noSymbols:force:timeout:=15s) -> String` — returns parsed password from stdout via `PassGenerateParser`.
  - `generateInPlace(path:length:noSymbols:timeout:=15s) -> String` — adds `--in-place` flag.
  - `remove(path:timeout:=10s)` — `["rm", "-f", path]`.
  - `move(from:to:force:timeout:=15s)` — `["mv"] + (force ? ["-f"] : []) + [from, to]`.
  - `body` parameter type is `Data` (not `String`) — caller (`LivePassManager`) encodes from `PassSecretSerializer.serialize(secret).data(using: .utf8)!`. Stdin content NEVER logged; `Invocation.stdinByteCount` carries the count only.
- **`PassManaging` protocol extended** with the four user-facing methods + `var changes: AsyncStream<StoreChange>`. `MockPassManager` and `LivePassManager` implement; `UnavailablePassManager` (release-safe placeholder) traps with `fatalError`.
- **`PassManagingTestDefaults.swift` fixture** in `KizbaTests/Fixtures/` provides default-implementation extensions (XCTFail-throwing write stubs + empty `changes` stream) so 8 pre-existing read-only test fakes compile without per-fake updates.
- **Always `pass insert -m`, never two-prompt** — single read-until-EOF unifies the body format across all writes.
- **`MockPassManager.listEntries()` preserves insertion order**, not lexicographic sort, to keep MVP1 fixture-pinned tests passing.

### `LivePassManager` writes + `AsyncStream<StoreChange>` (E.6)

- **`.inserted` vs `.updated` distinction** via pre-call existence check: `scanner.contains(path:in:)` (cache-hit O(1) `Set` lookup, cache-miss single `FileManager.fileExists`). Cost ≤ 1 syscall per write — worth the typed event payload for Phase H reconciliation. New `PasswordStoreScanning.contains(path:in:)` protocol method with default `false` for read-only test fakes.
- **Multi-subscriber `AsyncStream<StoreChange>`** pattern: actor-stored `[UUID: AsyncStream<StoreChange>.Continuation]`; `nonisolated var changes` returns a fresh stream per call; `onTermination` actor-hops to unregister. `emit(_:)` iterates all live continuations. Mirrors the `MockPassManager` pattern from E.5.
- **Ordering invariant**: `scanner.invalidate(storeRoot:)` runs BEFORE `emit(_:)` on every successful write, so any subscriber that re-lists in response to the event sees post-write FS state.
- **`PassSecretSerializer.serialize(_:)` is MainActor-isolated** under default-isolation = MainActor (reads MainActor-initialized domain types). `LivePassManager.insert` wraps the call in `await MainActor.run { Data(serialize(...).utf8) }`; the body bytes (Data) cross actor boundaries, the String form does not. PassCLI logs only `stdinByteCount`.

### Opt-in E2E (E.8)

- **`PassWriteIntegrationTests.swift`** gated by env var `KIZBA_E2E=1` (when running via `xcodebuild`, prefix with `TEST_RUNNER_` so xcodebuild propagates it). Each method calls `XCTSkipUnless` first; without the env, the suite is silently skipped on CI.
- **Per-test setup**: temp directory at `/tmp/kizba-e2e-<short-id>/` (NOT `~/Library/Caches/...` — Unix domain socket path limit `sun_path` 104 bytes, GPG agent fails on long paths). Configures `gpg-agent.conf` with `allow-loopback-pinentry`, `gpg.conf` with `pinentry-mode loopback`, `batch`, `trust-model always`. Generates ephemeral ECDSA primary + ECDH subkey via `gpg --batch --gen-key` recipe (`%no-protection`, `Expire-Date: 1d`). Both keys required — primary alone has only `[SC]` capabilities and `pass insert` fails with "Unusable public key".
- **Tear-down**: `gpgconf --kill all` (best-effort) + `rm -rf` temp tree. Reliable even on test failure (`defer` blocks).
- **`pass yesno()` quirk**: when stdin is a pipe (no TTY), `pass insert` SILENTLY OVERWRITES without prompting, regardless of `-f`. Confirmed against `pass` 1.7.4. The "collision throws without `-f`" test that the architecture imagined is therefore not reproducible at the E2E level — collision-throwing is verified at the unit level (`PassErrorMapperTests` against fixture stderr from 1.7.3 and 1.7.4 in Phase E.4). E2E's overwrite test was reformulated as `testInsert_forceOverwrite_replacesExistingContent`.
- **7 E2E methods**: insert+show round-trip, force-overwrite replaces content, force overwrite doesn't block on pinentry, generate+show, remove+listEntries+`changes`, move+`changes`, multi-event AsyncStream ordering. All 7 pass locally with `pass 1.7.4` + `gpg 2.5.19` in 5.2s.

### `Suite` size at end of Phase E

- 538 tests total; 8 skipped (1 from D.3 notes-look-like-metadata + 7 from PassWriteIntegrationTests when KIZBA_E2E off); 0 failures. With `KIZBA_E2E=1`: all 538 pass.

## 2026-05-09 — MVP 2 Phase F (resolution)

### `ToastCenter` ownership and lifecycle

- **`Toast` value type relocated** from `Kizba/Presentation/DesignSystem/Components/ToastOverlay.swift` to `Kizba/Presentation/Toast/Toast.swift`. Foundation only. The `Toast.swift` and `ToastCenter.swift` files are OUTSIDE `DesignSystem/` so the C.6 grep bans apply — both are pure observable code, naturally clean.
- **`ToastCenter` is `@Observable @MainActor final class`** owned by `AppState` (NOT a global singleton). `init()` takes no arguments. Mounted ONCE at `RootSplitView` body via `.overlay(alignment: .bottomTrailing) { ToastOverlay(toast: state.toastCenter.visible) }`.
- **Dedup window**: 1 second on `(severity, title, message)` triple. Duplicate `post(_:)` within the window is silently dropped. The first toast retains visibility.
- **Default durations**: 4s for non-actionable toasts, 10s for toasts with an action. Computed in `Toast.init` from `action == nil`.
- **At-most-one visible**: a new `post(_:)` pre-empts the currently-visible toast (cancels its dismiss task); no stacking.
- **`accessibilityNotification(.announcement(...))` on appear** in `ToastOverlay` for VoiceOver.
- **Real-clock waits in tests**: no clock injection (deferred — keeps API minimal). Test waits use generous windows (250ms for 50ms duration; 1200ms for 1s dedup expiry).

### `EntryFormModel` (.create mode)

- **`@Observable @MainActor final class`** owning a `SecretDraft` (reference) + `path` String + `forceOverwrite` Bool. State machine: `idle | loadingExisting | editing | saving | saved(path:) | failed(PassError)`. `.create` starts in `.editing`. `.edit(originalPath:)` (loadingExisting) deferred to G.2.
- **Validation is computed**: `pathError` (via `EntryPathValidator`), `metadataError` (via `MetadataValidator`), `passwordError` (non-empty). `canSave` ANDs all three plus `state != .saving`.
- **Generation-counter pattern**: `private var generation: UInt64`. Each `save()` bumps and captures locally; only the latest task can mutate state on completion. Stale completions silently dropped.
- **`save()`**: runs validators (gates without changing state), bumps counter, transitions `.editing → .saving`, cancels prior save task, spawns new task that calls `passManager.insert(entry, secret: draft.snapshot(), force: forceOverwrite)`. On success: post success toast (`Toast(severity: .success, title: "Entry created", message: entry.path)`), set `appState.selectedEntryID = entry.path` IMPERATIVELY (before the `pass.changes` event ripples to the list — both are MainActor; ordering invariant documented inline). Reset `forceOverwrite = false` on success (defensive). On `entryAlreadyExists`: state `.failed(error)`, NO toast (the form's inline banner handles it). On other errors: state `.failed(error)`, error toast posted.
- **`cancel()`**: cancels in-flight save, returns to `.editing`, clears `forceOverwrite`. Does NOT clear `path`/`draft` (user might be cancelling network only).
- **`handleDismissal()`**: cancels save, replaces `draft` with a fresh empty `SecretDraft` (ARC drops the old reference), resets path/forceOverwrite. Called from view's `.onDisappear`.
- **`MutableSettingsStore` test fixture not in shared Fixtures/**: each test that needs a `SettingsStoring` fake declares its own (private). `EntryFormModel` itself doesn't take `SettingsStoring` — clipboard/clear-delay is `EntryDetailModel`'s concern.

### `NewEntrySheet` view

- **Layout**: `VStack { header, ScrollView { FormSection × 4 }, collisionBanner, footerActions }` with `theme.spacing.lg` padding and `theme.colors.surface` background. Frame `minWidth: 480, minHeight: 540`.
- **Sections**: Path (`FormSection` + `FormFieldRow` + `FolderPathPicker`), Password (`FormFieldRow` + `SecretRevealField` + "Generate password…" Button), Metadata (`KeyValueEditor` + inline metadata error text), Notes (`TextEditor` with `theme.colors.surfaceSunken` background + `theme.radius.sm` corner).
- **`KeyValueEditor` ↔ `MetadataPair` bridging**: a proxy `Binding<[KeyValueEditor.Pair]>` translates between the design-system `Pair` type and the domain `MetadataPair` type. Same UUID identity preserved.
- **`@Bindable var model: EntryFormModel`** — uses Observation framework's binding for SwiftUI 5+ models.
- **`draft.password` and `draft.notes` bindings**: explicit proxy `Binding`s because `model.draft` is `private(set)`. Preserves the invariant "draft is replaced wholesale on dismissal" — direct `$model.draft.password` would expose the reference and break that.
- **`TextEditor` background**: `.scrollContentBackground(.hidden)` + token-styled background — necessary on macOS 14+ to suppress system fill.
- **`isNewEntrySheetPresented: Bool`** lives on `AppState`. Both toolbar `+` button (in `EntryListView`) AND the `Entry > New Entry…` menu item (in `KizbaApp`'s `EntryMenuCommands`) toggle it. Sheet hosted in `EntryListView`.
- **⌘N**: wired through `EntryMenuCommands` (Commands path); no hidden Buttons in views.
- **Reactive auto-dismiss**: `.onChange(of: model.state)` (via a derived stable id) calls `dismiss()` when state becomes `.saved(_)`.

### `GeneratePasswordSheet` sub-sheet

- **`PasswordGenerating` injected via `AppEnvironment`**: `let passwordGenerator: any PasswordGenerating`. `live()` and `preview()` both use `LivePasswordGenerator()` (it's pure-stateless and release-safe). Tests use `FakePasswordGenerator` directly.
- **`GeneratePasswordModel`** (separate `@Observable @MainActor` model from `EntryFormModel` — bounded to sub-sheet's lifetime): `length: Int = 25` (bounds 8...128), `includeSymbols: Bool = true`, `state: idle | ready(password:) | error(_)`. `init` runs `regenerate()` immediately so the user always sees a preview.
- **No auto-regenerate**: contract is "view's `.onChange` calls `regenerate()` after a stepper/toggle commit". This is documented in the model and tested explicitly.
- **`onApply` callback**: sub-sheet doesn't mutate `EntryFormModel.draft.password` directly; the parent (`NewEntrySheet`) provides an `onApply: (String) -> Void` closure that does the assignment. Decoupling.

### `EntryListModel` ↔ `pass.changes` subscription (F.5)

- **F.5 contract**: ANY `StoreChange` event triggers `await refresh()`. Full per-event reconciliation (`.removed` clears selection, `.moved` follows selection, `.updated` re-fetches detail) is Phase H's responsibility.
- **Per-view subscription**: `EntryListModel.observeChanges() async` is started by `EntryListView`'s `.task { ... }` (separate from the existing refresh-task). Auto-cancels on `.onDisappear`.
- **Re-entrancy guard**: a second call to `observeChanges()` short-circuits if a subscription is already running (idempotent for tests + view re-attachments).
- **`stop()`**: explicit cancellation seam for tests.
- **`MockPassManager.changes` registration race**: `MockPassManager` is an actor; `observeChanges` returns the stream synchronously, but the actual continuation registration happens via a detached `Task` and may not be in the subscriber map by the time a tight `manager.insert(...)` runs. In production this race is impossible (user takes ≥ms to click Save after the view appears). In tests, a `startObservation` helper does 5× `Task.yield()` + 20ms sleep before mutations. The end-to-end test (which spawns its own Task chain via `EntryFormModel.save`) doesn't need the helper. Documented as a test-only concern.

### `AppEnvironment` extended

- **New parameters in `AppEnvironment.init`**: `passwordGenerator: any PasswordGenerating`. Backward-compatible default `LivePasswordGenerator()` so existing test constructions work; production `live()` always supplies it explicitly.
- **5 test files updated** (`EntryDetailModelTests`, `EntryDetailModelCopyTests`, `EntryDetailModelRefinementTests`, `EntryListModelRefreshTests`, `ErrorPresentationIntegrationTests`) with the new parameter — no behavior change.

### Suite size at end of Phase F

- **583 tests total**; 8 skipped (1 D.3 known limitation + 7 PassWriteIntegrationTests when `KIZBA_E2E` off); 0 failures.
- Phase F net delta: +45 tests (566 from end of E + 14 ToastCenter + 14 EntryFormModelCreate + 0 NewEntrySheet (view) + 10 GeneratePasswordModel + 7 EntryListReconciliation = exactly +45).

## 2026-05-09 — MVP 2 Phase G (resolution)

### `ActionHistory` — single-step in-session undo

- **`UndoableAction` enum** in `Kizba/Domain/Models/UndoableAction.swift`: `.delete(path:secret:)`, `.move(from:to:)`, `.inPlaceGenerate(path:previousSecret:)`. `Sendable` only — NOT Codable / NOT CustomStringConvertible/Debug / NOT Equatable. Mirrors `PassSecret`'s security non-conformances.
- **`ActionHistory`**: `@Observable @MainActor final class` owned by `AppState` (NOT a global singleton). Holds at most ONE pending action. Default expiry 10s via `Task.sleep`; expired action silently dropped. `record(_:expiresAfter:)` cancels prior expiry task; `undoLast()` clears `pending` BEFORE awaiting the inverse so a duplicate Undo press is no-op; failed undo also clears (documented). System `UndoManager` integration deferred to MVP 3.
- **`AppState.init` signature change**: now takes `passManager: any PassManaging` (designated init) for `ActionHistory(passManager:)`. A DEBUG-only convenience `init()` constructs a `MockPassManager()` so existing tests don't need updates. Production `KizbaApp.init` passes `env.passManager`.

### `EntryFormModel.edit` mode

- **Init `mode == .edit(originalPath:)`**: state starts at `.loadingExisting`, immediately spawns a load task that calls `passManager.show(entry)`. Generation-counter pattern guards against late completions. On success: state `.editing`, `draft` populated via `SecretDraft(from: secret)`. On failure: `.failed(error)` + danger toast "Could not load entry".
- **`save()` in edit mode**: ALWAYS calls `passManager.insert(entry: PassEntry(originalPath), secret: draft.snapshot(), force: true)`. `forceOverwrite` flag is ignored. On success: state `.saved(originalPath)`, success toast "Changes saved" with message=path, **`appState.selectedEntryID` is NOT mutated** (user is already on this entry).
- **`canEditPath`**: computed bool (`true` for `.create`, `false` for `.edit`). View renders the path field as disabled in edit mode.
- **`canSave` in edit mode**: also blocks while `state == .loadingExisting`.
- **`EditEntrySheet`**: copy-and-adapt from `NewEntrySheet` (drops collision banner; adds loading skeleton; routes load-failure to a separate body via a `hasLoaded` heuristic). Pragmatic duplication; extract a shared `EntryFormBody` view if it grows painful.

### In-place regenerate password — `PassManaging.generateInPlace(...)` extension

- **`PassManaging` extended** with `func generateInPlace(_ entry: PassEntry, length: Int, includeSymbols: Bool) async throws -> PassSecret`. The existing `generate(...)` was a commit-new path (`pass generate [-f] [-n]`) that overwrites with EMPTY metadata — incompatible with G.3's "preserve metadata" contract. `generateInPlace` maps to `pass generate --in-place` (atomic).
- **Returned `PassSecret` has empty metadata** by design (avoids a second pinentry within the same user gesture). Consumers re-fetch via `show` once the `.updated` event arrives. Documented in the protocol's doc comment. `MockPassManager` STILL preserves metadata internally (so undo can verify), but the returned value's metadata is deliberately empty for production parity.
- **`RegenerateInPlaceModel`**: `@Observable @MainActor` sub-sheet model. State `idle | running | succeeded(newPassword:) | failed(PassError)`. `regenerate()`:
  1. Pre-`show` to capture prior secret. On failure → `.failed` + danger toast; no ActionHistory record.
  2. `passManager.generateInPlace(...)`. On failure → `.failed` + danger toast; no ActionHistory record.
  3. `actionHistory.record(.inPlaceGenerate(path:previousSecret:), expiresAfter: .seconds(10))`.
  4. State `.succeeded(newPassword:)` + success toast "Password regenerated" with Undo action.
- **No password preview**: unlike F.4's `GeneratePasswordSheet` (which uses `LivePasswordGenerator` for client-side preview before commit), in-place regenerate has no preview — the password committed by the CLI is THE password. Single-button "Regenerate" + warning banner upfront.

### Move / rename — `MoveEntryModel`

- **`MoveEntryModel`**: `@Observable @MainActor`. State `idle | saving | saved(newPath:) | failed(PassError)`. `forceMove: Bool` for collision retry. `pathError` includes a "same path" rule on top of `EntryPathValidator`. Generation-counter for cancellation safety.
- **`save()`**: calls `passManager.move(from: originalEntry, to: newPath, force: forceMove)`. On success: `appState.selectedEntryID = newEntry.path` (selection follows the moved entry); `actionHistory.record(.move(from:to:))` + undoable success toast "Entry moved · Now at <path>".
- **`MoveEntrySheet`**: compact (single field + buttons + banners). Hosted in `EntryListView` (move is a list-column action per `.ai/plan.md`). Toolbar `↔` (SF Symbol `arrow.left.arrow.right`); ⌘⇧M shortcut.

### Delete — `EntryListModel.deleteEntry(at:)` + two-step confirmation

- **No new sheet**: delete uses `destructiveConfirmation(...)` from `Kizba/Presentation/DesignSystem/Modifiers/` (Phase C.1). The two-step nature comes from the dialog itself appearing — user clicks 🗑 → confirms in the destructive-role dialog (`.confirmationDialog`) → action runs.
- **`EntryListModel.deleteEntry(at:)`**:
  1. Re-entrancy guard via `deletionState == .idle`.
  2. **Pre-`show`** to capture the secret for undo. If show fails → state idle, danger toast "Could not load secret for undo at \<path>". We REFUSE to delete what we can't restore.
  3. `passManager.remove(entry)`. On failure → danger toast.
  4. On success: clear `appState.selectedEntryID` if it was equal to deleted path; `actionHistory.record(.delete(path:secret:))`; success toast "Entry deleted" with Undo.
- **`isDeleteConfirmationPresented`** lives on `AppState`. Toolbar 🗑 (SF Symbol `trash`) and `Entry > Delete Entry` (⌫) both toggle it. Confirmation dialog hosted in `EntryListView`.

### Toolbar lockout — `ActiveWriteOp` set on `AppState`

- **`ActiveWriteOp` enum** (`Sendable, Hashable`): `.insertNew`, `.edit`, `.regenerate`, `.move`, `.delete`.
- **`AppState.activeWriteOps: Set<ActiveWriteOp>`** + `var anyWriteInFlight: Bool` + `func beginWrite(_:)` / `endWrite(_:)` (both idempotent via `Set` semantics).
- **Per-model wiring**: each write model calls `beginWrite(op)` before transitioning to `.saving/.deleting/.running` and `endWrite(op)` on completion (success, failure, cancel, dismissal). Cancel/dismissal release the lockout SYNCHRONOUSLY (so the user can immediately start a new op); the in-flight Task uses a `cancelled` flag to skip its own `endWrite` and avoid double-release.
- **Toolbar/menu disable conditions** updated for all 5 write actions: every write toolbar button (`+`, `✎`, 🎲, `↔`, 🗑) and every write menu item adds `state.anyWriteInFlight` to its existing `.disabled(...)` chain. Read-side buttons (Refresh, Settings, Diagnostics) are NOT affected.

### Suite size at end of Phase G

- **660 tests total**; 8 skipped (1 D.3 known limitation + 7 PassWriteIntegrationTests when `KIZBA_E2E` off); 0 failures.
- Phase G net: +77 tests over 6 substeps.

## 2026-05-09 — MVP 2 Phase H (resolution)

### Centralized `StoreChange` reconciliation (option B — neutral data layer)

- **`StoreChange` stays neutral** — no UI-origin tags. The `.inserted` event does NOT carry "was this a create or an edit?" — that's UI-side intent. Adding origin tags to the data layer would be a leak.
- **Selection on insert is IMPERATIVE from the write model**: `EntryFormModel(.create).applySuccess` sets `appState.selectedEntryID = newPath`; `.edit` mode does not. The centralized reconciler observes `.inserted` events but does NOT touch `selectedEntryID` for them.
- **Selection on move/delete is IDEMPOTENT**: write models (`MoveEntryModel.applySuccess`, `EntryListModel.deleteEntry`) imperatively set/clear `selectedEntryID` for instant UX feedback. The centralized reconciler ALSO sets/clears on `.moved`/`.removed` events. Both runs produce the same result; the centralized rule is "belt-and-suspenders" defense against a future write model forgetting to update selection.

### Per-event reconciliation rules (locked)

| Event | EntryListModel handler | EntryDetailModel handler |
|---|---|---|
| `.inserted(path:)` | refresh; selection NOT touched (write model owns it) | no-op |
| `.updated(path:)` | refresh; selection NOT touched | if `path == selectedEntryID` → re-fetch via load(entry:); else no-op |
| `.moved(from:to:)` | refresh; if `selectedEntryID == from` → set to `to` | if `selectedEntryID == from` → re-fetch via load(entry: `to`) |
| `.removed(path:)` | refresh; if `selectedEntryID == path` → clear | if `selectedEntryID == path` → clear loaded secret |
| `.bulk` | refresh; if selection no longer exists → clear | no-op |

### `EntryDetailModel` subscription

- New `observeChanges() async` method mirrors F.5's `EntryListModel` subscription pattern. Started by `EntryDetailView`'s `.task { await detailModel.observeChanges() }`. Auto-cancels on `.onDisappear`.
- Re-entrancy guard: a second call short-circuits if already running.
- `stop()` test seam.

### `MockPassManager.emitBulk()`

- New `#if DEBUG`-gated public method: `func emitBulk() async`. Emits `.bulk` to all subscribers without mutating the in-memory corpus. Test-only affordance for `EntryListReconciliationTests` to verify `.bulk` handling without needing a full multi-write batch. Live `LivePassManager` does not currently emit `.bulk` (no FSEvents wiring); future MVP3 work for external-change detection will exercise this code path.

### Suite size at end of Phase H

- **676 tests total**; 8 skipped (1 D.3 known limitation + 7 PassWriteIntegrationTests when KIZBA_E2E off); 0 failures.
- Phase H net: +16 tests across 3 sub-steps (H.1 model changes are tested by H.2's new EntryDetailReconciliationTests + H.2 extensions to EntryListReconciliationTests; H.3 was a regression check on G.6's existing tests).

### What's left in MVP 2

Phase I — polish, a11y, Sequoia smoke, README, opt-in E2E green, final regression sweep.

## 2026-05-09 — MVP 2 Phase I (resolution)

### Release-readiness audit complete

- **Phase I.1 — Shortcut + menu audit**: every documented MVP 2 surface has the right shortcut, the right disable condition (selection × `anyWriteInFlight`), and a `.help(...)` tooltip on toolbar buttons. Two missing tooltips fixed in `DiagnosticsView` (Refresh / Clear). All 13 audited surfaces pass.
- **Phase I.2 — `SemanticIconographyTests`** (5 methods): locks the per-severity SF Symbol mapping (`info.circle.fill`, `checkmark.circle.fill`, `exclamationmark.triangle.fill`, `xmark.octagon.fill`); asserts uniqueness + non-empty + ToastView's reuse of BannerView's source-of-truth helpers; asserts icon color != background color in every theme variant. WCAG SC 1.4.11 (3:1 graphical objects) and SC 1.4.3 (4.5:1 body text) contrast assertions stay in `BannerViewTests` (E.4 era).
- **Phase I.3 — `.ai/a11y-audit.md`** (375 lines, exhaustive): documents the code-side accessibility surface AND a manual checklist (VoiceOver, Increase Contrast, Dynamic Type, Reduce Motion, Color filters, Keyboard-only, Read-only without `pass`/`gpg`). 5 medium-priority gaps + 4 low-priority gaps documented for MVP 3 review. One trivial fix applied: `SidebarView` rows now carry `accessibilityLabel("\(folder.name), folder")` so VoiceOver announces the role.
- **Phase I.4 — `.ai/sequoia-smoke.md`** (109 lines): manual checklist for macOS 15 Sequoia compatibility. Hypothesis: clipboard auto-clear is unaffected (write-only pattern); Process spawn is unaffected (non-sandboxed Developer ID). Verification table left for the user to fill on first Sequoia smoke.
- **Phase I.5 — `pass` 1.7.3/1.7.4 fixture parity**: verified `PassErrorMapperTests` (E.4) covers both versions for every write-time stderr signature; `PassGenerateParserTests` (D.5) covers both versions for plain + colored + `--in-place` stdout shapes. No fixtures missing; no test additions needed.
- **Phase I.6 — `README.md`** rewritten (63 → 187 lines): MVP 2 feature list, requirements, build/test instructions, security model (what we do / what we don't), known limitations (in-memory secrets as plain `String`/`Data`, no FSEvents, `pass yesno()` quirk, notes-look-like-metadata limitation, single store), MVP 3 deferrals, project structure overview, links to `.ai/` docs. License preserved as TBD.
- **Phase I.7 — Opt-in E2E**: 7 / 7 pass locally (or 7 / 7 skipped if `pass`+`gpg` not installed on the test runner — the `XCTSkipUnless` gate is exercised either way).
- **Phase I.8 — Final regression sweep**: 681 / 8 skipped / 0 failures (default); SourceGrepTests 16/16; release build green; all repo-wide grep bans clean; warnings-as-errors clean.

### MVP 2 ships

- **Test count progression**: MVP 1 baseline 209 → A 216 → B 276 → C 330 → D 462 → E 538 → F 583 → G 660 → H 676 → **I 681**. Phase I net: +5 tests (`SemanticIconographyTests`).
- **Commits to date**: A+B+C+D (`ddcce10`), E (`db61d41`), F (`e569e7e`), G (`49b6c51`), H (`d9535a4`); Phase I to be committed in the same final pass.
- **Architectural ledger length**: `.ai/decisions.md` ~430 lines — 8 dated subsections (MVP 1 + MVP 2 Phases B/E/F/G/H/I).

### What's next

Phase I closes MVP 2. The next milestone is MVP 3 — see the "What's deferred" sections in `README.md` and `.ai/handoff.md`. Notable MVP 3 candidates:
- `pass git` integration (status / push / pull / conflicts).
- System `UndoManager` integration.
- Touch ID / LocalAuthentication unlock-before-reveal.
- Menu-bar (status item) app surface.
- FSEvents external-change detection.
- App Sandbox + helper tool.
- `ScrubbingString` secure-string buffer.
- Snapshot tests.

## 2026-05-10 — MVP 3 (planning locked)

The 20 architectural decisions for MVP 3 (planning phase, before any code). Items will be re-confirmed as resolutions in F.4 once implementation completes.

### Scope
- **MVP 3 = 5 features across 6 phases**: defense-in-depth, AppRouter+EntryFormBody refactor, FSEvents auto-refresh, a11y mediums, Touch ID per-reveal gate, polish.
- **`pass git ...` deferred to MVP 4.** Conflict-resolution UX is its own release.
- **Menu-bar / status item app surface deferred to MVP 4.** Global hotkey + lifecycle complexity warrants a separate MVP.
- **App Sandbox stays deferred** (was deferred in MVP 1+2+3). Privileged helper for `Process` spawn is too large for MVP 3.

### Architecture
- **AppRouter extraction is the right shape.** `@Observable @MainActor final class AppRouter` owned by `AppState`. Holds: 5 `is*Presented` flags + `selectedFolder` + `selectedEntryID`. Exposes imperative API (`presentNewEntry()`, `dismissAll()`, `selectEntry(_:)`, etc.). Migration is staged via proxy properties → call-site updates → proxy removal.
- **AppState keeps**: `searchQuery`, `isSidebarCollapsed`, `currentEntries`, `toastCenter`, `actionHistory`, `activeWriteOps`, `router`. `activeWriteOps` stays in AppState because it's about background work in flight (model concern), not presentation intent.
- **EntryFormBody extraction is the right shape.** Generic over `Header`/`Footer` slots, `pathFieldEnabled: Bool` parameter. `NewEntrySheet` and `EditEntrySheet` become thin wrappers. The Generate sub-sheet wiring lives in `EntryFormBody` (consolidates the `@State`-held sub-model rule from MVP 2 post-ship learning).
- **FSEvents emits ONLY `.bulk` events** from `LivePassManager` (no per-path delta in MVP 3). 350 ms trailing-edge debounce. Per-path delta is deferred — `.bulk` triggers a re-list which is fine for MVP 3.
- **`StoreWatching` protocol is a separate seam from `LivePassManager`.** `FSEventsStoreWatcher` is the production impl; `FakeStoreWatcher` for tests; `LivePassManager` owns optional `StoreWatching` and translates events to `.bulk`.

### Touch ID
- **Touch ID gate is per-reveal**, NOT per-`pass show` (pinentry already gates), NOT app-launch (overkill).
- **Default OFF** (opt-in toggle in Settings). Rationale: unboxing must Just Work; biometric unavailability is silent; opt-in keeps the contract that user explicitly requested the friction.
- **`.deviceOwnerAuthenticationWithBiometrics`** policy (NOT `.deviceOwnerAuthentication` — no password fallback). If Touch ID unavailable when toggle ON, reveal silently bypasses the gate (documented).
- **`BiometricAuthenticating` protocol stays free of `LAError`**, mapping happens inside `LocalAuthBiometricAuthenticator`. Domain remains free of `LocalAuthentication` import.
- **`LAContext` is fresh per `authenticate(_:)` call** (no reuse, no warming). `LAContext` not Sendable; impl is `final class @unchecked Sendable`.

### Defense-in-depth
- **`SourceGrepTests` rule: every `Presentation/**/*Model.swift` with `final class …Model` MUST contain `@Observable`.** Allow-list via `// kizba:not-observable-model` marker. Catches the `SecretDraft` regression class.
- **`SourceGrepTests` rule: forbid `*Model(` constructor inside `.sheet/.popover/.fullScreenCover { ... }` body.** Allow-list via `// kizba:allow-sheet-init` marker. Catches the model-recreation anti-pattern that bit the Generate sheet 3× in MVP 2 post-ship.
- **`.onChange(of: enumWithAssoc)` rule is a code-review checklist item, NOT a grep test.** Too hard to grep correctly without semantic analysis. Captured in `.ai/code-review-checklist.md`.

### Concurrency / threading
- **`LAContext` not Sendable**; `LocalAuthBiometricAuthenticator` is `@unchecked Sendable` (fresh context per call ensures safety).
- **`FSEventStreamRef` not Sendable**; `FSEventsStoreWatcher` is `@unchecked Sendable` (owns serial DispatchQueue; FSEvents callback runs there only).
- **`AppRouter` is `@MainActor`** like `AppState`. No new concurrency concerns.

### Test strategy
- **Snapshot tests still OUT** (per existing decisions).
- **Opt-in `KIZBA_FSEVENTS_TEST=1` env var** for FSEvents real-FS tests (CI-flaky). Existing `KIZBA_E2E=1` continues to gate `PassWriteIntegrationTests`.
- **Net suite delta ~+50 tests** (692 → ~742). New fakes: `FakeStoreWatcher`, `FakeBiometricAuthenticator`. New helpers: `AsyncTestHelpers`.
