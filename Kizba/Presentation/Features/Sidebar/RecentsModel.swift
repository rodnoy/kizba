//
//  RecentsModel.swift
//  Kizba
//
//  Observable view model for sidebar recents. Wraps RecentEntriesStoring,
//  exposes a newest-first list of recent entry ids, and keeps it in sync
//  with store change notifications.
//
//  MVP6 Phase H.2: the model now consults an optional
//  `RecentEntriesValidating` after every store read so paths that no
//  longer exist in the user's password store (legacy fixtures, deleted
//  entries, typoed records from old DEBUG builds) are dropped before
//  reaching the sidebar. The validator is optional with a `nil`
//  default so existing test/preview call sites that do not care about
//  filtering keep working unchanged — `nil` means "trust the store".
//

import Foundation
import Observation

@Observable
@MainActor
final class RecentsModel {

    private(set) var recents: [String] = []

    private let store: any RecentEntriesStoring
    private let validator: (any RecentEntriesValidating)?
    private var observationTask: Task<Void, Never>? = nil

    init(
        store: any RecentEntriesStoring,
        validator: (any RecentEntriesValidating)? = nil
    ) {
        self.store = store
        self.validator = validator
    }

    func load() async {
        let current = await store.recentPaths()
        recents = await Self.filter(current, with: validator)
        observeChanges()
    }

    func stop() {
        observationTask?.cancel()
        observationTask = nil
    }

    private func observeChanges() {
        guard observationTask == nil else { return }

        // Capture Sendable dependencies into locals so the detached
        // observation task does not touch MainActor-isolated state.
        let store = self.store
        let validator = self.validator
        observationTask = Task { [weak self] in
            for await _ in store.recentsChanged {
                guard !Task.isCancelled else { break }
                let current = await store.recentPaths()
                let filtered = await Self.filter(current, with: validator)
                await MainActor.run {
                    self?.recents = filtered
                }
            }
        }
    }

    /// Apply the validator (if any) to the supplied path list.
    /// Static + nonisolated so both the MainActor `load()` and the
    /// background observation task can call it without isolation hops.
    private nonisolated static func filter(
        _ paths: [String],
        with validator: (any RecentEntriesValidating)?
    ) async -> [String] {
        guard let validator else { return paths }
        return await validator.validate(paths)
    }
}
