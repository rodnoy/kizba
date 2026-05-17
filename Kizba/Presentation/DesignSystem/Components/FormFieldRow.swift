import SwiftUI

/// Fixed leading-label column width for `FormFieldRow`. Lives at file
/// scope because Swift forbids static stored properties on generic
/// types (and on enums nested in generic types).
private let formFieldRowLabelWidth: CGFloat = 140

/// Single labeled row inside a `FormSection`. Lays out the trailing-aligned
/// fixed-width label (140pt, native macOS settings layout) next to the
/// caller-supplied `control`. Optional `helpText` and `errorText` render
/// below the row; when both are present, `errorText` wins.
///
/// `infoText`, when supplied, renders an `InfoTooltip` next to the label
/// (after it in horizontal layout, alongside it in vertical/accessibility
/// layout) and **suppresses** the inline `helpText` for that row — the
/// tooltip is the new home for the same content. `errorText` still
/// takes priority over both: an erroring row shows its error message
/// below regardless of `infoText`.
public struct FormFieldRow<Control: View>: View {
    private let label: String
    private let helpText: String?
    private let errorText: String?
    private let infoText: String?
    private let infoAccessibilityLabel: String?
    private let control: () -> Control

    public init(
        label: String,
        helpText: String? = nil,
        errorText: String? = nil,
        infoText: String? = nil,
        infoAccessibilityLabel: String? = nil,
        @ViewBuilder control: @escaping () -> Control
    ) {
        self.label = label
        self.helpText = helpText
        self.errorText = errorText
        self.infoText = infoText
        self.infoAccessibilityLabel = infoAccessibilityLabel
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
                    HStack(alignment: .firstTextBaseline, spacing: theme.spacing.xs) {
                        Text(label)
                            .font(theme.typography.body)
                            .foregroundStyle(theme.colors.onSurface)
                            .accessibilityHidden(true)

                        if let infoText {
                            InfoTooltip(
                                text: infoText,
                                accessibilityLabel: infoAccessibilityLabel
                                    ?? Self.defaultInfoAccessibilityLabel(for: label)
                            )
                        }
                    }

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

                    HStack(alignment: .firstTextBaseline, spacing: theme.spacing.xs) {
                        control()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .accessibilityLabel(label)

                        if let infoText {
                            InfoTooltip(
                                text: infoText,
                                accessibilityLabel: infoAccessibilityLabel
                                    ?? Self.defaultInfoAccessibilityLabel(for: label)
                            )
                        }
                    }
                }
            }

            if let errorText {
                helperText(errorText, color: theme.colors.danger)
            } else if infoText == nil, let helpText {
                // `infoText` suppresses the inline helper — the tooltip
                // is now the canonical home for that copy. An explicit
                // `errorText` still takes priority above.
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

    /// Fallback accessibility label for the info button when the caller
    /// did not provide one. Keeps the announcement contextual to the
    /// field rather than the generic "More information".
    static func defaultInfoAccessibilityLabel(for label: String) -> String {
        "More information about \(label)"
    }

    /// Pure resolver for the row's helper-line copy. Encodes the
    /// priority contract testably:
    ///   1. `errorText` (when non-nil) always wins.
    ///   2. Otherwise, `helpText` is suppressed when `infoText` is set
    ///      (the tooltip is the new home for that copy).
    ///   3. Otherwise, `helpText` is shown as-is.
    /// Returns `nil` when nothing should render below the row.
    static func resolvedHelperText(
        helpText: String?,
        errorText: String?,
        infoText: String?
    ) -> String? {
        if let errorText { return errorText }
        if infoText != nil { return nil }
        return helpText
    }
}
