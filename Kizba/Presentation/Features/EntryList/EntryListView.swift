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

    /// Sheet-bound form model held in `@State` so it survives parent
    /// re-renders. Constructed by the matching `.onChange(of:
    /// isPresented)` handler exactly once per presentation and
    /// released in the sheet's `onDismiss`. Holding the model in a
    /// view-local `@State` (rather than constructing it inside the
    /// `.sheet { ... }` ViewBuilder closure) prevents a fresh
    /// `EntryFormModel` from being spawned on every parent body
    /// re-render — which previously discarded the in-flight
    /// `.editing → .saved` transition because the new model started
    /// over in `.editing` state.
    @State private var newEntryFormModel: EntryFormModel?

    /// Sheet-bound move model — same rationale as
    /// ``newEntryFormModel`` above. Move was not visibly bugged at
    /// the time of the fix but the anti-pattern is identical.
    @State private var moveEntryModel: MoveEntryModel?

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
                    isSelected: state.router.selectedEntryID == entry.id
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
        .navigationTitle(state.router.selectedFolder ?? "Entries")
        .searchable(text: $state.searchQuery, placement: .toolbar)
        .toolbar {
            ToolbarItem {
                Button {
                    state.router.isNewEntrySheetPresented = true
                } label: {
                    Label("New Entry", systemImage: "plus")
                }
                // Phase G.6 — lock out write affordances while any
                // write op is in flight. The new-entry button has
                // no other gate (it's always available otherwise).
                .disabled(state.anyWriteInFlight)
                .help("New Entry (⌘N)")
            }
            // Phase G.4 — ↔ Move Entry. Same enable rule as the
            // detail-side actions: a non-nil selection is required
            // because move targets the currently-selected entry.
            // Toggles `AppState.isMoveSheetPresented` which the
            // sheet host below consumes.
            ToolbarItem {
                Button {
                    state.router.isMoveEntrySheetPresented = true
                } label: {
                    Label("Move Entry", systemImage: "arrow.left.arrow.right")
                }
                // Phase G.6 — disable when no selection OR when any
                // write op is in flight (concurrent-write lockout).
                .disabled(state.router.selectedEntryID == nil || state.anyWriteInFlight)
                .help("Move Entry (⌘⇧M)")
            }
            // Phase G.5 — 🗑 Delete Entry. Flips
            // `AppState.isDeleteConfirmationPresented`; the
            // `destructiveConfirmation` modifier hosted below
            // renders the system two-step confirmation dialog. The
            // model's `canDelete` folds in both the selection gate
            // and the in-flight delete state so a re-entrant click
            // is impossible.
            ToolbarItem {
                Button {
                    state.router.isDeleteConfirmationPresented = true
                } label: {
                    Label("Delete Entry", systemImage: "trash")
                }
                // Phase G.6 — disable when `canDelete` is false OR
                // when any write op is in flight (concurrent-write
                // lockout). The active delete's own button stays
                // disabled here too — that's intentional; the
                // in-flight Task already runs and a second click
                // would have nothing to do.
                .disabled(model.canDelete == false || state.anyWriteInFlight)
                .help("Delete Entry (⌫)")
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
        // Build the form model BEFORE presenting the sheet so the
        // `.sheet { ... }` ViewBuilder closure can read it from
        // `@State`. Constructing inside the ViewBuilder would
        // re-create the model on every parent re-render (e.g. when
        // `appState.activeWriteOps` mutates or `toastCenter.visible`
        // updates) and the new model would have stale `.editing`
        // state, never observing the prior model's `.saved`
        // transition.
        .onChange(of: state.router.isNewEntrySheetPresented) { _, presented in
            if presented {
                newEntryFormModel = makeNewEntryFormModel()
            }
        }
        .sheet(
            isPresented: $state.router.isNewEntrySheetPresented,
            onDismiss: { newEntryFormModel = nil }
        ) {
            if let model = newEntryFormModel {
                NewEntrySheet(
                    model: model,
                    passwordGenerator: environment.passwordGenerator
                )
            }
        }
        // Same `@State`-held pattern as the New Entry sheet above.
        // The `MoveEntryModel` is built per presentation so the
        // captured original-path is released as soon as SwiftUI
        // tears down the sheet.
        .onChange(of: state.router.isMoveEntrySheetPresented) { _, presented in
            if presented, let path = state.router.selectedEntryID {
                moveEntryModel = makeMoveEntryModel(path: path)
            }
        }
        .sheet(
            isPresented: $state.router.isMoveEntrySheetPresented,
            onDismiss: { moveEntryModel = nil }
        ) {
            if let model = moveEntryModel {
                MoveEntrySheet(model: model)
            } else {
                // Defensive fallback — should be unreachable because
                // the toolbar/menu disable themselves without a
                // selection. Render a minimal placeholder so the
                // sheet is dismissable instead of empty.
                Text("No entry selected.")
                    .padding()
            }
        }
        // Phase G.5 — destructive delete confirmation. The C.1
        // modifier renders a system `confirmationDialog` with a
        // destructive-role confirm button (the "two-step" flow:
        // user clicks 🗑 / hits ⌫, then clicks Delete in the
        // dialog). The Delete button schedules `deleteEntry(at:)`
        // in a fresh Task so the @MainActor closure stays
        // synchronous-looking to the modifier API.
        .destructiveConfirmation(
            isPresented: $state.router.isDeleteConfirmationPresented,
            title: "Delete entry?",
            message: deleteConfirmationMessage,
            confirmLabel: "Delete"
        ) {
            guard let path = state.router.selectedEntryID else { return }
            Task { await model.deleteEntry(at: path) }
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
            appState: state,
            initialPath: Self.initialPath(for: state.router.selectedFolder)
        )
    }

    /// Compute the prefilled `initialPath` for the New Entry form
    /// from the currently selected sidebar folder. A non-empty
    /// folder produces `"<folder>/"` so the user can immediately
    /// type the entry name. A nil or empty folder produces `""` so
    /// the field starts blank (root-level new entry).
    static func initialPath(for selectedFolder: String?) -> String {
        guard let folder = selectedFolder, !folder.isEmpty else {
            return ""
        }
        return "\(folder)/"
    }

    /// Build a fresh `MoveEntryModel` for each presentation of the
    /// move sheet (Phase G.4). The model captures `actionHistory`
    /// and `toastCenter` from `AppState` so the success toast's
    /// Undo action wires through the same in-session undo
    /// coordinator the rest of Phase G consumes.
    private func makeMoveEntryModel(path: String) -> MoveEntryModel {
        MoveEntryModel(
            originalEntry: PassEntry(path: path),
            passManager: environment.passManager,
            actionHistory: state.actionHistory,
            toastCenter: state.toastCenter,
            appState: state
        )
    }

    /// Body text for the destructive delete confirmation dialog
    /// (Phase G.5). Names the entry path so the user can verify the
    /// target before confirming, and surfaces the 10-second Undo
    /// window so the destructive action does not feel terminal.
    private var deleteConfirmationMessage: String {
        let path = state.router.selectedEntryID ?? "the entry"
        return "This will permanently delete \(path). You'll have 10 seconds to undo."
    }
}
