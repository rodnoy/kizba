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
