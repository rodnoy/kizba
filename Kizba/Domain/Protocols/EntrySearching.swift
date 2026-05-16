import Foundation

public struct SearchContext: Sendable {
    public let favoritePaths: Set<String>
    public let recentPaths: Set<String>

    public init(favoritePaths: Set<String> = [], recentPaths: Set<String> = []) {
        self.favoritePaths = favoritePaths
        self.recentPaths = recentPaths
    }
}

public protocol EntrySearching: Sendable {
    /// Return ordered search results for `query`.
    func search(_ query: String) async throws -> [SearchResult]
    func search(_ query: String, context: SearchContext?) async throws -> [SearchResult]
}

public extension EntrySearching {
    func search(_ query: String) async throws -> [SearchResult] {
        try await search(query, context: nil)
    }
}
