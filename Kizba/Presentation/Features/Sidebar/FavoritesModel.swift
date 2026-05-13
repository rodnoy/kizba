//
//  FavoritesModel.swift
//  Kizba
//
//  Observable view model for sidebar favorites. Wraps FavoritesStoring,
//  exposes a sorted list of favorite entry ids, and keeps it in sync with
//  store change notifications.
//

import Foundation
import Observation

@Observable
@MainActor
final class FavoritesModel {

    private(set) var favorites: [String] = []

    private let store: any FavoritesStoring
    private var observationTask: Task<Void, Never>? = nil

    init(store: any FavoritesStoring) {
        self.store = store
    }

    func load() async {
        // Initial snapshot for immediate UI rendering.
        let current = await store.allFavorites()
        favorites = current.sorted()
        observeChanges()
    }

    func toggle(_ id: String) async {
        await store.toggleFavorite(id)

        // Refresh eagerly so toggles are reflected immediately.
        let current = await store.allFavorites()
        favorites = current.sorted()
    }

    func isFavorite(_ id: String) async -> Bool {
        await store.isFavorite(id)
    }

    func stop() {
        observationTask?.cancel()
        observationTask = nil
    }

    private func observeChanges() {
        guard observationTask == nil else { return }

        // Keep observing mutation events until cancellation.
        let store = self.store
        observationTask = Task { [weak self] in
            for await _ in store.favoritesChanged {
                guard !Task.isCancelled else { break }
                let current = await store.allFavorites()
                await MainActor.run {
                    self?.favorites = current.sorted()
                }
            }
        }
    }
}
