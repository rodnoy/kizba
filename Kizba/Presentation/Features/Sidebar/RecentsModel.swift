//
//  RecentsModel.swift
//  Kizba
//
//  Observable view model for sidebar recents. Wraps RecentEntriesStoring,
//  exposes a newest-first list of recent entry ids, and keeps it in sync
//  with store change notifications.
//

import Foundation
import Observation

@Observable
@MainActor
final class RecentsModel {

    private(set) var recents: [String] = []

    private let store: any RecentEntriesStoring
    private var observationTask: Task<Void, Never>? = nil

    init(store: any RecentEntriesStoring) {
        self.store = store
    }

    func load() async {
        let current = await store.recentPaths()
        recents = current
        observeChanges()
    }

    func stop() {
        observationTask?.cancel()
        observationTask = nil
    }

    private func observeChanges() {
        guard observationTask == nil else { return }

        let store = self.store
        observationTask = Task { [weak self] in
            for await _ in store.recentsChanged {
                guard !Task.isCancelled else { break }
                let current = await store.recentPaths()
                await MainActor.run {
                    self?.recents = current
                }
            }
        }
    }
}
