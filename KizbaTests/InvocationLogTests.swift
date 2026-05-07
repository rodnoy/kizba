//
//  InvocationLogTests.swift
//  KizbaTests
//
//  Behavioural tests for the in-memory `InvocationLog` ring buffer
//  (Phase 8.4).
//

import XCTest
@testable import Kizba

final class InvocationLogTests: XCTestCase {

    // MARK: - Helpers

    private func makeInvocation(_ tag: String, exitCode: Int32 = 0) -> Invocation {
        Invocation(
            executable: "/bin/echo",
            args: [tag],
            exitCode: exitCode,
            stderrExcerpt: "",
            startedAt: Date(),
            duration: 0.001
        )
    }

    // MARK: - Tests

    func testRecordAndRecent_limit() async {
        let log = InvocationLog(maxEntries: 3)

        // Record more than the cap; only the last `maxEntries` survive.
        for i in 0..<5 {
            await log.record(makeInvocation("\(i)"))
        }

        let recent = await log.recent()
        XCTAssertEqual(recent.count, 3)

        // Newest-first ordering: indices 4, 3, 2.
        XCTAssertEqual(recent.map { $0.args.first }, ["4", "3", "2"])
    }

    func testRecent_isEmptyInitially() async {
        let log = InvocationLog()
        let recent = await log.recent()
        XCTAssertTrue(recent.isEmpty)
    }

    func testRecent_newestFirst_underCap() async {
        let log = InvocationLog(maxEntries: 10)
        await log.record(makeInvocation("first"))
        await log.record(makeInvocation("second"))
        await log.record(makeInvocation("third"))

        let recent = await log.recent()
        XCTAssertEqual(recent.map { $0.args.first }, ["third", "second", "first"])
    }

    func testClear() async {
        let log = InvocationLog(maxEntries: 5)
        await log.record(makeInvocation("a"))
        await log.record(makeInvocation("b"))

        await log.clear()
        let recent = await log.recent()
        XCTAssertTrue(recent.isEmpty)
    }

    func testInit_clampsZeroOrNegativeMaxEntries() async {
        let log = InvocationLog(maxEntries: 0)
        await log.record(makeInvocation("a"))
        await log.record(makeInvocation("b"))

        // Cap should have been clamped to 1; only the newest remains.
        let recent = await log.recent()
        XCTAssertEqual(recent.count, 1)
        XCTAssertEqual(recent.first?.args.first, "b")
    }
}
