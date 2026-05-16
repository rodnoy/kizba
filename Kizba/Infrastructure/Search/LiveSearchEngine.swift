import Foundation

public actor LiveSearchEngine: EntrySearching {
    private let passManager: any PassManaging

    public init(passManager: any PassManaging) {
        self.passManager = passManager
    }

    public func search(_ query: String) async throws -> [SearchResult] {
        try await search(query, context: nil)
    }

    public func search(_ query: String, context: SearchContext?) async throws -> [SearchResult] {
        try Task.checkCancellation()

        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else {
            return []
        }

        let entries = try await passManager.listEntries()
        try Task.checkCancellation()

        let normalizedQuery = trimmedQuery.lowercased()

        return entries
            .compactMap { entry in
                let path = entry.path
                let title = Self.entryName(from: path)
                guard let baseScore = Self.score(for: normalizedQuery, path: path.lowercased(), title: title.lowercased()) else {
                    return nil
                }

                var score = baseScore
                if let context {
                    if context.favoritePaths.contains(path) {
                        score += 0.05
                    }
                    if context.recentPaths.contains(path) {
                        score += 0.03
                    }
                }
                score = min(1.0, score)

                let subtitle = Self.entryFolder(from: path)
                return SearchResult(id: path, title: title, subtitle: subtitle, score: score)
            }
            .sorted {
                if $0.score != $1.score {
                    return $0.score > $1.score
                }
                return $0.id.localizedCaseInsensitiveCompare($1.id) == .orderedAscending
            }
    }

    private nonisolated static func score(for query: String, path: String, title: String) -> Double? {
        guard !query.isEmpty else { return nil }

        if title == query || path == query {
            return 1.0
        }
        if title.hasPrefix(query) {
            return 0.9
        }
        if path.hasPrefix(query) {
            return 0.8
        }
        if title.contains(query) {
            return 0.7
        }
        if path.contains(query) {
            return 0.6
        }
        return nil
    }

    private nonisolated static func entryName(from path: String) -> String {
        guard let slash = path.lastIndex(of: "/") else {
            return path
        }
        let suffix = String(path[path.index(after: slash)...])
        return suffix.isEmpty ? path : suffix
    }

    private nonisolated static func entryFolder(from path: String) -> String? {
        guard let slash = path.lastIndex(of: "/") else {
            return nil
        }
        let folder = String(path[..<slash])
        return folder.isEmpty ? nil : folder
    }
}
