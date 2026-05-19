Phase: MVP9.2 (OTP UX expansion)
Status: COMPLETED

Next action: Phase 3 (Folder tree) when user confirms. Pending: фикс PassErrorMapper для bug на втором Маке после получения подтверждения от пользователя (Diagnostics stderr).

Notes:
- Base32.encode (RFC 4648, no padding) added in Infrastructure/OTP/Base32.swift. Symmetric inverse of the existing decoder; matches the otpauth:// URI convention used everywhere.
- OTPAuthURIBuilder (Domain/Services): inverse of OTPAuthURIParser. Omits sha1 / digits=6 / period=30 defaults per Google Authenticator KeyUriFormat; always emits HOTP counters; round-trips through the parser.
- OTPSecretGenerator (Domain/Services): three constructors — random() uses CryptoKit SymmetricKey(size: SymmetricKeySize(bitCount: 160)); fromPassphrase() takes SHA-256(passphrase).prefix(20) (deterministic — UI shows warning); fromBase32() normalises case/whitespace/padding and validates the RFC 4648 alphabet.
- QRCodeImage (DesignSystem/Components): native CoreImage CIFilter.qrCodeGenerator with 10x affine scale and `.interpolation(.none)`. White quiet-zone background lives inside the component (DesignSystem is exempt from the C.6 `Color.*` ban). Fallback to `theme.colors.surfaceSunken` on filter failure.
- OTPModel: existing requestCopy() preserved. New revealURI(), revealSecret(), revealQRPayload() all gated through BiometricGate with distinct reason strings ("Reveal OTP URI" / "Reveal OTP secret" / "Show OTP QR code"). copyRevealedExport(_:) routes through clipboard with the standard auto-clear delay.
- OTPView extended: "Copy" primary remains; new Export menu (square.and.arrow.up icon, `.menuStyle(.borderlessButton)`) with three reveal items. Sheets driven from optional `@State` so dismissal nils the cleartext.
- OTPRevealSheet (Features/EntryDetail): mono-styled value box with Copy + Done buttons + "anyone with this can generate codes" caption.
- OTPQRSheet (Features/EntryDetail): QRCodeImage + scan instructions + Done.
- EntryFormBody (Presentation/EntryForm): new "One-time password" FormSection after Notes. Shows "TOTP configured" + Remove when the draft already carries an `otpauth` metadata pair (case-insensitive key match — matches OTPDiscovery), otherwise "Add TOTP…" opens AddTOTPSheet. derivedIssuer(fromPath:) pure helper extracts the second-to-last path component as the issuer prefill.
- AddTOTPSheet (Features/EntryForm): segmented Picker over AddTOTPMethod {generateRandom, passphrase, pasteURI, typeSecret}. Common issuer + account fields. Submission goes through pure `AddTOTPSheet.buildSecret(method:issuer:label:passphrase:pastedURI:typedSecret:) -> Result<OTPSecret, SubmissionError>`; the resulting OTPSecret is serialised back via OTPAuthURIBuilder and appended to the draft as MetadataPair(key: "otpauth", value: uri).
- Storage convention (locked in MVP9): otpauth URI lives in metadata key "otpauth" (case-insensitive). OTPDiscovery already supports this via its Convention #1.
- Deferred from MVP9 scope: (f) Import from QR code (camera/picture) — requires Vision framework + AVCaptureDevice / camera permission, separate scope.
- Tests: 55 new total (10 Base32 encoder vectors + roundtrips; 12 OTPAuthURIBuilder default-omission / non-default / roundtrip; 15 OTPSecretGenerator random/deterministic/normalisation; 2 QRCodeImage smoke; 13 AddTOTPSheet.buildSecret per-branch + error-message; 3 EntryFormBody.derivedIssuer).
- Full suite: 1193 tests, 17 skipped, 0 failures (was 1140 — net +53; the AddTOTPSheet test file's 13 cases plus 40 across the other 5 files). Release build clean.
- `as!` greps: 0. stdin-logging greps: 0 (only the ban definition in SourceGrepTests).
- Commits on main:
    d18f45f (2a) — Base32 encoder + OTPAuthURIBuilder + OTPSecretGenerator
    8c3946e (2b) — QRCodeImage DS component
    75575fb (2c) — OTPView Export menu + reveal/QR sheets
    b88d591 (2d) — AddTOTPSheet + EntryFormBody integration

Timestamp: 2026-05-19T14:35:21+0200
