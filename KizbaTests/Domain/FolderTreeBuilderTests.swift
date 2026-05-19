//
//  FolderTreeBuilderTests.swift
//  KizbaTests
//
//  Pure tests for ``FolderTreeBuilder``: builds a hierarchical
//  ``FolderNode`` tree from a flat list of ``PassEntry`` paths.
//

import XCTest
@testable import Kizba

final class FolderTreeBuilderTests: XCTestCase {

    func testBuild_empty_returnsEmptyArray() {
        XCTAssertTrue(FolderTreeBuilder.build(from: []).isEmpty)
    }

    func testBuild_singleTopLevelEntry_producesNoFolder() {
        // A path without `/` is a top-level entry, not a folder.
        let entries = [PassEntry(path: "rootnote")]
        XCTAssertTrue(FolderTreeBuilder.build(from: entries).isEmpty)
    }

    func testBuild_singleNestedEntry_producesOneLeafFolder() {
        let entries = [PassEntry(path: "system/note")]
        let tree = FolderTreeBuilder.build(from: entries)
        XCTAssertEqual(tree.count, 1)
        XCTAssertEqual(tree[0].fullPath, "system")
        XCTAssertEqual(tree[0].name, "system")
        XCTAssertTrue(tree[0].isLeaf)
    }

    func testBuild_deepNesting_materialisesEveryIntermediate() {
        // "a/b/c/leaf" → folder nodes a, a/b, a/b/c (leaf is an
        // entry, not a folder).
        let entries = [PassEntry(path: "a/b/c/leaf")]
        let tree = FolderTreeBuilder.build(from: entries)
        XCTAssertEqual(tree.count, 1)
        XCTAssertEqual(tree[0].fullPath, "a")
        XCTAssertEqual(tree[0].children.count, 1)
        XCTAssertEqual(tree[0].children[0].fullPath, "a/b")
        XCTAssertEqual(tree[0].children[0].children.count, 1)
        XCTAssertEqual(tree[0].children[0].children[0].fullPath, "a/b/c")
        XCTAssertTrue(tree[0].children[0].children[0].isLeaf)
    }

    func testBuild_multipleSiblingEntries_singleFolderWithoutSubfolders() {
        // All entries live directly under `system/` — no sub-folders,
        // so `system` is a leaf folder.
        let entries = [
            PassEntry(path: "system/a"),
            PassEntry(path: "system/b"),
            PassEntry(path: "system/c"),
        ]
        let tree = FolderTreeBuilder.build(from: entries)
        XCTAssertEqual(tree.count, 1)
        XCTAssertEqual(tree[0].fullPath, "system")
        XCTAssertTrue(tree[0].isLeaf)
    }

    func testBuild_mixedNesting_topLevelOrdering_andSubfolder() {
        let entries = [
            PassEntry(path: "system/note"),
            PassEntry(path: "system/work/email"),
            PassEntry(path: "system/work/wifi"),
            PassEntry(path: "personal/banking"),
        ]
        let tree = FolderTreeBuilder.build(from: entries)
        XCTAssertEqual(tree.count, 2)
        // Top-level is alphabetically sorted.
        XCTAssertEqual(tree[0].fullPath, "personal")
        XCTAssertEqual(tree[1].fullPath, "system")
        // `system` now contains a nested `system/work` sub-folder.
        XCTAssertEqual(tree[1].children.count, 1)
        XCTAssertEqual(tree[1].children[0].fullPath, "system/work")
        XCTAssertTrue(tree[1].children[0].isLeaf)
        // `personal` has no sub-folders (only direct entries).
        XCTAssertTrue(tree[0].isLeaf)
    }

    func testBuild_alphabeticalSort_isCaseInsensitive() {
        let entries = [
            PassEntry(path: "zebra/note"),
            PassEntry(path: "apple/note"),
            PassEntry(path: "Mango/note"),
        ]
        let tree = FolderTreeBuilder.build(from: entries)
        // Case-insensitive: a/A/m/M/z/Z mix into apple, Mango, zebra.
        XCTAssertEqual(tree.map(\.name), ["apple", "Mango", "zebra"])
    }

    func testBuild_emptyPathComponent_isSkipped() {
        // `personal/empty-name/` (trailing slash → empty trailing
        // component) must not create an unnameable child folder
        // node under `personal/empty-name`.
        let entries = [PassEntry(path: "personal/empty-name/")]
        let tree = FolderTreeBuilder.build(from: entries)
        XCTAssertEqual(tree.count, 1)
        XCTAssertEqual(tree[0].fullPath, "personal")
        XCTAssertEqual(tree[0].children.count, 1)
        XCTAssertEqual(tree[0].children[0].fullPath, "personal/empty-name")
        // No third level — the empty trailing segment is intentionally
        // dropped.
        XCTAssertTrue(tree[0].children[0].isLeaf)
    }

    func testBuild_isDeterministic_acrossInputOrder() {
        let aFirst: [PassEntry] = [
            PassEntry(path: "a/x"),
            PassEntry(path: "b/y"),
            PassEntry(path: "a/z"),
        ]
        let bFirst: [PassEntry] = [
            PassEntry(path: "b/y"),
            PassEntry(path: "a/z"),
            PassEntry(path: "a/x"),
        ]
        XCTAssertEqual(
            FolderTreeBuilder.build(from: aFirst),
            FolderTreeBuilder.build(from: bFirst)
        )
    }
}
