// StoreWatching.swift
// Kizba

import Foundation

/// Protocol for filesystem store change watching.
/// Foundation-only. Implementations may use platform APIs (FSEvents) in Infrastructure.
protocol StoreWatching: Sendable {
    /// Multi-subscriber async stream of change notifications.
    var events: AsyncStream<Void> { get }

    /// Start watching the given store root. Implementations may attach platform watchers.
    func start(at storeRoot: URL) async

    /// Stop watching and clean up resources.
    func stop() async
}
