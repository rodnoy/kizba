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
    let searchModel: SearchModel

    @Bindable var state: AppState

    init(environment: AppEnvironment, searchModel: SearchModel, state: AppState) {
        self.environment = environment
        self.searchModel = searchModel
        self.state = state
    }

    var body: some View {
        NavigationSplitView {
            SidebarView(
                environment: environment,
                selection: Binding(
                    get: { state.router.selectedFolder },
                    set: { state.router.selectedFolder = $0 }
                ),
                gitStatusModel: state.gitStatusModel
            )
        } content: {
            EntryListView(environment: environment, state: state)
        } detail: {
            EntryDetailView(environment: environment, state: state)
        }
        // Phase F.1: a single `ToastOverlay` mounted at the root,
        // bottom-trailing aligned, observing the live `ToastCenter`
        // owned by `AppState`. View models post toasts via
        // `state.toastCenter.post(...)`; the overlay re-renders
        // automatically via `@Observable`.
        .overlay(alignment: .bottomTrailing) {
            ToastOverlay(toast: state.toastCenter.visible)
        }
        .overlay(alignment: .center) {
            if state.router.isSearchSheetPresented {
                SearchOverlayView(
                    model: searchModel,
                    onSelect: { result in
                        state.router.selectedEntryID = result.id
                        state.router.isSearchSheetPresented = false
                        searchModel.cancel()
                    },
                    onDismiss: {
                        state.router.isSearchSheetPresented = false
                        searchModel.cancel()
                    }
                )
            }
        }
    }
}
