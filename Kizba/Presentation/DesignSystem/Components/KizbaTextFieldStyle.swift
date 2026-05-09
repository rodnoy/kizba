import SwiftUI

/// Themed `TextFieldStyle`. Renders a sunken pill-corner field with the
/// design-system padding/typography and applies the shared two-tone
/// focus ring on focus so it visually matches `KizbaButtonStyle`.
///
/// `TextFieldStyle` exposes a single underscore-prefixed requirement
/// (`_body(configuration:)`) on macOS 14; this is the documented API
/// for shipping a custom style and is the same shape Apple's own
/// styles use.
public struct KizbaTextFieldStyle: TextFieldStyle {
    public init() {}

    @MainActor
    public func _body(configuration: TextField<Self._Label>) -> some View {
        TextFieldContent(field: configuration)
    }

    private struct TextFieldContent: View {
        let field: TextField<KizbaTextFieldStyle._Label>

        @Environment(\.theme) private var theme
        @Environment(\.isEnabled) private var isEnabled
        @FocusState private var isFocused: Bool

        var body: some View {
            field
                .textFieldStyle(.plain)
                .padding(.horizontal, theme.spacing.md)
                .padding(.vertical, theme.spacing.sm)
                .font(theme.typography.body)
                .foregroundStyle(theme.colors.onSurface)
                .background(
                    RoundedRectangle(cornerRadius: theme.radius.md, style: .continuous)
                        .fill(theme.colors.surfaceSunken)
                )
                .focused($isFocused)
                .kizbaFocusRing(cornerRadius: theme.radius.md, isFocused: isFocused)
                .opacity(isEnabled ? 1.0 : 0.5)
        }
    }
}

public extension TextFieldStyle where Self == KizbaTextFieldStyle {
    /// Convenience accessor: `.textFieldStyle(.kizba)`.
    static var kizba: KizbaTextFieldStyle { KizbaTextFieldStyle() }
}
