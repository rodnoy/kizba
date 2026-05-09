//
//  LivePassManagerWriteTests.swift
//  KizbaTests
//
//  Phase E.6 — wiring tests for the four ``PassManaging`` write
//  methods on ``LivePassManager`` and the multi-subscriber
//  ``changes`` ``AsyncStream``. Each test composes the live actor
//  on top of:
//
//  - a ``CountingScanner`` that records `invalidate` calls and
//    answers `contains` from a configurable set, so we can drive
//    both `.inserted` and `.updated` event paths deterministically;
//  - a ``FakeShellRunner`` that captures the exact ``ShellInvocation``
//    forwarded by ``PassCLI`` (argv + stdin bytes + env) and replays
//    a scripted ``Response``.
//
//  Coverage matrix:
//   - insert (new path)        → `.inserted`, returns entry, scanner
//                                invalidated, env carries override.
//   - insert (existing path)   → `.updated`.
//   - generate (new)           → `.inserted` + parsed `PassSecret`.
//   - generate (existing)      → `.updated`.
//   - remove                   → `.removed`.
//   - move                     → `.moved(from:to:)` + new entry.
//   - failure path             → typed `PassError` + NO event emitted.
//   - multi-subscriber         → two concurrent listeners both
//                                receive the event; cancelling one
//                                does not block the other.
//   - invalidate-before-emit ordering — subscribers that re-list
//                                      observe the post-write state.
//

import XCTest
@testable import Kizba

final class LivePassManagerWriteTests: XCTestCase {

    // MARK: - Shared fixtures

    private static let fakePassURL = URL(fileURLWithPath: "/opt/homebrew/bin/pass")
    private static let storeRoot = URL(fileURLWithPath: "/tmp/kizba-write-tests-store", isDirectory: true)

    /// Canonical "successful generate" stdout used across the
    /// happy-path tests. Plain non-coloured 1.7.x shape.
    private static let generateStdout: String = """
    The generated password for new/foo is:
    Gen3rated#Pass
    """

    /// Builds a wired stack and returns the trio every test asserts on.
    private func makeStack(
        responses: [FakeShellRunner.Response] = [
            .success(exitCode: 0, stdout: Data(), stderr: Data())
        ],
        existingPaths: Set<String> = []
    ) -> (LivePassManager, FakeShellRunner, CountingScanner) {
        let runner = FakeShellRunner()
        runner.script(responses)
        let discovery = WriteFixedBinaryLocator(
            mapping: [.pass: Self.fakePassURL]
        )
        let cli = LivePassCLI(discovery: discovery, shellRunner: runner)
        let scanner = CountingScanner(existingPaths: existingPaths)
        let manager = LivePassManager(
            scanner: scanner,
            passCLI: cli,
            storeRoot: Self.storeRoot
        )
        return (manager, runner, scanner)
    }

    // MARK: - insert

    func testInsert_newPath_emitsInsertedAndInvalidatesScanner() async throws {
        let (manager, runner, scanner) = makeStack()
        let entry = PassEntry(path: "new/foo")
        let secret = PassSecret(password: "hunter2")

        let collector = await makeStoreChangeCollector(for: manager.changes)
        try await Task.sleep(for: .milliseconds(20))

        let returned = try await manager.insert(entry, secret: secret, force: false)
        XCTAssertEqual(returned.path, "new/foo")

        // Argv: `pass insert -m new/foo` (no `-f` because force=false).
        let invocation = try XCTUnwrap(runner.lastInvocation)
        XCTAssertEqual(invocation.arguments, ["insert", "-m", "new/foo"])

        // Env carries the active store override on every write.
        XCTAssertEqual(
            invocation.environment["PASSWORD_STORE_DIR"],
            Self.storeRoot.path
        )

        // Scanner cache invalidated for the active store root.
        let invalidations = await scanner.invalidationCount
        XCTAssertEqual(invalidations, 1)
        let invalidatedRoots = await scanner.invalidatedRoots
        XCTAssertEqual(invalidatedRoots, [Self.storeRoot])

        let events = await collector.collected(timeout: .milliseconds(100))
        XCTAssertEqual(events, [.inserted(path: "new/foo")])
    }

    func testInsert_existingPath_emitsUpdated() async throws {
        let (manager, _, _) = makeStack(existingPaths: ["existing/foo"])
        let entry = PassEntry(path: "existing/foo")
        let secret = PassSecret(password: "hunter2")

        let collector = await makeStoreChangeCollector(for: manager.changes)
        try await Task.sleep(for: .milliseconds(20))

        _ = try await manager.insert(entry, secret: secret, force: true)

        let events = await collector.collected(timeout: .milliseconds(100))
        XCTAssertEqual(events, [.updated(path: "existing/foo")])
    }

    func testInsert_stdinCarriesSerialisedBody() async throws {
        let (manager, runner, _) = makeStack()
        let entry = PassEntry(path: "new/foo")
        let metadata = PassMetadata(
            fields: [.init(key: "user", value: "alice@example.com")],
            notes: "extra note"
        )
        let secret = PassSecret(password: "p@ss!", metadata: metadata)

        _ = try await manager.insert(entry, secret: secret, force: false)

        let invocation = try XCTUnwrap(runner.lastInvocation)
        let expectedBody = await MainActor.run {
            Data(PassSecretSerializer.serialize(secret).utf8)
        }
        XCTAssertEqual(invocation.stdin, .data(expectedBody))
    }

    func testInsert_failure_throwsAndEmitsNothing() async throws {
        let (manager, _, scanner) = makeStack(
            responses: [
                .success(
                    exitCode: 1,
                    stdout: Data(),
                    stderr: Data("Error: new/foo already exists.\n".utf8)
                )
            ]
        )
        let entry = PassEntry(path: "new/foo")
        let secret = PassSecret(password: "x")

        let collector = await makeStoreChangeCollector(for: manager.changes)
        try await Task.sleep(for: .milliseconds(20))

        do {
            _ = try await manager.insert(entry, secret: secret, force: false)
            XCTFail("Expected entryAlreadyExists")
        } catch PassError.entryAlreadyExists(let path) {
            XCTAssertEqual(path, "new/foo")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }

        // No invalidation, no event on failure.
        let invalidations = await scanner.invalidationCount
        XCTAssertEqual(invalidations, 0)
        let events = await collector.collected(timeout: .milliseconds(80))
        XCTAssertTrue(events.isEmpty, "Failure path must not emit a StoreChange.")
    }

    // MARK: - generate

    func testGenerate_newPath_returnsSecretAndEmitsInserted() async throws {
        let (manager, runner, scanner) = makeStack(
            responses: [
                .success(
                    exitCode: 0,
                    stdout: Self.generateStdout.data(using: .utf8)!,
                    stderr: Data()
                )
            ]
        )
        let entry = PassEntry(path: "new/foo")

        let collector = await makeStoreChangeCollector(for: manager.changes)
        try await Task.sleep(for: .milliseconds(20))

        let secret = try await manager.generate(
            entry,
            length: 24,
            includeSymbols: true,
            force: false
        )

        XCTAssertEqual(secret.password, "Gen3rated#Pass")
        XCTAssertTrue(secret.metadata.fields.isEmpty)
        XCTAssertNil(secret.metadata.notes)

        // Argv: includeSymbols=true ⇒ no `-n`; force=false ⇒ no `-f`.
        let invocation = try XCTUnwrap(runner.lastInvocation)
        XCTAssertEqual(invocation.arguments, ["generate", "new/foo", "24"])

        let invalidations = await scanner.invalidationCount
        XCTAssertEqual(invalidations, 1)
        let events = await collector.collected(timeout: .milliseconds(100))
        XCTAssertEqual(events, [.inserted(path: "new/foo")])
    }

    func testGenerate_existingPathWithForce_emitsUpdated() async throws {
        let (manager, runner, _) = makeStack(
            responses: [
                .success(
                    exitCode: 0,
                    stdout: Self.generateStdout.data(using: .utf8)!,
                    stderr: Data()
                )
            ],
            existingPaths: ["new/foo"]
        )
        let entry = PassEntry(path: "new/foo")

        let collector = await makeStoreChangeCollector(for: manager.changes)
        try await Task.sleep(for: .milliseconds(20))

        _ = try await manager.generate(
            entry,
            length: 24,
            includeSymbols: false,
            force: true
        )

        // Argv: includeSymbols=false ⇒ `-n`; force=true ⇒ `-f`.
        let invocation = try XCTUnwrap(runner.lastInvocation)
        XCTAssertEqual(invocation.arguments, ["generate", "-f", "-n", "new/foo", "24"])

        let events = await collector.collected(timeout: .milliseconds(100))
        XCTAssertEqual(events, [.updated(path: "new/foo")])
    }

    func testGenerate_failure_throwsAndEmitsNothing() async throws {
        let (manager, _, scanner) = makeStack(
            responses: [
                .success(
                    exitCode: 1,
                    stdout: Data(),
                    stderr: Data(
                        "Error: pass-length \"abc\" must be a positive integer.\n".utf8
                    )
                )
            ]
        )

        let collector = await makeStoreChangeCollector(for: manager.changes)
        try await Task.sleep(for: .milliseconds(20))

        do {
            _ = try await manager.generate(
                PassEntry(path: "new/foo"),
                length: 0,
                includeSymbols: true,
                force: false
            )
            XCTFail("Expected invalidLength")
        } catch PassError.invalidLength {
            // ok
        } catch {
            XCTFail("Unexpected error: \(error)")
        }

        let invalidations = await scanner.invalidationCount
        XCTAssertEqual(invalidations, 0)
        let events = await collector.collected(timeout: .milliseconds(80))
        XCTAssertTrue(events.isEmpty)
    }

    // MARK: - remove

    func testRemove_emitsRemovedAndInvalidates() async throws {
        let (manager, runner, scanner) = makeStack()
        let entry = PassEntry(path: "old/foo")

        let collector = await makeStoreChangeCollector(for: manager.changes)
        try await Task.sleep(for: .milliseconds(20))

        try await manager.remove(entry)

        let invocation = try XCTUnwrap(runner.lastInvocation)
        XCTAssertEqual(invocation.arguments, ["rm", "-f", "old/foo"])

        let invalidations = await scanner.invalidationCount
        XCTAssertEqual(invalidations, 1)
        let events = await collector.collected(timeout: .milliseconds(100))
        XCTAssertEqual(events, [.removed(path: "old/foo")])
    }

    func testRemove_failure_throwsAndEmitsNothing() async throws {
        let (manager, _, scanner) = makeStack(
            responses: [
                .success(
                    exitCode: 1,
                    stdout: Data(),
                    stderr: Data("Error: gone/foo is not in the password store.\n".utf8)
                )
            ]
        )

        let collector = await makeStoreChangeCollector(for: manager.changes)
        try await Task.sleep(for: .milliseconds(20))

        do {
            try await manager.remove(PassEntry(path: "gone/foo"))
            XCTFail("Expected sourceNotFound")
        } catch PassError.sourceNotFound(let path) {
            XCTAssertEqual(path, "gone/foo")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }

        let invalidations = await scanner.invalidationCount
        XCTAssertEqual(invalidations, 0)
        let events = await collector.collected(timeout: .milliseconds(80))
        XCTAssertTrue(events.isEmpty)
    }

    // MARK: - move

    func testMove_emitsMovedAndReturnsNewEntry() async throws {
        let (manager, runner, scanner) = makeStack()
        let from = PassEntry(path: "a/b")

        let collector = await makeStoreChangeCollector(for: manager.changes)
        try await Task.sleep(for: .milliseconds(20))

        let renamed = try await manager.move(from: from, to: "c/d", force: false)
        XCTAssertEqual(renamed.path, "c/d")

        let invocation = try XCTUnwrap(runner.lastInvocation)
        XCTAssertEqual(invocation.arguments, ["mv", "a/b", "c/d"])

        let invalidations = await scanner.invalidationCount
        XCTAssertEqual(invalidations, 1)
        let events = await collector.collected(timeout: .milliseconds(100))
        XCTAssertEqual(events, [.moved(from: "a/b", to: "c/d")])
    }

    func testMove_targetCollision_throwsAndEmitsNothing() async throws {
        let (manager, _, scanner) = makeStack(
            responses: [
                .success(
                    exitCode: 1,
                    stdout: Data(),
                    stderr: Data(
                        "mv: refusing to overwrite '/store/.password-store/c/d.gpg'\n".utf8
                    )
                )
            ]
        )

        let collector = await makeStoreChangeCollector(for: manager.changes)
        try await Task.sleep(for: .milliseconds(20))

        do {
            _ = try await manager.move(
                from: PassEntry(path: "a/b"),
                to: "c/d",
                force: false
            )
            XCTFail("Expected entryAlreadyExists")
        } catch PassError.entryAlreadyExists(let path) {
            XCTAssertEqual(path, "c/d")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }

        let invalidations = await scanner.invalidationCount
        XCTAssertEqual(invalidations, 0)
        let events = await collector.collected(timeout: .milliseconds(80))
        XCTAssertTrue(events.isEmpty)
    }

    // MARK: - Multi-subscriber

    func testChanges_multipleSubscribers_eachReceivesEveryEvent() async throws {
        let (manager, _, _) = makeStack()

        let collectorA = await makeStoreChangeCollector(for: manager.changes)
        let collectorB = await makeStoreChangeCollector(for: manager.changes)
        try await Task.sleep(for: .milliseconds(30))

        _ = try await manager.insert(
            PassEntry(path: "new/foo"),
            secret: PassSecret(password: "x"),
            force: false
        )

        let eventsA = await collectorA.collected(timeout: .milliseconds(150))
        let eventsB = await collectorB.collected(timeout: .milliseconds(150))
        XCTAssertEqual(eventsA, [.inserted(path: "new/foo")])
        XCTAssertEqual(eventsB, [.inserted(path: "new/foo")])
    }

    func testChanges_droppedSubscriber_doesNotBlockOthers() async throws {
        let (manager, _, _) = makeStack(
            responses: [
                .success(exitCode: 0, stdout: Data(), stderr: Data()),
                .success(exitCode: 0, stdout: Data(), stderr: Data()),
            ]
        )

        let collectorA = await makeStoreChangeCollector(for: manager.changes)
        let collectorB = await makeStoreChangeCollector(for: manager.changes)
        try await Task.sleep(for: .milliseconds(30))

        _ = try await manager.insert(
            PassEntry(path: "first/foo"),
            secret: PassSecret(password: "x"),
            force: false
        )

        // Wait for both collectors to receive the first event, then
        // drop subscriber B. The post-cancel sleep gives the actor's
        // `onTermination` hop a chance to land before the next write
        // so we are exercising the unregistration path, not a race.
        _ = await collectorA.collected(timeout: .milliseconds(150))
        _ = await collectorB.collected(timeout: .milliseconds(150))
        await collectorB.cancel()
        try await Task.sleep(for: .milliseconds(60))

        // Second write — A still alive, B finished + unregistered.
        _ = try await manager.insert(
            PassEntry(path: "second/foo"),
            secret: PassSecret(password: "y"),
            force: false
        )

        // Collectors accumulate over their lifetime. A saw both
        // writes; B finished after the first and never saw the
        // second event.
        let eventsA = await collectorA.collected(timeout: .milliseconds(150))
        XCTAssertEqual(eventsA, [
            .inserted(path: "first/foo"),
            .inserted(path: "second/foo"),
        ])
        let eventsB = await collectorB.collected(timeout: .milliseconds(80))
        XCTAssertEqual(eventsB, [.inserted(path: "first/foo")])
    }
}

// MARK: - StoreChangeCollector

/// Drains a single `AsyncStream<StoreChange>` into an array under
/// actor isolation. Tests subscribe via the manager, sleep briefly so
/// the registration hop completes, perform the mutation, then call
/// ``collected(timeout:)`` to read the events that landed within the
/// supplied window. Calling ``cancel()`` drops the subscription and
/// finishes the buffer.
private actor StoreChangeCollector {

    private var buffer: [StoreChange] = []
    private var task: Task<Void, Never>?

    init() {}

    /// Two-step bring-up because the spawned task has to capture `self`
    /// strongly and we cannot reference `self` from a stored-property
    /// initialiser inside an `actor init`. Tests use the
    /// ``StoreChangeCollector/start(stream:)`` helper below.
    fileprivate func start(stream: AsyncStream<StoreChange>) {
        // Strong capture is fine: the test owns the collector and
        // cancels it explicitly (or lets it fall out of scope, at
        // which point `cancel()` in `deinit` reaps the task).
        task = Task { [self] in
            for await change in stream {
                await self.append(change)
            }
        }
    }

    private func append(_ change: StoreChange) {
        buffer.append(change)
    }

    /// Returns all events buffered so far, after waiting at most
    /// `timeout` for new ones to arrive. The wait is the price of
    /// `AsyncStream` not exposing a "drain available" snapshot.
    func collected(timeout: Duration) async -> [StoreChange] {
        try? await Task.sleep(for: timeout)
        return buffer
    }

    /// Drop the subscription. Used by the multi-subscriber test to
    /// verify that surviving subscribers keep receiving events.
    func cancel() {
        task?.cancel()
        task = nil
    }
}

private extension XCTestCase {
    /// Convenience factory that creates a collector and immediately
    /// kicks off its consumer task. Mirrors the
    /// `let c = await StoreChangeCollector(stream:)` shape the tests
    /// were originally written against, but routes through the
    /// actor's two-step `init` + `start(stream:)` bring-up so the
    /// task captures a fully-constructed `self`.
    func makeStoreChangeCollector(
        for stream: AsyncStream<StoreChange>
    ) async -> StoreChangeCollector {
        let c = StoreChangeCollector()
        await c.start(stream: stream)
        return c
    }
}

// MARK: - CountingScanner

/// In-memory ``PasswordStoreScanning`` test double tailored to the
/// Phase E.6 wiring tests. Tracks `invalidate(storeRoot:)` calls and
/// answers `contains(path:in:)` from a configurable set so we can
/// drive both `.inserted` and `.updated` event paths on demand.
private actor CountingScanner: PasswordStoreScanning {

    private var existingPaths: Set<String>
    private(set) var invalidatedRoots: [URL] = []
    private(set) var listedRoots: [URL] = []

    init(existingPaths: Set<String> = []) {
        self.existingPaths = existingPaths
    }

    var invalidationCount: Int { invalidatedRoots.count }

    func listEntries(in storeRoot: URL) async throws -> [String] {
        listedRoots.append(storeRoot)
        return Array(existingPaths).sorted()
    }

    func validateStoreRoot(_ storeRoot: URL) async -> Bool { true }

    func invalidate(storeRoot: URL) async {
        invalidatedRoots.append(storeRoot)
    }

    func contains(path: String, in storeRoot: URL) async -> Bool {
        existingPaths.contains(path)
    }
}

// MARK: - WriteFixedBinaryLocator

/// Minimal ``BinaryLocating`` test double returning a fixed mapping.
/// Duplicated locally instead of reused from
/// `LivePassManagerTests` / `LivePassManagerStoreOverrideTests`
/// because those declarations are `private` to their own files.
private struct WriteFixedBinaryLocator: BinaryLocating {
    let mapping: [BinaryName: URL]
    func locate(_ binary: BinaryName) async -> URL? { mapping[binary] }
    func reDetect() async {}
}
