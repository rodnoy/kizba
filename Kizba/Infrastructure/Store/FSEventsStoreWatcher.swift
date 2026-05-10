// FSEventsStoreWatcher.swift
// Kizba

import Foundation
import CoreServices

// Actor owning continuations for multi-subscriber AsyncStream<Void>.
private actor ContinuationStore {
    var continuations: [UUID: AsyncStream<Void>.Continuation] = [:]

    // Async API per design requirements.
    func addContinuation(_ id: UUID, _ cont: AsyncStream<Void>.Continuation) async {
        continuations[id] = cont
    }

    func removeContinuation(_ id: UUID) async {
        continuations.removeValue(forKey: id)
    }

    func emitAll() async {
        for (_, cont) in continuations {
            cont.yield(())
        }
    }

    func finishAll() async {
        for (_, cont) in continuations {
            cont.finish()
        }
        continuations.removeAll()
    }
}

/// FSEvents-backed implementation of StoreWatching.
public final class FSEventsStoreWatcher: StoreWatching, @unchecked Sendable {
    // Serial queue for all FSEvents C API usage and timer handling.
    let queue = DispatchQueue(label: "kizba.fsevents")

    // Continuation actor. Actor methods are invoked from any context.
    private let store = ContinuationStore()

    // Stream and timer must be confined to `queue`.
    private var streamRef: FSEventStreamRef? = nil
    private var debounceTimer: DispatchSourceTimer? = nil

    public init() {}

    deinit {
        // Best-effort cleanup: perform invalidation on queue and finish continuations.
        queue.sync {
            if let s = streamRef {
                FSEventStreamStop(s)
                FSEventStreamInvalidate(s)
                FSEventStreamRelease(s)
                streamRef = nil
            }
            debounceTimer?.cancel()
            debounceTimer = nil
        }
        // Use a detached Task to avoid capturing `self`'s lifetime in a closure that outlives deinit.
        Task.detached { [store] in
            await store.finishAll()
        }
    }

    // Multi-subscriber AsyncStream. Each registration registers its continuation with the actor.
    public var events: AsyncStream<Void> {
        return AsyncStream<Void> { continuation in
            let id = UUID()
            // Register continuation on the actor.
            Task { await store.addContinuation(id, continuation) }

            continuation.onTermination = { @Sendable _ in
                Task { await self.store.removeContinuation(id) }
            }
        }
    }

    // MARK: Start / Stop

    public func start(at storeRoot: URL) async {
        // Create and start the FSEventStream on the dedicated queue.
        queue.async { [weak self] in
            guard let self = self else { return }

            // Ensure there's no existing stream.
            if let s = self.streamRef {
                FSEventStreamStop(s)
                FSEventStreamInvalidate(s)
                FSEventStreamRelease(s)
                self.streamRef = nil
            }

            // Paths to watch
            let paths = [storeRoot.path] as CFArray

            // Client info pointer: pass unretained self.
            // Build the FSEventStreamContext with the unretained self pointer.
            var context = FSEventStreamContext(version: 0, info: Unmanaged.passUnretained(self).toOpaque(), retain: nil, release: nil, copyDescription: nil)

            // Callback
            let callback: FSEventStreamCallback = { (_streamRef, clientCallBackInfo, numEvents, eventPaths, eventFlags, eventIds) in
                guard let client = clientCallBackInfo else { return }
                let watcher = Unmanaged<FSEventsStoreWatcher>.fromOpaque(client).takeUnretainedValue()
                // We're already on the dispatch queue set for the stream; schedule debounce work here.
                watcher.scheduleDebounce()
            }

            let flags = FSEventStreamCreateFlags(kFSEventStreamCreateFlagFileEvents | kFSEventStreamCreateFlagNoDefer)

            let stream = FSEventStreamCreate(kCFAllocatorDefault, callback, &context, paths, FSEventStreamEventId(kFSEventStreamEventIdSinceNow), 0, flags)
            guard let stream = stream else { return }

            // Set dispatch queue; the callback will now be invoked on `queue`.
            FSEventStreamSetDispatchQueue(stream, self.queue)

            if !FSEventStreamStart(stream) {
                // Failed to start — release stream and bail.
                FSEventStreamInvalidate(stream)
                FSEventStreamRelease(stream)
                return
            }

            self.streamRef = stream
        }
    }

    public func stop() async {
        // Invalidate stream and cancel timer on the queue, then finish continuations.
        await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
            queue.async { [weak self] in
                guard let self = self else { cont.resume(); return }
                if let s = self.streamRef {
                    FSEventStreamStop(s)
                    FSEventStreamInvalidate(s)
                    FSEventStreamRelease(s)
                    self.streamRef = nil
                }
                self.debounceTimer?.cancel()
                self.debounceTimer = nil
                cont.resume()
            }
        }

        await store.finishAll()
    }

    // MARK: Debounce handling (confined to `queue`)

    private func scheduleDebounce() {
        // This method is always called on `queue`.
        // Cancel existing timer and schedule a trailing-edge timer for 350 ms.
        debounceTimer?.cancel()

        let timer = DispatchSource.makeTimerSource(queue: queue)
        timer.schedule(deadline: .now() + .milliseconds(350))
        timer.setEventHandler { [weak self] in
            guard let self = self else { return }
            // When the timer fires, emit to all continuations via the actor.
            Task { await self.store.emitAll() }
            // Clear timer reference.
            self.debounceTimer?.cancel()
            self.debounceTimer = nil
        }
        debounceTimer = timer
        timer.activate()
    }
}
