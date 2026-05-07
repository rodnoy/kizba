//
//  PasswordStoreScannerTests.swift
//  KizbaTests
//
//  Unit tests for `PasswordStoreScanner` (Phase 6.3). These tests
//  build small password-store layouts in a per-test temporary
//  directory under `FileManager.default.temporaryDirectory`, run the
//  scanner, and clean up in `tearDownWithError`.
//
//  The fixture helper inlined here is a pragmatic minimum that will
//  be lifted into `Support/TempStoreFixture` in Phase 6.4 once the
//  scanner's wiring stabilises.
//

import XCTest
@testable import Kizba

final class PasswordStoreScannerTests: XCTestCase {

    private var tempRoot: URL!

    override func setUpWithError() throws {
        try super.setUpWithError()
        tempRoot = FileManager.default.temporaryDirectory
            .appendingPathComponent("kizba-store-tests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(
            at: tempRoot,
            withIntermediateDirectories: true
        )
    }

    override func tearDownWithError() throws {
        if let tempRoot, FileManager.default.fileExists(atPath: tempRoot.path) {
            try FileManager.default.removeItem(at: tempRoot)
        }
        tempRoot = nil
        try super.tearDownWithError()
    }

    // MARK: - Fixture helpers

    private func makeFile(_ relative: String, contents: String = "stub") throws {
        let url = tempRoot.appendingPathComponent(relative)
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try Data(contents.utf8).write(to: url)
    }

    // MARK: - Tests

    func testNestedAndTopLevelEntries() async throws {
        try makeFile("personal/work/one.gpg")
        try makeFile("personal/two.gpg")
        try makeFile("pass.gpg")

        let scanner = PasswordStoreScanner()
        let entries = try await scanner.listEntries(in: tempRoot)

        XCTAssertEqual(entries, ["pass", "personal/two", "personal/work/one"])
        // Deterministic sort: re-running yields the identical sequence.
        await scanner.invalidate(storeRoot: tempRoot)
        let again = try await scanner.listEntries(in: tempRoot)
        XCTAssertEqual(entries, again)
    }

    func testIgnoreGitAndGpgId() async throws {
        try makeFile(".git/ignored.gpg")
        try makeFile(".git/objects/abc/def.gpg")
        try makeFile(".gpg-id", contents: "user@example.com")
        try makeFile("real.gpg")

        let scanner = PasswordStoreScanner()
        let entries = try await scanner.listEntries(in: tempRoot)

        XCTAssertEqual(entries, ["real"])
    }

    func testNonGpgIgnored() async throws {
        try makeFile("readme.txt")
        try makeFile("note")
        try makeFile("docs/info.md")
        try makeFile("real.gpg")

        let scanner = PasswordStoreScanner()
        let entries = try await scanner.listEntries(in: tempRoot)

        XCTAssertEqual(entries, ["real"])
    }

    func testEmptyStoreReturnsEmpty() async throws {
        let scanner = PasswordStoreScanner()
        let entries = try await scanner.listEntries(in: tempRoot)
        XCTAssertEqual(entries, [])
    }

    func testMissingRootThrowsStoreNotFound() async throws {
        let missing = tempRoot.appendingPathComponent("does-not-exist", isDirectory: true)
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

    func testUnicodeAndSpacesPreserved() async throws {
        try makeFile("スペース dir/entry name ☃.gpg")
        try makeFile("with space.gpg")

        let scanner = PasswordStoreScanner()
        let entries = try await scanner.listEntries(in: tempRoot)

        XCTAssertEqual(entries, ["with space", "スペース dir/entry name ☃"])
    }

    func testCaseInsensitiveGpgExtension() async throws {
        try makeFile("upper.GPG")
        try makeFile("lower.gpg")

        let scanner = PasswordStoreScanner()
        let entries = try await scanner.listEntries(in: tempRoot)

        // Both files qualify; deterministic sort preserves expected order.
        XCTAssertEqual(entries.sorted(), ["lower", "upper"].sorted())
        XCTAssertEqual(entries.count, 2)
    }

    func testCachingAndInvalidate() async throws {
        try makeFile("first.gpg")

        let scanner = PasswordStoreScanner()
        let initial = try await scanner.listEntries(in: tempRoot)
        XCTAssertEqual(initial, ["first"])

        // Add a new file on disk; without invalidation the cached
        // result must not reflect the new file.
        try makeFile("second.gpg")
        let cached = try await scanner.listEntries(in: tempRoot)
        XCTAssertEqual(cached, ["first"], "Cache should hide the new file until invalidated")

        // After invalidation, the next call re-walks the filesystem.
        await scanner.invalidate(storeRoot: tempRoot)
        let refreshed = try await scanner.listEntries(in: tempRoot)
        XCTAssertEqual(refreshed, ["first", "second"])
    }

    func testValidateStoreRoot() async throws {
        let scanner = PasswordStoreScanner()
        let validRoot = await scanner.validateStoreRoot(tempRoot)
        XCTAssertTrue(validRoot)

        let missing = tempRoot.appendingPathComponent("nope", isDirectory: true)
        let validMissing = await scanner.validateStoreRoot(missing)
        XCTAssertFalse(validMissing)

        // A regular file is not a valid store root.
        try makeFile("file-not-dir.gpg")
        let asFile = tempRoot.appendingPathComponent("file-not-dir.gpg")
        let validFile = await scanner.validateStoreRoot(asFile)
        XCTAssertFalse(validFile)
    }
}
