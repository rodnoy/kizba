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
                    Label(folder.name, systemImage: "folder")
                        .tag(folder.name as String?)
                }
            }
        }
        .navigationTitle("Kizba")
        .task {
            await model.load()
        }
    }
}
