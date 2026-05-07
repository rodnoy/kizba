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
}
