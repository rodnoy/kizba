import Foundation
import AppKit
import XCTest
@testable import Kizba

/// MVP9.2 — smoke test for the DesignSystem QR code component.
/// We don't try to scan-decode the bitmap (that needs the Vision
/// framework and is out of scope for MVP9); we only assert that
/// CoreImage successfully produces a non-empty `NSImage` for a
/// typical otpauth payload, which catches misconfigured filter
/// inputs and bad CIContext setups before they reach the UI.
final class QRCodeImageTests: XCTestCase {

    func testGenerate_typicalOTPAuthURI_returnsImage() {
        let payload = "otpauth://totp/Acme:alice?secret=JBSWY3DPEHPK3PXP&issuer=Acme"
        let image = QRCodeImage.generate(payload: payload)
        let unwrapped = try? XCTUnwrap(image)
        XCTAssertNotNil(unwrapped)
        XCTAssertGreaterThan(unwrapped?.size.width ?? 0, 0)
        XCTAssertGreaterThan(unwrapped?.size.height ?? 0, 0)
    }

    func testGenerate_emptyPayload_stillReturnsImage() {
        // CoreImage's QR generator accepts an empty payload and
        // emits a tiny but well-formed code. The view should not
        // crash, and `generate` should return non-nil.
        let image = QRCodeImage.generate(payload: "")
        XCTAssertNotNil(image)
    }
}
