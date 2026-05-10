# Files Retrieved
1. `Kizba/Infrastructure/Pass/PassErrorMapper.swift` - Pure static mapper from pass/gpg stderr to PassError + sanitised excerpt. 483 lines. Core logic: ordered pattern matching on lowercased stderr, path/recipient extraction helpers, sanitize pipeline (email/hex redaction, whitespace collapse, length cap).
2. `KizbaTests/PassErrorMapperTests.swift` - 32 tests covering read-side (decryption, pinentry, binary-not-found, timeout, fallback), sanitisation (redaction, length, idempotency), and write-side E.4 (entryAlreadyExists 4 shapes, recipientNotFound 3 shapes + redaction, invalidLength 2 shapes, invalidGpgId 2 shapes, "is not in password store" disambiguation 4 contexts, idempotency).
3. `KizbaTests/PassWriteIntegrationTests.swift` - References PassErrorMapper in comments only (lines 354, 510); no direct calls.

# Key Structures
- `PassErrorMapper.map(stderr:exitCode:commandContext:)` → `(error: PassError, excerpt: String)`
- `PassErrorMapper.sanitize(_:maxLength:)` → `String` (idempotent)
- `PassErrorMapper.CommandContext` enum: `.show`, `.list`, `.insert`, `.generate`, `.remove`, `.move`, `.initStore`
- Private helpers: `matchesAny`, `parseMissingBinaryName`, `parseEntryPath(from:signature:)`, `firstQuotedToken`, `relativeEntryPath`, `stripErrorLeader`, `parseRecipientIdentifier`, `replace(in:pattern:with:)`

# Architecture
- PassErrorMapper is pure (no IO, no logging, no state). Called by PassCLI methods after shell invocation fails.
- Sanitise pipeline: email regex → hex regex → whitespace collapse → trim → length cap. Idempotent by design.
- Path extraction: quoted token preferred (for "cowardly refusing" / "mv refusing"), fallback to text before "already exists" with Error: leader stripped.
- Recipient extraction: line-by-line scan for "no public key", extract identifier before first colon after "gpg:" prefix, reject [stdin] and "encryption failed".
- CommandContext disambiguates "is not in the password store": move/remove → sourceNotFound, else → invalidGpgId.

# Recommended Starting Point
All 32 tests pass. No code changes required. If extending coverage, add tests for untested stderr shapes: `"pass init <gpg-id> requires a key"`, `"secret key not available"`, `"could not find executable"`.

# Risks / Unknowns
1. `writeFailed(reason:)` PassError case exists in domain (per decisions.md Phase D) but is never mapped by PassErrorMapper — unclear if intentional or a gap.
2. `"gpg-agent"` substring match for pinentryNotConfigured may be overly broad — any stderr mentioning gpg-agent triggers it.
3. No test for the third invalidGpgId shape: `"Error: pass init <gpg-id> requires a key."`.
4. No test for `"secret key not available"` decryption shape or `"could not find executable"` binary shape (both are handled in code but untested).
