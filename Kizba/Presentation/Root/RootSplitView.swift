//
//  RootSplitView.swift
//  Kizba
//
//  Three-column root layout for the Kizba window. The sidebar lists
//  top-level folders, the middle column is the entry list, and the
//  detail column renders the entry inspector via `EntryDetailView`.
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
            EntryDetailView(environment: environment, state: state)
        }
    }
}
