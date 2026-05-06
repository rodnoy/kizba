//
//  RootSplitView.swift
//  Kizba
//
//  Three-column root layout for the Kizba window. The sidebar lists
//  top-level folders, the middle column is the entry list, and the
//  detail column renders the entry inspector. The real detail surface
//  lands in step 2.5; this slice wires the layout end-to-end so the
//  remaining step can plug content without further restructuring.
//

import SwiftUI

/// Root `NavigationSplitView` for the Kizba window.
///
/// Dependencies (`AppEnvironment`, `AppState`) are injected via the
/// initializer rather than `EnvironmentObject` — domain services flow
/// through explicit DI per `.ai/decisions.md`.
@MainActor
struct RootSplitView: View {

    let environment: AppEnvironment

    @Bindable var state: AppState

    init(environment: AppEnvironment, state: AppState) {
        self.environment = environment
        self.state = state
    }

    var body: some View {
        NavigationSplitView {
            SidebarView(
                environment: environment,
                selection: $state.selectedFolder
            )
        } content: {
            EntryListView(environment: environment, state: state)
        } detail: {
            EmptyDetailView()
        }
    }
}

/// Placeholder for the upcoming `EntryDetailView` (step 2.5).
private struct EmptyDetailView: View {
    var body: some View {
        Text("No entry selected")
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle("Detail")
    }
}
