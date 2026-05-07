//
//  EntryPathConverterTests.swift
//  KizbaTests
//
//  Unit tests for `EntryPathConverter` (Phase 6.1). The converter is
//  pure, so these tests construct URLs in-memory and never touch disk.
//

import XCTest
@testable import Kizba

final class EntryPathConverterTests: XCTestCase {

    // A deterministic, non-existent store root. The converter is pure
    // and never checks for filesystem presence.
    private let storeRoot = URL(fileURLWithPath: "/tmpStore", isDirectory: true)

    // MARK: - Happy paths

    func testNestedPath() {
        let url = URL(fileURLWithPath: "/tmpStore/personal/work/pass.gpg")
        XCTAssertEqual(
            EntryPathConverter.entryPath(from: url, storeRoot: storeRoot),
            "personal/work/pass"
        )
    }

    func testTopLevel() {
        let url = URL(fileURLWithPath: "/tmpStore/pass.gpg")
        XCTAssertEqual(
            EntryPathConverter.entryPath(from: url, storeRoot: storeRoot),
            "pass"
        )
    }

    func testUnicodeAndSpacesPreserved() {
        let url = URL(fileURLWithPath: "/tmpStore/スペース dir/entry name ☃.gpg")
        XCTAssertEqual(
            EntryPathConverter.entryPath(from: url, storeRoot: storeRoot),
            "スペース dir/entry name ☃"
        )
    }

    func testDotsInBasenamePreserved() {
        // Only the final `.gpg` extension is stripped; earlier dots stay.
        let url = URL(fileURLWithPath: "/tmpStore/foo.bar.baz.gpg")
        XCTAssertEqual(
            EntryPathConverter.entryPath(from: url, storeRoot: storeRoot),
            "foo.bar.baz"
        )
    }

    // MARK: - Rejection paths

    func testNonGpgReturnsNil() {
        let url = URL(fileURLWithPath: "/tmpStore/readme.txt")
        XCTAssertNil(EntryPathConverter.entryPath(from: url, storeRoot: storeRoot))
    }

    func testOutsideRootReturnsNil() {
        let url = URL(fileURLWithPath: "/elsewhere/personal/pass.gpg")
        XCTAssertNil(EntryPathConverter.entryPath(from: url, storeRoot: storeRoot))
    }

    func testStoreRootItselfReturnsNil() {
        // The store root itself is a directory, not an entry.
        XCTAssertNil(EntryPathConverter.entryPath(from: storeRoot, storeRoot: storeRoot))
    }

    func testEmptyBasenameReturnsNil() {
        // A bare `.gpg` filename has an empty entry name and must be rejected.
        let url = URL(fileURLWithPath: "/tmpStore/.gpg")
        XCTAssertNil(EntryPathConverter.entryPath(from: url, storeRoot: storeRoot))
    }
}
