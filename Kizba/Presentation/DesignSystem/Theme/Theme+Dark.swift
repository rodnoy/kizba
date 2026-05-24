import SwiftUI

public extension ColorTokens {
    /// Dark-mode palette per the locked spec in `.ai/plan.md`
    /// ("Brand palette → semantic tokens" → "Dark mode").
    ///
    /// `onWarning` is inferred as deep indigo (`#1F1B2E`) — the warning
    /// surface in dark mode is a light amber (`#FFB870`), so dark text
    /// matches the on-accent / on-danger pattern used elsewhere in the
    /// dark palette.
    static let dark = ColorTokens(
        surface: Color(hex: 0x111018),
        surfaceElevated: Color(hex: 0x1E1A2A),
        surfaceSunken: Color(hex: 0x0B0A12),
        surfaceHover: Color(hex: 0xCDB4DB, opacity: 0.10),
        surfaceSelected: Color(hex: 0xA2D2FF, opacity: 0.18),
        surfaceCard: Color(hex: 0x1E1A2A),
        surfaceCardHover: Color(hex: 0xCDB4DB, opacity: 0.10),
        surfaceCardFlat: Color(hex: 0x1E1A2A),
        surfaceCardFlatHover: Color(hex: 0xCDB4DB, opacity: 0.10),
        surfaceCardInteractive: Color(hex: 0x1E1A2A),
        surfaceCardInteractiveHover: Color(hex: 0xCDB4DB, opacity: 0.10),
        onSurface: Color(hex: 0xF4EFF7),
        onSurfaceMuted: Color(hex: 0xB8B0C8),
        onSurfaceFaint: Color(hex: 0x7B7390),
        accent: Color(hex: 0xCDB4DB),
        accentMuted: Color(hex: 0xCDB4DB, opacity: 0.22),
        accentSecondary: Color(hex: 0xA2D2FF),
        accentStrong: Color(hex: 0xCDB4DB),
        onAccent: Color(hex: 0x1F1B2E),
        danger: Color(hex: 0xFFAFCC),
        dangerMuted: Color(hex: 0xFFAFCC, opacity: 0.18),
        onDanger: Color(hex: 0x1F1B2E),
        success: Color(hex: 0x7CD9A8),
        successMuted: Color(hex: 0xBDE0FE, opacity: 0.18),
        onSuccess: Color(hex: 0x0E1F18),
        warning: Color(hex: 0xFFB870),
        warningMuted: Color(hex: 0xFFC8DD, opacity: 0.18),
        onWarning: Color(hex: 0x1F1B2E),
        // Pastel sky-blue outer ring; opaque #A2D2FF reaches ~10.5:1
        // against the near-black dark surface.
        focusRingOuter: Color(hex: 0xA2D2FF),
        // Dark hairline core (== surface) provides a ~10.5:1 split
        // against the outer band and ~3.5:1 against the pastel accent,
        // so the ring stays legible on both chrome and accent fills.
        focusRingInner: Color(hex: 0x111018),
        divider: Color(hex: 0xF4EFF7, opacity: 0.10),
        scrim: Color(hex: 0x000000, opacity: 0.55),
        // Lowered from 0.14 → 0.06 so the masked rectangle composites
        // closer to the bare surface and lets `onSurface` clear the
        // AAA 7:1 password-reveal contrast target.
        secretMask: Color(hex: 0xA2D2FF, opacity: 0.06)
    )
}

public extension Theme {
    /// Default dark-mode theme.
    static let dark = Theme(
        id: .dark,
        colors: .dark,
        spacing: .default,
        radius: .default,
        typography: .default,
        motion: .default
    )
}
