import SwiftUI

/// Container that hosts a single optional `Toast` in the bottom-trailing
/// corner with safe-area padding. Designed to be mounted as the topmost
/// overlay of the root scene; it draws nothing when `toast == nil`.
///
/// The transition slides up from the bottom edge and fades in / out, but
/// collapses to no-op when `accessibilityReduceMotion` is set so users
/// who suppress motion still get an instant appearance.
///
/// `Toast` itself lives in `Kizba/Presentation/Toast/Toast.swift`
/// (Phase F.1); this view only consumes a value passed in by the
/// parent (typically `RootSplitView` reading from `AppState.toastCenter`).
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
                .accessibilityElement(children: .combine)
                .accessibilityAddTraits(.isStaticText)
                // Fire a VoiceOver announcement on appear of each new
                // toast. Driven off the toast's `id` so it re-fires
                // when a fresh toast replaces an in-flight one.
                .onAppear {
                    let label = ToastView.accessibilityLabel(
                        for: toast.severity,
                        title: toast.title,
                        message: toast.message
                    )
                    AccessibilityNotification.Announcement(label).post()
                }
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
