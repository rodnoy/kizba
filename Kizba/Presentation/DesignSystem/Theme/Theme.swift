import Foundation

/// Top-level design-system value type. A `Theme` bundles every token namespace
/// (colors, spacing, radius, typography, motion) into a single immutable
/// snapshot keyed by `id`. Views consume the active theme through
/// `EnvironmentValues.theme` (wired in Phase B.2); this file defines only
/// the value type and its identity.
///
/// All four `Theme.ID` cases are materialized as static constants on this
/// type via the `Theme+Light`, `Theme+Dark`, and `Theme+HighContrast`
/// extension files.
public struct Theme: Sendable, Equatable {
    public let id: ID
    public let colors: ColorTokens
    public let spacing: SpacingTokens
    public let radius: RadiusTokens
    public let typography: TypographyTokens
    public let motion: MotionTokens

    public init(
        id: ID,
        colors: ColorTokens,
        spacing: SpacingTokens,
        radius: RadiusTokens,
        typography: TypographyTokens,
        motion: MotionTokens
    ) {
        self.id = id
        self.colors = colors
        self.spacing = spacing
        self.radius = radius
        self.typography = typography
        self.motion = motion
    }

    public enum ID: String, Sendable, Equatable, CaseIterable {
        case light
        case dark
        case lightHighContrast
        case darkHighContrast
    }
}
