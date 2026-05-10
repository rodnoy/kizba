import XCTest
@testable import Kizba

// MARK: - Observing protocol

@MainActor
internal protocol AsyncObserving {
    func observeChanges() async
}

// Conform known test models to the protocol so the generic helper
// can be used without changing production sources.
@MainActor
extension EntryListModel: AsyncObserving {}

@MainActor
extension EntryDetailModel: AsyncObserving {}

// MARK: - startObservation

/// Starts `model.observeChanges()` on a detached task and yields a
/// few times so multi-subscriber AsyncStream continuations have a
/// chance to register. Returns the spawned Task so the caller can
/// cancel or await its completion.
@MainActor
internal func startObservation<M: AsyncObserving>(model: M) async -> Task<Void, Never> {
    let task = Task { await model.observeChanges() }
    for _ in 0..<5 { await Task.yield() }
    try? await Task.sleep(nanoseconds: 20_000_000) // 20ms safety margin
    return task
}

// MARK: - waitUntil

/// Polls `predicate` on the MainActor until it returns `true` or
/// `timeout` seconds elapse. On timeout records an `XCTFail` so the
/// test suite does not hang forever.
@MainActor
internal func waitUntil(
    _ predicate: @MainActor () -> Bool,
    timeout: TimeInterval = 1.0,
    message: String = "predicate did not become true in time",
    file: StaticString = #filePath,
    line: UInt = #line
) async {
    let deadline = Date().addingTimeInterval(timeout)
    while Date() < deadline {
        if predicate() { return }
        try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
    }
    XCTFail(message, file: file, line: line)
}

@MainActor
internal func waitUntil(
    _ predicate: @MainActor () async -> Bool,
    timeout: TimeInterval = 1.0,
    message: String = "predicate did not become true in time",
    file: StaticString = #filePath,
    line: UInt = #line
) async {
    let deadline = Date().addingTimeInterval(timeout)
    while Date() < deadline {
        if await predicate() { return }
        try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
    }
    XCTFail(message, file: file, line: line)
}

/// Alternate calling convention used by some tests: `waitUntil(timeout: 1.0) { ... }`
@MainActor
internal func waitUntil(
    timeout seconds: TimeInterval,
    file: StaticString = #filePath,
    line: UInt = #line,
    _ predicate: @MainActor () -> Bool
) async {
    let deadline = Date().addingTimeInterval(seconds)
    while Date() < deadline {
        if predicate() { return }
        try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
    }
    XCTFail("predicate did not become true in time", file: file, line: line)
}

/// Wait until an EntryFormModel has completed its initial loading and is
/// in `.editing` state. Some tests need a small helper with this
/// specific semantics beyond the generic `waitUntil`.
@MainActor
internal func waitUntilEditing(
    model: EntryFormModel,
    timeout: TimeInterval = 1.0,
    file: StaticString = #filePath,
    line: UInt = #line
) async {
    await waitUntil({ model.state == .editing }, timeout: timeout, file: file, line: line)
}
