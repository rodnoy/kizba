import SwiftUI

/// Themed elevated container. Wraps arbitrary content with the
/// design-system padding, an elevated surface fill, and a 1pt divider
/// stroke. Cards themselves are not focusable, so no focus ring is
/// applied here.
///
/// Visual decisions are factored into `internal static` pure helpers
/// (`backgroundColor(in:)`, `borderColor(in:)`, `cornerRadius(in:)`,
/// `padding(in:)`) so they can be unit-tested without rendering.
public struct KizbaCard<Content: View>: View {
    private let content: () -> Content

    public init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    @Environment(\.theme) private var theme

    public var body: some View {
        let shape = RoundedRectangle(
            cornerRadius: KizbaCard<Content>.cornerRadius(in: theme),
            style: .continuous
        )

        return content()
            .padding(KizbaCard<Content>.padding(in: theme))
            .background(shape.fill(KizbaCard<Content>.backgroundColor(in: theme)))
            .overlay(shape.strokeBorder(KizbaCard<Content>.borderColor(in: theme), lineWidth: 1))
    }

    // MARK: - Pure helpers (testable contract)

    /// Card fill color. Always `surfaceElevated` so cards visually lift
    /// off the host `surface` regardless of light/dark/HC variant.
    static func backgroundColor(in theme: Theme) -> Color {
        theme.colors.surfaceElevated
    }

    /// Card border color. The `divider` token is intentionally low-contrast
    /// so multiple stacked cards remain calm.
    static func borderColor(in theme: Theme) -> Color {
        theme.colors.divider
    }

    /// Card corner radius. `lg` (14pt) is one notch above the button
    /// radius scale so card-in-button compositions read cleanly.
    static func cornerRadius(in theme: Theme) -> CGFloat {
        theme.radius.lg
    }

    /// Internal padding applied around `content`. Matches `lg` (16pt) so
    /// content has breathing room without feeling sparse.
    static func padding(in theme: Theme) -> CGFloat {
        theme.spacing.lg
    }
}
