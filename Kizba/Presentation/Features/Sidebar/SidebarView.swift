//
//  SidebarView.swift
//  Kizba
//
//  Sidebar column of the root `NavigationSplitView`. Renders the
//  deterministic list of top-level folders produced by `SidebarModel`
//  and binds row selection to `AppState.selectedFolder`.
//

import SwiftUI

/// Sidebar column of `RootSplitView`.
///
/// The view owns its `SidebarModel` (constructed from
/// `AppEnvironment.passManager`) and reads/writes the currently
/// selected folder through the shared `AppState`.
struct SidebarView: View {

    /// Folder selection bound to `AppState.selectedFolder` so the
    /// middle column can react to it.
    @Binding var selection: String?

    @State private var model: SidebarModel
    @State private var favoritesModel: FavoritesModel
    private let gitStatusModel: GitStatusModel?
    @Environment(\.theme) private var theme

    init(
        environment: AppEnvironment,
        selection: Binding<String?>,
        gitStatusModel: GitStatusModel? = nil
    ) {
        self._selection = selection
        self._model = State(initialValue: SidebarModel(passManager: environment.passManager))
        self._favoritesModel = State(initialValue: FavoritesModel(store: environment.favoritesStore))
        self.gitStatusModel = gitStatusModel
    }

    var body: some View {
        VStack(spacing: 0) {
            List {
                if !favoritesModel.favorites.isEmpty {
                    Section("Favorites") {
                        ForEach(favoritesModel.favorites, id: \.self) { entryPath in
                            EntryRowView(
                                leadingIconName: "star.fill",
                                title: entryPath.components(separatedBy: "/").last ?? entryPath,
                                isSelected: selection == entryPath
                            )
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selection = entryPath
                            }
                            .listRowBackground(Color.clear)
                            .accessibilityLabel("\(entryPath), favorite")
                        }
                    }
                }

                Section("Folders") {
                    ForEach(model.folders) { folder in
                        EntryRowView(
                            leadingIconName: "folder",
                            title: folder.name,
                            isSelected: selection == folder.name
                        )
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selection = folder.name
                        }
                        .listRowBackground(Color.clear)
                        // I.3 a11y — VoiceOver row label includes the
                        // semantic role ("folder") so users navigating by
                        // ear can distinguish folder rows from entry rows
                        // (which carry no role suffix). The leading icon
                        // is `.accessibilityHidden(true)` inside
                        // `EntryRowView`, so this is the only carrier of
                        // the "folder" semantic.
                        .accessibilityLabel("\(folder.name), folder")
                    }
                }
            }
            // Use a plain `List` without SwiftUI's `List(selection:)` chrome so
            // `EntryRowView` remains the only visible selection indicator.
            .listStyle(.plain)
            // Hide the default list container background for a cleaner custom
            // sidebar surface.
            .scrollContentBackground(.hidden)

            if let gitStatusModel {
                GitStatusBadge(model: gitStatusModel)
                    .padding(.horizontal, theme.spacing.md)
                    .padding(.vertical, theme.spacing.sm)
            }
        }
        .navigationTitle("Kizba")
        .task {
            await favoritesModel.load()
            await model.load()
        }
    }
}
