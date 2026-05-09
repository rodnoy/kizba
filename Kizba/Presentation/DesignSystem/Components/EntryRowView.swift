import SwiftUI

/// Themed row used by the entry list. Pulled out as a DesignSystem
/// component so future view migration (Phase C.3) replaces the
/// `private struct EntryRow` inside `EntryListView` with this; until
/// then both shapes coexist.
///
/// Background resolution is factored into the pure helper
/// `backgroundColor(in:isSelected:isHovered:)` so it can be unit-tested
/// without rendering. Selection wins over hover; hover only takes effect
/// for non-selected rows.
public struct EntryRowView: View {
    private let leadingIconName: String?
    private let title: String
    private let subtitle: String?
    private let isSelected: Bool
    private let accessoryIconName: String?

    public init(
        leadingIconName: String? = nil,
        title: String,
        subtitle: String? = nil,
        isSelected: Bool,
        accessoryIconName: String? = nil
    ) {
        self.leadingIconName = leadingIconName
        self.title = title
        self.subtitle = subtitle
        self.isSelected = isSelected
        self.accessoryIconName = accessoryIconName
    }

    @Environment(\.theme) private var theme
    @State private var isHovered: Bool = false

    public var body: some View {
        HStack(spacing: theme.spacing.sm) {
            if let leadingIconName {
                Image(systemName: leadingIconName)
                    .foregroundStyle(theme.colors.onSurfaceMuted)
                    .accessibilityHidden(true)
            }

            VStack(alignment: .leading, spacing: theme.spacing.xs) {
                Text(title)
                    .font(theme.typography.body)
                    .foregroundStyle(theme.colors.onSurface)
                    .lineLimit(1)
                    .truncationMode(.tail)
                if let subtitle {
                    Text(subtitle)
                        .font(theme.typography.caption)
                        .foregroundStyle(theme.colors.onSurfaceMuted)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if let accessoryIconName {
                Image(systemName: accessoryIconName)
                    .foregroundStyle(theme.colors.onSurfaceFaint)
                    .accessibilityHidden(true)
            }
        }
        .padding(.horizontal, theme.spacing.md)
        .padding(.vertical, theme.spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: theme.radius.sm, style: .continuous)
                .fill(EntryRowView.backgroundColor(
                    in: theme,
                    isSelected: isSelected,
                    isHovered: isHovered
                ))
        )
        .contentShape(Rectangle())
        .onHover { hovering in
            isHovered = hovering
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    // MARK: - Pure helpers (testable contract)

    /// Resolves the row background fill. Selection always wins; hover
    /// only tints non-selected rows; idle rows are transparent so the
    /// host list's surface shows through.
    static func backgroundColor(
        in theme: Theme,
        isSelected: Bool,
        isHovered: Bool
    ) -> Color {
        if isSelected {
            return theme.colors.surfaceSelected
        }
        if isHovered {
            return theme.colors.surfaceHover
        }
        return Color.clear
    }
}
