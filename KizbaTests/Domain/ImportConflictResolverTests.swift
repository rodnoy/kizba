//
//  ImportConflictResolverTests.swift
//  KizbaTests
//
//  Pure tests for ``ImportConflictResolver``: resolves incoming
//  ``ExportRecord``s against a snapshot of existing paths and the
//  user-selected strategy.
//

import XCTest
@testable import Kizba

final class ImportConflictResolverTests: XCTestCase {

    // MARK: - Helpers

    private func record(_ path: String, password: String = "p") -> ExportRecord {
        ExportRecord(path: path, password: password)
    }

    // MARK: - No conflict

    func testResolve_noConflict_returnsCreate() {
        let resolver = ImportConflictResolver(
            strategy: .skip,
            existingPaths: ["existing/one"]
        )
        let action = resolver.resolve(record("fresh/path"))
        XCTAssertEqual(action, .create(record("fresh/path")))
    }

    // MARK: - Strategies

    func testResolve_conflictSkip_returnsNil() {
        let resolver = ImportConflictResolver(
            strategy: .skip,
            existingPaths: ["dup"]
        )
        XCTAssertNil(resolver.resolve(record("dup")))
    }

    func testResolve_conflictOverwrite_returnsOverwrite() {
        let resolver = ImportConflictResolver(
            strategy: .overwrite,
            existingPaths: ["dup"]
        )
        let action = resolver.resolve(record("dup", password: "new"))
        XCTAssertEqual(action, .overwrite(record("dup", password: "new")))
    }

    func testResolve_conflictRename_returnsCreateWithSuffix2() {
        let resolver = ImportConflictResolver(
            strategy: .rename,
            existingPaths: ["dup"]
        )
        guard case let .create(renamed)? = resolver.resolve(record("dup")) else {
            return XCTFail("Expected .create action")
        }
        XCTAssertEqual(renamed.path, "dup-2")
    }

    func testResolve_conflictRename_skipsExistingSuffix2() {
        let resolver = ImportConflictResolver(
            strategy: .rename,
            existingPaths: ["dup", "dup-2", "dup-3"]
        )
        guard case let .create(renamed)? = resolver.resolve(record("dup")) else {
            return XCTFail("Expected .create action")
        }
        XCTAssertEqual(renamed.path, "dup-4")
    }

    func testResolve_conflictRename_preservesAllFields() {
        let resolver = ImportConflictResolver(
            strategy: .rename,
            existingPaths: ["dup"]
        )
        let incoming = ExportRecord(
            path: "dup",
            password: "secret",
            username: "alice",
            url: "https://example.com",
            notes: "n",
            totp: "otpauth://totp/x",
            extraFields: ["k": "v"]
        )
        guard case let .create(renamed)? = resolver.resolve(incoming) else {
            return XCTFail("Expected .create action")
        }
        XCTAssertEqual(renamed.path, "dup-2")
        XCTAssertEqual(renamed.password, "secret")
        XCTAssertEqual(renamed.username, "alice")
        XCTAssertEqual(renamed.url, "https://example.com")
        XCTAssertEqual(renamed.notes, "n")
        XCTAssertEqual(renamed.totp, "otpauth://totp/x")
        XCTAssertEqual(renamed.extraFields, ["k": "v"])
    }
}
