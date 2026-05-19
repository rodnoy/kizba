import Foundation
import Observation

@Observable
@MainActor
public final class OTPModel {
    public private(set) var currentCode: String = ""
    public private(set) var remainingSeconds: Double = 0
    public private(set) var progressFraction: Double = 0

    private let secret: OTPSecret
    private let generator: any OTPGenerating
    private let clock: any ClockServicing
    private let gate: BiometricGate
    private let clipboard: any ClipboardServicing

    private var refreshTask: Task<Void, Never>?
    private var lastCounter: UInt64 = .max
    private var isStarted: Bool = false

    public init(
        secret: OTPSecret,
        generator: any OTPGenerating,
        clock: any ClockServicing,
        gate: BiometricGate,
        clipboard: any ClipboardServicing
    ) {
        self.secret = secret
        self.generator = generator
        self.clock = clock
        self.gate = gate
        self.clipboard = clipboard
    }

    public func start() {
        guard !isStarted else { return }
        isStarted = true

        switch secret.kind {
        case .hotp:
            currentCode = generator.generate(secret, at: clock.now())
            remainingSeconds = 0
            progressFraction = 0
            return

        case .totp:
            refresh(date: clock.now())
            refreshTask = Task { @MainActor [weak self] in
                guard let self else { return }
                while !Task.isCancelled {
                    self.refresh(date: self.clock.now())
                    try? await Task.sleep(for: .milliseconds(250))
                }
            }
        }
    }

    public func stop() {
        isStarted = false
        refreshTask?.cancel()
        refreshTask = nil
    }

    public func requestCopy() async {
        let allowed = await gate.run(reason: "Copy OTP")
        guard allowed else { return }

        await clipboard.copy(
            currentCode,
            clearAfter: .seconds(SettingsKeys.defaultClipboardClearDelaySeconds)
        )
    }

    // MARK: - Reveal (MVP9.2)
    //
    // The reveal helpers gate the SECRET-bearing operations (URI,
    // manual Base32, QR payload) through the same `BiometricGate`
    // the code-copy already uses. Per MVP9.2 the gating policy for
    // reveal is stricter than for code-copy: revealing the secret
    // hands the user (or anything looking at the screen) the full
    // ability to mint codes off-device, so the gate is mandatory.
    //
    // Each helper returns `nil` on cancellation / failed
    // authentication so the call site can keep its sheet closed.
    // The Sheet drives its own dismissal and is responsible for
    // nilling the revealed string from its `@State` when it closes,
    // so the cleartext never lingers beyond the user's session.

    /// Reveal the secret as a canonical `otpauth://` URI. Gated by
    /// Touch ID. Returns `nil` if the gate denies the operation.
    public func revealURI() async -> String? {
        let allowed = await gate.run(reason: "Reveal OTP URI")
        guard allowed else { return nil }
        return OTPAuthURIBuilder.build(secret)
    }

    /// Reveal the secret as its raw Base32 string (for manual entry
    /// in another authenticator app). Gated by Touch ID.
    public func revealSecret() async -> String? {
        let allowed = await gate.run(reason: "Reveal OTP secret")
        guard allowed else { return nil }
        return secret.secretBase32
    }

    /// Build the otpauth payload used by a QR render. Gated by
    /// Touch ID. The payload itself IS the secret, hence the gate —
    /// anyone scanning the resulting QR enrols the OTP into their
    /// own authenticator.
    public func revealQRPayload() async -> String? {
        let allowed = await gate.run(reason: "Show OTP QR code")
        guard allowed else { return nil }
        return OTPAuthURIBuilder.build(secret)
    }

    /// Copy a previously-revealed export string (URI / Base32) to
    /// the system pasteboard with the standard auto-clear window.
    /// Used by the reveal sheet's "Copy" button so the export path
    /// shares the same clipboard discipline as code-copy.
    public func copyRevealedExport(_ value: String) async {
        await clipboard.copy(
            value,
            clearAfter: .seconds(SettingsKeys.defaultClipboardClearDelaySeconds)
        )
    }

    private func refresh(date: Date) {
        guard case let .totp(period) = secret.kind, period > 0 else { return }

        let counter = UInt64(floor(date.timeIntervalSince1970 / period))
        if counter != lastCounter {
            currentCode = generator.generate(secret, at: date)
            lastCounter = counter
        }

        let remainder = date.timeIntervalSince1970.truncatingRemainder(dividingBy: period)
        let normalizedRemainder = remainder >= 0 ? remainder : (remainder + period)
        let remaining = period - normalizedRemainder
        remainingSeconds = remaining

        let elapsed = period - remaining
        let fraction = elapsed / period
        progressFraction = min(1, max(0, fraction))
    }
}
