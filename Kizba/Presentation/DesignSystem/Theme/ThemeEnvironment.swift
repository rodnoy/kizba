import SwiftUI

/// Sanctioned SwiftUI Environment slot for the active design-system `Theme`.
///
/// Per `.ai/decisions.md`, environment-based propagation is reserved for
/// cross-cutting presentation concerns (theme / locale) and is the ONLY
/// non-domain `EnvironmentValues` extension allowed in this project.
/// Domain services continue to be injected manually via initializers and
/// `AppEnvironment`. Do NOT add other custom environment keys without an
/// updated decision in `.ai/decisions.md`.
private struct ThemeEnvironmentKey: EnvironmentKey {
    static let defaultValue: Theme = .light
}

public extension EnvironmentValues {
    /// The active `Theme` for the current view subtree. Set by `ThemedRoot`
    /// at every scene root based on `colorScheme` + `colorSchemeContrast`.
    /// Default value (`.light`) only applies if a view is rendered outside
    /// any `ThemedRoot` (e.g. in previews); all production scenes are wrapped.
    var theme: Theme {
        get { self[ThemeEnvironmentKey.self] }
        set { self[ThemeEnvironmentKey.self] = newValue }
    }
}
