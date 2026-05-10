// FSEventsStoreWatcher.swift
// Kizba

import Foundation
import CoreServices

@unchecked Sendable final class FSEventsStoreWatcher: StoreWatching {
    private let queue = DispatchQueue(label: "kizba.fsevents")
    private var stream: FSEventStreamRef? = nil
    private var continuations: [UUID: AsyncStream<Void>.Continuation] = [:]
    private var debounceTimer: DispatchSourceTimer? = nil
    private let debounceInterval: TimeInterval = 0.350
    private(set) var isStarted = false

    var events: AsyncStream<Void> {
        AsyncStream { [weak self] continuation in
            guard let self = self else {
                continuation.finish()
                return
            }

            let id = UUID()
            // Register continuation on the serial queue to keep synchronization simple.
            self.queue.async {
                self.continuations[id] = continuation
            }

            continuation.onTermination = { @Sendable _ in
                // Unregister on the serial queue.
                self.queue.async {
                    self.continuations.removeValue(forKey: id)
                }
            }
        }
    }

    func start(at storeRoot: URL) async {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            queue.async { [weak self] in
                guard let self = self else {
                    continuation.resume()
                    return
                }

                if self.isStarted {
                    continuation.resume()
                    return
                }

                // Prepare paths
                let paths = [storeRoot.path] as CFArray

                // Context pointer
                var context = FSEventStreamContext(version: 0,
                                                   info: Unmanaged.passUnretained(self).toOpaque(),
                                                   retain: nil,
                                                   release: nil,
                                                   copyDescription: nil)

                let flags = FSEventStreamCreateFlags(kFSEventStreamCreateFlagFileEvents | kFSEventStreamCreateFlagNoDefer)

                guard let stream = FSEventStreamCreate(nil,
                                                      { (streamRef, clientCallBackInfo, numEvents, eventIds, eventFlags, eventPaths) in
                    // Callback invoked by FSEvents on our dispatch queue.
                    guard let info = clientCallBackInfo else { return }
                    let watcher = Unmanaged<FSEventsStoreWatcher>.fromOpaque(info).takeUnretainedValue()

                    // Schedule trailing-edge debounce on the serial queue.
                    watcher.queue.async {
                        // Cancel existing timer and create a new one for trailing-edge debounce.
                        if let t = watcher.debounceTimer {
                            t.cancel()
                            watcher.debounceTimer = nil
                        }

                        let timer = DispatchSource.makeTimerSource(queue: watcher.queue)
                        timer.schedule(deadline: .now() + watcher.debounceInterval)
                        timer.setEventHandler { [weak watcher] in
                            guard let watcher = watcher else { return }
                            watcher.debounceTimer = nil
                            watcher.emit()
                        }
                        watcher.debounceTimer = timer
                        timer.resume()
                    }
                }, &context, paths, FSEventStreamEventId(kFSEventStreamEventIdSinceNow), 0, flags) else {
                    // Failed to create stream
                    continuation.resume()
                    return
                }

                self.stream = stream
                // Schedule on our dispatch queue and start
                FSEventStreamSetDispatchQueue(stream, self.queue)
                FSEventStreamStart(stream)
                self.isStarted = true

                continuation.resume()
            }
        }
    }

    func stop() async {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            queue.async { [weak self] in
                guard let self = self else {
                    continuation.resume()
                    return
                }

                if let timer = self.debounceTimer {
                    timer.cancel()
                    self.debounceTimer = nil
                }

                if let stream = self.stream {
                    FSEventStreamStop(stream)
                    FSEventStreamInvalidate(stream)
                    FSEventStreamRelease(stream)
                    self.stream = nil
                }

                // Finish all continuations
                for (_, cont) in self.continuations {
                    cont.finish()
                }
                self.continuations.removeAll()
                self.isStarted = false

                continuation.resume()
            }
        }
    }

    deinit {
        // Fire-and-forget stop to clean up system resources.
        Task { await stop() }
    }

    // Emit a single Void to all registered continuations. Called from serial queue.
    private func emit() {
        for (_, cont) in continuations {
            // Yield a single Void value. Do not finish the stream; allow further events.
            cont.yield(())
        }
    }
}
