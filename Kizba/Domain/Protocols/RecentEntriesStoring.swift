import Foundation

public protocol RecentEntriesStoring: Sendable {
    func record(_ path: String) async
    func recentPaths() async -> [String]
    func clear() async
    /// Update the maximum number of recent entries retained by the store.
    ///
    /// Implementations must clamp `newValue` to
    /// ``SettingsKeys/recentsLimitBounds`` (currently `3...7`), truncate any
    /// existing entries beyond the new cap, persist first, then emit at most
    /// one ``recentsChanged`` event. No-op when the clamped value matches
    /// the current `maxCount`.
    func setMaxCount(_ newValue: Int) async
    var recentsChanged: AsyncStream<Void> { get }
}
