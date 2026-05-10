import XCTest
@testable import Kizba

@MainActor
final class EntryDetailModelBiometricRevealTests: XCTestCase {

    func makeModel(settings: any SettingsStoring = AppEnvironment.InMemorySettingsStore(), biometric: (any BiometricAuthenticating)? = nil) -> EntryDetailModel {
        let env = AppEnvironment(
            passManager: NullPassManager(),
            clipboard: FakeClipboardServicing(),
            settings: settings,
            passwordGenerator: LivePasswordGenerator(),
            biometricAuth: biometric,
            discovery: nil
        )
        return EntryDetailModel(environment: env, state: AppState())
    }

    func testRequestReveal_settingDisabled_revealsWithoutAuth() async {
        let settings = MutableSettingsStore()
        settings.set(false, for: SettingsKey<Bool>(SettingsKeys.touchIDPerRevealEnabled))
        let fake = FakeBiometricAuthenticator()
        let model = makeModel(settings: settings, biometric: fake)

        await model.requestReveal()

        XCTAssertTrue(model.isPasswordRevealed)
        XCTAssertNil(fake.lastReason)
    }

    func testRequestReveal_settingEnabled_authSuccess_reveals() async {
        let settings = MutableSettingsStore()
        settings.set(true, for: SettingsKey<Bool>(SettingsKeys.touchIDPerRevealEnabled))
        let fake = FakeBiometricAuthenticator(availability: .available, nextResult: .success)
        let model = makeModel(settings: settings, biometric: fake)

        await model.requestReveal()

        XCTAssertTrue(model.isPasswordRevealed)
        XCTAssertEqual(fake.lastReason, "Reveal password")
    }

    func testRequestReveal_settingEnabled_authCancelled_noReveal() async {
        let settings = MutableSettingsStore()
        settings.set(true, for: SettingsKey<Bool>(SettingsKeys.touchIDPerRevealEnabled))
        let fake = FakeBiometricAuthenticator(availability: .available, nextResult: .cancelled)
        let model = makeModel(settings: settings, biometric: fake)

        await model.requestReveal()

        XCTAssertFalse(model.isPasswordRevealed)
    }

    func testRequestReveal_settingEnabled_authUnavailable_fallsBackToReveal() async {
        let settings = MutableSettingsStore()
        settings.set(true, for: SettingsKey<Bool>(SettingsKeys.touchIDPerRevealEnabled))
        let fake = FakeBiometricAuthenticator(availability: .unavailable(.notEnrolled), nextResult: .success)
        let model = makeModel(settings: settings, biometric: fake)

        await model.requestReveal()

        XCTAssertTrue(model.isPasswordRevealed)
    }
}
