//
//  PassErrorGitCasesTests.swift
//  KizbaTests
//
//  Tests for the new git-related PassError cases added in MVP 4 A.2.
//

import XCTest
@testable import Kizba

final class PassErrorGitCasesTests: XCTestCase {

    func testEquality_gitCases() {
        XCTAssertEqual(PassError.gitNotInitialized, .gitNotInitialized)
        XCTAssertEqual(PassError.gitNoRemote, .gitNoRemote)
        XCTAssertEqual(PassError.gitAuthFailed, .gitAuthFailed)

        let c1 = PassError.gitConflict(paths: nil)
        let c2 = PassError.gitConflict(paths: nil)
        XCTAssertEqual(c1, c2)

        let c3 = PassError.gitConflict(paths: ["a","b"])
        let c4 = PassError.gitConflict(paths: ["a","b"])
        XCTAssertEqual(c3, c4)

        let r1 = PassError.gitRejected(reason: "x")
        let r2 = PassError.gitRejected(reason: "x")
        XCTAssertEqual(r1, r2)
    }

    func testInlineRecoverable_gitCases_allFalse() {
        XCTAssertFalse(PassError.gitNotInitialized.inlineRecoverable)
        XCTAssertFalse(PassError.gitNoRemote.inlineRecoverable)
        XCTAssertFalse(PassError.gitAuthFailed.inlineRecoverable)
        XCTAssertFalse(PassError.gitConflict(paths: nil).inlineRecoverable)
        XCTAssertFalse(PassError.gitNetworkUnavailable.inlineRecoverable)
        XCTAssertFalse(PassError.gitRejected(reason: "x").inlineRecoverable)
    }

    func testOnboardingHint_gitNotInitialized_configureGitRemote() {
        XCTAssertEqual(PassError.gitNotInitialized.onboardingHint, .configureGitRemote)
    }

    func testOnboardingHint_gitNoRemote_configureGitRemote() {
        XCTAssertEqual(PassError.gitNoRemote.onboardingHint, .configureGitRemote)
    }

    func testOnboardingHint_others_nil() {
        XCTAssertNil(PassError.gitAuthFailed.onboardingHint)
        XCTAssertNil(PassError.gitConflict(paths: nil).onboardingHint)
        XCTAssertNil(PassError.gitNetworkUnavailable.onboardingHint)
        XCTAssertNil(PassError.gitRejected(reason: "x").onboardingHint)
    }

    func testAutoRefreshes_gitCases_allFalse() {
        XCTAssertFalse(PassError.gitNotInitialized.autoRefreshes)
        XCTAssertFalse(PassError.gitNoRemote.autoRefreshes)
        XCTAssertFalse(PassError.gitAuthFailed.autoRefreshes)
        XCTAssertFalse(PassError.gitConflict(paths: nil).autoRefreshes)
        XCTAssertFalse(PassError.gitNetworkUnavailable.autoRefreshes)
        XCTAssertFalse(PassError.gitRejected(reason: "x").autoRefreshes)
    }

    func testHashing_gitConflictWithPaths() {
        var set = Set<PassError>()
        set.insert(.gitConflict(paths: ["a"]))
        XCTAssertTrue(set.contains(.gitConflict(paths: ["a"])))
    }
}
