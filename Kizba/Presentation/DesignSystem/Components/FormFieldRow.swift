import SwiftUI

/// Fixed leading-label column width for `FormFieldRow`. Lives at file
/// scope because Swift forbids static stored properties on generic
/// types (and on enums nested in generic types).
private let formFieldRowLabelWidth: CGFloat = 140

/// Single labeled row inside a `FormSection`. Lays out the trailing-aligned
/// fixed-width label (140pt, native macOS settings layout) next to the
/// caller-supplied `control`. Optional `helpText` and `errorText` render
/// below the row; when both are present, `errorText` wins.
public struct FormFieldRow<Control: View>: View {
    private let label: String
    private let helpText: String?
    private let errorText: String?
    private let control: () -> Control

    public init(
        label: String,
        helpText: String? = nil,
        errorText: String? = nil,
        @ViewBuilder control: @escaping () -> Control
    ) {
        self.label = label
        self.helpText = helpText
        self.errorText = errorText
        self.control = control
    }

    @Environment(\.theme) private var theme

    public var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.xs) {
            HStack(alignment: .firstTextBaseline, spacing: theme.spacing.md) {
                Text(label)
                    .font(theme.typography.body)
                    .foregroundStyle(theme.colors.onSurface)
                    .frame(width: formFieldRowLabelWidth, alignment: .trailing)
                    .accessibilityHidden(true)

                control()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityLabel(label)
            }

            if let errorText {
                helperText(errorText, color: theme.colors.danger)
            } else if let helpText {
                helperText(helpText, color: theme.colors.onSurfaceMuted)
            }
        }
    }

    private func helperText(_ text: String, color: Color) -> some View {
        HStack(spacing: 0) {
            // Match the indentation of the control column so helper text
            // visually aligns with the field above it.
            Spacer().frame(width: formFieldRowLabelWidth + theme.spacing.md)
            Text(text)
                .font(theme.typography.caption)
                .foregroundStyle(color)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
