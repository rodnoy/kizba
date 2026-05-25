import SwiftUI

public extension ColorTokens {
    /// Light-mode palette per the locked spec in `.ai/plan.md`
    /// ("Brand palette → semantic tokens" → "Light mode").
    static let light = ColorTokens(
        surface: Color(hex: 0xFBF7FB),
        surfaceElevated: Color(hex: 0xFFFFFF),
        surfaceSunken: Color(hex: 0xF2EAF1),
        surfaceHover: Color(hex: 0xCDB4DB, opacity: 0.14),
        surfaceSelected: Color(hex: 0xBDE0FE, opacity: 0.45),
        surfaceCard: Color(hex: 0xFFFFFF),
        surfaceCardHover: Color(hex: 0xCDB4DB, opacity: 0.14),
        surfaceCardFlat: Color(hex: 0xFFFFFF),
        surfaceCardFlatHover: Color(hex: 0xCDB4DB, opacity: 0.14),
        surfaceCardInteractive: Color(hex: 0xFFFFFF),
        surfaceCardInteractiveHover: Color(hex: 0xCDB4DB, opacity: 0.14),
        onSurface: Color(hex: 0x1F1B2E),
        onSurfaceMuted: Color(hex: 0x4A445E),
        onSurfaceFaint: Color(hex: 0x8A839E),
        accent: Color(hex: 0x7C5BC4),
        accentMuted: Color(hex: 0xCDB4DB, opacity: 0.28),
        accentSecondary: Color(hex: 0x1F4FA8),
        accentStrong: Color(hex: 0x7C5BC4),
        onAccent: Color(hex: 0xFFFFFF),
        buttonPrimaryFill: Color(hex: 0x7C5BC4),
        buttonSecondaryFill: Color(hex: 0xFFFFFF),
        buttonDestructiveFill: Color(hex: 0xC2185B),
        buttonGhostPressedFill: Color(hex: 0xFFFFFF),
        danger: Color(hex: 0xC2185B),
        dangerMuted: Color(hex: 0xFFC8DD, opacity: 0.45),
        onDanger: Color(hex: 0xFFFFFF),
        success: Color(hex: 0x2E7D5B),
        successMuted: Color(hex: 0xBDE0FE, opacity: 0.30),
        onSuccess: Color(hex: 0xFFFFFF),
        warning: Color(hex: 0x9A5A00),
        warningMuted: Color(hex: 0xFFC8DD, opacity: 0.35),
        onWarning: Color(hex: 0xFFFFFF),
        // Deep azure outer ring; opaque #1F4FA8 hits ~7.4:1 on the
        // light surface, well past the 3:1 floor for non-text UI.
        focusRingOuter: Color(hex: 0x1F4FA8),
        // White core gives ~7.4:1 against the outer band and ~5.4:1
        // against the deepened accent fill, keeping the inner stripe
        // visible whether the ring sits on chrome or on a primary button.
        focusRingInner: Color(hex: 0xFFFFFF),
        divider: Color(hex: 0x1F1B2E, opacity: 0.08),
        scrim: Color(hex: 0x1F1B2E, opacity: 0.45),
        secretMask: Color(hex: 0xBDE0FE, opacity: 0.22)
    )
}

public extension Theme {
    /// Default light-mode theme.
    static let light = Theme(
        id: .light,
        colors: .light,
        spacing: .default,
        radius: .default,
        typography: .default,
        motion: .default
    )
}
