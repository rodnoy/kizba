import SwiftUI

@MainActor
struct SearchView: View {
    @Bindable var model: SearchModel
    let onSelect: (SearchResult) -> Void

    @Environment(\.theme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.md) {
            TextField("Search…", text: $model.query)
                .textFieldStyle(.roundedBorder)
                .accessibilityLabel("Search")
                .onChange(of: model.query) { _, newValue in
                    model.updateQuery(newValue)
                }

            if model.isLoading {
                ProgressView()
            }

            List(model.results) { result in
                Button {
                    onSelect(result)
                } label: {
                    VStack(alignment: .leading, spacing: theme.spacing.xs) {
                        Text(result.title)
                            .foregroundStyle(theme.colors.onSurface)
                        if let subtitle = result.subtitle {
                            Text(subtitle)
                                .font(theme.typography.caption)
                                .foregroundStyle(theme.colors.onSurfaceMuted)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(result.title)
            }
        }
        .padding(theme.spacing.lg)
        .frame(minWidth: 420, minHeight: 320)
        .background(theme.colors.surface)
    }
}
