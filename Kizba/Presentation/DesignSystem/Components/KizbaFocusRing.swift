import SwiftUI

/// Two-tone focus ring modifier shared by every focusable atom in the
/// design system. Encapsulates the contract from `.ai/decisions.md`
/// (2026-05-09): an outer 2pt stroke in `theme.colors.focusRingOuter`
/// flush around the container, and an inner 1pt stroke in
/// `theme.colors.focusRingInner` inset by `outerWidth` so it sits inside
/// the outer ring. Centralising the geometry here is also what allows
/// Phase C.6 to ban direct reads of `focusRingOuter`/`focusRingInner`
/// outside this file.
///
/// The pure helpers (`outerColor(in:)`, `innerColor(in:)`,
/// `innerCornerRadius(outerCornerRadius:outerWidth:)`) are exposed
/// internally so unit tests can lock the contract without rendering
/// SwiftUI views.
public struct KizbaFocusRing: ViewModifier {
    private let cornerRadius: CGFloat
    private let isFocused: Bool
    private let outerWidth: CGFloat
    private let innerWidth: CGFloat

    public init(
        cornerRadius: CGFloat,
        isFocused: Bool,
        outerWidth: CGFloat = 2,
        innerWidth: CGFloat = 1
    ) {
        self.cornerRadius = cornerRadius
        self.isFocused = isFocused
        self.outerWidth = outerWidth
        self.innerWidth = innerWidth
    }

    @Environment(\.theme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public func body(content: Content) -> some View {
        content
            .overlay {
                if isFocused {
                    // Geometry: the outer ring is drawn with `.strokeBorder`
                    // so its 2pt stroke sits flush against the container's
                    // edge (no half-pixel bleed). The inner ring is a
                    // separate rounded rectangle inset by `outerWidth` and
                    // its corner radius reduced by the same amount so the
                    // two strokes stay concentric.
                    ZStack {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .strokeBorder(
                                KizbaFocusRing.outerColor(in: theme),
                                lineWidth: outerWidth
                            )
                        RoundedRectangle(
                            cornerRadius: KizbaFocusRing.innerCornerRadius(
                                outerCornerRadius: cornerRadius,
                                outerWidth: outerWidth
                            ),
                            style: .continuous
                        )
                        .strokeBorder(
                            KizbaFocusRing.innerColor(in: theme),
                            lineWidth: innerWidth
                        )
                        .padding(outerWidth)
                    }
                    .transition(.opacity)
                    .allowsHitTesting(false)
                }
            }
            .animation(theme.motion.animation(.quick, reduceMotion: reduceMotion), value: isFocused)
    }

    // MARK: - Pure helpers (testable contract)

    /// Outer-ring stroke color. Always `theme.colors.focusRingOuter`.
    static func outerColor(in theme: Theme) -> Color {
        theme.colors.focusRingOuter
    }

    /// Inner-ring stroke color. Always `theme.colors.focusRingInner`.
    static func innerColor(in theme: Theme) -> Color {
        theme.colors.focusRingInner
    }

    /// Inner-ring corner radius derived from the outer geometry. Inset by
    /// `outerWidth` so the two strokes stay concentric; clamped at 0
    /// when the outer radius is too small to inset (e.g. 1pt outer with
    /// a 2pt outer width).
    static func innerCornerRadius(
        outerCornerRadius: CGFloat,
        outerWidth: CGFloat
    ) -> CGFloat {
        max(outerCornerRadius - outerWidth, 0)
    }
}

public extension View {
    /// Apply the design-system two-tone focus ring around the receiver.
    /// `cornerRadius` should match the container's own corner radius so
    /// the ring traces it exactly.
    func kizbaFocusRing(cornerRadius: CGFloat, isFocused: Bool) -> some View {
        modifier(KizbaFocusRing(cornerRadius: cornerRadius, isFocused: isFocused))
    }
}
