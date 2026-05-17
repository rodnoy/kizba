Phase: MVP6.D.1
Status: COMPLETED

Next action: Run smart-worker on Task D.2 (SecurityTab UI gating + auth-failure banner)

Notes:
- SettingsModel.init extended with biometricAuth: (any BiometricAuthenticating)? = nil (default nil for backward compatibility with existing tests/previews).
- Public API:
  * var biometricAvailability: BiometricAvailability (computed from injected auth or .unavailable(.hardwareUnavailable) fallback).
  * enum ToggleBiometricError: Error, Equatable { case unavailable(_), case cancelled, case failed(_) } — annotated `public nonisolated`.
  * func requestToggleBiometric(_ desired: Bool) async -> Result<Void, ToggleBiometricError>.
- Init param order: (settings:, discovery:, recentStore:, biometricAuth: = nil, savedFlashDuration: = .milliseconds(1500)).
- Semantics:
  * Enable: persists without prompt (matches FileVault/Touch ID UX).
  * Disable: requires biometric auth via `authenticate(reason:)`; on cancel/fail — no persist, returns failure for UI to display.
  * No authenticator wired (nil) → disable permitted without prompt (safe for tests/preview).
  * After successful persist — initialSnapshot refreshed to keep hasChanges (B.2 dirty tracking) honest.
- AppEnvironment ALREADY had `biometricAuth: (any BiometricAuthenticating)?` field wired to `LocalAuthBiometricAuthenticator()` in `live()` (no env edits required).
- KizbaApp Settings scene call-site updated: `SettingsModel(... biometricAuth: environment.biometricAuth)`.
- Required side-fix: domain biometric enums (BiometricUnavailableReason, BiometricAvailability, BiometricFailureReason, BiometricResult) annotated `public nonisolated`. Without this, the target's `default-isolation=MainActor` pinned their synthesized `Equatable` conformances to MainActor, and the nested nonisolated `ToggleBiometricError` enum refused to compose them under `InferIsolatedConformances` (Swift 6). Matches the same pattern already applied to `PassShowResult`.
- Decision documented in .ai/decisions.md (MVP6.D.1 entry, including the nonisolated rationale).
- Tests deferred to D.3 (Fake + 4 scenarios).
- Full suite: 1051 tests, 17 skipped, 0 failures (no new tests this task, exactly the G-phase baseline). Release build SUCCEEDED. Grep bans clean: `as!` 0 in Kizba/; `Logger.*stdin|print\(.*stdin` matches only self-references in SourceGrepTests; `requestToggleBiometric` appears only in SettingsModel.swift (D.2 will add SecurityTab call-site).
- Commit: 02d23ef on main.

Timestamp: 2026-05-17T18:17:00+02:00
