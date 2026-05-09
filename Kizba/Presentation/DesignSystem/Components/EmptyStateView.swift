import SwiftUI

/// Centered placeholder used for empty lists, no-selection panes, and
/// missing-store states. The `actions` slot is generic so callers can
/// drop in a `KizbaButtonStyle` button, a `SettingsLink`, or nothing at
/// all (the `EmptyView` overload).
///
/// Background is intentionally transparent so the host container's
/// `surface` token shows through; it is not the empty state's job to
/// theme its own backdrop.
public struct EmptyStateView<Actions: View>: View {
    private let iconName: String
    private let title: String
    private let message: String?
    private let actions: () -> Actions

    public init(
        iconName: String,
        title: String,
        message: String? = nil,
        @ViewBuilder actions: @escaping () -> Actions
    ) {
        self.iconName = iconName
        self.title = title
        self.message = message
        self.actions = actions
    }

    @Environment(\.theme) private var theme

    public var body: some View {
        VStack(spacing: theme.spacing.md) {
            Image(systemName: iconName)
                .font(.system(.largeTitle))
                .foregroundStyle(theme.colors.onSurfaceMuted)
                .accessibilityHidden(true)

            Text(title)
                .font(theme.typography.title)
                .foregroundStyle(theme.colors.onSurface)
                .multilineTextAlignment(.center)

            if let message {
                Text(message)
                    .font(theme.typography.body)
                    .foregroundStyle(theme.colors.onSurfaceMuted)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            let renderedActions = actions()
            if !(Actions.self == EmptyView.self) {
                renderedActions
                    .padding(.top, theme.spacing.sm)
            }
        }
        .padding(theme.spacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
    }
}

public extension EmptyStateView where Actions == EmptyView {
    /// Convenience initialiser for empty states without action buttons.
    init(iconName: String, title: String, message: String? = nil) {
        self.init(
            iconName: iconName,
            title: title,
            message: message,
            actions: { EmptyView() }
        )
    }
}
