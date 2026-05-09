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
