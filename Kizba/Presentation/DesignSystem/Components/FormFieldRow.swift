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
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    public var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.xs) {
            if Self.shouldUseVerticalLayout(dynamicTypeSize) {
                // Vertical layout: label above control. Label should not
                // have a fixed width so it wraps naturally at large sizes.
                VStack(alignment: .leading, spacing: theme.spacing.xs) {
                    Text(label)
                        .font(theme.typography.body)
                        .foregroundStyle(theme.colors.onSurface)
                        .accessibilityHidden(true)

                    control()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .accessibilityLabel(label)
                }
            } else {
                // Existing horizontal layout preserved for non-accessibility sizes.
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
            // When using the vertical layout we should not indent the
            // helper text — it should start at the leading edge. For the
            // horizontal layout we keep the spacer so the helper aligns
            // with the control column.
            if !Self.shouldUseVerticalLayout(dynamicTypeSize) {
                Spacer().frame(width: formFieldRowLabelWidth + theme.spacing.md)
            }
            Text(text)
                .font(theme.typography.caption)
                .foregroundStyle(color)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Pure helpers

    static func shouldUseVerticalLayout(_ size: DynamicTypeSize) -> Bool {
        size >= .accessibility1
    }
}
