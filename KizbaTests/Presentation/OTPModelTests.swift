import Foundation
import XCTest
@testable import Kizba

@MainActor
final class OTPModelTests: XCTestCase {

    func test_start_emitsInitialCode() async throws {
        let clock = TestClock(date: Date(timeIntervalSince1970: 10))
        let generator = TestOTPGenerator()
        let model = makeModel(
            secret: Self.totp(period: 1),
            generator: generator,
            clock: clock
        )

        model.start()
        try await Task.sleep(for: .milliseconds(10))

        XCTAssertFalse(model.currentCode.isEmpty)
        XCTAssertEqual(model.currentCode, generator.generate(Self.totp(period: 1), at: clock.now()))
        model.stop()
    }

    func test_recomputesCodeOnPeriodBoundary() async throws {
        let clock = LiveClock()
        let generator = TestOTPGenerator()
        let model = makeModel(
            secret: Self.totp(period: 1),
            generator: generator,
            clock: clock
        )

        model.start()
        try await Task.sleep(for: .milliseconds(10))
        let initial = model.currentCode

        try await Task.sleep(for: .milliseconds(1100))

        XCTAssertNotEqual(model.currentCode, initial)
        model.stop()
    }

    func test_progressFraction_drainsLinearly() async throws {
        let clock = TestClock(date: Date(timeIntervalSince1970: 0.25))
        let model = makeModel(
            secret: Self.totp(period: 2),
            generator: TestOTPGenerator(),
            clock: clock
        )

        model.start()
        try await Task.sleep(for: .milliseconds(20))
        let first = model.progressFraction

        clock.advance(by: 0.5)
        try await Task.sleep(for: .milliseconds(300))
        let second = model.progressFraction

        XCTAssertGreaterThan(second, first)
        XCTAssertEqual(second - first, 0.25, accuracy: 0.2)
        model.stop()
    }

    func test_stop_cancelsRefreshTask() async throws {
        let clock = LiveClock()
        let model = makeModel(
            secret: Self.totp(period: 1),
            generator: TestOTPGenerator(),
            clock: clock
        )

        model.start()
        try await Task.sleep(for: .milliseconds(20))
        model.stop()
        let captured = model.currentCode

        try await Task.sleep(for: .milliseconds(1200))

        XCTAssertEqual(model.currentCode, captured)
    }

    func test_requestCopy_policyOnSuccess_writesToClipboard() async throws {
        let clipboard = FakeClipboardServicing()
        let settings = MutableSettingsStore()
        settings.set(true, for: SettingsKey<Bool>(SettingsKeys.touchIDForSensitiveActions))
        let auth = FakeBiometricAuthenticator(availability: .available, nextResult: .success)
        let gate = BiometricGate(
            auth: auth,
            settings: settings,
            policyKey: SettingsKey<Bool>(SettingsKeys.touchIDForSensitiveActions)
        )

        let model = OTPModel(
            secret: Self.totp(period: 1),
            generator: TestOTPGenerator(),
            clock: TestClock(date: Date(timeIntervalSince1970: 10)),
            gate: gate,
            clipboard: clipboard
        )

        model.start()
        try await Task.sleep(for: .milliseconds(10))
        let code = model.currentCode

        await model.requestCopy()

        XCTAssertEqual(clipboard.lastCall?.value, code)
        XCTAssertEqual(clipboard.lastCall?.clearAfter, .seconds(SettingsKeys.defaultClipboardClearDelaySeconds))
        model.stop()
    }

    func test_requestCopy_policyOnCancelled_doesNotWrite() async throws {
        let clipboard = FakeClipboardServicing()
        let settings = MutableSettingsStore()
        settings.set(true, for: SettingsKey<Bool>(SettingsKeys.touchIDForSensitiveActions))
        let auth = FakeBiometricAuthenticator(availability: .available, nextResult: .cancelled)
        let gate = BiometricGate(
            auth: auth,
            settings: settings,
            policyKey: SettingsKey<Bool>(SettingsKeys.touchIDForSensitiveActions)
        )

        let model = OTPModel(
            secret: Self.totp(period: 1),
            generator: TestOTPGenerator(),
            clock: TestClock(date: Date(timeIntervalSince1970: 10)),
            gate: gate,
            clipboard: clipboard
        )

        model.start()
        try await Task.sleep(for: .milliseconds(10))
        await model.requestCopy()

        XCTAssertTrue(clipboard.calls.isEmpty)
        model.stop()
    }

    func test_hotp_showsCodeOnce_noProgressDrain() async throws {
        let clock = LiveClock()
        let generator = TestOTPGenerator()
        let model = makeModel(
            secret: Self.hotp(counter: 7),
            generator: generator,
            clock: clock
        )

        model.start()
        try await Task.sleep(for: .milliseconds(20))
        let initial = model.currentCode

        try await Task.sleep(for: .milliseconds(1200))

        XCTAssertEqual(model.progressFraction, 0)
        XCTAssertEqual(model.remainingSeconds, 0)
        XCTAssertEqual(model.currentCode, initial)
        XCTAssertEqual(generator.callCount, 1)
        model.stop()
    }

    private func makeModel(
        secret: OTPSecret,
        generator: any OTPGenerating,
        clock: any ClockServicing
    ) -> OTPModel {
        OTPModel(
            secret: secret,
            generator: generator,
            clock: clock,
            gate: BiometricGate(
                auth: nil,
                settings: MutableSettingsStore(),
                policyKey: SettingsKey<Bool>(SettingsKeys.touchIDForSensitiveActions)
            ),
            clipboard: FakeClipboardServicing()
        )
    }

    private static func totp(period: TimeInterval) -> OTPSecret {
        OTPSecret(
            kind: .totp(period: period),
            secretBase32: "JBSWY3DPEHPK3PXP",
            algorithm: .sha1,
            digits: 6,
            label: nil,
            issuer: nil
        )
    }

    private static func hotp(counter: UInt64) -> OTPSecret {
        OTPSecret(
            kind: .hotp(counter: counter),
            secretBase32: "JBSWY3DPEHPK3PXP",
            algorithm: .sha1,
            digits: 6,
            label: nil,
            issuer: nil
        )
    }
}

private final class TestClock: ClockServicing, @unchecked Sendable {
    private let lock = NSLock()
    private var date: Date

    init(date: Date = Date(timeIntervalSince1970: 0)) {
        self.date = date
    }

    func now() -> Date {
        lock.lock(); defer { lock.unlock() }
        return date
    }

    func advance(by interval: TimeInterval) {
        lock.lock(); defer { lock.unlock() }
        date = date.addingTimeInterval(interval)
    }
}

private final class TestOTPGenerator: OTPGenerating, @unchecked Sendable {
    private let lock = NSLock()
    private var _callCount = 0

    var callCount: Int {
        lock.lock(); defer { lock.unlock() }
        return _callCount
    }

    func generate(_ secret: OTPSecret, at date: Date) -> String {
        lock.lock(); _callCount += 1; lock.unlock()

        switch secret.kind {
        case let .totp(period):
            return String(Int(floor(date.timeIntervalSince1970 / period)))
        case let .hotp(counter):
            return String(counter)
        }
    }
}
