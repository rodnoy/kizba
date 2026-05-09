//
//  EntryListView.swift
//  Kizba
//
//  Middle column of the root `NavigationSplitView`. Renders the list
//  of `PassEntry` rows produced by `EntryListModel`, filtered by the
//  current sidebar folder selection and the live search query held by
//  `AppState`.
//

import SwiftUI

/// Middle (entry list) column of `RootSplitView`.
///
/// The view owns its `EntryListModel` and binds row selection to
/// `AppState.selectedEntryID` so the detail column can react. Search
/// input is wired through `.searchable` against `AppState.searchQuery`.
@MainActor
struct EntryListView: View {

    @Bindable var state: AppState

    @State private var model: EntryListModel

    init(environment: AppEnvironment, state: AppState) {
        self.state = state
        self._model = State(
            initialValue: EntryListModel(environment: environment, state: state)
        )
    }

    var body: some View {
        List {
            ForEach(model.entries) { entry in
                EntryRowView(
                    title: entry.name,
                    subtitle: entry.folder.isEmpty ? nil : entry.path,
                    isSelected: state.selectedEntryID == entry.id
                )
                .contentShape(Rectangle())
                .onTapGesture {
                    model.select(entryID: entry.id)
                }
                .listRowBackground(Color.clear)
            }
        }
        // Use a plain `List` without SwiftUI's `List(selection:)` chrome so
        // `EntryRowView` remains the only visible selection indicator.
        .listStyle(.plain)
        // Hide the default list container background for a cleaner custom
        // entries surface.
        .scrollContentBackground(.hidden)
        .navigationTitle(state.selectedFolder ?? "Entries")
        .searchable(text: $state.searchQuery, placement: .toolbar)
        .toolbar {
            ToolbarItem {
                Button {
                    Task { await model.refresh() }
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
                .keyboardShortcut("r", modifiers: .command)
                .help("Refresh entries (⌘R)")
            }
        }
        .task {
            await model.refresh()
        }
    }
}
