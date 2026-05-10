import XCTest
@testable import Kizba

final class BiometricAuthenticatingTests: XCTestCase {

    func testEnumsAreEquatable() {
        // Availability
        XCTAssertEqual(BiometricAvailability.available, .available)
        XCTAssertNotEqual(BiometricAvailability.available, .unavailable(.notEnrolled))

        // Unavailable reasons
        XCTAssertEqual(BiometricUnavailableReason.notEnrolled, .notEnrolled)
        XCTAssertNotEqual(BiometricUnavailableReason.notEnrolled, .hardwareUnavailable)

        // Failure reasons
        XCTAssertEqual(BiometricFailureReason.userFailed, .userFailed)
        XCTAssertNotEqual(BiometricFailureReason.userFailed, .systemCancel)

        // Results
        XCTAssertEqual(BiometricResult.success, .success)
        XCTAssertNotEqual(BiometricResult.failed(.userFailed), .cancelled)
        XCTAssertEqual(BiometricResult.failed(.userFailed), .failed(.userFailed))
    }

    func testFakeAuthenticator_conformsAndReturnsConfigured() async {
        struct FakeBiometricAuthenticator: BiometricAuthenticating {
            let avail: BiometricAvailability
            let result: BiometricResult

            func isAvailable() -> BiometricAvailability { avail }

            func authenticate(reason: String) async -> BiometricResult {
                // return immediately; keep deterministic
                return result
            }
        }

        let fake1 = FakeBiometricAuthenticator(avail: .available, result: .success)
        XCTAssertEqual(fake1.isAvailable(), .available)
        let r1 = await fake1.authenticate(reason: "Test")
        XCTAssertEqual(r1, .success)

        let fake2 = FakeBiometricAuthenticator(avail: .unavailable(.notEnrolled), result: .failed(.invalidContext))
        XCTAssertEqual(fake2.isAvailable(), .unavailable(.notEnrolled))
        let r2 = await fake2.authenticate(reason: "Another")
        XCTAssertEqual(r2, .failed(.invalidContext))
    }

    func testBiometricResultEquatable() {
        XCTAssertEqual(BiometricResult.success, .success)
        XCTAssertNotEqual(BiometricResult.failed(.userFailed), .cancelled)
        XCTAssertEqual(BiometricResult.failed(.userFailed), .failed(.userFailed))
    }
}
