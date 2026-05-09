import CoreGraphics

/// Corner-radius scale. `pill` is large enough to fully round any reasonable
/// control height (capsule shape) without resorting to `Capsule()`.
public struct RadiusTokens: Sendable, Equatable {
    public let sm: CGFloat
    public let md: CGFloat
    public let lg: CGFloat
    public let pill: CGFloat

    public init(sm: CGFloat, md: CGFloat, lg: CGFloat, pill: CGFloat) {
        self.sm = sm
        self.md = md
        self.lg = lg
        self.pill = pill
    }

    public static let `default` = RadiusTokens(
        sm: 6,
        md: 10,
        lg: 14,
        pill: 999
    )
}
