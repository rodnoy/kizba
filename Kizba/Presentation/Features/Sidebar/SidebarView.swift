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
        List {
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
        .navigationTitle("Kizba")
        .task {
            await model.load()
        }
    }
}
