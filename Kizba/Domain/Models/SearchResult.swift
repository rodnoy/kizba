import Foundation

public struct SearchResult: Sendable, Equatable, Hashable, Identifiable {
    public let id: String // stable id (entry path)
    public let title: String
    public let subtitle: String? // e.g. folder or snippet
    public let score: Double

    public nonisolated init(id: String, title: String, subtitle: String?, score: Double) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.score = score
    }
}
