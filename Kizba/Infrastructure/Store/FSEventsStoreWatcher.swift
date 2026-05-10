// FSEventsStoreWatcher.swift
// Kizba

import Foundation
import CoreServices

final class FSEventsStoreWatcher: StoreWatching, @unchecked Sendable {
    private let queue = DispatchQueue(label: "kizba.fsevents")
    private let debounceInterval: TimeInterval = 0.350

    private struct InnerState {
        var stream: FSEventStreamRef?
        var continuations: [UUID: AsyncStream<Void>.Continuation]
        var debounceTimer: DispatchSourceTimer?
        var isStarted: Bool
    }

    // Use an unsafe pointer for mutable storage to avoid main-actor isolation enforcement.
    nonisolated private let statePtr: UnsafeMutablePointer<InnerState>

    init() {
        statePtr = UnsafeMutablePointer<InnerState>.allocate(capacity: 1)
        statePtr.initialize(to: InnerState(stream: nil, continuations: [:], debounceTimer: nil, isStarted: false))
    }

    nonisolated var events: AsyncStream<Void> {
        AsyncStream { [weak self] continuation in
            guard let self = self else {
                continuation.finish()
                return
            }

            let id = UUID()
            // Register continuation on the serial queue to keep synchronization simple.
            self.queue.async {
                self.statePtr.pointee.continuations[id] = continuation
            }

            continuation.onTermination = { @Sendable _ in
                // Unregister on the serial queue.
                self.queue.async {
                    self.statePtr.pointee.continuations.removeValue(forKey: id)
                }
            }
        }
    }

    nonisolated func start(at storeRoot: URL) async {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            queue.async { [weak self] in
                guard let self = self else {
                    continuation.resume()
                    return
                }

                if self.statePtr.pointee.isStarted {
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
                        if let t = watcher.statePtr.pointee.debounceTimer {
                            t.cancel()
                            watcher.statePtr.pointee.debounceTimer = nil
                        }

                        let timer = DispatchSource.makeTimerSource(queue: watcher.queue)
                        timer.schedule(deadline: .now() + watcher.debounceInterval)
                        timer.setEventHandler { [weak watcher] in
                            guard let watcher = watcher else { return }
                            watcher.statePtr.pointee.debounceTimer = nil
                            watcher.emit()
                        }
                        watcher.statePtr.pointee.debounceTimer = timer
                        timer.resume()
                    }
                }, &context, paths, FSEventStreamEventId(kFSEventStreamEventIdSinceNow), 0, flags) else {
                    // Failed to create stream
                    continuation.resume()
                    return
                }

                self.statePtr.pointee.stream = stream
                // Schedule on our dispatch queue and start
                FSEventStreamSetDispatchQueue(stream, self.queue)
                FSEventStreamStart(stream)
                self.statePtr.pointee.isStarted = true

                continuation.resume()
            }
        }
    }

    nonisolated func stop() async {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            queue.async { [weak self] in
                guard let self = self else {
                    continuation.resume()
                    return
                }

                if let timer = self.statePtr.pointee.debounceTimer {
                    timer.cancel()
                    self.statePtr.pointee.debounceTimer = nil
                }

                if let stream = self.statePtr.pointee.stream {
                    FSEventStreamStop(stream)
                    FSEventStreamInvalidate(stream)
                    FSEventStreamRelease(stream)
                    self.statePtr.pointee.stream = nil
                }

                // Finish all continuations
                for (_, cont) in self.statePtr.pointee.continuations {
                    cont.finish()
                }
                self.statePtr.pointee.continuations.removeAll()
                self.statePtr.pointee.isStarted = false

                continuation.resume()
            }
        }
    }

    deinit {
        // Schedule cleanup on our serial queue without awaiting to avoid async deinit capture.
        queue.async { [weak self] in
            guard let self = self else { return }

            if let timer = self.statePtr.pointee.debounceTimer {
                timer.cancel()
                self.statePtr.pointee.debounceTimer = nil
            }

            if let stream = self.statePtr.pointee.stream {
                FSEventStreamStop(stream)
                FSEventStreamInvalidate(stream)
                FSEventStreamRelease(stream)
                self.statePtr.pointee.stream = nil
            }

            for (_, cont) in self.statePtr.pointee.continuations {
                cont.finish()
            }
            self.statePtr.pointee.continuations.removeAll()
        }
    }

    // Emit a single Void to all registered continuations. Called from serial queue.
    nonisolated(unsafe) private func emit() {
        for (_, cont) in statePtr.pointee.continuations {
            // Yield a single Void value. Do not finish the stream; allow further events.
            cont.yield(())
        }
    }

    // Ensure we free the allocated pointer if the instance is ever deallocated.
    private func freeState() {
        statePtr.deinitialize(count: 1)
        statePtr.deallocate()
    }
}
