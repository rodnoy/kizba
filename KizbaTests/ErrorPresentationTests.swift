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
}
