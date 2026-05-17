import SwiftUI

@MainActor
struct MenuBarPopoverView: View {
    @Bindable var model: MenuBarModel
    @Environment(\.theme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.md) {
            TextField("Search…", text: $model.query)
                .textFieldStyle(.roundedBorder)
                .onChange(of: model.query) { _, newValue in
                    model.updateQuery(newValue)
                }

            if model.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            List(Array(model.results.enumerated()), id: \.element.id) { index, result in
                Button {
                    Task {
                        await model.copyResultPassword(index)
                    }
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
                .accessibilityLabel("Copy password for \(result.title)")
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
        .padding(theme.spacing.lg)
        .frame(width: 320, height: 400)
        .background(theme.colors.surface)
    }
}
