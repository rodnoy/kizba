import Foundation
@testable import Kizba

actor FakeRecentEntriesStore: RecentEntriesStoring {

    private var maxCount: Int
    private var paths: [String]
    private var continuations: [UUID: AsyncStream<Void>.Continuation] = [:]
    /// Records every `setMaxCount(_:)` invocation, in order, so tests can
    /// assert propagation from a presentation-layer model into the actor
    /// store (MVP6 Phase A.4 — `SettingsModel.save()` forwards the limit).
    private(set) var setMaxCountCalls: [Int] = []

    init(
        initialPaths: [String] = [],
        maxCount: Int = SettingsKeys.defaultRecentsLimit
    ) {
        self.maxCount = max(1, maxCount)
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
        setMaxCountCalls.append(newValue)
        let clamped = max(1, newValue)
        guard clamped != maxCount else { return }
        maxCount = clamped
        if paths.count > clamped {
            paths = Array(paths.prefix(clamped))
        }
        emitChange()
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
