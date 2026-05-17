#if DEBUG
import Foundation

actor InMemoryRecentEntriesStore: RecentEntriesStoring {

    private var maxCount: Int
    private var paths: [String]
    private var continuations: [UUID: AsyncStream<Void>.Continuation] = [:]

    init(
        initialPaths: [String] = [],
        maxCount: Int = SettingsKeys.defaultRecentsLimit
    ) {
        self.maxCount = Self.clamp(maxCount)
        self.paths = Array(initialPaths.prefix(self.maxCount))
    }

    func record(_ path: String) async {
        var updated = paths
        updated.removeAll { $0 == path }
        updated.insert(path, at: 0)
        if updated.count > maxCount {
            updated.removeSubrange(maxCount..<updated.count)
        }

        guard updated != paths else { return }
        paths = updated
        emitChange()
    }

    func recentPaths() async -> [String] {
        paths
    }

    func clear() async {
        guard paths.isEmpty == false else { return }
        paths.removeAll(keepingCapacity: false)
        emitChange()
    }

    func setMaxCount(_ newValue: Int) async {
        let clamped = Self.clamp(newValue)
        guard clamped != maxCount else { return }
        maxCount = clamped
        if paths.count > clamped {
            paths = Array(paths.prefix(clamped))
        }
        // Mirror UserDefaultsRecentEntriesStore: persist (n/a here),
        // then emit exactly one change event.
        emitChange()
    }

    private nonisolated static func clamp(_ value: Int) -> Int {
        min(
            max(value, SettingsKeys.minRecentsLimit),
            SettingsKeys.maxRecentsLimit
        )
    }

    nonisolated var recentsChanged: AsyncStream<Void> {
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
}
#endif
