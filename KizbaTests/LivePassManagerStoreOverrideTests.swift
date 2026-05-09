//
//  LivePassManagerStoreOverrideTests.swift
//  KizbaTests
//
//  Phase A.5 — verifies that ``LivePassManager`` honours the live
//  password-store override end-to-end:
//
//  - When the provider returns a non-default URL, the env exported by
//    `pass show` contains `PASSWORD_STORE_DIR=<override>` and the
//    scanner is queried against the same override.
//  - When the provider returns the default `~/.password-store` URL,
//    `PASSWORD_STORE_DIR` is still exported (we always pass it through
//    to keep behaviour deterministic) and the scanner uses the
//    default root.
//  - Mutating the override between two operations is reflected on the
//    next call without rebuilding the manager — this is the key
//    behaviour that was broken in MVP 1.
//

import XCTest
@testable import Kizba

final class LivePassManagerStoreOverrideTests: XCTestCase {

    // MARK: - Helpers

    /// Mutable, `Sendable`-friendly holder so a single closure can
    /// surface different store roots over time without forcing the
    /// closure itself to capture mutable state.
    private final class RootHolder: @unchecked Sendable {
        var current: URL
        init(_ initial: URL) { self.current = initial }
    }

    /// Builds a wired stack: a `LivePassManager` whose decryption goes
    /// through a `LivePassCLI` that uses a `FakeShellRunner` we can
    /// inspect. The discovery is stubbed to return a fixed `pass`
    /// path so every `show()` call lands on the runner.
    private func makeManager(
        rootProvider: @escaping @Sendable () -> URL,
        scannerStub: [String] = []
    ) -> (LivePassManager, FakeShellRunner, RecordingScanner) {
        let runner = FakeShellRunner(
            response: .success(
                exitCode: 0,
                stdout: Data("hunter2\nuser: a@b\n".utf8),
                stderr: Data()
            )
        )
        let discovery = FixedBinaryLocator(
            mapping: [.pass: URL(fileURLWithPath: "/opt/homebrew/bin/pass")]
        )
        let cli = LivePassCLI(discovery: discovery, shellRunner: runner)
        let scanner = RecordingScanner(stub: scannerStub)
        let manager = LivePassManager(
            scanner: scanner,
            passCLI: cli,
            storeRootProvider: rootProvider
        )
        return (manager, runner, scanner)
    }

    // MARK: - Tests

    /// Override set → next `pass show` carries
    /// `PASSWORD_STORE_DIR=<override>` in its env, and the scanner is
    /// asked to list against the same override URL.
    func testStoreOverride_propagatesToPasswordStoreDirEnv() async throws {
        let override = URL(fileURLWithPath: "/tmp/kizba-store-override", isDirectory: true)
        let (manager, runner, scanner) = makeManager(
            rootProvider: { override },
            scannerStub: ["personal/email"]
        )

        // List → scanner should see the override root.
        _ = try await manager.listEntries()
        let scannerRoots = await scanner.recordedRoots
        XCTAssertEqual(scannerRoots, [override])

        // Show → env exported to `pass` must include
        // `PASSWORD_STORE_DIR=<override.path>`.
        _ = try await manager.show(PassEntry(path: "personal/email"))
        let invocation = try XCTUnwrap(runner.lastInvocation)
        XCTAssertEqual(
            invocation.environment["PASSWORD_STORE_DIR"],
            override.path,
            "PASSWORD_STORE_DIR must mirror the active store override."
        )
    }

    /// Default root (no override) → `PASSWORD_STORE_DIR` still
    /// resolves to the home `.password-store` path; we never silently
    /// drop the env entirely because that would let the child inherit
    /// `pass`'s built-in default and diverge from the scanner.
    func testNoStoreOverride_passwordStoreDirIsDefaultRoot() async throws {
        let (manager, runner, _) = makeManager(
            rootProvider: { LivePassManager.defaultStoreRoot }
        )

        _ = try await manager.show(PassEntry(path: "personal/email"))

        let invocation = try XCTUnwrap(runner.lastInvocation)
        XCTAssertEqual(
            invocation.environment["PASSWORD_STORE_DIR"],
            LivePassManager.defaultStoreRoot.path,
            "PASSWORD_STORE_DIR must equal the manager's default root when no override is set."
        )
    }

    /// Mutating the override between two calls must be picked up on
    /// the next operation — the provider is consulted afresh each
    /// time, no manager rebuild required.
    func testStoreOverride_isReadLivePerCall() async throws {
        let first = URL(fileURLWithPath: "/tmp/kizba-store-A", isDirectory: true)
        let second = URL(fileURLWithPath: "/tmp/kizba-store-B", isDirectory: true)
        let holder = RootHolder(first)
        let (manager, runner, scanner) = makeManager(
            rootProvider: { holder.current },
            scannerStub: ["x"]
        )

        // First call — observes `first`.
        _ = try await manager.listEntries()
        _ = try await manager.show(PassEntry(path: "x"))
        let invA = try XCTUnwrap(runner.lastInvocation)
        XCTAssertEqual(invA.environment["PASSWORD_STORE_DIR"], first.path)

        // Mutate the override. No manager rebuild.
        holder.current = second

        _ = try await manager.listEntries()
        _ = try await manager.show(PassEntry(path: "x"))
        let invB = try XCTUnwrap(runner.lastInvocation)
        XCTAssertEqual(invB.environment["PASSWORD_STORE_DIR"], second.path)

        let scannerRoots = await scanner.recordedRoots
        XCTAssertEqual(
            scannerRoots,
            [first, second],
            "Scanner must observe the override change on the next listing call."
        )
    }

    /// `storeLocation()` must reflect the live provider too — the
    /// Diagnostics view and any other read path that calls it observe
    /// the current override without an actor hop.
    func testStoreLocation_readsLiveProvider() {
        let holder = RootHolder(URL(fileURLWithPath: "/tmp/A"))
        let (manager, _, _) = makeManager(rootProvider: { holder.current })

        XCTAssertEqual(manager.storeLocation().path, "/tmp/A")
        holder.current = URL(fileURLWithPath: "/tmp/B")
        XCTAssertEqual(manager.storeLocation().path, "/tmp/B")
    }
}

// MARK: - Local test doubles

/// In-memory ``PasswordStoreScanning`` that records every store root
/// it has been queried with (in order).
private actor RecordingScanner: PasswordStoreScanning {

    private let stub: [String]
    private(set) var recordedRoots: [URL] = []

    init(stub: [String]) {
        self.stub = stub
    }

    func listEntries(in storeRoot: URL) async throws -> [String] {
        recordedRoots.append(storeRoot)
        return stub
    }

    func validateStoreRoot(_ storeRoot: URL) async -> Bool { true }
    func invalidate(storeRoot: URL) async {}
}

/// Minimal ``BinaryLocating`` returning a fixed mapping. Identical in
/// shape to the helper used by `LivePassManagerTests`; duplicated here
/// because the original is `private` to its file.
private struct FixedBinaryLocator: BinaryLocating {
    let mapping: [BinaryName: URL]
    func locate(_ binary: BinaryName) async -> URL? { mapping[binary] }
    func reDetect() async {}
}
