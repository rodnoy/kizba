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
        List(selection: selectionBinding) {
            ForEach(model.entries) { entry in
                EntryRowView(
                    title: entry.name,
                    subtitle: entry.folder.isEmpty ? nil : entry.path,
                    isSelected: state.selectedEntryID == entry.id
                )
                .tag(entry.id as PassEntry.ID?)
            }
        }
        // Phase C.5 — suppress `List`'s default per-row selection chrome
        // (system accent fill) so the row's own `surfaceSelected`
        // background from `EntryRowView` is the sole selection
        // indicator. `.plain` was chosen over `.sidebar` (which is
        // semantically reserved for the leftmost split-view column)
        // and over a custom `ScrollView { LazyVStack { … } }`
        // (which would lose `List(selection:)`'s built-in arrow-key
        // navigation + accessibility wiring).
        .listStyle(.plain)
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

    /// Bridges SwiftUI `List` selection to the model's `select` helper
    /// so `AppState.selectedEntryID` stays the single source of truth.
    private var selectionBinding: Binding<PassEntry.ID?> {
        Binding(
            get: { state.selectedEntryID },
            set: { model.select(entryID: $0) }
        )
    }
}
