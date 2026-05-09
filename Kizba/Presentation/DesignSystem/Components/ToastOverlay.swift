import SwiftUI

/// Seed `Toast` value type used by `ToastOverlay` in this phase. Phase F.1
/// will move `Toast` to its own file under `Kizba/Presentation/Toast/`
/// and introduce `ToastCenter` (the actual posting / dedup / auto-dismiss
/// machinery). Until then, `ToastOverlay` accepts `Toast?` so the shell
/// can be wired and tested in isolation.
public struct Toast: Identifiable, Sendable {
    public let id: UUID
    public let severity: BannerView.Severity
    public let title: String
    public let message: String?
    public let action: BannerView.BannerAction?

    public init(
        severity: BannerView.Severity,
        title: String,
        message: String? = nil,
        action: BannerView.BannerAction? = nil
    ) {
        self.id = UUID()
        self.severity = severity
        self.title = title
        self.message = message
        self.action = action
    }
}

/// Container that hosts a single optional `Toast` in the bottom-trailing
/// corner with safe-area padding. Designed to be mounted as the topmost
/// overlay of the root scene; it draws nothing when `toast == nil`.
///
/// The transition slides up from the bottom edge and fades in / out, but
/// collapses to no-op when `accessibilityReduceMotion` is set so users
/// who suppress motion still get an instant appearance.
public struct ToastOverlay: View {
    private let toast: Toast?

    public init(toast: Toast?) {
        self.toast = toast
    }

    @Environment(\.theme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Color.clear
            if let toast {
                ToastView(
                    severity: toast.severity,
                    title: toast.title,
                    message: toast.message,
                    action: toast.action
                )
                .id(toast.id)
                .padding(theme.spacing.lg)
                .frame(maxWidth: 420, alignment: .trailing)
                .transition(ToastOverlay.transition(reduceMotion: reduceMotion))
            }
        }
        .animation(theme.motion.animation(.standard, reduceMotion: reduceMotion), value: toast?.id)
        .allowsHitTesting(toast != nil)
    }

    // MARK: - Pure helpers (testable contract)

    /// Selected SwiftUI transition for the toast. `reduceMotion` collapses
    /// to `.identity` so the toast appears / disappears without any
    /// animated motion or fade.
    static func transition(reduceMotion: Bool) -> AnyTransition {
        if reduceMotion {
            return .identity
        }
        return .move(edge: .bottom).combined(with: .opacity)
    }
}
