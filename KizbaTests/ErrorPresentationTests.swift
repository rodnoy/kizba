//
// ErrorPresentationTests.swift
// KizbaTests
//
// Unit tests for ErrorPresentation mapping from PassError cases.
//

import XCTest
@testable import Kizba

final class ErrorPresentationTests: XCTestCase {

    func testBinaryNotFoundPassMapsToEmptyStateWithPassKey() {
        let pres = ErrorPresentation.present(for: .binaryNotFound("pass"))
        guard case let .emptyState(nudge) = pres else {
            return XCTFail("Expected .emptyState, got \(pres)")
        }
        XCTAssertEqual(nudge.settingKey, SettingsKeys.passBinaryOverride)
    }

    func testPinentryNotConfiguredMapsToBannerWithHelpURL() {
        let pres = ErrorPresentation.present(for: .pinentryNotConfigured)
        guard case let .banner(_, helpURL) = pres else {
            return XCTFail("Expected .banner, got \(pres)")
        }
        XCTAssertNotNil(helpURL)
    }

    func testDecryptionFailedMapsToInlineWithDiagnosticsContainingExcerpt() {
        let excerpt = "sanitised stderr excerpt"
        let pres = ErrorPresentation.present(for: .decryptionFailed(stderrExcerpt: excerpt))
        guard case let .inlineWithDiagnostics(message) = pres else {
            return XCTFail("Expected .inlineWithDiagnostics, got \(pres)")
        }
        XCTAssertTrue(message.contains(excerpt))
    }

    func testTimedOutMapsToToastWithDiagnostics() {
        let pres = ErrorPresentation.present(for: .timedOut)
        guard case .toastWithDiagnostics = pres else {
            return XCTFail("Expected .toastWithDiagnostics, got \(pres)")
        }
    }

    // MARK: - Phase D.6 write-side mappings

    func testEntryAlreadyExistsMapsToSilent() {
        // The form renders the inline "Overwrite?" banner directly from
        // `error.inlineRecoverable`; the global presentation surface
        // stays out of the way.
        let pres = ErrorPresentation.present(for: .entryAlreadyExists(path: "a/b"))
        guard case .silent = pres else {
            return XCTFail("Expected .silent, got \(pres)")
        }
    }

    func testRecipientNotFoundMapsToBannerCarryingIdentifier() {
        let pres = ErrorPresentation.present(
            for: .recipientNotFound(emailOrKeyId: "alice@example.org")
        )
        guard case let .banner(message, helpURL) = pres else {
            return XCTFail("Expected .banner, got \(pres)")
        }
        XCTAssertTrue(
            message.contains("alice@example.org"),
            "banner message should mention the recipient (got \(message))"
        )
        XCTAssertNil(helpURL)
    }

    func testInvalidGpgIdMapsToOnboarding() {
        let pres = ErrorPresentation.present(for: .invalidGpgId)
        guard case let .onboarding(message) = pres else {
            return XCTFail("Expected .onboarding, got \(pres)")
        }
        XCTAssertFalse(message.isEmpty)
    }

    func testSourceNotFoundMapsToToastWithDiagnostics() {
        let pres = ErrorPresentation.present(for: .sourceNotFound(path: "vault/lost"))
        guard case let .toastWithDiagnostics(message) = pres else {
            return XCTFail("Expected .toastWithDiagnostics, got \(pres)")
        }
        XCTAssertTrue(
            message.contains("vault/lost"),
            "toast should mention the missing path (got \(message))"
        )
    }

    func testWriteFailedWithReasonMapsToToastWithDiagnosticsCarryingReason() {
        let pres = ErrorPresentation.present(for: .writeFailed(reason: "disk full"))
        guard case let .toastWithDiagnostics(message) = pres else {
            return XCTFail("Expected .toastWithDiagnostics, got \(pres)")
        }
        XCTAssertTrue(
            message.contains("disk full"),
            "toast should include the failure reason (got \(message))"
        )
    }

    func testWriteFailedWithoutReasonStillProducesToast() {
        let pres = ErrorPresentation.present(for: .writeFailed(reason: nil))
        guard case let .toastWithDiagnostics(message) = pres else {
            return XCTFail("Expected .toastWithDiagnostics, got \(pres)")
        }
        XCTAssertFalse(message.isEmpty)
    }

    func testRecipientKeyNotTrusted_mapsToBannerWithFixInstructions() {
        let pres = ErrorPresentation.present(
            for: .recipientKeyNotTrusted(keyHint: "ABCD1234EF")
        )
        guard case let .banner(message, helpURL) = pres else {
            return XCTFail("Expected .banner, got \(pres)")
        }
        // No external help link — the message itself carries the
        // complete actionable fix.
        XCTAssertNil(helpURL)
        // The fix command and trust value must appear verbatim so the
        // user can copy-paste them into Terminal.
        XCTAssertTrue(message.contains("gpg --edit-key"),
                      "message should mention the gpg --edit-key command (got \(message))")
        XCTAssertTrue(message.contains("trust"),
                      "message should mention the `trust` subcommand (got \(message))")
        XCTAssertTrue(message.contains("ABCD1234EF"),
                      "message should embed the keyHint when present (got \(message))")
        XCTAssertTrue(message.contains("--list-secret-keys"),
                      "message should tell the user how to find their key id (got \(message))")
    }

    func testRecipientKeyNotTrusted_nilHint_usesPlaceholder() {
        let pres = ErrorPresentation.present(
            for: .recipientKeyNotTrusted(keyHint: nil)
        )
        guard case let .banner(message, _) = pres else {
            return XCTFail("Expected .banner, got \(pres)")
        }
        XCTAssertTrue(message.contains("<your-key-id>"),
                      "message should include a placeholder when no hint is available (got \(message))")
    }

    func testInvalidLengthMapsToSilent() {
        // Length validation is a form-level concern; if it slips
        // through, the global surface stays quiet rather than confusing
        // the user with an out-of-context toast.
        let pres = ErrorPresentation.present(for: .invalidLength)
        guard case .silent = pres else {
            return XCTFail("Expected .silent, got \(pres)")
        }
    }

    // MARK: - MVP 4 git-side mappings (Phase A.3)

    func testGitNotInitialized_mapsToOnboarding() {
        let pres = ErrorPresentation.present(for: .gitNotInitialized)
        guard case let .onboarding(message) = pres else {
            return XCTFail("Expected .onboarding, got \(pres)")
        }
        XCTAssertTrue(
            message.contains("pass git init"),
            "onboarding message should mention `pass git init` (got \(message))"
        )
    }

    func testGitNoRemote_mapsToOnboarding() {
        let pres = ErrorPresentation.present(for: .gitNoRemote)
        guard case let .onboarding(message) = pres else {
            return XCTFail("Expected .onboarding, got \(pres)")
        }
        XCTAssertEqual(
            message,
            "No git remote configured. Add a remote to enable push and pull."
        )
    }

    func testGitAuthFailed_mapsToToastWithDiagnostics() {
        let pres = ErrorPresentation.present(for: .gitAuthFailed)
        guard case let .toastWithDiagnostics(message) = pres else {
            return XCTFail("Expected .toastWithDiagnostics, got \(pres)")
        }
        XCTAssertEqual(
            message,
            "Git authentication failed. Check your SSH keys or credentials."
        )
    }

    func testGitConflict_mapsToSilent() {
        let pres = ErrorPresentation.present(for: .gitConflict(paths: ["a.gpg"]))
        guard case .silent = pres else {
            return XCTFail("Expected .silent, got \(pres)")
        }
    }

    func testGitNetworkUnavailable_mapsToToastWithDiagnostics() {
        let pres = ErrorPresentation.present(for: .gitNetworkUnavailable)
        guard case let .toastWithDiagnostics(message) = pres else {
            return XCTFail("Expected .toastWithDiagnostics, got \(pres)")
        }
        XCTAssertEqual(
            message,
            "Network unavailable. Check your connection and try again."
        )
    }

    func testGitRejected_mapsToToastWithDiagnostics() {
        let reason = "non-fast-forward"
        let pres = ErrorPresentation.present(for: .gitRejected(reason: reason))
        guard case let .toastWithDiagnostics(message) = pres else {
            return XCTFail("Expected .toastWithDiagnostics, got \(pres)")
        }
        XCTAssertTrue(
            message.contains(reason),
            "message should include rejection reason (got \(message))"
        )
    }
}
