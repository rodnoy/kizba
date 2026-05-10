# Kizba — Code Review Checklist

Purpose: a short, mandatory checklist reviewers must follow for all PRs affecting Kizba source.

Checklist items:
- Security & secrets
  - Never log secret-bearing values (no printing of PassSecret, MetadataPair, SecretDraft contents).
  - No Logger/print strings that include the substring "stdin" (repo grep ban: `Logger.*stdin|print\(.*stdin`).
  - PassSecret, SecretDraft, MetadataPair, UndoableAction must not be made `Codable` or `CustomStringConvertible`/`CustomDebugStringConvertible`.

- Concurrency & safety
  - Respect strict concurrency rules. No `@unchecked Sendable` except where explicitly documented in .ai/decisions.md.
  - Prefer `@Observable` for presentation models; `Presentation/**/*Model.swift` files with `final class ...Model` must contain `@Observable` unless explicitly allow-listed.

- Presentation & models
  - Do NOT construct model instances inside `.sheet`, `.popover`, or `.fullScreenCover` closure bodies. Use `@State`, `@StateObject`, or create models outside the closure.
  - Avoid `.onChange(of: enumWithAssoc)` patterns — prefer derived stable `stateID: Int` or other stable identifiers.
  - Inline styling is banned in `Kizba/Presentation/**` outside `DesignSystem/`.

- API & logging
  - No `as!` in Sources/ production code.
  - Use structured logging; never emit PII or secret content. Log counts or sanitized excerpts only.

- Touch ID / LocalAuthentication
  - Do not leak LAError codes or context strings beyond the LocalAuthBiometricAuthenticator implementation. Map errors to domain enums before surface.

- Tests & fixtures
  - Tests must be deterministic and not depend on external network/FS unless behind opt-in env vars (KIZBA_E2E, KIZBA_FSEVENTS_TEST).
  - New fixtures belong in `KizbaTests/Fixtures/` or `Kizba/Presentation/SourceGrepFixtures/` (for grep-only tests); avoid adding long-running or platform-specific tests by default.

- Allow-list policy
  - If you must opt out of a grep rule, add an inline file-scoped comment (exact token) to the file:
    - `// kizba:not-observable-model` to skip the @Observable rule
    - `// kizba:allow-sheet-init` to skip the sheet-init constructor rule
  - A PR that includes an allow-list must include a code-review comment justifying the exception.

- Commit message & PR hygiene
  - All commit messages and PR descriptions must be in English and concise. Mention changed phases (e.g., "feat(mvp3): ...").
  - Ensure `xcodebuild test` passes locally before requesting review.

How to use this checklist
- Reviewers: consult this file and mark each item in review comments or checklist in PR template.
