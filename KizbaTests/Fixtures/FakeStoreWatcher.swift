import Foundation
@testable import Kizba

/// In-memory test double for `StoreWatching`.
/// Thread-safe via an internal serial DispatchQueue. Stores per-subscriber
/// continuations so tests can simulate change events deterministically.
final class FakeStoreWatcher: StoreWatching, @unchecked Sendable {

    private let lock = DispatchQueue(label: "kizba.fakeStoreWatcher")

    private struct Holder {
        let id: UUID
        var continuation: AsyncStream<Void>.Continuation
    }

    private var continuations: [Holder] = []
    private var startCount: Int = 0
    private var stopCount: Int = 0
    private(set) var storeRoot: URL?

    init() {}

    var events: AsyncStream<Void> {
        AsyncStream<Void>(bufferingPolicy: .unbounded) { continuation in
            let id = UUID()
            let holder = Holder(id: id, continuation: continuation)
            lock.sync {
                continuations.append(holder)
            }

            continuation.onTermination = { @Sendable _ in
                // Remove the continuation when the stream is terminated.
                self.lock.sync {
                    if let idx = self.continuations.firstIndex(where: { $0.id == id }) {
                        self.continuations.remove(at: idx)
                    }
                }
            }
        }
    }

    func start(at storeRoot: URL) async {
        lock.sync {
            startCount += 1
            self.storeRoot = storeRoot
        }
    }

    func stop() async {
        // Finish and clear all continuations.
        let toFinish: [AsyncStream<Void>.Continuation] = lock.sync {
            stopCount += 1
            let list = continuations.map { $0.continuation }
            continuations.removeAll()
            return list
        }
        for cont in toFinish {
            cont.finish()
        }
    }

    /// Yield a change event to all current subscribers.
    func simulateChange() {
        // Copy continuations under lock then yield outside the sync
        let current: [AsyncStream<Void>.Continuation] = lock.sync {
            continuations.map { $0.continuation }
        }
        for cont in current {
            cont.yield(())
        }
    }

    // MARK: - Test accessors

    func getStartCount() -> Int {
        return lock.sync { startCount }
    }

    func getStopCount() -> Int {
        return lock.sync { stopCount }
    }
}
