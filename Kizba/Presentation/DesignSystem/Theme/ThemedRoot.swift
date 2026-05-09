import SwiftUI

/// Wraps a scene's content view and injects the appropriate `Theme` into
/// `EnvironmentValues.theme` based on the system `colorScheme` and the
/// `Increase Contrast` accessibility setting (`colorSchemeContrast`).
///
/// Each top-level `Scene` (main window, Settings, Diagnostics) gets its own
/// `ThemedRoot` because separate scene trees do not share `@Environment`
/// state — theme injection must happen at every scene root independently.
///
/// This is purely a presentation-layer wrapper; it observes system settings
/// only and never touches domain services.
public struct ThemedRoot<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast

    private let content: () -> Content

    public init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    public var body: some View {
        content()
            .environment(\.theme, currentTheme)
    }

    /// Maps the system appearance × contrast pair to one of the four
    /// canonical `Theme` constants. Falls back to `.light` for any
    /// unexpected combination so the UI always renders.
    private var currentTheme: Theme {
        switch (colorScheme, colorSchemeContrast) {
        case (.light, .standard):
            return .light
        case (.dark, .standard):
            return .dark
        case (.light, .increased):
            return .lightHighContrast
        case (.dark, .increased):
            return .darkHighContrast
        @unknown default:
            return .light
        }
    }
}
