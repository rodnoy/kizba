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

    /// Captured composition root used to construct an
    /// `EntryFormModel` on demand when the user opens the New Entry
    /// sheet. Held as a stored property because `AppEnvironment` is
    /// a value type and capturing it in `body` would re-construct
    /// services on every redraw.
    private let environment: AppEnvironment

    init(environment: AppEnvironment, state: AppState) {
        self.environment = environment
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
                    state.isNewEntrySheetPresented = true
                } label: {
                    Label("New Entry", systemImage: "plus")
                }
                .help("New Entry (⌘N)")
            }
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
        .sheet(isPresented: $state.isNewEntrySheetPresented) {
            NewEntrySheet(
                model: makeNewEntryFormModel(),
                passwordGenerator: environment.passwordGenerator
            )
        }
        .task {
            await model.refresh()
        }
        // Phase F.5 — long-lived subscription to `pass.changes` so
        // any successful write (insert / update / remove / move /
        // bulk) re-lists automatically. The `.task` modifier scopes
        // the subscription to this view's lifetime: SwiftUI cancels
        // the surrounding task on disappear, `observeChanges()` sees
        // the cancellation and returns cleanly.
        .task {
            await model.observeChanges()
        }
    }

    /// Build a fresh `EntryFormModel` in `.create` mode for each
    /// presentation of the sheet. Constructing per-presentation
    /// (rather than holding a long-lived instance on `AppState`)
    /// guarantees the previous draft's cleartext is released as
    /// soon as SwiftUI tears down the sheet — `EntryFormModel`
    /// itself drops its draft in `handleDismissal()` too, so this
    /// is belt-and-braces.
    private func makeNewEntryFormModel() -> EntryFormModel {
        EntryFormModel(
            mode: .create,
            passManager: environment.passManager,
            toastCenter: state.toastCenter,
            appState: state
        )
    }
}
