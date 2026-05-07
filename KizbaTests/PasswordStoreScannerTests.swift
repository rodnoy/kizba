//
//  PasswordStoreScannerTests.swift
//  KizbaTests
//
//  Unit tests for `PasswordStoreScanner` (Phase 6.3 / 6.4). Tests use
//  `TempStoreFixture` to build deterministic on-disk layouts under a
//  unique temporary directory and clean up via `defer`.
//

import XCTest
@testable import Kizba

final class PasswordStoreScannerTests: XCTestCase {

    // MARK: - Standard layout

    func testStandardLayout_returnsExpectedSortedEntries() async throws {
        let fixture = TempStoreFixture()
        defer { fixture.cleanup() }
        try fixture.createStandardLayout()

        let scanner = PasswordStoreScanner()
        let entries = try await scanner.listEntries(in: fixture.root)

        // Sort order matches `PasswordStoreScanner`'s
        // `localizedStandardCompare`-based sort. Latin paths precede
        // the Japanese-prefixed entry deterministically.
        XCTAssertEqual(
            entries,
            [
                "archive/old",
                "pass",
                "personal/two",
                "personal/work/one",
                "work/entry",
                "スペース dir/entry name ☃"
            ]
        )

        // Re-running yields the identical sequence.
        await scanner.invalidate(storeRoot: fixture.root)
        let again = try await scanner.listEntries(in: fixture.root)
        XCTAssertEqual(entries, again)
    }

    // MARK: - Empty store

    func testEmptyStore_returnsEmpty() async throws {
        let fixture = TempStoreFixture()
        defer { fixture.cleanup() }
        try fixture.createEmptyStore()

        let scanner = PasswordStoreScanner()
        let entries = try await scanner.listEntries(in: fixture.root)

        XCTAssertEqual(entries, [])
    }

    // MARK: - Missing root

    func testMissingRoot_throws() async throws {
        let fixture = TempStoreFixture()
        defer { fixture.cleanup() }
        let missing = fixture.root.appendingPathComponent("does-not-exist", isDirectory: true)

        let scanner = PasswordStoreScanner()

        do {
            _ = try await scanner.listEntries(in: missing)
            XCTFail("Expected storeNotFound to be thrown")
        } catch let error as PassError {
            switch error {
            case .storeNotFound:
                break
            default:
                XCTFail("Unexpected PassError: \(error)")
            }
        }
    }

    // MARK: - .gpg-id and .git ignored

    func testGpgIdAndGitIgnored() async throws {
        let fixture = TempStoreFixture()
        defer { fixture.cleanup() }
        try fixture.createStandardLayout()

        let scanner = PasswordStoreScanner()
        let entries = try await scanner.listEntries(in: fixture.root)

        XCTAssertFalse(entries.contains(".gpg-id"))
        XCTAssertFalse(entries.contains { $0.hasPrefix(".git/") || $0.contains("ignored") })
        // `readme.txt` is not `.gpg`, must also be excluded.
        XCTAssertFalse(entries.contains { $0.contains("readme") })
    }

    // MARK: - Unicode and spaces

    func testUnicodeAndSpacesPreserved() async throws {
        let fixture = TempStoreFixture()
        defer { fixture.cleanup() }
        try fixture.createStandardLayout()

        let scanner = PasswordStoreScanner()
        let entries = try await scanner.listEntries(in: fixture.root)

        XCTAssertTrue(
            entries.contains("スペース dir/entry name ☃"),
            "Unicode + spaces in entry path must be preserved verbatim"
        )
    }

    // MARK: - Caching / invalidation

    func testCachingAndInvalidate() async throws {
        let fixture = TempStoreFixture()
        defer { fixture.cleanup() }
        try fixture.createEmptyStore()

        let firstURL = fixture.root.appendingPathComponent("first.gpg")
        try Data("fixture".utf8).write(to: firstURL)

        let scanner = PasswordStoreScanner()
        let initial = try await scanner.listEntries(in: fixture.root)
        XCTAssertEqual(initial, ["first"])

        // Add a new file on disk; without invalidation the cached
        // result must not reflect the new file.
        let secondURL = fixture.root.appendingPathComponent("second.gpg")
        try Data("fixture".utf8).write(to: secondURL)
        let cached = try await scanner.listEntries(in: fixture.root)
        XCTAssertEqual(cached, ["first"], "Cache should hide the new file until invalidated")

        await scanner.invalidate(storeRoot: fixture.root)
        let refreshed = try await scanner.listEntries(in: fixture.root)
        XCTAssertEqual(refreshed, ["first", "second"])
    }

    // MARK: - Case-insensitive .gpg extension

    func testCaseInsensitiveGpgExtension() async throws {
        let fixture = TempStoreFixture()
        defer { fixture.cleanup() }
        try fixture.createEmptyStore()

        try Data("fixture".utf8).write(
            to: fixture.root.appendingPathComponent("upper.GPG")
        )
        try Data("fixture".utf8).write(
            to: fixture.root.appendingPathComponent("lower.gpg")
        )

        let scanner = PasswordStoreScanner()
        let entries = try await scanner.listEntries(in: fixture.root)

        XCTAssertEqual(entries.count, 2)
        XCTAssertEqual(entries.sorted(), ["lower", "upper"].sorted())
    }

    // MARK: - validateStoreRoot

    func testValidateStoreRoot() async throws {
        let fixture = TempStoreFixture()
        defer { fixture.cleanup() }
        try fixture.createEmptyStore()

        let scanner = PasswordStoreScanner()
        let validRoot = await scanner.validateStoreRoot(fixture.root)
        XCTAssertTrue(validRoot)

        let missing = fixture.root.appendingPathComponent("nope", isDirectory: true)
        let validMissing = await scanner.validateStoreRoot(missing)
        XCTAssertFalse(validMissing)

        // A regular file is not a valid store root.
        let fileURL = fixture.root.appendingPathComponent("file-not-dir.gpg")
        try Data("fixture".utf8).write(to: fileURL)
        let validFile = await scanner.validateStoreRoot(fileURL)
        XCTAssertFalse(validFile)
    }
}
