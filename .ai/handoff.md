Phase: MVP7 (PLANNING)
Status: Plan written; ready to execute

Next action: Run smart-worker on Task A.1 (BiometricGate helper extraction) from .ai/plan.md.

Notes:
- MVP7 scope: Phase A (Touch ID copy gate) + Phase B (OTP display TOTP/HOTP). Phase F = polish/docs/regression.
- Browser extension / AutoFill remains explicitly deferred (separate-product complexity per analysis).
- Global hotkey remains deferred per MVP5/6 decisions.
- 10 tasks total: A.1, A.2, A.3, A.4, B.1, B.2, B.3, B.4, B.5, B.6, F.
- 5 open decisions locked: single setting + migration, username ungated, metadata whitelist (password/pin/token/secret/otpauth/key), MenuBar password gated, silent skip on cancel.
- Foundation reuse: existing BiometricAuthenticating + LocalAuthBiometricAuthenticator + FakeBiometricAuthenticator + ClipboardServicing.
- RFC vectors for OTP: 6238 (SHA1/256/512) + 4226 (HOTP counter 0-9).
- Suite baseline: 1070 tests, 0 failures.

Timestamp: 2026-05-18T00:06:21+0200
