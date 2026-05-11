//
//  GitStatusTests.swift
//  KizbaTests
//
//  Tests for the GitStatus value type.
//

import XCTest
@testable import Kizba

final class GitStatusTests: XCTestCase {

    func testNotARepository_hasExpectedDefaults() {
        let s = GitStatus.notARepository
        XCTAssertFalse(s.isGitRepository)
        XCTAssertNil(s.branch)
        XCTAssertFalse(s.hasLocalChanges)
        XCTAssertFalse(s.hasConflicts)
        XCTAssertEqual(s.aheadCount, 0)
        XCTAssertEqual(s.behindCount, 0)
        XCTAssertFalse(s.hasRemote)
        XCTAssertNil(s.lastFetchAt)
    }

    func testEquality_identicalInstances() {
        let a = GitStatus(isGitRepository: true, branch: "main", hasLocalChanges: true, hasConflicts: false, aheadCount: 1, behindCount: 2, hasRemote: true, lastFetchAt: Date(timeIntervalSince1970: 1_000_000))
        let b = GitStatus(isGitRepository: true, branch: "main", hasLocalChanges: true, hasConflicts: false, aheadCount: 1, behindCount: 2, hasRemote: true, lastFetchAt: Date(timeIntervalSince1970: 1_000_000))
        XCTAssertEqual(a, b)
    }

    func testEquality_differentBranch() {
        let a = GitStatus(isGitRepository: true, branch: "main")
        let b = GitStatus(isGitRepository: true, branch: "develop")
        XCTAssertNotEqual(a, b)
    }

    func testHashing_identicalInstancesShareHash() {
        let a = GitStatus(isGitRepository: true, branch: "main", aheadCount: 3)
        let b = GitStatus(isGitRepository: true, branch: "main", aheadCount: 3)
        var ha = Hasher()
        ha.combine(a)
        var hb = Hasher()
        hb.combine(b)
        XCTAssertEqual(ha.finalize(), hb.finalize())
    }

    func testCustomInit_allFieldsSet() {
        let date = Date()
        let s = GitStatus(isGitRepository: true, branch: "feat/x", hasLocalChanges: true, hasConflicts: true, aheadCount: 5, behindCount: 6, hasRemote: true, lastFetchAt: date)
        XCTAssertTrue(s.isGitRepository)
        XCTAssertEqual(s.branch, "feat/x")
        XCTAssertTrue(s.hasLocalChanges)
        XCTAssertTrue(s.hasConflicts)
        XCTAssertEqual(s.aheadCount, 5)
        XCTAssertEqual(s.behindCount, 6)
        XCTAssertTrue(s.hasRemote)
        XCTAssertEqual(s.lastFetchAt, date)
    }

    func testIsNotCodable() {
        XCTAssertFalse((GitStatus.self as Any) is Encodable.Type)
        XCTAssertFalse((GitStatus.self as Any) is Decodable.Type)
    }

    func testIsNotCustomStringConvertible() {
        XCTAssertFalse((GitStatus.self as Any) is CustomStringConvertible.Type)
        XCTAssertFalse((GitStatus.self as Any) is CustomDebugStringConvertible.Type)
    }
}
