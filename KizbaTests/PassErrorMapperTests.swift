//
//  PassErrorMapperTests.swift
//  KizbaTests
//
//  Unit tests for `PassErrorMapper` (Phase 4.3). All tests are pure
//  string-level checks: no fixtures from disk, no shell, no IO.
//

import XCTest
@testable import Kizba

final class PassErrorMapperTests: XCTestCase {

    // MARK: - Mapping

    func testDecryptionFailureMapsToDecryptionFailed() {
        let stderr = """
        gpg: decryption failed: No secret key
        gpg: encrypted with RSA key, ID ABCDEF1234567890
        gpg:                 alice@example.com
        """

        let result = PassErrorMapper.map(stderr: stderr, exitCode: 2)

        guard case let .decryptionFailed(excerpt) = result.error else {
            XCTFail("Expected .decryptionFailed, got \(result.error)")
            return
        }
        XCTAssertEqual(excerpt, result.excerpt)

        // Excerpt must NOT carry raw email or raw long hex IDs.
        XCTAssertFalse(excerpt.contains("alice@example.com"), "email leaked: \(excerpt)")
        XCTAssertFalse(excerpt.contains("ABCDEF1234567890"), "key id leaked: \(excerpt)")
        XCTAssertTrue(excerpt.contains("<redacted-email>"))
        XCTAssertTrue(excerpt.contains("<redacted-id>"))
    }

    func testPinentryMapsToPinentryNotConfigured() {
        let stderr = "gpg: problem with the agent: No pinentry"

        let result = PassErrorMapper.map(stderr: stderr, exitCode: 2)

        XCTAssertEqual(result.error, .pinentryNotConfigured)
        XCTAssertFalse(result.excerpt.isEmpty)
    }

    func testInappropriateIoctlMapsToPinentryNotConfigured() {
        let stderr = "gpg: signal Inappropriate ioctl for device"

        let result = PassErrorMapper.map(stderr: stderr, exitCode: 2)

        XCTAssertEqual(result.error, .pinentryNotConfigured)
    }

    func testBinaryNotFoundMapsToBinaryNotFound_pathShape() {
        let stderr = "/usr/bin/pass: No such file or directory"

        let result = PassErrorMapper.map(stderr: stderr, exitCode: 127)

        guard case let .binaryNotFound(name) = result.error else {
            XCTFail("Expected .binaryNotFound, got \(result.error)")
            return
        }
        XCTAssertEqual(name, "pass")
    }

    func testBinaryNotFoundMapsToBinaryNotFound_commandNotFoundShape() {
        let stderr = "zsh: command not found: gpg"

        let result = PassErrorMapper.map(stderr: stderr, exitCode: 127)

        guard case let .binaryNotFound(name) = result.error else {
            XCTFail("Expected .binaryNotFound, got \(result.error)")
            return
        }
        XCTAssertEqual(name, "gpg")
    }

    func testTimeoutByExitCode() {
        let result = PassErrorMapper.map(stderr: "", exitCode: PassErrorMapper.timeoutExitCode)
        XCTAssertEqual(result.error, .timedOut)
    }

    func testTimeoutByStderrText() {
        let result = PassErrorMapper.map(
            stderr: "operation timed out after 120s",
            exitCode: 1
        )
        XCTAssertEqual(result.error, .timedOut)
    }

    func testUnknownFallbackShellFailure() {
        let stderr = "something unusual happened in the world today"

        let result = PassErrorMapper.map(stderr: stderr, exitCode: 5)

        guard case let .shellFailure(code, excerpt) = result.error else {
            XCTFail("Expected .shellFailure, got \(result.error)")
            return
        }
        XCTAssertEqual(code, 5)
        XCTAssertEqual(excerpt, result.excerpt)
        XCTAssertTrue(excerpt.contains("unusual"))
    }

    // MARK: - Sanitisation

    func testSanitizeRedactsEmailAndHex() {
        let raw = """
        gpg: encrypted for alice@example.com
        gpg: key ID DEADBEEFCAFE1234 unavailable
        """

        let cleaned = PassErrorMapper.sanitize(raw)

        XCTAssertFalse(cleaned.contains("alice@example.com"))
        XCTAssertFalse(cleaned.contains("DEADBEEFCAFE1234"))
        XCTAssertTrue(cleaned.contains("<redacted-email>"))
        XCTAssertTrue(cleaned.contains("<redacted-id>"))

        // Whitespace runs (incl. the embedded newline) collapsed to a
        // single space — excerpt fits one UI line.
        XCTAssertFalse(cleaned.contains("\n"))
        XCTAssertFalse(cleaned.contains("  "))
    }

    func testSanitizeEnforcesLengthLimit() {
        let raw = String(repeating: "x", count: 1000)
        let cleaned = PassErrorMapper.sanitize(raw, maxLength: 32)

        XCTAssertEqual(cleaned.count, 32)
        XCTAssertTrue(cleaned.hasSuffix("…"))
    }

    func testSanitizeShortStringIsLeftIntact() {
        let raw = "short and harmless"
        let cleaned = PassErrorMapper.sanitize(raw)
        XCTAssertEqual(cleaned, "short and harmless")
    }

    func testSanitizeIdempotent() {
        let raw = """
          gpg: decryption failed for alice@example.com\n\n
          key ABCDEF1234567890 unavailable, please retry on\n
          \(String(repeating: "y", count: 600))
        """

        let once = PassErrorMapper.sanitize(raw)
        let twice = PassErrorMapper.sanitize(once)

        XCTAssertEqual(once, twice, "sanitize must be idempotent")
    }

    func testSanitizeIdempotent_atExactCap() {
        // Boundary: input that lands exactly at maxLength after pass 1
        // must round-trip through pass 2 unchanged.
        // Use a non-hex character so the long-hex redaction does not
        // collapse the input into the short token "<redacted-id>".
        let raw = String(repeating: "z", count: 500)
        let cleaned = PassErrorMapper.sanitize(raw, maxLength: 64)
        let again = PassErrorMapper.sanitize(cleaned, maxLength: 64)

        XCTAssertEqual(cleaned.count, 64)
        XCTAssertEqual(cleaned, again)
    }

    func testMapperExcerptIsAlwaysSanitised() {
        // Even on the fallback path, the excerpt embedded in the error
        // must equal the sanitised one returned alongside it.
        let raw = "weird failure with key ABCDEF1234567890 and bob@example.com"
        let result = PassErrorMapper.map(stderr: raw, exitCode: 9)

        guard case let .shellFailure(_, excerpt) = result.error else {
            return XCTFail("expected .shellFailure")
        }
        XCTAssertEqual(excerpt, result.excerpt)
        XCTAssertFalse(excerpt.contains("bob@example.com"))
        XCTAssertFalse(excerpt.contains("ABCDEF1234567890"))
    }

    // MARK: - Write-side: entryAlreadyExists (Phase E.4)

    func testEntryAlreadyExists_cowardlyRefusing() {
        // pass 1.7.3 / 1.7.4 emits this when `pass insert` is invoked
        // on an existing entry without `-f`.
        let stderr = "Cowardly refusing to overwrite '/Users/x/.password-store/foo/bar.gpg'\n"

        let result = PassErrorMapper.map(stderr: stderr, exitCode: 1)

        guard case let .entryAlreadyExists(path) = result.error else {
            XCTFail("Expected .entryAlreadyExists, got \(result.error)")
            return
        }
        XCTAssertEqual(path, "foo/bar")
    }

    func testEntryAlreadyExists_alreadyExistsBareForm() {
        // pass 1.7.3 emits this from `pass generate` when the entry
        // already exists and `-f` is absent.
        let stderr = "Error: foo/bar already exists.\n"

        let result = PassErrorMapper.map(stderr: stderr, exitCode: 1)

        guard case let .entryAlreadyExists(path) = result.error else {
            XCTFail("Expected .entryAlreadyExists, got \(result.error)")
            return
        }
        XCTAssertEqual(path, "foo/bar")
    }

    func testEntryAlreadyExists_mvRefusingToOverwrite() {
        // mv(1) underlies `pass mv`; on a destination collision it
        // surfaces this stderr verbatim through pass.
        let stderr = "mv: refusing to overwrite '/Users/x/.password-store/foo/baz.gpg'\n"

        let result = PassErrorMapper.map(stderr: stderr, exitCode: 1)

        guard case let .entryAlreadyExists(path) = result.error else {
            XCTFail("Expected .entryAlreadyExists, got \(result.error)")
            return
        }
        XCTAssertEqual(path, "foo/baz")
    }

    func testEntryAlreadyExists_withoutQuotedPath_returnsEmptyString() {
        // Path-extraction edge case: the "already exists" sentinel
        // appears but there's no recognisable path before it. The
        // mapper still constructs the case (just with an empty path)
        // so the form layer can render a generic message.
        let stderr = "Error: already exists.\n"

        let result = PassErrorMapper.map(stderr: stderr, exitCode: 1)

        guard case let .entryAlreadyExists(path) = result.error else {
            XCTFail("Expected .entryAlreadyExists, got \(result.error)")
            return
        }
        XCTAssertEqual(path, "")
    }

    // MARK: - Write-side: recipientNotFound (Phase E.4)

    func testRecipientNotFound_email() {
        let stderr = "gpg: alice@example.com: skipped: No public key\n"

        let result = PassErrorMapper.map(stderr: stderr, exitCode: 2)

        guard case let .recipientNotFound(id) = result.error else {
            XCTFail("Expected .recipientNotFound, got \(result.error)")
            return
        }
        // Error payload carries the EXTRACTED email so the form layer
        // can render contextual help. Sanitisation belongs to the
        // accompanying excerpt only.
        XCTAssertEqual(id, "alice@example.com")
    }

    func testRecipientNotFound_hexKeyId() {
        let stderr = "gpg: 0123456789ABCDEF: skipped: No public key\n"

        let result = PassErrorMapper.map(stderr: stderr, exitCode: 2)

        guard case let .recipientNotFound(id) = result.error else {
            XCTFail("Expected .recipientNotFound, got \(result.error)")
            return
        }
        XCTAssertEqual(id, "0123456789ABCDEF")
    }

    func testRecipientNotFound_stdinShape_fallsBackToEmpty() {
        // `gpg: [stdin]: encryption failed: No public key` carries no
        // usable identifier — the parser rejects the sentinel `[stdin]`
        // token and falls back to an empty string.
        let stderr = "gpg: [stdin]: encryption failed: No public key\n"

        let result = PassErrorMapper.map(stderr: stderr, exitCode: 2)

        guard case let .recipientNotFound(id) = result.error else {
            XCTFail("Expected .recipientNotFound, got \(result.error)")
            return
        }
        XCTAssertEqual(id, "")
    }

    func testRecipientNotFound_excerptRedactsEmail_payloadKeepsIt() {
        let stderr = "gpg: alice@example.com: skipped: No public key\n"

        let result = PassErrorMapper.map(stderr: stderr, exitCode: 2)

        guard case let .recipientNotFound(id) = result.error else {
            XCTFail("Expected .recipientNotFound, got \(result.error)")
            return
        }
        // Payload preserves the identifier (form-layer needs it).
        XCTAssertEqual(id, "alice@example.com")
        // Sanitised excerpt must NOT leak it.
        XCTAssertFalse(result.excerpt.contains("alice@example.com"))
        XCTAssertTrue(result.excerpt.contains("<redacted-email>"))
    }

    func testRecipientNotFound_excerptRedactsHexId_payloadKeepsIt() {
        let stderr = "gpg: 0123456789ABCDEF: skipped: No public key\n"

        let result = PassErrorMapper.map(stderr: stderr, exitCode: 2)

        guard case let .recipientNotFound(id) = result.error else {
            XCTFail("Expected .recipientNotFound, got \(result.error)")
            return
        }
        XCTAssertEqual(id, "0123456789ABCDEF")
        XCTAssertFalse(result.excerpt.contains("0123456789ABCDEF"))
        XCTAssertTrue(result.excerpt.contains("<redacted-id>"))
    }

    // MARK: - Write-side: invalidLength (Phase E.4)

    func testInvalidLength_quotedToken() {
        let stderr = "Error: pass-length \"abc\" must be a positive integer.\n"

        let result = PassErrorMapper.map(stderr: stderr, exitCode: 1)

        XCTAssertEqual(result.error, .invalidLength)
    }

    func testInvalidLength_bareForm() {
        let stderr = "Error: pass-length must be a positive integer.\n"

        let result = PassErrorMapper.map(stderr: stderr, exitCode: 1)

        XCTAssertEqual(result.error, .invalidLength)
    }

    // MARK: - Write-side: invalidGpgId (Phase E.4)

    func testInvalidGpgId_passwordStoreEmpty() {
        let stderr = "Error: password store is empty. Try \"pass init\".\n"

        let result = PassErrorMapper.map(stderr: stderr, exitCode: 1)

        XCTAssertEqual(result.error, .invalidGpgId)
    }

    func testInvalidGpgId_youMustRunPassInit() {
        let stderr = "You must run \"pass init\" first.\n"

        let result = PassErrorMapper.map(stderr: stderr, exitCode: 1)

        XCTAssertEqual(result.error, .invalidGpgId)
    }

    // MARK: - Disambiguation: "is not in the password store" (Phase E.4)

    func testIsNotInPasswordStore_moveContext_mapsToSourceNotFound() {
        let stderr = "Error: foo/bar is not in the password store.\n"

        let result = PassErrorMapper.map(
            stderr: stderr,
            exitCode: 1,
            commandContext: .move
        )

        guard case let .sourceNotFound(path) = result.error else {
            XCTFail("Expected .sourceNotFound, got \(result.error)")
            return
        }
        XCTAssertEqual(path, "foo/bar")
    }

    func testIsNotInPasswordStore_removeContext_mapsToSourceNotFound() {
        let stderr = "Error: foo/bar is not in the password store.\n"

        let result = PassErrorMapper.map(
            stderr: stderr,
            exitCode: 1,
            commandContext: .remove
        )

        guard case let .sourceNotFound(path) = result.error else {
            XCTFail("Expected .sourceNotFound, got \(result.error)")
            return
        }
        XCTAssertEqual(path, "foo/bar")
    }

    func testIsNotInPasswordStore_showContext_mapsToInvalidGpgId() {
        // Same stderr surfaced by `pass show` against an uninitialised
        // store; the read-side default is `.invalidGpgId` so onboarding
        // is offered.
        let stderr = "Error: foo/bar is not in the password store.\n"

        let result = PassErrorMapper.map(
            stderr: stderr,
            exitCode: 1,
            commandContext: .show
        )

        XCTAssertEqual(result.error, .invalidGpgId)
    }

    func testIsNotInPasswordStore_nilContext_mapsToInvalidGpgId() {
        // No context ⇒ historic read-side behaviour preserved.
        let stderr = "Error: foo/bar is not in the password store.\n"

        let result = PassErrorMapper.map(stderr: stderr, exitCode: 1)

        XCTAssertEqual(result.error, .invalidGpgId)
    }

    // MARK: - Idempotency (Phase E.4)

    func testWriteSideMapping_isIdempotent() {
        // Two consecutive maps of the same input must produce equal
        // results — the mapper is stateless and pure.
        let stderr = "Cowardly refusing to overwrite '/Users/x/.password-store/foo/bar.gpg'\n"

        let first = PassErrorMapper.map(stderr: stderr, exitCode: 1, commandContext: .insert)
        let second = PassErrorMapper.map(stderr: stderr, exitCode: 1, commandContext: .insert)

        XCTAssertEqual(first.error, second.error)
        XCTAssertEqual(first.excerpt, second.excerpt)
    }
}
