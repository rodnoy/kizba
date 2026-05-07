//
//  LivePassManagerTests.swift
//  KizbaTests
//
//  Phase 6.5 — wiring tests for ``LivePassManager``. Verifies that:
//  - ``listEntries()`` delegates to the injected
//    ``PasswordStoreScanning`` and maps entry path strings to
//    ``PassEntry`` values preserving order.
//  - ``show(_:)`` delegates to ``LivePassCLI`` (and therefore through
//    ``PassCLI`` + the injected shell runner) with the entry path
//    forwarded as the second `argv` element of `pass show <entry>`.
//  - ``storeLocation()`` returns whatever was injected, including a
//    non-default override.
//
//  All tests are deterministic and run without spawning processes:
//  the scanner and shell runner are both substituted with in-memory
//  fakes.
//

import XCTest
@testable import Kizba

final class LivePassManagerTests: XCTestCase {

    // MARK: - listEntries

    func testListEntries_delegatesToScannerAndMapsToPassEntries() async throws {
        let storeRoot = URL(fileURLWithPath: "/tmp/kizba-fake-store", isDirectory: true)
        let expected = [
            "archive/old",
            "personal/email",
            "work/aws/root",
        ]
        let scanner = FakeScanner(stub: expected)

        let manager = LivePassManager(
            scanner: scanner,
            passCLI: makeUnusedPassCLI(),
            storeRoot: storeRoot
        )

        let entries = try await manager.listEntries()

        XCTAssertEqual(entries.map(\.path), expected)
        XCTAssertEqual(entries.map(\.id), expected)
        // Scanner must be consulted exactly once with the configured
        // store root.
        let calls = await scanner.recordedRoots
        XCTAssertEqual(calls, [storeRoot])
    }

    func testListEntries_emptyStoreReturnsEmpty() async throws {
        let scanner = FakeScanner(stub: [])
        let manager = LivePassManager(
            scanner: scanner,
            passCLI: makeUnusedPassCLI(),
            storeRoot: URL(fileURLWithPath: "/tmp/empty")
        )

        let entries = try await manager.listEntries()
        XCTAssertTrue(entries.isEmpty)
    }

    // MARK: - show

    func testShow_delegatesToPassCLIWithEntryPath() async throws {
        let body = Data("hunter2\nurl: https://x.test\n\nbeware of the leopard\n".utf8)
        let fakeShell = FakeShellRunner(
            response: .success(exitCode: 0, stdout: body, stderr: Data())
        )
        let discovery = StubBinaryLocator(
            mapping: [.pass: URL(fileURLWithPath: "/opt/homebrew/bin/pass")]
        )
        let cli = LivePassCLI(discovery: discovery, shellRunner: fakeShell)

        let manager = LivePassManager(
            scanner: FakeScanner(stub: []),
            passCLI: cli,
            storeRoot: URL(fileURLWithPath: "/tmp/x")
        )

        let entry = PassEntry(path: "personal/email/gmail")
        let secret = try await manager.show(entry)

        // The CLI should have been invoked exactly once with
        // `pass show personal/email/gmail`.
        let invocation = try XCTUnwrap(fakeShell.lastInvocation)
        XCTAssertEqual(invocation.executable.path, "/opt/homebrew/bin/pass")
        XCTAssertEqual(invocation.arguments, ["show", "personal/email/gmail"])

        // Parsed payload should round-trip into PassSecret/PassMetadata.
        XCTAssertEqual(secret.password, "hunter2")
        XCTAssertEqual(secret.metadata.firstValue(for: "url"), "https://x.test")
        XCTAssertEqual(secret.metadata.notes, "\nbeware of the leopard\n")
    }

    // MARK: - storeLocation

    func testStoreLocation_returnsInjectedRoot() {
        let custom = URL(fileURLWithPath: "/tmp/kizba-custom-store", isDirectory: true)
        let manager = LivePassManager(
            scanner: FakeScanner(stub: []),
            passCLI: makeUnusedPassCLI(),
            storeRoot: custom
        )
        XCTAssertEqual(manager.storeLocation(), custom)
    }

    func testStoreLocation_defaultRootMatchesHomePasswordStore() {
        let expected = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".password-store", isDirectory: true)
        XCTAssertEqual(LivePassManager.defaultStoreRoot, expected)
    }

    // MARK: - Helpers

    /// Builds a `LivePassCLI` whose dependencies will never be invoked
    /// (suitable for tests that exercise listing-only / store-location
    /// paths). Discovery returns `nil` so any accidental decryption
    /// call would surface as ``PassError/binaryNotFound``.
    private func makeUnusedPassCLI() -> LivePassCLI {
        let shell = FakeShellRunner(
            response: .success(exitCode: 0, stdout: Data(), stderr: Data())
        )
        let discovery = StubBinaryLocator(mapping: [:])
        return LivePassCLI(discovery: discovery, shellRunner: shell)
    }
}

// MARK: - FakeScanner

/// In-memory ``PasswordStoreScanning`` that returns a fixed list and
/// records the store roots it was queried with.
private actor FakeScanner: PasswordStoreScanning {

    private let stub: [String]
    private(set) var recordedRoots: [URL] = []

    init(stub: [String]) {
        self.stub = stub
    }

    func listEntries(in storeRoot: URL) async throws -> [String] {
        recordedRoots.append(storeRoot)
        return stub
    }

    func validateStoreRoot(_ storeRoot: URL) async -> Bool {
        true
    }

    func invalidate(storeRoot: URL) async {
        // No-op — cache is not exercised by these tests.
    }
}

// MARK: - StubBinaryLocator

/// Minimal ``BinaryLocating`` test double: returns a pre-programmed
/// URL per ``BinaryName`` (or `nil` for unmapped names).
private struct StubBinaryLocator: BinaryLocating {

    let mapping: [BinaryName: URL]

    func locate(_ binary: BinaryName) async -> URL? {
        mapping[binary]
    }

    func reDetect() async {}
}
