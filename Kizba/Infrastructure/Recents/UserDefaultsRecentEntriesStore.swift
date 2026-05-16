import Foundation

public actor UserDefaultsRecentEntriesStore: RecentEntriesStoring {

    private enum Keys {
        static let recentEntries = "kizba.recentEntries"
    }

    nonisolated(unsafe) private let defaults: UserDefaults
    private let maxCount: Int
    private var paths: [String]
    private var continuations: [UUID: AsyncStream<Void>.Continuation] = [:]

    public init(defaults: UserDefaults = .standard, maxCount: Int = 20) {
        self.defaults = defaults
        self.maxCount = max(1, maxCount)

        if let stored = defaults.array(forKey: Keys.recentEntries) as? [String] {
            self.paths = Self.normalized(stored, maxCount: max(1, maxCount))
        } else {
            self.paths = []
        }
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
        defaults.set(paths, forKey: Keys.recentEntries)
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
