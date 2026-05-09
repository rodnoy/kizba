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

    func testInvalidLengthMapsToSilent() {
        // Length validation is a form-level concern; if it slips
        // through, the global surface stays quiet rather than confusing
        // the user with an out-of-context toast.
        let pres = ErrorPresentation.present(for: .invalidLength)
        guard case .silent = pres else {
            return XCTFail("Expected .silent, got \(pres)")
        }
    }
}
