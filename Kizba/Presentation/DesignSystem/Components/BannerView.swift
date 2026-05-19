import SwiftUI

/// Inline informational / success / warning / danger banner. The icon is
/// mandatory and fixed per severity so meaning never relies on color alone
/// (color-blind safety, see `.ai/decisions.md`).
///
/// Visual tokens per severity are factored into `internal static` pure
/// helpers (`iconName(for:)`, `iconColor(for:in:)`,
/// `backgroundColor(for:in:)`) so they can be unit-tested without
/// rendering SwiftUI views. `ToastView` reuses these helpers so the two
/// surfaces stay perfectly aligned.
public struct BannerView: View {
    public enum Severity: Sendable, Equatable, CaseIterable {
        case info
        case success
        case warning
        case danger
    }

    /// Optional trailing action attached to a banner. The closure is
    /// `@MainActor` because it bridges back into UI state mutation.
    public struct BannerAction: Sendable {
        public let label: String
        public let perform: @MainActor @Sendable () -> Void

        public init(label: String, perform: @escaping @MainActor @Sendable () -> Void) {
            self.label = label
            self.perform = perform
        }
    }

    private let severity: Severity
    private let title: String
    private let message: String?
    private let action: BannerAction?

    public init(
        severity: Severity,
        title: String,
        message: String? = nil,
        action: BannerAction? = nil
    ) {
        self.severity = severity
        self.title = title
        self.message = message
        self.action = action
    }

    @Environment(\.theme) private var theme

    public var body: some View {
        let shape = RoundedRectangle(cornerRadius: theme.radius.md, style: .continuous)

        return HStack(alignment: .top, spacing: theme.spacing.md) {
            Image(systemName: BannerView.iconName(for: severity))
                .foregroundStyle(BannerView.iconColor(for: severity, in: theme))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: theme.spacing.xs) {
                Text(title)
                    .font(theme.typography.bodyEmphasized)
                    .foregroundStyle(theme.colors.onSurface)
                if let message {
                    Text(message)
                        .font(theme.typography.body)
                        .foregroundStyle(theme.colors.onSurfaceMuted)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if let action {
                Button(action.label, action: action.perform)
                    .buttonStyle(.kizba(.ghost, size: .compact))
            }
        }
        .padding(theme.spacing.md)
        .background(shape.fill(BannerView.backgroundColor(for: severity, in: theme)))
        .overlay(shape.strokeBorder(theme.colors.divider, lineWidth: 1))
    }

    // MARK: - Pure helpers (testable contract)

    /// SF Symbol name for `severity`. Every case maps to a distinct shape
    /// (triangle / circle / octagon) so meaning is conveyed by silhouette
    /// as well as color.
    static func iconName(for severity: Severity) -> String {
        switch severity {
        case .info: return "info.circle.fill"
        case .success: return "checkmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .danger: return "xmark.octagon.fill"
        }
    }

    /// Foreground color for the leading icon. Uses the strong semantic
    /// hue (not the muted variant) so the icon reads against the muted
    /// background fill.
    static func iconColor(for severity: Severity, in theme: Theme) -> Color {
        switch severity {
        case .info: return theme.colors.accent
        case .success: return theme.colors.success
        case .warning: return theme.colors.warning
        case .danger: return theme.colors.danger
        }
    }

    /// Background fill color. `.info` uses `surfaceElevated` so plain
    /// informational banners feel calm; the other severities use their
    /// muted hue to signal state at a glance.
    static func backgroundColor(for severity: Severity, in theme: Theme) -> Color {
        switch severity {
        case .info: return theme.colors.surfaceElevated
        case .success: return theme.colors.successMuted
        case .warning: return theme.colors.warningMuted
        case .danger: return theme.colors.dangerMuted
        }
    }
}
