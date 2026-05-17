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

    /// Entry selection bound to `AppState.router.selectedEntryID` so
    /// the detail column can react to it. Used by Recents and
    /// Favorites rows; folder rows continue to write into `selection`.
    ///
    /// MVP6 Phase G.2: prior to this binding, Recents/Favorites taps
    /// wrote entry paths into `selection` (i.e. `selectedFolder`),
    /// which the middle column consumes as a folder name — so the
    /// detail column never opened. The two slots are now routed
    /// independently.
    @Binding var entrySelection: String?

    @State private var model: SidebarModel
    @State private var favoritesModel: FavoritesModel
    @State private var recentsModel: RecentsModel
    private let gitStatusModel: GitStatusModel?
    @Environment(\.theme) private var theme

    // MVP6 Phase A.3: Recents section is user-controllable.
    // `showRecents` is owned by Settings and lives under the
    // `app.kizba.settings.` namespace; the key string MUST match
    // `SettingsKeys.showRecents` exactly so the Settings toggle and
    // this `@AppStorage` reference the same UserDefaults slot.
    // `recentsExpanded` is purely a sidebar UI state (collapse
    // chevron) and is kept under a separate `kizba.sidebar.` prefix.
    @AppStorage("app.kizba.settings.showRecents") private var showRecents: Bool = true
    @AppStorage("kizba.sidebar.recentsExpanded") private var recentsExpanded: Bool = true

    // MVP6 Phase G.1: Favorites controls mirror Recents.
    // `showFavorites` shares the Settings namespace — the key MUST
    // match `SettingsKeys.showFavorites` exactly (`namespaced(...)` in
    // `UserDefaultsSettingsStore` produces this string) so the Settings
    // toggle and the sidebar read the same UserDefaults slot.
    // `favoritesExpanded` is sidebar-local UI state.
    @AppStorage("app.kizba.settings.showFavorites") private var showFavorites: Bool = true
    @AppStorage("kizba.sidebar.favoritesExpanded") private var favoritesExpanded: Bool = true

    init(
        environment: AppEnvironment,
        selection: Binding<String?>,
        entrySelection: Binding<String?>,
        gitStatusModel: GitStatusModel? = nil
    ) {
        self._selection = selection
        self._entrySelection = entrySelection
        self._model = State(initialValue: SidebarModel(passManager: environment.passManager))
        self._favoritesModel = State(initialValue: FavoritesModel(store: environment.favoritesStore))
        self._recentsModel = State(initialValue: RecentsModel(
            store: environment.recentStore,
            validator: environment.recentsValidator
        ))
        self.gitStatusModel = gitStatusModel
    }

    var body: some View {
        VStack(spacing: 0) {
            List {
                // MVP6 Phase G.1: Favorites is gated by Settings.showFavorites
                // and collapsible via a DisclosureGroup whose expansion state
                // persists across launches. When `showFavorites == false` or
                // the favorites set is empty the section is elided entirely,
                // matching the Recents semantics (Phase A.3).
                if showFavorites && !favoritesModel.favorites.isEmpty {
                    Section {
                        DisclosureGroup(isExpanded: $favoritesExpanded) {
                            ForEach(favoritesModel.favorites, id: \.self) { entryPath in
                                EntryRowView(
                                    leadingIconName: "star.fill",
                                    title: entryPath.components(separatedBy: "/").last ?? entryPath,
                                    isSelected: entrySelection == entryPath
                                )
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    // MVP6 Phase G.2: route into the
                                    // entry slot, not the folder slot.
                                    entrySelection = entryPath
                                }
                                .listRowBackground(Color.clear)
                                .accessibilityLabel("\(entryPath), favorite")
                            }
                        } label: {
                            Text("Favorites")
                        }
                    }
                }

                // MVP6 Phase A.3: Recents is gated by Settings.showRecents
                // and collapsible via a DisclosureGroup whose expansion
                // state persists across launches. When `showRecents == false`
                // the section is elided entirely (not just hidden), so the
                // List does not reserve any layout for it.
                if showRecents && !recentsModel.recents.isEmpty {
                    Section {
                        DisclosureGroup(isExpanded: $recentsExpanded) {
                            ForEach(recentsModel.recents, id: \.self) { entryPath in
                                EntryRowView(
                                    title: entryPath.components(separatedBy: "/").last ?? entryPath,
                                    isSelected: entrySelection == entryPath
                                )
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    // MVP6 Phase G.2: route into the
                                    // entry slot, not the folder slot.
                                    entrySelection = entryPath
                                }
                                .listRowBackground(Color.clear)
                                .accessibilityLabel("\(entryPath), recent")
                            }
                        } label: {
                            Text("Recents")
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
            await recentsModel.load()
            await model.load()
        }
    }
}
