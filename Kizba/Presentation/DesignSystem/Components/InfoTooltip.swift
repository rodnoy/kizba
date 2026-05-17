import SwiftUI

/// Reusable info-affordance: a small SF-Symbol `info.circle` button that
/// opens a popover with a short explanation. Intended for use next to
/// form field labels to surface context without permanently consuming
/// the helper-text slot below the row.
///
/// Behavioural contract:
///   - Defaults to closed.
///   - Tapping the button toggles the popover.
///   - The button exposes both `.help(...)` (hover tooltip) and an
///     explicit accessibility label so VoiceOver announces the purpose
///     before the user activates it.
///   - Optional `title` renders bold above `text`; both use DS
///     typography tokens. The popover body is capped at 280pt wide so
///     it stays readable inside `Form` / `TabView` hosts.
///
/// Styling rules: tokens only (`theme.colors.*`, `theme.typography.*`,
/// `theme.spacing.*`). No raw `Color.*`, no numeric corner radius, no
/// numeric `.opacity()` — enforced by `SourceGrepTests` for the
/// Presentation tree (DesignSystem is exempt but we honour the same
/// discipline for consistency).
public struct InfoTooltip: View {
    private let text: String
    private let accessibilityLabel: String
    private let title: String?

    @State private var isOpen = false

    @Environment(\.theme) private var theme

    public init(
        text: String,
        accessibilityLabel: String,
        title: String? = nil
    ) {
        self.text = text
        self.accessibilityLabel = accessibilityLabel
        self.title = title
    }

    public var body: some View {
        Button {
            isOpen.toggle()
        } label: {
            Image(systemName: "info.circle")
                .foregroundStyle(theme.colors.onSurfaceMuted)
        }
        .buttonStyle(.plain)
        .help(accessibilityLabel)
        .accessibilityLabel(accessibilityLabel)
        .popover(
            isPresented: $isOpen,
            attachmentAnchor: .point(.center),
            arrowEdge: .top
        ) {
            VStack(alignment: .leading, spacing: theme.spacing.xs) {
                if let title {
                    Text(title)
                        .font(theme.typography.bodyEmphasized)
                        .foregroundStyle(theme.colors.onSurface)
                }
                Text(text)
                    .font(theme.typography.caption)
                    .foregroundStyle(theme.colors.onSurface)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(theme.spacing.md)
            .frame(maxWidth: 280, alignment: .leading)
        }
    }
}
