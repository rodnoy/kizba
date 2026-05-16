import Foundation
@testable import Kizba

actor FakeRecentEntriesStore: RecentEntriesStoring {

    private var paths: [String]
    private var continuations: [UUID: AsyncStream<Void>.Continuation] = [:]

    init(initialPaths: [String] = []) {
        self.paths = initialPaths
    }

    func record(_ path: String) async {
        var updated = paths
        updated.removeAll { $0 == path }
        updated.insert(path, at: 0)
        if updated.count > 20 {
            updated.removeSubrange(20..<updated.count)
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
