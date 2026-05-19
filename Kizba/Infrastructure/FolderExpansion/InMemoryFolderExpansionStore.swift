#if DEBUG
import Foundation

/// In-memory folder-expansion store used by preview/test wiring.
actor InMemoryFolderExpansionStore: FolderExpansionStoring {

    private var expanded: Set<String>
    private var continuations: [UUID: AsyncStream<Void>.Continuation] = [:]

    init(initialExpanded: Set<String> = []) {
        self.expanded = initialExpanded
    }

    func isExpanded(_ folderPath: String) async -> Bool {
        expanded.contains(folderPath)
    }

    func setExpanded(_ folderPath: String, expanded value: Bool) async {
        let changed: Bool
        if value {
            changed = expanded.insert(folderPath).inserted
        } else {
            changed = expanded.remove(folderPath) != nil
        }
        guard changed else { return }
        emitChange()
    }

    nonisolated var folderExpansionChanged: AsyncStream<Void> {
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
