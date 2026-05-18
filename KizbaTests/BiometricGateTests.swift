import XCTest
@testable import Kizba

@MainActor
final class BiometricGateTests: XCTestCase {

    func testRun_policyOff_returnsTrue_andDoesNotAuthenticate() async {
        let settings = MutableSettingsStore()
        settings.set(false, for: SettingsKey<Bool>(SettingsKeys.touchIDPerRevealEnabled))
        let auth = FakeBiometricAuthenticator(availability: .available, nextResult: .success)
        let gate = BiometricGate(
            auth: auth,
            settings: settings,
            policyKey: SettingsKey<Bool>(SettingsKeys.touchIDPerRevealEnabled)
        )

        let result = await gate.run(reason: "Reveal password")

        XCTAssertTrue(result)
        XCTAssertEqual(auth.authenticateCalls.count, 0)
    }

    func testRun_policyOn_nilAuthenticator_returnsTrue() async {
        let settings = MutableSettingsStore()
        settings.set(true, for: SettingsKey<Bool>(SettingsKeys.touchIDPerRevealEnabled))
        let gate = BiometricGate(
            auth: nil,
            settings: settings,
            policyKey: SettingsKey<Bool>(SettingsKeys.touchIDPerRevealEnabled)
        )

        let result = await gate.run(reason: "Reveal password")

        XCTAssertTrue(result)
    }

    func testRun_policyOn_available_success_returnsTrue() async {
        let settings = MutableSettingsStore()
        settings.set(true, for: SettingsKey<Bool>(SettingsKeys.touchIDPerRevealEnabled))
        let auth = FakeBiometricAuthenticator(availability: .available, nextResult: .success)
        let gate = BiometricGate(
            auth: auth,
            settings: settings,
            policyKey: SettingsKey<Bool>(SettingsKeys.touchIDPerRevealEnabled)
        )

        let result = await gate.run(reason: "Reveal password")

        XCTAssertTrue(result)
        XCTAssertEqual(auth.authenticateCalls, ["Reveal password"])
    }

    func testRun_policyOn_available_cancelled_returnsFalse() async {
        let settings = MutableSettingsStore()
        settings.set(true, for: SettingsKey<Bool>(SettingsKeys.touchIDPerRevealEnabled))
        let auth = FakeBiometricAuthenticator(availability: .available, nextResult: .cancelled)
        let gate = BiometricGate(
            auth: auth,
            settings: settings,
            policyKey: SettingsKey<Bool>(SettingsKeys.touchIDPerRevealEnabled)
        )

        let result = await gate.run(reason: "Reveal password")

        XCTAssertFalse(result)
        XCTAssertEqual(auth.authenticateCalls, ["Reveal password"])
    }

    func testRun_policyOn_available_failed_returnsFalse() async {
        let settings = MutableSettingsStore()
        settings.set(true, for: SettingsKey<Bool>(SettingsKeys.touchIDPerRevealEnabled))
        let auth = FakeBiometricAuthenticator(availability: .available, nextResult: .failed(.userFailed))
        let gate = BiometricGate(
            auth: auth,
            settings: settings,
            policyKey: SettingsKey<Bool>(SettingsKeys.touchIDPerRevealEnabled)
        )

        let result = await gate.run(reason: "Reveal password")

        XCTAssertFalse(result)
        XCTAssertEqual(auth.authenticateCalls, ["Reveal password"])
    }

    func testRun_policyOn_unavailable_returnsTrue_andDoesNotAuthenticate() async {
        let settings = MutableSettingsStore()
        settings.set(true, for: SettingsKey<Bool>(SettingsKeys.touchIDPerRevealEnabled))
        let auth = FakeBiometricAuthenticator(availability: .unavailable(.notEnrolled), nextResult: .success)
        let gate = BiometricGate(
            auth: auth,
            settings: settings,
            policyKey: SettingsKey<Bool>(SettingsKeys.touchIDPerRevealEnabled)
        )

        let result = await gate.run(reason: "Reveal password")

        XCTAssertTrue(result)
        XCTAssertEqual(auth.authenticateCalls.count, 0)
    }
}
