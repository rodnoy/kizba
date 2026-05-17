import Foundation

public actor UserDefaultsRecentEntriesStore: RecentEntriesStoring {

    nonisolated(unsafe) private let defaults: UserDefaults
    private var maxCount: Int
    private var paths: [String]
    private var continuations: [UUID: AsyncStream<Void>.Continuation] = [:]

    public init(
        defaults: UserDefaults = .standard,
        maxCount: Int = SettingsKeys.defaultRecentsLimit
    ) {
        self.defaults = defaults
        let clamped = Self.clamp(maxCount)
        self.maxCount = clamped

        if let stored = defaults.array(forKey: StorageKeys.recentsEntriesV1) as? [String] {
            self.paths = Self.normalized(stored, maxCount: clamped)
        } else {
            self.paths = []
        }

        // G.3: best-effort cleanup of legacy un-namespaced key.
        // No value migration — Recents is auto-collected; safer to drop polluted DEBUG fixture data
        // than to risk promoting it to production.
        defaults.removeObject(forKey: StorageKeys.legacyRecentsEntries)
    }

    public func record(_ path: String) async {
        var updated = paths
        updated.removeAll { $0 == path }
        updated.insert(path, at: 0)
        if updated.count > maxCount {
            updated.removeSubrange(maxCount..<updated.count)
        }

        guard updated != paths else { return }
        paths = updated
        persistPaths()
        emitChange()
    }

    public func recentPaths() async -> [String] {
        paths
    }

    public func clear() async {
        guard paths.isEmpty == false else { return }
        paths.removeAll(keepingCapacity: false)
        persistPaths()
        emitChange()
    }

    public func setMaxCount(_ newValue: Int) async {
        let clamped = Self.clamp(newValue)
        guard clamped != maxCount else { return }
        maxCount = clamped
        if paths.count > clamped {
            paths = Array(paths.prefix(clamped))
        }
        // Persist first, then emit exactly one change event.
        persistPaths()
        emitChange()
    }

    public nonisolated var recentsChanged: AsyncStream<Void> {
        AsyncStream { continuation in
            let id = UUID()
            Task { [weak self] in
                await self?.register(id: id, continuation: continuation)
            }
            continuation.onTermination = { [weak self] _ in
                Task { [weak self] in
                    await self?.unregister(id: id)
                }
            }
        }
    }

    private func persistPaths() {
        defaults.set(paths, forKey: StorageKeys.recentsEntriesV1)
    }

    private func emitChange() {
        for continuation in continuations.values {
            continuation.yield(())
        }
    }

    private func register(id: UUID, continuation: AsyncStream<Void>.Continuation) {
        continuations[id] = continuation
    }

    private func unregister(id: UUID) {
        continuations.removeValue(forKey: id)
    }

    private nonisolated static func clamp(_ value: Int) -> Int {
        min(
            max(value, SettingsKeys.minRecentsLimit),
            SettingsKeys.maxRecentsLimit
        )
    }

    private nonisolated static func normalized(_ stored: [String], maxCount: Int) -> [String] {
        var seen = Set<String>()
        var result: [String] = []
        result.reserveCapacity(min(stored.count, maxCount))

        for path in stored {
            let inserted = seen.insert(path).inserted
            guard inserted else { continue }
            result.append(path)
            if result.count == maxCount { break }
        }

        return result
    }
}
