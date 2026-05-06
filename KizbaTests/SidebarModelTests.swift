//
//  SidebarModelTests.swift
//  KizbaTests
//
//  Tests for the sidebar's folder derivation. The MainActor-isolated
//  view model is fed `AppEnvironment.preview().passManager`
//  (`MockPassManager.preview()` in DEBUG) and asserted against the
//  expected sorted set of top-level folders.
//

import XCTest
@testable import Kizba

@MainActor
final class SidebarModelTests: XCTestCase {

    func testLoad_producesSortedTopLevelFolders_fromPreviewEnvironment() async {
        let env = AppEnvironment.preview()
        let model = SidebarModel(passManager: env.passManager)

        await model.load()

        XCTAssertEqual(model.folders.map(\.name), ["archive", "personal", "work"])
    }

    func testTopLevelFolders_isPureAndDeterministic() {
        let entries = [
            PassEntry(path: "work/aws/root"),
            PassEntry(path: "personal/email/gmail"),
            PassEntry(path: "work/github/org-bot"),
            PassEntry(path: "archive/services/forum"),
            PassEntry(path: "personal/wifi/home"),
        ]

        let folders = SidebarModel.topLevelFolders(from: entries)

        XCTAssertEqual(folders.map(\.name), ["archive", "personal", "work"])
    }

    func testTopLevelFolders_skipsTopLevelEntriesWithoutSlash() {
        let entries = [
            PassEntry(path: "loose-entry"),
            PassEntry(path: "work/aws/root"),
        ]

        let folders = SidebarModel.topLevelFolders(from: entries)

        XCTAssertEqual(folders.map(\.name), ["work"])
    }

    func testTopLevelFolders_dedupesRepeatedHeads() {
        let entries = [
            PassEntry(path: "work/a"),
            PassEntry(path: "work/b"),
            PassEntry(path: "work/c/d"),
        ]

        let folders = SidebarModel.topLevelFolders(from: entries)

        XCTAssertEqual(folders.map(\.name), ["work"])
    }

    func testInit_foldersStartEmpty() {
        let env = AppEnvironment.preview()
        let model = SidebarModel(passManager: env.passManager)

        XCTAssertTrue(model.folders.isEmpty)
    }
}
