import SwiftUI

/// A single toast cell. Reuses `BannerView.Severity` so the two surfaces
/// share one severity vocabulary and one icon-per-severity contract.
///
/// Compared to `BannerView`, a toast is sized more compactly, uses the
/// larger `radius.lg` corner, and casts a subtle drop shadow because it
/// floats above content rather than sitting in flow.
public struct ToastView: View {
    private let severity: BannerView.Severity
    private let title: String
    private let message: String?
    private let action: BannerView.BannerAction?

    public init(
        severity: BannerView.Severity,
        title: String,
        message: String? = nil,
        action: BannerView.BannerAction? = nil
    ) {
        self.severity = severity
        self.title = title
        self.message = message
        self.action = action
    }

    @Environment(\.theme) private var theme

    public var body: some View {
        let shape = RoundedRectangle(cornerRadius: theme.radius.lg, style: .continuous)

        return HStack(alignment: .top, spacing: theme.spacing.sm) {
            Image(systemName: BannerView.iconName(for: severity))
                .foregroundStyle(BannerView.iconColor(for: severity, in: theme))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: theme.spacing.xs) {
                Text(title)
                    .font(theme.typography.bodyEmphasized)
                    .foregroundStyle(theme.colors.onSurface)
                if let message {
                    Text(message)
                        .font(theme.typography.callout)
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
        .padding(.horizontal, theme.spacing.md)
        .padding(.vertical, theme.spacing.sm)
        .background(shape.fill(BannerView.backgroundColor(for: severity, in: theme)))
        .overlay(shape.strokeBorder(theme.colors.divider, lineWidth: 1))
        .shadow(color: theme.colors.scrim.opacity(0.3), radius: 8, y: 2)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isStaticText)
        .accessibilityLabel(ToastView.accessibilityLabel(for: severity, title: title, message: message))
    }

    // MARK: - Pure helpers (testable contract)

    /// Human-readable severity prefix used by VoiceOver. Kept private to
    /// the type so future localisation work has a single place to update.
    static func severityLabel(for severity: BannerView.Severity) -> String {
        switch severity {
        case .info: return "Info"
        case .success: return "Success"
        case .warning: return "Warning"
        case .danger: return "Error"
        }
    }

    /// Composes the VoiceOver label as `"<severity> — <title>[ — <message>]"`.
    static func accessibilityLabel(
        for severity: BannerView.Severity,
        title: String,
        message: String?
    ) -> String {
        let prefix = "\(severityLabel(for: severity)) — \(title)"
        if let message, !message.isEmpty {
            return "\(prefix) — \(message)"
        }
        return prefix
    }
}
