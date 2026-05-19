import Foundation

/// UserDefaults-backed implementation of ``FolderExpansionStoring``.
///
/// Persists the set of currently expanded folder paths under
/// ``StorageKeys/folderExpansionV1`` as an `[String]`. Mirrors the
/// shape of ``UserDefaultsFavoritesStore`` so subscribers, registration
/// lifecycle and storage discipline are uniform across sidebar
/// persistence surfaces.
public actor UserDefaultsFolderExpansionStore: FolderExpansionStoring {

    nonisolated(unsafe) private let userDefaults: UserDefaults
    private var expanded: Set<String>
    private var continuations: [UUID: AsyncStream<Void>.Continuation] = [:]

    public init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults

        let stored = userDefaults.array(forKey: StorageKeys.folderExpansionV1) as? [String] ?? []
        self.expanded = Set(stored)
    }

    public func isExpanded(_ folderPath: String) async -> Bool {
        expanded.contains(folderPath)
    }

    public func setExpanded(_ folderPath: String, expanded value: Bool) async {
        let changed: Bool
        if value {
            changed = expanded.insert(folderPath).inserted
        } else {
            changed = expanded.remove(folderPath) != nil
        }
        guard changed else { return }
        persist()
        emitChange()
    }

    public nonisolated var folderExpansionChanged: AsyncStream<Void> {
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

    private func persist() {
        userDefaults.set(Array(expanded), forKey: StorageKeys.folderExpansionV1)
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
