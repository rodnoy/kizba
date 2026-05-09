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

    init(environment: AppEnvironment, selection: Binding<String?>) {
        self._selection = selection
        self._model = State(initialValue: SidebarModel(passManager: environment.passManager))
    }

    var body: some View {
        List(selection: $selection) {
            Section("Folders") {
                ForEach(model.folders) { folder in
                    EntryRowView(
                        leadingIconName: "folder",
                        title: folder.name,
                        isSelected: selection == folder.name
                    )
                    .tag(folder.name as String?)
                }
            }
        }
        // Phase C.6 — match `EntryListView`: suppress `List`'s default
        // per-row selection chrome (system accent fill) so the row's
        // own `surfaceSelected` background from `EntryRowView` is the
        // sole selection indicator. `.plain` is used (rather than
        // `.sidebar`) for visual consistency with the middle column —
        // the goal of this phase is a single themed selection language
        // across the split view, not a macOS-native sidebar look.
        .listStyle(.plain)
        .navigationTitle("Kizba")
        .task {
            await model.load()
        }
    }
}
