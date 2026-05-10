import XCTest
@testable import Kizba
import LocalAuthentication

final class LocalAuthBiometricAuthenticatorTests: XCTestCase {
    func testMapUnavailableReason_mapsKnownLAErrorCodesCorrectly() {
        // biometryNotEnrolled -> notEnrolled
        var err = NSError(domain: LAError.errorDomain, code: LAError.Code.biometryNotEnrolled.rawValue)
        XCTAssertEqual(LocalAuthBiometricAuthenticator.mapUnavailableReason(from: err), .notEnrolled)

        // biometryNotAvailable -> hardwareUnavailable
        err = NSError(domain: LAError.errorDomain, code: LAError.Code.biometryNotAvailable.rawValue)
        XCTAssertEqual(LocalAuthBiometricAuthenticator.mapUnavailableReason(from: err), .hardwareUnavailable)

        // passcodeNotSet -> passcodeNotSet
        err = NSError(domain: LAError.errorDomain, code: LAError.Code.passcodeNotSet.rawValue)
        XCTAssertEqual(LocalAuthBiometricAuthenticator.mapUnavailableReason(from: err), .passcodeNotSet)

        // biometryLockout -> userDisabled
        err = NSError(domain: LAError.errorDomain, code: LAError.Code.biometryLockout.rawValue)
        XCTAssertEqual(LocalAuthBiometricAuthenticator.mapUnavailableReason(from: err), .userDisabled)

        // unknown code -> unknown
        err = NSError(domain: LAError.errorDomain, code: 9999)
        XCTAssertEqual(LocalAuthBiometricAuthenticator.mapUnavailableReason(from: err), .unknown)

        // nil -> unknown
        XCTAssertEqual(LocalAuthBiometricAuthenticator.mapUnavailableReason(from: nil), .unknown)
    }

    func testMapFailureReason_mapsKnownLAErrorCodesCorrectly() {
        // authenticationFailed -> userFailed
        XCTAssertEqual(LocalAuthBiometricAuthenticator.mapFailureReason(from: LAError(.authenticationFailed)), .userFailed)

        // systemCancel -> systemCancel
        XCTAssertEqual(LocalAuthBiometricAuthenticator.mapFailureReason(from: LAError(.systemCancel)), .systemCancel)

        // appCancel -> appCancel
        XCTAssertEqual(LocalAuthBiometricAuthenticator.mapFailureReason(from: LAError(.appCancel)), .appCancel)

        // invalidContext -> invalidContext
        XCTAssertEqual(LocalAuthBiometricAuthenticator.mapFailureReason(from: LAError(.invalidContext)), .invalidContext)

        // notInteractive (arbitrary unmapped) -> unknown
        XCTAssertEqual(LocalAuthBiometricAuthenticator.mapFailureReason(from: LAError(.notInteractive)), .unknown)

        // non-LAError -> unknown
        XCTAssertEqual(LocalAuthBiometricAuthenticator.mapFailureReason(from: NSError(domain: "Other", code: 1)), .unknown)
    }

    func testIsAvailable_and_authenticate_useContextPerCall_smokeConformance() async {
        // Smoke test to ensure the type conforms and methods are callable.
        // Do not rely on real LAContext behaviour in CI — this test only
        // exercises callability and does not assert on system-dependent
        // outcomes.
        let auth = LocalAuthBiometricAuthenticator()
        _ = auth.isAvailable()

        let task = Task { await auth.authenticate(reason: "Test") }
        // Await the task but do not assert result — it may trigger system UI
        // or be unavailable in CI. We simply ensure the call completes.
        _ = await task.value
    }
}
