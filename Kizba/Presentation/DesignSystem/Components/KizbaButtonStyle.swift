import SwiftUI

/// Themed `ButtonStyle` for Kizba. Variants map onto the four canonical
/// action roles of the design system; sizing has two presets (`.regular`
/// / `.compact`) sharing the same visual language. Disabled and pressed
/// states are uniform across variants so the whole button surface feels
/// like one component family rather than four.
///
/// SwiftUI's `ButtonStyle.makeBody(configuration:)` does not surface focus
/// state, so the actual rendering happens inside a private nested view
/// (`ButtonContent`) that owns a `@FocusState` and applies
/// `KizbaFocusRing` itself. This keeps the public API a regular
/// `ButtonStyle` callable as `.buttonStyle(.kizba(.primary))`.
///
/// All per-variant visual decisions are factored into `internal static`
/// pure helpers (`foregroundColor(for:in:)`, `backgroundColor(for:in:isPressed:)`,
/// `font(for:in:)`, `verticalPadding(for:in:)`, `horizontalPadding(for:in:)`,
/// `cornerRadius(for:in:)`) so they can be unit-tested without rendering
/// SwiftUI views. The runtime rendering path (`ButtonContent.body`) calls
/// the same helpers — there is one source of truth per visual property.
public struct KizbaButtonStyle: ButtonStyle {
    public enum Variant: Sendable, Equatable, CaseIterable {
        case primary
        case secondary
        case destructive
        case ghost
    }

    public enum Size: Sendable, Equatable, CaseIterable {
        case regular
        case compact
    }

    private let variant: Variant
    private let size: Size

    public init(variant: Variant, size: Size = .regular) {
        self.variant = variant
        self.size = size
    }

    public func makeBody(configuration: Configuration) -> some View {
        ButtonContent(configuration: configuration, variant: variant, size: size)
    }

    // MARK: - Pure helpers (testable contract)

    /// Foreground (label) color for `variant` resolved against `theme`.
    /// - `.primary` / `.destructive` invert onto white-on-fill.
    /// - `.secondary` / `.ghost` use the accent hue directly because their
    ///   surface is the elevated background or transparent.
    static func foregroundColor(for variant: Variant, in theme: Theme) -> Color {
        switch variant {
        case .primary: return theme.colors.onAccent
        case .secondary: return theme.colors.accent
        case .destructive: return theme.colors.onDanger
        case .ghost: return theme.colors.accent
        }
    }

    /// Background fill for `variant` resolved against `theme`. The
    /// `isPressed` flag matters only for `.ghost`; all other variants
    /// ignore it. `.ghost` idle background is `Color.clear` by design
    /// (transparent over the host surface). The pressed fill uses a
    /// luminance-away surface swap (see B.5 contrast resolution).
    static func backgroundColor(
        for variant: Variant,
        in theme: Theme,
        isPressed: Bool
    ) -> Color {
        switch variant {
        case .primary: return theme.colors.buttonPrimaryFill
        case .secondary: return theme.colors.buttonSecondaryFill
        case .destructive: return theme.colors.buttonDestructiveFill
        case .ghost:
            guard isPressed else { return Color.clear }
            return theme.colors.buttonGhostPressedFill
        }
    }

    /// Whether this variant draws a 1pt accent stroke on top of its fill.
    /// Only `.secondary` does — it sits on `surfaceElevated` and needs the
    /// border to read as actionable rather than as a card.
    static func hasAccentBorder(for variant: Variant) -> Bool {
        switch variant {
        case .secondary: return true
        case .primary, .destructive, .ghost: return false
        }
    }

    /// Label font for `variant` resolved against `theme`. Filled actions
    /// (`.primary` / `.destructive`) use the emphasized weight to stand
    /// out; the lighter `.secondary` / `.ghost` use the regular body
    /// weight to recede.
    static func font(for variant: Variant, in theme: Theme) -> Font {
        switch variant {
        case .primary, .destructive:
            return theme.typography.bodyEmphasized
        case .secondary, .ghost:
            return theme.typography.body
        }
    }

    /// Vertical padding for `size` resolved against `theme`'s spacing
    /// scale. `.regular` → `sm` (8pt), `.compact` → `xs` (4pt).
    static func verticalPadding(for size: Size, in theme: Theme) -> CGFloat {
        switch size {
        case .regular: return theme.spacing.sm
        case .compact: return theme.spacing.xs
        }
    }

    /// Horizontal padding for `size` resolved against `theme`'s spacing
    /// scale. `.regular` → `lg` (16pt), `.compact` → `md` (12pt).
    static func horizontalPadding(for size: Size, in theme: Theme) -> CGFloat {
        switch size {
        case .regular: return theme.spacing.lg
        case .compact: return theme.spacing.md
        }
    }

    /// Corner radius for `size` resolved against `theme`'s radius scale.
    /// `.regular` → `md` (10pt), `.compact` → `sm` (6pt).
    static func cornerRadius(for size: Size, in theme: Theme) -> CGFloat {
        switch size {
        case .regular: return theme.radius.md
        case .compact: return theme.radius.sm
        }
    }

    /// Opacity applied to the whole button when `isEnabled` is false.
    /// Single source of truth across variants so disabled state always
    /// reads the same.
    static let disabledOpacity: Double = 0.5

    private struct ButtonContent: View {
        let configuration: ButtonStyleConfiguration
        let variant: Variant
        let size: Size

        @Environment(\.theme) private var theme
        @Environment(\.isEnabled) private var isEnabled
        @Environment(\.accessibilityReduceMotion) private var reduceMotion
        @FocusState private var isFocused: Bool

        var body: some View {
            let radius = KizbaButtonStyle.cornerRadius(for: size, in: theme)
            let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)

            return configuration.label
                .font(KizbaButtonStyle.font(for: variant, in: theme))
                .foregroundStyle(KizbaButtonStyle.foregroundColor(for: variant, in: theme))
                .padding(.vertical, KizbaButtonStyle.verticalPadding(for: size, in: theme))
                .padding(.horizontal, KizbaButtonStyle.horizontalPadding(for: size, in: theme))
                .background(
                    shape.fill(
                        KizbaButtonStyle.backgroundColor(
                            for: variant,
                            in: theme,
                            isPressed: configuration.isPressed
                        )
                    )
                )
                .overlay(borderOverlay(shape: shape))
                .opacity(isEnabled ? 1.0 : KizbaButtonStyle.disabledOpacity)
                .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
                .animation(
                    theme.motion.animation(.quick, reduceMotion: reduceMotion),
                    value: configuration.isPressed
                )
                .contentShape(shape)
                .focusable(isEnabled)
                .focused($isFocused)
                .kizbaFocusRing(cornerRadius: radius, isFocused: isFocused)
        }

        @ViewBuilder
        private func borderOverlay(shape: RoundedRectangle) -> some View {
            if KizbaButtonStyle.hasAccentBorder(for: variant) {
                shape.strokeBorder(theme.colors.accent, lineWidth: 1)
            } else {
                EmptyView()
            }
        }
    }
}

public extension ButtonStyle where Self == KizbaButtonStyle {
    /// Convenience builder so call sites read as
    /// `.buttonStyle(.kizba(.primary))` rather than instantiating the
    /// style explicitly.
    static func kizba(
        _ variant: KizbaButtonStyle.Variant,
        size: KizbaButtonStyle.Size = .regular
    ) -> KizbaButtonStyle {
        KizbaButtonStyle(variant: variant, size: size)
    }
}
