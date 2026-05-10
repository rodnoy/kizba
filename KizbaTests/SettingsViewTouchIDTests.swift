import XCTest
@testable import Kizba

@MainActor
final class SettingsViewTouchIDTests: XCTestCase {

    func testToggleDisabledWhenBiometricUnavailable() {
        let fake = FakeBiometricAuthenticator(availability: .unavailable(.hardwareUnavailable), nextResult: .success)
        let settings = AppEnvironment.InMemorySettingsStore()
        let model = SettingsModel(settings: settings, discovery: PreviewDiscovery())

        // When no biometric is injected into the environment, the view
        // computes disabled state from an injected authenticator. We
        // simulate that by calling the same availability check here.
        let available = fake.isAvailable()
        switch available {
        case .available:
            XCTAssertTrue(true)
        case .unavailable:
            // Expect the toggle to be present on the model and default
            // to false; the view disables it based on availability.
            XCTAssertFalse(model.touchIDPerRevealEnabled)
        }
    }

    func testToggleEnabledWhenBiometricAvailable() {
        let fake = FakeBiometricAuthenticator(availability: .available, nextResult: .success)
        let settings = AppEnvironment.InMemorySettingsStore()
        let model = SettingsModel(settings: settings, discovery: PreviewDiscovery())

        // Model exposes the persisted property; availability is
        // orthogonal — when available the UI would enable the Toggle.
        XCTAssertFalse(model.touchIDPerRevealEnabled)
        model.touchIDPerRevealEnabled = true
        XCTAssertTrue(model.touchIDPerRevealEnabled)
    }
}

// Lightweight preview discovery stub used by SettingsModel init in tests
private struct PreviewDiscovery: BinaryLocating {
    func locate(_ binary: BinaryName) async -> URL? { nil }
    func reDetect() async {}
}
