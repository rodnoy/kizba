import Foundation

public protocol RecentEntriesStoring: Sendable {
    func record(_ path: String) async
    func recentPaths() async -> [String]
    func clear() async
    var recentsChanged: AsyncStream<Void> { get }
}
