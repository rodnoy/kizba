import SwiftUI

/// One of the four canonical motion durations. Carries its own seconds value
/// so callers can compose custom animations (e.g. spring) when the default
/// `.easeInOut` isn't appropriate, while still staying on a token.
public enum MotionToken: Sendable, Equatable, CaseIterable {
    case instant
    case quick
    case standard
    case emphasized

    /// Duration in seconds. `instant` is exactly zero; the helper on
    /// `MotionTokens` collapses to `nil` for that case.
    public var seconds: Double {
        switch self {
        case .instant: return 0
        case .quick: return 0.12
        case .standard: return 0.2
        case .emphasized: return 0.32
        }
    }
}

/// Motion tokens. The struct itself carries no per-instance state today; the
/// shape mirrors the other token namespaces and leaves room for future
/// per-theme overrides (e.g. a slower "calm" variant).
///
/// Reduce-motion handling is exposed as a helper rather than read from the
/// environment internally: `MotionTokens` is a value type usable from any
/// context, and the `accessibilityReduceMotion` flag must be supplied by
/// the caller (typically a `View` reading `@Environment(\.accessibilityReduceMotion)`).
public struct MotionTokens: Sendable, Equatable {
    public let instant: MotionToken
    public let quick: MotionToken
    public let standard: MotionToken
    public let emphasized: MotionToken

    public init(
        instant: MotionToken = .instant,
        quick: MotionToken = .quick,
        standard: MotionToken = .standard,
        emphasized: MotionToken = .emphasized
    ) {
        self.instant = instant
        self.quick = quick
        self.standard = standard
        self.emphasized = emphasized
    }

    public static let `default` = MotionTokens()

    /// Returns an `Animation` for the given token, or `nil` when motion
    /// should be suppressed (`token == .instant`, or `reduceMotion == true`).
    /// Callers can pass the result directly to `withAnimation(_:_:)`.
    public func animation(_ token: MotionToken, reduceMotion: Bool) -> Animation? {
        if reduceMotion || token == .instant {
            return nil
        }
        return .easeInOut(duration: token.seconds)
    }
}
