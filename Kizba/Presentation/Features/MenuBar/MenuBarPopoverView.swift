import SwiftUI

@MainActor
struct MenuBarPopoverView: View {
    @Bindable var model: MenuBarModel
    @Environment(\.theme) private var theme

    private var isQueryEmpty: Bool {
        model.query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

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

            if isQueryEmpty {
                List {
                    if model.recents.isEmpty == false {
                        Section("Recents") {
                            ForEach(model.recents, id: \.self) { path in
                                Button {
                                    Task {
                                        await model.copyEntry(path: path)
                                    }
                                } label: {
                                    Text(path)
                                        .foregroundStyle(theme.colors.onSurface)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel("Copy password for \(path)")
                            }
                        }
                    }

                    if model.favorites.isEmpty == false {
                        Section("Favorites") {
                            ForEach(model.favorites, id: \.self) { path in
                                Button {
                                    Task {
                                        await model.copyEntry(path: path)
                                    }
                                } label: {
                                    Text(path)
                                        .foregroundStyle(theme.colors.onSurface)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel("Copy password for \(path)")
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            } else {
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
        }
        .padding(theme.spacing.lg)
        .frame(width: 320, height: 400)
        .background(theme.colors.surface)
        .task {
            await model.loadRecentsAndFavorites()
        }
        .onDisappear {
            model.stop()
        }
    }
}
