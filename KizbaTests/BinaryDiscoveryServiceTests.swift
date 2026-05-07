//
//  BinaryDiscoveryServiceTests.swift
//  KizbaTests
//
//  Deterministic unit tests for `BinaryDiscoveryService` (Phase 5.1).
//  A `FakeFileExistenceChecker` reports a configurable set of
//  absolute paths as "executable", letting us exercise the override,
//  well-known and sanitised-PATH branches without touching disk.
//

import XCTest
@testable import Kizba

// MARK: - Test double

/// In-memory `FileExistenceChecking` whose set of "present"
/// executables is mutable from the test thread. Backed by an
/// `NSLock` so it remains `Sendable` across the actor boundary.
final class FakeFileExistenceChecker: FileExistenceChecking, @unchecked Sendable {

    private let lock = NSLock()
    private var executable: Set<String>

    init(executable: Set<String> = []) {
        self.executable = executable
    }

    nonisolated func isExecutableFile(atPath path: String) -> Bool {
        lock.lock(); defer { lock.unlock() }
        return executable.contains(path)
    }

    nonisolated func setExecutable(_ paths: Set<String>) {
        lock.lock(); defer { lock.unlock() }
        executable = paths
    }

    nonisolated func add(_ path: String) {
        lock.lock(); defer { lock.unlock() }
        executable.insert(path)
    }

    nonisolated func remove(_ path: String) {
        lock.lock(); defer { lock.unlock() }
        executable.remove(path)
    }
}

// MARK: - Tests

final class BinaryDiscoveryServiceTests: XCTestCase {

    // (a) Explicit override beats every system location.
    func testOverrideWins() async {
        let overrideURL = URL(fileURLWithPath: "/opt/kizba/bin/pass")
        let checker = FakeFileExistenceChecker(executable: [
            overrideURL.path,
            "/opt/homebrew/bin/pass",
            "/usr/local/bin/pass",
            "/usr/bin/pass",
        ])

        let service = BinaryDiscoveryService(
            overridePaths: [.pass: overrideURL],
            pathOverride: "",
            environmentReader: { [:] },
            fileChecker: checker
        )

        let resolved = await service.locate(.pass)
        XCTAssertEqual(resolved, overrideURL)
    }

    // (b) Apple-silicon Homebrew is preferred over `/usr/bin`.
    func testHomebrewPreferredOverUsrLocal() async {
        let checker = FakeFileExistenceChecker(executable: [
            "/usr/bin/pass",
            "/opt/homebrew/bin/pass",
        ])

        let service = BinaryDiscoveryService(
            pathOverride: "",
            environmentReader: { [:] },
            fileChecker: checker
        )

        let resolved = await service.locate(.pass)
        XCTAssertEqual(resolved?.path, "/opt/homebrew/bin/pass")
    }

    // (c) PATH fallback honours order; relative entries and `..` are
    // dropped during sanitisation.
    func testPathFallbackUsesSanitizedPathOrder() async {
        let checker = FakeFileExistenceChecker(executable: [
            "/some/dir/pass",
        ])

        // Mix in a relative entry, a `..` traversal entry, an empty
        // entry and a duplicate of `/some/dir`. After sanitisation
        // only `/some/dir` and `/usr/bin` should remain (in order).
        let path = "relative/bin:/etc/../bin:/some/dir::/some/dir:/usr/bin"

        let service = BinaryDiscoveryService(
            pathOverride: path,
            environmentReader: { [:] },
            fileChecker: checker
        )

        // Sanity-check sanitisation in isolation.
        let dirs = await service.sanitisedPathDirectories()
        XCTAssertEqual(dirs, ["/some/dir", "/usr/bin"])

        let resolved = await service.locate(.pass)
        XCTAssertEqual(resolved?.path, "/some/dir/pass")
    }

    // (d) First lookup caches; after `reDetect()` the cache is
    // invalidated and a second lookup observes the new world.
    func testCachingAndReDetect() async {
        let checker = FakeFileExistenceChecker(executable: [
            "/opt/homebrew/bin/pass",
        ])

        let service = BinaryDiscoveryService(
            pathOverride: "",
            environmentReader: { [:] },
            fileChecker: checker
        )

        let first = await service.locate(.pass)
        XCTAssertEqual(first?.path, "/opt/homebrew/bin/pass")

        // Mutate the world: the previously found binary is gone, a
        // new one appears under `/usr/local/bin`. Without cache
        // invalidation `locate` should still return the stale value.
        checker.setExecutable(["/usr/local/bin/pass"])

        let stale = await service.locate(.pass)
        XCTAssertEqual(
            stale?.path, "/opt/homebrew/bin/pass",
            "cache must shield repeated lookups from disk"
        )

        await service.reDetect()

        let fresh = await service.locate(.pass)
        XCTAssertEqual(fresh?.path, "/usr/local/bin/pass")
    }

    // (e) Names whose only matches live in non-executable locations
    // are reported as missing.
    func testNoFalsePositives() async {
        // The checker reports nothing as executable — so every
        // candidate path probe returns false.
        let checker = FakeFileExistenceChecker(executable: [])

        let service = BinaryDiscoveryService(
            pathOverride: "/opt/homebrew/bin:/usr/local/bin:/usr/bin",
            environmentReader: { [:] },
            fileChecker: checker
        )

        let resolved = await service.locate(.pass)
        XCTAssertNil(resolved)
    }

    // (f) An override that points at a non-existent file does NOT
    // silently fall back — the user's explicit choice is honoured by
    // surfacing a miss, so the caller can show a Settings nudge.
    func testOverrideMisconfigurationDoesNotFallBack() async {
        let checker = FakeFileExistenceChecker(executable: [
            "/opt/homebrew/bin/pass",
        ])

        let service = BinaryDiscoveryService(
            overridePaths: [.pass: URL(fileURLWithPath: "/nope/pass")],
            pathOverride: "",
            environmentReader: { [:] },
            fileChecker: checker
        )

        let resolved = await service.locate(.pass)
        XCTAssertNil(resolved)
    }
}
