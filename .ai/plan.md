# MVP7 — Touch ID Copy Gate + OTP Display

## Status of prior milestone

MVP6 fully shipped (Phases A–H). Suite: **1070 tests, 0 failures**, Release build clean,
SourceGrep bans clean. Recents fixture leak resolved by H.1 (schema bump v1→v2) + H.2 (path validation).

Foundations already in place for MVP7:
- `Kizba/Domain/Protocols/BiometricAuthenticating.swift` — protocol + `BiometricAvailability`,
  `BiometricResult`, `BiometricUnavailableReason`, `BiometricFailureReason`.
- `LocalAuthBiometricAuthenticator` — production impl (LAContext-based).
- `FakeBiometricAuthenticator` in `KizbaTests/Fixtures/` — configurable double.
- Reveal-gate live in `EntryDetailModel.requestReveal()` (lines 77–104) and
  `SecretRevealField.attemptReveal`.
- Setting `touchIDPerRevealEnabled` (`SettingsKeys`, `SettingsModel.requestToggleBiometric`,
  MVP6 D.1).
- `SecurityTab.swift` — UI gating by `availability` (MVP6 D.2).
- `MetadataPair` type exists on `PassSecret`.
- `PassSecret`: NOT `Codable`, NOT `CustomStringConvertible` (enforced by SourceGrep).
- `Help` topics already exist (MVP6 E.1) — extendable.
- `ClipboardServicing` — clipboard copy + auto-clear.

## Goal

Implement two carry-overs from the original "Later features" roadmap:

1. **Phase A — Touch ID gate before copy** (roadmap #4 partial → done).
   Reuse the existing biometric infra to gate copy-to-clipboard for *sensitive* values
   in both `EntryDetailView` and `MenuBarPopoverView`.
2. **Phase B — OTP display** (roadmap #8 not done → done).
   Detect `otpauth://` URIs in `PassSecret` metadata/extra lines and render a live
   TOTP/HOTP code (RFC 6238 / RFC 4226) with progress indicator and gated copy.

## Sequencing

**Phase A first** — small, reuses existing infra, and Phase B depends on the consolidated
gate for "Copy OTP" UX.

## Constraints (apply to every task)

- Swift 5.10, macOS 14, strict concurrency complete.
- No `as!`, no third-party deps, no stdin/stdout logging.
- Design-System tokens only (no literal `Color.*`, numeric `cornerRadius`, numeric
  `.opacity()` outside `DesignSystem/`).
- English-only strings (incl. Help topics, accessibility labels).
- `OTPSecret` must follow `PassSecret` pattern: NOT `Codable`, NOT
  `CustomStringConvertible` — enforced by `SourceGrepTests`.
- All Help topic copy in English.
- No new third-party dependencies; OTP HMAC via `CryptoKit`.
- `SettingsKeys` rename happens via additive migration — never break existing user prefs
  silently.

## Open decisions (locked)

1. **Single setting for reveal + copy.** New key `touchIDForSensitiveActions` (Bool, default `false`). One-shot migrate legacy `touchIDPerRevealEnabled` value into new key in `UserDefaultsSettingsStore.init`, then remove legacy key. Single mental model: "Touch ID protects sensitive actions" (reveal + copy).
2. **Username copy — NOT gated.** Usernames are routinely visible in lists; gating them would be UX-noise.
3. **Metadata copy — whitelist only.** Gated keys (case-insensitive): `password`, `pin`, `token`, `secret`, `otpauth`, `key`. Other metadata (notes/url/email) copy without prompt. Whitelist is a single constant in `BiometricGate`.
4. **MenuBar password copy — gated.**
5. **Failure semantics.** On `.cancelled`/`.failed` — silent skip (no clipboard write, no error banner). On `.unavailable` — bypass (graceful, mirrors reveal).

Decisions recorded in `.ai/decisions.md` MVP7 entry (Task F).

---

## Phase A — Touch ID Copy Gate

### A.1 — `BiometricGate` helper extraction

**Description:** Extract Touch ID gating logic currently inline in `EntryDetailModel.requestReveal()` into a reusable `@MainActor` helper. Refactor `requestReveal` to use it. Foundation for A.3 (copy gates) and B.4 (OTP copy gate).

**Agent:** smart-worker

**Files:**
- ADD `Kizba/Domain/BiometricGate.swift`:
  ```swift
  @MainActor
  public struct BiometricGate: Sendable {
      public static let sensitiveMetadataKeys: Set<String> = [
          "password", "pin", "token", "secret", "otpauth", "key"
      ]

      public let auth: (any BiometricAuthenticating)?
      public let settings: any SettingsStoring
      public let policyKey: SettingsKey<Bool>

      public init(
          auth: (any BiometricAuthenticating)?,
          settings: any SettingsStoring,
          policyKey: SettingsKey<Bool>
      )

      /// Returns `true` if the gated action may proceed.
      /// - Returns `true` immediately when policy is off, authenticator is nil,
      ///   or biometrics report `.unavailable`.
      /// - Returns `true` on `.success`, `false` on `.cancelled`/`.failed`.
      public func run(reason: String) async -> Bool

      /// Convenience: returns `true` iff `key` (case-insensitive) is in `sensitiveMetadataKeys`.
      public static func isSensitiveMetadataKey(_ key: String) -> Bool
  }
  ```
- MOD `Kizba/Presentation/Features/EntryDetail/EntryDetailModel.swift`:
  - Replace `requestReveal()` body with `BiometricGate.run(reason:)`. Construct gate from `environment.biometricAuth`, `environment.settings`, `SettingsKey<Bool>(SettingsKeys.touchIDForSensitiveActions)` (added in A.2; until then uses legacy key — A.2 swaps in one place).

**Tests:**
- ADD `KizbaTests/Domain/BiometricGateTests.swift` (≥5 cases):
  1. `policy off → run returns true, authenticator never called`.
  2. `policy on + nil authenticator → returns true`.
  3. `policy on + available + success → returns true`.
  4. `policy on + available + cancelled → returns false`.
  5. `policy on + available + failed → returns false`.
  6. `policy on + unavailable → returns true (graceful)`.
- VERIFY existing `EntryDetailModelTests` reveal-gate tests stay green.

**Verification:**
```sh
xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' \
  -only-testing:KizbaTests/BiometricGateTests \
  -only-testing:KizbaTests/EntryDetailModelTests
rg -n 'auth\.authenticate\(reason:' Kizba/   # should only match BiometricGate.swift after A.3
```

**Branch:** `mvp7/a1-biometric-gate-helper`
**Commit:** `refactor(security): extract BiometricGate helper for Touch ID gating (MVP7.A.1)`
**Difficulty:** S–M
**Risks:** Existing reveal-gate test coverage must keep passing — refactor mechanical but easy to mis-thread `policyKey` injection.

---

### A.2 — Setting consolidation (`touchIDForSensitiveActions` + migration)

**Description:** Introduce new setting key, migrate legacy one, rename model surface, update SecurityTab copy. Single source of truth for "Touch ID protects sensitive actions".

**Agent:** smart-worker

**Files:**
- MOD `Kizba/Infrastructure/Settings/SettingsKeys.swift`:
  - ADD `public static let touchIDForSensitiveActions = "touchIDForSensitiveActions"` (follow existing namespacing convention).
  - KEEP `public static let touchIDPerRevealEnabled` as legacy constant (marked `// Legacy MVP6 key — migrated by UserDefaultsSettingsStore.init`).
- MOD `Kizba/Infrastructure/Settings/UserDefaultsSettingsStore.swift`:
  - In `init`, add one-shot migration:
    ```swift
    // MVP7.A.2: migrate legacy reveal-only flag into combined sensitive-actions flag.
    let legacyKey = namespaced(SettingsKeys.touchIDPerRevealEnabled)
    let newKey = namespaced(SettingsKeys.touchIDForSensitiveActions)
    if userDefaults.object(forKey: newKey) == nil,
       let legacyValue = userDefaults.object(forKey: legacyKey) as? Bool {
        userDefaults.set(legacyValue, forKey: newKey)
        userDefaults.removeObject(forKey: legacyKey)
    }
    if userDefaults.object(forKey: newKey) == nil {
        userDefaults.register(defaults: [newKey: false])
    }
    ```
- MOD `Kizba/Presentation/Features/Settings/SettingsModel.swift`:
  - Rename property `touchIDPerRevealEnabled` → `touchIDForSensitiveActions`.
  - Rename snapshot field.
  - Update key references to `SettingsKeys.touchIDForSensitiveActions`.
- MOD `Kizba/Presentation/Features/Settings/Tabs/SecurityTab.swift`:
  - Toggle label: "Require Touch ID for sensitive actions".
  - InfoTooltip body: "When enabled, Kizba asks for Touch ID before revealing a password and before copying passwords or other sensitive metadata (PIN, token, secret, OTP, key) to the clipboard. Username and non-sensitive metadata are not gated."
- MOD `Kizba/Presentation/Features/EntryDetail/EntryDetailModel.swift`:
  - Update `BiometricGate` construction to use `SettingsKey<Bool>(SettingsKeys.touchIDForSensitiveActions)`.

**Tests:**
- ADD `KizbaTests/Settings/SettingsKeyMigrationTests.swift`:
  - `legacy true → new true, legacy key removed`.
  - `legacy false → new false, legacy key removed`.
  - `legacy missing → new key registered with default false`.
  - `new key already set → migration no-op (does NOT clobber user choice)`.
- UPDATE `SettingsModelTests` for renamed property.
- UPDATE `EntryDetailModelTests` reveal-gate tests if they reference old key literal.

**Verification:**
```sh
rg -n 'touchIDPerRevealEnabled' Kizba/        # only SettingsKeys.swift (legacy) + migration block
rg -n 'touchIDForSensitiveActions' Kizba/     # SettingsKeys + SettingsModel + SecurityTab + EntryDetailModel (≥4)
xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS'
```

**Branch:** `mvp7/a2-touchid-setting-consolidation`
**Commit:** `feat(settings): consolidate Touch ID flag to touchIDForSensitiveActions with one-shot migration (MVP7.A.2)`
**Difficulty:** M
**Risks:** Missed call-site → silent regression of reveal-gate. Mitigate via grep verification + dedicated migration tests.

---

### A.3 — Wire `BiometricGate` into copy actions

**Description:** Apply gate to every sensitive copy path: password copy in EntryDetailView, whitelisted metadata copy, MenuBar password copy. Username copy and non-whitelisted metadata stay ungated.

**Agent:** smart-worker

**Files:**
- MOD `Kizba/Presentation/Features/EntryDetail/EntryDetailModel.swift`:
  - Add `func requestCopyPassword() async` and `func requestCopyMetadata(_ pair: MetadataPair) async`.
  - Both construct `BiometricGate` (or reuse cached); password always gates; metadata gates iff `BiometricGate.isSensitiveMetadataKey(pair.key)`.
  - On `gate.run(reason:)` returning `true`, call `environment.clipboard.copy(...)`.
  - On `false`, no-op (silent skip).
- MOD `Kizba/Presentation/Features/EntryDetail/EntryDetailView.swift`:
  - Replace direct `clipboard.copy(...)` in copy-password and copy-metadata buttons with `await model.requestCopyPassword()` / `await model.requestCopyMetadata(pair)`.
  - Username copy: unchanged.
- MOD `Kizba/Presentation/Features/MenuBar/MenuBarModel.swift`:
  - In `copyEntry(path:)`, after fetching `PassSecret`, route password through `BiometricGate.run(reason: "Copy password from menu bar")` before clipboard write. Mirror EntryDetailModel injection of `auth`/`settings`.

**Tests:**
- ADD `EntryDetailModelTests` cases:
  - `requestCopyPassword_policyOn_success_writesToClipboard`.
  - `requestCopyPassword_policyOn_cancelled_doesNotWriteToClipboard`.
  - `requestCopyMetadata_sensitiveKey_policyOn_cancelled_doesNotWrite`.
  - `requestCopyMetadata_nonSensitiveKey_policyOn_writesWithoutPrompt` (authenticator NOT called).
  - `requestCopyMetadata_sensitiveKey_caseInsensitive` (`"Password"`, `"OTPAUTH"`).
- ADD `MenuBarModelTests` cases (success/cancel/policy-off).
- ADD `BiometricGateTests` table-driven test for every whitelist key + control non-whitelist (`notes`, `url`, `email`, `comment`).

**Verification:**
```sh
rg -n 'clipboard\.copy' Kizba/Presentation/   # username remains direct; password+metadata via model
xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS'
```

**Branch:** `mvp7/a3-gate-copy-actions`
**Commit:** `feat(security): gate password and sensitive metadata copy with Touch ID (MVP7.A.3)`
**Difficulty:** M
**Risks:** Whitelist mismatch; MenuBar inject of same `settings`/`auth` instances must match EntryDetailModel.

---

### A.4 — Help topic + polish

**Description:** Update Help to reflect Touch ID now gates copy + reveal. Add dedicated topic.

**Agent:** smart-worker

**Files:**
- ADD Help topic `touch-id-protection`:
  - Title: "Touch ID protection".
  - Body: scope (reveal + password copy + sensitive metadata copy); whitelist; what's NOT gated; graceful fallback when biometrics unavailable; how to enable in Settings → Security.
- MOD any existing topic mentioning Touch ID (search `rg -nI 'Touch ID' Kizba/`).

**Tests:**
- ADD Help-topic listing test asserting `touch-id-protection` registered.

**Verification:**
```sh
rg -n 'Touch ID' Kizba/
xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS'
```

**Branch:** `mvp7/a4-help-touchid-topic`
**Commit:** `docs(help): add Touch ID protection topic explaining gated actions (MVP7.A.4)`
**Difficulty:** S
**Risks:** none material.

---

### Phase A acceptance criteria

- [ ] `BiometricGate` helper exists; single call site for `auth.authenticate(reason:)` in production tree.
- [ ] `SettingsKeys.touchIDForSensitiveActions` exists; legacy `touchIDPerRevealEnabled` value migrated one-shot; SettingsModel surface renamed.
- [ ] SecurityTab wording covers reveal + copy.
- [ ] Password copy from EntryDetailView and MenuBarModel.copyEntry is gated.
- [ ] Metadata copy gated iff key in whitelist (case-insensitive); username and non-whitelisted ungated.
- [ ] Help topic `touch-id-protection` registered.
- [ ] Full suite green; Release build clean; grep bans clean.

---

## Phase B — OTP display (TOTP / HOTP)

### B.1 — Domain: `OTPSecret` + `OTPAuthURIParser`

**Description:** Pure-Swift domain types and parser for `otpauth://` URIs (RFC 6238 / RFC 4226). Must mirror `PassSecret` non-leaking shape.

**Agent:** smart-worker

**Files:**
- ADD `Kizba/Domain/Models/OTPSecret.swift`:
  ```swift
  public struct OTPSecret: Sendable, Equatable {
      public enum Kind: Sendable, Equatable {
          case totp(period: TimeInterval)
          case hotp(counter: UInt64)
      }
      public enum Algorithm: String, Sendable {
          case sha1, sha256, sha512
      }
      public let kind: Kind
      public let secretBase32: String   // raw base32; do NOT log
      public let algorithm: Algorithm
      public let digits: Int
      public let label: String?
      public let issuer: String?

      public init(kind: Kind, secretBase32: String, algorithm: Algorithm,
                  digits: Int, label: String?, issuer: String?)
  }
  // Intentionally NOT Codable, NOT CustomStringConvertible.
  ```
- ADD `Kizba/Domain/Services/OTPAuthURIParser.swift`:
  ```swift
  public enum OTPAuthURIParserError: Error, Equatable {
      case invalidScheme
      case unsupportedKind(String)
      case missingSecret
      case invalidBase32
      case unknownAlgorithm(String)
      case invalidDigits
      case invalidPeriod
      case invalidCounter
      case malformedURI
  }
  public struct OTPAuthURIParser {
      public static func parse(_ uri: String) throws -> OTPSecret
  }
  ```
  Parsing rules:
  - Scheme `otpauth`; host `totp` | `hotp`.
  - `secret` query param required; base32 case-insensitive, `=` padding optional.
  - `algorithm` default `SHA1`; SHA1/SHA256/SHA512 case-insensitive.
  - `digits` default `6`; clamp `[6, 8]`.
  - `period` default `30`; reject `≤ 0`.
  - `counter` required for HOTP.
  - `label` from URL path (minus leading `/`); split into `issuer:account` if `:` present.
  - `issuer` query param wins over label prefix.

**Tests:**
- ADD `KizbaTests/Domain/OTPAuthURIParserTests.swift` (≥12 cases):
  - RFC sample `otpauth://totp/ACME:alice@google.com?secret=JBSWY3DPEHPK3PXP&issuer=ACME`.
  - HOTP with counter.
  - Missing secret → `.missingSecret`.
  - Invalid scheme → `.invalidScheme`.
  - Unsupported host → `.unsupportedKind`.
  - Custom `period=60`, `algorithm=SHA512`, `digits=8`.
  - `digits=5` → `.invalidDigits`.
  - Issuer query overrides label.
  - Invalid base32 → `.invalidBase32`.
  - Lowercase base32 accepted.
  - URL-encoded label.

**Verification:**
```sh
xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' \
  -only-testing:KizbaTests/OTPAuthURIParserTests
```

**Branch:** `mvp7/b1-otp-domain-and-parser`
**Commit:** `feat(otp): OTPSecret model and otpauth URI parser (MVP7.B.1)`
**Difficulty:** M
**Risks:** Base32 edge cases (padding, lowercase). Covered by tests.

---

### B.2 — Infrastructure: `OTPGenerating` + `LiveOTPGenerator`

**Description:** HMAC TOTP/HOTP generator via `CryptoKit` + small Base32 decoder.

**Agent:** smart-worker

**Files:**
- ADD `Kizba/Domain/Protocols/OTPGenerating.swift`:
  ```swift
  public protocol OTPGenerating: Sendable {
      func generate(_ secret: OTPSecret, at date: Date) -> String
  }
  ```
- ADD `Kizba/Infrastructure/OTP/LiveOTPGenerator.swift`:
  - `public struct LiveOTPGenerator: OTPGenerating`.
  - TOTP: `counter = UInt64(date.timeIntervalSince1970 / period)`.
  - HOTP: counter from `OTPSecret.kind`.
  - HMAC via `CryptoKit`: `HMAC<SHA1>.authenticationCode(for: counterBigEndianBytes, using: SymmetricKey(data: keyBytes))` (and SHA256/SHA512).
  - Dynamic truncation per RFC 4226 §5.3; modulo `10^digits`; zero-pad to `digits`.
- ADD `Kizba/Infrastructure/OTP/Base32.swift`:
  - `enum Base32 { static func decode(_ s: String) -> Data? }`.
  - Uppercase input, strip `=` and whitespace; nil on invalid char.

**Tests:**
- ADD `KizbaTests/Infrastructure/LiveOTPGeneratorTests.swift`:
  - RFC 6238 vectors (secret `12345678901234567890` ASCII → base32 `GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ`):
    - `T=59` → `94287082` (SHA1, digits=8).
    - `T=1111111109` → `07081804`.
    - `T=1234567890` → `89005924`.
    - `T=2000000000` → `69279037`.
  - RFC 4226 HOTP vectors (counter 0–9), SHA1, digits=6.
  - SHA256 / SHA512 vectors (RFC 6238 Appendix B).
- ADD `KizbaTests/Infrastructure/Base32Tests.swift`:
  - Empty → empty.
  - `"MY======"` → `0x66`.
  - Lowercase accepted.
  - Whitespace stripped.
  - Invalid char → nil.

**Verification:**
```sh
xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' \
  -only-testing:KizbaTests/LiveOTPGeneratorTests \
  -only-testing:KizbaTests/Base32Tests
```

**Branch:** `mvp7/b2-otp-generator`
**Commit:** `feat(otp): LiveOTPGenerator with CryptoKit HMAC + Base32 decoder (MVP7.B.2)`
**Difficulty:** M
**Risks:** Counter endianness (must be big-endian 8-byte). Covered by RFC vectors.

---

### B.3 — `PassSecret.otpSecret` discovery

**Description:** Surface OTP discovery as computed property on `PassSecret`.

**Agent:** smart-worker

**Files:**
- MOD `Kizba/Domain/Models/PassSecret.swift`:
  - Add `public var otpSecret: OTPSecret? { OTPDiscovery.firstOTPSecret(in: self) }`.
  - Keep non-Codable / non-CustomStringConvertible shape.
- ADD `Kizba/Domain/Services/OTPDiscovery.swift`:
  - `enum OTPDiscovery { static func firstOTPSecret(in secret: PassSecret) -> OTPSecret? }`.
  - Search order:
    1. `secret.metadata.first { $0.key.lowercased() == "otpauth" }?.value`.
    2. First line of `secret.extra` / notes starting with `otpauth://` (trimmed).
  - On parse failure → return `nil` silently.

**Tests:**
- ADD `KizbaTests/Domain/OTPDiscoveryTests.swift` (≥5):
  - Metadata key match.
  - Extra line match.
  - Metadata wins when both present.
  - No OTP → nil.
  - Invalid URI → nil (silent).
  - Mixed-case key `"OTPAuth"` matched.

**Verification:**
```sh
xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' \
  -only-testing:KizbaTests/OTPDiscoveryTests
```

**Branch:** `mvp7/b3-otp-discovery`
**Commit:** `feat(otp): PassSecret.otpSecret discovery from metadata and extra (MVP7.B.3)`
**Difficulty:** S
**Risks:** none material.

---

### B.4 — Presentation: `OTPModel` + `OTPView`

**Description:** Live OTP code with refresh loop, progress indicator, Touch-ID-gated copy.

**Agent:** smart-worker

**Files:**
- ADD `Kizba/Presentation/Features/EntryDetail/OTPModel.swift`:
  ```swift
  @Observable
  @MainActor
  public final class OTPModel {
      public private(set) var currentCode: String = ""
      public private(set) var remainingSeconds: Double = 0
      public private(set) var progressFraction: Double = 0   // 0...1, drains over period

      private let secret: OTPSecret
      private let generator: any OTPGenerating
      private let clock: any ClockServicing
      private let gate: BiometricGate
      private let clipboard: any ClipboardServicing
      private var refreshTask: Task<Void, Never>?

      public init(secret: OTPSecret, generator: any OTPGenerating,
                  clock: any ClockServicing, gate: BiometricGate,
                  clipboard: any ClipboardServicing)

      public func start()
      public func stop()
      public func requestCopy() async
  }
  ```
  - Tick ~250 ms; recompute `currentCode` only when `floor(now/period)` rolls over.
  - HOTP shows current counter code only (no manual advance in MVP7).
  - `start()` idempotent.
- ADD `Kizba/Presentation/Features/EntryDetail/OTPView.swift`:
  - Code in groups of 3 digits (e.g. `123 456`), monospaced via DS token.
  - Circular progress ring or bar showing `progressFraction`; tints `theme.colors.warning` when `remainingSeconds < 5` (TOTP only).
  - Copy button via `await model.requestCopy()`; `.help("Copy current OTP code")`; accessibility label `"Copy one-time code"`.
  - Respect `@Environment(\.accessibilityReduceMotion)` — static remaining-seconds label when reduce-motion on.
  - DS tokens only.
- MOD `Kizba/Presentation/Features/EntryDetail/EntryDetailView.swift`:
  - When `entry.otpSecret != nil` AND `SettingsKeys.otpDisplayEnabled` (B.5) true — render OTP section above metadata.
  - `.onAppear { otpModel.start() }` / `.onDisappear { otpModel.stop() }`.
- MOD `Kizba/App/AppEnvironment.swift`:
  - `live()`: inject `LiveOTPGenerator()`, `LiveClock` (or equivalent).
  - `preview()`: inject fake generator returning `"123456"` for deterministic snapshots.

**Tests:**
- ADD `KizbaTests/Presentation/OTPModelTests.swift`:
  - `start_emitsInitialCode`.
  - `start_recomputesCodeOnPeriodBoundary` (FakeClock).
  - `progressFraction_drainsLinearly`.
  - `stop_cancelsRefreshTask`.
  - `requestCopy_policyOnSuccess_writesCodeToClipboard`.
  - `requestCopy_policyOnCancelled_doesNotWrite`.

**Verification:**
```sh
xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' \
  -only-testing:KizbaTests/OTPModelTests
xcodebuild build -scheme Kizba -project Kizba.xcodeproj -configuration Release \
  -destination 'platform=macOS'
```

**Branch:** `mvp7/b4-otp-ui`
**Commit:** `feat(otp): OTPModel + OTPView with gated copy and progress indicator (MVP7.B.4)`
**Difficulty:** M
**Risks:** Refresh-task leaks if `stop()` not called — covered by `onDisappear` + test. Reuse existing `ClockServicing`/`FakeClock` infra; verify exists, else add a tiny one.

---

### B.5 — Setting + Help topic

**Description:** Feature toggle for users who prefer to hide OTP UI; new Help topic.

**Agent:** smart-worker

**Files:**
- MOD `Kizba/Infrastructure/Settings/SettingsKeys.swift`:
  - `public static let otpDisplayEnabled = "otpDisplayEnabled"` default `true`.
- MOD `Kizba/Infrastructure/Settings/UserDefaultsSettingsStore.swift`:
  - Register default `true` in init.
- MOD `Kizba/Presentation/Features/Settings/SettingsModel.swift`:
  - Add `var otpDisplayEnabled: Bool` mirrored in snapshot.
- MOD `Kizba/Presentation/Features/Settings/Tabs/SecurityTab.swift`:
  - Toggle "Show one-time passwords (OTP)" with InfoTooltip: "When enabled, Kizba detects `otpauth://` URIs in entry metadata or notes and displays a live code. Copying the code is gated by Touch ID when that protection is enabled."
- ADD Help topic `otp-setup`:
  - Two ways to add OTP: `pass otp insert <entry>` (pass-otp extension) or manually append `otpauth: otpauth://totp/...` to metadata.
  - Note about TOTP vs HOTP, period, algorithm.
  - Cross-reference `touch-id-protection` topic.

**Tests:**
- UPDATE `SettingsModelTests` for new field.
- ADD Help-topic test asserting `otp-setup` registered.

**Verification:**
```sh
rg -n 'otpDisplayEnabled' Kizba/   # ≥3 sites
xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS'
```

**Branch:** `mvp7/b5-otp-setting-and-help`
**Commit:** `feat(otp): otpDisplayEnabled setting and otp-setup Help topic (MVP7.B.5)`
**Difficulty:** S
**Risks:** none material.

---

### B.6 — SourceGrep ban for `OTPSecret`

**Description:** Mirror PassSecret ban for OTPSecret.

**Agent:** smart-worker

**Files:**
- MOD `KizbaTests/SourceGrepTests.swift`:
  - Add `testOTPSecretIsNotCodableOrPrintable` mirroring existing `PassSecret` ban pattern.

**Tests:** the test itself.

**Verification:**
```sh
xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS' \
  -only-testing:KizbaTests/SourceGrepTests
```

**Branch:** `mvp7/b6-sourcegrep-otp-ban`
**Commit:** `test(grep): forbid Codable/CustomStringConvertible on OTPSecret (MVP7.B.6)`
**Difficulty:** S
**Risks:** none.

---

### Phase B acceptance criteria

- [ ] `OTPSecret`, `OTPAuthURIParser`, `OTPGenerating`, `LiveOTPGenerator`, `Base32`, `OTPDiscovery` exist.
- [ ] RFC 6238 (SHA1/256/512) and RFC 4226 vectors pass.
- [ ] `PassSecret.otpSecret` returns parsed secret on metadata/extra; nil on absence; silent on invalid.
- [ ] `EntryDetailView` renders OTP section when `entry.otpSecret != nil` and `otpDisplayEnabled == true`.
- [ ] OTP code refreshes on period boundary; progress indicator drains; warning tint last 5 s.
- [ ] OTP copy via `BiometricGate` (Phase A).
- [ ] Help topic `otp-setup` registered.
- [ ] SourceGrep bans `OTPSecret` non-conformances.
- [ ] Full suite green; Release build clean.

---

## Phase F — Final regression + docs

### F.1 — README + docs

**Files:**
- MOD `README.md`:
  - Touch ID section expanded: scope = reveal + sensitive copy + OTP copy.
  - New OTP section: detection, algorithms, period, RFC refs.
- MOD `.ai/decisions.md`:
  - MVP7 entry summarizing 5 open decisions + OTP discovery order.
- MOD `.ai/sequoia-smoke.md`:
  - MVP7 A rows + MVP7 B rows: "Open entry with otpauth metadata; verify code refreshes; copy with Touch ID enabled; cancel prompt; verify clipboard unchanged."
- MOD `.ai/a11y-audit.md`:
  - OTP checklist: monospaced font, group labeling, progress indicator accessible label, reduce-motion variant, copy button label.

### F.2 — Full regression

```sh
xcodebuild test -scheme Kizba -project Kizba.xcodeproj -destination 'platform=macOS'
xcodebuild build -scheme Kizba -project Kizba.xcodeproj -configuration Release -destination 'platform=macOS'
rg -n '\bas!\b' Kizba/
rg -n 'Logger.*stdin|print\(.*stdin' Kizba/ KizbaTests/
rg -n 'touchIDPerRevealEnabled' Kizba/           # only legacy + migration
rg -n 'touchIDForSensitiveActions' Kizba/        # ≥4 sites
rg -n 'BiometricGate' Kizba/                     # helper + 3+ call sites
rg -n 'OTPSecret' Kizba/                         # model + parser + discovery + presentation
rg -n 'auth\.authenticate\(reason:' Kizba/       # ONLY BiometricGate.swift
```

**Acceptance:**
- [ ] All tests pass; count ≥ 1070 + new tests.
- [ ] Release build clean.
- [ ] All grep bans clean.
- [ ] README, decisions.md, sequoia-smoke.md, a11y-audit.md updated.

**Branch:** `mvp7/f-final-regression-and-docs`
**Commit:** `docs(mvp7): README + decisions + smoke + a11y for Touch ID copy gate and OTP (MVP7.F)`
**Difficulty:** S–M
**Risks:** docs drift if A/B specs change late — write F.1 last.

---

## Suggested current step

Run **smart-worker** on **A.1 — `BiometricGate` helper extraction**.
