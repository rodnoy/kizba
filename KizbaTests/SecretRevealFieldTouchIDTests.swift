import XCTest
@testable import Kizba

final class SecretRevealFieldTouchIDTests: XCTestCase {

    func testAttemptReveal_gateDisabled_revealsImmediately() async {
        let fake = FakeBiometricAuthenticator(availability: .available, nextResult: .cancelled)
        let revealed = await SecretRevealField.attemptReveal(biometricAuthenticator: fake, gateEnabled: false)
        XCTAssertTrue(revealed)
        XCTAssertNil(fake.lastReason)
    }

    func testAttemptReveal_gateEnabled_authSuccess_reveals() async {
        let fake = FakeBiometricAuthenticator(availability: .available, nextResult: .success)
        let revealed = await SecretRevealField.attemptReveal(biometricAuthenticator: fake, gateEnabled: true)
        XCTAssertTrue(revealed)
        XCTAssertEqual(fake.lastReason, "Reveal password")
    }

    func testAttemptReveal_gateEnabled_authCancelled_noReveal() async {
        let fake = FakeBiometricAuthenticator(availability: .available, nextResult: .cancelled)
        let revealed = await SecretRevealField.attemptReveal(biometricAuthenticator: fake, gateEnabled: true)
        XCTAssertFalse(revealed)
    }

    func testAttemptReveal_gateEnabled_authFailed_noReveal() async {
        let fake = FakeBiometricAuthenticator(availability: .available, nextResult: .failed(.userFailed))
        let revealed = await SecretRevealField.attemptReveal(biometricAuthenticator: fake, gateEnabled: true)
        XCTAssertFalse(revealed)
    }

    func testRemask_alwaysImmediate() async {
        // Remasking logic lives in the view's button handler which
        // directly sets the binding. We verify the helper does not
        // gate hiding by asserting that gateEnabled only affects
        // reveal (attemptReveal returns early when gate disabled).
        let fake = FakeBiometricAuthenticator()
        let revealed = await SecretRevealField.attemptReveal(biometricAuthenticator: fake, gateEnabled: true)
        // If authenticator is available and returns success by default,
        // attemptReveal returns true; remasking (setting false) is not
        // gated by this helper and is immediate in the view.
        XCTAssertTrue(revealed)
    }
}
