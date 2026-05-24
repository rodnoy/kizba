import SwiftUI

public extension ColorTokens {
    /// Light-mode high-contrast variant. Derived from `.light` with these
    /// deltas (each rationale targets WCAG AAA where feasible):
    ///
    /// - `onSurfaceMuted` promoted to `onSurface` (`#1F1B2E`) — kills the
    ///   mid-grey body text role; muted text now reads at full body contrast.
    /// - `onSurfaceFaint` darkened to match `onSurfaceMuted` baseline
    ///   (`#4A445E`) — preserves the three-tier hierarchy by intent but
    ///   raises the floor.
    /// - `accent` deepened from `#7C5BC4` to `#5B3FA0` for stronger
    ///   contrast against `surface`/`surfaceElevated`.
    /// - `divider` opacity raised from 0.08 → 0.16 (doubled), making
    ///   structural lines visible without relying on subtle elevation.
    /// - `focusRingOuter` set to a deeper azure than the standard light
    ///   variant (`#0B2C66`) — pushes the outer-vs-surface ratio above
    ///   the standard light palette so HC never regresses.
    /// - `focusRingInner` stays white (`#FFFFFF`) for maximum split
    ///   against both the darker outer band and the deepened HC accent.
    /// - `secretMask` opacity lowered 0.30 → 0.18 so password-reveal
    ///   text composited over the mask still clears AAA (7:1) on `surface`.
    /// - `danger`/`success`/`warning` already use deepened hues in the
    ///   light palette; left unchanged.
    static let lightHighContrast = ColorTokens(
        surface: Color(hex: 0xFBF7FB),
        surfaceElevated: Color(hex: 0xFFFFFF),
        surfaceSunken: Color(hex: 0xF2EAF1),
        surfaceHover: Color(hex: 0xCDB4DB, opacity: 0.20),
        surfaceSelected: Color(hex: 0xBDE0FE, opacity: 0.55),
        surfaceCard: Color(hex: 0xFFFFFF),
        surfaceCardHover: Color(hex: 0xCDB4DB, opacity: 0.20),
        onSurface: Color(hex: 0x1F1B2E),
        onSurfaceMuted: Color(hex: 0x1F1B2E), // delta: was #4A445E
        onSurfaceFaint: Color(hex: 0x4A445E), // delta: was #8A839E
        accent: Color(hex: 0x5B3FA0),         // delta: was #7C5BC4
        accentMuted: Color(hex: 0xCDB4DB, opacity: 0.40),
        accentSecondary: Color(hex: 0x0B2C66),
        accentStrong: Color(hex: 0x5B3FA0),
        onAccent: Color(hex: 0xFFFFFF),
        danger: Color(hex: 0xC2185B),
        dangerMuted: Color(hex: 0xFFC8DD, opacity: 0.55),
        onDanger: Color(hex: 0xFFFFFF),
        success: Color(hex: 0x2E7D5B),
        successMuted: Color(hex: 0xBDE0FE, opacity: 0.40),
        onSuccess: Color(hex: 0xFFFFFF),
        warning: Color(hex: 0x9A5A00),
        warningMuted: Color(hex: 0xFFC8DD, opacity: 0.45),
        onWarning: Color(hex: 0xFFFFFF),
        // Deeper azure than standard light's #1F4FA8; #0B2C66 reaches
        // ~12:1 against the light surface, well above the 3:1 floor and
        // strictly stronger than the standard light variant.
        focusRingOuter: Color(hex: 0x0B2C66),    // delta: was #A2D2FF (single-tone)
        // White core gives ~12:1 against the outer band and ~7.9:1
        // against the deepened HC accent — the ring's structure stays
        // crisp on both chrome and primary action fills.
        focusRingInner: Color(hex: 0xFFFFFF),    // delta: ring is now two-tone
        divider: Color(hex: 0x1F1B2E, opacity: 0.16), // delta: was 0.08
        scrim: Color(hex: 0x1F1B2E, opacity: 0.55),
        // Lowered 0.30 → 0.18 so the masked rectangle composites closer
        // to bare surface; password-reveal mono on the mask now clears
        // the AAA 7:1 target without sacrificing the masked-state cue.
        secretMask: Color(hex: 0xBDE0FE, opacity: 0.18)
    )

    /// Dark-mode high-contrast variant. Derived from `.dark` with these
    /// deltas:
    ///
    /// - `onSurfaceMuted` promoted to `onSurface` (`#F4EFF7`) — same
    ///   rationale as the light variant.
    /// - `onSurfaceFaint` lifted to the previous `onSurfaceMuted` value
    ///   (`#B8B0C8`).
    /// - `accent` brightened from `#CDB4DB` to `#E5D2F2` for stronger
    ///   contrast against the dark surface.
    /// - `divider` opacity raised from 0.10 → 0.20 (doubled).
    /// - `focusRingOuter` set to a brighter sky-blue than the standard
    ///   dark variant (`#BDE0FE`) — pushes outer-vs-surface contrast
    ///   above the standard dark palette so HC never regresses.
    /// - `focusRingInner` is the surface hairline (`#15121C`); the dark
    ///   core gives a strong split against both the bright outer band
    ///   and the brightened HC accent fill.
    /// - `secretMask` opacity slashed 0.22 → 0.04 — the previous overlay
    ///   was light enough on a dark surface to lift the masked area into
    ///   a luminance band where `onSurface` text could no longer reach
    ///   AAA. The fainter overlay restores AAA password-reveal contrast
    ///   while keeping a perceptible masked-state tint.
    static let darkHighContrast = ColorTokens(
        surface: Color(hex: 0x111018),
        surfaceElevated: Color(hex: 0x1E1A2A),
        surfaceSunken: Color(hex: 0x0F0D16),
        surfaceHover: Color(hex: 0xCDB4DB, opacity: 0.18),
        surfaceSelected: Color(hex: 0xA2D2FF, opacity: 0.28),
        surfaceCard: Color(hex: 0x1E1A2A),
        surfaceCardHover: Color(hex: 0xCDB4DB, opacity: 0.18),
        onSurface: Color(hex: 0xF4EFF7),
        onSurfaceMuted: Color(hex: 0xF4EFF7), // delta: was #B8B0C8
        onSurfaceFaint: Color(hex: 0xB8B0C8), // delta: was #7B7390
        accent: Color(hex: 0xE5D2F2),         // delta: was #CDB4DB
        accentMuted: Color(hex: 0xCDB4DB, opacity: 0.28),
        accentSecondary: Color(hex: 0xBDE0FE),
        accentStrong: Color(hex: 0xE5D2F2),
        onAccent: Color(hex: 0x1F1B2E),
        danger: Color(hex: 0xFFAFCC),
        // Muted-bg α lowered 0.28 → 0.10 so the composite over the dark
        // surface stays close to bare surface. Both the icon vs bg ratio
        // (WCAG SC 1.4.11, ≥3:1) and the body text vs bg ratio
        // (WCAG SC 1.4.3, ≥4.5:1) rise simultaneously when α drops.
        dangerMuted: Color(hex: 0xFFAFCC, opacity: 0.10),
        onDanger: Color(hex: 0x1F1B2E),
        success: Color(hex: 0x7CD9A8),
        // See dangerMuted note: lower α → composite nearer surface →
        // both SC 1.4.11 (icon ≥3) and SC 1.4.3 (body ≥4.5) targets met.
        successMuted: Color(hex: 0xBDE0FE, opacity: 0.10),
        onSuccess: Color(hex: 0x0E1F18),
        warning: Color(hex: 0xFFB870),
        // See dangerMuted note: lower α → composite nearer surface →
        // both SC 1.4.11 (icon ≥3) and SC 1.4.3 (body ≥4.5) targets met.
        warningMuted: Color(hex: 0xFFC8DD, opacity: 0.10),
        onWarning: Color(hex: 0x1F1B2E),
        // Brighter sky than standard dark's #A2D2FF; #BDE0FE reaches
        // ~13.4:1 against the dark surface, strictly stronger than the
        // standard dark focus-ring outer.
        focusRingOuter: Color(hex: 0xBDE0FE),    // delta: was #A2D2FF (single-tone)
        // Dark hairline core (== surface) splits the outer band at
        // ~13.4:1 and reaches ~5.5:1 against the brightened HC accent.
        focusRingInner: Color(hex: 0x111018),    // delta: ring is now two-tone
        divider: Color(hex: 0xF4EFF7, opacity: 0.20), // delta: was 0.10
        scrim: Color(hex: 0x000000, opacity: 0.65),
        // Lowered 0.22 → 0.04 so the mask barely tints the surface; this
        // lets `onSurface` text on a masked password reveal clear AAA
        // (7:1) on the dark HC palette where the previous overlay broke it.
        secretMask: Color(hex: 0xA2D2FF, opacity: 0.04)
    )
}

public extension Theme {
    /// Light-mode high-contrast theme. Used when the user enables
    /// "Increase Contrast" in macOS System Settings while in light mode.
    static let lightHighContrast = Theme(
        id: .lightHighContrast,
        colors: .lightHighContrast,
        spacing: .default,
        radius: .default,
        typography: .default,
        motion: .default
    )

    /// Dark-mode high-contrast theme. Used when the user enables
    /// "Increase Contrast" in macOS System Settings while in dark mode.
    static let darkHighContrast = Theme(
        id: .darkHighContrast,
        colors: .darkHighContrast,
        spacing: .default,
        radius: .default,
        typography: .default,
        motion: .default
    )
}
