import CoreGraphics

/// Layout spacing scale. Single canonical instance (`SpacingTokens.default`)
/// is consumed everywhere; the struct shape is preserved so future variants
/// (e.g. a "compact" set) can be introduced without changing call sites.
public struct SpacingTokens: Sendable, Equatable {
    public let xs: CGFloat
    public let sm: CGFloat
    public let md: CGFloat
    public let lg: CGFloat
    public let xl: CGFloat
    public let xxl: CGFloat

    public init(
        xs: CGFloat,
        sm: CGFloat,
        md: CGFloat,
        lg: CGFloat,
        xl: CGFloat,
        xxl: CGFloat
    ) {
        self.xs = xs
        self.sm = sm
        self.md = md
        self.lg = lg
        self.xl = xl
        self.xxl = xxl
    }

    public static let `default` = SpacingTokens(
        xs: 4,
        sm: 8,
        md: 12,
        lg: 16,
        xl: 24,
        xxl: 32
    )
}
