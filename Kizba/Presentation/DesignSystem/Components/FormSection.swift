import SwiftUI

/// Themed form section grouping. Stand-in for vanilla SwiftUI
/// `Section { ... }` so settings-style layouts pick up `theme.*` tokens
/// (radius, spacing, divider, surface) consistently.
///
/// Title (when present) renders above the card in the muted headline
/// uppercase style typical of macOS Settings sections; content is
/// wrapped in an elevated card with a 1pt divider stroke.
public struct FormSection<Content: View>: View {
    private let title: String?
    private let content: () -> Content

    public init(_ title: String? = nil, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.content = content
    }

    @Environment(\.theme) private var theme

    public var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.md) {
            if let title {
                Text(title.uppercased())
                    .font(theme.typography.headline)
                    .foregroundStyle(theme.colors.onSurfaceMuted)
                    .tracking(0.5)
                    .accessibilityAddTraits(.isHeader)
            }

            VStack(alignment: .leading, spacing: theme.spacing.md) {
                content()
            }
            .padding(theme.spacing.md)
            .background(
                RoundedRectangle(cornerRadius: theme.radius.md, style: .continuous)
                    .fill(theme.colors.surfaceElevated)
            )
            .overlay(
                RoundedRectangle(cornerRadius: theme.radius.md, style: .continuous)
                    .strokeBorder(theme.colors.divider, lineWidth: 1)
            )
        }
    }
}
