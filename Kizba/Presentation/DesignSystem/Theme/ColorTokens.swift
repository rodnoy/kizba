import SwiftUI

/// Semantic color tokens for the Kizba design system. Every UI surface, text
/// role, and accent state in `Presentation/**` resolves through one of these
/// properties; views must never reference SwiftUI's built-in `Color.*`
/// statics directly (enforced in Phase C by `SourceGrepTests`).
///
/// `Color` is a value type holding immutable display data; sharing it across
/// actors is safe. SwiftUI marks `Color` as `Sendable` on macOS 14, so this
/// struct can adopt `Sendable` without an `@unchecked` escape hatch.
public struct ColorTokens: Sendable, Equatable {
    // Surfaces
    public let surface: Color
    public let surfaceElevated: Color
    public let surfaceSunken: Color
    public let surfaceHover: Color
    public let surfaceSelected: Color

    // On-surface text roles
    public let onSurface: Color
    public let onSurfaceMuted: Color
    public let onSurfaceFaint: Color

    // Accent
    public let accent: Color
    public let accentMuted: Color
    public let onAccent: Color

    // Danger
    public let danger: Color
    public let dangerMuted: Color
    public let onDanger: Color

    // Success
    public let success: Color
    public let successMuted: Color
    public let onSuccess: Color

    // Warning
    public let warning: Color
    public let warningMuted: Color
    public let onWarning: Color

    // Chrome
    /// Outer color of the two-tone focus ring; must reach ≥3:1 against
    /// `surface` so the ring is visible on adjacent chrome.
    public let focusRingOuter: Color
    /// Inner core of the two-tone focus ring; must reach ≥3:1 against
    /// `focusRingOuter` (so the ring's own structure is legible) and
    /// ≥3:1 against `accent` (so the ring stays visible when overlaid
    /// on a primary action fill).
    public let focusRingInner: Color
    public let divider: Color
    public let scrim: Color
    public let secretMask: Color

    public init(
        surface: Color,
        surfaceElevated: Color,
        surfaceSunken: Color,
        surfaceHover: Color,
        surfaceSelected: Color,
        onSurface: Color,
        onSurfaceMuted: Color,
        onSurfaceFaint: Color,
        accent: Color,
        accentMuted: Color,
        onAccent: Color,
        danger: Color,
        dangerMuted: Color,
        onDanger: Color,
        success: Color,
        successMuted: Color,
        onSuccess: Color,
        warning: Color,
        warningMuted: Color,
        onWarning: Color,
        focusRingOuter: Color,
        focusRingInner: Color,
        divider: Color,
        scrim: Color,
        secretMask: Color
    ) {
        self.surface = surface
        self.surfaceElevated = surfaceElevated
        self.surfaceSunken = surfaceSunken
        self.surfaceHover = surfaceHover
        self.surfaceSelected = surfaceSelected
        self.onSurface = onSurface
        self.onSurfaceMuted = onSurfaceMuted
        self.onSurfaceFaint = onSurfaceFaint
        self.accent = accent
        self.accentMuted = accentMuted
        self.onAccent = onAccent
        self.danger = danger
        self.dangerMuted = dangerMuted
        self.onDanger = onDanger
        self.success = success
        self.successMuted = successMuted
        self.onSuccess = onSuccess
        self.warning = warning
        self.warningMuted = warningMuted
        self.onWarning = onWarning
        self.focusRingOuter = focusRingOuter
        self.focusRingInner = focusRingInner
        self.divider = divider
        self.scrim = scrim
        self.secretMask = secretMask
    }
}
